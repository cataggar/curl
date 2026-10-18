#ifndef HEADER_CURL_VTLS_SCACHE_H
#define HEADER_CURL_VTLS_SCACHE_H
/***************************************************************************
 *                                  _   _ ____  _
 *  Project                     ___| | | |  _ \| |
 *                             / __| | | | |_) | |
 *                            | (__| |_| |  _ <| |___
 *                             \___|\___/|_| \_\_____|
 *
 * Copyright (C) Daniel Stenberg, <daniel@haxx.se>, et al.
 *
 * This software is licensed as described in the file COPYING, which
 * you should have received as part of this distribution. The terms
 * are also available at https://curl.se/docs/copyright.html.
 *
 * You may opt to use, copy, modify, merge, publish, distribute and/or sell
 * copies of the Software, and permit persons to whom the Software is
 * furnished to do so, under the terms of the COPYING file.
 *
 * This software is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY
 * KIND, either express or implied.
 *
 * SPDX-License-Identifier: curl
 *
 ***************************************************************************/
#include "curl_setup.h"

#ifdef USE_SSL

#include "cfilters.h"
#include "urldata.h"
#include "curl_share.h"
#include "curl_trc.h"
#include "vtls/vtls.h"

struct Curl_cfilter;
struct Curl_easy;
struct Curl_ssl_scache;
struct Curl_ssl_session;
struct ssl_peer;

static inline struct Curl_ssl_scache *
Curl_ssl_scache_get_from_easy(struct Curl_easy *data)
{
  if(!data)
    return NULL;
  if(data->share && data->share->ssl_scache)
    return data->share->ssl_scache;
  if(data->multi && data->multi->ssl_scache)
    return data->multi->ssl_scache;
  return NULL;
}

static inline bool
Curl_ssl_scache_has_share(struct Curl_easy *data)
{
  return data && CURL_SHARE_ssl_scache(data);
}

static inline struct curl_trc_feat *
Curl_ssl_scache_trc_feat(void)
{
#ifndef CURL_DISABLE_VERBOSE_STRINGS
  return &Curl_trc_feat_ssls;
#else
  return NULL;
#endif
}

/* RFC 8446 (TLSv1.3) restrict lifetime to one week max, for
 * other, less secure versions, we restrict it to a day */
#define CURL_SCACHE_MAX_13_LIFETIME_SEC    (60 * 60 * 24 * 7)
#define CURL_SCACHE_MAX_12_LIFETIME_SEC    (60 * 60 * 24)

/* Create a session cache for up to max_peers endpoints with a total
 * of up to max_sessions SSL sessions per peer */
CURLcode Curl_ssl_scache_create(size_t max_peers,
                                size_t max_sessions_per_peer,
                                struct Curl_ssl_scache **pscache);

void Curl_ssl_scache_destroy(struct Curl_ssl_scache *scache);

/* Create a key from peer and TLS configuration information that is
 * unique for how the connection filter wants to establish a TLS
 * connection to the peer.
 * If the filter is a TLS proxy filter, it uses the proxy relevant
 * information.
 * @param peer    the peer the filter wants to talk to
 * @param sslc    the relevant ssl configuration
 * @param tls_id  identifier of TLS implementation for sessions. Should
 *                include full version if session data from other versions
 *                is to be avoided.
 * @param ppeer_key on successful return, the key generated
 */
CURLcode Curl_ssl_peer_key_make(const struct ssl_peer *peer,
                                struct ssl_filter_config *sslc,
                                const char *tls_id,
                                char **ppeer_key);

/* Return if there is a session cache shall be used.
 * An SSL session might not be configured or not available for
 * "connect-only" transfers.
 */
bool Curl_ssl_scache_use_zig(struct Curl_easy *data,
                             struct Curl_ssl_scache *scache,
                             struct ssl_filter_config *conn_config);
static inline bool Curl_ssl_scache_use(struct Curl_cfilter *cf,
                                       struct Curl_easy *data)
{
  return Curl_ssl_scache_use_zig(
    data, Curl_ssl_scache_get_from_easy(data),
    cf ? Curl_ssl_cf_get_filter_config(cf) : NULL);
}

/* Lock session cache mutex.
 * Call this before calling other Curl_ssl_*session* functions
 * Caller should unlock this mutex as soon as possible, as it may block
 * other SSL connection from making progress.
 * The purpose of explicitly locking SSL session cache data is to allow
 * individual SSL engines to manage session lifetime in their specific way.
 */
void Curl_ssl_scache_lock_zig(struct Curl_easy *data,
                              struct Curl_ssl_scache *scache,
                              bool has_share_scache);
static inline void Curl_ssl_scache_lock(struct Curl_easy *data)
{
  Curl_ssl_scache_lock_zig(data, Curl_ssl_scache_get_from_easy(data),
                           Curl_ssl_scache_has_share(data));
}

/* Unlock session cache mutex */
void Curl_ssl_scache_unlock_zig(struct Curl_easy *data,
                                struct Curl_ssl_scache *scache,
                                bool has_share_scache);
static inline void Curl_ssl_scache_unlock(struct Curl_easy *data)
{
  Curl_ssl_scache_unlock_zig(data, Curl_ssl_scache_get_from_easy(data),
                             Curl_ssl_scache_has_share(data));
}

/* Get TLS session object from the cache for the ssl_peer_key.
 * scache mutex must be locked (see Curl_ssl_scache_lock).
 * Caller must make sure that the ownership of returned session object
 * is properly taken (e.g. its refcount is incremented
 * under scache mutex).
 * @param cf      the connection filter wanting to use it
 * @param data    the transfer involved
 * @param ssl_peer_key the key for lookup
 * @retval sobj   the object for the peer key or NULL
 */
void *Curl_ssl_scache_get_obj_zig(struct Curl_cfilter *cf,
                                  struct Curl_easy *data,
                                  struct Curl_ssl_scache *scache,
                                  struct ssl_filter_config *conn_config,
                                  struct curl_trc_feat *trc_feat,
                                  const char *ssl_peer_key);
static inline void *Curl_ssl_scache_get_obj(struct Curl_cfilter *cf,
                                            struct Curl_easy *data,
                                            const char *ssl_peer_key)
{
  return Curl_ssl_scache_get_obj_zig(
    cf, data,
    Curl_ssl_scache_get_from_easy(data),
    cf ? Curl_ssl_cf_get_filter_config(cf) : NULL,
    Curl_ssl_scache_trc_feat(),
    ssl_peer_key);
}

typedef void Curl_ssl_scache_obj_dtor(void *sobj);

/* Add a TLS session related object to the cache.
 * Replaces an existing object with the same peer_key.
 * scache mutex must be locked (see Curl_ssl_scache_lock).
 * Call takes ownership of `sobj`, using `sobj_dtor_cb`
 * to deallocate it. Is called in all outcomes, either right away or
 * later when the session cache is cleaned up.
 * Caller must ensure that it has properly shared ownership of `sobj`
 * with cache (e.g. incrementing refcount on success)
 * @param cf      the connection filter wanting to use it
 * @param data    the transfer involved
 * @param ssl_peer_key the key for lookup
 * @param sobj    the TLS session object
 * @param sobj_free_cb callback to free the session object
 */
CURLcode Curl_ssl_scache_add_obj_zig(struct Curl_cfilter *cf,
                                     struct Curl_easy *data,
                                     struct Curl_ssl_scache *scache,
                                     struct ssl_filter_config *conn_config,
                                     struct curl_trc_feat *trc_feat,
                                     const char *ssl_peer_key,
                                     void *sobj,
                                     Curl_ssl_scache_obj_dtor *sobj_dtor_cb);
static inline CURLcode
Curl_ssl_scache_add_obj(struct Curl_cfilter *cf,
                        struct Curl_easy *data,
                        const char *ssl_peer_key,
                        void *sobj,
                        Curl_ssl_scache_obj_dtor *sobj_dtor_cb)
{
  return Curl_ssl_scache_add_obj_zig(
    cf, data,
    Curl_ssl_scache_get_from_easy(data),
    cf ? Curl_ssl_cf_get_filter_config(cf) : NULL,
    Curl_ssl_scache_trc_feat(),
    ssl_peer_key, sobj, sobj_dtor_cb);
}

/* All about an SSL session ticket */
struct Curl_ssl_session {
  uint8_t *sdata;              /* session ticket data, plain bytes */
  size_t sdata_len;            /* number of bytes in sdata */
  curl_off_t valid_until;      /* seconds since EPOCH until ticket expires */
  int ietf_tls_id;             /* TLS protocol identifier negotiated */
  char *alpn;                  /* APLN TLS negotiated protocol string */
  size_t earlydata_max;        /* max 0-RTT data supported by peer */
  uint8_t *quic_tp;            /* Optional QUIC transport param bytes */
  size_t quic_tp_len;          /* number of bytes in quic_tp */
  struct Curl_llist_node list; /*  internal storage handling */
  BIT(sectrust_verified);      /* session comes from sectrust verified TLS */
};

/* Create a `session` instance. Does NOT need locking.
 * Takes ownership of `sdata` and `sobj` regardless of return code.
 * @param sdata     bytes of SSL session data or NULL (sobj then required)
 * @param sdata_len amount of session data bytes
 * @param ietf_tls_id  IETF protocol version, e.g. 0x304 for TLSv1.3
 * @param alpn      ALPN protocol selected or NULL
 * @param valid_until seconds since EPOCH when session expires, pass 0
 *                  in case this is not known.
 * @param psession on return the scached session instance created
 */
CURLcode Curl_ssl_session_create(void *sdata, size_t sdata_len,
                                 int ietf_tls_id, const char *alpn,
                                 curl_off_t valid_until, size_t earlydata_max,
                                 struct Curl_ssl_session **psession);

/* Variation of session creation with quic transport parameter bytes,
 * Takes ownership of `quic_tp` regardless of return code. */
CURLcode Curl_ssl_session_create2(void *sdata, size_t sdata_len,
                                  int ietf_tls_id, const char *alpn,
                                  curl_off_t valid_until, size_t earlydata_max,
                                  unsigned char *quic_tp, size_t quic_tp_len,
                                  struct Curl_ssl_session **psession);

/* Duplicate an ssl session */
CURLcode Curl_ssl_session_dup(struct Curl_ssl_session *src,
                              struct Curl_ssl_session **pdest);

/* Destroy a `session` instance. Can be called with NULL.
 * Does NOT need locking. */
void Curl_ssl_session_destroy(struct Curl_ssl_session *s);

/* Put the scache session into the cache. Does NOT need locking.
 * Call takes ownership of `s` in all outcomes.
 * @param cf      the connection filter wanting to use it
 * @param data    the transfer involved
 * @param ssl_peer_key the key for lookup
 * @param s       the scache session object
 */
CURLcode Curl_ssl_scache_put_zig(struct Curl_cfilter *cf,
                                 struct Curl_easy *data,
                                 struct Curl_ssl_scache *scache,
                                 bool has_share_scache,
                                 struct ssl_filter_config *conn_config,
                                 struct curl_trc_feat *trc_feat,
                                 const char *ssl_peer_key,
                                 struct Curl_ssl_session *s);
static inline CURLcode Curl_ssl_scache_put(struct Curl_cfilter *cf,
                                           struct Curl_easy *data,
                                           const char *ssl_peer_key,
                                           struct Curl_ssl_session *s)
{
  return Curl_ssl_scache_put_zig(
    cf, data,
    Curl_ssl_scache_get_from_easy(data),
    Curl_ssl_scache_has_share(data),
    cf ? Curl_ssl_cf_get_filter_config(cf) : NULL,
    Curl_ssl_scache_trc_feat(),
    ssl_peer_key, s);
}

/* Take a matching scache session from the cache. Does NOT need locking.
 * @param cf      the connection filter wanting to use it
 * @param data    the transfer involved
 * @param ssl_peer_key the key for lookup
 * @param s       on return, the scache session object or NULL
 */
CURLcode Curl_ssl_scache_take_zig(struct Curl_cfilter *cf,
                                  struct Curl_easy *data,
                                  struct Curl_ssl_scache *scache,
                                  bool has_share_scache,
                                  struct ssl_filter_config *conn_config,
                                  struct curl_trc_feat *trc_feat,
                                  const char *ssl_peer_key,
                                  struct Curl_ssl_session **ps);
static inline CURLcode Curl_ssl_scache_take(struct Curl_cfilter *cf,
                                            struct Curl_easy *data,
                                            const char *ssl_peer_key,
                                            struct Curl_ssl_session **ps)
{
  return Curl_ssl_scache_take_zig(
    cf, data,
    Curl_ssl_scache_get_from_easy(data),
    Curl_ssl_scache_has_share(data),
    cf ? Curl_ssl_cf_get_filter_config(cf) : NULL,
    Curl_ssl_scache_trc_feat(),
    ssl_peer_key, ps);
}

/* Return a taken scache session to the cache. Does NOT need locking.
 * Depending on TLS version and other criteria, it may cache it again
 * or destroy it. Maybe called with a NULL session.
 */
void Curl_ssl_scache_return_zig(struct Curl_cfilter *cf,
                                struct Curl_easy *data,
                                struct Curl_ssl_scache *scache,
                                bool has_share_scache,
                                struct ssl_filter_config *conn_config,
                                struct curl_trc_feat *trc_feat,
                                const char *ssl_peer_key,
                                struct Curl_ssl_session *s);
static inline void Curl_ssl_scache_return(struct Curl_cfilter *cf,
                                          struct Curl_easy *data,
                                          const char *ssl_peer_key,
                                          struct Curl_ssl_session *s)
{
  Curl_ssl_scache_return_zig(
    cf, data,
    Curl_ssl_scache_get_from_easy(data),
    Curl_ssl_scache_has_share(data),
    cf ? Curl_ssl_cf_get_filter_config(cf) : NULL,
    Curl_ssl_scache_trc_feat(),
    ssl_peer_key, s);
}

/* Remove all sessions and obj for the peer_key. Does NOT need locking. */
void Curl_ssl_scache_remove_all_zig(struct Curl_cfilter *cf,
                                    struct Curl_easy *data,
                                    struct Curl_ssl_scache *scache,
                                    bool has_share_scache,
                                    struct ssl_filter_config *conn_config,
                                    struct curl_trc_feat *trc_feat,
                                    const char *ssl_peer_key);
static inline void Curl_ssl_scache_remove_all(struct Curl_cfilter *cf,
                                              struct Curl_easy *data,
                                              const char *ssl_peer_key)
{
  Curl_ssl_scache_remove_all_zig(
    cf, data,
    Curl_ssl_scache_get_from_easy(data),
    Curl_ssl_scache_has_share(data),
    cf ? Curl_ssl_cf_get_filter_config(cf) : NULL,
    Curl_ssl_scache_trc_feat(),
    ssl_peer_key);
}

bool Curl_ssl_scache_is_locked_by_current_thread_zig(
  struct Curl_easy *data,
  struct Curl_ssl_scache *scache);
static inline bool
Curl_ssl_scache_is_locked_by_current_thread(struct Curl_easy *data)
{
  return Curl_ssl_scache_is_locked_by_current_thread_zig(
    data, Curl_ssl_scache_get_from_easy(data));
}

#ifdef USE_SSLS_EXPORT

CURLcode Curl_ssl_session_import_zig(struct Curl_easy *data,
                                     struct Curl_ssl_scache *scache,
                                     bool has_share_scache,
                                     struct curl_trc_feat *trc_feat,
                                     const char *ssl_peer_key,
                                     const unsigned char *shmac,
                                     size_t shmac_len,
                                     const void *sdata,
                                     size_t sdata_len);
static inline CURLcode
Curl_ssl_session_import(struct Curl_easy *data,
                        const char *ssl_peer_key,
                        const unsigned char *shmac,
                        size_t shmac_len,
                        const void *sdata,
                        size_t sdata_len)
{
  return Curl_ssl_session_import_zig(
    data,
    Curl_ssl_scache_get_from_easy(data),
    Curl_ssl_scache_has_share(data),
    Curl_ssl_scache_trc_feat(),
    ssl_peer_key, shmac, shmac_len, sdata, sdata_len);
}

CURLcode Curl_ssl_session_export_zig(struct Curl_easy *data,
                                     struct Curl_ssl_scache *scache,
                                     bool has_share_scache,
                                     struct curl_trc_feat *trc_feat,
                                     curl_ssls_export_cb *export_fn,
                                     void *userptr);
static inline CURLcode
Curl_ssl_session_export(struct Curl_easy *data,
                        curl_ssls_export_cb *export_fn,
                        void *userptr)
{
  return Curl_ssl_session_export_zig(
    data,
    Curl_ssl_scache_get_from_easy(data),
    Curl_ssl_scache_has_share(data),
    Curl_ssl_scache_trc_feat(),
    export_fn, userptr);
}

#endif /* USE_SSLS_EXPORT */
#endif /* USE_SSL */

#endif /* HEADER_CURL_VTLS_SCACHE_H */
