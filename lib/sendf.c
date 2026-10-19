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

static void cl_reset_writer(struct Curl_easy *data)
{
  struct Curl_cwriter *writer = data->req.writer.stack;
  while(writer) {
    data->req.writer.stack = writer->next;
    writer->cwt->do_close(data, writer);
    curlx_free(writer);
    writer = data->req.writer.stack;
  }
  data->req.writer.paused = FALSE;
}

static void cl_reset_reader(struct Curl_easy *data)
{
  struct Curl_creader *reader = data->req.reader.stack;
  data->req.reader_started = FALSE;
  while(reader) {
    data->req.reader.stack = reader->next;
    reader->crt->do_close(data, reader);
    curlx_free(reader);
    reader = data->req.reader.stack;
  }
}

void Curl_client_cleanup(struct Curl_easy *data)
{
  cl_reset_reader(data);
  cl_reset_writer(data);

  data->req.bytecount = 0;
  data->req.headerline = 0;
}

void Curl_client_reset(struct Curl_easy *data)
{
  if(data->req.rewind_read) {
    /* already requested */
    CURL_TRC_READ(data, "client_reset, will rewind reader");
  }
  else {
    CURL_TRC_READ(data, "client_reset, clear readers");
    cl_reset_reader(data);
  }
  cl_reset_writer(data);

  data->req.bytecount = 0;
  data->req.headerline = 0;
}

CURLcode Curl_client_start(struct Curl_easy *data)
{
  if(data->req.rewind_read) {
    struct Curl_creader *r = data->req.reader.stack;
    CURLcode result = CURLE_OK;

    CURL_TRC_READ(data, "client start, rewind readers");
    while(r) {
      result = r->crt->cntrl(data, r, CURL_CRCNTRL_REWIND);
      if(result) {
        failf(data, "rewind of client reader '%s' failed: %d",
              r->crt->name, (int)result);
        return result;
      }
      r = r->next;
    }
    data->req.rewind_read = FALSE;
    cl_reset_reader(data);
  }
  return CURLE_OK;
}

bool Curl_creader_will_rewind(struct Curl_easy *data)
{
  return (bool)data->req.rewind_read;
}

void Curl_creader_set_rewind(struct Curl_easy *data, bool enable)
{
  data->req.rewind_read = !!enable;
}

CURLcode Curl_cwriter_def_init(struct Curl_easy *data,
                               struct Curl_cwriter *writer)
{
  (void)data;
  (void)writer;
  return CURLE_OK;
}

CURLcode Curl_cwriter_def_write(struct Curl_easy *data,
                                struct Curl_cwriter *writer, int type,
                                const char *buf, size_t nbytes)
{
  return Curl_cwriter_write(data, writer->next, type, buf, nbytes);
}

CURLcode Curl_cwriter_def_flush(struct Curl_easy *data,
                                struct Curl_cwriter *writer)
{
  return Curl_cwriter_flush(data, writer->next);
}

void Curl_cwriter_def_close(struct Curl_easy *data,
                            struct Curl_cwriter *writer)
{
  (void)data;
  (void)writer;
}

static size_t get_max_body_write_len(struct Curl_easy *data, curl_off_t limit)
{
  if(limit != -1) {
    /* How much more are we allowed to write? */
    return curlx_sotouz_range(limit - data->req.bytecount, 0, SIZE_MAX);
  }
  return SIZE_MAX;
}

struct cw_download_ctx {
  struct Curl_cwriter super;
  BIT(started_response);
  BIT(started_body);
};

/* Download client writer in phase CURL_CW_PROTOCOL that
 * sees the "real" download body data. */
static CURLcode cw_download_write(struct Curl_easy *data,
                                  struct Curl_cwriter *writer, int type,
                                  const char *buf, size_t nbytes)
{
  struct cw_download_ctx *ctx = writer->ctx;
  CURLcode result;
  size_t nwrite, excess_len = 0;
  bool is_connect = !!(type & CLIENTWRITE_CONNECT);

  if(!ctx->started_response &&
     !(type & CLIENTWRITE_CONNECT) &&
     (!(type & CLIENTWRITE_INFO) || data->req.upload_done)) {
    Curl_pgrsTime(data, TIMER_STARTTRANSFER);
    ctx->started_response = TRUE;
  }

  if(!(type & CLIENTWRITE_BODY)) {
    if(is_connect && data->set.suppress_connect_headers)
      return CURLE_OK;
#ifdef DEBUGBUILD
    if(is_connect && getenv("CURL_DBG_SUPPRESS_CONNECT_HDS"))
      return CURLE_OK;
#endif
    result = Curl_cwriter_write(data, writer->next, type, buf, nbytes);
    CURL_TRC_WRITE(data, "download_write header(type=%x, blen=%zu) -> %d",
                   (unsigned int)type, nbytes, (int)result);
    return result;
  }

  if(!ctx->started_body &&
     !(type & (CLIENTWRITE_INFO | CLIENTWRITE_CONNECT))) {
    Curl_rlimit_start(&data->progress.dl.rlimit, Curl_pgrs_now(data),
                      data->req.size);
    ctx->started_body = TRUE;
  }

  /* Here, we deal with REAL BODY bytes. All filtering and transfer
   * encodings have been applied and only the true content, e.g. BODY,
   * bytes are passed here.
   * This allows us to check sizes, update stats, etc. independent
   * from the protocol in play. */

  if(data->req.no_body && nbytes > 0) {
    /* BODY arrives although we want none, bail out */
    streamclose(data->conn);
    CURL_TRC_WRITE(data, "download_write body(type=%x, blen=%zu), "
                   "did not want a BODY", (unsigned int)type, nbytes);
    data->req.download_done = TRUE;
    if(data->info.header_size)
      /* if headers have been received, this is fine */
      return CURLE_OK;
    return CURLE_WEIRD_SERVER_REPLY;
  }

  /* Determine if we see any bytes in excess to what is allowed.
   * We write the allowed bytes and handle excess further below.
   * This gives deterministic BODY writes on varying buffer receive
   * lengths. */
  nwrite = nbytes;
  if(data->req.maxdownload != -1) {
    size_t wmax = get_max_body_write_len(data, data->req.maxdownload);
    if(nwrite > wmax) {
      excess_len = nbytes - wmax;
      nwrite = wmax;
    }

    if(nwrite == wmax) {
      data->req.download_done = TRUE;
    }

    if((type & CLIENTWRITE_EOS) && !data->req.no_body &&
       (data->req.size > data->req.bytecount)) {
      failf(data, "end of response with %" FMT_OFF_T " bytes missing",
            data->req.size - data->req.bytecount);
      return CURLE_PARTIAL_FILE;
    }
  }

  /* Error on too large filesize is handled below, after writing
   * the permitted bytes */
  if(data->set.max_filesize && !data->req.ignorebody) {
    size_t wmax = get_max_body_write_len(data, data->set.max_filesize);
    if(nwrite > wmax) {
      nwrite = wmax;
    }
  }

  if(!data->req.ignorebody && (nwrite || (type & CLIENTWRITE_EOS))) {
    result = Curl_cwriter_write(data, writer->next, type, buf, nwrite);
    CURL_TRC_WRITE(data, "download_write body(type=%x, blen=%zu) -> %d",
                   (unsigned int)type, nbytes, (int)result);
    if(result)
      return result;
  }

  /* Update stats, write and report progress */
  if(nwrite) {
    data->req.bytecount += nwrite;
    Curl_pgrs_download_inc(data, nwrite);
  }

  if(excess_len) {
    if(!data->req.ignorebody) {
      infof(data,
            "Excess found writing body:"
            " excess = %zu"
            ", size = %" FMT_OFF_T
            ", maxdownload = %" FMT_OFF_T
            ", bytecount = %" FMT_OFF_T,
            excess_len, data->req.size, data->req.maxdownload,
            data->req.bytecount);
      connclose(data->conn);
    }
  }
  else if((nwrite < nbytes) && !data->req.ignorebody) {
    failf(data, "Exceeded the maximum allowed file size "
          "(%" FMT_OFF_T ") with %" FMT_OFF_T " bytes",
          data->set.max_filesize, data->req.bytecount);
    return CURLE_FILESIZE_EXCEEDED;
  }

  return CURLE_OK;
}

static const struct Curl_cwtype cw_download = {
  "protocol",
  NULL,
  0,
  Curl_cwriter_def_init,
  cw_download_write,
  Curl_cwriter_def_flush,
  Curl_cwriter_def_close,
  sizeof(struct cw_download_ctx)
};

/* RAW client writer in phase CURL_CW_RAW that
 * enabled tracing of raw data. */
static CURLcode cw_raw_write(struct Curl_easy *data,
                             struct Curl_cwriter *writer, int type,
                             const char *buf, size_t nbytes)
{
  if(type & CLIENTWRITE_BODY && data->set.verbose && !data->req.ignorebody) {
    Curl_debug(data, CURLINFO_DATA_IN, buf, nbytes);
  }
  return Curl_cwriter_write(data, writer->next, type, buf, nbytes);
}

static const struct Curl_cwtype cw_raw = {
  "raw",
  NULL,
  0,
  Curl_cwriter_def_init,
  cw_raw_write,
  Curl_cwriter_def_flush,
  Curl_cwriter_def_close,
  sizeof(struct Curl_cwriter)
};

static void cwriter_add(struct Curl_easy *data,
                        struct Curl_cwriter *writer)
{
  struct Curl_cwriter **anchor = &data->req.writer.stack;

  /* Insert the writer as first in its phase.
   * Skip existing writers of lower phases. */
  while(*anchor && (*anchor)->phase < writer->phase)
    anchor = &(*anchor)->next;
  writer->next = *anchor;
  *anchor = writer;
}

static CURLcode do_init_writer_stack(struct Curl_easy *data)
{
  struct Curl_cwriter *writer;
  CURLcode result;

  DEBUGASSERT(!data->req.writer.stack);
  result = Curl_cwriter_create(&data->req.writer.stack,
                               data, &Curl_cwt_out, CURL_CW_CLIENT);
  if(result)
    return result;

  result = Curl_cwriter_create(&writer, data, &cw_download, CURL_CW_PROTOCOL);
  if(result)
    return result;
  cwriter_add(data, writer);

  result = Curl_cwriter_create(&writer, data, &cw_raw, CURL_CW_RAW);
  if(result)
    return result;
  cwriter_add(data, writer);

  return result;
}

/* Curl_client_write() sends data to the write callback(s)

   The bit pattern defines to what "streams" to write to. Body and/or header.
   The defines are in sendf.h of course.
 */
CURLcode Curl_client_write(struct Curl_easy *data, int type, const char *buf,
                           size_t len)
{
  CURLcode result;

  /* it is one of those, at least */
  DEBUGASSERT(type &
              (CLIENTWRITE_BODY | CLIENTWRITE_HEADER | CLIENTWRITE_INFO));
  /* BODY is only BODY (with optional EOS) */
  DEBUGASSERT(!(type & CLIENTWRITE_BODY) ||
              ((type & ~(CLIENTWRITE_BODY | CLIENTWRITE_EOS)) == 0));
  /* INFO is only INFO (with optional EOS) */
  DEBUGASSERT(!(type & CLIENTWRITE_INFO) ||
              ((type & ~(CLIENTWRITE_INFO | CLIENTWRITE_EOS)) == 0));

  if(!data->req.writer.stack) {
    result = do_init_writer_stack(data);
    if(result)
      return result;
    DEBUGASSERT(data->req.writer.stack);
  }

  result = Curl_cwriter_write(data, data->req.writer.stack, type, buf, len);
  CURL_TRC_WRITE(data, "client_write(type=%x, len=%zu) -> %d",
                 (unsigned int)type, len, (int)result);
  return result;
}

CURLcode Curl_client_flush(struct Curl_easy *data)
{
  CURLcode result;

  if(!data->req.writer.stack) {
    result = do_init_writer_stack(data);
    if(result)
      return result;
    DEBUGASSERT(data->req.writer.stack);
  }

  result = Curl_cwriter_flush(data, data->req.writer.stack);
  CURL_TRC_WRITE(data, "client_flush() -> %d", (int)result);
  return result;
}

/* Create an unencoding writer stage using the given handler. */
CURLcode Curl_cwriter_create(struct Curl_cwriter **pwriter,
                             struct Curl_easy *data,
                             const struct Curl_cwtype *cwt,
                             Curl_cwriter_phase phase)
{
  struct Curl_cwriter *writer = NULL;
  CURLcode result = CURLE_OUT_OF_MEMORY;
  void *p;

  DEBUGASSERT(cwt->cwriter_size >= sizeof(struct Curl_cwriter));
  p = curlx_calloc(1, cwt->cwriter_size);
  if(!p)
    goto out;

  writer = (struct Curl_cwriter *)p;
  writer->cwt = cwt;
  writer->ctx = p;
  writer->phase = phase;
  result = cwt->do_init(data, writer);

out:
  *pwriter = result ? NULL : writer;
  if(result)
    curlx_free(writer);
  return result;
}

void Curl_cwriter_free(struct Curl_easy *data,
                       struct Curl_cwriter *writer)
{
  if(writer) {
    writer->cwt->do_close(data, writer);
    curlx_free(writer);
  }
}

size_t Curl_cwriter_count(struct Curl_easy *data, Curl_cwriter_phase phase)
{
  struct Curl_cwriter *w;
  size_t n = 0;

  for(w = data->req.writer.stack; w; w = w->next) {
    if(w->phase == phase)
      ++n;
  }
  return n;
}

static CURLcode cwriter_ensure_pause_writer(struct Curl_easy *data)
{
  struct Curl_cwriter *writer =
    Curl_cwriter_get_by_type(data, &Curl_cwt_pause);
  CURLcode result = CURLE_OK;

  if(!writer) {
    result = Curl_cwriter_create(&writer, data, &Curl_cwt_pause,
                                 CURL_CW_BEFORE_DECODE);
    if(!result)
      cwriter_add(data, writer);
  }
  return result;
}

CURLcode Curl_cwriter_add(struct Curl_easy *data,
                          struct Curl_cwriter *writer)
{
  CURLcode result;
  struct Curl_cwriter **anchor = &data->req.writer.stack;

  if(!*anchor) {
    result = do_init_writer_stack(data);
    if(result)
      return result;
  }

  if(writer->cwt->flags & CURL_CW_FLAG_BLOWUP) {
    /* On adding a writer that may blow up write sizes, e.g. zip bombs,
     * add the pause writer. Do this first as any failure will make the
     * caller destroy the writer again. */
    result = cwriter_ensure_pause_writer(data);
    if(result)
      return result;
  }

  cwriter_add(data, writer);
  return CURLE_OK;
}

struct Curl_cwriter *Curl_cwriter_get_by_name(struct Curl_easy *data,
                                              const char *name)
{
  struct Curl_cwriter *writer;
  for(writer = data->req.writer.stack; writer; writer = writer->next) {
    if(!strcmp(name, writer->cwt->name))
      return writer;
  }
  return NULL;
}

struct Curl_cwriter *Curl_cwriter_get_by_type(struct Curl_easy *data,
                                              const struct Curl_cwtype *cwt)
{
  struct Curl_cwriter *writer;
  for(writer = data->req.writer.stack; writer; writer = writer->next) {
    if(writer->cwt == cwt)
      return writer;
  }
  return NULL;
}

CURLcode Curl_cwriter_unpause(struct Curl_easy *data)
{
  data->req.writer.paused = FALSE;
  return Curl_cwriter_flush(data, data->req.writer.stack);
}

CURLcode Curl_creader_read(struct Curl_easy *data,
                           struct Curl_creader *reader,
                           char *buf, size_t blen, size_t *nread, bool *eos)
{
  *nread = 0;
  *eos = FALSE;
  if(!reader)
    return CURLE_READ_ERROR;
  return reader->crt->do_read(data, reader, buf, blen, nread, eos);
}

void Curl_creader_clear_eos(struct Curl_easy *data,
                            struct Curl_creader *reader)
{
  while(reader) {
    (void)reader->crt->cntrl(data, reader, CURL_CRCNTRL_CLEAR_EOS);
    reader = reader->next;
  }
}

CURLcode Curl_creader_def_init(struct Curl_easy *data,
                               struct Curl_creader *reader)
{
  (void)data;
  (void)reader;
  return CURLE_OK;
}

void Curl_creader_def_close(struct Curl_easy *data,
                            struct Curl_creader *reader)
{
  (void)data;
  (void)reader;
}

CURLcode Curl_creader_def_read(struct Curl_easy *data,
                               struct Curl_creader *reader,
                               char *buf, size_t blen,
                               size_t *nread, bool *eos)
{
  if(reader->next)
    return reader->next->crt->do_read(data, reader->next, buf, blen,
                                      nread, eos);
  else {
    *nread = 0;
    *eos = FALSE;
    return CURLE_READ_ERROR;
  }
}

bool Curl_creader_def_needs_rewind(struct Curl_easy *data,
                                   struct Curl_creader *reader)
{
  (void)data;
  (void)reader;
  return FALSE;
}

curl_off_t Curl_creader_def_total_length(struct Curl_easy *data,
                                         struct Curl_creader *reader)
{
  return reader->next ?
         reader->next->crt->total_length(data, reader->next) : -1;
}

CURLcode Curl_creader_def_resume_from(struct Curl_easy *data,
                                      struct Curl_creader *reader,
                                      curl_off_t offset)
{
  (void)data;
  (void)reader;
  (void)offset;
  return CURLE_READ_ERROR;
}

CURLcode Curl_creader_def_cntrl(struct Curl_easy *data,
                                struct Curl_creader *reader,
                                Curl_creader_cntrl opcode)
{
  (void)data;
  (void)reader;
  (void)opcode;
  return CURLE_OK;
}

bool Curl_creader_def_is_paused(struct Curl_easy *data,
                                struct Curl_creader *reader)
{
  (void)data;
  (void)reader;
  return FALSE;
}

void Curl_creader_def_done(struct Curl_easy *data,
                           struct Curl_creader *reader, int premature)
{
  (void)data;
  (void)reader;
  (void)premature;
}

struct cr_in_ctx {
  struct Curl_creader super;
  curl_read_callback read_cb;
  void *cb_user_data;
  curl_off_t total_len;
  curl_off_t read_len;
  CURLcode error_result;
  BIT(seen_eos);
  BIT(errored);
  BIT(has_used_cb);
  BIT(is_paused);
};

static CURLcode cr_in_init(struct Curl_easy *data, struct Curl_creader *reader)
{
  struct cr_in_ctx *ctx = reader->ctx;
  ctx->read_cb = data->state.fread_func;
  ctx->cb_user_data = data->state.in;
  ctx->total_len = -1;
  ctx->read_len = 0;
  return CURLE_OK;
}

/* Real client reader to installed client callbacks. */
static CURLcode cr_in_read(struct Curl_easy *data,
                           struct Curl_creader *reader,
                           char *buf, size_t blen,
                           size_t *pnread, bool *peos)
{
  struct cr_in_ctx *ctx = reader->ctx;
  CURLcode result = CURLE_OK;
  size_t nread;

  ctx->is_paused = FALSE;

  /* Once we have errored, we will return the same error forever */
  if(ctx->errored) {
    *pnread = 0;
    *peos = FALSE;
    return ctx->error_result;
  }
  if(ctx->seen_eos) {
    *pnread = 0;
    *peos = TRUE;
    return CURLE_OK;
  }
  /* respect length limitations */
  if(ctx->total_len >= 0) {
    blen = curlx_sotouz_range(ctx->total_len - ctx->read_len, 0, blen);
  }
  nread = 0;
  if(ctx->read_cb && blen) {
    struct Curl_mapi_guard guard;
    CURL_CBAPI_START(&guard, data, easy_cr_in_read);
    nread = ctx->read_cb(buf, 1, blen, ctx->cb_user_data);
    CURL_CBAPI_END(&guard);
    ctx->has_used_cb = TRUE;
  }

  switch(nread) {
  case 0:
    if((ctx->total_len >= 0) && (ctx->read_len < ctx->total_len)) {
      failf(data, "client read function EOF fail, "
            "only %" FMT_OFF_T "/%" FMT_OFF_T " of needed bytes read",
            ctx->read_len, ctx->total_len);
      result = CURLE_READ_ERROR;
      break;
    }
    *pnread = 0;
    *peos = TRUE;
    ctx->seen_eos = TRUE;
    break;

  case CURL_READFUNC_ABORT:
    failf(data, "operation aborted by callback");
    *pnread = 0;
    *peos = FALSE;
    ctx->errored = TRUE;
    ctx->error_result = CURLE_ABORTED_BY_CALLBACK;
    result = CURLE_ABORTED_BY_CALLBACK;
    break;

  case CURL_READFUNC_PAUSE:
    if(data->conn->scheme->flags & PROTOPT_NONETWORK) {
      /* protocols that work without network cannot be paused. This is
         actually only file:// now, and it cannot pause since the transfer
         is not done using the "normal" procedure. */
      failf(data, "Read callback asked for PAUSE when not supported");
      result = CURLE_READ_ERROR;
      break;
    }
    /* CURL_READFUNC_PAUSE pauses read callbacks that feed socket writes */
    CURL_TRC_READ(data, "cr_in_read, callback returned CURL_READFUNC_PAUSE");
    ctx->is_paused = TRUE;
    *pnread = 0;
    *peos = FALSE;
    result = Curl_xfer_pause_send(data, TRUE);
    break; /* nothing was read */

  default:
    if(nread > blen) {
      /* the read function returned a too large value */
      failf(data, "read function returned funny value");
      *pnread = 0;
      *peos = FALSE;
      ctx->errored = TRUE;
      ctx->error_result = CURLE_READ_ERROR;
      result = CURLE_READ_ERROR;
      break;
    }
    ctx->read_len += nread;
    if(ctx->total_len >= 0)
      ctx->seen_eos = (ctx->read_len >= ctx->total_len);
    *pnread = nread;
    *peos = (bool)ctx->seen_eos;
    break;
  }
  CURL_TRC_READ(data, "cr_in_read(len=%zu, total=%" FMT_OFF_T
                ", read=%" FMT_OFF_T ") -> %d, nread=%zu, eos=%d",
                blen, ctx->total_len, ctx->read_len, (int)result,
                *pnread, *peos);
  return result;
}

static bool cr_in_needs_rewind(struct Curl_easy *data,
                               struct Curl_creader *reader)
{
  struct cr_in_ctx *ctx = reader->ctx;
  (void)data;
  return (bool)ctx->has_used_cb;
}

static curl_off_t cr_in_total_length(struct Curl_easy *data,
                                     struct Curl_creader *reader)
{
  struct cr_in_ctx *ctx = reader->ctx;
  (void)data;
  return ctx->total_len;
}

static CURLcode cr_in_resume_from(struct Curl_easy *data,
                                  struct Curl_creader *reader,
                                  curl_off_t offset)
{
  struct cr_in_ctx *ctx = reader->ctx;
  int seekerr = CURL_SEEKFUNC_CANTSEEK;

  DEBUGASSERT(data->conn);
  /* already started reading? */
  if(ctx->read_len)
    return CURLE_READ_ERROR;

  if(data->set.seek_func) {
    struct Curl_mapi_guard guard;
    CURL_CBAPI_START(&guard, data, easy_seek_func);
    seekerr = data->set.seek_func(data->set.seek_client, offset, SEEK_SET);
    CURL_CBAPI_END(&guard);
  }

  if(seekerr != CURL_SEEKFUNC_OK) {
    curl_off_t passed = 0;

    if(seekerr != CURL_SEEKFUNC_CANTSEEK) {
      failf(data, "Could not seek stream");
      return CURLE_READ_ERROR;
    }
    /* when seekerr == CURL_SEEKFUNC_CANTSEEK (cannot seek to offset) */
    do {
      struct Curl_mapi_guard guard;
      char scratch[4 * 1024];
      size_t readthisamountnow =
        (offset - passed > (curl_off_t)sizeof(scratch)) ?
        sizeof(scratch) :
        curlx_sotouz(offset - passed);
      size_t actuallyread;

      CURL_CBAPI_START(&guard, data, easy_cr_in_resume_from);
      actuallyread = ctx->read_cb(scratch, 1, readthisamountnow,
                                  ctx->cb_user_data);
      CURL_CBAPI_END(&guard);

      passed += actuallyread;
      if((actuallyread == 0) || (actuallyread > readthisamountnow)) {
        /* this checks for greater-than only to make sure that the
           CURL_READFUNC_ABORT return code still aborts */
        failf(data, "Could only read %" FMT_OFF_T " bytes from the input",
              passed);
        return CURLE_READ_ERROR;
      }
    } while(passed < offset);
  }

  /* now, decrease the size of the read */
  if(ctx->total_len > 0) {
    ctx->total_len -= offset;

    if(ctx->total_len <= 0) {
      failf(data, "File already completely uploaded");
      return CURLE_PARTIAL_FILE;
    }
  }
  /* we have passed, proceed as normal */
  return CURLE_OK;
}

static CURLcode cr_in_rewind(struct Curl_easy *data,
                             struct Curl_creader *reader)
{
  struct cr_in_ctx *ctx = reader->ctx;

  /* If we never invoked the callback, there is noting to rewind */
  if(!ctx->has_used_cb)
    return CURLE_OK;

  if(data->set.seek_func) {
    struct Curl_mapi_guard guard;
    int err;

    CURL_CBAPI_START(&guard, data, easy_seek_func);
    err = data->set.seek_func(data->set.seek_client, 0, SEEK_SET);
    CURL_CBAPI_END(&guard);
    CURL_TRC_READ(data, "cr_in, rewind via set.seek_func -> %d", err);
    if(err) {
      failf(data, "seek callback returned error %d", err);
      return CURLE_SEND_FAIL_REWIND;
    }
  }
  else if(data->set.ioctl_func) {
    struct Curl_mapi_guard guard;
    curlioerr err;

    CURL_CBAPI_START(&guard, data, easy_ioctl_func);
    err = data->set.ioctl_func(data, CURLIOCMD_RESTARTREAD,
                               data->set.ioctl_client);
    CURL_CBAPI_END(&guard);
    CURL_TRC_READ(data, "cr_in, rewind via set.ioctl_func -> %d", (int)err);
    if(err) {
      failf(data, "ioctl callback returned error %d", (int)err);
      return CURLE_SEND_FAIL_REWIND;
    }
  }
  else {
    /* If no CURLOPT_READFUNCTION is used, we know that we operate on a
       given FILE * stream and we can actually attempt to rewind that
       ourselves with fseek() */
#if defined(__clang__) && __clang_major__ >= 16
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wcast-function-type-strict"
#endif
    if(data->state.fread_func == (curl_read_callback)fread) {
#if defined(__clang__) && __clang_major__ >= 16
#pragma clang diagnostic pop
#endif
      int err = fseek(data->state.in, 0, SEEK_SET);
      CURL_TRC_READ(data, "cr_in, rewind via fseek -> %d(%d)",
                    (int)err, (int)errno);
      if(err != -1)
        /* successful rewind */
        return CURLE_OK;
    }

    /* no callback set or failure above, makes us fail at once */
    failf(data, "necessary data rewind was not possible");
    return CURLE_SEND_FAIL_REWIND;
  }
  return CURLE_OK;
}

static CURLcode cr_in_cntrl(struct Curl_easy *data,
                            struct Curl_creader *reader,
                            Curl_creader_cntrl opcode)
{
  struct cr_in_ctx *ctx = reader->ctx;

  switch(opcode) {
  case CURL_CRCNTRL_REWIND:
    return cr_in_rewind(data, reader);
  case CURL_CRCNTRL_UNPAUSE:
    ctx->is_paused = FALSE;
    break;
  case CURL_CRCNTRL_CLEAR_EOS:
    ctx->seen_eos = FALSE;
    break;
  default:
    break;
  }
  return CURLE_OK;
}

static bool cr_in_is_paused(struct Curl_easy *data,
                            struct Curl_creader *reader)
{
  struct cr_in_ctx *ctx = reader->ctx;
  (void)data;
  return (bool)ctx->is_paused;
}

static const struct Curl_crtype cr_in = {
  "cr-in",
  cr_in_init,
  cr_in_read,
  Curl_creader_def_close,
  cr_in_needs_rewind,
  cr_in_total_length,
  cr_in_resume_from,
  cr_in_cntrl,
  cr_in_is_paused,
  Curl_creader_def_done,
  sizeof(struct cr_in_ctx)
};

CURLcode Curl_creader_create(struct Curl_creader **preader,
                             struct Curl_easy *data,
                             const struct Curl_crtype *crt,
                             Curl_creader_phase phase)
{
  struct Curl_creader *reader = NULL;
  CURLcode result = CURLE_OUT_OF_MEMORY;
  void *p;

  DEBUGASSERT(crt->creader_size >= sizeof(struct Curl_creader));
  p = curlx_calloc(1, crt->creader_size);
  if(!p)
    goto out;

  reader = (struct Curl_creader *)p;
  reader->crt = crt;
  reader->ctx = p;
  reader->phase = phase;
  result = crt->do_init(data, reader);

out:
  *preader = result ? NULL : reader;
  if(result)
    curlx_free(reader);
  return result;
}

void Curl_creader_free(struct Curl_easy *data, struct Curl_creader *reader)
{
  if(reader) {
    reader->crt->do_close(data, reader);
    curlx_free(reader);
  }
}

struct cr_lc_ctx {
  struct Curl_creader super;
  struct bufq buf;
  BIT(read_eos);  /* we read an EOS from the next reader */
  BIT(eos);       /* we have returned an EOS */
  BIT(prev_cr);   /* the last byte was a CR */
};

static CURLcode cr_lc_init(struct Curl_easy *data, struct Curl_creader *reader)
{
  struct cr_lc_ctx *ctx = reader->ctx;
  (void)data;
  Curl_bufq_init2(&ctx->buf, (16 * 1024), 1, BUFQ_OPT_SOFT_LIMIT);
  return CURLE_OK;
}

static void cr_lc_close(struct Curl_easy *data, struct Curl_creader *reader)
{
  struct cr_lc_ctx *ctx = reader->ctx;
  (void)data;
  Curl_bufq_free(&ctx->buf);
}

/* client reader doing line end conversions. */
static CURLcode cr_lc_read(struct Curl_easy *data,
                           struct Curl_creader *reader,
                           char *buf, size_t blen,
                           size_t *pnread, bool *peos)
{
  struct cr_lc_ctx *ctx = reader->ctx;
  CURLcode result;
  size_t nread, i, start, n;
  bool eos;

  if(ctx->eos) {
    *pnread = 0;
    *peos = TRUE;
    return CURLE_OK;
  }

  if(Curl_bufq_is_empty(&ctx->buf)) {
    if(ctx->read_eos) {
      ctx->eos = TRUE;
      *pnread = 0;
      *peos = TRUE;
      return CURLE_OK;
    }
    /* Still getting data form the next reader, ctx->buf is empty */
    result = Curl_creader_read(data, reader->next, buf, blen, &nread, &eos);
    if(result)
      return result;
    ctx->read_eos = eos;

    if(!nread || !memchr(buf, '\n', nread)) {
      /* nothing to convert, return this right away */
      if(nread)
        ctx->prev_cr = (buf[nread - 1] == '\r');
      if(ctx->read_eos)
        ctx->eos = TRUE;
      *pnread = nread;
      *peos = (bool)ctx->eos;
      goto out;
    }

    /* at least one \n might need conversion to '\r\n', place into ctx->buf */
    for(i = start = 0; i < nread; ++i) {
      /* if this byte is not an LF character, or if the preceding character is
         a CR (meaning this already is a CRLF pair), go to next */
      if((buf[i] != '\n') || ctx->prev_cr) {
        ctx->prev_cr = (buf[i] == '\r');
        continue;
      }
      ctx->prev_cr = FALSE;
      /* on a soft limit bufq, we do not need to check length */
      result = Curl_bufq_cwrite(&ctx->buf, buf + start, i - start, &n);
      if(!result)
        result = Curl_bufq_cwrite(&ctx->buf, STRCONST("\r\n"), &n);
      if(result)
        return result;
      start = i + 1;
    }

    if(start < i) { /* leftover */
      result = Curl_bufq_cwrite(&ctx->buf, buf + start, i - start, &n);
      if(result)
        return result;
    }
  }

  DEBUGASSERT(!Curl_bufq_is_empty(&ctx->buf));
  *peos = FALSE;
  result = Curl_bufq_cread(&ctx->buf, buf, blen, pnread);
  if(!result && ctx->read_eos && Curl_bufq_is_empty(&ctx->buf)) {
    /* no more data, read all, done. */
    ctx->eos = TRUE;
    *peos = TRUE;
  }

out:
  CURL_TRC_READ(data, "cr_lc_read(len=%zu) -> %d, nread=%zu, eos=%d",
                blen, (int)result, *pnread, *peos);
  return result;
}

static curl_off_t cr_lc_total_length(struct Curl_easy *data,
                                     struct Curl_creader *reader)
{
  /* this reader changes length depending on input */
  (void)data;
  (void)reader;
  return -1;
}

static const struct Curl_crtype cr_lc = {
  "cr-lineconv",
  cr_lc_init,
  cr_lc_read,
  cr_lc_close,
  Curl_creader_def_needs_rewind,
  cr_lc_total_length,
  Curl_creader_def_resume_from,
  Curl_creader_def_cntrl,
  Curl_creader_def_is_paused,
  Curl_creader_def_done,
  sizeof(struct cr_lc_ctx)
};

static CURLcode cr_lc_add(struct Curl_easy *data)
{
  struct Curl_creader *reader = NULL;
  CURLcode result;

  result = Curl_creader_create(&reader, data, &cr_lc, CURL_CR_CONTENT_ENCODE);
  if(!result)
    result = Curl_creader_add(data, reader);

  if(result && reader)
    Curl_creader_free(data, reader);
  return result;
}

static CURLcode do_init_reader_stack(struct Curl_easy *data,
                                     struct Curl_creader *r)
{
  CURLcode result = CURLE_OK;
  curl_off_t clen;

  DEBUGASSERT(r);
  DEBUGASSERT(r->crt);
  DEBUGASSERT(r->phase == CURL_CR_CLIENT);
  DEBUGASSERT(!data->req.reader.stack);

  data->req.reader.stack = r;
  clen = r->crt->total_length(data, r);
  /* if we do not have 0 length init, and CRLF conversion is wanted,
   * add the reader for it */
  if(clen &&
#ifdef CURL_PREFER_LF_LINEENDS
    (data->set.crlf || data->state.prefer_ascii)
#else
    data->set.crlf
#endif
    ) {
    result = cr_lc_add(data);
    if(result)
      return result;
  }

  return result;
}

CURLcode Curl_creader_set_fread(struct Curl_easy *data, curl_off_t len)
{
  CURLcode result;
  struct Curl_creader *r;
  struct cr_in_ctx *ctx;

  result = Curl_creader_create(&r, data, &cr_in, CURL_CR_CLIENT);
  if(result || !r)
    goto out;
  ctx = r->ctx;
  ctx->total_len = len;

  cl_reset_reader(data);
  result = do_init_reader_stack(data, r);
out:
  CURL_TRC_READ(data, "add fread reader, len=%" FMT_OFF_T " -> %d",
                len, (int)result);
  return result;
}

CURLcode Curl_creader_add(struct Curl_easy *data,
                          struct Curl_creader *reader)
{
  CURLcode result;
  struct Curl_creader **anchor = &data->req.reader.stack;

  if(!*anchor) {
    result = Curl_creader_set_fread(data, data->state.infilesize);
    if(result)
      return result;
  }

  /* Insert the writer as first in its phase.
   * Skip existing readers of lower phases. */
  while(*anchor && (*anchor)->phase < reader->phase)
    anchor = &(*anchor)->next;
  reader->next = *anchor;
  *anchor = reader;
  return CURLE_OK;
}

CURLcode Curl_creader_set(struct Curl_easy *data, struct Curl_creader *r)
{
  CURLcode result;

  DEBUGASSERT(r);
  DEBUGASSERT(r->crt);
  DEBUGASSERT(r->phase == CURL_CR_CLIENT);

  cl_reset_reader(data);
  result = do_init_reader_stack(data, r);
  if(result)
    Curl_creader_free(data, r);
  return result;
}

CURLcode Curl_client_read(struct Curl_easy *data, char *buf, size_t blen,
                          size_t *nread, bool *eos)
{
  CURLcode result;

  DEBUGASSERT(buf);
  DEBUGASSERT(blen);
  DEBUGASSERT(nread);
  DEBUGASSERT(eos);
  *nread = 0;

  if(!data->req.reader.stack) {
    result = Curl_creader_set_fread(data, data->state.infilesize);
    if(result)
      return result;
    DEBUGASSERT(data->req.reader.stack);
  }
  if(!data->req.reader_started) {
    Curl_rlimit_start(&data->progress.ul.rlimit, Curl_pgrs_now(data), -1);
    data->req.reader_started = TRUE;
  }

  if(Curl_rlimit_active(&data->progress.ul.rlimit)) {
    curl_off_t ul_avail = Curl_rlimit_avail(&data->progress.ul.rlimit, NULL);
    if(ul_avail <= 0) {
      result = CURLE_OK;
      *eos = FALSE;
      goto out;
    }
    if(ul_avail < (curl_off_t)blen)
      blen = (size_t)ul_avail;
  }
  result = Curl_creader_read(data, data->req.reader.stack, buf, blen,
                             nread, eos);

out:
  CURL_TRC_READ(data, "client_read(len=%zu) -> %d, nread=%zu, eos=%d",
                blen, (int)result, *nread, *eos);
  return result;
}

bool Curl_creader_needs_rewind(struct Curl_easy *data)
{
  struct Curl_creader *reader = data->req.reader.stack;
  while(reader) {
    if(reader->crt->needs_rewind(data, reader)) {
      CURL_TRC_READ(data, "client reader needs rewind before next request");
      return TRUE;
    }
    reader = reader->next;
  }
  return FALSE;
}

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

static CURLcode cr_null_read(struct Curl_easy *data,
                             struct Curl_creader *reader,
                             char *buf, size_t blen,
                             size_t *pnread, bool *peos)
{
  (void)data;
  (void)reader;
  (void)buf;
  (void)blen;
  *pnread = 0;
  *peos = TRUE;
  return CURLE_OK;
}

static curl_off_t cr_null_total_length(struct Curl_easy *data,
                                       struct Curl_creader *reader)
{
  /* this reader changes length depending on input */
  (void)data;
  (void)reader;
  return 0;
}

static const struct Curl_crtype cr_null = {
  "cr-null",
  Curl_creader_def_init,
  cr_null_read,
  Curl_creader_def_close,
  Curl_creader_def_needs_rewind,
  cr_null_total_length,
  Curl_creader_def_resume_from,
  Curl_creader_def_cntrl,
  Curl_creader_def_is_paused,
  Curl_creader_def_done,
  sizeof(struct Curl_creader)
};

CURLcode Curl_creader_set_null(struct Curl_easy *data)
{
  struct Curl_creader *r;
  CURLcode result;

  result = Curl_creader_create(&r, data, &cr_null, CURL_CR_CLIENT);
  if(result)
    return result;

  cl_reset_reader(data);
  return do_init_reader_stack(data, r);
}

struct cr_buf_ctx {
  struct Curl_creader super;
  const char *buf;
  size_t blen;
  size_t index;
};

static CURLcode cr_buf_read(struct Curl_easy *data,
                            struct Curl_creader *reader,
                            char *buf, size_t blen,
                            size_t *pnread, bool *peos)
{
  struct cr_buf_ctx *ctx = reader->ctx;
  size_t nread = ctx->blen - ctx->index;

  if(!nread || !ctx->buf) {
    *pnread = 0;
    *peos = TRUE;
  }
  else {
    if(nread > blen)
      nread = blen;
    memcpy(buf, ctx->buf + ctx->index, nread);
    *pnread = nread;
    ctx->index += nread;
    *peos = (ctx->index == ctx->blen);
  }
  CURL_TRC_READ(data, "cr_buf_read(len=%zu) -> 0, nread=%zu, eos=%d",
                blen, *pnread, *peos);
  return CURLE_OK;
}

static bool cr_buf_needs_rewind(struct Curl_easy *data,
                                struct Curl_creader *reader)
{
  struct cr_buf_ctx *ctx = reader->ctx;
  (void)data;
  return ctx->index > 0;
}

static CURLcode cr_buf_cntrl(struct Curl_easy *data,
                             struct Curl_creader *reader,
                             Curl_creader_cntrl opcode)
{
  struct cr_buf_ctx *ctx = reader->ctx;
  (void)data;
  switch(opcode) {
  case CURL_CRCNTRL_REWIND:
    ctx->index = 0;
    break;
  default:
    break;
  }
  return CURLE_OK;
}

static curl_off_t cr_buf_total_length(struct Curl_easy *data,
                                      struct Curl_creader *reader)
{
  struct cr_buf_ctx *ctx = reader->ctx;
  (void)data;
  return (curl_off_t)ctx->blen;
}

static CURLcode cr_buf_resume_from(struct Curl_easy *data,
                                   struct Curl_creader *reader,
                                   curl_off_t offset)
{
  struct cr_buf_ctx *ctx = reader->ctx;
  size_t boffset;

  (void)data;
  DEBUGASSERT(data->conn);
  /* already started reading? */
  if(ctx->index)
    return CURLE_READ_ERROR;
  boffset = curlx_sotouz_range(offset, 0, SIZE_MAX);
  if(!boffset)
    return CURLE_OK;
  if(boffset > ctx->blen)
    return CURLE_READ_ERROR;

  ctx->buf += boffset;
  ctx->blen -= boffset;
  return CURLE_OK;
}

static const struct Curl_crtype cr_buf = {
  "cr-buf",
  Curl_creader_def_init,
  cr_buf_read,
  Curl_creader_def_close,
  cr_buf_needs_rewind,
  cr_buf_total_length,
  cr_buf_resume_from,
  cr_buf_cntrl,
  Curl_creader_def_is_paused,
  Curl_creader_def_done,
  sizeof(struct cr_buf_ctx)
};

CURLcode Curl_creader_set_buf(struct Curl_easy *data,
                              const char *buf, size_t blen)
{
  CURLcode result;
  struct Curl_creader *r;
  struct cr_buf_ctx *ctx;

  result = Curl_creader_create(&r, data, &cr_buf, CURL_CR_CLIENT);
  if(result)
    goto out;
  ctx = r->ctx;
  ctx->buf = buf;
  ctx->blen = blen;
  ctx->index = 0;

  cl_reset_reader(data);
  result = do_init_reader_stack(data, r);
out:
  CURL_TRC_READ(data, "add buf reader, len=%zu -> %d", blen, (int)result);
  return result;
}

curl_off_t Curl_creader_total_length(struct Curl_easy *data)
{
  struct Curl_creader *r = data->req.reader.stack;
  return r ? r->crt->total_length(data, r) : -1;
}

curl_off_t Curl_creader_client_length(struct Curl_easy *data)
{
  struct Curl_creader *r = data->req.reader.stack;
  while(r && r->phase != CURL_CR_CLIENT)
    r = r->next;
  return r ? r->crt->total_length(data, r) : -1;
}

CURLcode Curl_creader_unpause(struct Curl_easy *data)
{
  struct Curl_creader *reader = data->req.reader.stack;
  CURLcode result = CURLE_OK;

  while(reader) {
    result = reader->crt->cntrl(data, reader, CURL_CRCNTRL_UNPAUSE);
    CURL_TRC_READ(data, "unpausing %s -> %d", reader->crt->name, (int)result);
    if(result)
      break;
    reader = reader->next;
  }
  return result;
}

bool Curl_creader_is_paused(struct Curl_easy *data)
{
  struct Curl_creader *reader = data->req.reader.stack;

  while(reader) {
    if(reader->crt->is_paused(data, reader))
      return TRUE;
    reader = reader->next;
  }
  return FALSE;
}

void Curl_creader_done(struct Curl_easy *data, int premature)
{
  struct Curl_creader *reader = data->req.reader.stack;
  while(reader) {
    reader->crt->done(data, reader, premature);
    reader = reader->next;
  }
}

struct Curl_creader *Curl_creader_get_by_type(struct Curl_easy *data,
                                              const struct Curl_crtype *crt)
{
  struct Curl_creader *r;
  for(r = data->req.reader.stack; r; r = r->next) {
    if(r->crt == crt)
      return r;
  }
  return NULL;
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
  return CURL_EASY_STR(data, STRING_CUSTOMREQUEST);
}

const char *Curl_pop3_smtp_get_mail_from(const struct Curl_easy *data)
{
  return CURL_EASY_STR(data, STRING_MAIL_FROM);
}

const char *Curl_pop3_smtp_get_mail_auth(const struct Curl_easy *data)
{
  return CURL_EASY_STR(data, STRING_MAIL_AUTH);
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
  return &multi->resolv_thrdq;
}

struct curl_thrdq *Curl_zig_multi_get_resolv_thrdq(
  const struct Curl_multi *multi)
{
  return multi ? multi->resolv_thrdq : NULL;
}

void Curl_zig_multi_set_resolv_thrdq(struct Curl_multi *multi,
                                     struct curl_thrdq *thrdq)
{
  multi->resolv_thrdq = thrdq;
}

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
  CURL_THRDQ_TRACE(tqueue, data);
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
