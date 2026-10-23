const std = @import("std");
const builtin = @import("builtin");
const mem = @import("mem.zig");
const containers = @import("containers.zig");
const collections = @import("collections.zig");
const doh_hostip_easy = @import("doh_hostip_easy.zig");
const primitives = @import("primitives.zig");
const curlx_parse = @import("curlx_parse.zig");
const curlx_time_net = @import("curlx_time_net.zig");
const cookie_getinfo_trc = @import("cookie_getinfo_trc.zig");
const sasl_rtsp_ftplist = @import("sasl_rtsp_ftplist.zig");
const vdns_cfilters = @import("vdns_cfilters.zig");

const is_windows = builtin.os.tag == .windows;
const prefer_lf_lineends = !is_windows;

pub const CURLcode = c_uint;
pub const curl_off_t = i64;
pub const time_t = i64;
pub const timediff_t = curlx_time_net.timediff_t;
pub const curl_socket_t = curlx_time_net.curl_socket_t;
pub const Curltime = curlx_time_net.Curltime;
pub const Curl_easy = vdns_cfilters.Curl_easy;
pub const connectdata = vdns_cfilters.connectdata;
pub const easy_pollset = vdns_cfilters.easy_pollset;
pub const Curl_addrinfo = vdns_cfilters.Curl_addrinfo;
pub const pingpong = cookie_getinfo_trc.pingpong;
pub const dynbuf = containers.dynbuf;
pub const curl_slist = containers.curl_slist;
pub const WildcardData = sasl_rtsp_ftplist.WildcardData;
pub const ftp_wc = sasl_rtsp_ftplist.ftp_wc;
pub const curl_fileinfo = sasl_rtsp_ftplist.curl_fileinfo;

pub const Curl_dns_entry = opaque {};

pub const CurlProtocol = extern struct {
    setup_connection: ?*const fn (data: *Curl_easy, conn: *connectdata) callconv(.c) CURLcode,
    do_it: ?*const fn (data: *Curl_easy, done: *bool) callconv(.c) CURLcode,
    done: ?*const fn (data: *Curl_easy, status: CURLcode, premature: bool) callconv(.c) CURLcode,
    do_more: ?*const fn (data: *Curl_easy, domore_out: *c_int) callconv(.c) CURLcode,
    connect_it: ?*const fn (data: *Curl_easy, done: *bool) callconv(.c) CURLcode,
    connecting: ?*const fn (data: *Curl_easy, done: *bool) callconv(.c) CURLcode,
    doing: ?*const fn (data: *Curl_easy, done: *bool) callconv(.c) CURLcode,
    proto_pollset: ?*const fn (data: *Curl_easy, ps: *easy_pollset) callconv(.c) CURLcode,
    doing_pollset: ?*const fn (data: *Curl_easy, ps: *easy_pollset) callconv(.c) CURLcode,
    domore_pollset: ?*const fn (data: *Curl_easy, ps: *easy_pollset) callconv(.c) CURLcode,
    perform_pollset: ?*const fn (data: *Curl_easy, ps: *easy_pollset) callconv(.c) CURLcode,
    disconnect: ?*const fn (data: *Curl_easy, conn: *connectdata, dead_connection: bool) callconv(.c) CURLcode,
    write_resp: ?*const fn (data: *Curl_easy, buf: [*]const u8, blen: usize, is_eos: bool) callconv(.c) CURLcode,
    write_resp_hd: ?*const fn (data: *Curl_easy, hd: [*]const u8, hdlen: usize, is_eos: bool) callconv(.c) CURLcode,
    connection_is_dead: ?*const fn (data: *Curl_easy, conn: *connectdata) callconv(.c) bool,
    attach: ?*const fn (data: *Curl_easy, conn: *connectdata) callconv(.c) void,
    follow: ?*const fn (data: *Curl_easy, newurl: [*:0]const u8, ftype: c_uint) callconv(.c) CURLcode,
};

// CURLcode constants
pub const CURLE_OK: CURLcode = 0;
pub const CURLE_UNSUPPORTED_PROTOCOL: CURLcode = 1;
pub const CURLE_FAILED_INIT: CURLcode = 2;
pub const CURLE_URL_MALFORMAT: CURLcode = 3;
pub const CURLE_COULDNT_RESOLVE_HOST: CURLcode = 6;
pub const CURLE_COULDNT_CONNECT: CURLcode = 7;
pub const CURLE_WEIRD_SERVER_REPLY: CURLcode = 8;
pub const CURLE_REMOTE_ACCESS_DENIED: CURLcode = 9;
pub const CURLE_FTP_ACCEPT_FAILED: CURLcode = 10;
pub const CURLE_FTP_WEIRD_PASS_REPLY: CURLcode = 11;
pub const CURLE_FTP_ACCEPT_TIMEOUT: CURLcode = 12;
pub const CURLE_FTP_WEIRD_PASV_REPLY: CURLcode = 13;
pub const CURLE_FTP_WEIRD_227_FORMAT: CURLcode = 14;
pub const CURLE_FTP_CANT_GET_HOST: CURLcode = 15;
pub const CURLE_FTP_COULDNT_SET_TYPE: CURLcode = 17;
pub const CURLE_PARTIAL_FILE: CURLcode = 18;
pub const CURLE_FTP_COULDNT_RETR_FILE: CURLcode = 19;
pub const CURLE_QUOTE_ERROR: CURLcode = 21;
pub const CURLE_WRITE_ERROR: CURLcode = 23;
pub const CURLE_UPLOAD_FAILED: CURLcode = 25;
pub const CURLE_OUT_OF_MEMORY: CURLcode = 27;
pub const CURLE_OPERATION_TIMEDOUT: CURLcode = 28;
pub const CURLE_FTP_PORT_FAILED: CURLcode = 30;
pub const CURLE_FTP_COULDNT_USE_REST: CURLcode = 31;
pub const CURLE_RANGE_ERROR: CURLcode = 33;
pub const CURLE_BAD_DOWNLOAD_RESUME: CURLcode = 36;
pub const CURLE_ABORTED_BY_CALLBACK: CURLcode = 42;
pub const CURLE_BAD_FUNCTION_ARGUMENT: CURLcode = 43;
pub const CURLE_UNKNOWN_OPTION: CURLcode = 48;
pub const CURLE_SEND_ERROR: CURLcode = 55;
pub const CURLE_RECV_ERROR: CURLcode = 56;
pub const CURLE_PEER_FAILED_VERIFICATION: CURLcode = 60;
pub const CURLE_FILESIZE_EXCEEDED: CURLcode = 63;
pub const CURLE_USE_SSL_FAILED: CURLcode = 64;
pub const CURLE_LOGIN_DENIED: CURLcode = 67;
pub const CURLE_REMOTE_DISK_FULL: CURLcode = 70;
pub const CURLE_REMOTE_FILE_NOT_FOUND: CURLcode = 78;
pub const CURLE_FTP_PRET_FAILED: CURLcode = 84;
pub const CURLE_FTP_BAD_FILE_LIST: CURLcode = 87;
pub const CURLE_CHUNK_FAILED: CURLcode = 88;

pub const FIRSTSOCKET: i8 = 0;
pub const SECONDARYSOCKET: i8 = 1;
pub const CURL_SOCKET_BAD: curl_socket_t = if (is_windows)
    std.math.maxInt(curl_socket_t)
else
    -1;

inline fn isDigit(c: u8) bool {
    return c >= '0' and c <= '9';
}

inline fn isCntrl(c: u8) bool {
    return c < 0x20 or c == 0x7f;
}

pub const CLIENTWRITE_BODY: c_int = 1 << 0;
pub const CLIENTWRITE_INFO: c_int = 1 << 1;
pub const CLIENTWRITE_HEADER: c_int = 1 << 2;
pub const CLIENTWRITE_EOS: c_int = 1 << 7;
pub const CURL_CW_CONTENT_DECODE: c_uint = 4;

pub const PPTRANSFER_BODY: c_uint = 0;
pub const PPTRANSFER_INFO: c_uint = 1;
pub const PPTRANSFER_NONE: c_uint = 2;

pub const FTPFILE_MULTICWD: u8 = 1;
pub const FTPFILE_NOCWD: u8 = 2;
pub const FTPFILE_SINGLECWD: u8 = 3;

pub const CURLFTPAUTH_DEFAULT: u8 = 0;
pub const CURLFTPAUTH_SSL: u8 = 1;
pub const CURLFTPAUTH_TLS: u8 = 2;

pub const CURLFTPSSL_CCC_NONE: u8 = 0;
pub const CURLFTPSSL_CCC_PASSIVE: u8 = 1;
pub const CURLFTPSSL_CCC_ACTIVE: u8 = 2;

pub const CURLUSESSL_NONE: u8 = 0;
pub const CURLUSESSL_TRY: u8 = 1;
pub const CURLUSESSL_CONTROL: u8 = 2;
pub const CURLUSESSL_ALL: u8 = 3;

pub const CURL_TIMECOND_NONE: u8 = 0;
pub const CURL_TIMECOND_IFMODSINCE: u8 = 1;
pub const CURL_TIMECOND_IFUNMODSINCE: u8 = 2;
pub const CURL_TIMECOND_LASTMOD: u8 = 3;

pub const DOMORE_GOBACK: c_int = -1;
pub const DOMORE_INCOMPLETE: c_int = 0;
pub const DOMORE_DONE: c_int = 1;

pub const PROTOPT_SSL: c_uint = 1 << 0;

pub const CURL_SEEKFUNC_OK: c_int = 0;

pub const REJECT_CTRL: c_uint = 3;
pub const EXPIRE_FTP_ACCEPT: c_uint = 9;
pub const DEFAULT_ACCEPT_TIMEOUT: timediff_t = 60000;
pub const RESPONSE_TIMEOUT_MS: timediff_t = 3600 * 1000;
pub const CURL_OFF_T_MAX: curl_off_t = std.math.maxInt(curl_off_t);
pub const STRERROR_LEN: usize = 256;
pub const NI_MAXHOST: usize = 1025;

pub const IF2IP_NOT_FOUND: c_int = 0;
pub const IF2IP_AF_NOT_SUPPORTED: c_int = 1;
pub const IF2IP_FOUND: c_int = 2;

pub const CURL_CSELECT_IN: c_int = 0x01;
pub const CURL_CSELECT_OUT: c_int = 0x02;
pub const CURL_CSELECT_ERR: c_int = 0x04;

pub const CURL_CHUNK_BGN_FUNC_OK: c_long = 0;
pub const CURL_CHUNK_BGN_FUNC_FAIL: c_long = 1;
pub const CURL_CHUNK_BGN_FUNC_SKIP: c_long = 2;

pub const CURL_META_FTP_EASY = "meta:proto:ftp:easy";
pub const CURL_META_FTP_CONN = "meta:proto:ftp:conn";

// ============================================================================
// FTP State Machine & Data Structures (from lib/ftp-int.h)
// ============================================================================

pub const ftpstate = enum(u8) {
    FTP_STOP = 0,
    FTP_WAIT220 = 1,
    FTP_AUTH = 2,
    FTP_USER = 3,
    FTP_PASS = 4,
    FTP_ACCT = 5,
    FTP_PBSZ = 6,
    FTP_PROT = 7,
    FTP_CCC = 8,
    FTP_PWD = 9,
    FTP_SYST = 10,
    FTP_NAMEFMT = 11,
    FTP_QUOTE = 12,
    FTP_RETR_PREQUOTE = 13,
    FTP_STOR_PREQUOTE = 14,
    FTP_LIST_PREQUOTE = 15,
    FTP_POSTQUOTE = 16,
    FTP_CWD = 17,
    FTP_MKD = 18,
    FTP_MDTM = 19,
    FTP_TYPE = 20,
    FTP_LIST_TYPE = 21,
    FTP_RETR_LIST_TYPE = 22,
    FTP_RETR_TYPE = 23,
    FTP_STOR_TYPE = 24,
    FTP_SIZE = 25,
    FTP_RETR_SIZE = 26,
    FTP_STOR_SIZE = 27,
    FTP_REST = 28,
    FTP_RETR_REST = 29,
    FTP_PORT = 30,
    FTP_PRET = 31,
    FTP_PASV = 32,
    FTP_LIST = 33,
    FTP_RETR = 34,
    FTP_STOR = 35,
    FTP_QUIT = 36,
    FTP_LAST = 37,
};

pub const ftp_parselist_data = sasl_rtsp_ftplist.ftp_parselist_data;

pub const FTP = extern struct {
    path: ?[*:0]u8 = null,
    pathalloc: ?[*:0]u8 = null,
    transfer: c_uint = PPTRANSFER_BODY,
    downloadsize: curl_off_t = 0,
};

pub const pathcomp = extern struct {
    start: c_int = 0,
    len: c_int = 0,
};

pub const ftp_conn = extern struct {
    pp: pingpong = undefined,
    account: ?[*:0]u8 = null,
    alternative_to_user: ?[*:0]u8 = null,
    entrypath: ?[*:0]u8 = null,
    file: ?[*:0]u8 = null,
    rawpath: ?[*:0]u8 = null,
    dirs: ?[*]pathcomp = null,
    prevpath: ?[*:0]u8 = null,
    transfertype: u8 = 0,
    server_os: ?[*:0]u8 = null,
    known_filesize: curl_off_t = -1,
    count1: c_int = 0,
    count2: c_int = 0,
    count3: c_int = 0,
    dirdepth: u16 = 0,
    cwdcount: u16 = 0,
    state: ftpstate = .FTP_STOP,
    use_ssl: u8 = 0,
    ccc: u8 = 0,
    ftp_trying_alternative: bool = false,
    dont_check: bool = false,
    ctl_valid: bool = false,
    cwddone: bool = false,
    cwdfail: bool = false,
    wait_data_conn: bool = false,
    shutdown: bool = false,
};

const ftpport = enum(c_uint) {
    EPRT = 0,
    PORT = 1,
    DONE = 2,
};

// ============================================================================
// Content Writer Types (from lib/sendf.h)
// ============================================================================

pub const Curl_cwriter = extern struct {
    cwt: *const Curl_cwtype,
    next: ?*Curl_cwriter,
    ctx: ?*anyopaque,
    phase: c_uint,
};

pub const Curl_cwtype = extern struct {
    name: [*:0]const u8,
    alias: ?[*:0]const u8,
    flags: u8,
    do_init: *const fn (data: *Curl_easy, writer: *Curl_cwriter) callconv(.c) CURLcode,
    do_write: *const fn (data: *Curl_easy, writer: *Curl_cwriter, wtype: c_int, buf: [*]const u8, nbytes: usize) callconv(.c) CURLcode,
    do_flush: *const fn (data: *Curl_easy, writer: *Curl_cwriter) callconv(.c) CURLcode,
    do_close: *const fn (data: *Curl_easy, writer: *Curl_cwriter) callconv(.c) void,
    cwriter_size: usize,
};

pub const ftp_cw_lc_ctx = extern struct {
    super: Curl_cwriter,
    newline_pending: bool,
};

inline fn Curl_cwriter_write(
    data: *Curl_easy,
    writer_opt: ?*Curl_cwriter,
    wtype: c_int,
    buf: [*]const u8,
    nbytes: usize,
) CURLcode {
    const writer = writer_opt orelse return CURLE_WRITE_ERROR;
    return writer.cwt.do_write(data, writer, wtype, buf, nbytes);
}

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

// ============================================================================
// External C Functions & Accessors
// ============================================================================

extern const Curl_wkday: [7][*:0]const u8;
extern const Curl_month: [12][*:0]const u8;

extern fn Curl_infof(data: ?*Curl_easy, fmt: [*:0]const u8, ...) callconv(.c) void;
extern fn Curl_failf(data: ?*Curl_easy, fmt: [*:0]const u8, ...) callconv(.c) void;
extern fn Curl_trc_ftp(data: ?*Curl_easy, fmt: [*:0]const u8, ...) callconv(.c) void;

extern fn curl_msnprintf(buffer: [*]u8, maxlength: usize, format: [*:0]const u8, ...) callconv(.c) c_int;
extern fn curl_maprintf(format: [*:0]const u8, ...) callconv(.c) ?[*:0]u8;
extern fn curlx_strerror(err: c_int, buf: [*]u8, buflen: usize) callconv(.c) [*:0]const u8;
extern fn curl_easy_strerror(err: CURLcode) callconv(.c) [*:0]const u8;
extern fn curlx_memdup0(src: ?[*]const u8, length: usize) callconv(.c) ?[*:0]u8;

extern fn curlx_str_number(linep: *?[*:0]const u8, nump: *curl_off_t, max: curl_off_t) callconv(.c) c_int;
extern fn curlx_str_single(linep: *?[*:0]const u8, byte: u8) callconv(.c) c_int;
extern fn curlx_str_newline(linep: *?[*:0]const u8) callconv(.c) c_int;
extern fn curlx_str_cspn(linep: *?[*:0]const u8, out: *curlx_parse.Curl_str, reject: [*:0]const u8) callconv(.c) c_int;

extern fn Curl_urldecode(string: [*:0]const u8, length: usize, ostring: *?[*:0]u8, olen: ?*usize, ctrl: c_uint) callconv(.c) CURLcode;
extern fn Curl_getdate_capped(p: ?[*:0]const u8, tp: *time_t) callconv(.c) c_int;

extern fn Curl_pgrs_now(data: *Curl_easy) callconv(.c) *const Curltime;
extern fn Curl_pgrsSetDownloadSize(data: *Curl_easy, size: curl_off_t) callconv(.c) void;
extern fn Curl_pgrsSetUploadSize(data: *Curl_easy, size: curl_off_t) callconv(.c) void;
extern fn Curl_pgrsUpdate(data: *Curl_easy) callconv(.c) CURLcode;
extern fn Curl_pgrsReset(data: *Curl_easy) callconv(.c) void;
extern fn Curl_expire(data: ?*Curl_easy, milli: timediff_t, id: c_uint) callconv(.c) void;

extern fn Curl_pp_init(pp: *pingpong, pnow: *const Curltime) callconv(.c) void;
extern fn Curl_pp_sendf(data: ?*Curl_easy, pp: *pingpong, fmt: [*:0]const u8, ...) callconv(.c) CURLcode;
extern fn Curl_pp_needs_flush(data: ?*Curl_easy, pp: *pingpong) callconv(.c) bool;
extern fn Curl_pp_flushsend(data: ?*Curl_easy, pp: *pingpong) callconv(.c) CURLcode;
extern fn Curl_pp_disconnect(pp: *pingpong) callconv(.c) CURLcode;
extern fn Curl_pp_moredata(pp: *pingpong) callconv(.c) bool;

extern fn Curl_conn_cf_discard_all(data: *Curl_easy, conn: *connectdata, index: i8) callconv(.c) void;
extern fn Curl_conn_connect(data: *Curl_easy, sockindex: i8, blocking: bool, done: *bool) callconv(.c) CURLcode;
extern fn Curl_conn_data_pending(data: *Curl_easy, sockindex: i8) callconv(.c) bool;
extern fn Curl_conn_is_connected(conn: *connectdata, sockindex: i8) callconv(.c) bool;
extern fn Curl_conn_is_ip_connected(data: *Curl_easy, sockindex: i8) callconv(.c) bool;
extern fn Curl_conn_is_setup(conn: *connectdata, sockindex: i8) callconv(.c) bool;
extern fn Curl_conn_is_ssl(conn: ?*connectdata, sockindex: i8) callconv(.c) bool;
extern fn Curl_conn_is_tcp_listen(data: *Curl_easy, sockindex: i8) callconv(.c) bool;
extern fn Curl_conn_is_tunneling(conn: *connectdata, sockindex: i8) callconv(.c) bool;
extern fn Curl_conn_tcp_listen_set(data: *Curl_easy, conn: *connectdata, sockindex: i8, s: *curl_socket_t) callconv(.c) CURLcode;
extern fn Curl_conn_adjust_pollset(data: *Curl_easy, conn: *connectdata, ps: *easy_pollset) callconv(.c) CURLcode;

extern fn Curl_socket_close(data: *Curl_easy, conn: *connectdata, sock: curl_socket_t) callconv(.c) c_int;
extern fn Curl_socket_check(readfd0: curl_socket_t, readfd1: curl_socket_t, writefd: curl_socket_t, timeout_ms: timediff_t) callconv(.c) c_int;

extern fn Curl_dns_entry_unlink(data: ?*Curl_easy, pdns: *?*Curl_dns_entry) callconv(.c) void;

extern fn Curl_xfer_setup_nop(data: *Curl_easy) callconv(.c) void;
extern fn Curl_xfer_set_shutdown(data: *Curl_easy, recv_shutdown: bool, send_shutdown: bool) callconv(.c) void;

extern fn Curl_cwriter_create(pwriter: *?*Curl_cwriter, data: *Curl_easy, cwt: *const Curl_cwtype, phase: c_uint) callconv(.c) CURLcode;
extern fn Curl_cwriter_add(data: *Curl_easy, writer: *Curl_cwriter) callconv(.c) CURLcode;
extern fn Curl_cwriter_free(data: *Curl_easy, writer: ?*Curl_cwriter) callconv(.c) void;
extern fn Curl_cwriter_def_init(data: *Curl_easy, writer: *Curl_cwriter) callconv(.c) CURLcode;
extern fn Curl_cwriter_def_flush(data: *Curl_easy, writer: *Curl_cwriter) callconv(.c) CURLcode;
extern fn Curl_cwriter_def_close(data: *Curl_easy, writer: *Curl_cwriter) callconv(.c) void;

const HashDtor = *const fn (key: ?*const anyopaque, klen: usize, entry: ?*anyopaque) callconv(.c) void;
extern fn Curl_conn_meta_set(conn: *connectdata, key: [*:0]const u8, entry: ?*anyopaque, dtor: HashDtor) callconv(.c) CURLcode;
extern fn Curl_conn_meta_get(conn: *connectdata, key: [*:0]const u8) callconv(.c) ?*anyopaque;
extern fn Curl_conn_meta_remove(conn: *connectdata, key: [*:0]const u8) callconv(.c) void;
extern fn Curl_meta_set(data: *Curl_easy, key: [*:0]const u8, entry: ?*anyopaque, dtor: HashDtor) callconv(.c) CURLcode;
extern fn Curl_meta_get(data: *Curl_easy, key: [*:0]const u8) callconv(.c) ?*anyopaque;

// Accessor helpers in lib/http.c
extern fn Curl_ftp_acc_trc_bind(data: ?*Curl_easy) callconv(.c) void;
extern fn Curl_ftp_acc_get_conn(data: *Curl_easy) callconv(.c) ?*connectdata;
extern fn Curl_ftp_acc_pwd_stop_debug(data: *Curl_easy) callconv(.c) bool;
extern fn Curl_ftp_acc_get_wildcard(data: *Curl_easy) callconv(.c) *WildcardData;
extern fn Curl_ftp_acc_get_wildcardmatch(data: *Curl_easy) callconv(.c) bool;
extern fn Curl_ftp_acc_get_ftp_filemethod(data: *Curl_easy) callconv(.c) u8;
extern fn Curl_ftp_acc_set_ftp_filemethod(data: *Curl_easy, val: u8) callconv(.c) void;
extern fn Curl_ftp_acc_get_upload(data: *Curl_easy) callconv(.c) bool;
extern fn Curl_ftp_acc_get_prefer_ascii(data: *Curl_easy) callconv(.c) bool;
extern fn Curl_ftp_acc_set_prefer_ascii(data: *Curl_easy, val: bool) callconv(.c) void;
extern fn Curl_ftp_acc_get_list_only(data: *Curl_easy) callconv(.c) bool;
extern fn Curl_ftp_acc_set_list_only(data: *Curl_easy, val: bool) callconv(.c) void;
extern fn Curl_ftp_acc_get_no_body(data: *Curl_easy) callconv(.c) bool;
extern fn Curl_ftp_acc_get_infilesize(data: *Curl_easy) callconv(.c) curl_off_t;
extern fn Curl_ftp_acc_set_infilesize(data: *Curl_easy, val: curl_off_t) callconv(.c) void;
extern fn Curl_ftp_acc_get_resume_from(data: *Curl_easy) callconv(.c) curl_off_t;
extern fn Curl_ftp_acc_set_resume_from(data: *Curl_easy, val: curl_off_t) callconv(.c) void;
extern fn Curl_ftp_acc_get_req_size(data: *Curl_easy) callconv(.c) curl_off_t;
extern fn Curl_ftp_acc_set_req_size(data: *Curl_easy, val: curl_off_t) callconv(.c) void;
extern fn Curl_ftp_acc_get_req_maxdownload(data: *Curl_easy) callconv(.c) curl_off_t;
extern fn Curl_ftp_acc_get_req_bytecount(data: *Curl_easy) callconv(.c) curl_off_t;
extern fn Curl_ftp_acc_get_req_writebytecount(data: *Curl_easy) callconv(.c) curl_off_t;
extern fn Curl_ftp_acc_get_max_filesize(data: *Curl_easy) callconv(.c) curl_off_t;
extern fn Curl_ftp_acc_get_ignorecl(data: *Curl_easy) callconv(.c) bool;
extern fn Curl_ftp_acc_get_crlf(data: *Curl_easy) callconv(.c) bool;
extern fn Curl_ftp_acc_get_remote_append(data: *Curl_easy) callconv(.c) bool;
extern fn Curl_ftp_acc_get_ftp_use_port(data: *Curl_easy) callconv(.c) bool;
extern fn Curl_ftp_acc_get_ftp_use_pret(data: *Curl_easy) callconv(.c) bool;
extern fn Curl_ftp_acc_get_ftp_skip_ip(data: *Curl_easy) callconv(.c) bool;
extern fn Curl_ftp_acc_get_ftp_create_missing_dirs(data: *Curl_easy) callconv(.c) u8;
extern fn Curl_ftp_acc_get_use_ssl(data: *Curl_easy) callconv(.c) u8;
extern fn Curl_ftp_acc_get_ftpsslauth(data: *Curl_easy) callconv(.c) u8;
extern fn Curl_ftp_acc_get_ftp_ccc(data: *Curl_easy) callconv(.c) u8;
extern fn Curl_ftp_acc_get_accepttimeout(data: *Curl_easy) callconv(.c) timediff_t;
extern fn Curl_ftp_acc_get_get_filetime(data: *Curl_easy) callconv(.c) bool;
extern fn Curl_ftp_acc_get_timecondition(data: *Curl_easy) callconv(.c) u8;
extern fn Curl_ftp_acc_get_timevalue(data: *Curl_easy) callconv(.c) curl_off_t;
extern fn Curl_ftp_acc_get_info_filetime(data: *Curl_easy) callconv(.c) curl_off_t;
extern fn Curl_ftp_acc_get_info_filetime_ptr(data: *Curl_easy) callconv(.c) *time_t;
extern fn Curl_ftp_acc_set_info_timecond(data: *Curl_easy, val: bool) callconv(.c) void;
extern fn Curl_ftp_acc_set_info_httpcode(data: *Curl_easy, code: c_int) callconv(.c) void;
extern fn Curl_ftp_acc_clear_state_errorbuf(data: *Curl_easy) callconv(.c) void;
extern fn Curl_ftp_acc_set_most_recent_ftp_entrypath(data: *Curl_easy, entrypath: [*:0]const u8) callconv(.c) CURLcode;
extern fn Curl_ftp_acc_get_up_path_after_slash(data: *Curl_easy) callconv(.c) [*:0]u8;
extern fn Curl_ftp_acc_get_quote(data: *Curl_easy) callconv(.c) ?*curl_slist;
extern fn Curl_ftp_acc_get_prequote(data: *Curl_easy) callconv(.c) ?*curl_slist;
extern fn Curl_ftp_acc_get_postquote(data: *Curl_easy) callconv(.c) ?*curl_slist;
extern fn Curl_ftp_acc_get_str_ftpport(data: *Curl_easy) callconv(.c) ?[*:0]const u8;
extern fn Curl_ftp_acc_get_str_customrequest(data: *Curl_easy) callconv(.c) ?[*:0]const u8;
extern fn Curl_ftp_acc_get_str_ftp_account(data: *Curl_easy) callconv(.c) ?[*:0]const u8;
extern fn Curl_ftp_acc_get_str_ftp_alternative_to_user(data: *Curl_easy) callconv(.c) ?[*:0]const u8;
extern fn Curl_ftp_acc_client_write_header(data: *Curl_easy, buf: [*]u8, blen: usize) callconv(.c) CURLcode;

extern fn Curl_ftp_acc_conn_get_sock(conn: *connectdata, idx: c_int) callconv(.c) curl_socket_t;
extern fn Curl_ftp_acc_conn_has_cfilter(conn: *connectdata, idx: c_int) callconv(.c) bool;
extern fn Curl_ftp_acc_conn_get_reuse(conn: *connectdata) callconv(.c) bool;
extern fn Curl_ftp_acc_conn_get_ipv6(conn: *connectdata) callconv(.c) bool;
extern fn Curl_ftp_acc_conn_get_ftp_use_eprt(conn: *connectdata) callconv(.c) bool;
extern fn Curl_ftp_acc_conn_set_ftp_use_eprt(conn: *connectdata, val: bool) callconv(.c) void;
extern fn Curl_ftp_acc_conn_get_ftp_use_epsv(conn: *connectdata) callconv(.c) bool;
extern fn Curl_ftp_acc_conn_set_ftp_use_epsv(conn: *connectdata, val: bool) callconv(.c) void;
extern fn Curl_ftp_acc_conn_get_ftp_use_data_ssl(conn: *connectdata) callconv(.c) bool;
extern fn Curl_ftp_acc_conn_set_ftp_use_data_ssl(conn: *connectdata, val: bool) callconv(.c) void;
extern fn Curl_ftp_acc_conn_set_do_more(conn: *connectdata, val: bool) callconv(.c) void;
extern fn Curl_ftp_acc_conn_get_origin_hostname(conn: *connectdata) callconv(.c) [*:0]const u8;
extern fn Curl_ftp_acc_conn_get_scheme_flags(conn: *connectdata) callconv(.c) c_uint;
extern fn Curl_ftp_acc_conn_get_user(conn: *connectdata) callconv(.c) [*:0]const u8;
extern fn Curl_ftp_acc_conn_get_passwd(conn: *connectdata) callconv(.c) [*:0]const u8;

extern fn Curl_ftp_acc_has_seek_func(data: *Curl_easy) callconv(.c) bool;
extern fn Curl_ftp_acc_call_seek_func(data: *Curl_easy, offset: curl_off_t) callconv(.c) c_int;
extern fn Curl_ftp_acc_call_fread_func(data: *Curl_easy, buf: [*]u8, amount: usize) callconv(.c) usize;
extern fn Curl_ftp_acc_has_chunk_bgn(data: *Curl_easy) callconv(.c) bool;
extern fn Curl_ftp_acc_call_chunk_bgn(data: *Curl_easy, finfo: *const curl_fileinfo, remains: c_int) callconv(.c) c_long;
extern fn Curl_ftp_acc_has_chunk_end(data: *Curl_easy) callconv(.c) bool;
extern fn Curl_ftp_acc_call_chunk_end(data: *Curl_easy) callconv(.c) void;

extern fn Curl_ftp_acc_get_sockerrno() callconv(.c) c_int;
extern fn Curl_ftp_acc_pp_state_timeleft_ms(data: *Curl_easy, pp: *pingpong) callconv(.c) timediff_t;
extern fn Curl_ftp_acc_pp_statemach(data: *Curl_easy, pp: *pingpong, block: bool, disconnecting: bool) callconv(.c) CURLcode;
extern fn Curl_ftp_acc_pp_readresp(data: *Curl_easy, sockindex: i8, pp: *pingpong, code: *c_int, size: *usize) callconv(.c) CURLcode;
extern fn Curl_ftp_acc_pp_pollset(data: *Curl_easy, pp: *pingpong, ps: *easy_pollset) callconv(.c) CURLcode;
extern fn Curl_ftp_acc_pollset_add_in(data: *Curl_easy, ps: *easy_pollset, sock: curl_socket_t) callconv(.c) CURLcode;
extern fn Curl_ftp_acc_range(data: *Curl_easy) callconv(.c) CURLcode;
extern fn Curl_ftp_acc_xfer_setup_send(data: *Curl_easy) callconv(.c) void;
extern fn Curl_ftp_acc_xfer_setup_recv(data: *Curl_easy, size: curl_off_t) callconv(.c) void;
extern fn Curl_ftp_acc_connclose(conn: *connectdata) callconv(.c) void;
extern fn Curl_ftp_acc_ssl_cfilter_add(data: *Curl_easy, conn: *connectdata, sockindex: i8) callconv(.c) CURLcode;
extern fn Curl_ftp_acc_ssl_cfilter_remove(data: *Curl_easy, sockindex: i8, send_shutdown: bool) callconv(.c) CURLcode;
extern fn Curl_ftp_acc_control_addr_dup(data: *Curl_easy, newhostp: *?[*:0]u8) callconv(.c) CURLcode;
extern fn Curl_ftp_acc_setup_pasv_conn(data: *Curl_easy, conn: *connectdata, newhost: [*:0]const u8, newport: u16) callconv(.c) CURLcode;
extern fn Curl_ftp_acc_is_ipv6_literal(str: [*:0]const u8) callconv(.c) bool;
extern fn Curl_ftp_acc_if2ip(data: *Curl_easy, conn: *connectdata, ipstr: [*:0]const u8, hbuf: [*]u8, hbuflen: usize) callconv(.c) c_int;
extern fn Curl_ftp_acc_port_default_host(data: *Curl_easy, conn: *connectdata, ss_ptr: *anyopaque, sslenp: *c_uint, hbuf: [*]u8, hbuflen: usize) callconv(.c) CURLcode;
extern fn Curl_ftp_acc_port_resolve_host(data: *Curl_easy, conn: *connectdata, host: [*:0]const u8, dns_entryp: *?*Curl_dns_entry, resp: *?*const Curl_addrinfo) callconv(.c) CURLcode;
extern fn Curl_ftp_acc_port_open_socket(data: *Curl_easy, conn: *connectdata, res: ?*const Curl_addrinfo, aip: *?*const Curl_addrinfo, portsockp: *curl_socket_t) callconv(.c) CURLcode;
extern fn Curl_ftp_acc_port_bind_socket(data: *Curl_easy, conn: *connectdata, portsock: curl_socket_t, ai: *const Curl_addrinfo, ss_ptr: *anyopaque, sslen_io: *c_uint, port_min: u16, port_max: u16, non_local: bool, pbound_port: *u16) callconv(.c) CURLcode;
extern fn Curl_ftp_acc_port_listen(data: *Curl_easy, portsock: curl_socket_t) callconv(.c) CURLcode;
extern fn Curl_ftp_acc_port_extract_sa(ss_ptr: *const anyopaque, ai: ?*const Curl_addrinfo, myhost: [*]u8, myhost_len: usize, pis_ipv4: *bool, pis_ipv6: *bool, pport: *u16) callconv(.c) void;

// ============================================================================
// Logging / Tracing Helpers
// ============================================================================

inline fn infof(data: ?*Curl_easy, fmt: [*:0]const u8, args: anytype) void {
    if (data) |d| {
        Curl_ftp_acc_trc_bind(d);
        @call(.auto, Curl_infof, .{ d, fmt } ++ args);
    }
}

inline fn failf(data: ?*Curl_easy, fmt: [*:0]const u8, args: anytype) void {
    if (data) |d| {
        Curl_ftp_acc_trc_bind(d);
        @call(.auto, Curl_failf, .{ d, fmt } ++ args);
    }
}

inline fn trcFtp(data: ?*Curl_easy, fmt: [*:0]const u8, args: anytype) void {
    if (data) |d| {
        Curl_ftp_acc_trc_bind(d);
        @call(.auto, Curl_trc_ftp, .{ d, fmt } ++ args);
    }
}

inline fn ppSendf(data: *Curl_easy, pp: *pingpong, fmt: [*:0]const u8, args: anytype) CURLcode {
    Curl_ftp_acc_trc_bind(data);
    return @call(.auto, Curl_pp_sendf, .{ data, pp, fmt } ++ args);
}

// ============================================================================
// State Machine Transition Helper
// ============================================================================

const ftp_state_names = [_][*:0]const u8{
    "STOP",
    "WAIT220",
    "AUTH",
    "USER",
    "PASS",
    "ACCT",
    "PBSZ",
    "PROT",
    "CCC",
    "PWD",
    "SYST",
    "NAMEFMT",
    "QUOTE",
    "RETR_PREQUOTE",
    "STOR_PREQUOTE",
    "LIST_PREQUOTE",
    "POSTQUOTE",
    "CWD",
    "MKD",
    "MDTM",
    "TYPE",
    "LIST_TYPE",
    "RETR_LIST_TYPE",
    "RETR_TYPE",
    "STOR_TYPE",
    "SIZE",
    "RETR_SIZE",
    "STOR_SIZE",
    "REST",
    "RETR_REST",
    "PORT",
    "PRET",
    "PASV",
    "LIST",
    "RETR",
    "STOR",
    "QUIT",
};

inline fn ftp_cstate(ftpc: *const ftp_conn) [*:0]const u8 {
    return ftp_state_names[@backingInt(ftpc.state)];
}

fn ftp_state(data: *Curl_easy, ftpc: *ftp_conn, newstate: ftpstate) void {
    if (ftpc.state != newstate) {
        trcFtp(data, "[%s] -> [%s]", .{
            ftp_cstate(ftpc),
            ftp_state_names[@backingInt(newstate)],
        });
    }
    ftpc.state = newstate;
}

// ============================================================================
// Path & Directory Helpers
// ============================================================================

inline fn fromOpaque(comptime T: type, ptr: anytype) *T {
    return @ptrCast(@alignCast(ptr));
}

inline fn getFtpEasy(data: *Curl_easy) ?*FTP {
    return doh_hostip_easy.metaGetTyped(FTP, data, CURL_META_FTP_EASY);
}

inline fn getFtpConn(conn: *connectdata) ?*ftp_conn {
    return doh_hostip_easy.connMetaGetTyped(ftp_conn, conn, CURL_META_FTP_CONN);
}

inline fn getLcCtx(writer: *Curl_cwriter) *ftp_cw_lc_ctx {
    return if (writer.ctx) |c| fromOpaque(ftp_cw_lc_ctx, c) else fromOpaque(ftp_cw_lc_ctx, writer);
}

fn freedirs(ftpc: *ftp_conn) void {
    if (ftpc.dirs) |d| {
        mem.freeTyped(d);
        ftpc.dirs = null;
    }
    ftpc.dirdepth = 0;
    if (ftpc.rawpath) |rp| {
        mem.free(rp);
        ftpc.rawpath = null;
    }
    ftpc.file = null;
}

fn numof_slashes(str: [*:0]const u8) usize {
    var count: usize = 0;
    var i: usize = 0;
    while (str[i] != 0) : (i += 1) {
        if (str[i] == '/')
            count += 1;
    }
    return count;
}

fn ftp_parse_url_path(data: *Curl_easy, ftpc: *ftp_conn, ftp: *FTP) CURLcode {
    var pathLen: usize = 0;

    ftpc.ctl_valid = false;
    ftpc.cwdfail = false;

    if (ftpc.rawpath != null)
        freedirs(ftpc);

    const path_in = ftp.path orelse "";
    const result = Curl_urldecode(path_in, 0, &ftpc.rawpath, &pathLen, REJECT_CTRL);
    if (result != CURLE_OK) {
        failf(data, "path contains control characters", .{});
        return result;
    }

    const rawPath = ftpc.rawpath orelse return CURLE_OUT_OF_MEMORY;
    var ok = false;
    defer if (!ok) freedirs(ftpc);
    var fileName: ?[*:0]u8 = null;
    const filemethod = Curl_ftp_acc_get_ftp_filemethod(data);

    switch (filemethod) {
        FTPFILE_NOCWD => {
            if ((pathLen > 0) and (rawPath[pathLen - 1] != '/'))
                fileName = rawPath;
        },
        FTPFILE_SINGLECWD => {
            const last_slash_idx = if (pathLen > 0)
                std.mem.lastIndexOfScalar(u8, rawPath[0..pathLen], '/')
            else
                null;
            if (last_slash_idx) |slash_idx| {
                var dirlen: usize = slash_idx;
                if (dirlen == 0)
                    dirlen += 1;

                ftpc.dirs = mem.callocMany(pathcomp, 1);
                if (ftpc.dirs == null) {
                    return CURLE_OUT_OF_MEMORY;
                }
                ftpc.dirs.?[0].start = 0;
                ftpc.dirs.?[0].len = @intCast(dirlen);
                ftpc.dirdepth = 1;
                fileName = rawPath + slash_idx + 1;
            } else {
                fileName = rawPath;
            }
        },
        else => {
            var curPos: usize = 0;
            const dirAlloc = numof_slashes(rawPath);
            if (dirAlloc > 0) {
                ftpc.dirs = mem.callocMany(pathcomp, dirAlloc);
                if (ftpc.dirs == null) {
                    return CURLE_OUT_OF_MEMORY;
                }

                var i: usize = 0;
                while (std.mem.indexOfScalarPos(u8, rawPath[0..pathLen], curPos, '/')) |slash_idx| {
                    var dirLen: usize = slash_idx - curPos;
                    if (dirLen == 0 and ftpc.dirdepth == 0)
                        dirLen += 1;

                    if (dirLen != 0) {
                        if (dirLen >= @as(usize, @intCast(std.math.maxInt(c_int))) or
                            curPos >= @as(usize, @intCast(std.math.maxInt(c_int))) or
                            ftpc.dirdepth >= 1000)
                        {
                            return CURLE_URL_MALFORMAT;
                        }
                        ftpc.dirs.?[i].start = @intCast(curPos);
                        ftpc.dirs.?[i].len = @intCast(dirLen);
                        ftpc.dirdepth += 1;
                        i += 1;
                    }
                    curPos = slash_idx + 1;
                }
            }
            fileName = rawPath + curPos;
        },
    }

    if (fileName) |fn_ptr| {
        if (fn_ptr[0] != 0) {
            ftpc.file = fn_ptr;
        } else {
            ftpc.file = null;
        }
    } else {
        ftpc.file = null;
    }

    if (Curl_ftp_acc_get_upload(data) and ftpc.file == null and ftp.transfer == PPTRANSFER_BODY) {
        failf(data, "Uploading to a URL without a filename", .{});
        return CURLE_URL_MALFORMAT;
    }

    ftpc.cwddone = false;

    if (filemethod == FTPFILE_NOCWD and rawPath[0] == '/') {
        ftpc.cwddone = true;
    } else {
        const conn = Curl_ftp_acc_get_conn(data).?;
        const oldPath_opt: ?[*:0]const u8 = if (Curl_ftp_acc_conn_get_reuse(conn))
            ftpc.prevpath
        else
            "";
        if (oldPath_opt) |oldPath| {
            var n: usize = pathLen;
            if (filemethod == FTPFILE_NOCWD) {
                n = 0;
            } else {
                const flen: usize = if (ftpc.file) |f| std.mem.len(f) else 0;
                n -= flen;
            }

            if (std.mem.len(oldPath) == n and std.mem.eql(u8, rawPath[0..n], oldPath[0..n])) {
                infof(data, "Request has same path as previous transfer", .{});
                ftpc.cwddone = true;
            }
        }
    }

    ok = true;
    return CURLE_OK;
}

fn ftp_need_type(ftpc: *const ftp_conn, ascii_wanted: bool) bool {
    const wanted: u8 = if (ascii_wanted) 'A' else 'I';
    return ftpc.transfertype != wanted;
}

fn close_secondarysocket(data: *Curl_easy, ftpc: *ftp_conn) void {
    trcFtp(data, "[%s] closing DATA connection", .{ftp_cstate(ftpc)});
    if (Curl_ftp_acc_get_conn(data)) |conn| {
        Curl_conn_cf_discard_all(data, conn, SECONDARYSOCKET);
    }
}

// ============================================================================
// FTP Line-End Content Writer (CURL_PREFER_LF_LINEENDS)
// ============================================================================

fn ftp_cw_lc_write(
    data: *Curl_easy,
    writer: *Curl_cwriter,
    wtype: c_int,
    buf_in: [*]const u8,
    blen_in: usize,
) callconv(.c) CURLcode {
    const nl = [_]u8{'\n'};
    const ctx = getLcCtx(writer);
    const conn = Curl_ftp_acc_get_conn(data) orelse return CURLE_FAILED_INIT;
    const ftpc = getFtpConn(conn) orelse return CURLE_FAILED_INIT;

    var buf = buf_in;
    var blen = blen_in;

    if ((wtype & CLIENTWRITE_BODY) == 0 or ftpc.transfertype != 'A')
        return Curl_cwriter_write(data, writer.next, wtype, buf, blen);

    const chunk_type = wtype & ~CLIENTWRITE_EOS;
    while (blen > 0) {
        var result: CURLcode = CURLE_OK;

        if (ctx.newline_pending) {
            if (buf[0] != '\n') {
                result = Curl_cwriter_write(data, writer.next, chunk_type, &nl, 1);
                if (result != CURLE_OK)
                    return result;
            }
            ctx.newline_pending = false;
        }

        const idx_opt = std.mem.indexOfScalar(u8, buf[0..blen], '\r');
        const chunk_len = idx_opt orelse break;

        if (chunk_len > 0) {
            result = Curl_cwriter_write(data, writer.next, chunk_type, buf, chunk_len);
            if (result != CURLE_OK)
                return result;
        }

        buf += chunk_len + 1;
        blen = blen - chunk_len - 1;
        ctx.newline_pending = true;
    }

    if (blen > 0) {
        std.debug.assert(!ctx.newline_pending);
        return Curl_cwriter_write(data, writer.next, wtype, buf, blen);
    } else if ((wtype & CLIENTWRITE_EOS) != 0) {
        if (ctx.newline_pending) {
            ctx.newline_pending = false;
            return Curl_cwriter_write(data, writer.next, wtype, &nl, 1);
        }
        return Curl_cwriter_write(data, writer.next, wtype, buf, 0);
    }
    return CURLE_OK;
}

const ftp_cw_lc = Curl_cwtype{
    .name = "ftp-lineconv",
    .alias = null,
    .flags = 0,
    .do_init = Curl_cwriter_def_init,
    .do_write = ftp_cw_lc_write,
    .do_flush = Curl_cwriter_def_flush,
    .do_close = Curl_cwriter_def_close,
    .cwriter_size = @sizeOf(ftp_cw_lc_ctx),
};

// ============================================================================
// FTP Control Response Helpers & Data Initiation
// ============================================================================

inline fn isLastLine(line: [*:0]const u8) bool {
    return isDigit(line[0]) and
        isDigit(line[1]) and
        isDigit(line[2]) and
        (line[3] == ' ');
}

fn ftp_check_ctrl_on_data_wait(data: *Curl_easy, ftpc: *ftp_conn) CURLcode {
    const conn = Curl_ftp_acc_get_conn(data) orelse return CURLE_FAILED_INIT;
    const ctrl_sock = Curl_ftp_acc_conn_get_sock(conn, FIRSTSOCKET);
    const pp = &ftpc.pp;
    var nread: usize = 0;
    var ftpcode: c_int = 0;
    var response: bool = false;

    if (containers.curlx_dyn_len(&pp.recvbuf) != 0) {
        const l = containers.curlx_dyn_ptr(&pp.recvbuf).?;
        if (!isDigit(l[0]) or (l[0] > '3')) {
            infof(data, "There is negative response in cache while serv connect", .{});
            _ = getftpresponse(data, &nread, &ftpcode);
            return CURLE_FTP_ACCEPT_FAILED;
        }
    }

    if (pp.overflow != 0) {
        response = true;
    } else {
        const socketstate = Curl_socket_check(ctrl_sock, CURL_SOCKET_BAD, CURL_SOCKET_BAD, 0);
        switch (socketstate) {
            -1 => {
                failf(data, "Error while waiting for server connect", .{});
                return CURLE_FTP_ACCEPT_FAILED;
            },
            0 => {},
            else => {
                if ((socketstate & CURL_CSELECT_IN) != 0)
                    response = true;
            },
        }
    }

    if (response) {
        infof(data, "Ctrl conn has data while waiting for data conn", .{});
        if (pp.overflow > 3) {
            const r_base = containers.curlx_dyn_ptr(&pp.recvbuf).?;
            var len = containers.curlx_dyn_len(&pp.recvbuf);

            std.debug.assert((pp.overflow + pp.nfinal) <= len);
            const r_ptr: [*:0]const u8 = r_base + pp.nfinal;
            len -= pp.nfinal;

            if ((len > 3) and isLastLine(r_ptr)) {
                var status: curl_off_t = 0;
                var line_p: ?[*:0]const u8 = r_ptr;
                if (curlx_str_number(&line_p, &status, 999) == 0 and status == 226) {
                    infof(data, "Got 226 before data activity", .{});
                    return CURLE_OK;
                }
            }
        }

        _ = getftpresponse(data, &nread, &ftpcode);
        infof(data, "FTP code: %03d", .{ftpcode});

        if (@divTrunc(ftpcode, 100) > 3)
            return CURLE_FTP_ACCEPT_FAILED;

        return CURLE_WEIRD_SERVER_REPLY;
    }

    return CURLE_OK;
}

fn ftp_initiate_transfer(data: *Curl_easy, ftpc: *ftp_conn) CURLcode {
    var result: CURLcode = CURLE_OK;
    var connected: bool = false;

    trcFtp(data, "ftp_initiate_transfer()", .{});
    result = Curl_conn_connect(data, SECONDARYSOCKET, true, &connected);
    if (result != CURLE_OK or !connected)
        return result;

    if (Curl_ftp_acc_get_upload(data)) {
        Curl_pgrsSetUploadSize(data, Curl_ftp_acc_get_infilesize(data));
        Curl_ftp_acc_xfer_setup_send(data);
        Curl_xfer_set_shutdown(data, true, true);
    } else {
        Curl_ftp_acc_xfer_setup_recv(data, Curl_ftp_acc_get_req_size(data));
        Curl_xfer_set_shutdown(data, true, false);
    }

    ftpc.pp.setPendingResp(true);
    ftp_state(data, ftpc, .FTP_STOP);

    return CURLE_OK;
}

fn ftp_endofresp(
    data: ?*Curl_easy,
    conn: ?*connectdata,
    line_in: [*:0]const u8,
    len: usize,
    code: *c_int,
) callconv(.c) bool {
    _ = data;
    _ = conn;
    var status: curl_off_t = 0;
    var line: ?[*:0]const u8 = line_in;

    if (len > 3 and isLastLine(line_in) and curlx_str_number(&line, &status, 999) == 0) {
        code.* = @intCast(status);
        return true;
    }

    return false;
}

fn ftp_readresp(
    data: *Curl_easy,
    ftpc: *ftp_conn,
    sockindex: i8,
    pp: *pingpong,
    ftpcode: ?*c_int,
    size: *usize,
) CURLcode {
    var code: c_int = 0;
    const result = Curl_ftp_acc_pp_readresp(data, sockindex, pp, &code, size);

    if (!ftpc.shutdown)
        Curl_ftp_acc_set_info_httpcode(data, code);

    if (ftpcode) |fc|
        fc.* = code;

    if (code == 421) {
        infof(data, "We got a 421 - timeout", .{});
        ftp_state(data, ftpc, .FTP_STOP);
        return CURLE_OPERATION_TIMEDOUT;
    }

    return result;
}

fn getftpresponse(
    data: *Curl_easy,
    nreadp: *usize,
    ftpcodep: *c_int,
) CURLcode {
    const conn = Curl_ftp_acc_get_conn(data) orelse return CURLE_FAILED_INIT;
    const sockfd = Curl_ftp_acc_conn_get_sock(conn, FIRSTSOCKET);
    var result: CURLcode = CURLE_OK;
    const ftpc = getFtpConn(conn) orelse return CURLE_FAILED_INIT;
    const pp = &ftpc.pp;
    var cache_skip: usize = 0;

    nreadp.* = 0;
    ftpcodep.* = 0;

    while (ftpcodep.* == 0 and result == CURLE_OK) {
        const timeout = Curl_ftp_acc_pp_state_timeleft_ms(data, pp);
        var interval_ms: timediff_t = 0;

        if (timeout <= 0) {
            failf(data, "FTP response timeout", .{});
            return CURLE_OPERATION_TIMEDOUT;
        }

        interval_ms = 1000;
        if (timeout < interval_ms)
            interval_ms = timeout;

        if (containers.curlx_dyn_len(&pp.recvbuf) != 0 and (cache_skip < 2)) {
            // There is a buffer to read; check if it parses before polling socket
        } else if (!Curl_conn_data_pending(data, FIRSTSOCKET)) {
            const wsock: curl_socket_t = if (Curl_pp_needs_flush(data, pp))
                sockfd
            else
                CURL_SOCKET_BAD;
            const ev = Curl_socket_check(sockfd, CURL_SOCKET_BAD, wsock, interval_ms);
            if (ev < 0) {
                failf(data, "FTP response aborted due to select/poll error: %d", .{Curl_ftp_acc_get_sockerrno()});
                return CURLE_RECV_ERROR;
            } else if (ev == 0) {
                result = Curl_pgrsUpdate(data);
                if (result != CURLE_OK)
                    return result;
                continue;
            }
        }

        if (Curl_pp_needs_flush(data, pp)) {
            result = Curl_pp_flushsend(data, pp);
            if (result != CURLE_OK)
                break;
        }

        var nread: usize = 0;
        result = ftp_readresp(data, ftpc, FIRSTSOCKET, pp, ftpcodep, &nread);
        if (result != CURLE_OK)
            break;

        if (nread == 0 and containers.curlx_dyn_len(&pp.recvbuf) != 0)
            cache_skip += 1
        else
            cache_skip = 0;

        nreadp.* += nread;
    }

    pp.setPendingResp(false);

    return result;
}

// ============================================================================
// FTP Command Senders (state initiators)
// ============================================================================

fn ftp_state_pwd(data: *Curl_easy, ftpc: *ftp_conn) CURLcode {
    if (Curl_ftp_acc_pwd_stop_debug(data))
        return CURLE_OK;
    const result = ppSendf(data, &ftpc.pp, "%s", .{"PWD"});
    if (result == CURLE_OK)
        ftp_state(data, ftpc, .FTP_PWD);
    return result;
}

fn ftp_send_command(data: *Curl_easy, ftpc: *ftp_conn, command: [*:0]const u8, arg: [*:0]const u8) CURLcode {
    return ppSendf(data, &ftpc.pp, "%s %s", .{ command, arg });
}

fn ftp_state_mdtm(data: *Curl_easy, ftpc: *ftp_conn, ftp: *FTP) CURLcode {
    var result: CURLcode = CURLE_OK;

    if ((Curl_ftp_acc_get_get_filetime(data) or Curl_ftp_acc_get_timecondition(data) != CURL_TIMECOND_NONE) and
        ftpc.file != null)
    {
        result = ftp_send_command(data, ftpc, "MDTM", ftpc.file.?);
        if (result == CURLE_OK)
            ftp_state(data, ftpc, .FTP_MDTM);
    } else {
        result = ftp_state_type(data, ftpc, ftp);
    }

    return result;
}

fn ftp_state_ul_setup(
    data: *Curl_easy,
    ftpc: *ftp_conn,
    ftp: *FTP,
    sizechecked: bool,
) CURLcode {
    var result: CURLcode = CURLE_OK;
    var append = Curl_ftp_acc_get_remote_append(data);
    const resume_from = Curl_ftp_acc_get_resume_from(data);

    if ((resume_from != 0 and !sizechecked) or (resume_from > 0 and sizechecked)) {
        var seekerr: c_int = CURL_SEEKFUNC_OK;

        if (resume_from < 0) {
            result = ftp_send_command(data, ftpc, "SIZE", ftpc.file.?);
            if (result == CURLE_OK)
                ftp_state(data, ftpc, .FTP_STOR_SIZE);
            return result;
        }

        append = true;

        if (Curl_ftp_acc_has_seek_func(data)) {
            seekerr = Curl_ftp_acc_call_seek_func(data, resume_from);
        }

        if (seekerr != CURL_SEEKFUNC_OK) {
            var passed: curl_off_t = 0;
            if (seekerr != 2) { // CURL_SEEKFUNC_CANTSEEK
                failf(data, "Could not seek stream", .{});
                return CURLE_FTP_COULDNT_USE_REST;
            }
            var scratch: [4 * 1024]u8 = undefined;
            while (passed < resume_from) {
                const readthisamountnow: usize = if ((resume_from - passed) > @as(curl_off_t, @intCast(scratch.len)))
                    scratch.len
                else
                    @intCast(resume_from - passed);

                const actuallyread = Curl_ftp_acc_call_fread_func(data, &scratch, readthisamountnow);
                passed += @intCast(actuallyread);
                if ((actuallyread == 0) or (actuallyread > readthisamountnow)) {
                    failf(data, "Failed to read data", .{});
                    return CURLE_FTP_COULDNT_USE_REST;
                }
            }
        }

        const infilesize = Curl_ftp_acc_get_infilesize(data);
        if (infilesize > 0) {
            const new_infilesize = infilesize - resume_from;
            Curl_ftp_acc_set_infilesize(data, new_infilesize);

            if (new_infilesize <= 0) {
                infof(data, "File already completely uploaded", .{});
                Curl_xfer_setup_nop(data);
                ftp.transfer = PPTRANSFER_NONE;
                ftp_state(data, ftpc, .FTP_STOP);
                return CURLE_OK;
            }
        }
    }

    const cmd: [*:0]const u8 = if (append) "APPE" else "STOR";
    result = ftp_send_command(data, ftpc, cmd, ftpc.file.?);
    if (result == CURLE_OK)
        ftp_state(data, ftpc, .FTP_STOR);

    return result;
}

// ============================================================================
// Active FTP (PORT / EPRT)
// ============================================================================

fn ftp_port_parse_string(
    data: *Curl_easy,
    conn: *connectdata,
    string_ftpport: ?[*:0]const u8,
    port_minp: *u16,
    port_maxp: *u16,
    hostp: *?[*:0]const u8,
    hbuf: *[NI_MAXHOST:0]u8,
) CURLcode {
    var ip_end: ?[*:0]const u8 = null;
    var addr: ?[*]const u8 = null;
    var addrlen: usize = 0;
    var port_min: u16 = 0;
    var port_max: u16 = 0;
    var ipstr: [50:0]u8 = undefined;

    hostp.* = null;
    port_minp.* = 0;
    port_maxp.* = 0;

    const str = string_ftpport orelse return CURLE_OK;
    const str_len = std.mem.len(str);
    if (str_len <= 1)
        return CURLE_OK;

    if (str[0] == '[') {
        const ip_start = str + 1;
        if (std.mem.indexOfScalar(u8, ip_start[0 .. str_len - 1], ']')) |idx| {
            addrlen = idx;
            addr = ip_start;
            ip_end = ip_start + idx;
        }
    } else if (str[0] == ':') {
        ip_end = str;
    } else {
        addr = str;
        if (std.mem.indexOfScalar(u8, str[0..str_len], ':')) |idx| {
            addrlen = idx;
            ip_end = str + idx;
            if (Curl_ftp_acc_is_ipv6_literal(str)) {
                addrlen = str_len;
                ip_end = null;
            }
        } else {
            addrlen = str_len;
        }
    }

    if (ip_end) |end_str| {
        const end_len = std.mem.len(end_str);
        if (std.mem.indexOfScalar(u8, end_str[0..end_len], ':')) |colon_idx| {
            var portp: ?[*:0]const u8 = end_str + colon_idx + 1;
            var start: curl_off_t = 0;
            var end: curl_off_t = 0;
            if (curlx_str_number(&portp, &start, 0xffff) == 0) {
                port_min = @intCast(start);
                if (curlx_str_single(&portp, '-') == 0 and
                    curlx_str_number(&portp, &end, 0xffff) == 0)
                {
                    port_max = @intCast(end);
                } else {
                    port_max = port_min;
                }
            }
        }
    }

    if (port_min > port_max) {
        port_min = 0;
        port_max = 0;
    }

    if (addrlen > 0) {
        const addr_ptr = addr orelse return CURLE_FTP_PORT_FAILED;
        if (addrlen >= ipstr.len or addrlen >= hbuf.len)
            return CURLE_FTP_PORT_FAILED;
        @memcpy(ipstr[0..addrlen], addr_ptr[0..addrlen]);
        ipstr[addrlen] = 0;

        const rc = Curl_ftp_acc_if2ip(data, conn, &ipstr, hbuf, hbuf.len);
        if (rc < 0)
            return CURLE_FTP_PORT_FAILED;
        switch (rc) {
            IF2IP_NOT_FOUND => {
                @memcpy(hbuf[0..addrlen], addr_ptr[0..addrlen]);
                hbuf[addrlen] = 0;
                hostp.* = hbuf;
            },
            IF2IP_AF_NOT_SUPPORTED => return CURLE_FTP_PORT_FAILED,
            IF2IP_FOUND => {
                hostp.* = hbuf;
            },
            else => {},
        }
    }

    port_minp.* = port_min;
    port_maxp.* = port_max;
    return CURLE_OK;
}

fn ftp_port_send_command(
    data: *Curl_easy,
    ftpc: *ftp_conn,
    conn: *connectdata,
    fcmd_in: ftpport,
    ss_ptr: *const anyopaque,
    ai: ?*const Curl_addrinfo,
) CURLcode {
    const mode = [_][*:0]const u8{ "EPRT", "PORT" };
    var myhost: [256:0]u8 = @splat(0);
    var is_ipv4: bool = false;
    var is_ipv6: bool = false;
    var port: u16 = 0;
    var fcmd = fcmd_in;
    var result: CURLcode = CURLE_OK;

    Curl_ftp_acc_port_extract_sa(ss_ptr, ai, &myhost, myhost.len, &is_ipv4, &is_ipv6, &port);

    if (!Curl_ftp_acc_conn_get_ftp_use_eprt(conn) and Curl_ftp_acc_conn_get_ipv6(conn)) {
        Curl_ftp_acc_conn_set_ftp_use_eprt(conn, true);
    }

    while (fcmd != .DONE) : (fcmd = @fromBackingInt(@intCast(@backingInt(fcmd) + 1))) {
        if (!Curl_ftp_acc_conn_get_ftp_use_eprt(conn) and fcmd == .EPRT)
            continue;

        if ((fcmd == .PORT) and !is_ipv4)
            continue;

        if (!is_ipv4 and !is_ipv6)
            continue;

        if (fcmd == .EPRT) {
            const af_num: c_int = if (is_ipv4) 1 else 2;
            const myhost_c: [*:0]const u8 = &myhost;
            result = ppSendf(
                data,
                &ftpc.pp,
                "%s |%d|%s|%hu|",
                .{ mode[@backingInt(fcmd)], af_num, myhost_c, @as(c_uint, port) },
            );
            if (result != CURLE_OK) {
                failf(data, "Failure sending EPRT command: %s", .{
                    curl_easy_strerror(result),
                });
                return result;
            }
            break;
        }
        if (fcmd == .PORT) {
            var target: [256 + 32:0]u8 = undefined;
            var source_idx: usize = 0;
            var dest_idx: usize = 0;

            while (myhost[source_idx] != 0) : (source_idx += 1) {
                if (myhost[source_idx] == '.')
                    target[dest_idx] = ','
                else
                    target[dest_idx] = myhost[source_idx];
                dest_idx += 1;
            }
            target[dest_idx] = 0;
            _ = curl_msnprintf(
                target[dest_idx..].ptr,
                20,
                ",%d,%d",
                @as(c_int, port >> 8),
                @as(c_int, port & 0xff),
            );

            result = ftp_send_command(data, ftpc, mode[@backingInt(fcmd)], &target);
            if (result != CURLE_OK) {
                failf(data, "Failure sending PORT command: %s", .{
                    curl_easy_strerror(result),
                });
                return result;
            }
            break;
        }
    }

    ftpc.count1 = @intCast(@backingInt(fcmd));
    ftp_state(data, ftpc, .FTP_PORT);
    return CURLE_OK;
}

fn ftp_state_use_port(
    data: *Curl_easy,
    ftpc: *ftp_conn,
    fcmd: ftpport,
) CURLcode {
    const conn = Curl_ftp_acc_get_conn(data) orelse return CURLE_FAILED_INIT;
    var portsock: curl_socket_t = CURL_SOCKET_BAD;

    var hbuf: [NI_MAXHOST:0]u8 = @splat(0);
    var res: ?*const Curl_addrinfo = null;
    var ai: ?*const Curl_addrinfo = null;
    var dns_entry: ?*Curl_dns_entry = null;
    var port_min: u16 = 0;
    var port_max: u16 = 0;
    var host: ?[*:0]const u8 = null;
    const string_ftpport = Curl_ftp_acc_get_str_ftpport(data);
    var ss_buf: [256]u8 align(8) = @splat(0);
    var sslen: c_uint = 0;
    var non_local: bool = true;
    var result: CURLcode = CURLE_FTP_PORT_FAILED;

    result = ftp_port_parse_string(data, conn, string_ftpport, &port_min, &port_max, &host, &hbuf);
    if (result == CURLE_OK and host == null) {
        result = Curl_ftp_acc_port_default_host(data, conn, &ss_buf, &sslen, &hbuf, hbuf.len);
        if (result == CURLE_OK) {
            host = &hbuf;
            non_local = false;
        }
    }

    if (result == CURLE_OK)
        result = Curl_ftp_acc_port_resolve_host(data, conn, host.?, &dns_entry, &res);

    if (result == CURLE_OK)
        result = Curl_ftp_acc_port_open_socket(data, conn, res, &ai, &portsock);

    if (result == CURLE_OK) {
        trcFtp(data, "[%s] ftp_state_use_port(), opened socket", .{ftp_cstate(ftpc)});
        var bound_port: u16 = 0;
        result = Curl_ftp_acc_port_bind_socket(
            data,
            conn,
            portsock,
            ai.?,
            &ss_buf,
            &sslen,
            port_min,
            port_max,
            non_local,
            &bound_port,
        );
    }

    if (result == CURLE_OK)
        result = Curl_ftp_acc_port_listen(data, portsock);

    if (result == CURLE_OK)
        result = ftp_port_send_command(data, ftpc, conn, fcmd, &ss_buf, ai);

    if (result == CURLE_OK)
        result = Curl_conn_tcp_listen_set(data, conn, SECONDARYSOCKET, &portsock);

    if (result == CURLE_OK)
        portsock = CURL_SOCKET_BAD;

    if (dns_entry != null)
        Curl_dns_entry_unlink(data, &dns_entry);

    if (result != CURLE_OK) {
        ftp_state(data, ftpc, .FTP_STOP);
    } else {
        if (Curl_ftp_acc_conn_get_ftp_use_data_ssl(conn) and
            Curl_ftp_acc_get_ftp_use_port(data) and
            !Curl_conn_is_ssl(conn, SECONDARYSOCKET))
        {
            result = Curl_ftp_acc_ssl_cfilter_add(data, conn, SECONDARYSOCKET);
        }
        Curl_ftp_acc_conn_set_do_more(conn, false);
        const accept_to = Curl_ftp_acc_get_accepttimeout(data);
        Curl_expire(
            data,
            if (accept_to > 0) accept_to else DEFAULT_ACCEPT_TIMEOUT,
            EXPIRE_FTP_ACCEPT,
        );
    }
    if (portsock != CURL_SOCKET_BAD)
        _ = Curl_socket_close(data, conn, portsock);
    return result;
}

// ============================================================================
// Passive FTP (PASV / EPSV) & Transfer Preparation
// ============================================================================

fn ftp_state_use_pasv(
    data: *Curl_easy,
    ftpc: *ftp_conn,
    conn: *connectdata,
) CURLcode {
    var result: CURLcode = CURLE_OK;
    const mode = [_][*:0]const u8{ "EPSV", "PASV" };

    if (!Curl_ftp_acc_conn_get_ftp_use_epsv(conn) and Curl_ftp_acc_conn_get_ipv6(conn)) {
        Curl_ftp_acc_conn_set_ftp_use_epsv(conn, true);
    }

    const modeoff: usize = if (Curl_ftp_acc_conn_get_ftp_use_epsv(conn)) 0 else 1;

    result = ppSendf(data, &ftpc.pp, "%s", .{mode[modeoff]});
    if (result == CURLE_OK) {
        ftpc.count1 = @intCast(modeoff);
        ftp_state(data, ftpc, .FTP_PASV);
        infof(data, "Connect data stream passively", .{});
    }
    return result;
}

fn ftp_state_prepare_transfer(
    data: *Curl_easy,
    ftpc: *ftp_conn,
    ftp: *FTP,
) CURLcode {
    var result: CURLcode = CURLE_OK;
    const conn = Curl_ftp_acc_get_conn(data) orelse return CURLE_FAILED_INIT;

    if (ftp.transfer != PPTRANSFER_BODY) {
        ftp_state(data, ftpc, .FTP_RETR_PREQUOTE);
        result = ftp_state_quote(data, ftpc, ftp, true, .FTP_RETR_PREQUOTE);
    } else if (Curl_ftp_acc_get_ftp_use_port(data)) {
        result = ftp_state_use_port(data, ftpc, .EPRT);
    } else {
        if (Curl_ftp_acc_get_ftp_use_pret(data)) {
            const custom = Curl_ftp_acc_get_str_customrequest(data);
            if (ftpc.file == null) {
                result = ppSendf(
                    data,
                    &ftpc.pp,
                    "PRET %s",
                    .{custom orelse (if (Curl_ftp_acc_get_list_only(data)) @as([*:0]const u8, "NLST") else @as([*:0]const u8, "LIST"))},
                );
            } else if (Curl_ftp_acc_get_upload(data)) {
                result = ppSendf(data, &ftpc.pp, "PRET STOR %s", .{ftpc.file.?});
            } else {
                result = ppSendf(data, &ftpc.pp, "PRET RETR %s", .{ftpc.file.?});
            }
            if (result == CURLE_OK)
                ftp_state(data, ftpc, .FTP_PRET);
        } else {
            result = ftp_state_use_pasv(data, ftpc, conn);
        }
    }
    return result;
}

fn ftp_state_rest(
    data: *Curl_easy,
    ftpc: *ftp_conn,
    ftp: *FTP,
) CURLcode {
    var result: CURLcode = CURLE_OK;

    if ((ftp.transfer != PPTRANSFER_BODY) and ftpc.file != null) {
        result = ppSendf(data, &ftpc.pp, "REST %d", .{@as(c_int, 0)});
        if (result == CURLE_OK)
            ftp_state(data, ftpc, .FTP_REST);
    } else {
        result = ftp_state_prepare_transfer(data, ftpc, ftp);
    }

    return result;
}

fn ftp_state_size(
    data: *Curl_easy,
    ftpc: *ftp_conn,
    ftp: *FTP,
) CURLcode {
    var result: CURLcode = CURLE_OK;

    if ((ftp.transfer == PPTRANSFER_INFO) and ftpc.file != null) {
        result = ftp_send_command(data, ftpc, "SIZE", ftpc.file.?);
        if (result == CURLE_OK)
            ftp_state(data, ftpc, .FTP_SIZE);
    } else {
        result = ftp_state_rest(data, ftpc, ftp);
    }

    return result;
}

fn ftp_state_list(
    data: *Curl_easy,
    ftpc: *ftp_conn,
    ftp: *FTP,
) CURLcode {
    var result: CURLcode = CURLE_OK;
    var lstArg: ?[*:0]const u8 = null;
    var lstArglen: c_int = 0;

    if ((Curl_ftp_acc_get_ftp_filemethod(data) == FTPFILE_NOCWD) and ftp.path != null) {
        if (ftpc.rawpath) |rawPath| {
            const rp_len = std.mem.len(rawPath);
            if (std.mem.lastIndexOfScalar(u8, rawPath[0..rp_len], '/')) |idx| {
                var n = idx;
                if (n == 0)
                    n += 1;
                lstArg = rawPath;
                lstArglen = @intCast(n);
            }
        }
    }

    const custom = Curl_ftp_acc_get_str_customrequest(data);
    const cmd_name: [*:0]const u8 = custom orelse
        (if (Curl_ftp_acc_get_list_only(data)) "NLST" else "LIST");
    const sep: [*:0]const u8 = if (lstArg != null) " " else "";
    const arg_str: [*:0]const u8 = if (lstArg) |la| la else "";

    const cmd = curl_maprintf("%s%s%.*s", cmd_name, sep, lstArglen, arg_str);
    if (cmd == null)
        return CURLE_OUT_OF_MEMORY;

    result = ppSendf(data, &ftpc.pp, "%s", .{cmd.?});
    mem.free(cmd.?);

    if (result == CURLE_OK)
        ftp_state(data, ftpc, .FTP_LIST);

    return result;
}

fn ftp_state_list_prequote(
    data: *Curl_easy,
    ftpc: *ftp_conn,
    ftp: *FTP,
) CURLcode {
    return ftp_state_quote(data, ftpc, ftp, true, .FTP_LIST_PREQUOTE);
}

fn ftp_state_retr_prequote(
    data: *Curl_easy,
    ftpc: *ftp_conn,
    ftp: *FTP,
) CURLcode {
    return ftp_state_quote(data, ftpc, ftp, true, .FTP_RETR_PREQUOTE);
}

fn ftp_state_stor_prequote(
    data: *Curl_easy,
    ftpc: *ftp_conn,
    ftp: *FTP,
) CURLcode {
    return ftp_state_quote(data, ftpc, ftp, true, .FTP_STOR_PREQUOTE);
}

fn ftp_state_type(
    data: *Curl_easy,
    ftpc: *ftp_conn,
    ftp: *FTP,
) CURLcode {
    var result: CURLcode = CURLE_OK;

    if (Curl_ftp_acc_get_no_body(data) and
        ftpc.file != null and
        ftp_need_type(ftpc, Curl_ftp_acc_get_prefer_ascii(data)))
    {
        ftp.transfer = PPTRANSFER_INFO;
        result = ftp_nb_type(data, ftpc, ftp, Curl_ftp_acc_get_prefer_ascii(data), .FTP_TYPE);
        if (result != CURLE_OK)
            return result;
    } else {
        result = ftp_state_size(data, ftpc, ftp);
    }

    return result;
}

fn ftp_state_cwd(
    data: *Curl_easy,
    ftpc: *ftp_conn,
    ftp: *FTP,
) CURLcode {
    var result: CURLcode = CURLE_OK;

    if (ftpc.cwddone) {
        result = ftp_state_mdtm(data, ftpc, ftp);
    } else {
        const filemethod = Curl_ftp_acc_get_ftp_filemethod(data);
        std.debug.assert((filemethod != FTPFILE_NOCWD) or !(ftpc.dirdepth != 0 and ftpc.rawpath.?[0] == '/'));

        ftpc.count2 = 0;

        const conn = Curl_ftp_acc_get_conn(data).?;
        if (Curl_ftp_acc_conn_get_reuse(conn) and ftpc.entrypath != null and
            !(ftpc.dirdepth != 0 and ftpc.rawpath.?[0] == '/'))
        {
            ftpc.cwdcount = 0;
            result = ftp_send_command(data, ftpc, "CWD", ftpc.entrypath.?);
            if (result == CURLE_OK)
                ftp_state(data, ftpc, .FTP_CWD);
        } else {
            if (ftpc.dirdepth != 0) {
                ftpc.cwdcount = 1;
                result = ppSendf(
                    data,
                    &ftpc.pp,
                    "CWD %.*s",
                    .{ ftpc.dirs.?[0].len, ftpc.rawpath.? + @as(usize, @intCast(ftpc.dirs.?[0].start)) },
                );
                if (result == CURLE_OK)
                    ftp_state(data, ftpc, .FTP_CWD);
            } else {
                result = ftp_state_mdtm(data, ftpc, ftp);
            }
        }
    }
    return result;
}

fn ftp_has_ctrl(str_opt: ?[*:0]const u8) bool {
    const s = str_opt orelse return false;
    var i: usize = 0;
    while (s[i] != 0) : (i += 1) {
        if (s[i] < 0x20)
            return true;
    }
    return false;
}

fn ftp_state_user(
    data: *Curl_easy,
    ftpc: *ftp_conn,
    conn: *connectdata,
) CURLcode {
    const user = Curl_ftp_acc_conn_get_user(conn);
    const result = ftp_send_command(data, ftpc, "USER", user);
    if (result == CURLE_OK) {
        ftpc.ftp_trying_alternative = false;
        ftp_state(data, ftpc, .FTP_USER);
    }
    return result;
}

// ============================================================================
// ftp_do_more & ftp_perform
// ============================================================================

fn ftp_do_more(data: *Curl_easy, more: *c_int) callconv(.c) CURLcode {
    const conn = Curl_ftp_acc_get_conn(data) orelse return CURLE_FAILED_INIT;
    const ftpc = getFtpConn(conn) orelse return CURLE_FAILED_INIT;
    const ftp = getFtpEasy(data) orelse return CURLE_FAILED_INIT;
    var result: CURLcode = CURLE_OK;
    var connected: bool = false;
    var complete: bool = false;

    more.* = DOMORE_INCOMPLETE;

    if (Curl_ftp_acc_conn_has_cfilter(conn, SECONDARYSOCKET)) {
        const is_eptr = Curl_conn_is_tcp_listen(data, SECONDARYSOCKET);
        result = Curl_conn_connect(data, SECONDARYSOCKET, false, &connected);
        if (result == CURLE_OUT_OF_MEMORY)
            return result;
        if (result != CURLE_OK or (!connected and !is_eptr and
            !Curl_conn_is_ip_connected(data, SECONDARYSOCKET)))
        {
            if (result != CURLE_OK and !is_eptr and (ftpc.count1 == 0)) {
                more.* = DOMORE_GOBACK;
                return ftp_epsv_disable(data, ftpc, conn);
            }
            return result;
        }
    }

    if (ftpc.state != .FTP_STOP) {
        result = ftp_multi_statemach(data, &complete);

        if (complete)
            more.* = DOMORE_DONE;

        if (result != CURLE_OK or !ftpc.wait_data_conn)
            return result;

        more.* = DOMORE_INCOMPLETE;
    }

    if (ftp.transfer <= PPTRANSFER_INFO) {
        if (ftpc.wait_data_conn) {
            var serv_conned: bool = false;

            result = Curl_conn_connect(data, SECONDARYSOCKET, false, &serv_conned);
            if (result != CURLE_OK)
                return result;

            if (serv_conned) {
                ftpc.wait_data_conn = false;
                result = ftp_initiate_transfer(data, ftpc);
                if (result != CURLE_OK)
                    return result;

                more.* = DOMORE_DONE;
            } else {
                result = ftp_check_ctrl_on_data_wait(data, ftpc);
                if (result != CURLE_OK)
                    return result;
            }
        } else if (Curl_ftp_acc_get_upload(data)) {
            result = ftp_nb_type(data, ftpc, ftp, Curl_ftp_acc_get_prefer_ascii(data), .FTP_STOR_TYPE);
            if (result != CURLE_OK)
                return result;

            result = ftp_multi_statemach(data, &complete);
            more.* = if (!ftpc.wait_data_conn and complete) DOMORE_DONE else DOMORE_INCOMPLETE;
        } else {
            ftp.downloadsize = -1;

            result = Curl_ftp_acc_range(data);

            if (result == CURLE_OK and Curl_ftp_acc_get_req_maxdownload(data) >= 0) {
                ftpc.dont_check = true;
            }

            if (result != CURLE_OK) {
                // skip
            } else if ((Curl_ftp_acc_get_list_only(data) or ftpc.file == null) and
                Curl_ftp_acc_get_prequote(data) == null)
            {
                if (ftp.transfer == PPTRANSFER_BODY) {
                    result = ftp_nb_type(data, ftpc, ftp, true, .FTP_LIST_TYPE);
                    if (result != CURLE_OK)
                        return result;
                }
            } else {
                if (Curl_ftp_acc_get_prequote(data) != null and ftpc.file == null) {
                    result = ftp_nb_type(data, ftpc, ftp, true, .FTP_RETR_LIST_TYPE);
                } else {
                    result = ftp_nb_type(data, ftpc, ftp, Curl_ftp_acc_get_prefer_ascii(data), .FTP_RETR_TYPE);
                }
                if (result != CURLE_OK)
                    return result;
            }

            result = ftp_multi_statemach(data, &complete);
            if (complete)
                more.* = DOMORE_DONE;
        }
        return result;
    }

    Curl_xfer_setup_nop(data);

    if (!ftpc.wait_data_conn) {
        more.* = DOMORE_DONE;
        trcFtp(data, "[%s] DO-MORE phase ends with %d", .{ ftp_cstate(ftpc), result });
    }

    return result;
}

fn ftp_perform(
    data: *Curl_easy,
    ftpc: *ftp_conn,
    ftp: *FTP,
    connected: *bool,
    dophase_done: *bool,
) CURLcode {
    var result: CURLcode = CURLE_OK;
    const conn = Curl_ftp_acc_get_conn(data) orelse return CURLE_FAILED_INIT;

    trcFtp(data, "[%s] DO phase starts", .{ftp_cstate(ftpc)});
    if (Curl_ftp_acc_get_no_body(data)) {
        ftp.transfer = PPTRANSFER_INFO;
    }

    dophase_done.* = false;

    result = ftp_state_quote(data, ftpc, ftp, true, .FTP_QUOTE);
    if (result != CURLE_OK)
        return result;

    result = ftp_multi_statemach(data, dophase_done);

    connected.* = Curl_conn_is_connected(conn, SECONDARYSOCKET);

    if (connected.*) {
        infof(data, "[FTP] [%s] perform, DATA connection established", .{ftp_cstate(ftpc)});
    } else {
        trcFtp(data, "[%s] perform, awaiting DATA connect", .{ftp_cstate(ftpc)});
    }

    if (dophase_done.*)
        trcFtp(data, "[%s] DO phase is complete1", .{ftp_cstate(ftpc)});

    return result;
}

// ============================================================================
// FTP Response Handlers
// ============================================================================

fn client_write_header(data: *Curl_easy, buf: [*]u8, blen: usize) CURLcode {
    return Curl_ftp_acc_client_write_header(data, buf, blen);
}

fn twodigit(p: [*]const u8, val: *c_int) bool {
    if (!isDigit(p[0]) or !isDigit(p[1]))
        return true;
    val.* = (@as(c_int, p[0] - '0') * 10) + @as(c_int, p[1] - '0');
    return false;
}

pub export fn ftp_213_date(
    p: [*:0]const u8,
    year: *c_int,
    month: *c_int,
    day: *c_int,
    hour: *c_int,
    minute: *c_int,
    second: *c_int,
) callconv(.c) bool {
    const len = std.mem.len(p);
    var century: c_int = 0;
    if (len < 14)
        return false;
    if (twodigit(p, &century) or
        twodigit(p + 2, year) or
        twodigit(p + 4, month) or
        twodigit(p + 6, day) or
        twodigit(p + 8, hour) or
        twodigit(p + 10, minute) or
        twodigit(p + 12, second))
        return false;

    year.* += century * 100;

    if ((month.* > 12) or (day.* > 31) or (hour.* > 23) or (minute.* > 59) or (second.* > 60))
        return false;
    return true;
}

fn ftp_state_mdtm_resp(
    data: *Curl_easy,
    ftpc: *ftp_conn,
    ftp: *FTP,
    ftpcode: c_int,
) CURLcode {
    var result: CURLcode = CURLE_OK;

    switch (ftpcode) {
        213 => {
            var year: c_int = 0;
            var month: c_int = 0;
            var day: c_int = 0;
            var hour: c_int = 0;
            var minute: c_int = 0;
            var second: c_int = 0;
            const pp = &ftpc.pp;
            const resp = containers.curlx_dyn_ptr(&pp.recvbuf).? + 4;
            var showtime: bool = false;
            if (ftp_213_date(resp, &year, &month, &day, &hour, &minute, &second)) {
                var timebuf: [24:0]u8 = undefined;
                _ = curl_msnprintf(
                    &timebuf,
                    timebuf.len,
                    "%04d%02d%02d %02d:%02d:%02d GMT",
                    year,
                    month,
                    day,
                    hour,
                    minute,
                    second,
                );
                if (Curl_getdate_capped(&timebuf, Curl_ftp_acc_get_info_filetime_ptr(data)) == 0)
                    showtime = true;
            }

            if (Curl_ftp_acc_get_no_body(data) and
                ftpc.file != null and
                Curl_ftp_acc_get_get_filetime(data) and
                showtime)
            {
                var headerbuf: [128]u8 = undefined;
                var buffer: Tm = std.mem.zeroes(Tm);
                const filetime = Curl_ftp_acc_get_info_filetime(data);

                result = curlx_time_net.curlx_gmtime(filetime, &buffer);
                if (result != CURLE_OK)
                    return result;

                const wday_idx: usize = if (buffer.tm_wday > 0) @intCast(buffer.tm_wday - 1) else 6;
                const mon_idx: usize = @intCast(@max(0, @min(11, buffer.tm_mon)));
                const headerbuflen = curl_msnprintf(
                    &headerbuf,
                    headerbuf.len,
                    "Last-Modified: %s, %02d %s %4d %02d:%02d:%02d GMT\r\n",
                    Curl_wkday[wday_idx],
                    buffer.tm_mday,
                    Curl_month[mon_idx],
                    buffer.tm_year + 1900,
                    buffer.tm_hour,
                    buffer.tm_min,
                    buffer.tm_sec,
                );
                result = client_write_header(data, &headerbuf, @intCast(headerbuflen));
                if (result != CURLE_OK)
                    return result;
            }
        },
        550 => {
            infof(data, "Given file does not exist", .{});
        },
        else => {
            infof(data, "unsupported MDTM reply format", .{});
        },
    }

    const timecond = Curl_ftp_acc_get_timecondition(data);
    if (timecond != CURL_TIMECOND_NONE) {
        const info_ft = Curl_ftp_acc_get_info_filetime(data);
        const set_tv = Curl_ftp_acc_get_timevalue(data);
        if ((info_ft > 0) and (set_tv > 0)) {
            switch (timecond) {
                CURL_TIMECOND_IFMODSINCE => {
                    if (info_ft <= set_tv) {
                        infof(data, "The requested document is not new enough", .{});
                        ftp.transfer = PPTRANSFER_NONE;
                        Curl_ftp_acc_set_info_timecond(data, true);
                        ftp_state(data, ftpc, .FTP_STOP);
                        return CURLE_OK;
                    }
                },
                CURL_TIMECOND_IFUNMODSINCE => {
                    if (info_ft > set_tv) {
                        infof(data, "The requested document is not old enough", .{});
                        ftp.transfer = PPTRANSFER_NONE;
                        Curl_ftp_acc_set_info_timecond(data, true);
                        ftp_state(data, ftpc, .FTP_STOP);
                        return CURLE_OK;
                    }
                },
                else => {},
            }
        } else {
            infof(data, "Skipping time comparison", .{});
        }
    }

    if (result == CURLE_OK)
        result = ftp_state_type(data, ftpc, ftp);

    return result;
}

fn ftp_state_type_resp(
    data: *Curl_easy,
    ftpc: *ftp_conn,
    ftp: *FTP,
    ftpcode: c_int,
    instate: ftpstate,
) CURLcode {
    var result: CURLcode = CURLE_OK;

    if (@divTrunc(ftpcode, 100) != 2) {
        failf(data, "Couldn't set desired mode", .{});
        return CURLE_FTP_COULDNT_SET_TYPE;
    }
    if (ftpcode != 200) {
        infof(data, "Got a %03d response code instead of the assumed 200", .{ftpcode});
    }

    if (instate == .FTP_TYPE)
        result = ftp_state_size(data, ftpc, ftp)
    else if (instate == .FTP_LIST_TYPE)
        result = ftp_state_list(data, ftpc, ftp)
    else if (instate == .FTP_RETR_TYPE)
        result = ftp_state_retr_prequote(data, ftpc, ftp)
    else if (instate == .FTP_STOR_TYPE)
        result = ftp_state_stor_prequote(data, ftpc, ftp)
    else if (instate == .FTP_RETR_LIST_TYPE)
        result = ftp_state_list_prequote(data, ftpc, ftp);

    return result;
}

fn ftp_state_retr(
    data: *Curl_easy,
    ftpc: *ftp_conn,
    ftp: *FTP,
    filesize: curl_off_t,
) CURLcode {
    var result: CURLcode = CURLE_OK;

    trcFtp(data, "[%s] ftp_state_retr()", .{ftp_cstate(ftpc)});
    const max_filesize = Curl_ftp_acc_get_max_filesize(data);
    if (max_filesize != 0 and (filesize > max_filesize)) {
        failf(data, "Maximum file size exceeded", .{});
        return CURLE_FILESIZE_EXCEEDED;
    }
    ftp.downloadsize = filesize;

    var resume_from = Curl_ftp_acc_get_resume_from(data);
    if (resume_from != 0) {
        if (filesize == -1) {
            infof(data, "ftp server doesn't support SIZE", .{});
        } else {
            if (resume_from < 0) {
                if (filesize < -resume_from) {
                    failf(
                        data,
                        "Offset (%lld) was beyond file size (%lld)",
                        .{ @as(c_longlong, resume_from), @as(c_longlong, filesize) },
                    );
                    return CURLE_BAD_DOWNLOAD_RESUME;
                }
                ftp.downloadsize = -resume_from;
                resume_from = filesize - ftp.downloadsize;
                Curl_ftp_acc_set_resume_from(data, resume_from);
            } else {
                if (filesize < resume_from) {
                    failf(
                        data,
                        "Offset (%lld) was beyond file size (%lld)",
                        .{ @as(c_longlong, resume_from), @as(c_longlong, filesize) },
                    );
                    return CURLE_BAD_DOWNLOAD_RESUME;
                }
                ftp.downloadsize = filesize - resume_from;
            }
        }

        if (ftp.downloadsize == 0) {
            Curl_xfer_setup_nop(data);
            infof(data, "File already completely downloaded", .{});
            ftp.transfer = PPTRANSFER_NONE;
            ftp_state(data, ftpc, .FTP_STOP);
            return CURLE_OK;
        }

        infof(
            data,
            "Instructs server to resume from offset %lld",
            .{@as(c_longlong, resume_from)},
        );

        result = ppSendf(data, &ftpc.pp, "REST %lld", .{@as(c_longlong, resume_from)});
        if (result == CURLE_OK)
            ftp_state(data, ftpc, .FTP_RETR_REST);
    } else {
        result = ftp_send_command(data, ftpc, "RETR", ftpc.file.?);
        if (result == CURLE_OK)
            ftp_state(data, ftpc, .FTP_RETR);
    }

    return result;
}

fn ftp_state_size_resp(
    data: *Curl_easy,
    ftpc: *ftp_conn,
    ftp: *FTP,
    ftpcode: c_int,
    instate: ftpstate,
) CURLcode {
    var result: CURLcode = CURLE_OK;
    var filesize: curl_off_t = -1;
    const buf = containers.curlx_dyn_ptr(&ftpc.pp.recvbuf).?;
    const len = ftpc.pp.nfinal;

    if (ftpcode == 213) {
        if (len > 4) {
            const start = buf + 4;
            const search_len = len - 4;
            var fdigit_ptr: [*:0]const u8 = start;
            if (std.mem.indexOfScalar(u8, start[0..search_len], '\r')) |cr_idx| {
                var idx = cr_idx;
                if (idx > 0) {
                    idx -= 1;
                    if (start[idx] == '\n' and idx > 0)
                        idx -= 1;
                    while (idx > 0 and isDigit(start[idx - 1])) : (idx -= 1) {}
                }
                fdigit_ptr = start + idx;
            }
            var fdigit: ?[*:0]const u8 = fdigit_ptr;
            if (curlx_str_number(&fdigit, &filesize, CURL_OFF_T_MAX) != 0)
                filesize = -1;
        }
    } else if (ftpcode == 550 and instate != .FTP_STOR_SIZE) {
        failf(data, "The file does not exist", .{});
        return CURLE_REMOTE_FILE_NOT_FOUND;
    }

    if (instate == .FTP_SIZE) {
        if (filesize != -1) {
            var clbuf: [128]u8 = undefined;
            const clbuflen = curl_msnprintf(
                &clbuf,
                clbuf.len,
                "Content-Length: %lld\r\n",
                @as(c_longlong, filesize),
            );
            result = client_write_header(data, &clbuf, @intCast(clbuflen));
            if (result != CURLE_OK)
                return result;
        }
        Curl_pgrsSetDownloadSize(data, filesize);
        result = ftp_state_rest(data, ftpc, ftp);
    } else if (instate == .FTP_RETR_SIZE) {
        Curl_pgrsSetDownloadSize(data, filesize);
        result = ftp_state_retr(data, ftpc, ftp, filesize);
    } else if (instate == .FTP_STOR_SIZE) {
        Curl_ftp_acc_set_resume_from(data, filesize);
        result = ftp_state_ul_setup(data, ftpc, ftp, true);
    }

    return result;
}

fn ftp_state_rest_resp(
    data: *Curl_easy,
    ftpc: *ftp_conn,
    ftp: *FTP,
    ftpcode: c_int,
    instate: ftpstate,
) CURLcode {
    var result: CURLcode = CURLE_OK;

    switch (instate) {
        .FTP_RETR_REST => {
            if (ftpcode != 350) {
                failf(data, "Could not use REST", .{});
                result = CURLE_FTP_COULDNT_USE_REST;
            } else {
                result = ftp_send_command(data, ftpc, "RETR", ftpc.file.?);
                if (result == CURLE_OK)
                    ftp_state(data, ftpc, .FTP_RETR);
            }
        },
        else => {
            if (ftpcode == 350) {
                var accept_ranges = "Accept-ranges: bytes\r\n".*;
                result = client_write_header(data, &accept_ranges, accept_ranges.len);
                if (result != CURLE_OK)
                    return result;
            }
            result = ftp_state_prepare_transfer(data, ftpc, ftp);
        },
    }

    return result;
}

fn ftp_state_stor_resp(
    data: *Curl_easy,
    ftpc: *ftp_conn,
    ftpcode: c_int,
) CURLcode {
    var result: CURLcode = CURLE_OK;

    if (ftpcode >= 400) {
        failf(data, "Failed FTP upload: %0d", .{ftpcode});
        ftp_state(data, ftpc, .FTP_STOP);
        return CURLE_UPLOAD_FAILED;
    }

    if (Curl_ftp_acc_get_ftp_use_port(data)) {
        var connected: bool = false;
        ftp_state(data, ftpc, .FTP_STOP);
        result = Curl_conn_connect(data, SECONDARYSOCKET, false, &connected);
        if (result != CURLE_OK)
            return result;

        if (!connected) {
            infof(data, "Data conn was not available immediately", .{});
            ftpc.wait_data_conn = true;
            return ftp_check_ctrl_on_data_wait(data, ftpc);
        }
        ftpc.wait_data_conn = false;
    }
    return ftp_initiate_transfer(data, ftpc);
}

fn ftp_state_get_resp(
    data: *Curl_easy,
    ftpc: *ftp_conn,
    ftp: *FTP,
    ftpcode: c_int,
    instate: ftpstate,
) CURLcode {
    var result: CURLcode = CURLE_OK;

    if ((ftpcode == 150) or (ftpcode == 125)) {
        Curl_ftp_acc_set_req_size(data, -1);

        if ((instate != .FTP_LIST) and
            !Curl_ftp_acc_get_prefer_ascii(data) and
            !Curl_ftp_acc_get_ignorecl(data) and
            (ftp.downloadsize < 1))
        {
            const buf = containers.curlx_dyn_ptr(&ftpc.pp.recvbuf).?;
            const len = containers.curlx_dyn_len(&ftpc.pp.recvbuf);
            if (len >= 7) {
                var i: usize = 0;
                while (i < len - 7) : (i += 1) {
                    var c: ?[*:0]const u8 = buf + i;
                    var what: curl_off_t = 0;
                    if (curlx_str_number(&c, &what, CURL_OFF_T_MAX) == 0 and
                        curlx_str_single(&c, ' ') == 0 and
                        std.mem.startsWith(u8, std.mem.span(c.?), "bytes"))
                    {
                        Curl_ftp_acc_set_req_size(data, what);
                        break;
                    }
                }
            }
        } else if (ftp.downloadsize > -1) {
            Curl_ftp_acc_set_req_size(data, ftp.downloadsize);
        }

        const maxdownload = Curl_ftp_acc_get_req_maxdownload(data);
        var req_size = Curl_ftp_acc_get_req_size(data);
        if (req_size > maxdownload and maxdownload > 0) {
            req_size = maxdownload;
            Curl_ftp_acc_set_req_size(data, req_size);
        } else if ((instate != .FTP_LIST) and Curl_ftp_acc_get_prefer_ascii(data)) {
            req_size = -1;
            Curl_ftp_acc_set_req_size(data, req_size);
        }

        infof(data, "Maxdownload = %lld", .{@as(c_longlong, maxdownload)});

        if (instate != .FTP_LIST) {
            infof(data, "Getting file with size: %lld", .{@as(c_longlong, req_size)});
        }

        if (Curl_ftp_acc_get_ftp_use_port(data)) {
            var connected: bool = false;
            result = Curl_conn_connect(data, SECONDARYSOCKET, false, &connected);
            if (result != CURLE_OK)
                return result;

            if (!connected) {
                infof(data, "Data conn was not available immediately", .{});
                ftp_state(data, ftpc, .FTP_STOP);
                ftpc.wait_data_conn = true;
                return ftp_check_ctrl_on_data_wait(data, ftpc);
            }
            ftpc.wait_data_conn = false;
        }
        return ftp_initiate_transfer(data, ftpc);
    } else {
        if ((instate == .FTP_LIST) and (ftpcode == 450)) {
            ftp.transfer = PPTRANSFER_NONE;
            ftp_state(data, ftpc, .FTP_STOP);
        } else {
            failf(data, "RETR response: %03d", .{ftpcode});
            return if (instate == .FTP_RETR and ftpcode == 550)
                CURLE_REMOTE_FILE_NOT_FOUND
            else
                CURLE_FTP_COULDNT_RETR_FILE;
        }
    }

    return result;
}

// ============================================================================
// Login & Authentication State Handlers
// ============================================================================

fn ftp_state_loggedin(
    data: *Curl_easy,
    ftpc: *ftp_conn,
) CURLcode {
    var result: CURLcode = CURLE_OK;
    const conn = Curl_ftp_acc_get_conn(data).?;

    if (Curl_conn_is_ssl(conn, FIRSTSOCKET)) {
        result = ppSendf(data, &ftpc.pp, "PBSZ %d", .{@as(c_int, 0)});
        if (result == CURLE_OK)
            ftp_state(data, ftpc, .FTP_PBSZ);
    } else {
        result = ftp_state_pwd(data, ftpc);
    }
    return result;
}

fn ftp_state_user_resp(
    data: *Curl_easy,
    ftpc: *ftp_conn,
    ftpcode: c_int,
) CURLcode {
    var result: CURLcode = CURLE_OK;
    const conn = Curl_ftp_acc_get_conn(data).?;

    if ((ftpcode == 331) and (ftpc.state == .FTP_USER)) {
        result = ftp_send_command(data, ftpc, "PASS", Curl_ftp_acc_conn_get_passwd(conn));
        if (result == CURLE_OK)
            ftp_state(data, ftpc, .FTP_PASS);
    } else if (@divTrunc(ftpcode, 100) == 2) {
        result = ftp_state_loggedin(data, ftpc);
    } else if (ftpcode == 332) {
        const account = Curl_ftp_acc_get_str_ftp_account(data);
        if (account == null) {
            failf(data, "ACCT requested but none available", .{});
            result = CURLE_LOGIN_DENIED;
        } else if (ftp_has_ctrl(account)) {
            failf(data, "Control byte in FTP account", .{});
            result = CURLE_BAD_FUNCTION_ARGUMENT;
        } else {
            result = ftp_send_command(data, ftpc, "ACCT", account.?);
            if (result == CURLE_OK)
                ftp_state(data, ftpc, .FTP_ACCT);
        }
    } else {
        const alt = Curl_ftp_acc_get_str_ftp_alternative_to_user(data);
        if (alt != null and !ftpc.ftp_trying_alternative) {
            if (ftp_has_ctrl(alt)) {
                failf(data, "Control byte in FTP alternative-to-user command", .{});
                result = CURLE_BAD_FUNCTION_ARGUMENT;
            } else {
                result = ppSendf(data, &ftpc.pp, "%s", .{alt.?});
                if (result == CURLE_OK) {
                    ftpc.ftp_trying_alternative = true;
                    ftp_state(data, ftpc, .FTP_USER);
                }
            }
        } else {
            failf(data, "Access denied: %03d", .{ftpcode});
            result = CURLE_LOGIN_DENIED;
        }
    }
    return result;
}

fn ftp_state_acct_resp(
    data: *Curl_easy,
    ftpc: *ftp_conn,
    ftpcode: c_int,
) CURLcode {
    var result: CURLcode = CURLE_OK;
    if (ftpcode != 230) {
        failf(data, "ACCT rejected by server: %03d", .{ftpcode});
        result = CURLE_FTP_WEIRD_PASS_REPLY;
    } else {
        result = ftp_state_loggedin(data, ftpc);
    }
    return result;
}

fn ftp_statemach(data: *Curl_easy, ftpc: *ftp_conn, done: *bool) CURLcode {
    const result = Curl_ftp_acc_pp_statemach(data, &ftpc.pp, false, false);
    done.* = (ftpc.state == .FTP_STOP);
    return result;
}

fn ftp_multi_statemach(data: *Curl_easy, done: *bool) callconv(.c) CURLcode {
    const conn = Curl_ftp_acc_get_conn(data) orelse return CURLE_FAILED_INIT;
    const ftpc = getFtpConn(conn) orelse return CURLE_FAILED_INIT;
    return ftp_statemach(data, ftpc, done);
}

fn ftp_block_statemach(
    data: *Curl_easy,
    ftpc: *ftp_conn,
) CURLcode {
    const pp = &ftpc.pp;
    var result: CURLcode = CURLE_OK;

    while (ftpc.state != .FTP_STOP) {
        if (ftpc.shutdown)
            trcFtp(data, "in shutdown, waiting for server response", .{});
        result = Curl_ftp_acc_pp_statemach(data, pp, true, true);
        if (result != CURLE_OK)
            break;
    }

    return result;
}

// ============================================================================
// Connect, Done, Quote & PASV/PORT/PWD/WAIT Response Handlers
// ============================================================================

inline fn pathlen(ftpc: *const ftp_conn, num: usize) c_int {
    std.debug.assert(ftpc.dirs != null);
    std.debug.assert(ftpc.dirdepth > num);
    return ftpc.dirs.?[num].len;
}

inline fn pathpiece(ftpc: *const ftp_conn, num: usize) [*]const u8 {
    std.debug.assert(ftpc.dirs != null);
    std.debug.assert(ftpc.dirdepth > num);
    return ftpc.rawpath.? + @as(usize, @intCast(ftpc.dirs.?[num].start));
}

fn ftp_connect(data: *Curl_easy, done: *bool) callconv(.c) CURLcode {
    var result: CURLcode = CURLE_OK;
    const conn = Curl_ftp_acc_get_conn(data) orelse return CURLE_FAILED_INIT;
    const ftpc = getFtpConn(conn) orelse return CURLE_FAILED_INIT;
    const pp = &ftpc.pp;

    done.* = false;

    pp.statemachine = &ftp_pp_statemachine;
    pp.endofresp = &ftp_endofresp;

    if (Curl_conn_is_ssl(conn, FIRSTSOCKET)) {
        result = Curl_conn_connect(data, FIRSTSOCKET, true, done);
        if (result != CURLE_OK)
            return result;
    }

    Curl_pp_init(pp, Curl_pgrs_now(data));
    ftp_state(data, ftpc, .FTP_WAIT220);

    result = ftp_statemach(data, ftpc, done);

    return result;
}

fn ftp_sendquote(
    data: *Curl_easy,
    ftpc: *ftp_conn,
    quote: ?*curl_slist,
) CURLcode {
    var item = quote;
    const pp = &ftpc.pp;

    while (item) |it| : (item = it.next) {
        if (it.data) |cmd_data| {
            var cmd: [*:0]const u8 = cmd_data;
            var acceptfail: bool = false;
            var ftpcode: c_int = 0;
            var nread: usize = 0;

            if (cmd[0] == '*') {
                cmd += 1;
                acceptfail = true;
            }

            var result = ppSendf(data, pp, "%s", .{cmd});
            if (result == CURLE_OK) {
                pp.response = Curl_pgrs_now(data).*;
                result = getftpresponse(data, &nread, &ftpcode);
            }
            if (result != CURLE_OK)
                return result;

            if (!acceptfail and (ftpcode >= 400)) {
                failf(data, "QUOT string not accepted: %s", .{cmd});
                return CURLE_QUOTE_ERROR;
            }
        }
    }

    return CURLE_OK;
}

fn ftp_need_quote(data: *Curl_easy, instate: ftpstate) ?*curl_slist {
    return switch (instate) {
        .FTP_QUOTE => Curl_ftp_acc_get_quote(data),
        .FTP_RETR_PREQUOTE,
        .FTP_STOR_PREQUOTE,
        .FTP_LIST_PREQUOTE,
        => Curl_ftp_acc_get_prequote(data),
        .FTP_POSTQUOTE => Curl_ftp_acc_get_postquote(data),
        else => null,
    };
}

fn ftp_state_quote(
    data: *Curl_easy,
    ftpc: *ftp_conn,
    ftp: *FTP,
    init: bool,
    instate: ftpstate,
) CURLcode {
    var result: CURLcode = CURLE_OK;
    var quote: bool = false;
    var item = ftp_need_quote(data, instate);

    if (init)
        ftpc.count1 = 0
    else
        ftpc.count1 += 1;

    if (item != null) {
        var i: c_int = 0;
        while ((i < ftpc.count1) and (item != null)) : (i += 1) {
            item = item.?.next;
        }
        if (item) |it| {
            if (it.data) |cmd_data| {
                var ptr: [*:0]const u8 = cmd_data;
                if (ptr[0] == '*') {
                    ptr += 1;
                    ftpc.count2 = 1;
                } else {
                    ftpc.count2 = 0;
                }

                result = ppSendf(data, &ftpc.pp, "%s", .{ptr});
                if (result == CURLE_OK)
                    ftp_state(data, ftpc, instate);
                quote = true;
            }
        }
    }

    if (!quote) {
        switch (instate) {
            .FTP_RETR_PREQUOTE => {
                if (ftp.transfer != PPTRANSFER_BODY) {
                    ftp_state(data, ftpc, .FTP_STOP);
                } else {
                    if (ftpc.known_filesize != -1) {
                        Curl_pgrsSetDownloadSize(data, ftpc.known_filesize);
                        result = ftp_state_retr(data, ftpc, ftp, ftpc.known_filesize);
                    } else {
                        if (Curl_ftp_acc_get_ignorecl(data) or Curl_ftp_acc_get_prefer_ascii(data)) {
                            result = ftp_send_command(data, ftpc, "RETR", ftpc.file.?);
                            if (result == CURLE_OK)
                                ftp_state(data, ftpc, .FTP_RETR);
                        } else {
                            result = ftp_send_command(data, ftpc, "SIZE", ftpc.file.?);
                            if (result == CURLE_OK)
                                ftp_state(data, ftpc, .FTP_RETR_SIZE);
                        }
                    }
                }
            },
            .FTP_STOR_PREQUOTE => {
                result = ftp_state_ul_setup(data, ftpc, ftp, false);
            },
            .FTP_POSTQUOTE => {},
            .FTP_LIST_PREQUOTE => {
                ftp_state(data, ftpc, .FTP_LIST_TYPE);
                result = ftp_state_list(data, ftpc, ftp);
            },
            else => {
                result = ftp_state_cwd(data, ftpc, ftp);
            },
        }
    }

    return result;
}

fn ftp_epsv_disable(
    data: *Curl_easy,
    ftpc: *ftp_conn,
    conn: *connectdata,
) CURLcode {
    var result: CURLcode = CURLE_OK;

    if (Curl_ftp_acc_conn_get_ipv6(conn) and !Curl_conn_is_tunneling(conn, FIRSTSOCKET)) {
        failf(data, "Failed EPSV attempt, exiting", .{});
        return CURLE_WEIRD_SERVER_REPLY;
    }

    infof(data, "Failed EPSV attempt. Disabling EPSV", .{});
    Curl_ftp_acc_conn_set_ftp_use_epsv(conn, false);
    close_secondarysocket(data, ftpc);
    Curl_ftp_acc_clear_state_errorbuf(data);
    result = ppSendf(data, &ftpc.pp, "%s", .{"PASV"});
    if (result == CURLE_OK) {
        ftpc.count1 += 1;
        ftp_state(data, ftpc, .FTP_PASV);
    }
    return result;
}

pub fn match_pasv_6nums(p_in: [*:0]const u8, array: *[6]c_uint) bool {
    var p: ?[*:0]const u8 = p_in;
    var i: usize = 0;
    while (i < 6) : (i += 1) {
        var num: curl_off_t = 0;
        if (i != 0) {
            if (p.?[0] != ',')
                return false;
            p = p.? + 1;
        }
        if (curlx_str_number(&p, &num, 0xff) != 0)
            return false;
        array[i] = std.math.cast(c_uint, num) orelse return false;
    }
    return true;
}

fn ftp_state_pasv_resp(
    data: *Curl_easy,
    ftpc: *ftp_conn,
    ftpcode: c_int,
) CURLcode {
    const conn = Curl_ftp_acc_get_conn(data) orelse return CURLE_FAILED_INIT;
    var result: CURLcode = CURLE_OK;
    const pp = &ftpc.pp;
    var newhost: ?[*:0]u8 = null;
    var newport: u16 = 0;
    const recv_ptr = containers.curlx_dyn_ptr(&pp.recvbuf).?;
    const recv_len = containers.curlx_dyn_len(&pp.recvbuf);
    var str: [*:0]const u8 = if (recv_len >= 4) recv_ptr + 4 else recv_ptr;

    if ((ftpc.count1 == 0) and (ftpcode == 229)) {
        const str_slice = std.mem.span(str);
        var valid_epsv: bool = false;
        if (std.mem.indexOfScalar(u8, str_slice, '(')) |open_idx| {
            const ptr: [*:0]const u8 = str + open_idx + 1;
            const sep = ptr[0];
            if (sep != 0 and (ptr[1] == sep) and (ptr[2] == sep) and isDigit(ptr[3])) {
                var p: ?[*:0]const u8 = ptr + 3;
                var num: curl_off_t = 0;
                if (curlx_str_number(&p, &num, 0xffff) != 0 or num < 1 or (p.?[0] != sep)) {
                    failf(data, "Illegal port number in EPSV reply", .{});
                    return CURLE_FTP_WEIRD_PASV_REPLY;
                }
                newport = std.math.cast(u16, num) orelse {
                    failf(data, "Illegal port number in EPSV reply", .{});
                    return CURLE_FTP_WEIRD_PASV_REPLY;
                };
                result = Curl_ftp_acc_control_addr_dup(data, &newhost);
                if (result != CURLE_OK)
                    return result;
                valid_epsv = true;
            }
        }
        if (!valid_epsv) {
            failf(data, "Weirdly formatted EPSV reply", .{});
            return CURLE_FTP_WEIRD_PASV_REPLY;
        }
    } else if ((ftpc.count1 == 1) and (ftpcode == 227)) {
        var ip: [6]c_uint = @splat(0);
        while (str[0] != 0) : (str += 1) {
            if (match_pasv_6nums(str, &ip))
                break;
        }

        if (str[0] == 0) {
            failf(data, "Could not interpret the 227-response", .{});
            return CURLE_FTP_WEIRD_227_FORMAT;
        }

        if (Curl_ftp_acc_get_ftp_skip_ip(data)) {
            infof(
                data,
                "Skip %u.%u.%u.%u for data connection, reuse %s instead",
                .{ ip[0], ip[1], ip[2], ip[3], Curl_ftp_acc_conn_get_origin_hostname(conn) },
            );
            result = Curl_ftp_acc_control_addr_dup(data, &newhost);
            if (result != CURLE_OK)
                return result;
        } else {
            newhost = curl_maprintf("%u.%u.%u.%u", ip[0], ip[1], ip[2], ip[3]);
        }

        if (newhost == null)
            return CURLE_OUT_OF_MEMORY;

        const pasv_port: c_uint = (ip[4] << 8) + ip[5];
        if (pasv_port < 1) {
            mem.free(newhost.?);
            failf(data, "Illegal port number in PASV reply", .{});
            return CURLE_FTP_WEIRD_PASV_REPLY;
        }
        newport = std.math.cast(u16, pasv_port) orelse {
            mem.free(newhost.?);
            failf(data, "Illegal port number in PASV reply", .{});
            return CURLE_FTP_WEIRD_PASV_REPLY;
        };
    } else if (ftpc.count1 == 0) {
        return ftp_epsv_disable(data, ftpc, conn);
    } else {
        failf(data, "Bad PASV/EPSV response: %03d", .{ftpcode});
        return CURLE_FTP_WEIRD_PASV_REPLY;
    }

    std.debug.assert(newhost != null);
    result = Curl_ftp_acc_setup_pasv_conn(data, conn, newhost.?, newport);
    mem.free(newhost.?);
    if (result != CURLE_OK) {
        if ((result != CURLE_OUT_OF_MEMORY) and
            (ftpc.count1 == 0) and (ftpcode == 229))
        {
            result = ftp_epsv_disable(data, ftpc, conn);
        }
        return result;
    }

    Curl_ftp_acc_conn_set_do_more(conn, true);
    ftp_state(data, ftpc, .FTP_STOP);

    return result;
}

fn ftp_state_port_resp(
    data: *Curl_easy,
    ftpc: *ftp_conn,
    ftp: *FTP,
    ftpcode: c_int,
) CURLcode {
    const conn = Curl_ftp_acc_get_conn(data).?;
    var fcmd: ftpport = @fromBackingInt(@intCast(@as(c_uint, @intCast(ftpc.count1))));
    var result: CURLcode = CURLE_OK;

    if (@divTrunc(ftpcode, 100) != 2) {
        if (fcmd == .EPRT) {
            infof(data, "disabling EPRT usage", .{});
            Curl_ftp_acc_conn_set_ftp_use_eprt(conn, false);
        }
        fcmd = @fromBackingInt(@intCast(@backingInt(fcmd) + 1));

        if (fcmd == .DONE) {
            failf(data, "Failed to do PORT", .{});
            result = CURLE_FTP_PORT_FAILED;
        } else {
            result = ftp_state_use_port(data, ftpc, fcmd);
        }
    } else {
        infof(data, "Connect data stream actively", .{});
        ftp_state(data, ftpc, .FTP_STOP);
        result = ftp_dophase_done(data, ftpc, ftp, false);
    }

    return result;
}

fn ftp_pwd_resp(
    data: *Curl_easy,
    ftpc: *ftp_conn,
    ftpcode: c_int,
) CURLcode {
    const pp = &ftpc.pp;
    var result: CURLcode = CURLE_OK;

    if (ftpcode == 257) {
        const recv_ptr = containers.curlx_dyn_ptr(&pp.recvbuf).?;
        const recv_len = containers.curlx_dyn_len(&pp.recvbuf);
        var ptr: [*:0]const u8 = if (recv_len >= 4) recv_ptr + 4 else recv_ptr;
        var entry_extracted: bool = false;
        var out: dynbuf = undefined;
        containers.curlx_dyn_init(&out, 1000);
        defer containers.curlx_dyn_free(&out);

        while (ptr[0] != '\n' and ptr[0] != 0 and ptr[0] != '"') : (ptr += 1) {}

        if (ptr[0] == '"') {
            ptr += 1;
            while (ptr[0] != 0) : (ptr += 1) {
                if (ptr[0] == '"') {
                    if (ptr[1] == '"') {
                        result = containers.curlx_dyn_addn(&out, ptr + 1, 1);
                        ptr += 1;
                    } else {
                        if (containers.curlx_dyn_len(&out) != 0)
                            entry_extracted = true;
                        break;
                    }
                } else {
                    if (isCntrl(ptr[0])) {
                        return CURLE_WEIRD_SERVER_REPLY;
                    }
                    result = containers.curlx_dyn_addn(&out, ptr, 1);
                }
                if (result != CURLE_OK) {
                    return result;
                }
            }
        }
        if (entry_extracted) {
            const dir = containers.curlx_dyn_ptr(&out).?;

            if (ftpc.server_os == null and dir[0] != '/') {
                result = ppSendf(data, &ftpc.pp, "%s", .{"SYST"});
                if (result != CURLE_OK) {
                    return result;
                }
            }

            if (ftpc.entrypath) |ep|
                mem.free(ep);
            ftpc.entrypath = dir;
            out = std.mem.zeroes(dynbuf);
            infof(data, "Entry path is '%s'", .{ftpc.entrypath.?});
            result = Curl_ftp_acc_set_most_recent_ftp_entrypath(data, ftpc.entrypath.?);
            if (result != CURLE_OK)
                return result;

            if (ftpc.server_os == null and dir[0] != '/') {
                ftp_state(data, ftpc, .FTP_SYST);
                return CURLE_OK;
            }
        } else {
            containers.curlx_dyn_free(&out);
            infof(data, "Failed to figure out path", .{});
        }
    }
    ftp_state(data, ftpc, .FTP_STOP);
    trcFtp(data, "[%s] protocol connect phase DONE", .{ftp_cstate(ftpc)});
    return CURLE_OK;
}

const ftpauth = [_][*:0]const u8{ "SSL", "TLS" };

fn ftp_wait_resp(
    data: *Curl_easy,
    conn: *connectdata,
    ftpc: *ftp_conn,
    ftpcode: c_int,
) CURLcode {
    var result: CURLcode = CURLE_OK;
    if (ftpcode == 230) {
        if (ftpc.use_ssl <= CURLUSESSL_TRY or Curl_conn_is_ssl(conn, FIRSTSOCKET))
            return ftp_state_user_resp(data, ftpc, ftpcode);
    } else if (ftpcode != 220) {
        failf(data, "Got a %03d ftp-server response when 220 was expected", .{ftpcode});
        return CURLE_WEIRD_SERVER_REPLY;
    }

    if (ftpc.use_ssl != 0 and !Curl_conn_is_ssl(conn, FIRSTSOCKET)) {
        ftpc.count3 = 0;
        switch (Curl_ftp_acc_get_ftpsslauth(data)) {
            CURLFTPAUTH_DEFAULT, CURLFTPAUTH_SSL => {
                ftpc.count2 = 1;
                ftpc.count1 = 0;
            },
            CURLFTPAUTH_TLS => {
                ftpc.count2 = -1;
                ftpc.count1 = 1;
            },
            else => {
                failf(data, "unsupported parameter to CURLOPT_FTPSSLAUTH: %d", .{
                    @as(c_int, Curl_ftp_acc_get_ftpsslauth(data)),
                });
                return CURLE_UNKNOWN_OPTION;
            },
        }
        result = ftp_send_command(data, ftpc, "AUTH", ftpauth[@intCast(ftpc.count1)]);
        if (result == CURLE_OK)
            ftp_state(data, ftpc, .FTP_AUTH);
    } else {
        result = ftp_state_user(data, ftpc, conn);
    }
    return result;
}

fn ftp_use_ssl(conn: *connectdata, ftpc: *const ftp_conn) u8 {
    if (ftpc.use_ssl == 0 and (Curl_ftp_acc_conn_get_scheme_flags(conn) & PROTOPT_SSL) != 0)
        return CURLUSESSL_ALL;
    return ftpc.use_ssl;
}

fn ftp_pp_statemachine(
    data_opt: ?*Curl_easy,
    conn_opt: ?*connectdata,
) callconv(.c) CURLcode {
    const data = data_opt orelse return CURLE_FAILED_INIT;
    const conn = conn_opt orelse return CURLE_FAILED_INIT;
    var result: CURLcode = CURLE_OK;
    var ftpcode: c_int = 0;
    const ftpc = getFtpConn(conn) orelse return CURLE_FAILED_INIT;
    const ftp = getFtpEasy(data) orelse return CURLE_FAILED_INIT;
    const pp = &ftpc.pp;
    var nread: usize = 0;

    if (pp.sendleft != 0)
        return Curl_pp_flushsend(data, pp);

    result = ftp_readresp(data, ftpc, FIRSTSOCKET, pp, &ftpcode, &nread);
    if (result != CURLE_OK or ftpcode == 0)
        return result;

    switch (ftpc.state) {
        .FTP_WAIT220 => {
            result = ftp_wait_resp(data, conn, ftpc, ftpcode);
        },
        .FTP_AUTH => {
            if (pp.overflow != 0)
                return CURLE_WEIRD_SERVER_REPLY;
            if ((ftpcode == 234) or (ftpcode == 334)) {
                var done: bool = false;
                if (!Curl_conn_is_ssl(conn, FIRSTSOCKET)) {
                    result = Curl_ftp_acc_ssl_cfilter_add(data, conn, FIRSTSOCKET);
                    if (result != CURLE_OK)
                        return CURLE_USE_SSL_FAILED;
                }
                result = Curl_conn_connect(data, FIRSTSOCKET, true, &done);
                if (result == CURLE_OK) {
                    Curl_ftp_acc_conn_set_ftp_use_data_ssl(conn, false);
                    result = ftp_state_user(data, ftpc, conn);
                }
            } else if (ftpc.count3 < 1) {
                ftpc.count3 += 1;
                ftpc.count1 += ftpc.count2;
                result = ftp_send_command(data, ftpc, "AUTH", ftpauth[@intCast(ftpc.count1)]);
            } else {
                if (ftpc.use_ssl > CURLUSESSL_TRY)
                    result = CURLE_USE_SSL_FAILED
                else
                    result = ftp_state_user(data, ftpc, conn);
            }
        },
        .FTP_USER, .FTP_PASS => {
            result = ftp_state_user_resp(data, ftpc, ftpcode);
        },
        .FTP_ACCT => {
            result = ftp_state_acct_resp(data, ftpc, ftpcode);
        },
        .FTP_PBSZ => {
            const prot_char: c_int = if (ftp_use_ssl(conn, ftpc) == CURLUSESSL_CONTROL) 'C' else 'P';
            result = ppSendf(data, &ftpc.pp, "PROT %c", .{prot_char});
            if (result == CURLE_OK)
                ftp_state(data, ftpc, .FTP_PROT);
        },
        .FTP_PROT => {
            if (@divTrunc(ftpcode, 100) == 2) {
                Curl_ftp_acc_conn_set_ftp_use_data_ssl(conn, ftp_use_ssl(conn, ftpc) != CURLUSESSL_CONTROL);
            } else if (ftp_use_ssl(conn, ftpc) > CURLUSESSL_CONTROL) {
                return CURLE_USE_SSL_FAILED;
            }

            if (Curl_ftp_acc_get_ftp_ccc(data) != 0) {
                result = ppSendf(data, &ftpc.pp, "%s", .{"CCC"});
                if (result == CURLE_OK)
                    ftp_state(data, ftpc, .FTP_CCC);
            } else {
                result = ftp_state_pwd(data, ftpc);
            }
        },
        .FTP_CCC => {
            if (ftpcode < 500) {
                result = Curl_ftp_acc_ssl_cfilter_remove(
                    data,
                    FIRSTSOCKET,
                    Curl_ftp_acc_get_ftp_ccc(data) == CURLFTPSSL_CCC_ACTIVE,
                );
                if (result != CURLE_OK)
                    failf(data, "Failed to clear the command channel (CCC)", .{});
            }
            if (result == CURLE_OK)
                result = ftp_state_pwd(data, ftpc);
        },
        .FTP_PWD => {
            result = ftp_pwd_resp(data, ftpc, ftpcode);
        },
        .FTP_SYST => {
            if (ftpcode == 215) {
                const recv_ptr = containers.curlx_dyn_ptr(&pp.recvbuf).?;
                const recv_len = containers.curlx_dyn_len(&pp.recvbuf);
                var ptr: [*:0]const u8 = if (recv_len >= 4) recv_ptr + 4 else recv_ptr;
                while (ptr[0] == ' ') : (ptr += 1) {}
                const start: [*]const u8 = ptr;
                var os_len: usize = 0;
                while (ptr[0] != 0 and ptr[0] != ' ') : ({
                    ptr += 1;
                    os_len += 1;
                }) {}
                const os = curlx_memdup0(start, os_len) orelse return CURLE_OUT_OF_MEMORY;

                if (primitives.curl_strequal(os, "OS/400") != 0) {
                    result = ppSendf(data, &ftpc.pp, "%s", .{"SITE NAMEFMT 1"});
                    if (result != CURLE_OK) {
                        mem.free(os);
                        return result;
                    }
                    if (ftpc.server_os) |old_os|
                        mem.free(old_os);
                    ftpc.server_os = os;
                    ftp_state(data, ftpc, .FTP_NAMEFMT);
                    return result;
                }
                if (ftpc.server_os) |old_os|
                    mem.free(old_os);
                ftpc.server_os = os;
            }
            ftp_state(data, ftpc, .FTP_STOP);
            trcFtp(data, "[%s] protocol connect phase DONE", .{ftp_cstate(ftpc)});
        },
        .FTP_NAMEFMT => {
            if (ftpcode == 250) {
                _ = ftp_state_pwd(data, ftpc);
                return result;
            }
            ftp_state(data, ftpc, .FTP_STOP);
            trcFtp(data, "[%s] protocol connect phase DONE", .{ftp_cstate(ftpc)});
        },
        .FTP_QUOTE,
        .FTP_POSTQUOTE,
        .FTP_RETR_PREQUOTE,
        .FTP_STOR_PREQUOTE,
        .FTP_LIST_PREQUOTE,
        => {
            if ((ftpcode >= 400) and (ftpc.count2 == 0)) {
                failf(data, "QUOT command failed with %03d", .{ftpcode});
                result = CURLE_QUOTE_ERROR;
            } else {
                result = ftp_state_quote(data, ftpc, ftp, false, ftpc.state);
            }
        },
        .FTP_CWD => {
            if (@divTrunc(ftpcode, 100) != 2) {
                const create_dirs = Curl_ftp_acc_get_ftp_create_missing_dirs(data);
                if (create_dirs != 0 and ftpc.cwdcount != 0 and ftpc.count2 == 0) {
                    ftpc.count2 += 1;
                    ftpc.count3 = if (create_dirs == 2) 1 else 0;
                    const idx: usize = @intCast(ftpc.cwdcount - 1);
                    result = ppSendf(
                        data,
                        &ftpc.pp,
                        "MKD %.*s",
                        .{ pathlen(ftpc, idx), pathpiece(ftpc, idx) },
                    );
                    if (result == CURLE_OK)
                        ftp_state(data, ftpc, .FTP_MKD);
                } else {
                    failf(data, "Server denied you to change to the given directory", .{});
                    ftpc.cwdfail = true;
                    result = CURLE_REMOTE_ACCESS_DENIED;
                }
            } else {
                ftpc.count2 = 0;
                if (ftpc.cwdcount >= ftpc.dirdepth) {
                    result = ftp_state_mdtm(data, ftpc, ftp);
                } else {
                    ftpc.cwdcount += 1;
                    const idx: usize = @intCast(ftpc.cwdcount - 1);
                    result = ppSendf(
                        data,
                        &ftpc.pp,
                        "CWD %.*s",
                        .{ pathlen(ftpc, idx), pathpiece(ftpc, idx) },
                    );
                }
            }
        },
        .FTP_MKD => {
            const prev_count3 = ftpc.count3;
            if (@divTrunc(ftpcode, 100) != 2) {
                ftpc.count3 -= 1;
            }
            if ((@divTrunc(ftpcode, 100) != 2) and (prev_count3 == 0)) {
                failf(data, "Failed to MKD dir: %03d", .{ftpcode});
                result = CURLE_REMOTE_ACCESS_DENIED;
            } else {
                ftp_state(data, ftpc, .FTP_CWD);
                const idx: usize = @intCast(ftpc.cwdcount - 1);
                result = ppSendf(
                    data,
                    &ftpc.pp,
                    "CWD %.*s",
                    .{ pathlen(ftpc, idx), pathpiece(ftpc, idx) },
                );
            }
        },
        .FTP_MDTM => {
            result = ftp_state_mdtm_resp(data, ftpc, ftp, ftpcode);
        },
        .FTP_TYPE,
        .FTP_LIST_TYPE,
        .FTP_RETR_LIST_TYPE,
        .FTP_RETR_TYPE,
        .FTP_STOR_TYPE,
        => {
            result = ftp_state_type_resp(data, ftpc, ftp, ftpcode, ftpc.state);
        },
        .FTP_SIZE,
        .FTP_RETR_SIZE,
        .FTP_STOR_SIZE,
        => {
            result = ftp_state_size_resp(data, ftpc, ftp, ftpcode, ftpc.state);
        },
        .FTP_REST,
        .FTP_RETR_REST,
        => {
            result = ftp_state_rest_resp(data, ftpc, ftp, ftpcode, ftpc.state);
        },
        .FTP_PRET => {
            if (ftpcode != 200) {
                failf(data, "PRET command not accepted: %03d", .{ftpcode});
                return CURLE_FTP_PRET_FAILED;
            }
            result = ftp_state_use_pasv(data, ftpc, conn);
        },
        .FTP_PASV => {
            result = ftp_state_pasv_resp(data, ftpc, ftpcode);
        },
        .FTP_PORT => {
            result = ftp_state_port_resp(data, ftpc, ftp, ftpcode);
        },
        .FTP_LIST,
        .FTP_RETR,
        => {
            result = ftp_state_get_resp(data, ftpc, ftp, ftpcode, ftpc.state);
        },
        .FTP_STOR => {
            result = ftp_state_stor_resp(data, ftpc, ftpcode);
        },
        .FTP_QUIT => {
            ftp_state(data, ftpc, .FTP_STOP);
        },
        else => {
            ftp_state(data, ftpc, .FTP_STOP);
        },
    }
    return result;
}

// ============================================================================
// Done, Pollset, Disconnect, Multi-stage Protocol Lifecycle
// ============================================================================

fn ftp_done_status(
    data: *Curl_easy,
    ftpc: *ftp_conn,
    status: CURLcode,
    premature: bool,
) CURLcode {
    const conn = Curl_ftp_acc_get_conn(data).?;
    switch (status) {
        CURLE_BAD_DOWNLOAD_RESUME,
        CURLE_FTP_WEIRD_PASV_REPLY,
        CURLE_FTP_PORT_FAILED,
        CURLE_FTP_ACCEPT_FAILED,
        CURLE_FTP_ACCEPT_TIMEOUT,
        CURLE_FTP_COULDNT_SET_TYPE,
        CURLE_FTP_COULDNT_RETR_FILE,
        CURLE_PARTIAL_FILE,
        CURLE_UPLOAD_FAILED,
        CURLE_REMOTE_ACCESS_DENIED,
        CURLE_FILESIZE_EXCEEDED,
        CURLE_REMOTE_FILE_NOT_FOUND,
        CURLE_WRITE_ERROR,
        CURLE_OK,
        => {
            if (!premature)
                return CURLE_OK;
        },
        else => {},
    }
    ftpc.ctl_valid = false;
    ftpc.cwdfail = true;
    trcFtp(data, "FTP ended with bad error code", .{});
    Curl_ftp_acc_connclose(conn);
    return status;
}

fn ftp_done_wildcard(data: *Curl_easy, ftpc: *ftp_conn) void {
    if (Curl_ftp_acc_get_wildcardmatch(data)) {
        if (Curl_ftp_acc_has_chunk_end(data) and ftpc.file != null) {
            Curl_ftp_acc_call_chunk_end(data);
            freedirs(ftpc);
        }
        ftpc.known_filesize = -1;
    }
}

fn ftp_done_path(data: *Curl_easy, ftpc: *ftp_conn, result: CURLcode) void {
    const conn = Curl_ftp_acc_get_conn(data).?;
    if (result != CURLE_OK) {
        ftpc.ctl_valid = false;
        Curl_ftp_acc_connclose(conn);
        if (ftpc.prevpath) |pp_str| {
            mem.free(pp_str);
            ftpc.prevpath = null;
        }
    } else {
        if (ftpc.rawpath) |rawPath| {
            if ((Curl_ftp_acc_get_ftp_filemethod(data) == FTPFILE_NOCWD) and (rawPath[0] == '/')) {
                // full path => no CWDs happened => keep ftpc.prevpath
            } else {
                var pathLen = std.mem.len(rawPath);

                if (ftpc.prevpath) |pp_str| {
                    mem.free(pp_str);
                    ftpc.prevpath = null;
                }

                if (!ftpc.cwdfail) {
                    if (Curl_ftp_acc_get_ftp_filemethod(data) == FTPFILE_NOCWD) {
                        pathLen = 0;
                    } else {
                        pathLen -= if (ftpc.file) |f| std.mem.len(f) else 0;
                    }
                    ftpc.prevpath = curlx_memdup0(rawPath, pathLen);
                } else {
                    ftpc.prevpath = null;
                }
            }
        }
        if (ftpc.prevpath) |pp_str| {
            infof(data, "Remembering we are in directory \"%s\"", .{pp_str});
        }
    }
}

fn ftp_done_secondary_socket(data: *Curl_easy, ftpc: *ftp_conn, result_in: CURLcode) CURLcode {
    const conn = Curl_ftp_acc_get_conn(data).?;
    var result = result_in;
    if (Curl_conn_is_setup(conn, SECONDARYSOCKET)) {
        if (result == CURLE_OK and ftpc.dont_check and Curl_ftp_acc_get_req_maxdownload(data) > 0) {
            result = ppSendf(data, &ftpc.pp, "%s", .{"ABOR"});
            if (result != CURLE_OK) {
                failf(data, "Failure sending ABOR command: %s", .{
                    curl_easy_strerror(result),
                });
                ftpc.ctl_valid = false;
                Curl_ftp_acc_connclose(conn);
            }
        }
        close_secondarysocket(data, ftpc);
    }
    return result;
}

fn ftp_done_control_reply(
    data: *Curl_easy,
    ftpc: *ftp_conn,
    ftp: *FTP,
    result_in: CURLcode,
    premature: bool,
) CURLcode {
    const conn = Curl_ftp_acc_get_conn(data).?;
    var result = result_in;
    var nread: usize = 0;
    var ftpcode: c_int = 0;

    if (result == CURLE_OK and (ftp.transfer == PPTRANSFER_BODY) and ftpc.ctl_valid and
        ftpc.pp.isPendingResp() and !premature)
    {
        ftpc.pp.response = Curl_pgrs_now(data).*;
        result = getftpresponse(data, &nread, &ftpcode);

        if (nread == 0 and (result == CURLE_OPERATION_TIMEDOUT)) {
            failf(data, "control connection looks dead", .{});
            ftpc.ctl_valid = false;
            Curl_ftp_acc_connclose(conn);
        }

        if (result != CURLE_OK)
            return result;

        if (ftpc.dont_check and Curl_ftp_acc_get_req_maxdownload(data) > 0) {
            infof(data, "partial download completed, closing connection", .{});
            Curl_ftp_acc_connclose(conn);
            return result;
        }

        if (!ftpc.dont_check) {
            switch (ftpcode) {
                226, 250 => {},
                552 => {
                    failf(data, "Exceeded storage allocation", .{});
                    result = CURLE_REMOTE_DISK_FULL;
                },
                else => {
                    failf(data, "server did not report OK, got %d", .{ftpcode});
                    result = CURLE_PARTIAL_FILE;
                },
            }
        }
    }
    return result;
}

fn ftp_done_check_partial(
    data: *Curl_easy,
    ftpc: *const ftp_conn,
    ftp: *const FTP,
    result_in: CURLcode,
    premature: bool,
) CURLcode {
    var result = result_in;
    if (result != CURLE_OK or premature) {
        // already an error
    } else if (Curl_ftp_acc_get_upload(data)) {
        const infilesize = Curl_ftp_acc_get_infilesize(data);
        const writebytecount = Curl_ftp_acc_get_req_writebytecount(data);
        const crlf = Curl_ftp_acc_get_crlf(data);
        const prefer_ascii = Curl_ftp_acc_get_prefer_ascii(data);
        if ((ftp.transfer == PPTRANSFER_BODY) and
            (infilesize != -1) and
            ((!crlf and !prefer_ascii and (infilesize != writebytecount)) or
                ((crlf or prefer_ascii) and (infilesize > writebytecount))))
        {
            failf(
                data,
                "Uploaded unaligned file size (%lld out of %lld bytes)",
                .{ @as(c_longlong, writebytecount), @as(c_longlong, infilesize) },
            );
            result = CURLE_PARTIAL_FILE;
        }
    } else {
        const req_size = Curl_ftp_acc_get_req_size(data);
        const bytecount = Curl_ftp_acc_get_req_bytecount(data);
        const maxdownload = Curl_ftp_acc_get_req_maxdownload(data);
        if ((req_size != -1) and
            (req_size != bytecount) and
            (maxdownload != bytecount))
        {
            failf(data, "Received only partial file: %lld bytes", .{@as(c_longlong, bytecount)});
            result = CURLE_PARTIAL_FILE;
        } else if (!ftpc.dont_check and bytecount == 0 and (req_size > 0)) {
            failf(data, "No data was received", .{});
            result = CURLE_FTP_COULDNT_RETR_FILE;
        }
    }
    return result;
}

fn ftp_done(
    data: *Curl_easy,
    status: CURLcode,
    premature: bool,
) callconv(.c) CURLcode {
    const conn = Curl_ftp_acc_get_conn(data) orelse return CURLE_OK;
    const ftp = getFtpEasy(data) orelse return CURLE_OK;
    const ftpc = getFtpConn(conn) orelse return CURLE_OK;
    var result: CURLcode = CURLE_OK;

    result = ftp_done_status(data, ftpc, status, premature);

    ftp_done_wildcard(data, ftpc);
    ftp_done_path(data, ftpc, result);
    result = ftp_done_secondary_socket(data, ftpc, result);
    result = ftp_done_control_reply(data, ftpc, ftp, result, premature);
    result = ftp_done_check_partial(data, ftpc, ftp, result, premature);

    ftp.transfer = PPTRANSFER_BODY;
    ftpc.dont_check = false;

    if (status == CURLE_OK and result == CURLE_OK and !premature and Curl_ftp_acc_get_postquote(data) != null) {
        result = ftp_sendquote(data, ftpc, Curl_ftp_acc_get_postquote(data));
    }
    trcFtp(data, "[%s] done, result=%d", .{ ftp_cstate(ftpc), @as(c_int, @intCast(result)) });
    return result;
}

fn ftp_pollset(data: *Curl_easy, ps: *easy_pollset) callconv(.c) CURLcode {
    const conn = Curl_ftp_acc_get_conn(data) orelse return CURLE_OK;
    const ftpc = getFtpConn(conn) orelse return CURLE_OK;
    return Curl_ftp_acc_pp_pollset(data, &ftpc.pp, ps);
}

fn ftp_domore_pollset(data: *Curl_easy, ps: *easy_pollset) callconv(.c) CURLcode {
    const conn = Curl_ftp_acc_get_conn(data) orelse return CURLE_OK;
    const ftpc = getFtpConn(conn) orelse return CURLE_OK;
    trcFtp(data, "[%s] ftp_domore_pollset()", .{ftp_cstate(ftpc)});

    if (ftpc.state != .FTP_STOP) {
        return Curl_ftp_acc_pp_pollset(data, &ftpc.pp, ps);
    }
    if (ftpc.wait_data_conn) {
        const result = Curl_ftp_acc_pollset_add_in(data, ps, Curl_ftp_acc_conn_get_sock(conn, FIRSTSOCKET));
        if (result != CURLE_OK)
            return result;
        return Curl_conn_adjust_pollset(data, conn, ps);
    }
    return CURLE_OK;
}

fn ftp_nb_type(
    data: *Curl_easy,
    ftpc: *ftp_conn,
    ftp: *FTP,
    ascii: bool,
    newstate: ftpstate,
) CURLcode {
    var result: CURLcode = CURLE_OK;
    const want: u8 = if (ascii) 'A' else 'I';

    if (ftpc.transfertype == want) {
        ftp_state(data, ftpc, newstate);
        return ftp_state_type_resp(data, ftpc, ftp, 200, newstate);
    }

    result = ppSendf(data, &ftpc.pp, "TYPE %c", .{@as(c_int, want)});
    if (result == CURLE_OK) {
        ftp_state(data, ftpc, newstate);
        ftpc.transfertype = want;
    }
    return result;
}

fn ftp_dophase_done(
    data: *Curl_easy,
    ftpc: *ftp_conn,
    ftp: *FTP,
    connected: bool,
) CURLcode {
    const conn = Curl_ftp_acc_get_conn(data).?;
    if (connected) {
        var completed: c_int = 0;
        const result = ftp_do_more(data, &completed);
        if (result != CURLE_OK) {
            close_secondarysocket(data, ftpc);
            return result;
        }
    }

    if (ftp.transfer != PPTRANSFER_BODY) {
        Curl_xfer_setup_nop(data);
    } else if (!connected) {
        Curl_ftp_acc_conn_set_do_more(conn, true);
    }

    ftpc.ctl_valid = true;

    return CURLE_OK;
}

fn ftp_doing(data: *Curl_easy, dophase_done: *bool) callconv(.c) CURLcode {
    const conn = Curl_ftp_acc_get_conn(data) orelse return CURLE_FAILED_INIT;
    const ftpc = getFtpConn(conn) orelse return CURLE_FAILED_INIT;
    const ftp = getFtpEasy(data) orelse return CURLE_FAILED_INIT;

    var result = ftp_statemach(data, ftpc, dophase_done);

    if (result != CURLE_OK) {
        trcFtp(data, "[%s] DO phase failed", .{ftp_cstate(ftpc)});
    } else if (dophase_done.*) {
        result = ftp_dophase_done(data, ftpc, ftp, false);

        trcFtp(data, "[%s] DO phase is complete2", .{ftp_cstate(ftpc)});
    }
    return result;
}

fn ftp_quit(data: *Curl_easy, ftpc: *ftp_conn) CURLcode {
    var result: CURLcode = CURLE_OK;
    const conn = Curl_ftp_acc_get_conn(data).?;

    if (ftpc.ctl_valid) {
        trcFtp(data, "sending QUIT to close session", .{});
        result = ppSendf(data, &ftpc.pp, "%s", .{"QUIT"});
        if (result != CURLE_OK) {
            failf(data, "Failure sending QUIT command: %s", .{
                curl_easy_strerror(result),
            });
            ftpc.ctl_valid = false;
            Curl_ftp_acc_connclose(conn);
            ftp_state(data, ftpc, .FTP_STOP);
            return result;
        }
        ftp_state(data, ftpc, .FTP_QUIT);
        result = ftp_block_statemach(data, ftpc);
    }

    return result;
}

fn ftp_disconnect(
    data: *Curl_easy,
    conn: *connectdata,
    dead_connection: bool,
) callconv(.c) CURLcode {
    const ftpc = getFtpConn(conn) orelse return CURLE_FAILED_INIT;

    ftpc.shutdown = true;
    if (dead_connection or Curl_pp_needs_flush(data, &ftpc.pp))
        ftpc.ctl_valid = false;

    _ = ftp_quit(data, ftpc);
    return CURLE_OK;
}

// ============================================================================
// Wildcard Transfers & ftp_do
// ============================================================================

fn wc_data_dtor(ptr: ?*anyopaque) callconv(.c) void {
    const ftpwc_raw = ptr orelse return;
    const ftpwc = fromOpaque(ftp_wc, ftpwc_raw);
    if (ftpwc.parser != null) {
        sasl_rtsp_ftplist.Curl_ftp_parselist_data_free(&ftpwc.parser);
    }
    mem.freeTyped(ftpwc);
}

fn init_wc_data(
    data: *Curl_easy,
    ftpc: *ftp_conn,
    ftp: *FTP,
) CURLcode {
    const path = ftp.path orelse return CURLE_OUT_OF_MEMORY;
    const wildcard = Curl_ftp_acc_get_wildcard(data);
    var result: CURLcode = CURLE_OK;

    const path_len = std.mem.len(path);
    if (std.mem.lastIndexOfScalar(u8, path[0..path_len], '/')) |idx| {
        const last_slash: [*:0]u8 = path + idx + 1;
        if (last_slash[0] == 0) {
            wildcard.state = sasl_rtsp_ftplist.CURLWC_CLEAN;
            return ftp_parse_url_path(data, ftpc, ftp);
        }
        wildcard.pattern = mem.strdup(last_slash);
        if (wildcard.pattern == null)
            return CURLE_OUT_OF_MEMORY;
        last_slash[0] = 0;
    } else {
        if (path[0] != 0) {
            wildcard.pattern = mem.strdup(path);
            if (wildcard.pattern == null)
                return CURLE_OUT_OF_MEMORY;
            path[0] = 0;
        } else {
            wildcard.state = sasl_rtsp_ftplist.CURLWC_CLEAN;
            return ftp_parse_url_path(data, ftpc, ftp);
        }
    }

    var ok = false;
    defer if (!ok) {
        if (wildcard.pattern) |pat| {
            mem.free(pat);
            wildcard.pattern = null;
        }
        wildcard.dtor = null;
        wildcard.ftpwc = null;
    };

    const ftpwc = mem.create(ftp_wc) orelse return CURLE_OUT_OF_MEMORY;
    defer if (!ok) mem.freeTyped(ftpwc);

    ftpwc.parser = sasl_rtsp_ftplist.Curl_ftp_parselist_data_alloc();
    if (ftpwc.parser == null) {
        return CURLE_OUT_OF_MEMORY;
    }
    defer if (!ok) sasl_rtsp_ftplist.Curl_ftp_parselist_data_free(&ftpwc.parser);

    wildcard.ftpwc = ftpwc;
    wildcard.dtor = wc_data_dtor;

    if (Curl_ftp_acc_get_ftp_filemethod(data) == FTPFILE_NOCWD)
        Curl_ftp_acc_set_ftp_filemethod(data, FTPFILE_MULTICWD);

    result = ftp_parse_url_path(data, ftpc, ftp);
    if (result != CURLE_OK) {
        return result;
    }

    wildcard.path = mem.strdup(ftp.path.?);
    if (wildcard.path == null) {
        return CURLE_OUT_OF_MEMORY;
    }

    ok = true;
    infof(data, "Wildcard - Parsing started", .{});
    return CURLE_OK;
}

extern fn curl_easy_escape(curl: ?*anyopaque, string: ?[*]const u8, length: c_int) callconv(.c) ?[*:0]u8;

fn wc_statemach(
    data: *Curl_easy,
    ftpc: *ftp_conn,
    ftp: *FTP,
) CURLcode {
    const wildcard = Curl_ftp_acc_get_wildcard(data);
    var result: CURLcode = CURLE_OK;

    while (true) {
        switch (wildcard.state) {
            sasl_rtsp_ftplist.CURLWC_INIT => {
                result = init_wc_data(data, ftpc, ftp);
                if (wildcard.state == sasl_rtsp_ftplist.CURLWC_CLEAN)
                    return result;
                wildcard.state = if (result != CURLE_OK)
                    sasl_rtsp_ftplist.CURLWC_ERROR
                else
                    sasl_rtsp_ftplist.CURLWC_MATCHING;
                return result;
            },
            sasl_rtsp_ftplist.CURLWC_MATCHING => {
                const ftpwc = wildcard.ftpwc.?;
                wildcard.state = sasl_rtsp_ftplist.CURLWC_DOWNLOADING;

                if (sasl_rtsp_ftplist.Curl_ftp_parselist_geterror(ftpwc.parser.?) != 0) {
                    wildcard.state = sasl_rtsp_ftplist.CURLWC_CLEAN;
                    continue;
                }
                if (containers.Curl_llist_count(&wildcard.filelist) == 0) {
                    wildcard.state = sasl_rtsp_ftplist.CURLWC_CLEAN;
                    return CURLE_REMOTE_FILE_NOT_FOUND;
                }
                continue;
            },
            sasl_rtsp_ftplist.CURLWC_DOWNLOADING => {
                const list = &wildcard.filelist;
                const head = containers.Curl_llist_head(list).?;
                const finfo = collections.llistElemTyped(curl_fileinfo, head).?;

                const enc = curl_easy_escape(null, finfo.filename, 0) orelse return CURLE_OUT_OF_MEMORY;
                const tmp_path = curl_maprintf("%s%s", wildcard.path.?, enc);
                mem.free(enc);
                if (tmp_path == null)
                    return CURLE_OUT_OF_MEMORY;

                if (ftp.pathalloc) |pa|
                    mem.free(pa);
                ftp.pathalloc = tmp_path;
                ftp.path = tmp_path;

                infof(data, "Wildcard - START of \"%s\"", .{finfo.filename.?});
                if (Curl_ftp_acc_has_chunk_bgn(data)) {
                    const userresponse = Curl_ftp_acc_call_chunk_bgn(
                        data,
                        finfo,
                        @intCast(containers.Curl_llist_count(list)),
                    );
                    switch (userresponse) {
                        CURL_CHUNK_BGN_FUNC_SKIP => {
                            infof(data, "Wildcard - \"%s\" skipped by user", .{finfo.filename.?});
                            wildcard.state = sasl_rtsp_ftplist.CURLWC_SKIP;
                            continue;
                        },
                        CURL_CHUNK_BGN_FUNC_FAIL => return CURLE_CHUNK_FAILED,
                        else => {},
                    }
                }

                if (finfo.filetype != sasl_rtsp_ftplist.CURLFILETYPE_FILE) {
                    wildcard.state = sasl_rtsp_ftplist.CURLWC_SKIP;
                    continue;
                }

                if ((finfo.flags & sasl_rtsp_ftplist.CURLFINFOFLAG_KNOWN_SIZE) != 0)
                    ftpc.known_filesize = finfo.size;

                result = ftp_parse_url_path(data, ftpc, ftp);
                if (result != CURLE_OK)
                    return result;

                containers.Curl_node_remove(containers.Curl_llist_head(list).?);

                if (containers.Curl_llist_count(list) == 0) {
                    wildcard.state = sasl_rtsp_ftplist.CURLWC_CLEAN;
                    return CURLE_OK;
                }
                return result;
            },
            sasl_rtsp_ftplist.CURLWC_SKIP => {
                if (Curl_ftp_acc_has_chunk_end(data)) {
                    Curl_ftp_acc_call_chunk_end(data);
                }
                if (containers.Curl_llist_head(&wildcard.filelist)) |node| {
                    containers.Curl_node_remove(node);
                }
                wildcard.state = if (containers.Curl_llist_count(&wildcard.filelist) == 0)
                    sasl_rtsp_ftplist.CURLWC_CLEAN
                else
                    sasl_rtsp_ftplist.CURLWC_DOWNLOADING;
                continue;
            },
            sasl_rtsp_ftplist.CURLWC_CLEAN => {
                result = CURLE_OK;
                if (wildcard.ftpwc) |ftpwc| {
                    result = sasl_rtsp_ftplist.Curl_ftp_parselist_geterror(ftpwc.parser.?);
                }
                wildcard.state = if (result != CURLE_OK)
                    sasl_rtsp_ftplist.CURLWC_ERROR
                else
                    sasl_rtsp_ftplist.CURLWC_DONE;
                return result;
            },
            sasl_rtsp_ftplist.CURLWC_DONE,
            sasl_rtsp_ftplist.CURLWC_ERROR,
            sasl_rtsp_ftplist.CURLWC_CLEAR,
            => {
                if (wildcard.dtor) |dtor_fn| {
                    dtor_fn(wildcard.ftpwc);
                    wildcard.ftpwc = null;
                }
                return result;
            },
            else => return result,
        }
    }
}

fn ftp_regular_transfer(
    data: *Curl_easy,
    ftpc: *ftp_conn,
    ftp: *FTP,
    dophase_done: *bool,
) CURLcode {
    var result: CURLcode = CURLE_OK;
    var connected: bool = false;

    Curl_ftp_acc_set_req_size(data, -1);
    Curl_pgrsReset(data);

    ftpc.ctl_valid = true;

    result = ftp_perform(data, ftpc, ftp, &connected, dophase_done);

    if (result == CURLE_OK) {
        if (!dophase_done.*)
            return CURLE_OK;

        result = ftp_dophase_done(data, ftpc, ftp, connected);
        if (result != CURLE_OK)
            return result;
    } else {
        freedirs(ftpc);
    }

    return result;
}

fn ftp_do(data: *Curl_easy, done: *bool) callconv(.c) CURLcode {
    var result: CURLcode = CURLE_OK;
    const conn = Curl_ftp_acc_get_conn(data) orelse return CURLE_FAILED_INIT;
    const ftpc = getFtpConn(conn) orelse return CURLE_FAILED_INIT;
    const ftp = getFtpEasy(data) orelse return CURLE_FAILED_INIT;

    done.* = false;
    ftpc.wait_data_conn = false;

    if (prefer_lf_lineends) {
        var ftp_lc_writer: ?*Curl_cwriter = null;
        result = Curl_cwriter_create(&ftp_lc_writer, data, &ftp_cw_lc, CURL_CW_CONTENT_DECODE);
        if (result != CURLE_OK)
            return result;

        result = Curl_cwriter_add(data, ftp_lc_writer.?);
        if (result != CURLE_OK) {
            Curl_cwriter_free(data, ftp_lc_writer);
            return result;
        }
    }

    if (Curl_ftp_acc_get_wildcardmatch(data)) {
        result = wc_statemach(data, ftpc, ftp);
        const wc = Curl_ftp_acc_get_wildcard(data);
        if (wc.state == sasl_rtsp_ftplist.CURLWC_SKIP or
            wc.state == sasl_rtsp_ftplist.CURLWC_DONE)
        {
            return CURLE_OK;
        }
        if (result != CURLE_OK)
            return result;
    } else {
        result = ftp_parse_url_path(data, ftpc, ftp);
        if (result != CURLE_OK)
            return result;
    }

    result = ftp_regular_transfer(data, ftpc, ftp, done);

    return result;
}

// ============================================================================
// Connection Matching & Setup
// ============================================================================

fn ftp_easy_dtor(key: ?*const anyopaque, klen: usize, entry: ?*anyopaque) callconv(.c) void {
    _ = key;
    _ = klen;
    const ftp_raw = entry orelse return;
    const ftp = fromOpaque(FTP, ftp_raw);
    if (ftp.pathalloc) |pa|
        mem.free(pa);
    mem.freeTyped(ftp);
}

fn ftp_conn_dtor(key: ?*const anyopaque, klen: usize, entry: ?*anyopaque) callconv(.c) void {
    _ = key;
    _ = klen;
    const ftpc_raw = entry orelse return;
    const ftpc = fromOpaque(ftp_conn, ftpc_raw);
    freedirs(ftpc);
    if (ftpc.account) |acct|
        mem.free(acct);
    if (ftpc.alternative_to_user) |alt|
        mem.free(alt);
    if (ftpc.entrypath) |ep|
        mem.free(ep);
    if (ftpc.prevpath) |prevp|
        mem.free(prevp);
    if (ftpc.server_os) |os|
        mem.free(os);
    _ = Curl_pp_disconnect(&ftpc.pp);
    mem.freeTyped(ftpc);
}

fn type_url_check(data: *Curl_easy, ftp: *FTP) void {
    const path = ftp.path orelse return;
    const len = std.mem.len(path);
    if (len >= 7 and std.mem.eql(u8, path[len - 7 .. len - 1], ";type=")) {
        const command = primitives.rawToupper(path[len - 1]);
        path[len - 7] = 0;

        switch (command) {
            'A' => Curl_ftp_acc_set_prefer_ascii(data, true),
            'D' => Curl_ftp_acc_set_list_only(data, true),
            else => Curl_ftp_acc_set_prefer_ascii(data, false),
        }
    }
}

fn ftp_setup_connection(data: *Curl_easy, conn: *connectdata) callconv(.c) CURLcode {
    const result: CURLcode = CURLE_OK;

    const ftp = mem.create(FTP) orelse return CURLE_OUT_OF_MEMORY;
    if (Curl_meta_set(data, CURL_META_FTP_EASY, ftp, ftp_easy_dtor) != CURLE_OK)
        return CURLE_OUT_OF_MEMORY;

    const ftpc = mem.create(ftp_conn) orelse return CURLE_OUT_OF_MEMORY;
    if (Curl_conn_meta_set(conn, CURL_META_FTP_CONN, ftpc, ftp_conn_dtor) != CURLE_OK)
        return CURLE_OUT_OF_MEMORY;
    var ok = false;
    defer if (!ok) Curl_conn_meta_remove(conn, CURL_META_FTP_CONN);

    if (Curl_ftp_acc_get_str_ftp_account(data)) |acct_str| {
        ftpc.account = mem.strdup(acct_str);
        if (ftpc.account == null) {
            return CURLE_OUT_OF_MEMORY;
        }
    }
    if (Curl_ftp_acc_get_str_ftp_alternative_to_user(data)) |alt_str| {
        ftpc.alternative_to_user = mem.strdup(alt_str);
        if (ftpc.alternative_to_user == null) {
            return CURLE_OUT_OF_MEMORY;
        }
    }

    ftp.path = Curl_ftp_acc_get_up_path_after_slash(data);
    type_url_check(data, ftp);

    ftp.transfer = PPTRANSFER_BODY;
    ftp.downloadsize = 0;
    ftpc.known_filesize = -1;
    ftpc.use_ssl = Curl_ftp_acc_get_use_ssl(data);
    ftpc.ccc = Curl_ftp_acc_get_ftp_ccc(data);

    ok = true;
    trcFtp(data, "[%s] setup connection -> %d", .{ ftp_cstate(ftpc), @as(c_int, @intCast(result)) });
    return result;
}

pub export fn Curl_ftp_conns_match(
    needle: *connectdata,
    conn: *connectdata,
) callconv(.c) bool {
    const nftpc = getFtpConn(needle) orelse return false;
    const cftpc = getFtpConn(conn) orelse return false;

    if (primitives.Curl_timestrcmp(nftpc.account, cftpc.account) != 0 or
        primitives.Curl_timestrcmp(nftpc.alternative_to_user, cftpc.alternative_to_user) != 0 or
        (nftpc.ccc != cftpc.ccc))
    {
        return false;
    }

    return switch (nftpc.use_ssl) {
        CURLUSESSL_TRY => cftpc.use_ssl != CURLUSESSL_NONE,
        else => nftpc.use_ssl == cftpc.use_ssl,
    };
}

// ============================================================================
// Exported Protocol Handler Table (Curl_protocol_ftp)
// ============================================================================

pub export const Curl_protocol_ftp = CurlProtocol{
    .setup_connection = ftp_setup_connection,
    .do_it = ftp_do,
    .done = ftp_done,
    .do_more = ftp_do_more,
    .connect_it = ftp_connect,
    .connecting = ftp_multi_statemach,
    .doing = ftp_doing,
    .proto_pollset = ftp_pollset,
    .doing_pollset = ftp_pollset,
    .domore_pollset = ftp_domore_pollset,
    .perform_pollset = null,
    .disconnect = ftp_disconnect,
    .write_resp = null,
    .write_resp_hd = null,
    .connection_is_dead = null,
    .attach = null,
    .follow = null,
};

// ============================================================================
// Unit Tests
// ============================================================================

test "ftp_213_date parses valid and rejects invalid timestamps" {
    var year: c_int = 0;
    var month: c_int = 0;
    var day: c_int = 0;
    var hour: c_int = 0;
    var minute: c_int = 0;
    var second: c_int = 0;

    try std.testing.expect(ftp_213_date("20240519143059\r\n", &year, &month, &day, &hour, &minute, &second));
    try std.testing.expectEqual(@as(c_int, 2024), year);
    try std.testing.expectEqual(@as(c_int, 5), month);
    try std.testing.expectEqual(@as(c_int, 19), day);
    try std.testing.expectEqual(@as(c_int, 14), hour);
    try std.testing.expectEqual(@as(c_int, 30), minute);
    try std.testing.expectEqual(@as(c_int, 59), second);

    try std.testing.expect(ftp_213_date("20241231235960.123\r\n", &year, &month, &day, &hour, &minute, &second));
    try std.testing.expectEqual(@as(c_int, 60), second);

    try std.testing.expect(!ftp_213_date("20241301000000\r\n", &year, &month, &day, &hour, &minute, &second));
    try std.testing.expect(ftp_213_date("19980020114234\r\n", &year, &month, &day, &hour, &minute, &second));
    try std.testing.expect(!ftp_213_date("20240532000000\r\n", &year, &month, &day, &hour, &minute, &second));
    try std.testing.expect(!ftp_213_date("20240519240000\r\n", &year, &month, &day, &hour, &minute, &second));
    try std.testing.expect(!ftp_213_date("20240519146000\r\n", &year, &month, &day, &hour, &minute, &second));
    try std.testing.expect(!ftp_213_date("20240519143061\r\n", &year, &month, &day, &hour, &minute, &second));
    try std.testing.expect(!ftp_213_date("2024051914305\r\n", &year, &month, &day, &hour, &minute, &second));
}

test "ftp_endofresp detects FTP response status line" {
    var code: c_int = 0;
    try std.testing.expect(ftp_endofresp(null, null, "220 Welcome to FTP\r\n", 20, &code));
    try std.testing.expectEqual(@as(c_int, 220), code);

    try std.testing.expect(!ftp_endofresp(null, null, "220-Multiline banner\r\n", 22, &code));
    try std.testing.expect(!ftp_endofresp(null, null, "220", 3, &code));
}

test "match_pasv_6nums parses 6 comma-separated octets" {
    var ip: [6]c_uint = @splat(0);
    try std.testing.expect(match_pasv_6nums("192,168,1,42,195,80)", &ip));
    try std.testing.expectEqual(@as(c_uint, 192), ip[0]);
    try std.testing.expectEqual(@as(c_uint, 168), ip[1]);
    try std.testing.expectEqual(@as(c_uint, 1), ip[2]);
    try std.testing.expectEqual(@as(c_uint, 42), ip[3]);
    try std.testing.expectEqual(@as(c_uint, 195), ip[4]);
    try std.testing.expectEqual(@as(c_uint, 80), ip[5]);

    try std.testing.expect(!match_pasv_6nums("256,0,0,1,4,51", &ip));
    try std.testing.expect(!match_pasv_6nums("127,0,0,1,4", &ip));
}

test "unit1668 ftp_213_date comprehensive vector suite" {
    const Spec = struct {
        in: [*:0]const u8,
        rc: bool,
        y: c_int = 0,
        m: c_int = 0,
        d: c_int = 0,
        h: c_int = 0,
        min: c_int = 0,
        s: c_int = 0,
    };
    const specs = [_]Spec{
        .{ .in = "19980320114234.123", .rc = true, .y = 1998, .m = 3, .d = 20, .h = 11, .min = 42, .s = 34 },
        .{ .in = "19980320114234.000", .rc = true, .y = 1998, .m = 3, .d = 20, .h = 11, .min = 42, .s = 34 },
        .{ .in = "19980320114234.aaa", .rc = true, .y = 1998, .m = 3, .d = 20, .h = 11, .min = 42, .s = 34 },
        .{ .in = "19980320114234", .rc = true, .y = 1998, .m = 3, .d = 20, .h = 11, .min = 42, .s = 34 },
        .{ .in = "09980320114234", .rc = true, .y = 998, .m = 3, .d = 20, .h = 11, .min = 42, .s = 34 },
        .{ .in = "19980020114234", .rc = true, .y = 1998, .m = 0, .d = 20, .h = 11, .min = 42, .s = 34 },
        .{ .in = "19980300114234", .rc = true, .y = 1998, .m = 3, .d = 0, .h = 11, .min = 42, .s = 34 },
        .{ .in = "19980231114234", .rc = true, .y = 1998, .m = 2, .d = 31, .h = 11, .min = 42, .s = 34 },
        .{ .in = "19980320256565", .rc = false },
        .{ .in = "19980320236565", .rc = false },
        .{ .in = "19980320235865", .rc = false },
        .{ .in = ":9980231114234", .rc = false },
        .{ .in = "a9980231114234", .rc = false },
        .{ .in = "19980320114234--", .rc = true, .y = 1998, .m = 3, .d = 20, .h = 11, .min = 42, .s = 34 },
        .{ .in = " 19980320114234", .rc = false },
        .{ .in = "1998032011423", .rc = false },
        .{ .in = "", .rc = false },
        .{ .in = "19980320114234\xff", .rc = true, .y = 1998, .m = 3, .d = 20, .h = 11, .min = 42, .s = 34 },
        .{ .in = "1998\x7e320114234\xff", .rc = false },
        .{ .in = "1998\x80320114234\xff", .rc = false },
    };
    for (specs) |spec| {
        var year: c_int = 0;
        var month: c_int = 0;
        var day: c_int = 0;
        var hour: c_int = 0;
        var minute: c_int = 0;
        var second: c_int = 0;
        const rc = ftp_213_date(spec.in, &year, &month, &day, &hour, &minute, &second);
        try std.testing.expectEqual(spec.rc, rc);
        if (rc) {
            try std.testing.expectEqual(spec.y, year);
            try std.testing.expectEqual(spec.m, month);
            try std.testing.expectEqual(spec.d, day);
            try std.testing.expectEqual(spec.h, hour);
            try std.testing.expectEqual(spec.min, minute);
            try std.testing.expectEqual(spec.s, second);
        }
    }
}

test "Curl_protocol_ftp handler table and pathlen/pathpiece helpers" {
    try std.testing.expect(Curl_protocol_ftp.setup_connection != null);
    try std.testing.expect(Curl_protocol_ftp.do_it != null);
    try std.testing.expect(Curl_protocol_ftp.done != null);
    try std.testing.expect(Curl_protocol_ftp.do_more != null);
    try std.testing.expect(Curl_protocol_ftp.connect_it != null);
    try std.testing.expect(Curl_protocol_ftp.connecting != null);
    try std.testing.expect(Curl_protocol_ftp.doing != null);
    try std.testing.expect(Curl_protocol_ftp.proto_pollset != null);
    try std.testing.expect(Curl_protocol_ftp.doing_pollset != null);
    try std.testing.expect(Curl_protocol_ftp.domore_pollset != null);
    try std.testing.expect(Curl_protocol_ftp.disconnect != null);
}
