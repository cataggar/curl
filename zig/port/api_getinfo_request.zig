const std = @import("std");
const builtin = @import("builtin");
const backend_options = @import("backend_options");
const mem = @import("mem.zig");
const collections = @import("collections.zig");
const doh_hostip_easy = @import("doh_hostip_easy.zig");
const curlx_time_net = @import("curlx_time_net.zig");
const headers_sock = @import("headers_sock.zig");
const io_buffers = @import("io_buffers.zig");
const os_leaf = @import("os_leaf.zig");

const use_ssl = switch (backend_options.ssl) {
    .openssl, .mbedtls, .schannel, .gnutls, .rustls, .wolfssl => true,
    .none => false,
};

pub const CURLcode = c_uint;
pub const CURLE_OK: CURLcode = 0;
pub const CURLE_FAILED_INIT: CURLcode = 2;
pub const CURLE_NOT_BUILT_IN: CURLcode = 4;
pub const CURLE_OUT_OF_MEMORY: CURLcode = 27;
pub const CURLE_BAD_FUNCTION_ARGUMENT: CURLcode = 43;
pub const CURLE_UNKNOWN_OPTION: CURLcode = 48;
pub const CURLE_AGAIN: CURLcode = 81;
pub const CURLE_RECURSIVE_API_CALL: CURLcode = 93;

pub const CURLMcode = c_int;
pub const CURLM_OK: CURLMcode = 0;
pub const CURLM_BAD_HANDLE: CURLMcode = 1;
pub const CURLM_OUT_OF_MEMORY: CURLMcode = 3;
pub const CURLM_INTERNAL_ERROR: CURLMcode = 4;
pub const CURLM_BAD_SOCKET: CURLMcode = 5;
pub const CURLM_RECURSIVE_API_CALL: CURLMcode = 8;
pub const CURLM_BAD_FUNCTION_ARGUMENT: CURLMcode = 10;
pub const CURLM_ABORTED_BY_CALLBACK: CURLMcode = 11;

pub const CURLHcode = c_uint;
pub const CURLHE_OK: CURLHcode = 0;
pub const CURLHE_OUT_OF_MEMORY: CURLHcode = 5;
pub const CURLHE_BAD_ARGUMENT: CURLHcode = 6;
pub const CURLHE_NOT_BUILT_IN: CURLHcode = 7;

pub const curl_socket_t = headers_sock.curl_socket_t;
pub const CURL_SOCKET_BAD = headers_sock.CURL_SOCKET_BAD;
pub const EasyPollset = headers_sock.EasyPollset;
pub const CurlHash = collections.Curl_hash;
pub const Uint32Tbl = collections.uint32_tbl;
pub const Uint32Bset = collections.uint32_bset;
pub const Uint32Spbset = collections.uint32_spbset;
pub const Bufq = io_buffers.bufq;
pub const Dynbuf = os_leaf.Dynbuf;
pub const Curltime = curlx_time_net.Curltime;

// ============================================================================
// 1. lib/api.c — Callstack Guards (EAPI, MAPI, CBAPI)
// ============================================================================

pub const CURLEASY_MAGIC_NUMBER: u32 = 0xc0dedbad;
pub const CURL_MULTI_HANDLE: u32 = 0x000bab1e;

pub const CURL_EAPI_MAX_RECURSION: usize = 7;
pub const CURL_MAPI_MAX_RECURSION: usize = 15;

pub const CURL_EAPI_FN_easy_cleanup: c_uint = 0;
pub const CURL_EAPI_FN_easy_duphandle: c_uint = 1;
pub const CURL_EAPI_FN_easy_getinfo: c_uint = 2;
pub const CURL_EAPI_FN_easy_header: c_uint = 3;
pub const CURL_EAPI_FN_easy_nextheader: c_uint = 4;
pub const CURL_EAPI_FN_easy_pause: c_uint = 5;
pub const CURL_EAPI_FN_easy_perform_ev: c_uint = 6;
pub const CURL_EAPI_FN_easy_perform: c_uint = 7;
pub const CURL_EAPI_FN_easy_recv: c_uint = 8;
pub const CURL_EAPI_FN_easy_reset: c_uint = 9;
pub const CURL_EAPI_FN_easy_send: c_uint = 10;
pub const CURL_EAPI_FN_easy_setopt: c_uint = 11;
pub const CURL_EAPI_FN_easy_ssls_export: c_uint = 12;
pub const CURL_EAPI_FN_easy_ssls_import: c_uint = 13;
pub const CURL_EAPI_FN_easy_upkeep: c_uint = 14;
pub const CURL_EAPI_FN_ws_recv: c_uint = 15;
pub const CURL_EAPI_FN_ws_send: c_uint = 16;
pub const CURL_EAPI_FN_ws_start_frame: c_uint = 17;
pub const CURL_EAPI_FN_LAST: c_uint = 18;

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
pub const CURL_MAPI_FN_LAST: c_uint = 19;

pub const CURL_CBAPI_FN_START: c_uint = 128;
pub const CURL_CBAPI_FN_easy_chunk_bgn: c_uint = 128;
pub const CURL_CBAPI_FN_easy_chunk_end: c_uint = 129;
pub const CURL_CBAPI_FN_easy_closesocket: c_uint = 130;
pub const CURL_CBAPI_FN_easy_cr_in_read: c_uint = 131;
pub const CURL_CBAPI_FN_easy_cr_in_resume_from: c_uint = 132;
pub const CURL_CBAPI_FN_easy_cw_out_cb: c_uint = 133;
pub const CURL_CBAPI_FN_easy_fdebug: c_uint = 134;
pub const CURL_CBAPI_FN_easy_fnmatch_data: c_uint = 135;
pub const CURL_CBAPI_FN_easy_fopensocket: c_uint = 136;
pub const CURL_CBAPI_FN_easy_fprereq: c_uint = 137;
pub const CURL_CBAPI_FN_easy_fprogress: c_uint = 138;
pub const CURL_CBAPI_FN_easy_fread_func: c_uint = 139;
pub const CURL_CBAPI_FN_easy_fsockopt: c_uint = 140;
pub const CURL_CBAPI_FN_easy_fsslctx: c_uint = 141;
pub const CURL_CBAPI_FN_easy_fwrite_rtp: c_uint = 142;
pub const CURL_CBAPI_FN_easy_fxferinfo: c_uint = 143;
pub const CURL_CBAPI_FN_easy_ioctl_func: c_uint = 144;
pub const CURL_CBAPI_FN_easy_resolver_start: c_uint = 145;
pub const CURL_CBAPI_FN_easy_seek_func: c_uint = 146;
pub const CURL_CBAPI_FN_easy_ssh_hostkeyfunc: c_uint = 147;
pub const CURL_CBAPI_FN_easy_ssh_keyfunc: c_uint = 148;
pub const CURL_CBAPI_FN_easy_trailer_callback: c_uint = 149;
pub const CURL_CBAPI_FN_multi_ntfy_cb: c_uint = 150;
pub const CURL_CBAPI_FN_multi_push_cb: c_uint = 151;
pub const CURL_CBAPI_FN_multi_socket_cb: c_uint = 152;
pub const CURL_CBAPI_FN_multi_timer_cb: c_uint = 153;
pub const CURL_CBAPI_FN_LAST: c_uint = 154;

pub const CurlEapiStack = extern struct {
    count: u16,
    calls: [CURL_EAPI_MAX_RECURSION]u16,
};

pub const CurlMapiStack = extern struct {
    count: u8,
    calls: [CURL_MAPI_MAX_RECURSION]u8,
};

pub const CurlEapiGuard = extern struct {
    data: ?*CurlEasyPrefix,
    depth: u16,
};

pub const CurlMapiGuard = extern struct {
    multi: ?*CurlMultiPrefix,
    depth: u8,
};

pub const CurlSocketCallback = *const fn (
    easy: ?*anyopaque,
    s: curl_socket_t,
    what: c_int,
    userp: ?*anyopaque,
    socketp: ?*anyopaque,
) callconv(.c) c_int;

pub const CurlEasyPrefix = extern struct {
    magic: u32,
    mid: u32,
    mstate: c_uint,
    result: CURLcode,
    conn: ?*anyopaque,
    multi: ?*CurlMultiPrefix,
    callstack: CurlEapiStack,
};

pub const SplayTimeouts = extern struct {
    tree: ?*anyopaque,
    time_base_sec: i64,
};

pub const CurlMultiPrefix = extern struct {
    magic: u32,
    xfers_alive: u32,
    xfers_really_alive: u32,
    max_concurrent_streams: u32,
    xfers_total_ever: i64,
    xfers: Uint32Tbl,
    process: Uint32Bset,
    dirty: Uint32Bset,
    pending: Uint32Bset,
    msgsent: Uint32Bset,
    callstack: CurlMapiStack,
    timeouts: SplayTimeouts,
    admin: ?*CurlEasyPrefix,
    socket_cb: ?CurlSocketCallback,
    socket_userp: ?*anyopaque,
    push_cb: ?*const anyopaque,
    push_userp: ?*anyopaque,
    dnscache: CurlHash,
    ssl_scache: ?*anyopaque,
};

const EapiFnProp = struct {
    data_is_killed: bool,
    recurse: bool,
    no_event_cb: bool,
    no_scache_lock: bool,
};

const eapi_fn_props = [CURL_EAPI_FN_LAST]EapiFnProp{
    .{ .data_is_killed = true, .recurse = false, .no_event_cb = false, .no_scache_lock = false }, // easy_cleanup
    .{ .data_is_killed = false, .recurse = true, .no_event_cb = false, .no_scache_lock = false }, // easy_duphandle
    .{ .data_is_killed = false, .recurse = true, .no_event_cb = false, .no_scache_lock = false }, // easy_getinfo
    .{ .data_is_killed = false, .recurse = true, .no_event_cb = false, .no_scache_lock = false }, // easy_header
    .{ .data_is_killed = false, .recurse = true, .no_event_cb = false, .no_scache_lock = false }, // easy_nextheader
    .{ .data_is_killed = false, .recurse = true, .no_event_cb = true, .no_scache_lock = false }, // easy_pause
    .{ .data_is_killed = false, .recurse = false, .no_event_cb = false, .no_scache_lock = true }, // easy_perform_ev
    .{ .data_is_killed = false, .recurse = false, .no_event_cb = false, .no_scache_lock = true }, // easy_perform
    .{ .data_is_killed = false, .recurse = false, .no_event_cb = false, .no_scache_lock = true }, // easy_recv
    .{ .data_is_killed = false, .recurse = false, .no_event_cb = false, .no_scache_lock = false }, // easy_reset
    .{ .data_is_killed = false, .recurse = false, .no_event_cb = false, .no_scache_lock = true }, // easy_send
    .{ .data_is_killed = false, .recurse = true, .no_event_cb = false, .no_scache_lock = false }, // easy_setopt
    .{ .data_is_killed = false, .recurse = false, .no_event_cb = false, .no_scache_lock = true }, // easy_ssls_export
    .{ .data_is_killed = false, .recurse = false, .no_event_cb = false, .no_scache_lock = true }, // easy_ssls_import
    .{ .data_is_killed = false, .recurse = false, .no_event_cb = false, .no_scache_lock = true }, // easy_upkeep
    .{ .data_is_killed = false, .recurse = true, .no_event_cb = false, .no_scache_lock = true }, // ws_recv
    .{ .data_is_killed = false, .recurse = true, .no_event_cb = false, .no_scache_lock = true }, // ws_send
    .{ .data_is_killed = false, .recurse = true, .no_event_cb = false, .no_scache_lock = false }, // ws_start_frame
};

const MapiFnProp = struct {
    multi_is_killed: bool,
    recurse: bool,
    allow_ntfy_cb: bool,
    no_scache_lock: bool,
};

const mapi_fn_props = [CURL_MAPI_FN_LAST]MapiFnProp{
    .{ .multi_is_killed = false, .recurse = false, .allow_ntfy_cb = true, .no_scache_lock = false }, // multi_add_handle
    .{ .multi_is_killed = false, .recurse = true, .allow_ntfy_cb = true, .no_scache_lock = false }, // multi_assign
    .{ .multi_is_killed = true, .recurse = false, .allow_ntfy_cb = false, .no_scache_lock = true }, // multi_cleanup
    .{ .multi_is_killed = false, .recurse = false, .allow_ntfy_cb = true, .no_scache_lock = false }, // multi_fdset
    .{ .multi_is_killed = false, .recurse = true, .allow_ntfy_cb = true, .no_scache_lock = false }, // multi_get_handles
    .{ .multi_is_killed = false, .recurse = true, .allow_ntfy_cb = true, .no_scache_lock = false }, // multi_get_offt
    .{ .multi_is_killed = false, .recurse = true, .allow_ntfy_cb = true, .no_scache_lock = false }, // multi_info_read
    .{ .multi_is_killed = false, .recurse = true, .allow_ntfy_cb = true, .no_scache_lock = false }, // multi_notify_disable
    .{ .multi_is_killed = false, .recurse = true, .allow_ntfy_cb = true, .no_scache_lock = false }, // multi_notify_enable
    .{ .multi_is_killed = false, .recurse = false, .allow_ntfy_cb = false, .no_scache_lock = true }, // multi_perform
    .{ .multi_is_killed = false, .recurse = false, .allow_ntfy_cb = true, .no_scache_lock = false }, // multi_poll
    .{ .multi_is_killed = false, .recurse = false, .allow_ntfy_cb = true, .no_scache_lock = false }, // multi_remove_handle
    .{ .multi_is_killed = false, .recurse = false, .allow_ntfy_cb = true, .no_scache_lock = false }, // multi_setopt
    .{ .multi_is_killed = false, .recurse = false, .allow_ntfy_cb = false, .no_scache_lock = true }, // multi_socket_action
    .{ .multi_is_killed = false, .recurse = false, .allow_ntfy_cb = false, .no_scache_lock = true }, // multi_socket_all
    .{ .multi_is_killed = false, .recurse = false, .allow_ntfy_cb = false, .no_scache_lock = true }, // multi_socket
    .{ .multi_is_killed = false, .recurse = false, .allow_ntfy_cb = true, .no_scache_lock = true }, // multi_timeout
    .{ .multi_is_killed = false, .recurse = false, .allow_ntfy_cb = true, .no_scache_lock = false }, // multi_wait
    .{ .multi_is_killed = false, .recurse = false, .allow_ntfy_cb = true, .no_scache_lock = false }, // multi_waitfds
};

extern fn Curl_multi_knows_easy(multi: ?*const anyopaque, data: ?*const anyopaque) callconv(.c) bool;
extern fn Curl_api_scache_is_locked(data: ?*anyopaque) callconv(.c) bool;

inline fn goodEasyHandle(data: ?*const CurlEasyPrefix) bool {
    const d = data orelse return false;
    return d.magic == CURLEASY_MAGIC_NUMBER;
}

inline fn goodMultiHandle(multi: ?*const CurlMultiPrefix) bool {
    const m = multi orelse return false;
    return m.magic == CURL_MULTI_HANDLE;
}

pub export fn Curl_api_multi_is_in_callback(multi: ?*CurlMultiPrefix) callconv(.c) bool {
    const m = multi orelse return false;
    const count: usize = m.callstack.count;
    for (0..count) |i| {
        if (m.callstack.calls[i] >= CURL_CBAPI_FN_START) {
            return true;
        }
    }
    return false;
}

pub export fn Curl_api_is_in_callback(data: ?*CurlEasyPrefix) callconv(.c) bool {
    const d = data orelse return false;
    return Curl_api_multi_is_in_callback(d.multi);
}

fn eapiInEventCb(data: *const CurlEasyPrefix) bool {
    const m = data.multi orelse return false;
    const count: usize = m.callstack.count;
    for (0..count) |i| {
        switch (m.callstack.calls[i]) {
            CURL_CBAPI_FN_multi_socket_cb,
            CURL_CBAPI_FN_multi_timer_cb,
            => return true,
            else => {},
        }
    }
    return false;
}

pub export fn Curl_eapi_enter_zig(
    guard: *CurlEapiGuard,
    data: ?*CurlEasyPrefix,
    is_internal: bool,
    fn_id: c_uint,
    presult: ?*CURLcode,
) callconv(.c) bool {
    var result: CURLcode = CURLE_OK;

    guard.depth = 0;
    if (!goodEasyHandle(data) or is_internal) {
        result = CURLE_BAD_FUNCTION_ARGUMENT;
        if (presult) |pr| pr.* = result;
        return false;
    }
    const d = data.?;

    if (d.mid != std.math.maxInt(u32)) {
        if (goodMultiHandle(d.multi)) {
            if (!Curl_multi_knows_easy(d.multi, d)) {
                result = CURLE_BAD_FUNCTION_ARGUMENT;
                if (presult) |pr| pr.* = result;
                return false;
            }
        } else {
            result = CURLE_BAD_FUNCTION_ARGUMENT;
            if (presult) |pr| pr.* = result;
            return false;
        }
    } else if (d.multi != null) {
        result = CURLE_BAD_FUNCTION_ARGUMENT;
        if (presult) |pr| pr.* = result;
        return false;
    }

    if (fn_id >= CURL_EAPI_FN_LAST) {
        result = CURLE_BAD_FUNCTION_ARGUMENT;
        if (presult) |pr| pr.* = result;
        return false;
    }

    const fn_props = eapi_fn_props[fn_id];
    if (!fn_props.recurse) {
        if (d.callstack.count != 0) {
            result = CURLE_RECURSIVE_API_CALL;
            if (presult) |pr| pr.* = result;
            return false;
        }
        if (d.multi) |m| {
            if (m.callstack.count != 0) {
                result = CURLE_RECURSIVE_API_CALL;
                if (presult) |pr| pr.* = result;
                return false;
            }
        }
    }

    if (fn_props.no_event_cb and eapiInEventCb(d)) {
        result = CURLE_RECURSIVE_API_CALL;
        if (presult) |pr| pr.* = result;
        return false;
    }

    if (comptime use_ssl) {
        if (fn_props.no_scache_lock and Curl_api_scache_is_locked(d)) {
            result = CURLE_RECURSIVE_API_CALL;
            if (presult) |pr| pr.* = result;
            return false;
        }
    }

    if (d.callstack.count >= CURL_EAPI_MAX_RECURSION) {
        result = CURLE_RECURSIVE_API_CALL;
        if (presult) |pr| pr.* = result;
        return false;
    }

    d.callstack.calls[d.callstack.count] = @intCast(fn_id);
    d.callstack.count += 1;
    guard.depth = d.callstack.count;
    guard.data = if (fn_props.data_is_killed) null else d;

    if (presult) |pr| pr.* = result;
    return guard.depth > 0;
}

pub export fn Curl_eapi_leave(guard: *CurlEapiGuard) callconv(.c) void {
    if (guard.depth != 0) {
        if (guard.data) |d| {
            if (goodEasyHandle(d) and guard.depth <= d.callstack.count) {
                d.callstack.count = guard.depth - 1;
            }
        }
    }
}

pub export fn Curl_eapi_hcode(result: CURLcode) callconv(.c) CURLHcode {
    return switch (result) {
        CURLE_OK => CURLHE_OK,
        CURLE_BAD_FUNCTION_ARGUMENT => CURLHE_BAD_ARGUMENT,
        CURLE_OUT_OF_MEMORY => CURLHE_OUT_OF_MEMORY,
        CURLE_NOT_BUILT_IN => CURLHE_NOT_BUILT_IN,
        else => CURLHE_BAD_ARGUMENT,
    };
}

fn mapiInNtfyCb(multi: *const CurlMultiPrefix) bool {
    const count: usize = multi.callstack.count;
    return count > 0 and multi.callstack.calls[count - 1] == CURL_CBAPI_FN_multi_ntfy_cb;
}

pub export fn Curl_mapi_enter(
    guard: *CurlMapiGuard,
    multi: ?*CurlMultiPrefix,
    fn_id: c_uint,
    pmresult: ?*CURLMcode,
) callconv(.c) bool {
    var mresult: CURLMcode = CURLM_OK;

    guard.depth = 0;
    if (!goodMultiHandle(multi)) {
        mresult = CURLM_BAD_HANDLE;
        if (pmresult) |pmr| pmr.* = mresult;
        return false;
    }
    const mh = multi.?;

    if (fn_id >= CURL_MAPI_FN_LAST) {
        mresult = CURLM_BAD_FUNCTION_ARGUMENT;
        if (pmresult) |pmr| pmr.* = mresult;
        return false;
    }

    const fn_props = mapi_fn_props[fn_id];
    if (fn_props.allow_ntfy_cb and mapiInNtfyCb(mh)) {
        // allowed to call from notify callback
    } else if (!fn_props.recurse and mh.callstack.count != 0) {
        mresult = CURLM_RECURSIVE_API_CALL;
        if (pmresult) |pmr| pmr.* = mresult;
        return false;
    }

    if (comptime use_ssl) {
        if (fn_props.no_scache_lock and mh.ssl_scache != null and
            Curl_api_scache_is_locked(mh.admin))
        {
            mresult = CURLM_RECURSIVE_API_CALL;
            if (pmresult) |pmr| pmr.* = mresult;
            return false;
        }
    }

    if (mh.callstack.count >= CURL_MAPI_MAX_RECURSION) {
        mresult = CURLM_RECURSIVE_API_CALL;
        if (pmresult) |pmr| pmr.* = mresult;
        return false;
    }

    mh.callstack.calls[mh.callstack.count] = @intCast(fn_id);
    mh.callstack.count += 1;
    guard.depth = mh.callstack.count;
    guard.multi = if (fn_props.multi_is_killed) null else mh;

    if (pmresult) |pmr| pmr.* = mresult;
    return guard.depth > 0;
}

pub export fn Curl_mapi_leave(guard: *CurlMapiGuard) callconv(.c) void {
    if (guard.depth != 0) {
        if (guard.multi) |m| {
            if (goodMultiHandle(m) and guard.depth <= m.callstack.count) {
                m.callstack.count = guard.depth - 1;
            }
        }
    }
}

pub export fn Curl_cbapi_enter(
    guard: *CurlMapiGuard,
    data: ?*CurlEasyPrefix,
    multi: ?*CurlMultiPrefix,
    fn_id: c_uint,
) callconv(.c) void {
    guard.depth = 0;
    const mh = multi orelse (if (data) |d| (if (goodEasyHandle(d)) d.multi else null) else null) orelse return;
    if (!goodMultiHandle(mh)) return;
    if (fn_id >= CURL_CBAPI_FN_LAST or fn_id < CURL_CBAPI_FN_START) return;
    if (mh.callstack.count >= CURL_MAPI_MAX_RECURSION) return;

    mh.callstack.calls[mh.callstack.count] = @intCast(fn_id);
    mh.callstack.count += 1;
    guard.depth = mh.callstack.count;
    guard.multi = mh;
}

pub export fn Curl_cbapi_leave(guard: *CurlMapiGuard) callconv(.c) void {
    Curl_mapi_leave(guard);
}

// ============================================================================
// 2. lib/getinfo.c — Curl_initinfo and Curl_getinfo
// ============================================================================

pub const CURLINFO_STRING: c_uint = 0x100000;
pub const CURLINFO_LONG: c_uint = 0x200000;
pub const CURLINFO_DOUBLE: c_uint = 0x300000;
pub const CURLINFO_SLIST: c_uint = 0x400000;
pub const CURLINFO_PTR: c_uint = 0x400000;
pub const CURLINFO_SOCKET: c_uint = 0x500000;
pub const CURLINFO_OFF_T: c_uint = 0x600000;
pub const CURLINFO_TYPEMASK: c_uint = 0xf00000;

pub const CURLINFO_EFFECTIVE_URL: c_uint = CURLINFO_STRING + 1;
pub const CURLINFO_RESPONSE_CODE: c_uint = CURLINFO_LONG + 2;
pub const CURLINFO_TOTAL_TIME: c_uint = CURLINFO_DOUBLE + 3;
pub const CURLINFO_NAMELOOKUP_TIME: c_uint = CURLINFO_DOUBLE + 4;
pub const CURLINFO_CONNECT_TIME: c_uint = CURLINFO_DOUBLE + 5;
pub const CURLINFO_PRETRANSFER_TIME: c_uint = CURLINFO_DOUBLE + 6;
pub const CURLINFO_SIZE_UPLOAD: c_uint = CURLINFO_DOUBLE + 7;
pub const CURLINFO_SIZE_UPLOAD_T: c_uint = CURLINFO_OFF_T + 7;
pub const CURLINFO_SIZE_DOWNLOAD: c_uint = CURLINFO_DOUBLE + 8;
pub const CURLINFO_SIZE_DOWNLOAD_T: c_uint = CURLINFO_OFF_T + 8;
pub const CURLINFO_SPEED_DOWNLOAD: c_uint = CURLINFO_DOUBLE + 9;
pub const CURLINFO_SPEED_DOWNLOAD_T: c_uint = CURLINFO_OFF_T + 9;
pub const CURLINFO_SPEED_UPLOAD: c_uint = CURLINFO_DOUBLE + 10;
pub const CURLINFO_SPEED_UPLOAD_T: c_uint = CURLINFO_OFF_T + 10;
pub const CURLINFO_HEADER_SIZE: c_uint = CURLINFO_LONG + 11;
pub const CURLINFO_REQUEST_SIZE: c_uint = CURLINFO_LONG + 12;
pub const CURLINFO_SSL_VERIFYRESULT: c_uint = CURLINFO_LONG + 13;
pub const CURLINFO_FILETIME: c_uint = CURLINFO_LONG + 14;
pub const CURLINFO_FILETIME_T: c_uint = CURLINFO_OFF_T + 14;
pub const CURLINFO_CONTENT_LENGTH_DOWNLOAD: c_uint = CURLINFO_DOUBLE + 15;
pub const CURLINFO_CONTENT_LENGTH_DOWNLOAD_T: c_uint = CURLINFO_OFF_T + 15;
pub const CURLINFO_CONTENT_LENGTH_UPLOAD: c_uint = CURLINFO_DOUBLE + 16;
pub const CURLINFO_CONTENT_LENGTH_UPLOAD_T: c_uint = CURLINFO_OFF_T + 16;
pub const CURLINFO_STARTTRANSFER_TIME: c_uint = CURLINFO_DOUBLE + 17;
pub const CURLINFO_CONTENT_TYPE: c_uint = CURLINFO_STRING + 18;
pub const CURLINFO_REDIRECT_TIME: c_uint = CURLINFO_DOUBLE + 19;
pub const CURLINFO_REDIRECT_COUNT: c_uint = CURLINFO_LONG + 20;
pub const CURLINFO_PRIVATE: c_uint = CURLINFO_STRING + 21;
pub const CURLINFO_HTTP_CONNECTCODE: c_uint = CURLINFO_LONG + 22;
pub const CURLINFO_HTTPAUTH_AVAIL: c_uint = CURLINFO_LONG + 23;
pub const CURLINFO_PROXYAUTH_AVAIL: c_uint = CURLINFO_LONG + 24;
pub const CURLINFO_OS_ERRNO: c_uint = CURLINFO_LONG + 25;
pub const CURLINFO_NUM_CONNECTS: c_uint = CURLINFO_LONG + 26;
pub const CURLINFO_SSL_ENGINES: c_uint = CURLINFO_SLIST + 27;
pub const CURLINFO_COOKIELIST: c_uint = CURLINFO_SLIST + 28;
pub const CURLINFO_LASTSOCKET: c_uint = CURLINFO_LONG + 29;
pub const CURLINFO_FTP_ENTRY_PATH: c_uint = CURLINFO_STRING + 30;
pub const CURLINFO_REDIRECT_URL: c_uint = CURLINFO_STRING + 31;
pub const CURLINFO_PRIMARY_IP: c_uint = CURLINFO_STRING + 32;
pub const CURLINFO_APPCONNECT_TIME: c_uint = CURLINFO_DOUBLE + 33;
pub const CURLINFO_CERTINFO: c_uint = CURLINFO_PTR + 34;
pub const CURLINFO_CONDITION_UNMET: c_uint = CURLINFO_LONG + 35;
pub const CURLINFO_RTSP_SESSION_ID: c_uint = CURLINFO_STRING + 36;
pub const CURLINFO_RTSP_CLIENT_CSEQ: c_uint = CURLINFO_LONG + 37;
pub const CURLINFO_RTSP_SERVER_CSEQ: c_uint = CURLINFO_LONG + 38;
pub const CURLINFO_RTSP_CSEQ_RECV: c_uint = CURLINFO_LONG + 39;
pub const CURLINFO_PRIMARY_PORT: c_uint = CURLINFO_LONG + 40;
pub const CURLINFO_LOCAL_IP: c_uint = CURLINFO_STRING + 41;
pub const CURLINFO_LOCAL_PORT: c_uint = CURLINFO_LONG + 42;
pub const CURLINFO_TLS_SESSION: c_uint = CURLINFO_PTR + 43;
pub const CURLINFO_ACTIVESOCKET: c_uint = CURLINFO_SOCKET + 44;
pub const CURLINFO_TLS_SSL_PTR: c_uint = CURLINFO_PTR + 45;
pub const CURLINFO_HTTP_VERSION: c_uint = CURLINFO_LONG + 46;
pub const CURLINFO_PROXY_SSL_VERIFYRESULT: c_uint = CURLINFO_LONG + 47;
pub const CURLINFO_PROTOCOL: c_uint = CURLINFO_LONG + 48;
pub const CURLINFO_SCHEME: c_uint = CURLINFO_STRING + 49;
pub const CURLINFO_TOTAL_TIME_T: c_uint = CURLINFO_OFF_T + 50;
pub const CURLINFO_NAMELOOKUP_TIME_T: c_uint = CURLINFO_OFF_T + 51;
pub const CURLINFO_CONNECT_TIME_T: c_uint = CURLINFO_OFF_T + 52;
pub const CURLINFO_PRETRANSFER_TIME_T: c_uint = CURLINFO_OFF_T + 53;
pub const CURLINFO_STARTTRANSFER_TIME_T: c_uint = CURLINFO_OFF_T + 54;
pub const CURLINFO_REDIRECT_TIME_T: c_uint = CURLINFO_OFF_T + 55;
pub const CURLINFO_APPCONNECT_TIME_T: c_uint = CURLINFO_OFF_T + 56;
pub const CURLINFO_RETRY_AFTER: c_uint = CURLINFO_OFF_T + 57;
pub const CURLINFO_EFFECTIVE_METHOD: c_uint = CURLINFO_STRING + 58;
pub const CURLINFO_PROXY_ERROR: c_uint = CURLINFO_LONG + 59;
pub const CURLINFO_REFERER: c_uint = CURLINFO_STRING + 60;
pub const CURLINFO_CAINFO: c_uint = CURLINFO_STRING + 61;
pub const CURLINFO_CAPATH: c_uint = CURLINFO_STRING + 62;
pub const CURLINFO_XFER_ID: c_uint = CURLINFO_OFF_T + 63;
pub const CURLINFO_CONN_ID: c_uint = CURLINFO_OFF_T + 64;
pub const CURLINFO_QUEUE_TIME_T: c_uint = CURLINFO_OFF_T + 65;
pub const CURLINFO_USED_PROXY: c_uint = CURLINFO_LONG + 66;
pub const CURLINFO_POSTTRANSFER_TIME_T: c_uint = CURLINFO_OFF_T + 67;
pub const CURLINFO_EARLYDATA_SENT_T: c_uint = CURLINFO_OFF_T + 68;
pub const CURLINFO_HTTPAUTH_USED: c_uint = CURLINFO_LONG + 69;
pub const CURLINFO_PROXYAUTH_USED: c_uint = CURLINFO_LONG + 70;
pub const CURLINFO_SIZE_DELIVERED: c_uint = CURLINFO_OFF_T + 71;

const HTTPREQ_GET: u8 = 0;
const HTTPREQ_POST: u8 = 1;
const HTTPREQ_POST_FORM: u8 = 2;
const HTTPREQ_POST_MIME: u8 = 3;
const HTTPREQ_PUT: u8 = 4;
const HTTPREQ_HEAD: u8 = 5;

const TRNSPRT_TCP: u8 = 3;
const TRNSPRT_UDP: u8 = 4;
const TRNSPRT_QUIC: u8 = 5;

const CF_QUERY_SSL_INFO: c_int = 12;
const CF_QUERY_SSL_CTX_INFO: c_int = 13;

pub const IpQuadruple = extern struct {
    remote_ip: [45:0]u8,
    local_ip: [45:0]u8,
    remote_port: u16,
    local_port: u16,
    transport: u8,
};

pub const CurlCertinfo = extern struct {
    num_of_certs: c_int,
    certinfo: ?*?*anyopaque,
};

pub const CurlTlssessioninfo = extern struct {
    backend: c_uint,
    internals: ?*anyopaque,
};

pub const PureInfoPrefix = extern struct {
    primary: IpQuadruple,
    certs: CurlCertinfo,
    filetime: i64,
    request_size: i64,
    numconnects: i64,
    contenttype: ?[*:0]u8,
    wouldredirect: ?[*:0]u8,
    effective_url: ?[*:0]u8,
    retry_after: i64,
    conn_scheme: ?[*:0]const u8,
    httpcode: c_int,
    httpproxycode: c_int,
    httpversion: c_int,
    conn_protocol: u32,
    proxyauthavail: u32,
    httpauthavail: u32,
    proxyauthpicked: u32,
    httpauthpicked: u32,
    header_size: u32,
    pxcode: u8,
};

pub const CurlGetinfoCtx = extern struct {
    info: *PureInfoPrefix,
    tsi: *CurlTlssessioninfo,
    url_str: ?[*:0]const u8,
    referer_str: ?[*:0]const u8,
    custom_request: ?[*:0]const u8,
    ftp_entrypath: ?[*:0]const u8,
    rtsp_session_id: ?[*:0]const u8,
    cainfo_default: ?[*:0]const u8,
    capath_default: ?[*:0]const u8,
    private_data: ?[*:0]const u8,
    xfer_id: i64,
    last_conn_id: i64,
    deliver: i64,
    earlydata_sent: i64,
    ul_total_size: i64,
    ul_cur_size: i64,
    ul_speed: i64,
    dl_total_size: i64,
    dl_cur_size: i64,
    dl_speed: i64,
    spent_us: i64,
    queued_us: i64,
    nslookup_us: i64,
    connect_us: i64,
    appconnect_us: i64,
    pretransfer_us: i64,
    starttransfer_us: i64,
    posttransfer_us: i64,
    startredirect_us: i64,
    ssl_verifyresult: c_long,
    proxy_ssl_verifyresult: c_long,
    rtsp_next_client_CSeq: u32,
    rtsp_next_server_CSeq: u32,
    rtsp_CSeq_recv: u32,
    os_errno: c_int,
    followlocation: u16,
    httpreq: u8,
    path_as_is: u8,
    opt_no_body: u8,
    timecond: u8,
    used_proxy: u8,
    ul_size_known: u8,
    dl_size_known: u8,
};

const CURLUPART_URL: c_uint = 0;
const CURLUPART_USER: c_uint = 2;
const CURLUPART_PASSWORD: c_uint = 3;
const CURLU_NON_SUPPORT_SCHEME: c_uint = 1 << 3;
const CURLU_PATH_AS_IS: c_uint = 1 << 4;
const CURLU_GET_EMPTY: c_uint = 1 << 14;

extern fn curl_url() callconv(.c) ?*anyopaque;
extern fn curl_url_cleanup(u: ?*anyopaque) callconv(.c) void;
extern fn curl_url_set(u: ?*anyopaque, what: c_uint, part: ?[*:0]const u8, flags: c_uint) callconv(.c) c_uint;
extern fn curl_url_get(u: ?*const anyopaque, what: c_uint, part: *?[*:0]u8, flags: c_uint) callconv(.c) c_uint;
extern fn Curl_uc_to_curlcode(uc: c_uint) callconv(.c) CURLcode;
extern fn Curl_getconnectinfo(data: ?*anyopaque, connp: ?*?*anyopaque) callconv(.c) curl_socket_t;
extern fn Curl_getinfo_cookie_list(data: ?*anyopaque) callconv(.c) ?*anyopaque;
extern fn Curl_conn_get_ssl_info(
    data: ?*anyopaque,
    conn: ?*anyopaque,
    sockindex: c_int,
    query: c_int,
    tsi: *CurlTlssessioninfo,
) callconv(.c) bool;
extern fn Curl_ssl_backend() callconv(.c) c_uint;
extern fn Curl_ssl_engines_list(data: ?*anyopaque) callconv(.c) ?*anyopaque;
extern fn Curl_ssl_free_certinfo(data: ?*anyopaque) callconv(.c) void;

pub export fn Curl_initinfo_zig(
    data: ?*anyopaque,
    pro_delta: ?*[5]i64,
    pro_total: ?*[8]i64,
    info_opt: ?*PureInfoPrefix,
) callconv(.c) void {
    if (pro_delta) |pd| {
        pd.* = @splat(0);
    }
    if (pro_total) |pt| {
        pt.* = @splat(0);
    }
    if (info_opt) |info| {
        info.httpcode = 0;
        info.httpproxycode = 0;
        info.httpversion = 0;
        info.filetime = -1;

        info.header_size = 0;
        info.request_size = 0;
        info.proxyauthavail = 0;
        info.httpauthavail = 0;
        info.proxyauthpicked = 0;
        info.httpauthpicked = 0;
        info.numconnects = 0;

        if (info.contenttype) |p| {
            mem.free(p);
            info.contenttype = null;
        }
        if (info.wouldredirect) |p| {
            mem.free(p);
            info.wouldredirect = null;
        }
        if (info.effective_url) |p| {
            mem.free(p);
            info.effective_url = null;
        }

        @memset(std.mem.asBytes(&info.primary), 0);
        info.retry_after = 0;
        info.conn_scheme = null;
        info.conn_protocol = 0;
    }

    if (comptime use_ssl) {
        if (data) |d| {
            Curl_ssl_free_certinfo(d);
        }
    }
}

fn effectiveUrlInner(ctx: *const CurlGetinfoCtx, s: [*:0]const u8, outp: *?[*:0]const u8, out_err: *CURLcode) error{UrlError}!void {
    const u = curl_url() orelse {
        out_err.* = CURLE_OUT_OF_MEMORY;
        return error.UrlError;
    };
    defer curl_url_cleanup(u);

    var url: ?[*:0]u8 = null;
    errdefer mem.free(url);
    var uc = curl_url_set(
        u,
        CURLUPART_URL,
        s,
        CURLU_NON_SUPPORT_SCHEME | (if (ctx.path_as_is != 0) CURLU_PATH_AS_IS else 0),
    );
    if (uc == 0) {
        uc = curl_url_set(u, CURLUPART_USER, null, 0);
    }
    if (uc == 0) {
        uc = curl_url_set(u, CURLUPART_PASSWORD, null, 0);
    }
    if (uc == 0) {
        uc = curl_url_get(u, CURLUPART_URL, &url, CURLU_GET_EMPTY);
    }

    if (uc != 0 or url == null) {
        out_err.* = if (uc != 0) Curl_uc_to_curlcode(uc) else CURLE_OUT_OF_MEMORY;
        return error.UrlError;
    }
    const u_str = url.?;
    if (!std.mem.eql(u8, std.mem.span(u_str), std.mem.span(s))) {
        if (ctx.info.effective_url) |old| {
            mem.free(old);
        }
        ctx.info.effective_url = u_str;
        outp.* = u_str;
    } else {
        mem.free(u_str);
        outp.* = s;
    }
}

fn effectiveUrl(ctx: *const CurlGetinfoCtx, url_in: ?[*:0]const u8, outp: *?[*:0]const u8) CURLcode {
    const s = url_in orelse {
        outp.* = "";
        return CURLE_OK;
    };
    outp.* = null;
    var err: CURLcode = CURLE_OK;
    effectiveUrlInner(ctx, s, outp, &err) catch return err;
    return CURLE_OK;
}

fn getinfoChar(ctx: *const CurlGetinfoCtx, info: c_uint, param_charp: *?[*:0]const u8) CURLcode {
    switch (info) {
        CURLINFO_EFFECTIVE_URL => {
            return effectiveUrl(ctx, ctx.url_str, param_charp);
        },
        CURLINFO_EFFECTIVE_METHOD => {
            var m = ctx.custom_request;
            if (m == null) {
                if (ctx.opt_no_body != 0) {
                    m = "HEAD";
                } else {
                    m = switch (ctx.httpreq) {
                        HTTPREQ_POST, HTTPREQ_POST_FORM, HTTPREQ_POST_MIME => "POST",
                        HTTPREQ_PUT => "PUT",
                        HTTPREQ_HEAD => "HEAD",
                        HTTPREQ_GET => "GET",
                        else => "GET",
                    };
                }
            }
            param_charp.* = m;
        },
        CURLINFO_CONTENT_TYPE => {
            param_charp.* = ctx.info.contenttype;
        },
        CURLINFO_PRIVATE => {
            param_charp.* = ctx.private_data;
        },
        CURLINFO_FTP_ENTRY_PATH => {
            param_charp.* = ctx.ftp_entrypath;
        },
        CURLINFO_REDIRECT_URL => {
            param_charp.* = ctx.info.wouldredirect;
        },
        CURLINFO_REFERER => {
            param_charp.* = ctx.referer_str;
        },
        CURLINFO_PRIMARY_IP => {
            param_charp.* = &ctx.info.primary.remote_ip;
        },
        CURLINFO_LOCAL_IP => {
            param_charp.* = &ctx.info.primary.local_ip;
        },
        CURLINFO_RTSP_SESSION_ID => {
            param_charp.* = ctx.rtsp_session_id;
        },
        CURLINFO_SCHEME => {
            param_charp.* = ctx.info.conn_scheme;
        },
        CURLINFO_CAPATH => {
            param_charp.* = ctx.capath_default;
        },
        CURLINFO_CAINFO => {
            param_charp.* = ctx.cainfo_default;
        },
        else => return CURLE_UNKNOWN_OPTION,
    }
    return CURLE_OK;
}

inline fn infoQuadHasIpPort(p: *const IpQuadruple) bool {
    return p.transport == TRNSPRT_TCP or
        p.transport == TRNSPRT_UDP or
        p.transport == TRNSPRT_QUIC;
}

fn getinfoLong(
    data: *CurlEasyPrefix,
    ctx: *const CurlGetinfoCtx,
    info: c_uint,
    param_longp: *c_long,
) CURLcode {
    const max_long: i64 = std.math.maxInt(c_long);

    switch (info) {
        CURLINFO_RESPONSE_CODE => {
            param_longp.* = @intCast(ctx.info.httpcode);
        },
        CURLINFO_HTTP_CONNECTCODE => {
            param_longp.* = @intCast(ctx.info.httpproxycode);
        },
        CURLINFO_FILETIME => {
            if (ctx.info.filetime > max_long) {
                param_longp.* = std.math.maxInt(c_long);
            } else if (ctx.info.filetime < std.math.minInt(c_long)) {
                param_longp.* = std.math.minInt(c_long);
            } else {
                param_longp.* = @intCast(ctx.info.filetime);
            }
        },
        CURLINFO_HEADER_SIZE => {
            param_longp.* = @intCast(ctx.info.header_size);
        },
        CURLINFO_REQUEST_SIZE => {
            param_longp.* = if (ctx.info.request_size > max_long)
                std.math.maxInt(c_long)
            else
                @intCast(ctx.info.request_size);
        },
        CURLINFO_SSL_VERIFYRESULT => {
            param_longp.* = ctx.ssl_verifyresult;
        },
        CURLINFO_PROXY_SSL_VERIFYRESULT => {
            param_longp.* = ctx.proxy_ssl_verifyresult;
        },
        CURLINFO_REDIRECT_COUNT => {
            param_longp.* = @intCast(ctx.followlocation);
        },
        CURLINFO_HTTPAUTH_AVAIL => {
            param_longp.* = @bitCast(@as(c_ulong, ctx.info.httpauthavail));
        },
        CURLINFO_PROXYAUTH_AVAIL => {
            param_longp.* = @bitCast(@as(c_ulong, ctx.info.proxyauthavail));
        },
        CURLINFO_HTTPAUTH_USED => {
            param_longp.* = @bitCast(@as(c_ulong, ctx.info.httpauthpicked));
        },
        CURLINFO_PROXYAUTH_USED => {
            param_longp.* = @bitCast(@as(c_ulong, ctx.info.proxyauthpicked));
        },
        CURLINFO_OS_ERRNO => {
            param_longp.* = @intCast(ctx.os_errno);
        },
        CURLINFO_NUM_CONNECTS => {
            param_longp.* = if (ctx.info.numconnects > max_long)
                std.math.maxInt(c_long)
            else
                @intCast(ctx.info.numconnects);
        },
        CURLINFO_LASTSOCKET => {
            const sockfd = Curl_getconnectinfo(data, null);
            if (sockfd != CURL_SOCKET_BAD) {
                param_longp.* = @intCast(sockfd);
            } else {
                param_longp.* = -1;
            }
        },
        CURLINFO_PRIMARY_PORT => {
            param_longp.* = if (infoQuadHasIpPort(&ctx.info.primary))
                @intCast(ctx.info.primary.remote_port)
            else
                -1;
        },
        CURLINFO_LOCAL_PORT => {
            param_longp.* = if (infoQuadHasIpPort(&ctx.info.primary))
                @intCast(ctx.info.primary.local_port)
            else
                -1;
        },
        CURLINFO_PROXY_ERROR => {
            param_longp.* = @intCast(ctx.info.pxcode);
        },
        CURLINFO_CONDITION_UNMET => {
            if (ctx.info.httpcode == 304) {
                param_longp.* = 1;
            } else {
                param_longp.* = if (ctx.timecond != 0) 1 else 0;
            }
        },
        CURLINFO_RTSP_CLIENT_CSEQ => {
            param_longp.* = @bitCast(@as(c_ulong, ctx.rtsp_next_client_CSeq));
        },
        CURLINFO_RTSP_SERVER_CSEQ => {
            param_longp.* = @bitCast(@as(c_ulong, ctx.rtsp_next_server_CSeq));
        },
        CURLINFO_RTSP_CSEQ_RECV => {
            param_longp.* = @bitCast(@as(c_ulong, ctx.rtsp_CSeq_recv));
        },
        CURLINFO_HTTP_VERSION => {
            switch (ctx.info.httpversion) {
                10 => param_longp.* = 1, // CURL_HTTP_VERSION_1_0
                11 => param_longp.* = 2, // CURL_HTTP_VERSION_1_1
                20 => param_longp.* = 3, // CURL_HTTP_VERSION_2_0
                30 => param_longp.* = 30, // CURL_HTTP_VERSION_3
                else => param_longp.* = 0, // CURL_HTTP_VERSION_NONE
            }
        },
        CURLINFO_PROTOCOL => {
            param_longp.* = @bitCast(@as(c_ulong, ctx.info.conn_protocol));
        },
        CURLINFO_USED_PROXY => {
            param_longp.* = if (ctx.used_proxy != 0) 1 else 0;
        },
        else => return CURLE_UNKNOWN_OPTION,
    }
    return CURLE_OK;
}

inline fn doubleSecs(x: i64) f64 {
    return @as(f64, @floatFromInt(x)) / 1000000.0;
}

fn getinfoOfft(ctx: *const CurlGetinfoCtx, info: c_uint, param_offt: *i64) CURLcode {
    switch (info) {
        CURLINFO_FILETIME_T => param_offt.* = ctx.info.filetime,
        CURLINFO_SIZE_UPLOAD_T => param_offt.* = ctx.ul_cur_size,
        CURLINFO_SIZE_DOWNLOAD_T => param_offt.* = ctx.dl_cur_size,
        CURLINFO_SIZE_DELIVERED => param_offt.* = ctx.deliver,
        CURLINFO_SPEED_DOWNLOAD_T => param_offt.* = ctx.dl_speed,
        CURLINFO_SPEED_UPLOAD_T => param_offt.* = ctx.ul_speed,
        CURLINFO_CONTENT_LENGTH_DOWNLOAD_T => {
            param_offt.* = if (ctx.dl_size_known != 0) ctx.dl_total_size else -1;
        },
        CURLINFO_CONTENT_LENGTH_UPLOAD_T => {
            param_offt.* = if (ctx.ul_size_known != 0) ctx.ul_total_size else -1;
        },
        CURLINFO_TOTAL_TIME_T => param_offt.* = ctx.spent_us,
        CURLINFO_QUEUE_TIME_T => param_offt.* = ctx.queued_us,
        CURLINFO_NAMELOOKUP_TIME_T => param_offt.* = ctx.nslookup_us,
        CURLINFO_CONNECT_TIME_T => param_offt.* = ctx.connect_us,
        CURLINFO_APPCONNECT_TIME_T => param_offt.* = ctx.appconnect_us,
        CURLINFO_PRETRANSFER_TIME_T => param_offt.* = ctx.pretransfer_us,
        CURLINFO_POSTTRANSFER_TIME_T => param_offt.* = ctx.posttransfer_us,
        CURLINFO_STARTTRANSFER_TIME_T => param_offt.* = ctx.starttransfer_us,
        CURLINFO_REDIRECT_TIME_T => param_offt.* = ctx.startredirect_us,
        CURLINFO_RETRY_AFTER => param_offt.* = ctx.info.retry_after,
        CURLINFO_XFER_ID => param_offt.* = ctx.xfer_id,
        CURLINFO_CONN_ID => param_offt.* = ctx.last_conn_id,
        CURLINFO_EARLYDATA_SENT_T => param_offt.* = ctx.earlydata_sent,
        else => return CURLE_UNKNOWN_OPTION,
    }
    return CURLE_OK;
}

fn getinfoDouble(ctx: *const CurlGetinfoCtx, info: c_uint, param_doublep: *f64) CURLcode {
    switch (info) {
        CURLINFO_TOTAL_TIME => param_doublep.* = doubleSecs(ctx.spent_us),
        CURLINFO_NAMELOOKUP_TIME => param_doublep.* = doubleSecs(ctx.nslookup_us),
        CURLINFO_CONNECT_TIME => param_doublep.* = doubleSecs(ctx.connect_us),
        CURLINFO_APPCONNECT_TIME => param_doublep.* = doubleSecs(ctx.appconnect_us),
        CURLINFO_PRETRANSFER_TIME => param_doublep.* = doubleSecs(ctx.pretransfer_us),
        CURLINFO_STARTTRANSFER_TIME => param_doublep.* = doubleSecs(ctx.starttransfer_us),
        CURLINFO_SIZE_UPLOAD => param_doublep.* = @floatFromInt(ctx.ul_cur_size),
        CURLINFO_SIZE_DOWNLOAD => param_doublep.* = @floatFromInt(ctx.dl_cur_size),
        CURLINFO_SPEED_DOWNLOAD => param_doublep.* = @floatFromInt(ctx.dl_speed),
        CURLINFO_SPEED_UPLOAD => param_doublep.* = @floatFromInt(ctx.ul_speed),
        CURLINFO_CONTENT_LENGTH_DOWNLOAD => {
            param_doublep.* = if (ctx.dl_size_known != 0)
                @floatFromInt(ctx.dl_total_size)
            else
                -1.0;
        },
        CURLINFO_CONTENT_LENGTH_UPLOAD => {
            param_doublep.* = if (ctx.ul_size_known != 0)
                @floatFromInt(ctx.ul_total_size)
            else
                -1.0;
        },
        CURLINFO_REDIRECT_TIME => param_doublep.* = doubleSecs(ctx.startredirect_us),
        else => return CURLE_UNKNOWN_OPTION,
    }
    return CURLE_OK;
}

fn getinfoSlist(
    data: *CurlEasyPrefix,
    ctx: *const CurlGetinfoCtx,
    info: c_uint,
    param_slistp: *?*anyopaque,
) CURLcode {
    switch (info) {
        CURLINFO_SSL_ENGINES => {
            if (comptime use_ssl) {
                param_slistp.* = Curl_ssl_engines_list(data);
            } else {
                param_slistp.* = null;
            }
        },
        CURLINFO_COOKIELIST => {
            param_slistp.* = Curl_getinfo_cookie_list(data);
        },
        CURLINFO_CERTINFO => {
            param_slistp.* = &ctx.info.certs;
        },
        CURLINFO_TLS_SESSION, CURLINFO_TLS_SSL_PTR => {
            const tsi = ctx.tsi;
            param_slistp.* = tsi;
            const query: c_int = if (info == CURLINFO_TLS_SSL_PTR)
                CF_QUERY_SSL_INFO
            else
                CF_QUERY_SSL_CTX_INFO;
            if (!Curl_conn_get_ssl_info(data, data.conn, 0, query, tsi)) {
                tsi.backend = Curl_ssl_backend();
                tsi.internals = null;
            }
        },
        else => return CURLE_UNKNOWN_OPTION,
    }
    return CURLE_OK;
}

fn getinfoSocket(data: *CurlEasyPrefix, info: c_uint, param_socketp: *curl_socket_t) CURLcode {
    switch (info) {
        CURLINFO_ACTIVESOCKET => {
            param_socketp.* = Curl_getconnectinfo(data, null);
        },
        else => return CURLE_UNKNOWN_OPTION,
    }
    return CURLE_OK;
}

inline fn castParam(comptime T: type, param: *anyopaque) *T {
    return @ptrCast(@alignCast(param));
}

pub export fn Curl_getinfo_zig(
    data_opt: ?*CurlEasyPrefix,
    ctx_opt: ?*const CurlGetinfoCtx,
    info: c_uint,
    paramp: ?*anyopaque,
) callconv(.c) CURLcode {
    const data = data_opt orelse return CURLE_BAD_FUNCTION_ARGUMENT;
    const ctx = ctx_opt orelse return CURLE_BAD_FUNCTION_ARGUMENT;
    const param = paramp orelse return CURLE_BAD_FUNCTION_ARGUMENT;

    const typ = info & CURLINFO_TYPEMASK;
    switch (typ) {
        CURLINFO_STRING => return getinfoChar(ctx, info, castParam(?[*:0]const u8, param)),
        CURLINFO_LONG => return getinfoLong(data, ctx, info, castParam(c_long, param)),
        CURLINFO_DOUBLE => return getinfoDouble(ctx, info, castParam(f64, param)),
        CURLINFO_OFF_T => return getinfoOfft(ctx, info, castParam(i64, param)),
        CURLINFO_SLIST => return getinfoSlist(data, ctx, info, castParam(?*anyopaque, param)),
        CURLINFO_SOCKET => return getinfoSocket(data, info, castParam(curl_socket_t, param)),
        else => return CURLE_UNKNOWN_OPTION,
    }
}

// ============================================================================
// 3. lib/request.c — SingleRequest Lifecycle and Buffering
// ============================================================================

pub const REQ_IO_RECV: u8 = 1 << 0;
pub const REQ_IO_SEND: u8 = 1 << 1;

const UPGR101_NONE: u8 = 0;
const MSTATE_DID: c_uint = 10;
const TIMER_POSTRANSFER: c_uint = 9;
const CURLINFO_HEADER_OUT: c_uint = 2;
const CURLINFO_DATA_OUT: c_uint = 4;

pub const SingleRequestFlags = packed struct(u24) {
    header: bool = false,
    done: bool = false,
    content_range: bool = false,
    download_done: bool = false,
    eos_written: bool = false,
    eos_read: bool = false,
    eos_sent: bool = false,
    rewind_read: bool = false,
    upload_done: bool = false,
    upload_aborted: bool = false,
    ignorebody: bool = false,
    http_bodyless: bool = false,
    chunk: bool = false,
    resp_trailer: bool = false,
    ignore_cl: bool = false,
    upload_chunky: bool = false,
    no_body: bool = false,
    authneg: bool = false,
    sendbuf_init: bool = false,
    shutdown: bool = false,
    shutdown_err_ignore: bool = false,
    reader_started: bool = false,
    _pad: u2 = 0,
};

pub const SingleRequestTail = if (builtin.os.tag == .windows)
    extern struct {
        setcookies: u8 = 0,
        _pad0: [3]u8 = .{ 0, 0, 0 },
        word: packed struct(u32) {
            flags: SingleRequestFlags = .{},
            _pad1: u8 = 0,
        } = .{},
    }
else
    extern struct {
        word: packed struct(u32) {
            setcookies: u8 = 0,
            flags: SingleRequestFlags = .{},
        } = .{},
    };

pub const SingleRequest = extern struct {
    size: i64,
    maxdownload: i64,
    bytecount: i64,
    writebytecount: i64,
    offset: i64,
    start: Curltime,
    headerbytecount: c_uint,
    allheadercount: c_uint,
    deductheadercount: c_uint,
    headerline: c_int,
    httpcode: c_int,
    httpversion_sent: u8,
    httpversion: u8,
    upgr101: u8,
    io_flags: u8,
    writer_stack: ?*anyopaque,
    writer_flags: u32,
    reader_stack: ?*anyopaque,
    sendbuf: Bufq,
    sendbuf_hds_len: usize,
    timeofdoc: i64,
    location: ?*u8,
    newurl: ?*u8,
    hd_auth: ?*u8,
    hd_proxy_auth: ?*u8,
    cookiehost: ?*u8,
    tail: SingleRequestTail,

    pub inline fn setSetcookies(self: *SingleRequest, val: u8) void {
        if (comptime builtin.os.tag == .windows) {
            self.tail.setcookies = val;
        } else {
            self.tail.word.setcookies = val;
        }
    }
};

comptime {
    std.debug.assert(@sizeOf(SingleRequest) == 232);
}

extern fn Curl_client_start(data: ?*anyopaque) callconv(.c) CURLcode;
extern fn Curl_client_reset(data: ?*anyopaque) callconv(.c) void;
extern fn Curl_client_cleanup(data: ?*anyopaque) callconv(.c) void;
extern fn Curl_client_read(
    data: ?*anyopaque,
    buf: [*]u8,
    blen: usize,
    nread: *usize,
    eos: *bool,
) callconv(.c) CURLcode;
extern fn Curl_creader_total_length(data: ?*anyopaque) callconv(.c) i64;
extern fn Curl_creader_done(data: ?*anyopaque, premature: bool) callconv(.c) void;
extern fn Curl_pgrs_now(data: ?*anyopaque) callconv(.c) *const Curltime;
extern fn Curl_pgrsTime(data: ?*anyopaque, timer: c_uint) callconv(.c) void;
extern fn Curl_pgrs_upload_inc(data: ?*anyopaque, delta: usize) callconv(.c) void;
extern fn Curl_resolv_destroy_all(data: ?*anyopaque) callconv(.c) void;
extern fn Curl_rlimit_block(r: ?*anyopaque, activate: bool, ts: *const Curltime) callconv(.c) void;
extern fn Curl_rlimit_is_blocked(r: ?*const anyopaque) callconv(.c) bool;
extern fn Curl_xfer_send(
    data: ?*anyopaque,
    buf: [*]const u8,
    blen: usize,
    eos: bool,
    pnwritten: *usize,
) callconv(.c) CURLcode;
extern fn Curl_xfer_send_close(data: ?*anyopaque) callconv(.c) CURLcode;
extern fn Curl_xfer_needs_flush(data: ?*anyopaque) callconv(.c) bool;
extern fn Curl_xfer_flush(data: ?*anyopaque) callconv(.c) CURLcode;
extern fn Curl_xfer_send_shutdown(data: ?*anyopaque, done: *bool) callconv(.c) CURLcode;
extern fn Curl_xfer_send_is_paused(data: ?*anyopaque) callconv(.c) bool;
extern fn Curl_debug(data: ?*anyopaque, trc: c_uint, ptr: [*]const u8, size: usize) callconv(.c) void;
extern fn Curl_infof(data: ?*anyopaque, fmt: [*:0]const u8, ...) callconv(.c) void;
extern fn curlx_dyn_ptr(s: *const Dynbuf) callconv(.c) ?[*:0]u8;
extern fn curlx_dyn_len(s: *const Dynbuf) callconv(.c) usize;

extern fn Curl_bufq_init2(
    q: *Bufq,
    chunk_size: usize,
    max_chunks: usize,
    opts: c_int,
) callconv(.c) void;
extern fn Curl_bufq_reset(q: *Bufq) callconv(.c) void;
extern fn Curl_bufq_free(q: *Bufq) callconv(.c) void;
extern fn Curl_bufq_is_empty(q: *const Bufq) callconv(.c) bool;
extern fn Curl_bufq_is_full(q: *const Bufq) callconv(.c) bool;
extern fn Curl_bufq_len(q: *const Bufq) callconv(.c) usize;
extern fn Curl_bufq_peek(q: *Bufq, pbuf: *?[*]const u8, plen: *usize) callconv(.c) bool;
extern fn Curl_bufq_skip(q: *Bufq, amount: usize) callconv(.c) void;
extern fn Curl_bufq_cwrite(
    q: *Bufq,
    buf: [*]const u8,
    len: usize,
    pnwritten: *usize,
) callconv(.c) CURLcode;
extern fn Curl_bufq_sipn(
    q: *Bufq,
    max_len: usize,
    reader: io_buffers.Curl_bufq_reader,
    reader_ctx: ?*anyopaque,
    pnread: *usize,
) callconv(.c) CURLcode;

pub export fn Curl_req_init(req: *SingleRequest) callconv(.c) void {
    @memset(std.mem.asBytes(req), 0);
}

pub export fn Curl_req_soft_reset_zig(
    req: *SingleRequest,
    data: ?*CurlEasyPrefix,
    upload_buffer_size: u32,
) callconv(.c) CURLcode {
    req.tail.word.flags.done = false;
    req.tail.word.flags.upload_done = false;
    req.tail.word.flags.upload_aborted = false;
    req.tail.word.flags.download_done = false;
    req.tail.word.flags.eos_written = false;
    req.tail.word.flags.eos_read = false;
    req.tail.word.flags.eos_sent = false;
    req.tail.word.flags.ignorebody = false;
    req.tail.word.flags.shutdown = false;
    req.bytecount = 0;
    req.writebytecount = 0;
    req.tail.word.flags.header = false;
    req.headerline = 0;
    req.headerbytecount = 0;
    req.allheadercount = 0;
    req.deductheadercount = 0;
    req.httpversion_sent = 0;
    req.httpversion = 0;
    req.sendbuf_hds_len = 0;

    if (req.hd_auth) |p| {
        mem.free(p);
        req.hd_auth = null;
    }
    if (req.hd_proxy_auth) |p| {
        mem.free(p);
        req.hd_proxy_auth = null;
    }

    const result = Curl_client_start(data);
    if (result != CURLE_OK) return result;

    const ubuf_size: usize = upload_buffer_size;
    if (!req.tail.word.flags.sendbuf_init) {
        Curl_bufq_init2(&req.sendbuf, ubuf_size, 1, io_buffers.BUFQ_OPT_SOFT_LIMIT);
        req.tail.word.flags.sendbuf_init = true;
    } else {
        Curl_bufq_reset(&req.sendbuf);
        if (ubuf_size != req.sendbuf.chunk_size) {
            Curl_bufq_free(&req.sendbuf);
            Curl_bufq_init2(&req.sendbuf, ubuf_size, 1, io_buffers.BUFQ_OPT_SOFT_LIMIT);
        }
    }

    return CURLE_OK;
}

pub export fn Curl_req_start_zig(
    req: *SingleRequest,
    data: ?*CurlEasyPrefix,
    upload_buffer_size: u32,
) callconv(.c) CURLcode {
    req.start = Curl_pgrs_now(data).*;
    return Curl_req_soft_reset_zig(req, data, upload_buffer_size);
}

pub export fn Curl_req_done_zig(
    req: *SingleRequest,
    data: ?*CurlEasyPrefix,
    aborted: bool,
    max_send_speed: i64,
) callconv(.c) CURLcode {
    if (!aborted) {
        _ = reqFlush(data, req, max_send_speed);
    }
    Curl_client_reset(data);
    return CURLE_OK;
}

pub export fn Curl_req_hard_reset_zig(
    req: *SingleRequest,
    data: ?*CurlEasyPrefix,
    opt_no_body: bool,
    dl_rlimit: ?*anyopaque,
    ul_rlimit: ?*anyopaque,
) callconv(.c) void {
    const t0 = Curltime{ .tv_sec = 0, .tv_usec = 0 };

    if (req.newurl) |p| {
        mem.free(p);
        req.newurl = null;
    }
    if (req.hd_auth) |p| {
        mem.free(p);
        req.hd_auth = null;
    }
    if (req.hd_proxy_auth) |p| {
        mem.free(p);
        req.hd_proxy_auth = null;
    }
    if (req.cookiehost) |p| {
        mem.free(p);
        req.cookiehost = null;
    }

    Curl_client_reset(data);
    if (req.tail.word.flags.sendbuf_init) {
        Curl_bufq_reset(&req.sendbuf);
    }

    Curl_resolv_destroy_all(data);

    req.size = -1;
    req.maxdownload = -1;
    req.bytecount = 0;
    req.writebytecount = 0;
    req.start = t0;
    req.headerbytecount = 0;
    req.allheadercount = 0;
    req.deductheadercount = 0;
    req.headerline = 0;
    req.offset = 0;
    req.httpcode = 0;
    req.io_flags = 0;
    req.upgr101 = UPGR101_NONE;
    req.sendbuf_hds_len = 0;
    req.timeofdoc = 0;
    req.location = null;
    req.newurl = null;
    req.setSetcookies(0);

    req.tail.word.flags.header = false;
    req.tail.word.flags.content_range = false;
    req.tail.word.flags.download_done = false;
    req.tail.word.flags.eos_written = false;
    req.tail.word.flags.eos_read = false;
    req.tail.word.flags.eos_sent = false;
    req.tail.word.flags.rewind_read = false;
    req.tail.word.flags.upload_done = false;
    req.tail.word.flags.upload_aborted = false;
    req.tail.word.flags.ignorebody = false;
    req.tail.word.flags.http_bodyless = false;
    req.tail.word.flags.chunk = false;
    req.tail.word.flags.resp_trailer = false;
    req.tail.word.flags.ignore_cl = false;
    req.tail.word.flags.upload_chunky = false;
    req.tail.word.flags.no_body = opt_no_body;
    req.tail.word.flags.authneg = false;
    req.tail.word.flags.shutdown = false;

    Curl_rlimit_block(dl_rlimit, false, &t0);
    Curl_rlimit_block(ul_rlimit, false, &t0);
}

pub export fn Curl_req_free(req: *SingleRequest, data: ?*CurlEasyPrefix) callconv(.c) void {
    if (req.newurl) |p| {
        mem.free(p);
        req.newurl = null;
    }
    if (req.hd_auth) |p| {
        mem.free(p);
        req.hd_auth = null;
    }
    if (req.hd_proxy_auth) |p| {
        mem.free(p);
        req.hd_proxy_auth = null;
    }
    if (req.tail.word.flags.sendbuf_init) {
        Curl_bufq_free(&req.sendbuf);
    }
    Curl_client_cleanup(data);
}

fn xferSend(
    data: *CurlEasyPrefix,
    sreq: *SingleRequest,
    buf: [*]const u8,
    blen_in: usize,
    hds_len: usize,
    max_send_speed: i64,
    pnwritten: *usize,
) CURLcode {
    var blen = blen_in;
    var eos = false;

    pnwritten.* = 0;

    if (max_send_speed > 0) {
        const body_bytes = blen - hds_len;
        const max_speed: usize = @intCast(max_send_speed);
        if (body_bytes > max_speed) {
            blen = hds_len + max_speed;
        }
    }

    if (sreq.tail.word.flags.eos_read and
        (Curl_bufq_is_empty(&sreq.sendbuf) or Curl_bufq_len(&sreq.sendbuf) == blen))
    {
        eos = true;
    }

    const result = Curl_xfer_send(data, buf, blen, eos, pnwritten);
    if (result == CURLE_OK) {
        if (eos and blen == pnwritten.*) {
            sreq.tail.word.flags.eos_sent = true;
        }
        if (pnwritten.* > 0) {
            if (hds_len > 0) {
                Curl_debug(data, CURLINFO_HEADER_OUT, buf, @min(hds_len, pnwritten.*));
            }
            if (pnwritten.* > hds_len) {
                const body_len = pnwritten.* - hds_len;
                Curl_debug(data, CURLINFO_DATA_OUT, buf + hds_len, body_len);
                sreq.writebytecount += @intCast(body_len);
                Curl_pgrs_upload_inc(data, body_len);
            }
        }
    }
    return result;
}

fn reqSendBufferFlush(
    data: *CurlEasyPrefix,
    sreq: *SingleRequest,
    max_send_speed: i64,
) CURLcode {
    var result: CURLcode = CURLE_OK;
    var buf_opt: ?[*]const u8 = null;
    var blen: usize = 0;

    while (Curl_bufq_peek(&sreq.sendbuf, &buf_opt, &blen)) {
        const buf = buf_opt.?;
        var nwritten: usize = 0;
        const hds_len = @min(sreq.sendbuf_hds_len, blen);
        result = xferSend(data, sreq, buf, blen, hds_len, max_send_speed, &nwritten);
        if (result != CURLE_OK) break;

        Curl_bufq_skip(&sreq.sendbuf, nwritten);
        if (hds_len > 0) {
            sreq.sendbuf_hds_len -= @min(hds_len, nwritten);
        }
        if (nwritten < blen) break;
    }
    return result;
}

fn reqSetUploadDone(data: *CurlEasyPrefix, sreq: *SingleRequest) CURLcode {
    sreq.tail.word.flags.upload_done = true;
    sreq.io_flags &= ~REQ_IO_SEND;

    if (data.mstate >= MSTATE_DID) {
        Curl_pgrsTime(data, TIMER_POSTRANSFER);
    }
    Curl_creader_done(data, sreq.tail.word.flags.upload_aborted);

    if (sreq.tail.word.flags.upload_aborted) {
        Curl_bufq_reset(&sreq.sendbuf);
        if (sreq.writebytecount != 0) {
            Curl_infof(data, "abort upload after having sent %lld bytes", @as(c_longlong, sreq.writebytecount));
        } else {
            Curl_infof(data, "abort upload");
        }
    } else if (sreq.writebytecount != 0) {
        Curl_infof(data, "upload completely sent off: %lld bytes", @as(c_longlong, sreq.writebytecount));
    } else if (!sreq.tail.word.flags.download_done) {
        if (Curl_creader_total_length(data) != 0) {
            Curl_infof(data, "We are completely uploaded and fine");
        } else {
            Curl_infof(data, "Request completely sent off");
        }
    }

    return Curl_xfer_send_close(data);
}

fn reqFlush(
    data_opt: ?*CurlEasyPrefix,
    sreq: *SingleRequest,
    max_send_speed: i64,
) CURLcode {
    const data = data_opt orelse return CURLE_FAILED_INIT;
    if (data.conn == null) return CURLE_FAILED_INIT;

    if (!Curl_bufq_is_empty(&sreq.sendbuf)) {
        const result = reqSendBufferFlush(data, sreq, max_send_speed);
        if (result != CURLE_OK) return result;
        if (!Curl_bufq_is_empty(&sreq.sendbuf)) {
            return CURLE_AGAIN;
        }
    } else if (Curl_xfer_needs_flush(data)) {
        return Curl_xfer_flush(data);
    }

    if (sreq.tail.word.flags.eos_read and !sreq.tail.word.flags.eos_sent) {
        const tmp: [1]u8 = .{0};
        var nwritten: usize = 0;
        const result = xferSend(data, sreq, &tmp, 0, 0, max_send_speed, &nwritten);
        if (result != CURLE_OK) return result;
    }

    if (!sreq.tail.word.flags.upload_done and
        sreq.tail.word.flags.eos_read and
        sreq.tail.word.flags.eos_sent)
    {
        if (sreq.tail.word.flags.shutdown) {
            var done: bool = false;
            var result = Curl_xfer_send_shutdown(data, &done);
            if (result != CURLE_OK and sreq.tail.word.flags.shutdown_err_ignore) {
                Curl_infof(
                    data,
                    "Shutdown send direction error: %d. Broken server? Proceeding as if everything is ok.",
                    @as(c_int, @intCast(result)),
                );
                result = CURLE_OK;
                done = true;
            }
            if (result != CURLE_OK) return result;
            if (!done) return CURLE_AGAIN;
        }
        return reqSetUploadDone(data, sreq);
    }
    return CURLE_OK;
}

const AddFromClientCtx = struct {
    data: ?*CurlEasyPrefix,
    sreq: *SingleRequest,
};

fn addFromClient(
    reader_ctx: ?*anyopaque,
    buf: [*]u8,
    buflen: usize,
    pnread: *usize,
) callconv(.c) CURLcode {
    const ctx = castParam(AddFromClientCtx, reader_ctx.?);
    var eos: bool = false;
    const result = Curl_client_read(ctx.data, buf, buflen, pnread, &eos);
    if (result == CURLE_OK and eos) {
        ctx.sreq.tail.word.flags.eos_read = true;
    }
    return result;
}

fn reqSendBufferAdd(
    sreq: *SingleRequest,
    buf: [*]const u8,
    blen: usize,
    hds_len: usize,
) CURLcode {
    var n: usize = 0;
    const result = Curl_bufq_cwrite(&sreq.sendbuf, buf, blen, &n);
    if (result != CURLE_OK) return result;
    sreq.sendbuf_hds_len += hds_len;
    return CURLE_OK;
}

pub export fn Curl_req_send_zig(
    data_opt: ?*CurlEasyPrefix,
    sreq: *SingleRequest,
    req: *Dynbuf,
    httpversion: u8,
    max_send_speed: i64,
) callconv(.c) CURLcode {
    const data = data_opt orelse return CURLE_FAILED_INIT;
    if (data.conn == null) return CURLE_FAILED_INIT;

    sreq.httpversion_sent = httpversion;
    const ptr_opt = curlx_dyn_ptr(req);
    var blen = curlx_dyn_len(req);
    const empty: [1]u8 = .{0};
    var buf: [*]const u8 = if (ptr_opt) |p| p else &empty;

    if (Curl_bufq_is_empty(&sreq.sendbuf) and
        Curl_creader_total_length(data) == 0 and
        blen <= sreq.sendbuf.chunk_size)
    {
        sreq.tail.word.flags.eos_read = true;
        var nwritten: usize = 0;
        var result = xferSend(data, sreq, buf, blen, blen, max_send_speed, &nwritten);
        if (result != CURLE_OK) return result;
        buf += nwritten;
        blen -= nwritten;
        if (blen == 0) {
            result = reqSetUploadDone(data, sreq);
            if (result != CURLE_OK) return result;
        }
    }

    if (blen > 0) {
        const result = reqSendBufferAdd(sreq, buf, blen, blen);
        if (result != CURLE_OK) return result;
        return Curl_req_send_more_zig(data, sreq, max_send_speed);
    }
    return CURLE_OK;
}

pub export fn Curl_req_sendbuf_empty_zig(sreq: *SingleRequest) callconv(.c) bool {
    return !sreq.tail.word.flags.sendbuf_init or Curl_bufq_is_empty(&sreq.sendbuf);
}

pub export fn Curl_req_want_send_zig(
    data: ?*CurlEasyPrefix,
    sreq: *SingleRequest,
    ul_rlimit: ?*const anyopaque,
) callconv(.c) bool {
    return !sreq.tail.word.flags.done and
        !Curl_rlimit_is_blocked(ul_rlimit) and
        ((sreq.io_flags & REQ_IO_SEND) != 0 or
            !Curl_req_sendbuf_empty_zig(sreq) or
            Curl_xfer_needs_flush(data));
}

pub export fn Curl_req_want_recv_zig(
    sreq: *SingleRequest,
    dl_rlimit: ?*const anyopaque,
) callconv(.c) bool {
    return !sreq.tail.word.flags.done and
        !Curl_rlimit_is_blocked(dl_rlimit) and
        (sreq.io_flags & REQ_IO_RECV) != 0;
}

pub export fn Curl_req_done_sending_zig(
    data: ?*CurlEasyPrefix,
    sreq: *SingleRequest,
    ul_rlimit: ?*const anyopaque,
) callconv(.c) bool {
    return sreq.tail.word.flags.upload_done and !Curl_req_want_send_zig(data, sreq, ul_rlimit);
}

pub export fn Curl_req_send_more_zig(
    data: ?*CurlEasyPrefix,
    sreq: *SingleRequest,
    max_send_speed: i64,
) callconv(.c) CURLcode {
    if (!sreq.tail.word.flags.upload_aborted and
        !sreq.tail.word.flags.eos_read and
        !Curl_xfer_send_is_paused(data) and
        !Curl_bufq_is_full(&sreq.sendbuf))
    {
        var nread: usize = 0;
        var ctx = AddFromClientCtx{ .data = data, .sreq = sreq };
        const result = Curl_bufq_sipn(&sreq.sendbuf, 0, addFromClient, &ctx, &nread);
        if (result != CURLE_OK and result != CURLE_AGAIN) {
            return result;
        }
    }

    var result = reqFlush(data, sreq, max_send_speed);
    if (result == CURLE_AGAIN) {
        result = CURLE_OK;
    }
    return result;
}

pub export fn Curl_req_abort_sending_zig(
    data: ?*CurlEasyPrefix,
    sreq: *SingleRequest,
) callconv(.c) CURLcode {
    if (!sreq.tail.word.flags.upload_done) {
        Curl_bufq_reset(&sreq.sendbuf);
        sreq.tail.word.flags.upload_aborted = true;
        sreq.io_flags &= ~REQ_IO_SEND;
        if (data) |d| {
            return reqSetUploadDone(d, sreq);
        }
    }
    return CURLE_OK;
}

pub export fn Curl_req_stop_send_recv_zig(
    data: ?*CurlEasyPrefix,
    sreq: *SingleRequest,
) callconv(.c) CURLcode {
    var result: CURLcode = CURLE_OK;
    if ((sreq.io_flags & REQ_IO_SEND) != 0) {
        result = Curl_req_abort_sending_zig(data, sreq);
    }
    sreq.io_flags &= ~(REQ_IO_RECV | REQ_IO_SEND);
    return result;
}

// ============================================================================
// 4. lib/multi_ev.c — Multi Event Socket Tracking and Pollset Diffing
// ============================================================================

const CURL_POLL_IN: u8 = 1;
const CURL_POLL_OUT: u8 = 2;
const CURL_POLL_REMOVE: c_int = 4;

const CURL_META_MEV_POLLSET: [*:0]const u8 = "meta:mev:ps";

pub const CurlMultiEv = extern struct {
    sh_entries: CurlHash,
};

const MevShEntry = struct {
    xfers: Uint32Spbset,
    conn: ?*anyopaque,
    user_data: ?*anyopaque,
    action: c_uint,
    readers: c_uint,
    writers: c_uint,
    announced: bool,
};

const MetaDtor = *const fn (key: ?*const anyopaque, klen: usize, entry: ?*anyopaque) callconv(.c) void;

extern fn Curl_multi_get_easy(multi: ?*anyopaque, mid: u32) callconv(.c) ?*CurlEasyPrefix;
extern fn Curl_multi_mark_dirty(data: ?*anyopaque) callconv(.c) void;
extern fn Curl_multi_pollset(data: ?*anyopaque, ps: *EasyPollset) callconv(.c) CURLMcode;
extern fn Curl_conn_adjust_pollset(
    data: ?*anyopaque,
    conn: ?*anyopaque,
    ps: *EasyPollset,
) callconv(.c) CURLcode;
extern fn Curl_meta_set(
    data: ?*anyopaque,
    key: [*:0]const u8,
    meta_data: ?*anyopaque,
    meta_dtor: MetaDtor,
) callconv(.c) CURLcode;
extern fn Curl_meta_get(data: ?*anyopaque, key: [*:0]const u8) callconv(.c) ?*anyopaque;
extern fn Curl_meta_remove(data: ?*anyopaque, key: [*:0]const u8) callconv(.c) void;
extern fn Curl_conn_meta_set(
    conn: ?*anyopaque,
    key: [*:0]const u8,
    meta_data: ?*anyopaque,
    meta_dtor: MetaDtor,
) callconv(.c) CURLcode;
extern fn Curl_conn_meta_get(conn: ?*anyopaque, key: [*:0]const u8) callconv(.c) ?*anyopaque;
extern fn Curl_conn_meta_remove(conn: ?*anyopaque, key: [*:0]const u8) callconv(.c) void;

extern fn Curl_hash_init(
    h: *CurlHash,
    slots: usize,
    hash_type: collections.Curl_hash_type,
    dtor: ?collections.Curl_hash_dtor,
) callconv(.c) void;
extern fn Curl_hash_destroy(h: *CurlHash) callconv(.c) void;
extern fn Curl_hash_pick(h: *CurlHash, key: ?*const anyopaque, key_len: usize) callconv(.c) ?*anyopaque;
extern fn Curl_hash_add(
    h: *CurlHash,
    key: ?*const anyopaque,
    key_len: usize,
    p: ?*anyopaque,
) callconv(.c) ?*anyopaque;
extern fn Curl_hash_delete(h: *CurlHash, key: ?*const anyopaque, key_len: usize) callconv(.c) c_int;

extern fn Curl_uint32_spbset_init(bset: *Uint32Spbset) callconv(.c) void;
extern fn Curl_uint32_spbset_destroy(bset: *Uint32Spbset) callconv(.c) void;
extern fn Curl_uint32_spbset_count(bset: *Uint32Spbset) callconv(.c) u32;
extern fn Curl_uint32_spbset_add(bset: ?*Uint32Spbset, i: u32) callconv(.c) bool;
extern fn Curl_uint32_spbset_remove(bset: ?*Uint32Spbset, i: u32) callconv(.c) void;
extern fn Curl_uint32_spbset_contains(bset: ?*Uint32Spbset, i: u32) callconv(.c) bool;
extern fn Curl_uint32_spbset_first(bset: *Uint32Spbset, pfirst: *u32) callconv(.c) bool;
extern fn Curl_uint32_spbset_next(bset: *Uint32Spbset, last: u32, pnext: *u32) callconv(.c) bool;

extern fn Curl_uint32_bset_first(bset: *Uint32Bset, pfirst: *u32) callconv(.c) bool;
extern fn Curl_uint32_bset_next(bset: *Uint32Bset, last: u32, pnext: *u32) callconv(.c) bool;

extern fn Curl_pollset_create() callconv(.c) ?*EasyPollset;
extern fn Curl_pollset_init(ps: *EasyPollset) callconv(.c) void;
extern fn Curl_pollset_cleanup(ps: *EasyPollset) callconv(.c) void;
extern fn Curl_pollset_move(to: *EasyPollset, from: *EasyPollset) callconv(.c) void;
extern fn Curl_pollset_remove(ps: *EasyPollset, sock: curl_socket_t) callconv(.c) void;

fn mevShEntryDtor(freethis: ?*anyopaque) callconv(.c) void {
    const raw = freethis orelse return;
    const entry = castParam(MevShEntry, raw);
    Curl_uint32_spbset_destroy(&entry.xfers);
    mem.freeTyped(entry);
}

fn mevShEntryGet(sh: *CurlHash, s: curl_socket_t) ?*MevShEntry {
    if (s != CURL_SOCKET_BAD) {
        var sock = s;
        return collections.hashPickTyped(MevShEntry, sh, &sock, @sizeOf(curl_socket_t));
    }
    return null;
}

fn mevShEntryCreate(sh: *CurlHash, s: curl_socket_t) error{OutOfMemory}!*MevShEntry {
    const check = mem.create(MevShEntry) orelse return error.OutOfMemory;
    errdefer mevShEntryDtor(check);
    Curl_uint32_spbset_init(&check.xfers);

    var sock = s;
    if (collections.hashAddTyped(MevShEntry, sh, &sock, @sizeOf(curl_socket_t), check) == null) {
        return error.OutOfMemory;
    }
    return check;
}

fn mevShEntryAdd(sh: *CurlHash, s: curl_socket_t) ?*MevShEntry {
    if (mevShEntryGet(sh, s)) |there| {
        return there;
    }
    return mevShEntryCreate(sh, s) catch null;
}

fn mevShEntryKill(ev: *CurlMultiEv, s: curl_socket_t) void {
    var sock = s;
    _ = Curl_hash_delete(&ev.sh_entries, &sock, @sizeOf(curl_socket_t));
}

inline fn mevShEntryUserCount(e: *MevShEntry) usize {
    return @as(usize, Curl_uint32_spbset_count(&e.xfers)) + @as(usize, if (e.conn != null) 1 else 0);
}

inline fn mevShEntryXferKnown(e: *MevShEntry, data: *const CurlEasyPrefix) bool {
    return Curl_uint32_spbset_contains(&e.xfers, data.mid);
}

inline fn mevShEntryConnKnown(e: *const MevShEntry, conn: ?*const anyopaque) bool {
    return e.conn == conn;
}

fn mevPollsetDtor(key: ?*const anyopaque, klen: usize, entry: ?*anyopaque) callconv(.c) void {
    _ = key;
    _ = klen;
    if (entry) |raw| {
        const ps = castParam(EasyPollset, raw);
        Curl_pollset_cleanup(ps);
        mem.freeTyped(ps);
    }
}

fn mevAddNewConnPollset(conn: ?*anyopaque) ?*EasyPollset {
    const ps = Curl_pollset_create() orelse return null;
    if (Curl_conn_meta_set(conn, CURL_META_MEV_POLLSET, ps, mevPollsetDtor) != CURLE_OK) {
        return null;
    }
    return ps;
}

fn mevAddNewXferPollset(data: ?*CurlEasyPrefix) ?*EasyPollset {
    const ps = Curl_pollset_create() orelse return null;
    if (Curl_meta_set(data, CURL_META_MEV_POLLSET, ps, mevPollsetDtor) != CURLE_OK) {
        return null;
    }
    return ps;
}

fn mevGetLastPollset(data: ?*CurlEasyPrefix, conn: ?*anyopaque) ?*EasyPollset {
    if (data != null) {
        return if (conn != null)
            doh_hostip_easy.connMetaGetTyped(EasyPollset, conn, CURL_META_MEV_POLLSET)
        else
            doh_hostip_easy.metaGetTyped(EasyPollset, data, CURL_META_MEV_POLLSET);
    }
    return null;
}

inline fn mevShEntryXferAdd(e: *MevShEntry, data: *const CurlEasyPrefix) bool {
    return Curl_uint32_spbset_add(&e.xfers, data.mid);
}

inline fn mevShEntryConnAdd(e: *MevShEntry, conn: ?*anyopaque) bool {
    if (e.conn != null) return false;
    e.conn = conn;
    return true;
}

inline fn mevShEntryXferRemove(e: *MevShEntry, data: *const CurlEasyPrefix) bool {
    const present = Curl_uint32_spbset_contains(&e.xfers, data.mid);
    if (present) {
        Curl_uint32_spbset_remove(&e.xfers, data.mid);
    }
    return present;
}

inline fn mevShEntryConnRemove(e: *MevShEntry, conn: ?*anyopaque) bool {
    if (e.conn == conn) {
        e.conn = null;
        return true;
    }
    return false;
}

fn mevForgetSocket(
    multi: *CurlMultiPrefix,
    ev: *CurlMultiEv,
    data: ?*CurlEasyPrefix,
    s: curl_socket_t,
) CURLMcode {
    var entry = mevShEntryGet(&ev.sh_entries, s) orelse return CURLM_OK;
    var mid: u32 = 0;
    var rc: c_int = 0;

    if (Curl_uint32_spbset_first(&entry.xfers, &mid)) {
        while (true) {
            if (Curl_multi_get_easy(multi, mid)) |sdata| {
                if (mevGetLastPollset(sdata, null)) |ps| {
                    Curl_pollset_remove(ps, s);
                }
            }
            if (!Curl_uint32_spbset_next(&entry.xfers, mid, &mid)) break;
        }
    }

    if (entry.conn) |c| {
        if (mevGetLastPollset(data, c)) |ps| {
            Curl_pollset_remove(ps, s);
        }
    }

    if (entry.announced) {
        if (multi.socket_cb) |socket_cb| {
            var guard: CurlMapiGuard = undefined;
            Curl_cbapi_enter(&guard, null, multi, CURL_CBAPI_FN_multi_socket_cb);
            rc = socket_cb(data, s, CURL_POLL_REMOVE, multi.socket_userp, entry.user_data);
            Curl_cbapi_leave(&guard);
            if (mevShEntryGet(&ev.sh_entries, s)) |re_entry| {
                entry = re_entry;
                entry.announced = false;
            }
        }
    }

    mevShEntryKill(ev, s);
    if (rc == -1) {
        return CURLM_ABORTED_BY_CALLBACK;
    }
    return CURLM_OK;
}

fn mevShEntryUpdate(
    multi: *CurlMultiPrefix,
    ev: *CurlMultiEv,
    data: ?*CurlEasyPrefix,
    entry_in: *MevShEntry,
    s: curl_socket_t,
    last_action: u8,
    cur_action: u8,
) CURLMcode {
    const socket_cb = multi.socket_cb orelse return CURLM_OK;
    if (last_action == cur_action) return CURLM_OK;

    if ((last_action & CURL_POLL_IN) != 0) {
        if ((cur_action & CURL_POLL_IN) == 0) {
            entry_in.readers -= 1;
        }
    } else if ((cur_action & CURL_POLL_IN) != 0) {
        entry_in.readers += 1;
    }

    if ((last_action & CURL_POLL_OUT) != 0) {
        if ((cur_action & CURL_POLL_OUT) == 0) {
            entry_in.writers -= 1;
        }
    } else if ((cur_action & CURL_POLL_OUT) != 0) {
        entry_in.writers += 1;
    }

    const comboaction: c_int = (if (entry_in.writers != 0) @as(c_int, CURL_POLL_OUT) else 0) |
        (if (entry_in.readers != 0) @as(c_int, CURL_POLL_IN) else 0);
    if (@as(c_int, @intCast(entry_in.action)) == comboaction) {
        return CURLM_OK;
    }

    var guard: CurlMapiGuard = undefined;
    Curl_cbapi_enter(&guard, null, multi, CURL_CBAPI_FN_multi_socket_cb);
    const rc = socket_cb(data, s, comboaction, multi.socket_userp, entry_in.user_data);
    Curl_cbapi_leave(&guard);

    if (rc == -1) {
        return CURLM_ABORTED_BY_CALLBACK;
    }

    if (mevShEntryGet(&ev.sh_entries, s)) |entry| {
        entry.announced = true;
        entry.action = @intCast(comboaction);
    }
    return CURLM_OK;
}

fn mevPollsetDiff(
    multi: *CurlMultiPrefix,
    ev: *CurlMultiEv,
    data: *CurlEasyPrefix,
    conn: ?*anyopaque,
    ps: *EasyPollset,
    prev_ps: *EasyPollset,
) CURLMcode {
    const mid = data.mid;
    const ps_sockets = ps.sockets.?;
    const ps_actions = ps.actions.?;
    const prev_sockets = prev_ps.sockets.?;
    const prev_actions = prev_ps.actions.?;

    var i: c_uint = 0;
    while (i < ps.n) : (i += 1) {
        var first_time = false;
        const s = ps_sockets[i];

        var entry = mevShEntryGet(&ev.sh_entries, s);
        if (entry == null) {
            first_time = true;
            entry = mevShEntryAdd(&ev.sh_entries, s);
            if (entry == null) return CURLM_OUT_OF_MEMORY;
        } else if (conn != null) {
            first_time = !mevShEntryConnKnown(entry.?, conn);
        } else {
            first_time = !mevShEntryXferKnown(entry.?, data);
        }

        const e = entry.?;
        var last_action: u8 = 0;
        if (first_time) {
            if (conn != null) {
                if (!mevShEntryConnAdd(e, conn)) return CURLM_OUT_OF_MEMORY;
            } else {
                if (!mevShEntryXferAdd(e, data)) return CURLM_OUT_OF_MEMORY;
            }
        } else {
            var j: c_uint = 0;
            while (j < prev_ps.n) : (j += 1) {
                if (s == prev_sockets[j]) {
                    last_action = prev_actions[j];
                    break;
                }
            }
        }

        const mresult = mevShEntryUpdate(multi, ev, data, e, s, last_action, ps_actions[i]);
        if (mresult != CURLM_OK) return mresult;
        if (Curl_multi_get_easy(multi, mid) != data or mevGetLastPollset(data, conn) != prev_ps) {
            return CURLM_OK;
        }
    }

    i = 0;
    while (i < prev_ps.n) : (i += 1) {
        var stillused = false;
        const s = prev_sockets[i];

        var j: c_uint = 0;
        while (j < ps.n) : (j += 1) {
            if (s == ps_sockets[j]) {
                stillused = true;
                break;
            }
        }
        if (stillused) continue;

        const entry = mevShEntryGet(&ev.sh_entries, s) orelse continue;

        if (conn != null and !mevShEntryConnRemove(entry, conn)) {
            continue;
        }
        if (conn == null and !mevShEntryXferRemove(entry, data)) {
            continue;
        }

        if (mevShEntryUserCount(entry) != 0) {
            const mresult = mevShEntryUpdate(multi, ev, data, entry, s, prev_actions[i], 0);
            if (mresult != CURLM_OK) return mresult;
        } else {
            const mresult = mevForgetSocket(multi, ev, data, s);
            if (mresult != CURLM_OK) return mresult;
        }
        if (Curl_multi_get_easy(multi, mid) != data or mevGetLastPollset(data, conn) != prev_ps) {
            return CURLM_OK;
        }
    }

    Curl_pollset_move(prev_ps, ps);
    return CURLM_OK;
}

fn mevAssess(
    multi_opt: ?*CurlMultiPrefix,
    ev: *CurlMultiEv,
    data_opt: ?*CurlEasyPrefix,
    conn: ?*anyopaque,
) CURLMcode {
    const multi = multi_opt orelse return CURLM_OK;
    if (multi.socket_cb == null) return CURLM_OK;
    const data = data_opt orelse return CURLM_OK;

    var ps: EasyPollset = undefined;
    var mresult: CURLMcode = CURLM_OK;

    Curl_pollset_init(&ps);
    if (conn != null) {
        const result = Curl_conn_adjust_pollset(data, conn, &ps);
        if (result != CURLE_OK) {
            mresult = if (result == CURLE_OUT_OF_MEMORY) CURLM_OUT_OF_MEMORY else CURLM_INTERNAL_ERROR;
            Curl_pollset_cleanup(&ps);
            return mresult;
        }
    } else {
        _ = Curl_multi_pollset(data, &ps);
    }

    var last_ps = mevGetLastPollset(data, conn);
    if (last_ps == null and ps.n != 0) {
        last_ps = if (conn != null)
            mevAddNewConnPollset(conn)
        else
            mevAddNewXferPollset(data);
        if (last_ps == null) {
            Curl_pollset_cleanup(&ps);
            return CURLM_OUT_OF_MEMORY;
        }
    }

    if (last_ps) |lps| {
        mresult = mevPollsetDiff(multi, ev, data, conn, &ps, lps);
    }

    Curl_pollset_cleanup(&ps);
    return mresult;
}

pub export fn Curl_multi_ev_assess_xfer_zig(
    multi: ?*CurlMultiPrefix,
    ev: *CurlMultiEv,
    data: ?*CurlEasyPrefix,
) callconv(.c) CURLMcode {
    return mevAssess(multi, ev, data, null);
}

pub export fn Curl_multi_ev_assess_conn_zig(
    multi: ?*CurlMultiPrefix,
    ev: *CurlMultiEv,
    data: ?*CurlEasyPrefix,
    conn: ?*anyopaque,
) callconv(.c) CURLMcode {
    return mevAssess(multi, ev, data, conn);
}

pub export fn Curl_multi_ev_assess_xfer_bset_zig(
    multi_opt: ?*CurlMultiPrefix,
    ev: *CurlMultiEv,
    set: *Uint32Bset,
) callconv(.c) CURLMcode {
    var mresult: CURLMcode = CURLM_OK;
    const multi = multi_opt orelse return CURLM_OK;
    var mid: u32 = 0;

    if (multi.socket_cb != null and Curl_uint32_bset_first(set, &mid)) {
        while (true) {
            if (Curl_multi_get_easy(multi, mid)) |data| {
                mresult = Curl_multi_ev_assess_xfer_zig(multi, ev, data);
            }
            if (mresult != CURLM_OK or !Curl_uint32_bset_next(set, mid, &mid)) break;
        }
    }
    return mresult;
}

pub export fn Curl_multi_ev_assign_zig(
    multi: ?*CurlMultiPrefix,
    ev: *CurlMultiEv,
    s: curl_socket_t,
    user_data: ?*anyopaque,
) callconv(.c) CURLMcode {
    _ = multi;
    const e = mevShEntryGet(&ev.sh_entries, s) orelse return CURLM_BAD_SOCKET;
    e.user_data = user_data;
    return CURLM_OK;
}

pub export fn Curl_multi_ev_dirty_xfers_zig(
    multi_opt: ?*CurlMultiPrefix,
    ev: *CurlMultiEv,
    s: curl_socket_t,
) callconv(.c) void {
    const multi = multi_opt orelse return;
    const entry = mevShEntryGet(&ev.sh_entries, s) orelse return;
    var mid: u32 = 0;

    if (Curl_uint32_spbset_first(&entry.xfers, &mid)) {
        while (true) {
            if (Curl_multi_get_easy(multi, mid)) |data| {
                Curl_multi_mark_dirty(data);
            } else {
                Curl_uint32_spbset_remove(&entry.xfers, mid);
            }
            if (!Curl_uint32_spbset_next(&entry.xfers, mid, &mid)) break;
        }
    }

    if (entry.conn != null) {
        Curl_multi_mark_dirty(multi.admin);
    }
}

pub export fn Curl_multi_ev_socket_done_zig(
    multi_opt: ?*CurlMultiPrefix,
    ev: *CurlMultiEv,
    data: ?*CurlEasyPrefix,
    s: curl_socket_t,
) callconv(.c) CURLMcode {
    const multi = multi_opt orelse return CURLM_OK;
    return mevForgetSocket(multi, ev, data, s);
}

pub export fn Curl_multi_ev_xfer_done_zig(
    multi: ?*CurlMultiPrefix,
    ev: *CurlMultiEv,
    data: ?*CurlEasyPrefix,
) callconv(.c) CURLMcode {
    const mresult = mevAssess(multi, ev, data, null);
    Curl_meta_remove(data, CURL_META_MEV_POLLSET);
    return mresult;
}

pub export fn Curl_multi_ev_conn_done_zig(
    multi: ?*CurlMultiPrefix,
    ev: *CurlMultiEv,
    data: ?*CurlEasyPrefix,
    conn: ?*anyopaque,
) callconv(.c) CURLMcode {
    const mresult = mevAssess(multi, ev, data, conn);
    Curl_conn_meta_remove(conn, CURL_META_MEV_POLLSET);
    return mresult;
}

pub export fn Curl_multi_ev_init_zig(
    multi: ?*CurlMultiPrefix,
    ev: *CurlMultiEv,
    hashsize: usize,
) callconv(.c) void {
    _ = multi;
    Curl_hash_init(
        &ev.sh_entries,
        hashsize,
        collections.CURL_HASH_TYPE_SOCKET,
        mevShEntryDtor,
    );
}

pub export fn Curl_multi_ev_cleanup_zig(
    multi: ?*CurlMultiPrefix,
    ev: *CurlMultiEv,
) callconv(.c) void {
    _ = multi;
    Curl_hash_destroy(&ev.sh_entries);
}

// ============================================================================
// Unit Tests
// ============================================================================

test "Curl_eapi_hcode error mapping" {
    try std.testing.expectEqual(CURLHE_OK, Curl_eapi_hcode(CURLE_OK));
    try std.testing.expectEqual(CURLHE_BAD_ARGUMENT, Curl_eapi_hcode(CURLE_BAD_FUNCTION_ARGUMENT));
    try std.testing.expectEqual(CURLHE_OUT_OF_MEMORY, Curl_eapi_hcode(CURLE_OUT_OF_MEMORY));
    try std.testing.expectEqual(CURLHE_NOT_BUILT_IN, Curl_eapi_hcode(CURLE_NOT_BUILT_IN));
    try std.testing.expectEqual(CURLHE_BAD_ARGUMENT, Curl_eapi_hcode(CURLE_UNKNOWN_OPTION));
}

test "Curl_mapi_enter, Curl_cbapi_enter, and recursion checks" {
    var multi: CurlMultiPrefix = std.mem.zeroes(CurlMultiPrefix);
    multi.magic = CURL_MULTI_HANDLE;

    var guard1: CurlMapiGuard = undefined;
    var mres: CURLMcode = CURLM_OK;

    // Non-recursive multi_perform enters at depth 1
    try std.testing.expect(Curl_mapi_enter(&guard1, &multi, CURL_MAPI_FN_multi_perform, &mres));
    try std.testing.expectEqual(CURLM_OK, mres);
    try std.testing.expectEqual(@as(u8, 1), multi.callstack.count);
    try std.testing.expect(!Curl_api_multi_is_in_callback(&multi));

    // Entering multi_perform again while on callstack must fail with CURLM_RECURSIVE_API_CALL
    var guard2: CurlMapiGuard = undefined;
    try std.testing.expect(!Curl_mapi_enter(&guard2, &multi, CURL_MAPI_FN_multi_perform, &mres));
    try std.testing.expectEqual(CURLM_RECURSIVE_API_CALL, mres);

    // Entering callback sets callback state
    var cb_guard: CurlMapiGuard = undefined;
    Curl_cbapi_enter(&cb_guard, null, &multi, CURL_CBAPI_FN_multi_ntfy_cb);
    try std.testing.expect(Curl_api_multi_is_in_callback(&multi));

    // multi_add_handle is allowed inside notify callback
    var guard3: CurlMapiGuard = undefined;
    try std.testing.expect(Curl_mapi_enter(&guard3, &multi, CURL_MAPI_FN_multi_add_handle, &mres));
    try std.testing.expectEqual(CURLM_OK, mres);
    Curl_mapi_leave(&guard3);

    Curl_cbapi_leave(&cb_guard);
    try std.testing.expect(!Curl_api_multi_is_in_callback(&multi));

    Curl_mapi_leave(&guard1);
    try std.testing.expectEqual(@as(u8, 0), multi.callstack.count);
}

test "Curl_getinfo string, long, double, and off_t queries" {
    var easy: CurlEasyPrefix = std.mem.zeroes(CurlEasyPrefix);
    easy.magic = CURLEASY_MAGIC_NUMBER;
    easy.mid = std.math.maxInt(u32);

    var pure: PureInfoPrefix = std.mem.zeroes(PureInfoPrefix);
    pure.httpcode = 200;
    pure.httpversion = 20;
    pure.filetime = 1700000000;
    pure.header_size = 512;
    pure.request_size = 256;
    pure.primary.transport = TRNSPRT_TCP;
    pure.primary.remote_port = 443;

    var tsi: CurlTlssessioninfo = .{ .backend = 0, .internals = null };
    var ctx: CurlGetinfoCtx = std.mem.zeroes(CurlGetinfoCtx);
    ctx.info = &pure;
    ctx.tsi = &tsi;
    ctx.httpreq = HTTPREQ_POST;
    ctx.spent_us = 2_500_000;
    ctx.dl_cur_size = 4096;
    ctx.dl_size_known = 1;
    ctx.dl_total_size = 8192;

    var method_ptr: ?[*:0]const u8 = null;
    try std.testing.expectEqual(
        CURLE_OK,
        Curl_getinfo_zig(&easy, &ctx, CURLINFO_EFFECTIVE_METHOD, mem.toRawPtr(&method_ptr)),
    );
    try std.testing.expectEqualStrings("POST", std.mem.span(method_ptr.?));

    var code: c_long = 0;
    try std.testing.expectEqual(
        CURLE_OK,
        Curl_getinfo_zig(&easy, &ctx, CURLINFO_RESPONSE_CODE, &code),
    );
    try std.testing.expectEqual(@as(c_long, 200), code);

    var http_ver: c_long = 0;
    try std.testing.expectEqual(
        CURLE_OK,
        Curl_getinfo_zig(&easy, &ctx, CURLINFO_HTTP_VERSION, &http_ver),
    );
    try std.testing.expectEqual(@as(c_long, 3), http_ver);

    var port: c_long = 0;
    try std.testing.expectEqual(
        CURLE_OK,
        Curl_getinfo_zig(&easy, &ctx, CURLINFO_PRIMARY_PORT, &port),
    );
    try std.testing.expectEqual(@as(c_long, 443), port);

    var total_sec: f64 = 0.0;
    try std.testing.expectEqual(
        CURLE_OK,
        Curl_getinfo_zig(&easy, &ctx, CURLINFO_TOTAL_TIME, &total_sec),
    );
    try std.testing.expectApproxEqAbs(@as(f64, 2.5), total_sec, 1e-6);

    var cl_dl: i64 = 0;
    try std.testing.expectEqual(
        CURLE_OK,
        Curl_getinfo_zig(&easy, &ctx, CURLINFO_CONTENT_LENGTH_DOWNLOAD_T, &cl_dl),
    );
    try std.testing.expectEqual(@as(i64, 8192), cl_dl);
}

test "Curl_req_init and Curl_req_sendbuf_empty" {
    var req: SingleRequest = undefined;
    Curl_req_init(&req);
    try std.testing.expect(Curl_req_sendbuf_empty_zig(&req));
    req.setSetcookies(3);
    if (builtin.os.tag == .windows) {
        try std.testing.expectEqual(@as(u8, 3), req.tail.setcookies);
    } else {
        try std.testing.expectEqual(@as(u8, 3), req.tail.word.setcookies);
    }
}

test "Curl_multi_ev_init, assign on unknown socket, and cleanup" {
    var multi: CurlMultiPrefix = std.mem.zeroes(CurlMultiPrefix);
    multi.magic = CURL_MULTI_HANDLE;
    var ev: CurlMultiEv = undefined;

    Curl_multi_ev_init_zig(&multi, &ev, 7);
    try std.testing.expectEqual(CURLM_BAD_SOCKET, Curl_multi_ev_assign_zig(&multi, &ev, 42, null));
    Curl_multi_ev_cleanup_zig(&multi, &ev);
}

// ============================================================================
// C-Zig ABI & Struct Layout Verification
// ============================================================================

comptime {
    // 1. CurlEapiStack, CurlMapiStack, CurlEapiGuard, CurlMapiGuard
    std.debug.assert(@sizeOf(CurlEapiStack) == 16);
    std.debug.assert(@alignOf(CurlEapiStack) == 2);
    std.debug.assert(@offsetOf(CurlEapiStack, "count") == 0);
    std.debug.assert(@offsetOf(CurlEapiStack, "calls") == 2);

    std.debug.assert(@sizeOf(CurlMapiStack) == 16);
    std.debug.assert(@alignOf(CurlMapiStack) == 1);
    std.debug.assert(@offsetOf(CurlMapiStack, "count") == 0);
    std.debug.assert(@offsetOf(CurlMapiStack, "calls") == 1);

    std.debug.assert(@sizeOf(CurlEapiGuard) == 16);
    std.debug.assert(@alignOf(CurlEapiGuard) == 8);
    std.debug.assert(@offsetOf(CurlEapiGuard, "data") == 0);
    std.debug.assert(@offsetOf(CurlEapiGuard, "depth") == 8);

    std.debug.assert(@sizeOf(CurlMapiGuard) == 16);
    std.debug.assert(@alignOf(CurlMapiGuard) == 8);
    std.debug.assert(@offsetOf(CurlMapiGuard, "multi") == 0);
    std.debug.assert(@offsetOf(CurlMapiGuard, "depth") == 8);

    // 2. CurlEasyPrefix
    std.debug.assert(@sizeOf(CurlEasyPrefix) == 48);
    std.debug.assert(@alignOf(CurlEasyPrefix) == 8);
    std.debug.assert(@offsetOf(CurlEasyPrefix, "magic") == 0);
    std.debug.assert(@offsetOf(CurlEasyPrefix, "mid") == 4);
    std.debug.assert(@offsetOf(CurlEasyPrefix, "mstate") == 8);
    std.debug.assert(@offsetOf(CurlEasyPrefix, "result") == 12);
    std.debug.assert(@offsetOf(CurlEasyPrefix, "conn") == 16);
    std.debug.assert(@offsetOf(CurlEasyPrefix, "multi") == 24);
    std.debug.assert(@offsetOf(CurlEasyPrefix, "callstack") == 32);

    // 3. CurlMultiPrefix
    std.debug.assert(@sizeOf(CurlMultiPrefix) == 232);
    std.debug.assert(@alignOf(CurlMultiPrefix) == 8);
    std.debug.assert(@offsetOf(CurlMultiPrefix, "magic") == 0);
    std.debug.assert(@offsetOf(CurlMultiPrefix, "xfers_alive") == 4);
    std.debug.assert(@offsetOf(CurlMultiPrefix, "xfers_really_alive") == 8);
    std.debug.assert(@offsetOf(CurlMultiPrefix, "max_concurrent_streams") == 12);
    std.debug.assert(@offsetOf(CurlMultiPrefix, "xfers_total_ever") == 16);
    std.debug.assert(@offsetOf(CurlMultiPrefix, "xfers") == 24);
    std.debug.assert(@offsetOf(CurlMultiPrefix, "process") == 48);
    std.debug.assert(@offsetOf(CurlMultiPrefix, "dirty") == 64);
    std.debug.assert(@offsetOf(CurlMultiPrefix, "pending") == 80);
    std.debug.assert(@offsetOf(CurlMultiPrefix, "msgsent") == 96);
    std.debug.assert(@offsetOf(CurlMultiPrefix, "callstack") == 112);
    std.debug.assert(@offsetOf(CurlMultiPrefix, "timeouts") == 128);
    std.debug.assert(@offsetOf(CurlMultiPrefix, "admin") == 144);
    std.debug.assert(@offsetOf(CurlMultiPrefix, "socket_cb") == 152);
    std.debug.assert(@offsetOf(CurlMultiPrefix, "socket_userp") == 160);
    std.debug.assert(@offsetOf(CurlMultiPrefix, "push_cb") == 168);
    std.debug.assert(@offsetOf(CurlMultiPrefix, "push_userp") == 176);
    std.debug.assert(@offsetOf(CurlMultiPrefix, "dnscache") == 184);
    std.debug.assert(@offsetOf(CurlMultiPrefix, "ssl_scache") == 224);

    // 4. PureInfoPrefix & CurlGetinfoCtx
    std.debug.assert(@sizeOf(PureInfoPrefix) == 224);
    std.debug.assert(@alignOf(PureInfoPrefix) == 8);
    std.debug.assert(@offsetOf(PureInfoPrefix, "primary") == 0);
    std.debug.assert(@offsetOf(PureInfoPrefix, "certs") == 104);
    std.debug.assert(@offsetOf(PureInfoPrefix, "filetime") == 120);
    std.debug.assert(@offsetOf(PureInfoPrefix, "request_size") == 128);
    std.debug.assert(@offsetOf(PureInfoPrefix, "numconnects") == 136);
    std.debug.assert(@offsetOf(PureInfoPrefix, "contenttype") == 144);
    std.debug.assert(@offsetOf(PureInfoPrefix, "wouldredirect") == 152);
    std.debug.assert(@offsetOf(PureInfoPrefix, "effective_url") == 160);
    std.debug.assert(@offsetOf(PureInfoPrefix, "retry_after") == 168);
    std.debug.assert(@offsetOf(PureInfoPrefix, "conn_scheme") == 176);
    std.debug.assert(@offsetOf(PureInfoPrefix, "httpcode") == 184);
    std.debug.assert(@offsetOf(PureInfoPrefix, "httpproxycode") == 188);
    std.debug.assert(@offsetOf(PureInfoPrefix, "httpversion") == 192);
    std.debug.assert(@offsetOf(PureInfoPrefix, "conn_protocol") == 196);
    std.debug.assert(@offsetOf(PureInfoPrefix, "proxyauthavail") == 200);
    std.debug.assert(@offsetOf(PureInfoPrefix, "httpauthavail") == 204);
    std.debug.assert(@offsetOf(PureInfoPrefix, "proxyauthpicked") == 208);
    std.debug.assert(@offsetOf(PureInfoPrefix, "httpauthpicked") == 212);
    std.debug.assert(@offsetOf(PureInfoPrefix, "header_size") == 216);
    std.debug.assert(@offsetOf(PureInfoPrefix, "pxcode") == 220);

    std.debug.assert(@sizeOf(CurlGetinfoCtx) == 264 + 2 * @sizeOf(c_long));
    std.debug.assert(@alignOf(CurlGetinfoCtx) == 8);
    std.debug.assert(@offsetOf(CurlGetinfoCtx, "info") == 0);
    std.debug.assert(@offsetOf(CurlGetinfoCtx, "tsi") == 8);
    std.debug.assert(@offsetOf(CurlGetinfoCtx, "url_str") == 16);
    std.debug.assert(@offsetOf(CurlGetinfoCtx, "referer_str") == 24);
    std.debug.assert(@offsetOf(CurlGetinfoCtx, "custom_request") == 32);
    std.debug.assert(@offsetOf(CurlGetinfoCtx, "ftp_entrypath") == 40);
    std.debug.assert(@offsetOf(CurlGetinfoCtx, "rtsp_session_id") == 48);
    std.debug.assert(@offsetOf(CurlGetinfoCtx, "cainfo_default") == 56);
    std.debug.assert(@offsetOf(CurlGetinfoCtx, "capath_default") == 64);
    std.debug.assert(@offsetOf(CurlGetinfoCtx, "private_data") == 72);
    std.debug.assert(@offsetOf(CurlGetinfoCtx, "xfer_id") == 80);
    std.debug.assert(@offsetOf(CurlGetinfoCtx, "last_conn_id") == 88);
    std.debug.assert(@offsetOf(CurlGetinfoCtx, "deliver") == 96);
    std.debug.assert(@offsetOf(CurlGetinfoCtx, "earlydata_sent") == 104);
    std.debug.assert(@offsetOf(CurlGetinfoCtx, "ul_total_size") == 112);
    std.debug.assert(@offsetOf(CurlGetinfoCtx, "ul_cur_size") == 120);
    std.debug.assert(@offsetOf(CurlGetinfoCtx, "ul_speed") == 128);
    std.debug.assert(@offsetOf(CurlGetinfoCtx, "dl_total_size") == 136);
    std.debug.assert(@offsetOf(CurlGetinfoCtx, "dl_cur_size") == 144);
    std.debug.assert(@offsetOf(CurlGetinfoCtx, "dl_speed") == 152);
    std.debug.assert(@offsetOf(CurlGetinfoCtx, "spent_us") == 160);
    std.debug.assert(@offsetOf(CurlGetinfoCtx, "queued_us") == 168);
    std.debug.assert(@offsetOf(CurlGetinfoCtx, "nslookup_us") == 176);
    std.debug.assert(@offsetOf(CurlGetinfoCtx, "connect_us") == 184);
    std.debug.assert(@offsetOf(CurlGetinfoCtx, "appconnect_us") == 192);
    std.debug.assert(@offsetOf(CurlGetinfoCtx, "pretransfer_us") == 200);
    std.debug.assert(@offsetOf(CurlGetinfoCtx, "starttransfer_us") == 208);
    std.debug.assert(@offsetOf(CurlGetinfoCtx, "posttransfer_us") == 216);
    std.debug.assert(@offsetOf(CurlGetinfoCtx, "startredirect_us") == 224);
    std.debug.assert(@offsetOf(CurlGetinfoCtx, "ssl_verifyresult") == 232);
    std.debug.assert(@offsetOf(CurlGetinfoCtx, "proxy_ssl_verifyresult") == 232 + @sizeOf(c_long));
    std.debug.assert(@offsetOf(CurlGetinfoCtx, "rtsp_next_client_CSeq") == 232 + 2 * @sizeOf(c_long));
    std.debug.assert(@offsetOf(CurlGetinfoCtx, "rtsp_next_server_CSeq") == 236 + 2 * @sizeOf(c_long));
    std.debug.assert(@offsetOf(CurlGetinfoCtx, "rtsp_CSeq_recv") == 240 + 2 * @sizeOf(c_long));
    std.debug.assert(@offsetOf(CurlGetinfoCtx, "os_errno") == 244 + 2 * @sizeOf(c_long));
    std.debug.assert(@offsetOf(CurlGetinfoCtx, "followlocation") == 248 + 2 * @sizeOf(c_long));
    std.debug.assert(@offsetOf(CurlGetinfoCtx, "httpreq") == 250 + 2 * @sizeOf(c_long));
    std.debug.assert(@offsetOf(CurlGetinfoCtx, "path_as_is") == 251 + 2 * @sizeOf(c_long));
    std.debug.assert(@offsetOf(CurlGetinfoCtx, "opt_no_body") == 252 + 2 * @sizeOf(c_long));
    std.debug.assert(@offsetOf(CurlGetinfoCtx, "timecond") == 253 + 2 * @sizeOf(c_long));
    std.debug.assert(@offsetOf(CurlGetinfoCtx, "used_proxy") == 254 + 2 * @sizeOf(c_long));
    std.debug.assert(@offsetOf(CurlGetinfoCtx, "ul_size_known") == 255 + 2 * @sizeOf(c_long));
    std.debug.assert(@offsetOf(CurlGetinfoCtx, "dl_size_known") == 256 + 2 * @sizeOf(c_long));

    // 5. SingleRequest
    std.debug.assert(@sizeOf(SingleRequest) == 232);
    std.debug.assert(@alignOf(SingleRequest) == 8);
    std.debug.assert(@offsetOf(SingleRequest, "size") == 0);
    std.debug.assert(@offsetOf(SingleRequest, "maxdownload") == 8);
    std.debug.assert(@offsetOf(SingleRequest, "bytecount") == 16);
    std.debug.assert(@offsetOf(SingleRequest, "writebytecount") == 24);
    std.debug.assert(@offsetOf(SingleRequest, "offset") == 32);
    std.debug.assert(@offsetOf(SingleRequest, "start") == 40);
    std.debug.assert(@offsetOf(SingleRequest, "headerbytecount") == 56);
    std.debug.assert(@offsetOf(SingleRequest, "allheadercount") == 60);
    std.debug.assert(@offsetOf(SingleRequest, "deductheadercount") == 64);
    std.debug.assert(@offsetOf(SingleRequest, "headerline") == 68);
    std.debug.assert(@offsetOf(SingleRequest, "httpcode") == 72);
    std.debug.assert(@offsetOf(SingleRequest, "httpversion_sent") == 76);
    std.debug.assert(@offsetOf(SingleRequest, "httpversion") == 77);
    std.debug.assert(@offsetOf(SingleRequest, "upgr101") == 78);
    std.debug.assert(@offsetOf(SingleRequest, "io_flags") == 79);
    std.debug.assert(@offsetOf(SingleRequest, "writer_stack") == 80);
    std.debug.assert(@offsetOf(SingleRequest, "reader_stack") == 96);
    std.debug.assert(@offsetOf(SingleRequest, "sendbuf") == 104);
    std.debug.assert(@offsetOf(SingleRequest, "sendbuf_hds_len") == 168);
    std.debug.assert(@offsetOf(SingleRequest, "timeofdoc") == 176);
    std.debug.assert(@offsetOf(SingleRequest, "location") == 184);
    std.debug.assert(@offsetOf(SingleRequest, "newurl") == 192);
    std.debug.assert(@offsetOf(SingleRequest, "hd_auth") == 200);
    std.debug.assert(@offsetOf(SingleRequest, "hd_proxy_auth") == 208);
    std.debug.assert(@offsetOf(SingleRequest, "cookiehost") == 216);
    std.debug.assert(@offsetOf(SingleRequest, "tail") == 224);

    // 6. CurlMultiEv
    std.debug.assert(@sizeOf(CurlMultiEv) == 40);
    std.debug.assert(@alignOf(CurlMultiEv) == 8);
    std.debug.assert(@offsetOf(CurlMultiEv, "sh_entries") == 0);
}

extern fn Curl_zig_abi_sizeof_eapi_stack() callconv(.c) usize;
extern fn Curl_zig_abi_sizeof_eapi_guard() callconv(.c) usize;
extern fn Curl_zig_abi_sizeof_mapi_stack() callconv(.c) usize;
extern fn Curl_zig_abi_sizeof_mapi_guard() callconv(.c) usize;
extern fn Curl_zig_abi_sizeof_easy_prefix() callconv(.c) usize;
extern fn Curl_zig_abi_sizeof_multi_prefix() callconv(.c) usize;
extern fn Curl_zig_abi_sizeof_pureinfo_prefix() callconv(.c) usize;
extern fn Curl_zig_abi_sizeof_getinfo_ctx() callconv(.c) usize;
extern fn Curl_zig_abi_sizeof_singlerequest() callconv(.c) usize;
extern fn Curl_zig_abi_sizeof_multi_ev() callconv(.c) usize;

test "C-Zig ABI struct sizes in api_getinfo_request" {
    try std.testing.expectEqual(@sizeOf(CurlEapiStack), Curl_zig_abi_sizeof_eapi_stack());
    try std.testing.expectEqual(@sizeOf(CurlEapiGuard), Curl_zig_abi_sizeof_eapi_guard());
    try std.testing.expectEqual(@sizeOf(CurlMapiStack), Curl_zig_abi_sizeof_mapi_stack());
    try std.testing.expectEqual(@sizeOf(CurlMapiGuard), Curl_zig_abi_sizeof_mapi_guard());
    try std.testing.expectEqual(@sizeOf(CurlEasyPrefix), Curl_zig_abi_sizeof_easy_prefix());
    try std.testing.expectEqual(@sizeOf(CurlMultiPrefix), Curl_zig_abi_sizeof_multi_prefix());
    try std.testing.expectEqual(@sizeOf(PureInfoPrefix), Curl_zig_abi_sizeof_pureinfo_prefix());
    try std.testing.expectEqual(@sizeOf(CurlGetinfoCtx), Curl_zig_abi_sizeof_getinfo_ctx());
    try std.testing.expectEqual(@sizeOf(SingleRequest), Curl_zig_abi_sizeof_singlerequest());
    try std.testing.expectEqual(@sizeOf(CurlMultiEv), Curl_zig_abi_sizeof_multi_ev());
}

test "mapiInNtfyCb only allows add/remove when multi_ntfy_cb is innermost frame (#128)" {
    var multi: CurlMultiPrefix = std.mem.zeroes(CurlMultiPrefix);
    multi.magic = CURL_MULTI_HANDLE;

    var ntfy_guard: CurlMapiGuard = undefined;
    Curl_cbapi_enter(&ntfy_guard, null, &multi, CURL_CBAPI_FN_multi_ntfy_cb);

    // Direct call from multi_ntfy_cb is permitted.
    var add_guard: CurlMapiGuard = undefined;
    var mresult: CURLMcode = CURLM_OK;
    try std.testing.expect(Curl_mapi_enter(&add_guard, &multi, CURL_MAPI_FN_multi_add_handle, &mresult));
    try std.testing.expectEqual(CURLM_OK, mresult);

    // Nested socket_cb inside curl_multi_add_handle must NOT inherit ntfy_cb exemption.
    var sock_guard: CurlMapiGuard = undefined;
    Curl_cbapi_enter(&sock_guard, null, &multi, CURL_CBAPI_FN_multi_socket_cb);

    var rem_guard: CurlMapiGuard = undefined;
    var rem_result: CURLMcode = CURLM_OK;
    try std.testing.expect(!Curl_mapi_enter(&rem_guard, &multi, CURL_MAPI_FN_multi_remove_handle, &rem_result));
    try std.testing.expectEqual(CURLM_RECURSIVE_API_CALL, rem_result);

    Curl_cbapi_leave(&sock_guard);
    Curl_mapi_leave(&add_guard);
    Curl_cbapi_leave(&ntfy_guard);
}
