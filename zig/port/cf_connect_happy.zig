const std = @import("std");
const builtin = @import("builtin");
const backend_options = @import("backend_options");
const mem = @import("mem.zig");
const containers = @import("containers.zig");
const curlx_time_net = @import("curlx_time_net.zig");
const headers_sock = @import("headers_sock.zig");
const vdns_cfilters = @import("vdns_cfilters.zig");

pub const CURLcode = c_uint;
pub const CURLE_OK: CURLcode = 0;
pub const CURLE_UNSUPPORTED_PROTOCOL: CURLcode = 1;
pub const CURLE_FAILED_INIT: CURLcode = 2;
pub const CURLE_COULDNT_RESOLVE_PROXY: CURLcode = 5;
pub const CURLE_COULDNT_RESOLVE_HOST: CURLcode = 6;
pub const CURLE_COULDNT_CONNECT: CURLcode = 7;
pub const CURLE_WEIRD_SERVER_REPLY: CURLcode = 8;
pub const CURLE_OUT_OF_MEMORY: CURLcode = 27;
pub const CURLE_OPERATION_TIMEDOUT: CURLcode = 28;
pub const CURLE_BAD_FUNCTION_ARGUMENT: CURLcode = 43;
pub const CURLE_UNKNOWN_OPTION: CURLcode = 48;
pub const CURLE_AGAIN: CURLcode = 81;

pub const timediff_t = curlx_time_net.timediff_t;
pub const Curltime = curlx_time_net.Curltime;
pub const curl_off_t = i64;
pub const curl_socket_t = vdns_cfilters.curl_socket_t;
pub const CURL_SOCKET_BAD = vdns_cfilters.CURL_SOCKET_BAD;

pub const Curl_easy = vdns_cfilters.Curl_easy;
pub const connectdata = vdns_cfilters.connectdata;
pub const easy_pollset = headers_sock.EasyPollset;
pub const curl_pollfds = headers_sock.CurlPollfds;
pub const pollfd = headers_sock.Pollfd;
pub const Curl_cfilter = vdns_cfilters.Curl_cfilter;
pub const Curl_cftype = vdns_cfilters.Curl_cftype;
pub const Curl_peer = vdns_cfilters.Curl_peer;
pub const Curl_addrinfo = vdns_cfilters.Curl_addrinfo;
pub const CAddrinfo = vdns_cfilters.CAddrinfo;
pub const ip_quadruple = vdns_cfilters.ip_quadruple;

pub const Curl_multi = opaque {};
pub const Curl_dns_entry = opaque {};
pub const curl_thrdq = opaque {};

pub const FIRSTSOCKET: i8 = 0;
pub const SECONDARYSOCKET: i8 = 1;

pub const DEFAULT_CONNECT_TIMEOUT: timediff_t = 300000;

pub const CONNCTRL_CONN_KEEP: c_int = 0;
pub const CONNCTRL_CONN_CLOSE: c_int = 1;
pub const CONNCTRL_STREAM_CLOSE: c_int = 2;

pub const TIMER_STARTOP: c_int = 1;
pub const TIMER_STARTSINGLE: c_int = 2;
pub const TIMER_APPCONNECT: c_int = 6;

pub const EXPIRE_ASYNC_NAME: c_int = 1;
pub const EXPIRE_HAPPY_EYEBALLS: c_int = 3;
pub const EXPIRE_ALPN_EYEBALLS: c_int = 10;

pub const PROTOPT_SSL: c_uint = 1 << 0;
pub const PROTOPT_NONETWORK: c_uint = 1 << 4;

pub const CF_TYPE_IP_CONNECT: c_int = 1 << 0;
pub const CF_TYPE_SETUP: c_int = 1 << 5;

pub const CURL_LOG_LVL_NONE: c_int = 0;
pub const CURL_LOG_LVL_INFO: c_int = 1;

pub const CF_CTRL_CONN_INFO_UPDATE: c_int = 256 + 0;
pub const CF_CTRL_REPORT_STATS: c_int = 256 + 3;

pub const CF_QUERY_CONNECT_REPLY_MS: c_int = 2;
pub const CF_QUERY_NEED_FLUSH: c_int = 7;

pub const CURL_CF_SSL_DEFAULT: c_int = -1;
pub const CURL_CF_SSL_DISABLE: c_int = 0;
pub const CURL_CF_SSL_ENABLE: c_int = 1;

pub const TRNSPRT_TCP: u8 = 3;
pub const TRNSPRT_UDP: u8 = 4;
pub const TRNSPRT_QUIC: u8 = 5;
pub const TRNSPRT_UNIX: u8 = 6;

pub const CURL_HTTP_V1x: u8 = 1 << 0;
pub const CURL_HTTP_V2x: u8 = 1 << 1;
pub const CURL_HTTP_V3x: u8 = 1 << 2;

pub const ALPN_none: c_uint = 0;
pub const ALPN_h1: c_uint = 1 << 3;
pub const ALPN_h2: c_uint = 1 << 4;
pub const ALPN_h3: c_uint = 1 << 5;

pub const AF_UNIX: c_int = 1;
pub const AF_INET: c_int = curlx_time_net.AF_INET;
pub const AF_INET6: c_int = curlx_time_net.AF_INET6;
pub const PF_UNSPEC: c_int = 0;
pub const PF_INET: c_int = AF_INET;
pub const PF_INET6: c_int = AF_INET6;

pub const CURL_DNSQ_A: u8 = 1 << 0;
pub const CURL_DNSQ_AAAA: u8 = 1 << 1;

pub const MAX_IPADR_LEN: usize = 46;

pub const Curl_sockaddr_ex = extern struct {
    family: c_int,
    socktype: c_int,
    protocol: c_int,
    addrlen: c_uint,
    addr_buf: [256]u8 align(8),
};

// ============================================================================
// External C Declarations & Zig Helper Accessors in lib/cf-socket.c
// ============================================================================

extern fn Curl_infof(data: ?*Curl_easy, fmt: [*:0]const u8, ...) callconv(.c) void;
extern fn Curl_failf(data: ?*Curl_easy, fmt: [*:0]const u8, ...) callconv(.c) void;
extern fn Curl_reset_fail(data: ?*Curl_easy) callconv(.c) void;
extern fn Curl_trc_dns(data: ?*Curl_easy, fmt: [*:0]const u8, ...) callconv(.c) void;
extern fn Curl_trc_cf_infof(data: ?*Curl_easy, cf: *const Curl_cfilter, fmt: [*:0]const u8, ...) callconv(.c) void;
extern fn curl_msnprintf(buffer: [*]u8, maxlength: usize, format: [*:0]const u8, ...) callconv(.c) c_int;
extern fn curl_easy_strerror(code: CURLcode) callconv(.c) [*:0]const u8;

extern fn Curl_pgrs_now(data: ?*Curl_easy) callconv(.c) *const Curltime;
extern fn Curl_pgrs_since_ms(data: ?*Curl_easy, pnow: ?*const Curltime, timer: c_int) callconv(.c) timediff_t;
extern fn Curl_pgrsTime(data: ?*Curl_easy, timer: c_int) callconv(.c) void;
extern fn Curl_is_connecting(data: ?*Curl_easy) callconv(.c) bool;
extern fn Curl_cshutdn_timeleft_ms(data: ?*Curl_easy, conn: ?*connectdata, sockindex: i8) callconv(.c) timediff_t;
extern fn Curl_cpool_get_last_conn(data: ?*Curl_easy) callconv(.c) ?*connectdata;
extern fn Curl_cpool_conn_was_used(data: ?*Curl_easy, conn: ?*connectdata, pnow: *const Curltime) callconv(.c) void;
extern fn Curl_conn_is_multiplex(conn: ?*connectdata, sockindex: i8) callconv(.c) bool;
extern fn Curl_conn_is_ssl(conn: ?*connectdata, sockindex: i8) callconv(.c) bool;
extern fn Curl_resolv_dns_queries(data: ?*Curl_easy, ip_version: u8) callconv(.c) u8;
extern fn Curl_conn_dns_add_addr_resolve(data: ?*Curl_easy, conn: ?*connectdata, sockindex: i8, peer: *Curl_peer, dns_queries: u8, transport: u8) callconv(.c) CURLcode;
extern fn Curl_conn_dns_addr_result(conn: ?*connectdata, sockindex: i8, peer: ?*Curl_peer) callconv(.c) CURLcode;
extern fn Curl_conn_dns_get_ai(data: ?*Curl_easy, peer: ?*Curl_peer, sockindex: i8, ai_family: c_int, index: c_uint) callconv(.c) ?*const Curl_addrinfo;
extern fn Curl_conn_cntrl_report_stats(data: ?*Curl_easy, conn: ?*connectdata, sockindex: c_int) callconv(.c) void;
extern fn Curl_conn_cntrl_update_info(data: ?*Curl_easy, conn: ?*connectdata) callconv(.c) void;
extern fn Curl_conn_cf_cntrl(cf: ?*Curl_cfilter, data: ?*Curl_easy, ignore_result: bool, event: c_int, arg1: c_int, arg2: ?*anyopaque) callconv(.c) CURLcode;
extern fn Curl_conn_cf_get_ip_info(cf: ?*Curl_cfilter, data: ?*Curl_easy, is_ipv6: *bool, ipquad: *ip_quadruple) callconv(.c) CURLcode;
extern fn Curl_conn_cf_get_socket(cf: ?*Curl_cfilter, data: ?*Curl_easy) callconv(.c) curl_socket_t;
extern fn Curl_conn_cf_get_alpn_negotiated(cf: ?*Curl_cfilter, data: ?*Curl_easy) callconv(.c) ?[*:0]const u8;
extern fn Curl_conn_cf_connect(cf: ?*Curl_cfilter, data: ?*Curl_easy, done: *bool) callconv(.c) CURLcode;
extern fn Curl_conn_cf_adjust_pollset(cf: ?*Curl_cfilter, data: ?*Curl_easy, ps: *easy_pollset) callconv(.c) CURLcode;
extern fn Curl_conn_cf_needs_flush(cf: ?*Curl_cfilter, data: ?*Curl_easy) callconv(.c) bool;
extern fn Curl_conn_cf_is_ip_connected(cf: ?*Curl_cfilter, data: ?*Curl_easy) callconv(.c) bool;
extern fn Curl_conn_cf_discard_chain(pcf: *?*Curl_cfilter, data: ?*Curl_easy) callconv(.c) void;
extern fn Curl_conn_cf_add(data: ?*Curl_easy, conn: ?*connectdata, index: i8, cf: *Curl_cfilter) callconv(.c) void;
extern fn Curl_conn_cf_insert_after(cf_at: *Curl_cfilter, cf_new: *Curl_cfilter) callconv(.c) void;
extern fn Curl_cf_create(pcf: *?*Curl_cfilter, cft: *const Curl_cftype, ctx: ?*anyopaque) callconv(.c) CURLcode;
extern fn Curl_conn_needs_flush(data: ?*Curl_easy, sockindex: i8) callconv(.c) bool;
extern fn Curl_conn_flush(data: ?*Curl_easy, sockindex: i8) callconv(.c) CURLcode;
extern fn Curl_conn_trc_filters(data: ?*Curl_easy, sockindex: i8, msg: [*:0]const u8) callconv(.c) void;
extern fn Curl_conn_remove_setup_filters(data: ?*Curl_easy, sockindex: i8) callconv(.c) void;
extern fn Curl_conn_adjust_pollset(data: ?*Curl_easy, conn: ?*connectdata, ps: *easy_pollset) callconv(.c) CURLcode;
extern fn Curl_multi_connchanged(multi: ?*Curl_multi) callconv(.c) void;
extern fn Curl_expire_set(data: ?*Curl_easy, id: c_int, time_ms: timediff_t, pnow: *const Curltime) callconv(.c) void;
extern fn Curl_expire_clear(data: ?*Curl_easy, id: c_int) callconv(.c) void;
extern fn Curl_conn_may_http3(data: ?*Curl_easy, conn: ?*connectdata) callconv(.c) CURLcode;
extern fn Curl_http2_switch_at(cf: *Curl_cfilter, data: ?*Curl_easy) callconv(.c) CURLcode;
extern fn Curl_peer_link(ppeer: *?*Curl_peer, peer: ?*Curl_peer) callconv(.c) void;
extern fn Curl_peer_unlink(ppeer: *?*Curl_peer) callconv(.c) void;
extern fn Curl_peer_equal(p1: ?*const Curl_peer, p2: ?*const Curl_peer) callconv(.c) bool;
extern fn Curl_socket_addr_from_ai(addr: *Curl_sockaddr_ex, ai: *const Curl_addrinfo, transport: u8) callconv(.c) CURLcode;

extern fn Curl_cf_def_send(cf: *Curl_cfilter, data: ?*Curl_easy, buf: [*]const u8, len: usize, eos: bool, pnwritten: *usize) callconv(.c) CURLcode;
extern fn Curl_cf_def_recv(cf: *Curl_cfilter, data: ?*Curl_easy, buf: [*]u8, len: usize, pnread: *usize) callconv(.c) CURLcode;
extern fn Curl_cf_def_cntrl(cf: *Curl_cfilter, data: ?*Curl_easy, event: c_int, arg1: c_int, arg2: ?*anyopaque) callconv(.c) CURLcode;
extern fn Curl_cf_def_conn_is_alive(cf: *Curl_cfilter, data: ?*Curl_easy, input_pending: *bool) callconv(.c) bool;
extern fn Curl_cf_def_conn_keep_alive(cf: *Curl_cfilter, data: ?*Curl_easy) callconv(.c) CURLcode;

pub const cf_ip_connect_create = *const fn (
    pcf: *?*Curl_cfilter,
    data: ?*Curl_easy,
    origin: ?*Curl_peer,
    peer: ?*Curl_peer,
    transport_peer: u8,
    conn: ?*connectdata,
    addr: *Curl_sockaddr_ex,
    tunnel_peer: ?*Curl_peer,
    tunnel_transport: u8,
) callconv(.c) CURLcode;

extern fn Curl_cf_tcp_create(
    pcf: *?*Curl_cfilter,
    data: ?*Curl_easy,
    origin: ?*Curl_peer,
    peer: ?*Curl_peer,
    transport_peer: u8,
    conn: ?*connectdata,
    addr: *Curl_sockaddr_ex,
    tunnel_peer: ?*Curl_peer,
    tunnel_transport: u8,
) callconv(.c) CURLcode;
extern fn Curl_cf_udp_create(
    pcf: *?*Curl_cfilter,
    data: ?*Curl_easy,
    origin: ?*Curl_peer,
    peer: ?*Curl_peer,
    transport_peer: u8,
    conn: ?*connectdata,
    addr: *Curl_sockaddr_ex,
    tunnel_peer: ?*Curl_peer,
    tunnel_transport: u8,
) callconv(.c) CURLcode;
extern fn Curl_cf_unix_create(
    pcf: *?*Curl_cfilter,
    data: ?*Curl_easy,
    origin: ?*Curl_peer,
    peer: ?*Curl_peer,
    transport_peer: u8,
    conn: ?*connectdata,
    addr: *Curl_sockaddr_ex,
    tunnel_peer: ?*Curl_peer,
    tunnel_transport: u8,
) callconv(.c) CURLcode;

// C accessors defined in lib/cf-socket.c
extern fn Curl_zig_connect_timeleft_info(
    data: *Curl_easy,
    in_shutdown: *bool,
    connecttimeout_ms: *timediff_t,
    timeout_ms: *timediff_t,
    connect_only: *u8,
) callconv(.c) void;
extern fn Curl_zig_data_get_conn(data: ?*Curl_easy) callconv(.c) ?*connectdata;
extern fn Curl_zig_conn_get_sock(conn: *const connectdata, sockindex: i8) callconv(.c) curl_socket_t;
extern fn Curl_zig_conn_set_close(conn: *connectdata, close_it: bool) callconv(.c) void;
extern fn Curl_zig_conn_get_cfilter(conn: ?*const connectdata, sockindex: i8) callconv(.c) ?*Curl_cfilter;
extern fn Curl_zig_conn_is_https(conn: ?*const connectdata) callconv(.c) bool;
extern fn Curl_zig_conn_get_ip_version(conn: *const connectdata) callconv(.c) u8;
extern fn Curl_zig_cf_setup_add(data: ?*Curl_easy, conn: *connectdata, sockindex: i8, ssl_mode: c_int) callconv(.c) CURLcode;
extern fn Curl_zig_cf_setup_insert_after(cf: *Curl_cfilter, data: ?*Curl_easy, transport: u8, ssl_mode: c_int) callconv(.c) CURLcode;
extern fn Curl_zig_conn_host_dispname(conn: ?*const connectdata) callconv(.c) [*:0]const u8;
extern fn Curl_zig_conn_scheme_flags(conn: *const connectdata) callconv(.c) c_uint;
extern fn Curl_zig_data_origin_scheme_flags(data: ?*const Curl_easy) callconv(.c) c_uint;
extern fn Curl_zig_conn_set_multiplex(conn: *connectdata, out_multi: *?*Curl_multi) callconv(.c) void;
extern fn Curl_zig_conn_get_origin(conn: *connectdata, sockindex: i8) callconv(.c) ?*Curl_peer;
extern fn Curl_zig_conn_get_destination(conn: *connectdata, sockindex: i8) callconv(.c) ?*Curl_peer;
extern fn Curl_zig_conn_get_first_peer(conn: *connectdata, sockindex: i8) callconv(.c) ?*Curl_peer;
extern fn Curl_zig_data_get_http_neg(data: *const Curl_easy, wanted: *u8, allowed: *u8, preferred: *u8) callconv(.c) void;
extern fn Curl_zig_data_set_http_neg_wanted(data: *Curl_easy, wanted: u8) callconv(.c) void;
extern fn Curl_zig_data_happy_eyeballs_timeout(data: *const Curl_easy) callconv(.c) timediff_t;
extern fn Curl_zig_conn_should_https_setup(conn: *const connectdata) callconv(.c) bool;
extern fn Curl_zig_conn_get_transport_wanted(conn: *const connectdata) callconv(.c) u8;
extern fn Curl_zig_conn_get_peers(conn: *const connectdata, origin: *?*Curl_peer, socks_proxy_peer: *?*Curl_peer, http_proxy_peer: *?*Curl_peer) callconv(.c) void;
extern fn Curl_zig_data_is_os_errno_timedout(data: *const Curl_easy) callconv(.c) bool;
extern fn Curl_zig_conn_is_ssh(conn: *const connectdata) callconv(.c) bool;
extern fn Curl_zig_data_inc_numconnects(data: *Curl_easy) callconv(.c) void;
extern fn Curl_zig_data_get_mid(data: *const Curl_easy) callconv(.c) u32;
extern fn Curl_zig_data_get_id(data: *const Curl_easy) callconv(.c) curl_off_t;
extern fn Curl_zig_data_get_multi(data: ?*const Curl_easy) callconv(.c) ?*Curl_multi;
extern fn Curl_zig_multi_get_resolv_thrdq_ptr(multi: *Curl_multi) callconv(.c) *?*curl_thrdq;
extern fn Curl_zig_multi_get_resolv_thrdq(multi: ?*const Curl_multi) callconv(.c) ?*curl_thrdq;
extern fn Curl_zig_multi_set_resolv_thrdq(multi: *Curl_multi, thrdq: ?*curl_thrdq) callconv(.c) void;
extern fn Curl_zig_multi_get_admin(multi: ?*const Curl_multi) callconv(.c) ?*Curl_easy;
extern fn Curl_zig_data_get_conn_scope_id(data: ?*const Curl_easy) callconv(.c) c_uint;
extern fn Curl_zig_trc_is_verbose(data: ?*Curl_easy) callconv(.c) bool;
extern fn Curl_zig_trc_cf_is_verbose(cf: *const Curl_cfilter, data: ?*Curl_easy) callconv(.c) bool;
extern fn Curl_zig_trc_dns_is_verbose(data: ?*Curl_easy) callconv(.c) bool;
extern fn Curl_zig_thrdq_trace(tqueue: ?*curl_thrdq, data: ?*Curl_easy) callconv(.c) void;
extern fn Curl_zig_async_thrdd_classify_gai_error(rc: c_int, out_sockerr: *c_int, out_negative: *bool) callconv(.c) void;

inline fn infof(data: ?*Curl_easy, fmt: [*:0]const u8, args: anytype) void {
    if (data != null) {
        @call(.auto, Curl_infof, .{ data, fmt } ++ args);
    }
}

inline fn failf(data: ?*Curl_easy, fmt: [*:0]const u8, args: anytype) void {
    if (data != null) {
        @call(.auto, Curl_failf, .{ data, fmt } ++ args);
    }
}

inline fn trcCf(data: ?*Curl_easy, cf: *const Curl_cfilter, fmt: [*:0]const u8, args: anytype) void {
    if (data != null and cf.cft.log_level >= CURL_LOG_LVL_INFO) {
        @call(.auto, Curl_trc_cf_infof, .{ data, cf, fmt } ++ args);
    }
}

inline fn trcDns(data: ?*Curl_easy, fmt: [*:0]const u8, args: anytype) void {
    if (data != null) {
        @call(.auto, Curl_trc_dns, .{ data, fmt } ++ args);
    }
}

// ============================================================================
// 1. lib/connect.c
// ============================================================================

export fn Curl_alpn2alpnid(name: ?[*]const u8, len: usize) callconv(.c) c_uint {
    const ptr = name orelse return ALPN_none;
    if (len == 2) {
        if (std.mem.eql(u8, ptr[0..2], "h1")) return ALPN_h1;
        if (std.mem.eql(u8, ptr[0..2], "h2")) return ALPN_h2;
        if (std.mem.eql(u8, ptr[0..2], "h3")) return ALPN_h3;
    } else if (len == 8 and std.mem.eql(u8, ptr[0..8], "http/1.1")) {
        return ALPN_h1;
    }
    return ALPN_none;
}

export fn timeleft_now_ms(data: ?*Curl_easy, pnow: *const Curltime) callconv(.c) timediff_t {
    const d = data orelse return 0;
    var timeleft_ms: timediff_t = 0;
    var ctimeleft_ms: timediff_t = 0;

    var in_shutdown: bool = false;
    var connecttimeout_ms: timediff_t = 0;
    var timeout_ms: timediff_t = 0;
    var connect_only: u8 = 0;
    Curl_zig_connect_timeleft_info(d, &in_shutdown, &connecttimeout_ms, &timeout_ms, &connect_only);

    if (in_shutdown) {
        return Curl_cshutdn_timeleft_ms(d, Curl_zig_data_get_conn(d), FIRSTSOCKET);
    } else if (Curl_is_connecting(d)) {
        const ctimeout_ms: timediff_t = if (connecttimeout_ms > 0)
            connecttimeout_ms
        else
            DEFAULT_CONNECT_TIMEOUT;
        ctimeleft_ms = ctimeout_ms - Curl_pgrs_since_ms(d, pnow, TIMER_STARTSINGLE);
        if (ctimeleft_ms == 0) {
            ctimeleft_ms = -1;
        }
    } else if (timeout_ms == 0 or connect_only != 0) {
        return 0;
    }

    if (timeout_ms != 0) {
        timeleft_ms = timeout_ms - Curl_pgrs_since_ms(d, pnow, TIMER_STARTOP);
        if (timeleft_ms == 0) {
            timeleft_ms = -1;
        }
    }

    if (ctimeleft_ms == 0) {
        return timeleft_ms;
    } else if (timeleft_ms == 0) {
        return ctimeleft_ms;
    }
    return @min(ctimeleft_ms, timeleft_ms);
}

export fn Curl_timeleft_ms(data: ?*Curl_easy) callconv(.c) timediff_t {
    return timeleft_now_ms(data, Curl_pgrs_now(data));
}

export fn Curl_timeleft_now_ms(data: ?*Curl_easy, pnow: *const Curltime) callconv(.c) timediff_t {
    return timeleft_now_ms(data, pnow);
}

export fn Curl_getconnectinfo(data: ?*Curl_easy, connp: ?*?*connectdata) callconv(.c) curl_socket_t {
    const conn = Curl_cpool_get_last_conn(data);
    if (connp) |out_conn| {
        out_conn.* = conn;
    }
    const c = conn orelse return CURL_SOCKET_BAD;
    return Curl_zig_conn_get_sock(c, FIRSTSOCKET);
}

export fn Curl_conncontrol(conn: ?*connectdata, ctrl: c_int) callconv(.c) void {
    const c = conn orelse return;
    switch (ctrl) {
        CONNCTRL_CONN_KEEP => {
            Curl_zig_conn_set_close(c, false);
        },
        CONNCTRL_CONN_CLOSE => {
            Curl_zig_conn_set_close(c, true);
        },
        CONNCTRL_STREAM_CLOSE => {
            if (!Curl_conn_is_multiplex(c, FIRSTSOCKET)) {
                Curl_zig_conn_set_close(c, true);
            }
        },
        else => {},
    }
}

export fn Curl_conn_setup(
    data: ?*Curl_easy,
    conn: ?*connectdata,
    sockindex: i8,
    ssl_mode: c_int,
) callconv(.c) CURLcode {
    const c = conn orelse return CURLE_FAILED_INIT;
    const first_peer = Curl_conn_get_first_peer(c, sockindex) orelse return CURLE_FAILED_INIT;
    var result: CURLcode = CURLE_OK;

    if (Curl_zig_conn_get_cfilter(c, sockindex) == null and Curl_zig_conn_is_https(c)) {
        result = Curl_cf_https_setup(
            data,
            Curl_conn_get_destination(c, sockindex),
            c,
            sockindex,
        );
        if (result != CURLE_OK) {
            return result;
        }
    }

    if (Curl_zig_conn_get_cfilter(c, sockindex) == null) {
        result = Curl_zig_cf_setup_add(data, c, sockindex, ssl_mode);
        if (result != CURLE_OK) {
            return result;
        }
    }

    const dns_queries = Curl_resolv_dns_queries(data, Curl_zig_conn_get_ip_version(c));
    result = Curl_conn_dns_add_addr_resolve(
        data,
        c,
        sockindex,
        first_peer,
        dns_queries,
        Curl_zig_conn_get_transport_wanted(c),
    );
    return result;
}

fn conn_connect_trace(data: ?*Curl_easy, cf: *Curl_cfilter) CURLcode {
    if (Curl_zig_trc_is_verbose(data)) {
        var ipquad: ip_quadruple = undefined;
        var is_ipv6: bool = false;
        const result = Curl_conn_cf_get_ip_info(cf, data, &is_ipv6, &ipquad);
        if (result != CURLE_OK) {
            return result;
        }
        const prefix: [*:0]const u8 = if (cf.sockindex == SECONDARYSOCKET) "2nd " else "";
        const dispname = Curl_zig_conn_host_dispname(Curl_zig_data_get_conn(data));
        const remote_ip_ptr: [*:0]const u8 = @ptrCast(&ipquad.remote_ip);
        const local_ip_ptr: [*:0]const u8 = @ptrCast(&ipquad.local_ip);
        infof(
            data,
            "Established %sconnection to %s (%s port %u) from %s port %u ",
            .{
                prefix,
                dispname,
                remote_ip_ptr,
                @as(c_uint, ipquad.remote_port),
                local_ip_ptr,
                @as(c_uint, ipquad.local_port),
            },
        );
    }
    return CURLE_OK;
}

inline fn conn_report_stats(data: ?*Curl_easy, sockindex: i8) void {
    if (sockindex == FIRSTSOCKET) {
        Curl_conn_cntrl_report_stats(data, Curl_zig_data_get_conn(data), @as(c_int, sockindex));
    }
}

export fn Curl_conn_report_failed(data: ?*Curl_easy, sockindex: i8) callconv(.c) void {
    const conn = Curl_zig_data_get_conn(data) orelse return;
    if (sockindex != FIRSTSOCKET) return;
    _ = Curl_conn_cf_cntrl(
        Curl_zig_conn_get_cfilter(conn, sockindex),
        data,
        true,
        CF_CTRL_CONN_INFO_UPDATE,
        0,
        null,
    );
    conn_report_stats(data, sockindex);
}

const CF_CONN_NUM_POLLS_ON_STACK: c_uint = 5;

export fn Curl_conn_connect(
    data: ?*Curl_easy,
    sockindex: i8,
    blocking: bool,
    done: *bool,
) callconv(.c) CURLcode {
    if (sockindex < FIRSTSOCKET or sockindex > SECONDARYSOCKET) {
        return CURLE_BAD_FUNCTION_ARGUMENT;
    }
    const conn = Curl_zig_data_get_conn(data) orelse return CURLE_BAD_FUNCTION_ARGUMENT;

    if ((Curl_zig_conn_scheme_flags(conn) & PROTOPT_NONETWORK) != 0) {
        done.* = true;
        return CURLE_OK;
    }

    const cf = Curl_zig_conn_get_cfilter(conn, sockindex) orelse {
        done.* = false;
        return CURLE_FAILED_INIT;
    };

    done.* = cf.isConnected();
    if (done.*) {
        return CURLE_OK;
    }

    var a_few_on_stack: [CF_CONN_NUM_POLLS_ON_STACK]pollfd = undefined;
    var ps: easy_pollset = undefined;
    var cpfds: curl_pollfds = undefined;
    var result: CURLcode = CURLE_OK;

    headers_sock.Curl_pollset_init(&ps);
    headers_sock.Curl_pollfds_init(&cpfds, &a_few_on_stack, CF_CONN_NUM_POLLS_ON_STACK);
    defer {
        headers_sock.Curl_pollset_cleanup(&ps);
        headers_sock.Curl_pollfds_cleanup(&cpfds);
    }

    while (!done.*) {
        if (Curl_conn_needs_flush(data, sockindex)) {
            result = Curl_conn_flush(data, sockindex);
            if (result != CURLE_OK and result != CURLE_AGAIN) {
                return result;
            }
        }

        result = cf.cft.do_connect(cf, data, done);
        trcCf(
            data,
            cf,
            "Curl_conn_connect(block=%d) -> %d, done=%d",
            .{ @as(c_int, @intFromBool(blocking)), @as(c_int, @intCast(result)), @as(c_int, @intFromBool(done.*)) },
        );
        if (result == CURLE_OK and done.*) {
            if ((Curl_zig_data_origin_scheme_flags(data) & PROTOPT_SSL) != 0 and
                sockindex == FIRSTSOCKET and
                !Curl_conn_is_ssl(conn, FIRSTSOCKET))
            {
                failf(data, "transfer requires SSL, but not connected via SSL", .{});
                return CURLE_FAILED_INIT;
            }
            Curl_conn_cntrl_update_info(data, conn);
            conn_report_stats(data, sockindex);
            Curl_cpool_conn_was_used(data, conn, Curl_pgrs_now(data));
            result = conn_connect_trace(data, cf);
            Curl_conn_trc_filters(data, sockindex, "connected");
            Curl_conn_remove_setup_filters(data, sockindex);
            Curl_conn_trc_filters(data, sockindex, "reduced to");
            return result;
        } else if (result != CURLE_OK) {
            trcCf(data, cf, "Curl_conn_connect(), filter returned %d", .{@as(c_int, @intCast(result))});
            Curl_conn_trc_filters(data, sockindex, "failed to connect");
            Curl_conn_report_failed(data, sockindex);
            return result;
        }

        if (!blocking) {
            return result;
        } else {
            const timeout_ms = Curl_timeleft_ms(data);
            const sockfd = Curl_conn_cf_get_socket(cf, data);

            if (timeout_ms < 0) {
                failf(data, "connect timeout", .{});
                return CURLE_OPERATION_TIMEDOUT;
            }

            trcCf(data, cf, "Curl_conn_connect(block=1), do poll", .{});
            headers_sock.Curl_pollset_reset(&ps);
            headers_sock.Curl_pollfds_reset(&cpfds);
            if (sockfd != CURL_SOCKET_BAD) {
                result = headers_sock.Curl_pollset_change(
                    data,
                    &ps,
                    sockfd,
                    headers_sock.CURL_POLL_OUT,
                    headers_sock.CURL_POLL_IN,
                );
            }
            if (result == CURLE_OK) {
                result = Curl_conn_adjust_pollset(data, conn, &ps);
            }
            if (result != CURLE_OK) {
                return result;
            }
            result = headers_sock.Curl_pollfds_add_ps(&cpfds, &ps);
            if (result != CURLE_OK) {
                return result;
            }

            const poll_timeout: timediff_t = @min(
                if (timeout_ms != 0) timeout_ms else @as(timediff_t, 1000),
                if (cpfds.n != 0) @as(timediff_t, 1000) else @as(timediff_t, 10),
            );
            const rc = headers_sock.Curl_poll(cpfds.pfds, cpfds.n, poll_timeout);
            trcCf(data, cf, "Curl_conn_connect(block=1), Curl_poll() -> %d", .{rc});
            if (rc < 0) {
                return CURLE_COULDNT_CONNECT;
            }
        }
    }
    return result;
}

export fn Curl_conn_set_multiplex(conn: ?*connectdata) callconv(.c) void {
    const c = conn orelse return;
    var multi: ?*Curl_multi = null;
    Curl_zig_conn_set_multiplex(c, &multi);
    if (multi) |m| {
        Curl_multi_connchanged(m);
    }
}

export fn Curl_conn_get_origin(conn: ?*connectdata, sockindex: i8) callconv(.c) ?*Curl_peer {
    const c = conn orelse return null;
    return Curl_zig_conn_get_origin(c, sockindex);
}

export fn Curl_conn_get_destination(conn: ?*connectdata, sockindex: i8) callconv(.c) ?*Curl_peer {
    const c = conn orelse return null;
    return Curl_zig_conn_get_destination(c, sockindex);
}

export fn Curl_conn_get_first_peer(conn: ?*connectdata, sockindex: i8) callconv(.c) ?*Curl_peer {
    const c = conn orelse return null;
    return Curl_zig_conn_get_first_peer(c, sockindex);
}

// ============================================================================
// 2. lib/cf-https-connect.c
// ============================================================================

const cf_hc_state = enum(c_int) {
    CF_HC_RESOLV = 0,
    CF_HC_INIT = 1,
    CF_HC_CONNECT = 2,
    CF_HC_SUCCESS = 3,
    CF_HC_FAILURE = 4,
};

const cf_hc_baller = struct {
    name: [*:0]const u8 = "no-alpn",
    cf: ?*Curl_cfilter = null,
    result: CURLcode = CURLE_OK,
    reply_ms: c_int = -1,
    transport: u8 = 0,
    alpn_id: c_uint = ALPN_none,
    shutdown: bool = false,
};

fn cf_hc_baller_discard(b: *cf_hc_baller, data: ?*Curl_easy) void {
    if (b.cf != null) {
        Curl_conn_cf_discard_chain(&b.cf, data);
        b.cf = null;
    }
}

inline fn cf_hc_baller_is_connecting(b: *const cf_hc_baller) bool {
    return b.cf != null and b.result == CURLE_OK;
}

inline fn cf_hc_baller_has_started(b: *const cf_hc_baller) bool {
    return b.cf != null;
}

fn cf_hc_baller_reply_ms(b: *cf_hc_baller, data: ?*Curl_easy) c_int {
    if (b.cf) |sub_cf| {
        if (b.reply_ms < 0) {
            _ = sub_cf.cft.query(sub_cf, data, CF_QUERY_CONNECT_REPLY_MS, &b.reply_ms, null);
        }
    }
    return b.reply_ms;
}

fn cf_hc_baller_data_pending(b: *const cf_hc_baller, data: ?*const Curl_easy) bool {
    if (b.cf) |sub_cf| {
        if (b.result == CURLE_OK) {
            return sub_cf.cft.has_data_pending(sub_cf, data);
        }
    }
    return false;
}

fn cf_hc_baller_needs_flush(b: *const cf_hc_baller, data: ?*Curl_easy) bool {
    if (b.cf) |sub_cf| {
        if (b.result == CURLE_OK) {
            return Curl_conn_cf_needs_flush(sub_cf, data);
        }
    }
    return false;
}

fn cf_hc_baller_cntrl(b: *cf_hc_baller, data: ?*Curl_easy, event: c_int, arg1: c_int, arg2: ?*anyopaque) CURLcode {
    if (b.cf) |sub_cf| {
        if (b.result == CURLE_OK) {
            return Curl_conn_cf_cntrl(sub_cf, data, false, event, arg1, arg2);
        }
    }
    return CURLE_OK;
}

const cf_hc_ctx = struct {
    state: cf_hc_state,
    destination: ?*Curl_peer,
    started: Curltime,
    result: CURLcode,
    check_h3_result: CURLcode,
    ballers: [2]cf_hc_baller,
    baller_count: usize,
    soft_eyeballs_timeout_ms: timediff_t,
    hard_eyeballs_timeout_ms: timediff_t,
    def_transport: u8,
    httpsrr_resolved: bool,
    checked_h3: bool,
    ballers_complete: bool,
};

fn cf_hc_ctx_destroy(data: ?*Curl_easy, ctx_opt: ?*cf_hc_ctx) void {
    const ctx = ctx_opt orelse return;
    var i: usize = 0;
    while (i < ctx.baller_count) : (i += 1) {
        cf_hc_baller_discard(&ctx.ballers[i], data);
    }
    Curl_peer_unlink(&ctx.destination);
    mem.free(ctx);
}

fn cf_hc_baller_assign(b: *cf_hc_baller, alpn_id: c_uint, def_transport: u8) void {
    b.alpn_id = alpn_id;
    b.transport = def_transport;
    b.cf = null;
    b.result = CURLE_OK;
    b.reply_ms = -1;
    b.shutdown = false;
    switch (b.alpn_id) {
        ALPN_h3 => {
            b.name = "h3";
            b.transport = TRNSPRT_QUIC;
        },
        ALPN_h2 => {
            b.name = "h2";
        },
        ALPN_h1 => {
            b.name = "h1";
        },
        ALPN_none => {
            b.name = "no-alpn";
        },
        else => {
            b.result = CURLE_FAILED_INIT;
        },
    }
}

fn cf_hc_baller_init(b: *cf_hc_baller, cf: *Curl_cfilter, data: ?*Curl_easy) void {
    const save = cf.next;
    cf.next = null;
    b.result = Curl_zig_cf_setup_insert_after(cf, data, b.transport, CURL_CF_SSL_ENABLE);
    b.cf = cf.next;
    cf.next = save;
}

fn cf_hc_baller_connect(b: *cf_hc_baller, cf: *Curl_cfilter, data: ?*Curl_easy, done: *bool) CURLcode {
    const save = cf.next;
    cf.next = b.cf;
    b.result = Curl_conn_cf_connect(cf.next, data, done);
    b.cf = cf.next;
    cf.next = save;
    return b.result;
}

fn baller_connected(cf: *Curl_cfilter, data: ?*Curl_easy, winner: *cf_hc_baller) CURLcode {
    const ctx: *cf_hc_ctx = @ptrCast(@alignCast(cf.ctx));
    if (cf.next != null) {
        return CURLE_FAILED_INIT;
    }
    if (winner.cf == null) {
        return CURLE_FAILED_INIT;
    }

    cf.next = winner.cf;
    winner.cf = null;
    ctx.state = .CF_HC_SUCCESS;
    cf.setConnected(true);

    Curl_reset_fail(data);

    if (backend_options.nghttp2) {
        if (Curl_conn_cf_get_alpn_negotiated(cf.next, data)) |alpn| {
            if (std.mem.orderZ(u8, "h2", alpn) == .eq) {
                const result = Curl_http2_switch_at(cf, data);
                if (result != CURLE_OK) {
                    ctx.state = .CF_HC_FAILURE;
                    ctx.result = result;
                    return result;
                }
            }
        }
    }
    return CURLE_OK;
}

fn time_to_start_baller2(cf: *Curl_cfilter, data: ?*Curl_easy, pnow: *const Curltime) bool {
    const ctx: *cf_hc_ctx = @ptrCast(@alignCast(cf.ctx));

    if (ctx.baller_count < 2) {
        return false;
    } else if (cf_hc_baller_has_started(&ctx.ballers[1])) {
        return false;
    } else if (ctx.ballers[0].result != CURLE_OK) {
        trcCf(data, cf, "%s baller failed, starting %s", .{ ctx.ballers[0].name, ctx.ballers[1].name });
        return true;
    }

    const elapsed_ms = curlx_time_net.curlx_ptimediff_ms(pnow, &ctx.started);
    if (elapsed_ms >= ctx.hard_eyeballs_timeout_ms) {
        trcCf(
            data,
            cf,
            "%s inconclusive after %lld, starting %s",
            .{ ctx.ballers[0].name, @as(c_longlong, ctx.hard_eyeballs_timeout_ms), ctx.ballers[1].name },
        );
        return true;
    } else if (elapsed_ms >= ctx.soft_eyeballs_timeout_ms) {
        if (cf_hc_baller_reply_ms(&ctx.ballers[0], data) < 0) {
            trcCf(
                data,
                cf,
                "%s has not seen any data after %lldms, starting %s",
                .{ ctx.ballers[0].name, @as(c_longlong, ctx.soft_eyeballs_timeout_ms), ctx.ballers[1].name },
            );
            return true;
        }
        Curl_expire_set(data, EXPIRE_ALPN_EYEBALLS, ctx.hard_eyeballs_timeout_ms - elapsed_ms, pnow);
    }
    return false;
}

fn cf_hc_may_h3(cf: *Curl_cfilter, data: ?*Curl_easy) bool {
    const ctx: *cf_hc_ctx = @ptrCast(@alignCast(cf.ctx));
    if (!ctx.checked_h3) {
        ctx.check_h3_result = Curl_conn_may_http3(data, cf.conn);
        ctx.checked_h3 = true;
    }
    return ctx.check_h3_result == CURLE_OK;
}

fn cf_hc_get_httpsrr_alpn(cf: *Curl_cfilter, data: ?*Curl_easy, not_this_one: c_uint) c_uint {
    _ = cf;
    _ = data;
    _ = not_this_one;
    return ALPN_none;
}

fn cf_hc_get_pref_alpn(cf: *Curl_cfilter, data: ?*Curl_easy, not_this_one: c_uint) c_uint {
    const d = data orelse return ALPN_none;
    var wanted: u8 = 0;
    var allowed: u8 = 0;
    var preferred: u8 = 0;
    Curl_zig_data_get_http_neg(d, &wanted, &allowed, &preferred);

    if ((preferred & allowed) != 0) {
        switch (preferred) {
            CURL_HTTP_V3x => {
                if (cf_hc_may_h3(cf, data) and ALPN_h3 != not_this_one) {
                    return ALPN_h3;
                }
            },
            CURL_HTTP_V2x => {
                if (ALPN_h2 != not_this_one) {
                    return ALPN_h2;
                }
            },
            CURL_HTTP_V1x => {
                if (ALPN_h1 != not_this_one and ALPN_h2 != not_this_one) {
                    return ALPN_h1;
                }
            },
            else => {},
        }
    }
    return ALPN_none;
}

fn cf_hc_get_first_alpn(cf: *Curl_cfilter, data: ?*Curl_easy, choices: u8, not_this_one: c_uint) c_uint {
    const allow_h1_or_h2 = (not_this_one != ALPN_h1) and (not_this_one != ALPN_h2);
    if (ALPN_h3 != not_this_one and (choices & CURL_HTTP_V3x) != 0 and cf_hc_may_h3(cf, data)) {
        return ALPN_h3;
    }
    if (allow_h1_or_h2 and (choices & CURL_HTTP_V2x) != 0) {
        return ALPN_h2;
    }
    if (allow_h1_or_h2 and (choices & CURL_HTTP_V1x) != 0) {
        return ALPN_h1;
    }
    return ALPN_none;
}

fn cf_hc_set_baller1(cf: *Curl_cfilter, data: ?*Curl_easy) CURLcode {
    const ctx: *cf_hc_ctx = @ptrCast(@alignCast(cf.ctx));
    const d = data orelse return CURLE_FAILED_INIT;
    var wanted: u8 = 0;
    var allowed: u8 = 0;
    var preferred: u8 = 0;
    Curl_zig_data_get_http_neg(d, &wanted, &allowed, &preferred);

    var alpn1: c_uint = ALPN_none;
    var source: [*:0]const u8 = "HTTPS-RR";

    alpn1 = cf_hc_get_httpsrr_alpn(cf, data, ALPN_none);
    if (alpn1 == ALPN_none) {
        source = "preferred version";
        alpn1 = cf_hc_get_pref_alpn(cf, data, ALPN_none);
    }
    if (alpn1 == ALPN_none) {
        source = "wanted versions";
        alpn1 = cf_hc_get_first_alpn(cf, data, wanted, ALPN_none);
    }
    if (alpn1 == ALPN_none) {
        source = "allowed versions";
        alpn1 = cf_hc_get_first_alpn(cf, data, allowed, ALPN_none);
    }

    if (alpn1 == ALPN_none) {
        if (ctx.check_h3_result != CURLE_OK) {
            trcCf(data, cf, "unable to use HTTP/3", .{});
            return ctx.check_h3_result;
        }
        trcCf(data, cf, "unable to select HTTP version", .{});
        return CURLE_FAILED_INIT;
    }

    cf_hc_baller_assign(&ctx.ballers[0], alpn1, ctx.def_transport);
    ctx.baller_count = 1;
    trcCf(data, cf, "1st attempt uses %s from %s", .{ ctx.ballers[0].name, source });

    if (alpn1 == ALPN_h1) {
        Curl_zig_data_set_http_neg_wanted(d, wanted & ~CURL_HTTP_V2x);
    }

    return CURLE_OK;
}

fn cf_hc_set_baller2(cf: *Curl_cfilter, data: ?*Curl_easy) void {
    const ctx: *cf_hc_ctx = @ptrCast(@alignCast(cf.ctx));
    const d = data orelse return;
    if (ctx.ballers_complete) return;
    if (!ctx.httpsrr_resolved) return;

    var wanted: u8 = 0;
    var allowed: u8 = 0;
    var preferred: u8 = 0;
    Curl_zig_data_get_http_neg(d, &wanted, &allowed, &preferred);

    const alpn1 = ctx.ballers[0].alpn_id;
    var alpn2: c_uint = ALPN_none;
    var source: [*:0]const u8 = "HTTPS-RR";

    alpn2 = cf_hc_get_httpsrr_alpn(cf, data, alpn1);
    if (alpn2 == ALPN_none) {
        source = "preferred version";
        alpn2 = cf_hc_get_pref_alpn(cf, data, alpn1);
    }
    if (alpn2 == ALPN_none) {
        source = "wanted versions";
        alpn2 = cf_hc_get_first_alpn(cf, data, wanted, alpn1);
    }

    if (alpn2 != ALPN_none) {
        cf_hc_baller_assign(&ctx.ballers[1], alpn2, ctx.def_transport);
        ctx.baller_count = 2;
        trcCf(data, cf, "2nd attempt uses %s from %s", .{ ctx.ballers[1].name, source });
    }
    ctx.ballers_complete = true;
}

fn cf_hc_connect(cf: *Curl_cfilter, data: ?*Curl_easy, done: *bool) callconv(.c) CURLcode {
    const ctx: *cf_hc_ctx = @ptrCast(@alignCast(cf.ctx));
    var result: CURLcode = CURLE_OK;

    if (cf.isConnected()) {
        done.* = true;
        return CURLE_OK;
    }

    done.* = false;

    if (!ctx.httpsrr_resolved) {
        ctx.httpsrr_resolved = true;
    }

    if (ctx.state == .CF_HC_RESOLV) {
        ctx.state = .CF_HC_INIT;
    }

    if (ctx.state == .CF_HC_INIT) {
        trcCf(data, cf, "connect, init", .{});
        result = cf_hc_set_baller1(cf, data);
        if (result != CURLE_OK) {
            ctx.result = result;
            ctx.state = .CF_HC_FAILURE;
            trcCf(data, cf, "connect -> %d, done=%d", .{ @as(c_int, @intCast(result)), @as(c_int, @intFromBool(done.*)) });
            return result;
        }
        cf_hc_set_baller2(cf, data);
        const pnow = Curl_pgrs_now(data);
        ctx.started = pnow.*;
        cf_hc_baller_init(&ctx.ballers[0], cf, data);
        if (ctx.baller_count > 1 or !ctx.ballers_complete) {
            Curl_expire_set(data, EXPIRE_ALPN_EYEBALLS, ctx.soft_eyeballs_timeout_ms, pnow);
        }
        ctx.state = .CF_HC_CONNECT;
    }

    switch (ctx.state) {
        .CF_HC_RESOLV, .CF_HC_INIT => unreachable,
        .CF_HC_CONNECT => {
            if (!ctx.ballers_complete) {
                cf_hc_set_baller2(cf, data);
            }

            if (cf_hc_baller_is_connecting(&ctx.ballers[0])) {
                result = cf_hc_baller_connect(&ctx.ballers[0], cf, data, done);
                if (result == CURLE_OK and done.*) {
                    result = baller_connected(cf, data, &ctx.ballers[0]);
                    trcCf(data, cf, "connect -> %d, done=%d", .{ @as(c_int, @intCast(result)), @as(c_int, @intFromBool(done.*)) });
                    return result;
                }
            }

            const pnow = Curl_pgrs_now(data);
            if (time_to_start_baller2(cf, data, pnow)) {
                cf_hc_baller_init(&ctx.ballers[1], cf, data);
            }

            if (cf_hc_baller_is_connecting(&ctx.ballers[1])) {
                result = cf_hc_baller_connect(&ctx.ballers[1], cf, data, done);
                if (result == CURLE_OK and done.*) {
                    result = baller_connected(cf, data, &ctx.ballers[1]);
                    trcCf(data, cf, "connect -> %d, done=%d", .{ @as(c_int, @intCast(result)), @as(c_int, @intFromBool(done.*)) });
                    return result;
                }
            }

            if (ctx.ballers[0].result != CURLE_OK and
                (ctx.ballers[1].result != CURLE_OK or (ctx.ballers_complete and ctx.baller_count < 2)))
            {
                trcCf(data, cf, "connect, all attempts failed", .{});
                result = ctx.ballers[0].result;
                ctx.result = result;
                ctx.state = .CF_HC_FAILURE;
                trcCf(data, cf, "connect -> %d, done=%d", .{ @as(c_int, @intCast(result)), @as(c_int, @intFromBool(done.*)) });
                return result;
            }
            result = CURLE_OK;
            done.* = false;
        },
        .CF_HC_FAILURE => {
            result = ctx.result;
            cf.setConnected(false);
            done.* = false;
        },
        .CF_HC_SUCCESS => {
            result = CURLE_OK;
            cf.setConnected(true);
            done.* = true;
        },
    }

    trcCf(data, cf, "connect -> %d, done=%d", .{ @as(c_int, @intCast(result)), @as(c_int, @intFromBool(done.*)) });
    return result;
}

fn cf_hc_shutdown(cf: *Curl_cfilter, data: ?*Curl_easy, done: *bool) callconv(.c) CURLcode {
    const ctx: *cf_hc_ctx = @ptrCast(@alignCast(cf.ctx));
    var result: CURLcode = CURLE_OK;

    if (cf.isConnected()) {
        done.* = true;
        return CURLE_OK;
    }

    var i: usize = 0;
    while (i < ctx.baller_count) : (i += 1) {
        const b = &ctx.ballers[i];
        var bdone: bool = false;
        if (!cf_hc_baller_is_connecting(b) or b.shutdown) continue;
        if (b.cf) |sub_cf| {
            b.result = sub_cf.cft.do_shutdown(sub_cf, data, &bdone);
            if (b.result != CURLE_OK or bdone) {
                b.shutdown = true;
            }
        }
    }

    done.* = true;
    i = 0;
    while (i < ctx.baller_count) : (i += 1) {
        if (!ctx.ballers[i].shutdown) {
            done.* = false;
        }
    }
    if (done.*) {
        i = 0;
        while (i < ctx.baller_count) : (i += 1) {
            if (ctx.ballers[i].result != CURLE_OK) {
                result = ctx.ballers[i].result;
            }
        }
    }
    trcCf(data, cf, "shutdown -> %d, done=%d", .{ @as(c_int, @intCast(result)), @as(c_int, @intFromBool(done.*)) });
    return result;
}

fn cf_hc_adjust_pollset(cf: *Curl_cfilter, data: ?*Curl_easy, ps_opaque: *vdns_cfilters.easy_pollset) callconv(.c) CURLcode {
    const ps: *easy_pollset = @ptrCast(@alignCast(ps_opaque));
    var result: CURLcode = CURLE_OK;
    if (!cf.isConnected()) {
        const ctx: *cf_hc_ctx = @ptrCast(@alignCast(cf.ctx));
        var i: usize = 0;
        while (i < ctx.baller_count and result == CURLE_OK) : (i += 1) {
            const b = &ctx.ballers[i];
            if (!cf_hc_baller_is_connecting(b)) continue;
            result = Curl_conn_cf_adjust_pollset(b.cf, data, ps);
        }
        trcCf(data, cf, "adjust_pollset -> %d, %u socks", .{ @as(c_int, @intCast(result)), ps.n });
    }
    return result;
}

fn cf_hc_data_pending(cf: *Curl_cfilter, data: ?*const Curl_easy) callconv(.c) bool {
    const ctx: *cf_hc_ctx = @ptrCast(@alignCast(cf.ctx));
    if (cf.isConnected()) {
        if (cf.next) |next_cf| {
            return next_cf.cft.has_data_pending(next_cf, data);
        }
        return false;
    }

    var i: usize = 0;
    while (i < ctx.baller_count) : (i += 1) {
        if (cf_hc_baller_data_pending(&ctx.ballers[i], data)) {
            return true;
        }
    }
    return false;
}

fn cf_hc_query(
    cf: *Curl_cfilter,
    data: ?*Curl_easy,
    query: c_int,
    pres1: ?*c_int,
    pres2: ?*anyopaque,
) callconv(.c) CURLcode {
    const ctx: *cf_hc_ctx = @ptrCast(@alignCast(cf.ctx));
    if (!cf.isConnected()) {
        if (query == CF_QUERY_NEED_FLUSH) {
            var i: usize = 0;
            while (i < ctx.baller_count) : (i += 1) {
                if (cf_hc_baller_needs_flush(&ctx.ballers[i], data)) {
                    if (pres1) |p1| p1.* = 1;
                    return CURLE_OK;
                }
            }
        }
    }
    if (cf.next) |next_cf| {
        return next_cf.cft.query(next_cf, data, query, pres1, pres2);
    }
    return CURLE_UNKNOWN_OPTION;
}

fn cf_hc_cntrl(
    cf: *Curl_cfilter,
    data: ?*Curl_easy,
    event: c_int,
    arg1: c_int,
    arg2: ?*anyopaque,
) callconv(.c) CURLcode {
    const ctx: *cf_hc_ctx = @ptrCast(@alignCast(cf.ctx));
    var result: CURLcode = CURLE_OK;

    if (!cf.isConnected()) {
        switch (event) {
            CF_CTRL_REPORT_STATS, CF_CTRL_CONN_INFO_UPDATE => {
                var i: usize = 0;
                while (i < ctx.baller_count) : (i += 1) {
                    if (Curl_conn_cf_is_ip_connected(ctx.ballers[i].cf, data)) {
                        _ = Curl_conn_cf_cntrl(ctx.ballers[i].cf, data, true, event, arg1, arg2);
                        break;
                    }
                }
            },
            else => {
                var i: usize = 0;
                while (i < ctx.baller_count) : (i += 1) {
                    result = cf_hc_baller_cntrl(&ctx.ballers[i], data, event, arg1, arg2);
                    if (result != CURLE_OK and result != CURLE_AGAIN) {
                        return result;
                    }
                }
                result = CURLE_OK;
            },
        }
    }
    return result;
}

fn cf_hc_destroy(cf: *Curl_cfilter, data: ?*Curl_easy) callconv(.c) void {
    const ctx: ?*cf_hc_ctx = @ptrCast(@alignCast(cf.ctx));
    trcCf(data, cf, "destroy", .{});
    cf_hc_ctx_destroy(data, ctx);
}

pub export var Curl_cft_http_connect: Curl_cftype = .{
    .name = "HTTPS-CONNECT",
    .flags = CF_TYPE_SETUP,
    .log_level = CURL_LOG_LVL_NONE,
    .destroy = cf_hc_destroy,
    .do_connect = cf_hc_connect,
    .do_shutdown = cf_hc_shutdown,
    .adjust_pollset = cf_hc_adjust_pollset,
    .has_data_pending = cf_hc_data_pending,
    .do_send = Curl_cf_def_send,
    .do_recv = Curl_cf_def_recv,
    .cntrl = cf_hc_cntrl,
    .is_alive = Curl_cf_def_conn_is_alive,
    .keep_alive = Curl_cf_def_conn_keep_alive,
    .query = cf_hc_query,
};

fn cf_hc_create(
    pcf: *?*Curl_cfilter,
    data: ?*Curl_easy,
    destination: ?*Curl_peer,
    def_transport: u8,
) CURLcode {
    var cf: ?*Curl_cfilter = null;
    const d = data orelse {
        pcf.* = null;
        return CURLE_FAILED_INIT;
    };

    const raw = mem.calloc(1, @sizeOf(cf_hc_ctx)) orelse {
        pcf.* = null;
        return CURLE_OUT_OF_MEMORY;
    };
    var ctx: ?*cf_hc_ctx = @ptrCast(@alignCast(raw));
    Curl_peer_link(&ctx.?.destination, destination);
    ctx.?.def_transport = def_transport;
    const he_timeout = Curl_zig_data_happy_eyeballs_timeout(d);
    ctx.?.hard_eyeballs_timeout_ms = he_timeout;
    ctx.?.soft_eyeballs_timeout_ms = @divTrunc(he_timeout, 2);

    const result = Curl_cf_create(&cf, &Curl_cft_http_connect, ctx);
    if (result == CURLE_OK) {
        ctx = null;
    }
    pcf.* = if (result != CURLE_OK) null else cf;
    cf_hc_ctx_destroy(data, ctx);
    return result;
}

fn cf_hc_add(
    data: ?*Curl_easy,
    destination: ?*Curl_peer,
    conn: ?*connectdata,
    sockindex: i8,
    def_transport: u8,
) CURLcode {
    var cf: ?*Curl_cfilter = null;
    const result = cf_hc_create(&cf, data, destination, def_transport);
    if (result != CURLE_OK) {
        return result;
    }
    Curl_conn_cf_add(data, conn, sockindex, cf.?);
    return CURLE_OK;
}

export fn Curl_cf_https_setup(
    data: ?*Curl_easy,
    destination: ?*Curl_peer,
    conn: ?*connectdata,
    sockindex: i8,
) callconv(.c) CURLcode {
    const c = conn orelse return CURLE_OK;
    if (!Curl_zig_conn_should_https_setup(c)) {
        return CURLE_OK;
    }
    return cf_hc_add(
        data,
        destination,
        c,
        sockindex,
        Curl_zig_conn_get_transport_wanted(c),
    );
}

// ============================================================================
// 3. lib/cf-ip-happy.c
// ============================================================================

const transport_provider = struct {
    cf_create: cf_ip_connect_create,
    transport: u8,
    tunnel: bool,
};

var transport_providers = [_]transport_provider{
    .{ .cf_create = Curl_cf_tcp_create, .transport = TRNSPRT_TCP, .tunnel = false },
    .{ .cf_create = Curl_cf_tcp_create, .transport = TRNSPRT_TCP, .tunnel = true },
    .{ .cf_create = Curl_cf_udp_create, .transport = TRNSPRT_UDP, .tunnel = false },
    .{ .cf_create = Curl_cf_unix_create, .transport = TRNSPRT_UNIX, .tunnel = false },
    .{ .cf_create = Curl_cf_unix_create, .transport = TRNSPRT_UNIX, .tunnel = true },
};

fn get_cf_create(transport: u8, tunnel: bool) ?cf_ip_connect_create {
    for (&transport_providers) |*p| {
        if (transport == p.transport and tunnel == p.tunnel) {
            return p.cf_create;
        }
    }
    return null;
}

export fn debug_set_transport_provider(transport: u8, cf_create: cf_ip_connect_create) callconv(.c) void {
    for (&transport_providers) |*p| {
        if (transport == p.transport) {
            p.cf_create = cf_create;
        }
    }
}

const cf_ai_iter = struct {
    cf: ?*Curl_cfilter = null,
    peer: ?*Curl_peer = null,
    ai_family: c_int = 0,
    n: c_uint = 0,
};

fn cf_ai_iter_init(iter: *cf_ai_iter, cf: *Curl_cfilter, peer: ?*Curl_peer, ai_family: c_int) void {
    iter.cf = cf;
    iter.peer = peer;
    iter.ai_family = ai_family;
    iter.n = 0;
}

fn cf_ai_iter_next(iter: *cf_ai_iter, data: ?*Curl_easy) ?*const Curl_addrinfo {
    const cf = iter.cf orelse return null;
    const addr = Curl_conn_dns_get_ai(data, iter.peer, cf.sockindex, iter.ai_family, iter.n);
    if (addr != null) {
        iter.n += 1;
    }
    return addr;
}

fn cf_ai_iter_has_more(iter: *const cf_ai_iter, data: ?*Curl_easy) bool {
    const cf = iter.cf orelse return false;
    return Curl_conn_dns_get_ai(data, iter.peer, cf.sockindex, iter.ai_family, iter.n) != null;
}

const cf_ip_attempt = struct {
    next: ?*cf_ip_attempt,
    origin: ?*Curl_peer,
    peer: ?*Curl_peer,
    tunnel_peer: ?*Curl_peer,
    addr: Curl_sockaddr_ex,
    cf: ?*Curl_cfilter,
    cf_create: cf_ip_connect_create,
    result: CURLcode,
    ai_family: c_int,
    transport_peer: u8,
    tunnel_transport: u8,
    error_code: c_int,
    connected: bool,
    shutdown: bool,
    inconclusive: bool,
};

fn cf_ip_attempt_free(a_opt: ?*cf_ip_attempt, data: ?*Curl_easy) void {
    const a = a_opt orelse return;
    if (a.cf != null) {
        Curl_conn_cf_discard_chain(&a.cf, data);
    }
    Curl_peer_unlink(&a.origin);
    Curl_peer_unlink(&a.peer);
    Curl_peer_unlink(&a.tunnel_peer);
    mem.free(a);
}

fn cf_ip_attempt_new(
    pa: *?*cf_ip_attempt,
    data: ?*Curl_easy,
    cf: *Curl_cfilter,
    origin: ?*Curl_peer,
    peer: ?*Curl_peer,
    transport_peer: u8,
    addr: *const Curl_sockaddr_ex,
    ai_family: c_int,
    tunnel_peer: ?*Curl_peer,
    tunnel_transport: u8,
    cf_create: cf_ip_connect_create,
) CURLcode {
    pa.* = null;
    const raw = mem.calloc(1, @sizeOf(cf_ip_attempt)) orelse return CURLE_OUT_OF_MEMORY;
    const a: *cf_ip_attempt = @ptrCast(@alignCast(raw));

    Curl_peer_link(&a.origin, origin);
    Curl_peer_link(&a.peer, peer);
    a.transport_peer = transport_peer;
    Curl_peer_link(&a.tunnel_peer, tunnel_peer);
    a.tunnel_transport = tunnel_transport;
    a.addr = addr.*;
    a.ai_family = ai_family;
    a.result = CURLE_OK;
    a.cf_create = cf_create;
    pa.* = a;

    const result = a.cf_create(
        &a.cf,
        data,
        a.origin,
        a.peer,
        a.transport_peer,
        cf.conn,
        &a.addr,
        a.tunnel_peer,
        a.tunnel_transport,
    );
    if (result != CURLE_OK) {
        cf_ip_attempt_free(a, data);
        pa.* = null;
        return result;
    }

    var wcf = a.cf;
    while (wcf) |sub_cf| : (wcf = sub_cf.next) {
        sub_cf.conn = cf.conn;
        sub_cf.sockindex = cf.sockindex;
    }
    return CURLE_OK;
}

fn cf_ip_attempt_connect(a: *cf_ip_attempt, data: ?*Curl_easy, connected: *bool) CURLcode {
    connected.* = a.connected;
    if (a.result == CURLE_OK and !connected.*) {
        a.result = Curl_conn_cf_connect(a.cf, data, connected);
        if (a.result == CURLE_OK) {
            if (connected.*) {
                a.connected = true;
            }
        } else {
            if (a.result == CURLE_WEIRD_SERVER_REPLY) {
                a.inconclusive = true;
            }
            if (a.cf != null) {
                Curl_conn_cf_discard_chain(&a.cf, data);
            }
        }
    }
    return a.result;
}

const cf_ip_ballers = struct {
    running: ?*cf_ip_attempt,
    running_tail: *?*cf_ip_attempt,
    winner: ?*cf_ip_attempt,
    addr_iter: cf_ai_iter,
    ipv6_iter: cf_ai_iter,
    origin: ?*Curl_peer,
    peer: ?*Curl_peer,
    tunnel_peer: ?*Curl_peer,
    cf_create: ?cf_ip_connect_create,
    last_attempt_started: Curltime,
    attempt_delay_ms: timediff_t,
    last_dead_result: CURLcode,
    last_attempt_ai_family: c_int,
    max_concurrent: u32,
    transport_peer: u8,
    tunnel_transport: u8,
    had_dead: bool,
};

fn cf_ip_attempt_restart(a: *cf_ip_attempt, cf: *Curl_cfilter, data: ?*Curl_easy) CURLcode {
    if (a.cf != null) {
        Curl_conn_cf_discard_chain(&a.cf, data);
    }
    a.result = CURLE_OK;
    a.connected = false;
    a.inconclusive = false;
    a.cf = null;

    const result = a.cf_create(
        &a.cf,
        data,
        a.origin,
        a.peer,
        a.transport_peer,
        cf.conn,
        &a.addr,
        a.tunnel_peer,
        a.tunnel_transport,
    );
    if (result == CURLE_OK) {
        var dummy: bool = false;
        var wcf = a.cf;
        while (wcf) |sub_cf| : (wcf = sub_cf.next) {
            sub_cf.conn = cf.conn;
            sub_cf.sockindex = cf.sockindex;
        }
        a.result = cf_ip_attempt_connect(a, data, &dummy);
    }
    return result;
}

fn cf_ip_ballers_clear(data: ?*Curl_easy, bs: *cf_ip_ballers) void {
    while (bs.running) |a| {
        bs.running = a.next;
        cf_ip_attempt_free(a, data);
    }
    bs.running_tail = &bs.running;
    cf_ip_attempt_free(bs.winner, data);
    bs.winner = null;
    Curl_peer_unlink(&bs.origin);
    Curl_peer_unlink(&bs.peer);
    Curl_peer_unlink(&bs.tunnel_peer);
}

fn cf_ip_ballers_init(
    bs: *cf_ip_ballers,
    data: ?*Curl_easy,
    origin: ?*Curl_peer,
    peer: ?*Curl_peer,
    transport_peer: u8,
    tunnel_peer: ?*Curl_peer,
    tunnel_transport: u8,
    attempt_delay_ms: timediff_t,
    max_concurrent: u32,
) CURLcode {
    bs.* = .{
        .running = null,
        .running_tail = &bs.running,
        .winner = null,
        .addr_iter = .{},
        .ipv6_iter = .{},
        .origin = null,
        .peer = null,
        .tunnel_peer = null,
        .cf_create = get_cf_create(transport_peer, tunnel_peer != null),
        .last_attempt_started = .{ .tv_sec = 0, .tv_usec = 0 },
        .attempt_delay_ms = attempt_delay_ms,
        .last_dead_result = CURLE_OK,
        .last_attempt_ai_family = AF_INET,
        .max_concurrent = max_concurrent,
        .transport_peer = transport_peer,
        .tunnel_transport = tunnel_transport,
        .had_dead = false,
    };
    if (bs.cf_create == null) {
        const proxy_suffix: [*:0]const u8 = if (tunnel_peer != null) " to proxy" else "";
        failf(data, "unsupported transport type %u%s", .{ @as(c_uint, transport_peer), proxy_suffix });
        return CURLE_UNSUPPORTED_PROTOCOL;
    }
    Curl_peer_link(&bs.origin, origin);
    Curl_peer_link(&bs.peer, peer);
    Curl_peer_link(&bs.tunnel_peer, tunnel_peer);
    return CURLE_OK;
}

fn cf_ip_ballers_prune(
    bs: *cf_ip_ballers,
    cf: *Curl_cfilter,
    data: ?*Curl_easy,
    max_concurrent: u32,
) void {
    var ongoing: u32 = 0;
    var cur = bs.running;
    while (cur) |a| : (cur = a.next) {
        if (a.result == CURLE_OK and !a.connected) {
            ongoing += 1;
        }
    }

    var panchor: *?*cf_ip_attempt = &bs.running;
    while (panchor.* != null and ongoing > max_concurrent) {
        const a = panchor.*.?;
        if (a.result == CURLE_OK and !a.connected) {
            panchor.* = a.next;
            if (a.next == null) {
                bs.running_tail = panchor;
            }
            a.next = null;
            cf_ip_attempt_free(a, data);
            ongoing -= 1;
            trcCf(data, cf, "discarding oldest attempt to keep limit", .{});
        } else {
            panchor = &a.next;
        }
    }
}

fn cf_ip_ballers_run(
    bs: *cf_ip_ballers,
    cf: *Curl_cfilter,
    data: ?*Curl_easy,
    dns_resolved: bool,
    connected: *bool,
) CURLcode {
    var result: CURLcode = CURLE_OK;

    if (bs.winner != null) {
        return CURLE_OK;
    }

    evaluate: while (true) {
        if (Curl_timeleft_now_ms(data, Curl_pgrs_now(data)) < 0) {
            failf(
                data,
                "Connection timeout after %lld ms",
                .{@as(c_longlong, Curl_pgrs_since_ms(data, null, TIMER_STARTSINGLE))},
            );
            return CURLE_OPERATION_TIMEDOUT;
        }

        var ongoing: u32 = 0;
        var inconclusive: u32 = 0;
        var i: c_int = -1;

        var panchor: *?*cf_ip_attempt = &bs.running;
        while (panchor.*) |a| {
            i += 1;
            a.result = cf_ip_attempt_connect(a, data, connected);
            if (a.result == CURLE_OK) {
                if (connected.*) {
                    trcCf(data, cf, "connect attempt #%d successful", .{i});
                    bs.winner = a;
                    panchor.* = a.next;
                    a.next = null;
                    while (bs.running) |rem| {
                        bs.running = rem.next;
                        cf_ip_attempt_free(rem, data);
                    }
                    bs.running_tail = &bs.running;
                    return CURLE_OK;
                }
                ongoing += 1;
                panchor = &a.next;
            } else if (a.inconclusive) {
                inconclusive += 1;
                panchor = &a.next;
            } else {
                panchor.* = a.next;
                if (a.next == null) {
                    bs.running_tail = panchor;
                }
                a.next = null;
                bs.last_dead_result = a.result;
                bs.had_dead = true;
                cf_ip_attempt_free(a, data);
            }
        }
        if (bs.running != null) {
            trcCf(data, cf, "checked connect attempts: %u ongoing, %u inconclusive", .{ ongoing, inconclusive });
        }

        const pnow = Curl_pgrs_now(data);
        var do_more: bool = false;
        if (ongoing == 0) {
            do_more = true;
        } else {
            var more_possible = cf_ai_iter_has_more(&bs.addr_iter, data);
            if (!more_possible) {
                more_possible = cf_ai_iter_has_more(&bs.ipv6_iter, data);
            }
            do_more = more_possible and
                (curlx_time_net.curlx_ptimediff_ms(pnow, &bs.last_attempt_started) >= bs.attempt_delay_ms);
            if (do_more) {
                trcCf(data, cf, "happy eyeballs timeout expired, start next attempt", .{});
            }
        }

        if (do_more) {
            var ai: ?*const Curl_addrinfo = null;
            var ai_family: c_int = 0;
            trcCf(data, cf, "want to do more", .{});
            if (bs.last_attempt_ai_family == AF_INET or !cf_ai_iter_has_more(&bs.addr_iter, data)) {
                ai = cf_ai_iter_next(&bs.ipv6_iter, data);
                ai_family = bs.ipv6_iter.ai_family;
                const found_str: [*:0]const u8 = if (ai != null) "found" else "none";
                trcCf(data, cf, "check for next AAAA address: %s", .{found_str});
            }
            if (ai == null) {
                ai = cf_ai_iter_next(&bs.addr_iter, data);
                ai_family = bs.addr_iter.ai_family;
                const found_str: [*:0]const u8 = if (ai != null) "found" else "none";
                trcCf(data, cf, "check for next A address: %s", .{found_str});
            }

            Curl_reset_fail(data);

            if (ai) |ai_ptr| {
                var addr: Curl_sockaddr_ex = undefined;
                if (bs.max_concurrent != 0) {
                    cf_ip_ballers_prune(bs, cf, data, bs.max_concurrent - 1);
                }

                result = Curl_socket_addr_from_ai(&addr, ai_ptr, bs.transport_peer);
                if (result != CURLE_OK) {
                    break :evaluate;
                }

                var new_a: ?*cf_ip_attempt = null;
                result = cf_ip_attempt_new(
                    &new_a,
                    data,
                    cf,
                    bs.origin,
                    bs.peer,
                    bs.transport_peer,
                    &addr,
                    ai_family,
                    bs.tunnel_peer,
                    bs.tunnel_transport,
                    bs.cf_create.?,
                );
                const which_str: [*:0]const u8 = if (bs.running != null) "next" else "first";
                const fam_str: [*:0]const u8 = if (ai_family == AF_INET) "4" else "6";
                trcCf(
                    data,
                    cf,
                    "starting %s attempt for ipv%s -> %d",
                    .{ which_str, fam_str, @as(c_int, @intCast(result)) },
                );
                if (result != CURLE_OK) {
                    break :evaluate;
                }

                const a = new_a.?;
                bs.running_tail.* = a;
                a.next = null;
                bs.running_tail = &a.next;
                bs.last_attempt_started = pnow.*;
                bs.last_attempt_ai_family = ai_family;
                continue :evaluate;
            } else if (inconclusive != 0) {
                const since_ms = curlx_time_net.curlx_ptimediff_ms(pnow, &bs.last_attempt_started);
                const delay_ms = bs.attempt_delay_ms - since_ms;
                if (delay_ms <= 0) {
                    trcCf(data, cf, "all attempts inconclusive, restarting one", .{});
                    i = -1;
                    var cur = bs.running;
                    while (cur) |a| : (cur = a.next) {
                        i += 1;
                        if (!a.inconclusive) continue;
                        result = cf_ip_attempt_restart(a, cf, data);
                        trcCf(data, cf, "restarted baller %d -> %d", .{ i, @as(c_int, @intCast(result)) });
                        if (result != CURLE_OK) {
                            break :evaluate;
                        }
                        bs.last_attempt_started = pnow.*;
                        continue :evaluate;
                    }
                } else {
                    infof(
                        data,
                        "connect attempts inconclusive, retrying in %lldms",
                        .{@as(c_longlong, delay_ms)},
                    );
                    Curl_expire_set(data, EXPIRE_HAPPY_EYEBALLS, delay_ms, pnow);
                }
                break :evaluate;
            } else if (ongoing == 0 and dns_resolved) {
                trcCf(data, cf, "no more attempts to try", .{});
                result = if (bs.had_dead) bs.last_dead_result else CURLE_COULDNT_CONNECT;
            }
        }

        if (result == CURLE_OK) {
            const now2 = Curl_pgrs_now(data);
            var next_expire_ms = Curl_timeleft_now_ms(data, now2);
            if (next_expire_ms < 0) {
                failf(
                    data,
                    "Connection timeout after %lld ms",
                    .{@as(c_longlong, Curl_pgrs_since_ms(data, null, TIMER_STARTSINGLE))},
                );
                return CURLE_OPERATION_TIMEDOUT;
            }

            var more_possible = cf_ai_iter_has_more(&bs.addr_iter, data);
            if (!more_possible) {
                more_possible = cf_ai_iter_has_more(&bs.ipv6_iter, data);
            }
            if (more_possible) {
                const elapsed_ms = curlx_time_net.curlx_ptimediff_ms(now2, &bs.last_attempt_started);
                const expire_ms = @max(bs.attempt_delay_ms - elapsed_ms, @as(timediff_t, 0));
                next_expire_ms = @min(next_expire_ms, expire_ms);
                if (next_expire_ms <= 0) {
                    trcCf(data, cf, "HAPPY_EYEBALLS timeout due, re-evaluate", .{});
                    continue :evaluate;
                }
                trcCf(
                    data,
                    cf,
                    "next HAPPY_EYEBALLS timeout in %lldms",
                    .{@as(c_longlong, next_expire_ms)},
                );
                Curl_expire_set(data, EXPIRE_HAPPY_EYEBALLS, next_expire_ms, now2);
            }
        }
        break :evaluate;
    }
    return result;
}

fn cf_ip_ballers_shutdown(bs: *cf_ip_ballers, data: ?*Curl_easy, done: *bool) CURLcode {
    done.* = true;
    var cur = bs.running;
    while (cur) |a| : (cur = a.next) {
        var bdone: bool = false;
        const sub_cf = a.cf orelse continue;
        if (a.shutdown) continue;
        a.result = sub_cf.cft.do_shutdown(sub_cf, data, &bdone);
        if (a.result != CURLE_OK or bdone) {
            a.shutdown = true;
        } else {
            done.* = false;
        }
    }
    return CURLE_OK;
}

fn cf_ip_ballers_pollset(bs: *cf_ip_ballers, data: ?*Curl_easy, ps: *easy_pollset) CURLcode {
    var result: CURLcode = CURLE_OK;
    var cur = bs.running;
    while (cur != null and result == CURLE_OK) : (cur = cur.?.next) {
        const a = cur.?;
        if (a.result != CURLE_OK) continue;
        result = Curl_conn_cf_adjust_pollset(a.cf, data, ps);
    }
    return result;
}

fn cf_ip_ballers_pending(bs: *const cf_ip_ballers, data: ?*const Curl_easy) bool {
    var cur = bs.running;
    while (cur) |a| : (cur = a.next) {
        if (a.result != CURLE_OK) continue;
        if (a.cf) |sub_cf| {
            if (sub_cf.cft.has_data_pending(sub_cf, data)) {
                return true;
            }
        }
    }
    return false;
}

fn cf_ip_ballers_min_reply_ms(bs: *cf_ip_ballers, data: ?*Curl_easy) c_int {
    var reply_ms: c_int = -1;
    var cur = bs.running;
    while (cur) |a| : (cur = a.next) {
        if (a.cf) |sub_cf| {
            var breply_ms: c_int = -1;
            if (sub_cf.cft.query(sub_cf, data, CF_QUERY_CONNECT_REPLY_MS, &breply_ms, null) == CURLE_OK and
                breply_ms >= 0 and (reply_ms < 0 or breply_ms < reply_ms))
            {
                reply_ms = breply_ms;
            }
        }
    }
    return reply_ms;
}

const cf_connect_state = enum(c_int) {
    SCFST_INIT = 0,
    SCFST_WAITING = 1,
    SCFST_DONE = 2,
};

const cf_ip_happy_ctx = struct {
    cf_create: ?cf_ip_connect_create,
    state: cf_connect_state,
    ballers: cf_ip_ballers,
    dns_resolved: bool,
};

fn is_connected(cf: *Curl_cfilter, data: ?*Curl_easy, connected: *bool) CURLcode {
    const ctx: *cf_ip_happy_ctx = @ptrCast(@alignCast(cf.ctx));
    const conn = cf.conn orelse return CURLE_FAILED_INIT;
    var result = cf_ip_ballers_run(&ctx.ballers, cf, data, ctx.dns_resolved, connected);
    if (result == CURLE_OK) {
        return CURLE_OK;
    }

    const peer = Curl_conn_get_first_peer(conn, cf.sockindex);
    var origin: ?*Curl_peer = null;
    var socks_proxy_peer: ?*Curl_peer = null;
    var http_proxy_peer: ?*Curl_peer = null;
    Curl_zig_conn_get_peers(conn, &origin, &socks_proxy_peer, &http_proxy_peer);

    if (origin == null or peer == null) {
        return CURLE_FAILED_INIT;
    }

    const proxy_peer: ?*Curl_peer = socks_proxy_peer orelse http_proxy_peer;

    var viamsg: [160]u8 = undefined;
    viamsg[0] = 0;
    if (!Curl_peer_equal(peer, origin) and !Curl_peer_equal(peer, proxy_peer)) {
        if (peer.?.isUnixSocket()) {
            _ = curl_msnprintf(&viamsg, viamsg.len, " over unix://%s", peer.?.hostname.?);
        } else {
            _ = curl_msnprintf(&viamsg, viamsg.len, " via %s:%u", peer.?.hostname.?, @as(c_uint, peer.?.port));
        }
    }

    const viamsg_ptr: [*:0]const u8 = @ptrCast(&viamsg);
    const over_proxy: [*:0]const u8 = if (proxy_peer != null) "over proxy " else "";
    const proxy_host: [*:0]const u8 = if (proxy_peer) |pp| pp.hostname.? else "";
    const proxy_space: [*:0]const u8 = if (proxy_peer != null) " " else "";

    failf(
        data,
        "Failed to connect to %s:%u%s %s%s%safter %lld ms: %s",
        .{
            origin.?.hostname.?,
            @as(c_uint, origin.?.port),
            viamsg_ptr,
            over_proxy,
            proxy_host,
            proxy_space,
            @as(c_longlong, Curl_pgrs_since_ms(data, null, TIMER_STARTSINGLE)),
            curl_easy_strerror(result),
        },
    );

    if (data) |d| {
        if (Curl_zig_data_is_os_errno_timedout(d)) {
            result = CURLE_OPERATION_TIMEDOUT;
        }
    }

    return result;
}

const IP_HE_MAX_CONCURRENT_ATTEMPTS: u32 = 6;

fn cf_ip_happy_init(cf: *Curl_cfilter, data: ?*Curl_easy) CURLcode {
    const ctx: *cf_ip_happy_ctx = @ptrCast(@alignCast(cf.ctx));

    if (Curl_timeleft_ms(data) < 0) {
        failf(data, "Connection time-out", .{});
        return CURLE_OPERATION_TIMEDOUT;
    }

    if (ctx.ballers.transport_peer == TRNSPRT_UNIX) {
        cf_ai_iter_init(&ctx.ballers.addr_iter, cf, ctx.ballers.peer, AF_UNIX);
    } else {
        cf_ai_iter_init(&ctx.ballers.ipv6_iter, cf, ctx.ballers.peer, AF_INET6);
        cf_ai_iter_init(&ctx.ballers.addr_iter, cf, ctx.ballers.peer, AF_INET);
    }

    trcCf(data, cf, "init ip ballers for transport %u", .{@as(c_uint, ctx.ballers.transport_peer)});
    return CURLE_OK;
}

fn cf_ip_happy_ctx_clear(ctx_opt: ?*cf_ip_happy_ctx, data: ?*Curl_easy) void {
    const ctx = ctx_opt orelse return;
    cf_ip_ballers_clear(data, &ctx.ballers);
}

fn cf_ip_happy_ctx_destroy(ctx_opt: ?*cf_ip_happy_ctx, data: ?*Curl_easy) void {
    const ctx = ctx_opt orelse return;
    cf_ip_happy_ctx_clear(ctx, data);
    mem.free(ctx);
}

fn cf_ip_happy_shutdown(cf: *Curl_cfilter, data: ?*Curl_easy, done: *bool) callconv(.c) CURLcode {
    const ctx: *cf_ip_happy_ctx = @ptrCast(@alignCast(cf.ctx));
    if (cf.isConnected()) {
        done.* = true;
        return CURLE_OK;
    }

    const result = cf_ip_ballers_shutdown(&ctx.ballers, data, done);
    trcCf(data, cf, "shutdown -> %d, done=%d", .{ @as(c_int, @intCast(result)), @as(c_int, @intFromBool(done.*)) });
    return result;
}

fn cf_ip_happy_adjust_pollset(cf: *Curl_cfilter, data: ?*Curl_easy, ps_opaque: *vdns_cfilters.easy_pollset) callconv(.c) CURLcode {
    const ps: *easy_pollset = @ptrCast(@alignCast(ps_opaque));
    const ctx: *cf_ip_happy_ctx = @ptrCast(@alignCast(cf.ctx));
    var result: CURLcode = CURLE_OK;
    if (!cf.isConnected()) {
        result = cf_ip_ballers_pollset(&ctx.ballers, data, ps);
        trcCf(data, cf, "adjust_pollset -> %d, %u socks", .{ @as(c_int, @intCast(result)), ps.n });
    }
    return result;
}

fn cf_ip_happy_connect(cf: *Curl_cfilter, data: ?*Curl_easy, done: *bool) callconv(.c) CURLcode {
    const ctx: *cf_ip_happy_ctx = @ptrCast(@alignCast(cf.ctx));
    const d = data orelse return CURLE_FAILED_INIT;
    var result: CURLcode = CURLE_OK;

    if (cf.isConnected()) {
        done.* = true;
        return CURLE_OK;
    }

    done.* = false;

    if (!ctx.dns_resolved) {
        result = Curl_conn_dns_addr_result(cf.conn, cf.sockindex, ctx.ballers.peer);
        if (result == CURLE_OK) {
            ctx.dns_resolved = true;
        } else if (result == CURLE_AGAIN) {
            result = CURLE_OK;
        } else {
            return result;
        }
    }

    if (ctx.state == .SCFST_INIT) {
        result = cf_ip_happy_init(cf, d);
        if (result != CURLE_OK) {
            return result;
        }
        ctx.state = .SCFST_WAITING;
    }

    switch (ctx.state) {
        .SCFST_INIT => unreachable,
        .SCFST_WAITING => {
            result = is_connected(cf, d, done);
            if (result == CURLE_OK and done.*) {
                ctx.state = .SCFST_DONE;
                cf.setConnected(true);
                cf.next = ctx.ballers.winner.?.cf;
                ctx.ballers.winner.?.cf = null;

                if (cf.conn) |conn| {
                    if (Curl_zig_conn_is_ssh(conn)) {
                        Curl_pgrsTime(d, TIMER_APPCONNECT);
                    }
                }
                if (Curl_zig_trc_cf_is_verbose(cf, d)) {
                    var ipquad: ip_quadruple = undefined;
                    var is_ipv6: bool = false;
                    if (Curl_conn_cf_get_ip_info(cf.next, d, &is_ipv6, &ipquad) == CURLE_OK) {
                        const remote_ip_ptr: [*:0]const u8 = @ptrCast(&ipquad.remote_ip);
                        trcCf(
                            d,
                            cf,
                            "Connected to %s (%s) port %u",
                            .{ ctx.ballers.peer.?.hostname.?, remote_ip_ptr, @as(c_uint, ipquad.remote_port) },
                        );
                    }
                }
                cf_ip_happy_ctx_clear(ctx, d);
                Curl_expire_clear(d, EXPIRE_HAPPY_EYEBALLS);
                Curl_reset_fail(d);
                Curl_zig_data_inc_numconnects(d);
            }
        },
        .SCFST_DONE => {
            done.* = true;
        },
    }
    return result;
}

fn cf_ip_happy_data_pending(cf: *Curl_cfilter, data: ?*const Curl_easy) callconv(.c) bool {
    const ctx: *cf_ip_happy_ctx = @ptrCast(@alignCast(cf.ctx));
    if (!cf.isConnected()) {
        return cf_ip_ballers_pending(&ctx.ballers, data);
    }
    if (cf.next) |next_cf| {
        return next_cf.cft.has_data_pending(next_cf, data);
    }
    return false;
}

fn cf_ip_happy_query(
    cf: *Curl_cfilter,
    data: ?*Curl_easy,
    query: c_int,
    pres1: ?*c_int,
    pres2: ?*anyopaque,
) callconv(.c) CURLcode {
    const ctx: *cf_ip_happy_ctx = @ptrCast(@alignCast(cf.ctx));
    if (!cf.isConnected()) {
        if (query == CF_QUERY_CONNECT_REPLY_MS) {
            const r = cf_ip_ballers_min_reply_ms(&ctx.ballers, data);
            if (pres1) |p1| p1.* = r;
            trcCf(data, cf, "query connect reply: %dms", .{r});
            return CURLE_OK;
        }
    }
    if (cf.next) |next_cf| {
        return next_cf.cft.query(next_cf, data, query, pres1, pres2);
    }
    return CURLE_UNKNOWN_OPTION;
}

fn cf_ip_happy_destroy(cf: *Curl_cfilter, data: ?*Curl_easy) callconv(.c) void {
    const ctx: ?*cf_ip_happy_ctx = @ptrCast(@alignCast(cf.ctx));
    trcCf(data, cf, "destroy", .{});
    if (ctx) |c| {
        cf_ip_happy_ctx_clear(c, data);
        cf_ip_happy_ctx_destroy(c, data);
    }
}

pub export var Curl_cft_ip_happy: Curl_cftype = .{
    .name = "HAPPY-EYEBALLS",
    .flags = CF_TYPE_SETUP,
    .log_level = CURL_LOG_LVL_NONE,
    .destroy = cf_ip_happy_destroy,
    .do_connect = cf_ip_happy_connect,
    .do_shutdown = cf_ip_happy_shutdown,
    .adjust_pollset = cf_ip_happy_adjust_pollset,
    .has_data_pending = cf_ip_happy_data_pending,
    .do_send = Curl_cf_def_send,
    .do_recv = Curl_cf_def_recv,
    .cntrl = Curl_cf_def_cntrl,
    .is_alive = Curl_cf_def_conn_is_alive,
    .keep_alive = Curl_cf_def_conn_keep_alive,
    .query = cf_ip_happy_query,
};

fn cf_ip_happy_create(
    pcf: *?*Curl_cfilter,
    data: ?*Curl_easy,
    origin: ?*Curl_peer,
    peer: ?*Curl_peer,
    transport_peer: u8,
    conn: ?*connectdata,
    tunnel_peer: ?*Curl_peer,
    tunnel_transport: u8,
) CURLcode {
    _ = conn;
    pcf.* = null;
    const d = data orelse return CURLE_FAILED_INIT;
    const raw = mem.calloc(1, @sizeOf(cf_ip_happy_ctx)) orelse return CURLE_OUT_OF_MEMORY;
    const ctx: *cf_ip_happy_ctx = @ptrCast(@alignCast(raw));

    var result = cf_ip_ballers_init(
        &ctx.ballers,
        d,
        origin,
        peer,
        transport_peer,
        tunnel_peer,
        tunnel_transport,
        Curl_zig_data_happy_eyeballs_timeout(d),
        IP_HE_MAX_CONCURRENT_ATTEMPTS,
    );
    if (result == CURLE_OK) {
        result = Curl_cf_create(pcf, &Curl_cft_ip_happy, ctx);
    }
    if (result != CURLE_OK) {
        if (pcf.*) |cf| {
            mem.free(cf);
            pcf.* = null;
        }
        cf_ip_happy_ctx_destroy(ctx, d);
    }
    return result;
}

export fn Curl_cf_ip_happy_insert_after(
    cf_at: *Curl_cfilter,
    data: ?*Curl_easy,
    origin: ?*Curl_peer,
    peer: ?*Curl_peer,
    transport_peer: u8,
    tunnel_peer: ?*Curl_peer,
    tunnel_transport: u8,
) callconv(.c) CURLcode {
    var cf: ?*Curl_cfilter = null;
    const result = cf_ip_happy_create(
        &cf,
        data,
        origin,
        peer,
        transport_peer,
        cf_at.conn,
        tunnel_peer,
        tunnel_transport,
    );
    if (result != CURLE_OK) {
        return result;
    }
    Curl_conn_cf_insert_after(cf_at, cf.?);
    return CURLE_OK;
}

// ============================================================================
// 4. lib/vdns/asyn-thrdd.c
// ============================================================================

const CURL_ASYN_ITEM_DESC_LEN: usize = 64;

const AI_NUMERICSERV: c_int = switch (builtin.os.tag) {
    .windows => 0x00000008,
    .macos, .ios, .tvos, .watchos, .visionos => 0x1000,
    else => 0x0400,
};

const AI_ADDRCONFIG: c_int = switch (builtin.os.tag) {
    .windows => 0x00000400,
    .macos, .ios, .tvos, .watchos, .visionos => 0x0400,
    else => 0x0020,
};

const CURL_THRDQ_EV_ITEM_DONE: c_int = 0;

const Curl_thrdq_item_free_cb = *const fn (item: ?*anyopaque) callconv(.c) void;
const Curl_thrdq_item_process_cb = *const fn (item: ?*anyopaque) callconv(.c) void;
const Curl_thrdq_ev_cb = *const fn (tqueue: ?*const curl_thrdq, ev: c_int, user_data: ?*anyopaque) callconv(.c) void;
const Curl_thrdq_item_match_cb = *const fn (item: ?*anyopaque, match_data: ?*anyopaque) callconv(.c) bool;

extern fn Curl_thrdq_create(
    ptqueue: *?*curl_thrdq,
    name: [*:0]const u8,
    min_threads: u32,
    max_threads: u32,
    idle_time_ms: u32,
    fn_free: Curl_thrdq_item_free_cb,
    fn_process: Curl_thrdq_item_process_cb,
    fn_event: ?Curl_thrdq_ev_cb,
    user_data: ?*anyopaque,
) callconv(.c) CURLcode;
extern fn Curl_thrdq_destroy(tqueue: ?*curl_thrdq, join: bool) callconv(.c) void;
extern fn Curl_thrdq_send(tqueue: ?*curl_thrdq, item: ?*anyopaque, description: ?[*:0]const u8, timeout_ms: timediff_t) callconv(.c) CURLcode;
extern fn Curl_thrdq_recv(tqueue: ?*curl_thrdq, pitem: *?*anyopaque) callconv(.c) CURLcode;
extern fn Curl_thrdq_check_started(tqueue: ?*curl_thrdq) callconv(.c) bool;
extern fn Curl_thrdq_clear(tqueue: ?*curl_thrdq, fn_match: Curl_thrdq_item_match_cb, match_data: ?*anyopaque) callconv(.c) void;
extern fn Curl_thrdq_set_props(tqueue: ?*curl_thrdq, min_threads: u32, max_threads: u32, idle_time_ms: u32) callconv(.c) CURLcode;

extern fn Curl_freeaddrinfo(cahead: ?*Curl_addrinfo) callconv(.c) void;
extern fn Curl_getaddrinfo_ex(
    nodename: ?[*:0]const u8,
    servname: ?[*:0]const u8,
    hints: *const CAddrinfo,
    result: *?*Curl_addrinfo,
) callconv(.c) c_int;
extern fn Curl_addrinfo_set_port(addrinfo: ?*Curl_addrinfo, port: c_int) callconv(.c) void;
extern fn Curl_socktype_for_transport(transport: u8) callconv(.c) c_int;
extern fn Curl_protocol_for_transport(transport: u8) callconv(.c) c_int;
extern fn Curl_resolv_query_str(dns_queries: u8) callconv(.c) [*:0]const u8;
extern fn Curl_async_get(data: ?*Curl_easy, resolv_id: u32) callconv(.c) ?*Curl_resolv_async;
extern fn Curl_async_timeleft_ms(data: ?*Curl_easy, async_ctx: *Curl_resolv_async) callconv(.c) timediff_t;
extern fn Curl_async_failed(data: ?*Curl_easy, async_ctx: *Curl_resolv_async, detail: ?[*:0]const u8) callconv(.c) CURLcode;
extern fn Curl_resolv_announce_start(data: ?*Curl_easy, resolver: ?*anyopaque) callconv(.c) CURLcode;
extern fn Curl_multi_get_easy(multi: ?*Curl_multi, mid: u32) callconv(.c) ?*Curl_easy;
extern fn Curl_multi_mark_dirty(data: ?*Curl_easy) callconv(.c) void;
extern fn Curl_multi_wakeup_internal(multi: ?*Curl_multi) callconv(.c) void;
extern fn Curl_printable_address(ai: *const Curl_addrinfo, buf: [*]u8, bufsize: usize) callconv(.c) void;
extern fn Curl_dnsc_mk_addr2(
    data: ?*Curl_easy,
    dns_queries: u8,
    pai_A: *?*Curl_addrinfo,
    pai_AAAA: *?*Curl_addrinfo,
    peer: ?*Curl_peer,
) callconv(.c) ?*Curl_dns_entry;
extern fn Curl_dns_entry_unlink(data: ?*Curl_easy, pdns: *?*Curl_dns_entry) callconv(.c) void;

extern fn curlx_dyn_init(s: *containers.dynbuf, toobig: usize) callconv(.c) void;
extern fn curlx_dyn_free(s: *containers.dynbuf) callconv(.c) void;
extern fn curlx_dyn_len(s: *const containers.dynbuf) callconv(.c) usize;
extern fn curlx_dyn_ptr(s: *const containers.dynbuf) callconv(.c) ?[*:0]u8;
extern fn curlx_dyn_addf(s: *containers.dynbuf, fmt: [*:0]const u8, ...) callconv(.c) CURLcode;

pub const async_thrdd_item = vdns_cfilters.async_thrdd_item;
pub const async_thrdd_ctx = vdns_cfilters.async_thrdd_ctx;
pub const Curl_resolv_async = vdns_cfilters.Curl_resolv_async;

fn Curl_async_global_init() callconv(.c) c_int {
    return @intCast(CURLE_OK);
}

fn Curl_async_global_cleanup() callconv(.c) void {}

fn async_thrdd_item_destroy(item_opt: ?*async_thrdd_item) void {
    const item = item_opt orelse return;
    if (item.res) |res| {
        Curl_freeaddrinfo(res);
    }
    mem.free(item);
}

fn async_thrdd_item_create(
    data: *Curl_easy,
    resolv_id: u32,
    dns_queries: u8,
    hostname: [*:0]const u8,
    port: u16,
    transport: u8,
) ?*async_thrdd_item {
    const hostlen = std.mem.len(hostname);
    const raw = mem.calloc(1, @sizeOf(async_thrdd_item) + hostlen) orelse return null;
    const item: *async_thrdd_item = @ptrCast(@alignCast(raw));

    if (hostlen > 0) {
        const dst: [*]u8 = @ptrCast(&item.hostname);
        @memcpy(dst[0..hostlen], hostname[0..hostlen]);
    }
    item.mid = Curl_zig_data_get_mid(data);
    item.resolv_id = resolv_id;
    item.dns_queries = dns_queries;
    item.port = port;
    item.transport = transport;

    _ = curl_msnprintf(
        &item.description,
        item.description.len,
        "[%lld/%u] %s %s:%u",
        @as(c_longlong, Curl_zig_data_get_id(data)),
        item.resolv_id,
        Curl_resolv_query_str(dns_queries),
        item.hostnamePtr(),
        @as(c_uint, item.port),
    );

    return item;
}

fn Curl_async_thrdd_shutdown(data: ?*Curl_easy, async_ctx: ?*Curl_resolv_async) callconv(.c) void {
    Curl_async_thrdd_destroy(data, async_ctx);
}

const async_thrdd_match_ctx = extern struct {
    mid: u32,
    resolv_id: u32,
};

fn async_thrdd_match_item(qitem: ?*anyopaque, match_data: ?*anyopaque) callconv(.c) bool {
    const ctx: *const async_thrdd_match_ctx = @ptrCast(@alignCast(match_data.?));
    const item: *const async_thrdd_item = @ptrCast(@alignCast(qitem.?));
    return (item.mid == ctx.mid) and (item.resolv_id == ctx.resolv_id);
}

fn Curl_async_thrdd_destroy(data: ?*Curl_easy, async_ctx: ?*Curl_resolv_async) callconv(.c) void {
    const a = async_ctx orelse return;
    if (a.queries_ongoing != 0 and !a.isDone()) {
        if (data) |d| {
            const multi = Curl_zig_data_get_multi(d);
            const thrdq = Curl_zig_multi_get_resolv_thrdq(multi);
            if (thrdq != null) {
                var mctx: async_thrdd_match_ctx = .{
                    .mid = Curl_zig_data_get_mid(d),
                    .resolv_id = a.id,
                };
                Curl_thrdq_clear(thrdq, async_thrdd_match_item, &mctx);
            }
        }
    }
    async_thrdd_item_destroy(a.thrdd.res_A);
    a.thrdd.res_A = null;
    async_thrdd_item_destroy(a.thrdd.res_AAAA);
    a.thrdd.res_AAAA = null;
}

fn Curl_async_await(data: ?*Curl_easy, resolv_id: u32, pdns: *?*Curl_dns_entry) callconv(.c) CURLcode {
    const a = Curl_async_get(data, resolv_id) orelse return CURLE_FAILED_INIT;
    var result: CURLcode = CURLE_AGAIN;

    while (result == CURLE_AGAIN) {
        while (a.queries_ongoing != 0 and !a.isDone()) {
            Curl_async_thrdd_multi_process(Curl_zig_data_get_multi(data));
            if (a.isDone()) break;

            const ms = curlx_time_net.curlx_ptimediff_ms(Curl_pgrs_now(data), &a.start);
            const milli: timediff_t = if (ms < 3)
                0
            else if (ms <= 50)
                @divTrunc(ms, 3)
            else if (ms <= 250)
                50
            else
                200;
            trcDns(data, "await, waiting %lldms", .{@as(c_longlong, milli)});
            _ = curlx_time_net.curlx_wait_ms(milli);
        }
        result = Curl_async_take_result(data, a, pdns);
    }
    return result;
}

fn async_thrdd_item_process(arg: ?*anyopaque) callconv(.c) void {
    const item: *async_thrdd_item = @ptrCast(@alignCast(arg.?));
    var hints: CAddrinfo = .{};
    var service: [12]u8 = undefined;
    var pf: c_int = PF_INET;

    if ((item.dns_queries & CURL_DNSQ_AAAA) != 0) {
        pf = if ((item.dns_queries & CURL_DNSQ_A) != 0) PF_UNSPEC else PF_INET6;
    }
    hints.ai_family = pf;
    hints.ai_socktype = Curl_socktype_for_transport(item.transport);
    hints.ai_protocol = Curl_protocol_for_transport(item.transport);
    if (builtin.os.tag.isDarwin()) {
        hints.ai_flags = AI_ADDRCONFIG;
    }

    _ = curl_msnprintf(&service, service.len, "%u", @as(c_uint, item.port));
    hints.ai_flags |= AI_NUMERICSERV;

    const service_ptr: [*:0]const u8 = @ptrCast(&service);
    const rc = Curl_getaddrinfo_ex(item.hostnamePtr(), service_ptr, &hints, &item.res);
    if (rc != 0) {
        Curl_zig_async_thrdd_classify_gai_error(rc, &item.sockerr, &item.negative);
    } else {
        Curl_addrinfo_set_port(item.res, @as(c_int, item.port));
    }
}

fn async_thrdd_event(tqueue: ?*const curl_thrdq, ev: c_int, user_data: ?*anyopaque) callconv(.c) void {
    _ = tqueue;
    const multi: ?*Curl_multi = @ptrCast(user_data);
    if (ev == CURL_THRDQ_EV_ITEM_DONE) {
        Curl_multi_wakeup_internal(multi);
    }
}

fn async_thrdd_item_free(item: ?*anyopaque) callconv(.c) void {
    async_thrdd_item_destroy(@ptrCast(@alignCast(item)));
}

fn Curl_async_thrdd_multi_init(
    multi: *Curl_multi,
    min_threads: u32,
    max_threads: u32,
    idle_time_ms: u32,
) callconv(.c) CURLcode {
    const ev_cb: ?Curl_thrdq_ev_cb = if (builtin.os.tag == .windows) null else async_thrdd_event;
    return Curl_thrdq_create(
        Curl_zig_multi_get_resolv_thrdq_ptr(multi),
        "DNS",
        min_threads,
        max_threads,
        idle_time_ms,
        async_thrdd_item_free,
        async_thrdd_item_process,
        ev_cb,
        multi,
    );
}

fn Curl_async_thrdd_multi_destroy(multi: ?*Curl_multi, join: bool) callconv(.c) void {
    const m = multi orelse return;
    const thrdq = Curl_zig_multi_get_resolv_thrdq(m) orelse return;
    const admin = Curl_zig_multi_get_admin(m);
    trcDns(admin, "destroy thread queue+pool, join=%d", .{@as(c_int, @intFromBool(join))});
    Curl_zig_thrdq_trace(thrdq, admin);
    Curl_thrdq_destroy(thrdq, join);
    Curl_zig_multi_set_resolv_thrdq(m, null);
}

fn async_thrdd_report_item(data: ?*Curl_easy, item: *async_thrdd_item) void {
    if (!Curl_zig_trc_dns_is_verbose(data)) return;

    var buf: [MAX_IPADR_LEN]u8 = undefined;
    var tmp: containers.dynbuf = undefined;
    var sep: [*:0]const u8 = "";
    var ai = item.res;
    const ai_family: c_int = if ((item.dns_queries & CURL_DNSQ_AAAA) != 0) AF_INET6 else AF_INET;

    curlx_dyn_init(&tmp, 1024);
    defer curlx_dyn_free(&tmp);

    while (ai) |cur| : (ai = cur.ai_next) {
        if (cur.ai_family == ai_family) {
            Curl_printable_address(cur, &buf, buf.len);
            const buf_ptr: [*:0]const u8 = @ptrCast(&buf);
            const result = curlx_dyn_addf(&tmp, "%s%s", sep, buf_ptr);
            if (result != CURLE_OK) {
                trcDns(data, "too many IP, cannot show", .{});
                return;
            }
            sep = ", ";
        }
    }

    const ipv_char: c_int = if ((item.dns_queries & CURL_DNSQ_AAAA) != 0) '6' else '4';
    const resolved_str: [*:0]const u8 = if (curlx_dyn_len(&tmp) != 0) curlx_dyn_ptr(&tmp).? else "(none)";
    trcDns(
        data,
        "Host %s:%u resolved IPv%c: %s",
        .{ item.hostnamePtr(), @as(c_uint, item.port), ipv_char, resolved_str },
    );
}

fn Curl_async_thrdd_multi_process(multi: ?*Curl_multi) callconv(.c) void {
    const m = multi orelse return;
    const thrdq = Curl_zig_multi_get_resolv_thrdq(m);
    var qitem: ?*anyopaque = null;

    while (Curl_thrdq_recv(thrdq, &qitem) == CURLE_OK) {
        var item: ?*async_thrdd_item = @ptrCast(@alignCast(qitem));
        const data = Curl_multi_get_easy(m, item.?.mid);
        const a: ?*Curl_resolv_async = if (data != null) Curl_async_get(data, item.?.resolv_id) else null;
        if (a) |async_ctx| {
            const pdest: *?*async_thrdd_item = if ((item.?.dns_queries & CURL_DNSQ_AAAA) != 0)
                &async_ctx.thrdd.res_AAAA
            else
                &async_ctx.thrdd.res_A;
            if (pdest.* == null) {
                pdest.* = item;
                item = null;
            }
            async_ctx.queries_ongoing -= 1;
            Curl_multi_mark_dirty(data);
        }
        async_thrdd_item_free(item);
    }
    Curl_zig_thrdq_trace(thrdq, Curl_zig_multi_get_admin(m));
}

fn Curl_async_thrdd_multi_set_props(
    multi: ?*Curl_multi,
    min_threads: u32,
    max_threads: u32,
    idle_time_ms: u32,
) callconv(.c) CURLcode {
    return Curl_thrdq_set_props(
        Curl_zig_multi_get_resolv_thrdq(multi),
        min_threads,
        max_threads,
        idle_time_ms,
    );
}

fn async_thrdd_query(data: *Curl_easy, async_ctx: *Curl_resolv_async, dns_queries: u8) CURLcode {
    const peer = async_ctx.peer orelse return CURLE_FAILED_INIT;
    const hostname = peer.hostname orelse return CURLE_FAILED_INIT;
    var item = async_thrdd_item_create(
        data,
        async_ctx.id,
        dns_queries,
        hostname,
        peer.port,
        async_ctx.transport,
    ) orelse return CURLE_OUT_OF_MEMORY;

    trcDns(data, "queueing query %s", .{item.descriptionPtr()});
    const thrdq = Curl_zig_multi_get_resolv_thrdq(Curl_zig_data_get_multi(data));
    const result = Curl_thrdq_send(thrdq, item, item.descriptionPtr(), async_ctx.timeout_ms);
    if (result == CURLE_OK) {
        item = undefined;
        async_ctx.queries_ongoing += 1;
    } else {
        async_thrdd_item_free(item);
    }
    return result;
}

fn Curl_async_getaddrinfo(data: ?*Curl_easy, async_ctx: ?*Curl_resolv_async) callconv(.c) CURLcode {
    const d = data orelse return CURLE_FAILED_INIT;
    const a = async_ctx orelse return CURLE_FAILED_INIT;

    if (a.queries_ongoing != 0 or a.isDone()) {
        return CURLE_FAILED_INIT;
    }

    var result = Curl_resolv_announce_start(d, null);
    if (result != CURLE_OK) {
        return result;
    }

    blk: {
        if ((a.dns_queries & CURL_DNSQ_AAAA) != 0 and
            !(a.isIpv4Addr() and (a.dns_queries & CURL_DNSQ_A) != 0))
        {
            result = async_thrdd_query(d, a, CURL_DNSQ_AAAA);
            if (result != CURLE_OK) break :blk;
        }
        if ((a.dns_queries & CURL_DNSQ_A) != 0) {
            result = async_thrdd_query(d, a, CURL_DNSQ_A);
            if (result != CURLE_OK) break :blk;
        }
        Curl_zig_thrdq_trace(Curl_zig_multi_get_resolv_thrdq(Curl_zig_data_get_multi(d)), d);
    }

    if (a.queries_ongoing == 0) {
        a.setDone(true);
    }

    if (result != CURLE_OK) {
        if (a.peer) |peer| {
            if (peer.hostname) |hostname| {
                trcDns(
                    d,
                    "error queueing query %s:%d -> %d",
                    .{ hostname, @as(c_int, peer.port), @as(c_int, @intCast(result)) },
                );
            }
        }
    }
    return result;
}

fn Curl_async_pollset(
    data: ?*Curl_easy,
    async_ctx: ?*Curl_resolv_async,
    ps: *easy_pollset,
) callconv(.c) CURLcode {
    _ = ps;
    const a = async_ctx orelse return CURLE_OK;
    var timeout_ms = Curl_async_timeleft_ms(data, a);

    if (!a.isDone()) {
        const pnow = Curl_pgrs_now(data);
        if (builtin.os.tag == .windows) {
            const elapsed_ms = curlx_time_net.curlx_ptimediff_ms(pnow, &a.start);
            const stutter_ms: timediff_t = if (elapsed_ms < 3)
                1
            else if (elapsed_ms <= 50)
                @divTrunc(elapsed_ms, 3)
            else if (elapsed_ms <= 250)
                50
            else
                200;
            timeout_ms = @min(stutter_ms, timeout_ms);
        } else {
            const thrdq = Curl_zig_multi_get_resolv_thrdq(Curl_zig_data_get_multi(data));
            if (a.queries_ongoing != 0 and !Curl_thrdq_check_started(thrdq)) {
                trcDns(data, "resolver thread start failed again, retrying", .{});
                timeout_ms = @min(@as(timediff_t, 100), timeout_ms);
            }
        }
        Curl_expire_set(data, EXPIRE_ASYNC_NAME, timeout_ms, pnow);
    }
    return CURLE_OK;
}

fn async_thrdd_item_missing_scope(data: ?*Curl_easy, item: *async_thrdd_item) bool {
    if (Curl_zig_data_get_conn_scope_id(data) != 0) {
        return false;
    }
    var ai = item.res;
    while (ai) |cur| : (ai = cur.ai_next) {
        if (cur.ai_family == AF_INET6) {
            if (cur.ai_addr) |addr_ptr| {
                const sa6: *const headers_sock.SockaddrIn6 = @ptrCast(@alignCast(addr_ptr));
                const is_linklocal = (sa6.sin6_addr[0] == 0xfe) and ((sa6.sin6_addr[1] & 0xc0) == 0x80);
                if (is_linklocal and sa6.sin6_scope_id == 0) {
                    return true;
                }
            }
        }
    }
    return false;
}

fn async_thrdd_item_strip_results(item: *async_thrdd_item, ai_family: c_int) void {
    var panchor: *?*Curl_addrinfo = &item.res;
    while (panchor.*) |ai| {
        if (ai.ai_family == ai_family) {
            panchor.* = ai.ai_next;
            ai.ai_next = null;
            Curl_freeaddrinfo(ai);
        } else {
            panchor = &ai.ai_next;
        }
    }
}

fn async_thrdd_check_done(data: ?*Curl_easy, async_ctx: *Curl_resolv_async) CURLcode {
    const thrdd = &async_ctx.thrdd;

    if (thrdd.res_A) |res_a| {
        if (!thrdd.isProcessedA()) {
            async_thrdd_report_item(data, res_a);
            async_ctx.dns_responses |= res_a.dns_queries;
            async_ctx.ai_A = res_a.res;
            res_a.res = null;
            thrdd.setProcessedA(true);
        }
    }

    if (thrdd.res_AAAA) |res_aaaa| {
        if (!thrdd.isProcessedAAAA()) {
            if ((res_aaaa.dns_queries & CURL_DNSQ_A) == 0 and
                async_thrdd_item_missing_scope(data, res_aaaa))
            {
                const item = res_aaaa;
                thrdd.res_AAAA = null;
                item.dns_queries |= CURL_DNSQ_A;
                if (item.res) |old_res| {
                    Curl_freeaddrinfo(old_res);
                    item.res = null;
                }

                trcDns(data, "re-queueing query %s for AF_UNSPEC resolve", .{item.descriptionPtr()});
                const thrdq = Curl_zig_multi_get_resolv_thrdq(Curl_zig_data_get_multi(data));
                const result = Curl_thrdq_send(thrdq, item, item.descriptionPtr(), async_ctx.timeout_ms);
                if (result != CURLE_OK) {
                    async_thrdd_item_free(item);
                    return result;
                }
                async_ctx.queries_ongoing += 1;
                return CURLE_AGAIN;
            }
            async_thrdd_item_strip_results(res_aaaa, AF_INET);
            async_thrdd_report_item(data, res_aaaa);
            async_ctx.dns_responses |= res_aaaa.dns_queries;
            async_ctx.ai_AAAA = res_aaaa.res;
            res_aaaa.res = null;
            thrdd.setProcessedAAAA(true);
        }
    }

    if (async_ctx.queries_ongoing != 0) {
        return CURLE_AGAIN;
    }
    async_ctx.setDone(true);
    return CURLE_OK;
}

fn Curl_async_take_result(
    data: ?*Curl_easy,
    async_ctx: ?*Curl_resolv_async,
    pdns: *?*Curl_dns_entry,
) callconv(.c) CURLcode {
    pdns.* = null;
    const a = async_ctx orelse return CURLE_FAILED_INIT;
    const thrdd = &a.thrdd;

    if (builtin.os.tag == .windows) {
        Curl_async_thrdd_multi_process(Curl_zig_data_get_multi(data));
    }

    var result = async_thrdd_check_done(data, a);
    if (result != CURLE_OK) {
        return result;
    }

    Curl_expire_clear(data, EXPIRE_ASYNC_NAME);

    {
        const ip_queries: u8 = a.dns_queries & (CURL_DNSQ_A | CURL_DNSQ_AAAA);
        var negative: bool = (a.dns_responses & ip_queries) == ip_queries;
        if (thrdd.res_A) |res_a| {
            if (a.ai_A != null or !res_a.negative) {
                negative = false;
            }
        }
        if (thrdd.res_AAAA) |res_aaaa| {
            if (a.ai_AAAA != null or !res_aaaa.negative) {
                negative = false;
            }
        }
        if (thrdd.res_A == null and thrdd.res_AAAA == null) {
            negative = false;
        }
        a.setNegativeAnswer(negative);
    }

    var dns: ?*Curl_dns_entry = null;
    blk: {
        if (a.result != CURLE_OK) {
            result = a.result;
            break :blk;
        }

        if (a.ai_A != null or a.ai_AAAA != null) {
            dns = Curl_dnsc_mk_addr2(data, a.dns_queries, &a.ai_A, &a.ai_AAAA, a.peer);
            if (dns == null) {
                result = CURLE_OUT_OF_MEMORY;
                break :blk;
            }
        }

        if (dns != null) {
            pdns.* = dns;
            dns = null;
        }
        Curl_zig_thrdq_trace(Curl_zig_multi_get_resolv_thrdq(Curl_zig_data_get_multi(data)), data);
    }

    Curl_dns_entry_unlink(data, &dns);
    Curl_async_thrdd_shutdown(data, a);
    if (result == CURLE_OK and pdns.* == null) {
        result = Curl_async_failed(data, a, null);
    }
    if (result != CURLE_OK and
        result != CURLE_COULDNT_RESOLVE_HOST and
        result != CURLE_COULDNT_RESOLVE_PROXY)
    {
        if (a.peer) |peer| {
            if (peer.hostname) |hostname| {
                trcDns(
                    data,
                    "Error %d resolving %s:%d",
                    .{ @as(c_int, @intCast(result)), hostname, @as(c_int, peer.port) },
                );
            }
        }
    }
    return result;
}

comptime {
    if (vdns_cfilters.use_resolv_threaded) {
        @export(&Curl_async_global_init, .{ .name = "Curl_async_global_init" });
        @export(&Curl_async_global_cleanup, .{ .name = "Curl_async_global_cleanup" });
        @export(&Curl_async_thrdd_shutdown, .{ .name = "Curl_async_thrdd_shutdown" });
        @export(&Curl_async_thrdd_destroy, .{ .name = "Curl_async_thrdd_destroy" });
        @export(&Curl_async_await, .{ .name = "Curl_async_await" });
        @export(&Curl_async_thrdd_multi_init, .{ .name = "Curl_async_thrdd_multi_init" });
        @export(&Curl_async_thrdd_multi_destroy, .{ .name = "Curl_async_thrdd_multi_destroy" });
        @export(&Curl_async_thrdd_multi_process, .{ .name = "Curl_async_thrdd_multi_process" });
        @export(&Curl_async_thrdd_multi_set_props, .{ .name = "Curl_async_thrdd_multi_set_props" });
        @export(&Curl_async_getaddrinfo, .{ .name = "Curl_async_getaddrinfo" });
        @export(&Curl_async_pollset, .{ .name = "Curl_async_pollset" });
        @export(&Curl_async_take_result, .{ .name = "Curl_async_take_result" });
    }
}

// ============================================================================
// Unit Tests
// ============================================================================

test "Curl_alpn2alpnid maps known ALPN strings" {
    const h1 = "h1";
    const h2 = "h2";
    const h3 = "h3";
    const http11 = "http/1.1";
    const unknown = "spdy/3.1";

    try std.testing.expectEqual(ALPN_h1, Curl_alpn2alpnid(h1.ptr, h1.len));
    try std.testing.expectEqual(ALPN_h2, Curl_alpn2alpnid(h2.ptr, h2.len));
    try std.testing.expectEqual(ALPN_h3, Curl_alpn2alpnid(h3.ptr, h3.len));
    try std.testing.expectEqual(ALPN_h1, Curl_alpn2alpnid(http11.ptr, http11.len));
    try std.testing.expectEqual(ALPN_none, Curl_alpn2alpnid(unknown.ptr, unknown.len));
    try std.testing.expectEqual(ALPN_none, Curl_alpn2alpnid(null, 0));
}

test "cf_hc_baller_assign initializes baller fields by ALPN" {
    var b: cf_hc_baller = .{};
    cf_hc_baller_assign(&b, ALPN_h3, TRNSPRT_TCP);
    try std.testing.expectEqualStrings("h3", std.mem.span(b.name));
    try std.testing.expectEqual(TRNSPRT_QUIC, b.transport);
    try std.testing.expectEqual(CURLE_OK, b.result);
    try std.testing.expectEqual(@as(c_int, -1), b.reply_ms);

    cf_hc_baller_assign(&b, ALPN_h2, TRNSPRT_TCP);
    try std.testing.expectEqualStrings("h2", std.mem.span(b.name));
    try std.testing.expectEqual(TRNSPRT_TCP, b.transport);

    cf_hc_baller_assign(&b, 999, TRNSPRT_TCP);
    try std.testing.expectEqual(CURLE_FAILED_INIT, b.result);
}

test "Curl_cft_http_connect and Curl_cft_ip_happy vtable properties" {
    try std.testing.expectEqualStrings("HTTPS-CONNECT", std.mem.span(Curl_cft_http_connect.name));
    try std.testing.expectEqual(CF_TYPE_SETUP, Curl_cft_http_connect.flags);
    try std.testing.expectEqualStrings("HAPPY-EYEBALLS", std.mem.span(Curl_cft_ip_happy.name));
    try std.testing.expectEqual(CF_TYPE_SETUP, Curl_cft_ip_happy.flags);
    try std.testing.expect(get_cf_create(TRNSPRT_TCP, false) != null);
    try std.testing.expect(get_cf_create(TRNSPRT_UDP, false) != null);
    try std.testing.expect(get_cf_create(TRNSPRT_UNIX, true) != null);
    try std.testing.expect(get_cf_create(TRNSPRT_QUIC, false) == null);
}

test "Curl_async_global_init and async_thrdd_ctx flags" {
    try std.testing.expectEqual(@as(c_int, 0), Curl_async_global_init());
    Curl_async_global_cleanup();

    var thrdd: async_thrdd_ctx = .{};
    try std.testing.expect(!thrdd.isProcessedA());
    try std.testing.expect(!thrdd.isProcessedAAAA());
    thrdd.setProcessedA(true);
    try std.testing.expect(thrdd.isProcessedA());
    try std.testing.expect(!thrdd.isProcessedAAAA());
    thrdd.setProcessedAAAA(true);
    try std.testing.expect(thrdd.isProcessedAAAA());
}

test "cf_ai_iter_init and async_thrdd_item_missing_scope" {
    var peer = std.mem.zeroes(Curl_peer);
    var cf = std.mem.zeroes(Curl_cfilter);
    var iter_v4: cf_ai_iter = undefined;
    cf_ai_iter_init(&iter_v4, &cf, &peer, AF_INET);
    try std.testing.expectEqual(@as(c_int, AF_INET), iter_v4.ai_family);
    try std.testing.expectEqual(@as(c_uint, 0), iter_v4.n);
    iter_v4.cf = null;
    try std.testing.expect(!cf_ai_iter_has_more(&iter_v4, null));

    var sa6 = std.mem.zeroes(headers_sock.SockaddrIn6);
    sa6.sin6_family = @intCast(AF_INET6);
    sa6.sin6_addr[0] = 0xfe;
    sa6.sin6_addr[1] = 0x80;
    sa6.sin6_scope_id = 0;

    var ai6 = std.mem.zeroes(Curl_addrinfo);
    ai6.ai_family = AF_INET6;
    ai6.ai_addr = @ptrCast(&sa6);

    var item = std.mem.zeroes(async_thrdd_item);
    item.res = &ai6;
    try std.testing.expect(async_thrdd_item_missing_scope(null, &item));

    sa6.sin6_scope_id = 2;
    try std.testing.expect(!async_thrdd_item_missing_scope(null, &item));
}
