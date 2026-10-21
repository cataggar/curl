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

#ifdef HAVE_LIMITS_H
#include <limits.h>
#endif

#include "urldata.h"
#include "mime.h"
#include "vtls/vtls.h"
#include "transfer.h"
#include "sendf.h"
#include "progress.h"
#include "cookie.h"
#include "strcase.h"
#include "escape.h"
#include "vssh/ssh.h"
#include "vssh/vssh.h"
#include "headers.h"
#include "curl_share.h"
#include "vtls/vtls_scache.h"
#include "http_digest.h"
#include "select.h"
#include "multiif.h"
#include "multi_ev.h"
#include "ftp.h"
#include "cw-out.h"
#include "curl_ldap.h"
#include "hsts.h"
#include "url.h"
#include "cfilters.h"
#include "connect.h"
#include "psl.h"
#include "curl_trc.h"
#include "http.h"
#include "curlx/wait.h"
#include "conncache.h"
#include "multihandle.h"
#include "sigpipe.h"
#include "http_proxy.h"
#include "http2.h"
#include "socketpair.h"
#include "bufref.h"
#include "curlx/strdup.h"
#include "altsvc.h"
#include "curlx/dynbuf.h"
#include "curlx/strparse.h"

/* initial multi->xfers table size for a full multi */
#define CURL_XFER_TABLE_SIZE 128

/* CURL_SOCKET_HASH_TABLE_SIZE should be a prime number. Increasing it from 97
   to 911 takes on a 32-bit machine 4 x 804 = 3211 more bytes. Still, every
   curl handle takes 6K memory, therefore this 3K are not significant. */
#ifndef CURL_SOCKET_HASH_TABLE_SIZE
#define CURL_SOCKET_HASH_TABLE_SIZE 911
#endif

#ifndef CURL_CONNECTION_HASH_SIZE
#define CURL_CONNECTION_HASH_SIZE 97
#endif

#ifndef CURL_DNS_HASH_SIZE
#define CURL_DNS_HASH_SIZE 71
#endif

#ifndef CURL_TLS_SESSION_SIZE
#define CURL_TLS_SESSION_SIZE 25
#endif

#include "mime.h"
#include "vssh/vssh.h"
#include "curl_addrinfo.h"
#include "cookie.h"
#include "escape.h"
#include "http_digest.h"
#include "pop3.h"
#include "urlapi-int.h"
#include "proxy.h"
#include "idn.h"
#include "setopt.h"
#include "headers.h"
#include "curlx/strerr.h"
#include "peer.h"
#include "ftp.h"
#include "dict.h"
#include "telnet.h"
#include "tftp.h"
#include "vauth/vauth.h"
#include "file.h"
#include "vssh/ssh.h"
#include "imap.h"

/* C ABI forwarders to Zig-ported Session 30 functions (api, getinfo,
 * request, multi_ev) that unpack struct Curl_easy / struct Curl_multi
 * fields while preserving original C symbol signatures across modules. */
#include "getinfo.h"
#include "request.h"

bool Curl_eapi_enter_zig(struct Curl_eapi_guard *guard, CURL *curl,
                         bool is_internal, unsigned int fn,
                         CURLcode *presult);

bool Curl_eapi_enter(struct Curl_eapi_guard *guard,
                     CURL *curl,
                     Curl_eapi_fn fn,
                     CURLcode *presult)
{
  return Curl_eapi_enter_zig(guard, curl,
                             curl &&
                             ((struct Curl_easy *)curl)->state.internal,
                             (unsigned int)fn, presult);
}

struct Curl_getinfo_ctx {
  struct PureInfo *info;
  struct curl_tlssessioninfo *tsi;
  const char *url_str;
  const char *referer_str;
  const char *custom_request;
  const char *ftp_entrypath;
  const char *rtsp_session_id;
  const char *cainfo_default;
  const char *capath_default;
  void *private_data;
  int64_t xfer_id;
  int64_t last_conn_id;
  int64_t deliver;
  int64_t earlydata_sent;
  int64_t ul_total_size;
  int64_t ul_cur_size;
  int64_t ul_speed;
  int64_t dl_total_size;
  int64_t dl_cur_size;
  int64_t dl_speed;
  int64_t spent_us;
  int64_t queued_us;
  int64_t nslookup_us;
  int64_t connect_us;
  int64_t appconnect_us;
  int64_t pretransfer_us;
  int64_t starttransfer_us;
  int64_t posttransfer_us;
  int64_t startredirect_us;
  long ssl_verifyresult;
  long proxy_ssl_verifyresult;
  uint32_t rtsp_next_client_CSeq;
  uint32_t rtsp_next_server_CSeq;
  uint32_t rtsp_CSeq_recv;
  int os_errno;
  uint16_t followlocation;
  uint8_t httpreq;
  uint8_t path_as_is;
  uint8_t opt_no_body;
  uint8_t timecond;
  uint8_t used_proxy;
  uint8_t ul_size_known;
  uint8_t dl_size_known;
};

void Curl_initinfo_zig(struct Curl_easy *data,
                       void *pro_delta,
                       void *pro_total,
                       struct PureInfo *info);
CURLcode Curl_getinfo_zig(struct Curl_easy *data,
                          const struct Curl_getinfo_ctx *ctx,
                          CURLINFO info,
                          void *param);

void Curl_initinfo(struct Curl_easy *data)
{
  if(data) {
    Curl_initinfo_zig(data, &data->progress.delta,
                      &data->progress.total, &data->info);
    data->progress.startransfer_added = FALSE;
    data->info.timecond = FALSE;
    data->info.used_proxy = 0;
  }
}

CURLcode Curl_getinfo(struct Curl_easy *data, CURLINFO info, ...)
{
  va_list arg;
  void *paramp;
  struct Curl_getinfo_ctx ctx;
  if(!data)
    return CURLE_BAD_FUNCTION_ARGUMENT;
  va_start(arg, info);
  paramp = va_arg(arg, void *);
  va_end(arg);
  ctx.info = &data->info;
  ctx.tsi = &data->tsi;
  ctx.url_str = Curl_bufref_ptr(&data->state.url);
  ctx.referer_str = Curl_bufref_ptr(&data->state.referer);
  ctx.custom_request = CURL_EASY_STR(data, STRING_CUSTOMREQUEST);
  ctx.ftp_entrypath = data->state.most_recent_ftp_entrypath;
#ifndef CURL_DISABLE_RTSP
  ctx.rtsp_session_id = CURL_EASY_STR(data, STRING_RTSP_SESSION_ID);
#else
  ctx.rtsp_session_id = NULL;
#endif
#ifdef CURL_CA_BUNDLE
  ctx.cainfo_default = CURL_CA_BUNDLE;
#else
  ctx.cainfo_default = NULL;
#endif
#ifdef CURL_CA_PATH
  ctx.capath_default = CURL_CA_PATH;
#else
  ctx.capath_default = NULL;
#endif
  ctx.private_data = data->set.private_data;
  ctx.xfer_id = data->id;
  ctx.last_conn_id = data->state.last_conn_id;
  ctx.deliver = data->progress.deliver;
  ctx.earlydata_sent = data->progress.earlydata_sent;
  ctx.ul_total_size = data->progress.ul.total_size;
  ctx.ul_cur_size = data->progress.ul.cur_size;
  ctx.ul_speed = data->progress.ul.speed;
  ctx.dl_total_size = data->progress.dl.total_size;
  ctx.dl_cur_size = data->progress.dl.cur_size;
  ctx.dl_speed = data->progress.dl.speed;
  ctx.spent_us = data->progress.total.spent_us;
  ctx.queued_us = data->progress.total.queued_us;
  ctx.nslookup_us = data->progress.total.nslookup_us;
  ctx.connect_us = data->progress.total.connect_us;
  ctx.appconnect_us = data->progress.total.appconnect_us;
  ctx.pretransfer_us = data->progress.total.pretransfer_us;
  ctx.starttransfer_us = data->progress.total.starttransfer_us;
  ctx.posttransfer_us = data->progress.total.posttransfer_us;
  ctx.startredirect_us = data->progress.delta.startredirect_us;
  ctx.ssl_verifyresult = data->set.ssl.certverifyresult;
#ifndef CURL_DISABLE_PROXY
  ctx.proxy_ssl_verifyresult = data->set.proxy_ssl.certverifyresult;
#else
  ctx.proxy_ssl_verifyresult = 0;
#endif
#ifndef CURL_DISABLE_RTSP
  ctx.rtsp_next_client_CSeq = data->state.rtsp_next_client_CSeq;
  ctx.rtsp_next_server_CSeq = data->state.rtsp_next_server_CSeq;
  ctx.rtsp_CSeq_recv = data->state.rtsp_CSeq_recv;
#else
  ctx.rtsp_next_client_CSeq = 0;
  ctx.rtsp_next_server_CSeq = 0;
  ctx.rtsp_CSeq_recv = 0;
#endif
  ctx.os_errno = data->state.os_errno;
  ctx.followlocation = data->state.followlocation;
  ctx.httpreq = data->state.httpreq;
  ctx.path_as_is = data->set.path_as_is ? 1 : 0;
  ctx.opt_no_body = data->set.opt_no_body ? 1 : 0;
  ctx.timecond = data->info.timecond ? 1 : 0;
#ifndef CURL_DISABLE_PROXY
  ctx.used_proxy = data->info.used_proxy ? 1 : 0;
#else
  ctx.used_proxy = 0;
#endif
  ctx.ul_size_known = data->progress.ul_size_known ? 1 : 0;
  ctx.dl_size_known = data->progress.dl_size_known ? 1 : 0;
  return Curl_getinfo_zig(data, &ctx, info, paramp);
}

CURLcode Curl_req_soft_reset_zig(struct SingleRequest *req,
                                 struct Curl_easy *data,
                                 uint32_t upload_buffer_size);
CURLcode Curl_req_start_zig(struct SingleRequest *req,
                            struct Curl_easy *data,
                            uint32_t upload_buffer_size);
CURLcode Curl_req_done_zig(struct SingleRequest *req,
                           struct Curl_easy *data, bool aborted,
                           curl_off_t max_send_speed);
void Curl_req_hard_reset_zig(struct SingleRequest *req,
                             struct Curl_easy *data,
                             bool opt_no_body,
                             void *dl_rlimit,
                             void *ul_rlimit);
CURLcode Curl_req_send_zig(struct Curl_easy *data,
                           struct SingleRequest *sreq,
                           struct dynbuf *req,
                           unsigned char httpversion,
                           curl_off_t max_send_speed);
bool Curl_req_sendbuf_empty_zig(struct SingleRequest *sreq);
bool Curl_req_want_send_zig(struct Curl_easy *data,
                            struct SingleRequest *sreq,
                            const void *ul_rlimit);
bool Curl_req_want_recv_zig(struct SingleRequest *sreq,
                            const void *dl_rlimit);
bool Curl_req_done_sending_zig(struct Curl_easy *data,
                               struct SingleRequest *sreq,
                               const void *ul_rlimit);
CURLcode Curl_req_send_more_zig(struct Curl_easy *data,
                                struct SingleRequest *sreq,
                                curl_off_t max_send_speed);
CURLcode Curl_req_abort_sending_zig(struct Curl_easy *data,
                                    struct SingleRequest *sreq);
CURLcode Curl_req_stop_send_recv_zig(struct Curl_easy *data,
                                     struct SingleRequest *sreq);

CURLcode Curl_req_soft_reset(struct SingleRequest *req,
                             struct Curl_easy *data)
{
  return Curl_req_soft_reset_zig(req, data, data->set.upload_buffer_size);
}

CURLcode Curl_req_start(struct SingleRequest *req,
                        struct Curl_easy *data)
{
  return Curl_req_start_zig(req, data, data->set.upload_buffer_size);
}

CURLcode Curl_req_done(struct SingleRequest *req,
                       struct Curl_easy *data, bool aborted)
{
  return Curl_req_done_zig(req, data, aborted, data->set.max_send_speed);
}

void Curl_req_hard_reset(struct SingleRequest *req,
                         struct Curl_easy *data)
{
  Curl_req_hard_reset_zig(req, data, (bool)data->set.opt_no_body,
                          &data->progress.dl.rlimit,
                          &data->progress.ul.rlimit);
}

CURLcode Curl_req_send(struct Curl_easy *data, struct dynbuf *req,
                       unsigned char httpversion)
{
  return Curl_req_send_zig(data, &data->req, req, httpversion,
                           data->set.max_send_speed);
}

bool Curl_req_sendbuf_empty(struct Curl_easy *data)
{
  return Curl_req_sendbuf_empty_zig(&data->req);
}

bool Curl_req_want_send(struct Curl_easy *data)
{
  return Curl_req_want_send_zig(data, &data->req, &data->progress.ul.rlimit);
}

bool Curl_req_want_recv(struct Curl_easy *data)
{
  return Curl_req_want_recv_zig(&data->req, &data->progress.dl.rlimit);
}

bool Curl_req_done_sending(struct Curl_easy *data)
{
  return Curl_req_done_sending_zig(data, &data->req,
                                   &data->progress.ul.rlimit);
}

CURLcode Curl_req_send_more(struct Curl_easy *data)
{
  return Curl_req_send_more_zig(data, &data->req, data->set.max_send_speed);
}

CURLcode Curl_req_abort_sending(struct Curl_easy *data)
{
  return Curl_req_abort_sending_zig(data, &data->req);
}

CURLcode Curl_req_stop_send_recv(struct Curl_easy *data)
{
  return Curl_req_stop_send_recv_zig(data, &data->req);
}

void Curl_multi_ev_init_zig(struct Curl_multi *multi,
                            struct curl_multi_ev *ev,
                            size_t hashsize);
void Curl_multi_ev_cleanup_zig(struct Curl_multi *multi,
                               struct curl_multi_ev *ev);
CURLMcode Curl_multi_ev_assign_zig(struct Curl_multi *multi,
                                   struct curl_multi_ev *ev,
                                   curl_socket_t s,
                                   void *user_data);
CURLMcode Curl_multi_ev_assess_xfer_zig(struct Curl_multi *multi,
                                        struct curl_multi_ev *ev,
                                        struct Curl_easy *data);
CURLMcode Curl_multi_ev_assess_conn_zig(struct Curl_multi *multi,
                                        struct curl_multi_ev *ev,
                                        struct Curl_easy *data,
                                        struct connectdata *conn);
CURLMcode Curl_multi_ev_assess_xfer_bset_zig(struct Curl_multi *multi,
                                             struct curl_multi_ev *ev,
                                             struct uint32_bset *set);
void Curl_multi_ev_dirty_xfers_zig(struct Curl_multi *multi,
                                   struct curl_multi_ev *ev,
                                   curl_socket_t s);
CURLMcode Curl_multi_ev_socket_done_zig(struct Curl_multi *multi,
                                        struct curl_multi_ev *ev,
                                        struct Curl_easy *data,
                                        curl_socket_t s);
CURLMcode Curl_multi_ev_xfer_done_zig(struct Curl_multi *multi,
                                      struct curl_multi_ev *ev,
                                      struct Curl_easy *data);
CURLMcode Curl_multi_ev_conn_done_zig(struct Curl_multi *multi,
                                      struct curl_multi_ev *ev,
                                      struct Curl_easy *data,
                                      struct connectdata *conn);

void Curl_multi_ev_init(struct Curl_multi *multi, size_t hashsize)
{
  Curl_multi_ev_init_zig(multi, &multi->ev, hashsize);
}

void Curl_multi_ev_cleanup(struct Curl_multi *multi)
{
  Curl_multi_ev_cleanup_zig(multi, &multi->ev);
}

CURLMcode Curl_multi_ev_assign(struct Curl_multi *multi,
                               curl_socket_t s,
                               void *user_data)
{
  return Curl_multi_ev_assign_zig(multi, &multi->ev, s, user_data);
}

CURLMcode Curl_multi_ev_assess_xfer(struct Curl_multi *multi,
                                    struct Curl_easy *data)
{
  CURLMcode r = Curl_multi_ev_assess_xfer_zig(multi, &multi->ev, data);
  if(r == CURLM_ABORTED_BY_CALLBACK)
    multi->dead = TRUE;
  return r;
}

CURLMcode Curl_multi_ev_assess_conn(struct Curl_multi *multi,
                                    struct Curl_easy *data,
                                    struct connectdata *conn)
{
  CURLMcode r = Curl_multi_ev_assess_conn_zig(multi, &multi->ev, data, conn);
  if(r == CURLM_ABORTED_BY_CALLBACK)
    multi->dead = TRUE;
  return r;
}

CURLMcode Curl_multi_ev_assess_xfer_bset(struct Curl_multi *multi,
                                         struct uint32_bset *set)
{
  CURLMcode r = Curl_multi_ev_assess_xfer_bset_zig(multi, &multi->ev, set);
  if(r == CURLM_ABORTED_BY_CALLBACK)
    multi->dead = TRUE;
  return r;
}

void Curl_multi_ev_dirty_xfers(struct Curl_multi *multi, curl_socket_t s)
{
  Curl_multi_ev_dirty_xfers_zig(multi, &multi->ev, s);
}

void Curl_multi_ev_socket_done(struct Curl_multi *multi,
                               struct Curl_easy *data, curl_socket_t s)
{
  if(Curl_multi_ev_socket_done_zig(multi, &multi->ev, data, s) ==
     CURLM_ABORTED_BY_CALLBACK)
    multi->dead = TRUE;
}

void Curl_multi_ev_xfer_done(struct Curl_multi *multi,
                             struct Curl_easy *data)
{
  if(Curl_multi_ev_xfer_done_zig(multi, &multi->ev, data) ==
     CURLM_ABORTED_BY_CALLBACK)
    multi->dead = TRUE;
}

void Curl_multi_ev_conn_done(struct Curl_multi *multi,
                             struct Curl_easy *data,
                             struct connectdata *conn)
{
  if(Curl_multi_ev_conn_done_zig(multi, &multi->ev, data, conn) ==
     CURLM_ABORTED_BY_CALLBACK)
    multi->dead = TRUE;
}

#include "vtls/vtls_scache.h"
#include "cookie.h"

bool Curl_api_scache_is_locked(struct Curl_easy *data)
{
#ifdef USE_SSL
  return Curl_ssl_scache_is_locked_by_current_thread(data);
#else
  (void)data;
  return FALSE;
#endif
}

struct curl_slist *Curl_getinfo_cookie_list(struct Curl_easy *data)
{
#ifndef CURL_DISABLE_COOKIES
  return Curl_cookie_list(data);
#else
  (void)data;
  return NULL;
#endif
}

/* -------------------------------------------------------------------------
 * Phase 8 Session 42: setopt.zig C struct-field accessors & va_list shim
 * ------------------------------------------------------------------------- */
#include "setopt.h"

void *Curl_easy_strset_ptr(struct Curl_easy *data)
{
  return &data->set.strings;
}

struct curl_blob **Curl_easy_blob_ptr(struct Curl_easy *data, unsigned int idx)
{
  return &data->set.blobs[idx];
}

void *Curl_setopt_default_stderr(void)
{
  return (void *)stderr;
}

#if defined(__clang__) && __clang_major__ >= 16
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wcast-function-type-strict"
#endif
void *Curl_setopt_default_fwrite(void)
{
  return (void *)(curl_write_callback)fwrite;
}

void *Curl_setopt_default_fread(void)
{
  return (void *)(curl_read_callback)fread;
}
#if defined(__clang__) && __clang_major__ >= 16
#pragma clang diagnostic pop
#endif

bool Curl_setopt_trc_bind_is_verbose(struct Curl_easy *data)
{
#ifndef CURL_DISABLE_VERBOSE_STRINGS
  return Curl_trc_is_verbose(data);
#else
  (void)data;
  return FALSE;
#endif
}

bool Curl_setopt_get_bit(struct Curl_easy *data, int bit_id)
{
  struct UserDefined *s = &data->set;
  switch(bit_id) {
  case 1: return s->reuse_forbid;
  case 2: return s->reuse_fresh;
  case 3: return s->verbose;
  case 4: return s->include_header;
  case 5: return data->progress.hide;
  case 6: return s->opt_no_body;
  case 7: return s->http_fail_on_error;
  case 8: return s->http_keep_sending_on_error;
  case 9: return s->get_filetime;
#ifndef CURL_DISABLE_HTTP
  case 10: return s->http09_allowed;
#ifndef CURL_DISABLE_COOKIES
  case 11: return s->cookiesession;
#endif
  case 12: return s->http_auto_referer;
  case 13: return s->http_transfer_encoding;
  case 14: return s->allow_auth_to_other_hosts;
  case 15: return s->http_te_skip;
  case 16: return s->http_ce_skip;
#endif
#ifndef CURL_DISABLE_PROXY
  case 17: return s->tunnel_thru_httpproxy;
  case 18: return s->haproxyprotocol;
  case 19: return s->proxy_ssl.verifypeer;
  case 20: return s->proxy_ssl.verifyhost;
  case 21: return s->proxy_transfer_mode;
#endif
#if defined(HAVE_GSSAPI) || defined(USE_WINDOWS_SSPI)
  case 22: return s->socks5_gssapi_nec;
#endif
#ifdef CURL_LIST_ONLY_PROTOCOL
  case 23: return s->list_only;
#endif
  case 24: return s->remote_append;
#ifndef CURL_DISABLE_FTP
  case 25: return s->ftp_use_eprt;
  case 26: return s->ftp_use_epsv;
  case 27: return s->ftp_use_pret;
  case 28: return s->ftp_skip_ip;
  case 29: return s->wildcard_enabled;
#endif
  case 30: return s->crlf;
#ifndef CURL_DISABLE_TFTP
  case 31: return s->tftp_no_options;
#endif
  case 32: return s->prefer_ascii;
  case 33: return s->ssl.verifypeer;
#ifndef CURL_DISABLE_DOH
  case 34: return s->doh_verifypeer;
  case 35: return s->doh_verifyhost;
  case 36: return s->doh_verifystatus;
#endif
  case 37: return s->ssl.verifyhost;
  case 38: return s->ssl.verifystatus;
#ifdef USE_SSL
  case 39: return s->ssl.certinfo;
#endif
  case 40: return s->no_signal;
  case 41: return s->tcp_nodelay;
  case 42: return s->ignorecl;
  case 43: return s->ssl.cache_session;
#ifndef CURL_DISABLE_PROXY
  case 44: return s->proxy_ssl.cache_session;
#endif
#ifdef USE_SSH
  case 45: return s->ssh_compression;
#endif
#ifndef CURL_DISABLE_SMTP
  case 46: return s->mail_rcpt_allowfails;
#endif
  case 47: return s->sasl_ir;
  case 48: return s->tcp_keepalive;
  case 49: return s->tcp_fastopen;
  case 50: return s->ssl_enable_alpn;
  case 51: return s->path_as_is;
  case 52: return s->pipewait;
  case 53: return s->suppress_connect_headers;
#ifndef CURL_DISABLE_SHUFFLE_DNS
  case 54: return s->dns_shuffle_addresses;
#endif
  case 55: return s->disallow_username_in_url;
  case 56: return s->quick_exit;
  case 57: return s->connect_only;
  case 58: return s->connect_only_ws;
#ifdef USE_OPENSSL
  case 59: return s->engine_default;
#endif
#ifndef CURL_DISABLE_PROXY
  case 60: return s->socks5_auth_only;
#endif
#ifndef CURL_DISABLE_HTTP
  case 61: return s->post301;
  case 62: return s->post302;
  case 63: return s->post303;
  case 64: return s->sep_headers;
#endif
#ifndef CURL_DISABLE_WEBSOCKETS
  case 65: return s->ws_raw_mode;
  case 66: return s->ws_no_auto_pong;
#endif
#ifndef CURL_DISABLE_MIME
  case 67: return s->mime_formescape;
#endif
#if !defined(CURL_DISABLE_HTTP) && !defined(CURL_DISABLE_COOKIES)
  case 68: return data->state.cookie_engine;
#endif
#ifndef CURL_DISABLE_PROXY
  case 69: return s->proxy_ssl.custom_cafile;
  case 70: return s->proxy_ssl.custom_capath;
#endif
  case 71: return s->ssl.custom_cafile;
  case 72: return s->ssl.custom_capath;
#ifndef CURL_DISABLE_FTP
  case 73: return s->ftp_use_port;
#endif
#ifdef USE_UNIX_SOCKETS
  case 74: return s->abstract_unix_socket;
#endif
#ifndef CURL_DISABLE_DOH
  case 75: return s->doh;
#endif
  case 76: return data->progress.callback;
  case 77: return s->is_fread_set;
#ifndef CURL_DISABLE_PROXY
  case 78: return s->proxy_ssl.custom_cablob;
#endif
  case 79: return s->ssl.custom_cablob;
  default: return FALSE;
  }
}

void Curl_setopt_set_bit(struct Curl_easy *data, int bit_id, bool val)
{
  struct UserDefined *s = &data->set;
  switch(bit_id) {
  case 1: s->reuse_forbid = val; break;
  case 2: s->reuse_fresh = val; break;
  case 3: s->verbose = val; break;
  case 4: s->include_header = val; break;
  case 5: data->progress.hide = val; break;
  case 6: s->opt_no_body = val; break;
  case 7: s->http_fail_on_error = val; break;
  case 8: s->http_keep_sending_on_error = val; break;
  case 9: s->get_filetime = val; break;
#ifndef CURL_DISABLE_HTTP
  case 10: s->http09_allowed = val; break;
#ifndef CURL_DISABLE_COOKIES
  case 11: s->cookiesession = val; break;
#endif
  case 12: s->http_auto_referer = val; break;
  case 13: s->http_transfer_encoding = val; break;
  case 14: s->allow_auth_to_other_hosts = val; break;
  case 15: s->http_te_skip = val; break;
  case 16: s->http_ce_skip = val; break;
#endif
#ifndef CURL_DISABLE_PROXY
  case 17: s->tunnel_thru_httpproxy = val; break;
  case 18: s->haproxyprotocol = val; break;
  case 19: s->proxy_ssl.verifypeer = val; break;
  case 20: s->proxy_ssl.verifyhost = val; break;
  case 21: s->proxy_transfer_mode = val; break;
#endif
#if defined(HAVE_GSSAPI) || defined(USE_WINDOWS_SSPI)
  case 22: s->socks5_gssapi_nec = val; break;
#endif
#ifdef CURL_LIST_ONLY_PROTOCOL
  case 23: s->list_only = val; break;
#endif
  case 24: s->remote_append = val; break;
#ifndef CURL_DISABLE_FTP
  case 25: s->ftp_use_eprt = val; break;
  case 26: s->ftp_use_epsv = val; break;
  case 27: s->ftp_use_pret = val; break;
  case 28: s->ftp_skip_ip = val; break;
  case 29: s->wildcard_enabled = val; break;
#endif
  case 30: s->crlf = val; break;
#ifndef CURL_DISABLE_TFTP
  case 31: s->tftp_no_options = val; break;
#endif
  case 32: s->prefer_ascii = val; break;
  case 33: s->ssl.verifypeer = val; break;
#ifndef CURL_DISABLE_DOH
  case 34: s->doh_verifypeer = val; break;
  case 35: s->doh_verifyhost = val; break;
  case 36: s->doh_verifystatus = val; break;
#endif
  case 37: s->ssl.verifyhost = val; break;
  case 38: s->ssl.verifystatus = val; break;
#ifdef USE_SSL
  case 39: s->ssl.certinfo = val; break;
#endif
  case 40: s->no_signal = val; break;
  case 41: s->tcp_nodelay = val; break;
  case 42: s->ignorecl = val; break;
  case 43: s->ssl.cache_session = val; break;
#ifndef CURL_DISABLE_PROXY
  case 44: s->proxy_ssl.cache_session = val; break;
#endif
#ifdef USE_SSH
  case 45: s->ssh_compression = val; break;
#endif
#ifndef CURL_DISABLE_SMTP
  case 46: s->mail_rcpt_allowfails = val; break;
#endif
  case 47: s->sasl_ir = val; break;
  case 48: s->tcp_keepalive = val; break;
  case 49: s->tcp_fastopen = val; break;
  case 50: s->ssl_enable_alpn = val; break;
  case 51: s->path_as_is = val; break;
  case 52: s->pipewait = val; break;
  case 53: s->suppress_connect_headers = val; break;
#ifndef CURL_DISABLE_SHUFFLE_DNS
  case 54: s->dns_shuffle_addresses = val; break;
#endif
  case 55: s->disallow_username_in_url = val; break;
  case 56: s->quick_exit = val; break;
  case 57: s->connect_only = val; break;
  case 58: s->connect_only_ws = val; break;
#ifdef USE_OPENSSL
  case 59: s->engine_default = val; break;
#endif
#ifndef CURL_DISABLE_PROXY
  case 60: s->socks5_auth_only = val; break;
#endif
#ifndef CURL_DISABLE_HTTP
  case 61: s->post301 = val; break;
  case 62: s->post302 = val; break;
  case 63: s->post303 = val; break;
  case 64: s->sep_headers = val; break;
#endif
#ifndef CURL_DISABLE_WEBSOCKETS
  case 65: s->ws_raw_mode = val; break;
  case 66: s->ws_no_auto_pong = val; break;
#endif
#ifndef CURL_DISABLE_MIME
  case 67: s->mime_formescape = val; break;
#endif
#if !defined(CURL_DISABLE_HTTP) && !defined(CURL_DISABLE_COOKIES)
  case 68: data->state.cookie_engine = val; break;
#endif
#ifndef CURL_DISABLE_PROXY
  case 69: s->proxy_ssl.custom_cafile = val; break;
  case 70: s->proxy_ssl.custom_capath = val; break;
#endif
  case 71: s->ssl.custom_cafile = val; break;
  case 72: s->ssl.custom_capath = val; break;
#ifndef CURL_DISABLE_FTP
  case 73: s->ftp_use_port = val; break;
#endif
#ifdef USE_UNIX_SOCKETS
  case 74: s->abstract_unix_socket = val; break;
#endif
#ifndef CURL_DISABLE_DOH
  case 75: s->doh = val; break;
#endif
  case 76: data->progress.callback = val; break;
  case 77: s->is_fread_set = val; break;
#ifndef CURL_DISABLE_PROXY
  case 78: s->proxy_ssl.custom_cablob = val; break;
#endif
  case 79: s->ssl.custom_cablob = val; break;
  default: break;
  }
}

int64_t Curl_setopt_get_i64(struct Curl_easy *data, int field_id)
{
  struct UserDefined *s = &data->set;
  switch(field_id) {
  case 1: return (int64_t)s->httpauth;
#ifndef CURL_DISABLE_PROXY
  case 2: return (int64_t)s->proxyauth;
#endif
  case 3: return (int64_t)s->httpwant;
#ifdef USE_SSL
  case 4: return (int64_t)s->ssl.version;
  case 5: return (int64_t)s->ssl.version_max;
#ifndef CURL_DISABLE_PROXY
  case 6: return (int64_t)s->proxy_ssl.version;
  case 7: return (int64_t)s->proxy_ssl.version_max;
#endif
#endif
#ifndef CURL_DISABLE_RTSP
  case 8: return (int64_t)s->rtspreq;
#endif
  case 9: return (int64_t)s->method;
  case 10: return (int64_t)s->dns_cache_timeout_ms;
  case 11: return (int64_t)s->maxconnects;
  case 12: return (int64_t)s->server_response_timeout;
  case 13: return (int64_t)s->low_speed_limit;
  case 14: return (int64_t)s->low_speed_time;
  case 15: return (int64_t)s->use_port;
  case 16: return (int64_t)s->timeout;
  case 17: return (int64_t)s->connecttimeout;
#ifndef CURL_DISABLE_BINDLOCAL
  case 18: return (int64_t)s->localport;
  case 19: return (int64_t)s->localportrange;
#endif
  case 20: return (int64_t)s->buffer_size;
  case 21: return (int64_t)s->upload_buffer_size;
  case 22: return (int64_t)s->max_filesize;
  case 23: return (int64_t)s->ipver;
#ifdef USE_IPV6
  case 24: return (int64_t)s->scope_id;
#endif
  case 25: return (int64_t)s->tcp_keepidle;
  case 26: return (int64_t)s->tcp_keepintvl;
  case 27: return (int64_t)s->tcp_keepcnt;
  case 28: return (int64_t)s->happy_eyeballs_timeout;
  case 29: return (int64_t)s->upkeep_interval_ms;
  case 30: return (int64_t)s->conn_max_idle_ms;
  case 31: return (int64_t)s->conn_max_age_ms;
#ifdef USE_SSL
  case 32: return (int64_t)s->ssl_ca_cache_timeout;
#endif
  case 33: return (int64_t)s->use_ssl;
  case 34: return (int64_t)s->ssl.ssl_options;
#ifndef CURL_DISABLE_PROXY
  case 35: return (int64_t)s->proxy_ssl.ssl_options;
  case 36: return (int64_t)s->proxyport;
  case 37: return (int64_t)s->proxytype;
  case 38: return (int64_t)s->socks5auth;
#endif
#ifndef CURL_DISABLE_HTTP
  case 39: return (int64_t)s->http_follow_mode;
  case 40: return (int64_t)s->maxredirs;
  case 41: return (int64_t)s->expect_100_timeout;
#if defined(USE_HTTP2) || defined(USE_HTTP3)
  case 42: return (int64_t)s->weight;
#endif
#ifndef CURL_DISABLE_HTTPSIG
  case 43: return (int64_t)s->httpsig_algorithm;
#endif
#endif
#ifndef CURL_DISABLE_TFTP
  case 44: return (int64_t)s->tftp_blksize;
#endif
#ifndef CURL_DISABLE_NETRC
  case 45: return (int64_t)s->use_netrc;
#endif
#ifndef CURL_DISABLE_FTP
  case 46: return (int64_t)s->ftp_filemethod;
  case 47: return (int64_t)s->ftp_ccc;
  case 48: return (int64_t)s->ftpsslauth;
  case 49: return (int64_t)s->accepttimeout;
#endif
#if !defined(CURL_DISABLE_FTP) || defined(USE_SSH)
  case 50: return (int64_t)s->ftp_create_missing_dirs;
  case 51: return (int64_t)s->new_file_perms;
#endif
#ifndef CURL_DISABLE_RTSP
  case 52: return (int64_t)data->state.rtsp_next_client_CSeq;
  case 53: return (int64_t)data->state.rtsp_next_server_CSeq;
#endif
#ifdef USE_SSH
  case 54: return (int64_t)s->ssh_auth_types;
  case 55: return (int64_t)s->new_directory_perms;
#endif
  case 56: return (int64_t)s->allowed_protocols;
  case 57: return (int64_t)s->redir_protocols;
  case 58: return (int64_t)s->timecondition;
  case 59: return (int64_t)s->timevalue;
  case 60: return (int64_t)s->postfieldsize;
  case 61: return (int64_t)s->filesize;
  case 62: return (int64_t)s->set_resume_from;
  case 63: return (int64_t)s->upload_flags;
#if defined(HAVE_GSSAPI) || defined(USE_WINDOWS_SSPI)
  case 64: return (int64_t)s->gssapi_delegation;
#endif
  case 65: return (int64_t)s->max_send_speed;
  case 66: return (int64_t)s->max_recv_speed;
  default: return 0;
  }
}

void Curl_setopt_set_i64(struct Curl_easy *data, int field_id, int64_t val)
{
  struct UserDefined *s = &data->set;
  switch(field_id) {
  case 1: s->httpauth = (uint32_t)val; break;
#ifndef CURL_DISABLE_PROXY
  case 2: s->proxyauth = (uint32_t)val; break;
#endif
  case 3: s->httpwant = (unsigned char)val; break;
#ifdef USE_SSL
  case 4: s->ssl.version = (unsigned char)val; break;
  case 5: s->ssl.version_max = (unsigned int)val; break;
#ifndef CURL_DISABLE_PROXY
  case 6: s->proxy_ssl.version = (unsigned char)val; break;
  case 7: s->proxy_ssl.version_max = (unsigned int)val; break;
#endif
#endif
#ifndef CURL_DISABLE_RTSP
  case 8: s->rtspreq = (unsigned char)val; break;
#endif
  case 9: s->method = (Curl_HttpReq)val; break;
  case 10: s->dns_cache_timeout_ms = (timediff_t)val; break;
  case 11: s->maxconnects = (uint32_t)val; break;
  case 12: s->server_response_timeout = (timediff_t)val; break;
  case 13: s->low_speed_limit = (long)val; break;
  case 14: s->low_speed_time = (uint16_t)val; break;
  case 15: s->use_port = (unsigned short)val; break;
  case 16: s->timeout = (timediff_t)val; break;
  case 17: s->connecttimeout = (timediff_t)val; break;
#ifndef CURL_DISABLE_BINDLOCAL
  case 18: s->localport = (unsigned short)val; break;
  case 19: s->localportrange = (unsigned short)val; break;
#endif
  case 20: s->buffer_size = (unsigned int)val; break;
  case 21: s->upload_buffer_size = (unsigned int)val; break;
  case 22: s->max_filesize = (curl_off_t)val; break;
  case 23: s->ipver = (unsigned char)val; break;
#ifdef USE_IPV6
  case 24: s->scope_id = (unsigned int)val; break;
#endif
  case 25: s->tcp_keepidle = (int)val; break;
  case 26: s->tcp_keepintvl = (int)val; break;
  case 27: s->tcp_keepcnt = (int)val; break;
  case 28: s->happy_eyeballs_timeout = (timediff_t)val; break;
  case 29: s->upkeep_interval_ms = (timediff_t)val; break;
  case 30: s->conn_max_idle_ms = (timediff_t)val; break;
  case 31: s->conn_max_age_ms = (timediff_t)val; break;
#ifdef USE_SSL
  case 32: s->ssl_ca_cache_timeout = (int)val; break;
#endif
  case 33: s->use_ssl = (unsigned char)val; break;
  case 34: s->ssl.ssl_options = (unsigned char)val; break;
#ifndef CURL_DISABLE_PROXY
  case 35: s->proxy_ssl.ssl_options = (unsigned char)val; break;
  case 36: s->proxyport = (uint16_t)val; break;
  case 37: s->proxytype = (unsigned char)val; break;
  case 38: s->socks5auth = (unsigned char)val; break;
#endif
#ifndef CURL_DISABLE_HTTP
  case 39: s->http_follow_mode = (unsigned char)val; break;
  case 40: s->maxredirs = (short)val; break;
  case 41: s->expect_100_timeout = (unsigned short)val; break;
#if defined(USE_HTTP2) || defined(USE_HTTP3)
  case 42: s->weight = (int)val; break;
#endif
#ifndef CURL_DISABLE_HTTPSIG
  case 43: s->httpsig_algorithm = (uint8_t)val; break;
#endif
#endif
#ifndef CURL_DISABLE_TFTP
  case 44: s->tftp_blksize = (unsigned short)val; break;
#endif
#ifndef CURL_DISABLE_NETRC
  case 45: s->use_netrc = (unsigned char)val; break;
#endif
#ifndef CURL_DISABLE_FTP
  case 46: s->ftp_filemethod = (unsigned char)val; break;
  case 47: s->ftp_ccc = (unsigned char)val; break;
  case 48: s->ftpsslauth = (unsigned char)val; break;
  case 49: s->accepttimeout = (timediff_t)val; break;
#endif
#if !defined(CURL_DISABLE_FTP) || defined(USE_SSH)
  case 50: s->ftp_create_missing_dirs = (unsigned char)val; break;
  case 51: s->new_file_perms = (unsigned int)val; break;
#endif
#ifndef CURL_DISABLE_RTSP
  case 52: data->state.rtsp_next_client_CSeq = (uint32_t)val; break;
  case 53: data->state.rtsp_next_server_CSeq = (uint32_t)val; break;
#endif
#ifdef USE_SSH
  case 54: s->ssh_auth_types = (uint32_t)val; break;
  case 55: s->new_directory_perms = (unsigned int)val; break;
#endif
  case 56: s->allowed_protocols = (curl_prot_t)val; break;
  case 57: s->redir_protocols = (curl_prot_t)val; break;
  case 58: s->timecondition = (unsigned char)val; break;
  case 59: s->timevalue = (time_t)val; break;
  case 60: s->postfieldsize = (curl_off_t)val; break;
  case 61: s->filesize = (curl_off_t)val; break;
  case 62: s->set_resume_from = (curl_off_t)val; break;
  case 63: s->upload_flags = (unsigned char)val; break;
#if defined(HAVE_GSSAPI) || defined(USE_WINDOWS_SSPI)
  case 64: s->gssapi_delegation = (unsigned char)val; break;
#endif
  case 65: s->max_send_speed = (curl_off_t)val; break;
  case 66: s->max_recv_speed = (curl_off_t)val; break;
  default: break;
  }
}

void *Curl_setopt_get_ptr(struct Curl_easy *data, int ptr_id)
{
  struct UserDefined *s = &data->set;
  switch(ptr_id) {
  case 1: return s->str_copypostfields;
  case 2: return s->postfields;
#ifndef CURL_DISABLE_HSTS
  case 3: return data->hsts;
#endif
  case 4: return data->share;
#ifndef CURL_DISABLE_HSTS
  case 5: return data->share ? data->share->hsts : NULL;
  case 6: return data->state.hstslist;
#endif
#ifndef CURL_DISABLE_PROXY
  case 7: return s->proxyheaders;
#endif
#ifndef CURL_DISABLE_HTTP
  case 8: return s->http200aliases;
#endif
#if !defined(CURL_DISABLE_FTP) || defined(USE_SSH)
  case 9: return s->postquote;
  case 10: return s->prequote;
  case 11: return s->quote;
#endif
  case 12: return s->resolve;
  case 13: return data->state.resolve;
#if !defined(CURL_DISABLE_HTTP) || !defined(CURL_DISABLE_MIME)
  case 14: return s->headers;
#endif
#ifndef CURL_DISABLE_TELNET
  case 15: return s->telnet_options;
#endif
#ifndef CURL_DISABLE_SMTP
  case 16: return s->mail_rcpt;
#endif
  case 17: return s->connect_to;
#ifndef CURL_DISABLE_MIME
  case 18: return s->mimepostp;
  case 19: return data->state.formp;
  case 20: return data->state.mimepost;
#endif
  case 21: return data->conn;
  case 22: return s->uh;
#ifndef CURL_DISABLE_FORM_API
  case 23: return s->httppost;
#endif
  case 24: return s->err;
#if !defined(CURL_DISABLE_HTTP) && !defined(CURL_DISABLE_COOKIES)
  case 25: return data->cookies;
  case 26: return data->state.cookielist;
  case 27: return data->share ? data->share->cookies : NULL;
#endif
#ifdef USE_SSL
  case 28: return s->ssl_fsslctxp;
#endif
#ifndef CURL_DISABLE_HTTP
  case 29: return s->trailer_data;
#endif
#ifndef CURL_DISABLE_FTP
  case 30: return s->wildcardptr;
  case 31: return s->fnmatch_data;
#endif
  case 32: return s->writeheader;
  case 33: return s->in_set;
  case 34: return s->out;
  case 35: return s->debugdata;
  case 36: return s->progress_client;
  case 37: return s->seek_client;
  case 38: return s->ioctl_client;
  case 39: return s->sockopt_client;
  case 40: return s->opensocket_client;
  case 41: return s->resolver_start_client;
  case 42: return s->closesocket_client;
  case 43: return s->prereq_userp;
  case 44: return s->errorbuffer;
  case 45: return s->private_data;
#ifndef CURL_DISABLE_RTSP
  case 46: return s->rtp_out;
#endif
#ifndef CURL_DISABLE_HSTS
  case 47: return s->hsts_read_userp;
  case 48: return s->hsts_write_userp;
#endif
#ifndef CURL_DISABLE_ALTSVC
  case 49: return data->asi;
#endif
  case 50: return (void *)(uintptr_t)s->fprogress;
  case 51: return (void *)(uintptr_t)s->fxferinfo;
  case 52: return (void *)(uintptr_t)s->fdebug;
  case 53: return (void *)(uintptr_t)s->fwrite_header;
  case 54: return (void *)(uintptr_t)s->fwrite_func;
  case 55: return (void *)(uintptr_t)s->fread_func_set;
  case 56: return (void *)(uintptr_t)s->seek_func;
  case 57: return (void *)(uintptr_t)s->ioctl_func;
#ifdef USE_SSL
  case 58: return (void *)(uintptr_t)s->ssl_fsslctx;
#endif
  case 59: return (void *)(uintptr_t)s->fsockopt;
  case 60: return (void *)(uintptr_t)s->fopensocket;
  case 61: return (void *)(uintptr_t)s->fclosesocket;
  case 62: return (void *)(uintptr_t)s->resolver_start;
#ifndef CURL_DISABLE_RTSP
  case 63: return (void *)(uintptr_t)s->fwrite_rtp;
#endif
#ifndef CURL_DISABLE_FTP
  case 64: return (void *)(uintptr_t)s->chunk_bgn;
  case 65: return (void *)(uintptr_t)s->chunk_end;
  case 66: return (void *)(uintptr_t)s->fnmatch;
#endif
#ifndef CURL_DISABLE_HTTP
  case 67: return (void *)(uintptr_t)s->trailer_callback;
#endif
#ifndef CURL_DISABLE_HSTS
  case 68: return (void *)(uintptr_t)s->hsts_read;
  case 69: return (void *)(uintptr_t)s->hsts_write;
#endif
  case 70: return (void *)(uintptr_t)s->fprereq;
  default: return NULL;
  }
}

void Curl_setopt_set_ptr(struct Curl_easy *data, int ptr_id, void *val)
{
  struct UserDefined *s = &data->set;
  switch(ptr_id) {
  case 1: s->str_copypostfields = (char *)val; break;
  case 2: s->postfields = val; break;
#ifndef CURL_DISABLE_HSTS
  case 3: data->hsts = (struct hsts *)val; break;
#endif
  case 4: data->share = (struct Curl_share *)val; break;
#ifndef CURL_DISABLE_HSTS
  case 6: data->state.hstslist = (struct curl_slist *)val; break;
#endif
#ifndef CURL_DISABLE_PROXY
  case 7: s->proxyheaders = (struct curl_slist *)val; break;
#endif
#ifndef CURL_DISABLE_HTTP
  case 8: s->http200aliases = (struct curl_slist *)val; break;
#endif
#if !defined(CURL_DISABLE_FTP) || defined(USE_SSH)
  case 9: s->postquote = (struct curl_slist *)val; break;
  case 10: s->prequote = (struct curl_slist *)val; break;
  case 11: s->quote = (struct curl_slist *)val; break;
#endif
  case 12: s->resolve = (struct curl_slist *)val; break;
  case 13: data->state.resolve = (struct curl_slist *)val; break;
#if !defined(CURL_DISABLE_HTTP) || !defined(CURL_DISABLE_MIME)
  case 14: s->headers = (struct curl_slist *)val; break;
#endif
#ifndef CURL_DISABLE_TELNET
  case 15: s->telnet_options = (struct curl_slist *)val; break;
#endif
#ifndef CURL_DISABLE_SMTP
  case 16: s->mail_rcpt = (struct curl_slist *)val; break;
#endif
  case 17: s->connect_to = (struct curl_slist *)val; break;
#ifndef CURL_DISABLE_MIME
  case 18: s->mimepostp = (curl_mimepart *)val; break;
  case 19: data->state.formp = (curl_mimepart *)val; break;
  case 20: data->state.mimepost = (curl_mimepart *)val; break;
#endif
  case 22: s->uh = (CURLU *)val; break;
#ifndef CURL_DISABLE_FORM_API
  case 23: s->httppost = (struct curl_httppost *)val; break;
#endif
  case 24: s->err = (FILE *)val; break;
#if !defined(CURL_DISABLE_HTTP) && !defined(CURL_DISABLE_COOKIES)
  case 25: data->cookies = (struct CookieInfo *)val; break;
  case 26: data->state.cookielist = (struct curl_slist *)val; break;
#endif
#ifdef USE_SSL
  case 28: s->ssl_fsslctxp = val; break;
#endif
#ifndef CURL_DISABLE_HTTP
  case 29: s->trailer_data = val; break;
#endif
#ifndef CURL_DISABLE_FTP
  case 30: s->wildcardptr = val; break;
  case 31: s->fnmatch_data = val; break;
#endif
  case 32: s->writeheader = val; break;
  case 33: s->in_set = val; break;
  case 34: s->out = val; break;
  case 35: s->debugdata = val; break;
  case 36: s->progress_client = val; break;
  case 37: s->seek_client = val; break;
  case 38: s->ioctl_client = val; break;
  case 39: s->sockopt_client = val; break;
  case 40: s->opensocket_client = val; break;
  case 41: s->resolver_start_client = val; break;
  case 42: s->closesocket_client = val; break;
  case 43: s->prereq_userp = val; break;
  case 44: s->errorbuffer = (char *)val; break;
  case 45: s->private_data = val; break;
#ifndef CURL_DISABLE_RTSP
  case 46: s->rtp_out = val; break;
#endif
#ifndef CURL_DISABLE_HSTS
  case 47: s->hsts_read_userp = val; break;
  case 48: s->hsts_write_userp = val; break;
#endif
#ifndef CURL_DISABLE_ALTSVC
  case 49: data->asi = (struct altsvcinfo *)val; break;
#endif
  case 50: s->fprogress = (curl_progress_callback)(uintptr_t)val; break;
  case 51: s->fxferinfo = (curl_xferinfo_callback)(uintptr_t)val; break;
  case 52: s->fdebug = (curl_debug_callback)(uintptr_t)val; break;
  case 53: s->fwrite_header = (curl_write_callback)(uintptr_t)val; break;
  case 54: s->fwrite_func = (curl_write_callback)(uintptr_t)val; break;
  case 55: s->fread_func_set = (curl_read_callback)(uintptr_t)val; break;
  case 56: s->seek_func = (curl_seek_callback)(uintptr_t)val; break;
  case 57: s->ioctl_func = (curl_ioctl_callback)(uintptr_t)val; break;
#ifdef USE_SSL
  case 58: s->ssl_fsslctx = (curl_ssl_ctx_callback)(uintptr_t)val; break;
#endif
  case 59: s->fsockopt = (curl_sockopt_callback)(uintptr_t)val; break;
  case 60: s->fopensocket = (curl_opensocket_callback)(uintptr_t)val; break;
  case 61: s->fclosesocket = (curl_closesocket_callback)(uintptr_t)val; break;
  case 62: s->resolver_start = (curl_resolver_start_callback)(uintptr_t)val; break;
#ifndef CURL_DISABLE_RTSP
  case 63: s->fwrite_rtp = (curl_write_callback)(uintptr_t)val; break;
#endif
#ifndef CURL_DISABLE_FTP
  case 64: s->chunk_bgn = (curl_chunk_bgn_callback)(uintptr_t)val; break;
  case 65: s->chunk_end = (curl_chunk_end_callback)(uintptr_t)val; break;
  case 66: s->fnmatch = (curl_fnmatch_callback)(uintptr_t)val; break;
#endif
#ifndef CURL_DISABLE_HTTP
  case 67: s->trailer_callback = (curl_trailer_callback)(uintptr_t)val; break;
#endif
#ifndef CURL_DISABLE_HSTS
  case 68: s->hsts_read = (curl_hstsread_callback)(uintptr_t)val; break;
  case 69: s->hsts_write = (curl_hstswrite_callback)(uintptr_t)val; break;
#endif
  case 70: s->fprereq = (curl_prereq_callback)(uintptr_t)val; break;
  default: break;
  }
}

void *Curl_setopt_get_ptr_ref(struct Curl_easy *data, int ref_id)
{
  switch(ref_id) {
#ifndef CURL_DISABLE_PROXY
  case 1: return &data->state.proxydigest;
  case 2: return &data->state.authproxy;
#endif
#ifndef CURL_DISABLE_HSTS
  case 3: return &data->hsts;
#endif
#ifndef CURL_DISABLE_ALTSVC
  case 4: return &data->asi;
#endif
  case 5: return &data->state.url;
#if !defined(CURL_DISABLE_HTTP) && !defined(CURL_DISABLE_COOKIES)
  case 6: return &data->cookies;
  case 7: return &data->req.setcookies;
#endif
#ifndef CURL_DISABLE_HTTP
  case 8: return &data->state.referer;
#endif
#ifndef CURL_DISABLE_RTSP
  case 9: return &data->state.rtsp_session_origin;
#endif
  case 10: return &data->progress.ul.rlimit;
  case 11: return &data->progress.dl.rlimit;
  case 12: return &data->set.ssl;
#ifndef CURL_DISABLE_PROXY
  case 13: return &data->set.proxy_ssl;
#endif
  case 14: return data->conn ? &data->conn->ssl_config : NULL;
#ifndef CURL_DISABLE_PROXY
  case 15: return data->conn ? &data->conn->proxy_ssl_config : NULL;
#endif
  default: return NULL;
  }
}

CURLcode Curl_vsetopt_zig(struct Curl_easy *data, CURLoption option,
                          long larg, void *parg, curl_off_t oarg);

CURLcode Curl_vsetopt(struct Curl_easy *data, CURLoption option, va_list param)
{
  if(option < CURLOPTTYPE_OBJECTPOINT)
    return Curl_vsetopt_zig(data, option, va_arg(param, long), NULL, 0);
  else if(option < CURLOPTTYPE_OFF_T) {
    if(option == CURLOPT_STREAM_DEPENDS || option == CURLOPT_STREAM_DEPENDS_E)
      return CURLE_OK;
    return Curl_vsetopt_zig(data, option, 0, va_arg(param, void *), 0);
  }
  else if(option < CURLOPTTYPE_BLOB)
    return Curl_vsetopt_zig(data, option, 0, NULL, va_arg(param, curl_off_t));
  return Curl_vsetopt_zig(data, option, 0, va_arg(param, void *), 0);
}

#undef curl_easy_setopt
CURLcode curl_easy_setopt(CURL *curl, CURLoption option, ...)
{
  struct Curl_eapi_guard guard;
  CURLcode result;

  if(CURL_EAPI_ENTER(&guard, curl, easy_setopt, &result)) {
    struct Curl_easy *data = curl;
    va_list arg;

    va_start(arg, option);

    result = Curl_vsetopt(data, option, arg);

    va_end(arg);
    if(result == CURLE_BAD_FUNCTION_ARGUMENT)
      failf(data, "setopt 0x%x got bad argument", (unsigned int)option);
  }
  CURL_EAPI_LEAVE(&guard);
  return result;
}



#ifdef HAVE_NETINET_IN_H
#include <netinet/in.h>
#endif

#ifdef HAVE_LINUX_TCP_H
#include <linux/tcp.h>
#elif defined(HAVE_NETINET_TCP_H)
#include <netinet/tcp.h>
#endif
#ifdef HAVE_NETINET_UDP_H
#include <netinet/udp.h>
#endif
#ifdef HAVE_NETINET_IP_H
#include <netinet/ip.h>
#endif
#ifdef HAVE_SYS_IOCTL_H
#include <sys/ioctl.h>
#endif
#ifdef HAVE_NETDB_H
#include <netdb.h>
#endif
#ifdef HAVE_ARPA_INET_H
#include <arpa/inet.h>
#endif
#ifdef HAVE_IFADDRS_H
#include <ifaddrs.h>
#endif
#ifdef HAVE_NET_IF_H
#include <net/if.h>
#endif
#include <signal.h>

#include "urldata.h"
#include "sendf.h"
#include "curl_trc.h"
#include "transfer.h"
#include "cfilters.h"
#include "connect.h"
#include "cw-out.h"
#include "cw-pause.h"
#include "multiif.h"
#include "progress.h"
#include "sigpipe.h"
#include "cshutdn.h"
#include "ftp.h"
#include "curl_share.h"
#include "conncache.h"
#include "if2ip.h"
#include "cf-socket.h"
#include "curl_addrinfo.h"
#include "select.h"
#include "curlx/inet_ntop.h"
#include "curlx/inet_pton.h"
#include "multihandle.h"
#include "rand.h"
#include "sockaddr.h"
#include "curlx/strdup.h"
#include "curlx/nonblock.h"
#include "curlx/strcopy.h"
#include "curlx/version_win32.h"
#include "curlx/strerr.h"
#include "curlx/strparse.h"
#include "curl_range.h"
#include "http.h"
#include "url.h"
#include "getinfo.h"
#include "hsts.h"
#include "setopt.h"
#include "headers.h"
#include "bufref.h"
#include "rtsp.h"
#ifdef _WIN32
#include <mstcpip.h>
#endif

bool Curl_chunked_te_skip(const struct Curl_easy *data)
{
  return data ? (bool)data->set.http_te_skip : FALSE;
}

void Curl_chunked_set_req_chunk(struct Curl_easy *data)
{
  if(data)
    data->req.chunk = TRUE;
}

bool Curl_chunked_set_download_done(struct Curl_easy *data)
{
  if(!data)
    return FALSE;
  data->req.download_done = TRUE;
  return (bool)data->req.no_body;
}

int Curl_chunked_call_trailer_cb(struct Curl_easy *data,
                                 struct curl_slist **trailers)
{
  struct Curl_mapi_guard guard;
  int rc;
  if(!data || !data->set.trailer_callback)
    return -1;
  CURL_CBAPI_START(&guard, data, easy_trailer_callback);
  rc = data->set.trailer_callback(trailers, data->set.trailer_data);
  CURL_CBAPI_END(&guard);
  return rc;
}

/* Helpers for zig/port/cfilters_progress.zig */
void Curl_cw_out_get_writefunc(struct Curl_easy *data, int otype,
                               curl_write_callback *pwcb, void **pwcb_data,
                               size_t *pmax_write, size_t *pmin_write);
void Curl_cw_out_get_writefunc(struct Curl_easy *data, int otype,
                               curl_write_callback *pwcb, void **pwcb_data,
                               size_t *pmax_write, size_t *pmin_write)
{
  switch(otype) {
  case 1: /* CW_OUT_BODY */
  case 2: /* CW_OUT_BODY_0LEN */
    if(Curl_ftp_listmode(data)) {
      *pwcb = Curl_ftp_parselist;
      *pwcb_data = data;
    }
    else {
      *pwcb = data->set.fwrite_func;
      *pwcb_data = data->set.out;
    }
    *pmax_write = CURL_MAX_WRITE_SIZE;
    *pmin_write = 0;
    break;
  case 3: /* CW_OUT_HDS */
    *pwcb = data->set.fwrite_header ? data->set.fwrite_header :
             (data->set.writeheader ? data->set.fwrite_func : NULL);
    *pwcb_data = data->set.writeheader;
    *pmax_write = 0;
    *pmin_write = 0;
    break;
  default:
    *pwcb = NULL;
    *pwcb_data = NULL;
    *pmax_write = CURL_MAX_WRITE_SIZE;
    *pmin_write = 0;
  }
}

bool Curl_cw_out_is_paused(struct Curl_easy *data);
bool Curl_cw_out_is_paused(struct Curl_easy *data)
{
  return (bool)data->req.writer.paused;
}

void Curl_cw_out_set_paused(struct Curl_easy *data, bool paused);
void Curl_cw_out_set_paused(struct Curl_easy *data, bool paused)
{
  data->req.writer.paused = paused;
}

bool Curl_trc_is_verbose_fn(struct Curl_easy *data);
bool Curl_trc_is_verbose_fn(struct Curl_easy *data)
{
  return (bool)Curl_trc_is_verbose(data);
}

bool Curl_trc_ft_is_verbose_fn(struct Curl_easy *data,
                               const struct curl_trc_feat *ft);
bool Curl_trc_ft_is_verbose_fn(struct Curl_easy *data,
                               const struct curl_trc_feat *ft)
{
  return (bool)Curl_trc_ft_is_verbose(data, ft);
}

bool Curl_cw_out_is_nonetwork(struct Curl_easy *data);
bool Curl_cw_out_is_nonetwork(struct Curl_easy *data)
{
  return data->conn && data->conn->scheme &&
         (data->conn->scheme->flags & PROTOPT_NONETWORK);
}

bool Curl_cw_out_include_header(struct Curl_easy *data);
bool Curl_cw_out_include_header(struct Curl_easy *data)
{
  return (bool)data->set.include_header;
}

struct Progress *Curl_easy_progress(struct Curl_easy *data);
struct Progress *Curl_easy_progress(struct Curl_easy *data)
{
  return &data->progress;
}

curl_off_t Curl_easy_max_filesize(struct Curl_easy *data);
curl_off_t Curl_easy_max_filesize(struct Curl_easy *data)
{
  return data->set.max_filesize;
}

struct Curl_cfilter *Curl_easy_conn_cfilter(struct Curl_easy *data,
                                            int8_t sockindex);
struct Curl_cfilter *Curl_easy_conn_cfilter(struct Curl_easy *data,
                                            int8_t sockindex)
{
  return (data && data->conn && CONN_SOCK_IDX_VALID(sockindex)) ?
         data->conn->cfilter[sockindex] : NULL;
}

bool Curl_share_keep_connect(const struct Curl_share *share);
bool Curl_share_keep_connect(const struct Curl_share *share)
{
  return CURL_SHARE_KEEP_CONNECT(share) ? TRUE : FALSE;
}

void Curl_cpool_with_sigpipe(struct Curl_easy *admin,
                             struct cpool *cpool,
                             void (*fn)(struct cpool *, struct Curl_easy *));
void Curl_cpool_with_sigpipe(struct Curl_easy *admin,
                             struct cpool *cpool,
                             void (*fn)(struct cpool *, struct Curl_easy *))
{
  struct Curl_sigpipe_ctx pipe_ctx;
  sigpipe_init(&pipe_ctx);
  sigpipe_apply(admin, &pipe_ctx);
  fn(cpool, admin);
  sigpipe_restore(&pipe_ctx);
}

uint32_t Curl_conn_get_cpid(const struct connectdata *conn);
uint32_t Curl_conn_get_cpid(const struct connectdata *conn)
{
  return conn->cpid;
}

void Curl_conn_set_cpid(struct connectdata *conn, uint32_t cpid);
void Curl_conn_set_cpid(struct connectdata *conn, uint32_t cpid)
{
  conn->cpid = cpid;
}

uint32_t Curl_conn_get_attached_xfers(const struct connectdata *conn);
uint32_t Curl_conn_get_attached_xfers(const struct connectdata *conn)
{
  return conn->attached_xfers;
}

bool Curl_conn_is_connect_only(const struct connectdata *conn);
bool Curl_conn_is_connect_only(const struct connectdata *conn)
{
  return (bool)conn->bits.connect_only;
}

bool Curl_conn_is_aborted(const struct connectdata *conn);
bool Curl_conn_is_aborted(const struct connectdata *conn)
{
  return (bool)conn->bits.aborted;
}

void Curl_conn_set_aborted(struct connectdata *conn, bool aborted);
void Curl_conn_set_aborted(struct connectdata *conn, bool aborted)
{
  conn->bits.aborted = aborted;
}

bool Curl_conn_is_no_reuse_or_close(const struct connectdata *conn);
bool Curl_conn_is_no_reuse_or_close(const struct connectdata *conn)
{
  return (bool)(conn->bits.no_reuse || conn->bits.close);
}

bool Curl_conn_is_close(const struct connectdata *conn);
bool Curl_conn_is_close(const struct connectdata *conn)
{
  return (bool)conn->bits.close;
}

void Curl_conn_set_no_reuse(struct connectdata *conn, bool no_reuse);
void Curl_conn_set_no_reuse(struct connectdata *conn, bool no_reuse)
{
  conn->bits.no_reuse = no_reuse;
}

curl_off_t Curl_conn_get_id(const struct connectdata *conn);
curl_off_t Curl_conn_get_id(const struct connectdata *conn)
{
  return conn->connection_id;
}

void Curl_conn_set_id(struct connectdata *conn, curl_off_t id);
void Curl_conn_set_id(struct connectdata *conn, curl_off_t id)
{
  conn->connection_id = id;
}

const char *Curl_cpool_conn_get_destination(const struct connectdata *conn);
const char *Curl_cpool_conn_get_destination(const struct connectdata *conn)
{
  return conn->destination;
}

const struct curltime *Curl_conn_get_created(const struct connectdata *conn);
const struct curltime *Curl_conn_get_created(const struct connectdata *conn)
{
  return &conn->created;
}

void Curl_conn_init_cpool_times(struct connectdata *conn,
                                const struct curltime *pnow);
void Curl_conn_init_cpool_times(struct connectdata *conn,
                                const struct curltime *pnow)
{
  conn->created = *pnow;
  conn->shutdown.start_ms[FIRSTSOCKET] =
    conn->shutdown.start_ms[SECONDARYSOCKET] = -1;
}

timediff_t Curl_conn_get_lastused_ms(const struct connectdata *conn);
timediff_t Curl_conn_get_lastused_ms(const struct connectdata *conn)
{
  return conn->lastused_ms;
}

timediff_t Curl_conn_get_lastchecked_ms(const struct connectdata *conn);
timediff_t Curl_conn_get_lastchecked_ms(const struct connectdata *conn)
{
  return conn->lastchecked_ms;
}

void Curl_conn_set_lastchecked_ms(struct connectdata *conn, timediff_t ms);
void Curl_conn_set_lastchecked_ms(struct connectdata *conn, timediff_t ms)
{
  conn->lastchecked_ms = ms;
}

timediff_t Curl_conn_get_lastupkeep_ms(const struct connectdata *conn);
timediff_t Curl_conn_get_lastupkeep_ms(const struct connectdata *conn)
{
  return conn->lastupkeep_ms;
}

void Curl_conn_set_lastupkeep_ms(struct connectdata *conn, timediff_t ms);
void Curl_conn_set_lastupkeep_ms(struct connectdata *conn, timediff_t ms)
{
  conn->lastupkeep_ms = ms;
}

void Curl_conn_set_return_times(struct connectdata *conn, timediff_t ms);
void Curl_conn_set_return_times(struct connectdata *conn, timediff_t ms)
{
  conn->lastchecked_ms = conn->lastupkeep_ms = conn->lastused_ms = ms;
}

void Curl_conn_get_origin_info(const struct connectdata *conn,
                               const char **puser_hostname,
                               uint16_t *pport);
void Curl_conn_get_origin_info(const struct connectdata *conn,
                               const char **puser_hostname,
                               uint16_t *pport)
{
  *puser_hostname = conn->origin->user_hostname;
  *pport = conn->origin->port;
}

struct Curl_cfilter **Curl_conn_get_cfilters(struct connectdata *conn);
struct Curl_cfilter **Curl_conn_get_cfilters(struct connectdata *conn)
{
  return conn ? conn->cfilter : NULL;
}

bool Curl_conn_has_dead_cb(const struct connectdata *conn);
bool Curl_conn_has_dead_cb(const struct connectdata *conn)
{
  return conn && conn->scheme && conn->scheme->run &&
         conn->scheme->run->connection_is_dead != NULL;
}

bool Curl_conn_call_dead_cb(struct Curl_easy *admin,
                            struct connectdata *conn);
bool Curl_conn_call_dead_cb(struct Curl_easy *admin,
                            struct connectdata *conn)
{
  return conn->scheme->run->connection_is_dead(admin, conn);
}

void Curl_easy_get_multi_cpool(struct Curl_easy *data,
                               struct Curl_multi **pmulti,
                               struct Curl_easy **pmulti_admin,
                               struct cpool **pmulti_cpool,
                               struct cshutdn **pmulti_cshutdn,
                               uint32_t *pmax_total_conns,
                               uint32_t *pmaxconnects);
void Curl_easy_get_multi_cpool(struct Curl_easy *data,
                               struct Curl_multi **pmulti,
                               struct Curl_easy **pmulti_admin,
                               struct cpool **pmulti_cpool,
                               struct cshutdn **pmulti_cshutdn,
                               uint32_t *pmax_total_conns,
                               uint32_t *pmaxconnects)
{
  struct Curl_multi *multi = data ? data->multi : NULL;
  *pmulti = multi;
  *pmulti_admin = multi ? multi->admin : NULL;
  *pmulti_cpool = multi ? &multi->cpool : NULL;
  *pmulti_cshutdn = multi ? &multi->cshutdn : NULL;
  *pmax_total_conns = multi ? multi->max_total_connections : 0;
  *pmaxconnects = multi ? multi->maxconnects : 0;
}

void Curl_easy_get_conn_age_limits(struct Curl_easy *data,
                                   timediff_t *pmax_idle_ms,
                                   timediff_t *pmax_age_ms,
                                   timediff_t *pupkeep_interval_ms);
void Curl_easy_get_conn_age_limits(struct Curl_easy *data,
                                   timediff_t *pmax_idle_ms,
                                   timediff_t *pmax_age_ms,
                                   timediff_t *pupkeep_interval_ms)
{
  *pmax_idle_ms = data->set.conn_max_idle_ms;
  *pmax_age_ms = data->set.conn_max_age_ms;
  *pupkeep_interval_ms = data->set.upkeep_interval_ms;
}

#define CURL_CPOOL_INSTANCE(d) \
  ((d) ? (CURL_SHARE_KEEP_CONNECT((d)->share) ? &(d)->share->cpool : \
          ((d)->multi_easy ? &(d)->multi_easy->cpool : \
           ((d)->multi ? &(d)->multi->cpool : NULL))) : NULL)

/* progress.h wrappers */
const struct curltime *Curl_pgrs_now_zig(struct Curl_easy *data,
                                         struct Progress *p);
const struct curltime *Curl_pgrs_now(struct Curl_easy *data)
{
  return Curl_pgrs_now_zig(data, &data->progress);
}

int Curl_pgrsDone_zig(struct Curl_easy *data,
                      const struct curltime *pnow,
                      struct Progress *p,
                      bool req_done,
                      curl_off_t resume_from,
                      FILE *err,
                      curl_xferinfo_callback fxferinfo,
                      curl_progress_callback fprogress,
                      void *progress_client);
int Curl_pgrsDone(struct Curl_easy *data, const struct curltime *pnow)
{
  return Curl_pgrsDone_zig(data, pnow, &data->progress,
                           (bool)data->req.done, data->state.resume_from,
                           data->set.err, data->set.fxferinfo,
                           data->set.fprogress, data->set.progress_client);
}

void Curl_pgrsStart_zig(struct Curl_easy *data,
                        const struct curltime *pnow,
                        struct Progress *p);
void Curl_pgrsStart(struct Curl_easy *data, const struct curltime *pnow)
{
  Curl_pgrsStart_zig(data, pnow, &data->progress);
}

void Curl_pgrsSetDownloadSize_zig(struct Curl_easy *data,
                                  curl_off_t size,
                                  struct Progress *p);
void Curl_pgrsSetDownloadSize(struct Curl_easy *data, curl_off_t size)
{
  Curl_pgrsSetDownloadSize_zig(data, size, &data->progress);
}

void Curl_pgrsSetUploadSize_zig(struct Curl_easy *data,
                                curl_off_t size,
                                struct Progress *p);
void Curl_pgrsSetUploadSize(struct Curl_easy *data, curl_off_t size)
{
  Curl_pgrsSetUploadSize_zig(data, size, &data->progress);
}

CURLcode Curl_pgrs_deliver_check_zig(struct Curl_easy *data,
                                     size_t delta,
                                     const struct Progress *p,
                                     curl_off_t max_filesize);
CURLcode Curl_pgrs_deliver_check(struct Curl_easy *data, size_t delta)
{
  return Curl_pgrs_deliver_check_zig(data, delta, &data->progress,
                                     data->set.max_filesize);
}

void Curl_pgrs_deliver_inc_zig(struct Curl_easy *data,
                               size_t delta,
                               struct Progress *p);
void Curl_pgrs_deliver_inc(struct Curl_easy *data, size_t delta)
{
  Curl_pgrs_deliver_inc_zig(data, delta, &data->progress);
}

void Curl_pgrs_download_inc_zig(struct Curl_easy *data,
                                size_t delta,
                                struct Progress *p);
void Curl_pgrs_download_inc(struct Curl_easy *data, size_t delta)
{
  Curl_pgrs_download_inc_zig(data, delta, &data->progress);
}

void Curl_pgrs_upload_inc_zig(struct Curl_easy *data,
                              size_t delta,
                              struct Progress *p);
void Curl_pgrs_upload_inc(struct Curl_easy *data, size_t delta)
{
  Curl_pgrs_upload_inc_zig(data, delta, &data->progress);
}

void Curl_pgrsSetUploadCounter_zig(struct Curl_easy *data,
                                   curl_off_t size,
                                   struct Progress *p);
void Curl_pgrsSetUploadCounter(struct Curl_easy *data, curl_off_t size)
{
  Curl_pgrsSetUploadCounter_zig(data, size, &data->progress);
}

CURLcode Curl_pgrsUpdate_zig(struct Curl_easy *data,
                             struct Progress *p,
                             bool req_done,
                             curl_off_t resume_from,
                             FILE *err,
                             curl_xferinfo_callback fxferinfo,
                             curl_progress_callback fprogress,
                             void *progress_client);
CURLcode Curl_pgrsUpdate(struct Curl_easy *data)
{
  return Curl_pgrsUpdate_zig(data, &data->progress,
                             (bool)data->req.done, data->state.resume_from,
                             data->set.err, data->set.fxferinfo,
                             data->set.fprogress, data->set.progress_client);
}

CURLcode Curl_pgrsUpdateX_zig(struct Curl_easy *data,
                              const struct curltime *pnow,
                              struct Progress *p,
                              bool req_done,
                              curl_off_t resume_from,
                              FILE *err,
                              curl_xferinfo_callback fxferinfo,
                              curl_progress_callback fprogress,
                              void *progress_client);
CURLcode Curl_pgrsUpdateX(struct Curl_easy *data, const struct curltime *pnow)
{
  return Curl_pgrsUpdateX_zig(data, pnow, &data->progress,
                              (bool)data->req.done, data->state.resume_from,
                              data->set.err, data->set.fxferinfo,
                              data->set.fprogress, data->set.progress_client);
}

void Curl_pgrsUpdate_nometer_zig(struct Curl_easy *data,
                                 struct Progress *p,
                                 bool req_done);
void Curl_pgrsUpdate_nometer(struct Curl_easy *data)
{
  Curl_pgrsUpdate_nometer_zig(data, &data->progress, (bool)data->req.done);
}

CURLcode Curl_pgrsCheck_zig(struct Curl_easy *data,
                            struct Progress *p,
                            bool req_done,
                            curl_off_t resume_from,
                            FILE *err,
                            curl_xferinfo_callback fxferinfo,
                            curl_progress_callback fprogress,
                            void *progress_client,
                            uint32_t low_speed_time,
                            curl_off_t low_speed_limit,
                            struct curltime *keeps_speed);
CURLcode Curl_pgrsCheck(struct Curl_easy *data)
{
  return Curl_pgrsCheck_zig(data, &data->progress,
                            (bool)data->req.done, data->state.resume_from,
                            data->set.err, data->set.fxferinfo,
                            data->set.fprogress, data->set.progress_client,
                            data->set.low_speed_time, data->set.low_speed_limit,
                            &data->state.keeps_speed);
}

CURLcode Curl_pgrsCheckX_zig(struct Curl_easy *data,
                             const struct curltime *pnow,
                             struct Progress *p,
                             bool req_done,
                             curl_off_t resume_from,
                             FILE *err,
                             curl_xferinfo_callback fxferinfo,
                             curl_progress_callback fprogress,
                             void *progress_client,
                             uint32_t low_speed_time,
                             curl_off_t low_speed_limit,
                             struct curltime *keeps_speed);
CURLcode Curl_pgrsCheckX(struct Curl_easy *data, const struct curltime *pnow)
{
  return Curl_pgrsCheckX_zig(data, pnow, &data->progress,
                             (bool)data->req.done, data->state.resume_from,
                             data->set.err, data->set.fxferinfo,
                             data->set.fprogress, data->set.progress_client,
                             data->set.low_speed_time, data->set.low_speed_limit,
                             &data->state.keeps_speed);
}

void Curl_pgrsRecvPause_zig(struct Curl_easy *data,
                            bool enable,
                            struct Progress *p,
                            struct curltime *keeps_speed);
void Curl_pgrsRecvPause(struct Curl_easy *data, bool enable)
{
  Curl_pgrsRecvPause_zig(data, enable, &data->progress,
                         &data->state.keeps_speed);
}

void Curl_pgrsSendPause_zig(struct Curl_easy *data,
                            bool enable,
                            struct Progress *p,
                            struct curltime *keeps_speed);
void Curl_pgrsSendPause(struct Curl_easy *data, bool enable)
{
  Curl_pgrsSendPause_zig(data, enable, &data->progress,
                         &data->state.keeps_speed);
}

void Curl_pgrsReset_zig(struct Curl_easy *data,
                        struct Progress *p,
                        struct curltime *keeps_speed);
void Curl_pgrsReset(struct Curl_easy *data)
{
  Curl_pgrsReset_zig(data, &data->progress, &data->state.keeps_speed);
}

void Curl_pgrsResetTransferSizes_zig(struct Curl_easy *data,
                                     struct Progress *p);
void Curl_pgrsResetTransferSizes(struct Curl_easy *data)
{
  Curl_pgrsResetTransferSizes_zig(data, &data->progress);
}

void Curl_pgrsTime_zig(struct Curl_easy *data,
                       timerid timer,
                       struct Progress *p);
void Curl_pgrsTime(struct Curl_easy *data, timerid timer)
{
  Curl_pgrsTime_zig(data, timer, &data->progress);
}

void Curl_pgrsTimeWas_zig(struct Curl_easy *data,
                          timerid timer,
                          struct curltime timestamp,
                          struct Progress *p);
void Curl_pgrsTimeWas(struct Curl_easy *data, timerid timer,
                      struct curltime timestamp)
{
  Curl_pgrsTimeWas_zig(data, timer, timestamp, &data->progress);
}

void Curl_pgrsEarlyData_zig(struct Curl_easy *data,
                            curl_off_t sent,
                            struct Progress *p);
void Curl_pgrsEarlyData(struct Curl_easy *data, curl_off_t sent)
{
  Curl_pgrsEarlyData_zig(data, sent, &data->progress);
}

void Curl_pgrsCompleted_zig(struct Curl_easy *data,
                            struct Progress *p);
void Curl_pgrsCompleted(struct Curl_easy *data)
{
  Curl_pgrsCompleted_zig(data, &data->progress);
}

timediff_t Curl_pgrs_since_ms_zig(struct Curl_easy *data,
                                  const struct curltime *pnow,
                                  timerid timer,
                                  struct Progress *p);
timediff_t Curl_pgrs_since_ms(struct Curl_easy *data,
                              const struct curltime *pnow,
                              timerid timer)
{
  return Curl_pgrs_since_ms_zig(data, pnow, timer, &data->progress);
}

CURLcode pgrs_speedcheck_zig(struct Curl_easy *data,
                             const struct curltime *pnow,
                             struct Progress *p,
                             uint32_t low_speed_time,
                             curl_off_t low_speed_limit,
                             struct curltime *keeps_speed);
CURLcode pgrs_speedcheck(struct Curl_easy *data, const struct curltime *pnow);
CURLcode pgrs_speedcheck(struct Curl_easy *data, const struct curltime *pnow)
{
  return pgrs_speedcheck_zig(data, pnow, &data->progress,
                             data->set.low_speed_time, data->set.low_speed_limit,
                             &data->state.keeps_speed);
}

/* cfilters.h wrappers */
void Curl_conn_cf_add_zig(struct Curl_easy *data,
                          struct connectdata *conn,
                          int8_t sockindex,
                          struct Curl_cfilter *cf,
                          struct Curl_cfilter **conn_cfilters);
void Curl_conn_cf_add(struct Curl_easy *data,
                      struct connectdata *conn,
                      int8_t sockindex,
                      struct Curl_cfilter *cf)
{
  Curl_conn_cf_add_zig(data, conn, sockindex, cf, conn->cfilter);
}

bool Curl_conn_cf_discard_zig(struct Curl_cfilter **pcf,
                              struct Curl_easy *data,
                              struct Curl_cfilter **conn_cfilters);
bool Curl_conn_cf_discard(struct Curl_cfilter **pcf,
                          struct Curl_easy *data)
{
  return Curl_conn_cf_discard_zig(pcf, data,
                                  (*pcf && (*pcf)->conn) ?
                                  (*pcf)->conn->cfilter : NULL);
}

void Curl_conn_cf_discard_all_zig(struct Curl_easy *data,
                                  struct connectdata *conn, int8_t sockindex,
                                  struct Curl_cfilter **conn_cfilters,
                                  timediff_t *shutdown_start_ms);
void Curl_conn_cf_discard_all(struct Curl_easy *data,
                              struct connectdata *conn, int8_t sockindex)
{
  Curl_conn_cf_discard_all_zig(data, conn, sockindex, conn->cfilter,
                               conn->shutdown.start_ms);
}

unsigned char Curl_conn_cf_get_transport_zig(struct Curl_cfilter *cf,
                                             struct Curl_easy *data,
                                             uint8_t transport_wanted);
unsigned char Curl_conn_cf_get_transport(struct Curl_cfilter *cf,
                                         struct Curl_easy *data)
{
  return Curl_conn_cf_get_transport_zig(cf, data,
                                        (data && data->conn) ?
                                        data->conn->transport_wanted : 0);
}

bool Curl_conn_is_setup_zig(struct connectdata *conn, int8_t sockindex,
                            struct Curl_cfilter * const *conn_cfilters);
bool Curl_conn_is_setup(struct connectdata *conn, int8_t sockindex)
{
  return Curl_conn_is_setup_zig(conn, sockindex,
                                conn ? conn->cfilter : NULL);
}

bool Curl_conn_is_connected_zig(struct connectdata *conn, int8_t sockindex,
                                struct Curl_cfilter * const *conn_cfilters,
                                unsigned int scheme_flags);
bool Curl_conn_is_connected(struct connectdata *conn, int8_t sockindex)
{
  return Curl_conn_is_connected_zig(conn, sockindex,
                                    conn ? conn->cfilter : NULL,
                                    (conn && conn->scheme) ?
                                    conn->scheme->flags : 0);
}

bool Curl_conn_is_ip_connected_zig(struct Curl_easy *data, int8_t sockindex,
                                   struct Curl_cfilter * const *conn_cfilters);
bool Curl_conn_is_ip_connected(struct Curl_easy *data, int8_t sockindex)
{
  return Curl_conn_is_ip_connected_zig(data, sockindex,
                                       data->conn->cfilter);
}

bool Curl_conn_is_ssl_zig(struct connectdata *conn, int8_t sockindex,
                          struct Curl_cfilter * const *conn_cfilters);
bool Curl_conn_is_ssl(struct connectdata *conn, int8_t sockindex)
{
  return Curl_conn_is_ssl_zig(conn, sockindex,
                              conn ? conn->cfilter : NULL);
}

bool Curl_conn_is_tunneling_zig(struct connectdata *conn, int8_t sockindex,
                                struct Curl_cfilter * const *conn_cfilters);
bool Curl_conn_is_tunneling(struct connectdata *conn, int8_t sockindex)
{
  return Curl_conn_is_tunneling_zig(conn, sockindex,
                                    conn ? conn->cfilter : NULL);
}

bool Curl_conn_get_ssl_info_zig(struct Curl_easy *data,
                                struct connectdata *conn, int8_t sockindex,
                                int query,
                                struct curl_tlssessioninfo *info,
                                struct Curl_cfilter * const *conn_cfilters);
bool Curl_conn_get_ssl_info(struct Curl_easy *data,
                            struct connectdata *conn, int8_t sockindex,
                            int query,
                            struct curl_tlssessioninfo *info)
{
  return Curl_conn_get_ssl_info_zig(data, conn, sockindex, query, info,
                                    conn ? conn->cfilter : NULL);
}

CURLcode Curl_conn_get_ip_info_zig(struct Curl_easy *data,
                                   struct connectdata *conn, int8_t sockindex,
                                   bool *is_ipv6, struct ip_quadruple *ipquad,
                                   struct Curl_cfilter * const *conn_cfilters);
CURLcode Curl_conn_get_ip_info(struct Curl_easy *data,
                               struct connectdata *conn, int8_t sockindex,
                               bool *is_ipv6, struct ip_quadruple *ipquad)
{
  return Curl_conn_get_ip_info_zig(data, conn, sockindex, is_ipv6, ipquad,
                                   conn->cfilter);
}

bool Curl_conn_is_multiplex_zig(struct connectdata *conn, int8_t sockindex,
                                struct Curl_cfilter * const *conn_cfilters);
bool Curl_conn_is_multiplex(struct connectdata *conn, int8_t sockindex)
{
  return Curl_conn_is_multiplex_zig(conn, sockindex,
                                    conn ? conn->cfilter : NULL);
}

unsigned char Curl_conn_http_version_zig(struct Curl_easy *data,
                                         struct connectdata *conn,
                                         struct Curl_cfilter * const *conn_cfilters);
unsigned char Curl_conn_http_version(struct Curl_easy *data,
                                     struct connectdata *conn)
{
  return Curl_conn_http_version_zig(data, conn,
                                    conn ? conn->cfilter : NULL);
}

unsigned char Curl_conn_get_transport_zig(struct Curl_easy *data,
                                          struct connectdata *conn,
                                          struct Curl_cfilter * const *conn_cfilters,
                                          uint8_t transport_wanted);
unsigned char Curl_conn_get_transport(struct Curl_easy *data,
                                      struct connectdata *conn)
{
  return Curl_conn_get_transport_zig(data, conn, conn->cfilter,
                                     conn->transport_wanted);
}

const char *Curl_conn_get_alpn_negotiated_zig(struct Curl_easy *data,
                                              struct connectdata *conn,
                                              struct Curl_cfilter * const *conn_cfilters);
const char *Curl_conn_get_alpn_negotiated(struct Curl_easy *data,
                                          struct connectdata *conn)
{
  return Curl_conn_get_alpn_negotiated_zig(data, conn, conn->cfilter);
}

void Curl_conn_cntrl_update_info_zig(struct Curl_easy *data,
                                     struct connectdata *conn,
                                     struct Curl_cfilter * const *conn_cfilters);
void Curl_conn_cntrl_update_info(struct Curl_easy *data,
                                 struct connectdata *conn)
{
  Curl_conn_cntrl_update_info_zig(data, conn, conn->cfilter);
}

void Curl_conn_cntrl_report_stats_zig(struct Curl_easy *data,
                                      struct connectdata *conn,
                                      int sockindex,
                                      struct Curl_cfilter * const *conn_cfilters);
void Curl_conn_cntrl_report_stats(struct Curl_easy *data,
                                  struct connectdata *conn,
                                  int sockindex)
{
  Curl_conn_cntrl_report_stats_zig(data, conn, sockindex, conn->cfilter);
}

void Curl_conn_remove_setup_filters_zig(struct Curl_easy *data,
                                        int8_t sockindex,
                                        struct Curl_cfilter **conn_cfilters);
void Curl_conn_remove_setup_filters(struct Curl_easy *data,
                                    int8_t sockindex)
{
  Curl_conn_remove_setup_filters_zig(data, sockindex,
                                     data->conn ? data->conn->cfilter : NULL);
}

bool Curl_conn_data_pending_zig(struct Curl_easy *data,
                                int8_t sockindex,
                                struct Curl_cfilter * const *conn_cfilters);
bool Curl_conn_data_pending(struct Curl_easy *data,
                            int8_t sockindex)
{
  return Curl_conn_data_pending_zig(data, sockindex, data->conn->cfilter);
}

bool Curl_conn_needs_flush_zig(struct Curl_easy *data, int8_t sockindex,
                               struct Curl_cfilter * const *conn_cfilters);
bool Curl_conn_needs_flush(struct Curl_easy *data, int8_t sockindex)
{
  return Curl_conn_needs_flush_zig(data, sockindex, data->conn->cfilter);
}

CURLcode Curl_conn_flush_zig(struct Curl_easy *data, int8_t sockindex,
                             struct Curl_cfilter * const *conn_cfilters);
CURLcode Curl_conn_flush(struct Curl_easy *data, int8_t sockindex)
{
  return Curl_conn_flush_zig(data, sockindex, data->conn->cfilter);
}

curl_socket_t Curl_conn_get_first_socket_zig(struct Curl_easy *data,
                                             struct Curl_cfilter * const *conn_cfilters,
                                             const curl_socket_t *conn_sock);
curl_socket_t Curl_conn_get_first_socket(struct Curl_easy *data)
{
  return Curl_conn_get_first_socket_zig(data,
                                        data->conn ? data->conn->cfilter : NULL,
                                        data->conn ? data->conn->sock : NULL);
}

const struct Curl_sockaddr_ex *
Curl_conn_get_remote_addr_zig(struct Curl_easy *data, int8_t sockindex,
                              struct Curl_cfilter * const *conn_cfilters);
const struct Curl_sockaddr_ex *
Curl_conn_get_remote_addr(struct Curl_easy *data, int8_t sockindex)
{
  return Curl_conn_get_remote_addr_zig(data, sockindex,
                                       data->conn ? data->conn->cfilter : NULL);
}

CURLcode Curl_conn_adjust_pollset_zig(struct Curl_easy *data,
                                      struct connectdata *conn,
                                      struct easy_pollset *ps,
                                      struct Curl_cfilter **conn_cfilters,
                                      const timediff_t *shutdown_start_ms);
CURLcode Curl_conn_adjust_pollset(struct Curl_easy *data,
                                  struct connectdata *conn,
                                  struct easy_pollset *ps)
{
  return Curl_conn_adjust_pollset_zig(data, conn, ps, conn->cfilter,
                                      conn->shutdown.start_ms);
}

CURLcode Curl_conn_ev_data_setup_zig(struct Curl_easy *data,
                                     struct Curl_cfilter **conn_cfilters,
                                     const timediff_t *shutdown_start_ms);
CURLcode Curl_conn_ev_data_setup(struct Curl_easy *data)
{
  return Curl_conn_ev_data_setup_zig(data, data->conn->cfilter,
                                     data->conn->shutdown.start_ms);
}

void Curl_conn_ev_data_done_send_zig(struct Curl_easy *data,
                                     struct Curl_cfilter **conn_cfilters,
                                     const timediff_t *shutdown_start_ms);
void Curl_conn_ev_data_done_send(struct Curl_easy *data)
{
  Curl_conn_ev_data_done_send_zig(data, data->conn->cfilter,
                                  data->conn->shutdown.start_ms);
}

void Curl_conn_ev_data_done_zig(struct Curl_easy *data, bool premature,
                                struct Curl_cfilter **conn_cfilters,
                                const timediff_t *shutdown_start_ms);
void Curl_conn_ev_data_done(struct Curl_easy *data, bool premature)
{
  Curl_conn_ev_data_done_zig(data, premature, data->conn->cfilter,
                             data->conn->shutdown.start_ms);
}

CURLcode Curl_conn_ev_data_pause_zig(struct Curl_easy *data, bool do_pause,
                                     struct Curl_cfilter **conn_cfilters,
                                     const timediff_t *shutdown_start_ms);
CURLcode Curl_conn_ev_data_pause(struct Curl_easy *data, bool do_pause)
{
  return Curl_conn_ev_data_pause_zig(data, do_pause, data->conn->cfilter,
                                     data->conn->shutdown.start_ms);
}

bool Curl_conn_is_alive_zig(struct Curl_easy *data, struct connectdata *conn,
                            bool *input_pending,
                            struct Curl_cfilter * const *conn_cfilters,
                            bool conn_bits_close);
bool Curl_conn_is_alive(struct Curl_easy *data, struct connectdata *conn,
                        bool *input_pending)
{
  return Curl_conn_is_alive_zig(data, conn, input_pending,
                                conn->cfilter, (bool)conn->bits.close);
}

CURLcode Curl_conn_keep_alive_zig(struct Curl_easy *data,
                                  struct connectdata *conn,
                                  struct Curl_cfilter **conn_cfilters,
                                  const timediff_t *shutdown_start_ms);
CURLcode Curl_conn_keep_alive(struct Curl_easy *data,
                              struct connectdata *conn)
{
  return Curl_conn_keep_alive_zig(data, conn, conn->cfilter,
                                  conn->shutdown.start_ms);
}

void Curl_conn_get_current_host_zig(struct Curl_easy *data, int8_t sockindex,
                                    const char **phost, int *pport,
                                    struct Curl_cfilter * const *conn_cfilters,
                                    const char *origin_hostname,
                                    int origin_port);
void Curl_conn_get_current_host(struct Curl_easy *data, int8_t sockindex,
                                const char **phost, int *pport)
{
  Curl_conn_get_current_host_zig(data, sockindex, phost, pport,
                                 data->conn->cfilter,
                                 data->conn->origin->hostname,
                                 data->conn->origin->port);
}

size_t Curl_conn_get_max_concurrent_zig(struct Curl_easy *data,
                                        struct connectdata *conn,
                                        int8_t sockindex,
                                        struct Curl_cfilter * const *conn_cfilters);
size_t Curl_conn_get_max_concurrent(struct Curl_easy *data,
                                    struct connectdata *conn,
                                    int8_t sockindex)
{
  return Curl_conn_get_max_concurrent_zig(data, conn, sockindex,
                                          conn->cfilter);
}

int Curl_conn_get_stream_error_zig(struct Curl_easy *data,
                                   struct connectdata *conn,
                                   int8_t sockindex,
                                   struct Curl_cfilter * const *conn_cfilters);
int Curl_conn_get_stream_error(struct Curl_easy *data,
                               struct connectdata *conn,
                               int8_t sockindex)
{
  return Curl_conn_get_stream_error_zig(data, conn, sockindex, conn->cfilter);
}

#ifdef CURLVERBOSE
void Curl_conn_trc_filters_zig(struct Curl_easy *data,
                               int8_t sockindex, const char *info,
                               struct Curl_cfilter * const *conn_cfilters);
void Curl_conn_trc_filters(struct Curl_easy *data,
                           int8_t sockindex, const char *info)
{
  Curl_conn_trc_filters_zig(data, sockindex, info,
                            data->conn ? data->conn->cfilter : NULL);
}
#endif

int8_t Curl_conn_sockindex_zig(struct Curl_easy *data, curl_socket_t sockfd,
                               const curl_socket_t *conn_sock);
int8_t Curl_conn_sockindex(struct Curl_easy *data, curl_socket_t sockfd)
{
  return Curl_conn_sockindex_zig(data, sockfd,
                                 (data && data->conn) ? data->conn->sock : NULL);
}

CURLcode Curl_conn_recv_zig(struct Curl_easy *data, int8_t sockindex,
                            char *buf, size_t len, size_t *pnread,
                            const void *conn_recv);
CURLcode Curl_conn_recv(struct Curl_easy *data, int8_t sockindex,
                        char *buf, size_t len, size_t *pnread)
{
  return Curl_conn_recv_zig(data, sockindex, buf, len, pnread,
                            data->conn ? data->conn->recv : NULL);
}

CURLcode Curl_conn_send_zig(struct Curl_easy *data, int8_t sockindex,
                            const void *buf, size_t len, bool eos,
                            size_t *pnwritten,
                            const void *conn_send);
CURLcode Curl_conn_send(struct Curl_easy *data, int8_t sockindex,
                        const void *buf, size_t len, bool eos,
                        size_t *pnwritten)
{
  return Curl_conn_send_zig(data, sockindex, buf, len, eos, pnwritten,
                            data->conn ? data->conn->send : NULL);
}

/* conncache.h wrappers */
void Curl_conn_close_zig(struct Curl_easy *data,
                         struct connectdata *conn,
                         bool aborted,
                         struct cpool *cpool);
void Curl_conn_close(struct Curl_easy *data,
                     struct connectdata *conn,
                     bool aborted)
{
  Curl_conn_close_zig(data, conn, aborted, CURL_CPOOL_INSTANCE(data));
}

struct cpool *Curl_cpool_get_instance_zig(struct Curl_easy *data,
                                          struct cpool *cpool);
struct cpool *Curl_cpool_get_instance(struct Curl_easy *data)
{
  return Curl_cpool_get_instance_zig(data, CURL_CPOOL_INSTANCE(data));
}

void Curl_cpool_xfer_init_zig(struct Curl_easy *data,
                              struct cpool *cpool,
                              curl_off_t *p_easy_id,
                              curl_off_t *p_last_conn_id,
                              uint32_t *p_last_cpid);
void Curl_cpool_xfer_init(struct Curl_easy *data)
{
  Curl_cpool_xfer_init_zig(data, CURL_CPOOL_INSTANCE(data),
                           &data->id, &data->state.last_conn_id,
                           &data->state.last_cpid);
}

struct connectdata *Curl_cpool_get_last_conn_zig(struct Curl_easy *data,
                                                 struct cpool *cpool,
                                                 curl_off_t *p_last_conn_id,
                                                 uint32_t *p_last_cpid);
struct connectdata *Curl_cpool_get_last_conn(struct Curl_easy *data)
{
  return Curl_cpool_get_last_conn_zig(data, CURL_CPOOL_INSTANCE(data),
                                      &data->state.last_conn_id,
                                      &data->state.last_cpid);
}

CURLcode Curl_cpool_add_zig(struct Curl_easy *data,
                            struct connectdata *conn,
                            uint32_t max_total,
                            uint32_t max_host,
                            const struct curltime *pnow,
                            struct cpool *cpool,
                            bool data_internal);
CURLcode Curl_cpool_add(struct Curl_easy *data,
                        struct connectdata *conn,
                        uint32_t max_total,
                        uint32_t max_host,
                        const struct curltime *pnow)
{
  return Curl_cpool_add_zig(data, conn, max_total, max_host, pnow,
                            CURL_CPOOL_INSTANCE(data),
                            (bool)data->state.internal);
}

void Curl_cpool_conn_was_used_zig(struct Curl_easy *data,
                                  struct connectdata *conn,
                                  const struct curltime *pnow,
                                  const struct curltime *conn_created,
                                  timediff_t *p_lastupkeep_ms);
void Curl_cpool_conn_was_used(struct Curl_easy *data,
                              struct connectdata *conn,
                              const struct curltime *pnow)
{
  Curl_cpool_conn_was_used_zig(data, conn, pnow, &conn->created,
                               &conn->lastupkeep_ms);
}

timediff_t Curl_cpool_conn_age_ms_zig(struct Curl_easy *data,
                                      struct connectdata *conn,
                                      const struct curltime *pnow,
                                      const struct curltime *conn_created);
timediff_t Curl_cpool_conn_age_ms(struct Curl_easy *data,
                                  struct connectdata *conn,
                                  const struct curltime *pnow)
{
  return Curl_cpool_conn_age_ms_zig(data, conn, pnow, &conn->created);
}

bool Curl_cpool_find_zig(struct Curl_easy *data,
                         const char *destination,
                         bool prune_dead,
                         const struct curltime *pnow,
                         Curl_cpool_conn_match_cb *conn_cb,
                         Curl_cpool_done_match_cb *done_cb,
                         void *userdata,
                         struct cpool *cpool,
                         curl_off_t *p_last_conn_id,
                         uint32_t *p_last_cpid);
bool Curl_cpool_find(struct Curl_easy *data,
                     const char *destination,
                     bool prune_dead,
                     const struct curltime *pnow,
                     Curl_cpool_conn_match_cb *conn_cb,
                     Curl_cpool_done_match_cb *done_cb,
                     void *userdata)
{
  return Curl_cpool_find_zig(data, destination, prune_dead, pnow,
                             conn_cb, done_cb, userdata,
                             CURL_CPOOL_INSTANCE(data),
                             &data->state.last_conn_id,
                             &data->state.last_cpid);
}

CURLcode Curl_cpool_upkeep_zig(struct Curl_easy *data,
                               struct cpool *cpool);
CURLcode Curl_cpool_upkeep(struct Curl_easy *data)
{
  return Curl_cpool_upkeep_zig(data, CURL_CPOOL_INSTANCE(data));
}

void Curl_cpool_return_zig(struct Curl_easy *data,
                           struct connectdata *conn,
                           Curl_cpool_return_cb *cb, void *cbdata,
                           const struct curltime *pnow,
                           struct cpool *cpool,
                           curl_off_t *p_last_conn_id,
                           uint32_t *p_last_cpid);
void Curl_cpool_return(struct Curl_easy *data,
                       struct connectdata *conn,
                       Curl_cpool_return_cb *cb, void *cbdata,
                       const struct curltime *pnow)
{
  Curl_cpool_return_zig(data, conn, cb, cbdata, pnow,
                        CURL_CPOOL_INSTANCE(data),
                        &data->state.last_conn_id, &data->state.last_cpid);
}

#include "pingpong.h"
#include "curl_sasl.h"
#include "mime.h"
#include "vtls/vtls.h"

struct connectdata *Curl_pop3_smtp_get_conn(struct Curl_easy *data)
{
  return data->conn;
}

const char *Curl_pop3_smtp_get_conn_options(const struct connectdata *conn)
{
  return conn->options;
}

bool Curl_pop3_smtp_conn_has_creds(const struct connectdata *conn)
{
  return conn->creds != NULL;
}

bool Curl_pop3_smtp_easy_has_creds(const struct Curl_easy *data)
{
  return data->state.creds != NULL;
}

const char *Curl_pop3_smtp_get_conn_user(const struct connectdata *conn)
{
  return Curl_creds_user(conn->creds);
}

const char *Curl_pop3_smtp_get_conn_passwd(const struct connectdata *conn)
{
  return Curl_creds_passwd(conn->creds);
}

bool Curl_pop3_smtp_get_protoconnstart(const struct connectdata *conn)
{
  return (bool)conn->bits.protoconnstart;
}

void Curl_pop3_smtp_connclose(struct connectdata *conn)
{
  connclose(conn);
}

bool Curl_pop3_smtp_conn_is_ssl(struct connectdata *conn)
{
  return Curl_conn_is_ssl(conn, FIRSTSOCKET);
}

bool Curl_pop3_smtp_conn_is_connected(struct connectdata *conn)
{
  return Curl_conn_is_connected(conn, FIRSTSOCKET);
}

CURLcode Curl_pop3_smtp_upgrade_tls(struct Curl_easy *data,
                                    struct connectdata *conn,
                                    bool is_smtp,
                                    bool *ssldone)
{
#ifdef USE_SSL
  CURLcode result;
  *ssldone = FALSE;
  if(!Curl_conn_is_ssl(conn, FIRSTSOCKET)) {
    result = Curl_ssl_cfilter_add(
      data, Curl_conn_get_origin(conn, FIRSTSOCKET), conn, FIRSTSOCKET);
    if(result)
      return result;
    conn->scheme = is_smtp ? &Curl_scheme_smtps : &Curl_scheme_pop3s;
  }
  result = Curl_conn_connect(data, FIRSTSOCKET, FALSE, ssldone);
  return result;
#else
  (void)data;
  (void)conn;
  (void)is_smtp;
  *ssldone = FALSE;
  return CURLE_NOT_BUILT_IN;
#endif
}

const char *Curl_pop3_smtp_get_up_path(const struct Curl_easy *data)
{
  return data->state.up.path;
}

const char *Curl_pop3_smtp_get_customrequest(const struct Curl_easy *data)
{
  return CURL_EASY_STR((struct Curl_easy *)data, STRING_CUSTOMREQUEST);
}

const char *Curl_pop3_smtp_get_mail_from(const struct Curl_easy *data)
{
  return CURL_EASY_STR((struct Curl_easy *)data, STRING_MAIL_FROM);
}

const char *Curl_pop3_smtp_get_mail_auth(const struct Curl_easy *data)
{
  return CURL_EASY_STR((struct Curl_easy *)data, STRING_MAIL_AUTH);
}

bool Curl_pop3_smtp_get_list_only(const struct Curl_easy *data)
{
  return (bool)data->set.list_only;
}

unsigned char Curl_pop3_smtp_get_use_ssl(const struct Curl_easy *data)
{
  return (unsigned char)data->set.use_ssl;
}

bool Curl_pop3_smtp_get_connect_only(const struct Curl_easy *data)
{
  return (bool)data->set.connect_only;
}

struct curl_slist *Curl_pop3_smtp_get_mail_rcpt(const struct Curl_easy *data)
{
  return data->set.mail_rcpt;
}

bool Curl_pop3_smtp_get_mail_rcpt_allowfails(const struct Curl_easy *data)
{
  return (bool)data->set.mail_rcpt_allowfails;
}

bool Curl_pop3_smtp_get_req_no_body(const struct Curl_easy *data)
{
  return (bool)data->req.no_body;
}

void Curl_pop3_smtp_set_req_no_body(struct Curl_easy *data, bool val)
{
  data->req.no_body = val;
}

void Curl_pop3_smtp_set_req_size(struct Curl_easy *data, curl_off_t size)
{
  data->req.size = size;
}

void Curl_pop3_smtp_req_clear_recv(struct Curl_easy *data)
{
  CURL_REQ_CLEAR_RECV(data);
}

curl_off_t Curl_pop3_smtp_get_infilesize(const struct Curl_easy *data)
{
  return data->state.infilesize;
}

void Curl_pop3_smtp_inc_infilesize(struct Curl_easy *data)
{
  if(data->state.infilesize > 0)
    data->state.infilesize++;
}

void Curl_pop3_smtp_set_httpcode(struct Curl_easy *data, int code)
{
  data->info.httpcode = code;
}

bool Curl_pop3_smtp_is_upload_or_mime(const struct Curl_easy *data)
{
  return (bool)(data->state.upload || IS_MIME_POST(data));
}

CURLcode Curl_pop3_smtp_prepare_mail_reader(struct Curl_easy *data)
{
  CURLcode result = CURLE_OK;
#ifndef CURL_DISABLE_MIME
  if(IS_MIME_POST(data)) {
    curl_mimepart *postp = data->set.mimepostp;
    postp->flags &= ~(unsigned int)MIME_BODY_ONLY;
    curl_mime_headers(postp, data->set.headers, 0);
    result = Curl_mime_prepare_headers(data, postp, NULL,
                                       NULL, MIMESTRATEGY_MAIL);
    if(!result && !Curl_checkheaders(data, STRCONST("Mime-Version")))
      result = Curl_mime_add_header(&postp->curlheaders, "Mime-Version: 1.0");
    if(!result)
      result = Curl_creader_set_mime(data, postp);
    if(result)
      return result;
    data->state.infilesize = Curl_creader_total_length(data);
  }
  else
#endif
  {
    result = Curl_creader_set_fread(data, data->state.infilesize);
  }
  return result;
}

void Curl_pop3_smtp_pp_init(struct Curl_easy *data, struct pingpong *pp)
{
  Curl_pp_init(pp, Curl_pgrs_now(data));
}

CURLcode Curl_pop3_smtp_pp_statemach(struct Curl_easy *data,
                                     struct pingpong *pp,
                                     bool block,
                                     bool disconnecting)
{
  return Curl_pp_statemach(data, pp, block, disconnecting);
}

CURLcode Curl_pop3_smtp_pp_readresp(struct Curl_easy *data,
                                    int sockindex,
                                    struct pingpong *pp,
                                    int *code,
                                    size_t *size)
{
  return Curl_pp_readresp(data, (int8_t)sockindex, pp, code, size);
}

CURLcode Curl_pop3_smtp_pp_pollset(struct Curl_easy *data,
                                   struct pingpong *pp,
                                   struct easy_pollset *ps)
{
  return Curl_pp_pollset(data, pp, ps);
}

void Curl_pop3_smtp_sasl_init(struct SASL *sasl,
                              struct Curl_easy *data,
                              const struct SASLproto *params)
{
  Curl_sasl_init(sasl, data, params);
}

bool Curl_pop3_smtp_sasl_can_authenticate(struct SASL *sasl,
                                          struct Curl_easy *data)
{
  return Curl_sasl_can_authenticate(sasl, data);
}

CURLcode Curl_pop3_smtp_sasl_start(struct SASL *sasl,
                                   struct Curl_easy *data,
                                   bool force_ir,
                                   saslprogress *progress)
{
  return Curl_sasl_start(sasl, data, force_ir, progress);
}

CURLcode Curl_pop3_smtp_sasl_continue(struct SASL *sasl,
                                      struct Curl_easy *data,
                                      int code,
                                      saslprogress *progress)
{
  return Curl_sasl_continue(sasl, data, code, progress);
}

CURLcode Curl_pop3_smtp_sasl_is_blocked(struct SASL *sasl,
                                        struct Curl_easy *data)
{
  return Curl_sasl_is_blocked(sasl, data);
}

unsigned short Curl_pop3_smtp_sasl_decode_mech(const char *ptr,
                                               size_t maxlen,
                                               size_t *len)
{
  return Curl_sasl_decode_mech(ptr, maxlen, len);
}

CURLcode Curl_pop3_smtp_sasl_parse_url_auth_option(struct SASL *sasl,
                                                   const char *value,
                                                   size_t len)
{
  return Curl_sasl_parse_url_auth_option(sasl, value, len);
}

unsigned short Curl_pop3_smtp_sasl_get_prefmech(const struct SASL *sasl)
{
  return sasl->prefmech;
}

void Curl_pop3_smtp_sasl_set_prefmech(struct SASL *sasl,
                                      unsigned short prefmech)
{
  sasl->prefmech = prefmech;
}

void Curl_pop3_smtp_sasl_set_authmechs(struct SASL *sasl,
                                       unsigned short authmechs)
{
  sasl->authmechs = authmechs;
}

void Curl_pop3_smtp_sasl_or_authmechs(struct SASL *sasl,
                                      unsigned short mech)
{
  sasl->authmechs |= mech;
}

unsigned short Curl_pop3_smtp_sasl_get_authused(const struct SASL *sasl)
{
  return sasl->authused;
}

void Curl_pop3_smtp_sasl_set_authused(struct SASL *sasl,
                                      unsigned short authused)
{
  sasl->authused = authused;
}

void Curl_pop3_smtp_failf_msg(struct Curl_easy *data, const char *msg)
{
  failf(data, "%s", msg);
}

void Curl_pop3_smtp_failf_int(struct Curl_easy *data,
                              const char *fmt,
                              int arg)
{
  failf(data, fmt, arg);
}

void Curl_pop3_smtp_trc_m(struct Curl_easy *data, const char *msg)
{
  CURL_TRC_M(data, "%s", msg);
}

void Curl_pop3_smtp_trc_smtp_msg(struct Curl_easy *data, const char *msg)
{
  CURL_TRC_SMTP(data, "%s", msg);
}

void Curl_pop3_smtp_trc_smtp_state(struct Curl_easy *data,
                                   const char *from,
                                   const char *to)
{
  CURL_TRC_SMTP(data, "state change from %s to %s", from, to);
}

void Curl_pop3_smtp_trc_smtp_int(struct Curl_easy *data,
                                 const char *fmt,
                                 int a1)
{
  CURL_TRC_SMTP(data, fmt, a1);
}

void Curl_pop3_smtp_trc_smtp_int_int(struct Curl_easy *data,
                                     const char *fmt,
                                     int a1,
                                     int a2)
{
  CURL_TRC_SMTP(data, fmt, a1, a2);
}

void Curl_pop3_smtp_trc_smtp_int_int_int(struct Curl_easy *data,
                                         const char *fmt,
                                         int a1,
                                         int a2,
                                         int a3)
{
  CURL_TRC_SMTP(data, fmt, a1, a2, a3);
}

void Curl_pop3_smtp_trc_smtp_read(struct Curl_easy *data,
                                  size_t blen,
                                  int res,
                                  size_t nread,
                                  int eos)
{
  CURL_TRC_SMTP(data, "cr_eob_read, next_read(len=%zu) -> %d, %zu eos=%d",
                blen, res, nread, eos);
}

void Curl_pop3_smtp_infof_msg(struct Curl_easy *data, const char *msg)
{
  infof(data, "%s", msg);
}

/* Accessor helpers for Zig protocol handlers (gopher, dict, file, mqtt) */

struct connectdata *Curl_proto_get_conn(struct Curl_easy *data)
{
  return data->conn;
}

curl_socket_t Curl_proto_get_firstsocket(struct Curl_easy *data)
{
  return data->conn->sock[FIRSTSOCKET];
}

const char *Curl_proto_get_up_path(struct Curl_easy *data)
{
  return data->state.up.path;
}

const char *Curl_proto_get_up_query(struct Curl_easy *data)
{
  return data->state.up.query;
}

bool Curl_proto_is_upload(struct Curl_easy *data)
{
  return data->state.upload;
}

curl_off_t Curl_proto_get_resume_from(struct Curl_easy *data)
{
  return data->state.resume_from;
}

void Curl_proto_set_resume_from(struct Curl_easy *data, curl_off_t val)
{
  data->state.resume_from = val;
}

uint32_t Curl_proto_get_new_file_perms(struct Curl_easy *data)
{
  return data->set.new_file_perms;
}

curl_off_t Curl_proto_get_infilesize(struct Curl_easy *data)
{
  return data->state.infilesize;
}

time_t Curl_proto_get_filetime(struct Curl_easy *data)
{
  return data->info.filetime;
}

void Curl_proto_set_filetime(struct Curl_easy *data, time_t val)
{
  data->info.filetime = val;
}

bool Curl_proto_has_range(struct Curl_easy *data)
{
  return data->state.range != NULL;
}

bool Curl_proto_has_timecondition(struct Curl_easy *data)
{
  return data->set.timecondition != 0;
}

bool Curl_proto_is_no_body(struct Curl_easy *data)
{
  return data->req.no_body;
}

curl_off_t Curl_proto_get_maxdownload(struct Curl_easy *data)
{
  return data->req.maxdownload;
}

void Curl_proto_get_creds(struct Curl_easy *data,
                          const char **user, const char **passwd)
{
  struct Curl_creds *creds = data->state.creds;
  *user = creds ? creds->user : NULL;
  *passwd = creds ? creds->passwd : NULL;
}

void Curl_proto_unlink_creds(struct Curl_easy *data)
{
  Curl_creds_unlink(&data->state.creds);
}

char *Curl_proto_get_postfields(struct Curl_easy *data)
{
  return (char *)data->set.postfields;
}

curl_off_t Curl_proto_get_postfieldsize(struct Curl_easy *data)
{
  return data->set.postfieldsize;
}

curl_off_t Curl_proto_get_max_filesize(struct Curl_easy *data)
{
  return data->set.max_filesize;
}

void Curl_proto_set_req_download(struct Curl_easy *data, curl_off_t size)
{
  data->req.bytecount = 0;
  data->req.size = size;
}

timediff_t Curl_proto_get_upkeep_interval_ms(struct Curl_easy *data)
{
  return data->set.upkeep_interval_ms;
}

bool Curl_proto_is_httpreq_post(struct Curl_easy *data)
{
  return data->state.httpreq == HTTPREQ_POST;
}

CURLcode Curl_proto_range(struct Curl_easy *data)
{
  return Curl_range(data);
}

/* Helpers for cfsocket_transfer.zig */

void Curl_trc_bind_c(struct Curl_easy *data)
{
  if(data)
    (void)CURL_TRC_BIND(data);
}

int Curl_cfsock_get_errno(void)
{
  return SOCKERRNO;
}

void Curl_cfsock_set_errno(int err)
{
  SET_SOCKERRNO(err);
}

void Curl_cfsock_set_data_os_errno(struct Curl_easy *data, int err)
{
  if(data)
    data->state.os_errno = err;
}

int Curl_cfsock_get_eafnosupport(void)
{
  return SOCKEAFNOSUPPORT;
}

bool Curl_cfsock_is_einprogress_or_eagain(int sockerr)
{
  return (sockerr == SOCKEINPROGRESS || SOCK_EAGAIN(sockerr));
}

bool Curl_cfsock_is_send_eagain(int sockerr)
{
  if(SOCK_EAGAIN(sockerr))
    return TRUE;
#ifndef USE_WINSOCK
  if((sockerr == SOCKEINTR) || (sockerr == SOCKEINPROGRESS))
    return TRUE;
#endif
  return FALSE;
}

bool Curl_cfsock_is_recv_eagain(int sockerr)
{
  if(SOCK_EAGAIN(sockerr))
    return TRUE;
#ifndef USE_WINSOCK
  if(sockerr == SOCKEINTR)
    return TRUE;
#endif
  return FALSE;
}

int Curl_cfsock_strip_socktype(int x)
{
#ifdef SOCK_CLOEXEC
  x &= ~SOCK_CLOEXEC;
#endif
#ifdef CURL_USE_SOCK_NONBLOCK
  x &= ~SOCK_NONBLOCK;
#endif
  return x;
}

bool Curl_cfsock_is_dgram(int socktype)
{
  return Curl_cfsock_strip_socktype(socktype) == SOCK_DGRAM;
}

#ifdef USE_SO_NOSIGPIPE
int Curl_sock_nosigpipe(curl_socket_t sockfd)
{
  int onoff = 1;
  return setsockopt(sockfd, SOL_SOCKET, SO_NOSIGPIPE,
                    (void *)&onoff, sizeof(onoff));
}
#endif

#if defined(USE_IPV6) && defined(HAVE_SOCKADDR_IN6_SIN6_SCOPE_ID)
static uint32_t cfsock_get_scope_id(struct Curl_easy *data,
                                    struct sockaddr_in6 *sa6)
{
  uint32_t scope_id = 0;
  if(data->conn->scope_id)
    return data->conn->scope_id;
  scope_id = sa6->sin6_scope_id;
  if(!scope_id && IN6_IS_ADDR_LINKLOCAL(&sa6->sin6_addr)) {
#if defined(HAVE_GETIFADDRS) && defined(HAVE_NET_IF_H)
    struct ifaddrs *ifa, *ifa_list;
    if(getifaddrs(&ifa_list) == 0) {
      for(ifa = ifa_list; ifa; ifa = ifa->ifa_next) {
        if(ifa->ifa_addr && ifa->ifa_addr->sa_family == AF_INET6 &&
           (ifa->ifa_flags & IFF_UP) &&
           !(ifa->ifa_flags & IFF_LOOPBACK)) {
          struct sockaddr_in6 *s6 = (void *)ifa->ifa_addr;
          if(IN6_IS_ADDR_LINKLOCAL(&s6->sin6_addr) && s6->sin6_scope_id) {
            scope_id = s6->sin6_scope_id;
            infof(data,
                  "determined scope_id=%lu for link-local address "
                  "from local interface",
                  (unsigned long)scope_id);
            break;
          }
        }
      }
      freeifaddrs(ifa_list);
    }
#endif
  }
  return scope_id;
}
#endif

CURLcode Curl_cfsock_open_fd(struct Curl_easy *data,
                             struct Curl_sockaddr_ex *addr,
                             curl_socket_t *sockfd)
{
  char errbuf[STRERROR_LEN];

#ifdef SOCK_CLOEXEC
  addr->socktype |= SOCK_CLOEXEC;
#endif

  DEBUGASSERT(data);
  DEBUGASSERT(data->conn);
  if(data->set.fopensocket) {
    struct Curl_mapi_guard guard;
    CURL_CBAPI_START(&guard, data, easy_fopensocket);
    *sockfd = data->set.fopensocket(data->set.opensocket_client,
                                    CURLSOCKTYPE_IPCXN,
                                    (struct curl_sockaddr *)addr);
    CURL_CBAPI_END(&guard);
  }
  else {
#ifdef DEBUGBUILD
    if((addr->family == AF_INET6) && getenv("CURL_DBG_SOCK_FAIL_IPV6")) {
      failf(data, "CURL_DBG_SOCK_FAIL_IPV6: failed to open socket");
      return CURLE_COULDNT_CONNECT;
    }
#endif
    *sockfd = CURL_SOCKET(addr->family, addr->socktype, addr->protocol);
    if((*sockfd == CURL_SOCKET_BAD) && (SOCKERRNO == SOCKENOMEM))
      return CURLE_OUT_OF_MEMORY;
  }

  if(*sockfd == CURL_SOCKET_BAD) {
    failf(data, "failed to open socket: %s",
          curlx_strerror(SOCKERRNO, errbuf, sizeof(errbuf)));
    return CURLE_COULDNT_CONNECT;
  }

#ifdef USE_SO_NOSIGPIPE
  if(Curl_sock_nosigpipe(*sockfd) < 0) {
    failf(data, "setsockopt enable SO_NOSIGPIPE: %s",
          curlx_strerror(SOCKERRNO, errbuf, sizeof(errbuf)));
    sclose(*sockfd);
    *sockfd = CURL_SOCKET_BAD;
    return CURLE_COULDNT_CONNECT;
  }
#endif

#if defined(HAVE_FCNTL) && !defined(SOCK_CLOEXEC)
  if(fcntl(*sockfd, F_SETFD, FD_CLOEXEC) < 0) {
    failf(data, "fcntl set CLOEXEC: %s",
          curlx_strerror(SOCKERRNO, errbuf, sizeof(errbuf)));
    sclose(*sockfd);
    *sockfd = CURL_SOCKET_BAD;
    return CURLE_COULDNT_CONNECT;
  }
#endif

#if defined(USE_IPV6) && defined(HAVE_SOCKADDR_IN6_SIN6_SCOPE_ID)
  if(addr->family == AF_INET6) {
    struct sockaddr_in6 * const sa6 = (void *)&addr->curl_sa_addr;
    sa6->sin6_scope_id = cfsock_get_scope_id(data, sa6);
  }
#endif
  return CURLE_OK;
}

int Curl_cfsock_close_fd(struct Curl_easy *data, struct connectdata *conn,
                         int use_callback, curl_socket_t sock)
{
  if(sock == CURL_SOCKET_BAD)
    return 0;

  if(use_callback && conn && conn->fclosesocket) {
    struct Curl_mapi_guard guard;
    int rc;
    Curl_multi_will_close(data, sock);
    CURL_CBAPI_START(&guard, data, easy_closesocket);
    rc = conn->fclosesocket(conn->closesocket_client, sock);
    CURL_CBAPI_END(&guard);
    return rc;
  }

  if(conn)
    Curl_multi_will_close(data, sock);

  sclose(sock);

  return 0;
}

static void cfsock_tcpnodelay(struct Curl_cfilter *cf,
                              struct Curl_easy *data,
                              curl_socket_t sockfd)
{
#if defined(TCP_NODELAY) && defined(CURL_TCP_NODELAY_SUPPORTED)
  curl_socklen_t onoff = (curl_socklen_t)1;
  int level = IPPROTO_TCP;
  VERBOSE(char buffer[STRERROR_LEN]);

  if(setsockopt(sockfd, level, TCP_NODELAY, (void *)&onoff, sizeof(onoff)) < 0)
    CURL_TRC_CF(data, cf, "Could not set TCP_NODELAY: %s",
                curlx_strerror(SOCKERRNO, buffer, sizeof(buffer)));
#else
  (void)cf;
  (void)data;
  (void)sockfd;
#endif
}

#if defined(USE_WINSOCK) || defined(TCP_KEEPIDLE) ||               \
  defined(TCP_KEEPALIVE) || defined(TCP_KEEPALIVE_THRESHOLD) ||    \
  defined(TCP_KEEPINTVL) || defined(TCP_KEEPALIVE_ABORT_THRESHOLD)
#if defined(USE_WINSOCK) || \
  (defined(__sun) && !defined(TCP_KEEPIDLE)) || \
  (defined(__DragonFly__) && __DragonFly_version < 500702) || \
  (defined(_WIN32) && !defined(TCP_KEEPIDLE))
static void cfsock_alive_unit(int *x)
{
  if(*x < (INT_MAX / 1000))
    *x *= 1000;
  else
    *x = INT_MAX;
}
#else
#define cfsock_alive_unit(x)
#endif
#endif

static void cfsock_tcpkeepalive(struct Curl_cfilter *cf,
                                struct Curl_easy *data,
                                curl_socket_t sockfd)
{
  int optval = data->set.tcp_keepalive ? 1 : 0;

  if(setsockopt(sockfd, SOL_SOCKET, SO_KEEPALIVE,
                (void *)&optval, sizeof(optval)) < 0) {
    CURL_TRC_CF(data, cf, "Failed to set SO_KEEPALIVE on fd "
                "%" FMT_SOCKET_T ": errno %d", sockfd, SOCKERRNO);
  }
  else {
#ifdef USE_WINSOCK
    if(curlx_verify_windows_version(10, 0, 16299, PLATFORM_WINNT,
                                    VERSION_GREATER_THAN_EQUAL)) {
      CURL_TRC_CF(data, cf, "Set TCP_KEEP* on fd=%" FMT_SOCKET_T, sockfd);
      optval = curlx_sltosi(data->set.tcp_keepidle);
#ifndef TCP_KEEPALIVE
#define TCP_KEEPALIVE 3
#endif
#ifndef TCP_KEEPCNT
#define TCP_KEEPCNT 16
#endif
#ifndef TCP_KEEPIDLE
#define TCP_KEEPIDLE TCP_KEEPALIVE
#endif
#ifndef TCP_KEEPINTVL
#define TCP_KEEPINTVL 17
#endif
      if(setsockopt(sockfd, IPPROTO_TCP, TCP_KEEPIDLE,
                    (const char *)&optval, sizeof(optval)) < 0) {
        CURL_TRC_CF(data, cf, "Failed to set TCP_KEEPIDLE on fd "
                    "%" FMT_SOCKET_T ": errno %d", sockfd, SOCKERRNO);
      }
      optval = curlx_sltosi(data->set.tcp_keepintvl);
      if(setsockopt(sockfd, IPPROTO_TCP, TCP_KEEPINTVL,
                    (const char *)&optval, sizeof(optval)) < 0) {
        CURL_TRC_CF(data, cf, "Failed to set TCP_KEEPINTVL on fd "
                    "%" FMT_SOCKET_T ": errno %d", sockfd, SOCKERRNO);
      }
      optval = curlx_sltosi(data->set.tcp_keepcnt);
      if(setsockopt(sockfd, IPPROTO_TCP, TCP_KEEPCNT,
                    (const char *)&optval, sizeof(optval)) < 0) {
        CURL_TRC_CF(data, cf, "Failed to set TCP_KEEPCNT on fd "
                    "%" FMT_SOCKET_T ": errno %d", sockfd, SOCKERRNO);
      }
    }
    else {
#ifndef SIO_KEEPALIVE_VALS
#define SIO_KEEPALIVE_VALS  _WSAIOW(IOC_VENDOR, 4)
      struct tcp_keepalive {
        u_long onoff;
        u_long keepalivetime;
        u_long keepaliveinterval;
      };
#endif
      struct tcp_keepalive vals;
      DWORD dummy;
      vals.onoff = 1;
      optval = curlx_sltosi(data->set.tcp_keepidle);
      cfsock_alive_unit(&optval);
      vals.keepalivetime = (u_long)optval;
      optval = curlx_sltosi(data->set.tcp_keepintvl);
      cfsock_alive_unit(&optval);
      vals.keepaliveinterval = (u_long)optval;
      if(WSAIoctl(sockfd, SIO_KEEPALIVE_VALS, (LPVOID)&vals, sizeof(vals),
                  NULL, 0, &dummy, NULL, NULL) != 0) {
        CURL_TRC_CF(data, cf, "Failed to set SIO_KEEPALIVE_VALS on fd "
                    "%" FMT_SOCKET_T ": errno %d", sockfd, SOCKERRNO);
      }
    }
#else /* !USE_WINSOCK */
#ifdef TCP_KEEPIDLE
    optval = curlx_sltosi(data->set.tcp_keepidle);
    cfsock_alive_unit(&optval);
    if(setsockopt(sockfd, IPPROTO_TCP, TCP_KEEPIDLE,
                  (void *)&optval, sizeof(optval)) < 0) {
      CURL_TRC_CF(data, cf, "Failed to set TCP_KEEPIDLE on fd "
                  "%" FMT_SOCKET_T ": errno %d", sockfd, SOCKERRNO);
    }
#elif defined(TCP_KEEPALIVE)
    optval = curlx_sltosi(data->set.tcp_keepidle);
    cfsock_alive_unit(&optval);
    if(setsockopt(sockfd, IPPROTO_TCP, TCP_KEEPALIVE,
                  (void *)&optval, sizeof(optval)) < 0) {
      CURL_TRC_CF(data, cf, "Failed to set TCP_KEEPALIVE on fd "
                  "%" FMT_SOCKET_T ": errno %d", sockfd, SOCKERRNO);
    }
#elif defined(TCP_KEEPALIVE_THRESHOLD)
    optval = curlx_sltosi(data->set.tcp_keepidle);
    cfsock_alive_unit(&optval);
    if(setsockopt(sockfd, IPPROTO_TCP, TCP_KEEPALIVE_THRESHOLD,
                  (void *)&optval, sizeof(optval)) < 0) {
      CURL_TRC_CF(data, cf, "Failed to set TCP_KEEPALIVE_THRESHOLD on fd "
                  "%" FMT_SOCKET_T ": errno %d", sockfd, SOCKERRNO);
    }
#endif
#ifdef TCP_KEEPINTVL
    optval = curlx_sltosi(data->set.tcp_keepintvl);
    cfsock_alive_unit(&optval);
    if(setsockopt(sockfd, IPPROTO_TCP, TCP_KEEPINTVL,
                  (void *)&optval, sizeof(optval)) < 0) {
      CURL_TRC_CF(data, cf, "Failed to set TCP_KEEPINTVL on fd "
                  "%" FMT_SOCKET_T ": errno %d", sockfd, SOCKERRNO);
    }
#elif defined(TCP_KEEPALIVE_ABORT_THRESHOLD)
    {
      int keepcnt = curlx_sltosi(data->set.tcp_keepcnt);
      int keepintvl = curlx_sltosi(data->set.tcp_keepintvl);

      if(keepcnt > 0 && keepintvl > (INT_MAX / keepcnt))
        optval = INT_MAX;
      else
        optval = keepcnt * keepintvl;
    }
    cfsock_alive_unit(&optval);
    if(setsockopt(sockfd, IPPROTO_TCP, TCP_KEEPALIVE_ABORT_THRESHOLD,
                  (void *)&optval, sizeof(optval)) < 0) {
      CURL_TRC_CF(data, cf, "Failed to set TCP_KEEPALIVE_ABORT_THRESHOLD"
                  " on fd %" FMT_SOCKET_T ": errno %d", sockfd, SOCKERRNO);
    }
#endif
#ifdef TCP_KEEPCNT
    optval = curlx_sltosi(data->set.tcp_keepcnt);
    if(setsockopt(sockfd, IPPROTO_TCP, TCP_KEEPCNT,
                  (void *)&optval, sizeof(optval)) < 0) {
      CURL_TRC_CF(data, cf, "Failed to set TCP_KEEPCNT on fd "
                  "%" FMT_SOCKET_T ": errno %d", sockfd, SOCKERRNO);
    }
#endif
#endif /* USE_WINSOCK */
  }
}

#ifdef _WIN32
#ifndef SIO_TCP_INITIAL_RTO
#define SIO_TCP_INITIAL_RTO _WSAIOW(IOC_VENDOR, 17)
#define TCP_INITIAL_RTO_DEFAULT_RTT 0
typedef struct _TCP_INITIAL_RTO_PARAMETERS {
  USHORT Rtt;
  UCHAR MaxSynRetransmissions;
} TCP_INITIAL_RTO_PARAMETERS;
#endif
#ifndef TCP_INITIAL_RTO_NO_SYN_RETRANSMISSIONS
#define TCP_INITIAL_RTO_NO_SYN_RETRANSMISSIONS 0xFE
#endif
static void cfsock_tcplocalhost(curl_socket_t sockfd, int family,
                                const char *remote_ip)
{
  if(((family == AF_INET) && !strcmp(remote_ip, "127.0.0.1")) ||
     ((family == AF_INET6) && !strcmp(remote_ip, "::1"))) {
    TCP_INITIAL_RTO_PARAMETERS rto;
    DWORD bytes = 0;
    memset(&rto, 0, sizeof(rto));
    rto.Rtt = TCP_INITIAL_RTO_DEFAULT_RTT;
    if(curlx_verify_windows_version(10, 0, 16299, PLATFORM_WINNT,
                                    VERSION_GREATER_THAN_EQUAL))
      rto.MaxSynRetransmissions = TCP_INITIAL_RTO_NO_SYN_RETRANSMISSIONS;
    else
      rto.MaxSynRetransmissions = 1;
    (void)WSAIoctl(sockfd, SIO_TCP_INITIAL_RTO, &rto, sizeof(rto),
                   NULL, 0, &bytes, NULL, NULL);
  }
}
#endif

#ifndef CURL_DISABLE_BINDLOCAL
CURLcode Curl_cfsock_bindlocal(struct Curl_easy *data, struct connectdata *conn,
                               curl_socket_t sockfd, int af, unsigned int scope,
                               uint8_t transport)
{
  struct Curl_sockaddr_storage sa;
  struct sockaddr *sock = (struct sockaddr *)&sa;
  curl_socklen_t sizeof_sa = 0;
  struct sockaddr_in *si4 = (struct sockaddr_in *)&sa;
#ifdef USE_IPV6
  struct sockaddr_in6 *si6 = (struct sockaddr_in6 *)&sa;
#endif
  struct Curl_dns_entry *h = NULL;
  unsigned short port = data->set.localport;
  int portnum = data->set.localportrange;
  char *dev_in = NULL, *iface_in = NULL, *host_in = NULL;
  const char *iface = NULL, *host = NULL;
  int sockerr;
#ifdef IP_BIND_ADDRESS_NO_PORT
  int on = 1;
#endif
  CURLcode result = CURLE_OK;

#ifndef USE_IPV6
  (void)scope;
#endif
  if(conn->interface_opts) {
    result = Curl_parse_interface(conn->interface_opts,
                                  &dev_in, &iface_in, &host_in);
    if(result)
      goto out;
    iface = iface_in ? iface_in : dev_in;
    host = host_in ? host_in : dev_in;
  }

  if(!iface && !host && !port)
    goto out;

  if(iface && (strlen(iface) >= 255)) {
    result = CURLE_BAD_FUNCTION_ARGUMENT;
    goto out;
  }
  memset(&sa, 0, sizeof(struct Curl_sockaddr_storage));

  if(iface || host) {
    char myhost[256] = "";
    int done = 0;
    if2ip_result_t if2ip_result = IF2IP_NOT_FOUND;

#ifdef SO_BINDTODEVICE
    if(iface &&
       setsockopt(sockfd, SOL_SOCKET, SO_BINDTODEVICE,
                  iface, (curl_socklen_t)strlen(iface) + 1) == 0 &&
       !host_in) {
      infof(data, "socket successfully bound to interface '%s'", iface);
      result = CURLE_OK;
      goto out;
    }
#endif
    if(!host_in) {
      if2ip_result = Curl_if2ip(af,
#ifdef USE_IPV6
                                scope, conn->scope_id,
#endif
                                iface, myhost, sizeof(myhost));
    }
    switch(if2ip_result) {
    case IF2IP_NOT_FOUND:
      if(iface_in && !host_in) {
        char buffer[STRERROR_LEN];
        data->state.os_errno = sockerr = SOCKERRNO;
        failf(data, "Could not bind to interface '%s' with errno %d: %s",
              iface, sockerr, curlx_strerror(sockerr, buffer, sizeof(buffer)));
        result = CURLE_INTERFACE_FAILED;
        goto out;
      }
      break;
    case IF2IP_AF_NOT_SUPPORTED:
      result = CURLE_UNSUPPORTED_PROTOCOL;
      goto out;
    case IF2IP_FOUND:
      host = myhost;
      infof(data, "Local Interface %s is ip %s using address family %d",
            iface, host, af);
      done = 1;
      break;
    }
    if(!iface_in || host_in) {
      uint8_t dns_queries = (af == AF_INET) ?
                            CURL_DNSQ_A : (CURL_DNSQ_A | CURL_DNSQ_AAAA);
#ifdef USE_IPV6
      if(af == AF_INET6)
        dns_queries = CURL_DNSQ_AAAA;
#endif

      (void)Curl_resolv_blocking(data, dns_queries, host, 80, transport, &h);
      if(h) {
        int h_af = h->addr->ai_family;
        Curl_printable_address(h->addr, myhost, sizeof(myhost));
        infof(data, "Name '%s' family %d resolved to '%s' family %d",
              host, af, myhost, h_af);
        Curl_dns_entry_unlink(data, &h);
        if(af != h_af) {
          result = CURLE_UNSUPPORTED_PROTOCOL;
          goto out;
        }
        done = 1;
      }
      else {
        done = -1;
      }
    }

    if(done > 0) {
#ifdef USE_IPV6
      if(af == AF_INET6) {
#ifdef HAVE_SOCKADDR_IN6_SIN6_SCOPE_ID
        char *scope_ptr = strchr(myhost, '%');
        if(scope_ptr)
          *(scope_ptr++) = '\0';
#endif
        if(curlx_inet_pton(AF_INET6, myhost, &si6->sin6_addr) > 0) {
          si6->sin6_family = AF_INET6;
          si6->sin6_port = htons(port);
#ifdef HAVE_SOCKADDR_IN6_SIN6_SCOPE_ID
          if(scope_ptr) {
            curl_off_t scope_id;
            if(curlx_str_number((const char **)CURL_UNCONST(&scope_ptr),
                                &scope_id, UINT_MAX)) {
              result = CURLE_UNSUPPORTED_PROTOCOL;
              goto out;
            }
            si6->sin6_scope_id = (unsigned int)scope_id;
          }
#endif
        }
        sizeof_sa = sizeof(struct sockaddr_in6);
      }
      else
#endif
      if((af == AF_INET) &&
         (curlx_inet_pton(AF_INET, myhost, &si4->sin_addr) > 0)) {
        si4->sin_family = AF_INET;
        si4->sin_port = htons(port);
        sizeof_sa = sizeof(struct sockaddr_in);
      }
    }

    if(done < 1) {
      char buffer[STRERROR_LEN];
      data->state.errorbuf = FALSE;
      data->state.os_errno = sockerr = SOCKERRNO;
      failf(data, "Could not bind to '%s' with errno %d: %s", host,
            sockerr, curlx_strerror(sockerr, buffer, sizeof(buffer)));
      result = CURLE_INTERFACE_FAILED;
      goto out;
    }
  }
  else {
#ifdef USE_IPV6
    if(af == AF_INET6) {
      si6->sin6_family = AF_INET6;
      si6->sin6_port = htons(port);
      sizeof_sa = sizeof(struct sockaddr_in6);
    }
    else
#endif
    if(af == AF_INET) {
      si4->sin_family = AF_INET;
      si4->sin_port = htons(port);
      sizeof_sa = sizeof(struct sockaddr_in);
    }
  }
#ifdef IP_BIND_ADDRESS_NO_PORT
  (void)setsockopt(sockfd, SOL_IP, IP_BIND_ADDRESS_NO_PORT, &on, sizeof(on));
#endif
  for(;;) {
    if(bind(sockfd, sock, sizeof_sa) >= 0) {
      infof(data, "Local port: %hu", port);
      conn->bits.bound = TRUE;
      result = CURLE_OK;
      goto out;
    }

    if(--portnum > 0) {
      port++;
      if(port == 0)
        break;
      infof(data, "Bind to local port %d failed, trying next", port - 1);
      if(sock->sa_family == AF_INET)
        si4->sin_port = htons(port);
#ifdef USE_IPV6
      else
        si6->sin6_port = htons(port);
#endif
    }
    else
      break;
  }
  {
    char buffer[STRERROR_LEN];
    data->state.os_errno = sockerr = SOCKERRNO;
    failf(data, "bind failed with errno %d: %s",
          sockerr, curlx_strerror(sockerr, buffer, sizeof(buffer)));
  }

  result = CURLE_INTERFACE_FAILED;

out:
  curlx_free(dev_in);
  curlx_free(iface_in);
  curlx_free(host_in);
  return result;
}
#endif

void Curl_cfsock_tuck_nonblock(struct Curl_easy *data,
                               struct Curl_sockaddr_ex *addr,
                               bool set)
{
#ifdef CURL_USE_SOCK_NONBLOCK
  if(!data->set.fopensocket) {
    if(set)
      addr->socktype |= SOCK_NONBLOCK;
    else
      addr->socktype &= ~SOCK_NONBLOCK;
  }
#else
  (void)data;
  (void)addr;
  (void)set;
#endif
}

bool Curl_cfsock_needs_nonblock_call(struct Curl_easy *data)
{
#ifndef CURL_USE_SOCK_NONBLOCK
  (void)data;
  return TRUE;
#else
  return data->set.fopensocket != NULL;
#endif
}

CURLcode Curl_cfsock_post_open_opts(struct Curl_cfilter *cf,
                                    struct Curl_easy *data,
                                    curl_socket_t sock,
                                    const struct Curl_sockaddr_ex *addr,
                                    const struct ip_quadruple *ip,
                                    uint8_t transport,
                                    bool *isconnected_out)
{
  bool is_tcp;
  *isconnected_out = FALSE;

#ifdef USE_IPV6
  if(addr->family == AF_INET6) {
#ifdef USE_WINSOCK
    int on = 0;
    (void)setsockopt(sock, IPPROTO_IPV6, IPV6_V6ONLY,
                     (void *)&on, sizeof(on));
#endif
#ifdef HAVE_SOCKADDR_IN6_SIN6_SCOPE_ID
    {
      const struct sockaddr_in6 *sa6 = (const void *)&addr->curl_sa_addr;
      if(sa6->sin6_scope_id)
        infof(data, "  Trying [%s]:%d scope_id=%lu...",
              ip->remote_ip, ip->remote_port,
              (unsigned long)sa6->sin6_scope_id);
      else
#endif
        infof(data, "  Trying [%s]:%d...",
              ip->remote_ip, ip->remote_port);
#ifdef HAVE_SOCKADDR_IN6_SIN6_SCOPE_ID
    }
#endif
  }
  else
#endif
    infof(data, "  Trying %s:%d...", ip->remote_ip, ip->remote_port);

#ifdef USE_IPV6
  is_tcp = (addr->family == AF_INET ||
            addr->family == AF_INET6) &&
    Curl_cfsock_strip_socktype(addr->socktype) == SOCK_STREAM;
#else
  is_tcp = (addr->family == AF_INET) &&
    Curl_cfsock_strip_socktype(addr->socktype) == SOCK_STREAM;
#endif
  if(is_tcp) {
    if(data->set.tcp_nodelay)
      cfsock_tcpnodelay(cf, data, sock);

    if(data->set.tcp_keepalive)
      cfsock_tcpkeepalive(cf, data, sock);

#ifdef _WIN32
    cfsock_tcplocalhost(sock, addr->family, ip->remote_ip);
#endif
  }

  if(data->set.fsockopt) {
    struct Curl_mapi_guard guard;
    int error;
    CURL_CBAPI_START(&guard, data, easy_fsockopt);
    error = data->set.fsockopt(data->set.sockopt_client,
                               sock,
                               CURLSOCKTYPE_IPCXN);
    CURL_CBAPI_END(&guard);

    if(error == CURL_SOCKOPT_ALREADY_CONNECTED)
      *isconnected_out = TRUE;
    else if(error)
      return CURLE_ABORTED_BY_CALLBACK;
  }

#ifndef CURL_DISABLE_BINDLOCAL
  if(addr->family == AF_INET
#ifdef USE_IPV6
     || addr->family == AF_INET6
#endif
    ) {
    CURLcode result = Curl_cfsock_bindlocal(data, cf->conn, sock, addr->family,
                                            Curl_ipv6_scope(&addr->curl_sa_addr),
                                            transport);
    if(result) {
      if(result == CURLE_UNSUPPORTED_PROTOCOL)
        result = CURLE_COULDNT_CONNECT;
      return result;
    }
  }
#else
  (void)transport;
#endif

  return CURLE_OK;
}

int Curl_cfsock_do_connect(struct Curl_cfilter *cf, struct Curl_easy *data,
                           curl_socket_t sock, struct Curl_sockaddr_ex *addr,
                           bool is_tcp_fastopen)
{
#ifdef TCP_FASTOPEN_CONNECT
  int optval = 1;
#endif
  int rc = -1;

  (void)data;
  if(is_tcp_fastopen) {
#ifdef CONNECT_DATA_IDEMPOTENT
#  ifdef HAVE_BUILTIN_AVAILABLE
    if(__builtin_available(macOS 10.11, iOS 9, tvOS 9, watchOS 2, *)) {
      sa_endpoints_t endpoints;
      endpoints.sae_srcif = 0;
      endpoints.sae_srcaddr = NULL;
      endpoints.sae_srcaddrlen = 0;
      endpoints.sae_dstaddr = &addr->curl_sa_addr;
      endpoints.sae_dstaddrlen = addr->addrlen;

      rc = connectx(sock, &endpoints, SAE_ASSOCID_ANY,
                    CONNECT_RESUME_ON_READ_WRITE | CONNECT_DATA_IDEMPOTENT,
                    NULL, 0, NULL, NULL);
    }
    else {
      rc = connect(sock, &addr->curl_sa_addr, addr->addrlen);
    }
#  else
    rc = connect(sock, &addr->curl_sa_addr, addr->addrlen);
#  endif
#elif defined(TCP_FASTOPEN_CONNECT)
    if(setsockopt(sock, IPPROTO_TCP, TCP_FASTOPEN_CONNECT,
                  (void *)&optval, sizeof(optval)) < 0)
      CURL_TRC_CF(data, cf, "Failed to enable TCP Fast Open on fd %"
                  FMT_SOCKET_T, sock);

    rc = connect(sock, &addr->curl_sa_addr, addr->addrlen);
#elif defined(MSG_FASTOPEN)
    if(Curl_conn_is_ssl(cf->conn, cf->sockindex))
      rc = connect(sock, &addr->curl_sa_addr, addr->addrlen);
    else
      rc = 0;
#endif
  }
  else {
    rc = connect(sock, &addr->curl_sa_addr,
                 (curl_socklen_t)addr->addrlen);
  }
  return rc;
}

bool Curl_cfsock_verifyconnect(curl_socket_t sockfd, int *psockerr)
{
  bool rc = TRUE;
#ifdef SO_ERROR
  int sockerr = 0;
  curl_socklen_t errSize = sizeof(sockerr);

#ifdef _WIN32
  SleepEx(0, FALSE);
#endif

  if(getsockopt(sockfd, SOL_SOCKET, SO_ERROR, (void *)&sockerr, &errSize))
    sockerr = SOCKERRNO;
#if defined(EBADIOCTL) && defined(__minix)
  if(EBADIOCTL == sockerr) {
    SET_SOCKERRNO(0);
    sockerr = 0;
  }
#endif
  if((sockerr == 0) || (SOCKEISCONN == sockerr))
    rc = TRUE;
  else
    rc = FALSE;
  if(psockerr)
    *psockerr = sockerr;
#else
  (void)sockfd;
  if(psockerr)
    *psockerr = SOCKERRNO;
#endif
  return rc;
}

int Curl_cfsock_getsockname(struct Curl_easy *data, curl_socket_t sock,
                            struct Curl_sockaddr_storage *ssloc,
                            curl_socklen_t *slen, int *sockerr_out)
{
#ifdef HAVE_GETSOCKNAME
  if((sock != CURL_SOCKET_BAD) &&
     !(data->conn->scheme->protocol & CURLPROTO_TFTP)) {
    *slen = sizeof(struct Curl_sockaddr_storage);
    memset(ssloc, 0, sizeof(struct Curl_sockaddr_storage));
    if(getsockname(sock, (struct sockaddr *)ssloc, slen)) {
      *sockerr_out = SOCKERRNO;
      return -1;
    }
    return 1;
  }
#else
  (void)data;
  (void)sock;
  (void)ssloc;
  (void)slen;
  (void)sockerr_out;
#endif
  return 0;
}

int Curl_cfsock_getpeername(curl_socket_t sock,
                            struct Curl_sockaddr_storage *ssrem,
                            curl_socklen_t *plen, int *sockerr_out)
{
#ifdef HAVE_GETPEERNAME
  *plen = sizeof(struct Curl_sockaddr_storage);
  memset(ssrem, 0, sizeof(struct Curl_sockaddr_storage));
  if(getpeername(sock, (struct sockaddr *)ssrem, plen)) {
    *sockerr_out = SOCKERRNO;
    return -1;
  }
  return 1;
#else
  (void)sock;
  (void)ssrem;
  (void)plen;
  (void)sockerr_out;
  return 0;
#endif
}

ssize_t Curl_cfsock_swrite(struct connectdata *conn, curl_socket_t sock,
                           const void *buf, size_t len,
                           const struct Curl_sockaddr_ex *addr,
                           int *sockerr_out)
{
  ssize_t rv;
#if defined(MSG_FASTOPEN) && !defined(TCP_FASTOPEN_CONNECT)
  if(conn->bits.tcp_fastopen) {
    rv = sendto(sock, buf, len, MSG_FASTOPEN,
                &addr->curl_sa_addr, addr->addrlen);
    conn->bits.tcp_fastopen = FALSE;
  }
  else
#else
  (void)conn;
  (void)addr;
#endif
    rv = swrite(sock, buf, len);
  if(rv < 0)
    *sockerr_out = SOCKERRNO;
  return rv;
}

ssize_t Curl_cfsock_sread(curl_socket_t sock, void *buf, size_t len,
                          int *sockerr_out)
{
  ssize_t rv = sread(sock, buf, len);
  if(rv < 0)
    *sockerr_out = SOCKERRNO;
  return rv;
}

void Curl_cfsock_win_update_sndbuf(struct Curl_easy *data,
                                   curl_socket_t sock,
                                   struct curltime *last_query_at,
                                   unsigned int *sndbuf_size)
{
#ifdef USE_WINSOCK
#ifndef SIO_IDEAL_SEND_BACKLOG_QUERY
#define SIO_IDEAL_SEND_BACKLOG_QUERY 0x4004747B
#endif
  ULONG ideal;
  DWORD ideallen;

  if(curlx_ptimediff_ms(Curl_pgrs_now(data), last_query_at) > 1000) {
    if(!WSAIoctl(sock, SIO_IDEAL_SEND_BACKLOG_QUERY, 0, 0,
                 &ideal, sizeof(ideal), &ideallen, 0, 0) &&
       ideal != (ULONG)*sndbuf_size &&
       !setsockopt(sock, SOL_SOCKET, SO_SNDBUF,
                   (const char *)&ideal, sizeof(ideal))) {
      *sndbuf_size = (unsigned int)ideal;
    }
    *last_query_at = *Curl_pgrs_now(data);
  }
#else
  (void)data;
  (void)sock;
  (void)last_query_at;
  (void)sndbuf_size;
#endif
}

void Curl_cfsock_quic_opts(curl_socket_t sock, int addr_family)
{
#if (defined(__linux__) || defined(__APPLE__)) && defined(IP_RECVTOS)
  {
    unsigned int tos = 1;
    switch(addr_family) {
    case AF_INET:
      (void)setsockopt(sock, IPPROTO_IP, IP_RECVTOS, &tos, sizeof(tos));
      break;
#ifdef IPV6_RECVTCLASS
    case AF_INET6:
      (void)setsockopt(sock, IPPROTO_IPV6, IPV6_RECVTCLASS,
                       &tos, sizeof(tos));
      break;
#endif
    }
  }
#endif
#ifdef __linux__
  {
    int val;
    switch(addr_family) {
#ifdef IP_MTU_DISCOVER
    case AF_INET:
      val = IP_PMTUDISC_DO;
      (void)setsockopt(sock, IPPROTO_IP, IP_MTU_DISCOVER, &val,
                       sizeof(val));
      break;
#endif
#ifdef IPV6_MTU_DISCOVER
    case AF_INET6:
      val = IPV6_PMTUDISC_DO;
      (void)setsockopt(sock, IPPROTO_IPV6, IPV6_MTU_DISCOVER, &val,
                       sizeof(val));
      break;
#endif
    }
  }
#endif
#if (defined(__linux__) || defined(__APPLE__)) && defined(IP_DONTFRAG)
  {
    int val = 1;
    switch(addr_family) {
    case AF_INET:
      (void)setsockopt(sock, IPPROTO_IP, IP_DONTFRAG, &val, sizeof(val));
      break;
#ifdef IPV6_DONTFRAG
    case AF_INET6:
      (void)setsockopt(sock, IPPROTO_IPV6, IPV6_DONTFRAG,
                       &val, sizeof(val));
      break;
#endif
    }
  }
#endif
#if defined(UDP_GRO) &&                                                 \
  (defined(HAVE_SENDMMSG) || defined(HAVE_SENDMSG)) &&                  \
  ((defined(USE_NGTCP2) && defined(USE_NGHTTP3)) || defined(USE_QUICHE))
  {
    int one = 1;
    (void)setsockopt(sock, IPPROTO_UDP, UDP_GRO, &one,
                     (socklen_t)sizeof(one));
  }
#endif
  (void)sock;
  (void)addr_family;
}

timediff_t Curl_cfsock_get_accepttimeout(struct Curl_easy *data)
{
  timediff_t timeout_ms = DEFAULT_ACCEPT_TIMEOUT;
#ifndef CURL_DISABLE_FTP
  if(data->set.accepttimeout > 0)
    timeout_ms = data->set.accepttimeout;
#else
  (void)data;
#endif
  return timeout_ms;
}

CURLcode Curl_cfsock_accept_fd(struct Curl_easy *data,
                               struct connectdata *conn,
                               curl_socket_t listen_sock,
                               curl_socket_t *s_accepted_out)
{
  char errbuf[STRERROR_LEN];
#ifdef USE_IPV6
  struct Curl_sockaddr_storage add;
#else
  struct sockaddr_in add;
#endif
  curl_socklen_t size = (curl_socklen_t)sizeof(add);
  curl_socket_t s_accepted;

#ifdef HAVE_ACCEPT4
  s_accepted = CURL_ACCEPT4(listen_sock, (struct sockaddr *)&add, &size,
                            SOCK_NONBLOCK | SOCK_CLOEXEC);
#else
  s_accepted = CURL_ACCEPT(listen_sock, (struct sockaddr *)&add, &size);
#endif

  if(s_accepted == CURL_SOCKET_BAD) {
    failf(data, "Error accept()ing server connect: %s",
          curlx_strerror(SOCKERRNO, errbuf, sizeof(errbuf)));
    return CURLE_FTP_ACCEPT_FAILED;
  }
#ifndef HAVE_ACCEPT4
#ifdef HAVE_FCNTL
  if(fcntl(s_accepted, F_SETFD, FD_CLOEXEC) < 0) {
    failf(data, "fcntl set CLOEXEC: %s",
          curlx_strerror(SOCKERRNO, errbuf, sizeof(errbuf)));
    Curl_socket_close(data, conn, s_accepted);
    return CURLE_FTP_ACCEPT_FAILED;
  }
#endif
  if(curlx_nonblock(s_accepted, TRUE) < 0) {
    failf(data, "set socket NONBLOCK: %s",
          curlx_strerror(SOCKERRNO, errbuf, sizeof(errbuf)));
    Curl_socket_close(data, conn, s_accepted);
    return CURLE_FTP_ACCEPT_FAILED;
  }
#else
  (void)conn;
#endif
  *s_accepted_out = s_accepted;
  return CURLE_OK;
}

CURLcode Curl_cfsock_call_fsockopt_accept(struct Curl_easy *data,
                                          curl_socket_t sock)
{
  if(data->set.fsockopt) {
    struct Curl_mapi_guard guard;
    int error = 0;

    CURL_CBAPI_START(&guard, data, easy_fsockopt);
    error = data->set.fsockopt(data->set.sockopt_client,
                               sock, CURLSOCKTYPE_ACCEPT);
    CURL_CBAPI_END(&guard);

    if(error)
      return CURLE_ABORTED_BY_CALLBACK;
  }
  return CURLE_OK;
}

curl_socket_t Curl_cfsock_get_conn_sock(struct connectdata *conn,
                                        int8_t sockindex)
{
  return conn->sock[sockindex];
}

void Curl_cfsock_set_conn_sock(struct connectdata *conn,
                               int8_t sockindex,
                               curl_socket_t sock)
{
  conn->sock[sockindex] = sock;
}

struct Curl_cfilter *Curl_cfsock_get_conn_cfilter(struct Curl_easy *data,
                                                  int8_t sockindex)
{
  return data->conn->cfilter[sockindex];
}

bool Curl_cfsock_is_tcp_fastopen(struct connectdata *conn)
{
  return (bool)conn->bits.tcp_fastopen;
}

void Curl_cfsock_set_conn_ipv6(struct connectdata *conn, int8_t sockindex,
                               int addr_family)
{
#ifdef USE_IPV6
  if(sockindex == FIRSTSOCKET)
    conn->bits.ipv6 = (addr_family == AF_INET6);
#else
  (void)conn;
  (void)sockindex;
  (void)addr_family;
#endif
}

void Curl_cfsock_set_data_primary_ip(struct Curl_easy *data,
                                     const struct ip_quadruple *ip)
{
  data->info.primary = *ip;
}

/* Transfer helpers for cfsocket_transfer.zig */

struct curl_slist *Curl_xfer_get_set_headers(const struct Curl_easy *data)
{
  return data->set.headers;
}

struct connectdata *Curl_xfer_get_conn(struct Curl_easy *data)
{
  return data ? data->conn : NULL;
}

int8_t Curl_xfer_get_send_idx(struct Curl_easy *data)
{
  return data->conn->send_idx;
}

int8_t Curl_xfer_get_recv_idx(struct Curl_easy *data)
{
  return data->conn->recv_idx;
}

bool Curl_xfer_in_recv_shutdown(struct Curl_easy *data)
{
  if(!data || !data->conn)
    return FALSE;
  return CURL_CONN_IN_SHUTDOWN(data->conn, data->conn->recv_idx);
}

uint32_t Curl_xfer_get_scheme_protocol(struct Curl_easy *data)
{
  return data->conn->scheme->protocol;
}

void Curl_xfer_get_timecond_info(struct Curl_easy *data,
                                 curl_off_t *timevalue,
                                 uint8_t *timecondition)
{
  *timevalue = data->set.timevalue;
  *timecondition = data->set.timecondition;
}

void Curl_xfer_set_timecond_met(struct Curl_easy *data)
{
  data->info.timecond = TRUE;
}

void Curl_xfer_get_recv_resp_state(struct Curl_easy *data,
                                   curl_off_t *size,
                                   curl_off_t *bytecount,
                                   bool *header,
                                   bool *shutdown)
{
  *size = data->req.size;
  *bytecount = data->req.bytecount;
  *header = (bool)data->req.header;
  *shutdown = (bool)data->req.shutdown;
}

struct Curl_rlimit *Curl_xfer_get_dl_rlimit(struct Curl_easy *data)
{
  return &data->progress.dl.rlimit;
}

struct Curl_rlimit *Curl_xfer_get_ul_rlimit(struct Curl_easy *data)
{
  return &data->progress.ul.rlimit;
}

bool Curl_xfer_can_skip_eagain_eos(struct Curl_easy *data)
{
  return data->req.download_done && data->req.no_body &&
         !data->req.resp_trailer;
}

bool Curl_xfer_is_eos_written(struct Curl_easy *data)
{
  return (bool)data->req.eos_written;
}

bool Curl_xfer_is_req_done(struct Curl_easy *data)
{
  return (bool)data->req.done;
}

void Curl_xfer_set_req_done(struct Curl_easy *data, bool done)
{
  data->req.done = done;
}

bool Curl_xfer_is_download_done(struct Curl_easy *data)
{
  return (bool)data->req.download_done;
}

void Curl_xfer_clear_req_recv(struct Curl_easy *data)
{
  CURL_REQ_CLEAR_RECV(data);
}

bool Curl_xfer_req_want_recv(struct Curl_easy *data)
{
  return (bool)CURL_REQ_WANT_RECV(data);
}

bool Curl_xfer_req_want_send(struct Curl_easy *data)
{
  return (bool)CURL_REQ_WANT_SEND(data);
}

bool Curl_xfer_req_want_io(struct Curl_easy *data)
{
  return (bool)CURL_REQ_WANT_IO(data);
}

bool Curl_xfer_is_conn_close(struct Curl_easy *data)
{
  return (bool)data->conn->bits.close;
}

void Curl_xfer_get_final_check_info(struct Curl_easy *data,
                                    bool *no_body,
                                    curl_off_t *size,
                                    curl_off_t *bytecount,
                                    bool *has_newurl)
{
  *no_body = (bool)data->req.no_body;
  *size = data->req.size;
  *bytecount = data->req.bytecount;
  *has_newurl = data->req.newurl != NULL;
}

void Curl_xfer_init_connect_c(struct Curl_easy *data)
{
  data->state.fread_func = data->set.fread_func_set;
  data->state.in = data->set.in_set;
  data->state.upload = (data->state.httpreq == HTTPREQ_PUT);
}

CURLcode Curl_xfer_pretransfer_c(struct Curl_easy *data)
{
  CURLcode result = CURLE_OK;

  data->state.retrycount = 0;

  if(!CURL_EASY_STR(data, STRING_SET_URL) && !data->set.uh) {
    failf(data, "No URL set");
    return CURLE_URL_MALFORMAT;
  }

  if(data->set.uh) {
    char *url = NULL;
    CURLUcode uc;
    uc = curl_url_get(data->set.uh, CURLUPART_URL, &url, 0);
    if(uc) {
      Curl_bufref_set(&data->state.url, NULL, 0, NULL);
      failf(data, "No URL set");
      return CURLE_URL_MALFORMAT;
    }
    result = CURL_EASY_STR_SETN(data, STRING_SET_URL, url);
    if(result)
      return result;
  }

  Curl_bufref_set(&data->state.url, CURL_EASY_STR(data, STRING_SET_URL),
                  0, NULL);

  if(data->set.postfields && data->set.set_resume_from) {
    failf(data, "cannot mix POSTFIELDS with RESUME_FROM");
    return CURLE_BAD_FUNCTION_ARGUMENT;
  }

  data->state.prefer_ascii = data->set.prefer_ascii;
#ifdef CURL_LIST_ONLY_PROTOCOL
  data->state.list_only = data->set.list_only;
#endif
  data->state.httpreq = data->set.method;

  Curl_peer_unlink(&data->state.initial_origin);
  Curl_peer_unlink(&data->state.origin);
  data->state.requests = 0;
  data->state.followlocation = 0;
  data->state.this_is_a_follow = FALSE;
  data->state.http_ignorecustom = FALSE;
  data->state.errorbuf = FALSE;
#ifndef CURL_DISABLE_HTTP
  Curl_http_neg_init(data, &data->state.http_neg);
#endif
  data->state.authproblem = FALSE;
  data->state.authhost.want = data->set.httpauth;
  data->state.authproxy.want = data->set.proxyauth;
  curlx_safefree(data->info.wouldredirect);
  curlx_safefree(data->info.effective_url);
  Curl_data_priority_clear_state(data);
  if(data->set.http_auto_referer)
    Curl_bufref_free(&data->state.referer);
  if(CURL_EASY_STR(data, STRING_SET_REFERER))
    Curl_bufref_set(&data->state.referer,
                    CURL_EASY_STR(data, STRING_SET_REFERER), 0, NULL);
  else
    Curl_bufref_free(&data->state.referer);

  if(data->state.httpreq == HTTPREQ_PUT)
    data->state.infilesize = data->set.filesize;
  else if((data->state.httpreq != HTTPREQ_GET) &&
          (data->state.httpreq != HTTPREQ_HEAD)) {
    data->state.infilesize = data->set.postfieldsize;
    if(data->set.postfields && (data->state.infilesize == -1))
      data->state.infilesize = (curl_off_t)strlen(data->set.postfields);
  }
  else
    data->state.infilesize = 0;

  result = Curl_cookie_loadfiles(data,
                                 data->set.cookiesession ?
                                 COOKIE_NOSESSION : 0);
  if(!result)
    Curl_cookie_run(data);

  if(!result && data->state.resolve)
    result = Curl_loadhostpairs(data);

  if(!result)
    result = Curl_hsts_loadfiles(data);

  if(!result) {
    data->state.allow_port = TRUE;

#if defined(HAVE_SIGNAL) && defined(SIGPIPE) && !defined(MSG_NOSIGNAL)
    if(!data->set.no_signal)
      data->state.prev_signal = signal(SIGPIPE, SIG_IGN);
#endif

    Curl_initinfo(data);
    Curl_pgrsResetTransferSizes(data);
    Curl_pgrsStart(data, NULL);

    data->state.authhost.picked &= data->state.authhost.want;
    data->state.authproxy.picked &= data->state.authproxy.want;

#ifndef CURL_DISABLE_FTP
    data->state.wildcardmatch = data->set.wildcard_enabled;
#ifdef DEBUGBUILD
    if(getenv("CURL_DBG_FTP_WILDCARD"))
      data->state.wildcardmatch = TRUE;
#endif
    if(data->state.wildcardmatch) {
      struct WildcardData *wc;
      if(!data->wildcard) {
        data->wildcard = curlx_calloc(1, sizeof(struct WildcardData));
        if(!data->wildcard)
          return CURLE_OUT_OF_MEMORY;
      }
      wc = data->wildcard;
      if(wc->state < CURLWC_INIT) {
        if(wc->ftpwc)
          wc->dtor(wc->ftpwc);
        curlx_safefree(wc->pattern);
        curlx_safefree(wc->path);
        Curl_wildcard_init(wc);
      }
    }
#endif
    result = Curl_hsts_loadcb(data, data->hsts);
  }

  data->req.headerbytecount = 0;
  Curl_headers_cleanup(data);
  return result;
}

int Curl_xfer_check_retry(struct Curl_easy *data, uint8_t *retrycount_out)
{
  struct connectdata *conn = data->conn;

  if(data->state.upload &&
     !(conn->scheme->protocol & (PROTO_FAMILY_HTTP | CURLPROTO_RTSP)))
    return 0;

  if(conn->bits.reuse &&
     (data->req.bytecount + data->req.headerbytecount == 0) &&
     ((!data->req.no_body && !data->req.done) ||
      (conn->scheme->protocol & PROTO_FAMILY_HTTP))
#ifndef CURL_DISABLE_RTSP
     && (data->set.rtspreq != RTSPREQ_RECEIVE)
#endif
    ) {
    *retrycount_out = data->state.retrycount;
    return 1;
  }
  else if(data->state.refused_stream &&
          (data->req.bytecount + data->req.headerbytecount == 0)) {
    data->state.refused_stream = FALSE;
    *retrycount_out = data->state.retrycount;
    return 2;
  }
  return 0;
}

void Curl_xfer_set_retrycount(struct Curl_easy *data, uint8_t val)
{
  data->state.retrycount = val;
}

CURLcode Curl_xfer_apply_retry(struct Curl_easy *data, char **url)
{
  struct connectdata *conn = data->conn;
  *url = Curl_bufref_dup(&data->state.url);
  if(!*url)
    return CURLE_OUT_OF_MEMORY;

  connclose(conn);
  conn->bits.retry = TRUE;
  return CURLE_OK;
}

void Curl_xfer_setup_fields(struct Curl_easy *data,
                            int8_t send_idx,
                            int8_t recv_idx,
                            curl_off_t recv_size,
                            bool *is_header_out)
{
  struct SingleRequest *k = &data->req;
  struct connectdata *conn = data->conn;

  DEBUGASSERT(conn);
  DEBUGASSERT((send_idx <= 1) && (send_idx >= -1));
  DEBUGASSERT((recv_idx <= 1) && (recv_idx >= -1));
  DEBUGASSERT((send_idx >= 0) || !Curl_req_want_send(data));

  conn->send_idx = send_idx;
  conn->recv_idx = recv_idx;

  DEBUGASSERT((conn->recv_idx >= 0) || (recv_size == -1));
  k->size = recv_size;
  k->header = !!conn->scheme->run->write_resp_hd;
  k->shutdown = FALSE;
  k->shutdown_err_ignore = FALSE;
  *is_header_out = (bool)k->header;

  if(conn->scheme->run->write_resp_hd || !data->req.no_body) {
    if(conn->recv_idx != -1)
      CURL_REQ_SET_RECV(data);
    if(conn->send_idx != -1)
      CURL_REQ_SET_SEND(data);
  }
}

void Curl_xfer_set_shutdown_fields(struct Curl_easy *data,
                                   bool shutdown,
                                   bool ignore_errors)
{
  DEBUGASSERT(!shutdown ||
              (data->conn->send_idx < 0) || (data->conn->recv_idx < 0));
  data->req.shutdown = shutdown;
  data->req.shutdown_err_ignore = ignore_errors;
}

CURLcode Curl_xfer_scheme_write_resp(struct Curl_easy *data,
                                     const char *buf, size_t blen,
                                     bool is_eos, bool *handled_out)
{
  if(data->conn->scheme->run->write_resp) {
    *handled_out = TRUE;
    return data->conn->scheme->run->write_resp(data, buf, blen, is_eos);
  }
  *handled_out = FALSE;
  return CURLE_OK;
}

void Curl_xfer_mark_eos_written(struct Curl_easy *data)
{
  data->req.eos_written = TRUE;
  data->req.download_done = TRUE;
}

bool Curl_xfer_is_cwriter_paused(struct Curl_easy *data)
{
  return Curl_cwriter_is_paused(data);
}

CURLcode Curl_xfer_scheme_write_resp_hd(struct Curl_easy *data,
                                        const char *hd0, size_t hdlen,
                                        bool is_eos, bool *handled_out)
{
  if(data->conn->scheme->run->write_resp_hd) {
    DEBUGASSERT(!hd0[hdlen]);
    *handled_out = TRUE;
    return data->conn->scheme->run->write_resp_hd(data, hd0, hdlen, is_eos);
  }
  *handled_out = FALSE;
  return CURLE_OK;
}

void Curl_xfer_add_request_size(struct Curl_easy *data, size_t nwritten)
{
  data->info.request_size += nwritten;
}

size_t Curl_xfer_get_buffer_size(struct Curl_easy *data)
{
  DEBUGASSERT(data);
  DEBUGASSERT(data->conn);
  DEBUGASSERT(data->set.buffer_size > 0);
  return curlx_uitouz(data->set.buffer_size);
}

bool Curl_xfer_check_is_secure(struct Curl_easy *data)
{
#ifndef CURL_DISABLE_PROXY
  if(data->conn && data->conn->bits.origin_is_proxy) {
    DEBUGASSERT(!(data->state.origin->scheme->flags & PROTOPT_SSL));
    return FALSE;
  }
#endif
  return (data->state.origin->scheme->flags & PROTOPT_SSL) != 0;
}

#include "cf-setup.h"
#include "thrdqueue.h"

void Curl_zig_connect_timeleft_info(struct Curl_easy *data,
                                    bool *in_shutdown,
                                    timediff_t *connecttimeout_ms,
                                    timediff_t *timeout_ms,
                                    uint8_t *connect_only)
{
  *in_shutdown = (data->conn &&
                  CURL_CONN_IN_SHUTDOWN(data->conn, FIRSTSOCKET)) ?
                 TRUE : FALSE;
  *connecttimeout_ms = data->set.connecttimeout;
  *timeout_ms = data->set.timeout;
  *connect_only = data->set.connect_only;
}

struct connectdata *Curl_zig_data_get_conn(struct Curl_easy *data)
{
  return data ? data->conn : NULL;
}

curl_socket_t Curl_zig_conn_get_sock(const struct connectdata *conn,
                                     int8_t sockindex)
{
  return conn->sock[sockindex];
}

void Curl_zig_conn_set_close(struct connectdata *conn, bool close_it)
{
  conn->bits.close = close_it ? TRUE : FALSE;
}

struct Curl_cfilter *Curl_zig_conn_get_cfilter(const struct connectdata *conn,
                                               int8_t sockindex)
{
  return conn ? conn->cfilter[sockindex] : NULL;
}

bool Curl_zig_conn_is_https(const struct connectdata *conn)
{
  return (conn && conn->scheme &&
          (conn->scheme->protocol == CURLPROTO_HTTPS)) ? TRUE : FALSE;
}

uint8_t Curl_zig_conn_get_ip_version(const struct connectdata *conn)
{
  return conn->ip_version;
}

CURLcode Curl_zig_cf_setup_add(struct Curl_easy *data,
                               struct connectdata *conn,
                               int8_t sockindex,
                               int ssl_mode)
{
  return Curl_cf_setup_add(data, conn, sockindex,
                           conn->transport_wanted, ssl_mode);
}

CURLcode Curl_zig_cf_setup_insert_after(struct Curl_cfilter *cf,
                                        struct Curl_easy *data,
                                        uint8_t transport,
                                        int ssl_mode)
{
  return Curl_cf_setup_insert_after(cf, data, transport, ssl_mode);
}

const char *Curl_zig_conn_host_dispname(const struct connectdata *conn)
{
  return CURL_CONN_HOST_DISPNAME(conn);
}

unsigned int Curl_zig_conn_scheme_flags(const struct connectdata *conn)
{
  return conn->scheme->flags;
}

unsigned int Curl_zig_data_origin_scheme_flags(const struct Curl_easy *data)
{
  return (data && data->state.origin && data->state.origin->scheme) ?
         data->state.origin->scheme->flags : 0;
}

void Curl_zig_conn_set_multiplex(struct connectdata *conn,
                                 struct Curl_multi **out_multi)
{
  if(!conn->bits.multiplex) {
    conn->bits.multiplex = TRUE;
    *out_multi = conn->attached_multi;
  }
  else
    *out_multi = NULL;
}

struct Curl_peer *Curl_zig_conn_get_origin(
  struct connectdata *conn, int8_t sockindex)
{
  return (sockindex == SECONDARYSOCKET) ? conn->origin2 : conn->origin;
}

struct Curl_peer *Curl_zig_conn_get_destination(
  struct connectdata *conn, int8_t sockindex)
{
  return (sockindex == SECONDARYSOCKET) ?
    (conn->via_peer2 ? conn->via_peer2 : conn->origin2) :
    (conn->via_peer ? conn->via_peer : conn->origin);
}

struct Curl_peer *Curl_zig_conn_get_first_peer(
  struct connectdata *conn, int8_t sockindex)
{
#ifndef CURL_DISABLE_PROXY
  if(conn->socks_proxy.peer)
    return conn->socks_proxy.peer;
  if(conn->http_proxy.peer)
    return conn->http_proxy.peer;
#endif
  return (sockindex == SECONDARYSOCKET) ?
    (conn->via_peer2 ? conn->via_peer2 : conn->origin2) :
    (conn->via_peer ? conn->via_peer : conn->origin);
}

void Curl_zig_data_get_http_neg(const struct Curl_easy *data,
                                uint8_t *wanted,
                                uint8_t *allowed,
                                uint8_t *preferred)
{
  *wanted = data->state.http_neg.wanted;
  *allowed = data->state.http_neg.allowed;
  *preferred = data->state.http_neg.preferred;
}

void Curl_zig_data_set_http_neg_wanted(struct Curl_easy *data,
                                       uint8_t wanted)
{
  data->state.http_neg.wanted = wanted;
}

timediff_t Curl_zig_data_happy_eyeballs_timeout(const struct Curl_easy *data)
{
  return data->set.happy_eyeballs_timeout;
}

bool Curl_zig_conn_should_https_setup(const struct connectdata *conn)
{
  return (conn->scheme->protocol == CURLPROTO_HTTPS) &&
#ifndef CURL_DISABLE_PROXY
         !conn->bits.origin_is_proxy &&
#endif
         conn->bits.tls_enable_alpn;
}

uint8_t Curl_zig_conn_get_transport_wanted(const struct connectdata *conn)
{
  return conn->transport_wanted;
}

void Curl_zig_conn_get_peers(const struct connectdata *conn,
                             struct Curl_peer **origin,
                             struct Curl_peer **socks_proxy_peer,
                             struct Curl_peer **http_proxy_peer)
{
  *origin = conn->origin;
#ifndef CURL_DISABLE_PROXY
  *socks_proxy_peer = conn->socks_proxy.peer;
  *http_proxy_peer = conn->http_proxy.peer;
#else
  *socks_proxy_peer = NULL;
  *http_proxy_peer = NULL;
#endif
}

bool Curl_zig_data_is_os_errno_timedout(const struct Curl_easy *data)
{
#ifdef SOCKETIMEDOUT
  return (SOCKETIMEDOUT == data->state.os_errno) ? TRUE : FALSE;
#else
  (void)data;
  return FALSE;
#endif
}

bool Curl_zig_conn_is_ssh(const struct connectdata *conn)
{
  return (conn->scheme->protocol & PROTO_FAMILY_SSH) != 0;
}

void Curl_zig_data_inc_numconnects(struct Curl_easy *data)
{
  data->info.numconnects++;
}

uint32_t Curl_zig_data_get_mid(const struct Curl_easy *data)
{
  return data->mid;
}

curl_off_t Curl_zig_data_get_id(const struct Curl_easy *data)
{
  return data->id;
}

struct Curl_multi *Curl_zig_data_get_multi(const struct Curl_easy *data)
{
  return data ? data->multi : NULL;
}

struct curl_thrdq **Curl_zig_multi_get_resolv_thrdq_ptr(
  struct Curl_multi *multi)
{
#ifdef USE_RESOLV_THREADED
  return &multi->resolv_thrdq;
#else
  (void)multi;
  return NULL;
#endif
}

struct curl_thrdq *Curl_zig_multi_get_resolv_thrdq(
  const struct Curl_multi *multi)
{
#ifdef USE_RESOLV_THREADED
  return multi ? multi->resolv_thrdq : NULL;
#else
  (void)multi;
  return NULL;
#endif
}

void Curl_zig_multi_set_resolv_thrdq(struct Curl_multi *multi,
                                     struct curl_thrdq *thrdq)
{
#ifdef USE_RESOLV_THREADED
  multi->resolv_thrdq = thrdq;
#else
  (void)multi;
  (void)thrdq;
#endif
}

#ifdef USE_ARES
int Curl_zig_ares_init_channel(struct Curl_easy *data,
                               int ares_ver,
                               void **channel_out)
{
  struct ares_options options;
  int optmask = ARES_OPT_SOCK_STATE_CB;

  memset(&options, 0, sizeof(options));
  options.sock_state_cb = NULL;
  options.sock_state_cb_data = data;
#if ARES_VERSION >= 0x011f00
  options.qcache_max_ttl = 0;
  optmask |= ARES_OPT_QUERY_CACHE;
#endif
  if(ares_ver < 0x011400) {
    options.timeout = CURL_TIMEOUT_RESOLVE_MS;
    optmask |= ARES_OPT_TIMEOUTMS;
  }
  return ares_init_options((ares_channel *)channel_out, &options, optmask);
}

const char *Curl_zig_easy_get_dns_servers(const struct Curl_easy *data)
{
  return data ? CURL_EASY_STR(data, STRING_DNS_SERVERS) : NULL;
}

const char *Curl_zig_easy_get_dns_interface(const struct Curl_easy *data)
{
  return data ? CURL_EASY_STR(data, STRING_DNS_INTERFACE) : NULL;
}

const char *Curl_zig_easy_get_dns_local_ip4(const struct Curl_easy *data)
{
  return data ? CURL_EASY_STR(data, STRING_DNS_LOCAL_IP4) : NULL;
}

const char *Curl_zig_easy_get_dns_local_ip6(const struct Curl_easy *data)
{
  return data ? CURL_EASY_STR(data, STRING_DNS_LOCAL_IP6) : NULL;
}
#endif

struct Curl_easy *Curl_zig_multi_get_admin(const struct Curl_multi *multi)
{
  return multi ? multi->admin : NULL;
}

unsigned int Curl_zig_data_get_conn_scope_id(const struct Curl_easy *data)
{
  return (data && data->conn) ? data->conn->scope_id : 0;
}

bool Curl_zig_trc_is_verbose(struct Curl_easy *data)
{
  return Curl_trc_is_verbose(data) ? TRUE : FALSE;
}

bool Curl_zig_trc_cf_is_verbose(const struct Curl_cfilter *cf,
                                struct Curl_easy *data)
{
  return Curl_trc_cf_is_verbose(cf, data) ? TRUE : FALSE;
}

bool Curl_zig_trc_dns_is_verbose(struct Curl_easy *data)
{
  return CURL_TRC_DNS_is_verbose(data) ? TRUE : FALSE;
}

void Curl_zig_thrdq_trace(struct curl_thrdq *tqueue, struct Curl_easy *data)
{
#ifdef USE_THREADS
  CURL_THRDQ_TRACE(tqueue, data);
#else
  (void)tqueue;
  (void)data;
#endif
}

void Curl_zig_async_thrdd_classify_gai_error(int rc,
                                             int *out_sockerr,
                                             bool *out_negative)
{
  int sockerr = SOCKERRNO ? SOCKERRNO : rc;
  if(sockerr == 0)
    sockerr = EAI_MEMORY;
  *out_sockerr = sockerr;
  switch(rc) {
#ifdef EAI_NONAME
  case EAI_NONAME:
#endif
#if defined(EAI_NODATA) && \
  (!defined(EAI_NONAME) || (EAI_NODATA != EAI_NONAME))
  case EAI_NODATA:
#endif
    *out_negative = TRUE;
    break;
  default:
    *out_negative = FALSE;
    break;
  }
}

/* Helpers for zig/port/sendf.zig */
struct Curl_cwriter **Curl_sendf_get_writer_stack_ptr(struct Curl_easy *data)
{
  return &data->req.writer.stack;
}

struct Curl_creader **Curl_sendf_get_reader_stack_ptr(struct Curl_easy *data)
{
  return &data->req.reader.stack;
}

bool Curl_sendf_get_reader_started(const struct Curl_easy *data)
{
  return (bool)data->req.reader_started;
}

void Curl_sendf_set_reader_started(struct Curl_easy *data, bool val)
{
  data->req.reader_started = val ? TRUE : FALSE;
}

void Curl_sendf_reset_req_counts(struct Curl_easy *data)
{
  data->req.bytecount = 0;
  data->req.headerline = 0;
}

bool Curl_sendf_get_rewind_read(const struct Curl_easy *data)
{
  return (bool)data->req.rewind_read;
}

void Curl_sendf_set_rewind_read(struct Curl_easy *data, bool enable)
{
  data->req.rewind_read = enable ? TRUE : FALSE;
}

curl_off_t Curl_sendf_get_req_bytecount(const struct Curl_easy *data)
{
  return data->req.bytecount;
}

void Curl_sendf_add_req_bytecount(struct Curl_easy *data, size_t nwrite)
{
  data->req.bytecount += (curl_off_t)nwrite;
}

bool Curl_sendf_get_upload_done(const struct Curl_easy *data)
{
  return (bool)data->req.upload_done;
}

bool Curl_sendf_suppress_connect_headers(const struct Curl_easy *data)
{
  if(data->set.suppress_connect_headers)
    return TRUE;
#ifdef DEBUGBUILD
  if(getenv("CURL_DBG_SUPPRESS_CONNECT_HDS"))
    return TRUE;
#endif
  return FALSE;
}

bool Curl_sendf_get_no_body(const struct Curl_easy *data)
{
  return (bool)data->req.no_body;
}

void Curl_sendf_set_download_done(struct Curl_easy *data, bool done)
{
  data->req.download_done = done ? TRUE : FALSE;
}

long Curl_sendf_get_header_size(const struct Curl_easy *data)
{
  return data->info.header_size;
}

curl_off_t Curl_sendf_get_maxdownload(const struct Curl_easy *data)
{
  return data->req.maxdownload;
}

curl_off_t Curl_sendf_get_req_size(const struct Curl_easy *data)
{
  return data->req.size;
}

bool Curl_sendf_get_ignorebody(const struct Curl_easy *data)
{
  return (bool)data->req.ignorebody;
}

bool Curl_sendf_get_verbose(const struct Curl_easy *data)
{
  return (bool)data->set.verbose;
}

void Curl_sendf_get_fread_in(const struct Curl_easy *data,
                             curl_read_callback *pread_cb,
                             void **pcb_user_data)
{
  *pread_cb = data->state.fread_func;
  *pcb_user_data = data->state.in;
}

bool Curl_sendf_has_seek_func(const struct Curl_easy *data)
{
  return data->set.seek_func != NULL;
}

int Curl_sendf_call_seek_func(struct Curl_easy *data, curl_off_t offset)
{
  int seekerr = CURL_SEEKFUNC_CANTSEEK;
  if(data->set.seek_func) {
    struct Curl_mapi_guard guard;
    CURL_CBAPI_START(&guard, data, easy_seek_func);
    seekerr = data->set.seek_func(data->set.seek_client, offset, SEEK_SET);
    CURL_CBAPI_END(&guard);
  }
  return seekerr;
}

bool Curl_sendf_has_ioctl_func(const struct Curl_easy *data)
{
  return data->set.ioctl_func != NULL;
}

int Curl_sendf_call_ioctl_restartread(struct Curl_easy *data)
{
  struct Curl_mapi_guard guard;
  curlioerr err;
  CURL_CBAPI_START(&guard, data, easy_ioctl_func);
  err = data->set.ioctl_func(data, CURLIOCMD_RESTARTREAD,
                             data->set.ioctl_client);
  CURL_CBAPI_END(&guard);
  return (int)err;
}

bool Curl_sendf_try_fseek_rewind(struct Curl_easy *data,
                                 int *perr, int *perrno)
{
#if defined(__clang__) && __clang_major__ >= 16
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wcast-function-type-strict"
#endif
  if(data->state.fread_func == (curl_read_callback)fread) {
#if defined(__clang__) && __clang_major__ >= 16
#pragma clang diagnostic pop
#endif
    *perr = fseek(data->state.in, 0, SEEK_SET);
    *perrno = (int)errno;
    return TRUE;
  }
  *perr = -1;
  *perrno = 0;
  return FALSE;
}

bool Curl_sendf_want_crlf_reader(const struct Curl_easy *data)
{
#ifdef CURL_PREFER_LF_LINEENDS
  return (data->set.crlf || data->state.prefer_ascii) ? TRUE : FALSE;
#else
  return data->set.crlf ? TRUE : FALSE;
#endif
}

curl_off_t Curl_sendf_get_infilesize(const struct Curl_easy *data)
{
  return data->state.infilesize;
}

#include "curl_sasl.h"
#include "sendf.h"
#include "easyif.h"
#include "cf-recvbuf.h"
#include "select.h"

void Curl_imap_ws_failf_str(struct Curl_easy *data, const char *msg);
void Curl_imap_ws_infof_str(struct Curl_easy *data, const char *msg);
void Curl_imap_ws_trc_ws_str(struct Curl_easy *data, const char *msg);
void Curl_imap_ws_trc_m_str(struct Curl_easy *data, const char *msg);
void Curl_imap_ws_trc_write_str(struct Curl_easy *data, const char *msg);
void Curl_imap_ws_trc_read_str(struct Curl_easy *data, const char *msg);
bool Curl_imap_ws_infof_enabled(struct Curl_easy *data);
bool Curl_imap_ws_trc_ws_enabled(struct Curl_easy *data);
bool Curl_imap_ws_trc_m_enabled(struct Curl_easy *data);
bool Curl_imap_ws_trc_write_enabled(struct Curl_easy *data);
bool Curl_imap_ws_trc_read_enabled(struct Curl_easy *data);

void Curl_imap_ws_pp_init(struct Curl_easy *data, struct pingpong *pp);
CURLcode Curl_imap_ws_pp_statemach(struct Curl_easy *data,
                                   struct pingpong *pp,
                                   bool block, bool disconnecting);
CURLcode Curl_imap_ws_pp_readresp(struct Curl_easy *data,
                                  int8_t sockindex,
                                  struct pingpong *pp,
                                  int *code, size_t *size);
CURLcode Curl_imap_ws_pp_pollset(struct Curl_easy *data,
                                 struct pingpong *pp,
                                 struct easy_pollset *ps);
CURLcode Curl_imap_ws_pp_send_str(struct Curl_easy *data,
                                  struct pingpong *pp,
                                  const char *prefix,
                                  const char *str);

unsigned short Curl_imap_ws_sasl_get_authmechs(const struct SASL *sasl);
void Curl_imap_ws_sasl_set_authmechs(struct SASL *sasl, unsigned short val);
unsigned short Curl_imap_ws_sasl_get_prefmech(const struct SASL *sasl);
void Curl_imap_ws_sasl_set_prefmech(struct SASL *sasl, unsigned short val);
unsigned short Curl_imap_ws_sasl_get_authused(const struct SASL *sasl);
void Curl_imap_ws_sasl_set_authused(struct SASL *sasl, unsigned short val);

struct connectdata *Curl_imap_ws_easy_conn(const struct Curl_easy *data);
curl_off_t Curl_imap_ws_conn_id(const struct connectdata *conn);
const char *Curl_imap_ws_conn_options(const struct connectdata *conn);
bool Curl_imap_ws_conn_protoconnstart(const struct connectdata *conn);
bool Curl_imap_ws_conn_has_creds(const struct connectdata *conn);
const char *Curl_imap_ws_conn_creds_user(const struct connectdata *conn);
const char *Curl_imap_ws_conn_creds_passwd(const struct connectdata *conn);
void Curl_imap_ws_connclose(struct connectdata *conn);
CURLcode Curl_imap_ws_upgrade_tls_setup(struct Curl_easy *data,
                                        struct connectdata *conn);
CURLcode Curl_imap_ws_prepare_append(struct Curl_easy *data,
                                     curl_off_t *pinfilesize,
                                     bool *pcrlf,
                                     unsigned char *pupload_flags);
curl_off_t Curl_imap_ws_get_infilesize(const struct Curl_easy *data);
unsigned char Curl_imap_ws_get_use_ssl(const struct Curl_easy *data);
bool Curl_imap_ws_get_connect_only(const struct Curl_easy *data);
bool Curl_imap_ws_is_upload_or_mime(const struct Curl_easy *data);
curl_off_t Curl_imap_ws_get_req_bytecount(const struct Curl_easy *data);
curl_off_t Curl_imap_ws_get_req_maxdownload(const struct Curl_easy *data);
void Curl_imap_ws_set_req_maxdownload(struct Curl_easy *data, curl_off_t val);
void Curl_imap_ws_set_req_size(struct Curl_easy *data, curl_off_t val);
bool Curl_imap_ws_get_req_no_body(const struct Curl_easy *data);
const char *Curl_imap_ws_get_up_path(const struct Curl_easy *data);
CURLU *Curl_imap_ws_get_uh(const struct Curl_easy *data);
const char *Curl_imap_ws_get_customrequest(struct Curl_easy *data);

bool Curl_imap_ws_get_raw_mode(const struct Curl_easy *data);
bool Curl_imap_ws_get_no_auto_pong(const struct Curl_easy *data);
bool Curl_imap_ws_cwriter_is_paused(const struct Curl_easy *data);
void Curl_imap_ws_mark_request_upgrade(struct Curl_easy *data);
void Curl_imap_ws_set_req_header(struct Curl_easy *data, bool val);
void Curl_imap_ws_clear_req_recv(struct Curl_easy *data);
bool Curl_imap_ws_is_method_put(const struct Curl_easy *data);
void Curl_imap_ws_restart_req_send(struct Curl_easy *data);
void Curl_imap_ws_set_upgr101_received(struct Curl_easy *data);
curl_socket_t Curl_imap_ws_conn_firstsocket(const struct Curl_easy *data);
void Curl_imap_ws_setup_http_neg(struct Curl_easy *data);
bool Curl_imap_ws_good_easy_handle(const struct Curl_easy *data);

void Curl_imap_ws_failf_str(struct Curl_easy *data, const char *msg)
{
  if(data && msg)
    failf(data, "%s", msg);
}

void Curl_imap_ws_infof_str(struct Curl_easy *data, const char *msg)
{
  if(data && msg)
    infof(data, "%s", msg);
}

void Curl_imap_ws_trc_ws_str(struct Curl_easy *data, const char *msg)
{
  if(data && msg)
    CURL_TRC_WS(data, "%s", msg);
}

void Curl_imap_ws_trc_m_str(struct Curl_easy *data, const char *msg)
{
  if(data && msg)
    CURL_TRC_M(data, "%s", msg);
}

void Curl_imap_ws_trc_write_str(struct Curl_easy *data, const char *msg)
{
  if(data && msg)
    CURL_TRC_WRITE(data, "%s", msg);
}

void Curl_imap_ws_trc_read_str(struct Curl_easy *data, const char *msg)
{
  if(data && msg)
    CURL_TRC_READ(data, "%s", msg);
}

bool Curl_imap_ws_infof_enabled(struct Curl_easy *data)
{
#ifdef CURLVERBOSE
  return data && Curl_trc_is_verbose(data);
#else
  (void)data;
  return FALSE;
#endif
}

bool Curl_imap_ws_trc_ws_enabled(struct Curl_easy *data)
{
#ifdef CURLVERBOSE
  return data && Curl_trc_ft_is_verbose(data, &Curl_trc_feat_ws);
#else
  (void)data;
  return FALSE;
#endif
}

bool Curl_imap_ws_trc_m_enabled(struct Curl_easy *data)
{
#ifdef CURLVERBOSE
  return data && Curl_trc_ft_is_verbose(data, &Curl_trc_feat_multi);
#else
  (void)data;
  return FALSE;
#endif
}

bool Curl_imap_ws_trc_write_enabled(struct Curl_easy *data)
{
#ifdef CURLVERBOSE
  return data && Curl_trc_ft_is_verbose(data, &Curl_trc_feat_write);
#else
  (void)data;
  return FALSE;
#endif
}

bool Curl_imap_ws_trc_read_enabled(struct Curl_easy *data)
{
#ifdef CURLVERBOSE
  return data && Curl_trc_ft_is_verbose(data, &Curl_trc_feat_read);
#else
  (void)data;
  return FALSE;
#endif
}

CURLcode Curl_imap_ws_pp_statemach(struct Curl_easy *data,
                                   struct pingpong *pp,
                                   bool block, bool disconnecting)
{
  return Curl_pp_statemach(data, pp, block, disconnecting);
}

CURLcode Curl_imap_ws_pp_readresp(struct Curl_easy *data,
                                  int8_t sockindex,
                                  struct pingpong *pp,
                                  int *code, size_t *size)
{
  return Curl_pp_readresp(data, sockindex, pp, code, size);
}

CURLcode Curl_imap_ws_pp_pollset(struct Curl_easy *data,
                                 struct pingpong *pp,
                                 struct easy_pollset *ps)
{
  return Curl_pp_pollset(data, pp, ps);
}

static CURLcode imap_ws_pp_vsendf_fmt(struct Curl_easy *data,
                                      struct pingpong *pp,
                                      const char *prefix,
                                      const char *fmt, ...) CURL_PRINTF(4, 5);
static CURLcode imap_ws_pp_vsendf_fmt(struct Curl_easy *data,
                                      struct pingpong *pp,
                                      const char *prefix,
                                      const char *fmt, ...)
{
  va_list ap;
  CURLcode result;
  va_start(ap, fmt);
  result = Curl_pp_vsendf(data, pp, prefix, fmt, ap);
  va_end(ap);
  return result;
}

void Curl_imap_ws_pp_init(struct Curl_easy *data, struct pingpong *pp)
{
  Curl_pp_init(pp, Curl_pgrs_now(data));
}

CURLcode Curl_imap_ws_pp_send_str(struct Curl_easy *data,
                                  struct pingpong *pp,
                                  const char *prefix,
                                  const char *str)
{
  if(prefix)
    return imap_ws_pp_vsendf_fmt(data, pp, prefix, "%s", str);
  return Curl_pp_sendf(data, pp, "%s", str);
}

unsigned short Curl_imap_ws_sasl_get_authmechs(const struct SASL *sasl)
{
  return sasl ? sasl->authmechs : 0;
}

void Curl_imap_ws_sasl_set_authmechs(struct SASL *sasl, unsigned short val)
{
  if(sasl)
    sasl->authmechs = val;
}

unsigned short Curl_imap_ws_sasl_get_prefmech(const struct SASL *sasl)
{
  return sasl ? sasl->prefmech : 0;
}

void Curl_imap_ws_sasl_set_prefmech(struct SASL *sasl, unsigned short val)
{
  if(sasl)
    sasl->prefmech = val;
}

unsigned short Curl_imap_ws_sasl_get_authused(const struct SASL *sasl)
{
  return sasl ? sasl->authused : 0;
}

void Curl_imap_ws_sasl_set_authused(struct SASL *sasl, unsigned short val)
{
  if(sasl)
    sasl->authused = val;
}

struct connectdata *Curl_imap_ws_easy_conn(const struct Curl_easy *data)
{
  return data ? data->conn : NULL;
}

curl_off_t Curl_imap_ws_conn_id(const struct connectdata *conn)
{
  return conn ? conn->connection_id : 0;
}

const char *Curl_imap_ws_conn_options(const struct connectdata *conn)
{
  return conn ? conn->options : NULL;
}

bool Curl_imap_ws_conn_protoconnstart(const struct connectdata *conn)
{
  return conn ? (bool)conn->bits.protoconnstart : FALSE;
}

bool Curl_imap_ws_conn_has_creds(const struct connectdata *conn)
{
  return conn && conn->creds != NULL;
}

const char *Curl_imap_ws_conn_creds_user(const struct connectdata *conn)
{
  return conn ? Curl_creds_user(conn->creds) : "";
}

const char *Curl_imap_ws_conn_creds_passwd(const struct connectdata *conn)
{
  return conn ? Curl_creds_passwd(conn->creds) : "";
}

void Curl_imap_ws_connclose(struct connectdata *conn)
{
  if(conn)
    connclose(conn);
}

CURLcode Curl_imap_ws_upgrade_tls_setup(struct Curl_easy *data,
                                        struct connectdata *conn)
{
#ifdef USE_SSL
  if(!Curl_conn_is_ssl(conn, FIRSTSOCKET)) {
    CURLcode result = Curl_ssl_cfilter_add(
      data, Curl_conn_get_origin(conn, FIRSTSOCKET), conn, FIRSTSOCKET);
    if(result)
      return result;
    conn->scheme = &Curl_scheme_imaps;
  }
  return CURLE_OK;
#else
  (void)data;
  (void)conn;
  return CURLE_NOT_BUILT_IN;
#endif
}

CURLcode Curl_imap_ws_prepare_append(struct Curl_easy *data,
                                     curl_off_t *pinfilesize,
                                     bool *pcrlf,
                                     unsigned char *pupload_flags)
{
  CURLcode result = CURLE_OK;
#ifndef CURL_DISABLE_MIME
  if(IS_MIME_POST(data)) {
    curl_mimepart *postp = data->set.mimepostp;
    postp->flags &= ~(unsigned int)MIME_BODY_ONLY;
    curl_mime_headers(postp, data->set.headers, 0);
    result = Curl_mime_prepare_headers(data, postp, NULL,
                                       NULL, MIMESTRATEGY_MAIL);
    if(!result && !Curl_checkheaders(data, STRCONST("Mime-Version")))
      result = Curl_mime_add_header(&postp->curlheaders, "Mime-Version: 1.0");
    if(!result)
      result = Curl_creader_set_mime(data, postp);
    if(result)
      return result;
  }
  else
#endif
  {
    result = Curl_creader_set_fread(data, data->state.infilesize);
    if(result)
      return result;
  }

  data->state.infilesize = Curl_creader_total_length(data);
  *pinfilesize = data->state.infilesize;
  *pcrlf = (bool)data->set.crlf;
  *pupload_flags = data->set.upload_flags;
  return CURLE_OK;
}

curl_off_t Curl_imap_ws_get_infilesize(const struct Curl_easy *data)
{
  return data ? data->state.infilesize : -1;
}

unsigned char Curl_imap_ws_get_use_ssl(const struct Curl_easy *data)
{
  return data ? data->set.use_ssl : 0;
}

bool Curl_imap_ws_get_connect_only(const struct Curl_easy *data)
{
  return data ? (bool)data->set.connect_only : FALSE;
}

bool Curl_imap_ws_is_upload_or_mime(const struct Curl_easy *data)
{
  return data ? (bool)(data->state.upload || IS_MIME_POST(data)) : FALSE;
}

curl_off_t Curl_imap_ws_get_req_bytecount(const struct Curl_easy *data)
{
  return data ? data->req.bytecount : 0;
}

curl_off_t Curl_imap_ws_get_req_maxdownload(const struct Curl_easy *data)
{
  return data ? data->req.maxdownload : -1;
}

void Curl_imap_ws_set_req_maxdownload(struct Curl_easy *data, curl_off_t val)
{
  if(data)
    data->req.maxdownload = val;
}

void Curl_imap_ws_set_req_size(struct Curl_easy *data, curl_off_t val)
{
  if(data)
    data->req.size = val;
}

bool Curl_imap_ws_get_req_no_body(const struct Curl_easy *data)
{
  return data ? (bool)data->req.no_body : FALSE;
}

const char *Curl_imap_ws_get_up_path(const struct Curl_easy *data)
{
  return data ? data->state.up.path : NULL;
}

CURLU *Curl_imap_ws_get_uh(const struct Curl_easy *data)
{
  return data ? data->state.uh : NULL;
}

const char *Curl_imap_ws_get_customrequest(struct Curl_easy *data)
{
  return data ? CURL_EASY_STR(data, STRING_CUSTOMREQUEST) : NULL;
}

bool Curl_imap_ws_get_raw_mode(const struct Curl_easy *data)
{
  return data ? (bool)data->set.ws_raw_mode : FALSE;
}

bool Curl_imap_ws_get_no_auto_pong(const struct Curl_easy *data)
{
  return data ? (bool)data->set.ws_no_auto_pong : FALSE;
}

bool Curl_imap_ws_cwriter_is_paused(const struct Curl_easy *data)
{
  return data ? Curl_cwriter_is_paused(data) : FALSE;
}

void Curl_imap_ws_mark_request_upgrade(struct Curl_easy *data)
{
  if(data) {
    data->state.http_hd_upgrade = TRUE;
    data->req.upgr101 = UPGR101_WS;
    if(data->conn)
      data->conn->bits.upgrade_in_progress = TRUE;
  }
}

void Curl_imap_ws_set_req_header(struct Curl_easy *data, bool val)
{
  if(data)
    data->req.header = val;
}

void Curl_imap_ws_clear_req_recv(struct Curl_easy *data)
{
  if(data)
    CURL_REQ_CLEAR_RECV(data);
}

bool Curl_imap_ws_is_method_put(const struct Curl_easy *data)
{
  return data ? (data->set.method == HTTPREQ_PUT) : FALSE;
}

void Curl_imap_ws_restart_req_send(struct Curl_easy *data)
{
  if(data) {
    data->req.eos_read = FALSE;
    data->req.upload_done = FALSE;
    CURL_REQ_SET_SEND(data);
  }
}

void Curl_imap_ws_set_upgr101_received(struct Curl_easy *data)
{
  if(data)
    data->req.upgr101 = UPGR101_RECEIVED;
}

curl_socket_t Curl_imap_ws_conn_firstsocket(const struct Curl_easy *data)
{
  return (data && data->conn) ? data->conn->sock[FIRSTSOCKET] :
                                CURL_SOCKET_BAD;
}

void Curl_imap_ws_setup_http_neg(struct Curl_easy *data)
{
  if(data) {
    data->state.http_neg.accept_09 = FALSE;
    data->state.http_neg.only_10 = FALSE;
    data->state.http_neg.wanted = CURL_HTTP_V1x;
    data->state.http_neg.allowed = CURL_HTTP_V1x;
  }
}

bool Curl_imap_ws_good_easy_handle(const struct Curl_easy *data)
{
  return GOOD_EASY_HANDLE(data);
}

#include "sigpipe.h"
#include "vdns/dnscache.h"
#include "vdns/doh.h"
#include "vdns/hostip.h"

/* Thin accessors for zig/port/vdns_core.zig */
struct Curl_peer *Curl_vdns_data_conn_origin(const struct Curl_easy *data);
bool Curl_vdns_trc_is_verbose(const struct Curl_easy *data);
bool Curl_vdns_trc_dns_is_verbose(const struct Curl_easy *data);
struct connectdata *Curl_vdns_data_conn(const struct Curl_easy *data);
struct Curl_cfilter *Curl_vdns_conn_cfilter(const struct connectdata *conn,
                                            int8_t sockindex);
uint8_t Curl_vdns_conn_transport_wanted(const struct connectdata *conn);
void Curl_vdns_conn_set_dns_resolved(struct connectdata *conn);
bool Curl_vdns_conn_is_proxy_peer(const struct connectdata *conn,
                                  const struct Curl_peer *peer);
struct Curl_dnscache *Curl_vdns_dnscache_get(const struct Curl_easy *data);
void Curl_vdns_dnscache_lock(struct Curl_easy *data,
                             struct Curl_dnscache *dnscache);
void Curl_vdns_dnscache_unlock(struct Curl_easy *data,
                               struct Curl_dnscache *dnscache);
timediff_t Curl_vdns_data_dns_cache_timeout_ms(const struct Curl_easy *data);
bool Curl_vdns_data_get_wildcard_resolve(const struct Curl_easy *data);
void Curl_vdns_data_set_wildcard_resolve(struct Curl_easy *data, bool val);
bool Curl_vdns_data_dns_shuffle_addresses(const struct Curl_easy *data);
struct curl_slist *Curl_vdns_data_get_resolve(const struct Curl_easy *data);
void Curl_vdns_data_clear_resolve(struct Curl_easy *data);

struct Curl_peer *Curl_vdns_data_conn_origin(const struct Curl_easy *data)
{
  return (data && data->conn) ? data->conn->origin : NULL;
}

bool Curl_vdns_trc_is_verbose(const struct Curl_easy *data)
{
  return Curl_trc_is_verbose(data);
}

bool Curl_vdns_trc_dns_is_verbose(const struct Curl_easy *data)
{
  return CURL_TRC_DNS_is_verbose(data);
}

struct connectdata *Curl_vdns_data_conn(const struct Curl_easy *data)
{
  return data ? data->conn : NULL;
}

struct Curl_cfilter *Curl_vdns_conn_cfilter(const struct connectdata *conn,
                                            int8_t sockindex)
{
  return conn ? conn->cfilter[sockindex] : NULL;
}

uint8_t Curl_vdns_conn_transport_wanted(const struct connectdata *conn)
{
  return conn ? conn->transport_wanted : 0;
}

void Curl_vdns_conn_set_dns_resolved(struct connectdata *conn)
{
  if(conn)
    conn->bits.dns_resolved = TRUE;
}

bool Curl_vdns_conn_is_proxy_peer(const struct connectdata *conn,
                                  const struct Curl_peer *peer)
{
#ifndef CURL_DISABLE_PROXY
  return conn &&
    ((peer == conn->socks_proxy.peer) || (peer == conn->http_proxy.peer));
#else
  (void)conn;
  (void)peer;
  return FALSE;
#endif
}

struct Curl_dnscache *Curl_vdns_dnscache_get(const struct Curl_easy *data)
{
  if(!data)
    return NULL;
  if(data->share && (data->share->specifier & (1 << CURL_LOCK_DATA_DNS)))
    return &data->share->dnscache;
  if(data->multi)
    return &data->multi->dnscache;
  return NULL;
}

void Curl_vdns_dnscache_lock(struct Curl_easy *data,
                             struct Curl_dnscache *dnscache)
{
  if(data && data->share && (dnscache == &data->share->dnscache))
    Curl_share_lock(data, CURL_LOCK_DATA_DNS, CURL_LOCK_ACCESS_SINGLE);
}

void Curl_vdns_dnscache_unlock(struct Curl_easy *data,
                               struct Curl_dnscache *dnscache)
{
  if(data && data->share && (dnscache == &data->share->dnscache))
    Curl_share_unlock(data, CURL_LOCK_DATA_DNS);
}

timediff_t Curl_vdns_data_dns_cache_timeout_ms(const struct Curl_easy *data)
{
  return data ? data->set.dns_cache_timeout_ms : 0;
}

bool Curl_vdns_data_get_wildcard_resolve(const struct Curl_easy *data)
{
  return data ? (bool)data->state.wildcard_resolve : FALSE;
}

void Curl_vdns_data_set_wildcard_resolve(struct Curl_easy *data, bool val)
{
  if(data)
    data->state.wildcard_resolve = val;
}

bool Curl_vdns_data_dns_shuffle_addresses(const struct Curl_easy *data)
{
  return data ? (bool)data->set.dns_shuffle_addresses : FALSE;
}

struct curl_slist *Curl_vdns_data_get_resolve(const struct Curl_easy *data)
{
  return data ? data->state.resolve : NULL;
}

void Curl_vdns_data_clear_resolve(struct Curl_easy *data)
{
  if(data)
    data->state.resolve = NULL;
}

/* Thin accessors for zig/port/doh_hostip_easy.zig */
const char *Curl_easy_str_doh(const struct Curl_easy *data);
const char *Curl_easy_str_ssl_cafile(const struct Curl_easy *data);
const char *Curl_easy_str_ssl_capath(const struct Curl_easy *data);
const char *Curl_easy_str_ssl_crlfile(const struct Curl_easy *data);
const char *Curl_easy_str_ssl_ec_curves(const struct Curl_easy *data);
const char *Curl_easy_str_altsvc(const struct Curl_easy *data);
const char *Curl_easy_str_hsts(const struct Curl_easy *data);
struct curl_blob *Curl_easy_blob_cainfo(const struct Curl_easy *data);
struct Curl_multi *Curl_easy_get_multi(const struct Curl_easy *data);
struct Curl_multi *Curl_easy_get_multi_easy(const struct Curl_easy *data);
void Curl_easy_set_multi_easy(struct Curl_easy *data,
                              struct Curl_multi *multi);
uint32_t Curl_easy_get_mid(const struct Curl_easy *data);
int Curl_easy_get_httpcode(const struct Curl_easy *data);
struct Curl_share *Curl_easy_get_share(const struct Curl_easy *data);
FILE *Curl_doh_data_custom_stderr(const struct Curl_easy *data);
bool Curl_easy_get_no_signal(const struct Curl_easy *data);
void *Curl_doh_data_fdebug(const struct Curl_easy *data);
void *Curl_doh_data_debugdata(const struct Curl_easy *data);
bool Curl_doh_data_verifyhost(const struct Curl_easy *data);
bool Curl_doh_data_verifypeer(const struct Curl_easy *data);
bool Curl_doh_data_verifystatus(const struct Curl_easy *data);
void Curl_doh_copy_ssl_custom_flags(struct Curl_easy *doh,
                                    const struct Curl_easy *data);
bool Curl_doh_data_ssl_certinfo(const struct Curl_easy *data);
void *Curl_doh_data_ssl_fsslctx(const struct Curl_easy *data);
void *Curl_doh_data_ssl_fsslctxp(const struct Curl_easy *data);
uint8_t Curl_doh_data_ssl_options(const struct Curl_easy *data);
void Curl_doh_set_feat(struct Curl_easy *doh);
void Curl_doh_init_probe_state(struct Curl_easy *doh,
                               const struct Curl_easy *data,
                               multi_sub_xfer_done_cb *cb);
void Curl_doh_clear_sub_xfer_done(struct Curl_easy *probe_data);
void Curl_multi_set_ipv6_works(struct Curl_multi *multi, bool works);
bool Curl_easy_ipv6_works(const struct Curl_easy *data);
curl_resolver_start_callback
Curl_easy_get_resolver_start(const struct Curl_easy *data);
void *Curl_easy_get_resolver_start_client(const struct Curl_easy *data);
uint32_t Curl_multi_next_resolv_id(struct Curl_multi *multi);
bool Curl_easy_get_doh(const struct Curl_easy *data);
struct Curl_resolv_async *
Curl_easy_get_async_head(const struct Curl_easy *data);
void Curl_easy_set_async_head(struct Curl_easy *data,
                              struct Curl_resolv_async *async);
const struct Curl_scheme *
Curl_easy_get_conn_scheme(const struct Curl_easy *data);
void Curl_easy_sigpipe_ignore(struct Curl_easy *data, void *ctx_buf);
void Curl_easy_sigpipe_restore(void *ctx_buf);
void Curl_easy_clear_error_and_errno(struct Curl_easy *data);
uint32_t Curl_easy_get_maxconnects(const struct Curl_easy *data);
bool Curl_easy_get_quick_exit(const struct Curl_easy *data);
size_t Curl_easy_sizeof(void);
void Curl_easy_dupset_init(struct Curl_easy *dst,
                           const struct Curl_easy *src);
struct u8_strset *Curl_easy_get_strings(struct Curl_easy *data);
unsigned int Curl_easy_blob_count(void);
struct curl_blob **Curl_easy_get_blob_slot(struct Curl_easy *data,
                                           unsigned int idx);
struct curl_blob *Curl_easy_get_blob_at(const struct Curl_easy *data,
                                        unsigned int idx);
char *Curl_easy_get_copypostfields(const struct Curl_easy *data);
curl_off_t Curl_easy_get_postfieldsize(const struct Curl_easy *data);
void Curl_easy_set_copypostfields(struct Curl_easy *data, char *p);
struct curl_mimepart *Curl_easy_get_mimepostp(const struct Curl_easy *data);
size_t Curl_easy_mimepart_sizeof(void);
void Curl_easy_set_mimepostp(struct Curl_easy *data,
                             struct curl_mimepart *p);
void Curl_easy_sync_state_resolve(struct Curl_easy *dst,
                                  const struct Curl_easy *src);
void Curl_easy_dup_copy_buffer_size(struct Curl_easy *outcurl,
                                    const struct Curl_easy *data);
struct Curl_hash *Curl_easy_get_meta_hash(struct Curl_easy *data);
struct dynbuf *Curl_easy_get_headerb(struct Curl_easy *data);
struct bufref *Curl_easy_get_state_url(struct Curl_easy *data);
struct bufref *Curl_easy_get_state_referer(struct Curl_easy *data);
struct store_netrc *Curl_easy_get_state_netrc(struct Curl_easy *data);
struct Curl_llist *Curl_easy_get_state_httphdrs(struct Curl_easy *data);
void Curl_easy_dup_init_ids(struct Curl_easy *outcurl);
void Curl_easy_dup_copy_progress(struct Curl_easy *outcurl,
                                 const struct Curl_easy *data);
bool Curl_easy_has_cookie_engine(const struct Curl_easy *data);
struct CookieInfo *Curl_easy_get_cookies(const struct Curl_easy *data);
void Curl_easy_set_cookies_enabled(struct Curl_easy *data,
                                   struct CookieInfo *ci);
struct curl_slist *Curl_easy_get_state_cookielist(const struct Curl_easy *data);
void Curl_easy_set_state_cookielist(struct Curl_easy *data,
                                    struct curl_slist *list);
struct altsvcinfo *Curl_easy_get_asi(const struct Curl_easy *data);
struct altsvcinfo **Curl_easy_get_asi_slot(struct Curl_easy *data);
struct hsts *Curl_easy_get_hsts(const struct Curl_easy *data);
struct hsts **Curl_easy_get_hsts_slot(struct Curl_easy *data);
CURLcode Curl_easy_hsts_loadcb(struct Curl_easy *data, struct hsts *h);
void Curl_easy_set_magic(struct Curl_easy *data, uint32_t magic);
void Curl_easy_reset_conn_ids(struct Curl_easy *data);
void Curl_easy_req_hard_reset(struct Curl_easy *data);
void Curl_easy_zero_set(struct Curl_easy *data);
void Curl_easy_zero_progress(struct Curl_easy *data);
void Curl_easy_reset_post_initinfo(struct Curl_easy *data);
void Curl_easy_clear_keeps_speed_sec(struct Curl_easy *data);
bool Curl_easy_get_state_done(const struct Curl_easy *data);
uint8_t Curl_easy_get_connect_only(const struct Curl_easy *data);
curl_off_t Curl_easy_get_last_conn_id(const struct Curl_easy *data);

const char *Curl_easy_str_doh(const struct Curl_easy *data)
{
#ifndef CURL_DISABLE_DOH
  return data ? CURL_EASY_STR((struct Curl_easy *)data, STRING_DOH) : NULL;
#else
  (void)data;
  return NULL;
#endif
}

const char *Curl_easy_str_ssl_cafile(const struct Curl_easy *data)
{
  return data ?
    CURL_EASY_STR((struct Curl_easy *)data, STRING_SSL_CAFILE) : NULL;
}

const char *Curl_easy_str_ssl_capath(const struct Curl_easy *data)
{
  return data ?
    CURL_EASY_STR((struct Curl_easy *)data, STRING_SSL_CAPATH) : NULL;
}

const char *Curl_easy_str_ssl_crlfile(const struct Curl_easy *data)
{
  return data ?
    CURL_EASY_STR((struct Curl_easy *)data, STRING_SSL_CRLFILE) : NULL;
}

const char *Curl_easy_str_ssl_ec_curves(const struct Curl_easy *data)
{
  return data ?
    CURL_EASY_STR((struct Curl_easy *)data, STRING_SSL_EC_CURVES) : NULL;
}

const char *Curl_easy_str_altsvc(const struct Curl_easy *data)
{
#ifndef CURL_DISABLE_ALTSVC
  return data ? CURL_EASY_STR((struct Curl_easy *)data, STRING_ALTSVC) : NULL;
#else
  (void)data;
  return NULL;
#endif
}

const char *Curl_easy_str_hsts(const struct Curl_easy *data)
{
#ifndef CURL_DISABLE_HSTS
  return data ? CURL_EASY_STR((struct Curl_easy *)data, STRING_HSTS) : NULL;
#else
  (void)data;
  return NULL;
#endif
}

struct curl_blob *Curl_easy_blob_cainfo(const struct Curl_easy *data)
{
  return data ? data->set.blobs[BLOB_CAINFO] : NULL;
}

struct Curl_multi *Curl_easy_get_multi(const struct Curl_easy *data)
{
  return data ? data->multi : NULL;
}

struct Curl_multi *Curl_easy_get_multi_easy(const struct Curl_easy *data)
{
  return data ? data->multi_easy : NULL;
}

void Curl_easy_set_multi_easy(struct Curl_easy *data, struct Curl_multi *multi)
{
  if(data)
    data->multi_easy = multi;
}

uint32_t Curl_easy_get_mid(const struct Curl_easy *data)
{
  return data ? data->mid : UINT32_MAX;
}

int Curl_easy_get_httpcode(const struct Curl_easy *data)
{
  return data ? data->info.httpcode : 0;
}

struct Curl_share *Curl_easy_get_share(const struct Curl_easy *data)
{
  return data ? data->share : NULL;
}

FILE *Curl_doh_data_custom_stderr(const struct Curl_easy *data)
{
  return (data && data->set.err && data->set.err != stderr) ?
    data->set.err : NULL;
}

bool Curl_easy_get_no_signal(const struct Curl_easy *data)
{
  return data ? (bool)data->set.no_signal : FALSE;
}

void *Curl_doh_data_fdebug(const struct Curl_easy *data)
{
  return data ? (void *)data->set.fdebug : NULL;
}

void *Curl_doh_data_debugdata(const struct Curl_easy *data)
{
  return data ? data->set.debugdata : NULL;
}

bool Curl_doh_data_verifyhost(const struct Curl_easy *data)
{
  return data ? (bool)data->set.doh_verifyhost : FALSE;
}

bool Curl_doh_data_verifypeer(const struct Curl_easy *data)
{
  return data ? (bool)data->set.doh_verifypeer : FALSE;
}

bool Curl_doh_data_verifystatus(const struct Curl_easy *data)
{
  return data ? (bool)data->set.doh_verifystatus : FALSE;
}

void Curl_doh_copy_ssl_custom_flags(struct Curl_easy *doh,
                                    const struct Curl_easy *data)
{
  if(doh && data) {
    doh->set.ssl.custom_cafile = data->set.ssl.custom_cafile;
    doh->set.ssl.custom_capath = data->set.ssl.custom_capath;
    doh->set.ssl.custom_cablob = data->set.ssl.custom_cablob;
  }
}

bool Curl_doh_data_ssl_certinfo(const struct Curl_easy *data)
{
  return data ? (bool)data->set.ssl.certinfo : FALSE;
}

void *Curl_doh_data_ssl_fsslctx(const struct Curl_easy *data)
{
  return data ? (void *)data->set.ssl_fsslctx : NULL;
}

void *Curl_doh_data_ssl_fsslctxp(const struct Curl_easy *data)
{
  return data ? data->set.ssl_fsslctxp : NULL;
}

uint8_t Curl_doh_data_ssl_options(const struct Curl_easy *data)
{
  return data ? data->set.ssl.ssl_options : 0;
}

void Curl_doh_set_feat(struct Curl_easy *doh)
{
#ifdef CURLVERBOSE
  if(doh)
    doh->state.feat = &Curl_trc_feat_doh;
#else
  (void)doh;
#endif
}

void Curl_doh_init_probe_state(struct Curl_easy *doh,
                               const struct Curl_easy *data,
                               multi_sub_xfer_done_cb *cb)
{
  if(doh && data) {
    doh->state.internal = TRUE;
    doh->master_mid = data->mid;
    doh->sub_xfer_done = cb;
  }
}

void Curl_doh_clear_sub_xfer_done(struct Curl_easy *probe_data)
{
  if(probe_data)
    probe_data->sub_xfer_done = NULL;
}

void Curl_multi_set_ipv6_works(struct Curl_multi *multi, bool works)
{
  if(multi)
    multi->ipv6_works = works;
}

bool Curl_easy_ipv6_works(const struct Curl_easy *data)
{
  return (data && data->multi) ? (bool)data->multi->ipv6_works : FALSE;
}

curl_resolver_start_callback
Curl_easy_get_resolver_start(const struct Curl_easy *data)
{
  return data ? data->set.resolver_start : NULL;
}

void *Curl_easy_get_resolver_start_client(const struct Curl_easy *data)
{
  return data ? data->set.resolver_start_client : NULL;
}

uint32_t Curl_multi_next_resolv_id(struct Curl_multi *multi)
{
  if(!multi)
    return 0;
  if(multi->last_resolv_id == UINT32_MAX)
    multi->last_resolv_id = 1;
  else
    multi->last_resolv_id++;
  return multi->last_resolv_id;
}

bool Curl_easy_get_doh(const struct Curl_easy *data)
{
  return data ? (bool)data->set.doh : FALSE;
}

struct Curl_resolv_async *
Curl_easy_get_async_head(const struct Curl_easy *data)
{
  return data ? data->state.async : NULL;
}

void Curl_easy_set_async_head(struct Curl_easy *data,
                              struct Curl_resolv_async *async)
{
  if(data)
    data->state.async = async;
}

const struct Curl_scheme *
Curl_easy_get_conn_scheme(const struct Curl_easy *data)
{
  return (data && data->conn) ? data->conn->scheme : NULL;
}

void Curl_easy_sigpipe_ignore(struct Curl_easy *data, void *ctx_buf)
{
  struct Curl_sigpipe_ctx *ig = (struct Curl_sigpipe_ctx *)ctx_buf;
  DEBUGASSERT(sizeof(struct Curl_sigpipe_ctx) <= 256);
  sigpipe_init(ig);
  sigpipe_ignore(data, ig);
}

void Curl_easy_sigpipe_restore(void *ctx_buf)
{
  struct Curl_sigpipe_ctx *ig = (struct Curl_sigpipe_ctx *)ctx_buf;
  sigpipe_restore(ig);
}

void Curl_easy_clear_error_and_errno(struct Curl_easy *data)
{
  if(data) {
    if(data->set.errorbuffer)
      data->set.errorbuffer[0] = 0;
    data->state.os_errno = 0;
  }
}

uint32_t Curl_easy_get_maxconnects(const struct Curl_easy *data)
{
  return data ? data->set.maxconnects : 0;
}

bool Curl_easy_get_quick_exit(const struct Curl_easy *data)
{
  return data ? (bool)data->set.quick_exit : FALSE;
}

size_t Curl_easy_sizeof(void)
{
  return sizeof(struct Curl_easy);
}

void Curl_easy_dupset_init(struct Curl_easy *dst,
                           const struct Curl_easy *src)
{
  dst->set = src->set;
#if !defined(CURL_DISABLE_MIME) || !defined(CURL_DISABLE_FORM_API)
  dst->set.mimepostp = NULL;
#endif
  dst->set.str_copypostfields = NULL;
  memset(dst->set.blobs, 0, BLOB_LAST * sizeof(struct curl_blob *));
}

struct u8_strset *Curl_easy_get_strings(struct Curl_easy *data)
{
  return data ? &data->set.strings : NULL;
}

unsigned int Curl_easy_blob_count(void)
{
  return (unsigned int)BLOB_LAST;
}

struct curl_blob **Curl_easy_get_blob_slot(struct Curl_easy *data,
                                           unsigned int idx)
{
  return (data && idx < BLOB_LAST) ? &data->set.blobs[idx] : NULL;
}

struct curl_blob *Curl_easy_get_blob_at(const struct Curl_easy *data,
                                        unsigned int idx)
{
  return (data && idx < BLOB_LAST) ? data->set.blobs[idx] : NULL;
}

char *Curl_easy_get_copypostfields(const struct Curl_easy *data)
{
  return data ? data->set.str_copypostfields : NULL;
}

curl_off_t Curl_easy_get_postfieldsize(const struct Curl_easy *data)
{
  return data ? data->set.postfieldsize : 0;
}

void Curl_easy_set_copypostfields(struct Curl_easy *data, char *p)
{
  if(data) {
    data->set.str_copypostfields = p;
    data->set.postfields = p;
  }
}

struct curl_mimepart *Curl_easy_get_mimepostp(const struct Curl_easy *data)
{
#if !defined(CURL_DISABLE_MIME) || !defined(CURL_DISABLE_FORM_API)
  return data ? data->set.mimepostp : NULL;
#else
  (void)data;
  return NULL;
#endif
}

size_t Curl_easy_mimepart_sizeof(void)
{
#if !defined(CURL_DISABLE_MIME) || !defined(CURL_DISABLE_FORM_API)
  return sizeof(struct curl_mimepart);
#else
  return 0;
#endif
}

void Curl_easy_set_mimepostp(struct Curl_easy *data,
                             struct curl_mimepart *p)
{
#if !defined(CURL_DISABLE_MIME) || !defined(CURL_DISABLE_FORM_API)
  if(data)
    data->set.mimepostp = p;
#else
  (void)data;
  (void)p;
#endif
}

void Curl_easy_sync_state_resolve(struct Curl_easy *dst,
                                  const struct Curl_easy *src)
{
  if(dst && src && src->set.resolve)
    dst->state.resolve = dst->set.resolve;
}

void Curl_easy_dup_copy_buffer_size(struct Curl_easy *outcurl,
                                    const struct Curl_easy *data)
{
  outcurl->set.buffer_size = data->set.buffer_size;
}

struct Curl_hash *Curl_easy_get_meta_hash(struct Curl_easy *data)
{
  return data ? &data->meta_hash : NULL;
}

struct dynbuf *Curl_easy_get_headerb(struct Curl_easy *data)
{
  return data ? &data->state.headerb : NULL;
}

struct bufref *Curl_easy_get_state_url(struct Curl_easy *data)
{
  return data ? &data->state.url : NULL;
}

struct bufref *Curl_easy_get_state_referer(struct Curl_easy *data)
{
  return data ? &data->state.referer : NULL;
}

struct store_netrc *Curl_easy_get_state_netrc(struct Curl_easy *data)
{
  return data ? &data->state.netrc : NULL;
}

struct Curl_llist *Curl_easy_get_state_httphdrs(struct Curl_easy *data)
{
#ifndef CURL_DISABLE_HTTP
  return data ? &data->state.httphdrs : NULL;
#else
  (void)data;
  return NULL;
#endif
}

void Curl_easy_dup_init_ids(struct Curl_easy *outcurl)
{
  outcurl->state.last_conn_id = -1;
  outcurl->state.last_cpid = UINT32_MAX;
  outcurl->id = -1;
  outcurl->mid = UINT32_MAX;
  outcurl->master_mid = UINT32_MAX;
}

void Curl_easy_dup_copy_progress(struct Curl_easy *outcurl,
                                 const struct Curl_easy *data)
{
  outcurl->progress.hide = data->progress.hide;
  outcurl->progress.callback = data->progress.callback;
#ifndef CURL_DISABLE_COOKIES
  outcurl->state.cookielist = NULL;
#endif
}

bool Curl_easy_has_cookie_engine(const struct Curl_easy *data)
{
#ifndef CURL_DISABLE_COOKIES
  return data ? (bool)(data->cookies && data->state.cookie_engine) : FALSE;
#else
  (void)data;
  return FALSE;
#endif
}

struct CookieInfo *Curl_easy_get_cookies(const struct Curl_easy *data)
{
#ifndef CURL_DISABLE_COOKIES
  return data ? data->cookies : NULL;
#else
  (void)data;
  return NULL;
#endif
}

void Curl_easy_set_cookies_enabled(struct Curl_easy *data,
                                   struct CookieInfo *ci)
{
#ifndef CURL_DISABLE_COOKIES
  if(data) {
    data->cookies = ci;
    data->state.cookie_engine = TRUE;
  }
#else
  (void)data;
  (void)ci;
#endif
}

struct curl_slist *Curl_easy_get_state_cookielist(const struct Curl_easy *data)
{
#ifndef CURL_DISABLE_COOKIES
  return data ? data->state.cookielist : NULL;
#else
  (void)data;
  return NULL;
#endif
}

void Curl_easy_set_state_cookielist(struct Curl_easy *data,
                                    struct curl_slist *list)
{
#ifndef CURL_DISABLE_COOKIES
  if(data)
    data->state.cookielist = list;
#else
  (void)data;
  (void)list;
#endif
}

struct altsvcinfo *Curl_easy_get_asi(const struct Curl_easy *data)
{
#ifndef CURL_DISABLE_ALTSVC
  return data ? data->asi : NULL;
#else
  (void)data;
  return NULL;
#endif
}

struct altsvcinfo **Curl_easy_get_asi_slot(struct Curl_easy *data)
{
#ifndef CURL_DISABLE_ALTSVC
  return data ? &data->asi : NULL;
#else
  static struct altsvcinfo *dummy_asi = NULL;
  (void)data;
  dummy_asi = NULL;
  return &dummy_asi;
#endif
}

struct hsts *Curl_easy_get_hsts(const struct Curl_easy *data)
{
#ifndef CURL_DISABLE_HSTS
  return data ? data->hsts : NULL;
#else
  (void)data;
  return NULL;
#endif
}

struct hsts **Curl_easy_get_hsts_slot(struct Curl_easy *data)
{
#ifndef CURL_DISABLE_HSTS
  return data ? &data->hsts : NULL;
#else
  static struct hsts *dummy_hsts = NULL;
  (void)data;
  dummy_hsts = NULL;
  return &dummy_hsts;
#endif
}

CURLcode Curl_easy_hsts_loadcb(struct Curl_easy *data, struct hsts *h)
{
#ifndef CURL_DISABLE_HSTS
  return Curl_hsts_loadcb(data, h);
#else
  (void)data;
  (void)h;
  return CURLE_OK;
#endif
}

void Curl_easy_set_magic(struct Curl_easy *data, uint32_t magic)
{
  if(data)
    data->magic = magic;
}

void Curl_easy_reset_conn_ids(struct Curl_easy *data)
{
  if(data) {
    data->state.last_conn_id = -1;
    data->state.last_cpid = UINT32_MAX;
  }
}

void Curl_easy_req_hard_reset(struct Curl_easy *data)
{
  if(data)
    Curl_req_hard_reset(&data->req, data);
}

void Curl_easy_zero_set(struct Curl_easy *data)
{
  if(data)
    memset(&data->set, 0, sizeof(struct UserDefined));
}

void Curl_easy_zero_progress(struct Curl_easy *data)
{
  if(data)
    memset(&data->progress, 0, sizeof(struct Progress));
}

void Curl_easy_reset_post_initinfo(struct Curl_easy *data)
{
  if(data) {
    data->progress.hide = TRUE;
    memset(&data->state.authhost, 0, sizeof(struct auth));
    memset(&data->state.authproxy, 0, sizeof(struct auth));
    data->master_mid = UINT32_MAX;
#if !defined(CURL_DISABLE_HTTP) && !defined(CURL_DISABLE_DIGEST_AUTH)
    Curl_http_auth_cleanup_digest(data);
#endif
  }
}

void Curl_easy_clear_keeps_speed_sec(struct Curl_easy *data)
{
  if(data)
    data->state.keeps_speed.tv_sec = 0;
}

bool Curl_easy_get_state_done(const struct Curl_easy *data)
{
  return data ? (bool)data->state.done : FALSE;
}

uint8_t Curl_easy_get_connect_only(const struct Curl_easy *data)
{
  return data ? data->set.connect_only : 0;
}

curl_off_t Curl_easy_get_last_conn_id(const struct Curl_easy *data)
{
  return data ? data->state.last_conn_id : -1;
}

#include "socks.h"

/* Accessor helpers for Zig-ported tftp, socks, and telnet modules */
struct connectdata *Curl_easy_get_conn(struct Curl_easy *data);
curl_socket_t Curl_conn_get_sock(const struct connectdata *conn,
                                 int sockindex);
bool Curl_easy_get_verbose(const struct Curl_easy *data);

bool Curl_tftp_is_upload(const struct Curl_easy *data);
bool Curl_tftp_prefer_ascii(const struct Curl_easy *data);
void Curl_tftp_set_prefer_ascii(struct Curl_easy *data, bool val);
curl_off_t Curl_tftp_infilesize(const struct Curl_easy *data);
char *Curl_tftp_up_path(struct Curl_easy *data);
bool Curl_tftp_no_options(const struct Curl_easy *data);
unsigned int Curl_tftp_blksize(const struct Curl_easy *data);
curl_off_t Curl_tftp_add_writebytecount(struct Curl_easy *data, size_t nbytes);
bool Curl_conn_is_bound(const struct connectdata *conn);
void Curl_conn_set_bound(struct connectdata *conn, bool val);
void Curl_conn_set_transport_wanted(struct connectdata *conn,
                                    uint8_t transport);

uint8_t Curl_socks_get_socks5auth(const struct Curl_easy *data);
bool Curl_socks_is_auth_only(const struct Curl_easy *data);
uint8_t Curl_socks_get_ipver(const struct Curl_easy *data);
void Curl_socks_set_pxcode(struct Curl_easy *data, uint8_t pxcode);
void Curl_conn_set_socks5_authenticated(struct connectdata *conn, bool val);
bool Curl_socks5_has_gssapi(void);
CURLcode Curl_socks5_gssapi_negotiate(struct Curl_cfilter *cf,
                                      struct Curl_easy *data,
                                      struct Curl_creds *creds);
bool Curl_conn_socks5_gssapi_enctype(const struct connectdata *conn);

bool Curl_telnet_has_creds(const struct Curl_easy *data);
const char *Curl_telnet_creds_user(const struct Curl_easy *data);
struct curl_slist *Curl_telnet_get_options(const struct Curl_easy *data);
bool Curl_telnet_is_fread_set(const struct Curl_easy *data);
size_t Curl_telnet_invoke_fread(struct Curl_easy *data,
                                char *buf, size_t size);
int Curl_telnet_get_in_fd(const struct Curl_easy *data);

struct connectdata *Curl_easy_get_conn(struct Curl_easy *data)
{
  return data->conn;
}

curl_socket_t Curl_conn_get_sock(const struct connectdata *conn,
                                 int sockindex)
{
  return conn->sock[sockindex];
}

bool Curl_easy_get_verbose(const struct Curl_easy *data)
{
  return data->set.verbose;
}

bool Curl_tftp_is_upload(const struct Curl_easy *data)
{
  return data->state.upload;
}

bool Curl_tftp_prefer_ascii(const struct Curl_easy *data)
{
  return data->state.prefer_ascii;
}

void Curl_tftp_set_prefer_ascii(struct Curl_easy *data, bool val)
{
  data->state.prefer_ascii = val;
}

curl_off_t Curl_tftp_infilesize(const struct Curl_easy *data)
{
  return data->state.infilesize;
}

char *Curl_tftp_up_path(struct Curl_easy *data)
{
  return data->state.up.path;
}

bool Curl_tftp_no_options(const struct Curl_easy *data)
{
  return data->set.tftp_no_options;
}

unsigned int Curl_tftp_blksize(const struct Curl_easy *data)
{
#ifndef CURL_DISABLE_TFTP
  return data->set.tftp_blksize;
#else
  (void)data;
  return 0;
#endif
}

curl_off_t Curl_tftp_add_writebytecount(struct Curl_easy *data, size_t nbytes)
{
  data->req.writebytecount += nbytes;
  return data->req.writebytecount;
}

bool Curl_conn_is_bound(const struct connectdata *conn)
{
  return conn->bits.bound;
}

void Curl_conn_set_bound(struct connectdata *conn, bool val)
{
  conn->bits.bound = val;
}

void Curl_conn_set_transport_wanted(struct connectdata *conn,
                                    uint8_t transport)
{
  conn->transport_wanted = transport;
}

uint8_t Curl_socks_get_socks5auth(const struct Curl_easy *data)
{
#ifndef CURL_DISABLE_PROXY
  return data->set.socks5auth;
#else
  (void)data;
  return 0;
#endif
}

bool Curl_socks_is_auth_only(const struct Curl_easy *data)
{
  return data->set.socks5_auth_only;
}

uint8_t Curl_socks_get_ipver(const struct Curl_easy *data)
{
  return data->set.ipver;
}

void Curl_socks_set_pxcode(struct Curl_easy *data, uint8_t pxcode)
{
  data->info.pxcode = pxcode;
}

void Curl_conn_set_socks5_authenticated(struct connectdata *conn, bool val)
{
#ifndef CURL_DISABLE_PROXY
  conn->bits.socks5_authenticated = val;
#else
  (void)conn;
  (void)val;
#endif
}

bool Curl_socks5_has_gssapi(void)
{
#if defined(HAVE_GSSAPI) || defined(USE_WINDOWS_SSPI)
  return TRUE;
#else
  return FALSE;
#endif
}

CURLcode Curl_socks5_gssapi_negotiate(struct Curl_cfilter *cf,
                                      struct Curl_easy *data,
                                      struct Curl_creds *creds)
{
#if !defined(CURL_DISABLE_PROXY) && \
  (defined(HAVE_GSSAPI) || defined(USE_WINDOWS_SSPI))
  return Curl_SOCKS5_gssapi_negotiate(cf, data, creds);
#else
  (void)cf;
  (void)data;
  (void)creds;
  return CURLE_NOT_BUILT_IN;
#endif
}

bool Curl_conn_socks5_gssapi_enctype(const struct connectdata *conn)
{
#if defined(HAVE_GSSAPI) || defined(USE_WINDOWS_SSPI)
  return conn->socks5_gssapi_enctype != 0;
#else
  (void)conn;
  return FALSE;
#endif
}

bool Curl_telnet_has_creds(const struct Curl_easy *data)
{
  return data->state.creds != NULL;
}

const char *Curl_telnet_creds_user(const struct Curl_easy *data)
{
  return Curl_creds_user(data->conn->creds);
}

struct curl_slist *Curl_telnet_get_options(const struct Curl_easy *data)
{
#ifndef CURL_DISABLE_TELNET
  return data->set.telnet_options;
#else
  (void)data;
  return NULL;
#endif
}

bool Curl_telnet_is_fread_set(const struct Curl_easy *data)
{
  return data->set.is_fread_set;
}

size_t Curl_telnet_invoke_fread(struct Curl_easy *data,
                                char *buf, size_t size)
{
  return data->state.fread_func(buf, 1, size, data->state.in);
}

int Curl_telnet_get_in_fd(const struct Curl_easy *data)
{
#ifndef USE_WINSOCK
  return fileno((FILE *)data->state.in);
#else
  (void)data;
  return -1;
#endif
}
#ifdef USE_SSL
struct curl_certinfo *Curl_vtls_acc_data_certs(struct Curl_easy *data);
struct curl_certinfo *Curl_vtls_acc_data_certs(struct Curl_easy *data)
{
  return data ? &data->info.certs : NULL;
}

struct connectdata *Curl_vtls_acc_data_conn(struct Curl_easy *data);
struct connectdata *Curl_vtls_acc_data_conn(struct Curl_easy *data)
{
  return data ? data->conn : NULL;
}

struct Curl_cfilter *Curl_vtls_acc_conn_cfilter(struct connectdata *conn,
                                                int8_t sockindex);
struct Curl_cfilter *Curl_vtls_acc_conn_cfilter(struct connectdata *conn,
                                                int8_t sockindex)
{
  return (conn && sockindex >= 0 && sockindex < 2) ?
    conn->cfilter[sockindex] : NULL;
}

struct ssl_easy_config *
Curl_vtls_acc_data_ssl_easy_config(struct Curl_easy *data, bool is_proxy);
struct ssl_easy_config *
Curl_vtls_acc_data_ssl_easy_config(struct Curl_easy *data, bool is_proxy)
{
  if(!data)
    return NULL;
#ifndef CURL_DISABLE_PROXY
  if(is_proxy)
    return &data->set.proxy_ssl;
#else
  (void)is_proxy;
#endif
  return &data->set.ssl;
}

struct ssl_filter_config *
Curl_vtls_acc_conn_ssl_filter_config(struct connectdata *conn, bool is_proxy);
struct ssl_filter_config *
Curl_vtls_acc_conn_ssl_filter_config(struct connectdata *conn, bool is_proxy)
{
  if(!conn)
    return NULL;
#ifndef CURL_DISABLE_PROXY
  if(is_proxy)
    return &conn->proxy_ssl_config;
#else
  (void)is_proxy;
#endif
  return &conn->ssl_config;
}

struct Curl_peer *Curl_vtls_acc_conn_via_peer(struct connectdata *conn,
                                              int8_t sockindex);
struct Curl_peer *Curl_vtls_acc_conn_via_peer(struct connectdata *conn,
                                              int8_t sockindex)
{
  if(!conn)
    return NULL;
#ifndef CURL_DISABLE_PROXY
  return (sockindex == SECONDARYSOCKET) ? conn->via_peer2 : conn->via_peer;
#else
  (void)sockindex;
  return NULL;
#endif
}

void Curl_vtls_acc_conn_set_httpversion_seen(struct connectdata *conn,
                                             unsigned char ver);
void Curl_vtls_acc_conn_set_httpversion_seen(struct connectdata *conn,
                                             unsigned char ver)
{
  if(conn)
    conn->httpversion_seen = ver;
}

void Curl_vtls_acc_conn_set_multiplex(struct connectdata *conn, bool val);
void Curl_vtls_acc_conn_set_multiplex(struct connectdata *conn, bool val)
{
  if(conn)
    conn->bits.multiplex = val;
}

void Curl_vtls_acc_cf_ssl_create_params(struct Curl_easy *data,
                                        struct connectdata *conn,
                                        uint8_t *wanted,
                                        uint8_t *preferred,
                                        bool *only_http_10,
                                        bool *use_alpn);
void Curl_vtls_acc_cf_ssl_create_params(struct Curl_easy *data,
                                        struct connectdata *conn,
                                        uint8_t *wanted,
                                        uint8_t *preferred,
                                        bool *only_http_10,
                                        bool *use_alpn)
{
#ifndef CURL_DISABLE_HTTP
  *wanted = data ? data->state.http_neg.wanted : 0;
  *preferred = data ? data->state.http_neg.preferred : 0;
  *only_http_10 = data ? (bool)data->state.http_neg.only_10 : FALSE;
  *use_alpn = conn ? (bool)conn->bits.tls_enable_alpn : FALSE;
#else
  (void)data;
  (void)conn;
  *wanted = 0;
  *preferred = 0;
  *only_http_10 = FALSE;
  *use_alpn = FALSE;
#endif
}

void Curl_vtls_acc_cf_proxy_create_params(struct Curl_easy *data,
                                          struct connectdata *conn,
                                          uint8_t *wanted,
                                          bool *use_alpn);
void Curl_vtls_acc_cf_proxy_create_params(struct Curl_easy *data,
                                          struct connectdata *conn,
                                          uint8_t *wanted,
                                          bool *use_alpn)
{
  bool alpn = data ? (bool)data->set.ssl_enable_alpn : FALSE;
  http_majors w = CURL_HTTP_V1x;
#if !defined(CURL_DISABLE_PROXY) && defined(USE_HTTP2)
  if(conn && conn->http_proxy.proxytype == CURLPROXY_HTTPS2) {
    alpn = TRUE;
    w = (CURL_HTTP_V1x | CURL_HTTP_V2x);
  }
#else
  (void)conn;
#endif
  *wanted = w;
  *use_alpn = alpn;
}

void *Curl_vtls_acc_conn_get_ssl_context(struct connectdata *conn);
void *Curl_vtls_acc_conn_get_ssl_context(struct connectdata *conn)
{
#ifdef USE_WINDOWS_SSPI
  return conn ? conn->sslContext : NULL;
#else
  (void)conn;
  return NULL;
#endif
}

void Curl_vtls_acc_conn_set_ssl_context(struct connectdata *conn, void *ctx);
void Curl_vtls_acc_conn_set_ssl_context(struct connectdata *conn, void *ctx)
{
#ifdef USE_WINDOWS_SSPI
  if(conn)
    conn->sslContext = ctx;
#else
  (void)conn;
  (void)ctx;
#endif
}

struct Curl_hash *Curl_vtls_acc_multi_proto_hash(struct Curl_easy *data);
struct Curl_hash *Curl_vtls_acc_multi_proto_hash(struct Curl_easy *data)
{
  return (data && data->multi) ? &data->multi->proto_hash : NULL;
}

void Curl_vtls_acc_scache_params(struct Curl_easy *data,
                                 struct Curl_ssl_scache **pscache,
                                 bool *has_share_scache,
                                 struct curl_trc_feat **ptrc_feat);
void Curl_vtls_acc_scache_params(struct Curl_easy *data,
                                 struct Curl_ssl_scache **pscache,
                                 bool *has_share_scache,
                                 struct curl_trc_feat **ptrc_feat)
{
  *pscache = (data && data->share && data->share->ssl_scache) ?
    data->share->ssl_scache :
    ((data && data->multi) ? data->multi->ssl_scache : NULL);
  *has_share_scache =
    (data && CURL_SHARE_ssl_scache(data)) ? TRUE : FALSE;
#ifndef CURL_DISABLE_VERBOSE_STRINGS
  *ptrc_feat = &Curl_trc_feat_ssls;
#else
  *ptrc_feat = NULL;
#endif
}

const char *Curl_vtls_acc_pinned_pubkey(struct Curl_easy *data, bool is_proxy);
const char *Curl_vtls_acc_pinned_pubkey(struct Curl_easy *data, bool is_proxy)
{
  if(!data)
    return NULL;
#ifndef CURL_DISABLE_PROXY
  if(is_proxy)
    return CURL_EASY_STR(data, STRING_SSL_PINNEDPUBLICKEY_PROXY);
#else
  (void)is_proxy;
#endif
  return CURL_EASY_STR(data, STRING_SSL_PINNEDPUBLICKEY);
}

bool Curl_vtls_acc_ssl_certinfo(struct Curl_easy *data);
bool Curl_vtls_acc_ssl_certinfo(struct Curl_easy *data)
{
  return data ? (bool)data->set.ssl.certinfo : FALSE;
}

unsigned char Curl_vtls_acc_ssl_fsslctx(struct Curl_easy *data,
                                        curl_ssl_ctx_callback *pfsslctx,
                                        void **pfsslctxp);
unsigned char Curl_vtls_acc_ssl_fsslctx(struct Curl_easy *data,
                                        curl_ssl_ctx_callback *pfsslctx,
                                        void **pfsslctxp)
{
  if(!data) {
    *pfsslctx = NULL;
    *pfsslctxp = NULL;
    return 0;
  }
  *pfsslctx = data->set.ssl_fsslctx;
  *pfsslctxp = data->set.ssl_fsslctxp;
  return data->set.ssl_fsslctx ? 1 : 0;
}

const char *Curl_vtls_acc_ssl_key_passwd(struct Curl_easy *data,
                                         bool is_proxy);
const char *Curl_vtls_acc_ssl_key_passwd(struct Curl_easy *data,
                                         bool is_proxy)
{
  if(!data)
    return NULL;
#ifndef CURL_DISABLE_PROXY
  if(is_proxy)
    return CURL_EASY_STR(data, STRING_KEY_PASSWD_PROXY);
#else
  (void)is_proxy;
#endif
  return CURL_EASY_STR(data, STRING_KEY_PASSWD);
}

const char *Curl_vtls_acc_ssl_key(struct Curl_easy *data, bool is_proxy);
const char *Curl_vtls_acc_ssl_key(struct Curl_easy *data, bool is_proxy)
{
  if(!data)
    return NULL;
#ifndef CURL_DISABLE_PROXY
  if(is_proxy)
    return CURL_EASY_STR(data, STRING_KEY_PROXY);
#else
  (void)is_proxy;
#endif
  return CURL_EASY_STR(data, STRING_KEY);
}

const char *Curl_vtls_acc_ssl_key_type(struct Curl_easy *data, bool is_proxy);
const char *Curl_vtls_acc_ssl_key_type(struct Curl_easy *data, bool is_proxy)
{
  if(!data)
    return NULL;
#ifndef CURL_DISABLE_PROXY
  if(is_proxy)
    return CURL_EASY_STR(data, STRING_KEY_TYPE_PROXY);
#else
  (void)is_proxy;
#endif
  return CURL_EASY_STR(data, STRING_KEY_TYPE);
}

const char *Curl_vtls_acc_ssl_cert(struct Curl_easy *data, bool is_proxy);
const char *Curl_vtls_acc_ssl_cert(struct Curl_easy *data, bool is_proxy)
{
  if(!data)
    return NULL;
#ifndef CURL_DISABLE_PROXY
  if(is_proxy)
    return CURL_EASY_STR(data, STRING_CERT_PROXY);
#else
  (void)is_proxy;
#endif
  return CURL_EASY_STR(data, STRING_CERT);
}

const char *Curl_vtls_acc_ssl_cert_type(struct Curl_easy *data, bool is_proxy);
const char *Curl_vtls_acc_ssl_cert_type(struct Curl_easy *data, bool is_proxy)
{
  if(!data)
    return NULL;
#ifndef CURL_DISABLE_PROXY
  if(is_proxy)
    return CURL_EASY_STR(data, STRING_CERT_TYPE_PROXY);
#else
  (void)is_proxy;
#endif
  return CURL_EASY_STR(data, STRING_CERT_TYPE);
}

const struct curl_blob *Curl_vtls_acc_ssl_cert_blob(struct Curl_easy *data,
                                                    bool is_proxy);
const struct curl_blob *Curl_vtls_acc_ssl_cert_blob(struct Curl_easy *data,
                                                    bool is_proxy)
{
  if(!data)
    return NULL;
#ifndef CURL_DISABLE_PROXY
  if(is_proxy)
    return data->set.blobs[BLOB_CERT_PROXY];
#else
  (void)is_proxy;
#endif
  return data->set.blobs[BLOB_CERT];
}

const struct curl_blob *Curl_vtls_acc_ssl_ca_info_blob(struct Curl_easy *data,
                                                       bool is_proxy);
const struct curl_blob *Curl_vtls_acc_ssl_ca_info_blob(struct Curl_easy *data,
                                                       bool is_proxy)
{
  if(!data)
    return NULL;
#ifndef CURL_DISABLE_PROXY
  if(is_proxy)
    return data->set.blobs[BLOB_CAINFO_PROXY];
#else
  (void)is_proxy;
#endif
  return data->set.blobs[BLOB_CAINFO];
}

const char *Curl_vtls_acc_ssl_cainfo(struct Curl_easy *data, bool is_proxy);
const char *Curl_vtls_acc_ssl_cainfo(struct Curl_easy *data, bool is_proxy)
{
  if(!data)
    return NULL;
#ifndef CURL_DISABLE_PROXY
  if(is_proxy)
    return CURL_EASY_STR(data, STRING_SSL_CAFILE_PROXY);
#else
  (void)is_proxy;
#endif
  return CURL_EASY_STR(data, STRING_SSL_CAFILE);
}

const char *Curl_vtls_acc_ssl_capath(struct Curl_easy *data, bool is_proxy);
const char *Curl_vtls_acc_ssl_capath(struct Curl_easy *data, bool is_proxy)
{
  if(!data)
    return NULL;
#ifndef CURL_DISABLE_PROXY
  if(is_proxy)
    return CURL_EASY_STR(data, STRING_SSL_CAPATH_PROXY);
#else
  (void)is_proxy;
#endif
  return CURL_EASY_STR(data, STRING_SSL_CAPATH);
}

const char *Curl_vtls_acc_ssl_cipher_list(struct Curl_easy *data,
                                          bool is_proxy);
const char *Curl_vtls_acc_ssl_cipher_list(struct Curl_easy *data,
                                          bool is_proxy)
{
  if(!data)
    return NULL;
#ifndef CURL_DISABLE_PROXY
  if(is_proxy)
    return CURL_EASY_STR(data, STRING_SSL_CIPHER_LIST_PROXY);
#else
  (void)is_proxy;
#endif
  return CURL_EASY_STR(data, STRING_SSL_CIPHER_LIST);
}

const char *Curl_vtls_acc_ssl_cipher13_list(struct Curl_easy *data,
                                            bool is_proxy);
const char *Curl_vtls_acc_ssl_cipher13_list(struct Curl_easy *data,
                                            bool is_proxy)
{
  if(!data)
    return NULL;
#ifndef CURL_DISABLE_PROXY
  if(is_proxy)
    return CURL_EASY_STR(data, STRING_SSL_CIPHER13_LIST_PROXY);
#else
  (void)is_proxy;
#endif
  return CURL_EASY_STR(data, STRING_SSL_CIPHER13_LIST);
}

const char *Curl_vtls_acc_ssl_ec_curves(struct Curl_easy *data);
const char *Curl_vtls_acc_ssl_ec_curves(struct Curl_easy *data)
{
  return data ? CURL_EASY_STR(data, STRING_SSL_EC_CURVES) : NULL;
}

const char *Curl_vtls_acc_ssl_signature_algorithms(struct Curl_easy *data);
const char *Curl_vtls_acc_ssl_signature_algorithms(struct Curl_easy *data)
{
  return data ? CURL_EASY_STR(data, STRING_SSL_SIGNATURE_ALGORITHMS) : NULL;
}

const char *Curl_vtls_acc_ssl_crlfile(struct Curl_easy *data, bool is_proxy);
const char *Curl_vtls_acc_ssl_crlfile(struct Curl_easy *data, bool is_proxy)
{
  if(!data)
    return NULL;
#ifndef CURL_DISABLE_PROXY
  if(is_proxy)
    return CURL_EASY_STR(data, STRING_SSL_CRLFILE_PROXY);
#else
  (void)is_proxy;
#endif
  return CURL_EASY_STR(data, STRING_SSL_CRLFILE);
}

const char *Curl_vtls_acc_ssl_issuercert(struct Curl_easy *data,
                                         bool is_proxy);
const char *Curl_vtls_acc_ssl_issuercert(struct Curl_easy *data,
                                         bool is_proxy)
{
  if(!data)
    return NULL;
#ifndef CURL_DISABLE_PROXY
  if(is_proxy)
    return CURL_EASY_STR(data, STRING_SSL_ISSUERCERT_PROXY);
#else
  (void)is_proxy;
#endif
  return CURL_EASY_STR(data, STRING_SSL_ISSUERCERT);
}

const struct curl_blob *Curl_vtls_acc_ssl_issuercert_blob(
  struct Curl_easy *data, bool is_proxy);
const struct curl_blob *Curl_vtls_acc_ssl_issuercert_blob(
  struct Curl_easy *data, bool is_proxy)
{
  if(!data)
    return NULL;
#ifndef CURL_DISABLE_PROXY
  if(is_proxy)
    return data->set.blobs[BLOB_SSL_ISSUERCERT_PROXY];
#else
  (void)is_proxy;
#endif
  return data->set.blobs[BLOB_SSL_ISSUERCERT];
}

const char *Curl_vtls_acc_ssl_username(struct Curl_easy *data, bool is_proxy);
const char *Curl_vtls_acc_ssl_username(struct Curl_easy *data, bool is_proxy)
{
#ifdef USE_TLS_SRP
  if(!data)
    return NULL;
#ifndef CURL_DISABLE_PROXY
  if(is_proxy)
    return CURL_EASY_STR(data, STRING_TLSAUTH_USERNAME_PROXY);
#else
  (void)is_proxy;
#endif
  return CURL_EASY_STR(data, STRING_TLSAUTH_USERNAME);
#else
  (void)data;
  (void)is_proxy;
  return NULL;
#endif
}

const char *Curl_vtls_acc_ssl_password(struct Curl_easy *data, bool is_proxy);
const char *Curl_vtls_acc_ssl_password(struct Curl_easy *data, bool is_proxy)
{
#ifdef USE_TLS_SRP
  if(!data)
    return NULL;
#ifndef CURL_DISABLE_PROXY
  if(is_proxy)
    return CURL_EASY_STR(data, STRING_TLSAUTH_PASSWORD_PROXY);
#else
  (void)is_proxy;
#endif
  return CURL_EASY_STR(data, STRING_TLSAUTH_PASSWORD);
#else
  (void)data;
  (void)is_proxy;
  return NULL;
#endif
}

const char *Curl_vtls_acc_ssl_engine(struct Curl_easy *data);
const char *Curl_vtls_acc_ssl_engine(struct Curl_easy *data)
{
  return data ? CURL_EASY_STR(data, STRING_SSL_ENGINE) : NULL;
}

bool Curl_vtls_acc_ssl_engine_default(struct Curl_easy *data);
bool Curl_vtls_acc_ssl_engine_default(struct Curl_easy *data)
{
  (void)data;
  return FALSE;
}

int Curl_vtls_acc_ssl_buffer_size(struct Curl_easy *data);
int Curl_vtls_acc_ssl_buffer_size(struct Curl_easy *data)
{
  return data ? (int)data->set.buffer_size : 16384;
}

int Curl_vtls_acc_ssl_ca_cache_timeout(struct Curl_easy *data);
int Curl_vtls_acc_ssl_ca_cache_timeout(struct Curl_easy *data)
{
  return data ? data->set.ssl_ca_cache_timeout : 0;
}
#endif /* USE_SSL */

/* Thin struct-field and bitfield accessors for zig/port/url.zig */
uint32_t Curl_zig_url_build_flags(void);
uint32_t Curl_zig_url_build_flags(void)
{
  uint32_t flags = 0;
#ifdef USE_SSL
  flags |= (1u << 0);
#endif
#ifdef USE_NTLM
  flags |= (1u << 1);
#endif
#ifdef USE_SPNEGO
  flags |= (1u << 2);
#endif
#ifdef USE_GSASL
  flags |= (1u << 3);
#endif
#ifdef USE_IPV6
  flags |= (1u << 4);
#endif
#ifdef USE_UNIX_SOCKETS
  flags |= (1u << 5);
#endif
#ifdef USE_HTTP2
  flags |= (1u << 6);
#endif
#ifdef USE_HTTP3
  flags |= (1u << 7);
#endif
#ifdef USE_SSH
  flags |= (1u << 8);
#endif
#if defined(HAVE_GSSAPI) || defined(USE_WINDOWS_SSPI)
  flags |= (1u << 9);
#endif
#ifdef CURL_DISABLE_PROXY
  flags |= (1u << 10);
#endif
#ifdef CURL_DISABLE_HTTP
  flags |= (1u << 11);
#endif
#ifdef CURL_DISABLE_FTP
  flags |= (1u << 12);
#endif
#ifdef CURL_DISABLE_NETRC
  flags |= (1u << 13);
#endif
#ifdef CURL_DISABLE_ALTSVC
  flags |= (1u << 14);
#endif
#ifdef CURL_DISABLE_HSTS
  flags |= (1u << 15);
#endif
#ifdef CURL_DISABLE_DOH
  flags |= (1u << 16);
#endif
#ifdef CURL_DISABLE_COOKIES
  flags |= (1u << 17);
#endif
#ifdef CURL_DISABLE_DIGEST_AUTH
  flags |= (1u << 18);
#endif
#ifdef CURL_DISABLE_RTSP
  flags |= (1u << 19);
#endif
#ifdef CURL_DISABLE_BINDLOCAL
  flags |= (1u << 20);
#endif
#ifdef CURL_DISABLE_VERBOSE_STRINGS
  flags |= (1u << 21);
#endif
#ifdef DEBUGBUILD
  flags |= (1u << 22);
#endif
#if defined(USE_APPLE_SECTRUST) || defined(CURL_CA_NATIVE)
  flags |= (1u << 23);
#endif
#ifdef CURL_DISABLE_FILE
  flags |= (1u << 24);
#endif
#ifdef CURL_DISABLE_FORM_API
  flags |= (1u << 25);
#endif
#ifdef CURL_DISABLE_MIME
  flags |= (1u << 26);
#endif
#ifdef CURL_DISABLE_TELNET
  flags |= (1u << 27);
#endif
#ifdef CURL_DISABLE_SMTP
  flags |= (1u << 28);
#endif
#ifdef CURL_DISABLE_WEBSOCKETS
  flags |= (1u << 29);
#endif
  return flags;
}

void *Curl_zig_url_default_stdout(void);
void *Curl_zig_url_default_stdout(void)
{
  return (void *)stdout;
}

void *Curl_zig_url_default_stdin(void);
void *Curl_zig_url_default_stdin(void)
{
  return (void *)stdin;
}

const char *Curl_zig_url_default_ca_path(void);
const char *Curl_zig_url_default_ca_path(void)
{
  return CURL_ZIG_DEFAULT_CA_PATH;
}

const char *Curl_zig_url_default_ca_bundle(void);
const char *Curl_zig_url_default_ca_bundle(void)
{
  return CURL_ZIG_DEFAULT_CA_BUNDLE;
}

size_t Curl_zig_url_easy_sizeof(void);
size_t Curl_zig_url_easy_sizeof(void)
{
  return sizeof(struct Curl_easy);
}

size_t Curl_zig_url_conn_sizeof(void);
size_t Curl_zig_url_conn_sizeof(void)
{
  return sizeof(struct connectdata);
}

void Curl_zig_url_ssh_conn_keys(const void *sshc,
                                const char **ppriv_key,
                                const char **ppub_key);
void Curl_zig_url_ssh_conn_keys(const void *sshc,
                                const char **ppriv_key,
                                const char **ppub_key)
{
  (void)sshc;
  *ppriv_key = NULL;
  *ppub_key = NULL;
}

struct Curl_easy *Curl_zig_url_multi_admin(const struct Curl_multi *multi);
struct Curl_easy *Curl_zig_url_multi_admin(const struct Curl_multi *multi)
{
  return multi ? multi->admin : NULL;
}

size_t Curl_zig_url_multi_max_total_connections(const struct Curl_multi *multi);
size_t Curl_zig_url_multi_max_total_connections(const struct Curl_multi *multi)
{
  return multi ? multi->max_total_connections : 0;
}

size_t Curl_zig_url_multi_max_host_connections(const struct Curl_multi *multi);
size_t Curl_zig_url_multi_max_host_connections(const struct Curl_multi *multi)
{
  return multi ? multi->max_host_connections : 0;
}

bool Curl_zig_url_data_get_bit(const struct Curl_easy *data, int bit_id);
bool Curl_zig_url_data_get_bit(const struct Curl_easy *data, int bit_id)
{
  switch(bit_id) {
  case 1: return (bool)data->state.internal;
  case 2: return (bool)data->state.rangestringalloc;
  case 3: return (bool)data->state.use_range;
  case 4: return (bool)data->state.this_is_a_follow;
  case 5: return (bool)data->state.allow_port;
#ifndef CURL_DISABLE_FTP
  case 6: return (bool)data->state.wildcardmatch;
#endif
  case 7: return (bool)data->state.done;
  case 8: return (bool)data->req.no_body;
  case 9: return (bool)data->state.authhost.done;
  case 10: return (bool)data->state.authproxy.done;
#ifndef CURL_DISABLE_HTTP
  case 11: return (bool)data->state.http_neg.h2_prior_knowledge;
  case 12: return (bool)data->state.http_neg.only_10;
#endif
  case 13: return (bool)data->progress.hide;
  default: return FALSE;
  }
}

void Curl_zig_url_data_set_bit(struct Curl_easy *data, int bit_id, bool val);
void Curl_zig_url_data_set_bit(struct Curl_easy *data, int bit_id, bool val)
{
  switch(bit_id) {
  case 1: data->state.internal = val; break;
  case 2: data->state.rangestringalloc = val; break;
  case 3: data->state.use_range = val; break;
  case 4: data->state.this_is_a_follow = val; break;
  case 5: data->state.allow_port = val; break;
#ifndef CURL_DISABLE_FTP
  case 6: data->state.wildcardmatch = val; break;
#endif
  case 7: data->state.done = val; break;
  case 8: data->req.no_body = val; break;
  case 9: data->state.authhost.done = val; break;
  case 10: data->state.authproxy.done = val; break;
#ifndef CURL_DISABLE_HTTP
  case 11: data->state.http_neg.h2_prior_knowledge = val; break;
  case 12: data->state.http_neg.only_10 = val; break;
#endif
  case 13: data->progress.hide = val; break;
  default: break;
  }
}

int64_t Curl_zig_url_data_get_i64(const struct Curl_easy *data, int field_id);
int64_t Curl_zig_url_data_get_i64(const struct Curl_easy *data, int field_id)
{
  switch(field_id) {
  case 1: return (int64_t)data->magic;
  case 2: return (int64_t)data->id;
  case 3: return (int64_t)data->mid;
  case 4: return (int64_t)data->master_mid;
  case 5: return (int64_t)data->state.last_conn_id;
  case 6: return (int64_t)data->state.last_cpid;
  case 7: return (int64_t)data->state.resume_from;
  case 8: return (int64_t)data->state.followlocation;
  case 9: return (int64_t)data->state.httpreq;
#if defined(USE_HTTP2) || defined(USE_HTTP3)
  case 10: return (int64_t)data->state.weight;
#endif
  case 11: return (int64_t)data->state.authhost.want;
  case 12: return (int64_t)data->state.authhost.picked;
  case 13: return (int64_t)data->state.authproxy.want;
  case 14: return (int64_t)data->state.authproxy.picked;
#ifndef CURL_DISABLE_HTTP
  case 15: return (int64_t)data->state.http_neg.wanted;
  case 16: return (int64_t)data->state.http_neg.allowed;
  case 17: return (int64_t)data->state.http_neg.preferred;
#endif
  case 18: return (int64_t)data->info.conn_protocol;
  case 19: return (int64_t)data->info.used_proxy;
  default: return 0;
  }
}

void Curl_zig_url_data_set_i64(struct Curl_easy *data, int field_id,
                               int64_t val);
void Curl_zig_url_data_set_i64(struct Curl_easy *data, int field_id,
                               int64_t val)
{
  switch(field_id) {
  case 1: data->magic = (uint32_t)val; break;
  case 2: data->id = (curl_off_t)val; break;
  case 3: data->mid = (uint32_t)val; break;
  case 4: data->master_mid = (uint32_t)val; break;
  case 5: data->state.last_conn_id = (curl_off_t)val; break;
  case 6: data->state.last_cpid = (uint32_t)val; break;
  case 7: data->state.resume_from = (curl_off_t)val; break;
  case 8: data->state.followlocation = (uint32_t)val; break;
  case 9: data->state.httpreq = (unsigned char)val; break;
#if defined(USE_HTTP2) || defined(USE_HTTP3)
  case 10: data->state.weight = (uint8_t)val; break;
#endif
  case 11: data->state.authhost.want = (uint32_t)val; break;
  case 12: data->state.authhost.picked = (uint32_t)val; break;
  case 13: data->state.authproxy.want = (uint32_t)val; break;
  case 14: data->state.authproxy.picked = (uint32_t)val; break;
#ifndef CURL_DISABLE_HTTP
  case 15: data->state.http_neg.wanted = (uint8_t)val; break;
  case 16: data->state.http_neg.allowed = (uint8_t)val; break;
  case 17: data->state.http_neg.preferred = (uint8_t)val; break;
#endif
  case 18: data->info.conn_protocol = (curl_prot_t)val; break;
  case 19: data->info.used_proxy = (unsigned int)val; break;
  default: break;
  }
}

void *Curl_zig_url_data_get_ptr(struct Curl_easy *data, int ptr_id);
void *Curl_zig_url_data_get_ptr(struct Curl_easy *data, int ptr_id)
{
  switch(ptr_id) {
  case 1: return data->multi;
  case 2: return data->multi_easy;
  case 3: return data->conn;
  case 4: return data->state.uh;
  case 5: return data->state.origin;
  case 6: return data->state.initial_origin;
  case 7: return data->state.creds;
  case 8: return data->state.range;
  case 9: return data->state.most_recent_ftp_entrypath;
#ifndef CURL_DISABLE_HTTP
  case 10: return data->state.rangeline;
  case 11: return data->state.http_host;
#endif
#ifndef CURL_DISABLE_DIGEST_AUTH
  case 12: return data->state.envproxy;
#endif
  case 13: return data->info.contenttype;
  case 14: return data->info.wouldredirect;
  case 15: return data->info.effective_url;
  case 16: return (void *)data->info.conn_scheme;
#ifndef CURL_DISABLE_COOKIES
  case 17: return data->req.cookiehost;
#endif
  case 18: return &data->req;
  case 19: return &data->state.up;
  case 20: return &data->state.headerb;
  case 21: return &data->state.netrc;
#ifndef CURL_DISABLE_HTTP
  case 22: return &data->state.httphdrs;
#endif
  case 23: return &data->wildcard;
  case 24: return &data->state.origin;
  case 25: return &data->state.initial_origin;
#ifndef CURL_DISABLE_RTSP
  case 26: return &data->state.rtsp_session_origin;
#endif
  case 27: return &data->state.creds;
  case 28: return &data->meta_hash;
#if !defined(CURL_DISABLE_HTTP) && !defined(CURL_DISABLE_DIGEST_AUTH)
  case 29: return &data->state.digest;
#endif
  case 30: return &data->state.resume_from;
  case 31: return &data->req.maxdownload;
  case 32: return data->set.blobs;
  default: return NULL;
  }
}

void Curl_zig_url_data_set_ptr(struct Curl_easy *data, int ptr_id, void *val);
void Curl_zig_url_data_set_ptr(struct Curl_easy *data, int ptr_id, void *val)
{
  switch(ptr_id) {
  case 1: data->multi = (struct Curl_multi *)val; break;
  case 2: data->multi_easy = (struct Curl_multi *)val; break;
  case 3: data->conn = (struct connectdata *)val; break;
  case 4: data->state.uh = (CURLU *)val; break;
  case 5: data->state.origin = (struct Curl_peer *)val; break;
  case 6: data->state.initial_origin = (struct Curl_peer *)val; break;
  case 7: data->state.creds = (struct Curl_creds *)val; break;
  case 8: data->state.range = (char *)val; break;
  case 9: data->state.most_recent_ftp_entrypath = (char *)val; break;
#ifndef CURL_DISABLE_HTTP
  case 10: data->state.rangeline = (char *)val; break;
  case 11: data->state.http_host = (char *)val; break;
#endif
#ifndef CURL_DISABLE_DIGEST_AUTH
  case 12: data->state.envproxy = (char *)val; break;
#endif
  case 13: data->info.contenttype = (char *)val; break;
  case 14: data->info.wouldredirect = (char *)val; break;
  case 15: data->info.effective_url = (char *)val; break;
  case 16: data->info.conn_scheme = (const char *)val; break;
#ifndef CURL_DISABLE_COOKIES
  case 17: data->req.cookiehost = (char *)val; break;
#endif
  default: break;
  }
}

bool Curl_zig_url_conn_get_bit(const struct connectdata *conn, int bit_id);
bool Curl_zig_url_conn_get_bit(const struct connectdata *conn, int bit_id)
{
  switch(bit_id) {
  case 1: return (bool)conn->bits.connect_only;
#ifndef CURL_DISABLE_PROXY
  case 2: return (bool)conn->bits.origin_is_proxy;
  case 3: return (bool)conn->bits.socks5_authenticated;
#endif
  case 4: return (bool)conn->bits.close;
  case 5: return (bool)conn->bits.reuse;
  case 6: return (bool)conn->bits.altused;
  case 7: return (bool)conn->bits.ipv6;
  case 8: return (bool)conn->bits.do_more;
  case 9: return (bool)conn->bits.protoconnstart;
  case 10: return (bool)conn->bits.retry;
#ifndef CURL_DISABLE_FTP
  case 11: return (bool)conn->bits.ftp_use_epsv;
  case 12: return (bool)conn->bits.ftp_use_eprt;
#endif
  case 13: return (bool)conn->bits.upgrade_in_progress;
  case 14: return (bool)conn->bits.multiplex;
  case 15: return (bool)conn->bits.tcp_fastopen;
  case 16: return (bool)conn->bits.tls_enable_alpn;
  case 17: return (bool)conn->bits.no_reuse;
  case 18: return (bool)conn->bits.shutdown_handler;
  default: return FALSE;
  }
}

void Curl_zig_url_conn_set_bit(struct connectdata *conn, int bit_id, bool val);
void Curl_zig_url_conn_set_bit(struct connectdata *conn, int bit_id, bool val)
{
  switch(bit_id) {
  case 1: conn->bits.connect_only = val; break;
#ifndef CURL_DISABLE_PROXY
  case 2: conn->bits.origin_is_proxy = val; break;
  case 3: conn->bits.socks5_authenticated = val; break;
#endif
  case 4: conn->bits.close = val; break;
  case 5: conn->bits.reuse = val; break;
  case 6: conn->bits.altused = val; break;
  case 7: conn->bits.ipv6 = val; break;
  case 8: conn->bits.do_more = val; break;
  case 9: conn->bits.protoconnstart = val; break;
  case 10: conn->bits.retry = val; break;
#ifndef CURL_DISABLE_FTP
  case 11: conn->bits.ftp_use_epsv = val; break;
  case 12: conn->bits.ftp_use_eprt = val; break;
#endif
  case 13: conn->bits.upgrade_in_progress = val; break;
  case 14: conn->bits.multiplex = val; break;
  case 15: conn->bits.tcp_fastopen = val; break;
  case 16: conn->bits.tls_enable_alpn = val; break;
  case 17: conn->bits.no_reuse = val; break;
  case 18: conn->bits.shutdown_handler = val; break;
  default: break;
  }
}

int64_t Curl_zig_url_conn_get_i64(const struct connectdata *conn, int field_id);
int64_t Curl_zig_url_conn_get_i64(const struct connectdata *conn, int field_id)
{
  switch(field_id) {
  case 1: return (int64_t)conn->connection_id;
  case 2: return (int64_t)conn->cpid;
  case 3: return (int64_t)conn->attached_xfers;
  case 4: return (int64_t)conn->ip_version;
#ifndef CURL_DISABLE_BINDLOCAL
  case 5: return (int64_t)conn->localport;
  case 6: return (int64_t)conn->localportrange;
#endif
  case 7: return (int64_t)conn->httpversion_seen;
#if defined(HAVE_GSSAPI) || defined(USE_WINDOWS_SSPI)
  case 8: return (int64_t)conn->gssapi_delegation;
#endif
#ifdef USE_NTLM
  case 9: return (int64_t)conn->http_ntlm_state;
#ifndef CURL_DISABLE_PROXY
  case 10: return (int64_t)conn->proxy_ntlm_state;
#endif
#endif
#ifdef USE_SPNEGO
  case 11: return (int64_t)conn->http_negotiate_state;
#ifndef CURL_DISABLE_PROXY
  case 12: return (int64_t)conn->proxy_negotiate_state;
#endif
#endif
#ifdef USE_IPV6
  case 13: return (int64_t)conn->scope_id;
#endif
  case 14: return (int64_t)conn->transport_wanted;
  case 15: return (int64_t)conn->recv_idx;
  case 16: return (int64_t)conn->send_idx;
  case 17: return (int64_t)conn->sock[FIRSTSOCKET];
  case 18: return (int64_t)conn->sock[SECONDARYSOCKET];
  case 19: return (int64_t)conn->shutdown.start_ms[FIRSTSOCKET];
  case 20: return (int64_t)conn->shutdown.start_ms[SECONDARYSOCKET];
  default: return 0;
  }
}

void Curl_zig_url_conn_set_i64(struct connectdata *conn, int field_id,
                               int64_t val);
void Curl_zig_url_conn_set_i64(struct connectdata *conn, int field_id,
                               int64_t val)
{
  switch(field_id) {
  case 1: conn->connection_id = (curl_off_t)val; break;
  case 2: conn->cpid = (uint32_t)val; break;
  case 3: conn->attached_xfers = (uint32_t)val; break;
  case 4: conn->ip_version = (uint8_t)val; break;
#ifndef CURL_DISABLE_BINDLOCAL
  case 5: conn->localport = (uint16_t)val; break;
  case 6: conn->localportrange = (uint16_t)val; break;
#endif
  case 7: conn->httpversion_seen = (uint8_t)val; break;
#if defined(HAVE_GSSAPI) || defined(USE_WINDOWS_SSPI)
  case 8: conn->gssapi_delegation = (uint8_t)val; break;
#endif
#ifdef USE_NTLM
  case 9: conn->http_ntlm_state = (curlntlm)val; break;
#ifndef CURL_DISABLE_PROXY
  case 10: conn->proxy_ntlm_state = (curlntlm)val; break;
#endif
#endif
#ifdef USE_SPNEGO
  case 11: conn->http_negotiate_state = (uint8_t)val; break;
#ifndef CURL_DISABLE_PROXY
  case 12: conn->proxy_negotiate_state = (uint8_t)val; break;
#endif
#endif
#ifdef USE_IPV6
  case 13: conn->scope_id = (unsigned int)val; break;
#endif
  case 14: conn->transport_wanted = (uint8_t)val; break;
  case 15: conn->recv_idx = (int8_t)val; break;
  case 16: conn->send_idx = (int8_t)val; break;
  case 17: conn->sock[FIRSTSOCKET] = (curl_socket_t)val; break;
  case 18: conn->sock[SECONDARYSOCKET] = (curl_socket_t)val; break;
  case 19: conn->shutdown.start_ms[FIRSTSOCKET] = (timediff_t)val; break;
  case 20: conn->shutdown.start_ms[SECONDARYSOCKET] = (timediff_t)val; break;
  default: break;
  }
}

void *Curl_zig_url_conn_get_ptr(struct connectdata *conn, int ptr_id);
void *Curl_zig_url_conn_get_ptr(struct connectdata *conn, int ptr_id)
{
  switch(ptr_id) {
  case 1: return (void *)conn->scheme;
  case 2: return conn->origin;
  case 3: return conn->via_peer;
  case 4: return conn->origin2;
  case 5: return conn->via_peer2;
  case 6: return conn->creds;
  case 7: return conn->creds_origin;
  case 8: return conn->destination;
  case 9: return conn->options;
  case 10: return conn->interface_opts;
  case 11: return conn->attached_multi;
  case 12: return conn->closesocket_client;
  case 13: return (void *)(uintptr_t)conn->fclosesocket;
  case 14: return &conn->meta_hash;
  case 15: return &conn->origin;
  case 16: return &conn->via_peer;
  case 17: return &conn->origin2;
  case 18: return &conn->via_peer2;
  case 19: return &conn->creds;
  case 20: return &conn->creds_origin;
#ifndef CURL_DISABLE_PROXY
  case 21: return &conn->http_proxy;
  case 22: return &conn->socks_proxy;
#endif
  case 23: return &conn->ssl_config;
#ifndef CURL_DISABLE_PROXY
  case 24: return &conn->proxy_ssl_config;
#endif
  case 25: return (void *)(uintptr_t)conn->recv[FIRSTSOCKET];
  case 26: return (void *)(uintptr_t)conn->send[FIRSTSOCKET];
  case 27: return (void *)(uintptr_t)conn->recv[SECONDARYSOCKET];
  case 28: return (void *)(uintptr_t)conn->send[SECONDARYSOCKET];
  default: return NULL;
  }
}

void Curl_zig_url_conn_set_ptr(struct connectdata *conn, int ptr_id, void *val);
void Curl_zig_url_conn_set_ptr(struct connectdata *conn, int ptr_id, void *val)
{
  switch(ptr_id) {
  case 1: conn->scheme = (const struct Curl_scheme *)val; break;
  case 2: conn->origin = (struct Curl_peer *)val; break;
  case 3: conn->via_peer = (struct Curl_peer *)val; break;
  case 4: conn->origin2 = (struct Curl_peer *)val; break;
  case 5: conn->via_peer2 = (struct Curl_peer *)val; break;
  case 6: conn->creds = (struct Curl_creds *)val; break;
  case 7: conn->creds_origin = (struct Curl_peer *)val; break;
  case 8: conn->destination = (char *)val; break;
  case 9: conn->options = (char *)val; break;
  case 10: conn->interface_opts = (char *)val; break;
  case 11: conn->attached_multi = (struct Curl_multi *)val; break;
  case 12: conn->closesocket_client = val; break;
  case 13: conn->fclosesocket = (curl_closesocket_callback)(uintptr_t)val; break;
  case 25: conn->recv[FIRSTSOCKET] = (Curl_recv *)(uintptr_t)val; break;
  case 26: conn->send[FIRSTSOCKET] = (Curl_send *)(uintptr_t)val; break;
  case 27: conn->recv[SECONDARYSOCKET] = (Curl_recv *)(uintptr_t)val; break;
  case 28: conn->send[SECONDARYSOCKET] = (Curl_send *)(uintptr_t)val; break;
  default: break;
  }
}

/* Thin struct-field / bitfield accessors for zig/port/multi.zig */

size_t Curl_zig_multi_sizeof(void)
{
  return sizeof(struct Curl_multi);
}

struct curl_multi_ntfy *Curl_zig_multi_ntfy(struct Curl_multi *multi)
{
  return &multi->ntfy;
}

bool Curl_zig_multi_ntfy_has_entries(const struct Curl_multi *multi)
{
  return CURL_MNTFY_HAS_ENTRIES(multi) ? TRUE : FALSE;
}

bool Curl_zig_multi_ntfy_has_cb(const struct Curl_multi *multi)
{
  return multi->ntfy.ntfy_cb != NULL;
}

void Curl_zig_multi_set_ntfy_cb(struct Curl_multi *multi,
                                curl_notify_callback cb)
{
  multi->ntfy.ntfy_cb = cb;
}

void Curl_zig_multi_set_ntfy_cb_data(struct Curl_multi *multi, void *userp)
{
  multi->ntfy.ntfy_cb_data = userp;
}

struct Curl_hash *Curl_zig_multi_proto_hash(struct Curl_multi *multi)
{
  return &multi->proto_hash;
}

struct cpool *Curl_zig_multi_cpool(struct Curl_multi *multi)
{
  return &multi->cpool;
}

struct cshutdn *Curl_zig_multi_cshutdn(struct Curl_multi *multi)
{
  return &multi->cshutdn;
}

struct curl_multi_ev *Curl_zig_multi_ev(struct Curl_multi *multi)
{
  return &multi->ev;
}

struct PslCache *Curl_zig_multi_psl(struct Curl_multi *multi)
{
#ifdef USE_LIBPSL
  return &multi->psl;
#else
  (void)multi;
  return NULL;
#endif
}

struct Curl_ssl_scache *Curl_zig_multi_ssl_scache(struct Curl_multi *multi)
{
#ifdef USE_SSL
  return multi->ssl_scache;
#else
  (void)multi;
  return NULL;
#endif
}

static void zig_ph_freeentry(void *p)
{
  curlx_free(p);
}

void Curl_zig_multi_proto_hash_init(struct Curl_multi *multi)
{
  Curl_hash_init(&multi->proto_hash, 23, CURL_HASH_TYPE_BYTES,
                 zig_ph_freeentry);
}

void Curl_zig_multi_debug_env_init(struct Curl_multi *multi)
{
#ifdef DEBUGBUILD
  const char *p;
  if(getenv("CURL_DEBUG"))
    multi->admin->set.verbose = TRUE;
  p = getenv("CURL_DBG_MAX_TOTAL_CONNECTIONS");
  if(p) {
    curl_off_t l;
    if(!curlx_str_number(&p, &l, UINT32_MAX)) {
      multi->max_total_connections = (uint32_t)l;
    }
  }
#else
  (void)multi;
#endif
}

int Curl_zig_multi_init_optional_fields(struct Curl_multi *multi,
                                        size_t sesssize,
                                        uint32_t xfer_table_size)
{
#ifdef USE_SSL
  if(Curl_ssl_scache_create(sesssize, 2, &multi->ssl_scache))
    return -1;
#else
  (void)sesssize;
#endif
#ifdef USE_WINSOCK
  multi->wsa_event = WSACreateEvent();
  if(multi->wsa_event == WSA_INVALID_EVENT)
    return -1;
#elif defined(ENABLE_WAKEUP)
  if(Curl_wakeup_init(multi->wakeup_pair, TRUE) < 0)
    return -1;
#endif
#ifdef ENABLE_INTERNAL_WAKEUP
  if(Curl_wakeup_init(multi->wakeup_internal, TRUE) < 0)
    return -1;
#endif
  if(Curl_probeipv6(multi))
    return -1;
#ifdef USE_RESOLV_THREADED
#ifndef CURL_XFER_TABLE_SIZE
#define CURL_XFER_TABLE_SIZE 512
#endif
  if(xfer_table_size < CURL_XFER_TABLE_SIZE) {
    if(Curl_async_thrdd_multi_init(multi, 0, 2, 10))
      return -1;
  }
  else {
    if(Curl_async_thrdd_multi_init(multi, 0, 20, 2000))
      return -1;
  }
#else
  (void)xfer_table_size;
#endif
  return 0;
}

void Curl_zig_multi_prepare_admin(struct Curl_multi *multi)
{
  if(multi && multi->admin) {
    multi->admin->state.internal = TRUE;
    multi->admin->multi = multi;
  }
#ifdef USE_WINSOCK
  if(multi)
    multi->wsa_event = WSA_INVALID_EVENT;
#endif
#ifdef ENABLE_WAKEUP
  if(multi) {
    multi->wakeup_pair[0] = CURL_SOCKET_BAD;
    multi->wakeup_pair[1] = CURL_SOCKET_BAD;
  }
#endif
#ifdef ENABLE_INTERNAL_WAKEUP
  if(multi) {
    multi->wakeup_internal[0] = CURL_SOCKET_BAD;
    multi->wakeup_internal[1] = CURL_SOCKET_BAD;
  }
#endif
}

void Curl_zig_multi_trc_created_admin(struct Curl_multi *multi)
{
  if(multi && multi->admin) {
    CURL_TRC_M(multi->admin, "created multi, easy-admin-handle (mid=%u)",
               multi->admin->mid);
  }
}

void Curl_zig_multi_clone_admin_timeouts(struct Curl_multi *multi,
                                         const struct Curl_easy *data)
{
  if(multi && multi->admin && data) {
    multi->admin->set.timeout = data->set.timeout;
    multi->admin->set.server_response_timeout =
      data->set.server_response_timeout;
    multi->admin->set.no_signal = data->set.no_signal;
  }
}

void Curl_zig_multi_destroy_async_thrdd(struct Curl_multi *multi, bool join)
{
#ifdef USE_RESOLV_THREADED
  Curl_async_thrdd_multi_destroy(multi, join);
#else
  (void)multi;
  (void)join;
#endif
}

void Curl_zig_multi_free_optional_fields(struct Curl_multi *multi)
{
#ifdef USE_LIBPSL
  Curl_psl_destroy(&multi->psl);
#endif
#ifdef USE_SSL
  Curl_ssl_scache_destroy(multi->ssl_scache);
#endif
#ifdef USE_WINSOCK
  if(multi->wsa_event != WSA_INVALID_EVENT) {
    WSACloseEvent(multi->wsa_event);
    multi->wsa_event = WSA_INVALID_EVENT;
  }
#elif defined(ENABLE_WAKEUP)
  Curl_wakeup_destroy(multi->wakeup_pair);
#endif
#ifdef ENABLE_INTERNAL_WAKEUP
  Curl_wakeup_destroy(multi->wakeup_internal);
#endif
}

void Curl_zig_multi_warn_debug(struct Curl_multi *multi,
                               struct Curl_easy *data)
{
#ifdef DEBUGBUILD
  if(!multi->warned) {
    infof(data, "WARNING: USING A DEBUG BUILD OF LIBCURL, "
          "DO NOT USE IN PRODUCTION");
    multi->warned = TRUE;
  }
#else
  (void)multi;
  (void)data;
#endif
}

CURLMcode Curl_zig_multi_assess_wakeup(struct Curl_multi *multi)
{
#ifdef ENABLE_INTERNAL_WAKEUP
  if(multi->socket_cb)
    return Curl_multi_ev_assess_xfer(multi, multi->admin);
#else
  (void)multi;
#endif
  return CURLM_OK;
}

CURLcode Curl_zig_multi_pollset_internal_wakeup(struct Curl_easy *data,
                                                struct easy_pollset *ps)
{
#ifdef ENABLE_INTERNAL_WAKEUP
  return Curl_pollset_add_in(data, ps, data->multi->wakeup_internal[0]);
#else
  (void)data;
  (void)ps;
  return CURLE_OK;
#endif
}

void Curl_zig_multi_async_thrdd_before_pollset(struct Curl_multi *multi)
{
#ifdef USE_RESOLV_THREADED
  Curl_async_thrdd_multi_process(multi);
#ifdef ENABLE_INTERNAL_WAKEUP
  (void)Curl_wakeup_consume(multi->wakeup_internal, FALSE);
#endif
#else
  (void)multi;
#endif
}

void Curl_zig_multi_async_thrdd_process(struct Curl_multi *multi)
{
#ifdef USE_RESOLV_THREADED
  Curl_async_thrdd_multi_process(multi);
#else
  (void)multi;
#endif
}

timediff_t Curl_zig_multi_last_expire_offset_us(
  const struct Curl_multi *multi)
{
  return multi->last_expire_offset_us;
}

void Curl_zig_multi_set_last_expire_offset_us(struct Curl_multi *multi,
                                              timediff_t val)
{
  multi->last_expire_offset_us = val;
}

uint32_t Curl_zig_multi_last_pending_mid(const struct Curl_multi *multi)
{
  return multi->last_pending_mid;
}

void Curl_zig_multi_set_last_pending_mid(struct Curl_multi *multi,
                                         uint32_t val)
{
  multi->last_pending_mid = val;
}

uint32_t Curl_zig_multi_max_host_connections(const struct Curl_multi *multi)
{
  return multi->max_host_connections;
}

void Curl_zig_multi_set_max_host_connections(struct Curl_multi *multi,
                                             uint32_t val)
{
  multi->max_host_connections = val;
}

uint32_t Curl_zig_multi_max_total_connections(const struct Curl_multi *multi)
{
  return multi->max_total_connections;
}

void Curl_zig_multi_set_max_total_connections(struct Curl_multi *multi,
                                              uint32_t val)
{
  multi->max_total_connections = val;
}

uint32_t Curl_zig_multi_maxconnects(const struct Curl_multi *multi)
{
  return multi->maxconnects;
}

void Curl_zig_multi_set_maxconnects(struct Curl_multi *multi, uint32_t val)
{
  multi->maxconnects = val;
}

curl_multi_timer_callback
Curl_zig_multi_timer_cb(const struct Curl_multi *multi)
{
  return multi->timer_cb;
}

void Curl_zig_multi_set_timer_cb(struct Curl_multi *multi,
                                 curl_multi_timer_callback cb)
{
  multi->timer_cb = cb;
}

void *Curl_zig_multi_timer_userp(const struct Curl_multi *multi)
{
  return multi->timer_userp;
}

void Curl_zig_multi_set_timer_userp(struct Curl_multi *multi, void *userp)
{
  multi->timer_userp = userp;
}

struct Curl_fixed_buf **Curl_zig_multi_xfer_buf_ptr(struct Curl_multi *multi)
{
  return &multi->xfer_buf;
}

struct Curl_fixed_buf **
Curl_zig_multi_xfer_ulbuf_ptr(struct Curl_multi *multi)
{
  return &multi->xfer_ulbuf;
}

struct Curl_fixed_buf **
Curl_zig_multi_xfer_sockbuf_ptr(struct Curl_multi *multi)
{
  return &multi->xfer_sockbuf;
}

bool Curl_zig_multi_ipv6_works(const struct Curl_multi *multi)
{
  return (bool)multi->ipv6_works;
}

void Curl_zig_multi_set_ipv6_works(struct Curl_multi *multi, bool val)
{
  multi->ipv6_works = val ? TRUE : FALSE;
}

bool Curl_zig_multi_multiplexing(const struct Curl_multi *multi)
{
  return (bool)multi->multiplexing;
}

void Curl_zig_multi_set_multiplexing(struct Curl_multi *multi, bool val)
{
  multi->multiplexing = val ? TRUE : FALSE;
}

bool Curl_zig_multi_recheckstate(const struct Curl_multi *multi)
{
  return (bool)multi->recheckstate;
}

void Curl_zig_multi_set_recheckstate(struct Curl_multi *multi, bool val)
{
  multi->recheckstate = val ? TRUE : FALSE;
}

void Curl_zig_multi_seed_ssl_if_needed(struct Curl_multi *multi,
                                       struct Curl_easy *data)
{
#ifdef USE_OPENSSL
  if(!multi->ssl_seeded) {
    Curl_ssl_random(data, NULL, 0);
    multi->ssl_seeded = TRUE;
  }
#else
  (void)multi;
  (void)data;
#endif
}

bool Curl_zig_multi_dead(const struct Curl_multi *multi)
{
  return (bool)multi->dead;
}

void Curl_zig_multi_set_dead(struct Curl_multi *multi, bool val)
{
  multi->dead = val ? TRUE : FALSE;
}

bool Curl_zig_multi_quick_exit(const struct Curl_multi *multi)
{
  return (bool)multi->quick_exit;
}

void Curl_zig_multi_set_quick_exit(struct Curl_multi *multi, bool val)
{
  multi->quick_exit = val ? TRUE : FALSE;
}

bool Curl_zig_multi_last_timeout_set(const struct Curl_multi *multi)
{
  return (bool)multi->last_timeout_set;
}

void Curl_zig_multi_set_last_timeout_set(struct Curl_multi *multi, bool val)
{
  multi->last_timeout_set = val ? TRUE : FALSE;
}

bool Curl_zig_multi_xfer_buf_borrowed(const struct Curl_multi *multi)
{
  return (bool)multi->xfer_buf_borrowed;
}

void Curl_zig_multi_set_xfer_buf_borrowed(struct Curl_multi *multi, bool val)
{
  multi->xfer_buf_borrowed = val ? TRUE : FALSE;
}

bool Curl_zig_multi_xfer_ulbuf_borrowed(const struct Curl_multi *multi)
{
  return (bool)multi->xfer_ulbuf_borrowed;
}

void Curl_zig_multi_set_xfer_ulbuf_borrowed(struct Curl_multi *multi, bool val)
{
  multi->xfer_ulbuf_borrowed = val ? TRUE : FALSE;
}

bool Curl_zig_multi_xfer_sockbuf_borrowed(const struct Curl_multi *multi)
{
  return (bool)multi->xfer_sockbuf_borrowed;
}

void Curl_zig_multi_set_xfer_sockbuf_borrowed(struct Curl_multi *multi,
                                              bool val)
{
  multi->xfer_sockbuf_borrowed = val ? TRUE : FALSE;
}

CURLMcode Curl_zig_multi_resolve_threads_max_set(struct Curl_multi *multi,
                                                 long val)
{
#ifdef USE_RESOLV_THREADED
  unsigned long uarg = (unsigned long)val;
  if((uarg <= 0) || (uarg > UINT32_MAX))
    return CURLM_BAD_FUNCTION_ARGUMENT;
  else {
    CURLcode result = Curl_async_thrdd_multi_set_props(
      multi, 0, (uint32_t)uarg, 2000);
    switch(result) {
    case CURLE_OK:
      return CURLM_OK;
    case CURLE_BAD_FUNCTION_ARGUMENT:
      return CURLM_BAD_FUNCTION_ARGUMENT;
    case CURLE_OUT_OF_MEMORY:
      return CURLM_OUT_OF_MEMORY;
    default:
      return CURLM_INTERNAL_ERROR;
    }
  }
#else
  (void)multi;
  (void)val;
  return CURLM_OK;
#endif
}

bool Curl_zig_multi_fdset_valid_sock(curl_socket_t s)
{
  return (VALID_SOCK(s) && FDSET_SOCK(s)) ? TRUE : FALSE;
}

void Curl_zig_multi_fdset_add(curl_socket_t s,
                              unsigned char action,
                              fd_set *read_fd_set,
                              fd_set *write_fd_set)
{
  if(action & CURL_POLL_IN)
    FD_SET(s, read_fd_set);
  if(action & CURL_POLL_OUT)
    FD_SET(s, write_fd_set);
}

#ifdef USE_WINSOCK
static void zig_reset_socket_fdwrite(curl_socket_t s)
{
  int t;
  int l = (int)sizeof(t);
  if(!getsockopt(s, SOL_SOCKET, SO_TYPE, (char *)&t, &l) && t == SOCK_STREAM)
    swrite(s, NULL, 0);
}
#endif

CURLMcode Curl_zig_multi_winsock_select(struct Curl_multi *multi,
                                        struct curl_pollfds *cpfds,
                                        unsigned int curl_nfds,
                                        struct curl_waitfd extra_fds[],
                                        unsigned int extra_nfds,
                                        int timeout_ms,
                                        bool extrawait,
                                        int *pnevents)
{
#ifdef USE_WINSOCK
  CURLMcode mresult = CURLM_OK;
  WSANETWORKEVENTS wsa_events;
  int nevents = 0;
  size_t i;

  DEBUGASSERT(multi->wsa_event != WSA_INVALID_EVENT);

  /* Set the WSA events based on the collected pollds */
  for(i = 0; i < cpfds->n; i++) {
    long mask = 0;
    if(cpfds->pfds[i].events & POLLIN)
      mask |= FD_READ | FD_ACCEPT | FD_CLOSE;
    if(cpfds->pfds[i].events & POLLPRI)
      mask |= FD_OOB;
    if(cpfds->pfds[i].events & POLLOUT) {
      mask |= FD_WRITE | FD_CONNECT | FD_CLOSE;
      zig_reset_socket_fdwrite(cpfds->pfds[i].fd);
    }
    if(mask && WSAEventSelect(cpfds->pfds[i].fd, multi->wsa_event, mask)) {
      mresult = CURLM_OUT_OF_MEMORY;
      goto out;
    }
  }

  if(cpfds->n || extrawait) {
    int pollrc = 0;

    if(cpfds->n) {         /* pre-check with Winsock */
      pollrc = Curl_poll(cpfds->pfds, cpfds->n, 0);
      if(pollrc < 0) {
        mresult = CURLM_UNRECOVERABLE_POLL;
        goto out;
      }
      nevents = pollrc;
    }

    if(!nevents) {
      /* now wait... if not ready during the pre-check (pollrc == 0) */
      WSAWaitForMultipleEvents(1, &multi->wsa_event, FALSE, (DWORD)timeout_ms,
                               FALSE);
    }

    /* With Winsock, we have to run the following section unconditionally
       to call WSAEventSelect(fd, event, 0) on all the sockets */
    for(i = 0; i < extra_nfds; i++) {
      unsigned short mask = 0;
      curl_socket_t s = extra_fds[i].fd;

      wsa_events.lNetworkEvents = 0;
      if(WSAEnumNetworkEvents(s, NULL, &wsa_events) == 0) {
        if(wsa_events.lNetworkEvents & (FD_READ | FD_ACCEPT | FD_CLOSE))
          mask |= CURL_WAIT_POLLIN;
        if(wsa_events.lNetworkEvents & (FD_WRITE | FD_CONNECT | FD_CLOSE))
          mask |= CURL_WAIT_POLLOUT;
        if(wsa_events.lNetworkEvents & FD_OOB)
          mask |= CURL_WAIT_POLLPRI;
        if(!pollrc && wsa_events.lNetworkEvents)
          nevents++;
      }
      WSAEventSelect(s, multi->wsa_event, 0);
      if(!pollrc) {
        extra_fds[i].revents = (short)mask;
        continue;
      }
      else {
        unsigned r = (unsigned)cpfds->pfds[curl_nfds + i].revents;
        if(r & POLLIN)
          mask |= CURL_WAIT_POLLIN;
        if(r & POLLOUT)
          mask |= CURL_WAIT_POLLOUT;
        if(r & POLLPRI)
          mask |= CURL_WAIT_POLLPRI;
        extra_fds[i].revents = (short)mask;
      }
    }

    /* Count up all our own sockets that had activity,
       and remove them from the event. */
    for(i = 0; i < curl_nfds; ++i) {
      wsa_events.lNetworkEvents = 0;
      if(WSAEnumNetworkEvents(cpfds->pfds[i].fd, NULL, &wsa_events) == 0) {
        if(!pollrc && wsa_events.lNetworkEvents)
          nevents++;
      }
      WSAEventSelect(cpfds->pfds[i].fd, multi->wsa_event, 0);
    }
    WSAResetEvent(multi->wsa_event);
  }

out:
  *pnevents = nevents;
  return mresult;
#else
  (void)multi;
  (void)cpfds;
  (void)curl_nfds;
  (void)extra_fds;
  (void)extra_nfds;
  (void)timeout_ms;
  (void)extrawait;
  (void)pnevents;
  return CURLM_INTERNAL_ERROR;
#endif
}

curl_socket_t *Curl_zig_multi_wakeup_pair(struct Curl_multi *multi)
{
#if !defined(USE_WINSOCK) && defined(ENABLE_WAKEUP)
  return multi->wakeup_pair;
#else
  (void)multi;
  return NULL;
#endif
}

CURLMcode Curl_zig_multi_wakeup_exec(struct Curl_multi *multi)
{
#ifdef ENABLE_WAKEUP
#ifdef USE_WINSOCK
  if(WSASetEvent(multi->wsa_event))
    return CURLM_OK;
#else
  if(!Curl_wakeup_signal(multi->wakeup_pair))
    return CURLM_OK;
#endif
#else
  (void)multi;
#endif
  return CURLM_WAKEUP_FAILURE;
}

void Curl_zig_multi_wakeup_internal_exec(struct Curl_multi *multi)
{
#ifdef ENABLE_INTERNAL_WAKEUP
  (void)Curl_wakeup_signal(multi->wakeup_internal);
#else
  (void)multi;
#endif
}

struct Curl_share *Curl_zig_easy_share(const struct Curl_easy *data)
{
  return data->share;
}

void Curl_zig_easy_setup_psl(struct Curl_multi *multi, struct Curl_easy *data)
{
#ifdef USE_LIBPSL
  if(data->share && (data->share->specifier & (1 << CURL_LOCK_DATA_PSL)))
    data->psl = &data->share->psl;
  else
    data->psl = &multi->psl;
#else
  (void)multi;
  (void)data;
#endif
}

struct PslCache *Curl_zig_easy_psl(const struct Curl_easy *data)
{
#ifdef USE_LIBPSL
  return data ? data->psl : NULL;
#else
  (void)data;
  return NULL;
#endif
}

void Curl_zig_easy_clear_psl(struct Curl_easy *data)
{
#ifdef USE_LIBPSL
  data->psl = NULL;
#else
  (void)data;
#endif
}

struct Curl_multi *Curl_zig_easy_multi_easy(const struct Curl_easy *data)
{
  return data->multi_easy;
}

void Curl_zig_easy_set_multi_easy(struct Curl_easy *data,
                                  struct Curl_multi *m)
{
  data->multi_easy = m;
}

curl_off_t Curl_zig_easy_id(const struct Curl_easy *data)
{
  return data->id;
}

void Curl_zig_easy_set_id(struct Curl_easy *data, curl_off_t id)
{
  data->id = id;
}

uint32_t Curl_zig_easy_master_mid(const struct Curl_easy *data)
{
  return data->master_mid;
}

multi_sub_xfer_done_cb *
Curl_zig_easy_sub_xfer_done(const struct Curl_easy *data)
{
  return data->sub_xfer_done;
}

struct CURLMsg *Curl_zig_easy_set_msg_done(struct Curl_easy *data,
                                           CURLcode result)
{
  data->msg.msg = CURLMSG_DONE;
  data->msg.easy_handle = data;
  data->msg.data.result = result;
  return &data->msg;
}

struct CURLMsg *Curl_zig_easy_msg_ptr(struct Curl_easy *data)
{
  return &data->msg;
}

struct Curl_tree *Curl_zig_easy_timeouts_splaynode(struct Curl_easy *data)
{
  return &data->state.timeouts.splaynode;
}

uint8_t *Curl_zig_easy_timeouts_first_ptr(struct Curl_easy *data)
{
  return &data->state.timeouts.first;
}

uint8_t *Curl_zig_easy_timeouts_next_ptr(struct Curl_easy *data)
{
  return &data->state.timeouts.next[0];
}

timediff_t *Curl_zig_easy_timeouts_offset_us_ptr(struct Curl_easy *data)
{
  return &data->state.timeouts.offset_us[0];
}

struct store_netrc *Curl_zig_easy_state_netrc(struct Curl_easy *data)
{
  return &data->state.netrc;
}

struct dynbuf *Curl_zig_easy_headerb_ptr(struct Curl_easy *data)
{
  return &data->state.headerb;
}

struct bufref *Curl_zig_easy_url_bufref(struct Curl_easy *data)
{
  return &data->state.url;
}

char *Curl_zig_easy_set_errorbuffer(struct Curl_easy *data)
{
  return data->set.errorbuffer;
}

void Curl_zig_easy_clear_errorbuffer(struct Curl_easy *data)
{
  if(data->set.errorbuffer)
    data->set.errorbuffer[0] = 0;
}

void *Curl_zig_easy_set_postfields(const struct Curl_easy *data)
{
  return data->set.postfields;
}

curl_off_t Curl_zig_easy_set_set_resume_from(const struct Curl_easy *data)
{
  return data->set.set_resume_from;
}

long Curl_zig_easy_set_maxredirs(const struct Curl_easy *data)
{
  return data->set.maxredirs;
}

unsigned char Curl_zig_easy_set_method(const struct Curl_easy *data)
{
  return (unsigned char)data->set.method;
}

timediff_t Curl_zig_easy_set_timeout_ms(const struct Curl_easy *data)
{
  return (timediff_t)data->set.timeout;
}

timediff_t Curl_zig_easy_set_connecttimeout_ms(const struct Curl_easy *data)
{
  return (timediff_t)data->set.connecttimeout;
}

void Curl_zig_easy_clone_admin_timeouts(struct Curl_easy *admin,
                                        const struct Curl_easy *data)
{
  admin->set.timeout = data->set.timeout;
  admin->set.server_response_timeout = data->set.server_response_timeout;
  admin->set.no_signal = data->set.no_signal;
}

unsigned int Curl_zig_easy_set_buffer_size(const struct Curl_easy *data)
{
  return data->set.buffer_size;
}

unsigned int Curl_zig_easy_set_upload_buffer_size(const struct Curl_easy *data)
{
  return data->set.upload_buffer_size;
}

uint32_t Curl_zig_easy_set_maxconnects(const struct Curl_easy *data)
{
  return data->set.maxconnects;
}

bool Curl_zig_easy_set_pipewait(const struct Curl_easy *data)
{
  return (bool)data->set.pipewait;
}

unsigned char Curl_zig_easy_set_connect_only(const struct Curl_easy *data)
{
  return data->set.connect_only;
}

bool Curl_zig_easy_set_reuse_forbid(const struct Curl_easy *data)
{
  return (bool)data->set.reuse_forbid;
}

bool Curl_zig_easy_set_quick_exit(const struct Curl_easy *data)
{
  return (bool)data->set.quick_exit;
}

bool Curl_zig_easy_set_verbose(const struct Curl_easy *data)
{
  return (bool)data->set.verbose;
}

void Curl_zig_easy_sync_list_only(struct Curl_easy *data)
{
#ifdef CURL_LIST_ONLY_PROTOCOL
  data->state.list_only = data->set.list_only;
#else
  (void)data;
#endif
}

bool Curl_zig_easy_state_internal(const struct Curl_easy *data)
{
  return (bool)data->state.internal;
}

bool Curl_zig_easy_state_really_alive(const struct Curl_easy *data)
{
  return (bool)data->state.really_alive;
}

void Curl_zig_easy_set_state_really_alive(struct Curl_easy *data, bool val)
{
  data->state.really_alive = val ? TRUE : FALSE;
}

bool Curl_zig_easy_state_done(const struct Curl_easy *data)
{
  return (bool)data->state.done;
}

void Curl_zig_easy_set_state_done(struct Curl_easy *data, bool val)
{
  data->state.done = val ? TRUE : FALSE;
}

long Curl_zig_easy_state_followlocation(const struct Curl_easy *data)
{
  return data->state.followlocation;
}

void Curl_zig_easy_inc_followlocation(struct Curl_easy *data)
{
  data->state.followlocation++;
}

void Curl_zig_easy_reset_followlocation(struct Curl_easy *data)
{
  data->state.followlocation = 0;
}

int Curl_zig_easy_state_requests(const struct Curl_easy *data)
{
  return data->state.requests;
}

void Curl_zig_easy_inc_requests(struct Curl_easy *data)
{
  data->state.requests++;
}

void Curl_zig_easy_reset_requests(struct Curl_easy *data)
{
  data->state.requests = 0;
}

bool Curl_zig_easy_state_this_is_a_follow(const struct Curl_easy *data)
{
  return (bool)data->state.this_is_a_follow;
}

void Curl_zig_easy_set_this_is_a_follow(struct Curl_easy *data, bool val)
{
  data->state.this_is_a_follow = val ? TRUE : FALSE;
}

bool Curl_zig_easy_state_errorbuf(const struct Curl_easy *data)
{
  return (bool)data->state.errorbuf;
}

void Curl_zig_easy_set_state_errorbuf(struct Curl_easy *data, bool val)
{
  data->state.errorbuf = val ? TRUE : FALSE;
}

bool Curl_zig_easy_state_wildcardmatch(const struct Curl_easy *data)
{
  return (bool)data->state.wildcardmatch;
}

void Curl_zig_easy_set_state_wildcardmatch(struct Curl_easy *data, bool val)
{
  data->state.wildcardmatch = val ? TRUE : FALSE;
}

bool Curl_zig_easy_state_prefer_ascii(const struct Curl_easy *data)
{
  return (bool)data->state.prefer_ascii;
}

void Curl_zig_easy_set_state_prefer_ascii(struct Curl_easy *data, bool val)
{
  data->state.prefer_ascii = val ? TRUE : FALSE;
}

unsigned char Curl_zig_easy_state_httpreq(const struct Curl_easy *data)
{
  return data->state.httpreq;
}

void Curl_zig_easy_set_state_httpreq(struct Curl_easy *data, unsigned char val)
{
  data->state.httpreq = val;
}

void Curl_zig_easy_http_neg_clear_only_10(struct Curl_easy *data)
{
  data->state.http_neg.only_10 = FALSE;
}

bool Curl_zig_easy_http_neg_has_h3(const struct Curl_easy *data)
{
  return (data->state.http_neg.wanted & CURL_HTTP_V3x) != 0;
}

curl_off_t Curl_zig_easy_state_resume_from(const struct Curl_easy *data)
{
  return data->state.resume_from;
}

void Curl_zig_easy_set_state_resume_from(struct Curl_easy *data,
                                         curl_off_t val)
{
  data->state.resume_from = val;
}

curl_off_t Curl_zig_easy_state_infilesize(const struct Curl_easy *data)
{
  return data->state.infilesize;
}

void Curl_zig_easy_set_state_infilesize(struct Curl_easy *data, curl_off_t val)
{
  data->state.infilesize = val;
}

int Curl_zig_easy_state_os_errno(const struct Curl_easy *data)
{
  return data->state.os_errno;
}

void Curl_zig_easy_set_state_os_errno(struct Curl_easy *data, int val)
{
  data->state.os_errno = val;
}

bool Curl_zig_easy_state_authproblem(const struct Curl_easy *data)
{
  return (bool)data->state.authproblem;
}

void Curl_zig_easy_set_state_authproblem(struct Curl_easy *data, bool val)
{
  data->state.authproblem = val ? TRUE : FALSE;
}

unsigned long Curl_zig_easy_state_authhost_picked(const struct Curl_easy *data)
{
  return data->state.authhost.picked;
}

unsigned long
Curl_zig_easy_state_authproxy_picked(const struct Curl_easy *data)
{
  return data->state.authproxy.picked;
}

bool Curl_zig_easy_state_authhost_done(const struct Curl_easy *data)
{
  return (bool)data->state.authhost.done;
}

bool Curl_zig_easy_state_authproxy_done(const struct Curl_easy *data)
{
  return (bool)data->state.authproxy.done;
}

void Curl_zig_easy_reset_last_conn(struct Curl_easy *data)
{
  data->state.last_conn_id = -1;
  data->state.last_cpid = 0;
}

struct SingleRequest *Curl_zig_easy_req_ptr(struct Curl_easy *data)
{
  return &data->req;
}

bool Curl_zig_easy_req_done(const struct Curl_easy *data)
{
  return (bool)data->req.done;
}

void Curl_zig_easy_set_req_chunk(struct Curl_easy *data, bool val)
{
  data->req.chunk = val ? TRUE : FALSE;
}

bool Curl_zig_easy_req_want_send(struct Curl_easy *data)
{
  return CURL_REQ_WANT_SEND(data) ? TRUE : FALSE;
}

char *Curl_zig_easy_req_newurl(const struct Curl_easy *data)
{
  return data->req.newurl;
}

void Curl_zig_easy_clear_req_newurl(struct Curl_easy *data)
{
  data->req.newurl = NULL;
}

void Curl_zig_easy_free_req_newurl(struct Curl_easy *data)
{
  curlx_safefree(data->req.newurl);
}

char *Curl_zig_easy_req_location(const struct Curl_easy *data)
{
  return data->req.location;
}

void Curl_zig_easy_free_req_location(struct Curl_easy *data)
{
  curlx_safefree(data->req.location);
}

curl_off_t Curl_zig_easy_req_size(const struct Curl_easy *data)
{
  return data->req.size;
}

curl_off_t Curl_zig_easy_req_bytecount(const struct Curl_easy *data)
{
  return data->req.bytecount;
}

unsigned int Curl_zig_easy_req_headerbytecount(const struct Curl_easy *data)
{
  return data->req.headerbytecount;
}

unsigned int Curl_zig_easy_req_deductheadercount(const struct Curl_easy *data)
{
  return data->req.deductheadercount;
}

int Curl_zig_easy_info_httpcode(const struct Curl_easy *data)
{
  return data->info.httpcode;
}

void Curl_zig_easy_set_info_httpcode(struct Curl_easy *data, int val)
{
  data->info.httpcode = val;
}

curl_off_t Curl_zig_easy_info_header_size(const struct Curl_easy *data)
{
  return data->info.header_size;
}

void Curl_zig_easy_add_info_header_size(struct Curl_easy *data,
                                        curl_off_t delta)
{
  data->info.header_size += (long)delta;
}

curl_off_t Curl_zig_easy_info_request_size(const struct Curl_easy *data)
{
  return data->info.request_size;
}

void Curl_zig_easy_set_info_request_size(struct Curl_easy *data,
                                         curl_off_t val)
{
  data->info.request_size = val;
}

void Curl_zig_easy_info_wouldredirect_set(struct Curl_easy *data, char *url)
{
  curlx_free(data->info.wouldredirect);
  data->info.wouldredirect = url;
}

void Curl_zig_easy_info_wouldredirect_clear(struct Curl_easy *data)
{
  curlx_safefree(data->info.wouldredirect);
}

bool Curl_zig_easy_info_timecond(const struct Curl_easy *data)
{
  return (bool)data->info.timecond;
}

struct Curl_rlimit *Curl_zig_easy_progress_ul_rlimit(struct Curl_easy *data)
{
  return &data->progress.ul.rlimit;
}

struct Curl_rlimit *Curl_zig_easy_progress_dl_rlimit(struct Curl_easy *data)
{
  return &data->progress.dl.rlimit;
}

struct SingleRequest *Curl_zig_easy_req(struct Curl_easy *data)
{
  return &data->req;
}

void Curl_zig_easy_init_psl(struct Curl_easy *data, struct Curl_multi *multi)
{
  Curl_zig_easy_setup_psl(multi, data);
}

void Curl_zig_easy_clear_psl_if_multi(struct Curl_easy *data,
                                      struct Curl_multi *multi)
{
#ifdef USE_LIBPSL
  if(data->psl == &multi->psl)
    data->psl = NULL;
#else
  (void)data;
  (void)multi;
#endif
}

void Curl_zig_easy_set_master_mid(struct Curl_easy *data, uint32_t mid)
{
  data->master_mid = mid;
}

void Curl_zig_easy_set_state_last_cpid(struct Curl_easy *data, int cpid)
{
  data->state.last_cpid = cpid;
}

curl_off_t Curl_zig_easy_state_last_conn_id(const struct Curl_easy *data)
{
  return data->state.last_conn_id;
}

void Curl_zig_easy_set_state_last_conn_id(struct Curl_easy *data,
                                          curl_off_t id)
{
  data->state.last_conn_id = id;
}

void Curl_zig_easy_set_req_done(struct Curl_easy *data, bool val)
{
  data->req.done = val ? TRUE : FALSE;
}

void Curl_zig_easy_req_set_recv(struct Curl_easy *data)
{
  CURL_REQ_SET_RECV(data);
}

bool Curl_zig_easy_req_want_recv(struct Curl_easy *data)
{
  return Curl_req_want_recv(data) ? TRUE : FALSE;
}

void Curl_zig_easy_clear_req_location(struct Curl_easy *data)
{
  data->req.location = NULL;
}

int Curl_zig_easy_call_fprereq(struct Curl_easy *data, bool *has_fprereq)
{
  if(data->set.fprereq) {
    struct Curl_mapi_guard guard;
    int rc;
    *has_fprereq = TRUE;
    CURL_CBAPI_START(&guard, data, easy_fprereq);
    rc = data->set.fprereq(data->set.prereq_userp,
                           data->info.primary.remote_ip,
                           data->info.primary.local_ip,
                           data->info.primary.remote_port,
                           data->info.primary.local_port);
    CURL_CBAPI_END(&guard);
    return rc;
  }
  *has_fprereq = FALSE;
  return 0;
}

bool Curl_zig_easy_set_connect_only_non_ws(const struct Curl_easy *data)
{
  return (data->set.connect_only && !data->set.connect_only_ws) ? TRUE : FALSE;
}

void Curl_zig_easy_posttransfer_restore_signal(struct Curl_easy *data)
{
#if defined(HAVE_SIGNAL) && defined(SIGPIPE) && !defined(MSG_NOSIGNAL)
  if(!data->set.no_signal)
    signal(SIGPIPE, data->state.prev_signal);
#else
  (void)data;
#endif
}

bool Curl_zig_easy_h2_downgrade_check(struct Curl_easy *data)
{
#ifndef CURL_DISABLE_HTTP
  return Curl_h2_http_1_1_error(data) ? TRUE : FALSE;
#else
  (void)data;
  return FALSE;
#endif
}

void Curl_zig_easy_h2_downgrade_apply(struct Curl_easy *data)
{
#ifndef CURL_DISABLE_HTTP
  data->state.http_neg.wanted = CURL_HTTP_V1x;
  data->state.http_neg.allowed = CURL_HTTP_V1x;
  data->state.errorbuf = FALSE;
#else
  (void)data;
#endif
}

void Curl_zig_multi_consume_internal_wakeup(struct Curl_multi *multi, bool all)
{
#ifdef ENABLE_INTERNAL_WAKEUP
  (void)Curl_wakeup_consume(multi->wakeup_internal, all);
#else
  (void)multi;
  (void)all;
#endif
}

void Curl_zig_multi_consume_wakeup_pair(struct Curl_multi *multi, bool all)
{
#ifdef ENABLE_WAKEUP
  (void)Curl_wakeup_consume(multi->wakeup_pair, all);
#else
  (void)multi;
  (void)all;
#endif
}

bool Curl_zig_easy_wildcard_is_done(const struct Curl_easy *data)
{
#ifndef CURL_DISABLE_FTP
  return (!data->wildcard || data->wildcard->state == CURLWC_DONE);
#else
  (void)data;
  return TRUE;
#endif
}

bool Curl_zig_easy_wildcard_is_done_or_skip(const struct Curl_easy *data)
{
#ifndef CURL_DISABLE_FTP
  return (data->wildcard &&
          (data->wildcard->state == CURLWC_DONE ||
           data->wildcard->state == CURLWC_SKIP));
#else
  (void)data;
  return FALSE;
#endif
}

void Curl_zig_easy_wildcard_set_done(struct Curl_easy *data)
{
#ifndef CURL_DISABLE_FTP
  if(data->wildcard)
    data->wildcard->state = CURLWC_DONE;
#else
  (void)data;
#endif
}

void Curl_zig_easy_wildcard_dtor(struct Curl_easy *data)
{
#ifndef CURL_DISABLE_FTP
  Curl_wildcard_dtor(&data->wildcard);
#else
  (void)data;
#endif
}

curl_off_t Curl_zig_conn_connection_id(const struct connectdata *conn)
{
  return conn->connection_id;
}

int Curl_zig_conn_cpid(const struct connectdata *conn)
{
  return conn->cpid;
}

curl_socket_t Curl_zig_conn_sock_at(const struct connectdata *conn, int idx)
{
  return conn->sock[idx];
}

int Curl_zig_conn_send_idx(const struct connectdata *conn)
{
  return (int)conn->send_idx;
}

int Curl_zig_conn_recv_idx(const struct connectdata *conn)
{
  return (int)conn->recv_idx;
}

uint32_t Curl_zig_conn_attached_xfers(const struct connectdata *conn)
{
  return conn->attached_xfers;
}

void Curl_zig_conn_inc_attached_xfers(struct connectdata *conn)
{
  DEBUGASSERT(conn->attached_xfers < UINT32_MAX);
  conn->attached_xfers++;
}

void Curl_zig_conn_dec_attached_xfers(struct connectdata *conn)
{
  DEBUGASSERT(conn->attached_xfers > 0);
  conn->attached_xfers--;
}

struct Curl_multi *
Curl_zig_conn_attached_multi(const struct connectdata *conn)
{
  return conn->attached_multi;
}

void Curl_zig_conn_set_attached_multi(struct connectdata *conn,
                                      struct Curl_multi *multi)
{
  conn->attached_multi = multi;
}

bool Curl_zig_conn_bits_close(const struct connectdata *conn)
{
  return (bool)conn->bits.close;
}

void Curl_zig_conn_set_bits_close(struct connectdata *conn, bool val)
{
  conn->bits.close = val ? TRUE : FALSE;
}

bool Curl_zig_conn_bits_reuse(const struct connectdata *conn)
{
  return (bool)conn->bits.reuse;
}

bool Curl_zig_conn_bits_multiplex(const struct connectdata *conn)
{
  return (bool)conn->bits.multiplex;
}

bool Curl_zig_conn_bits_dns_resolved(const struct connectdata *conn)
{
  return (bool)conn->bits.dns_resolved;
}

bool Curl_zig_conn_bits_connect_only(const struct connectdata *conn)
{
  return (bool)conn->bits.connect_only;
}

bool Curl_zig_conn_should_close_reuse_forbid(const struct connectdata *conn)
{
#ifdef USE_NTLM
  if(conn->http_ntlm_state == NTLMSTATE_TYPE2 ||
     conn->proxy_ntlm_state == NTLMSTATE_TYPE2)
    return FALSE;
#endif
#ifdef USE_SPNEGO
  if(conn->http_negotiate_state == CURL_NEGO_AUTH_RECV ||
     conn->proxy_negotiate_state == CURL_NEGO_AUTH_RECV)
    return FALSE;
#endif
  (void)conn;
  return TRUE;
}

bool Curl_zig_conn_bits_do_more(const struct connectdata *conn)
{
  return (bool)conn->bits.do_more;
}

void Curl_zig_conn_set_bits_do_more(struct connectdata *conn, bool val)
{
  conn->bits.do_more = val ? TRUE : FALSE;
}

bool Curl_zig_conn_bits_protoconnstart(const struct connectdata *conn)
{
  return (bool)conn->bits.protoconnstart;
}

void Curl_zig_conn_set_bits_protoconnstart(struct connectdata *conn, bool val)
{
  conn->bits.protoconnstart = val ? TRUE : FALSE;
}

const struct Curl_scheme *Curl_zig_conn_scheme(const struct connectdata *conn)
{
  return conn ? conn->scheme : NULL;
}

curl_prot_t Curl_zig_conn_scheme_protocol(const struct connectdata *conn)
{
  return conn->scheme->protocol;
}

void Curl_zig_conn_run_call_attach(struct Curl_easy *data,
                                   struct connectdata *conn)
{
  if(conn->scheme && conn->scheme->run && conn->scheme->run->attach)
    conn->scheme->run->attach(data, conn);
}

bool Curl_zig_conn_run_has_doing(const struct connectdata *conn)
{
  return conn->scheme && conn->scheme->run && conn->scheme->run->doing != NULL;
}

CURLcode Curl_zig_conn_run_call_doing(struct Curl_easy *data,
                                      bool *dophase_done)
{
  return data->conn->scheme->run->doing(data, dophase_done);
}

bool Curl_zig_conn_run_has_do_it(const struct connectdata *conn)
{
  return conn->scheme && conn->scheme->run && conn->scheme->run->do_it != NULL;
}

CURLcode Curl_zig_conn_run_call_do_it(struct Curl_easy *data, bool *done)
{
  return data->conn->scheme->run->do_it(data, done);
}

bool Curl_zig_conn_run_has_do_more(const struct connectdata *conn)
{
  return conn->scheme && conn->scheme->run &&
         conn->scheme->run->do_more != NULL;
}

CURLcode Curl_zig_conn_run_call_do_more(struct Curl_easy *data, int *complete)
{
  domore dm = DOMORE_INCOMPLETE;
  CURLcode r = data->conn->scheme->run->do_more(data, &dm);
  *complete = (int)dm;
  return r;
}

bool Curl_zig_conn_run_has_done(const struct connectdata *conn)
{
  return conn->scheme && conn->scheme->run && conn->scheme->run->done != NULL;
}

CURLcode Curl_zig_conn_run_call_done(struct Curl_easy *data,
                                     CURLcode status,
                                     bool premature)
{
  return data->conn->scheme->run->done(data, status, premature);
}

bool Curl_zig_conn_run_has_connecting(const struct connectdata *conn)
{
  return conn->scheme && conn->scheme->run &&
         conn->scheme->run->connecting != NULL;
}

CURLcode Curl_zig_conn_run_call_connecting(struct Curl_easy *data, bool *done)
{
  return data->conn->scheme->run->connecting(data, done);
}

bool Curl_zig_conn_run_has_connect_it(const struct connectdata *conn)
{
  return conn->scheme && conn->scheme->run &&
         conn->scheme->run->connect_it != NULL;
}

CURLcode Curl_zig_conn_run_call_connect_it(struct Curl_easy *data, bool *done)
{
  return data->conn->scheme->run->connect_it(data, done);
}

CURLcode Curl_zig_scheme_run_follow(struct Curl_easy *data,
                                    const struct Curl_scheme *handler,
                                    const char *newurl,
                                    int type,
                                    bool *has_follow)
{
  if(handler && handler->run && handler->run->follow) {
    *has_follow = TRUE;
    return handler->run->follow(data, newurl, (followtype)type);
  }
  *has_follow = FALSE;
  return CURLE_OK;
}

bool Curl_zig_conn_run_has_proto_pollset(const struct connectdata *conn)
{
  return conn->scheme && conn->scheme->run &&
         conn->scheme->run->proto_pollset != NULL;
}

CURLcode Curl_zig_conn_run_call_proto_pollset(struct Curl_easy *data,
                                              struct easy_pollset *ps)
{
  return data->conn->scheme->run->proto_pollset(data, ps);
}

bool Curl_zig_conn_run_has_doing_pollset(const struct connectdata *conn)
{
  return conn->scheme && conn->scheme->run &&
         conn->scheme->run->doing_pollset != NULL;
}

CURLcode Curl_zig_conn_run_call_doing_pollset(struct Curl_easy *data,
                                              struct easy_pollset *ps)
{
  return data->conn->scheme->run->doing_pollset(data, ps);
}

bool Curl_zig_conn_run_has_domore_pollset(const struct connectdata *conn)
{
  return conn->scheme && conn->scheme->run &&
         conn->scheme->run->domore_pollset != NULL;
}

CURLcode Curl_zig_conn_run_call_domore_pollset(struct Curl_easy *data,
                                               struct easy_pollset *ps)
{
  return data->conn->scheme->run->domore_pollset(data, ps);
}

bool Curl_zig_conn_run_has_perform_pollset(const struct connectdata *conn)
{
  return conn->scheme && conn->scheme->run &&
         conn->scheme->run->perform_pollset != NULL;
}

CURLcode Curl_zig_conn_run_call_perform_pollset(struct Curl_easy *data,
                                                struct easy_pollset *ps)
{
  return data->conn->scheme->run->perform_pollset(data, ps);
}

void Curl_zig_multi_trc_state(struct Curl_easy *data,
                              CURLMstate oldstate,
                              CURLMstate newstate)
{
  (void)oldstate;
  CURL_TRC_M(data, "-> [%s]", CURL_MSTATE_NAME(newstate));
}

bool Curl_zig_multi_timeouts_check(struct Curl_easy *data)
{
#ifdef DEBUGBUILD
  struct expire_timers *timeouts = &data->state.timeouts;
  uint8_t id;
  int i = 0;
  for(id = timeouts->first; id < EXPIRE_LAST; id = timeouts->next[id]) {
    if(++i >= EXPIRE_LAST) {
      failf(data, "expire timeouts looped: %d iterations and no end", i);
      return FALSE;
    }
    if(id == timeouts->next[id]) {
      failf(data, "expire timeouts wrong: %d points to itself", (int)id);
      return FALSE;
    }
    if((timeouts->next[id] < EXPIRE_LAST) &&
       (timeouts->offset_us[id] > timeouts->offset_us[timeouts->next[id]])) {
      failf(data, "expire timeouts not sorted: %d happens after %d but "
            "is listed before", (int)id, (int)timeouts->next[id]);
      return FALSE;
    }
  }
#else
  (void)data;
#endif
  return TRUE;
}
#ifndef CURL_DISABLE_FTP
extern bool Curl_ftp_listmode_zig(struct Curl_easy *data, bool wildcardmatch,
                                  struct WildcardData *wildcard);

bool Curl_ftp_listmode(struct Curl_easy *data)
{
  return Curl_ftp_listmode_zig(data, (bool)data->state.wildcardmatch,
                               data->wildcard);
}

void Curl_ftp_parselist_get_easy(struct Curl_easy *data,
                                 struct WildcardData **pwc,
                                 curl_fnmatch_callback *pfnmatch,
                                 void **pfnmatch_data)
{
  *pwc = data->wildcard;
  *pfnmatch = data->set.fnmatch;
  *pfnmatch_data = data->set.fnmatch_data;
}
#endif

#include "curl_sasl.h"

extern void Curl_sasl_init_zig(struct SASL *sasl, struct Curl_easy *data,
                               const struct SASLproto *params,
                               uint32_t httpauth);
extern bool Curl_sasl_can_authenticate_zig(struct SASL *sasl,
                                           struct Curl_easy *data,
                                           struct Curl_creds *conn_creds);
extern CURLcode Curl_sasl_start_zig(struct SASL *sasl, struct Curl_easy *data,
                                    bool force_ir, saslprogress *progress,
                                    struct connectdata *conn,
                                    struct Curl_creds *conn_creds,
                                    struct Curl_creds *state_creds,
                                    const char *conn_hostname,
                                    int conn_port,
                                    bool sasl_ir);
extern CURLcode Curl_sasl_continue_zig(struct SASL *sasl,
                                       struct Curl_easy *data,
                                       int code, saslprogress *progress,
                                       struct connectdata *conn,
                                       struct Curl_creds *conn_creds,
                                       struct Curl_creds *state_creds,
                                       const char *conn_hostname,
                                       int conn_port,
                                       const char *origin_hostname,
                                       bool sasl_ir);
extern CURLcode Curl_sasl_is_blocked_zig(struct SASL *sasl,
                                         struct Curl_easy *data,
                                         struct Curl_creds *conn_creds);

void Curl_sasl_init(struct SASL *sasl, struct Curl_easy *data,
                    const struct SASLproto *params)
{
  Curl_sasl_init_zig(sasl, data, params, data->set.httpauth);
}

bool Curl_sasl_can_authenticate(struct SASL *sasl, struct Curl_easy *data)
{
  return Curl_sasl_can_authenticate_zig(sasl, data, data->conn->creds);
}

CURLcode Curl_sasl_start(struct SASL *sasl, struct Curl_easy *data,
                         bool force_ir, saslprogress *progress)
{
  return Curl_sasl_start_zig(sasl, data, force_ir, progress,
                             data->conn, data->conn->creds, data->state.creds,
                             data->conn->origin->hostname,
                             data->conn->origin->port,
                             (bool)data->set.sasl_ir);
}

CURLcode Curl_sasl_continue(struct SASL *sasl, struct Curl_easy *data,
                            int code, saslprogress *progress)
{
  return Curl_sasl_continue_zig(sasl, data, code, progress,
                                data->conn, data->conn->creds,
                                data->state.creds,
                                data->conn->origin->hostname,
                                data->conn->origin->port,
                                data->state.origin->hostname,
                                (bool)data->set.sasl_ir);
}

CURLcode Curl_sasl_is_blocked(struct SASL *sasl, struct Curl_easy *data)
{
  return Curl_sasl_is_blocked_zig(sasl, data, data->conn->creds);
}

#ifndef CURL_DISABLE_RTSP
struct connectdata *Curl_rtsp_get_conn(struct Curl_easy *data)
{
  return data->conn;
}

curl_socket_t Curl_rtsp_get_firstsocket(struct Curl_easy *data)
{
  return data->conn->sock[FIRSTSOCKET];
}

void Curl_rtsp_init_cseq(struct Curl_easy *data)
{
  if(data->state.rtsp_next_client_CSeq == 0)
    data->state.rtsp_next_client_CSeq = 1;
  if(data->state.rtsp_next_server_CSeq == 0)
    data->state.rtsp_next_server_CSeq = 1;
}

uint32_t Curl_rtsp_get_next_client_cseq(struct Curl_easy *data)
{
  return data->state.rtsp_next_client_CSeq;
}

void Curl_rtsp_inc_next_client_cseq(struct Curl_easy *data)
{
  data->state.rtsp_next_client_CSeq++;
}

void Curl_rtsp_set_cseq_recv(struct Curl_easy *data, uint32_t cseq)
{
  data->state.rtsp_CSeq_recv = cseq;
}

unsigned char Curl_rtsp_get_rtspreq(struct Curl_easy *data)
{
  return data->set.rtspreq;
}

bool Curl_rtsp_get_eos_written(struct Curl_easy *data)
{
  return (bool)data->req.eos_written;
}

void Curl_rtsp_set_no_body(struct Curl_easy *data, bool no_body)
{
  data->req.no_body = no_body;
}

void Curl_rtsp_set_httpreq(struct Curl_easy *data, unsigned char httpreq)
{
  data->state.httpreq = httpreq;
}

void Curl_rtsp_get_body_info(struct Curl_easy *data,
                             bool *pupload,
                             curl_off_t *pinfilesize,
                             void **ppostfields,
                             curl_off_t *ppostfieldsize,
                             bool *pcrlf)
{
  *pupload = (bool)data->state.upload;
  *pinfilesize = data->state.infilesize;
  *ppostfields = data->set.postfields;
  *ppostfieldsize = data->set.postfieldsize;
  *pcrlf = (bool)data->set.crlf;
}

void Curl_rtsp_get_request_info(struct Curl_easy *data,
                                const char **psession_id,
                                const char **pstream_uri,
                                const char **ptransport,
                                const char **pencoding,
                                const char **puseragent,
                                const char **preferer,
                                bool *puse_range,
                                const char **prange,
                                char ***prangeline)
{
  *psession_id = CURL_EASY_STR(data, STRING_RTSP_SESSION_ID);
  *pstream_uri = CURL_EASY_STR(data, STRING_RTSP_STREAM_URI);
  *ptransport = CURL_EASY_STR(data, STRING_RTSP_TRANSPORT);
  *pencoding = CURL_EASY_STR(data, STRING_ENCODING);
  *puseragent = CURL_EASY_STR(data, STRING_USERAGENT);
  *preferer = Curl_bufref_ptr(&data->state.referer);
  *puse_range = (bool)data->state.use_range;
  *prange = data->state.range;
  *prangeline = &data->state.rangeline;
}

void Curl_rtsp_get_auth_headers(struct Curl_easy *data,
                                const char **phd_proxy_auth,
                                const char **phd_auth)
{
#ifndef CURL_DISABLE_PROXY
  *phd_proxy_auth = data->req.hd_proxy_auth;
#else
  *phd_proxy_auth = NULL;
#endif
  *phd_auth = data->req.hd_auth;
}

bool Curl_rtsp_allow_session_to_host(struct Curl_easy *data)
{
  if(data->state.rtsp_session_origin &&
     !data->set.allow_auth_to_other_hosts &&
     !Curl_peer_equal(data->state.origin, data->state.rtsp_session_origin))
    return FALSE;
  return TRUE;
}

curl_off_t Curl_rtsp_get_writebytecount(struct Curl_easy *data)
{
  return data->req.writebytecount;
}

void Curl_rtsp_get_req_state(struct Curl_easy *data,
                             int *pheaderline,
                             bool *pheader,
                             curl_off_t *psize,
                             curl_off_t *pbytecount,
                             bool *pdone)
{
  *pheaderline = data->req.headerline;
  *pheader = (bool)data->req.header;
  *psize = data->req.size;
  *pbytecount = data->req.bytecount;
  *pdone = (bool)data->req.done;
}

void Curl_rtsp_set_req_size_zero_done(struct Curl_easy *data)
{
  data->req.size = 0;
  data->req.download_done = TRUE;
}

void Curl_rtsp_set_download_done(struct Curl_easy *data)
{
  data->req.download_done = TRUE;
}

void Curl_rtsp_set_req_done_false(struct Curl_easy *data)
{
  data->req.done = FALSE;
}

void Curl_rtsp_get_rtp_writer(struct Curl_easy *data,
                              curl_write_callback *pwriteit,
                              void **puser_ptr)
{
  if(data->set.fwrite_rtp) {
    *pwriteit = data->set.fwrite_rtp;
    *puser_ptr = data->set.rtp_out;
  }
  else {
    *pwriteit = data->set.fwrite_func;
    *puser_ptr = data->set.out;
  }
}

unsigned char *Curl_rtsp_get_rtp_channel_mask(struct Curl_easy *data)
{
  return data->state.rtp_channel_mask;
}

const char *Curl_rtsp_get_session_id(struct Curl_easy *data)
{
  return CURL_EASY_STR(data, STRING_RTSP_SESSION_ID);
}

CURLcode Curl_rtsp_set_session_id(struct Curl_easy *data, char *mem)
{
  if(CURL_EASY_STR_SETN(data, STRING_RTSP_SESSION_ID, mem))
    return CURLE_OUT_OF_MEMORY;
  Curl_peer_link(&data->state.rtsp_session_origin, data->state.origin);
  return CURLE_OK;
}
#endif /* CURL_DISABLE_RTSP */

#if !defined(CURL_DISABLE_PROXY) || !defined(CURL_DISABLE_HTTP)
#include "urldata.h"
#include "request.h"
#include "vauth/vauth.h"
#include "strcase.h"
#include "curlx/strdup.h"

struct Curl_peer *Curl_proxy_get_origin(struct Curl_easy *data);
const char *Curl_proxy_str_noproxy(struct Curl_easy *data);
const char *Curl_proxy_str_proxy(struct Curl_easy *data);
const char *Curl_proxy_str_pre_proxy(struct Curl_easy *data);
const char *Curl_proxy_str_proxy_service_name(struct Curl_easy *data);
const char *Curl_proxy_str_proxyusername(struct Curl_easy *data);
const char *Curl_proxy_str_proxypassword(struct Curl_easy *data);
const char *Curl_proxy_str_useragent(struct Curl_easy *data);
uint8_t Curl_proxy_get_set_proxytype(struct Curl_easy *data);
uint16_t Curl_proxy_get_set_proxyport(struct Curl_easy *data);
bool Curl_proxy_get_tunnel_thru_httpproxy(struct Curl_easy *data);
void Curl_proxy_update_envproxy(struct Curl_easy *data, const char *proxy);
void Curl_proxy_conn_set_origin_is_proxy(struct connectdata *conn, bool val);
const struct Curl_scheme *Curl_proxy_conn_get_scheme(struct connectdata *conn);
void Curl_proxy_conn_set_scheme(struct connectdata *conn,
                                const struct Curl_scheme *scheme);
struct proxy_info *Curl_proxy_conn_get_socks_proxy(struct connectdata *conn);
struct proxy_info *Curl_proxy_conn_get_http_proxy(struct connectdata *conn);
struct Curl_peer **Curl_proxy_conn_get_via_peer_ptr(struct connectdata *conn);
struct Curl_peer **Curl_proxy_conn_get_origin_ptr(struct connectdata *conn);
bool Curl_proxy_data_origin_is_proxy(struct Curl_easy *data);
bool Curl_proxy_get_sep_headers(struct Curl_easy *data);
struct curl_slist *Curl_proxy_get_headers(struct Curl_easy *data);
struct curl_slist *Curl_proxy_get_proxyheaders(struct Curl_easy *data);
const char *Curl_proxy_get_http_host(struct Curl_easy *data);
uint8_t Curl_proxy_get_httpreq(struct Curl_easy *data);
bool Curl_proxy_get_authneg(struct Curl_easy *data);
bool Curl_proxy_auth_allowed_to_host(struct Curl_easy *data);
const char *Curl_proxy_get_hd_proxy_auth(struct Curl_easy *data);
void Curl_proxy_clear_hd_proxy_auth(struct Curl_easy *data);
const char *Curl_proxy_get_newurl(struct Curl_easy *data);
bool Curl_proxy_clear_newurl(struct Curl_easy *data);
void Curl_proxy_start_connect_auth(struct Curl_easy *data);
void Curl_proxy_set_info_httpcode(struct Curl_easy *data, int code);
int Curl_proxy_get_httpproxycode(struct Curl_easy *data);
int Curl_proxy_get_req_httpcode(struct Curl_easy *data);
void Curl_proxy_set_proxy_and_req_httpcode(struct Curl_easy *data, int code);
bool Curl_proxy_get_authproblem(struct Curl_easy *data);
bool Curl_proxy_has_avail_auth(struct Curl_easy *data);
void Curl_proxy_req_soft_reset(struct Curl_easy *data);
bool Curl_proxy_conn_is_closed(struct connectdata *conn);
bool Curl_ce_should_skip(struct Curl_easy *data, int is_transfer);
void Curl_ce_set_ignorebody(struct Curl_easy *data);
bool Curl_ce_get_http_transfer_encoding(struct Curl_easy *data);
bool Curl_ce_get_http_ce_skip(struct Curl_easy *data);
bool Curl_ce_get_http_te_skip(struct Curl_easy *data);

struct Curl_peer *Curl_proxy_get_origin(struct Curl_easy *data)
{
  return data->state.origin;
}

const char *Curl_proxy_str_noproxy(struct Curl_easy *data)
{
  return CURL_EASY_STR(data, STRING_NOPROXY);
}

const char *Curl_proxy_str_proxy(struct Curl_easy *data)
{
  return CURL_EASY_STR(data, STRING_PROXY);
}

const char *Curl_proxy_str_pre_proxy(struct Curl_easy *data)
{
  return CURL_EASY_STR(data, STRING_PRE_PROXY);
}

const char *Curl_proxy_str_proxy_service_name(struct Curl_easy *data)
{
  return CURL_EASY_STR(data, STRING_PROXY_SERVICE_NAME);
}

const char *Curl_proxy_str_proxyusername(struct Curl_easy *data)
{
  return CURL_EASY_STR(data, STRING_PROXYUSERNAME);
}

const char *Curl_proxy_str_proxypassword(struct Curl_easy *data)
{
  return CURL_EASY_STR(data, STRING_PROXYPASSWORD);
}

const char *Curl_proxy_str_useragent(struct Curl_easy *data)
{
  return CURL_EASY_STR(data, STRING_USERAGENT);
}

uint8_t Curl_proxy_get_set_proxytype(struct Curl_easy *data)
{
  return data->set.proxytype;
}

uint16_t Curl_proxy_get_set_proxyport(struct Curl_easy *data)
{
  return (uint16_t)data->set.proxyport;
}

bool Curl_proxy_get_tunnel_thru_httpproxy(struct Curl_easy *data)
{
  return (bool)data->set.tunnel_thru_httpproxy;
}

void Curl_proxy_update_envproxy(struct Curl_easy *data, const char *proxy)
{
#ifndef CURL_DISABLE_DIGEST_AUTH
  if(!Curl_safecmp(data->state.envproxy, proxy)) {
    Curl_auth_digest_cleanup(&data->state.proxydigest);
    curlx_free(data->state.envproxy);
    data->state.envproxy = curlx_strdup(proxy);
  }
#else
  (void)data;
  (void)proxy;
#endif
}

void Curl_proxy_conn_set_origin_is_proxy(struct connectdata *conn, bool val)
{
  conn->bits.origin_is_proxy = val;
}

const struct Curl_scheme *Curl_proxy_conn_get_scheme(struct connectdata *conn)
{
  return conn->scheme;
}

void Curl_proxy_conn_set_scheme(struct connectdata *conn,
                                const struct Curl_scheme *scheme)
{
  conn->scheme = scheme;
}

struct proxy_info *Curl_proxy_conn_get_socks_proxy(struct connectdata *conn)
{
  return &conn->socks_proxy;
}

struct proxy_info *Curl_proxy_conn_get_http_proxy(struct connectdata *conn)
{
  return &conn->http_proxy;
}

struct Curl_peer **Curl_proxy_conn_get_via_peer_ptr(struct connectdata *conn)
{
  return &conn->via_peer;
}

struct Curl_peer **Curl_proxy_conn_get_origin_ptr(struct connectdata *conn)
{
  return &conn->origin;
}

bool Curl_proxy_data_origin_is_proxy(struct Curl_easy *data)
{
  return (bool)data->conn->bits.origin_is_proxy;
}

bool Curl_proxy_get_sep_headers(struct Curl_easy *data)
{
  return (bool)data->set.sep_headers;
}

struct curl_slist *Curl_proxy_get_headers(struct Curl_easy *data)
{
  return data->set.headers;
}

struct curl_slist *Curl_proxy_get_proxyheaders(struct Curl_easy *data)
{
  return data->set.proxyheaders;
}

const char *Curl_proxy_get_http_host(struct Curl_easy *data)
{
  return data->state.http_host;
}

uint8_t Curl_proxy_get_httpreq(struct Curl_easy *data)
{
  return data->state.httpreq;
}

bool Curl_proxy_get_authneg(struct Curl_easy *data)
{
  return (bool)data->req.authneg;
}

bool Curl_proxy_auth_allowed_to_host(struct Curl_easy *data)
{
  return Curl_auth_allowed_to_host(data);
}

const char *Curl_proxy_get_hd_proxy_auth(struct Curl_easy *data)
{
  return data->req.hd_proxy_auth;
}

void Curl_proxy_clear_hd_proxy_auth(struct Curl_easy *data)
{
  curlx_safefree(data->req.hd_proxy_auth);
}

const char *Curl_proxy_get_newurl(struct Curl_easy *data)
{
  return data->req.newurl;
}

bool Curl_proxy_clear_newurl(struct Curl_easy *data)
{
  if(data->req.newurl) {
    curlx_safefree(data->req.newurl);
    return TRUE;
  }
  return FALSE;
}

void Curl_proxy_start_connect_auth(struct Curl_easy *data)
{
  data->state.authproxy.done = TRUE;
  data->state.authproxy.multipass = FALSE;
}

void Curl_proxy_set_info_httpcode(struct Curl_easy *data, int code)
{
  data->info.httpcode = code;
}

int Curl_proxy_get_httpproxycode(struct Curl_easy *data)
{
  return data->info.httpproxycode;
}

int Curl_proxy_get_req_httpcode(struct Curl_easy *data)
{
  return data->req.httpcode;
}

void Curl_proxy_set_proxy_and_req_httpcode(struct Curl_easy *data, int code)
{
  data->info.httpproxycode = data->req.httpcode = code;
}

bool Curl_proxy_get_authproblem(struct Curl_easy *data)
{
  return (bool)data->state.authproblem;
}

bool Curl_proxy_has_avail_auth(struct Curl_easy *data)
{
  return (bool)(data->set.proxyauth && data->state.authproxy.avail &&
                data->req.hd_proxy_auth);
}

void Curl_proxy_req_soft_reset(struct Curl_easy *data)
{
  Curl_req_soft_reset(&data->req, data);
}

bool Curl_ce_get_http_transfer_encoding(struct Curl_easy *data)
{
  return (bool)data->set.http_transfer_encoding;
}

bool Curl_ce_get_http_ce_skip(struct Curl_easy *data)
{
  return (bool)data->set.http_ce_skip;
}

bool Curl_ce_get_http_te_skip(struct Curl_easy *data)
{
  return (bool)data->set.http_te_skip;
}

bool Curl_proxy_conn_is_closed(struct connectdata *conn)
{
  return (bool)conn->bits.close;
}

bool Curl_ce_should_skip(struct Curl_easy *data, int is_transfer)
{
  return (!is_transfer && data->set.http_ce_skip) ||
         (is_transfer && data->set.http_te_skip);
}

void Curl_ce_set_ignorebody(struct Curl_easy *data)
{
  data->req.ignorebody = TRUE;
}
#endif /* !CURL_DISABLE_PROXY || !CURL_DISABLE_HTTP */

#if !defined(CURL_DISABLE_HTTP) && defined(USE_NGHTTP2)
#include "api.h"
#include "multiif.h"
#include "url.h"
#include "http2.h"

void Curl_h2_trc_bind(struct Curl_easy *data);
curl_off_t Curl_h2_rlimit_per_step(struct Curl_easy *data);
curl_off_t Curl_h2_rlimit_avail(struct Curl_easy *data);
uint32_t Curl_h2_multi_max_concurrent_streams(struct Curl_easy *data);
bool Curl_h2_has_multi(const struct Curl_easy *data);
bool Curl_h2_multi_has_push_cb(const struct Curl_easy *data);
int Curl_h2_call_push_cb(struct Curl_easy *data, struct Curl_easy *newhandle,
                         size_t num_headers, struct curl_pushheaders *headers);
CURLMcode Curl_h2_multi_add_perform(struct Curl_easy *data,
                                    struct Curl_easy *newhandle,
                                    struct connectdata *conn);
void Curl_h2_multi_connchanged(struct Curl_easy *data);
struct Curl_easy *Curl_h2_multi_get_easy(struct Curl_easy *call_data,
                                         uint32_t mid);
uint32_t Curl_h2_easy_mid(const struct Curl_easy *data);
curl_off_t Curl_h2_easy_id(const struct Curl_easy *data);
struct connectdata *Curl_h2_easy_conn(struct Curl_easy *data);
void Curl_h2_connclose(struct connectdata *conn);
bool Curl_h2_conn_is_connect_only(const struct connectdata *conn);
void Curl_h2_conn_set_http20_multiplex(struct connectdata *conn);
uint32_t Curl_h2_conn_attached_xfers(const struct connectdata *conn);
void Curl_h2_duphandle_copy(struct Curl_easy *second, struct Curl_easy *data);
CURLU *Curl_h2_easy_uh(struct Curl_easy *data);
void Curl_h2_set_transfer_url_commit(struct Curl_easy *newhandle,
                                     CURLU *u, char *url);
void Curl_h2_init_pushed_req(struct Curl_easy *newhandle);
bool Curl_h2_req_want_send(const struct Curl_easy *data);
void Curl_h2_get_origin_host_port(const struct Curl_easy *data,
                                  const char **phostname,
                                  int *pport,
                                  int *pdefport);
void Curl_h2_set_upgrade_state(struct Curl_easy *data);
void Curl_h2_set_refused_stream(struct Curl_easy *data);
bool Curl_h2_req_no_body(const struct Curl_easy *data);
curl_off_t Curl_h2_req_bytecount(const struct Curl_easy *data);
void Curl_h2_add_req_bytecount(struct Curl_easy *data, size_t nbytes);
int Curl_h2_set_weight(const struct Curl_easy *data);
int Curl_h2_state_weight(const struct Curl_easy *data);
void Curl_h2_update_state_weight(struct Curl_easy *data, int weight);
const char *Curl_h2_custom_request(struct Curl_easy *data);
unsigned char Curl_h2_state_httpreq(const struct Curl_easy *data);
const char *Curl_h2_state_url_ptr(const struct Curl_easy *data);
bool Curl_h2_may_switch_check(struct Curl_easy *data);
void Curl_h2_set_upgraded_req(struct Curl_easy *data);
void Curl_h2_clear_ignorebody(struct Curl_easy *data);

void Curl_h2_trc_bind(struct Curl_easy *data)
{
  (void)CURL_TRC_BIND(data);
}

curl_off_t Curl_h2_rlimit_per_step(struct Curl_easy *data)
{
  return Curl_rlimit_per_step(&data->progress.dl.rlimit);
}

curl_off_t Curl_h2_rlimit_avail(struct Curl_easy *data)
{
  return Curl_rlimit_avail(&data->progress.dl.rlimit, NULL);
}

uint32_t Curl_h2_multi_max_concurrent_streams(struct Curl_easy *data)
{
  return data->multi ? Curl_multi_max_concurrent_streams(data->multi) : 0;
}

bool Curl_h2_has_multi(const struct Curl_easy *data)
{
  return data && data->multi != NULL;
}

bool Curl_h2_multi_has_push_cb(const struct Curl_easy *data)
{
  return data && data->multi && data->multi->push_cb != NULL;
}

int Curl_h2_call_push_cb(struct Curl_easy *data, struct Curl_easy *newhandle,
                         size_t num_headers, struct curl_pushheaders *headers)
{
  struct Curl_mapi_guard guard;
  int rv;
  CURL_CBAPI_START(&guard, data, multi_push_cb);
  rv = data->multi->push_cb(data, newhandle, num_headers, headers,
                            data->multi->push_userp);
  CURL_CBAPI_END(&guard);
  return rv;
}

CURLMcode Curl_h2_multi_add_perform(struct Curl_easy *data,
                                    struct Curl_easy *newhandle,
                                    struct connectdata *conn)
{
  return Curl_multi_add_perform(data->multi, newhandle, conn);
}

void Curl_h2_multi_connchanged(struct Curl_easy *data)
{
  if(data)
    Curl_multi_connchanged(data->multi);
}

struct Curl_easy *Curl_h2_multi_get_easy(struct Curl_easy *call_data,
                                         uint32_t mid)
{
  if(call_data && call_data->multi)
    return Curl_multi_get_easy(call_data->multi, mid);
  return NULL;
}

uint32_t Curl_h2_easy_mid(const struct Curl_easy *data)
{
  return data ? data->mid : 0;
}

curl_off_t Curl_h2_easy_id(const struct Curl_easy *data)
{
  return data ? data->id : 0;
}

struct connectdata *Curl_h2_easy_conn(struct Curl_easy *data)
{
  return data ? data->conn : NULL;
}

void Curl_h2_connclose(struct connectdata *conn)
{
  connclose(conn);
}

bool Curl_h2_conn_is_connect_only(const struct connectdata *conn)
{
  return conn ? (bool)conn->bits.connect_only : FALSE;
}

void Curl_h2_conn_set_http20_multiplex(struct connectdata *conn)
{
  if(conn) {
    conn->httpversion_seen = 20;
    Curl_conn_set_multiplex(conn);
  }
}

uint32_t Curl_h2_conn_attached_xfers(const struct connectdata *conn)
{
  return conn ? conn->attached_xfers : 0;
}

void Curl_h2_duphandle_copy(struct Curl_easy *second, struct Curl_easy *data)
{
  second->state.weight = data->state.weight;
  if(data->share)
    (void)Curl_share_easy_link(second, data->share);
  second->set.fwrite_func = data->set.fwrite_func;
  second->set.out = data->set.out;
  second->set.fwrite_header = data->set.fwrite_header;
  second->set.writeheader = data->set.writeheader;
  second->set.fdebug = data->set.fdebug;
  second->set.debugdata = data->set.debugdata;
  second->set.fxferinfo = data->set.fxferinfo;
  second->set.fprogress = data->set.fprogress;
  second->set.progress_client = data->set.progress_client;
  second->progress.hide = data->progress.hide;
  second->progress.callback = data->progress.callback;
}

CURLU *Curl_h2_easy_uh(struct Curl_easy *data)
{
  return data->state.uh;
}

void Curl_h2_set_transfer_url_commit(struct Curl_easy *newhandle,
                                     CURLU *u, char *url)
{
  newhandle->state.uh = u;
  Curl_bufref_set(&newhandle->state.url, url, 0, curl_free);
}

void Curl_h2_init_pushed_req(struct Curl_easy *newhandle)
{
  newhandle->req.maxdownload = -1;
  newhandle->req.size = -1;
}

bool Curl_h2_req_want_send(const struct Curl_easy *data)
{
  return CURL_REQ_WANT_SEND(data);
}

void Curl_h2_get_origin_host_port(const struct Curl_easy *data,
                                  const char **phostname,
                                  int *pport,
                                  int *pdefport)
{
  *phostname = data->state.origin->hostname;
  *pport = data->state.origin->port;
  *pdefport = data->state.origin->scheme->defport;
}

void Curl_h2_set_upgrade_state(struct Curl_easy *data)
{
  data->state.http_hd_upgrade = TRUE;
  data->state.http_hd_h2_settings = TRUE;
  data->req.upgr101 = UPGR101_H2;
  data->conn->bits.upgrade_in_progress = TRUE;
}

void Curl_h2_set_refused_stream(struct Curl_easy *data)
{
  data->state.refused_stream = TRUE;
}

bool Curl_h2_req_no_body(const struct Curl_easy *data)
{
  return (bool)data->req.no_body;
}

curl_off_t Curl_h2_req_bytecount(const struct Curl_easy *data)
{
  return data->req.bytecount;
}

void Curl_h2_add_req_bytecount(struct Curl_easy *data, size_t nbytes)
{
  data->req.bytecount += nbytes;
}

int Curl_h2_set_weight(const struct Curl_easy *data)
{
  return data->set.weight;
}

int Curl_h2_state_weight(const struct Curl_easy *data)
{
  return data->state.weight;
}

void Curl_h2_update_state_weight(struct Curl_easy *data, int weight)
{
  data->state.weight = weight;
}

const char *Curl_h2_custom_request(struct Curl_easy *data)
{
  return !data->state.http_ignorecustom ?
    CURL_EASY_STR(data, STRING_CUSTOMREQUEST) : NULL;
}

unsigned char Curl_h2_state_httpreq(const struct Curl_easy *data)
{
  return data->state.httpreq;
}

const char *Curl_h2_state_url_ptr(const struct Curl_easy *data)
{
  return Curl_bufref_ptr(&data->state.url);
}

bool Curl_h2_may_switch_check(struct Curl_easy *data)
{
  if(Curl_conn_http_version(data, data->conn) < 20 &&
     (data->state.http_neg.wanted & CURL_HTTP_V2x) &&
     data->state.http_neg.h2_prior_knowledge) {
#ifndef CURL_DISABLE_PROXY
    if(data->conn->bits.origin_is_proxy) {
      infof(data, "Ignoring HTTP/2 prior knowledge due to proxy");
      return FALSE;
    }
#endif
    return TRUE;
  }
  return FALSE;
}

void Curl_h2_set_upgraded_req(struct Curl_easy *data)
{
  data->req.httpversion_sent = 20;
  data->req.header = TRUE;
  data->req.headerline = 0;
}

void Curl_h2_clear_ignorebody(struct Curl_easy *data)
{
  data->req.ignorebody = FALSE;
}
#endif /* !CURL_DISABLE_HTTP && USE_NGHTTP2 */

#ifndef CURL_DISABLE_FTP
#ifdef HAVE_NETINET_IN_H
#include <netinet/in.h>
#endif
#ifdef HAVE_ARPA_INET_H
#include <arpa/inet.h>
#endif
#ifdef HAVE_NETDB_H
#include <netdb.h>
#endif
#include "sendf.h"
#include "curl_addrinfo.h"
#include "curl_trc.h"
#include "if2ip.h"
#include "progress.h"
#include "transfer.h"
#include "escape.h"
#include "ftp.h"
#include "ftp-int.h"
#include "ftplistparser.h"
#include "curl_range.h"
#include "strcase.h"
#include "vtls/vtls.h"
#include "cfilters.h"
#include "cf-socket.h"
#include "connect.h"
#include "curlx/inet_ntop.h"
#include "curlx/inet_pton.h"
#include "select.h"
#include "parsedate.h"
#include "sockaddr.h"
#include "multiif.h"
#include "url.h"
#include "vdns/hostip.h"
#include "curlx/strdup.h"
#include "curlx/strerr.h"
#include "curlx/strparse.h"
#include "peer.h"
#include "creds.h"
#include "api.h"

void Curl_ftp_acc_trc_bind(struct Curl_easy *data);
struct connectdata *Curl_ftp_acc_get_conn(struct Curl_easy *data);
bool Curl_ftp_acc_pwd_stop_debug(struct Curl_easy *data);
struct WildcardData *Curl_ftp_acc_get_wildcard(struct Curl_easy *data);
bool Curl_ftp_acc_get_wildcardmatch(struct Curl_easy *data);
uint8_t Curl_ftp_acc_get_ftp_filemethod(struct Curl_easy *data);
void Curl_ftp_acc_set_ftp_filemethod(struct Curl_easy *data, uint8_t val);
bool Curl_ftp_acc_get_upload(struct Curl_easy *data);
bool Curl_ftp_acc_get_prefer_ascii(struct Curl_easy *data);
void Curl_ftp_acc_set_prefer_ascii(struct Curl_easy *data, bool val);
bool Curl_ftp_acc_get_list_only(struct Curl_easy *data);
void Curl_ftp_acc_set_list_only(struct Curl_easy *data, bool val);
bool Curl_ftp_acc_get_no_body(struct Curl_easy *data);
curl_off_t Curl_ftp_acc_get_infilesize(struct Curl_easy *data);
void Curl_ftp_acc_set_infilesize(struct Curl_easy *data, curl_off_t val);
curl_off_t Curl_ftp_acc_get_resume_from(struct Curl_easy *data);
void Curl_ftp_acc_set_resume_from(struct Curl_easy *data, curl_off_t val);
curl_off_t Curl_ftp_acc_get_req_size(struct Curl_easy *data);
void Curl_ftp_acc_set_req_size(struct Curl_easy *data, curl_off_t val);
curl_off_t Curl_ftp_acc_get_req_maxdownload(struct Curl_easy *data);
curl_off_t Curl_ftp_acc_get_req_bytecount(struct Curl_easy *data);
curl_off_t Curl_ftp_acc_get_req_writebytecount(struct Curl_easy *data);
curl_off_t Curl_ftp_acc_get_max_filesize(struct Curl_easy *data);
bool Curl_ftp_acc_get_ignorecl(struct Curl_easy *data);
bool Curl_ftp_acc_get_crlf(struct Curl_easy *data);
bool Curl_ftp_acc_get_remote_append(struct Curl_easy *data);
bool Curl_ftp_acc_get_ftp_use_port(struct Curl_easy *data);
bool Curl_ftp_acc_get_ftp_use_pret(struct Curl_easy *data);
bool Curl_ftp_acc_get_ftp_skip_ip(struct Curl_easy *data);
uint8_t Curl_ftp_acc_get_ftp_create_missing_dirs(struct Curl_easy *data);
uint8_t Curl_ftp_acc_get_use_ssl(struct Curl_easy *data);
uint8_t Curl_ftp_acc_get_ftpsslauth(struct Curl_easy *data);
uint8_t Curl_ftp_acc_get_ftp_ccc(struct Curl_easy *data);
timediff_t Curl_ftp_acc_get_accepttimeout(struct Curl_easy *data);
bool Curl_ftp_acc_get_get_filetime(struct Curl_easy *data);
uint8_t Curl_ftp_acc_get_timecondition(struct Curl_easy *data);
curl_off_t Curl_ftp_acc_get_timevalue(struct Curl_easy *data);
curl_off_t Curl_ftp_acc_get_info_filetime(struct Curl_easy *data);
time_t *Curl_ftp_acc_get_info_filetime_ptr(struct Curl_easy *data);
void Curl_ftp_acc_set_info_timecond(struct Curl_easy *data, bool val);
void Curl_ftp_acc_set_info_httpcode(struct Curl_easy *data, int code);
void Curl_ftp_acc_clear_state_errorbuf(struct Curl_easy *data);
CURLcode Curl_ftp_acc_set_most_recent_ftp_entrypath(struct Curl_easy *data,
                                                    const char *entrypath);
char *Curl_ftp_acc_get_up_path_after_slash(struct Curl_easy *data);
struct curl_slist *Curl_ftp_acc_get_quote(struct Curl_easy *data);
struct curl_slist *Curl_ftp_acc_get_prequote(struct Curl_easy *data);
struct curl_slist *Curl_ftp_acc_get_postquote(struct Curl_easy *data);
const char *Curl_ftp_acc_get_str_ftpport(struct Curl_easy *data);
const char *Curl_ftp_acc_get_str_customrequest(struct Curl_easy *data);
const char *Curl_ftp_acc_get_str_ftp_account(struct Curl_easy *data);
const char *Curl_ftp_acc_get_str_ftp_alternative_to_user(
  struct Curl_easy *data);
CURLcode Curl_ftp_acc_client_write_header(struct Curl_easy *data,
                                          char *buf, size_t blen);
curl_socket_t Curl_ftp_acc_conn_get_sock(struct connectdata *conn, int idx);
bool Curl_ftp_acc_conn_has_cfilter(struct connectdata *conn, int idx);
bool Curl_ftp_acc_conn_get_reuse(struct connectdata *conn);
bool Curl_ftp_acc_conn_get_ipv6(struct connectdata *conn);
bool Curl_ftp_acc_conn_get_ftp_use_eprt(struct connectdata *conn);
void Curl_ftp_acc_conn_set_ftp_use_eprt(struct connectdata *conn, bool val);
bool Curl_ftp_acc_conn_get_ftp_use_epsv(struct connectdata *conn);
void Curl_ftp_acc_conn_set_ftp_use_epsv(struct connectdata *conn, bool val);
bool Curl_ftp_acc_conn_get_ftp_use_data_ssl(struct connectdata *conn);
void Curl_ftp_acc_conn_set_ftp_use_data_ssl(struct connectdata *conn,
                                            bool val);
void Curl_ftp_acc_conn_set_do_more(struct connectdata *conn, bool val);
const char *Curl_ftp_acc_conn_get_origin_hostname(struct connectdata *conn);
unsigned int Curl_ftp_acc_conn_get_scheme_flags(struct connectdata *conn);
const char *Curl_ftp_acc_conn_get_user(struct connectdata *conn);
const char *Curl_ftp_acc_conn_get_passwd(struct connectdata *conn);
bool Curl_ftp_acc_has_seek_func(struct Curl_easy *data);
int Curl_ftp_acc_call_seek_func(struct Curl_easy *data, curl_off_t offset);
size_t Curl_ftp_acc_call_fread_func(struct Curl_easy *data, char *buf,
                                    size_t amount);
bool Curl_ftp_acc_has_chunk_bgn(struct Curl_easy *data);
long Curl_ftp_acc_call_chunk_bgn(struct Curl_easy *data,
                                 const struct curl_fileinfo *finfo,
                                 int remains);
bool Curl_ftp_acc_has_chunk_end(struct Curl_easy *data);
void Curl_ftp_acc_call_chunk_end(struct Curl_easy *data);
int Curl_ftp_acc_get_sockerrno(void);
timediff_t Curl_ftp_acc_pp_state_timeleft_ms(struct Curl_easy *data,
                                             struct pingpong *pp);
CURLcode Curl_ftp_acc_pp_statemach(struct Curl_easy *data,
                                   struct pingpong *pp,
                                   bool block, bool disconnecting);
CURLcode Curl_ftp_acc_pp_readresp(struct Curl_easy *data, int8_t sockindex,
                                  struct pingpong *pp,
                                  int *code, size_t *size);
CURLcode Curl_ftp_acc_pp_pollset(struct Curl_easy *data,
                                 struct pingpong *pp,
                                 struct easy_pollset *ps);
CURLcode Curl_ftp_acc_pollset_add_in(struct Curl_easy *data,
                                     struct easy_pollset *ps,
                                     curl_socket_t sock);
CURLcode Curl_ftp_acc_range(struct Curl_easy *data);
void Curl_ftp_acc_xfer_setup_send(struct Curl_easy *data);
void Curl_ftp_acc_xfer_setup_recv(struct Curl_easy *data, curl_off_t size);
void Curl_ftp_acc_connclose(struct connectdata *conn);
CURLcode Curl_ftp_acc_ssl_cfilter_add(struct Curl_easy *data,
                                      struct connectdata *conn,
                                      int8_t sockindex);
CURLcode Curl_ftp_acc_ssl_cfilter_remove(struct Curl_easy *data,
                                         int8_t sockindex,
                                         bool send_shutdown);
CURLcode Curl_ftp_acc_control_addr_dup(struct Curl_easy *data,
                                       char **newhostp);
CURLcode Curl_ftp_acc_setup_pasv_conn(struct Curl_easy *data,
                                      struct connectdata *conn,
                                      const char *newhost,
                                      unsigned short newport);
bool Curl_ftp_acc_is_ipv6_literal(const char *str);
int Curl_ftp_acc_if2ip(struct Curl_easy *data, struct connectdata *conn,
                       const char *ipstr, char *hbuf, size_t hbuflen);
CURLcode Curl_ftp_acc_port_default_host(struct Curl_easy *data,
                                        struct connectdata *conn,
                                        void *ss_ptr,
                                        unsigned int *sslenp,
                                        char *hbuf, size_t hbuflen);
CURLcode Curl_ftp_acc_port_resolve_host(struct Curl_easy *data,
                                        struct connectdata *conn,
                                        const char *host,
                                        struct Curl_dns_entry **dns_entryp,
                                        const struct Curl_addrinfo **resp);
CURLcode Curl_ftp_acc_port_open_socket(struct Curl_easy *data,
                                       struct connectdata *conn,
                                       const struct Curl_addrinfo *res,
                                       const struct Curl_addrinfo **aip,
                                       curl_socket_t *portsockp);
CURLcode Curl_ftp_acc_port_bind_socket(struct Curl_easy *data,
                                       struct connectdata *conn,
                                       curl_socket_t portsock,
                                       const struct Curl_addrinfo *ai,
                                       void *ss_ptr,
                                       unsigned int *sslen_io,
                                       unsigned short port_min,
                                       unsigned short port_max,
                                       bool non_local,
                                       unsigned short *pbound_port);
CURLcode Curl_ftp_acc_port_listen(struct Curl_easy *data,
                                  curl_socket_t portsock);
void Curl_ftp_acc_port_extract_sa(const void *ss_ptr,
                                  const struct Curl_addrinfo *ai,
                                  char *myhost, size_t myhost_len,
                                  bool *pis_ipv4, bool *pis_ipv6,
                                  unsigned short *pport);

void Curl_ftp_acc_trc_bind(struct Curl_easy *data)
{
  (void)CURL_TRC_BIND(data);
}

struct connectdata *Curl_ftp_acc_get_conn(struct Curl_easy *data)
{
  (void)CURL_TRC_BIND(data);
  return data ? data->conn : NULL;
}

bool Curl_ftp_acc_pwd_stop_debug(struct Curl_easy *data)
{
#ifdef DEBUGBUILD
  if(!data->id && getenv("CURL_FTP_PWD_STOP"))
    return TRUE;
#else
  (void)data;
#endif
  return FALSE;
}

struct WildcardData *Curl_ftp_acc_get_wildcard(struct Curl_easy *data)
{
  return data->wildcard;
}

bool Curl_ftp_acc_get_wildcardmatch(struct Curl_easy *data)
{
  return (bool)data->state.wildcardmatch;
}

uint8_t Curl_ftp_acc_get_ftp_filemethod(struct Curl_easy *data)
{
  return data->set.ftp_filemethod;
}

void Curl_ftp_acc_set_ftp_filemethod(struct Curl_easy *data, uint8_t val)
{
  data->set.ftp_filemethod = val;
}

bool Curl_ftp_acc_get_upload(struct Curl_easy *data)
{
  return (bool)data->state.upload;
}

bool Curl_ftp_acc_get_prefer_ascii(struct Curl_easy *data)
{
  return (bool)data->state.prefer_ascii;
}

void Curl_ftp_acc_set_prefer_ascii(struct Curl_easy *data, bool val)
{
  data->state.prefer_ascii = val;
}

bool Curl_ftp_acc_get_list_only(struct Curl_easy *data)
{
  return (bool)data->state.list_only;
}

void Curl_ftp_acc_set_list_only(struct Curl_easy *data, bool val)
{
  data->state.list_only = val;
}

bool Curl_ftp_acc_get_no_body(struct Curl_easy *data)
{
  return (bool)data->req.no_body;
}

curl_off_t Curl_ftp_acc_get_infilesize(struct Curl_easy *data)
{
  return data->state.infilesize;
}

void Curl_ftp_acc_set_infilesize(struct Curl_easy *data, curl_off_t val)
{
  data->state.infilesize = val;
}

curl_off_t Curl_ftp_acc_get_resume_from(struct Curl_easy *data)
{
  return data->state.resume_from;
}

void Curl_ftp_acc_set_resume_from(struct Curl_easy *data, curl_off_t val)
{
  data->state.resume_from = val;
}

curl_off_t Curl_ftp_acc_get_req_size(struct Curl_easy *data)
{
  return data->req.size;
}

void Curl_ftp_acc_set_req_size(struct Curl_easy *data, curl_off_t val)
{
  data->req.size = val;
}

curl_off_t Curl_ftp_acc_get_req_maxdownload(struct Curl_easy *data)
{
  return data->req.maxdownload;
}

curl_off_t Curl_ftp_acc_get_req_bytecount(struct Curl_easy *data)
{
  return data->req.bytecount;
}

curl_off_t Curl_ftp_acc_get_req_writebytecount(struct Curl_easy *data)
{
  return data->req.writebytecount;
}

curl_off_t Curl_ftp_acc_get_max_filesize(struct Curl_easy *data)
{
  return data->set.max_filesize;
}

bool Curl_ftp_acc_get_ignorecl(struct Curl_easy *data)
{
  return (bool)data->set.ignorecl;
}

bool Curl_ftp_acc_get_crlf(struct Curl_easy *data)
{
  return (bool)data->set.crlf;
}

bool Curl_ftp_acc_get_remote_append(struct Curl_easy *data)
{
  return (bool)data->set.remote_append;
}

bool Curl_ftp_acc_get_ftp_use_port(struct Curl_easy *data)
{
  return (bool)data->set.ftp_use_port;
}

bool Curl_ftp_acc_get_ftp_use_pret(struct Curl_easy *data)
{
  return (bool)data->set.ftp_use_pret;
}

bool Curl_ftp_acc_get_ftp_skip_ip(struct Curl_easy *data)
{
  return (bool)data->set.ftp_skip_ip;
}

uint8_t Curl_ftp_acc_get_ftp_create_missing_dirs(struct Curl_easy *data)
{
  return data->set.ftp_create_missing_dirs;
}

uint8_t Curl_ftp_acc_get_use_ssl(struct Curl_easy *data)
{
  return data->set.use_ssl;
}

uint8_t Curl_ftp_acc_get_ftpsslauth(struct Curl_easy *data)
{
  return data->set.ftpsslauth;
}

uint8_t Curl_ftp_acc_get_ftp_ccc(struct Curl_easy *data)
{
  return data->set.ftp_ccc;
}

timediff_t Curl_ftp_acc_get_accepttimeout(struct Curl_easy *data)
{
  return data->set.accepttimeout;
}

bool Curl_ftp_acc_get_get_filetime(struct Curl_easy *data)
{
  return (bool)data->set.get_filetime;
}

uint8_t Curl_ftp_acc_get_timecondition(struct Curl_easy *data)
{
  return data->set.timecondition;
}

curl_off_t Curl_ftp_acc_get_timevalue(struct Curl_easy *data)
{
  return data->set.timevalue;
}

curl_off_t Curl_ftp_acc_get_info_filetime(struct Curl_easy *data)
{
  return (curl_off_t)data->info.filetime;
}

time_t *Curl_ftp_acc_get_info_filetime_ptr(struct Curl_easy *data)
{
  return &data->info.filetime;
}

void Curl_ftp_acc_set_info_timecond(struct Curl_easy *data, bool val)
{
  data->info.timecond = val;
}

void Curl_ftp_acc_set_info_httpcode(struct Curl_easy *data, int code)
{
  data->info.httpcode = code;
}

void Curl_ftp_acc_clear_state_errorbuf(struct Curl_easy *data)
{
  data->state.errorbuf = FALSE;
}

CURLcode Curl_ftp_acc_set_most_recent_ftp_entrypath(struct Curl_easy *data,
                                                    const char *entrypath)
{
  curlx_free(data->state.most_recent_ftp_entrypath);
  data->state.most_recent_ftp_entrypath = curlx_strdup(entrypath);
  return data->state.most_recent_ftp_entrypath ?
    CURLE_OK : CURLE_OUT_OF_MEMORY;
}

char *Curl_ftp_acc_get_up_path_after_slash(struct Curl_easy *data)
{
  return &data->state.up.path[1];
}

struct curl_slist *Curl_ftp_acc_get_quote(struct Curl_easy *data)
{
  return data->set.quote;
}

struct curl_slist *Curl_ftp_acc_get_prequote(struct Curl_easy *data)
{
  return data->set.prequote;
}

struct curl_slist *Curl_ftp_acc_get_postquote(struct Curl_easy *data)
{
  return data->set.postquote;
}

const char *Curl_ftp_acc_get_str_ftpport(struct Curl_easy *data)
{
  return CURL_EASY_STR(data, STRING_FTPPORT);
}

const char *Curl_ftp_acc_get_str_customrequest(struct Curl_easy *data)
{
  return CURL_EASY_STR(data, STRING_CUSTOMREQUEST);
}

const char *Curl_ftp_acc_get_str_ftp_account(struct Curl_easy *data)
{
  return CURL_EASY_STR(data, STRING_FTP_ACCOUNT);
}

const char *Curl_ftp_acc_get_str_ftp_alternative_to_user(
  struct Curl_easy *data)
{
  return CURL_EASY_STR(data, STRING_FTP_ALTERNATIVE_TO_USER);
}

CURLcode Curl_ftp_acc_client_write_header(struct Curl_easy *data,
                                          char *buf, size_t blen)
{
  CURLcode result;
  bool save = (bool)data->set.include_header;
  data->set.include_header = TRUE;
  result = Curl_client_write(data, CLIENTWRITE_HEADER, buf, blen);
  data->set.include_header = save;
  return result;
}

curl_socket_t Curl_ftp_acc_conn_get_sock(struct connectdata *conn, int idx)
{
  return conn->sock[idx];
}

bool Curl_ftp_acc_conn_has_cfilter(struct connectdata *conn, int idx)
{
  return conn->cfilter[idx] != NULL;
}

bool Curl_ftp_acc_conn_get_reuse(struct connectdata *conn)
{
  return (bool)conn->bits.reuse;
}

bool Curl_ftp_acc_conn_get_ipv6(struct connectdata *conn)
{
  return (bool)conn->bits.ipv6;
}

bool Curl_ftp_acc_conn_get_ftp_use_eprt(struct connectdata *conn)
{
  return (bool)conn->bits.ftp_use_eprt;
}

void Curl_ftp_acc_conn_set_ftp_use_eprt(struct connectdata *conn, bool val)
{
  conn->bits.ftp_use_eprt = val;
}

bool Curl_ftp_acc_conn_get_ftp_use_epsv(struct connectdata *conn)
{
  return (bool)conn->bits.ftp_use_epsv;
}

void Curl_ftp_acc_conn_set_ftp_use_epsv(struct connectdata *conn, bool val)
{
  conn->bits.ftp_use_epsv = val;
}

bool Curl_ftp_acc_conn_get_ftp_use_data_ssl(struct connectdata *conn)
{
  return (bool)conn->bits.ftp_use_data_ssl;
}

void Curl_ftp_acc_conn_set_ftp_use_data_ssl(struct connectdata *conn,
                                            bool val)
{
  conn->bits.ftp_use_data_ssl = val;
}

void Curl_ftp_acc_conn_set_do_more(struct connectdata *conn, bool val)
{
  conn->bits.do_more = val;
}

const char *Curl_ftp_acc_conn_get_origin_hostname(struct connectdata *conn)
{
  return conn->origin->hostname;
}

unsigned int Curl_ftp_acc_conn_get_scheme_flags(struct connectdata *conn)
{
  return conn->scheme->flags;
}

const char *Curl_ftp_acc_conn_get_user(struct connectdata *conn)
{
  return Curl_creds_user(conn->creds);
}

const char *Curl_ftp_acc_conn_get_passwd(struct connectdata *conn)
{
  return Curl_creds_passwd(conn->creds);
}

bool Curl_ftp_acc_has_seek_func(struct Curl_easy *data)
{
  return data->set.seek_func != NULL;
}

int Curl_ftp_acc_call_seek_func(struct Curl_easy *data, curl_off_t offset)
{
  struct Curl_mapi_guard guard;
  int seekerr;
  CURL_CBAPI_START(&guard, data, easy_seek_func);
  seekerr = data->set.seek_func(data->set.seek_client, offset, SEEK_SET);
  CURL_CBAPI_END(&guard);
  return seekerr;
}

size_t Curl_ftp_acc_call_fread_func(struct Curl_easy *data, char *buf,
                                    size_t amount)
{
  return data->state.fread_func(buf, 1, amount, data->state.in);
}

bool Curl_ftp_acc_has_chunk_bgn(struct Curl_easy *data)
{
  return data->set.chunk_bgn != NULL;
}

long Curl_ftp_acc_call_chunk_bgn(struct Curl_easy *data,
                                 const struct curl_fileinfo *finfo,
                                 int remains)
{
  struct Curl_mapi_guard guard;
  long rc;
  CURL_CBAPI_START(&guard, data, easy_chunk_bgn);
  rc = data->set.chunk_bgn(finfo, data->set.wildcardptr, remains);
  CURL_CBAPI_END(&guard);
  return rc;
}

bool Curl_ftp_acc_has_chunk_end(struct Curl_easy *data)
{
  return data->set.chunk_end != NULL;
}

void Curl_ftp_acc_call_chunk_end(struct Curl_easy *data)
{
  struct Curl_mapi_guard guard;
  CURL_CBAPI_START(&guard, data, easy_chunk_end);
  data->set.chunk_end(data->set.wildcardptr);
  CURL_CBAPI_END(&guard);
}

int Curl_ftp_acc_get_sockerrno(void)
{
  return SOCKERRNO;
}

timediff_t Curl_ftp_acc_pp_state_timeleft_ms(struct Curl_easy *data,
                                             struct pingpong *pp)
{
  return Curl_pp_state_timeleft_ms(data, pp);
}

CURLcode Curl_ftp_acc_pp_statemach(struct Curl_easy *data,
                                   struct pingpong *pp,
                                   bool block, bool disconnecting)
{
  return Curl_pp_statemach(data, pp, block, disconnecting);
}

CURLcode Curl_ftp_acc_pp_readresp(struct Curl_easy *data, int8_t sockindex,
                                  struct pingpong *pp,
                                  int *code, size_t *size)
{
  return Curl_pp_readresp(data, sockindex, pp, code, size);
}

CURLcode Curl_ftp_acc_pp_pollset(struct Curl_easy *data,
                                 struct pingpong *pp,
                                 struct easy_pollset *ps)
{
  return Curl_pp_pollset(data, pp, ps);
}

CURLcode Curl_ftp_acc_pollset_add_in(struct Curl_easy *data,
                                     struct easy_pollset *ps,
                                     curl_socket_t sock)
{
  return Curl_pollset_add_in(data, ps, sock);
}

CURLcode Curl_ftp_acc_range(struct Curl_easy *data)
{
  return Curl_range(data);
}

void Curl_ftp_acc_xfer_setup_send(struct Curl_easy *data)
{
  Curl_xfer_setup_send(data, SECONDARYSOCKET);
}

void Curl_ftp_acc_xfer_setup_recv(struct Curl_easy *data, curl_off_t size)
{
  Curl_xfer_setup_recv(data, SECONDARYSOCKET, size);
}

void Curl_ftp_acc_connclose(struct connectdata *conn)
{
  connclose(conn);
}

CURLcode Curl_ftp_acc_ssl_cfilter_add(struct Curl_easy *data,
                                      struct connectdata *conn,
                                      int8_t sockindex)
{
  (void)data;
  (void)conn;
  (void)sockindex;
  return Curl_ssl_cfilter_add(data, Curl_conn_get_origin(conn, FIRSTSOCKET),
                              conn, sockindex);
}

CURLcode Curl_ftp_acc_ssl_cfilter_remove(struct Curl_easy *data,
                                         int8_t sockindex,
                                         bool send_shutdown)
{
  (void)data;
  (void)sockindex;
  (void)send_shutdown;
  return Curl_ssl_cfilter_remove(data, sockindex, send_shutdown);
}

CURLcode Curl_ftp_acc_control_addr_dup(struct Curl_easy *data,
                                       char **newhostp)
{
  struct connectdata *conn = data->conn;
  struct ip_quadruple ipquad;
  bool is_ipv6;

#ifndef CURL_DISABLE_PROXY
  if(Curl_conn_is_tunneling(conn, FIRSTSOCKET))
    *newhostp = curlx_strdup(conn->origin->hostname);
  else
#endif
  if(!Curl_conn_get_ip_info(data, conn, FIRSTSOCKET, &is_ipv6, &ipquad) &&
     *ipquad.remote_ip)
    *newhostp = curlx_strdup(ipquad.remote_ip);
  else {
    failf(data, "unable to get peername of DATA connection");
    *newhostp = NULL;
    return CURLE_FTP_CANT_GET_HOST;
  }
  return *newhostp ? CURLE_OK : CURLE_OUT_OF_MEMORY;
}

CURLcode Curl_ftp_acc_setup_pasv_conn(struct Curl_easy *data,
                                      struct connectdata *conn,
                                      const char *newhost,
                                      unsigned short newport)
{
  CURLcode result;
  Curl_peer_unlink(&conn->origin2);
  result = Curl_peer_create(data, conn->scheme, newhost, newport,
                            &conn->origin2);
  if(result)
    return result;

  if(conn->via_peer) {
    Curl_peer_unlink(&conn->via_peer2);
    result = Curl_peer_create(data, conn->via_peer->scheme,
                              conn->via_peer->hostname, newport,
                              &conn->via_peer2);
    if(result)
      return result;
  }

  result = Curl_conn_setup(data, conn, SECONDARYSOCKET,
                           conn->bits.ftp_use_data_ssl ?
                           CURL_CF_SSL_ENABLE : CURL_CF_SSL_DISABLE);
  if(result)
    return result;

#ifdef CURLVERBOSE
  if(data->set.verbose) {
    infof(data, "Connecting to %s port %d",
          conn->origin2->hostname, conn->origin2->port);
  }
#endif
  return CURLE_OK;
}

bool Curl_ftp_acc_is_ipv6_literal(const char *str)
{
#ifdef USE_IPV6
  struct in6_addr addr6;
  return curlx_inet_pton(AF_INET6, str, &addr6) == 1;
#else
  (void)str;
  return FALSE;
#endif
}

int Curl_ftp_acc_if2ip(struct Curl_easy *data, struct connectdata *conn,
                       const char *ipstr, char *hbuf, size_t hbuflen)
{
  const struct Curl_sockaddr_ex *remote_addr =
    Curl_conn_get_remote_addr(data, FIRSTSOCKET);
#ifndef USE_IPV6
  (void)conn;
#endif
  if(!remote_addr)
    return -1;
  return (int)Curl_if2ip(remote_addr->family,
#ifdef USE_IPV6
                         Curl_ipv6_scope(&remote_addr->curl_sa_addr),
                         conn->scope_id,
#endif
                         ipstr, hbuf, hbuflen);
}

CURLcode Curl_ftp_acc_port_default_host(struct Curl_easy *data,
                                        struct connectdata *conn,
                                        void *ss_ptr,
                                        unsigned int *sslenp,
                                        char *hbuf, size_t hbuflen)
{
  struct Curl_sockaddr_storage *ss = ss_ptr;
  struct sockaddr *sa = (struct sockaddr *)ss;
  struct sockaddr_in * const sa4 = (void *)sa;
#ifdef USE_IPV6
  struct sockaddr_in6 * const sa6 = (void *)sa;
#endif
  char buffer[STRERROR_LEN];
  curl_socklen_t slen = (curl_socklen_t)sizeof(*ss);
  CURLcode result;

  if(getsockname(conn->sock[FIRSTSOCKET], sa, &slen)) {
    failf(data, "getsockname() failed: %s",
          curlx_strerror(SOCKERRNO, buffer, sizeof(buffer)));
    return CURLE_FTP_PORT_FAILED;
  }
  *sslenp = (unsigned int)slen;
  switch(sa->sa_family) {
#ifdef USE_IPV6
  case AF_INET6:
    result = curlx_inet_ntop(sa->sa_family, &sa6->sin6_addr, hbuf, hbuflen);
    break;
#endif
  default:
    result = curlx_inet_ntop(sa->sa_family, &sa4->sin_addr, hbuf, hbuflen);
    break;
  }
  if(result)
    return CURLE_FTP_PORT_FAILED;
  return CURLE_OK;
}

CURLcode Curl_ftp_acc_port_resolve_host(struct Curl_easy *data,
                                        struct connectdata *conn,
                                        const char *host,
                                        struct Curl_dns_entry **dns_entryp,
                                        const struct Curl_addrinfo **resp)
{
  CURLcode result;

  *resp = NULL;
  result = Curl_resolv_blocking(
    data, Curl_resolv_dns_queries(data, conn->ip_version),
    host, 0, Curl_conn_get_transport(data, conn), dns_entryp);
  if(result)
    failf(data, "failed to resolve the address provided to PORT: %s", host);
  else {
    DEBUGASSERT(*dns_entryp);
    *resp = (*dns_entryp)->addr;
  }
  return result;
}

CURLcode Curl_ftp_acc_port_open_socket(struct Curl_easy *data,
                                       struct connectdata *conn,
                                       const struct Curl_addrinfo *res,
                                       const struct Curl_addrinfo **aip,
                                       curl_socket_t *portsockp)
{
  char buffer[STRERROR_LEN];
  int sockerr = 0;
  const struct Curl_addrinfo *ai;
  CURLcode result = CURLE_FTP_PORT_FAILED;

  for(ai = res; ai; ai = ai->ai_next) {
    result =
      Curl_socket_open(data, ai, NULL,
                       Curl_conn_get_transport(data, conn), portsockp);
    if(result) {
      if(result == CURLE_OUT_OF_MEMORY)
        return result;
      result = CURLE_FTP_PORT_FAILED;
      sockerr = SOCKERRNO;
      continue;
    }
    break;
  }
  if(!ai) {
    failf(data, "socket failure: %s",
          curlx_strerror(sockerr, buffer, sizeof(buffer)));
    return CURLE_FTP_PORT_FAILED;
  }
  *aip = ai;
  return result;
}

CURLcode Curl_ftp_acc_port_bind_socket(struct Curl_easy *data,
                                       struct connectdata *conn,
                                       curl_socket_t portsock,
                                       const struct Curl_addrinfo *ai,
                                       void *ss_ptr,
                                       unsigned int *sslen_io,
                                       unsigned short port_min,
                                       unsigned short port_max,
                                       bool non_local,
                                       unsigned short *pbound_port)
{
  struct Curl_sockaddr_storage *ss = ss_ptr;
  struct sockaddr *sa = (struct sockaddr *)ss;
  struct sockaddr_in * const sa4 = (void *)sa;
#ifdef USE_IPV6
  struct sockaddr_in6 * const sa6 = (void *)sa;
#endif
  char buffer[STRERROR_LEN];
  unsigned short port;
  int sockerr;
  curl_socklen_t slen;

  memcpy(sa, ai->ai_addr, ai->ai_addrlen);
  slen = ai->ai_addrlen;

  for(port = port_min; port <= port_max;) {
    if(sa->sa_family == AF_INET)
      sa4->sin_port = htons(port);
#ifdef USE_IPV6
    else
      sa6->sin6_port = htons(port);
#endif
    if(bind(portsock, sa, slen)) {
      sockerr = SOCKERRNO;
      if(non_local && (sockerr == SOCKEADDRNOTAVAIL)) {
        infof(data, "bind(port=%hu) on non-local address failed: %s", port,
              curlx_strerror(sockerr, buffer, sizeof(buffer)));

        slen = (curl_socklen_t)sizeof(*ss);
        if(getsockname(conn->sock[FIRSTSOCKET], sa, &slen)) {
          failf(data, "getsockname() failed: %s",
                curlx_strerror(SOCKERRNO, buffer, sizeof(buffer)));
          return CURLE_FTP_PORT_FAILED;
        }
        port = port_min;
        non_local = FALSE;
        continue;
      }
      if(sockerr != SOCKEADDRINUSE && sockerr != SOCKEACCES) {
        failf(data, "bind(port=%hu) failed: %s", port,
              curlx_strerror(sockerr, buffer, sizeof(buffer)));
        return CURLE_FTP_PORT_FAILED;
      }
    }
    else
      break;

    if(port == port_max) {
      failf(data, "bind() failed, ran out of ports");
      return CURLE_FTP_PORT_FAILED;
    }
    port++;
  }

  slen = (curl_socklen_t)sizeof(*ss);
  if(getsockname(portsock, sa, &slen)) {
    failf(data, "getsockname() failed: %s",
          curlx_strerror(SOCKERRNO, buffer, sizeof(buffer)));
    return CURLE_FTP_PORT_FAILED;
  }
  *sslen_io = (unsigned int)slen;
  *pbound_port = port;
  return CURLE_OK;
}

CURLcode Curl_ftp_acc_port_listen(struct Curl_easy *data,
                                  curl_socket_t portsock)
{
  char buffer[STRERROR_LEN];

  if(listen(portsock, 1)) {
    failf(data, "socket failure: %s",
          curlx_strerror(SOCKERRNO, buffer, sizeof(buffer)));
    return CURLE_FTP_PORT_FAILED;
  }
  return CURLE_OK;
}

void Curl_ftp_acc_port_extract_sa(const void *ss_ptr,
                                  const struct Curl_addrinfo *ai,
                                  char *myhost, size_t myhost_len,
                                  bool *pis_ipv4, bool *pis_ipv6,
                                  unsigned short *pport)
{
  const struct Curl_sockaddr_storage *ss = ss_ptr;
  const struct sockaddr *sa = (const struct sockaddr *)ss;
  const struct sockaddr_in * const sa4 = (const void *)sa;
#ifdef USE_IPV6
  const struct sockaddr_in6 * const sa6 = (const void *)sa;
#endif

  myhost[0] = '\0';
  Curl_printable_address(ai, myhost, myhost_len);
  *pis_ipv4 = FALSE;
  *pis_ipv6 = FALSE;
  *pport = 0;

  switch(sa->sa_family) {
  case AF_INET:
    *pis_ipv4 = TRUE;
    *pport = ntohs(sa4->sin_port);
    break;
#ifdef USE_IPV6
  case AF_INET6:
    *pis_ipv6 = TRUE;
    *pport = ntohs(sa6->sin6_port);
    break;
#endif
  default:
    break;
  }
}
#endif /* CURL_DISABLE_FTP */
/* C helper/accessor functions for zig/port/http.zig */
#include "http_ntlm.h"
#include "http_negotiate.h"
#include "http_aws_sigv4.h"
#include "http_httpsig.h"
#include "ws.h"

unsigned int Curl_http_acc_features(void);
struct connectdata *Curl_http_acc_conn(struct Curl_easy *data);
struct Curl_multi *Curl_http_acc_multi(struct Curl_easy *data);
curl_socket_t Curl_http_acc_conn_firstsocket(struct connectdata *conn);
unsigned char Curl_http_acc_conn_httpversion_seen(struct connectdata *conn);
void Curl_http_acc_conn_set_httpversion_seen(struct connectdata *conn,
                                             unsigned char v);
curl_prot_t Curl_http_acc_conn_scheme_protocol(const struct connectdata *conn);
curl_prot_t Curl_http_acc_conn_scheme_family(const struct connectdata *conn);
bool Curl_http_acc_conn_bits_origin_is_proxy(const struct connectdata *conn);
bool Curl_http_acc_conn_bits_close(const struct connectdata *conn);
bool Curl_http_acc_conn_bits_reuse(const struct connectdata *conn);
bool Curl_http_acc_conn_bits_retry(const struct connectdata *conn);
bool Curl_http_acc_conn_bits_altused(const struct connectdata *conn);
bool Curl_http_acc_conn_bits_upgrade_in_progress(
  const struct connectdata *conn);
void Curl_http_acc_conn_set_bits_upgrade_in_progress(struct connectdata *conn,
                                                     bool v);
const char *Curl_http_acc_conn_via_peer_hostname(
  const struct connectdata *conn);
int Curl_http_acc_conn_via_peer_port(const struct connectdata *conn);
struct Curl_peer *Curl_http_acc_conn_http_proxy_peer(
  const struct connectdata *conn);
struct Curl_creds *Curl_http_acc_conn_http_proxy_creds(
  const struct connectdata *conn);
const char *Curl_http_acc_creds_user(const struct Curl_creds *creds);
const char *Curl_http_acc_creds_passwd(const struct Curl_creds *creds);
bool Curl_http_acc_creds_has_user_or_pass(const struct Curl_creds *creds);
bool Curl_http_acc_creds_has_oauth_bearer(const struct Curl_creds *creds);
const char *Curl_http_acc_creds_oauth_bearer(const struct Curl_creds *creds);
unsigned char Curl_http_acc_set_httpwant(struct Curl_easy *data);
bool Curl_http_acc_set_http09_allowed(struct Curl_easy *data);
bool Curl_http_acc_set_sep_headers(struct Curl_easy *data);
struct curl_slist *Curl_http_acc_set_headers(struct Curl_easy *data);
struct curl_slist *Curl_http_acc_set_proxyheaders(struct Curl_easy *data);
struct curl_slist *Curl_http_acc_set_http200aliases(struct Curl_easy *data);
char *Curl_http_acc_easy_str(struct Curl_easy *data, int idx);
unsigned char Curl_http_acc_set_http_follow_mode(struct Curl_easy *data);
bool Curl_http_acc_set_http_auto_referer(struct Curl_easy *data);
bool Curl_http_acc_set_opt_no_body(struct Curl_easy *data);
bool Curl_http_acc_set_post301(struct Curl_easy *data);
bool Curl_http_acc_set_post302(struct Curl_easy *data);
bool Curl_http_acc_set_post303(struct Curl_easy *data);
long Curl_http_acc_set_maxredirs(struct Curl_easy *data);
bool Curl_http_acc_set_path_as_is(struct Curl_easy *data);
unsigned int Curl_http_acc_set_expect_100_timeout(struct Curl_easy *data);
unsigned char Curl_http_acc_set_connect_only(struct Curl_easy *data);
unsigned char Curl_http_acc_set_timecondition(struct Curl_easy *data);
curl_off_t Curl_http_acc_set_timevalue(struct Curl_easy *data);
void *Curl_http_acc_set_postfields(struct Curl_easy *data);
curl_off_t Curl_http_acc_set_set_resume_from(struct Curl_easy *data);
bool Curl_http_acc_set_get_filetime(struct Curl_easy *data);
bool Curl_http_acc_set_http_fail_on_error(struct Curl_easy *data);
bool Curl_http_acc_set_http_keep_sending_on_error(struct Curl_easy *data);
bool Curl_http_acc_set_http_transfer_encoding(struct Curl_easy *data);
bool Curl_http_acc_set_proxy_transfer_mode(struct Curl_easy *data);
bool Curl_http_acc_set_ignorecl(struct Curl_easy *data);
curl_off_t Curl_http_acc_set_max_filesize(struct Curl_easy *data);
struct http_negotiation *Curl_http_acc_state_http_neg(struct Curl_easy *data);
struct auth *Curl_http_acc_state_authhost(struct Curl_easy *data);
struct auth *Curl_http_acc_state_authproxy(struct Curl_easy *data);
struct Curl_creds *Curl_http_acc_state_creds(struct Curl_easy *data);
struct Curl_peer *Curl_http_acc_state_origin(struct Curl_easy *data);
struct Curl_peer *Curl_http_acc_state_initial_origin(struct Curl_easy *data);
const char *Curl_http_acc_peer_hostname(const struct Curl_peer *peer);
const char *Curl_http_acc_peer_user_hostname(const struct Curl_peer *peer);
int Curl_http_acc_peer_port(const struct Curl_peer *peer);
bool Curl_http_acc_peer_ipv6(const struct Curl_peer *peer);
const char *Curl_http_acc_peer_scheme_name(const struct Curl_peer *peer);
int Curl_http_acc_peer_scheme_defport(const struct Curl_peer *peer);
curl_prot_t Curl_http_acc_peer_scheme_family(const struct Curl_peer *peer);
bool Curl_http_acc_peer_is_http(const struct Curl_peer *peer);
bool Curl_http_acc_peer_is_ftp(const struct Curl_peer *peer);
bool Curl_http_acc_auth_allowed_to_host(struct Curl_easy *data);
bool Curl_http_acc_state_authproblem(struct Curl_easy *data);
void Curl_http_acc_state_set_authproblem(struct Curl_easy *data, bool v);
bool Curl_http_acc_state_this_is_a_follow(struct Curl_easy *data);
void Curl_http_acc_state_set_this_is_a_follow(struct Curl_easy *data, bool v);
bool Curl_http_acc_state_allow_port(struct Curl_easy *data);
void Curl_http_acc_state_set_allow_port(struct Curl_easy *data, bool v);
bool Curl_http_acc_state_prefer_ascii(struct Curl_easy *data);
curl_off_t Curl_http_acc_state_resume_from(struct Curl_easy *data);
void Curl_http_acc_state_set_resume_from(struct Curl_easy *data, curl_off_t v);
bool Curl_http_acc_state_use_range(struct Curl_easy *data);
char *Curl_http_acc_state_range(struct Curl_easy *data);
char *Curl_http_acc_state_rangeline(struct Curl_easy *data);
void Curl_http_acc_state_set_rangeline(struct Curl_easy *data, char *v);
curl_off_t Curl_http_acc_state_infilesize(struct Curl_easy *data);
void Curl_http_acc_state_set_infilesize(struct Curl_easy *data, curl_off_t v);
unsigned char Curl_http_acc_state_httpreq(struct Curl_easy *data);
void Curl_http_acc_state_set_httpreq(struct Curl_easy *data, unsigned char v);
bool Curl_http_acc_state_upload(struct Curl_easy *data);
bool Curl_http_acc_state_http_ignorecustom(struct Curl_easy *data);
void Curl_http_acc_state_set_http_ignorecustom(struct Curl_easy *data, bool v);
bool Curl_http_acc_state_disableexpect(struct Curl_easy *data);
void Curl_http_acc_state_set_disableexpect(struct Curl_easy *data, bool v);
void Curl_http_acc_state_http_hd_flags(struct Curl_easy *data,
                                       bool *pte, bool *pupgrade,
                                       bool *ph2settings);
void Curl_http_acc_state_set_http_hd_flags(struct Curl_easy *data,
                                           bool te, bool upgrade,
                                           bool h2settings);
bool Curl_http_acc_state_maybe_folded(struct Curl_easy *data);
void Curl_http_acc_state_set_maybe_folded(struct Curl_easy *data, bool v);
bool Curl_http_acc_state_leading_unfold(struct Curl_easy *data);
void Curl_http_acc_state_set_leading_unfold(struct Curl_easy *data, bool v);
long Curl_http_acc_state_followlocation(struct Curl_easy *data);
void Curl_http_acc_state_inc_followlocation(struct Curl_easy *data);
void Curl_http_acc_state_inc_requests(struct Curl_easy *data);
CURLU *Curl_http_acc_state_uh(struct Curl_easy *data);
struct bufref *Curl_http_acc_state_url_bufref(struct Curl_easy *data);
struct bufref *Curl_http_acc_state_referer_bufref(struct Curl_easy *data);
char *Curl_http_acc_state_http_host(struct Curl_easy *data);
void Curl_http_acc_state_set_http_host(struct Curl_easy *data, char *v);
struct dynbuf *Curl_http_acc_state_headerb(struct Curl_easy *data);
const char *Curl_http_acc_state_up_path(struct Curl_easy *data);
const char *Curl_http_acc_state_up_query(struct Curl_easy *data);
int Curl_http_acc_req_httpcode(struct Curl_easy *data);
void Curl_http_acc_req_set_httpcode(struct Curl_easy *data, int v);
unsigned char Curl_http_acc_req_httpversion(struct Curl_easy *data);
void Curl_http_acc_req_set_httpversion(struct Curl_easy *data,
                                       unsigned char v);
unsigned char Curl_http_acc_req_httpversion_sent(struct Curl_easy *data);
curl_off_t Curl_http_acc_req_size(struct Curl_easy *data);
void Curl_http_acc_req_set_size(struct Curl_easy *data, curl_off_t v);
curl_off_t Curl_http_acc_req_maxdownload(struct Curl_easy *data);
void Curl_http_acc_req_set_maxdownload(struct Curl_easy *data, curl_off_t v);
curl_off_t Curl_http_acc_req_bytecount(struct Curl_easy *data);
curl_off_t Curl_http_acc_req_writebytecount(struct Curl_easy *data);
unsigned int Curl_http_acc_req_headerbytecount(struct Curl_easy *data);
void Curl_http_acc_req_set_headerbytecount(struct Curl_easy *data,
                                           unsigned int v);
unsigned int Curl_http_acc_req_deductheadercount(struct Curl_easy *data);
void Curl_http_acc_req_set_deductheadercount(struct Curl_easy *data,
                                             unsigned int v);
size_t Curl_http_acc_req_allheadercount(struct Curl_easy *data);
void Curl_http_acc_req_set_allheadercount(struct Curl_easy *data, size_t v);
int Curl_http_acc_req_headerline(struct Curl_easy *data);
void Curl_http_acc_req_set_headerline(struct Curl_easy *data, int v);
curl_off_t *Curl_http_acc_req_offset_ptr(struct Curl_easy *data);
time_t *Curl_http_acc_req_timeofdoc_ptr(struct Curl_easy *data);
char *Curl_http_acc_req_newurl(struct Curl_easy *data);
void Curl_http_acc_req_set_newurl(struct Curl_easy *data, char *v);
char *Curl_http_acc_req_location(struct Curl_easy *data);
void Curl_http_acc_req_set_location(struct Curl_easy *data, char *v);
char *Curl_http_acc_req_cookiehost(struct Curl_easy *data);
void Curl_http_acc_req_set_cookiehost(struct Curl_easy *data, char *v);
char *Curl_http_acc_req_hd_auth(struct Curl_easy *data, bool proxy);
void Curl_http_acc_req_set_hd_auth(struct Curl_easy *data, bool proxy,
                                   char *v);
unsigned char Curl_http_acc_req_upgr101(struct Curl_easy *data);
void Curl_http_acc_req_set_upgr101(struct Curl_easy *data, unsigned char v);
bool Curl_http_acc_req_header(struct Curl_easy *data);
void Curl_http_acc_req_set_header(struct Curl_easy *data, bool v);
bool Curl_http_acc_req_content_range(struct Curl_easy *data);
void Curl_http_acc_req_set_content_range(struct Curl_easy *data, bool v);
bool Curl_http_acc_req_download_done(struct Curl_easy *data);
void Curl_http_acc_req_set_download_done(struct Curl_easy *data, bool v);
bool Curl_http_acc_req_upload_done(struct Curl_easy *data);
bool Curl_http_acc_req_done(struct Curl_easy *data);
void Curl_http_acc_req_set_done(struct Curl_easy *data, bool v);
bool Curl_http_acc_req_chunk(struct Curl_easy *data);
bool Curl_http_acc_req_upload_chunky(struct Curl_easy *data);
void Curl_http_acc_req_set_upload_chunky(struct Curl_easy *data, bool v);
bool Curl_http_acc_req_no_body(struct Curl_easy *data);
void Curl_http_acc_req_set_no_body(struct Curl_easy *data, bool v);
bool Curl_http_acc_req_authneg(struct Curl_easy *data);
void Curl_http_acc_req_set_authneg(struct Curl_easy *data, bool v);
bool Curl_http_acc_req_ignorebody(struct Curl_easy *data);
void Curl_http_acc_req_set_ignorebody(struct Curl_easy *data, bool v);
bool Curl_http_acc_req_http_bodyless(struct Curl_easy *data);
void Curl_http_acc_req_set_http_bodyless(struct Curl_easy *data, bool v);
bool Curl_http_acc_req_ignore_cl(struct Curl_easy *data);
void Curl_http_acc_req_set_ignore_cl(struct Curl_easy *data, bool v);
void Curl_http_acc_req_set_resp_trailer(struct Curl_easy *data, bool v);
bool Curl_http_acc_req_want_recv(struct Curl_easy *data);
void Curl_http_acc_req_clear_recv(struct Curl_easy *data);
void Curl_http_acc_req_set_send(struct Curl_easy *data);
CURLcode Curl_http_acc_req_soft_reset(struct Curl_easy *data);
int Curl_http_acc_info_httpcode(struct Curl_easy *data);
void Curl_http_acc_info_set_httpcode(struct Curl_easy *data, int v);
void Curl_http_acc_info_set_httpversion(struct Curl_easy *data, int v);
uint32_t *Curl_http_acc_info_authpicked_ptr(struct Curl_easy *data,
                                            bool proxy);
uint32_t *Curl_http_acc_info_authavail_ptr(struct Curl_easy *data, bool proxy);
void Curl_http_acc_info_set_filetime(struct Curl_easy *data, time_t v);
void Curl_http_acc_info_set_timecond(struct Curl_easy *data, bool v);
void Curl_http_acc_info_set_contenttype(struct Curl_easy *data, char *v);
void Curl_http_acc_info_set_wouldredirect(struct Curl_easy *data, char *v);
void Curl_http_acc_info_set_retry_after(struct Curl_easy *data, time_t v);
curl_off_t Curl_http_acc_info_header_size(struct Curl_easy *data);
void Curl_http_acc_info_set_header_size(struct Curl_easy *data, curl_off_t v);
CURLcode Curl_http_acc_input_negotiate(struct Curl_easy *data,
                                       struct connectdata *conn,
                                       bool proxy, const char *header);
void Curl_http_acc_conn_set_nego_recv(struct connectdata *conn, bool proxy);
CURLcode Curl_http_acc_output_negotiate(struct Curl_easy *data,
                                        struct connectdata *conn, bool proxy);
CURLcode Curl_http_acc_input_ntlm(struct Curl_easy *data,
                                  bool proxy, const char *header);
CURLcode Curl_http_acc_output_ntlm(struct Curl_easy *data, bool proxy);
bool Curl_http_acc_is_ntlm_supported(void);
bool Curl_http_acc_is_spnego_supported(void);
bool Curl_http_acc_is_digest_supported(void);
CURLcode Curl_http_acc_input_digest(struct Curl_easy *data,
                                    bool proxy, const char *header);
CURLcode Curl_http_acc_output_digest(struct Curl_easy *data,
                                     bool proxy,
                                     const unsigned char *request,
                                     const unsigned char *uripath);
void Curl_http_acc_digest_cleanup(struct Curl_easy *data);
CURLcode Curl_http_acc_output_aws_sigv4(struct Curl_easy *data);
CURLcode Curl_http_acc_output_httpsig(struct Curl_easy *data);
CURLcode Curl_http_acc_headers_init(struct Curl_easy *data);
CURLcode Curl_http_acc_http_cookies(struct Curl_easy *data, struct dynbuf *r);
CURLcode Curl_http_acc_cookie_add(struct Curl_easy *data, const char *v);
bool Curl_http_acc_has_cookie_engine(struct Curl_easy *data);
CURLcode Curl_http_acc_altsvc_header(struct Curl_easy *data,
                                     const char *hd, size_t hdlen);
CURLcode Curl_http_acc_hsts_header(struct Curl_easy *data,
                                   const char *hd, size_t hdlen);
CURLcode Curl_http_acc_persistent_auth(struct Curl_easy *data,
                                       const char *hd, size_t hdlen);
void Curl_http_acc_check_auth_closure(struct Curl_easy *data,
                                      struct connectdata *conn);
bool Curl_http_acc_perhapsrewind_auth_check(struct Curl_easy *data,
                                            struct connectdata *conn,
                                            const char **pongoing_auth);
CURLcode Curl_http_acc_set_post_reader(struct Curl_easy *data,
                                       Curl_HttpReq httpreq);
struct curl_slist *Curl_http_acc_mimepost_curlheaders(struct Curl_easy *data);
bool Curl_http_acc_http2_may_switch(struct Curl_easy *data);
CURLcode Curl_http_acc_http2_switch(struct Curl_easy *data);
CURLcode Curl_http_acc_http2_request_upgrade(struct dynbuf *req,
                                             struct Curl_easy *data);
CURLcode Curl_http_acc_http2_upgrade(struct Curl_easy *data,
                                     struct connectdata *conn,
                                     const char *mem, size_t nread);
CURLcode Curl_http_acc_ws_request(struct Curl_easy *data, struct dynbuf *req);
CURLcode Curl_http_acc_ws_accept(struct Curl_easy *data,
                                 const char *mem, size_t nread);
CURLcode Curl_http_acc_rtsp_parseheader(struct Curl_easy *data,
                                        const char *hd);
curl_off_t Curl_http_acc_current_time(void);

unsigned int Curl_http_acc_features(void)
{
  unsigned int f = 0;
#ifdef USE_SPNEGO
  f |= (1u << 0);
#endif
#ifdef USE_NTLM
  f |= (1u << 1);
#endif
#ifndef CURL_DISABLE_DIGEST_AUTH
  f |= (1u << 2);
#endif
#ifndef CURL_DISABLE_AWS
  f |= (1u << 3);
#endif
#ifndef CURL_DISABLE_HTTPSIG
  f |= (1u << 4);
#endif
#ifndef CURL_DISABLE_PROXY
  f |= (1u << 5);
#endif
#ifdef USE_SSL
  f |= (1u << 6);
#endif
#ifdef USE_NGHTTP2
  f |= (1u << 7);
#endif
#ifndef CURL_DISABLE_WEBSOCKETS
  f |= (1u << 8);
#endif
#ifndef CURL_DISABLE_ALTSVC
  f |= (1u << 9);
#endif
#ifndef CURL_DISABLE_HSTS
  f |= (1u << 10);
#endif
#ifndef CURL_DISABLE_COOKIES
  f |= (1u << 11);
#endif
#ifdef HAVE_LIBZ
  f |= (1u << 12);
#endif
#ifndef CURL_DISABLE_MIME
  f |= (1u << 13);
#endif
#ifndef CURL_DISABLE_FORM_API
  f |= (1u << 14);
#endif
#ifndef CURL_DISABLE_HEADERS_API
  f |= (1u << 15);
#endif
#ifndef CURL_DISABLE_NETRC
  f |= (1u << 16);
#endif
#ifdef DEBUGBUILD
  f |= (1u << 17);
#endif
#ifndef CURL_DISABLE_HTTP_AUTH
  f |= (1u << 18);
#endif
#ifndef CURL_DISABLE_BASIC_AUTH
  f |= (1u << 19);
#endif
#ifndef CURL_DISABLE_BEARER_AUTH
  f |= (1u << 20);
#endif
#ifdef USE_HTTP2
  f |= (1u << 21);
#endif
#ifdef USE_HTTP3
  f |= (1u << 22);
#endif
#ifndef CURL_DISABLE_PARSEDATE
  f |= (1u << 23);
#endif
#ifndef CURL_DISABLE_RTSP
  f |= (1u << 24);
#endif
  return f;
}

struct connectdata *Curl_http_acc_conn(struct Curl_easy *data)
{
  return data->conn;
}

struct Curl_multi *Curl_http_acc_multi(struct Curl_easy *data)
{
  return data->multi;
}

curl_socket_t Curl_http_acc_conn_firstsocket(struct connectdata *conn)
{
  return conn->sock[FIRSTSOCKET];
}

unsigned char Curl_http_acc_conn_httpversion_seen(struct connectdata *conn)
{
  return conn->httpversion_seen;
}

void Curl_http_acc_conn_set_httpversion_seen(struct connectdata *conn,
                                             unsigned char v)
{
  conn->httpversion_seen = v;
}

curl_prot_t Curl_http_acc_conn_scheme_protocol(const struct connectdata *conn)
{
  return conn->scheme->protocol;
}

curl_prot_t Curl_http_acc_conn_scheme_family(const struct connectdata *conn)
{
  return conn->scheme->family;
}

bool Curl_http_acc_conn_bits_origin_is_proxy(const struct connectdata *conn)
{
  return conn->bits.origin_is_proxy ? TRUE : FALSE;
}

bool Curl_http_acc_conn_bits_close(const struct connectdata *conn)
{
  return conn->bits.close ? TRUE : FALSE;
}

bool Curl_http_acc_conn_bits_reuse(const struct connectdata *conn)
{
  return conn->bits.reuse ? TRUE : FALSE;
}

bool Curl_http_acc_conn_bits_retry(const struct connectdata *conn)
{
  return conn->bits.retry ? TRUE : FALSE;
}

bool Curl_http_acc_conn_bits_altused(const struct connectdata *conn)
{
  return conn->bits.altused ? TRUE : FALSE;
}

bool Curl_http_acc_conn_bits_upgrade_in_progress(
  const struct connectdata *conn)
{
  return conn->bits.upgrade_in_progress ? TRUE : FALSE;
}

void Curl_http_acc_conn_set_bits_upgrade_in_progress(struct connectdata *conn,
                                                     bool v)
{
  conn->bits.upgrade_in_progress = v;
}

const char *Curl_http_acc_conn_via_peer_hostname(
  const struct connectdata *conn)
{
  return conn->via_peer ? conn->via_peer->hostname : NULL;
}

int Curl_http_acc_conn_via_peer_port(const struct connectdata *conn)
{
  return conn->via_peer ? conn->via_peer->port : 0;
}

struct Curl_peer *Curl_http_acc_conn_http_proxy_peer(
  const struct connectdata *conn)
{
#ifndef CURL_DISABLE_PROXY
  return conn->http_proxy.peer;
#else
  (void)conn;
  return NULL;
#endif
}

struct Curl_creds *Curl_http_acc_conn_http_proxy_creds(
  const struct connectdata *conn)
{
#ifndef CURL_DISABLE_PROXY
  return conn->http_proxy.creds;
#else
  (void)conn;
  return NULL;
#endif
}

const char *Curl_http_acc_creds_user(const struct Curl_creds *creds)
{
  return creds ? creds->user : NULL;
}

const char *Curl_http_acc_creds_passwd(const struct Curl_creds *creds)
{
  return creds ? creds->passwd : NULL;
}

bool Curl_http_acc_creds_has_user_or_pass(const struct Curl_creds *creds)
{
  return Curl_creds_has_user_or_pass(creds) ? TRUE : FALSE;
}

bool Curl_http_acc_creds_has_oauth_bearer(const struct Curl_creds *creds)
{
  return Curl_creds_has_oauth_bearer(creds) ? TRUE : FALSE;
}

const char *Curl_http_acc_creds_oauth_bearer(const struct Curl_creds *creds)
{
  return Curl_creds_oauth_bearer(creds);
}

unsigned char Curl_http_acc_set_httpwant(struct Curl_easy *data)
{
  return data->set.httpwant;
}

bool Curl_http_acc_set_http09_allowed(struct Curl_easy *data)
{
  return data->set.http09_allowed ? TRUE : FALSE;
}

bool Curl_http_acc_set_sep_headers(struct Curl_easy *data)
{
  return data->set.sep_headers ? TRUE : FALSE;
}

struct curl_slist *Curl_http_acc_set_headers(struct Curl_easy *data)
{
  return data->set.headers;
}

struct curl_slist *Curl_http_acc_set_proxyheaders(struct Curl_easy *data)
{
#ifndef CURL_DISABLE_PROXY
  return data->set.proxyheaders;
#else
  (void)data;
  return NULL;
#endif
}

struct curl_slist *Curl_http_acc_set_http200aliases(struct Curl_easy *data)
{
  return data->set.http200aliases;
}

char *Curl_http_acc_easy_str(struct Curl_easy *data, int idx)
{
  return (char *)CURL_EASY_STR(data, (enum dupstring)idx);
}

unsigned char Curl_http_acc_set_http_follow_mode(struct Curl_easy *data)
{
  return data->set.http_follow_mode;
}

bool Curl_http_acc_set_http_auto_referer(struct Curl_easy *data)
{
  return data->set.http_auto_referer ? TRUE : FALSE;
}

bool Curl_http_acc_set_opt_no_body(struct Curl_easy *data)
{
  return data->set.opt_no_body ? TRUE : FALSE;
}

bool Curl_http_acc_set_post301(struct Curl_easy *data)
{
  return data->set.post301 ? TRUE : FALSE;
}

bool Curl_http_acc_set_post302(struct Curl_easy *data)
{
  return data->set.post302 ? TRUE : FALSE;
}

bool Curl_http_acc_set_post303(struct Curl_easy *data)
{
  return data->set.post303 ? TRUE : FALSE;
}

long Curl_http_acc_set_maxredirs(struct Curl_easy *data)
{
  return data->set.maxredirs;
}

bool Curl_http_acc_set_path_as_is(struct Curl_easy *data)
{
  return data->set.path_as_is ? TRUE : FALSE;
}

unsigned int Curl_http_acc_set_expect_100_timeout(struct Curl_easy *data)
{
  return data->set.expect_100_timeout;
}

unsigned char Curl_http_acc_set_connect_only(struct Curl_easy *data)
{
  return data->set.connect_only;
}

unsigned char Curl_http_acc_set_timecondition(struct Curl_easy *data)
{
  return data->set.timecondition;
}

curl_off_t Curl_http_acc_set_timevalue(struct Curl_easy *data)
{
  return data->set.timevalue;
}

void *Curl_http_acc_set_postfields(struct Curl_easy *data)
{
  return data->set.postfields;
}

curl_off_t Curl_http_acc_set_set_resume_from(struct Curl_easy *data)
{
  return data->set.set_resume_from;
}

bool Curl_http_acc_set_get_filetime(struct Curl_easy *data)
{
  return data->set.get_filetime ? TRUE : FALSE;
}

bool Curl_http_acc_set_http_fail_on_error(struct Curl_easy *data)
{
  return data->set.http_fail_on_error ? TRUE : FALSE;
}

bool Curl_http_acc_set_http_keep_sending_on_error(struct Curl_easy *data)
{
  return data->set.http_keep_sending_on_error ? TRUE : FALSE;
}

bool Curl_http_acc_set_http_transfer_encoding(struct Curl_easy *data)
{
  return data->set.http_transfer_encoding ? TRUE : FALSE;
}

bool Curl_http_acc_set_proxy_transfer_mode(struct Curl_easy *data)
{
  return data->set.proxy_transfer_mode ? TRUE : FALSE;
}

bool Curl_http_acc_set_ignorecl(struct Curl_easy *data)
{
  return data->set.ignorecl ? TRUE : FALSE;
}

curl_off_t Curl_http_acc_set_max_filesize(struct Curl_easy *data)
{
  return data->set.max_filesize;
}

struct http_negotiation *Curl_http_acc_state_http_neg(struct Curl_easy *data)
{
  return &data->state.http_neg;
}

struct auth *Curl_http_acc_state_authhost(struct Curl_easy *data)
{
  return &data->state.authhost;
}

struct auth *Curl_http_acc_state_authproxy(struct Curl_easy *data)
{
  return &data->state.authproxy;
}

struct Curl_creds *Curl_http_acc_state_creds(struct Curl_easy *data)
{
  return data->state.creds;
}

struct Curl_peer *Curl_http_acc_state_origin(struct Curl_easy *data)
{
  return data->state.origin;
}

struct Curl_peer *Curl_http_acc_state_initial_origin(struct Curl_easy *data)
{
  return data->state.initial_origin;
}

const char *Curl_http_acc_peer_hostname(const struct Curl_peer *peer)
{
  return peer ? peer->hostname : NULL;
}

const char *Curl_http_acc_peer_user_hostname(const struct Curl_peer *peer)
{
  return peer ? peer->user_hostname : NULL;
}

int Curl_http_acc_peer_port(const struct Curl_peer *peer)
{
  return peer ? peer->port : 0;
}

bool Curl_http_acc_peer_ipv6(const struct Curl_peer *peer)
{
  return (peer && peer->ipv6) ? TRUE : FALSE;
}

const char *Curl_http_acc_peer_scheme_name(const struct Curl_peer *peer)
{
  return (peer && peer->scheme) ? peer->scheme->name : NULL;
}

int Curl_http_acc_peer_scheme_defport(const struct Curl_peer *peer)
{
  return (peer && peer->scheme) ? peer->scheme->defport : 0;
}

curl_prot_t Curl_http_acc_peer_scheme_family(const struct Curl_peer *peer)
{
  return (peer && peer->scheme) ? peer->scheme->family : 0;
}

bool Curl_http_acc_peer_is_http(const struct Curl_peer *peer)
{
  return (peer && peer->scheme == &Curl_scheme_http) ? TRUE : FALSE;
}

bool Curl_http_acc_peer_is_ftp(const struct Curl_peer *peer)
{
  return (peer && (peer->scheme->protocol & CURLPROTO_FTP)) ? TRUE : FALSE;
}

bool Curl_http_acc_auth_allowed_to_host(struct Curl_easy *data)
{
  return Curl_auth_allowed_to_host(data) ? TRUE : FALSE;
}

bool Curl_http_acc_state_authproblem(struct Curl_easy *data)
{
  return data->state.authproblem ? TRUE : FALSE;
}

void Curl_http_acc_state_set_authproblem(struct Curl_easy *data, bool v)
{
  data->state.authproblem = v;
}

bool Curl_http_acc_state_this_is_a_follow(struct Curl_easy *data)
{
  return data->state.this_is_a_follow ? TRUE : FALSE;
}

void Curl_http_acc_state_set_this_is_a_follow(struct Curl_easy *data, bool v)
{
  data->state.this_is_a_follow = v;
}

bool Curl_http_acc_state_allow_port(struct Curl_easy *data)
{
  return data->state.allow_port ? TRUE : FALSE;
}

void Curl_http_acc_state_set_allow_port(struct Curl_easy *data, bool v)
{
  data->state.allow_port = v;
}

bool Curl_http_acc_state_prefer_ascii(struct Curl_easy *data)
{
  return data->state.prefer_ascii ? TRUE : FALSE;
}

curl_off_t Curl_http_acc_state_resume_from(struct Curl_easy *data)
{
  return data->state.resume_from;
}

void Curl_http_acc_state_set_resume_from(struct Curl_easy *data, curl_off_t v)
{
  data->state.resume_from = v;
}

bool Curl_http_acc_state_use_range(struct Curl_easy *data)
{
  return data->state.use_range ? TRUE : FALSE;
}

char *Curl_http_acc_state_range(struct Curl_easy *data)
{
  return data->state.range;
}

char *Curl_http_acc_state_rangeline(struct Curl_easy *data)
{
  return data->state.rangeline;
}

void Curl_http_acc_state_set_rangeline(struct Curl_easy *data, char *v)
{
  data->state.rangeline = v;
}

curl_off_t Curl_http_acc_state_infilesize(struct Curl_easy *data)
{
  return data->state.infilesize;
}

void Curl_http_acc_state_set_infilesize(struct Curl_easy *data, curl_off_t v)
{
  data->state.infilesize = v;
}

unsigned char Curl_http_acc_state_httpreq(struct Curl_easy *data)
{
  return data->state.httpreq;
}

void Curl_http_acc_state_set_httpreq(struct Curl_easy *data, unsigned char v)
{
  data->state.httpreq = v;
}

bool Curl_http_acc_state_upload(struct Curl_easy *data)
{
  return data->state.upload ? TRUE : FALSE;
}

bool Curl_http_acc_state_http_ignorecustom(struct Curl_easy *data)
{
  return data->state.http_ignorecustom ? TRUE : FALSE;
}

void Curl_http_acc_state_set_http_ignorecustom(struct Curl_easy *data, bool v)
{
  data->state.http_ignorecustom = v;
}

bool Curl_http_acc_state_disableexpect(struct Curl_easy *data)
{
  return data->state.disableexpect ? TRUE : FALSE;
}

void Curl_http_acc_state_set_disableexpect(struct Curl_easy *data, bool v)
{
  data->state.disableexpect = v;
}

void Curl_http_acc_state_http_hd_flags(struct Curl_easy *data,
                                       bool *pte, bool *pupgrade,
                                       bool *ph2settings)
{
  *pte = data->state.http_hd_te ? TRUE : FALSE;
  *pupgrade = data->state.http_hd_upgrade ? TRUE : FALSE;
  *ph2settings = data->state.http_hd_h2_settings ? TRUE : FALSE;
}

void Curl_http_acc_state_set_http_hd_flags(struct Curl_easy *data,
                                           bool te, bool upgrade,
                                           bool h2settings)
{
  data->state.http_hd_te = te;
  data->state.http_hd_upgrade = upgrade;
  data->state.http_hd_h2_settings = h2settings;
}

bool Curl_http_acc_state_maybe_folded(struct Curl_easy *data)
{
  return data->state.maybe_folded ? TRUE : FALSE;
}

void Curl_http_acc_state_set_maybe_folded(struct Curl_easy *data, bool v)
{
  data->state.maybe_folded = v;
}

bool Curl_http_acc_state_leading_unfold(struct Curl_easy *data)
{
  return data->state.leading_unfold ? TRUE : FALSE;
}

void Curl_http_acc_state_set_leading_unfold(struct Curl_easy *data, bool v)
{
  data->state.leading_unfold = v;
}

long Curl_http_acc_state_followlocation(struct Curl_easy *data)
{
  return data->state.followlocation;
}

void Curl_http_acc_state_inc_followlocation(struct Curl_easy *data)
{
  data->state.followlocation++;
}

void Curl_http_acc_state_inc_requests(struct Curl_easy *data)
{
  data->state.requests++;
}

CURLU *Curl_http_acc_state_uh(struct Curl_easy *data)
{
  return data->state.uh;
}

struct bufref *Curl_http_acc_state_url_bufref(struct Curl_easy *data)
{
  return &data->state.url;
}

struct bufref *Curl_http_acc_state_referer_bufref(struct Curl_easy *data)
{
  return &data->state.referer;
}

char *Curl_http_acc_state_http_host(struct Curl_easy *data)
{
  return data->state.http_host;
}

void Curl_http_acc_state_set_http_host(struct Curl_easy *data, char *v)
{
  data->state.http_host = v;
}

struct dynbuf *Curl_http_acc_state_headerb(struct Curl_easy *data)
{
  return &data->state.headerb;
}

const char *Curl_http_acc_state_up_path(struct Curl_easy *data)
{
  return data->state.up.path;
}

const char *Curl_http_acc_state_up_query(struct Curl_easy *data)
{
  return data->state.up.query;
}

int Curl_http_acc_req_httpcode(struct Curl_easy *data)
{
  return data->req.httpcode;
}

void Curl_http_acc_req_set_httpcode(struct Curl_easy *data, int v)
{
  data->req.httpcode = v;
}

unsigned char Curl_http_acc_req_httpversion(struct Curl_easy *data)
{
  return data->req.httpversion;
}

void Curl_http_acc_req_set_httpversion(struct Curl_easy *data,
                                       unsigned char v)
{
  data->req.httpversion = v;
}

unsigned char Curl_http_acc_req_httpversion_sent(struct Curl_easy *data)
{
  return data->req.httpversion_sent;
}

curl_off_t Curl_http_acc_req_size(struct Curl_easy *data)
{
  return data->req.size;
}

void Curl_http_acc_req_set_size(struct Curl_easy *data, curl_off_t v)
{
  data->req.size = v;
}

curl_off_t Curl_http_acc_req_maxdownload(struct Curl_easy *data)
{
  return data->req.maxdownload;
}

void Curl_http_acc_req_set_maxdownload(struct Curl_easy *data, curl_off_t v)
{
  data->req.maxdownload = v;
}

curl_off_t Curl_http_acc_req_bytecount(struct Curl_easy *data)
{
  return data->req.bytecount;
}

curl_off_t Curl_http_acc_req_writebytecount(struct Curl_easy *data)
{
  return data->req.writebytecount;
}

unsigned int Curl_http_acc_req_headerbytecount(struct Curl_easy *data)
{
  return data->req.headerbytecount;
}

void Curl_http_acc_req_set_headerbytecount(struct Curl_easy *data,
                                           unsigned int v)
{
  data->req.headerbytecount = v;
}

unsigned int Curl_http_acc_req_deductheadercount(struct Curl_easy *data)
{
  return data->req.deductheadercount;
}

void Curl_http_acc_req_set_deductheadercount(struct Curl_easy *data,
                                             unsigned int v)
{
  data->req.deductheadercount = v;
}

size_t Curl_http_acc_req_allheadercount(struct Curl_easy *data)
{
  return data->req.allheadercount;
}

void Curl_http_acc_req_set_allheadercount(struct Curl_easy *data, size_t v)
{
  data->req.allheadercount = v;
}

int Curl_http_acc_req_headerline(struct Curl_easy *data)
{
  return data->req.headerline;
}

void Curl_http_acc_req_set_headerline(struct Curl_easy *data, int v)
{
  data->req.headerline = v;
}

curl_off_t *Curl_http_acc_req_offset_ptr(struct Curl_easy *data)
{
  return &data->req.offset;
}

time_t *Curl_http_acc_req_timeofdoc_ptr(struct Curl_easy *data)
{
  return &data->req.timeofdoc;
}

char *Curl_http_acc_req_newurl(struct Curl_easy *data)
{
  return data->req.newurl;
}

void Curl_http_acc_req_set_newurl(struct Curl_easy *data, char *v)
{
  data->req.newurl = v;
}

char *Curl_http_acc_req_location(struct Curl_easy *data)
{
  return data->req.location;
}

void Curl_http_acc_req_set_location(struct Curl_easy *data, char *v)
{
  data->req.location = v;
}

char *Curl_http_acc_req_cookiehost(struct Curl_easy *data)
{
  return data->req.cookiehost;
}

void Curl_http_acc_req_set_cookiehost(struct Curl_easy *data, char *v)
{
  data->req.cookiehost = v;
}

char *Curl_http_acc_req_hd_auth(struct Curl_easy *data, bool proxy)
{
  return proxy ? data->req.hd_proxy_auth : data->req.hd_auth;
}

void Curl_http_acc_req_set_hd_auth(struct Curl_easy *data, bool proxy,
                                   char *v)
{
  if(proxy)
    data->req.hd_proxy_auth = v;
  else
    data->req.hd_auth = v;
}

unsigned char Curl_http_acc_req_upgr101(struct Curl_easy *data)
{
  return data->req.upgr101;
}

void Curl_http_acc_req_set_upgr101(struct Curl_easy *data, unsigned char v)
{
  data->req.upgr101 = v;
}

bool Curl_http_acc_req_header(struct Curl_easy *data)
{
  return data->req.header ? TRUE : FALSE;
}

void Curl_http_acc_req_set_header(struct Curl_easy *data, bool v)
{
  data->req.header = v;
}

bool Curl_http_acc_req_content_range(struct Curl_easy *data)
{
  return data->req.content_range ? TRUE : FALSE;
}

void Curl_http_acc_req_set_content_range(struct Curl_easy *data, bool v)
{
  data->req.content_range = v;
}

bool Curl_http_acc_req_download_done(struct Curl_easy *data)
{
  return data->req.download_done ? TRUE : FALSE;
}

void Curl_http_acc_req_set_download_done(struct Curl_easy *data, bool v)
{
  data->req.download_done = v;
}

bool Curl_http_acc_req_upload_done(struct Curl_easy *data)
{
  return data->req.upload_done ? TRUE : FALSE;
}

bool Curl_http_acc_req_done(struct Curl_easy *data)
{
  return data->req.done ? TRUE : FALSE;
}

void Curl_http_acc_req_set_done(struct Curl_easy *data, bool v)
{
  data->req.done = v;
}

bool Curl_http_acc_req_chunk(struct Curl_easy *data)
{
  return data->req.chunk ? TRUE : FALSE;
}

bool Curl_http_acc_req_upload_chunky(struct Curl_easy *data)
{
  return data->req.upload_chunky ? TRUE : FALSE;
}

void Curl_http_acc_req_set_upload_chunky(struct Curl_easy *data, bool v)
{
  data->req.upload_chunky = v;
}

bool Curl_http_acc_req_no_body(struct Curl_easy *data)
{
  return data->req.no_body ? TRUE : FALSE;
}

void Curl_http_acc_req_set_no_body(struct Curl_easy *data, bool v)
{
  data->req.no_body = v;
}

bool Curl_http_acc_req_authneg(struct Curl_easy *data)
{
  return data->req.authneg ? TRUE : FALSE;
}

void Curl_http_acc_req_set_authneg(struct Curl_easy *data, bool v)
{
  data->req.authneg = v;
}

bool Curl_http_acc_req_ignorebody(struct Curl_easy *data)
{
  return data->req.ignorebody ? TRUE : FALSE;
}

void Curl_http_acc_req_set_ignorebody(struct Curl_easy *data, bool v)
{
  data->req.ignorebody = v;
}

bool Curl_http_acc_req_http_bodyless(struct Curl_easy *data)
{
  return data->req.http_bodyless ? TRUE : FALSE;
}

void Curl_http_acc_req_set_http_bodyless(struct Curl_easy *data, bool v)
{
  data->req.http_bodyless = v;
}

bool Curl_http_acc_req_ignore_cl(struct Curl_easy *data)
{
  return data->req.ignore_cl ? TRUE : FALSE;
}

void Curl_http_acc_req_set_ignore_cl(struct Curl_easy *data, bool v)
{
  data->req.ignore_cl = v;
}

void Curl_http_acc_req_set_resp_trailer(struct Curl_easy *data, bool v)
{
  data->req.resp_trailer = v;
}

bool Curl_http_acc_req_want_recv(struct Curl_easy *data)
{
  return CURL_REQ_WANT_RECV(data) ? TRUE : FALSE;
}

void Curl_http_acc_req_clear_recv(struct Curl_easy *data)
{
  CURL_REQ_CLEAR_RECV(data);
}

void Curl_http_acc_req_set_send(struct Curl_easy *data)
{
  CURL_REQ_SET_SEND(data);
}

CURLcode Curl_http_acc_req_soft_reset(struct Curl_easy *data)
{
  return Curl_req_soft_reset(&data->req, data);
}

int Curl_http_acc_info_httpcode(struct Curl_easy *data)
{
  return data->info.httpcode;
}

void Curl_http_acc_info_set_httpcode(struct Curl_easy *data, int v)
{
  data->info.httpcode = v;
}

void Curl_http_acc_info_set_httpversion(struct Curl_easy *data, int v)
{
  data->info.httpversion = v;
}

uint32_t *Curl_http_acc_info_authpicked_ptr(struct Curl_easy *data, bool proxy)
{
  return proxy ? &data->info.proxyauthpicked : &data->info.httpauthpicked;
}

uint32_t *Curl_http_acc_info_authavail_ptr(struct Curl_easy *data, bool proxy)
{
  return proxy ? &data->info.proxyauthavail : &data->info.httpauthavail;
}

void Curl_http_acc_info_set_filetime(struct Curl_easy *data, time_t v)
{
  data->info.filetime = v;
}

void Curl_http_acc_info_set_timecond(struct Curl_easy *data, bool v)
{
  data->info.timecond = v;
}

void Curl_http_acc_info_set_contenttype(struct Curl_easy *data, char *v)
{
  curlx_free(data->info.contenttype);
  data->info.contenttype = v;
}

void Curl_http_acc_info_set_wouldredirect(struct Curl_easy *data, char *v)
{
  curlx_free(data->info.wouldredirect);
  data->info.wouldredirect = v;
}

void Curl_http_acc_info_set_retry_after(struct Curl_easy *data, time_t v)
{
  data->info.retry_after = v;
}

curl_off_t Curl_http_acc_info_header_size(struct Curl_easy *data)
{
  return data->info.header_size;
}

void Curl_http_acc_info_set_header_size(struct Curl_easy *data, curl_off_t v)
{
  data->info.header_size = v;
}

CURLcode Curl_http_acc_input_negotiate(struct Curl_easy *data,
                                       struct connectdata *conn,
                                       bool proxy, const char *header)
{
#ifdef USE_SPNEGO
  return Curl_input_negotiate(data, conn, proxy, header);
#else
  (void)data;
  (void)conn;
  (void)proxy;
  (void)header;
  return CURLE_NOT_BUILT_IN;
#endif
}

void Curl_http_acc_conn_set_nego_recv(struct connectdata *conn, bool proxy)
{
#ifdef USE_SPNEGO
  if(proxy)
    conn->proxy_negotiate_state = CURL_NEGO_AUTH_RECV;
  else
    conn->http_negotiate_state = CURL_NEGO_AUTH_RECV;
#else
  (void)conn;
  (void)proxy;
#endif
}

CURLcode Curl_http_acc_output_negotiate(struct Curl_easy *data,
                                        struct connectdata *conn, bool proxy)
{
#ifdef USE_SPNEGO
  return Curl_output_negotiate(data, conn, proxy);
#else
  (void)data;
  (void)conn;
  (void)proxy;
  return CURLE_NOT_BUILT_IN;
#endif
}

CURLcode Curl_http_acc_input_ntlm(struct Curl_easy *data,
                                  bool proxy, const char *header)
{
#ifdef USE_NTLM
  return Curl_input_ntlm(data, proxy, header);
#else
  (void)data;
  (void)proxy;
  (void)header;
  return CURLE_NOT_BUILT_IN;
#endif
}

CURLcode Curl_http_acc_output_ntlm(struct Curl_easy *data, bool proxy)
{
#ifdef USE_NTLM
  return Curl_output_ntlm(data, proxy);
#else
  (void)data;
  (void)proxy;
  return CURLE_NOT_BUILT_IN;
#endif
}

bool Curl_http_acc_is_ntlm_supported(void)
{
#ifdef USE_NTLM
  return Curl_auth_is_ntlm_supported() ? TRUE : FALSE;
#else
  return FALSE;
#endif
}

bool Curl_http_acc_is_spnego_supported(void)
{
#ifdef USE_SPNEGO
  return Curl_auth_is_spnego_supported() ? TRUE : FALSE;
#else
  return FALSE;
#endif
}

bool Curl_http_acc_is_digest_supported(void)
{
#ifndef CURL_DISABLE_DIGEST_AUTH
  return Curl_auth_is_digest_supported() ? TRUE : FALSE;
#else
  return FALSE;
#endif
}

CURLcode Curl_http_acc_input_digest(struct Curl_easy *data,
                                    bool proxy, const char *header)
{
#ifndef CURL_DISABLE_DIGEST_AUTH
  return Curl_input_digest(data, proxy, header);
#else
  (void)data;
  (void)proxy;
  (void)header;
  return CURLE_NOT_BUILT_IN;
#endif
}

CURLcode Curl_http_acc_output_digest(struct Curl_easy *data,
                                     bool proxy,
                                     const unsigned char *request,
                                     const unsigned char *uripath)
{
#ifndef CURL_DISABLE_DIGEST_AUTH
  return Curl_output_digest(data, proxy, request, uripath);
#else
  (void)data;
  (void)proxy;
  (void)request;
  (void)uripath;
  return CURLE_NOT_BUILT_IN;
#endif
}

void Curl_http_acc_digest_cleanup(struct Curl_easy *data)
{
#ifndef CURL_DISABLE_DIGEST_AUTH
  Curl_auth_digest_cleanup(&data->state.digest);
#else
  (void)data;
#endif
}

CURLcode Curl_http_acc_output_aws_sigv4(struct Curl_easy *data)
{
#ifndef CURL_DISABLE_AWS
  return Curl_output_aws_sigv4(data);
#else
  (void)data;
  return CURLE_NOT_BUILT_IN;
#endif
}

CURLcode Curl_http_acc_output_httpsig(struct Curl_easy *data)
{
#ifndef CURL_DISABLE_HTTPSIG
  return Curl_output_httpsig(data);
#else
  (void)data;
  return CURLE_NOT_BUILT_IN;
#endif
}

CURLcode Curl_http_acc_headers_init(struct Curl_easy *data)
{
  return Curl_headers_init(data);
}

CURLcode Curl_http_acc_http_cookies(struct Curl_easy *data, struct dynbuf *r)
{
#ifndef CURL_DISABLE_COOKIES
  CURLcode result = CURLE_OK;
  const char *addcookies = NULL;
  bool linecap = FALSE;
  if(CURL_EASY_STR(data, STRING_COOKIE) &&
     !Curl_checkheaders(data, STRCONST("Cookie")) &&
     Curl_auth_allowed_to_host(data))
    addcookies = CURL_EASY_STR(data, STRING_COOKIE);

  if(data->cookies || addcookies) {
    struct Curl_llist list;
    int count = 0;

    if(data->cookies && data->state.cookie_engine) {
      bool okay;
      const char *host = data->req.cookiehost ?
        data->req.cookiehost : data->state.origin->hostname;
      Curl_share_lock(data, CURL_LOCK_DATA_COOKIE, CURL_LOCK_ACCESS_SINGLE);
      result = Curl_cookie_getlist(data, &okay, host, &list);
      if(!result && okay) {
        struct Curl_llist_node *n;
        size_t clen = 8; /* hold the size of the generated Cookie: header */

        for(n = Curl_llist_head(&list); n; n = Curl_node_next(n)) {
          struct Cookie *co = Curl_node_elem(n);
          if(co->value) {
            size_t add;
            if(!count) {
              result = curlx_dyn_addn(r, STRCONST("Cookie: "));
              if(result)
                break;
            }
            add = strlen(co->name) + strlen(co->value) + 1;
            if(clen + add >= MAX_COOKIE_HEADER_LEN) {
              infof(data, "Restricted outgoing cookies due to header size, "
                    "'%s' not sent", co->name);
              linecap = TRUE;
              break;
            }
            result = curlx_dyn_addf(r, "%s%s=%s", count ? "; " : "",
                                    co->name, co->value);
            if(result)
              break;
            clen += add + (count ? 2 : 0);
            count++;
          }
        }
        Curl_llist_destroy(&list, NULL);
      }
      Curl_share_unlock(data, CURL_LOCK_DATA_COOKIE);
    }
    if(addcookies && !result && !linecap) {
      if(!count)
        result = curlx_dyn_addn(r, STRCONST("Cookie: "));
      if(!result) {
        result = curlx_dyn_addf(r, "%s%s", count ? "; " : "", addcookies);
        count++;
      }
    }
    if(count && !result)
      result = curlx_dyn_addn(r, STRCONST("\r\n"));

    if(result)
      return result;
  }
  return result;
#else
  (void)data;
  (void)r;
  return CURLE_OK;
#endif
}

CURLcode Curl_http_acc_cookie_add(struct Curl_easy *data, const char *v)
{
#ifndef CURL_DISABLE_COOKIES
  const char *host = data->req.cookiehost ?
    data->req.cookiehost : data->state.origin->hostname;
  const unsigned char secure_context = Curl_secure_context(data, host) ?
    COOKIE_SECURE : 0;
  CURLcode result;
  Curl_share_lock(data, CURL_LOCK_DATA_COOKIE, CURL_LOCK_ACCESS_SINGLE);
  result = Curl_cookie_add(data, data->cookies, v, host,
                           data->state.up.path,
                           COOKIE_HTTPHEADER | secure_context);
  Curl_share_unlock(data, CURL_LOCK_DATA_COOKIE);
  return result;
#else
  (void)data;
  (void)v;
  return CURLE_OK;
#endif
}

bool Curl_http_acc_has_cookie_engine(struct Curl_easy *data)
{
#ifndef CURL_DISABLE_COOKIES
  return (data->cookies && data->state.cookie_engine) ? TRUE : FALSE;
#else
  (void)data;
  return FALSE;
#endif
}

CURLcode Curl_http_acc_altsvc_header(struct Curl_easy *data,
                                     const char *hd, size_t hdlen)
{
#ifndef CURL_DISABLE_ALTSVC
  const char *v = (data->asi &&
                   (Curl_xfer_is_secure(data) ||
#ifdef DEBUGBUILD
                    getenv("CURL_ALTSVC_HTTP")
#else
                    0
#endif
                     ) &&
                   (hdlen >= (sizeof("Alt-Svc:") - 1)) && hd &&
                   curl_strnequal("Alt-Svc:", hd, sizeof("Alt-Svc:") - 1)) ?
    (hd + (sizeof("Alt-Svc:") - 1)) : NULL;
  if(v) {
    struct SingleRequest *k = &data->req;
    enum alpnid id = (k->httpversion == 30) ? ALPN_h3 :
      (k->httpversion == 20) ? ALPN_h2 : ALPN_h1;
    return Curl_altsvc_parse(data, data->asi, v, data->state.origin, id);
  }
#else
  (void)data;
  (void)hd;
  (void)hdlen;
#endif
  return CURLE_OK;
}

CURLcode Curl_http_acc_hsts_header(struct Curl_easy *data,
                                   const char *hd, size_t hdlen)
{
#ifndef CURL_DISABLE_HSTS
  const char *v = (data->hsts &&
                   (Curl_xfer_is_secure(data) ||
#ifdef DEBUGBUILD
                    getenv("CURL_HSTS_HTTP")
#else
                    0
#endif
                     ) &&
                   (hdlen >= (sizeof("Strict-Transport-Security:") - 1)) &&
                   hd &&
                   curl_strnequal("Strict-Transport-Security:", hd,
                                  sizeof("Strict-Transport-Security:") - 1)) ?
    (hd + (sizeof("Strict-Transport-Security:") - 1)) : NULL;
  if(v) {
    CURLcode result = Curl_hsts_parse(
      data->hsts, data->state.origin->hostname, v);
    if(result) {
      if(result == CURLE_OUT_OF_MEMORY)
        return result;
      infof(data, "Illegal STS header skipped");
    }
#ifdef DEBUGBUILD
    else
      infof(data, "Parsed STS header fine (%zu entries)",
            Curl_llist_count(&data->hsts->list));
#endif
  }
#else
  (void)data;
  (void)hd;
  (void)hdlen;
#endif
  return CURLE_OK;
}

CURLcode Curl_http_acc_persistent_auth(struct Curl_easy *data,
                                       const char *hd, size_t hdlen)
{
#ifdef USE_SPNEGO
  if((hdlen >= (sizeof("Persistent-Auth:") - 1)) &&
     curl_strnequal("Persistent-Auth:", hd, sizeof("Persistent-Auth:") - 1)) {
    struct connectdata *conn = data->conn;
    struct negotiatedata *negdata = Curl_auth_nego_get(conn, FALSE);
    struct auth *authp = &data->state.authhost;
    if(!negdata)
      return CURLE_OUT_OF_MEMORY;
    if(authp->picked == CURLAUTH_NEGOTIATE) {
      char *persistentauth = Curl_copy_header_value(hd);
      if(!persistentauth)
        return CURLE_OUT_OF_MEMORY;
      negdata->noauthpersist = !!checkprefix("false", persistentauth);
      negdata->havenoauthpersist = TRUE;
      infof(data, "Negotiate: noauthpersist -> %d, header part: %s",
            negdata->noauthpersist, persistentauth);
      curlx_free(persistentauth);
    }
  }
#else
  (void)data;
  (void)hd;
  (void)hdlen;
#endif
  return CURLE_OK;
}

void Curl_http_acc_check_auth_closure(struct Curl_easy *data,
                                      struct connectdata *conn)
{
#ifdef USE_NTLM
  if(conn->bits.close &&
     (((data->req.httpcode == 401) &&
       (conn->http_ntlm_state == NTLMSTATE_TYPE2)) ||
      ((data->req.httpcode == 407) &&
       (conn->proxy_ntlm_state == NTLMSTATE_TYPE2)))) {
    infof(data, "Connection closure while negotiating auth (HTTP 1.0?)");
    data->state.authproblem = TRUE;
  }
#endif
#ifdef USE_SPNEGO
  if(conn->bits.close &&
    (((data->req.httpcode == 401) &&
      (conn->http_negotiate_state == CURL_NEGO_AUTH_RECV)) ||
     ((data->req.httpcode == 407) &&
      (conn->proxy_negotiate_state == CURL_NEGO_AUTH_RECV)))) {
    infof(data, "Connection closure while negotiating auth (HTTP 1.0?)");
    data->state.authproblem = TRUE;
  }
  if((conn->http_negotiate_state == CURL_NEGO_AUTH_DONE) &&
     (data->req.httpcode != 401)) {
    conn->http_negotiate_state = CURL_NEGO_AUTH_SUCC;
  }
  if((conn->proxy_negotiate_state == CURL_NEGO_AUTH_DONE) &&
     (data->req.httpcode != 407)) {
    conn->proxy_negotiate_state = CURL_NEGO_AUTH_SUCC;
  }
#endif
  (void)data;
  (void)conn;
}

bool Curl_http_acc_perhapsrewind_auth_check(struct Curl_easy *data,
                                            struct connectdata *conn,
                                            const char **pongoing_auth)
{
  bool abort_upload = TRUE;
  *pongoing_auth = NULL;
#ifdef USE_NTLM
  if((data->state.authproxy.picked == CURLAUTH_NTLM) ||
     (data->state.authhost.picked == CURLAUTH_NTLM)) {
    VERBOSE(*pongoing_auth = "NTLM");
    if((conn->http_ntlm_state != NTLMSTATE_NONE) ||
       (conn->proxy_ntlm_state != NTLMSTATE_NONE)) {
      abort_upload = FALSE;
    }
  }
#endif
#ifdef USE_SPNEGO
  if((data->state.authproxy.picked == CURLAUTH_NEGOTIATE) ||
     (data->state.authhost.picked == CURLAUTH_NEGOTIATE)) {
    VERBOSE(*pongoing_auth = "NEGOTIATE");
    if((conn->http_negotiate_state != CURL_NEGO_AUTH_NONE) ||
       (conn->proxy_negotiate_state != CURL_NEGO_AUTH_NONE)) {
      abort_upload = FALSE;
    }
  }
#endif
  (void)data;
  (void)conn;
  return abort_upload;
}

CURLcode Curl_http_acc_set_post_reader(struct Curl_easy *data,
                                       Curl_HttpReq httpreq)
{
#if !defined(CURL_DISABLE_MIME) || !defined(CURL_DISABLE_FORM_API)
  CURLcode result;

  switch(httpreq) {
#ifndef CURL_DISABLE_MIME
  case HTTPREQ_POST_MIME:
    data->state.mimepost = data->set.mimepostp;
    break;
#endif
#ifndef CURL_DISABLE_FORM_API
  case HTTPREQ_POST_FORM:
    if(!data->state.formp) {
      data->state.formp = curlx_calloc(1, sizeof(curl_mimepart));
      if(!data->state.formp)
        return CURLE_OUT_OF_MEMORY;
      Curl_mime_cleanpart(data->state.formp);
      result = Curl_getformdata(data, data->state.formp, data->set.httppost,
                                data->state.fread_func);
      if(result) {
        curlx_safefree(data->state.formp);
        return result;
      }
      data->state.mimepost = data->state.formp;
    }
    break;
#endif
  default:
    data->state.mimepost = NULL;
    break;
  }

  switch(httpreq) {
  case HTTPREQ_POST_FORM:
  case HTTPREQ_POST_MIME:
#ifndef CURL_DISABLE_MIME
    if(data->state.mimepost) {
      const char *cthdr = Curl_checkheaders(data, STRCONST("Content-Type"));
      data->state.mimepost->flags |= MIME_BODY_ONLY;
      if(cthdr)
        for(cthdr += 13; *cthdr == ' '; cthdr++)
          ;
      else if(data->state.mimepost->kind == MIMEKIND_MULTIPART)
        cthdr = "multipart/form-data";

      curl_mime_headers(data->state.mimepost, data->set.headers, 0);
      result = Curl_mime_prepare_headers(data, data->state.mimepost, cthdr,
                                         NULL, MIMESTRATEGY_FORM);
      if(result)
        return result;
      curl_mime_headers(data->state.mimepost, NULL, 0);
      result = Curl_creader_set_mime(data, data->state.mimepost);
      if(result)
        return result;
    }
    else
#endif
    {
      result = Curl_creader_set_null(data);
    }
    data->state.infilesize = Curl_creader_total_length(data);
    return result;

  default:
    return Curl_creader_set_null(data);
  }
#else
  (void)httpreq;
  return Curl_creader_set_null(data);
#endif
}

struct curl_slist *Curl_http_acc_mimepost_curlheaders(struct Curl_easy *data)
{
#ifndef CURL_DISABLE_MIME
  return data->state.mimepost ? data->state.mimepost->curlheaders : NULL;
#else
  (void)data;
  return NULL;
#endif
}

/* http_negotiation helpers */
void Curl_http_acc_neg_zero(struct http_negotiation *neg);
unsigned char Curl_http_acc_neg_wanted(const struct http_negotiation *neg);
void Curl_http_acc_neg_set_wanted(struct http_negotiation *neg,
                                  unsigned char v);
unsigned char Curl_http_acc_neg_allowed(const struct http_negotiation *neg);
void Curl_http_acc_neg_set_allowed(struct http_negotiation *neg,
                                   unsigned char v);
unsigned char Curl_http_acc_neg_preferred(const struct http_negotiation *neg);
void Curl_http_acc_neg_set_preferred(struct http_negotiation *neg,
                                     unsigned char v);
unsigned char Curl_http_acc_neg_rcvd_min(const struct http_negotiation *neg);
void Curl_http_acc_neg_set_rcvd_min(struct http_negotiation *neg,
                                    unsigned char v);
bool Curl_http_acc_neg_h2_upgrade(const struct http_negotiation *neg);
void Curl_http_acc_neg_set_h2_upgrade(struct http_negotiation *neg, bool v);
bool Curl_http_acc_neg_h2_prior_knowledge(const struct http_negotiation *neg);
void Curl_http_acc_neg_set_h2_prior_knowledge(struct http_negotiation *neg,
                                              bool v);
bool Curl_http_acc_neg_accept_09(const struct http_negotiation *neg);
void Curl_http_acc_neg_set_accept_09(struct http_negotiation *neg, bool v);
bool Curl_http_acc_neg_only_10(const struct http_negotiation *neg);
void Curl_http_acc_neg_set_only_10(struct http_negotiation *neg, bool v);

/* struct auth helpers */
uint32_t Curl_http_acc_auth_want(const struct auth *a);
void Curl_http_acc_auth_set_want(struct auth *a, uint32_t v);
uint32_t Curl_http_acc_auth_picked(const struct auth *a);
void Curl_http_acc_auth_set_picked(struct auth *a, uint32_t v);
uint32_t Curl_http_acc_auth_avail(const struct auth *a);
void Curl_http_acc_auth_set_avail(struct auth *a, uint32_t v);
bool Curl_http_acc_auth_done(const struct auth *a);
void Curl_http_acc_auth_set_done(struct auth *a, bool v);
bool Curl_http_acc_auth_multipass(const struct auth *a);
void Curl_http_acc_auth_set_multipass(struct auth *a, bool v);

/* Specific set.str helpers */
char *Curl_http_acc_str_cookie(struct Curl_easy *data);
char *Curl_http_acc_str_customrequest(struct Curl_easy *data);
char *Curl_http_acc_str_encoding(struct Curl_easy *data);
char *Curl_http_acc_str_useragent(struct Curl_easy *data);
char *Curl_http_acc_str_target(struct Curl_easy *data);
bool Curl_http_acc_creds_from_url(const struct Curl_creds *creds);

void Curl_http_acc_neg_zero(struct http_negotiation *neg)
{
  memset(neg, 0, sizeof(*neg));
}
unsigned char Curl_http_acc_neg_wanted(const struct http_negotiation *neg)
{
  return neg->wanted;
}
void Curl_http_acc_neg_set_wanted(struct http_negotiation *neg,
                                  unsigned char v)
{
  neg->wanted = v;
}
unsigned char Curl_http_acc_neg_allowed(const struct http_negotiation *neg)
{
  return neg->allowed;
}
void Curl_http_acc_neg_set_allowed(struct http_negotiation *neg,
                                   unsigned char v)
{
  neg->allowed = v;
}
unsigned char Curl_http_acc_neg_preferred(const struct http_negotiation *neg)
{
  return neg->preferred;
}
void Curl_http_acc_neg_set_preferred(struct http_negotiation *neg,
                                     unsigned char v)
{
  neg->preferred = v;
}
unsigned char Curl_http_acc_neg_rcvd_min(const struct http_negotiation *neg)
{
  return neg->rcvd_min;
}
void Curl_http_acc_neg_set_rcvd_min(struct http_negotiation *neg,
                                    unsigned char v)
{
  neg->rcvd_min = v;
}
bool Curl_http_acc_neg_h2_upgrade(const struct http_negotiation *neg)
{
  return neg->h2_upgrade;
}
void Curl_http_acc_neg_set_h2_upgrade(struct http_negotiation *neg, bool v)
{
  neg->h2_upgrade = v;
}
bool Curl_http_acc_neg_h2_prior_knowledge(const struct http_negotiation *neg)
{
  return neg->h2_prior_knowledge;
}
void Curl_http_acc_neg_set_h2_prior_knowledge(struct http_negotiation *neg,
                                              bool v)
{
  neg->h2_prior_knowledge = v;
}
bool Curl_http_acc_neg_accept_09(const struct http_negotiation *neg)
{
  return neg->accept_09;
}
void Curl_http_acc_neg_set_accept_09(struct http_negotiation *neg, bool v)
{
  neg->accept_09 = v;
}
bool Curl_http_acc_neg_only_10(const struct http_negotiation *neg)
{
  return neg->only_10;
}
void Curl_http_acc_neg_set_only_10(struct http_negotiation *neg, bool v)
{
  neg->only_10 = v;
}

uint32_t Curl_http_acc_auth_want(const struct auth *a)
{
  return a->want;
}
void Curl_http_acc_auth_set_want(struct auth *a, uint32_t v)
{
  a->want = v;
}
uint32_t Curl_http_acc_auth_picked(const struct auth *a)
{
  return a->picked;
}
void Curl_http_acc_auth_set_picked(struct auth *a, uint32_t v)
{
  a->picked = v;
}
uint32_t Curl_http_acc_auth_avail(const struct auth *a)
{
  return a->avail;
}
void Curl_http_acc_auth_set_avail(struct auth *a, uint32_t v)
{
  a->avail = v;
}
bool Curl_http_acc_auth_done(const struct auth *a)
{
  return a->done;
}
void Curl_http_acc_auth_set_done(struct auth *a, bool v)
{
  a->done = v;
}
bool Curl_http_acc_auth_multipass(const struct auth *a)
{
  return a->multipass;
}
void Curl_http_acc_auth_set_multipass(struct auth *a, bool v)
{
  a->multipass = v;
}

char *Curl_http_acc_str_cookie(struct Curl_easy *data)
{
  return (char *)CURL_EASY_STR(data, STRING_COOKIE);
}
char *Curl_http_acc_str_customrequest(struct Curl_easy *data)
{
  return (char *)CURL_EASY_STR(data, STRING_CUSTOMREQUEST);
}
char *Curl_http_acc_str_encoding(struct Curl_easy *data)
{
  return (char *)CURL_EASY_STR(data, STRING_ENCODING);
}
char *Curl_http_acc_str_useragent(struct Curl_easy *data)
{
  return (char *)CURL_EASY_STR(data, STRING_USERAGENT);
}
char *Curl_http_acc_str_target(struct Curl_easy *data)
{
  return (char *)CURL_EASY_STR(data, STRING_TARGET);
}
bool Curl_http_acc_creds_from_url(const struct Curl_creds *creds)
{
  return (creds && creds->source == CREDS_URL) ? TRUE : FALSE;
}

bool Curl_http_acc_http2_may_switch(struct Curl_easy *data)
{
#ifdef USE_HTTP2
  return Curl_http2_may_switch(data) ? TRUE : FALSE;
#else
  (void)data;
  return FALSE;
#endif
}

CURLcode Curl_http_acc_http2_switch(struct Curl_easy *data)
{
#ifdef USE_HTTP2
  return Curl_http2_switch(data);
#else
  (void)data;
  return CURLE_NOT_BUILT_IN;
#endif
}

CURLcode Curl_http_acc_http2_request_upgrade(struct dynbuf *req,
                                             struct Curl_easy *data)
{
#ifdef USE_HTTP2
  return Curl_http2_request_upgrade(req, data);
#else
  (void)req;
  (void)data;
  return CURLE_NOT_BUILT_IN;
#endif
}

CURLcode Curl_http_acc_http2_upgrade(struct Curl_easy *data,
                                     struct connectdata *conn,
                                     const char *mem, size_t nread)
{
#ifdef USE_NGHTTP2
  return Curl_http2_upgrade(data, conn, FIRSTSOCKET, mem, nread);
#else
  (void)data;
  (void)conn;
  (void)mem;
  (void)nread;
  return CURLE_NOT_BUILT_IN;
#endif
}

CURLcode Curl_http_acc_ws_request(struct Curl_easy *data, struct dynbuf *req)
{
#ifndef CURL_DISABLE_WEBSOCKETS
  return Curl_ws_request(data, req);
#else
  (void)data;
  (void)req;
  return CURLE_OK;
#endif
}

CURLcode Curl_http_acc_ws_accept(struct Curl_easy *data,
                                 const char *mem, size_t nread)
{
#ifndef CURL_DISABLE_WEBSOCKETS
  return Curl_ws_accept(data, mem, nread);
#else
  (void)data;
  (void)mem;
  (void)nread;
  return CURLE_NOT_BUILT_IN;
#endif
}

CURLcode Curl_http_acc_rtsp_parseheader(struct Curl_easy *data,
                                        const char *hd)
{
#ifndef CURL_DISABLE_RTSP
  return Curl_rtsp_parseheader(data, hd);
#else
  (void)data;
  (void)hd;
  return CURLE_OK;
#endif
}

curl_off_t Curl_http_acc_current_time(void)
{
  return (curl_off_t)time(NULL);
}

/* =========================================================================
 * C-Zig ABI & Struct Layout Compile-Time Assertions and Size Helpers
 * ========================================================================= */
#include <stddef.h>
#include "api.h"
#include "multi_ev.h"
#include "protocol.h"
#include "vdns/asyn.h"

/* 1. API recursion stack & guard layouts (lib/api.h) */
_Static_assert(CURL_EAPI_MAX_RECURSION == 7, "CURL_EAPI_MAX_RECURSION");
_Static_assert(sizeof(struct Curl_eapi_stack) == 16, "sizeof(Curl_eapi_stack)");
_Static_assert(_Alignof(struct Curl_eapi_stack) == 2, "alignof(Curl_eapi_stack)");
_Static_assert(offsetof(struct Curl_eapi_stack, count) == 0, "Curl_eapi_stack.count");
_Static_assert(offsetof(struct Curl_eapi_stack, calls) == 2, "Curl_eapi_stack.calls");

_Static_assert(sizeof(struct Curl_eapi_guard) == 16, "sizeof(Curl_eapi_guard)");
_Static_assert(_Alignof(struct Curl_eapi_guard) == 8, "alignof(Curl_eapi_guard)");
_Static_assert(offsetof(struct Curl_eapi_guard, data) == 0, "Curl_eapi_guard.data");
_Static_assert(offsetof(struct Curl_eapi_guard, depth) == 8, "Curl_eapi_guard.depth");

_Static_assert(CURL_MAPI_MAX_RECURSION == 15, "CURL_MAPI_MAX_RECURSION");
_Static_assert(sizeof(struct Curl_mapi_stack) == 16, "sizeof(Curl_mapi_stack)");
_Static_assert(_Alignof(struct Curl_mapi_stack) == 1, "alignof(Curl_mapi_stack)");
_Static_assert(offsetof(struct Curl_mapi_stack, count) == 0, "Curl_mapi_stack.count");
_Static_assert(offsetof(struct Curl_mapi_stack, calls) == 1, "Curl_mapi_stack.calls");

_Static_assert(sizeof(struct Curl_mapi_guard) == 16, "sizeof(Curl_mapi_guard)");
_Static_assert(_Alignof(struct Curl_mapi_guard) == 8, "alignof(Curl_mapi_guard)");
_Static_assert(offsetof(struct Curl_mapi_guard, multi) == 0, "Curl_mapi_guard.multi");
_Static_assert(offsetof(struct Curl_mapi_guard, depth) == 8, "Curl_mapi_guard.depth");

/* 2. Curl_easy prefix layout matching CurlEasyPrefix */
_Static_assert(_Alignof(struct Curl_easy) == 8, "alignof(Curl_easy)");
_Static_assert(offsetof(struct Curl_easy, magic) == 0, "Curl_easy.magic");
_Static_assert(offsetof(struct Curl_easy, mid) == 4, "Curl_easy.mid");
_Static_assert(offsetof(struct Curl_easy, mstate) == 8, "Curl_easy.mstate");
_Static_assert(offsetof(struct Curl_easy, result) == 12, "Curl_easy.result");
_Static_assert(offsetof(struct Curl_easy, conn) == 16, "Curl_easy.conn");
_Static_assert(offsetof(struct Curl_easy, multi) == 24, "Curl_easy.multi");
_Static_assert(offsetof(struct Curl_easy, callstack) == 32, "Curl_easy.callstack");
_Static_assert(offsetof(struct Curl_easy, callstack) +
               sizeof(struct Curl_eapi_stack) == 48, "sizeof(CurlEasyPrefix)");

/* 3. Curl_multi prefix layout matching CurlMultiPrefix */
_Static_assert(_Alignof(struct Curl_multi) == 8, "alignof(Curl_multi)");
_Static_assert(offsetof(struct Curl_multi, magic) == 0, "Curl_multi.magic");
_Static_assert(offsetof(struct Curl_multi, xfers_alive) == 4, "Curl_multi.xfers_alive");
_Static_assert(offsetof(struct Curl_multi, xfers_really_alive) == 8, "Curl_multi.xfers_really_alive");
_Static_assert(offsetof(struct Curl_multi, max_concurrent_streams) == 12, "Curl_multi.max_concurrent_streams");
_Static_assert(offsetof(struct Curl_multi, xfers_total_ever) == 16, "Curl_multi.xfers_total_ever");
_Static_assert(offsetof(struct Curl_multi, xfers) == 24, "Curl_multi.xfers");
_Static_assert(offsetof(struct Curl_multi, process) == 48, "Curl_multi.process");
_Static_assert(offsetof(struct Curl_multi, dirty) == 64, "Curl_multi.dirty");
_Static_assert(offsetof(struct Curl_multi, pending) == 80, "Curl_multi.pending");
_Static_assert(offsetof(struct Curl_multi, msgsent) == 96, "Curl_multi.msgsent");
_Static_assert(offsetof(struct Curl_multi, callstack) == 112, "Curl_multi.callstack");
_Static_assert(offsetof(struct Curl_multi, timeouts) == 128, "Curl_multi.timeouts");
_Static_assert(offsetof(struct Curl_multi, admin) == 144, "Curl_multi.admin");
_Static_assert(offsetof(struct Curl_multi, socket_cb) == 152, "Curl_multi.socket_cb");
_Static_assert(offsetof(struct Curl_multi, socket_userp) == 160, "Curl_multi.socket_userp");
_Static_assert(offsetof(struct Curl_multi, push_cb) == 168, "Curl_multi.push_cb");
_Static_assert(offsetof(struct Curl_multi, push_userp) == 176, "Curl_multi.push_userp");
_Static_assert(offsetof(struct Curl_multi, dnscache) == 184, "Curl_multi.dnscache");
_Static_assert(offsetof(struct Curl_multi, ssl_scache) == 224, "Curl_multi.ssl_scache");
_Static_assert(offsetof(struct Curl_multi, ssl_scache) +
               sizeof(struct Curl_ssl_scache *) == 232, "sizeof(CurlMultiPrefix)");

/* 4. PureInfo prefix and Curl_getinfo_ctx layout matching CurlGetinfoCtx */
_Static_assert(offsetof(struct PureInfo, primary) == 0, "PureInfo.primary");
_Static_assert(offsetof(struct PureInfo, certs) == 104, "PureInfo.certs");
_Static_assert(offsetof(struct PureInfo, filetime) == 120, "PureInfo.filetime");
_Static_assert(offsetof(struct PureInfo, request_size) == 128, "PureInfo.request_size");
_Static_assert(offsetof(struct PureInfo, numconnects) == 136, "PureInfo.numconnects");
_Static_assert(offsetof(struct PureInfo, contenttype) == 144, "PureInfo.contenttype");
_Static_assert(offsetof(struct PureInfo, wouldredirect) == 152, "PureInfo.wouldredirect");
_Static_assert(offsetof(struct PureInfo, effective_url) == 160, "PureInfo.effective_url");
_Static_assert(offsetof(struct PureInfo, retry_after) == 168, "PureInfo.retry_after");
_Static_assert(offsetof(struct PureInfo, conn_scheme) == 176, "PureInfo.conn_scheme");
_Static_assert(offsetof(struct PureInfo, httpcode) == 184, "PureInfo.httpcode");
_Static_assert(offsetof(struct PureInfo, httpproxycode) == 188, "PureInfo.httpproxycode");
_Static_assert(offsetof(struct PureInfo, httpversion) == 192, "PureInfo.httpversion");
_Static_assert(offsetof(struct PureInfo, conn_protocol) == 196, "PureInfo.conn_protocol");
_Static_assert(offsetof(struct PureInfo, proxyauthavail) == 200, "PureInfo.proxyauthavail");
_Static_assert(offsetof(struct PureInfo, httpauthavail) == 204, "PureInfo.httpauthavail");
_Static_assert(offsetof(struct PureInfo, proxyauthpicked) == 208, "PureInfo.proxyauthpicked");
_Static_assert(offsetof(struct PureInfo, httpauthpicked) == 212, "PureInfo.httpauthpicked");
_Static_assert(offsetof(struct PureInfo, header_size) == 216, "PureInfo.header_size");
_Static_assert(offsetof(struct PureInfo, pxcode) == 220, "PureInfo.pxcode");

_Static_assert(sizeof(struct Curl_getinfo_ctx) == 264 + 2 * sizeof(long), "sizeof(Curl_getinfo_ctx)");
_Static_assert(_Alignof(struct Curl_getinfo_ctx) == 8, "alignof(Curl_getinfo_ctx)");
_Static_assert(offsetof(struct Curl_getinfo_ctx, info) == 0, "Curl_getinfo_ctx.info");
_Static_assert(offsetof(struct Curl_getinfo_ctx, tsi) == 8, "Curl_getinfo_ctx.tsi");
_Static_assert(offsetof(struct Curl_getinfo_ctx, url_str) == 16, "Curl_getinfo_ctx.url_str");
_Static_assert(offsetof(struct Curl_getinfo_ctx, referer_str) == 24, "Curl_getinfo_ctx.referer_str");
_Static_assert(offsetof(struct Curl_getinfo_ctx, custom_request) == 32, "Curl_getinfo_ctx.custom_request");
_Static_assert(offsetof(struct Curl_getinfo_ctx, ftp_entrypath) == 40, "Curl_getinfo_ctx.ftp_entrypath");
_Static_assert(offsetof(struct Curl_getinfo_ctx, rtsp_session_id) == 48, "Curl_getinfo_ctx.rtsp_session_id");
_Static_assert(offsetof(struct Curl_getinfo_ctx, cainfo_default) == 56, "Curl_getinfo_ctx.cainfo_default");
_Static_assert(offsetof(struct Curl_getinfo_ctx, capath_default) == 64, "Curl_getinfo_ctx.capath_default");
_Static_assert(offsetof(struct Curl_getinfo_ctx, private_data) == 72, "Curl_getinfo_ctx.private_data");
_Static_assert(offsetof(struct Curl_getinfo_ctx, xfer_id) == 80, "Curl_getinfo_ctx.xfer_id");
_Static_assert(offsetof(struct Curl_getinfo_ctx, last_conn_id) == 88, "Curl_getinfo_ctx.last_conn_id");
_Static_assert(offsetof(struct Curl_getinfo_ctx, deliver) == 96, "Curl_getinfo_ctx.deliver");
_Static_assert(offsetof(struct Curl_getinfo_ctx, earlydata_sent) == 104, "Curl_getinfo_ctx.earlydata_sent");
_Static_assert(offsetof(struct Curl_getinfo_ctx, ul_total_size) == 112, "Curl_getinfo_ctx.ul_total_size");
_Static_assert(offsetof(struct Curl_getinfo_ctx, ul_cur_size) == 120, "Curl_getinfo_ctx.ul_cur_size");
_Static_assert(offsetof(struct Curl_getinfo_ctx, ul_speed) == 128, "Curl_getinfo_ctx.ul_speed");
_Static_assert(offsetof(struct Curl_getinfo_ctx, dl_total_size) == 136, "Curl_getinfo_ctx.dl_total_size");
_Static_assert(offsetof(struct Curl_getinfo_ctx, dl_cur_size) == 144, "Curl_getinfo_ctx.dl_cur_size");
_Static_assert(offsetof(struct Curl_getinfo_ctx, dl_speed) == 152, "Curl_getinfo_ctx.dl_speed");
_Static_assert(offsetof(struct Curl_getinfo_ctx, spent_us) == 160, "Curl_getinfo_ctx.spent_us");
_Static_assert(offsetof(struct Curl_getinfo_ctx, queued_us) == 168, "Curl_getinfo_ctx.queued_us");
_Static_assert(offsetof(struct Curl_getinfo_ctx, nslookup_us) == 176, "Curl_getinfo_ctx.nslookup_us");
_Static_assert(offsetof(struct Curl_getinfo_ctx, connect_us) == 184, "Curl_getinfo_ctx.connect_us");
_Static_assert(offsetof(struct Curl_getinfo_ctx, appconnect_us) == 192, "Curl_getinfo_ctx.appconnect_us");
_Static_assert(offsetof(struct Curl_getinfo_ctx, pretransfer_us) == 200, "Curl_getinfo_ctx.pretransfer_us");
_Static_assert(offsetof(struct Curl_getinfo_ctx, starttransfer_us) == 208, "Curl_getinfo_ctx.starttransfer_us");
_Static_assert(offsetof(struct Curl_getinfo_ctx, posttransfer_us) == 216, "Curl_getinfo_ctx.posttransfer_us");
_Static_assert(offsetof(struct Curl_getinfo_ctx, startredirect_us) == 224, "Curl_getinfo_ctx.startredirect_us");
_Static_assert(offsetof(struct Curl_getinfo_ctx, ssl_verifyresult) == 232, "Curl_getinfo_ctx.ssl_verifyresult");
_Static_assert(offsetof(struct Curl_getinfo_ctx, proxy_ssl_verifyresult) == 232 + sizeof(long), "Curl_getinfo_ctx.proxy_ssl_verifyresult");
_Static_assert(offsetof(struct Curl_getinfo_ctx, rtsp_next_client_CSeq) == 232 + 2 * sizeof(long), "Curl_getinfo_ctx.rtsp_next_client_CSeq");
_Static_assert(offsetof(struct Curl_getinfo_ctx, rtsp_next_server_CSeq) == 236 + 2 * sizeof(long), "Curl_getinfo_ctx.rtsp_next_server_CSeq");
_Static_assert(offsetof(struct Curl_getinfo_ctx, rtsp_CSeq_recv) == 240 + 2 * sizeof(long), "Curl_getinfo_ctx.rtsp_CSeq_recv");
_Static_assert(offsetof(struct Curl_getinfo_ctx, os_errno) == 244 + 2 * sizeof(long), "Curl_getinfo_ctx.os_errno");
_Static_assert(offsetof(struct Curl_getinfo_ctx, followlocation) == 248 + 2 * sizeof(long), "Curl_getinfo_ctx.followlocation");
_Static_assert(offsetof(struct Curl_getinfo_ctx, httpreq) == 250 + 2 * sizeof(long), "Curl_getinfo_ctx.httpreq");
_Static_assert(offsetof(struct Curl_getinfo_ctx, path_as_is) == 251 + 2 * sizeof(long), "Curl_getinfo_ctx.path_as_is");
_Static_assert(offsetof(struct Curl_getinfo_ctx, opt_no_body) == 252 + 2 * sizeof(long), "Curl_getinfo_ctx.opt_no_body");
_Static_assert(offsetof(struct Curl_getinfo_ctx, timecond) == 253 + 2 * sizeof(long), "Curl_getinfo_ctx.timecond");
_Static_assert(offsetof(struct Curl_getinfo_ctx, used_proxy) == 254 + 2 * sizeof(long), "Curl_getinfo_ctx.used_proxy");
_Static_assert(offsetof(struct Curl_getinfo_ctx, ul_size_known) == 255 + 2 * sizeof(long), "Curl_getinfo_ctx.ul_size_known");
_Static_assert(offsetof(struct Curl_getinfo_ctx, dl_size_known) == 256 + 2 * sizeof(long), "Curl_getinfo_ctx.dl_size_known");

/* 5. SingleRequest and Curl_multi_ev layouts */
_Static_assert(sizeof(struct SingleRequest) == 232, "sizeof(SingleRequest)");
_Static_assert(_Alignof(struct SingleRequest) == 8, "alignof(SingleRequest)");
_Static_assert(offsetof(struct SingleRequest, size) == 0, "SingleRequest.size");
_Static_assert(offsetof(struct SingleRequest, maxdownload) == 8, "SingleRequest.maxdownload");
_Static_assert(offsetof(struct SingleRequest, bytecount) == 16, "SingleRequest.bytecount");
_Static_assert(offsetof(struct SingleRequest, writebytecount) == 24, "SingleRequest.writebytecount");
_Static_assert(offsetof(struct SingleRequest, offset) == 32, "SingleRequest.offset");
_Static_assert(offsetof(struct SingleRequest, start) == 40, "SingleRequest.start");
_Static_assert(offsetof(struct SingleRequest, headerbytecount) == 56, "SingleRequest.headerbytecount");
_Static_assert(offsetof(struct SingleRequest, allheadercount) == 60, "SingleRequest.allheadercount");
_Static_assert(offsetof(struct SingleRequest, deductheadercount) == 64, "SingleRequest.deductheadercount");
_Static_assert(offsetof(struct SingleRequest, headerline) == 68, "SingleRequest.headerline");
_Static_assert(offsetof(struct SingleRequest, httpcode) == 72, "SingleRequest.httpcode");
_Static_assert(offsetof(struct SingleRequest, httpversion_sent) == 76, "SingleRequest.httpversion_sent");
_Static_assert(offsetof(struct SingleRequest, httpversion) == 77, "SingleRequest.httpversion");
_Static_assert(offsetof(struct SingleRequest, upgr101) == 78, "SingleRequest.upgr101");
_Static_assert(offsetof(struct SingleRequest, io_flags) == 79, "SingleRequest.io_flags");
_Static_assert(offsetof(struct SingleRequest, writer.stack) == 80, "SingleRequest.writer.stack");
_Static_assert(offsetof(struct SingleRequest, reader.stack) == 96, "SingleRequest.reader.stack");
_Static_assert(offsetof(struct SingleRequest, sendbuf) == 104, "SingleRequest.sendbuf");
_Static_assert(offsetof(struct SingleRequest, sendbuf_hds_len) == 168, "SingleRequest.sendbuf_hds_len");
_Static_assert(offsetof(struct SingleRequest, timeofdoc) == 176, "SingleRequest.timeofdoc");
_Static_assert(offsetof(struct SingleRequest, location) == 184, "SingleRequest.location");
_Static_assert(offsetof(struct SingleRequest, newurl) == 192, "SingleRequest.newurl");
_Static_assert(offsetof(struct SingleRequest, hd_auth) == 200, "SingleRequest.hd_auth");
#ifndef CURL_DISABLE_PROXY
_Static_assert(offsetof(struct SingleRequest, hd_proxy_auth) == 208, "SingleRequest.hd_proxy_auth");
#endif
#ifndef CURL_DISABLE_COOKIES
_Static_assert(offsetof(struct SingleRequest, cookiehost) == 216, "SingleRequest.cookiehost");
_Static_assert(offsetof(struct SingleRequest, setcookies) == 224, "SingleRequest.setcookies");
#endif

_Static_assert(sizeof(struct curl_multi_ev) == 40, "sizeof(curl_multi_ev)");
_Static_assert(_Alignof(struct curl_multi_ev) == 8, "alignof(curl_multi_ev)");
_Static_assert(offsetof(struct curl_multi_ev, sh_entries) == 0, "curl_multi_ev.sh_entries");

/* 6. Connection filters, writers/readers, progress, cpool, peer, vdns */
_Static_assert(sizeof(struct Curl_cfilter) == 40, "sizeof(Curl_cfilter)");
_Static_assert(_Alignof(struct Curl_cfilter) == 8, "alignof(Curl_cfilter)");
_Static_assert(offsetof(struct Curl_cfilter, cft) == 0, "Curl_cfilter.cft");
_Static_assert(offsetof(struct Curl_cfilter, next) == 8, "Curl_cfilter.next");
_Static_assert(offsetof(struct Curl_cfilter, ctx) == 16, "Curl_cfilter.ctx");
_Static_assert(offsetof(struct Curl_cfilter, conn) == 24, "Curl_cfilter.conn");
_Static_assert(offsetof(struct Curl_cfilter, sockindex) == 32, "Curl_cfilter.sockindex");

_Static_assert(sizeof(struct Curl_cftype) == 104, "sizeof(Curl_cftype)");
_Static_assert(_Alignof(struct Curl_cftype) == 8, "alignof(Curl_cftype)");
_Static_assert(offsetof(struct Curl_cftype, name) == 0, "Curl_cftype.name");
_Static_assert(offsetof(struct Curl_cftype, flags) == 8, "Curl_cftype.flags");
_Static_assert(offsetof(struct Curl_cftype, log_level) == 12, "Curl_cftype.log_level");
_Static_assert(offsetof(struct Curl_cftype, destroy) == 16, "Curl_cftype.destroy");
_Static_assert(offsetof(struct Curl_cftype, do_connect) == 24, "Curl_cftype.do_connect");
_Static_assert(offsetof(struct Curl_cftype, do_shutdown) == 32, "Curl_cftype.do_shutdown");
_Static_assert(offsetof(struct Curl_cftype, adjust_pollset) == 40, "Curl_cftype.adjust_pollset");
_Static_assert(offsetof(struct Curl_cftype, has_data_pending) == 48, "Curl_cftype.has_data_pending");
_Static_assert(offsetof(struct Curl_cftype, do_send) == 56, "Curl_cftype.do_send");
_Static_assert(offsetof(struct Curl_cftype, do_recv) == 64, "Curl_cftype.do_recv");
_Static_assert(offsetof(struct Curl_cftype, cntrl) == 72, "Curl_cftype.cntrl");
_Static_assert(offsetof(struct Curl_cftype, is_alive) == 80, "Curl_cftype.is_alive");
_Static_assert(offsetof(struct Curl_cftype, keep_alive) == 88, "Curl_cftype.keep_alive");
_Static_assert(offsetof(struct Curl_cftype, query) == 96, "Curl_cftype.query");

_Static_assert(sizeof(struct Curl_cwtype) == 64, "sizeof(Curl_cwtype)");
_Static_assert(_Alignof(struct Curl_cwtype) == 8, "alignof(Curl_cwtype)");
_Static_assert(offsetof(struct Curl_cwtype, name) == 0, "Curl_cwtype.name");
_Static_assert(offsetof(struct Curl_cwtype, alias) == 8, "Curl_cwtype.alias");
_Static_assert(offsetof(struct Curl_cwtype, flags) == 16, "Curl_cwtype.flags");
_Static_assert(offsetof(struct Curl_cwtype, do_init) == 24, "Curl_cwtype.do_init");
_Static_assert(offsetof(struct Curl_cwtype, do_write) == 32, "Curl_cwtype.do_write");
_Static_assert(offsetof(struct Curl_cwtype, do_flush) == 40, "Curl_cwtype.do_flush");
_Static_assert(offsetof(struct Curl_cwtype, do_close) == 48, "Curl_cwtype.do_close");
_Static_assert(offsetof(struct Curl_cwtype, cwriter_size) == 56, "Curl_cwtype.cwriter_size");

_Static_assert(sizeof(struct Curl_cwriter) == 32, "sizeof(Curl_cwriter)");
_Static_assert(_Alignof(struct Curl_cwriter) == 8, "alignof(Curl_cwriter)");
_Static_assert(offsetof(struct Curl_cwriter, cwt) == 0, "Curl_cwriter.cwt");
_Static_assert(offsetof(struct Curl_cwriter, next) == 8, "Curl_cwriter.next");
_Static_assert(offsetof(struct Curl_cwriter, ctx) == 16, "Curl_cwriter.ctx");
_Static_assert(offsetof(struct Curl_cwriter, phase) == 24, "Curl_cwriter.phase");

_Static_assert(sizeof(struct Curl_crtype) == 88, "sizeof(Curl_crtype)");
_Static_assert(_Alignof(struct Curl_crtype) == 8, "alignof(Curl_crtype)");
_Static_assert(offsetof(struct Curl_crtype, name) == 0, "Curl_crtype.name");
_Static_assert(offsetof(struct Curl_crtype, do_init) == 8, "Curl_crtype.do_init");
_Static_assert(offsetof(struct Curl_crtype, do_read) == 16, "Curl_crtype.do_read");
_Static_assert(offsetof(struct Curl_crtype, do_close) == 24, "Curl_crtype.do_close");
_Static_assert(offsetof(struct Curl_crtype, needs_rewind) == 32, "Curl_crtype.needs_rewind");
_Static_assert(offsetof(struct Curl_crtype, total_length) == 40, "Curl_crtype.total_length");
_Static_assert(offsetof(struct Curl_crtype, resume_from) == 48, "Curl_crtype.resume_from");
_Static_assert(offsetof(struct Curl_crtype, cntrl) == 56, "Curl_crtype.cntrl");
_Static_assert(offsetof(struct Curl_crtype, is_paused) == 64, "Curl_crtype.is_paused");
_Static_assert(offsetof(struct Curl_crtype, done) == 72, "Curl_crtype.done");
_Static_assert(offsetof(struct Curl_crtype, creader_size) == 80, "Curl_crtype.creader_size");

_Static_assert(sizeof(struct Curl_creader) == 32, "sizeof(Curl_creader)");
_Static_assert(_Alignof(struct Curl_creader) == 8, "alignof(Curl_creader)");
_Static_assert(offsetof(struct Curl_creader, crt) == 0, "Curl_creader.crt");
_Static_assert(offsetof(struct Curl_creader, next) == 8, "Curl_creader.next");
_Static_assert(offsetof(struct Curl_creader, ctx) == 16, "Curl_creader.ctx");
_Static_assert(offsetof(struct Curl_creader, phase) == 24, "Curl_creader.phase");

_Static_assert(sizeof(struct Progress) == 472, "sizeof(Progress)");
_Static_assert(_Alignof(struct Progress) == 8, "alignof(Progress)");
_Static_assert(offsetof(struct Progress, now) == 0, "Progress.now");
_Static_assert(offsetof(struct Progress, start) == 16, "Progress.start");
_Static_assert(offsetof(struct Progress, ul) == 32, "Progress.ul");
_Static_assert(offsetof(struct Progress, dl) == 136, "Progress.dl");
_Static_assert(offsetof(struct Progress, deliver) == 240, "Progress.deliver");
_Static_assert(offsetof(struct Progress, current_speed) == 248, "Progress.current_speed");
_Static_assert(offsetof(struct Progress, earlydata_sent) == 256, "Progress.earlydata_sent");
_Static_assert(offsetof(struct Progress, delta) == 264, "Progress.delta");
_Static_assert(offsetof(struct Progress, total) == 304, "Progress.total");
_Static_assert(offsetof(struct Progress, speed_amount) == 368, "Progress.speed_amount");
_Static_assert(offsetof(struct Progress, speed_time) == 416, "Progress.speed_time");
_Static_assert(offsetof(struct Progress, speeder_c) == 464, "Progress.speeder_c");

_Static_assert(sizeof(struct cpool) == 128, "sizeof(cpool)");
_Static_assert(_Alignof(struct cpool) == 8, "alignof(cpool)");
_Static_assert(offsetof(struct cpool, conns) == 0, "cpool.conns");
_Static_assert(offsetof(struct cpool, idles) == 24, "cpool.idles");
_Static_assert(offsetof(struct cpool, dest2bundle) == 40, "cpool.dest2bundle");
_Static_assert(offsetof(struct cpool, next_connection_id) == 80, "cpool.next_connection_id");
_Static_assert(offsetof(struct cpool, next_easy_id) == 88, "cpool.next_easy_id");
_Static_assert(offsetof(struct cpool, last_cleanup) == 96, "cpool.last_cleanup");
_Static_assert(offsetof(struct cpool, share) == 112, "cpool.share");

_Static_assert(_Alignof(struct Curl_peer) == 8, "alignof(Curl_peer)");
_Static_assert(offsetof(struct Curl_peer, scheme) == 0, "Curl_peer.scheme");
_Static_assert(offsetof(struct Curl_peer, hostname) == 8, "Curl_peer.hostname");
_Static_assert(offsetof(struct Curl_peer, zoneid) == 16, "Curl_peer.zoneid");
_Static_assert(offsetof(struct Curl_peer, refcount) == 24, "Curl_peer.refcount");
_Static_assert(offsetof(struct Curl_peer, scopeid) == 28, "Curl_peer.scopeid");
_Static_assert(offsetof(struct Curl_peer, port) == 32, "Curl_peer.port");
#ifdef _WIN32
_Static_assert(sizeof(struct Curl_peer) == 48, "sizeof(Curl_peer)");
_Static_assert(offsetof(struct Curl_peer, user_hostname) == 40, "Curl_peer.user_hostname");
#else
_Static_assert(sizeof(struct Curl_peer) == 40, "sizeof(Curl_peer)");
_Static_assert(offsetof(struct Curl_peer, user_hostname) == 35, "Curl_peer.user_hostname");
#endif

#ifdef USE_CURL_ASYNC
#ifdef USE_HTTPSRR
#define CURL_ABI_HTTPSRR_OFF 8
#else
#define CURL_ABI_HTTPSRR_OFF 0
#endif
#if defined(USE_RESOLV_THREADED) && defined(USE_HTTPSRR) && defined(USE_ARES)
#define CURL_ABI_RESOLV_CTX_SIZE 32
#elif defined(USE_RESOLV_THREADED) || defined(USE_RESOLV_ARES)
#define CURL_ABI_RESOLV_CTX_SIZE 24
#else
#define CURL_ABI_RESOLV_CTX_SIZE 0
#endif
_Static_assert(sizeof(struct Curl_resolv_async) == (96 + CURL_ABI_HTTPSRR_OFF + CURL_ABI_RESOLV_CTX_SIZE), "sizeof(Curl_resolv_async)");
_Static_assert(_Alignof(struct Curl_resolv_async) == 8, "alignof(Curl_resolv_async)");
_Static_assert(offsetof(struct Curl_resolv_async, next) == 0, "Curl_resolv_async.next");
_Static_assert(offsetof(struct Curl_resolv_async, peer) == 8, "Curl_resolv_async.peer");
_Static_assert(offsetof(struct Curl_resolv_async, ai_A) == 16, "Curl_resolv_async.ai_A");
_Static_assert(offsetof(struct Curl_resolv_async, ai_AAAA) == 24, "Curl_resolv_async.ai_AAAA");
#ifdef USE_HTTPSRR
_Static_assert(offsetof(struct Curl_resolv_async, httpsrr) == 32, "Curl_resolv_async.httpsrr");
#endif
#ifdef USE_RESOLV_ARES
_Static_assert(sizeof(struct async_ares_ctx) == 24, "sizeof(async_ares_ctx)");
_Static_assert(offsetof(struct Curl_resolv_async, ares) == (32 + CURL_ABI_HTTPSRR_OFF), "Curl_resolv_async.ares");
#endif
#ifdef USE_RESOLV_THREADED
_Static_assert(sizeof(struct async_thrdd_ctx) == CURL_ABI_RESOLV_CTX_SIZE, "sizeof(async_thrdd_ctx)");
_Static_assert(offsetof(struct Curl_resolv_async, thrdd) == (32 + CURL_ABI_HTTPSRR_OFF), "Curl_resolv_async.thrdd");
#endif
_Static_assert(offsetof(struct Curl_resolv_async, doh) == (32 + CURL_ABI_HTTPSRR_OFF + CURL_ABI_RESOLV_CTX_SIZE), "Curl_resolv_async.doh");
_Static_assert(offsetof(struct Curl_resolv_async, start) == (40 + CURL_ABI_HTTPSRR_OFF + CURL_ABI_RESOLV_CTX_SIZE), "Curl_resolv_async.start");
_Static_assert(offsetof(struct Curl_resolv_async, interval_end) == (56 + CURL_ABI_HTTPSRR_OFF + CURL_ABI_RESOLV_CTX_SIZE), "Curl_resolv_async.interval_end");
_Static_assert(offsetof(struct Curl_resolv_async, timeout_ms) == (64 + CURL_ABI_HTTPSRR_OFF + CURL_ABI_RESOLV_CTX_SIZE), "Curl_resolv_async.timeout_ms");
_Static_assert(offsetof(struct Curl_resolv_async, result) == (72 + CURL_ABI_HTTPSRR_OFF + CURL_ABI_RESOLV_CTX_SIZE), "Curl_resolv_async.result");
_Static_assert(offsetof(struct Curl_resolv_async, poll_interval) == (76 + CURL_ABI_HTTPSRR_OFF + CURL_ABI_RESOLV_CTX_SIZE), "Curl_resolv_async.poll_interval");
_Static_assert(offsetof(struct Curl_resolv_async, id) == (80 + CURL_ABI_HTTPSRR_OFF + CURL_ABI_RESOLV_CTX_SIZE), "Curl_resolv_async.id");
_Static_assert(offsetof(struct Curl_resolv_async, dns_queries) == (84 + CURL_ABI_HTTPSRR_OFF + CURL_ABI_RESOLV_CTX_SIZE), "Curl_resolv_async.dns_queries");
_Static_assert(offsetof(struct Curl_resolv_async, dns_responses) == (85 + CURL_ABI_HTTPSRR_OFF + CURL_ABI_RESOLV_CTX_SIZE), "Curl_resolv_async.dns_responses");
_Static_assert(offsetof(struct Curl_resolv_async, transport) == (86 + CURL_ABI_HTTPSRR_OFF + CURL_ABI_RESOLV_CTX_SIZE), "Curl_resolv_async.transport");
_Static_assert(offsetof(struct Curl_resolv_async, queries_ongoing) == (87 + CURL_ABI_HTTPSRR_OFF + CURL_ABI_RESOLV_CTX_SIZE), "Curl_resolv_async.queries_ongoing");
#endif

_Static_assert(sizeof(struct ip_quadruple) == 98, "sizeof(ip_quadruple)");
_Static_assert(_Alignof(struct ip_quadruple) == 2, "alignof(ip_quadruple)");
_Static_assert(offsetof(struct ip_quadruple, remote_ip) == 0, "ip_quadruple.remote_ip");
_Static_assert(offsetof(struct ip_quadruple, local_ip) == 46, "ip_quadruple.local_ip");
_Static_assert(offsetof(struct ip_quadruple, remote_port) == 92, "ip_quadruple.remote_port");
_Static_assert(offsetof(struct ip_quadruple, local_port) == 94, "ip_quadruple.local_port");
_Static_assert(offsetof(struct ip_quadruple, transport) == 96, "ip_quadruple.transport");

/* 7. Curl_scheme, Curl_protocol, and mime structs */
_Static_assert(sizeof(struct Curl_scheme) == 40, "sizeof(Curl_scheme)");
_Static_assert(_Alignof(struct Curl_scheme) == 8, "alignof(Curl_scheme)");
_Static_assert(offsetof(struct Curl_scheme, name) == 0, "Curl_scheme.name");
_Static_assert(offsetof(struct Curl_scheme, run) == 8, "Curl_scheme.run");
_Static_assert(offsetof(struct Curl_scheme, protocol) == 16, "Curl_scheme.protocol");
_Static_assert(offsetof(struct Curl_scheme, family) == 24, "Curl_scheme.family");
_Static_assert(offsetof(struct Curl_scheme, flags) == 32, "Curl_scheme.flags");
_Static_assert(offsetof(struct Curl_scheme, defport) == 36, "Curl_scheme.defport");

_Static_assert(sizeof(struct Curl_protocol) == 136, "sizeof(Curl_protocol)");
_Static_assert(_Alignof(struct Curl_protocol) == 8, "alignof(Curl_protocol)");
_Static_assert(offsetof(struct Curl_protocol, setup_connection) == 0, "Curl_protocol.setup_connection");
_Static_assert(offsetof(struct Curl_protocol, do_it) == 8, "Curl_protocol.do_it");
_Static_assert(offsetof(struct Curl_protocol, done) == 16, "Curl_protocol.done");
_Static_assert(offsetof(struct Curl_protocol, do_more) == 24, "Curl_protocol.do_more");
_Static_assert(offsetof(struct Curl_protocol, connect_it) == 32, "Curl_protocol.connect_it");
_Static_assert(offsetof(struct Curl_protocol, connecting) == 40, "Curl_protocol.connecting");
_Static_assert(offsetof(struct Curl_protocol, doing) == 48, "Curl_protocol.doing");
_Static_assert(offsetof(struct Curl_protocol, proto_pollset) == 56, "Curl_protocol.proto_pollset");
_Static_assert(offsetof(struct Curl_protocol, doing_pollset) == 64, "Curl_protocol.doing_pollset");
_Static_assert(offsetof(struct Curl_protocol, domore_pollset) == 72, "Curl_protocol.domore_pollset");
_Static_assert(offsetof(struct Curl_protocol, perform_pollset) == 80, "Curl_protocol.perform_pollset");
_Static_assert(offsetof(struct Curl_protocol, disconnect) == 88, "Curl_protocol.disconnect");
_Static_assert(offsetof(struct Curl_protocol, write_resp) == 96, "Curl_protocol.write_resp");
_Static_assert(offsetof(struct Curl_protocol, write_resp_hd) == 104, "Curl_protocol.write_resp_hd");
_Static_assert(offsetof(struct Curl_protocol, connection_is_dead) == 112, "Curl_protocol.connection_is_dead");
_Static_assert(offsetof(struct Curl_protocol, attach) == 120, "Curl_protocol.attach");
_Static_assert(offsetof(struct Curl_protocol, follow) == 128, "Curl_protocol.follow");

#if !defined(CURL_DISABLE_MIME) || !defined(CURL_DISABLE_FORM_API)
_Static_assert(sizeof(struct mime_encoder) == 24, "sizeof(mime_encoder)");
_Static_assert(offsetof(struct mime_encoder, name) == 0, "mime_encoder.name");
_Static_assert(offsetof(struct mime_encoder, encodefunc) == 8, "mime_encoder.encodefunc");
_Static_assert(offsetof(struct mime_encoder, sizefunc) == 16, "mime_encoder.sizefunc");

_Static_assert(sizeof(struct mime_encoder_state) == 280, "sizeof(mime_encoder_state)");
_Static_assert(offsetof(struct mime_encoder_state, pos) == 0, "mime_encoder_state.pos");
_Static_assert(offsetof(struct mime_encoder_state, bufbeg) == 8, "mime_encoder_state.bufbeg");
_Static_assert(offsetof(struct mime_encoder_state, bufend) == 16, "mime_encoder_state.bufend");
_Static_assert(offsetof(struct mime_encoder_state, buf) == 24, "mime_encoder_state.buf");

_Static_assert(sizeof(struct mime_state) == 24, "sizeof(mime_state)");
_Static_assert(offsetof(struct mime_state, state) == 0, "mime_state.state");
_Static_assert(offsetof(struct mime_state, ptr) == 8, "mime_state.ptr");
_Static_assert(offsetof(struct mime_state, offset) == 16, "mime_state.offset");

_Static_assert(sizeof(struct curl_mime) == 96, "sizeof(curl_mime)");
_Static_assert(offsetof(struct curl_mime, parent) == 0, "curl_mime.parent");
_Static_assert(offsetof(struct curl_mime, firstpart) == 8, "curl_mime.firstpart");
_Static_assert(offsetof(struct curl_mime, lastpart) == 16, "curl_mime.lastpart");
_Static_assert(offsetof(struct curl_mime, boundary) == 24, "curl_mime.boundary");
_Static_assert(offsetof(struct curl_mime, state) == 72, "curl_mime.state");

_Static_assert(sizeof(struct curl_mimepart) == 440, "sizeof(curl_mimepart)");
_Static_assert(offsetof(struct curl_mimepart, parent) == 0, "curl_mimepart.parent");
_Static_assert(offsetof(struct curl_mimepart, nextpart) == 8, "curl_mimepart.nextpart");
_Static_assert(offsetof(struct curl_mimepart, kind) == 16, "curl_mimepart.kind");
_Static_assert(offsetof(struct curl_mimepart, flags) == 20, "curl_mimepart.flags");
_Static_assert(offsetof(struct curl_mimepart, data) == 24, "curl_mimepart.data");
_Static_assert(offsetof(struct curl_mimepart, readfunc) == 32, "curl_mimepart.readfunc");
_Static_assert(offsetof(struct curl_mimepart, seekfunc) == 40, "curl_mimepart.seekfunc");
_Static_assert(offsetof(struct curl_mimepart, freefunc) == 48, "curl_mimepart.freefunc");
_Static_assert(offsetof(struct curl_mimepart, arg) == 56, "curl_mimepart.arg");
_Static_assert(offsetof(struct curl_mimepart, fp) == 64, "curl_mimepart.fp");
_Static_assert(offsetof(struct curl_mimepart, curlheaders) == 72, "curl_mimepart.curlheaders");
_Static_assert(offsetof(struct curl_mimepart, userheaders) == 80, "curl_mimepart.userheaders");
_Static_assert(offsetof(struct curl_mimepart, mimetype) == 88, "curl_mimepart.mimetype");
_Static_assert(offsetof(struct curl_mimepart, filename) == 96, "curl_mimepart.filename");
_Static_assert(offsetof(struct curl_mimepart, name) == 104, "curl_mimepart.name");
_Static_assert(offsetof(struct curl_mimepart, datasize) == 112, "curl_mimepart.datasize");
_Static_assert(offsetof(struct curl_mimepart, state) == 120, "curl_mimepart.state");
_Static_assert(offsetof(struct curl_mimepart, encoder) == 144, "curl_mimepart.encoder");
_Static_assert(offsetof(struct curl_mimepart, encstate) == 152, "curl_mimepart.encstate");
_Static_assert(offsetof(struct curl_mimepart, lastreadstatus) == 432, "curl_mimepart.lastreadstatus");
#endif

/* 8. API Enum Value Parity (lib/api.h) */
_Static_assert(CURL_EAPI_FN_easy_cleanup == 0, "CURL_EAPI_FN_easy_cleanup");
_Static_assert(CURL_EAPI_FN_easy_duphandle == 1, "CURL_EAPI_FN_easy_duphandle");
_Static_assert(CURL_EAPI_FN_easy_getinfo == 2, "CURL_EAPI_FN_easy_getinfo");
_Static_assert(CURL_EAPI_FN_easy_header == 3, "CURL_EAPI_FN_easy_header");
_Static_assert(CURL_EAPI_FN_easy_nextheader == 4, "CURL_EAPI_FN_easy_nextheader");
_Static_assert(CURL_EAPI_FN_easy_pause == 5, "CURL_EAPI_FN_easy_pause");
_Static_assert(CURL_EAPI_FN_easy_perform_ev == 6, "CURL_EAPI_FN_easy_perform_ev");
_Static_assert(CURL_EAPI_FN_easy_perform == 7, "CURL_EAPI_FN_easy_perform");
_Static_assert(CURL_EAPI_FN_easy_recv == 8, "CURL_EAPI_FN_easy_recv");
_Static_assert(CURL_EAPI_FN_easy_reset == 9, "CURL_EAPI_FN_easy_reset");
_Static_assert(CURL_EAPI_FN_easy_send == 10, "CURL_EAPI_FN_easy_send");
_Static_assert(CURL_EAPI_FN_easy_setopt == 11, "CURL_EAPI_FN_easy_setopt");
_Static_assert(CURL_EAPI_FN_easy_ssls_export == 12, "CURL_EAPI_FN_easy_ssls_export");
_Static_assert(CURL_EAPI_FN_easy_ssls_import == 13, "CURL_EAPI_FN_easy_ssls_import");
_Static_assert(CURL_EAPI_FN_easy_upkeep == 14, "CURL_EAPI_FN_easy_upkeep");
_Static_assert(CURL_EAPI_FN_ws_recv == 15, "CURL_EAPI_FN_ws_recv");
_Static_assert(CURL_EAPI_FN_ws_send == 16, "CURL_EAPI_FN_ws_send");
_Static_assert(CURL_EAPI_FN_ws_start_frame == 17, "CURL_EAPI_FN_ws_start_frame");
_Static_assert(CURL_EAPI_FN_LAST == 18, "CURL_EAPI_FN_LAST");

_Static_assert(CURL_MAPI_FN_multi_add_handle == 0, "CURL_MAPI_FN_multi_add_handle");
_Static_assert(CURL_MAPI_FN_multi_assign == 1, "CURL_MAPI_FN_multi_assign");
_Static_assert(CURL_MAPI_FN_multi_cleanup == 2, "CURL_MAPI_FN_multi_cleanup");
_Static_assert(CURL_MAPI_FN_multi_fdset == 3, "CURL_MAPI_FN_multi_fdset");
_Static_assert(CURL_MAPI_FN_multi_get_handles == 4, "CURL_MAPI_FN_multi_get_handles");
_Static_assert(CURL_MAPI_FN_multi_get_offt == 5, "CURL_MAPI_FN_multi_get_offt");
_Static_assert(CURL_MAPI_FN_multi_info_read == 6, "CURL_MAPI_FN_multi_info_read");
_Static_assert(CURL_MAPI_FN_multi_notify_disable == 7, "CURL_MAPI_FN_multi_notify_disable");
_Static_assert(CURL_MAPI_FN_multi_notify_enable == 8, "CURL_MAPI_FN_multi_notify_enable");
_Static_assert(CURL_MAPI_FN_multi_perform == 9, "CURL_MAPI_FN_multi_perform");
_Static_assert(CURL_MAPI_FN_multi_poll == 10, "CURL_MAPI_FN_multi_poll");
_Static_assert(CURL_MAPI_FN_multi_remove_handle == 11, "CURL_MAPI_FN_multi_remove_handle");
_Static_assert(CURL_MAPI_FN_multi_setopt == 12, "CURL_MAPI_FN_multi_setopt");
_Static_assert(CURL_MAPI_FN_multi_socket_action == 13, "CURL_MAPI_FN_multi_socket_action");
_Static_assert(CURL_MAPI_FN_multi_socket_all == 14, "CURL_MAPI_FN_multi_socket_all");
_Static_assert(CURL_MAPI_FN_multi_socket == 15, "CURL_MAPI_FN_multi_socket");
_Static_assert(CURL_MAPI_FN_multi_timeout == 16, "CURL_MAPI_FN_multi_timeout");
_Static_assert(CURL_MAPI_FN_multi_wait == 17, "CURL_MAPI_FN_multi_wait");
_Static_assert(CURL_MAPI_FN_multi_waitfds == 18, "CURL_MAPI_FN_multi_waitfds");
_Static_assert(CURL_MAPI_FN_LAST == 19, "CURL_MAPI_FN_LAST");

_Static_assert(CURL_CBAPI_FN_START == 128, "CURL_CBAPI_FN_START");
_Static_assert(CURL_CBAPI_FN_easy_chunk_bgn == 128, "CURL_CBAPI_FN_easy_chunk_bgn");
_Static_assert(CURL_CBAPI_FN_easy_chunk_end == 129, "CURL_CBAPI_FN_easy_chunk_end");
_Static_assert(CURL_CBAPI_FN_easy_closesocket == 130, "CURL_CBAPI_FN_easy_closesocket");
_Static_assert(CURL_CBAPI_FN_easy_cr_in_read == 131, "CURL_CBAPI_FN_easy_cr_in_read");
_Static_assert(CURL_CBAPI_FN_easy_cr_in_resume_from == 132, "CURL_CBAPI_FN_easy_cr_in_resume_from");
_Static_assert(CURL_CBAPI_FN_easy_cw_out_cb == 133, "CURL_CBAPI_FN_easy_cw_out_cb");
_Static_assert(CURL_CBAPI_FN_easy_fdebug == 134, "CURL_CBAPI_FN_easy_fdebug");
_Static_assert(CURL_CBAPI_FN_easy_fnmatch_data == 135, "CURL_CBAPI_FN_easy_fnmatch_data");
_Static_assert(CURL_CBAPI_FN_easy_fopensocket == 136, "CURL_CBAPI_FN_easy_fopensocket");
_Static_assert(CURL_CBAPI_FN_easy_fprereq == 137, "CURL_CBAPI_FN_easy_fprereq");
_Static_assert(CURL_CBAPI_FN_easy_fprogress == 138, "CURL_CBAPI_FN_easy_fprogress");
_Static_assert(CURL_CBAPI_FN_easy_fread_func == 139, "CURL_CBAPI_FN_easy_fread_func");
_Static_assert(CURL_CBAPI_FN_easy_fsockopt == 140, "CURL_CBAPI_FN_easy_fsockopt");
_Static_assert(CURL_CBAPI_FN_easy_fsslctx == 141, "CURL_CBAPI_FN_easy_fsslctx");
_Static_assert(CURL_CBAPI_FN_easy_fwrite_rtp == 142, "CURL_CBAPI_FN_easy_fwrite_rtp");
_Static_assert(CURL_CBAPI_FN_easy_fxferinfo == 143, "CURL_CBAPI_FN_easy_fxferinfo");
_Static_assert(CURL_CBAPI_FN_easy_ioctl_func == 144, "CURL_CBAPI_FN_easy_ioctl_func");
_Static_assert(CURL_CBAPI_FN_easy_resolver_start == 145, "CURL_CBAPI_FN_easy_resolver_start");
_Static_assert(CURL_CBAPI_FN_easy_seek_func == 146, "CURL_CBAPI_FN_easy_seek_func");
_Static_assert(CURL_CBAPI_FN_easy_ssh_hostkeyfunc == 147, "CURL_CBAPI_FN_easy_ssh_hostkeyfunc");
_Static_assert(CURL_CBAPI_FN_easy_ssh_keyfunc == 148, "CURL_CBAPI_FN_easy_ssh_keyfunc");
_Static_assert(CURL_CBAPI_FN_easy_trailer_callback == 149, "CURL_CBAPI_FN_easy_trailer_callback");
_Static_assert(CURL_CBAPI_FN_multi_ntfy_cb == 150, "CURL_CBAPI_FN_multi_ntfy_cb");
_Static_assert(CURL_CBAPI_FN_multi_push_cb == 151, "CURL_CBAPI_FN_multi_push_cb");
_Static_assert(CURL_CBAPI_FN_multi_socket_cb == 152, "CURL_CBAPI_FN_multi_socket_cb");
_Static_assert(CURL_CBAPI_FN_multi_timer_cb == 153, "CURL_CBAPI_FN_multi_timer_cb");
_Static_assert(CURL_CBAPI_FN_LAST == 154, "CURL_CBAPI_FN_LAST");

/* 9. Runtime ABI sizeof helpers for Zig unit test cross-checks */
size_t Curl_zig_abi_sizeof_eapi_stack(void);
size_t Curl_zig_abi_sizeof_eapi_stack(void)
{
  return sizeof(struct Curl_eapi_stack);
}

size_t Curl_zig_abi_sizeof_eapi_guard(void);
size_t Curl_zig_abi_sizeof_eapi_guard(void)
{
  return sizeof(struct Curl_eapi_guard);
}

size_t Curl_zig_abi_sizeof_mapi_stack(void);
size_t Curl_zig_abi_sizeof_mapi_stack(void)
{
  return sizeof(struct Curl_mapi_stack);
}

size_t Curl_zig_abi_sizeof_mapi_guard(void);
size_t Curl_zig_abi_sizeof_mapi_guard(void)
{
  return sizeof(struct Curl_mapi_guard);
}

size_t Curl_zig_abi_sizeof_easy_prefix(void);
size_t Curl_zig_abi_sizeof_easy_prefix(void)
{
  return offsetof(struct Curl_easy, callstack) + sizeof(struct Curl_eapi_stack);
}

size_t Curl_zig_abi_sizeof_multi_prefix(void);
size_t Curl_zig_abi_sizeof_multi_prefix(void)
{
  return offsetof(struct Curl_multi, ssl_scache) +
         sizeof(struct Curl_ssl_scache *);
}

size_t Curl_zig_abi_sizeof_pureinfo_prefix(void);
size_t Curl_zig_abi_sizeof_pureinfo_prefix(void)
{
  return offsetof(struct PureInfo, pxcode) + 4;
}

size_t Curl_zig_abi_sizeof_getinfo_ctx(void);
size_t Curl_zig_abi_sizeof_getinfo_ctx(void)
{
  return sizeof(struct Curl_getinfo_ctx);
}

size_t Curl_zig_abi_sizeof_singlerequest(void);
size_t Curl_zig_abi_sizeof_singlerequest(void)
{
  return sizeof(struct SingleRequest);
}

size_t Curl_zig_abi_sizeof_multi_ev(void);
size_t Curl_zig_abi_sizeof_multi_ev(void)
{
  return sizeof(struct curl_multi_ev);
}

size_t Curl_zig_abi_sizeof_cfilter(void);
size_t Curl_zig_abi_sizeof_cfilter(void)
{
  return sizeof(struct Curl_cfilter);
}

size_t Curl_zig_abi_sizeof_cftype(void);
size_t Curl_zig_abi_sizeof_cftype(void)
{
  return sizeof(struct Curl_cftype);
}

size_t Curl_zig_abi_sizeof_cwtype(void);
size_t Curl_zig_abi_sizeof_cwtype(void)
{
  return sizeof(struct Curl_cwtype);
}

size_t Curl_zig_abi_sizeof_cwriter(void);
size_t Curl_zig_abi_sizeof_cwriter(void)
{
  return sizeof(struct Curl_cwriter);
}

size_t Curl_zig_abi_sizeof_crtype(void);
size_t Curl_zig_abi_sizeof_crtype(void)
{
  return sizeof(struct Curl_crtype);
}

size_t Curl_zig_abi_sizeof_creader(void);
size_t Curl_zig_abi_sizeof_creader(void)
{
  return sizeof(struct Curl_creader);
}

size_t Curl_zig_abi_sizeof_progress(void);
size_t Curl_zig_abi_sizeof_progress(void)
{
  return sizeof(struct Progress);
}

size_t Curl_zig_abi_sizeof_cpool(void);
size_t Curl_zig_abi_sizeof_cpool(void)
{
  return sizeof(struct cpool);
}

size_t Curl_zig_abi_sizeof_peer(void);
size_t Curl_zig_abi_sizeof_peer(void)
{
  return sizeof(struct Curl_peer);
}

size_t Curl_zig_abi_sizeof_resolv_async(void);
size_t Curl_zig_abi_sizeof_resolv_async(void)
{
  return sizeof(struct Curl_resolv_async);
}

size_t Curl_zig_abi_sizeof_ip_quadruple(void);
size_t Curl_zig_abi_sizeof_ip_quadruple(void)
{
  return sizeof(struct ip_quadruple);
}

size_t Curl_zig_abi_sizeof_scheme(void);
size_t Curl_zig_abi_sizeof_scheme(void)
{
  return sizeof(struct Curl_scheme);
}

size_t Curl_zig_abi_sizeof_protocol(void);
size_t Curl_zig_abi_sizeof_protocol(void)
{
  return sizeof(struct Curl_protocol);
}

size_t Curl_zig_abi_sizeof_mime(void);
size_t Curl_zig_abi_sizeof_mime(void)
{
  return sizeof(struct curl_mime);
}

size_t Curl_zig_abi_sizeof_mimepart(void);
size_t Curl_zig_abi_sizeof_mimepart(void)
{
  return sizeof(struct curl_mimepart);
}

#ifdef USE_NGTCP2
#include <ngtcp2/ngtcp2.h>
#include <ngtcp2/ngtcp2_crypto.h>
#include <nghttp3/nghttp3.h>
#if defined(USE_OPENSSL)
#include <openssl/ssl.h>
#include <openssl/err.h>
#include <ngtcp2/ngtcp2_crypto_ossl.h>
#elif defined(USE_GNUTLS)
#include <gnutls/gnutls.h>
#include <ngtcp2/ngtcp2_crypto_gnutls.h>
#endif

void Curl_ngtcp2_settings_default(ngtcp2_settings *settings);
void Curl_ngtcp2_settings_default(ngtcp2_settings *settings)
{
  ngtcp2_settings_default(settings);
}

void Curl_ngtcp2_transport_params_default(ngtcp2_transport_params *params);
void Curl_ngtcp2_transport_params_default(ngtcp2_transport_params *params)
{
  ngtcp2_transport_params_default(params);
}

int Curl_ngtcp2_conn_client_new(ngtcp2_conn **pconn, const ngtcp2_cid *dcid,
                                const ngtcp2_cid *scid, const ngtcp2_path *path,
                                uint32_t client_chosen_version,
                                const ngtcp2_callbacks *callbacks,
                                const ngtcp2_settings *settings,
                                const ngtcp2_transport_params *params,
                                const ngtcp2_mem *mem, void *user_data);
int Curl_ngtcp2_conn_client_new(ngtcp2_conn **pconn, const ngtcp2_cid *dcid,
                                const ngtcp2_cid *scid, const ngtcp2_path *path,
                                uint32_t client_chosen_version,
                                const ngtcp2_callbacks *callbacks,
                                const ngtcp2_settings *settings,
                                const ngtcp2_transport_params *params,
                                const ngtcp2_mem *mem, void *user_data)
{
  return ngtcp2_conn_client_new(pconn, dcid, scid, path, client_chosen_version,
                                callbacks, settings, params, mem, user_data);
}

int Curl_ngtcp2_conn_read_pkt(ngtcp2_conn *conn, const ngtcp2_path *path,
                              const ngtcp2_pkt_info *pi, const uint8_t *pkt,
                              size_t pktlen, ngtcp2_tstamp ts);
int Curl_ngtcp2_conn_read_pkt(ngtcp2_conn *conn, const ngtcp2_path *path,
                              const ngtcp2_pkt_info *pi, const uint8_t *pkt,
                              size_t pktlen, ngtcp2_tstamp ts)
{
  return ngtcp2_conn_read_pkt(conn, path, pi, pkt, pktlen, ts);
}

ngtcp2_ssize Curl_ngtcp2_conn_writev_stream(ngtcp2_conn *conn,
                                            ngtcp2_path *path,
                                            ngtcp2_pkt_info *pi, uint8_t *dest,
                                            size_t destlen,
                                            ngtcp2_ssize *pdatalen,
                                            uint32_t flags, int64_t stream_id,
                                            const ngtcp2_vec *datav,
                                            size_t datavcnt, ngtcp2_tstamp ts);
ngtcp2_ssize Curl_ngtcp2_conn_writev_stream(ngtcp2_conn *conn,
                                            ngtcp2_path *path,
                                            ngtcp2_pkt_info *pi, uint8_t *dest,
                                            size_t destlen,
                                            ngtcp2_ssize *pdatalen,
                                            uint32_t flags, int64_t stream_id,
                                            const ngtcp2_vec *datav,
                                            size_t datavcnt, ngtcp2_tstamp ts)
{
  return ngtcp2_conn_writev_stream(conn, path, pi, dest, destlen, pdatalen,
                                   flags, stream_id, datav, datavcnt, ts);
}

ngtcp2_ssize Curl_ngtcp2_conn_writev_datagram(ngtcp2_conn *conn,
                                              ngtcp2_path *path,
                                              ngtcp2_pkt_info *pi,
                                              uint8_t *dest, size_t destlen,
                                              int *paccepted, uint32_t flags,
                                              uint64_t dgram_id,
                                              const ngtcp2_vec *datav,
                                              size_t datavcnt,
                                              ngtcp2_tstamp ts);
ngtcp2_ssize Curl_ngtcp2_conn_writev_datagram(ngtcp2_conn *conn,
                                              ngtcp2_path *path,
                                              ngtcp2_pkt_info *pi,
                                              uint8_t *dest, size_t destlen,
                                              int *paccepted, uint32_t flags,
                                              uint64_t dgram_id,
                                              const ngtcp2_vec *datav,
                                              size_t datavcnt,
                                              ngtcp2_tstamp ts)
{
  return ngtcp2_conn_writev_datagram(conn, path, pi, dest, destlen, paccepted,
                                     flags, dgram_id, datav, datavcnt, ts);
}

ngtcp2_ssize Curl_ngtcp2_conn_write_connection_close(ngtcp2_conn *conn,
                                                     ngtcp2_path *path,
                                                     ngtcp2_pkt_info *pi,
                                                     uint8_t *dest,
                                                     size_t destlen,
                                                     const ngtcp2_ccerr *ccerr,
                                                     ngtcp2_tstamp ts);
ngtcp2_ssize Curl_ngtcp2_conn_write_connection_close(ngtcp2_conn *conn,
                                                     ngtcp2_path *path,
                                                     ngtcp2_pkt_info *pi,
                                                     uint8_t *dest,
                                                     size_t destlen,
                                                     const ngtcp2_ccerr *ccerr,
                                                     ngtcp2_tstamp ts)
{
  return ngtcp2_conn_write_connection_close(conn, path, pi, dest, destlen,
                                            ccerr, ts);
}

void Curl_nghttp3_settings_default(nghttp3_settings *settings);
void Curl_nghttp3_settings_default(nghttp3_settings *settings)
{
  nghttp3_settings_default(settings);
}

int Curl_nghttp3_conn_client_new(nghttp3_conn **pconn,
                                 const nghttp3_callbacks *callbacks,
                                 const nghttp3_settings *settings,
                                 const nghttp3_mem *mem, void *conn_user_data);
int Curl_nghttp3_conn_client_new(nghttp3_conn **pconn,
                                 const nghttp3_callbacks *callbacks,
                                 const nghttp3_settings *settings,
                                 const nghttp3_mem *mem, void *conn_user_data)
{
  return nghttp3_conn_client_new(pconn, callbacks, settings, mem,
                                 conn_user_data);
}
#endif /* USE_NGTCP2 */

#ifdef USE_QUICHE
#include <quiche.h>
#endif

#if defined(USE_NGTCP2) || defined(USE_QUICHE)
#include <poll.h>
#include <time.h>

static uint64_t h3_test_now_ns(void)
{
  struct timespec ts;
  clock_gettime(CLOCK_MONOTONIC, &ts);
  return (uint64_t)ts.tv_sec * 1000000000ULL + (uint64_t)ts.tv_nsec;
}

struct h3_test_stream {
  int64_t stream_id;
  char method[16];
  char path[128];
  uint8_t req_body[4096];
  size_t req_body_len;
  uint8_t resp_body[4096];
  size_t resp_body_len;
  char content_length_str[32];
  bool in_use;
  bool resp_submitted;
};

static void h3_test_build_response(struct h3_test_stream *st)
{
  if(strcmp(st->method, "POST") == 0) {
    const char *prefix = "post-echo:";
    size_t plen = strlen(prefix);
    memcpy(st->resp_body, prefix, plen);
    size_t copy_len = st->req_body_len;
    if(plen + copy_len > sizeof(st->resp_body))
      copy_len = sizeof(st->resp_body) - plen;
    if(copy_len > 0)
      memcpy(st->resp_body + plen, st->req_body, copy_len);
    st->resp_body_len = plen + copy_len;
  }
  else if(strcmp(st->path, "/stream1") == 0) {
    const char *msg = "h3-stream-1-ok";
    st->resp_body_len = strlen(msg);
    memcpy(st->resp_body, msg, st->resp_body_len);
  }
  else if(strcmp(st->path, "/stream2") == 0) {
    const char *msg = "h3-stream-2-ok";
    st->resp_body_len = strlen(msg);
    memcpy(st->resp_body, msg, st->resp_body_len);
  }
  else {
    const char *msg = "hello-http3";
    st->resp_body_len = strlen(msg);
    memcpy(st->resp_body, msg, st->resp_body_len);
  }
  curl_msnprintf(st->content_length_str, sizeof(st->content_length_str),
                 "%zu", st->resp_body_len);
}
#endif

#if defined(USE_NGTCP2)
struct h3_ngtcp2_srv {
  ngtcp2_crypto_conn_ref conn_ref;
  ngtcp2_conn *qconn;
  nghttp3_conn *h3conn;
  struct sockaddr_storage local_addr;
  socklen_t local_addrlen;
  struct sockaddr_storage client_addr;
  socklen_t client_addrlen;
  struct h3_test_stream streams[16];
  uint8_t next_cid_seq;
#if defined(USE_OPENSSL)
  SSL_CTX *ssl_ctx;
  SSL *ssl;
  ngtcp2_crypto_ossl_ctx *ossl_ctx;
#elif defined(USE_GNUTLS)
  gnutls_certificate_credentials_t cred;
  gnutls_session_t session;
#endif
};

static ngtcp2_conn *h3_srv_get_conn(ngtcp2_crypto_conn_ref *conn_ref)
{
  struct h3_ngtcp2_srv *srv = (struct h3_ngtcp2_srv *)conn_ref->user_data;
  return srv->qconn;
}

static struct h3_test_stream *h3_srv_get_stream(struct h3_ngtcp2_srv *srv,
                                                int64_t stream_id)
{
  size_t i;
  for(i = 0; i < 16; i++) {
    if(srv->streams[i].in_use && srv->streams[i].stream_id == stream_id)
      return &srv->streams[i];
  }
  for(i = 0; i < 16; i++) {
    if(!srv->streams[i].in_use) {
      memset(&srv->streams[i], 0, sizeof(srv->streams[i]));
      srv->streams[i].in_use = TRUE;
      srv->streams[i].stream_id = stream_id;
      return &srv->streams[i];
    }
  }
  return NULL;
}

static void h3_srv_rand(uint8_t *dest, size_t destlen,
                        const ngtcp2_rand_ctx *rand_ctx)
{
  size_t i;
  (void)rand_ctx;
  for(i = 0; i < destlen; i++)
    dest[i] = (uint8_t)(i * 37 + 13);
}

static int h3_srv_get_new_connection_id(ngtcp2_conn *conn, ngtcp2_cid *cid,
                                        uint8_t *token, size_t cidlen,
                                        void *user_data)
{
  struct h3_ngtcp2_srv *srv = (struct h3_ngtcp2_srv *)user_data;
  uint8_t seq = srv ? ++srv->next_cid_seq : 1;
  size_t i;
  (void)conn;
  for(i = 0; i < cidlen; i++)
    cid->data[i] = (uint8_t)(0x40 + seq * 17 + i);
  cid->datalen = cidlen;
  if(token)
    memset(token, (int)(0xa0 + seq), NGTCP2_STATELESS_RESET_TOKENLEN);
  return 0;
}

static nghttp3_ssize h3_srv_h3_read_data(nghttp3_conn *conn, int64_t stream_id,
                                         nghttp3_vec *vec, size_t veccnt,
                                         uint32_t *pflags, void *conn_user_data,
                                         void *stream_user_data)
{
  struct h3_ngtcp2_srv *srv = (struct h3_ngtcp2_srv *)conn_user_data;
  struct h3_test_stream *st = (struct h3_test_stream *)stream_user_data;
  (void)conn;
  (void)veccnt;
  if(!st)
    st = h3_srv_get_stream(srv, stream_id);
  if(!st || st->resp_body_len == 0) {
    *pflags = NGHTTP3_DATA_FLAG_EOF;
    return 0;
  }
  vec[0].base = st->resp_body;
  vec[0].len = st->resp_body_len;
  *pflags = NGHTTP3_DATA_FLAG_EOF;
  return 1;
}

static void h3_srv_submit_response(struct h3_ngtcp2_srv *srv,
                                   struct h3_test_stream *st)
{
  nghttp3_nv nva[3];
  nghttp3_data_reader dr;
  if(!st || st->resp_submitted || !srv->h3conn)
    return;
  st->resp_submitted = TRUE;
  h3_test_build_response(st);

  nva[0].name = (const uint8_t *)":status";
  nva[0].namelen = 7;
  nva[0].value = (const uint8_t *)"200";
  nva[0].valuelen = 3;
  nva[0].flags = NGHTTP3_NV_FLAG_NONE;

  nva[1].name = (const uint8_t *)"content-type";
  nva[1].namelen = 12;
  nva[1].value = (const uint8_t *)"text/plain";
  nva[1].valuelen = 10;
  nva[1].flags = NGHTTP3_NV_FLAG_NONE;

  nva[2].name = (const uint8_t *)"content-length";
  nva[2].namelen = 14;
  nva[2].value = (const uint8_t *)st->content_length_str;
  nva[2].valuelen = strlen(st->content_length_str);
  nva[2].flags = NGHTTP3_NV_FLAG_NONE;

  memset(&dr, 0, sizeof(dr));
  dr.read_data = h3_srv_h3_read_data;
  (void)nghttp3_conn_submit_response(srv->h3conn, st->stream_id, nva, 3, &dr);
}

static int h3_srv_h3_begin_headers(nghttp3_conn *conn, int64_t stream_id,
                                   void *conn_user_data, void *stream_user_data)
{
  struct h3_ngtcp2_srv *srv = (struct h3_ngtcp2_srv *)conn_user_data;
  struct h3_test_stream *st = h3_srv_get_stream(srv, stream_id);
  (void)stream_user_data;
  if(st)
    (void)nghttp3_conn_set_stream_user_data(conn, stream_id, st);
  return 0;
}

static int h3_srv_h3_recv_header(nghttp3_conn *conn, int64_t stream_id,
                                 int32_t token, nghttp3_rcbuf *name,
                                 nghttp3_rcbuf *value, uint8_t flags,
                                 void *conn_user_data, void *stream_user_data)
{
  struct h3_ngtcp2_srv *srv = (struct h3_ngtcp2_srv *)conn_user_data;
  struct h3_test_stream *st = (struct h3_test_stream *)stream_user_data;
  nghttp3_vec nvec = nghttp3_rcbuf_get_buf(name);
  nghttp3_vec vvec = nghttp3_rcbuf_get_buf(value);
  (void)conn;
  (void)token;
  (void)flags;
  if(!st)
    st = h3_srv_get_stream(srv, stream_id);
  if(!st)
    return 0;
  if(nvec.len == 7 && memcmp(nvec.base, ":method", 7) == 0) {
    size_t clen = vvec.len < sizeof(st->method) - 1 ?
                  vvec.len : sizeof(st->method) - 1;
    memcpy(st->method, vvec.base, clen);
    st->method[clen] = '\0';
  }
  else if(nvec.len == 5 && memcmp(nvec.base, ":path", 5) == 0) {
    size_t clen = vvec.len < sizeof(st->path) - 1 ?
                  vvec.len : sizeof(st->path) - 1;
    memcpy(st->path, vvec.base, clen);
    st->path[clen] = '\0';
  }
  return 0;
}

static int h3_srv_h3_end_headers(nghttp3_conn *conn, int64_t stream_id,
                                 int fin, void *conn_user_data,
                                 void *stream_user_data)
{
  struct h3_ngtcp2_srv *srv = (struct h3_ngtcp2_srv *)conn_user_data;
  struct h3_test_stream *st = (struct h3_test_stream *)stream_user_data;
  (void)conn;
  if(!st)
    st = h3_srv_get_stream(srv, stream_id);
  if(fin && st)
    h3_srv_submit_response(srv, st);
  return 0;
}

static int h3_srv_h3_recv_data(nghttp3_conn *conn, int64_t stream_id,
                               const uint8_t *data, size_t datalen,
                               void *conn_user_data, void *stream_user_data)
{
  struct h3_ngtcp2_srv *srv = (struct h3_ngtcp2_srv *)conn_user_data;
  struct h3_test_stream *st = (struct h3_test_stream *)stream_user_data;
  (void)conn;
  if(!st)
    st = h3_srv_get_stream(srv, stream_id);
  if(st && datalen > 0) {
    size_t avail = sizeof(st->req_body) - st->req_body_len;
    size_t clen = datalen < avail ? datalen : avail;
    if(clen > 0) {
      memcpy(st->req_body + st->req_body_len, data, clen);
      st->req_body_len += clen;
    }
  }
  ngtcp2_conn_extend_max_stream_offset(srv->qconn, stream_id, datalen);
  ngtcp2_conn_extend_max_offset(srv->qconn, datalen);
  return 0;
}

static int h3_srv_h3_deferred_consume(nghttp3_conn *conn, int64_t stream_id,
                                      size_t consumed, void *conn_user_data,
                                      void *stream_user_data)
{
  struct h3_ngtcp2_srv *srv = (struct h3_ngtcp2_srv *)conn_user_data;
  (void)conn;
  (void)stream_user_data;
  ngtcp2_conn_extend_max_stream_offset(srv->qconn, stream_id, consumed);
  ngtcp2_conn_extend_max_offset(srv->qconn, consumed);
  return 0;
}

static int h3_srv_h3_end_stream(nghttp3_conn *conn, int64_t stream_id,
                                void *conn_user_data, void *stream_user_data)
{
  struct h3_ngtcp2_srv *srv = (struct h3_ngtcp2_srv *)conn_user_data;
  struct h3_test_stream *st = (struct h3_test_stream *)stream_user_data;
  (void)conn;
  if(!st)
    st = h3_srv_get_stream(srv, stream_id);
  if(st)
    h3_srv_submit_response(srv, st);
  return 0;
}

static int h3_srv_h3_stop_sending(nghttp3_conn *conn, int64_t stream_id,
                                  uint64_t app_error_code,
                                  void *conn_user_data, void *stream_user_data)
{
  struct h3_ngtcp2_srv *srv = (struct h3_ngtcp2_srv *)conn_user_data;
  (void)conn;
  (void)stream_user_data;
  (void)ngtcp2_conn_shutdown_stream_read(srv->qconn, 0, stream_id,
                                         app_error_code);
  return 0;
}

static int h3_srv_h3_reset_stream(nghttp3_conn *conn, int64_t stream_id,
                                  uint64_t app_error_code,
                                  void *conn_user_data, void *stream_user_data)
{
  struct h3_ngtcp2_srv *srv = (struct h3_ngtcp2_srv *)conn_user_data;
  (void)conn;
  (void)stream_user_data;
  (void)ngtcp2_conn_shutdown_stream_write(srv->qconn, 0, stream_id,
                                          app_error_code);
  return 0;
}

static int h3_srv_setup_h3(struct h3_ngtcp2_srv *srv)
{
  nghttp3_callbacks callbacks;
  nghttp3_settings settings;
  int64_t ctrl_stream_id, qenc_stream_id, qdec_stream_id;

  if(srv->h3conn)
    return 0;
  if(ngtcp2_conn_get_streams_uni_left(srv->qconn) < 3)
    return -1;

  memset(&callbacks, 0, sizeof(callbacks));
  callbacks.begin_headers = h3_srv_h3_begin_headers;
  callbacks.recv_header = h3_srv_h3_recv_header;
  callbacks.end_headers = h3_srv_h3_end_headers;
  callbacks.recv_data = h3_srv_h3_recv_data;
  callbacks.deferred_consume = h3_srv_h3_deferred_consume;
  callbacks.end_stream = h3_srv_h3_end_stream;
  callbacks.stop_sending = h3_srv_h3_stop_sending;
  callbacks.reset_stream = h3_srv_h3_reset_stream;

  nghttp3_settings_default(&settings);
  if(nghttp3_conn_server_new(&srv->h3conn, &callbacks, &settings, NULL, srv) != 0)
    return -1;

  nghttp3_conn_set_max_client_streams_bidi(srv->h3conn, 100);

  if(ngtcp2_conn_open_uni_stream(srv->qconn, &ctrl_stream_id, NULL) != 0)
    return -1;
  if(nghttp3_conn_bind_control_stream(srv->h3conn, ctrl_stream_id) != 0)
    return -1;
  if(ngtcp2_conn_open_uni_stream(srv->qconn, &qenc_stream_id, NULL) != 0)
    return -1;
  if(ngtcp2_conn_open_uni_stream(srv->qconn, &qdec_stream_id, NULL) != 0)
    return -1;
  if(nghttp3_conn_bind_qpack_streams(srv->h3conn, qenc_stream_id,
                                     qdec_stream_id) != 0)
    return -1;
  return 0;
}

static int h3_srv_handshake_completed(ngtcp2_conn *conn, void *user_data)
{
  struct h3_ngtcp2_srv *srv = (struct h3_ngtcp2_srv *)user_data;
  (void)conn;
  return h3_srv_setup_h3(srv);
}

static int h3_srv_stream_open(ngtcp2_conn *conn, int64_t stream_id,
                              void *user_data)
{
  struct h3_ngtcp2_srv *srv = (struct h3_ngtcp2_srv *)user_data;
  (void)conn;
  if(!srv->h3conn) {
    if(h3_srv_setup_h3(srv) != 0)
      return NGTCP2_ERR_CALLBACK_FAILURE;
  }
  if(ngtcp2_is_bidi_stream(stream_id)) {
    struct h3_test_stream *st = h3_srv_get_stream(srv, stream_id);
    if(st)
      (void)nghttp3_conn_set_stream_user_data(srv->h3conn, stream_id, st);
  }
  return 0;
}

static int h3_srv_recv_stream_data(ngtcp2_conn *conn, uint32_t flags,
                                   int64_t stream_id, uint64_t offset,
                                   const uint8_t *data, size_t datalen,
                                   void *user_data, void *stream_user_data)
{
  struct h3_ngtcp2_srv *srv = (struct h3_ngtcp2_srv *)user_data;
  int fin = (flags & NGTCP2_STREAM_DATA_FLAG_FIN) ? 1 : 0;
  nghttp3_ssize nconsumed;
  (void)offset;
  (void)stream_user_data;
  if(!srv->h3conn) {
    if(h3_srv_setup_h3(srv) != 0)
      return NGTCP2_ERR_CALLBACK_FAILURE;
  }
  nconsumed = nghttp3_conn_read_stream(srv->h3conn, stream_id, data, datalen,
                                       fin);
  if(nconsumed < 0)
    return NGTCP2_ERR_CALLBACK_FAILURE;
  ngtcp2_conn_extend_max_stream_offset(conn, stream_id, (uint64_t)nconsumed);
  ngtcp2_conn_extend_max_offset(conn, (uint64_t)nconsumed);
  return 0;
}

static int h3_srv_acked_stream_data_offset(ngtcp2_conn *conn, int64_t stream_id,
                                           uint64_t offset, uint64_t datalen,
                                           void *user_data,
                                           void *stream_user_data)
{
  struct h3_ngtcp2_srv *srv = (struct h3_ngtcp2_srv *)user_data;
  (void)conn;
  (void)offset;
  (void)stream_user_data;
  if(srv->h3conn) {
    if(nghttp3_conn_add_ack_offset(srv->h3conn, stream_id, datalen) != 0)
      return NGTCP2_ERR_CALLBACK_FAILURE;
  }
  return 0;
}

static int h3_srv_stream_close(ngtcp2_conn *conn, uint32_t flags,
                               int64_t stream_id, uint64_t app_error_code,
                               void *user_data, void *stream_user_data)
{
  struct h3_ngtcp2_srv *srv = (struct h3_ngtcp2_srv *)user_data;
  (void)conn;
  (void)stream_user_data;
  if(!(flags & NGTCP2_STREAM_CLOSE_FLAG_APP_ERROR_CODE_SET))
    app_error_code = NGHTTP3_H3_NO_ERROR;
  if(srv->h3conn)
    (void)nghttp3_conn_close_stream(srv->h3conn, stream_id, app_error_code);
  return 0;
}

static int h3_srv_stream_reset(ngtcp2_conn *conn, int64_t stream_id,
                               uint64_t final_size, uint64_t app_error_code,
                               void *user_data, void *stream_user_data)
{
  struct h3_ngtcp2_srv *srv = (struct h3_ngtcp2_srv *)user_data;
  (void)conn;
  (void)final_size;
  (void)app_error_code;
  (void)stream_user_data;
  if(srv->h3conn)
    (void)nghttp3_conn_shutdown_stream_read(srv->h3conn, stream_id);
  return 0;
}

static int h3_srv_stream_stop_sending(ngtcp2_conn *conn, int64_t stream_id,
                                      uint64_t app_error_code,
                                      void *user_data, void *stream_user_data)
{
  struct h3_ngtcp2_srv *srv = (struct h3_ngtcp2_srv *)user_data;
  (void)conn;
  (void)app_error_code;
  (void)stream_user_data;
  if(srv->h3conn)
    nghttp3_conn_shutdown_stream_write(srv->h3conn, stream_id);
  return 0;
}

#if defined(USE_OPENSSL)
static int h3_srv_alpn_select_cb(SSL *ssl, const unsigned char **out,
                                 unsigned char *outlen,
                                 const unsigned char *in,
                                 unsigned int inlen, void *arg)
{
  static const unsigned char h3_alpn[] = "\x02h3";
  (void)ssl;
  (void)arg;
  if(SSL_select_next_proto((unsigned char **)out, outlen,
                           h3_alpn, sizeof(h3_alpn) - 1,
                           in, inlen) == OPENSSL_NPN_NEGOTIATED)
    return SSL_TLSEXT_ERR_OK;
  return SSL_TLSEXT_ERR_ALERT_FATAL;
}
#endif
#elif defined(USE_QUICHE)
struct h3_quiche_srv {
  struct h3_test_stream streams[16];
};

static struct h3_test_stream *h3_quiche_get_stream(struct h3_quiche_srv *srv,
                                                   int64_t stream_id)
{
  size_t i;
  for(i = 0; i < 16; i++) {
    if(srv->streams[i].in_use && srv->streams[i].stream_id == stream_id)
      return &srv->streams[i];
  }
  for(i = 0; i < 16; i++) {
    if(!srv->streams[i].in_use) {
      memset(&srv->streams[i], 0, sizeof(srv->streams[i]));
      srv->streams[i].in_use = TRUE;
      srv->streams[i].stream_id = stream_id;
      return &srv->streams[i];
    }
  }
  return NULL;
}

static int h3_quiche_header_cb(uint8_t *name, size_t name_len,
                               uint8_t *value, size_t value_len, void *argp)
{
  struct h3_test_stream *st = (struct h3_test_stream *)argp;
  if(!st)
    return 0;
  if(name_len == 7 && memcmp(name, ":method", 7) == 0) {
    size_t clen = value_len < sizeof(st->method) - 1 ?
                  value_len : sizeof(st->method) - 1;
    memcpy(st->method, value, clen);
    st->method[clen] = '\0';
  }
  else if(name_len == 5 && memcmp(name, ":path", 5) == 0) {
    size_t clen = value_len < sizeof(st->path) - 1 ?
                  value_len : sizeof(st->path) - 1;
    memcpy(st->path, value, clen);
    st->path[clen] = '\0';
  }
  return 0;
}
#endif

int Curl_test_h3_server_serve(int udp_fd, const char *cert_file,
                              const char *key_file, volatile int *stop_flag);
int Curl_test_h3_server_serve(int udp_fd, const char *cert_file,
                              const char *key_file, volatile int *stop_flag)
{
#if defined(USE_NGTCP2) && (defined(USE_OPENSSL) || defined(USE_GNUTLS))
  struct h3_ngtcp2_srv srv;
  uint8_t buf[2048];
  uint8_t outbuf[1452];
  memset(&srv, 0, sizeof(srv));
  srv.conn_ref.get_conn = h3_srv_get_conn;
  srv.conn_ref.user_data = &srv;
  srv.local_addrlen = sizeof(srv.local_addr);
  (void)getsockname(udp_fd, (struct sockaddr *)&srv.local_addr,
                    &srv.local_addrlen);

#if defined(USE_OPENSSL)
  (void)ngtcp2_crypto_ossl_init();
  srv.ssl_ctx = SSL_CTX_new(TLS_server_method());
  if(!srv.ssl_ctx)
    return -1;
  SSL_CTX_set_min_proto_version(srv.ssl_ctx, TLS1_3_VERSION);
  SSL_CTX_set_max_proto_version(srv.ssl_ctx, TLS1_3_VERSION);
  SSL_CTX_set_alpn_select_cb(srv.ssl_ctx, h3_srv_alpn_select_cb, NULL);
  if(SSL_CTX_use_certificate_chain_file(srv.ssl_ctx, cert_file) != 1 ||
     SSL_CTX_use_PrivateKey_file(srv.ssl_ctx, key_file, SSL_FILETYPE_PEM) != 1) {
    SSL_CTX_free(srv.ssl_ctx);
    return -1;
  }
#elif defined(USE_GNUTLS)
  if(gnutls_certificate_allocate_credentials(&srv.cred) != 0)
    return -1;
  if(gnutls_certificate_set_x509_key_file(srv.cred, cert_file, key_file,
                                          GNUTLS_X509_FMT_PEM) < 0) {
    gnutls_certificate_free_credentials(srv.cred);
    return -1;
  }
#endif

  while(!*stop_flag) {
    struct pollfd pfd;
    pfd.fd = udp_fd;
    pfd.events = POLLIN;
    pfd.revents = 0;
    int prc = poll(&pfd, 1, 20);
    if(prc > 0 && (pfd.revents & POLLIN)) {
      for(;;) {
        struct sockaddr_storage raddr;
        socklen_t raddrlen = sizeof(raddr);
        ssize_t nread = recvfrom(udp_fd, buf, sizeof(buf), MSG_DONTWAIT,
                                 (struct sockaddr *)&raddr, &raddrlen);
        if(nread <= 0)
          break;
        uint64_t ts = h3_test_now_ns();
        if(!srv.qconn) {
          ngtcp2_version_cid vc;
          if(ngtcp2_pkt_decode_version_cid(&vc, buf, (size_t)nread,
                                           NGTCP2_MAX_CIDLEN) != 0)
            continue;
          memcpy(&srv.client_addr, &raddr, raddrlen);
          srv.client_addrlen = raddrlen;
          ngtcp2_cid dcid, scid, odcid;
          uint8_t scid_bytes[16] = {
            0x11, 0x22, 0x33, 0x44, 0x55, 0x66, 0x77, 0x88,
            0x99, 0xaa, 0xbb, 0xcc, 0xdd, 0xee, 0xff, 0x01
          };
          ngtcp2_cid_init(&dcid, vc.scid, vc.scidlen);
          ngtcp2_cid_init(&scid, scid_bytes, sizeof(scid_bytes));
          ngtcp2_cid_init(&odcid, vc.dcid, vc.dcidlen);

          ngtcp2_callbacks cb;
          memset(&cb, 0, sizeof(cb));
          cb.recv_client_initial = ngtcp2_crypto_recv_client_initial_cb;
          cb.recv_crypto_data = ngtcp2_crypto_recv_crypto_data_cb;
          cb.handshake_completed = h3_srv_handshake_completed;
          cb.encrypt = ngtcp2_crypto_encrypt_cb;
          cb.decrypt = ngtcp2_crypto_decrypt_cb;
          cb.hp_mask = ngtcp2_crypto_hp_mask_cb;
          cb.recv_stream_data = h3_srv_recv_stream_data;
          cb.acked_stream_data_offset = h3_srv_acked_stream_data_offset;
          cb.stream_open = h3_srv_stream_open;
          cb.stream_close = h3_srv_stream_close;
          cb.rand = h3_srv_rand;
          cb.get_new_connection_id = h3_srv_get_new_connection_id;
          cb.update_key = ngtcp2_crypto_update_key_cb;
          cb.stream_reset = h3_srv_stream_reset;
          cb.stream_stop_sending = h3_srv_stream_stop_sending;
          cb.delete_crypto_aead_ctx = ngtcp2_crypto_delete_crypto_aead_ctx_cb;
          cb.delete_crypto_cipher_ctx =
            ngtcp2_crypto_delete_crypto_cipher_ctx_cb;
          cb.get_path_challenge_data = ngtcp2_crypto_get_path_challenge_data_cb;
          cb.version_negotiation = ngtcp2_crypto_version_negotiation_cb;

          ngtcp2_settings settings;
          ngtcp2_settings_default(&settings);
          settings.initial_ts = ts;

          ngtcp2_transport_params params;
          ngtcp2_transport_params_default(&params);
          params.original_dcid = odcid;
          params.original_dcid_present = 1;
          params.initial_max_stream_data_bidi_local = 256 * 1024;
          params.initial_max_stream_data_bidi_remote = 256 * 1024;
          params.initial_max_stream_data_uni = 256 * 1024;
          params.initial_max_data = 1024 * 1024;
          params.initial_max_streams_bidi = 100;
          params.initial_max_streams_uni = 10;
          params.max_idle_timeout = 30ULL * NGTCP2_SECONDS;
          params.active_connection_id_limit = 7;

          ngtcp2_path_storage ps;
          ngtcp2_path_storage_init(&ps,
                                   (struct sockaddr *)&srv.local_addr,
                                   srv.local_addrlen,
                                   (struct sockaddr *)&srv.client_addr,
                                   srv.client_addrlen, NULL);
          if(ngtcp2_conn_server_new(&srv.qconn, &dcid, &scid, &ps.path,
                                    vc.version, &cb, &settings, &params,
                                    NULL, &srv) != 0)
            break;

#if defined(USE_OPENSSL)
          srv.ssl = SSL_new(srv.ssl_ctx);
          (void)ngtcp2_crypto_ossl_ctx_new(&srv.ossl_ctx, srv.ssl);
          (void)ngtcp2_crypto_ossl_configure_server_session(srv.ssl);
          SSL_set_app_data(srv.ssl, &srv.conn_ref);
          SSL_set_accept_state(srv.ssl);
          ngtcp2_conn_set_tls_native_handle(srv.qconn, srv.ossl_ctx);
#elif defined(USE_GNUTLS)
          {
            gnutls_datum_t alpn = { (unsigned char *)"h3", 2 };
            (void)gnutls_init(&srv.session, GNUTLS_SERVER);
            (void)gnutls_priority_set_direct(
              srv.session,
              "NORMAL:-VERS-ALL:+VERS-TLS1.3:-CIPHER-ALL:+AES-128-GCM:"
              "+AES-256-GCM:+CHACHA20-POLY1305:+AES-128-CCM",
              NULL);
            (void)gnutls_credentials_set(srv.session, GNUTLS_CRD_CERTIFICATE,
                                         srv.cred);
            (void)gnutls_alpn_set_protocols(srv.session, &alpn, 1,
                                            GNUTLS_ALPN_MANDATORY);
            (void)ngtcp2_crypto_gnutls_configure_server_session(srv.session);
            gnutls_session_set_ptr(srv.session, &srv.conn_ref);
            ngtcp2_conn_set_tls_native_handle(srv.qconn, srv.session);
          }
#endif
        }

        ngtcp2_path_storage ps;
        ngtcp2_path_storage_init(&ps,
                                 (struct sockaddr *)&srv.local_addr,
                                 srv.local_addrlen,
                                 (struct sockaddr *)&raddr,
                                 raddrlen, NULL);
        ngtcp2_pkt_info pi;
        memset(&pi, 0, sizeof(pi));
        int rv = ngtcp2_conn_read_pkt(srv.qconn, &ps.path, &pi, buf,
                                      (size_t)nread, ts);
        if(rv != 0) {
          ngtcp2_ccerr ccerr;
          ngtcp2_ccerr_default(&ccerr);
          if(rv == NGTCP2_ERR_CRYPTO)
            ngtcp2_ccerr_set_tls_alert(
              &ccerr, ngtcp2_conn_get_tls_alert(srv.qconn), NULL, 0);
          else
            ngtcp2_ccerr_set_liberr(&ccerr, rv, NULL, 0);
          ngtcp2_ssize nclose = ngtcp2_conn_write_connection_close(
            srv.qconn, NULL, &pi, outbuf, sizeof(outbuf), &ccerr, ts);
          if(nclose > 0)
            (void)sendto(udp_fd, outbuf, (size_t)nclose, 0,
                         (struct sockaddr *)&srv.client_addr,
                         srv.client_addrlen);
          break;
        }
      }
    }

    if(srv.qconn) {
      uint64_t ts = h3_test_now_ns();
      for(;;) {
        nghttp3_vec h3vec[16];
        int64_t stream_id = -1;
        int fin = 0;
        nghttp3_ssize veccnt = 0;
        if(srv.h3conn) {
          veccnt = nghttp3_conn_writev_stream(srv.h3conn, &stream_id, &fin,
                                              h3vec, 16);
          if(veccnt < 0)
            break;
        }
        uint32_t flags = NGTCP2_WRITE_STREAM_FLAG_MORE |
                         (fin ? NGTCP2_WRITE_STREAM_FLAG_FIN :
                                NGTCP2_WRITE_STREAM_FLAG_NONE);
        ngtcp2_ssize ndatalen = -1;
        ngtcp2_pkt_info pi;
        memset(&pi, 0, sizeof(pi));
        ngtcp2_ssize nwrite = ngtcp2_conn_writev_stream(
          srv.qconn, NULL, &pi, outbuf, sizeof(outbuf), &ndatalen, flags,
          stream_id, (const ngtcp2_vec *)h3vec, (size_t)veccnt, ts);
        if(nwrite < 0) {
          if(nwrite == NGTCP2_ERR_WRITE_MORE) {
            if(srv.h3conn && ndatalen >= 0)
              (void)nghttp3_conn_add_write_offset(srv.h3conn, stream_id,
                                                  (size_t)ndatalen);
            continue;
          }
          if(nwrite == NGTCP2_ERR_STREAM_DATA_BLOCKED) {
            if(srv.h3conn && stream_id >= 0)
              nghttp3_conn_block_stream(srv.h3conn, stream_id);
            continue;
          }
          if(nwrite == NGTCP2_ERR_STREAM_SHUT_WR) {
            if(srv.h3conn && stream_id >= 0 && ndatalen >= 0)
              (void)nghttp3_conn_add_write_offset(srv.h3conn, stream_id,
                                                  (size_t)ndatalen);
            continue;
          }
          break;
        }
        if(nwrite == 0)
          break;
        if(srv.h3conn && stream_id >= 0 && ndatalen >= 0)
          (void)nghttp3_conn_add_write_offset(srv.h3conn, stream_id,
                                              (size_t)ndatalen);
        (void)sendto(udp_fd, outbuf, (size_t)nwrite, 0,
                     (struct sockaddr *)&srv.client_addr, srv.client_addrlen);
      }
    }
  }

  if(srv.h3conn)
    nghttp3_conn_del(srv.h3conn);
  if(srv.qconn)
    ngtcp2_conn_del(srv.qconn);
#if defined(USE_OPENSSL)
  if(srv.ossl_ctx)
    ngtcp2_crypto_ossl_ctx_del(srv.ossl_ctx);
  if(srv.ssl) {
    SSL_set_app_data(srv.ssl, NULL);
    SSL_free(srv.ssl);
  }
  if(srv.ssl_ctx)
    SSL_CTX_free(srv.ssl_ctx);
#elif defined(USE_GNUTLS)
  if(srv.session)
    gnutls_deinit(srv.session);
  if(srv.cred)
    gnutls_certificate_free_credentials(srv.cred);
#endif
  return 0;
#elif defined(USE_QUICHE)
  struct h3_quiche_srv srv;
  uint8_t buf[2048];
  uint8_t outbuf[1452];
  struct sockaddr_storage local_addr;
  socklen_t local_addrlen = sizeof(local_addr);
  struct sockaddr_storage client_addr;
  socklen_t client_addrlen = 0;
  quiche_config *cfg = NULL;
  quiche_h3_config *h3cfg = NULL;
  quiche_conn *qconn = NULL;
  quiche_h3_conn *h3conn = NULL;

  memset(&srv, 0, sizeof(srv));
  (void)getsockname(udp_fd, (struct sockaddr *)&local_addr, &local_addrlen);

  cfg = quiche_config_new(QUICHE_PROTOCOL_VERSION);
  if(!cfg)
    return -1;
  if(quiche_config_load_cert_chain_from_pem_file(cfg, cert_file) < 0 ||
     quiche_config_load_priv_key_from_pem_file(cfg, key_file) < 0) {
    quiche_config_free(cfg);
    return -1;
  }
  (void)quiche_config_set_application_protos(
    cfg, (const uint8_t *)QUICHE_H3_APPLICATION_PROTOCOL,
    sizeof(QUICHE_H3_APPLICATION_PROTOCOL) - 1);
  quiche_config_set_max_idle_timeout(cfg, 30000);
  quiche_config_set_max_recv_udp_payload_size(cfg, 1452);
  quiche_config_set_max_send_udp_payload_size(cfg, 1452);
  quiche_config_set_initial_max_data(cfg, 1024 * 1024);
  quiche_config_set_initial_max_stream_data_bidi_local(cfg, 256 * 1024);
  quiche_config_set_initial_max_stream_data_bidi_remote(cfg, 256 * 1024);
  quiche_config_set_initial_max_stream_data_uni(cfg, 256 * 1024);
  quiche_config_set_initial_max_streams_bidi(cfg, 100);
  quiche_config_set_initial_max_streams_uni(cfg, 10);

  while(!*stop_flag) {
    struct pollfd pfd;
    pfd.fd = udp_fd;
    pfd.events = POLLIN;
    pfd.revents = 0;
    int prc = poll(&pfd, 1, 20);
    if(prc > 0 && (pfd.revents & POLLIN)) {
      for(;;) {
        struct sockaddr_storage raddr;
        socklen_t raddrlen = sizeof(raddr);
        ssize_t nread = recvfrom(udp_fd, buf, sizeof(buf), MSG_DONTWAIT,
                                 (struct sockaddr *)&raddr, &raddrlen);
        if(nread <= 0)
          break;
        if(!qconn) {
          uint32_t version = 0;
          uint8_t ty = 0;
          uint8_t scid[20], dcid[20], token[64];
          size_t scid_len = sizeof(scid), dcid_len = sizeof(dcid),
                 token_len = sizeof(token);
          uint8_t srv_scid[16] = {
            0x11, 0x22, 0x33, 0x44, 0x55, 0x66, 0x77, 0x88,
            0x99, 0xaa, 0xbb, 0xcc, 0xdd, 0xee, 0xff, 0x01
          };
          if(quiche_header_info(buf, (size_t)nread, 16, &version, &ty,
                                scid, &scid_len, dcid, &dcid_len,
                                token, &token_len) < 0)
            continue;
          memcpy(&client_addr, &raddr, raddrlen);
          client_addrlen = raddrlen;
          qconn = quiche_accept(srv_scid, sizeof(srv_scid), dcid, dcid_len,
                                (struct sockaddr *)&local_addr, local_addrlen,
                                (struct sockaddr *)&client_addr,
                                client_addrlen, cfg);
          if(!qconn)
            break;
        }
        quiche_recv_info rinfo;
        rinfo.from = (struct sockaddr *)&raddr;
        rinfo.from_len = raddrlen;
        rinfo.to = (struct sockaddr *)&local_addr;
        rinfo.to_len = local_addrlen;
        (void)quiche_conn_recv(qconn, buf, (size_t)nread, &rinfo);
      }
    }

    if(qconn) {
      if(quiche_conn_is_established(qconn) && !h3conn) {
        h3cfg = quiche_h3_config_new();
        if(h3cfg)
          h3conn = quiche_h3_conn_new_with_transport(qconn, h3cfg);
      }
      if(h3conn) {
        for(;;) {
          quiche_h3_event *ev = NULL;
          int64_t sid = quiche_h3_conn_poll(h3conn, qconn, &ev);
          if(sid < 0 || !ev)
            break;
          struct h3_test_stream *st = h3_quiche_get_stream(&srv, sid);
          switch(quiche_h3_event_type(ev)) {
          case QUICHE_H3_EVENT_HEADERS:
            if(st)
              (void)quiche_h3_event_for_each_header(ev, h3_quiche_header_cb,
                                                    st);
            break;
          case QUICHE_H3_EVENT_DATA:
            if(st) {
              for(;;) {
                size_t avail = sizeof(st->req_body) - st->req_body_len;
                if(avail == 0)
                  break;
                ssize_t nb = quiche_h3_recv_body(
                  h3conn, qconn, (uint64_t)sid,
                  st->req_body + st->req_body_len, avail);
                if(nb <= 0)
                  break;
                st->req_body_len += (size_t)nb;
              }
            }
            break;
          case QUICHE_H3_EVENT_FINISHED:
            if(st && !st->resp_submitted) {
              st->resp_submitted = TRUE;
              h3_test_build_response(st);
              quiche_h3_header hdrs[3];
              hdrs[0].name = (const uint8_t *)":status";
              hdrs[0].name_len = 7;
              hdrs[0].value = (const uint8_t *)"200";
              hdrs[0].value_len = 3;
              hdrs[1].name = (const uint8_t *)"content-type";
              hdrs[1].name_len = 12;
              hdrs[1].value = (const uint8_t *)"text/plain";
              hdrs[1].value_len = 10;
              hdrs[2].name = (const uint8_t *)"content-length";
              hdrs[2].name_len = 14;
              hdrs[2].value = (const uint8_t *)st->content_length_str;
              hdrs[2].value_len = strlen(st->content_length_str);
              (void)quiche_h3_send_response(h3conn, qconn, (uint64_t)sid,
                                            hdrs, 3, FALSE);
              (void)quiche_h3_send_body(h3conn, qconn, (uint64_t)sid,
                                        st->resp_body, st->resp_body_len,
                                        TRUE);
            }
            break;
          default:
            break;
          }
          quiche_h3_event_free(ev);
        }
      }
      for(;;) {
        quiche_send_info sinfo;
        ssize_t nwrite = quiche_conn_send(qconn, outbuf, sizeof(outbuf),
                                          &sinfo);
        if(nwrite <= 0)
          break;
        (void)sendto(udp_fd, outbuf, (size_t)nwrite, 0,
                     (struct sockaddr *)&sinfo.to, sinfo.to_len);
      }
    }
  }

  if(h3conn)
    quiche_h3_conn_free(h3conn);
  if(h3cfg)
    quiche_h3_config_free(h3cfg);
  if(qconn)
    quiche_conn_free(qconn);
  if(cfg)
    quiche_config_free(cfg);
  return 0;
#else
  (void)udp_fd;
  (void)cert_file;
  (void)key_file;
  (void)stop_flag;
  return -1;
#endif
}



