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

#include "urldata.h"
#include "transfer.h"
#include "url.h"
#include "cfilters.h"
#include "connect.h"
#include "progress.h"
#include "curl_share.h"
#include "psl.h"
#include "multiif.h"
#include "multi_ev.h"
#include "sendf.h"
#include "curl_trc.h"
#include "http.h"
#include "select.h"
#include "curlx/wait.h"
#include "conncache.h"
#include "multihandle.h"
#include "sigpipe.h"
#include "vtls/vtls.h"
#include "vtls/vtls_scache.h"
#include "http_proxy.h"
#include "http2.h"
#include "socketpair.h"
#include "bufref.h"
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

static void move_pending_to_connect(struct Curl_multi *multi,
                                    struct Curl_easy *data);
static CURLMcode add_next_timeout(const struct curltime *pnow,
                                  struct Curl_multi *multi,
                                  struct Curl_easy *data);
static void multi_timeout(struct Curl_multi *multi,
                          timediff_t *pexire_offset_us,
                          int *timeout_ms);
static void multi_schedule_pending(struct Curl_multi *multi);
static void multi_xfer_bufs_free(struct Curl_multi *multi);
#ifdef DEBUGBUILD
static void multi_xfer_tbl_dump(struct Curl_multi *multi);
#endif
/* Get the # of transfers current in process/pending. */
static uint32_t multi_xfers_running(struct Curl_multi *multi);

/* function pointer called once when entering a state */
typedef void (*mstate_enter_func)(struct Curl_easy *data,
                                  CURLMstate from_state);

static void mstate_enter_connect(struct Curl_easy *data,
                                 CURLMstate from_state)
{
  (void)from_state;
  Curl_init_CONNECT(data);
}

static void mstate_enter_did(struct Curl_easy *data,
                             CURLMstate from_state)
{
  (void)from_state;
  data->req.chunk = FALSE;
  Curl_pgrsTime(data, TIMER_PRETRANSFER);
  if(!CURL_REQ_WANT_SEND(data))
    Curl_pgrsTime(data, TIMER_POSTRANSFER);
}

static void mstate_enter_done(struct Curl_easy *data,
                              CURLMstate from_state)
{
  (void)from_state;
  CURLM_NTFY(data, CURLMNOTIFY_EASY_DONE);
}

static void mstate_enter_completed(struct Curl_easy *data,
                                   CURLMstate from_state)
{
  /* we sometimes directly jump to COMPLETED, trigger things
   * we then missed. */
  if(from_state < MSTATE_DID) {
    Curl_pgrsTime(data, TIMER_PRETRANSFER);
    Curl_pgrsTime(data, TIMER_POSTRANSFER);
    Curl_pgrsTime(data, TIMER_STARTTRANSFER);
  }
  /* multi_done() should have run and detached any connection already */
  DEBUGASSERT(!data->conn);
  Curl_pgrsCompleted(data);
  if(from_state < MSTATE_DONE)
    CURLM_NTFY(data, CURLMNOTIFY_EASY_DONE);
  /* changing to COMPLETED means it is in process and needs to go */
  DEBUGASSERT(Curl_uint32_bset_contains(&data->multi->process, data->mid));
  Curl_uint32_bset_remove(&data->multi->process, data->mid);
  Curl_uint32_bset_remove(&data->multi->pending, data->mid); /* to be sure */

  if(Curl_uint32_bset_empty(&data->multi->process)) {
    /* free the transfer buffer when we have no more active transfers */
    multi_xfer_bufs_free(data->multi);
  }
  /* Important: reset the conn pointer so that we do not point to memory
     that could be freed anytime */
  Curl_detach_connection(data);
  Curl_expire_clear_all(data); /* stop all timers */
}

/* always use this function to change state, to make debugging easier */
static void mstate(struct Curl_easy *data, CURLMstate state
#ifdef DEBUGBUILD
                   , int lineno
#endif
)
{
  CURLMstate oldstate = data->mstate;
  static const mstate_enter_func state_enter[MSTATE_LAST] = {
    NULL,                      /* INIT */
    NULL,                      /* PENDING */
    NULL,                      /* SETUP */
    mstate_enter_connect,      /* CONNECT */
    NULL,                      /* CONNECTING */
    NULL,                      /* PROTOCONNECT */
    NULL,                      /* PROTOCONNECTING */
    NULL,                      /* DO */
    NULL,                      /* DOING */
    NULL,                      /* DOING_MORE */
    mstate_enter_did,          /* DID */
    NULL,                      /* PERFORMING */
    NULL,                      /* RATELIMITING */
    mstate_enter_done,         /* DONE */
    mstate_enter_completed,    /* COMPLETED */
    NULL                       /* MSGSENT */
  };

  if(oldstate == state)
    /* do not bother when the new state is the same as the old state */
    return;

#ifdef DEBUGBUILD
  NOVERBOSE((void)lineno);
  CURL_TRC_M(data, "-> [%s] (line %d)", CURL_MSTATE_NAME(state), lineno);
#else
  CURL_TRC_M(data, "-> [%s]", CURL_MSTATE_NAME(state));
#endif

  /* really switching state */
  data->mstate = state;
  if(state_enter[state])
    state_enter[state](data, oldstate);
}

#ifndef DEBUGBUILD
#define multistate(x, y) mstate(x, y)
#else
#define multistate(x, y) mstate(x, y, __LINE__)
#endif

/* multi->proto_hash destructor. Should never be called as elements
 * MUST be added with their own destructor */
static void ph_freeentry(void *p)
{
  (void)p;
  /* Always FALSE. Cannot use a 0 assert here since compilers
   * are not in agreement if they then want a NORETURN attribute or
   * not. *sigh* */
  DEBUGASSERT(!p);
}

/*
 * multi_addmsg()
 *
 * Called when a transfer is completed. Marks its message as unread.
 */
static void multi_addmsg(struct Curl_multi *multi, struct Curl_easy *data)
{
  if(Curl_uint32_bset_empty(&multi->msgsent))
    CURLM_NTFY(multi->admin, CURLMNOTIFY_INFO_READ);
  Curl_uint32_bset_add(&multi->msgsent, data->mid);
}

static void multi_timeouts_init(struct Curl_easy *data);

struct Curl_multi *Curl_multi_handle(uint32_t xfer_table_size,
                                     size_t ev_hashsize,  /* event hash */
                                     size_t chashsize, /* connection hash */
                                     size_t dnssize,   /* dns hash */
                                     size_t sesssize)  /* TLS session cache */
{
  struct curltime created;
  struct Curl_multi *multi = curlx_calloc(1, sizeof(struct Curl_multi));

  if(!multi)
    return NULL;

  multi->magic = CURLMULTI_MAGIC_NUMBER;

  /* Initialisation order is important here!
   * easy_init() does a lazy check on curl_global_init() which sets
   * up platform specific things we need. For example calling curlx_pnow()
   * before this is not safe. */
  multi->admin = curl_easy_init();
  if(!multi->admin) {
    curlx_free(multi);
    return NULL;
  }
  multi->admin->multi = multi;
  multi->admin->state.internal = TRUE;

  /* Now we can use curlx_* things safely */
  curlx_pnow(&created);
  Curl_timeouts_init(&multi->timeouts, &created);
  multi_timeouts_init(multi->admin);

  Curl_dnscache_init(&multi->dnscache, dnssize);
  Curl_mntfy_init(multi);
  Curl_multi_ev_init(multi, ev_hashsize);
  Curl_uint32_tbl_init(&multi->xfers);
  Curl_uint32_bset_init(&multi->process);
  Curl_uint32_bset_init(&multi->dirty);
  Curl_uint32_bset_init(&multi->pending);
  Curl_uint32_bset_init(&multi->msgsent);
  Curl_hash_init(&multi->proto_hash, 23, CURL_HASH_TYPE_BYTES, ph_freeentry);
  Curl_cshutdn_init(&multi->cshutdn);

  multi->multiplexing = TRUE;
  multi->max_concurrent_streams = 100;
#ifdef ENABLE_WAKEUP
  multi->wakeup_pair[0] = CURL_SOCKET_BAD;
  multi->wakeup_pair[1] = CURL_SOCKET_BAD;
#endif
#ifdef ENABLE_INTERNAL_WAKEUP
  multi->wakeup_internal[0] = CURL_SOCKET_BAD;
  multi->wakeup_internal[1] = CURL_SOCKET_BAD;
#endif

  if(Curl_uint32_bset_resize(&multi->process, xfer_table_size) ||
     Curl_uint32_bset_resize(&multi->pending, xfer_table_size) ||
     Curl_uint32_bset_resize(&multi->dirty, xfer_table_size) ||
     Curl_uint32_bset_resize(&multi->msgsent, xfer_table_size) ||
     Curl_uint32_tbl_resize(&multi->xfers, xfer_table_size))
    goto error;

#ifdef DEBUGBUILD
  {
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
  }
#endif
  Curl_uint32_tbl_add(&multi->xfers, multi->admin, &multi->admin->mid);
  Curl_uint32_bset_add(&multi->process, multi->admin->mid);

  Curl_cpool_init(&multi->cpool, NULL, chashsize);

#ifdef USE_SSL
  if(Curl_ssl_scache_create(sesssize, 2, &multi->ssl_scache))
    goto error;
#else
  (void)sesssize;
#endif

#ifdef USE_WINSOCK
  multi->wsa_event = WSACreateEvent();
  if(multi->wsa_event == WSA_INVALID_EVENT)
    goto error;
#endif
#ifdef ENABLE_WAKEUP
  /* When enabled, rely on this to work. We ignore this in previous
   * versions, but that seems an unnecessary complication. */
  if(Curl_wakeup_init(multi->wakeup_pair, TRUE) < 0)
    goto error;
#endif
#ifdef ENABLE_INTERNAL_WAKEUP
  if(Curl_wakeup_init(multi->wakeup_internal, TRUE) < 0)
    goto error;
#endif

  if(Curl_probeipv6(multi))
    goto error;

#ifdef USE_RESOLV_THREADED
  if(xfer_table_size < CURL_XFER_TABLE_SIZE) { /* easy multi */
    if(Curl_async_thrdd_multi_init(multi, 0, 2, 10))
      goto error;
  }
  else { /* real multi handle */
    if(Curl_async_thrdd_multi_init(multi, 0, 20, 2000))
      goto error;
  }
#endif

  return multi;

error:

#ifdef USE_RESOLV_THREADED
  Curl_async_thrdd_multi_destroy(multi, TRUE);
#endif
  Curl_multi_ev_cleanup(multi);
  Curl_hash_destroy(&multi->proto_hash);
  Curl_dnscache_destroy(&multi->dnscache);
  Curl_cpool_destroy(&multi->cpool, multi->admin);
  Curl_cshutdn_destroy(&multi->cshutdn, multi->admin);
#ifdef USE_SSL
  Curl_ssl_scache_destroy(multi->ssl_scache);
#endif
  if(multi->admin) {
    Curl_multi_ev_xfer_done(multi, multi->admin);
    multi->admin->multi = NULL;
    Curl_close(&multi->admin);
  }
  Curl_mntfy_cleanup(multi);

  Curl_uint32_bset_destroy(&multi->process);
  Curl_uint32_bset_destroy(&multi->dirty);
  Curl_uint32_bset_destroy(&multi->pending);
  Curl_uint32_bset_destroy(&multi->msgsent);
  Curl_uint32_tbl_destroy(&multi->xfers);
#ifdef ENABLE_WAKEUP
  Curl_wakeup_destroy(multi->wakeup_pair);
#endif
#ifdef ENABLE_INTERNAL_WAKEUP
  Curl_wakeup_destroy(multi->wakeup_internal);
#endif

  curlx_free(multi);
  return NULL;
}

CURLM *curl_multi_init(void)
{
  return Curl_multi_handle(CURL_XFER_TABLE_SIZE,
                           CURL_SOCKET_HASH_TABLE_SIZE,
                           CURL_CONNECTION_HASH_SIZE,
                           CURL_DNS_HASH_SIZE,
                           CURL_TLS_SESSION_SIZE);
}

#if defined(DEBUGBUILD) && defined(CURLVERBOSE)
static void multi_warn_debug(struct Curl_multi *multi, struct Curl_easy *data)
{
  if(!multi->warned) {
    infof(data, "!!! WARNING !!!");
    infof(data, "This is a debug build of libcurl, "
                "do not use in production.");
    multi->warned = TRUE;
  }
}
#else
#define multi_warn_debug(x, y) Curl_nop_stmt
#endif

bool Curl_is_connecting(struct Curl_easy *data)
{
  return data->mstate < MSTATE_DO;
}

static CURLMcode multi_assess_wakeup(struct Curl_multi *multi)
{
#ifdef ENABLE_INTERNAL_WAKEUP
  if(multi->socket_cb)
    return Curl_multi_ev_assess_xfer(multi, multi->admin);
#else
  (void)multi;
#endif
  return CURLM_OK;
}

static CURLMcode multi_xfers_add(struct Curl_multi *multi,
                                 struct Curl_easy *data)
{
  uint32_t capacity = Curl_uint32_tbl_capacity(&multi->xfers);
  uint32_t new_size = 0;
  /* Prepare to make this into a CURLMOPT_MAX_TRANSFERS, because some
   * applications may want to prevent a run-away of their memory use. */
  /* UINT_MAX is our "invalid" id, do not let the table grow up to that. */
  const uint32_t max_capacity = UINT_MAX - 1;

  if(capacity < max_capacity) {
    /* We want `multi->xfers` to have "sufficient" free rows, so that we do
     * not have to reuse the `mid` from a removed easy right away.
     * Check if an 8th of the capacity is still free */
    uint32_t used = Curl_uint32_tbl_count(&multi->xfers);
    uint32_t unused = capacity - used;
    uint32_t min_unused = CURLMAX(capacity >> 3, 4);
    if(unused < min_unused) {
      /* Grow by 50% of current capacity, in range of [128, 2048],
       * which means the table grows max by 16kb on 64-bit arch. */
      uint32_t growth = CURLMIN(CURLMAX(capacity >> 1, 128), 2048);
      /* Make sure the uint arithmetic here works on the corner
       * cases where we are close to max_capacity or UINT_MAX */
      if((max_capacity - growth) <= capacity)
        new_size = max_capacity;
      else
        new_size = capacity + growth;
    }
  }

  if(new_size > capacity) {
    /* Grow the bitsets first. Should one fail, we do not need
     * to downsize the already resized ones. The sets continue
     * to work properly when larger than the table, but not
     * the other way around. */
    CURL_TRC_M(data, "increasing xfer table size to %u", new_size);
    if(Curl_uint32_bset_resize(&multi->process, new_size) ||
       Curl_uint32_bset_resize(&multi->dirty, new_size) ||
       Curl_uint32_bset_resize(&multi->pending, new_size) ||
       Curl_uint32_bset_resize(&multi->msgsent, new_size) ||
       Curl_uint32_tbl_resize(&multi->xfers, new_size))
      return CURLM_OUT_OF_MEMORY;
  }

  /* Insert the easy into the table now */
  if(!Curl_uint32_tbl_add(&multi->xfers, data, &data->mid)) {
    /* MUST only happen when table is full */
    DEBUGASSERT(Curl_uint32_tbl_capacity(&multi->xfers) <=
                Curl_uint32_tbl_count(&multi->xfers));
    return CURLM_OUT_OF_MEMORY;
  }
  return CURLM_OK;
}

CURLMcode Curl_multi_add_handle(struct Curl_multi *multi,
                                struct Curl_easy *data)
{
  CURLMcode mresult;

  /* Prevent users from adding same easy handle more than once and prevent
     adding to more than one multi stack */
  if(data->multi)
    return CURLM_ADDED_ALREADY;

  if(multi->dead) {
    /* a "dead" handle cannot get added transfers while any existing easy
       handles are still alive - but if there are none alive anymore, it is
       fine to start over and unmark the "deadness" of this handle.
       This means only the admin handle MUST be present. */
    if((Curl_uint32_tbl_count(&multi->xfers) != 1) ||
       !Curl_uint32_tbl_contains(&multi->xfers, 0))
      return CURLM_ABORTED_BY_CALLBACK;
    multi->dead = FALSE;
    Curl_uint32_bset_clear(&multi->process);
    Curl_uint32_bset_clear(&multi->dirty);
    Curl_uint32_bset_clear(&multi->pending);
    Curl_uint32_bset_clear(&multi->msgsent);
  }

  if(data->multi_easy) {
    /* if this easy handle was previously used for curl_easy_perform(), there
       is a private multi handle here that we can kill */
    curl_multi_cleanup(data->multi_easy);
    data->multi_easy = NULL;
  }

  /* Insert the easy into the multi->xfers table, assigning it a `mid`. */
  if(multi_xfers_add(multi, data))
    return CURLM_OUT_OF_MEMORY;

  /* Initialize timeouts for this handle */
  multi_timeouts_init(data);

  /*
   * No failure allowed in this function beyond this point. No modification
   * of easy nor multi handle allowed before this except for potential
   * multi's connection pool growing which will not be undone in this
   * function no matter what.
   */
  if(data->set.errorbuffer)
    data->set.errorbuffer[0] = 0;

  data->state.os_errno = 0;

  /* make the Curl_easy refer back to this multi handle - before
     Curl_expire() is called. */
  data->multi = multi;

  /* set the easy handle */
  multistate(data, MSTATE_INIT);
  /* not yet passed INIT state */
  data->state.really_alive = FALSE;

#ifdef USE_LIBPSL
  /* Do the same for PSL. */
  if(data->share && (data->share->specifier & (1 << CURL_LOCK_DATA_PSL)))
    data->psl = &data->share->psl;
  else
    data->psl = &multi->psl;
#endif

  /* add the easy handle to the process set */
  Curl_uint32_bset_add(&multi->process, data->mid);
  ++multi->xfers_alive;
  ++multi->xfers_total_ever;

  Curl_cpool_xfer_init(data);
  multi_warn_debug(multi, data);

  /* Make sure the new handle will run */
  Curl_multi_mark_dirty(data);

  /* Necessary in event based processing, where dirty handles trigger
   * a timeout callback invocation. */
  mresult = Curl_update_timer(multi);
  if(mresult) {
    data->multi = NULL; /* not anymore */
    Curl_uint32_tbl_remove(&multi->xfers, data->mid);
    data->mid = UINT32_MAX;
    return mresult;
  }

  /* The admin handle only ever has default timeouts set. To improve the
     state somewhat we clone the timeouts from each added handle so that the
     admin handle always has the same timeouts as the most recently added
     easy handle. */
  multi->admin->set.timeout = data->set.timeout;
  multi->admin->set.server_response_timeout =
    data->set.server_response_timeout;
  multi->admin->set.no_signal = data->set.no_signal;

  CURL_TRC_M(data, "added to multi, mid=%u, running=%u, total=%u",
             data->mid, multi_xfers_running(multi),
             Curl_uint32_tbl_count(&multi->xfers));
  return CURLM_OK;
}

CURLMcode curl_multi_add_handle(CURLM *m, CURL *curl)
{
  struct Curl_mapi_guard guard;
  CURLMcode mresult;

  if(CURL_MAPI_ENTER(&guard, m, multi_add_handle, &mresult)) {
    struct Curl_easy *data = curl;
    /* Verify that we got a somewhat good easy handle too */
    if(!GOOD_EASY_HANDLE(data) || data->state.internal)
      mresult = CURLM_BAD_EASY_HANDLE;
    else
      mresult = Curl_multi_add_handle(m, data);
  }
  CURL_MAPI_LEAVE(&guard);
  return mresult;
}

struct multi_done_ctx {
  BIT(premature);
};

static bool multi_conn_should_close(struct connectdata *conn,
                                    struct Curl_easy *data,
                                    bool premature)
{
  /* if conn->bits.close is TRUE, it means that the connection should be
     closed in spite of everything else. */
  if(conn->bits.close)
    return TRUE;

  /* if data->set.reuse_forbid is TRUE, it means the libcurl client has
     forced us to close this connection. This is ignored for requests taking
     place in a NTLM/NEGOTIATE authentication handshake. */
  if(data->set.reuse_forbid
#ifdef USE_NTLM
     && !(conn->http_ntlm_state == NTLMSTATE_TYPE2 ||
          conn->proxy_ntlm_state == NTLMSTATE_TYPE2)
#endif
#ifdef USE_SPNEGO
     && !(conn->http_negotiate_state == CURL_NEGO_AUTH_RECV ||
          conn->proxy_negotiate_state == CURL_NEGO_AUTH_RECV)
#endif
    )
    return TRUE;

  /* Unless this connection is for a "connect-only" transfer, it
   * needs to be closed if the protocol handler does not support reuse. */
  if(!data->set.connect_only && conn->scheme &&
     !(conn->scheme->flags & PROTOPT_CONN_REUSE))
    return TRUE;

  /* if premature is TRUE, it means this connection was said to be DONE before
     the entire request operation is complete and thus we cannot know in what
     state it is for reusing, so we are forced to close it. In a perfect world
     we can add code that keep track of if we really must close it here or not,
     but currently we have no such detail knowledge. */
  if(premature && !Curl_conn_is_multiplex(conn, FIRSTSOCKET))
    return TRUE;

  return FALSE;
}

static cpool_do_result multi_done_locked(struct Curl_easy *data,
                                         struct connectdata *conn,
                                         void *userdata,
                                         const struct curltime *pnow)
{
  struct multi_done_ctx *mdctx = userdata;

  (void)pnow;
  CURL_TRC_M(data, "multi_done_locked, in use=%u", conn->attached_xfers);
  if(CONN_INUSE(conn)) {
    /* Stop if still used. */
    CURL_TRC_M(data, "Connection still in use %u, no more multi_done now!",
               conn->attached_xfers);
    return CPOOL_DO_KEEP;
  }

  if(multi_conn_should_close(conn, data, (bool)mdctx->premature)) {
    CURL_TRC_M(data, "multi_done, terminating conn #%" FMT_OFF_T " to %s:%u, "
               "forbid=%d, close=%d, premature=%d, conn_multiplex=%d",
               conn->connection_id, conn->origin->user_hostname,
               conn->origin->port,
               data->set.reuse_forbid, conn->bits.close, mdctx->premature,
               Curl_conn_is_multiplex(conn, FIRSTSOCKET));
    connclose(conn);
    return mdctx->premature ? CPOOL_DO_TERMINATE : CPOOL_DO_CLOSE;
  }
  else if(!Curl_conn_get_max_concurrent(data, conn, FIRSTSOCKET)) {
    CURL_TRC_M(data, "multi_done, conn #%" FMT_OFF_T " to %s:%u was shutdown"
               " by server, not reusing", conn->connection_id,
               conn->origin->user_hostname, conn->origin->port);
    connclose(conn);
    return mdctx->premature ? CPOOL_DO_TERMINATE : CPOOL_DO_CLOSE;
  }
  else {
    return CPOOL_DO_IDLE;
  }
}

static CURLcode multi_done(struct Curl_easy *data,
                           CURLcode status,  /* an error if this is called
                                                after an error was detected */
                           bool premature)
{
  CURLcode result;
  struct connectdata *conn = data->conn;
  const struct curltime *pnow = Curl_pgrs_now(data);

  CURL_TRC_M(data, "multi_done: status: %d prem: %d done: %d",
             (int)status, (int)premature, data->state.done);

  if(data->state.done) {
    /* Stop if multi_done() has already been called */
    return CURLE_OK;
  }
  data->state.done = TRUE; /* called now! */

  /* Shut down any ongoing async resolver operation. */
  Curl_resolv_shutdown_all(data);

  /* Cleanup possible redirect junk */
  curlx_safefree(data->req.newurl);
  curlx_safefree(data->req.location);

  switch(status) {
  case CURLE_ABORTED_BY_CALLBACK:
  case CURLE_READ_ERROR:
  case CURLE_WRITE_ERROR:
    /* When we are aborted due to a callback return code it has to be counted
       as premature as there is trouble ahead if we do not. We have many
       callbacks and protocols work differently, we could potentially do this
       more fine-grained in the future. */
    premature = TRUE;
    FALLTHROUGH();
  default:
    break;
  }

  /* this calls the protocol-specific function pointer previously set */
  if(conn && conn->scheme->run->done && (data->mstate >= MSTATE_PROTOCONNECT))
    result = conn->scheme->run->done(data, status, premature);
  else
    result = status;

  if(data->mstate > MSTATE_CONNECTING &&
     (result != CURLE_ABORTED_BY_CALLBACK)) {
    /* avoid this if
     * - the transfer has not connected
     * - we already aborted by callback to avoid this calling another callback
     */
    int rc = Curl_pgrsDone(data, pnow);
    if(!result && rc)
      result = CURLE_ABORTED_BY_CALLBACK;
  }

  /* Make sure that transfer client writes are really done now. */
  result = Curl_1st_fatal(result, Curl_xfer_write_done(data, premature));

  if(!result)
    result = Curl_req_done(&data->req, data, premature);

  if(conn) {
    /* Detach connection and decide what to do with it. */
    struct multi_done_ctx mdctx;

    /* Inform connection filters that this transfer is done and they
     * need to give up any references to `data`. */
    Curl_conn_ev_data_done(data, premature);
    Curl_detach_connection(data);
    Curl_dnscache_prune(data, pnow);

    memset(&mdctx, 0, sizeof(mdctx));
    mdctx.premature = premature;
    Curl_cpool_return(data, conn, multi_done_locked, &mdctx, pnow);

    if(data->multi)
      multi_schedule_pending(data->multi);
  }

  /* flush the netrc cache */
  Curl_netrc_cleanup(&data->state.netrc);
  return result;
}

CURLMcode Curl_multi_remove_handle(struct Curl_multi *multi,
                                   struct Curl_easy *data)
{
  CURLMcode mresult;
  bool premature;
  uint32_t mid;

  /* Prevent users from trying to remove same easy handle more than once */
  if(!data->multi)
    return CURLM_OK; /* it is already removed so let's say it is fine! */

  /* Prevent users from trying to remove an easy handle from the wrong multi */
  if(data->multi != multi)
    return CURLM_BAD_EASY_HANDLE;

  if(data->mid == UINT32_MAX) {
    DEBUGASSERT(0);
    return CURLM_INTERNAL_ERROR;
  }
  if(Curl_uint32_tbl_get(&multi->xfers, data->mid) != data) {
    DEBUGASSERT(0);
    return CURLM_INTERNAL_ERROR;
  }

  premature = (data->mstate < MSTATE_COMPLETED);

  if(data->conn) {
    /* If the 'state' is not INIT or COMPLETED, we might need to do something
       nice to put the easy_handle in a good known state when this returns. */
    if(premature && (data->mstate > MSTATE_DO))
      streamclose(data->conn);

    /* multi_done() clears the association between the easy handle and the
       connection.
       Note that this ignores the return code because there is
       nothing really useful to do with it anyway! */
    (void)multi_done(data, data->result, premature);
  }

  /* The timer must be shut down before data->multi is set to NULL, else
     data's splaynode would remain in the splay tree after curl_easy_cleanup is
     called. Do it after multi_done() in case that sets another time! */
  Curl_expire_clear_all(data);

  /* In MSGSENT, it was deducted from `multi->xfers_alive` already. */
  if(data->mstate != MSTATE_MSGSENT)
    --multi->xfers_alive;

  if(data->state.really_alive) {
    data->state.really_alive = FALSE;
    --multi->xfers_really_alive;
    if(!multi->xfers_really_alive)
      (void)multi_assess_wakeup(multi);
  }

  Curl_wildcard_dtor(&data->wildcard);

  data->mstate = MSTATE_COMPLETED;

  /* Remove the association between the connection and the handle */
  Curl_detach_connection(data);

  /* Tell event handling that this transfer is definitely going away */
  Curl_multi_ev_xfer_done(multi, data);

  if(data->set.connect_only) {
    if(data->multi_easy) {
      if(data->state.last_conn_id != -1) {
        /* Mark any connect-only connection for closure */
        struct connectdata *conn;
        (void)Curl_getconnectinfo(data, &conn);
        if(conn && conn->bits.connect_only)
          connclose(conn);
      }
    }
    else {
      /* This removes a handle that was part the multi interface that used
         CONNECT_ONLY, that connection is now left alive but since this handle
         has bits.close set nothing can use that connection anymore and it is
         forbidden from reuse. This easy handle cannot find the connection
         anymore once removed from the multi handle

         Better close the connection here, at once. */
      struct connectdata *conn;
      (void)Curl_getconnectinfo(data, &conn);
      if(conn)
        Curl_conn_close(data, conn, TRUE);
    }
  }

#ifdef USE_LIBPSL
  /* Remove the PSL association. */
  if(data->psl == &multi->psl)
    data->psl = NULL;
#endif

  /* clear the association to this multi handle */
  mid = data->mid;
  DEBUGASSERT(Curl_uint32_tbl_contains(&multi->xfers, mid));
  Curl_uint32_tbl_remove(&multi->xfers, mid);
  Curl_uint32_bset_remove(&multi->process, mid);
  Curl_uint32_bset_remove(&multi->dirty, mid);
  Curl_uint32_bset_remove(&multi->pending, mid);
  Curl_uint32_bset_remove(&multi->msgsent, mid);
  data->multi = NULL;
  data->mid = UINT32_MAX;
  data->master_mid = UINT32_MAX;

  /* A pending transfer *might* be able to run now. */
  multi_schedule_pending(multi);
  mresult = Curl_update_timer(multi);
  if(mresult)
    return mresult;

  mresult = multi_assess_wakeup(multi);
  if(mresult) {
    failf(data, "error enabling wakeup listening: %d", mresult);
    return mresult;
  }

  CURL_TRC_M(data, "removed from multi, mid=%u, running=%u, total=%u",
             mid, multi_xfers_running(multi),
             Curl_uint32_tbl_count(&multi->xfers));
  return CURLM_OK;
}

CURLMcode curl_multi_remove_handle(CURLM *m, CURL *curl)
{
  struct Curl_mapi_guard guard;
  CURLMcode mresult;

  if(CURL_MAPI_ENTER(&guard, m, multi_remove_handle, &mresult)) {
    struct Curl_easy *data = curl;
    if(!GOOD_EASY_HANDLE(data) || data->state.internal)
      mresult = CURLM_BAD_EASY_HANDLE;
    else
      mresult = Curl_multi_remove_handle(m, data);
  }
  CURL_MAPI_LEAVE(&guard);
  return mresult;
}

/* Return TRUE if the application asked for multiplexing */
bool Curl_multiplex_wanted(const struct Curl_multi *multi)
{
  return multi && multi->multiplexing;
}

/*
 * Curl_detach_connection() removes the given transfer from the connection.
 *
 * This is the only function that should clear data->conn. This will
 * occasionally be called with the data->conn pointer already cleared.
 */
void Curl_detach_connection(struct Curl_easy *data)
{
  struct connectdata *conn = data->conn;
  if(conn) {
    /* this should never happen, prevent underflow */
    DEBUGASSERT(conn->attached_xfers);
    if(conn->attached_xfers) {
      conn->attached_xfers--;
      if(!conn->attached_xfers)
        conn->attached_multi = NULL;
    }
  }
  data->conn = NULL;
}

/*
 * Curl_attach_connection() attaches this transfer to this connection.
 *
 * This is the only function that should assign data->conn.
 * `matched == TRUE` means the transfer's properties match this
 * connection and it is not a temporary attach for maintenance.
 */
void Curl_attach_connection(struct Curl_easy *data,
                            struct connectdata *conn,
                            bool matched)
{
  DEBUGASSERT(data);
  DEBUGASSERT(!data->conn);
  DEBUGASSERT(conn);
  DEBUGASSERT(conn->attached_xfers < UINT32_MAX);
  data->conn = conn;
  if(matched) {
    data->state.last_conn_id = conn->connection_id;
    data->state.last_cpid = conn->cpid;
  }
  else
    DEBUGASSERT(!data->mid); /* admin handle */
  conn->attached_xfers++;
  /* all attached transfers must be from the same multi */
  if(!conn->attached_multi)
    conn->attached_multi = data->multi;
  DEBUGASSERT(conn->attached_multi == data->multi);

  if(conn->scheme && conn->scheme->run->attach)
    conn->scheme->run->attach(data, conn);
}

/* adjust pollset for rate limits/pauses */
static CURLcode multi_adjust_pollset(struct Curl_easy *data,
                                     struct easy_pollset *ps)
{
  CURLcode result = CURLE_OK;

  if(ps->n) {
    bool send_blocked, recv_blocked;

    recv_blocked = (Curl_rlimit_avail(&data->progress.dl.rlimit, NULL) <= 0);
    send_blocked = (Curl_rlimit_avail(&data->progress.ul.rlimit, NULL) <= 0);
    if(send_blocked || recv_blocked) {
      int i;
      for(i = 0; i <= SECONDARYSOCKET; ++i) {
        curl_socket_t sock = data->conn->sock[i];
        if(sock == CURL_SOCKET_BAD)
          continue;
        if(recv_blocked && Curl_pollset_want_recv(data, ps, sock)) {
          result = Curl_pollset_remove_in(data, ps, sock);
          if(result)
            break;
        }
        if(send_blocked && Curl_pollset_want_send(data, ps, sock)) {
          result = Curl_pollset_remove_out(data, ps, sock);
          if(result)
            break;
        }
      }
    }

    /* Not blocked and wanting to receive. If there is data pending
     * in the connection filters, make transfer run again. */
    if(!recv_blocked &&
       ((Curl_pollset_want_recv(data, ps, data->conn->sock[FIRSTSOCKET]) &&
         Curl_conn_data_pending(data, FIRSTSOCKET)) ||
        (Curl_pollset_want_recv(data, ps, data->conn->sock[SECONDARYSOCKET]) &&
         Curl_conn_data_pending(data, SECONDARYSOCKET)))) {
      CURL_TRC_M(data, "pollset[] has POLLIN, but there is still "
                 "buffered input -> mark as dirty");
      Curl_multi_mark_dirty(data);
    }
  }
  return result;
}

static CURLcode mstate_connecting_pollset(struct Curl_easy *data,
                                          struct easy_pollset *ps)
{
  struct connectdata *conn = data->conn;
  curl_socket_t sockfd;
  CURLcode result = CURLE_OK;

  if(Curl_xfer_recv_is_paused(data))
    return CURLE_OK;
  /* If a socket is set, receiving is default. If the socket
   * has not been determined yet (eyeballing), always ask the
   * connection filters for what to monitor. */
  sockfd = Curl_conn_get_first_socket(data);
  if(sockfd != CURL_SOCKET_BAD) {
    result = Curl_pollset_change(data, ps, sockfd, CURL_POLL_IN, 0);
    if(!result)
      result = multi_adjust_pollset(data, ps);
  }
  if(!result)
    result = Curl_conn_adjust_pollset(data, conn, ps);
  return result;
}

static CURLcode mstate_protocol_pollset(struct Curl_easy *data,
                                        struct easy_pollset *ps)
{
  struct connectdata *conn = data->conn;
  CURLcode result = CURLE_OK;

  if(conn->scheme->run->proto_pollset)
    result = conn->scheme->run->proto_pollset(data, ps);
  else {
    curl_socket_t sockfd = conn->sock[FIRSTSOCKET];
    if(sockfd != CURL_SOCKET_BAD) {
      /* Default is to wait to something from the server */
      result = Curl_pollset_change(data, ps, sockfd, CURL_POLL_IN, 0);
    }
  }
  if(!result)
    result = multi_adjust_pollset(data, ps);
  if(!result)
    result = Curl_conn_adjust_pollset(data, conn, ps);
  return result;
}

static CURLcode mstate_do_pollset(struct Curl_easy *data,
                                  struct easy_pollset *ps)
{
  struct connectdata *conn = data->conn;
  CURLcode result = CURLE_OK;

  if(conn->scheme->run->doing_pollset)
    result = conn->scheme->run->doing_pollset(data, ps);
  else if(CONN_SOCK_IDX_VALID(conn->send_idx)) {
    /* Default is that we want to send something to the server */
    result = Curl_pollset_add_out(data, ps, conn->sock[conn->send_idx]);
  }
  if(!result)
    result = multi_adjust_pollset(data, ps);
  if(!result)
    result = Curl_conn_adjust_pollset(data, conn, ps);
  return result;
}

static CURLcode mstate_domore_pollset(struct Curl_easy *data,
                                      struct easy_pollset *ps)
{
  struct connectdata *conn = data->conn;
  CURLcode result = CURLE_OK;

  if(conn->scheme->run->domore_pollset)
    result = conn->scheme->run->domore_pollset(data, ps);
  else if(CONN_SOCK_IDX_VALID(conn->send_idx)) {
    /* Default is that we want to send something to the server */
    result = Curl_pollset_add_out(data, ps, conn->sock[conn->send_idx]);
  }
  if(!result)
    result = multi_adjust_pollset(data, ps);
  if(!result)
    result = Curl_conn_adjust_pollset(data, conn, ps);
  return result;
}

static CURLcode mstate_perform_pollset(struct Curl_easy *data,
                                       struct easy_pollset *ps)
{
  struct connectdata *conn = data->conn;
  CURLcode result = CURLE_OK;

  if(conn->scheme->run->perform_pollset)
    result = conn->scheme->run->perform_pollset(data, ps);
  else {
    /* Default is to obey the request flags for send/recv */
    if(Curl_req_want_recv(data) && CONN_SOCK_IDX_VALID(conn->recv_idx)) {
      result = Curl_pollset_add_in(data, ps, conn->sock[conn->recv_idx]);
    }
    if(!result && Curl_req_want_send(data) &&
       CONN_SOCK_IDX_VALID(conn->send_idx)) {
      result = Curl_pollset_add_out(data, ps, conn->sock[conn->send_idx]);
    }
  }
  if(!result)
    result = multi_adjust_pollset(data, ps);
  if(!result)
    result = Curl_conn_adjust_pollset(data, conn, ps);
  return result;
}

#ifdef CURLVERBOSE
static size_t multi_timeouts_count(struct expire_timers *timeouts)
{
  size_t n = 0;
  uint8_t eid = timeouts->first;
  for(; eid < EXPIRE_LAST; eid = timeouts->next[eid])
    ++n;
  return n;
}
#endif

/* Initializes `poll_set` with the current socket poll actions needed
 * for transfer `data`. */
CURLMcode Curl_multi_pollset(struct Curl_easy *data,
                             struct easy_pollset *ps)
{
  CURLcode result = CURLE_OK;

  Curl_pollset_reset(ps);
#ifdef ENABLE_INTERNAL_WAKEUP
  /* The admin handle always listens on the wakeup socket when there
   * are transfers alive. */
  if(data->multi && (data == data->multi->admin) &&
     data->multi->xfers_really_alive) {
    CURL_TRC_M(data, "adding wakeup, %u xfers really alive",
               data->multi->xfers_really_alive);
    result = Curl_pollset_add_in(data, ps, data->multi->wakeup_internal[0]);
  }
#endif
  /* If the transfer has no connection, this is fine. Happens when
     called via curl_multi_remove_handle() => Curl_multi_ev_assess() =>
     Curl_multi_pollset(). */
  if(!result && data->conn) {
    switch(data->mstate) {
    case MSTATE_INIT:
    case MSTATE_PENDING:
    case MSTATE_SETUP:
    case MSTATE_CONNECT:
      /* nothing to poll for yet */
      break;

    case MSTATE_CONNECTING:
      result = mstate_connecting_pollset(data, ps);
      break;

    case MSTATE_PROTOCONNECT:
    case MSTATE_PROTOCONNECTING:
      result = mstate_protocol_pollset(data, ps);
      break;

    case MSTATE_DO:
    case MSTATE_DOING:
      result = mstate_do_pollset(data, ps);
      break;

    case MSTATE_DOING_MORE:
      result = mstate_domore_pollset(data, ps);
      break;

    case MSTATE_DID: /* same as PERFORMING in regard to polling */
    case MSTATE_PERFORMING:
      result = mstate_perform_pollset(data, ps);
      break;

    case MSTATE_RATELIMITING:
      /* we need to let time pass, ignore socket(s) */
      break;

    case MSTATE_DONE:
    case MSTATE_COMPLETED:
    case MSTATE_MSGSENT:
      /* nothing more to poll for */
      break;

    default:
      failf(data, "multi_getsock: unexpected multi state %d",
            (int)data->mstate);
      DEBUGASSERT(0);
      break;
    }
  }

  if(result) {
    if(result == CURLE_OUT_OF_MEMORY)
      return CURLM_OUT_OF_MEMORY;
    failf(data, "error determining pollset: %d", (int)result);
    return CURLM_INTERNAL_ERROR;
  }

#ifdef CURLVERBOSE
  if(CURL_TRC_M_is_verbose(data)) {
    size_t timeout_count = multi_timeouts_count(&data->state.timeouts);
    switch(ps->n) {
    case 0:
      CURL_TRC_M(data, "pollset[], timeouts=%zu, paused %d/%d (r/w)",
                 timeout_count,
                 Curl_xfer_send_is_paused(data),
                 Curl_xfer_recv_is_paused(data));
      break;
    case 1:
      CURL_TRC_M(data, "pollset[fd=%" FMT_SOCKET_T " %s%s], timeouts=%zu",
                 ps->sockets[0],
                 (ps->actions[0] & CURL_POLL_IN) ? "IN" : "",
                 (ps->actions[0] & CURL_POLL_OUT) ? "OUT" : "",
                 timeout_count);
      break;
    case 2:
      CURL_TRC_M(data, "pollset[fd=%" FMT_SOCKET_T " %s%s, "
                 "fd=%" FMT_SOCKET_T " %s%s], timeouts=%zu",
                 ps->sockets[0],
                 (ps->actions[0] & CURL_POLL_IN) ? "IN" : "",
                 (ps->actions[0] & CURL_POLL_OUT) ? "OUT" : "",
                 ps->sockets[1],
                 (ps->actions[1] & CURL_POLL_IN) ? "IN" : "",
                 (ps->actions[1] & CURL_POLL_OUT) ? "OUT" : "",
                 timeout_count);
      break;
    default:
      CURL_TRC_M(data, "pollset[fds=%u], timeouts=%zu", ps->n, timeout_count);
      break;
    }
    CURL_TRC_EASY_TIMERS(data);
  }
#endif

  return CURLM_OK;
}

CURLMcode curl_multi_fdset(CURLM *m,
                           fd_set *read_fd_set, fd_set *write_fd_set,
                           fd_set *exc_fd_set, int *max_fd)
{
  struct Curl_mapi_guard guard;
  CURLMcode mresult;

  if(CURL_MAPI_ENTER(&guard, m, multi_fdset, &mresult)) {
    /* Scan through all the easy handles to get the file descriptors set.
       Some easy handles may not have connected to the remote host yet,
       and then we must make sure that is done. */
    struct Curl_multi *multi = m;
    struct easy_pollset ps;
    int this_max_fd = -1;
    unsigned int i;
    uint32_t mid;
    (void)exc_fd_set;

    Curl_pollset_init(&ps);
    if(Curl_uint32_bset_first(&multi->process, &mid)) {
      do {
        struct Curl_easy *data = Curl_multi_get_easy(multi, mid);

        if(!data) {
          DEBUGASSERT(0);
          continue;
        }

        Curl_multi_pollset(data, &ps);
        for(i = 0; i < ps.n; i++) {
          if(!FDSET_SOCK(ps.sockets[i]))
            /* pretend it does not exist */
            continue;
          if(ps.actions[i] & CURL_POLL_IN)
            FD_SET(ps.sockets[i], read_fd_set);
          if(ps.actions[i] & CURL_POLL_OUT)
            FD_SET(ps.sockets[i], write_fd_set);
          if((int)ps.sockets[i] > this_max_fd)
            this_max_fd = (int)ps.sockets[i];
        }
      } while(Curl_uint32_bset_next(&multi->process, mid, &mid));
    }

    Curl_cshutdn_setfds(&multi->cshutdn, multi->admin,
                        read_fd_set, write_fd_set, &this_max_fd);

    *max_fd = this_max_fd;
    Curl_pollset_cleanup(&ps);

    mresult = CURLM_OK;
  }
  CURL_MAPI_LEAVE(&guard);
  return mresult;
}

CURLMcode curl_multi_waitfds(CURLM *m,
                             struct curl_waitfd *ufds,
                             unsigned int size,
                             unsigned int *fd_count)
{
  struct Curl_mapi_guard guard;
  CURLMcode mresult;

  if(CURL_MAPI_ENTER(&guard, m, multi_waitfds, &mresult)) {
    struct Curl_waitfds cwfds;
    struct Curl_multi *multi = m;
    struct easy_pollset ps;
    unsigned int need = 0;
    uint32_t mid;

    if(!ufds && (size || !fd_count)) {
      mresult = CURLM_BAD_FUNCTION_ARGUMENT;
      goto out;
    }

    Curl_pollset_init(&ps);
    Curl_waitfds_init(&cwfds, ufds, size);
    mresult = CURLM_OK;
    if(Curl_uint32_bset_first(&multi->process, &mid)) {
      do {
        struct Curl_easy *data = Curl_multi_get_easy(multi, mid);
        if(!data) {
          DEBUGASSERT(0);
          Curl_uint32_bset_remove(&multi->process, mid);
          Curl_uint32_bset_remove(&multi->dirty, mid);
          continue;
        }
        Curl_multi_pollset(data, &ps);
        need += Curl_waitfds_add_ps(&cwfds, &ps);
      } while(Curl_uint32_bset_next(&multi->process, mid, &mid));
    }

    need += Curl_cshutdn_add_waitfds(&multi->cshutdn, multi->admin, &cwfds);

    if(need != cwfds.n && ufds)
      mresult = CURLM_OUT_OF_MEMORY;

    if(fd_count)
      *fd_count = need;
    Curl_pollset_cleanup(&ps);
  }
out:
  CURL_MAPI_LEAVE(&guard);
  return mresult;
}

#ifdef USE_WINSOCK
/* Reset FD_WRITE for TCP sockets. Nothing is actually sent. UDP sockets cannot
 * be reset this way because an empty datagram would be sent. #9203
 *
 * "On Windows the internal state of FD_WRITE as returned from
 * WSAEnumNetworkEvents is only reset after successful send()."
 */
static void reset_socket_fdwrite(curl_socket_t s)
{
  int t;
  int l = (int)sizeof(t);
  if(!getsockopt(s, SOL_SOCKET, SO_TYPE, (char *)&t, &l) && t == SOCK_STREAM)
    swrite(s, NULL, 0);
}

static CURLMcode multi_winsock_select(struct Curl_multi *multi,
                                      struct curl_pollfds *cpfds,
                                      unsigned int curl_nfds,
                                      struct curl_waitfd extra_fds[],
                                      unsigned int extra_nfds,
                                      int timeout_ms,
                                      bool extrawait,
                                      int *pnevents)
{
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
      reset_socket_fdwrite(cpfds->pfds[i].fd);
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
    /* copy revents results from the poll to the curl_multi_wait poll
       struct, the bit values of the actual underlying poll() implementation
       may not be the same as the ones in the public libcurl API! */
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
}

#else /* USE_WINSOCK */

static CURLMcode multi_posix_poll(struct Curl_multi *multi,
                                  struct curl_pollfds *cpfds,
                                  unsigned int curl_nfds,
                                  struct curl_waitfd extra_fds[],
                                  unsigned int extra_nfds,
                                  int timeout_ms,
                                  bool extrawait,
                                  int *pnevents)
{
  CURLMcode mresult = CURLM_OK;
  int nevents = 0;
  size_t i;

  (void)multi;
  if(cpfds->n) {
    int pollrc = Curl_poll(cpfds->pfds, cpfds->n, timeout_ms); /* wait... */
    if(pollrc < 0) {
      mresult = CURLM_UNRECOVERABLE_POLL;
      goto out;
    }
    nevents = pollrc;

    /* copy revents results from the poll to the curl_multi_wait poll
       struct, the bit values of the actual underlying poll() implementation
       may not be the same as the ones in the public libcurl API! */
    for(i = 0; i < extra_nfds; i++) {
      unsigned r = (unsigned)cpfds->pfds[curl_nfds + i].revents;
      unsigned short mask = 0;
      if(r & POLLIN)
        mask |= CURL_WAIT_POLLIN;
      if(r & POLLOUT)
        mask |= CURL_WAIT_POLLOUT;
      if(r & POLLPRI)
        mask |= CURL_WAIT_POLLPRI;
      extra_fds[i].revents = (short)mask;
    }
  }
  else if(extrawait) {
    /* No fds to poll, but asked to obey timeout_ms anyway. We cannot
     * use Curl_poll() as it, on some platforms, returns immediately
     * without fds. */
    curlx_wait_ms(timeout_ms);
  }

out:
  *pnevents = nevents;
  return mresult;
}

#endif /* !USE_WINSOCK */

#define NUM_POLLS_ON_STACK 10

static CURLMcode multi_wait(struct Curl_multi *multi,
                            struct curl_waitfd extra_fds[],
                            unsigned int extra_nfds,
                            int timeout_ms,
                            int *ret,
                            bool extrawait)  /* when no socket, wait */
{
  size_t i;
  int timeout_internal;
  int nevents = 0;
  struct easy_pollset ps;
  struct pollfd a_few_on_stack[NUM_POLLS_ON_STACK];
  struct curl_pollfds cpfds;
  unsigned int curl_nfds = 0; /* how many pfds are for curl transfers */
  struct Curl_easy *data = NULL;
  CURLMcode mresult = CURLM_OK;
  uint32_t mid;
#ifdef ENABLE_WAKEUP
  int wakeup_idx = -1;
#endif

  if(timeout_ms < 0)
    return CURLM_BAD_FUNCTION_ARGUMENT;

  Curl_pollset_init(&ps);
  Curl_pollfds_init(&cpfds, a_few_on_stack, NUM_POLLS_ON_STACK);

  /* Add the curl handles to our pollfds first */
  if(Curl_uint32_bset_first(&multi->process, &mid)) {
    do {
      data = Curl_multi_get_easy(multi, mid);
      if(!data) {
        DEBUGASSERT(0);
        Curl_uint32_bset_remove(&multi->process, mid);
        Curl_uint32_bset_remove(&multi->dirty, mid);
        continue;
      }
      Curl_multi_pollset(data, &ps);
      if(Curl_pollfds_add_ps(&cpfds, &ps)) {
        mresult = CURLM_OUT_OF_MEMORY;
        goto out;
      }
    } while(Curl_uint32_bset_next(&multi->process, mid, &mid));
  }

  if(Curl_cshutdn_add_pollfds(&multi->cshutdn, multi->admin, &cpfds)) {
    mresult = CURLM_OUT_OF_MEMORY;
    goto out;
  }

#ifdef ENABLE_WAKEUP
  /* If `extrawait` is TRUE *or* we have `extra_fds`to poll *or* we
   * have transfer sockets to poll, we obey `timeout_ms`.
   * Then we need to also monitor the multi's wakeup
   * socket to catch calls to `curl_multi_wakeup()` during the wait. */
  if(extrawait || cpfds.n || extra_nfds) {
    wakeup_idx = cpfds.n;
    if(Curl_pollfds_add_sock(&cpfds, multi->wakeup_pair[0], POLLIN)) {
      mresult = CURLM_OUT_OF_MEMORY;
      goto out;
    }
  }
#endif

  curl_nfds = cpfds.n; /* what curl internally uses in cpfds */
  /* Add external file descriptions from poll-like struct curl_waitfd */
  for(i = 0; i < extra_nfds; i++) {
    unsigned short events = 0;
    if(extra_fds[i].events & CURL_WAIT_POLLIN)
      events |= POLLIN;
    if(extra_fds[i].events & CURL_WAIT_POLLPRI)
      events |= POLLPRI;
    if(extra_fds[i].events & CURL_WAIT_POLLOUT)
      events |= POLLOUT;
    if(Curl_pollfds_add_sock(&cpfds, extra_fds[i].fd, events)) {
      mresult = CURLM_OUT_OF_MEMORY;
      goto out;
    }
  }

  /* We check the internal timeout *AFTER* we collected all sockets to
   * poll. Collecting the sockets may install new timers by protocols
   * and connection filters.
   * Use the shorter one of the internal and the caller requested timeout.
   * If we are called with `!extrawait` and multi_timeout() reports no
   * timeouts exist, do not wait. */
  multi_timeout(multi, NULL, &timeout_internal);
  if((timeout_internal >= 0) && (timeout_internal < timeout_ms))
    timeout_ms = timeout_internal;

  if(data)
    CURL_TRC_M(data, "multi_wait(fds=%u, timeout=%d) tinternal=%d",
               cpfds.n, timeout_ms, timeout_internal);

#ifdef USE_WINSOCK
  mresult = multi_winsock_select(multi, &cpfds, curl_nfds,
                                 extra_fds, extra_nfds,
                                 timeout_ms, extrawait, &nevents);
#else
  mresult = multi_posix_poll(multi, &cpfds, curl_nfds,
                             extra_fds, extra_nfds,
                             timeout_ms, extrawait, &nevents);
#endif

#ifdef ENABLE_WAKEUP
    if(nevents && (wakeup_idx >= 0)) {
      if(cpfds.pfds[wakeup_idx].revents & POLLIN) {
        (void)Curl_wakeup_consume(multi->wakeup_pair, TRUE);
        /* do not count the wakeup socket into the returned value */
        nevents--;
      }
    }
#endif

out:
  Curl_pollset_cleanup(&ps);
  Curl_pollfds_cleanup(&cpfds);
  if(ret)
    *ret = nevents;
  return mresult;
}

CURLMcode curl_multi_wait(CURLM *m,
                          struct curl_waitfd extra_fds[],
                          unsigned int extra_nfds,
                          int timeout_ms,
                          int *ret)
{
  struct Curl_mapi_guard guard;
  CURLMcode mresult;

  if(CURL_MAPI_ENTER(&guard, m, multi_wait, &mresult)) {
    mresult = multi_wait(m, extra_fds, extra_nfds, timeout_ms, ret, FALSE);
  }
  CURL_MAPI_LEAVE(&guard);
  return mresult;
}

CURLMcode curl_multi_poll(CURLM *m,
                          struct curl_waitfd extra_fds[],
                          unsigned int extra_nfds,
                          int timeout_ms,
                          int *ret)
{
  struct Curl_mapi_guard guard;
  CURLMcode mresult;

  if(CURL_MAPI_ENTER(&guard, m, multi_poll, &mresult)) {
    mresult = multi_wait(m, extra_fds, extra_nfds, timeout_ms, ret, TRUE);
  }
  CURL_MAPI_LEAVE(&guard);
  return mresult;
}

CURLMcode curl_multi_wakeup(CURLM *m)
{
  /* this function is usually called from another thread,
     it has to be careful only to access parts of the
     Curl_multi struct that are constant */
  struct Curl_multi *multi = m;
  CURLMcode mresult = CURLM_WAKEUP_FAILURE;

  /* GOOD_MULTI_HANDLE can be safely called */
  if(!GOOD_MULTI_HANDLE(multi))
    return CURLM_BAD_HANDLE;

#ifdef ENABLE_WAKEUP
  /* the wakeup_pair variable is only written during init and cleanup,
     making it safe to access from another thread after the init part
     and before cleanup */
  if(!Curl_wakeup_signal(multi->wakeup_pair))
    mresult = CURLM_OK;
#endif
#ifdef USE_WINSOCK
  if(WSASetEvent(multi->wsa_event))
    mresult = CURLM_OK;
#endif
  return mresult;
}

#ifdef ENABLE_INTERNAL_WAKEUP
void Curl_multi_wakeup_internal(struct Curl_multi *multi)
{
  /* This is expected to be invocable from another thread which
   * does NOT outlive the multi handle. Check for sanity. */
  if(GOOD_MULTI_HANDLE(multi))
    Curl_wakeup_signal(multi->wakeup_internal);
  else
    DEBUGASSERT(0);
}
#endif

/*
 * multi_ischanged() is called
 *
 * Returns TRUE/FALSE whether the state is changed to trigger a CONNECT_PEND
 * => CONNECT action.
 *
 * Set 'clear' to TRUE to have it also clear the state variable.
 */
static bool multi_ischanged(struct Curl_multi *multi, bool clear)
{
  bool retval = FALSE;
  DEBUGASSERT(multi);
  if(multi) {
    retval = (bool)multi->recheckstate;
    if(clear)
      multi->recheckstate = FALSE;
  }
  return retval;
}

/*
 * Curl_multi_connchanged() is called to tell that there is a connection in
 * this multi handle that has changed state (multiplexing become possible, the
 * number of allowed streams changed or similar), and a subsequent use of this
 * multi handle should move CONNECT_PEND handles back to CONNECT to have them
 * retry.
 */
void Curl_multi_connchanged(struct Curl_multi *multi)
{
  /* May be invoked for a `data->multi` when no multi is present. */
  if(multi)
    multi->recheckstate = TRUE;
}

CURLMcode Curl_multi_add_perform(struct Curl_multi *multi,
                                 struct Curl_easy *data,
                                 struct connectdata *conn)
{
  CURLMcode mresult;

  mresult = Curl_multi_add_handle(multi, data);
  if(!mresult) {
    CURLcode result;

    /* pass in NULL for 'conn' here since we do not want to init the
       connection, only this transfer */
    result = Curl_init_transfer(data, NULL);
    if(result) {
      Curl_multi_remove_handle(multi, data);
      return CURLM_INTERNAL_ERROR;
    }

    /* take this handle to the perform state right away */
    multistate(data, MSTATE_PERFORMING);
    Curl_attach_connection(data, conn, TRUE);
    CURL_REQ_SET_RECV(data);
  }
  return mresult;
}

static CURLcode multi_do(struct Curl_easy *data, bool *done)
{
  CURLcode result = CURLE_OK;
  struct connectdata *conn = data->conn;

  DEBUGASSERT(conn);
  DEBUGASSERT(conn->scheme);

  if(conn->scheme->run->do_it)
    result = conn->scheme->run->do_it(data, done);

  return result;
}

/*
 * multi_do_more() is called during the DO_MORE multi state. It is a second
 * stage DO state which (wrongly) was introduced to support FTP's second
 * connection.
 *
 * 'complete' can return DOMORE_INCOMPLETE, DOMORE_DONE or DOMORE_GOBACK
 * (to DOING state when there is more work to do)
 */

static CURLcode multi_do_more(struct Curl_easy *data, domore *complete)
{
  CURLcode result = CURLE_OK;
  struct connectdata *conn = data->conn;

  *complete = DOMORE_INCOMPLETE;

  if(conn->scheme->run->do_more)
    result = conn->scheme->run->do_more(data, complete);

  return result;
}

/*
 * Check whether a timeout occurred, and handle it if it did
 */
static bool multi_handle_timeout(struct Curl_easy *data,
                                 const struct curltime *pnow,
                                 bool *stream_error,
                                 CURLcode *result)
{
  timediff_t timeout_ms;

  timeout_ms = Curl_timeleft_now_ms(data, pnow);
  if(timeout_ms < 0) {
    /* Handle timed out */
    timerid base_timer = Curl_is_connecting(data) ?
                         TIMER_STARTSINGLE : TIMER_STARTOP;
    timediff_t elapsed_ms = Curl_pgrs_since_ms(data, NULL, base_timer);
    if(data->mstate == MSTATE_CONNECTING) {
      failf(data, "%s timed out after %" FMT_TIMEDIFF_T " milliseconds",
            data->conn->bits.dns_resolved ? "Connection" : "Resolving",
            elapsed_ms);
      /* keep what we know about a partly done connect, e.g. TCP done
       * but TLS handshake still ongoing */
      Curl_conn_report_failed(data, FIRSTSOCKET);
    }
    else {
      struct SingleRequest *k = &data->req;
      if(k->size != -1) {
        failf(data, "Operation timed out after %" FMT_TIMEDIFF_T
              " milliseconds with %" FMT_OFF_T " out of %"
              FMT_OFF_T " bytes received",
              elapsed_ms, k->bytecount, k->size);
      }
      else {
        failf(data, "Operation timed out after %" FMT_TIMEDIFF_T
              " milliseconds with %" FMT_OFF_T " bytes received",
              elapsed_ms, k->bytecount);
      }
    }
    *result = CURLE_OPERATION_TIMEDOUT;
    if(data->conn) {
      /* Force connection closed if the connection has indeed been used */
      if(data->mstate > MSTATE_DO) {
        streamclose(data->conn);
        *stream_error = TRUE;
      }
      (void)multi_done(data, *result, TRUE);
    }
    return TRUE;
  }

  return FALSE;
}

/*
 * We are doing protocol-specific connecting and this is being called over and
 * over from the multi interface until the connection phase is done on
 * protocol layer.
 */

static CURLcode protocol_connecting(struct Curl_easy *data, bool *done)
{
  CURLcode result = CURLE_OK;
  struct connectdata *conn = data->conn;

  if(conn && conn->scheme->run->connecting) {
    *done = FALSE;
    result = conn->scheme->run->connecting(data, done);
  }
  else
    *done = TRUE;

  return result;
}

/*
 * We are DOING this is being called over and over from the multi interface
 * until the DOING phase is done on protocol layer.
 */

static CURLcode protocol_doing(struct Curl_easy *data, bool *done)
{
  CURLcode result = CURLE_OK;
  struct connectdata *conn = data->conn;

  if(conn && conn->scheme->run->doing) {
    *done = FALSE;
    result = conn->scheme->run->doing(data, done);
  }
  else
    *done = TRUE;

  return result;
}

/*
 * We have discovered that the TCP connection has been successful, we can now
 * proceed with some action.
 *
 */
static CURLcode protocol_connect(struct Curl_easy *data, bool *protocol_done)
{
  struct connectdata *conn = data->conn;
  CURLcode result = CURLE_OK;

  DEBUGASSERT(conn);
  DEBUGASSERT(protocol_done);
  DEBUGASSERT(Curl_conn_is_connected(conn, FIRSTSOCKET));

  *protocol_done = FALSE;
  if(!conn->bits.protoconnstart) {
    if(conn->scheme->run->connect_it) {
      /* Call the protocol-specific connect function */
      result = conn->scheme->run->connect_it(data, protocol_done);
      if(result)
        return result;
    }
    conn->bits.protoconnstart = TRUE;
  }

  /* Unless this protocol does not have any protocol-connect callback, as
     then we know we are done. */
  if(!conn->scheme->run->connecting)
    *protocol_done = TRUE;
  return CURLE_OK;
}

/*
 * posttransfer() is called immediately after a transfer ends
 */
static void multi_posttransfer(struct Curl_easy *data)
{
#if defined(HAVE_SIGNAL) && defined(SIGPIPE) && !defined(MSG_NOSIGNAL)
  /* restore the signal handler for SIGPIPE before we get back */
  if(!data->set.no_signal)
    signal(SIGPIPE, data->state.prev_signal);
#else
  (void)data;
#endif
}

/*
 * multi_follow() handles the URL redirect magic. Pass in the 'newurl' string
 * as given by the remote server and set up the new URL to request.
 *
 * This function DOES NOT FREE the given URL.
 */
static CURLcode multi_follow(struct Curl_easy *data,
                             const struct Curl_scheme *handler,
                             const char *newurl, /* the Location: string */
                             followtype type) /* see transfer.h */
{
  if(handler && handler->run->follow)
    return handler->run->follow(data, newurl, type);

  if(type == FOLLOW_RETRY)
    /* Retries are generic and do not require protocol-specific redirect
       handling. */
    return CURLE_OK;

  return CURLE_TOO_MANY_REDIRECTS;
}

static CURLcode mspeed_check(struct Curl_easy *data)
{
  if(Curl_rlimit_active(&data->progress.dl.rlimit) ||
     Curl_rlimit_active(&data->progress.ul.rlimit)) {
    /* check if our send/recv limits require idle waits */
    const struct curltime *pnow = Curl_pgrs_now(data);
    timediff_t recv_ms, send_ms;

    send_ms = Curl_rlimit_wait_ms(&data->progress.ul.rlimit, pnow);
    recv_ms = Curl_rlimit_wait_ms(&data->progress.dl.rlimit, pnow);

    if(send_ms || recv_ms) {
      if(data->mstate != MSTATE_RATELIMITING) {
        multistate(data, MSTATE_RATELIMITING);
      }
      Curl_expire_set(data, EXPIRE_TOOFAST, CURLMAX(send_ms, recv_ms), pnow);
      Curl_multi_clear_dirty(data);
      CURL_TRC_M(data, "[RLIMIT] waiting %" FMT_TIMEDIFF_T "ms",
                 CURLMAX(send_ms, recv_ms));
      return CURLE_AGAIN;
    }
    else {
      /* when will the rate limits increase next? The transfer needs
       * to run again at that time or it may stall. */
      send_ms = Curl_rlimit_next_step_ms(&data->progress.ul.rlimit, pnow);
      recv_ms = Curl_rlimit_next_step_ms(&data->progress.dl.rlimit, pnow);
      if(send_ms || recv_ms) {
        timediff_t next_ms = CURLMIN(send_ms, recv_ms);
        if(!next_ms)
          next_ms = CURLMAX(send_ms, recv_ms);
        Curl_expire_set(data, EXPIRE_TOOFAST, next_ms, pnow);
        CURL_TRC_M(data, "[RLIMIT] next token update in %" FMT_TIMEDIFF_T "ms",
                   next_ms);
      }
    }
  }

  if(data->mstate != MSTATE_PERFORMING) {
    CURL_TRC_M(data, "[RLIMIT] wait over, continue");
    multistate(data, MSTATE_PERFORMING);
  }
  return CURLE_OK;
}

static CURLMcode multistate_performing(struct Curl_easy *data,
                                       bool *stream_errorp,
                                       CURLcode *resultp)
{
  char *newurl = NULL;
  bool retry = FALSE;
  CURLMcode mresult = CURLM_OK;
  CURLcode result = *resultp = CURLE_OK;
  *stream_errorp = FALSE;

  if(mspeed_check(data) == CURLE_AGAIN)
    return CURLM_OK;

  /* read/write data if it is ready to do so */
  result = Curl_sendrecv(data);

  if(data->req.done || (result == CURLE_RECV_ERROR)) {
    /* If CURLE_RECV_ERROR happens early enough, we assume it was a race
     * condition and the server closed the reused connection exactly when we
     * wanted to use it, so figure out if that is indeed the case.
     */
    CURLcode ret = Curl_retry_request(data, &newurl);
    if(!ret)
      retry = !!newurl;
    else if(!result)
      result = ret;

    if(retry) {
      /* if we are to retry, set the result to OK and consider the
         request as done */
      result = CURLE_OK;
      data->req.done = TRUE;
    }
  }
#ifndef CURL_DISABLE_HTTP
  else if((result == CURLE_HTTP2_STREAM) &&
          Curl_h2_http_1_1_error(data)) {
    CURLcode ret = Curl_retry_request(data, &newurl);

    if(!ret) {
      infof(data, "Downgrades to HTTP/1.1");
      streamclose(data->conn);
      data->state.http_neg.wanted = CURL_HTTP_V1x;
      data->state.http_neg.allowed = CURL_HTTP_V1x;
      /* clear the error message bit too as we ignore the one we got */
      data->state.errorbuf = FALSE;
      if(!newurl)
        /* typically for HTTP_1_1_REQUIRED error on first flight */
        newurl = Curl_bufref_dup(&data->state.url);
      if(!newurl) {
        result = CURLE_OUT_OF_MEMORY;
      }
      else {
        /* if we are to retry, set the result to OK and consider the request
          as done */
        retry = TRUE;
        result = CURLE_OK;
        data->req.done = TRUE;
      }
    }
    else
      result = ret;
  }
#endif

  if(result) {
    /*
     * The transfer phase returned error, we mark the connection to get closed
     * to prevent being reused. This is because we cannot possibly know if the
     * connection is in a good shape or not now. Unless it is a protocol which
     * uses two "channels" like FTP, as then the error happened in the data
     * connection.
     */

    if(!(data->conn->scheme->flags & PROTOPT_DUAL) &&
       result != CURLE_HTTP2_STREAM)
      streamclose(data->conn);

    multi_posttransfer(data);
    multi_done(data, result, TRUE);
  }
  else if(data->req.done && !Curl_cwriter_is_paused(data)) {
    const struct Curl_scheme *handler = data->conn->scheme;

    /* call this even if the readwrite function returned error */
    multi_posttransfer(data);

    /* When we follow redirects or is set to retry the connection, we must to
       go back to the CONNECT state */
    if(data->req.newurl || retry) {
      followtype follow = FOLLOW_NONE;
      if(!retry) {
        /* if the URL is a follow-location and not a retried request then
           figure out the URL here */
        curlx_free(newurl);
        newurl = data->req.newurl;
        data->req.newurl = NULL;
        follow = FOLLOW_REDIR;
      }
      else
        follow = FOLLOW_RETRY;
      (void)multi_done(data, CURLE_OK, FALSE);
      /* multi_done() might return CURLE_GOT_NOTHING */
      result = multi_follow(data, handler, newurl, follow);
      if(!result) {
        multistate(data, MSTATE_SETUP);
        mresult = CURLM_CALL_MULTI_PERFORM;
      }
    }
    else {
      /* after the transfer is done, go DONE */

      /* but first check to see if we got a location info even though we are
         not following redirects */
      if(data->req.location) {
        curlx_free(newurl);
        newurl = data->req.location;
        data->req.location = NULL;
        result = multi_follow(data, handler, newurl, FOLLOW_FAKE);
        if(result) {
          *stream_errorp = TRUE;
          result = multi_done(data, result, TRUE);
        }
      }

      if(!result) {
        multistate(data, MSTATE_DONE);
        mresult = CURLM_CALL_MULTI_PERFORM;
      }
    }
  }
  else { /* not errored, not done */
    mspeed_check(data);
  }
  curlx_free(newurl);
  *resultp = result;
  return mresult;
}

static CURLMcode multistate_do(struct Curl_easy *data,
                               bool *stream_errorp,
                               CURLcode *resultp)
{
  CURLMcode mresult = CURLM_OK;
  CURLcode result = CURLE_OK;
  if(data->set.fprereq) {
    struct Curl_mapi_guard guard;
    int prereq_rc;

    /* call the prerequest callback function */
    CURL_CBAPI_START(&guard, data, easy_fprereq);
    prereq_rc = data->set.fprereq(data->set.prereq_userp,
                                  data->info.primary.remote_ip,
                                  data->info.primary.local_ip,
                                  data->info.primary.remote_port,
                                  data->info.primary.local_port);
    CURL_CBAPI_END(&guard);
    if(prereq_rc != CURL_PREREQFUNC_OK) {
      failf(data, "operation aborted by pre-request callback");
      /* failure in pre-request callback - do not do any other processing */
      result = CURLE_ABORTED_BY_CALLBACK;
      multi_posttransfer(data);
      multi_done(data, result, FALSE);
      *stream_errorp = TRUE;
      goto end;
    }
  }

  if(data->set.connect_only && !data->set.connect_only_ws) {
    multistate(data, MSTATE_DONE);
    mresult = CURLM_CALL_MULTI_PERFORM;
  }
  else {
    bool dophase_done = FALSE;
    /* Perform the protocol's DO action */
    result = multi_do(data, &dophase_done);

    if(!result) {
      if(!dophase_done) {
#ifndef CURL_DISABLE_FTP
        /* some steps needed for wildcard matching */
        if(data->state.wildcardmatch) {
          struct WildcardData *wc = data->wildcard;
          if(wc->state == CURLWC_DONE || wc->state == CURLWC_SKIP) {
            /* skip some states if it is important */
            multi_done(data, CURLE_OK, FALSE);

            /* if there is no connection left, skip the DONE state */
            multistate(data, data->conn ? MSTATE_DONE : MSTATE_COMPLETED);
            mresult = CURLM_CALL_MULTI_PERFORM;
            goto end;
          }
        }
#endif
        /* DO was not completed in one function call, we must continue
           DOING... */
        multistate(data, MSTATE_DOING);
        mresult = CURLM_CALL_MULTI_PERFORM;
      }

      /* after DO, go DO_DONE... or DO_MORE */
      else if(data->conn->bits.do_more) {
        /* we are supposed to do more, but we need to sit down, relax and wait
           a little while first */
        multistate(data, MSTATE_DOING_MORE);
        mresult = CURLM_CALL_MULTI_PERFORM;
      }
      else {
        /* we are done with the DO, now DID */
        multistate(data, MSTATE_DID);
        mresult = CURLM_CALL_MULTI_PERFORM;
      }
    }
    else if((result == CURLE_SEND_ERROR) &&
            data->conn->bits.reuse) {
      /*
       * In this situation, a connection that we were trying to use may have
       * unexpectedly died. If possible, send the connection back to the
       * CONNECT phase so we can try again.
       */
      const struct Curl_scheme *handler = data->conn->scheme;
      char *newurl = NULL;
      followtype follow = FOLLOW_NONE;
      CURLcode drc;

      drc = Curl_retry_request(data, &newurl);
      if(drc) {
        /* a failure here pretty much implies an out of memory */
        result = drc;
        *stream_errorp = TRUE;
      }

      multi_posttransfer(data);
      drc = multi_done(data, result, FALSE);

      /* When set to retry the connection, we must go back to the CONNECT
       * state */
      if(newurl) {
        if(!drc || (drc == CURLE_SEND_ERROR)) {
          follow = FOLLOW_RETRY;
          drc = multi_follow(data, handler, newurl, follow);
          if(!drc) {
            multistate(data, MSTATE_SETUP);
            mresult = CURLM_CALL_MULTI_PERFORM;
            result = CURLE_OK;
          }
          else {
            /* Follow failed */
            result = drc;
          }
        }
        else {
          /* done did not return OK or SEND_ERROR */
          result = drc;
        }
      }
      else {
        /* Have error handler disconnect conn if we cannot retry */
        *stream_errorp = TRUE;
      }
      curlx_free(newurl);
    }
    else {
      /* failure detected */
      multi_posttransfer(data);
      if(data->conn)
        multi_done(data, result, FALSE);
      *stream_errorp = TRUE;
    }
  }
end:
  *resultp = result;
  return mresult;
}

static CURLMcode multistate_ratelimiting(struct Curl_easy *data,
                                         CURLcode *resultp)
{
  CURLcode result = CURLE_OK;
  CURLMcode mresult = CURLM_OK;
  DEBUGASSERT(data->conn);
  /* if both rates are within spec, resume transfer */
  result = Curl_pgrsCheck(data);

  if(result) {
    if(!(data->conn->scheme->flags & PROTOPT_DUAL) &&
       result != CURLE_HTTP2_STREAM)
      streamclose(data->conn);

    multi_posttransfer(data);
    multi_done(data, result, TRUE);
  }
  else {
    if(!mspeed_check(data))
      mresult = CURLM_CALL_MULTI_PERFORM;
  }
  *resultp = result;
  return mresult;
}

static CURLMcode multistate_connect(struct Curl_multi *multi,
                                    struct Curl_easy *data,
                                    CURLcode *resultp)
{
  /* Connect. We want to get a connection identifier filled in. This state can
     be entered from SETUP and from PENDING. */
  bool connected;
  CURLMcode mresult = CURLM_OK;
  CURLcode result = Curl_connect(data, &connected);
  if(result == CURLE_NO_CONNECTION_AVAILABLE) {
    /* There was no connection available. We will go to the pending state and
       wait for an available connection. */
    multistate(data, MSTATE_PENDING);
    /* move from process to pending set */
    Curl_uint32_bset_remove(&multi->process, data->mid);
    Curl_uint32_bset_remove(&multi->dirty, data->mid);
    Curl_uint32_bset_add(&multi->pending, data->mid);
    *resultp = CURLE_OK;
    return mresult;
  }
  else
    multi_schedule_pending(data->multi);

  if(!result) {
    /* after the connect has been sent off, go WAITCONNECT unless the
       protocol connect is already done and we can go directly to WAITDO or
       DO! */
    mresult = CURLM_CALL_MULTI_PERFORM;

    if(connected) {
      if(!data->conn->bits.reuse &&
         Curl_conn_is_multiplex(data->conn, FIRSTSOCKET)) {
        /* new connection, can multiplex, wake pending handles */
        multi_schedule_pending(data->multi);
      }
      multistate(data, MSTATE_PROTOCONNECT);
    }
    else {
      multistate(data, MSTATE_CONNECTING);
    }
  }
  *resultp = result;
  return mresult;
}

/* returns the possibly updated result */
static CURLcode is_finished(struct Curl_multi *multi,
                            struct Curl_easy *data,
                            const struct curltime *pnow,
                            bool stream_error,
                            CURLcode result)
{
  if(data->mstate < MSTATE_COMPLETED) {
    if(result) {
      /*
       * If an error was returned, and we are not in completed state now,
       * then we go to completed and consider this transfer aborted.
       */

      /* No attempt to disconnect connections must be made before this -
         connection detach and termination happens only here */

      /* Check if we can move pending requests to send pipe */
      multi_schedule_pending(multi); /* connection */

      if(data->conn) {
        if(stream_error) {
          /* Do not attempt to send data over a connection that timed out */
          bool dead_connection = result == CURLE_OPERATION_TIMEDOUT;
          struct connectdata *conn = data->conn;

          /* This is where we make sure that the conn pointer is reset.
             We do not have to do this in every case block above where a
             failure is detected */
          Curl_detach_connection(data);
          Curl_conn_close(data, conn, dead_connection);
        }
      }
      else if(data->mstate == MSTATE_CONNECT) {
        /* Curl_connect() failed */
        multi_posttransfer(data);
        Curl_pgrsUpdate_nometer(data);
      }

      multistate(data, MSTATE_COMPLETED);
      return result;
    }
    /* if there is still a connection to use, call the progress function */
    else if(data->conn && Curl_conn_is_connected(data->conn, FIRSTSOCKET)) {
      result = Curl_pgrsUpdateX(data, pnow);
      if(result) {
        /* aborted due to progress callback return code must close the
           connection */
        streamclose(data->conn);

        /* if not yet in DONE state, go there. */
        if(data->mstate < MSTATE_DONE)
          multistate(data, MSTATE_DONE);
        return result;
      }
    }
  }
  return result;
}

static void handle_completed(struct Curl_multi *multi,
                             struct Curl_easy *data,
                             CURLcode result)
{
  bool msg_to_app = data->master_mid == UINT32_MAX;

  if(!msg_to_app) {
    /* A sub transfer, not reported to the application. Is anyone still
     * interested in processing its results? */
    if(data->sub_xfer_done) {
      struct Curl_easy *master = Curl_multi_get_easy(multi, data->master_mid);

      CURL_TRC_M(data, "sub xfer done for master %u", data->master_mid);
      if(master)
        data->sub_xfer_done(data, master, result);
      else
        CURL_TRC_M(data, "master easy %u already gone.", data->master_mid);
    }
  }
  else {
    /* now fill in the CURLMsg with this info */
    struct CURLMsg *msg = &data->msg;

    msg->msg = CURLMSG_DONE;
    msg->easy_handle = data;
    msg->data.result = result;

    DEBUGASSERT(!data->conn);
  }
  multistate(data, MSTATE_MSGSENT);

  /* remove from the other sets */
  Curl_uint32_bset_remove(&multi->process, data->mid);
  Curl_uint32_bset_remove(&multi->dirty, data->mid);
  Curl_uint32_bset_remove(&multi->pending, data->mid);
  if(msg_to_app)
    multi_addmsg(multi, data);
  if(data->state.really_alive) {
    data->state.really_alive = FALSE;
    --multi->xfers_really_alive;
    if(!multi->xfers_really_alive)
      (void)multi_assess_wakeup(multi);
  }
  --multi->xfers_alive;
  if(!multi->xfers_alive)
    multi_assess_wakeup(multi);
}

static CURLMcode multistate_init(struct Curl_easy *data, CURLcode *result)
{
  if(!data->state.really_alive) {
    data->state.really_alive = TRUE;
    ++data->multi->xfers_really_alive;
    if(data->multi->xfers_really_alive == 1) {
      CURLMcode mresult = multi_assess_wakeup(data->multi);
      if(mresult) {
        failf(data, "error enabling wakeup listening: %d", mresult);
        return mresult;
      }
    }
  }

  *result = Curl_pretransfer(data);
  if(*result)
    return CURLM_OK;

  /* after init, go SETUP */
  multistate(data, MSTATE_SETUP);
  Curl_pgrsTime(data, TIMER_STARTOP);
  return CURLM_CALL_MULTI_PERFORM;
}

static CURLMcode multistate_setup(struct Curl_easy *data)
{
  const struct curltime *pnow = Curl_pgrs_now(data);
  Curl_pgrsTimeWas(data, TIMER_STARTSINGLE, *pnow);
  if(data->set.timeout)
    Curl_expire_set(data, EXPIRE_TIMEOUT, data->set.timeout, pnow);
  if(data->set.connecttimeout)
    /* Since a connection might go to pending and back to CONNECT several
       times before it actually takes off, we need to set the timeout once
       in SETUP before we enter CONNECT the first time. */
    Curl_expire_set(data, EXPIRE_CONNECTTIMEOUT,
                    data->set.connecttimeout, pnow);

  multistate(data, MSTATE_CONNECT);
  return CURLM_CALL_MULTI_PERFORM;
}

static CURLMcode multistate_connecting(struct Curl_easy *data,
                                       bool *stream_error,
                                       CURLcode *result)
{
  bool connected;

  if(!data->conn) {
    DEBUGASSERT(0);
    *result = CURLE_FAILED_INIT;
    return CURLM_OK;
  }
  if(!Curl_xfer_recv_is_paused(data)) {
    *result = Curl_conn_connect(data, FIRSTSOCKET, FALSE, &connected);
    if(connected && !*result) {
      if(!data->conn->bits.reuse &&
         Curl_conn_is_multiplex(data->conn, FIRSTSOCKET)) {
        /* new connection, can multiplex, wake pending handles */
        multi_schedule_pending(data->multi);
      }
      multistate(data, MSTATE_PROTOCONNECT);
      return CURLM_CALL_MULTI_PERFORM;
    }
    else if(*result) {
      /* failure detected */
      CURL_TRC_M(data, "connect failed -> %d", (int)*result);
      multi_posttransfer(data);
      multi_done(data, *result, TRUE);
      *stream_error = TRUE;
      return CURLM_OK;
    }
  }
  return CURLM_OK;
}

static CURLMcode multistate_protoconnect(struct Curl_easy *data,
                                         bool *stream_error,
                                         CURLcode *result)
{
  bool protocol_connected = FALSE;

  if(!*result && data->conn->bits.reuse) {
    /* ftp seems to hang when protoconnect on reused connection since we
     * handle PROTOCONNECT in general inside the filters, it seems wrong to
     * restart this on a reused connection.
     */
    multistate(data, MSTATE_DO);
    return CURLM_CALL_MULTI_PERFORM;
  }
  if(!*result)
    *result = protocol_connect(data, &protocol_connected);
  if(!*result && !protocol_connected) {
    /* switch to waiting state */
    multistate(data, MSTATE_PROTOCONNECTING);
    return CURLM_CALL_MULTI_PERFORM;
  }
  else if(!*result) {
    /* protocol connect has completed, go WAITDO or DO */
    multistate(data, MSTATE_DO);
    return CURLM_CALL_MULTI_PERFORM;
  }

  /* failure detected */
  multi_posttransfer(data);
  multi_done(data, *result, TRUE);
  *stream_error = TRUE;
  return CURLM_OK;
}

static CURLMcode multistate_protoconnecting(struct Curl_easy *data,
                                            bool *stream_error,
                                            CURLcode *result)
{
  bool protocol_connected = FALSE;

  /* protocol-specific connect phase */
  *result = protocol_connecting(data, &protocol_connected);
  if(!*result && protocol_connected) {
    /* after the connect has completed, go WAITDO or DO */
    multistate(data, MSTATE_DO);
    return CURLM_CALL_MULTI_PERFORM;
  }
  else if(*result) {
    /* failure detected */
    multi_posttransfer(data);
    multi_done(data, *result, TRUE);
    *stream_error = TRUE;
  }
  return CURLM_OK;
}

static CURLMcode multistate_doing(struct Curl_easy *data,
                                  bool *stream_error,
                                  CURLcode *result)
{
  bool dophase_done = FALSE;

  /* we continue DOING until the DO phase is complete */
  DEBUGASSERT(data->conn);
  *result = protocol_doing(data, &dophase_done);
  if(!*result) {
    if(dophase_done) {
      /* after DO, go DO_DONE or DO_MORE */
      multistate(data, data->conn->bits.do_more ?
                 MSTATE_DOING_MORE : MSTATE_DID);
      return CURLM_CALL_MULTI_PERFORM;
    } /* dophase_done */
  }
  else {
    /* failure detected */
    multi_posttransfer(data);
    multi_done(data, *result, FALSE);
    *stream_error = TRUE;
  }
  return CURLM_OK;
}

static CURLMcode multistate_doing_more(struct Curl_easy *data,
                                       bool *stream_error,
                                       CURLcode *result)
{
  domore control;

  /*
   * When we are connected, DOING MORE and then go DID
   */
  DEBUGASSERT(data->conn);
  *result = multi_do_more(data, &control);

  if(!*result) {
    if(control != DOMORE_INCOMPLETE) {
      /* if DONE, advance to DO_DONE
         if GOBACK, go back to DOING */
      multistate(data, control == DOMORE_DONE ? MSTATE_DID : MSTATE_DOING);
      return CURLM_CALL_MULTI_PERFORM;
    }
    /* else
       stay in DO_MORE */
  }
  else {
    /* failure detected */
    multi_posttransfer(data);
    multi_done(data, *result, FALSE);
    *stream_error = TRUE;
  }
  return CURLM_OK;
}

static CURLMcode multistate_did(struct Curl_multi *multi,
                                struct Curl_easy *data)
{
  DEBUGASSERT(data->conn);
  if(data->conn->bits.multiplex)
    /* Check if we can move pending requests to send pipe */
    multi_schedule_pending(multi); /* multiplexed */

  /* Only perform the transfer if there is a good socket to work with.
     Having both BAD is a signal to skip immediately to DONE */
  if(CONN_SOCK_IDX_VALID(data->conn->recv_idx) ||
     CONN_SOCK_IDX_VALID(data->conn->send_idx)) {
    multistate(data, MSTATE_PERFORMING);
    /* Do not return CURLM_CALL_MULTI_PERFORM to give other transfers
     * a chance to send off their requests.
     * Note: Some SFTP handlers do not seem to like this.
     *       Restrict it to HTTP families. */
    return ((multi->xfers_alive > 1) &&
            (data->conn->scheme->protocol & PROTO_FAMILY_HTTP)) ?
           CURLM_OK : CURLM_CALL_MULTI_PERFORM;
  }
  else {
#ifndef CURL_DISABLE_FTP
    if(data->state.wildcardmatch &&
       ((data->conn->scheme->flags & PROTOPT_WILDCARD) == 0)) {
      data->wildcard->state = CURLWC_DONE;
    }
#endif
    multistate(data, MSTATE_DONE);
    return CURLM_CALL_MULTI_PERFORM;
  }
}

static CURLMcode multistate_done(struct Curl_easy *data, CURLcode *presult)
{
  if(data->conn) {
    CURLcode result;

    /* post-transfer command */
    result = multi_done(data, *presult, FALSE);

    /* allow a previously set error code take precedence */
    if(!(*presult))
      *presult = result;
  }

#ifndef CURL_DISABLE_FTP
  if(data->state.wildcardmatch) {
    if(data->wildcard->state != CURLWC_DONE) {
      /* if a wildcard is set and we are not ending -> lets start again
         with MSTATE_INIT */
      multistate(data, MSTATE_INIT);
      return CURLM_CALL_MULTI_PERFORM;
    }
  }
#endif
  /* after we have DONE what we are supposed to do, go COMPLETED, and
     it does not matter what the multi_done() returned! */
  multistate(data, MSTATE_COMPLETED);
  return CURLM_CALL_MULTI_PERFORM;
}

static CURLMcode multi_runsingle(struct Curl_multi *multi,
                                 struct Curl_easy *data,
                                 struct Curl_sigpipe_ctx *sigpipe_ctx)
{
  CURLMcode mresult = CURLM_OK;
  CURLcode result = CURLE_OK;
  const struct curltime *pnow = NULL;

  if(multi->dead) {
    /* a multi-level callback returned error before, meaning every individual
     transfer now has failed */
    result = CURLE_ABORTED_BY_CALLBACK;
    multi_posttransfer(data);
    multi_done(data, result, FALSE);
    multistate(data, MSTATE_COMPLETED);
  }

  multi_warn_debug(multi, data);

  /* transfer runs now, clear the dirty bit. This may be set
   * again during processing, triggering a re-run later. */
  Curl_uint32_bset_remove(&multi->dirty, data->mid);

  if(data == multi->admin) {
#ifdef ENABLE_INTERNAL_WAKEUP
    /* Consume any pending wakeup signals before processing.
     * This is necessary for event based processing. See #21547 */
    (void)Curl_wakeup_consume(multi->wakeup_internal, TRUE);
#endif
#ifdef USE_RESOLV_THREADED
    Curl_async_thrdd_multi_process(multi);
#endif
    Curl_cshutdn_perform(&multi->cshutdn, multi->admin, sigpipe_ctx);
    goto out;
  }

  sigpipe_apply(data, sigpipe_ctx);
  do {
    /* A "stream" here is a logical stream if the protocol can handle that
       (HTTP/2), or the full connection for older protocols */
    bool stream_error = FALSE;
    mresult = CURLM_OK;
    pnow = NULL;

    if(multi_ischanged(multi, TRUE)) {
      CURL_TRC_M(data, "multi changed, check CONNECT_PEND queue");
      multi_schedule_pending(multi); /* multiplexed */
    }

    if(data->mstate > MSTATE_CONNECT &&
       data->mstate < MSTATE_COMPLETED) {
      /* Make sure we set the connection's current owner */
      DEBUGASSERT(data->conn);
      if(!data->conn) {
        mresult = CURLM_INTERNAL_ERROR;
        goto out;
      }
    }

    /* Wait for the connect state as only then is the start time stored, but
       we must not check already completed handles */
    if((data->mstate >= MSTATE_CONNECT) && (data->mstate < MSTATE_COMPLETED)) {
      pnow = Curl_pgrs_now(data);
      if(multi_handle_timeout(data, pnow, &stream_error, &result))
        /* Skip the statemachine and go directly to error handling section. */
        goto statemachine_end;
      pnow = NULL;
    }

    switch(data->mstate) {
    case MSTATE_INIT:
      /* Transitional state. init this transfer. A handle never comes back to
         this state. */
      mresult = multistate_init(data, &result);
      break;

    case MSTATE_SETUP:
      /* Transitional state. Setup things for a new transfer. The handle
         can come back to this state on a redirect. */
      mresult = multistate_setup(data);
      break;

    case MSTATE_CONNECT:
      mresult = multistate_connect(multi, data, &result);
      break;

    case MSTATE_CONNECTING:
      /* awaiting a completion of an asynch TCP connect */
      mresult = multistate_connecting(data, &stream_error, &result);
      break;

    case MSTATE_PROTOCONNECT:
      mresult = multistate_protoconnect(data, &stream_error, &result);
      break;

    case MSTATE_PROTOCONNECTING:
      /* protocol-specific connect phase */
      mresult = multistate_protoconnecting(data, &stream_error, &result);
      break;

    case MSTATE_DO:
      mresult = multistate_do(data, &stream_error, &result);
      break;

    case MSTATE_DOING:
      /* we continue DOING until the DO phase is complete */
      mresult = multistate_doing(data, &stream_error, &result);
      break;

    case MSTATE_DOING_MORE:
      /*
       * When we are connected, DOING MORE and then go DID
       */
      mresult = multistate_doing_more(data, &stream_error, &result);
      break;

    case MSTATE_DID:
      mresult = multistate_did(multi, data);
      break;

    case MSTATE_RATELIMITING: /* limit-rate exceeded in either direction */
      mresult = multistate_ratelimiting(data, &result);
      break;

    case MSTATE_PERFORMING:
      mresult = multistate_performing(data, &stream_error, &result);
      break;

    case MSTATE_DONE:
      mresult = multistate_done(data, &result);
      break;

    case MSTATE_COMPLETED:
      break;

    case MSTATE_PENDING:
    case MSTATE_MSGSENT:
      /* handles in these states should NOT be in this list */
      break;

    default:
      mresult = CURLM_INTERNAL_ERROR;
      goto out;
    }

    if(data->mstate >= MSTATE_CONNECT &&
       data->mstate < MSTATE_DO &&
       mresult != CURLM_CALL_MULTI_PERFORM &&
       !multi_ischanged(multi, FALSE)) {
      /* We now handle stream timeouts if and only if this will be the last
       * loop iteration. We only check this on the last iteration to ensure
       * that if we know we have additional work to do immediately
       * (i.e. CURLM_CALL_MULTI_PERFORM == TRUE) then we should do that before
       * declaring the connection timed out as we may almost have a completed
       * connection. */
      pnow = Curl_pgrs_now(data);
      multi_handle_timeout(data, pnow, &stream_error, &result);
    }

statemachine_end:
    if(!pnow)
      pnow = Curl_pgrs_now(data);
    result = is_finished(multi, data, pnow, stream_error, result);
    if(result)
      mresult = CURLM_CALL_MULTI_PERFORM;

    if(MSTATE_COMPLETED == data->mstate) {
      handle_completed(multi, data, result);
      mresult = CURLM_OK;
      goto out;
    }
  } while((mresult == CURLM_CALL_MULTI_PERFORM) ||
          multi_ischanged(multi, FALSE));

out:
  data->result = result;
  return mresult;
}

static CURLMcode multi_perform(struct Curl_multi *multi,
                               int *running_handles)
{
  CURLMcode returncode = CURLM_OK;
  struct curltime start;
  uint32_t mid;
  struct Curl_sigpipe_ctx sigpipe_ctx;

  curlx_pnow(&start);
  sigpipe_init(&sigpipe_ctx);

  if(Curl_uint32_bset_first(&multi->process, &mid)) {
    CURL_TRC_M(multi->admin, "multi_perform(running=%u)",
               multi_xfers_running(multi));
    do {
      struct Curl_easy *data = Curl_multi_get_easy(multi, mid);
      CURLMcode mresult;
      if(!data) {
        DEBUGASSERT(0);
        Curl_uint32_bset_remove(&multi->process, mid);
        Curl_uint32_bset_remove(&multi->dirty, mid);
        continue;
      }
      mresult = multi_runsingle(multi, data, &sigpipe_ctx);
      if(mresult)
        returncode = mresult;
    } while(Curl_uint32_bset_next(&multi->process, mid, &mid));
  }
  sigpipe_restore(&sigpipe_ctx);

  if(multi_ischanged(multi, TRUE))
    multi_schedule_pending(multi);

  if(!returncode && CURL_MNTFY_HAS_ENTRIES(multi))
    returncode = Curl_mntfy_dispatch_all(multi);

  /*
   * Remove all expired timers from the splay since handles are dealt
   * with unconditionally by this function and curl_multi_timeout() requires
   * that already passed/handled expire times are removed from the splay.
   *
   * It is important that the 'now' value is set at the entry of this function
   * and not for the current time as it may have ticked a little while since
   * then and then we risk this loop to remove timers that actually have not
   * been handled!
   */
  while(Curl_timeouts_remove_expired(&multi->timeouts, &start, &mid)) {
    /* the removed may have another timeout in queue */
    struct Curl_easy *data = Curl_multi_get_easy(multi, mid);
    if(!data) {
      DEBUGASSERT(0);
      continue;
    }
    (void)add_next_timeout(&start, multi, data);
    if(data->mstate == MSTATE_PENDING) {
      bool stream_unused;
      CURLcode result_unused;
      if(multi_handle_timeout(data, Curl_pgrs_now(data),
                              &stream_unused, &result_unused)) {
        infof(data, "PENDING handle timeout");
        move_pending_to_connect(multi, data);
      }
    }
  }

  if(running_handles) {
    uint32_t running = multi_xfers_running(multi);
    *running_handles = (running < INT_MAX) ? (int)running : INT_MAX;
  }

  if(CURLM_OK >= returncode)
    returncode = Curl_update_timer(multi);

  return returncode;
}

CURLMcode curl_multi_perform(CURLM *m, int *running_handles)
{
  struct Curl_mapi_guard guard;
  CURLMcode mresult;

  if(CURL_MAPI_ENTER(&guard, m, multi_perform, &mresult)) {
    mresult = multi_perform(m, running_handles);
  }
  CURL_MAPI_LEAVE(&guard);
  return mresult;
}

CURLMcode curl_multi_cleanup(CURLM *m)
{
  struct Curl_mapi_guard guard;
  CURLMcode mresult;

  if(CURL_MAPI_ENTER(&guard, m, multi_cleanup, &mresult)) {
    struct Curl_multi *multi = m;
    void *entry;
    uint32_t mid;

    /* First remove all remaining easy handles,
     * close internal ones. admin handle is special */
    if(Curl_uint32_tbl_first(&multi->xfers, &mid, &entry)) {
      do {
        struct Curl_easy *data = entry;
        if(!GOOD_EASY_HANDLE(data)) {
          mresult = CURLM_BAD_HANDLE;
          goto out;
        }

#ifdef DEBUGBUILD
        if(mid != data->mid) {
          CURL_TRC_M(data, "multi_cleanup: still present with mid=%u, "
                     "but unexpected data->mid=%u\n", mid, data->mid);
          DEBUGASSERT(0);
        }
#endif

        if(data == multi->admin)
          continue;

        if(!data->state.done && data->conn)
          /* if DONE was never called for this handle */
          (void)multi_done(data, CURLE_OK, TRUE);

        data->multi = NULL; /* clear the association */
        Curl_uint32_tbl_remove(&multi->xfers, mid);
        data->mid = UINT32_MAX;

#ifdef USE_LIBPSL
        if(data->psl == &multi->psl)
          data->psl = NULL;
#endif
        if(data->state.internal)
          Curl_close(&data);
      } while(Curl_uint32_tbl_next(&multi->xfers, mid, &mid, &entry));
    }

#ifdef USE_RESOLV_THREADED
    Curl_async_thrdd_multi_destroy(multi, !multi->quick_exit);
#endif
    Curl_cpool_destroy(&multi->cpool, multi->admin);
    Curl_cshutdn_destroy(&multi->cshutdn, multi->admin);
    if(multi->admin) {
      CURL_TRC_M(multi->admin, "multi_cleanup, closing admin handle, done");
      multi->admin->multi = NULL;
      Curl_uint32_tbl_remove(&multi->xfers, multi->admin->mid);
      Curl_close(&multi->admin);
    }

    multi->magic = 0; /* not good anymore */

    Curl_multi_ev_cleanup(multi);
    Curl_hash_destroy(&multi->proto_hash);
    Curl_dnscache_destroy(&multi->dnscache);
    Curl_psl_destroy(&multi->psl);
#ifdef USE_SSL
    Curl_ssl_scache_destroy(multi->ssl_scache);
#endif

#ifdef USE_WINSOCK
    WSACloseEvent(multi->wsa_event);
#endif
#ifdef ENABLE_WAKEUP
  Curl_wakeup_destroy(multi->wakeup_pair);
#endif
#ifdef ENABLE_INTERNAL_WAKEUP
  Curl_wakeup_destroy(multi->wakeup_internal);
#endif

    multi_xfer_bufs_free(multi);
    Curl_mntfy_cleanup(multi);
#ifdef DEBUGBUILD
    if(Curl_uint32_tbl_count(&multi->xfers)) {
      multi_xfer_tbl_dump(multi);
      DEBUGASSERT(0);
    }
#endif
    Curl_uint32_bset_destroy(&multi->process);
    Curl_uint32_bset_destroy(&multi->dirty);
    Curl_uint32_bset_destroy(&multi->pending);
    Curl_uint32_bset_destroy(&multi->msgsent);
    Curl_uint32_tbl_destroy(&multi->xfers);
    curlx_memzero(multi, sizeof(*multi));
    curlx_free(multi);

    mresult = CURLM_OK;
  }
out:
  CURL_MAPI_LEAVE(&guard);
  return mresult;
}

/*
 * curl_multi_info_read()
 *
 * This function is the primary way for a multi/multi_socket application to
 * figure out if a transfer has ended.
 */

CURLMsg *curl_multi_info_read(CURLM *m, int *msgs_in_queue)
{
  struct Curl_mapi_guard guard;
  CURLMsg *msg_result = NULL;

  *msgs_in_queue = 0; /* default to none */
  if(CURL_MAPI_ENTER(&guard, m, multi_info_read, NULL)) {
    struct Curl_multi *multi = m;
    uint32_t mid;
    if(Curl_uint32_bset_first(&multi->msgsent, &mid)) {
      struct Curl_easy *data = Curl_multi_get_easy(multi, mid);

      DEBUGASSERT(data);
      Curl_uint32_bset_remove(&multi->msgsent, mid);
      *msgs_in_queue =
        curlx_uztosi(Curl_uint32_bset_count(&multi->msgsent));
      if(data)
        msg_result = &data->msg;
    }
  }
  CURL_MAPI_LEAVE(&guard);
  return msg_result;
}

void Curl_multi_will_close(struct Curl_easy *data, curl_socket_t s)
{
  if(data) {
    struct Curl_multi *multi = data->multi;
    if(multi) {
      CURL_TRC_M(data, "Curl_multi_will_close fd=%" FMT_SOCKET_T, s);
      Curl_multi_ev_socket_done(multi, data, s);
    }
  }
}

static void multi_timeouts_init(struct Curl_easy *data)
{
  data->state.timeouts.first = EXPIRE_LAST;
  data->state.timeouts.splaynode.registered = FALSE;
}

/*
 * Each Curl_easy has a list of timeouts. The add_next_timeout() is called
 * when it has been removed from the splay tree because the timeout has
 * expired. This function is then to advance in the list to pick the next
 * timeout to use (skip the already expired ones) and add this node back to
 * the splay tree again.
 *
 * The splay tree only has each Curl_easy as a single node and the nearest
 * timeout is used to sort it on.
 */
static CURLMcode add_next_timeout(const struct curltime *pnow,
                                  struct Curl_multi *multi,
                                  struct Curl_easy *data)
{
  struct expire_timers *timeouts = &data->state.timeouts;
  timediff_t now_us = Curl_timeouts_offset_us(&multi->timeouts, pnow);

  while(timeouts->first < EXPIRE_LAST) {
    if(timeouts->offset_us[timeouts->first] <= now_us)  /* already expired */
      timeouts->first = timeouts->next[timeouts->first];
    else /* timeouts are sorted, first is first in the future now */
      break;
  }

  if(timeouts->first < EXPIRE_LAST) {
    /* Insert this node again into the splay. Keep the timer in the list in
       case we need to recompute future timers. */
    Curl_timeouts_add(&multi->timeouts, data,
                      timeouts->offset_us[timeouts->first]);
  }
  return CURLM_OK;
}

static void multi_mark_expired_as_dirty(struct Curl_multi *multi,
                                        const struct curltime *ts)
{
  struct Curl_easy *data = NULL;
  uint32_t mid;

  /*
   * The loop following here will go on as long as there are expire-times left
   * to process (compared to `ts`) in the splay and 'data' will be
   * re-assigned for every expired handle we deal with.
   */
  while(Curl_timeouts_remove_expired(&multi->timeouts, ts, &mid)) {
    /* Check if there is one (more) expired timer to deal with! This function
       extracts a matching node if there is one */
    data = Curl_multi_get_easy(multi, mid);
    if(!data) {
      DEBUGASSERT(0);
      continue;
    }
#ifdef CURLVERBOSE
    if(CURL_TRC_TIMER_is_verbose(data)) {
      if(data->state.timeouts.first < EXPIRE_LAST) {
        CURL_TRC_TIMER(data, data->state.timeouts.first, "has expired");
      }
    }
#endif
    (void)add_next_timeout(ts, multi, data);
    Curl_multi_mark_dirty(data);
  }
}

static CURLMcode multi_run_dirty(struct Curl_multi *multi,
                                 struct Curl_sigpipe_ctx *sigpipe_ctx,
                                 uint32_t *pnum)
{
  CURLMcode mresult = CURLM_OK;
  uint32_t mid;

  *pnum = 0;
  if(Curl_uint32_bset_first(&multi->dirty, &mid)) {
    do {
      struct Curl_easy *data = Curl_multi_get_easy(multi, mid);
      if(data) {
        CURL_TRC_M(data, "multi_run_dirty");

        if(!Curl_uint32_bset_contains(&multi->process, mid)) {
          if(Curl_uint32_bset_contains(&multi->pending, mid)) {
            /* Something happened on the pending transfer, act on it. */
            move_pending_to_connect(multi, data);
          }
          else {
            /* We are no longer processing this transfer */
            Curl_uint32_bset_remove(&multi->dirty, mid);
            continue;
          }
        }

        (*pnum)++;
        /* runsingle() clears the dirty mid */
        mresult = multi_runsingle(multi, data, sigpipe_ctx);

        if(CURLM_OK >= mresult) {
          /* reassess event handling of data */
          mresult = Curl_multi_ev_assess_xfer(multi, data);
          if(mresult)
            goto out;
        }
      }
      else {
        CURL_TRC_M(multi->admin, "multi_run_dirty, %u no longer found", mid);
        Curl_uint32_bset_remove(&multi->dirty, mid);
      }
    } while(Curl_uint32_bset_next(&multi->dirty, mid, &mid));
  }

out:
  return mresult;
}

static CURLMcode multi_socket(struct Curl_multi *multi,
                              bool checkall,
                              curl_socket_t s,
                              int ev_bitmask,
                              int *running_handles)
{
  CURLMcode mresult = CURLM_OK;
  struct Curl_sigpipe_ctx pipe_ctx;
  struct curltime now;
  uint32_t run_xfers;

  (void)ev_bitmask;
  sigpipe_init(&pipe_ctx);

  if(checkall) {
    /* *perform() deals with running_handles on its own */
    mresult = multi_perform(multi, running_handles);

    if(mresult != CURLM_BAD_HANDLE) {
      /* Reassess event status of all active transfers */
      mresult = Curl_multi_ev_assess_xfer_bset(multi, &multi->process);
    }
    goto out;
  }

  if(s != CURL_SOCKET_TIMEOUT) {
    /* Mark all transfers of that socket as dirty */
    Curl_multi_ev_dirty_xfers(multi, s);
  }
  else {
    /* Asked to run due to time-out. Clear the 'last_expire_ts' variable to
       force Curl_update_timer() to trigger a callback to the app again even
       if the same timeout is still the one to run after this call. That
       handles the case when the application asks libcurl to run the timeout
       prematurely. */
    multi->last_expire_offset_us = 0;

    /* Applications may set `socket_cb` *after* having added transfers
     * first. *Then* kick off processing with a
     * curl_multi_socket_action(TIMEOUT) afterwards. Make sure our
     * admin handle registers its pollset with the callbacks present. */
    mresult = multi_assess_wakeup(multi);
    if(mresult)
      goto out;
  }

  curlx_pnow(&now);
  multi_mark_expired_as_dirty(multi, &now);
  mresult = multi_run_dirty(multi, &pipe_ctx, &run_xfers);
  if(mresult)
    goto out;

  if(run_xfers) {
    /* Running transfers takes time. With a new timestamp, we might catch
     * other expires which are due now. Instead of telling the application
     * to set a 0 timeout and call us again, we run them here.
     * Do that only once or it might be unfair to transfers on other
     * sockets. */
    curlx_pnow(&now);
    multi_mark_expired_as_dirty(multi, &now);
    mresult = multi_run_dirty(multi, &pipe_ctx, &run_xfers);
  }

out:
  sigpipe_restore(&pipe_ctx);

  if(multi_ischanged(multi, TRUE))
    multi_schedule_pending(multi);

  if(!mresult && CURL_MNTFY_HAS_ENTRIES(multi))
    mresult = Curl_mntfy_dispatch_all(multi);

  if(running_handles) {
    uint32_t running = multi_xfers_running(multi);
    *running_handles = (running < INT_MAX) ? (int)running : INT_MAX;
  }

  if(CURLM_OK >= mresult)
    mresult = Curl_update_timer(multi);
  return mresult;
}

#undef curl_multi_setopt
CURLMcode curl_multi_setopt(CURLM *m, CURLMoption option, ...)
{
  struct Curl_mapi_guard guard;
  CURLMcode mresult = CURLM_OK;

  if(CURL_MAPI_ENTER(&guard, m, multi_setopt, &mresult)) {
    struct Curl_multi *multi = m;
    va_list param;
    unsigned long uarg;
    size_t szarg;

    va_start(param, option);

    switch(option) {
    case CURLMOPT_SOCKETFUNCTION:
      multi->socket_cb = va_arg(param, curl_socket_callback);
      break;
    case CURLMOPT_SOCKETDATA:
      multi->socket_userp = va_arg(param, void *);
      break;
    case CURLMOPT_PUSHFUNCTION:
      multi->push_cb = va_arg(param, curl_push_callback);
      break;
    case CURLMOPT_PUSHDATA:
      multi->push_userp = va_arg(param, void *);
      break;
    case CURLMOPT_PIPELINING:
      multi->multiplexing = va_arg(param, long) & CURLPIPE_MULTIPLEX ? 1 : 0;
      break;
    case CURLMOPT_TIMERFUNCTION:
      multi->timer_cb = va_arg(param, curl_multi_timer_callback);
      break;
    case CURLMOPT_TIMERDATA:
      multi->timer_userp = va_arg(param, void *);
      break;
    case CURLMOPT_MAXCONNECTS:
      uarg = va_arg(param, unsigned long);
      if(uarg <= UINT32_MAX)
        multi->maxconnects = (uint32_t)uarg;
      break;
    case CURLMOPT_MAX_HOST_CONNECTIONS:
      if(!curlx_sltouz(va_arg(param, long), &szarg))
        mresult = CURLM_BAD_FUNCTION_ARGUMENT;
      multi->max_host_connections = (szarg < UINT32_MAX) ?
                                    (uint32_t)szarg : UINT32_MAX;
      break;
    case CURLMOPT_MAX_TOTAL_CONNECTIONS:
      if(!curlx_sltouz(va_arg(param, long), &szarg))
        mresult = CURLM_BAD_FUNCTION_ARGUMENT;
      multi->max_total_connections = (szarg < UINT32_MAX) ?
                                     (uint32_t)szarg : UINT32_MAX;
      break;
      /* options formerly used for pipelining */
    case CURLMOPT_MAX_PIPELINE_LENGTH:
      break;
    case CURLMOPT_CONTENT_LENGTH_PENALTY_SIZE:
      break;
    case CURLMOPT_CHUNK_LENGTH_PENALTY_SIZE:
      break;
    case CURLMOPT_PIPELINING_SITE_BL:
      break;
    case CURLMOPT_PIPELINING_SERVER_BL:
      break;
    case CURLMOPT_MAX_CONCURRENT_STREAMS: {
      if(!curlx_sltouz(va_arg(param, long), &szarg) ||
         !szarg || (szarg > (size_t)INT_MAX)) /* preserve previous cutoff */
        multi->max_concurrent_streams = 100;
      else
        multi->max_concurrent_streams = (szarg < UINT32_MAX) ?
                                       (uint32_t)szarg : UINT32_MAX;
      break;
    }
    case CURLMOPT_NETWORK_CHANGED: {
      long val = va_arg(param, long);
      if(val & CURLMNWC_CLEAR_ALL)
        /* In the beginning, all values available to set were 1 by mistake. We
           converted this to mean "all", thus setting all the bits
           automatically */
        val = CURLMNWC_CLEAR_DNS | CURLMNWC_CLEAR_CONNS;
      if(val & CURLMNWC_CLEAR_DNS) {
        Curl_dnscache_clear(multi->admin);
      }
      if(val & CURLMNWC_CLEAR_CONNS) {
        Curl_cpool_nw_changed(&multi->cpool, multi->admin);
      }
      break;
    }
    case CURLMOPT_NOTIFYFUNCTION:
      multi->ntfy.ntfy_cb = va_arg(param, curl_notify_callback);
      break;
    case CURLMOPT_NOTIFYDATA:
      multi->ntfy.ntfy_cb_data = va_arg(param, void *);
      break;
    case CURLMOPT_RESOLVE_THREADS_MAX:
#ifdef USE_RESOLV_THREADED
      uarg = va_arg(param, long);
      if((uarg <= 0) || (uarg > UINT32_MAX))
        mresult = CURLM_BAD_FUNCTION_ARGUMENT;
      else {
        CURLcode result = Curl_async_thrdd_multi_set_props(
          multi, 0, (uint32_t)uarg, 2000);
        switch(result) {
        case CURLE_OK:
          mresult = CURLM_OK;
          break;
        case CURLE_BAD_FUNCTION_ARGUMENT:
          mresult = CURLM_BAD_FUNCTION_ARGUMENT;
          break;
        case CURLE_OUT_OF_MEMORY:
          mresult = CURLM_OUT_OF_MEMORY;
          break;
        default:
          mresult = CURLM_INTERNAL_ERROR;
          break;
        }
      }
#endif
      break;
    case CURLMOPT_QUICK_EXIT:
      multi->quick_exit = va_arg(param, long) ? 1 : 0;
      break;
    default:
      mresult = CURLM_UNKNOWN_OPTION;
      break;
    }
    va_end(param);
  }
  CURL_MAPI_LEAVE(&guard);
  return mresult;
}

/* we define curl_multi_socket() in the public multi.h header */
#undef curl_multi_socket

CURLMcode curl_multi_socket(CURLM *m, curl_socket_t s, int *running_handles)
{
  struct Curl_mapi_guard guard;
  CURLMcode mresult;

  if(CURL_MAPI_ENTER(&guard, m, multi_socket, &mresult)) {
    mresult = multi_socket(m, FALSE, s, 0, running_handles);
  }
  CURL_MAPI_LEAVE(&guard);
  return mresult;
}

CURLMcode curl_multi_socket_action(CURLM *m, curl_socket_t s,
                                   int ev_bitmask, int *running_handles)
{
  struct Curl_mapi_guard guard;
  CURLMcode mresult;

  if(CURL_MAPI_ENTER(&guard, m, multi_socket_action, &mresult)) {
    mresult = multi_socket(m, FALSE, s, ev_bitmask, running_handles);
  }
  CURL_MAPI_LEAVE(&guard);
  return mresult;
}

CURLMcode curl_multi_socket_all(CURLM *m, int *running_handles)
{
  struct Curl_mapi_guard guard;
  CURLMcode mresult;

  if(CURL_MAPI_ENTER(&guard, m, multi_socket_all, &mresult)) {
    mresult = multi_socket(m, TRUE, CURL_SOCKET_BAD, 0, running_handles);
  }
  CURL_MAPI_LEAVE(&guard);
  return mresult;
}

static bool multi_has_dirties(struct Curl_multi *multi)
{
  uint32_t mid;
  if(Curl_uint32_bset_first(&multi->dirty, &mid)) {
    do {
      struct Curl_easy *data = Curl_multi_get_easy(multi, mid);
      if(data) {
        if(Curl_uint32_bset_contains(&multi->process, mid))
          return TRUE;
        /* We are no longer processing this transfer */
        Curl_uint32_bset_remove(&multi->dirty, mid);
      }
      else {
        CURL_TRC_M(multi->admin, "dirty transfer %u no longer found", mid);
        Curl_uint32_bset_remove(&multi->dirty, mid);
      }
    } while(Curl_uint32_bset_next(&multi->dirty, mid, &mid));
  }
  return FALSE;
}

static void multi_timeout(struct Curl_multi *multi,
                          timediff_t *pexire_offset_us,
                          int *timeout_ms)
{
  if(multi->dead) {
    if(pexire_offset_us)
      *pexire_offset_us = 0;
    *timeout_ms = 0;
    return;
  }

  if(multi_has_dirties(multi)) {
    if(pexire_offset_us) {
      struct curltime now;
      curlx_pnow(&now);
      *pexire_offset_us = Curl_timeouts_offset_us(&multi->timeouts, &now);
    }
    *timeout_ms = 0;
    return;
  }
  else {
    struct curltime now;
    uint32_t mid;

    curlx_pnow(&now);
    *timeout_ms = Curl_timeouts_next_ms(&multi->timeouts, &now,
                                        pexire_offset_us, &mid);
#ifdef CURLVERBOSE
    if(mid != UINT32_MAX) {
      struct Curl_easy *data = Curl_multi_get_easy(multi, mid);
      if(data && CURL_TRC_TIMER_is_verbose(data) &&
         (data->state.timeouts.first < EXPIRE_LAST)) {
        CURL_TRC_TIMER(data, data->state.timeouts.first,
                       "gives multi timeout in %dms", *timeout_ms);
      }
    }
#endif
  }
}

CURLMcode curl_multi_timeout(CURLM *m,
                             long *timeout_ms)
{
  struct Curl_mapi_guard guard;
  CURLMcode mresult;

  if(CURL_MAPI_ENTER(&guard, m, multi_timeout, &mresult)) {
    int itimeout_ms;

    multi_timeout(m, NULL, &itimeout_ms);
    *timeout_ms = (long)itimeout_ms;
    mresult = CURLM_OK;
  }
  CURL_MAPI_LEAVE(&guard);
  return mresult;
}

/*
 * Tell the application it should update its timers, if it subscribes to the
 * update timer callback.
 */
CURLMcode Curl_update_timer(struct Curl_multi *multi)
{
  timediff_t timeouts_offset_us = 0;
  int timeout_ms;
  int rc;
  bool set_value = FALSE;

  if(!multi->timer_cb || multi->dead)
    return CURLM_OK;
  multi_timeout(multi, &timeouts_offset_us, &timeout_ms);

  if(timeout_ms < 0 && !multi->last_timeout_set) {
    /* nothing to do */
  }
  else if(timeout_ms < 0) {
    /* there is no timeout now but there was one previously */
    CURL_TRC_M(multi->admin, "[TIMER] clear");
    timeout_ms = -1; /* normalize */
    set_value = TRUE;
  }
  else if(!multi->last_timeout_set) {
    CURL_TRC_M(multi->admin, "[TIMER] set %dms, none before", timeout_ms);
    set_value = TRUE;
  }
  else if(multi->last_expire_offset_us != timeouts_offset_us) {
    /* We had a timeout before and have one now, the absolute timestamp
     * differs. The relative timeout_ms may be the same, but the starting
     * point differs. Let the application restart its timer. */
    CURL_TRC_M(multi->admin, "[TIMER] set %dms, replace previous",
               timeout_ms);
    set_value = TRUE;
  }
  else {
    /* We have same expire time as previously. Our relative 'timeout_ms'
     * may be different now, but the application has the timer running
     * and we do not to tell it to start this again. */
  }

  if(set_value) {
    struct Curl_mapi_guard guard;

    multi->last_expire_offset_us = timeouts_offset_us;
    multi->last_timeout_set = timeout_ms >= 0;
    CURL_CBAPI_MULTI_START(&guard, multi, multi_timer_cb);
    rc = multi->timer_cb(multi, timeout_ms, multi->timer_userp);
    CURL_CBAPI_MULTI_END(&guard);
    if(rc == -1) {
      multi->dead = TRUE;
      return CURLM_ABORTED_BY_CALLBACK;
    }
  }
  return CURLM_OK;
}

#ifdef DEBUGBUILD
static bool multi_timeouts_check(struct Curl_easy *data)
{
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
  return TRUE;
}
#endif

/*
 * Remove a given timestamp from the list of timeouts.
 */
static void multi_clear_timeout(struct Curl_easy *data, expire_id eid)
{
  struct expire_timers *timeouts = &data->state.timeouts;
  uint8_t orig_first = timeouts->first;
  uint8_t *anchor = &timeouts->first;
  uint8_t id = (uint8_t)eid;

  if((unsigned)eid >= EXPIRE_LAST) {
    DEBUGASSERT(0);
    return;
  }

  while(*anchor < EXPIRE_LAST) {
    if(*anchor == id) {
      *anchor = timeouts->next[id];
      break;
    }
    anchor = &timeouts->next[*anchor];
  }
  DEBUGASSERT(multi_timeouts_check(data));
  if(Curl_timeouts_has(data)) {
    struct Curl_multi *multi = data->multi;

    if(!multi) {
      DEBUGASSERT(0);
      return;
    }
    if((timeouts->first >= EXPIRE_LAST) || /* no more timeouts */
       (timeouts->first != orig_first)) {  /* active timeout changed */
      Curl_timeouts_remove(&multi->timeouts, data);
    }
    if((timeouts->first < EXPIRE_LAST) && !Curl_timeouts_has(data)) {
      Curl_timeouts_add(&multi->timeouts, data,
                        timeouts->offset_us[timeouts->first]);
    }
  }
}

/*
 * Add a timestamp to the list of timeouts. Keep the list sorted so that head
 * of list is always the timeout nearest in time.
 */
static CURLMcode multi_set_timeout(struct Curl_easy *data,
                                   const struct curltime *stamp,
                                   expire_id eid)
{
  struct expire_timers *timeouts = &data->state.timeouts;
  uint8_t *anchor = &timeouts->first;
  uint8_t id = (uint8_t)eid;

  if((unsigned)eid >= EXPIRE_LAST) {
    DEBUGASSERT(0);
    return CURLM_BAD_FUNCTION_ARGUMENT;
  }
  /* remove from list, store time and re-insert */
  multi_clear_timeout(data, eid);
  timeouts->offset_us[id] =
    Curl_timeouts_offset_us(&data->multi->timeouts, stamp);

  while(*anchor < EXPIRE_LAST) {
    if(timeouts->offset_us[*anchor] > timeouts->offset_us[id])
      break;
    anchor = &timeouts->next[*anchor];
  }
  timeouts->next[eid] = *anchor;
  timeouts->next[eid] = *anchor;
  *anchor = id;
  DEBUGASSERT(multi_timeouts_check(data));
  CURL_TRC_TIMER(data, eid, "set for %" FMT_TIMEDIFF_T "us",
                 curlx_ptimediff_us(stamp, Curl_pgrs_now(data)));
  return CURLM_OK;
}

/*
 * given a number of milliseconds from now to use to set the 'act before
 * this'-time for the transfer, to be extracted by curl_multi_timeout()
 *
 * The timeout will be added to a queue of timeouts if it defines a moment in
 * time that is later than the current head of queue.
 *
 * Expire replaces a former timeout using the same id if already set.
 */
void Curl_expire_set(struct Curl_easy *data,
                     expire_id eid, timediff_t ms,
                     const struct curltime *pnow)
{
  struct Curl_multi *multi = data->multi;
  struct expire_timers *timeouts = &data->state.timeouts;
  uint8_t prev_id = timeouts->first;
  struct curltime set;

  /* this is only interesting while there is still an associated multi struct
     remaining! */
  if(!multi)
    return;
  DEBUGASSERT(eid < EXPIRE_LAST);
  if(ms > INT_MAX)
    /* Cap ridiculous timeouts, 31-bit ms is still 3.5 weeks. When the time
       goes to the user, it must fit in this size. */
    ms = INT_MAX;

  set = *pnow;
  set.tv_sec += (time_t)(ms / 1000); /* may be a 64 to 32-bit conversion */
  set.tv_usec += (int)(ms % 1000) * 1000;
  if(set.tv_usec >= 1000000) {
    set.tv_sec++;
    set.tv_usec -= 1000000;
  }

  /* Add the timeout, will replace any previous value for this timer. */
  multi_set_timeout(data, &set, eid);
  DEBUGASSERT(timeouts->first < EXPIRE_LAST);

  if(Curl_timeouts_has(data)) {
    /* data has already a timeout registered. If the first timer
     * was NOT the one we just set AND is still the first one,
     * nothing changed from the timeouts point of view. The
     * set timer triggers after the one already registered. Leave. */
    if((prev_id != eid) && (prev_id == timeouts->first))
      return;

    /* Since this is an updated time, we must remove data from
     * timeouts and then add it again. */
    Curl_timeouts_remove(&multi->timeouts, data);
  }

  /* Insert the new timer expiry since it is our local minimum. */
  Curl_timeouts_add(&multi->timeouts, data,
                    timeouts->offset_us[timeouts->first]);
}

void Curl_expire(struct Curl_easy *data,
                 timediff_t milli, expire_id eid)
{
  Curl_expire_set(data, eid, milli, Curl_pgrs_now(data));
}

/*
 * Removes the expire timer. Marks it as done.
 */
void Curl_expire_clear(struct Curl_easy *data, expire_id eid)
{
  /* remove the timer, if there */
  multi_clear_timeout(data, eid);
  CURL_TRC_TIMER(data, eid, "cleared");
}

/*
 * Clear ALL timeout values for this handle.
 */
void Curl_expire_clear_all(struct Curl_easy *data)
{
  struct Curl_multi *multi = data->multi;

  /* this is only interesting while there is still an associated multi struct
     remaining! */
  if(!multi)
    return;

  if(Curl_timeouts_remove(&multi->timeouts, data)) {
    /* Since this is an cleared time, we must remove the previous entry from
       the splay tree */
    multi_timeouts_init(data);

    if(data->id >= 0)
      CURL_TRC_M(data, "[TIMEOUT] all cleared");
  }
}

CURLMcode curl_multi_assign(CURLM *m, curl_socket_t sockfd,
                            void *sockp)
{
  struct Curl_mapi_guard guard;
  CURLMcode mresult;

  if(CURL_MAPI_ENTER(&guard, m, multi_assign, &mresult)) {
    mresult = Curl_multi_ev_assign(m, sockfd, sockp);
  }
  CURL_MAPI_LEAVE(&guard);
  return mresult;
}

static void move_pending_to_connect(struct Curl_multi *multi,
                                    struct Curl_easy *data)
{
  DEBUGASSERT(data->mstate == MSTATE_PENDING);

  /* Remove this node from the pending set, add into process set */
  Curl_uint32_bset_remove(&multi->pending, data->mid);
  Curl_uint32_bset_add(&multi->process, data->mid);

  multistate(data, MSTATE_CONNECT);
  Curl_multi_mark_dirty(data); /* make it run */
}

/* multi_schedule_pending() moves a handle from PENDING back into the process
   list and change state to CONNECT.

   We do not move all transfers because that can be a significant amount.
   Since this is tried every now and then doing too many too often becomes a
   performance problem.

   When there is a change for connection limits like max host connections etc,
   this likely only allows one new transfer. When there is a pipewait change,
   it can potentially allow hundreds of new transfers.

   We could consider an improvement where we store the queue reason and allow
   more pipewait rechecks than others. */
static void multi_schedule_pending(struct Curl_multi *multi)
{
  uint32_t mid = multi->last_pending_mid;

  if(mid) {
    while(Curl_uint32_bset_next(&multi->pending, mid, &mid)) {
      struct Curl_easy *data = Curl_multi_get_easy(multi, mid);
      if(data) {
        move_pending_to_connect(multi, data);
        multi->last_pending_mid = mid;
        return;
      }
      /* transfer no longer known, should not happen */
      Curl_uint32_bset_remove(&multi->pending, mid);
      DEBUGASSERT(0);
    }
    /* found no pending transfers with `mid` larger than `last_pending_mid`.
     * Start at the beginning of the pending set again. */
    multi->last_pending_mid = 0;
  }

  if(Curl_uint32_bset_first(&multi->pending, &mid)) {
    do {
      struct Curl_easy *data = Curl_multi_get_easy(multi, mid);
      if(data) {
        move_pending_to_connect(multi, data);
        multi->last_pending_mid = mid;
        return;
      }
      /* transfer no longer known, should not happen */
      Curl_uint32_bset_remove(&multi->pending, mid);
      DEBUGASSERT(0);
    } while(Curl_uint32_bset_next(&multi->pending, mid, &mid));
  }
}

uint32_t Curl_multi_max_concurrent_streams(struct Curl_multi *multi)
{
  DEBUGASSERT(multi);
  return multi->max_concurrent_streams;
}

CURL **curl_multi_get_handles(CURLM *m)
{
  struct Curl_mapi_guard guard;
  CURL **a = NULL;

  if(CURL_MAPI_ENTER(&guard, m, multi_get_handles, NULL)) {
    struct Curl_multi *multi = m;
    void *entry;
    size_t count = Curl_uint32_tbl_count(&multi->xfers);

    a = curlx_malloc(sizeof(struct Curl_easy *) * (count + 1));
    if(a) {
      unsigned int i = 0;
      uint32_t mid;

      if(Curl_uint32_tbl_first(&multi->xfers, &mid, &entry)) {
        do {
          struct Curl_easy *data = entry;
          DEBUGASSERT(i < count);
          if(!data->state.internal)
            a[i++] = data;
        } while(Curl_uint32_tbl_next(&multi->xfers, mid, &mid, &entry));
      }
      a[i] = NULL; /* last entry is a NULL */
    }
  }
  CURL_MAPI_LEAVE(&guard);
  return a;
}

CURLMcode curl_multi_get_offt(CURLM *m,
                              CURLMinfo_offt info,
                              curl_off_t *pvalue)
{
  struct Curl_mapi_guard guard;
  CURLMcode mresult = CURLM_OK;

  if(CURL_MAPI_ENTER(&guard, m, multi_get_offt, &mresult)) {
    struct Curl_multi *multi = m;
    uint32_t n;

    if(!pvalue) {
      mresult = CURLM_BAD_FUNCTION_ARGUMENT;
      goto out;
    }

    switch(info) {
    case CURLMINFO_XFERS_CURRENT:
      n = Curl_uint32_tbl_count(&multi->xfers);
      if(n && multi->admin)
        --n;
      *pvalue = (curl_off_t)n;
      break;
    case CURLMINFO_XFERS_RUNNING:
      n = Curl_uint32_bset_count(&multi->process);
      if(n && Curl_uint32_bset_contains(&multi->process, multi->admin->mid))
        --n;
      *pvalue = (curl_off_t)n;
      break;
    case CURLMINFO_XFERS_PENDING:
      *pvalue = (curl_off_t)Curl_uint32_bset_count(&multi->pending);
      break;
    case CURLMINFO_XFERS_DONE:
      *pvalue = (curl_off_t)Curl_uint32_bset_count(&multi->msgsent);
      break;
    case CURLMINFO_XFERS_ADDED:
      *pvalue = multi->xfers_total_ever;
      break;
    default:
      *pvalue = -1;
      mresult = CURLM_UNKNOWN_OPTION;
      break;
    }
  }
out:
  CURL_MAPI_LEAVE(&guard);
  return mresult;
}

static struct Curl_fixed_buf *fixed_buf_create(size_t len)
{
  struct Curl_fixed_buf *fbuf;
  if((SIZE_MAX - sizeof(*fbuf)) < len)
    return NULL; /* too large */
  fbuf = curlx_malloc(len + sizeof(*fbuf));
  if(fbuf)
    fbuf->len = len;
  return fbuf;
}

CURLcode Curl_multi_xfer_buf_borrow(struct Curl_easy *data,
                                    char **pbuf, size_t *pbuflen)
{
  DEBUGASSERT(data);
  DEBUGASSERT(data->multi);
  *pbuf = NULL;
  *pbuflen = 0;
  if(!data->multi) {
    failf(data, "transfer has no multi handle");
    return CURLE_FAILED_INIT;
  }
  if(!data->set.buffer_size) {
    failf(data, "transfer buffer size is 0");
    return CURLE_FAILED_INIT;
  }
  if(data->multi->xfer_buf_borrowed) {
    failf(data, "attempt to borrow xfer_buf when already borrowed");
    return CURLE_AGAIN;
  }

  if(data->multi->xfer_buf &&
     data->set.buffer_size > data->multi->xfer_buf->len) {
    /* not large enough, get a new one */
    curlx_safefree(data->multi->xfer_buf);
  }

  if(!data->multi->xfer_buf) {
    data->multi->xfer_buf =
      fixed_buf_create(curlx_uitouz(data->set.buffer_size));
    if(!data->multi->xfer_buf) {
      failf(data, "could not allocate xfer_buf of %u bytes",
            data->set.buffer_size);
      return CURLE_OUT_OF_MEMORY;
    }
  }

  data->multi->xfer_buf_borrowed = TRUE;
  *pbuf = data->multi->xfer_buf->data;
  *pbuflen = data->multi->xfer_buf->len;
  return CURLE_OK;
}

void Curl_multi_xfer_buf_release(struct Curl_easy *data, char *buf)
{
  (void)buf;
  DEBUGASSERT(data);
  DEBUGASSERT(data->multi);
  DEBUGASSERT(!buf || (data->multi->xfer_buf &&
                       data->multi->xfer_buf->data == buf));
  data->multi->xfer_buf_borrowed = FALSE;
}

CURLcode Curl_multi_xfer_ulbuf_borrow(struct Curl_easy *data,
                                      char **pbuf, size_t *pbuflen)
{
  DEBUGASSERT(data);
  DEBUGASSERT(data->multi);
  *pbuf = NULL;
  *pbuflen = 0;
  if(!data->multi) {
    failf(data, "transfer has no multi handle");
    return CURLE_FAILED_INIT;
  }
  if(data->multi->xfer_ulbuf_borrowed) {
    failf(data, "attempt to borrow xfer_ulbuf when already borrowed");
    return CURLE_AGAIN;
  }

  if(data->multi->xfer_ulbuf &&
     data->set.upload_buffer_size > data->multi->xfer_ulbuf->len) {
    /* not large enough, get a new one */
    curlx_safefree(data->multi->xfer_ulbuf);
  }

  if(!data->multi->xfer_ulbuf) {
    data->multi->xfer_ulbuf =
      fixed_buf_create(curlx_uitouz(data->set.upload_buffer_size));
    if(!data->multi->xfer_ulbuf) {
      failf(data, "could not allocate xfer_ulbuf of %u bytes",
            data->set.upload_buffer_size);
      return CURLE_OUT_OF_MEMORY;
    }
  }

  data->multi->xfer_ulbuf_borrowed = TRUE;
  *pbuf = data->multi->xfer_ulbuf->data;
  *pbuflen = data->multi->xfer_ulbuf->len;
  return CURLE_OK;
}

void Curl_multi_xfer_ulbuf_release(struct Curl_easy *data, char *buf)
{
  (void)buf;
  DEBUGASSERT(data);
  DEBUGASSERT(data->multi);
  DEBUGASSERT(!buf || (data->multi->xfer_ulbuf &&
                       data->multi->xfer_ulbuf->data == buf));
  data->multi->xfer_ulbuf_borrowed = FALSE;
}

CURLcode Curl_multi_xfer_sockbuf_borrow(struct Curl_easy *data,
                                        size_t blen, char **pbuf)
{
  DEBUGASSERT(data);
  *pbuf = NULL;
  if(!data->multi) {
    /* When a SHARE gets destroyed and has a connection pool, we get
     * call with share->admin which does not have a multi handle. */
    *pbuf = curlx_malloc(blen);
    return *pbuf ? CURLE_OK : CURLE_OUT_OF_MEMORY;
  }
  if(data->multi->xfer_sockbuf_borrowed) {
    failf(data, "attempt to borrow xfer_sockbuf when already borrowed");
    return CURLE_AGAIN;
  }

  if(data->multi->xfer_sockbuf && blen > data->multi->xfer_sockbuf->len) {
    /* not large enough, get a new one */
    curlx_safefree(data->multi->xfer_sockbuf);
  }

  if(!data->multi->xfer_sockbuf) {
    data->multi->xfer_sockbuf = fixed_buf_create(blen);
    if(!data->multi->xfer_sockbuf) {
      failf(data, "could not allocate xfer_sockbuf of %zu bytes", blen);
      return CURLE_OUT_OF_MEMORY;
    }
  }

  data->multi->xfer_sockbuf_borrowed = TRUE;
  *pbuf = data->multi->xfer_sockbuf->data;
  return CURLE_OK;
}

void Curl_multi_xfer_sockbuf_release(struct Curl_easy *data, char *buf)
{
  DEBUGASSERT(data);
  if(!data->multi) {
    /* When a SHARE gets destroyed and has a connection pool, we get
     * call with share->admin which does not have a multi handle. */
    curlx_free(buf);
  }
  else {
    DEBUGASSERT(!buf || (data->multi->xfer_sockbuf &&
                         data->multi->xfer_sockbuf->data == buf));
    data->multi->xfer_sockbuf_borrowed = FALSE;
  }
}

static void multi_xfer_bufs_free(struct Curl_multi *multi)
{
  DEBUGASSERT(multi);
  curlx_safefree(multi->xfer_buf);
  multi->xfer_buf_borrowed = FALSE;
  curlx_safefree(multi->xfer_ulbuf);
  multi->xfer_ulbuf_borrowed = FALSE;
  curlx_safefree(multi->xfer_sockbuf);
  multi->xfer_sockbuf_borrowed = FALSE;
}

struct Curl_easy *Curl_multi_get_easy(struct Curl_multi *multi,
                                      uint32_t mid)
{
  struct Curl_easy *data = Curl_uint32_tbl_get(&multi->xfers, mid);
  if(GOOD_EASY_HANDLE(data))
    return data;
  CURL_TRC_M(multi->admin, "invalid easy handle in xfer table for mid=%u",
             mid);
  Curl_uint32_tbl_remove(&multi->xfers, mid);
  return NULL;
}

bool Curl_multi_knows_easy(struct Curl_multi *multi, struct Curl_easy *data)
{
  return Curl_uint32_tbl_get(&multi->xfers, data->mid) == data;
}

static uint32_t multi_xfers_running(struct Curl_multi *multi)
{
  if(!multi) {
    DEBUGASSERT(0);
    return 0;
  }
  return multi->xfers_alive;
}

uint32_t Curl_multi_xfers_attached(struct Curl_multi *multi)
{
  if(!multi || !multi->admin) {
    DEBUGASSERT(0);
    return 0;
  }
  /* Discount the admin handle */
  return Curl_uint32_tbl_count(&multi->xfers) - 1;
}

void Curl_multi_mark_dirty(struct Curl_easy *data)
{
  if(data->multi && data->mid != UINT32_MAX)
    Curl_uint32_bset_add(&data->multi->dirty, data->mid);
}

void Curl_multi_clear_dirty(struct Curl_easy *data)
{
  if(data->multi && data->mid != UINT32_MAX)
    Curl_uint32_bset_remove(&data->multi->dirty, data->mid);
}

CURLMcode curl_multi_notify_enable(CURLM *m, unsigned int notification)
{
  struct Curl_mapi_guard guard;
  CURLMcode mresult = CURLM_OK;

  if(CURL_MAPI_ENTER(&guard, m, multi_notify_enable, &mresult)) {
    mresult = Curl_mntfy_enable(m, notification);
  }
  CURL_MAPI_LEAVE(&guard);
  return mresult;
}

CURLMcode curl_multi_notify_disable(CURLM *m, unsigned int notification)
{
  struct Curl_mapi_guard guard;
  CURLMcode mresult = CURLM_OK;

  if(CURL_MAPI_ENTER(&guard, m, multi_notify_disable, &mresult)) {
    mresult = Curl_mntfy_disable(m, notification);
  }
  CURL_MAPI_LEAVE(&guard);
  return mresult;
}

#ifdef DEBUGBUILD
static void multi_xfer_dump(struct Curl_multi *multi, uint32_t mid,
                            void *entry)
{
  struct Curl_easy *data = entry;

  (void)multi;
  if(!data) {
    curl_mfprintf(stderr, "mid=%u, entry=NULL, bug in xfer table?\n", mid);
  }
  else {
    curl_mfprintf(stderr, "mid=%u, magic=%s, p=%p, id=%" FMT_OFF_T
                  ", url=%s\n",
                  mid,
                  (data->magic == CURLEASY_MAGIC_NUMBER) ? "GOOD" : "BAD!",
                  (void *)data, data->id, Curl_bufref_ptr(&data->state.url));
  }
}

static void multi_xfer_tbl_dump(struct Curl_multi *multi)
{
  uint32_t mid;
  void *entry;
  curl_mfprintf(stderr, "=== multi xfer table (count=%u, capacity=%u\n",
                Curl_uint32_tbl_count(&multi->xfers),
                Curl_uint32_tbl_capacity(&multi->xfers));
  if(Curl_uint32_tbl_first(&multi->xfers, &mid, &entry)) {
    multi_xfer_dump(multi, mid, entry);
    while(Curl_uint32_tbl_next(&multi->xfers, mid, &mid, &entry))
      multi_xfer_dump(multi, mid, entry);
  }
  curl_mfprintf(stderr, "===\n");
  fflush(stderr);
}
#endif /* DEBUGBUILD */

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
  const char *url;
  const char *customrequest;
  const char *referer;
  const char *ftp_entrypath;
  const char *most_recent_ftp_entrypath;
  int64_t spent_us;
  int64_t ns_us;
  int64_t connect_us;
  int64_t appconnect_us;
  int64_t pretransfer_us;
  int64_t posttransfer_us;
  int64_t starttransfer_us;
  int64_t redirect_us;
  int64_t queue_us;
  int64_t earlydata_sent;
  int64_t ul_cur_size;
  int64_t dl_cur_size;
  int64_t dl_speed;
  int64_t ul_speed;
  int64_t dl_total_size;
  int64_t ul_total_size;
  long rtsp_client_cseq;
  long rtsp_server_cseq;
  long rtsp_cseq_recv;
  uint32_t redirects;
  unsigned char httpreq;
  unsigned char path_as_is;
  unsigned char prefer_ascii;
  unsigned char timecond;
  unsigned char used_proxy;
  unsigned char dl_size_known;
  unsigned char ul_size_known;
  unsigned char _pad;
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
  ctx.url = Curl_bufref_ptr(&data->state.url);
  ctx.customrequest = CURL_EASY_STR(data, STRING_CUSTOMREQUEST);
  ctx.referer = Curl_bufref_ptr(&data->state.referer);
  ctx.ftp_entrypath = NULL;
  ctx.most_recent_ftp_entrypath = data->state.most_recent_ftp_entrypath;
  ctx.spent_us = data->progress.total.spent_us;
  ctx.ns_us = data->progress.total.nslookup_us;
  ctx.connect_us = data->progress.total.connect_us;
  ctx.appconnect_us = data->progress.total.appconnect_us;
  ctx.pretransfer_us = data->progress.total.pretransfer_us;
  ctx.posttransfer_us = data->progress.total.posttransfer_us;
  ctx.starttransfer_us = data->progress.total.starttransfer_us;
  ctx.redirect_us = data->progress.delta.startredirect_us;
  ctx.queue_us = data->progress.total.queued_us;
  ctx.earlydata_sent = data->progress.earlydata_sent;
  ctx.ul_cur_size = data->progress.ul.cur_size;
  ctx.dl_cur_size = data->progress.dl.cur_size;
  ctx.dl_speed = data->progress.dl.speed;
  ctx.ul_speed = data->progress.ul.speed;
  ctx.dl_total_size = data->progress.dl.total_size;
  ctx.ul_total_size = data->progress.ul.total_size;
#ifndef CURL_DISABLE_RTSP
  ctx.rtsp_client_cseq = data->state.rtsp_next_client_CSeq;
  ctx.rtsp_server_cseq = data->state.rtsp_next_server_CSeq;
  ctx.rtsp_cseq_recv = data->state.rtsp_CSeq_recv;
#else
  ctx.rtsp_client_cseq = 0;
  ctx.rtsp_server_cseq = 0;
  ctx.rtsp_cseq_recv = 0;
#endif
  ctx.redirects = data->state.followlocation;
  ctx.httpreq = data->state.httpreq;
  ctx.path_as_is = data->set.path_as_is ? 1 : 0;
  ctx.prefer_ascii = data->state.prefer_ascii ? 1 : 0;
  ctx.timecond = data->info.timecond ? 1 : 0;
  ctx.used_proxy = data->info.used_proxy ? 1 : 0;
  ctx.dl_size_known = data->progress.dl_size_known ? 1 : 0;
  ctx.ul_size_known = data->progress.ul_size_known ? 1 : 0;
  ctx._pad = 0;
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
