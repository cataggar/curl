#ifndef HEADER_CURL_RTSP_H
#define HEADER_CURL_RTSP_H
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
#ifndef CURL_DISABLE_RTSP
CURLcode Curl_rtsp_parseheader(struct Curl_easy *data, const char *header);
extern const struct Curl_protocol Curl_protocol_rtsp;

struct connectdata *Curl_rtsp_get_conn(struct Curl_easy *data);
curl_socket_t Curl_rtsp_get_firstsocket(struct Curl_easy *data);
void Curl_rtsp_init_cseq(struct Curl_easy *data);
uint32_t Curl_rtsp_get_next_client_cseq(struct Curl_easy *data);
void Curl_rtsp_inc_next_client_cseq(struct Curl_easy *data);
void Curl_rtsp_set_cseq_recv(struct Curl_easy *data, uint32_t cseq);
unsigned char Curl_rtsp_get_rtspreq(struct Curl_easy *data);
bool Curl_rtsp_get_eos_written(struct Curl_easy *data);
void Curl_rtsp_set_no_body(struct Curl_easy *data, bool no_body);
void Curl_rtsp_set_httpreq(struct Curl_easy *data, unsigned char httpreq);
void Curl_rtsp_get_body_info(struct Curl_easy *data,
                             bool *pupload,
                             curl_off_t *pinfilesize,
                             void **ppostfields,
                             curl_off_t *ppostfieldsize,
                             bool *pcrlf);
void Curl_rtsp_get_request_info(struct Curl_easy *data,
                                const char **psession_id,
                                const char **pstream_uri,
                                const char **ptransport,
                                const char **pencoding,
                                const char **puseragent,
                                const char **preferer,
                                bool *puse_range,
                                const char **prange,
                                char ***prangeline);
void Curl_rtsp_get_auth_headers(struct Curl_easy *data,
                                const char **phd_proxy_auth,
                                const char **phd_auth);
bool Curl_rtsp_allow_session_to_host(struct Curl_easy *data);
curl_off_t Curl_rtsp_get_writebytecount(struct Curl_easy *data);
void Curl_rtsp_get_req_state(struct Curl_easy *data,
                             int *pheaderline,
                             bool *pheader,
                             curl_off_t *psize,
                             curl_off_t *pbytecount,
                             bool *pdone);
void Curl_rtsp_set_req_size_zero_done(struct Curl_easy *data);
void Curl_rtsp_set_download_done(struct Curl_easy *data);
void Curl_rtsp_set_req_done_false(struct Curl_easy *data);
void Curl_rtsp_get_rtp_writer(struct Curl_easy *data,
                              curl_write_callback *pwriteit,
                              void **puser_ptr);
unsigned char *Curl_rtsp_get_rtp_channel_mask(struct Curl_easy *data);
const char *Curl_rtsp_get_session_id(struct Curl_easy *data);
CURLcode Curl_rtsp_set_session_id(struct Curl_easy *data, char *mem);
#else
#define Curl_rtsp_parseheader(x, y) CURLE_NOT_BUILT_IN
#endif

#define RTSPREQ_NONE CURL_RTSPREQ_NONE
#define RTSPREQ_OPTIONS CURL_RTSPREQ_OPTIONS
#define RTSPREQ_DESCRIBE CURL_RTSPREQ_DESCRIBE
#define RTSPREQ_ANNOUNCE CURL_RTSPREQ_ANNOUNCE
#define RTSPREQ_SETUP CURL_RTSPREQ_SETUP
#define RTSPREQ_PLAY CURL_RTSPREQ_PLAY
#define RTSPREQ_PAUSE CURL_RTSPREQ_PAUSE
#define RTSPREQ_TEARDOWN CURL_RTSPREQ_TEARDOWN
#define RTSPREQ_GET_PARAMETER CURL_RTSPREQ_GET_PARAMETER
#define RTSPREQ_SET_PARAMETER CURL_RTSPREQ_SET_PARAMETER
#define RTSPREQ_RECORD CURL_RTSPREQ_RECORD
#define RTSPREQ_RECEIVE CURL_RTSPREQ_RECEIVE
#define RTSPREQ_LAST CURL_RTSPREQ_LAST

#endif /* HEADER_CURL_RTSP_H */
