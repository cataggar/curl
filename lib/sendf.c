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
