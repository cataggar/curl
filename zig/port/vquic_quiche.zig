const std = @import("std");
const builtin = @import("builtin");
const backend_options = @import("backend_options");
const mem = @import("mem.zig");
const curlx_time_net = @import("curlx_time_net.zig");
const io_buffers = @import("io_buffers.zig");
const headers_sock = @import("headers_sock.zig");
const collections = @import("collections.zig");
const containers = @import("containers.zig");
const http1_options = @import("http1_options.zig");
const cfsocket_transfer = @import("cfsocket_transfer.zig");
const vtls_core = @import("vtls_core.zig");
const vtls_backends = @import("vtls_backends.zig");
const vquic_core = @import("vquic_core.zig");

const is_windows = builtin.os.tag == .windows;
pub const use_quiche = backend_options.quic == .quiche;

pub const CURLcode = c_uint;
pub const CURLE_OK: CURLcode = 0;
pub const CURLE_UNSUPPORTED_PROTOCOL: CURLcode = 1;
pub const CURLE_FAILED_INIT: CURLcode = 2;
pub const CURLE_URL_MALFORMAT: CURLcode = 3;
pub const CURLE_NOT_BUILT_IN: CURLcode = 4;
pub const CURLE_COULDNT_RESOLVE_HOST: CURLcode = 6;
pub const CURLE_COULDNT_CONNECT: CURLcode = 7;
pub const CURLE_WEIRD_SERVER_REPLY: CURLcode = 8;
pub const CURLE_PARTIAL_FILE: CURLcode = 18;
pub const CURLE_WRITE_ERROR: CURLcode = 23;
pub const CURLE_OUT_OF_MEMORY: CURLcode = 27;
pub const CURLE_OPERATION_TIMEDOUT: CURLcode = 28;
pub const CURLE_SSL_CONNECT_ERROR: CURLcode = 35;
pub const CURLE_BAD_FUNCTION_ARGUMENT: CURLcode = 43;
pub const CURLE_INTERNAL_ERROR: CURLcode = 43;
pub const CURLE_UNKNOWN_OPTION: CURLcode = 48;
pub const CURLE_SEND_ERROR: CURLcode = 55;
pub const CURLE_RECV_ERROR: CURLcode = 56;
pub const CURLE_PEER_FAILED_VERIFICATION: CURLcode = 60;
pub const CURLE_AGAIN: CURLcode = 81;
pub const CURLE_HTTP3: CURLcode = 95;
pub const CURLE_QUIC_CONNECT_ERROR: CURLcode = 96;

pub const curl_socket_t = headers_sock.curl_socket_t;
pub const CURL_SOCKET_BAD = headers_sock.CURL_SOCKET_BAD;
pub const Curltime = curlx_time_net.Curltime;
pub const timediff_t = curlx_time_net.timediff_t;
pub const curl_off_t = i64;
pub const socklen_t = vquic_core.socklen_t;
pub const SockaddrStorage = vquic_core.SockaddrStorage;
pub const EasyPollset = vtls_backends.EasyPollset;
pub const Bufq = io_buffers.bufq;
pub const BufcPool = io_buffers.bufc_pool;
pub const Dynhds = io_buffers.dynhds;
pub const Dynbuf = containers.dynbuf;
pub const H1ReqParser = http1_options.h1_req_parser;
pub const HttpReq = http1_options.httpreq;
pub const UintHash = collections.u32_ptrset;

pub const CurlEasy = vtls_backends.CurlEasy;
pub const ConnectData = vtls_backends.ConnectData;
pub const CurlCfilter = vtls_backends.CurlCfilter;
pub const CurlCftype = vtls_backends.CurlCftype;
pub const CfCallData = struct {
    data: ?*CurlEasy = null,
    depth: u32 = 0,
};
pub const CurlPeer = vquic_core.CurlPeer;
pub const SslPeer = vtls_backends.SslPeer;
pub const SslFilterConfig = vtls_backends.SslFilterConfig;
pub const CurlSockaddrEx = cfsocket_transfer.CurlSockaddrEx;
pub const AlpnSpec = vtls_backends.AlpnSpec;
pub const CurlTlsSessionInfo = vtls_backends.CurlTlsSessionInfo;
pub const CurlTlsCtx = vquic_core.CurlTlsCtx;
pub const CfQuicCtx = vquic_core.CfQuicCtx;

pub const CF_TYPE_IP_CONNECT: c_int = 1 << 0;
pub const CF_TYPE_SSL: c_int = 1 << 1;
pub const CF_TYPE_MULTIPLEX: c_int = 1 << 2;
pub const CF_TYPE_PROXY: c_int = 1 << 3;
pub const CF_TYPE_HTTP: c_int = 1 << 4;

pub const CURL_LOG_LVL_NONE: c_int = 0;

pub const CF_CTRL_DATA_SETUP: c_int = 4;
pub const CF_CTRL_DATA_IDLE: c_int = 5;
pub const CF_CTRL_DATA_PAUSE: c_int = 6;
pub const CF_CTRL_DATA_DONE: c_int = 7;
pub const CF_CTRL_DATA_DONE_SEND: c_int = 8;
pub const CF_CTRL_CONN_INFO_UPDATE: c_int = 256 + 0;

pub const CF_QUERY_MAX_CONCURRENT: c_int = 1;
pub const CF_QUERY_CONNECT_REPLY_MS: c_int = 2;
pub const CF_QUERY_SOCKET: c_int = 3;
pub const CF_QUERY_TIMER_CONNECT: c_int = 4;
pub const CF_QUERY_TIMER_APPCONNECT: c_int = 5;
pub const CF_QUERY_STREAM_ERROR: c_int = 6;
pub const CF_QUERY_NEED_FLUSH: c_int = 7;
pub const CF_QUERY_IP_INFO: c_int = 8;
pub const CF_QUERY_HTTP_VERSION: c_int = 9;
pub const CF_QUERY_REMOTE_ADDR: c_int = 10;
pub const CF_QUERY_HOST_PORT: c_int = 11;
pub const CF_QUERY_SSL_INFO: c_int = 12;
pub const CF_QUERY_SSL_CTX_INFO: c_int = 13;
pub const CF_QUERY_TRANSPORT: c_int = 14;
pub const CF_QUERY_ALPN_NEGOTIATED: c_int = 15;
pub const CF_QUERY_REALLY_CONNECTED: c_int = 16;

pub const EXPIRE_QUIC: c_uint = 8;
pub const TRNSPRT_QUIC: u8 = vquic_core.TRNSPRT_QUIC;
pub const ALPN_h3: c_int = 1 << 5;

const TIMER_CONNECT: c_int = 5;
const TIMER_APPCONNECT: c_int = 6;

const BUFQ_OPT_NONE: c_int = io_buffers.BUFQ_OPT_NONE;

// ============================================================================
// Quiche C ABI Declarations (/usr/include/quiche.h)
// ============================================================================

pub const QUICHE_PROTOCOL_VERSION: u32 = 0x00000001;
pub const QUICHE_MAX_CONN_ID_LEN: usize = 20;
pub const QUICHE_MIN_CLIENT_INITIAL_LEN: usize = 1200;
pub const QUICHE_H3_APPLICATION_PROTOCOL = "\x02h3";

pub const QuicheError = enum(c_int) {
    QUICHE_ERR_DONE = -1,
    QUICHE_ERR_BUFFER_TOO_SHORT = -2,
    QUICHE_ERR_UNKNOWN_VERSION = -3,
    QUICHE_ERR_INVALID_FRAME = -4,
    QUICHE_ERR_INVALID_PACKET = -5,
    QUICHE_ERR_INVALID_STATE = -6,
    QUICHE_ERR_INVALID_STREAM_STATE = -7,
    QUICHE_ERR_INVALID_TRANSPORT_PARAM = -8,
    QUICHE_ERR_CRYPTO_FAIL = -9,
    QUICHE_ERR_TLS_FAIL = -10,
    QUICHE_ERR_FLOW_CONTROL = -11,
    QUICHE_ERR_STREAM_LIMIT = -12,
    QUICHE_ERR_FINAL_SIZE = -13,
    QUICHE_ERR_CONGESTION_CONTROL = -14,
    QUICHE_ERR_STREAM_STOPPED = -15,
    QUICHE_ERR_STREAM_RESET = -16,
    QUICHE_ERR_ID_LIMIT = -17,
    QUICHE_ERR_OUT_OF_IDENTIFIERS = -18,
    QUICHE_ERR_KEY_UPDATE = -19,
    QUICHE_ERR_CRYPTO_BUFFER_EXCEEDED = -20,
    QUICHE_ERR_INVALID_ACK_RANGE = -21,
    QUICHE_ERR_OPTIMISTIC_ACK_DETECTED = -22,
};

pub const QUICHE_H3_ERR_DONE: c_int = -1;
pub const QUICHE_H3_ERR_STREAM_BLOCKED: c_int = -10;
pub const QUICHE_H3_ERR_REQUEST_REJECTED: c_int = -12;

pub const quiche_config = opaque {};
pub const quiche_conn = opaque {};
pub const quiche_h3_config = opaque {};
pub const quiche_h3_conn = opaque {};
pub const quiche_h3_event = opaque {};

pub const QuicheRecvInfo = extern struct {
    from: ?*const anyopaque,
    from_len: socklen_t,
    to: ?*const anyopaque,
    to_len: socklen_t,
};

pub const QuicheSendInfo = extern struct {
    from: SockaddrStorage,
    from_len: socklen_t,
    to: SockaddrStorage,
    to_len: socklen_t,
    at: extern struct {
        tv_sec: c_long,
        tv_nsec: c_long,
    },
};

pub const QuicheH3EventType = enum(c_uint) {
    QUICHE_H3_EVENT_HEADERS = 0,
    QUICHE_H3_EVENT_DATA = 1,
    QUICHE_H3_EVENT_FINISHED = 2,
    QUICHE_H3_EVENT_RESET = 3,
    QUICHE_H3_EVENT_PRIORITY_UPDATE = 4,
    QUICHE_H3_EVENT_GOAWAY = 5,
};

pub const QuicheH3Header = extern struct {
    name: [*c]const u8,
    name_len: usize,
    value: [*c]const u8,
    value_len: usize,
};

pub const QuicheForEachHeaderCb = *const fn (
    name: [*c]u8,
    name_len: usize,
    value: [*c]u8,
    value_len: usize,
    argp: ?*anyopaque,
) callconv(.c) c_int;

const quiche_ext = if (use_quiche) struct {
    extern fn quiche_version() callconv(.c) [*:0]const u8;
    extern fn quiche_config_new(version: u32) callconv(.c) ?*quiche_config;
    extern fn quiche_config_load_cert_chain_from_pem_file(config: *quiche_config, path: [*:0]const u8) callconv(.c) c_int;
    extern fn quiche_config_load_priv_key_from_pem_file(config: *quiche_config, path: [*:0]const u8) callconv(.c) c_int;
    extern fn quiche_config_load_verify_locations_from_file(config: *quiche_config, path: [*:0]const u8) callconv(.c) c_int;
    extern fn quiche_config_load_verify_locations_from_directory(config: *quiche_config, path: [*:0]const u8) callconv(.c) c_int;
    extern fn quiche_config_verify_peer(config: *quiche_config, v: bool) callconv(.c) void;
    extern fn quiche_config_set_application_protos(config: *quiche_config, protos: [*]const u8, protos_len: usize) callconv(.c) c_int;
    extern fn quiche_config_set_max_idle_timeout(config: *quiche_config, v: u64) callconv(.c) void;
    extern fn quiche_config_set_initial_max_data(config: *quiche_config, v: u64) callconv(.c) void;
    extern fn quiche_config_set_initial_max_stream_data_bidi_local(config: *quiche_config, v: u64) callconv(.c) void;
    extern fn quiche_config_set_initial_max_stream_data_bidi_remote(config: *quiche_config, v: u64) callconv(.c) void;
    extern fn quiche_config_set_initial_max_stream_data_uni(config: *quiche_config, v: u64) callconv(.c) void;
    extern fn quiche_config_set_initial_max_streams_bidi(config: *quiche_config, v: u64) callconv(.c) void;
    extern fn quiche_config_set_initial_max_streams_uni(config: *quiche_config, v: u64) callconv(.c) void;
    extern fn quiche_config_set_disable_active_migration(config: *quiche_config, v: bool) callconv(.c) void;
    extern fn quiche_config_enable_pacing(config: *quiche_config, v: bool) callconv(.c) void;
    extern fn quiche_config_free(config: *quiche_config) callconv(.c) void;

    extern fn quiche_connect(
        server_name: ?[*:0]const u8,
        scid: [*]const u8,
        scid_len: usize,
        local: *const anyopaque,
        local_len: socklen_t,
        peer: *const anyopaque,
        peer_len: socklen_t,
        config: *quiche_config,
    ) callconv(.c) ?*quiche_conn;
    extern fn quiche_conn_set_qlog_fd(
        conn: *quiche_conn,
        fd: c_int,
        log_title: [*:0]const u8,
        log_desc: [*:0]const u8,
    ) callconv(.c) void;
    extern fn quiche_conn_recv(
        conn: *quiche_conn,
        buf: [*]u8,
        buf_len: usize,
        info: *const QuicheRecvInfo,
    ) callconv(.c) isize;
    extern fn quiche_conn_send(
        conn: *quiche_conn,
        out: [*]u8,
        out_len: usize,
        out_info: *QuicheSendInfo,
    ) callconv(.c) isize;
    extern fn quiche_conn_stream_shutdown(
        conn: *quiche_conn,
        stream_id: u64,
        direction: c_uint,
        err: u64,
    ) callconv(.c) c_int;
    extern fn quiche_conn_stream_writable(
        conn: *quiche_conn,
        stream_id: u64,
        len: usize,
    ) callconv(.c) c_int;
    extern fn quiche_conn_close(
        conn: *quiche_conn,
        app: bool,
        err: u64,
        reason: [*]const u8,
        reason_len: usize,
    ) callconv(.c) c_int;
    extern fn quiche_conn_peer_cert(
        conn: *const quiche_conn,
        out: *?[*]const u8,
        out_len: *usize,
    ) callconv(.c) void;
    extern fn quiche_conn_is_established(conn: *const quiche_conn) callconv(.c) bool;
    extern fn quiche_conn_is_closed(conn: *const quiche_conn) callconv(.c) bool;
    extern fn quiche_conn_is_draining(conn: *const quiche_conn) callconv(.c) bool;
    extern fn quiche_conn_peer_error(
        conn: *const quiche_conn,
        is_app: *bool,
        error_code: *u64,
        reason: *[*]const u8,
        reason_len: *usize,
    ) callconv(.c) bool;
    extern fn quiche_conn_timeout_as_millis(conn: *const quiche_conn) callconv(.c) u64;
    extern fn quiche_conn_on_timeout(conn: *quiche_conn) callconv(.c) void;
    extern fn quiche_conn_peer_streams_left_bidi(conn: *const quiche_conn) callconv(.c) u64;
    extern fn quiche_conn_max_send_udp_payload_size(conn: *const quiche_conn) callconv(.c) usize;
    extern fn quiche_conn_free(conn: *quiche_conn) callconv(.c) void;

    extern fn quiche_h3_config_new() callconv(.c) ?*quiche_h3_config;
    extern fn quiche_h3_config_free(config: *quiche_h3_config) callconv(.c) void;
    extern fn quiche_h3_conn_new_with_transport(
        quiche_conn_ptr: *quiche_conn,
        config: *quiche_h3_config,
    ) callconv(.c) ?*quiche_h3_conn;
    extern fn quiche_h3_conn_poll(
        conn: *quiche_h3_conn,
        quic_conn: *quiche_conn,
        ev: *?*quiche_h3_event,
    ) callconv(.c) i64;
    extern fn quiche_h3_event_type(ev: *quiche_h3_event) callconv(.c) QuicheH3EventType;
    extern fn quiche_h3_event_for_each_header(
        ev: *quiche_h3_event,
        cb: QuicheForEachHeaderCb,
        argp: ?*anyopaque,
    ) callconv(.c) c_int;
    extern fn quiche_h3_event_free(ev: *quiche_h3_event) callconv(.c) void;
    extern fn quiche_h3_send_request(
        conn: *quiche_h3_conn,
        quic_conn: *quiche_conn,
        headers: [*]const QuicheH3Header,
        headers_len: usize,
        fin: bool,
    ) callconv(.c) i64;
    extern fn quiche_h3_send_body(
        conn: *quiche_h3_conn,
        quic_conn: *quiche_conn,
        stream_id: u64,
        body: [*]const u8,
        body_len: usize,
        fin: bool,
    ) callconv(.c) isize;
    extern fn quiche_h3_recv_body(
        conn: *quiche_h3_conn,
        quic_conn: *quiche_conn,
        stream_id: u64,
        out: [*]u8,
        out_len: usize,
    ) callconv(.c) isize;
    extern fn quiche_h3_conn_free(conn: *quiche_h3_conn) callconv(.c) void;
    extern fn Curl_vtls_acc_ssl_cainfo(data: ?*CurlEasy, is_proxy: bool) callconv(.c) ?[*:0]u8;
    extern fn d2i_X509(a: ?*?*anyopaque, ppin: *[*]const u8, length: c_long) callconv(.c) ?*anyopaque;
    extern fn X509_free(x: ?*anyopaque) callconv(.c) void;
    extern fn Curl_ossl_verifyhost(data: ?*CurlEasy, conn: ?*anyopaque, peer: *anyopaque, server_cert: *anyopaque) callconv(.c) CURLcode;
} else struct {};

const posix_io = if (!is_windows) struct {
    extern "c" fn close(fd: c_int) c_int;
    extern "c" fn getsockname(sockfd: c_int, addr: *anyopaque, addrlen: *socklen_t) c_int;
} else struct {
    extern "c" fn _close(fd: c_int) c_int;
    extern "ws2_32" fn getsockname(s: curl_socket_t, name: *anyopaque, namelen: *socklen_t) callconv(.winapi) c_int;
};

fn closeFd(fd: c_int) void {
    if (fd < 0) return;
    if (is_windows) {
        _ = posix_io._close(fd);
    } else {
        _ = posix_io.close(fd);
    }
}

// ============================================================================
// External C & Zig Port Helpers
// ============================================================================

extern fn curl_msnprintf(buffer: [*c]u8, maxlength: usize, format: [*:0]const u8, ...) callconv(.c) c_int;
extern fn Curl_failf(data: ?*anyopaque, fmt: [*:0]const u8, ...) callconv(.c) void;
extern fn Curl_infof(data: ?*anyopaque, fmt: [*:0]const u8, ...) callconv(.c) void;
extern fn Curl_trc_cf_infof(data: ?*anyopaque, cf: ?*const anyopaque, fmt: [*:0]const u8, ...) callconv(.c) void;
extern fn Curl_pgrs_now(data: ?*anyopaque) callconv(.c) *const Curltime;
extern fn Curl_pgrsTimeWas(data: ?*CurlEasy, timer: c_int, timestamp: Curltime) callconv(.c) void;
extern fn Curl_rand_bytes(data: ?*anyopaque, rnd: [*]u8, num: usize) callconv(.c) CURLcode;
extern fn Curl_expire(data: ?*anyopaque, milli: timediff_t, id: c_uint) callconv(.c) void;
extern fn Curl_multi_get_easy(multi: ?*anyopaque, mid: u32) callconv(.c) ?*CurlEasy;
extern fn Curl_multi_mark_dirty(data: *anyopaque) callconv(.c) void;
extern fn Curl_multi_connchanged(multi: ?*anyopaque) callconv(.c) void;
extern fn Curl_conn_set_multiplex(conn: ?*anyopaque) callconv(.c) void;
extern fn Curl_conn_get_attached_xfers(conn: ?*const anyopaque) callconv(.c) u32;
extern fn Curl_http_acc_conn_set_httpversion_seen(conn: ?*anyopaque, ver: u8) callconv(.c) void;
extern fn Curl_zig_url_data_get_i64(data: *const anyopaque, field_id: c_int) callconv(.c) i64;
extern fn Curl_zig_url_data_get_ptr(data: *const anyopaque, ptr_id: c_int) callconv(.c) ?*anyopaque;
extern fn Curl_zig_easy_state_infilesize(data: *const anyopaque) callconv(.c) curl_off_t;
extern fn Curl_xfer_write_resp(data: ?*CurlEasy, buf: [*]const u8, blen: usize, is_eos: bool) callconv(.c) CURLcode;
extern fn Curl_http_req_to_h2(h2_headers: *Dynhds, req: *HttpReq, data: ?*anyopaque) callconv(.c) CURLcode;
extern fn Curl_1st_fatal(result: CURLcode, result2: CURLcode) callconv(.c) CURLcode;
extern fn Curl_cf_create(pcf: *?*CurlCfilter, cft: *const CurlCftype, ctx: ?*anyopaque) callconv(.c) CURLcode;
extern fn Curl_cf_udp_create(pcf: *?*CurlCfilter, data: ?*CurlEasy, origin: ?*CurlPeer, peer: ?*CurlPeer, transport_peer: u8, conn: ?*ConnectData, addr: ?*CurlSockaddrEx, tunnel_peer: ?*CurlPeer, tunnel_transport: u8) callconv(.c) CURLcode;
extern fn Curl_cf_socket_peek(cf: ?*CurlCfilter, data: ?*CurlEasy, psock: ?*curl_socket_t, paddr: ?*?*CurlSockaddrEx, pip: ?*anyopaque) callconv(.c) CURLcode;
extern fn Curl_conn_cf_insert_after(cf_at: *CurlCfilter, cf_new: *CurlCfilter) callconv(.c) void;
extern fn Curl_conn_cf_connect(cf: ?*CurlCfilter, data: ?*CurlEasy, done: *bool) callconv(.c) CURLcode;
extern fn Curl_conn_cf_adjust_pollset(cf: ?*CurlCfilter, data: ?*CurlEasy, ps: *EasyPollset) callconv(.c) CURLcode;
extern fn Curl_cf_def_conn_keep_alive(cf: *CurlCfilter, data: ?*CurlEasy) callconv(.c) CURLcode;
extern fn Curl_cf_def_query(cf: *CurlCfilter, data: ?*CurlEasy, query: c_int, pres1: ?*c_int, pres2: ?*anyopaque) callconv(.c) CURLcode;

extern fn Curl_u32_ptrset_init(set: *UintHash, dtor: ?collections.Curl_u32_ptrset_dtor) callconv(.c) void;
extern fn Curl_u32_ptrset_clear(set: *UintHash) callconv(.c) void;
extern fn Curl_u32_ptrset_get(set: *UintHash, id: u32) callconv(.c) ?*anyopaque;
extern fn Curl_u32_ptrset_set(set: *UintHash, id: u32, ptr: ?*anyopaque) callconv(.c) CURLcode;
extern fn Curl_u32_ptrset_unset(set: *UintHash, id: u32) callconv(.c) void;
extern fn Curl_u32_ptrset_visit(set: *UintHash, cb: collections.Curl_u32_ptrset_visit_cb, user_data: ?*anyopaque) callconv(.c) void;

pub const CURLEASY_MAGIC_NUMBER: c_uint = 0xc0dedbad;

inline fn goodEasyHandle(data: ?*const CurlEasy) bool {
    const ptr = data orelse return false;
    const magic_ptr: *const c_uint = @ptrCast(@alignCast(ptr));
    return magic_ptr.* == CURLEASY_MAGIC_NUMBER;
}

inline fn easyMid(data: ?*const CurlEasy) u32 {
    const d = data orelse return std.math.maxInt(u32);
    if (!goodEasyHandle(d)) return std.math.maxInt(u32);
    return std.math.cast(u32, Curl_zig_url_data_get_i64(d, 3)) orelse std.math.maxInt(u32);
}

inline fn easyId(data: ?*const CurlEasy) i64 {
    const d = data orelse return -1;
    if (!goodEasyHandle(d)) return -1;
    return Curl_zig_url_data_get_i64(d, 2);
}

inline fn easyMulti(data: ?*const CurlEasy) ?*anyopaque {
    const d = data orelse return null;
    if (!goodEasyHandle(d)) return null;
    return Curl_zig_url_data_get_ptr(d, 1);
}

inline fn multiGetEasy(call_data: ?*CurlEasy, mid: u32) ?*CurlEasy {
    if (!goodEasyHandle(call_data)) return null;
    if (mid == std.math.maxInt(u32)) return null;
    const m = easyMulti(call_data) orelse return null;
    const sdata = Curl_multi_get_easy(m, mid) orelse return null;
    if (!goodEasyHandle(sdata)) return null;
    return sdata;
}

inline fn multiConnChanged(data: ?*CurlEasy) void {
    const m = easyMulti(data) orelse return;
    Curl_multi_connchanged(m);
}

inline fn cfDataSave(save: *CfCallData, call_data: *CfCallData, data: ?*CurlEasy) void {
    save.* = call_data.*;
    call_data.data = data;
    call_data.depth += 1;
}

inline fn cfDataRestore(call_data: *CfCallData, save: CfCallData) void {
    call_data.* = save;
}

// ============================================================================
// Constants & Context Structs (lib/vquic/cf-quiche.c)
// ============================================================================

pub const QUIC_MAX_STREAMS: u64 = 100;
pub const H3_STREAM_WINDOW_SIZE: u64 = 128 * 1024;
pub const H3_STREAM_CHUNK_SIZE: usize = 16 * 1024;
pub const H3_STREAM_POOL_SPARES: usize = 2;
pub const H3_SEND_SIZE: usize = 2 * 1024;
pub const MAX_PKT_BURST: usize = 10;
pub const MAX_UDP_PAYLOAD_SIZE: usize = vquic_core.MAX_UDP_PAYLOAD_SIZE;
pub const QUIC_IDLE_TIMEOUT_MS: u64 = 60 * 1000;

const ALPN_SPEC_H3 = AlpnSpec{
    .entries = .{
        .{ 'h', '3', 0, 0, 0, 0, 0, 0, 0, 0 },
        @splat(0),
        @splat(0),
    },
    .count = 1,
};

/// HTTP/3 per-transfer stream context (`struct h3_stream_ctx` in `lib/vquic/cf-quiche.c`).
pub const H3StreamCtx = struct {
    id: i64 = 0,
    mid: u32 = std.math.maxInt(u32),
    xfer_id: i64 = -1,
    sendbuf: Bufq = std.mem.zeroes(Bufq),
    h1: H1ReqParser = std.mem.zeroes(H1ReqParser),
    upload_left: usize = 0,
    closed: bool = false,
    reset: bool = false,
    send_closed: bool = false,
    resp_hds_complete: bool = false,
    resp_got_header: bool = false,
    quic_flow_blocked: bool = false,
};

/// Quiche connection filter context (`struct cf_quiche_ctx` in `lib/vquic/cf-quiche.c`).
pub const CfQuicheCtx = struct {
    q: CfQuicCtx = .{},
    ssl_peer: SslPeer = std.mem.zeroes(SslPeer),
    cf: ?*CurlCfilter = null,
    call_data: CfCallData = .{},
    tls: CurlTlsCtx = .{},
    cfg: ?*quiche_config = null,
    qconn: ?*quiche_conn = null,
    h3config: ?*quiche_h3_config = null,
    h3c: ?*quiche_h3_conn = null,
    scid: [QUICHE_MAX_CONN_ID_LEN]u8 = @splat(0),
    dcid: [QUICHE_MAX_CONN_ID_LEN]u8 = @splat(0),
    qlogfd: c_int = -1,
    streams: UintHash = std.mem.zeroes(UintHash),
    stream_bufcp: BufcPool = std.mem.zeroes(BufcPool),
    max_stream_window: u64 = 0,
    data_recvd: u64 = 0,
    started_at: Curltime = .{ .tv_sec = 0, .tv_usec = 0 },
    handshake_at: Curltime = .{ .tv_sec = 0, .tv_usec = 0 },
    reconnect_at: Curltime = .{ .tv_sec = 0, .tv_usec = 0 },
    goaway: bool = false,
    x509_store_setup: bool = false,
    shutdown_started: bool = false,
    initialized: bool = false,
};

inline fn cfToQuicheCtx(cf: ?*CurlCfilter) ?*CfQuicheCtx {
    const f = cf orelse return null;
    const raw = f.ctx orelse return null;
    return @ptrCast(@alignCast(raw));
}

inline fn H3_STREAM_CTX(ctx: *CfQuicheCtx, data: ?*const CurlEasy) ?*H3StreamCtx {
    const d = data orelse return null;
    if (!goodEasyHandle(d)) return null;
    const mid = easyMid(d);
    if (mid == std.math.maxInt(u32)) return null;
    const raw = Curl_u32_ptrset_get(&ctx.streams, mid) orelse return null;
    const stream: *H3StreamCtx = @ptrCast(@alignCast(raw));
    if (stream.mid != mid or stream.xfer_id != easyId(d)) return null;
    return stream;
}

// ============================================================================
// Version String
// ============================================================================

pub export fn Curl_quiche_ver(p: [*c]u8, len: usize) callconv(.c) void {
    if (len == 0) return;
    if (comptime use_quiche) {
        _ = curl_msnprintf(p, len, "quiche/%s", quiche_ext.quiche_version());
    } else {
        p[0] = 0;
    }
}

// ============================================================================
// Stream Management
// ============================================================================

fn h3_stream_ctx_free(stream: ?*H3StreamCtx) void {
    const s = stream orelse return;
    io_buffers.Curl_bufq_free(&s.sendbuf);
    http1_options.Curl_h1_req_parse_free(&s.h1);
    mem.freeTyped(s);
}

fn h3_stream_hash_free(id: u32, stream_ptr: ?*anyopaque) callconv(.c) void {
    _ = id;
    if (stream_ptr) |p| {
        h3_stream_ctx_free(@ptrCast(@alignCast(p)));
    }
}

fn cf_quiche_expire_timeout(cf: *CurlCfilter, data: ?*CurlEasy) void {
    if (comptime !use_quiche) return;
    const ctx = cfToQuicheCtx(cf) orelse return;
    const qconn = ctx.qconn orelse return;
    const d = data orelse return;

    var timeout_ms: timediff_t = @intCast(@min(
        quiche_ext.quiche_conn_timeout_as_millis(qconn),
        @as(u64, @intCast(std.math.maxInt(timediff_t))),
    ));
    if (timeout_ms <= 0) {
        timeout_ms = 1;
    }
    Curl_expire(d, timeout_ms, EXPIRE_QUIC);
}

fn h3_stream_open(
    cf: *CurlCfilter,
    data: *CurlEasy,
    pstream: *?*H3StreamCtx,
) CURLcode {
    const ctx = cfToQuicheCtx(cf) orelse return CURLE_FAILED_INIT;
    if (!goodEasyHandle(data)) {
        pstream.* = null;
        return CURLE_BAD_FUNCTION_ARGUMENT;
    }
    const mid = easyMid(data);
    const xfer_id = easyId(data);
    if (mid == std.math.maxInt(u32) or xfer_id < 0) {
        pstream.* = null;
        return CURLE_BAD_FUNCTION_ARGUMENT;
    }
    std.debug.assert(H3_STREAM_CTX(ctx, data) == null);

    const raw = mem.calloc(1, @sizeOf(H3StreamCtx)) orelse {
        pstream.* = null;
        return CURLE_OUT_OF_MEMORY;
    };
    const stream: *H3StreamCtx = @ptrCast(@alignCast(raw));
    stream.* = .{};
    stream.id = -1;
    stream.mid = mid;
    stream.xfer_id = xfer_id;
    io_buffers.Curl_bufq_initp(
        &stream.sendbuf,
        &ctx.stream_bufcp,
        1,
        BUFQ_OPT_NONE,
    );
    http1_options.Curl_h1_req_parse_init(&stream.h1, H3_SEND_SIZE);

    if (Curl_u32_ptrset_set(&ctx.streams, mid, stream) != CURLE_OK) {
        h3_stream_ctx_free(stream);
        pstream.* = null;
        return CURLE_OUT_OF_MEMORY;
    }

    pstream.* = stream;
    return CURLE_OK;
}

fn h3_stream_close(cf: *CurlCfilter, data: ?*CurlEasy, stream: ?*H3StreamCtx) void {
    const s = stream orelse return;
    const d = data orelse return;
    const ctx = cfToQuicheCtx(cf) orelse return;
    const mid = if (s.mid != std.math.maxInt(u32)) s.mid else easyMid(d);
    if (comptime use_quiche) {
        if (ctx.qconn != null and !s.closed and s.id >= 0) {
            const qconn = ctx.qconn.?;
            _ = quiche_ext.quiche_conn_stream_shutdown(
                qconn,
                @intCast(s.id),
                0, // QUICHE_SHUTDOWN_READ
                0x010c, // H3_REQUEST_CANCELLED
            );
            if (!s.send_closed) {
                _ = quiche_ext.quiche_conn_stream_shutdown(
                    qconn,
                    @intCast(s.id),
                    1, // QUICHE_SHUTDOWN_WRITE
                    0x010c, // H3_REQUEST_CANCELLED
                );
                s.send_closed = true;
            }
        }
    }
    if (mid != std.math.maxInt(u32)) {
        Curl_u32_ptrset_unset(&ctx.streams, mid);
    }
}

// ============================================================================
// Response Header & Body Processing
// ============================================================================

const CbCtx = struct {
    cf: *CurlCfilter,
    data: *CurlEasy,
};

fn write_resp_raw(
    cf: *CurlCfilter,
    data: *CurlEasy,
    mem_buf: [*]const u8,
    memlen: usize,
) CURLcode {
    const ctx = cfToQuicheCtx(cf) orelse return CURLE_FAILED_INIT;
    _ = H3_STREAM_CTX(ctx, data) orelse return CURLE_RECV_ERROR;
    return Curl_xfer_write_resp(data, mem_buf, memlen, false);
}

fn cb_each_header(
    name: [*c]u8,
    name_len: usize,
    value: [*c]u8,
    value_len: usize,
    argp: ?*anyopaque,
) callconv(.c) c_int {
    const pair: *CbCtx = @ptrCast(@alignCast(argp orelse return 1));
    const ctx = cfToQuicheCtx(pair.cf) orelse return 1;
    const stream = H3_STREAM_CTX(ctx, pair.data) orelse return 1;
    var result: CURLcode = CURLE_OK;

    if ((name_len == 7) and std.mem.eql(u8, name[0..7], ":status")) {
        var line: [14]u8 = undefined;
        const n = curl_msnprintf(&line, line.len, "HTTP/3 %.*s \r\n", @as(c_int, @intCast(value_len)), value);
        if (n > 0) {
            result = write_resp_raw(pair.cf, pair.data, &line, @intCast(n));
        }
    } else {
        result = write_resp_raw(pair.cf, pair.data, name, name_len);
        if (result == CURLE_OK) {
            result = write_resp_raw(pair.cf, pair.data, ": ", 2);
        }
        if (result == CURLE_OK) {
            result = write_resp_raw(pair.cf, pair.data, value, value_len);
        }
        if (result == CURLE_OK) {
            result = write_resp_raw(pair.cf, pair.data, "\r\n", 2);
        }
    }
    if (result != CURLE_OK) {
        Curl_trc_cf_infof(pair.data, pair.cf, "[%" ++ "lld] on header error %d", @as(c_longlong, stream.id), result);
    }
    return @intCast(result);
}

fn stream_resp_read(
    buf: [*c]u8,
    blen: usize,
    err: *CURLcode,
    userp: ?*anyopaque,
) callconv(.c) usize {
    if (comptime !use_quiche) {
        err.* = CURLE_NOT_BUILT_IN;
        return 0;
    }
    const pair: *CbCtx = @ptrCast(@alignCast(userp orelse {
        err.* = CURLE_RECV_ERROR;
        return 0;
    }));
    const ctx = cfToQuicheCtx(pair.cf) orelse {
        err.* = CURLE_RECV_ERROR;
        return 0;
    };
    const stream = H3_STREAM_CTX(ctx, pair.data) orelse {
        err.* = CURLE_RECV_ERROR;
        return 0;
    };
    const h3c = ctx.h3c orelse {
        err.* = CURLE_RECV_ERROR;
        return 0;
    };
    const qconn = ctx.qconn orelse {
        err.* = CURLE_RECV_ERROR;
        return 0;
    };

    const nread = quiche_ext.quiche_h3_recv_body(
        h3c,
        qconn,
        @intCast(stream.id),
        buf,
        blen,
    );
    if (nread < 0) {
        if (nread == QUICHE_H3_ERR_DONE) {
            err.* = CURLE_AGAIN;
        } else {
            Curl_failf(
                pair.data,
                "Error %zd in HTTP/3 response body for stream[%" ++ "lld]",
                nread,
                @as(c_longlong, stream.id),
            );
            stream.closed = true;
            stream.reset = true;
            stream.send_closed = true;
            err.* = if (stream.resp_got_header) CURLE_HTTP3 else CURLE_RECV_ERROR;
        }
        return 0;
    }
    err.* = CURLE_OK;
    return @intCast(nread);
}

fn cf_quiche_pass_data(cf: *CurlCfilter, data: *CurlEasy) CURLcode {
    const ctx = cfToQuicheCtx(cf) orelse return CURLE_FAILED_INIT;
    const stream = H3_STREAM_CTX(ctx, data) orelse return CURLE_OK;
    var pair = CbCtx{ .cf = cf, .data = data };

    var result: CURLcode = CURLE_OK;
    while (!stream.closed) {
        var scratch: [H3_STREAM_CHUNK_SIZE]u8 = undefined;
        var rerr: CURLcode = CURLE_OK;
        const nread = stream_resp_read(&scratch, scratch.len, &rerr, &pair);
        if (nread > 0) {
            ctx.data_recvd += @intCast(nread);
            result = write_resp_raw(cf, data, &scratch, nread);
            if (result != CURLE_OK) break;
        } else {
            if (rerr != CURLE_AGAIN) {
                result = rerr;
            }
            break;
        }
    }
    return result;
}

fn cf_quiche_drain_stream(cf: *CurlCfilter, data: *CurlEasy) void {
    const ctx = cfToQuicheCtx(cf) orelse return;
    const stream = H3_STREAM_CTX(ctx, data) orelse return;
    if (stream.quic_flow_blocked or stream.resp_got_header or stream.closed) {
        Curl_multi_mark_dirty(data);
    }
}

fn h3_process_event(
    cf: *CurlCfilter,
    data: *CurlEasy,
    stream: *H3StreamCtx,
    ev: *quiche_h3_event,
) void {
    if (comptime !use_quiche) return;
    var pair = CbCtx{ .cf = cf, .data = data };
    var rc: c_int = 0;

    switch (quiche_ext.quiche_h3_event_type(ev)) {
        .QUICHE_H3_EVENT_HEADERS => {
            stream.resp_got_header = true;
            rc = quiche_ext.quiche_h3_event_for_each_header(ev, cb_each_header, &pair);
            if (rc != 0) {
                Curl_failf(data, "Error %d in HTTP/3 response header for stream[%" ++ "lld]", rc, @as(c_longlong, stream.id));
                Curl_multi_mark_dirty(data);
                return;
            }
            const wrc = write_resp_raw(cf, data, "\r\n", 2);
            if (wrc != CURLE_OK) {
                Curl_trc_cf_infof(data, cf, "[%" ++ "lld] error %d writing end of headers", @as(c_longlong, stream.id), wrc);
            }
            stream.resp_hds_complete = true;
            cf_quiche_drain_stream(cf, data);
        },
        .QUICHE_H3_EVENT_DATA => {
            if (!stream.closed) {
                const result = cf_quiche_pass_data(cf, data);
                if (result != CURLE_OK) {
                    Curl_trc_cf_infof(data, cf, "[%" ++ "lld] error %d receiving data", @as(c_longlong, stream.id), result);
                }
            }
        },
        .QUICHE_H3_EVENT_FINISHED => {
            if (!stream.closed) {
                stream.closed = true;
                cf_quiche_drain_stream(cf, data);
            }
        },
        .QUICHE_H3_EVENT_RESET => {
            stream.closed = true;
            stream.reset = true;
            stream.send_closed = true;
            cf_quiche_drain_stream(cf, data);
        },
        .QUICHE_H3_EVENT_PRIORITY_UPDATE => {},
        .QUICHE_H3_EVENT_GOAWAY => {
            const ctx = cfToQuicheCtx(cf) orelse return;
            ctx.goaway = true;
        },
    }
}

const H3EventNode = struct {
    cf: *CurlCfilter,
    ctx: *CfQuicheCtx,
    stream_id: i64,
    ev: ?*quiche_h3_event,
};

fn h3_stream_match_process(mid: u32, value: ?*anyopaque, user_data: ?*anyopaque) callconv(.c) bool {
    const stream: *H3StreamCtx = @ptrCast(@alignCast(value orelse return true));
    const node: *H3EventNode = @ptrCast(@alignCast(user_data orelse return false));
    if (stream.id == node.stream_id) {
        if (mid == std.math.maxInt(u32) or mid != stream.mid or stream.xfer_id < 0) return false;
        const call_data = node.ctx.call_data.data orelse return false;
        if (!goodEasyHandle(call_data)) return false;
        if (multiGetEasy(call_data, mid)) |sdata| {
            if (!goodEasyHandle(sdata) or easyMid(sdata) != stream.mid or easyMid(sdata) != mid or easyId(sdata) != stream.xfer_id) {
                return false;
            }
            var save: CfCallData = undefined;
            cfDataSave(&save, &node.ctx.call_data, sdata);
            defer cfDataRestore(&node.ctx.call_data, save);
            if (comptime use_quiche) {
                if (node.ev) |ev| {
                    h3_process_event(node.cf, sdata, stream, ev);
                    quiche_ext.quiche_h3_event_free(ev);
                    node.ev = null;
                }
            } else {
                node.ev = null;
            }
            return false;
        }
    }
    return true;
}

fn poll_control_streams(cf: *CurlCfilter, data: *CurlEasy) CURLcode {
    if (comptime !use_quiche) return CURLE_NOT_BUILT_IN;
    const ctx = cfToQuicheCtx(cf) orelse return CURLE_FAILED_INIT;
    const qconn = ctx.qconn orelse return CURLE_OK;
    const h3c = ctx.h3c orelse return CURLE_OK;

    if (cf.conn == null) return CURLE_OK;

    while (true) {
        var ev: ?*quiche_h3_event = null;
        const stream_id = quiche_ext.quiche_h3_conn_poll(h3c, qconn, &ev);
        if (stream_id == QUICHE_H3_ERR_DONE) {
            break;
        }
        if (stream_id < 0) {
            Curl_trc_cf_infof(data, cf, "error poll: %" ++ "lld", @as(c_longlong, stream_id));
            return CURLE_HTTP3;
        }

        const cur_stream = H3_STREAM_CTX(ctx, data);
        if (cur_stream != null and cur_stream.?.id == stream_id) {
            if (ev) |e| {
                h3_process_event(cf, data, cur_stream.?, e);
                quiche_ext.quiche_h3_event_free(e);
            }
        } else {
            var node = H3EventNode{
                .cf = cf,
                .ctx = ctx,
                .stream_id = stream_id,
                .ev = ev,
            };
            Curl_u32_ptrset_visit(&ctx.streams, h3_stream_match_process, &node);
            if (node.ev) |leftover| {
                quiche_ext.quiche_h3_event_free(leftover);
            }
        }
    }
    return CURLE_OK;
}

// ============================================================================
// Packet Ingress & Egress
// ============================================================================

const RecvPktCtx = struct {
    cf: *CurlCfilter,
    data: *CurlEasy,
    ctx: *CfQuicheCtx,
};

fn recv_pkt(
    pkt: [*]const u8,
    pktlen: usize,
    remote_addr: *const SockaddrStorage,
    remote_addrlen: socklen_t,
    ecn: c_int,
    userp: ?*anyopaque,
) CURLcode {
    if (comptime !use_quiche) return CURLE_NOT_BUILT_IN;
    _ = ecn;
    const rctx: *RecvPktCtx = @ptrCast(@alignCast(userp orelse return CURLE_RECV_ERROR));
    const qconn = rctx.ctx.qconn orelse return CURLE_RECV_ERROR;

    var recv_info = QuicheRecvInfo{
        .to = @ptrCast(&rctx.ctx.q.local_addr),
        .to_len = rctx.ctx.q.local_addrlen,
        .from = @ptrCast(remote_addr),
        .from_len = remote_addrlen,
    };

    const rc = quiche_ext.quiche_conn_recv(
        qconn,
        @constCast(pkt),
        pktlen,
        &recv_info,
    );
    if (rc < 0) {
        if (rc == @backingInt(QuicheError.QUICHE_ERR_TLS_FAIL)) {
            Curl_failf(rctx.data, "SSL: certificate verification failed (quiche)");
            return CURLE_PEER_FAILED_VERIFICATION;
        }
        Curl_failf(rctx.data, "quiche_conn_recv() == %zd", rc);
        return CURLE_RECV_ERROR;
    }
    return CURLE_OK;
}

fn recv_pkt_vquic_cb(
    pkt: [*]const u8,
    pktlen: usize,
    remote_addr: *const SockaddrStorage,
    remote_addrlen: socklen_t,
    ifindex: c_int,
    ecn: u8,
    userp: ?*anyopaque,
) callconv(.c) CURLcode {
    _ = ifindex;
    return recv_pkt(pkt, pktlen, remote_addr, remote_addrlen, @intCast(ecn), userp);
}

fn process_ingress(cf: *CurlCfilter, data: *CurlEasy) CURLcode {
    const ctx = cfToQuicheCtx(cf) orelse return CURLE_FAILED_INIT;
    std.debug.assert(ctx.qconn != null);

    var result = vquic_core.Curl_vquic_tls_before_recv(&ctx.tls, cf, data);
    if (result != CURLE_OK) return result;

    var rctx = RecvPktCtx{
        .cf = cf,
        .data = data,
        .ctx = ctx,
    };
    result = vquic_core.Curl_vquic_recv_packets(
        cf,
        data,
        &ctx.q,
        1000,
        recv_pkt_vquic_cb,
        &rctx,
    );
    if (result != CURLE_OK) return result;

    return poll_control_streams(cf, data);
}

const ReadPktCtx = struct {
    cf: *CurlCfilter,
    data: *CurlEasy,
    send_info: QuicheSendInfo = undefined,
};

fn read_pkt_to_send(
    userp: ?*anyopaque,
    buf: [*]u8,
    buflen: usize,
    pnread: *usize,
) callconv(.c) CURLcode {
    pnread.* = 0;
    if (comptime !use_quiche) return CURLE_NOT_BUILT_IN;
    const x: *ReadPktCtx = @ptrCast(@alignCast(userp orelse return CURLE_SEND_ERROR));
    const ctx = cfToQuicheCtx(x.cf) orelse return CURLE_SEND_ERROR;
    const qconn = ctx.qconn orelse return CURLE_SEND_ERROR;

    const nwritten = quiche_ext.quiche_conn_send(
        qconn,
        buf,
        buflen,
        &x.send_info,
    );
    if (nwritten == @backingInt(QuicheError.QUICHE_ERR_DONE)) {
        return CURLE_AGAIN;
    }
    if (nwritten < 0) {
        Curl_failf(x.data, "quiche_conn_send returned %zd", nwritten);
        return CURLE_SEND_ERROR;
    }
    pnread.* = @intCast(nwritten);
    return CURLE_OK;
}

fn flush_egress(cf: *CurlCfilter, data: *CurlEasy) CURLcode {
    if (comptime !use_quiche) return CURLE_NOT_BUILT_IN;
    const ctx = cfToQuicheCtx(cf) orelse return CURLE_FAILED_INIT;
    const qconn = ctx.qconn orelse return CURLE_FAILED_INIT;

    var result = vquic_core.Curl_vquic_flush(cf, data, &ctx.q);
    if (result != CURLE_OK) {
        if (result == CURLE_AGAIN) {
            cf_quiche_expire_timeout(cf, data);
            return CURLE_OK;
        }
        return result;
    }

    var x = ReadPktCtx{ .cf = cf, .data = data };
    const max_udp_payload_size = quiche_ext.quiche_conn_max_send_udp_payload_size(qconn);

    while (true) {
        var gso_size: usize = 0;
        var pkts: usize = 0;
        result = io_buffers.Curl_bufq_sipn(
            &ctx.q.sendbuf,
            max_udp_payload_size,
            read_pkt_to_send,
            &x,
            &gso_size,
        );
        if (result != CURLE_OK) {
            if (result != CURLE_AGAIN) return result;
            break;
        } else if (gso_size > 0) {
            pkts += 1;
        }

        while (pkts < MAX_PKT_BURST) {
            var psent: usize = 0;
            result = io_buffers.Curl_bufq_sipn(
                &ctx.q.sendbuf,
                gso_size,
                read_pkt_to_send,
                &x,
                &psent,
            );
            if (result != CURLE_OK) {
                if (result != CURLE_AGAIN) return result;
                break;
            } else if (psent > 0) {
                pkts += 1;
                if (gso_size != psent) break;
            }
        }

        result = vquic_core.Curl_vquic_send(cf, data, &ctx.q, gso_size);
        if (result != CURLE_OK) {
            if (result == CURLE_AGAIN) break;
            return result;
        }
    }

    cf_quiche_expire_timeout(cf, data);
    return CURLE_OK;
}

const NotifyCtx = struct {
    cf: *CurlCfilter,
    ctx: *CfQuicheCtx,
};

fn notify_blocked_stream(mid: u32, value: ?*anyopaque, user_data: ?*anyopaque) callconv(.c) bool {
    const stream: *H3StreamCtx = @ptrCast(@alignCast(value orelse return true));
    const nctx: *NotifyCtx = @ptrCast(@alignCast(user_data orelse return false));
    const call_data = nctx.ctx.call_data.data orelse return false;
    if (!goodEasyHandle(call_data)) return false;
    const qconn = nctx.ctx.qconn orelse return false;

    if (stream.quic_flow_blocked and stream.id >= 0) {
        if (mid == std.math.maxInt(u32) or mid != stream.mid or stream.xfer_id < 0) return true;
        const writable = if (comptime use_quiche)
            quiche_ext.quiche_conn_stream_writable(qconn, @intCast(stream.id), 1) > 0
        else
            true;
        if (writable) {
            if (multiGetEasy(call_data, mid)) |sdata| {
                if (goodEasyHandle(sdata) and easyMid(sdata) == stream.mid and easyMid(sdata) == mid and easyId(sdata) == stream.xfer_id) {
                    stream.quic_flow_blocked = false;
                    Curl_multi_mark_dirty(sdata);
                }
            }
        }
    }
    return true;
}

fn cf_notify_idle_streams(cf: *CurlCfilter) void {
    const ctx = cfToQuicheCtx(cf) orelse return;
    if (cf.conn == null) return;
    var nctx = NotifyCtx{ .cf = cf, .ctx = ctx };
    Curl_u32_ptrset_visit(&ctx.streams, notify_blocked_stream, &nctx);
}

fn cf_quiche_io(cf: *CurlCfilter, data: *CurlEasy) CURLcode {
    const ctx = cfToQuicheCtx(cf) orelse return CURLE_FAILED_INIT;
    var save: CfCallData = undefined;
    cfDataSave(&save, &ctx.call_data, data);
    defer cfDataRestore(&ctx.call_data, save);

    var result = process_ingress(cf, data);
    if (result == CURLE_OK) {
        result = flush_egress(cf, data);
    }
    cf_notify_idle_streams(cf);
    return result;
}

// ============================================================================
// Filter Recv & Send
// ============================================================================

fn cf_quiche_recv(
    cf: *CurlCfilter,
    data: ?*CurlEasy,
    buf: [*]u8,
    len: usize,
    nread: *usize,
) callconv(.c) CURLcode {
    nread.* = 0;
    if (comptime !use_quiche) return CURLE_NOT_BUILT_IN;
    _ = buf;
    _ = len;
    const d = data orelse return CURLE_RECV_ERROR;
    const ctx = cfToQuicheCtx(cf) orelse return CURLE_RECV_ERROR;

    var save: CfCallData = undefined;
    cfDataSave(&save, &ctx.call_data, d);
    defer cfDataRestore(&ctx.call_data, save);

    const stream = H3_STREAM_CTX(ctx, d) orelse return CURLE_RECV_ERROR;
    var result: CURLcode = CURLE_OK;

    if (!stream.closed) {
        result = cf_quiche_pass_data(cf, d);
        if (result != CURLE_OK) return result;
    }

    if (process_ingress(cf, d) != CURLE_OK) {
        result = CURLE_RECV_ERROR;
    }
    if (result == CURLE_OK and !stream.closed) {
        result = cf_quiche_pass_data(cf, d);
    }

    if (result == CURLE_OK) {
        if (stream.reset) {
            Curl_failf(
                d,
                "HTTP/3 stream %" ++ "lld reset by server",
                @as(c_longlong, stream.id),
            );
            result = if (stream.resp_got_header) CURLE_HTTP3 else CURLE_RECV_ERROR;
        } else if (!stream.closed) {
            result = CURLE_AGAIN;
        }
    }

    const result2 = flush_egress(cf, d);
    return Curl_1st_fatal(result, result2);
}

const SendBodyCtx = struct {
    cf: *CurlCfilter,
    data: *CurlEasy,
    stream: *H3StreamCtx,
};

fn cf_quiche_send_body(
    userp: ?*anyopaque,
    buf: [*]const u8,
    blen: usize,
    pwritten: *usize,
) callconv(.c) CURLcode {
    pwritten.* = 0;
    if (comptime !use_quiche) return CURLE_NOT_BUILT_IN;
    const sctx: *SendBodyCtx = @ptrCast(@alignCast(userp orelse return CURLE_SEND_ERROR));
    const ctx = cfToQuicheCtx(sctx.cf) orelse return CURLE_SEND_ERROR;
    const h3c = ctx.h3c orelse return CURLE_SEND_ERROR;
    const qconn = ctx.qconn orelse return CURLE_SEND_ERROR;

    const eof = !sctx.stream.send_closed and
        (sctx.stream.upload_left <= blen) and
        io_buffers.Curl_bufq_is_empty(&sctx.stream.sendbuf);

    const nwritten = quiche_ext.quiche_h3_send_body(
        h3c,
        qconn,
        @intCast(sctx.stream.id),
        buf,
        blen,
        eof,
    );
    if (nwritten == QUICHE_H3_ERR_DONE) {
        sctx.stream.quic_flow_blocked = true;
        return CURLE_AGAIN;
    } else if (nwritten == @backingInt(QuicheError.QUICHE_ERR_STREAM_STOPPED)) {
        Curl_trc_cf_infof(sctx.data, sctx.cf, "[%" ++ "lld] send_body, stream stopped", @as(c_longlong, sctx.stream.id));
        sctx.stream.send_closed = true;
        pwritten.* = blen;
        return CURLE_OK;
    } else if (nwritten == @backingInt(QuicheError.QUICHE_ERR_INVALID_STREAM_STATE)) {
        if (sctx.stream.resp_hds_complete) {
            sctx.stream.send_closed = true;
            pwritten.* = blen;
            return CURLE_OK;
        }
        Curl_failf(sctx.data, "send_body, invalid stream[%" ++ "lld] state", @as(c_longlong, sctx.stream.id));
        return CURLE_HTTP3;
    } else if (nwritten < 0) {
        Curl_failf(
            sctx.data,
            "quiche_h3_send_body(len=%zu) -> %zd",
            blen,
            nwritten,
        );
        return CURLE_SEND_ERROR;
    } else {
        const nw: usize = @intCast(nwritten);
        if (eof and nw == blen) {
            sctx.stream.send_closed = true;
        }
        pwritten.* = nw;
        return CURLE_OK;
    }
}

fn cf_quiche_resume_upload(
    cf: *CurlCfilter,
    data: *CurlEasy,
    stream: *H3StreamCtx,
) CURLcode {
    var sctx = SendBodyCtx{
        .cf = cf,
        .data = data,
        .stream = stream,
    };
    var nw: usize = 0;
    const result = io_buffers.Curl_bufq_pass(
        &stream.sendbuf,
        cf_quiche_send_body,
        &sctx,
        &nw,
    );
    if (result != CURLE_OK and result != CURLE_AGAIN) {
        return result;
    }
    if (nw > 0) {
        if (stream.upload_left > nw) {
            stream.upload_left -= nw;
        } else {
            stream.upload_left = 0;
        }
    }
    return CURLE_OK;
}

fn h3_open_stream(
    cf: *CurlCfilter,
    data: *CurlEasy,
    buf: [*]const u8,
    len: usize,
    eos: bool,
    pnwritten: *usize,
) CURLcode {
    pnwritten.* = 0;
    if (comptime !use_quiche) return CURLE_NOT_BUILT_IN;
    const ctx = cfToQuicheCtx(cf) orelse return CURLE_FAILED_INIT;
    const qconn = ctx.qconn orelse return CURLE_FAILED_INIT;
    const h3c = ctx.h3c orelse return CURLE_FAILED_INIT;

    var stream = H3_STREAM_CTX(ctx, data);
    var result: CURLcode = CURLE_OK;
    if (stream == null) {
        result = h3_stream_open(cf, data, &stream);
        if (result != CURLE_OK) return result;
    }
    const s = stream orelse return CURLE_OUT_OF_MEMORY;

    var nparsed: usize = 0;
    result = http1_options.Curl_h1_req_parse_read(&s.h1, buf, len, null, null, 0, &nparsed);
    if (result != CURLE_OK) return result;
    pnwritten.* = nparsed;
    if (s.h1.done == 0) {
        return CURLE_OK;
    }

    const req = s.h1.req orelse return CURLE_HTTP3;
    var h2_headers: Dynhds = undefined;
    io_buffers.Curl_dynhds_init(&h2_headers, 0, 1024 * 1024);
    defer io_buffers.Curl_dynhds_free(&h2_headers);

    result = Curl_http_req_to_h2(&h2_headers, req, data);
    if (result != CURLE_OK) return result;
    http1_options.Curl_h1_req_parse_free(&s.h1);

    const nheaders = io_buffers.Curl_dynhds_count(&h2_headers);
    const nva_raw = mem.calloc(if (nheaders > 0) nheaders else 1, @sizeOf(QuicheH3Header)) orelse
        return CURLE_OUT_OF_MEMORY;
    defer mem.free(nva_raw);
    const nva: [*]QuicheH3Header = @ptrCast(@alignCast(nva_raw));

    var i: usize = 0;
    while (i < nheaders) : (i += 1) {
        const e = io_buffers.Curl_dynhds_getn(&h2_headers, i) orelse break;
        nva[i] = .{
            .name = e.name,
            .name_len = e.namelen,
            .value = e.value,
            .value_len = e.valuelen,
        };
    }

    const rest_len = len - nparsed;
    const send_fin = eos and (rest_len == 0);
    s.upload_left = if (send_fin) 0 else if (eos) rest_len else std.math.maxInt(usize);

    const stream3_id = quiche_ext.quiche_h3_send_request(
        h3c,
        qconn,
        nva,
        nheaders,
        send_fin,
    );
    if (stream3_id < 0) {
        if (stream3_id == QUICHE_H3_ERR_STREAM_BLOCKED) {
            Curl_trc_cf_infof(data, cf, "send_request, stream blocked");
            s.quic_flow_blocked = true;
            pnwritten.* = 0;
            return CURLE_AGAIN;
        }
        Curl_trc_cf_infof(data, cf, "quiche_h3_send_request returned %" ++ "lld", @as(c_longlong, stream3_id));
        pnwritten.* = 0;
        return CURLE_SEND_ERROR;
    }

    s.id = stream3_id;
    s.closed = false;
    s.reset = false;
    s.send_closed = send_fin;

    if (nparsed < len) {
        const rest = buf + nparsed;
        var bw: usize = 0;
        var sctx = SendBodyCtx{ .cf = cf, .data = data, .stream = s };
        const berr = cf_quiche_send_body(&sctx, rest, rest_len, &bw);
        if (bw == 0 and berr != CURLE_OK and berr != CURLE_AGAIN) {
            return berr;
        }
        if (bw > 0) {
            pnwritten.* += bw;
            if (s.upload_left > bw) {
                s.upload_left -= bw;
            } else {
                s.upload_left = 0;
            }
        }
    }

    return CURLE_OK;
}

fn cf_quiche_send(
    cf: *CurlCfilter,
    data: ?*CurlEasy,
    buf_raw: ?*const anyopaque,
    len: usize,
    eos: bool,
    pnwritten: *usize,
) callconv(.c) CURLcode {
    pnwritten.* = 0;
    if (comptime !use_quiche) return CURLE_NOT_BUILT_IN;
    const buf: [*]const u8 = @ptrCast(buf_raw orelse return CURLE_BAD_FUNCTION_ARGUMENT);
    const d = data orelse return CURLE_SEND_ERROR;
    const ctx = cfToQuicheCtx(cf) orelse return CURLE_SEND_ERROR;

    var save: CfCallData = undefined;
    cfDataSave(&save, &ctx.call_data, d);
    defer cfDataRestore(&ctx.call_data, save);

    var result = process_ingress(cf, d);
    if (result != CURLE_OK) return result;

    const stream = H3_STREAM_CTX(ctx, d);
    if (stream == null or stream.?.id < 0) {
        result = h3_open_stream(cf, d, buf, len, eos, pnwritten);
        if (result != CURLE_OK) {
            const result2 = flush_egress(cf, d);
            return Curl_1st_fatal(result, result2);
        }
    } else {
        const s = stream.?;
        if (eos and s.upload_left > len) {
            s.upload_left = len;
        }
        if (!io_buffers.Curl_bufq_is_empty(&s.sendbuf)) {
            result = cf_quiche_resume_upload(cf, d, s);
            if (result != CURLE_OK) return result;
        }

        if (s.closed) {
            if (s.resp_hds_complete) {
                pnwritten.* = len;
                return CURLE_OK;
            }
            return CURLE_HTTP3;
        }

        var sctx = SendBodyCtx{ .cf = cf, .data = d, .stream = s };
        var nw: usize = 0;
        const berr = cf_quiche_send_body(&sctx, buf, len, &nw);
        if (nw > 0) {
            pnwritten.* = nw;
            if (s.upload_left > nw) {
                s.upload_left -= nw;
            } else {
                s.upload_left = 0;
            }
        } else if (berr == CURLE_AGAIN) {
            if (!io_buffers.Curl_bufq_is_full(&s.sendbuf)) {
                result = io_buffers.Curl_bufq_write(&s.sendbuf, buf, len, &nw);
                if (result == CURLE_OK and nw > 0) {
                    pnwritten.* = nw;
                } else {
                    result = berr;
                }
            } else {
                result = berr;
            }
        } else {
            result = berr;
        }
    }

    const result2 = flush_egress(cf, d);
    return Curl_1st_fatal(result, result2);
}

// ============================================================================
// Context Lifecycle & Connection Setup
// ============================================================================

fn cf_quiche_ctx_init(ctx: *CfQuicheCtx, cf: *CurlCfilter) CURLcode {
    std.debug.assert(!ctx.initialized);
    ctx.cf = cf;
    ctx.qlogfd = -1;
    io_buffers.Curl_bufcp_init(&ctx.stream_bufcp, H3_STREAM_CHUNK_SIZE, H3_STREAM_POOL_SPARES);
    Curl_u32_ptrset_init(&ctx.streams, h3_stream_hash_free);
    ctx.data_recvd = 0;
    ctx.max_stream_window = H3_STREAM_WINDOW_SIZE;
    ctx.initialized = true;
    return CURLE_OK;
}

fn cf_quiche_ctx_cleanup(c: *CfQuicheCtx) void {
    if (c.initialized) {
        if (comptime use_quiche) {
            if (c.h3c) |h3c| {
                quiche_ext.quiche_h3_conn_free(h3c);
                c.h3c = null;
            }
            if (c.h3config) |h3cfg| {
                quiche_ext.quiche_h3_config_free(h3cfg);
                c.h3config = null;
            }
            if (c.qconn) |qconn| {
                quiche_ext.quiche_conn_free(qconn);
                c.qconn = null;
            }
            if (c.cfg) |cfg| {
                quiche_ext.quiche_config_free(cfg);
                c.cfg = null;
            }
        }
        closeFd(c.qlogfd);
        c.qlogfd = -1;
        vquic_core.Curl_vquic_tls_cleanup(&c.tls);
        vtls_backends.vtls_impl.Curl_ssl_peer_cleanup(&c.ssl_peer);
        vquic_core.Curl_vquic_ctx_free(&c.q);
        Curl_u32_ptrset_clear(&c.streams);
        io_buffers.Curl_bufcp_free(&c.stream_bufcp);
        c.initialized = false;
    } else {
        vtls_backends.vtls_impl.Curl_ssl_peer_cleanup(&c.ssl_peer);
    }
}

fn cf_quiche_ctx_free(ctx: ?*CfQuicheCtx) void {
    const c = ctx orelse return;
    cf_quiche_ctx_cleanup(c);
    mem.freeTyped(c);
}

fn cf_quiche_close(cf: *CurlCfilter, data: ?*CurlEasy) void {
    const ctx = cfToQuicheCtx(cf) orelse return;

    var save: CfCallData = undefined;
    cfDataSave(&save, &ctx.call_data, data);
    defer cfDataRestore(&ctx.call_data, save);

    if (cf.isConnected() or ctx.qconn != null) {
        cf.setConnected(false);
        if (ctx.initialized) {
            if (comptime use_quiche) {
                if (ctx.h3c) |h3c| {
                    quiche_ext.quiche_h3_conn_free(h3c);
                    ctx.h3c = null;
                }
                if (ctx.h3config) |h3cfg| {
                    quiche_ext.quiche_h3_config_free(h3cfg);
                    ctx.h3config = null;
                }
                if (ctx.qconn) |qconn| {
                    _ = quiche_ext.quiche_conn_close(qconn, true, 0, "", 0);
                    if (data) |d| {
                        _ = flush_egress(cf, d);
                    }
                    quiche_ext.quiche_conn_free(qconn);
                    ctx.qconn = null;
                }
                if (ctx.cfg) |cfg| {
                    quiche_ext.quiche_config_free(cfg);
                    ctx.cfg = null;
                }
            }
            closeFd(ctx.qlogfd);
            ctx.qlogfd = -1;
            vquic_core.Curl_vquic_tls_cleanup(&ctx.tls);
            vquic_core.Curl_vquic_ctx_free(&ctx.q);
            Curl_u32_ptrset_clear(&ctx.streams);
            io_buffers.Curl_bufcp_free(&ctx.stream_bufcp);
            ctx.initialized = false;
        }
    }
}

fn cf_quiche_destroy(cf: *CurlCfilter, data: ?*CurlEasy) callconv(.c) void {
    const ctx = cfToQuicheCtx(cf) orelse return;
    {
        var save: CfCallData = undefined;
        cfDataSave(&save, &ctx.call_data, data);
        defer cfDataRestore(&ctx.call_data, save);
        cf_quiche_ctx_cleanup(ctx);
    }
    mem.freeTyped(ctx);
    cf.ctx = null;
}

fn cf_quiche_tls_ctx_setup(
    cf: *CurlCfilter,
    data: ?*CurlEasy,
    cb_user_data: ?*anyopaque,
) callconv(.c) CURLcode {
    _ = cf;
    _ = data;
    _ = cb_user_data;
    return CURLE_OK;
}

fn cf_quiche_ctx_open(
    cf: *CurlCfilter,
    data: *CurlEasy,
) CURLcode {
    if (comptime !use_quiche) return CURLE_NOT_BUILT_IN;
    const ctx = cfToQuicheCtx(cf) orelse return CURLE_FAILED_INIT;
    const result_init = cf_quiche_ctx_init(ctx, cf);
    if (result_init != CURLE_OK) return result_init;

    var result = vquic_core.Curl_vquic_ctx_init(data, &ctx.q);
    if (result != CURLE_OK) return result;

    const cfg = quiche_ext.quiche_config_new(QUICHE_PROTOCOL_VERSION) orelse
        return CURLE_FAILED_INIT;
    ctx.cfg = cfg;
    quiche_ext.quiche_config_set_max_idle_timeout(cfg, QUIC_IDLE_TIMEOUT_MS);
    quiche_ext.quiche_config_set_initial_max_data(cfg, (1 * 1024 * 1024) * 2);
    quiche_ext.quiche_config_set_initial_max_stream_data_bidi_local(cfg, H3_STREAM_WINDOW_SIZE);
    quiche_ext.quiche_config_set_initial_max_stream_data_bidi_remote(cfg, H3_STREAM_WINDOW_SIZE);
    quiche_ext.quiche_config_set_initial_max_stream_data_uni(cfg, H3_STREAM_WINDOW_SIZE);
    quiche_ext.quiche_config_set_initial_max_streams_bidi(cfg, QUIC_MAX_STREAMS);
    quiche_ext.quiche_config_set_initial_max_streams_uni(cfg, QUIC_MAX_STREAMS);
    quiche_ext.quiche_config_set_disable_active_migration(cfg, true);
    quiche_ext.quiche_config_enable_pacing(cfg, false);

    if (quiche_ext.quiche_config_set_application_protos(
        cfg,
        QUICHE_H3_APPLICATION_PROTOCOL.ptr,
        QUICHE_H3_APPLICATION_PROTOCOL.len,
    ) < 0) {
        return CURLE_FAILED_INIT;
    }

    result = vquic_core.Curl_vquic_tls_init(
        &ctx.tls,
        cf,
        data,
        &ctx.ssl_peer,
        &ALPN_SPEC_H3,
        cf_quiche_tls_ctx_setup,
        &ctx.tls.ossl,
        ctx,
        null,
    );
    if (result != CURLE_OK) return result;

    if (vtls_backends.vtls_impl.Curl_ssl_cf_get_filter_config(cf)) |conn_config| {
        quiche_ext.quiche_config_verify_peer(cfg, conn_config.verifypeer());
        const cafile = conn_config.CAfile orelse quiche_ext.Curl_vtls_acc_ssl_cainfo(data, false);
        if (cafile) |ca| {
            _ = quiche_ext.quiche_config_load_verify_locations_from_file(cfg, ca);
        }
        if (conn_config.CApath) |capath| {
            _ = quiche_ext.quiche_config_load_verify_locations_from_directory(cfg, capath);
        }
        if (conn_config.clientcert) |cert| {
            _ = quiche_ext.quiche_config_load_cert_chain_from_pem_file(cfg, cert);
        }
        if (conn_config.key) |key| {
            _ = quiche_ext.quiche_config_load_priv_key_from_pem_file(cfg, key);
        }
    }

    result = Curl_rand_bytes(data, &ctx.scid, ctx.scid.len);
    if (result != CURLE_OK) return result;

    var addr: ?*CurlSockaddrEx = null;
    if (Curl_cf_socket_peek(cf.next, data, &ctx.q.sockfd, &addr, null) != CURLE_OK) {
        ctx.q.sockfd = CURL_SOCKET_BAD;
        ctx.q.no_gso = true;
    }

    var local_ptr: *const anyopaque = @ptrCast(&ctx.q.local_addr);
    var local_len: socklen_t = ctx.q.local_addrlen;
    var remote_ptr: *const anyopaque = @ptrCast(&ctx.q.local_addr);
    var remote_len: socklen_t = ctx.q.local_addrlen;

    if (ctx.q.sockfd != CURL_SOCKET_BAD and addr != null) {
        ctx.q.local_addrlen = @sizeOf(SockaddrStorage);
        if (posix_io.getsockname(
            ctx.q.sockfd,
            @ptrCast(&ctx.q.local_addr),
            &ctx.q.local_addrlen,
        ) == -1) {
            return CURLE_QUIC_CONNECT_ERROR;
        }
        local_ptr = @ptrCast(&ctx.q.local_addr);
        local_len = ctx.q.local_addrlen;
        remote_ptr = @ptrCast(&addr.?.sa_addr);
        remote_len = addr.?.addrlen;
    }

    const server_name: ?[*:0]const u8 = if (vtls_backends.vtls_impl.Curl_ssl_cf_get_filter_config(cf)) |conn_config|
        (if (conn_config.verifyhost()) ctx.ssl_peer.sni else null)
    else
        ctx.ssl_peer.sni;
    ctx.qconn = quiche_ext.quiche_connect(
        server_name,
        &ctx.scid,
        ctx.scid.len,
        local_ptr,
        local_len,
        remote_ptr,
        remote_len,
        cfg,
    );
    if (ctx.qconn == null) {
        Curl_failf(data, "quiche_connect failed");
        return CURLE_QUIC_CONNECT_ERROR;
    }

    vquic_core.Curl_qlogdir(data, &ctx.scid, ctx.scid.len, &ctx.qlogfd);
    if (ctx.qlogfd != -1) {
        quiche_ext.quiche_conn_set_qlog_fd(
            ctx.qconn.?,
            ctx.qlogfd,
            "qlog title",
            "curl qlog",
        );
    }

    result = flush_egress(cf, data);
    if (result != CURLE_OK) return result;

    return CURLE_OK;
}

fn cf_quiche_verify_peer(
    cf: *CurlCfilter,
    data: *CurlEasy,
) CURLcode {
    if (comptime !use_quiche) return CURLE_NOT_BUILT_IN;
    const ctx = cfToQuicheCtx(cf) orelse return CURLE_FAILED_INIT;
    const qconn = ctx.qconn orelse return CURLE_FAILED_INIT;

    if (cf.conn) |conn| {
        Curl_conn_set_multiplex(conn);
        Curl_http_acc_conn_set_httpversion_seen(conn, 30);
    }

    const conn_config = vtls_backends.vtls_impl.Curl_ssl_cf_get_filter_config(cf) orelse
        return CURLE_FAILED_INIT;

    if (conn_config.verifypeer() or conn_config.verifyhost()) {
        var cert_der: ?[*]const u8 = null;
        var cert_der_len: usize = 0;
        quiche_ext.quiche_conn_peer_cert(qconn, &cert_der, &cert_der_len);
        if (cert_der == null or cert_der_len == 0) {
            Curl_failf(data, "SSL: couldn't get peer certificate!");
            return CURLE_PEER_FAILED_VERIFICATION;
        }
        if (conn_config.verifyhost() and backend_options.ssl == .openssl) {
            var p: [*]const u8 = cert_der.?;
            const x509 = quiche_ext.d2i_X509(null, &p, @intCast(cert_der_len)) orelse {
                Curl_failf(data, "SSL: failed to parse peer DER certificate");
                return CURLE_PEER_FAILED_VERIFICATION;
            };
            defer quiche_ext.X509_free(x509);
            const vh_rc = quiche_ext.Curl_ossl_verifyhost(data, cf.conn, &ctx.ssl_peer, x509);
            if (vh_rc != CURLE_OK) return vh_rc;
        }
    } else {
        const rc = vquic_core.Curl_vquic_tls_verify_peer(&ctx.tls, cf, data, &ctx.ssl_peer);
        if (rc != CURLE_OK) return rc;
    }

    return CURLE_OK;
}

fn cf_quiche_connect(
    cf: *CurlCfilter,
    data: ?*CurlEasy,
    done: *bool,
) callconv(.c) CURLcode {
    done.* = false;
    if (comptime !use_quiche) return CURLE_NOT_BUILT_IN;
    const d = data orelse return CURLE_QUIC_CONNECT_ERROR;
    const ctx = cfToQuicheCtx(cf) orelse return CURLE_QUIC_CONNECT_ERROR;

    if (cf.isConnected()) {
        done.* = true;
        return CURLE_OK;
    }

    var save: CfCallData = undefined;
    cfDataSave(&save, &ctx.call_data, d);
    defer cfDataRestore(&ctx.call_data, save);

    var dbool = false;
    var result = Curl_conn_cf_connect(cf.next, d, &dbool);
    if (result != CURLE_OK or !dbool) {
        done.* = false;
        return result;
    }

    done.* = false;
    ctx.q.last_op = Curl_pgrs_now(d).*;

    if (ctx.reconnect_at.tv_sec != 0 and
        curlx_time_net.curlx_ptimediff_ms(&ctx.q.last_op, &ctx.reconnect_at) < 0)
    {
        return CURLE_OK;
    }

    if (ctx.qconn == null) {
        ctx.started_at = ctx.q.last_op;
        result = cf_quiche_ctx_open(cf, d);
        if (result != CURLE_OK) return result;
        result = flush_egress(cf, d);
        return result;
    }

    const qconn = ctx.qconn.?;
    result = process_ingress(cf, d);
    if (result != CURLE_OK) return result;

    result = flush_egress(cf, d);
    if (result != CURLE_OK) return result;

    if (quiche_ext.quiche_conn_is_established(qconn)) {
        ctx.handshake_at = ctx.q.last_op;
        Curl_trc_cf_infof(d, cf, "handshake complete after %" ++ "lldms", @as(c_longlong, curlx_time_net.curlx_ptimediff_ms(&ctx.handshake_at, &ctx.started_at)));
        result = cf_quiche_verify_peer(cf, d);
        if (result != CURLE_OK) return result;

        const h3cfg = quiche_ext.quiche_h3_config_new() orelse return CURLE_OUT_OF_MEMORY;
        ctx.h3config = h3cfg;
        ctx.h3c = quiche_ext.quiche_h3_conn_new_with_transport(qconn, h3cfg) orelse
            return CURLE_OUT_OF_MEMORY;

        cf.setConnected(true);
        done.* = true;
        Curl_pgrsTimeWas(d, TIMER_CONNECT, ctx.started_at);
        Curl_pgrsTimeWas(d, TIMER_APPCONNECT, ctx.handshake_at);
        multiConnChanged(d);
    } else if (quiche_ext.quiche_conn_is_draining(qconn)) {
        ctx.reconnect_at = ctx.q.last_op;
        ctx.reconnect_at.tv_usec += 100 * 1000;
        cf_quiche_close(cf, d);
        done.* = false;
    } else if (quiche_ext.quiche_conn_is_closed(qconn)) {
        var is_app = false;
        var app_error: u64 = 0;
        var reason: [*]const u8 = undefined;
        var reason_len: usize = 0;
        if (quiche_ext.quiche_conn_peer_error(qconn, &is_app, &app_error, &reason, &reason_len)) {
            if (!is_app and app_error == 0x0100 + 48) { // TLS unknown_ca
                return CURLE_PEER_FAILED_VERIFICATION;
            }
            Curl_failf(
                d,
                "connection refused by server, %s error 0x%" ++ "llx, reason: %.*s",
                if (is_app) @as([*:0]const u8, "app") else "transport",
                @as(c_ulonglong, app_error),
                @as(c_int, @intCast(reason_len)),
                reason,
            );
        }
        return CURLE_QUIC_CONNECT_ERROR;
    }

    return result;
}

// ============================================================================
// Shutdown, Pollset, Data Pending, Control, Alive, Query
// ============================================================================

fn cf_quiche_shutdown(
    cf: *CurlCfilter,
    data: ?*CurlEasy,
    done: *bool,
) callconv(.c) CURLcode {
    done.* = true;
    if (comptime !use_quiche) return CURLE_NOT_BUILT_IN;
    const d = data orelse return CURLE_OK;
    const ctx = cfToQuicheCtx(cf) orelse return CURLE_OK;
    if (cf.isShutdown() or ctx.qconn == null) {
        return CURLE_OK;
    }

    var save: CfCallData = undefined;
    cfDataSave(&save, &ctx.call_data, d);
    defer cfDataRestore(&ctx.call_data, save);

    done.* = false;
    if (!ctx.shutdown_started) {
        ctx.shutdown_started = true;
        ctx.q.last_op = Curl_pgrs_now(d).*;
        const rc = quiche_ext.quiche_conn_close(ctx.qconn.?, true, 0, "", 0);
        if (rc < 0) {
            Curl_failf(d, "error %d adding shutdown frame", rc);
            return CURLE_SEND_ERROR;
        }
    }

    if (!io_buffers.Curl_bufq_is_empty(&ctx.q.sendbuf)) {
        const result = vquic_core.Curl_vquic_flush(cf, d, &ctx.q);
        if (result != CURLE_OK) return result;
    }

    if (io_buffers.Curl_bufq_is_empty(&ctx.q.sendbuf)) {
        var send_info: QuicheSendInfo = undefined;
        var buf: [MAX_UDP_PAYLOAD_SIZE]u8 = undefined;
        const nwritten = quiche_ext.quiche_conn_send(
            ctx.qconn.?,
            &buf,
            buf.len,
            &send_info,
        );
        if (nwritten == @backingInt(QuicheError.QUICHE_ERR_DONE)) {
            done.* = true;
            return CURLE_OK;
        } else if (nwritten < 0) {
            done.* = true;
            return CURLE_SEND_ERROR;
        } else {
            const result = flush_egress(cf, d);
            if (result == CURLE_AGAIN) return CURLE_OK;
            return result;
        }
    }

    return CURLE_OK;
}

fn cf_quiche_adjust_pollset(
    cf: *CurlCfilter,
    data: ?*CurlEasy,
    ps_opt: ?*EasyPollset,
) callconv(.c) CURLcode {
    const ps = ps_opt orelse return CURLE_OK;
    const ctx = cfToQuicheCtx(cf) orelse return CURLE_OK;
    if (ctx.qconn == null) {
        return Curl_conn_cf_adjust_pollset(cf.next, data, ps);
    }

    var want_recv = false;
    var want_send = !io_buffers.Curl_bufq_is_empty(&ctx.q.sendbuf);
    if (!cf.isConnected()) {
        want_recv = true;
    } else if (H3_STREAM_CTX(ctx, data)) |stream| {
        const s_exhaust = stream.closed or stream.quic_flow_blocked;
        want_recv = true;
        if (!s_exhaust and !io_buffers.Curl_bufq_is_empty(&stream.sendbuf)) {
            want_send = true;
        }
    }

    if (want_recv or want_send) {
        var sock: curl_socket_t = ctx.q.sockfd;
        if (sock == CURL_SOCKET_BAD) {
            _ = Curl_cf_socket_peek(cf.next, data, &sock, null, null);
        }
        if (sock != CURL_SOCKET_BAD) {
            return headers_sock.Curl_pollset_change(
                data,
                @ptrCast(@alignCast(ps)),
                sock,
                (if (want_recv) headers_sock.CURL_POLL_IN else 0) |
                    (if (want_send) headers_sock.CURL_POLL_OUT else 0),
                0,
            );
        }
    }
    return CURLE_OK;
}

fn cf_quiche_data_pending(
    cf: *CurlCfilter,
    data: ?*const CurlEasy,
) callconv(.c) bool {
    const ctx = cfToQuicheCtx(cf) orelse return false;
    if (H3_STREAM_CTX(ctx, data)) |stream| {
        if (!io_buffers.Curl_bufq_is_empty(&stream.sendbuf)) return true;
    }
    return false;
}

fn cf_quiche_cntrl(
    cf: *CurlCfilter,
    data: ?*CurlEasy,
    event: c_int,
    arg1: c_int,
    arg2: ?*anyopaque,
) callconv(.c) CURLcode {
    _ = arg2;
    const d = data orelse return CURLE_OK;
    const ctx = cfToQuicheCtx(cf) orelse return CURLE_OK;

    var save: CfCallData = undefined;
    cfDataSave(&save, &ctx.call_data, d);
    defer cfDataRestore(&ctx.call_data, save);

    var result: CURLcode = CURLE_OK;
    switch (event) {
        CF_CTRL_DATA_SETUP => {},
        CF_CTRL_DATA_PAUSE => {
            if (arg1 == 0) {
                result = cf_quiche_pass_data(cf, d);
                if (result == CURLE_OK) {
                    result = flush_egress(cf, d);
                }
            }
        },
        CF_CTRL_DATA_DONE => {
            h3_stream_close(cf, d, H3_STREAM_CTX(ctx, d));
        },
        CF_CTRL_DATA_DONE_SEND => {
            if (H3_STREAM_CTX(ctx, d)) |stream| {
                if (!stream.send_closed) {
                    stream.upload_left = io_buffers.Curl_bufq_len(&stream.sendbuf);
                    result = flush_egress(cf, d);
                }
            }
        },
        CF_CTRL_CONN_INFO_UPDATE => {
            if (cf.sockindex == 0 and cf.isConnected()) {
                if (cf.conn) |conn| {
                    Curl_http_acc_conn_set_httpversion_seen(conn, 30);
                    Curl_conn_set_multiplex(conn);
                }
            }
        },
        else => {},
    }
    return result;
}

fn cf_quiche_is_alive(
    cf: *CurlCfilter,
    data: ?*CurlEasy,
    input_pending: *bool,
) callconv(.c) bool {
    input_pending.* = false;
    if (comptime !use_quiche) return false;
    const d = data orelse return false;
    const ctx = cfToQuicheCtx(cf) orelse return false;
    const qconn = ctx.qconn orelse return false;

    if (quiche_ext.quiche_conn_is_closed(qconn)) return false;

    var save: CfCallData = undefined;
    cfDataSave(&save, &ctx.call_data, d);
    defer cfDataRestore(&ctx.call_data, save);

    if (cf_quiche_io(cf, d) != CURLE_OK) return false;

    if (cf.next) |next| {
        if (!next.cft.is_alive(next, d, input_pending)) return false;
        if (input_pending.*) {
            input_pending.* = false;
            if (cf_quiche_io(cf, d) != CURLE_OK) return false;
        }
    }
    return !quiche_ext.quiche_conn_is_closed(qconn) and !quiche_ext.quiche_conn_is_draining(qconn);
}

fn cf_quiche_query(
    cf: *CurlCfilter,
    data: ?*CurlEasy,
    query: c_int,
    pres1: ?*c_int,
    pres2: ?*anyopaque,
) callconv(.c) CURLcode {
    const ctx = cfToQuicheCtx(cf) orelse return Curl_cf_def_query(cf, data, query, pres1, pres2);

    var save: CfCallData = undefined;
    cfDataSave(&save, &ctx.call_data, data);
    defer cfDataRestore(&ctx.call_data, save);

    switch (query) {
        CF_QUERY_MAX_CONCURRENT => {
            if (comptime use_quiche) {
                const p1 = pres1 orelse return CURLE_BAD_FUNCTION_ARGUMENT;
                const qconn = ctx.qconn orelse {
                    p1.* = 0;
                    return CURLE_OK;
                };
                const max_streams: u64 = if (cf.conn) |c| Curl_conn_get_attached_xfers(c) else 0;
                if (!ctx.goaway) {
                    const left = quiche_ext.quiche_conn_peer_streams_left_bidi(qconn);
                    const total = left + max_streams;
                    p1.* = if (total > std.math.maxInt(c_int))
                        std.math.maxInt(c_int)
                    else
                        @intCast(total);
                } else {
                    p1.* = 0;
                }
                return CURLE_OK;
            }
        },
        CF_QUERY_CONNECT_REPLY_MS => {
            if (pres1) |p1| {
                if (ctx.q.got_first_byte) {
                    const ms = curlx_time_net.curlx_ptimediff_ms(&ctx.q.first_byte_at, &ctx.started_at);
                    p1.* = if (ms < std.math.maxInt(c_int)) @intCast(ms) else std.math.maxInt(c_int);
                } else {
                    p1.* = -1;
                }
            }
            return CURLE_OK;
        },
        CF_QUERY_TIMER_CONNECT => {
            if (pres2) |p2| {
                const ts: *Curltime = @ptrCast(@alignCast(p2));
                if (ctx.q.got_first_byte) {
                    ts.* = ctx.q.first_byte_at;
                }
            }
            return CURLE_OK;
        },
        CF_QUERY_TIMER_APPCONNECT => {
            if (pres2) |p2| {
                const ts: *Curltime = @ptrCast(@alignCast(p2));
                if (cf.isConnected()) {
                    ts.* = ctx.handshake_at;
                }
            }
            return CURLE_OK;
        },
        CF_QUERY_HTTP_VERSION => {
            if (pres1) |p1| {
                p1.* = 30;
            }
            return CURLE_OK;
        },
        CF_QUERY_SSL_INFO, CF_QUERY_SSL_CTX_INFO => {
            if (pres2) |p2| {
                const info: *CurlTlsSessionInfo = @ptrCast(@alignCast(p2));
                if (vquic_core.Curl_vquic_tls_get_ssl_info(
                    &ctx.tls,
                    query == CF_QUERY_SSL_CTX_INFO,
                    info,
                )) {
                    return CURLE_OK;
                }
            }
            return Curl_cf_def_query(cf, data, query, pres1, pres2);
        },
        CF_QUERY_ALPN_NEGOTIATED => {
            if (pres2) |p2| {
                const palpn: *?[*:0]const u8 = @ptrCast(@alignCast(p2));
                palpn.* = if (cf.isConnected()) "h3" else null;
            }
            return CURLE_OK;
        },
        else => {},
    }

    return Curl_cf_def_query(cf, data, query, pres1, pres2);
}

// ============================================================================
// Filter Table & Creation Entrypoints
// ============================================================================

pub var Curl_cft_http3 = CurlCftype{
    .name = "HTTP/3",
    .flags = CF_TYPE_IP_CONNECT | CF_TYPE_SSL | CF_TYPE_MULTIPLEX | CF_TYPE_HTTP,
    .log_level = CURL_LOG_LVL_NONE,
    .destroy = cf_quiche_destroy,
    .do_connect = cf_quiche_connect,
    .do_shutdown = cf_quiche_shutdown,
    .adjust_pollset = cf_quiche_adjust_pollset,
    .has_data_pending = cf_quiche_data_pending,
    .do_send = cf_quiche_send,
    .do_recv = cf_quiche_recv,
    .cntrl = cf_quiche_cntrl,
    .is_alive = cf_quiche_is_alive,
    .keep_alive = Curl_cf_def_conn_keep_alive,
    .query = cf_quiche_query,
};

pub fn Curl_cf_quiche_create(
    pcf: *?*CurlCfilter,
    data: ?*CurlEasy,
    origin: ?*CurlPeer,
    peer: ?*CurlPeer,
    conn: ?*ConnectData,
    addr: ?*CurlSockaddrEx,
) callconv(.c) CURLcode {
    pcf.* = null;
    if (comptime !use_quiche) return CURLE_NOT_BUILT_IN;

    const ctx_raw = mem.calloc(1, @sizeOf(CfQuicheCtx)) orelse
        return CURLE_OUT_OF_MEMORY;
    const ctx: *CfQuicheCtx = @ptrCast(@alignCast(ctx_raw));
    ctx.* = .{};

    var result = vquic_core.Curl_vquic_tls_peer_init(origin, peer, null, &ctx.ssl_peer);
    if (result != CURLE_OK) {
        cf_quiche_ctx_free(ctx);
        return result;
    }

    var cf_quiche: ?*CurlCfilter = null;
    result = Curl_cf_create(&cf_quiche, &Curl_cft_http3, ctx);
    if (result != CURLE_OK or cf_quiche == null) {
        cf_quiche_ctx_free(ctx);
        return result;
    }
    cf_quiche.?.conn = conn;

    var cf_udp: ?*CurlCfilter = null;
    result = Curl_cf_udp_create(&cf_udp, data, origin, peer, TRNSPRT_QUIC, conn, addr, null, TRNSPRT_QUIC);
    if (result != CURLE_OK or cf_udp == null) {
        cf_quiche_destroy(cf_quiche.?, data);
        mem.freeTyped(cf_quiche);
        return result;
    }

    cf_quiche.?.next = cf_udp;
    pcf.* = cf_quiche;
    return CURLE_OK;
}

pub fn Curl_cf_quiche_insert_after(
    cf_at: *CurlCfilter,
    origin: ?*CurlPeer,
    peer: ?*CurlPeer,
    pcf: *?*CurlCfilter,
) callconv(.c) CURLcode {
    pcf.* = null;
    if (comptime !use_quiche) return CURLE_NOT_BUILT_IN;

    const ctx_raw = mem.calloc(1, @sizeOf(CfQuicheCtx)) orelse
        return CURLE_OUT_OF_MEMORY;
    const ctx: *CfQuicheCtx = @ptrCast(@alignCast(ctx_raw));
    ctx.* = .{};

    var result = vquic_core.Curl_vquic_tls_peer_init(origin, peer, null, &ctx.ssl_peer);
    if (result != CURLE_OK) {
        cf_quiche_ctx_free(ctx);
        return result;
    }

    var cf: ?*CurlCfilter = null;
    result = Curl_cf_create(&cf, &Curl_cft_http3, ctx);
    if (result != CURLE_OK or cf == null) {
        cf_quiche_ctx_free(ctx);
        return result;
    }

    Curl_conn_cf_insert_after(cf_at, cf.?);
    pcf.* = cf;
    return CURLE_OK;
}

comptime {
    if (use_quiche) {
        @export(&Curl_cft_http3, .{ .name = "Curl_cft_http3", .linkage = .strong });
    }
}

test "Curl_cft_http3 vtable properties for quiche" {
    try std.testing.expectEqualStrings("HTTP/3", std.mem.span(Curl_cft_http3.name));
    try std.testing.expectEqual(
        CF_TYPE_IP_CONNECT | CF_TYPE_SSL | CF_TYPE_MULTIPLEX | CF_TYPE_HTTP,
        Curl_cft_http3.flags,
    );
    try std.testing.expect(@intFromPtr(Curl_cft_http3.do_connect) != 0);
    try std.testing.expect(@intFromPtr(Curl_cft_http3.do_send) != 0);
    try std.testing.expect(@intFromPtr(Curl_cft_http3.do_recv) != 0);
    try std.testing.expect(@intFromPtr(Curl_cft_http3.destroy) != 0);
}

test "Curl_cf_quiche_create and Curl_quiche_ver initialization" {
    var cf: ?*CurlCfilter = null;
    var dummy_addr: CurlSockaddrEx = std.mem.zeroes(CurlSockaddrEx);
    const rc = Curl_cf_quiche_create(
        &cf,
        null,
        null,
        null,
        null,
        &dummy_addr,
    );
    if (comptime use_quiche) {
        try std.testing.expectEqual(CURLE_OK, rc);
        try std.testing.expect(cf != null);
        const h3_cf = cf.?;
        defer {
            if (h3_cf.next) |udp_cf| {
                udp_cf.cft.destroy(udp_cf, null);
                mem.freeTyped(udp_cf);
            }
            h3_cf.cft.destroy(h3_cf, null);
            mem.freeTyped(h3_cf);
        }
        try std.testing.expectEqual(&Curl_cft_http3, h3_cf.cft);
        try std.testing.expect(h3_cf.next != null);

        var ver_buf: [128]u8 = @splat(0);
        Curl_quiche_ver(&ver_buf, ver_buf.len);
        const ver_str = std.mem.sliceTo(&ver_buf, 0);
        try std.testing.expect(std.mem.indexOf(u8, ver_str, "quiche/") != null);
    } else {
        try std.testing.expectEqual(CURLE_NOT_BUILT_IN, rc);
        try std.testing.expect(cf == null);
    }
}

test "vquic_quiche detached easyMid, magic/xfer_id stream validation, and H3StreamCtx freeTyped poisoning" {
    const test_ext = struct {
        extern fn Curl_open(curl: *?*CurlEasy) callconv(.c) CURLcode;
        extern fn Curl_close(datap: *?*CurlEasy) callconv(.c) CURLcode;
        extern fn Curl_zig_url_data_set_i64(data: *CurlEasy, field_id: c_int, val: i64) callconv(.c) void;
        extern fn curl_multi_init() callconv(.c) ?*anyopaque;
        extern fn curl_multi_cleanup(multi: ?*anyopaque) callconv(.c) c_int;
        extern fn curl_multi_add_handle(multi: ?*anyopaque, data: ?*CurlEasy) callconv(.c) c_int;
        extern fn curl_multi_remove_handle(multi: ?*anyopaque, data: ?*CurlEasy) callconv(.c) c_int;
        extern var Curl_cfree: mem.FreeCallback;
        extern "c" fn free(ptr: ?*anyopaque) void;

        var captured_free_bytes: [@sizeOf(H3StreamCtx)]u8 = @splat(0);
        var expected_free_ptr: ?*anyopaque = null;
        var captured_stream_free: bool = false;

        fn mockFree(ptr: ?*anyopaque) callconv(.c) void {
            if (ptr != null and ptr == expected_free_ptr) {
                const src: [*]const u8 = @ptrCast(ptr.?);
                @memcpy(&captured_free_bytes, src[0..@sizeOf(H3StreamCtx)]);
                captured_stream_free = true;
            }
            free(ptr);
        }
    };

    var ctx = CfQuicheCtx{};
    Curl_u32_ptrset_init(&ctx.streams, h3_stream_hash_free);
    io_buffers.Curl_bufcp_init(&ctx.stream_bufcp, H3_STREAM_CHUNK_SIZE, H3_STREAM_POOL_SPARES);
    defer {
        Curl_u32_ptrset_clear(&ctx.streams);
        io_buffers.Curl_bufcp_free(&ctx.stream_bufcp);
    }

    var dummy_cf: CurlCfilter = std.mem.zeroes(CurlCfilter);
    dummy_cf.cft = &Curl_cft_http3;
    dummy_cf.ctx = &ctx;

    // 1. Detached easy handle (mid = -1 / maxInt(u32)) does not panic and is rejected
    var easy_opt: ?*CurlEasy = null;
    try std.testing.expectEqual(CURLE_OK, test_ext.Curl_open(&easy_opt));
    defer _ = test_ext.Curl_close(&easy_opt);
    const easy = easy_opt.?;

    try std.testing.expect(goodEasyHandle(easy));
    try std.testing.expectEqual(std.math.maxInt(u32), easyMid(easy));
    try std.testing.expectEqual(std.math.maxInt(u32), easyMid(null));
    try std.testing.expectEqual(@as(?*H3StreamCtx, null), H3_STREAM_CTX(&ctx, easy));
    try std.testing.expectEqual(@as(?*H3StreamCtx, null), H3_STREAM_CTX(&ctx, null));

    var opened_stream: ?*H3StreamCtx = null;
    try std.testing.expectEqual(CURLE_BAD_FUNCTION_ARGUMENT, h3_stream_open(&dummy_cf, easy, &opened_stream));
    try std.testing.expectEqual(@as(?*H3StreamCtx, null), opened_stream);

    // 2. Attach to multi, open stream, and verify lookup works when magic + mid + xfer_id match
    const multi = test_ext.curl_multi_init() orelse return error.OutOfMemory;
    defer _ = test_ext.curl_multi_cleanup(multi);
    try std.testing.expectEqual(@as(c_int, 0), test_ext.curl_multi_add_handle(multi, easy));
    defer _ = test_ext.curl_multi_remove_handle(multi, easy);

    test_ext.Curl_zig_url_data_set_i64(easy, 2, 303);
    const orig_mid = easyMid(easy);
    try std.testing.expect(orig_mid != std.math.maxInt(u32));

    try std.testing.expectEqual(CURLE_OK, h3_stream_open(&dummy_cf, easy, &opened_stream));
    const stream = opened_stream.?;
    stream.id = 8;
    try std.testing.expectEqual(orig_mid, stream.mid);
    try std.testing.expectEqual(@as(i64, 303), stream.xfer_id);
    try std.testing.expectEqual(@as(?*H3StreamCtx, stream), H3_STREAM_CTX(&ctx, easy));

    ctx.call_data.data = easy;
    var dummy_ev: u8 = 1;
    var node = H3EventNode{
        .cf = &dummy_cf,
        .ctx = &ctx,
        .stream_id = 8,
        .ev = if (comptime !use_quiche) @ptrCast(&dummy_ev) else null,
    };
    try std.testing.expect(!h3_stream_match_process(orig_mid, stream, &node));

    // 3. Reject when xfer_id mismatches (simulating mid slot reuse after transfer teardown)
    var dummy_qconn: u8 = 0;
    ctx.qconn = @ptrCast(&dummy_qconn);
    var nctx = NotifyCtx{ .cf = &dummy_cf, .ctx = &ctx };

    test_ext.Curl_zig_url_data_set_i64(easy, 2, 777);
    try std.testing.expectEqual(@as(?*H3StreamCtx, null), H3_STREAM_CTX(&ctx, easy));
    node.ev = @ptrCast(&dummy_ev);
    _ = h3_stream_match_process(orig_mid, stream, &node);
    try std.testing.expect(node.ev != null);

    stream.quic_flow_blocked = true;
    _ = notify_blocked_stream(orig_mid, stream, &nctx);
    try std.testing.expect(stream.quic_flow_blocked);
    test_ext.Curl_zig_url_data_set_i64(easy, 2, 303);

    // 4. Reject when magic != CURLEASY_MAGIC_NUMBER
    test_ext.Curl_zig_url_data_set_i64(easy, 1, 0);
    try std.testing.expect(!goodEasyHandle(easy));
    try std.testing.expectEqual(std.math.maxInt(u32), easyMid(easy));
    try std.testing.expectEqual(@as(?*H3StreamCtx, null), H3_STREAM_CTX(&ctx, easy));
    node.ev = @ptrCast(&dummy_ev);
    _ = h3_stream_match_process(orig_mid, stream, &node);
    try std.testing.expect(node.ev != null);

    stream.quic_flow_blocked = true;
    _ = notify_blocked_stream(orig_mid, stream, &nctx);
    try std.testing.expect(stream.quic_flow_blocked);
    test_ext.Curl_zig_url_data_set_i64(easy, 1, CURLEASY_MAGIC_NUMBER);

    // 5. Verify H3StreamCtx freed-memory poisoning via mem.freeTyped
    const expected_poison: u8 = switch (@import("builtin").mode) {
        .Debug, .ReleaseSafe => 0xaa,
        .ReleaseFast, .ReleaseSmall => 0x00,
    };
    const saved_cfree = test_ext.Curl_cfree;
    test_ext.Curl_cfree = test_ext.mockFree;
    defer test_ext.Curl_cfree = saved_cfree;

    const raw_s = mem.calloc(1, @sizeOf(H3StreamCtx)) orelse return error.OutOfMemory;
    const temp_s: *H3StreamCtx = @ptrCast(@alignCast(raw_s));
    temp_s.* = .{};
    temp_s.id = 12;
    temp_s.mid = 5;
    temp_s.xfer_id = 888;
    io_buffers.Curl_bufq_initp(&temp_s.sendbuf, &ctx.stream_bufcp, 1, BUFQ_OPT_NONE);
    http1_options.Curl_h1_req_parse_init(&temp_s.h1, H3_SEND_SIZE);

    @memset(&test_ext.captured_free_bytes, 0);
    test_ext.expected_free_ptr = @ptrCast(temp_s);
    test_ext.captured_stream_free = false;
    h3_stream_ctx_free(temp_s);
    try std.testing.expect(test_ext.captured_stream_free);
    for (test_ext.captured_free_bytes) |b| {
        try std.testing.expectEqual(expected_poison, b);
    }
}
