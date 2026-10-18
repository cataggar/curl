#ifndef HEADER_CURL_HEADER_H
#define HEADER_CURL_HEADER_H
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

#if !defined(CURL_DISABLE_HTTP) && !defined(CURL_DISABLE_HEADERS_API)

#include "urldata.h"

struct Curl_header_store {
  struct Curl_llist_node node;
  char *name; /* points into 'buffer' */
  char *value; /* points into 'buffer' */
  size_t nh_amount; /* cached amount for curl_easy_nextheader() */
  size_t nh_index; /* cached index for curl_easy_nextheader() */
  int request; /* 0 is the first request, then 1.. 2.. */
  unsigned char type; /* CURLH_* defines */
  char buffer[1]; /* this is the raw header blob */
};

void Curl_headers_Register(struct Curl_easy *data,
                           struct Curl_llist *httphdrs,
                           struct curl_header *headerout,
                           unsigned int *nh_origin,
                           int *nh_request,
                           size_t *nh_count,
                           int *requests);

CURLcode Curl_headers_init_ex(struct Curl_easy *data, unsigned int protocol);

/*
 * Initialize header collecting for a transfer.
 * Add a client writer that catches CLIENTWRITE_HEADER writes.
 */
CURLcode Curl_headers_init(struct Curl_easy *data);

/*
 * Curl_headers_push() gets passed a full header to store.
 */
CURLcode Curl_headers_push(struct Curl_easy *data, const char *header,
                           size_t hlen, unsigned char type);

/*
 * Curl_headers_cleanup(). Free all stored headers and associated memory.
 */
CURLcode Curl_headers_cleanup(struct Curl_easy *data);

static inline CURLcode curl_headers_init_wrap(struct Curl_easy *data)
{
  if(data) {
    unsigned int proto = (data->conn && data->conn->scheme) ?
                         data->conn->scheme->protocol : 0;
    Curl_headers_Register(data, &data->state.httphdrs, data->state.headerout,
                          &data->state.nh_origin, &data->state.nh_request,
                          &data->state.nh_count, &data->state.requests);
    return Curl_headers_init_ex(data, proto);
  }
  return CURLE_OK;
}

static inline CURLcode curl_headers_push_wrap(struct Curl_easy *data,
                                              const char *header,
                                              size_t hlen,
                                              unsigned char type)
{
  if(data) {
    Curl_headers_Register(data, &data->state.httphdrs, data->state.headerout,
                          &data->state.nh_origin, &data->state.nh_request,
                          &data->state.nh_count, &data->state.requests);
  }
  return Curl_headers_push(data, header, hlen, type);
}

static inline CURLcode curl_headers_cleanup_wrap(struct Curl_easy *data)
{
  if(data) {
    Curl_headers_Register(data, &data->state.httphdrs, data->state.headerout,
                          &data->state.nh_origin, &data->state.nh_request,
                          &data->state.nh_count, &data->state.requests);
  }
  return Curl_headers_cleanup(data);
}

#ifdef HEADER_CURL_VSSH_VSSH_H
#include "cshutdn.h"

void Curl_headers_auto_register(struct Curl_easy *data);
void Curl_headers_auto_register(struct Curl_easy *data)
{
  if(data) {
    Curl_headers_Register(data, &data->state.httphdrs, data->state.headerout,
                          &data->state.nh_origin, &data->state.nh_request,
                          &data->state.nh_count, &data->state.requests);
  }
}

unsigned int Curl_headers_get_protocol(struct Curl_easy *data);
unsigned int Curl_headers_get_protocol(struct Curl_easy *data)
{
  return (data && data->conn && data->conn->scheme) ?
         data->conn->scheme->protocol : 0;
}
#endif

#define Curl_headers_init(data) curl_headers_init_wrap(data)
#define Curl_headers_push(data, header, hlen, type) \
  curl_headers_push_wrap(data, header, hlen, type)
#define Curl_headers_cleanup(data) curl_headers_cleanup_wrap(data)

#else
#define Curl_headers_init(x)          CURLE_OK
#define Curl_headers_push(x, y, z, a) \
  ((void)(x), (void)(y), (void)(z), (void)(a), CURLE_OK)
#define Curl_headers_cleanup(x)       Curl_nop_stmt
#endif

#endif /* HEADER_CURL_HEADER_H */
