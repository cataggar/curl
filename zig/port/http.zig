// ============================================================================
// Port of lib/http.c (lines 1-5136):
//   - Core HTTP/1.x, HTTP/2, HTTP/3 request/response engine
//   - HTTP authentication negotiation (Basic, Bearer, Digest, NTLM, SPNEGO,
//     AWS SigV4, HTTP Message Signatures)
//   - Redirect handling (Curl_http_follow), custom header management,
//     100-continue reader (cr_exp100), range/resume, time-conditions,
//     status-line & response header parsing, httpreq / http_resp helpers,
//     H2 request conversion (Curl_http_req_to_h2), and Curl_protocol_http
// ============================================================================

const std = @import("std");
const mem = @import("mem.zig");
const containers = @import("containers.zig");
const curlx_parse = @import("curlx_parse.zig");
const curlx_time_net = @import("curlx_time_net.zig");
const urlapi = @import("urlapi.zig");
const io_buffers = @import("io_buffers.zig");
const headers_sock = @import("headers_sock.zig");
const sendf = @import("sendf.zig");
const http1_options = @import("http1_options.zig");

pub const CURLcode = c_uint;
pub const CURLUcode = urlapi.CURLUcode;
pub const CURLU = urlapi.Curl_URL;
pub const curl_off_t = i64;
pub const time_t = i64;
pub const timediff_t = i64;
pub const curl_socket_t = headers_sock.curl_socket_t;
pub const curl_prot_t = u64;
pub const Curl_HttpReq = c_uint;
pub const followtype = c_uint;

pub const CURLE_OK: CURLcode = 0;
pub const CURLE_UNSUPPORTED_PROTOCOL: CURLcode = 1;
pub const CURLE_FAILED_INIT: CURLcode = 2;
pub const CURLE_URL_MALFORMAT: CURLcode = 3;
pub const CURLE_NOT_BUILT_IN: CURLcode = 4;
pub const CURLE_WEIRD_SERVER_REPLY: CURLcode = 8;
pub const CURLE_REMOTE_ACCESS_DENIED: CURLcode = 9;
pub const CURLE_HTTP_RETURNED_ERROR: CURLcode = 22;
pub const CURLE_WRITE_ERROR: CURLcode = 23;
pub const CURLE_UPLOAD_FAILED: CURLcode = 25;
pub const CURLE_READ_ERROR: CURLcode = 26;
pub const CURLE_OUT_OF_MEMORY: CURLcode = 27;
pub const CURLE_RANGE_ERROR: CURLcode = 33;
pub const CURLE_BAD_FUNCTION_ARGUMENT: CURLcode = 43;
pub const CURLE_TOO_MANY_REDIRECTS: CURLcode = 47;
pub const CURLE_GOT_NOTHING: CURLcode = 52;
pub const CURLE_SEND_ERROR: CURLcode = 55;
pub const CURLE_RECV_ERROR: CURLcode = 56;
pub const CURLE_FILESIZE_EXCEEDED: CURLcode = 63;
pub const CURLE_TOO_LARGE: CURLcode = 100;

pub const HTTPREQ_GET: Curl_HttpReq = 0;
pub const HTTPREQ_POST: Curl_HttpReq = 1;
pub const HTTPREQ_POST_FORM: Curl_HttpReq = 2;
pub const HTTPREQ_POST_MIME: Curl_HttpReq = 3;
pub const HTTPREQ_PUT: Curl_HttpReq = 4;
pub const HTTPREQ_HEAD: Curl_HttpReq = 5;

pub const FOLLOW_NONE: followtype = 0;
pub const FOLLOW_FAKE: followtype = 1;
pub const FOLLOW_RETRY: followtype = 2;
pub const FOLLOW_REDIR: followtype = 3;

pub const CURLFOLLOW_ALL: u8 = 1;
pub const CURLFOLLOW_OBEYCODE: u8 = 2;
pub const CURLFOLLOW_FIRSTONLY: u8 = 3;

pub const CURL_HTTP_VERSION_NONE: u8 = 0;
pub const CURL_HTTP_VERSION_1_0: u8 = 1;
pub const CURL_HTTP_VERSION_1_1: u8 = 2;
pub const CURL_HTTP_VERSION_2_0: u8 = 3;
pub const CURL_HTTP_VERSION_2TLS: u8 = 4;
pub const CURL_HTTP_VERSION_2_PRIOR_KNOWLEDGE: u8 = 5;
pub const CURL_HTTP_VERSION_3: u8 = 30;
pub const CURL_HTTP_VERSION_3ONLY: u8 = 31;

pub const CURL_HTTP_V1x: u8 = 1 << 0;
pub const CURL_HTTP_V2x: u8 = 1 << 1;
pub const CURL_HTTP_V3x: u8 = 1 << 2;

pub const CURLAUTH_NONE: u32 = 0;
pub const CURLAUTH_BASIC: u32 = 1 << 0;
pub const CURLAUTH_DIGEST: u32 = 1 << 1;
pub const CURLAUTH_NEGOTIATE: u32 = 1 << 2;
pub const CURLAUTH_NTLM: u32 = 1 << 3;
pub const CURLAUTH_DIGEST_IE: u32 = 1 << 4;
pub const CURLAUTH_NTLM_WB: u32 = 1 << 5;
pub const CURLAUTH_BEARER: u32 = 1 << 6;
pub const CURLAUTH_AWS_SIGV4: u32 = 1 << 7;
pub const CURLAUTH_HTTPSIG: u32 = 1 << 8;
pub const CURLAUTH_PICKNONE: u32 = 1 << 30;
pub const CURLAUTH_ONLY: u32 = 1 << 31;

pub const CURL_TIMECOND_NONE: u8 = 0;
pub const CURL_TIMECOND_IFMODSINCE: u8 = 1;
pub const CURL_TIMECOND_IFUNMODSINCE: u8 = 2;
pub const CURL_TIMECOND_LASTMOD: u8 = 3;

pub const UPGR101_NONE: u8 = 0;
pub const UPGR101_WS: u8 = 1;
pub const UPGR101_H2: u8 = 2;
pub const UPGR101_RECEIVED: u8 = 3;

pub const EXP100_SEND_DATA: c_uint = 0;
pub const EXP100_AWAITING_CONTINUE: c_uint = 1;
pub const EXP100_SENDING_REQUEST: c_uint = 2;
pub const EXP100_FAILED: c_uint = 3;

pub const CONNCTRL_CONN_KEEP: c_int = 0;
pub const CONNCTRL_CONN_CLOSE: c_int = 1;
pub const CONNCTRL_STREAM_CLOSE: c_int = 2;

pub const FIRSTSOCKET: i8 = 0;
pub const EXPIRE_100_TIMEOUT: c_uint = 0;
pub const TIMER_REDIRECT: c_uint = 10;
pub const CURLINFO_HEADER_IN: c_uint = 1;

pub const DYN_HTTP_REQUEST: usize = 1024 * 1024;
pub const MAX_HTTP_RESP_HEADER_SIZE: usize = 300 * 1024;
pub const CURL_MAX_HTTP_HEADER: usize = 100 * 1024;
pub const EXPECT_100_THRESHOLD: curl_off_t = 1024 * 1024;
pub const CURL_OFF_T_MAX: curl_off_t = std.math.maxInt(curl_off_t);

pub const CURLPROTO_HTTP: curl_prot_t = 1 << 0;
pub const CURLPROTO_HTTPS: curl_prot_t = 1 << 1;
pub const CURLPROTO_FTP: curl_prot_t = 1 << 2;
pub const CURLPROTO_RTSP: curl_prot_t = 1 << 18;
pub const CURLPROTO_WS: curl_prot_t = @as(curl_prot_t, 1) << 30;
pub const CURLPROTO_WSS: curl_prot_t = @as(curl_prot_t, 1) << 31;
pub const PROTO_FAMILY_HTTP: curl_prot_t = CURLPROTO_HTTP | CURLPROTO_HTTPS | CURLPROTO_WS | CURLPROTO_WSS;

// Feature bits from Curl_http_acc_features()
const FEAT_SPNEGO: c_uint = 1 << 0;
const FEAT_NTLM: c_uint = 1 << 1;
const FEAT_DIGEST_AUTH: c_uint = 1 << 2;
const FEAT_AWS: c_uint = 1 << 3;
const FEAT_HTTPSIG: c_uint = 1 << 4;
const FEAT_PROXY: c_uint = 1 << 5;
const FEAT_SSL: c_uint = 1 << 6;
const FEAT_NGHTTP2: c_uint = 1 << 7;
const FEAT_WEBSOCKETS: c_uint = 1 << 8;
const FEAT_ALTSVC: c_uint = 1 << 9;
const FEAT_HSTS: c_uint = 1 << 10;
const FEAT_COOKIES: c_uint = 1 << 11;
const FEAT_LIBZ: c_uint = 1 << 12;
const FEAT_MIME: c_uint = 1 << 13;
const FEAT_FORM_API: c_uint = 1 << 14;
const FEAT_HEADERS_API: c_uint = 1 << 15;
const FEAT_NETRC: c_uint = 1 << 16;
const FEAT_DEBUGBUILD: c_uint = 1 << 17;
const FEAT_HTTP_AUTH: c_uint = 1 << 18;
const FEAT_BASIC_AUTH: c_uint = 1 << 19;
const FEAT_BEARER_AUTH: c_uint = 1 << 20;
const FEAT_HTTP2: c_uint = 1 << 21;
const FEAT_HTTP3: c_uint = 1 << 22;
const FEAT_PARSEDATE: c_uint = 1 << 23;
const FEAT_RTSP: c_uint = 1 << 24;

inline fn hasFeat(bit: c_uint) bool {
    return (Curl_http_acc_features() & bit) != 0;
}

pub const Curl_easy = sendf.CurlEasy;
pub const connectdata = opaque {};
pub const Curl_multi = opaque {};
pub const http_negotiation = opaque {};
pub const auth = opaque {};
pub const Curl_creds = opaque {};
pub const Curl_peer = opaque {};
pub const easy_pollset = headers_sock.EasyPollset;
pub const dynbuf = containers.dynbuf;
pub const dynhds = io_buffers.dynhds;
pub const dynhds_entry = io_buffers.dynhds_entry;
pub const bufref = containers.bufref;
pub const curl_slist = containers.curl_slist;
pub const Curl_str = curlx_parse.Curl_str;
pub const Curltime = curlx_time_net.Curltime;

pub const Curl_protocol = extern struct {
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
    write_resp_hd: ?*const fn (data: *Curl_easy, hd: [*:0]const u8, hdlen: usize, is_eos: bool) callconv(.c) CURLcode,
    connection_is_dead: ?*const fn (data: *Curl_easy, conn: *connectdata) callconv(.c) bool,
    attach: ?*const fn (data: *Curl_easy, conn: *connectdata) callconv(.c) void,
    follow: ?*const fn (data: *Curl_easy, newurl: [*:0]const u8, ftype: followtype) callconv(.c) CURLcode,
};

pub const Tm = extern struct {
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
extern fn curl_free(p: ?*anyopaque) callconv(.c) void;
extern fn curl_url_strerror(err: CURLUcode) callconv(.c) [*:0]const u8;
extern fn Curl_uc_to_curlcode(uc: CURLUcode) callconv(.c) CURLcode;
extern fn curl_maprintf(format: [*:0]const u8, ...) callconv(.c) ?[*:0]u8;
extern fn curlx_memdup0(src: ?[*]const u8, length: usize) callconv(.c) ?[*:0]u8;
extern fn curl_strnequal(s1: ?[*]const u8, s2: ?[*]const u8, n: usize) callconv(.c) c_int;
extern fn curl_strequal(s1: ?[*]const u8, s2: ?[*]const u8) callconv(.c) c_int;
extern fn curlx_gmtime(intime: time_t, store: *Tm) callconv(.c) CURLcode;
extern fn Curl_getdate_capped(p: ?[*:0]const u8, tp: *time_t) callconv(.c) c_int;

extern fn curlx_str_until(linep: *?[*:0]const u8, out: *Curl_str, max: usize, delim: u8) callconv(.c) c_int;
extern fn curlx_str_untilnl(linep: *?[*:0]const u8, out: *Curl_str, max: usize) callconv(.c) c_int;
extern fn curlx_str_quotedword(linep: *?[*:0]const u8, out: *Curl_str, max: usize) callconv(.c) c_int;
extern fn curlx_str_single(linep: *?[*:0]const u8, byte: u8) callconv(.c) c_int;
extern fn curlx_str_number(linep: *?[*:0]const u8, nump: *i64, max: i64) callconv(.c) c_int;
extern fn curlx_str_numblanks(str: *?[*:0]const u8, num: *i64) callconv(.c) c_int;
extern fn curlx_str_newline(linep: *?[*:0]const u8) callconv(.c) c_int;
extern fn curlx_str_casecompare(str: *Curl_str, check: ?[*:0]const u8) callconv(.c) c_int;
extern fn curlx_str_cmp(str: *Curl_str, check: ?[*:0]const u8) callconv(.c) c_int;
extern fn curlx_str_cspn(linep: *?[*:0]const u8, out: *Curl_str, reject: [*:0]const u8) callconv(.c) c_int;
extern fn curlx_str_trimblanks(out: *Curl_str) callconv(.c) void;
extern fn curlx_str_passblanks(linep: *?[*:0]const u8) callconv(.c) void;

extern fn Curl_bufref_free(br: *bufref) callconv(.c) void;
extern fn Curl_bufref_ptr(br: *const bufref) callconv(.c) ?[*:0]const u8;
extern fn Curl_bufref_set(br: *bufref, ptr: ?*const anyopaque, len: usize, dtor: ?*const fn (?*anyopaque) callconv(.c) void) callconv(.c) void;

inline fn Curl_bufref_dup(br: *const bufref) ?[*:0]u8 {
    const p = Curl_bufref_ptr(br) orelse return null;
    return mem.strdup(p);
}

pub const httpreq = http1_options.httpreq;

pub const http_resp = extern struct {
    status: c_int,
    description: ?[*:0]u8,
    headers: dynhds,
    trailers: dynhds,
    prev: ?*http_resp,
};

// ============================================================================
// Extern C Accessors (from lib/multi.c lines 13690-15725) & Core Helpers
// ============================================================================

extern fn Curl_http_acc_features() callconv(.c) c_uint;
extern fn Curl_http_acc_conn(data: *Curl_easy) callconv(.c) ?*connectdata;
extern fn Curl_http_acc_multi(data: *Curl_easy) callconv(.c) ?*Curl_multi;
extern fn Curl_http_acc_conn_firstsocket(conn: *connectdata) callconv(.c) curl_socket_t;
extern fn Curl_http_acc_conn_httpversion_seen(conn: *const connectdata) callconv(.c) u8;
extern fn Curl_http_acc_conn_set_httpversion_seen(conn: *connectdata, v: u8) callconv(.c) void;
extern fn Curl_http_acc_conn_scheme_protocol(conn: *const connectdata) callconv(.c) curl_prot_t;
extern fn Curl_http_acc_conn_scheme_family(conn: *const connectdata) callconv(.c) curl_prot_t;
extern fn Curl_http_acc_conn_bits_origin_is_proxy(conn: *const connectdata) callconv(.c) bool;
extern fn Curl_http_acc_conn_bits_close(conn: *const connectdata) callconv(.c) bool;
extern fn Curl_http_acc_conn_bits_reuse(conn: *const connectdata) callconv(.c) bool;
extern fn Curl_http_acc_conn_bits_retry(conn: *const connectdata) callconv(.c) bool;
extern fn Curl_http_acc_conn_bits_altused(conn: *const connectdata) callconv(.c) bool;
extern fn Curl_http_acc_conn_bits_upgrade_in_progress(conn: *const connectdata) callconv(.c) bool;
extern fn Curl_http_acc_conn_set_bits_upgrade_in_progress(conn: *connectdata, v: bool) callconv(.c) void;
extern fn Curl_http_acc_conn_via_peer_hostname(conn: *const connectdata) callconv(.c) ?[*:0]const u8;
extern fn Curl_http_acc_conn_via_peer_port(conn: *const connectdata) callconv(.c) c_int;
extern fn Curl_http_acc_conn_http_proxy_peer(conn: *const connectdata) callconv(.c) ?*Curl_peer;
extern fn Curl_http_acc_conn_http_proxy_creds(conn: *const connectdata) callconv(.c) ?*Curl_creds;
extern fn Curl_http_acc_creds_user(creds: ?*const Curl_creds) callconv(.c) ?[*:0]const u8;
extern fn Curl_http_acc_creds_passwd(creds: ?*const Curl_creds) callconv(.c) ?[*:0]const u8;
extern fn Curl_http_acc_creds_has_user_or_pass(creds: ?*const Curl_creds) callconv(.c) bool;
extern fn Curl_http_acc_creds_has_oauth_bearer(creds: ?*const Curl_creds) callconv(.c) bool;
extern fn Curl_http_acc_creds_oauth_bearer(creds: ?*const Curl_creds) callconv(.c) ?[*:0]const u8;
extern fn Curl_http_acc_creds_from_url(creds: ?*const Curl_creds) callconv(.c) bool;
extern fn Curl_http_acc_set_httpwant(data: *const Curl_easy) callconv(.c) u8;
extern fn Curl_http_acc_set_http09_allowed(data: *const Curl_easy) callconv(.c) bool;
extern fn Curl_http_acc_set_sep_headers(data: *const Curl_easy) callconv(.c) bool;
extern fn Curl_http_acc_set_headers(data: *const Curl_easy) callconv(.c) ?*curl_slist;
extern fn Curl_http_acc_set_proxyheaders(data: *const Curl_easy) callconv(.c) ?*curl_slist;
extern fn Curl_http_acc_set_http200aliases(data: *const Curl_easy) callconv(.c) ?*curl_slist;
extern fn Curl_http_acc_set_http_follow_mode(data: *const Curl_easy) callconv(.c) u8;
extern fn Curl_http_acc_set_http_auto_referer(data: *const Curl_easy) callconv(.c) bool;
extern fn Curl_http_acc_set_opt_no_body(data: *const Curl_easy) callconv(.c) bool;
extern fn Curl_http_acc_set_post301(data: *const Curl_easy) callconv(.c) bool;
extern fn Curl_http_acc_set_post302(data: *const Curl_easy) callconv(.c) bool;
extern fn Curl_http_acc_set_post303(data: *const Curl_easy) callconv(.c) bool;
extern fn Curl_http_acc_set_maxredirs(data: *const Curl_easy) callconv(.c) c_long;
extern fn Curl_http_acc_set_path_as_is(data: *const Curl_easy) callconv(.c) bool;
extern fn Curl_http_acc_set_expect_100_timeout(data: *const Curl_easy) callconv(.c) c_uint;
extern fn Curl_http_acc_set_connect_only(data: *const Curl_easy) callconv(.c) u8;
extern fn Curl_http_acc_set_timecondition(data: *const Curl_easy) callconv(.c) u8;
extern fn Curl_http_acc_set_timevalue(data: *const Curl_easy) callconv(.c) curl_off_t;
extern fn Curl_http_acc_set_postfields(data: *const Curl_easy) callconv(.c) ?[*]const u8;
extern fn Curl_http_acc_set_set_resume_from(data: *const Curl_easy) callconv(.c) curl_off_t;
extern fn Curl_http_acc_set_get_filetime(data: *const Curl_easy) callconv(.c) bool;
extern fn Curl_http_acc_set_http_fail_on_error(data: *const Curl_easy) callconv(.c) bool;
extern fn Curl_http_acc_set_http_keep_sending_on_error(data: *const Curl_easy) callconv(.c) bool;
extern fn Curl_http_acc_set_http_transfer_encoding(data: *const Curl_easy) callconv(.c) bool;
extern fn Curl_http_acc_set_proxy_transfer_mode(data: *const Curl_easy) callconv(.c) bool;
extern fn Curl_http_acc_set_ignorecl(data: *const Curl_easy) callconv(.c) bool;
extern fn Curl_http_acc_set_max_filesize(data: *const Curl_easy) callconv(.c) curl_off_t;
extern fn Curl_http_acc_state_http_neg(data: *const Curl_easy) callconv(.c) *http_negotiation;
extern fn Curl_http_acc_state_authhost(data: *Curl_easy) callconv(.c) *auth;
extern fn Curl_http_acc_state_authproxy(data: *Curl_easy) callconv(.c) *auth;
extern fn Curl_http_acc_state_creds(data: *const Curl_easy) callconv(.c) ?*Curl_creds;
extern fn Curl_http_acc_state_origin(data: *const Curl_easy) callconv(.c) ?*Curl_peer;
extern fn Curl_http_acc_state_initial_origin(data: *const Curl_easy) callconv(.c) ?*Curl_peer;
extern fn Curl_http_acc_peer_hostname(peer: ?*const Curl_peer) callconv(.c) ?[*:0]const u8;
extern fn Curl_http_acc_peer_user_hostname(peer: ?*const Curl_peer) callconv(.c) ?[*:0]const u8;
extern fn Curl_http_acc_peer_port(peer: ?*const Curl_peer) callconv(.c) c_int;
extern fn Curl_http_acc_peer_ipv6(peer: ?*const Curl_peer) callconv(.c) bool;
extern fn Curl_http_acc_peer_scheme_name(peer: ?*const Curl_peer) callconv(.c) ?[*:0]const u8;
extern fn Curl_http_acc_peer_scheme_defport(peer: ?*const Curl_peer) callconv(.c) c_int;
extern fn Curl_http_acc_peer_scheme_family(peer: ?*const Curl_peer) callconv(.c) curl_prot_t;
extern fn Curl_http_acc_peer_is_http(peer: ?*const Curl_peer) callconv(.c) bool;
extern fn Curl_http_acc_peer_is_ftp(peer: ?*const Curl_peer) callconv(.c) bool;
extern fn Curl_http_acc_auth_allowed_to_host(data: *const Curl_easy) callconv(.c) bool;
extern fn Curl_http_acc_state_authproblem(data: *const Curl_easy) callconv(.c) bool;
extern fn Curl_http_acc_state_set_authproblem(data: *Curl_easy, v: bool) callconv(.c) void;
extern fn Curl_http_acc_state_set_this_is_a_follow(data: *Curl_easy, v: bool) callconv(.c) void;
extern fn Curl_http_acc_state_set_allow_port(data: *Curl_easy, v: bool) callconv(.c) void;
extern fn Curl_http_acc_state_prefer_ascii(data: *const Curl_easy) callconv(.c) bool;
extern fn Curl_http_acc_state_resume_from(data: *const Curl_easy) callconv(.c) curl_off_t;
extern fn Curl_http_acc_state_set_resume_from(data: *Curl_easy, v: curl_off_t) callconv(.c) void;
extern fn Curl_http_acc_state_use_range(data: *const Curl_easy) callconv(.c) bool;
extern fn Curl_http_acc_state_range(data: *const Curl_easy) callconv(.c) ?[*:0]const u8;
extern fn Curl_http_acc_state_rangeline(data: *const Curl_easy) callconv(.c) ?[*:0]u8;
extern fn Curl_http_acc_state_set_rangeline(data: *Curl_easy, v: ?[*:0]u8) callconv(.c) void;
extern fn Curl_http_acc_state_infilesize(data: *const Curl_easy) callconv(.c) curl_off_t;
extern fn Curl_http_acc_state_set_infilesize(data: *Curl_easy, v: curl_off_t) callconv(.c) void;
extern fn Curl_http_acc_state_httpreq(data: *const Curl_easy) callconv(.c) u8;
extern fn Curl_http_acc_state_set_httpreq(data: *Curl_easy, v: u8) callconv(.c) void;
extern fn Curl_http_acc_state_upload(data: *const Curl_easy) callconv(.c) bool;
extern fn Curl_http_acc_state_http_ignorecustom(data: *const Curl_easy) callconv(.c) bool;
extern fn Curl_http_acc_state_set_http_ignorecustom(data: *Curl_easy, v: bool) callconv(.c) void;
extern fn Curl_http_acc_state_disableexpect(data: *const Curl_easy) callconv(.c) bool;
extern fn Curl_http_acc_state_set_disableexpect(data: *Curl_easy, v: bool) callconv(.c) void;
extern fn Curl_http_acc_state_http_hd_flags(data: *Curl_easy, pte: *bool, pupgrade: *bool, ph2settings: *bool) callconv(.c) void;
extern fn Curl_http_acc_state_set_http_hd_flags(data: *Curl_easy, te: bool, upgrade: bool, h2settings: bool) callconv(.c) void;
extern fn Curl_http_acc_state_maybe_folded(data: *const Curl_easy) callconv(.c) bool;
extern fn Curl_http_acc_state_set_maybe_folded(data: *Curl_easy, v: bool) callconv(.c) void;
extern fn Curl_http_acc_state_leading_unfold(data: *const Curl_easy) callconv(.c) bool;
extern fn Curl_http_acc_state_set_leading_unfold(data: *Curl_easy, v: bool) callconv(.c) void;
extern fn Curl_http_acc_state_followlocation(data: *const Curl_easy) callconv(.c) c_long;
extern fn Curl_http_acc_state_inc_followlocation(data: *Curl_easy) callconv(.c) void;
extern fn Curl_http_acc_state_inc_requests(data: *Curl_easy) callconv(.c) void;
extern fn Curl_http_acc_state_uh(data: *const Curl_easy) callconv(.c) ?*CURLU;
extern fn Curl_http_acc_state_url_bufref(data: *Curl_easy) callconv(.c) *bufref;
extern fn Curl_http_acc_state_referer_bufref(data: *Curl_easy) callconv(.c) *bufref;
extern fn Curl_http_acc_state_http_host(data: *const Curl_easy) callconv(.c) ?[*:0]u8;
extern fn Curl_http_acc_state_set_http_host(data: *Curl_easy, v: ?[*:0]u8) callconv(.c) void;
extern fn Curl_http_acc_state_headerb(data: *Curl_easy) callconv(.c) *dynbuf;
extern fn Curl_http_acc_state_up_path(data: *const Curl_easy) callconv(.c) ?[*:0]const u8;
extern fn Curl_http_acc_state_up_query(data: *const Curl_easy) callconv(.c) ?[*:0]const u8;
extern fn Curl_http_acc_req_httpcode(data: *const Curl_easy) callconv(.c) c_int;
extern fn Curl_http_acc_req_set_httpcode(data: *Curl_easy, v: c_int) callconv(.c) void;
extern fn Curl_http_acc_req_httpversion(data: *const Curl_easy) callconv(.c) u8;
extern fn Curl_http_acc_req_set_httpversion(data: *Curl_easy, v: u8) callconv(.c) void;
extern fn Curl_http_acc_req_httpversion_sent(data: *const Curl_easy) callconv(.c) u8;
extern fn Curl_http_acc_req_size(data: *const Curl_easy) callconv(.c) curl_off_t;
extern fn Curl_http_acc_req_set_size(data: *Curl_easy, v: curl_off_t) callconv(.c) void;
extern fn Curl_http_acc_req_maxdownload(data: *const Curl_easy) callconv(.c) curl_off_t;
extern fn Curl_http_acc_req_set_maxdownload(data: *Curl_easy, v: curl_off_t) callconv(.c) void;
extern fn Curl_http_acc_req_bytecount(data: *const Curl_easy) callconv(.c) curl_off_t;
extern fn Curl_http_acc_req_writebytecount(data: *const Curl_easy) callconv(.c) curl_off_t;
extern fn Curl_http_acc_req_headerbytecount(data: *const Curl_easy) callconv(.c) c_uint;
extern fn Curl_http_acc_req_set_headerbytecount(data: *Curl_easy, v: c_uint) callconv(.c) void;
extern fn Curl_http_acc_req_deductheadercount(data: *const Curl_easy) callconv(.c) c_uint;
extern fn Curl_http_acc_req_set_deductheadercount(data: *Curl_easy, v: c_uint) callconv(.c) void;
extern fn Curl_http_acc_req_allheadercount(data: *const Curl_easy) callconv(.c) usize;
extern fn Curl_http_acc_req_set_allheadercount(data: *Curl_easy, v: usize) callconv(.c) void;
extern fn Curl_http_acc_req_headerline(data: *const Curl_easy) callconv(.c) c_int;
extern fn Curl_http_acc_req_set_headerline(data: *Curl_easy, v: c_int) callconv(.c) void;
extern fn Curl_http_acc_req_offset_ptr(data: *Curl_easy) callconv(.c) *curl_off_t;
extern fn Curl_http_acc_req_timeofdoc_ptr(data: *Curl_easy) callconv(.c) *time_t;
extern fn Curl_http_acc_req_newurl(data: *const Curl_easy) callconv(.c) ?[*:0]u8;
extern fn Curl_http_acc_req_set_newurl(data: *Curl_easy, v: ?[*:0]u8) callconv(.c) void;
extern fn Curl_http_acc_req_location(data: *const Curl_easy) callconv(.c) ?[*:0]u8;
extern fn Curl_http_acc_req_set_location(data: *Curl_easy, v: ?[*:0]u8) callconv(.c) void;
extern fn Curl_http_acc_req_cookiehost(data: *const Curl_easy) callconv(.c) ?[*:0]u8;
extern fn Curl_http_acc_req_set_cookiehost(data: *Curl_easy, v: ?[*:0]u8) callconv(.c) void;
extern fn Curl_http_acc_req_hd_auth(data: *const Curl_easy, proxy: bool) callconv(.c) ?[*:0]u8;
extern fn Curl_http_acc_req_set_hd_auth(data: *Curl_easy, proxy: bool, v: ?[*:0]u8) callconv(.c) void;
extern fn Curl_http_acc_req_upgr101(data: *const Curl_easy) callconv(.c) u8;
extern fn Curl_http_acc_req_set_upgr101(data: *Curl_easy, v: u8) callconv(.c) void;
extern fn Curl_http_acc_req_header(data: *const Curl_easy) callconv(.c) bool;
extern fn Curl_http_acc_req_set_header(data: *Curl_easy, v: bool) callconv(.c) void;
extern fn Curl_http_acc_req_content_range(data: *const Curl_easy) callconv(.c) bool;
extern fn Curl_http_acc_req_set_content_range(data: *Curl_easy, v: bool) callconv(.c) void;
extern fn Curl_http_acc_req_set_download_done(data: *Curl_easy, v: bool) callconv(.c) void;
extern fn Curl_http_acc_req_upload_done(data: *const Curl_easy) callconv(.c) bool;
extern fn Curl_http_acc_req_done(data: *const Curl_easy) callconv(.c) bool;
extern fn Curl_http_acc_req_set_done(data: *Curl_easy, v: bool) callconv(.c) void;
extern fn Curl_http_acc_req_chunk(data: *const Curl_easy) callconv(.c) bool;
extern fn Curl_http_acc_req_upload_chunky(data: *const Curl_easy) callconv(.c) bool;
extern fn Curl_http_acc_req_set_upload_chunky(data: *Curl_easy, v: bool) callconv(.c) void;
extern fn Curl_http_acc_req_no_body(data: *const Curl_easy) callconv(.c) bool;
extern fn Curl_http_acc_req_set_no_body(data: *Curl_easy, v: bool) callconv(.c) void;
extern fn Curl_http_acc_req_authneg(data: *const Curl_easy) callconv(.c) bool;
extern fn Curl_http_acc_req_set_authneg(data: *Curl_easy, v: bool) callconv(.c) void;
extern fn Curl_http_acc_req_ignorebody(data: *const Curl_easy) callconv(.c) bool;
extern fn Curl_http_acc_req_set_ignorebody(data: *Curl_easy, v: bool) callconv(.c) void;
extern fn Curl_http_acc_req_http_bodyless(data: *const Curl_easy) callconv(.c) bool;
extern fn Curl_http_acc_req_set_http_bodyless(data: *Curl_easy, v: bool) callconv(.c) void;
extern fn Curl_http_acc_req_ignore_cl(data: *const Curl_easy) callconv(.c) bool;
extern fn Curl_http_acc_req_set_ignore_cl(data: *Curl_easy, v: bool) callconv(.c) void;
extern fn Curl_http_acc_req_set_resp_trailer(data: *Curl_easy, v: bool) callconv(.c) void;
extern fn Curl_http_acc_req_want_recv(data: *const Curl_easy) callconv(.c) bool;
extern fn Curl_http_acc_req_clear_recv(data: *Curl_easy) callconv(.c) void;
extern fn Curl_http_acc_req_set_send(data: *Curl_easy) callconv(.c) void;
extern fn Curl_http_acc_req_soft_reset(data: *Curl_easy) callconv(.c) CURLcode;
extern fn Curl_http_acc_info_httpcode(data: *const Curl_easy) callconv(.c) c_int;
extern fn Curl_http_acc_info_set_httpcode(data: *Curl_easy, v: c_int) callconv(.c) void;
extern fn Curl_http_acc_info_set_httpversion(data: *Curl_easy, v: c_int) callconv(.c) void;
extern fn Curl_http_acc_info_authpicked_ptr(data: *Curl_easy, proxy: bool) callconv(.c) *u32;
extern fn Curl_http_acc_info_authavail_ptr(data: *Curl_easy, proxy: bool) callconv(.c) *u32;
extern fn Curl_http_acc_info_set_filetime(data: *Curl_easy, v: time_t) callconv(.c) void;
extern fn Curl_http_acc_info_set_timecond(data: *Curl_easy, v: bool) callconv(.c) void;
extern fn Curl_http_acc_info_set_contenttype(data: *Curl_easy, v: ?[*:0]u8) callconv(.c) void;
extern fn Curl_http_acc_info_set_wouldredirect(data: *Curl_easy, v: ?[*:0]u8) callconv(.c) void;
extern fn Curl_http_acc_info_set_retry_after(data: *Curl_easy, v: time_t) callconv(.c) void;
extern fn Curl_http_acc_info_header_size(data: *const Curl_easy) callconv(.c) curl_off_t;
extern fn Curl_http_acc_info_set_header_size(data: *Curl_easy, v: curl_off_t) callconv(.c) void;
extern fn Curl_http_acc_input_negotiate(data: *Curl_easy, conn: *connectdata, proxy: bool, header: [*:0]const u8) callconv(.c) CURLcode;
extern fn Curl_http_acc_conn_set_nego_recv(conn: *connectdata, proxy: bool) callconv(.c) void;
extern fn Curl_http_acc_output_negotiate(data: *Curl_easy, conn: *connectdata, proxy: bool) callconv(.c) CURLcode;
extern fn Curl_http_acc_input_ntlm(data: *Curl_easy, proxy: bool, header: [*:0]const u8) callconv(.c) CURLcode;
extern fn Curl_http_acc_output_ntlm(data: *Curl_easy, proxy: bool) callconv(.c) CURLcode;
extern fn Curl_http_acc_is_ntlm_supported() callconv(.c) bool;
extern fn Curl_http_acc_is_spnego_supported() callconv(.c) bool;
extern fn Curl_http_acc_is_digest_supported() callconv(.c) bool;
extern fn Curl_http_acc_input_digest(data: *Curl_easy, proxy: bool, header: [*:0]const u8) callconv(.c) CURLcode;
extern fn Curl_http_acc_output_digest(data: *Curl_easy, proxy: bool, request: [*:0]const u8, uripath: [*:0]const u8) callconv(.c) CURLcode;
extern fn Curl_http_acc_digest_cleanup(data: *Curl_easy) callconv(.c) void;
extern fn Curl_http_acc_output_aws_sigv4(data: *Curl_easy) callconv(.c) CURLcode;
extern fn Curl_http_acc_output_httpsig(data: *Curl_easy) callconv(.c) CURLcode;
extern fn Curl_http_acc_headers_init(data: *Curl_easy) callconv(.c) CURLcode;
extern fn Curl_http_acc_http_cookies(data: *Curl_easy, r: *dynbuf) callconv(.c) CURLcode;
extern fn Curl_http_acc_cookie_add(data: *Curl_easy, v: [*:0]const u8) callconv(.c) CURLcode;
extern fn Curl_http_acc_has_cookie_engine(data: *const Curl_easy) callconv(.c) bool;
extern fn Curl_http_acc_altsvc_header(data: *Curl_easy, hd: [*]const u8, hdlen: usize) callconv(.c) CURLcode;
extern fn Curl_http_acc_hsts_header(data: *Curl_easy, hd: [*]const u8, hdlen: usize) callconv(.c) CURLcode;
extern fn Curl_http_acc_persistent_auth(data: *Curl_easy, hd: [*:0]const u8, hdlen: usize) callconv(.c) CURLcode;
extern fn Curl_http_acc_check_auth_closure(data: *Curl_easy, conn: *connectdata) callconv(.c) void;
extern fn Curl_http_acc_perhapsrewind_auth_check(data: *Curl_easy, conn: *connectdata, pongoing_auth: *?[*:0]const u8) callconv(.c) bool;
extern fn Curl_http_acc_set_post_reader(data: *Curl_easy, req_type: Curl_HttpReq) callconv(.c) CURLcode;
extern fn Curl_http_acc_mimepost_curlheaders(data: *const Curl_easy) callconv(.c) ?*curl_slist;
extern fn Curl_http_acc_http2_may_switch(data: *Curl_easy) callconv(.c) bool;
extern fn Curl_http_acc_http2_switch(data: *Curl_easy) callconv(.c) CURLcode;
extern fn Curl_http_acc_http2_request_upgrade(req: *dynbuf, data: *Curl_easy) callconv(.c) CURLcode;
extern fn Curl_http_acc_http2_upgrade(data: *Curl_easy, conn: *connectdata, mem_ptr: [*]const u8, nread: usize) callconv(.c) CURLcode;
extern fn Curl_http_acc_ws_request(data: *Curl_easy, req: *dynbuf) callconv(.c) CURLcode;
extern fn Curl_http_acc_ws_accept(data: *Curl_easy, mem_ptr: [*]const u8, nread: usize) callconv(.c) CURLcode;
extern fn Curl_http_acc_rtsp_parseheader(data: *Curl_easy, hd: [*:0]const u8) callconv(.c) CURLcode;
extern fn Curl_http_acc_current_time() callconv(.c) curl_off_t;

// http_negotiation helpers
extern fn Curl_http_acc_neg_zero(neg: *http_negotiation) callconv(.c) void;
extern fn Curl_http_acc_neg_wanted(neg: *const http_negotiation) callconv(.c) u8;
extern fn Curl_http_acc_neg_set_wanted(neg: *http_negotiation, v: u8) callconv(.c) void;
extern fn Curl_http_acc_neg_allowed(neg: *const http_negotiation) callconv(.c) u8;
extern fn Curl_http_acc_neg_set_allowed(neg: *http_negotiation, v: u8) callconv(.c) void;
extern fn Curl_http_acc_neg_rcvd_min(neg: *const http_negotiation) callconv(.c) u8;
extern fn Curl_http_acc_neg_set_rcvd_min(neg: *http_negotiation, v: u8) callconv(.c) void;
extern fn Curl_http_acc_neg_h2_upgrade(neg: *const http_negotiation) callconv(.c) bool;
extern fn Curl_http_acc_neg_set_h2_upgrade(neg: *http_negotiation, v: bool) callconv(.c) void;
extern fn Curl_http_acc_neg_set_h2_prior_knowledge(neg: *http_negotiation, v: bool) callconv(.c) void;
extern fn Curl_http_acc_neg_accept_09(neg: *const http_negotiation) callconv(.c) bool;
extern fn Curl_http_acc_neg_set_accept_09(neg: *http_negotiation, v: bool) callconv(.c) void;
extern fn Curl_http_acc_neg_only_10(neg: *const http_negotiation) callconv(.c) bool;
extern fn Curl_http_acc_neg_set_only_10(neg: *http_negotiation, v: bool) callconv(.c) void;

// struct auth helpers
extern fn Curl_http_acc_auth_want(a: *const auth) callconv(.c) u32;
extern fn Curl_http_acc_auth_picked(a: *const auth) callconv(.c) u32;
extern fn Curl_http_acc_auth_set_picked(a: *auth, v: u32) callconv(.c) void;
extern fn Curl_http_acc_auth_avail(a: *const auth) callconv(.c) u32;
extern fn Curl_http_acc_auth_set_avail(a: *auth, v: u32) callconv(.c) void;
extern fn Curl_http_acc_auth_done(a: *const auth) callconv(.c) bool;
extern fn Curl_http_acc_auth_set_done(a: *auth, v: bool) callconv(.c) void;
extern fn Curl_http_acc_auth_multipass(a: *const auth) callconv(.c) bool;
extern fn Curl_http_acc_auth_set_multipass(a: *auth, v: bool) callconv(.c) void;

// Specific set.str helpers
extern fn Curl_http_acc_str_customrequest(data: *const Curl_easy) callconv(.c) ?[*:0]u8;
extern fn Curl_http_acc_str_encoding(data: *const Curl_easy) callconv(.c) ?[*:0]u8;
extern fn Curl_http_acc_str_useragent(data: *const Curl_easy) callconv(.c) ?[*:0]u8;
extern fn Curl_http_acc_str_target(data: *const Curl_easy) callconv(.c) ?[*:0]u8;

// External libcurl functions
extern fn Curl_checkheaders(data: ?*const Curl_easy, thisheader: [*]const u8, thislen: usize) callconv(.c) ?[*:0]u8;
extern fn Curl_conncontrol(conn: ?*connectdata, ctrl: c_int) callconv(.c) void;
extern fn Curl_conn_may_http3(data: ?*Curl_easy, conn: ?*connectdata) callconv(.c) CURLcode;
extern fn Curl_conn_http_version(data: ?*const Curl_easy, conn: ?*connectdata) callconv(.c) u8;
extern fn Curl_conn_is_ssl(conn: ?*const connectdata, sockindex: i8) callconv(.c) bool;
extern fn Curl_conn_get_alpn_negotiated(data: ?*Curl_easy, conn: ?*connectdata) callconv(.c) ?[*:0]const u8;
extern fn Curl_conn_set_multiplex(conn: ?*connectdata) callconv(.c) void;
extern fn Curl_peer_equal(p1: ?*const Curl_peer, p2: ?*const Curl_peer) callconv(.c) bool;
extern fn Curl_multi_connchanged(multi: ?*Curl_multi) callconv(.c) void;
extern fn Curl_1st_fatal(r1: CURLcode, r2: CURLcode) callconv(.c) CURLcode;
extern fn Curl_pgrs_now(data: ?*Curl_easy) callconv(.c) *const Curltime;
extern fn Curl_expire_set(data: ?*Curl_easy, id: c_uint, ms: timediff_t, pnow: *const Curltime) callconv(.c) void;
extern fn Curl_expire_clear(data: ?*Curl_easy, id: c_uint) callconv(.c) void;
extern fn Curl_pgrsTime(data: ?*Curl_easy, timer: c_uint) callconv(.c) void;
extern fn Curl_pgrsResetTransferSizes(data: ?*Curl_easy) callconv(.c) void;
extern fn Curl_pgrsSetUploadSize(data: ?*Curl_easy, size: curl_off_t) callconv(.c) void;
extern fn Curl_pgrsSetDownloadSize(data: ?*Curl_easy, size: curl_off_t) callconv(.c) void;
extern fn Curl_meets_timecondition(data: ?*Curl_easy, timeofdoc: time_t) callconv(.c) bool;
extern fn Curl_req_send(data: ?*Curl_easy, req: *dynbuf, httpversion: u8) callconv(.c) CURLcode;
extern fn Curl_req_sendbuf_empty(data: ?*Curl_easy) callconv(.c) bool;
extern fn Curl_req_done_sending(data: ?*Curl_easy) callconv(.c) bool;
extern fn Curl_req_want_send(data: ?*Curl_easy) callconv(.c) bool;
extern fn Curl_req_abort_sending(data: ?*Curl_easy) callconv(.c) CURLcode;
extern fn Curl_xfer_setup_sendrecv(data: ?*Curl_easy, sockindex: i8, recv_size: curl_off_t) callconv(.c) void;
extern fn Curl_httpchunk_add_reader(data: ?*Curl_easy) callconv(.c) CURLcode;
extern fn Curl_build_unencoding_stack(data: ?*Curl_easy, enclist: [*:0]const u8, is_te: bool) callconv(.c) CURLcode;
extern fn Curl_infof(data: ?*Curl_easy, fmt: [*:0]const u8, ...) callconv(.c) void;
extern fn Curl_failf(data: ?*Curl_easy, fmt: [*:0]const u8, ...) callconv(.c) void;
extern fn Curl_debug(data: ?*Curl_easy, info_type: c_uint, ptr: [*]const u8, size: usize) callconv(.c) void;

inline fn connclose(conn: ?*connectdata) void {
    Curl_conncontrol(conn, CONNCTRL_CONN_CLOSE);
}

inline fn connkeep(conn: ?*connectdata) void {
    Curl_conncontrol(conn, CONNCTRL_CONN_KEEP);
}

inline fn streamclose(conn: ?*connectdata) void {
    Curl_conncontrol(conn, CONNCTRL_STREAM_CLOSE);
}

inline fn Curl_headersep(c: u8) bool {
    return c == ':' or c == ';';
}

inline fn isBlank(c: u8) bool {
    return c == ' ' or c == '\t';
}

inline fn isNewline(c: u8) bool {
    return c == '\r' or c == '\n';
}

inline fn isDigit(c: u8) bool {
    return c >= '0' and c <= '9';
}

inline fn isAlnum(c: u8) bool {
    return (c >= '0' and c <= '9') or (c >= 'a' and c <= 'z') or (c >= 'A' and c <= 'Z');
}

// ============================================================================
// 1. HTTP Negotiation Init & Connection Setup
// ============================================================================

pub export fn Curl_http_neg_init(data: *Curl_easy, neg: *http_negotiation) callconv(.c) void {
    Curl_http_acc_neg_zero(neg);
    Curl_http_acc_neg_set_accept_09(neg, Curl_http_acc_set_http09_allowed(data));
    switch (Curl_http_acc_set_httpwant(data)) {
        CURL_HTTP_VERSION_1_0 => {
            Curl_http_acc_neg_set_wanted(neg, CURL_HTTP_V1x);
            Curl_http_acc_neg_set_allowed(neg, CURL_HTTP_V1x);
            Curl_http_acc_neg_set_only_10(neg, true);
        },
        CURL_HTTP_VERSION_1_1 => {
            Curl_http_acc_neg_set_wanted(neg, CURL_HTTP_V1x);
            Curl_http_acc_neg_set_allowed(neg, CURL_HTTP_V1x);
        },
        CURL_HTTP_VERSION_2_0 => {
            Curl_http_acc_neg_set_wanted(neg, CURL_HTTP_V1x | CURL_HTTP_V2x);
            Curl_http_acc_neg_set_allowed(neg, CURL_HTTP_V1x | CURL_HTTP_V2x);
            Curl_http_acc_neg_set_h2_upgrade(neg, true);
        },
        CURL_HTTP_VERSION_2TLS => {
            Curl_http_acc_neg_set_wanted(neg, CURL_HTTP_V1x | CURL_HTTP_V2x);
            Curl_http_acc_neg_set_allowed(neg, CURL_HTTP_V1x | CURL_HTTP_V2x);
        },
        CURL_HTTP_VERSION_2_PRIOR_KNOWLEDGE => {
            Curl_http_acc_neg_set_wanted(neg, CURL_HTTP_V2x);
            Curl_http_acc_neg_set_allowed(neg, CURL_HTTP_V2x);
            Curl_http_acc_neg_set_h2_prior_knowledge(Curl_http_acc_state_http_neg(data), true);
        },
        CURL_HTTP_VERSION_3 => {
            Curl_http_acc_neg_set_wanted(neg, CURL_HTTP_V1x | CURL_HTTP_V2x | CURL_HTTP_V3x);
            Curl_http_acc_neg_set_allowed(neg, CURL_HTTP_V1x | CURL_HTTP_V2x | CURL_HTTP_V3x);
        },
        CURL_HTTP_VERSION_3ONLY => {
            Curl_http_acc_neg_set_wanted(neg, CURL_HTTP_V3x);
            Curl_http_acc_neg_set_allowed(neg, CURL_HTTP_V3x);
        },
        else => {
            Curl_http_acc_neg_set_wanted(neg, CURL_HTTP_V1x | CURL_HTTP_V2x);
            Curl_http_acc_neg_set_allowed(neg, CURL_HTTP_V1x | CURL_HTTP_V2x | CURL_HTTP_V3x);
        },
    }
}

pub export fn Curl_http_setup_conn(data: *Curl_easy, conn: *connectdata) callconv(.c) CURLcode {
    const neg = Curl_http_acc_state_http_neg(data);
    if (Curl_http_acc_neg_wanted(neg) == CURL_HTTP_V3x) {
        return Curl_conn_may_http3(data, conn);
    }
    return CURLE_OK;
}

// ============================================================================
// 2. Proxy Headers & Custom Header Value Helpers
// ============================================================================

pub export fn Curl_checkProxyheaders(
    data: *const Curl_easy,
    conn: *const connectdata,
    thisheader: [*]const u8,
    thislen: usize,
) callconv(.c) ?[*:0]u8 {
    if (!hasFeat(FEAT_PROXY))
        return null;

    var head: ?*curl_slist = if (Curl_http_acc_conn_http_proxy_peer(conn) != null and
        Curl_http_acc_set_sep_headers(data))
        Curl_http_acc_set_proxyheaders(data)
    else
        Curl_http_acc_set_headers(data);

    while (head) |h| : (head = h.next) {
        if (h.data) |d| {
            if (curl_strnequal(d, thisheader, thislen) != 0 and
                Curl_headersep(d[thislen]))
            {
                return d;
            }
        }
    }
    return null;
}

fn header_has_value(headerp: *?[*:0]const u8, outp: *Curl_str) bool {
    const value = (curlx_str_cspn(headerp, outp, ";:") == 0) and
        (curlx_str_single(headerp, ':') == 0 or
            curlx_str_single(headerp, ';') == 0);
    if (value) {
        _ = curlx_str_cspn(headerp, outp, "\r\n");
        curlx_str_trimblanks(outp);
    }
    return value;
}

fn http_header_is_empty(header: [*:0]const u8) bool {
    var h: ?[*:0]const u8 = header;
    var out = std.mem.zeroes(Curl_str);
    if (header_has_value(&h, &out)) {
        return out.len == 0;
    }
    return true;
}

fn copy_custom_value(header: [*:0]const u8, valp: *?[*:0]u8) CURLcode {
    var h: ?[*:0]const u8 = header;
    var out = std.mem.zeroes(Curl_str);
    if (header_has_value(&h, &out)) {
        valp.* = curlx_memdup0(out.str, out.len);
        if (valp.* != null)
            return CURLE_OK;
        return CURLE_OUT_OF_MEMORY;
    }
    valp.* = null;
    return CURLE_BAD_FUNCTION_ARGUMENT;
}

pub export fn Curl_copy_header_value(header: [*:0]const u8) callconv(.c) ?[*:0]u8 {
    var h: ?[*:0]const u8 = header;
    var out = std.mem.zeroes(Curl_str);
    if (curlx_str_until(&h, &out, MAX_HTTP_RESP_HEADER_SIZE, ':') == 0 and
        curlx_str_single(&h, ':') == 0)
    {
        _ = curlx_str_untilnl(&h, &out, MAX_HTTP_RESP_HEADER_SIZE);
        curlx_str_trimblanks(&out);
        return curlx_memdup0(out.str, out.len);
    }
    return null;
}

// ============================================================================
// 3. HTTP Authentication (Basic, Bearer, Negotiate, NTLM, Digest, SigV4, etc.)
// ============================================================================

fn http_output_basic(data: *Curl_easy, conn: *connectdata, proxy: bool) CURLcode {
    if (!hasFeat(FEAT_HTTP_AUTH) or !hasFeat(FEAT_BASIC_AUTH))
        return CURLE_NOT_BUILT_IN;

    var creds: ?*const Curl_creds = null;
    if (proxy) {
        if (!hasFeat(FEAT_PROXY))
            return CURLE_NOT_BUILT_IN;
        creds = Curl_http_acc_conn_http_proxy_creds(conn);
    } else {
        creds = Curl_http_acc_state_creds(data);
    }

    const c = creds orelse return CURLE_FAILED_INIT;
    const user: [*:0]const u8 = Curl_http_acc_creds_user(c) orelse "";
    const passwd: [*:0]const u8 = Curl_http_acc_creds_passwd(c) orelse "";

    const out = curl_maprintf("%s:%s", user, passwd) orelse return CURLE_OUT_OF_MEMORY;
    defer mem.free(out);

    var authorization: ?[*:0]u8 = null;
    var size: usize = 0;
    const result = curlx_parse.curlx_base64_encode(out, std.mem.len(out), &authorization, &size);
    if (result != CURLE_OK)
        return result;

    const auth_b64 = authorization orelse return CURLE_REMOTE_ACCESS_DENIED;
    defer mem.free(auth_b64);

    mem.free(Curl_http_acc_req_hd_auth(data, proxy));
    const pfx: [*:0]const u8 = if (proxy) "Proxy-" else "";
    const hd = curl_maprintf("%sAuthorization: Basic %s\r\n", pfx, auth_b64);
    Curl_http_acc_req_set_hd_auth(data, proxy, hd);
    if (hd == null)
        return CURLE_OUT_OF_MEMORY;

    return CURLE_OK;
}

fn http_output_bearer(data: *Curl_easy) CURLcode {
    if (!hasFeat(FEAT_HTTP_AUTH) or !hasFeat(FEAT_BEARER_AUTH))
        return CURLE_NOT_BUILT_IN;

    const creds = Curl_http_acc_state_creds(data);
    const bearer: [*:0]const u8 = Curl_http_acc_creds_oauth_bearer(creds) orelse "";
    mem.free(Curl_http_acc_req_hd_auth(data, false));
    const hd = curl_maprintf("Authorization: Bearer %s\r\n", bearer);
    Curl_http_acc_req_set_hd_auth(data, false, hd);
    if (hd == null)
        return CURLE_OUT_OF_MEMORY;
    return CURLE_OK;
}

fn pickoneauth(pick: *auth, mask: u32, creds: ?*const Curl_creds) bool {
    const have_user_pass = Curl_http_acc_creds_has_user_or_pass(creds);
    const avail: u32 = Curl_http_acc_auth_avail(pick) & Curl_http_acc_auth_want(pick) & mask;
    var picked = true;

    if ((avail & CURLAUTH_NEGOTIATE) != 0) {
        Curl_http_acc_auth_set_picked(pick, CURLAUTH_NEGOTIATE);
    } else if (hasFeat(FEAT_BEARER_AUTH) and (avail & CURLAUTH_BEARER) != 0 and Curl_http_acc_creds_has_oauth_bearer(creds)) {
        Curl_http_acc_auth_set_picked(pick, CURLAUTH_BEARER);
    } else if (hasFeat(FEAT_DIGEST_AUTH) and (avail & CURLAUTH_DIGEST) != 0 and have_user_pass) {
        Curl_http_acc_auth_set_picked(pick, CURLAUTH_DIGEST);
    } else if ((avail & CURLAUTH_NTLM) != 0) {
        Curl_http_acc_auth_set_picked(pick, CURLAUTH_NTLM);
    } else if (hasFeat(FEAT_BASIC_AUTH) and (avail & CURLAUTH_BASIC) != 0 and have_user_pass) {
        Curl_http_acc_auth_set_picked(pick, CURLAUTH_BASIC);
    } else if (hasFeat(FEAT_AWS) and (avail & CURLAUTH_AWS_SIGV4) != 0) {
        Curl_http_acc_auth_set_picked(pick, CURLAUTH_AWS_SIGV4);
    } else if (hasFeat(FEAT_HTTPSIG) and (avail & CURLAUTH_HTTPSIG) != 0) {
        Curl_http_acc_auth_set_picked(pick, CURLAUTH_HTTPSIG);
    } else {
        Curl_http_acc_auth_set_picked(pick, CURLAUTH_PICKNONE);
        picked = false;
    }
    Curl_http_acc_auth_set_avail(pick, CURLAUTH_NONE);
    return picked;
}

fn http_perhapsrewind(data: *Curl_easy, conn: *connectdata) CURLcode {
    const bytessent = Curl_http_acc_req_writebytecount(data);
    const expectsend = sendf.Curl_creader_total_length(data);
    const upload_remain: curl_off_t = if (expectsend >= 0) (expectsend - bytessent) else -1;
    const little_upload_remains = (upload_remain >= 0 and upload_remain < 2000);
    const needs_rewind = sendf.Curl_creader_needs_rewind(data);
    var abort_upload = (!Curl_http_acc_req_upload_done(data) and !little_upload_remains);
    var ongoing_auth: ?[*:0]const u8 = null;

    if (needs_rewind) {
        Curl_infof(data, "Need to rewind upload for next request");
        sendf.Curl_creader_set_rewind(data, true);
    }

    if (Curl_http_acc_conn_bits_close(conn))
        return CURLE_OK;

    if (abort_upload) {
        abort_upload = Curl_http_acc_perhapsrewind_auth_check(data, conn, &ongoing_auth);
    }

    if (abort_upload) {
        const oa: [*:0]const u8 = ongoing_auth orelse "";
        const oa_sep: [*:0]const u8 = if (ongoing_auth != null) " send, " else "";
        if (upload_remain >= 0) {
            Curl_infof(data, "%s%sclose instead of sending %lld more bytes", oa, oa_sep, @as(c_longlong, upload_remain));
        } else {
            Curl_infof(data, "%s%sclose instead of sending unknown amount of more bytes", oa, oa_sep);
        }
        streamclose(conn);
        Curl_http_acc_req_set_size(data, 0);
        Curl_http_acc_req_set_http_bodyless(data, true);
    }
    return CURLE_OK;
}

fn http_should_fail(data: *const Curl_easy, httpcode: c_int) bool {
    if (!Curl_http_acc_set_http_fail_on_error(data))
        return false;
    if (httpcode < 400)
        return false;
    if (Curl_http_acc_state_resume_from(data) != 0 and
        Curl_http_acc_state_httpreq(data) == HTTPREQ_GET and
        httpcode == 416)
        return false;
    if (httpcode != 401 and httpcode != 407)
        return true;

    if (httpcode == 401 and Curl_http_acc_state_creds(data) == null)
        return true;
    if (hasFeat(FEAT_PROXY)) {
        const conn = Curl_http_acc_conn(@constCast(data));
        if (httpcode == 407 and (conn == null or Curl_http_acc_conn_http_proxy_creds(conn.?) == null))
            return true;
    }
    return Curl_http_acc_state_authproblem(data);
}

pub export fn Curl_http_auth_act(data: *Curl_easy) callconv(.c) CURLcode {
    const conn = Curl_http_acc_conn(data) orelse return CURLE_BAD_FUNCTION_ARGUMENT;
    var pickhost = false;
    var pickproxy = false;
    var result: CURLcode = CURLE_OK;
    var authmask: u32 = ~@as(u32, 0);

    if (!Curl_http_acc_creds_has_oauth_bearer(Curl_http_acc_state_creds(data)))
        authmask &= ~CURLAUTH_BEARER;

    const httpcode = Curl_http_acc_req_httpcode(data);
    if (httpcode >= 100 and httpcode <= 199)
        return CURLE_OK;

    if (Curl_http_acc_state_authproblem(data))
        return if (Curl_http_acc_set_http_fail_on_error(data)) CURLE_HTTP_RETURNED_ERROR else CURLE_OK;

    const authhost = Curl_http_acc_state_authhost(data);
    const authproxy = Curl_http_acc_state_authproxy(data);
    const authneg = Curl_http_acc_req_authneg(data);

    if (Curl_http_acc_state_creds(data)) |creds| {
        if (httpcode == 401 or (authneg and httpcode < 300)) {
            pickhost = pickoneauth(authhost, authmask, creds);
            if (!pickhost) {
                Curl_http_acc_state_set_authproblem(data, true);
            } else {
                Curl_http_acc_info_authpicked_ptr(data, false).* = Curl_http_acc_auth_picked(authhost);
            }
            if (Curl_http_acc_auth_picked(authhost) == CURLAUTH_NTLM and
                Curl_http_acc_req_httpversion_sent(data) > 11)
            {
                Curl_infof(data, "Forcing HTTP/1.1 for NTLM");
                connclose(conn);
                const neg = Curl_http_acc_state_http_neg(data);
                Curl_http_acc_neg_set_wanted(neg, CURL_HTTP_V1x);
                Curl_http_acc_neg_set_allowed(neg, CURL_HTTP_V1x);
            }
        }
    }

    if (hasFeat(FEAT_PROXY)) {
        if (Curl_http_acc_conn_http_proxy_creds(conn)) |pcreds| {
            if (httpcode == 407 or (authneg and httpcode < 300)) {
                pickproxy = pickoneauth(authproxy, authmask & ~CURLAUTH_BEARER, pcreds);
                if (!pickproxy) {
                    Curl_http_acc_state_set_authproblem(data, true);
                } else {
                    Curl_http_acc_info_authpicked_ptr(data, true).* = Curl_http_acc_auth_picked(authproxy);
                }
            }
        }
    }

    if (pickhost or pickproxy) {
        result = http_perhapsrewind(data, conn);
        if (result != CURLE_OK)
            return result;

        mem.free(Curl_http_acc_req_newurl(data));
        const dup = Curl_bufref_dup(Curl_http_acc_state_url_bufref(data));
        Curl_http_acc_req_set_newurl(data, dup);
        if (dup == null)
            return CURLE_OUT_OF_MEMORY;
    } else if (httpcode < 300 and
        !Curl_http_acc_auth_done(authhost) and
        authneg and
        Curl_http_acc_state_httpreq(data) != HTTPREQ_GET and
        Curl_http_acc_state_httpreq(data) != HTTPREQ_HEAD)
    {
        const dup = Curl_bufref_dup(Curl_http_acc_state_url_bufref(data));
        Curl_http_acc_req_set_newurl(data, dup);
        if (dup == null)
            return CURLE_OUT_OF_MEMORY;
        Curl_http_acc_auth_set_done(authhost, true);
    }

    if (http_should_fail(data, Curl_http_acc_req_httpcode(data))) {
        Curl_failf(data, "The requested URL returned error: %d", Curl_http_acc_req_httpcode(data));
        result = CURLE_HTTP_RETURNED_ERROR;
    }
    return result;
}

fn output_auth_headers(
    data: *Curl_easy,
    conn: *connectdata,
    authstatus: *auth,
    request: [*:0]const u8,
    path: [*:0]const u8,
    proxy: bool,
) CURLcode {
    var auth_name: ?[*:0]const u8 = null;
    var result: CURLcode = CURLE_OK;
    const picked = Curl_http_acc_auth_picked(authstatus);

    if (hasFeat(FEAT_AWS) and picked == CURLAUTH_AWS_SIGV4 and !proxy) {
        auth_name = "AWS_SIGV4";
        result = Curl_http_acc_output_aws_sigv4(data);
        if (result != CURLE_OK)
            return result;
    } else if (hasFeat(FEAT_HTTPSIG) and picked == CURLAUTH_HTTPSIG and !proxy) {
        if (Curl_http_acc_auth_allowed_to_host(data)) {
            auth_name = "HTTPSIG";
            result = Curl_http_acc_output_httpsig(data);
            if (result != CURLE_OK)
                return result;
        } else {
            Curl_http_acc_auth_set_done(authstatus, true);
        }
    } else if (hasFeat(FEAT_SPNEGO) and picked == CURLAUTH_NEGOTIATE) {
        const allow_nego = (hasFeat(FEAT_PROXY) and proxy and
            Curl_checkProxyheaders(data, conn, "Proxy-authorization", "Proxy-authorization".len) == null) or
            (!proxy and Curl_checkheaders(data, "Authorization", "Authorization".len) == null and
                Curl_http_acc_auth_allowed_to_host(data));
        if (allow_nego) {
            auth_name = "Negotiate";
            result = Curl_http_acc_output_negotiate(data, conn, proxy);
            if (result != CURLE_OK)
                return result;
        } else {
            Curl_http_acc_auth_set_done(authstatus, true);
        }
    } else if (hasFeat(FEAT_NTLM) and picked == CURLAUTH_NTLM) {
        if (proxy or Curl_http_acc_auth_allowed_to_host(data)) {
            auth_name = "NTLM";
            result = Curl_http_acc_output_ntlm(data, proxy);
            if (result != CURLE_OK)
                return result;
        } else {
            Curl_http_acc_auth_set_done(authstatus, true);
        }
    } else if (hasFeat(FEAT_DIGEST_AUTH) and picked == CURLAUTH_DIGEST) {
        auth_name = "Digest";
        result = Curl_http_acc_output_digest(data, proxy, request, path);
        if (result != CURLE_OK)
            return result;
    } else if (hasFeat(FEAT_BASIC_AUTH) and picked == CURLAUTH_BASIC) {
        const proxy_creds = Curl_http_acc_conn_http_proxy_creds(conn);
        const host_creds = Curl_http_acc_state_creds(data);
        const allow_basic = (hasFeat(FEAT_PROXY) and proxy and proxy_creds != null and
            Curl_http_acc_creds_has_user_or_pass(proxy_creds) and
            Curl_checkProxyheaders(data, conn, "Proxy-authorization", "Proxy-authorization".len) == null) or
            (!proxy and host_creds != null and
                Curl_http_acc_creds_has_user_or_pass(host_creds) and
                Curl_checkheaders(data, "Authorization", "Authorization".len) == null);
        if (allow_basic) {
            auth_name = "Basic";
            result = http_output_basic(data, conn, proxy);
            if (result != CURLE_OK)
                return result;
        }
        Curl_http_acc_auth_set_done(authstatus, true);
    }

    if (hasFeat(FEAT_BEARER_AUTH) and picked == CURLAUTH_BEARER) {
        if (!proxy and
            Curl_http_acc_creds_has_oauth_bearer(Curl_http_acc_state_creds(data)) and
            Curl_checkheaders(data, "Authorization", "Authorization".len) == null)
        {
            auth_name = "Bearer";
            result = http_output_bearer(data);
            if (result != CURLE_OK)
                return result;
        }
        Curl_http_acc_auth_set_done(authstatus, true);
    }

    if (auth_name) |an| {
        if (hasFeat(FEAT_PROXY)) {
            Curl_http_acc_info_authpicked_ptr(data, proxy).* = Curl_http_acc_auth_picked(authstatus);
            const who: [*:0]const u8 = if (proxy) "Proxy" else "Server";
            const usr: [*:0]const u8 = if (proxy)
                (Curl_http_acc_creds_user(Curl_http_acc_conn_http_proxy_creds(conn)) orelse "")
            else
                (Curl_http_acc_creds_user(Curl_http_acc_state_creds(data)) orelse "");
            Curl_infof(data, "%s auth using %s with user '%s'", who, an, usr);
        } else {
            const usr: [*:0]const u8 = Curl_http_acc_creds_user(Curl_http_acc_state_creds(data)) orelse "";
            Curl_infof(data, "Server auth using %s with user '%s'", an, usr);
        }
        Curl_http_acc_auth_set_multipass(authstatus, !Curl_http_acc_auth_done(authstatus));
    } else {
        Curl_http_acc_auth_set_multipass(authstatus, false);
        Curl_http_acc_info_authpicked_ptr(data, proxy).* = 0;
    }

    return result;
}

pub export fn Curl_http_output_auth(
    data: *Curl_easy,
    conn: *connectdata,
    request: [*:0]const u8,
    req_type: Curl_HttpReq,
    path: [*:0]const u8,
    query: ?[*:0]const u8,
    is_connect: bool,
) callconv(.c) CURLcode {
    if (!hasFeat(FEAT_HTTP_AUTH))
        return CURLE_OK;

    const authhost = Curl_http_acc_state_authhost(data);
    const authproxy = Curl_http_acc_state_authproxy(data);
    var path_and_query: [*:0]const u8 = path;
    var tmp_str: ?[*:0]u8 = null;
    defer mem.free(tmp_str);

    const no_proxy_creds = !hasFeat(FEAT_PROXY) or
        Curl_http_acc_conn_http_proxy_peer(conn) == null or
        Curl_http_acc_conn_http_proxy_creds(conn) == null;
    const no_spnego = !hasFeat(FEAT_SPNEGO) or
        ((Curl_http_acc_auth_want(authhost) & CURLAUTH_NEGOTIATE) == 0 and
            (Curl_http_acc_auth_want(authproxy) & CURLAUTH_NEGOTIATE) == 0);
    const no_httpsig = !hasFeat(FEAT_HTTPSIG) or
        (Curl_http_acc_auth_want(authhost) & CURLAUTH_HTTPSIG) == 0;

    if (no_proxy_creds and no_spnego and no_httpsig and Curl_http_acc_state_creds(data) == null) {
        Curl_http_acc_auth_set_done(authhost, true);
        Curl_http_acc_auth_set_done(authproxy, true);
        return CURLE_OK;
    }

    if (query) |q| {
        tmp_str = curl_maprintf("%s?%s", path, q) orelse return CURLE_OUT_OF_MEMORY;
        path_and_query = tmp_str.?;
    }

    if (Curl_http_acc_auth_want(authhost) != 0 and Curl_http_acc_auth_picked(authhost) == 0)
        Curl_http_acc_auth_set_picked(authhost, Curl_http_acc_auth_want(authhost));

    if (Curl_http_acc_auth_want(authproxy) != 0 and Curl_http_acc_auth_picked(authproxy) == 0)
        Curl_http_acc_auth_set_picked(authproxy, Curl_http_acc_auth_want(authproxy));

    var result: CURLcode = CURLE_OK;
    if (hasFeat(FEAT_PROXY) and (Curl_http_acc_conn_bits_origin_is_proxy(conn) or is_connect)) {
        result = output_auth_headers(data, conn, authproxy, request, path_and_query, true);
        if (result != CURLE_OK)
            return result;
    } else {
        Curl_http_acc_auth_set_done(authproxy, true);
    }

    if (Curl_http_acc_state_creds(data) != null or Curl_http_acc_auth_allowed_to_host(data)) {
        result = output_auth_headers(data, conn, authhost, request, path_and_query, false);
    } else {
        Curl_http_acc_auth_set_done(authhost, true);
    }

    if (((Curl_http_acc_auth_multipass(authhost) and !Curl_http_acc_auth_done(authhost)) or
        (Curl_http_acc_auth_multipass(authproxy) and !Curl_http_acc_auth_done(authproxy))) and
        req_type != HTTPREQ_GET and
        req_type != HTTPREQ_HEAD)
    {
        Curl_http_acc_req_set_authneg(data, true);
    } else {
        Curl_http_acc_req_set_authneg(data, false);
    }

    return result;
}

fn authcmp(auth_name: []const u8, line: [*:0]const u8) bool {
    const n = auth_name.len;
    return curl_strnequal(auth_name.ptr, line, n) != 0 and !isAlnum(line[n]);
}

pub export fn Curl_http_input_auth(
    data: *Curl_easy,
    proxy: bool,
    auth_in: [*:0]const u8,
) callconv(.c) CURLcode {
    if (!hasFeat(FEAT_SPNEGO) and !hasFeat(FEAT_NTLM) and
        !hasFeat(FEAT_DIGEST_AUTH) and !hasFeat(FEAT_BASIC_AUTH) and
        !hasFeat(FEAT_BEARER_AUTH))
        return CURLE_OK;

    const availp = Curl_http_acc_info_authavail_ptr(data, proxy);
    const authp = if (proxy) Curl_http_acc_state_authproxy(data) else Curl_http_acc_state_authhost(data);
    const result: CURLcode = CURLE_OK;
    var cur: ?[*:0]const u8 = auth_in;

    while (cur) |a| {
        if (a[0] == 0)
            break;

        if (hasFeat(FEAT_SPNEGO) and authcmp("Negotiate", a)) {
            if ((Curl_http_acc_auth_avail(authp) & CURLAUTH_NEGOTIATE) != 0 or Curl_http_acc_is_spnego_supported()) {
                availp.* |= CURLAUTH_NEGOTIATE;
                Curl_http_acc_auth_set_avail(authp, Curl_http_acc_auth_avail(authp) | CURLAUTH_NEGOTIATE);
                if (Curl_http_acc_auth_picked(authp) == CURLAUTH_NEGOTIATE) {
                    if (Curl_http_acc_conn(data)) |conn| {
                        const rc = Curl_http_acc_input_negotiate(data, conn, proxy, a);
                        if (rc == CURLE_OK) {
                            mem.free(Curl_http_acc_req_newurl(data));
                            const dup = Curl_bufref_dup(Curl_http_acc_state_url_bufref(data));
                            Curl_http_acc_req_set_newurl(data, dup);
                            if (dup == null)
                                return CURLE_OUT_OF_MEMORY;
                            Curl_http_acc_state_set_authproblem(data, false);
                            Curl_http_acc_conn_set_nego_recv(conn, proxy);
                        } else {
                            Curl_http_acc_state_set_authproblem(data, true);
                        }
                    }
                }
            }
        }
        if (result == CURLE_OK and hasFeat(FEAT_NTLM) and authcmp("NTLM", a)) {
            if ((Curl_http_acc_auth_avail(authp) & CURLAUTH_NTLM) != 0 or Curl_http_acc_is_ntlm_supported()) {
                availp.* |= CURLAUTH_NTLM;
                Curl_http_acc_auth_set_avail(authp, Curl_http_acc_auth_avail(authp) | CURLAUTH_NTLM);
                if (Curl_http_acc_auth_picked(authp) == CURLAUTH_NTLM) {
                    const rc = Curl_http_acc_input_ntlm(data, proxy, a);
                    if (rc == CURLE_OK) {
                        Curl_http_acc_state_set_authproblem(data, false);
                    } else {
                        if (rc == CURLE_OUT_OF_MEMORY)
                            return rc;
                        Curl_infof(data, "NTLM authentication problem, ignoring.");
                        Curl_http_acc_state_set_authproblem(data, true);
                    }
                }
            }
        }
        if (result == CURLE_OK and hasFeat(FEAT_DIGEST_AUTH) and authcmp("Digest", a)) {
            if ((Curl_http_acc_auth_avail(authp) & CURLAUTH_DIGEST) != 0) {
                availp.* |= CURLAUTH_DIGEST;
                Curl_infof(data, "Ignoring duplicate digest auth header.");
            } else if (Curl_http_acc_is_digest_supported()) {
                availp.* |= CURLAUTH_DIGEST;
                Curl_http_acc_auth_set_avail(authp, Curl_http_acc_auth_avail(authp) | CURLAUTH_DIGEST);
                const rc = Curl_http_acc_input_digest(data, proxy, a);
                if (rc != CURLE_OK) {
                    if (rc == CURLE_OUT_OF_MEMORY)
                        return rc;
                    Curl_infof(data, "Digest authentication problem, ignoring.");
                    Curl_http_acc_state_set_authproblem(data, true);
                }
            }
        }
        if (result == CURLE_OK and hasFeat(FEAT_BASIC_AUTH) and authcmp("Basic", a)) {
            availp.* |= CURLAUTH_BASIC;
            Curl_http_acc_auth_set_avail(authp, Curl_http_acc_auth_avail(authp) | CURLAUTH_BASIC);
            if (Curl_http_acc_auth_picked(authp) == CURLAUTH_BASIC) {
                Curl_http_acc_auth_set_avail(authp, CURLAUTH_NONE);
                Curl_infof(data, "Basic authentication problem, ignoring.");
                Curl_http_acc_state_set_authproblem(data, true);
            }
        }
        if (hasFeat(FEAT_BEARER_AUTH) and authcmp("Bearer", a)) {
            availp.* |= CURLAUTH_BEARER;
            Curl_http_acc_auth_set_avail(authp, Curl_http_acc_auth_avail(authp) | CURLAUTH_BEARER);
            if (Curl_http_acc_auth_picked(authp) == CURLAUTH_BEARER) {
                Curl_http_acc_auth_set_avail(authp, CURLAUTH_NONE);
                Curl_infof(data, "Bearer authentication problem, ignoring.");
                Curl_http_acc_state_set_authproblem(data, true);
            }
        }

        if (result != CURLE_OK)
            break;

        const slice = std.mem.span(a);
        if (std.mem.indexOfScalar(u8, slice, ',')) |idx| {
            var next_p: ?[*:0]const u8 = a + idx + 1;
            curlx_str_passblanks(&next_p);
            cur = next_p;
        } else {
            break;
        }
    }
    return result;
}

// ============================================================================
// 4. Redirect & Follow Logic (Curl_http_follow) & Curl_compareheader
// ============================================================================

fn http_switch_to_get(data: *Curl_easy, code: c_int) void {
    const req = Curl_http_acc_str_customrequest(data);
    if ((req != null or Curl_http_acc_state_httpreq(data) != HTTPREQ_GET) and
        Curl_http_acc_set_http_follow_mode(data) == CURLFOLLOW_OBEYCODE)
    {
        Curl_infof(data, "Switch to GET because of %d response", code);
        Curl_http_acc_state_set_http_ignorecustom(data, true);
    } else if (req) |r| {
        if (Curl_http_acc_set_http_follow_mode(data) != CURLFOLLOW_FIRSTONLY)
            Curl_infof(data, "Stick to %s instead of GET", r);
    }
    Curl_http_acc_state_set_httpreq(data, @intCast(HTTPREQ_GET));
    sendf.Curl_creader_set_rewind(data, false);
}

fn httpreq_is_post(data: *const Curl_easy) bool {
    const r = Curl_http_acc_state_httpreq(data);
    return r == HTTPREQ_POST or r == HTTPREQ_POST_FORM or r == HTTPREQ_POST_MIME;
}

fn set_auto_referer(data: *Curl_easy) CURLcode {
    Curl_bufref_free(Curl_http_acc_state_referer_bufref(data));
    const u = urlapi.curl_url() orelse return CURLE_OUT_OF_MEMORY;
    defer urlapi.curl_url_cleanup(u);

    var referer: ?[*:0]u8 = null;
    var uc = urlapi.curl_url_set(u, .CURLUPART_URL, Curl_bufref_ptr(Curl_http_acc_state_url_bufref(data)), 0);
    if (uc == .CURLUE_OK)
        uc = urlapi.curl_url_set(u, .CURLUPART_FRAGMENT, null, 0);
    if (uc == .CURLUE_OK)
        uc = urlapi.curl_url_set(u, .CURLUPART_USER, null, 0);
    if (uc == .CURLUE_OK)
        uc = urlapi.curl_url_set(u, .CURLUPART_PASSWORD, null, 0);
    if (uc == .CURLUE_OK)
        uc = urlapi.curl_url_get(u, .CURLUPART_URL, &referer, 0);

    if (uc != .CURLUE_OK or referer == null)
        return CURLE_OUT_OF_MEMORY;

    Curl_bufref_set(Curl_http_acc_state_referer_bufref(data), referer, 0, curl_free);
    return CURLE_OK;
}

fn follow_parse_url(
    data: *Curl_easy,
    newurl: [*:0]const u8,
    ftype: followtype,
    follow_urlp: *?[*:0]u8,
    ucp: *CURLUcode,
) CURLcode {
    const uh = Curl_http_acc_state_uh(data) orelse return CURLE_BAD_FUNCTION_ARGUMENT;
    var flags: c_uint = urlapi.CURLU_ALLOW_SPACE;
    if (ftype == FOLLOW_FAKE) {
        flags |= urlapi.CURLU_NON_SUPPORT_SCHEME;
    } else if (ftype == FOLLOW_REDIR) {
        flags |= urlapi.CURLU_URLENCODE;
    }
    if (Curl_http_acc_set_path_as_is(data))
        flags |= urlapi.CURLU_PATH_AS_IS;

    var uc = urlapi.curl_url_set(uh, .CURLUPART_URL, newurl, flags);
    ucp.* = uc;
    if (uc != .CURLUE_OK) {
        if (uc == .CURLUE_OUT_OF_MEMORY or ftype != FOLLOW_FAKE) {
            Curl_failf(data, "The redirect target URL could not be parsed: %s", curl_url_strerror(uc));
            return Curl_uc_to_curlcode(uc);
        }
        follow_urlp.* = mem.strdup(newurl);
        if (follow_urlp.* == null)
            return CURLE_OUT_OF_MEMORY;
    } else {
        const u = urlapi.curl_url() orelse return CURLE_OUT_OF_MEMORY;
        defer urlapi.curl_url_cleanup(u);
        uc = urlapi.curl_url_set(
            u,
            .CURLUPART_URL,
            Curl_bufref_ptr(Curl_http_acc_state_url_bufref(data)),
            urlapi.CURLU_URLENCODE | urlapi.CURLU_ALLOW_SPACE,
        );
        if (uc == .CURLUE_OK)
            uc = urlapi.curl_url_get(uh, .CURLUPART_URL, follow_urlp, 0);
        if (uc != .CURLUE_OK)
            return Curl_uc_to_curlcode(uc);

        if (hasFeat(FEAT_DIGEST_AUTH)) {
            if (!urlapi.Curl_url_same_origin(u, uh))
                Curl_http_acc_digest_cleanup(data);
        }
    }
    return CURLE_OK;
}

fn follow_fake(
    data: *Curl_easy,
    follow_url_in: [*:0]u8,
    uc: CURLUcode,
    reachedmax: bool,
) CURLcode {
    var follow_url = follow_url_in;
    if (uc == .CURLUE_OK) {
        const u = urlapi.curl_url();
        if (u == null) {
            mem.free(follow_url);
            return CURLE_OUT_OF_MEMORY;
        }
        defer urlapi.curl_url_cleanup(u);

        var nocred: ?[*:0]u8 = null;
        const flags: c_uint = urlapi.CURLU_NON_SUPPORT_SCHEME |
            (if (Curl_http_acc_set_path_as_is(data)) urlapi.CURLU_PATH_AS_IS else 0);
        if (urlapi.curl_url_set(u.?, .CURLUPART_URL, follow_url, flags) == .CURLUE_OK and
            urlapi.curl_url_set(u.?, .CURLUPART_USER, null, 0) == .CURLUE_OK and
            urlapi.curl_url_set(u.?, .CURLUPART_PASSWORD, null, 0) == .CURLUE_OK)
        {
            _ = urlapi.curl_url_get(u.?, .CURLUPART_URL, &nocred, urlapi.CURLU_GET_EMPTY);
        }
        if (nocred) |nc| {
            mem.free(follow_url);
            follow_url = nc;
        }
    }
    Curl_http_acc_info_set_wouldredirect(data, follow_url);

    if (reachedmax) {
        Curl_failf(data, "Maximum (%ld) redirects followed", Curl_http_acc_set_maxredirs(data));
        return CURLE_TOO_MANY_REDIRECTS;
    }
    return CURLE_OK;
}

fn follow_switch_get(data: *Curl_easy) bool {
    switch (Curl_http_acc_info_httpcode(data)) {
        301 => {
            if (httpreq_is_post(data) and !Curl_http_acc_set_post301(data)) {
                http_switch_to_get(data, 301);
                return true;
            }
        },
        302 => {
            if (httpreq_is_post(data) and !Curl_http_acc_set_post302(data)) {
                http_switch_to_get(data, 302);
                return true;
            }
        },
        303 => {
            if (!httpreq_is_post(data) or !Curl_http_acc_set_post303(data)) {
                http_switch_to_get(data, 303);
                return true;
            }
        },
        else => {},
    }
    return false;
}

pub export fn Curl_http_follow(
    data: *Curl_easy,
    newurl: [*:0]const u8,
    type_in: followtype,
) callconv(.c) CURLcode {
    var ftype = type_in;
    var disallowport = false;
    var reachedmax = false;
    var follow_url: ?[*:0]u8 = null;
    var uc: CURLUcode = .CURLUE_OK;

    if (ftype != FOLLOW_FAKE)
        Curl_http_acc_state_inc_requests(data);

    if (ftype == FOLLOW_REDIR) {
        const maxredirs = Curl_http_acc_set_maxredirs(data);
        if (maxredirs != -1 and Curl_http_acc_state_followlocation(data) >= maxredirs) {
            reachedmax = true;
            ftype = FOLLOW_FAKE;
        } else {
            Curl_http_acc_state_inc_followlocation(data);
            if (Curl_http_acc_set_http_auto_referer(data)) {
                const res = set_auto_referer(data);
                if (res != CURLE_OK)
                    return res;
            }
        }
    }

    const httpcode = Curl_http_acc_req_httpcode(data);
    if (ftype != FOLLOW_RETRY and
        httpcode != 401 and httpcode != 407 and
        urlapi.Curl_is_absolute_url(newurl, null, 0, false) != 0)
    {
        disallowport = true;
    }

    const result = follow_parse_url(data, newurl, ftype, &follow_url, &uc);
    if (result != CURLE_OK)
        return result;

    const furl = follow_url orelse return CURLE_OUT_OF_MEMORY;
    if (ftype == FOLLOW_FAKE)
        return follow_fake(data, furl, uc, reachedmax);

    if (disallowport)
        Curl_http_acc_state_set_allow_port(data, false);

    Curl_bufref_set(Curl_http_acc_state_url_bufref(data), furl, 0, curl_free);
    const rewind_result = Curl_http_acc_req_soft_reset(data);
    Curl_infof(data, "Issue another request to this URL: '%s'", furl);
    if (Curl_http_acc_set_http_follow_mode(data) == CURLFOLLOW_FIRSTONLY and
        !Curl_http_acc_state_http_ignorecustom(data) and
        Curl_http_acc_str_customrequest(data) != null)
    {
        Curl_http_acc_state_set_http_ignorecustom(data, true);
        Curl_infof(data, "Drop custom request method for next request");
    }

    const switch_to_get = follow_switch_get(data);
    if (rewind_result != CURLE_OK and !switch_to_get)
        return rewind_result;

    Curl_pgrsTime(data, TIMER_REDIRECT);
    Curl_pgrsResetTransferSizes(data);
    return CURLE_OK;
}

pub export fn Curl_compareheader(
    headerline: [*:0]const u8,
    header: [*:0]const u8,
    hlen: usize,
    content: [*:0]const u8,
    clen: usize,
) callconv(.c) bool {
    if (curl_strnequal(headerline, header, hlen) == 0)
        return false;

    var p: ?[*:0]const u8 = headerline + hlen;
    var val = std.mem.zeroes(Curl_str);
    if (curlx_str_cspn(&p, &val, "\r\n") != 0)
        return false;
    curlx_str_trimblanks(&val);

    if (val.len >= clen) {
        var len = val.len;
        p = @ptrCast(val.str);
        while (len >= clen) {
            var next = std.mem.zeroes(Curl_str);
            const cur = p orelse break;
            const o = cur;
            if (curl_strnequal(cur, content, clen) != 0 and
                (cur[clen] == ',' or isBlank(cur[clen]) or isNewline(cur[clen]) or cur[clen] == 0))
            {
                return true;
            }
            if (curlx_str_until(&p, &next, len, ',') != 0 or
                curlx_str_single(&p, ',') != 0)
                break;

            while (true) {
                curlx_str_passblanks(&p);
                if (curlx_str_single(&p, ',') != 0)
                    break;
            }
            const after = p orelse break;
            const diff = @intFromPtr(after) - @intFromPtr(o);
            if (diff > len)
                break;
            len -= diff;
        }
    }
    return false;
}

// ============================================================================
// 5. 100-Continue Reader (cr_exp100), Pollsets, Curl_http_done, Custom Headers
// ============================================================================

const cr_exp100_ctx = extern struct {
    super: sendf.CurlCreader,
    start: Curltime,
    state: c_uint,
};

inline fn crExp100Ctx(reader: *sendf.CurlCreader) *cr_exp100_ctx {
    return @ptrCast(@alignCast(reader.ctx));
}

fn http_exp100_continue(data: *Curl_easy, reader: *sendf.CurlCreader) void {
    const ctx = crExp100Ctx(reader);
    if (ctx.state > EXP100_SEND_DATA) {
        ctx.state = EXP100_SEND_DATA;
        Curl_expire_clear(data, EXPIRE_100_TIMEOUT);
    }
}

fn cr_exp100_read(
    data: ?*sendf.CurlEasy,
    reader: *sendf.CurlCreader,
    buf: ?[*]u8,
    blen: usize,
    nread: *usize,
    eos: *bool,
) callconv(.c) CURLcode {
    const d = data orelse return CURLE_BAD_FUNCTION_ARGUMENT;
    const ctx = crExp100Ctx(reader);

    switch (ctx.state) {
        EXP100_SENDING_REQUEST => {
            if (!Curl_req_sendbuf_empty(d)) {
                nread.* = 0;
                eos.* = false;
                return CURLE_OK;
            }
            ctx.state = EXP100_AWAITING_CONTINUE;
            ctx.start = Curl_pgrs_now(d).*;
            const timeout_ms: timediff_t = @intCast(Curl_http_acc_set_expect_100_timeout(d));
            Curl_expire_set(d, EXPIRE_100_TIMEOUT, timeout_ms, &ctx.start);
            nread.* = 0;
            eos.* = false;
            return CURLE_OK;
        },
        EXP100_FAILED => {
            nread.* = 0;
            eos.* = false;
            return CURLE_READ_ERROR;
        },
        EXP100_AWAITING_CONTINUE => {
            const ms = curlx_time_net.curlx_ptimediff_ms(Curl_pgrs_now(d), &ctx.start);
            const timeout_ms: timediff_t = @intCast(Curl_http_acc_set_expect_100_timeout(d));
            if (ms < timeout_ms) {
                nread.* = 0;
                eos.* = false;
                return CURLE_OK;
            }
            http_exp100_continue(d, reader);
            Curl_infof(d, "Done waiting for 100-continue");
            return sendf.Curl_creader_read(data, reader.next, buf, blen, nread, eos);
        },
        else => {
            return sendf.Curl_creader_read(data, reader.next, buf, blen, nread, eos);
        },
    }
}

fn cr_exp100_done(
    data: ?*sendf.CurlEasy,
    reader: *sendf.CurlCreader,
    premature: c_int,
) callconv(.c) void {
    const d = data orelse return;
    const ctx = crExp100Ctx(reader);
    ctx.state = if (premature != 0) EXP100_FAILED else EXP100_SEND_DATA;
    Curl_expire_clear(d, EXPIRE_100_TIMEOUT);
}

pub const cr_exp100 = sendf.CurlCrtype{
    .name = "cr-exp100",
    .do_init = sendf.Curl_creader_def_init,
    .do_read = cr_exp100_read,
    .do_close = sendf.Curl_creader_def_close,
    .needs_rewind = sendf.Curl_creader_def_needs_rewind,
    .total_length = sendf.Curl_creader_def_total_length,
    .resume_from = sendf.Curl_creader_def_resume_from,
    .cntrl = sendf.Curl_creader_def_cntrl,
    .is_paused = sendf.Curl_creader_def_is_paused,
    .done = cr_exp100_done,
    .creader_size = @sizeOf(cr_exp100_ctx),
};

fn http_exp100_add_reader(data: *Curl_easy) CURLcode {
    var reader: ?*sendf.CurlCreader = null;
    var result = sendf.Curl_creader_create(&reader, data, &cr_exp100, sendf.CURL_CR_PROTOCOL);
    if (result == CURLE_OK)
        result = sendf.Curl_creader_add(data, reader.?);
    if (result == CURLE_OK) {
        const ctx = crExp100Ctx(reader.?);
        ctx.state = EXP100_SENDING_REQUEST;
    }
    if (result != CURLE_OK and reader != null)
        sendf.Curl_creader_free(data, reader);
    return result;
}

fn http_exp100_got100(data: *Curl_easy) void {
    if (sendf.Curl_creader_get_by_type(data, &cr_exp100)) |r| {
        http_exp100_continue(data, r);
    }
}

fn http_exp100_is_waiting(data: *Curl_easy) bool {
    if (sendf.Curl_creader_get_by_type(data, &cr_exp100)) |r| {
        const ctx = crExp100Ctx(r);
        return ctx.state == EXP100_AWAITING_CONTINUE;
    }
    return false;
}

fn http_exp100_send_anyway(data: *Curl_easy) void {
    if (sendf.Curl_creader_get_by_type(data, &cr_exp100)) |r| {
        http_exp100_continue(data, r);
    }
}

fn http_exp100_is_selected(data: *Curl_easy) bool {
    return sendf.Curl_creader_get_by_type(data, &cr_exp100) != null;
}

pub export fn Curl_http_doing_pollset(
    data: *Curl_easy,
    ps: *easy_pollset,
) callconv(.c) CURLcode {
    const conn = Curl_http_acc_conn(data) orelse return CURLE_BAD_FUNCTION_ARGUMENT;
    return headers_sock.Curl_pollset_change(
        data,
        ps,
        Curl_http_acc_conn_firstsocket(conn),
        headers_sock.CURL_POLL_OUT,
        0,
    );
}

pub export fn Curl_http_perform_pollset(
    data: *Curl_easy,
    ps: *easy_pollset,
) callconv(.c) CURLcode {
    const conn = Curl_http_acc_conn(data) orelse return CURLE_BAD_FUNCTION_ARGUMENT;
    var result: CURLcode = CURLE_OK;

    if (Curl_http_acc_req_want_recv(data)) {
        result = headers_sock.Curl_pollset_change(
            data,
            ps,
            Curl_http_acc_conn_firstsocket(conn),
            headers_sock.CURL_POLL_IN,
            0,
        );
    }

    if (result == CURLE_OK and Curl_req_want_send(data) and !http_exp100_is_waiting(data)) {
        result = headers_sock.Curl_pollset_change(
            data,
            ps,
            Curl_http_acc_conn_firstsocket(conn),
            headers_sock.CURL_POLL_OUT,
            0,
        );
    }
    return result;
}

fn http_write_header(
    data: *Curl_easy,
    hd: [*]const u8,
    hdlen: usize,
) CURLcode {
    Curl_debug(data, CURLINFO_HEADER_IN, hd, hdlen);

    const httpcode = Curl_http_acc_req_httpcode(data);
    const writetype: c_int = sendf.CLIENTWRITE_HEADER |
        (if (@divTrunc(httpcode, 100) == 1) sendf.CLIENTWRITE_1XX else 0);

    var result = sendf.Curl_client_write(data, writetype, hd, hdlen);
    if (result != CURLE_OK)
        return result;

    result = Curl_bump_headersize(data, hdlen, false);
    if (result != CURLE_OK)
        return result;

    const cur_hc = Curl_http_acc_req_httpcode(data);
    const deduct: c_uint = if (100 <= cur_hc and cur_hc <= 199)
        Curl_http_acc_req_headerbytecount(data)
    else
        0;
    Curl_http_acc_req_set_deductheadercount(data, deduct);
    return result;
}

pub export fn Curl_http_done(
    data: *Curl_easy,
    status: CURLcode,
    premature: bool,
) callconv(.c) CURLcode {
    const conn = Curl_http_acc_conn(data) orelse return CURLE_BAD_FUNCTION_ARGUMENT;

    Curl_http_acc_auth_set_multipass(Curl_http_acc_state_authhost(data), false);
    Curl_http_acc_auth_set_multipass(Curl_http_acc_state_authproxy(data), false);

    const hb = Curl_http_acc_state_headerb(data);
    if (containers.curlx_dyn_len(hb) > 0) {
        if (containers.curlx_dyn_ptr(hb)) |ptr| {
            _ = http_write_header(data, ptr, containers.curlx_dyn_len(hb));
        }
    }
    containers.curlx_dyn_reset(hb);

    if (status != CURLE_OK)
        return status;

    if (!premature and
        !Curl_http_acc_conn_bits_retry(conn) and
        Curl_http_acc_set_connect_only(data) == 0 and
        (Curl_http_acc_req_bytecount(data) +
            @as(curl_off_t, Curl_http_acc_req_headerbytecount(data)) -
            @as(curl_off_t, Curl_http_acc_req_deductheadercount(data))) <= 0)
    {
        Curl_failf(data, "Empty reply from server");
        streamclose(conn);
        return CURLE_GOT_NOTHING;
    }

    return CURLE_OK;
}

fn http_may_use_1_1(data: *const Curl_easy) bool {
    const conn = Curl_http_acc_conn(@constCast(data));
    const neg = Curl_http_acc_state_http_neg(data);
    if (Curl_http_acc_neg_rcvd_min(neg) == 10)
        return false;
    if (conn != null and Curl_http_acc_conn_httpversion_seen(conn.?) == 10)
        return false;
    if (Curl_http_acc_neg_only_10(neg) and
        (conn == null or Curl_http_acc_conn_httpversion_seen(conn.?) <= 10))
        return false;
    return !Curl_http_acc_neg_only_10(neg);
}

fn http_request_version(data: *Curl_easy) u8 {
    var v = Curl_conn_http_version(data, Curl_http_acc_conn(data));
    if (v == 0) {
        v = if (http_may_use_1_1(data)) 11 else 10;
    }
    return v;
}

fn get_http_string(httpversion: c_int) [*:0]const u8 {
    return switch (httpversion) {
        30 => "3",
        20 => "2",
        11 => "1.1",
        else => "1.0",
    };
}

pub export fn Curl_add_custom_headers(
    data: *Curl_easy,
    is_connect: bool,
    httpversion: c_int,
    req: *dynbuf,
) callconv(.c) CURLcode {
    var h: [2]?*curl_slist = .{ null, null };
    var numlists: usize = 1;

    if (!hasFeat(FEAT_PROXY)) {
        h[0] = Curl_http_acc_set_headers(data);
    } else {
        const conn = Curl_http_acc_conn(data) orelse return CURLE_BAD_FUNCTION_ARGUMENT;
        if (is_connect) {
            if (Curl_http_acc_set_sep_headers(data)) {
                h[0] = Curl_http_acc_set_proxyheaders(data);
            } else {
                h[0] = Curl_http_acc_set_headers(data);
            }
        } else if (Curl_http_acc_conn_bits_origin_is_proxy(conn)) {
            h[0] = Curl_http_acc_set_headers(data);
            if (Curl_http_acc_set_sep_headers(data)) {
                h[1] = Curl_http_acc_set_proxyheaders(data);
                numlists += 1;
            }
        } else {
            h[0] = Curl_http_acc_set_headers(data);
        }
    }

    for (0..numlists) |i| {
        var headers = h[i];
        while (headers) |node| : (headers = node.next) {
            const origp = node.data orelse continue;
            var p: ?[*:0]const u8 = origp;
            const hlen = std.mem.len(origp);
            var name = std.mem.zeroes(Curl_str);
            var blankheader = false;

            if (curlx_str_until(&p, &name, hlen, ';') == 0 and
                curlx_str_single(&p, ';') == 0 and
                curlx_str_single(&p, 0) == 0 and
                (name.len == 0 or std.mem.indexOfScalar(u8, name.str.?[0..name.len], ':') == null))
            {
                blankheader = true;
            } else {
                p = origp;
                if (curlx_str_until(&p, &name, hlen, ':') == 0 and
                    curlx_str_single(&p, ':') == 0)
                {
                    var val = std.mem.zeroes(Curl_str);
                    _ = curlx_str_untilnl(&p, &val, hlen);
                    curlx_str_trimblanks(&val);
                    if (val.len == 0)
                        continue;
                } else {
                    continue;
                }
            }

            curlx_str_trimblanks(&name);

            var result: CURLcode = CURLE_OK;
            if (Curl_http_acc_state_http_host(data) != null and
                curlx_str_casecompare(&name, "Host") != 0)
            {
                // skip
            } else if (Curl_http_acc_state_httpreq(data) == HTTPREQ_POST_FORM and
                curlx_str_casecompare(&name, "Content-Type") != 0)
            {
                // skip
            } else if (Curl_http_acc_state_httpreq(data) == HTTPREQ_POST_MIME and
                curlx_str_casecompare(&name, "Content-Type") != 0)
            {
                // skip
            } else if (Curl_http_acc_req_authneg(data) and
                curlx_str_casecompare(&name, "Content-Length") != 0)
            {
                // skip
            } else if (curlx_str_casecompare(&name, "Connection") != 0) {
                // skip
            } else if (httpversion >= 20 and
                curlx_str_casecompare(&name, "Transfer-Encoding") != 0)
            {
                // skip
            } else if ((curlx_str_casecompare(&name, "Authorization") != 0 or
                curlx_str_casecompare(&name, "Cookie") != 0) and
                !Curl_http_acc_auth_allowed_to_host(data))
            {
                // skip
            } else if (blankheader) {
                if (name.str) |ns| {
                    result = containers.curlx_dyn_addn(req, ns, name.len);
                }
                if (result == CURLE_OK)
                    result = containers.curlx_dyn_addn(req, ":\r\n", 3);
            } else {
                result = containers.curlx_dyn_addf(req, "%s\r\n", origp);
            }

            if (result != CURLE_OK)
                return result;
        }
    }
    return CURLE_OK;
}

pub export fn Curl_add_timecondition(
    data: *Curl_easy,
    req: *dynbuf,
) callconv(.c) CURLcode {
    if (!hasFeat(FEAT_PARSEDATE))
        return CURLE_OK;

    const tc = Curl_http_acc_set_timecondition(data);
    if (tc == CURL_TIMECOND_NONE)
        return CURLE_OK;

    var keeptime = std.mem.zeroes(Tm);
    const result = curlx_gmtime(@intCast(Curl_http_acc_set_timevalue(data)), &keeptime);
    if (result != CURLE_OK) {
        Curl_failf(data, "Invalid TIMEVALUE");
        return result;
    }

    var condp: [*:0]const u8 = undefined;
    var len: usize = 0;
    switch (tc) {
        CURL_TIMECOND_IFMODSINCE => {
            condp = "If-Modified-Since";
            len = 17;
        },
        CURL_TIMECOND_IFUNMODSINCE => {
            condp = "If-Unmodified-Since";
            len = 19;
        },
        CURL_TIMECOND_LASTMOD => {
            condp = "Last-Modified";
            len = 13;
        },
        else => return CURLE_BAD_FUNCTION_ARGUMENT,
    }

    if (Curl_checkheaders(data, condp, len) != null)
        return CURLE_OK;

    const wday_idx: usize = if (keeptime.tm_wday != 0) @intCast(keeptime.tm_wday - 1) else 6;
    const mon_idx: usize = if (keeptime.tm_mon >= 0 and keeptime.tm_mon < 12) @intCast(keeptime.tm_mon) else 0;

    return containers.curlx_dyn_addf(
        req,
        "%s: %s, %02d %s %4d %02d:%02d:%02d GMT\r\n",
        condp,
        Curl_wkday[wday_idx],
        keeptime.tm_mday,
        Curl_month[mon_idx],
        keeptime.tm_year + 1900,
        keeptime.tm_hour,
        keeptime.tm_min,
        keeptime.tm_sec,
    );
}

// ============================================================================
// 6. Request Building Steps (Curl_http_method, host, target, reader, headers)
// ============================================================================

pub export fn Curl_http_method(
    data: *Curl_easy,
    method: *?[*:0]const u8,
    reqp: *Curl_HttpReq,
) callconv(.c) void {
    const conn = Curl_http_acc_conn(data).?;
    var httpreq_val: Curl_HttpReq = Curl_http_acc_state_httpreq(data);
    var request: [*:0]const u8 = "GET";

    if (hasFeat(FEAT_WEBSOCKETS) and
        (Curl_http_acc_conn_scheme_protocol(conn) & (CURLPROTO_WS | CURLPROTO_WSS)) != 0)
    {
        httpreq_val = HTTPREQ_GET;
    } else if ((Curl_http_acc_conn_scheme_protocol(conn) & (PROTO_FAMILY_HTTP | CURLPROTO_FTP)) != 0 and
        Curl_http_acc_state_upload(data))
    {
        httpreq_val = HTTPREQ_PUT;
    }

    const custom = Curl_http_acc_str_customrequest(data);
    if (!Curl_http_acc_state_http_ignorecustom(data) and custom != null) {
        request = custom.?;
    } else if (Curl_http_acc_req_no_body(data)) {
        request = "HEAD";
    } else {
        request = switch (httpreq_val) {
            HTTPREQ_POST, HTTPREQ_POST_FORM, HTTPREQ_POST_MIME => "POST",
            HTTPREQ_PUT => "PUT",
            HTTPREQ_HEAD => "HEAD",
            else => "GET",
        };
    }
    method.* = request;
    reqp.* = httpreq_val;
}

fn http_set_aptr_host(data: *Curl_easy) CURLcode {
    const conn = Curl_http_acc_conn(data) orelse return CURLE_BAD_FUNCTION_ARGUMENT;
    var ptr: ?[*:0]u8 = null;

    mem.free(Curl_http_acc_state_http_host(data));
    Curl_http_acc_state_set_http_host(data, null);
    if (hasFeat(FEAT_COOKIES)) {
        mem.free(Curl_http_acc_req_cookiehost(data));
        Curl_http_acc_req_set_cookiehost(data, null);
    }

    const origin = Curl_http_acc_state_origin(data);
    if (Curl_peer_equal(Curl_http_acc_state_initial_origin(data), origin)) {
        ptr = Curl_checkheaders(data, "Host", "Host".len);
    }

    if (ptr) |p| {
        if (hasFeat(FEAT_COOKIES)) {
            var cookiehost: ?[*:0]u8 = null;
            const res = copy_custom_value(p, &cookiehost);
            if (res != CURLE_OK)
                return res;
            if (cookiehost) |ch| {
                if (ch[0] == 0) {
                    mem.free(ch);
                } else {
                    if (ch[0] == '[') {
                        const clen = std.mem.len(ch);
                        std.mem.copyForwards(u8, ch[0 .. clen - 1], ch[1..clen]);
                        ch[clen - 1] = 0;
                        const s = std.mem.span(ch);
                        if (std.mem.indexOfScalar(u8, s, ']')) |idx| {
                            ch[idx] = 0;
                        }
                    } else {
                        const s = std.mem.span(ch);
                        if (std.mem.indexOfScalar(u8, s, ':')) |idx| {
                            ch[idx] = 0;
                        }
                    }
                    Curl_http_acc_req_set_cookiehost(data, ch);
                }
            }
        }

        if (curl_strequal("Host:", p) == 0) {
            const h = curl_maprintf("Host:%s", p + 5) orelse
                return CURLE_OUT_OF_MEMORY;
            Curl_http_acc_state_set_http_host(data, h);
        }
    } else {
        const ipv6 = Curl_http_acc_peer_ipv6(origin);
        var tmp: dynbuf = undefined;
        var hlen: usize = 0;
        containers.curlx_dyn_init(&tmp, DYN_HTTP_REQUEST);
        var result = containers.curlx_dyn_addn(&tmp, "Host: ", 6);
        if (result == CURLE_OK and ipv6)
            result = containers.curlx_dyn_addn(&tmp, "[", 1);
        if (result == CURLE_OK) {
            if (Curl_http_acc_peer_hostname(origin)) |hn| {
                result = containers.curlx_dyn_add(&tmp, hn);
            }
        }
        if (result == CURLE_OK and ipv6)
            result = containers.curlx_dyn_addn(&tmp, "]", 1);
        if (result == CURLE_OK and
            ((Curl_http_acc_peer_port(origin) != Curl_http_acc_peer_scheme_defport(origin)) or
                (Curl_http_acc_peer_scheme_family(origin) != Curl_http_acc_conn_scheme_family(conn))))
        {
            result = containers.curlx_dyn_addf(&tmp, ":%u", @as(c_uint, @intCast(Curl_http_acc_peer_port(origin))));
        }

        const taken = if (result != CURLE_OK) null else containers.curlx_dyn_take(&tmp, &hlen);
        Curl_http_acc_state_set_http_host(data, taken);
        containers.curlx_dyn_free(&tmp);
        return result;
    }
    return CURLE_OK;
}

fn http_target(data: *Curl_easy, r: *dynbuf) CURLcode {
    var result: CURLcode = CURLE_OK;
    var path: [*:0]const u8 = Curl_http_acc_state_up_path(data) orelse "/";
    var query: ?[*:0]const u8 = Curl_http_acc_state_up_query(data);

    if (Curl_http_acc_str_target(data)) |t| {
        path = t;
        query = null;
    }

    if (hasFeat(FEAT_PROXY)) {
        const conn = Curl_http_acc_conn(data) orelse return CURLE_BAD_FUNCTION_ARGUMENT;
        if (Curl_http_acc_conn_bits_origin_is_proxy(conn)) {
            var url: ?[*:0]u8 = null;
            const uh = Curl_http_acc_state_uh(data) orelse return CURLE_OUT_OF_MEMORY;
            const h = urlapi.curl_url_dup(uh) orelse return CURLE_OUT_OF_MEMORY;
            defer urlapi.curl_url_cleanup(h);

            const origin = Curl_http_acc_state_origin(data);
            if (!Curl_http_acc_peer_ipv6(origin) and
                Curl_http_acc_peer_user_hostname(origin) != Curl_http_acc_peer_hostname(origin))
            {
                const uc = urlapi.curl_url_set(h, .CURLUPART_HOST, Curl_http_acc_peer_hostname(origin), 0);
                if (uc != .CURLUE_OK)
                    return CURLE_OUT_OF_MEMORY;
            }
            if (urlapi.curl_url_set(h, .CURLUPART_FRAGMENT, null, 0) != .CURLUE_OK)
                return CURLE_OUT_OF_MEMORY;

            if (Curl_http_acc_peer_is_http(origin)) {
                if (urlapi.curl_url_set(h, .CURLUPART_USER, null, 0) != .CURLUE_OK)
                    return CURLE_OUT_OF_MEMORY;
                if (urlapi.curl_url_set(h, .CURLUPART_PASSWORD, null, 0) != .CURLUE_OK)
                    return CURLE_OUT_OF_MEMORY;
            } else if (Curl_http_acc_state_creds(data)) |creds| {
                if (!Curl_http_acc_creds_from_url(creds)) {
                    var uc = urlapi.curl_url_set(h, .CURLUPART_USER, Curl_http_acc_creds_user(creds), urlapi.CURLU_URLENCODE);
                    if (uc == .CURLUE_OK)
                        uc = urlapi.curl_url_set(h, .CURLUPART_PASSWORD, Curl_http_acc_creds_passwd(creds), urlapi.CURLU_URLENCODE);
                    if (uc != .CURLUE_OK)
                        return Curl_uc_to_curlcode(uc);
                }
            }

            if (urlapi.curl_url_get(h, .CURLUPART_URL, &url, urlapi.CURLU_NO_DEFAULT_PORT) != .CURLUE_OK or url == null)
                return CURLE_OUT_OF_MEMORY;
            defer mem.free(url);

            const target_or_url: [*:0]const u8 = Curl_http_acc_str_target(data) orelse url.?;
            result = containers.curlx_dyn_add(r, target_or_url);
            if (result != CURLE_OK)
                return result;

            if (Curl_http_acc_peer_is_ftp(origin) and Curl_http_acc_set_proxy_transfer_mode(data)) {
                const len = std.mem.len(path);
                var type_present = false;
                if (len >= 7 and std.mem.eql(u8, path[len - 7 .. len - 1], ";type=")) {
                    switch (std.ascii.toUpper(path[len - 1])) {
                        'A', 'D', 'I' => type_present = true,
                        else => {},
                    }
                }
                if (!type_present) {
                    const tc: c_int = if (Curl_http_acc_state_prefer_ascii(data)) 'a' else 'i';
                    result = containers.curlx_dyn_addf(r, ";type=%c", tc);
                    if (result != CURLE_OK)
                        return result;
                }
            }
            return result;
        }
    }

    result = containers.curlx_dyn_add(r, path);
    if (result != CURLE_OK)
        return result;
    if (query) |q| {
        result = containers.curlx_dyn_addf(r, "?%s", q);
    }
    return result;
}

fn set_reader(data: *Curl_easy, httpreq_val: Curl_HttpReq) CURLcode {
    var result: CURLcode = CURLE_OK;
    const postsize = Curl_http_acc_state_infilesize(data);

    if (Curl_http_acc_req_authneg(data))
        return sendf.Curl_creader_set_null(data);

    switch (httpreq_val) {
        HTTPREQ_PUT => {
            return if (postsize != 0)
                sendf.Curl_creader_set_fread(data, postsize)
            else
                sendf.Curl_creader_set_null(data);
        },
        HTTPREQ_POST_FORM, HTTPREQ_POST_MIME => {
            if (hasFeat(FEAT_MIME) or hasFeat(FEAT_FORM_API)) {
                return Curl_http_acc_set_post_reader(data, httpreq_val);
            }
            Curl_http_acc_state_set_infilesize(data, 0);
            return sendf.Curl_creader_set_null(data);
        },
        HTTPREQ_POST => {
            if (postsize == 0) {
                result = sendf.Curl_creader_set_null(data);
            } else if (Curl_http_acc_set_postfields(data)) |pf| {
                if (postsize < 0 or @as(u64, @intCast(postsize)) >= std.math.maxInt(usize))
                    return CURLE_OUT_OF_MEMORY;
                const plen: usize = @intCast(postsize);
                if (plen != 0) {
                    result = sendf.Curl_creader_set_buf(data, pf, plen);
                } else {
                    result = sendf.Curl_creader_set_null(data);
                }
            } else {
                var chunked = false;
                if (Curl_checkheaders(data, "Transfer-Encoding", "Transfer-Encoding".len)) |ptr| {
                    chunked = Curl_compareheader(
                        ptr,
                        "Transfer-Encoding:",
                        "Transfer-Encoding:".len,
                        "chunked",
                        "chunked".len,
                    );
                }
                result = sendf.Curl_creader_set_fread(data, if (chunked) -1 else postsize);
            }
            return result;
        },
        else => {
            Curl_http_acc_state_set_infilesize(data, 0);
            return sendf.Curl_creader_set_null(data);
        },
    }
}

fn http_resume(data: *Curl_easy, httpreq_val: Curl_HttpReq) CURLcode {
    if ((httpreq_val == HTTPREQ_POST or httpreq_val == HTTPREQ_POST_FORM or
        httpreq_val == HTTPREQ_POST_MIME or httpreq_val == HTTPREQ_PUT) and
        Curl_http_acc_state_resume_from(data) != 0)
    {
        Curl_failf(data, "HTTP upload cannot be resumed");
        return CURLE_BAD_FUNCTION_ARGUMENT;
    }
    return CURLE_OK;
}

fn http_req_set_TE(data: *Curl_easy, req: *dynbuf, httpversion: c_int) CURLcode {
    var result: CURLcode = CURLE_OK;
    if (Curl_checkheaders(data, "Transfer-Encoding", "Transfer-Encoding".len)) |ptr| {
        const chunky = Curl_compareheader(
            ptr,
            "Transfer-Encoding:",
            "Transfer-Encoding:".len,
            "chunked",
            "chunked".len,
        );
        Curl_http_acc_req_set_upload_chunky(data, chunky);
        if (chunky and httpversion >= 20) {
            Curl_infof(data, "suppressing chunked transfer encoding on connection using HTTP version 2 or higher");
            Curl_http_acc_req_set_upload_chunky(data, false);
        }
    } else {
        const req_clen = sendf.Curl_creader_total_length(data);
        if (req_clen < 0) {
            if (httpversion > 10) {
                Curl_http_acc_req_set_upload_chunky(data, httpversion < 20);
            } else {
                Curl_failf(data, "Chunky upload is not supported by HTTP 1.0");
                return CURLE_UPLOAD_FAILED;
            }
        } else {
            Curl_http_acc_req_set_upload_chunky(data, false);
        }

        if (Curl_http_acc_req_upload_chunky(data))
            result = containers.curlx_dyn_add(req, "Transfer-Encoding: chunked\r\n");
    }
    return result;
}

fn addexpect(
    data: *Curl_easy,
    r: *dynbuf,
    httpversion: c_int,
    announced_exp100: *bool,
) CURLcode {
    announced_exp100.* = false;
    if (Curl_http_acc_req_upgr101(data) != UPGR101_NONE)
        return CURLE_OK;

    if (Curl_checkheaders(data, "Expect", "Expect".len)) |ptr| {
        announced_exp100.* = Curl_compareheader(
            ptr,
            "Expect:",
            "Expect:".len,
            "100-continue",
            "100-continue".len,
        );
    } else if (!Curl_http_acc_state_disableexpect(data) and httpversion == 11) {
        const client_len = sendf.Curl_creader_client_length(data);
        if (client_len > EXPECT_100_THRESHOLD or client_len < 0) {
            const result = containers.curlx_dyn_addn(r, "Expect: 100-continue\r\n", "Expect: 100-continue\r\n".len);
            if (result != CURLE_OK)
                return result;
            announced_exp100.* = true;
        }
    }
    return CURLE_OK;
}

fn http_add_content_hds(
    data: *Curl_easy,
    r: *dynbuf,
    httpversion: c_int,
    httpreq_val: Curl_HttpReq,
) CURLcode {
    var result: CURLcode = CURLE_OK;
    var announced_exp100 = false;

    if (Curl_http_acc_req_upload_chunky(data)) {
        result = Curl_httpchunk_add_reader(data);
        if (result != CURLE_OK)
            return result;
    }

    const req_clen = sendf.Curl_creader_total_length(data);
    switch (httpreq_val) {
        HTTPREQ_PUT, HTTPREQ_POST, HTTPREQ_POST_FORM, HTTPREQ_POST_MIME => {
            if ((httpreq_val == HTTPREQ_POST_FORM or httpreq_val == HTTPREQ_POST_MIME) and
                !hasFeat(FEAT_MIME) and !hasFeat(FEAT_FORM_API))
            {
                // disabled
            } else {
                if (req_clen >= 0 and !Curl_http_acc_req_upload_chunky(data) and
                    (Curl_http_acc_req_authneg(data) or
                        Curl_checkheaders(data, "Content-Length", "Content-Length".len) == null))
                {
                    result = containers.curlx_dyn_addf(r, "Content-Length: %lld\r\n", @as(c_longlong, req_clen));
                }
                if (result != CURLE_OK)
                    return result;

                if (hasFeat(FEAT_MIME) and
                    (httpreq_val == HTTPREQ_POST_FORM or httpreq_val == HTTPREQ_POST_MIME))
                {
                    var hdr = Curl_http_acc_mimepost_curlheaders(data);
                    while (hdr) |node| : (hdr = node.next) {
                        if (node.data) |d| {
                            result = containers.curlx_dyn_addf(r, "%s\r\n", d);
                            if (result != CURLE_OK)
                                return result;
                        }
                    }
                }

                if (httpreq_val == HTTPREQ_POST and
                    Curl_checkheaders(data, "Content-Type", "Content-Type".len) == null)
                {
                    result = containers.curlx_dyn_addn(
                        r,
                        "Content-Type: application/x-www-form-urlencoded\r\n",
                        "Content-Type: application/x-www-form-urlencoded\r\n".len,
                    );
                    if (result != CURLE_OK)
                        return result;
                }

                result = addexpect(data, r, httpversion, &announced_exp100);
                if (result != CURLE_OK)
                    return result;
            }
        },
        else => {},
    }

    Curl_pgrsSetUploadSize(data, req_clen);
    if (announced_exp100)
        result = http_exp100_add_reader(data);
    return result;
}

fn http_cookies(data: *Curl_easy, r: *dynbuf) CURLcode {
    if (!hasFeat(FEAT_COOKIES))
        return CURLE_OK;
    return Curl_http_acc_http_cookies(data, r);
}

fn http_range(data: *Curl_easy, httpreq_val: Curl_HttpReq) CURLcode {
    if (Curl_http_acc_state_use_range(data)) {
        const range: [*:0]const u8 = Curl_http_acc_state_range(data) orelse "";
        if ((httpreq_val == HTTPREQ_GET or httpreq_val == HTTPREQ_HEAD) and
            Curl_checkheaders(data, "Range", "Range".len) == null)
        {
            mem.free(Curl_http_acc_state_rangeline(data));
            const rl = curl_maprintf("Range: bytes=%s\r\n", range) orelse return CURLE_OUT_OF_MEMORY;
            Curl_http_acc_state_set_rangeline(data, rl);
        } else if ((httpreq_val == HTTPREQ_POST or httpreq_val == HTTPREQ_PUT) and
            Curl_checkheaders(data, "Content-Range", "Content-Range".len) == null)
        {
            const req_clen = sendf.Curl_creader_total_length(data);
            mem.free(Curl_http_acc_state_rangeline(data));
            var rl: ?[*:0]u8 = null;
            if (Curl_http_acc_set_set_resume_from(data) < 0) {
                rl = curl_maprintf(
                    "Content-Range: bytes 0-%lld/%lld\r\n",
                    @as(c_longlong, req_clen - 1),
                    @as(c_longlong, req_clen),
                );
            } else if (Curl_http_acc_state_resume_from(data) != 0) {
                const total_len: curl_off_t = if (Curl_http_acc_req_authneg(data))
                    Curl_http_acc_state_infilesize(data)
                else
                    (Curl_http_acc_state_resume_from(data) + req_clen);
                rl = curl_maprintf(
                    "Content-Range: bytes %s%lld/%lld\r\n",
                    range,
                    @as(c_longlong, total_len - 1),
                    @as(c_longlong, total_len),
                );
            } else {
                rl = curl_maprintf(
                    "Content-Range: bytes %s/%lld\r\n",
                    range,
                    @as(c_longlong, req_clen),
                );
            }
            Curl_http_acc_state_set_rangeline(data, rl);
            if (rl == null)
                return CURLE_OUT_OF_MEMORY;
        }
    }
    return CURLE_OK;
}

fn http_firstwrite(data: *Curl_easy) CURLcode {
    const conn = Curl_http_acc_conn(data) orelse return CURLE_BAD_FUNCTION_ARGUMENT;

    if (Curl_http_acc_req_newurl(data) != null) {
        if (Curl_http_acc_conn_bits_close(conn)) {
            Curl_http_acc_req_clear_recv(data);
            Curl_http_acc_req_set_done(data, true);
            return CURLE_OK;
        }
        Curl_http_acc_req_set_ignorebody(data, true);
        Curl_infof(data, "Ignoring the response-body");
    }

    if (Curl_http_acc_state_resume_from(data) != 0 and
        !Curl_http_acc_req_content_range(data) and
        Curl_http_acc_state_httpreq(data) == HTTPREQ_GET and
        !Curl_http_acc_req_ignorebody(data))
    {
        if (Curl_http_acc_req_size(data) == Curl_http_acc_state_resume_from(data)) {
            Curl_infof(data, "The entire document is already downloaded");
            streamclose(conn);
            Curl_http_acc_req_clear_recv(data);
            Curl_http_acc_req_set_done(data, true);
            return CURLE_OK;
        }
        Curl_failf(data, "HTTP server does not seem to support byte ranges. Cannot resume.");
        return CURLE_RANGE_ERROR;
    }

    if (Curl_http_acc_set_timecondition(data) != 0 and
        Curl_http_acc_state_range(data) == null and
        !Curl_meets_timecondition(data, Curl_http_acc_req_timeofdoc_ptr(data).*))
    {
        Curl_http_acc_req_set_done(data, true);
        Curl_http_acc_info_set_httpcode(data, 304);
        Curl_infof(data, "Simulate an HTTP 304 response");
        streamclose(conn);
        return CURLE_OK;
    }

    return CURLE_OK;
}

fn http_check_new_conn(data: *Curl_easy) CURLcode {
    const conn = Curl_http_acc_conn(data) orelse return CURLE_BAD_FUNCTION_ARGUMENT;
    var info_version: ?[*:0]const u8 = null;
    const alpn = Curl_conn_get_alpn_negotiated(data, conn);

    if (alpn != null and std.mem.eql(u8, std.mem.span(alpn.?), "h3")) {
        info_version = "HTTP/3";
    } else if (alpn != null and std.mem.eql(u8, std.mem.span(alpn.?), "h2")) {
        if (hasFeat(FEAT_PROXY) and
            Curl_conn_http_version(data, conn) != 20 and
            Curl_http_acc_conn_bits_origin_is_proxy(conn))
        {
            const result = Curl_http_acc_http2_switch(data);
            if (result != CURLE_OK)
                return result;
        }
        info_version = "HTTP/2";
    } else {
        if (Curl_http_acc_http2_may_switch(data)) {
            const result = Curl_http_acc_http2_switch(data);
            if (result != CURLE_OK)
                return result;
            info_version = "HTTP/2";
            Curl_http_acc_conn_set_httpversion_seen(conn, 20);
            Curl_conn_set_multiplex(conn);
        } else {
            info_version = "HTTP/1.x";
        }
    }

    if (info_version) |iv|
        Curl_infof(data, "using %s", iv);
    return CURLE_OK;
}

fn http_add_connection_hd(data: *Curl_easy, req: *dynbuf) CURLcode {
    var head = Curl_http_acc_set_headers(data);
    var sep: [*:0]const u8 = "Connection: ";
    var result: CURLcode = CURLE_OK;
    const rlen = containers.curlx_dyn_len(req);

    while (head) |node| : (head = node.next) {
        if (node.data) |d| {
            if (curl_strnequal(d, "Connection", 10) != 0 and
                Curl_headersep(d[10]) and
                !http_header_is_empty(d))
            {
                var value: ?[*:0]u8 = null;
                result = copy_custom_value(d, &value);
                if (result != CURLE_OK)
                    return result;
                result = containers.curlx_dyn_addf(req, "%s%s", sep, value.?);
                sep = ", ";
                mem.free(value);
                break;
            }
        }
    }

    var hd_te = false;
    var hd_upgrade = false;
    var hd_h2_settings = false;
    Curl_http_acc_state_http_hd_flags(data, &hd_te, &hd_upgrade, &hd_h2_settings);

    if (result == CURLE_OK and hd_te) {
        result = containers.curlx_dyn_addf(req, "%s%s", sep, @as([*:0]const u8, "TE"));
        sep = ", ";
    }
    if (result == CURLE_OK and hd_upgrade) {
        result = containers.curlx_dyn_addf(req, "%s%s", sep, @as([*:0]const u8, "Upgrade"));
        sep = ", ";
    }
    if (result == CURLE_OK and hd_h2_settings) {
        result = containers.curlx_dyn_addf(req, "%s%s", sep, @as([*:0]const u8, "HTTP2-Settings"));
    }
    if (result == CURLE_OK and rlen < containers.curlx_dyn_len(req))
        result = containers.curlx_dyn_addn(req, "\r\n", 2);
    if (result != CURLE_OK)
        return result;

    var skip = true;
    head = Curl_http_acc_set_headers(data);
    while (head) |node| : (head = node.next) {
        if (node.data) |d| {
            if (curl_strnequal(d, "Connection", 10) != 0 and
                Curl_headersep(d[10]) and
                !http_header_is_empty(d))
            {
                if (skip) {
                    skip = false;
                    continue;
                }
                result = containers.curlx_dyn_addf(req, "%s\r\n", d);
                if (result != CURLE_OK)
                    return result;
            }
        }
    }
    return CURLE_OK;
}

const http_hd_t = enum(c_uint) {
    H1_HD_REQUEST = 0,
    H1_HD_HOST,
    H1_HD_PROXY_AUTH,
    H1_HD_AUTH,
    H1_HD_RANGE,
    H1_HD_USER_AGENT,
    H1_HD_ACCEPT,
    H1_HD_TE,
    H1_HD_ACCEPT_ENCODING,
    H1_HD_REFERER,
    H1_HD_PROXY_CONNECTION,
    H1_HD_TRANSFER_ENCODING,
    H1_HD_ALT_USED,
    H1_HD_UPGRADE,
    H1_HD_COOKIES,
    H1_HD_CONDITIONALS,
    H1_HD_CUSTOM,
    H1_HD_CONTENT,
    H1_HD_CONNECTION,
    H1_HD_LAST,
};

fn http_add_hd(
    data: *Curl_easy,
    req: *dynbuf,
    id: http_hd_t,
    httpversion: u8,
    method: [*:0]const u8,
    httpreq_val: Curl_HttpReq,
) CURLcode {
    var result: CURLcode = CURLE_OK;
    const conn = Curl_http_acc_conn(data) orelse return CURLE_BAD_FUNCTION_ARGUMENT;

    switch (id) {
        .H1_HD_REQUEST => {
            result = containers.curlx_dyn_addf(req, "%s ", method);
            if (result == CURLE_OK)
                result = http_target(data, req);
            if (result == CURLE_OK)
                result = containers.curlx_dyn_addf(req, " HTTP/%s\r\n", get_http_string(httpversion));
        },
        .H1_HD_HOST => {
            if (Curl_http_acc_state_http_host(data)) |hh| {
                result = containers.curlx_dyn_add(req, hh);
                if (result == CURLE_OK)
                    result = containers.curlx_dyn_addn(req, "\r\n", 2);
            }
        },
        .H1_HD_PROXY_AUTH => {
            if (hasFeat(FEAT_PROXY)) {
                if (Curl_http_acc_req_hd_auth(data, true)) |pa|
                    result = containers.curlx_dyn_add(req, pa);
            }
        },
        .H1_HD_AUTH => {
            if (Curl_http_acc_req_hd_auth(data, false)) |ha|
                result = containers.curlx_dyn_add(req, ha);
        },
        .H1_HD_RANGE => {
            if (Curl_http_acc_state_use_range(data)) {
                if (Curl_http_acc_state_rangeline(data)) |rl|
                    result = containers.curlx_dyn_add(req, rl);
            }
        },
        .H1_HD_USER_AGENT => {
            if (Curl_http_acc_str_useragent(data)) |ua| {
                if (ua[0] != 0 and Curl_checkheaders(data, "User-Agent", "User-Agent".len) == null)
                    result = containers.curlx_dyn_addf(req, "User-Agent: %s\r\n", ua);
            }
        },
        .H1_HD_ACCEPT => {
            if (Curl_checkheaders(data, "Accept", "Accept".len) == null)
                result = containers.curlx_dyn_add(req, "Accept: */*\r\n");
        },
        .H1_HD_TE => {
            if (hasFeat(FEAT_LIBZ)) {
                if (Curl_checkheaders(data, "TE", "TE".len) == null and
                    Curl_http_acc_set_http_transfer_encoding(data))
                {
                    var te = false;
                    var upg = false;
                    var h2s = false;
                    Curl_http_acc_state_http_hd_flags(data, &te, &upg, &h2s);
                    Curl_http_acc_state_set_http_hd_flags(data, true, upg, h2s);
                    result = containers.curlx_dyn_add(req, "TE: gzip\r\n");
                }
            }
        },
        .H1_HD_ACCEPT_ENCODING => {
            if (Curl_http_acc_str_encoding(data)) |enc| {
                if (Curl_checkheaders(data, "Accept-Encoding", "Accept-Encoding".len) == null)
                    result = containers.curlx_dyn_addf(req, "Accept-Encoding: %s\r\n", enc);
            }
        },
        .H1_HD_REFERER => {
            if (Curl_bufref_ptr(Curl_http_acc_state_referer_bufref(data))) |ref_ptr| {
                if (Curl_checkheaders(data, "Referer", "Referer".len) == null)
                    result = containers.curlx_dyn_addf(req, "Referer: %s\r\n", ref_ptr);
            }
        },
        .H1_HD_PROXY_CONNECTION => {
            if (hasFeat(FEAT_PROXY)) {
                if (Curl_http_acc_conn_bits_origin_is_proxy(conn) and
                    Curl_checkheaders(data, "Proxy-Connection", "Proxy-Connection".len) == null and
                    Curl_checkProxyheaders(data, conn, "Proxy-Connection", "Proxy-Connection".len) == null)
                {
                    result = containers.curlx_dyn_add(req, "Proxy-Connection: Keep-Alive\r\n");
                }
            }
        },
        .H1_HD_TRANSFER_ENCODING => {
            result = http_req_set_TE(data, req, httpversion);
        },
        .H1_HD_ALT_USED => {
            if (hasFeat(FEAT_ALTSVC)) {
                if (Curl_http_acc_conn_bits_altused(conn)) {
                    if (Curl_http_acc_conn_via_peer_hostname(conn)) |vh| {
                        if (Curl_checkheaders(data, "Alt-Used", "Alt-Used".len) == null) {
                            result = containers.curlx_dyn_addf(
                                req,
                                "Alt-Used: %s:%u\r\n",
                                vh,
                                @as(c_uint, @intCast(Curl_http_acc_conn_via_peer_port(conn))),
                            );
                        }
                    }
                }
            }
        },
        .H1_HD_UPGRADE => {
            const neg = Curl_http_acc_state_http_neg(data);
            if (!Curl_conn_is_ssl(conn, FIRSTSOCKET) and httpversion < 20 and
                (Curl_http_acc_neg_wanted(neg) & CURL_HTTP_V2x) != 0 and
                Curl_http_acc_neg_h2_upgrade(neg))
            {
                result = Curl_http_acc_http2_request_upgrade(req, data);
            }
            if (hasFeat(FEAT_WEBSOCKETS) and result == CURLE_OK and
                (Curl_http_acc_conn_scheme_protocol(conn) & (CURLPROTO_WS | CURLPROTO_WSS)) != 0)
            {
                result = Curl_http_acc_ws_request(data, req);
            }
        },
        .H1_HD_COOKIES => {
            result = http_cookies(data, req);
        },
        .H1_HD_CONDITIONALS => {
            result = Curl_add_timecondition(data, req);
        },
        .H1_HD_CUSTOM => {
            result = Curl_add_custom_headers(data, false, httpversion, req);
        },
        .H1_HD_CONTENT => {
            result = http_add_content_hds(data, req, httpversion, httpreq_val);
        },
        .H1_HD_CONNECTION => {
            result = http_add_connection_hd(data, req);
        },
        .H1_HD_LAST => {
            result = containers.curlx_dyn_addn(req, "\r\n", 2);
        },
    }
    return result;
}

pub export fn Curl_http(data: *Curl_easy, done: *bool) callconv(.c) CURLcode {
    const conn = Curl_http_acc_conn(data) orelse return CURLE_BAD_FUNCTION_ARGUMENT;
    var result: CURLcode = CURLE_OK;
    var httpreq_val: Curl_HttpReq = HTTPREQ_GET;
    var method: ?[*:0]const u8 = null;
    var req: dynbuf = undefined;

    done.* = true;
    containers.curlx_dyn_init(&req, DYN_HTTP_REQUEST);
    defer containers.curlx_dyn_free(&req);

    containers.curlx_dyn_reset(Curl_http_acc_state_headerb(data));
    Curl_http_acc_state_set_maybe_folded(data, false);

    if (!Curl_http_acc_conn_bits_reuse(conn)) {
        result = http_check_new_conn(data);
        if (result != CURLE_OK)
            return result;
    }

    result = Curl_http_acc_headers_init(data);
    if (result != CURLE_OK)
        return result;

    Curl_http_acc_state_set_http_hd_flags(data, false, false, false);

    Curl_http_method(data, &method, &httpreq_val);

    result = http_set_aptr_host(data);
    if (result == CURLE_OK) {
        result = Curl_http_output_auth(
            data,
            conn,
            method orelse "GET",
            httpreq_val,
            Curl_http_acc_state_up_path(data) orelse "/",
            Curl_http_acc_state_up_query(data),
            false,
        );
    }
    if (result == CURLE_OK)
        result = set_reader(data, httpreq_val);
    if (result == CURLE_OK)
        result = http_resume(data, httpreq_val);
    if (result == CURLE_OK)
        result = http_range(data, httpreq_val);
    if (result != CURLE_OK) {
        if (result == CURLE_TOO_LARGE)
            Curl_failf(data, "HTTP request too large");
        return result;
    }

    const httpversion = http_request_version(data);
    var hd_id: c_uint = 0;
    while (hd_id <= @backingInt(http_hd_t.H1_HD_LAST)) : (hd_id += 1) {
        result = http_add_hd(
            data,
            &req,
            @fromBackingInt(@intCast(hd_id)),
            httpversion,
            method orelse "GET",
            httpreq_val,
        );
        if (result != CURLE_OK) {
            if (result == CURLE_TOO_LARGE)
                Curl_failf(data, "HTTP request too large");
            return result;
        }
    }

    Curl_xfer_setup_sendrecv(data, FIRSTSOCKET, -1);
    result = Curl_req_send(data, &req, httpversion);

    if (httpversion >= 20 and Curl_http_acc_req_upload_chunky(data))
        Curl_http_acc_req_set_upload_chunky(data, false);

    if (result == CURLE_TOO_LARGE)
        Curl_failf(data, "HTTP request too large");
    return result;
}

// ============================================================================
// 7. Response Status Line, Header Parsing & Response Writing
// ============================================================================

const statusline = enum(c_uint) {
    STATUS_UNKNOWN = 0,
    STATUS_DONE = 1,
    STATUS_BAD = 2,
};

fn checkprefixmax(prefix: [*:0]const u8, buffer: [*]const u8, len: usize) bool {
    const ch = @min(std.mem.len(prefix), len);
    return curl_strnequal(prefix, buffer, ch) != 0;
}

fn checkhttpprefix(data: *Curl_easy, s: [*]const u8, len: usize) statusline {
    var head = Curl_http_acc_set_http200aliases(data);
    var rc: statusline = .STATUS_BAD;
    const onmatch: statusline = if (len >= 5) .STATUS_DONE else .STATUS_UNKNOWN;

    while (head) |node| : (head = node.next) {
        if (node.data) |alias| {
            if (checkprefixmax(alias, s, len)) {
                rc = onmatch;
                break;
            }
        }
    }

    if (rc != .STATUS_DONE and checkprefixmax("HTTP/", s, len))
        rc = onmatch;

    return rc;
}

fn checkrtspprefix(data: *Curl_easy, s: [*]const u8, len: usize) statusline {
    _ = data;
    var status: statusline = .STATUS_BAD;
    const onmatch: statusline = if (len >= 5) .STATUS_DONE else .STATUS_UNKNOWN;
    if (checkprefixmax("RTSP/", s, len))
        status = onmatch;
    return status;
}

fn checkprotoprefix(
    data: *Curl_easy,
    conn: *connectdata,
    s: [*]const u8,
    len: usize,
) statusline {
    if (hasFeat(FEAT_RTSP) and (Curl_http_acc_conn_scheme_protocol(conn) & CURLPROTO_RTSP) != 0)
        return checkrtspprefix(data, s, len);
    return checkhttpprefix(data, s, len);
}

inline fn hdIs(hd: [*]const u8, hdlen: usize, comptime name: []const u8) bool {
    return hdlen >= name.len and curl_strnequal(name.ptr, hd, name.len) != 0;
}

inline fn hdVal(hd: [*:0]const u8, hdlen: usize, comptime name: []const u8) ?[*:0]const u8 {
    if (hdlen >= name.len and curl_strnequal(name.ptr, hd, name.len) != 0) {
        return hd + name.len;
    }
    return null;
}

inline fn hdIsAndSays(
    hd: [*:0]const u8,
    hdlen: usize,
    comptime name: [:0]const u8,
    comptime val: [:0]const u8,
) bool {
    return hdIs(hd, hdlen, name) and
        hdlen > (name.len + val.len) and
        Curl_compareheader(hd, name.ptr, name.len, val.ptr, val.len);
}

fn http_header_a(data: *Curl_easy, hd: [*]const u8, hdlen: usize) CURLcode {
    if (!hasFeat(FEAT_ALTSVC))
        return CURLE_OK;
    return Curl_http_acc_altsvc_header(data, hd, hdlen);
}

fn http_header_c(data: *Curl_easy, hd: [*:0]const u8, hdlen: usize) CURLcode {
    const conn = Curl_http_acc_conn(data) orelse return CURLE_BAD_FUNCTION_ARGUMENT;
    const bodyless = Curl_http_acc_req_http_bodyless(data);

    if (!bodyless and !Curl_http_acc_set_ignorecl(data) and !Curl_http_acc_req_ignore_cl(data)) {
        if (hdVal(hd, hdlen, "Content-Length:")) |v_init| {
            var v: ?[*:0]const u8 = v_init;
            while (true) {
                var contentlength: i64 = 0;
                const offt = curlx_str_numblanks(&v, &contentlength);
                if (offt == curlx_parse.STRE_OVERFLOW) {
                    if (Curl_http_acc_set_max_filesize(data) != 0) {
                        Curl_failf(data, "Maximum file size exceeded");
                        return CURLE_FILESIZE_EXCEEDED;
                    }
                    streamclose(conn);
                    Curl_infof(data, "Overflow Content-Length: value");
                    return CURLE_OK;
                } else {
                    const cur_size = Curl_http_acc_req_size(data);
                    if (offt == curlx_parse.STRE_OK and (cur_size == -1 or cur_size == contentlength)) {
                        Curl_http_acc_req_set_size(data, contentlength);
                        curlx_str_passblanks(&v);
                        if (curlx_str_single(&v, ',') == 0)
                            continue;
                        if (curlx_str_newline(&v) == 0) {
                            Curl_http_acc_req_set_maxdownload(data, contentlength);
                            return CURLE_OK;
                        }
                    }
                    Curl_failf(data, "Invalid Content-Length: value");
                    return CURLE_WEIRD_SERVER_REPLY;
                }
            }
        }
    }

    if (!bodyless and Curl_http_acc_str_encoding(data) != null) {
        if (hdVal(hd, hdlen, "Content-Encoding:")) |v| {
            return Curl_build_unencoding_stack(data, v, false);
        }
    }

    if (hdVal(hd, hdlen, "Content-Type:") != null) {
        const contenttype = Curl_copy_header_value(hd) orelse return CURLE_OUT_OF_MEMORY;
        if (contenttype[0] == 0) {
            mem.free(contenttype);
        } else {
            Curl_http_acc_info_set_contenttype(data, contenttype);
        }
        return CURLE_OK;
    }

    const req_hv = Curl_http_acc_req_httpversion(data);
    if (req_hv < 20 and hdIsAndSays(hd, hdlen, "Connection:", "close")) {
        connclose(conn);
        return CURLE_OK;
    }
    if (req_hv == 10 and hdIsAndSays(hd, hdlen, "Connection:", "keep-alive")) {
        connkeep(conn);
        Curl_infof(data, "HTTP/1.0 connection set to keep alive");
        return CURLE_OK;
    }

    if (!bodyless) {
        if (hdVal(hd, hdlen, "Content-Range:")) |v| {
            var ptr: [*:0]const u8 = v;
            while (ptr[0] != 0 and !isDigit(ptr[0]) and ptr[0] != '*') {
                ptr += 1;
            }
            if (isDigit(ptr[0])) {
                var p: ?[*:0]const u8 = ptr;
                const off_ptr = Curl_http_acc_req_offset_ptr(data);
                if (curlx_str_number(&p, off_ptr, CURL_OFF_T_MAX) == 0 and
                    Curl_http_acc_state_resume_from(data) == off_ptr.*)
                {
                    Curl_http_acc_req_set_content_range(data, true);
                }
            } else if (Curl_http_acc_req_httpcode(data) < 300) {
                Curl_http_acc_state_set_resume_from(data, 0);
            }
        }
    }
    return CURLE_OK;
}

fn http_header_l(data: *Curl_easy, hd: [*:0]const u8, hdlen: usize) CURLcode {
    const conn = Curl_http_acc_conn(data) orelse return CURLE_BAD_FUNCTION_ARGUMENT;
    const bodyless = Curl_http_acc_req_http_bodyless(data);

    if (!bodyless and
        (Curl_http_acc_set_timecondition(data) != 0 or Curl_http_acc_set_get_filetime(data)))
    {
        if (hdVal(hd, hdlen, "Last-Modified:")) |v| {
            const tod_ptr = Curl_http_acc_req_timeofdoc_ptr(data);
            if (Curl_getdate_capped(v, tod_ptr) != 0)
                tod_ptr.* = 0;
            if (Curl_http_acc_set_get_filetime(data))
                Curl_http_acc_info_set_filetime(data, tod_ptr.*);
            return CURLE_OK;
        }
    }

    if (hdIs(hd, hdlen, "Location:")) {
        const location = Curl_copy_header_value(hd) orelse return CURLE_OUT_OF_MEMORY;
        const prev_loc = Curl_http_acc_req_location(data);
        if (location[0] == 0 or
            (prev_loc != null and std.mem.eql(u8, std.mem.span(prev_loc.?), std.mem.span(location))))
        {
            mem.free(location);
            return CURLE_OK;
        } else {
            if (prev_loc != null) {
                Curl_failf(data, "Multiple Location headers");
                mem.free(location);
                return CURLE_WEIRD_SERVER_REPLY;
            }
            Curl_http_acc_req_set_location(data, location);

            const httpcode = Curl_http_acc_req_httpcode(data);
            if (httpcode >= 300 and httpcode < 400 and Curl_http_acc_set_http_follow_mode(data) != 0) {
                const dup = mem.strdup(location) orelse return CURLE_OUT_OF_MEMORY;
                Curl_http_acc_req_set_newurl(data, dup);

                const result = http_perhapsrewind(data, conn);
                if (result != CURLE_OK)
                    return result;

                Curl_http_acc_state_set_this_is_a_follow(data, true);
            }
        }
    }
    return CURLE_OK;
}

fn http_header_p(data: *Curl_easy, hd: [*:0]const u8, hdlen: usize) CURLcode {
    const conn = Curl_http_acc_conn(data) orelse return CURLE_BAD_FUNCTION_ARGUMENT;
    const req_hv = Curl_http_acc_req_httpversion(data);
    const httpcode = Curl_http_acc_req_httpcode(data);

    if (hasFeat(FEAT_PROXY)) {
        if (hdVal(hd, hdlen, "Proxy-Connection:") != null) {
            if (req_hv == 10 and Curl_http_acc_conn_http_proxy_peer(conn) != null and
                hdIsAndSays(hd, hdlen, "Proxy-Connection:", "keep-alive"))
            {
                connkeep(conn);
                Curl_infof(data, "HTTP/1.0 proxy connection set to keep alive");
            } else if (req_hv == 11 and Curl_http_acc_conn_http_proxy_peer(conn) != null and
                hdIsAndSays(hd, hdlen, "Proxy-Connection:", "close"))
            {
                connclose(conn);
                Curl_infof(data, "HTTP/1.1 proxy connection set close");
            }
            return CURLE_OK;
        }
    }

    if (httpcode == 407 and hdIs(hd, hdlen, "Proxy-authenticate:")) {
        if (hasFeat(FEAT_PROXY) and !Curl_http_acc_conn_bits_origin_is_proxy(conn))
            return CURLE_OK;
        const auth_val = Curl_copy_header_value(hd) orelse return CURLE_OUT_OF_MEMORY;
        defer mem.free(auth_val);
        return Curl_http_input_auth(data, true, auth_val);
    }

    if (hasFeat(FEAT_SPNEGO)) {
        const res = Curl_http_acc_persistent_auth(data, hd, hdlen);
        if (res != CURLE_OK)
            return res;
    }
    return CURLE_OK;
}

fn http_header_r(data: *Curl_easy, hd: [*:0]const u8, hdlen: usize) CURLcode {
    if (hdVal(hd, hdlen, "Retry-After:")) |v_init| {
        var v: ?[*:0]const u8 = v_init;
        var retry_after: curl_off_t = 0;
        var date: time_t = 0;
        curlx_str_passblanks(&v);

        if (v) |v_str| {
            if (Curl_getdate_capped(v_str, &date) == 0) {
                const current = Curl_http_acc_current_time();
                if (date >= current)
                    retry_after = date - current;
            } else {
                _ = curlx_str_number(&v, &retry_after, CURL_OFF_T_MAX);
            }
        }
        if (retry_after > 21600)
            retry_after = 21600;
        Curl_http_acc_info_set_retry_after(data, retry_after);
    }
    return CURLE_OK;
}

fn http_header_s(data: *Curl_easy, hd: [*:0]const u8, hdlen: usize) CURLcode {
    if (hasFeat(FEAT_COOKIES)) {
        if (Curl_http_acc_has_cookie_engine(data)) {
            if (hdVal(hd, hdlen, "Set-Cookie:")) |v| {
                return Curl_http_acc_cookie_add(data, v);
            }
        }
    }
    if (hasFeat(FEAT_HSTS)) {
        const res = Curl_http_acc_hsts_header(data, hd, hdlen);
        if (res != CURLE_OK)
            return res;
    }
    return CURLE_OK;
}

fn http_header_t(data: *Curl_easy, hd: [*:0]const u8, hdlen: usize) CURLcode {
    const conn = Curl_http_acc_conn(data) orelse return CURLE_BAD_FUNCTION_ARGUMENT;
    if (!Curl_http_acc_req_http_bodyless(data) and
        Curl_http_acc_state_httpreq(data) != HTTPREQ_HEAD and
        Curl_http_acc_req_httpcode(data) != 304)
    {
        if (hdVal(hd, hdlen, "Transfer-Encoding:")) |v| {
            const result = Curl_build_unencoding_stack(data, v, true);
            if (result != CURLE_OK)
                return result;
            if (!Curl_http_acc_req_chunk(data)) {
                connclose(conn);
                Curl_http_acc_req_set_ignore_cl(data, true);
            }
            return CURLE_OK;
        }
    }
    if (hdVal(hd, hdlen, "Trailer:") != null) {
        Curl_http_acc_req_set_resp_trailer(data, true);
        return CURLE_OK;
    }
    return CURLE_OK;
}

fn http_header_w(data: *Curl_easy, hd: [*:0]const u8, hdlen: usize) CURLcode {
    if (Curl_http_acc_req_httpcode(data) == 401 and hdIs(hd, hdlen, "WWW-Authenticate:")) {
        const auth_val = Curl_copy_header_value(hd) orelse return CURLE_OUT_OF_MEMORY;
        defer mem.free(auth_val);
        return Curl_http_input_auth(data, false, auth_val);
    }
    return CURLE_OK;
}

fn http_header(data: *Curl_easy, hd: [*:0]const u8, hdlen: usize) CURLcode {
    var result: CURLcode = CURLE_OK;
    switch (hd[0]) {
        'a', 'A' => result = http_header_a(data, hd, hdlen),
        'c', 'C' => result = http_header_c(data, hd, hdlen),
        'l', 'L' => result = http_header_l(data, hd, hdlen),
        'p', 'P' => result = http_header_p(data, hd, hdlen),
        'r', 'R' => result = http_header_r(data, hd, hdlen),
        's', 'S' => result = http_header_s(data, hd, hdlen),
        't', 'T' => result = http_header_t(data, hd, hdlen),
        'w', 'W' => result = http_header_w(data, hd, hdlen),
        else => {},
    }

    if (result == CURLE_OK) {
        if (Curl_http_acc_conn(data)) |conn| {
            if ((Curl_http_acc_conn_scheme_protocol(conn) & CURLPROTO_RTSP) != 0)
                result = Curl_http_acc_rtsp_parseheader(data, hd);
        }
    }
    return result;
}

fn http_statusline(data: *Curl_easy, conn: *connectdata) CURLcode {
    const hv = Curl_http_acc_req_httpversion(data);
    const hv_sent = Curl_http_acc_req_httpversion_sent(data);

    const valid_version = switch (hv) {
        10, 11 => true,
        20 => hasFeat(FEAT_HTTP2),
        30 => hasFeat(FEAT_HTTP3),
        else => false,
    };

    if (!valid_version) {
        Curl_failf(
            data,
            "Unsupported HTTP version (%d.%d) in response",
            @as(c_int, hv / 10),
            @as(c_int, hv % 10),
        );
        return CURLE_UNSUPPORTED_PROTOCOL;
    }

    if (hv_sent != 0 and (hv / 10 != hv_sent / 10)) {
        Curl_failf(
            data,
            "Version mismatch (from HTTP/%d to HTTP/%d)",
            @as(c_int, hv_sent / 10),
            @as(c_int, hv / 10),
        );
        return CURLE_WEIRD_SERVER_REPLY;
    }

    const httpcode = Curl_http_acc_req_httpcode(data);
    Curl_http_acc_info_set_httpcode(data, httpcode);
    Curl_http_acc_info_set_httpversion(data, hv);
    Curl_http_acc_conn_set_httpversion_seen(conn, hv);

    const neg = Curl_http_acc_state_http_neg(data);
    if (Curl_http_acc_neg_rcvd_min(neg) == 0 or Curl_http_acc_neg_rcvd_min(neg) > hv)
        Curl_http_acc_neg_set_rcvd_min(neg, hv);

    if (Curl_http_acc_state_resume_from(data) != 0 and
        Curl_http_acc_state_httpreq(data) == HTTPREQ_GET and
        httpcode == 416)
    {
        Curl_http_acc_req_set_ignorebody(data, true);
    }

    if (hv == 10) {
        Curl_infof(data, "HTTP 1.0, assume close after body");
        connclose(conn);
    }

    Curl_http_acc_req_set_http_bodyless(data, httpcode >= 100 and httpcode < 200);
    switch (httpcode) {
        304 => {
            if (Curl_http_acc_set_timecondition(data) != 0)
                Curl_http_acc_info_set_timecond(data, true);
            Curl_http_acc_req_set_size(data, 0);
            Curl_http_acc_req_set_maxdownload(data, 0);
            Curl_http_acc_req_set_http_bodyless(data, true);
        },
        204 => {
            Curl_http_acc_req_set_size(data, 0);
            Curl_http_acc_req_set_maxdownload(data, 0);
            Curl_http_acc_req_set_http_bodyless(data, true);
        },
        else => {},
    }
    return CURLE_OK;
}

fn http_size(data: *Curl_easy) CURLcode {
    if (Curl_http_acc_req_ignore_cl(data) or Curl_http_acc_req_chunk(data)) {
        Curl_http_acc_req_set_size(data, -1);
        Curl_http_acc_req_set_maxdownload(data, -1);
    } else if (Curl_http_acc_req_size(data) != -1) {
        const sz = Curl_http_acc_req_size(data);
        const max_fs = Curl_http_acc_set_max_filesize(data);
        const ignorebody = Curl_http_acc_req_ignorebody(data);
        if (max_fs != 0 and !ignorebody and sz > max_fs) {
            Curl_failf(data, "Maximum file size exceeded");
            return CURLE_FILESIZE_EXCEEDED;
        }
        if (ignorebody)
            Curl_infof(data, "setting size while ignoring");
        Curl_pgrsSetDownloadSize(data, sz);
        Curl_http_acc_req_set_maxdownload(data, sz);
    }
    return CURLE_OK;
}

pub export fn Curl_verify_header(
    data: *Curl_easy,
    hd: [*]const u8,
    hdlen: usize,
) callconv(.c) CURLcode {
    var has_colon = false;
    for (0..hdlen) |i| {
        switch (hd[i]) {
            0 => {
                Curl_failf(data, "NUL byte in header");
                return CURLE_WEIRD_SERVER_REPLY;
            },
            '\r' => {
                if (hdlen >= 2 and i < hdlen - 2) {
                    Curl_failf(data, "Carriage return found in header");
                    return CURLE_WEIRD_SERVER_REPLY;
                }
            },
            ':' => has_colon = true,
            else => {},
        }
    }
    const headerline = Curl_http_acc_req_headerline(data);
    if (headerline < 2)
        return CURLE_OK;
    if ((hd[0] == ' ' or hd[0] == '\t') and headerline > 2) {
        // line folding
    } else if (!has_colon) {
        Curl_failf(data, "Header without colon");
        return CURLE_WEIRD_SERVER_REPLY;
    }
    return CURLE_OK;
}

pub export fn Curl_bump_headersize(
    data: *Curl_easy,
    delta: usize,
    connect_only: bool,
) callconv(.c) CURLcode {
    var bad: usize = 0;
    var max: c_uint = @intCast(MAX_HTTP_RESP_HEADER_SIZE);
    if (delta < MAX_HTTP_RESP_HEADER_SIZE) {
        const hs = Curl_http_acc_info_header_size(data) + @as(curl_off_t, @intCast(delta));
        Curl_http_acc_info_set_header_size(data, hs);
        const all_hc = Curl_http_acc_req_allheadercount(data) + delta;
        Curl_http_acc_req_set_allheadercount(data, all_hc);
        if (!connect_only) {
            const hbc = Curl_http_acc_req_headerbytecount(data) + @as(c_uint, @intCast(delta));
            Curl_http_acc_req_set_headerbytecount(data, hbc);
        }
        if (all_hc > max) {
            bad = all_hc;
        } else if (hs > @as(curl_off_t, max) * 20) {
            bad = @intCast(hs);
            max *= 20;
        }
    } else {
        bad = Curl_http_acc_req_allheadercount(data) + delta;
    }
    if (bad != 0) {
        Curl_failf(data, "Too large response headers: %zu > %u", bad, max);
        return CURLE_RECV_ERROR;
    }
    return CURLE_OK;
}

fn http_on_101_upgrade(
    data: *Curl_easy,
    buf: [*]const u8,
    blen: usize,
    pconsumed: *usize,
    conn_changed: *bool,
) CURLcode {
    const conn = Curl_http_acc_conn(data) orelse return CURLE_BAD_FUNCTION_ARGUMENT;
    const upgr101_requested = Curl_http_acc_req_upgr101(data);

    if (Curl_http_acc_req_httpversion_sent(data) != 11) {
        Curl_failf(data, "server sent 101 response while not talking HTTP/1.1");
        return CURLE_WEIRD_SERVER_REPLY;
    }

    Curl_http_acc_req_set_upgr101(data, UPGR101_RECEIVED);
    Curl_http_acc_conn_set_bits_upgrade_in_progress(conn, false);
    conn_changed.* = true;

    if (hasFeat(FEAT_NGHTTP2) and upgr101_requested == UPGR101_H2) {
        Curl_infof(data, "Received 101, Switching to HTTP/2");
        const result = Curl_http_acc_http2_upgrade(data, conn, buf, blen);
        if (result == CURLE_OK)
            pconsumed.* += blen;
        return result;
    }
    if (hasFeat(FEAT_WEBSOCKETS) and upgr101_requested == UPGR101_WS) {
        Curl_infof(data, "Received 101, Switching to WebSocket");
        const result = Curl_http_acc_ws_accept(data, buf, blen);
        if (result == CURLE_OK)
            pconsumed.* += blen;
        return result;
    }

    Curl_http_acc_req_set_header(data, false);
    return CURLE_OK;
}

fn http_on_1xx_response(
    data: *Curl_easy,
    buf: [*]const u8,
    blen: usize,
    pconsumed: *usize,
    conn_changed: *bool,
) CURLcode {
    Curl_http_acc_req_set_header(data, true);
    Curl_http_acc_req_set_headerline(data, 0);

    switch (Curl_http_acc_req_httpcode(data)) {
        100 => {
            http_exp100_got100(data);
        },
        101 => {
            return http_on_101_upgrade(data, buf, blen, pconsumed, conn_changed);
        },
        else => {},
    }
    return CURLE_OK;
}

fn http_check_auth_closure(data: *Curl_easy, conn: *connectdata) void {
    if (hasFeat(FEAT_NTLM) or hasFeat(FEAT_SPNEGO)) {
        Curl_http_acc_check_auth_closure(data, conn);
    }
}

fn http_handle_send_error(data: *Curl_easy) CURLcode {
    const conn = Curl_http_acc_conn(data) orelse return CURLE_BAD_FUNCTION_ARGUMENT;
    var result: CURLcode = CURLE_OK;

    if (!Curl_http_acc_req_authneg(data) and
        !Curl_http_acc_conn_bits_close(conn) and
        !sendf.Curl_creader_will_rewind(data))
    {
        switch (Curl_http_acc_state_httpreq(data)) {
            HTTPREQ_PUT, HTTPREQ_POST, HTTPREQ_POST_FORM, HTTPREQ_POST_MIME => {
                if (!Curl_req_done_sending(data)) {
                    if (Curl_http_acc_req_httpcode(data) == 417 and http_exp100_is_selected(data)) {
                        if (Curl_http_acc_req_writebytecount(data) == 0 and http_exp100_is_waiting(data)) {
                            Curl_infof(data, "Got HTTP failure 417 while waiting for a 100");
                        } else {
                            Curl_infof(data, "Got HTTP failure 417 while sending data");
                            streamclose(conn);
                            result = http_perhapsrewind(data, conn);
                            if (result != CURLE_OK)
                                return result;
                        }
                        Curl_http_acc_state_set_disableexpect(data, true);
                        _ = Curl_req_abort_sending(data);
                        const dup = Curl_bufref_dup(Curl_http_acc_state_url_bufref(data));
                        Curl_http_acc_req_set_newurl(data, dup);
                        if (dup == null)
                            return CURLE_OUT_OF_MEMORY;
                    } else if (Curl_http_acc_set_http_keep_sending_on_error(data)) {
                        Curl_infof(data, "HTTP error before end of send, keep sending");
                        http_exp100_send_anyway(data);
                    } else {
                        Curl_infof(data, "HTTP error before end of send, stop sending");
                        streamclose(conn);
                        result = Curl_req_abort_sending(data);
                        if (result != CURLE_OK)
                            return result;
                    }
                }
            },
            else => {},
        }
    }

    if (sendf.Curl_creader_will_rewind(data) and !Curl_req_done_sending(data)) {
        Curl_infof(data, "Keep sending data to get tossed away");
        Curl_http_acc_req_set_send(data);
    }
    return result;
}

fn http_on_response(
    data: *Curl_easy,
    last_hd_in: ?[*]const u8,
    last_hd_len: usize,
    buf: ?[*]const u8,
    blen: usize,
    pconsumed: *usize,
) CURLcode {
    const conn = Curl_http_acc_conn(data) orelse return CURLE_BAD_FUNCTION_ARGUMENT;
    var result: CURLcode = CURLE_OK;
    var conn_changed = false;
    var last_hd = last_hd_in;
    const empty_buf: [1]u8 = .{0};
    const buf_ptr: [*]const u8 = buf orelse &empty_buf;

    pconsumed.* = 0;

    if (Curl_http_acc_req_upgr101(data) == UPGR101_RECEIVED) {
        if (Curl_http_acc_req_httpversion(data) != 20)
            Curl_infof(data, "Lying server, not serving HTTP/2");
    }

    const httpcode = Curl_http_acc_req_httpcode(data);
    if (httpcode < 200 and last_hd != null) {
        result = http_write_header(data, last_hd.?, last_hd_len);
        last_hd = null;
        if (result != CURLE_OK)
            return finish_on_response(data, result, last_hd, last_hd_len, conn_changed);
    }

    if (httpcode < 100) {
        Curl_failf(data, "Unsupported response code in HTTP response");
        result = CURLE_UNSUPPORTED_PROTOCOL;
        return finish_on_response(data, result, last_hd, last_hd_len, conn_changed);
    } else if (httpcode < 200) {
        result = http_on_1xx_response(data, buf_ptr, blen, pconsumed, &conn_changed);
        return finish_on_response(data, result, last_hd, last_hd_len, conn_changed);
    }

    Curl_http_acc_req_set_header(data, false);
    if (Curl_http_acc_conn_bits_upgrade_in_progress(conn)) {
        Curl_http_acc_conn_set_bits_upgrade_in_progress(conn, false);
        conn_changed = true;
    }

    if (Curl_http_acc_req_size(data) == -1 and
        !Curl_http_acc_req_chunk(data) and
        !Curl_http_acc_conn_bits_close(conn) and
        Curl_http_acc_req_httpversion(data) == 11 and
        (Curl_http_acc_conn_scheme_protocol(conn) & CURLPROTO_RTSP) == 0 and
        Curl_http_acc_state_httpreq(data) != HTTPREQ_HEAD)
    {
        Curl_infof(data, "no chunk, no close, no size. Assume close to signal end");
        streamclose(conn);
    }

    http_check_auth_closure(data, conn);

    if (hasFeat(FEAT_WEBSOCKETS) and Curl_http_acc_req_upgr101(data) == UPGR101_WS) {
        Curl_failf(data, "Refused WebSocket upgrade: %d", Curl_http_acc_req_httpcode(data));
        result = CURLE_HTTP_RETURNED_ERROR;
        return finish_on_response(data, result, last_hd, last_hd_len, conn_changed);
    }

    if (http_should_fail(data, Curl_http_acc_req_httpcode(data))) {
        Curl_failf(data, "The requested URL returned error: %d", Curl_http_acc_req_httpcode(data));
        result = CURLE_HTTP_RETURNED_ERROR;
        return finish_on_response(data, result, last_hd, last_hd_len, conn_changed);
    }

    result = Curl_http_auth_act(data);
    if (result != CURLE_OK)
        return finish_on_response(data, result, last_hd, last_hd_len, conn_changed);

    if (Curl_http_acc_req_httpcode(data) >= 300) {
        result = http_handle_send_error(data);
        if (result != CURLE_OK)
            return finish_on_response(data, result, last_hd, last_hd_len, conn_changed);
    }

    result = http_firstwrite(data);
    if (result != CURLE_OK)
        return finish_on_response(data, result, last_hd, last_hd_len, conn_changed);

    result = http_size(data);
    if (result != CURLE_OK)
        return finish_on_response(data, result, last_hd, last_hd_len, conn_changed);

    if (hasFeat(FEAT_RTSP) and
        (Curl_http_acc_conn_scheme_protocol(conn) & CURLPROTO_RTSP) != 0 and
        Curl_http_acc_req_no_body(data) and
        !Curl_http_acc_set_opt_no_body(data) and
        Curl_http_acc_req_size(data) > 0)
    {
        Curl_http_acc_req_set_no_body(data, false);
    }

    if (Curl_http_acc_req_no_body(data))
        Curl_http_acc_req_set_download_done(data, true);

    if (Curl_http_acc_req_maxdownload(data) == 0 and Curl_http_acc_req_httpversion_sent(data) < 20)
        Curl_http_acc_req_set_download_done(data, true);

    return finish_on_response(data, result, last_hd, last_hd_len, conn_changed);
}

inline fn finish_on_response(
    data: *Curl_easy,
    result_in: CURLcode,
    last_hd: ?[*]const u8,
    last_hd_len: usize,
    conn_changed: bool,
) CURLcode {
    var result = result_in;
    if (last_hd) |lh| {
        result = Curl_1st_fatal(result, http_write_header(data, lh, last_hd_len));
    }
    if (conn_changed) {
        Curl_multi_connchanged(Curl_http_acc_multi(data));
    }
    return result;
}

fn http_rw_hd(
    data: *Curl_easy,
    hd: [*:0]const u8,
    hdlen: usize,
    buf_remain: ?[*]const u8,
    blen: usize,
    pconsumed: *usize,
) CURLcode {
    const conn = Curl_http_acc_conn(data) orelse return CURLE_BAD_FUNCTION_ARGUMENT;
    var result: CURLcode = CURLE_OK;
    var writetype: c_int = sendf.CLIENTWRITE_HEADER;

    pconsumed.* = 0;
    if (hd[0] == 0x0a or hd[0] == 0x0d) {
        var last_header: dynbuf = undefined;
        var consumed: usize = 0;

        containers.curlx_dyn_init(&last_header, hdlen + 1);
        result = containers.curlx_dyn_addn(&last_header, hd, hdlen);
        if (result != CURLE_OK)
            return result;

        containers.curlx_dyn_reset(Curl_http_acc_state_headerb(data));
        result = http_on_response(
            data,
            containers.curlx_dyn_ptr(&last_header),
            containers.curlx_dyn_len(&last_header),
            buf_remain,
            blen,
            &consumed,
        );
        pconsumed.* += consumed;
        containers.curlx_dyn_free(&last_header);
        return result;
    }

    const prev_hl = Curl_http_acc_req_headerline(data);
    Curl_http_acc_req_set_headerline(data, prev_hl + 1);
    if (prev_hl == 0) {
        var fine_statusline = false;
        Curl_http_acc_req_set_httpversion(data, 0);
        const proto = Curl_http_acc_conn_scheme_protocol(conn);

        if ((proto & PROTO_FAMILY_HTTP) != 0) {
            var p_opt: ?[*:0]const u8 = hd;
            curlx_str_passblanks(&p_opt);
            var p = p_opt.?;

            if (std.mem.startsWith(u8, std.mem.span(p), "HTTP/")) {
                p += 5;
                switch (p[0]) {
                    '1' => {
                        p += 1;
                        if (p[0] == '.' and (p[1] == '0' or p[1] == '1')) {
                            if (isBlank(p[2])) {
                                Curl_http_acc_req_set_httpversion(data, @intCast(10 + (p[1] - '0')));
                                p += 3;
                                if (isDigit(p[0]) and isDigit(p[1]) and isDigit(p[2])) {
                                    const hc: c_int = (@as(c_int, p[0] - '0') * 100) +
                                        (@as(c_int, p[1] - '0') * 10) +
                                        @as(c_int, p[2] - '0');
                                    Curl_http_acc_req_set_httpcode(data, hc);
                                    fine_statusline = true;
                                }
                            }
                        }
                        if (!fine_statusline) {
                            Curl_failf(data, "Unsupported HTTP/1 subversion in response");
                            return CURLE_UNSUPPORTED_PROTOCOL;
                        }
                    },
                    '2', '3' => {
                        if (isBlank(p[1])) {
                            Curl_http_acc_req_set_httpversion(data, @intCast((p[0] - '0') * 10));
                            p += 2;
                            if (isDigit(p[0]) and isDigit(p[1]) and isDigit(p[2])) {
                                const hc: c_int = (@as(c_int, p[0] - '0') * 100) +
                                    (@as(c_int, p[1] - '0') * 10) +
                                    @as(c_int, p[2] - '0');
                                Curl_http_acc_req_set_httpcode(data, hc);
                                p += 3;
                                if (isBlank(p[0])) {
                                    fine_statusline = true;
                                }
                            }
                        }
                    },
                    else => {
                        Curl_failf(data, "Unsupported HTTP version in response");
                        return CURLE_UNSUPPORTED_PROTOCOL;
                    },
                }
            }

            if (!fine_statusline) {
                const check = checkhttpprefix(data, hd, hdlen);
                if (check == .STATUS_DONE) {
                    fine_statusline = true;
                    Curl_http_acc_req_set_httpcode(data, 200);
                    Curl_http_acc_req_set_httpversion(data, 10);
                }
            }
        } else if ((proto & CURLPROTO_RTSP) != 0) {
            var p: ?[*:0]const u8 = hd;
            var ver = std.mem.zeroes(Curl_str);
            var status: curl_off_t = 0;
            if (curlx_str_until(&p, &ver, 32, ' ') == 0 and
                curlx_str_single(&p, ' ') == 0 and
                curlx_str_number(&p, &status, 999) == 0)
            {
                curlx_str_trimblanks(&ver);
                if (curlx_str_cmp(&ver, "RTSP/1.0") != 0) {
                    Curl_http_acc_req_set_httpcode(data, @intCast(status));
                    fine_statusline = true;
                    Curl_http_acc_req_set_httpversion(data, 11);
                }
            }
            if (!fine_statusline)
                return CURLE_WEIRD_SERVER_REPLY;
        }

        if (fine_statusline) {
            result = http_statusline(data, conn);
            if (result != CURLE_OK)
                return result;
            writetype |= sendf.CLIENTWRITE_STATUS;
        } else {
            Curl_http_acc_req_set_header(data, false);
            return CURLE_WEIRD_SERVER_REPLY;
        }
    }

    result = Curl_verify_header(data, hd, hdlen);
    if (result != CURLE_OK)
        return result;

    result = http_header(data, hd, hdlen);
    if (result != CURLE_OK)
        return result;

    Curl_debug(data, CURLINFO_HEADER_IN, hd, hdlen);

    if (@divTrunc(Curl_http_acc_req_httpcode(data), 100) == 1)
        writetype |= sendf.CLIENTWRITE_1XX;
    result = sendf.Curl_client_write(data, writetype, hd, hdlen);
    if (result != CURLE_OK)
        return result;

    result = Curl_bump_headersize(data, hdlen, false);
    if (result != CURLE_OK)
        return result;

    return CURLE_OK;
}

pub export fn Curl_http_to_fold(bf: *dynbuf) callconv(.c) void {
    var len = containers.curlx_dyn_len(bf);
    const hd = containers.curlx_dyn_ptr(bf) orelse return;
    if (len > 0 and hd[len - 1] == '\n')
        len -= 1;
    if (len > 0 and hd[len - 1] == '\r')
        len -= 1;
    while (len > 0 and isBlank(hd[len - 1]))
        len -= 1;
    _ = containers.curlx_dyn_setlen(bf, len);
}

fn unfold_header(data: *Curl_easy) void {
    Curl_http_to_fold(Curl_http_acc_state_headerb(data));
    Curl_http_acc_state_set_leading_unfold(data, true);
}

fn http_parse_headers(
    data: *Curl_easy,
    buf_in: [*]const u8,
    blen_in: usize,
    pconsumed: *usize,
) CURLcode {
    const conn = Curl_http_acc_conn(data) orelse return CURLE_BAD_FUNCTION_ARGUMENT;
    const hb = Curl_http_acc_state_headerb(data);
    var result: CURLcode = CURLE_OK;
    var buf = buf_in;
    var blen = blen_in;
    var leftover_body = false;

    if (Curl_http_acc_state_maybe_folded(data) and blen > 0) {
        if (isBlank(buf[0])) {
            unfold_header(data);
        } else {
            var ignore_this: usize = 0;
            if (containers.curlx_dyn_ptr(hb)) |ptr| {
                result = http_rw_hd(
                    data,
                    ptr,
                    containers.curlx_dyn_len(hb),
                    null,
                    0,
                    &ignore_this,
                );
            }
            containers.curlx_dyn_reset(hb);
            if (result != CURLE_OK)
                return result;
        }
        Curl_http_acc_state_set_maybe_folded(data, false);
    }

    pconsumed.* = 0;
    while (blen > 0 and Curl_http_acc_req_header(data)) {
        var unfold_len: usize = 0;

        if (Curl_http_acc_state_leading_unfold(data)) {
            while (blen > 0 and isBlank(buf[0])) {
                buf += 1;
                blen -= 1;
                unfold_len += 1;
            }
            if (blen > 0) {
                result = containers.curlx_dyn_addn(hb, " ", 1);
                if (result != CURLE_OK)
                    return result;
                Curl_http_acc_state_set_leading_unfold(data, false);
            }
        }

        const nl_idx = if (blen > 0) std.mem.indexOfScalar(u8, buf[0..blen], '\n') else null;
        if (nl_idx == null) {
            result = containers.curlx_dyn_addn(hb, buf, blen);
            if (result != CURLE_OK)
                return result;
            pconsumed.* += blen + unfold_len;

            if (Curl_http_acc_req_headerline(data) == 0) {
                if (containers.curlx_dyn_ptr(hb)) |ptr| {
                    const st = checkprotoprefix(data, conn, ptr, containers.curlx_dyn_len(hb));
                    if (st == .STATUS_BAD) {
                        Curl_http_acc_req_set_header(data, false);
                        streamclose(conn);
                        if (Curl_http_acc_req_httpversion(data) >= 10 or Curl_http_acc_conn_bits_reuse(conn)) {
                            Curl_failf(data, "Invalid status line");
                            return CURLE_WEIRD_SERVER_REPLY;
                        }
                        if (!Curl_http_acc_neg_accept_09(Curl_http_acc_state_http_neg(data))) {
                            Curl_failf(data, "Received HTTP/0.9 when not allowed");
                            return CURLE_UNSUPPORTED_PROTOCOL;
                        }
                        leftover_body = true;
                        break;
                    }
                }
            }
            break;
        }

        var consumed = nl_idx.? + 1;
        result = containers.curlx_dyn_addn(hb, buf, consumed);
        if (result != CURLE_OK)
            return result;
        blen -= consumed;
        buf += consumed;
        pconsumed.* += consumed + unfold_len;

        const hlen = containers.curlx_dyn_len(hb);
        const hd = containers.curlx_dyn_ptr(hb) orelse break;

        if (Curl_http_acc_req_headerline(data) == 0) {
            const st = checkprotoprefix(data, conn, hd, hlen);
            if (st == .STATUS_BAD) {
                streamclose(conn);
                if (Curl_http_acc_req_httpversion(data) >= 10 or Curl_http_acc_conn_bits_reuse(conn)) {
                    Curl_failf(data, "Invalid status line");
                    return CURLE_WEIRD_SERVER_REPLY;
                }
                if (!Curl_http_acc_neg_accept_09(Curl_http_acc_state_http_neg(data))) {
                    Curl_failf(data, "Received HTTP/0.9 when not allowed");
                    return CURLE_UNSUPPORTED_PROTOCOL;
                }
                Curl_http_acc_req_set_header(data, false);
                leftover_body = true;
                break;
            }
        } else {
            if (hlen > 0 and !isNewline(hd[0])) {
                if (blen > 0 and isBlank(buf[0])) {
                    unfold_header(data);
                    continue;
                } else if (blen == 0) {
                    Curl_http_acc_state_set_maybe_folded(data, true);
                    break;
                }
            }
        }

        result = http_rw_hd(data, hd, hlen, buf, blen, &consumed);
        containers.curlx_dyn_reset(hb);
        if (consumed > 0) {
            blen -= consumed;
            buf += consumed;
            pconsumed.* += consumed;
        }
        if (result != CURLE_OK)
            return result;
    }

    if (!Curl_http_acc_req_header(data) and !leftover_body) {
        containers.curlx_dyn_free(hb);
    }
    return CURLE_OK;
}

pub export fn Curl_http_write_resp_hd(
    data: *Curl_easy,
    hd: [*:0]const u8,
    hdlen: usize,
    is_eos: bool,
) callconv(.c) CURLcode {
    var consumed: usize = 0;
    const tmp: [1]u8 = .{0};
    var result = http_rw_hd(data, hd, hdlen, &tmp, 0, &consumed);
    if (result == CURLE_OK and is_eos) {
        result = sendf.Curl_client_write(
            data,
            sendf.CLIENTWRITE_BODY | sendf.CLIENTWRITE_EOS,
            &tmp,
            0,
        );
    }
    return result;
}

pub export fn Curl_http_write_resp_hds(
    data: *Curl_easy,
    buf: [*]const u8,
    blen: usize,
    pconsumed: *usize,
) callconv(.c) CURLcode {
    if (!Curl_http_acc_req_header(data)) {
        pconsumed.* = 0;
        return CURLE_OK;
    } else {
        const hb = Curl_http_acc_state_headerb(data);
        var result = http_parse_headers(data, buf, blen, pconsumed);
        if (result == CURLE_OK and !Curl_http_acc_req_header(data)) {
            if (!Curl_http_acc_req_no_body(data) and containers.curlx_dyn_len(hb) > 0) {
                if (containers.curlx_dyn_ptr(hb)) |ptr| {
                    result = sendf.Curl_client_write(
                        data,
                        sendf.CLIENTWRITE_BODY,
                        ptr,
                        containers.curlx_dyn_len(hb),
                    );
                }
            }
            containers.curlx_dyn_free(hb);
        }
        return result;
    }
}

pub export fn Curl_http_write_resp(
    data: *Curl_easy,
    buf_in: [*]const u8,
    blen_in: usize,
    is_eos: bool,
) callconv(.c) CURLcode {
    var consumed: usize = 0;
    var buf = buf_in;
    var blen = blen_in;

    var result = Curl_http_write_resp_hds(data, buf, blen, &consumed);
    if (result != CURLE_OK or Curl_http_acc_req_done(data))
        return result;

    blen -= consumed;
    buf += consumed;
    if (!Curl_http_acc_req_header(data) and (blen > 0 or is_eos)) {
        var flags: c_int = sendf.CLIENTWRITE_BODY;
        if (is_eos)
            flags |= sendf.CLIENTWRITE_EOS;
        result = sendf.Curl_client_write(data, flags, buf, blen);
    }
    return result;
}

pub export fn Curl_http_decode_status(
    pstatus: *i32,
    s: [*]const u8,
    len: usize,
) callconv(.c) CURLcode {
    if (len != 3) {
        pstatus.* = -1;
        return CURLE_BAD_FUNCTION_ARGUMENT;
    }

    var status: i32 = 0;
    for (0..3) |i| {
        const c = s[i];
        if (c < '0' or c > '9') {
            pstatus.* = -1;
            return CURLE_BAD_FUNCTION_ARGUMENT;
        }
        status = status * 10 + @as(i32, c - '0');
    }
    pstatus.* = status;
    return CURLE_OK;
}

// ============================================================================
// 8. HTTP Request & Response Struct Helpers (httpreq, http_resp, H2 convert)
// ============================================================================

fn allocHttpReq(method: [*]const u8, m_len: usize) ?*httpreq {
    const raw = mem.callocMany(u8, @sizeOf(httpreq) + m_len) orelse return null;
    const method_offset = @offsetOf(httpreq, "method");
    @memcpy(raw[method_offset .. method_offset + m_len], method[0..m_len]);
    const req: *httpreq = @ptrCast(@alignCast(raw));
    return req;
}

fn httpReqMakeImpl(
    method: [*]const u8,
    m_len: usize,
    scheme: ?[*]const u8,
    s_len: usize,
    authority: ?[*]const u8,
    a_len: usize,
    path: ?[*]const u8,
    p_len: usize,
) error{OutOfMemory}!*httpreq {
    const req = allocHttpReq(method, m_len) orelse return error.OutOfMemory;
    errdefer Curl_http_req_free(req);

    if (scheme) |s| {
        req.scheme = curlx_memdup0(s, s_len) orelse return error.OutOfMemory;
    }
    if (authority) |a| {
        req.authority = curlx_memdup0(a, a_len) orelse return error.OutOfMemory;
    }
    if (path) |p| {
        req.path = curlx_memdup0(p, p_len) orelse return error.OutOfMemory;
    }
    io_buffers.Curl_dynhds_init(&req.headers, 0, DYN_HTTP_REQUEST);
    io_buffers.Curl_dynhds_init(&req.trailers, 0, DYN_HTTP_REQUEST);
    return req;
}

pub export fn Curl_http_req_make(
    preq: *?*httpreq,
    method: [*]const u8,
    m_len: usize,
    scheme: ?[*]const u8,
    s_len: usize,
    authority: ?[*]const u8,
    a_len: usize,
    path: ?[*]const u8,
    p_len: usize,
) callconv(.c) CURLcode {
    preq.* = null;
    preq.* = httpReqMakeImpl(method, m_len, scheme, s_len, authority, a_len, path, p_len) catch
        return CURLE_OUT_OF_MEMORY;
    return CURLE_OK;
}

fn req_assign_url_authority(req: *httpreq, url: *CURLU) CURLcode {
    var host: ?[*:0]u8 = null;
    var port: ?[*:0]u8 = null;
    var buf: dynbuf = undefined;
    var result: CURLcode = CURLE_URL_MALFORMAT;

    containers.curlx_dyn_init(&buf, DYN_HTTP_REQUEST);
    defer {
        mem.free(host);
        mem.free(port);
        if (result != CURLE_OK)
            containers.curlx_dyn_free(&buf);
    }

    var uc = urlapi.curl_url_get(url, .CURLUPART_HOST, &host, 0);
    if (uc != .CURLUE_OK and uc != .CURLUE_NO_HOST)
        return result;
    if (host == null) {
        req.authority = null;
        result = CURLE_OK;
        return result;
    }

    uc = urlapi.curl_url_get(url, .CURLUPART_PORT, &port, urlapi.CURLU_NO_DEFAULT_PORT);
    if (uc != .CURLUE_OK and uc != .CURLUE_NO_PORT)
        return result;

    result = containers.curlx_dyn_add(&buf, host.?);
    if (result != CURLE_OK)
        return result;
    if (port) |prt| {
        result = containers.curlx_dyn_addf(&buf, ":%s", prt);
        if (result != CURLE_OK)
            return result;
    }
    req.authority = containers.curlx_dyn_ptr(&buf);
    return result;
}

fn req_assign_url_path(req: *httpreq, url: *CURLU) CURLcode {
    var path: ?[*:0]u8 = null;
    var query: ?[*:0]u8 = null;
    var buf: dynbuf = undefined;
    var result: CURLcode = CURLE_URL_MALFORMAT;

    containers.curlx_dyn_init(&buf, DYN_HTTP_REQUEST);
    defer {
        mem.free(path);
        mem.free(query);
        if (result != CURLE_OK)
            containers.curlx_dyn_free(&buf);
    }

    var uc = urlapi.curl_url_get(url, .CURLUPART_PATH, &path, 0);
    if (uc != .CURLUE_OK)
        return result;
    uc = urlapi.curl_url_get(url, .CURLUPART_QUERY, &query, 0);
    if (uc != .CURLUE_OK and uc != .CURLUE_NO_QUERY)
        return result;

    if (query == null) {
        req.path = path;
        path = null;
    } else {
        if (path) |pth| {
            result = containers.curlx_dyn_add(&buf, pth);
        } else {
            result = CURLE_OK;
        }
        if (result == CURLE_OK)
            result = containers.curlx_dyn_addf(&buf, "?%s", query.?);
        if (result != CURLE_OK)
            return result;
        req.path = containers.curlx_dyn_ptr(&buf);
    }
    result = CURLE_OK;
    return result;
}

fn httpReqMake2Impl(
    preq: *?*httpreq,
    method: [*]const u8,
    m_len: usize,
    url: *CURLU,
    scheme_default: ?[*:0]const u8,
) error{ OutOfMemory, UrlMalformat }!void {
    const req = allocHttpReq(method, m_len) orelse return error.OutOfMemory;
    errdefer Curl_http_req_free(req);

    const uc = urlapi.curl_url_get(url, .CURLUPART_SCHEME, &req.scheme, 0);
    if (uc != .CURLUE_OK and uc != .CURLUE_NO_SCHEME)
        return error.OutOfMemory;
    if (req.scheme == null and scheme_default != null) {
        req.scheme = mem.strdup(scheme_default.?) orelse return error.OutOfMemory;
    }

    const r1 = req_assign_url_authority(req, url);
    if (r1 != CURLE_OK) {
        return if (r1 == CURLE_OUT_OF_MEMORY) error.OutOfMemory else error.UrlMalformat;
    }
    const r2 = req_assign_url_path(req, url);
    if (r2 != CURLE_OK) {
        return if (r2 == CURLE_OUT_OF_MEMORY) error.OutOfMemory else error.UrlMalformat;
    }

    io_buffers.Curl_dynhds_init(&req.headers, 0, DYN_HTTP_REQUEST);
    io_buffers.Curl_dynhds_init(&req.trailers, 0, DYN_HTTP_REQUEST);
    preq.* = req;
}

pub export fn Curl_http_req_make2(
    preq: *?*httpreq,
    method: [*]const u8,
    m_len: usize,
    url: *CURLU,
    scheme_default: ?[*:0]const u8,
) callconv(.c) CURLcode {
    preq.* = null;
    httpReqMake2Impl(preq, method, m_len, url, scheme_default) catch |err| return switch (err) {
        error.OutOfMemory => CURLE_OUT_OF_MEMORY,
        error.UrlMalformat => CURLE_URL_MALFORMAT,
    };
    return CURLE_OK;
}

pub export fn Curl_http_req_free(req: ?*httpreq) callconv(.c) void {
    const r = req orelse return;
    mem.free(r.scheme);
    mem.free(r.authority);
    mem.free(r.path);
    io_buffers.Curl_dynhds_free(&r.headers);
    io_buffers.Curl_dynhds_free(&r.trailers);
    mem.freeTyped(r);
}

const H2_NON_FIELD = [_][]const u8{
    "Host",
    "Upgrade",
    "Connection",
    "Keep-Alive",
    "Proxy-Connection",
    "Transfer-Encoding",
};

fn h2_permissible_field(e: *const dynhds_entry) bool {
    for (H2_NON_FIELD) |nf| {
        if (e.namelen == nf.len and curl_strnequal(nf.ptr, e.name, e.namelen) != 0)
            return false;
    }
    return true;
}

fn http_TE_has_token(fvalue_in: [*:0]const u8, token: [*:0]const u8) bool {
    var fvalue: [*:0]const u8 = fvalue_in;
    while (fvalue[0] != 0) {
        while (isBlank(fvalue[0]) or fvalue[0] == ',')
            fvalue += 1;
        var fv_opt: ?[*:0]const u8 = fvalue;
        var name = std.mem.zeroes(Curl_str);
        if (curlx_str_cspn(&fv_opt, &name, " \t\r;,") != 0)
            return false;
        fvalue = fv_opt.?;
        if (curlx_str_casecompare(&name, token) != 0)
            return true;

        while (fvalue[0] != 0 and fvalue[0] != ',') {
            if (fvalue[0] == '"') {
                var qw = std.mem.zeroes(Curl_str);
                var q_opt: ?[*:0]const u8 = fvalue;
                if (curlx_str_quotedword(&q_opt, &qw, CURL_MAX_HTTP_HEADER) != 0)
                    return false;
                fvalue = q_opt.?;
            } else {
                fvalue += 1;
            }
        }
    }
    return false;
}

pub export fn Curl_http_req_to_h2(
    h2_headers: *dynhds,
    req: *httpreq,
    data: *Curl_easy,
) callconv(.c) CURLcode {
    var scheme: ?[*:0]const u8 = req.scheme;
    var authority: ?[*:0]const u8 = req.authority;
    const m_ptr: [*:0]const u8 = req.methodZ();

    if (scheme == null and !std.mem.eql(u8, std.mem.span(m_ptr), "CONNECT")) {
        if (Curl_checkheaders(data, ":scheme", ":scheme".len)) |hdr| {
            var s_opt: ?[*:0]const u8 = hdr + ":scheme".len + 1;
            curlx_str_passblanks(&s_opt);
            scheme = s_opt;
            if (scheme) |sc|
                Curl_infof(data, "set pseudo header :scheme to %s", sc);
        } else {
            scheme = Curl_http_acc_peer_scheme_name(Curl_http_acc_state_origin(data));
        }
    }

    if (authority == null) {
        if (io_buffers.Curl_dynhds_get(&req.headers, "Host", 4)) |e| {
            authority = e.value;
        }
    }

    io_buffers.Curl_dynhds_reset(h2_headers);
    io_buffers.Curl_dynhds_set_opts(h2_headers, io_buffers.DYNHDS_OPT_LOWERCASE);

    var result = io_buffers.Curl_dynhds_add(h2_headers, ":method", 7, m_ptr, std.mem.len(m_ptr));
    if (result == CURLE_OK and scheme != null) {
        result = io_buffers.Curl_dynhds_add(h2_headers, ":scheme", 7, scheme.?, std.mem.len(scheme.?));
    }
    if (result == CURLE_OK and authority != null) {
        result = io_buffers.Curl_dynhds_add(h2_headers, ":authority", 10, authority.?, std.mem.len(authority.?));
    }
    if (result == CURLE_OK and req.path != null) {
        result = io_buffers.Curl_dynhds_add(h2_headers, ":path", 5, req.path.?, std.mem.len(req.path.?));
    }

    var i: usize = 0;
    const count = io_buffers.Curl_dynhds_count(&req.headers);
    while (result == CURLE_OK and i < count) : (i += 1) {
        if (io_buffers.Curl_dynhds_getn(&req.headers, i)) |e| {
            if (e.namelen == 2 and curl_strequal("TE", e.name) != 0) {
                if (http_TE_has_token(e.value, "trailers")) {
                    result = io_buffers.Curl_dynhds_add(h2_headers, e.name, e.namelen, "trailers", 8);
                }
            } else if (h2_permissible_field(e)) {
                result = io_buffers.Curl_dynhds_add(h2_headers, e.name, e.namelen, e.value, e.valuelen);
            }
        }
    }
    return result;
}

fn httpRespMakeImpl(
    status: c_int,
    description: ?[*:0]const u8,
) error{OutOfMemory}!*http_resp {
    const resp = mem.create(http_resp) orelse return error.OutOfMemory;
    errdefer Curl_http_resp_free(resp);

    resp.status = status;
    if (description) |desc| {
        resp.description = mem.strdup(desc) orelse return error.OutOfMemory;
    }
    io_buffers.Curl_dynhds_init(&resp.headers, 0, DYN_HTTP_REQUEST);
    io_buffers.Curl_dynhds_init(&resp.trailers, 0, DYN_HTTP_REQUEST);
    return resp;
}

pub export fn Curl_http_resp_make(
    presp: *?*http_resp,
    status: c_int,
    description: ?[*:0]const u8,
) callconv(.c) CURLcode {
    presp.* = null;
    presp.* = httpRespMakeImpl(status, description) catch return CURLE_OUT_OF_MEMORY;
    return CURLE_OK;
}

pub export fn Curl_http_resp_free(resp: ?*http_resp) callconv(.c) void {
    const r = resp orelse return;
    mem.free(r.description);
    io_buffers.Curl_dynhds_free(&r.headers);
    io_buffers.Curl_dynhds_free(&r.trailers);
    if (r.prev) |prev|
        Curl_http_resp_free(prev);
    mem.freeTyped(r);
}

pub export const Curl_protocol_http = Curl_protocol{
    .setup_connection = &Curl_http_setup_conn,
    .do_it = &Curl_http,
    .done = &Curl_http_done,
    .do_more = null,
    .connect_it = null,
    .connecting = null,
    .doing = null,
    .proto_pollset = null,
    .doing_pollset = &Curl_http_doing_pollset,
    .domore_pollset = null,
    .perform_pollset = &Curl_http_perform_pollset,
    .disconnect = null,
    .write_resp = &Curl_http_write_resp,
    .write_resp_hd = &Curl_http_write_resp_hd,
    .connection_is_dead = null,
    .attach = null,
    .follow = &Curl_http_follow,
};

// ============================================================================
// Unit Tests
// ============================================================================

test "Curl_copy_header_value parses and trims HTTP header value" {
    const val = Curl_copy_header_value("Content-Type:   text/html; charset=utf-8  \r\n");
    try std.testing.expect(val != null);
    defer mem.free(val);
    try std.testing.expectEqualStrings("text/html; charset=utf-8", std.mem.span(val.?));

    const empty = Curl_copy_header_value("X-Custom:   \r\n");
    try std.testing.expect(empty != null);
    defer mem.free(empty);
    try std.testing.expectEqualStrings("", std.mem.span(empty.?));

    const bad = Curl_copy_header_value("MalformedHeaderWithoutColon\r\n");
    try std.testing.expect(bad == null);
}

test "Curl_compareheader token matching" {
    try std.testing.expect(Curl_compareheader(
        "Connection: keep-alive, Upgrade\r\n",
        "Connection:",
        "Connection:".len,
        "keep-alive",
        "keep-alive".len,
    ));
    try std.testing.expect(Curl_compareheader(
        "Connection: keep-alive, Upgrade\r\n",
        "Connection:",
        "Connection:".len,
        "upgrade",
        "upgrade".len,
    ));
    try std.testing.expect(!Curl_compareheader(
        "Connection: keep-alive-extra\r\n",
        "Connection:",
        "Connection:".len,
        "keep-alive",
        "keep-alive".len,
    ));
}

test "Curl_http_decode_status validates 3-digit HTTP status code" {
    var code: i32 = 0;
    try std.testing.expectEqual(CURLE_OK, Curl_http_decode_status(&code, "200", 3));
    try std.testing.expectEqual(@as(i32, 200), code);

    try std.testing.expectEqual(CURLE_BAD_FUNCTION_ARGUMENT, Curl_http_decode_status(&code, "20", 2));
    try std.testing.expectEqual(@as(i32, -1), code);

    try std.testing.expectEqual(CURLE_BAD_FUNCTION_ARGUMENT, Curl_http_decode_status(&code, "20a", 3));
    try std.testing.expectEqual(@as(i32, -1), code);
}

test "Curl_http_req_make and Curl_http_req_free" {
    var req: ?*httpreq = null;
    const rc = Curl_http_req_make(&req, "POST", 4, "https", 5, "example.com", 11, "/v1/items", 9);
    try std.testing.expectEqual(CURLE_OK, rc);
    try std.testing.expect(req != null);
    defer Curl_http_req_free(req);

    const r = req.?;
    try std.testing.expectEqualStrings("POST", std.mem.span(r.methodPtr()));
    try std.testing.expectEqualStrings("https", std.mem.span(r.scheme.?));
    try std.testing.expectEqualStrings("example.com", std.mem.span(r.authority.?));
    try std.testing.expectEqualStrings("/v1/items", std.mem.span(r.path.?));
}

test "Curl_http_resp_make and Curl_http_resp_free" {
    var resp: ?*http_resp = null;
    const rc = Curl_http_resp_make(&resp, 200, "OK");
    try std.testing.expectEqual(CURLE_OK, rc);
    try std.testing.expect(resp != null);
    defer Curl_http_resp_free(resp);

    try std.testing.expectEqual(@as(c_int, 200), resp.?.status);
    try std.testing.expectEqualStrings("OK", std.mem.span(resp.?.description.?));
}
