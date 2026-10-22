const std = @import("std");
const builtin = @import("builtin");
const mem = @import("mem.zig");
const primitives = @import("primitives.zig");
const containers = @import("containers.zig");
const format_parse = @import("format_parse.zig");
const curlx_time_net = @import("curlx_time_net.zig");
const os_leaf = @import("os_leaf.zig");
const doh_hostip_easy = @import("doh_hostip_easy.zig");

const is_windows = builtin.os.tag == .windows;

pub const CURLcode = c_uint;
pub const CURLE_OK: CURLcode = 0;
pub const CURLE_FAILED_INIT: CURLcode = 2;
pub const CURLE_URL_MALFORMAT: CURLcode = 3;
pub const CURLE_WEIRD_SERVER_REPLY: CURLcode = 8;
pub const CURLE_PARTIAL_FILE: CURLcode = 18;
pub const CURLE_WRITE_ERROR: CURLcode = 23;
pub const CURLE_READ_ERROR: CURLcode = 26;
pub const CURLE_OUT_OF_MEMORY: CURLcode = 27;
pub const CURLE_OPERATION_TIMEDOUT: CURLcode = 28;
pub const CURLE_BAD_DOWNLOAD_RESUME: CURLcode = 36;
pub const CURLE_FILE_COULDNT_READ_FILE: CURLcode = 37;
pub const CURLE_BAD_FUNCTION_ARGUMENT: CURLcode = 43;
pub const CURLE_SEND_ERROR: CURLcode = 55;
pub const CURLE_RECV_ERROR: CURLcode = 56;
pub const CURLE_FILESIZE_EXCEEDED: CURLcode = 63;
pub const CURLE_AGAIN: CURLcode = 81;
pub const CURLE_TOO_LARGE: CURLcode = 100;

pub const curl_off_t = i64;
pub const timediff_t = curlx_time_net.timediff_t;
pub const TIMEDIFF_T_MAX = curlx_time_net.TIMEDIFF_T_MAX;
pub const time_t = curlx_time_net.time_t;
pub const curl_socket_t = curlx_time_net.curl_socket_t;
pub const Curltime = curlx_time_net.Curltime;

pub const FIRSTSOCKET: i8 = 0;
pub const CONNCTRL_CONN_CLOSE: c_int = 1;

pub const CLIENTWRITE_BODY: c_int = 1 << 0;
pub const CLIENTWRITE_HEADER: c_int = 1 << 2;

pub const CURLINFO_HEADER_IN: c_uint = 1;
pub const CURLINFO_HEADER_OUT: c_uint = 2;
pub const CURLINFO_DATA_OUT: c_uint = 4;

pub const CURL_POLL_IN: c_int = 1;
pub const CURL_POLL_OUT: c_int = 2;

pub const CURL_SOCKET_BAD: curl_socket_t = if (is_windows) std.math.maxInt(usize) else -1;
pub const SEEK_SET: c_int = 0;

const backend_options = @import("backend_options");

pub const LIBCURL_NAME = "libcurl";
pub const LIBCURL_VERSION: [:0]const u8 = backend_options.version ++ "";

pub const Curl_meta_dtor = *const fn (?*const anyopaque, usize, ?*anyopaque) callconv(.c) void;

pub const Curl_protocol = extern struct {
    setup_connection: ?*const fn (?*anyopaque, ?*anyopaque) callconv(.c) CURLcode,
    do_it: ?*const fn (?*anyopaque, *bool) callconv(.c) CURLcode,
    done: ?*const fn (?*anyopaque, CURLcode, bool) callconv(.c) CURLcode,
    do_more: ?*const fn (?*anyopaque, *c_int) callconv(.c) CURLcode,
    connect_it: ?*const fn (?*anyopaque, *bool) callconv(.c) CURLcode,
    connecting: ?*const fn (?*anyopaque, *bool) callconv(.c) CURLcode,
    doing: ?*const fn (?*anyopaque, *bool) callconv(.c) CURLcode,
    proto_pollset: ?*const fn (?*anyopaque, ?*anyopaque) callconv(.c) CURLcode,
    doing_pollset: ?*const fn (?*anyopaque, ?*anyopaque) callconv(.c) CURLcode,
    domore_pollset: ?*const fn (?*anyopaque, ?*anyopaque) callconv(.c) CURLcode,
    perform_pollset: ?*const fn (?*anyopaque, ?*anyopaque) callconv(.c) CURLcode,
    disconnect: ?*const fn (?*anyopaque, ?*anyopaque, bool) callconv(.c) CURLcode,
    write_resp: ?*const fn (?*anyopaque, [*]const u8, usize, bool) callconv(.c) CURLcode,
    write_resp_hd: ?*const fn (?*anyopaque, [*]const u8, usize, bool) callconv(.c) CURLcode,
    connection_is_dead: ?*const fn (?*anyopaque, ?*anyopaque) callconv(.c) bool,
    attach: ?*const fn (?*anyopaque, ?*anyopaque) callconv(.c) void,
    follow: ?*const fn (?*anyopaque, [*:0]const u8, c_uint) callconv(.c) CURLcode,
};

const Tm = extern struct {
    tm_sec: c_int,
    tm_min: c_int,
    tm_hour: c_int,
    tm_mday: c_int,
    tm_mon: c_int,
    tm_year: c_int,
    tm_wday: c_int,
    tm_yday: c_int,
    tm_isdst: c_int,
    _extra: [32]u8 = undefined,
};

extern const Curl_wkday: [7][*:0]const u8;
extern const Curl_month: [12][*:0]const u8;

extern fn Curl_urldecode(
    string: ?[*]const u8,
    length: usize,
    ostring: ?*?[*:0]u8,
    olen: ?*usize,
    ctrl: c_uint,
) callconv(.c) CURLcode;

extern fn curl_maprintf(format: [*:0]const u8, ...) callconv(.c) ?[*:0]u8;
extern fn curl_msnprintf(buffer: [*]u8, maxlength: usize, format: [*:0]const u8, ...) callconv(.c) c_int;

extern fn Curl_failf(data: ?*anyopaque, fmt: [*:0]const u8, ...) callconv(.c) void;
extern fn Curl_infof(data: ?*anyopaque, fmt: [*:0]const u8, ...) callconv(.c) void;
extern fn Curl_debug(data: ?*anyopaque, info_type: c_uint, ptr: [*]const u8, size: usize) callconv(.c) void;

extern fn Curl_conn_connect(data: ?*anyopaque, sockindex: i8, blocking: bool, done: *bool) callconv(.c) CURLcode;
extern fn Curl_conncontrol(conn: ?*anyopaque, ctrl: c_int) callconv(.c) void;
extern fn Curl_timeleft_ms(data: ?*anyopaque) callconv(.c) timediff_t;
extern fn Curl_socket_check(readfd0: curl_socket_t, readfd1: curl_socket_t, writefd: curl_socket_t, timeout_ms: timediff_t) callconv(.c) c_int;
extern fn Curl_pollset_change(data: ?*anyopaque, ps: ?*anyopaque, sock: curl_socket_t, add_flags: c_int, remove_flags: c_int) callconv(.c) CURLcode;

extern fn Curl_xfer_send(data: ?*anyopaque, buf: *const anyopaque, blen: usize, eos: bool, pnwritten: *usize) callconv(.c) CURLcode;
extern fn Curl_xfer_recv(data: ?*anyopaque, buf: [*]u8, blen: usize, pnrcvd: *usize) callconv(.c) CURLcode;
extern fn Curl_xfer_setup_recv(data: ?*anyopaque, sockindex: i8, recv_size: curl_off_t) callconv(.c) void;
extern fn Curl_meets_timecondition(data: ?*anyopaque, timeofdoc: time_t) callconv(.c) bool;

extern fn Curl_client_write(data: ?*anyopaque, wtype: c_int, buf: [*]const u8, len: usize) callconv(.c) CURLcode;
extern fn Curl_client_read(data: ?*anyopaque, buf: [*]u8, blen: usize, nread: *usize, eos: *bool) callconv(.c) CURLcode;

extern fn Curl_meta_set(data: ?*anyopaque, key: [*:0]const u8, meta_data: ?*anyopaque, meta_dtor: Curl_meta_dtor) callconv(.c) CURLcode;
extern fn Curl_meta_get(data: ?*anyopaque, key: [*:0]const u8) callconv(.c) ?*anyopaque;
extern fn Curl_conn_meta_set(conn: ?*anyopaque, key: [*:0]const u8, meta_data: ?*anyopaque, meta_dtor: Curl_meta_dtor) callconv(.c) CURLcode;
extern fn Curl_conn_meta_get(conn: ?*anyopaque, key: [*:0]const u8) callconv(.c) ?*anyopaque;

extern fn Curl_pgrs_now(data: ?*anyopaque) callconv(.c) *const Curltime;
extern fn Curl_pgrsSetDownloadSize(data: ?*anyopaque, size: curl_off_t) callconv(.c) void;
extern fn Curl_pgrsSetUploadSize(data: ?*anyopaque, size: curl_off_t) callconv(.c) void;
extern fn Curl_pgrs_upload_inc(data: ?*anyopaque, delta: usize) callconv(.c) void;
extern fn Curl_pgrsCheck(data: ?*anyopaque) callconv(.c) CURLcode;
extern fn Curl_pgrsUpdate(data: ?*anyopaque) callconv(.c) CURLcode;

extern fn Curl_multi_xfer_buf_borrow(data: ?*anyopaque, pbuf: *?[*]u8, pbuflen: *usize) callconv(.c) CURLcode;
extern fn Curl_multi_xfer_buf_release(data: ?*anyopaque, buf: ?[*]u8) callconv(.c) void;
extern fn Curl_multi_xfer_ulbuf_borrow(data: ?*anyopaque, pbuf: *?[*]u8, pbuflen: *usize) callconv(.c) CURLcode;
extern fn Curl_multi_xfer_ulbuf_release(data: ?*anyopaque, buf: ?[*]u8) callconv(.c) void;

extern fn Curl_proto_range(data: ?*anyopaque) callconv(.c) CURLcode;
extern fn Curl_rand_alnum(data: ?*anyopaque, rnd: [*]u8, num: usize) callconv(.c) CURLcode;
extern fn curlx_gmtime(intime: time_t, store: ?*anyopaque) callconv(.c) CURLcode;

extern fn Curl_proto_get_conn(data: ?*anyopaque) callconv(.c) ?*anyopaque;
extern fn Curl_proto_get_firstsocket(data: ?*anyopaque) callconv(.c) curl_socket_t;
extern fn Curl_proto_get_up_path(data: ?*anyopaque) callconv(.c) ?[*:0]const u8;
extern fn Curl_proto_get_up_query(data: ?*anyopaque) callconv(.c) ?[*:0]const u8;
extern fn Curl_proto_is_upload(data: ?*anyopaque) callconv(.c) bool;
extern fn Curl_proto_get_resume_from(data: ?*anyopaque) callconv(.c) curl_off_t;
extern fn Curl_proto_set_resume_from(data: ?*anyopaque, val: curl_off_t) callconv(.c) void;
extern fn Curl_proto_get_new_file_perms(data: ?*anyopaque) callconv(.c) u32;
extern fn Curl_proto_get_infilesize(data: ?*anyopaque) callconv(.c) curl_off_t;
extern fn Curl_proto_get_filetime(data: ?*anyopaque) callconv(.c) time_t;
extern fn Curl_proto_set_filetime(data: ?*anyopaque, val: time_t) callconv(.c) void;
extern fn Curl_proto_has_range(data: ?*anyopaque) callconv(.c) bool;
extern fn Curl_proto_has_timecondition(data: ?*anyopaque) callconv(.c) bool;
extern fn Curl_proto_is_no_body(data: ?*anyopaque) callconv(.c) bool;
extern fn Curl_proto_get_maxdownload(data: ?*anyopaque) callconv(.c) curl_off_t;
extern fn Curl_proto_get_creds(data: ?*anyopaque, user: *?[*:0]const u8, passwd: *?[*:0]const u8) callconv(.c) void;
extern fn Curl_proto_unlink_creds(data: ?*anyopaque) callconv(.c) void;
extern fn Curl_proto_get_postfields(data: ?*anyopaque) callconv(.c) ?[*:0]u8;
extern fn Curl_proto_get_postfieldsize(data: ?*anyopaque) callconv(.c) curl_off_t;
extern fn Curl_proto_get_max_filesize(data: ?*anyopaque) callconv(.c) curl_off_t;
extern fn Curl_proto_set_req_download(data: ?*anyopaque, size: curl_off_t) callconv(.c) void;
extern fn Curl_proto_get_upkeep_interval_ms(data: ?*anyopaque) callconv(.c) timediff_t;
extern fn Curl_proto_is_httpreq_post(data: ?*anyopaque) callconv(.c) bool;

fn strchrMut(s: [*:0]u8, c: u8) ?[*:0]u8 {
    var p = s;
    while (p[0] != 0) : (p += 1) {
        if (p[0] == c) return p;
    }
    return null;
}

fn strchrConst(s: [*:0]const u8, c: u8) ?[*:0]const u8 {
    var p = s;
    while (p[0] != 0) : (p += 1) {
        if (p[0] == c) return p;
    }
    return null;
}

// ============================================================================
// 1. lib/gopher.c — Gopher and Gophers protocol handlers
// ============================================================================

fn gopher_connect(data: ?*anyopaque, done: *bool) callconv(.c) CURLcode {
    _ = data;
    _ = done;
    return CURLE_OK;
}

fn gopher_connecting(data: ?*anyopaque, done: *bool) callconv(.c) CURLcode {
    const conn = Curl_proto_get_conn(data);
    const result = Curl_conn_connect(data, FIRSTSOCKET, true, done);
    if (result != CURLE_OK) {
        Curl_conncontrol(conn, CONNCTRL_CONN_CLOSE);
    }
    done.* = true;
    return result;
}

fn send_buf(
    data: ?*anyopaque,
    buf_in: [*]const u8,
    buf_len_in: usize,
    client_write: bool,
) CURLcode {
    var result: CURLcode = CURLE_OK;
    const sockfd = Curl_proto_get_firstsocket(data);
    var buf = buf_in;
    var buf_len = buf_len_in;

    while (buf_len != 0) {
        var nwritten: usize = 0;
        result = Curl_xfer_send(data, buf, buf_len, false, &nwritten);
        if (result == CURLE_OK) {
            if (client_write) {
                result = Curl_client_write(data, CLIENTWRITE_HEADER, buf, nwritten);
                if (result != CURLE_OK) break;
            }
            if (nwritten > buf_len) break;
            buf_len -= nwritten;
            buf += nwritten;
            if (buf_len == 0) break;
        } else {
            break;
        }

        var timeout_ms = Curl_timeleft_ms(data);
        if (timeout_ms < 0) {
            result = CURLE_OPERATION_TIMEDOUT;
            break;
        }
        if (timeout_ms == 0) {
            timeout_ms = TIMEDIFF_T_MAX;
        }

        const what = Curl_socket_check(CURL_SOCKET_BAD, CURL_SOCKET_BAD, sockfd, timeout_ms);
        if (what < 0) {
            result = CURLE_SEND_ERROR;
            break;
        } else if (what == 0) {
            result = CURLE_OPERATION_TIMEDOUT;
            break;
        }
    }

    return result;
}

fn gopherDecodeSelector(
    data: ?*anyopaque,
    gopherpath: [*:0]u8,
    buf_out: *[*]const u8,
    buf_len_out: *usize,
    out_rc: *CURLcode,
) error{SelectorInvalid}!?[*:0]u8 {
    if (std.mem.len(gopherpath) <= 2) {
        buf_out.* = "";
        buf_len_out.* = 0;
        return null;
    }

    var buf_alloc: ?[*:0]u8 = null;
    var buf_len: usize = 0;
    const newp: [*:0]const u8 = gopherpath + 2;
    const result = Curl_urldecode(newp, 0, &buf_alloc, &buf_len, format_parse.REJECT_ZERO);
    if (result != CURLE_OK) {
        out_rc.* = result;
        return error.SelectorInvalid;
    }
    const alloc_ptr = buf_alloc.?;
    errdefer mem.free(alloc_ptr);

    const slice = alloc_ptr[0..buf_len];
    if (std.mem.indexOfScalar(u8, slice, '\r') != null or
        std.mem.indexOfScalar(u8, slice, '\n') != null)
    {
        Curl_failf(data, "Bad gopher selector, CR or LF not allowed");
        out_rc.* = CURLE_URL_MALFORMAT;
        return error.SelectorInvalid;
    }

    buf_out.* = alloc_ptr;
    buf_len_out.* = buf_len;
    return alloc_ptr;
}

fn gopher_do(data: ?*anyopaque, done: *bool) callconv(.c) CURLcode {
    var result: CURLcode = CURLE_OK;
    const path = Curl_proto_get_up_path(data) orelse return CURLE_URL_MALFORMAT;
    const query = Curl_proto_get_up_query(data);
    var buf: [*]const u8 = "";
    var buf_len: usize = 0;

    done.* = true;

    const gopherpath_opt: ?[*:0]u8 = if (query) |q|
        curl_maprintf("%s?%s", path, q)
    else
        mem.strdup(path);

    const gopherpath = gopherpath_opt orelse return CURLE_OUT_OF_MEMORY;
    const buf_alloc = blk: {
        defer mem.free(gopherpath);
        break :blk gopherDecodeSelector(data, gopherpath, &buf, &buf_len, &result) catch return result;
    };
    defer mem.free(buf_alloc);

    result = send_buf(data, buf, buf_len, true);

    if (result == CURLE_OK) {
        result = send_buf(data, "\r\n", 2, false);
    }
    if (result != CURLE_OK) {
        Curl_failf(data, "Failed sending Gopher request");
        return result;
    }
    result = Curl_client_write(data, CLIENTWRITE_HEADER, "\r\n", 2);
    if (result != CURLE_OK) return result;

    Curl_xfer_setup_recv(data, FIRSTSOCKET, -1);
    return CURLE_OK;
}

pub export const Curl_protocol_gopher: Curl_protocol = .{
    .setup_connection = null,
    .do_it = gopher_do,
    .done = null,
    .do_more = null,
    .connect_it = null,
    .connecting = null,
    .doing = null,
    .proto_pollset = null,
    .doing_pollset = null,
    .domore_pollset = null,
    .perform_pollset = null,
    .disconnect = null,
    .write_resp = null,
    .write_resp_hd = null,
    .connection_is_dead = null,
    .attach = null,
    .follow = null,
};

pub export const Curl_protocol_gophers: Curl_protocol = .{
    .setup_connection = null,
    .do_it = gopher_do,
    .done = null,
    .do_more = null,
    .connect_it = gopher_connect,
    .connecting = gopher_connecting,
    .doing = null,
    .proto_pollset = null,
    .doing_pollset = null,
    .domore_pollset = null,
    .perform_pollset = null,
    .disconnect = null,
    .write_resp = null,
    .write_resp_hd = null,
    .connection_is_dead = null,
    .attach = null,
    .follow = null,
};

// ============================================================================
// 2. lib/dict.c — DICT protocol handler
// ============================================================================

const DICT_MATCH = "/MATCH:";
const DICT_MATCH2 = "/M:";
const DICT_MATCH3 = "/FIND:";
const DICT_DEFINE = "/DEFINE:";
const DICT_DEFINE2 = "/D:";
const DICT_DEFINE3 = "/LOOKUP:";
const DYN_DICT_WORD: usize = 10000;

fn unescapeWordInner(input: [*:0]const u8) error{OutOfMemory}!?[*:0]u8 {
    var out: containers.dynbuf = undefined;
    containers.curlx_dyn_init(&out, DYN_DICT_WORD);
    errdefer containers.curlx_dyn_free(&out);

    var ptr: [*:0]const u8 = input;
    while (ptr[0] != 0) : (ptr += 1) {
        const ch = ptr[0];
        if (ch <= 32 or ch == 127 or ch == '\'' or ch == '"' or ch == '\\') {
            if (containers.curlx_dyn_addn(&out, "\\", 1) != CURLE_OK) return error.OutOfMemory;
        }
        if (containers.curlx_dyn_addn(&out, ptr, 1) != CURLE_OK) return error.OutOfMemory;
    }
    return containers.curlx_dyn_ptr(&out);
}

pub fn unescape_word(input: [*:0]const u8) ?[*:0]u8 {
    return unescapeWordInner(input) catch null;
}

fn dict_send_str(data: ?*anyopaque, s_opt: ?[*:0]u8) CURLcode {
    const s = s_opt orelse return CURLE_OUT_OF_MEMORY;
    defer mem.free(s);

    const sockfd = Curl_proto_get_firstsocket(data);
    var write_len: usize = std.mem.len(s);
    var sptr: [*]const u8 = s;
    var result: CURLcode = CURLE_OK;

    while (true) {
        var bytes_written: usize = 0;
        result = Curl_xfer_send(data, sptr, write_len, false, &bytes_written);
        if (result != CURLE_OK) break;

        Curl_debug(data, CURLINFO_DATA_OUT, sptr, bytes_written);

        if (bytes_written != write_len) {
            write_len -= bytes_written;
            sptr += bytes_written;
        } else {
            break;
        }

        var timeout_ms = Curl_timeleft_ms(data);
        if (timeout_ms < 0) {
            result = CURLE_OPERATION_TIMEDOUT;
            break;
        }
        if (timeout_ms == 0) {
            timeout_ms = TIMEDIFF_T_MAX;
        }

        const what = Curl_socket_check(CURL_SOCKET_BAD, CURL_SOCKET_BAD, sockfd, timeout_ms);
        if (what < 0) {
            result = CURLE_SEND_ERROR;
            break;
        } else if (what == 0) {
            result = CURLE_OPERATION_TIMEDOUT;
            break;
        }
    }

    return result;
}

fn dict_do(data: ?*anyopaque, done: *bool) callconv(.c) CURLcode {
    done.* = true;

    const up_path = Curl_proto_get_up_path(data) orelse return CURLE_URL_MALFORMAT;
    var path_opt: ?[*:0]u8 = null;
    var result = Curl_urldecode(up_path, 0, &path_opt, null, format_parse.REJECT_CTRL);
    if (result != CURLE_OK) return result;
    const path = path_opt orelse return CURLE_OUT_OF_MEMORY;
    defer mem.free(path);

    var eword: ?[*:0]u8 = null;
    defer mem.free(eword);

    if (primitives.curl_strnequal(path, DICT_MATCH, DICT_MATCH.len) != 0 or
        primitives.curl_strnequal(path, DICT_MATCH2, DICT_MATCH2.len) != 0 or
        primitives.curl_strnequal(path, DICT_MATCH3, DICT_MATCH3.len) != 0)
    {
        var word = strchrMut(path, ':');
        var database: ?[*:0]u8 = null;
        var strategy: ?[*:0]u8 = null;
        if (word) |w| {
            word = w + 1;
            database = strchrMut(word.?, ':');
            if (database) |db| {
                db[0] = 0;
                database = db + 1;
                strategy = strchrMut(database.?, ':');
                if (strategy) |st| {
                    st[0] = 0;
                    strategy = st + 1;
                    if (strchrMut(strategy.?, ':')) |nthdef| {
                        nthdef[0] = 0;
                    }
                }
            }
        }

        if (word == null or word.?[0] == 0) {
            Curl_infof(data, "lookup word is missing");
        }
        const lookup_word: [*:0]const u8 = if (word == null or word.?[0] == 0) "default" else word.?;
        eword = unescape_word(lookup_word) orelse return CURLE_OUT_OF_MEMORY;

        const db_str: [*:0]const u8 = if (database == null or database.?[0] == 0) "!" else database.?;
        const strat_str: [*:0]const u8 = if (strategy == null or strategy.?[0] == 0) "." else strategy.?;

        const msg = curl_maprintf(
            "CLIENT " ++ LIBCURL_NAME ++ " " ++ LIBCURL_VERSION ++ "\r\n" ++
                "MATCH %s %s %s\r\nQUIT\r\n",
            db_str,
            strat_str,
            eword.?,
        );
        result = dict_send_str(data, msg);
        if (result != CURLE_OK) {
            Curl_failf(data, "Failed sending DICT request");
            return result;
        }
        Curl_xfer_setup_recv(data, FIRSTSOCKET, -1);
    } else if (primitives.curl_strnequal(path, DICT_DEFINE, DICT_DEFINE.len) != 0 or
        primitives.curl_strnequal(path, DICT_DEFINE2, DICT_DEFINE2.len) != 0 or
        primitives.curl_strnequal(path, DICT_DEFINE3, DICT_DEFINE3.len) != 0)
    {
        var word = strchrMut(path, ':');
        var database: ?[*:0]u8 = null;
        if (word) |w| {
            word = w + 1;
            database = strchrMut(word.?, ':');
            if (database) |db| {
                db[0] = 0;
                database = db + 1;
                if (strchrMut(database.?, ':')) |nthdef| {
                    nthdef[0] = 0;
                }
            }
        }

        if (word == null or word.?[0] == 0) {
            Curl_infof(data, "lookup word is missing");
        }
        const lookup_word: [*:0]const u8 = if (word == null or word.?[0] == 0) "default" else word.?;
        eword = unescape_word(lookup_word) orelse return CURLE_OUT_OF_MEMORY;

        const db_str: [*:0]const u8 = if (database == null or database.?[0] == 0) "!" else database.?;

        const msg = curl_maprintf(
            "CLIENT " ++ LIBCURL_NAME ++ " " ++ LIBCURL_VERSION ++ "\r\n" ++
                "DEFINE %s %s\r\nQUIT\r\n",
            db_str,
            eword.?,
        );
        result = dict_send_str(data, msg);
        if (result != CURLE_OK) {
            Curl_failf(data, "Failed sending DICT request");
            return result;
        }
        Curl_xfer_setup_recv(data, FIRSTSOCKET, -1);
    } else {
        if (strchrMut(path, '/')) |slash| {
            const ppath = slash + 1;
            var i: usize = 0;
            while (ppath[i] != 0) : (i += 1) {
                if (ppath[i] == ':') ppath[i] = ' ';
            }
            const msg = curl_maprintf(
                "CLIENT " ++ LIBCURL_NAME ++ " " ++ LIBCURL_VERSION ++ "\r\n" ++
                    "%s\r\nQUIT\r\n",
                ppath,
            );
            result = dict_send_str(data, msg);
            if (result != CURLE_OK) {
                Curl_failf(data, "Failed sending DICT request");
                return result;
            }
            Curl_xfer_setup_recv(data, FIRSTSOCKET, -1);
        }
    }

    return result;
}

pub export const Curl_protocol_dict: Curl_protocol = .{
    .setup_connection = null,
    .do_it = dict_do,
    .done = null,
    .do_more = null,
    .connect_it = null,
    .connecting = null,
    .doing = null,
    .proto_pollset = null,
    .doing_pollset = null,
    .domore_pollset = null,
    .perform_pollset = null,
    .disconnect = null,
    .write_resp = null,
    .write_resp_hd = null,
    .connection_is_dead = null,
    .attach = null,
    .follow = null,
};

// ============================================================================
// 3. lib/file.c — FILE protocol handler
// ============================================================================

const CURL_META_FILE_EASY = "meta:proto:file:easy";
const DIRSEP: u8 = if (is_windows) '\\' else '/';

const FILEPROTO = extern struct {
    path: ?[*:0]u8,
    freepath: ?[*:0]u8,
    fd: c_int,
    is_dir: bool,
};

const FileStat = struct {
    is_dir: bool,
    size: curl_off_t,
    mtime: time_t,
};

const win_c = struct {
    const O_RDONLY: c_int = 0x0000;
    const O_WRONLY: c_int = 0x0001;
    const O_APPEND: c_int = 0x0008;
    const O_CREAT: c_int = 0x0100;
    const O_TRUNC: c_int = 0x0200;
    const O_BINARY: c_int = 0x8000;
    const S_IWRITE: u32 = 0x0080;
    const S_IREAD: u32 = 0x0100;
    const ERROR_NO_MORE_FILES: u32 = 18;

    const Win32Stati64 = extern struct {
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

    const FILETIME = extern struct {
        dwLowDateTime: u32,
        dwHighDateTime: u32,
    };

    const WIN32_FIND_DATAA = extern struct {
        dwFileAttributes: u32,
        ftCreationTime: FILETIME,
        ftLastAccessTime: FILETIME,
        ftLastWriteTime: FILETIME,
        nFileSizeHigh: u32,
        nFileSizeLow: u32,
        dwReserved0: u32,
        dwReserved1: u32,
        cFileName: [260]u8,
        cAlternateFileName: [14]u8,
    };

    extern "c" fn _close(fd: c_int) c_int;
    extern "c" fn _read(fd: c_int, buffer: [*]u8, count: c_uint) c_int;
    extern "c" fn _write(fd: c_int, buffer: [*]const u8, count: c_uint) c_int;
    extern "c" fn _lseeki64(fd: c_int, offset: i64, origin: c_int) i64;
    extern "c" fn _fstati64(fd: c_int, buffer: *Win32Stati64) c_int;

    extern "kernel32" fn FindNextFileA(hFindFile: *anyopaque, lpFindFileData: *WIN32_FIND_DATAA) callconv(.winapi) c_int;
    extern "kernel32" fn FindClose(hFindFile: *anyopaque) callconv(.winapi) c_int;
    extern "kernel32" fn GetLastError() callconv(.winapi) u32;
};

const posix_c = struct {
    const Dirent = if (builtin.os.tag.isDarwin())
        extern struct {
            d_ino: u64,
            d_seekoff: u64,
            d_reclen: u16,
            d_namlen: u16,
            d_type: u8,
            d_name: [1024]u8,
        }
    else
        extern struct {
            d_ino: u64,
            d_off: i64,
            d_reclen: u16,
            d_type: u8,
            d_name: [256]u8,
        };

    extern "c" fn open(path: [*:0]const u8, oflag: c_int, ...) c_int;
    extern "c" fn close(fd: c_int) c_int;
    extern "c" fn read(fd: c_int, buf: [*]u8, count: usize) isize;
    extern "c" fn write(fd: c_int, buf: [*]const u8, count: usize) isize;
    extern "c" fn lseek(fd: c_int, offset: i64, whence: c_int) i64;
    extern "c" fn opendir(name: [*:0]const u8) ?*anyopaque;
    extern "c" fn readdir(dirp: *anyopaque) ?*Dirent;
    extern "c" fn closedir(dirp: *anyopaque) c_int;
};

fn fileClose(fd: c_int) c_int {
    if (comptime is_windows) {
        return win_c._close(fd);
    } else {
        return posix_c.close(fd);
    }
}

fn fileRead(fd: c_int, buf: [*]u8, count: usize) isize {
    if (comptime is_windows) {
        const capped: c_uint = @intCast(@min(count, @as(usize, std.math.maxInt(c_int))));
        return @intCast(win_c._read(fd, buf, capped));
    } else {
        return posix_c.read(fd, buf, count);
    }
}

fn fileWrite(fd: c_int, buf: [*]const u8, count: usize) isize {
    if (comptime is_windows) {
        const capped: c_uint = @intCast(@min(count, @as(usize, std.math.maxInt(c_int))));
        return @intCast(win_c._write(fd, buf, capped));
    } else {
        return posix_c.write(fd, buf, count);
    }
}

fn fileLseek(fd: c_int, offset: curl_off_t, whence: c_int) curl_off_t {
    if (comptime is_windows) {
        return win_c._lseeki64(fd, offset, whence);
    } else {
        return posix_c.lseek(fd, offset, whence);
    }
}

fn fileStat(path: [*:0]const u8, out: *FileStat) bool {
    if (comptime is_windows) {
        var sbuf: win_c.Win32Stati64 = undefined;
        var rc = os_leaf.win32.curlx_win32_stat(path, &sbuf);
        if (rc != 0) {
            var pathlen = std.mem.len(path);
            if (pathlen > 3 and (path[pathlen - 1] == '\\' or path[pathlen - 1] == '/')) {
                if (mem.strdup(path)) |trimmed| {
                    defer mem.free(trimmed);
                    while (true) {
                        pathlen -= 1;
                        trimmed[pathlen] = 0;
                        if (!(pathlen > 3 and (trimmed[pathlen - 1] == '\\' or trimmed[pathlen - 1] == '/'))) break;
                    }
                    rc = os_leaf.win32.curlx_win32_stat(trimmed, &sbuf);
                }
            }
        }
        if (rc != 0) return false;
        out.* = .{
            .is_dir = (sbuf.st_mode & 0xf000) == 0x4000,
            .size = sbuf.st_size,
            .mtime = sbuf.st_mtime,
        };
        return true;
    } else if (comptime builtin.os.tag == .linux) {
        var stx: std.os.linux.Statx = std.mem.zeroes(std.os.linux.Statx);
        const rc = std.os.linux.statx(
            std.os.linux.AT.FDCWD,
            path,
            0,
            std.os.linux.STATX.BASIC_STATS,
            &stx,
        );
        if (std.os.linux.errno(rc) != .SUCCESS) return false;
        out.* = .{
            .is_dir = (stx.mode & std.os.linux.S.IFMT) == std.os.linux.S.IFDIR,
            .size = @intCast(stx.size),
            .mtime = stx.mtime.sec,
        };
        return true;
    } else {
        var st: std.c.Stat = std.mem.zeroes(std.c.Stat);
        if (std.c.stat(path, &st) != 0) return false;
        out.* = .{
            .is_dir = (st.mode & std.c.S.IFMT) == std.c.S.IFDIR,
            .size = @intCast(st.size),
            .mtime = st.mtime().sec,
        };
        return true;
    }
}

fn fileFstat(fd: c_int, out: *FileStat) bool {
    if (fd < 0) return false;
    if (comptime is_windows) {
        var sbuf: win_c.Win32Stati64 = undefined;
        if (win_c._fstati64(fd, &sbuf) != 0) return false;
        out.* = .{
            .is_dir = (sbuf.st_mode & 0xf000) == 0x4000,
            .size = sbuf.st_size,
            .mtime = sbuf.st_mtime,
        };
        return true;
    } else if (comptime builtin.os.tag == .linux) {
        var stx: std.os.linux.Statx = std.mem.zeroes(std.os.linux.Statx);
        const rc = std.os.linux.statx(
            fd,
            "",
            std.os.linux.AT.EMPTY_PATH,
            std.os.linux.STATX.BASIC_STATS,
            &stx,
        );
        if (std.os.linux.errno(rc) != .SUCCESS) return false;
        out.* = .{
            .is_dir = (stx.mode & std.os.linux.S.IFMT) == std.os.linux.S.IFDIR,
            .size = @intCast(stx.size),
            .mtime = stx.mtime.sec,
        };
        return true;
    } else {
        var st: std.c.Stat = std.mem.zeroes(std.c.Stat);
        if (std.c.fstat(fd, &st) != 0) return false;
        out.* = .{
            .is_dir = (st.mode & std.c.S.IFMT) == std.c.S.IFDIR,
            .size = @intCast(st.size),
            .mtime = st.mtime().sec,
        };
        return true;
    }
}

inline fn fileEasy(data: ?*anyopaque) ?*FILEPROTO {
    return doh_hostip_easy.metaGetTyped(FILEPROTO, data, CURL_META_FILE_EASY);
}

fn file_cleanup(file: *FILEPROTO) void {
    if (file.freepath) |fp| {
        mem.free(fp);
        file.freepath = null;
    }
    file.path = null;
    file.is_dir = false;
    if (file.fd != -1) {
        _ = fileClose(file.fd);
        file.fd = -1;
    }
}

fn file_easy_dtor(key: ?*const anyopaque, klen: usize, entry: ?*anyopaque) callconv(.c) void {
    _ = key;
    _ = klen;
    const file: *FILEPROTO = @ptrCast(@alignCast(entry orelse return));
    file_cleanup(file);
    mem.freeTyped(file);
}

fn file_setup_connection(data: ?*anyopaque, conn: ?*anyopaque) callconv(.c) CURLcode {
    _ = conn;
    const filep = mem.create(FILEPROTO) orelse return CURLE_OUT_OF_MEMORY;
    filep.fd = -1;
    if (Curl_meta_set(data, CURL_META_FILE_EASY, filep, file_easy_dtor) != CURLE_OK) {
        return CURLE_OUT_OF_MEMORY;
    }
    return CURLE_OK;
}

fn file_done(data: ?*anyopaque, status: CURLcode, premature: bool) callconv(.c) CURLcode {
    _ = status;
    _ = premature;
    if (fileEasy(data)) |file| {
        file_cleanup(file);
    }
    return CURLE_OK;
}

fn fileDecodePath(up_path: [*:0]const u8, file: *FILEPROTO, out_rc: *CURLcode) error{PathDecodeFailed}!c_int {
    var real_path_opt: ?[*:0]u8 = null;
    var real_path_len: usize = 0;
    const result = Curl_urldecode(up_path, 0, &real_path_opt, &real_path_len, format_parse.REJECT_ZERO);
    if (result != CURLE_OK) {
        out_rc.* = result;
        return error.PathDecodeFailed;
    }
    const real_path = real_path_opt orelse {
        out_rc.* = CURLE_OUT_OF_MEMORY;
        return error.PathDecodeFailed;
    };
    errdefer mem.free(real_path);

    var fd: c_int = -1;
    if (comptime is_windows) {
        var actual_path: [*:0]u8 = real_path;
        if (actual_path[0] == '/' and actual_path[1] != 0 and
            (actual_path[2] == ':' or actual_path[2] == '|'))
        {
            actual_path[2] = ':';
            actual_path += 1;
            real_path_len -= 1;
        }

        var i: usize = 0;
        while (i < real_path_len) : (i += 1) {
            if (actual_path[i] == '/') {
                actual_path[i] = '\\';
            } else if (actual_path[i] == 0) {
                out_rc.* = CURLE_URL_MALFORMAT;
                return error.PathDecodeFailed;
            }
        }

        fd = os_leaf.win32.curlx_win32_open(actual_path, win_c.O_RDONLY | win_c.O_BINARY, 0);
        file.path = actual_path;
    } else {
        if (std.mem.indexOfScalar(u8, real_path[0..real_path_len], 0) != null) {
            out_rc.* = CURLE_URL_MALFORMAT;
            return error.PathDecodeFailed;
        }
        const o_rdonly: c_int = @bitCast(std.c.O{ .ACCMODE = .RDONLY });
        fd = posix_c.open(real_path, o_rdonly);
        file.path = real_path;
    }

    mem.free(file.freepath);
    file.freepath = real_path;
    file.fd = fd;
    return fd;
}

fn file_connect(data: ?*anyopaque, done: *bool) callconv(.c) CURLcode {
    const file = fileEasy(data) orelse return CURLE_FAILED_INIT;

    if (file.path != null) {
        done.* = true;
        return CURLE_OK;
    }

    const up_path = Curl_proto_get_up_path(data) orelse return CURLE_URL_MALFORMAT;
    var decode_rc: CURLcode = CURLE_OK;
    const fd = fileDecodePath(up_path, file, &decode_rc) catch return decode_rc;

    const is_upload = Curl_proto_is_upload(data);
    if (comptime is_windows) {
        var statbuf: FileStat = undefined;
        if (!is_upload and fd == -1 and fileStat(file.path.?, &statbuf) and statbuf.is_dir) {
            file.is_dir = true;
        }
    }

    if (!is_upload and fd == -1 and !file.is_dir) {
        Curl_failf(data, "Could not open file %s", up_path);
        _ = file_done(data, CURLE_FILE_COULDNT_READ_FILE, false);
        return CURLE_FILE_COULDNT_READ_FILE;
    }
    done.* = true;
    return CURLE_OK;
}

fn file_disconnect(data: ?*anyopaque, conn: ?*anyopaque, dead_connection: bool) callconv(.c) CURLcode {
    _ = dead_connection;
    _ = conn;
    return file_done(data, CURLE_OK, false);
}

fn file_upload(data: ?*anyopaque, file: *FILEPROTO) CURLcode {
    const path = file.path orelse return CURLE_FILE_COULDNT_READ_FILE;
    const dir = strchrConst(path, DIRSEP) orelse return CURLE_FILE_COULDNT_READ_FILE;
    if (dir[1] == 0) return CURLE_FILE_COULDNT_READ_FILE;

    var resume_from = Curl_proto_get_resume_from(data);
    const perms = Curl_proto_get_new_file_perms(data);

    const fd: c_int = if (comptime is_windows) blk: {
        var mode: c_int = win_c.O_WRONLY | win_c.O_CREAT | win_c.O_BINARY;
        if (resume_from != 0) mode |= win_c.O_APPEND else mode |= win_c.O_TRUNC;
        const pmode: c_int = @intCast(perms & (win_c.S_IREAD | win_c.S_IWRITE));
        break :blk os_leaf.win32.curlx_win32_open(path, mode, pmode);
    } else blk: {
        const o_wronly: c_int = @bitCast(std.c.O{ .ACCMODE = .WRONLY });
        const o_creat: c_int = @bitCast(std.c.O{ .CREAT = true });
        const o_append: c_int = @bitCast(std.c.O{ .APPEND = true });
        const o_trunc: c_int = @bitCast(std.c.O{ .TRUNC = true });
        const mode: c_int = o_wronly | o_creat | (if (resume_from != 0) o_append else o_trunc);
        break :blk posix_c.open(path, mode, @as(c_uint, perms));
    };

    if (fd < 0) {
        Curl_failf(data, "cannot open %s for writing", path);
        return CURLE_WRITE_ERROR;
    }

    const infilesize = Curl_proto_get_infilesize(data);
    if (infilesize != -1) {
        Curl_pgrsSetUploadSize(data, infilesize);
    }

    if (resume_from < 0) {
        var fstat_info: FileStat = undefined;
        if (!fileFstat(fd, &fstat_info)) {
            _ = fileClose(fd);
            Curl_failf(data, "cannot get the size of %s", path);
            return CURLE_WRITE_ERROR;
        }
        resume_from = fstat_info.size;
        Curl_proto_set_resume_from(data, resume_from);
    }

    var result: CURLcode = CURLE_OK;
    var xfer_ulbuf: ?[*]u8 = null;
    var xfer_ulblen: usize = 0;
    var eos: bool = false;

    result = Curl_multi_xfer_ulbuf_borrow(data, &xfer_ulbuf, &xfer_ulblen);
    if (result == CURLE_OK) {
        const ulbuf = xfer_ulbuf.?;
        while (result == CURLE_OK and !eos) {
            var readcount: usize = 0;
            result = Curl_client_read(data, ulbuf, xfer_ulblen, &readcount, &eos);
            if (result != CURLE_OK) break;
            if (readcount == 0) break;

            var nread: usize = readcount;
            var sendbuf: [*]const u8 = ulbuf;

            resume_from = Curl_proto_get_resume_from(data);
            if (resume_from != 0) {
                if (@as(curl_off_t, @intCast(nread)) <= resume_from) {
                    resume_from -= @as(curl_off_t, @intCast(nread));
                    Curl_proto_set_resume_from(data, resume_from);
                    nread = 0;
                    sendbuf = ulbuf;
                } else {
                    const skip: usize = @intCast(resume_from);
                    sendbuf = ulbuf + skip;
                    nread -= skip;
                    resume_from = 0;
                    Curl_proto_set_resume_from(data, 0);
                }
            }

            var nwritten: usize = 0;
            const rv = fileWrite(fd, sendbuf, nread);
            if (!primitives.curlx_sztouz(rv, &nwritten) or nwritten != nread) {
                result = CURLE_SEND_ERROR;
                break;
            }
            Curl_pgrs_upload_inc(data, nwritten);
            result = Curl_pgrsCheck(data);
        }
        if (result == CURLE_OK) {
            result = Curl_pgrsUpdate(data);
        }
    }

    _ = fileClose(fd);
    Curl_multi_xfer_ulbuf_release(data, xfer_ulbuf);
    return result;
}

fn win32_file_list(data: ?*anyopaque, path: [*:0]const u8) CURLcode {
    var entry: win_c.WIN32_FIND_DATAA = undefined;
    const pathlen = std.mem.len(path);
    var result: CURLcode = CURLE_OK;

    const sep: [*:0]const u8 = if (pathlen > 0 and (path[pathlen - 1] == '\\' or path[pathlen - 1] == '/')) "" else "\\";
    const pattern = curl_maprintf("%s%s*", path, sep) orelse return CURLE_OUT_OF_MEMORY;
    const handle = os_leaf.win32.curlx_FindFirstFile(pattern, &entry);
    mem.free(pattern);
    if (handle == null or @intFromPtr(handle.?) == std.math.maxInt(usize)) {
        return CURLE_READ_ERROR;
    }

    while (true) {
        if (entry.cFileName[0] != '.') {
            const c_fname = std.mem.sliceTo(&entry.cFileName, 0);
            const name = mem.memdup0(c_fname.ptr, c_fname.len) orelse {
                result = CURLE_OUT_OF_MEMORY;
                break;
            };
            result = Curl_client_write(data, CLIENTWRITE_BODY, name, c_fname.len);
            mem.free(name);
            if (result != CURLE_OK) break;

            result = Curl_client_write(data, CLIENTWRITE_BODY, "\n", 1);
            if (result != CURLE_OK) break;
        }
        if (win_c.FindNextFileA(handle.?, &entry) == 0) break;
    }

    const err = win_c.GetLastError();
    if (result == CURLE_OK and err != win_c.ERROR_NO_MORE_FILES) {
        result = CURLE_READ_ERROR;
    }

    _ = win_c.FindClose(handle.?);
    return result;
}

fn file_do(data: ?*anyopaque, done: *bool) callconv(.c) CURLcode {
    var result: CURLcode = CURLE_OK;
    var statbuf: FileStat = undefined;
    var expected_size: curl_off_t = -1;
    var size_known: bool = false;
    var fstated: bool = false;
    var xfer_buf: ?[*]u8 = null;
    var xfer_blen: usize = 0;

    done.* = true;
    const file = fileEasy(data) orelse return CURLE_FAILED_INIT;

    if (Curl_proto_is_upload(data)) {
        return file_upload(data, file);
    }

    const fd = file.fd;

    const stat_ok = if (file.is_dir)
        fileStat(file.path.?, &statbuf)
    else
        fileFstat(fd, &statbuf);

    if (stat_ok) {
        file.is_dir = (fd == -1) or statbuf.is_dir;
        if (!file.is_dir) {
            expected_size = statbuf.size;
        }
        Curl_proto_set_filetime(data, statbuf.mtime);
        fstated = true;
    }

    if (fstated and !Curl_proto_has_range(data) and Curl_proto_has_timecondition(data) and
        !Curl_meets_timecondition(data, Curl_proto_get_filetime(data)))
    {
        return CURLE_OK;
    }

    if (fstated) {
        var buffer: Tm = std.mem.zeroes(Tm);
        var header: [80]u8 = undefined;
        var headerlen: c_int = 0;
        const accept_ranges = "Accept-ranges: bytes\r\n";
        if (expected_size >= 0) {
            headerlen = curl_msnprintf(&header, header.len, "Content-Length: %lld\r\n", @as(c_longlong, expected_size));
            result = Curl_client_write(data, CLIENTWRITE_HEADER, &header, @intCast(headerlen));
            if (result != CURLE_OK) return result;

            result = Curl_client_write(data, CLIENTWRITE_HEADER, accept_ranges, accept_ranges.len);
            if (result != CURLE_OK) return result;
        }

        const filetime: time_t = statbuf.mtime;
        result = curlx_gmtime(filetime, &buffer);
        if (result != CURLE_OK) return result;

        const wday_idx: usize = if (buffer.tm_wday != 0) @intCast(buffer.tm_wday - 1) else 6;
        const mon_idx: usize = @intCast(buffer.tm_mon);
        headerlen = curl_msnprintf(
            &header,
            header.len,
            "Last-Modified: %s, %02d %s %4d %02d:%02d:%02d GMT\r\n",
            Curl_wkday[wday_idx],
            buffer.tm_mday,
            Curl_month[mon_idx],
            buffer.tm_year + 1900,
            buffer.tm_hour,
            buffer.tm_min,
            buffer.tm_sec,
        );
        result = Curl_client_write(data, CLIENTWRITE_HEADER, &header, @intCast(headerlen));
        if (result == CURLE_OK) {
            result = Curl_client_write(data, CLIENTWRITE_HEADER, "\r\n", 2);
        }
        if (result != CURLE_OK) return result;

        Curl_pgrsSetDownloadSize(data, expected_size);
        if (Curl_proto_is_no_body(data)) return CURLE_OK;
    }

    result = Curl_proto_range(data);
    if (result != CURLE_OK) return result;

    var resume_from = Curl_proto_get_resume_from(data);
    if (resume_from < 0) {
        if (!fstated) {
            Curl_failf(data, "cannot get the size of file.");
            return CURLE_READ_ERROR;
        }
        resume_from += statbuf.size;
        Curl_proto_set_resume_from(data, resume_from);
    }

    if (resume_from > 0) {
        if (resume_from <= expected_size) {
            expected_size -= resume_from;
        } else {
            Curl_failf(data, "failed to resume file:// transfer");
            return CURLE_BAD_DOWNLOAD_RESUME;
        }
    }

    const maxdownload = Curl_proto_get_maxdownload(data);
    if (maxdownload > 0) {
        expected_size = maxdownload;
    }

    if (!fstated or expected_size <= 0) {
        size_known = false;
    } else {
        size_known = true;
    }

    if (size_known) {
        Curl_pgrsSetDownloadSize(data, expected_size);
    }

    resume_from = Curl_proto_get_resume_from(data);
    if (resume_from != 0) {
        if (!file.is_dir) {
            if (resume_from != fileLseek(fd, resume_from, SEEK_SET)) {
                return CURLE_BAD_DOWNLOAD_RESUME;
            }
        } else {
            return CURLE_BAD_DOWNLOAD_RESUME;
        }
    }

    result = Curl_multi_xfer_buf_borrow(data, &xfer_buf, &xfer_blen);
    if (result != CURLE_OK) {
        Curl_multi_xfer_buf_release(data, xfer_buf);
        return result;
    }
    defer Curl_multi_xfer_buf_release(data, xfer_buf);
    const buf = xfer_buf.?;

    if (!file.is_dir) {
        while (result == CURLE_OK) {
            const bytestoread: usize = if (size_known)
                if (expected_size < @as(curl_off_t, @intCast(xfer_blen - 1)))
                    primitives.curlx_sotouz(expected_size)
                else
                    (xfer_blen - 1)
            else
                (xfer_blen - 1);

            const nread = fileRead(fd, buf, bytestoread);
            if (nread > 0) {
                buf[@intCast(nread)] = 0;
            }
            if (nread <= 0 or (size_known and expected_size == 0)) {
                break;
            }

            const nread_uz: usize = @intCast(nread);
            if (size_known) {
                expected_size -= @as(curl_off_t, @intCast(nread_uz));
            }

            result = Curl_client_write(data, CLIENTWRITE_BODY, buf, nread_uz);
            if (result != CURLE_OK) return result;

            result = Curl_pgrsCheck(data);
            if (result != CURLE_OK) return result;
        }
    } else {
        if (comptime is_windows) {
            result = win32_file_list(data, file.path.?);
            if (result != CURLE_OK) return result;
        } else {
            const dir = posix_c.opendir(file.path.?) orelse return CURLE_READ_ERROR;
            defer _ = posix_c.closedir(dir);
            while (posix_c.readdir(dir)) |entry| {
                const d_name = std.mem.sliceTo(&entry.d_name, 0);
                if (d_name.len > 0 and d_name[0] != '.') {
                    result = Curl_client_write(data, CLIENTWRITE_BODY, d_name.ptr, d_name.len);
                    if (result != CURLE_OK) break;
                    result = Curl_client_write(data, CLIENTWRITE_BODY, "\n", 1);
                    if (result != CURLE_OK) break;
                }
            }
        }
    }

    if (result == CURLE_OK) {
        result = Curl_pgrsUpdate(data);
    }

    return result;
}

pub export const Curl_protocol_file: Curl_protocol = .{
    .setup_connection = file_setup_connection,
    .do_it = file_do,
    .done = file_done,
    .do_more = null,
    .connect_it = file_connect,
    .connecting = null,
    .doing = null,
    .proto_pollset = null,
    .doing_pollset = null,
    .domore_pollset = null,
    .perform_pollset = null,
    .disconnect = file_disconnect,
    .write_resp = null,
    .write_resp_hd = null,
    .connection_is_dead = null,
    .attach = null,
    .follow = null,
};

// ============================================================================
// 4. lib/mqtt.c — MQTT and MQTTS protocol handlers
// ============================================================================

pub const MQTT_MSG_CONNECT: u8 = 0x10;
pub const MQTT_MSG_PUBLISH: u8 = 0x30;
pub const MQTT_MSG_SUBSCRIBE: u8 = 0x82;
pub const MQTT_MSG_SUBACK: u8 = 0x90;
pub const MQTT_MSG_DISCONNECT: u8 = 0xe0;
pub const MQTT_MSG_PINGRESP: u8 = 0xd0;

pub const MQTT_CONNACK_LEN: usize = 2;
pub const MQTT_SUBACK_LEN: usize = 3;
pub const MQTT_CLIENTID_LEN: usize = 12;

const DYN_MQTT_RECV: usize = 64 * 1024;
const DYN_MQTT_SEND: usize = 0xFFFFFFF;
const MAX_MQTT_MESSAGE_SIZE: usize = 0xFFFFFFF;

const CURL_META_MQTT_EASY = "meta:proto:mqtt:easy";
const CURL_META_MQTT_CONN = "meta:proto:mqtt:conn";

pub const mqttstate = enum(c_uint) {
    MQTT_FIRST = 0,
    MQTT_REMAINING_LENGTH = 1,
    MQTT_CONNACK = 2,
    MQTT_SUBACK = 3,
    MQTT_SUBACK_COMING = 4,
    MQTT_PUBWAIT = 5,
    MQTT_PUB_REMAIN = 6,
    MQTT_POST_DRAIN = 7,
    MQTT_DISCONNECT_DRAIN = 8,
    MQTT_NOSTATE = 9,
};

const mqtt_conn = extern struct {
    state: mqttstate,
    nextstate: mqttstate,
    packetid: c_uint,
};

const MQTT = extern struct {
    sendbuf: containers.dynbuf,
    recvbuf: containers.dynbuf,
    npacket: usize,
    remaining_length: usize,
    pkt_hd: [4]u8,
    lastTime: Curltime,
    firstbyte: u8,
    pingsent: bool,
};

inline fn mqttEasy(data: ?*anyopaque) ?*MQTT {
    return doh_hostip_easy.metaGetTyped(MQTT, data, CURL_META_MQTT_EASY);
}

inline fn mqttConn(conn: ?*anyopaque) ?*mqtt_conn {
    return doh_hostip_easy.connMetaGetTyped(mqtt_conn, conn, CURL_META_MQTT_CONN);
}

fn mqtt_easy_dtor(key: ?*const anyopaque, klen: usize, entry: ?*anyopaque) callconv(.c) void {
    _ = key;
    _ = klen;
    const mq: *MQTT = @ptrCast(@alignCast(entry orelse return));
    containers.curlx_dyn_free(&mq.sendbuf);
    containers.curlx_dyn_free(&mq.recvbuf);
    mem.freeTyped(mq);
}

fn mqtt_setup_conn(data: ?*anyopaque, conn: ?*anyopaque) callconv(.c) CURLcode {
    const mqc = mem.create(mqtt_conn) orelse return CURLE_OUT_OF_MEMORY;
    if (doh_hostip_easy.connMetaSetTyped(mqtt_conn, conn, CURL_META_MQTT_CONN, mqc) != CURLE_OK) {
        return CURLE_OUT_OF_MEMORY;
    }

    const mq = mem.create(MQTT) orelse return CURLE_OUT_OF_MEMORY;
    containers.curlx_dyn_init(&mq.recvbuf, DYN_MQTT_RECV);
    containers.curlx_dyn_init(&mq.sendbuf, DYN_MQTT_SEND);
    if (Curl_meta_set(data, CURL_META_MQTT_EASY, mq, mqtt_easy_dtor) != CURLE_OK) {
        return CURLE_OUT_OF_MEMORY;
    }
    return CURLE_OK;
}

fn mqtt_send(data: ?*anyopaque, buf: [*]const u8, len: usize) CURLcode {
    var n: usize = 0;
    const mq = mqttEasy(data) orelse return CURLE_FAILED_INIT;

    var result = Curl_xfer_send(data, buf, len, false, &n);
    if (result != CURLE_OK) return result;
    mq.lastTime = Curl_pgrs_now(data).*;
    Curl_debug(data, CURLINFO_HEADER_OUT, buf, n);
    if (len != n) {
        result = containers.curlx_dyn_addn(&mq.sendbuf, buf + n, len - n);
    }
    return result;
}

fn mqtt_flush(data: ?*anyopaque) CURLcode {
    const mq = mqttEasy(data) orelse return CURLE_FAILED_INIT;
    const len = containers.curlx_dyn_len(&mq.sendbuf);
    if (len == 0) return CURLE_OK;

    var n: usize = 0;
    const ptr = containers.curlx_dyn_ptr(&mq.sendbuf).?;
    const result = Curl_xfer_send(data, ptr, len, false, &n);
    if (result != CURLE_OK) return result;
    mq.lastTime = Curl_pgrs_now(data).*;
    Curl_debug(data, CURLINFO_HEADER_OUT, ptr, n);
    return containers.curlx_dyn_tail(&mq.sendbuf, len - n);
}

fn mqtt_pollset(data: ?*anyopaque, ps: ?*anyopaque) callconv(.c) CURLcode {
    const sock = Curl_proto_get_firstsocket(data);
    if (mqttEasy(data)) |mq| {
        if (containers.curlx_dyn_len(&mq.sendbuf) != 0) {
            return Curl_pollset_change(data, ps, sock, CURL_POLL_OUT, 0);
        }
    }
    return Curl_pollset_change(data, ps, sock, CURL_POLL_IN, 0);
}

pub fn mqtt_encode_len(buf: [*]u8, len_in: usize) usize {
    var len = len_in;
    var i: usize = 0;
    while (len > 0 and i < 4) : (i += 1) {
        var encoded: u8 = @intCast(len % 0x80);
        len /= 0x80;
        if (len != 0) {
            encoded |= 0x80;
        }
        buf[i] = encoded;
    }
    return i;
}

pub fn add_passwd(
    passwd: [*]const u8,
    plen: usize,
    pkt: [*]u8,
    start: usize,
    remain_pos: usize,
) c_int {
    const conn_flags_pos = remain_pos + 8;
    if (plen > 0xffff) return 1;
    pkt[conn_flags_pos] |= 0x40;
    pkt[start] = @intCast((plen >> 8) & 0xFF);
    pkt[start + 1] = @intCast(plen & 0xFF);
    @memcpy(pkt[start + 2 .. start + 2 + plen], passwd[0..plen]);
    return 0;
}

pub fn add_user(
    username: [*]const u8,
    ulen: usize,
    pkt: [*]u8,
    start: usize,
    remain_pos: usize,
) c_int {
    const conn_flags_pos = remain_pos + 8;
    if (ulen > 0xffff) return 1;
    pkt[conn_flags_pos] |= 0x80;
    pkt[start] = @intCast((ulen >> 8) & 0xFF);
    pkt[start + 1] = @intCast(ulen & 0xFF);
    @memcpy(pkt[start + 2 .. start + 2 + ulen], username[0..ulen]);
    return 0;
}

pub fn add_client_id(
    client_id: [*]const u8,
    client_id_len: usize,
    pkt: [*]u8,
    start: usize,
) c_int {
    if (client_id_len != MQTT_CLIENTID_LEN) return 1;
    pkt[start] = 0x00;
    pkt[start + 1] = MQTT_CLIENTID_LEN;
    @memcpy(pkt[start + 2 .. start + 2 + MQTT_CLIENTID_LEN], client_id[0..MQTT_CLIENTID_LEN]);
    return 0;
}

pub fn init_connpack(packet: [*]u8, remain: [*]const u8, remain_pos: usize) usize {
    packet[0] = MQTT_MSG_CONNECT;
    @memcpy(packet[1 .. 1 + remain_pos], remain[0..remain_pos]);
    packet[remain_pos + 1] = 0x00;
    packet[remain_pos + 2] = 0x04;
    packet[remain_pos + 3] = 'M';
    packet[remain_pos + 4] = 'Q';
    packet[remain_pos + 5] = 'T';
    packet[remain_pos + 6] = 'T';
    packet[remain_pos + 7] = 0x04;
    packet[remain_pos + 8] = 0x02;
    packet[remain_pos + 9] = 0x00;
    packet[remain_pos + 10] = 0x3c;
    return remain_pos + 10;
}

fn mqtt_connect(data: ?*anyopaque) CURLcode {
    var result: CURLcode = CURLE_OK;
    var remain: [4]u8 = .{ 0, 0, 0, 0 };
    var client_id: [MQTT_CLIENTID_LEN:0]u8 = @splat(0);
    @memcpy(client_id[0..4], "curl");
    const clen: usize = 4;

    var user_ptr: ?[*:0]const u8 = null;
    var passwd_ptr: ?[*:0]const u8 = null;
    Curl_proto_get_creds(data, &user_ptr, &passwd_ptr);
    const ulen: usize = if (user_ptr) |u| std.mem.len(u) else 0;
    const plen: usize = if (passwd_ptr) |p| std.mem.len(p) else 0;
    const payloadlen: usize = ulen + plen + MQTT_CLIENTID_LEN + 2 +
        (if (ulen != 0) @as(usize, 2) else 0) +
        (if (plen != 0) @as(usize, 2) else 0);

    const remain_pos = mqtt_encode_len(&remain, payloadlen + 10);
    const packetlen: usize = payloadlen + 10 + remain_pos + 1;
    if (packetlen > 0xFFFFFFF) {
        return CURLE_WEIRD_SERVER_REPLY;
    }
    const packet = mem.callocMany(u8, packetlen) orelse return CURLE_OUT_OF_MEMORY;
    defer {
        std.crypto.secureZero(u8, packet[0..packetlen]);
        mem.free(packet);
        Curl_proto_unlink_creds(data);
    }

    const pos = init_connpack(packet, &remain, remain_pos);

    result = Curl_rand_alnum(data, client_id[clen..].ptr, MQTT_CLIENTID_LEN - clen + 1);
    const cid_cstr: [*:0]const u8 = &client_id;
    const cid_len = std.mem.len(cid_cstr);
    if (add_client_id(cid_cstr, cid_len, packet, pos + 1) != 0) {
        Curl_failf(data, "Client ID length mismatched: [%zu]", cid_len);
        return CURLE_WEIRD_SERVER_REPLY;
    }
    Curl_infof(data, "Using client id '%s'", cid_cstr);

    const start_user: usize = pos + 3 + MQTT_CLIENTID_LEN;
    var start_pwd: usize = start_user + ulen;
    if (ulen != 0) {
        start_pwd += 2;
        if (add_user(user_ptr.?, ulen, packet, start_user, remain_pos) != 0) {
            Curl_failf(data, "Username too long: [%zu]", ulen);
            return CURLE_WEIRD_SERVER_REPLY;
        }
    }

    if (plen != 0) {
        if (add_passwd(passwd_ptr.?, plen, packet, start_pwd, remain_pos) != 0) {
            Curl_failf(data, "Password too long: [%zu]", plen);
            return CURLE_WEIRD_SERVER_REPLY;
        }
    }

    if (result == CURLE_OK) {
        result = mqtt_send(data, packet, packetlen);
    }
    return result;
}

fn mqtt_disconnect(data: ?*anyopaque) CURLcode {
    return mqtt_send(data, "\xe0\x00", 2);
}

fn mqtt_recv_atleast(data: ?*anyopaque, nbytes: usize) CURLcode {
    const mq = mqttEasy(data) orelse return CURLE_FAILED_INIT;
    var rlen = containers.curlx_dyn_len(&mq.recvbuf);

    if (rlen < nbytes) {
        var readbuf: [1024]u8 = undefined;
        var nread: usize = 0;
        const result = Curl_xfer_recv(data, &readbuf, nbytes - rlen, &nread);
        if (result != CURLE_OK) return result;
        if (nread == 0) return CURLE_RECV_ERROR;
        if (containers.curlx_dyn_addn(&mq.recvbuf, &readbuf, nread) != CURLE_OK) {
            return CURLE_OUT_OF_MEMORY;
        }
        rlen = containers.curlx_dyn_len(&mq.recvbuf);
    }
    return if (rlen >= nbytes) CURLE_OK else CURLE_AGAIN;
}

fn mqtt_recv_consume(data: ?*anyopaque, nbytes: usize) void {
    if (mqttEasy(data)) |mq| {
        const rlen = containers.curlx_dyn_len(&mq.recvbuf);
        if (rlen <= nbytes) {
            containers.curlx_dyn_reset(&mq.recvbuf);
        } else {
            _ = containers.curlx_dyn_tail(&mq.recvbuf, rlen - nbytes);
        }
    }
}

fn mqtt_verify_connack(data: ?*anyopaque) CURLcode {
    const mq = mqttEasy(data) orelse return CURLE_FAILED_INIT;

    if (mq.remaining_length != 2) {
        Curl_failf(data, "CONNACK expected Remaining Length 2, got %zu", mq.remaining_length);
        return CURLE_WEIRD_SERVER_REPLY;
    }

    const result = mqtt_recv_atleast(data, MQTT_CONNACK_LEN);
    if (result != CURLE_OK) return result;

    const ptr = containers.curlx_dyn_ptr(&mq.recvbuf).?;
    Curl_debug(data, CURLINFO_HEADER_IN, ptr, MQTT_CONNACK_LEN);

    if (ptr[0] != 0x00 or ptr[1] != 0x00) {
        Curl_failf(
            data,
            "Expected %02x%02x but got %02x%02x",
            @as(c_uint, 0x00),
            @as(c_uint, 0x00),
            @as(c_uint, ptr[0]),
            @as(c_uint, ptr[1]),
        );
        containers.curlx_dyn_reset(&mq.recvbuf);
        return CURLE_WEIRD_SERVER_REPLY;
    }
    mqtt_recv_consume(data, MQTT_CONNACK_LEN);
    return CURLE_OK;
}

fn mqtt_get_topic(data: ?*anyopaque, topic: *?[*:0]u8, topiclen: *usize) CURLcode {
    const path = Curl_proto_get_up_path(data) orelse {
        Curl_failf(data, "No MQTT topic found. Forgot to URL encode it?");
        return CURLE_URL_MALFORMAT;
    };
    var result: CURLcode = CURLE_URL_MALFORMAT;
    if (std.mem.len(path) > 1) {
        result = Curl_urldecode(path + 1, 0, topic, topiclen, format_parse.REJECT_CTRL);
        if (result == CURLE_OK and topiclen.* > 0xffff) {
            Curl_failf(data, "Too long MQTT topic");
            result = CURLE_URL_MALFORMAT;
        }
    } else {
        Curl_failf(data, "No MQTT topic found. Forgot to URL encode it?");
    }
    return result;
}

fn mqtt_subscribe(data: ?*anyopaque) CURLcode {
    var result: CURLcode = CURLE_OK;
    var topic: ?[*:0]u8 = null;
    var topiclen: usize = 0;
    var encodedsize: [4]u8 = undefined;
    const conn = Curl_proto_get_conn(data);
    const mqtt = mqttConn(conn) orelse return CURLE_FAILED_INIT;

    defer mem.free(topic);

    result = mqtt_get_topic(data, &topic, &topiclen);
    if (result != CURLE_OK) return result;

    mqtt.packetid +%= 1;

    var packetlen: usize = topiclen + 5;
    const n = mqtt_encode_len(&encodedsize, packetlen);
    packetlen += n + 1;

    const pkt = mem.allocMany(u8, packetlen) orelse return CURLE_OUT_OF_MEMORY;
    defer mem.free(pkt);

    pkt[0] = MQTT_MSG_SUBSCRIBE;
    @memcpy(pkt[1 .. 1 + n], encodedsize[0..n]);
    pkt[1 + n] = @intCast((mqtt.packetid >> 8) & 0xff);
    pkt[2 + n] = @intCast(mqtt.packetid & 0xff);
    pkt[3 + n] = @intCast((topiclen >> 8) & 0xff);
    pkt[4 + n] = @intCast(topiclen & 0xff);
    @memcpy(pkt[5 + n .. 5 + n + topiclen], topic.?[0..topiclen]);
    pkt[5 + n + topiclen] = 0;

    result = mqtt_send(data, pkt, packetlen);
    return result;
}

fn mqtt_verify_suback(data: ?*anyopaque) CURLcode {
    const mq = mqttEasy(data) orelse return CURLE_FAILED_INIT;
    const conn = Curl_proto_get_conn(data);
    const mqtt = mqttConn(conn) orelse return CURLE_FAILED_INIT;

    if (mq.remaining_length != 3) {
        Curl_failf(data, "SUBACK expected Remaining Length 3, got %zu", mq.remaining_length);
        return CURLE_WEIRD_SERVER_REPLY;
    }

    const result = mqtt_recv_atleast(data, MQTT_SUBACK_LEN);
    if (result != CURLE_OK) return result;

    const ptr = containers.curlx_dyn_ptr(&mq.recvbuf).?;
    Curl_debug(data, CURLINFO_HEADER_IN, ptr, MQTT_SUBACK_LEN);

    if (ptr[0] != @as(u8, @intCast((mqtt.packetid >> 8) & 0xff)) or
        ptr[1] != @as(u8, @intCast(mqtt.packetid & 0xff)) or
        ptr[2] != 0x00)
    {
        containers.curlx_dyn_reset(&mq.recvbuf);
        return CURLE_WEIRD_SERVER_REPLY;
    }
    mqtt_recv_consume(data, MQTT_SUBACK_LEN);
    return CURLE_OK;
}

fn mqtt_publish(data: ?*anyopaque) CURLcode {
    var result: CURLcode = CURLE_OK;
    const payload = Curl_proto_get_postfields(data) orelse return CURLE_BAD_FUNCTION_ARGUMENT;
    var payloadlen: usize = 0;
    var topic: ?[*:0]u8 = null;
    var topiclen: usize = 0;
    var encodedbytes: [4]u8 = undefined;
    const postfieldsize = Curl_proto_get_postfieldsize(data);

    if (!primitives.curlx_sotouz_fits(postfieldsize, &payloadlen)) {
        if (postfieldsize > 0) return CURLE_BAD_FUNCTION_ARGUMENT;
        payloadlen = std.mem.len(payload);
    }

    defer mem.free(topic);

    result = mqtt_get_topic(data, &topic, &topiclen);
    if (result != CURLE_OK) return result;

    if ((std.math.maxInt(usize) - topiclen - 2) < payloadlen) {
        return CURLE_TOO_LARGE;
    }

    const remaininglength: usize = payloadlen + 2 + topiclen;
    const encodelen = mqtt_encode_len(&encodedbytes, remaininglength);
    if (remaininglength > (MAX_MQTT_MESSAGE_SIZE - encodelen - 1)) {
        return CURLE_TOO_LARGE;
    }

    const p = mem.allocMany(u8, remaininglength + 1 + encodelen) orelse return CURLE_OUT_OF_MEMORY;
    defer mem.free(p);

    var i: usize = 0;
    p[i] = MQTT_MSG_PUBLISH;
    i += 1;
    @memcpy(p[i .. i + encodelen], encodedbytes[0..encodelen]);
    i += encodelen;
    p[i] = @intCast((topiclen >> 8) & 0xff);
    i += 1;
    p[i] = @intCast(topiclen & 0xff);
    i += 1;
    @memcpy(p[i .. i + topiclen], topic.?[0..topiclen]);
    i += topiclen;
    @memcpy(p[i .. i + payloadlen], payload[0..payloadlen]);
    i += payloadlen;
    result = mqtt_send(data, p, i);
    return result;
}

pub fn mqtt_decode_len(lenp: *usize, buf: [*]const u8, buflen: usize) bool {
    const slice = buf[0..buflen];
    var len: usize = 0;
    var mult: usize = 1;
    var i: usize = 0;
    var encoded: u8 = 128;

    while (i < slice.len and (encoded & 128) != 0) : (i += 1) {
        if (i >= 4) return true;
        encoded = slice[i];
        const low7 = std.math.cast(usize, encoded & 127) orelse return true;
        const term = std.math.mul(usize, low7, mult) catch return true;
        len = std.math.add(usize, len, term) catch return true;
        if ((encoded & 128) != 0) {
            if (i == 3) return true;
            mult = std.math.mul(usize, mult, 128) catch return true;
        }
    }
    if ((encoded & 128) != 0) return true;

    lenp.* = len;
    return false;
}

fn mqstate(data: ?*anyopaque, state: mqttstate, nextstate: mqttstate) void {
    const conn = Curl_proto_get_conn(data);
    const mqtt = mqttConn(conn) orelse return;
    mqtt.state = state;
    if (state == .MQTT_FIRST) {
        mqtt.nextstate = nextstate;
    }
}

fn mqtt_read_publish(data: ?*anyopaque, done: *bool) CURLcode {
    var result: CURLcode = CURLE_OK;
    const conn = Curl_proto_get_conn(data);
    const mqtt = mqttConn(conn) orelse return CURLE_FAILED_INIT;
    const mq = mqttEasy(data) orelse return CURLE_FAILED_INIT;

    sw: switch (mqtt.state) {
        .MQTT_SUBACK_COMING => {
            result = mqtt_verify_suback(data);
            if (result != CURLE_OK) break :sw;
            mqstate(data, .MQTT_FIRST, .MQTT_PUBWAIT);
        },
        .MQTT_SUBACK, .MQTT_PUBWAIT => {
            const packet: u8 = mq.firstbyte & 0xf0;
            if (packet == MQTT_MSG_PUBLISH) {
                mqstate(data, .MQTT_PUB_REMAIN, .MQTT_NOSTATE);
            } else if (packet == MQTT_MSG_SUBACK) {
                mqstate(data, .MQTT_SUBACK_COMING, .MQTT_NOSTATE);
                continue :sw .MQTT_SUBACK_COMING;
            } else if (packet == MQTT_MSG_DISCONNECT) {
                Curl_infof(data, "Got DISCONNECT");
                done.* = true;
                break :sw;
            } else {
                result = CURLE_WEIRD_SERVER_REPLY;
                break :sw;
            }

            const remlen = mq.remaining_length;
            Curl_infof(data, "Remaining length: %zu bytes", remlen);
            const remlen_off = std.math.cast(curl_off_t, remlen) orelse {
                result = CURLE_WEIRD_SERVER_REPLY;
                break :sw;
            };
            const max_filesize = Curl_proto_get_max_filesize(data);
            if (max_filesize != 0 and remlen_off > max_filesize) {
                Curl_failf(data, "Maximum file size exceeded");
                result = CURLE_FILESIZE_EXCEEDED;
                break :sw;
            }
            Curl_pgrsSetDownloadSize(data, remlen_off);
            Curl_proto_set_req_download(data, remlen_off);
            mq.npacket = remlen;
            continue :sw .MQTT_PUB_REMAIN;
        },
        .MQTT_PUB_REMAIN => {
            var buffer: [4 * 1024]u8 = undefined;
            var nread: usize = 0;
            var rest = mq.npacket;
            if (rest > buffer.len) {
                rest = buffer.len;
            }
            result = Curl_xfer_recv(data, &buffer, rest, &nread);
            if (result != CURLE_OK) {
                if (result == CURLE_AGAIN) {
                    Curl_infof(data, "EEEE AAAAGAIN");
                }
                break :sw;
            }
            if (nread == 0) {
                Curl_infof(data, "server disconnected");
                result = CURLE_PARTIAL_FILE;
                break :sw;
            }

            mq.lastTime = Curl_pgrs_now(data).*;
            result = Curl_client_write(data, CLIENTWRITE_BODY, &buffer, nread);
            if (result != CURLE_OK) break :sw;

            mq.npacket -= nread;
            if (mq.npacket == 0) {
                mqstate(data, .MQTT_FIRST, .MQTT_PUBWAIT);
            }
        },
        else => {
            result = CURLE_WEIRD_SERVER_REPLY;
        },
    }
    return result;
}

fn mqtt_do(data: ?*anyopaque, done: *bool) callconv(.c) CURLcode {
    const mq = mqttEasy(data) orelse return CURLE_FAILED_INIT;
    done.* = false;

    mq.lastTime = Curl_pgrs_now(data).*;
    mq.pingsent = false;

    const result = mqtt_connect(data);
    if (result != CURLE_OK) {
        Curl_failf(data, "Error %d sending MQTT CONNECT request", @as(c_int, @intCast(result)));
        return result;
    }
    mqstate(data, .MQTT_FIRST, .MQTT_CONNACK);
    return CURLE_OK;
}

fn mqtt_done(data: ?*anyopaque, status: CURLcode, premature: bool) callconv(.c) CURLcode {
    _ = status;
    _ = premature;
    if (mqttEasy(data)) |mq| {
        containers.curlx_dyn_free(&mq.sendbuf);
        containers.curlx_dyn_free(&mq.recvbuf);
    }
    return CURLE_OK;
}

fn mqtt_ping(data: ?*anyopaque) CURLcode {
    const mq = mqttEasy(data) orelse return CURLE_FAILED_INIT;
    const conn = Curl_proto_get_conn(data);
    const mqtt = mqttConn(conn) orelse return CURLE_FAILED_INIT;

    var result: CURLcode = CURLE_OK;
    const upkeep_ms = Curl_proto_get_upkeep_interval_ms(data);
    if (mqtt.state == .MQTT_FIRST and !mq.pingsent and upkeep_ms > 0) {
        const t = Curl_pgrs_now(data).*;
        const diff = curlx_time_net.curlx_ptimediff_ms(&t, &mq.lastTime);
        if (diff > upkeep_ms) {
            const packet = [2]u8{ 0xC0, 0x00 };
            result = mqtt_send(data, &packet, packet.len);
            if (result == CURLE_OK) {
                mq.pingsent = true;
            }
            Curl_infof(data, "mqtt_ping: sent ping request.");
        }
    }
    return result;
}

fn mqtt_doing(data: ?*anyopaque, done: *bool) callconv(.c) CURLcode {
    const mq = mqttEasy(data) orelse return CURLE_FAILED_INIT;
    const conn = Curl_proto_get_conn(data);
    const mqtt = mqttConn(conn) orelse return CURLE_FAILED_INIT;

    var result: CURLcode = CURLE_OK;
    var nread: usize = 0;
    var recvbyte: u8 = 0;

    done.* = false;

    if (containers.curlx_dyn_len(&mq.sendbuf) != 0) {
        result = mqtt_flush(data);
        if (result != CURLE_OK or containers.curlx_dyn_len(&mq.sendbuf) != 0) {
            return result;
        }
    }

    result = mqtt_ping(data);
    if (result != CURLE_OK or containers.curlx_dyn_len(&mq.sendbuf) != 0) {
        return result;
    }

    Curl_infof(data, "mqtt_doing: state [%d]", @as(c_int, @intCast(@backingInt(mqtt.state))));
    sw: switch (mqtt.state) {
        .MQTT_FIRST => {
            const firstbyte_ptr = (&mq.firstbyte)[0..1].ptr;
            result = Curl_xfer_recv(data, firstbyte_ptr, 1, &nread);
            if (result != CURLE_OK) {
                break :sw;
            } else if (nread == 0) {
                Curl_failf(data, "Connection disconnected");
                done.* = true;
                result = CURLE_RECV_ERROR;
                break :sw;
            }
            Curl_debug(data, CURLINFO_HEADER_IN, firstbyte_ptr, 1);
            mq.lastTime = Curl_pgrs_now(data).*;
            mq.npacket = 0;
            mqstate(data, .MQTT_REMAINING_LENGTH, .MQTT_NOSTATE);
            continue :sw .MQTT_REMAINING_LENGTH;
        },
        .MQTT_REMAINING_LENGTH => {
            const recvbyte_ptr = (&recvbyte)[0..1].ptr;
            while (true) {
                result = Curl_xfer_recv(data, recvbyte_ptr, 1, &nread);
                if (result != CURLE_OK or nread == 0) break;
                Curl_debug(data, CURLINFO_HEADER_IN, recvbyte_ptr, 1);
                mq.pkt_hd[mq.npacket] = recvbyte;
                mq.npacket += 1;
                if (!((recvbyte & 0x80) != 0 and mq.npacket < 4)) break;
            }
            if (result == CURLE_OK and nread != 0 and (recvbyte & 0x80) != 0) {
                result = CURLE_WEIRD_SERVER_REPLY;
            }
            if (result != CURLE_OK) break :sw;
            if (mqtt_decode_len(&mq.remaining_length, &mq.pkt_hd, mq.npacket)) {
                result = CURLE_WEIRD_SERVER_REPLY;
                break :sw;
            }
            mq.npacket = 0;
            const pkt_type: u8 = mq.firstbyte & 0xF0;
            const reserved: u8 = mq.firstbyte & 0x0F;
            if ((pkt_type == MQTT_MSG_DISCONNECT or pkt_type == MQTT_MSG_PINGRESP) and
                (mq.remaining_length != 0 or reserved != 0))
            {
                const type_str: [*:0]const u8 = if (pkt_type == MQTT_MSG_DISCONNECT) "DISCONNECT" else "PINGRESP";
                Curl_failf(
                    data,
                    "Broker sent malformed %s (remaining_length=%zu, header byte=0x%02x)",
                    type_str,
                    mq.remaining_length,
                    @as(c_uint, mq.firstbyte),
                );
                result = CURLE_WEIRD_SERVER_REPLY;
                break :sw;
            }
            if (mq.remaining_length != 0) {
                mqstate(data, mqtt.nextstate, .MQTT_NOSTATE);
                break :sw;
            }
            mqstate(data, .MQTT_FIRST, .MQTT_FIRST);

            if (mq.firstbyte == MQTT_MSG_DISCONNECT) {
                Curl_infof(data, "Got DISCONNECT");
                done.* = true;
            }
            if (mq.firstbyte == MQTT_MSG_PINGRESP) {
                Curl_infof(data, "Received ping response.");
                mq.pingsent = false;
                mqstate(data, .MQTT_FIRST, .MQTT_PUBWAIT);
            }
        },
        .MQTT_CONNACK => {
            result = mqtt_verify_connack(data);
            if (result != CURLE_OK) break :sw;

            if (!Curl_proto_is_httpreq_post(data)) {
                result = mqtt_subscribe(data);
                if (result == CURLE_OK) {
                    mqstate(data, .MQTT_FIRST, .MQTT_SUBACK);
                }
                break :sw;
            }

            result = mqtt_publish(data);
            if (result != CURLE_OK) break :sw;
            mqstate(data, .MQTT_POST_DRAIN, .MQTT_NOSTATE);
            continue :sw .MQTT_POST_DRAIN;
        },
        .MQTT_POST_DRAIN => {
            if (containers.curlx_dyn_len(&mq.sendbuf) != 0) break :sw;
            result = mqtt_disconnect(data);
            if (result != CURLE_OK) break :sw;
            mqstate(data, .MQTT_DISCONNECT_DRAIN, .MQTT_NOSTATE);
            continue :sw .MQTT_DISCONNECT_DRAIN;
        },
        .MQTT_DISCONNECT_DRAIN => {
            if (containers.curlx_dyn_len(&mq.sendbuf) == 0) {
                done.* = true;
            }
        },
        .MQTT_SUBACK, .MQTT_PUBWAIT, .MQTT_PUB_REMAIN => {
            result = mqtt_read_publish(data, done);
        },
        else => {
            Curl_failf(data, "State not handled yet");
            done.* = true;
        },
    }

    if (result == CURLE_AGAIN) {
        result = CURLE_OK;
    }
    return result;
}

fn mqtts_connecting(data: ?*anyopaque, done: *bool) callconv(.c) CURLcode {
    const conn = Curl_proto_get_conn(data);
    const result = Curl_conn_connect(data, FIRSTSOCKET, true, done);
    if (result != CURLE_OK) {
        Curl_conncontrol(conn, CONNCTRL_CONN_CLOSE);
    }
    return result;
}

pub export const Curl_protocol_mqtts: Curl_protocol = .{
    .setup_connection = mqtt_setup_conn,
    .do_it = mqtt_do,
    .done = mqtt_done,
    .do_more = null,
    .connect_it = null,
    .connecting = mqtts_connecting,
    .doing = mqtt_doing,
    .proto_pollset = null,
    .doing_pollset = mqtt_pollset,
    .domore_pollset = null,
    .perform_pollset = null,
    .disconnect = null,
    .write_resp = null,
    .write_resp_hd = null,
    .connection_is_dead = null,
    .attach = null,
    .follow = null,
};

pub export const Curl_protocol_mqtt: Curl_protocol = .{
    .setup_connection = mqtt_setup_conn,
    .do_it = mqtt_do,
    .done = mqtt_done,
    .do_more = null,
    .connect_it = null,
    .connecting = null,
    .doing = mqtt_doing,
    .proto_pollset = null,
    .doing_pollset = mqtt_pollset,
    .domore_pollset = null,
    .perform_pollset = null,
    .disconnect = null,
    .write_resp = null,
    .write_resp_hd = null,
    .connection_is_dead = null,
    .attach = null,
    .follow = null,
};

// ============================================================================
// Unit tests
// ============================================================================

test "Curl_protocol vtables for gopher, dict, file, and mqtt" {
    try std.testing.expect(Curl_protocol_gopher.do_it != null);
    try std.testing.expect(Curl_protocol_gopher.connect_it == null);
    try std.testing.expect(Curl_protocol_gophers.do_it != null);
    try std.testing.expect(Curl_protocol_gophers.connect_it != null);
    try std.testing.expect(Curl_protocol_gophers.connecting != null);

    try std.testing.expect(Curl_protocol_dict.do_it != null);
    try std.testing.expect(Curl_protocol_dict.setup_connection == null);

    try std.testing.expect(Curl_protocol_file.setup_connection != null);
    try std.testing.expect(Curl_protocol_file.do_it != null);
    try std.testing.expect(Curl_protocol_file.done != null);
    try std.testing.expect(Curl_protocol_file.connect_it != null);
    try std.testing.expect(Curl_protocol_file.disconnect != null);

    try std.testing.expect(Curl_protocol_mqtt.setup_connection != null);
    try std.testing.expect(Curl_protocol_mqtt.do_it != null);
    try std.testing.expect(Curl_protocol_mqtt.done != null);
    try std.testing.expect(Curl_protocol_mqtt.doing != null);
    try std.testing.expect(Curl_protocol_mqtt.doing_pollset != null);
    try std.testing.expect(Curl_protocol_mqtts.connecting != null);
}

test "dict unescape_word escapes RFC 2229 special characters" {
    const plain = unescape_word("hello") orelse return error.TestUnexpectedResult;
    defer mem.free(plain);
    try std.testing.expectEqualStrings("hello", std.mem.span(plain));

    const special = unescape_word("a b'\"\\") orelse return error.TestUnexpectedResult;
    defer mem.free(special);
    try std.testing.expectEqualStrings("a\\ b\\'\\\"\\\\", std.mem.span(special));
}

test "mqtt length encoding and decoding roundtrip" {
    const cases = [_]struct { len: usize, expected_bytes: usize }{
        .{ .len = 1, .expected_bytes = 1 },
        .{ .len = 127, .expected_bytes = 1 },
        .{ .len = 128, .expected_bytes = 2 },
        .{ .len = 16383, .expected_bytes = 2 },
        .{ .len = 16384, .expected_bytes = 3 },
        .{ .len = 2097151, .expected_bytes = 3 },
        .{ .len = 2097152, .expected_bytes = 4 },
        .{ .len = 268435455, .expected_bytes = 4 },
    };

    for (cases) |tc| {
        var buf: [4]u8 = undefined;
        const n = mqtt_encode_len(&buf, tc.len);
        try std.testing.expectEqual(tc.expected_bytes, n);

        var decoded: usize = 0;
        const err = mqtt_decode_len(&decoded, &buf, n);
        try std.testing.expect(!err);
        try std.testing.expectEqual(tc.len, decoded);
    }

    // Truncated or oversized variable-length integer should fail
    var bad_decoded: usize = 0;
    const truncated = [_]u8{ 0x80, 0x80 };
    try std.testing.expect(mqtt_decode_len(&bad_decoded, &truncated, truncated.len));
    const too_long = [_]u8{ 0x80, 0x80, 0x80, 0x80, 0x01 };
    try std.testing.expect(mqtt_decode_len(&bad_decoded, &too_long, too_long.len));
    // 4-byte varint with MSB still set on 4th byte (requires 5th byte) must fail even if buflen == 4
    const cont4 = [_]u8{ 0xff, 0xff, 0xff, 0xff };
    try std.testing.expect(mqtt_decode_len(&bad_decoded, &cont4, cont4.len));
}

test "mqtt CONNECT packet construction helpers" {
    var pkt: [64]u8 = std.mem.zeroes([64]u8);
    var remain: [4]u8 = undefined;
    const remain_pos = mqtt_encode_len(&remain, 24);
    const pos = init_connpack(&pkt, &remain, remain_pos);
    try std.testing.expectEqual(@as(u8, MQTT_MSG_CONNECT), pkt[0]);
    try std.testing.expectEqualStrings("MQTT", pkt[remain_pos + 3 .. remain_pos + 7]);

    try std.testing.expectEqual(@as(c_int, 0), add_client_id("curl0123abcd", 12, &pkt, pos + 1));
    try std.testing.expectEqual(@as(c_int, 1), add_client_id("short", 5, &pkt, pos + 1));

    const start_user = pos + 3 + MQTT_CLIENTID_LEN;
    try std.testing.expectEqual(@as(c_int, 0), add_user("alice", 5, &pkt, start_user, remain_pos));
    try std.testing.expect((pkt[remain_pos + 8] & 0x80) != 0);

    const start_pwd = start_user + 2 + 5;
    try std.testing.expectEqual(@as(c_int, 0), add_passwd("secret", 6, &pkt, start_pwd, remain_pos));
    try std.testing.expect((pkt[remain_pos + 8] & 0x40) != 0);
}
