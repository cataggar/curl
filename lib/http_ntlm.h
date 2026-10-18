#ifndef HEADER_CURL_HTTP_NTLM_H
#define HEADER_CURL_HTTP_NTLM_H
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

#if !defined(CURL_DISABLE_HTTP) && defined(USE_NTLM)

#include "urldata.h"
#include "vauth/vauth.h"
#ifdef USE_WINDOWS_SSPI
#include "curl_sspi.h"
#endif

typedef CURLcode (*Curl_ntlm_sspi_prep_fn)(struct connectdata *conn,
                                           struct ntlmdata *ntlm);

static CURL_INLINE CURLcode
curl_ntlm_prepare_sspi(struct connectdata *conn, struct ntlmdata *ntlm)
{
#ifdef USE_WINDOWS_SSPI
  if(ntlm) {
    if(!Curl_pSecFn) {
      CURLcode result = Curl_sspi_global_init();
      if(!Curl_pSecFn)
        return result;
    }
    if(conn)
      ntlm->sslContext = conn->sslContext;
  }
#else
  (void)conn;
  (void)ntlm;
#endif
  return CURLE_OK;
}

/* this is for NTLM header input */
CURLcode Curl_input_ntlm(struct Curl_easy *data, bool proxy,
                         const char *header,
                         struct connectdata *conn,
                         struct ntlmdata *ntlm,
                         curlntlm *state,
                         struct Curl_peer **conn_creds_origin,
                         struct Curl_creds **conn_creds);

/* this is for creating NTLM header output */
CURLcode Curl_output_ntlm(struct Curl_easy *data, bool proxy,
                          struct connectdata *conn,
                          struct ntlmdata *ntlm,
                          const char *hostname,
                          struct Curl_creds *creds,
                          curlntlm *state,
                          char **allocuserpwd,
                          struct auth *authp,
                          struct Curl_peer *origin,
                          struct Curl_peer **conn_creds_origin,
                          struct Curl_creds **conn_creds,
                          uint32_t *authpicked,
                          Curl_ntlm_sspi_prep_fn sspi_prep_fn);

#ifndef CURL_DISABLE_PROXY
#define Curl_input_ntlm(data, proxy, header) \
  Curl_input_ntlm((data), (proxy), (header), (data)->conn, \
    Curl_auth_ntlm_get((data)->conn, (proxy)), \
    (proxy) ? &(data)->conn->proxy_ntlm_state : &(data)->conn->http_ntlm_state, \
    &(data)->conn->creds_origin, &(data)->conn->creds)
#define Curl_output_ntlm(data, proxy) \
  Curl_output_ntlm((data), (proxy), (data)->conn, \
    Curl_auth_ntlm_get((data)->conn, (proxy)), \
    (proxy) ? (data)->conn->http_proxy.peer->hostname : \
              (data)->state.origin->hostname, \
    (proxy) ? (data)->conn->http_proxy.creds : (data)->state.creds, \
    (proxy) ? &(data)->conn->proxy_ntlm_state : &(data)->conn->http_ntlm_state, \
    (proxy) ? &(data)->req.hd_proxy_auth : &(data)->req.hd_auth, \
    (proxy) ? &(data)->state.authproxy : &(data)->state.authhost, \
    (data)->state.origin, &(data)->conn->creds_origin, &(data)->conn->creds, \
    (proxy) ? &(data)->info.proxyauthpicked : &(data)->info.httpauthpicked, \
    curl_ntlm_prepare_sspi)
#else
#define Curl_input_ntlm(data, proxy, header) \
  Curl_input_ntlm((data), (proxy), (header), (data)->conn, \
    Curl_auth_ntlm_get((data)->conn, FALSE), \
    &(data)->conn->http_ntlm_state, \
    &(data)->conn->creds_origin, &(data)->conn->creds)
#define Curl_output_ntlm(data, proxy) \
  Curl_output_ntlm((data), (proxy), (data)->conn, \
    Curl_auth_ntlm_get((data)->conn, FALSE), \
    (data)->state.origin->hostname, (data)->state.creds, \
    &(data)->conn->http_ntlm_state, &(data)->req.hd_auth, \
    &(data)->state.authhost, \
    (data)->state.origin, &(data)->conn->creds_origin, &(data)->conn->creds, \
    &(data)->info.httpauthpicked, \
    curl_ntlm_prepare_sspi)
#endif

#endif

#endif /* HEADER_CURL_HTTP_NTLM_H */
