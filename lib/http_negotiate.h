#ifndef HEADER_CURL_HTTP_NEGOTIATE_H
#define HEADER_CURL_HTTP_NEGOTIATE_H
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

#if !defined(CURL_DISABLE_HTTP) && defined(USE_SPNEGO)

#include "urldata.h"
#include "vauth/vauth.h"
#include "vtls/vtls.h"
#include "cfilters.h"

typedef CURLcode (*Curl_spnego_decode_fn)(struct Curl_easy *data,
                                          struct connectdata *conn,
                                          struct Curl_creds *creds,
                                          const char *host,
                                          const char *header,
                                          struct negotiatedata *neg_ctx);
typedef CURLcode (*Curl_spnego_create_fn)(struct negotiatedata *neg_ctx,
                                          char **outptr, size_t *outlen,
                                          bool *has_context, bool *is_done);
typedef void (*Curl_spnego_cleanup_fn)(struct negotiatedata *neg_ctx);

static CURL_INLINE CURLcode
curl_nego_decode_cb(struct Curl_easy *data,
                    struct connectdata *conn,
                    struct Curl_creds *creds,
                    const char *host,
                    const char *header,
                    struct negotiatedata *neg_ctx)
{
  CURLcode result;
#ifdef USE_WINDOWS_SSPI
  if(conn)
    neg_ctx->sslContext = conn->sslContext;
#else
  (void)conn;
#endif
#ifdef GSS_C_CHANNEL_BOUND_FLAG
#ifdef USE_SSL
  curlx_dyn_init(&neg_ctx->channel_binding_data, SSL_CB_MAX_SIZE + 1);
  if(conn && Curl_conn_is_ssl(conn, FIRSTSOCKET)) {
    result = Curl_ssl_get_channel_binding(data, FIRSTSOCKET,
                                          &neg_ctx->channel_binding_data);
    if(result) {
      curlx_dyn_free(&neg_ctx->channel_binding_data);
      return result;
    }
  }
#else
  curlx_dyn_init(&neg_ctx->channel_binding_data, 1);
#endif
#endif
  result = Curl_auth_decode_spnego_message(data, creds, "HTTP",
                                           host, header, neg_ctx);
#ifdef GSS_C_CHANNEL_BOUND_FLAG
  curlx_dyn_free(&neg_ctx->channel_binding_data);
#endif
  return result;
}

static CURL_INLINE CURLcode
curl_nego_create_cb(struct negotiatedata *neg_ctx,
                    char **outptr, size_t *outlen,
                    bool *has_context, bool *is_done)
{
  if(!outptr) {
    *has_context = neg_ctx->context != NULL;
    return CURLE_OK;
  }
  {
    CURLcode result = Curl_auth_create_spnego_message(neg_ctx, outptr, outlen);
#ifdef HAVE_GSSAPI
    *is_done = (neg_ctx->status == GSS_S_COMPLETE ||
                neg_ctx->status == GSS_S_CONTINUE_NEEDED);
#elif defined(USE_WINDOWS_SSPI)
    *is_done = (neg_ctx->status == SEC_E_OK ||
                neg_ctx->status == SEC_I_CONTINUE_NEEDED);
#else
    *is_done = FALSE;
#endif
    return result;
  }
}

/* this is for Negotiate header input */
CURLcode Curl_input_negotiate(struct Curl_easy *data, struct connectdata *conn,
                              bool proxy, const char *header,
                              struct Curl_creds *creds,
                              const char *host,
                              struct negotiatedata *neg_ctx,
                              uint8_t *state,
                              struct Curl_peer *origin,
                              struct Curl_peer **conn_creds_origin,
                              struct Curl_creds **conn_creds,
                              Curl_spnego_decode_fn decode_fn,
                              Curl_spnego_cleanup_fn cleanup_fn);

/* this is for creating Negotiate header output */
CURLcode Curl_output_negotiate(struct Curl_easy *data,
                               struct connectdata *conn, bool proxy,
                              struct Curl_creds *creds,
                              const char *host,
                              struct negotiatedata *neg_ctx,
                              uint8_t *state,
                              struct Curl_peer *origin,
                              struct Curl_peer **conn_creds_origin,
                              struct Curl_creds **conn_creds,
                              char **allocuserpwd,
                              struct auth *authp,
                              Curl_spnego_decode_fn decode_fn,
                              Curl_spnego_create_fn create_fn,
                              Curl_spnego_cleanup_fn cleanup_fn);

#ifndef CURL_DISABLE_PROXY
#define Curl_input_negotiate(data, conn, proxy, header) \
  Curl_input_negotiate((data), (conn), (proxy), (header), \
    (proxy) ? (conn)->http_proxy.creds : (data)->state.creds, \
    (proxy) ? (conn)->http_proxy.peer->hostname : (data)->state.origin->hostname, \
    Curl_auth_nego_get((conn), (proxy)), \
    (proxy) ? &(conn)->proxy_negotiate_state : &(conn)->http_negotiate_state, \
    (data)->state.origin, &(conn)->creds_origin, &(conn)->creds, \
    curl_nego_decode_cb, Curl_auth_cleanup_spnego)
#define Curl_output_negotiate(data, conn, proxy) \
  Curl_output_negotiate((data), (conn), (proxy), \
    (proxy) ? (conn)->http_proxy.creds : (data)->state.creds, \
    (proxy) ? (conn)->http_proxy.peer->hostname : (data)->state.origin->hostname, \
    Curl_auth_nego_get((conn), (proxy)), \
    (proxy) ? &(conn)->proxy_negotiate_state : &(conn)->http_negotiate_state, \
    (data)->state.origin, &(conn)->creds_origin, &(conn)->creds, \
    (proxy) ? &(data)->req.hd_proxy_auth : &(data)->req.hd_auth, \
    (proxy) ? &(data)->state.authproxy : &(data)->state.authhost, \
    curl_nego_decode_cb, curl_nego_create_cb, Curl_auth_cleanup_spnego)
#else
#define Curl_input_negotiate(data, conn, proxy, header) \
  Curl_input_negotiate((data), (conn), (proxy), (header), \
    (data)->state.creds, (data)->state.origin->hostname, \
    Curl_auth_nego_get((conn), FALSE), &(conn)->http_negotiate_state, \
    (data)->state.origin, &(conn)->creds_origin, &(conn)->creds, \
    curl_nego_decode_cb, Curl_auth_cleanup_spnego)
#define Curl_output_negotiate(data, conn, proxy) \
  Curl_output_negotiate((data), (conn), (proxy), \
    (data)->state.creds, (data)->state.origin->hostname, \
    Curl_auth_nego_get((conn), FALSE), &(conn)->http_negotiate_state, \
    (data)->state.origin, &(conn)->creds_origin, &(conn)->creds, \
    &(data)->req.hd_auth, &(data)->state.authhost, \
    curl_nego_decode_cb, curl_nego_create_cb, Curl_auth_cleanup_spnego)
#endif

#endif

#endif /* HEADER_CURL_HTTP_NEGOTIATE_H */
