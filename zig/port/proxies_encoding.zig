const std = @import("std");
const builtin = @import("builtin");
const backend_options = @import("backend_options");
const mem = @import("mem.zig");
const primitives = @import("primitives.zig");
const containers = @import("containers.zig");
const curlx_parse = @import("curlx_parse.zig");
const curlx_time_net = @import("curlx_time_net.zig");
const os_leaf = @import("os_leaf.zig");
const urlapi = @import("urlapi.zig");
const io_buffers = @import("io_buffers.zig");
const vdns_cfilters = @import("vdns_cfilters.zig");
const altsvc_hsts_peer = @import("altsvc_hsts_peer.zig");
const http1_options = @import("http1_options.zig");
const http_auth_chunks = @import("http_auth_chunks.zig");
const protocol_version_mime = @import("protocol_version_mime.zig");

pub const CURLcode = c_uint;
pub const CURLE_OK: CURLcode = 0;
pub const CURLE_UNSUPPORTED_PROTOCOL: CURLcode = 1;
pub const CURLE_FAILED_INIT: CURLcode = 2;
pub const CURLE_COULDNT_RESOLVE_PROXY: CURLcode = 5;
pub const CURLE_COULDNT_CONNECT: CURLcode = 7;
pub const CURLE_WEIRD_SERVER_REPLY: CURLcode = 8;
pub const CURLE_WRITE_ERROR: CURLcode = 23;
pub const CURLE_OUT_OF_MEMORY: CURLcode = 27;
pub const CURLE_OPERATION_TIMEDOUT: CURLcode = 28;
pub const CURLE_BAD_FUNCTION_ARGUMENT: CURLcode = 43;
pub const CURLE_UNKNOWN_OPTION: CURLcode = 48;
pub const CURLE_RECV_ERROR: CURLcode = 56;
pub const CURLE_BAD_CONTENT_ENCODING: CURLcode = 61;
pub const CURLE_AGAIN: CURLcode = 81;

pub const Curl_easy = vdns_cfilters.Curl_easy;
pub const connectdata = vdns_cfilters.connectdata;
pub const easy_pollset = vdns_cfilters.easy_pollset;
pub const Curl_cfilter = vdns_cfilters.Curl_cfilter;
pub const Curl_cftype = vdns_cfilters.Curl_cftype;
pub const curl_socket_t = curlx_time_net.curl_socket_t;
pub const Curl_peer = altsvc_hsts_peer.CurlPeer;
pub const Curl_scheme = protocol_version_mime.Curl_scheme;
pub const Curl_creds = http1_options.Curl_creds;
pub const dynbuf = containers.dynbuf;
pub const curl_slist = containers.curl_slist;
pub const Curl_str = curlx_parse.Curl_str;
pub const dynhds = io_buffers.dynhds;
pub const dynhds_entry = io_buffers.dynhds_entry;
pub const Curl_chunker = http_auth_chunks.Curl_chunker;

pub const httpreq = extern struct {
    headers: dynhds,
    trailers: dynhds,
    scheme: ?[*:0]u8,
    authority: ?[*:0]u8,
    path: ?[*:0]u8,
    method: [1]u8,
};

pub const CURL_CW_FLAG_BLOWUP: u8 = 1 << 0;

pub const Curl_cwriter = extern struct {
    cwt: *const Curl_cwtype,
    next: ?*Curl_cwriter,
    ctx: *anyopaque,
    phase: c_uint,
};

pub const Curl_cwtype = extern struct {
    name: [*:0]const u8,
    alias: ?[*:0]const u8,
    flags: u8,
    do_init: *const fn (?*Curl_easy, *Curl_cwriter) callconv(.c) CURLcode,
    do_write: *const fn (?*Curl_easy, *Curl_cwriter, c_int, [*]const u8, usize) callconv(.c) CURLcode,
    do_flush: *const fn (?*Curl_easy, *Curl_cwriter) callconv(.c) CURLcode,
    do_close: *const fn (?*Curl_easy, *Curl_cwriter) callconv(.c) void,
    cwriter_size: usize,
};

const AF_INET: c_int = 2;
const AF_INET6: c_int = switch (builtin.os.tag) {
    .windows => 23,
    .macos, .ios, .tvos, .watchos, .visionos => 30,
    .freebsd, .netbsd, .openbsd, .dragonfly => 28,
    else => 10,
};

const CURLPROXY_HTTP: u8 = 0;
const CURLPROXY_HTTP_1_0: u8 = 1;
const CURLPROXY_HTTPS: u8 = 2;
const CURLPROXY_HTTPS2: u8 = 3;
const CURLPROXY_SOCKS4: u8 = 4;
const CURLPROXY_SOCKS5: u8 = 5;
const CURLPROXY_SOCKS4A: u8 = 6;
const CURLPROXY_SOCKS5_HOSTNAME: u8 = 7;
const CURLPROXY_HTTPS3: u8 = 8;

const PROTO_FAMILY_HTTP: u32 = (1 << 0) | (1 << 1);
const PROTOPT_SSL: u32 = 1 << 0;
const PROTOPT_NONETWORK: u32 = 1 << 4;
const PROTOPT_PROXY_AS_HTTP: u32 = 1 << 11;
const PROTOPT_NOTCPPROXY: u32 = 1 << 14;
const PROTOPT_HTTP_PROXY_TUNNEL: u32 = 1 << 18;

const CREDS_NONE: u8 = 0;
const CREDS_URL: u8 = 1;
const CREDS_NETRC: u8 = 2;
const CREDS_OPTION: u8 = 3;

const TRNSPRT_TCP: u8 = 3;
const TRNSPRT_UDP: u8 = 4;
const TRNSPRT_QUIC: u8 = 5;

const CF_TYPE_IP_CONNECT: c_int = 1 << 0;
const CF_TYPE_SETUP: c_int = 1 << 1;
const CF_TYPE_PROXY: c_int = 1 << 3;

const CF_QUERY_HOST_PORT: c_int = 2;
const CF_QUERY_ALPN_NEGOTIATED: c_int = 3;

const CURL_POLL_IN: c_int = 1;
const CURL_POLL_OUT: c_int = 2;

const CURLINFO_HEADER_IN: c_uint = 1;
const CURLINFO_HEADER_OUT: c_uint = 2;

const CLIENTWRITE_BODY: c_int = 1 << 0;
const CLIENTWRITE_HEADER: c_int = 1 << 2;
const CLIENTWRITE_STATUS: c_int = 1 << 3;
const CLIENTWRITE_CONNECT: c_int = 1 << 4;
const CLIENTWRITE_EOS: c_int = 1 << 7;

const HTTPREQ_GET: c_uint = 0;
const HTTPREQ_POST_FORM: u8 = 2;
const HTTPREQ_POST_MIME: u8 = 3;

const DYN_PROXY_CONNECT_HEADERS: usize = 16384;
const DYN_HTTP_REQUEST: usize = 1024 * 1024;

pub const proxy_info = extern struct {
    peer: ?*Curl_peer,
    creds: ?*Curl_creds,
    proxytype: u8,
};

pub const http_resp = extern struct {
    status: c_int,
    description: ?[*:0]u8,
    headers: dynhds,
    trailers: dynhds,
    prev: ?*http_resp,
};

pub const proxy_http_ver = c_uint;
pub const PROXY_HTTP_V1: proxy_http_ver = 0;
pub const PROXY_HTTP_V2: proxy_http_ver = 1;
pub const PROXY_HTTP_V3: proxy_http_ver = 2;

pub const proxy_inspect_result = c_uint;
pub const PROXY_INSPECT_OK: proxy_inspect_result = 0;
pub const PROXY_INSPECT_AUTH_RETRY: proxy_inspect_result = 1;
pub const PROXY_INSPECT_FAILED: proxy_inspect_result = 2;

extern fn curl_msnprintf(buffer: [*]u8, maxlength: usize, format: [*:0]const u8, ...) callconv(.c) c_int;
extern fn curl_maprintf(format: [*:0]const u8, ...) callconv(.c) ?[*:0]u8;
extern fn Curl_infof(data: ?*Curl_easy, fmt: [*:0]const u8, ...) callconv(.c) void;
extern fn Curl_failf(data: ?*Curl_easy, fmt: [*:0]const u8, ...) callconv(.c) void;
extern fn Curl_trc_cf_infof(data: ?*Curl_easy, cf: *const Curl_cfilter, fmt: [*:0]const u8, ...) callconv(.c) void;
extern fn Curl_debug(data: ?*Curl_easy, info_type: c_uint, ptr: ?[*]const u8, size: usize) callconv(.c) void;

extern fn Curl_proxy_get_origin(data: *Curl_easy) callconv(.c) ?*Curl_peer;
extern fn Curl_proxy_str_noproxy(data: *Curl_easy) callconv(.c) ?[*:0]const u8;
extern fn Curl_proxy_str_proxy(data: *Curl_easy) callconv(.c) ?[*:0]const u8;
extern fn Curl_proxy_str_pre_proxy(data: *Curl_easy) callconv(.c) ?[*:0]const u8;
extern fn Curl_proxy_str_proxy_service_name(data: *Curl_easy) callconv(.c) ?[*:0]const u8;
extern fn Curl_proxy_str_proxyusername(data: *Curl_easy) callconv(.c) ?[*:0]const u8;
extern fn Curl_proxy_str_proxypassword(data: *Curl_easy) callconv(.c) ?[*:0]const u8;
extern fn Curl_proxy_str_useragent(data: *Curl_easy) callconv(.c) ?[*:0]const u8;
extern fn Curl_proxy_get_set_proxytype(data: *Curl_easy) callconv(.c) u8;
extern fn Curl_proxy_get_set_proxyport(data: *Curl_easy) callconv(.c) u16;
extern fn Curl_proxy_get_tunnel_thru_httpproxy(data: *Curl_easy) callconv(.c) bool;
extern fn Curl_proxy_update_envproxy(data: *Curl_easy, proxy: ?[*:0]const u8) callconv(.c) void;
extern fn Curl_proxy_conn_set_origin_is_proxy(conn: *connectdata, val: bool) callconv(.c) void;
extern fn Curl_proxy_conn_get_scheme(conn: *connectdata) callconv(.c) *const Curl_scheme;
extern fn Curl_proxy_conn_set_scheme(conn: *connectdata, scheme: *const Curl_scheme) callconv(.c) void;
extern fn Curl_proxy_conn_get_socks_proxy(conn: *connectdata) callconv(.c) *proxy_info;
extern fn Curl_proxy_conn_get_http_proxy(conn: *connectdata) callconv(.c) *proxy_info;
extern fn Curl_proxy_conn_get_via_peer_ptr(conn: *connectdata) callconv(.c) *?*Curl_peer;
extern fn Curl_proxy_conn_get_origin_ptr(conn: *connectdata) callconv(.c) *?*Curl_peer;
extern fn Curl_proxy_data_origin_is_proxy(data: *Curl_easy) callconv(.c) bool;
extern fn Curl_proxy_get_sep_headers(data: *Curl_easy) callconv(.c) bool;
extern fn Curl_proxy_get_headers(data: *Curl_easy) callconv(.c) ?*curl_slist;
extern fn Curl_proxy_get_proxyheaders(data: *Curl_easy) callconv(.c) ?*curl_slist;
extern fn Curl_proxy_get_http_host(data: *Curl_easy) callconv(.c) ?[*:0]const u8;
extern fn Curl_proxy_get_httpreq(data: *Curl_easy) callconv(.c) u8;
extern fn Curl_proxy_get_authneg(data: *Curl_easy) callconv(.c) bool;
extern fn Curl_proxy_auth_allowed_to_host(data: *Curl_easy) callconv(.c) bool;
extern fn Curl_proxy_get_hd_proxy_auth(data: *Curl_easy) callconv(.c) ?[*:0]const u8;
extern fn Curl_proxy_clear_hd_proxy_auth(data: *Curl_easy) callconv(.c) void;
extern fn Curl_proxy_get_newurl(data: *Curl_easy) callconv(.c) ?[*:0]const u8;
extern fn Curl_proxy_clear_newurl(data: *Curl_easy) callconv(.c) bool;
extern fn Curl_proxy_start_connect_auth(data: *Curl_easy) callconv(.c) void;
extern fn Curl_proxy_set_info_httpcode(data: *Curl_easy, code: c_int) callconv(.c) void;
extern fn Curl_proxy_get_httpproxycode(data: *Curl_easy) callconv(.c) c_int;
extern fn Curl_proxy_get_req_httpcode(data: *Curl_easy) callconv(.c) c_int;
extern fn Curl_proxy_set_proxy_and_req_httpcode(data: *Curl_easy, code: c_int) callconv(.c) void;
extern fn Curl_proxy_get_authproblem(data: *Curl_easy) callconv(.c) bool;
extern fn Curl_proxy_has_avail_auth(data: *Curl_easy) callconv(.c) bool;
extern fn Curl_proxy_req_soft_reset(data: *Curl_easy) callconv(.c) void;
extern fn Curl_proxy_conn_is_closed(conn: *connectdata) callconv(.c) bool;
extern fn Curl_ce_should_skip(data: *Curl_easy, is_transfer: c_int) callconv(.c) bool;
extern fn Curl_ce_get_http_transfer_encoding(data: *Curl_easy) callconv(.c) bool;
extern fn Curl_ce_get_http_ce_skip(data: *Curl_easy) callconv(.c) bool;
extern fn Curl_ce_get_http_te_skip(data: *Curl_easy) callconv(.c) bool;
extern fn Curl_ce_set_ignorebody(data: *Curl_easy) callconv(.c) void;

extern fn Curl_checkProxyheaders(data: ?*Curl_easy, conn: ?*const connectdata, thisheader: [*]const u8, thislen: usize) callconv(.c) ?[*:0]u8;
extern fn Curl_http_req_make(
    preq: *?*httpreq,
    method: [*]const u8,
    m_len: usize,
    scheme: ?[*]const u8,
    s_len: usize,
    authority: ?[*]const u8,
    a_len: usize,
    path: ?[*]const u8,
    p_len: usize,
) callconv(.c) CURLcode;
extern fn Curl_http_req_free(req: ?*httpreq) callconv(.c) void;
extern fn Curl_http_output_auth(
    data: ?*Curl_easy,
    conn: ?*connectdata,
    request: [*:0]const u8,
    httpreq_type: c_uint,
    path: ?[*:0]const u8,
    query: ?[*:0]const u8,
    is_connect: bool,
) callconv(.c) CURLcode;
extern fn Curl_http_input_auth(data: ?*Curl_easy, proxy: bool, auth: [*:0]const u8) callconv(.c) CURLcode;
extern fn Curl_http_auth_act(data: ?*Curl_easy) callconv(.c) CURLcode;
extern fn Curl_verify_header(data: ?*Curl_easy, hd: [*]const u8, hdlen: usize) callconv(.c) CURLcode;
extern fn Curl_bump_headersize(data: ?*Curl_easy, delta: usize, connect_only: bool) callconv(.c) CURLcode;
extern fn Curl_http_to_fold(rbuf: *dynbuf) callconv(.c) void;
extern fn Curl_client_write(data: ?*Curl_easy, wtype: c_int, buf: [*]const u8, blen: usize) callconv(.c) CURLcode;
extern fn Curl_client_reset(data: ?*Curl_easy) callconv(.c) void;
extern fn Curl_creader_set_null(data: ?*Curl_easy) callconv(.c) CURLcode;
extern fn Curl_conn_cf_get_alpn_negotiated(cf: *Curl_cfilter, data: ?*Curl_easy) callconv(.c) ?[*:0]const u8;
extern fn Curl_cf_h2_proxy_insert_after(
    cf_at: *Curl_cfilter,
    data: ?*Curl_easy,
    peer: *Curl_peer,
    dest: *Curl_peer,
    udp_tunnel: bool,
) callconv(.c) CURLcode;
extern fn Curl_cf_h3_proxy_insert_after(
    cf_at: *Curl_cfilter,
    data: ?*Curl_easy,
    origin: ?*Curl_peer,
    peer: ?*Curl_peer,
    tunnel_peer: ?*Curl_peer,
    tunnel_transport: u8,
) callconv(.c) CURLcode;

const use_proxy_http3 = if (@hasDecl(backend_options, "proxy_http3")) backend_options.proxy_http3 else false;

extern fn Curl_cf_def_shutdown(cf: *Curl_cfilter, data: ?*Curl_easy, done: *bool) callconv(.c) CURLcode;
extern fn Curl_cf_def_adjust_pollset(cf: *Curl_cfilter, data: ?*Curl_easy, ps: *easy_pollset) callconv(.c) CURLcode;
extern fn Curl_cf_def_data_pending(cf: *Curl_cfilter, data: ?*const Curl_easy) callconv(.c) bool;
extern fn Curl_cf_def_send(cf: *Curl_cfilter, data: ?*Curl_easy, buf: [*]const u8, len: usize, eos: bool, pnwritten: *usize) callconv(.c) CURLcode;
extern fn Curl_cf_def_recv(cf: *Curl_cfilter, data: ?*Curl_easy, buf: [*]u8, len: usize, pnread: *usize) callconv(.c) CURLcode;
extern fn Curl_cf_def_cntrl(cf: *Curl_cfilter, data: ?*Curl_easy, event: c_int, arg1: c_int, arg2: ?*anyopaque) callconv(.c) CURLcode;
extern fn Curl_cf_def_conn_is_alive(cf: *Curl_cfilter, data: ?*Curl_easy, input_pending: *bool) callconv(.c) bool;
extern fn Curl_cf_def_conn_keep_alive(cf: *Curl_cfilter, data: ?*Curl_easy) callconv(.c) CURLcode;
extern fn Curl_cf_create(pcf: *?*Curl_cfilter, cft: *const Curl_cftype, ctx: ?*anyopaque) callconv(.c) CURLcode;
extern fn Curl_conn_cf_insert_after(cf_at: *Curl_cfilter, cf_new: *Curl_cfilter) callconv(.c) void;
extern fn Curl_conn_cf_get_socket(cf: *Curl_cfilter, data: ?*Curl_easy) callconv(.c) curl_socket_t;
extern fn Curl_pollset_change(data: ?*Curl_easy, ps: *easy_pollset, sock: curl_socket_t, add_flags: c_int, remove_flags: c_int) callconv(.c) CURLcode;
extern fn Curl_pgrsUpdate(data: ?*Curl_easy) callconv(.c) CURLcode;
extern fn Curl_pgrsReset(data: ?*Curl_easy) callconv(.c) void;
extern fn Curl_timeleft_ms(data: ?*Curl_easy) callconv(.c) curlx_time_net.timediff_t;
extern fn curlx_str_passblanks(linep: *?[*:0]const u8) callconv(.c) void;
extern fn curlx_str_number(linep: *?[*:0]const u8, nump: *i64, max: i64) callconv(.c) c_int;
extern fn curlx_str_numblanks(str: *?[*:0]const u8, num: *i64) callconv(.c) c_int;
extern fn curlx_str_cspn(linep: *?[*:0]const u8, out: *Curl_str, reject: [*:0]const u8) callconv(.c) c_int;
extern fn curlx_str_single(linep: *?[*:0]const u8, byte: u8) callconv(.c) c_int;
extern fn curlx_str_trimblanks(out: *Curl_str) callconv(.c) void;
extern fn curlx_str_casecompare(str: *Curl_str, check: ?[*:0]const u8) callconv(.c) c_int;
extern fn curlx_str_assign(out: *Curl_str, str: [*]const u8, len: usize) callconv(.c) void;
extern fn curl_url_strerror(err: c_uint) callconv(.c) [*:0]const u8;
extern fn Curl_uc_to_curlcode(uc: c_uint) callconv(.c) CURLcode;
extern fn Curl_copy_header_value(header: [*:0]const u8) callconv(.c) ?[*:0]u8;
extern fn Curl_compareheader(headerline: [*:0]const u8, header: [*]const u8, hlen: usize, content: [*]const u8, clen: usize) callconv(.c) bool;
extern fn Curl_conn_recv(data: ?*Curl_easy, num: c_int, buf: [*]u8, len: usize, pnread: *usize) callconv(.c) CURLcode;
extern fn Curl_httpchunk_init(data: ?*Curl_easy, ch: *Curl_chunker, ignore_body: bool, in_connect: bool) callconv(.c) void;
extern fn Curl_httpchunk_free(data: ?*Curl_easy, ch: *Curl_chunker) callconv(.c) void;
extern fn Curl_httpchunk_reset(data: ?*Curl_easy, ch: *Curl_chunker, ignore_body: bool) callconv(.c) void;
extern fn Curl_httpchunk_read(data: ?*Curl_easy, ch: *Curl_chunker, datap: [*]const u8, length: isize, wrotep: *usize) callconv(.c) CURLcode;
extern fn Curl_httpchunk_is_done(data: ?*Curl_easy, ch: *Curl_chunker) callconv(.c) bool;
extern const Curl_httpchunk_unencoder: Curl_cwtype;

inline fn isBlank(c: u8) bool {
    return c == ' ' or c == '\t';
}

inline fn isDigit(c: u8) bool {
    return c >= '0' and c <= '9';
}

inline fn isNewline(c: u8) bool {
    return c == '\r' or c == '\n';
}

inline fn checkprefix(prefix: [:0]const u8, str: [*:0]const u8) bool {
    return primitives.curl_strnequal(str, prefix.ptr, prefix.len) != 0;
}

inline fn peerIsIpv6(peer: *const Curl_peer) bool {
    return (peer.flags & 0x02) != 0;
}

// ============================================================================
// 1. lib/proxy.c — Proxy setup & NO_PROXY matching
// ============================================================================

const NameType = enum {
    host,
    ipv4,
    ipv6,
};

pub export fn cidr4_match(
    ipv4: ?[*:0]const u8,
    network: ?[*:0]const u8,
    bits: c_int,
) callconv(.c) bool {
    var address: u32 = 0;
    var check: u32 = 0;

    if (bits > 32)
        return false;

    const ip_str = ipv4 orelse return false;
    const net_str = network orelse return false;

    if (curlx_time_net.curlx_inet_pton(AF_INET, ip_str, &address) != 1)
        return false;
    if (curlx_time_net.curlx_inet_pton(AF_INET, net_str, &check) != 1)
        return false;

    if (bits > 0 and bits != 32) {
        const shift: u5 = @intCast(32 - bits);
        const mask: u32 = @as(u32, 0xffffffff) << shift;
        const haddr: u32 = std.mem.bigToNative(u32, address);
        const hcheck: u32 = std.mem.bigToNative(u32, check);
        if (((haddr ^ hcheck) & mask) != 0)
            return false;
        return true;
    } else if (bits == 0 and check == 0) {
        return true;
    }

    return address == check;
}

pub export fn cidr6_match(
    ipv6: ?[*:0]const u8,
    network: ?[*:0]const u8,
    bits_in: c_int,
) callconv(.c) bool {
    var bits = bits_in;
    if (bits == -1)
        bits = 128;

    const u_bits: c_uint = @bitCast(bits);
    const bytes: c_uint = u_bits / 8;
    const rest: c_uint = u_bits & 0x07;
    if (bytes > 16 or (bytes == 16 and rest != 0))
        return false;

    const ip_str = ipv6 orelse return false;
    const net_str = network orelse return false;

    var address: [16]u8 = undefined;
    var check: [16]u8 = undefined;

    if (curlx_time_net.curlx_inet_pton(AF_INET6, ip_str, &address) != 1)
        return false;
    if (curlx_time_net.curlx_inet_pton(AF_INET6, net_str, &check) != 1)
        return false;

    if (bytes != 0 and !std.mem.eql(u8, address[0..bytes], check[0..bytes]))
        return false;

    if (rest != 0) {
        const mask: u8 = @truncate(@as(u32, 0xff) << @intCast(8 - rest));
        if (((address[bytes] ^ check[bytes]) & mask) != 0)
            return false;
    }

    return true;
}

fn match_host(
    token_in: [*]const u8,
    tokenlen_in: usize,
    name: [*]const u8,
    namelen: usize,
) bool {
    var token = token_in;
    var tokenlen = tokenlen_in;

    if (token[tokenlen - 1] == '.')
        tokenlen -= 1;

    if (tokenlen != 0 and token[0] == '.') {
        token += 1;
        tokenlen -= 1;
    }

    if (tokenlen == namelen) {
        return primitives.curl_strnequal(@ptrCast(token), @ptrCast(name), namelen) != 0;
    } else if (tokenlen < namelen) {
        return (name[namelen - tokenlen - 1] == '.') and
            (primitives.curl_strnequal(@ptrCast(token), @ptrCast(name + (namelen - tokenlen)), tokenlen) != 0);
    }
    return false;
}

fn match_ip(
    ip_type: NameType,
    token: [*]const u8,
    tokenlen: usize,
    name: [*:0]const u8,
) bool {
    var bits: c_int = -1;
    var checkip: [128]u8 = undefined;
    if (tokenlen >= checkip.len)
        return false;

    @memcpy(checkip[0..tokenlen], token[0..tokenlen]);
    checkip[tokenlen] = 0;

    if (std.mem.indexOfScalar(u8, checkip[0..tokenlen], '/')) |slash_idx| {
        var value: i64 = 0;
        var p: ?[*:0]const u8 = @ptrCast(&checkip[slash_idx + 1]);
        if (curlx_str_number(&p, &value, 128) != 0 or p == null or p.?[0] != 0)
            return false;
        bits = @intCast(value);
        checkip[slash_idx] = 0;
    }

    const checkip_cstr: [*:0]const u8 = @ptrCast(&checkip);
    if (ip_type == .ipv6)
        return cidr6_match(name, checkip_cstr, bits)
    else
        return cidr4_match(name, checkip_cstr, bits);
}

pub export fn proxy_check_noproxy(
    name_opt: ?[*:0]const u8,
    no_proxy_opt: ?[*:0]const u8,
) callconv(.c) bool {
    return check_noproxy_impl(name_opt, no_proxy_opt);
}

pub export fn Curl_check_noproxy(
    name_opt: ?[*:0]const u8,
    no_proxy_opt: ?[*:0]const u8,
    spacesep: ?*bool,
) callconv(.c) bool {
    if (spacesep) |sp| sp.* = false;
    return check_noproxy_impl(name_opt, no_proxy_opt);
}

fn check_noproxy_impl(
    name_opt: ?[*:0]const u8,
    no_proxy_opt: ?[*:0]const u8,
) bool {
    const name = name_opt orelse return false;
    if (name[0] == 0)
        return false;

    const no_proxy = no_proxy_opt orelse return false;
    if (no_proxy[0] == 0)
        return false;

    if (std.mem.orderZ(u8, "*", no_proxy) == .eq)
        return true;

    var namelen = std.mem.len(name);
    var address: [16]u8 = undefined;
    var ip_type: NameType = .host;

    if (curlx_time_net.curlx_inet_pton(AF_INET, name, &address) == 1) {
        ip_type = .ipv4;
    } else if (curlx_time_net.curlx_inet_pton(AF_INET6, name, &address) == 1) {
        ip_type = .ipv6;
    } else {
        if (name[namelen - 1] == '.')
            namelen -= 1;
    }

    var p: ?[*:0]const u8 = no_proxy;
    while (p != null and p.?[0] != 0) {
        curlx_str_passblanks(&p);

        const token: [*]const u8 = p.?;
        var tokenlen: usize = 0;
        while (p.?[0] != 0 and !isBlank(p.?[0]) and p.?[0] != ',') {
            p = p.? + 1;
            tokenlen += 1;
        }

        if (tokenlen != 0) {
            const match = if (ip_type == .host)
                match_host(token, tokenlen, name, namelen)
            else
                match_ip(ip_type, token, tokenlen, name);

            if (match)
                return true;
        }

        curlx_str_passblanks(&p);
        if (p.?[0] != ',')
            break;
        while (p.?[0] == ',')
            p = p.? + 1;
    }

    return false;
}

fn proxy_detect_proxy(data: ?*Curl_easy, scheme: *const Curl_scheme) ?[*:0]u8 {
    var env_name: ?[*:0]const u8 = null;
    var proxy: ?[*:0]u8 = null;
    var name_buf: [20]u8 = undefined;

    if (scheme != &protocol_version_mime.Curl_scheme_https and
        scheme != &protocol_version_mime.Curl_scheme_http)
    {
        _ = curl_msnprintf(&name_buf, name_buf.len, "%s_proxy", scheme.name);
        env_name = @ptrCast(&name_buf);
        proxy = os_leaf.curl_getenv(env_name);
        if (proxy == null) {
            primitives.Curl_strntoupper(&name_buf, &name_buf, name_buf.len);
            proxy = os_leaf.curl_getenv(env_name);
        }
    }

    if (proxy == null and
        (scheme == &protocol_version_mime.Curl_scheme_https or
            scheme == &protocol_version_mime.Curl_scheme_wss))
    {
        env_name = "https_proxy";
        proxy = os_leaf.curl_getenv(env_name);
        if (proxy == null) {
            env_name = "HTTPS_PROXY";
            proxy = os_leaf.curl_getenv(env_name);
        }
    } else if (proxy == null and
        (scheme == &protocol_version_mime.Curl_scheme_http or
            scheme == &protocol_version_mime.Curl_scheme_ws))
    {
        env_name = "http_proxy";
        proxy = os_leaf.curl_getenv(env_name);
    }

    if (proxy == null) {
        env_name = "all_proxy";
        proxy = os_leaf.curl_getenv(env_name);
        if (proxy == null) {
            env_name = "ALL_PROXY";
            proxy = os_leaf.curl_getenv(env_name);
        }
    }

    if (proxy) |prx| {
        Curl_infof(data, "Uses proxy env variable %s == '%s'", env_name.?, prx);
    }

    return proxy;
}

fn parse_proxy(
    data: *Curl_easy,
    proxy: [*:0]const u8,
    for_pre_proxy: bool,
    proxyinfo: *proxy_info,
) CURLcode {
    var proxyuser: ?[*:0]u8 = null;
    var proxypasswd: ?[*:0]u8 = null;
    var scheme: ?[*:0]u8 = null;
    var result: CURLcode = CURLE_OK;
    var proxytype: u8 = if (for_pre_proxy) CURLPROXY_SOCKS4 else Curl_proxy_get_set_proxytype(data);
    const uhp = urlapi.curl_url() orelse return CURLE_OUT_OF_MEMORY;
    defer {
        mem.free(scheme);
        mem.free(proxyuser);
        mem.free(proxypasswd);
        urlapi.curl_url_cleanup(uhp);
    }

    var uc = urlapi.curl_url_set(
        uhp,
        .CURLUPART_URL,
        proxy,
        urlapi.CURLU_NON_SUPPORT_SCHEME | urlapi.CURLU_GUESS_SCHEME,
    );
    if (uc == .CURLUE_OK) {
        uc = urlapi.curl_url_get(uhp, .CURLUPART_SCHEME, &scheme, urlapi.CURLU_NO_GUESS_SCHEME);
        if (uc == .CURLUE_OK) {
            result = altsvc_hsts_peer.Curl_scheme_to_proxytype(data, scheme, &proxytype, proxy);
            if (result != CURLE_OK)
                return result;
        } else if (uc != .CURLUE_NO_SCHEME) {
            return CURLE_OUT_OF_MEMORY;
        }
    } else {
        Curl_failf(
            data,
            "Unsupported proxy syntax in '%s': %s",
            proxy,
            curl_url_strerror(@backingInt(uc)),
        );
        return CURLE_COULDNT_RESOLVE_PROXY;
    }

    result = altsvc_hsts_peer.Curl_peer_from_proxy_url(
        uhp,
        data,
        proxy,
        proxytype,
        Curl_proxy_get_set_proxyport(data),
        &proxyinfo.peer,
        &proxytype,
    );
    if (result != CURLE_OK)
        return result;

    switch (proxytype) {
        CURLPROXY_HTTP,
        CURLPROXY_HTTP_1_0,
        CURLPROXY_HTTPS,
        CURLPROXY_HTTPS2,
        CURLPROXY_HTTPS3,
        => {
            if (for_pre_proxy) {
                Curl_failf(data, "Unsupported pre-proxy type for '%s'", proxy);
                return CURLE_COULDNT_RESOLVE_PROXY;
            }
        },
        CURLPROXY_SOCKS4,
        CURLPROXY_SOCKS4A,
        CURLPROXY_SOCKS5,
        CURLPROXY_SOCKS5_HOSTNAME,
        => {},
        else => {
            Curl_failf(data, "Unsupported proxy type %u for '%s'", @as(c_uint, proxytype), proxy);
            return CURLE_COULDNT_RESOLVE_PROXY;
        },
    }

    uc = urlapi.curl_url_get(uhp, .CURLUPART_USER, &proxyuser, urlapi.CURLU_URLDECODE);
    if (uc != .CURLUE_OK and uc != .CURLUE_NO_USER) {
        return Curl_uc_to_curlcode(@backingInt(uc));
    }
    uc = urlapi.curl_url_get(uhp, .CURLUPART_PASSWORD, &proxypasswd, urlapi.CURLU_URLDECODE);
    if (uc != .CURLUE_OK and uc != .CURLUE_NO_PASSWORD) {
        return Curl_uc_to_curlcode(@backingInt(uc));
    }

    if (proxyuser != null or proxypasswd != null) {
        result = http1_options.Curl_creds_create(
            proxyuser,
            proxypasswd,
            null,
            null,
            Curl_proxy_str_proxy_service_name(data),
            CREDS_URL,
            &proxyinfo.creds,
        );
        if (result != CURLE_OK)
            return result;
    } else if (!for_pre_proxy and
        (Curl_proxy_str_proxyusername(data) != null or
            Curl_proxy_str_proxypassword(data) != null or
            Curl_proxy_str_proxy_service_name(data) != null))
    {
        result = http1_options.Curl_creds_create(
            Curl_proxy_str_proxyusername(data),
            Curl_proxy_str_proxypassword(data),
            null,
            null,
            Curl_proxy_str_proxy_service_name(data),
            CREDS_OPTION,
            &proxyinfo.creds,
        );
    } else {
        http1_options.Curl_creds_unlink(&proxyinfo.creds);
    }

    proxyinfo.proxytype = proxytype;
    return result;
}

fn proxy_do_not_proxy(data: *Curl_easy) bool {
    const origin = Curl_proxy_get_origin(data) orelse return true;
    const scheme = origin.scheme orelse return true;
    if ((scheme.flags & PROTOPT_NONETWORK) != 0)
        return true;

    var no_proxy = Curl_proxy_str_noproxy(data);
    var env_no_proxy: ?[*:0]u8 = null;
    if (no_proxy == null) {
        var p: [*:0]const u8 = "no_proxy";
        env_no_proxy = os_leaf.curl_getenv(p);
        if (env_no_proxy == null) {
            p = "NO_PROXY";
            env_no_proxy = os_leaf.curl_getenv(p);
        }
        if (env_no_proxy) |env_np| {
            Curl_infof(data, "Uses proxy env variable %s == '%s'", p, env_np);
        }
        no_proxy = env_no_proxy;
    }

    const do_not_proxy = proxy_check_noproxy(origin.hostname, no_proxy);
    mem.free(env_no_proxy);
    return do_not_proxy;
}

pub export fn Curl_proxy_init_conn(
    data: *Curl_easy,
    conn: *connectdata,
) callconv(.c) CURLcode {
    var proxy: ?[*:0]u8 = null;
    var pre_proxy: ?[*:0]u8 = null;
    var do_env_detect = true;
    var result: CURLcode = CURLE_OK;

    defer {
        mem.free(pre_proxy);
        mem.free(proxy);
    }

    Curl_proxy_conn_set_origin_is_proxy(conn, false);

    if (proxy_do_not_proxy(data))
        return CURLE_OK;

    if (Curl_proxy_str_proxy(data)) |str| {
        if (str[0] != 0) {
            proxy = mem.strdup(str);
            if (proxy == null) {
                Curl_failf(data, "memory shortage");
                return CURLE_OUT_OF_MEMORY;
            }
        } else {
            do_env_detect = false;
        }
    }

    if (Curl_proxy_str_pre_proxy(data)) |str| {
        if (str[0] != 0) {
            pre_proxy = mem.strdup(str);
            if (pre_proxy == null) {
                Curl_failf(data, "memory shortage");
                return CURLE_OUT_OF_MEMORY;
            }
        } else {
            do_env_detect = false;
        }
    }

    if (proxy == null and pre_proxy == null and do_env_detect) {
        proxy = proxy_detect_proxy(data, Curl_proxy_conn_get_scheme(conn));
    }

    if (proxy == null and pre_proxy == null)
        return CURLE_OK;

    const socks_proxy = Curl_proxy_conn_get_socks_proxy(conn);
    const http_proxy = Curl_proxy_conn_get_http_proxy(conn);

    if (pre_proxy) |pp| {
        result = parse_proxy(data, pp, true, socks_proxy);
        if (result != CURLE_OK)
            return result;
    }

    if (proxy) |prx| {
        result = parse_proxy(data, prx, false, http_proxy);
        if (result != CURLE_OK)
            return result;

        switch (http_proxy.proxytype) {
            CURLPROXY_SOCKS4,
            CURLPROXY_SOCKS4A,
            CURLPROXY_SOCKS5,
            CURLPROXY_SOCKS5_HOSTNAME,
            => {
                if (pre_proxy != null) {
                    Curl_failf(
                        data,
                        "Having a SOCKS pre-proxy and proxy is not supported with '%s'",
                        prx,
                    );
                    return CURLE_COULDNT_RESOLVE_PROXY;
                }
                socks_proxy.* = http_proxy.*;
                http_proxy.* = std.mem.zeroes(proxy_info);
            },
            else => {},
        }
    }

    if (http_proxy.peer) |hp_peer| {
        const origin = Curl_proxy_get_origin(data).?;
        const scheme: *const Curl_scheme = @ptrCast(@alignCast(origin.scheme.?));
        var tunnel_proxy = Curl_proxy_get_tunnel_thru_httpproxy(data);

        if (!tunnel_proxy) {
            if (Curl_proxy_conn_get_via_peer_ptr(conn).* != null) {
                tunnel_proxy = true;
            } else if ((scheme.flags & PROTOPT_SSL) != 0) {
                tunnel_proxy = true;
            } else if ((scheme.flags & PROTOPT_HTTP_PROXY_TUNNEL) != 0) {
                tunnel_proxy = true;
            } else if ((scheme.protocol & PROTO_FAMILY_HTTP) == 0 and
                (scheme.flags & PROTOPT_PROXY_AS_HTTP) == 0)
            {
                tunnel_proxy = true;
            }
        }

        if (!tunnel_proxy) {
            altsvc_hsts_peer.Curl_peer_link(Curl_proxy_conn_get_origin_ptr(conn), hp_peer);
            Curl_proxy_conn_set_scheme(conn, @ptrCast(@alignCast(hp_peer.scheme.?)));
            Curl_proxy_conn_set_origin_is_proxy(conn, true);
        }

        Curl_proxy_update_envproxy(data, proxy);
    }

    return result;
}

// ============================================================================
// 2. lib/http_proxy.c — HTTP Proxy Tunnel Requests & HTTP-PROXY cfilter
// ============================================================================

const CurlProxyUse = enum {
    header_server,
    header_proxy,
    header_connect,
    header_connect_udp,
};

fn dynhds_add_custom(
    data: *Curl_easy,
    is_connect: bool,
    httpversion: c_int,
    is_udp: bool,
    hds: *dynhds,
) CURLcode {
    var h: [2]?*curl_slist = .{ null, null };
    var numlists: usize = 1;

    const proxy: CurlProxyUse = if (is_connect and !is_udp)
        .header_connect
    else if (is_connect and is_udp)
        .header_connect_udp
    else if (Curl_proxy_data_origin_is_proxy(data))
        .header_proxy
    else
        .header_server;

    switch (proxy) {
        .header_server => {
            h[0] = Curl_proxy_get_headers(data);
        },
        .header_proxy => {
            h[0] = Curl_proxy_get_headers(data);
            if (Curl_proxy_get_sep_headers(data)) {
                h[1] = Curl_proxy_get_proxyheaders(data);
                numlists += 1;
            }
        },
        .header_connect, .header_connect_udp => {
            if (Curl_proxy_get_sep_headers(data)) {
                h[0] = Curl_proxy_get_proxyheaders(data);
            } else {
                h[0] = Curl_proxy_get_headers(data);
            }
        },
    }

    var i: usize = 0;
    while (i < numlists) : (i += 1) {
        var headers = h[i];
        while (headers) |hdr_node| : (headers = hdr_node.next) {
            var name: Curl_str = .{ .str = null, .len = 0 };
            var value: ?[*:0]const u8 = null;
            var valuelen: usize = 0;
            var ptr: ?[*:0]const u8 = hdr_node.data;

            if (curlx_str_cspn(&ptr, &name, ";:") == 0) {
                if (curlx_str_single(&ptr, ':') == 0) {
                    curlx_str_passblanks(&ptr);
                    if (ptr != null and ptr.?[0] != 0) {
                        value = ptr;
                        valuelen = std.mem.len(value.?);
                    } else {
                        continue;
                    }
                } else if (curlx_str_single(&ptr, ';') == 0) {
                    curlx_str_passblanks(&ptr);
                    if (ptr == null or ptr.?[0] == 0) {
                        value = "";
                        valuelen = 0;
                    } else {
                        continue;
                    }
                } else {
                    continue;
                }
            } else {
                continue;
            }

            curlx_str_trimblanks(&name);
            if (name.len == 0)
                continue;

            const httpreq_type = Curl_proxy_get_httpreq(data);
            if (Curl_proxy_get_http_host(data) != null and
                curlx_str_casecompare(&name, "Host") != 0)
            {
                // skip duplicate Host
            } else if (httpreq_type == HTTPREQ_POST_FORM and
                curlx_str_casecompare(&name, "Content-Type") != 0)
            {
                // skip
            } else if (httpreq_type == HTTPREQ_POST_MIME and
                curlx_str_casecompare(&name, "Content-Type") != 0)
            {
                // skip
            } else if (Curl_proxy_get_authneg(data) and
                curlx_str_casecompare(&name, "Content-Length") != 0)
            {
                // skip
            } else if (httpversion >= 20 and
                curlx_str_casecompare(&name, "Transfer-Encoding") != 0)
            {
                // skip
            } else if ((curlx_str_casecompare(&name, "Authorization") != 0 or
                curlx_str_casecompare(&name, "Cookie") != 0) and
                !Curl_proxy_auth_allowed_to_host(data))
            {
                // skip
            } else {
                const result = io_buffers.Curl_dynhds_add(
                    hds,
                    name.str.?,
                    name.len,
                    value.?,
                    valuelen,
                );
                if (result != CURLE_OK)
                    return result;
            }
        }
    }

    return CURLE_OK;
}

pub const cf_proxy_ctx = extern struct {
    peer: ?*Curl_peer,
    tunnel_peer: ?*Curl_peer,
    proxytype: u8,
    tunnel_transport: u8,
    flags: u8,
    _pad: [5]u8 = .{ 0, 0, 0, 0, 0 },

    pub inline fn isSubFilterInstalled(self: *const cf_proxy_ctx) bool {
        return (self.flags & 0x01) != 0;
    }

    pub inline fn setSubFilterInstalled(self: *cf_proxy_ctx, val: bool) void {
        if (val) {
            self.flags |= 0x01;
        } else {
            self.flags &= ~@as(u8, 0x01);
        }
    }
};

fn proxy_http_ver_major(ver: proxy_http_ver) c_int {
    return switch (ver) {
        PROXY_HTTP_V1 => 11,
        PROXY_HTTP_V2 => 20,
        PROXY_HTTP_V3 => 30,
        else => 0,
    };
}

fn http_proxy_create_CONNECT(
    preq: *?*httpreq,
    cf: *Curl_cfilter,
    data: *Curl_easy,
    peer: *Curl_peer,
    dest: *Curl_peer,
    ver: proxy_http_ver,
) CURLcode {
    _ = peer;
    const httpversion = proxy_http_ver_major(ver);
    var result: CURLcode = CURLE_OK;
    var req: ?*httpreq = null;

    const is_ipv6 = peerIsIpv6(dest);
    const authority = curl_maprintf(
        "%s%s%s:%u",
        @as([*:0]const u8, if (is_ipv6) "[" else ""),
        dest.hostname,
        @as([*:0]const u8, if (is_ipv6) "]" else ""),
        @as(c_uint, dest.port),
    ) orelse {
        preq.* = null;
        return CURLE_OUT_OF_MEMORY;
    };
    defer mem.free(authority);

    const out_cleanup = struct {
        fn clean(r: *?*httpreq, res: CURLcode, pr: *?*httpreq) void {
            if (res != CURLE_OK) {
                if (r.*) |req_ptr| {
                    Curl_http_req_free(req_ptr);
                    r.* = null;
                }
            }
            pr.* = r.*;
        }
    }.clean;
    defer out_cleanup(&req, result, preq);

    result = Curl_http_req_make(
        &req,
        "CONNECT",
        "CONNECT".len,
        null,
        0,
        authority,
        std.mem.len(authority),
        null,
        0,
    );
    if (result != CURLE_OK)
        return result;

    const req_ptr = req.?;
    const method_cstr: [*:0]const u8 = @ptrCast(&req_ptr.method[0]);
    result = Curl_http_output_auth(
        data,
        cf.conn,
        method_cstr,
        HTTPREQ_GET,
        req_ptr.authority,
        null,
        true,
    );
    if (result != CURLE_OK)
        return result;

    if (ver == PROXY_HTTP_V1 and
        Curl_checkProxyheaders(data, cf.conn, "Host", "Host".len) == null)
    {
        result = io_buffers.Curl_dynhds_cadd(&req_ptr.headers, "Host", authority);
        if (result != CURLE_OK)
            return result;
    }

    if (Curl_proxy_get_hd_proxy_auth(data)) |hd_proxy_auth| {
        result = io_buffers.Curl_dynhds_h1_cadd_line(&req_ptr.headers, hd_proxy_auth);
        if (result != CURLE_OK)
            return result;
    }

    const ua = Curl_proxy_str_useragent(data);
    if (Curl_checkProxyheaders(data, cf.conn, "User-Agent", "User-Agent".len) == null and
        ua != null and ua.?[0] != 0)
    {
        result = io_buffers.Curl_dynhds_cadd(&req_ptr.headers, "User-Agent", ua.?);
        if (result != CURLE_OK)
            return result;
    }

    if (ver == PROXY_HTTP_V1 and
        Curl_checkProxyheaders(data, cf.conn, "Proxy-Connection", "Proxy-Connection".len) == null)
    {
        result = io_buffers.Curl_dynhds_cadd(&req_ptr.headers, "Proxy-Connection", "Keep-Alive");
        if (result != CURLE_OK)
            return result;
    }

    result = dynhds_add_custom(data, true, httpversion, false, &req_ptr.headers);
    return result;
}

fn http_proxy_create_CONNECTUDP(
    preq: *?*httpreq,
    cf: *Curl_cfilter,
    data: *Curl_easy,
    peer: *Curl_peer,
    dest: *Curl_peer,
    ver: proxy_http_ver,
) CURLcode {
    var proxy_scheme: [*:0]const u8 = "http";
    const httpversion = proxy_http_ver_major(ver);
    var authority: ?[*:0]u8 = null;
    var path: ?[*:0]u8 = null;
    var encoded_host: ?[*]u8 = null;
    var req: ?*httpreq = null;
    var result: CURLcode = CURLE_OK;

    defer {
        if (result != CURLE_OK) {
            if (req) |r| {
                Curl_http_req_free(r);
                req = null;
            }
        }
        mem.free(authority);
        mem.free(path);
        mem.free(encoded_host);
        preq.* = req;
    }

    const http_proxy = Curl_proxy_conn_get_http_proxy(cf.conn.?);
    if (http_proxy.proxytype == CURLPROXY_HTTPS or
        http_proxy.proxytype == CURLPROXY_HTTPS2 or
        http_proxy.proxytype == CURLPROXY_HTTPS3)
    {
        proxy_scheme = "https";
    }

    const peer_ipv6 = peerIsIpv6(peer);
    authority = curl_maprintf(
        "%s%s%s:%d",
        @as([*:0]const u8, if (peer_ipv6) "[" else ""),
        peer.hostname,
        @as([*:0]const u8, if (peer_ipv6) "]" else ""),
        @as(c_int, peer.port),
    );
    if (authority == null) {
        result = CURLE_OUT_OF_MEMORY;
        return result;
    }

    if (peerIsIpv6(dest)) {
        const s = dest.hostname;
        const hlen = std.mem.len(s);
        const enc_raw = mem.malloc(hlen * 3 + 1) orelse {
            result = CURLE_OUT_OF_MEMORY;
            return result;
        };
        encoded_host = @ptrCast(enc_raw);
        var d: [*]u8 = encoded_host.?;
        var idx: usize = 0;
        while (s[idx] != 0) : (idx += 1) {
            if (s[idx] == ':') {
                d[0] = '%';
                d[1] = '3';
                d[2] = 'A';
                d += 3;
            } else {
                d[0] = s[idx];
                d += 1;
            }
        }
        d[0] = 0;
        const enc_cstr: [*:0]const u8 = @ptrCast(encoded_host.?);
        path = curl_maprintf("/.well-known/masque/udp/%s/%u/", enc_cstr, @as(c_uint, dest.port));
    } else {
        path = curl_maprintf("/.well-known/masque/udp/%s/%u/", dest.hostname, @as(c_uint, dest.port));
    }

    if (path == null) {
        result = CURLE_OUT_OF_MEMORY;
        return result;
    }

    if (ver == PROXY_HTTP_V1) {
        result = Curl_http_req_make(
            &req,
            "GET",
            "GET".len,
            proxy_scheme,
            std.mem.len(proxy_scheme),
            authority.?,
            std.mem.len(authority.?),
            path.?,
            std.mem.len(path.?),
        );
        if (result != CURLE_OK)
            return result;
    } else if (ver == PROXY_HTTP_V2 or ver == PROXY_HTTP_V3) {
        result = Curl_http_req_make(
            &req,
            "CONNECT",
            "CONNECT".len,
            proxy_scheme,
            std.mem.len(proxy_scheme),
            authority.?,
            std.mem.len(authority.?),
            path.?,
            std.mem.len(path.?),
        );
        if (result != CURLE_OK)
            return result;
    } else {
        result = CURLE_FAILED_INIT;
        return result;
    }

    const req_ptr = req.?;
    const method_cstr: [*:0]const u8 = @ptrCast(&req_ptr.method[0]);
    result = Curl_http_output_auth(
        data,
        cf.conn,
        method_cstr,
        HTTPREQ_GET,
        req_ptr.authority,
        null,
        true,
    );
    if (result != CURLE_OK)
        return result;

    if (ver == PROXY_HTTP_V1 and
        Curl_checkProxyheaders(data, cf.conn, "Host", "Host".len) == null)
    {
        result = io_buffers.Curl_dynhds_cadd(&req_ptr.headers, "Host", authority.?);
        if (result != CURLE_OK)
            return result;
    }

    if (Curl_proxy_get_hd_proxy_auth(data)) |hd_proxy_auth| {
        result = io_buffers.Curl_dynhds_h1_cadd_line(&req_ptr.headers, hd_proxy_auth);
        if (result != CURLE_OK)
            return result;
    }

    const ua = Curl_proxy_str_useragent(data);
    if (ver == PROXY_HTTP_V1 and
        Curl_checkProxyheaders(data, cf.conn, "User-Agent", "User-Agent".len) == null and
        ua != null and ua.?[0] != 0)
    {
        result = io_buffers.Curl_dynhds_cadd(&req_ptr.headers, "User-Agent", ua.?);
        if (result != CURLE_OK)
            return result;
    }

    if (ver == PROXY_HTTP_V1 and
        Curl_checkProxyheaders(data, cf.conn, "Proxy-Connection", "Proxy-Connection".len) == null)
    {
        result = io_buffers.Curl_dynhds_cadd(&req_ptr.headers, "Proxy-Connection", "Keep-Alive");
        if (result != CURLE_OK)
            return result;
    }

    if (ver == PROXY_HTTP_V1) {
        result = io_buffers.Curl_dynhds_cadd(&req_ptr.headers, "Connection", "Upgrade");
        if (result != CURLE_OK)
            return result;
        result = io_buffers.Curl_dynhds_cadd(&req_ptr.headers, "Upgrade", "connect-udp");
        if (result != CURLE_OK)
            return result;
        result = io_buffers.Curl_dynhds_cadd(&req_ptr.headers, "Capsule-Protocol", "?1");
        if (result != CURLE_OK)
            return result;
    } else {
        result = io_buffers.Curl_dynhds_cadd(&req_ptr.headers, ":Protocol", "connect-udp");
        if (result != CURLE_OK)
            return result;
        if (ver >= PROXY_HTTP_V2) {
            result = io_buffers.Curl_dynhds_cadd(&req_ptr.headers, "Capsule-Protocol", "?1");
            if (result != CURLE_OK)
                return result;
        }
    }

    result = dynhds_add_custom(data, true, httpversion, true, &req_ptr.headers);
    return result;
}

pub export fn Curl_http_proxy_create_tunnel_request(
    preq: *?*httpreq,
    cf: *Curl_cfilter,
    data: *Curl_easy,
    peer: *Curl_peer,
    dest: *Curl_peer,
    ver: proxy_http_ver,
    udp_tunnel: bool,
) callconv(.c) CURLcode {
    const result = if (udp_tunnel)
        http_proxy_create_CONNECTUDP(preq, cf, data, peer, dest, ver)
    else
        http_proxy_create_CONNECT(preq, cf, data, peer, dest, ver);
    if (result != CURLE_OK)
        return result;

    const ver_str: [*:0]const u8 = if (ver == PROXY_HTTP_V2)
        "HTTP/2"
    else if (ver == PROXY_HTTP_V3)
        "HTTP/3"
    else
        "HTTP";
    const udp_str: [*:0]const u8 = if (udp_tunnel) "UDP " else "";
    const user_host: [*:0]const u8 = @ptrCast(&dest.user_hostname[0]);
    Curl_infof(
        data,
        "Establishing %s proxy %stunnel to %s:%u",
        ver_str,
        udp_str,
        user_host,
        @as(c_uint, dest.port),
    );
    return CURLE_OK;
}

pub export fn Curl_http_proxy_inspect_tunnel_response(
    cf: *Curl_cfilter,
    data: *Curl_easy,
    resp: *http_resp,
    udp_tunnel: bool,
    presult: *proxy_inspect_result,
) callconv(.c) CURLcode {
    const header_count = io_buffers.Curl_dynhds_count(&resp.headers);
    Curl_infof(
        data,
        "CONNECT%s Response Status %d",
        @as([*:0]const u8, if (udp_tunnel) "-UDP" else ""),
        resp.status,
    );
    Curl_infof(data, "Response Headers (%zu total):", header_count);
    var i: usize = 0;
    while (i < header_count) : (i += 1) {
        if (io_buffers.Curl_dynhds_getn(&resp.headers, i)) |entry| {
            Curl_infof(data, "  %s: %s", entry.name, entry.value);
        }
    }

    var auth_reply: ?*dynhds_entry = null;
    if (resp.status == 407) {
        auth_reply = io_buffers.Curl_dynhds_cget(&resp.headers, "Proxy-Authenticate");
    }

    if (auth_reply) |ar| {
        Curl_trc_cf_infof(
            data,
            cf,
            "[0] CONNECT%s: fwd auth header '%s'",
            @as([*:0]const u8, if (udp_tunnel) "-UDP" else ""),
            ar.value,
        );
        const result = Curl_http_input_auth(data, resp.status == 407, ar.value);
        if (result != CURLE_OK)
            return result;
        if (Curl_proxy_clear_newurl(data)) {
            presult.* = PROXY_INSPECT_AUTH_RETRY;
            return CURLE_OK;
        }
    }

    if (udp_tunnel) {
        if (@divTrunc(resp.status, 100) == 2) {
            if (io_buffers.Curl_dynhds_cget(&resp.headers, "capsule-protocol")) |cp| {
                if (cp.value[0] == '?' and cp.value[1] == '1' and cp.value[2] == 0) {
                    Curl_infof(data, "CONNECT-UDP tunnel established, response %d", resp.status);
                    presult.* = PROXY_INSPECT_OK;
                    return CURLE_OK;
                }
                Curl_failf(
                    data,
                    "Failed to establish CONNECT-UDP tunnel, response %d, unsupported capsule-protocol value '%s'",
                    resp.status,
                    cp.value,
                );
                presult.* = PROXY_INSPECT_FAILED;
                return CURLE_COULDNT_CONNECT;
            } else {
                Curl_infof(
                    data,
                    "CONNECT-UDP tunnel established, response %d but no capsule-protocol header found",
                    resp.status,
                );
                presult.* = PROXY_INSPECT_OK;
                return CURLE_OK;
            }
        } else {
            Curl_failf(data, "Failed to establish CONNECT-UDP tunnel, response %d", resp.status);
            presult.* = PROXY_INSPECT_FAILED;
            return CURLE_COULDNT_CONNECT;
        }
    }

    if (@divTrunc(resp.status, 100) == 2) {
        Curl_infof(data, "CONNECT tunnel established, response %d", resp.status);
        presult.* = PROXY_INSPECT_OK;
        return CURLE_OK;
    }

    presult.* = PROXY_INSPECT_FAILED;
    return CURLE_COULDNT_CONNECT;
}

fn http_proxy_cf_connect(cf: *Curl_cfilter, data: ?*Curl_easy, done: *bool) callconv(.c) CURLcode {
    const ctx: *cf_proxy_ctx = @ptrCast(@alignCast(cf.ctx.?));
    var result: CURLcode = CURLE_OK;
    const udp_tunnel = ctx.tunnel_transport == TRNSPRT_UDP or ctx.tunnel_transport == TRNSPRT_QUIC;

    if (cf.isConnected()) {
        done.* = true;
        return CURLE_OK;
    }

    Curl_trc_cf_infof(
        data,
        cf,
        "CONNECT%s",
        @as([*:0]const u8, if (udp_tunnel) "-UDP" else ""),
    );

    while (true) {
        if (cf.next) |next| {
            result = next.cft.do_connect(next, data, done);
            if (result != CURLE_OK or !done.*)
                return result;
        }

        done.* = false;
        if (!ctx.isSubFilterInstalled()) {
            var alpn: ?[*:0]const u8 = null;
            if (cf.next) |next| {
                alpn = Curl_conn_cf_get_alpn_negotiated(next, data);
            }

            if (alpn) |a| {
                Curl_infof(
                    data,
                    "CONNECT%s: '%s' negotiated",
                    @as([*:0]const u8, if (udp_tunnel) "-UDP" else ""),
                    a,
                );
            } else {
                Curl_infof(
                    data,
                    "CONNECT%s: no ALPN negotiated",
                    @as([*:0]const u8, if (udp_tunnel) "-UDP" else ""),
                );
                alpn = switch (ctx.proxytype) {
                    CURLPROXY_HTTP_1_0 => "http/1.0",
                    CURLPROXY_HTTPS2 => "h2",
                    CURLPROXY_HTTPS3 => "h3",
                    else => "http/1.1",
                };
            }

            const alpn_str = alpn.?;
            if (std.mem.orderZ(u8, alpn_str, "http/1.0") == .eq) {
                Curl_trc_cf_infof(data, cf, "installing subfilter for HTTP/1.0");
                result = Curl_cf_h1_proxy_insert_after(
                    cf,
                    data,
                    ctx.peer,
                    ctx.tunnel_peer,
                    10,
                    udp_tunnel,
                );
                if (result != CURLE_OK)
                    return result;
            } else if (std.mem.orderZ(u8, alpn_str, "http/1.1") == .eq) {
                const httpversion: c_int = if (ctx.proxytype == CURLPROXY_HTTP_1_0) 10 else 11;
                Curl_trc_cf_infof(data, cf, "installing subfilter for HTTP/1.%d", @rem(httpversion, 10));
                result = Curl_cf_h1_proxy_insert_after(
                    cf,
                    data,
                    ctx.peer,
                    ctx.tunnel_peer,
                    httpversion,
                    udp_tunnel,
                );
                if (result != CURLE_OK)
                    return result;
            } else if (backend_options.nghttp2 and std.mem.orderZ(u8, alpn_str, "h2") == .eq) {
                Curl_trc_cf_infof(data, cf, "installing subfilter for HTTP/2");
                result = Curl_cf_h2_proxy_insert_after(
                    cf,
                    data,
                    ctx.peer.?,
                    ctx.tunnel_peer.?,
                    udp_tunnel,
                );
                if (result != CURLE_OK)
                    return result;
            } else if (use_proxy_http3 and std.mem.orderZ(u8, alpn_str, "h3") == .eq) {
                Curl_trc_cf_infof(data, cf, "installing subfilter for HTTP/3");
                result = Curl_cf_h3_proxy_insert_after(
                    cf,
                    data,
                    ctx.peer,
                    ctx.peer,
                    ctx.tunnel_peer,
                    ctx.tunnel_transport,
                );
                if (result != CURLE_OK)
                    return result;
            } else {
                Curl_failf(
                    data,
                    "CONNECT%s: negotiated ALPN '%s' not supported",
                    @as([*:0]const u8, if (udp_tunnel) "-UDP" else ""),
                    alpn_str,
                );
                return CURLE_COULDNT_CONNECT;
            }

            ctx.setSubFilterInstalled(true);
            continue;
        } else {
            result = CURLE_OK;
            break;
        }
    }

    if (result == CURLE_OK) {
        cf.setConnected(true);
        done.* = true;
    }
    return result;
}

fn cf_http_proxy_query(
    cf: *Curl_cfilter,
    data: ?*Curl_easy,
    query: c_int,
    pres1: ?*c_int,
    pres2: ?*anyopaque,
) callconv(.c) CURLcode {
    const ctx: *cf_proxy_ctx = @ptrCast(@alignCast(cf.ctx.?));
    switch (query) {
        CF_QUERY_HOST_PORT => {
            if (pres1) |p1| p1.* = @intCast(ctx.tunnel_peer.?.port);
            if (pres2) |p2| {
                const host_out: *?[*:0]const u8 = @ptrCast(@alignCast(p2));
                host_out.* = ctx.tunnel_peer.?.hostname;
            }
            return CURLE_OK;
        },
        CF_QUERY_ALPN_NEGOTIATED => {
            if (pres2) |p2| {
                const palpn: *?[*:0]const u8 = @ptrCast(@alignCast(p2));
                palpn.* = null;
            }
            return CURLE_OK;
        },
        else => {},
    }
    if (cf.next) |next| {
        return next.cft.query(next, data, query, pres1, pres2);
    }
    return CURLE_UNKNOWN_OPTION;
}

fn cf_https_proxy_ctx_free(ctx_opt: ?*cf_proxy_ctx) void {
    if (ctx_opt) |ctx| {
        altsvc_hsts_peer.Curl_peer_unlink(&ctx.peer);
        altsvc_hsts_peer.Curl_peer_unlink(&ctx.tunnel_peer);
        mem.freeSized(ctx, @sizeOf(cf_proxy_ctx));
    }
}

fn http_proxy_cf_destroy(cf: *Curl_cfilter, data: ?*Curl_easy) callconv(.c) void {
    if (cf.ctx) |raw| {
        const ctx: *cf_proxy_ctx = @ptrCast(@alignCast(raw));
        Curl_trc_cf_infof(data, cf, "destroy");
        cf_https_proxy_ctx_free(ctx);
    }
}

pub export var Curl_cft_http_proxy: Curl_cftype = .{
    .name = "HTTP-PROXY",
    .flags = CF_TYPE_IP_CONNECT | CF_TYPE_PROXY | CF_TYPE_SETUP,
    .log_level = 0,
    .destroy = http_proxy_cf_destroy,
    .do_connect = http_proxy_cf_connect,
    .do_shutdown = Curl_cf_def_shutdown,
    .adjust_pollset = Curl_cf_def_adjust_pollset,
    .has_data_pending = Curl_cf_def_data_pending,
    .do_send = Curl_cf_def_send,
    .do_recv = Curl_cf_def_recv,
    .cntrl = Curl_cf_def_cntrl,
    .is_alive = Curl_cf_def_conn_is_alive,
    .keep_alive = Curl_cf_def_conn_keep_alive,
    .query = cf_http_proxy_query,
};

pub export fn Curl_cf_http_proxy_insert_after(
    cf_at: *Curl_cfilter,
    data: ?*Curl_easy,
    peer_opt: ?*Curl_peer,
    tunnel_peer_opt: ?*Curl_peer,
    tunnel_transport: u8,
    proxytype: u8,
) callconv(.c) CURLcode {
    _ = data;
    const peer = peer_opt orelse return CURLE_FAILED_INIT;
    const tunnel_peer = tunnel_peer_opt orelse return CURLE_FAILED_INIT;

    const raw_ctx = mem.calloc(1, @sizeOf(cf_proxy_ctx)) orelse return CURLE_OUT_OF_MEMORY;
    var ctx: ?*cf_proxy_ctx = @ptrCast(@alignCast(raw_ctx));
    defer cf_https_proxy_ctx_free(ctx);

    altsvc_hsts_peer.Curl_peer_link(&ctx.?.peer, peer);
    altsvc_hsts_peer.Curl_peer_link(&ctx.?.tunnel_peer, tunnel_peer);
    ctx.?.proxytype = proxytype;
    ctx.?.tunnel_transport = tunnel_transport;

    var cf: ?*Curl_cfilter = null;
    const result = Curl_cf_create(&cf, &Curl_cft_http_proxy, ctx);
    if (result != CURLE_OK)
        return result;
    ctx = null;
    Curl_conn_cf_insert_after(cf_at, cf.?);
    return CURLE_OK;
}

pub export fn Curl_http_proxy_transport(proxytype: u8) callconv(.c) u8 {
    return switch (proxytype) {
        CURLPROXY_HTTPS3 => TRNSPRT_QUIC,
        else => TRNSPRT_TCP,
    };
}

// ============================================================================
// 3. lib/cf-h1-proxy.c — HTTP/1.1 CONNECT tunnel connection filter
// ============================================================================

const H1TunnelStateEnum = enum(c_uint) {
    H1_TUNNEL_INIT = 0,
    H1_TUNNEL_CONNECT = 1,
    H1_TUNNEL_RECEIVE = 2,
    H1_TUNNEL_RESPONSE = 3,
    H1_TUNNEL_ESTABLISHED = 4,
    H1_TUNNEL_FAILED = 5,
};

const KeeponVal = enum(c_uint) {
    KEEPON_DONE = 0,
    KEEPON_CONNECT = 1,
    KEEPON_IGNORE = 2,
};

pub const h1_tunnel_state = extern struct {
    dest: ?*Curl_peer,
    rcvbuf: dynbuf,
    request_data: dynbuf,
    nsent: usize,
    headerlines: usize,
    ch: Curl_chunker,
    httpversion: c_int,
    keepon: KeeponVal,
    cl: i64,
    tunnel_state: H1TunnelStateEnum,
    chunked_encoding: bool,
    close_connection: bool,
    maybe_folded: bool,
    leading_unfold: bool,
    udp_tunnel: bool,
};

pub const cf_h1_proxy_ctx = extern struct {
    peer: ?*Curl_peer,
    ts: ?*h1_tunnel_state,
};

inline fn tunnel_is_established(ts: ?*const h1_tunnel_state) bool {
    const t = ts orelse return false;
    return t.tunnel_state == .H1_TUNNEL_ESTABLISHED;
}

inline fn tunnel_is_failed(ts: ?*const h1_tunnel_state) bool {
    const t = ts orelse return false;
    return t.tunnel_state == .H1_TUNNEL_FAILED;
}

inline fn h1_proxy_is_udp(cf: *const Curl_cfilter) bool {
    const pctx: *const cf_h1_proxy_ctx = @ptrCast(@alignCast(cf.ctx.?));
    if (pctx.ts) |ts| return ts.udp_tunnel;
    return false;
}

fn tunnel_reinit(cf: *Curl_cfilter, data: ?*Curl_easy, ts: *h1_tunnel_state) CURLcode {
    _ = cf;
    _ = data;
    containers.curlx_dyn_reset(&ts.rcvbuf);
    containers.curlx_dyn_reset(&ts.request_data);
    ts.tunnel_state = .H1_TUNNEL_INIT;
    ts.keepon = .KEEPON_CONNECT;
    ts.cl = 0;
    ts.close_connection = false;
    ts.maybe_folded = false;
    ts.leading_unfold = false;
    ts.chunked_encoding = false;
    ts.nsent = 0;
    ts.headerlines = 0;
    return CURLE_OK;
}

fn tunnel_init(cf: *Curl_cfilter, data: ?*Curl_easy, pts: *?*h1_tunnel_state) CURLcode {
    const scheme = Curl_proxy_conn_get_scheme(cf.conn.?);
    if ((scheme.flags & PROTOPT_NOTCPPROXY) != 0) {
        Curl_failf(data, "%s cannot be done over CONNECT", scheme.name);
        return CURLE_UNSUPPORTED_PROTOCOL;
    }

    const raw = mem.calloc(1, @sizeOf(h1_tunnel_state)) orelse return CURLE_OUT_OF_MEMORY;
    const ts: *h1_tunnel_state = @ptrCast(@alignCast(raw));

    Curl_infof(data, "allocate connect buffer");

    containers.curlx_dyn_init(&ts.rcvbuf, DYN_PROXY_CONNECT_HEADERS);
    containers.curlx_dyn_init(&ts.request_data, DYN_HTTP_REQUEST);
    Curl_httpchunk_init(data, &ts.ch, true, true);

    pts.* = ts;
    return tunnel_reinit(cf, data, ts);
}

fn h1_tunnel_go_state(
    cf: *Curl_cfilter,
    ts: *h1_tunnel_state,
    new_state: H1TunnelStateEnum,
    data: ?*Curl_easy,
) void {
    if (ts.tunnel_state == new_state)
        return;

    switch (new_state) {
        .H1_TUNNEL_INIT => {
            Curl_trc_cf_infof(data, cf, "new tunnel state 'init'");
            _ = tunnel_reinit(cf, data, ts);
        },
        .H1_TUNNEL_CONNECT => {
            Curl_trc_cf_infof(data, cf, "new tunnel state 'connect'");
            ts.tunnel_state = .H1_TUNNEL_CONNECT;
            ts.keepon = .KEEPON_CONNECT;
            containers.curlx_dyn_reset(&ts.rcvbuf);
        },
        .H1_TUNNEL_RECEIVE => {
            Curl_trc_cf_infof(data, cf, "new tunnel state 'receive'");
            ts.tunnel_state = .H1_TUNNEL_RECEIVE;
        },
        .H1_TUNNEL_RESPONSE => {
            Curl_trc_cf_infof(data, cf, "new tunnel state 'response'");
            ts.tunnel_state = .H1_TUNNEL_RESPONSE;
        },
        .H1_TUNNEL_ESTABLISHED, .H1_TUNNEL_FAILED => {
            if (new_state == .H1_TUNNEL_ESTABLISHED) {
                Curl_trc_cf_infof(data, cf, "new tunnel state 'established'");
                Curl_infof(
                    data,
                    "CONNECT%s phase completed for HTTP proxy",
                    @as([*:0]const u8, if (h1_proxy_is_udp(cf)) "-UDP" else ""),
                );
                if (data) |d| {
                    Curl_proxy_start_connect_auth(d);
                }
            } else {
                Curl_trc_cf_infof(data, cf, "new tunnel state 'failed'");
            }
            ts.tunnel_state = new_state;
            containers.curlx_dyn_reset(&ts.rcvbuf);
            containers.curlx_dyn_reset(&ts.request_data);
            if (data) |d| {
                Curl_proxy_set_info_httpcode(d, 0);
                Curl_proxy_clear_hd_proxy_auth(d);
            }
        },
    }
}

fn tunnel_free(ts_opt: ?*h1_tunnel_state, data: ?*Curl_easy) void {
    if (ts_opt) |ts| {
        altsvc_hsts_peer.Curl_peer_unlink(&ts.dest);
        containers.curlx_dyn_free(&ts.rcvbuf);
        containers.curlx_dyn_free(&ts.request_data);
        Curl_httpchunk_free(data, &ts.ch);
        mem.freeSized(ts, @sizeOf(h1_tunnel_state));
    }
}

fn cf_tunnel_free(cf_opt: ?*Curl_cfilter, data: ?*Curl_easy) void {
    if (cf_opt) |cf| {
        if (cf.ctx) |raw| {
            const pctx: *cf_h1_proxy_ctx = @ptrCast(@alignCast(raw));
            if (pctx.ts) |ts| {
                h1_tunnel_go_state(cf, ts, .H1_TUNNEL_FAILED, data);
                tunnel_free(ts, data);
                pctx.ts = null;
            }
        }
    }
}

inline fn tunnel_want_send(ts: *const h1_tunnel_state) bool {
    return ts.tunnel_state == .H1_TUNNEL_CONNECT;
}

fn start_CONNECT(cf: *Curl_cfilter, data: *Curl_easy, ts: *h1_tunnel_state) CURLcode {
    const pctx: *cf_h1_proxy_ctx = @ptrCast(@alignCast(cf.ctx.?));
    var req: ?*httpreq = null;
    defer if (req) |r| Curl_http_req_free(r);

    _ = Curl_proxy_clear_newurl(data);

    var result = Curl_http_proxy_create_tunnel_request(
        &req,
        cf,
        data,
        pctx.peer.?,
        ts.dest.?,
        PROXY_HTTP_V1,
        h1_proxy_is_udp(cf),
    );
    if (result == CURLE_OK) {
        containers.curlx_dyn_reset(&ts.request_data);
        ts.nsent = 0;
        ts.headerlines = 0;
        const http_minor = @rem(ts.httpversion, 10);

        result = http1_options.Curl_h1_req_write_head(@ptrCast(req.?), http_minor, &ts.request_data);
        if (result == CURLE_OK) {
            result = Curl_creader_set_null(data);
        }
    }

    if (result != CURLE_OK) {
        Curl_failf(data, "Failed sending CONNECT to proxy");
    }
    return result;
}

fn send_CONNECT(
    cf: *Curl_cfilter,
    data: *Curl_easy,
    ts: *h1_tunnel_state,
    done: *bool,
) CURLcode {
    const buf = containers.curlx_dyn_uptr(&ts.request_data);
    const request_len = containers.curlx_dyn_len(&ts.request_data);
    var blen = request_len;
    var result: CURLcode = CURLE_OK;
    var nwritten: usize = 0;

    if (blen > ts.nsent) {
        blen -= ts.nsent;
        const send_ptr = buf.? + ts.nsent;
        const next = cf.next.?;
        result = next.cft.do_send(next, data, send_ptr, blen, false, &nwritten);
        if (result != CURLE_OK) {
            if (result == CURLE_AGAIN)
                result = CURLE_OK;
        } else {
            ts.nsent += nwritten;
            Curl_debug(data, CURLINFO_HEADER_OUT, send_ptr, nwritten);
        }
    }

    if (result != CURLE_OK) {
        Curl_failf(data, "Failed sending CONNECT to proxy");
    }
    done.* = (result == CURLE_OK) and (ts.nsent >= request_len);
    return result;
}

fn on_resp_status(
    cf: *Curl_cfilter,
    data: *Curl_easy,
    ts: *h1_tunnel_state,
    header: [*:0]const u8,
) CURLcode {
    _ = ts;
    if (std.mem.eql(u8, header[0..7], "HTTP/1.") and
        (header[7] == '0' or header[7] == '1') and
        header[8] == ' ' and
        isDigit(header[9]) and isDigit(header[10]) and isDigit(header[11]) and
        !isDigit(header[12]))
    {
        const code: c_int = (@as(c_int, header[9] - '0') * 100) +
            (@as(c_int, header[10] - '0') * 10) +
            @as(c_int, header[11] - '0');
        Curl_proxy_set_proxy_and_req_httpcode(data, code);
        Curl_trc_cf_infof(
            data,
            cf,
            "CONNECT%s HTTP status %d",
            @as([*:0]const u8, if (h1_proxy_is_udp(cf)) "-UDP" else ""),
            code,
        );
        return CURLE_OK;
    }
    Curl_failf(data, "Invalid response header");
    return CURLE_WEIRD_SERVER_REPLY;
}

fn on_resp_header(
    cf: *Curl_cfilter,
    data: *Curl_easy,
    ts: *h1_tunnel_state,
    header: [*:0]const u8,
) CURLcode {
    var result: CURLcode = CURLE_OK;
    const httpcode = Curl_proxy_get_req_httpcode(data);
    const is_udp = h1_proxy_is_udp(cf);

    if (checkprefix("Proxy-authenticate:", header) and httpcode == 407) {
        const auth = Curl_copy_header_value(header) orelse return CURLE_OUT_OF_MEMORY;
        defer mem.free(auth);

        Curl_trc_cf_infof(
            data,
            cf,
            "CONNECT%s: fwd auth header '%s'",
            @as([*:0]const u8, if (is_udp) "-UDP" else ""),
            header,
        );
        result = Curl_http_input_auth(data, true, auth);
        if (result != CURLE_OK)
            return result;
    } else if (checkprefix("Content-Length:", header)) {
        if (httpcode < 300) {
            if (httpcode < 200) {
                Curl_failf(data, "Invalid Content-Length: in %03d response", httpcode);
                return CURLE_WEIRD_SERVER_REPLY;
            }
            Curl_infof(
                data,
                "Ignoring Content-Length in CONNECT%s %03d response",
                @as([*:0]const u8, if (is_udp) "-UDP" else ""),
                httpcode,
            );
        } else {
            var p: ?[*:0]const u8 = header + "Content-Length:".len;
            if (curlx_str_numblanks(&p, &ts.cl) != 0) {
                Curl_failf(data, "Unsupported Content-Length value");
                return CURLE_WEIRD_SERVER_REPLY;
            }
        }
    } else if (Curl_compareheader(
        header,
        "Connection:",
        "Connection:".len,
        "close",
        "close".len,
    )) {
        Curl_trc_cf_infof(
            data,
            cf,
            "CONNECT%s Connection: close",
            @as([*:0]const u8, if (is_udp) "-UDP" else ""),
        );
        ts.close_connection = true;
    } else if (checkprefix("Transfer-Encoding:", header)) {
        if (httpcode < 300) {
            if (httpcode < 200) {
                Curl_failf(data, "Invalid Transfer-Encoding: in %03d response", httpcode);
                return CURLE_WEIRD_SERVER_REPLY;
            }
            Curl_infof(
                data,
                "Ignoring Transfer-Encoding in CONNECT%s %03d response",
                @as([*:0]const u8, if (is_udp) "-UDP" else ""),
                httpcode,
            );
        } else if (Curl_compareheader(
            header,
            "Transfer-Encoding:",
            "Transfer-Encoding:".len,
            "chunked",
            "chunked".len,
        )) {
            Curl_trc_cf_infof(
                data,
                cf,
                "CONNECT%s response chunked",
                @as([*:0]const u8, if (is_udp) "-UDP" else ""),
            );
            ts.chunked_encoding = true;
            Curl_httpchunk_reset(data, &ts.ch, true);
        }
    } else if (is_udp and checkprefix("Capsule-protocol:", header)) {
        if (Curl_compareheader(
            header,
            "Capsule-protocol:",
            "Capsule-protocol:".len,
            "?1",
            "?1".len,
        )) {
            Curl_trc_cf_infof(data, cf, "CONNECT-UDP Response --> Capsule-protocol: ?1");
        }
    } else if (Curl_compareheader(
        header,
        "Proxy-Connection:",
        "Proxy-Connection:".len,
        "close",
        "close".len,
    )) {
        Curl_trc_cf_infof(
            data,
            cf,
            "CONNECT%s Proxy-Connection: close",
            @as([*:0]const u8, if (is_udp) "-UDP" else ""),
        );
        ts.close_connection = true;
    }
    return result;
}

fn single_header(
    cf: *Curl_cfilter,
    data: *Curl_easy,
    ts: *h1_tunnel_state,
) CURLcode {
    var result: CURLcode = CURLE_OK;
    const linep = containers.curlx_dyn_ptr(&ts.rcvbuf).?;
    const line_len = containers.curlx_dyn_len(&ts.rcvbuf);
    const httpcode = Curl_proxy_get_req_httpcode(data);
    ts.headerlines += 1;

    Curl_debug(data, CURLINFO_HEADER_IN, linep, line_len);

    result = Curl_verify_header(data, linep, line_len);
    if (result != CURLE_OK)
        return result;

    const writetype: c_int = CLIENTWRITE_HEADER | CLIENTWRITE_CONNECT |
        (if (ts.headerlines == 1) CLIENTWRITE_STATUS else 0);
    result = Curl_client_write(data, writetype, linep, line_len);
    if (result != CURLE_OK)
        return result;

    result = Curl_bump_headersize(data, line_len, true);
    if (result != CURLE_OK)
        return result;

    if (isNewline(linep[0])) {
        if (ts.headerlines == 1) {
            ts.keepon = .KEEPON_DONE;
            result = CURLE_WEIRD_SERVER_REPLY;
        } else if (httpcode == 407 and !Curl_proxy_get_authproblem(data)) {
            ts.keepon = .KEEPON_IGNORE;
            if (ts.cl != 0) {
                Curl_infof(data, "Ignore %lld bytes of response-body", @as(c_longlong, ts.cl));
            } else if (ts.chunked_encoding) {
                Curl_infof(data, "Ignore chunked response-body");
            } else {
                Curl_trc_cf_infof(data, cf, "CONNECT: no content-length or chunked");
                ts.keepon = .KEEPON_DONE;
            }
        } else {
            ts.keepon = .KEEPON_DONE;
        }
        return result;
    }

    if (ts.headerlines == 1) {
        result = on_resp_status(cf, data, ts, linep);
    } else {
        result = on_resp_header(cf, data, ts, linep);
    }
    if (result != CURLE_OK)
        return result;

    containers.curlx_dyn_reset(&ts.rcvbuf);
    return result;
}

fn recv_CONNECT_resp(
    cf: *Curl_cfilter,
    data: *Curl_easy,
    ts: *h1_tunnel_state,
    done: *bool,
) CURLcode {
    var result: CURLcode = CURLE_OK;
    var select_error = false;
    done.* = false;

    while (ts.keepon != .KEEPON_DONE) {
        var nread: usize = 0;
        var byte: u8 = 0;

        result = Curl_conn_recv(data, cf.sockindex, @ptrCast(&byte), 1, &nread);
        if (result == CURLE_AGAIN)
            return CURLE_OK;

        if (result == CURLE_OK)
            result = Curl_pgrsUpdate(data);

        if (result != CURLE_OK) {
            ts.keepon = .KEEPON_DONE;
            break;
        }

        if (nread == 0) {
            if (ts.maybe_folded) {
                result = single_header(cf, data, ts);
                if (result != CURLE_OK)
                    return result;
                ts.maybe_folded = false;
            }
            if (Curl_proxy_has_avail_auth(data)) {
                ts.close_connection = true;
                Curl_infof(data, "Proxy CONNECT connection closed");
            } else {
                select_error = true;
                Curl_failf(data, "Proxy CONNECT aborted");
            }
            ts.keepon = .KEEPON_DONE;
            break;
        }

        if (ts.keepon == .KEEPON_IGNORE) {
            if (ts.chunked_encoding) {
                var consumed: usize = 0;
                result = Curl_httpchunk_read(data, &ts.ch, @ptrCast(&byte), 1, &consumed);
                if (result != CURLE_OK)
                    return result;
                if (Curl_httpchunk_is_done(data, &ts.ch)) {
                    Curl_infof(data, "chunk reading DONE");
                    ts.keepon = .KEEPON_DONE;
                }
            } else if (ts.cl != 0) {
                ts.cl -= 1;
                if (ts.cl <= 0) {
                    ts.keepon = .KEEPON_DONE;
                    break;
                }
            }
            continue;
        }

        if (ts.maybe_folded) {
            if (isBlank(byte)) {
                Curl_http_to_fold(&ts.rcvbuf);
                ts.leading_unfold = true;
            } else {
                result = single_header(cf, data, ts);
                if (result != CURLE_OK)
                    return result;
            }
            ts.maybe_folded = false;
        }

        if (ts.leading_unfold) {
            if (isBlank(byte))
                continue;
            if (containers.curlx_dyn_addn(&ts.rcvbuf, " ", 1) != CURLE_OK) {
                Curl_failf(data, "CONNECT response too large");
                return CURLE_RECV_ERROR;
            }
            ts.leading_unfold = false;
        }

        if (containers.curlx_dyn_addn(&ts.rcvbuf, @ptrCast(&byte), 1) != CURLE_OK) {
            Curl_failf(data, "CONNECT response too large");
            return CURLE_RECV_ERROR;
        }

        if (byte != 0x0a) {
            continue;
        } else {
            const linep = containers.curlx_dyn_ptr(&ts.rcvbuf);
            const hlen = containers.curlx_dyn_len(&ts.rcvbuf);
            if (hlen != 0 and linep != null and isNewline(linep.?[0])) {
                result = single_header(cf, data, ts);
                if (result != CURLE_OK)
                    return result;
            } else {
                ts.maybe_folded = true;
            }
        }

        if (result != CURLE_OK)
            return result;
    }

    if (select_error)
        result = CURLE_RECV_ERROR;
    done.* = (ts.keepon == .KEEPON_DONE);
    const proxycode = Curl_proxy_get_httpproxycode(data);
    if (result == CURLE_OK and done.* and
        @divTrunc(proxycode, 100) != 2 and
        !(h1_proxy_is_udp(cf) and proxycode == 101))
    {
        result = Curl_http_auth_act(data);
    }
    return result;
}

fn H1_CONNECT(cf: *Curl_cfilter, data: *Curl_easy, ts: *h1_tunnel_state) CURLcode {
    const conn = cf.conn.?;
    var result: CURLcode = CURLE_OK;
    var done = false;

    if (tunnel_is_established(ts))
        return CURLE_OK;
    if (tunnel_is_failed(ts))
        return CURLE_RECV_ERROR;

    while (true) {
        if (Curl_timeleft_ms(data) < 0) {
            Curl_failf(data, "Proxy CONNECT aborted due to timeout");
            result = CURLE_OPERATION_TIMEDOUT;
            break;
        }

        if (ts.tunnel_state == .H1_TUNNEL_INIT) {
            Curl_trc_cf_infof(data, cf, "CONNECT start");
            result = start_CONNECT(cf, data, ts);
            if (result != CURLE_OK)
                break;
            h1_tunnel_go_state(cf, ts, .H1_TUNNEL_CONNECT, data);
        }

        if (ts.tunnel_state == .H1_TUNNEL_CONNECT) {
            Curl_trc_cf_infof(data, cf, "CONNECT send");
            result = send_CONNECT(cf, data, ts, &done);
            if (result != CURLE_OK or !done)
                break;
            h1_tunnel_go_state(cf, ts, .H1_TUNNEL_RECEIVE, data);
        }

        if (ts.tunnel_state == .H1_TUNNEL_RECEIVE) {
            Curl_trc_cf_infof(data, cf, "CONNECT receive");
            result = recv_CONNECT_resp(cf, data, ts, &done);
            if (result != CURLE_OK) {
                Curl_trc_cf_infof(data, cf, "error receiving CONNECT response: %d", @as(c_int, @intCast(result)));
            }
            if (result == CURLE_OK) {
                result = Curl_pgrsUpdate(data);
            }
            if (result != CURLE_OK or !done)
                break;
            h1_tunnel_go_state(cf, ts, .H1_TUNNEL_RESPONSE, data);
        }

        if (ts.tunnel_state == .H1_TUNNEL_RESPONSE) {
            Curl_trc_cf_infof(data, cf, "CONNECT response");
            if (Curl_proxy_get_newurl(data) != null) {
                Curl_proxy_req_soft_reset(data);
                if (ts.close_connection or Curl_proxy_conn_is_closed(conn)) {
                    Curl_trc_cf_infof(data, cf, "CONNECT need to close+open");
                    Curl_infof(data, "Connect me again please");
                    return CURLE_AGAIN;
                } else {
                    h1_tunnel_go_state(cf, ts, .H1_TUNNEL_INIT, data);
                }
            }
        }

        if (Curl_proxy_get_newurl(data) == null)
            break;
    }

    if (result != CURLE_OK) {
        h1_tunnel_go_state(cf, ts, .H1_TUNNEL_FAILED, data);
        return result;
    }

    if (ts.tunnel_state != .H1_TUNNEL_RESPONSE)
        return CURLE_OK;

    const proxycode = Curl_proxy_get_httpproxycode(data);
    const req_httpcode = Curl_proxy_get_req_httpcode(data);
    if (h1_proxy_is_udp(cf)) {
        if (@divTrunc(proxycode, 100) != 2 and proxycode != 101) {
            _ = Curl_proxy_clear_newurl(data);
            h1_tunnel_go_state(cf, ts, .H1_TUNNEL_FAILED, data);
            Curl_failf(data, "CONNECT-UDP tunnel failed, response %d", req_httpcode);
            return CURLE_COULDNT_CONNECT;
        }
    } else {
        if (@divTrunc(proxycode, 100) != 2) {
            _ = Curl_proxy_clear_newurl(data);
            h1_tunnel_go_state(cf, ts, .H1_TUNNEL_FAILED, data);
            Curl_failf(data, "CONNECT tunnel failed, response %d", req_httpcode);
            return CURLE_COULDNT_CONNECT;
        }
    }

    h1_tunnel_go_state(cf, ts, .H1_TUNNEL_ESTABLISHED, data);
    Curl_infof(
        data,
        "CONNECT%s tunnel established, response %d",
        @as([*:0]const u8, if (h1_proxy_is_udp(cf)) "-UDP" else ""),
        proxycode,
    );
    return CURLE_OK;
}

fn cf_h1_proxy_connect(cf: *Curl_cfilter, data_opt: ?*Curl_easy, done: *bool) callconv(.c) CURLcode {
    const pctx: *cf_h1_proxy_ctx = @ptrCast(@alignCast(cf.ctx.?));
    var ts = pctx.ts;

    if (cf.isConnected()) {
        done.* = true;
        return CURLE_OK;
    }

    Curl_trc_cf_infof(data_opt, cf, "connect");
    const next = cf.next.?;
    var result = next.cft.do_connect(next, data_opt, done);
    if (result != CURLE_OK or !done.*)
        return result;

    done.* = false;
    if (ts == null) {
        result = tunnel_init(cf, data_opt, &ts);
        if (result != CURLE_OK)
            return result;
        pctx.ts = ts;
    }

    const data = data_opt.?;
    result = H1_CONNECT(cf, data, ts.?);
    if (result == CURLE_OK) {
        Curl_proxy_clear_hd_proxy_auth(data);
    }

    done.* = (result == CURLE_OK) and tunnel_is_established(pctx.ts);
    if (done.*) {
        cf.setConnected(true);
        Curl_proxy_req_soft_reset(data);
        Curl_client_reset(data);
        Curl_pgrsReset(data);
        cf_tunnel_free(cf, data);
    }
    return result;
}

fn cf_h1_proxy_adjust_pollset(
    cf: *Curl_cfilter,
    data: ?*Curl_easy,
    ps: *easy_pollset,
) callconv(.c) CURLcode {
    const pctx: *cf_h1_proxy_ctx = @ptrCast(@alignCast(cf.ctx.?));
    const ts = pctx.ts;
    var result: CURLcode = CURLE_OK;

    if (!cf.isConnected()) {
        const sock = Curl_conn_cf_get_socket(cf, data);
        if (ts) |t| {
            if (tunnel_want_send(t)) {
                result = Curl_pollset_change(data, ps, sock, CURL_POLL_OUT, CURL_POLL_IN);
            } else {
                result = Curl_pollset_change(data, ps, sock, CURL_POLL_IN, CURL_POLL_OUT);
            }
        } else {
            result = Curl_pollset_change(data, ps, sock, CURL_POLL_OUT, CURL_POLL_IN);
        }
    } else if (cf.next) |next| {
        result = next.cft.adjust_pollset(next, data, ps);
    }
    return result;
}

fn cf_h1_proxy_data_pending(cf: *Curl_cfilter, data: ?*const Curl_easy) callconv(.c) bool {
    if (cf.next) |next| {
        return next.cft.has_data_pending(next, data);
    }
    return false;
}

fn cf_h1_proxy_destroy(cf: *Curl_cfilter, data: ?*Curl_easy) callconv(.c) void {
    Curl_trc_cf_infof(data, cf, "destroy");
    if (cf.ctx) |raw| {
        const pctx: *cf_h1_proxy_ctx = @ptrCast(@alignCast(raw));
        cf_tunnel_free(cf, data);
        altsvc_hsts_peer.Curl_peer_unlink(&pctx.peer);
        mem.freeSized(pctx, @sizeOf(cf_h1_proxy_ctx));
        cf.ctx = null;
    }
}

fn cf_h1_proxy_query(
    cf: *Curl_cfilter,
    data: ?*Curl_easy,
    query: c_int,
    pres1: ?*c_int,
    pres2: ?*anyopaque,
) callconv(.c) CURLcode {
    const pctx: ?*cf_h1_proxy_ctx = if (cf.ctx) |raw| @ptrCast(@alignCast(raw)) else null;
    const ts: ?*h1_tunnel_state = if (pctx) |p| p.ts else null;

    switch (query) {
        CF_QUERY_HOST_PORT => {
            if (ts) |t| {
                if (t.dest) |dest| {
                    if (pres1) |p1| p1.* = @intCast(dest.port);
                    if (pres2) |p2| {
                        const host_out: *?[*:0]const u8 = @ptrCast(@alignCast(p2));
                        host_out.* = dest.hostname;
                    }
                    return CURLE_OK;
                }
            }
        },
        CF_QUERY_ALPN_NEGOTIATED => {
            if (pres2) |p2| {
                const palpn: *?[*:0]const u8 = @ptrCast(@alignCast(p2));
                palpn.* = null;
            }
            return CURLE_OK;
        },
        else => {},
    }
    if (cf.next) |next| {
        return next.cft.query(next, data, query, pres1, pres2);
    }
    return CURLE_UNKNOWN_OPTION;
}

pub export var Curl_cft_h1_proxy: Curl_cftype = .{
    .name = "H1-PROXY",
    .flags = CF_TYPE_IP_CONNECT | CF_TYPE_PROXY,
    .log_level = 0,
    .destroy = cf_h1_proxy_destroy,
    .do_connect = cf_h1_proxy_connect,
    .do_shutdown = Curl_cf_def_shutdown,
    .adjust_pollset = cf_h1_proxy_adjust_pollset,
    .has_data_pending = cf_h1_proxy_data_pending,
    .do_send = Curl_cf_def_send,
    .do_recv = Curl_cf_def_recv,
    .cntrl = Curl_cf_def_cntrl,
    .is_alive = Curl_cf_def_conn_is_alive,
    .keep_alive = Curl_cf_def_conn_keep_alive,
    .query = cf_h1_proxy_query,
};

pub export fn Curl_cf_h1_proxy_insert_after(
    cf_at: *Curl_cfilter,
    data: ?*Curl_easy,
    peer_opt: ?*Curl_peer,
    dest_opt: ?*Curl_peer,
    httpversion: c_int,
    udp_tunnel: bool,
) callconv(.c) CURLcode {
    const dest = dest_opt orelse return CURLE_FAILED_INIT;
    if (httpversion < 10 or httpversion >= 20)
        return CURLE_FAILED_INIT;

    const raw_ts = mem.calloc(1, @sizeOf(h1_tunnel_state)) orelse return CURLE_OUT_OF_MEMORY;
    var ts: ?*h1_tunnel_state = @ptrCast(@alignCast(raw_ts));
    defer tunnel_free(ts, data);

    altsvc_hsts_peer.Curl_peer_link(&ts.?.dest, dest);
    ts.?.udp_tunnel = udp_tunnel;
    ts.?.httpversion = httpversion;
    containers.curlx_dyn_init(&ts.?.rcvbuf, DYN_PROXY_CONNECT_HEADERS);
    containers.curlx_dyn_init(&ts.?.request_data, DYN_HTTP_REQUEST);
    Curl_httpchunk_init(data, &ts.?.ch, true, true);

    const raw_pctx = mem.calloc(1, @sizeOf(cf_h1_proxy_ctx)) orelse return CURLE_OUT_OF_MEMORY;
    const pctx: *cf_h1_proxy_ctx = @ptrCast(@alignCast(raw_pctx));
    altsvc_hsts_peer.Curl_peer_link(&pctx.peer, peer_opt);
    pctx.ts = ts;

    var cf: ?*Curl_cfilter = null;
    const result = Curl_cf_create(&cf, &Curl_cft_h1_proxy, pctx);
    if (result != CURLE_OK) {
        altsvc_hsts_peer.Curl_peer_unlink(&pctx.peer);
        mem.freeSized(pctx, @sizeOf(cf_h1_proxy_ctx));
        return result;
    }
    ts = null;
    Curl_conn_cf_insert_after(cf_at, cf.?);
    return CURLE_OK;
}

// ============================================================================
// 4. lib/content_encoding.c — Content-Encoding & Transfer-Encoding writers
// ============================================================================

const CONTENT_ENCODING_DEFAULT: [*:0]const u8 = "identity";
const DECOMPRESS_BUFFER_SIZE: usize = 16384;
const MAX_ENCODE_STACK: usize = 5;

const CURL_CW_TRANSFER_DECODE: c_uint = 1;
const CURL_CW_CONTENT_DECODE: c_uint = 4;

extern fn Curl_cwriter_def_init(data: ?*Curl_easy, writer: *Curl_cwriter) callconv(.c) CURLcode;
extern fn Curl_cwriter_def_write(data: ?*Curl_easy, writer: *Curl_cwriter, wtype: c_int, buf: [*]const u8, nbytes: usize) callconv(.c) CURLcode;
extern fn Curl_cwriter_def_flush(data: ?*Curl_easy, writer: *Curl_cwriter) callconv(.c) CURLcode;
extern fn Curl_cwriter_def_close(data: ?*Curl_easy, writer: *Curl_cwriter) callconv(.c) void;
extern fn Curl_cwriter_create(
    pwriter: *?*Curl_cwriter,
    data: ?*Curl_easy,
    cwt: *const Curl_cwtype,
    phase: c_uint,
) callconv(.c) CURLcode;
extern fn Curl_cwriter_free(data: ?*Curl_easy, writer: ?*Curl_cwriter) callconv(.c) void;
extern fn Curl_cwriter_count(data: ?*Curl_easy, phase: c_uint) callconv(.c) usize;
extern fn Curl_cwriter_add(data: ?*Curl_easy, writer: *Curl_cwriter) callconv(.c) CURLcode;
extern fn Curl_cwriter_get_by_name(data: ?*Curl_easy, name: [*:0]const u8) callconv(.c) ?*Curl_cwriter;
extern fn Curl_cwriter_get_by_type(data: ?*Curl_easy, cwt: *const Curl_cwtype) callconv(.c) ?*Curl_cwriter;

inline fn Curl_cwriter_write(
    data: ?*Curl_easy,
    writer: ?*Curl_cwriter,
    wtype: c_int,
    buf: [*]const u8,
    nbytes: usize,
) CURLcode {
    const w = writer orelse return CURLE_WRITE_ERROR;
    return w.cwt.do_write(data, w, wtype, buf, nbytes);
}

// --- Zlib (deflate & gzip) ---

const Z_OK: c_int = 0;
const Z_STREAM_END: c_int = 1;
const Z_NEED_DICT: c_int = 2;
const Z_ERRNO: c_int = -1;
const Z_STREAM_ERROR: c_int = -2;
const Z_DATA_ERROR: c_int = -3;
const Z_MEM_ERROR: c_int = -4;
const Z_BUF_ERROR: c_int = -5;
const Z_VERSION_ERROR: c_int = -6;
const Z_BLOCK: c_int = 5;
const MAX_WBITS: c_int = 15;

const z_alloc_func = *const fn (opaque_ptr: ?*anyopaque, items: c_uint, size: c_uint) callconv(.c) ?*anyopaque;
const z_free_func = *const fn (opaque_ptr: ?*anyopaque, address: ?*anyopaque) callconv(.c) void;

pub const z_stream = extern struct {
    next_in: ?[*]const u8 = null,
    avail_in: c_uint = 0,
    total_in: c_ulong = 0,
    next_out: ?[*]u8 = null,
    avail_out: c_uint = 0,
    total_out: c_ulong = 0,
    msg: ?[*:0]const u8 = null,
    state: ?*anyopaque = null,
    zalloc: ?z_alloc_func = null,
    zfree: ?z_free_func = null,
    opaque_ptr: ?*anyopaque = null,
    data_type: c_int = 0,
    adler: c_ulong = 0,
    reserved: c_ulong = 0,
};

const zlibInitState = enum(c_uint) {
    ZLIB_UNINIT = 0,
    ZLIB_INIT = 1,
    ZLIB_INFLATING = 2,
    ZLIB_EXTERNAL_TRAILER = 3,
    ZLIB_INIT_GZIP = 4,
};

pub const zlib_writer = extern struct {
    super: Curl_cwriter,
    zlib_init: zlibInitState,
    buffer: [DECOMPRESS_BUFFER_SIZE]u8,
    trailerlen: c_uint,
    z: z_stream,
};

const zlib_c = struct {
    extern fn zlibVersion() callconv(.c) [*:0]const u8;
    extern fn inflateInit_(strm: *z_stream, version: [*:0]const u8, stream_size: c_int) callconv(.c) c_int;
    extern fn inflateInit2_(strm: *z_stream, windowBits: c_int, version: [*:0]const u8, stream_size: c_int) callconv(.c) c_int;
    extern fn inflate(strm: *z_stream, flush: c_int) callconv(.c) c_int;
    extern fn inflateEnd(strm: *z_stream) callconv(.c) c_int;
    extern fn inflateReset2(strm: *z_stream, windowBits: c_int) callconv(.c) c_int;
};

fn zalloc_cb(opaque_ptr: ?*anyopaque, items: c_uint, size: c_uint) callconv(.c) ?*anyopaque {
    _ = opaque_ptr;
    return mem.calloc(items, size);
}

fn zfree_cb(opaque_ptr: ?*anyopaque, ptr: ?*anyopaque) callconv(.c) void {
    _ = opaque_ptr;
    mem.free(ptr);
}

fn process_zlib_error(data: ?*Curl_easy, z: *z_stream) CURLcode {
    if (z.msg) |msg| {
        Curl_failf(data, "Error while processing content unencoding: %s", msg);
    } else {
        Curl_failf(
            data,
            "Error while processing content unencoding: Unknown failure within decompression software.",
        );
    }
    return CURLE_BAD_CONTENT_ENCODING;
}

fn exit_zlib(
    data: ?*Curl_easy,
    z: *z_stream,
    zlib_init: *zlibInitState,
    result_in: CURLcode,
) CURLcode {
    var result = result_in;
    if (zlib_init.* != .ZLIB_UNINIT) {
        if (zlib_c.inflateEnd(z) != Z_OK and result == CURLE_OK)
            result = process_zlib_error(data, z);
        zlib_init.* = .ZLIB_UNINIT;
    }

    return result;
}

fn process_trailer(data: ?*Curl_easy, zp: *zlib_writer) CURLcode {
    const z = &zp.z;
    var result: CURLcode = CURLE_OK;
    const len: c_uint = @min(z.avail_in, zp.trailerlen);

    zp.trailerlen -= len;
    z.avail_in -= len;
    if (z.next_in) |ni| z.next_in = ni + len;
    if (z.avail_in != 0)
        result = CURLE_WRITE_ERROR;
    if (result != CURLE_OK or zp.trailerlen == 0) {
        result = exit_zlib(data, z, &zp.zlib_init, result);
    } else {
        zp.zlib_init = .ZLIB_EXTERNAL_TRAILER;
    }
    return result;
}

fn inflate_stream(
    data: ?*Curl_easy,
    writer: *Curl_cwriter,
    wtype: c_int,
    started: zlibInitState,
) CURLcode {
    const zp: *zlib_writer = @ptrCast(@alignCast(writer.ctx));
    const z = &zp.z;
    const nread = z.avail_in;
    const orig_in = z.next_in;
    var done = false;
    var result: CURLcode = CURLE_OK;
    var i: c_int = 0;

    if (zp.zlib_init != .ZLIB_INIT and
        zp.zlib_init != .ZLIB_INFLATING and
        zp.zlib_init != .ZLIB_INIT_GZIP)
    {
        return exit_zlib(data, z, &zp.zlib_init, CURLE_WRITE_ERROR);
    }

    while (!done) {
        done = true;

        i += 1;
        if (i > @as(c_int, @intCast((1024 * 1024) / DECOMPRESS_BUFFER_SIZE))) {
            i = 0;
            if (Curl_timeleft_ms(data) < 0) {
                Curl_failf(data, "Operation timed out while decoding payload");
                return exit_zlib(data, z, &zp.zlib_init, CURLE_OPERATION_TIMEDOUT);
            }
        }

        z.next_out = @ptrCast(&zp.buffer[0]);
        z.avail_out = @intCast(DECOMPRESS_BUFFER_SIZE);

        const status = zlib_c.inflate(z, Z_BLOCK);

        if (z.avail_out != DECOMPRESS_BUFFER_SIZE) {
            if (status == Z_OK or status == Z_STREAM_END) {
                zp.zlib_init = started;
                result = Curl_cwriter_write(
                    data,
                    writer.next,
                    wtype,
                    @ptrCast(&zp.buffer[0]),
                    DECOMPRESS_BUFFER_SIZE - z.avail_out,
                );
                if (result != CURLE_OK) {
                    _ = exit_zlib(data, z, &zp.zlib_init, result);
                    break;
                }
            }
        }

        switch (status) {
            Z_OK => {
                done = false;
            },
            Z_BUF_ERROR => {},
            Z_STREAM_END => {
                if (started == .ZLIB_INIT_GZIP and z.avail_in >= 2 and
                    z.next_in != null and z.next_in.?[0] == 0x1f and z.next_in.?[1] == 0x8b)
                {
                    Curl_failf(data, "Multi-member gzip response not supported");
                    result = exit_zlib(data, z, &zp.zlib_init, CURLE_WRITE_ERROR);
                    break;
                }
                result = process_trailer(data, zp);
            },
            Z_DATA_ERROR => {
                if (zp.zlib_init == .ZLIB_INIT) {
                    if (zlib_c.inflateReset2(z, -MAX_WBITS) == Z_OK) {
                        z.next_in = orig_in;
                        z.avail_in = nread;
                        zp.zlib_init = .ZLIB_INFLATING;
                        zp.trailerlen = 4;
                        done = false;
                        continue;
                    }
                    zp.zlib_init = .ZLIB_UNINIT;
                }
                result = exit_zlib(data, z, &zp.zlib_init, process_zlib_error(data, z));
            },
            else => {
                result = exit_zlib(data, z, &zp.zlib_init, process_zlib_error(data, z));
            },
        }
    }

    if (nread != 0 and zp.zlib_init == .ZLIB_INIT)
        zp.zlib_init = started;

    return result;
}

fn deflate_do_init(data: ?*Curl_easy, writer: *Curl_cwriter) callconv(.c) CURLcode {
    const zp: *zlib_writer = @ptrCast(@alignCast(writer.ctx));
    const z = &zp.z;
    z.zalloc = zalloc_cb;
    z.zfree = zfree_cb;

    if (zlib_c.inflateInit_(z, zlib_c.zlibVersion(), @sizeOf(z_stream)) != Z_OK)
        return process_zlib_error(data, z);
    zp.zlib_init = .ZLIB_INIT;
    return CURLE_OK;
}

fn deflate_do_write(
    data: ?*Curl_easy,
    writer: *Curl_cwriter,
    wtype: c_int,
    buf: [*]const u8,
    nbytes: usize,
) callconv(.c) CURLcode {
    const zp: *zlib_writer = @ptrCast(@alignCast(writer.ctx));
    const z = &zp.z;

    if ((wtype & CLIENTWRITE_BODY) == 0 or nbytes == 0)
        return Curl_cwriter_write(data, writer.next, wtype, buf, nbytes);

    z.next_in = buf;
    z.avail_in = @intCast(@min(nbytes, std.math.maxInt(c_uint)));

    if (zp.zlib_init == .ZLIB_EXTERNAL_TRAILER)
        return process_trailer(data, zp);

    return inflate_stream(data, writer, wtype, .ZLIB_INFLATING);
}

fn deflate_do_close(data: ?*Curl_easy, writer: *Curl_cwriter) callconv(.c) void {
    const zp: *zlib_writer = @ptrCast(@alignCast(writer.ctx));
    const z = &zp.z;
    _ = exit_zlib(data, z, &zp.zlib_init, CURLE_OK);
    mem.secureZero(&zp.buffer, DECOMPRESS_BUFFER_SIZE);
    zp.z = .{};
    zp.trailerlen = 0;
}

const deflate_encoding: Curl_cwtype = .{
    .name = "deflate",
    .alias = null,
    .flags = CURL_CW_FLAG_BLOWUP,
    .do_init = deflate_do_init,
    .do_write = deflate_do_write,
    .do_flush = Curl_cwriter_def_flush,
    .do_close = deflate_do_close,
    .cwriter_size = @sizeOf(zlib_writer),
};

fn gzip_do_init(data: ?*Curl_easy, writer: *Curl_cwriter) callconv(.c) CURLcode {
    const zp: *zlib_writer = @ptrCast(@alignCast(writer.ctx));
    const z = &zp.z;

    z.zalloc = zalloc_cb;
    z.zfree = zfree_cb;

    if (zlib_c.inflateInit2_(z, MAX_WBITS + 32, zlib_c.zlibVersion(), @sizeOf(z_stream)) != Z_OK)
        return process_zlib_error(data, z);

    zp.zlib_init = .ZLIB_INIT_GZIP;
    return CURLE_OK;
}

fn gzip_do_write(
    data: ?*Curl_easy,
    writer: *Curl_cwriter,
    wtype: c_int,
    buf: [*]const u8,
    nbytes: usize,
) callconv(.c) CURLcode {
    const zp: *zlib_writer = @ptrCast(@alignCast(writer.ctx));
    const z = &zp.z;

    if ((wtype & CLIENTWRITE_BODY) == 0 or nbytes == 0)
        return Curl_cwriter_write(data, writer.next, wtype, buf, nbytes);

    if (zp.zlib_init == .ZLIB_INIT_GZIP) {
        z.next_in = buf;
        z.avail_in = @intCast(@min(nbytes, std.math.maxInt(c_uint)));
        return inflate_stream(data, writer, wtype, .ZLIB_INIT_GZIP);
    }

    return exit_zlib(data, z, &zp.zlib_init, CURLE_WRITE_ERROR);
}

fn gzip_do_close(data: ?*Curl_easy, writer: *Curl_cwriter) callconv(.c) void {
    const zp: *zlib_writer = @ptrCast(@alignCast(writer.ctx));
    const z = &zp.z;
    _ = exit_zlib(data, z, &zp.zlib_init, CURLE_OK);
    mem.secureZero(&zp.buffer, DECOMPRESS_BUFFER_SIZE);
    zp.z = .{};
    zp.trailerlen = 0;
}

const gzip_encoding: Curl_cwtype = .{
    .name = "gzip",
    .alias = "x-gzip",
    .flags = CURL_CW_FLAG_BLOWUP,
    .do_init = gzip_do_init,
    .do_write = gzip_do_write,
    .do_flush = Curl_cwriter_def_flush,
    .do_close = gzip_do_close,
    .cwriter_size = @sizeOf(zlib_writer),
};

// --- Brotli ---

const BrotliDecoderState = opaque {};
const BrotliDecoderResult = c_int;
const BROTLI_DECODER_RESULT_ERROR: BrotliDecoderResult = 0;
const BROTLI_DECODER_RESULT_SUCCESS: BrotliDecoderResult = 1;
const BROTLI_DECODER_RESULT_NEEDS_MORE_INPUT: BrotliDecoderResult = 2;
const BROTLI_DECODER_RESULT_NEEDS_MORE_OUTPUT: BrotliDecoderResult = 3;
const BrotliDecoderErrorCode = c_int;

extern fn BrotliDecoderCreateInstance(
    alloc_func: ?*const anyopaque,
    free_func: ?*const anyopaque,
    opaque_ptr: ?*anyopaque,
) callconv(.c) ?*BrotliDecoderState;
extern fn BrotliDecoderDestroyInstance(state: *BrotliDecoderState) callconv(.c) void;
extern fn BrotliDecoderDecompressStream(
    state: *BrotliDecoderState,
    available_in: *usize,
    next_in: *?[*]const u8,
    available_out: *usize,
    next_out: *[*]u8,
    total_out: ?*usize,
) callconv(.c) BrotliDecoderResult;
extern fn BrotliDecoderGetErrorCode(state: *const BrotliDecoderState) callconv(.c) BrotliDecoderErrorCode;

pub const brotli_writer = extern struct {
    super: Curl_cwriter,
    br: ?*BrotliDecoderState,
};

fn brotli_map_error(be: BrotliDecoderErrorCode) CURLcode {
    return switch (be) {
        -16...-1, -20...-18 => CURLE_BAD_CONTENT_ENCODING,
        -30...-21 => CURLE_OUT_OF_MEMORY,
        else => CURLE_WRITE_ERROR,
    };
}

fn brotli_do_init(data: ?*Curl_easy, writer: *Curl_cwriter) callconv(.c) CURLcode {
    _ = data;
    const bp: *brotli_writer = @ptrCast(@alignCast(writer.ctx));
    bp.br = BrotliDecoderCreateInstance(null, null, null);
    return if (bp.br != null) CURLE_OK else CURLE_OUT_OF_MEMORY;
}

fn brotli_do_write(
    data: ?*Curl_easy,
    writer: *Curl_cwriter,
    wtype: c_int,
    buf: [*]const u8,
    nbytes: usize,
) callconv(.c) CURLcode {
    const bp: *brotli_writer = @ptrCast(@alignCast(writer.ctx));
    var result: CURLcode = CURLE_OK;

    if ((wtype & CLIENTWRITE_BODY) == 0 or nbytes == 0)
        return Curl_cwriter_write(data, writer.next, wtype, buf, nbytes);

    if (bp.br == null)
        return CURLE_WRITE_ERROR;

    const decomp = mem.malloc(DECOMPRESS_BUFFER_SIZE) orelse return CURLE_OUT_OF_MEMORY;
    defer mem.freeSized(decomp, DECOMPRESS_BUFFER_SIZE);

    var src: ?[*]const u8 = buf;
    var src_len: usize = nbytes;
    var decomp_len: usize = 0;
    var r: BrotliDecoderResult = BROTLI_DECODER_RESULT_NEEDS_MORE_OUTPUT;

    while ((src_len != 0 or r == BROTLI_DECODER_RESULT_NEEDS_MORE_OUTPUT) and result == CURLE_OK) {
        var dst: [*]u8 = decomp;
        var dst_len: usize = DECOMPRESS_BUFFER_SIZE;

        r = BrotliDecoderDecompressStream(bp.br.?, &src_len, &src, &dst_len, &dst, null);
        const used_out = DECOMPRESS_BUFFER_SIZE - dst_len;
        decomp_len += used_out;
        if (decomp_len > 1024 * 1024) {
            if (Curl_timeleft_ms(data) < 0) {
                Curl_failf(data, "Operation timed out while decoding payload");
                result = CURLE_OPERATION_TIMEDOUT;
                break;
            } else {
                decomp_len = 0;
            }
        }
        if (used_out > 0) {
            result = Curl_cwriter_write(data, writer.next, wtype, decomp, used_out);
            if (result != CURLE_OK)
                break;
        }
        switch (r) {
            BROTLI_DECODER_RESULT_SUCCESS => {
                BrotliDecoderDestroyInstance(bp.br.?);
                bp.br = null;
                if (src_len != 0)
                    result = CURLE_WRITE_ERROR;
                break;
            },
            BROTLI_DECODER_RESULT_NEEDS_MORE_OUTPUT,
            BROTLI_DECODER_RESULT_NEEDS_MORE_INPUT,
            => {},
            else => {
                result = brotli_map_error(BrotliDecoderGetErrorCode(bp.br.?));
            },
        }
    }
    return result;
}

fn brotli_do_close(data: ?*Curl_easy, writer: *Curl_cwriter) callconv(.c) void {
    _ = data;
    const bp: *brotli_writer = @ptrCast(@alignCast(writer.ctx));
    if (bp.br) |br| {
        BrotliDecoderDestroyInstance(br);
        bp.br = null;
    }
}

const brotli_encoding: Curl_cwtype = .{
    .name = "br",
    .alias = null,
    .flags = CURL_CW_FLAG_BLOWUP,
    .do_init = brotli_do_init,
    .do_write = brotli_do_write,
    .do_flush = Curl_cwriter_def_flush,
    .do_close = brotli_do_close,
    .cwriter_size = @sizeOf(brotli_writer),
};

// --- Zstd ---

const ZSTD_DStream = opaque {};

pub const ZSTD_inBuffer = extern struct {
    src: ?*const anyopaque,
    size: usize,
    pos: usize,
};

pub const ZSTD_outBuffer = extern struct {
    dst: ?*anyopaque,
    size: usize,
    pos: usize,
};

pub const zstd_writer = extern struct {
    super: Curl_cwriter,
    zds: ?*ZSTD_DStream,
    buffer: [DECOMPRESS_BUFFER_SIZE]u8,
};

const zstd_c = struct {
    extern fn ZSTD_createDStream() callconv(.c) ?*ZSTD_DStream;
    extern fn ZSTD_freeDStream(zds: ?*ZSTD_DStream) callconv(.c) usize;
    extern fn ZSTD_decompressStream(zds: *ZSTD_DStream, output: *ZSTD_outBuffer, input: *ZSTD_inBuffer) callconv(.c) usize;
    extern fn ZSTD_isError(code: usize) callconv(.c) c_uint;
};

fn zstd_do_init(data: ?*Curl_easy, writer: *Curl_cwriter) callconv(.c) CURLcode {
    _ = data;
    const zp: *zstd_writer = @ptrCast(@alignCast(writer.ctx));
    zp.zds = zstd_c.ZSTD_createDStream();
    return if (zp.zds != null) CURLE_OK else CURLE_OUT_OF_MEMORY;
}

fn zstd_do_write(
    data: ?*Curl_easy,
    writer: *Curl_cwriter,
    wtype: c_int,
    buf: [*]const u8,
    nbytes: usize,
) callconv(.c) CURLcode {
    var result: CURLcode = CURLE_OK;
    const zp: *zstd_writer = @ptrCast(@alignCast(writer.ctx));
    var in: ZSTD_inBuffer = undefined;
    var out: ZSTD_outBuffer = undefined;
    var i: c_int = 0;

    if ((wtype & CLIENTWRITE_BODY) == 0 or nbytes == 0)
        return Curl_cwriter_write(data, writer.next, wtype, buf, nbytes);

    in.pos = 0;
    in.src = buf;
    in.size = nbytes;

    while (true) {
        i += 1;
        if (i > @as(c_int, @intCast((1024 * 1024) / DECOMPRESS_BUFFER_SIZE))) {
            i = 0;
            if (Curl_timeleft_ms(data) < 0) {
                Curl_failf(data, "Operation timed out while decoding payload");
                return CURLE_OPERATION_TIMEDOUT;
            }
        }

        out.pos = 0;
        out.dst = @ptrCast(&zp.buffer[0]);
        out.size = DECOMPRESS_BUFFER_SIZE;

        const errorCode = zstd_c.ZSTD_decompressStream(zp.zds.?, &out, &in);
        if (zstd_c.ZSTD_isError(errorCode) != 0)
            return CURLE_BAD_CONTENT_ENCODING;

        if (out.pos > 0) {
            result = Curl_cwriter_write(
                data,
                writer.next,
                wtype,
                @ptrCast(&zp.buffer[0]),
                out.pos,
            );
            if (result != CURLE_OK)
                break;
        }
        if (in.pos == nbytes and out.pos < out.size)
            break;
    }

    return result;
}

fn zstd_do_close(data: ?*Curl_easy, writer: *Curl_cwriter) callconv(.c) void {
    _ = data;
    const zp: *zstd_writer = @ptrCast(@alignCast(writer.ctx));
    if (zp.zds) |zds| {
        _ = zstd_c.ZSTD_freeDStream(zds);
        zp.zds = null;
    }
    mem.secureZero(&zp.buffer, DECOMPRESS_BUFFER_SIZE);
}

const zstd_encoding: Curl_cwtype = .{
    .name = "zstd",
    .alias = null,
    .flags = CURL_CW_FLAG_BLOWUP,
    .do_init = zstd_do_init,
    .do_write = zstd_do_write,
    .do_flush = Curl_cwriter_def_flush,
    .do_close = zstd_do_close,
    .cwriter_size = @sizeOf(zstd_writer),
};

// --- Identity & Error Handlers ---

const identity_encoding: Curl_cwtype = .{
    .name = CONTENT_ENCODING_DEFAULT,
    .alias = "none",
    .flags = 0,
    .do_init = Curl_cwriter_def_init,
    .do_write = Curl_cwriter_def_write,
    .do_flush = Curl_cwriter_def_flush,
    .do_close = Curl_cwriter_def_close,
    .cwriter_size = @sizeOf(Curl_cwriter),
};

const general_unencoders = blk: {
    var list: []const ?*const Curl_cwtype = &.{&identity_encoding};
    if (backend_options.zlib) {
        list = list ++ &[_]?*const Curl_cwtype{ &deflate_encoding, &gzip_encoding };
    }
    if (backend_options.brotli) {
        list = list ++ &[_]?*const Curl_cwtype{&brotli_encoding};
    }
    if (backend_options.zstd) {
        list = list ++ &[_]?*const Curl_cwtype{&zstd_encoding};
    }
    list = list ++ &[_]?*const Curl_cwtype{null};
    break :blk list;
};

const transfer_unencoders = blk: {
    break :blk [_]?*const Curl_cwtype{
        &Curl_httpchunk_unencoder,
        null,
    };
};

pub export fn Curl_get_content_encodings() callconv(.c) ?[*:0]u8 {
    var enc: dynbuf = undefined;
    var result: CURLcode = CURLE_OK;
    containers.curlx_dyn_init(&enc, 255);

    for (general_unencoders) |cep_opt| {
        if (result != CURLE_OK) break;
        const ce = cep_opt orelse break;
        if (primitives.curl_strequal(ce.name, CONTENT_ENCODING_DEFAULT) == 0) {
            if (containers.curlx_dyn_len(&enc) != 0) {
                result = containers.curlx_dyn_addn(&enc, ", ", 2);
            }
            if (result == CURLE_OK) {
                result = containers.curlx_dyn_add(&enc, ce.name);
            }
        }
    }
    if (result == CURLE_OK and containers.curlx_dyn_len(&enc) == 0) {
        result = containers.curlx_dyn_add(&enc, CONTENT_ENCODING_DEFAULT);
    }

    if (result == CURLE_OK)
        return containers.curlx_dyn_ptr(&enc);
    return null;
}

pub export fn Curl_all_content_encodings(buf: [*]u8, blen: usize) callconv(.c) void {
    buf[0] = 0;
    var len: usize = 0;
    for (general_unencoders) |cep_opt| {
        const cep = cep_opt orelse break;
        if (primitives.curl_strequal(cep.name, identity_encoding.name) == 0) {
            len += std.mem.len(cep.name) + 2;
        }
    }

    if (len == 0) {
        if (blen > identity_encoding.name[0.."identity".len].len) {
            @memcpy(buf[0.."identity".len], "identity");
            buf["identity".len] = 0;
        }
    } else if (blen > len) {
        var p: usize = 0;
        for (general_unencoders) |cep_opt| {
            const cep = cep_opt orelse break;
            if (primitives.curl_strequal(cep.name, identity_encoding.name) == 0) {
                const nlen = std.mem.len(cep.name);
                @memcpy(buf[p .. p + nlen], cep.name[0..nlen]);
                p += nlen;
                buf[p] = ',';
                p += 1;
                buf[p] = ' ';
                p += 1;
            }
        }
        buf[p - 2] = 0;
    }
}

fn error_do_init(data: ?*Curl_easy, writer: *Curl_cwriter) callconv(.c) CURLcode {
    _ = data;
    _ = writer;
    return CURLE_OK;
}

fn error_do_write(
    data: ?*Curl_easy,
    writer: *Curl_cwriter,
    wtype: c_int,
    buf: [*]const u8,
    nbytes: usize,
) callconv(.c) CURLcode {
    if ((wtype & CLIENTWRITE_BODY) == 0 or nbytes == 0)
        return Curl_cwriter_write(data, writer.next, wtype, buf, nbytes);
    Curl_failf(data, "Unrecognized content encoding type");
    return CURLE_BAD_CONTENT_ENCODING;
}

fn error_do_close(data: ?*Curl_easy, writer: *Curl_cwriter) callconv(.c) void {
    _ = data;
    _ = writer;
}

const error_writer: Curl_cwtype = .{
    .name = "ce-error",
    .alias = null,
    .flags = 0,
    .do_init = error_do_init,
    .do_write = error_do_write,
    .do_flush = Curl_cwriter_def_flush,
    .do_close = error_do_close,
    .cwriter_size = @sizeOf(Curl_cwriter),
};

fn find_unencode_writer(
    name: [*]const u8,
    len: usize,
    phase: c_uint,
) ?*const Curl_cwtype {
    const name_c: [*:0]const u8 = @ptrCast(name);
    if (phase == CURL_CW_TRANSFER_DECODE) {
        for (transfer_unencoders) |cep_opt| {
            const cep = cep_opt orelse break;
            if ((primitives.curl_strnequal(name_c, cep.name, len) != 0 and cep.name[len] == 0) or
                (cep.alias != null and primitives.curl_strnequal(name_c, cep.alias.?, len) != 0 and cep.alias.?[len] == 0))
            {
                return cep;
            }
        }
    }
    for (general_unencoders) |cep_opt| {
        const cep = cep_opt orelse break;
        if ((primitives.curl_strnequal(name_c, cep.name, len) != 0 and cep.name[len] == 0) or
            (cep.alias != null and primitives.curl_strnequal(name_c, cep.alias.?, len) != 0 and cep.alias.?[len] == 0))
        {
            return cep;
        }
    }
    return null;
}

pub export fn Curl_build_unencoding_stack(
    data: *Curl_easy,
    enclist_in: [*:0]const u8,
    is_transfer_int: c_int,
) callconv(.c) CURLcode {
    const is_transfer = is_transfer_int != 0;
    const phase: c_uint = if (is_transfer) CURL_CW_TRANSFER_DECODE else CURL_CW_CONTENT_DECODE;
    var enclist: [*:0]const u8 = enclist_in;
    var has_chunked = false;

    while (true) {
        while (isBlank(enclist[0]) or enclist[0] == ',') {
            enclist += 1;
        }

        const name: [*]const u8 = enclist;
        var namelen: usize = 0;
        while (enclist[0] != 0 and enclist[0] != ',') : (enclist += 1) {
            if (enclist[0] > ' ') {
                namelen = (@intFromPtr(enclist) - @intFromPtr(name)) + 1;
            }
        }

        if (namelen != 0) {
            const name_c: [*:0]const u8 = @ptrCast(name);
            const is_chunked = is_transfer and (namelen == 7) and
                (primitives.curl_strnequal(name_c, "chunked", 7) != 0);

            if ((is_transfer and !Curl_ce_get_http_transfer_encoding(data) and !is_chunked) or
                (!is_transfer and Curl_ce_get_http_ce_skip(data)))
            {
                const is_identity = (namelen == 8) and
                    (primitives.curl_strnequal(name_c, "identity", 8) != 0);
                if (is_transfer and !Curl_ce_get_http_te_skip(data)) {
                    if (has_chunked) {
                        Curl_failf(
                            data,
                            "A Transfer-Encoding (%.*s) was listed after chunked",
                            @as(c_int, @intCast(namelen)),
                            name_c,
                        );
                    } else if (is_identity) {
                        if (enclist[0] == 0) break;
                        continue;
                    } else {
                        Curl_failf(
                            data,
                            "Unsolicited Transfer-Encoding (%.*s) found",
                            @as(c_int, @intCast(namelen)),
                            name_c,
                        );
                    }
                    return CURLE_BAD_CONTENT_ENCODING;
                }
                return CURLE_OK;
            }

            if (Curl_cwriter_count(data, phase) >= MAX_ENCODE_STACK) {
                Curl_failf(
                    data,
                    "Reject response exceeding limit of %d %s encodings",
                    @as(c_int, MAX_ENCODE_STACK),
                    @as([*:0]const u8, if (is_transfer) "transfer" else "content"),
                );
                return CURLE_BAD_CONTENT_ENCODING;
            }

            var cwt = find_unencode_writer(name, namelen, phase);
            if (is_transfer and !is_chunked and
                Curl_cwriter_get_by_name(data, "chunked") != null)
            {
                Curl_failf(
                    data,
                    "Reject response due to 'chunked' not being the last Transfer-Encoding",
                );
                return CURLE_BAD_CONTENT_ENCODING;
            }

            if (cwt != null and is_chunked and Curl_cwriter_get_by_type(data, cwt.?) != null) {
                // Ignore duplicate chunked decoder
            } else {
                if (cwt == null)
                    cwt = &error_writer;

                var writer: ?*Curl_cwriter = null;
                var result = Curl_cwriter_create(&writer, data, cwt.?, phase);
                if (result != CURLE_OK)
                    return result;

                result = Curl_cwriter_add(data, writer.?);
                if (result != CURLE_OK) {
                    Curl_cwriter_free(data, writer);
                    return result;
                }
            }
            if (is_chunked)
                has_chunked = true;
        }

        if (enclist[0] == 0)
            break;
    }

    return CURLE_OK;
}

// ============================================================================
// Unit Tests
// ============================================================================

test "cidr4_match and cidr6_match (unit1614)" {
    const Check = struct {
        a: [*:0]const u8,
        n: [*:0]const u8,
        bits: c_int,
        match: bool,
    };
    const list4 = [_]Check{
        .{ .a = "192.160.0.1", .n = "192.160.0.1", .bits = 33, .match = false },
        .{ .a = "192.160.0.1", .n = "192.160.0.1", .bits = 32, .match = true },
        .{ .a = "192.160.0.1", .n = "192.160.0.1", .bits = 0, .match = true },
        .{ .a = "192.160.0.1", .n = "192.160.0.1", .bits = 24, .match = true },
        .{ .a = "192.160.0.1", .n = "192.160.0.1", .bits = 26, .match = true },
        .{ .a = "192.160.0.1", .n = "192.160.0.1", .bits = 20, .match = true },
        .{ .a = "192.160.0.1", .n = "192.160.0.1", .bits = 18, .match = true },
        .{ .a = "192.160.0.1", .n = "192.160.0.1", .bits = 12, .match = true },
        .{ .a = "192.160.0.1", .n = "192.160.0.1", .bits = 8, .match = true },
        .{ .a = "192.160.0.1", .n = "10.0.0.1", .bits = 8, .match = false },
        .{ .a = "192.160.0.1", .n = "10.0.0.1", .bits = 32, .match = false },
        .{ .a = "192.160.0.1", .n = "10.0.0.1", .bits = 0, .match = false },
        .{ .a = "192.160.0.1", .n = "0.0.0.0", .bits = 0, .match = true },
        .{ .a = "0.0.0.1", .n = "0.0.0.0", .bits = 0, .match = true },
        .{ .a = "127.0.0.1", .n = "0.0.0.0", .bits = 0, .match = true },
        .{ .a = "0.0.0.1", .n = "0.0.0.0", .bits = -1, .match = false },
        .{ .a = "127.0.0.1", .n = "0.0.0.0", .bits = -1, .match = false },
    };
    for (list4) |tc| {
        try std.testing.expectEqual(tc.match, cidr4_match(tc.a, tc.n, tc.bits));
    }

    const list6 = [_]Check{
        .{ .a = "::1", .n = "::1", .bits = 0, .match = true },
        .{ .a = "::1", .n = "::1", .bits = 128, .match = true },
        .{ .a = "::1", .n = "0:0::1", .bits = 128, .match = true },
        .{ .a = "::1", .n = "0:0::1", .bits = 129, .match = false },
        .{ .a = "fe80::ab47:4396:55c9:8474", .n = "fe80::ab47:4396:55c9:8474", .bits = 64, .match = true },
        .{ .a = "fe80::ab47:4396:55c9:8474", .n = "::", .bits = 0, .match = true },
        .{ .a = "::1", .n = "::", .bits = 0, .match = true },
        .{ .a = "::1", .n = "::", .bits = -1, .match = false },
    };
    for (list6) |tc| {
        try std.testing.expectEqual(tc.match, cidr6_match(tc.a, tc.n, tc.bits));
    }
}

test "proxy_check_noproxy and Curl_check_noproxy (unit1614)" {
    try std.testing.expect(!proxy_check_noproxy(null, "example.com"));
    try std.testing.expect(!proxy_check_noproxy("", "example.com"));
    try std.testing.expect(!proxy_check_noproxy("example.com", null));
    try std.testing.expect(!proxy_check_noproxy("example.com", ""));
    try std.testing.expect(proxy_check_noproxy("example.com", "*"));

    var spacesep: bool = true;
    try std.testing.expect(Curl_check_noproxy("www.example.com", "example.com", &spacesep));
    try std.testing.expect(!spacesep);

    const NoProxy = struct {
        a: [*:0]const u8,
        n: [*:0]const u8,
        match: bool,
    };
    const list = [_]NoProxy{
        .{ .a = "www.example.com", .n = "localhost .example.com .example.de", .match = false },
        .{ .a = "www.example.com", .n = "localhost,.example.com,.example.de", .match = true },
        .{ .a = "www.example.com.", .n = "localhost,.example.com,.example.de", .match = true },
        .{ .a = "example.com", .n = "localhost,.example.com,.example.de", .match = true },
        .{ .a = "example.com.", .n = "localhost,.example.com,.example.de", .match = true },
        .{ .a = "www.example.com", .n = "localhost,.example.com.,.example.de", .match = true },
        .{ .a = "www.example.com", .n = "localhost,www.example.com.,.example.de", .match = true },
        .{ .a = "example.com", .n = "localhost,example.com,.example.de", .match = true },
        .{ .a = "example.com.", .n = "localhost,example.com,.example.de", .match = true },
        .{ .a = "nexample.com", .n = "localhost,example.com,.example.de", .match = false },
        .{ .a = "www.example.com", .n = "localhost,example.com,.example.de", .match = true },
        .{ .a = "127.0.0.1", .n = "127.0.0.1,localhost", .match = true },
        .{ .a = "127.0.0.1", .n = "127.0.0.1,localhost,", .match = true },
        .{ .a = "127.0.0.1", .n = "127.0.0.1/8,localhost,", .match = true },
        .{ .a = "127.0.0.1", .n = "127.0.0.1/28,localhost,", .match = true },
        .{ .a = "127.0.0.1", .n = "127.0.0.1/31,localhost,", .match = true },
        .{ .a = "127.0.0.1", .n = "localhost,127.0.0.1", .match = true },
        .{ .a = "localhost", .n = "localhost,127.0.0.1", .match = true },
        .{ .a = "localhost", .n = "127.0.0.1,localhost", .match = true },
        .{ .a = "foobar", .n = "barfoo", .match = false },
        .{ .a = "foobar", .n = "foobar", .match = true },
        .{ .a = "192.168.0.1", .n = "foobar", .match = false },
        .{ .a = "192.168.0.1", .n = "192.168.0.0/16", .match = true },
        .{ .a = "192.168.0.1", .n = "192.168.0.0/16a", .match = false },
        .{ .a = "192.168.0.1", .n = "192.168.0.0/16 ", .match = true },
        .{ .a = "192.168.0.1", .n = "192.168.0.0/a16", .match = false },
        .{ .a = "192.168.0.1", .n = "192.168.0.0/ 16", .match = false },
        .{ .a = "192.168.0.1", .n = "192.168.0.0/24", .match = true },
        .{ .a = "192.168.0.1", .n = "192.168.0.0/32", .match = false },
        .{ .a = "192.168.0.1", .n = "192.168.0.1/32", .match = true },
        .{ .a = "192.168.0.1", .n = "192.168.0.1/33", .match = false },
        .{ .a = "192.168.0.1", .n = "192.168.0.0", .match = false },
        .{ .a = "192.168.1.1", .n = "192.168.0.0/24", .match = false },
        .{ .a = "192.168.1.1", .n = "192.168.0.0/33", .match = false },
        .{ .a = "192.168.1.1", .n = "foo, bar, 192.168.0.0/24", .match = false },
        .{ .a = "192.168.1.1", .n = "foo, bar, 192.168.0.0/16", .match = true },
        .{ .a = "192.168.1.1", .n = "0.0.0.0/0", .match = true },
        .{ .a = "192.168.1.1", .n = "0.0.0.0", .match = false },
        .{ .a = "::1", .n = "::/0", .match = true },
        .{ .a = "::1", .n = "::", .match = false },
        .{ .a = "::1", .n = "::/128", .match = false },
        .{ .a = "::1", .n = "foo, bar, 192.168.0.0/16", .match = false },
        .{ .a = "::1", .n = "foo, bar, ::1/64", .match = true },
        .{ .a = "::1", .n = "::1/64", .match = true },
        .{ .a = "::1", .n = "::1/96", .match = true },
        .{ .a = "::1", .n = "::1/129", .match = false },
        .{ .a = "::1", .n = "::1/128", .match = true },
        .{ .a = "::1", .n = "::1/127", .match = true },
        .{ .a = "::1", .n = "::1/a127", .match = false },
        .{ .a = "::1", .n = "::1/127a", .match = false },
        .{ .a = "::1", .n = "::1/ 127", .match = false },
        .{ .a = "::1", .n = "::1/127 ", .match = true },
        .{ .a = "2001:db8:8000::1", .n = "2001:db8::/65", .match = false },
        .{ .a = "2001:db8::1", .n = "2001:db8::/65", .match = true },
        .{ .a = "bar", .n = "foo, bar, ::1/64", .match = true },
        .{ .a = "BAr", .n = "foo, bar, ::1/64", .match = true },
        .{ .a = "BAr", .n = "foo,,,,,              bar, ::1/64", .match = true },
        .{ .a = "www.example.com", .n = "foo, .example.com", .match = true },
        .{ .a = "www.example.com", .n = "www2.example.com, .example.net", .match = false },
        .{ .a = "example.com", .n = ".example.com, .example.net", .match = true },
        .{ .a = "nonexample.com", .n = ".example.com, .example.net", .match = false },
    };
    for (list) |tc| {
        try std.testing.expectEqual(tc.match, proxy_check_noproxy(tc.a, tc.n));
    }
}

test "Curl_http_proxy_transport, proxy cftypes, and content encodings" {
    try std.testing.expectEqual(TRNSPRT_QUIC, Curl_http_proxy_transport(CURLPROXY_HTTPS3));
    try std.testing.expectEqual(TRNSPRT_TCP, Curl_http_proxy_transport(CURLPROXY_HTTP));
    try std.testing.expectEqual(TRNSPRT_TCP, Curl_http_proxy_transport(CURLPROXY_HTTPS));

    try std.testing.expectEqualStrings("HTTP-PROXY", std.mem.span(Curl_cft_http_proxy.name));
    try std.testing.expectEqualStrings("H1-PROXY", std.mem.span(Curl_cft_h1_proxy.name));
    try std.testing.expectEqual(CF_TYPE_IP_CONNECT | CF_TYPE_PROXY | CF_TYPE_SETUP, Curl_cft_http_proxy.flags);
    try std.testing.expectEqual(CF_TYPE_IP_CONNECT | CF_TYPE_PROXY, Curl_cft_h1_proxy.flags);

    var buf: [128]u8 = undefined;
    Curl_all_content_encodings(&buf, buf.len);
    const enc_str = std.mem.sliceTo(&buf, 0);

    const dyn_enc = Curl_get_content_encodings();
    try std.testing.expect(dyn_enc != null);
    defer mem.free(dyn_enc);
    try std.testing.expectEqualStrings(enc_str, std.mem.span(dyn_enc.?));

    if (backend_options.zlib) {
        try std.testing.expect(std.mem.indexOf(u8, enc_str, "deflate") != null);
        try std.testing.expect(std.mem.indexOf(u8, enc_str, "gzip") != null);
        try std.testing.expect(find_unencode_writer("gzip", 4, CURL_CW_CONTENT_DECODE) == &gzip_encoding);
        try std.testing.expect(find_unencode_writer("x-gzip", 6, CURL_CW_CONTENT_DECODE) == &gzip_encoding);
        try std.testing.expect(find_unencode_writer("deflate", 7, CURL_CW_CONTENT_DECODE) == &deflate_encoding);
    }
    if (backend_options.brotli) {
        try std.testing.expect(std.mem.indexOf(u8, enc_str, "br") != null);
        try std.testing.expect(find_unencode_writer("br", 2, CURL_CW_CONTENT_DECODE) == &brotli_encoding);

        const Capture = struct {
            var out_buf: [64]u8 = undefined;
            var out_len: usize = 0;

            fn doWrite(
                data: ?*Curl_easy,
                writer: *Curl_cwriter,
                wtype: c_int,
                b: [*]const u8,
                n: usize,
            ) callconv(.c) CURLcode {
                _ = data;
                _ = writer;
                if ((wtype & CLIENTWRITE_BODY) != 0 and n > 0) {
                    @memcpy(out_buf[out_len .. out_len + n], b[0..n]);
                    out_len += n;
                }
                return CURLE_OK;
            }
        };

        const sink_cwt = Curl_cwtype{
            .name = "sink",
            .alias = null,
            .flags = 0,
            .do_init = Curl_cwriter_def_init,
            .do_write = Capture.doWrite,
            .do_flush = Curl_cwriter_def_flush,
            .do_close = Curl_cwriter_def_close,
            .cwriter_size = @sizeOf(Curl_cwriter),
        };
        var sink = Curl_cwriter{
            .cwt = &sink_cwt,
            .next = null,
            .ctx = undefined,
            .phase = CURL_CW_CONTENT_DECODE,
        };
        sink.ctx = @ptrCast(&sink);

        var bw = brotli_writer{
            .super = .{
                .cwt = &brotli_encoding,
                .next = &sink,
                .ctx = undefined,
                .phase = CURL_CW_CONTENT_DECODE,
            },
            .br = null,
        };
        bw.super.ctx = @ptrCast(&bw);

        Capture.out_len = 0;
        try std.testing.expectEqual(CURLE_OK, brotli_do_init(null, &bw.super));
        defer brotli_do_close(null, &bw.super);

        const br_stream = "\xb0\x00\x10hello brotli\x03";
        try std.testing.expectEqual(CURLE_OK, brotli_do_write(null, &bw.super, CLIENTWRITE_BODY, br_stream[0..5].ptr, 5));
        try std.testing.expectEqual(CURLE_OK, brotli_do_write(null, &bw.super, CLIENTWRITE_BODY, br_stream[5..].ptr, br_stream.len - 5));
        try std.testing.expectEqualStrings("hello brotli", Capture.out_buf[0..Capture.out_len]);
        try std.testing.expect(bw.br == null);
        // Writing body bytes after stream completion fails with CURLE_WRITE_ERROR
        try std.testing.expectEqual(CURLE_WRITE_ERROR, brotli_do_write(null, &bw.super, CLIENTWRITE_BODY, "x", 1));

        // Corrupt input returns CURLE_BAD_CONTENT_ENCODING
        try std.testing.expectEqual(CURLE_OK, brotli_do_init(null, &bw.super));
        const corrupt = "\xff\xff\xff\xff";
        try std.testing.expectEqual(CURLE_BAD_CONTENT_ENCODING, brotli_do_write(null, &bw.super, CLIENTWRITE_BODY, corrupt.ptr, corrupt.len));
        brotli_do_close(null, &bw.super);
    }
    if (backend_options.zstd) {
        try std.testing.expect(std.mem.indexOf(u8, enc_str, "zstd") != null);
        try std.testing.expect(find_unencode_writer("zstd", 4, CURL_CW_CONTENT_DECODE) == &zstd_encoding);
    }
    if (!backend_options.zlib and !backend_options.brotli and !backend_options.zstd) {
        try std.testing.expectEqualStrings("identity", enc_str);
    }
    try std.testing.expectEqual(CURLE_BAD_CONTENT_ENCODING, brotli_map_error(-1));
    try std.testing.expectEqual(CURLE_BAD_CONTENT_ENCODING, brotli_map_error(-16));
    try std.testing.expectEqual(CURLE_BAD_CONTENT_ENCODING, brotli_map_error(-18));
    try std.testing.expectEqual(CURLE_BAD_CONTENT_ENCODING, brotli_map_error(-20));
    try std.testing.expectEqual(CURLE_OUT_OF_MEMORY, brotli_map_error(-21));
    try std.testing.expectEqual(CURLE_OUT_OF_MEMORY, brotli_map_error(-30));
    try std.testing.expectEqual(CURLE_WRITE_ERROR, brotli_map_error(-31));
    try std.testing.expectEqual(CURLE_WRITE_ERROR, brotli_map_error(0));
    try std.testing.expect(find_unencode_writer("identity", 8, CURL_CW_CONTENT_DECODE) == &identity_encoding);
    try std.testing.expect(find_unencode_writer("none", 4, CURL_CW_CONTENT_DECODE) == &identity_encoding);
    try std.testing.expect(find_unencode_writer("chunked", 7, CURL_CW_TRANSFER_DECODE) == &Curl_httpchunk_unencoder);
    try std.testing.expect(find_unencode_writer("chunked", 7, CURL_CW_CONTENT_DECODE) == null);
}
