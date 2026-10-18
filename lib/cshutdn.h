#ifndef HEADER_CURL_CSHUTDN_H
#define HEADER_CURL_CSHUTDN_H
/***************************************************************************
 *                                  _   _ ____  _
 *  Project                     ___| | | |  _ \| |
 *                             / __| | | | |_) | |
 *                            | (__| |_| |  _ <| |___
 *                             \___|\___/|_| \_\_____|
 *
 * Copyright (C) Daniel Stenberg, <daniel@haxx.se>, et al.
 * Copyright (C) Linus Nielsen Feltzing, <linus@haxx.se>
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
#include "ptrarray.h"

struct connectdata;
struct Curl_easy;
struct curl_pollfds;
struct Curl_waitfds;
struct Curl_multi;
struct Curl_share;
struct Curl_sigpipe_ctx;


/* Terminates the connection, e.g. closes and destroys it.
 * If `do_shutdown` is TRUE, the shutdown will be run once.
 * Takes ownership of `conn`. `conn` MUST no longer be in
 * a pool or on a shutdown list. */
void Curl_cshutdn_terminate(struct Curl_easy *admin,
                            struct connectdata *conn,
                            bool do_shutdown);

/* Start the shutdown timer,
 * marks the connection sockindex as being shut down. */
void Curl_cshutdn_start_timer(struct Curl_easy *data, int8_t sockindex,
                              int timeout_ms);
/* Clear the shutdown timer at sockindex again. */
void Curl_cshutdn_clear_timer(struct Curl_easy *data, int8_t sockindex);

/* return how much time there is left to shutdown the connection at
 * sockindex. Returns 0 if there is no limit or shutdown has not started. */
timediff_t Curl_cshutdn_timeleft_ms(struct Curl_easy *data,
                                    struct connectdata *conn,
                                    int8_t sockindex);

#define CURL_CONN_IN_SHUTDOWN(c,i)   ((c)->shutdown.start_ms[(i)] >= 0)

/* Shutdown the connection at `sockindex` non-blocking.
 * Will start the shutdown timer if not already set.
 * Return CURLE_OK and *done == FALSE if not finished. */
CURLcode Curl_cshutdn_try_once_idx(struct Curl_easy *data,
                                   int8_t sockindex, bool *done);

/* Run the shutdown of the connection once non-blocking for both
 * socket indices. Will start the shutdown timer if not already set.
 * Shortly attach/detach the admin handle to `conn` while doing so.
 * `done` will be set TRUE if any error was encountered or if
 * the connection was shut down completely. */
void Curl_cshutdn_try_once(struct Curl_easy *admin,
                           struct connectdata *conn, bool *done);

/* A `cshutdown` is always owned by a multi handle to maintain
 * the connections to be shut down. It registers timers and
 * sockets to monitor via the multi handle. */
struct cshutdn {
  struct ptrarray conns;    /* connections being shut down */
};

/* Init as part of the given multi handle. */
void Curl_cshutdn_init(struct cshutdn *cshutdn);

/* Terminate all remaining connections and free resources. */
void Curl_cshutdn_destroy(struct cshutdn *cshutdn,
                          struct Curl_easy *admin);

/* Number of connections being shut down. */
size_t Curl_cshutdn_count(struct cshutdn *cshutdn);

/* Number of connections to the destination being shut down. */
size_t Curl_cshutdn_dest_count(struct cshutdn *cshutdn,
                               const char *destination);

/* Close the oldest `count` connections in shutdown to destination or,
 * when destination is NULL for any destination.
 * Return the number of connections closed. */
size_t Curl_cshutdn_close_oldest(struct cshutdn *cshutdn,
                                 struct Curl_easy *admin,
                                 const char *destination,
                                 size_t count);

/* Add a connection to have it shut down. Terminate the oldest
 * connection when shutdowns exceed max_shutdowns. */
void Curl_cshutdn_add(struct cshutdn *cshutdn,
                      struct Curl_multi *multi,
                      struct connectdata *conn,
                      size_t max_shutdowns);

/* Add sockets and POLLIN/OUT flags for connections being shut down. */
CURLcode Curl_cshutdn_add_pollfds(struct cshutdn *cshutdn,
                                  struct Curl_easy *admin,
                                  struct curl_pollfds *cpfds);

unsigned int Curl_cshutdn_add_waitfds(struct cshutdn *cshutdn,
                                      struct Curl_easy *admin,
                                      struct Curl_waitfds *cwfds);

void Curl_cshutdn_setfds(struct cshutdn *cshutdn,
                         struct Curl_easy *admin,
                         fd_set *read_fd_set, fd_set *write_fd_set,
                         int *maxfd);

/* Run maintenance on all connections. */
void Curl_cshutdn_perform(struct cshutdn *cshutdn,
                          struct Curl_easy *admin,
                          struct Curl_sigpipe_ctx *sigpipe_ctx);

#endif /* HEADER_CURL_CSHUTDN_H */

#if defined(HEADER_CURL_VSSH_VSSH_H) && !defined(CURL_CSHUTDN_HELPERS_EMITTED)
#define CURL_CSHUTDN_HELPERS_EMITTED
#include "urldata.h"
#include "url.h"
#include "cfilters.h"
#include "progress.h"
#include "multiif.h"
#include "multi_ev.h"
#include "sigpipe.h"
#include "select.h"

void Curl_cshutdn_conn_get_times(struct connectdata *conn,
                                 int8_t sockindex,
                                 timediff_t *start_ms,
                                 timediff_t *timeout_ms,
                                 struct curltime *created);
void Curl_cshutdn_conn_get_times(struct connectdata *conn,
                                 int8_t sockindex,
                                 timediff_t *start_ms,
                                 timediff_t *timeout_ms,
                                 struct curltime *created)
{
  *start_ms = conn->shutdown.start_ms[sockindex];
  *timeout_ms = conn->shutdown.timeout_ms;
  *created = conn->created;
}

void Curl_cshutdn_conn_set_times(struct connectdata *conn,
                                 int8_t sockindex,
                                 timediff_t start_ms,
                                 timediff_t timeout_ms);
void Curl_cshutdn_conn_set_times(struct connectdata *conn,
                                 int8_t sockindex,
                                 timediff_t start_ms,
                                 timediff_t timeout_ms)
{
  conn->shutdown.start_ms[sockindex] = start_ms;
  conn->shutdown.timeout_ms = timeout_ms;
}

void Curl_cshutdn_conn_clear_start(struct connectdata *conn, int8_t sockindex);
void Curl_cshutdn_conn_clear_start(struct connectdata *conn, int8_t sockindex)
{
  conn->shutdown.start_ms[sockindex] = -1;
}

struct Curl_cfilter *Curl_cshutdn_conn_get_cfilter(struct connectdata *conn,
                                                   int8_t sockindex);
struct Curl_cfilter *Curl_cshutdn_conn_get_cfilter(struct connectdata *conn,
                                                   int8_t sockindex)
{
  return conn->cfilter[sockindex];
}

const char *Curl_cshutdn_conn_get_dest(struct connectdata *conn);
const char *Curl_cshutdn_conn_get_dest(struct connectdata *conn)
{
  return conn->destination;
}

void Curl_cshutdn_conn_get_bits(struct connectdata *conn,
                                bool *shutdown_filters,
                                bool *connect_only);
void Curl_cshutdn_conn_get_bits(struct connectdata *conn,
                                bool *shutdown_filters,
                                bool *connect_only)
{
  *shutdown_filters = conn->bits.shutdown_filters ? TRUE : FALSE;
  *connect_only = conn->bits.connect_only ? TRUE : FALSE;
}

void Curl_cshutdn_conn_set_shutdown_filters(struct connectdata *conn,
                                            bool val);
void Curl_cshutdn_conn_set_shutdown_filters(struct connectdata *conn,
                                            bool val)
{
  conn->bits.shutdown_filters = val ? TRUE : FALSE;
}

void Curl_cshutdn_run_conn_handler_c(struct Curl_easy *data,
                                     struct connectdata *conn);
void Curl_cshutdn_run_conn_handler_c(struct Curl_easy *data,
                                     struct connectdata *conn)
{
  if(!conn->bits.shutdown_handler) {
    if(conn->scheme && conn->scheme->run->disconnect) {
      if(data->state.internal) {
        data->set.timeout = 2000;
        Curl_pgrsTime(data, TIMER_STARTOP);
      }
      conn->scheme->run->disconnect(data, conn, (bool)conn->bits.aborted);
    }
    conn->bits.shutdown_handler = TRUE;
  }
}

void Curl_cshutdn_data_get_info(struct Curl_easy *data,
                                struct connectdata **pconn,
                                timediff_t *shutdowntimeout,
                                uint32_t *mid,
                                struct Curl_multi **pmulti);
void Curl_cshutdn_data_get_info(struct Curl_easy *data,
                                struct connectdata **pconn,
                                timediff_t *shutdowntimeout,
                                uint32_t *mid,
                                struct Curl_multi **pmulti)
{
  *pconn = data->conn;
  *shutdowntimeout = data->set.shutdowntimeout;
  *mid = data->mid;
  *pmulti = data->multi;
}

void Curl_cshutdn_multi_get_info(struct Curl_multi *multi,
                                 struct Curl_easy **padmin,
                                 bool *has_socket_cb);
void Curl_cshutdn_multi_get_info(struct Curl_multi *multi,
                                 struct Curl_easy **padmin,
                                 bool *has_socket_cb)
{
  *padmin = multi->admin;
  *has_socket_cb = multi->socket_cb ? TRUE : FALSE;
}

void Curl_cshutdn_fdset_apply(curl_socket_t sock,
                              unsigned char action,
                              fd_set *read_fd_set,
                              fd_set *write_fd_set,
                              int *maxfd);
void Curl_cshutdn_fdset_apply(curl_socket_t sock,
                              unsigned char action,
                              fd_set *read_fd_set,
                              fd_set *write_fd_set,
                              int *maxfd)
{
  if(!FDSET_SOCK(sock))
    return;
  if(action & CURL_POLL_IN)
    FD_SET(sock, read_fd_set);
  if(action & CURL_POLL_OUT)
    FD_SET(sock, write_fd_set);
  if((action & (CURL_POLL_OUT | CURL_POLL_IN)) && ((int)sock > *maxfd))
    *maxfd = (int)sock;
}

void Curl_cshutdn_sigpipe_init_c(struct Curl_sigpipe_ctx *ctx);
void Curl_cshutdn_sigpipe_init_c(struct Curl_sigpipe_ctx *ctx)
{
  sigpipe_init(ctx);
}

void Curl_cshutdn_sigpipe_apply_c(struct Curl_easy *data,
                                  struct Curl_sigpipe_ctx *ctx);
void Curl_cshutdn_sigpipe_apply_c(struct Curl_easy *data,
                                  struct Curl_sigpipe_ctx *ctx)
{
  sigpipe_apply(data, ctx);
}

void Curl_cshutdn_sigpipe_restore_c(struct Curl_sigpipe_ctx *ctx);
void Curl_cshutdn_sigpipe_restore_c(struct Curl_sigpipe_ctx *ctx)
{
  sigpipe_restore(ctx);
}
#endif
