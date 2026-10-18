#ifndef HEADER_CURL_CF_SETUP_H
#define HEADER_CURL_CF_SETUP_H
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

struct Curl_creds;
struct Curl_dns_entry;
struct ip_quadruple;
struct Curl_peer;
struct Curl_str;

#ifdef USE_SSL
#define CURL_CF_SETUP_FLAG_USE_SSL 8u
#else
#define CURL_CF_SETUP_FLAG_USE_SSL 0u
#endif

CURLcode Curl_cf_setup_add(struct Curl_easy *data,
                           struct connectdata *conn,
                           int8_t sockindex,
                           uint8_t transport,
                           int ssl_mode,
                           struct Curl_peer *socks_peer,
                           struct Curl_creds *socks_creds,
                           struct Curl_peer *http_peer,
                           uint8_t socks_type,
                           uint8_t http_type,
                           uint8_t ip_version,
                           uint8_t setup_flags);
#define Curl_cf_setup_add(data, conn, sockindex, transport, ssl_mode) \
  Curl_cf_setup_add((data), (conn), (sockindex), (transport), (ssl_mode), \
    (conn)->socks_proxy.peer, (conn)->socks_proxy.creds, \
    (conn)->http_proxy.peer, (conn)->socks_proxy.proxytype, \
    (conn)->http_proxy.proxytype, (conn)->ip_version, \
    (uint8_t)(((conn)->bits.origin_is_proxy ? 1u : 0u) | \
              (((conn)->scheme->flags & PROTOPT_SSL) ? 2u : 0u) | \
              ((data)->set.haproxyprotocol ? 4u : 0u) | \
              CURL_CF_SETUP_FLAG_USE_SSL))

CURLcode Curl_cf_setup_insert_after(struct Curl_cfilter *cf_at,
                                    struct Curl_easy *data,
                                    uint8_t transport,
                                    int ssl_mode,
                                    struct Curl_peer *socks_peer,
                                    struct Curl_creds *socks_creds,
                                    struct Curl_peer *http_peer,
                                    uint8_t socks_type,
                                    uint8_t http_type,
                                    uint8_t ip_version,
                                    uint8_t setup_flags);
#define Curl_cf_setup_insert_after(cf_at, data, transport, ssl_mode) \
  Curl_cf_setup_insert_after((cf_at), (data), (transport), (ssl_mode), \
    (cf_at)->conn->socks_proxy.peer, (cf_at)->conn->socks_proxy.creds, \
    (cf_at)->conn->http_proxy.peer, (cf_at)->conn->socks_proxy.proxytype, \
    (cf_at)->conn->http_proxy.proxytype, (cf_at)->conn->ip_version, \
    (uint8_t)(((cf_at)->conn->bits.origin_is_proxy ? 1u : 0u) | \
              (((cf_at)->conn->scheme->flags & PROTOPT_SSL) ? 2u : 0u) | \
              ((data)->set.haproxyprotocol ? 4u : 0u) | \
              CURL_CF_SETUP_FLAG_USE_SSL))

extern struct Curl_cftype Curl_cft_setup;

#endif /* HEADER_CURL_CF_SETUP_H */
