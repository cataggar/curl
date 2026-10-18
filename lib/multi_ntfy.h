#ifndef HEADER_CURL_MULTI_NTFY_H
#define HEADER_CURL_MULTI_NTFY_H
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

#define CURL_MNTFY_FLAG_HAS_ENTRIES  ((uint32_t)1 << 31)

struct Curl_easy;
struct Curl_multi;

struct curl_multi_ntfy {
  curl_notify_callback ntfy_cb;
  void *ntfy_cb_data;
  struct mntfy_chunk *head;
  struct mntfy_chunk *tail;
  uint32_t flags;
  CURLMcode failure;
};

void Curl_mntfy_init(struct Curl_multi *multi, struct curl_multi_ntfy *ntfy);
#define Curl_mntfy_init(multi) \
  Curl_mntfy_init((multi), &((struct Curl_multi *)(multi))->ntfy)

void Curl_mntfy_cleanup(struct Curl_multi *multi,
                        struct curl_multi_ntfy *ntfy);
#define Curl_mntfy_cleanup(multi) \
  Curl_mntfy_cleanup((multi), &((struct Curl_multi *)(multi))->ntfy)

CURLMcode Curl_mntfy_enable(struct Curl_multi *multi,
                            struct curl_multi_ntfy *ntfy,
                            unsigned int type);
#define Curl_mntfy_enable(multi, type) \
  Curl_mntfy_enable((multi), &((struct Curl_multi *)(multi))->ntfy, (type))

CURLMcode Curl_mntfy_disable(struct Curl_multi *multi,
                             struct curl_multi_ntfy *ntfy,
                             unsigned int type);
#define Curl_mntfy_disable(multi, type) \
  Curl_mntfy_disable((multi), &((struct Curl_multi *)(multi))->ntfy, (type))

void Curl_mntfy_add(struct Curl_easy *data,
                    struct curl_multi_ntfy *ntfy,
                    uint32_t mid,
                    unsigned int type);
#define Curl_mntfy_add(data, type) \
  Curl_mntfy_add((data), (data)->multi ? &(data)->multi->ntfy : NULL, \
                 (data)->mid, (type))

#define CURLM_NTFY(d, t)                              \
  do {                                                \
    if((d) && (d)->multi && (d)->multi->ntfy.ntfy_cb) \
      Curl_mntfy_add((d), (t));                       \
  } while(0)

#define CURL_MNTFY_HAS_ENTRIES(m) \
  ((m)->ntfy.flags & CURL_MNTFY_FLAG_HAS_ENTRIES)

CURLMcode Curl_mntfy_dispatch_all(struct Curl_multi *multi,
                                  struct curl_multi_ntfy *ntfy,
                                  struct Curl_easy *admin);
#define Curl_mntfy_dispatch_all(multi) \
  Curl_mntfy_dispatch_all((multi), &(multi)->ntfy, (multi)->admin)

#endif /* HEADER_CURL_MULTI_NTFY_H */
