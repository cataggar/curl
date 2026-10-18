#ifndef HEADER_CURL_HTTP_HTTPSIG_H
#define HEADER_CURL_HTTP_HTTPSIG_H
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

#if !defined(CURL_DISABLE_HTTP) && !defined(CURL_DISABLE_HTTPSIG)

#include "urldata.h"
#include "curlx/strparse.h"
#include <time.h>

static CURL_INLINE int64_t curl_httpsig_get_created(void)
{
#ifdef DEBUGBUILD
  char *force = getenv("CURL_FORCETIME");
  if(force && *force) {
    char *sigts = getenv("CURL_HTTPSIG_CREATED");
    if(sigts && *sigts) {
      const char *p = sigts;
      curl_off_t num;
      if(!curlx_str_number(&p, &num, CURL_OFF_T_MAX))
        return (int64_t)num;
    }
    return 0;
  }
#endif
  return (int64_t)time(NULL);
}

CURLcode Curl_output_httpsig(struct Curl_easy *data,
                             uint8_t alg_id,
                             const char *hexkey,
                             const char *keyid,
                             const char *hdr_list,
                             const char *http_host,
                             const char *up_path,
                             const char *up_query,
                             struct curl_slist *headers,
                             const char *origin_hostname,
                             uint16_t origin_port,
                             uint16_t origin_defport,
                             int64_t created,
                             char **hd_auth,
                             struct auth *authhost,
                             const char *method_override);
#define Curl_output_httpsig(data) \
  Curl_output_httpsig((data), \
    (data)->set.httpsig_algorithm, \
    CURL_EASY_STR((data), STRING_HTTPSIG_KEY), \
    CURL_EASY_STR((data), STRING_HTTPSIG_KEYID), \
    CURL_EASY_STR((data), STRING_HTTPSIG_HEADERS), \
    (data)->state.http_host, \
    (data)->state.up.path, \
    (data)->state.up.query, \
    (data)->set.headers, \
    (data)->conn->origin->hostname, \
    (data)->conn->origin->port, \
    (uint16_t)(data)->conn->origin->scheme->defport, \
    curl_httpsig_get_created(), \
    &(data)->req.hd_auth, \
    &(data)->state.authhost, \
    NULL)

#endif /* !CURL_DISABLE_HTTP && !CURL_DISABLE_HTTPSIG */
#endif /* HEADER_CURL_HTTP_HTTPSIG_H */
