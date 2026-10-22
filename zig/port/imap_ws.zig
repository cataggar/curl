const std = @import("std");
const builtin = @import("builtin");
const mem = @import("mem.zig");
const primitives = @import("primitives.zig");
const containers = @import("containers.zig");
const curlx_parse = @import("curlx_parse.zig");
const curlx_time_net = @import("curlx_time_net.zig");
const io_buffers = @import("io_buffers.zig");
const headers_sock = @import("headers_sock.zig");

const CURLcode = c_uint;
const CURLE_OK: CURLcode = 0;
const CURLE_UNSUPPORTED_PROTOCOL: CURLcode = 1;
const CURLE_FAILED_INIT: CURLcode = 2;
const CURLE_URL_MALFORMAT: CURLcode = 3;
const CURLE_WEIRD_SERVER_REPLY: CURLcode = 8;
const CURLE_REMOTE_ACCESS_DENIED: CURLcode = 9;
const CURLE_QUOTE_ERROR: CURLcode = 21;
const CURLE_WRITE_ERROR: CURLcode = 23;
const CURLE_UPLOAD_FAILED: CURLcode = 25;
const CURLE_OUT_OF_MEMORY: CURLcode = 27;
const CURLE_BAD_FUNCTION_ARGUMENT: CURLcode = 43;
const CURLE_GOT_NOTHING: CURLcode = 52;
const CURLE_SEND_ERROR: CURLcode = 55;
const CURLE_RECV_ERROR: CURLcode = 56;
const CURLE_USE_SSL_FAILED: CURLcode = 64;
const CURLE_LOGIN_DENIED: CURLcode = 67;
const CURLE_REMOTE_FILE_NOT_FOUND: CURLcode = 78;
const CURLE_AGAIN: CURLcode = 81;
const CURLE_TOO_LARGE: CURLcode = 100;

const curl_off_t = i64;
const timediff_t = i64;
const curl_socket_t = if (builtin.os.tag == .windows) usize else c_int;
const CURL_SOCKET_BAD: curl_socket_t = if (builtin.os.tag == .windows) ~@as(usize, 0) else -1;

const Curl_easy = opaque {};
const connectdata = opaque {};
const CURLU = opaque {};
const easy_pollset = opaque {};

const dynbuf = containers.dynbuf;
const bufref = containers.bufref;
const bufq = io_buffers.bufq;

const pingpong = extern struct {
    nread_resp: usize,
    sendthis: ?[*]u8,
    sendleft: usize,
    sendsize: usize,
    response: curlx_time_net.Curltime,
    sendbuf: dynbuf,
    recvbuf: dynbuf,
    overflow: usize,
    nfinal: usize,
    statemachine: ?*const fn (data: ?*Curl_easy, conn: ?*connectdata) callconv(.c) CURLcode,
    endofresp: ?*const fn (data: ?*Curl_easy, conn: ?*connectdata, ptr: [*:0]const u8, len: usize, code: *c_int) callconv(.c) bool,
    flags: c_uint,
};

pub const Curl_protocol = extern struct {
    setup_connection: ?*const fn (data: ?*Curl_easy, conn: ?*connectdata) callconv(.c) CURLcode,
    do_it: ?*const fn (data: ?*Curl_easy, done: *bool) callconv(.c) CURLcode,
    done: ?*const fn (data: ?*Curl_easy, status: CURLcode, premature: bool) callconv(.c) CURLcode,
    do_more: ?*const fn (data: ?*Curl_easy, domore: *c_int) callconv(.c) CURLcode,
    connect_it: ?*const fn (data: ?*Curl_easy, done: *bool) callconv(.c) CURLcode,
    connecting: ?*const fn (data: ?*Curl_easy, done: *bool) callconv(.c) CURLcode,
    doing: ?*const fn (data: ?*Curl_easy, done: *bool) callconv(.c) CURLcode,
    proto_pollset: ?*const fn (data: ?*Curl_easy, ps: ?*easy_pollset) callconv(.c) CURLcode,
    doing_pollset: ?*const fn (data: ?*Curl_easy, ps: ?*easy_pollset) callconv(.c) CURLcode,
    domore_pollset: ?*const fn (data: ?*Curl_easy, ps: ?*easy_pollset) callconv(.c) CURLcode,
    perform_pollset: ?*const fn (data: ?*Curl_easy, ps: ?*easy_pollset) callconv(.c) CURLcode,
    disconnect: ?*const fn (data: ?*Curl_easy, conn: ?*connectdata, dead_connection: bool) callconv(.c) CURLcode,
    write_resp: ?*const fn (data: ?*Curl_easy, buf: [*]const u8, blen: usize, is_eos: bool) callconv(.c) CURLcode,
    write_resp_hd: ?*const fn (data: ?*Curl_easy, hd: [*]const u8, hdlen: usize, is_eos: bool) callconv(.c) CURLcode,
    connection_is_dead: ?*const fn (data: ?*Curl_easy, conn: ?*connectdata) callconv(.c) bool,
    attach: ?*const fn (data: ?*Curl_easy, conn: ?*connectdata) callconv(.c) void,
    follow: ?*const fn (data: ?*Curl_easy, newurl: [*:0]const u8, @"type": c_uint) callconv(.c) CURLcode,
};

const FIRSTSOCKET: i8 = 0;

const CLIENTWRITE_BODY: c_int = 1 << 0;
const CLIENTWRITE_INFO: c_int = 1 << 1;
const CLIENTWRITE_HEADER: c_int = 1 << 2;
const CLIENTWRITE_EOS: c_int = 1 << 7;
const CLIENTWRITE_0LEN: c_int = 1 << 8;

const PPTRANSFER_BODY: c_uint = 0;
const PPTRANSFER_INFO: c_uint = 1;
const PPTRANSFER_NONE: c_uint = 2;

const CURLUSESSL_NONE: u8 = 0;
const CURLUSESSL_TRY: u8 = 1;

const CURLULFLAG_ANSWERED: u8 = 1 << 0;
const CURLULFLAG_DELETED: u8 = 1 << 1;
const CURLULFLAG_DRAFT: u8 = 1 << 2;
const CURLULFLAG_FLAGGED: u8 = 1 << 3;
const CURLULFLAG_SEEN: u8 = 1 << 4;

const CURLUPART_QUERY: c_uint = 8;
const CURLU_URLDECODE: c_uint = 1 << 6;
const CURLUE_OUT_OF_MEMORY: c_uint = 7;

const REJECT_CTRL: c_uint = 3;

// SASL constants
const SASL_MECH_EXTERNAL: c_ushort = 1 << 5;
const SASL_AUTH_NONE: c_ushort = 0;
const SASL_AUTH_ANY: c_ushort = 0xffff;
const SASL_AUTH_DEFAULT: c_ushort = SASL_AUTH_ANY & ~SASL_MECH_EXTERNAL;

const SASL_FLAG_BASE64: c_ushort = 0x0001;

const SASL_IDLE: c_uint = 0;
const SASL_INPROGRESS: c_uint = 1;
const SASL_DONE: c_uint = 2;

const IMAP_RESP_OK: c_int = 1;
const IMAP_RESP_NOT_OK: c_int = 2;
const IMAP_RESP_PREAUTH: c_int = 3;

const IMAP_TYPE_CLEARTEXT: u8 = 1 << 0;
const IMAP_TYPE_SASL: u8 = 1 << 1;
const IMAP_TYPE_NONE: u8 = 0;
const IMAP_TYPE_ANY: u8 = IMAP_TYPE_CLEARTEXT | IMAP_TYPE_SASL;

const CURL_META_IMAP_EASY = "meta:proto:imap:easy";
const CURL_META_IMAP_CONN = "meta:proto:imap:conn";

const imapstate = enum(c_uint) {
    IMAP_STOP = 0,
    IMAP_SERVERGREET,
    IMAP_CAPABILITY,
    IMAP_STARTTLS,
    IMAP_UPGRADETLS,
    IMAP_AUTHENTICATE,
    IMAP_LOGIN,
    IMAP_LIST,
    IMAP_SELECT,
    IMAP_FETCH,
    IMAP_FETCH_FINAL,
    IMAP_APPEND,
    IMAP_APPEND_FINAL,
    IMAP_SEARCH,
    IMAP_LOGOUT,
    IMAP_LAST,
};

const SASLproto = extern struct {
    service: [*:0]const u8,
    sendauth: *const fn (data: ?*Curl_easy, mech: [*:0]const u8, ir: *const bufref) callconv(.c) CURLcode,
    contauth: *const fn (data: ?*Curl_easy, mech: [*:0]const u8, contauth: *const bufref) callconv(.c) CURLcode,
    cancelauth: *const fn (data: ?*Curl_easy, mech: [*:0]const u8) callconv(.c) CURLcode,
    getmessage: *const fn (data: ?*Curl_easy, out: *bufref) callconv(.c) CURLcode,
    maxirlen: usize,
    contcode: c_int,
    finalcode: c_int,
    defmechs: c_ushort,
    flags: c_ushort,
};

const SASL = extern struct {
    _opaque: [5]u64,
};

const IMAP = extern struct {
    transfer: c_uint,
    mailbox: ?[*:0]u8,
    uid: ?[*:0]u8,
    mindex: ?[*:0]u8,
    section: ?[*:0]u8,
    partial: ?[*:0]u8,
    query: ?[*:0]u8,
    custom: ?[*:0]u8,
    custom_params: ?[*:0]u8,
    uidvalidity: c_uint,
    uidvalidity_set: bool,
};

const imap_conn = extern struct {
    pp: pingpong,
    sasl: SASL,
    mailbox: ?[*:0]u8,
    state: imapstate,
    mb_uidvalidity: c_uint,
    resptag: [5]u8,
    preftype: u8,
    cmdid: u8,
    ssldone: bool,
    preauth: bool,
    tls_supported: bool,
    login_disabled: bool,
    ir_supported: bool,
    mb_uidvalidity_set: bool,
};

const Curl_meta_dtor = *const fn (key: [*:0]const u8, klen: usize, entry: ?*anyopaque) callconv(.c) void;

// C / Zig extern declarations
extern fn curlx_dyn_addn(s: *dynbuf, mem_ptr: *const anyopaque, len: usize) callconv(.c) CURLcode;
extern fn curlx_dyn_tail(s: *dynbuf, length: usize) callconv(.c) CURLcode;
extern fn Curl_bufref_set(br: *bufref, ptr: ?*const anyopaque, len: usize, dtor: ?*const fn (?*anyopaque) callconv(.c) void) callconv(.c) void;
extern fn Curl_bufref_ptr(br: *const bufref) callconv(.c) ?[*]const u8;
extern fn curlx_str_number(linep: *[*:0]const u8, nump: *curl_off_t, max: curl_off_t) callconv(.c) c_int;
extern fn curlx_str_single(linep: *[*:0]const u8, byte: u8) callconv(.c) c_int;
extern fn curlx_strzero(buf: ?[*:0]u8) callconv(.c) void;
extern fn Curl_urldecode(string: [*]const u8, length: usize, ostring: *?[*:0]u8, olen: ?*usize, ctrl: c_uint) callconv(.c) CURLcode;

extern fn Curl_pp_flushsend(data: ?*Curl_easy, pp: *pingpong) callconv(.c) CURLcode;
extern fn Curl_pp_disconnect(pp: *pingpong) callconv(.c) CURLcode;
extern fn Curl_pp_moredata(pp: *pingpong) callconv(.c) bool;
extern fn Curl_pp_needs_flush(data: ?*Curl_easy, pp: *pingpong) callconv(.c) bool;

extern fn Curl_meta_set(data: ?*Curl_easy, key: [*:0]const u8, meta_data: ?*anyopaque, meta_dtor: Curl_meta_dtor) callconv(.c) CURLcode;
extern fn Curl_meta_get(data: ?*Curl_easy, key: [*:0]const u8) callconv(.c) ?*anyopaque;
extern fn Curl_conn_meta_set(conn: ?*connectdata, key: [*:0]const u8, meta_data: ?*anyopaque, meta_dtor: Curl_meta_dtor) callconv(.c) CURLcode;
extern fn Curl_conn_meta_get(conn: ?*connectdata, key: [*:0]const u8) callconv(.c) ?*anyopaque;

extern fn Curl_sasl_init(sasl: *SASL, data: ?*Curl_easy, params: *const SASLproto) callconv(.c) void;
extern fn Curl_sasl_can_authenticate(sasl: *SASL, data: ?*Curl_easy) callconv(.c) bool;
extern fn Curl_sasl_start(sasl: *SASL, data: ?*Curl_easy, force_ir: bool, progress: *c_uint) callconv(.c) CURLcode;
extern fn Curl_sasl_continue(sasl: *SASL, data: ?*Curl_easy, code: c_int, progress: *c_uint) callconv(.c) CURLcode;
extern fn Curl_sasl_parse_url_auth_option(sasl: *SASL, value: [*]const u8, len: usize) callconv(.c) CURLcode;
extern fn Curl_sasl_decode_mech(ptr: [*]const u8, maxlen: usize, len: *usize) callconv(.c) c_ushort;
extern fn Curl_sasl_is_blocked(sasl: *SASL, data: ?*Curl_easy) callconv(.c) CURLcode;

extern fn Curl_conn_is_ssl(conn: ?*connectdata, sockindex: i8) callconv(.c) bool;
extern fn Curl_conn_is_connected(conn: ?*connectdata, sockindex: i8) callconv(.c) bool;
extern fn Curl_conn_connect(data: ?*Curl_easy, sockindex: i8, blocking: bool, done: *bool) callconv(.c) CURLcode;
extern fn Curl_pgrsReset(data: ?*Curl_easy) callconv(.c) void;
extern fn Curl_pgrsSetUploadSize(data: ?*Curl_easy, size: curl_off_t) callconv(.c) void;
extern fn Curl_pgrsSetDownloadSize(data: ?*Curl_easy, size: curl_off_t) callconv(.c) void;
extern fn Curl_pgrsSetDownloadCounter(data: ?*Curl_easy, size: curl_off_t) callconv(.c) void;
extern fn Curl_pgrsSetUploadCounter(data: ?*Curl_easy, size: curl_off_t) callconv(.c) void;
extern fn Curl_xfer_setup_nop(data: ?*Curl_easy) callconv(.c) void;
extern fn Curl_xfer_setup_send(data: ?*Curl_easy, sockindex: i8) callconv(.c) void;
extern fn Curl_xfer_setup_recv(data: ?*Curl_easy, sockindex: i8, recv_size: curl_off_t) callconv(.c) void;
extern fn Curl_client_write(data: ?*Curl_easy, @"type": c_int, buf: [*]const u8, blen: usize) callconv(.c) CURLcode;
extern fn Curl_senddata(data: ?*Curl_easy, buffer: ?*const anyopaque, buflen: usize, n: *usize) callconv(.c) CURLcode;
extern fn curl_url_get(uh: ?*CURLU, what: c_uint, part: *?[*:0]u8, flags: c_uint) callconv(.c) c_uint;
extern fn getenv(name: [*:0]const u8) callconv(.c) ?[*:0]const u8;

// Accessor / helper functions in lib/url.c
extern fn Curl_imap_ws_failf_str(data: ?*Curl_easy, msg: [*:0]const u8) callconv(.c) void;
extern fn Curl_imap_ws_infof_str(data: ?*Curl_easy, msg: [*:0]const u8) callconv(.c) void;
extern fn Curl_imap_ws_trc_ws_str(data: ?*Curl_easy, msg: [*:0]const u8) callconv(.c) void;
extern fn Curl_imap_ws_trc_m_str(data: ?*Curl_easy, msg: [*:0]const u8) callconv(.c) void;
extern fn Curl_imap_ws_trc_write_str(data: ?*Curl_easy, msg: [*:0]const u8) callconv(.c) void;
extern fn Curl_imap_ws_trc_read_str(data: ?*Curl_easy, msg: [*:0]const u8) callconv(.c) void;
extern fn Curl_imap_ws_infof_enabled(data: ?*Curl_easy) callconv(.c) bool;
extern fn Curl_imap_ws_trc_ws_enabled(data: ?*Curl_easy) callconv(.c) bool;
extern fn Curl_imap_ws_trc_m_enabled(data: ?*Curl_easy) callconv(.c) bool;
extern fn Curl_imap_ws_trc_write_enabled(data: ?*Curl_easy) callconv(.c) bool;
extern fn Curl_imap_ws_trc_read_enabled(data: ?*Curl_easy) callconv(.c) bool;

extern fn Curl_imap_ws_pp_init(data: ?*Curl_easy, pp: *pingpong) callconv(.c) void;
extern fn Curl_imap_ws_pp_statemach(data: ?*Curl_easy, pp: *pingpong, block: bool, disconnecting: bool) callconv(.c) CURLcode;
extern fn Curl_imap_ws_pp_readresp(data: ?*Curl_easy, sockindex: i8, pp: *pingpong, code: *c_int, size: *usize) callconv(.c) CURLcode;
extern fn Curl_imap_ws_pp_pollset(data: ?*Curl_easy, pp: *pingpong, ps: ?*easy_pollset) callconv(.c) CURLcode;
extern fn Curl_imap_ws_pp_send_str(data: ?*Curl_easy, pp: *pingpong, prefix: ?[*:0]const u8, str: [*:0]const u8) callconv(.c) CURLcode;

extern fn Curl_imap_ws_sasl_get_authmechs(sasl: *const SASL) callconv(.c) c_ushort;
extern fn Curl_imap_ws_sasl_set_authmechs(sasl: *SASL, val: c_ushort) callconv(.c) void;
extern fn Curl_imap_ws_sasl_get_prefmech(sasl: *const SASL) callconv(.c) c_ushort;
extern fn Curl_imap_ws_sasl_set_prefmech(sasl: *SASL, val: c_ushort) callconv(.c) void;
extern fn Curl_imap_ws_sasl_get_authused(sasl: *const SASL) callconv(.c) c_ushort;
extern fn Curl_imap_ws_sasl_set_authused(sasl: *SASL, val: c_ushort) callconv(.c) void;

extern fn Curl_imap_ws_easy_conn(data: ?*const Curl_easy) callconv(.c) ?*connectdata;
extern fn Curl_imap_ws_conn_id(conn: ?*const connectdata) callconv(.c) curl_off_t;
extern fn Curl_imap_ws_conn_options(conn: ?*const connectdata) callconv(.c) ?[*:0]const u8;
extern fn Curl_imap_ws_conn_protoconnstart(conn: ?*const connectdata) callconv(.c) bool;
extern fn Curl_imap_ws_conn_has_creds(conn: ?*const connectdata) callconv(.c) bool;
extern fn Curl_imap_ws_conn_creds_user(conn: ?*const connectdata) callconv(.c) [*:0]const u8;
extern fn Curl_imap_ws_conn_creds_passwd(conn: ?*const connectdata) callconv(.c) [*:0]const u8;
extern fn Curl_imap_ws_connclose(conn: ?*connectdata) callconv(.c) void;
extern fn Curl_imap_ws_upgrade_tls_setup(data: ?*Curl_easy, conn: ?*connectdata) callconv(.c) CURLcode;
extern fn Curl_imap_ws_prepare_append(data: ?*Curl_easy, pinfilesize: *curl_off_t, pcrlf: *bool, pupload_flags: *u8) callconv(.c) CURLcode;
extern fn Curl_imap_ws_get_infilesize(data: ?*const Curl_easy) callconv(.c) curl_off_t;
extern fn Curl_imap_ws_get_use_ssl(data: ?*const Curl_easy) callconv(.c) u8;
extern fn Curl_imap_ws_get_connect_only(data: ?*const Curl_easy) callconv(.c) bool;
extern fn Curl_imap_ws_is_upload_or_mime(data: ?*const Curl_easy) callconv(.c) bool;
extern fn Curl_imap_ws_get_req_bytecount(data: ?*const Curl_easy) callconv(.c) curl_off_t;
extern fn Curl_imap_ws_get_req_maxdownload(data: ?*const Curl_easy) callconv(.c) curl_off_t;
extern fn Curl_imap_ws_set_req_maxdownload(data: ?*Curl_easy, val: curl_off_t) callconv(.c) void;
extern fn Curl_imap_ws_set_req_size(data: ?*Curl_easy, val: curl_off_t) callconv(.c) void;
extern fn Curl_imap_ws_get_req_no_body(data: ?*const Curl_easy) callconv(.c) bool;
extern fn Curl_imap_ws_get_up_path(data: ?*const Curl_easy) callconv(.c) ?[*:0]const u8;
extern fn Curl_imap_ws_get_uh(data: ?*const Curl_easy) callconv(.c) ?*CURLU;
extern fn Curl_imap_ws_get_customrequest(data: ?*Curl_easy) callconv(.c) ?[*:0]const u8;

extern fn Curl_imap_ws_get_raw_mode(data: ?*const Curl_easy) callconv(.c) bool;
extern fn Curl_imap_ws_get_no_auto_pong(data: ?*const Curl_easy) callconv(.c) bool;
extern fn Curl_imap_ws_cwriter_is_paused(data: ?*const Curl_easy) callconv(.c) bool;
extern fn Curl_imap_ws_mark_request_upgrade(data: ?*Curl_easy) callconv(.c) void;
extern fn Curl_imap_ws_set_req_header(data: ?*Curl_easy, val: bool) callconv(.c) void;
extern fn Curl_imap_ws_clear_req_recv(data: ?*Curl_easy) callconv(.c) void;
extern fn Curl_imap_ws_is_method_put(data: ?*const Curl_easy) callconv(.c) bool;
extern fn Curl_imap_ws_restart_req_send(data: ?*Curl_easy) callconv(.c) void;
extern fn Curl_imap_ws_set_upgr101_received(data: ?*Curl_easy) callconv(.c) void;
extern fn Curl_imap_ws_conn_firstsocket(data: ?*const Curl_easy) callconv(.c) curl_socket_t;
extern fn Curl_imap_ws_setup_http_neg(data: ?*Curl_easy) callconv(.c) void;
extern fn Curl_imap_ws_good_easy_handle(data: ?*const Curl_easy) callconv(.c) bool;

fn failfFmt(data: ?*Curl_easy, comptime fmt: []const u8, args: anytype) void {
    if (data == null) return;
    var buf: [512]u8 = undefined;
    const slice = std.fmt.bufPrint(&buf, fmt ++ "\x00", args) catch return;
    Curl_imap_ws_failf_str(data, @ptrCast(slice.ptr));
}

fn infofFmt(data: ?*Curl_easy, comptime fmt: []const u8, args: anytype) void {
    if (!Curl_imap_ws_infof_enabled(data)) return;
    var buf: [512]u8 = undefined;
    const slice = std.fmt.bufPrint(&buf, fmt ++ "\x00", args) catch return;
    Curl_imap_ws_infof_str(data, @ptrCast(slice.ptr));
}

fn trcWsFmt(data: ?*Curl_easy, comptime fmt: []const u8, args: anytype) void {
    if (!Curl_imap_ws_trc_ws_enabled(data)) return;
    var buf: [512]u8 = undefined;
    const slice = std.fmt.bufPrint(&buf, fmt ++ "\x00", args) catch return;
    Curl_imap_ws_trc_ws_str(data, @ptrCast(slice.ptr));
}

fn trcMFmt(data: ?*Curl_easy, comptime fmt: []const u8, args: anytype) void {
    if (!Curl_imap_ws_trc_m_enabled(data)) return;
    var buf: [512]u8 = undefined;
    const slice = std.fmt.bufPrint(&buf, fmt ++ "\x00", args) catch return;
    Curl_imap_ws_trc_m_str(data, @ptrCast(slice.ptr));
}

fn trcWriteFmt(data: ?*Curl_easy, comptime fmt: []const u8, args: anytype) void {
    if (!Curl_imap_ws_trc_write_enabled(data)) return;
    var buf: [512]u8 = undefined;
    const slice = std.fmt.bufPrint(&buf, fmt ++ "\x00", args) catch return;
    Curl_imap_ws_trc_write_str(data, @ptrCast(slice.ptr));
}

fn trcReadFmt(data: ?*Curl_easy, comptime fmt: []const u8, args: anytype) void {
    if (!Curl_imap_ws_trc_read_enabled(data)) return;
    var buf: [512]u8 = undefined;
    const slice = std.fmt.bufPrint(&buf, fmt ++ "\x00", args) catch return;
    Curl_imap_ws_trc_read_str(data, @ptrCast(slice.ptr));
}

fn cStrSlice(s: ?[*:0]const u8) []const u8 {
    if (s) |p| return std.mem.span(p);
    return "";
}

fn freeOptStr(ptr: *?[*:0]u8) void {
    if (ptr.*) |p| {
        mem.free(@ptrCast(p));
        ptr.* = null;
    }
}

// ============================================================================
// Part 1: IMAP Protocol Handler (ported from lib/imap.c)
// ============================================================================

const saslimap = SASLproto{
    .service = "imap",
    .sendauth = imap_perform_authenticate,
    .contauth = imap_continue_authenticate,
    .cancelauth = imap_cancel_authenticate,
    .getmessage = imap_get_message,
    .maxirlen = 0,
    .contcode = '+',
    .finalcode = IMAP_RESP_OK,
    .defmechs = SASL_AUTH_DEFAULT,
    .flags = SASL_FLAG_BASE64,
};

fn imap_sendf(data: ?*Curl_easy, imapc: *imap_conn, comptime fmt: []const u8, args: anytype) CURLcode {
    const conn = Curl_imap_ws_easy_conn(data);
    const conn_id = Curl_imap_ws_conn_id(conn);
    const rem: i64 = @rem(conn_id, 26);
    const tag_char: u8 = @intCast(@as(i64, 'A') + (if (rem < 0) -rem else rem));
    imapc.cmdid +%= 1;
    _ = std.fmt.bufPrint(&imapc.resptag, "{c}{d:0>3}\x00", .{ tag_char, imapc.cmdid }) catch unreachable;

    var stack_buf: [1024]u8 = undefined;
    if (std.fmt.bufPrint(&stack_buf, fmt ++ "\x00", args)) |slice| {
        return Curl_imap_ws_pp_send_str(data, &imapc.pp, @ptrCast(&imapc.resptag), @ptrCast(slice.ptr));
    } else |_| {
        const len = std.fmt.count(fmt, args);
        const heap_ptr = mem.malloc(len + 1) orelse return CURLE_OUT_OF_MEMORY;
        defer mem.free(heap_ptr);
        const heap_slice = heap_ptr[0 .. len + 1];
        _ = std.fmt.bufPrint(heap_slice, fmt ++ "\x00", args) catch return CURLE_OUT_OF_MEMORY;
        return Curl_imap_ws_pp_send_str(data, &imapc.pp, @ptrCast(&imapc.resptag), @ptrCast(heap_slice.ptr));
    }
}

fn imap_pp_sendf(data: ?*Curl_easy, pp: *pingpong, comptime fmt: []const u8, args: anytype) CURLcode {
    var stack_buf: [1024]u8 = undefined;
    if (std.fmt.bufPrint(&stack_buf, fmt ++ "\x00", args)) |slice| {
        return Curl_imap_ws_pp_send_str(data, pp, null, @ptrCast(slice.ptr));
    } else |_| {
        const len = std.fmt.count(fmt, args);
        const heap_ptr = mem.malloc(len + 1) orelse return CURLE_OUT_OF_MEMORY;
        defer mem.free(heap_ptr);
        const heap_slice = heap_ptr[0 .. len + 1];
        _ = std.fmt.bufPrint(heap_slice, fmt ++ "\x00", args) catch return CURLE_OUT_OF_MEMORY;
        return Curl_imap_ws_pp_send_str(data, pp, null, @ptrCast(heap_slice.ptr));
    }
}

fn imap_atom(str: ?[*:0]const u8, escape_only: bool) ?[*:0]u8 {
    const s = str orelse return null;
    const s_slice = std.mem.span(s);
    if (std.mem.indexOfAny(u8, s_slice, "() {%*]\\\"") == null) {
        return mem.strdup(s);
    }

    var line: dynbuf = undefined;
    containers.curlx_dyn_init(&line, 2000);
    if (!escape_only and curlx_dyn_addn(&line, "\"", 1) != CURLE_OK) {
        return null;
    }

    for (s_slice) |ch| {
        if ((ch == '\\' or ch == '"') and curlx_dyn_addn(&line, "\\", 1) != CURLE_OK) {
            return null;
        }
        const c_arr = [1]u8{ch};
        if (curlx_dyn_addn(&line, &c_arr, 1) != CURLE_OK) {
            return null;
        }
    }

    if (!escape_only and curlx_dyn_addn(&line, "\"", 1) != CURLE_OK) {
        return null;
    }

    return containers.curlx_dyn_ptr(&line);
}

fn imap_is_bchar(ch: u8) bool {
    return switch (ch) {
        ':', '@', '/', '&', '=', '0'...'9', 'A'...'Z', 'a'...'z', '-', '.', '_', '~', '!', '$', '\'', '(', ')', '*', '+', ',', '%' => true,
        else => false,
    };
}

fn imap_parse_url_options(conn: ?*connectdata, imapc: *imap_conn) CURLcode {
    var result: CURLcode = CURLE_OK;
    var ptr_opt: ?[*:0]const u8 = Curl_imap_ws_conn_options(conn);
    var prefer_login: bool = false;

    while (result == CURLE_OK and ptr_opt != null and ptr_opt.?[0] != 0) {
        var ptr = ptr_opt.?;
        const key = ptr;
        while (ptr[0] != 0 and ptr[0] != '=') : (ptr += 1) {}

        const value = ptr + 1;
        while (ptr[0] != 0 and ptr[0] != ';') : (ptr += 1) {}

        if (primitives.curl_strnequal(key, "AUTH=+LOGIN", 11) != 0) {
            prefer_login = true;
            Curl_imap_ws_sasl_set_prefmech(&imapc.sasl, SASL_AUTH_NONE);
        } else if (primitives.curl_strnequal(key, "AUTH=", 5) != 0) {
            prefer_login = false;
            const vlen = @intFromPtr(ptr) - @intFromPtr(value);
            result = Curl_sasl_parse_url_auth_option(&imapc.sasl, value, vlen);
        } else {
            prefer_login = false;
            result = CURLE_URL_MALFORMAT;
        }

        if (ptr[0] == ';') {
            ptr_opt = ptr + 1;
        } else {
            ptr_opt = null;
        }
    }

    if (prefer_login) {
        imapc.preftype = IMAP_TYPE_CLEARTEXT;
    } else {
        switch (Curl_imap_ws_sasl_get_prefmech(&imapc.sasl)) {
            SASL_AUTH_NONE => imapc.preftype = IMAP_TYPE_NONE,
            SASL_AUTH_DEFAULT => imapc.preftype = IMAP_TYPE_ANY,
            else => imapc.preftype = IMAP_TYPE_SASL,
        }
    }

    return result;
}

fn imap_parse_url_path(data: ?*Curl_easy, imap: *IMAP) CURLcode {
    var result: CURLcode = CURLE_OK;
    const up_path = Curl_imap_ws_get_up_path(data) orelse "/";
    var ptr: [*:0]const u8 = if (up_path[0] != 0) up_path + 1 else up_path;
    var begin: [*:0]const u8 = ptr;

    while (imap_is_bchar(ptr[0])) : (ptr += 1) {}

    if (ptr != begin) {
        var end = ptr;
        if (@intFromPtr(end) > @intFromPtr(begin) and (end - 1)[0] == '/') {
            end -= 1;
        }
        result = Curl_urldecode(begin, @intFromPtr(end) - @intFromPtr(begin), &imap.mailbox, null, REJECT_CTRL);
        if (result != CURLE_OK) return result;
    } else {
        imap.mailbox = null;
    }

    while (ptr[0] == ';') {
        var tname: ?[*:0]u8 = null;
        var tnamelen: usize = 0;
        var tval: ?[*:0]u8 = null;
        var tvallen: usize = 0;

        begin = ptr + 1;
        while (begin[0] != 0 and begin[0] != '=') : (begin += 1) {}
        if (begin[0] == 0) return CURLE_URL_MALFORMAT;

        const name = ptr + 1;
        const namelen = @intFromPtr(begin) - @intFromPtr(name);

        ptr = begin + 1;
        begin = ptr;
        while (imap_is_bchar(ptr[0])) : (ptr += 1) {}

        const value = begin;
        var valuelen = @intFromPtr(ptr) - @intFromPtr(begin);

        result = Curl_urldecode(name, namelen, &tname, &tnamelen, REJECT_CTRL);
        if (result != CURLE_OK) return result;

        if (valuelen > 0 and value[valuelen - 1] == '/') {
            valuelen -= 1;
        }
        result = Curl_urldecode(value, valuelen, &tval, &tvallen, REJECT_CTRL);
        if (result != CURLE_OK) {
            freeOptStr(&tname);
            return result;
        }

        const tname_p = tname.?;
        const tval_p = tval.?;

        if (tnamelen == 11 and primitives.curl_strnequal(tname_p, "UIDVALIDITY", 11) != 0 and !imap.uidvalidity_set) {
            var vptr: [*:0]const u8 = tval_p;
            var uv: curl_off_t = 0;
            if (curlx_str_number(&vptr, &uv, std.math.maxInt(u32)) != 0 or vptr[0] != 0) {
                result = CURLE_URL_MALFORMAT;
            } else {
                imap.uidvalidity = @intCast(uv);
                imap.uidvalidity_set = true;
            }
        } else if (tnamelen == 3 and primitives.curl_strnequal(tname_p, "UID", 3) != 0 and imap.uid == null) {
            imap.uid = tval;
            tval = null;
        } else if (tnamelen == 9 and primitives.curl_strnequal(tname_p, "MAILINDEX", 9) != 0 and imap.mindex == null) {
            imap.mindex = tval;
            tval = null;
        } else if (tnamelen == 7 and primitives.curl_strnequal(tname_p, "SECTION", 7) != 0 and imap.section == null) {
            imap.section = tval;
            tval = null;
        } else if (tnamelen == 7 and primitives.curl_strnequal(tname_p, "PARTIAL", 7) != 0 and imap.partial == null) {
            imap.partial = tval;
            tval = null;
        } else {
            result = CURLE_URL_MALFORMAT;
        }

        freeOptStr(&tname);
        freeOptStr(&tval);
        if (result != CURLE_OK) return result;
    }

    if (imap.mailbox != null and imap.uid == null and imap.mindex == null) {
        const uc = curl_url_get(Curl_imap_ws_get_uh(data), CURLUPART_QUERY, &imap.query, CURLU_URLDECODE);
        if (uc == CURLUE_OUT_OF_MEMORY) return CURLE_OUT_OF_MEMORY;
    }

    if (ptr[0] != 0) return CURLE_URL_MALFORMAT;
    return CURLE_OK;
}

fn imap_parse_custom_request(data: ?*Curl_easy, imap: *IMAP) CURLcode {
    var result: CURLcode = CURLE_OK;
    const custom = Curl_imap_ws_get_customrequest(data);

    if (custom) |cust_ptr| {
        result = Curl_urldecode(cust_ptr, 0, &imap.custom, null, REJECT_CTRL);
        if (result == CURLE_OK) {
            if (imap.custom) |decoded| {
                var params: [*:0]u8 = decoded;
                while (params[0] != 0 and params[0] != ' ') : (params += 1) {}
                if (params[0] != 0) {
                    imap.custom_params = mem.strdup(params);
                    params[0] = 0;
                    if (imap.custom_params == null) {
                        result = CURLE_OUT_OF_MEMORY;
                    }
                }
            }
        }
    }

    return result;
}

fn imap_matchresp(line_in: [*:0]const u8, len_in: usize, cmd: [*:0]const u8) bool {
    const cmd_len = std.mem.len(cmd);
    if (len_in < 2) return false;
    var line = line_in + 2;
    var len = len_in - 2;

    if (len > 0 and std.ascii.isDigit(line[0])) {
        while (len > 0 and std.ascii.isDigit(line[0])) {
            line += 1;
            len -= 1;
        }
        if (len == 0 or line[0] != ' ') return false;
        line += 1;
        len -= 1;
    }

    return (cmd_len <= len and
        primitives.curl_strnequal(line, cmd, cmd_len) != 0 and
        (line[cmd_len] == ' ' or cmd_len + 2 == len));
}

fn is_custom_fetch_listing_match(params_in: [*:0]const u8) bool {
    var p = params_in;
    if (p[0] != ' ') return false;
    p += 1;

    if (!std.ascii.isDigit(p[0])) return false;
    while (std.ascii.isDigit(p[0])) {
        p += 1;
        if (p[0] == 0) return false;
    }
    return (p[0] == ':' or p[0] == ',');
}

fn is_custom_fetch_listing(imap: *const IMAP) bool {
    const custom = imap.custom orelse return false;
    const params = imap.custom_params orelse return false;
    if (primitives.curl_strequal(custom, "FETCH") != 0) {
        return is_custom_fetch_listing_match(params);
    } else if (primitives.curl_strequal(custom, "UID") != 0 and
        primitives.curl_strnequal(params, " FETCH ", 7) != 0)
    {
        return is_custom_fetch_listing_match(params + 6);
    }
    return false;
}

fn imap_endofresp(data: ?*Curl_easy, conn: ?*connectdata, line: [*:0]const u8, len: usize, resp: *c_int) callconv(.c) bool {
    const imap_ptr = Curl_meta_get(data, CURL_META_IMAP_EASY) orelse return false;
    const imap: *IMAP = @ptrCast(@alignCast(imap_ptr));
    const imapc_ptr = Curl_conn_meta_get(conn, CURL_META_IMAP_CONN) orelse return false;
    const imapc: *imap_conn = @ptrCast(@alignCast(imapc_ptr));

    const id: [*:0]const u8 = @ptrCast(&imapc.resptag);
    const id_len = std.mem.len(id);

    if (len >= id_len + 1 and std.mem.eql(u8, line[0..id_len], id[0..id_len]) and line[id_len] == ' ') {
        const p = line + id_len + 1;
        const rem = len - id_len - 1;

        if (rem >= 2 and std.mem.eql(u8, p[0..2], "OK")) {
            resp.* = IMAP_RESP_OK;
        } else if (rem >= 7 and std.mem.eql(u8, p[0..7], "PREAUTH")) {
            resp.* = IMAP_RESP_PREAUTH;
        } else {
            resp.* = IMAP_RESP_NOT_OK;
        }
        return true;
    }

    if (len >= 2 and std.mem.eql(u8, line[0..2], "* ")) {
        switch (imapc.state) {
            .IMAP_CAPABILITY => {
                if (!imap_matchresp(line, len, "CAPABILITY")) return false;
            },
            .IMAP_LIST => {
                if ((imap.custom == null and !imap_matchresp(line, len, "LIST")) or
                    (imap.custom != null and !imap_matchresp(line, len, imap.custom.?) and
                        (primitives.curl_strequal(imap.custom.?, "STORE") == 0 or !imap_matchresp(line, len, "FETCH")) and
                        primitives.curl_strequal(imap.custom.?, "SELECT") == 0 and
                        primitives.curl_strequal(imap.custom.?, "EXAMINE") == 0 and
                        primitives.curl_strequal(imap.custom.?, "SEARCH") == 0 and
                        primitives.curl_strequal(imap.custom.?, "EXPUNGE") == 0 and
                        primitives.curl_strequal(imap.custom.?, "LSUB") == 0 and
                        primitives.curl_strequal(imap.custom.?, "UID") == 0 and
                        primitives.curl_strequal(imap.custom.?, "GETQUOTAROOT") == 0 and
                        primitives.curl_strequal(imap.custom.?, "NOOP") == 0))
                {
                    return false;
                }
            },
            .IMAP_SELECT => {},
            .IMAP_FETCH => {
                if (!imap_matchresp(line, len, "FETCH")) return false;
            },
            .IMAP_SEARCH => {
                if (!imap_matchresp(line, len, "SEARCH")) return false;
            },
            else => return false,
        }

        resp.* = '*';
        return true;
    }

    if (imap.custom == null and ((len == 3 and line[0] == '+') or (len >= 2 and std.mem.eql(u8, line[0..2], "+ ")))) {
        switch (imapc.state) {
            .IMAP_AUTHENTICATE, .IMAP_APPEND => {
                resp.* = '+';
            },
            else => {
                failfFmt(data, "Unexpected continuation response", .{});
                resp.* = -1;
            },
        }
        return true;
    }

    return false;
}

fn imap_get_message(data: ?*Curl_easy, out: *bufref) callconv(.c) CURLcode {
    const conn = Curl_imap_ws_easy_conn(data);
    const imapc_ptr = Curl_conn_meta_get(conn, CURL_META_IMAP_CONN) orelse return CURLE_FAILED_INIT;
    const imapc: *imap_conn = @ptrCast(@alignCast(imapc_ptr));

    var message = containers.curlx_dyn_ptr(&imapc.pp.recvbuf) orelse {
        Curl_bufref_set(out, "", 0, null);
        return CURLE_OK;
    };
    var len = imapc.pp.nfinal;

    if (len > 2) {
        len -= 2;
        message += 2;
        while (len > 0 and (message[0] == ' ' or message[0] == '\t')) {
            message += 1;
            len -= 1;
        }
        while (len > 0) : (len -= 1) {
            const c = message[len - 1];
            if (c != '\r' and c != '\n' and c != ' ' and c != '\t') break;
        }
        message[len] = 0;
        Curl_bufref_set(out, message, len, null);
    } else {
        Curl_bufref_set(out, "", 0, null);
    }

    return CURLE_OK;
}

fn imap_state(data: ?*Curl_easy, imapc: *imap_conn, newstate: imapstate) void {
    _ = data;
    imapc.state = newstate;
}

fn imap_perform_capability(data: ?*Curl_easy, imapc: *imap_conn) CURLcode {
    Curl_imap_ws_sasl_set_authmechs(&imapc.sasl, SASL_AUTH_NONE);
    Curl_imap_ws_sasl_set_authused(&imapc.sasl, SASL_AUTH_NONE);
    imapc.tls_supported = false;

    const result = imap_sendf(data, imapc, "CAPABILITY", .{});
    if (result == CURLE_OK) {
        imap_state(data, imapc, .IMAP_CAPABILITY);
    }
    return result;
}

fn imap_perform_starttls(data: ?*Curl_easy, imapc: *imap_conn) CURLcode {
    const result = imap_sendf(data, imapc, "STARTTLS", .{});
    if (result == CURLE_OK) {
        imap_state(data, imapc, .IMAP_STARTTLS);
    }
    return result;
}

fn imap_perform_upgrade_tls(data: ?*Curl_easy, imapc: *imap_conn, conn: ?*connectdata) CURLcode {
    var result: CURLcode = CURLE_OK;
    var ssldone: bool = false;

    if (!Curl_conn_is_ssl(conn, FIRSTSOCKET)) {
        result = Curl_imap_ws_upgrade_tls_setup(data, conn);
        if (result != CURLE_OK) return result;
    }

    result = Curl_conn_connect(data, FIRSTSOCKET, false, &ssldone);
    if (result == CURLE_OK) {
        imapc.ssldone = ssldone;
        if (imapc.state != .IMAP_UPGRADETLS) {
            imap_state(data, imapc, .IMAP_UPGRADETLS);
        }
        if (imapc.ssldone) {
            result = imap_perform_capability(data, imapc);
        }
    }
    return result;
}

fn imap_perform_login(data: ?*Curl_easy, imapc: *imap_conn, conn: ?*connectdata) CURLcode {
    if (!Curl_imap_ws_conn_has_creds(conn)) {
        imap_state(data, imapc, .IMAP_STOP);
        return CURLE_OK;
    }

    const user = imap_atom(Curl_imap_ws_conn_creds_user(conn), false);
    const passwd = imap_atom(Curl_imap_ws_conn_creds_passwd(conn), false);

    const user_s = cStrSlice(user);
    const passwd_s = cStrSlice(passwd);
    const result = imap_sendf(data, imapc, "LOGIN {s} {s}", .{ user_s, passwd_s });

    if (user) |u| mem.free(@ptrCast(u));
    if (passwd) |p| {
        curlx_strzero(p);
        mem.free(@ptrCast(p));
    }

    if (result == CURLE_OK) {
        imap_state(data, imapc, .IMAP_LOGIN);
    }
    return result;
}

fn imap_perform_authenticate(data: ?*Curl_easy, mech: [*:0]const u8, initresp: *const bufref) callconv(.c) CURLcode {
    const conn = Curl_imap_ws_easy_conn(data);
    const imapc_ptr = Curl_conn_meta_get(conn, CURL_META_IMAP_CONN) orelse return CURLE_FAILED_INIT;
    const imapc: *imap_conn = @ptrCast(@alignCast(imapc_ptr));

    const mech_s = std.mem.span(mech);
    const ir = Curl_bufref_ptr(initresp);
    if (ir) |ir_ptr| {
        const ir_z: [*:0]const u8 = @ptrCast(ir_ptr);
        const ir_s = if (ir_z[0] != 0) std.mem.span(ir_z) else "=";
        return imap_sendf(data, imapc, "AUTHENTICATE {s} {s}", .{ mech_s, ir_s });
    } else {
        return imap_sendf(data, imapc, "AUTHENTICATE {s}", .{mech_s});
    }
}

fn imap_continue_authenticate(data: ?*Curl_easy, mech: [*:0]const u8, resp: *const bufref) callconv(.c) CURLcode {
    _ = mech;
    const conn = Curl_imap_ws_easy_conn(data);
    const imapc_ptr = Curl_conn_meta_get(conn, CURL_META_IMAP_CONN) orelse return CURLE_FAILED_INIT;
    const imapc: *imap_conn = @ptrCast(@alignCast(imapc_ptr));
    const ptr = Curl_bufref_ptr(resp);
    const s = if (ptr) |p| std.mem.span(@as([*:0]const u8, @ptrCast(p))) else "";
    return imap_pp_sendf(data, &imapc.pp, "{s}", .{s});
}

fn imap_cancel_authenticate(data: ?*Curl_easy, mech: [*:0]const u8) callconv(.c) CURLcode {
    _ = mech;
    const conn = Curl_imap_ws_easy_conn(data);
    const imapc_ptr = Curl_conn_meta_get(conn, CURL_META_IMAP_CONN) orelse return CURLE_FAILED_INIT;
    const imapc: *imap_conn = @ptrCast(@alignCast(imapc_ptr));
    return imap_pp_sendf(data, &imapc.pp, "*", .{});
}

fn imap_perform_authentication(data: ?*Curl_easy, imapc: *imap_conn) CURLcode {
    var result: CURLcode = CURLE_OK;
    var progress: c_uint = SASL_IDLE;

    if (imapc.preauth or !Curl_sasl_can_authenticate(&imapc.sasl, data)) {
        imap_state(data, imapc, .IMAP_STOP);
        return result;
    }

    result = Curl_sasl_start(&imapc.sasl, data, imapc.ir_supported, &progress);
    if (result == CURLE_OK) {
        if (progress == SASL_INPROGRESS) {
            imap_state(data, imapc, .IMAP_AUTHENTICATE);
        } else if (!imapc.login_disabled and (imapc.preftype & IMAP_TYPE_CLEARTEXT) != 0) {
            result = imap_perform_login(data, imapc, Curl_imap_ws_easy_conn(data));
        } else {
            result = Curl_sasl_is_blocked(&imapc.sasl, data);
        }
    }

    return result;
}

fn imap_perform_list(data: ?*Curl_easy, imap: *IMAP, imapc: *imap_conn) CURLcode {
    var result: CURLcode = CURLE_OK;
    if (imap.custom) |custom_ptr| {
        const custom_s = std.mem.span(custom_ptr);
        const params_s = cStrSlice(imap.custom_params);
        result = imap_sendf(data, imapc, "{s}{s}", .{ custom_s, params_s });
    } else {
        const mailbox = if (imap.mailbox) |mb|
            imap_atom(mb, true)
        else
            mem.strdup("");
        if (mailbox == null) return CURLE_OUT_OF_MEMORY;
        defer mem.free(@ptrCast(mailbox.?));
        const mb_s = std.mem.span(mailbox.?);
        result = imap_sendf(data, imapc, "LIST \"{s}\" *", .{mb_s});
    }

    if (result == CURLE_OK) {
        imap_state(data, imapc, .IMAP_LIST);
    }
    return result;
}

fn imap_perform_select(data: ?*Curl_easy, imap: *IMAP, imapc: *imap_conn) CURLcode {
    freeOptStr(&imapc.mailbox);
    imapc.mb_uidvalidity_set = false;

    if (imap.mailbox == null) {
        failfFmt(data, "Cannot SELECT without a mailbox.", .{});
        return CURLE_URL_MALFORMAT;
    }

    const mailbox = imap_atom(imap.mailbox, false) orelse return CURLE_OUT_OF_MEMORY;
    defer mem.free(@ptrCast(mailbox));

    const mb_s = std.mem.span(mailbox);
    const result = imap_sendf(data, imapc, "SELECT {s}", .{mb_s});
    if (result == CURLE_OK) {
        imap_state(data, imapc, .IMAP_SELECT);
    }
    return result;
}

fn imap_perform_fetch(data: ?*Curl_easy, imap: *IMAP, imapc: *imap_conn) CURLcode {
    var result: CURLcode = CURLE_OK;
    const section_s = cStrSlice(imap.section);

    if (imap.uid) |uid_ptr| {
        const uid_s = std.mem.span(uid_ptr);
        if (imap.partial) |partial_ptr| {
            const partial_s = std.mem.span(partial_ptr);
            result = imap_sendf(data, imapc, "UID FETCH {s} BODY[{s}]<{s}>", .{ uid_s, section_s, partial_s });
        } else {
            result = imap_sendf(data, imapc, "UID FETCH {s} BODY[{s}]", .{ uid_s, section_s });
        }
    } else if (imap.mindex) |mindex_ptr| {
        const mindex_s = std.mem.span(mindex_ptr);
        if (imap.partial) |partial_ptr| {
            const partial_s = std.mem.span(partial_ptr);
            result = imap_sendf(data, imapc, "FETCH {s} BODY[{s}]<{s}>", .{ mindex_s, section_s, partial_s });
        } else {
            result = imap_sendf(data, imapc, "FETCH {s} BODY[{s}]", .{ mindex_s, section_s });
        }
    } else {
        failfFmt(data, "Cannot FETCH without a UID.", .{});
        return CURLE_URL_MALFORMAT;
    }

    if (result == CURLE_OK) {
        imap_state(data, imapc, .IMAP_FETCH);
    }
    return result;
}

fn imap_perform_append(data: ?*Curl_easy, imap: *IMAP, imapc: *imap_conn) CURLcode {
    if (imap.mailbox == null) {
        failfFmt(data, "Cannot APPEND without a mailbox.", .{});
        return CURLE_URL_MALFORMAT;
    }

    var infilesize: curl_off_t = -1;
    var crlf: bool = false;
    var upload_flags: u8 = 0;
    var result = Curl_imap_ws_prepare_append(data, &infilesize, &crlf, &upload_flags);
    if (result != CURLE_OK) return result;

    if (infilesize < 0) {
        if (crlf) {
            failfFmt(data, "Cannot APPEND with CRLF conversion making size unknown", .{});
        } else {
            failfFmt(data, "Cannot APPEND with unknown input file size", .{});
        }
        return CURLE_UPLOAD_FAILED;
    }

    const mailbox = imap_atom(imap.mailbox, false) orelse return CURLE_OUT_OF_MEMORY;
    defer mem.free(@ptrCast(mailbox));

    const ulbits_table = [_]struct { bit: u8, flag: []const u8 }{
        .{ .bit = CURLULFLAG_ANSWERED, .flag = "Answered" },
        .{ .bit = CURLULFLAG_DELETED, .flag = "Deleted" },
        .{ .bit = CURLULFLAG_DRAFT, .flag = "Draft" },
        .{ .bit = CURLULFLAG_FLAGGED, .flag = "Flagged" },
        .{ .bit = CURLULFLAG_SEEN, .flag = "Seen" },
    };

    var flags_buf: [64]u8 = undefined;
    var flags_len: usize = 0;
    if (upload_flags != 0) {
        var sep: u8 = '(';
        flags_buf[0] = ' ';
        flags_len = 1;
        for (ulbits_table) |entry| {
            if ((upload_flags & entry.bit) != 0) {
                const part = std.fmt.bufPrint(flags_buf[flags_len..], "{c}\\{s}", .{ sep, entry.flag }) catch break;
                flags_len += part.len;
                sep = ' ';
            }
        }
        flags_buf[flags_len] = ')';
        flags_len += 1;
    }
    const flags_s = flags_buf[0..flags_len];

    const mb_s = std.mem.span(mailbox);
    result = imap_sendf(data, imapc, "APPEND {s}{s} {{{d}}}", .{ mb_s, flags_s, infilesize });
    if (result == CURLE_OK) {
        imap_state(data, imapc, .IMAP_APPEND);
    }
    return result;
}

fn imap_perform_search(data: ?*Curl_easy, imap: *IMAP, imapc: *imap_conn) CURLcode {
    if (imap.query == null) {
        failfFmt(data, "Cannot SEARCH without a query string.", .{});
        return CURLE_URL_MALFORMAT;
    }

    const query_s = std.mem.span(imap.query.?);
    const result = imap_sendf(data, imapc, "SEARCH {s}", .{query_s});
    if (result == CURLE_OK) {
        imap_state(data, imapc, .IMAP_SEARCH);
    }
    return result;
}

fn imap_perform_logout(data: ?*Curl_easy, imapc: *imap_conn) CURLcode {
    const result = imap_sendf(data, imapc, "LOGOUT", .{});
    if (result == CURLE_OK) {
        imap_state(data, imapc, .IMAP_LOGOUT);
    }
    return result;
}

fn imap_state_servergreet_resp(data: ?*Curl_easy, imapc: *imap_conn, imapcode: c_int, line: [*:0]const u8) CURLcode {
    _ = line;
    if (imapcode == IMAP_RESP_PREAUTH) {
        imapc.preauth = true;
        infofFmt(data, "PREAUTH connection, already authenticated", .{});
    } else if (imapcode != IMAP_RESP_OK) {
        failfFmt(data, "Got unexpected imap-server response", .{});
        return CURLE_WEIRD_SERVER_REPLY;
    }
    return imap_perform_capability(data, imapc);
}

fn imap_state_capability_resp(data: ?*Curl_easy, imapc: *imap_conn, imapcode: c_int, line_in: [*:0]const u8) CURLcode {
    var result: CURLcode = CURLE_OK;
    const conn = Curl_imap_ws_easy_conn(data);
    var line: [*:0]const u8 = line_in;

    if (imapcode == '*') {
        line += 2;
        while (true) {
            while (line[0] != 0 and (line[0] == ' ' or line[0] == '\t' or line[0] == '\r' or line[0] == '\n')) {
                line += 1;
            }
            if (line[0] == 0) break;

            var wordlen: usize = 0;
            while (line[wordlen] != 0 and line[wordlen] != ' ' and line[wordlen] != '\t' and line[wordlen] != '\r' and line[wordlen] != '\n') : (wordlen += 1) {}

            if (wordlen == 8 and primitives.curl_strnequal(line, "STARTTLS", 8) != 0) {
                imapc.tls_supported = true;
            } else if (wordlen == 13 and primitives.curl_strnequal(line, "LOGINDISABLED", 13) != 0) {
                imapc.login_disabled = true;
            } else if (wordlen == 7 and primitives.curl_strnequal(line, "SASL-IR", 7) != 0) {
                imapc.ir_supported = true;
            } else if (wordlen > 5 and primitives.curl_strnequal(line, "AUTH=", 5) != 0) {
                var llen: usize = 0;
                const mechbit = Curl_sasl_decode_mech(line + 5, wordlen - 5, &llen);
                if (mechbit != 0 and llen == wordlen - 5) {
                    const cur = Curl_imap_ws_sasl_get_authmechs(&imapc.sasl);
                    Curl_imap_ws_sasl_set_authmechs(&imapc.sasl, cur | mechbit);
                }
            }

            line += wordlen;
        }
    } else if (Curl_imap_ws_get_use_ssl(data) != CURLUSESSL_NONE and !Curl_conn_is_ssl(conn, FIRSTSOCKET)) {
        if (imapcode == IMAP_RESP_OK and imapc.tls_supported and !imapc.preauth) {
            result = imap_perform_starttls(data, imapc);
        } else if (Curl_imap_ws_get_use_ssl(data) <= CURLUSESSL_TRY) {
            result = imap_perform_authentication(data, imapc);
        } else {
            failfFmt(data, "STARTTLS not available.", .{});
            result = CURLE_USE_SSL_FAILED;
        }
    } else {
        result = imap_perform_authentication(data, imapc);
    }

    return result;
}

fn imap_state_starttls_resp(data: ?*Curl_easy, imapc: *imap_conn, imapcode: c_int, line: [*:0]const u8) CURLcode {
    _ = line;
    if (imapc.pp.overflow != 0) {
        return CURLE_WEIRD_SERVER_REPLY;
    }

    if (imapcode != IMAP_RESP_OK) {
        if (Curl_imap_ws_get_use_ssl(data) != CURLUSESSL_TRY) {
            failfFmt(data, "STARTTLS denied", .{});
            return CURLE_USE_SSL_FAILED;
        }
        return imap_perform_authentication(data, imapc);
    }

    imap_state(data, imapc, .IMAP_UPGRADETLS);
    return CURLE_OK;
}

fn imap_state_auth_resp(data: ?*Curl_easy, conn: ?*connectdata, imapc: *imap_conn, imapcode: c_int, line: [*:0]const u8) CURLcode {
    _ = line;
    var progress: c_uint = SASL_IDLE;
    var result = Curl_sasl_continue(&imapc.sasl, data, imapcode, &progress);
    if (result == CURLE_OK) {
        switch (progress) {
            SASL_DONE => imap_state(data, imapc, .IMAP_STOP),
            SASL_IDLE => {
                if (!imapc.login_disabled and (imapc.preftype & IMAP_TYPE_CLEARTEXT) != 0) {
                    result = imap_perform_login(data, imapc, conn);
                } else {
                    failfFmt(data, "Authentication cancelled", .{});
                    result = CURLE_LOGIN_DENIED;
                }
            },
            else => {},
        }
    }
    return result;
}

fn imap_state_login_resp(data: ?*Curl_easy, imapc: *imap_conn, imapcode: c_int, line: [*:0]const u8) CURLcode {
    _ = line;
    if (imapcode != IMAP_RESP_OK) {
        failfFmt(data, "Access denied. {c}", .{@as(u8, @intCast(imapcode & 0xff))});
        return CURLE_LOGIN_DENIED;
    }
    imap_state(data, imapc, .IMAP_STOP);
    return CURLE_OK;
}

fn imap_find_literal(line_in: [*]const u8, len_in: usize) ?[*:0]const u8 {
    var slice = line_in[0..len_in];
    var quoted: bool = false;

    while (slice.len > 0) {
        if (quoted) {
            if (slice[0] == '\\' and slice.len > 1) {
                slice = slice[2..];
                continue;
            } else if (slice[0] == '"') {
                quoted = false;
            }
        } else if (slice[0] == '"') {
            quoted = true;
        } else if (slice[0] == '{') {
            return @ptrCast(slice.ptr);
        }
        slice = slice[1..];
    }
    return null;
}

pub fn imap_parse_literal(line_slice: []const u8) ?curl_off_t {
    const lit_ptr = imap_find_literal(line_slice.ptr, line_slice.len) orelse return null;
    const offset = @intFromPtr(lit_ptr) - @intFromPtr(line_slice.ptr);
    if (offset >= line_slice.len) return null;
    const rem = line_slice[offset + 1 ..];
    if (rem.len < 2) return null;

    var idx: usize = 0;
    var acc: curl_off_t = 0;
    while (idx < rem.len and rem[idx] >= '0' and rem[idx] <= '9') : (idx += 1) {
        const digit = std.math.cast(curl_off_t, rem[idx] - '0') orelse return null;
        const scaled = std.math.mul(curl_off_t, acc, 10) catch return null;
        acc = std.math.add(curl_off_t, scaled, digit) catch return null;
    }
    if (idx == 0 or idx >= rem.len or rem[idx] != '}') return null;
    if (idx + 1 < rem.len and rem[idx + 1] != '\r' and rem[idx + 1] != '\n') return null;
    return acc;
}

fn imap_state_listsearch_resp(data: ?*Curl_easy, imap: *IMAP, imapc: *imap_conn, imapcode: c_int, line_in: [*:0]const u8) CURLcode {
    var result: CURLcode = CURLE_OK;
    const line: [*:0]const u8 = line_in;
    const len = imapc.pp.nfinal;

    if (imapcode == '*' and is_custom_fetch_listing(imap)) {
        // custom FETCH or UID FETCH for listing is not handled here
    } else if (imapcode == '*') {
        const line_slice = line[0..len];
        const line_len = std.mem.indexOfScalar(u8, line_slice, '\r') orelse len;
        if (imap_parse_literal(line_slice[0..line_len])) |parsed_size| {
            var size = parsed_size;
            const pp = &imapc.pp;
            const buffer_len = containers.curlx_dyn_len(&pp.recvbuf);
            const after_header = if (buffer_len >= pp.nfinal) buffer_len - pp.nfinal else 0;

            infofFmt(data, "Found {d} bytes to download", .{size});

            result = Curl_client_write(data, CLIENTWRITE_BODY, line, len);
            if (result != CURLE_OK) return result;

            if (after_header > 0) {
                var chunk = after_header;
                _ = curlx_dyn_tail(&pp.recvbuf, chunk);
                pp.nfinal = 0;

                const size_uz = std.math.cast(usize, size) orelse std.math.maxInt(usize);
                if (chunk > size_uz) {
                    chunk = size_uz;
                }

                if (chunk > 0) {
                    const recv_ptr = containers.curlx_dyn_ptr(&pp.recvbuf) orelse return CURLE_WEIRD_SERVER_REPLY;
                    result = Curl_client_write(data, CLIENTWRITE_BODY, recv_ptr, chunk);
                    if (result != CURLE_OK) return result;

                    const chunk_off = std.math.cast(curl_off_t, chunk) orelse return CURLE_WEIRD_SERVER_REPLY;
                    infofFmt(data, "Written {d} bytes, {d} bytes are left for transfer", .{ chunk, size - chunk_off });
                }

                if (after_header > chunk) {
                    pp.overflow = after_header - chunk;
                    _ = curlx_dyn_tail(&pp.recvbuf, pp.overflow);
                } else {
                    pp.overflow = 0;
                    containers.curlx_dyn_reset(&pp.recvbuf);
                }
            } else {
                pp.overflow = 0;
            }

            const len_off = std.math.cast(curl_off_t, len) orelse std.math.maxInt(curl_off_t);
            size = std.math.add(curl_off_t, size, len_off) catch std.math.maxInt(curl_off_t);

            Curl_pgrsSetDownloadSize(data, size);

            if (Curl_imap_ws_get_req_bytecount(data) == size) {
                Curl_xfer_setup_nop(data);
            } else {
                Curl_imap_ws_set_req_maxdownload(data, size);
                Curl_xfer_setup_recv(data, FIRSTSOCKET, size);
            }
            imap_state(data, imapc, .IMAP_STOP);
        } else {
            result = Curl_client_write(data, CLIENTWRITE_BODY, line, len);
        }
    } else if (imapcode != IMAP_RESP_OK) {
        result = CURLE_QUOTE_ERROR;
    } else {
        imap_state(data, imapc, .IMAP_STOP);
    }

    return result;
}

fn imap_state_select_resp(data: ?*Curl_easy, imap: *IMAP, imapc: *imap_conn, imapcode: c_int, line: [*:0]const u8) CURLcode {
    var result: CURLcode = CURLE_OK;

    if (imapcode == '*') {
        const len = containers.curlx_dyn_len(&imapc.pp.recvbuf);
        if (len >= 18 and primitives.curl_strnequal(line + 2, "OK [UIDVALIDITY ", 16) != 0) {
            var p: [*:0]const u8 = line + 2 + 16;
            var uv: curl_off_t = 0;
            if (curlx_str_number(&p, &uv, std.math.maxInt(u32)) == 0) {
                imapc.mb_uidvalidity = @intCast(uv);
                imapc.mb_uidvalidity_set = true;
            }
        }
    } else if (imapcode == IMAP_RESP_OK) {
        if (imap.uidvalidity_set and imapc.mb_uidvalidity_set and (imap.uidvalidity != imapc.mb_uidvalidity)) {
            failfFmt(data, "Mailbox UIDVALIDITY has changed", .{});
            result = CURLE_REMOTE_FILE_NOT_FOUND;
        } else {
            if (imapc.mailbox == null) {
                if (imap.mailbox) |mb| {
                    imapc.mailbox = mem.strdup(mb);
                    if (imapc.mailbox == null) return CURLE_OUT_OF_MEMORY;
                }
            }

            if (imap.custom != null) {
                result = imap_perform_list(data, imap, imapc);
            } else if (imap.query != null) {
                result = imap_perform_search(data, imap, imapc);
            } else {
                result = imap_perform_fetch(data, imap, imapc);
            }
        }
    } else {
        failfFmt(data, "Select failed", .{});
        result = CURLE_LOGIN_DENIED;
    }

    return result;
}

fn imap_state_fetch_resp(data: ?*Curl_easy, imap: *IMAP, imapc: *imap_conn, imapcode: c_int, line: [*:0]const u8) CURLcode {
    _ = imap;
    var result: CURLcode = CURLE_OK;
    var parsed: bool = false;
    var size: curl_off_t = 0;
    const pp = &imapc.pp;

    if (imapcode != '*') {
        Curl_pgrsSetDownloadSize(data, -1);
        imap_state(data, imapc, .IMAP_STOP);
        return CURLE_REMOTE_FILE_NOT_FOUND;
    }

    const len = pp.nfinal;
    if (imap_parse_literal(line[0..len])) |parsed_size| {
        size = parsed_size;
        parsed = true;
    }

    if (parsed) {
        infofFmt(data, "Found {d} bytes to download", .{size});
        Curl_pgrsSetDownloadSize(data, size);

        if (pp.overflow > 0) {
            var chunk = pp.overflow;
            _ = curlx_dyn_tail(&pp.recvbuf, chunk);
            pp.nfinal = 0;

            const size_uz = std.math.cast(usize, size) orelse std.math.maxInt(usize);
            if (chunk > size_uz) {
                chunk = size_uz;
            }

            if (chunk == 0) {
                imap_state(data, imapc, .IMAP_STOP);
                return CURLE_OK;
            }

            const recv_ptr = containers.curlx_dyn_ptr(&pp.recvbuf) orelse return CURLE_WEIRD_SERVER_REPLY;
            result = Curl_client_write(data, CLIENTWRITE_BODY, recv_ptr, chunk);
            if (result != CURLE_OK) return result;

            const chunk_off = std.math.cast(curl_off_t, chunk) orelse return CURLE_WEIRD_SERVER_REPLY;
            infofFmt(data, "Written {d} bytes, {d} bytes are left for transfer", .{ chunk, size - chunk_off });

            if (pp.overflow > chunk) {
                pp.overflow -= chunk;
                _ = curlx_dyn_tail(&pp.recvbuf, pp.overflow);
            } else {
                pp.overflow = 0;
                containers.curlx_dyn_reset(&pp.recvbuf);
            }
        }

        if (Curl_imap_ws_get_req_bytecount(data) == size) {
            Curl_xfer_setup_nop(data);
        } else {
            Curl_imap_ws_set_req_maxdownload(data, size);
            Curl_xfer_setup_recv(data, FIRSTSOCKET, size);
        }
        imap_state(data, imapc, .IMAP_STOP);
    } else {
        failfFmt(data, "Failed to parse FETCH response.", .{});
        result = CURLE_WEIRD_SERVER_REPLY;
    }

    imap_state(data, imapc, .IMAP_STOP);
    return result;
}

fn imap_state_fetch_final_resp(data: ?*Curl_easy, imapc: *imap_conn, imapcode: c_int, line: [*:0]const u8) CURLcode {
    _ = line;
    var result: CURLcode = CURLE_OK;
    if (imapcode != IMAP_RESP_OK) {
        result = CURLE_WEIRD_SERVER_REPLY;
    } else {
        imap_state(data, imapc, .IMAP_STOP);
    }
    return result;
}

fn imap_state_append_resp(data: ?*Curl_easy, imapc: *imap_conn, imapcode: c_int, line: [*:0]const u8) CURLcode {
    _ = line;
    if (imapcode != '+') {
        imap_state(data, imapc, .IMAP_STOP);
        return CURLE_UPLOAD_FAILED;
    }

    Curl_pgrsSetUploadSize(data, Curl_imap_ws_get_infilesize(data));
    Curl_xfer_setup_send(data, FIRSTSOCKET);
    imap_state(data, imapc, .IMAP_STOP);
    return CURLE_OK;
}

fn imap_state_append_final_resp(data: ?*Curl_easy, imapc: *imap_conn, imapcode: c_int, line: [*:0]const u8) CURLcode {
    _ = line;
    var result: CURLcode = CURLE_OK;
    if (imapcode != IMAP_RESP_OK) {
        result = CURLE_UPLOAD_FAILED;
    } else {
        imap_state(data, imapc, .IMAP_STOP);
    }
    return result;
}

fn imap_pp_statemachine(data: ?*Curl_easy, conn: ?*connectdata) callconv(.c) CURLcode {
    var result: CURLcode = CURLE_OK;
    var imapcode: c_int = 0;
    var nread: usize = 0;

    const imap_ptr = Curl_meta_get(data, CURL_META_IMAP_EASY) orelse return CURLE_FAILED_INIT;
    const imap: *IMAP = @ptrCast(@alignCast(imap_ptr));
    const imapc_ptr = Curl_conn_meta_get(conn, CURL_META_IMAP_CONN) orelse return CURLE_FAILED_INIT;
    const imapc: *imap_conn = @ptrCast(@alignCast(imapc_ptr));
    const pp = &imapc.pp;

    if (imapc.state == .IMAP_UPGRADETLS) {
        return imap_perform_upgrade_tls(data, imapc, conn);
    }

    if (pp.sendleft != 0) {
        return Curl_pp_flushsend(data, pp);
    }

    while (true) {
        result = Curl_imap_ws_pp_readresp(data, FIRSTSOCKET, pp, &imapcode, &nread);
        if (result != CURLE_OK) return result;

        if (imapcode == -1) return CURLE_WEIRD_SERVER_REPLY;
        if (imapcode == 0) break;

        const line: [*:0]const u8 = @ptrCast(containers.curlx_dyn_ptr(&pp.recvbuf) orelse "");

        switch (imapc.state) {
            .IMAP_SERVERGREET => result = imap_state_servergreet_resp(data, imapc, imapcode, line),
            .IMAP_CAPABILITY => result = imap_state_capability_resp(data, imapc, imapcode, line),
            .IMAP_STARTTLS => result = imap_state_starttls_resp(data, imapc, imapcode, line),
            .IMAP_AUTHENTICATE => result = imap_state_auth_resp(data, conn, imapc, imapcode, line),
            .IMAP_LOGIN => result = imap_state_login_resp(data, imapc, imapcode, line),
            .IMAP_LIST, .IMAP_SEARCH => result = imap_state_listsearch_resp(data, imap, imapc, imapcode, line),
            .IMAP_SELECT => result = imap_state_select_resp(data, imap, imapc, imapcode, line),
            .IMAP_FETCH => result = imap_state_fetch_resp(data, imap, imapc, imapcode, line),
            .IMAP_FETCH_FINAL => result = imap_state_fetch_final_resp(data, imapc, imapcode, line),
            .IMAP_APPEND => result = imap_state_append_resp(data, imapc, imapcode, line),
            .IMAP_APPEND_FINAL => result = imap_state_append_final_resp(data, imapc, imapcode, line),
            .IMAP_LOGOUT => imap_state(data, imapc, .IMAP_STOP),
            else => imap_state(data, imapc, .IMAP_STOP),
        }

        if (result == CURLE_OK and imapc.state == .IMAP_UPGRADETLS) {
            return imap_perform_upgrade_tls(data, imapc, conn);
        }

        if (result != CURLE_OK or imapc.state == .IMAP_STOP or !Curl_pp_moredata(pp)) {
            break;
        }
    }

    return result;
}

fn imap_multi_statemach(data: ?*Curl_easy, done: *bool) callconv(.c) CURLcode {
    const conn = Curl_imap_ws_easy_conn(data);
    const imapc_ptr = Curl_conn_meta_get(conn, CURL_META_IMAP_CONN) orelse return CURLE_FAILED_INIT;
    const imapc: *imap_conn = @ptrCast(@alignCast(imapc_ptr));

    const result = Curl_imap_ws_pp_statemach(data, &imapc.pp, false, false);
    done.* = (imapc.state == .IMAP_STOP);
    return result;
}

fn imap_block_statemach(data: ?*Curl_easy, imapc: *imap_conn, disconnecting: bool) CURLcode {
    var result: CURLcode = CURLE_OK;
    while (imapc.state != .IMAP_STOP and result == CURLE_OK) {
        result = Curl_imap_ws_pp_statemach(data, &imapc.pp, true, disconnecting);
    }
    return result;
}

fn imap_easy_dtor(key: [*:0]const u8, klen: usize, entry: ?*anyopaque) callconv(.c) void {
    _ = key;
    _ = klen;
    const p = entry orelse return;
    const imap: *IMAP = @ptrCast(@alignCast(p));
    freeOptStr(&imap.mailbox);
    freeOptStr(&imap.uid);
    freeOptStr(&imap.mindex);
    freeOptStr(&imap.section);
    freeOptStr(&imap.partial);
    freeOptStr(&imap.query);
    freeOptStr(&imap.custom);
    freeOptStr(&imap.custom_params);
    mem.freeSized(p, @sizeOf(IMAP));
}

fn imap_conn_dtor(key: [*:0]const u8, klen: usize, entry: ?*anyopaque) callconv(.c) void {
    _ = key;
    _ = klen;
    const p = entry orelse return;
    const imapc: *imap_conn = @ptrCast(@alignCast(p));
    _ = Curl_pp_disconnect(&imapc.pp);
    freeOptStr(&imapc.mailbox);
    mem.freeSized(p, @sizeOf(imap_conn));
}

fn imap_pollset(data: ?*Curl_easy, ps: ?*easy_pollset) callconv(.c) CURLcode {
    const conn = Curl_imap_ws_easy_conn(data);
    const imapc_ptr = Curl_conn_meta_get(conn, CURL_META_IMAP_CONN) orelse return CURLE_FAILED_INIT;
    const imapc: *imap_conn = @ptrCast(@alignCast(imapc_ptr));
    return Curl_imap_ws_pp_pollset(data, &imapc.pp, ps);
}

fn imap_connect(data: ?*Curl_easy, done: *bool) callconv(.c) CURLcode {
    const conn = Curl_imap_ws_easy_conn(data);
    const imapc_ptr = Curl_conn_meta_get(conn, CURL_META_IMAP_CONN) orelse return CURLE_FAILED_INIT;
    const imapc: *imap_conn = @ptrCast(@alignCast(imapc_ptr));

    done.* = false;

    const result = imap_parse_url_options(conn, imapc);
    if (result != CURLE_OK) return result;

    imap_state(data, imapc, .IMAP_SERVERGREET);
    primitives.curlx_strcopy(&imapc.resptag, @sizeOf(@TypeOf(imapc.resptag)), "*", 1);

    return imap_multi_statemach(data, done);
}

fn imap_done(data: ?*Curl_easy, status: CURLcode, premature: bool) callconv(.c) CURLcode {
    var result: CURLcode = CURLE_OK;
    const conn = Curl_imap_ws_easy_conn(data);
    const imap_ptr = Curl_meta_get(data, CURL_META_IMAP_EASY);
    const imapc_ptr = Curl_conn_meta_get(conn, CURL_META_IMAP_CONN);

    if (imap_ptr == null) return CURLE_OK;
    const imap: *IMAP = @ptrCast(@alignCast(imap_ptr.?));
    if (imapc_ptr == null) return CURLE_FAILED_INIT;
    const imapc: *imap_conn = @ptrCast(@alignCast(imapc_ptr.?));

    if (status != CURLE_OK or premature) {
        Curl_imap_ws_connclose(conn);
        result = status;
    } else if (!Curl_imap_ws_get_connect_only(data) and
        ((imap.custom == null and (imap.uid != null or imap.mindex != null)) or
            (imap.custom != null and Curl_imap_ws_get_req_maxdownload(data) > 0) or
            Curl_imap_ws_is_upload_or_mime(data)))
    {
        if (!Curl_imap_ws_is_upload_or_mime(data)) {
            imap_state(data, imapc, .IMAP_FETCH_FINAL);
        } else {
            result = imap_pp_sendf(data, &imapc.pp, "", .{});
            if (result == CURLE_OK) {
                imap_state(data, imapc, .IMAP_APPEND_FINAL);
            }
        }

        if (result == CURLE_OK) {
            result = imap_block_statemach(data, imapc, false);
        }
    }

    freeOptStr(&imap.mailbox);
    freeOptStr(&imap.uid);
    freeOptStr(&imap.mindex);
    freeOptStr(&imap.section);
    freeOptStr(&imap.partial);
    freeOptStr(&imap.query);
    freeOptStr(&imap.custom);
    freeOptStr(&imap.custom_params);
    imap.uidvalidity_set = false;
    imap.transfer = PPTRANSFER_BODY;

    return result;
}

fn imap_perform(data: ?*Curl_easy, imap: *IMAP, imapc: *imap_conn, connected: *bool, dophase_done: *bool) CURLcode {
    var result: CURLcode = CURLE_OK;
    const conn = Curl_imap_ws_easy_conn(data);
    var selected: bool = false;

    if (Curl_imap_ws_get_req_no_body(data)) {
        imap.transfer = PPTRANSFER_INFO;
    }

    dophase_done.* = false;

    if (imap.mailbox != null and imapc.mailbox != null and
        (std.mem.eql(u8, std.mem.span(imap.mailbox.?), std.mem.span(imapc.mailbox.?)) or
            (primitives.curl_strequal(imap.mailbox.?, "INBOX") != 0 and
                primitives.curl_strequal(imapc.mailbox.?, "INBOX") != 0)) and
        (!imap.uidvalidity_set or !imapc.mb_uidvalidity_set or (imap.uidvalidity == imapc.mb_uidvalidity)))
    {
        selected = true;
    }

    if (Curl_imap_ws_is_upload_or_mime(data)) {
        result = imap_perform_append(data, imap, imapc);
    } else if (imap.custom != null and (selected or imap.mailbox == null)) {
        result = imap_perform_list(data, imap, imapc);
    } else if (imap.custom == null and selected and (imap.uid != null or imap.mindex != null)) {
        result = imap_perform_fetch(data, imap, imapc);
    } else if (imap.custom == null and selected and imap.query != null) {
        result = imap_perform_search(data, imap, imapc);
    } else if (imap.mailbox != null and !selected and
        (imap.custom != null or imap.uid != null or imap.mindex != null or imap.query != null))
    {
        result = imap_perform_select(data, imap, imapc);
    } else {
        result = imap_perform_list(data, imap, imapc);
    }

    if (result != CURLE_OK) return result;

    result = imap_multi_statemach(data, dophase_done);
    connected.* = Curl_conn_is_connected(conn, FIRSTSOCKET);

    if (dophase_done.*) {
        trcMFmt(data, "DO phase is complete1", .{});
    }

    return result;
}

fn imap_do(data: ?*Curl_easy, done: *bool) callconv(.c) CURLcode {
    const imap_ptr = Curl_meta_get(data, CURL_META_IMAP_EASY) orelse return CURLE_FAILED_INIT;
    const imap: *IMAP = @ptrCast(@alignCast(imap_ptr));
    const conn = Curl_imap_ws_easy_conn(data);
    const imapc_ptr = Curl_conn_meta_get(conn, CURL_META_IMAP_CONN) orelse return CURLE_FAILED_INIT;
    const imapc: *imap_conn = @ptrCast(@alignCast(imapc_ptr));

    done.* = false;

    var result = imap_parse_url_path(data, imap);
    if (result != CURLE_OK) return result;

    result = imap_parse_custom_request(data, imap);
    if (result != CURLE_OK) return result;

    return imap_regular_transfer(data, imap, imapc, done);
}

fn imap_disconnect(data: ?*Curl_easy, conn: ?*connectdata, dead_connection: bool) callconv(.c) CURLcode {
    const imapc_ptr = Curl_conn_meta_get(conn, CURL_META_IMAP_CONN);
    if (imapc_ptr) |p| {
        const imapc: *imap_conn = @ptrCast(@alignCast(p));
        if (!dead_connection and Curl_imap_ws_conn_protoconnstart(conn) and
            !Curl_pp_needs_flush(data, &imapc.pp) and
            imap_perform_logout(data, imapc) == CURLE_OK)
        {
            _ = imap_block_statemach(data, imapc, true);
        }
    }
    return CURLE_OK;
}

fn imap_dophase_done(data: ?*Curl_easy, imap: *IMAP, connected: bool) CURLcode {
    _ = connected;
    if (imap.transfer != PPTRANSFER_BODY) {
        Curl_xfer_setup_nop(data);
    }
    return CURLE_OK;
}

fn imap_doing(data: ?*Curl_easy, dophase_done: *bool) callconv(.c) CURLcode {
    const imap_ptr = Curl_meta_get(data, CURL_META_IMAP_EASY) orelse return CURLE_FAILED_INIT;
    const imap: *IMAP = @ptrCast(@alignCast(imap_ptr));

    var result = imap_multi_statemach(data, dophase_done);
    if (result != CURLE_OK) {
        trcMFmt(data, "DO phase failed", .{});
    } else if (dophase_done.*) {
        result = imap_dophase_done(data, imap, false);
        trcMFmt(data, "DO phase is complete2", .{});
    }
    return result;
}

fn imap_regular_transfer(data: ?*Curl_easy, imap: *IMAP, imapc: *imap_conn, dophase_done: *bool) CURLcode {
    var result: CURLcode = CURLE_OK;
    var connected: bool = false;

    Curl_imap_ws_set_req_size(data, -1);
    Curl_pgrsReset(data);

    result = imap_perform(data, imap, imapc, &connected, dophase_done);
    if (result == CURLE_OK and dophase_done.*) {
        result = imap_dophase_done(data, imap, connected);
    }
    return result;
}

fn imap_setup_connection(data: ?*Curl_easy, conn: ?*connectdata) callconv(.c) CURLcode {
    const raw_conn = mem.calloc(1, @sizeOf(imap_conn)) orelse return CURLE_OUT_OF_MEMORY;
    const imapc: *imap_conn = @ptrCast(@alignCast(raw_conn));

    imapc.pp.statemachine = imap_pp_statemachine;
    imapc.pp.endofresp = imap_endofresp;
    imapc.preftype = IMAP_TYPE_ANY;
    Curl_sasl_init(&imapc.sasl, data, &saslimap);
    Curl_imap_ws_pp_init(data, &imapc.pp);

    const result = Curl_conn_meta_set(conn, CURL_META_IMAP_CONN, raw_conn, imap_conn_dtor);
    if (result != CURLE_OK) return result;

    const raw_easy = mem.calloc(1, @sizeOf(IMAP)) orelse return CURLE_OUT_OF_MEMORY;
    return Curl_meta_set(data, CURL_META_IMAP_EASY, raw_easy, imap_easy_dtor);
}

pub export const Curl_protocol_imap = Curl_protocol{
    .setup_connection = imap_setup_connection,
    .do_it = imap_do,
    .done = imap_done,
    .do_more = null,
    .connect_it = imap_connect,
    .connecting = imap_multi_statemach,
    .doing = imap_doing,
    .proto_pollset = imap_pollset,
    .doing_pollset = imap_pollset,
    .domore_pollset = null,
    .perform_pollset = null,
    .disconnect = imap_disconnect,
    .write_resp = null,
    .write_resp_hd = null,
    .connection_is_dead = null,
    .attach = null,
    .follow = null,
};

// ============================================================================
// Part 2: WebSocket Protocol & Framing (ported from lib/ws.c)
// ============================================================================

pub const curl_ws_frame = extern struct {
    age: c_int,
    flags: c_int,
    offset: curl_off_t,
    bytesleft: curl_off_t,
    len: usize,
};

const CURLWS_TEXT: c_uint = 1 << 0;
const CURLWS_BINARY: c_uint = 1 << 1;
const CURLWS_CONT: c_uint = 1 << 2;
const CURLWS_CLOSE: c_uint = 1 << 3;
const CURLWS_PING: c_uint = 1 << 4;
const CURLWS_OFFSET: c_uint = 1 << 5;
const CURLWS_PONG: c_uint = 1 << 6;

const WSBIT_FIN: u8 = 0x80;
const WSBIT_RSV1: u8 = 0x40;
const WSBIT_RSV2: u8 = 0x20;
const WSBIT_RSV3: u8 = 0x10;
const WSBIT_RSV_MASK: u8 = WSBIT_RSV1 | WSBIT_RSV2 | WSBIT_RSV3;
const WSBIT_OPCODE_CONT: u8 = 0x0;
const WSBIT_OPCODE_TEXT: u8 = 0x1;
const WSBIT_OPCODE_BIN: u8 = 0x2;
const WSBIT_OPCODE_CLOSE: u8 = 0x8;
const WSBIT_OPCODE_PING: u8 = 0x9;
const WSBIT_OPCODE_PONG: u8 = 0xa;
const WSBIT_OPCODE_MASK: u8 = 0xf;
const WSBIT_MASK: u8 = 0x80;

const WS_MAX_CNTRL_LEN: usize = 125;
const WS_CHUNK_SIZE: usize = 65535;
const WS_CHUNK_COUNT: usize = 2;

const CURL_META_PROTO_WS_CONN = "meta:proto:ws:conn";

const CURL_CW_CONTENT_DECODE: c_uint = 4;
const CURL_CR_CONTENT_ENCODE: c_uint = 3;

const CURL_EAPI_FN_ws_recv: c_uint = 15;
const CURL_EAPI_FN_ws_send: c_uint = 16;
const CURL_EAPI_FN_ws_start_frame: c_uint = 17;

const Curl_eapi_guard = extern struct {
    data: ?*Curl_easy = null,
    depth: u16 = 0,
};

const Curl_cwtype = extern struct {
    name: [*:0]const u8,
    alias: ?[*:0]const u8,
    flags: u8,
    do_init: *const fn (data: ?*Curl_easy, writer: *Curl_cwriter) callconv(.c) CURLcode,
    do_write: *const fn (data: ?*Curl_easy, writer: *Curl_cwriter, @"type": c_int, buf: [*]const u8, nbytes: usize) callconv(.c) CURLcode,
    do_flush: *const fn (data: ?*Curl_easy, writer: *Curl_cwriter) callconv(.c) CURLcode,
    do_close: *const fn (data: ?*Curl_easy, writer: *Curl_cwriter) callconv(.c) void,
    cwriter_size: usize,
};

const Curl_cwriter = extern struct {
    cwt: *const Curl_cwtype,
    next: ?*Curl_cwriter,
    ctx: *anyopaque,
    phase: c_uint,
};

const Curl_crtype = extern struct {
    name: [*:0]const u8,
    do_init: *const fn (data: ?*Curl_easy, reader: *Curl_creader) callconv(.c) CURLcode,
    do_read: *const fn (data: ?*Curl_easy, reader: *Curl_creader, buf: [*]u8, blen: usize, nread: *usize, eos: *bool) callconv(.c) CURLcode,
    do_close: *const fn (data: ?*Curl_easy, reader: *Curl_creader) callconv(.c) void,
    needs_rewind: *const fn (data: ?*Curl_easy, reader: *Curl_creader) callconv(.c) bool,
    total_length: *const fn (data: ?*Curl_easy, reader: *Curl_creader) callconv(.c) curl_off_t,
    resume_from: *const fn (data: ?*Curl_easy, reader: *Curl_creader, offset: curl_off_t) callconv(.c) CURLcode,
    cntrl: *const fn (data: ?*Curl_easy, reader: *Curl_creader, opcode: c_uint) callconv(.c) CURLcode,
    is_paused: *const fn (data: ?*Curl_easy, reader: *Curl_creader) callconv(.c) bool,
    done: *const fn (data: ?*Curl_easy, reader: *Curl_creader, premature: c_int) callconv(.c) void,
    creader_size: usize,
};

const Curl_creader = extern struct {
    crt: *const Curl_crtype,
    next: ?*Curl_creader,
    ctx: *anyopaque,
    phase: c_uint,
};

extern fn Curl_creader_read(data: ?*Curl_easy, reader: ?*Curl_creader, buf: [*]u8, blen: usize, nread: *usize, eos: *bool) callconv(.c) CURLcode;
extern fn Curl_creader_clear_eos(data: ?*Curl_easy, reader: ?*Curl_creader) callconv(.c) void;
extern fn Curl_creader_set_fread(data: ?*Curl_easy, len: curl_off_t) callconv(.c) CURLcode;
extern fn Curl_creader_create(preader: *?*Curl_creader, data: ?*Curl_easy, crt: *const Curl_crtype, phase: c_uint) callconv(.c) CURLcode;
extern fn Curl_creader_add(data: ?*Curl_easy, reader: *Curl_creader) callconv(.c) CURLcode;
extern fn Curl_creader_free(data: ?*Curl_easy, reader: *Curl_creader) callconv(.c) void;
extern fn Curl_creader_def_needs_rewind(data: ?*Curl_easy, reader: *Curl_creader) callconv(.c) bool;
extern fn Curl_creader_def_resume_from(data: ?*Curl_easy, reader: *Curl_creader, offset: curl_off_t) callconv(.c) CURLcode;
extern fn Curl_creader_def_cntrl(data: ?*Curl_easy, reader: *Curl_creader, opcode: c_uint) callconv(.c) CURLcode;
extern fn Curl_creader_def_is_paused(data: ?*Curl_easy, reader: *Curl_creader) callconv(.c) bool;
extern fn Curl_creader_def_done(data: ?*Curl_easy, reader: *Curl_creader, premature: c_int) callconv(.c) void;

extern fn Curl_rand_bytes(data: ?*Curl_easy, rnd: [*]u8, num: usize) callconv(.c) CURLcode;

extern fn Curl_eapi_enter(guard: *Curl_eapi_guard, curl: ?*Curl_easy, @"fn": c_uint, presult: *CURLcode) callconv(.c) bool;
extern fn Curl_eapi_leave(guard: *Curl_eapi_guard) callconv(.c) void;
extern fn Curl_api_is_in_callback(data: ?*Curl_easy) callconv(.c) bool;

extern fn Curl_cwriter_create(pwriter: *?*Curl_cwriter, data: ?*Curl_easy, ce_handler: *const Curl_cwtype, phase: c_uint) callconv(.c) CURLcode;
extern fn Curl_cwriter_add(data: ?*Curl_easy, writer: *Curl_cwriter) callconv(.c) CURLcode;
extern fn Curl_cwriter_free(data: ?*Curl_easy, writer: *Curl_cwriter) callconv(.c) void;

extern fn Curl_checkheaders(data: ?*const Curl_easy, thisheader: [*]const u8, thislen: usize) callconv(.c) ?[*:0]u8;
extern fn Curl_cf_recvbuf_add(data: ?*Curl_easy, conn: ?*connectdata, sockindex: c_int, buf: [*]const u8, len: usize) callconv(.c) CURLcode;
extern fn Curl_easy_recv(data: ?*Curl_easy, buffer: ?*anyopaque, buflen: usize, n: *usize) callconv(.c) CURLcode;
extern fn Curl_getconnectinfo(data: ?*Curl_easy, connp: *?*connectdata) callconv(.c) curl_socket_t;
extern fn Curl_connect_only_attach(data: ?*Curl_easy) callconv(.c) CURLcode;
extern fn Curl_xfer_send(data: ?*Curl_easy, buf: ?*const anyopaque, blen: usize, eos: bool, pnwritten: *usize) callconv(.c) CURLcode;
extern fn Curl_timeleft_ms(data: ?*Curl_easy) callconv(.c) timediff_t;

extern fn Curl_http_setup_conn(data: ?*Curl_easy, conn: ?*connectdata) callconv(.c) CURLcode;
extern fn Curl_http(data: ?*Curl_easy, done: *bool) callconv(.c) CURLcode;
extern fn Curl_http_done(data: ?*Curl_easy, status: CURLcode, premature: bool) callconv(.c) CURLcode;
extern fn Curl_http_doing_pollset(data: ?*Curl_easy, ps: ?*easy_pollset) callconv(.c) CURLcode;
extern fn Curl_http_perform_pollset(data: ?*Curl_easy, ps: ?*easy_pollset) callconv(.c) CURLcode;
extern fn Curl_http_write_resp(data: ?*Curl_easy, buf: [*]const u8, blen: usize, is_eos: bool) callconv(.c) CURLcode;
extern fn Curl_http_write_resp_hd(data: ?*Curl_easy, hd: [*]const u8, hdlen: usize, is_eos: bool) callconv(.c) CURLcode;
extern fn Curl_http_follow(data: ?*Curl_easy, newurl: [*:0]const u8, @"type": c_uint) callconv(.c) CURLcode;

fn cwriter_write(data: ?*Curl_easy, writer: ?*Curl_cwriter, wtype: c_int, buf: [*]const u8, nbytes: usize) CURLcode {
    const w = writer orelse return CURLE_WRITE_ERROR;
    return w.cwt.do_write(data, w, wtype, buf, nbytes);
}

fn cwriter_flush(data: ?*Curl_easy, writer: ?*Curl_cwriter) CURLcode {
    const w = writer orelse return CURLE_WRITE_ERROR;
    return w.cwt.do_flush(data, w);
}

const ws_dec_state = enum(c_uint) {
    WS_DEC_INIT = 0,
    WS_DEC_HEAD,
    WS_DEC_PAYLOAD,
};

const ws_decoder = extern struct {
    frame_age: c_int,
    frame_flags: c_int,
    payload_offset: curl_off_t,
    payload_len: curl_off_t,
    head: [10]u8,
    head_len: c_int,
    head_total: c_int,
    state: ws_dec_state,
    cont_flags: c_int,
};

const ws_encoder = extern struct {
    payload_len: curl_off_t,
    payload_remain: curl_off_t,
    xori: c_uint,
    mask: [4]u8,
    firstbyte: u8,
    contfragment: bool,
};

const ws_cntrl_frame = extern struct {
    type: c_uint,
    payload_len: usize,
    payload: [WS_MAX_CNTRL_LEN]u8,
};

const websocket = extern struct {
    data: ?*Curl_easy,
    dec: ws_decoder,
    enc: ws_encoder,
    recvbuf: bufq,
    sendbuf: bufq,
    recvframe: curl_ws_frame,
    pending: ws_cntrl_frame,
    sendbuf_payload: usize,
    using_reader: bool,
    block_first_send: bool,
};

const ws_cw_ctx = extern struct {
    super: Curl_cwriter,
    buf: bufq,
};

fn ws_frame_name_of_op(firstbyte: u8) []const u8 {
    return switch (firstbyte & WSBIT_OPCODE_MASK) {
        WSBIT_OPCODE_CONT => "CONT",
        WSBIT_OPCODE_TEXT => "TEXT",
        WSBIT_OPCODE_BIN => "BIN",
        WSBIT_OPCODE_CLOSE => "CLOSE",
        WSBIT_OPCODE_PING => "PING",
        WSBIT_OPCODE_PONG => "PONG",
        else => "???",
    };
}

fn ws_frame_firstbyte2flags(data: ?*Curl_easy, firstbyte: u8, cont_flags: c_int) c_int {
    const ucont: c_uint = @bitCast(cont_flags);
    switch (firstbyte) {
        WSBIT_OPCODE_CONT => {
            if ((ucont & CURLWS_CONT) == 0) {
                failfFmt(data, "[WS] no ongoing fragmented message to resume", .{});
                return 0;
            }
            return @bitCast(ucont | CURLWS_CONT);
        },
        (WSBIT_OPCODE_CONT | WSBIT_FIN) => {
            if ((ucont & CURLWS_CONT) == 0) {
                failfFmt(data, "[WS] no ongoing fragmented message to resume", .{});
                return 0;
            }
            return @bitCast(ucont & ~CURLWS_CONT);
        },
        WSBIT_OPCODE_TEXT => {
            if ((ucont & CURLWS_CONT) != 0) {
                failfFmt(data, "[WS] fragmented message interrupted by new TEXT msg", .{});
                return 0;
            }
            return @bitCast(CURLWS_TEXT | CURLWS_CONT);
        },
        (WSBIT_OPCODE_TEXT | WSBIT_FIN) => {
            if ((ucont & CURLWS_CONT) != 0) {
                failfFmt(data, "[WS] fragmented message interrupted by new TEXT msg", .{});
                return 0;
            }
            return @bitCast(CURLWS_TEXT);
        },
        WSBIT_OPCODE_BIN => {
            if ((ucont & CURLWS_CONT) != 0) {
                failfFmt(data, "[WS] fragmented message interrupted by new BINARY msg", .{});
                return 0;
            }
            return @bitCast(CURLWS_BINARY | CURLWS_CONT);
        },
        (WSBIT_OPCODE_BIN | WSBIT_FIN) => {
            if ((ucont & CURLWS_CONT) != 0) {
                failfFmt(data, "[WS] fragmented message interrupted by new BINARY msg", .{});
                return 0;
            }
            return @bitCast(CURLWS_BINARY);
        },
        WSBIT_OPCODE_CLOSE => {
            failfFmt(data, "[WS] invalid fragmented CLOSE frame", .{});
            return 0;
        },
        (WSBIT_OPCODE_CLOSE | WSBIT_FIN) => return @bitCast(CURLWS_CLOSE),
        WSBIT_OPCODE_PING => {
            failfFmt(data, "[WS] invalid fragmented PING frame", .{});
            return 0;
        },
        (WSBIT_OPCODE_PING | WSBIT_FIN) => return @bitCast(CURLWS_PING),
        WSBIT_OPCODE_PONG => {
            failfFmt(data, "[WS] invalid fragmented PONG frame", .{});
            return 0;
        },
        (WSBIT_OPCODE_PONG | WSBIT_FIN) => return @bitCast(CURLWS_PONG),
        else => {
            if ((firstbyte & WSBIT_RSV_MASK) != 0) {
                failfFmt(data, "[WS] invalid reserved bits: {x:0>2}", .{firstbyte});
            } else {
                failfFmt(data, "[WS] invalid opcode: {x:0>2}", .{firstbyte});
            }
            return 0;
        },
    }
}

fn ws_frame_flags2firstbyte(
    data: ?*Curl_easy,
    flags: c_uint,
    contfragment: bool,
    pfirstbyte: *u8,
) CURLcode {
    pfirstbyte.* = 0;
    switch (flags & ~CURLWS_OFFSET) {
        0 => {
            if (contfragment) {
                trcWsFmt(data, "no flags given; interpreting as continuation fragment for compatibility", .{});
                pfirstbyte.* = WSBIT_OPCODE_CONT | WSBIT_FIN;
                return CURLE_OK;
            }
            failfFmt(data, "[WS] no flags given", .{});
            return CURLE_BAD_FUNCTION_ARGUMENT;
        },
        CURLWS_CONT => {
            if (contfragment) {
                infofFmt(data, "[WS] setting CURLWS_CONT flag without message type is supported for compatibility but highly discouraged", .{});
                pfirstbyte.* = WSBIT_OPCODE_CONT;
                return CURLE_OK;
            }
            failfFmt(data, "[WS] No ongoing fragmented message to continue", .{});
            return CURLE_BAD_FUNCTION_ARGUMENT;
        },
        CURLWS_TEXT => {
            pfirstbyte.* = if (contfragment) (WSBIT_OPCODE_CONT | WSBIT_FIN) else (WSBIT_OPCODE_TEXT | WSBIT_FIN);
            return CURLE_OK;
        },
        (CURLWS_TEXT | CURLWS_CONT) => {
            pfirstbyte.* = if (contfragment) WSBIT_OPCODE_CONT else WSBIT_OPCODE_TEXT;
            return CURLE_OK;
        },
        CURLWS_BINARY => {
            pfirstbyte.* = if (contfragment) (WSBIT_OPCODE_CONT | WSBIT_FIN) else (WSBIT_OPCODE_BIN | WSBIT_FIN);
            return CURLE_OK;
        },
        (CURLWS_BINARY | CURLWS_CONT) => {
            pfirstbyte.* = if (contfragment) WSBIT_OPCODE_CONT else WSBIT_OPCODE_BIN;
            return CURLE_OK;
        },
        CURLWS_CLOSE => {
            pfirstbyte.* = WSBIT_OPCODE_CLOSE | WSBIT_FIN;
            return CURLE_OK;
        },
        (CURLWS_CLOSE | CURLWS_CONT) => {
            failfFmt(data, "[WS] CLOSE frame must not be fragmented", .{});
            return CURLE_BAD_FUNCTION_ARGUMENT;
        },
        CURLWS_PING => {
            pfirstbyte.* = WSBIT_OPCODE_PING | WSBIT_FIN;
            return CURLE_OK;
        },
        (CURLWS_PING | CURLWS_CONT) => {
            failfFmt(data, "[WS] PING frame must not be fragmented", .{});
            return CURLE_BAD_FUNCTION_ARGUMENT;
        },
        CURLWS_PONG => {
            pfirstbyte.* = WSBIT_OPCODE_PONG | WSBIT_FIN;
            return CURLE_OK;
        },
        (CURLWS_PONG | CURLWS_CONT) => {
            failfFmt(data, "[WS] PONG frame must not be fragmented", .{});
            return CURLE_BAD_FUNCTION_ARGUMENT;
        },
        else => {
            failfFmt(data, "[WS] unknown flags: {x}", .{flags});
            return CURLE_BAD_FUNCTION_ARGUMENT;
        },
    }
}

fn ws_dec_info(dec: *ws_decoder, data: ?*Curl_easy, msg: []const u8) void {
    switch (dec.head_len) {
        0 => {},
        1 => {
            trcWsFmt(data, "decoded {s} [{s}{s}]", .{
                msg,
                ws_frame_name_of_op(dec.head[0]),
                if ((dec.head[0] & WSBIT_FIN) != 0) "" else " NON-FINAL",
            });
        },
        else => {
            if (dec.head_len < dec.head_total) {
                trcWsFmt(data, "decoded {s} [{s}{s}]({d}/{d})", .{
                    msg,
                    ws_frame_name_of_op(dec.head[0]),
                    if ((dec.head[0] & WSBIT_FIN) != 0) "" else " NON-FINAL",
                    dec.head_len,
                    dec.head_total,
                });
            } else {
                trcWsFmt(data, "decoded {s} [{s}{s} payload={d}/{d}]", .{
                    msg,
                    ws_frame_name_of_op(dec.head[0]),
                    if ((dec.head[0] & WSBIT_FIN) != 0) "" else " NON-FINAL",
                    dec.payload_offset,
                    dec.payload_len,
                });
            }
        },
    }
}

const ws_write_payload_fn = *const fn (
    buf: [*]const u8,
    buflen: usize,
    frame_age: c_int,
    frame_flags: c_int,
    payload_offset: curl_off_t,
    payload_len: curl_off_t,
    userp: *anyopaque,
    pnwritten: *usize,
) CURLcode;

fn ws_dec_next_frame(dec: *ws_decoder) void {
    dec.frame_age = 0;
    dec.frame_flags = 0;
    dec.payload_offset = 0;
    dec.payload_len = 0;
    dec.head_len = 0;
    dec.head_total = 0;
    dec.state = .WS_DEC_INIT;
}

fn ws_dec_reset(dec: *ws_decoder) void {
    dec.frame_age = 0;
    dec.frame_flags = 0;
    dec.payload_offset = 0;
    dec.payload_len = 0;
    dec.head_len = 0;
    dec.head_total = 0;
    dec.state = .WS_DEC_INIT;
    dec.cont_flags = 0;
}

fn ws_dec_init(dec: *ws_decoder) void {
    ws_dec_reset(dec);
}

fn ws_dec_read_head(dec: *ws_decoder, data: ?*Curl_easy, inraw: *bufq) CURLcode {
    var inbuf: ?[*]const u8 = null;
    var inlen: usize = 0;

    while (io_buffers.Curl_bufq_peek(inraw, &inbuf, &inlen)) {
        const src_ptr = inbuf orelse break;
        if (inlen == 0) break;
        const src = src_ptr[0..inlen];
        if (dec.head_len == 0) {
            dec.head[0] = src[0];
            io_buffers.Curl_bufq_skip(inraw, 1);

            dec.frame_flags = ws_frame_firstbyte2flags(data, dec.head[0], dec.cont_flags);
            if (dec.frame_flags == 0) {
                ws_dec_reset(dec);
                return CURLE_RECV_ERROR;
            }

            const uflags: c_uint = @bitCast(dec.frame_flags);
            if ((uflags & (CURLWS_TEXT | CURLWS_BINARY)) != 0) {
                dec.cont_flags = dec.frame_flags;
            }

            dec.head_len = 1;
            continue;
        } else if (dec.head_len == 1) {
            dec.head[1] = src[0];
            io_buffers.Curl_bufq_skip(inraw, 1);
            dec.head_len = 2;

            const head_prefix = dec.head[0..2];
            if ((head_prefix[1] & WSBIT_MASK) != 0) {
                failfFmt(data, "[WS] masked input frame", .{});
                ws_dec_reset(dec);
                return CURLE_RECV_ERROR;
            }
            const uflags: c_uint = @bitCast(dec.frame_flags);
            if ((uflags & (CURLWS_PING | CURLWS_PONG | CURLWS_CLOSE)) != 0) {
                if ((head_prefix[0] & WSBIT_FIN) == 0 or (uflags & CURLWS_CONT) != 0) {
                    failfFmt(data, "[WS] control frame must not be fragmented", .{});
                    ws_dec_reset(dec);
                    return CURLE_RECV_ERROR;
                }
                if ((uflags & CURLWS_PING) != 0 and head_prefix[1] > WS_MAX_CNTRL_LEN) {
                    failfFmt(data, "[WS] received PING frame is too big", .{});
                    ws_dec_reset(dec);
                    return CURLE_RECV_ERROR;
                }
                if ((uflags & CURLWS_PONG) != 0 and head_prefix[1] > WS_MAX_CNTRL_LEN) {
                    failfFmt(data, "[WS] received PONG frame is too big", .{});
                    ws_dec_reset(dec);
                    return CURLE_RECV_ERROR;
                }
                if ((uflags & CURLWS_CLOSE) != 0 and head_prefix[1] > WS_MAX_CNTRL_LEN) {
                    failfFmt(data, "[WS] received CLOSE frame is too big", .{});
                    ws_dec_reset(dec);
                    return CURLE_RECV_ERROR;
                }
            }

            if (head_prefix[1] == 126) {
                dec.head_total = 4;
                continue;
            } else if (head_prefix[1] == 127) {
                dec.head_total = 10;
                continue;
            } else {
                dec.head_total = 2;
            }
        }

        const head_total_uz = std.math.cast(usize, dec.head_total) orelse return CURLE_WEIRD_SERVER_REPLY;
        if (head_total_uz > dec.head.len) return CURLE_WEIRD_SERVER_REPLY;
        const head_slice = dec.head[0..head_total_uz];

        if (dec.head_len < dec.head_total) {
            const head_len_uz = std.math.cast(usize, dec.head_len) orelse return CURLE_WEIRD_SERVER_REPLY;
            head_slice[head_len_uz] = src[0];
            io_buffers.Curl_bufq_skip(inraw, 1);
            dec.head_len += 1;
            if (dec.head_len < dec.head_total) {
                continue;
            }
        }

        switch (head_slice.len) {
            2 => {
                dec.payload_len = @intCast(head_slice[1]);
            },
            4 => {
                const len16 = std.mem.readInt(u16, head_slice[2..4], .big);
                dec.payload_len = @intCast(len16);
            },
            10 => {
                const len64 = std.mem.readInt(u64, head_slice[2..10], .big);
                dec.payload_len = std.math.cast(curl_off_t, len64) orelse {
                    failfFmt(data, "[WS] frame length longer than 63 bits not supported", .{});
                    ws_dec_reset(dec);
                    return CURLE_WEIRD_SERVER_REPLY;
                };
            },
            else => {
                failfFmt(data, "[WS] unexpected frame header length", .{});
                return CURLE_RECV_ERROR;
            },
        }

        dec.frame_age = 0;
        dec.payload_offset = 0;
        ws_dec_info(dec, data, "head");
        return CURLE_OK;
    }
    return CURLE_AGAIN;
}

fn sotouz_range(val: curl_off_t, min_val: usize, max_val: usize) usize {
    if (val <= 0) return min_val;
    const uval: u64 = @intCast(val);
    if (uval < min_val) return min_val;
    if (uval > max_val) return max_val;
    return @intCast(uval);
}

fn ws_dec_pass_payload(
    dec: *ws_decoder,
    data: ?*Curl_easy,
    inraw: *bufq,
    write_cb: ws_write_payload_fn,
    write_ctx: *anyopaque,
) CURLcode {
    var inbuf: ?[*]const u8 = null;
    var inlen: usize = 0;
    var nwritten: usize = 0;
    var remain = sotouz_range(dec.payload_len - dec.payload_offset, 0, std.math.maxInt(usize));

    while (remain > 0 and io_buffers.Curl_bufq_peek(inraw, &inbuf, &inlen) and !Curl_imap_ws_cwriter_is_paused(data)) {
        const src = inbuf orelse break;
        if (inlen > remain) inlen = remain;
        const result = write_cb(
            src,
            inlen,
            dec.frame_age,
            dec.frame_flags,
            dec.payload_offset,
            dec.payload_len,
            write_ctx,
            &nwritten,
        );
        if (result != CURLE_OK) return result;
        io_buffers.Curl_bufq_skip(inraw, nwritten);
        dec.payload_offset += @intCast(nwritten);
        remain = sotouz_range(dec.payload_len - dec.payload_offset, 0, std.math.maxInt(usize));
        trcWsFmt(data, "passed {d} bytes payload, {d} remain", .{ nwritten, remain });
    }

    return if (remain > 0) CURLE_AGAIN else CURLE_OK;
}

fn ws_dec_pass(
    dec: *ws_decoder,
    data: ?*Curl_easy,
    inraw: *bufq,
    write_cb: ws_write_payload_fn,
    write_ctx: *anyopaque,
) CURLcode {
    if (io_buffers.Curl_bufq_is_empty(inraw)) return CURLE_AGAIN;

    switch (dec.state) {
        .WS_DEC_INIT => {
            ws_dec_next_frame(dec);
            dec.state = .WS_DEC_HEAD;
            const r = ws_dec_read_head(dec, data, inraw);
            if (r != CURLE_OK) {
                if (r != CURLE_AGAIN) {
                    failfFmt(data, "[WS] decode frame error {d}", .{r});
                }
                return r;
            }
            dec.state = .WS_DEC_PAYLOAD;
            if (dec.payload_len == 0) {
                var nwritten: usize = 0;
                const tmp = [1]u8{0};
                const r2 = write_cb(&tmp, 0, dec.frame_age, dec.frame_flags, 0, 0, write_ctx, &nwritten);
                if (r2 != CURLE_OK) return r2;
                dec.state = .WS_DEC_INIT;
                return CURLE_OK;
            }
            const r3 = ws_dec_pass_payload(dec, data, inraw, write_cb, write_ctx);
            ws_dec_info(dec, data, "passing");
            if (r3 != CURLE_OK) return r3;
            dec.state = .WS_DEC_INIT;
            return CURLE_OK;
        },
        .WS_DEC_HEAD => {
            const r = ws_dec_read_head(dec, data, inraw);
            if (r != CURLE_OK) {
                if (r != CURLE_AGAIN) {
                    failfFmt(data, "[WS] decode frame error {d}", .{r});
                }
                return r;
            }
            dec.state = .WS_DEC_PAYLOAD;
            if (dec.payload_len == 0) {
                var nwritten: usize = 0;
                const tmp = [1]u8{0};
                const r2 = write_cb(&tmp, 0, dec.frame_age, dec.frame_flags, 0, 0, write_ctx, &nwritten);
                if (r2 != CURLE_OK) return r2;
                dec.state = .WS_DEC_INIT;
                return CURLE_OK;
            }
            const r3 = ws_dec_pass_payload(dec, data, inraw, write_cb, write_ctx);
            ws_dec_info(dec, data, "passing");
            if (r3 != CURLE_OK) return r3;
            dec.state = .WS_DEC_INIT;
            return CURLE_OK;
        },
        .WS_DEC_PAYLOAD => {
            const r3 = ws_dec_pass_payload(dec, data, inraw, write_cb, write_ctx);
            ws_dec_info(dec, data, "passing");
            if (r3 != CURLE_OK) return r3;
            dec.state = .WS_DEC_INIT;
            return CURLE_OK;
        },
    }
}

fn update_meta(
    ws: *websocket,
    frame_age: c_int,
    frame_flags: c_int,
    payload_offset: curl_off_t,
    payload_len: curl_off_t,
    cur_len: usize,
) void {
    const bytesleft = payload_len - payload_offset - @as(curl_off_t, @intCast(cur_len));
    ws.recvframe.age = frame_age;
    ws.recvframe.flags = frame_flags;
    ws.recvframe.offset = payload_offset;
    ws.recvframe.len = cur_len;
    ws.recvframe.bytesleft = bytesleft;
}

fn ws_cw_init(data: ?*Curl_easy, writer: *Curl_cwriter) callconv(.c) CURLcode {
    _ = data;
    const ctx: *ws_cw_ctx = @ptrCast(@alignCast(writer.ctx));
    io_buffers.Curl_bufq_init2(&ctx.buf, WS_CHUNK_SIZE, 1, io_buffers.BUFQ_OPT_SOFT_LIMIT);
    return CURLE_OK;
}

fn ws_cw_close(data: ?*Curl_easy, writer: *Curl_cwriter) callconv(.c) void {
    _ = data;
    const ctx: *ws_cw_ctx = @ptrCast(@alignCast(writer.ctx));
    io_buffers.Curl_bufq_free(&ctx.buf);
}

const ws_cw_dec_ctx = struct {
    data: ?*Curl_easy,
    ws: *websocket,
    next_writer: ?*Curl_cwriter,
    cw_type: c_int,
};

fn ws_enc_add_cntrl(
    data: ?*Curl_easy,
    ws: *websocket,
    payload: [*]const u8,
    plen: usize,
    frame_type: c_uint,
) CURLcode {
    _ = data;
    if (plen > WS_MAX_CNTRL_LEN) return CURLE_BAD_FUNCTION_ARGUMENT;
    ws.pending.type = frame_type;
    ws.pending.payload_len = plen;
    if (plen > 0) {
        @memcpy(ws.pending.payload[0..plen], payload[0..plen]);
    }
    return CURLE_OK;
}

fn ws_payload_remain(payload_total: curl_off_t, payload_offset: curl_off_t, payload_buffered: usize) curl_off_t {
    const remain = payload_total - payload_offset;
    if (payload_total < 0 or payload_offset < 0 or remain < 0) return -1;
    const buffered: curl_off_t = @intCast(payload_buffered);
    if (remain < buffered) return -1;
    return remain - buffered;
}

fn ws_cw_dec_next(
    buf: [*]const u8,
    buflen: usize,
    frame_age: c_int,
    frame_flags: c_int,
    payload_offset: curl_off_t,
    payload_len: curl_off_t,
    user_data: *anyopaque,
    pnwritten: *usize,
) CURLcode {
    const ctx: *ws_cw_dec_ctx = @ptrCast(@alignCast(user_data));
    const data = ctx.data;
    const ws = ctx.ws;
    const auto_pong = !Curl_imap_ws_get_raw_mode(data) and !Curl_imap_ws_get_no_auto_pong(data);

    pnwritten.* = 0;
    const remain = ws_payload_remain(payload_len, payload_offset, buflen);
    if (remain < 0) {
        return CURLE_BAD_FUNCTION_ARGUMENT;
    }

    const uflags: c_uint = @bitCast(frame_flags);
    if (auto_pong and (uflags & CURLWS_PING) != 0 and remain == 0) {
        trcWsFmt(data, "auto PONG to [PING payload={d}/{d}]", .{ payload_offset, payload_len });
        const result = ws_enc_add_cntrl(data, ws, buf, buflen, CURLWS_PONG);
        if (result != CURLE_OK) return result;
    } else if (buflen > 0 or remain == 0) {
        update_meta(ws, frame_age, frame_flags, payload_offset, payload_len, buflen);
        trcWriteFmt(data, "[WS] pass {d} decoded bytes", .{buflen});
        const result = cwriter_write(data, ctx.next_writer, ctx.cw_type | CLIENTWRITE_0LEN, buf, buflen);
        if (result != CURLE_OK) return result;
    }
    pnwritten.* = buflen;
    return CURLE_OK;
}

fn ws_cw_write(data: ?*Curl_easy, writer: *Curl_cwriter, wtype: c_int, buf: [*]const u8, nbytes: usize) callconv(.c) CURLcode {
    const ctx: *ws_cw_ctx = @ptrCast(@alignCast(writer.ctx));
    var result: CURLcode = CURLE_OK;

    trcWriteFmt(data, "[WS] write(len={d}, type={d})", .{ nbytes, wtype });
    if ((wtype & CLIENTWRITE_BODY) == 0 or Curl_imap_ws_get_raw_mode(data)) {
        return cwriter_write(data, writer.next, wtype, buf, nbytes);
    }

    const conn = Curl_imap_ws_easy_conn(data);
    const ws_ptr = Curl_conn_meta_get(conn, CURL_META_PROTO_WS_CONN) orelse {
        failfFmt(data, "[WS] not a websocket transfer", .{});
        return CURLE_FAILED_INIT;
    };
    const ws: *websocket = @ptrCast(@alignCast(ws_ptr));

    if (nbytes > 0) {
        var nwritten: usize = 0;
        result = io_buffers.Curl_bufq_write(&ctx.buf, buf, nbytes, &nwritten);
        if (result != CURLE_OK) {
            infofFmt(data, "[WS] error adding data to buffer {d}", .{result});
            return result;
        }
    }

    result = cwriter_flush(data, writer.next);
    if (result == CURLE_OK) {
        while (!io_buffers.Curl_bufq_is_empty(&ctx.buf) and !Curl_imap_ws_cwriter_is_paused(data)) {
            var pass_ctx = ws_cw_dec_ctx{
                .data = data,
                .ws = ws,
                .next_writer = writer.next,
                .cw_type = wtype,
            };
            result = ws_dec_pass(&ws.dec, data, &ctx.buf, ws_cw_dec_next, @ptrCast(&pass_ctx));
            if (result == CURLE_AGAIN) {
                result = CURLE_OK;
                break;
            } else if (result != CURLE_OK) {
                failfFmt(data, "[WS] decode payload error {d}", .{result});
                io_buffers.Curl_bufq_reset(&ctx.buf);
                break;
            }
        }
    }

    if (result == CURLE_OK and !ws.using_reader) {
        result = ws_flush(data, ws, Curl_api_is_in_callback(data));
        if (result == CURLE_AGAIN) result = CURLE_OK;
    }

    if (result == CURLE_OK and (wtype & CLIENTWRITE_EOS) != 0 and
        (!io_buffers.Curl_bufq_is_empty(&ctx.buf) or ws.dec.state != .WS_DEC_INIT))
    {
        failfFmt(data, "[WS] decode ended with incomplete frame", .{});
        result = CURLE_RECV_ERROR;
    }
    return result;
}

fn ws_cw_flush(data: ?*Curl_easy, writer: *Curl_cwriter) callconv(.c) CURLcode {
    var result: CURLcode = CURLE_OK;

    trcWriteFmt(data, "[ws] flush", .{});
    if (!Curl_imap_ws_get_raw_mode(data)) {
        const ctx: *ws_cw_ctx = @ptrCast(@alignCast(writer.ctx));
        result = cwriter_flush(data, writer.next);
        if (result == CURLE_OK) {
            const conn = Curl_imap_ws_easy_conn(data);
            const ws_ptr = Curl_conn_meta_get(conn, CURL_META_PROTO_WS_CONN) orelse {
                failfFmt(data, "[WS] not a websocket transfer", .{});
                return CURLE_FAILED_INIT;
            };
            const ws: *websocket = @ptrCast(@alignCast(ws_ptr));

            while (!io_buffers.Curl_bufq_is_empty(&ctx.buf) and !Curl_imap_ws_cwriter_is_paused(data)) {
                var pass_ctx = ws_cw_dec_ctx{
                    .data = data,
                    .ws = ws,
                    .next_writer = writer.next,
                    .cw_type = CLIENTWRITE_BODY,
                };
                result = ws_dec_pass(&ws.dec, data, &ctx.buf, ws_cw_dec_next, @ptrCast(&pass_ctx));
                if (result == CURLE_AGAIN) {
                    result = CURLE_OK;
                    break;
                } else if (result != CURLE_OK) {
                    failfFmt(data, "[WS] decode payload error {d}", .{result});
                    io_buffers.Curl_bufq_reset(&ctx.buf);
                    break;
                }
            }
        }
    }

    if (result == CURLE_OK) {
        result = cwriter_flush(data, writer.next);
    }
    return result;
}

const ws_cw_decode = Curl_cwtype{
    .name = "ws-decode",
    .alias = null,
    .flags = 0,
    .do_init = ws_cw_init,
    .do_write = ws_cw_write,
    .do_flush = ws_cw_flush,
    .do_close = ws_cw_close,
    .cwriter_size = @sizeOf(ws_cw_ctx),
};

fn ws_enc_info(enc: *ws_encoder, data: ?*Curl_easy, msg: []const u8) void {
    trcWsFmt(data, "WS-ENC: {s} [{s}{s} payload={d}/{d}]", .{
        msg,
        ws_frame_name_of_op(enc.firstbyte),
        if ((enc.firstbyte & WSBIT_FIN) != 0) "" else " NON-FIN",
        enc.payload_len - enc.payload_remain,
        enc.payload_len,
    });
}

fn ws_enc_reset(enc: *ws_encoder) void {
    enc.payload_remain = 0;
    enc.xori = 0;
    enc.contfragment = false;
}

fn ws_enc_init(enc: *ws_encoder) void {
    ws_enc_reset(enc);
}

fn ws_enc_add_frame(
    data: ?*Curl_easy,
    enc: *ws_encoder,
    flags: c_uint,
    payload_len: curl_off_t,
    out: *bufq,
) CURLcode {
    var firstb: u8 = 0;
    var head: [14]u8 = undefined;
    var hlen: usize = 0;
    var nwritten: usize = 0;

    if (payload_len < 0) {
        failfFmt(data, "[WS] starting new frame with negative payload length {d}", .{payload_len});
        return CURLE_SEND_ERROR;
    }

    if (enc.payload_remain > 0) {
        failfFmt(data, "[WS] starting new frame with {d} bytes from last one remaining to be sent", .{enc.payload_remain});
        return CURLE_SEND_ERROR;
    }

    var result = ws_frame_flags2firstbyte(data, flags, enc.contfragment, &firstb);
    if (result != CURLE_OK) return result;

    if ((flags & (CURLWS_TEXT | CURLWS_BINARY)) != 0) {
        enc.contfragment = (flags & CURLWS_CONT) != 0;
    }

    if ((flags & CURLWS_PING) != 0 and payload_len > WS_MAX_CNTRL_LEN) {
        failfFmt(data, "[WS] given PING frame is too big", .{});
        return CURLE_TOO_LARGE;
    }
    if ((flags & CURLWS_PONG) != 0 and payload_len > WS_MAX_CNTRL_LEN) {
        failfFmt(data, "[WS] given PONG frame is too big", .{});
        return CURLE_TOO_LARGE;
    }
    if ((flags & CURLWS_CLOSE) != 0 and payload_len > WS_MAX_CNTRL_LEN) {
        failfFmt(data, "[WS] given CLOSE frame is too big", .{});
        return CURLE_TOO_LARGE;
    }

    enc.firstbyte = firstb;
    head[0] = firstb;
    if (payload_len > 65535) {
        head[1] = 127 | WSBIT_MASK;
        const ulen: u64 = @intCast(payload_len);
        head[2] = @intCast((ulen >> 56) & 0xff);
        head[3] = @intCast((ulen >> 48) & 0xff);
        head[4] = @intCast((ulen >> 40) & 0xff);
        head[5] = @intCast((ulen >> 32) & 0xff);
        head[6] = @intCast((ulen >> 24) & 0xff);
        head[7] = @intCast((ulen >> 16) & 0xff);
        head[8] = @intCast((ulen >> 8) & 0xff);
        head[9] = @intCast(ulen & 0xff);
        hlen = 10;
    } else if (payload_len >= 126) {
        head[1] = 126 | WSBIT_MASK;
        const ulen: u16 = @intCast(payload_len);
        head[2] = @intCast((ulen >> 8) & 0xff);
        head[3] = @intCast(ulen & 0xff);
        hlen = 4;
    } else {
        head[1] = @as(u8, @intCast(payload_len)) | WSBIT_MASK;
        hlen = 2;
    }

    enc.payload_remain = payload_len;
    enc.payload_len = payload_len;
    ws_enc_info(enc, data, "sending");

    result = Curl_rand_bytes(data, &enc.mask, enc.mask.len);
    if (result != CURLE_OK) return result;
    if (getenv("CURL_WS_FORCE_ZERO_MASK") != null) {
        @memset(&enc.mask, 0);
    }

    @memcpy(head[hlen .. hlen + 4], &enc.mask);
    hlen += 4;
    enc.xori = 0;

    result = io_buffers.Curl_bufq_write(out, &head, hlen, &nwritten);
    if (result != CURLE_OK) return result;
    if (nwritten != hlen) return CURLE_SEND_ERROR;
    return CURLE_OK;
}

fn ws_enc_write_head(
    data: ?*Curl_easy,
    ws: *websocket,
    enc: *ws_encoder,
    flags: c_uint,
    payload_len: curl_off_t,
    out: *bufq,
) CURLcode {
    if (ws.pending.type != 0) {
        const result = ws_enc_add_pending(data, ws);
        if (result != CURLE_OK) return result;
    }
    return ws_enc_add_frame(data, enc, flags, payload_len, out);
}

fn ws_enc_write_payload(
    enc: *ws_encoder,
    data: ?*Curl_easy,
    buf: [*]const u8,
    buflen: usize,
    out: *bufq,
    pnwritten: *usize,
) CURLcode {
    pnwritten.* = 0;
    if (io_buffers.Curl_bufq_is_full(out)) return CURLE_AGAIN;

    var len = buflen;
    const remain = sotouz_range(enc.payload_remain, 0, std.math.maxInt(usize));
    if (remain < len) len = remain;

    var i: usize = 0;
    while (i < len) : (i += 1) {
        var c: [1]u8 = .{buf[i] ^ enc.mask[enc.xori]};
        var n: usize = 0;
        const result = io_buffers.Curl_bufq_write(out, &c, 1, &n);
        if (result != CURLE_OK) {
            if (result != CURLE_AGAIN or i == 0) return result;
            break;
        }
        enc.xori = (enc.xori + 1) & 3;
    }
    pnwritten.* = i;
    enc.payload_remain -= @intCast(i);
    ws_enc_info(enc, data, "buffered");
    return CURLE_OK;
}

fn ws_enc_add_pending(data: ?*Curl_easy, ws: *websocket) CURLcode {
    if (ws.pending.type == 0) return CURLE_OK;
    if (ws.enc.payload_remain != 0) return CURLE_AGAIN;

    var n: usize = 0;
    var result = ws_enc_add_frame(data, &ws.enc, ws.pending.type, @intCast(ws.pending.payload_len), &ws.sendbuf);
    if (result != CURLE_OK) {
        trcWsFmt(data, "ws_enc_cntrl(), error adding head: {d}", .{result});
        return result;
    }
    result = ws_enc_write_payload(&ws.enc, data, &ws.pending.payload, ws.pending.payload_len, &ws.sendbuf, &n);
    if (result != CURLE_OK) {
        trcWsFmt(data, "ws_enc_cntrl(), error adding payload: {d}", .{result});
        return result;
    }
    if (n != ws.pending.payload_len) {
        trcWsFmt(data, "ws_enc_cntrl(), error added only {d}/{d} payload,", .{ n, ws.pending.payload_len });
        return CURLE_SEND_ERROR;
    }
    ws.pending.type = 0;
    ws.pending.payload_len = 0;
    @memset(&ws.pending.payload, 0);
    return CURLE_OK;
}

fn ws_enc_send(
    data: ?*Curl_easy,
    ws: *websocket,
    buffer_in: ?[*]const u8,
    buflen_in: usize,
    fragsize: curl_off_t,
    flags: c_uint,
    pnsent: *usize,
) CURLcode {
    var n: usize = 0;
    var result: CURLcode = CURLE_OK;
    var buffer = buffer_in;
    var buflen = buflen_in;

    pnsent.* = 0;

    if (ws.enc.payload_remain != 0 or !io_buffers.Curl_bufq_is_empty(&ws.sendbuf)) {
        if (buflen < ws.sendbuf_payload) {
            failfFmt(data, "[WS] curl_ws_send() called with smaller 'buflen' than bytes already buffered in previous call, {d} vs {d}", .{ buflen, ws.sendbuf_payload });
            return CURLE_BAD_FUNCTION_ARGUMENT;
        }
        if (@as(curl_off_t, @intCast(buflen)) > (ws.enc.payload_remain + @as(curl_off_t, @intCast(ws.sendbuf_payload)))) {
            failfFmt(data, "[WS] unaligned frame size (sending {d} instead of {d})", .{
                buflen,
                ws.enc.payload_remain + @as(curl_off_t, @intCast(ws.sendbuf_payload)),
            });
            return CURLE_BAD_FUNCTION_ARGUMENT;
        }
    } else {
        result = ws_flush(data, ws, Curl_api_is_in_callback(data));
        if (result != CURLE_OK) return result;

        result = ws_enc_write_head(
            data,
            ws,
            &ws.enc,
            flags,
            if ((flags & CURLWS_OFFSET) != 0) fragsize else @intCast(buflen),
            &ws.sendbuf,
        );
        if (result != CURLE_OK) {
            trcWsFmt(data, "curl_ws_send(), error writing frame head {d}", .{result});
            return result;
        }
    }

    while (!io_buffers.Curl_bufq_is_empty(&ws.sendbuf) or (buflen > ws.sendbuf_payload)) {
        if (buflen > ws.sendbuf_payload) {
            const prev_len = io_buffers.Curl_bufq_len(&ws.sendbuf);
            const src = (buffer orelse return CURLE_BAD_FUNCTION_ARGUMENT) + ws.sendbuf_payload;
            result = ws_enc_write_payload(&ws.enc, data, src, buflen - ws.sendbuf_payload, &ws.sendbuf, &n);
            if (result != CURLE_OK and result != CURLE_AGAIN) return result;
            ws.sendbuf_payload += io_buffers.Curl_bufq_len(&ws.sendbuf) - prev_len;
            if (ws.sendbuf_payload == 0) {
                return CURLE_AGAIN;
            }
        }

        if (!ws.block_first_send and getenv("CURL_WS_CHUNK_EAGAIN") != null) {
            ws.block_first_send = true;
            return CURLE_AGAIN;
        }
        result = ws_flush(data, ws, Curl_api_is_in_callback(data));
        if (result == CURLE_OK and ws.sendbuf_payload > 0) {
            pnsent.* += ws.sendbuf_payload;
            if (buffer) |b| buffer = b + ws.sendbuf_payload;
            buflen -= ws.sendbuf_payload;
            ws.sendbuf_payload = 0;
        } else if (result == CURLE_AGAIN) {
            const cur_bufq_len = io_buffers.Curl_bufq_len(&ws.sendbuf);
            if (ws.sendbuf_payload > cur_bufq_len) {
                const flushed = ws.sendbuf_payload - cur_bufq_len;
                pnsent.* += flushed;
                ws.sendbuf_payload -= flushed;
                return CURLE_OK;
            } else {
                trcWsFmt(data, "EAGAIN flushing sendbuf, payload_encoded: {d}/{d}", .{ ws.sendbuf_payload, buflen });
                return CURLE_AGAIN;
            }
        } else {
            return result;
        }
    }
    return CURLE_OK;
}

const cr_ws_ctx = extern struct {
    super: Curl_creader,
    read_eos: bool,
    eos: bool,
};

fn cr_ws_init(data: ?*Curl_easy, reader: *Curl_creader) callconv(.c) CURLcode {
    _ = data;
    _ = reader;
    return CURLE_OK;
}

fn cr_ws_close(data: ?*Curl_easy, reader: *Curl_creader) callconv(.c) void {
    _ = data;
    _ = reader;
}

fn cr_ws_read(data: ?*Curl_easy, reader: *Curl_creader, buf: [*]u8, blen_in: usize, pnread: *usize, peos: *bool) callconv(.c) CURLcode {
    const ctx: *cr_ws_ctx = @ptrCast(@alignCast(reader.ctx));
    var result: CURLcode = CURLE_OK;
    var nread: usize = 0;
    var n: usize = 0;
    var eos: bool = false;
    var blen = blen_in;

    pnread.* = 0;
    if (ctx.eos) {
        peos.* = true;
        return CURLE_OK;
    }

    const conn = Curl_imap_ws_easy_conn(data);
    const ws_ptr = Curl_conn_meta_get(conn, CURL_META_PROTO_WS_CONN) orelse {
        failfFmt(data, "[WS] not a websocket transfer", .{});
        return CURLE_FAILED_INIT;
    };
    const ws: *websocket = @ptrCast(@alignCast(ws_ptr));

    if (io_buffers.Curl_bufq_is_empty(&ws.sendbuf)) {
        if (ctx.read_eos) {
            ctx.eos = true;
            peos.* = true;
            return CURLE_OK;
        }

        if (ws.enc.payload_remain != 0) {
            trcWsFmt(data, "current frame, {d} remaining", .{ws.enc.payload_remain});
            blen = sotouz_range(ws.enc.payload_remain, 0, blen);
        }

        result = Curl_creader_read(data, reader.next, buf, blen, &nread, &eos);
        if (result != CURLE_OK) return result;
        ctx.read_eos = eos;

        if (!io_buffers.Curl_bufq_is_empty(&ws.sendbuf)) {
            ctx.read_eos = false;
            Curl_creader_clear_eos(data, reader.next);
        } else if (nread == 0) {
            if (ctx.read_eos) ctx.eos = true;
            pnread.* = nread;
            peos.* = ctx.eos;
            trcReadFmt(data, "cr_ws_read(len={d}) -> {d}, nread={d}, eos={d}", .{ blen, result, pnread.*, @intFromBool(peos.*) });
            return result;
        }

        if (ws.enc.payload_remain == 0 and io_buffers.Curl_bufq_is_empty(&ws.sendbuf)) {
            var frame_len: curl_off_t = @intCast(nread);
            if (getenv("CURL_WS_CHUNK_SIZE")) |env_p| {
                var p: [*:0]const u8 = env_p;
                var x: curl_off_t = 0;
                if (curlx_str_number(&p, &x, 1024 * 1024) == 0 and x > 0) {
                    frame_len = x;
                }
            }
            result = ws_enc_write_head(data, ws, &ws.enc, CURLWS_BINARY, frame_len, &ws.sendbuf);
            if (result != CURLE_OK) {
                trcReadFmt(data, "cr_ws_read(len={d}) -> {d}, nread={d}, eos={d}", .{ blen, result, pnread.*, @intFromBool(peos.*) });
                return result;
            }
        }

        result = ws_enc_write_payload(&ws.enc, data, buf, nread, &ws.sendbuf, &n);
        if (result != CURLE_OK) {
            trcReadFmt(data, "cr_ws_read(len={d}) -> {d}, nread={d}, eos={d}", .{ blen, result, pnread.*, @intFromBool(peos.*) });
            return result;
        }
        trcReadFmt(data, "cr_ws_read, added {d} payload, len={d}", .{ nread, n });
    }

    peos.* = false;
    result = io_buffers.Curl_bufq_cread(&ws.sendbuf, buf, blen, pnread);
    if (result == CURLE_OK and ctx.read_eos and io_buffers.Curl_bufq_is_empty(&ws.sendbuf)) {
        ctx.eos = true;
        peos.* = true;
    }

    trcReadFmt(data, "cr_ws_read(len={d}) -> {d}, nread={d}, eos={d}", .{ blen, result, pnread.*, @intFromBool(peos.*) });
    return result;
}

fn cr_ws_total_length(data: ?*Curl_easy, reader: *Curl_creader) callconv(.c) curl_off_t {
    _ = data;
    _ = reader;
    return -1;
}

const ws_cr_encode = Curl_crtype{
    .name = "ws-encode",
    .do_init = cr_ws_init,
    .do_read = cr_ws_read,
    .do_close = cr_ws_close,
    .needs_rewind = Curl_creader_def_needs_rewind,
    .total_length = cr_ws_total_length,
    .resume_from = Curl_creader_def_resume_from,
    .cntrl = Curl_creader_def_cntrl,
    .is_paused = Curl_creader_def_is_paused,
    .done = Curl_creader_def_done,
    .creader_size = @sizeOf(cr_ws_ctx),
};

fn ws_conn_dtor(key: [*:0]const u8, klen: usize, entry: ?*anyopaque) callconv(.c) void {
    _ = key;
    _ = klen;
    const p = entry orelse return;
    const ws: *websocket = @ptrCast(@alignCast(p));
    io_buffers.Curl_bufq_free(&ws.recvbuf);
    io_buffers.Curl_bufq_free(&ws.sendbuf);
    mem.freeSized(p, @sizeOf(websocket));
}

pub export fn Curl_ws_request(data: ?*Curl_easy, req: *dynbuf) callconv(.c) CURLcode {
    var rand: [16]u8 = undefined;
    var randstr: ?[*:0]u8 = null;
    var randlen: usize = 0;

    var result = Curl_rand_bytes(data, &rand, rand.len);
    if (result != CURLE_OK) return result;

    result = curlx_parse.curlx_base64_encode(&rand, rand.len, &randstr, &randlen);
    if (result != CURLE_OK) return result;
    const key_ptr = randstr orelse return CURLE_OUT_OF_MEMORY;
    defer mem.free(@ptrCast(key_ptr));

    if (randlen >= 40) return CURLE_FAILED_INIT;
    const key_s = key_ptr[0..randlen];

    const heads = [_]struct { name: []const u8, val: []const u8 }{
        .{ .name = "Upgrade", .val = "websocket" },
        .{ .name = "Sec-WebSocket-Version", .val = "13" },
        .{ .name = "Sec-WebSocket-Key", .val = key_s },
    };

    for (heads) |h| {
        if (Curl_checkheaders(data, h.name.ptr, h.name.len) == null) {
            var line_buf: [128]u8 = undefined;
            const line = std.fmt.bufPrint(&line_buf, "{s}: {s}\r\n", .{ h.name, h.val }) catch return CURLE_OUT_OF_MEMORY;
            result = curlx_dyn_addn(req, line.ptr, line.len);
            if (result != CURLE_OK) return result;
        }
    }

    Curl_imap_ws_mark_request_upgrade(data);
    return result;
}

pub export fn Curl_ws_accept(data: ?*Curl_easy, mem_ptr: ?[*]const u8, nread: usize) callconv(.c) CURLcode {
    const conn = Curl_imap_ws_easy_conn(data);
    var ws: *websocket = undefined;
    var ws_dec_writer: ?*Curl_cwriter = null;
    var ws_enc_reader: ?*Curl_creader = null;
    var result: CURLcode = CURLE_OK;

    if (Curl_conn_meta_get(conn, CURL_META_PROTO_WS_CONN)) |existing| {
        ws = @ptrCast(@alignCast(existing));
        io_buffers.Curl_bufq_reset(&ws.recvbuf);
        ws_dec_reset(&ws.dec);
        ws_enc_reset(&ws.enc);
    } else {
        const raw = mem.calloc(1, @sizeOf(websocket)) orelse return CURLE_OUT_OF_MEMORY;
        ws = @ptrCast(@alignCast(raw));
        var chunk_size: usize = WS_CHUNK_SIZE;
        if (getenv("CURL_WS_CHUNK_SIZE")) |env_p| {
            var p: [*:0]const u8 = env_p;
            var x: curl_off_t = 0;
            if (curlx_str_number(&p, &x, 1024 * 1024) == 0 and x > 0) {
                chunk_size = @intCast(x);
            }
        }
        trcWsFmt(data, "WS, using chunk size {d}", .{chunk_size});
        io_buffers.Curl_bufq_init2(&ws.recvbuf, chunk_size, WS_CHUNK_COUNT, io_buffers.BUFQ_OPT_SOFT_LIMIT);
        io_buffers.Curl_bufq_init2(&ws.sendbuf, chunk_size, WS_CHUNK_COUNT, io_buffers.BUFQ_OPT_SOFT_LIMIT);
        ws_dec_init(&ws.dec);
        ws_enc_init(&ws.enc);
        result = Curl_conn_meta_set(conn, CURL_META_PROTO_WS_CONN, raw, ws_conn_dtor);
        if (result != CURLE_OK) return result;
    }

    infofFmt(data, "[WS] Received 101, switch to WebSocket", .{});

    result = Curl_cwriter_create(&ws_dec_writer, data, &ws_cw_decode, CURL_CW_CONTENT_DECODE);
    if (result == CURLE_OK) {
        result = Curl_cwriter_add(data, ws_dec_writer.?);
        if (result == CURLE_OK) {
            ws_dec_writer = null;
            Curl_imap_ws_set_req_header(data, false);

            if (Curl_imap_ws_get_connect_only(data)) {
                if (nread > 0) {
                    if (mem_ptr) |mp| {
                        result = Curl_cf_recvbuf_add(data, conn, FIRSTSOCKET, mp, nread);
                    }
                }
                if (result == CURLE_OK) {
                    Curl_imap_ws_clear_req_recv(data);
                }
            } else {
                if (Curl_imap_ws_is_method_put(data)) {
                    trcWsFmt(data, "UPLOAD set, add ws-encode reader", .{});
                    result = Curl_creader_set_fread(data, -1);
                    if (result == CURLE_OK and !Curl_imap_ws_get_raw_mode(data)) {
                        result = Curl_creader_create(&ws_enc_reader, data, &ws_cr_encode, CURL_CR_CONTENT_ENCODE);
                        if (result == CURLE_OK) {
                            result = Curl_creader_add(data, ws_enc_reader.?);
                            if (result == CURLE_OK) {
                                ws_enc_reader = null;
                                ws.using_reader = true;
                            }
                        }
                    }
                    if (result == CURLE_OK) {
                        Curl_imap_ws_restart_req_send(data);
                    }
                }

                if (result == CURLE_OK and nread > 0) {
                    if (mem_ptr) |mp| {
                        result = Curl_client_write(data, CLIENTWRITE_BODY, mp, nread);
                    }
                }
            }

            if (result == CURLE_OK) {
                Curl_imap_ws_set_upgr101_received(data);
                Curl_imap_ws_set_req_header(data, false);
            }
        }
    }

    if (ws_dec_writer) |w| Curl_cwriter_free(data, w);
    if (ws_enc_reader) |r| Curl_creader_free(data, r);
    if (result != CURLE_OK) {
        trcWsFmt(data, "Curl_ws_accept() failed -> {d}", .{result});
    } else {
        trcWsFmt(data, "websocket established, {s} mode", .{
            if (Curl_imap_ws_get_connect_only(data)) "connect-only" else "callback",
        });
    }
    return result;
}

const ws_collect = struct {
    data: ?*Curl_easy,
    ws: *websocket,
    buffer: ?[*]u8,
    buflen: usize,
    bufidx: usize,
    frame_age: c_int,
    frame_flags: c_int,
    payload_offset: curl_off_t,
    payload_len: curl_off_t,
    written: bool,
};

fn ws_client_collect(
    buf: [*]const u8,
    buflen: usize,
    frame_age: c_int,
    frame_flags: c_int,
    payload_offset: curl_off_t,
    payload_len: curl_off_t,
    userp: *anyopaque,
    pnwritten: *usize,
) CURLcode {
    const ctx: *ws_collect = @ptrCast(@alignCast(userp));
    const data = ctx.data;
    const auto_pong = !Curl_imap_ws_get_raw_mode(data) and !Curl_imap_ws_get_no_auto_pong(data);
    var result: CURLcode = CURLE_OK;

    pnwritten.* = 0;
    const remain = ws_payload_remain(payload_len, payload_offset, buflen);
    if (remain < 0) return CURLE_BAD_FUNCTION_ARGUMENT;

    if (ctx.bufidx == 0) {
        ctx.frame_age = frame_age;
        ctx.frame_flags = frame_flags;
        ctx.payload_offset = payload_offset;
        ctx.payload_len = payload_len;
    }

    const uflags: c_uint = @bitCast(frame_flags);
    if (auto_pong and (uflags & CURLWS_PING) != 0 and remain == 0) {
        trcWsFmt(data, "auto PONG to [PING payload={d}/{d}]", .{ payload_offset, payload_len });
        result = ws_enc_add_cntrl(ctx.data, ctx.ws, buf, buflen, CURLWS_PONG);
        if (result != CURLE_OK) return result;
        pnwritten.* = buflen;
    } else {
        ctx.written = true;
        const write_len = @min(buflen, ctx.buflen - ctx.bufidx);
        if (write_len == 0) {
            if (buflen == 0) return CURLE_OK;
            return CURLE_AGAIN;
        }
        if (ctx.buffer) |dst| {
            @memcpy(dst[ctx.bufidx .. ctx.bufidx + write_len], buf[0..write_len]);
        }
        ctx.bufidx += write_len;
        pnwritten.* = write_len;
    }
    return result;
}

fn nw_in_recv(reader_ctx: ?*anyopaque, buf: [*]u8, buflen: usize, pnread: *usize) callconv(.c) CURLcode {
    const data: ?*Curl_easy = @ptrCast(reader_ctx);
    return Curl_easy_recv(data, buf, buflen, pnread);
}

pub export fn curl_ws_recv(
    curl: ?*Curl_easy,
    buffer: ?*anyopaque,
    buflen: usize,
    recv: ?*usize,
    metap: ?*?*const curl_ws_frame,
) callconv(.c) CURLcode {
    var guard = Curl_eapi_guard{};
    var result: CURLcode = CURLE_OK;

    if (Curl_eapi_enter(&guard, curl, CURL_EAPI_FN_ws_recv, &result) and curl != null) {
        defer Curl_eapi_leave(&guard);
        const data = curl;

        if (recv == null or metap == null or (buflen > 0 and buffer == null)) {
            return CURLE_BAD_FUNCTION_ARGUMENT;
        }
        const recv_p = recv.?;
        const metap_p = metap.?;

        recv_p.* = 0;
        metap_p.* = null;

        var conn = Curl_imap_ws_easy_conn(data);
        if (conn == null) {
            if (!Curl_imap_ws_get_connect_only(data)) {
                failfFmt(data, "[WS] CONNECT_ONLY is required", .{});
                return CURLE_UNSUPPORTED_PROTOCOL;
            }
            _ = Curl_getconnectinfo(data, &conn);
            if (conn == null) {
                failfFmt(data, "[WS] connection not found", .{});
                return CURLE_BAD_FUNCTION_ARGUMENT;
            }
        }

        const ws_ptr = Curl_conn_meta_get(conn, CURL_META_PROTO_WS_CONN) orelse {
            failfFmt(data, "[WS] connection is not setup for websocket", .{});
            return CURLE_BAD_FUNCTION_ARGUMENT;
        };
        const ws: *websocket = @ptrCast(@alignCast(ws_ptr));

        var ctx = ws_collect{
            .data = data,
            .ws = ws,
            .buffer = if (buffer) |b| @ptrCast(b) else null,
            .buflen = buflen,
            .bufidx = 0,
            .frame_age = 0,
            .frame_flags = 0,
            .payload_offset = 0,
            .payload_len = 0,
            .written = false,
        };

        while (true) {
            if (io_buffers.Curl_bufq_is_empty(&ws.recvbuf)) {
                var n: usize = 0;
                result = io_buffers.Curl_bufq_slurp(&ws.recvbuf, nw_in_recv, @ptrCast(data), &n);
                if (result != CURLE_OK) {
                    return result;
                } else if (n == 0) {
                    infofFmt(data, "[WS] connection expectedly closed?", .{});
                    return CURLE_GOT_NOTHING;
                }
                trcWsFmt(data, "curl_ws_recv, added {d} bytes from network", .{io_buffers.Curl_bufq_len(&ws.recvbuf)});
            }

            result = ws_dec_pass(&ws.dec, data, &ws.recvbuf, ws_client_collect, @ptrCast(&ctx));
            if (result == CURLE_AGAIN) {
                if (!ctx.written) {
                    ws_dec_info(&ws.dec, data, "need more input");
                    continue;
                }
                break;
            } else if (result != CURLE_OK) {
                return result;
            } else if (ctx.written) {
                break;
            }
        }

        update_meta(ws, ctx.frame_age, ctx.frame_flags, ctx.payload_offset, ctx.payload_len, ctx.bufidx);
        metap_p.* = &ws.recvframe;
        recv_p.* = ws.recvframe.len;
        trcWsFmt(data, "curl_ws_recv(len={d}) -> {d} bytes (frame at {d}, {d} left)", .{
            buflen,
            recv_p.*,
            ws.recvframe.offset,
            ws.recvframe.bytesleft,
        });

        if (!Curl_imap_ws_get_raw_mode(data) and !ws.using_reader and ws.pending.type != 0) {
            const r2 = ws_enc_add_pending(data, ws);
            if (r2 == CURLE_OK) {
                _ = ws_flush(data, ws, Curl_api_is_in_callback(data));
            }
        }
        return CURLE_OK;
    }

    Curl_eapi_leave(&guard);
    return result;
}

fn ws_flush(data: ?*Curl_easy, ws: *websocket, blocking: bool) CURLcode {
    var result: CURLcode = CURLE_OK;

    if (io_buffers.Curl_bufq_len(&ws.sendbuf) < ws.sendbuf.chunk_size) {
        result = ws_enc_add_pending(data, ws);
        if (result != CURLE_OK and result != CURLE_AGAIN) return result;
    }

    if (!io_buffers.Curl_bufq_is_empty(&ws.sendbuf)) {
        var out: ?[*]const u8 = null;
        var outlen: usize = 0;
        var n: usize = 0;

        while (io_buffers.Curl_bufq_peek(&ws.sendbuf, &out, &outlen)) {
            const src = out orelse break;
            if (blocking) {
                result = ws_send_raw_blocking(data, ws, src, outlen);
                n = if (result != CURLE_OK) 0 else outlen;
            } else if (Curl_imap_ws_get_connect_only(data) or Curl_api_is_in_callback(data)) {
                result = Curl_senddata(data, src, outlen, &n);
            } else {
                result = Curl_xfer_send(data, src, outlen, false, &n);
                if (result == CURLE_OK and n == 0 and outlen > 0) {
                    result = CURLE_AGAIN;
                }
            }

            if (result == CURLE_AGAIN) {
                trcWsFmt(data, "flush EAGAIN, {d} bytes remain in buffer", .{io_buffers.Curl_bufq_len(&ws.sendbuf)});
                return result;
            } else if (result != CURLE_OK) {
                failfFmt(data, "[WS] flush, write error {d}", .{result});
                return result;
            } else {
                trcWsFmt(data, "flushed {d} bytes", .{n});
                io_buffers.Curl_bufq_skip(&ws.sendbuf, n);
            }
        }
    }
    return CURLE_OK;
}

fn ws_send_raw_blocking(data: ?*Curl_easy, ws: *websocket, buffer_in: [*]const u8, buflen_in: usize) CURLcode {
    var result: CURLcode = CURLE_OK;
    var nwritten: usize = 0;
    var buffer = buffer_in;
    var buflen = buflen_in;

    if (data == null) return result;
    _ = ws;

    while (buflen > 0) {
        result = Curl_xfer_send(data, buffer, buflen, false, &nwritten);
        if (result != CURLE_OK) return result;
        buffer += nwritten;
        buflen -= nwritten;
        if (buflen > 0) {
            const sock = Curl_imap_ws_conn_firstsocket(data);
            trcWsFmt(data, "ws_send_raw_blocking() partial, {d} left to send", .{buflen});
            const left_ms = Curl_timeleft_ms(data);
            if (left_ms < 0) {
                failfFmt(data, "[WS] Timeout waiting for socket becoming writable", .{});
                return CURLE_SEND_ERROR;
            }
            if (sock == CURL_SOCKET_BAD) return CURLE_SEND_ERROR;
            const ev = headers_sock.Curl_socket_check(CURL_SOCKET_BAD, CURL_SOCKET_BAD, sock, if (left_ms != 0) left_ms else 500);
            if (ev < 0) {
                failfFmt(data, "[WS] Error while waiting for socket becoming writable", .{});
                return CURLE_SEND_ERROR;
            }
        }
    }
    return result;
}

fn ws_send_raw(data: ?*Curl_easy, buffer: *const anyopaque, buflen: usize, pnwritten: *usize) CURLcode {
    const conn = Curl_imap_ws_easy_conn(data);
    const ws_ptr = Curl_conn_meta_get(conn, CURL_META_PROTO_WS_CONN) orelse {
        failfFmt(data, "[WS] Not a websocket transfer", .{});
        return CURLE_SEND_ERROR;
    };
    const ws: *websocket = @ptrCast(@alignCast(ws_ptr));
    if (buflen == 0) return CURLE_OK;

    var result: CURLcode = CURLE_OK;
    if (Curl_api_is_in_callback(data)) {
        result = ws_flush(data, ws, true);
        if (result != CURLE_OK) return result;
        result = ws_send_raw_blocking(data, ws, @ptrCast(buffer), buflen);
        if (result == CURLE_OK) pnwritten.* = buflen;
    } else {
        result = ws_flush(data, ws, false);
        if (result != CURLE_OK) return result;
        result = Curl_senddata(data, buffer, buflen, pnwritten);
    }

    trcWsFmt(data, "ws_send_raw(len={d}) -> {d}, {d}", .{ buflen, result, pnwritten.* });
    return result;
}

pub export fn curl_ws_send(
    curl: ?*Curl_easy,
    buffer_arg: ?*const anyopaque,
    buflen: usize,
    sent: ?*usize,
    fragsize: curl_off_t,
    flags: c_uint,
) callconv(.c) CURLcode {
    var guard = Curl_eapi_guard{};
    var result: CURLcode = CURLE_OK;

    if (Curl_eapi_enter(&guard, curl, CURL_EAPI_FN_ws_send, &result) and curl != null) {
        defer Curl_eapi_leave(&guard);
        const data = curl;
        const buffer: ?[*]const u8 = if (buffer_arg) |b| @ptrCast(b) else null;
        var ndummy: usize = 0;
        const pnsent: *usize = sent orelse &ndummy;

        trcWsFmt(data, "curl_ws_send(len={d}, fragsize={d}, flags={x}), raw={d}", .{
            buflen,
            fragsize,
            flags,
            @intFromBool(Curl_imap_ws_get_raw_mode(data)),
        });

        pnsent.* = 0;

        if (buffer == null and buflen > 0) {
            failfFmt(data, "[WS] buffer is NULL when buflen is not", .{});
            return CURLE_BAD_FUNCTION_ARGUMENT;
        }

        if (Curl_imap_ws_easy_conn(data) == null and Curl_imap_ws_get_connect_only(data)) {
            result = Curl_connect_only_attach(data);
            if (result != CURLE_OK) return result;
        }
        const conn = Curl_imap_ws_easy_conn(data) orelse {
            failfFmt(data, "[WS] No associated connection", .{});
            return CURLE_SEND_ERROR;
        };
        const ws_ptr = Curl_conn_meta_get(conn, CURL_META_PROTO_WS_CONN) orelse {
            failfFmt(data, "[WS] Not a websocket transfer", .{});
            return CURLE_SEND_ERROR;
        };
        const ws: *websocket = @ptrCast(@alignCast(ws_ptr));

        if (Curl_imap_ws_get_raw_mode(data)) {
            result = ws_flush(data, ws, false);
            if (result != CURLE_OK) return result;

            const buf_nn = buffer_arg orelse {
                failfFmt(data, "[WS] buffer is NULL in raw mode", .{});
                return CURLE_BAD_FUNCTION_ARGUMENT;
            };
            if (sent == null) {
                failfFmt(data, "[WS] sent is NULL in raw mode", .{});
                return CURLE_BAD_FUNCTION_ARGUMENT;
            }
            if (fragsize != 0 or flags != 0) {
                failfFmt(data, "[WS] fragsize and flags must be zero in raw mode", .{});
                return CURLE_BAD_FUNCTION_ARGUMENT;
            }
            return ws_send_raw(data, buf_nn, buflen, pnsent);
        }

        result = ws_enc_send(data, ws, buffer, buflen, fragsize, flags, pnsent);
        trcWsFmt(data, "curl_ws_send(len={d}, fragsize={d}, flags={x}, raw={d}) -> {d}, {d}", .{
            buflen,
            fragsize,
            flags,
            @intFromBool(Curl_imap_ws_get_raw_mode(data)),
            result,
            pnsent.*,
        });
        return result;
    }

    Curl_eapi_leave(&guard);
    return result;
}

fn ws_setup_conn(data: ?*Curl_easy, conn: ?*connectdata) callconv(.c) CURLcode {
    Curl_imap_ws_setup_http_neg(data);
    return Curl_http_setup_conn(data, conn);
}

pub export fn curl_ws_meta(curl: ?*Curl_easy) callconv(.c) ?*const curl_ws_frame {
    if (Curl_imap_ws_good_easy_handle(curl) and Curl_api_is_in_callback(curl) and !Curl_imap_ws_get_raw_mode(curl)) {
        if (Curl_imap_ws_easy_conn(curl)) |conn| {
            if (Curl_conn_meta_get(conn, CURL_META_PROTO_WS_CONN)) |ws_ptr| {
                const ws: *websocket = @ptrCast(@alignCast(ws_ptr));
                return &ws.recvframe;
            }
        }
    }
    return null;
}

pub export fn curl_ws_start_frame(
    curl: ?*Curl_easy,
    flags: c_uint,
    frame_len: curl_off_t,
) callconv(.c) CURLcode {
    var guard = Curl_eapi_guard{};
    var result: CURLcode = CURLE_OK;

    if (Curl_eapi_enter(&guard, curl, CURL_EAPI_FN_ws_start_frame, &result) and curl != null) {
        defer Curl_eapi_leave(&guard);
        const data = curl;

        if (Curl_imap_ws_get_raw_mode(data)) {
            failfFmt(data, "cannot curl_ws_start_frame() with CURLWS_RAW_MODE enabled", .{});
            return CURLE_FAILED_INIT;
        }

        trcWsFmt(data, "curl_ws_start_frame(flags={x}, frame_len={d}", .{ flags, frame_len });

        const conn = Curl_imap_ws_easy_conn(data) orelse {
            failfFmt(data, "[WS] No associated connection", .{});
            return CURLE_SEND_ERROR;
        };
        const ws_ptr = Curl_conn_meta_get(conn, CURL_META_PROTO_WS_CONN) orelse {
            failfFmt(data, "[WS] Not a websocket transfer", .{});
            return CURLE_SEND_ERROR;
        };
        const ws: *websocket = @ptrCast(@alignCast(ws_ptr));

        if (ws.enc.payload_remain != 0) {
            failfFmt(data, "[WS] previous frame not finished", .{});
            return CURLE_SEND_ERROR;
        }

        result = ws_enc_write_head(data, ws, &ws.enc, flags, frame_len, &ws.sendbuf);
        if (result != CURLE_OK) {
            trcWsFmt(data, "curl_start_frame(), error adding frame head {d}", .{result});
        }
        return result;
    }

    Curl_eapi_leave(&guard);
    return result;
}

pub export const Curl_protocol_ws = Curl_protocol{
    .setup_connection = ws_setup_conn,
    .do_it = Curl_http,
    .done = Curl_http_done,
    .do_more = null,
    .connect_it = null,
    .connecting = null,
    .doing = null,
    .proto_pollset = null,
    .doing_pollset = Curl_http_doing_pollset,
    .domore_pollset = null,
    .perform_pollset = Curl_http_perform_pollset,
    .disconnect = null,
    .write_resp = Curl_http_write_resp,
    .write_resp_hd = Curl_http_write_resp_hd,
    .connection_is_dead = null,
    .attach = null,
    .follow = Curl_http_follow,
};

// ============================================================================
// Unit Tests
// ============================================================================

test "imap_atom quoting and escaping" {
    const plain = imap_atom("INBOX", false);
    try std.testing.expect(plain != null);
    defer mem.free(@ptrCast(plain.?));
    try std.testing.expectEqualStrings("INBOX", std.mem.span(plain.?));

    const with_space = imap_atom("My Folder", false);
    try std.testing.expect(with_space != null);
    defer mem.free(@ptrCast(with_space.?));
    try std.testing.expectEqualStrings("\"My Folder\"", std.mem.span(with_space.?));

    const escape_only_space = imap_atom("My Folder", true);
    try std.testing.expect(escape_only_space != null);
    defer mem.free(@ptrCast(escape_only_space.?));
    try std.testing.expectEqualStrings("My Folder", std.mem.span(escape_only_space.?));

    const with_quote = imap_atom("a\"b\\c", false);
    try std.testing.expect(with_quote != null);
    defer mem.free(@ptrCast(with_quote.?));
    try std.testing.expectEqualStrings("\"a\\\"b\\\\c\"", std.mem.span(with_quote.?));
}

test "imap_matchresp matching" {
    const line1 = "* CAPABILITY IMAP4rev1 STARTTLS\r\n";
    try std.testing.expect(imap_matchresp(line1, line1.len, "CAPABILITY"));
    try std.testing.expect(!imap_matchresp(line1, line1.len, "LIST"));

    const line2 = "* 42 FETCH (BODY[] {123}\r\n";
    try std.testing.expect(imap_matchresp(line2, line2.len, "FETCH"));
    try std.testing.expect(!imap_matchresp(line2, line2.len, "SEARCH"));

    const line3 = "* SEARCH\r\n";
    try std.testing.expect(imap_matchresp(line3, line3.len, "SEARCH"));
}

test "imap_is_bchar RFC 5092 validation" {
    try std.testing.expect(imap_is_bchar('A'));
    try std.testing.expect(imap_is_bchar('9'));
    try std.testing.expect(imap_is_bchar('@'));
    try std.testing.expect(imap_is_bchar('%'));
    try std.testing.expect(!imap_is_bchar(';'));
    try std.testing.expect(!imap_is_bchar('?'));
    try std.testing.expect(!imap_is_bchar(' '));
}

test "ws_frame_firstbyte2flags and ws_frame_flags2firstbyte" {
    try std.testing.expectEqual(@as(c_int, @intCast(CURLWS_TEXT)), ws_frame_firstbyte2flags(null, WSBIT_OPCODE_TEXT | WSBIT_FIN, 0));
    try std.testing.expectEqual(@as(c_int, @intCast(CURLWS_BINARY)), ws_frame_firstbyte2flags(null, WSBIT_OPCODE_BIN | WSBIT_FIN, 0));
    try std.testing.expectEqual(@as(c_int, @intCast(CURLWS_CLOSE)), ws_frame_firstbyte2flags(null, WSBIT_OPCODE_CLOSE | WSBIT_FIN, 0));
    try std.testing.expectEqual(@as(c_int, @intCast(CURLWS_PING)), ws_frame_firstbyte2flags(null, WSBIT_OPCODE_PING | WSBIT_FIN, 0));
    try std.testing.expectEqual(@as(c_int, @intCast(CURLWS_PONG)), ws_frame_firstbyte2flags(null, WSBIT_OPCODE_PONG | WSBIT_FIN, 0));

    var fb: u8 = 0;
    try std.testing.expectEqual(CURLE_OK, ws_frame_flags2firstbyte(null, CURLWS_TEXT, false, &fb));
    try std.testing.expectEqual(@as(u8, WSBIT_OPCODE_TEXT | WSBIT_FIN), fb);
    try std.testing.expectEqual(CURLE_OK, ws_frame_flags2firstbyte(null, CURLWS_BINARY | CURLWS_CONT, false, &fb));
    try std.testing.expectEqual(@as(u8, WSBIT_OPCODE_BIN), fb);
}

test "ws_decoder decodes unmasked text frame" {
    var dec: ws_decoder = undefined;
    ws_dec_init(&dec);

    var inq: bufq = undefined;
    io_buffers.Curl_bufq_init2(&inq, 1024, 1, io_buffers.BUFQ_OPT_SOFT_LIMIT);
    defer io_buffers.Curl_bufq_free(&inq);

    const raw_frame = [_]u8{ 0x81, 0x05, 'h', 'e', 'l', 'l', 'o' };
    var written: usize = 0;
    try std.testing.expectEqual(CURLE_OK, io_buffers.Curl_bufq_write(&inq, &raw_frame, raw_frame.len, &written));
    try std.testing.expectEqual(@as(usize, 7), written);

    try std.testing.expectEqual(CURLE_OK, ws_dec_read_head(&dec, null, &inq));
    try std.testing.expectEqual(@as(curl_off_t, 5), dec.payload_len);
    try std.testing.expectEqual(@as(c_int, @intCast(CURLWS_TEXT)), dec.frame_flags);
}

test "ws_decoder rejects 64-bit MSB-set frame and oversized/fragmented control frames" {
    var dec: ws_decoder = undefined;
    var inq: bufq = undefined;
    io_buffers.Curl_bufq_init2(&inq, 1024, 1, io_buffers.BUFQ_OPT_SOFT_LIMIT);
    defer io_buffers.Curl_bufq_free(&inq);

    // 64-bit WebSocket frame with MSB set (0x8000_0000_0000_0000) -> CURLE_WEIRD_SERVER_REPLY
    ws_dec_init(&dec);
    const msb_frame = [_]u8{ 0x82, 127, 0x80, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 };
    var written: usize = 0;
    try std.testing.expectEqual(CURLE_OK, io_buffers.Curl_bufq_write(&inq, &msb_frame, msb_frame.len, &written));
    try std.testing.expectEqual(CURLE_WEIRD_SERVER_REPLY, ws_dec_read_head(&dec, null, &inq));
    io_buffers.Curl_bufq_reset(&inq);

    // Oversized PING control frame (payload len indicator 126 > 125)
    ws_dec_init(&dec);
    const big_ping = [_]u8{ WSBIT_OPCODE_PING | WSBIT_FIN, 126, 0x00, 0x7e };
    try std.testing.expectEqual(CURLE_OK, io_buffers.Curl_bufq_write(&inq, &big_ping, big_ping.len, &written));
    try std.testing.expectEqual(CURLE_RECV_ERROR, ws_dec_read_head(&dec, null, &inq));
    io_buffers.Curl_bufq_reset(&inq);

    // Fragmented PING control frame (FIN = 0)
    ws_dec_init(&dec);
    const frag_ping = [_]u8{ WSBIT_OPCODE_PING, 0x02, 'h', 'i' };
    try std.testing.expectEqual(CURLE_OK, io_buffers.Curl_bufq_write(&inq, &frag_ping, frag_ping.len, &written));
    try std.testing.expectEqual(CURLE_RECV_ERROR, ws_dec_read_head(&dec, null, &inq));
    io_buffers.Curl_bufq_reset(&inq);

    // IMAP literal parsing checked arithmetic
    try std.testing.expectEqual(@as(?curl_off_t, 42), imap_parse_literal("* 1 FETCH (BODY[] {42}\r\n"));
    try std.testing.expectEqual(@as(?curl_off_t, null), imap_parse_literal("* 1 FETCH (BODY[] {99999999999999999999}\r\n"));
    try std.testing.expectEqual(@as(?curl_off_t, null), imap_parse_literal("* 1 FETCH (BODY[] {-5}\r\n"));
}
