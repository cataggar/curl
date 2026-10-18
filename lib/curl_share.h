#ifndef HEADER_CURL_SHARE_H
#define HEADER_CURL_SHARE_H
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

#include "curl_threads.h"
#include "cookie.h"
#include "psl.h"
#include "urldata.h"
#include "conncache.h"

struct Curl_easy;
struct CookieInfo;
struct hsts;
struct Curl_ssl_scache;

#define CURL_GOOD_SHARE 0x7e117a1e
#define GOOD_SHARE_HANDLE(x) ((x) && (x)->magic == CURL_GOOD_SHARE)

#define CURL_SHARE_KEEP_CONNECT(s)                          \
  ((s) && ((s)->specifier & (1 << CURL_LOCK_DATA_CONNECT)))

/* this struct is libcurl-private, do not export details */
struct Curl_share {
  unsigned int magic; /* CURL_GOOD_SHARE */
  unsigned int specifier;

  uint32_t ref_count;
  int has_been_shared;
  curl_lock_function lockfunc;
  curl_unlock_function unlockfunc;
  void *clientdata;
  struct Curl_easy *admin;
  struct CookieInfo *cookies;
  struct hsts *hsts;
  struct Curl_ssl_scache *ssl_scache;

  struct Curl_dnscache dnscache; /* DNS cache */
  struct cpool cpool;
#ifdef USE_LIBPSL
  struct PslCache psl;
#else
  struct {
    const void *psl;
    time_t expires;
    BIT(dynamic);
  } psl;
#endif
#ifdef USE_MUTEX
   /* do `ref_count` and `has_been_shared` checks using this mutex. */
  curl_mutex_t lock;
#endif
};

CURLSHcode Curl_share_lock(struct Curl_easy *data, curl_lock_data type,
                           curl_lock_access accesstype);
CURLSHcode Curl_share_unlock(struct Curl_easy *data, curl_lock_data type);

CURLSHcode Curl_share_lock_share(struct Curl_share *share,
                                 struct Curl_easy *data,
                                 curl_lock_data type,
                                 curl_lock_access accesstype);
CURLSHcode Curl_share_unlock_share(struct Curl_share *share,
                                   struct Curl_easy *data,
                                   curl_lock_data type);

/* convenience macro to check if this handle is using a shared SSL spool */
#define CURL_SHARE_ssl_scache(data)                                \
  ((data)->share &&                                                \
   ((data)->share->specifier & (1 << CURL_LOCK_DATA_SSL_SESSION)))

CURLcode Curl_share_easy_unlink(struct Curl_easy *data);
CURLcode Curl_share_easy_link(struct Curl_easy *data,
                              struct Curl_share *share);

CURLcode Curl_share_easy_unlink_ex(struct Curl_easy *data,
                                   struct Curl_share **pshare,
                                   struct connectdata *conn,
                                   curl_off_t *last_conn_id,
                                   uint32_t *last_cpid,
                                   struct CookieInfo **pcookies,
                                   struct hsts **phsts,
                                   void **ppsl,
                                   void *multi_psl);

CURLcode Curl_share_easy_link_ex(struct Curl_easy *data,
                                 struct Curl_share *share,
                                 struct Curl_share **pshare,
                                 curl_off_t *last_conn_id,
                                 uint32_t *last_cpid,
                                 struct CookieInfo **pcookies,
                                 struct hsts **phsts,
                                 void **ppsl);

static inline CURLSHcode curl_share_lock_wrap(struct Curl_easy *data,
                                              curl_lock_data type,
                                              curl_lock_access accesstype)
{
  return Curl_share_lock_share(data->share, data, type, accesstype);
}

static inline CURLSHcode curl_share_unlock_wrap(struct Curl_easy *data,
                                                curl_lock_data type)
{
  return Curl_share_unlock_share(data->share, data, type);
}

static inline CURLcode curl_share_easy_unlink_wrap(struct Curl_easy *data)
{
  return Curl_share_easy_unlink_ex(
    data,
    &data->share,
    data->conn,
    &data->state.last_conn_id,
    &data->state.last_cpid,
#if !defined(CURL_DISABLE_HTTP) && !defined(CURL_DISABLE_COOKIES)
    &data->cookies,
#else
    NULL,
#endif
#ifndef CURL_DISABLE_HSTS
    &data->hsts,
#else
    NULL,
#endif
#ifdef USE_LIBPSL
    (void **)&data->psl,
    data->multi ? (void *)&data->multi->psl : NULL
#else
    NULL,
    NULL
#endif
  );
}

static inline CURLcode curl_share_easy_link_wrap(struct Curl_easy *data,
                                                 struct Curl_share *share)
{
  return Curl_share_easy_link_ex(
    data,
    share,
    &data->share,
    &data->state.last_conn_id,
    &data->state.last_cpid,
#if !defined(CURL_DISABLE_HTTP) && !defined(CURL_DISABLE_COOKIES)
    &data->cookies,
#else
    NULL,
#endif
#ifndef CURL_DISABLE_HSTS
    &data->hsts,
#else
    NULL,
#endif
#ifdef USE_LIBPSL
    (void **)&data->psl
#else
    NULL
#endif
  );
}

#ifdef HEADER_CURL_VSSH_VSSH_H
#include "vtls/vtls_scache.h"
#include "hsts.h"

void Curl_share_init_admin(struct Curl_easy *admin);
void Curl_share_init_admin(struct Curl_easy *admin)
{
  if(admin) {
    admin->mid = 0;
    admin->state.internal = TRUE;
#ifdef DEBUGBUILD
    if(getenv("CURL_DEBUG"))
      admin->set.verbose = TRUE;
#endif
  }
}

CURLSHcode Curl_share_hsts_init(struct hsts **phsts);
CURLSHcode Curl_share_hsts_init(struct hsts **phsts)
{
#ifndef CURL_DISABLE_HSTS
  if(!*phsts) {
    *phsts = Curl_hsts_init();
    if(!*phsts)
      return CURLSHE_NOMEM;
  }
  return CURLSHE_OK;
#else
  (void)phsts;
  return CURLSHE_NOT_BUILT_IN;
#endif
}

void Curl_share_hsts_cleanup(struct hsts **phsts);
void Curl_share_hsts_cleanup(struct hsts **phsts)
{
#ifndef CURL_DISABLE_HSTS
  Curl_hsts_cleanup(phsts);
#else
  (void)phsts;
#endif
}

CURLSHcode Curl_share_ssl_scache_init(struct Curl_ssl_scache **pscache);
CURLSHcode Curl_share_ssl_scache_init(struct Curl_ssl_scache **pscache)
{
#ifdef USE_SSL
  if(!*pscache) {
    if(Curl_ssl_scache_create(25, 2, pscache))
      return CURLSHE_NOMEM;
  }
  return CURLSHE_OK;
#else
  (void)pscache;
  return CURLSHE_NOT_BUILT_IN;
#endif
}

void Curl_share_ssl_scache_cleanup(struct Curl_ssl_scache **pscache);
void Curl_share_ssl_scache_cleanup(struct Curl_ssl_scache **pscache)
{
#ifdef USE_SSL
  if(*pscache) {
    Curl_ssl_scache_destroy(*pscache);
    *pscache = NULL;
  }
#else
  (void)pscache;
#endif
}

struct Curl_share *Curl_share_get_easy_share(struct Curl_easy *data);
struct Curl_share *Curl_share_get_easy_share(struct Curl_easy *data)
{
  return data ? data->share : NULL;
}

CURLcode Curl_share_easy_unlink_dispatch(struct Curl_easy *data);
CURLcode Curl_share_easy_unlink_dispatch(struct Curl_easy *data)
{
  return curl_share_easy_unlink_wrap(data);
}

CURLcode Curl_share_easy_link_dispatch(struct Curl_easy *data,
                                       struct Curl_share *share);
CURLcode Curl_share_easy_link_dispatch(struct Curl_easy *data,
                                       struct Curl_share *share)
{
  return curl_share_easy_link_wrap(data, share);
}
#endif

#define Curl_share_lock(data, type, accesstype) \
  curl_share_lock_wrap(data, type, accesstype)
#define Curl_share_unlock(data, type) \
  curl_share_unlock_wrap(data, type)
#define Curl_share_easy_unlink(data) \
  curl_share_easy_unlink_wrap(data)
#define Curl_share_easy_link(data, share) \
  curl_share_easy_link_wrap(data, share)

#endif /* HEADER_CURL_SHARE_H */
