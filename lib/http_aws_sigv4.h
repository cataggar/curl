#ifndef HEADER_CURL_HTTP_AWS_SIGV4_H
#define HEADER_CURL_HTTP_AWS_SIGV4_H
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

#include "curlx/dynbuf.h"
#include "urldata.h"
#include "creds.h"

#if !defined(CURL_DISABLE_HTTP) && !defined(CURL_DISABLE_AWS)

CURLcode Curl_output_aws_sigv4_ex(struct Curl_easy *data,
                                  bool path_as_is,
                                  const char *provider_opt,
                                  const char *origin_hostname,
                                  const char *http_host,
                                  struct curl_slist *custom_headers,
                                  const char *postfields,
                                  curl_off_t postfieldsize,
                                  curl_off_t filesize,
                                  const char *up_query,
                                  const char *up_path,
                                  const char *user,
                                  const char *passwd,
                                  char **hd_auth,
                                  bool *auth_done);

/* this is for creating aws_sigv4 header output */
CURLcode Curl_output_aws_sigv4(struct Curl_easy *data);

static inline CURLcode curl_output_aws_sigv4_wrap(struct Curl_easy *data)
{
  bool auth_done = FALSE;
  CURLcode result = Curl_output_aws_sigv4_ex(
    data,
    data->set.path_as_is ? TRUE : FALSE,
    CURL_EASY_STR(data, STRING_AWS_SIGV4),
    data->state.origin ? data->state.origin->hostname : NULL,
    data->state.http_host,
    data->set.headers,
    (const char *)data->set.postfields,
    data->set.postfieldsize,
    data->set.filesize,
    data->state.up.query,
    data->state.up.path,
    Curl_creds_user(data->state.creds),
    Curl_creds_passwd(data->state.creds),
    &data->req.hd_auth,
    &auth_done);
  if(auth_done)
    data->state.authhost.done = TRUE;
  return result;
}

#ifdef HEADER_CURL_HTTP_NTLM_H
CURLcode Curl_aws_sigv4_dispatch(struct Curl_easy *data);
CURLcode Curl_aws_sigv4_dispatch(struct Curl_easy *data)
{
  return curl_output_aws_sigv4_wrap(data);
}
#endif

#define Curl_output_aws_sigv4(data) curl_output_aws_sigv4_wrap(data)

#endif /* !CURL_DISABLE_HTTP && !CURL_DISABLE_AWS */

#endif /* HEADER_CURL_HTTP_AWS_SIGV4_H */
