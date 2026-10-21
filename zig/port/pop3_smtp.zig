const std = @import("std");
const builtin = @import("builtin");
const mem = @import("mem.zig");
const primitives = @import("primitives.zig");
const containers = @import("containers.zig");
const os_leaf = @import("os_leaf.zig");
const io_buffers = @import("io_buffers.zig");
const cookie_getinfo_trc = @import("cookie_getinfo_trc.zig");
const netrc_addr_idn = @import("netrc_addr_idn.zig");
const crypto = @import("crypto.zig");

const CURLcode = c_uint;
const CURLE_OK: CURLcode = 0;
const CURLE_FAILED_INIT: CURLcode = 2;
const CURLE_URL_MALFORMAT: CURLcode = 3;
const CURLE_WEIRD_SERVER_REPLY: CURLcode = 8;
const CURLE_REMOTE_ACCESS_DENIED: CURLcode = 9;
const CURLE_OUT_OF_MEMORY: CURLcode = 27;
const CURLE_OPERATION_TIMEDOUT: CURLcode = 28;
const CURLE_SEND_ERROR: CURLcode = 55;
const CURLE_RECV_ERROR: CURLcode = 56;
const CURLE_USE_SSL_FAILED: CURLcode = 64;
const CURLE_LOGIN_DENIED: CURLcode = 67;
const CURLE_AGAIN: CURLcode = 81;

const curl_off_t = i64;
const FIRSTSOCKET: c_int = 0;
const CLIENTWRITE_BODY: c_int = 1 << 0;
const CURLINFO_HEADER_OUT: c_uint = 2;

const USESSL_NONE: u8 = 0;
const USESSL_TRY: u8 = 1;

const PPTRANSFER_BODY: c_uint = 0;
const PPTRANSFER_INFO: c_uint = 1;

const SASL_IDLE: c_uint = 0;
const SASL_INPROGRESS: c_uint = 1;
const SASL_FINAL: c_uint = 2;

const SASL_AUTH_NONE: c_ushort = 0;
const SASL_MECH_EXTERNAL: c_ushort = 1 << 5;
const SASL_AUTH_DEFAULT: c_ushort = 0xffff & ~SASL_MECH_EXTERNAL;
const SASL_FLAG_BASE64: c_ushort = 0x0001;

const HOST_NAME_MAX: usize = 255;
const URLDEC_NO_CTRL: c_uint = 3;
const CURL_CR_CONTENT_ENCODE: c_uint = 3;

const pingpong = cookie_getinfo_trc.pingpong;
const bufref = containers.bufref;
const curl_slist = containers.curl_slist;
const bufq = io_buffers.bufq;

pub const Curl_creader = extern struct {
    criter: *const Curl_criter,
    next: ?*Curl_creader,
    phase: c_uint,
};

pub const Curl_criter = extern struct {
    name: [*:0]const u8,
    do_init: *const fn (data: ?*anyopaque, reader: *Curl_creader) callconv(.c) CURLcode,
    do_read: *const fn (data: ?*anyopaque, reader: *Curl_creader, buf: [*]u8, blen: usize, nread: *usize, eos: *bool) callconv(.c) CURLcode,
    do_close: *const fn (data: ?*anyopaque, reader: *Curl_creader) callconv(.c) void,
    needs_rewind: *const fn (data: ?*anyopaque, reader: *Curl_creader) callconv(.c) bool,
    total_length: *const fn (data: ?*anyopaque, reader: *Curl_creader) callconv(.c) curl_off_t,
    resume_from: *const fn (data: ?*anyopaque, reader: *Curl_creader, offset: curl_off_t) callconv(.c) CURLcode,
    cntrl: *const fn (data: ?*anyopaque, reader: *Curl_creader, opcode: c_uint) callconv(.c) CURLcode,
    is_paused: *const fn (data: ?*anyopaque, reader: *Curl_creader) callconv(.c) bool,
    done: *const fn (data: ?*anyopaque, reader: *Curl_creader, premature: c_int) callconv(.c) void,
    size: usize,
};

extern fn Curl_creader_create(preader: *?*Curl_creader, data: ?*anyopaque, criter: *const Curl_criter, phase: c_uint) callconv(.c) CURLcode;
extern fn Curl_creader_add(data: ?*anyopaque, reader: ?*Curl_creader) callconv(.c) CURLcode;
extern fn Curl_creader_free(data: ?*anyopaque, reader: ?*Curl_creader) callconv(.c) void;
extern fn Curl_creader_read(data: ?*anyopaque, reader: ?*Curl_creader, buf: [*]u8, blen: usize, nread: *usize, eos: *bool) callconv(.c) CURLcode;
extern fn Curl_creader_def_needs_rewind(data: ?*anyopaque, reader: *Curl_creader) callconv(.c) bool;
extern fn Curl_creader_def_resume_from(data: ?*anyopaque, reader: *Curl_creader, offset: curl_off_t) callconv(.c) CURLcode;
extern fn Curl_creader_def_cntrl(data: ?*anyopaque, reader: *Curl_creader, opcode: c_uint) callconv(.c) CURLcode;
extern fn Curl_creader_def_is_paused(data: ?*anyopaque, reader: *Curl_creader) callconv(.c) bool;
extern fn Curl_creader_def_done(data: ?*anyopaque, reader: *Curl_creader, premature: c_int) callconv(.c) void;

const SASLproto = extern struct {
    service: [*:0]const u8,
    sendauth: *const fn (data: ?*anyopaque, mech: [*:0]const u8, ir: *const bufref) callconv(.c) CURLcode,
    contauth: *const fn (data: ?*anyopaque, mech: [*:0]const u8, contauth: *const bufref) callconv(.c) CURLcode,
    cancelauth: *const fn (data: ?*anyopaque, mech: [*:0]const u8) callconv(.c) CURLcode,
    getmessage: *const fn (data: ?*anyopaque, out: *bufref) callconv(.c) CURLcode,
    maxirlen: usize,
    contcode: c_int,
    finalcode: c_int,
    defmechs: c_ushort,
    flags: c_ushort,
};

const SASL = extern struct {
    params: ?*const SASLproto,
    state: c_uint,
    curmech: ?[*:0]const u8,
    authmechs: c_ushort,
    prefmech: c_ushort,
    authused: c_ushort,
    flags: u8,
};

pub const Curl_protocol = extern struct {
    setup_connection: ?*const fn (data: ?*anyopaque, conn: ?*anyopaque) callconv(.c) CURLcode,
    do_it: ?*const fn (data: ?*anyopaque, done: *bool) callconv(.c) CURLcode,
    done: ?*const fn (data: ?*anyopaque, status: CURLcode, premature: bool) callconv(.c) CURLcode,
    do_more: ?*const fn (data: ?*anyopaque, completed: *c_int) callconv(.c) CURLcode,
    connect_it: ?*const fn (data: ?*anyopaque, done: *bool) callconv(.c) CURLcode,
    connecting: ?*const fn (data: ?*anyopaque, done: *bool) callconv(.c) CURLcode,
    doing: ?*const fn (data: ?*anyopaque, dophase_done: *bool) callconv(.c) CURLcode,
    proto_pollset: ?*const fn (data: ?*anyopaque, ps: ?*anyopaque) callconv(.c) CURLcode,
    doing_pollset: ?*const fn (data: ?*anyopaque, ps: ?*anyopaque) callconv(.c) CURLcode,
    domore_pollset: ?*const fn (data: ?*anyopaque, ps: ?*anyopaque) callconv(.c) CURLcode,
    perform_pollset: ?*const fn (data: ?*anyopaque, ps: ?*anyopaque) callconv(.c) CURLcode,
    disconnect: ?*const fn (data: ?*anyopaque, conn: ?*anyopaque, dead_connection: bool) callconv(.c) CURLcode,
    write_resp: ?*const fn (data: ?*anyopaque, buf: [*]const u8, blen: usize, is_eos: bool) callconv(.c) CURLcode,
    write_resp_hd: ?*const fn (data: ?*anyopaque, buf: [*]const u8, blen: usize, is_eos: bool) callconv(.c) CURLcode,
    connection_is_dead: ?*const fn (data: ?*anyopaque, conn: ?*anyopaque) callconv(.c) bool,
    attach: ?*const fn (data: ?*anyopaque, conn: ?*anyopaque) callconv(.c) void,
    follow: ?*const fn (data: ?*anyopaque, newurl: [*:0]const u8, followtype: c_uint) callconv(.c) CURLcode,
};

const CURL_META_POP3_EASY: [*:0]const u8 = "meta:proto:pop3:easy";
const CURL_META_POP3_CONN: [*:0]const u8 = "meta:proto:pop3:conn";
const CURL_META_SMTP_EASY: [*:0]const u8 = "meta:proto:smtp:easy";
const CURL_META_SMTP_CONN: [*:0]const u8 = "meta:proto:smtp:conn";

const Curl_meta_dtor = *const fn (key: ?*const anyopaque, key_len: usize, entry: ?*anyopaque) callconv(.c) void;

// Extern C functions from libcurl & Zig port modules
extern fn Curl_conn_meta_get(conn: ?*anyopaque, key: [*:0]const u8) callconv(.c) ?*anyopaque;
extern fn Curl_conn_meta_set(conn: ?*anyopaque, key: [*:0]const u8, meta_data: ?*anyopaque, meta_dtor: Curl_meta_dtor) callconv(.c) CURLcode;
extern fn Curl_meta_get(data: ?*anyopaque, key: [*:0]const u8) callconv(.c) ?*anyopaque;
extern fn Curl_meta_set(data: ?*anyopaque, key: [*:0]const u8, meta_data: ?*anyopaque, meta_dtor: Curl_meta_dtor) callconv(.c) CURLcode;

extern fn Curl_pp_sendf(data: ?*anyopaque, pp: *pingpong, fmt: [*:0]const u8, ...) callconv(.c) CURLcode;
extern fn Curl_pp_disconnect(pp: *pingpong) callconv(.c) CURLcode;
extern fn Curl_pp_moredata(pp: *const pingpong) callconv(.c) bool;

extern fn Curl_bufref_set(br: *bufref, ptr: ?*const anyopaque, len: usize, dtor: ?containers.BufrefDtor) callconv(.c) void;
extern fn Curl_bufref_ptr(br: *const bufref) callconv(.c) ?[*:0]const u8;
extern fn curlx_memdup0(src: ?[*]const u8, length: usize) callconv(.c) ?[*:0]u8;
extern fn curlx_str_number(linep: *[*:0]const u8, nump: *i64, max: i64) callconv(.c) c_int;
extern fn curl_maprintf(format: [*:0]const u8, ...) callconv(.c) ?[*:0]u8;

extern fn Curl_client_write(data: ?*anyopaque, type_flags: c_int, buf: [*]const u8, blen: usize) callconv(.c) CURLcode;
extern fn Curl_debug(data: ?*anyopaque, info_type: c_uint, ptr: [*]const u8, size: usize) callconv(.c) void;
extern fn Curl_urldecode(s: [*:0]const u8, length: usize, ostring: *?[*:0]u8, olen: ?*usize, ctrl: c_uint) callconv(.c) CURLcode;
extern fn Curl_xfer_setup_nop(data: ?*anyopaque) callconv(.c) void;
extern fn Curl_xfer_setup_recv(data: ?*anyopaque, sockindex: c_int, size: curl_off_t) callconv(.c) void;
extern fn Curl_xfer_setup_send(data: ?*anyopaque, sockindex: c_int) callconv(.c) void;
extern fn Curl_pgrsSetUploadCounter(data: ?*anyopaque, size: curl_off_t) callconv(.c) void;
extern fn Curl_pgrsSetDownloadCounter(data: ?*anyopaque, size: curl_off_t) callconv(.c) void;
extern fn Curl_pgrsSetUploadSize(data: ?*anyopaque, size: curl_off_t) callconv(.c) void;
extern fn Curl_pgrsReset(data: ?*anyopaque) callconv(.c) void;

// C helper functions in lib/sendf.c
extern fn Curl_pop3_smtp_get_conn(data: ?*anyopaque) callconv(.c) ?*anyopaque;
extern fn Curl_pop3_smtp_get_conn_options(conn: ?*const anyopaque) callconv(.c) ?[*:0]const u8;
extern fn Curl_pop3_smtp_conn_has_creds(conn: ?*const anyopaque) callconv(.c) bool;
extern fn Curl_pop3_smtp_easy_has_creds(data: ?*const anyopaque) callconv(.c) bool;
extern fn Curl_pop3_smtp_get_conn_user(conn: ?*const anyopaque) callconv(.c) ?[*:0]const u8;
extern fn Curl_pop3_smtp_get_conn_passwd(conn: ?*const anyopaque) callconv(.c) ?[*:0]const u8;
extern fn Curl_pop3_smtp_get_protoconnstart(conn: ?*const anyopaque) callconv(.c) bool;
extern fn Curl_pop3_smtp_connclose(conn: ?*anyopaque) callconv(.c) void;
extern fn Curl_pop3_smtp_conn_is_ssl(conn: ?*anyopaque) callconv(.c) bool;
extern fn Curl_pop3_smtp_conn_is_connected(conn: ?*anyopaque) callconv(.c) bool;
extern fn Curl_pop3_smtp_upgrade_tls(data: ?*anyopaque, conn: ?*anyopaque, is_smtp: bool, ssldone: *bool) callconv(.c) CURLcode;
extern fn Curl_pop3_smtp_get_up_path(data: ?*const anyopaque) callconv(.c) ?[*:0]const u8;
extern fn Curl_pop3_smtp_get_customrequest(data: ?*const anyopaque) callconv(.c) ?[*:0]const u8;
extern fn Curl_pop3_smtp_get_mail_from(data: ?*const anyopaque) callconv(.c) ?[*:0]const u8;
extern fn Curl_pop3_smtp_get_mail_auth(data: ?*const anyopaque) callconv(.c) ?[*:0]const u8;
extern fn Curl_pop3_smtp_get_list_only(data: ?*const anyopaque) callconv(.c) bool;
extern fn Curl_pop3_smtp_get_use_ssl(data: ?*const anyopaque) callconv(.c) u8;
extern fn Curl_pop3_smtp_get_connect_only(data: ?*const anyopaque) callconv(.c) bool;
extern fn Curl_pop3_smtp_get_mail_rcpt(data: ?*const anyopaque) callconv(.c) ?*curl_slist;
extern fn Curl_pop3_smtp_get_mail_rcpt_allowfails(data: ?*const anyopaque) callconv(.c) bool;
extern fn Curl_pop3_smtp_get_req_no_body(data: ?*const anyopaque) callconv(.c) bool;
extern fn Curl_pop3_smtp_set_req_no_body(data: ?*anyopaque, val: bool) callconv(.c) void;
extern fn Curl_pop3_smtp_set_req_size(data: ?*anyopaque, size: curl_off_t) callconv(.c) void;
extern fn Curl_pop3_smtp_req_clear_recv(data: ?*anyopaque) callconv(.c) void;
extern fn Curl_pop3_smtp_get_infilesize(data: ?*const anyopaque) callconv(.c) curl_off_t;
extern fn Curl_pop3_smtp_inc_infilesize(data: ?*anyopaque) callconv(.c) void;
extern fn Curl_pop3_smtp_set_httpcode(data: ?*anyopaque, code: c_int) callconv(.c) void;
extern fn Curl_pop3_smtp_is_upload_or_mime(data: ?*const anyopaque) callconv(.c) bool;
extern fn Curl_pop3_smtp_prepare_mail_reader(data: ?*anyopaque) callconv(.c) CURLcode;
extern fn Curl_pop3_smtp_pp_init(data: ?*anyopaque, pp: *pingpong) callconv(.c) void;
extern fn Curl_pop3_smtp_pp_statemach(data: ?*anyopaque, pp: *pingpong, block: bool, disconnecting: bool) callconv(.c) CURLcode;
extern fn Curl_pop3_smtp_pp_readresp(data: ?*anyopaque, sockindex: c_int, pp: *pingpong, code: *c_int, size: *usize) callconv(.c) CURLcode;
extern fn Curl_pop3_smtp_pp_pollset(data: ?*anyopaque, pp: *pingpong, ps: ?*anyopaque) callconv(.c) CURLcode;
extern fn Curl_pop3_smtp_sasl_init(sasl: *SASL, data: ?*anyopaque, params: *const SASLproto) callconv(.c) void;
extern fn Curl_pop3_smtp_sasl_can_authenticate(sasl: *SASL, data: ?*anyopaque) callconv(.c) bool;
extern fn Curl_pop3_smtp_sasl_start(sasl: *SASL, data: ?*anyopaque, force_ir: bool, progress: *c_uint) callconv(.c) CURLcode;
extern fn Curl_pop3_smtp_sasl_continue(sasl: *SASL, data: ?*anyopaque, code: c_int, progress: *c_uint) callconv(.c) CURLcode;
extern fn Curl_pop3_smtp_sasl_is_blocked(sasl: *SASL, data: ?*anyopaque) callconv(.c) CURLcode;
extern fn Curl_pop3_smtp_sasl_decode_mech(ptr: [*]const u8, maxlen: usize, len: *usize) callconv(.c) c_ushort;
extern fn Curl_pop3_smtp_sasl_parse_url_auth_option(sasl: *SASL, value: [*]const u8, len: usize) callconv(.c) CURLcode;
extern fn Curl_pop3_smtp_sasl_get_prefmech(sasl: *const SASL) callconv(.c) c_ushort;
extern fn Curl_pop3_smtp_sasl_set_prefmech(sasl: *SASL, prefmech: c_ushort) callconv(.c) void;
extern fn Curl_pop3_smtp_sasl_set_authmechs(sasl: *SASL, authmechs: c_ushort) callconv(.c) void;
extern fn Curl_pop3_smtp_sasl_or_authmechs(sasl: *SASL, mech: c_ushort) callconv(.c) void;
extern fn Curl_pop3_smtp_sasl_get_authused(sasl: *const SASL) callconv(.c) c_ushort;
extern fn Curl_pop3_smtp_sasl_set_authused(sasl: *SASL, authused: c_ushort) callconv(.c) void;
extern fn Curl_pop3_smtp_failf_msg(data: ?*anyopaque, msg: [*:0]const u8) callconv(.c) void;
extern fn Curl_pop3_smtp_failf_int(data: ?*anyopaque, fmt: [*:0]const u8, arg: c_int) callconv(.c) void;
extern fn Curl_pop3_smtp_infof_msg(data: ?*anyopaque, msg: [*:0]const u8) callconv(.c) void;
extern fn Curl_pop3_smtp_trc_m(data: ?*anyopaque, msg: [*:0]const u8) callconv(.c) void;
extern fn Curl_pop3_smtp_trc_smtp_msg(data: ?*anyopaque, msg: [*:0]const u8) callconv(.c) void;
extern fn Curl_pop3_smtp_trc_smtp_state(data: ?*anyopaque, from: [*:0]const u8, to: [*:0]const u8) callconv(.c) void;
extern fn Curl_pop3_smtp_trc_smtp_int(data: ?*anyopaque, fmt: [*:0]const u8, a1: c_int) callconv(.c) void;
extern fn Curl_pop3_smtp_trc_smtp_int_int(data: ?*anyopaque, fmt: [*:0]const u8, a1: c_int, a2: c_int) callconv(.c) void;
extern fn Curl_pop3_smtp_trc_smtp_int_int_int(data: ?*anyopaque, fmt: [*:0]const u8, a1: c_int, a2: c_int, a3: c_int) callconv(.c) void;
extern fn Curl_pop3_smtp_trc_smtp_read(data: ?*anyopaque, blen: usize, res: c_int, nread: usize, eos: c_int) callconv(.c) void;

// ============================================================================
// POP3 Implementation (ported from lib/pop3.c)
// ============================================================================

const POP3_TYPE_CLEARTEXT: u8 = 1 << 0;
const POP3_TYPE_APOP: u8 = 1 << 1;
const POP3_TYPE_SASL: u8 = 1 << 2;
const POP3_TYPE_ANY: u8 = 0xff;

const POP3_EOB = "\r\n.\r\n";
const POP3_EOB_LEN: usize = 5;

const pop3state = enum(c_uint) {
    POP3_STOP = 0,
    POP3_SERVERGREET,
    POP3_CAPA,
    POP3_STARTTLS,
    POP3_UPGRADETLS,
    POP3_AUTH,
    POP3_APOP,
    POP3_USER,
    POP3_PASS,
    POP3_COMMAND,
    POP3_QUIT,
    POP3_LAST,
};

const POP3 = extern struct {
    transfer: c_uint,
    id: ?[*:0]u8,
    custom: ?[*:0]u8,
};

const pop3_conn = extern struct {
    pp: pingpong,
    state: pop3state,
    eob: usize,
    strip: usize,
    sasl: SASL,
    apoptimestamp: ?[*:0]u8,
    authtypes: u8,
    preftype: u8,
    ssldone: bool,
    tls_supported: bool,
    utf8_supported: bool,
};

const pop3_cmd = struct {
    name: []const u8,
    nlen: u16,
    multiline: bool,
    multiline_with_args: bool,
};

const pop3cmds = [_]pop3_cmd{
    .{ .name = "APOP", .nlen = 4, .multiline = false, .multiline_with_args = false },
    .{ .name = "AUTH", .nlen = 4, .multiline = false, .multiline_with_args = false },
    .{ .name = "CAPA", .nlen = 4, .multiline = true, .multiline_with_args = true },
    .{ .name = "DELE", .nlen = 4, .multiline = false, .multiline_with_args = false },
    .{ .name = "LIST", .nlen = 4, .multiline = true, .multiline_with_args = false },
    .{ .name = "MSG", .nlen = 3, .multiline = true, .multiline_with_args = true },
    .{ .name = "NOOP", .nlen = 4, .multiline = false, .multiline_with_args = false },
    .{ .name = "PASS", .nlen = 4, .multiline = false, .multiline_with_args = false },
    .{ .name = "QUIT", .nlen = 4, .multiline = false, .multiline_with_args = false },
    .{ .name = "RETR", .nlen = 4, .multiline = true, .multiline_with_args = true },
    .{ .name = "RSET", .nlen = 4, .multiline = false, .multiline_with_args = false },
    .{ .name = "STAT", .nlen = 4, .multiline = false, .multiline_with_args = false },
    .{ .name = "STLS", .nlen = 4, .multiline = false, .multiline_with_args = false },
    .{ .name = "TOP", .nlen = 3, .multiline = true, .multiline_with_args = true },
    .{ .name = "UIDL", .nlen = 4, .multiline = true, .multiline_with_args = false },
    .{ .name = "USER", .nlen = 4, .multiline = false, .multiline_with_args = false },
    .{ .name = "UTF8", .nlen = 4, .multiline = false, .multiline_with_args = false },
    .{ .name = "XTND", .nlen = 4, .multiline = true, .multiline_with_args = true },
};

fn pop3_is_multiline(cmdline: [*:0]const u8) bool {
    for (pop3cmds) |cmd| {
        if (primitives.curl_strnequal(cmdline, @ptrCast(cmd.name.ptr), cmd.nlen) != 0) {
            if (cmdline[cmd.nlen] == 0)
                return cmd.multiline;
            if (cmdline[cmd.nlen] == ' ')
                return cmd.multiline_with_args;
        }
    }
    return true;
}

const saslpop3 = SASLproto{
    .service = "pop",
    .sendauth = pop3_perform_auth,
    .contauth = pop3_continue_auth,
    .cancelauth = pop3_cancel_auth,
    .getmessage = pop3_get_message,
    .maxirlen = 255 - 8,
    .contcode = '*',
    .finalcode = '+',
    .defmechs = SASL_AUTH_DEFAULT,
    .flags = SASL_FLAG_BASE64,
};

fn pop3_endofresp(
    data: ?*anyopaque,
    conn: ?*anyopaque,
    line: [*]const u8,
    len: usize,
    resp: *c_int,
) callconv(.c) bool {
    _ = data;
    const pop3c_raw = Curl_conn_meta_get(conn, CURL_META_POP3_CONN) orelse return true;
    const pop3c: *pop3_conn = @ptrCast(@alignCast(pop3c_raw));

    if (len >= 4 and std.mem.eql(u8, line[0..4], "-ERR")) {
        resp.* = '-';
        return true;
    }

    if (pop3c.state == .POP3_CAPA) {
        if ((len == 3 and line[0] == '.' and line[1] == '\r') or
            (len == 2 and line[0] == '.' and line[1] == '\n'))
        {
            resp.* = '+';
        } else {
            resp.* = '*';
        }
        return true;
    }

    if (len >= 3 and std.mem.eql(u8, line[0..3], "+OK")) {
        resp.* = '+';
        return true;
    }

    if (len >= 1 and line[0] == '+') {
        resp.* = '*';
        return true;
    }

    return false;
}

fn pop3_get_message(data: ?*anyopaque, out: *bufref) callconv(.c) CURLcode {
    const conn = Curl_pop3_smtp_get_conn(data);
    const pop3c_raw = Curl_conn_meta_get(conn, CURL_META_POP3_CONN) orelse return CURLE_FAILED_INIT;
    const pop3c: *pop3_conn = @ptrCast(@alignCast(pop3c_raw));
    const msg_ptr = containers.curlx_dyn_ptr(&pop3c.pp.recvbuf);
    var len = pop3c.pp.nfinal;

    if (msg_ptr) |base| {
        if (len > 2) {
            var message: [*]u8 = base + 2;
            len -= 2;
            while (len > 0 and (message[0] == ' ' or message[0] == '\t')) {
                message += 1;
                len -= 1;
            }
            while (len > 0) : (len -= 1) {
                const c = message[len - 1];
                if (c != '\r' and c != '\n' and c != ' ' and c != '\t')
                    break;
            }
            message[len] = 0;
            Curl_bufref_set(out, message, len, null);
            return CURLE_OK;
        }
    }
    Curl_bufref_set(out, "", 0, null);
    return CURLE_OK;
}

fn pop3_state(data: ?*anyopaque, newstate: pop3state) void {
    const conn = Curl_pop3_smtp_get_conn(data);
    const pop3c_raw = Curl_conn_meta_get(conn, CURL_META_POP3_CONN) orelse return;
    const pop3c: *pop3_conn = @ptrCast(@alignCast(pop3c_raw));
    pop3c.state = newstate;
}

fn pop3_perform_capa(data: ?*anyopaque, conn: ?*anyopaque) CURLcode {
    const pop3c_raw = Curl_conn_meta_get(conn, CURL_META_POP3_CONN) orelse return CURLE_FAILED_INIT;
    const pop3c: *pop3_conn = @ptrCast(@alignCast(pop3c_raw));

    Curl_pop3_smtp_sasl_set_authmechs(&pop3c.sasl, SASL_AUTH_NONE);
    Curl_pop3_smtp_sasl_set_authused(&pop3c.sasl, SASL_AUTH_NONE);
    pop3c.tls_supported = false;

    const result = Curl_pp_sendf(data, &pop3c.pp, "%s", @as([*:0]const u8, "CAPA"));
    if (result == CURLE_OK)
        pop3_state(data, .POP3_CAPA);

    return result;
}

fn pop3_perform_starttls(data: ?*anyopaque, conn: ?*anyopaque) CURLcode {
    const pop3c_raw = Curl_conn_meta_get(conn, CURL_META_POP3_CONN) orelse return CURLE_FAILED_INIT;
    const pop3c: *pop3_conn = @ptrCast(@alignCast(pop3c_raw));

    const result = Curl_pp_sendf(data, &pop3c.pp, "%s", @as([*:0]const u8, "STLS"));
    if (result == CURLE_OK)
        pop3_state(data, .POP3_STARTTLS);

    return result;
}

fn pop3_perform_upgrade_tls(data: ?*anyopaque, conn: ?*anyopaque) CURLcode {
    const pop3c_raw = Curl_conn_meta_get(conn, CURL_META_POP3_CONN) orelse return CURLE_FAILED_INIT;
    const pop3c: *pop3_conn = @ptrCast(@alignCast(pop3c_raw));

    var ssldone: bool = false;
    var result = Curl_pop3_smtp_upgrade_tls(data, conn, false, &ssldone);
    if (result == CURLE_OK and ssldone) {
        pop3c.ssldone = ssldone;
        result = pop3_perform_capa(data, conn);
    }
    return result;
}

fn pop3_perform_user(data: ?*anyopaque, conn: ?*anyopaque) CURLcode {
    const pop3c_raw = Curl_conn_meta_get(conn, CURL_META_POP3_CONN) orelse return CURLE_FAILED_INIT;
    const pop3c: *pop3_conn = @ptrCast(@alignCast(pop3c_raw));

    if (!Curl_pop3_smtp_conn_has_creds(conn)) {
        pop3_state(data, .POP3_STOP);
        return CURLE_OK;
    }

    const user: [*:0]const u8 = Curl_pop3_smtp_get_conn_user(conn) orelse "";
    const result = Curl_pp_sendf(data, &pop3c.pp, "USER %s", user);
    if (result == CURLE_OK)
        pop3_state(data, .POP3_USER);

    return result;
}

fn pop3_perform_apop(data: ?*anyopaque, conn: ?*anyopaque) CURLcode {
    const pop3c_raw = Curl_conn_meta_get(conn, CURL_META_POP3_CONN) orelse return CURLE_FAILED_INIT;
    const pop3c: *pop3_conn = @ptrCast(@alignCast(pop3c_raw));

    if (!Curl_pop3_smtp_easy_has_creds(data)) {
        pop3_state(data, .POP3_STOP);
        return CURLE_OK;
    }

    const ts = pop3c.apoptimestamp orelse return CURLE_FAILED_INIT;
    const ctxt = crypto.Curl_MD5_init(&crypto.Curl_DIGEST_MD5[0]) orelse return CURLE_OUT_OF_MEMORY;

    var result = crypto.Curl_MD5_update(ctxt, ts, primitives.curlx_uztoui(std.mem.len(ts)));
    const passwd: [*:0]const u8 = Curl_pop3_smtp_get_conn_passwd(conn) orelse "";
    if (result == CURLE_OK)
        result = crypto.Curl_MD5_update(ctxt, passwd, primitives.curlx_uztoui(std.mem.len(passwd)));

    var digest: [16]u8 = undefined;
    if (result == CURLE_OK)
        result = crypto.Curl_MD5_final(ctxt, &digest);
    if (result != CURLE_OK)
        return result;

    const hex_chars = "0123456789abcdef";
    var secret: [33]u8 = undefined;
    for (digest, 0..) |b, i| {
        secret[2 * i] = hex_chars[b >> 4];
        secret[2 * i + 1] = hex_chars[b & 0x0f];
    }
    secret[32] = 0;

    const user: [*:0]const u8 = Curl_pop3_smtp_get_conn_user(conn) orelse "";
    result = Curl_pp_sendf(data, &pop3c.pp, "APOP %s %s", user, @as([*:0]const u8, @ptrCast(&secret)));
    if (result == CURLE_OK)
        pop3_state(data, .POP3_APOP);

    return result;
}

fn pop3_perform_auth(data: ?*anyopaque, mech: [*:0]const u8, initresp: *const bufref) callconv(.c) CURLcode {
    const conn = Curl_pop3_smtp_get_conn(data);
    const pop3c_raw = Curl_conn_meta_get(conn, CURL_META_POP3_CONN) orelse return CURLE_FAILED_INIT;
    const pop3c: *pop3_conn = @ptrCast(@alignCast(pop3c_raw));

    const ir = Curl_bufref_ptr(initresp);
    if (ir) |ir_str| {
        const arg: [*:0]const u8 = if (ir_str[0] != 0) ir_str else "=";
        return Curl_pp_sendf(data, &pop3c.pp, "AUTH %s %s", mech, arg);
    }
    return Curl_pp_sendf(data, &pop3c.pp, "AUTH %s", mech);
}

fn pop3_continue_auth(data: ?*anyopaque, mech: [*:0]const u8, resp: *const bufref) callconv(.c) CURLcode {
    _ = mech;
    const conn = Curl_pop3_smtp_get_conn(data);
    const pop3c_raw = Curl_conn_meta_get(conn, CURL_META_POP3_CONN) orelse return CURLE_FAILED_INIT;
    const pop3c: *pop3_conn = @ptrCast(@alignCast(pop3c_raw));

    const r = Curl_bufref_ptr(resp) orelse @as([*:0]const u8, "");
    return Curl_pp_sendf(data, &pop3c.pp, "%s", r);
}

fn pop3_cancel_auth(data: ?*anyopaque, mech: [*:0]const u8) callconv(.c) CURLcode {
    _ = mech;
    const conn = Curl_pop3_smtp_get_conn(data);
    const pop3c_raw = Curl_conn_meta_get(conn, CURL_META_POP3_CONN) orelse return CURLE_FAILED_INIT;
    const pop3c: *pop3_conn = @ptrCast(@alignCast(pop3c_raw));

    return Curl_pp_sendf(data, &pop3c.pp, "*");
}

fn pop3_perform_authentication(data: ?*anyopaque, conn: ?*anyopaque) CURLcode {
    const pop3c_raw = Curl_conn_meta_get(conn, CURL_META_POP3_CONN) orelse return CURLE_FAILED_INIT;
    const pop3c: *pop3_conn = @ptrCast(@alignCast(pop3c_raw));
    var result: CURLcode = CURLE_OK;
    var progress: c_uint = SASL_IDLE;

    if (!Curl_pop3_smtp_sasl_can_authenticate(&pop3c.sasl, data)) {
        pop3_state(data, .POP3_STOP);
        return result;
    }

    if ((pop3c.authtypes & pop3c.preftype & POP3_TYPE_SASL) != 0) {
        result = Curl_pop3_smtp_sasl_start(&pop3c.sasl, data, false, &progress);
        if (result == CURLE_OK) {
            if (progress == SASL_INPROGRESS)
                pop3_state(data, .POP3_AUTH);
        }
    }

    if (result == CURLE_OK and progress == SASL_IDLE) {
        if ((pop3c.authtypes & pop3c.preftype & POP3_TYPE_APOP) != 0) {
            result = pop3_perform_apop(data, conn);
        } else if ((pop3c.authtypes & pop3c.preftype & POP3_TYPE_CLEARTEXT) != 0) {
            result = pop3_perform_user(data, conn);
        } else {
            Curl_pop3_smtp_infof_msg(data, "No known authentication mechanisms supported");
            result = CURLE_LOGIN_DENIED;
        }
    }

    return result;
}

fn pop3_perform_command(data: ?*anyopaque) CURLcode {
    const conn = Curl_pop3_smtp_get_conn(data);
    const pop3c_raw = Curl_conn_meta_get(conn, CURL_META_POP3_CONN) orelse return CURLE_FAILED_INIT;
    const pop3c: *pop3_conn = @ptrCast(@alignCast(pop3c_raw));
    const pop3_raw = Curl_meta_get(data, CURL_META_POP3_EASY) orelse return CURLE_FAILED_INIT;
    const pop3: *POP3 = @ptrCast(@alignCast(pop3_raw));

    const id_str: [*:0]const u8 = if (pop3.id) |id| id else "";
    var command: [*:0]const u8 = undefined;

    if (id_str[0] == 0 or Curl_pop3_smtp_get_list_only(data)) {
        command = "LIST";
        if (id_str[0] != 0)
            pop3.transfer = PPTRANSFER_INFO;
    } else {
        command = "RETR";
    }

    if (pop3.custom) |cust| {
        if (cust[0] != 0)
            command = cust;
    }

    const result = if (id_str[0] != 0)
        Curl_pp_sendf(data, &pop3c.pp, "%s %s", command, id_str)
    else
        Curl_pp_sendf(data, &pop3c.pp, "%s", command);

    if (result == CURLE_OK) {
        pop3_state(data, .POP3_COMMAND);
        Curl_pop3_smtp_set_req_no_body(data, !pop3_is_multiline(command));
    }

    return result;
}

fn pop3_perform_quit(data: ?*anyopaque, conn: ?*anyopaque) CURLcode {
    const pop3c_raw = Curl_conn_meta_get(conn, CURL_META_POP3_CONN) orelse return CURLE_FAILED_INIT;
    const pop3c: *pop3_conn = @ptrCast(@alignCast(pop3c_raw));

    const result = Curl_pp_sendf(data, &pop3c.pp, "%s", @as([*:0]const u8, "QUIT"));
    if (result == CURLE_OK)
        pop3_state(data, .POP3_QUIT);

    return result;
}

fn pop3_state_servergreet_resp(data: ?*anyopaque, pop3code: c_int, instate: pop3state) CURLcode {
    _ = instate;
    var result: CURLcode = CURLE_OK;
    const conn = Curl_pop3_smtp_get_conn(data);
    const pop3c_raw = Curl_conn_meta_get(conn, CURL_META_POP3_CONN) orelse return CURLE_FAILED_INIT;
    const pop3c: *pop3_conn = @ptrCast(@alignCast(pop3c_raw));
    const line_opt = containers.curlx_dyn_ptr(&pop3c.pp.recvbuf);
    const len = pop3c.pp.nfinal;

    if (pop3code != '+') {
        Curl_pop3_smtp_failf_msg(data, "Got unexpected pop3-server response");
        result = CURLE_WEIRD_SERVER_REPLY;
    } else if (len > 3) {
        if (line_opt) |line| {
            const slice = line[0..len];
            if (std.mem.indexOfScalar(u8, slice, '<')) |lt_idx| {
                const rem = slice[lt_idx..];
                if (std.mem.indexOfScalar(u8, rem, '>')) |gt_rel| {
                    const timestamplen = gt_rel + 1;
                    const ts_slice = rem[0..timestamplen];
                    if (std.mem.indexOfScalar(u8, ts_slice, '@') != null) {
                        pop3c.apoptimestamp = curlx_memdup0(ts_slice.ptr, timestamplen) orelse return CURLE_OUT_OF_MEMORY;
                        pop3c.authtypes |= POP3_TYPE_APOP;
                    }
                }
            }
        }
        if (result == CURLE_OK)
            result = pop3_perform_capa(data, conn);
    }

    return result;
}

fn pop3_state_capa_resp(data: ?*anyopaque, pop3code: c_int, instate: pop3state) CURLcode {
    _ = instate;
    var result: CURLcode = CURLE_OK;
    const conn = Curl_pop3_smtp_get_conn(data);
    const pop3c_raw = Curl_conn_meta_get(conn, CURL_META_POP3_CONN) orelse return CURLE_FAILED_INIT;
    const pop3c: *pop3_conn = @ptrCast(@alignCast(pop3c_raw));
    const line_opt = containers.curlx_dyn_ptr(&pop3c.pp.recvbuf);
    var len = pop3c.pp.nfinal;

    if (pop3code == '*') {
        if (line_opt) |line| {
            if (len >= 4 and std.mem.eql(u8, line[0..4], "STLS")) {
                pop3c.tls_supported = true;
            } else if (len >= 4 and std.mem.eql(u8, line[0..4], "USER")) {
                pop3c.authtypes |= POP3_TYPE_CLEARTEXT;
            } else if (len >= 5 and std.mem.eql(u8, line[0..5], "SASL ")) {
                pop3c.authtypes |= POP3_TYPE_SASL;
                var idx: usize = 5;
                len -= 5;
                while (true) {
                    while (len > 0 and (line[idx] == ' ' or line[idx] == '\t' or line[idx] == '\r' or line[idx] == '\n')) {
                        idx += 1;
                        len -= 1;
                    }
                    if (len == 0)
                        break;
                    var wordlen: usize = 0;
                    while (wordlen < len and line[idx + wordlen] != ' ' and line[idx + wordlen] != '\t' and line[idx + wordlen] != '\r' and line[idx + wordlen] != '\n') : (wordlen += 1) {}
                    var llen: usize = 0;
                    const mechbit = Curl_pop3_smtp_sasl_decode_mech(line + idx, wordlen, &llen);
                    if (mechbit != 0 and llen == wordlen)
                        Curl_pop3_smtp_sasl_or_authmechs(&pop3c.sasl, mechbit);
                    idx += wordlen;
                    len -= wordlen;
                }
            } else if (len >= 4 and std.mem.eql(u8, line[0..4], "UTF8")) {
                pop3c.utf8_supported = true;
            }
        }
    } else {
        if (pop3code != '+') {
            pop3c.authtypes |= POP3_TYPE_CLEARTEXT;
        }
        const use_ssl = Curl_pop3_smtp_get_use_ssl(data);
        if (use_ssl == USESSL_NONE or Curl_pop3_smtp_conn_is_ssl(conn)) {
            result = pop3_perform_authentication(data, conn);
        } else if (pop3code == '+' and pop3c.tls_supported) {
            result = pop3_perform_starttls(data, conn);
        } else if (use_ssl <= USESSL_TRY) {
            result = pop3_perform_authentication(data, conn);
        } else {
            Curl_pop3_smtp_failf_msg(data, "STLS not supported.");
            result = CURLE_USE_SSL_FAILED;
        }
    }

    return result;
}

fn pop3_state_starttls_resp(data: ?*anyopaque, conn: ?*anyopaque, pop3code: c_int, instate: pop3state) CURLcode {
    _ = instate;
    var result: CURLcode = CURLE_OK;
    const pop3c_raw = Curl_conn_meta_get(conn, CURL_META_POP3_CONN) orelse return CURLE_FAILED_INIT;
    const pop3c: *pop3_conn = @ptrCast(@alignCast(pop3c_raw));

    if (pop3c.pp.overflow != 0)
        return CURLE_WEIRD_SERVER_REPLY;

    if (pop3code != '+') {
        if (Curl_pop3_smtp_get_use_ssl(data) != USESSL_TRY) {
            Curl_pop3_smtp_failf_msg(data, "STARTTLS denied");
            result = CURLE_USE_SSL_FAILED;
        } else {
            result = pop3_perform_authentication(data, conn);
        }
    } else {
        pop3_state(data, .POP3_UPGRADETLS);
        result = pop3_perform_upgrade_tls(data, conn);
    }

    return result;
}

fn pop3_state_auth_resp(data: ?*anyopaque, pop3code: c_int, instate: pop3state) CURLcode {
    _ = instate;
    var result: CURLcode = CURLE_OK;
    const conn = Curl_pop3_smtp_get_conn(data);
    const pop3c_raw = Curl_conn_meta_get(conn, CURL_META_POP3_CONN) orelse return CURLE_FAILED_INIT;
    const pop3c: *pop3_conn = @ptrCast(@alignCast(pop3c_raw));
    var progress: c_uint = SASL_IDLE;

    result = Curl_pop3_smtp_sasl_continue(&pop3c.sasl, data, pop3code, &progress);
    if (result == CURLE_OK) {
        switch (progress) {
            SASL_FINAL => pop3_state(data, .POP3_STOP),
            SASL_IDLE => {
                if ((pop3c.authtypes & pop3c.preftype & POP3_TYPE_APOP) != 0) {
                    result = pop3_perform_apop(data, conn);
                } else if ((pop3c.authtypes & pop3c.preftype & POP3_TYPE_CLEARTEXT) != 0) {
                    result = pop3_perform_user(data, conn);
                } else {
                    Curl_pop3_smtp_failf_msg(data, "Authentication cancelled");
                    result = CURLE_LOGIN_DENIED;
                }
            },
            else => {},
        }
    }

    return result;
}

fn pop3_state_apop_resp(data: ?*anyopaque, pop3code: c_int, instate: pop3state) CURLcode {
    _ = instate;
    var result: CURLcode = CURLE_OK;
    if (pop3code != '+') {
        Curl_pop3_smtp_failf_int(data, "Authentication failed: %d", pop3code);
        result = CURLE_LOGIN_DENIED;
    } else {
        pop3_state(data, .POP3_STOP);
    }
    return result;
}

fn pop3_state_user_resp(data: ?*anyopaque, pop3code: c_int, instate: pop3state) CURLcode {
    _ = instate;
    var result: CURLcode = CURLE_OK;
    const conn = Curl_pop3_smtp_get_conn(data);
    const pop3c_raw = Curl_conn_meta_get(conn, CURL_META_POP3_CONN) orelse return CURLE_FAILED_INIT;
    const pop3c: *pop3_conn = @ptrCast(@alignCast(pop3c_raw));

    if (pop3code != '+') {
        Curl_pop3_smtp_failf_int(data, "Access denied. %c", pop3code);
        result = CURLE_LOGIN_DENIED;
    } else {
        const passwd: [*:0]const u8 = Curl_pop3_smtp_get_conn_passwd(conn) orelse "";
        result = Curl_pp_sendf(data, &pop3c.pp, "PASS %s", passwd);
        if (result == CURLE_OK)
            pop3_state(data, .POP3_PASS);
    }

    return result;
}

fn pop3_state_pass_resp(data: ?*anyopaque, pop3code: c_int, instate: pop3state) CURLcode {
    _ = instate;
    var result: CURLcode = CURLE_OK;
    if (pop3code != '+') {
        Curl_pop3_smtp_failf_int(data, "Access denied. %c", pop3code);
        result = CURLE_LOGIN_DENIED;
    } else {
        pop3_state(data, .POP3_STOP);
    }
    return result;
}

fn pop3_state_command_resp(data: ?*anyopaque, pop3code: c_int, instate: pop3state) CURLcode {
    _ = instate;
    var result: CURLcode = CURLE_OK;
    const conn = Curl_pop3_smtp_get_conn(data);
    const pop3c_raw = Curl_conn_meta_get(conn, CURL_META_POP3_CONN) orelse return CURLE_FAILED_INIT;
    const pop3c: *pop3_conn = @ptrCast(@alignCast(pop3c_raw));
    const pop3_raw = Curl_meta_get(data, CURL_META_POP3_EASY) orelse return CURLE_FAILED_INIT;
    const pop3: *POP3 = @ptrCast(@alignCast(pop3_raw));
    const pp = &pop3c.pp;

    if (pop3code != '+') {
        pop3_state(data, .POP3_STOP);
        return CURLE_WEIRD_SERVER_REPLY;
    }

    pop3c.eob = 2;
    pop3c.strip = 2;

    if (pop3.transfer == PPTRANSFER_BODY) {
        Curl_xfer_setup_recv(data, FIRSTSOCKET, -1);

        if (pp.overflow != 0) {
            if (containers.curlx_dyn_ptr(&pp.recvbuf)) |recv_ptr| {
                result = Curl_pop3_write(data, recv_ptr + pp.nfinal, pp.overflow);
            }
            containers.curlx_dyn_reset(&pp.recvbuf);
            pp.nfinal = 0;
            pp.overflow = 0;
            if (result != CURLE_OK)
                return result;
        }
    } else {
        pp.overflow = 0;
    }

    pop3_state(data, .POP3_STOP);
    return result;
}

fn pop3_statemachine(data: ?*anyopaque, conn: ?*anyopaque) callconv(.c) CURLcode {
    var result: CURLcode = CURLE_OK;
    var pop3code: c_int = 0;
    const pop3c_raw = Curl_conn_meta_get(conn, CURL_META_POP3_CONN) orelse return CURLE_FAILED_INIT;
    const pop3c: *pop3_conn = @ptrCast(@alignCast(pop3c_raw));
    const pp = &pop3c.pp;
    var nread: usize = 0;

    if (pop3c.state == .POP3_UPGRADETLS)
        return pop3_perform_upgrade_tls(data, conn);

    if (pp.sendleft != 0)
        return Curl_pp_MoreSend(data, pp);

    while (true) {
        result = Curl_pop3_smtp_pp_readresp(data, FIRSTSOCKET, pp, &pop3code, &nread);
        if (result != CURLE_OK)
            return result;

        if (pop3code == 0)
            break;

        const instate = pop3c.state;
        switch (instate) {
            .POP3_SERVERGREET => result = pop3_state_servergreet_resp(data, pop3code, instate),
            .POP3_CAPA => result = pop3_state_capa_resp(data, pop3code, instate),
            .POP3_STARTTLS => result = pop3_state_starttls_resp(data, conn, pop3code, instate),
            .POP3_AUTH => result = pop3_state_auth_resp(data, pop3code, instate),
            .POP3_APOP => result = pop3_state_apop_resp(data, pop3code, instate),
            .POP3_USER => result = pop3_state_user_resp(data, pop3code, instate),
            .POP3_PASS => result = pop3_state_pass_resp(data, pop3code, instate),
            .POP3_COMMAND => result = pop3_state_command_resp(data, pop3code, instate),
            .POP3_QUIT => pop3_state(data, .POP3_STOP),
            else => pop3_state(data, .POP3_STOP),
        }

        if (result != CURLE_OK or pop3c.state == .POP3_STOP or !Curl_pp_moredata(pp))
            break;
    }

    return result;
}

extern fn Curl_pp_flushsend(data: ?*anyopaque, pp: *pingpong) callconv(.c) CURLcode;
inline fn Curl_pp_MoreSend(data: ?*anyopaque, pp: *pingpong) CURLcode {
    return Curl_pp_flushsend(data, pp);
}

fn pop3_multi_statemach(data: ?*anyopaque, done: *bool) callconv(.c) CURLcode {
    const conn = Curl_pop3_smtp_get_conn(data);
    const pop3c_raw = Curl_conn_meta_get(conn, CURL_META_POP3_CONN) orelse return CURLE_FAILED_INIT;
    const pop3c: *pop3_conn = @ptrCast(@alignCast(pop3c_raw));

    const result = Curl_pop3_smtp_pp_statemach(data, &pop3c.pp, false, false);
    done.* = (pop3c.state == .POP3_STOP);
    return result;
}

fn pop3_block_statemach(data: ?*anyopaque, conn: ?*anyopaque, disconnecting: bool) CURLcode {
    const pop3c_raw = Curl_conn_meta_get(conn, CURL_META_POP3_CONN) orelse return CURLE_FAILED_INIT;
    const pop3c: *pop3_conn = @ptrCast(@alignCast(pop3c_raw));
    var result: CURLcode = CURLE_OK;

    while (pop3c.state != .POP3_STOP and result == CURLE_OK)
        result = Curl_pop3_smtp_pp_statemach(data, &pop3c.pp, true, disconnecting);

    return result;
}

fn pop3_easy_dtor(key: ?*const anyopaque, klen: usize, entry: ?*anyopaque) callconv(.c) void {
    _ = key;
    _ = klen;
    const pop3: *POP3 = @ptrCast(@alignCast(entry orelse return));
    if (pop3.id) |id| mem.free(@ptrCast(id));
    if (pop3.custom) |cust| mem.free(@ptrCast(cust));
    mem.freeSized(pop3, @sizeOf(POP3));
}

fn pop3_conn_dtor(key: ?*const anyopaque, klen: usize, entry: ?*anyopaque) callconv(.c) void {
    _ = key;
    _ = klen;
    const pop3c: *pop3_conn = @ptrCast(@alignCast(entry orelse return));
    _ = Curl_pp_disconnect(&pop3c.pp);
    if (pop3c.apoptimestamp) |ts| mem.free(@ptrCast(ts));
    mem.freeSized(pop3c, @sizeOf(pop3_conn));
}

fn pop3_init(data: ?*anyopaque) CURLcode {
    const pop3_raw = mem.calloc(1, @sizeOf(POP3)) orelse return CURLE_OUT_OF_MEMORY;
    return Curl_meta_set(data, CURL_META_POP3_EASY, pop3_raw, pop3_easy_dtor);
}

fn pop3_pollset(data: ?*anyopaque, ps: ?*anyopaque) callconv(.c) CURLcode {
    const conn = Curl_pop3_smtp_get_conn(data);
    const pop3c_raw = Curl_conn_meta_get(conn, CURL_META_POP3_CONN) orelse return CURLE_FAILED_INIT;
    const pop3c: *pop3_conn = @ptrCast(@alignCast(pop3c_raw));
    return Curl_pop3_smtp_pp_pollset(data, &pop3c.pp, ps);
}

fn pop3_connect(data: ?*anyopaque, done: *bool) callconv(.c) CURLcode {
    const conn = Curl_pop3_smtp_get_conn(data);
    const pop3c_raw = Curl_conn_meta_get(conn, CURL_META_POP3_CONN) orelse return CURLE_FAILED_INIT;
    const pop3c: *pop3_conn = @ptrCast(@alignCast(pop3c_raw));
    const pp = &pop3c.pp;

    done.* = false;

    Curl_pop3_smtp_pp_init(data, pp);

    const result = pop3_parse_url_options(conn, pop3c);
    if (result != CURLE_OK)
        return result;

    pop3_state(data, .POP3_SERVERGREET);

    return pop3_multi_statemach(data, done);
}

fn pop3_done(data: ?*anyopaque, status: CURLcode, premature: bool) callconv(.c) CURLcode {
    _ = premature;
    const pop3_raw = Curl_meta_get(data, CURL_META_POP3_EASY) orelse return CURLE_OK;
    const pop3: *POP3 = @ptrCast(@alignCast(pop3_raw));

    if (pop3.id) |id| {
        mem.free(@ptrCast(id));
        pop3.id = null;
    }
    if (pop3.custom) |cust| {
        mem.free(@ptrCast(cust));
        pop3.custom = null;
    }

    pop3.transfer = PPTRANSFER_BODY;
    return status;
}

fn pop3_perform(data: ?*anyopaque, connected: *bool, dophase_done: *bool) CURLcode {
    const conn = Curl_pop3_smtp_get_conn(data);
    const pop3_raw = Curl_meta_get(data, CURL_META_POP3_EASY) orelse return CURLE_FAILED_INIT;
    const pop3: *POP3 = @ptrCast(@alignCast(pop3_raw));

    if (Curl_pop3_smtp_get_req_no_body(data))
        pop3.transfer = PPTRANSFER_INFO;

    dophase_done.* = false;

    var result = pop3_perform_command(data);
    if (result != CURLE_OK)
        return result;

    result = pop3_multi_statemach(data, dophase_done);
    connected.* = Curl_pop3_smtp_conn_is_connected(conn);

    return result;
}

fn pop3_do(data: ?*anyopaque, done: *bool) callconv(.c) CURLcode {
    done.* = false;

    var result = pop3_parse_url_path(data);
    if (result != CURLE_OK)
        return result;

    result = pop3_parse_custom_request(data);
    if (result != CURLE_OK)
        return result;

    return pop3_regular_transfer(data, done);
}

fn pop3_disconnect(data: ?*anyopaque, conn: ?*anyopaque, dead_connection: bool) callconv(.c) CURLcode {
    const pop3c_raw = Curl_conn_meta_get(conn, CURL_META_POP3_CONN) orelse return CURLE_FAILED_INIT;
    const pop3c: *pop3_conn = @ptrCast(@alignCast(pop3c_raw));

    if (!dead_connection and Curl_pop3_smtp_get_protoconnstart(conn)) {
        if (pop3_perform_quit(data, conn) == CURLE_OK)
            _ = pop3_block_statemach(data, conn, true);
    }

    _ = Curl_pp_disconnect(&pop3c.pp);

    if (pop3c.apoptimestamp) |ts| {
        mem.free(@ptrCast(ts));
        pop3c.apoptimestamp = null;
    }

    return CURLE_OK;
}

fn pop3_dophase_done(data: ?*anyopaque, connected: bool) CURLcode {
    _ = data;
    _ = connected;
    return CURLE_OK;
}

fn pop3_doing(data: ?*anyopaque, dophase_done: *bool) callconv(.c) CURLcode {
    var result = pop3_multi_statemach(data, dophase_done);
    if (result == CURLE_OK and dophase_done.*) {
        const conn = Curl_pop3_smtp_get_conn(data);
        result = pop3_dophase_done(data, Curl_pop3_smtp_conn_is_connected(conn));
    }
    return result;
}

fn pop3_regular_transfer(data: ?*anyopaque, dophase_done: *bool) CURLcode {
    var connected: bool = false;

    Curl_pop3_smtp_set_req_size(data, -1);
    Curl_pgrsReset(data);

    var result = pop3_perform(data, &connected, dophase_done);
    if (result == CURLE_OK and dophase_done.*)
        result = pop3_dophase_done(data, connected);

    return result;
}

fn pop3_setup_connection(data: ?*anyopaque, conn: ?*anyopaque) callconv(.c) CURLcode {
    const pop3c_raw = mem.calloc(1, @sizeOf(pop3_conn)) orelse return CURLE_OUT_OF_MEMORY;
    const pop3c: *pop3_conn = @ptrCast(@alignCast(pop3c_raw));

    pop3c.pp.statemachine = @ptrCast(&pop3_statemachine);
    pop3c.pp.endofresp = @ptrCast(&pop3_endofresp);
    pop3c.preftype = POP3_TYPE_ANY;

    Curl_pop3_smtp_sasl_init(&pop3c.sasl, data, &saslpop3);

    if (Curl_conn_meta_set(conn, CURL_META_POP3_CONN, pop3c_raw, pop3_conn_dtor) != CURLE_OK)
        return CURLE_OUT_OF_MEMORY;

    return pop3_init(data);
}

fn pop3_parse_url_options(conn: ?*anyopaque, pop3c: *pop3_conn) CURLcode {
    var result: CURLcode = CURLE_OK;
    var ptr_opt = Curl_pop3_smtp_get_conn_options(conn);

    while (result == CURLE_OK and ptr_opt != null and ptr_opt.?[0] != 0) {
        const ptr = ptr_opt.?;
        const key = ptr;
        var i: usize = 0;
        while (ptr[i] != 0 and ptr[i] != '=') : (i += 1) {}

        const val = ptr + i + 1;
        var vlen: usize = 0;
        while (ptr[i] != 0 and ptr[i] != ';') : (i += 1) {
            if (ptr[i] != '=')
                vlen += 1;
        }
        // Recalculate exact value length from val to ptr + i
        const val_start = @intFromPtr(val);
        const end_ptr = @intFromPtr(ptr + i);
        vlen = if (end_ptr >= val_start) end_ptr - val_start else 0;

        if (primitives.curl_strnequal(key, "AUTH=", 5) != 0) {
            result = Curl_pop3_smtp_sasl_parse_url_auth_option(&pop3c.sasl, val, vlen);
            if (result != CURLE_OK and primitives.curl_strnequal(val, "+APOP", vlen) != 0) {
                pop3c.preftype = POP3_TYPE_APOP;
                Curl_pop3_smtp_sasl_set_prefmech(&pop3c.sasl, SASL_AUTH_NONE);
                result = CURLE_OK;
            }
        } else {
            result = CURLE_URL_MALFORMAT;
        }

        if (ptr[i] == ';')
            i += 1;
        ptr_opt = ptr + i;
    }

    switch (Curl_pop3_smtp_sasl_get_prefmech(&pop3c.sasl)) {
        SASL_AUTH_NONE => pop3c.preftype &= ~POP3_TYPE_SASL,
        SASL_AUTH_DEFAULT => {},
        else => pop3c.preftype = POP3_TYPE_SASL,
    }

    return result;
}

fn pop3_parse_url_path(data: ?*anyopaque) CURLcode {
    const pop3_raw = Curl_meta_get(data, CURL_META_POP3_EASY) orelse return CURLE_FAILED_INIT;
    const pop3: *POP3 = @ptrCast(@alignCast(pop3_raw));
    const path: [*:0]const u8 = Curl_pop3_smtp_get_up_path(data) orelse "/";

    const start: [*:0]const u8 = if (path[0] == '/') path + 1 else path;
    return Curl_urldecode(start, 0, &pop3.id, null, URLDEC_NO_CTRL);
}

fn pop3_parse_custom_request(data: ?*anyopaque) CURLcode {
    var result: CURLcode = CURLE_OK;
    const pop3_raw = Curl_meta_get(data, CURL_META_POP3_EASY) orelse return CURLE_FAILED_INIT;
    const pop3: *POP3 = @ptrCast(@alignCast(pop3_raw));
    const custom = Curl_pop3_smtp_get_customrequest(data);

    if (custom) |cust| {
        result = Curl_urldecode(cust, 0, &pop3.custom, null, URLDEC_NO_CTRL);
    }

    return result;
}

pub export fn Curl_pop3_write(data: ?*anyopaque, str: [*]const u8, nread: usize) callconv(.c) CURLcode {
    var result: CURLcode = CURLE_OK;
    const conn = Curl_pop3_smtp_get_conn(data);
    const pop3c_raw = Curl_conn_meta_get(conn, CURL_META_POP3_CONN) orelse return CURLE_FAILED_INIT;
    const pop3c: *pop3_conn = @ptrCast(@alignCast(pop3c_raw));
    var strip_dot: bool = false;
    var last: usize = 0;

    for (0..nread) |i| {
        const prev = pop3c.eob;
        switch (str[i]) {
            0x0d => {
                if (pop3c.eob == 0) {
                    pop3c.eob += 1;
                    if (i != 0) {
                        result = Curl_client_write(data, CLIENTWRITE_BODY, str + last, i - last);
                        if (result != CURLE_OK)
                            return result;
                        last = i;
                    }
                } else if (pop3c.eob == 3) {
                    pop3c.eob += 1;
                } else {
                    pop3c.eob = 1;
                }
            },
            0x0a => {
                if (pop3c.eob == 1 or pop3c.eob == 4) {
                    pop3c.eob += 1;
                } else {
                    pop3c.eob = 0;
                }
            },
            0x2e => {
                if (pop3c.eob == 2) {
                    pop3c.eob += 1;
                } else if (pop3c.eob == 3) {
                    strip_dot = true;
                    pop3c.eob = 0;
                } else {
                    pop3c.eob = 0;
                }
            },
            else => {
                pop3c.eob = 0;
            },
        }

        if (prev != 0 and prev >= pop3c.eob) {
            var prev_work = prev;
            while (prev_work != 0 and pop3c.strip != 0) {
                prev_work -= 1;
                pop3c.strip -= 1;
            }
            if (prev_work != 0) {
                if (strip_dot and prev_work - 1 > 0) {
                    result = Curl_client_write(data, CLIENTWRITE_BODY, POP3_EOB.ptr, prev_work - 1);
                } else if (!strip_dot) {
                    result = Curl_client_write(data, CLIENTWRITE_BODY, POP3_EOB.ptr, prev_work);
                } else {
                    result = CURLE_OK;
                }
                if (result != CURLE_OK)
                    return result;
                last = i;
                strip_dot = false;
            }
        }
    }

    if (pop3c.eob == POP3_EOB_LEN) {
        result = Curl_client_write(data, CLIENTWRITE_BODY, "\r\n", 2);
        Curl_pop3_smtp_req_clear_recv(data);
        pop3c.eob = 0;
        return result;
    }

    if (pop3c.eob != 0)
        return CURLE_OK;

    if (nread - last != 0) {
        result = Curl_client_write(data, CLIENTWRITE_BODY, str + last, nread - last);
    }

    return result;
}

fn pop3_write_resp_hd(data: ?*anyopaque, buf: [*]const u8, blen: usize, is_eos: bool) callconv(.c) CURLcode {
    _ = data;
    _ = buf;
    _ = blen;
    _ = is_eos;
    return CURLE_RECV_ERROR;
}

fn pop3_write_resp(data: ?*anyopaque, buf: [*]const u8, blen: usize, is_eos: bool) callconv(.c) CURLcode {
    _ = is_eos;
    const conn = Curl_pop3_smtp_get_conn(data);
    if (Curl_conn_meta_get(conn, CURL_META_POP3_CONN) == null)
        return CURLE_RECV_ERROR;
    return Curl_pop3_write(data, buf, blen);
}

pub export const Curl_protocol_pop3 = Curl_protocol{
    .setup_connection = pop3_setup_connection,
    .do_it = pop3_do,
    .done = pop3_done,
    .do_more = null,
    .connect_it = pop3_connect,
    .connecting = pop3_multi_statemach,
    .doing = pop3_doing,
    .proto_pollset = pop3_pollset,
    .doing_pollset = pop3_pollset,
    .domore_pollset = null,
    .perform_pollset = null,
    .disconnect = pop3_disconnect,
    .write_resp = pop3_write_resp,
    .write_resp_hd = pop3_write_resp_hd,
    .connection_is_dead = null,
    .attach = null,
    .follow = null,
};

// ============================================================================
// SMTP Implementation (ported from lib/smtp.c)
// ============================================================================

const SMTP_EOB = "\r\n.\r\n";
const SMTP_EOB_FIND_LEN: usize = 3;

const smtpstate = enum(c_uint) {
    SMTP_STOP = 0,
    SMTP_SERVERGREET,
    SMTP_EHLO,
    SMTP_HELO,
    SMTP_STARTTLS,
    SMTP_UPGRADETLS,
    SMTP_AUTH,
    SMTP_COMMAND,
    SMTP_MAIL,
    SMTP_RCPT,
    SMTP_DATA,
    SMTP_POSTDATA,
    SMTP_QUIT,
    SMTP_LAST,
};

const smtp_state_names = [_][*:0]const u8{
    "STOP",
    "SERVERGREET",
    "EHLO",
    "HELO",
    "STARTTLS",
    "UPGRADETLS",
    "AUTH",
    "COMMAND",
    "MAIL",
    "RCPT",
    "DATA",
    "POSTDATA",
    "QUIT",
};

const SMTP = extern struct {
    transfer: c_uint,
    custom: ?[*:0]u8,
    rcpt: ?*curl_slist,
    rcpt_last_error: c_int,
    eob: usize,
    rcpt_had_ok: bool,
    trailing_crlf: bool,
};

const smtp_conn = extern struct {
    pp: pingpong,
    sasl: SASL,
    state: smtpstate,
    domain: ?[*:0]u8,
    ssldone: bool,
    tls_supported: bool,
    size_supported: bool,
    utf8_supported: bool,
    auth_supported: bool,
};

const saslsmtp = SASLproto{
    .service = "smtp",
    .sendauth = smtp_perform_auth,
    .contauth = smtp_continue_auth,
    .cancelauth = smtp_cancel_auth,
    .getmessage = smtp_get_message,
    .maxirlen = 512 - 8,
    .contcode = 334,
    .finalcode = 235,
    .defmechs = SASL_AUTH_DEFAULT,
    .flags = SASL_FLAG_BASE64,
};

const cr_eob_ctx = extern struct {
    super: Curl_creader,
    buf: bufq,
    n_eob: usize,
    eob_added: bool,
    eos: bool,
};

fn cr_eob_init(data: ?*anyopaque, reader: *Curl_creader) callconv(.c) CURLcode {
    _ = data;
    const ctx: *cr_eob_ctx = @fieldParentPtr("super", reader);
    io_buffers.Curl_bufq_init2(&ctx.buf, 16 * 1024, 1, io_buffers.BUFQ_OPT_SOFT_LIMIT);
    return CURLE_OK;
}

fn cr_eob_close(data: ?*anyopaque, reader: *Curl_creader) callconv(.c) void {
    _ = data;
    const ctx: *cr_eob_ctx = @fieldParentPtr("super", reader);
    io_buffers.Curl_bufq_free(&ctx.buf);
}

fn cr_eob_read(
    data: ?*anyopaque,
    reader: *Curl_creader,
    buf: [*]u8,
    blen: usize,
    pnread: *usize,
    peos: *bool,
) callconv(.c) CURLcode {
    const ctx: *cr_eob_ctx = @fieldParentPtr("super", reader);
    var result: CURLcode = CURLE_OK;
    var nread: usize = 0;
    var i: usize = 0;
    var start: usize = 0;
    var eos: bool = false;

    if (!ctx.eos and io_buffers.Curl_bufq_is_empty(&ctx.buf)) {
        result = Curl_creader_read(data, reader.next, buf, blen, &nread, &eos);
        Curl_pop3_smtp_trc_smtp_read(data, blen, @intCast(result), nread, @intFromBool(eos));
        if (result != CURLE_OK)
            return result;

        ctx.eos = eos;
        if (nread != 0) {
            if (ctx.n_eob == 0 and buf[0] == '.') {
                result = io_buffers.Curl_bufq_cwrite(&ctx.buf, SMTP_EOB.ptr + 2, 1, &nread);
                if (result != CURLE_OK)
                    return result;
            }
            for (0..nread) |idx| {
                i = idx;
                const prev = ctx.n_eob;
                switch (buf[i]) {
                    0x0d => ctx.n_eob = 1,
                    0x0a => {
                        if (ctx.n_eob == 1 or ctx.n_eob == 4)
                            ctx.n_eob += 1
                        else
                            ctx.n_eob = 0;
                    },
                    0x2e => {
                        if (ctx.n_eob == 2)
                            ctx.n_eob += 1
                        else
                            ctx.n_eob = 0;
                    },
                    else => ctx.n_eob = 0,
                }

                if (prev != 0 and prev >= ctx.n_eob) {
                    result = io_buffers.Curl_bufq_cwrite(&ctx.buf, SMTP_EOB.ptr, prev, &nread);
                    if (result != CURLE_OK)
                        return result;
                    if (ctx.n_eob == 0)
                        start = i
                    else
                        start = i + 1;
                } else if (ctx.n_eob == SMTP_EOB_FIND_LEN) {
                    result = io_buffers.Curl_bufq_cwrite(&ctx.buf, "..", 2, &nread);
                    if (result != CURLE_OK)
                        return result;
                    ctx.n_eob = 0;
                    start = i + 1;
                    Curl_pop3_smtp_inc_infilesize(data);
                } else if (ctx.n_eob == 1 and i > start) {
                    result = io_buffers.Curl_bufq_cwrite(&ctx.buf, buf + start, i - start, &nread);
                    if (result != CURLE_OK)
                        return result;
                    start = i + 1;
                }
            }

            if (ctx.n_eob == 0 and i >= start) {
                result = io_buffers.Curl_bufq_cwrite(&ctx.buf, buf + start, i + 1 - start, &nread);
                if (result != CURLE_OK)
                    return result;
            }
        }

        if (ctx.eos and !ctx.eob_added) {
            const tail: [*:0]const u8 = switch (ctx.n_eob) {
                1 => "\r\r\n.\r\n",
                2 => ".\r\n",
                else => "\r\n.\r\n",
            };
            result = io_buffers.Curl_bufq_cwrite(&ctx.buf, tail, std.mem.len(tail), &nread);
            if (result != CURLE_OK)
                return result;
            ctx.n_eob = 0;
            ctx.eob_added = true;
        }
    }

    peos.* = false;
    if (!io_buffers.Curl_bufq_is_empty(&ctx.buf)) {
        result = io_buffers.Curl_bufq_cread(&ctx.buf, buf, blen, pnread);
    } else {
        pnread.* = 0;
    }

    if (result == CURLE_OK and ctx.eos and io_buffers.Curl_bufq_is_empty(&ctx.buf)) {
        peos.* = true;
    }

    return result;
}

fn cr_eob_total_length(data: ?*anyopaque, reader: *Curl_creader) callconv(.c) curl_off_t {
    _ = data;
    _ = reader;
    return -1;
}

const cr_eob = Curl_criter{
    .name = "cr-smtp-eob",
    .do_init = cr_eob_init,
    .do_read = cr_eob_read,
    .do_close = cr_eob_close,
    .needs_rewind = Curl_creader_def_needs_rewind,
    .total_length = cr_eob_total_length,
    .resume_from = Curl_creader_def_resume_from,
    .cntrl = Curl_creader_def_cntrl,
    .is_paused = Curl_creader_def_is_paused,
    .done = Curl_creader_def_done,
    .size = @sizeOf(cr_eob_ctx),
};

fn cr_eob_insert_after(data: ?*anyopaque) CURLcode {
    var reader: ?*Curl_creader = null;
    var result = Curl_creader_create(&reader, data, &cr_eob, CURL_CR_CONTENT_ENCODE);
    if (result == CURLE_OK) {
        result = Curl_creader_add(data, reader);
        if (result != CURLE_OK)
            Curl_creader_free(data, reader);
    }
    return result;
}

fn smtp_endofresp(
    data: ?*anyopaque,
    conn: ?*anyopaque,
    line: [*]const u8,
    len: usize,
    resp: *c_int,
) callconv(.c) bool {
    _ = data;
    const smtpc_raw = Curl_conn_meta_get(conn, CURL_META_SMTP_CONN) orelse return false;
    const smtpc: *smtp_conn = @ptrCast(@alignCast(smtpc_raw));

    if (len < 4 or !std.ascii.isDigit(line[0]) or !std.ascii.isDigit(line[1]) or !std.ascii.isDigit(line[2]))
        return false;

    if (line[3] == ' ' or len == 5) {
        var tmpline: [6]u8 = @splat(0);
        var p: [*:0]const u8 = @ptrCast(&tmpline);
        var code: curl_off_t = 0;
        const copy_len: usize = if (len == 5) 5 else 3;
        @memcpy(tmpline[0..copy_len], line[0..copy_len]);
        if (curlx_str_number(&p, &code, if (len == 5) 99999 else 999) != 0)
            return false;
        resp.* = @intCast(code);
        return true;
    } else if (line[3] == '-' and (smtpc.state == .SMTP_EHLO or smtpc.state == .SMTP_COMMAND)) {
        resp.* = 1;
        return true;
    }

    return false;
}

fn smtp_get_message(data: ?*anyopaque, out: *bufref) callconv(.c) CURLcode {
    const conn = Curl_pop3_smtp_get_conn(data);
    const smtpc_raw = Curl_conn_meta_get(conn, CURL_META_SMTP_CONN) orelse return CURLE_FAILED_INIT;
    const smtpc: *smtp_conn = @ptrCast(@alignCast(smtpc_raw));
    const msg_ptr = containers.curlx_dyn_ptr(&smtpc.pp.recvbuf);
    var len = smtpc.pp.nfinal;

    if (msg_ptr) |base| {
        if (len > 4) {
            var message: [*]u8 = base + 4;
            len -= 4;
            while (len > 0 and (message[0] == ' ' or message[0] == '\t')) {
                message += 1;
                len -= 1;
            }
            while (len > 0) : (len -= 1) {
                const c = message[len - 1];
                if (c != '\r' and c != '\n' and c != ' ' and c != '\t')
                    break;
            }
            message[len] = 0;
            Curl_bufref_set(out, message, len, null);
            return CURLE_OK;
        }
    }
    Curl_bufref_set(out, "", 0, null);
    return CURLE_OK;
}

fn smtp_state(data: ?*anyopaque, smtpc: *smtp_conn, newstate: smtpstate) void {
    if (smtpc.state != newstate) {
        Curl_pop3_smtp_trc_smtp_state(
            data,
            smtp_state_names[@backingInt(smtpc.state)],
            smtp_state_names[@backingInt(newstate)],
        );
    }
    smtpc.state = newstate;
}

fn smtp_perform_ehlo(data: ?*anyopaque, smtpc: *smtp_conn) CURLcode {
    Curl_pop3_smtp_sasl_set_authmechs(&smtpc.sasl, SASL_AUTH_NONE);
    Curl_pop3_smtp_sasl_set_authused(&smtpc.sasl, SASL_AUTH_NONE);
    smtpc.tls_supported = false;
    smtpc.auth_supported = false;

    const domain: [*:0]const u8 = smtpc.domain orelse "localhost";
    const result = Curl_pp_sendf(data, &smtpc.pp, "EHLO %s", domain);
    if (result == CURLE_OK)
        smtp_state(data, smtpc, .SMTP_EHLO);

    return result;
}

fn smtp_perform_helo(data: ?*anyopaque, smtpc: *smtp_conn) CURLcode {
    Curl_pop3_smtp_sasl_set_authused(&smtpc.sasl, SASL_AUTH_NONE);

    const domain: [*:0]const u8 = smtpc.domain orelse "localhost";
    const result = Curl_pp_sendf(data, &smtpc.pp, "HELO %s", domain);
    if (result == CURLE_OK)
        smtp_state(data, smtpc, .SMTP_HELO);

    return result;
}

fn smtp_perform_starttls(data: ?*anyopaque, smtpc: *smtp_conn) CURLcode {
    const result = Curl_pp_sendf(data, &smtpc.pp, "%s", @as([*:0]const u8, "STARTTLS"));
    if (result == CURLE_OK)
        smtp_state(data, smtpc, .SMTP_STARTTLS);

    return result;
}

fn smtp_perform_upgrade_tls(data: ?*anyopaque, conn: ?*anyopaque) CURLcode {
    const smtpc_raw = Curl_conn_meta_get(conn, CURL_META_SMTP_CONN) orelse return CURLE_FAILED_INIT;
    const smtpc: *smtp_conn = @ptrCast(@alignCast(smtpc_raw));

    var ssldone: bool = false;
    var result = Curl_pop3_smtp_upgrade_tls(data, conn, true, &ssldone);
    if (result == CURLE_OK and ssldone) {
        smtpc.ssldone = ssldone;
        result = smtp_perform_ehlo(data, smtpc);
    }
    return result;
}

fn smtp_perform_auth(data: ?*anyopaque, mech: [*:0]const u8, initresp: *const bufref) callconv(.c) CURLcode {
    const conn = Curl_pop3_smtp_get_conn(data);
    const smtpc_raw = Curl_conn_meta_get(conn, CURL_META_SMTP_CONN) orelse return CURLE_FAILED_INIT;
    const smtpc: *smtp_conn = @ptrCast(@alignCast(smtpc_raw));

    const ir = Curl_bufref_ptr(initresp);
    if (ir) |ir_str| {
        const arg: [*:0]const u8 = if (ir_str[0] != 0) ir_str else "=";
        return Curl_pp_sendf(data, &smtpc.pp, "AUTH %s %s", mech, arg);
    }
    return Curl_pp_sendf(data, &smtpc.pp, "AUTH %s", mech);
}

fn smtp_continue_auth(data: ?*anyopaque, mech: [*:0]const u8, resp: *const bufref) callconv(.c) CURLcode {
    _ = mech;
    const conn = Curl_pop3_smtp_get_conn(data);
    const smtpc_raw = Curl_conn_meta_get(conn, CURL_META_SMTP_CONN) orelse return CURLE_FAILED_INIT;
    const smtpc: *smtp_conn = @ptrCast(@alignCast(smtpc_raw));

    const r = Curl_bufref_ptr(resp) orelse @as([*:0]const u8, "");
    return Curl_pp_sendf(data, &smtpc.pp, "%s", r);
}

fn smtp_cancel_auth(data: ?*anyopaque, mech: [*:0]const u8) callconv(.c) CURLcode {
    _ = mech;
    const conn = Curl_pop3_smtp_get_conn(data);
    const smtpc_raw = Curl_conn_meta_get(conn, CURL_META_SMTP_CONN) orelse return CURLE_FAILED_INIT;
    const smtpc: *smtp_conn = @ptrCast(@alignCast(smtpc_raw));

    return Curl_pp_sendf(data, &smtpc.pp, "*");
}

fn smtp_perform_authentication(data: ?*anyopaque, smtpc: *smtp_conn) CURLcode {
    var result: CURLcode = CURLE_OK;
    var progress: c_uint = SASL_IDLE;

    if (!smtpc.auth_supported or !Curl_pop3_smtp_sasl_can_authenticate(&smtpc.sasl, data)) {
        smtp_state(data, smtpc, .SMTP_STOP);
        return result;
    }

    result = Curl_pop3_smtp_sasl_start(&smtpc.sasl, data, false, &progress);
    if (result == CURLE_OK) {
        if (progress == SASL_INPROGRESS) {
            smtp_state(data, smtpc, .SMTP_AUTH);
        } else {
            result = Curl_pop3_smtp_sasl_is_blocked(&smtpc.sasl, data);
            if (result == CURLE_OK) {
                Curl_pop3_smtp_infof_msg(data, "No known authentication mechanisms supported");
                result = CURLE_LOGIN_DENIED;
            }
        }
    }

    return result;
}

fn smtp_perform_command(data: ?*anyopaque) CURLcode {
    var result: CURLcode = CURLE_OK;
    const conn = Curl_pop3_smtp_get_conn(data);
    const smtpc_raw = Curl_conn_meta_get(conn, CURL_META_SMTP_CONN) orelse return CURLE_FAILED_INIT;
    const smtpc: *smtp_conn = @ptrCast(@alignCast(smtpc_raw));
    const smtp_raw = Curl_meta_get(data, CURL_META_SMTP_EASY) orelse return CURLE_FAILED_INIT;
    const smtp: *SMTP = @ptrCast(@alignCast(smtp_raw));

    const rcpt = Curl_pop3_smtp_get_mail_rcpt(data);
    if (rcpt != null) {
        var utf8: bool = false;
        const custom_str = smtp.custom;
        const custom_empty = (custom_str == null or custom_str.?[0] == 0);

        if (custom_empty or
            primitives.curl_strnequal(custom_str.?, "VRFY", 4) != 0 or
            primitives.curl_strnequal(custom_str.?, "EXPN", 4) != 0)
        {
            var address: ?[*:0]u8 = null;
            var host: netrc_addr_idn.Hostname = std.mem.zeroes(netrc_addr_idn.Hostname);
            var suffix: [*:0]const u8 = "";

            const rcpt_data: [*:0]const u8 = rcpt.?.data orelse "";
            result = smtp_parse_address(data, rcpt_data, &address, &host, &suffix);
            if (result != CURLE_OK)
                return result;

            utf8 = smtpc.utf8_supported and
                ((host.encalloc != null) or
                    !netrc_addr_idn.Curl_is_ASCII_name(address) or
                    !netrc_addr_idn.Curl_is_ASCII_name(host.name));

            const cmd_name: [*:0]const u8 = if (!custom_empty) custom_str.? else "VRFY";
            const addr_str: [*:0]const u8 = address orelse "";
            if (host.name != null) {
                result = Curl_pp_sendf(
                    data,
                    &smtpc.pp,
                    "%s %s@%s%s%s",
                    cmd_name,
                    addr_str,
                    host.dispname,
                    suffix,
                    @as([*:0]const u8, if (utf8) " SMTPUTF8" else ""),
                );
            } else {
                result = Curl_pp_sendf(
                    data,
                    &smtpc.pp,
                    "%s %s%s%s",
                    cmd_name,
                    addr_str,
                    suffix,
                    @as([*:0]const u8, if (utf8) " SMTPUTF8" else ""),
                );
            }

            netrc_addr_idn.Curl_free_idnconverted_hostname(&host);
            if (address) |a| mem.free(@ptrCast(a));
        } else {
            const rcpt_data: [*:0]const u8 = rcpt.?.data orelse "";
            utf8 = smtpc.utf8_supported and (std.mem.eql(u8, std.mem.span(custom_str.?), "EXPN"));
            result = Curl_pp_sendf(
                data,
                &smtpc.pp,
                "%s %s%s",
                custom_str.?,
                rcpt_data,
                @as([*:0]const u8, if (utf8) " SMTPUTF8" else ""),
            );
        }
    } else {
        const custom_str = smtp.custom;
        const cmd_name: [*:0]const u8 = if (custom_str != null and custom_str.?[0] != 0) custom_str.? else "HELP";
        result = Curl_pp_sendf(data, &smtpc.pp, "%s", cmd_name);
    }

    if (result == CURLE_OK)
        smtp_state(data, smtpc, .SMTP_COMMAND);

    return result;
}

fn smtp_perform_mail(data: ?*anyopaque) CURLcode {
    var from: ?[*:0]u8 = null;
    var auth: ?[*:0]u8 = null;
    var size: ?[*:0]u8 = null;
    var result: CURLcode = CURLE_OK;
    const conn = Curl_pop3_smtp_get_conn(data);
    const smtpc_raw = Curl_conn_meta_get(conn, CURL_META_SMTP_CONN) orelse return CURLE_FAILED_INIT;
    const smtpc: *smtp_conn = @ptrCast(@alignCast(smtpc_raw));

    var utf8: bool = false;

    const mail_from = Curl_pop3_smtp_get_mail_from(data);
    if (mail_from != null and mail_from.?[0] != 0) {
        var address: ?[*:0]u8 = null;
        var host: netrc_addr_idn.Hostname = std.mem.zeroes(netrc_addr_idn.Hostname);
        var suffix: [*:0]const u8 = "";

        result = smtp_parse_address(data, mail_from.?, &address, &host, &suffix);
        if (result != CURLE_OK)
            goto_out(from, auth, size, result);
        if (result != CURLE_OK)
            return result;

        utf8 = smtpc.utf8_supported and
            ((host.encalloc != null) or
                !netrc_addr_idn.Curl_is_ASCII_name(address) or
                !netrc_addr_idn.Curl_is_ASCII_name(host.name));

        const addr_str: [*:0]const u8 = address orelse "";
        if (host.name != null) {
            from = curl_maprintf("<%s@%s>%s", addr_str, host.dispname, suffix);
            netrc_addr_idn.Curl_free_idnconverted_hostname(&host);
        } else {
            from = curl_maprintf("<%s>%s", addr_str, suffix);
        }
        if (address) |a| mem.free(@ptrCast(a));
    } else {
        from = mem.strdup("<>");
    }

    if (from == null)
        return CURLE_OUT_OF_MEMORY;

    const mail_auth = Curl_pop3_smtp_get_mail_auth(data);
    if (mail_auth != null and smtpc.sasl.authused != 0) {
        if (mail_auth.?[0] != 0) {
            var address: ?[*:0]u8 = null;
            var host: netrc_addr_idn.Hostname = std.mem.zeroes(netrc_addr_idn.Hostname);
            var suffix: [*:0]const u8 = "";

            result = smtp_parse_address(data, mail_auth.?, &address, &host, &suffix);
            if (result != CURLE_OK) {
                if (from) |f| mem.free(@ptrCast(f));
                return result;
            }

            if (!utf8 and smtpc.utf8_supported and
                ((host.encalloc != null) or
                    !netrc_addr_idn.Curl_is_ASCII_name(address) or
                    !netrc_addr_idn.Curl_is_ASCII_name(host.name)))
            {
                utf8 = true;
            }

            const addr_str: [*:0]const u8 = address orelse "";
            if (host.name != null) {
                auth = curl_maprintf("<%s@%s>%s", addr_str, host.dispname, suffix);
                netrc_addr_idn.Curl_free_idnconverted_hostname(&host);
            } else {
                auth = curl_maprintf("<%s>%s", addr_str, suffix);
            }
            if (address) |a| mem.free(@ptrCast(a));
        } else {
            auth = mem.strdup("<>");
        }
        if (auth == null) {
            if (from) |f| mem.free(@ptrCast(f));
            return CURLE_OUT_OF_MEMORY;
        }
    }

    result = Curl_pop3_smtp_prepare_mail_reader(data);
    if (result != CURLE_OK) {
        if (from) |f| mem.free(@ptrCast(f));
        if (auth) |a| mem.free(@ptrCast(a));
        return result;
    }

    const infilesize = Curl_pop3_smtp_get_infilesize(data);
    if (smtpc.size_supported and infilesize > 0) {
        size = curl_maprintf("%lld", @as(c_longlong, infilesize));
        if (size == null) {
            if (from) |f| mem.free(@ptrCast(f));
            if (auth) |a| mem.free(@ptrCast(a));
            return CURLE_OUT_OF_MEMORY;
        }
    }

    if (smtpc.utf8_supported and !utf8) {
        const smtp_raw = Curl_meta_get(data, CURL_META_SMTP_EASY) orelse {
            if (from) |f| mem.free(@ptrCast(f));
            if (auth) |a| mem.free(@ptrCast(a));
            if (size) |s| mem.free(@ptrCast(s));
            return CURLE_FAILED_INIT;
        };
        const smtp: *SMTP = @ptrCast(@alignCast(smtp_raw));
        var rcpt = smtp.rcpt;
        while (rcpt != null and !utf8) {
            if (!netrc_addr_idn.Curl_is_ASCII_name(rcpt.?.data))
                utf8 = true;
            rcpt = rcpt.?.next;
        }
    }

    result = cr_eob_insert_after(data);
    if (result == CURLE_OK) {
        result = Curl_pp_sendf(
            data,
            &smtpc.pp,
            "MAIL FROM:%s%s%s%s%s%s",
            from.?,
            @as([*:0]const u8, if (auth != null) " AUTH=" else ""),
            @as([*:0]const u8, if (auth) |a| a else ""),
            @as([*:0]const u8, if (size != null) " SIZE=" else ""),
            @as([*:0]const u8, if (size) |s| s else ""),
            @as([*:0]const u8, if (utf8) " SMTPUTF8" else ""),
        );
    }

    if (from) |f| mem.free(@ptrCast(f));
    if (auth) |a| mem.free(@ptrCast(a));
    if (size) |s| mem.free(@ptrCast(s));

    if (result == CURLE_OK)
        smtp_state(data, smtpc, .SMTP_MAIL);

    return result;
}

inline fn goto_out(from: ?[*:0]u8, auth: ?[*:0]u8, size: ?[*:0]u8, result: CURLcode) void {
    _ = from;
    _ = auth;
    _ = size;
    _ = result;
}

fn smtp_perform_rcpt_to(data: ?*anyopaque) CURLcode {
    var result: CURLcode = CURLE_OK;
    const conn = Curl_pop3_smtp_get_conn(data);
    const smtpc_raw = Curl_conn_meta_get(conn, CURL_META_SMTP_CONN) orelse return CURLE_FAILED_INIT;
    const smtpc: *smtp_conn = @ptrCast(@alignCast(smtpc_raw));
    const smtp_raw = Curl_meta_get(data, CURL_META_SMTP_EASY) orelse return CURLE_FAILED_INIT;
    const smtp: *SMTP = @ptrCast(@alignCast(smtp_raw));

    var address: ?[*:0]u8 = null;
    var host: netrc_addr_idn.Hostname = std.mem.zeroes(netrc_addr_idn.Hostname);
    var suffix: [*:0]const u8 = "";

    const rcpt_node = smtp.rcpt orelse return CURLE_FAILED_INIT;
    const rcpt_data: [*:0]const u8 = rcpt_node.data orelse "";

    result = smtp_parse_address(data, rcpt_data, &address, &host, &suffix);
    if (result != CURLE_OK)
        return result;

    const addr_str: [*:0]const u8 = address orelse "";
    if (host.name != null) {
        result = Curl_pp_sendf(data, &smtpc.pp, "RCPT TO:<%s@%s>%s", addr_str, host.dispname, suffix);
    } else {
        result = Curl_pp_sendf(data, &smtpc.pp, "RCPT TO:<%s>%s", addr_str, suffix);
    }

    netrc_addr_idn.Curl_free_idnconverted_hostname(&host);
    if (address) |a| mem.free(@ptrCast(a));

    if (result == CURLE_OK)
        smtp_state(data, smtpc, .SMTP_RCPT);

    return result;
}

fn smtp_perform_quit(data: ?*anyopaque, smtpc: *smtp_conn) CURLcode {
    const result = Curl_pp_sendf(data, &smtpc.pp, "%s", @as([*:0]const u8, "QUIT"));
    if (result == CURLE_OK)
        smtp_state(data, smtpc, .SMTP_QUIT);

    return result;
}

fn smtp_state_servergreet_resp(data: ?*anyopaque, smtpc: *smtp_conn, smtpcode: c_int, instate: smtpstate) CURLcode {
    _ = instate;
    var result: CURLcode = CURLE_OK;

    if (@divTrunc(smtpcode, 100) != 2) {
        Curl_pop3_smtp_failf_int(data, "Got unexpected smtp-server response: %d", smtpcode);
        result = CURLE_WEIRD_SERVER_REPLY;
    } else {
        result = smtp_perform_ehlo(data, smtpc);
    }

    return result;
}

fn smtp_state_ehlo_resp(
    data: ?*anyopaque,
    conn: ?*anyopaque,
    smtpc: *smtp_conn,
    smtpcode: c_int,
    instate: smtpstate,
) CURLcode {
    _ = instate;
    var result: CURLcode = CURLE_OK;
    const line_opt = containers.curlx_dyn_ptr(&smtpc.pp.recvbuf);
    var len = smtpc.pp.nfinal;

    if (@divTrunc(smtpcode, 100) != 2 and smtpcode != 1) {
        if (Curl_pop3_smtp_get_use_ssl(data) <= USESSL_TRY or Curl_pop3_smtp_conn_is_ssl(conn)) {
            result = smtp_perform_helo(data, smtpc);
        } else {
            Curl_pop3_smtp_failf_int(data, "Remote access denied: %d", smtpcode);
            result = CURLE_REMOTE_ACCESS_DENIED;
        }
    } else if (len >= 4) {
        if (line_opt) |base| {
            var line: [*]const u8 = base + 4;
            len -= 4;

            if (len >= 8 and std.mem.eql(u8, line[0..8], "STARTTLS")) {
                smtpc.tls_supported = true;
            } else if (len >= 4 and std.mem.eql(u8, line[0..4], "SIZE")) {
                smtpc.size_supported = true;
            } else if (len >= 8 and std.mem.eql(u8, line[0..8], "SMTPUTF8")) {
                smtpc.utf8_supported = true;
            } else if (len >= 5 and std.mem.eql(u8, line[0..5], "AUTH ")) {
                smtpc.auth_supported = true;
                line += 5;
                len -= 5;
                while (true) {
                    while (len > 0 and (line[0] == ' ' or line[0] == '\t' or line[0] == '\r' or line[0] == '\n')) {
                        line += 1;
                        len -= 1;
                    }
                    if (len == 0)
                        break;
                    var wordlen: usize = 0;
                    while (wordlen < len and line[wordlen] != ' ' and line[wordlen] != '\t' and line[wordlen] != '\r' and line[wordlen] != '\n') : (wordlen += 1) {}
                    var llen: usize = 0;
                    const mechbit = Curl_pop3_smtp_sasl_decode_mech(line, wordlen, &llen);
                    if (mechbit != 0 and llen == wordlen)
                        Curl_pop3_smtp_sasl_or_authmechs(&smtpc.sasl, mechbit);
                    line += wordlen;
                    len -= wordlen;
                }
            }
        }

        if (smtpcode != 1) {
            const use_ssl = Curl_pop3_smtp_get_use_ssl(data);
            if (use_ssl != USESSL_NONE and !Curl_pop3_smtp_conn_is_ssl(conn)) {
                if (smtpc.tls_supported) {
                    result = smtp_perform_starttls(data, smtpc);
                } else if (use_ssl == USESSL_TRY) {
                    result = smtp_perform_authentication(data, smtpc);
                } else {
                    Curl_pop3_smtp_failf_msg(data, "STARTTLS not supported.");
                    result = CURLE_USE_SSL_FAILED;
                }
            } else {
                result = smtp_perform_authentication(data, smtpc);
            }
        }
    } else {
        Curl_pop3_smtp_failf_msg(data, "Unexpectedly short EHLO response");
        result = CURLE_WEIRD_SERVER_REPLY;
    }

    return result;
}

fn smtp_state_helo_resp(data: ?*anyopaque, smtpc: *smtp_conn, smtpcode: c_int, instate: smtpstate) CURLcode {
    _ = instate;
    var result: CURLcode = CURLE_OK;

    if (@divTrunc(smtpcode, 100) != 2) {
        Curl_pop3_smtp_failf_int(data, "Remote access denied: %d", smtpcode);
        result = CURLE_REMOTE_ACCESS_DENIED;
    } else {
        smtp_state(data, smtpc, .SMTP_STOP);
    }

    return result;
}

fn smtp_state_starttls_resp(
    data: ?*anyopaque,
    conn: ?*anyopaque,
    smtpc: *smtp_conn,
    smtpcode: c_int,
    instate: smtpstate,
) CURLcode {
    _ = instate;
    var result: CURLcode = CURLE_OK;

    if (smtpc.pp.overflow != 0)
        return CURLE_WEIRD_SERVER_REPLY;

    if (smtpcode != 220) {
        if (Curl_pop3_smtp_get_use_ssl(data) != USESSL_TRY) {
            Curl_pop3_smtp_failf_int(data, "STARTTLS denied, code %d", smtpcode);
            result = CURLE_USE_SSL_FAILED;
        } else {
            result = smtp_perform_authentication(data, smtpc);
        }
    } else {
        smtp_state(data, smtpc, .SMTP_UPGRADETLS);
        result = smtp_perform_upgrade_tls(data, conn);
    }

    return result;
}

fn smtp_state_auth_resp(data: ?*anyopaque, smtpc: *smtp_conn, smtpcode: c_int, instate: smtpstate) CURLcode {
    _ = instate;
    var result: CURLcode = CURLE_OK;
    var progress: c_uint = SASL_IDLE;

    result = Curl_pop3_smtp_sasl_continue(&smtpc.sasl, data, smtpcode, &progress);
    if (result == CURLE_OK) {
        switch (progress) {
            SASL_FINAL => smtp_state(data, smtpc, .SMTP_STOP),
            SASL_IDLE => {
                Curl_pop3_smtp_failf_msg(data, "Authentication cancelled");
                result = CURLE_LOGIN_DENIED;
            },
            else => {},
        }
    }

    return result;
}

fn smtp_state_command_resp(data: ?*anyopaque, smtpc: *smtp_conn, smtpcode: c_int, instate: smtpstate) CURLcode {
    _ = instate;
    var result: CURLcode = CURLE_OK;
    const smtp_raw = Curl_meta_get(data, CURL_META_SMTP_EASY) orelse return CURLE_FAILED_INIT;
    const smtp: *SMTP = @ptrCast(@alignCast(smtp_raw));
    const line_opt = containers.curlx_dyn_ptr(&smtpc.pp.recvbuf);
    const len = smtpc.pp.nfinal;

    if (smtp.rcpt != null and @divTrunc(smtpcode, 100) != 2 and smtpcode != 553 and smtpcode != 1) {
        Curl_pop3_smtp_failf_int(data, "Command failed: %d", smtpcode);
        result = CURLE_RECV_ERROR;
    } else {
        if (!Curl_pop3_smtp_get_req_no_body(data)) {
            if (line_opt) |line| {
                line[len] = '\n';
                result = Curl_client_write(data, CLIENTWRITE_BODY, line, len + 1);
                line[len] = 0;
            }
        }

        if (smtpcode != 1) {
            if (smtp.rcpt) |rcpt| {
                smtp.rcpt = rcpt.next;
                if (smtp.rcpt != null) {
                    result = smtp_perform_command(data);
                } else {
                    smtp_state(data, smtpc, .SMTP_STOP);
                }
            } else {
                smtp_state(data, smtpc, .SMTP_STOP);
            }
        }
    }

    return result;
}

fn smtp_state_mail_resp(data: ?*anyopaque, smtpc: *smtp_conn, smtpcode: c_int, instate: smtpstate) CURLcode {
    _ = smtpc;
    _ = instate;
    var result: CURLcode = CURLE_OK;

    if (@divTrunc(smtpcode, 100) != 2) {
        Curl_pop3_smtp_failf_int(data, "MAIL failed: %d", smtpcode);
        result = CURLE_SEND_ERROR;
    } else {
        result = smtp_perform_rcpt_to(data);
    }

    return result;
}

fn smtp_state_rcpt_resp(data: ?*anyopaque, smtpc: *smtp_conn, smtpcode: c_int, instate: smtpstate) CURLcode {
    _ = instate;
    var result: CURLcode = CURLE_OK;
    const smtp_raw = Curl_meta_get(data, CURL_META_SMTP_EASY) orelse return CURLE_FAILED_INIT;
    const smtp: *SMTP = @ptrCast(@alignCast(smtp_raw));

    const is_smtp_err = (@divTrunc(smtpcode, 100) != 2);
    const is_smtp_blocking_err = (is_smtp_err and !Curl_pop3_smtp_get_mail_rcpt_allowfails(data));

    if (is_smtp_err) {
        smtp.rcpt_last_error = smtpcode;
        if (is_smtp_blocking_err) {
            Curl_pop3_smtp_failf_int(data, "RCPT failed: %d", smtpcode);
            result = CURLE_SEND_ERROR;
        }
    } else {
        smtp.rcpt_had_ok = true;
    }

    if (!is_smtp_blocking_err) {
        if (smtp.rcpt) |rcpt| {
            smtp.rcpt = rcpt.next;
        }
        if (smtp.rcpt != null) {
            result = smtp_perform_rcpt_to(data);
        } else {
            if (!smtp.rcpt_had_ok) {
                Curl_pop3_smtp_failf_int(data, "RCPT failed: %d (last error)", smtp.rcpt_last_error);
                result = CURLE_SEND_ERROR;
            } else {
                result = Curl_pp_sendf(data, &smtpc.pp, "%s", @as([*:0]const u8, "DATA"));
                if (result == CURLE_OK)
                    smtp_state(data, smtpc, .SMTP_DATA);
            }
        }
    }

    return result;
}

fn smtp_state_data_resp(data: ?*anyopaque, smtpc: *smtp_conn, smtpcode: c_int, instate: smtpstate) CURLcode {
    _ = instate;
    if (smtpcode != 354) {
        Curl_pop3_smtp_failf_int(data, "DATA failed: %d", smtpcode);
        return CURLE_SEND_ERROR;
    }

    Curl_pgrsSetUploadSize(data, Curl_pop3_smtp_get_infilesize(data));
    Curl_xfer_setup_send(data, FIRSTSOCKET);
    smtp_state(data, smtpc, .SMTP_STOP);

    return CURLE_OK;
}

fn smtp_state_postdata_resp(data: ?*anyopaque, smtpc: *smtp_conn, smtpcode: c_int, instate: smtpstate) CURLcode {
    _ = instate;
    var result: CURLcode = CURLE_OK;
    if (smtpcode != 250)
        result = CURLE_WEIRD_SERVER_REPLY;

    smtp_state(data, smtpc, .SMTP_STOP);
    return result;
}

fn smtp_statemachine(data: ?*anyopaque, conn: ?*anyopaque) callconv(.c) CURLcode {
    var result: CURLcode = CURLE_OK;
    var smtpcode: c_int = 0;
    const smtpc_raw = Curl_conn_meta_get(conn, CURL_META_SMTP_CONN) orelse return CURLE_FAILED_INIT;
    const smtpc: *smtp_conn = @ptrCast(@alignCast(smtpc_raw));
    const pp = &smtpc.pp;
    var nread: usize = 0;

    if (smtpc.state == .SMTP_UPGRADETLS)
        return smtp_perform_upgrade_tls(data, conn);

    if (pp.sendleft != 0)
        return Curl_pp_MoreSend(data, pp);

    while (true) {
        result = Curl_pop3_smtp_pp_readresp(data, FIRSTSOCKET, pp, &smtpcode, &nread);
        if (result != CURLE_OK)
            return result;

        if (smtpc.state != .SMTP_QUIT and smtpcode != 1)
            Curl_pop3_smtp_set_httpcode(data, smtpcode);

        if (smtpcode == 0)
            break;

        const instate = smtpc.state;
        switch (instate) {
            .SMTP_SERVERGREET => result = smtp_state_servergreet_resp(data, smtpc, smtpcode, instate),
            .SMTP_EHLO => result = smtp_state_ehlo_resp(data, conn, smtpc, smtpcode, instate),
            .SMTP_HELO => result = smtp_state_helo_resp(data, smtpc, smtpcode, instate),
            .SMTP_STARTTLS => result = smtp_state_starttls_resp(data, conn, smtpc, smtpcode, instate),
            .SMTP_AUTH => result = smtp_state_auth_resp(data, smtpc, smtpcode, instate),
            .SMTP_COMMAND => result = smtp_state_command_resp(data, smtpc, smtpcode, instate),
            .SMTP_MAIL => result = smtp_state_mail_resp(data, smtpc, smtpcode, instate),
            .SMTP_RCPT => result = smtp_state_rcpt_resp(data, smtpc, smtpcode, instate),
            .SMTP_DATA => result = smtp_state_data_resp(data, smtpc, smtpcode, instate),
            .SMTP_POSTDATA => result = smtp_state_postdata_resp(data, smtpc, smtpcode, instate),
            .SMTP_QUIT => smtp_state(data, smtpc, .SMTP_STOP),
            else => smtp_state(data, smtpc, .SMTP_STOP),
        }

        if (result != CURLE_OK or smtpc.state == .SMTP_STOP or !Curl_pp_moredata(pp))
            break;
    }

    return result;
}

fn smtp_multi_statemach(data: ?*anyopaque, done: *bool) callconv(.c) CURLcode {
    const conn = Curl_pop3_smtp_get_conn(data);
    const smtpc_raw = Curl_conn_meta_get(conn, CURL_META_SMTP_CONN) orelse return CURLE_FAILED_INIT;
    const smtpc: *smtp_conn = @ptrCast(@alignCast(smtpc_raw));

    const result = Curl_pop3_smtp_pp_statemach(data, &smtpc.pp, false, false);
    done.* = (smtpc.state == .SMTP_STOP);
    return result;
}

fn smtp_block_statemach(data: ?*anyopaque, smtpc: *smtp_conn, disconnecting: bool) CURLcode {
    var result: CURLcode = CURLE_OK;
    while (smtpc.state != .SMTP_STOP and result == CURLE_OK)
        result = Curl_pop3_smtp_pp_statemach(data, &smtpc.pp, true, disconnecting);

    return result;
}

fn smtp_easy_dtor(key: ?*const anyopaque, klen: usize, entry: ?*anyopaque) callconv(.c) void {
    _ = key;
    _ = klen;
    const smtp: *SMTP = @ptrCast(@alignCast(entry orelse return));
    if (smtp.custom) |cust| mem.free(@ptrCast(cust));
    mem.freeSized(smtp, @sizeOf(SMTP));
}

fn smtp_conn_dtor(key: ?*const anyopaque, klen: usize, entry: ?*anyopaque) callconv(.c) void {
    _ = key;
    _ = klen;
    const smtpc: *smtp_conn = @ptrCast(@alignCast(entry orelse return));
    _ = Curl_pp_disconnect(&smtpc.pp);
    if (smtpc.domain) |dom| mem.free(@ptrCast(dom));
    mem.freeSized(smtpc, @sizeOf(smtp_conn));
}

fn smtp_init(data: ?*anyopaque) CURLcode {
    const smtp_raw = mem.calloc(1, @sizeOf(SMTP)) orelse return CURLE_OUT_OF_MEMORY;
    return Curl_meta_set(data, CURL_META_SMTP_EASY, smtp_raw, smtp_easy_dtor);
}

fn smtp_pollset(data: ?*anyopaque, ps: ?*anyopaque) callconv(.c) CURLcode {
    const conn = Curl_pop3_smtp_get_conn(data);
    const smtpc_raw = Curl_conn_meta_get(conn, CURL_META_SMTP_CONN) orelse return CURLE_FAILED_INIT;
    const smtpc: *smtp_conn = @ptrCast(@alignCast(smtpc_raw));
    return Curl_pop3_smtp_pp_pollset(data, &smtpc.pp, ps);
}

fn smtp_connect(data: ?*anyopaque, done: *bool) callconv(.c) CURLcode {
    const conn = Curl_pop3_smtp_get_conn(data);
    const smtpc_raw = Curl_conn_meta_get(conn, CURL_META_SMTP_CONN) orelse return CURLE_FAILED_INIT;
    const smtpc: *smtp_conn = @ptrCast(@alignCast(smtpc_raw));
    const pp = &smtpc.pp;

    done.* = false;

    Curl_pop3_smtp_pp_init(data, pp);

    var result = smtp_parse_url_options(conn, smtpc);
    if (result != CURLE_OK)
        return result;

    result = smtp_parse_url_path(data);
    if (result != CURLE_OK)
        return result;

    smtp_state(data, smtpc, .SMTP_SERVERGREET);

    return smtp_multi_statemach(data, done);
}

fn smtp_done(data: ?*anyopaque, status: CURLcode, premature: bool) callconv(.c) CURLcode {
    var result: CURLcode = CURLE_OK;
    const conn = Curl_pop3_smtp_get_conn(data);
    const smtp_raw = Curl_meta_get(data, CURL_META_SMTP_EASY) orelse return CURLE_OK;
    const smtp: *SMTP = @ptrCast(@alignCast(smtp_raw));
    const smtpc_raw = Curl_conn_meta_get(conn, CURL_META_SMTP_CONN) orelse return CURLE_FAILED_INIT;
    const smtpc: *smtp_conn = @ptrCast(@alignCast(smtpc_raw));

    if (smtp.custom) |cust| {
        mem.free(@ptrCast(cust));
        smtp.custom = null;
    }

    if (status != CURLE_OK) {
        Curl_pop3_smtp_connclose(conn);
        result = status;
    } else if (!Curl_pop3_smtp_get_connect_only(data) and
        Curl_pop3_smtp_get_mail_rcpt(data) != null and
        Curl_pop3_smtp_is_upload_or_mime(data))
    {
        if (premature or smtpc.pp.sendleft != 0) {
            Curl_pop3_smtp_connclose(conn);
            return result;
        }
        smtp_state(data, smtpc, .SMTP_POSTDATA);
        result = smtp_block_statemach(data, smtpc, false);
    }

    smtp.transfer = PPTRANSFER_BODY;
    return result;
}

fn smtp_perform(data: ?*anyopaque, connected: *bool, dophase_done: *bool) CURLcode {
    var result: CURLcode = CURLE_OK;
    const conn = Curl_pop3_smtp_get_conn(data);
    const smtp_raw = Curl_meta_get(data, CURL_META_SMTP_EASY) orelse return CURLE_FAILED_INIT;
    const smtp: *SMTP = @ptrCast(@alignCast(smtp_raw));

    if (Curl_pop3_smtp_get_req_no_body(data))
        smtp.transfer = PPTRANSFER_INFO;

    dophase_done.* = false;

    smtp.rcpt = Curl_pop3_smtp_get_mail_rcpt(data);
    smtp.rcpt_had_ok = false;
    smtp.rcpt_last_error = 0;
    smtp.trailing_crlf = true;
    smtp.eob = 2;

    if (Curl_pop3_smtp_is_upload_or_mime(data) and Curl_pop3_smtp_get_mail_rcpt(data) != null) {
        result = smtp_perform_mail(data);
    } else {
        result = smtp_perform_command(data);
    }

    if (result != CURLE_OK)
        return result;

    result = smtp_multi_statemach(data, dophase_done);
    connected.* = Curl_pop3_smtp_conn_is_connected(conn);

    return result;
}

fn smtp_do(data: ?*anyopaque, done: *bool) callconv(.c) CURLcode {
    done.* = false;

    const result = smtp_parse_custom_request(data);
    if (result != CURLE_OK)
        return result;

    return smtp_regular_transfer(data, done);
}

fn smtp_disconnect(data: ?*anyopaque, conn: ?*anyopaque, dead_connection: bool) callconv(.c) CURLcode {
    const smtpc_raw = Curl_conn_meta_get(conn, CURL_META_SMTP_CONN) orelse return CURLE_FAILED_INIT;
    const smtpc: *smtp_conn = @ptrCast(@alignCast(smtpc_raw));

    if (!dead_connection and Curl_pop3_smtp_get_protoconnstart(conn)) {
        if (smtp_perform_quit(data, smtpc) == CURLE_OK)
            _ = smtp_block_statemach(data, smtpc, true);
    }

    _ = Curl_pp_disconnect(&smtpc.pp);

    if (smtpc.domain) |dom| {
        mem.free(@ptrCast(dom));
        smtpc.domain = null;
    }

    return CURLE_OK;
}

fn smtp_dophase_done(data: ?*anyopaque, connected: bool) CURLcode {
    _ = connected;
    const smtp_raw = Curl_meta_get(data, CURL_META_SMTP_EASY) orelse return CURLE_FAILED_INIT;
    const smtp: *SMTP = @ptrCast(@alignCast(smtp_raw));

    if (smtp.transfer != PPTRANSFER_BODY)
        Curl_xfer_setup_nop(data);

    return CURLE_OK;
}

fn smtp_doing(data: ?*anyopaque, dophase_done: *bool) callconv(.c) CURLcode {
    var result = smtp_multi_statemach(data, dophase_done);
    if (result == CURLE_OK and dophase_done.*) {
        const conn = Curl_pop3_smtp_get_conn(data);
        result = smtp_dophase_done(data, Curl_pop3_smtp_conn_is_connected(conn));
    }
    return result;
}

fn smtp_regular_transfer(data: ?*anyopaque, dophase_done: *bool) CURLcode {
    var connected: bool = false;

    Curl_pop3_smtp_set_req_size(data, -1);
    Curl_pgrsReset(data);

    var result = smtp_perform(data, &connected, dophase_done);
    if (result == CURLE_OK and dophase_done.*)
        result = smtp_dophase_done(data, connected);

    return result;
}

fn smtp_setup_connection(data: ?*anyopaque, conn: ?*anyopaque) callconv(.c) CURLcode {
    const smtpc_raw = mem.calloc(1, @sizeOf(smtp_conn)) orelse return CURLE_OUT_OF_MEMORY;
    const smtpc: *smtp_conn = @ptrCast(@alignCast(smtpc_raw));

    smtpc.pp.statemachine = @ptrCast(&smtp_statemachine);
    smtpc.pp.endofresp = @ptrCast(&smtp_endofresp);

    Curl_pop3_smtp_sasl_init(&smtpc.sasl, data, &saslsmtp);

    if (Curl_conn_meta_set(conn, CURL_META_SMTP_CONN, smtpc_raw, smtp_conn_dtor) != CURLE_OK)
        return CURLE_OUT_OF_MEMORY;

    return smtp_init(data);
}

fn smtp_parse_url_options(conn: ?*anyopaque, smtpc: *smtp_conn) CURLcode {
    var result: CURLcode = CURLE_OK;
    var ptr_opt = Curl_pop3_smtp_get_conn_options(conn);

    while (result == CURLE_OK and ptr_opt != null and ptr_opt.?[0] != 0) {
        const ptr = ptr_opt.?;
        const key = ptr;
        var i: usize = 0;
        while (ptr[i] != 0 and ptr[i] != '=') : (i += 1) {}

        const val = ptr + i + 1;
        while (ptr[i] != 0 and ptr[i] != ';') : (i += 1) {}

        const val_start = @intFromPtr(val);
        const end_ptr = @intFromPtr(ptr + i);
        const vlen: usize = if (end_ptr >= val_start) end_ptr - val_start else 0;

        if (primitives.curl_strnequal(key, "AUTH=", 5) != 0) {
            result = Curl_pop3_smtp_sasl_parse_url_auth_option(&smtpc.sasl, val, vlen);
        } else {
            result = CURLE_URL_MALFORMAT;
        }

        if (ptr[i] == ';')
            i += 1;
        ptr_opt = ptr + i;
    }

    return result;
}

fn smtp_parse_url_path(data: ?*anyopaque) CURLcode {
    const conn = Curl_pop3_smtp_get_conn(data);
    const smtpc_raw = Curl_conn_meta_get(conn, CURL_META_SMTP_CONN) orelse return CURLE_FAILED_INIT;
    const smtpc: *smtp_conn = @ptrCast(@alignCast(smtpc_raw));
    const path: [*:0]const u8 = Curl_pop3_smtp_get_up_path(data) orelse "/";
    var localhost: [HOST_NAME_MAX + 1]u8 = @splat(0);

    var p: [*:0]const u8 = if (path[0] == '/') path + 1 else path;
    if (p[0] == 0) {
        if (os_leaf.Curl_gethostname(&localhost, @intCast(localhost.len)) == 0) {
            p = @ptrCast(&localhost);
        } else {
            p = "localhost";
        }
    }

    return Curl_urldecode(p, 0, &smtpc.domain, null, URLDEC_NO_CTRL);
}

fn smtp_parse_custom_request(data: ?*anyopaque) CURLcode {
    var result: CURLcode = CURLE_OK;
    const smtp_raw = Curl_meta_get(data, CURL_META_SMTP_EASY) orelse return CURLE_FAILED_INIT;
    const smtp: *SMTP = @ptrCast(@alignCast(smtp_raw));
    const custom = Curl_pop3_smtp_get_customrequest(data);

    if (custom != null and custom.?[0] != 0) {
        result = Curl_urldecode(custom.?, 0, &smtp.custom, null, URLDEC_NO_CTRL);
    }

    return result;
}

fn smtp_parse_address(
    data: ?*anyopaque,
    fqma: [*:0]const u8,
    address: *?[*:0]u8,
    host: *netrc_addr_idn.Hostname,
    suffix: *[*:0]const u8,
) CURLcode {
    var result: CURLcode = CURLE_OK;
    var length: usize = 0;

    const start: [*:0]const u8 = if (fqma[0] == '<') fqma + 1 else fqma;
    var dup: ?[*:0]u8 = null;
    result = Curl_urldecode(start, 0, &dup, &length, 0);
    if (result != CURLE_OK)
        return result;

    const d = dup orelse return CURLE_OUT_OF_MEMORY;
    if (length != 0) {
        if (fqma[0] != '<') {
            if (d[length - 1] == '>')
                d[length - 1] = 0;
        } else {
            if (std.mem.lastIndexOfScalar(u8, d[0..length], '>')) |end_idx| {
                d[end_idx] = 0;
                suffix.* = @ptrCast(d + end_idx + 1);
            } else {
                mem.free(@ptrCast(d));
                return CURLE_URL_MALFORMAT;
            }
        }
    }

    const cur_len = std.mem.len(d);
    if (std.mem.indexOfScalar(u8, d[0..cur_len], '@')) |at_idx| {
        d[at_idx] = 0;
        host.name = @ptrCast(d + at_idx + 1);
        _ = netrc_addr_idn.Curl_idnconvert_hostname(host);
    }

    _ = data;
    address.* = d;
    return result;
}

pub export const Curl_protocol_smtp = Curl_protocol{
    .setup_connection = smtp_setup_connection,
    .do_it = smtp_do,
    .done = smtp_done,
    .do_more = null,
    .connect_it = smtp_connect,
    .connecting = smtp_multi_statemach,
    .doing = smtp_doing,
    .proto_pollset = smtp_pollset,
    .doing_pollset = smtp_pollset,
    .domore_pollset = null,
    .perform_pollset = null,
    .disconnect = smtp_disconnect,
    .write_resp = null,
    .write_resp_hd = null,
    .connection_is_dead = null,
    .attach = null,
    .follow = null,
};

// ============================================================================
// Unit Tests
// ============================================================================

test "pop3_is_multiline classification" {
    try std.testing.expect(!pop3_is_multiline("APOP"));
    try std.testing.expect(!pop3_is_multiline("APOP user secret"));
    try std.testing.expect(!pop3_is_multiline("AUTH"));
    try std.testing.expect(pop3_is_multiline("CAPA"));
    try std.testing.expect(pop3_is_multiline("CAPA arg"));
    try std.testing.expect(!pop3_is_multiline("DELE 1"));
    try std.testing.expect(pop3_is_multiline("LIST"));
    try std.testing.expect(!pop3_is_multiline("LIST 1"));
    try std.testing.expect(pop3_is_multiline("RETR 1"));
    try std.testing.expect(!pop3_is_multiline("STAT"));
    try std.testing.expect(pop3_is_multiline("TOP 1 10"));
    try std.testing.expect(pop3_is_multiline("UIDL"));
    try std.testing.expect(!pop3_is_multiline("UIDL 1"));
    try std.testing.expect(!pop3_is_multiline("NOOP"));
    try std.testing.expect(pop3_is_multiline("UNKNOWN_CUSTOM"));
}

test "Curl_protocol_pop3 and Curl_protocol_smtp table layout" {
    try std.testing.expect(Curl_protocol_pop3.setup_connection != null);
    try std.testing.expect(Curl_protocol_pop3.do_it != null);
    try std.testing.expect(Curl_protocol_pop3.done != null);
    try std.testing.expect(Curl_protocol_pop3.connect_it != null);
    try std.testing.expect(Curl_protocol_pop3.connecting != null);
    try std.testing.expect(Curl_protocol_pop3.doing != null);
    try std.testing.expect(Curl_protocol_pop3.proto_pollset != null);
    try std.testing.expect(Curl_protocol_pop3.doing_pollset != null);
    try std.testing.expect(Curl_protocol_pop3.disconnect != null);
    try std.testing.expect(Curl_protocol_pop3.write_resp != null);
    try std.testing.expect(Curl_protocol_pop3.write_resp_hd != null);

    try std.testing.expect(Curl_protocol_smtp.setup_connection != null);
    try std.testing.expect(Curl_protocol_smtp.do_it != null);
    try std.testing.expect(Curl_protocol_smtp.done != null);
    try std.testing.expect(Curl_protocol_smtp.connect_it != null);
    try std.testing.expect(Curl_protocol_smtp.connecting != null);
    try std.testing.expect(Curl_protocol_smtp.doing != null);
    try std.testing.expect(Curl_protocol_smtp.proto_pollset != null);
    try std.testing.expect(Curl_protocol_smtp.doing_pollset != null);
    try std.testing.expect(Curl_protocol_smtp.disconnect != null);
    try std.testing.expect(Curl_protocol_smtp.write_resp == null);
    try std.testing.expect(Curl_protocol_smtp.write_resp_hd == null);
}

test "smtp_parse_address angle brackets, host, and suffix" {
    var addr: ?[*:0]u8 = null;
    var host: netrc_addr_idn.Hostname = std.mem.zeroes(netrc_addr_idn.Hostname);
    var suffix: [*:0]const u8 = "";

    try std.testing.expectEqual(CURLE_OK, smtp_parse_address(null, "<alice@example.com> NOTIFY=SUCCESS", &addr, &host, &suffix));
    try std.testing.expectEqualStrings("alice", std.mem.span(addr.?));
    try std.testing.expectEqualStrings("example.com", std.mem.span(host.name.?));
    try std.testing.expectEqualStrings(" NOTIFY=SUCCESS", std.mem.span(suffix));
    netrc_addr_idn.Curl_free_idnconverted_hostname(&host);
    mem.free(@ptrCast(addr.?));

    addr = null;
    host = std.mem.zeroes(netrc_addr_idn.Hostname);
    suffix = "";
    try std.testing.expectEqual(CURLE_OK, smtp_parse_address(null, "bob@example.org>", &addr, &host, &suffix));
    try std.testing.expectEqualStrings("bob", std.mem.span(addr.?));
    try std.testing.expectEqualStrings("example.org", std.mem.span(host.name.?));
    try std.testing.expectEqualStrings("", std.mem.span(suffix));
    netrc_addr_idn.Curl_free_idnconverted_hostname(&host);
    mem.free(@ptrCast(addr.?));

    addr = null;
    host = std.mem.zeroes(netrc_addr_idn.Hostname);
    suffix = "";
    try std.testing.expectEqual(CURLE_URL_MALFORMAT, smtp_parse_address(null, "<unclosed@example.com", &addr, &host, &suffix));
}
