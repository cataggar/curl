const std = @import("std");
const builtin = @import("builtin");
const mem = @import("mem.zig");
const primitives = @import("primitives.zig");
const curlx_parse = @import("curlx_parse.zig");
const curlx_time_net = @import("curlx_time_net.zig");
const os_leaf = @import("os_leaf.zig");
const containers = @import("containers.zig");
const http1_options = @import("http1_options.zig");
const netrc_addr_idn = @import("netrc_addr_idn.zig");
const vfilters = @import("vdns_cfilters.zig");

const in_libcurl = (builtin.output_mode == .Lib) or builtin.is_test;

const CURLcode = containers.CURLcode;
const CURLE_OK: CURLcode = containers.CURLE_OK;
const CURLE_OUT_OF_MEMORY: CURLcode = containers.CURLE_OUT_OF_MEMORY;
const CURLE_BAD_FUNCTION_ARGUMENT: CURLcode = containers.CURLE_BAD_FUNCTION_ARGUMENT;
const CURLE_WRITE_ERROR: CURLcode = 23;
const CURLE_OPERATION_TIMEDOUT: CURLcode = 28;
const CURLE_SEND_ERROR: CURLcode = 55;
const CURLE_RECV_ERROR: CURLcode = 56;
const CURLE_AGAIN: CURLcode = 81;
const CURLE_WEIRD_SERVER_REPLY: CURLcode = 8;

const CVaListParam = containers.CVaListParam;
const Curl_easy = vfilters.Curl_easy;
const connectdata = vfilters.connectdata;
const easy_pollset = vfilters.easy_pollset;
const curl_socket_t = vfilters.curl_socket_t;
const CURL_SOCKET_BAD = vfilters.CURL_SOCKET_BAD;
const FIRSTSOCKET: i8 = 0;
const timediff_t = i64;
const CURL_OFF_T_MAX: i64 = std.math.maxInt(i64);

// ============================================================================
// Common External C / Zig Declarations
// ============================================================================

extern fn curl_msnprintf(buffer: ?[*]u8, maxlength: usize, format: [*:0]const u8, ...) callconv(.c) c_int;
extern fn curl_mvsnprintf(buffer: ?[*]u8, maxlength: usize, format: [*:0]const u8, ap_param: CVaListParam) callconv(.c) c_int;
extern fn curl_maprintf(format: [*:0]const u8, ...) callconv(.c) ?[*:0]u8;
extern fn curl_mfprintf(fd: ?*anyopaque, format: [*:0]const u8, ...) callconv(.c) c_int;

extern fn curlx_memdup(src: ?*const anyopaque, length: usize) callconv(.c) ?*anyopaque;
extern fn curlx_memdup0(src: ?[*]const u8, length: usize) callconv(.c) ?[*:0]u8;
extern fn curlx_str_init(out: *curlx_parse.Curl_str) callconv(.c) void;
extern fn curlx_str_until(linep: *?[*:0]const u8, out: *curlx_parse.Curl_str, max: usize, delim: u8) callconv(.c) c_int;
extern fn curlx_str_single(linep: *?[*:0]const u8, byte: u8) callconv(.c) c_int;
extern fn curlx_str_number(linep: *?[*]const u8, nump: *i64, max: i64) callconv(.c) c_int;
extern fn curlx_str_casecompare(str: *curlx_parse.Curl_str, check: ?[*:0]const u8) callconv(.c) c_int;
extern fn curlx_str_nudge(str: *curlx_parse.Curl_str, num: usize) callconv(.c) c_int;
extern fn curlx_str_cspn(linep: *?[*:0]const u8, out: *curlx_parse.Curl_str, reject: [*:0]const u8) callconv(.c) c_int;
extern fn curlx_str_trimblanks(out: *curlx_parse.Curl_str) callconv(.c) void;
extern fn curlx_str_passblanks(linep: *?[*:0]const u8) callconv(.c) void;
extern fn curlx_dyn_vaddf(s: *containers.dynbuf, fmt: [*:0]const u8, ap: CVaListParam) callconv(.c) CURLcode;
extern fn Curl_slist_append_nodup(list: ?*containers.curl_slist, data: ?[*:0]const u8) callconv(.c) ?*containers.curl_slist;
extern fn curl_slist_free_all(list: ?*containers.curl_slist) callconv(.c) void;
extern fn Curl_getdate_capped(p: ?[*:0]const u8, tp: *i64) callconv(.c) c_int;
extern fn curl_easy_strerror(err: CURLcode) callconv(.c) [*:0]const u8;
extern fn Curl_timeouts_offset_us(timeouts: ?*const anyopaque, now: *const curlx_time_net.Curltime) callconv(.c) timediff_t;

extern fn Curl_xfer_is_secure(data: ?*Curl_easy) callconv(.c) bool;
extern fn Curl_pgrs_now(data: ?*Curl_easy) callconv(.c) *const curlx_time_net.Curltime;
extern fn Curl_timeleft_ms(data: ?*Curl_easy) callconv(.c) timediff_t;
extern fn Curl_expire(data: ?*Curl_easy, milli: timediff_t, id: c_uint) callconv(.c) void;
extern fn Curl_conn_data_pending(data: ?*Curl_easy, sockindex: c_int) callconv(.c) bool;
extern fn Curl_socket_check(readfd0: curl_socket_t, readfd1: curl_socket_t, writefd: curl_socket_t, timeout_ms: timediff_t) callconv(.c) c_int;
extern fn Curl_pgrsCheck(data: ?*Curl_easy) callconv(.c) CURLcode;
extern fn Curl_conn_send(data: ?*Curl_easy, sockindex: i8, buf: [*]const u8, len: usize, eos: bool, pnwritten: *usize) callconv(.c) CURLcode;
extern fn Curl_conn_recv(data: ?*Curl_easy, sockindex: i8, buf: [*]u8, len: usize, pnread: *usize) callconv(.c) CURLcode;
extern fn Curl_client_write(data: ?*Curl_easy, wtype: c_int, buf: [*]const u8, blen: usize) callconv(.c) CURLcode;
extern fn Curl_pollset_change(data: ?*Curl_easy, ps: *easy_pollset, sock: curl_socket_t, add_flags: c_int, remove_flags: c_int) callconv(.c) CURLcode;
extern fn Curl_cbapi_enter(guard: *Curl_mapi_guard, data: ?*Curl_easy, multi: ?*anyopaque, fn_id: c_uint) callconv(.c) void;
extern fn Curl_cbapi_leave(guard: *Curl_mapi_guard) callconv(.c) void;
extern fn Curl_share_lock(data: ?*Curl_easy, lock_type: c_uint, lock_access: c_uint) callconv(.c) c_uint;
extern fn Curl_share_unlock(data: ?*Curl_easy, lock_type: c_uint) callconv(.c) c_uint;

const Curl_mapi_guard = extern struct {
    multi: ?*anyopaque = null,
    depth: u8 = 0,
};

const CURL_CBAPI_FN_easy_fdebug: c_uint = 128 + 6;

const stdio_c = if (builtin.os.tag == .windows) struct {
    extern "c" fn __acrt_iob_func(ix: c_uint) callconv(.c) *anyopaque;
    extern "c" fn _fileno(stream: ?*anyopaque) callconv(.c) c_int;
    extern "c" fn _fstati64(fd: c_int, buffer: *Win32Stat64) callconv(.c) c_int;
    extern "c" fn fclose(stream: ?*anyopaque) callconv(.c) c_int;
    extern "c" fn fputs(s: [*:0]const u8, stream: ?*anyopaque) callconv(.c) c_int;
    extern "c" fn fwrite(ptr: ?*const anyopaque, size: usize, nmemb: usize, stream: ?*anyopaque) callconv(.c) usize;
    extern "c" fn _unlink(filename: [*:0]const u8) callconv(.c) c_int;
    extern "c" fn _time64(timer: ?*i64) callconv(.c) i64;
    extern "ws2_32" fn WSAGetLastError() callconv(.winapi) c_int;

    const Win32Stat64 = extern struct {
        st_dev: u32,
        st_ino: u16,
        st_mode: u16,
        st_nlink: i16,
        st_uid: i16,
        st_gid: i16,
        st_rdev: u32,
        st_size: i64,
        st_atime: i64,
        st_mtime: i64,
        st_ctime: i64,
    };

    inline fn getStdin() *anyopaque {
        return __acrt_iob_func(0);
    }
    inline fn getStdout() *anyopaque {
        return __acrt_iob_func(1);
    }
    inline fn getStderr() *anyopaque {
        return __acrt_iob_func(2);
    }
    inline fn currentTime() i64 {
        return _time64(null);
    }
    inline fn fopenReadBinary(filename: [*:0]const u8) ?*anyopaque {
        return os_leaf.win32.curlx_win32_fopen(filename, "rb");
    }
    inline fn renameFile(oldpath: [*:0]const u8, newpath: [*:0]const u8) c_int {
        return os_leaf.win32.curlx_win32_rename(oldpath, newpath);
    }
    inline fn unlinkFile(filename: [*:0]const u8) c_int {
        return _unlink(filename);
    }
    inline fn isStreamDir(_: [*:0]const u8, fp: *anyopaque) bool {
        var st: Win32Stat64 = std.mem.zeroes(Win32Stat64);
        const fd = _fileno(fp);
        if (_fstati64(fd, &st) == -1) return false;
        return (st.st_mode & 0xF000) == 0x4000;
    }
    inline fn getSockErrno() c_int {
        return WSAGetLastError();
    }
} else if (builtin.os.tag.isDarwin()) struct {
    extern "c" var __stdinp: *anyopaque;
    extern "c" var __stdoutp: *anyopaque;
    extern "c" var __stderrp: *anyopaque;
    extern "c" fn fopen(filename: [*:0]const u8, mode: [*:0]const u8) callconv(.c) ?*anyopaque;
    extern "c" fn fclose(stream: ?*anyopaque) callconv(.c) c_int;
    extern "c" fn fputs(s: [*:0]const u8, stream: ?*anyopaque) callconv(.c) c_int;
    extern "c" fn fwrite(ptr: ?*const anyopaque, size: usize, nmemb: usize, stream: ?*anyopaque) callconv(.c) usize;
    extern "c" fn rename(oldpath: [*:0]const u8, newpath: [*:0]const u8) callconv(.c) c_int;
    extern "c" fn unlink(filename: [*:0]const u8) callconv(.c) c_int;
    extern "c" fn time(timer: ?*i64) callconv(.c) i64;
    extern "c" fn opendir(name: [*:0]const u8) callconv(.c) ?*anyopaque;
    extern "c" fn closedir(dirp: *anyopaque) callconv(.c) c_int;

    inline fn getStdin() *anyopaque {
        return __stdinp;
    }
    inline fn getStdout() *anyopaque {
        return __stdoutp;
    }
    inline fn getStderr() *anyopaque {
        return __stderrp;
    }
    inline fn currentTime() i64 {
        return time(null);
    }
    inline fn fopenReadBinary(filename: [*:0]const u8) ?*anyopaque {
        return fopen(filename, "rb");
    }
    inline fn renameFile(oldpath: [*:0]const u8, newpath: [*:0]const u8) c_int {
        return rename(oldpath, newpath);
    }
    inline fn unlinkFile(filename: [*:0]const u8) c_int {
        return unlink(filename);
    }
    inline fn isStreamDir(filename: [*:0]const u8, _: *anyopaque) bool {
        if (opendir(filename)) |dir| {
            _ = closedir(dir);
            return true;
        }
        return false;
    }
    inline fn getSockErrno() c_int {
        return std.c._errno().*;
    }
} else struct {
    extern "c" var stdin: *anyopaque;
    extern "c" var stdout: *anyopaque;
    extern "c" var stderr: *anyopaque;
    extern "c" fn fopen(filename: [*:0]const u8, mode: [*:0]const u8) callconv(.c) ?*anyopaque;
    extern "c" fn fclose(stream: ?*anyopaque) callconv(.c) c_int;
    extern "c" fn fputs(s: [*:0]const u8, stream: ?*anyopaque) callconv(.c) c_int;
    extern "c" fn fwrite(ptr: ?*const anyopaque, size: usize, nmemb: usize, stream: ?*anyopaque) callconv(.c) usize;
    extern "c" fn rename(oldpath: [*:0]const u8, newpath: [*:0]const u8) callconv(.c) c_int;
    extern "c" fn unlink(filename: [*:0]const u8) callconv(.c) c_int;
    extern "c" fn time(timer: ?*i64) callconv(.c) i64;
    extern "c" fn opendir(name: [*:0]const u8) callconv(.c) ?*anyopaque;
    extern "c" fn closedir(dirp: *anyopaque) callconv(.c) c_int;

    inline fn getStdin() *anyopaque {
        return stdin;
    }
    inline fn getStdout() *anyopaque {
        return stdout;
    }
    inline fn getStderr() *anyopaque {
        return stderr;
    }
    inline fn currentTime() i64 {
        return time(null);
    }
    inline fn fopenReadBinary(filename: [*:0]const u8) ?*anyopaque {
        return fopen(filename, "rb");
    }
    inline fn renameFile(oldpath: [*:0]const u8, newpath: [*:0]const u8) c_int {
        return rename(oldpath, newpath);
    }
    inline fn unlinkFile(filename: [*:0]const u8) c_int {
        return unlink(filename);
    }
    inline fn isStreamDir(filename: [*:0]const u8, _: *anyopaque) bool {
        if (opendir(filename)) |dir| {
            _ = closedir(dir);
            return true;
        }
        return false;
    }
    inline fn getSockErrno() c_int {
        return std.c._errno().*;
    }
};

// ============================================================================
// Invariant Prefix of struct Curl_easy & Bound Easy Handle Table
// ============================================================================

const CURLEASY_MAGIC_NUMBER: u32 = 0xc0dedbad;

const Curl_easy_prefix = extern struct {
    magic: u32,
    mid: u32,
    mstate: c_uint,
    result: c_uint,
    conn: ?*connectdata,
    multi: ?*anyopaque,
    callstack_count: u16,
    callstack_calls: [7]u16,
    share: ?*anyopaque,
    multi_easy: ?*anyopaque,
    msg_msg: c_uint,
    msg_easy_handle: ?*anyopaque,
    msg_data: ?*anyopaque,
    id: i64,
};

pub const curl_infotype = c_uint;
pub const CURLINFO_TEXT: curl_infotype = 0;
pub const CURLINFO_HEADER_IN: curl_infotype = 1;
pub const CURLINFO_HEADER_OUT: curl_infotype = 2;
pub const CURLINFO_DATA_IN: curl_infotype = 3;
pub const CURLINFO_DATA_OUT: curl_infotype = 4;
pub const CURLINFO_SSL_DATA_IN: curl_infotype = 5;
pub const CURLINFO_SSL_DATA_OUT: curl_infotype = 6;
pub const CURLINFO_END: curl_infotype = 7;

pub const curl_debug_callback = *const fn (
    handle: ?*Curl_easy,
    infotype: curl_infotype,
    data: [*]u8,
    size: usize,
    userptr: ?*anyopaque,
) callconv(.c) c_int;

pub const curl_trc_feat = vfilters.curl_trc_feat;

const BoundEasy = struct {
    data: ?*const Curl_easy = null,
    peasy_id: ?*const i64 = null,
    pmstate: ?*const c_uint = null,
    plast_conn_id: ?*const i64 = null,
    pstate_feat: ?*const ?*curl_trc_feat = null,
    perrorbuffer: ?*const ?[*]u8 = null,
    phttpreq: ?[*]u8 = null,
    verbose: bool = false,
    pfdebug: ?*const ?curl_debug_callback = null,
    pdebugdata: ?*const ?*anyopaque = null,
    perr: ?*const ?*anyopaque = null,
};

const BOUND_EASY_SLOTS = 16;
threadlocal var bound_easies: [BOUND_EASY_SLOTS]BoundEasy = @splat(.{});
threadlocal var bound_easy_next: usize = 0;

pub export fn Curl_trc_bind_easy(
    data: ?*const Curl_easy,
    peasy_id: ?*const anyopaque,
    pmstate: ?*const anyopaque,
    plast_conn_id: ?*const anyopaque,
    pstate_feat: ?*const anyopaque,
    perrorbuffer: ?*const anyopaque,
    phttpreq: ?*const anyopaque,
    verbose: bool,
    pfdebug: ?*const anyopaque,
    pdebugdata: ?*const anyopaque,
    perr: ?*const anyopaque,
) callconv(.c) bool {
    const d = data orelse return false;
    const entry = BoundEasy{
        .data = d,
        .peasy_id = if (peasy_id) |p| @ptrCast(@alignCast(p)) else null,
        .pmstate = if (pmstate) |p| @ptrCast(@alignCast(p)) else null,
        .plast_conn_id = if (plast_conn_id) |p| @ptrCast(@alignCast(p)) else null,
        .pstate_feat = if (pstate_feat) |p| @ptrCast(@alignCast(p)) else null,
        .perrorbuffer = if (perrorbuffer) |p| @ptrCast(@alignCast(p)) else null,
        .phttpreq = if (phttpreq) |p| @ptrCast(@constCast(p)) else null,
        .verbose = verbose,
        .pfdebug = if (pfdebug) |p| @ptrCast(@alignCast(p)) else null,
        .pdebugdata = if (pdebugdata) |p| @ptrCast(@alignCast(p)) else null,
        .perr = if (perr) |p| @ptrCast(@alignCast(p)) else null,
    };

    for (&bound_easies) |*slot| {
        if (slot.data == d) {
            slot.* = entry;
            return true;
        }
    }
    bound_easies[bound_easy_next] = entry;
    bound_easy_next = (bound_easy_next + 1) % BOUND_EASY_SLOTS;
    return true;
}

inline fn lookupBoundEasy(data: ?*const Curl_easy) ?*BoundEasy {
    const d = data orelse return null;
    for (&bound_easies) |*slot| {
        if (slot.data == d) return slot;
    }
    return null;
}

inline fn easyIsVerbose(data: ?*const Curl_easy) bool {
    if (lookupBoundEasy(data)) |b| return b.verbose;
    return false;
}

inline fn easyStateFeat(data: ?*const Curl_easy) ?*curl_trc_feat {
    if (lookupBoundEasy(data)) |b| {
        if (b.pstate_feat) |p| return p.*;
    }
    return null;
}

inline fn easyId(data: ?*const Curl_easy) i64 {
    if (lookupBoundEasy(data)) |b| {
        if (b.peasy_id) |p| return p.*;
    }
    if (data) |d| {
        const pref: *const Curl_easy_prefix = @ptrCast(@alignCast(d));
        if (pref.magic == CURLEASY_MAGIC_NUMBER) return pref.id;
    }
    return -1;
}

inline fn easyMstate(data: ?*const Curl_easy) c_int {
    if (lookupBoundEasy(data)) |b| {
        if (b.pmstate) |p| return @intCast(p.*);
    }
    if (data) |d| {
        const pref: *const Curl_easy_prefix = @ptrCast(@alignCast(d));
        if (pref.magic == CURLEASY_MAGIC_NUMBER) return @intCast(pref.mstate);
    }
    return -1;
}

inline fn easyLastConnId(data: ?*const Curl_easy) i64 {
    if (lookupBoundEasy(data)) |b| {
        if (b.plast_conn_id) |p| return p.*;
    }
    return -1;
}

inline fn easyErrorBuffer(data: ?*const Curl_easy) ?[*]u8 {
    if (lookupBoundEasy(data)) |b| {
        if (b.perrorbuffer) |p| return p.*;
    }
    return null;
}

inline fn easyErrorbufSet(data: ?*const Curl_easy) bool {
    if (lookupBoundEasy(data)) |b| {
        if (b.phttpreq) |p| {
            return (p[1] & 0x08) != 0;
        }
    }
    return false;
}

inline fn easySetErrorbuf(data: ?*const Curl_easy, val: bool) void {
    if (lookupBoundEasy(data)) |b| {
        if (b.phttpreq) |p| {
            if (val) {
                p[1] |= 0x08;
            } else {
                p[1] &= ~@as(u8, 0x08);
            }
        }
    }
}

inline fn easyFdebug(data: ?*const Curl_easy) ?curl_debug_callback {
    if (lookupBoundEasy(data)) |b| {
        if (b.pfdebug) |p| return p.*;
    }
    return null;
}

inline fn easyDebugdata(data: ?*const Curl_easy) ?*anyopaque {
    if (lookupBoundEasy(data)) |b| {
        if (b.pdebugdata) |p| return p.*;
    }
    return null;
}

inline fn easyErrStream(data: ?*const Curl_easy) *anyopaque {
    if (lookupBoundEasy(data)) |b| {
        if (b.perr) |p| {
            if (p.*) |s| return s;
        }
    }
    return stdio_c.getStderr();
}

// ============================================================================
// 1. lib/curl_trc.c (lib/curl_trc.h)
// ============================================================================

pub const CURL_LOG_LVL_NONE: c_int = 0;
pub const CURL_LOG_LVL_INFO: c_int = 1;
const TRC_LINE_MAX: usize = 2048;
const CURL_ERROR_SIZE: usize = 256;

const s_infotype = [CURLINFO_END][3:0]u8{
    "*  ".*,
    "<  ".*,
    ">  ".*,
    "{  ".*,
    "}  ".*,
    "{  ".*,
    "}  ".*,
};

const s_infotype_prefix = [CURLINFO_END][2]u8{
    .{ '*', ' ' },
    .{ '<', ' ' },
    .{ '>', ' ' },
    .{ '{', ' ' },
    .{ '}', ' ' },
    .{ '{', ' ' },
    .{ '}', ' ' },
};

var Curl_trc_feat_ids: curl_trc_feat = .{
    .name = "LIB-IDS",
    .log_level = CURL_LOG_LVL_NONE,
};

pub export var Curl_trc_feat_multi: curl_trc_feat = .{
    .name = "MULTI",
    .log_level = CURL_LOG_LVL_NONE,
};
pub export var Curl_trc_feat_read: curl_trc_feat = .{
    .name = "READ",
    .log_level = CURL_LOG_LVL_NONE,
};
pub export var Curl_trc_feat_write: curl_trc_feat = .{
    .name = "WRITE",
    .log_level = CURL_LOG_LVL_NONE,
};
pub export var Curl_trc_feat_dns: curl_trc_feat = .{
    .name = "DNS",
    .log_level = CURL_LOG_LVL_NONE,
};
pub export var Curl_trc_feat_doh: curl_trc_feat = .{
    .name = "DoH",
    .log_level = CURL_LOG_LVL_NONE,
};
pub export var Curl_trc_feat_timer: curl_trc_feat = .{
    .name = "TIMER",
    .log_level = CURL_LOG_LVL_NONE,
};
pub export var Curl_trc_feat_threads: curl_trc_feat = .{
    .name = "THREADS",
    .log_level = CURL_LOG_LVL_NONE,
};
pub export var Curl_trc_feat_ftp: curl_trc_feat = .{
    .name = "FTP",
    .log_level = CURL_LOG_LVL_NONE,
};
pub export var Curl_trc_feat_smtp: curl_trc_feat = .{
    .name = "SMTP",
    .log_level = CURL_LOG_LVL_NONE,
};
pub export var Curl_trc_feat_ssls: curl_trc_feat = .{
    .name = "SSLS",
    .log_level = CURL_LOG_LVL_NONE,
};
pub export var Curl_trc_feat_ssh: curl_trc_feat = .{
    .name = "SSH",
    .log_level = CURL_LOG_LVL_NONE,
};
pub export var Curl_trc_feat_ws: curl_trc_feat = .{
    .name = "WS",
    .log_level = CURL_LOG_LVL_NONE,
};

inline fn trcIsVerbose(data: ?*const Curl_easy) bool {
    if (!easyIsVerbose(data)) return false;
    if (easyStateFeat(data)) |ft| {
        return ft.log_level >= CURL_LOG_LVL_INFO;
    }
    return true;
}

inline fn trcCfIsVerbose(cf: ?*const vfilters.Curl_cfilter, data: ?*const Curl_easy) bool {
    const c = cf orelse return false;
    return trcIsVerbose(data) and c.cft.log_level >= CURL_LOG_LVL_INFO;
}

inline fn trcFtIsVerbose(data: ?*const Curl_easy, ft: ?*const curl_trc_feat) bool {
    const f = ft orelse return false;
    return trcIsVerbose(data) and f.log_level >= CURL_LOG_LVL_INFO;
}

inline fn trcIdsEnabled(data: ?*const Curl_easy) bool {
    return trcIsVerbose(data) and Curl_trc_feat_ids.log_level >= CURL_LOG_LVL_INFO;
}

fn trcWrite(data: ?*Curl_easy, info_type: curl_infotype, ptr: [*]const u8, size: usize) void {
    if (!easyIsVerbose(data)) return;
    if (easyFdebug(data)) |fdebug| {
        var guard: Curl_mapi_guard = .{};
        if (in_libcurl) Curl_cbapi_enter(&guard, data, null, CURL_CBAPI_FN_easy_fdebug);
        _ = fdebug(data, info_type, @constCast(ptr), size, easyDebugdata(data));
        if (in_libcurl) Curl_cbapi_leave(&guard);
    } else {
        switch (info_type) {
            CURLINFO_TEXT, CURLINFO_HEADER_OUT, CURLINFO_HEADER_IN => {
                const err_stream = easyErrStream(data);
                _ = stdio_c.fwrite(&s_infotype_prefix[info_type], 2, 1, err_stream);
                _ = stdio_c.fwrite(ptr, size, 1, err_stream);
            },
            else => {},
        }
    }
}

fn trcPrintIds(data: ?*const Curl_easy, buf: [*]u8, maxlen: usize) usize {
    const cid = easyLastConnId(data);
    const id = easyId(data);
    const rc: c_int = if (id >= 0)
        (if (cid >= 0)
            curl_msnprintf(buf, maxlen, "[%lld-%lld] ", @as(c_longlong, id), @as(c_longlong, cid))
        else
            curl_msnprintf(buf, maxlen, "[%lld-x] ", @as(c_longlong, id)))
    else if (cid >= 0)
        curl_msnprintf(buf, maxlen, "[x-%lld] ", @as(c_longlong, cid))
    else
        curl_msnprintf(buf, maxlen, "[x-x] ");
    return if (rc > 0) @intCast(rc) else 0;
}

fn trcEndBuf(buf: [*]u8, len_in: usize, maxlen: usize, addnl: bool) usize {
    var len = len_in;
    const reserve: usize = if (addnl) 2 else 1;
    if (len >= (maxlen - reserve)) {
        len = maxlen - 5;
        buf[len] = '.';
        buf[len + 1] = '.';
        buf[len + 2] = '.';
        buf[len + 3] = '\n';
        len += 4;
    } else if (addnl) {
        buf[len] = '\n';
        len += 1;
    }
    buf[len] = 0;
    return len;
}

pub export fn Curl_debug(
    data: ?*Curl_easy,
    info_type: curl_infotype,
    ptr: ?[*]const u8,
    size: usize,
) callconv(.c) void {
    if (!easyIsVerbose(data)) return;
    const p = ptr orelse "";
    var buf: [TRC_LINE_MAX]u8 = undefined;
    if (easyFdebug(data)) |fdebug| {
        var guard: Curl_mapi_guard = .{};
        if (trcIdsEnabled(data) and size < TRC_LINE_MAX) {
            var len = trcPrintIds(data, &buf, TRC_LINE_MAX);
            const n = curl_msnprintf((&buf)[len..].ptr, TRC_LINE_MAX - len, "%.*s", @as(c_int, @intCast(size)), p);
            if (n > 0) len += @intCast(n);
            len = trcEndBuf(&buf, len, TRC_LINE_MAX, false);
            if (in_libcurl) Curl_cbapi_enter(&guard, data, null, CURL_CBAPI_FN_easy_fdebug);
            _ = fdebug(data, info_type, &buf, len, easyDebugdata(data));
            if (in_libcurl) Curl_cbapi_leave(&guard);
        } else {
            if (in_libcurl) Curl_cbapi_enter(&guard, data, null, CURL_CBAPI_FN_easy_fdebug);
            _ = fdebug(data, info_type, @constCast(p), size, easyDebugdata(data));
            if (in_libcurl) Curl_cbapi_leave(&guard);
        }
    } else {
        switch (info_type) {
            CURLINFO_TEXT, CURLINFO_HEADER_OUT, CURLINFO_HEADER_IN => {
                const err_stream = easyErrStream(data);
                if (trcIdsEnabled(data)) {
                    const len = trcPrintIds(data, &buf, TRC_LINE_MAX);
                    _ = stdio_c.fwrite(&buf, len, 1, err_stream);
                }
                _ = stdio_c.fwrite(&s_infotype_prefix[info_type], 2, 1, err_stream);
                _ = stdio_c.fwrite(p, size, 1, err_stream);
            },
            else => {},
        }
    }
}

pub export fn Curl_vfailf(
    data: ?*Curl_easy,
    fmt: [*:0]const u8,
    ap: CVaListParam,
) callconv(.c) void {
    const errbuf = easyErrorBuffer(data);
    if (easyIsVerbose(data) or errbuf != null) {
        var error_buf: [CURL_ERROR_SIZE + 2]u8 = undefined;
        const rc = curl_mvsnprintf(&error_buf, CURL_ERROR_SIZE, fmt, ap);
        var len: usize = if (rc > 0) @intCast(rc) else 0;
        if (errbuf) |eb| {
            if (!easyErrorbufSet(data)) {
                primitives.curlx_strcopy(eb, CURL_ERROR_SIZE, &error_buf, len);
                easySetErrorbuf(data, true);
            }
        }
        error_buf[len] = '\n';
        len += 1;
        error_buf[len] = 0;
        trcWrite(data, CURLINFO_TEXT, &error_buf, len);
    }
}

pub export fn Curl_reset_fail(data: ?*Curl_easy) callconv(.c) void {
    if (easyErrorBuffer(data)) |eb| {
        eb[0] = 0;
    }
    easySetErrorbuf(data, false);
}

fn trcInfof(
    data: ?*Curl_easy,
    feat: ?*const curl_trc_feat,
    opt_id: ?[*:0]const u8,
    opt_id_idx: c_int,
    fmt: [*:0]const u8,
    ap: CVaListParam,
) void {
    var len: usize = 0;
    var buf: [TRC_LINE_MAX]u8 = undefined;

    if (trcIdsEnabled(data)) {
        len += trcPrintIds(data, (&buf)[len..].ptr, TRC_LINE_MAX - len);
    }
    if (feat) |f| {
        const n = curl_msnprintf((&buf)[len..].ptr, TRC_LINE_MAX - len, "[%s] ", f.name);
        if (n > 0) len += @intCast(n);
    }
    if (opt_id) |oid| {
        const n = if (opt_id_idx > 0)
            curl_msnprintf((&buf)[len..].ptr, TRC_LINE_MAX - len, "[%s-%d] ", oid, opt_id_idx)
        else
            curl_msnprintf((&buf)[len..].ptr, TRC_LINE_MAX - len, "[%s] ", oid);
        if (n > 0) len += @intCast(n);
    }
    const n = curl_mvsnprintf((&buf)[len..].ptr, TRC_LINE_MAX - len, fmt, ap);
    if (n > 0) len += @intCast(n);
    len = trcEndBuf(&buf, len, TRC_LINE_MAX, true);
    trcWrite(data, CURLINFO_TEXT, &buf, len);
}

pub export fn Curl_vinfof(data: ?*Curl_easy, fmt: [*:0]const u8, ap: CVaListParam) callconv(.c) void {
    if (trcIsVerbose(data)) {
        trcInfof(data, easyStateFeat(data), null, 0, fmt, ap);
    }
}

pub export fn Curl_vtrc_cf_infof(
    data: ?*Curl_easy,
    cf: ?*const vfilters.Curl_cfilter,
    fmt: [*:0]const u8,
    ap: CVaListParam,
) callconv(.c) void {
    if (trcCfIsVerbose(cf, data)) {
        const c = cf.?;
        trcInfof(data, easyStateFeat(data), c.cft.name, c.sockindex, fmt, ap);
    }
}

pub export fn Curl_vtrc_feat_infof(
    data: ?*Curl_easy,
    feat: ?*curl_trc_feat,
    fmt: [*:0]const u8,
    ap: CVaListParam,
) callconv(.c) void {
    if (trcFtIsVerbose(data, feat)) {
        trcInfof(data, feat, null, 0, fmt, ap);
    }
}

const Curl_trc_timer_names = [_][*:0]const u8{
    "100_TIMEOUT",
    "ASYNC_NAME",
    "CONNECTTIMEOUT",
    "HAPPY_EYEBALLS",
    "MULTI_PENDING",
    "SPEEDCHECK",
    "TIMEOUT",
    "TOOFAST",
    "QUIC",
    "FTP_ACCEPT",
    "ALPN_EYEBALLS",
    "SHUTDOWN",
    "SERVER_RESPONSE",
};

const EXPIRE_LAST: u8 = @intCast(Curl_trc_timer_names.len);

pub export fn Curl_trc_timer_name(tid: c_int) callconv(.c) [*:0]const u8 {
    if (tid >= 0 and @as(usize, @intCast(tid)) < Curl_trc_timer_names.len) {
        return Curl_trc_timer_names[@intCast(tid)];
    }
    return "TIMER-???";
}

pub export fn Curl_vtrc_timer(
    data: ?*Curl_easy,
    tid: c_int,
    fmt: [*:0]const u8,
    ap: CVaListParam,
) callconv(.c) void {
    if (trcFtIsVerbose(data, &Curl_trc_feat_timer)) {
        const tname = Curl_trc_timer_name(tid);
        trcInfof(data, &Curl_trc_feat_timer, tname, 0, fmt, ap);
    }
}

pub export fn Curl_trc_easy_timers(
    data: ?*Curl_easy,
    multi_timeouts: ?*const anyopaque,
    offset_us: ?[*]const timediff_t,
    next: ?[*]const u8,
    first: u8,
) callconv(.c) void {
    if (!in_libcurl) return;
    if (trcFtIsVerbose(data, &Curl_trc_feat_timer) and multi_timeouts != null and offset_us != null and next != null) {
        if (first < EXPIRE_LAST) {
            const base_us = Curl_timeouts_offset_us(multi_timeouts, Curl_pgrs_now(data));
            var id = first;
            while (id < EXPIRE_LAST) : (id = next.?[id]) {
                Curl_trc_timer(data, @intCast(id), "expires in %lldus", @as(c_longlong, offset_us.?[id] - base_us));
            }
        }
    }
}

const Curl_trc_mstate_names = [_][*:0]const u8{
    "INIT",
    "PENDING",
    "SETUP",
    "CONNECT",
    "CONNECTING",
    "PROTOCONNECT",
    "PROTOCONNECTING",
    "DO",
    "DOING",
    "DOING_MORE",
    "DID",
    "PERFORMING",
    "RATELIMITING",
    "DONE",
    "COMPLETED",
    "MSGSENT",
};

pub export fn Curl_trc_mstate_name(state: c_int) callconv(.c) [*:0]const u8 {
    if (state >= 0 and @as(usize, @intCast(state)) < Curl_trc_mstate_names.len) {
        return Curl_trc_mstate_names[@intCast(state)];
    }
    return "?";
}

pub export fn Curl_vtrc_multi(data: ?*Curl_easy, fmt: [*:0]const u8, ap: CVaListParam) callconv(.c) void {
    if (trcFtIsVerbose(data, &Curl_trc_feat_multi)) {
        const sname: ?[*:0]const u8 = if (easyId(data) >= 0) Curl_trc_mstate_name(easyMstate(data)) else null;
        trcInfof(data, &Curl_trc_feat_multi, sname, 0, fmt, ap);
    }
}

pub export fn Curl_vtrc_read(data: ?*Curl_easy, fmt: [*:0]const u8, ap: CVaListParam) callconv(.c) void {
    if (trcFtIsVerbose(data, &Curl_trc_feat_read)) {
        trcInfof(data, &Curl_trc_feat_read, null, 0, fmt, ap);
    }
}

pub export fn Curl_vtrc_write(data: ?*Curl_easy, fmt: [*:0]const u8, ap: CVaListParam) callconv(.c) void {
    if (trcFtIsVerbose(data, &Curl_trc_feat_write)) {
        trcInfof(data, &Curl_trc_feat_write, null, 0, fmt, ap);
    }
}

pub export fn Curl_vtrc_dns(data: ?*Curl_easy, fmt: [*:0]const u8, ap: CVaListParam) callconv(.c) void {
    if (trcFtIsVerbose(data, &Curl_trc_feat_dns)) {
        trcInfof(data, &Curl_trc_feat_dns, null, 0, fmt, ap);
    }
}

pub export fn Curl_vtrc_ftp(data: ?*Curl_easy, fmt: [*:0]const u8, ap: CVaListParam) callconv(.c) void {
    if (trcFtIsVerbose(data, &Curl_trc_feat_ftp)) {
        trcInfof(data, &Curl_trc_feat_ftp, null, 0, fmt, ap);
    }
}

pub export fn Curl_vtrc_smtp(data: ?*Curl_easy, fmt: [*:0]const u8, ap: CVaListParam) callconv(.c) void {
    if (trcFtIsVerbose(data, &Curl_trc_feat_smtp)) {
        trcInfof(data, &Curl_trc_feat_smtp, null, 0, fmt, ap);
    }
}

pub export fn Curl_vtrc_ssls(data: ?*Curl_easy, fmt: [*:0]const u8, ap: CVaListParam) callconv(.c) void {
    if (trcFtIsVerbose(data, &Curl_trc_feat_ssls)) {
        trcInfof(data, &Curl_trc_feat_ssls, null, 0, fmt, ap);
    }
}

pub export fn Curl_vtrc_ssh(data: ?*Curl_easy, fmt: [*:0]const u8, ap: CVaListParam) callconv(.c) void {
    if (trcFtIsVerbose(data, &Curl_trc_feat_ssh)) {
        trcInfof(data, &Curl_trc_feat_ssh, null, 0, fmt, ap);
    }
}

pub export fn Curl_vtrc_ws(data: ?*Curl_easy, fmt: [*:0]const u8, ap: CVaListParam) callconv(.c) void {
    if (trcFtIsVerbose(data, &Curl_trc_feat_ws)) {
        trcInfof(data, &Curl_trc_feat_ws, null, 0, fmt, ap);
    }
}

const TRC_CT_NONE: c_uint = 0;
const TRC_CT_PROTOCOL: c_uint = 1 << 0;
const TRC_CT_NETWORK: c_uint = 1 << 1;
const TRC_CT_PROXY: c_uint = 1 << 2;
const TRC_CT_INTERNALS: c_uint = 1 << 3;

const trc_feat_def = struct {
    feat: *curl_trc_feat,
    category: c_uint,
};

const trc_feats = [_]trc_feat_def{
    .{ .feat = &Curl_trc_feat_ids, .category = TRC_CT_INTERNALS },
    .{ .feat = &Curl_trc_feat_multi, .category = TRC_CT_NETWORK },
    .{ .feat = &Curl_trc_feat_read, .category = TRC_CT_NONE },
    .{ .feat = &Curl_trc_feat_write, .category = TRC_CT_NONE },
    .{ .feat = &Curl_trc_feat_dns, .category = TRC_CT_NETWORK },
    .{ .feat = &Curl_trc_feat_doh, .category = TRC_CT_NETWORK },
    .{ .feat = &Curl_trc_feat_timer, .category = TRC_CT_NETWORK },
    .{ .feat = &Curl_trc_feat_threads, .category = TRC_CT_NONE },
    .{ .feat = &Curl_trc_feat_ftp, .category = TRC_CT_PROTOCOL },
    .{ .feat = &Curl_trc_feat_smtp, .category = TRC_CT_PROTOCOL },
    .{ .feat = &Curl_trc_feat_ssls, .category = TRC_CT_NETWORK },
    .{ .feat = &Curl_trc_feat_ssh, .category = TRC_CT_PROTOCOL },
    .{ .feat = &Curl_trc_feat_ws, .category = TRC_CT_PROTOCOL },
};

extern var Curl_cft_dns: vfilters.Curl_cftype;
extern var Curl_cft_tcp: vfilters.Curl_cftype;
extern var Curl_cft_udp: vfilters.Curl_cftype;
extern var Curl_cft_unix: vfilters.Curl_cftype;
extern var Curl_cft_tcp_accept: vfilters.Curl_cftype;
extern var Curl_cft_ip_happy: vfilters.Curl_cftype;
extern var Curl_cft_setup: vfilters.Curl_cftype;
extern var Curl_cft_h1_proxy: vfilters.Curl_cftype;
extern var Curl_cft_http_proxy: vfilters.Curl_cftype;
extern var Curl_cft_socks_proxy: vfilters.Curl_cftype;
extern var Curl_cft_http_connect: vfilters.Curl_cftype;

var registered_cft_ssl: ?*vfilters.Curl_cftype = null;
var registered_cft_ssl_proxy: ?*vfilters.Curl_cftype = null;

pub export fn Curl_trc_register_ssl_cfts(
    cft_ssl: ?*anyopaque,
    cft_ssl_proxy: ?*anyopaque,
) callconv(.c) void {
    registered_cft_ssl = if (cft_ssl) |p| @ptrCast(@alignCast(p)) else null;
    registered_cft_ssl_proxy = if (cft_ssl_proxy) |p| @ptrCast(@alignCast(p)) else null;
}

const trc_cft_def = struct {
    cft: *vfilters.Curl_cftype,
    category: c_uint,
};

const trc_cfts = [_]trc_cft_def{
    .{ .cft = &Curl_cft_dns, .category = TRC_CT_NETWORK },
    .{ .cft = &Curl_cft_tcp, .category = TRC_CT_NETWORK },
    .{ .cft = &Curl_cft_udp, .category = TRC_CT_NETWORK },
    .{ .cft = &Curl_cft_unix, .category = TRC_CT_NETWORK },
    .{ .cft = &Curl_cft_tcp_accept, .category = TRC_CT_NETWORK },
    .{ .cft = &Curl_cft_ip_happy, .category = TRC_CT_NETWORK },
    .{ .cft = &vfilters.Curl_cft_recvbuf, .category = TRC_CT_PROTOCOL },
    .{ .cft = &Curl_cft_setup, .category = TRC_CT_PROTOCOL },
    .{ .cft = &Curl_cft_h1_proxy, .category = TRC_CT_PROXY },
    .{ .cft = &Curl_cft_http_proxy, .category = TRC_CT_PROXY },
    .{ .cft = &vfilters.Curl_cft_haproxy, .category = TRC_CT_PROXY },
    .{ .cft = &Curl_cft_socks_proxy, .category = TRC_CT_PROXY },
    .{ .cft = &Curl_cft_http_connect, .category = TRC_CT_PROTOCOL },
};

fn trcApplyLevelByName(token: *curlx_parse.Curl_str, lvl: c_int) void {
    if (in_libcurl) {
        for (trc_cfts) |entry| {
            if (curlx_str_casecompare(token, entry.cft.name) != 0) {
                entry.cft.log_level = lvl;
                break;
            }
        }
        if (registered_cft_ssl) |cft| {
            if (curlx_str_casecompare(token, cft.name) != 0) {
                cft.log_level = lvl;
            }
        }
        if (registered_cft_ssl_proxy) |cft| {
            if (curlx_str_casecompare(token, cft.name) != 0) {
                cft.log_level = lvl;
            }
        }
    }
    for (trc_feats) |entry| {
        if (curlx_str_casecompare(token, entry.feat.name) != 0) {
            entry.feat.log_level = lvl;
            break;
        }
    }
}

fn trcApplyLevelByCategory(category: c_uint, lvl: c_int) void {
    if (in_libcurl) {
        for (trc_cfts) |entry| {
            if (category == 0 or (entry.category & category) != 0) {
                entry.cft.log_level = lvl;
            }
        }
        if (registered_cft_ssl) |cft| {
            if (category == 0 or (TRC_CT_NETWORK & category) != 0) {
                cft.log_level = lvl;
            }
        }
        if (registered_cft_ssl_proxy) |cft| {
            if (category == 0 or (TRC_CT_PROXY & category) != 0) {
                cft.log_level = lvl;
            }
        }
    }
    for (trc_feats) |entry| {
        if (category == 0 or (entry.category & category) != 0) {
            entry.feat.log_level = lvl;
        }
    }
}

fn trcOpt(config_in: [*:0]const u8) CURLcode {
    var config: ?[*:0]const u8 = config_in;
    var out: curlx_parse.Curl_str = .{ .str = null, .len = 0 };
    while (curlx_str_until(&config, &out, 32, ',') == 0) {
        var lvl: c_int = CURL_LOG_LVL_INFO;
        if (out.str) |token| {
            if (token[0] == '-') {
                lvl = CURL_LOG_LVL_NONE;
                _ = curlx_str_nudge(&out, 1);
            } else if (token[0] == '+') {
                _ = curlx_str_nudge(&out, 1);
            }
        }

        if (curlx_str_casecompare(&out, "all") != 0) {
            trcApplyLevelByCategory(TRC_CT_NONE, lvl);
        } else if (curlx_str_casecompare(&out, "protocol") != 0) {
            trcApplyLevelByCategory(TRC_CT_PROTOCOL, lvl);
        } else if (curlx_str_casecompare(&out, "network") != 0) {
            trcApplyLevelByCategory(TRC_CT_NETWORK, lvl);
        } else if (curlx_str_casecompare(&out, "proxy") != 0) {
            trcApplyLevelByCategory(TRC_CT_PROXY, lvl);
        } else {
            trcApplyLevelByName(&out, lvl);
        }

        if (curlx_str_single(&config, ',') != 0) {
            break;
        }
    }
    return CURLE_OK;
}

pub export fn Curl_trc_opt(config: ?[*:0]const u8) callconv(.c) CURLcode {
    return if (config) |c| trcOpt(c) else CURLE_OK;
}

pub export fn Curl_trc_init() callconv(.c) CURLcode {
    return CURLE_OK;
}

// ============================================================================
// 2. lib/pingpong.c (lib/pingpong.h)
// ============================================================================

pub const PINGPONG_TIMEOUT_MS: timediff_t = 60 * 1000;
const DYN_PINGPPONG_CMD: usize = 65536;
const EXPIRE_SERVER_RESPONSE: c_uint = 12;
const CLIENTWRITE_INFO: c_int = 1 << 2;
const CURL_POLL_IN: c_int = 1;
const CURL_POLL_OUT: c_int = 2;

pub const pingpong = extern struct {
    nread_resp: usize,
    sendthis: ?[*]u8,
    sendleft: usize,
    sendsize: usize,
    response: curlx_time_net.Curltime,
    sendbuf: containers.dynbuf,
    recvbuf: containers.dynbuf,
    overflow: usize,
    nfinal: usize,
    statemachine: ?*const fn (data: ?*Curl_easy, conn: ?*connectdata) callconv(.c) CURLcode,
    endofresp: ?*const fn (data: ?*Curl_easy, conn: ?*connectdata, ptr: [*:0]const u8, len: usize, code: *c_int) callconv(.c) bool,
    flags: c_uint,

    pub inline fn isInitialized(self: *const @This()) bool {
        return (self.flags & 0x01) != 0;
    }
    pub inline fn setInitialized(self: *@This(), val: bool) void {
        if (val) self.flags |= 0x01 else self.flags &= ~@as(c_uint, 0x01);
    }
    pub inline fn isPendingResp(self: *const @This()) bool {
        return (self.flags & 0x02) != 0;
    }
    pub inline fn setPendingResp(self: *@This(), val: bool) void {
        if (val) self.flags |= 0x02 else self.flags &= ~@as(c_uint, 0x02);
    }
};

pub export fn Curl_pp_state_timeleft_ms(
    data: ?*Curl_easy,
    pp: *pingpong,
    server_response_timeout: timediff_t,
) callconv(.c) timediff_t {
    if (!in_libcurl) return 0;
    var remain_ms: timediff_t = if (server_response_timeout != 0)
        server_response_timeout
    else
        PINGPONG_TIMEOUT_MS;

    remain_ms -= curlx_time_net.curlx_ptimediff_ms(Curl_pgrs_now(data), &pp.response);
    const xfer_remain_ms = Curl_timeleft_ms(data);
    if (xfer_remain_ms != 0) {
        return @min(remain_ms, xfer_remain_ms);
    }
    return remain_ms;
}

pub export fn Curl_pp_statemach(
    data: ?*Curl_easy,
    pp: *pingpong,
    block: bool,
    disconnecting: bool,
    conn: ?*connectdata,
    sock: curl_socket_t,
    server_response_timeout: timediff_t,
) callconv(.c) CURLcode {
    if (!in_libcurl) return CURLE_OK;
    var interval_ms: timediff_t = 0;
    const timeout_ms = Curl_pp_state_timeleft_ms(data, pp, server_response_timeout);
    var result: CURLcode = CURLE_OK;

    if (timeout_ms <= 0) {
        Curl_failf(data, "server response timeout");
        return CURLE_OPERATION_TIMEDOUT;
    }

    if (block) {
        interval_ms = 1000;
        if (timeout_ms < interval_ms) {
            interval_ms = timeout_ms;
        }
    } else {
        interval_ms = 0;
        Curl_expire(data, timeout_ms, EXPIRE_SERVER_RESPONSE);
    }

    var rc: c_int = 0;
    if (Curl_conn_data_pending(data, FIRSTSOCKET)) {
        rc = 1;
    } else if (pp.overflow != 0) {
        rc = 1;
    } else if (pp.sendleft == 0 and Curl_conn_data_pending(data, FIRSTSOCKET)) {
        rc = 1;
    } else {
        rc = Curl_socket_check(
            if (pp.sendleft != 0) CURL_SOCKET_BAD else sock,
            CURL_SOCKET_BAD,
            if (pp.sendleft != 0) sock else CURL_SOCKET_BAD,
            interval_ms,
        );
    }

    if (block) {
        result = Curl_pgrsCheck(data);
        if (result != CURLE_OK) return result;
    }

    if (rc == -1) {
        Curl_failf(data, "select/poll error");
        result = CURLE_OUT_OF_MEMORY;
    } else if (rc != 0) {
        if (pp.statemachine) |sm| {
            result = sm(data, conn);
        }
    } else if (disconnecting) {
        return CURLE_OPERATION_TIMEDOUT;
    }

    return result;
}

pub export fn Curl_pp_init(pp: *pingpong, pnow: *const curlx_time_net.Curltime) callconv(.c) void {
    pp.nread_resp = 0;
    pp.response = pnow.*;
    pp.setPendingResp(true);
    containers.curlx_dyn_init(&pp.sendbuf, DYN_PINGPPONG_CMD);
    containers.curlx_dyn_init(&pp.recvbuf, DYN_PINGPPONG_CMD);
    pp.setInitialized(true);
}

pub export fn Curl_pp_vsendf(
    data: ?*Curl_easy,
    pp: *pingpong,
    prefix: ?[*:0]const u8,
    fmt: [*:0]const u8,
    args: CVaListParam,
) callconv(.c) CURLcode {
    if (!in_libcurl) return CURLE_SEND_ERROR;
    const d = data orelse return CURLE_SEND_ERROR;
    const pref: *const Curl_easy_prefix = @ptrCast(@alignCast(d));
    if (pref.magic == CURLEASY_MAGIC_NUMBER and pref.conn == null) {
        return CURLE_SEND_ERROR;
    }

    var bytes_written: usize = 0;
    var result: CURLcode = CURLE_OK;

    containers.curlx_dyn_reset(&pp.sendbuf);
    if (prefix) |pfx| {
        result = containers.curlx_dyn_add(&pp.sendbuf, pfx);
        if (result == CURLE_OK) {
            result = containers.curlx_dyn_addn(&pp.sendbuf, " ", 1);
        }
    }
    if (result == CURLE_OK) {
        result = curlx_dyn_vaddf(&pp.sendbuf, fmt, args);
    }
    if (result != CURLE_OK) return result;

    result = containers.curlx_dyn_addn(&pp.sendbuf, "\r\n", 2);
    if (result != CURLE_OK) return result;

    pp.setPendingResp(true);
    const write_len = containers.curlx_dyn_len(&pp.sendbuf);
    const s_opt = containers.curlx_dyn_ptr(&pp.sendbuf);
    const s: [*]u8 = if (s_opt) |ptr| @ptrCast(ptr) else return CURLE_SEND_ERROR;

    result = Curl_conn_send(data, FIRSTSOCKET, s, write_len, false, &bytes_written);
    if (result == CURLE_AGAIN) {
        bytes_written = 0;
    } else if (result != CURLE_OK) {
        return result;
    }

    Curl_debug(data, CURLINFO_HEADER_OUT, s, bytes_written);

    if (bytes_written < write_len) {
        pp.sendthis = s;
        pp.sendsize = write_len;
        pp.sendleft = write_len - bytes_written;
    } else {
        pp.sendthis = null;
        pp.sendleft = 0;
        pp.sendsize = 0;
        pp.response = Curl_pgrs_now(data).*;
    }

    return CURLE_OK;
}

pub export fn Curl_pp_vsendf_3(
    data: ?*Curl_easy,
    pp: *pingpong,
    fmt: [*:0]const u8,
    args: CVaListParam,
) callconv(.c) CURLcode {
    return Curl_pp_vsendf(data, pp, null, fmt, args);
}

pub export fn Curl_pp_readresp(
    data: ?*Curl_easy,
    sockindex: i8,
    pp: *pingpong,
    code: *c_int,
    size: *usize,
    conn: ?*connectdata,
    pheaderbytecount: ?*c_uint,
) callconv(.c) CURLcode {
    if (!in_libcurl) return CURLE_RECV_ERROR;
    var result: CURLcode = CURLE_OK;
    var gotbytes: usize = 0;
    var buffer: [900]u8 = undefined;
    var maxloops: c_int = 10;

    code.* = 0;
    size.* = 0;

    while (true) {
        gotbytes = 0;
        if (pp.nfinal != 0) {
            const full = containers.curlx_dyn_len(&pp.recvbuf);
            _ = containers.curlx_dyn_tail(&pp.recvbuf, full - pp.nfinal);
            pp.nfinal = 0;
        }
        if (pp.overflow == 0) {
            if (maxloops == 0) return CURLE_OK;
            maxloops -= 1;

            result = Curl_conn_recv(data, sockindex, &buffer, buffer.len, &gotbytes);
            if (result == CURLE_AGAIN) return CURLE_OK;
            if (result != CURLE_OK) return result;

            if (gotbytes == 0) {
                Curl_failf(data, "response reading failed (errno: %d)", stdio_c.getSockErrno());
                return CURLE_RECV_ERROR;
            }

            result = containers.curlx_dyn_addn(&pp.recvbuf, &buffer, gotbytes);
            if (result != CURLE_OK) return result;

            if (pheaderbytecount) |phbc| {
                phbc.* +%= @intCast(gotbytes);
            }
            pp.nread_resp += gotbytes;
        }

        while (true) {
            const line_ptr = containers.curlx_dyn_ptr(&pp.recvbuf);
            const rlen = containers.curlx_dyn_len(&pp.recvbuf);
            const line_opt: ?[*]const u8 = if (line_ptr) |p| @ptrCast(p) else null;
            const nl_idx: ?usize = if (line_opt) |lp| std.mem.indexOfScalar(u8, lp[0..rlen], '\n') else null;
            if (nl_idx) |idx| {
                const line = line_opt.?;
                const length = idx + 1;

                if (std.mem.indexOfScalar(u8, line[0..length], 0) != null) {
                    Curl_failf(data, "NUL byte in server response line");
                    return CURLE_WEIRD_SERVER_REPLY;
                }

                Curl_debug(data, CURLINFO_HEADER_IN, line, length);

                result = Curl_client_write(data, CLIENTWRITE_INFO, line, length);
                if (result != CURLE_OK) return result;

                const is_end = if (pp.endofresp) |eor|
                    eor(data, conn, line_ptr.?, length, code)
                else
                    false;
                if (is_end) {
                    pp.nfinal = length;
                    const cur_len = containers.curlx_dyn_len(&pp.recvbuf);
                    if (cur_len > length) {
                        pp.overflow = cur_len - length;
                    } else {
                        pp.overflow = 0;
                    }
                    size.* = pp.nread_resp;
                    pp.nread_resp = 0;
                    gotbytes = 0;
                    break;
                }
                const cur_len = containers.curlx_dyn_len(&pp.recvbuf);
                if (cur_len > length) {
                    _ = containers.curlx_dyn_tail(&pp.recvbuf, cur_len - length);
                } else {
                    containers.curlx_dyn_reset(&pp.recvbuf);
                }
            } else {
                pp.overflow = 0;
                break;
            }
        }

        if (gotbytes != buffer.len) break;
    }

    pp.setPendingResp(false);
    return result;
}

pub export fn Curl_pp_pollset(
    data: ?*Curl_easy,
    pp: *pingpong,
    ps: *easy_pollset,
    sock: curl_socket_t,
) callconv(.c) CURLcode {
    if (!in_libcurl) return CURLE_OK;
    const flags: c_int = if (pp.sendleft != 0) CURL_POLL_OUT else CURL_POLL_IN;
    return Curl_pollset_change(data, ps, sock, flags, 0);
}

pub export fn Curl_pp_needs_flush(_: ?*Curl_easy, pp: *pingpong) callconv(.c) bool {
    return pp.sendleft > 0;
}

pub export fn Curl_pp_flushsend(data: ?*Curl_easy, pp: *pingpong) callconv(.c) CURLcode {
    if (!in_libcurl) return CURLE_SEND_ERROR;
    if (!Curl_pp_needs_flush(data, pp)) return CURLE_OK;

    var written: usize = 0;
    const send_ptr = (pp.sendthis orelse return CURLE_SEND_ERROR) + (pp.sendsize - pp.sendleft);
    var result = Curl_conn_send(data, FIRSTSOCKET, send_ptr, pp.sendleft, false, &written);
    if (result == CURLE_AGAIN) {
        result = CURLE_OK;
        written = 0;
    }
    if (result != CURLE_OK) return result;

    if (written < pp.sendleft) {
        pp.sendleft -= written;
    } else {
        pp.sendthis = null;
        pp.sendleft = 0;
        pp.sendsize = 0;
        pp.response = Curl_pgrs_now(data).*;
    }
    return CURLE_OK;
}

pub export fn Curl_pp_disconnect(pp: *pingpong) callconv(.c) CURLcode {
    if (pp.isInitialized()) {
        containers.curlx_dyn_free(&pp.sendbuf);
        containers.curlx_dyn_free(&pp.recvbuf);
        pp.* = std.mem.zeroes(pingpong);
    }
    return CURLE_OK;
}

pub export fn Curl_pp_moredata(pp: *pingpong) callconv(.c) bool {
    return pp.sendleft == 0 and containers.curlx_dyn_len(&pp.recvbuf) > pp.nfinal;
}

// ============================================================================
// 3. lib/cookie.c (lib/cookie.h)
// ============================================================================

pub const COOKIE_PREFIX__SECURE: c_int = 1 << 0;
pub const COOKIE_PREFIX__HOST: c_int = 1 << 1;
pub const COOKIE_HASH_SIZE: usize = 63;
pub const MAX_COOKIE_LINE: usize = 5000;
pub const MAX_NAME: usize = 4096;
pub const MAX_SET_COOKIE_AMOUNT: u8 = 50;
pub const MAX_COOKIE_HEADER_LEN: usize = 8190;
pub const MAX_COOKIE_SEND_AMOUNT: usize = 150;

pub const COOKIE_HTTPHEADER: c_int = 1 << 0;
pub const COOKIE_NOEXPIRE: c_int = 1 << 1;
pub const COOKIE_SECURE: c_int = 1 << 2;
pub const COOKIE_NOPSL: c_int = 1 << 3;
pub const COOKIE_NOSESSION: c_int = 1 << 6;

const COOKIES_MAXAGE: i64 = 400 * 24 * 3600;
const MAX_DATE_LENGTH: usize = 80;
const DYN_APRINTF: usize = 8 * 1024 * 1024;

const COOKIE_NAME: usize = 0;
const COOKIE_VALUE: usize = 1;
const COOKIE_DOMAIN: usize = 2;
const COOKIE_PATH: usize = 3;
const COOKIE_PIECES: usize = 4;

const CURL_LOCK_DATA_COOKIE: c_uint = 2;
const CURL_LOCK_ACCESS_SINGLE: c_uint = 2;

pub const Cookie = extern struct {
    node: containers.Curl_llist_node = std.mem.zeroes(containers.Curl_llist_node),
    getnode: containers.Curl_llist_node = std.mem.zeroes(containers.Curl_llist_node),
    name: ?[*:0]u8 = null,
    value: ?[*:0]u8 = null,
    path: ?[*:0]u8 = null,
    domain: ?[*:0]u8 = null,
    expires: i64 = 0,
    creationtime: c_uint = 0,
    flags: c_uint = 0,

    pub inline fn isTailmatch(self: *const @This()) bool {
        return (self.flags & 0x01) != 0;
    }
    pub inline fn setTailmatch(self: *@This(), val: bool) void {
        if (val) self.flags |= 0x01 else self.flags &= ~@as(c_uint, 0x01);
    }
    pub inline fn isSecure(self: *const @This()) bool {
        return (self.flags & 0x02) != 0;
    }
    pub inline fn setSecure(self: *@This(), val: bool) void {
        if (val) self.flags |= 0x02 else self.flags &= ~@as(c_uint, 0x02);
    }
    pub inline fn isLivecookie(self: *const @This()) bool {
        return (self.flags & 0x04) != 0;
    }
    pub inline fn setLivecookie(self: *@This(), val: bool) void {
        if (val) self.flags |= 0x04 else self.flags &= ~@as(c_uint, 0x04);
    }
    pub inline fn isHttponly(self: *const @This()) bool {
        return (self.flags & 0x08) != 0;
    }
    pub inline fn setHttponly(self: *@This(), val: bool) void {
        if (val) self.flags |= 0x08 else self.flags &= ~@as(c_uint, 0x08);
    }
    pub inline fn isPrefixSecure(self: *const @This()) bool {
        return (self.flags & 0x10) != 0;
    }
    pub inline fn setPrefixSecure(self: *@This(), val: bool) void {
        if (val) self.flags |= 0x10 else self.flags &= ~@as(c_uint, 0x10);
    }
    pub inline fn isPrefixHost(self: *const @This()) bool {
        return (self.flags & 0x20) != 0;
    }
    pub inline fn setPrefixHost(self: *@This(), val: bool) void {
        if (val) self.flags |= 0x20 else self.flags &= ~@as(c_uint, 0x20);
    }
};

pub const CookieInfo = extern struct {
    cookielist: [COOKIE_HASH_SIZE]containers.Curl_llist,
    next_expiration: i64,
    numcookies: c_uint,
    lastct: c_uint,
    flags: c_uint,

    pub inline fn isRunning(self: *const @This()) bool {
        return (self.flags & 0x01) != 0;
    }
    pub inline fn setRunning(self: *@This(), val: bool) void {
        if (val) self.flags |= 0x01 else self.flags &= ~@as(c_uint, 0x01);
    }
    pub inline fn isNewsession(self: *const @This()) bool {
        return (self.flags & 0x02) != 0;
    }
    pub inline fn setNewsession(self: *@This(), val: bool) void {
        if (val) self.flags |= 0x02 else self.flags &= ~@as(c_uint, 0x02);
    }
};

fn capExpires(now: i64, co: *Cookie) void {
    if (co.expires != 0 and (CURL_OFF_T_MAX - COOKIES_MAXAGE - 30) > now) {
        var cap: i64 = now + COOKIES_MAXAGE;
        if (co.expires > cap) {
            cap += 30;
            co.expires = @divTrunc(cap, 60) * 60;
        }
    }
}

fn freecookie(co: *Cookie, maintoo: bool) void {
    mem.free(co.domain);
    mem.free(co.path);
    mem.free(co.name);
    mem.free(co.value);
    if (maintoo) {
        mem.free(co);
    }
}

fn cookieTailmatch(cookie_domain: [*:0]const u8, cookie_domain_len: usize, hostname: [*:0]const u8) bool {
    const hostname_len = std.mem.len(hostname);
    if (hostname_len < cookie_domain_len) return false;

    const tail_ptr: [*:0]const u8 = @ptrCast(hostname + (hostname_len - cookie_domain_len));
    if (primitives.curl_strnequal(cookie_domain, tail_ptr, cookie_domain_len) == 0) {
        return false;
    }

    if (hostname_len == cookie_domain_len) return true;
    return hostname[hostname_len - cookie_domain_len - 1] == '.';
}

fn pathmatch(cookie_path: [*:0]const u8, uri_path_in: ?[*:0]const u8) bool {
    const cookie_path_len = std.mem.len(cookie_path);
    if (cookie_path_len == 1) return true;

    const raw_uri = uri_path_in orelse "/";
    const uri_path: [*:0]const u8 = if (raw_uri[0] == 0 or raw_uri[0] != '/') "/" else raw_uri;
    const uri_path_len = std.mem.len(uri_path);

    if (uri_path_len < cookie_path_len) return false;
    if (!std.mem.eql(u8, cookie_path[0..cookie_path_len], uri_path[0..cookie_path_len])) return false;
    if (cookie_path_len == uri_path_len) return true;
    if (uri_path[cookie_path_len] == '/') return true;
    return false;
}

fn getTopDomain(domain: ?[*:0]const u8, outlen: *usize) ?[*]const u8 {
    var len: usize = 0;
    if (domain) |dom| {
        len = std.mem.len(dom);
        const slice = dom[0..len];
        if (std.mem.lastIndexOfScalar(u8, slice, '.')) |last_idx| {
            if (std.mem.lastIndexOfScalar(u8, slice[0..last_idx], '.')) |first_idx| {
                const start = first_idx + 1;
                outlen.* = len - start;
                return dom + start;
            }
        }
        outlen.* = len;
        return dom;
    }
    outlen.* = 0;
    return null;
}

fn cookieHashDomain(domain: [*]const u8, len: usize) usize {
    var h: usize = 5381;
    for (domain[0..len]) |ch| {
        const j: usize = primitives.Curl_touppermap[ch];
        h +%= h << 5;
        h ^= j;
    }
    return h % COOKIE_HASH_SIZE;
}

fn cookiehash(domain: ?[*:0]const u8) usize {
    const dom = domain orelse return 0;
    if (netrc_addr_idn.Curl_is_ipaddr(dom)) return 0;
    var len: usize = 0;
    const top = getTopDomain(dom, &len) orelse return 0;
    return cookieHashDomain(top, len);
}

fn sanitizeCookiePath(cookie_path_in: [*]const u8, len_in: usize) ?[*:0]u8 {
    var cookie_path = cookie_path_in;
    var len = len_in;
    if (len > 0 and cookie_path[0] == '"') {
        cookie_path += 1;
        len -= 1;
        if (len > 0 and cookie_path[len - 1] == '"') {
            len -= 1;
        }
    }
    if (len == 0 or cookie_path[0] != '/') {
        const dup = mem.strdup("/") orelse return null;
        return @ptrCast(dup);
    }
    if (len > 1 and cookie_path[len - 1] == '/') {
        len -= 1;
    }
    const dup = curlx_memdup0(cookie_path, len) orelse return null;
    return @ptrCast(dup);
}

fn strstore(str: *?[*:0]u8, newstr: ?[*]const u8, len: usize) CURLcode {
    const dup = curlx_memdup0(newstr, len) orelse return CURLE_OUT_OF_MEMORY;
    str.* = @ptrCast(dup);
    return CURLE_OK;
}

fn removeExpired(ci: *CookieInfo) void {
    const now: i64 = stdio_c.currentTime();
    if (now < ci.next_expiration and ci.next_expiration != CURL_OFF_T_MAX) {
        return;
    }
    ci.next_expiration = CURL_OFF_T_MAX;

    for (&ci.cookielist) |*bucket| {
        var n = containers.Curl_llist_head(bucket);
        while (n) |node| {
            const co: *Cookie = @ptrCast(@alignCast(containers.Curl_node_elem(node).?));
            const next_node = containers.Curl_node_next(node);
            if (co.expires != 0) {
                if (co.expires < now) {
                    containers.Curl_node_remove(node);
                    freecookie(co, true);
                    ci.numcookies -= 1;
                } else if (co.expires < ci.next_expiration) {
                    ci.next_expiration = co.expires;
                }
            }
            n = next_node;
        }
    }
}

fn badDomain(domain: [*]const u8, len: usize) bool {
    if (len == 9 and primitives.curl_strnequal(@ptrCast(domain), "localhost", 9) != 0) {
        return false;
    }
    if (std.mem.indexOfScalar(u8, domain[0..len], '.')) |dot_idx| {
        if ((len - dot_idx) > 1) return false;
    }
    return true;
}

fn invalidOctets(ptr: ?[*]const u8, len: usize) bool {
    const p = ptr orelse return false;
    var i: usize = 0;
    while (i < len and p[i] != 0) : (i += 1) {
        if (p[i] < 0x20 or p[i] == 0x7f) return true;
    }
    return false;
}

fn storecookie(
    co: *Cookie,
    cp: *const [COOKIE_PIECES]curlx_parse.Curl_str,
    path_in: ?[*:0]const u8,
    domain: ?[*:0]const u8,
) CURLcode {
    var result = strstore(&co.name, cp[COOKIE_NAME].str, cp[COOKIE_NAME].len);
    if (result == CURLE_OK) {
        result = strstore(&co.value, cp[COOKIE_VALUE].str, cp[COOKIE_VALUE].len);
    }
    if (result == CURLE_OK) {
        var plen: usize = 0;
        var p_ptr: ?[*]const u8 = null;
        if (cp[COOKIE_PATH].len != 0) {
            p_ptr = cp[COOKIE_PATH].str;
            plen = cp[COOKIE_PATH].len;
        } else if (path_in) |p| {
            p_ptr = p;
            const p_slice = std.mem.span(p);
            if (std.mem.lastIndexOfScalar(u8, p_slice, '/')) |endslash| {
                plen = endslash + 1;
            } else {
                plen = p_slice.len;
            }
        }
        if (p_ptr) |pp| {
            co.path = sanitizeCookiePath(pp, plen);
            if (co.path == null) result = CURLE_OUT_OF_MEMORY;
        }
    }
    if (result == CURLE_OK) {
        if (cp[COOKIE_DOMAIN].len != 0) {
            result = strstore(&co.domain, cp[COOKIE_DOMAIN].str, cp[COOKIE_DOMAIN].len);
        } else if (domain) |dom| {
            const dup = mem.strdup(dom);
            co.domain = if (dup) |d| @ptrCast(d) else null;
            if (co.domain == null) result = CURLE_OUT_OF_MEMORY;
        }
    }
    return result;
}

fn parseFirstPair(
    data: ?*Curl_easy,
    co: *Cookie,
    cookie: *[COOKIE_PIECES]curlx_parse.Curl_str,
    name: *const curlx_parse.Curl_str,
    val: *const curlx_parse.Curl_str,
    sep: bool,
) bool {
    if (!sep or name.len == 0) {
        Curl_infof(data, "invalid cookie, dropped");
        return false;
    }
    if ((name.len + val.len) > MAX_NAME) {
        Curl_infof(data, "oversized cookie dropped, name/val %zu + %zu bytes", name.len, val.len);
        return false;
    }
    if (name.str) |nptr| {
        if (name.len >= 9 and std.mem.eql(u8, nptr[0..9], "__Secure-")) {
            co.setPrefixSecure(true);
        } else if (name.len >= 7 and std.mem.eql(u8, nptr[0..7], "__Host-")) {
            co.setPrefixHost(true);
        }
    }
    cookie[COOKIE_NAME] = name.*;
    cookie[COOKIE_VALUE] = val.*;
    return true;
}

fn parseDomain(
    data: ?*Curl_easy,
    co: *Cookie,
    cookie_domain: *curlx_parse.Curl_str,
    val: *curlx_parse.Curl_str,
    domainp: *?[*:0]const u8,
) bool {
    var domain = domainp.*;
    if (val.str) |v| {
        if (val.len > 0 and v[0] == '.') {
            _ = curlx_str_nudge(val, 1);
        }
    }

    const vptr = val.str orelse return false;
    if (badDomain(vptr, val.len)) {
        domainp.* = ":";
        domain = ":";
    }

    var v_null_buf: [MAX_COOKIE_LINE + 1]u8 = undefined;
    const copy_len = @min(val.len, MAX_COOKIE_LINE);
    @memcpy(v_null_buf[0..copy_len], vptr[0..copy_len]);
    v_null_buf[copy_len] = 0;
    const v_cstr: [*:0]const u8 = @ptrCast(&v_null_buf);

    const is_ip = netrc_addr_idn.Curl_is_ipaddr(domain orelse v_cstr);

    if (domain == null or
        (is_ip and std.mem.eql(u8, vptr[0..val.len], std.mem.span(domain.?))) or
        (!is_ip and cookieTailmatch(v_cstr, val.len, domain.?)))
    {
        cookie_domain.* = val.*;
        if (!is_ip) {
            co.setTailmatch(true);
        }
        return true;
    } else {
        Curl_infof(data, "skipped cookie with bad tailmatch domain: %s", v_cstr);
        return false;
    }
}

fn parseMaxage(co: *Cookie, val: *const curlx_parse.Curl_str, nowp: *i64) void {
    const m_start = val.str orelse {
        co.expires = 1;
        return;
    };
    if (val.len == 0) {
        co.expires = 1;
        return;
    }
    var maxage: ?[*]const u8 = if (m_start[0] == '"') m_start + 1 else m_start;
    if (maxage.?[0] == 0) {
        co.expires = 1;
        return;
    }
    const rc = curlx_str_number(&maxage, &co.expires, CURL_OFF_T_MAX);
    if (nowp.* == 0) {
        nowp.* = stdio_c.currentTime();
    }
    switch (rc) {
        curlx_parse.STRE_OVERFLOW => {
            co.expires = CURL_OFF_T_MAX;
        },
        curlx_parse.STRE_OK => {
            if (co.expires == 0) {
                co.expires = 1;
            } else if ((CURL_OFF_T_MAX - nowp.*) < co.expires) {
                co.expires = CURL_OFF_T_MAX;
            } else {
                co.expires += nowp.*;
            }
        },
        else => {
            co.expires = 1;
        },
    }
    capExpires(nowp.*, co);
}

fn parseExpires(co: *Cookie, val: *const curlx_parse.Curl_str, nowp: *i64) void {
    if (co.expires == 0 and val.len < MAX_DATE_LENGTH) {
        if (val.str) |vptr| {
            var dbuf: [MAX_DATE_LENGTH + 1]u8 = undefined;
            @memcpy(dbuf[0..val.len], vptr[0..val.len]);
            dbuf[val.len] = 0;
            var date: i64 = 0;
            if (Curl_getdate_capped(@ptrCast(&dbuf), &date) == 0) {
                if (date == 0) date += 1;
                co.expires = date;
            } else {
                co.expires = 0;
            }
            if (nowp.* == 0) {
                nowp.* = stdio_c.currentTime();
            }
            capExpires(nowp.*, co);
        }
    }
}

fn parseCookieHeader(
    data: ?*Curl_easy,
    co: *Cookie,
    okay: *bool,
    ptr_in: [*:0]const u8,
    domain_in: ?[*:0]const u8,
    path: ?[*:0]const u8,
    secure_origin: bool,
) CURLcode {
    var now: i64 = 0;
    const linelength = std.mem.len(ptr_in);
    var result: CURLcode = CURLE_OK;
    var cookie: [COOKIE_PIECES]curlx_parse.Curl_str = @splat(.{ .str = null, .len = 0 });
    var ptr: ?[*:0]const u8 = ptr_in;
    var domain = domain_in;

    okay.* = false;
    if (linelength > MAX_COOKIE_LINE) {
        return CURLE_OK;
    }

    while (true) {
        var name: curlx_parse.Curl_str = .{ .str = null, .len = 0 };
        const rc = curlx_str_cspn(&ptr, &name, ";\r\n=");
        if (rc == 0 or rc == curlx_parse.STRE_SHORT) {
            var val: curlx_parse.Curl_str = .{ .str = null, .len = 0 };
            var sep = false;
            curlx_str_trimblanks(&name);

            if (invalidOctets(name.str, name.len)) {
                Curl_infof(data, "invalid octets in name, cookie dropped");
                return CURLE_OK;
            }

            if (curlx_str_single(&ptr, '=') == 0) {
                sep = true;
                if (curlx_str_cspn(&ptr, &val, ";\r\n") == 0) {
                    curlx_str_trimblanks(&val);
                }
                if (invalidOctets(val.str, val.len)) {
                    Curl_infof(data, "invalid octets in value, cookie dropped");
                    return CURLE_OK;
                }
            } else {
                curlx_str_init(&val);
            }

            if (cookie[COOKIE_NAME].len == 0) {
                if (!parseFirstPair(data, co, &cookie, &name, &val, sep)) {
                    return CURLE_OK;
                }
            } else if (curlx_str_casecompare(&name, "secure") != 0) {
                if (secure_origin) {
                    co.setSecure(true);
                } else {
                    Curl_infof(data, "skipped cookie because not 'secure'");
                    return CURLE_OK;
                }
            } else if (curlx_str_casecompare(&name, "httponly") != 0) {
                co.setHttponly(true);
            } else if (sep) {
                if (curlx_str_casecompare(&name, "path") != 0) {
                    cookie[COOKIE_PATH] = val;
                } else if (curlx_str_casecompare(&name, "domain") != 0) {
                    if (val.len != 0 and !parseDomain(data, co, &cookie[COOKIE_DOMAIN], &val, &domain)) {
                        return CURLE_OK;
                    }
                } else if (curlx_str_casecompare(&name, "max-age") != 0 and val.len != 0) {
                    parseMaxage(co, &val, &now);
                } else if (curlx_str_casecompare(&name, "expires") != 0 and val.len != 0) {
                    parseExpires(co, &val, &now);
                }
            }
        }
        if (curlx_str_single(&ptr, ';') != 0) break;
    }

    if (cookie[COOKIE_NAME].len != 0) {
        result = storecookie(co, &cookie, path, domain);
        if (result == CURLE_OK) {
            okay.* = true;
        }
    }
    return result;
}

fn cstrSpnUntil(ptr: [*:0]const u8, delims: []const u8) usize {
    var i: usize = 0;
    while (ptr[i] != 0) : (i += 1) {
        for (delims) |d| {
            if (ptr[i] == d) return i;
        }
    }
    return i;
}

fn parseNetscape(
    co: *Cookie,
    ci: *const CookieInfo,
    okay: *bool,
    lineptr_in: [*:0]const u8,
    secure_origin: bool,
) CURLcode {
    var lineptr = lineptr_in;
    okay.* = false;

    if (std.mem.startsWith(u8, std.mem.span(lineptr), "#HttpOnly_")) {
        lineptr += 10;
        co.setHttponly(true);
    }

    if (lineptr[0] == '#') {
        return CURLE_OK;
    }

    var fields: usize = 0;
    var next_opt: ?[*:0]const u8 = lineptr;
    while (next_opt) |cur_ptr| : (fields += 1) {
        var ptr = cur_ptr;
        var len = cstrSpnUntil(ptr, "\t\r\n");
        next_opt = if (ptr[len] == '\t') ptr + len + 1 else null;

        switch (fields) {
            0 => {
                if (len > 0 and ptr[0] == '.') {
                    ptr += 1;
                    len -= 1;
                }
                const dup = curlx_memdup0(ptr, len) orelse return CURLE_OUT_OF_MEMORY;
                co.domain = @ptrCast(dup);
            },
            1 => {
                co.setTailmatch(primitives.curl_strnequal(ptr, "TRUE", len) != 0);
            },
            2 => {
                if (!std.mem.eql(u8, ptr[0..len], "TRUE") and !std.mem.eql(u8, ptr[0..len], "FALSE")) {
                    co.path = sanitizeCookiePath(ptr, len) orelse return CURLE_OUT_OF_MEMORY;
                } else {
                    const dup = mem.strdup("/") orelse return CURLE_OUT_OF_MEMORY;
                    co.path = @ptrCast(dup);
                    fields += 1;
                    co.setSecure(false);
                    if (primitives.curl_strnequal(ptr, "TRUE", len) != 0) {
                        if (secure_origin or ci.isRunning()) {
                            co.setSecure(true);
                        } else {
                            return CURLE_OK;
                        }
                    }
                }
            },
            3 => {
                co.setSecure(false);
                if (primitives.curl_strnequal(ptr, "TRUE", len) != 0) {
                    if (secure_origin or ci.isRunning()) {
                        co.setSecure(true);
                    } else {
                        return CURLE_OK;
                    }
                }
            },
            4 => {
                var num_ptr: ?[*]const u8 = ptr;
                if (curlx_str_number(&num_ptr, &co.expires, CURL_OFF_T_MAX) != 0) {
                    return CURLE_OK;
                }
            },
            5 => {
                const dup = curlx_memdup0(ptr, len) orelse return CURLE_OUT_OF_MEMORY;
                const name_cstr: [*:0]u8 = @ptrCast(dup);
                co.name = name_cstr;
                const name_slice = name_cstr[0..len];
                if (std.mem.startsWith(u8, name_slice, "__Secure-")) {
                    co.setPrefixSecure(true);
                } else if (std.mem.startsWith(u8, name_slice, "__Host-")) {
                    co.setPrefixHost(true);
                }
            },
            6 => {
                const dup = curlx_memdup0(ptr, len) orelse return CURLE_OUT_OF_MEMORY;
                co.value = @ptrCast(dup);
            },
            else => {},
        }
    }

    if (fields == 6) {
        const dup = mem.strdup("") orelse return CURLE_OUT_OF_MEMORY;
        co.value = @ptrCast(dup);
        fields += 1;
    }

    if (fields != 7) {
        return CURLE_OK;
    }

    const name_cstr = co.name orelse return CURLE_OK;
    const val_cstr = co.value orelse return CURLE_OK;
    if (invalidOctets(name_cstr, std.mem.len(name_cstr)) or
        invalidOctets(val_cstr, std.mem.len(val_cstr)))
    {
        return CURLE_OK;
    }

    okay.* = true;
    return CURLE_OK;
}

fn replaceExisting(
    data: ?*Curl_easy,
    co: *Cookie,
    ci: *CookieInfo,
    secure: bool,
    replacep: *bool,
) bool {
    var replace_old = false;
    var replace_n: ?*containers.Curl_llist_node = null;
    const myhash = cookiehash(co.domain);
    const co_name = std.mem.span(co.name.?);

    var n = containers.Curl_llist_head(&ci.cookielist[myhash]);
    while (n) |node| : (n = containers.Curl_node_next(node)) {
        const clist: *Cookie = @ptrCast(@alignCast(containers.Curl_node_elem(node).?));
        const clist_name = std.mem.span(clist.name.?);
        if (std.mem.eql(u8, clist_name, co_name)) {
            var matching_domains = false;
            if (clist.domain != null and co.domain != null) {
                const cdom = clist.domain.?;
                const ndom = co.domain.?;
                if (cookieTailmatch(cdom, std.mem.len(cdom), ndom) or
                    cookieTailmatch(ndom, std.mem.len(ndom), cdom))
                {
                    matching_domains = true;
                }
            } else if (clist.domain == null and co.domain == null) {
                matching_domains = true;
            }

            if (matching_domains and clist.path != null and co.path != null and
                clist.isSecure() and !co.isSecure() and !secure)
            {
                const cpath_slice = std.mem.span(clist.path.?);
                const npath_slice = std.mem.span(co.path.?);
                var cllen: usize = cpath_slice.len;
                if (cpath_slice.len > 0) {
                    if (std.mem.indexOfScalar(u8, cpath_slice[1..], '/')) |sep_off| {
                        cllen = sep_off + 1;
                    }
                }
                if (npath_slice.len >= cllen and std.mem.eql(u8, cpath_slice[0..cllen], npath_slice[0..cllen])) {
                    Curl_infof(
                        data,
                        "cookie '%s' for domain '%s' dropped, would overlay an existing cookie",
                        co.name.?,
                        co.domain orelse "",
                    );
                    return false;
                }
            }
        }

        if (replace_n == null and std.mem.eql(u8, clist_name, co_name)) {
            if (clist.domain != null and co.domain != null) {
                if (primitives.curl_strequal(clist.domain.?, co.domain.?) != 0 and
                    (clist.isTailmatch() == co.isTailmatch()))
                {
                    replace_old = true;
                }
            } else if (clist.domain == null and co.domain == null) {
                replace_old = true;
            }

            if (replace_old) {
                if (clist.path != null and co.path != null) {
                    if (!std.mem.eql(u8, std.mem.span(clist.path.?), std.mem.span(co.path.?))) {
                        replace_old = false;
                    }
                } else if ((clist.path == null) != (co.path == null)) {
                    replace_old = false;
                }
            }

            if (replace_old and !co.isLivecookie() and clist.isLivecookie()) {
                return false;
            }
            if (replace_old) {
                replace_n = node;
            }
        }
    }

    if (replace_n) |rnode| {
        const repl: *Cookie = @ptrCast(@alignCast(containers.Curl_node_elem(rnode).?));
        co.creationtime = repl.creationtime;
        containers.Curl_node_remove(rnode);
        freecookie(repl, true);
    }
    replacep.* = replace_old;
    return true;
}

pub export fn Curl_cookie_add(
    data: ?*Curl_easy,
    ci: *CookieInfo,
    lineptr: [*:0]const u8,
    domain: ?[*:0]const u8,
    path: ?[*:0]const u8,
    flags: c_int,
    psetcookies: ?*u8,
) callconv(.c) CURLcode {
    if (psetcookies) |psc| {
        if (psc.* >= MAX_SET_COOKIE_AMOUNT) return CURLE_OK;
    }

    var comem: Cookie = .{};
    var result: CURLcode = CURLE_OK;
    var replaces = false;
    var okay = false;
    const secure_flag = (flags & COOKIE_SECURE) != 0;

    if ((flags & COOKIE_HTTPHEADER) != 0) {
        result = parseCookieHeader(data, &comem, &okay, lineptr, domain, path, secure_flag);
    } else {
        result = parseNetscape(&comem, ci, &okay, lineptr, secure_flag);
    }

    if (result != CURLE_OK or !okay) {
        freecookie(&comem, false);
        return result;
    }

    if (comem.isPrefixSecure() and !comem.isSecure()) {
        freecookie(&comem, false);
        return result;
    }

    if (comem.isPrefixHost()) {
        const path_ok = if (comem.path) |p| std.mem.eql(u8, std.mem.span(p), "/") else false;
        if (!(comem.isSecure() and path_ok and !comem.isTailmatch())) {
            freecookie(&comem, false);
            return result;
        }
    }

    if (!ci.isRunning() and ci.isNewsession() and comem.expires == 0) {
        freecookie(&comem, false);
        return result;
    }

    comem.setLivecookie(ci.isRunning());
    ci.lastct +%= 1;
    comem.creationtime = ci.lastct;

    if ((flags & COOKIE_NOEXPIRE) == 0) {
        removeExpired(ci);
    }

    if (!replaceExisting(data, &comem, ci, secure_flag, &replaces)) {
        freecookie(&comem, false);
        return result;
    }

    const co_raw = curlx_memdup(&comem, @sizeOf(Cookie)) orelse {
        freecookie(&comem, false);
        return CURLE_OUT_OF_MEMORY;
    };
    const co: *Cookie = @ptrCast(@alignCast(co_raw));

    const myhash = cookiehash(co.domain);
    containers.Curl_llist_append(&ci.cookielist[myhash], co, &co.node);

    if (ci.isRunning()) {
        Curl_infof(
            data,
            "%s cookie %s=\"%s\" for domain %s, path %s, expire %lld",
            if (replaces) @as([*:0]const u8, "Replaced") else @as([*:0]const u8, "Added"),
            co.name orelse "",
            co.value orelse "",
            co.domain orelse "",
            co.path orelse "",
            @as(c_longlong, co.expires),
        );
    }

    if (!replaces) {
        ci.numcookies += 1;
    }

    if (co.expires != 0 and co.expires < ci.next_expiration) {
        ci.next_expiration = co.expires;
    }

    if ((flags & COOKIE_HTTPHEADER) != 0) {
        if (psetcookies) |psc| {
            psc.* += 1;
        }
    }

    return result;
}

pub export fn Curl_cookie_init() callconv(.c) ?*CookieInfo {
    const raw = mem.calloc(1, @sizeOf(CookieInfo)) orelse return null;
    const ci: *CookieInfo = @ptrCast(@alignCast(raw));
    for (&ci.cookielist) |*bucket| {
        containers.Curl_llist_init(bucket, null);
    }
    ci.next_expiration = CURL_OFF_T_MAX;
    return ci;
}

fn cookieLoad(
    data: ?*Curl_easy,
    file: ?[*:0]const u8,
    ci: *CookieInfo,
    flags: c_int,
    psetcookies: ?*u8,
) CURLcode {
    var handle: ?*anyopaque = null;
    var result: CURLcode = CURLE_OK;
    var fp: ?*anyopaque = null;

    ci.setNewsession((flags & COOKIE_NOSESSION) != 0);
    ci.setRunning(false);

    if (file) |f| {
        if (f[0] != 0) {
            if (std.mem.eql(u8, std.mem.span(f), "-")) {
                fp = stdio_c.getStdin();
            } else {
                fp = stdio_c.fopenReadBinary(f);
                if (fp == null) {
                    Curl_infof(data, "WARNING: failed to open cookie file \"%s\"", f);
                } else if (stdio_c.isStreamDir(f, fp.?)) {
                    _ = stdio_c.fclose(fp);
                    fp = null;
                    Curl_infof(data, "WARNING: cookie filename points to a directory: \"%s\"", f);
                } else {
                    handle = fp;
                }
            }
        }
    }

    if (fp) |stream| {
        var buf: containers.dynbuf = std.mem.zeroes(containers.dynbuf);
        var eof = false;
        containers.curlx_dyn_init(&buf, DYN_APRINTF + 2);
        while (true) {
            result = os_leaf.Curl_get_line(@ptrCast(&buf), stream, &eof);
            if (result == CURLE_OK) {
                if (containers.curlx_dyn_ptr(&buf)) |raw_line| {
                    var lineptr: [*:0]const u8 = raw_line;
                    var headerline = false;
                    if (primitives.curl_strnequal(lineptr, "Set-Cookie:", 11) != 0) {
                        lineptr += 11;
                        headerline = true;
                        var opt_ptr: ?[*:0]const u8 = lineptr;
                        curlx_str_passblanks(&opt_ptr);
                        lineptr = opt_ptr.?;
                    }
                    const add_flags: c_int = (if (headerline) COOKIE_HTTPHEADER else 0) |
                        COOKIE_NOEXPIRE | COOKIE_SECURE | (flags & COOKIE_NOPSL);
                    result = Curl_cookie_add(data, ci, lineptr, null, null, add_flags, psetcookies);
                    if (result != CURLE_OUT_OF_MEMORY) {
                        result = CURLE_OK;
                    }
                }
            }
            if (result != CURLE_OK or eof) break;
        }
        containers.curlx_dyn_free(&buf);
        removeExpired(ci);
        if (handle) |h| {
            _ = stdio_c.fclose(h);
        }
    }
    ci.setRunning(true);
    return result;
}

pub export fn Curl_cookie_loadfiles(
    data: ?*Curl_easy,
    flags: c_int,
    cookielist: ?*containers.curl_slist,
    pcookies: *?*CookieInfo,
    psetcookies: ?*u8,
) callconv(.c) CURLcode {
    var result: CURLcode = CURLE_OK;
    var list = cookielist;
    if (list != null) {
        if (in_libcurl and data != null) _ = Curl_share_lock(data, CURL_LOCK_DATA_COOKIE, CURL_LOCK_ACCESS_SINGLE);
        if (pcookies.* == null) {
            pcookies.* = Curl_cookie_init();
        }
        if (pcookies.*) |ci| {
            while (list) |item| : (list = item.next) {
                result = cookieLoad(data, item.data, ci, flags, psetcookies);
                if (result != CURLE_OK) break;
            }
        } else {
            result = CURLE_OUT_OF_MEMORY;
        }
        if (in_libcurl and data != null) _ = Curl_share_unlock(data, CURL_LOCK_DATA_COOKIE);
    }
    return result;
}

fn cookieSortLessThan(_: void, c1: *Cookie, c2: *Cookie) bool {
    const p1 = if (c1.path) |p| std.mem.len(p) else 0;
    const p2 = if (c2.path) |p| std.mem.len(p) else 0;
    if (p1 != p2) return p1 > p2;

    const d1 = if (c1.domain) |d| std.mem.len(d) else 0;
    const d2 = if (c2.domain) |d| std.mem.len(d) else 0;
    if (d1 != d2) return d1 > d2;

    const n1 = if (c1.name) |n| std.mem.len(n) else 0;
    const n2 = if (c2.name) |n| std.mem.len(n) else 0;
    if (n1 != n2) return n1 > n2;

    return c1.creationtime < c2.creationtime;
}

fn cookieSortCtLessThan(_: void, c1: *Cookie, c2: *Cookie) bool {
    return c1.creationtime < c2.creationtime;
}

pub export fn Curl_secure_context(data: ?*Curl_easy, host: [*:0]const u8) callconv(.c) bool {
    const host_slice = std.mem.span(host);
    const xfer_sec = if (in_libcurl and data != null) Curl_xfer_is_secure(data) else false;
    return xfer_sec or
        primitives.curl_strequal("localhost", host) != 0 or
        std.mem.eql(u8, host_slice, "127.0.0.1") or
        std.mem.eql(u8, host_slice, "::1");
}

pub export fn Curl_cookie_getlist(
    data: ?*Curl_easy,
    ci_opt: ?*CookieInfo,
    uri_path: ?[*:0]const u8,
    okay: *bool,
    host: [*:0]const u8,
    list: *containers.Curl_llist,
) callconv(.c) CURLcode {
    var matches: usize = 0;
    const is_ip = netrc_addr_idn.Curl_is_ipaddr(host);
    const myhash = cookiehash(host);
    const secure = Curl_secure_context(data, host);
    okay.* = false;

    containers.Curl_llist_init(list, null);

    const ci = ci_opt orelse return CURLE_OK;
    if (containers.Curl_llist_count(&ci.cookielist[myhash]) == 0) {
        return CURLE_OK;
    }

    removeExpired(ci);

    var n = containers.Curl_llist_head(&ci.cookielist[myhash]);
    while (n) |node| : (n = containers.Curl_node_next(node)) {
        const co: *Cookie = @ptrCast(@alignCast(containers.Curl_node_elem(node).?));
        if (if (co.isSecure()) secure else true) {
            const domain_ok = if (co.domain) |cdom|
                ((co.isTailmatch() and !is_ip and cookieTailmatch(cdom, std.mem.len(cdom), host)) or
                    ((!co.isTailmatch() or is_ip) and primitives.curl_strequal(host, cdom) != 0))
            else
                true;
            if (domain_ok) {
                const path_ok = if (co.path) |cpath| pathmatch(cpath, uri_path) else true;
                if (path_ok) {
                    containers.Curl_llist_append(list, co, &co.getnode);
                    matches += 1;
                    if (matches >= MAX_COOKIE_SEND_AMOUNT) {
                        Curl_infof(data, "Included max number of cookies (%zu) in request!", matches);
                        break;
                    }
                }
            }
        }
    }

    if (matches != 0) {
        const array_raw = mem.malloc(@sizeOf(*Cookie) * matches) orelse {
            containers.Curl_llist_destroy(list, null);
            return CURLE_OUT_OF_MEMORY;
        };
        const array: [*]*Cookie = @ptrCast(@alignCast(array_raw));

        var cur = containers.Curl_llist_head(list);
        var i: usize = 0;
        while (cur) |node| : (cur = containers.Curl_node_next(node)) {
            array[i] = @ptrCast(@alignCast(containers.Curl_node_elem(node).?));
            i += 1;
        }

        std.mem.sort(*Cookie, array[0..matches], {}, cookieSortLessThan);

        containers.Curl_llist_destroy(list, null);
        for (array[0..matches]) |co| {
            containers.Curl_llist_append(list, co, &co.getnode);
        }
        mem.free(array_raw);
    }

    okay.* = true;
    return CURLE_OK;
}

pub export fn Curl_cookie_clearall(ci_opt: ?*CookieInfo) callconv(.c) void {
    const ci = ci_opt orelse return;
    for (&ci.cookielist) |*bucket| {
        var n = containers.Curl_llist_head(bucket);
        while (n) |node| {
            const c: *Cookie = @ptrCast(@alignCast(containers.Curl_node_elem(node).?));
            const next_node = containers.Curl_node_next(node);
            containers.Curl_node_remove(node);
            freecookie(c, true);
            n = next_node;
        }
    }
    ci.numcookies = 0;
}

pub export fn Curl_cookie_clearsess(ci_opt: ?*CookieInfo) callconv(.c) void {
    const ci = ci_opt orelse return;
    for (&ci.cookielist) |*bucket| {
        var n = containers.Curl_llist_head(bucket);
        while (n) |node| {
            const curr: *Cookie = @ptrCast(@alignCast(containers.Curl_node_elem(node).?));
            const next_node = containers.Curl_node_next(node);
            if (curr.expires == 0) {
                containers.Curl_node_remove(node);
                freecookie(curr, true);
                ci.numcookies -= 1;
            }
            n = next_node;
        }
    }
}

pub export fn Curl_cookie_cleanup(ci_opt: ?*CookieInfo) callconv(.c) void {
    const ci = ci_opt orelse return;
    Curl_cookie_clearall(ci);
    mem.free(ci);
}

fn getNetscapeFormat(co: *const Cookie) ?[*:0]u8 {
    const httponly_str: [*:0]const u8 = if (co.isHttponly()) "#HttpOnly_" else "";
    const lead_dot: [*:0]const u8 = if (co.isTailmatch() and co.domain != null and co.domain.?[0] != '.') "." else "";
    const dom_str: [*:0]const u8 = co.domain orelse "unknown";
    const tail_str: [*:0]const u8 = if (co.isTailmatch()) "TRUE" else "FALSE";
    const path_str: [*:0]const u8 = co.path orelse "/";
    const sec_str: [*:0]const u8 = if (co.isSecure()) "TRUE" else "FALSE";
    const name_str: [*:0]const u8 = co.name orelse "";
    const val_str: [*:0]const u8 = co.value orelse "";

    return curl_maprintf(
        "%s%s%s\t%s\t%s\t%s\t%lld\t%s\t%s",
        httponly_str,
        lead_dot,
        dom_str,
        tail_str,
        path_str,
        sec_str,
        @as(c_longlong, co.expires),
        name_str,
        val_str,
    );
}

fn cookieOutput(data: ?*Curl_easy, ci_opt: ?*CookieInfo, filename: [*:0]const u8) CURLcode {
    const ci = ci_opt orelse return CURLE_OK;
    var out: ?*anyopaque = null;
    var use_stdout = false;
    var tempstore: ?[*:0]u8 = null;
    var result: CURLcode = CURLE_OK;

    removeExpired(ci);

    if (std.mem.eql(u8, std.mem.span(filename), "-")) {
        out = stdio_c.getStdout();
        use_stdout = true;
    } else {
        result = http1_options.Curl_fopen(data, filename, &out, &tempstore);
        if (result != CURLE_OK) {
            if (tempstore) |ts| {
                _ = stdio_c.unlinkFile(ts);
                mem.free(ts);
            }
            return result;
        }
    }

    _ = stdio_c.fputs(
        "# Netscape HTTP Cookie File\n" ++
            "# https://curl.se/docs/http-cookies.html\n" ++
            "# This file was generated by libcurl! Edit at your own risk.\n\n",
        out,
    );

    if (ci.numcookies != 0) {
        var nvalid: usize = 0;
        const array_raw = mem.calloc(1, @sizeOf(*Cookie) * ci.numcookies) orelse {
            if (out != null and !use_stdout) _ = stdio_c.fclose(out);
            if (tempstore) |ts| {
                _ = stdio_c.unlinkFile(ts);
                mem.free(ts);
            }
            return CURLE_OUT_OF_MEMORY;
        };
        const array: [*]*Cookie = @ptrCast(@alignCast(array_raw));

        for (&ci.cookielist) |*bucket| {
            var n = containers.Curl_llist_head(bucket);
            while (n) |node| : (n = containers.Curl_node_next(node)) {
                const co: *Cookie = @ptrCast(@alignCast(containers.Curl_node_elem(node).?));
                if (co.domain == null) continue;
                array[nvalid] = co;
                nvalid += 1;
            }
        }

        std.mem.sort(*Cookie, array[0..nvalid], {}, cookieSortCtLessThan);

        for (array[0..nvalid]) |co| {
            const format_ptr = getNetscapeFormat(co) orelse {
                mem.free(array_raw);
                if (out != null and !use_stdout) _ = stdio_c.fclose(out);
                if (tempstore) |ts| {
                    _ = stdio_c.unlinkFile(ts);
                    mem.free(ts);
                }
                return CURLE_OUT_OF_MEMORY;
            };
            _ = curl_mfprintf(out, "%s\n", format_ptr);
            mem.free(format_ptr);
        }

        mem.free(array_raw);
    }

    if (!use_stdout) {
        _ = stdio_c.fclose(out);
        out = null;
        if (tempstore) |ts| {
            if (stdio_c.renameFile(ts, filename) != 0) {
                _ = stdio_c.unlinkFile(ts);
                mem.free(ts);
                return CURLE_WRITE_ERROR;
            }
        }
    }

    mem.free(tempstore);
    return CURLE_OK;
}

fn cookieListInternal(cookies_opt: ?*CookieInfo) ?*containers.curl_slist {
    const cookies = cookies_opt orelse return null;
    if (cookies.numcookies == 0) return null;

    var list: ?*containers.curl_slist = null;
    var tail: *?*containers.curl_slist = &list;

    removeExpired(cookies);

    for (&cookies.cookielist) |*bucket| {
        var n = containers.Curl_llist_head(bucket);
        while (n) |node| : (n = containers.Curl_node_next(node)) {
            const c: *Cookie = @ptrCast(@alignCast(containers.Curl_node_elem(node).?));
            if (c.domain == null) continue;
            const line = getNetscapeFormat(c) orelse {
                curl_slist_free_all(list);
                return null;
            };
            const beg = Curl_slist_append_nodup(null, line) orelse {
                mem.free(line);
                curl_slist_free_all(list);
                return null;
            };
            tail.* = beg;
            tail = &beg.next;
        }
    }

    return list;
}

pub export fn Curl_cookie_list(data: ?*Curl_easy, cookies: ?*CookieInfo) callconv(.c) ?*containers.curl_slist {
    if (in_libcurl and data != null) _ = Curl_share_lock(data, CURL_LOCK_DATA_COOKIE, CURL_LOCK_ACCESS_SINGLE);
    const list = cookieListInternal(cookies);
    if (in_libcurl and data != null) _ = Curl_share_unlock(data, CURL_LOCK_DATA_COOKIE);
    return list;
}

pub export fn Curl_flush_cookies(
    data: ?*Curl_easy,
    cleanup: bool,
    pcookies: *?*CookieInfo,
    cookiejar: ?[*:0]const u8,
    share_cookies: ?*CookieInfo,
) callconv(.c) void {
    if (in_libcurl and data != null) _ = Curl_share_lock(data, CURL_LOCK_DATA_COOKIE, CURL_LOCK_ACCESS_SINGLE);
    if (pcookies.*) |cookies| {
        if (cookiejar) |jar| {
            if (cookies.isRunning()) {
                const result = cookieOutput(data, cookies, jar);
                if (result != CURLE_OK) {
                    Curl_infof(data, "WARNING: failed to save cookies in %s: %s", jar, curl_easy_strerror(result));
                }
            }
        }
        if (cleanup and (share_cookies == null or cookies != share_cookies.?)) {
            Curl_cookie_cleanup(cookies);
            pcookies.* = null;
        }
    }
    if (in_libcurl and data != null) _ = Curl_share_unlock(data, CURL_LOCK_DATA_COOKIE);
}

pub export fn Curl_cookie_run(data: ?*Curl_easy, cookies: ?*CookieInfo) callconv(.c) void {
    if (in_libcurl and data != null) _ = Curl_share_lock(data, CURL_LOCK_DATA_COOKIE, CURL_LOCK_ACCESS_SINGLE);
    if (cookies) |ci| {
        ci.setRunning(true);
    }
    if (in_libcurl and data != null) _ = Curl_share_unlock(data, CURL_LOCK_DATA_COOKIE);
}

// ============================================================================
// Variadic C ABI Entry Points Across All 4 Targets
// ============================================================================

const use_c_vastart = switch (builtin.cpu.arch) {
    .x86_64 => builtin.os.tag != .windows,
    .aarch64, .aarch64_be => builtin.os.tag.isDarwin(),
    else => false,
};

fn win64Thunk2(comptime target_sym: []const u8) fn () callconv(.naked) void {
    return struct {
        fn thunk() callconv(.naked) void {
            asm volatile ("movq %%r8, 24(%%rsp)\n\t" ++
                    "movq %%r9, 32(%%rsp)\n\t" ++
                    "leaq 24(%%rsp), %%r8\n\t" ++
                    "jmp " ++ target_sym);
        }
    }.thunk;
}

fn win64Thunk3(comptime target_sym: []const u8) fn () callconv(.naked) void {
    return struct {
        fn thunk() callconv(.naked) void {
            asm volatile ("movq %%r9, 32(%%rsp)\n\t" ++
                    "leaq 32(%%rsp), %%r9\n\t" ++
                    "jmp " ++ target_sym);
        }
    }.thunk;
}

fn aarch64Thunk2(comptime target_sym: []const u8) fn () callconv(.naked) void {
    return struct {
        fn thunk() callconv(.naked) void {
            asm volatile ("sub sp, sp, #256\n\t" ++
                    "stp x29, x30, [sp, #240]\n\t" ++
                    "add x29, sp, #240\n\t" ++
                    "stp x2, x3, [x29, #-112]\n\t" ++
                    "stp x4, x5, [x29, #-96]\n\t" ++
                    "stp x6, x7, [x29, #-80]\n\t" ++
                    "stp q0, q1, [sp]\n\t" ++
                    "stp q2, q3, [sp, #32]\n\t" ++
                    "stp q4, q5, [sp, #64]\n\t" ++
                    "stp q6, q7, [sp, #96]\n\t" ++
                    "add x9, x29, #16\n\t" ++
                    "sub x8, x29, #64\n\t" ++
                    "stp x9, x8, [x29, #-64]\n\t" ++
                    "add x9, sp, #128\n\t" ++
                    "mov x8, #-48\n\t" ++
                    "movk x8, #65408, lsl #32\n\t" ++
                    "stp x9, x8, [x29, #-48]\n\t" ++
                    "sub x2, x29, #64\n\t" ++
                    "bl " ++ target_sym ++ "\n\t" ++
                    "ldp x29, x30, [sp, #240]\n\t" ++
                    "add sp, sp, #256\n\t" ++
                    "ret");
        }
    }.thunk;
}

fn aarch64Thunk3(comptime target_sym: []const u8) fn () callconv(.naked) void {
    return struct {
        fn thunk() callconv(.naked) void {
            asm volatile ("sub sp, sp, #256\n\t" ++
                    "stp x29, x30, [sp, #240]\n\t" ++
                    "add x29, sp, #240\n\t" ++
                    "str x3, [x29, #-104]\n\t" ++
                    "stp x4, x5, [x29, #-96]\n\t" ++
                    "stp x6, x7, [x29, #-80]\n\t" ++
                    "stp q0, q1, [sp]\n\t" ++
                    "stp q2, q3, [sp, #32]\n\t" ++
                    "stp q4, q5, [sp, #64]\n\t" ++
                    "stp q6, q7, [sp, #96]\n\t" ++
                    "add x9, x29, #16\n\t" ++
                    "sub x8, x29, #64\n\t" ++
                    "stp x9, x8, [x29, #-64]\n\t" ++
                    "add x9, sp, #128\n\t" ++
                    "mov x8, #-40\n\t" ++
                    "movk x8, #65408, lsl #32\n\t" ++
                    "stp x9, x8, [x29, #-48]\n\t" ++
                    "sub x3, x29, #64\n\t" ++
                    "bl " ++ target_sym ++ "\n\t" ++
                    "ldp x29, x30, [sp, #240]\n\t" ++
                    "add sp, sp, #256\n\t" ++
                    "ret");
        }
    }.thunk;
}

const variadic_impl = if (use_c_vastart) struct {
    pub fn Curl_failf(data: ?*Curl_easy, fmt: [*:0]const u8, ...) callconv(.c) void {
        var ap = @cVaStart();
        defer @cVaEnd(&ap);
        const param: CVaListParam = if (builtin.cpu.arch == .x86_64) &ap else @ptrCast(ap);
        Curl_vfailf(data, fmt, param);
    }
    pub fn Curl_infof(data: ?*Curl_easy, fmt: [*:0]const u8, ...) callconv(.c) void {
        var ap = @cVaStart();
        defer @cVaEnd(&ap);
        const param: CVaListParam = if (builtin.cpu.arch == .x86_64) &ap else @ptrCast(ap);
        Curl_vinfof(data, fmt, param);
    }
    pub fn Curl_trc_cf_infof(data: ?*Curl_easy, cf: ?*const vfilters.Curl_cfilter, fmt: [*:0]const u8, ...) callconv(.c) void {
        var ap = @cVaStart();
        defer @cVaEnd(&ap);
        const param: CVaListParam = if (builtin.cpu.arch == .x86_64) &ap else @ptrCast(ap);
        Curl_vtrc_cf_infof(data, cf, fmt, param);
    }
    pub fn Curl_trc_feat_infof(data: ?*Curl_easy, feat: ?*curl_trc_feat, fmt: [*:0]const u8, ...) callconv(.c) void {
        var ap = @cVaStart();
        defer @cVaEnd(&ap);
        const param: CVaListParam = if (builtin.cpu.arch == .x86_64) &ap else @ptrCast(ap);
        Curl_vtrc_feat_infof(data, feat, fmt, param);
    }
    pub fn Curl_trc_timer(data: ?*Curl_easy, tid: c_int, fmt: [*:0]const u8, ...) callconv(.c) void {
        var ap = @cVaStart();
        defer @cVaEnd(&ap);
        const param: CVaListParam = if (builtin.cpu.arch == .x86_64) &ap else @ptrCast(ap);
        Curl_vtrc_timer(data, tid, fmt, param);
    }
    pub fn Curl_trc_multi(data: ?*Curl_easy, fmt: [*:0]const u8, ...) callconv(.c) void {
        var ap = @cVaStart();
        defer @cVaEnd(&ap);
        const param: CVaListParam = if (builtin.cpu.arch == .x86_64) &ap else @ptrCast(ap);
        Curl_vtrc_multi(data, fmt, param);
    }
    pub fn Curl_trc_read(data: ?*Curl_easy, fmt: [*:0]const u8, ...) callconv(.c) void {
        var ap = @cVaStart();
        defer @cVaEnd(&ap);
        const param: CVaListParam = if (builtin.cpu.arch == .x86_64) &ap else @ptrCast(ap);
        Curl_vtrc_read(data, fmt, param);
    }
    pub fn Curl_trc_write(data: ?*Curl_easy, fmt: [*:0]const u8, ...) callconv(.c) void {
        var ap = @cVaStart();
        defer @cVaEnd(&ap);
        const param: CVaListParam = if (builtin.cpu.arch == .x86_64) &ap else @ptrCast(ap);
        Curl_vtrc_write(data, fmt, param);
    }
    pub fn Curl_trc_dns(data: ?*Curl_easy, fmt: [*:0]const u8, ...) callconv(.c) void {
        var ap = @cVaStart();
        defer @cVaEnd(&ap);
        const param: CVaListParam = if (builtin.cpu.arch == .x86_64) &ap else @ptrCast(ap);
        Curl_vtrc_dns(data, fmt, param);
    }
    pub fn Curl_trc_ftp(data: ?*Curl_easy, fmt: [*:0]const u8, ...) callconv(.c) void {
        var ap = @cVaStart();
        defer @cVaEnd(&ap);
        const param: CVaListParam = if (builtin.cpu.arch == .x86_64) &ap else @ptrCast(ap);
        Curl_vtrc_ftp(data, fmt, param);
    }
    pub fn Curl_trc_smtp(data: ?*Curl_easy, fmt: [*:0]const u8, ...) callconv(.c) void {
        var ap = @cVaStart();
        defer @cVaEnd(&ap);
        const param: CVaListParam = if (builtin.cpu.arch == .x86_64) &ap else @ptrCast(ap);
        Curl_vtrc_smtp(data, fmt, param);
    }
    pub fn Curl_trc_ssls(data: ?*Curl_easy, fmt: [*:0]const u8, ...) callconv(.c) void {
        var ap = @cVaStart();
        defer @cVaEnd(&ap);
        const param: CVaListParam = if (builtin.cpu.arch == .x86_64) &ap else @ptrCast(ap);
        Curl_vtrc_ssls(data, fmt, param);
    }
    pub fn Curl_trc_ssh(data: ?*Curl_easy, fmt: [*:0]const u8, ...) callconv(.c) void {
        var ap = @cVaStart();
        defer @cVaEnd(&ap);
        const param: CVaListParam = if (builtin.cpu.arch == .x86_64) &ap else @ptrCast(ap);
        Curl_vtrc_ssh(data, fmt, param);
    }
    pub fn Curl_trc_ws(data: ?*Curl_easy, fmt: [*:0]const u8, ...) callconv(.c) void {
        var ap = @cVaStart();
        defer @cVaEnd(&ap);
        const param: CVaListParam = if (builtin.cpu.arch == .x86_64) &ap else @ptrCast(ap);
        Curl_vtrc_ws(data, fmt, param);
    }
    pub fn Curl_pp_sendf(data: ?*Curl_easy, pp: *pingpong, fmt: [*:0]const u8, ...) callconv(.c) CURLcode {
        var ap = @cVaStart();
        defer @cVaEnd(&ap);
        const param: CVaListParam = if (builtin.cpu.arch == .x86_64) &ap else @ptrCast(ap);
        return Curl_pp_vsendf_3(data, pp, fmt, param);
    }
} else if (builtin.cpu.arch == .x86_64 and builtin.os.tag == .windows) struct {
    pub const Curl_failf = win64Thunk2("Curl_vfailf");
    pub const Curl_infof = win64Thunk2("Curl_vinfof");
    pub const Curl_trc_cf_infof = win64Thunk3("Curl_vtrc_cf_infof");
    pub const Curl_trc_feat_infof = win64Thunk3("Curl_vtrc_feat_infof");
    pub const Curl_trc_timer = win64Thunk3("Curl_vtrc_timer");
    pub const Curl_trc_multi = win64Thunk2("Curl_vtrc_multi");
    pub const Curl_trc_read = win64Thunk2("Curl_vtrc_read");
    pub const Curl_trc_write = win64Thunk2("Curl_vtrc_write");
    pub const Curl_trc_dns = win64Thunk2("Curl_vtrc_dns");
    pub const Curl_trc_ftp = win64Thunk2("Curl_vtrc_ftp");
    pub const Curl_trc_smtp = win64Thunk2("Curl_vtrc_smtp");
    pub const Curl_trc_ssls = win64Thunk2("Curl_vtrc_ssls");
    pub const Curl_trc_ssh = win64Thunk2("Curl_vtrc_ssh");
    pub const Curl_trc_ws = win64Thunk2("Curl_vtrc_ws");
    pub const Curl_pp_sendf = win64Thunk3("Curl_pp_vsendf_3");
} else if (builtin.cpu.arch == .aarch64) struct {
    pub const Curl_failf = aarch64Thunk2("Curl_vfailf");
    pub const Curl_infof = aarch64Thunk2("Curl_vinfof");
    pub const Curl_trc_cf_infof = aarch64Thunk3("Curl_vtrc_cf_infof");
    pub const Curl_trc_feat_infof = aarch64Thunk3("Curl_vtrc_feat_infof");
    pub const Curl_trc_timer = aarch64Thunk3("Curl_vtrc_timer");
    pub const Curl_trc_multi = aarch64Thunk2("Curl_vtrc_multi");
    pub const Curl_trc_read = aarch64Thunk2("Curl_vtrc_read");
    pub const Curl_trc_write = aarch64Thunk2("Curl_vtrc_write");
    pub const Curl_trc_dns = aarch64Thunk2("Curl_vtrc_dns");
    pub const Curl_trc_ftp = aarch64Thunk2("Curl_vtrc_ftp");
    pub const Curl_trc_smtp = aarch64Thunk2("Curl_vtrc_smtp");
    pub const Curl_trc_ssls = aarch64Thunk2("Curl_vtrc_ssls");
    pub const Curl_trc_ssh = aarch64Thunk2("Curl_vtrc_ssh");
    pub const Curl_trc_ws = aarch64Thunk2("Curl_vtrc_ws");
    pub const Curl_pp_sendf = aarch64Thunk3("Curl_pp_vsendf_3");
} else struct {};

comptime {
    @export(&variadic_impl.Curl_failf, .{ .name = "Curl_failf", .linkage = .strong });
    @export(&variadic_impl.Curl_infof, .{ .name = "Curl_infof", .linkage = .strong });
    @export(&variadic_impl.Curl_trc_cf_infof, .{ .name = "Curl_trc_cf_infof", .linkage = .strong });
    @export(&variadic_impl.Curl_trc_feat_infof, .{ .name = "Curl_trc_feat_infof", .linkage = .strong });
    @export(&variadic_impl.Curl_trc_timer, .{ .name = "Curl_trc_timer", .linkage = .strong });
    @export(&variadic_impl.Curl_trc_multi, .{ .name = "Curl_trc_multi", .linkage = .strong });
    @export(&variadic_impl.Curl_trc_read, .{ .name = "Curl_trc_read", .linkage = .strong });
    @export(&variadic_impl.Curl_trc_write, .{ .name = "Curl_trc_write", .linkage = .strong });
    @export(&variadic_impl.Curl_trc_dns, .{ .name = "Curl_trc_dns", .linkage = .strong });
    @export(&variadic_impl.Curl_trc_ftp, .{ .name = "Curl_trc_ftp", .linkage = .strong });
    @export(&variadic_impl.Curl_trc_smtp, .{ .name = "Curl_trc_smtp", .linkage = .strong });
    @export(&variadic_impl.Curl_trc_ssls, .{ .name = "Curl_trc_ssls", .linkage = .strong });
    @export(&variadic_impl.Curl_trc_ssh, .{ .name = "Curl_trc_ssh", .linkage = .strong });
    @export(&variadic_impl.Curl_trc_ws, .{ .name = "Curl_trc_ws", .linkage = .strong });
    @export(&variadic_impl.Curl_pp_sendf, .{ .name = "Curl_pp_sendf", .linkage = .strong });
}

extern fn Curl_failf(data: ?*Curl_easy, fmt: [*:0]const u8, ...) callconv(.c) void;
extern fn Curl_infof(data: ?*Curl_easy, fmt: [*:0]const u8, ...) callconv(.c) void;
extern fn Curl_trc_timer(data: ?*Curl_easy, tid: c_int, fmt: [*:0]const u8, ...) callconv(.c) void;

// ============================================================================
// Unit Tests
// ============================================================================

test "Curl_trc_mstate_name, Curl_trc_timer_name, and Curl_trc_opt" {
    try std.testing.expectEqualStrings("INIT", std.mem.span(Curl_trc_mstate_name(0)));
    try std.testing.expectEqualStrings("MSGSENT", std.mem.span(Curl_trc_mstate_name(15)));
    try std.testing.expectEqualStrings("?", std.mem.span(Curl_trc_mstate_name(-1)));
    try std.testing.expectEqualStrings("?", std.mem.span(Curl_trc_mstate_name(99)));

    try std.testing.expectEqualStrings("100_TIMEOUT", std.mem.span(Curl_trc_timer_name(0)));
    try std.testing.expectEqualStrings("SERVER_RESPONSE", std.mem.span(Curl_trc_timer_name(12)));
    try std.testing.expectEqualStrings("TIMER-???", std.mem.span(Curl_trc_timer_name(-1)));

    try std.testing.expectEqual(CURLE_OK, Curl_trc_opt("all,-dns"));
    try std.testing.expectEqual(CURL_LOG_LVL_INFO, Curl_trc_feat_multi.log_level);
    try std.testing.expectEqual(CURL_LOG_LVL_NONE, Curl_trc_feat_dns.log_level);
    try std.testing.expectEqual(CURLE_OK, Curl_trc_opt("-all,+dns"));
    try std.testing.expectEqual(CURL_LOG_LVL_NONE, Curl_trc_feat_multi.log_level);
    try std.testing.expectEqual(CURL_LOG_LVL_INFO, Curl_trc_feat_dns.log_level);
    try std.testing.expectEqual(CURLE_OK, Curl_trc_opt("-all"));
}

test "Curl_failf, Curl_reset_fail, and Curl_infof with bound easy" {
    const DummyCapture = struct {
        var last_buf: [256]u8 = undefined;
        var last_len: usize = 0;
        var last_type: curl_infotype = CURLINFO_END;

        fn debugCb(_: ?*Curl_easy, itype: curl_infotype, ptr: [*]u8, size: usize, _: ?*anyopaque) callconv(.c) c_int {
            last_type = itype;
            last_len = @min(size, last_buf.len);
            @memcpy(last_buf[0..last_len], ptr[0..last_len]);
            return 0;
        }
    };

    var dummy_easy: [8]u64 = @splat(0);
    const data: *Curl_easy = @ptrCast(&dummy_easy);
    var easy_id: i64 = 7;
    var mstate: c_uint = 3;
    var conn_id: i64 = 11;
    var state_feat: ?*curl_trc_feat = null;
    var errbuf_storage: [CURL_ERROR_SIZE]u8 = @splat(0);
    var errbuf_ptr: ?[*]u8 = &errbuf_storage;
    var httpreq_bits: [4]u8 = .{ 0, 0, 0, 0 };
    var fdebug_ptr: ?curl_debug_callback = &DummyCapture.debugCb;
    var debugdata_ptr: ?*anyopaque = null;
    var err_stream: ?*anyopaque = null;

    _ = Curl_trc_bind_easy(
        data,
        &easy_id,
        &mstate,
        &conn_id,
        @ptrCast(&state_feat),
        @ptrCast(&errbuf_ptr),
        &httpreq_bits[0],
        true,
        @ptrCast(&fdebug_ptr),
        @ptrCast(&debugdata_ptr),
        @ptrCast(&err_stream),
    );

    Curl_failf(data, "error %d: %s", @as(c_int, 404), "not found");
    try std.testing.expectEqualStrings("error 404: not found", std.mem.sliceTo(&errbuf_storage, 0));
    try std.testing.expect((httpreq_bits[1] & 0x08) != 0);
    try std.testing.expectEqual(CURLINFO_TEXT, DummyCapture.last_type);
    try std.testing.expectEqualStrings("error 404: not found\n", DummyCapture.last_buf[0..DummyCapture.last_len]);

    // Second failf does not overwrite errorbuffer until Curl_reset_fail
    Curl_failf(data, "second error");
    try std.testing.expectEqualStrings("error 404: not found", std.mem.sliceTo(&errbuf_storage, 0));

    Curl_reset_fail(data);
    try std.testing.expectEqual(@as(u8, 0), errbuf_storage[0]);
    try std.testing.expect((httpreq_bits[1] & 0x08) == 0);

    Curl_infof(data, "hello %s", "trace");
    try std.testing.expectEqualStrings("hello trace\n", DummyCapture.last_buf[0..DummyCapture.last_len]);
}

test "Cookie engine init, add, getlist, list, clearsess, clearall, cleanup" {
    const ci = Curl_cookie_init() orelse return error.OutOfMemory;
    defer Curl_cookie_cleanup(ci);

    ci.setRunning(true);
    var setcookies: u8 = 0;

    // Add HTTP Set-Cookie headers with different paths
    try std.testing.expectEqual(
        CURLE_OK,
        Curl_cookie_add(
            null,
            ci,
            "sid=abc123; Domain=example.com; Path=/app; HttpOnly",
            "www.example.com",
            "/app/index.html",
            COOKIE_HTTPHEADER | COOKIE_SECURE,
            &setcookies,
        ),
    );
    try std.testing.expectEqual(
        CURLE_OK,
        Curl_cookie_add(
            null,
            ci,
            "sid=rootval; Domain=example.com; Path=/; Max-Age=3600",
            "www.example.com",
            "/",
            COOKIE_HTTPHEADER | COOKIE_SECURE,
            &setcookies,
        ),
    );
    try std.testing.expectEqual(
        CURLE_OK,
        Curl_cookie_add(
            null,
            ci,
            "sec=onlytls; Domain=example.com; Path=/app; Secure",
            "www.example.com",
            "/app/index.html",
            COOKIE_HTTPHEADER | COOKIE_SECURE,
            &setcookies,
        ),
    );
    try std.testing.expectEqual(@as(u8, 3), setcookies);
    try std.testing.expectEqual(@as(c_uint, 3), ci.numcookies);

    // Longest path (/app) must sort before shorter path (/), and Secure cookie
    // is excluded for non-secure context (data=null, host=www.example.com)
    var okay = false;
    var llist: containers.Curl_llist = undefined;
    try std.testing.expectEqual(
        CURLE_OK,
        Curl_cookie_getlist(null, ci, "/app/dashboard", &okay, "www.example.com", &llist),
    );
    try std.testing.expect(okay);
    try std.testing.expectEqual(@as(usize, 2), containers.Curl_llist_count(&llist));

    const first_node = containers.Curl_llist_head(&llist).?;
    const first_cookie: *Cookie = @ptrCast(@alignCast(containers.Curl_node_elem(first_node).?));
    try std.testing.expectEqualStrings("/app", std.mem.span(first_cookie.path.?));
    try std.testing.expectEqualStrings("abc123", std.mem.span(first_cookie.value.?));

    // Netscape cookie list export
    const slist = Curl_cookie_list(null, ci);
    try std.testing.expect(slist != null);
    curl_slist_free_all(slist);

    // Clear session cookies (sid=abc123 and sec=onlytls have no expires, sid=rootval has Max-Age)
    Curl_cookie_clearsess(ci);
    try std.testing.expectEqual(@as(c_uint, 1), ci.numcookies);

    Curl_cookie_clearall(ci);
    try std.testing.expectEqual(@as(c_uint, 0), ci.numcookies);
}

test "Pingpong init, needs_flush, moredata, and disconnect" {
    var pp: pingpong = std.mem.zeroes(pingpong);
    const now = curlx_time_net.Curltime{ .tv_sec = 100, .tv_usec = 500 };
    Curl_pp_init(&pp, &now);
    try std.testing.expect(pp.isInitialized());
    try std.testing.expect(pp.isPendingResp());
    try std.testing.expect(!Curl_pp_needs_flush(null, &pp));
    try std.testing.expect(!Curl_pp_moredata(&pp));

    try std.testing.expectEqual(CURLE_OK, containers.curlx_dyn_addn(&pp.recvbuf, "220 OK\r\n", 8));
    try std.testing.expect(Curl_pp_moredata(&pp));

    try std.testing.expectEqual(CURLE_OK, Curl_pp_disconnect(&pp));
    try std.testing.expect(!pp.isInitialized());
}

test "adversarial cookie parsing: oversized attributes, control bytes, max-age and domain/path edge cases" {
    const ci = Curl_cookie_init() orelse return error.OutOfMemory;
    defer Curl_cookie_cleanup(ci);

    ci.setRunning(true);
    var setcookies: u8 = 0;

    // Empty quoted Max-Age="", negative Max-Age, and extreme Max-Age overflow
    try std.testing.expectEqual(
        CURLE_OK,
        Curl_cookie_add(null, ci, "empty_ma=1; Max-Age=\"\"", "example.com", "/", COOKIE_HTTPHEADER | COOKIE_SECURE, &setcookies),
    );
    try std.testing.expectEqual(
        CURLE_OK,
        Curl_cookie_add(null, ci, "neg_ma=1; Max-Age=-999999", "example.com", "/", COOKIE_HTTPHEADER | COOKIE_SECURE, &setcookies),
    );
    try std.testing.expectEqual(
        CURLE_OK,
        Curl_cookie_add(null, ci, "huge_ma=1; Max-Age=999999999999999999999999999999", "example.com", "/", COOKIE_HTTPHEADER | COOKIE_SECURE, &setcookies),
    );

    // Control characters inside cookie name or value must be rejected
    try std.testing.expectEqual(
        CURLE_OK,
        Curl_cookie_add(null, ci, "bad\x01name=val", "example.com", "/", COOKIE_HTTPHEADER | COOKIE_SECURE, &setcookies),
    );
    try std.testing.expectEqual(
        CURLE_OK,
        Curl_cookie_add(null, ci, "badval=v\x07al", "example.com", "/", COOKIE_HTTPHEADER | COOKIE_SECURE, &setcookies),
    );

    // Cross-domain tailmatch mismatch and single-label TLD rejection
    try std.testing.expectEqual(
        CURLE_OK,
        Curl_cookie_add(null, ci, "evil=1; Domain=other.com", "example.com", "/", COOKIE_HTTPHEADER | COOKIE_SECURE, &setcookies),
    );
    try std.testing.expectEqual(
        CURLE_OK,
        Curl_cookie_add(null, ci, "tld=1; Domain=.com", "example.com", "/", COOKIE_HTTPHEADER | COOKIE_SECURE, &setcookies),
    );

    // Oversized cookie name (> MAX_NAME = 4096) must be rejected
    var big_line: [4200]u8 = @splat('a');
    big_line[4100] = '=';
    big_line[4101] = '1';
    big_line[4102] = 0;
    const big_cstr: [*:0]const u8 = @ptrCast(&big_line);
    try std.testing.expectEqual(
        CURLE_OK,
        Curl_cookie_add(null, ci, big_cstr, "example.com", "/", COOKIE_HTTPHEADER | COOKIE_SECURE, &setcookies),
    );

    // Only huge_ma should be returned as an active cookie (empty_ma and neg_ma expired at expires=1)
    var okay = false;
    var llist: containers.Curl_llist = undefined;
    try std.testing.expectEqual(
        CURLE_OK,
        Curl_cookie_getlist(null, ci, "/", &okay, "example.com", &llist),
    );
    try std.testing.expect(okay);
    try std.testing.expectEqual(@as(usize, 1), containers.Curl_llist_count(&llist));
    const node = containers.Curl_llist_head(&llist).?;
    const co: *Cookie = @ptrCast(@alignCast(containers.Curl_node_elem(node).?));
    try std.testing.expectEqualStrings("huge_ma", std.mem.span(co.name.?));
}
