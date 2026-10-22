const std = @import("std");
const builtin = @import("builtin");
const api_mod = @import("api_getinfo_request.zig");
const collections_mod = @import("collections.zig");
const containers_mod = @import("containers.zig");
const headers_sock_mod = @import("headers_sock.zig");
const mem_mod = @import("mem.zig");

pub const curl_socket_t = if (builtin.os.tag == .windows) usize else c_int;
pub const CURL_SOCKET_BAD: curl_socket_t = if (builtin.os.tag == .windows) ~@as(usize, 0) else -1;
pub const CURL_SOCKET_TIMEOUT: curl_socket_t = CURL_SOCKET_BAD;

pub const CURLcode = c_uint;
pub const CURLMcode = c_int;
pub const CURLMstate = c_uint;
pub const CURLMoption = c_uint;
pub const CURLMinfo_offt = c_uint;
pub const expire_id = c_uint;
pub const timediff_t = i64;
pub const curl_off_t = i64;
pub const curl_prot_t = u64;

pub const CurlEasyPrefix = api_mod.CurlEasyPrefix;
pub const CurlMultiPrefix = api_mod.CurlMultiPrefix;
pub const CurlMapiGuard = api_mod.CurlMapiGuard;
pub const CurlHash = collections_mod.Curl_hash;
pub const Uint32Bset = collections_mod.uint32_bset;
pub const Uint32Tbl = collections_mod.uint32_tbl;
pub const CurlMultiNtfy = opaque {};
pub const SplayTimeouts = api_mod.SplayTimeouts;
pub const curltime = containers_mod.curltime;
pub const EasyPollset = headers_sock_mod.EasyPollset;
pub const CurlPollfds = headers_sock_mod.CurlPollfds;
pub const CurlWaitfds = headers_sock_mod.CurlWaitfds;
pub const curl_waitfd = headers_sock_mod.CurlWaitfd;
pub const pollfd = headers_sock_mod.Pollfd;

const mem = struct {
    pub const curl_calloc_fn = mem_mod.calloc;
    pub const curl_malloc_fn = mem_mod.malloc;
    pub const curl_free_fn = mem_mod.free;
};

const collections = struct {
    pub extern fn Curl_hash_destroy(h: *CurlHash) callconv(.c) void;
};

const altsvc_mod = struct {
    pub extern fn Curl_multi_ev_init(multi: *CurlMultiPrefix, hashsize: usize) callconv(.c) void;
    pub extern fn Curl_multi_ev_cleanup(multi: *CurlMultiPrefix) callconv(.c) void;
    pub extern fn Curl_multi_ev_assign(multi: *CurlMultiPrefix, s: curl_socket_t, user_data: ?*anyopaque) callconv(.c) CURLMcode;
    pub extern fn Curl_multi_ev_assess_xfer(multi: *CurlMultiPrefix, data: *CurlEasyPrefix) callconv(.c) CURLMcode;
    pub extern fn Curl_multi_ev_assess_xfer_bset(multi: *CurlMultiPrefix, set: *Uint32Bset) callconv(.c) CURLMcode;
    pub extern fn Curl_multi_ev_dirty_xfers(multi: *CurlMultiPrefix, s: curl_socket_t) callconv(.c) void;
    pub extern fn Curl_multi_ev_socket_done(multi: *CurlMultiPrefix, data: *CurlEasyPrefix, s: curl_socket_t) callconv(.c) void;
    pub extern fn Curl_multi_ev_xfer_done(multi: *CurlMultiPrefix, data: *CurlEasyPrefix) callconv(.c) void;
};

const doh_mod = struct {
    pub extern fn Curl_zig_easy_timeouts_splaynode(data: *CurlEasyPrefix) callconv(.c) *containers_mod.Curl_tree;
};

const time_net = struct {
    pub const curltime = containers_mod.curltime;
    pub extern fn curlx_pnow(pnow: *containers_mod.curltime) callconv(.c) void;
    pub extern fn curlx_wait_ms(timeout_ms: timediff_t) callconv(.c) c_int;
};

const headers_sock = struct {
    pub extern fn Curl_pollset_init(ps: *EasyPollset) callconv(.c) void;
    pub extern fn Curl_pollset_cleanup(ps: *EasyPollset) callconv(.c) void;
    pub extern fn Curl_pollset_reset(ps: *EasyPollset) callconv(.c) void;
    pub extern fn Curl_pollset_change(
        data: *CurlEasyPrefix,
        ps: *EasyPollset,
        sock: curl_socket_t,
        add_flags: c_int,
        remove_flags: c_int,
    ) callconv(.c) CURLcode;
    pub extern fn Curl_pollset_want_recv(data: *CurlEasyPrefix, ps: *EasyPollset, sock: curl_socket_t) callconv(.c) bool;
    pub extern fn Curl_pollset_want_send(data: *CurlEasyPrefix, ps: *EasyPollset, sock: curl_socket_t) callconv(.c) bool;

    pub inline fn Curl_pollset_add_in(data: *CurlEasyPrefix, ps: *EasyPollset, sock: curl_socket_t) CURLcode {
        return Curl_pollset_change(data, ps, sock, @intCast(CURL_POLL_IN), 0);
    }
    pub inline fn Curl_pollset_add_out(data: *CurlEasyPrefix, ps: *EasyPollset, sock: curl_socket_t) CURLcode {
        return Curl_pollset_change(data, ps, sock, @intCast(CURL_POLL_OUT), 0);
    }
    pub inline fn Curl_pollset_remove_in(data: *CurlEasyPrefix, ps: *EasyPollset, sock: curl_socket_t) CURLcode {
        return Curl_pollset_change(data, ps, sock, 0, @intCast(CURL_POLL_IN));
    }
    pub inline fn Curl_pollset_remove_out(data: *CurlEasyPrefix, ps: *EasyPollset, sock: curl_socket_t) CURLcode {
        return Curl_pollset_change(data, ps, sock, 0, @intCast(CURL_POLL_OUT));
    }

    pub extern fn Curl_waitfds_init(cwfds: *CurlWaitfds, static_wfds: ?[*]curl_waitfd, n: c_uint) callconv(.c) void;
    pub extern fn Curl_waitfds_add_ps(cwfds: *CurlWaitfds, ps: *EasyPollset) callconv(.c) c_uint;
    pub extern fn Curl_pollfds_init(cpfds: *CurlPollfds, static_pfds: ?[*]pollfd, n: c_uint) callconv(.c) void;
    pub extern fn Curl_pollfds_cleanup(cpfds: *CurlPollfds) callconv(.c) void;
    pub extern fn Curl_pollfds_add_ps(cpfds: *CurlPollfds, ps: *EasyPollset) callconv(.c) CURLcode;
    pub extern fn Curl_pollfds_add_sock(cpfds: *CurlPollfds, sock: curl_socket_t, events: c_short) callconv(.c) CURLcode;
    pub extern fn Curl_poll(ufds: ?[*]pollfd, nfds: c_uint, timeout_ms: timediff_t) callconv(.c) c_int;
};

const containers = struct {
    pub extern fn Curl_mntfy_init(multi: *CurlMultiPrefix, ntfy: *CurlMultiNtfy) callconv(.c) void;
    pub extern fn Curl_mntfy_cleanup(multi: *CurlMultiPrefix, ntfy: *CurlMultiNtfy) callconv(.c) void;
    pub extern fn Curl_mntfy_enable(multi: *CurlMultiPrefix, ntfy: *CurlMultiNtfy, t: c_uint) callconv(.c) CURLMcode;
    pub extern fn Curl_mntfy_disable(multi: *CurlMultiPrefix, ntfy: *CurlMultiNtfy, t: c_uint) callconv(.c) CURLMcode;
    pub extern fn Curl_mntfy_add(data: *CurlEasyPrefix, ntfy: *CurlMultiNtfy, mid: u32, t: c_uint) callconv(.c) void;
    pub extern fn Curl_mntfy_dispatch_all(multi: *CurlMultiPrefix, ntfy: *CurlMultiNtfy, admin: ?*CurlEasyPrefix) callconv(.c) CURLMcode;

    pub extern fn Curl_uint32_bset_init(bset: *Uint32Bset) callconv(.c) void;
    pub extern fn Curl_uint32_bset_resize(bset: *Uint32Bset, nmax: u32) callconv(.c) CURLcode;
    pub extern fn Curl_uint32_bset_destroy(bset: *Uint32Bset) callconv(.c) void;
    pub extern fn Curl_uint32_bset_count(bset: *Uint32Bset) callconv(.c) u32;
    pub extern fn Curl_uint32_bset_empty(bset: *Uint32Bset) callconv(.c) bool;
    pub extern fn Curl_uint32_bset_clear(bset: *Uint32Bset) callconv(.c) void;
    pub extern fn Curl_uint32_bset_add(bset: *Uint32Bset, i: u32) callconv(.c) bool;
    pub extern fn Curl_uint32_bset_remove(bset: *Uint32Bset, i: u32) callconv(.c) void;
    pub extern fn Curl_uint32_bset_contains(bset: *Uint32Bset, i: u32) callconv(.c) bool;
    pub extern fn Curl_uint32_bset_first(bset: *Uint32Bset, pfirst: *u32) callconv(.c) bool;
    pub extern fn Curl_uint32_bset_next(bset: *Uint32Bset, last: u32, pnext: *u32) callconv(.c) bool;

    extern fn Curl_uint32_tbl_init_c(tbl: *Uint32Tbl) callconv(.c) void;
    pub inline fn Curl_uint32_tbl_init(tbl: *Uint32Tbl, dtor: ?*const anyopaque) void {
        _ = dtor;
        @extern(*const fn (*Uint32Tbl) callconv(.c) void, .{ .name = "Curl_uint32_tbl_init" })(tbl);
    }
    pub extern fn Curl_uint32_tbl_resize(tbl: *Uint32Tbl, nrows: u32) callconv(.c) CURLcode;
    pub extern fn Curl_uint32_tbl_destroy(tbl: *Uint32Tbl) callconv(.c) void;
    pub extern fn Curl_uint32_tbl_capacity(tbl: *Uint32Tbl) callconv(.c) u32;
    pub extern fn Curl_uint32_tbl_count(tbl: *Uint32Tbl) callconv(.c) u32;
    pub extern fn Curl_uint32_tbl_get(tbl: *Uint32Tbl, key: u32) callconv(.c) ?*anyopaque;
    pub extern fn Curl_uint32_tbl_add(tbl: *Uint32Tbl, entry: ?*anyopaque, pkey: *u32) callconv(.c) bool;
    pub extern fn Curl_uint32_tbl_remove(tbl: *Uint32Tbl, key: u32) callconv(.c) void;
    pub extern fn Curl_uint32_tbl_contains(tbl: *Uint32Tbl, key: u32) callconv(.c) bool;
    pub extern fn Curl_uint32_tbl_first(tbl: *Uint32Tbl, pkey: *u32, pentry: *?*anyopaque) callconv(.c) bool;
    pub extern fn Curl_uint32_tbl_next(tbl: *Uint32Tbl, last_key: u32, pkey: *u32, pentry: *?*anyopaque) callconv(.c) bool;

    pub extern fn Curl_timeouts_init(timeouts: *SplayTimeouts, ptime_base: ?*const curltime) callconv(.c) void;
    pub extern fn Curl_timeouts_offset_us(timeouts: *SplayTimeouts, pts: *const curltime) callconv(.c) timediff_t;
    pub extern fn Curl_timeouts_next_ms(timeouts: *SplayTimeouts, pnow: *const curltime, pexpire_offset: ?*timediff_t, pmid: ?*u32) callconv(.c) c_int;
    pub extern fn Curl_timeouts_remove_expired(timeouts: *SplayTimeouts, ts: *const curltime, pmid: *u32) callconv(.c) bool;
    pub extern fn Curl_timeouts_has_node(node: ?*const containers_mod.Curl_tree) callconv(.c) bool;
    pub extern fn Curl_timeouts_add_node(timeouts: *SplayTimeouts, node: *containers_mod.Curl_tree, mid: u32, offset_us: timediff_t) callconv(.c) void;
    pub extern fn Curl_timeouts_remove_node(timeouts: *SplayTimeouts, node: *containers_mod.Curl_tree) callconv(.c) bool;

    pub inline fn Curl_timeouts_has(data: *CurlEasyPrefix) bool {
        return Curl_timeouts_has_node(doh_mod.Curl_zig_easy_timeouts_splaynode(data));
    }
    pub inline fn Curl_timeouts_add(timeouts: *SplayTimeouts, data: *CurlEasyPrefix, offset_us: timediff_t) void {
        Curl_timeouts_add_node(timeouts, doh_mod.Curl_zig_easy_timeouts_splaynode(data), data.mid, offset_us);
    }
    pub inline fn Curl_timeouts_remove(timeouts: *SplayTimeouts, data: *CurlEasyPrefix) bool {
        return Curl_timeouts_remove_node(timeouts, doh_mod.Curl_zig_easy_timeouts_splaynode(data));
    }
};

pub const CURLE_OK: CURLcode = 0;
pub const CURLE_UNSUPPORTED_PROTOCOL: CURLcode = 1;
pub const CURLE_FAILED_INIT: CURLcode = 2;
pub const CURLE_URL_MALFORMAT: CURLcode = 3;
pub const CURLE_COULDNT_RESOLVE_PROXY: CURLcode = 5;
pub const CURLE_COULDNT_RESOLVE_HOST: CURLcode = 6;
pub const CURLE_COULDNT_CONNECT: CURLcode = 7;
pub const CURLE_WRITE_ERROR: CURLcode = 23;
pub const CURLE_READ_ERROR: CURLcode = 26;
pub const CURLE_OUT_OF_MEMORY: CURLcode = 27;
pub const CURLE_OPERATION_TIMEDOUT: CURLcode = 28;
pub const CURLE_ABORTED_BY_CALLBACK: CURLcode = 42;
pub const CURLE_TOO_MANY_REDIRECTS: CURLcode = 47;
pub const CURLE_SEND_ERROR: CURLcode = 55;
pub const CURLE_RECV_ERROR: CURLcode = 56;
pub const CURLE_AGAIN: CURLcode = 81;
pub const CURLE_NO_CONNECTION_AVAILABLE: CURLcode = 89;
pub const CURLE_HTTP2_STREAM: CURLcode = 92;

pub const CURLM_CALL_MULTI_PERFORM: CURLMcode = -1;
pub const CURLM_OK: CURLMcode = 0;
pub const CURLM_BAD_HANDLE: CURLMcode = 1;
pub const CURLM_BAD_EASY_HANDLE: CURLMcode = 2;
pub const CURLM_OUT_OF_MEMORY: CURLMcode = 3;
pub const CURLM_INTERNAL_ERROR: CURLMcode = 4;
pub const CURLM_BAD_SOCKET: CURLMcode = 5;
pub const CURLM_UNKNOWN_OPTION: CURLMcode = 6;
pub const CURLM_ADDED_ALREADY: CURLMcode = 7;
pub const CURLM_RECURSIVE_API_CALL: CURLMcode = 8;
pub const CURLM_WAKEUP_FAILURE: CURLMcode = 9;
pub const CURLM_BAD_FUNCTION_ARGUMENT: CURLMcode = 10;
pub const CURLM_ABORTED_BY_CALLBACK: CURLMcode = 11;
pub const CURLM_UNRECOVERABLE_POLL: CURLMcode = 12;

pub const MSTATE_INIT: CURLMstate = 0;
pub const MSTATE_PENDING: CURLMstate = 1;
pub const MSTATE_SETUP: CURLMstate = 2;
pub const MSTATE_CONNECT: CURLMstate = 3;
pub const MSTATE_CONNECTING: CURLMstate = 4;
pub const MSTATE_PROTOCONNECT: CURLMstate = 5;
pub const MSTATE_PROTOCONNECTING: CURLMstate = 6;
pub const MSTATE_DO: CURLMstate = 7;
pub const MSTATE_DOING: CURLMstate = 8;
pub const MSTATE_DOING_MORE: CURLMstate = 9;
pub const MSTATE_DID: CURLMstate = 10;
pub const MSTATE_PERFORMING: CURLMstate = 11;
pub const MSTATE_RATELIMITING: CURLMstate = 12;
pub const MSTATE_DONE: CURLMstate = 13;
pub const MSTATE_COMPLETED: CURLMstate = 14;
pub const MSTATE_MSGSENT: CURLMstate = 15;
pub const MSTATE_LAST: CURLMstate = 16;

pub const EXPIRE_100_TIMEOUT: expire_id = 0;
pub const EXPIRE_ASYNC_NAME: expire_id = 1;
pub const EXPIRE_CONNECTTIMEOUT: expire_id = 2;
pub const EXPIRE_DNS_PER_NAME: expire_id = 3;
pub const EXPIRE_DNS_PER_NAME2: expire_id = 4;
pub const EXPIRE_HAPPY_EYEBALLS: expire_id = 5;
pub const EXPIRE_HAPPY_EYEBALLS_DNS: expire_id = 6;
pub const EXPIRE_MULTI_PENDING: expire_id = 7;
pub const EXPIRE_QUIC: expire_id = 8;
pub const EXPIRE_RUN_NOW: expire_id = 9;
pub const EXPIRE_SPEEDCHECK: expire_id = 10;
pub const EXPIRE_TIMEOUT: expire_id = 11;
pub const EXPIRE_TOOFAST: expire_id = 12;
pub const EXPIRE_ALPN_EYEBALLS: expire_id = 13;
pub const EXPIRE_SHUTDOWN: expire_id = 14;
pub const EXPIRE_LAST: expire_id = 15;

pub const CURL_MULTI_HANDLE: u32 = 0x000bab1e;
pub const CURL_EASY_HANDLE: u32 = 0xc0dedbad;

pub const CURL_XFER_TABLE_SIZE: u32 = 500;
pub const CURL_CONNECTION_HASH_SIZE: usize = 97;
pub const CURL_DNS_HASH_SIZE: usize = 71;
pub const CURL_TLS_SESSION_SIZE: usize = 25;
pub const CURL_SOCKET_HASH_TABLE_SIZE: usize = 911;

pub const CURL_POLL_NONE: c_int = 0;
pub const CURL_POLL_IN: c_int = 1;
pub const CURL_POLL_OUT: c_int = 2;
pub const CURL_POLL_INOUT: c_int = 3;
pub const CURL_POLL_REMOVE: c_int = 4;

pub const CURL_WAIT_POLLIN: c_short = 0x0001;
pub const CURL_WAIT_POLLPRI: c_short = 0x0002;
pub const CURL_WAIT_POLLOUT: c_short = 0x0004;

pub const POLLIN: c_short = if (builtin.os.tag == .windows) 0x0100 else 0x0001;
pub const POLLPRI: c_short = if (builtin.os.tag == .windows) 0x0400 else 0x0002;
pub const POLLOUT: c_short = if (builtin.os.tag == .windows) 0x0010 else 0x0004;

pub const FIRSTSOCKET: c_int = 0;
pub const SECONDARYSOCKET: c_int = 1;

pub const DOMORE_INCOMPLETE: c_int = 0;
pub const DOMORE_DONE: c_int = 1;
pub const DOMORE_GOBACK: c_int = 2;

pub const FOLLOW_NONE: c_int = 0;
pub const FOLLOW_FAKE: c_int = 1;
pub const FOLLOW_RETRY: c_int = 2;
pub const FOLLOW_REDIR: c_int = 3;

pub const CPOOL_DO_KEEP: c_int = 0;
pub const CPOOL_DO_IDLE: c_int = 1;
pub const CPOOL_DO_CLOSE: c_int = 2;
pub const CPOOL_DO_TERMINATE: c_int = 3;

pub const TIMER_NONE: c_int = 0;
pub const TIMER_STARTOP: c_int = 1;
pub const TIMER_STARTSINGLE: c_int = 2;
pub const TIMER_POSTQUEUE: c_int = 3;
pub const TIMER_NAMELOOKUP: c_int = 4;
pub const TIMER_CONNECT: c_int = 5;
pub const TIMER_APPCONNECT: c_int = 6;
pub const TIMER_PRETRANSFER: c_int = 7;
pub const TIMER_STARTTRANSFER: c_int = 8;
pub const TIMER_POSTRANSFER: c_int = 9;
pub const TIMER_STARTACCEPT: c_int = 10;
pub const TIMER_REDIRECT: c_int = 10;

pub const CURLMNOTIFY_INFO_READ: c_uint = 0;
pub const CURLMNOTIFY_EASY_DONE: c_uint = 1;

pub const CURLMSG_DONE: c_uint = 1;

pub const CURL_PREREQFUNC_OK: c_int = 0;

pub const PROTOPT_DUAL: u32 = 1 << 1;
pub const PROTOPT_WILDCARD: u32 = 1 << 12;
pub const PROTOPT_CONN_REUSE: u32 = 1 << 16;
pub const PROTO_FAMILY_HTTP: curl_prot_t = (1 << 0) | (1 << 1) | (1 << 30) | (1 << 31);

pub const CURLPIPE_MULTIPLEX: c_long = 2;

pub const CURLMNWC_CLEAR_ALL: c_long = 1 << 0;
pub const CURLMNWC_CLEAR_CONNS: c_long = 1 << 1;
pub const CURLMNWC_CLEAR_DNS: c_long = 1 << 2;

pub const CURLMOPT_SOCKETFUNCTION: CURLMoption = 20001;
pub const CURLMOPT_SOCKETDATA: CURLMoption = 10002;
pub const CURLMOPT_PIPELINING: CURLMoption = 3;
pub const CURLMOPT_TIMERFUNCTION: CURLMoption = 20004;
pub const CURLMOPT_TIMERDATA: CURLMoption = 10005;
pub const CURLMOPT_MAXCONNECTS: CURLMoption = 6;
pub const CURLMOPT_MAX_HOST_CONNECTIONS: CURLMoption = 7;
pub const CURLMOPT_MAX_PIPELINE_LENGTH: CURLMoption = 8;
pub const CURLMOPT_CONTENT_LENGTH_PENALTY_SIZE: CURLMoption = 30009;
pub const CURLMOPT_CHUNK_LENGTH_PENALTY_SIZE: CURLMoption = 30010;
pub const CURLMOPT_PIPELINING_SITE_BL: CURLMoption = 10011;
pub const CURLMOPT_PIPELINING_SERVER_BL: CURLMoption = 10012;
pub const CURLMOPT_MAX_TOTAL_CONNECTIONS: CURLMoption = 13;
pub const CURLMOPT_PUSHFUNCTION: CURLMoption = 20014;
pub const CURLMOPT_PUSHDATA: CURLMoption = 10015;
pub const CURLMOPT_MAX_CONCURRENT_STREAMS: CURLMoption = 16;
pub const CURLMOPT_NETWORK_CHANGED: CURLMoption = 17;
pub const CURLMOPT_NOTIFYFUNCTION: CURLMoption = 20018;
pub const CURLMOPT_NOTIFYDATA: CURLMoption = 10019;
pub const CURLMOPT_RESOLVE_THREADS_MAX: CURLMoption = 20;
pub const CURLMOPT_QUICK_EXIT: CURLMoption = 21;

pub const CURLMINFO_XFERS_CURRENT: CURLMinfo_offt = 1;
pub const CURLMINFO_XFERS_RUNNING: CURLMinfo_offt = 2;
pub const CURLMINFO_XFERS_PENDING: CURLMinfo_offt = 3;
pub const CURLMINFO_XFERS_DONE: CURLMinfo_offt = 4;
pub const CURLMINFO_XFERS_ADDED: CURLMinfo_offt = 5;

pub const CURL_MAPI_FN_multi_add_handle: c_uint = 0;
pub const CURL_MAPI_FN_multi_assign: c_uint = 1;
pub const CURL_MAPI_FN_multi_cleanup: c_uint = 2;
pub const CURL_MAPI_FN_multi_fdset: c_uint = 3;
pub const CURL_MAPI_FN_multi_get_handles: c_uint = 4;
pub const CURL_MAPI_FN_multi_get_offt: c_uint = 5;
pub const CURL_MAPI_FN_multi_info_read: c_uint = 6;
pub const CURL_MAPI_FN_multi_notify_disable: c_uint = 7;
pub const CURL_MAPI_FN_multi_notify_enable: c_uint = 8;
pub const CURL_MAPI_FN_multi_perform: c_uint = 9;
pub const CURL_MAPI_FN_multi_poll: c_uint = 10;
pub const CURL_MAPI_FN_multi_remove_handle: c_uint = 11;
pub const CURL_MAPI_FN_multi_setopt: c_uint = 12;
pub const CURL_MAPI_FN_multi_socket_action: c_uint = 13;
pub const CURL_MAPI_FN_multi_socket_all: c_uint = 14;
pub const CURL_MAPI_FN_multi_socket: c_uint = 15;
pub const CURL_MAPI_FN_multi_timeout: c_uint = 16;
pub const CURL_MAPI_FN_multi_wait: c_uint = 17;
pub const CURL_MAPI_FN_multi_waitfds: c_uint = 18;

pub const CURL_CBAPI_FN_multi_ntfy_cb: c_uint = 150;
pub const CURL_CBAPI_FN_multi_push_cb: c_uint = 151;
pub const CURL_CBAPI_FN_multi_socket_cb: c_uint = 152;
pub const CURL_CBAPI_FN_multi_timer_cb: c_uint = 153;

pub const curl_multi_timer_callback = ?*const fn (
    ?*CurlMultiPrefix,
    c_long,
    ?*anyopaque,
) callconv(.c) c_int;

pub const curl_notify_callback = ?*const fn (
    ?*CurlMultiPrefix,
    c_uint,
    ?*CurlEasyPrefix,
    ?*anyopaque,
) callconv(.c) void;

pub const multi_sub_xfer_done_cb = ?*const fn (
    *CurlEasyPrefix,
    *CurlEasyPrefix,
    CURLcode,
) callconv(.c) void;

pub const CurlFixedBuf = extern struct {
    len: usize,
    data: [1]u8,
};

pub const CURLMsgData = extern union {
    whatever: ?*anyopaque,
    result: CURLcode,
};

pub const CURLMsg = extern struct {
    msg: c_uint,
    easy_handle: ?*CurlEasyPrefix,
    data: CURLMsgData,
};

pub const SigpipeIgnoreBuf = extern struct {
    words: [32]u64 = std.mem.zeroes([32]u64),
};

const MultiDoneCtx = extern struct {
    premature: u8 = 0,
};

// External C struct-field/bitfield accessors and subsystem entry points
extern fn Curl_zig_multi_sizeof() callconv(.c) usize;
extern fn Curl_zig_multi_ntfy(multi: *CurlMultiPrefix) callconv(.c) *CurlMultiNtfy;
extern fn Curl_zig_multi_ntfy_has_entries(multi: *const CurlMultiPrefix) callconv(.c) bool;
extern fn Curl_zig_multi_ntfy_has_cb(multi: *const CurlMultiPrefix) callconv(.c) bool;
extern fn Curl_zig_multi_set_ntfy_cb(multi: *CurlMultiPrefix, cb: curl_notify_callback) callconv(.c) void;
extern fn Curl_zig_multi_set_ntfy_cb_data(multi: *CurlMultiPrefix, userp: ?*anyopaque) callconv(.c) void;
extern fn Curl_zig_multi_proto_hash(multi: *CurlMultiPrefix) callconv(.c) *CurlHash;
extern fn Curl_zig_multi_cpool(multi: *CurlMultiPrefix) callconv(.c) *anyopaque;
extern fn Curl_zig_multi_cshutdn(multi: *CurlMultiPrefix) callconv(.c) *anyopaque;
extern fn Curl_zig_multi_proto_hash_init(multi: *CurlMultiPrefix) callconv(.c) void;
extern fn Curl_zig_multi_debug_env_init(multi: *CurlMultiPrefix) callconv(.c) void;
extern fn Curl_zig_multi_init_optional_fields(multi: *CurlMultiPrefix, sesssize: usize, xfer_table_size: u32) callconv(.c) c_int;
extern fn Curl_zig_multi_prepare_admin(multi: *CurlMultiPrefix) callconv(.c) void;
extern fn Curl_zig_multi_trc_created_admin(multi: *CurlMultiPrefix) callconv(.c) void;
extern fn Curl_zig_multi_clone_admin_timeouts(multi: *CurlMultiPrefix, data: *const CurlEasyPrefix) callconv(.c) void;
extern fn Curl_zig_multi_destroy_async_thrdd(multi: *CurlMultiPrefix, join: bool) callconv(.c) void;
extern fn Curl_zig_multi_free_optional_fields(multi: *CurlMultiPrefix) callconv(.c) void;
extern fn Curl_zig_multi_warn_debug(multi: *CurlMultiPrefix, data: *CurlEasyPrefix) callconv(.c) void;
extern fn Curl_zig_multi_assess_wakeup(multi: *CurlMultiPrefix) callconv(.c) CURLMcode;
extern fn Curl_zig_multi_pollset_internal_wakeup(data: *CurlEasyPrefix, ps: *EasyPollset) callconv(.c) CURLcode;
extern fn Curl_zig_multi_async_thrdd_process(multi: *CurlMultiPrefix) callconv(.c) void;
extern fn Curl_zig_multi_consume_internal_wakeup(multi: *CurlMultiPrefix, all: bool) callconv(.c) void;
extern fn Curl_zig_multi_consume_wakeup_pair(multi: *CurlMultiPrefix, all: bool) callconv(.c) void;
extern fn Curl_zig_multi_last_expire_offset_us(multi: *const CurlMultiPrefix) callconv(.c) timediff_t;
extern fn Curl_zig_multi_set_last_expire_offset_us(multi: *CurlMultiPrefix, val: timediff_t) callconv(.c) void;
extern fn Curl_zig_multi_last_pending_mid(multi: *const CurlMultiPrefix) callconv(.c) u32;
extern fn Curl_zig_multi_set_last_pending_mid(multi: *CurlMultiPrefix, val: u32) callconv(.c) void;
extern fn Curl_zig_multi_set_max_host_connections(multi: *CurlMultiPrefix, val: u32) callconv(.c) void;
extern fn Curl_zig_multi_set_max_total_connections(multi: *CurlMultiPrefix, val: u32) callconv(.c) void;
extern fn Curl_zig_multi_set_maxconnects(multi: *CurlMultiPrefix, val: u32) callconv(.c) void;
extern fn Curl_zig_multi_timer_cb(multi: *const CurlMultiPrefix) callconv(.c) curl_multi_timer_callback;
extern fn Curl_zig_multi_set_timer_cb(multi: *CurlMultiPrefix, cb: curl_multi_timer_callback) callconv(.c) void;
extern fn Curl_zig_multi_timer_userp(multi: *const CurlMultiPrefix) callconv(.c) ?*anyopaque;
extern fn Curl_zig_multi_set_timer_userp(multi: *CurlMultiPrefix, userp: ?*anyopaque) callconv(.c) void;
extern fn Curl_zig_multi_xfer_buf_ptr(multi: *CurlMultiPrefix) callconv(.c) *?*CurlFixedBuf;
extern fn Curl_zig_multi_xfer_ulbuf_ptr(multi: *CurlMultiPrefix) callconv(.c) *?*CurlFixedBuf;
extern fn Curl_zig_multi_xfer_sockbuf_ptr(multi: *CurlMultiPrefix) callconv(.c) *?*CurlFixedBuf;
extern fn Curl_zig_multi_multiplexing(multi: *const CurlMultiPrefix) callconv(.c) bool;
extern fn Curl_zig_multi_set_multiplexing(multi: *CurlMultiPrefix, val: bool) callconv(.c) void;
extern fn Curl_zig_multi_recheckstate(multi: *const CurlMultiPrefix) callconv(.c) bool;
extern fn Curl_zig_multi_set_recheckstate(multi: *CurlMultiPrefix, val: bool) callconv(.c) void;
extern fn Curl_zig_multi_dead(multi: *const CurlMultiPrefix) callconv(.c) bool;
extern fn Curl_zig_multi_set_dead(multi: *CurlMultiPrefix, val: bool) callconv(.c) void;
extern fn Curl_zig_multi_quick_exit(multi: *const CurlMultiPrefix) callconv(.c) bool;
extern fn Curl_zig_multi_set_quick_exit(multi: *CurlMultiPrefix, val: bool) callconv(.c) void;
extern fn Curl_zig_multi_last_timeout_set(multi: *const CurlMultiPrefix) callconv(.c) bool;
extern fn Curl_zig_multi_set_last_timeout_set(multi: *CurlMultiPrefix, val: bool) callconv(.c) void;
extern fn Curl_zig_multi_xfer_buf_borrowed(multi: *const CurlMultiPrefix) callconv(.c) bool;
extern fn Curl_zig_multi_set_xfer_buf_borrowed(multi: *CurlMultiPrefix, val: bool) callconv(.c) void;
extern fn Curl_zig_multi_xfer_ulbuf_borrowed(multi: *const CurlMultiPrefix) callconv(.c) bool;
extern fn Curl_zig_multi_set_xfer_ulbuf_borrowed(multi: *CurlMultiPrefix, val: bool) callconv(.c) void;
extern fn Curl_zig_multi_xfer_sockbuf_borrowed(multi: *const CurlMultiPrefix) callconv(.c) bool;
extern fn Curl_zig_multi_set_xfer_sockbuf_borrowed(multi: *CurlMultiPrefix, val: bool) callconv(.c) void;
extern fn Curl_zig_multi_resolve_threads_max_set(multi: *CurlMultiPrefix, val: c_long) callconv(.c) CURLMcode;
extern fn Curl_zig_multi_fdset_valid_sock(s: curl_socket_t) callconv(.c) bool;
extern fn Curl_zig_multi_fdset_add(s: curl_socket_t, action: u8, read_fd_set: ?*anyopaque, write_fd_set: ?*anyopaque) callconv(.c) void;
extern fn Curl_zig_multi_winsock_select(
    multi: *CurlMultiPrefix,
    cpfds: *CurlPollfds,
    curl_nfds: c_uint,
    extra_fds: ?[*]curl_waitfd,
    extra_nfds: c_uint,
    timeout_ms: c_int,
    extrawait: bool,
    pnevents: *c_int,
) callconv(.c) CURLMcode;
extern fn Curl_zig_multi_wakeup_pair(multi: *CurlMultiPrefix) callconv(.c) ?[*]curl_socket_t;
extern fn Curl_zig_multi_wakeup_exec(multi: *CurlMultiPrefix) callconv(.c) CURLMcode;
extern fn Curl_zig_multi_wakeup_internal_exec(multi: *CurlMultiPrefix) callconv(.c) void;
extern fn Curl_zig_multi_trc_state(data: *CurlEasyPrefix, oldstate: CURLMstate, newstate: CURLMstate) callconv(.c) void;
extern fn Curl_zig_multi_timeouts_check(data: *CurlEasyPrefix) callconv(.c) bool;

extern fn Curl_zig_easy_multi_easy(data: *const CurlEasyPrefix) callconv(.c) ?*CurlMultiPrefix;
extern fn Curl_zig_easy_set_multi_easy(data: *CurlEasyPrefix, m: ?*CurlMultiPrefix) callconv(.c) void;
extern fn Curl_zig_easy_master_mid(data: *const CurlEasyPrefix) callconv(.c) u32;
extern fn Curl_zig_easy_set_master_mid(data: *CurlEasyPrefix, mid: u32) callconv(.c) void;
extern fn Curl_zig_easy_sub_xfer_done(data: *const CurlEasyPrefix) callconv(.c) multi_sub_xfer_done_cb;
extern fn Curl_zig_easy_set_msg_done(data: *CurlEasyPrefix, result: CURLcode) callconv(.c) *CURLMsg;
extern fn Curl_zig_easy_msg_ptr(data: *CurlEasyPrefix) callconv(.c) *CURLMsg;
extern fn Curl_zig_easy_timeouts_first_ptr(data: *CurlEasyPrefix) callconv(.c) *u8;
extern fn Curl_zig_easy_timeouts_next_ptr(data: *CurlEasyPrefix) callconv(.c) [*]u8;
extern fn Curl_zig_easy_timeouts_offset_us_ptr(data: *CurlEasyPrefix) callconv(.c) [*]timediff_t;
extern fn Curl_zig_easy_state_netrc(data: *CurlEasyPrefix) callconv(.c) *anyopaque;
extern fn Curl_zig_easy_url_bufref(data: *CurlEasyPrefix) callconv(.c) *anyopaque;
extern fn Curl_zig_easy_clear_errorbuffer(data: *CurlEasyPrefix) callconv(.c) void;
extern fn Curl_zig_easy_set_timeout_ms(data: *const CurlEasyPrefix) callconv(.c) timediff_t;
extern fn Curl_zig_easy_set_connecttimeout_ms(data: *const CurlEasyPrefix) callconv(.c) timediff_t;
extern fn Curl_zig_easy_set_buffer_size(data: *const CurlEasyPrefix) callconv(.c) c_uint;
extern fn Curl_zig_easy_set_upload_buffer_size(data: *const CurlEasyPrefix) callconv(.c) c_uint;
extern fn Curl_zig_easy_set_connect_only(data: *const CurlEasyPrefix) callconv(.c) u8;
extern fn Curl_zig_easy_set_connect_only_non_ws(data: *const CurlEasyPrefix) callconv(.c) bool;
extern fn Curl_zig_easy_set_reuse_forbid(data: *const CurlEasyPrefix) callconv(.c) bool;
extern fn Curl_zig_easy_state_internal(data: *const CurlEasyPrefix) callconv(.c) bool;
extern fn Curl_zig_easy_state_really_alive(data: *const CurlEasyPrefix) callconv(.c) bool;
extern fn Curl_zig_easy_set_state_really_alive(data: *CurlEasyPrefix, val: bool) callconv(.c) void;
extern fn Curl_zig_easy_state_done(data: *const CurlEasyPrefix) callconv(.c) bool;
extern fn Curl_zig_easy_set_state_done(data: *CurlEasyPrefix, val: bool) callconv(.c) void;
extern fn Curl_zig_easy_state_wildcardmatch(data: *const CurlEasyPrefix) callconv(.c) bool;
extern fn Curl_zig_easy_set_state_os_errno(data: *CurlEasyPrefix, val: c_int) callconv(.c) void;
extern fn Curl_zig_easy_state_last_conn_id(data: *const CurlEasyPrefix) callconv(.c) curl_off_t;
extern fn Curl_zig_easy_set_state_last_conn_id(data: *CurlEasyPrefix, id: curl_off_t) callconv(.c) void;
extern fn Curl_zig_easy_set_state_last_cpid(data: *CurlEasyPrefix, cpid: c_int) callconv(.c) void;
extern fn Curl_zig_easy_req(data: *CurlEasyPrefix) callconv(.c) *anyopaque;
extern fn Curl_zig_easy_req_done(data: *const CurlEasyPrefix) callconv(.c) bool;
extern fn Curl_zig_easy_set_req_done(data: *CurlEasyPrefix, val: bool) callconv(.c) void;
extern fn Curl_zig_easy_set_req_chunk(data: *CurlEasyPrefix, val: bool) callconv(.c) void;
extern fn Curl_zig_easy_req_want_send(data: *CurlEasyPrefix) callconv(.c) bool;
extern fn Curl_zig_easy_req_want_recv(data: *CurlEasyPrefix) callconv(.c) bool;
extern fn Curl_zig_easy_req_set_recv(data: *CurlEasyPrefix) callconv(.c) void;
extern fn Curl_zig_easy_req_newurl(data: *const CurlEasyPrefix) callconv(.c) ?[*:0]u8;
extern fn Curl_zig_easy_clear_req_newurl(data: *CurlEasyPrefix) callconv(.c) void;
extern fn Curl_zig_easy_free_req_newurl(data: *CurlEasyPrefix) callconv(.c) void;
extern fn Curl_zig_easy_req_location(data: *const CurlEasyPrefix) callconv(.c) ?[*:0]u8;
extern fn Curl_zig_easy_clear_req_location(data: *CurlEasyPrefix) callconv(.c) void;
extern fn Curl_zig_easy_free_req_location(data: *CurlEasyPrefix) callconv(.c) void;
extern fn Curl_zig_easy_req_size(data: *const CurlEasyPrefix) callconv(.c) curl_off_t;
extern fn Curl_zig_easy_req_bytecount(data: *const CurlEasyPrefix) callconv(.c) curl_off_t;
extern fn Curl_zig_easy_progress_ul_rlimit(data: *CurlEasyPrefix) callconv(.c) *anyopaque;
extern fn Curl_zig_easy_progress_dl_rlimit(data: *CurlEasyPrefix) callconv(.c) *anyopaque;
extern fn Curl_zig_easy_init_psl(data: *CurlEasyPrefix, multi: *CurlMultiPrefix) callconv(.c) void;
extern fn Curl_zig_easy_clear_psl_if_multi(data: *CurlEasyPrefix, multi: *CurlMultiPrefix) callconv(.c) void;
extern fn Curl_zig_easy_call_fprereq(data: *CurlEasyPrefix, has_fprereq: *bool) callconv(.c) c_int;
extern fn Curl_zig_easy_posttransfer_restore_signal(data: *CurlEasyPrefix) callconv(.c) void;
extern fn Curl_zig_easy_h2_downgrade_check(data: *CurlEasyPrefix) callconv(.c) bool;
extern fn Curl_zig_easy_h2_downgrade_apply(data: *CurlEasyPrefix) callconv(.c) void;
extern fn Curl_zig_easy_wildcard_is_done(data: *const CurlEasyPrefix) callconv(.c) bool;
extern fn Curl_zig_easy_wildcard_is_done_or_skip(data: *const CurlEasyPrefix) callconv(.c) bool;
extern fn Curl_zig_easy_wildcard_set_done(data: *CurlEasyPrefix) callconv(.c) void;
extern fn Curl_zig_easy_wildcard_dtor(data: *CurlEasyPrefix) callconv(.c) void;

extern fn Curl_zig_conn_connection_id(conn: *const anyopaque) callconv(.c) curl_off_t;
extern fn Curl_zig_conn_cpid(conn: *const anyopaque) callconv(.c) c_int;
extern fn Curl_zig_conn_sock_at(conn: *const anyopaque, idx: c_int) callconv(.c) curl_socket_t;
extern fn Curl_zig_conn_send_idx(conn: *const anyopaque) callconv(.c) c_int;
extern fn Curl_zig_conn_recv_idx(conn: *const anyopaque) callconv(.c) c_int;
extern fn Curl_zig_conn_attached_xfers(conn: *const anyopaque) callconv(.c) u32;
extern fn Curl_zig_conn_inc_attached_xfers(conn: *anyopaque) callconv(.c) void;
extern fn Curl_zig_conn_dec_attached_xfers(conn: *anyopaque) callconv(.c) void;
extern fn Curl_zig_conn_attached_multi(conn: *const anyopaque) callconv(.c) ?*CurlMultiPrefix;
extern fn Curl_zig_conn_set_attached_multi(conn: *anyopaque, multi: ?*CurlMultiPrefix) callconv(.c) void;
extern fn Curl_zig_conn_bits_close(conn: *const anyopaque) callconv(.c) bool;
extern fn Curl_zig_conn_set_bits_close(conn: *anyopaque, val: bool) callconv(.c) void;
extern fn Curl_zig_conn_bits_reuse(conn: *const anyopaque) callconv(.c) bool;
extern fn Curl_zig_conn_bits_multiplex(conn: *const anyopaque) callconv(.c) bool;
extern fn Curl_zig_conn_bits_dns_resolved(conn: *const anyopaque) callconv(.c) bool;
extern fn Curl_zig_conn_bits_connect_only(conn: *const anyopaque) callconv(.c) bool;
extern fn Curl_zig_conn_should_close_reuse_forbid(conn: *const anyopaque) callconv(.c) bool;
extern fn Curl_zig_conn_bits_do_more(conn: *const anyopaque) callconv(.c) bool;
extern fn Curl_zig_conn_bits_protoconnstart(conn: *const anyopaque) callconv(.c) bool;
extern fn Curl_zig_conn_set_bits_protoconnstart(conn: *anyopaque, val: bool) callconv(.c) void;
extern fn Curl_zig_conn_scheme(conn: *const anyopaque) callconv(.c) ?*const anyopaque;
extern fn Curl_zig_conn_scheme_protocol(conn: *const anyopaque) callconv(.c) curl_prot_t;
extern fn Curl_zig_conn_scheme_flags(conn: *const anyopaque) callconv(.c) c_uint;
extern fn Curl_zig_conn_run_call_attach(data: *CurlEasyPrefix, conn: *anyopaque) callconv(.c) void;
extern fn Curl_zig_conn_run_has_doing(conn: *const anyopaque) callconv(.c) bool;
extern fn Curl_zig_conn_run_call_doing(data: *CurlEasyPrefix, dophase_done: *bool) callconv(.c) CURLcode;
extern fn Curl_zig_conn_run_has_do_it(conn: *const anyopaque) callconv(.c) bool;
extern fn Curl_zig_conn_run_call_do_it(data: *CurlEasyPrefix, done: *bool) callconv(.c) CURLcode;
extern fn Curl_zig_conn_run_has_do_more(conn: *const anyopaque) callconv(.c) bool;
extern fn Curl_zig_conn_run_call_do_more(data: *CurlEasyPrefix, complete: *c_int) callconv(.c) CURLcode;
extern fn Curl_zig_conn_run_has_done(conn: *const anyopaque) callconv(.c) bool;
extern fn Curl_zig_conn_run_call_done(data: *CurlEasyPrefix, status: CURLcode, premature: bool) callconv(.c) CURLcode;
extern fn Curl_zig_conn_run_has_connecting(conn: *const anyopaque) callconv(.c) bool;
extern fn Curl_zig_conn_run_call_connecting(data: *CurlEasyPrefix, done: *bool) callconv(.c) CURLcode;
extern fn Curl_zig_conn_run_has_connect_it(conn: *const anyopaque) callconv(.c) bool;
extern fn Curl_zig_conn_run_call_connect_it(data: *CurlEasyPrefix, done: *bool) callconv(.c) CURLcode;
extern fn Curl_zig_scheme_run_follow(
    data: *CurlEasyPrefix,
    handler: ?*const anyopaque,
    newurl: ?[*:0]const u8,
    ftype: c_int,
    has_follow: *bool,
) callconv(.c) CURLcode;
extern fn Curl_zig_conn_run_has_proto_pollset(conn: *const anyopaque) callconv(.c) bool;
extern fn Curl_zig_conn_run_call_proto_pollset(data: *CurlEasyPrefix, ps: *EasyPollset) callconv(.c) CURLcode;
extern fn Curl_zig_conn_run_has_doing_pollset(conn: *const anyopaque) callconv(.c) bool;
extern fn Curl_zig_conn_run_call_doing_pollset(data: *CurlEasyPrefix, ps: *EasyPollset) callconv(.c) CURLcode;
extern fn Curl_zig_conn_run_has_domore_pollset(conn: *const anyopaque) callconv(.c) bool;
extern fn Curl_zig_conn_run_call_domore_pollset(data: *CurlEasyPrefix, ps: *EasyPollset) callconv(.c) CURLcode;
extern fn Curl_zig_conn_run_has_perform_pollset(conn: *const anyopaque) callconv(.c) bool;
extern fn Curl_zig_conn_run_call_perform_pollset(data: *CurlEasyPrefix, ps: *EasyPollset) callconv(.c) CURLcode;

extern fn curl_easy_init() callconv(.c) ?*CurlEasyPrefix;
extern fn Curl_close(datap: *?*CurlEasyPrefix) callconv(.c) CURLcode;
extern fn Curl_dnscache_init(dns: *anyopaque, size: usize) callconv(.c) void;
extern fn Curl_dnscache_destroy(dns: *anyopaque) callconv(.c) void;
extern fn Curl_dnscache_clear(data: *CurlEasyPrefix) callconv(.c) void;
extern fn Curl_dnscache_prune(data: *CurlEasyPrefix, pnow: *const curltime) callconv(.c) void;
extern fn Curl_cshutdn_init(cshutdn: *anyopaque) callconv(.c) void;
extern fn Curl_cshutdn_destroy(cshutdn: *anyopaque, admin: ?*CurlEasyPrefix) callconv(.c) void;
extern fn Curl_cshutdn_perform(cshutdn: *anyopaque, admin: ?*CurlEasyPrefix, sigpipe_ctx: *SigpipeIgnoreBuf) callconv(.c) void;
extern fn Curl_cshutdn_setfds(cshutdn: *anyopaque, admin: ?*CurlEasyPrefix, read_fd_set: ?*anyopaque, write_fd_set: ?*anyopaque, maxfd: *c_int) callconv(.c) void;
extern fn Curl_cshutdn_add_waitfds(cshutdn: *anyopaque, admin: ?*CurlEasyPrefix, cwfds: *CurlWaitfds) callconv(.c) c_uint;
extern fn Curl_cshutdn_add_pollfds(cshutdn: *anyopaque, admin: ?*CurlEasyPrefix, cpfds: *CurlPollfds) callconv(.c) CURLcode;
extern fn Curl_cshutdn_sigpipe_init_c(ig: *SigpipeIgnoreBuf) callconv(.c) void;
extern fn Curl_cshutdn_sigpipe_apply_c(data: ?*CurlEasyPrefix, ig: *SigpipeIgnoreBuf) callconv(.c) void;
extern fn Curl_cshutdn_sigpipe_restore_c(ig: *SigpipeIgnoreBuf) callconv(.c) void;
extern fn Curl_cpool_init(cpool: *anyopaque, share: ?*anyopaque, size: usize) callconv(.c) void;
extern fn Curl_cpool_destroy(cpool: *anyopaque, admin: ?*CurlEasyPrefix) callconv(.c) void;
extern fn Curl_cpool_xfer_init(data: *CurlEasyPrefix) callconv(.c) void;
extern fn Curl_cpool_nw_changed(cpool: *anyopaque, admin: *CurlEasyPrefix) callconv(.c) void;
extern fn Curl_cpool_return(
    data: *CurlEasyPrefix,
    conn: *anyopaque,
    cb: *const fn (*CurlEasyPrefix, *anyopaque, ?*anyopaque, *const curltime) callconv(.c) c_int,
    cbdata: ?*anyopaque,
    pnow: *const curltime,
) callconv(.c) void;
extern fn Curl_conn_close(data: *CurlEasyPrefix, conn: *anyopaque, aborted: bool) callconv(.c) void;
extern fn Curl_conn_is_connected(conn: *anyopaque, sockindex: c_int) callconv(.c) bool;
extern fn Curl_conn_is_multiplex(conn: *anyopaque, sockindex: c_int) callconv(.c) bool;
extern fn Curl_conn_get_max_concurrent(data: *CurlEasyPrefix, conn: *anyopaque, sockindex: c_int) callconv(.c) c_uint;
extern fn Curl_conn_ev_data_done(data: *CurlEasyPrefix, premature: bool) callconv(.c) void;
extern fn Curl_conn_data_pending(data: *CurlEasyPrefix, sockindex: c_int) callconv(.c) bool;
extern fn Curl_conn_get_first_socket(data: *CurlEasyPrefix) callconv(.c) curl_socket_t;
extern fn Curl_conn_adjust_pollset(data: *CurlEasyPrefix, conn: *anyopaque, ps: *EasyPollset) callconv(.c) CURLcode;
extern fn Curl_conn_connect(data: *CurlEasyPrefix, sockindex: c_int, blocking: bool, done: *bool) callconv(.c) CURLcode;
extern fn Curl_conn_report_failed(data: *CurlEasyPrefix, sockindex: c_int) callconv(.c) void;
extern fn Curl_pgrs_now(data: *CurlEasyPrefix) callconv(.c) *const curltime;
extern fn Curl_pgrs_since_ms(data: *CurlEasyPrefix, pnow: ?*const curltime, timer: c_int) callconv(.c) timediff_t;
extern fn Curl_pgrsTime(data: *CurlEasyPrefix, timer: c_int) callconv(.c) void;
extern fn Curl_pgrsTimeWas(data: *CurlEasyPrefix, timer: c_int, timestamp: curltime) callconv(.c) void;
extern fn Curl_pgrsCompleted(data: *CurlEasyPrefix) callconv(.c) void;
extern fn Curl_pgrsDone(data: *CurlEasyPrefix, pnow: *const curltime) callconv(.c) c_int;
extern fn Curl_pgrsCheck(data: *CurlEasyPrefix) callconv(.c) CURLcode;
extern fn Curl_pgrsUpdate_nometer(data: *CurlEasyPrefix) callconv(.c) void;
extern fn Curl_pgrsUpdateX(data: *CurlEasyPrefix, pnow: *const curltime) callconv(.c) CURLcode;
extern fn Curl_init_CONNECT(data: *CurlEasyPrefix) callconv(.c) void;
extern fn Curl_init_transfer(data: *CurlEasyPrefix, conn: ?*anyopaque) callconv(.c) CURLcode;
extern fn Curl_pretransfer(data: *CurlEasyPrefix) callconv(.c) CURLcode;
extern fn Curl_connect(data: *CurlEasyPrefix, connected: *bool) callconv(.c) CURLcode;
extern fn Curl_sendrecv(data: *CurlEasyPrefix) callconv(.c) CURLcode;
extern fn Curl_retry_request(data: *CurlEasyPrefix, url: *?[*:0]u8) callconv(.c) CURLcode;
extern fn Curl_imap_ws_cwriter_is_paused(data: *const CurlEasyPrefix) callconv(.c) bool;
inline fn Curl_cwriter_is_paused(data: *const CurlEasyPrefix) bool {
    return Curl_imap_ws_cwriter_is_paused(data);
}
extern fn Curl_xfer_recv_is_paused(data: *CurlEasyPrefix) callconv(.c) bool;
extern fn Curl_xfer_write_done(data: *CurlEasyPrefix, premature: bool) callconv(.c) CURLcode;
extern fn Curl_1st_fatal(result1: CURLcode, result2: CURLcode) callconv(.c) CURLcode;
extern fn Curl_req_done(req: *anyopaque, data: *CurlEasyPrefix, aborted: bool) callconv(.c) CURLcode;
extern fn Curl_resolv_shutdown_all(data: *CurlEasyPrefix) callconv(.c) void;
extern fn Curl_netrc_cleanup(store: *anyopaque) callconv(.c) void;
extern fn Curl_getconnectinfo(data: *CurlEasyPrefix, connp: *?*anyopaque) callconv(.c) curl_socket_t;
extern fn Curl_timeleft_now_ms(data: *CurlEasyPrefix, pnow: *const curltime) callconv(.c) timediff_t;
extern fn Curl_rlimit_avail(r: *anyopaque, pnow: ?*const curltime) callconv(.c) i64;
extern fn Curl_rlimit_active(r: *const anyopaque) callconv(.c) bool;
extern fn Curl_rlimit_wait_ms(r: *anyopaque, pnow: *const curltime) callconv(.c) timediff_t;
extern fn Curl_rlimit_next_step_ms(r: *anyopaque, pnow: *const curltime) callconv(.c) timediff_t;
extern fn Curl_bufref_ptr(br: *const anyopaque) callconv(.c) ?[*:0]const u8;
inline fn Curl_bufref_dup(br: *const anyopaque) ?[*:0]u8 {
    const p = Curl_bufref_ptr(br) orelse return null;
    return mem_mod.strdup(p);
}
extern fn Curl_failf(data: *CurlEasyPrefix, fmt: [*:0]const u8, ...) callconv(.c) void;
extern fn Curl_infof(data: *CurlEasyPrefix, fmt: [*:0]const u8, ...) callconv(.c) void;

inline fn goodMultiHandle(multi: ?*const CurlMultiPrefix) bool {
    const m = multi orelse return false;
    return m.magic == CURL_MULTI_HANDLE;
}

inline fn goodEasyHandle(data: ?*const CurlEasyPrefix) bool {
    const d = data orelse return false;
    return d.magic == CURL_EASY_HANDLE;
}

inline fn connSockIdxValid(idx: c_int) bool {
    return idx == FIRSTSOCKET or idx == SECONDARYSOCKET;
}

inline fn curlmNtfy(data: ?*CurlEasyPrefix, ntype: c_uint) void {
    const d = data orelse return;
    const m = d.multi orelse return;
    if (Curl_zig_multi_ntfy_has_cb(m)) {
        containers.Curl_mntfy_add(d, Curl_zig_multi_ntfy(m), d.mid, ntype);
    }
}

fn mstateEnterConnect(data: *CurlEasyPrefix, from_state: CURLMstate) void {
    _ = from_state;
    Curl_init_CONNECT(data);
}

fn mstateEnterDid(data: *CurlEasyPrefix, from_state: CURLMstate) void {
    _ = from_state;
    Curl_zig_easy_set_req_chunk(data, false);
    Curl_pgrsTime(data, TIMER_PRETRANSFER);
    if (!Curl_zig_easy_req_want_send(data)) {
        Curl_pgrsTime(data, TIMER_POSTRANSFER);
    }
}

fn mstateEnterDone(data: *CurlEasyPrefix, from_state: CURLMstate) void {
    _ = from_state;
    curlmNtfy(data, CURLMNOTIFY_EASY_DONE);
}

fn mstateEnterCompleted(data: *CurlEasyPrefix, from_state: CURLMstate) void {
    if (from_state < MSTATE_DID) {
        Curl_pgrsTime(data, TIMER_PRETRANSFER);
        Curl_pgrsTime(data, TIMER_POSTRANSFER);
        Curl_pgrsTime(data, TIMER_STARTTRANSFER);
    }
    Curl_pgrsCompleted(data);
    if (from_state < MSTATE_DONE) {
        curlmNtfy(data, CURLMNOTIFY_EASY_DONE);
    }
    if (data.multi) |multi| {
        containers.Curl_uint32_bset_remove(&multi.process, data.mid);
        containers.Curl_uint32_bset_remove(&multi.pending, data.mid);
        if (containers.Curl_uint32_bset_empty(&multi.process)) {
            multi_xfer_bufs_free(multi);
        }
    }
    Curl_detach_connection(data);
    Curl_expire_clear_all(data);
}

fn mstate(data: *CurlEasyPrefix, state: CURLMstate) void {
    const oldstate = data.mstate;
    if (oldstate == state)
        return;

    Curl_zig_multi_trc_state(data, oldstate, state);
    data.mstate = state;

    switch (state) {
        MSTATE_CONNECT => mstateEnterConnect(data, oldstate),
        MSTATE_DID => mstateEnterDid(data, oldstate),
        MSTATE_DONE => mstateEnterDone(data, oldstate),
        MSTATE_COMPLETED => mstateEnterCompleted(data, oldstate),
        else => {},
    }
}

fn multi_addmsg(multi: *CurlMultiPrefix, data: *CurlEasyPrefix) void {
    if (containers.Curl_uint32_bset_empty(&multi.msgsent)) {
        curlmNtfy(multi.admin, CURLMNOTIFY_INFO_READ);
    }
    _ = containers.Curl_uint32_bset_add(&multi.msgsent, data.mid);
}

fn multi_timeouts_init(data: *CurlEasyPrefix) void {
    const first_ptr = Curl_zig_easy_timeouts_first_ptr(data);
    first_ptr.* = @intCast(EXPIRE_LAST);
    const splaynode = doh_mod.Curl_zig_easy_timeouts_splaynode(data);
    splaynode.setRegistered(false);
}

pub export fn Curl_multi_handle(
    xfer_table_size: u32,
    ev_hashsize: usize,
    chashsize: usize,
    dnssize: usize,
    sesssize: usize,
) callconv(.c) ?*CurlMultiPrefix {
    const raw = mem.curl_calloc_fn(1, Curl_zig_multi_sizeof()) orelse return null;
    const multi: *CurlMultiPrefix = @ptrCast(@alignCast(raw));

    multi.magic = CURL_MULTI_HANDLE;

    multi.admin = curl_easy_init();
    if (multi.admin == null) {
        mem.curl_free_fn(multi);
        return null;
    }
    Curl_zig_multi_prepare_admin(multi);

    var created: curltime = .{ .tv_sec = 0, .tv_usec = 0 };
    var tnow: time_net.curltime = .{ .tv_sec = 0, .tv_usec = 0 };
    time_net.curlx_pnow(&tnow);
    created.tv_sec = tnow.tv_sec;
    created.tv_usec = tnow.tv_usec;

    containers.Curl_timeouts_init(&multi.timeouts, &created);
    multi_timeouts_init(multi.admin.?);

    Curl_dnscache_init(&multi.dnscache, dnssize);
    containers.Curl_mntfy_init(multi, Curl_zig_multi_ntfy(multi));
    altsvc_mod.Curl_multi_ev_init(multi, ev_hashsize);
    containers.Curl_uint32_tbl_init(&multi.xfers, null);
    containers.Curl_uint32_bset_init(&multi.process);
    containers.Curl_uint32_bset_init(&multi.dirty);
    containers.Curl_uint32_bset_init(&multi.pending);
    containers.Curl_uint32_bset_init(&multi.msgsent);
    Curl_zig_multi_proto_hash_init(multi);
    Curl_cshutdn_init(Curl_zig_multi_cshutdn(multi));

    Curl_zig_multi_set_multiplexing(multi, true);
    multi.max_concurrent_streams = 100;

    if (containers.Curl_uint32_bset_resize(&multi.process, xfer_table_size) != 0 or
        containers.Curl_uint32_bset_resize(&multi.pending, xfer_table_size) != 0 or
        containers.Curl_uint32_bset_resize(&multi.dirty, xfer_table_size) != 0 or
        containers.Curl_uint32_bset_resize(&multi.msgsent, xfer_table_size) != 0 or
        containers.Curl_uint32_tbl_resize(&multi.xfers, xfer_table_size) != 0)
    {
        return cleanupFailedMultiInit(multi);
    }

    Curl_zig_multi_debug_env_init(multi);

    _ = containers.Curl_uint32_tbl_add(&multi.xfers, multi.admin, &multi.admin.?.mid);
    _ = containers.Curl_uint32_bset_add(&multi.process, multi.admin.?.mid);

    Curl_cpool_init(Curl_zig_multi_cpool(multi), null, chashsize);

    if (Curl_zig_multi_init_optional_fields(multi, sesssize, xfer_table_size) != 0) {
        return cleanupFailedMultiInit(multi);
    }

    return multi;
}

fn cleanupFailedMultiInit(multi: *CurlMultiPrefix) ?*CurlMultiPrefix {
    Curl_zig_multi_destroy_async_thrdd(multi, true);
    altsvc_mod.Curl_multi_ev_cleanup(multi);
    collections.Curl_hash_destroy(Curl_zig_multi_proto_hash(multi));
    Curl_dnscache_destroy(&multi.dnscache);
    Curl_cpool_destroy(Curl_zig_multi_cpool(multi), multi.admin);
    Curl_cshutdn_destroy(Curl_zig_multi_cshutdn(multi), multi.admin);
    Curl_zig_multi_free_optional_fields(multi);
    if (multi.admin) |admin| {
        altsvc_mod.Curl_multi_ev_xfer_done(multi, admin);
        admin.multi = null;
        _ = Curl_close(&multi.admin);
    }
    containers.Curl_mntfy_cleanup(multi, Curl_zig_multi_ntfy(multi));

    containers.Curl_uint32_bset_destroy(&multi.process);
    containers.Curl_uint32_bset_destroy(&multi.dirty);
    containers.Curl_uint32_bset_destroy(&multi.pending);
    containers.Curl_uint32_bset_destroy(&multi.msgsent);
    containers.Curl_uint32_tbl_destroy(&multi.xfers);

    mem.curl_free_fn(multi);
    return null;
}

pub export fn curl_multi_init() callconv(.c) ?*CurlMultiPrefix {
    return Curl_multi_handle(
        CURL_XFER_TABLE_SIZE,
        CURL_SOCKET_HASH_TABLE_SIZE,
        CURL_CONNECTION_HASH_SIZE,
        CURL_DNS_HASH_SIZE,
        CURL_TLS_SESSION_SIZE,
    );
}

pub export fn Curl_is_connecting(data: *CurlEasyPrefix) callconv(.c) bool {
    return data.mstate < MSTATE_DO;
}

fn multi_assess_wakeup(multi: *CurlMultiPrefix) CURLMcode {
    return Curl_zig_multi_assess_wakeup(multi);
}

fn multi_xfers_add(multi: *CurlMultiPrefix, data: *CurlEasyPrefix) CURLMcode {
    const capacity = containers.Curl_uint32_tbl_capacity(&multi.xfers);
    var new_size: u32 = 0;
    const max_capacity: u32 = std.math.maxInt(u32) - 1;

    if (capacity < max_capacity) {
        const used = containers.Curl_uint32_tbl_count(&multi.xfers);
        const unused = capacity - used;
        const min_unused = @max(capacity >> 3, 4);
        if (unused < min_unused) {
            const growth = @min(@max(capacity >> 1, 128), 2048);
            if ((max_capacity - growth) <= capacity) {
                new_size = max_capacity;
            } else {
                new_size = capacity + growth;
            }
        }
    }

    if (new_size > capacity) {
        if (containers.Curl_uint32_bset_resize(&multi.process, new_size) != 0 or
            containers.Curl_uint32_bset_resize(&multi.dirty, new_size) != 0 or
            containers.Curl_uint32_bset_resize(&multi.pending, new_size) != 0 or
            containers.Curl_uint32_bset_resize(&multi.msgsent, new_size) != 0 or
            containers.Curl_uint32_tbl_resize(&multi.xfers, new_size) != 0)
        {
            return CURLM_OUT_OF_MEMORY;
        }
    }

    if (!containers.Curl_uint32_tbl_add(&multi.xfers, data, &data.mid)) {
        return CURLM_OUT_OF_MEMORY;
    }
    return CURLM_OK;
}

pub export fn Curl_multi_add_handle(
    multi: *CurlMultiPrefix,
    data: *CurlEasyPrefix,
) callconv(.c) CURLMcode {
    if (data.multi != null)
        return CURLM_ADDED_ALREADY;

    if (Curl_zig_multi_dead(multi)) {
        if (containers.Curl_uint32_tbl_count(&multi.xfers) != 1 or
            !containers.Curl_uint32_tbl_contains(&multi.xfers, 0))
        {
            return CURLM_ABORTED_BY_CALLBACK;
        }
        Curl_zig_multi_set_dead(multi, false);
        containers.Curl_uint32_bset_clear(&multi.process);
        containers.Curl_uint32_bset_clear(&multi.dirty);
        containers.Curl_uint32_bset_clear(&multi.pending);
        containers.Curl_uint32_bset_clear(&multi.msgsent);
    }

    if (Curl_zig_easy_multi_easy(data)) |me| {
        _ = curl_multi_cleanup(me);
        Curl_zig_easy_set_multi_easy(data, null);
    }

    if (multi_xfers_add(multi, data) != CURLM_OK)
        return CURLM_OUT_OF_MEMORY;

    multi_timeouts_init(data);

    Curl_zig_easy_clear_errorbuffer(data);
    Curl_zig_easy_set_state_os_errno(data, 0);

    data.multi = multi;

    mstate(data, MSTATE_INIT);
    Curl_zig_easy_set_state_really_alive(data, false);

    Curl_zig_easy_init_psl(data, multi);

    _ = containers.Curl_uint32_bset_add(&multi.process, data.mid);
    multi.xfers_alive += 1;
    multi.xfers_total_ever += 1;

    Curl_cpool_xfer_init(data);
    Curl_zig_multi_warn_debug(multi, data);

    Curl_multi_mark_dirty(data);

    const mresult = Curl_update_timer(multi);
    if (mresult != CURLM_OK) {
        data.multi = null;
        containers.Curl_uint32_tbl_remove(&multi.xfers, data.mid);
        data.mid = std.math.maxInt(u32);
        return mresult;
    }

    Curl_zig_multi_clone_admin_timeouts(multi, data);
    return CURLM_OK;
}

pub export fn curl_multi_add_handle(
    m: ?*CurlMultiPrefix,
    curl: ?*CurlEasyPrefix,
) callconv(.c) CURLMcode {
    var guard: CurlMapiGuard = undefined;
    var mresult: CURLMcode = CURLM_OK;

    if (api_mod.Curl_mapi_enter(&guard, m, CURL_MAPI_FN_multi_add_handle, &mresult)) {
        if (!goodEasyHandle(curl) or Curl_zig_easy_state_internal(curl.?)) {
            mresult = CURLM_BAD_EASY_HANDLE;
        } else {
            mresult = Curl_multi_add_handle(m.?, curl.?);
        }
    }
    api_mod.Curl_mapi_leave(&guard);
    return mresult;
}

fn multi_conn_should_close(
    conn: *anyopaque,
    data: *CurlEasyPrefix,
    premature: bool,
) bool {
    if (Curl_zig_conn_bits_close(conn))
        return true;

    if (Curl_zig_easy_set_reuse_forbid(data) and
        Curl_zig_conn_should_close_reuse_forbid(conn))
    {
        return true;
    }

    if (Curl_zig_easy_set_connect_only(data) == 0 and
        Curl_zig_conn_scheme(conn) != null and
        (Curl_zig_conn_scheme_flags(conn) & PROTOPT_CONN_REUSE) == 0)
    {
        return true;
    }

    if (premature and !Curl_conn_is_multiplex(conn, FIRSTSOCKET))
        return true;

    return false;
}

fn multi_done_locked(
    data: *CurlEasyPrefix,
    conn: *anyopaque,
    userdata: ?*anyopaque,
    pnow: *const curltime,
) callconv(.c) c_int {
    _ = pnow;
    const mdctx: *const MultiDoneCtx = @ptrCast(@alignCast(userdata.?));
    const premature = mdctx.premature != 0;

    if (Curl_zig_conn_attached_xfers(conn) != 0) {
        return CPOOL_DO_KEEP;
    }

    if (multi_conn_should_close(conn, data, premature)) {
        Curl_zig_conn_set_bits_close(conn, true);
        return if (premature) CPOOL_DO_TERMINATE else CPOOL_DO_CLOSE;
    } else if (Curl_conn_get_max_concurrent(data, conn, FIRSTSOCKET) == 0) {
        Curl_zig_conn_set_bits_close(conn, true);
        return if (premature) CPOOL_DO_TERMINATE else CPOOL_DO_CLOSE;
    } else {
        return CPOOL_DO_IDLE;
    }
}

fn multi_done(
    data: *CurlEasyPrefix,
    status: CURLcode,
    premature_arg: bool,
) CURLcode {
    var result: CURLcode = CURLE_OK;
    var premature = premature_arg;
    const conn_opt = data.conn;
    const pnow = Curl_pgrs_now(data);

    if (Curl_zig_easy_state_done(data))
        return CURLE_OK;
    Curl_zig_easy_set_state_done(data, true);

    Curl_resolv_shutdown_all(data);

    Curl_zig_easy_free_req_newurl(data);
    Curl_zig_easy_free_req_location(data);

    switch (status) {
        CURLE_ABORTED_BY_CALLBACK,
        CURLE_READ_ERROR,
        CURLE_WRITE_ERROR,
        => {
            premature = true;
        },
        else => {},
    }

    if (conn_opt) |conn| {
        if (Curl_zig_conn_run_has_done(conn) and data.mstate >= MSTATE_PROTOCONNECT) {
            result = Curl_zig_conn_run_call_done(data, status, premature);
        } else {
            result = status;
        }
    } else {
        result = status;
    }

    if (data.mstate > MSTATE_CONNECTING and result != CURLE_ABORTED_BY_CALLBACK) {
        const rc = Curl_pgrsDone(data, pnow);
        if (result == CURLE_OK and rc != 0) {
            result = CURLE_ABORTED_BY_CALLBACK;
        }
    }

    result = Curl_1st_fatal(result, Curl_xfer_write_done(data, premature));

    if (result == CURLE_OK) {
        result = Curl_req_done(Curl_zig_easy_req(data), data, premature);
    }

    if (conn_opt) |conn| {
        var mdctx: MultiDoneCtx = .{ .premature = @intFromBool(premature) };

        Curl_conn_ev_data_done(data, premature);
        Curl_detach_connection(data);
        Curl_dnscache_prune(data, pnow);

        Curl_cpool_return(data, conn, &multi_done_locked, &mdctx, pnow);

        if (data.multi) |multi| {
            multi_schedule_pending(multi);
        }
    }

    Curl_netrc_cleanup(Curl_zig_easy_state_netrc(data));
    return result;
}

pub export fn Curl_multi_remove_handle(
    multi: *CurlMultiPrefix,
    data: *CurlEasyPrefix,
) callconv(.c) CURLMcode {
    if (data.multi == null)
        return CURLM_OK;

    if (data.multi != multi)
        return CURLM_BAD_EASY_HANDLE;

    if (data.mid == std.math.maxInt(u32))
        return CURLM_INTERNAL_ERROR;

    const entry = containers.Curl_uint32_tbl_get(&multi.xfers, data.mid);
    if (entry != @as(?*anyopaque, @ptrCast(data)))
        return CURLM_INTERNAL_ERROR;

    const premature = data.mstate < MSTATE_COMPLETED;

    if (data.conn) |conn| {
        if (premature and data.mstate > MSTATE_DO) {
            Curl_zig_conn_set_bits_close(conn, true);
        }
        _ = multi_done(data, data.result, premature);
    }

    Curl_expire_clear_all(data);

    if (data.mstate != MSTATE_MSGSENT) {
        multi.xfers_alive -= 1;
    }

    if (Curl_zig_easy_state_really_alive(data)) {
        Curl_zig_easy_set_state_really_alive(data, false);
        multi.xfers_really_alive -= 1;
        if (multi.xfers_really_alive == 0) {
            _ = multi_assess_wakeup(multi);
        }
    }

    Curl_zig_easy_wildcard_dtor(data);

    data.mstate = MSTATE_COMPLETED;

    Curl_detach_connection(data);

    altsvc_mod.Curl_multi_ev_xfer_done(multi, data);

    if (Curl_zig_easy_set_connect_only(data) != 0) {
        if (Curl_zig_easy_multi_easy(data) != null) {
            if (Curl_zig_easy_state_last_conn_id(data) != -1) {
                var conn: ?*anyopaque = null;
                _ = Curl_getconnectinfo(data, &conn);
                if (conn) |c| {
                    if (Curl_zig_conn_bits_connect_only(c)) {
                        Curl_zig_conn_set_bits_close(c, true);
                    }
                }
            }
        } else {
            var conn: ?*anyopaque = null;
            _ = Curl_getconnectinfo(data, &conn);
            if (conn) |c| {
                Curl_conn_close(data, c, true);
            }
        }
    }

    Curl_zig_easy_clear_psl_if_multi(data, multi);

    const mid = data.mid;
    containers.Curl_uint32_tbl_remove(&multi.xfers, mid);
    containers.Curl_uint32_bset_remove(&multi.process, mid);
    containers.Curl_uint32_bset_remove(&multi.dirty, mid);
    containers.Curl_uint32_bset_remove(&multi.pending, mid);
    containers.Curl_uint32_bset_remove(&multi.msgsent, mid);
    data.multi = null;
    data.mid = std.math.maxInt(u32);
    Curl_zig_easy_set_master_mid(data, std.math.maxInt(u32));

    multi_schedule_pending(multi);
    var mresult = Curl_update_timer(multi);
    if (mresult != CURLM_OK)
        return mresult;

    mresult = multi_assess_wakeup(multi);
    if (mresult != CURLM_OK) {
        Curl_failf(data, "error enabling wakeup listening: %d", mresult);
        return mresult;
    }

    return CURLM_OK;
}

pub export fn curl_multi_remove_handle(
    m: ?*CurlMultiPrefix,
    curl: ?*CurlEasyPrefix,
) callconv(.c) CURLMcode {
    var guard: CurlMapiGuard = undefined;
    var mresult: CURLMcode = CURLM_OK;

    if (api_mod.Curl_mapi_enter(&guard, m, CURL_MAPI_FN_multi_remove_handle, &mresult)) {
        if (!goodEasyHandle(curl) or Curl_zig_easy_state_internal(curl.?)) {
            mresult = CURLM_BAD_EASY_HANDLE;
        } else {
            mresult = Curl_multi_remove_handle(m.?, curl.?);
        }
    }
    api_mod.Curl_mapi_leave(&guard);
    return mresult;
}

pub export fn Curl_multiplex_wanted(multi: ?*const CurlMultiPrefix) callconv(.c) bool {
    const m = multi orelse return false;
    return Curl_zig_multi_multiplexing(m);
}

pub export fn Curl_detach_connection(data: *CurlEasyPrefix) callconv(.c) void {
    if (data.conn) |conn| {
        if (Curl_zig_conn_attached_xfers(conn) != 0) {
            Curl_zig_conn_dec_attached_xfers(conn);
            if (Curl_zig_conn_attached_xfers(conn) == 0) {
                Curl_zig_conn_set_attached_multi(conn, null);
            }
        }
    }
    data.conn = null;
}

pub export fn Curl_attach_connection(
    data: *CurlEasyPrefix,
    conn: *anyopaque,
    matched: bool,
) callconv(.c) void {
    data.conn = conn;
    if (matched) {
        Curl_zig_easy_set_state_last_conn_id(data, Curl_zig_conn_connection_id(conn));
        Curl_zig_easy_set_state_last_cpid(data, Curl_zig_conn_cpid(conn));
    }
    Curl_zig_conn_inc_attached_xfers(conn);
    if (Curl_zig_conn_attached_multi(conn) == null) {
        Curl_zig_conn_set_attached_multi(conn, data.multi);
    }
    Curl_zig_conn_run_call_attach(data, conn);
}

fn multi_adjust_pollset(data: *CurlEasyPrefix, ps: *EasyPollset) CURLcode {
    var result: CURLcode = CURLE_OK;

    if (ps.n != 0) {
        const conn = data.conn orelse return CURLE_OK;
        const recv_blocked = Curl_rlimit_avail(Curl_zig_easy_progress_dl_rlimit(data), null) <= 0;
        const send_blocked = Curl_rlimit_avail(Curl_zig_easy_progress_ul_rlimit(data), null) <= 0;

        if (send_blocked or recv_blocked) {
            var i: c_int = 0;
            while (i <= SECONDARYSOCKET) : (i += 1) {
                const sock = Curl_zig_conn_sock_at(conn, i);
                if (sock == CURL_SOCKET_BAD)
                    continue;
                if (recv_blocked and headers_sock.Curl_pollset_want_recv(data, ps, sock)) {
                    result = headers_sock.Curl_pollset_remove_in(data, ps, sock);
                    if (result != CURLE_OK)
                        break;
                }
                if (send_blocked and headers_sock.Curl_pollset_want_send(data, ps, sock)) {
                    result = headers_sock.Curl_pollset_remove_out(data, ps, sock);
                    if (result != CURLE_OK)
                        break;
                }
            }
        }

        const sock0 = Curl_zig_conn_sock_at(conn, FIRSTSOCKET);
        const sock1 = Curl_zig_conn_sock_at(conn, SECONDARYSOCKET);
        if (!recv_blocked and
            ((headers_sock.Curl_pollset_want_recv(data, ps, sock0) and Curl_conn_data_pending(data, FIRSTSOCKET)) or
                (headers_sock.Curl_pollset_want_recv(data, ps, sock1) and Curl_conn_data_pending(data, SECONDARYSOCKET))))
        {
            Curl_multi_mark_dirty(data);
        }
    }
    return result;
}

fn mstate_connecting_pollset(data: *CurlEasyPrefix, ps: *EasyPollset) CURLcode {
    const conn = data.conn orelse return CURLE_OK;
    var result: CURLcode = CURLE_OK;

    if (Curl_xfer_recv_is_paused(data))
        return CURLE_OK;

    const sockfd = Curl_conn_get_first_socket(data);
    if (sockfd != CURL_SOCKET_BAD) {
        result = headers_sock.Curl_pollset_change(data, ps, sockfd, CURL_POLL_IN, 0);
        if (result == CURLE_OK)
            result = multi_adjust_pollset(data, ps);
    }
    if (result == CURLE_OK)
        result = Curl_conn_adjust_pollset(data, conn, ps);
    return result;
}

fn mstate_protocol_pollset(data: *CurlEasyPrefix, ps: *EasyPollset) CURLcode {
    const conn = data.conn orelse return CURLE_OK;
    var result: CURLcode = CURLE_OK;

    if (Curl_zig_conn_run_has_proto_pollset(conn)) {
        result = Curl_zig_conn_run_call_proto_pollset(data, ps);
    } else {
        const sockfd = Curl_zig_conn_sock_at(conn, FIRSTSOCKET);
        if (sockfd != CURL_SOCKET_BAD) {
            result = headers_sock.Curl_pollset_change(data, ps, sockfd, CURL_POLL_IN, 0);
        }
    }
    if (result == CURLE_OK)
        result = multi_adjust_pollset(data, ps);
    if (result == CURLE_OK)
        result = Curl_conn_adjust_pollset(data, conn, ps);
    return result;
}

fn mstate_do_pollset(data: *CurlEasyPrefix, ps: *EasyPollset) CURLcode {
    const conn = data.conn orelse return CURLE_OK;
    var result: CURLcode = CURLE_OK;

    if (Curl_zig_conn_run_has_doing_pollset(conn)) {
        result = Curl_zig_conn_run_call_doing_pollset(data, ps);
    } else {
        const send_idx = Curl_zig_conn_send_idx(conn);
        if (connSockIdxValid(send_idx)) {
            result = headers_sock.Curl_pollset_add_out(data, ps, Curl_zig_conn_sock_at(conn, send_idx));
        }
    }
    if (result == CURLE_OK)
        result = multi_adjust_pollset(data, ps);
    if (result == CURLE_OK)
        result = Curl_conn_adjust_pollset(data, conn, ps);
    return result;
}

fn mstate_domore_pollset(data: *CurlEasyPrefix, ps: *EasyPollset) CURLcode {
    const conn = data.conn orelse return CURLE_OK;
    var result: CURLcode = CURLE_OK;

    if (Curl_zig_conn_run_has_domore_pollset(conn)) {
        result = Curl_zig_conn_run_call_domore_pollset(data, ps);
    } else {
        const send_idx = Curl_zig_conn_send_idx(conn);
        if (connSockIdxValid(send_idx)) {
            result = headers_sock.Curl_pollset_add_out(data, ps, Curl_zig_conn_sock_at(conn, send_idx));
        }
    }
    if (result == CURLE_OK)
        result = multi_adjust_pollset(data, ps);
    if (result == CURLE_OK)
        result = Curl_conn_adjust_pollset(data, conn, ps);
    return result;
}

fn mstate_perform_pollset(data: *CurlEasyPrefix, ps: *EasyPollset) CURLcode {
    const conn = data.conn orelse return CURLE_OK;
    var result: CURLcode = CURLE_OK;

    if (Curl_zig_conn_run_has_perform_pollset(conn)) {
        result = Curl_zig_conn_run_call_perform_pollset(data, ps);
    } else {
        const recv_idx = Curl_zig_conn_recv_idx(conn);
        if (Curl_zig_easy_req_want_recv(data) and connSockIdxValid(recv_idx)) {
            result = headers_sock.Curl_pollset_add_in(data, ps, Curl_zig_conn_sock_at(conn, recv_idx));
        }
        const send_idx = Curl_zig_conn_send_idx(conn);
        if (result == CURLE_OK and Curl_zig_easy_req_want_send(data) and connSockIdxValid(send_idx)) {
            result = headers_sock.Curl_pollset_add_out(data, ps, Curl_zig_conn_sock_at(conn, send_idx));
        }
    }
    if (result == CURLE_OK)
        result = multi_adjust_pollset(data, ps);
    if (result == CURLE_OK)
        result = Curl_conn_adjust_pollset(data, conn, ps);
    return result;
}

pub export fn Curl_multi_pollset(
    data: *CurlEasyPrefix,
    ps: *EasyPollset,
) callconv(.c) CURLMcode {
    var result: CURLcode = CURLE_OK;

    headers_sock.Curl_pollset_reset(ps);
    if (data.multi) |multi| {
        if (multi.admin == data and multi.xfers_really_alive != 0) {
            result = Curl_zig_multi_pollset_internal_wakeup(data, ps);
        }
    }

    if (result == CURLE_OK and data.conn != null) {
        switch (data.mstate) {
            MSTATE_INIT,
            MSTATE_PENDING,
            MSTATE_SETUP,
            MSTATE_CONNECT,
            => {},
            MSTATE_CONNECTING => {
                result = mstate_connecting_pollset(data, ps);
            },
            MSTATE_PROTOCONNECT,
            MSTATE_PROTOCONNECTING,
            => {
                result = mstate_protocol_pollset(data, ps);
            },
            MSTATE_DO,
            MSTATE_DOING,
            => {
                result = mstate_do_pollset(data, ps);
            },
            MSTATE_DOING_MORE => {
                result = mstate_domore_pollset(data, ps);
            },
            MSTATE_DID,
            MSTATE_PERFORMING,
            => {
                result = mstate_perform_pollset(data, ps);
            },
            MSTATE_RATELIMITING,
            MSTATE_DONE,
            MSTATE_COMPLETED,
            MSTATE_MSGSENT,
            => {},
            else => {
                Curl_failf(data, "multi_getsock: unexpected multi state %d", @as(c_int, @intCast(data.mstate)));
            },
        }
    }

    if (result != CURLE_OK) {
        if (result == CURLE_OUT_OF_MEMORY)
            return CURLM_OUT_OF_MEMORY;
        Curl_failf(data, "error determining pollset: %d", result);
        return CURLM_INTERNAL_ERROR;
    }

    return CURLM_OK;
}

pub export fn curl_multi_fdset(
    m: ?*CurlMultiPrefix,
    read_fd_set: ?*anyopaque,
    write_fd_set: ?*anyopaque,
    exc_fd_set: ?*anyopaque,
    max_fd: ?*c_int,
) callconv(.c) CURLMcode {
    var guard: CurlMapiGuard = undefined;
    var mresult: CURLMcode = CURLM_OK;
    _ = exc_fd_set;

    if (api_mod.Curl_mapi_enter(&guard, m, CURL_MAPI_FN_multi_fdset, &mresult)) {
        const multi = m.?;
        var ps: EasyPollset = undefined;
        var this_max_fd: c_int = -1;
        var mid: u32 = 0;

        headers_sock.Curl_pollset_init(&ps);
        if (containers.Curl_uint32_bset_first(&multi.process, &mid)) {
            while (true) {
                if (Curl_multi_get_easy(multi, mid)) |data| {
                    _ = Curl_multi_pollset(data, &ps);
                    var i: c_uint = 0;
                    while (i < ps.n) : (i += 1) {
                        const s = ps.sockets.?[i];
                        if (!Curl_zig_multi_fdset_valid_sock(s))
                            continue;
                        Curl_zig_multi_fdset_add(s, ps.actions.?[i], read_fd_set, write_fd_set);
                        const s_int: c_int = @intCast(s);
                        if (s_int > this_max_fd)
                            this_max_fd = s_int;
                    }
                }
                if (!containers.Curl_uint32_bset_next(&multi.process, mid, &mid))
                    break;
            }
        }

        Curl_cshutdn_setfds(
            Curl_zig_multi_cshutdn(multi),
            multi.admin,
            read_fd_set,
            write_fd_set,
            &this_max_fd,
        );

        if (max_fd) |mf| {
            mf.* = this_max_fd;
        }
        headers_sock.Curl_pollset_cleanup(&ps);
        mresult = CURLM_OK;
    }
    api_mod.Curl_mapi_leave(&guard);
    return mresult;
}

pub export fn curl_multi_waitfds(
    m: ?*CurlMultiPrefix,
    ufds: ?[*]curl_waitfd,
    size: c_uint,
    fd_count: ?*c_uint,
) callconv(.c) CURLMcode {
    var guard: CurlMapiGuard = undefined;
    var mresult: CURLMcode = CURLM_OK;

    if (api_mod.Curl_mapi_enter(&guard, m, CURL_MAPI_FN_multi_waitfds, &mresult)) {
        const multi = m.?;
        if (ufds == null and (size != 0 or fd_count == null)) {
            mresult = CURLM_BAD_FUNCTION_ARGUMENT;
        } else {
            var cwfds: CurlWaitfds = undefined;
            var ps: EasyPollset = undefined;
            var need: c_uint = 0;
            var mid: u32 = 0;

            headers_sock.Curl_pollset_init(&ps);
            headers_sock.Curl_waitfds_init(&cwfds, ufds, size);
            mresult = CURLM_OK;

            if (containers.Curl_uint32_bset_first(&multi.process, &mid)) {
                while (true) {
                    if (Curl_multi_get_easy(multi, mid)) |data| {
                        _ = Curl_multi_pollset(data, &ps);
                        need += headers_sock.Curl_waitfds_add_ps(&cwfds, &ps);
                    } else {
                        containers.Curl_uint32_bset_remove(&multi.process, mid);
                        containers.Curl_uint32_bset_remove(&multi.dirty, mid);
                    }
                    if (!containers.Curl_uint32_bset_next(&multi.process, mid, &mid))
                        break;
                }
            }

            need += Curl_cshutdn_add_waitfds(Curl_zig_multi_cshutdn(multi), multi.admin, &cwfds);

            if (need != cwfds.n and ufds != null) {
                mresult = CURLM_OUT_OF_MEMORY;
            }
            if (fd_count) |fc| {
                fc.* = need;
            }
            headers_sock.Curl_pollset_cleanup(&ps);
        }
    }
    api_mod.Curl_mapi_leave(&guard);
    return mresult;
}

fn multi_posix_poll(
    multi: *CurlMultiPrefix,
    cpfds: *CurlPollfds,
    curl_nfds: c_uint,
    extra_fds: ?[*]curl_waitfd,
    extra_nfds: c_uint,
    timeout_ms: c_int,
    extrawait: bool,
    pnevents: *c_int,
) CURLMcode {
    var mresult: CURLMcode = CURLM_OK;
    var nevents: c_int = 0;
    _ = multi;

    if (cpfds.n != 0) {
        const pollrc = headers_sock.Curl_poll(cpfds.pfds, cpfds.n, timeout_ms);
        if (pollrc < 0) {
            mresult = CURLM_UNRECOVERABLE_POLL;
            pnevents.* = nevents;
            return mresult;
        }
        nevents = pollrc;

        if (extra_fds) |efds| {
            const pfds = cpfds.pfds.?;
            var i: usize = 0;
            while (i < extra_nfds) : (i += 1) {
                const r = pfds[curl_nfds + i].revents;
                var mask: c_short = 0;
                if ((r & POLLIN) != 0)
                    mask |= CURL_WAIT_POLLIN;
                if ((r & POLLOUT) != 0)
                    mask |= CURL_WAIT_POLLOUT;
                if ((r & POLLPRI) != 0)
                    mask |= CURL_WAIT_POLLPRI;
                efds[i].revents = mask;
            }
        }
    } else if (extrawait) {
        _ = time_net.curlx_wait_ms(timeout_ms);
    }

    pnevents.* = nevents;
    return mresult;
}

const NUM_POLLS_ON_STACK = 10;

fn multi_wait(
    multi: *CurlMultiPrefix,
    extra_fds: ?[*]curl_waitfd,
    extra_nfds: c_uint,
    timeout_ms_arg: c_int,
    ret: ?*c_int,
    extrawait: bool,
) CURLMcode {
    var timeout_ms = timeout_ms_arg;
    var timeout_internal: c_int = 0;
    var nevents: c_int = 0;
    var ps: EasyPollset = undefined;
    var a_few_on_stack: [NUM_POLLS_ON_STACK]pollfd = undefined;
    var cpfds: CurlPollfds = undefined;
    var curl_nfds: c_uint = 0;
    var mresult: CURLMcode = CURLM_OK;
    var mid: u32 = 0;
    var wakeup_idx: isize = -1;

    if (timeout_ms < 0)
        return CURLM_BAD_FUNCTION_ARGUMENT;

    headers_sock.Curl_pollset_init(&ps);
    headers_sock.Curl_pollfds_init(&cpfds, &a_few_on_stack, NUM_POLLS_ON_STACK);

    if (containers.Curl_uint32_bset_first(&multi.process, &mid)) {
        while (true) {
            if (Curl_multi_get_easy(multi, mid)) |data| {
                _ = Curl_multi_pollset(data, &ps);
                if (headers_sock.Curl_pollfds_add_ps(&cpfds, &ps) != 0) {
                    mresult = CURLM_OUT_OF_MEMORY;
                    return finishMultiWait(&ps, &cpfds, ret, nevents, mresult);
                }
            } else {
                containers.Curl_uint32_bset_remove(&multi.process, mid);
                containers.Curl_uint32_bset_remove(&multi.dirty, mid);
            }
            if (!containers.Curl_uint32_bset_next(&multi.process, mid, &mid))
                break;
        }
    }

    if (Curl_cshutdn_add_pollfds(Curl_zig_multi_cshutdn(multi), multi.admin, &cpfds) != CURLE_OK) {
        mresult = CURLM_OUT_OF_MEMORY;
        return finishMultiWait(&ps, &cpfds, ret, nevents, mresult);
    }

    if (Curl_zig_multi_wakeup_pair(multi)) |wp| {
        if (extrawait or cpfds.n != 0 or extra_nfds != 0) {
            wakeup_idx = @intCast(cpfds.n);
            if (headers_sock.Curl_pollfds_add_sock(&cpfds, wp[0], POLLIN) != 0) {
                mresult = CURLM_OUT_OF_MEMORY;
                return finishMultiWait(&ps, &cpfds, ret, nevents, mresult);
            }
        }
    }

    curl_nfds = cpfds.n;
    if (extra_fds) |efds| {
        var i: usize = 0;
        while (i < extra_nfds) : (i += 1) {
            var events: c_short = 0;
            if ((efds[i].events & CURL_WAIT_POLLIN) != 0)
                events |= POLLIN;
            if ((efds[i].events & CURL_WAIT_POLLPRI) != 0)
                events |= POLLPRI;
            if ((efds[i].events & CURL_WAIT_POLLOUT) != 0)
                events |= POLLOUT;
            if (headers_sock.Curl_pollfds_add_sock(&cpfds, efds[i].fd, events) != 0) {
                mresult = CURLM_OUT_OF_MEMORY;
                return finishMultiWait(&ps, &cpfds, ret, nevents, mresult);
            }
        }
    }

    multi_timeout(multi, null, &timeout_internal);
    if (timeout_internal >= 0 and timeout_internal < timeout_ms) {
        timeout_ms = timeout_internal;
    }

    if (builtin.os.tag == .windows) {
        mresult = Curl_zig_multi_winsock_select(
            multi,
            &cpfds,
            curl_nfds,
            extra_fds,
            extra_nfds,
            timeout_ms,
            extrawait,
            &nevents,
        );
    } else {
        mresult = multi_posix_poll(
            multi,
            &cpfds,
            curl_nfds,
            extra_fds,
            extra_nfds,
            timeout_ms,
            extrawait,
            &nevents,
        );
    }

    if (nevents != 0 and wakeup_idx >= 0) {
        if (cpfds.pfds) |pfds| {
            const idx: usize = @intCast(wakeup_idx);
            if ((pfds[idx].revents & POLLIN) != 0) {
                Curl_zig_multi_consume_wakeup_pair(multi, true);
                nevents -= 1;
            }
        }
    }

    return finishMultiWait(&ps, &cpfds, ret, nevents, mresult);
}

fn finishMultiWait(
    ps: *EasyPollset,
    cpfds: *CurlPollfds,
    ret: ?*c_int,
    nevents: c_int,
    mresult: CURLMcode,
) CURLMcode {
    headers_sock.Curl_pollset_cleanup(ps);
    headers_sock.Curl_pollfds_cleanup(cpfds);
    if (ret) |r| {
        r.* = nevents;
    }
    return mresult;
}

pub export fn curl_multi_wait(
    m: ?*CurlMultiPrefix,
    extra_fds: ?[*]curl_waitfd,
    extra_nfds: c_uint,
    timeout_ms: c_int,
    ret: ?*c_int,
) callconv(.c) CURLMcode {
    var guard: CurlMapiGuard = undefined;
    var mresult: CURLMcode = CURLM_OK;

    if (api_mod.Curl_mapi_enter(&guard, m, CURL_MAPI_FN_multi_wait, &mresult)) {
        mresult = multi_wait(m.?, extra_fds, extra_nfds, timeout_ms, ret, false);
    }
    api_mod.Curl_mapi_leave(&guard);
    return mresult;
}

pub export fn curl_multi_poll(
    m: ?*CurlMultiPrefix,
    extra_fds: ?[*]curl_waitfd,
    extra_nfds: c_uint,
    timeout_ms: c_int,
    ret: ?*c_int,
) callconv(.c) CURLMcode {
    var guard: CurlMapiGuard = undefined;
    var mresult: CURLMcode = CURLM_OK;

    if (api_mod.Curl_mapi_enter(&guard, m, CURL_MAPI_FN_multi_poll, &mresult)) {
        mresult = multi_wait(m.?, extra_fds, extra_nfds, timeout_ms, ret, true);
    }
    api_mod.Curl_mapi_leave(&guard);
    return mresult;
}

pub export fn curl_multi_wakeup(m: ?*CurlMultiPrefix) callconv(.c) CURLMcode {
    if (!goodMultiHandle(m))
        return CURLM_BAD_HANDLE;
    return Curl_zig_multi_wakeup_exec(m.?);
}

pub export fn Curl_multi_wakeup_internal(multi: ?*CurlMultiPrefix) callconv(.c) void {
    if (goodMultiHandle(multi)) {
        Curl_zig_multi_wakeup_internal_exec(multi.?);
    }
}

fn multi_ischanged(multi: ?*CurlMultiPrefix, clear: bool) bool {
    const m = multi orelse return false;
    const retval = Curl_zig_multi_recheckstate(m);
    if (clear) {
        Curl_zig_multi_set_recheckstate(m, false);
    }
    return retval;
}

pub export fn Curl_multi_connchanged(multi: ?*CurlMultiPrefix) callconv(.c) void {
    if (multi) |m| {
        Curl_zig_multi_set_recheckstate(m, true);
    }
}

pub export fn Curl_multi_add_perform(
    multi: *CurlMultiPrefix,
    data: *CurlEasyPrefix,
    conn: *anyopaque,
) callconv(.c) CURLMcode {
    const mresult = Curl_multi_add_handle(multi, data);
    if (mresult == CURLM_OK) {
        const result = Curl_init_transfer(data, null);
        if (result != CURLE_OK) {
            _ = Curl_multi_remove_handle(multi, data);
            return CURLM_INTERNAL_ERROR;
        }
        mstate(data, MSTATE_PERFORMING);
        Curl_attach_connection(data, conn, true);
        Curl_zig_easy_req_set_recv(data);
    }
    return mresult;
}

fn multi_do(data: *CurlEasyPrefix, done: *bool) CURLcode {
    const conn = data.conn orelse return CURLE_OK;
    if (Curl_zig_conn_run_has_do_it(conn)) {
        return Curl_zig_conn_run_call_do_it(data, done);
    }
    return CURLE_OK;
}

fn multi_do_more(data: *CurlEasyPrefix, complete: *c_int) CURLcode {
    complete.* = DOMORE_INCOMPLETE;
    const conn = data.conn orelse return CURLE_OK;
    if (Curl_zig_conn_run_has_do_more(conn)) {
        return Curl_zig_conn_run_call_do_more(data, complete);
    }
    return CURLE_OK;
}

fn multi_handle_timeout(
    data: *CurlEasyPrefix,
    pnow: *const curltime,
    stream_error: *bool,
    result: *CURLcode,
) bool {
    const timeout_ms = Curl_timeleft_now_ms(data, pnow);
    if (timeout_ms < 0) {
        const base_timer: c_int = if (Curl_is_connecting(data)) TIMER_STARTSINGLE else TIMER_STARTOP;
        const elapsed_ms = Curl_pgrs_since_ms(data, null, base_timer);
        if (data.mstate == MSTATE_CONNECTING) {
            const resolved = if (data.conn) |c| Curl_zig_conn_bits_dns_resolved(c) else false;
            const prefix: [*:0]const u8 = if (resolved) "Connection" else "Resolving";
            Curl_failf(data, "%s timed out after %lld milliseconds", prefix, @as(c_longlong, elapsed_ms));
            Curl_conn_report_failed(data, FIRSTSOCKET);
        } else {
            const size = Curl_zig_easy_req_size(data);
            const bytecount = Curl_zig_easy_req_bytecount(data);
            if (size != -1) {
                Curl_failf(
                    data,
                    "Operation timed out after %lld milliseconds with %lld out of %lld bytes received",
                    @as(c_longlong, elapsed_ms),
                    @as(c_longlong, bytecount),
                    @as(c_longlong, size),
                );
            } else {
                Curl_failf(
                    data,
                    "Operation timed out after %lld milliseconds with %lld bytes received",
                    @as(c_longlong, elapsed_ms),
                    @as(c_longlong, bytecount),
                );
            }
        }
        result.* = CURLE_OPERATION_TIMEDOUT;
        if (data.conn) |conn| {
            if (data.mstate > MSTATE_DO) {
                Curl_zig_conn_set_bits_close(conn, true);
                stream_error.* = true;
            }
            _ = multi_done(data, result.*, true);
        }
        return true;
    }
    return false;
}

fn protocol_connecting(data: *CurlEasyPrefix, done: *bool) CURLcode {
    if (data.conn) |conn| {
        if (Curl_zig_conn_run_has_connecting(conn)) {
            done.* = false;
            return Curl_zig_conn_run_call_connecting(data, done);
        }
    }
    done.* = true;
    return CURLE_OK;
}

fn protocol_doing(data: *CurlEasyPrefix, done: *bool) CURLcode {
    if (data.conn) |conn| {
        if (Curl_zig_conn_run_has_doing(conn)) {
            done.* = false;
            return Curl_zig_conn_run_call_doing(data, done);
        }
    }
    done.* = true;
    return CURLE_OK;
}

fn protocol_connect(data: *CurlEasyPrefix, protocol_done: *bool) CURLcode {
    const conn = data.conn orelse return CURLE_OK;
    protocol_done.* = false;
    if (!Curl_zig_conn_bits_protoconnstart(conn)) {
        if (Curl_zig_conn_run_has_connect_it(conn)) {
            const result = Curl_zig_conn_run_call_connect_it(data, protocol_done);
            if (result != CURLE_OK)
                return result;
        }
        Curl_zig_conn_set_bits_protoconnstart(conn, true);
    }
    if (!Curl_zig_conn_run_has_connecting(conn)) {
        protocol_done.* = true;
    }
    return CURLE_OK;
}

fn multi_posttransfer(data: *CurlEasyPrefix) void {
    Curl_zig_easy_posttransfer_restore_signal(data);
}

fn multi_follow(
    data: *CurlEasyPrefix,
    handler: ?*const anyopaque,
    newurl: ?[*:0]const u8,
    ftype: c_int,
) CURLcode {
    var has_follow: bool = false;
    const result = Curl_zig_scheme_run_follow(data, handler, newurl, ftype, &has_follow);
    if (has_follow)
        return result;

    if (ftype == FOLLOW_RETRY)
        return CURLE_OK;

    return CURLE_TOO_MANY_REDIRECTS;
}

fn mspeed_check(data: *CurlEasyPrefix) CURLcode {
    const dl_rlimit = Curl_zig_easy_progress_dl_rlimit(data);
    const ul_rlimit = Curl_zig_easy_progress_ul_rlimit(data);

    if (Curl_rlimit_active(dl_rlimit) or Curl_rlimit_active(ul_rlimit)) {
        const pnow = Curl_pgrs_now(data);
        var send_ms = Curl_rlimit_wait_ms(ul_rlimit, pnow);
        var recv_ms = Curl_rlimit_wait_ms(dl_rlimit, pnow);

        if (send_ms != 0 or recv_ms != 0) {
            if (data.mstate != MSTATE_RATELIMITING) {
                mstate(data, MSTATE_RATELIMITING);
            }
            Curl_expire_set(data, EXPIRE_TOOFAST, @max(send_ms, recv_ms), pnow);
            Curl_multi_clear_dirty(data);
            return CURLE_AGAIN;
        } else {
            send_ms = Curl_rlimit_next_step_ms(ul_rlimit, pnow);
            recv_ms = Curl_rlimit_next_step_ms(dl_rlimit, pnow);
            if (send_ms != 0 or recv_ms != 0) {
                var next_ms = @min(send_ms, recv_ms);
                if (next_ms == 0)
                    next_ms = @max(send_ms, recv_ms);
                Curl_expire_set(data, EXPIRE_TOOFAST, next_ms, pnow);
            }
        }
    }

    if (data.mstate != MSTATE_PERFORMING) {
        mstate(data, MSTATE_PERFORMING);
    }
    return CURLE_OK;
}

fn multistate_performing(
    data: *CurlEasyPrefix,
    stream_errorp: *bool,
    resultp: *CURLcode,
) CURLMcode {
    var newurl: ?[*:0]u8 = null;
    var retry: bool = false;
    var mresult: CURLMcode = CURLM_OK;
    var result: CURLcode = CURLE_OK;
    resultp.* = CURLE_OK;
    stream_errorp.* = false;

    if (mspeed_check(data) == CURLE_AGAIN)
        return CURLM_OK;

    result = Curl_sendrecv(data);

    if (Curl_zig_easy_req_done(data) or result == CURLE_RECV_ERROR) {
        const ret = Curl_retry_request(data, &newurl);
        if (ret == CURLE_OK) {
            retry = newurl != null;
        } else if (result == CURLE_OK) {
            result = ret;
        }

        if (retry) {
            result = CURLE_OK;
            Curl_zig_easy_set_req_done(data, true);
        }
    } else if (result == CURLE_HTTP2_STREAM and Curl_zig_easy_h2_downgrade_check(data)) {
        const ret = Curl_retry_request(data, &newurl);
        if (ret == CURLE_OK) {
            Curl_infof(data, "Downgrades to HTTP/1.1");
            if (data.conn) |conn| {
                Curl_zig_conn_set_bits_close(conn, true);
            }
            Curl_zig_easy_h2_downgrade_apply(data);
            if (newurl == null) {
                newurl = Curl_bufref_dup(Curl_zig_easy_url_bufref(data));
            }
            if (newurl == null) {
                result = CURLE_OUT_OF_MEMORY;
            } else {
                retry = true;
                result = CURLE_OK;
                Curl_zig_easy_set_req_done(data, true);
            }
        } else {
            result = ret;
        }
    }

    if (result != CURLE_OK) {
        if (data.conn) |conn| {
            if ((Curl_zig_conn_scheme_flags(conn) & PROTOPT_DUAL) == 0 and
                result != CURLE_HTTP2_STREAM)
            {
                Curl_zig_conn_set_bits_close(conn, true);
            }
        }
        multi_posttransfer(data);
        _ = multi_done(data, result, true);
    } else if ((Curl_zig_easy_req_done(data) and !Curl_cwriter_is_paused(data)) or retry) {
        const handler = if (data.conn) |conn| Curl_zig_conn_scheme(conn) else null;

        multi_posttransfer(data);

        if (Curl_zig_easy_req_newurl(data) != null or retry) {
            var follow: c_int = FOLLOW_NONE;
            if (!retry) {
                mem.curl_free_fn(@ptrCast(newurl));
                newurl = Curl_zig_easy_req_newurl(data);
                Curl_zig_easy_clear_req_newurl(data);
                follow = FOLLOW_REDIR;
            } else {
                follow = FOLLOW_RETRY;
            }
            _ = multi_done(data, CURLE_OK, retry);
            result = multi_follow(data, handler, newurl, follow);
            if (result == CURLE_OK) {
                mstate(data, MSTATE_SETUP);
                mresult = CURLM_CALL_MULTI_PERFORM;
            }
        } else {
            if (Curl_zig_easy_req_location(data)) |loc| {
                mem.curl_free_fn(@ptrCast(newurl));
                newurl = loc;
                Curl_zig_easy_clear_req_location(data);
                result = multi_follow(data, handler, newurl, FOLLOW_FAKE);
                if (result != CURLE_OK) {
                    stream_errorp.* = true;
                    result = multi_done(data, result, true);
                }
            }

            if (result == CURLE_OK) {
                mstate(data, MSTATE_DONE);
                mresult = CURLM_CALL_MULTI_PERFORM;
            }
        }
    } else {
        _ = mspeed_check(data);
    }

    mem.curl_free_fn(@ptrCast(newurl));
    resultp.* = result;
    return mresult;
}

fn multistate_do(
    data: *CurlEasyPrefix,
    stream_errorp: *bool,
    resultp: *CURLcode,
) CURLMcode {
    var mresult: CURLMcode = CURLM_OK;
    var result: CURLcode = CURLE_OK;

    var has_fprereq: bool = false;
    const prereq_rc = Curl_zig_easy_call_fprereq(data, &has_fprereq);
    if (has_fprereq and prereq_rc != CURL_PREREQFUNC_OK) {
        Curl_failf(data, "operation aborted by pre-request callback");
        result = CURLE_ABORTED_BY_CALLBACK;
        multi_posttransfer(data);
        _ = multi_done(data, result, false);
        stream_errorp.* = true;
        resultp.* = result;
        return mresult;
    }

    if (Curl_zig_easy_set_connect_only_non_ws(data)) {
        mstate(data, MSTATE_DONE);
        mresult = CURLM_CALL_MULTI_PERFORM;
    } else {
        var dophase_done: bool = false;
        result = multi_do(data, &dophase_done);

        if (result == CURLE_OK) {
            if (!dophase_done) {
                if (Curl_zig_easy_state_wildcardmatch(data)) {
                    if (Curl_zig_easy_wildcard_is_done_or_skip(data)) {
                        _ = multi_done(data, CURLE_OK, false);
                        mstate(data, if (data.conn != null) MSTATE_DONE else MSTATE_COMPLETED);
                        mresult = CURLM_CALL_MULTI_PERFORM;
                        resultp.* = result;
                        return mresult;
                    }
                }
                mstate(data, MSTATE_DOING);
                mresult = CURLM_CALL_MULTI_PERFORM;
            } else if (data.conn != null and Curl_zig_conn_bits_do_more(data.conn.?)) {
                mstate(data, MSTATE_DOING_MORE);
                mresult = CURLM_CALL_MULTI_PERFORM;
            } else {
                mstate(data, MSTATE_DID);
                mresult = CURLM_CALL_MULTI_PERFORM;
            }
        } else if (result == CURLE_SEND_ERROR and data.conn != null and Curl_zig_conn_bits_reuse(data.conn.?)) {
            const handler = Curl_zig_conn_scheme(data.conn.?);
            var newurl: ?[*:0]u8 = null;
            var drc = Curl_retry_request(data, &newurl);
            if (drc != CURLE_OK) {
                result = drc;
                stream_errorp.* = true;
            }

            multi_posttransfer(data);
            drc = multi_done(data, result, false);

            if (newurl != null) {
                if (drc == CURLE_OK or drc == CURLE_SEND_ERROR) {
                    drc = multi_follow(data, handler, newurl, FOLLOW_RETRY);
                    if (drc == CURLE_OK) {
                        mstate(data, MSTATE_SETUP);
                        mresult = CURLM_CALL_MULTI_PERFORM;
                        result = CURLE_OK;
                    } else {
                        result = drc;
                    }
                } else {
                    result = drc;
                }
            } else {
                stream_errorp.* = true;
            }
            mem.curl_free_fn(@ptrCast(newurl));
        } else {
            multi_posttransfer(data);
            if (data.conn != null) {
                _ = multi_done(data, result, false);
            }
            stream_errorp.* = true;
        }
    }

    resultp.* = result;
    return mresult;
}

fn multistate_ratelimiting(
    data: *CurlEasyPrefix,
    resultp: *CURLcode,
) CURLMcode {
    var mresult: CURLMcode = CURLM_OK;
    const result = Curl_pgrsCheck(data);

    if (result != CURLE_OK) {
        if (data.conn) |conn| {
            if ((Curl_zig_conn_scheme_flags(conn) & PROTOPT_DUAL) == 0 and
                result != CURLE_HTTP2_STREAM)
            {
                Curl_zig_conn_set_bits_close(conn, true);
            }
        }
        multi_posttransfer(data);
        _ = multi_done(data, result, true);
    } else {
        if (mspeed_check(data) == CURLE_OK) {
            mresult = CURLM_CALL_MULTI_PERFORM;
        }
    }
    resultp.* = result;
    return mresult;
}

fn multistate_connect(
    multi: *CurlMultiPrefix,
    data: *CurlEasyPrefix,
    resultp: *CURLcode,
) CURLMcode {
    var connected: bool = false;
    var mresult: CURLMcode = CURLM_OK;
    const result = Curl_connect(data, &connected);

    if (result == CURLE_NO_CONNECTION_AVAILABLE) {
        mstate(data, MSTATE_PENDING);
        containers.Curl_uint32_bset_remove(&multi.process, data.mid);
        containers.Curl_uint32_bset_remove(&multi.dirty, data.mid);
        _ = containers.Curl_uint32_bset_add(&multi.pending, data.mid);
        resultp.* = CURLE_OK;
        return mresult;
    } else if (data.multi) |m| {
        multi_schedule_pending(m);
    }

    if (result == CURLE_OK) {
        mresult = CURLM_CALL_MULTI_PERFORM;
        if (connected) {
            if (data.conn) |conn| {
                if (!Curl_zig_conn_bits_reuse(conn) and
                    Curl_conn_is_multiplex(conn, FIRSTSOCKET))
                {
                    if (data.multi) |m| {
                        multi_schedule_pending(m);
                    }
                }
            }
            mstate(data, MSTATE_PROTOCONNECT);
        } else {
            mstate(data, MSTATE_CONNECTING);
        }
    }
    resultp.* = result;
    return mresult;
}

fn is_finished(
    multi: *CurlMultiPrefix,
    data: *CurlEasyPrefix,
    pnow: *const curltime,
    stream_error: bool,
    result_arg: CURLcode,
) CURLcode {
    var result = result_arg;
    if (data.mstate < MSTATE_COMPLETED) {
        if (result != CURLE_OK) {
            multi_schedule_pending(multi);

            if (data.conn) |conn| {
                if (stream_error) {
                    const dead_connection = result == CURLE_OPERATION_TIMEDOUT;
                    Curl_detach_connection(data);
                    Curl_conn_close(data, conn, dead_connection);
                }
            } else if (data.mstate == MSTATE_CONNECT) {
                multi_posttransfer(data);
                Curl_pgrsUpdate_nometer(data);
            }

            mstate(data, MSTATE_COMPLETED);
            return result;
        } else if (data.conn != null and Curl_conn_is_connected(data.conn.?, FIRSTSOCKET)) {
            result = Curl_pgrsUpdateX(data, pnow);
            if (result != CURLE_OK) {
                Curl_zig_conn_set_bits_close(data.conn.?, true);
                if (data.mstate < MSTATE_DONE) {
                    mstate(data, MSTATE_DONE);
                }
                return result;
            }
        }
    }
    return result;
}

fn handle_completed(
    multi: *CurlMultiPrefix,
    data: *CurlEasyPrefix,
    result: CURLcode,
) void {
    const master_mid = Curl_zig_easy_master_mid(data);
    const msg_to_app = master_mid == std.math.maxInt(u32);

    if (!msg_to_app) {
        if (Curl_zig_easy_sub_xfer_done(data)) |cb| {
            if (Curl_multi_get_easy(multi, master_mid)) |master| {
                cb(data, master, result);
            }
        }
    } else {
        _ = Curl_zig_easy_set_msg_done(data, result);
    }
    mstate(data, MSTATE_MSGSENT);

    containers.Curl_uint32_bset_remove(&multi.process, data.mid);
    containers.Curl_uint32_bset_remove(&multi.dirty, data.mid);
    containers.Curl_uint32_bset_remove(&multi.pending, data.mid);
    if (msg_to_app) {
        multi_addmsg(multi, data);
    }
    if (Curl_zig_easy_state_really_alive(data)) {
        Curl_zig_easy_set_state_really_alive(data, false);
        multi.xfers_really_alive -= 1;
        if (multi.xfers_really_alive == 0) {
            _ = multi_assess_wakeup(multi);
        }
    }
    multi.xfers_alive -= 1;
    if (multi.xfers_alive == 0) {
        _ = multi_assess_wakeup(multi);
    }
}

fn multistate_init(data: *CurlEasyPrefix, result: *CURLcode) CURLMcode {
    if (!Curl_zig_easy_state_really_alive(data)) {
        Curl_zig_easy_set_state_really_alive(data, true);
        if (data.multi) |multi| {
            multi.xfers_really_alive += 1;
            if (multi.xfers_really_alive == 1) {
                const mresult = multi_assess_wakeup(multi);
                if (mresult != CURLM_OK) {
                    Curl_failf(data, "error enabling wakeup listening: %d", mresult);
                    return mresult;
                }
            }
        }
    }

    result.* = Curl_pretransfer(data);
    if (result.* != CURLE_OK)
        return CURLM_OK;

    mstate(data, MSTATE_SETUP);
    Curl_pgrsTime(data, TIMER_STARTOP);
    return CURLM_CALL_MULTI_PERFORM;
}

fn multistate_setup(data: *CurlEasyPrefix) CURLMcode {
    const pnow = Curl_pgrs_now(data);
    Curl_pgrsTimeWas(data, TIMER_STARTSINGLE, pnow.*);
    const timeout_ms = Curl_zig_easy_set_timeout_ms(data);
    if (timeout_ms != 0) {
        Curl_expire_set(data, EXPIRE_TIMEOUT, timeout_ms, pnow);
    }
    const connecttimeout_ms = Curl_zig_easy_set_connecttimeout_ms(data);
    if (connecttimeout_ms != 0) {
        Curl_expire_set(data, EXPIRE_CONNECTTIMEOUT, connecttimeout_ms, pnow);
    }

    mstate(data, MSTATE_CONNECT);
    return CURLM_CALL_MULTI_PERFORM;
}

fn multistate_connecting(
    data: *CurlEasyPrefix,
    stream_error: *bool,
    result: *CURLcode,
) CURLMcode {
    var connected: bool = false;

    if (data.conn == null) {
        result.* = CURLE_FAILED_INIT;
        return CURLM_OK;
    }
    if (!Curl_xfer_recv_is_paused(data)) {
        result.* = Curl_conn_connect(data, FIRSTSOCKET, false, &connected);
        if (connected and result.* == CURLE_OK) {
            if (data.conn) |conn| {
                if (!Curl_zig_conn_bits_reuse(conn) and
                    Curl_conn_is_multiplex(conn, FIRSTSOCKET))
                {
                    if (data.multi) |multi| {
                        multi_schedule_pending(multi);
                    }
                }
            }
            mstate(data, MSTATE_PROTOCONNECT);
            return CURLM_CALL_MULTI_PERFORM;
        } else if (result.* != CURLE_OK) {
            multi_posttransfer(data);
            _ = multi_done(data, result.*, true);
            stream_error.* = true;
            return CURLM_OK;
        }
    }
    return CURLM_OK;
}

fn multistate_protoconnect(
    data: *CurlEasyPrefix,
    stream_error: *bool,
    result: *CURLcode,
) CURLMcode {
    var protocol_connected: bool = false;

    if (result.* == CURLE_OK and data.conn != null and Curl_zig_conn_bits_reuse(data.conn.?)) {
        mstate(data, MSTATE_DO);
        return CURLM_CALL_MULTI_PERFORM;
    }
    if (result.* == CURLE_OK) {
        result.* = protocol_connect(data, &protocol_connected);
    }
    if (result.* == CURLE_OK and !protocol_connected) {
        mstate(data, MSTATE_PROTOCONNECTING);
        return CURLM_CALL_MULTI_PERFORM;
    } else if (result.* == CURLE_OK) {
        mstate(data, MSTATE_DO);
        return CURLM_CALL_MULTI_PERFORM;
    }

    multi_posttransfer(data);
    _ = multi_done(data, result.*, true);
    stream_error.* = true;
    return CURLM_OK;
}

fn multistate_protoconnecting(
    data: *CurlEasyPrefix,
    stream_error: *bool,
    result: *CURLcode,
) CURLMcode {
    var protocol_connected: bool = false;

    result.* = protocol_connecting(data, &protocol_connected);
    if (result.* == CURLE_OK and protocol_connected) {
        mstate(data, MSTATE_DO);
        return CURLM_CALL_MULTI_PERFORM;
    } else if (result.* != CURLE_OK) {
        multi_posttransfer(data);
        _ = multi_done(data, result.*, true);
        stream_error.* = true;
    }
    return CURLM_OK;
}

fn multistate_doing(
    data: *CurlEasyPrefix,
    stream_error: *bool,
    result: *CURLcode,
) CURLMcode {
    var dophase_done: bool = false;

    result.* = protocol_doing(data, &dophase_done);
    if (result.* == CURLE_OK) {
        if (dophase_done) {
            const do_more = if (data.conn) |c| Curl_zig_conn_bits_do_more(c) else false;
            mstate(data, if (do_more) MSTATE_DOING_MORE else MSTATE_DID);
            return CURLM_CALL_MULTI_PERFORM;
        }
    } else {
        multi_posttransfer(data);
        _ = multi_done(data, result.*, false);
        stream_error.* = true;
    }
    return CURLM_OK;
}

fn multistate_doing_more(
    data: *CurlEasyPrefix,
    stream_error: *bool,
    result: *CURLcode,
) CURLMcode {
    var control: c_int = DOMORE_INCOMPLETE;

    result.* = multi_do_more(data, &control);
    if (result.* == CURLE_OK) {
        if (control != DOMORE_INCOMPLETE) {
            mstate(data, if (control == DOMORE_DONE) MSTATE_DID else MSTATE_DOING);
            return CURLM_CALL_MULTI_PERFORM;
        }
    } else {
        multi_posttransfer(data);
        _ = multi_done(data, result.*, false);
        stream_error.* = true;
    }
    return CURLM_OK;
}

fn multistate_did(
    multi: *CurlMultiPrefix,
    data: *CurlEasyPrefix,
) CURLMcode {
    const conn = data.conn.?;
    if (Curl_zig_conn_bits_multiplex(conn)) {
        multi_schedule_pending(multi);
    }

    if (connSockIdxValid(Curl_zig_conn_recv_idx(conn)) or
        connSockIdxValid(Curl_zig_conn_send_idx(conn)))
    {
        mstate(data, MSTATE_PERFORMING);
        if (multi.xfers_alive > 1 and
            (Curl_zig_conn_scheme_protocol(conn) & PROTO_FAMILY_HTTP) != 0)
        {
            return CURLM_OK;
        }
        return CURLM_CALL_MULTI_PERFORM;
    } else {
        if (Curl_zig_easy_state_wildcardmatch(data) and
            (Curl_zig_conn_scheme_flags(conn) & PROTOPT_WILDCARD) == 0)
        {
            Curl_zig_easy_wildcard_set_done(data);
        }
        mstate(data, MSTATE_DONE);
        return CURLM_CALL_MULTI_PERFORM;
    }
}

fn multistate_done(
    data: *CurlEasyPrefix,
    presult: *CURLcode,
) CURLMcode {
    if (data.conn != null) {
        const result = multi_done(data, presult.*, false);
        if (presult.* == CURLE_OK) {
            presult.* = result;
        }
    }

    if (Curl_zig_easy_state_wildcardmatch(data)) {
        if (!Curl_zig_easy_wildcard_is_done(data)) {
            mstate(data, MSTATE_INIT);
            return CURLM_CALL_MULTI_PERFORM;
        }
    }

    mstate(data, MSTATE_COMPLETED);
    return CURLM_CALL_MULTI_PERFORM;
}

fn multi_runsingle(
    multi: *CurlMultiPrefix,
    data: *CurlEasyPrefix,
    sigpipe_ctx: *SigpipeIgnoreBuf,
) CURLMcode {
    var mresult: CURLMcode = CURLM_OK;
    var result: CURLcode = CURLE_OK;
    var pnow: ?*const curltime = null;

    if (Curl_zig_multi_dead(multi)) {
        result = CURLE_ABORTED_BY_CALLBACK;
        multi_posttransfer(data);
        _ = multi_done(data, result, false);
        mstate(data, MSTATE_COMPLETED);
    }

    Curl_zig_multi_warn_debug(multi, data);

    containers.Curl_uint32_bset_remove(&multi.dirty, data.mid);

    if (multi.admin == data) {
        Curl_zig_multi_consume_internal_wakeup(multi, true);
        Curl_zig_multi_async_thrdd_process(multi);
        Curl_cshutdn_perform(Curl_zig_multi_cshutdn(multi), multi.admin, sigpipe_ctx);
        data.result = result;
        return mresult;
    }

    Curl_cshutdn_sigpipe_apply_c(data, sigpipe_ctx);

    while (true) {
        var stream_error: bool = false;
        mresult = CURLM_OK;
        pnow = null;

        if (multi_ischanged(multi, true)) {
            multi_schedule_pending(multi);
        }

        if (data.mstate > MSTATE_CONNECT and data.mstate < MSTATE_COMPLETED) {
            if (data.conn == null) {
                mresult = CURLM_INTERNAL_ERROR;
                data.result = result;
                return mresult;
            }
        }

        var timed_out: bool = false;
        if (data.mstate >= MSTATE_CONNECT and data.mstate < MSTATE_COMPLETED) {
            pnow = Curl_pgrs_now(data);
            if (multi_handle_timeout(data, pnow.?, &stream_error, &result)) {
                timed_out = true;
            } else {
                pnow = null;
            }
        }

        if (!timed_out) {
            switch (data.mstate) {
                MSTATE_INIT => {
                    mresult = multistate_init(data, &result);
                },
                MSTATE_SETUP => {
                    mresult = multistate_setup(data);
                },
                MSTATE_CONNECT => {
                    mresult = multistate_connect(multi, data, &result);
                },
                MSTATE_CONNECTING => {
                    mresult = multistate_connecting(data, &stream_error, &result);
                },
                MSTATE_PROTOCONNECT => {
                    mresult = multistate_protoconnect(data, &stream_error, &result);
                },
                MSTATE_PROTOCONNECTING => {
                    mresult = multistate_protoconnecting(data, &stream_error, &result);
                },
                MSTATE_DO => {
                    mresult = multistate_do(data, &stream_error, &result);
                },
                MSTATE_DOING => {
                    mresult = multistate_doing(data, &stream_error, &result);
                },
                MSTATE_DOING_MORE => {
                    mresult = multistate_doing_more(data, &stream_error, &result);
                },
                MSTATE_DID => {
                    mresult = multistate_did(multi, data);
                },
                MSTATE_RATELIMITING => {
                    mresult = multistate_ratelimiting(data, &result);
                },
                MSTATE_PERFORMING => {
                    mresult = multistate_performing(data, &stream_error, &result);
                },
                MSTATE_DONE => {
                    mresult = multistate_done(data, &result);
                },
                MSTATE_COMPLETED,
                MSTATE_PENDING,
                MSTATE_MSGSENT,
                => {},
                else => {
                    mresult = CURLM_INTERNAL_ERROR;
                    data.result = result;
                    return mresult;
                },
            }

            if (data.mstate >= MSTATE_CONNECT and
                data.mstate < MSTATE_DO and
                mresult != CURLM_CALL_MULTI_PERFORM and
                !multi_ischanged(multi, false))
            {
                pnow = Curl_pgrs_now(data);
                _ = multi_handle_timeout(data, pnow.?, &stream_error, &result);
            }
        }

        if (pnow == null) {
            pnow = Curl_pgrs_now(data);
        }
        result = is_finished(multi, data, pnow.?, stream_error, result);
        if (result != CURLE_OK) {
            mresult = CURLM_CALL_MULTI_PERFORM;
        }

        if (data.mstate == MSTATE_COMPLETED) {
            handle_completed(multi, data, result);
            mresult = CURLM_OK;
            data.result = result;
            return mresult;
        }

        if (mresult != CURLM_CALL_MULTI_PERFORM and !multi_ischanged(multi, false))
            break;
    }

    data.result = result;
    return mresult;
}

fn multi_perform(
    multi: *CurlMultiPrefix,
    running_handles: ?*c_int,
) CURLMcode {
    var returncode: CURLMcode = CURLM_OK;
    var start: curltime = .{ .tv_sec = 0, .tv_usec = 0 };
    var tnow: time_net.curltime = .{ .tv_sec = 0, .tv_usec = 0 };
    var mid: u32 = 0;
    var sigpipe_ctx: SigpipeIgnoreBuf = .{};

    time_net.curlx_pnow(&tnow);
    start.tv_sec = tnow.tv_sec;
    start.tv_usec = tnow.tv_usec;

    Curl_cshutdn_sigpipe_init_c(&sigpipe_ctx);

    if (containers.Curl_uint32_bset_first(&multi.process, &mid)) {
        while (true) {
            if (Curl_multi_get_easy(multi, mid)) |data| {
                const mresult = multi_runsingle(multi, data, &sigpipe_ctx);
                if (mresult != CURLM_OK) {
                    returncode = mresult;
                }
            } else {
                containers.Curl_uint32_bset_remove(&multi.process, mid);
                containers.Curl_uint32_bset_remove(&multi.dirty, mid);
            }
            if (!containers.Curl_uint32_bset_next(&multi.process, mid, &mid))
                break;
        }
    }
    Curl_cshutdn_sigpipe_restore_c(&sigpipe_ctx);

    if (multi_ischanged(multi, true)) {
        multi_schedule_pending(multi);
    }

    if (returncode == CURLM_OK and Curl_zig_multi_ntfy_has_entries(multi)) {
        returncode = containers.Curl_mntfy_dispatch_all(multi, Curl_zig_multi_ntfy(multi), multi.admin);
    }

    while (containers.Curl_timeouts_remove_expired(&multi.timeouts, &start, &mid)) {
        if (Curl_multi_get_easy(multi, mid)) |data| {
            _ = add_next_timeout(&start, multi, data);
            if (data.mstate == MSTATE_PENDING) {
                var stream_unused: bool = false;
                var result_unused: CURLcode = CURLE_OK;
                if (multi_handle_timeout(data, Curl_pgrs_now(data), &stream_unused, &result_unused)) {
                    Curl_infof(data, "PENDING handle timeout");
                    move_pending_to_connect(multi, data);
                }
            }
        }
    }

    if (running_handles) |rh| {
        const running = multi_xfers_running(multi);
        rh.* = if (running < @as(u32, @intCast(std.math.maxInt(c_int))))
            @intCast(running)
        else
            std.math.maxInt(c_int);
    }

    if (returncode <= CURLM_OK) {
        returncode = Curl_update_timer(multi);
    }

    return returncode;
}

pub export fn curl_multi_perform(
    m: ?*CurlMultiPrefix,
    running_handles: ?*c_int,
) callconv(.c) CURLMcode {
    var guard: CurlMapiGuard = undefined;
    var mresult: CURLMcode = CURLM_OK;

    if (api_mod.Curl_mapi_enter(&guard, m, CURL_MAPI_FN_multi_perform, &mresult)) {
        mresult = multi_perform(m.?, running_handles);
    }
    api_mod.Curl_mapi_leave(&guard);
    return mresult;
}

pub export fn curl_multi_cleanup(m: ?*CurlMultiPrefix) callconv(.c) CURLMcode {
    var guard: CurlMapiGuard = undefined;
    var mresult: CURLMcode = CURLM_OK;

    if (api_mod.Curl_mapi_enter(&guard, m, CURL_MAPI_FN_multi_cleanup, &mresult)) {
        const multi = m.?;
        var entry: ?*anyopaque = null;
        var mid: u32 = 0;

        if (containers.Curl_uint32_tbl_first(&multi.xfers, &mid, &entry)) {
            while (true) {
                const data: ?*CurlEasyPrefix = if (entry) |e| @ptrCast(@alignCast(e)) else null;
                if (!goodEasyHandle(data)) {
                    mresult = CURLM_BAD_HANDLE;
                    api_mod.Curl_mapi_leave(&guard);
                    return mresult;
                }
                const d = data.?;
                if (multi.admin != d) {
                    if (!Curl_zig_easy_state_done(d) and d.conn != null) {
                        _ = multi_done(d, CURLE_OK, true);
                    }
                    d.multi = null;
                    containers.Curl_uint32_tbl_remove(&multi.xfers, mid);
                    d.mid = std.math.maxInt(u32);
                    Curl_zig_easy_clear_psl_if_multi(d, multi);
                    if (Curl_zig_easy_state_internal(d)) {
                        var close_ptr: ?*CurlEasyPrefix = d;
                        _ = Curl_close(&close_ptr);
                    }
                }
                if (!containers.Curl_uint32_tbl_next(&multi.xfers, mid, &mid, &entry))
                    break;
            }
        }

        Curl_zig_multi_destroy_async_thrdd(multi, !Curl_zig_multi_quick_exit(multi));
        Curl_cpool_destroy(Curl_zig_multi_cpool(multi), multi.admin);
        Curl_cshutdn_destroy(Curl_zig_multi_cshutdn(multi), multi.admin);
        if (multi.admin) |admin| {
            admin.multi = null;
            containers.Curl_uint32_tbl_remove(&multi.xfers, admin.mid);
            _ = Curl_close(&multi.admin);
        }

        multi.magic = 0;

        altsvc_mod.Curl_multi_ev_cleanup(multi);
        collections.Curl_hash_destroy(Curl_zig_multi_proto_hash(multi));
        Curl_dnscache_destroy(&multi.dnscache);
        Curl_zig_multi_free_optional_fields(multi);

        multi_xfer_bufs_free(multi);
        containers.Curl_mntfy_cleanup(multi, Curl_zig_multi_ntfy(multi));

        containers.Curl_uint32_bset_destroy(&multi.process);
        containers.Curl_uint32_bset_destroy(&multi.dirty);
        containers.Curl_uint32_bset_destroy(&multi.pending);
        containers.Curl_uint32_bset_destroy(&multi.msgsent);
        containers.Curl_uint32_tbl_destroy(&multi.xfers);

        const multi_bytes: [*]u8 = @ptrCast(multi);
        @memset(multi_bytes[0..Curl_zig_multi_sizeof()], 0);
        mem.curl_free_fn(multi);

        mresult = CURLM_OK;
    }
    api_mod.Curl_mapi_leave(&guard);
    return mresult;
}

pub export fn curl_multi_info_read(
    m: ?*CurlMultiPrefix,
    msgs_in_queue: ?*c_int,
) callconv(.c) ?*CURLMsg {
    var guard: CurlMapiGuard = undefined;
    var msg_result: ?*CURLMsg = null;

    if (msgs_in_queue) |q| {
        q.* = 0;
    }
    if (api_mod.Curl_mapi_enter(&guard, m, CURL_MAPI_FN_multi_info_read, null)) {
        const multi = m.?;
        var mid: u32 = 0;
        if (containers.Curl_uint32_bset_first(&multi.msgsent, &mid)) {
            const data = Curl_multi_get_easy(multi, mid);
            containers.Curl_uint32_bset_remove(&multi.msgsent, mid);
            if (msgs_in_queue) |q| {
                const count = containers.Curl_uint32_bset_count(&multi.msgsent);
                q.* = @intCast(@min(count, @as(u32, @intCast(std.math.maxInt(c_int)))));
            }
            if (data) |d| {
                msg_result = Curl_zig_easy_msg_ptr(d);
            }
        }
    }
    api_mod.Curl_mapi_leave(&guard);
    return msg_result;
}

pub export fn Curl_multi_will_close(
    data: ?*CurlEasyPrefix,
    s: curl_socket_t,
) callconv(.c) void {
    const d = data orelse return;
    const multi = d.multi orelse return;
    altsvc_mod.Curl_multi_ev_socket_done(multi, d, s);
}

fn add_next_timeout(
    pnow: *const curltime,
    multi: *CurlMultiPrefix,
    data: *CurlEasyPrefix,
) CURLMcode {
    const first_ptr = Curl_zig_easy_timeouts_first_ptr(data);
    const next_ptr = Curl_zig_easy_timeouts_next_ptr(data);
    const offset_us_ptr = Curl_zig_easy_timeouts_offset_us_ptr(data);
    const now_us = containers.Curl_timeouts_offset_us(&multi.timeouts, pnow);

    while (first_ptr.* < EXPIRE_LAST) {
        if (offset_us_ptr[first_ptr.*] <= now_us) {
            first_ptr.* = next_ptr[first_ptr.*];
        } else {
            break;
        }
    }

    if (first_ptr.* < EXPIRE_LAST) {
        containers.Curl_timeouts_add(&multi.timeouts, data, offset_us_ptr[first_ptr.*]);
    }
    return CURLM_OK;
}

fn multi_mark_expired_as_dirty(
    multi: *CurlMultiPrefix,
    ts: *const curltime,
) void {
    var mid: u32 = 0;
    while (containers.Curl_timeouts_remove_expired(&multi.timeouts, ts, &mid)) {
        if (Curl_multi_get_easy(multi, mid)) |data| {
            _ = add_next_timeout(ts, multi, data);
            Curl_multi_mark_dirty(data);
        }
    }
}

fn multi_run_dirty(
    multi: *CurlMultiPrefix,
    sigpipe_ctx: *SigpipeIgnoreBuf,
    pnum: *u32,
) CURLMcode {
    var mresult: CURLMcode = CURLM_OK;
    var mid: u32 = 0;

    pnum.* = 0;
    if (containers.Curl_uint32_bset_first(&multi.dirty, &mid)) {
        while (true) {
            if (Curl_multi_get_easy(multi, mid)) |data| {
                if (!containers.Curl_uint32_bset_contains(&multi.process, mid)) {
                    if (containers.Curl_uint32_bset_contains(&multi.pending, mid)) {
                        move_pending_to_connect(multi, data);
                    } else {
                        containers.Curl_uint32_bset_remove(&multi.dirty, mid);
                        if (!containers.Curl_uint32_bset_next(&multi.dirty, mid, &mid))
                            break;
                        continue;
                    }
                }

                pnum.* += 1;
                mresult = multi_runsingle(multi, data, sigpipe_ctx);
                if (mresult <= CURLM_OK) {
                    mresult = altsvc_mod.Curl_multi_ev_assess_xfer(multi, data);
                    if (mresult != CURLM_OK)
                        return mresult;
                }
            } else {
                containers.Curl_uint32_bset_remove(&multi.dirty, mid);
            }
            if (!containers.Curl_uint32_bset_next(&multi.dirty, mid, &mid))
                break;
        }
    }
    return mresult;
}

fn multi_socket(
    multi: *CurlMultiPrefix,
    checkall: bool,
    s: curl_socket_t,
    ev_bitmask: c_int,
    running_handles: ?*c_int,
) CURLMcode {
    var mresult: CURLMcode = CURLM_OK;
    var pipe_ctx: SigpipeIgnoreBuf = .{};
    var now: curltime = .{ .tv_sec = 0, .tv_usec = 0 };
    var tnow: time_net.curltime = .{ .tv_sec = 0, .tv_usec = 0 };
    var run_xfers: u32 = 0;

    _ = ev_bitmask;
    Curl_cshutdn_sigpipe_init_c(&pipe_ctx);

    if (checkall) {
        mresult = multi_perform(multi, running_handles);
        if (mresult != CURLM_BAD_HANDLE) {
            mresult = altsvc_mod.Curl_multi_ev_assess_xfer_bset(multi, &multi.process);
        }
        return finishMultiSocket(multi, &pipe_ctx, running_handles, mresult);
    }

    if (s != CURL_SOCKET_TIMEOUT) {
        altsvc_mod.Curl_multi_ev_dirty_xfers(multi, s);
    } else {
        Curl_zig_multi_set_last_expire_offset_us(multi, 0);
        mresult = multi_assess_wakeup(multi);
        if (mresult != CURLM_OK) {
            return finishMultiSocket(multi, &pipe_ctx, running_handles, mresult);
        }
    }

    time_net.curlx_pnow(&tnow);
    now.tv_sec = tnow.tv_sec;
    now.tv_usec = tnow.tv_usec;
    multi_mark_expired_as_dirty(multi, &now);
    mresult = multi_run_dirty(multi, &pipe_ctx, &run_xfers);
    if (mresult != CURLM_OK) {
        return finishMultiSocket(multi, &pipe_ctx, running_handles, mresult);
    }

    if (run_xfers != 0) {
        time_net.curlx_pnow(&tnow);
        now.tv_sec = tnow.tv_sec;
        now.tv_usec = tnow.tv_usec;
        multi_mark_expired_as_dirty(multi, &now);
        mresult = multi_run_dirty(multi, &pipe_ctx, &run_xfers);
    }

    return finishMultiSocket(multi, &pipe_ctx, running_handles, mresult);
}

fn finishMultiSocket(
    multi: *CurlMultiPrefix,
    pipe_ctx: *SigpipeIgnoreBuf,
    running_handles: ?*c_int,
    mresult_arg: CURLMcode,
) CURLMcode {
    var mresult = mresult_arg;
    Curl_cshutdn_sigpipe_restore_c(pipe_ctx);

    if (multi_ischanged(multi, true)) {
        multi_schedule_pending(multi);
    }

    if (mresult == CURLM_OK and Curl_zig_multi_ntfy_has_entries(multi)) {
        mresult = containers.Curl_mntfy_dispatch_all(multi, Curl_zig_multi_ntfy(multi), multi.admin);
    }

    if (running_handles) |rh| {
        const running = multi_xfers_running(multi);
        rh.* = if (running < @as(u32, @intCast(std.math.maxInt(c_int))))
            @intCast(running)
        else
            std.math.maxInt(c_int);
    }

    if (mresult <= CURLM_OK) {
        mresult = Curl_update_timer(multi);
    }
    return mresult;
}

fn curlx_sltouz(slnum: c_long, puznum: *usize) bool {
    if (slnum < 0)
        return false;
    puznum.* = @intCast(slnum);
    return true;
}

const use_c_vastart = switch (builtin.cpu.arch) {
    .x86_64 => builtin.os.tag != .windows,
    .aarch64, .aarch64_be => builtin.os.tag.isDarwin(),
    else => false,
};

fn multi_setopt_apply(
    multi: *CurlMultiPrefix,
    option: CURLMoption,
    arg_usize: usize,
    arg_long: c_long,
) CURLMcode {
    var mresult: CURLMcode = CURLM_OK;
    var szarg: usize = 0;

    switch (option) {
        CURLMOPT_SOCKETFUNCTION => {
            multi.socket_cb = if (arg_usize == 0) null else @ptrFromInt(arg_usize);
        },
        CURLMOPT_SOCKETDATA => {
            multi.socket_userp = if (arg_usize == 0) null else @ptrFromInt(arg_usize);
        },
        CURLMOPT_PUSHFUNCTION => {
            multi.push_cb = if (arg_usize == 0) null else @ptrFromInt(arg_usize);
        },
        CURLMOPT_PUSHDATA => {
            multi.push_userp = if (arg_usize == 0) null else @ptrFromInt(arg_usize);
        },
        CURLMOPT_PIPELINING => {
            Curl_zig_multi_set_multiplexing(multi, (arg_long & CURLPIPE_MULTIPLEX) != 0);
        },
        CURLMOPT_TIMERFUNCTION => {
            const cb: curl_multi_timer_callback = if (arg_usize == 0) null else @ptrFromInt(arg_usize);
            Curl_zig_multi_set_timer_cb(multi, cb);
        },
        CURLMOPT_TIMERDATA => {
            Curl_zig_multi_set_timer_userp(multi, if (arg_usize == 0) null else @ptrFromInt(arg_usize));
        },
        CURLMOPT_MAXCONNECTS => {
            const uarg: c_ulong = @bitCast(arg_long);
            if (uarg <= std.math.maxInt(u32)) {
                Curl_zig_multi_set_maxconnects(multi, @intCast(uarg));
            }
        },
        CURLMOPT_MAX_HOST_CONNECTIONS => {
            if (!curlx_sltouz(arg_long, &szarg))
                mresult = CURLM_BAD_FUNCTION_ARGUMENT;
            const capped: u32 = if (szarg < std.math.maxInt(u32)) @intCast(szarg) else std.math.maxInt(u32);
            Curl_zig_multi_set_max_host_connections(multi, capped);
        },
        CURLMOPT_MAX_TOTAL_CONNECTIONS => {
            if (!curlx_sltouz(arg_long, &szarg))
                mresult = CURLM_BAD_FUNCTION_ARGUMENT;
            const capped: u32 = if (szarg < std.math.maxInt(u32)) @intCast(szarg) else std.math.maxInt(u32);
            Curl_zig_multi_set_max_total_connections(multi, capped);
        },
        CURLMOPT_MAX_PIPELINE_LENGTH,
        CURLMOPT_CONTENT_LENGTH_PENALTY_SIZE,
        CURLMOPT_CHUNK_LENGTH_PENALTY_SIZE,
        CURLMOPT_PIPELINING_SITE_BL,
        CURLMOPT_PIPELINING_SERVER_BL,
        => {},
        CURLMOPT_MAX_CONCURRENT_STREAMS => {
            if (!curlx_sltouz(arg_long, &szarg) or szarg == 0 or szarg > @as(usize, @intCast(std.math.maxInt(c_int)))) {
                multi.max_concurrent_streams = 100;
            } else {
                multi.max_concurrent_streams = if (szarg < std.math.maxInt(u32)) @intCast(szarg) else std.math.maxInt(u32);
            }
        },
        CURLMOPT_NETWORK_CHANGED => {
            var val = arg_long;
            if ((val & CURLMNWC_CLEAR_ALL) != 0)
                val = CURLMNWC_CLEAR_DNS | CURLMNWC_CLEAR_CONNS;
            if ((val & CURLMNWC_CLEAR_DNS) != 0) {
                if (multi.admin) |admin|
                    Curl_dnscache_clear(admin);
            }
            if ((val & CURLMNWC_CLEAR_CONNS) != 0) {
                if (multi.admin) |admin|
                    Curl_cpool_nw_changed(Curl_zig_multi_cpool(multi), admin);
            }
        },
        CURLMOPT_NOTIFYFUNCTION => {
            const cb: curl_notify_callback = if (arg_usize == 0) null else @ptrFromInt(arg_usize);
            Curl_zig_multi_set_ntfy_cb(multi, cb);
        },
        CURLMOPT_NOTIFYDATA => {
            Curl_zig_multi_set_ntfy_cb_data(multi, if (arg_usize == 0) null else @ptrFromInt(arg_usize));
        },
        CURLMOPT_RESOLVE_THREADS_MAX => {
            mresult = Curl_zig_multi_resolve_threads_max_set(multi, arg_long);
        },
        CURLMOPT_QUICK_EXIT => {
            Curl_zig_multi_set_quick_exit(multi, arg_long != 0);
        },
        else => {
            mresult = CURLM_UNKNOWN_OPTION;
        },
    }
    return mresult;
}

const multi_setopt_variadic_impl = if (use_c_vastart) struct {
    fn curl_multi_setopt(m: ?*CurlMultiPrefix, option: CURLMoption, ...) callconv(.c) CURLMcode {
        var guard: CurlMapiGuard = undefined;
        var mresult: CURLMcode = CURLM_OK;

        if (api_mod.Curl_mapi_enter(&guard, m, CURL_MAPI_FN_multi_setopt, &mresult)) {
            var ap = @cVaStart();
            defer @cVaEnd(&ap);
            const arg_usize = @cVaArg(&ap, usize);
            const arg_long: c_long = @truncate(@as(isize, @bitCast(arg_usize)));
            mresult = multi_setopt_apply(m.?, option, arg_usize, arg_long);
        }
        api_mod.Curl_mapi_leave(&guard);
        return mresult;
    }
} else struct {
    fn curl_multi_setopt(
        m: ?*CurlMultiPrefix,
        option: CURLMoption,
        arg0: usize,
    ) callconv(.c) CURLMcode {
        var guard: CurlMapiGuard = undefined;
        var mresult: CURLMcode = CURLM_OK;

        if (api_mod.Curl_mapi_enter(&guard, m, CURL_MAPI_FN_multi_setopt, &mresult)) {
            const arg_long: c_long = @truncate(@as(isize, @bitCast(arg0)));
            mresult = multi_setopt_apply(m.?, option, arg0, arg_long);
        }
        api_mod.Curl_mapi_leave(&guard);
        return mresult;
    }
};

comptime {
    @export(&multi_setopt_variadic_impl.curl_multi_setopt, .{
        .name = "curl_multi_setopt",
        .linkage = .strong,
    });
}

pub export fn curl_multi_socket(
    m: ?*CurlMultiPrefix,
    s: curl_socket_t,
    running_handles: ?*c_int,
) callconv(.c) CURLMcode {
    var guard: CurlMapiGuard = undefined;
    var mresult: CURLMcode = CURLM_OK;

    if (api_mod.Curl_mapi_enter(&guard, m, CURL_MAPI_FN_multi_socket, &mresult)) {
        mresult = multi_socket(m.?, false, s, 0, running_handles);
    }
    api_mod.Curl_mapi_leave(&guard);
    return mresult;
}

pub export fn curl_multi_socket_action(
    m: ?*CurlMultiPrefix,
    s: curl_socket_t,
    ev_bitmask: c_int,
    running_handles: ?*c_int,
) callconv(.c) CURLMcode {
    var guard: CurlMapiGuard = undefined;
    var mresult: CURLMcode = CURLM_OK;

    if (api_mod.Curl_mapi_enter(&guard, m, CURL_MAPI_FN_multi_socket_action, &mresult)) {
        mresult = multi_socket(m.?, false, s, ev_bitmask, running_handles);
    }
    api_mod.Curl_mapi_leave(&guard);
    return mresult;
}

pub export fn curl_multi_socket_all(
    m: ?*CurlMultiPrefix,
    running_handles: ?*c_int,
) callconv(.c) CURLMcode {
    var guard: CurlMapiGuard = undefined;
    var mresult: CURLMcode = CURLM_OK;

    if (api_mod.Curl_mapi_enter(&guard, m, CURL_MAPI_FN_multi_socket_all, &mresult)) {
        mresult = multi_socket(m.?, true, CURL_SOCKET_BAD, 0, running_handles);
    }
    api_mod.Curl_mapi_leave(&guard);
    return mresult;
}

fn multi_has_dirties(multi: *CurlMultiPrefix) bool {
    var mid: u32 = 0;
    if (containers.Curl_uint32_bset_first(&multi.dirty, &mid)) {
        while (true) {
            if (Curl_multi_get_easy(multi, mid) != null) {
                if (containers.Curl_uint32_bset_contains(&multi.process, mid))
                    return true;
                containers.Curl_uint32_bset_remove(&multi.dirty, mid);
            } else {
                containers.Curl_uint32_bset_remove(&multi.dirty, mid);
            }
            if (!containers.Curl_uint32_bset_next(&multi.dirty, mid, &mid))
                break;
        }
    }
    return false;
}

fn multi_timeout(
    multi: *CurlMultiPrefix,
    pexpire_offset_us: ?*timediff_t,
    timeout_ms: *c_int,
) void {
    if (Curl_zig_multi_dead(multi)) {
        if (pexpire_offset_us) |p|
            p.* = 0;
        timeout_ms.* = 0;
        return;
    }

    var now: curltime = .{ .tv_sec = 0, .tv_usec = 0 };
    var tnow: time_net.curltime = .{ .tv_sec = 0, .tv_usec = 0 };

    if (multi_has_dirties(multi)) {
        if (pexpire_offset_us) |p| {
            time_net.curlx_pnow(&tnow);
            now.tv_sec = tnow.tv_sec;
            now.tv_usec = tnow.tv_usec;
            p.* = containers.Curl_timeouts_offset_us(&multi.timeouts, &now);
        }
        timeout_ms.* = 0;
        return;
    } else {
        var mid: u32 = 0;
        time_net.curlx_pnow(&tnow);
        now.tv_sec = tnow.tv_sec;
        now.tv_usec = tnow.tv_usec;
        timeout_ms.* = containers.Curl_timeouts_next_ms(
            &multi.timeouts,
            &now,
            pexpire_offset_us,
            &mid,
        );
    }
}

pub export fn curl_multi_timeout(
    m: ?*CurlMultiPrefix,
    timeout_ms: ?*c_long,
) callconv(.c) CURLMcode {
    var guard: CurlMapiGuard = undefined;
    var mresult: CURLMcode = CURLM_OK;

    if (api_mod.Curl_mapi_enter(&guard, m, CURL_MAPI_FN_multi_timeout, &mresult)) {
        var itimeout_ms: c_int = 0;
        multi_timeout(m.?, null, &itimeout_ms);
        if (timeout_ms) |tm| {
            tm.* = @intCast(itimeout_ms);
        }
        mresult = CURLM_OK;
    }
    api_mod.Curl_mapi_leave(&guard);
    return mresult;
}

pub export fn Curl_update_timer(multi: *CurlMultiPrefix) callconv(.c) CURLMcode {
    const timer_cb = Curl_zig_multi_timer_cb(multi) orelse return CURLM_OK;
    if (Curl_zig_multi_dead(multi))
        return CURLM_OK;

    var timeouts_offset_us: timediff_t = 0;
    var timeout_ms: c_int = 0;
    var set_value: bool = false;

    multi_timeout(multi, &timeouts_offset_us, &timeout_ms);

    const last_timeout_set = Curl_zig_multi_last_timeout_set(multi);
    if (timeout_ms < 0 and !last_timeout_set) {
        // nothing to do
    } else if (timeout_ms < 0) {
        timeout_ms = -1;
        set_value = true;
    } else if (!last_timeout_set) {
        set_value = true;
    } else if (Curl_zig_multi_last_expire_offset_us(multi) != timeouts_offset_us) {
        set_value = true;
    }

    if (set_value) {
        var guard: CurlMapiGuard = undefined;
        Curl_zig_multi_set_last_expire_offset_us(multi, timeouts_offset_us);
        Curl_zig_multi_set_last_timeout_set(multi, timeout_ms >= 0);
        api_mod.Curl_cbapi_enter(&guard, null, multi, CURL_CBAPI_FN_multi_timer_cb);
        const rc = timer_cb(multi, @intCast(timeout_ms), Curl_zig_multi_timer_userp(multi));
        api_mod.Curl_cbapi_leave(&guard);
        if (rc == -1) {
            Curl_zig_multi_set_dead(multi, true);
            return CURLM_ABORTED_BY_CALLBACK;
        }
    }
    return CURLM_OK;
}

fn multi_clear_timeout(data: *CurlEasyPrefix, eid: expire_id) void {
    if (eid >= EXPIRE_LAST)
        return;

    const first_ptr = Curl_zig_easy_timeouts_first_ptr(data);
    const next_ptr = Curl_zig_easy_timeouts_next_ptr(data);
    const offset_us_ptr = Curl_zig_easy_timeouts_offset_us_ptr(data);
    const orig_first: u8 = first_ptr.*;
    const id: u8 = @intCast(eid);

    var anchor: *u8 = first_ptr;
    while (anchor.* < EXPIRE_LAST) {
        if (anchor.* == id) {
            anchor.* = next_ptr[id];
            break;
        }
        anchor = &next_ptr[anchor.*];
    }

    std.debug.assert(Curl_zig_multi_timeouts_check(data));

    if (containers.Curl_timeouts_has(data)) {
        const multi = data.multi orelse return;
        if (first_ptr.* >= EXPIRE_LAST or first_ptr.* != orig_first) {
            _ = containers.Curl_timeouts_remove(&multi.timeouts, data);
        }
        if (first_ptr.* < EXPIRE_LAST and !containers.Curl_timeouts_has(data)) {
            containers.Curl_timeouts_add(&multi.timeouts, data, offset_us_ptr[first_ptr.*]);
        }
    }
}

fn multi_set_timeout(
    data: *CurlEasyPrefix,
    stamp: *const curltime,
    eid: expire_id,
) CURLMcode {
    if (eid >= EXPIRE_LAST)
        return CURLM_BAD_FUNCTION_ARGUMENT;
    const multi = data.multi orelse return CURLM_BAD_HANDLE;

    const first_ptr = Curl_zig_easy_timeouts_first_ptr(data);
    const next_ptr = Curl_zig_easy_timeouts_next_ptr(data);
    const offset_us_ptr = Curl_zig_easy_timeouts_offset_us_ptr(data);
    const id: u8 = @intCast(eid);

    multi_clear_timeout(data, eid);
    offset_us_ptr[id] = containers.Curl_timeouts_offset_us(&multi.timeouts, stamp);

    var anchor: *u8 = first_ptr;
    while (anchor.* < EXPIRE_LAST) {
        if (offset_us_ptr[anchor.*] > offset_us_ptr[id])
            break;
        anchor = &next_ptr[anchor.*];
    }
    next_ptr[id] = anchor.*;
    anchor.* = id;

    std.debug.assert(Curl_zig_multi_timeouts_check(data));
    return CURLM_OK;
}

pub export fn Curl_expire_set(
    data: *CurlEasyPrefix,
    eid: expire_id,
    ms_arg: timediff_t,
    pnow: *const curltime,
) callconv(.c) void {
    const multi = data.multi orelse return;
    const first_ptr = Curl_zig_easy_timeouts_first_ptr(data);
    const offset_us_ptr = Curl_zig_easy_timeouts_offset_us_ptr(data);
    const prev_id: u8 = first_ptr.*;
    var ms = ms_arg;

    if (ms > @as(timediff_t, std.math.maxInt(c_int))) {
        ms = @as(timediff_t, std.math.maxInt(c_int));
    }

    var set: curltime = pnow.*;
    set.tv_sec += @intCast(@divTrunc(ms, 1000));
    set.tv_usec += @intCast(@rem(ms, 1000) * 1000);
    if (set.tv_usec >= 1000000) {
        set.tv_sec += 1;
        set.tv_usec -= 1000000;
    }

    _ = multi_set_timeout(data, &set, eid);

    if (containers.Curl_timeouts_has(data)) {
        if (prev_id != @as(u8, @intCast(eid)) and prev_id == first_ptr.*)
            return;
        _ = containers.Curl_timeouts_remove(&multi.timeouts, data);
    }

    containers.Curl_timeouts_add(&multi.timeouts, data, offset_us_ptr[first_ptr.*]);
}

pub export fn Curl_expire(
    data: *CurlEasyPrefix,
    milli: timediff_t,
    eid: expire_id,
) callconv(.c) void {
    Curl_expire_set(data, eid, milli, Curl_pgrs_now(data));
}

pub export fn Curl_expire_clear(
    data: *CurlEasyPrefix,
    eid: expire_id,
) callconv(.c) void {
    multi_clear_timeout(data, eid);
}

pub export fn Curl_expire_clear_all(data: *CurlEasyPrefix) callconv(.c) void {
    const multi = data.multi orelse return;
    if (containers.Curl_timeouts_remove(&multi.timeouts, data)) {
        multi_timeouts_init(data);
    }
}

pub export fn curl_multi_assign(
    m: ?*CurlMultiPrefix,
    sockfd: curl_socket_t,
    sockp: ?*anyopaque,
) callconv(.c) CURLMcode {
    var guard: CurlMapiGuard = undefined;
    var mresult: CURLMcode = CURLM_OK;

    if (api_mod.Curl_mapi_enter(&guard, m, CURL_MAPI_FN_multi_assign, &mresult)) {
        mresult = altsvc_mod.Curl_multi_ev_assign(m.?, sockfd, sockp);
    }
    api_mod.Curl_mapi_leave(&guard);
    return mresult;
}

fn move_pending_to_connect(
    multi: *CurlMultiPrefix,
    data: *CurlEasyPrefix,
) void {
    containers.Curl_uint32_bset_remove(&multi.pending, data.mid);
    _ = containers.Curl_uint32_bset_add(&multi.process, data.mid);
    mstate(data, MSTATE_CONNECT);
    Curl_multi_mark_dirty(data);
}

fn multi_schedule_pending(multi: *CurlMultiPrefix) void {
    var mid = Curl_zig_multi_last_pending_mid(multi);

    if (mid != 0) {
        while (containers.Curl_uint32_bset_next(&multi.pending, mid, &mid)) {
            if (Curl_multi_get_easy(multi, mid)) |data| {
                move_pending_to_connect(multi, data);
                Curl_zig_multi_set_last_pending_mid(multi, mid);
                return;
            }
            containers.Curl_uint32_bset_remove(&multi.pending, mid);
        }
        Curl_zig_multi_set_last_pending_mid(multi, 0);
    }

    if (containers.Curl_uint32_bset_first(&multi.pending, &mid)) {
        while (true) {
            if (Curl_multi_get_easy(multi, mid)) |data| {
                move_pending_to_connect(multi, data);
                Curl_zig_multi_set_last_pending_mid(multi, mid);
                return;
            }
            containers.Curl_uint32_bset_remove(&multi.pending, mid);
            if (!containers.Curl_uint32_bset_next(&multi.pending, mid, &mid))
                break;
        }
    }
}

pub export fn Curl_multi_max_concurrent_streams(multi: *CurlMultiPrefix) callconv(.c) u32 {
    return multi.max_concurrent_streams;
}

pub export fn curl_multi_get_handles(m: ?*CurlMultiPrefix) callconv(.c) ?[*]?*CurlEasyPrefix {
    var guard: CurlMapiGuard = undefined;
    var a: ?[*]?*CurlEasyPrefix = null;

    if (api_mod.Curl_mapi_enter(&guard, m, CURL_MAPI_FN_multi_get_handles, null)) {
        const multi = m.?;
        const count: usize = containers.Curl_uint32_tbl_count(&multi.xfers);
        const raw = mem.curl_malloc_fn(@sizeOf(?*CurlEasyPrefix) * (count + 1));
        if (raw) |r| {
            const arr: [*]?*CurlEasyPrefix = @ptrCast(@alignCast(r));
            var i: usize = 0;
            var mid: u32 = 0;
            var entry: ?*anyopaque = null;

            if (containers.Curl_uint32_tbl_first(&multi.xfers, &mid, &entry)) {
                while (true) {
                    if (entry) |e| {
                        const data: *CurlEasyPrefix = @ptrCast(@alignCast(e));
                        if (!Curl_zig_easy_state_internal(data)) {
                            arr[i] = data;
                            i += 1;
                        }
                    }
                    if (!containers.Curl_uint32_tbl_next(&multi.xfers, mid, &mid, &entry))
                        break;
                }
            }
            arr[i] = null;
            a = arr;
        }
    }
    api_mod.Curl_mapi_leave(&guard);
    return a;
}

pub export fn curl_multi_get_offt(
    m: ?*CurlMultiPrefix,
    info: CURLMinfo_offt,
    pvalue: ?*curl_off_t,
) callconv(.c) CURLMcode {
    var guard: CurlMapiGuard = undefined;
    var mresult: CURLMcode = CURLM_OK;

    if (api_mod.Curl_mapi_enter(&guard, m, CURL_MAPI_FN_multi_get_offt, &mresult)) {
        const multi = m.?;
        if (pvalue == null) {
            mresult = CURLM_BAD_FUNCTION_ARGUMENT;
        } else {
            const pv = pvalue.?;
            var n: u32 = 0;
            switch (info) {
                CURLMINFO_XFERS_CURRENT => {
                    n = containers.Curl_uint32_tbl_count(&multi.xfers);
                    if (n != 0 and multi.admin != null)
                        n -= 1;
                    pv.* = @intCast(n);
                },
                CURLMINFO_XFERS_RUNNING => {
                    n = containers.Curl_uint32_bset_count(&multi.process);
                    if (n != 0 and multi.admin != null and
                        containers.Curl_uint32_bset_contains(&multi.process, multi.admin.?.mid))
                    {
                        n -= 1;
                    }
                    pv.* = @intCast(n);
                },
                CURLMINFO_XFERS_PENDING => {
                    pv.* = @intCast(containers.Curl_uint32_bset_count(&multi.pending));
                },
                CURLMINFO_XFERS_DONE => {
                    pv.* = @intCast(containers.Curl_uint32_bset_count(&multi.msgsent));
                },
                CURLMINFO_XFERS_ADDED => {
                    pv.* = multi.xfers_total_ever;
                },
                else => {
                    pv.* = -1;
                    mresult = CURLM_UNKNOWN_OPTION;
                },
            }
        }
    }
    api_mod.Curl_mapi_leave(&guard);
    return mresult;
}

fn fixed_buf_create(len: usize) ?*CurlFixedBuf {
    if ((std.math.maxInt(usize) - @sizeOf(CurlFixedBuf)) < len)
        return null;
    const raw = mem.curl_malloc_fn(len + @sizeOf(CurlFixedBuf)) orelse return null;
    const fbuf: *CurlFixedBuf = @ptrCast(@alignCast(raw));
    fbuf.len = len;
    return fbuf;
}

pub export fn Curl_multi_xfer_buf_borrow(
    data: *CurlEasyPrefix,
    pbuf: *?[*]u8,
    pbuflen: *usize,
) callconv(.c) CURLcode {
    pbuf.* = null;
    pbuflen.* = 0;
    const multi = data.multi orelse {
        Curl_failf(data, "transfer has no multi handle");
        return CURLE_FAILED_INIT;
    };
    const buf_size = Curl_zig_easy_set_buffer_size(data);
    if (buf_size == 0) {
        Curl_failf(data, "transfer buffer size is 0");
        return CURLE_FAILED_INIT;
    }
    if (Curl_zig_multi_xfer_buf_borrowed(multi)) {
        Curl_failf(data, "attempt to borrow xfer_buf when already borrowed");
        return CURLE_AGAIN;
    }

    const xfer_buf_ptr = Curl_zig_multi_xfer_buf_ptr(multi);
    if (xfer_buf_ptr.*) |fb| {
        if (@as(usize, buf_size) > fb.len) {
            mem.curl_free_fn(fb);
            xfer_buf_ptr.* = null;
        }
    }

    if (xfer_buf_ptr.* == null) {
        xfer_buf_ptr.* = fixed_buf_create(@intCast(buf_size));
        if (xfer_buf_ptr.* == null) {
            Curl_failf(data, "could not allocate xfer_buf of %u bytes", buf_size);
            return CURLE_OUT_OF_MEMORY;
        }
    }

    Curl_zig_multi_set_xfer_buf_borrowed(multi, true);
    pbuf.* = @ptrCast(&xfer_buf_ptr.*.?.data);
    pbuflen.* = xfer_buf_ptr.*.?.len;
    return CURLE_OK;
}

pub export fn Curl_multi_xfer_buf_release(
    data: *CurlEasyPrefix,
    buf: ?[*]u8,
) callconv(.c) void {
    _ = buf;
    if (data.multi) |multi| {
        Curl_zig_multi_set_xfer_buf_borrowed(multi, false);
    }
}

pub export fn Curl_multi_xfer_ulbuf_borrow(
    data: *CurlEasyPrefix,
    pbuf: *?[*]u8,
    pbuflen: *usize,
) callconv(.c) CURLcode {
    pbuf.* = null;
    pbuflen.* = 0;
    const multi = data.multi orelse {
        Curl_failf(data, "transfer has no multi handle");
        return CURLE_FAILED_INIT;
    };
    if (Curl_zig_multi_xfer_ulbuf_borrowed(multi)) {
        Curl_failf(data, "attempt to borrow xfer_ulbuf when already borrowed");
        return CURLE_AGAIN;
    }

    const ulbuf_size = Curl_zig_easy_set_upload_buffer_size(data);
    const xfer_ulbuf_ptr = Curl_zig_multi_xfer_ulbuf_ptr(multi);
    if (xfer_ulbuf_ptr.*) |fb| {
        if (@as(usize, ulbuf_size) > fb.len) {
            mem.curl_free_fn(fb);
            xfer_ulbuf_ptr.* = null;
        }
    }

    if (xfer_ulbuf_ptr.* == null) {
        xfer_ulbuf_ptr.* = fixed_buf_create(@intCast(ulbuf_size));
        if (xfer_ulbuf_ptr.* == null) {
            Curl_failf(data, "could not allocate xfer_ulbuf of %u bytes", ulbuf_size);
            return CURLE_OUT_OF_MEMORY;
        }
    }

    Curl_zig_multi_set_xfer_ulbuf_borrowed(multi, true);
    pbuf.* = @ptrCast(&xfer_ulbuf_ptr.*.?.data);
    pbuflen.* = xfer_ulbuf_ptr.*.?.len;
    return CURLE_OK;
}

pub export fn Curl_multi_xfer_ulbuf_release(
    data: *CurlEasyPrefix,
    buf: ?[*]u8,
) callconv(.c) void {
    _ = buf;
    if (data.multi) |multi| {
        Curl_zig_multi_set_xfer_ulbuf_borrowed(multi, false);
    }
}

pub export fn Curl_multi_xfer_sockbuf_borrow(
    data: *CurlEasyPrefix,
    blen: usize,
    pbuf: *?[*]u8,
) callconv(.c) CURLcode {
    pbuf.* = null;
    const multi = data.multi orelse {
        const raw = mem.curl_malloc_fn(blen) orelse return CURLE_OUT_OF_MEMORY;
        pbuf.* = @ptrCast(raw);
        return CURLE_OK;
    };
    if (Curl_zig_multi_xfer_sockbuf_borrowed(multi)) {
        Curl_failf(data, "attempt to borrow xfer_sockbuf when already borrowed");
        return CURLE_AGAIN;
    }

    const xfer_sockbuf_ptr = Curl_zig_multi_xfer_sockbuf_ptr(multi);
    if (xfer_sockbuf_ptr.*) |fb| {
        if (blen > fb.len) {
            mem.curl_free_fn(fb);
            xfer_sockbuf_ptr.* = null;
        }
    }

    if (xfer_sockbuf_ptr.* == null) {
        xfer_sockbuf_ptr.* = fixed_buf_create(blen);
        if (xfer_sockbuf_ptr.* == null) {
            Curl_failf(data, "could not allocate xfer_sockbuf of %zu bytes", blen);
            return CURLE_OUT_OF_MEMORY;
        }
    }

    Curl_zig_multi_set_xfer_sockbuf_borrowed(multi, true);
    pbuf.* = @ptrCast(&xfer_sockbuf_ptr.*.?.data);
    return CURLE_OK;
}

pub export fn Curl_multi_xfer_sockbuf_release(
    data: *CurlEasyPrefix,
    buf: ?[*]u8,
) callconv(.c) void {
    if (data.multi) |multi| {
        Curl_zig_multi_set_xfer_sockbuf_borrowed(multi, false);
    } else {
        mem.curl_free_fn(@ptrCast(buf));
    }
}

fn multi_xfer_bufs_free(multi: *CurlMultiPrefix) void {
    const xfer_buf_ptr = Curl_zig_multi_xfer_buf_ptr(multi);
    if (xfer_buf_ptr.*) |fb| {
        mem.curl_free_fn(fb);
        xfer_buf_ptr.* = null;
    }
    Curl_zig_multi_set_xfer_buf_borrowed(multi, false);

    const xfer_ulbuf_ptr = Curl_zig_multi_xfer_ulbuf_ptr(multi);
    if (xfer_ulbuf_ptr.*) |fb| {
        mem.curl_free_fn(fb);
        xfer_ulbuf_ptr.* = null;
    }
    Curl_zig_multi_set_xfer_ulbuf_borrowed(multi, false);

    const xfer_sockbuf_ptr = Curl_zig_multi_xfer_sockbuf_ptr(multi);
    if (xfer_sockbuf_ptr.*) |fb| {
        mem.curl_free_fn(fb);
        xfer_sockbuf_ptr.* = null;
    }
    Curl_zig_multi_set_xfer_sockbuf_borrowed(multi, false);
}

pub export fn Curl_multi_get_easy(
    multi: *CurlMultiPrefix,
    mid: u32,
) callconv(.c) ?*CurlEasyPrefix {
    if (!goodMultiHandle(multi))
        return null;
    const raw = containers.Curl_uint32_tbl_get(&multi.xfers, mid) orelse return null;
    const data: *CurlEasyPrefix = @ptrCast(@alignCast(raw));
    if (goodEasyHandle(data) and data.multi == multi and data.mid == mid)
        return data;
    containers.Curl_uint32_tbl_remove(&multi.xfers, mid);
    return null;
}

pub export fn Curl_multi_knows_easy(
    multi: *CurlMultiPrefix,
    data: *CurlEasyPrefix,
) callconv(.c) bool {
    if (!goodMultiHandle(multi) or !goodEasyHandle(data))
        return false;
    if (data.multi != multi or data.mid == std.math.maxInt(u32))
        return false;
    const raw = containers.Curl_uint32_tbl_get(&multi.xfers, data.mid);
    return raw == @as(?*anyopaque, @ptrCast(data));
}

fn multi_xfers_running(multi: ?*CurlMultiPrefix) u32 {
    const m = multi orelse return 0;
    return m.xfers_alive;
}

pub export fn Curl_multi_xfers_attached(multi: ?*CurlMultiPrefix) callconv(.c) u32 {
    const m = multi orelse return 0;
    if (m.admin == null)
        return 0;
    return containers.Curl_uint32_tbl_count(&m.xfers) - 1;
}

pub export fn Curl_multi_mark_dirty(data: *CurlEasyPrefix) callconv(.c) void {
    if (data.multi) |multi| {
        if (data.mid != std.math.maxInt(u32)) {
            _ = containers.Curl_uint32_bset_add(&multi.dirty, data.mid);
        }
    }
}

pub export fn Curl_multi_clear_dirty(data: *CurlEasyPrefix) callconv(.c) void {
    if (data.multi) |multi| {
        if (data.mid != std.math.maxInt(u32)) {
            containers.Curl_uint32_bset_remove(&multi.dirty, data.mid);
        }
    }
}

pub export fn curl_multi_notify_enable(
    m: ?*CurlMultiPrefix,
    notification: c_uint,
) callconv(.c) CURLMcode {
    var guard: CurlMapiGuard = undefined;
    var mresult: CURLMcode = CURLM_OK;

    if (api_mod.Curl_mapi_enter(&guard, m, CURL_MAPI_FN_multi_notify_enable, &mresult)) {
        mresult = containers.Curl_mntfy_enable(m.?, Curl_zig_multi_ntfy(m.?), notification);
    }
    api_mod.Curl_mapi_leave(&guard);
    return mresult;
}

pub export fn curl_multi_notify_disable(
    m: ?*CurlMultiPrefix,
    notification: c_uint,
) callconv(.c) CURLMcode {
    var guard: CurlMapiGuard = undefined;
    var mresult: CURLMcode = CURLM_OK;

    if (api_mod.Curl_mapi_enter(&guard, m, CURL_MAPI_FN_multi_notify_disable, &mresult)) {
        mresult = containers.Curl_mntfy_disable(m.?, Curl_zig_multi_ntfy(m.?), notification);
    }
    api_mod.Curl_mapi_leave(&guard);
    return mresult;
}

test "multi state constants and handle validation" {
    try std.testing.expectEqual(@as(CURLMstate, 0), MSTATE_INIT);
    try std.testing.expectEqual(@as(CURLMstate, 3), MSTATE_CONNECT);
    try std.testing.expectEqual(@as(CURLMstate, 7), MSTATE_DO);
    try std.testing.expectEqual(@as(CURLMstate, 10), MSTATE_DID);
    try std.testing.expectEqual(@as(CURLMstate, 11), MSTATE_PERFORMING);
    try std.testing.expectEqual(@as(CURLMstate, 13), MSTATE_DONE);
    try std.testing.expectEqual(@as(CURLMstate, 14), MSTATE_COMPLETED);
    try std.testing.expectEqual(@as(CURLMstate, 15), MSTATE_MSGSENT);
    try std.testing.expectEqual(@as(CURLMstate, 16), MSTATE_LAST);
    try std.testing.expect(!goodMultiHandle(null));
    try std.testing.expect(!goodEasyHandle(null));
}

test "curlx_sltouz signed long to usize conversion" {
    var out: usize = 0;
    try std.testing.expect(!curlx_sltouz(-1, &out));
    try std.testing.expect(curlx_sltouz(0, &out));
    try std.testing.expectEqual(@as(usize, 0), out);
    try std.testing.expect(curlx_sltouz(12345, &out));
    try std.testing.expectEqual(@as(usize, 12345), out);
}

test "Curl_multi_get_easy rejects corrupted magic or mismatched multi/mid and EAPI/MAPI guards block recursion" {
    var multi: CurlMultiPrefix = std.mem.zeroes(CurlMultiPrefix);
    multi.magic = CURL_MULTI_HANDLE;
    containers.Curl_uint32_tbl_init(&multi.xfers, null);
    defer containers.Curl_uint32_tbl_destroy(&multi.xfers);
    try std.testing.expectEqual(CURLE_OK, containers.Curl_uint32_tbl_resize(&multi.xfers, 8));

    var easy: CurlEasyPrefix = std.mem.zeroes(CurlEasyPrefix);
    easy.magic = api_mod.CURLEASY_MAGIC_NUMBER;
    easy.multi = &multi;
    easy.mid = std.math.maxInt(u32);

    try std.testing.expect(containers.Curl_uint32_tbl_add(&multi.xfers, &easy, &easy.mid));
    const mid = easy.mid;
    try std.testing.expectEqual(@as(?*CurlEasyPrefix, &easy), Curl_multi_get_easy(&multi, mid));
    try std.testing.expect(Curl_multi_knows_easy(&multi, &easy));

    // Mismatched multi pointer must be rejected and evicted
    easy.multi = null;
    try std.testing.expectEqual(@as(?*CurlEasyPrefix, null), Curl_multi_get_easy(&multi, mid));
    try std.testing.expectEqual(@as(?*anyopaque, null), containers.Curl_uint32_tbl_get(&multi.xfers, mid));

    // Re-insert and corrupt magic number (simulating use-after-free/scrubbed handle)
    easy.multi = &multi;
    try std.testing.expect(containers.Curl_uint32_tbl_add(&multi.xfers, &easy, &easy.mid));
    const mid2 = easy.mid;
    easy.magic = 0;
    try std.testing.expectEqual(@as(?*CurlEasyPrefix, null), Curl_multi_get_easy(&multi, mid2));
    try std.testing.expectEqual(@as(?*anyopaque, null), containers.Curl_uint32_tbl_get(&multi.xfers, mid2));

    // Restore valid magic, re-add to multi.xfers, and verify MAPI/EAPI recursion guards
    easy.magic = api_mod.CURLEASY_MAGIC_NUMBER;
    try std.testing.expect(containers.Curl_uint32_tbl_add(&multi.xfers, &easy, &easy.mid));
    var mresult: CURLMcode = CURLM_OK;
    var mguard1: CurlMapiGuard = undefined;
    try std.testing.expect(api_mod.Curl_mapi_enter(&mguard1, &multi, CURL_MAPI_FN_multi_perform, &mresult));
    try std.testing.expectEqual(CURLM_OK, mresult);

    var mguard2: CurlMapiGuard = undefined;
    try std.testing.expect(!api_mod.Curl_mapi_enter(&mguard2, &multi, CURL_MAPI_FN_multi_cleanup, &mresult));
    try std.testing.expectEqual(CURLM_RECURSIVE_API_CALL, mresult);
    api_mod.Curl_mapi_leave(&mguard2);

    var cb_guard: CurlMapiGuard = undefined;
    api_mod.Curl_cbapi_enter(&cb_guard, &easy, &multi, CURL_CBAPI_FN_multi_socket_cb);
    var eresult: CURLcode = CURLE_OK;
    var eguard: api_mod.CurlEapiGuard = undefined;
    try std.testing.expect(!api_mod.Curl_eapi_enter_zig(&eguard, &easy, false, api_mod.CURL_EAPI_FN_easy_cleanup, &eresult));
    try std.testing.expectEqual(api_mod.CURLE_RECURSIVE_API_CALL, eresult);
    api_mod.Curl_eapi_leave(&eguard);
    api_mod.Curl_cbapi_leave(&cb_guard);

    api_mod.Curl_mapi_leave(&mguard1);
}
