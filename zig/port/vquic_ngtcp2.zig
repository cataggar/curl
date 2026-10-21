// Ported from:
//   lib/vquic/cf-ngtcp2-cmn.h + lib/vquic/cf-ngtcp2-cmn.c (2,128 LOC)
//   lib/vquic/cf-ngtcp2.h     + lib/vquic/cf-ngtcp2.c     (1,147 LOC)
//   lib/vquic/cf-ngtcp2-proxy.h + lib/vquic/cf-ngtcp2-proxy.c (1,317 LOC)

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
const vtls_scache_asn1 = @import("vtls_scache_asn1.zig");
const vtls_backends = @import("vtls_backends.zig");
const vtls_gtls = @import("vtls_gtls.zig");
const vtls_wolfssl = @import("vtls_wolfssl.zig");
const vquic_core = @import("vquic_core.zig");
const cfilters_progress = @import("cfilters_progress.zig");

const is_windows = builtin.os.tag == .windows;
pub const use_ngtcp2 = backend_options.quic == .ngtcp2;
pub const use_proxy_http3 = backend_options.proxy_http3;

pub const CURLcode = c_uint;
pub const CURLE_OK: CURLcode = 0;
pub const CURLE_UNSUPPORTED_PROTOCOL: CURLcode = 1;
pub const CURLE_FAILED_INIT: CURLcode = 2;
pub const CURLE_URL_MALFORMAT: CURLcode = 3;
pub const CURLE_NOT_BUILT_IN: CURLcode = 4;
pub const CURLE_COULDNT_RESOLVE_HOST: CURLcode = 6;
pub const CURLE_COULDNT_CONNECT: CURLcode = 7;
pub const CURLE_WEIRD_SERVER_REPLY: CURLcode = 8;
pub const CURLE_HTTP2: CURLcode = 16;
pub const CURLE_PARTIAL_FILE: CURLcode = 18;
pub const CURLE_WRITE_ERROR: CURLcode = 23;
pub const CURLE_OUT_OF_MEMORY: CURLcode = 27;
pub const CURLE_OPERATION_TIMEDOUT: CURLcode = 28;
pub const CURLE_SSL_CONNECT_ERROR: CURLcode = 35;
pub const CURLE_ABORTED_BY_CALLBACK: CURLcode = 42;
pub const CURLE_BAD_FUNCTION_ARGUMENT: CURLcode = 43;
pub const CURLE_INTERNAL_ERROR: CURLcode = 43;
pub const CURLE_SEND_ERROR: CURLcode = 55;
pub const CURLE_RECV_ERROR: CURLcode = 56;
pub const CURLE_PEER_FAILED_VERIFICATION: CURLcode = 60;
pub const CURLE_AGAIN: CURLcode = 81;
pub const CURLE_HTTP3: CURLcode = 95;
pub const CURLE_QUIC_CONNECT_ERROR: CURLcode = 96;
pub const CURLE_PROXY: CURLcode = 97;

pub const curl_socket_t = headers_sock.curl_socket_t;
pub const CURL_SOCKET_BAD = headers_sock.CURL_SOCKET_BAD;
pub const curltime = curlx_time_net.Curltime;
pub const timediff_t = curlx_time_net.timediff_t;
pub const curl_off_t = i64;
pub const socklen_t = vquic_core.socklen_t;
pub const SockaddrStorage = vquic_core.SockaddrStorage;
pub const EasyPollset = vtls_backends.EasyPollset;
pub const Bufq = io_buffers.bufq;
pub const BufcPool = io_buffers.bufc_pool;
pub const dynhds = io_buffers.dynhds;
pub const dynhds_entry = io_buffers.dynhds_entry;
pub const Dynbuf = containers.dynbuf;
pub const h1_req_parser = http1_options.h1_req_parser;
pub const httpreq = http1_options.httpreq;
pub const http_resp = extern struct {
    status: c_int = 0,
    description: ?[*:0]u8 = null,
    headers: dynhds = undefined,
    trailers: dynhds = undefined,
    prev: ?*http_resp = null,
};
pub const u32_ptrset = collections.u32_ptrset;
pub const uint32_bset = collections.uint32_bset;

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
pub const SslEasyConfig = vtls_backends.SslEasyConfig;
pub const CurlSockaddrEx = cfsocket_transfer.CurlSockaddrEx;
pub const AlpnSpec = vtls_backends.AlpnSpec;
pub const CurlSslSession = vtls_core.CurlSslSession;
pub const CurlTlsCtx = vquic_core.CurlTlsCtx;
pub const CfQuicCtx = vquic_core.CfQuicCtx;

pub const CF_TYPE_IP_CONNECT: c_int = 1 << 0;
pub const CF_TYPE_SSL: c_int = 1 << 1;
pub const CF_TYPE_MULTIPLEX: c_int = 1 << 2;
pub const CF_TYPE_PROXY: c_int = 1 << 3;
pub const CF_TYPE_HTTP: c_int = 1 << 4;

pub const CURL_LOG_LVL_NONE: c_int = 0;
pub const CURL_LOG_LVL_INFO: c_int = 1;

pub const CF_CTRL_DATA_SETUP: c_int = 4;
pub const CF_CTRL_DATA_IDLE: c_int = 5;
pub const CF_CTRL_DATA_PAUSE: c_int = 6;
pub const CF_CTRL_DATA_DONE: c_int = 7;
pub const CF_CTRL_DATA_DONE_SEND: c_int = 8;
pub const CF_CTRL_CONN_INFO_UPDATE: c_int = 256 + 0;
pub const CF_CTRL_FORGET_SOCKET: c_int = 256 + 1;
pub const CF_CTRL_FLUSH: c_int = 256 + 2;
pub const CF_CTRL_REPORT_STATS: c_int = 256 + 3;

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
pub const PROXY_HTTP_V3: c_uint = 3;
pub const TRNSPRT_TCP: u8 = vquic_core.TRNSPRT_TCP;
pub const TRNSPRT_UDP: u8 = vquic_core.TRNSPRT_UDP;
pub const TRNSPRT_QUIC: u8 = vquic_core.TRNSPRT_QUIC;
pub const FIRSTSOCKET: i8 = vquic_core.FIRSTSOCKET;
pub const ALPN_h3: c_int = 1 << 5;
pub const CONNCTRL_CONN_CLOSE: c_int = 1;
pub const CURLH_HEADER: u8 = 1 << 0;
pub const CURLH_1XX: u8 = 1 << 3;
pub const CURLH_PSEUDO: u8 = 1 << 4;

const BUFQ_OPT_NONE: c_int = io_buffers.BUFQ_OPT_NONE;
const BUFQ_OPT_SOFT_LIMIT: c_int = io_buffers.BUFQ_OPT_SOFT_LIMIT;
const BUFQ_OPT_NO_SPARES: c_int = io_buffers.BUFQ_OPT_NO_SPARES;

const ALPN_SPEC_H3 = AlpnSpec{
    .entries = .{
        .{ 'h', '3', 0, 0, 0, 0, 0, 0, 0, 0 },
        @splat(0),
        @splat(0),
    },
    .count = 1,
};

// ============================================================================
// 1. ngtcp2 / ngtcp2_crypto / nghttp3 C ABI Types & Constants
// ============================================================================

pub const ngtcp2_tstamp = u64;
pub const ngtcp2_duration = u64;
pub const ngtcp2_ssize = isize;

pub const NGTCP2_PROTO_VER_V1: u32 = 0x00000001;
pub const NGTCP2_PROTO_VER_V2: u32 = 0x6b3343cf;
pub const NGTCP2_PROTO_VER_MAX: u32 = NGTCP2_PROTO_VER_V2;
pub const NGTCP2_MAX_CIDLEN: usize = 20;
pub const NGTCP2_MIN_INITIAL_DCIDLEN: usize = 8;
pub const NGTCP2_MAX_UDP_PAYLOAD_SIZE: usize = vquic_core.MAX_UDP_PAYLOAD_SIZE;
pub const NGTCP2_STATELESS_RESET_TOKENLEN: usize = 16;

pub const NGTCP2_NANOSECONDS: u64 = 1;
pub const NGTCP2_MICROSECONDS: u64 = 1000;
pub const NGTCP2_MILLISECONDS: u64 = 1000000;
pub const NGTCP2_SECONDS: u64 = 1000000000;

pub const NGTCP2_PKT_INFO_VERSION: c_int = 1;
pub const NGTCP2_SETTINGS_VERSION: c_int = 3;
pub const NGTCP2_TRANSPORT_PARAMS_VERSION: c_int = 1;
pub const NGTCP2_CALLBACKS_VERSION: c_int = 2;

pub const NGTCP2_CC_ALGO_CUBIC: c_uint = 1;
pub const NGTCP2_DEFAULT_INITIAL_RTT: u64 = 333 * NGTCP2_MILLISECONDS;
pub const NGTCP2_STREAM_DATA_FLAG_NONE: u32 = 0x00;
pub const NGTCP2_STREAM_DATA_FLAG_FIN: u32 = 0x01;
pub const NGTCP2_STREAM_DATA_FLAG_0RTT: u32 = 0x02;

pub const NGTCP2_WRITE_STREAM_FLAG_NONE: u32 = 0x00;
pub const NGTCP2_WRITE_STREAM_FLAG_MORE: u32 = 0x01;
pub const NGTCP2_WRITE_STREAM_FLAG_FIN: u32 = 0x02;
pub const NGTCP2_WRITE_DATAGRAM_FLAG_NONE: u32 = 0x00;
pub const NGTCP2_WRITE_DATAGRAM_FLAG_MORE: u32 = 0x01;

pub const NGTCP2_ERR_INVALID_ARGUMENT: c_int = -201;
pub const NGTCP2_ERR_NOBUF: c_int = -202;
pub const NGTCP2_ERR_PROTO: c_int = -203;
pub const NGTCP2_ERR_INVALID_STATE: c_int = -204;
pub const NGTCP2_ERR_ACK_FRAME: c_int = -205;
pub const NGTCP2_ERR_STREAM_ID_BLOCKED: c_int = -206;
pub const NGTCP2_ERR_STREAM_IN_USE: c_int = -207;
pub const NGTCP2_ERR_STREAM_DATA_BLOCKED: c_int = -208;
pub const NGTCP2_ERR_FLOW_CONTROL: c_int = -209;
pub const NGTCP2_ERR_CONNECTION_ID_LIMIT: c_int = -210;
pub const NGTCP2_ERR_STREAM_LIMIT: c_int = -211;
pub const NGTCP2_ERR_FINAL_SIZE: c_int = -212;
pub const NGTCP2_ERR_CRYPTO: c_int = -213;
pub const NGTCP2_ERR_PKT_NUM_EXHAUSTED: c_int = -214;
pub const NGTCP2_ERR_REQUIRED_TRANSPORT_PARAM: c_int = -215;
pub const NGTCP2_ERR_MALFORMED_TRANSPORT_PARAM: c_int = -216;
pub const NGTCP2_ERR_FRAME_ENCODING: c_int = -217;
pub const NGTCP2_ERR_DECRYPT: c_int = -218;
pub const NGTCP2_ERR_STREAM_SHUT_WR: c_int = -219;
pub const NGTCP2_ERR_STREAM_NOT_FOUND: c_int = -220;
pub const NGTCP2_ERR_STREAM_STATE: c_int = -221;
pub const NGTCP2_ERR_RECV_VERSION_NEGOTIATION: c_int = -222;
pub const NGTCP2_ERR_CLOSING: c_int = -223;
pub const NGTCP2_ERR_DRAINING: c_int = -224;
pub const NGTCP2_ERR_TRANSPORT_PARAM: c_int = -225;
pub const NGTCP2_ERR_DISCARD_PKT: c_int = -226;
pub const NGTCP2_ERR_CONN_ID_BLOCKED: c_int = -227;
pub const NGTCP2_ERR_INTERNAL: c_int = -228;
pub const NGTCP2_ERR_CRYPTO_BUFFER_EXCEEDED: c_int = -229;
pub const NGTCP2_ERR_WRITE_MORE: isize = -230;
pub const NGTCP2_ERR_RETRY: c_int = -231;
pub const NGTCP2_ERR_DROP_CONN: c_int = -232;
pub const NGTCP2_ERR_AEAD_LIMIT_REACHED: c_int = -233;
pub const NGTCP2_ERR_NO_VIABLE_PATH: c_int = -234;
pub const NGTCP2_ERR_VERSION_NEGOTIATION: c_int = -235;
pub const NGTCP2_ERR_HANDSHAKE_TIMEOUT: c_int = -236;
pub const NGTCP2_ERR_VERSION_NEGOTIATION_FAILURE: c_int = -237;
pub const NGTCP2_ERR_IDLE_CLOSE: c_int = -238;
pub const NGTCP2_ERR_FATAL: c_int = -500;
pub const NGTCP2_ERR_NOMEM: c_int = -501;
pub const NGTCP2_ERR_CALLBACK_FAILURE: c_int = -502;

pub const NGTCP2_NO_ERROR: u64 = 0x00;
pub const NGTCP2_CONNECTION_REFUSED: u64 = 0x02;
pub const NGTCP2_CRYPTO_ERROR: u64 = 0x100;

pub const NGTCP2_CCERR_TYPE_TRANSPORT: c_uint = 0;
pub const NGTCP2_CCERR_TYPE_APPLICATION: c_uint = 1;
pub const NGTCP2_CCERR_TYPE_VERSION_NEGOTIATION: c_uint = 2;
pub const NGTCP2_CCERR_TYPE_IDLE_CLOSE: c_uint = 3;
pub const NGTCP2_CCERR_TYPE_DROP_CONN: c_uint = 4;
pub const NGTCP2_CCERR_TYPE_RETRY: c_uint = 5;

pub const NGTCP2_CRYPTO_LEVEL_INITIAL: c_uint = 0;
pub const NGTCP2_CRYPTO_LEVEL_HANDSHAKE: c_uint = 1;
pub const NGTCP2_CRYPTO_LEVEL_APPLICATION: c_uint = 2;
pub const NGTCP2_CRYPTO_LEVEL_EARLY: c_uint = 3;

pub const NGHTTP3_SETTINGS_VERSION: c_int = 3;
pub const NGHTTP3_CALLBACKS_VERSION: c_int = 2;
pub const NGHTTP3_PRI_VERSION: c_int = 1;

pub const NGHTTP3_DATA_FLAG_NONE: u32 = 0x00;
pub const NGHTTP3_DATA_FLAG_EOF: u32 = 0x01;
pub const NGHTTP3_DATA_FLAG_NO_END_STREAM: u32 = 0x02;
pub const NGHTTP3_NV_FLAG_NONE: u8 = 0x00;
pub const NGHTTP3_NV_FLAG_NEVER_INDEX: u8 = 0x01;
pub const NGHTTP3_NV_FLAG_NO_COPY_NAME: u8 = 0x02;
pub const NGHTTP3_NV_FLAG_NO_COPY_VALUE: u8 = 0x04;

pub const NGHTTP3_ERR_INVALID_ARGUMENT: c_int = -101;
pub const NGHTTP3_ERR_INVALID_STATE: c_int = -102;
pub const NGHTTP3_ERR_WOULDBLOCK: c_int = -103;
pub const NGHTTP3_ERR_STREAM_IN_USE: c_int = -104;
pub const NGHTTP3_ERR_MALFORMED_HTTP_HEADER: c_int = -105;
pub const NGHTTP3_ERR_REMOVE_HTTP_HEADER: c_int = -106;
pub const NGHTTP3_ERR_MALFORMED_HTTP_MESSAGING: c_int = -107;
pub const NGHTTP3_ERR_QPACK_FATAL: c_int = -108;
pub const NGHTTP3_ERR_QPACK_HEADER_TOO_LARGE: c_int = -109;
pub const NGHTTP3_ERR_STREAM_NOT_FOUND: c_int = -110;
pub const NGHTTP3_ERR_CONN_CLOSING: c_int = -111;
pub const NGHTTP3_ERR_STREAM_DATA_OVERFLOW: c_int = -112;
pub const NGHTTP3_ERR_QPACK_DECOMPRESSION_FAILED: c_int = -401;
pub const NGHTTP3_ERR_QPACK_ENCODER_STREAM_ERROR: c_int = -402;
pub const NGHTTP3_ERR_QPACK_DECODER_STREAM_ERROR: c_int = -403;
pub const NGHTTP3_ERR_H3_FRAME_UNEXPECTED: c_int = -601;
pub const NGHTTP3_ERR_H3_FRAME_ERROR: c_int = -602;
pub const NGHTTP3_ERR_H3_MISSING_SETTINGS: c_int = -603;
pub const NGHTTP3_ERR_H3_INTERNAL_ERROR: c_int = -604;
pub const NGHTTP3_ERR_H3_CLOSED_CRITICAL_STREAM: c_int = -605;
pub const NGHTTP3_ERR_H3_GENERAL_PROTOCOL_ERROR: c_int = -606;
pub const NGHTTP3_ERR_H3_ID_ERROR: c_int = -607;
pub const NGHTTP3_ERR_H3_SETTINGS_ERROR: c_int = -608;
pub const NGHTTP3_ERR_H3_STREAM_CREATION_ERROR: c_int = -609;
pub const NGHTTP3_ERR_H3_EXCESSIVE_LOAD: c_int = -610;
pub const NGHTTP3_ERR_FATAL: c_int = -900;
pub const NGHTTP3_ERR_NOMEM: c_int = -901;
pub const NGHTTP3_ERR_CALLBACK_FAILURE: c_int = -902;

pub const NGHTTP3_H3_NO_ERROR: u64 = 0x0100;
pub const NGHTTP3_H3_GENERAL_PROTOCOL_ERROR: u64 = 0x0101;
pub const NGHTTP3_H3_INTERNAL_ERROR: u64 = 0x0102;
pub const NGHTTP3_H3_REQUEST_CANCELLED: u64 = 0x010c;

pub const ngtcp2_conn = opaque {};
pub const ngtcp2_crypto_ossl_ctx = opaque {};
pub const nghttp3_conn = opaque {};

pub const ngtcp2_cid = extern struct {
    datalen: usize = 0,
    data: [NGTCP2_MAX_CIDLEN]u8 = @splat(0),
};

pub const ngtcp2_vec = extern struct {
    base: ?[*]u8 = null,
    len: usize = 0,
};

pub const ngtcp2_addr = extern struct {
    addr: ?*anyopaque = null,
    addrlen: socklen_t = 0,
};

pub const ngtcp2_path = extern struct {
    local: ngtcp2_addr = .{},
    remote: ngtcp2_addr = .{},
    user_data: ?*anyopaque = null,
};

pub const ngtcp2_path_storage = extern struct {
    path: ngtcp2_path = .{},
    local_addrbuf: [28]u8 align(4) = @splat(0),
    remote_addrbuf: [28]u8 align(4) = @splat(0),
};

pub const ngtcp2_pkt_info = extern struct {
    ecn: u8 align(8) = 0,
};

pub const ngtcp2_ccerr = extern struct {
    type: c_uint = 0,
    error_code: u64 = 0,
    frame_type: u64 = 0,
    reason: ?[*]const u8 = null,
    reasonlen: usize = 0,
};

pub const ngtcp2_rand_ctx = extern struct {
    native_handle: ?*anyopaque = null,
};

pub const ngtcp2_preferred_addr = extern struct {
    cid: ngtcp2_cid = .{},
    ipv4: [16]u8 align(4) = @splat(0),
    ipv6: [28]u8 align(4) = @splat(0),
    ipv4_present: u8 = 0,
    ipv6_present: u8 = 0,
    stateless_reset_token: [NGTCP2_STATELESS_RESET_TOKENLEN]u8 = @splat(0),
};

pub const ngtcp2_version_info = extern struct {
    chosen_version: u32 = 0,
    available_versions: ?[*]const u8 = null,
    available_versionslen: usize = 0,
};

pub const ngtcp2_settings = extern struct {
    qlog_write: ?*const fn (user_data: ?*anyopaque, flags: u32, data: ?*const anyopaque, datalen: usize) callconv(.c) void = null,
    cc_algo: c_uint = 0,
    initial_ts: ngtcp2_tstamp = 0,
    initial_rtt: ngtcp2_duration = 0,
    log_printf: ?*const anyopaque = null,
    max_tx_udp_payload_size: usize = 0,
    token: ?[*]const u8 = null,
    tokenlen: usize = 0,
    token_type: c_uint = 0,
    rand_ctx: ngtcp2_rand_ctx = .{},
    max_window: u64 = 0,
    max_stream_window: u64 = 0,
    ack_thresh: usize = 0,
    no_tx_udp_payload_size_shaping: u8 = 0,
    handshake_timeout: ngtcp2_duration = 0,
    preferred_versions: ?[*]const u32 = null,
    preferred_versionslen: usize = 0,
    available_versions: ?[*]const u32 = null,
    available_versionslen: usize = 0,
    original_version: u32 = 0,
    no_pmtud: u8 = 0,
    initial_pkt_num: u32 = 0,
    pmtud_probes: ?[*]const u16 = null,
    pmtud_probeslen: usize = 0,
    glitch_ratelim_burst: u64 = 0,
    glitch_ratelim_rate: u64 = 0,
};

pub const ngtcp2_transport_params = extern struct {
    preferred_addr: ngtcp2_preferred_addr = .{},
    original_dcid: ngtcp2_cid = .{},
    initial_scid: ngtcp2_cid = .{},
    retry_scid: ngtcp2_cid = .{},
    initial_max_stream_data_bidi_local: u64 = 0,
    initial_max_stream_data_bidi_remote: u64 = 0,
    initial_max_stream_data_uni: u64 = 0,
    initial_max_data: u64 = 0,
    initial_max_streams_bidi: u64 = 0,
    initial_max_streams_uni: u64 = 0,
    max_idle_timeout: ngtcp2_duration = 0,
    max_udp_payload_size: u64 = 0,
    Active_connection_id_limit: u64 = 0,
    ack_delay_exponent: u64 = 0,
    max_ack_delay: ngtcp2_duration = 0,
    max_datagram_frame_size: u64 = 0,
    stateless_reset_token_present: u8 = 0,
    disable_active_migration: u8 = 0,
    original_dcid_present: u8 = 0,
    initial_scid_present: u8 = 0,
    retry_scid_present: u8 = 0,
    preferred_addr_present: u8 = 0,
    stateless_reset_token: [NGTCP2_STATELESS_RESET_TOKENLEN]u8 = @splat(0),
    grease_quic_bit: u8 = 0,
    version_info: ngtcp2_version_info = .{},
    version_info_present: u8 = 0,
};

pub const ngtcp2_callbacks = extern struct {
    client_initial: ?*const anyopaque = null,
    recv_client_initial: ?*const anyopaque = null,
    recv_crypto_data: ?*const anyopaque = null,
    handshake_completed: ?*const fn (conn: *ngtcp2_conn, user_data: ?*anyopaque) callconv(.c) c_int = null,
    recv_version_negotiation: ?*const anyopaque = null,
    encrypt: ?*const anyopaque = null,
    decrypt: ?*const anyopaque = null,
    hp_mask: ?*const anyopaque = null,
    recv_stream_data: ?*const fn (conn: *ngtcp2_conn, flags: u32, stream_id: i64, offset: u64, data: ?[*]const u8, datalen: usize, user_data: ?*anyopaque, stream_user_data: ?*anyopaque) callconv(.c) c_int = null,
    acked_stream_data_offset: ?*const fn (conn: *ngtcp2_conn, stream_id: i64, offset: u64, datalen: u64, user_data: ?*anyopaque, stream_user_data: ?*anyopaque) callconv(.c) c_int = null,
    stream_open: ?*const fn (conn: *ngtcp2_conn, stream_id: i64, user_data: ?*anyopaque) callconv(.c) c_int = null,
    stream_close: ?*const fn (conn: *ngtcp2_conn, flags: u32, stream_id: i64, app_error_code: u64, user_data: ?*anyopaque, stream_user_data: ?*anyopaque) callconv(.c) c_int = null,
    recv_stateless_reset: ?*const anyopaque = null,
    recv_retry: ?*const anyopaque = null,
    extend_max_local_streams_bidi: ?*const fn (conn: *ngtcp2_conn, max_streams: u64, user_data: ?*anyopaque) callconv(.c) c_int = null,
    extend_max_local_streams_uni: ?*const anyopaque = null,
    rand: ?*const fn (dest: [*]u8, destlen: usize, rand_ctx: *const ngtcp2_rand_ctx) callconv(.c) void = null,
    get_new_connection_id: ?*const fn (conn: *ngtcp2_conn, cid: *ngtcp2_cid, token: [*]u8, cidlen: usize, user_data: ?*anyopaque) callconv(.c) c_int = null,
    remove_connection_id: ?*const fn (conn: *ngtcp2_conn, cid: *const ngtcp2_cid, user_data: ?*anyopaque) callconv(.c) c_int = null,
    update_key: ?*const anyopaque = null,
    path_validation: ?*const anyopaque = null,
    select_preferred_addr: ?*const anyopaque = null,
    stream_reset: ?*const fn (conn: *ngtcp2_conn, stream_id: i64, final_size: u64, app_error_code: u64, user_data: ?*anyopaque, stream_user_data: ?*anyopaque) callconv(.c) c_int = null,
    extend_max_remote_streams_bidi: ?*const anyopaque = null,
    extend_max_remote_streams_uni: ?*const anyopaque = null,
    extend_max_stream_data: ?*const anyopaque = null,
    dcid_status: ?*const anyopaque = null,
    handshake_confirmed: ?*const anyopaque = null,
    recv_new_token: ?*const anyopaque = null,
    delete_crypto_aead_ctx: ?*const anyopaque = null,
    delete_crypto_cipher_ctx: ?*const anyopaque = null,
    recv_datagram: ?*const fn (conn: *ngtcp2_conn, flags: u32, data: [*]const u8, datalen: usize, user_data: ?*anyopaque) callconv(.c) c_int = null,
    ack_datagram: ?*const anyopaque = null,
    lost_datagram: ?*const anyopaque = null,
    get_path_challenge_data: ?*const anyopaque = null,
    stream_stop_sending: ?*const fn (conn: *ngtcp2_conn, stream_id: i64, app_error_code: u64, user_data: ?*anyopaque, stream_user_data: ?*anyopaque) callconv(.c) c_int = null,
    version_negotiation: ?*const anyopaque = null,
    recv_rx_key: ?*const fn (conn: *ngtcp2_conn, level: c_uint, user_data: ?*anyopaque) callconv(.c) c_int = null,
    recv_tx_key: ?*const fn (conn: *ngtcp2_conn, level: c_uint, user_data: ?*anyopaque) callconv(.c) c_int = null,
    tls_early_data_rejected: ?*const anyopaque = null,
    begin_path_validation: ?*const anyopaque = null,
};

pub const ngtcp2_crypto_conn_ref = extern struct {
    get_conn: ?*const fn (conn_ref: *ngtcp2_crypto_conn_ref) callconv(.c) ?*ngtcp2_conn = null,
    user_data: ?*anyopaque = null,
};

pub const nghttp3_vec = extern struct {
    base: ?[*]u8 = null,
    len: usize = 0,
};

pub const nghttp3_rcbuf = opaque {};

pub const nghttp3_nv = extern struct {
    name: ?[*]const u8 = null,
    value: ?[*]const u8 = null,
    namelen: usize = 0,
    valuelen: usize = 0,
    flags: u8 = 0,
};

pub const nghttp3_read_data_callback = *const fn (
    conn: *nghttp3_conn,
    stream_id: i64,
    vec: [*]nghttp3_vec,
    veccnt: usize,
    pflags: *u32,
    conn_user_data: ?*anyopaque,
    stream_user_data: ?*anyopaque,
) callconv(.c) ngtcp2_ssize;

pub const nghttp3_data_reader = extern struct {
    read_data: ?nghttp3_read_data_callback = null,
};

pub const nghttp3_settings = extern struct {
    max_field_section_size: u64 = 0,
    qpack_max_dtable_capacity: usize = 0,
    qpack_encoder_max_dtable_capacity: usize = 0,
    qpack_blocked_streams: usize = 0,
    enable_connect_protocol: u8 = 0,
    h3_datagram: u8 = 0,
    origin_list: ?*const nghttp3_vec = null,
    glitch_ratelim_burst: u64 = 0,
    glitch_ratelim_rate: u64 = 0,
};

pub const nghttp3_callbacks = extern struct {
    acked_stream_data: ?*const fn (conn: *nghttp3_conn, stream_id: i64, datalen: u64, conn_user_data: ?*anyopaque, stream_user_data: ?*anyopaque) callconv(.c) c_int = null,
    stream_close: ?*const fn (conn: *nghttp3_conn, stream_id: i64, app_error_code: u64, conn_user_data: ?*anyopaque, stream_user_data: ?*anyopaque) callconv(.c) c_int = null,
    recv_data: ?*const fn (conn: *nghttp3_conn, stream_id: i64, data: [*]const u8, datalen: usize, conn_user_data: ?*anyopaque, stream_user_data: ?*anyopaque) callconv(.c) c_int = null,
    deferred_consume: ?*const fn (conn: *nghttp3_conn, stream_id: i64, consumed: usize, conn_user_data: ?*anyopaque, stream_user_data: ?*anyopaque) callconv(.c) c_int = null,
    begin_headers: ?*const fn (conn: *nghttp3_conn, stream_id: i64, conn_user_data: ?*anyopaque, stream_user_data: ?*anyopaque) callconv(.c) c_int = null,
    recv_header: ?*const fn (conn: *nghttp3_conn, stream_id: i64, token: i32, name: *nghttp3_rcbuf, value: *nghttp3_rcbuf, flags: u8, conn_user_data: ?*anyopaque, stream_user_data: ?*anyopaque) callconv(.c) c_int = null,
    end_headers: ?*const fn (conn: *nghttp3_conn, stream_id: i64, fin: c_int, conn_user_data: ?*anyopaque, stream_user_data: ?*anyopaque) callconv(.c) c_int = null,
    begin_trailers: ?*const anyopaque = null,
    recv_trailer: ?*const fn (conn: *nghttp3_conn, stream_id: i64, token: i32, name: *nghttp3_rcbuf, value: *nghttp3_rcbuf, flags: u8, conn_user_data: ?*anyopaque, stream_user_data: ?*anyopaque) callconv(.c) c_int = null,
    end_trailers: ?*const anyopaque = null,
    stop_sending: ?*const fn (conn: *nghttp3_conn, stream_id: i64, app_error_code: u64, conn_user_data: ?*anyopaque, stream_user_data: ?*anyopaque) callconv(.c) c_int = null,
    end_stream: ?*const fn (conn: *nghttp3_conn, stream_id: i64, conn_user_data: ?*anyopaque, stream_user_data: ?*anyopaque) callconv(.c) c_int = null,
    reset_stream: ?*const fn (conn: *nghttp3_conn, stream_id: i64, app_error_code: u64, conn_user_data: ?*anyopaque, stream_user_data: ?*anyopaque) callconv(.c) c_int = null,
    shutdown: ?*const anyopaque = null,
    recv_settings: ?*const anyopaque = null,
    recv_origin: ?*const anyopaque = null,
    end_origin: ?*const anyopaque = null,
    rand: ?*const anyopaque = null,
};

comptime {
    if (@sizeOf(usize) == 8) {
        std.debug.assert(@sizeOf(ngtcp2_cid) == 32);
        std.debug.assert(@sizeOf(ngtcp2_addr) == 16);
        std.debug.assert(@sizeOf(ngtcp2_path) == 40);
        std.debug.assert(@sizeOf(ngtcp2_path_storage) == 96);
        std.debug.assert(@sizeOf(ngtcp2_pkt_info) == 8);
        std.debug.assert(@sizeOf(ngtcp2_ccerr) == 40);
        std.debug.assert(@sizeOf(ngtcp2_settings) == 200);
        std.debug.assert(@offsetOf(ngtcp2_settings, "handshake_timeout") == 112);
        std.debug.assert(@offsetOf(ngtcp2_settings, "original_version") == 152);
        std.debug.assert(@sizeOf(ngtcp2_transport_params) == 344);
        std.debug.assert(@offsetOf(ngtcp2_transport_params, "initial_max_stream_data_bidi_local") == 192);
        std.debug.assert(@offsetOf(ngtcp2_transport_params, "initial_max_data") == 216);
        std.debug.assert(@offsetOf(ngtcp2_transport_params, "max_idle_timeout") == 240);
        std.debug.assert(@offsetOf(ngtcp2_transport_params, "Active_connection_id_limit") == 256);
        std.debug.assert(@offsetOf(ngtcp2_transport_params, "max_datagram_frame_size") == 280);
        std.debug.assert(@offsetOf(ngtcp2_transport_params, "grease_quic_bit") == 310);
        std.debug.assert(@sizeOf(ngtcp2_callbacks) == 328);
        std.debug.assert(@sizeOf(nghttp3_settings) == 64);
        std.debug.assert(@offsetOf(nghttp3_settings, "enable_connect_protocol") == 32);
        std.debug.assert(@offsetOf(nghttp3_settings, "h3_datagram") == 33);
        std.debug.assert(@sizeOf(nghttp3_callbacks) == 144);
    }
}

// ============================================================================
// 2. External C Library Bindings (ngtcp2, ngtcp2_crypto, nghttp3, curl)
// ============================================================================

const ngtcp2_c = if (use_ngtcp2) struct {
    extern fn ngtcp2_cid_init(cid: *ngtcp2_cid, data: [*]const u8, datalen: usize) callconv(.c) void;
    extern fn Curl_ngtcp2_settings_default(settings: *ngtcp2_settings) callconv(.c) void;
    extern fn Curl_ngtcp2_transport_params_default(params: *ngtcp2_transport_params) callconv(.c) void;
    extern fn ngtcp2_ccerr_default(ccerr: *ngtcp2_ccerr) callconv(.c) void;
    extern fn ngtcp2_ccerr_set_application_error(ccerr: *ngtcp2_ccerr, error_code: u64, reason: ?[*]const u8, reasonlen: usize) callconv(.c) void;
    extern fn ngtcp2_ccerr_set_transport_error(ccerr: *ngtcp2_ccerr, error_code: u64, reason: ?[*]const u8, reasonlen: usize) callconv(.c) void;
    extern fn ngtcp2_ccerr_set_tls_alert(ccerr: *ngtcp2_ccerr, alert: u8, reason: ?[*]const u8, reasonlen: usize) callconv(.c) void;
    extern fn ngtcp2_ccerr_set_liberr(ccerr: *ngtcp2_ccerr, liberr: c_int, reason: ?[*]const u8, reasonlen: usize) callconv(.c) void;
    extern fn ngtcp2_path_storage_init(ps: *ngtcp2_path_storage, local_addr: ?*const anyopaque, local_addrlen: socklen_t, remote_addr: ?*const anyopaque, remote_addrlen: socklen_t, user_data: ?*anyopaque) callconv(.c) void;
    extern fn ngtcp2_path_storage_zero(ps: *ngtcp2_path_storage) callconv(.c) void;
    extern fn Curl_ngtcp2_conn_client_new(
        pconn: *?*ngtcp2_conn,
        dcid: *const ngtcp2_cid,
        scid: *const ngtcp2_cid,
        path: *const ngtcp2_path,
        version: u32,
        callbacks: *const ngtcp2_callbacks,
        settings: *const ngtcp2_settings,
        params: *const ngtcp2_transport_params,
        mem_ptr: ?*const vquic_core.ngtcp2_mem,
        user_data: ?*anyopaque,
    ) callconv(.c) c_int;
    extern fn ngtcp2_conn_del(conn: ?*ngtcp2_conn) callconv(.c) void;
    extern fn ngtcp2_conn_set_tls_native_handle(conn: *ngtcp2_conn, tls_native_handle: ?*anyopaque) callconv(.c) void;
    extern fn ngtcp2_conn_get_tls_alert(conn: *ngtcp2_conn) callconv(.c) u8;
    extern fn ngtcp2_conn_in_closing_period(conn: *ngtcp2_conn) callconv(.c) c_int;
    extern fn ngtcp2_conn_in_draining_period(conn: *ngtcp2_conn) callconv(.c) c_int;
    extern fn ngtcp2_conn_get_expiry(conn: *ngtcp2_conn) callconv(.c) ngtcp2_tstamp;
    extern fn ngtcp2_conn_handle_expiry(conn: *ngtcp2_conn, ts: ngtcp2_tstamp) callconv(.c) c_int;
    extern fn ngtcp2_conn_get_send_quantum(conn: *ngtcp2_conn) callconv(.c) usize;
    extern fn ngtcp2_conn_get_path(conn: *ngtcp2_conn) callconv(.c) *const ngtcp2_path;
    extern fn ngtcp2_conn_get_max_tx_udp_payload_size(conn: *ngtcp2_conn) callconv(.c) usize;
    extern fn ngtcp2_conn_get_streams_bidi_left(conn: *ngtcp2_conn) callconv(.c) u64;
    extern fn ngtcp2_conn_get_remote_transport_params(conn: *ngtcp2_conn) callconv(.c) *const ngtcp2_transport_params;
    extern fn ngtcp2_conn_open_bidi_stream(conn: *ngtcp2_conn, pstream_id: *i64, stream_user_data: ?*anyopaque) callconv(.c) c_int;
    extern fn ngtcp2_conn_open_uni_stream(conn: *ngtcp2_conn, pstream_id: *i64, stream_user_data: ?*anyopaque) callconv(.c) c_int;
    extern fn ngtcp2_conn_shutdown_stream(conn: *ngtcp2_conn, flags: u32, stream_id: i64, app_error_code: u64) callconv(.c) c_int;
    extern fn ngtcp2_conn_shutdown_stream_read(conn: *ngtcp2_conn, flags: u32, stream_id: i64, app_error_code: u64) callconv(.c) c_int;
    extern fn ngtcp2_conn_shutdown_stream_write(conn: *ngtcp2_conn, flags: u32, stream_id: i64, app_error_code: u64) callconv(.c) c_int;
    extern fn ngtcp2_conn_extend_max_stream_offset(conn: *ngtcp2_conn, stream_id: i64, datalen: u64) callconv(.c) c_int;
    extern fn ngtcp2_conn_extend_max_offset(conn: *ngtcp2_conn, datalen: u64) callconv(.c) void;
    extern fn ngtcp2_conn_update_pkt_tx_time(conn: *ngtcp2_conn, ts: ngtcp2_tstamp) callconv(.c) void;
    extern fn ngtcp2_conn_encode_0rtt_transport_params(conn: *ngtcp2_conn, dest: [*]u8, destlen: usize) callconv(.c) ngtcp2_ssize;
    extern fn ngtcp2_conn_decode_and_set_0rtt_transport_params(conn: *ngtcp2_conn, data: [*]const u8, datalen: usize) callconv(.c) c_int;
    extern fn Curl_ngtcp2_conn_read_pkt(
        conn: *ngtcp2_conn,
        path: *const ngtcp2_path,
        pi: ?*const ngtcp2_pkt_info,
        pkt: [*]const u8,
        pktlen: usize,
        ts: ngtcp2_tstamp,
    ) callconv(.c) c_int;
    extern fn Curl_ngtcp2_conn_writev_stream(
        conn: *ngtcp2_conn,
        path: ?*ngtcp2_path,
        pi: ?*ngtcp2_pkt_info,
        dest: [*]u8,
        destlen: usize,
        pdatalen: ?*ngtcp2_ssize,
        flags: u32,
        stream_id: i64,
        datav: ?[*]const ngtcp2_vec,
        datavcnt: usize,
        ts: ngtcp2_tstamp,
    ) callconv(.c) ngtcp2_ssize;
    extern fn Curl_ngtcp2_conn_writev_datagram(
        conn: *ngtcp2_conn,
        path: ?*ngtcp2_path,
        pi: ?*ngtcp2_pkt_info,
        dest: [*]u8,
        destlen: usize,
        paccepted: *c_int,
        flags: u32,
        dgram_id: u64,
        datav: [*]const ngtcp2_vec,
        datavcnt: usize,
        ts: ngtcp2_tstamp,
    ) callconv(.c) ngtcp2_ssize;
    extern fn Curl_ngtcp2_conn_write_connection_close(
        conn: *ngtcp2_conn,
        path: ?*ngtcp2_path,
        pi: ?*ngtcp2_pkt_info,
        dest: [*]u8,
        destlen: usize,
        ccerr: *const ngtcp2_ccerr,
        ts: ngtcp2_tstamp,
    ) callconv(.c) ngtcp2_ssize;
    extern fn ngtcp2_strerror(liberr: c_int) callconv(.c) [*:0]const u8;
    extern fn ngtcp2_err_is_fatal(liberr: c_int) callconv(.c) c_int;

    extern fn ngtcp2_crypto_client_initial_cb(conn: *ngtcp2_conn, user_data: ?*anyopaque) callconv(.c) c_int;
    extern fn ngtcp2_crypto_recv_crypto_data_cb(conn: *ngtcp2_conn, encryption_level: c_uint, offset: u64, data: [*]const u8, datalen: usize, user_data: ?*anyopaque) callconv(.c) c_int;
    extern fn ngtcp2_crypto_encrypt_cb(dest: [*]u8, aead: *const anyopaque, aead_ctx: *const anyopaque, plaintext: [*]const u8, plaintextlen: usize, nonce: [*]const u8, noncelen: usize, aad: [*]const u8, aadlen: usize) callconv(.c) c_int;
    extern fn ngtcp2_crypto_decrypt_cb(dest: [*]u8, aead: *const anyopaque, aead_ctx: *const anyopaque, ciphertext: [*]const u8, ciphertextlen: usize, nonce: [*]const u8, noncelen: usize, aad: [*]const u8, aadlen: usize) callconv(.c) c_int;
    extern fn ngtcp2_crypto_hp_mask_cb(dest: [*]u8, hp: *const anyopaque, hp_ctx: *const anyopaque, sample: [*]const u8) callconv(.c) c_int;
    extern fn ngtcp2_crypto_recv_retry_cb(conn: *ngtcp2_conn, hd: *const anyopaque, user_data: ?*anyopaque) callconv(.c) c_int;
    extern fn ngtcp2_crypto_update_key_cb(conn: *ngtcp2_conn, rx_secret: [*]u8, tx_secret: [*]u8, rx_aead_ctx: *anyopaque, rx_iv: [*]u8, tx_aead_ctx: *anyopaque, tx_iv: [*]u8, current_rx_secret: [*]const u8, current_tx_secret: [*]const u8, secretlen: usize, user_data: ?*anyopaque) callconv(.c) c_int;
    extern fn ngtcp2_crypto_delete_crypto_aead_ctx_cb(conn: *ngtcp2_conn, aead_ctx: *anyopaque, user_data: ?*anyopaque) callconv(.c) void;
    extern fn ngtcp2_crypto_delete_crypto_cipher_ctx_cb(conn: *ngtcp2_conn, cipher_ctx: *anyopaque, user_data: ?*anyopaque) callconv(.c) void;
    extern fn ngtcp2_crypto_get_path_challenge_data_cb(conn: *ngtcp2_conn, data: [*]u8, user_data: ?*anyopaque) callconv(.c) c_int;
    extern fn ngtcp2_crypto_version_negotiation_cb(conn: *ngtcp2_conn, version: u32, client_dcid: *const ngtcp2_cid, user_data: ?*anyopaque) callconv(.c) c_int;

    extern fn Curl_nghttp3_settings_default(settings: *nghttp3_settings) callconv(.c) void;
    extern fn Curl_nghttp3_conn_client_new(
        pconn: *?*nghttp3_conn,
        callbacks: *const nghttp3_callbacks,
        settings: *const nghttp3_settings,
        mem_ptr: ?*const vquic_core.nghttp3_mem,
        conn_user_data: ?*anyopaque,
    ) callconv(.c) c_int;
    extern fn nghttp3_conn_del(conn: ?*nghttp3_conn) callconv(.c) void;
    extern fn nghttp3_conn_bind_control_stream(conn: *nghttp3_conn, stream_id: i64) callconv(.c) c_int;
    extern fn nghttp3_conn_bind_qpack_streams(conn: *nghttp3_conn, qenc_stream_id: i64, qdec_stream_id: i64) callconv(.c) c_int;
    extern fn nghttp3_conn_read_stream(conn: *nghttp3_conn, stream_id: i64, src: ?[*]const u8, srclen: usize, fin: c_int) callconv(.c) ngtcp2_ssize;
    extern fn nghttp3_conn_writev_stream(conn: *nghttp3_conn, pstream_id: *i64, pfin: *c_int, vec: [*]nghttp3_vec, cnt: usize) callconv(.c) ngtcp2_ssize;
    extern fn nghttp3_conn_add_write_offset(conn: *nghttp3_conn, stream_id: i64, n: usize) callconv(.c) c_int;
    extern fn nghttp3_conn_add_ack_offset(conn: *nghttp3_conn, stream_id: i64, n: u64) callconv(.c) c_int;
    extern fn nghttp3_conn_block_stream(conn: *nghttp3_conn, stream_id: i64) callconv(.c) c_int;
    extern fn nghttp3_conn_unblock_stream(conn: *nghttp3_conn, stream_id: i64) callconv(.c) c_int;
    extern fn nghttp3_conn_resume_stream(conn: *nghttp3_conn, stream_id: i64) callconv(.c) c_int;
    extern fn nghttp3_conn_close_stream(conn: *nghttp3_conn, stream_id: i64, app_error_code: u64) callconv(.c) c_int;
    extern fn nghttp3_conn_shutdown_stream_read(conn: *nghttp3_conn, stream_id: i64) callconv(.c) c_int;
    extern fn nghttp3_conn_set_stream_user_data(conn: *nghttp3_conn, stream_id: i64, stream_user_data: ?*anyopaque) callconv(.c) c_int;
    extern fn nghttp3_conn_set_max_client_streams_bidi(conn: *nghttp3_conn, max_streams: u64) callconv(.c) void;
    extern fn nghttp3_conn_submit_request(
        conn: *nghttp3_conn,
        stream_id: i64,
        nva: [*]const nghttp3_nv,
        nvlen: usize,
        dr: ?*const nghttp3_data_reader,
        stream_user_data: ?*anyopaque,
    ) callconv(.c) c_int;
    extern fn nghttp3_rcbuf_get_buf(rcbuf: *const nghttp3_rcbuf) callconv(.c) nghttp3_vec;
    extern fn nghttp3_strerror(liberr: c_int) callconv(.c) [*:0]const u8;
    extern fn nghttp3_err_is_fatal(liberr: c_int) callconv(.c) c_int;
    extern fn nghttp3_err_infer_quic_app_error_code(liberr: c_int) callconv(.c) u64;
} else struct {};

const ngtcp2_ossl_c = if (use_ngtcp2 and backend_options.ssl == .openssl) struct {
    extern fn ngtcp2_crypto_ossl_ctx_new(poctx: *?*ngtcp2_crypto_ossl_ctx, ssl: ?*anyopaque) callconv(.c) c_int;
    extern fn ngtcp2_crypto_ossl_ctx_del(octx: ?*ngtcp2_crypto_ossl_ctx) callconv(.c) void;
    extern fn ngtcp2_crypto_ossl_ctx_set_ssl(octx: *ngtcp2_crypto_ossl_ctx, ssl: ?*anyopaque) callconv(.c) void;
    extern fn ngtcp2_crypto_ossl_configure_client_session(ssl: ?*anyopaque) callconv(.c) c_int;

    extern fn SSL_CTX_ctrl(ctx: *anyopaque, cmd: c_int, larg: c_long, parg: ?*anyopaque) callconv(.c) c_long;
    extern fn SSL_CTX_sess_set_new_cb(ctx: *anyopaque, new_session_cb: ?*const fn (ssl: *anyopaque, sess: *anyopaque) callconv(.c) c_int) callconv(.c) void;
    extern fn SSL_set_ex_data(ssl: *anyopaque, idx: c_int, data: ?*anyopaque) callconv(.c) c_int;
    extern fn SSL_get_ex_data(ssl: *const anyopaque, idx: c_int) callconv(.c) ?*anyopaque;
    extern fn SSL_set_quic_tls_early_data_enabled(ssl: *anyopaque, enabled: c_int) callconv(.c) c_int;
    extern fn SSL_get_early_data_status(ssl: *const anyopaque) callconv(.c) c_int;
    extern fn SSL_version(ssl: *const anyopaque) callconv(.c) c_int;
    extern fn SSL_SESSION_get_timeout(s: *const anyopaque) callconv(.c) c_long;
    extern fn SSL_SESSION_get_max_early_data(s: *const anyopaque) callconv(.c) u32;
    extern fn i2d_SSL_SESSION(in: *anyopaque, pp: ?*?[*]u8) callconv(.c) c_int;

    const SSL_CTRL_SET_SESS_CACHE_MODE: c_int = 44;
    const SSL_SESS_CACHE_CLIENT: c_long = 0x0001;
    const SSL_SESS_CACHE_NO_INTERNAL: c_long = 0x0300;
    const SSL_EARLY_DATA_NOT_SENT: c_int = 0;
    const SSL_EARLY_DATA_ACCEPTED: c_int = 2;
} else struct {};

const ngtcp2_gtls_c = if (use_ngtcp2 and backend_options.ssl == .gnutls) struct {
    extern fn ngtcp2_crypto_gnutls_configure_client_session(session: ?*anyopaque) callconv(.c) c_int;
} else struct {};

const ngtcp2_wssl_c = if (use_ngtcp2 and backend_options.ssl == .wolfssl) struct {
    extern fn ngtcp2_crypto_wolfssl_configure_client_context(ssl_ctx: ?*anyopaque) callconv(.c) c_int;
} else struct {};

const posix_io = if (!is_windows) struct {
    extern "c" fn write(fd: c_int, buf: *const anyopaque, count: usize) isize;
    extern "c" fn close(fd: c_int) c_int;
    extern "c" fn getsockname(sockfd: c_int, addr: *anyopaque, addrlen: *socklen_t) c_int;
} else struct {
    extern "c" fn _write(fd: c_int, buf: *const anyopaque, count: c_uint) c_int;
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

fn writeFd(fd: c_int, data: ?*const anyopaque, datalen: usize) isize {
    const ptr = data orelse return 0;
    if (is_windows) {
        return posix_io._write(fd, ptr, @intCast(datalen));
    } else {
        return posix_io.write(fd, ptr, datalen);
    }
}

// External curl & Zig port helpers
extern fn Curl_failf(data: ?*anyopaque, fmt: [*:0]const u8, ...) callconv(.c) void;
extern fn Curl_infof(data: ?*anyopaque, fmt: [*:0]const u8, ...) callconv(.c) void;
extern fn Curl_trc_is_verbose_fn(data: ?*anyopaque) callconv(.c) bool;
extern fn Curl_trc_cf_infof(data: ?*anyopaque, cf: ?*const anyopaque, fmt: [*:0]const u8, ...) callconv(.c) void;
extern fn Curl_pgrs_now(data: ?*anyopaque) callconv(.c) *const curltime;
extern fn Curl_pgrsEarlyData(data: ?*anyopaque, sent: curl_off_t) callconv(.c) void;
extern fn Curl_rand_bytes(data: ?*anyopaque, rnd: [*]u8, num: usize) callconv(.c) CURLcode;
extern fn Curl_expire(data: ?*anyopaque, milli: timediff_t, id: c_uint) callconv(.c) void;
extern fn Curl_expire_clear(data: ?*anyopaque, id: c_uint) callconv(.c) void;
extern fn Curl_multi_get_easy(multi: ?*anyopaque, mid: u32) callconv(.c) ?*CurlEasy;
extern fn Curl_multi_max_concurrent_streams(multi: *anyopaque) callconv(.c) u32;
extern fn Curl_multi_connchanged(multi: ?*anyopaque) callconv(.c) void;
extern fn Curl_multi_mark_dirty(data: *anyopaque) callconv(.c) void;
extern fn Curl_conncontrol(conn: ?*anyopaque, ctrl: c_int) callconv(.c) void;
extern fn Curl_conn_set_multiplex(conn: ?*anyopaque) callconv(.c) void;
extern fn Curl_conn_get_attached_xfers(conn: ?*const anyopaque) callconv(.c) u32;
extern fn Curl_http_acc_conn_set_httpversion_seen(conn: ?*anyopaque, ver: u8) callconv(.c) void;
extern fn Curl_vtls_acc_scache_params(data: ?*anyopaque, pscache: *?*vtls_backends.CurlSslScache, phas_share: *bool, ptrc_feat: *?*vtls_backends.CurlTrcFeat) callconv(.c) void;
extern fn Curl_zig_url_data_get_i64(data: *const anyopaque, field_id: c_int) callconv(.c) i64;
extern fn Curl_zig_url_data_get_ptr(data: *const anyopaque, ptr_id: c_int) callconv(.c) ?*anyopaque;
extern fn Curl_zig_easy_state_infilesize(data: *const anyopaque) callconv(.c) curl_off_t;
extern fn Curl_zig_url_conn_get_bit(conn: *const anyopaque, bit_id: c_int) callconv(.c) bool;
extern fn Curl_sendf_get_upload_done(data: *const anyopaque) callconv(.c) bool;
extern fn Curl_xfer_is_eos_written(data: *anyopaque) callconv(.c) bool;
extern fn Curl_xfer_req_want_send(data: *anyopaque) callconv(.c) bool;
extern fn Curl_xfer_get_dl_rlimit(data: *anyopaque) callconv(.c) *anyopaque;
extern fn Curl_rlimit_per_step(r: *anyopaque) callconv(.c) i64;
extern fn Curl_rlimit_avail(r: *anyopaque, pnow: ?*const curltime) callconv(.c) i64;
extern fn Curl_xfer_write_resp(data: ?*CurlEasy, buf: [*]const u8, blen: usize, is_eos: bool) callconv(.c) CURLcode;
extern fn Curl_xfer_write_resp_hd(data: ?*CurlEasy, hd0: [*]const u8, hdlen: usize, is_eos: bool) callconv(.c) CURLcode;
extern fn Curl_xfer_write_is_paused(data: ?*CurlEasy) callconv(.c) bool;
extern fn Curl_headers_push(data: ?*anyopaque, line: [*]const u8, clen: usize, htype: u8) callconv(.c) CURLcode;
extern fn Curl_http_decode_status(pstatus: *i32, s: [*]const u8, len: usize) callconv(.c) CURLcode;
extern fn Curl_http_req_to_h2(h2_headers: *dynhds, req: *httpreq, data: ?*anyopaque) callconv(.c) CURLcode;
extern fn Curl_http_req_free(req: ?*httpreq) callconv(.c) void;
extern fn Curl_http_resp_make(presp: *?*http_resp, status: c_int, description: ?[*:0]const u8) callconv(.c) CURLcode;
extern fn Curl_http_resp_free(resp: ?*http_resp) callconv(.c) void;
extern fn Curl_creader_set_null(data: ?*anyopaque) callconv(.c) CURLcode;
extern fn Curl_1st_fatal(result: CURLcode, result2: CURLcode) callconv(.c) CURLcode;
extern fn curl_maprintf(format: [*:0]const u8, ...) callconv(.c) ?[*:0]u8;
extern fn Curl_peer_link(pdest: *?*CurlPeer, src: ?*CurlPeer) callconv(.c) void;
extern fn Curl_peer_unlink(ppeer: *?*CurlPeer) callconv(.c) void;
extern fn Curl_cf_create(pcf: *?*CurlCfilter, cft: *const CurlCftype, ctx: ?*anyopaque) callconv(.c) CURLcode;
extern fn Curl_cf_udp_create(pcf: *?*CurlCfilter, data: ?*CurlEasy, origin: ?*CurlPeer, peer: ?*CurlPeer, transport_peer: u8, conn: ?*ConnectData, addr: ?*CurlSockaddrEx, tunnel_peer: ?*CurlPeer, tunnel_transport: u8) callconv(.c) CURLcode;
extern fn Curl_cf_socket_peek(cf: ?*CurlCfilter, data: ?*CurlEasy, psock: ?*curl_socket_t, paddr: ?*?*CurlSockaddrEx, pip: ?*anyopaque) callconv(.c) CURLcode;
extern fn Curl_cf_capsule_insert_after(cf_at: *CurlCfilter, data: ?*anyopaque) callconv(.c) CURLcode;
extern fn Curl_conn_cf_insert_after(cf_at: *CurlCfilter, cf_new: *CurlCfilter) callconv(.c) void;
extern fn Curl_conn_cf_discard_chain(pcf: *?*CurlCfilter, data: ?*CurlEasy) callconv(.c) void;
extern fn Curl_conn_cf_discard_sub(cf: *CurlCfilter, data: ?*CurlEasy, dead: *CurlCfilter, destroy_always: bool) callconv(.c) CURLcode;
extern fn Curl_conn_cf_connect(cf: ?*CurlCfilter, data: ?*CurlEasy, done: *bool) callconv(.c) CURLcode;
extern fn Curl_conn_cf_send(cf: ?*CurlCfilter, data: ?*CurlEasy, buf: [*]const u8, len: usize, eos: bool, pnwritten: *usize) callconv(.c) CURLcode;
extern fn Curl_conn_cf_recv(cf: ?*CurlCfilter, data: ?*CurlEasy, buf: [*]u8, len: usize, pnread: *usize) callconv(.c) CURLcode;
extern fn Curl_conn_cf_adjust_pollset(cf: ?*CurlCfilter, data: ?*CurlEasy, ps: *EasyPollset) callconv(.c) CURLcode;
extern fn Curl_conn_cf_cntrl(cf: ?*CurlCfilter, data: ?*CurlEasy, ignore_result: bool, event: c_int, arg1: c_int, arg2: ?*anyopaque) callconv(.c) CURLcode;
extern fn Curl_cf_def_conn_keep_alive(cf: *CurlCfilter, data: ?*CurlEasy) callconv(.c) CURLcode;
extern fn Curl_cf_def_query(cf: *CurlCfilter, data: ?*CurlEasy, query: c_int, pres1: ?*c_int, pres2: ?*anyopaque) callconv(.c) CURLcode;
extern fn Curl_cf_def_cntrl(cf: *CurlCfilter, data: ?*CurlEasy, event: c_int, arg1: c_int, arg2: ?*anyopaque) callconv(.c) CURLcode;

const proxy_inspect_result = enum(c_int) {
    PROXY_INSPECT_OK = 0,
    PROXY_INSPECT_FAILED = 1,
    PROXY_INSPECT_AUTH_RETRY = 2,
};

extern fn Curl_http_proxy_create_tunnel_request(
    preq: *?*httpreq,
    cf: *CurlCfilter,
    data: *CurlEasy,
    peer: ?*CurlPeer,
    dest: ?*CurlPeer,
    ver: c_uint,
    udp_tunnel: bool,
) callconv(.c) CURLcode;
extern fn Curl_http_proxy_inspect_tunnel_response(
    cf: *CurlCfilter,
    data: *CurlEasy,
    resp: ?*http_resp,
    is_udp: bool,
    pres: *proxy_inspect_result,
) callconv(.c) CURLcode;
extern fn Curl_proxy_start_connect_auth(data: ?*CurlEasy) callconv(.c) void;
extern fn Curl_proxy_clear_hd_proxy_auth(data: ?*CurlEasy) callconv(.c) void;
extern fn Curl_proxy_req_soft_reset(data: ?*CurlEasy) callconv(.c) void;
extern fn Curl_http_acc_req_set_ignorebody(data: ?*CurlEasy, v: bool) callconv(.c) void;

extern fn Curl_u32_ptrset_init(set: *u32_ptrset, dtor: ?collections.Curl_u32_ptrset_dtor) callconv(.c) void;
extern fn Curl_u32_ptrset_clear(set: *u32_ptrset) callconv(.c) void;
extern fn Curl_u32_ptrset_count(set: *u32_ptrset) callconv(.c) u32;
extern fn Curl_u32_ptrset_get(set: *u32_ptrset, id: u32) callconv(.c) ?*anyopaque;
extern fn Curl_u32_ptrset_set(set: *u32_ptrset, id: u32, ptr: ?*anyopaque) callconv(.c) CURLcode;
extern fn Curl_u32_ptrset_unset(set: *u32_ptrset, id: u32) callconv(.c) void;
extern fn Curl_u32_ptrset_visit(set: *u32_ptrset, cb: collections.Curl_u32_ptrset_visit_cb, user_data: ?*anyopaque) callconv(.c) void;

extern fn Curl_uint32_bset_init(bset: *uint32_bset) callconv(.c) void;
extern fn Curl_uint32_bset_resize(bset: *uint32_bset, nmax: u32) callconv(.c) CURLcode;
extern fn Curl_uint32_bset_destroy(bset: *uint32_bset) callconv(.c) void;
extern fn Curl_uint32_bset_empty(bset: *uint32_bset) callconv(.c) bool;
extern fn Curl_uint32_bset_clear(bset: *uint32_bset) callconv(.c) void;
extern fn Curl_uint32_bset_add(bset: *uint32_bset, i: u32) callconv(.c) bool;
extern fn Curl_uint32_bset_remove(bset: *uint32_bset, i: u32) callconv(.c) void;
extern fn Curl_uint32_bset_first(bset: *uint32_bset, pfirst: *u32) callconv(.c) bool;
extern fn Curl_uint32_bset_next(bset: *uint32_bset, last: u32, pnext: *u32) callconv(.c) bool;

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
    const multi = easyMulti(call_data) orelse return null;
    const sdata = Curl_multi_get_easy(multi, mid) orelse return null;
    if (!goodEasyHandle(sdata)) return null;
    return sdata;
}

inline fn multiMaxConcurrentStreams(data: ?*CurlEasy) u32 {
    const multi = easyMulti(data) orelse return 0;
    return Curl_multi_max_concurrent_streams(multi);
}

inline fn multiConnChanged(data: ?*CurlEasy) void {
    const multi = easyMulti(data) orelse return;
    Curl_multi_connchanged(multi);
}

inline fn cfDataSave(save: *CfCallData, call_data: *CfCallData, data: ?*CurlEasy) void {
    save.* = call_data.*;
    call_data.data = data;
    call_data.depth += 1;
}

inline fn cfDataRestore(call_data: *CfCallData, save: CfCallData) void {
    call_data.* = save;
}

inline fn trcCfIsVerbose(cf: ?*const CurlCfilter, data: ?*CurlEasy) bool {
    const c = cf orelse return false;
    return Curl_trc_is_verbose_fn(data) and c.cft.log_level >= CURL_LOG_LVL_INFO;
}

inline fn trcCf(data: ?*CurlEasy, cf: ?*const CurlCfilter, comptime fmt: [*:0]const u8, args: anytype) void {
    if (trcCfIsVerbose(cf, data)) {
        @call(.auto, Curl_trc_cf_infof, .{ data, cf, fmt } ++ args);
    }
}

// ============================================================================
// 3. Shared QUIC + HTTP/3 Engine (lib/vquic/cf-ngtcp2-cmn.c)
// ============================================================================

pub const QUIC_MAX_STREAMS: usize = 100;
pub const H3_STREAM_WINDOW_SIZE: usize = 128 * 1024;
pub const H3_STREAM_CHUNK_SIZE: usize = 16 * 1024;
pub const H3_STREAM_POOL_SPARES: usize = H3_STREAM_WINDOW_SIZE / H3_STREAM_CHUNK_SIZE;
pub const H3_STREAM_RECV_CHUNKS: usize = H3_STREAM_WINDOW_SIZE / H3_STREAM_CHUNK_SIZE;
pub const H3_STREAM_SEND_CHUNKS: usize = 4;
pub const QUIC_IDLE_TIMEOUT: ngtcp2_duration = 60 * NGTCP2_SECONDS;
pub const HANDSHAKE_TIMEOUT: ngtcp2_duration = 10 * NGTCP2_SECONDS;
const GSO_MAX_BUFFERS: usize = 16;

pub const PktIoCtx = struct {
    cf: *CurlCfilter,
    data: ?*CurlEasy,
    ctx: *CfNgtcp2Ctx,
    ts: ngtcp2_tstamp,
    pkt_count: usize,
    ps: ngtcp2_path_storage,
};

pub const H3StreamCtx = struct {
    id: i64 = -1,
    mid: u32 = std.math.maxInt(u32),
    xfer_id: i64 = -1,
    sendbuf: Bufq = std.mem.zeroes(Bufq),
    h1: h1_req_parser = std.mem.zeroes(h1_req_parser),
    sendbuf_len_in_flight: usize = 0,
    upload_left: curl_off_t = 0,
    status_code: i32 = -1,
    quic_flow_blocked: bool = false,
    closed: bool = false,
    reset: bool = false,
    send_closed: bool = false,
    resp_hds_complete: bool = false,
    rx_eos: bool = false,
    xfer_result: CURLcode = CURLE_OK,
};

pub const CfNgtcp2Cbs = struct {
    q_cbs: ngtcp2_callbacks,
    h3_cbs: nghttp3_callbacks,
    ng_settings: ?*const fn (
        cf: *CurlCfilter,
        data: ?*CurlEasy,
        ctx: *CfNgtcp2Ctx,
        settings: *ngtcp2_settings,
        params: *ngtcp2_transport_params,
    ) callconv(.c) CURLcode = null,
    h3_settings: ?*const fn (
        cf: *CurlCfilter,
        data: ?*CurlEasy,
        ctx: *CfNgtcp2Ctx,
        settings: *nghttp3_settings,
    ) callconv(.c) CURLcode = null,
};

pub const CfNgtcp2Ctx = struct {
    cf: ?*CurlCfilter = null,
    q: CfQuicCtx = std.mem.zeroes(CfQuicCtx),
    ssl_peer: SslPeer = std.mem.zeroes(SslPeer),
    conn_ref: ngtcp2_crypto_conn_ref = .{},
    qconn: ?*ngtcp2_conn = null,
    dcid: ngtcp2_cid = .{},
    scid: ngtcp2_cid = .{},
    version: u32 = 0,
    settings: ngtcp2_settings = .{},
    transport_params: ngtcp2_transport_params = .{},
    last_error: ngtcp2_ccerr = .{},
    tls: CurlTlsCtx = .{},
    ossl_ctx: ?*ngtcp2_crypto_ossl_ctx = null,
    h3conn: ?*nghttp3_conn = null,
    h3settings: nghttp3_settings = .{},
    stream_bufcp: BufcPool = std.mem.zeroes(BufcPool),
    max_stream_window: usize = 0,
    max_idle_ms: u64 = 0,
    last_ts: ngtcp2_tstamp = 0,
    qlogfd: c_int = -1,
    streams: u32_ptrset = std.mem.zeroes(u32_ptrset),
    active_streams: uint32_bset = std.mem.zeroes(uint32_bset),
    cbs: ?*const CfNgtcp2Cbs = null,
    call_data: CfCallData = .{},
    tls_vrfy_result: CURLcode = CURLE_OK,
    initialized: bool = false,
    tls_vrfy_ok: bool = false,
    tls_hshk_reported: bool = false,
    earlydata_Attempted: bool = false,
    shutdown_started: bool = false,
};

pub fn h3StreamCtx(ctx: *CfNgtcp2Ctx, data: ?*CurlEasy) ?*H3StreamCtx {
    const d = data orelse return null;
    if (!goodEasyHandle(d)) return null;
    const mid = easyMid(d);
    if (mid == std.math.maxInt(u32)) return null;
    const raw = Curl_u32_ptrset_get(&ctx.streams, mid) orelse return null;
    const stream: *H3StreamCtx = @ptrCast(@alignCast(raw));
    if (stream.mid != mid or stream.xfer_id != easyId(d)) return null;
    return stream;
}

pub fn Curl_ngtcp2_ver(p: [*]u8, len: usize) callconv(.c) void {
    vquic_core.Curl_cf_ngtcp2_ver(p, len);
}

pub fn Curl_cf_ngtcp2_io_ctx_update_time(pktx: *PktIoCtx) callconv(.c) void {
    vquic_core.Curl_vquic_ctx_update_time(&pktx.ctx.q, pktx.data);
    const raw_ts = @as(ngtcp2_tstamp, @intCast(pktx.ctx.q.last_op.tv_sec)) * NGTCP2_SECONDS +
        @as(ngtcp2_tstamp, @intCast(pktx.ctx.q.last_op.tv_usec)) * NGTCP2_MICROSECONDS;
    const ts = @max(raw_ts, pktx.ctx.last_ts);
    pktx.ctx.last_ts = ts;
    pktx.ts = ts;
}

pub fn Curl_cf_ngtcp2_io_ctx_init(
    pktx: *PktIoCtx,
    cf: *CurlCfilter,
    data: ?*CurlEasy,
    ctx: *CfNgtcp2Ctx,
) callconv(.c) void {
    pktx.cf = cf;
    pktx.data = data;
    pktx.ctx = ctx;
    pktx.pkt_count = 0;
    if (comptime use_ngtcp2) {
        ngtcp2_c.ngtcp2_path_storage_zero(&pktx.ps);
    } else {
        pktx.ps = .{};
    }
    Curl_cf_ngtcp2_io_ctx_update_time(pktx);
}

pub fn Curl_cf_ngtcp2_h3_stream_ctx_free(stream_opt: ?*H3StreamCtx) callconv(.c) void {
    const stream = stream_opt orelse return;
    io_buffers.Curl_bufq_free(&stream.sendbuf);
    http1_options.Curl_h1_req_parse_free(&stream.h1);
    mem.freeTyped(stream);
}

fn h3_stream_hash_free(id: u32, stream_ptr: ?*anyopaque) callconv(.c) void {
    _ = id;
    if (stream_ptr) |p| {
        const stream: *H3StreamCtx = @ptrCast(@alignCast(p));
        Curl_cf_ngtcp2_h3_stream_ctx_free(stream);
    }
}

pub fn Curl_cf_ngtcp2_ctx_init(
    ctx: *CfNgtcp2Ctx,
    origin: ?*CurlPeer,
    peer: ?*CurlPeer,
    cbs: *const CfNgtcp2Cbs,
) callconv(.c) CURLcode {
    std.debug.assert(!ctx.initialized);
    ctx.qlogfd = -1;
    io_buffers.Curl_bufcp_init(&ctx.stream_bufcp, H3_STREAM_CHUNK_SIZE, H3_STREAM_POOL_SPARES);
    Curl_u32_ptrset_init(&ctx.streams, h3_stream_hash_free);
    Curl_uint32_bset_init(&ctx.active_streams);
    if (Curl_uint32_bset_resize(&ctx.active_streams, QUIC_MAX_STREAMS) != CURLE_OK) {
        return CURLE_OUT_OF_MEMORY;
    }
    ctx.cbs = cbs;
    ctx.initialized = true;
    const result = vquic_core.Curl_vquic_tls_peer_init(origin, peer, null, &ctx.ssl_peer);
    if (result != CURLE_OK) {
        Curl_cf_ngtcp2_ctx_cleanup(ctx);
        return result;
    }
    return CURLE_OK;
}

pub fn Curl_cf_ngtcp2_ctx_cleanup(ctx: *CfNgtcp2Ctx) callconv(.c) void {
    if (ctx.initialized) {
        if (ctx.qlogfd != -1) {
            closeFd(ctx.qlogfd);
            ctx.qlogfd = -1;
        }
        vquic_core.Curl_vquic_tls_cleanup(&ctx.tls);
        vquic_core.Curl_vquic_ctx_free(&ctx.q);
        if (comptime use_ngtcp2) {
            if (ctx.h3conn) |h3| {
                ngtcp2_c.nghttp3_conn_del(h3);
                ctx.h3conn = null;
            }
            if (ctx.qconn) |qc| {
                ngtcp2_c.ngtcp2_conn_del(qc);
                ctx.qconn = null;
            }
        }
        if (comptime (use_ngtcp2 and backend_options.ssl == .openssl)) {
            if (ctx.ossl_ctx) |octx| {
                ngtcp2_ossl_c.ngtcp2_crypto_ossl_ctx_del(octx);
                ctx.ossl_ctx = null;
            }
        }
        io_buffers.Curl_bufcp_free(&ctx.stream_bufcp);
        Curl_u32_ptrset_clear(&ctx.streams);
        Curl_uint32_bset_destroy(&ctx.active_streams);
        vtls_backends.vtls_impl.Curl_ssl_peer_cleanup(&ctx.ssl_peer);
    }
}

const StreamVisitSidCtx = struct {
    ctx: *CfNgtcp2Ctx,
    stream_id: i64,
    data: ?*CurlEasy = null,
};

fn visit_by_sid(mid: u32, value: ?*anyopaque, user_data: ?*anyopaque) callconv(.c) bool {
    const stream: *H3StreamCtx = @ptrCast(@alignCast(value orelse return true));
    const vctx: *StreamVisitSidCtx = @ptrCast(@alignCast(user_data orelse return false));
    if (stream.id == vctx.stream_id) {
        if (mid != std.math.maxInt(u32) and mid == stream.mid and stream.xfer_id >= 0) {
            const call_data = vctx.ctx.call_data.data;
            if (goodEasyHandle(call_data)) {
                if (multiGetEasy(call_data, mid)) |sdata| {
                    if (goodEasyHandle(sdata) and easyMid(sdata) == stream.mid and easyMid(sdata) == mid and easyId(sdata) == stream.xfer_id) {
                        vctx.data = sdata;
                    }
                }
            }
        }
        return false;
    }
    return true;
}

pub fn Curl_cf_ngtcp2_get_xfer(ctx: *CfNgtcp2Ctx, stream_id: i64) callconv(.c) ?*CurlEasy {
    if (ctx.call_data.data) |cd| {
        if (!goodEasyHandle(cd)) return null;
        if (h3StreamCtx(ctx, cd)) |stream| {
            if (stream.id == stream_id and easyMid(cd) == stream.mid and easyId(cd) == stream.xfer_id)
                return cd;
        }
        var vctx = StreamVisitSidCtx{
            .ctx = ctx,
            .stream_id = stream_id,
        };
        Curl_u32_ptrset_visit(&ctx.streams, visit_by_sid, &vctx);
        return vctx.data;
    }
    return null;
}

pub fn Curl_cf_ngtcp2_h3_stream_setup(
    cf: *CurlCfilter,
    data: ?*CurlEasy,
    ctx: *CfNgtcp2Ctx,
    pstream: *?*H3StreamCtx,
) callconv(.c) CURLcode {
    _ = cf;
    std.debug.assert(data != null);
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
    if (h3StreamCtx(ctx, data)) |existing| {
        pstream.* = existing;
        return CURLE_OK;
    }

    const raw = mem.calloc(1, @sizeOf(H3StreamCtx)) orelse return CURLE_OUT_OF_MEMORY;
    const stream: *H3StreamCtx = @ptrCast(@alignCast(raw));
    stream.id = -1;
    stream.mid = mid;
    stream.xfer_id = xfer_id;
    io_buffers.Curl_bufq_initp(
        &stream.sendbuf,
        &ctx.stream_bufcp,
        H3_STREAM_SEND_CHUNKS,
        BUFQ_OPT_NONE,
    );
    http1_options.Curl_h1_req_parse_init(&stream.h1, 16 * 1024);
    stream.sendbuf_len_in_flight = 0;
    stream.upload_left = 0;
    stream.status_code = -1;
    stream.quic_flow_blocked = false;
    stream.closed = false;
    stream.reset = false;
    stream.send_closed = false;
    stream.resp_hds_complete = false;
    stream.rx_eos = false;
    stream.xfer_result = CURLE_OK;

    const result = Curl_u32_ptrset_set(&ctx.streams, mid, stream);
    if (result != CURLE_OK) {
        Curl_cf_ngtcp2_h3_stream_ctx_free(stream);
        pstream.* = null;
        return result;
    }

    if (Curl_u32_ptrset_count(&ctx.streams) > collections.uint32_bset_capacity(&ctx.active_streams)) {
        _ = Curl_uint32_bset_resize(&ctx.active_streams, Curl_u32_ptrset_count(&ctx.streams) * 2);
    }

    pstream.* = stream;
    return CURLE_OK;
}

pub fn Curl_cf_ngtcp2_h3_stream_close(
    cf: *CurlCfilter,
    data: ?*CurlEasy,
    ctx: *CfNgtcp2Ctx,
    stream: *H3StreamCtx,
) callconv(.c) void {
    if (comptime use_ngtcp2) {
        if (!stream.closed and ctx.qconn != null and ctx.h3conn != null and stream.id >= 0) {
            var pktx: PktIoCtx = undefined;
            Curl_cf_ngtcp2_io_ctx_init(&pktx, cf, data, ctx);
            _ = ngtcp2_c.nghttp3_conn_set_stream_user_data(ctx.h3conn.?, stream.id, null);
            _ = ngtcp2_c.ngtcp2_conn_shutdown_stream(ctx.qconn.?, 0, stream.id, NGHTTP3_H3_REQUEST_CANCELLED);
            stream.closed = true;
            _ = progress_egress(cf, data, ctx, &pktx);
        }
    }
    if ((cf.cft.flags & CF_TYPE_PROXY) != 0 or ctx.cbs == &cf_ngtcp2_proxy_cbs) {
        const proxy_ctx = qToProxyCtx(ctx);
        if (proxy_ctx.ts.stream == stream) {
            proxy_ctx.ts.stream = null;
        }
    }
    if (stream.mid != std.math.maxInt(u32)) {
        Curl_uint32_bset_remove(&ctx.active_streams, stream.mid);
    } else if (data) |d| {
        const mid = easyMid(d);
        if (mid != std.math.maxInt(u32)) {
            Curl_uint32_bset_remove(&ctx.active_streams, mid);
        }
    }
}

pub fn Curl_cf_ngtcp2_h3_stream_done(
    cf: *CurlCfilter,
    data: ?*CurlEasy,
    ctx: *CfNgtcp2Ctx,
) callconv(.c) void {
    const d = data orelse return;
    if (h3StreamCtx(ctx, d)) |stream| {
        const mid = stream.mid;
        Curl_cf_ngtcp2_h3_stream_close(cf, d, ctx, stream);
        Curl_u32_ptrset_unset(&ctx.streams, mid);
    }
}

fn should_notify(stream: *const H3StreamCtx) bool {
    return stream.closed or stream.reset or stream.xfer_result != CURLE_OK;
}

fn check_and_notify(ctx: *CfNgtcp2Ctx, data: ?*CurlEasy, stream: *const H3StreamCtx) void {
    if (data) |d| {
        if (should_notify(stream)) {
            Curl_multi_mark_dirty(d);
        }
    }
    _ = ctx;
}

pub fn Curl_cf_ngtcp2_cb_handshake_completed(
    tconn: *ngtcp2_conn,
    user_data: ?*anyopaque,
) callconv(.c) c_int {
    _ = tconn;
    const ctx: *CfNgtcp2Ctx = @ptrCast(@alignCast(user_data orelse return NGTCP2_ERR_CALLBACK_FAILURE));
    const cf = ctx.cf orelse return NGTCP2_ERR_CALLBACK_FAILURE;
    const data = ctx.call_data.data;

    ctx.q.last_io = Curl_pgrs_now(data).*;
    trcCf(data, cf, "handshake completed", .{});
    const result = vquic_core.Curl_vquic_tls_verify_peer(&ctx.tls, cf, data, &ctx.ssl_peer);
    ctx.tls_vrfy_result = result;
    if (result != CURLE_OK) {
        trcCf(data, cf, "verify peer failed -> %d", .{@as(c_int, @intCast(result))});
        return NGTCP2_ERR_CALLBACK_FAILURE;
    }
    ctx.tls_vrfy_ok = true;
    return 0;
}

pub fn Curl_cf_ngtcp2_cb_recv_stream_data(
    tconn: *ngtcp2_conn,
    flags: u32,
    stream_id: i64,
    offset: u64,
    buf: ?[*]const u8,
    buflen: usize,
    user_data: ?*anyopaque,
    stream_user_data: ?*anyopaque,
) callconv(.c) c_int {
    _ = offset;
    _ = stream_user_data;
    if (comptime !use_ngtcp2) return NGTCP2_ERR_CALLBACK_FAILURE;
    const ctx: *CfNgtcp2Ctx = @ptrCast(@alignCast(user_data orelse return NGTCP2_ERR_CALLBACK_FAILURE));
    const h3conn = ctx.h3conn orelse return NGTCP2_ERR_CALLBACK_FAILURE;
    const fin: c_int = if ((flags & NGTCP2_STREAM_DATA_FLAG_FIN) != 0) 1 else 0;

    const nconsumed = ngtcp2_c.nghttp3_conn_read_stream(h3conn, stream_id, buf, buflen, fin);
    if (nconsumed < 0) {
        const h3err: c_int = @intCast(nconsumed);
        trcCf(ctx.call_data.data, ctx.cf, "h3sid[%lld] nghttp3_conn_read_stream_error: %s", .{
            @as(c_longlong, stream_id),
            ngtcp2_c.nghttp3_strerror(h3err),
        });
        ngtcp2_c.ngtcp2_ccerr_set_application_error(
            &ctx.last_error,
            ngtcp2_c.nghttp3_err_infer_quic_app_error_code(h3err),
            null,
            0,
        );
        return NGTCP2_ERR_CALLBACK_FAILURE;
    }

    _ = ngtcp2_c.ngtcp2_conn_extend_max_stream_offset(tconn, stream_id, @intCast(nconsumed));
    ngtcp2_c.ngtcp2_conn_extend_max_offset(tconn, @intCast(nconsumed));
    return 0;
}

pub fn Curl_cf_ngtcp2_cb_acked_stream_data_offset(
    tconn: *ngtcp2_conn,
    stream_id: i64,
    offset: u64,
    datalen: u64,
    user_data: ?*anyopaque,
    stream_user_data: ?*anyopaque,
) callconv(.c) c_int {
    _ = tconn;
    _ = offset;
    _ = stream_user_data;
    if (comptime !use_ngtcp2) return NGTCP2_ERR_CALLBACK_FAILURE;
    const ctx: *CfNgtcp2Ctx = @ptrCast(@alignCast(user_data orelse return NGTCP2_ERR_CALLBACK_FAILURE));
    const h3conn = ctx.h3conn orelse return 0;
    const rv = ngtcp2_c.nghttp3_conn_add_ack_offset(h3conn, stream_id, datalen);
    if (rv != 0 and rv != NGHTTP3_ERR_STREAM_NOT_FOUND) {
        return NGTCP2_ERR_CALLBACK_FAILURE;
    }
    return 0;
}

pub fn Curl_cf_ngtcp2_cb_stream_open(
    tconn: *ngtcp2_conn,
    stream_id: i64,
    user_data: ?*anyopaque,
) callconv(.c) c_int {
    _ = tconn;
    _ = stream_id;
    _ = user_data;
    return 0;
}

pub fn Curl_cf_ngtcp2_cb_stream_close(
    tconn: *ngtcp2_conn,
    flags: u32,
    stream_id: i64,
    app_error_code: u64,
    user_data: ?*anyopaque,
    stream_user_data: ?*anyopaque,
) callconv(.c) c_int {
    _ = tconn;
    _ = stream_user_data;
    if (comptime !use_ngtcp2) return NGTCP2_ERR_CALLBACK_FAILURE;
    const ctx: *CfNgtcp2Ctx = @ptrCast(@alignCast(user_data orelse return NGTCP2_ERR_CALLBACK_FAILURE));
    const h3conn = ctx.h3conn orelse return 0;
    var err_code = app_error_code;
    if ((flags & 0x01) == 0) { // NGTCP2_STREAM_CLOSE_FLAG_APP_ERROR_CODE_SET
        err_code = NGHTTP3_H3_NO_ERROR;
    }
    const rv = ngtcp2_c.nghttp3_conn_close_stream(h3conn, stream_id, err_code);
    if (rv != 0 and rv != NGHTTP3_ERR_STREAM_NOT_FOUND) {
        ngtcp2_c.ngtcp2_ccerr_set_application_error(
            &ctx.last_error,
            ngtcp2_c.nghttp3_err_infer_quic_app_error_code(rv),
            null,
            0,
        );
        return NGTCP2_ERR_CALLBACK_FAILURE;
    }
    return 0;
}

pub fn Curl_cf_ngtcp2_cb_stream_reset(
    tconn: *ngtcp2_conn,
    stream_id: i64,
    final_size: u64,
    app_error_code: u64,
    user_data: ?*anyopaque,
    stream_user_data: ?*anyopaque,
) callconv(.c) c_int {
    _ = tconn;
    _ = final_size;
    _ = app_error_code;
    _ = stream_user_data;
    if (comptime !use_ngtcp2) return NGTCP2_ERR_CALLBACK_FAILURE;
    const ctx: *CfNgtcp2Ctx = @ptrCast(@alignCast(user_data orelse return NGTCP2_ERR_CALLBACK_FAILURE));
    const h3conn = ctx.h3conn orelse return 0;
    const rv = ngtcp2_c.nghttp3_conn_shutdown_stream_read(h3conn, stream_id);
    if (rv != 0 and rv != NGHTTP3_ERR_STREAM_NOT_FOUND) {
        return NGTCP2_ERR_CALLBACK_FAILURE;
    }
    return 0;
}

pub fn Curl_cf_ngtcp2_cb_stream_stop_sending(
    tconn: *ngtcp2_conn,
    stream_id: i64,
    app_error_code: u64,
    user_data: ?*anyopaque,
    stream_user_data: ?*anyopaque,
) callconv(.c) c_int {
    _ = tconn;
    _ = app_error_code;
    _ = stream_user_data;
    if (comptime !use_ngtcp2) return NGTCP2_ERR_CALLBACK_FAILURE;
    const ctx: *CfNgtcp2Ctx = @ptrCast(@alignCast(user_data orelse return NGTCP2_ERR_CALLBACK_FAILURE));
    const h3conn = ctx.h3conn orelse return 0;
    const rv = ngtcp2_c.nghttp3_conn_shutdown_stream_read(h3conn, stream_id);
    if (rv != 0 and rv != NGHTTP3_ERR_STREAM_NOT_FOUND) {
        return NGTCP2_ERR_CALLBACK_FAILURE;
    }
    return 0;
}

pub fn Curl_cf_ngtcp2_cb_extend_max_local_streams_bidi(
    tconn: *ngtcp2_conn,
    max_streams: u64,
    user_data: ?*anyopaque,
) callconv(.c) c_int {
    _ = tconn;
    _ = max_streams;
    _ = user_data;
    return 0;
}

pub fn Curl_cf_ngtcp2_cb_rand(
    dest: [*]u8,
    destlen: usize,
    rand_ctx: *const ngtcp2_rand_ctx,
) callconv(.c) void {
    _ = rand_ctx;
    const result = Curl_rand_bytes(null, dest, destlen);
    if (result != CURLE_OK) {
        @memset(dest[0..destlen], 0);
    }
}

pub fn Curl_cf_ngtcp2_cb_get_new_connection_id(
    tconn: *ngtcp2_conn,
    cid: *ngtcp2_cid,
    token: [*]u8,
    cidlen: usize,
    user_data: ?*anyopaque,
) callconv(.c) c_int {
    _ = tconn;
    _ = user_data;
    if (Curl_rand_bytes(null, &cid.data, cidlen) != CURLE_OK)
        return NGTCP2_ERR_CALLBACK_FAILURE;
    cid.datalen = cidlen;
    if (Curl_rand_bytes(null, token, NGTCP2_STATELESS_RESET_TOKENLEN) != CURLE_OK)
        return NGTCP2_ERR_CALLBACK_FAILURE;
    return 0;
}

pub fn Curl_cf_ngtcp2_cb_remove_connection_id(
    tconn: *ngtcp2_conn,
    cid: *const ngtcp2_cid,
    user_data: ?*anyopaque,
) callconv(.c) c_int {
    _ = tconn;
    _ = cid;
    _ = user_data;
    return 0;
}

pub fn Curl_cf_ngtcp2_h3_init_ctrls(
    cf: *CurlCfilter,
    data: ?*CurlEasy,
    ctx: *CfNgtcp2Ctx,
) callconv(.c) CURLcode {
    if (comptime !use_ngtcp2) return CURLE_NOT_BUILT_IN;
    const qconn = ctx.qconn orelse return CURLE_QUIC_CONNECT_ERROR;
    const cbs = ctx.cbs orelse return CURLE_QUIC_CONNECT_ERROR;

    ngtcp2_c.Curl_nghttp3_settings_default(&ctx.h3settings);
    if (cbs.h3_settings) |h3_settings_fn| {
        const result = h3_settings_fn(cf, data, ctx, &ctx.h3settings);
        if (result != CURLE_OK) return result;
    }

    var rc = ngtcp2_c.Curl_nghttp3_conn_client_new(
        &ctx.h3conn,
        &cbs.h3_cbs,
        &ctx.h3settings,
        vquic_core.Curl_nghttp3_mem(),
        ctx,
    );
    if (rc != 0) return CURLE_OUT_OF_MEMORY;

    var ctrl_stream_id: i64 = 0;
    rc = ngtcp2_c.ngtcp2_conn_open_uni_stream(qconn, &ctrl_stream_id, null);
    if (rc != 0) return CURLE_QUIC_CONNECT_ERROR;

    rc = ngtcp2_c.nghttp3_conn_bind_control_stream(ctx.h3conn.?, ctrl_stream_id);
    if (rc != 0) return CURLE_QUIC_CONNECT_ERROR;

    var qpack_enc_stream_id: i64 = 0;
    var qpack_dec_stream_id: i64 = 0;
    rc = ngtcp2_c.ngtcp2_conn_open_uni_stream(qconn, &qpack_enc_stream_id, null);
    if (rc != 0) return CURLE_QUIC_CONNECT_ERROR;
    rc = ngtcp2_c.ngtcp2_conn_open_uni_stream(qconn, &qpack_dec_stream_id, null);
    if (rc != 0) return CURLE_QUIC_CONNECT_ERROR;

    rc = ngtcp2_c.nghttp3_conn_bind_qpack_streams(ctx.h3conn.?, qpack_enc_stream_id, qpack_dec_stream_id);
    if (rc != 0) return CURLE_QUIC_CONNECT_ERROR;

    return CURLE_OK;
}

pub fn Curl_cf_ngtcp2_cb_recv_rx_key(
    tconn: *ngtcp2_conn,
    level: c_uint,
    user_data: ?*anyopaque,
) callconv(.c) c_int {
    _ = tconn;
    if (level != NGTCP2_CRYPTO_LEVEL_APPLICATION)
        return 0;
    const ctx: *CfNgtcp2Ctx = @ptrCast(@alignCast(user_data orelse return NGTCP2_ERR_CALLBACK_FAILURE));
    const cf = ctx.cf orelse return NGTCP2_ERR_CALLBACK_FAILURE;
    if (ctx.h3conn == null) {
        const rc = Curl_cf_ngtcp2_h3_init_ctrls(cf, ctx.call_data.data, ctx);
        if (rc != CURLE_OK) {
            return NGTCP2_ERR_CALLBACK_FAILURE;
        }
    }
    return 0;
}

pub fn Curl_cf_ngtcp2_cb_recv_tx_key(
    tconn: *ngtcp2_conn,
    level: c_uint,
    user_data: ?*anyopaque,
) callconv(.c) c_int {
    _ = tconn;
    if (level != NGTCP2_CRYPTO_LEVEL_EARLY)
        return 0;
    const ctx: *CfNgtcp2Ctx = @ptrCast(@alignCast(user_data orelse return NGTCP2_ERR_CALLBACK_FAILURE));
    const cf = ctx.cf orelse return NGTCP2_ERR_CALLBACK_FAILURE;
    if (ctx.h3conn == null) {
        if (Curl_cf_ngtcp2_h3_init_ctrls(cf, ctx.call_data.data, ctx) != CURLE_OK)
            return NGTCP2_ERR_CALLBACK_FAILURE;
    }
    return 0;
}

pub fn Curl_cf_ngtcp2_cb_h3_acked_stream_data(
    conn: *nghttp3_conn,
    stream_id: i64,
    datalen: u64,
    user_data: ?*anyopaque,
    stream_user_data: ?*anyopaque,
) callconv(.c) c_int {
    _ = conn;
    _ = stream_user_data;
    const ctx: *CfNgtcp2Ctx = @ptrCast(@alignCast(user_data orelse return 0));
    const sdata = Curl_cf_ngtcp2_get_xfer(ctx, stream_id) orelse return 0;
    const stream = h3StreamCtx(ctx, sdata) orelse return 0;

    if (!Curl_sendf_get_upload_done(sdata) and stream.sendbuf_len_in_flight >= datalen) {
        stream.sendbuf_len_in_flight -= @intCast(datalen);
        io_buffers.Curl_bufq_skip(&stream.sendbuf, @intCast(datalen));
        if (stream.upload_left > 0 and stream.sendbuf_len_in_flight == 0) {
            Curl_multi_mark_dirty(sdata);
        }
    }
    return 0;
}

pub fn Curl_cf_ngtcp2_cb_h3_stream_close(
    conn: *nghttp3_conn,
    stream_id: i64,
    app_error_code: u64,
    user_data: ?*anyopaque,
    stream_user_data: ?*anyopaque,
) callconv(.c) c_int {
    _ = conn;
    _ = stream_user_data;
    const ctx: *CfNgtcp2Ctx = @ptrCast(@alignCast(user_data orelse return 0));
    const sdata = Curl_cf_ngtcp2_get_xfer(ctx, stream_id) orelse return 0;
    const stream = h3StreamCtx(ctx, sdata) orelse return 0;

    stream.closed = true;
    if (app_error_code != NGHTTP3_H3_NO_ERROR) {
        stream.reset = true;
        if (stream.xfer_result == CURLE_OK) {
            stream.xfer_result = CURLE_HTTP3;
        }
    }
    if (!stream.rx_eos and stream.xfer_result == CURLE_OK) {
        stream.xfer_result = CURLE_PARTIAL_FILE;
    }
    check_and_notify(ctx, sdata, stream);
    return 0;
}

fn write_client_super(
    cf: *CurlCfilter,
    data: *CurlEasy,
    stream: *H3StreamCtx,
    buf: ?[*]const u8,
    buflen: usize,
    eos: bool,
) c_int {
    _ = cf;
    var result: CURLcode = CURLE_OK;
    if (buflen > 0) {
        if (buf) |b| {
            result = Curl_xfer_write_resp(data, b, buflen, false);
        }
    }
    if (result == CURLE_OK and eos) {
        var dummy: [1]u8 = .{0};
        result = Curl_xfer_write_resp(data, &dummy, 0, true);
    }
    if (result != CURLE_OK) {
        stream.xfer_result = result;
        if (result != CURLE_AGAIN) {
            return NGHTTP3_ERR_CALLBACK_FAILURE;
        }
    }
    return 0;
}

pub fn Curl_cf_ngtcp2_cb_h3_recv_data(
    conn: *nghttp3_conn,
    stream_id: i64,
    buf: [*]const u8,
    buflen: usize,
    user_data: ?*anyopaque,
    stream_user_data: ?*anyopaque,
) callconv(.c) c_int {
    _ = conn;
    _ = stream_user_data;
    const ctx: *CfNgtcp2Ctx = @ptrCast(@alignCast(user_data orelse return NGHTTP3_ERR_CALLBACK_FAILURE));
    const cf = ctx.cf orelse return NGHTTP3_ERR_CALLBACK_FAILURE;
    const sdata = Curl_cf_ngtcp2_get_xfer(ctx, stream_id) orelse return NGHTTP3_ERR_CALLBACK_FAILURE;
    const stream = h3StreamCtx(ctx, sdata) orelse return NGHTTP3_ERR_CALLBACK_FAILURE;

    var save: CfCallData = undefined;
    cfDataSave(&save, &ctx.call_data, sdata);
    defer cfDataRestore(&ctx.call_data, save);

    const rv = write_client_super(cf, sdata, stream, buf, buflen, false);
    if (Curl_xfer_write_is_paused(sdata)) {
        stream.quic_flow_blocked = true;
    }
    check_and_notify(ctx, sdata, stream);
    return rv;
}

pub fn Curl_cf_ngtcp2_cb_h3_deferred_consume(
    conn: *nghttp3_conn,
    stream_id: i64,
    consumed: usize,
    user_data: ?*anyopaque,
    stream_user_data: ?*anyopaque,
) callconv(.c) c_int {
    _ = conn;
    _ = stream_user_data;
    if (comptime !use_ngtcp2) return 0;
    const ctx: *CfNgtcp2Ctx = @ptrCast(@alignCast(user_data orelse return 0));
    if (ctx.qconn) |qconn| {
        _ = ngtcp2_c.ngtcp2_conn_extend_max_stream_offset(qconn, stream_id, consumed);
        ngtcp2_c.ngtcp2_conn_extend_max_offset(qconn, consumed);
    }
    return 0;
}

pub fn Curl_cf_ngtcp2_cb_h3_begin_headers(
    conn: *nghttp3_conn,
    stream_id: i64,
    user_data: ?*anyopaque,
    stream_user_data: ?*anyopaque,
) callconv(.c) c_int {
    _ = conn;
    _ = stream_id;
    _ = user_data;
    _ = stream_user_data;
    return 0;
}

pub fn Curl_cf_ngtcp2_cb_h3_recv_header(
    conn: *nghttp3_conn,
    stream_id: i64,
    token: i32,
    name: *nghttp3_rcbuf,
    value: *nghttp3_rcbuf,
    flags: u8,
    user_data: ?*anyopaque,
    stream_user_data: ?*anyopaque,
) callconv(.c) c_int {
    _ = conn;
    _ = token;
    _ = flags;
    _ = stream_user_data;
    if (comptime !use_ngtcp2) return NGHTTP3_ERR_CALLBACK_FAILURE;
    const ctx: *CfNgtcp2Ctx = @ptrCast(@alignCast(user_data orelse return NGHTTP3_ERR_CALLBACK_FAILURE));
    const sdata = Curl_cf_ngtcp2_get_xfer(ctx, stream_id) orelse return 0;
    const stream = h3StreamCtx(ctx, sdata) orelse return 0;

    const h3name = ngtcp2_c.nghttp3_rcbuf_get_buf(name);
    const h3val = ngtcp2_c.nghttp3_rcbuf_get_buf(value);

    var save: CfCallData = undefined;
    cfDataSave(&save, &ctx.call_data, sdata);
    defer cfDataRestore(&ctx.call_data, save);

    var result: CURLcode = CURLE_OK;
    if (h3name.len == 7 and h3name.base != null and std.mem.eql(u8, h3name.base.?[0..7], ":status")) {
        var line_buf: [16]u8 = @splat(0);
        result = Curl_http_decode_status(&stream.status_code, h3val.base.?, h3val.len);
        if (result == CURLE_OK) {
            const slice = std.fmt.bufPrint(line_buf[0 .. line_buf.len - 1], "HTTP/3 {d} \r\n", .{stream.status_code}) catch return NGHTTP3_ERR_CALLBACK_FAILURE;
            result = Curl_xfer_write_resp_hd(sdata, slice.ptr, slice.len, false);
        }
    } else if (h3name.base != null and h3val.base != null) {
        const total_len = h3name.len + 2 + h3val.len + 2;
        const hbuf = mem.malloc(total_len + 1) orelse {
            stream.xfer_result = CURLE_OUT_OF_MEMORY;
            check_and_notify(ctx, sdata, stream);
            return NGHTTP3_ERR_CALLBACK_FAILURE;
        };
        defer mem.free(hbuf);
        @memcpy(hbuf[0..h3name.len], h3name.base.?[0..h3name.len]);
        hbuf[h3name.len] = ':';
        hbuf[h3name.len + 1] = ' ';
        @memcpy(hbuf[h3name.len + 2 .. h3name.len + 2 + h3val.len], h3val.base.?[0..h3val.len]);
        hbuf[h3name.len + 2 + h3val.len] = '\r';
        hbuf[h3name.len + 2 + h3val.len + 1] = '\n';
        hbuf[total_len] = 0;

        result = Curl_xfer_write_resp_hd(sdata, hbuf, total_len, false);
    }

    if (result != CURLE_OK) {
        stream.xfer_result = result;
        check_and_notify(ctx, sdata, stream);
        return NGHTTP3_ERR_CALLBACK_FAILURE;
    }
    return 0;
}

pub fn Curl_cf_ngtcp2_cb_h3_end_headers(
    conn: *nghttp3_conn,
    stream_id: i64,
    fin: c_int,
    user_data: ?*anyopaque,
    stream_user_data: ?*anyopaque,
) callconv(.c) c_int {
    _ = conn;
    _ = stream_user_data;
    const ctx: *CfNgtcp2Ctx = @ptrCast(@alignCast(user_data orelse return NGHTTP3_ERR_CALLBACK_FAILURE));
    const cf = ctx.cf orelse return NGHTTP3_ERR_CALLBACK_FAILURE;
    const sdata = Curl_cf_ngtcp2_get_xfer(ctx, stream_id) orelse return 0;
    const stream = h3StreamCtx(ctx, sdata) orelse return 0;

    var save: CfCallData = undefined;
    cfDataSave(&save, &ctx.call_data, sdata);
    defer cfDataRestore(&ctx.call_data, save);

    const crlf = "\r\n";
    const result = Curl_xfer_write_resp_hd(sdata, crlf, 2, fin != 0);
    if (result != CURLE_OK) {
        stream.xfer_result = result;
        check_and_notify(ctx, sdata, stream);
        return NGHTTP3_ERR_CALLBACK_FAILURE;
    }
    if (@divTrunc(stream.status_code, 100) != 1) {
        stream.resp_hds_complete = true;
    }
    if (fin != 0) {
        stream.rx_eos = true;
        if (write_client_super(cf, sdata, stream, null, 0, true) != 0) {
            return NGHTTP3_ERR_CALLBACK_FAILURE;
        }
    }
    if (Curl_xfer_write_is_paused(sdata)) {
        stream.quic_flow_blocked = true;
    }
    check_and_notify(ctx, sdata, stream);
    return 0;
}

pub fn Curl_cf_ngtcp2_cb_h3_stop_sending(
    conn: *nghttp3_conn,
    stream_id: i64,
    app_error_code: u64,
    user_data: ?*anyopaque,
    stream_user_data: ?*anyopaque,
) callconv(.c) c_int {
    _ = conn;
    _ = stream_user_data;
    if (comptime !use_ngtcp2) return 0;
    const ctx: *CfNgtcp2Ctx = @ptrCast(@alignCast(user_data orelse return 0));
    const qconn = ctx.qconn orelse return 0;
    const rv = ngtcp2_c.ngtcp2_conn_shutdown_stream_read(qconn, 0, stream_id, app_error_code);
    if (rv != 0 and rv != NGTCP2_ERR_STREAM_NOT_FOUND) {
        return NGHTTP3_ERR_CALLBACK_FAILURE;
    }
    return 0;
}

pub fn Curl_cf_ngtcp2_cb_h3_end_stream(
    conn: *nghttp3_conn,
    stream_id: i64,
    user_data: ?*anyopaque,
    stream_user_data: ?*anyopaque,
) callconv(.c) c_int {
    _ = conn;
    _ = stream_user_data;
    const ctx: *CfNgtcp2Ctx = @ptrCast(@alignCast(user_data orelse return NGHTTP3_ERR_CALLBACK_FAILURE));
    const cf = ctx.cf orelse return NGHTTP3_ERR_CALLBACK_FAILURE;
    const sdata = Curl_cf_ngtcp2_get_xfer(ctx, stream_id) orelse return 0;
    const stream = h3StreamCtx(ctx, sdata) orelse return 0;

    var save: CfCallData = undefined;
    cfDataSave(&save, &ctx.call_data, sdata);
    defer cfDataRestore(&ctx.call_data, save);

    stream.rx_eos = true;
    const rv = write_client_super(cf, sdata, stream, null, 0, true);
    check_and_notify(ctx, sdata, stream);
    return rv;
}

pub fn Curl_cf_ngtcp2_cb_h3_reset_stream(
    conn: *nghttp3_conn,
    stream_id: i64,
    app_error_code: u64,
    user_data: ?*anyopaque,
    stream_user_data: ?*anyopaque,
) callconv(.c) c_int {
    _ = conn;
    _ = stream_user_data;
    if (comptime !use_ngtcp2) return 0;
    const ctx: *CfNgtcp2Ctx = @ptrCast(@alignCast(user_data orelse return 0));
    const qconn = ctx.qconn orelse return 0;
    const rv = ngtcp2_c.ngtcp2_conn_shutdown_stream_write(qconn, 0, stream_id, app_error_code);
    if (rv != 0 and rv != NGTCP2_ERR_STREAM_NOT_FOUND) {
        return NGHTTP3_ERR_CALLBACK_FAILURE;
    }
    return 0;
}

fn cb_get_conn(conn_ref: *ngtcp2_crypto_conn_ref) callconv(.c) ?*ngtcp2_conn {
    const ctx: *CfNgtcp2Ctx = @ptrCast(@alignCast(conn_ref.user_data orelse return null));
    return ctx.qconn;
}

fn cf_ngtcp2_on_session_reuse(
    cf: *CurlCfilter,
    data: ?*CurlEasy,
    alpns: *AlpnSpec,
    scs: *CurlSslSession,
    do_early_data: *bool,
) callconv(.c) CURLcode {
    _ = alpns;
    do_early_data.* = false;
    if (comptime !use_ngtcp2) return CURLE_OK;
    const ctx = cfToNgtcp2Ctx(cf) orelse return CURLE_OK;
    const qconn = ctx.qconn orelse return CURLE_OK;

    if (scs.quic_tp != null and scs.quic_tp_len > 0) {
        if (comptime (backend_options.ssl == .openssl)) {
            if (ctx.ossl_ctx) |octx| {
                ngtcp2_ossl_c.ngtcp2_crypto_ossl_ctx_set_ssl(octx, ctx.tls.ossl.ssl);
            }
        }
        const rv = ngtcp2_c.ngtcp2_conn_decode_and_set_0rtt_transport_params(
            qconn,
            scs.quic_tp.?,
            scs.quic_tp_len,
        );
        if (rv != 0) {
            trcCf(data, cf, "no zero rtt possible, error decoding transport parameters: %s", .{
                ngtcp2_c.ngtcp2_strerror(rv),
            });
        } else {
            do_early_data.* = true;
            ctx.earlydata_Attempted = true;
        }
    }
    return CURLE_OK;
}

fn cf_ngtcp2_new_session_cb(ssl: *anyopaque, ssl_sessionid: *anyopaque) callconv(.c) c_int {
    if (comptime !(use_ngtcp2 and backend_options.ssl == .openssl)) return 0;
    const cref_raw = ngtcp2_ossl_c.SSL_get_ex_data(ssl, 0) orelse return 0;
    const cref: *ngtcp2_crypto_conn_ref = @ptrCast(@alignCast(cref_raw));
    const ctx: *CfNgtcp2Ctx = @ptrCast(@alignCast(cref.user_data orelse return 0));
    const cf = ctx.cf orelse return 0;
    const data = ctx.call_data.data orelse return 0;
    const peer_key = ctx.ssl_peer.scache_key orelse return 0;
    const conn_config = vtls_backends.vtls_impl.Curl_ssl_cf_get_filter_config(cf) orelse return 0;
    if (!conn_config.primary_cache_session()) return 0;

    var scache: ?*vtls_backends.CurlSslScache = null;
    var has_share_scache = false;
    var trc_feat: ?*vtls_backends.CurlTrcFeat = null;
    Curl_vtls_acc_scache_params(data, &scache, &has_share_scache, &trc_feat);
    if (!vtls_scache_asn1.Curl_ssl_scache_use_zig(data, scache, conn_config)) return 0;

    const sess_len = ngtcp2_ossl_c.i2d_SSL_SESSION(ssl_sessionid, null);
    if (sess_len <= 0) return 0;
    const sess_buf_raw = mem.calloc(1, @intCast(sess_len)) orelse return 0;
    var sess_ptr: ?[*]u8 = @ptrCast(sess_buf_raw);
    const enc_len = ngtcp2_ossl_c.i2d_SSL_SESSION(ssl_sessionid, &sess_ptr);
    if (enc_len <= 0 or enc_len > sess_len) {
        mem.free(sess_buf_raw);
        return 0;
    }

    var qtp_clone: ?[*]u8 = null;
    var qtp_len: usize = 0;
    if (ctx.qconn) |qconn| {
        var tpbuf: [256]u8 = undefined;
        const tplen = ngtcp2_c.ngtcp2_conn_encode_0rtt_transport_params(qconn, &tpbuf, tpbuf.len);
        if (tplen > 0) {
            const ulen: usize = @intCast(tplen);
            if (mem.malloc(ulen)) |p| {
                @memcpy(p[0..ulen], tpbuf[0..ulen]);
                qtp_clone = p;
                qtp_len = ulen;
            }
        }
    }

    const timeout = ngtcp2_ossl_c.SSL_SESSION_get_timeout(ssl_sessionid);
    const valid_until = if (timeout > 0) Curl_pgrs_now(data).tv_sec + @as(i64, @intCast(timeout)) else 0;
    const earlydata_max: usize = ngtcp2_ossl_c.SSL_SESSION_get_max_early_data(ssl_sessionid);
    const ietf_tls_id = ngtcp2_ossl_c.SSL_version(ssl);

    var sc_session: ?*CurlSslSession = null;
    const res = vtls_scache_asn1.Curl_ssl_session_create2(
        @ptrCast(sess_buf_raw),
        @intCast(enc_len),
        ietf_tls_id,
        "h3",
        valid_until,
        earlydata_max,
        qtp_clone,
        qtp_len,
        &sc_session,
    );
    if (res != CURLE_OK or sc_session == null) return 0;
    _ = vtls_scache_asn1.Curl_ssl_scache_put_zig(
        cf,
        data,
        scache,
        has_share_scache,
        @ptrCast(conn_config),
        trc_feat,
        peer_key,
        sc_session.?,
    );
    return 0;
}

fn cf_ngtcp2_ssl_ctx_setup(
    cf: *CurlCfilter,
    data: ?*CurlEasy,
    user_data: ?*anyopaque,
) callconv(.c) CURLcode {
    if (comptime !use_ngtcp2) return CURLE_NOT_BUILT_IN;
    switch (comptime backend_options.ssl) {
        .openssl => {
            const octx: *vtls_backends.openssl_backend.OsslCtx = @ptrCast(@alignCast(user_data orelse return CURLE_FAILED_INIT));
            const ssl_ctx = octx.ssl_ctx orelse return CURLE_FAILED_INIT;
            _ = ngtcp2_ossl_c.SSL_CTX_ctrl(
                ssl_ctx,
                ngtcp2_ossl_c.SSL_CTRL_SET_SESS_CACHE_MODE,
                ngtcp2_ossl_c.SSL_SESS_CACHE_CLIENT | ngtcp2_ossl_c.SSL_SESS_CACHE_NO_INTERNAL,
                null,
            );
            ngtcp2_ossl_c.SSL_CTX_sess_set_new_cb(ssl_ctx, cf_ngtcp2_new_session_cb);
            _ = cf;
            return CURLE_OK;
        },
        .gnutls => {
            const gctx: *vtls_gtls.GtlsCtx = @ptrCast(@alignCast(user_data orelse return CURLE_FAILED_INIT));
            if (ngtcp2_gtls_c.ngtcp2_crypto_gnutls_configure_client_session(gctx.session) != 0) {
                Curl_failf(data, "ngtcp2_crypto_gnutls_configure_client_session failed");
                return CURLE_QUIC_CONNECT_ERROR;
            }
            _ = cf;
            return CURLE_OK;
        },
        .wolfssl => {
            const wctx: *vtls_wolfssl.WsslCtx = @ptrCast(@alignCast(user_data orelse return CURLE_FAILED_INIT));
            if (ngtcp2_wssl_c.ngtcp2_crypto_wolfssl_configure_client_context(wctx.ssl_ctx) != 0) {
                Curl_failf(data, "ngtcp2_crypto_wolfssl_configure_client_context failed");
                return CURLE_QUIC_CONNECT_ERROR;
            }
            _ = cf;
            return CURLE_OK;
        },
        else => return CURLE_NOT_BUILT_IN,
    }
}

fn quic_init_ssl(
    cf: *CurlCfilter,
    data: ?*CurlEasy,
    ctx: *CfNgtcp2Ctx,
) CURLcode {
    if (comptime !use_ngtcp2) return CURLE_NOT_BUILT_IN;
    const qconn = ctx.qconn orelse return CURLE_FAILED_INIT;
    ctx.conn_ref.get_conn = cb_get_conn;
    ctx.conn_ref.user_data = ctx;

    switch (comptime backend_options.ssl) {
        .openssl => {
            const result = vquic_core.Curl_vquic_tls_init(
                &ctx.tls,
                cf,
                data,
                &ctx.ssl_peer,
                &ALPN_SPEC_H3,
                cf_ngtcp2_ssl_ctx_setup,
                &ctx.tls.ossl,
                &ctx.conn_ref,
                cf_ngtcp2_on_session_reuse,
            );
            if (result != CURLE_OK) return result;
            if (ngtcp2_ossl_c.ngtcp2_crypto_ossl_ctx_new(&ctx.ossl_ctx, ctx.tls.ossl.ssl) != 0) {
                Curl_failf(data, "ngtcp2_crypto_ossl_ctx_new failed");
                return CURLE_FAILED_INIT;
            }
            ngtcp2_c.ngtcp2_conn_set_tls_native_handle(qconn, ctx.ossl_ctx);
            if (ngtcp2_ossl_c.ngtcp2_crypto_ossl_configure_client_session(ctx.tls.ossl.ssl) != 0) {
                Curl_failf(data, "ngtcp2_crypto_ossl_configure_client_session failed");
                return CURLE_FAILED_INIT;
            }
            if (ctx.tls.ossl.ssl) |ssl| {
                _ = ngtcp2_ossl_c.SSL_set_ex_data(ssl, 0, &ctx.conn_ref);
            }
            if (ctx.earlydata_Attempted) {
                if (ctx.tls.ossl.ssl) |ssl| {
                    _ = ngtcp2_ossl_c.SSL_set_quic_tls_early_data_enabled(ssl, 1);
                }
            }
            return CURLE_OK;
        },
        .gnutls => {
            const result = vquic_core.Curl_vquic_tls_init(
                &ctx.tls,
                cf,
                data,
                &ctx.ssl_peer,
                &ALPN_SPEC_H3,
                cf_ngtcp2_ssl_ctx_setup,
                &ctx.tls.gtls,
                &ctx.conn_ref,
                cf_ngtcp2_on_session_reuse,
            );
            if (result != CURLE_OK) return result;
            ngtcp2_c.ngtcp2_conn_set_tls_native_handle(qconn, ctx.tls.gtls.session);
            return CURLE_OK;
        },
        .wolfssl => {
            const result = vquic_core.Curl_vquic_tls_init(
                &ctx.tls,
                cf,
                data,
                &ctx.ssl_peer,
                &ALPN_SPEC_H3,
                cf_ngtcp2_ssl_ctx_setup,
                &ctx.tls.wssl,
                &ctx.conn_ref,
                cf_ngtcp2_on_session_reuse,
            );
            if (result != CURLE_OK) return result;
            ngtcp2_c.ngtcp2_conn_set_tls_native_handle(qconn, ctx.tls.wssl.ssl);
            return CURLE_OK;
        },
        else => return CURLE_NOT_BUILT_IN,
    }
}

fn qlog_callback(
    user_data: ?*anyopaque,
    flags: u32,
    data: ?*const anyopaque,
    datalen: usize,
) callconv(.c) void {
    _ = flags;
    const ctx: *CfNgtcp2Ctx = @ptrCast(@alignCast(user_data orelse return));
    if (ctx.qlogfd != -1) {
        const rc = writeFd(ctx.qlogfd, data, datalen);
        if (rc == -1) {
            closeFd(ctx.qlogfd);
            ctx.qlogfd = -1;
        }
    }
}

fn cfToNgtcp2Ctx(cf: *CurlCfilter) ?*CfNgtcp2Ctx {
    const raw = cf.ctx orelse return null;
    // Both CfNgtcp2Ctx and CfNgtcp2ProxyCtx (whose first field is `q: CfNgtcp2Ctx`) start with CfNgtcp2Ctx.
    return @ptrCast(@alignCast(raw));
}

fn report_consumed_data(
    cf: *CurlCfilter,
    data: ?*CurlEasy,
    ctx: *CfNgtcp2Ctx,
    stream: *H3StreamCtx,
) CURLcode {
    _ = cf;
    if (comptime !use_ngtcp2) return CURLE_OK;
    if (stream.quic_flow_blocked) {
        if (!Curl_xfer_write_is_paused(data)) {
            if (ctx.h3conn) |h3conn| {
                const rv = ngtcp2_c.nghttp3_conn_unblock_stream(h3conn, stream.id);
                if (rv != 0 and rv != NGHTTP3_ERR_STREAM_NOT_FOUND) {
                    return CURLE_HTTP3;
                }
            }
            stream.quic_flow_blocked = false;
        }
    }
    return CURLE_OK;
}

fn recv_pkt(
    pkt: [*]const u8,
    pktlen: usize,
    remote_addr: *const SockaddrStorage,
    remote_addrlen: socklen_t,
    ifindex: c_int,
    ecn: u8,
    userp: ?*anyopaque,
) callconv(.c) CURLcode {
    _ = ifindex;
    if (comptime !use_ngtcp2) return CURLE_NOT_BUILT_IN;
    const pktx: *PktIoCtx = @ptrCast(@alignCast(userp orelse return CURLE_INTERNAL_ERROR));
    const ctx = pktx.ctx;
    const qconn = ctx.qconn orelse return CURLE_QUIC_CONNECT_ERROR;

    Curl_cf_ngtcp2_io_ctx_update_time(pktx);
    pktx.pkt_count += 1;
    ngtcp2_c.ngtcp2_path_storage_init(
        &pktx.ps,
        &ctx.q.local_addr,
        ctx.q.local_addrlen,
        remote_addr,
        remote_addrlen,
        null,
    );

    var pi = ngtcp2_pkt_info{ .ecn = ecn };
    const rv = ngtcp2_c.Curl_ngtcp2_conn_read_pkt(
        qconn,
        &pktx.ps.path,
        &pi,
        pkt,
        pktlen,
        pktx.ts,
    );
    if (rv != 0) {
        trcCf(pktx.data, pktx.cf, "ingress, ngtcp2_conn_read_pkt failed: %s", .{ngtcp2_c.ngtcp2_strerror(rv)});
        if (ctx.last_error.error_code == 0) {
            if (rv == NGTCP2_ERR_CRYPTO) {
                ngtcp2_c.ngtcp2_ccerr_set_tls_alert(&ctx.last_error, ngtcp2_c.ngtcp2_conn_get_tls_alert(qconn), null, 0);
            } else {
                ngtcp2_c.ngtcp2_ccerr_set_liberr(&ctx.last_error, rv, null, 0);
            }
        }
        if (ctx.tls_vrfy_result != CURLE_OK) {
            return ctx.tls_vrfy_result;
        }
        if (rv == NGTCP2_ERR_CRYPTO) {
            return if (ctx.tls_vrfy_ok) CURLE_SSL_CONNECT_ERROR else CURLE_PEER_FAILED_VERIFICATION;
        }
        return CURLE_RECV_ERROR;
    }
    return CURLE_OK;
}

fn progress_ingress_cf(
    cf: *CurlCfilter,
    data: ?*CurlEasy,
    ctx: *CfNgtcp2Ctx,
    pcount: ?*usize,
) CURLcode {
    if (comptime !use_ngtcp2) return CURLE_NOT_BUILT_IN;
    var buf: [4096]u8 = undefined;
    var nread: usize = 0;
    var pktx: PktIoCtx = undefined;
    var pkt_count: usize = 0;
    var result: CURLcode = CURLE_OK;

    Curl_cf_ngtcp2_io_ctx_init(&pktx, cf, data, ctx);

    while (pkt_count < 64) {
        nread = 0;
        result = Curl_conn_cf_recv(cf.next, data, &buf, buf.len, &nread);
        if (result != CURLE_OK) {
            if (result == CURLE_AGAIN) {
                result = CURLE_OK;
            }
            break;
        }
        if (nread == 0) break;

        if (!ctx.q.got_first_byte) {
            ctx.q.first_byte_at = ctx.q.last_op;
            ctx.q.got_first_byte = true;
        }
        ctx.q.last_io = ctx.q.last_op;
        pkt_count += 1;

        const path_ptr = ngtcp2_c.ngtcp2_conn_get_path(ctx.qconn.?);
        var pi = ngtcp2_pkt_info{ .ecn = 0 };
        const rv = ngtcp2_c.Curl_ngtcp2_conn_read_pkt(
            ctx.qconn.?,
            path_ptr,
            &pi,
            &buf,
            nread,
            pktx.ts,
        );
        if (rv != 0) {
            if (ctx.last_error.error_code == 0) {
                if (rv == NGTCP2_ERR_CRYPTO) {
                    ngtcp2_c.ngtcp2_ccerr_set_tls_alert(&ctx.last_error, ngtcp2_c.ngtcp2_conn_get_tls_alert(ctx.qconn.?), null, 0);
                } else {
                    ngtcp2_c.ngtcp2_ccerr_set_liberr(&ctx.last_error, rv, null, 0);
                }
            }
            if (rv == NGTCP2_ERR_CRYPTO) {
                result = if (ctx.tls_vrfy_ok) CURLE_SSL_CONNECT_ERROR else CURLE_PEER_FAILED_VERIFICATION;
            } else {
                result = CURLE_RECV_ERROR;
            }
            break;
        }
    }

    if (pcount) |pc| pc.* = pkt_count;
    return result;
}

pub fn Curl_cf_ngtcp2_progress_ingress(
    cf: *CurlCfilter,
    data: ?*CurlEasy,
    ctx: *CfNgtcp2Ctx,
    pcount: ?*usize,
) callconv(.c) CURLcode {
    if (pcount) |pc| pc.* = 0;
    if (comptime !use_ngtcp2) return CURLE_NOT_BUILT_IN;

    var result = vquic_core.Curl_vquic_tls_before_recv(&ctx.tls, cf, data);
    if (result != CURLE_OK) return result;

    if (ctx.q.sockfd != CURL_SOCKET_BAD) {
        var pktx: PktIoCtx = undefined;
        Curl_cf_ngtcp2_io_ctx_init(&pktx, cf, data, ctx);

        const pkts_chunk: usize = 128;
        const pkts_max: usize = 10 * pkts_chunk;
        var i: usize = 0;
        var total_pkts: usize = 0;
        while (i < pkts_max) : (i += pkts_chunk) {
            pktx.pkt_count = 0;
            result = vquic_core.Curl_vquic_recv_packets(cf, data, &ctx.q, pkts_chunk, recv_pkt, &pktx);
            total_pkts += pktx.pkt_count;
            if (result != CURLE_OK) break;
            if (pktx.pkt_count < pkts_chunk) break;
            result = progress_egress(cf, data, ctx, &pktx);
            if (result != CURLE_OK) break;
        }
        if (pcount) |pc| pc.* = total_pkts;
    } else {
        result = progress_ingress_cf(cf, data, ctx, pcount);
    }
    return result;
}

fn progress_egress(
    cf: *CurlCfilter,
    data: ?*CurlEasy,
    ctx: *CfNgtcp2Ctx,
    pktx: *PktIoCtx,
) CURLcode {
    if (comptime !use_ngtcp2) return CURLE_NOT_BUILT_IN;
    const qconn = ctx.qconn orelse return CURLE_OK;

    var result = vquic_core.Curl_vquic_flush(cf, data, &ctx.q);
    if (result != CURLE_OK) {
        if (result == CURLE_AGAIN) {
            Curl_cf_ngtcp2_cmn_set_expiry(cf, data, ctx);
        }
        return result;
    }

    Curl_cf_ngtcp2_io_ctx_update_time(pktx);
    ngtcp2_c.ngtcp2_path_storage_zero(&pktx.ps);

    const pathmax = ngtcp2_c.ngtcp2_conn_get_max_tx_udp_payload_size(qconn);
    const max_pktlen = @min(NGTCP2_MAX_UDP_PAYLOAD_SIZE, pathmax);
    const max_pktcnt: usize = GSO_MAX_BUFFERS;
    const send_quantum = ngtcp2_c.ngtcp2_conn_get_send_quantum(qconn);

    var gsolen: usize = 0;
    var pktcnt: usize = 0;
    var ts_quantum: usize = 0;
    var pkt_buf: [NGTCP2_MAX_UDP_PAYLOAD_SIZE]u8 = undefined;

    while (pktcnt < max_pktcnt and ts_quantum < send_quantum) {
        if (io_buffers.Curl_bufq_is_full(&ctx.q.sendbuf)) break;
        var vec: [16]nghttp3_vec = undefined;
        var veccnt: usize = 0;
        var stream_id: i64 = -1;
        var fin: c_int = 0;

        if (ctx.h3conn != null and ngtcp2_c.ngtcp2_conn_get_streams_bidi_left(qconn) > 0) {
            const sveccnt = ngtcp2_c.nghttp3_conn_writev_stream(
                ctx.h3conn.?,
                &stream_id,
                &fin,
                &vec,
                vec.len,
            );
            if (sveccnt < 0) {
                const h3err: c_int = @intCast(sveccnt);
                Curl_failf(data, "nghttp3_conn_writev_stream returned error: %s", ngtcp2_c.nghttp3_strerror(h3err));
                return CURLE_SEND_ERROR;
            }
            veccnt = @intCast(sveccnt);
        }

        var flags: u32 = NGTCP2_WRITE_STREAM_FLAG_MORE |
            (if (fin != 0) NGTCP2_WRITE_STREAM_FLAG_FIN else NGTCP2_WRITE_STREAM_FLAG_NONE);
        if (pktcnt + 1 >= max_pktcnt) {
            flags &= ~NGTCP2_WRITE_STREAM_FLAG_MORE;
        }

        var ndatalen: ngtcp2_ssize = 0;
        const written = ngtcp2_c.Curl_ngtcp2_conn_writev_stream(
            qconn,
            &pktx.ps.path,
            null,
            &pkt_buf,
            max_pktlen,
            &ndatalen,
            flags,
            stream_id,
            @ptrCast(&vec),
            veccnt,
            pktx.ts,
        );

        if (written == 0) {
            break;
        } else if (written < 0) {
            if (written == NGTCP2_ERR_WRITE_MORE) {
                std.debug.assert(ndatalen >= 0);
                const rc = ngtcp2_c.nghttp3_conn_add_write_offset(ctx.h3conn.?, stream_id, @intCast(ndatalen));
                if (rc != 0) return CURLE_SEND_ERROR;
                continue;
            }
            const qerr: c_int = @intCast(written);
            switch (qerr) {
                NGTCP2_ERR_STREAM_DATA_BLOCKED => {
                    _ = ngtcp2_c.nghttp3_conn_block_stream(ctx.h3conn.?, stream_id);
                    continue;
                },
                NGTCP2_ERR_STREAM_SHUT_WR => {
                    const rc = ngtcp2_c.nghttp3_conn_add_write_offset(ctx.h3conn.?, stream_id, @intCast(ndatalen));
                    if (rc != 0) return CURLE_SEND_ERROR;
                    continue;
                },
                NGTCP2_ERR_IDLE_CLOSE => return CURLE_OK,
                else => {
                    Curl_failf(data, "ngtcp2_conn_writev_stream returned error: %s", ngtcp2_c.ngtcp2_strerror(qerr));
                    return CURLE_SEND_ERROR;
                },
            }
        }

        const pkt_size: usize = @intCast(written);
        if (ndatalen > 0 and ctx.h3conn != null) {
            const rc = ngtcp2_c.nghttp3_conn_add_write_offset(ctx.h3conn.?, stream_id, @intCast(ndatalen));
            if (rc != 0) return CURLE_SEND_ERROR;
        }

        if (pktcnt == 0) {
            gsolen = pkt_size;
            ctx.q.gsolen = gsolen;
            ctx.q.split_len = 0;
            ctx.q.split_gsolen = 0;
        } else if (pkt_size > gsolen or (gsolen != max_pktlen and pkt_size != gsolen)) {
            ctx.q.split_len = io_buffers.Curl_bufq_len(&ctx.q.sendbuf);
            ctx.q.split_gsolen = pkt_size;
        }

        var nwritten_buf: usize = 0;
        result = io_buffers.Curl_bufq_write(&ctx.q.sendbuf, &pkt_buf, pkt_size, &nwritten_buf);
        if (result != CURLE_OK) return result;

        pktcnt += 1;
        ts_quantum += pkt_size;

        if (ctx.q.split_len > 0 or pkt_size < gsolen) {
            break;
        }
    }

    if (!io_buffers.Curl_bufq_is_empty(&ctx.q.sendbuf)) {
        result = vquic_core.Curl_vquic_flush(cf, data, &ctx.q);
        ngtcp2_c.ngtcp2_conn_update_pkt_tx_time(qconn, pktx.ts);
        if (result != CURLE_OK) {
            if (result == CURLE_AGAIN) {
                Curl_cf_ngtcp2_cmn_set_expiry(cf, data, ctx);
            }
            return result;
        }
    }

    Curl_cf_ngtcp2_cmn_set_expiry(cf, data, ctx);
    return CURLE_OK;
}

pub fn Curl_cf_ngtcp2_progress_egress(
    cf: *CurlCfilter,
    data: ?*CurlEasy,
    ctx: *CfNgtcp2Ctx,
) callconv(.c) CURLcode {
    var pktx: PktIoCtx = undefined;
    Curl_cf_ngtcp2_io_ctx_init(&pktx, cf, data, ctx);
    return progress_egress(cf, data, ctx, &pktx);
}

pub fn Curl_cf_ngtcp2_cmn_set_expiry(
    cf: *CurlCfilter,
    data: ?*CurlEasy,
    ctx: *CfNgtcp2Ctx,
) callconv(.c) void {
    _ = cf;
    if (comptime !use_ngtcp2) return;
    const d = data orelse return;
    const qconn = ctx.qconn orelse {
        Curl_expire_clear(d, EXPIRE_QUIC);
        return;
    };

    const expiry = ngtcp2_c.ngtcp2_conn_get_expiry(qconn);
    if (expiry != std.math.maxInt(u64)) {
        const now_p = Curl_pgrs_now(d);
        const now_ts: u64 = @as(u64, @intCast(now_p.tv_sec)) * NGTCP2_SECONDS +
            @as(u64, @intCast(now_p.tv_usec)) * NGTCP2_MICROSECONDS;
        var timeout_ms: timediff_t = 0;
        if (expiry > now_ts) {
            timeout_ms = @intCast((expiry - now_ts + NGTCP2_MILLISECONDS - 1) / NGTCP2_MILLISECONDS);
        }
        Curl_expire(d, timeout_ms, EXPIRE_QUIC);
    } else {
        Curl_expire_clear(d, EXPIRE_QUIC);
    }
}

fn check_expiry(
    cf: *CurlCfilter,
    data: ?*CurlEasy,
    ctx: *CfNgtcp2Ctx,
    pktx: *PktIoCtx,
) CURLcode {
    if (comptime !use_ngtcp2) return CURLE_NOT_BUILT_IN;
    const qconn = ctx.qconn orelse return CURLE_OK;

    Curl_cf_ngtcp2_io_ctx_update_time(pktx);
    const rv = ngtcp2_c.ngtcp2_conn_handle_expiry(qconn, pktx.ts);
    if (rv != 0) {
        switch (rv) {
            NGTCP2_ERR_IDLE_CLOSE => {
                trcCf(data, cf, "connection idle timeout", .{});
                return CURLE_OPERATION_TIMEDOUT;
            },
            else => {
                Curl_failf(data, "ngtcp2_conn_handle_expiry returned error: %s", ngtcp2_c.ngtcp2_strerror(rv));
                ngtcp2_c.ngtcp2_ccerr_set_liberr(&ctx.last_error, rv, null, 0);
                return CURLE_SEND_ERROR;
            },
        }
    }
    return CURLE_OK;
}

fn cf_ngtcp2_start(
    cf: *CurlCfilter,
    data: ?*CurlEasy,
    ctx: *CfNgtcp2Ctx,
    pktx: *PktIoCtx,
) CURLcode {
    if (comptime !use_ngtcp2) return CURLE_NOT_BUILT_IN;
    const cbs = ctx.cbs orelse return CURLE_FAILED_INIT;

    var result = vquic_core.Curl_vquic_ctx_init(data, &ctx.q);
    if (result != CURLE_OK) return result;

    ctx.cf = cf;
    var addr: ?*CurlSockaddrEx = null;
    if (Curl_cf_socket_peek(cf.next, data, &ctx.q.sockfd, &addr, null) != CURLE_OK) {
        ctx.q.sockfd = CURL_SOCKET_BAD;
        ctx.q.no_gso = true;
    }

    ctx.version = NGTCP2_PROTO_VER_MAX;
    ctx.max_stream_window = H3_STREAM_WINDOW_SIZE;
    ctx.max_idle_ms = @intCast(QUIC_IDLE_TIMEOUT / NGTCP2_MILLISECONDS);

    ngtcp2_c.Curl_ngtcp2_settings_default(&ctx.settings);
    ctx.settings.initial_ts = pktx.ts;
    ctx.settings.initial_rtt = NGTCP2_DEFAULT_INITIAL_RTT;
    ctx.settings.cc_algo = NGTCP2_CC_ALGO_CUBIC;
    ctx.settings.max_tx_udp_payload_size = vquic_core.MAX_UDP_PAYLOAD_SIZE;
    ctx.settings.max_window = 10 * H3_STREAM_WINDOW_SIZE;
    ctx.settings.max_stream_window = ctx.max_stream_window;
    ctx.settings.handshake_timeout = HANDSHAKE_TIMEOUT;

    ngtcp2_c.Curl_ngtcp2_transport_params_default(&ctx.transport_params);
    ctx.transport_params.initial_max_stream_data_bidi_local = ctx.max_stream_window;
    ctx.transport_params.initial_max_stream_data_bidi_remote = H3_STREAM_WINDOW_SIZE;
    ctx.transport_params.initial_max_stream_data_uni = H3_STREAM_WINDOW_SIZE;
    ctx.transport_params.initial_max_data = 10 * H3_STREAM_WINDOW_SIZE;
    ctx.transport_params.initial_max_streams_bidi = 0;
    ctx.transport_params.initial_max_streams_uni = 3;
    ctx.transport_params.max_idle_timeout = ctx.max_idle_ms * NGTCP2_MILLISECONDS;
    ctx.transport_params.Active_connection_id_limit = 7;
    ctx.transport_params.grease_quic_bit = 1;

    if (cbs.ng_settings) |ng_settings_fn| {
        result = ng_settings_fn(cf, data, ctx, &ctx.settings, &ctx.transport_params);
        if (result != CURLE_OK) return result;
    }

    ctx.dcid.datalen = NGTCP2_MAX_CIDLEN;
    if (Curl_rand_bytes(data, &ctx.dcid.data, NGTCP2_MAX_CIDLEN) != CURLE_OK)
        return CURLE_QUIC_CONNECT_ERROR;

    ctx.scid.datalen = NGTCP2_MAX_CIDLEN;
    if (Curl_rand_bytes(data, &ctx.scid.data, NGTCP2_MAX_CIDLEN) != CURLE_OK)
        return CURLE_QUIC_CONNECT_ERROR;

    _ = vquic_core.Curl_qlogdir(data, &ctx.scid.data, NGTCP2_MAX_CIDLEN, &ctx.qlogfd);
    if (ctx.qlogfd != -1) {
        ctx.settings.qlog_write = qlog_callback;
    }

    ngtcp2_c.ngtcp2_ccerr_default(&ctx.last_error);

    if (ctx.q.sockfd != CURL_SOCKET_BAD and addr != null) {
        ctx.q.local_addrlen = @sizeOf(SockaddrStorage);
        const grv = posix_io.getsockname(
            ctx.q.sockfd,
            @ptrCast(&ctx.q.local_addr),
            &ctx.q.local_addrlen,
        );
        if (grv == -1) {
            return CURLE_QUIC_CONNECT_ERROR;
        }
        ngtcp2_c.ngtcp2_path_storage_init(
            &pktx.ps,
            &ctx.q.local_addr,
            ctx.q.local_addrlen,
            &addr.?.sa_addr,
            addr.?.addrlen,
            null,
        );
    } else {
        var dummy_local: SockaddrStorage = .{};
        var dummy_remote: SockaddrStorage = .{};
        dummy_local.ss_family = 2; // AF_INET
        dummy_remote.ss_family = 2;
        ngtcp2_c.ngtcp2_path_storage_init(
            &pktx.ps,
            &dummy_local,
            16,
            &dummy_remote,
            16,
            null,
        );
    }

    const rc = ngtcp2_c.Curl_ngtcp2_conn_client_new(
        &ctx.qconn,
        &ctx.dcid,
        &ctx.scid,
        &pktx.ps.path,
        NGTCP2_PROTO_VER_V1,
        &cbs.q_cbs,
        &ctx.settings,
        &ctx.transport_params,
        vquic_core.Curl_ngtcp2_mem(),
        ctx,
    );
    if (rc != 0) return CURLE_QUIC_CONNECT_ERROR;

    result = quic_init_ssl(cf, data, ctx);
    if (result != CURLE_OK) return result;

    return CURLE_OK;
}

pub fn Curl_cf_ngtcp2_cmn_connect(
    cf: *CurlCfilter,
    data: ?*CurlEasy,
    ctx: *CfNgtcp2Ctx,
    done: *bool,
) callconv(.c) CURLcode {
    if (comptime !use_ngtcp2) return CURLE_NOT_BUILT_IN;
    if (cf.isConnected()) {
        done.* = true;
        return CURLE_OK;
    }

    var save: CfCallData = undefined;
    cfDataSave(&save, &ctx.call_data, data);
    defer cfDataRestore(&ctx.call_data, save);

    var dbool = false;
    var result = Curl_conn_cf_connect(cf.next, data, &dbool);
    if (result != CURLE_OK or !dbool) {
        done.* = false;
        return result;
    }

    var pktx: PktIoCtx = undefined;
    Curl_cf_ngtcp2_io_ctx_init(&pktx, cf, data, ctx);

    if (ctx.qconn == null) {
        ctx.q.last_io = pktx.ctx.q.last_op;
        result = cf_ngtcp2_start(cf, data, ctx, &pktx);
        if (result != CURLE_OK) return result;
        if (cf.isConnected()) {
            done.* = true;
            return CURLE_OK;
        }
        result = progress_egress(cf, data, ctx, &pktx);
        return if (result == CURLE_AGAIN) CURLE_OK else result;
    }

    result = Curl_cf_ngtcp2_progress_ingress(cf, data, ctx, null);
    if (result != CURLE_OK) return result;

    result = check_expiry(cf, data, ctx, &pktx);
    if (result != CURLE_OK) return result;

    result = progress_egress(cf, data, ctx, &pktx);
    if (result == CURLE_AGAIN) {
        result = CURLE_OK;
    } else if (result != CURLE_OK) {
        return result;
    }

    if (ctx.h3conn != null and ctx.tls_vrfy_ok) {
        if (!ctx.tls_hshk_reported) {
            vquic_core.Curl_vquic_report_handshake(&ctx.tls, cf, data);
            ctx.tls_hshk_reported = true;
        }
        done.* = true;
    }

    return result;
}

pub fn Curl_cf_ngtcp2_cmn_shutdown(
    cf: *CurlCfilter,
    data: ?*CurlEasy,
    ctx: *CfNgtcp2Ctx,
    done: *bool,
) callconv(.c) CURLcode {
    if (comptime !use_ngtcp2) {
        done.* = true;
        return CURLE_OK;
    }
    if (cf.isShutdown() or ctx.qconn == null) {
        done.* = true;
        return CURLE_OK;
    }

    var save: CfCallData = undefined;
    cfDataSave(&save, &ctx.call_data, data);
    defer cfDataRestore(&ctx.call_data, save);

    done.* = false;
    if (!ctx.shutdown_started) {
        var pktx: PktIoCtx = undefined;
        Curl_cf_ngtcp2_io_ctx_init(&pktx, cf, data, ctx);
        ctx.shutdown_started = true;

        var pkt_buf: [NGTCP2_MAX_UDP_PAYLOAD_SIZE]u8 = undefined;
        const rc = ngtcp2_c.Curl_ngtcp2_conn_write_connection_close(
            ctx.qconn.?,
            &pktx.ps.path,
            null,
            &pkt_buf,
            pkt_buf.len,
            &ctx.last_error,
            pktx.ts,
        );
        if (rc > 0) {
            var nwritten_buf: usize = 0;
            _ = io_buffers.Curl_bufq_write(&ctx.q.sendbuf, &pkt_buf, @intCast(rc), &nwritten_buf);
            ctx.q.gsolen = @intCast(rc);
            ctx.q.split_len = 0;
            ctx.q.split_gsolen = 0;
        }
    }

    if (!io_buffers.Curl_bufq_is_empty(&ctx.q.sendbuf)) {
        const result = vquic_core.Curl_vquic_flush(cf, data, &ctx.q);
        if (result == CURLE_AGAIN) {
            return CURLE_OK;
        }
        return result;
    }

    done.* = true;
    return CURLE_OK;
}

pub fn Curl_cf_ngtcp2_cmn_conn_close(
    cf: *CurlCfilter,
    data: ?*CurlEasy,
    ctx: *CfNgtcp2Ctx,
) callconv(.c) void {
    var save: CfCallData = undefined;
    cfDataSave(&save, &ctx.call_data, data);
    defer cfDataRestore(&ctx.call_data, save);

    if (ctx.qconn != null and !ctx.shutdown_started) {
        var done = false;
        _ = Curl_cf_ngtcp2_cmn_shutdown(cf, data, ctx, &done);
    }
}

pub fn Curl_cf_ngtcp2_cmn_conn_is_alive(
    cf: *CurlCfilter,
    data: ?*CurlEasy,
    ctx: *CfNgtcp2Ctx,
    input_pending: *bool,
) callconv(.c) bool {
    input_pending.* = false;
    if (comptime !use_ngtcp2) return false;
    const qconn = ctx.qconn orelse return false;

    if (ngtcp2_c.ngtcp2_conn_in_closing_period(qconn) != 0 or
        ngtcp2_c.ngtcp2_conn_in_draining_period(qconn) != 0)
    {
        return false;
    }

    const now = Curl_pgrs_now(data);
    const elapsed_ms = curlx_time_net.curlx_ptimediff_ms(now, &ctx.q.last_io);
    if (elapsed_ms > 0 and @as(u64, @intCast(elapsed_ms)) > ctx.max_idle_ms) {
        return false;
    }

    if (cf.next) |next| {
        if (!next.cft.is_alive(next, data, input_pending)) {
            return false;
        }
        if (input_pending.*) {
            var save: CfCallData = undefined;
            cfDataSave(&save, &ctx.call_data, data);
            defer cfDataRestore(&ctx.call_data, save);
            if (Curl_cf_ngtcp2_progress_ingress(cf, data, ctx, null) != CURLE_OK) {
                return false;
            }
            if (ngtcp2_c.ngtcp2_conn_in_closing_period(qconn) != 0 or
                ngtcp2_c.ngtcp2_conn_in_draining_period(qconn) != 0)
            {
                return false;
            }
        }
    }
    return true;
}

pub fn Curl_cf_ngtcp2_cmn_query(
    cf: *CurlCfilter,
    data: ?*CurlEasy,
    ctx: *CfNgtcp2Ctx,
    query: c_int,
    pres1: ?*c_int,
    pres2: ?*anyopaque,
) callconv(.c) CURLcode {
    switch (query) {
        CF_QUERY_MAX_CONCURRENT => {
            if (comptime !use_ngtcp2) return CURLE_NOT_BUILT_IN;
            const p1 = pres1 orelse return CURLE_BAD_FUNCTION_ARGUMENT;
            const qconn = ctx.qconn orelse {
                p1.* = 0;
                return CURLE_OK;
            };
            const max_bidi = ngtcp2_c.ngtcp2_conn_get_streams_bidi_left(qconn);
            const in_use: u64 = if (cf.conn) |c| Curl_conn_get_attached_xfers(c) else 0;
            const total = max_bidi + in_use;
            p1.* = if (total > std.math.maxInt(c_int)) std.math.maxInt(c_int) else @intCast(total);
            return CURLE_OK;
        },
        CF_QUERY_CONNECT_REPLY_MS => {
            const p1 = pres1 orelse return CURLE_BAD_FUNCTION_ARGUMENT;
            if (ctx.q.got_first_byte) {
                const ms = curlx_time_net.curlx_ptimediff_ms(&ctx.q.first_byte_at, &ctx.q.last_op);
                p1.* = if (ms > 0) @intCast(ms) else 0;
            } else {
                p1.* = -1;
            }
            return CURLE_OK;
        },
        CF_QUERY_TIMER_CONNECT => {
            if (pres2) |p2| {
                const ts: *curltime = @ptrCast(@alignCast(p2));
                if (ctx.q.got_first_byte) {
                    ts.* = ctx.q.first_byte_at;
                }
            }
            return CURLE_OK;
        },
        CF_QUERY_TIMER_APPCONNECT => {
            if (pres2) |p2| {
                const ts: *curltime = @ptrCast(@alignCast(p2));
                if (cf.isConnected()) {
                    ts.* = ctx.q.last_io;
                }
            }
            return CURLE_OK;
        },
        CF_QUERY_NEED_FLUSH => {
            if (pres1) |p1| {
                p1.* = if (!io_buffers.Curl_bufq_is_empty(&ctx.q.sendbuf)) 1 else 0;
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
                const info: *vtls_backends.CurlTlsSessionInfo = @ptrCast(@alignCast(p2));
                if (vquic_core.Curl_vquic_tls_get_ssl_info(&ctx.tls, query == CF_QUERY_SSL_CTX_INFO, info)) {
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
        else => return Curl_cf_def_query(cf, data, query, pres1, pres2),
    }
}

pub fn Curl_cf_ngtcp2_cmn_cntrl(
    cf: *CurlCfilter,
    data: ?*CurlEasy,
    ctx: *CfNgtcp2Ctx,
    event: c_int,
    arg1: c_int,
    arg2: ?*anyopaque,
) callconv(.c) CURLcode {
    _ = arg2;
    switch (event) {
        CF_CTRL_DATA_SETUP => return CURLE_OK,
        CF_CTRL_DATA_PAUSE => {
            if (arg1 == 0) {
                if (h3StreamCtx(ctx, data)) |stream| {
                    const result = report_consumed_data(cf, data, ctx, stream);
                    if (result != CURLE_OK) return result;
                    return Curl_cf_ngtcp2_progress_egress(cf, data, ctx);
                }
            }
            return CURLE_OK;
        },
        CF_CTRL_DATA_DONE_SEND => {
            if (h3StreamCtx(ctx, data)) |stream| {
                if (!stream.send_closed) {
                    stream.send_closed = true;
                    stream.upload_left = 0;
                    if (comptime use_ngtcp2) {
                        if (ctx.h3conn) |h3conn| {
                            _ = ngtcp2_c.nghttp3_conn_resume_stream(h3conn, stream.id);
                        }
                    }
                }
            }
            return CURLE_OK;
        },
        CF_CTRL_DATA_DONE => {
            Curl_cf_ngtcp2_h3_stream_done(cf, data, ctx);
            return CURLE_OK;
        },
        CF_CTRL_CONN_INFO_UPDATE => {
            if ((cf.cft.flags & CF_TYPE_PROXY) == 0 and cf.isConnected()) {
                if (cf.conn) |conn| {
                    Curl_http_acc_conn_set_httpversion_seen(conn, 30);
                    Curl_conn_set_multiplex(conn);
                }
            }
            return CURLE_OK;
        },
        else => return CURLE_OK,
    }
}

// ============================================================================
// 4. HTTP/3 Connection Filter: Curl_cft_http3 (lib/vquic/cf-ngtcp2.c)
// ============================================================================

fn cf_ngtcp2_ng_settings(
    cf: *CurlCfilter,
    data: ?*CurlEasy,
    ctx: *CfNgtcp2Ctx,
    settings: *ngtcp2_settings,
    params: *ngtcp2_transport_params,
) callconv(.c) CURLcode {
    _ = cf;
    var max_stream_window: usize = H3_STREAM_WINDOW_SIZE;
    if (data) |d| {
        const dl_rlimit = Curl_xfer_get_dl_rlimit(d);
        const rlimit_step = Curl_rlimit_per_step(dl_rlimit);
        if (rlimit_step > 0) {
            max_stream_window = @min(max_stream_window, @as(usize, @intCast(rlimit_step)));
        }
    }
    ctx.max_stream_window = max_stream_window;
    settings.max_stream_window = max_stream_window;
    settings.max_window = 10 * max_stream_window;
    params.initial_max_stream_data_bidi_local = max_stream_window;
    params.initial_max_data = 10 * max_stream_window;
    return CURLE_OK;
}

fn cf_ngtcp2_h3_settings(
    cf: *CurlCfilter,
    data: ?*CurlEasy,
    ctx: *CfNgtcp2Ctx,
    settings: *nghttp3_settings,
) callconv(.c) CURLcode {
    _ = cf;
    _ = data;
    _ = ctx;
    _ = settings;
    return CURLE_OK;
}

pub const cf_ngtcp2_cbs: CfNgtcp2Cbs = if (use_ngtcp2) .{
    .q_cbs = .{
        .client_initial = @ptrCast(&ngtcp2_c.ngtcp2_crypto_client_initial_cb),
        .recv_crypto_data = @ptrCast(&ngtcp2_c.ngtcp2_crypto_recv_crypto_data_cb),
        .handshake_completed = Curl_cf_ngtcp2_cb_handshake_completed,
        .encrypt = @ptrCast(&ngtcp2_c.ngtcp2_crypto_encrypt_cb),
        .decrypt = @ptrCast(&ngtcp2_c.ngtcp2_crypto_decrypt_cb),
        .hp_mask = @ptrCast(&ngtcp2_c.ngtcp2_crypto_hp_mask_cb),
        .recv_stream_data = Curl_cf_ngtcp2_cb_recv_stream_data,
        .acked_stream_data_offset = Curl_cf_ngtcp2_cb_acked_stream_data_offset,
        .stream_open = Curl_cf_ngtcp2_cb_stream_open,
        .stream_close = Curl_cf_ngtcp2_cb_stream_close,
        .recv_retry = @ptrCast(&ngtcp2_c.ngtcp2_crypto_recv_retry_cb),
        .extend_max_local_streams_bidi = Curl_cf_ngtcp2_cb_extend_max_local_streams_bidi,
        .rand = Curl_cf_ngtcp2_cb_rand,
        .get_new_connection_id = Curl_cf_ngtcp2_cb_get_new_connection_id,
        .remove_connection_id = Curl_cf_ngtcp2_cb_remove_connection_id,
        .update_key = @ptrCast(&ngtcp2_c.ngtcp2_crypto_update_key_cb),
        .stream_reset = Curl_cf_ngtcp2_cb_stream_reset,
        .delete_crypto_aead_ctx = @ptrCast(&ngtcp2_c.ngtcp2_crypto_delete_crypto_aead_ctx_cb),
        .delete_crypto_cipher_ctx = @ptrCast(&ngtcp2_c.ngtcp2_crypto_delete_crypto_cipher_ctx_cb),
        .get_path_challenge_data = @ptrCast(&ngtcp2_c.ngtcp2_crypto_get_path_challenge_data_cb),
        .stream_stop_sending = Curl_cf_ngtcp2_cb_stream_stop_sending,
        .version_negotiation = @ptrCast(&ngtcp2_c.ngtcp2_crypto_version_negotiation_cb),
        .recv_rx_key = Curl_cf_ngtcp2_cb_recv_rx_key,
        .recv_tx_key = Curl_cf_ngtcp2_cb_recv_tx_key,
    },
    .h3_cbs = .{
        .acked_stream_data = Curl_cf_ngtcp2_cb_h3_acked_stream_data,
        .stream_close = Curl_cf_ngtcp2_cb_h3_stream_close,
        .recv_data = Curl_cf_ngtcp2_cb_h3_recv_data,
        .deferred_consume = Curl_cf_ngtcp2_cb_h3_deferred_consume,
        .begin_headers = Curl_cf_ngtcp2_cb_h3_begin_headers,
        .recv_header = Curl_cf_ngtcp2_cb_h3_recv_header,
        .end_headers = Curl_cf_ngtcp2_cb_h3_end_headers,
        .begin_trailers = null,
        .recv_trailer = Curl_cf_ngtcp2_cb_h3_recv_header,
        .end_trailers = null,
        .stop_sending = Curl_cf_ngtcp2_cb_h3_stop_sending,
        .end_stream = Curl_cf_ngtcp2_cb_h3_end_stream,
        .reset_stream = Curl_cf_ngtcp2_cb_h3_reset_stream,
    },
    .ng_settings = cf_ngtcp2_ng_settings,
    .h3_settings = cf_ngtcp2_h3_settings,
} else .{
    .q_cbs = .{},
    .h3_cbs = .{},
};

fn cf_ngtcp2_adjust_pollset(
    cf: *CurlCfilter,
    data: ?*CurlEasy,
    ps_opt: ?*EasyPollset,
) callconv(.c) CURLcode {
    const ps = ps_opt orelse return CURLE_OK;
    const ctx = cfToNgtcp2Ctx(cf) orelse return CURLE_OK;
    if (ctx.qconn == null) {
        return Curl_conn_cf_adjust_pollset(cf.next, data, ps);
    }

    var want_recv = false;
    var want_send = !io_buffers.Curl_bufq_is_empty(&ctx.q.sendbuf);
    if (!cf.isConnected()) {
        want_recv = true;
    } else if (h3StreamCtx(ctx, data)) |stream| {
        want_recv = true;
        if (data != null and Curl_xfer_req_want_send(data.?) and !io_buffers.Curl_bufq_is_empty(&stream.sendbuf)) {
            want_send = true;
        }
    } else if (!Curl_uint32_bset_empty(&ctx.active_streams)) {
        want_recv = true;
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

fn cf_ngtcp2_data_pending(
    cf: *CurlCfilter,
    data: ?*const CurlEasy,
) callconv(.c) bool {
    _ = cf;
    _ = data;
    return false;
}

fn cf_ngtcp2_recv(
    cf: *CurlCfilter,
    data: ?*CurlEasy,
    buf: [*]u8,
    len: usize,
    pnread: *usize,
) callconv(.c) CURLcode {
    _ = buf;
    _ = len;
    pnread.* = 0;
    const ctx = cfToNgtcp2Ctx(cf) orelse return CURLE_RECV_ERROR;

    var save: CfCallData = undefined;
    cfDataSave(&save, &ctx.call_data, data);
    defer cfDataRestore(&ctx.call_data, save);

    const stream = h3StreamCtx(ctx, data) orelse return CURLE_RECV_ERROR;
    var pktx: PktIoCtx = undefined;
    Curl_cf_ngtcp2_io_ctx_init(&pktx, cf, data, ctx);

    var result = report_consumed_data(cf, data, ctx, stream);
    if (result != CURLE_OK) return result;

    result = Curl_cf_ngtcp2_progress_ingress(cf, data, ctx, null);
    if (result != CURLE_OK) return result;

    if (stream.xfer_result != CURLE_OK) {
        Curl_cf_ngtcp2_h3_stream_close(cf, data, ctx, stream);
        return stream.xfer_result;
    }

    if (stream.closed) {
        if (stream.reset) {
            if (stream.status_code != -1 and !stream.resp_hds_complete) {
                if (data != null and Curl_xfer_is_eos_written(data.?)) {
                    return CURLE_OK;
                }
            }
            return CURLE_HTTP3;
        }
        return CURLE_OK;
    }

    result = progress_egress(cf, data, ctx, &pktx);
    if (result == CURLE_AGAIN) {
        result = CURLE_OK;
    }
    return if (result != CURLE_OK) result else CURLE_AGAIN;
}

fn cb_h3_readfunction(
    conn: *nghttp3_conn,
    stream_id: i64,
    vec: [*]nghttp3_vec,
    veccnt: usize,
    pflags: *u32,
    user_data: ?*anyopaque,
    stream_user_data: ?*anyopaque,
) callconv(.c) ngtcp2_ssize {
    _ = conn;
    _ = stream_user_data;
    const ctx: *CfNgtcp2Ctx = @ptrCast(@alignCast(user_data orelse return NGHTTP3_ERR_CALLBACK_FAILURE));
    const sdata = Curl_cf_ngtcp2_get_xfer(ctx, stream_id) orelse return NGHTTP3_ERR_CALLBACK_FAILURE;
    const stream = h3StreamCtx(ctx, sdata) orelse return NGHTTP3_ERR_CALLBACK_FAILURE;

    var nwritten: usize = 0;
    var nvecs: usize = 0;
    if (stream.sendbuf_len_in_flight < io_buffers.Curl_bufq_len(&stream.sendbuf)) {
        while (nvecs < veccnt) {
            var chunk_ptr: ?[*]const u8 = null;
            var chunk_len: usize = 0;
            if (!io_buffers.Curl_bufq_peek_at(&stream.sendbuf, stream.sendbuf_len_in_flight, &chunk_ptr, &chunk_len))
                break;
            vec[nvecs].base = @constCast(chunk_ptr);
            vec[nvecs].len = chunk_len;
            stream.sendbuf_len_in_flight += chunk_len;
            nwritten += chunk_len;
            nvecs += 1;
        }
    }

    if (nwritten > 0 and stream.upload_left != -1) {
        stream.upload_left -= @intCast(nwritten);
    }

    pflags.* = NGHTTP3_DATA_FLAG_NONE;
    if (stream.upload_left == 0 or (stream.send_closed and stream.sendbuf_len_in_flight == io_buffers.Curl_bufq_len(&stream.sendbuf))) {
        pflags.* = NGHTTP3_DATA_FLAG_EOF;
        stream.send_closed = true;
    } else if (nwritten == 0) {
        return NGHTTP3_ERR_WOULDBLOCK;
    }

    return @intCast(nvecs);
}

fn h3_stream_open(
    cf: *CurlCfilter,
    data: ?*CurlEasy,
    buf: [*]const u8,
    len: usize,
    eos: bool,
    pnwritten: *usize,
) CURLcode {
    pnwritten.* = 0;
    if (comptime !use_ngtcp2) return CURLE_NOT_BUILT_IN;
    const ctx = cfToNgtcp2Ctx(cf) orelse return CURLE_SEND_ERROR;
    const qconn = ctx.qconn orelse return CURLE_SEND_ERROR;
    const h3conn = ctx.h3conn orelse return CURLE_SEND_ERROR;

    var stream: ?*H3StreamCtx = null;
    var result = Curl_cf_ngtcp2_h3_stream_setup(cf, data, ctx, &stream);
    if (result != CURLE_OK) return result;
    const s = stream.?;

    result = http1_options.Curl_h1_req_parse_read(&s.h1, buf, len, null, null, 0, pnwritten);
    if (result != CURLE_OK) {
        return result;
    }
    if (s.h1.done == 0) {
        return CURLE_OK;
    }

    const req = s.h1.req orelse return CURLE_SEND_ERROR;
    var h2_headers: dynhds = undefined;
    io_buffers.Curl_dynhds_init(&h2_headers, 0, 1024 * 1024);
    defer io_buffers.Curl_dynhds_free(&h2_headers);

    result = Curl_http_req_to_h2(&h2_headers, req, data);
    if (result != CURLE_OK) return result;

    const nheader = io_buffers.Curl_dynhds_count(&h2_headers);
    const nva_raw = mem.calloc(nheader, @sizeOf(nghttp3_nv)) orelse return CURLE_OUT_OF_MEMORY;
    defer mem.free(nva_raw);
    const nva: [*]nghttp3_nv = @ptrCast(@alignCast(nva_raw));

    var i: usize = 0;
    while (i < nheader) : (i += 1) {
        const e = io_buffers.Curl_dynhds_getn(&h2_headers, i) orelse return CURLE_INTERNAL_ERROR;
        nva[i] = .{
            .name = e.name,
            .namelen = e.namelen,
            .value = e.value,
            .valuelen = e.valuelen,
            .flags = NGHTTP3_NV_FLAG_NONE,
        };
    }

    var rc = ngtcp2_c.ngtcp2_conn_open_bidi_stream(qconn, &s.id, data);
    if (rc != 0) {
        Curl_failf(data, "QUIC: ngtcp2_conn_open_bidi_stream failed: %s", ngtcp2_c.ngtcp2_strerror(rc));
        return CURLE_SEND_ERROR;
    }

    const rest_len = len - pnwritten.*;
    const send_fin = eos and (rest_len == 0);
    s.upload_left = if (send_fin) 0 else if (eos) @intCast(rest_len) else -1;
    s.send_closed = send_fin;

    var dr = nghttp3_data_reader{ .read_data = cb_h3_readfunction };
    const dr_ptr: ?*const nghttp3_data_reader = if (!s.send_closed) &dr else null;

    rc = ngtcp2_c.nghttp3_conn_submit_request(h3conn, s.id, nva, nheader, dr_ptr, data);
    if (rc != 0) {
        return CURLE_SEND_ERROR;
    }

    if (data) |d| {
        _ = Curl_uint32_bset_add(&ctx.active_streams, easyMid(d));
    }
    return CURLE_OK;
}

fn cf_ngtcp2_send(
    cf: *CurlCfilter,
    data: ?*CurlEasy,
    buf_raw: ?*const anyopaque,
    len: usize,
    eos: bool,
    pnwritten: *usize,
) callconv(.c) CURLcode {
    pnwritten.* = 0;
    if (comptime !use_ngtcp2) return CURLE_NOT_BUILT_IN;
    const buf: [*]const u8 = @ptrCast(buf_raw orelse return CURLE_BAD_FUNCTION_ARGUMENT);
    const ctx = cfToNgtcp2Ctx(cf) orelse return CURLE_SEND_ERROR;

    var save: CfCallData = undefined;
    cfDataSave(&save, &ctx.call_data, data);
    defer cfDataRestore(&ctx.call_data, save);

    var pktx: PktIoCtx = undefined;
    Curl_cf_ngtcp2_io_ctx_init(&pktx, cf, data, ctx);

    var result = Curl_cf_ngtcp2_progress_ingress(cf, data, ctx, null);
    if (result != CURLE_OK) return result;

    var stream = h3StreamCtx(ctx, data);
    if (stream == null) {
        result = Curl_cf_ngtcp2_h3_stream_setup(cf, data, ctx, &stream);
        if (result != CURLE_OK) return result;
    }
    var s = stream.?;

    if (s.h1.done == 0) {
        var hdr_bytes: usize = 0;
        result = h3_stream_open(cf, data, buf, len, eos, &hdr_bytes);
        if (result != CURLE_OK) return result;
        pnwritten.* += hdr_bytes;
        if (s.h1.done == 0) {
            result = progress_egress(cf, data, ctx, &pktx);
            if (result == CURLE_AGAIN) result = CURLE_OK;
            return result;
        }
        if (hdr_bytes >= len) {
            if (eos and !s.send_closed) {
                s.send_closed = true;
                s.upload_left = 0;
                if (ctx.h3conn) |h3conn| {
                    _ = ngtcp2_c.nghttp3_conn_resume_stream(h3conn, s.id);
                }
            }
            result = progress_egress(cf, data, ctx, &pktx);
            if (result == CURLE_AGAIN) result = CURLE_OK;
            return result;
        }
    }

    if (s.xfer_result != CURLE_OK) {
        Curl_cf_ngtcp2_h3_stream_close(cf, data, ctx, s);
        return s.xfer_result;
    }
    if (s.closed) {
        return CURLE_HTTP3;
    }

    const body_ptr = buf + pnwritten.*;
    const body_len = len - pnwritten.*;
    if (body_len > 0) {
        var nbody: usize = 0;
        result = io_buffers.Curl_bufq_write(&s.sendbuf, body_ptr, body_len, &nbody);
        if (result != CURLE_OK and result != CURLE_AGAIN) {
            return result;
        }
        if (nbody > 0) {
            pnwritten.* += nbody;
            if (s.upload_left > 0) {
                s.upload_left -= @min(s.upload_left, @as(curl_off_t, @intCast(nbody)));
                if (s.upload_left == 0) {
                    s.send_closed = true;
                }
            }
            if (eos and nbody == body_len) {
                s.send_closed = true;
                s.upload_left = 0;
            }
            if (ctx.h3conn) |h3conn| {
                _ = ngtcp2_c.nghttp3_conn_resume_stream(h3conn, s.id);
            }
        }
    } else if (eos and !s.send_closed) {
        s.send_closed = true;
        s.upload_left = 0;
        if (ctx.h3conn) |h3conn| {
            _ = ngtcp2_c.nghttp3_conn_resume_stream(h3conn, s.id);
        }
    }

    result = progress_egress(cf, data, ctx, &pktx);
    if (result == CURLE_AGAIN) result = CURLE_OK;
    if (result != CURLE_OK) return result;

    if (pnwritten.* == 0) {
        return CURLE_AGAIN;
    }
    return CURLE_OK;
}

fn cf_ngtcp2_cntrl(
    cf: *CurlCfilter,
    data: ?*CurlEasy,
    event: c_int,
    arg1: c_int,
    arg2: ?*anyopaque,
) callconv(.c) CURLcode {
    const ctx = cfToNgtcp2Ctx(cf) orelse return CURLE_OK;
    var save: CfCallData = undefined;
    cfDataSave(&save, &ctx.call_data, data);
    defer cfDataRestore(&ctx.call_data, save);
    return Curl_cf_ngtcp2_cmn_cntrl(cf, data, ctx, event, arg1, arg2);
}

fn cf_ngtcp2_is_alive(
    cf: *CurlCfilter,
    data: ?*CurlEasy,
    input_pending: *bool,
) callconv(.c) bool {
    const ctx = cfToNgtcp2Ctx(cf) orelse return false;
    var save: CfCallData = undefined;
    cfDataSave(&save, &ctx.call_data, data);
    defer cfDataRestore(&ctx.call_data, save);
    return Curl_cf_ngtcp2_cmn_conn_is_alive(cf, data, ctx, input_pending);
}

fn cf_ngtcp2_connect(
    cf: *CurlCfilter,
    data: ?*CurlEasy,
    done: *bool,
) callconv(.c) CURLcode {
    const ctx = cfToNgtcp2Ctx(cf) orelse return CURLE_FAILED_INIT;
    const result = Curl_cf_ngtcp2_cmn_connect(cf, data, ctx, done);
    if (result == CURLE_OK and done.*) {
        cf.setConnected(true);
        if (cf.conn) |conn| {
            Curl_http_acc_conn_set_httpversion_seen(conn, 30);
            Curl_conn_set_multiplex(conn);
        }
        multiConnChanged(data);
    }
    return result;
}

fn cf_ngtcp2_destroy(
    cf: *CurlCfilter,
    data: ?*CurlEasy,
) callconv(.c) void {
    const ctx = cfToNgtcp2Ctx(cf) orelse return;
    {
        var save: CfCallData = undefined;
        cfDataSave(&save, &ctx.call_data, data);
        defer cfDataRestore(&ctx.call_data, save);
        Curl_cf_ngtcp2_ctx_cleanup(ctx);
    }
    mem.freeTyped(ctx);
    cf.ctx = null;
}

fn cf_ngtcp2_shutdown(
    cf: *CurlCfilter,
    data: ?*CurlEasy,
    done: *bool,
) callconv(.c) CURLcode {
    const ctx = cfToNgtcp2Ctx(cf) orelse {
        done.* = true;
        return CURLE_OK;
    };
    return Curl_cf_ngtcp2_cmn_shutdown(cf, data, ctx, done);
}

fn cf_ngtcp2_query(
    cf: *CurlCfilter,
    data: ?*CurlEasy,
    query: c_int,
    pres1: ?*c_int,
    pres2: ?*anyopaque,
) callconv(.c) CURLcode {
    const ctx = cfToNgtcp2Ctx(cf) orelse return Curl_cf_def_query(cf, data, query, pres1, pres2);
    var save: CfCallData = undefined;
    cfDataSave(&save, &ctx.call_data, data);
    defer cfDataRestore(&ctx.call_data, save);
    return Curl_cf_ngtcp2_cmn_query(cf, data, ctx, query, pres1, pres2);
}

pub var Curl_cft_http3 = CurlCftype{
    .name = "HTTP/3",
    .flags = CF_TYPE_IP_CONNECT | CF_TYPE_SSL | CF_TYPE_MULTIPLEX | CF_TYPE_HTTP,
    .log_level = CURL_LOG_LVL_NONE,
    .destroy = cf_ngtcp2_destroy,
    .do_connect = cf_ngtcp2_connect,
    .do_shutdown = cf_ngtcp2_shutdown,
    .adjust_pollset = cf_ngtcp2_adjust_pollset,
    .has_data_pending = cf_ngtcp2_data_pending,
    .do_send = cf_ngtcp2_send,
    .do_recv = cf_ngtcp2_recv,
    .cntrl = cf_ngtcp2_cntrl,
    .is_alive = cf_ngtcp2_is_alive,
    .keep_alive = Curl_cf_def_conn_keep_alive,
    .query = cf_ngtcp2_query,
};

pub fn Curl_cf_ngtcp2_insert_after(
    cf_at: *CurlCfilter,
    origin: ?*CurlPeer,
    peer: ?*CurlPeer,
    pcf: *?*CurlCfilter,
) callconv(.c) CURLcode {
    pcf.* = null;
    if (comptime !use_ngtcp2) return CURLE_NOT_BUILT_IN;

    const raw = mem.calloc(1, @sizeOf(CfNgtcp2Ctx)) orelse return CURLE_OUT_OF_MEMORY;
    const ctx: *CfNgtcp2Ctx = @ptrCast(@alignCast(raw));
    var result = Curl_cf_ngtcp2_ctx_init(ctx, origin, peer, &cf_ngtcp2_cbs);
    if (result != CURLE_OK) {
        mem.freeTyped(ctx);
        return result;
    }

    var cf: ?*CurlCfilter = null;
    result = Curl_cf_create(&cf, &Curl_cft_http3, ctx);
    if (result != CURLE_OK) {
        Curl_cf_ngtcp2_ctx_cleanup(ctx);
        mem.freeTyped(ctx);
        return result;
    }

    Curl_conn_cf_insert_after(cf_at, cf.?);
    pcf.* = cf;
    return CURLE_OK;
}

pub fn Curl_cf_ngtcp2_create(
    pcf: *?*CurlCfilter,
    data: ?*CurlEasy,
    origin: ?*CurlPeer,
    peer: ?*CurlPeer,
    conn: ?*ConnectData,
    addr: ?*CurlSockaddrEx,
) callconv(.c) CURLcode {
    pcf.* = null;
    if (comptime !use_ngtcp2) return CURLE_NOT_BUILT_IN;

    const raw = mem.calloc(1, @sizeOf(CfNgtcp2Ctx)) orelse return CURLE_OUT_OF_MEMORY;
    const ctx: *CfNgtcp2Ctx = @ptrCast(@alignCast(raw));
    var result = Curl_cf_ngtcp2_ctx_init(ctx, origin, peer, &cf_ngtcp2_cbs);
    if (result != CURLE_OK) {
        mem.freeTyped(ctx);
        return result;
    }

    var cf_ngtcp2: ?*CurlCfilter = null;
    result = Curl_cf_create(&cf_ngtcp2, &Curl_cft_http3, ctx);
    if (result != CURLE_OK or cf_ngtcp2 == null) {
        Curl_cf_ngtcp2_ctx_cleanup(ctx);
        mem.freeTyped(ctx);
        return result;
    }
    cf_ngtcp2.?.conn = conn;

    var cf_udp: ?*CurlCfilter = null;
    result = Curl_cf_udp_create(&cf_udp, data, origin, peer, TRNSPRT_QUIC, conn, addr, null, TRNSPRT_QUIC);
    if (result != CURLE_OK or cf_udp == null) {
        cf_ngtcp2_destroy(cf_ngtcp2.?, data);
        mem.freeTyped(cf_ngtcp2);
        return result;
    }

    cf_udp.?.conn = cf_ngtcp2.?.conn;
    cf_udp.?.sockindex = cf_ngtcp2.?.sockindex;
    cf_ngtcp2.?.next = cf_udp;
    pcf.* = cf_ngtcp2;
    return CURLE_OK;
}

// ============================================================================
// 5. HTTP/3 MASQUE Proxy Filter: Curl_cft_h3_proxy (lib/vquic/cf-ngtcp2-proxy.c)
// ============================================================================

const PROXY_H3_TUNNEL_RX_WIN: usize = H3_STREAM_WINDOW_SIZE;
const PROXY_H3_TUNNEL_RECV_CHUNKS: usize = PROXY_H3_TUNNEL_RX_WIN / H3_STREAM_CHUNK_SIZE;

pub const H3TunnelState = enum(c_uint) {
    H3_TUNNEL_INIT = 0,
    H3_TUNNEL_CONNECT = 1,
    H3_TUNNEL_RESPONSE = 2,
    H3_TUNNEL_ESTABLISHED = 3,
    H3_TUNNEL_FAILED = 4,
};

pub const H3TunnelStream = struct {
    dest: ?*CurlPeer = null,
    resp: ?*http_resp = null,
    recvbuf: Bufq = std.mem.zeroes(Bufq),
    authority: ?[*:0]u8 = null,
    stream: ?*H3StreamCtx = null,
    state: H3TunnelState = .H3_TUNNEL_INIT,
    udp: bool = false,
    has_final_response: bool = false,
    closed: bool = false,
};

pub const CfNgtcp2ProxyCtx = struct {
    q: CfNgtcp2Ctx = .{},
    peer: ?*CurlPeer = null,
    ts: H3TunnelStream = .{},
    bufcp: BufcPool = std.mem.zeroes(BufcPool),
    max_stream_window: usize = 0,
    max_idle_ms: u64 = 0,
    initialized: bool = false,
};

fn cfToProxyCtx(cf: *CurlCfilter) ?*CfNgtcp2ProxyCtx {
    const raw = cf.ctx orelse return null;
    return @ptrCast(@alignCast(raw));
}

fn qToProxyCtx(q: *CfNgtcp2Ctx) *CfNgtcp2ProxyCtx {
    return @fieldParentPtr("q", q);
}

fn h3_tunnel_stream_init(ts: *H3TunnelStream, dest_opt: ?*CurlPeer, udp: bool) CURLcode {
    const dest = dest_opt orelse return CURLE_FAILED_INIT;
    ts.state = .H3_TUNNEL_INIT;
    Curl_peer_link(&ts.dest, dest);
    io_buffers.Curl_bufq_init2(&ts.recvbuf, H3_STREAM_CHUNK_SIZE, PROXY_H3_TUNNEL_RECV_CHUNKS, BUFQ_OPT_SOFT_LIMIT);
    ts.udp = udp;
    const lbr: [*:0]const u8 = if (dest.ipv6()) "[" else "";
    const rbr: [*:0]const u8 = if (dest.ipv6()) "]" else "";
    ts.authority = curl_maprintf("%s%s%s:%u", lbr, dest.hostname, rbr, @as(c_uint, dest.port));
    if (ts.authority == null) {
        return CURLE_OUT_OF_MEMORY;
    }
    return CURLE_OK;
}

fn h3_tunnel_stream_reset(ts: *H3TunnelStream) void {
    io_buffers.Curl_bufq_reset(&ts.recvbuf);
    Curl_http_resp_free(ts.resp);
    ts.resp = null;
    ts.stream = null;
    ts.has_final_response = false;
    ts.closed = false;
    ts.state = .H3_TUNNEL_INIT;
}

fn h3_tunnel_stream_cleanup(ts: *H3TunnelStream) void {
    Curl_peer_unlink(&ts.dest);
    io_buffers.Curl_bufq_free(&ts.recvbuf);
    Curl_http_resp_free(ts.resp);
    ts.resp = null;
    mem.free(ts.authority);
    ts.authority = null;
    ts.stream = null;
    ts.state = .H3_TUNNEL_INIT;
}

fn h3_tunnel_go_state(
    cf: *CurlCfilter,
    ts: *H3TunnelStream,
    new_state: H3TunnelState,
    data: ?*CurlEasy,
) void {
    _ = cf;
    if (ts.state == new_state) return;

    if (ts.state == .H3_TUNNEL_CONNECT) {
        Curl_http_acc_req_set_ignorebody(data, false);
    }

    switch (new_state) {
        .H3_TUNNEL_INIT => {
            h3_tunnel_stream_reset(ts);
        },
        .H3_TUNNEL_CONNECT => {
            ts.state = .H3_TUNNEL_CONNECT;
        },
        .H3_TUNNEL_RESPONSE => {
            ts.state = .H3_TUNNEL_RESPONSE;
        },
        .H3_TUNNEL_ESTABLISHED => {
            Curl_proxy_start_connect_auth(data);
            ts.state = .H3_TUNNEL_ESTABLISHED;
            Curl_proxy_clear_hd_proxy_auth(data);
        },
        .H3_TUNNEL_FAILED => {
            ts.state = .H3_TUNNEL_FAILED;
            Curl_proxy_clear_hd_proxy_auth(data);
        },
    }
}

fn cf_ngtcp2_proxy_cb_recv_datagram(
    tconn: *ngtcp2_conn,
    flags: u32,
    buf: [*]const u8,
    buflen: usize,
    user_data: ?*anyopaque,
) callconv(.c) c_int {
    _ = tconn;
    _ = flags;
    const q: *CfNgtcp2Ctx = @ptrCast(@alignCast(user_data orelse return 0));
    const ctx = qToProxyCtx(q);
    if (!ctx.ts.udp or buflen < 2) return 0;
    // RFC 9298 / RFC 9297 Quarter Stream ID + Context ID (0)
    const stream = ctx.ts.stream orelse return 0;
    const qsid: u64 = @intCast(@divTrunc(stream.id, 4));
    // Decode 1-byte varint Quarter Stream ID + 1-byte Context ID 0
    if (qsid < 64 and buf[0] == @as(u8, @intCast(qsid)) and buf[1] == 0) {
        const payload = buf + 2;
        const payload_len = buflen - 2;
        if (payload_len > 0) {
            var nwritten: usize = 0;
            _ = io_buffers.Curl_bufq_write(&ctx.ts.recvbuf, payload, payload_len, &nwritten);
        }
    }
    return 0;
}

fn cf_ngtcp2_proxy_cb_h3_recv_data(
    conn: *nghttp3_conn,
    stream_id: i64,
    buf: [*]const u8,
    buflen: usize,
    user_data: ?*anyopaque,
    stream_user_data: ?*anyopaque,
) callconv(.c) c_int {
    _ = conn;
    _ = stream_id;
    _ = stream_user_data;
    const q: *CfNgtcp2Ctx = @ptrCast(@alignCast(user_data orelse return NGHTTP3_ERR_CALLBACK_FAILURE));
    const ctx = qToProxyCtx(q);
    var nwritten: usize = 0;
    const result = io_buffers.Curl_bufq_write(&ctx.ts.recvbuf, buf, buflen, &nwritten);
    if (result != CURLE_OK and result != CURLE_AGAIN) {
        return NGHTTP3_ERR_CALLBACK_FAILURE;
    }
    return 0;
}

fn cf_ngtcp2_proxy_cb_h3_recv_header(
    conn: *nghttp3_conn,
    stream_id: i64,
    token: i32,
    name: *nghttp3_rcbuf,
    value: *nghttp3_rcbuf,
    flags: u8,
    user_data: ?*anyopaque,
    stream_user_data: ?*anyopaque,
) callconv(.c) c_int {
    _ = conn;
    _ = stream_id;
    _ = token;
    _ = flags;
    _ = stream_user_data;
    if (comptime !use_ngtcp2) return NGHTTP3_ERR_CALLBACK_FAILURE;
    const q: *CfNgtcp2Ctx = @ptrCast(@alignCast(user_data orelse return NGHTTP3_ERR_CALLBACK_FAILURE));
    const ctx = qToProxyCtx(q);
    if (ctx.ts.has_final_response) return 0;

    const vname = ngtcp2_c.nghttp3_rcbuf_get_buf(name);
    const vval = ngtcp2_c.nghttp3_rcbuf_get_buf(value);

    if (vname.len == 7 and vname.base != null and std.mem.eql(u8, vname.base.?[0..7], ":status")) {
        var status: i32 = 0;
        var result = Curl_http_decode_status(&status, vval.base.?, vval.len);
        if (result == CURLE_OK) {
            Curl_http_resp_free(ctx.ts.resp);
            ctx.ts.resp = null;
            result = Curl_http_resp_make(&ctx.ts.resp, @intCast(status), null);
        }
        if (result != CURLE_OK) return NGHTTP3_ERR_CALLBACK_FAILURE;
    } else if (ctx.ts.resp) |resp| {
        const result = io_buffers.Curl_dynhds_add(
            &resp.headers,
            vname.base.?,
            vname.len,
            vval.base.?,
            vval.len,
        );
        if (result != CURLE_OK) return NGHTTP3_ERR_CALLBACK_FAILURE;
    } else {
        return NGHTTP3_ERR_CALLBACK_FAILURE;
    }
    return 0;
}

fn cf_ngtcp2_proxy_cb_h3_end_headers(
    conn: *nghttp3_conn,
    stream_id: i64,
    fin: c_int,
    user_data: ?*anyopaque,
    stream_user_data: ?*anyopaque,
) callconv(.c) c_int {
    _ = conn;
    _ = stream_id;
    _ = stream_user_data;
    const q: *CfNgtcp2Ctx = @ptrCast(@alignCast(user_data orelse return NGHTTP3_ERR_CALLBACK_FAILURE));
    const ctx = qToProxyCtx(q);
    const resp = ctx.ts.resp orelse return NGHTTP3_ERR_CALLBACK_FAILURE;
    if (resp.status >= 200) {
        ctx.ts.has_final_response = true;
    }
    if (fin != 0) {
        ctx.ts.closed = true;
    }
    return 0;
}

fn cf_ngtcp2_proxy_cb_h3_stream_close(
    conn: *nghttp3_conn,
    stream_id: i64,
    app_error_code: u64,
    user_data: ?*anyopaque,
    stream_user_data: ?*anyopaque,
) callconv(.c) c_int {
    const q: *CfNgtcp2Ctx = @ptrCast(@alignCast(user_data orelse return 0));
    const ctx = qToProxyCtx(q);
    if (ctx.ts.stream) |s| {
        if (s.id == stream_id) {
            ctx.ts.closed = true;
        }
    }
    return Curl_cf_ngtcp2_cb_h3_stream_close(conn, stream_id, app_error_code, user_data, stream_user_data);
}

fn cf_ngtcp2_proxy_ng_settings(
    cf: *CurlCfilter,
    data: ?*CurlEasy,
    ctx: *CfNgtcp2Ctx,
    settings: *ngtcp2_settings,
    params: *ngtcp2_transport_params,
) callconv(.c) CURLcode {
    const result = cf_ngtcp2_ng_settings(cf, data, ctx, settings, params);
    if (result != CURLE_OK) return result;
    params.max_datagram_frame_size = vquic_core.MAX_UDP_PAYLOAD_SIZE;
    return CURLE_OK;
}

fn cf_ngtcp2_proxy_h3_settings(
    cf: *CurlCfilter,
    data: ?*CurlEasy,
    ctx: *CfNgtcp2Ctx,
    settings: *nghttp3_settings,
) callconv(.c) CURLcode {
    _ = cf;
    _ = data;
    _ = ctx;
    settings.enable_connect_protocol = 1;
    settings.h3_datagram = 1;
    return CURLE_OK;
}

pub const cf_ngtcp2_proxy_cbs: CfNgtcp2Cbs = if (use_ngtcp2) .{
    .q_cbs = .{
        .client_initial = @ptrCast(&ngtcp2_c.ngtcp2_crypto_client_initial_cb),
        .recv_crypto_data = @ptrCast(&ngtcp2_c.ngtcp2_crypto_recv_crypto_data_cb),
        .handshake_completed = Curl_cf_ngtcp2_cb_handshake_completed,
        .encrypt = @ptrCast(&ngtcp2_c.ngtcp2_crypto_encrypt_cb),
        .decrypt = @ptrCast(&ngtcp2_c.ngtcp2_crypto_decrypt_cb),
        .hp_mask = @ptrCast(&ngtcp2_c.ngtcp2_crypto_hp_mask_cb),
        .recv_stream_data = Curl_cf_ngtcp2_cb_recv_stream_data,
        .acked_stream_data_offset = Curl_cf_ngtcp2_cb_acked_stream_data_offset,
        .stream_open = Curl_cf_ngtcp2_cb_stream_open,
        .stream_close = Curl_cf_ngtcp2_cb_stream_close,
        .recv_retry = @ptrCast(&ngtcp2_c.ngtcp2_crypto_recv_retry_cb),
        .extend_max_local_streams_bidi = Curl_cf_ngtcp2_cb_extend_max_local_streams_bidi,
        .rand = Curl_cf_ngtcp2_cb_rand,
        .get_new_connection_id = Curl_cf_ngtcp2_cb_get_new_connection_id,
        .remove_connection_id = Curl_cf_ngtcp2_cb_remove_connection_id,
        .update_key = @ptrCast(&ngtcp2_c.ngtcp2_crypto_update_key_cb),
        .stream_reset = Curl_cf_ngtcp2_cb_stream_reset,
        .delete_crypto_aead_ctx = @ptrCast(&ngtcp2_c.ngtcp2_crypto_delete_crypto_aead_ctx_cb),
        .delete_crypto_cipher_ctx = @ptrCast(&ngtcp2_c.ngtcp2_crypto_delete_crypto_cipher_ctx_cb),
        .recv_datagram = cf_ngtcp2_proxy_cb_recv_datagram,
        .get_path_challenge_data = @ptrCast(&ngtcp2_c.ngtcp2_crypto_get_path_challenge_data_cb),
        .stream_stop_sending = Curl_cf_ngtcp2_cb_stream_stop_sending,
        .version_negotiation = @ptrCast(&ngtcp2_c.ngtcp2_crypto_version_negotiation_cb),
        .recv_rx_key = Curl_cf_ngtcp2_cb_recv_rx_key,
        .recv_tx_key = Curl_cf_ngtcp2_cb_recv_tx_key,
    },
    .h3_cbs = .{
        .acked_stream_data = Curl_cf_ngtcp2_cb_h3_acked_stream_data,
        .stream_close = cf_ngtcp2_proxy_cb_h3_stream_close,
        .recv_data = cf_ngtcp2_proxy_cb_h3_recv_data,
        .deferred_consume = Curl_cf_ngtcp2_cb_h3_deferred_consume,
        .begin_headers = Curl_cf_ngtcp2_cb_h3_begin_headers,
        .recv_header = cf_ngtcp2_proxy_cb_h3_recv_header,
        .end_headers = cf_ngtcp2_proxy_cb_h3_end_headers,
        .begin_trailers = null,
        .recv_trailer = cf_ngtcp2_proxy_cb_h3_recv_header,
        .end_trailers = null,
        .stop_sending = Curl_cf_ngtcp2_cb_h3_stop_sending,
        .end_stream = Curl_cf_ngtcp2_cb_h3_end_stream,
        .reset_stream = Curl_cf_ngtcp2_cb_h3_reset_stream,
    },
    .ng_settings = cf_ngtcp2_proxy_ng_settings,
    .h3_settings = cf_ngtcp2_proxy_h3_settings,
} else .{
    .q_cbs = .{},
    .h3_cbs = .{},
};

fn proxy_h3_submit(
    cf: *CurlCfilter,
    data: *CurlEasy,
    ctx: *CfNgtcp2ProxyCtx,
    req: *httpreq,
) CURLcode {
    if (comptime !use_ngtcp2) return CURLE_NOT_BUILT_IN;
    const qconn = ctx.q.qconn orelse return CURLE_SEND_ERROR;
    const h3conn = ctx.q.h3conn orelse return CURLE_SEND_ERROR;

    var h2_headers: dynhds = undefined;
    io_buffers.Curl_dynhds_init(&h2_headers, 0, 1024 * 1024);
    defer io_buffers.Curl_dynhds_free(&h2_headers);

    var result = Curl_http_req_to_h2(&h2_headers, req, data);
    if (result != CURLE_OK) return result;

    const nheader = io_buffers.Curl_dynhds_count(&h2_headers);
    const nva_raw = mem.calloc(nheader, @sizeOf(nghttp3_nv)) orelse return CURLE_OUT_OF_MEMORY;
    defer mem.free(nva_raw);
    const nva: [*]nghttp3_nv = @ptrCast(@alignCast(nva_raw));

    var i: usize = 0;
    while (i < nheader) : (i += 1) {
        const e = io_buffers.Curl_dynhds_getn(&h2_headers, i) orelse return CURLE_INTERNAL_ERROR;
        nva[i] = .{
            .name = e.name,
            .namelen = e.namelen,
            .value = e.value,
            .valuelen = e.valuelen,
            .flags = NGHTTP3_NV_FLAG_NONE,
        };
    }

    result = Curl_cf_ngtcp2_h3_stream_setup(cf, data, &ctx.q, &ctx.ts.stream);
    if (result != CURLE_OK) return result;
    const stream = ctx.ts.stream.?;

    var rc = ngtcp2_c.ngtcp2_conn_open_bidi_stream(qconn, &stream.id, data);
    if (rc != 0) return CURLE_SEND_ERROR;

    var dr = nghttp3_data_reader{ .read_data = cb_h3_readfunction };
    rc = ngtcp2_c.nghttp3_conn_submit_request(h3conn, stream.id, nva, nheader, &dr, null);
    if (rc != 0) return CURLE_SEND_ERROR;

    return CURLE_OK;
}

fn submit_connect(
    cf: *CurlCfilter,
    data: *CurlEasy,
    ctx: *CfNgtcp2ProxyCtx,
) CURLcode {
    var req: ?*httpreq = null;
    defer if (req != null) Curl_http_req_free(req);

    var result = Curl_http_proxy_create_tunnel_request(
        &req,
        cf,
        data,
        ctx.peer,
        ctx.ts.dest,
        PROXY_HTTP_V3,
        ctx.ts.udp,
    );
    if (result == CURLE_OK) {
        result = Curl_creader_set_null(data);
    }
    if (result == CURLE_OK and req != null) {
        result = proxy_h3_submit(cf, data, ctx, req.?);
    }
    if (result != CURLE_OK) {
        Curl_failf(data, "Failed sending CONNECT to proxy");
    }
    return result;
}

fn inspect_response(
    cf: *CurlCfilter,
    data: *CurlEasy,
    ctx: *CfNgtcp2ProxyCtx,
) CURLcode {
    var res: proxy_inspect_result = .PROXY_INSPECT_OK;
    var result = Curl_http_proxy_inspect_tunnel_response(
        cf,
        data,
        ctx.ts.resp,
        ctx.ts.udp,
        &res,
    );
    if (result != CURLE_OK) return result;

    switch (res) {
        .PROXY_INSPECT_OK => {
            h3_tunnel_go_state(cf, &ctx.ts, .H3_TUNNEL_ESTABLISHED, data);
        },
        .PROXY_INSPECT_FAILED => {
            h3_tunnel_go_state(cf, &ctx.ts, .H3_TUNNEL_FAILED, data);
            result = CURLE_COULDNT_CONNECT;
        },
        .PROXY_INSPECT_AUTH_RETRY => {
            h3_tunnel_go_state(cf, &ctx.ts, .H3_TUNNEL_INIT, data);
        },
    }
    return result;
}

fn h3_connect_tunnel(
    cf: *CurlCfilter,
    data: *CurlEasy,
    ctx: *CfNgtcp2ProxyCtx,
) CURLcode {
    var result: CURLcode = CURLE_OK;
    while (true) {
        switch (ctx.ts.state) {
            .H3_TUNNEL_INIT => {
                result = submit_connect(cf, data, ctx);
                if (result != CURLE_OK) {
                    h3_tunnel_go_state(cf, &ctx.ts, .H3_TUNNEL_FAILED, data);
                    break;
                }
                h3_tunnel_go_state(cf, &ctx.ts, .H3_TUNNEL_CONNECT, data);
                continue;
            },
            .H3_TUNNEL_CONNECT => {
                var pktx: PktIoCtx = undefined;
                Curl_cf_ngtcp2_io_ctx_init(&pktx, cf, data, &ctx.q);
                result = Curl_cf_ngtcp2_progress_ingress(cf, data, &ctx.q, null);
                if (result == CURLE_OK) {
                    result = progress_egress(cf, data, &ctx.q, &pktx);
                    if (result == CURLE_AGAIN) result = CURLE_OK;
                }
                if (result != CURLE_OK and result != CURLE_AGAIN) {
                    h3_tunnel_go_state(cf, &ctx.ts, .H3_TUNNEL_FAILED, data);
                    break;
                }
                if (ctx.ts.has_final_response) {
                    h3_tunnel_go_state(cf, &ctx.ts, .H3_TUNNEL_RESPONSE, data);
                    continue;
                }
                result = CURLE_OK;
                break;
            },
            .H3_TUNNEL_RESPONSE => {
                result = inspect_response(cf, data, ctx);
                if (result != CURLE_OK) break;
                continue;
            },
            .H3_TUNNEL_ESTABLISHED => {
                return CURLE_OK;
            },
            .H3_TUNNEL_FAILED => {
                return CURLE_COULDNT_CONNECT;
            },
        }
    }
    return result;
}

fn cf_ngtcp2_proxy_connect(
    cf: *CurlCfilter,
    data: ?*CurlEasy,
    done: *bool,
) callconv(.c) CURLcode {
    if (cf.isConnected()) {
        done.* = true;
        return CURLE_OK;
    }
    const ctx = cfToProxyCtx(cf) orelse return CURLE_FAILED_INIT;
    const d = data orelse return CURLE_BAD_FUNCTION_ARGUMENT;

    var save: CfCallData = undefined;
    cfDataSave(&save, &ctx.q.call_data, d);
    defer cfDataRestore(&ctx.q.call_data, save);

    done.* = false;
    var qdone = false;
    var result = Curl_cf_ngtcp2_cmn_connect(cf, d, &ctx.q, &qdone);
    if (result != CURLE_OK or !qdone) {
        return result;
    }

    result = h3_connect_tunnel(cf, d, ctx);
    if (result == CURLE_OK and ctx.ts.state == .H3_TUNNEL_ESTABLISHED) {
        var use_capsule = ctx.ts.udp;
        if (comptime use_ngtcp2) {
            if (use_capsule and ctx.q.qconn != null) {
                const rparams = ngtcp2_c.ngtcp2_conn_get_remote_transport_params(ctx.q.qconn.?);
                if (rparams.max_datagram_frame_size > 0) {
                    use_capsule = false;
                }
            }
        }
        if (use_capsule) {
            result = Curl_cf_capsule_insert_after(cf, d);
            if (result != CURLE_OK) return result;
        }
        cf.setConnected(true);
        done.* = true;
        Curl_proxy_req_soft_reset(d);
    }
    return result;
}

fn cf_ngtcp2_proxy_ctx_cleanup(ctx: *CfNgtcp2ProxyCtx) void {
    if (ctx.initialized) {
        h3_tunnel_stream_cleanup(&ctx.ts);
    }
    Curl_cf_ngtcp2_ctx_cleanup(&ctx.q);
    if (ctx.initialized) {
        io_buffers.Curl_bufcp_free(&ctx.bufcp);
        Curl_peer_unlink(&ctx.peer);
        ctx.initialized = false;
    }
}

fn cf_ngtcp2_proxy_destroy(
    cf: *CurlCfilter,
    data: ?*CurlEasy,
) callconv(.c) void {
    const ctx = cfToProxyCtx(cf) orelse return;
    {
        var save: CfCallData = undefined;
        cfDataSave(&save, &ctx.q.call_data, data);
        defer cfDataRestore(&ctx.q.call_data, save);
        cf_ngtcp2_proxy_ctx_cleanup(ctx);
    }
    mem.freeTyped(ctx);
    cf.ctx = null;
}

fn cf_ngtcp2_proxy_shutdown(
    cf: *CurlCfilter,
    data: ?*CurlEasy,
    done: *bool,
) callconv(.c) CURLcode {
    const ctx = cfToProxyCtx(cf) orelse {
        done.* = true;
        return CURLE_OK;
    };
    return Curl_cf_ngtcp2_cmn_shutdown(cf, data, &ctx.q, done);
}

fn cf_ngtcp2_proxy_adjust_pollset(
    cf: *CurlCfilter,
    data: ?*CurlEasy,
    ps_opt: ?*EasyPollset,
) callconv(.c) CURLcode {
    const ps = ps_opt orelse return CURLE_OK;
    const ctx = cfToProxyCtx(cf) orelse return CURLE_OK;
    if (ctx.q.qconn == null) {
        return Curl_conn_cf_adjust_pollset(cf.next, data, ps);
    }

    var want_recv = !cf.isConnected();
    var want_send = !io_buffers.Curl_bufq_is_empty(&ctx.q.q.sendbuf);
    if (ctx.ts.stream) |stream| {
        want_recv = true;
        if (!io_buffers.Curl_bufq_is_empty(&stream.sendbuf)) {
            want_send = true;
        }
    }

    if (want_recv or want_send) {
        var sock: curl_socket_t = ctx.q.q.sockfd;
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

fn cf_ngtcp2_proxy_data_pending(
    cf: *CurlCfilter,
    data: ?*const CurlEasy,
) callconv(.c) bool {
    _ = data;
    const ctx = cfToProxyCtx(cf) orelse return false;
    return !io_buffers.Curl_bufq_is_empty(&ctx.ts.recvbuf);
}

fn cf_ngtcp2_proxy_send(
    cf: *CurlCfilter,
    data: ?*CurlEasy,
    buf_raw: ?*const anyopaque,
    len: usize,
    eos: bool,
    pnwritten: *usize,
) callconv(.c) CURLcode {
    pnwritten.* = 0;
    if (comptime !use_ngtcp2) return CURLE_NOT_BUILT_IN;
    const buf: [*]const u8 = @ptrCast(buf_raw orelse return CURLE_BAD_FUNCTION_ARGUMENT);
    const ctx = cfToProxyCtx(cf) orelse return CURLE_SEND_ERROR;
    const stream = ctx.ts.stream orelse return CURLE_SEND_ERROR;

    var save: CfCallData = undefined;
    cfDataSave(&save, &ctx.q.call_data, data);
    defer cfDataRestore(&ctx.q.call_data, save);

    var pktx: PktIoCtx = undefined;
    Curl_cf_ngtcp2_io_ctx_init(&pktx, cf, data, &ctx.q);

    var result = Curl_cf_ngtcp2_progress_ingress(cf, data, &ctx.q, null);
    if (result != CURLE_OK) return result;

    if (ctx.ts.closed or stream.closed) {
        return CURLE_SEND_ERROR;
    }

    var use_datagram = false;
    if (ctx.ts.udp and ctx.q.qconn != null) {
        const rparams = ngtcp2_c.ngtcp2_conn_get_remote_transport_params(ctx.q.qconn.?);
        if (rparams.max_datagram_frame_size > 0) {
            use_datagram = true;
        }
    }

    if (use_datagram) {
        const qconn = ctx.q.qconn.?;
        if (io_buffers.Curl_bufq_is_full(&ctx.q.q.sendbuf)) {
            return CURLE_AGAIN;
        }
        const qsid: u64 = @intCast(@divTrunc(stream.id, 4));
        var prefix: [2]u8 = .{ @intCast(qsid & 0x3f), 0 };
        var dvec: [2]ngtcp2_vec = .{
            .{ .base = &prefix, .len = 2 },
            .{ .base = @constCast(buf), .len = len },
        };
        var accepted: c_int = 0;
        const pathmax = ngtcp2_c.ngtcp2_conn_get_max_tx_udp_payload_size(qconn);
        var pkt_buf: [NGTCP2_MAX_UDP_PAYLOAD_SIZE]u8 = undefined;
        const written = ngtcp2_c.Curl_ngtcp2_conn_writev_datagram(
            qconn,
            &pktx.ps.path,
            null,
            &pkt_buf,
            @min(pkt_buf.len, pathmax),
            &accepted,
            NGTCP2_WRITE_DATAGRAM_FLAG_NONE,
            0,
            &dvec,
            2,
            pktx.ts,
        );
        if (written > 0) {
            ctx.q.q.gsolen = @intCast(written);
            ctx.q.q.split_len = 0;
            ctx.q.q.split_gsolen = 0;
            var nwritten_buf: usize = 0;
            _ = io_buffers.Curl_bufq_write(&ctx.q.q.sendbuf, &pkt_buf, @intCast(written), &nwritten_buf);
        }
        if (accepted != 0) {
            pnwritten.* = len;
        }
    } else {
        result = io_buffers.Curl_bufq_write(&stream.sendbuf, buf, len, pnwritten);
        if (result != CURLE_OK and result != CURLE_AGAIN) {
            return result;
        }
        if (eos and pnwritten.* == len) {
            stream.send_closed = true;
        }
        if ((pnwritten.* > 0 or eos) and ctx.q.h3conn != null) {
            _ = ngtcp2_c.nghttp3_conn_resume_stream(ctx.q.h3conn.?, stream.id);
        }
    }

    result = progress_egress(cf, data, &ctx.q, &pktx);
    if (result == CURLE_AGAIN) result = CURLE_OK;
    if (result != CURLE_OK) return result;

    return if (pnwritten.* > 0) CURLE_OK else CURLE_AGAIN;
}

fn cf_ngtcp2_proxy_recv(
    cf: *CurlCfilter,
    data: ?*CurlEasy,
    buf: [*]u8,
    len: usize,
    pnread: *usize,
) callconv(.c) CURLcode {
    pnread.* = 0;
    const ctx = cfToProxyCtx(cf) orelse return CURLE_RECV_ERROR;

    var save: CfCallData = undefined;
    cfDataSave(&save, &ctx.q.call_data, data);
    defer cfDataRestore(&ctx.q.call_data, save);

    var pktx: PktIoCtx = undefined;
    Curl_cf_ngtcp2_io_ctx_init(&pktx, cf, data, &ctx.q);

    var result = Curl_cf_ngtcp2_progress_ingress(cf, data, &ctx.q, null);
    if (result != CURLE_OK) return result;

    if (!io_buffers.Curl_bufq_is_empty(&ctx.ts.recvbuf)) {
        result = io_buffers.Curl_bufq_read(&ctx.ts.recvbuf, buf, len, pnread);
        if (result != CURLE_OK) return result;
    }

    result = progress_egress(cf, data, &ctx.q, &pktx);
    if (result == CURLE_AGAIN) result = CURLE_OK;
    if (result != CURLE_OK) return result;

    if (pnread.* > 0) return CURLE_OK;
    if (ctx.ts.closed) return CURLE_OK;
    return CURLE_AGAIN;
}

fn cf_ngtcp2_proxy_cntrl(
    cf: *CurlCfilter,
    data: ?*CurlEasy,
    event: c_int,
    arg1: c_int,
    arg2: ?*anyopaque,
) callconv(.c) CURLcode {
    const ctx = cfToProxyCtx(cf) orelse return CURLE_OK;
    var save: CfCallData = undefined;
    cfDataSave(&save, &ctx.q.call_data, data);
    defer cfDataRestore(&ctx.q.call_data, save);
    return Curl_cf_ngtcp2_cmn_cntrl(cf, data, &ctx.q, event, arg1, arg2);
}

fn cf_ngtcp2_proxy_is_alive(
    cf: *CurlCfilter,
    data: ?*CurlEasy,
    input_pending: *bool,
) callconv(.c) bool {
    const ctx = cfToProxyCtx(cf) orelse return false;
    var save: CfCallData = undefined;
    cfDataSave(&save, &ctx.q.call_data, data);
    defer cfDataRestore(&ctx.q.call_data, save);
    return Curl_cf_ngtcp2_cmn_conn_is_alive(cf, data, &ctx.q, input_pending);
}

fn cf_ngtcp2_proxy_query(
    cf: *CurlCfilter,
    data: ?*CurlEasy,
    query: c_int,
    pres1: ?*c_int,
    pres2: ?*anyopaque,
) callconv(.c) CURLcode {
    const ctx = cfToProxyCtx(cf) orelse return Curl_cf_def_query(cf, data, query, pres1, pres2);
    var save: CfCallData = undefined;
    cfDataSave(&save, &ctx.q.call_data, data);
    defer cfDataRestore(&ctx.q.call_data, save);
    return Curl_cf_ngtcp2_cmn_query(cf, data, &ctx.q, query, pres1, pres2);
}

pub var Curl_cft_h3_proxy = CurlCftype{
    .name = "H3-PROXY",
    .flags = CF_TYPE_IP_CONNECT | CF_TYPE_PROXY | CF_TYPE_SSL,
    .log_level = CURL_LOG_LVL_NONE,
    .destroy = cf_ngtcp2_proxy_destroy,
    .do_connect = cf_ngtcp2_proxy_connect,
    .do_shutdown = cf_ngtcp2_proxy_shutdown,
    .adjust_pollset = cf_ngtcp2_proxy_adjust_pollset,
    .has_data_pending = cf_ngtcp2_proxy_data_pending,
    .do_send = cf_ngtcp2_proxy_send,
    .do_recv = cf_ngtcp2_proxy_recv,
    .cntrl = cf_ngtcp2_proxy_cntrl,
    .is_alive = cf_ngtcp2_proxy_is_alive,
    .keep_alive = Curl_cf_def_conn_keep_alive,
    .query = cf_ngtcp2_proxy_query,
};

fn cf_ngtcp2_proxy_ctx_init(
    ctx: *CfNgtcp2ProxyCtx,
    origin: ?*CurlPeer,
    peer: ?*CurlPeer,
    tunnel_peer: ?*CurlPeer,
    tunnel_transport: u8,
) CURLcode {
    std.debug.assert(!ctx.initialized);
    io_buffers.Curl_bufcp_init(&ctx.bufcp, H3_STREAM_CHUNK_SIZE, H3_STREAM_POOL_SPARES);
    ctx.initialized = true;
    var result = Curl_cf_ngtcp2_ctx_init(&ctx.q, origin, peer, &cf_ngtcp2_proxy_cbs);
    if (result == CURLE_OK) {
        Curl_peer_link(&ctx.peer, peer);
        result = h3_tunnel_stream_init(&ctx.ts, tunnel_peer, tunnel_transport != TRNSPRT_TCP);
    }
    if (result != CURLE_OK) {
        cf_ngtcp2_proxy_ctx_cleanup(ctx);
    }
    return result;
}

pub fn Curl_cf_ngtcp2_proxy_insert_after(
    cf_at: *CurlCfilter,
    data: ?*CurlEasy,
    origin: ?*CurlPeer,
    peer: ?*CurlPeer,
    tunnel_peer: ?*CurlPeer,
    tunnel_transport: u8,
) callconv(.c) CURLcode {
    _ = data;
    if (comptime !use_proxy_http3) return CURLE_NOT_BUILT_IN;

    const raw = mem.calloc(1, @sizeOf(CfNgtcp2ProxyCtx)) orelse return CURLE_OUT_OF_MEMORY;
    const ctx: *CfNgtcp2ProxyCtx = @ptrCast(@alignCast(raw));
    var result = cf_ngtcp2_proxy_ctx_init(ctx, origin, peer, tunnel_peer, tunnel_transport);
    if (result != CURLE_OK) {
        mem.freeTyped(ctx);
        return result;
    }

    var cf: ?*CurlCfilter = null;
    result = Curl_cf_create(&cf, &Curl_cft_h3_proxy, ctx);
    if (result != CURLE_OK) {
        cf_ngtcp2_proxy_ctx_cleanup(ctx);
        mem.freeTyped(ctx);
        return result;
    }

    Curl_conn_cf_insert_after(cf_at, cf.?);
    return CURLE_OK;
}

pub fn Curl_cf_ngtcp2_proxy_create(
    pcf: *?*CurlCfilter,
    data: ?*CurlEasy,
    origin: ?*CurlPeer,
    peer: ?*CurlPeer,
    transport_peer: u8,
    conn: ?*ConnectData,
    addr: ?*CurlSockaddrEx,
    tunnel_peer: ?*CurlPeer,
    tunnel_transport: u8,
) callconv(.c) CURLcode {
    pcf.* = null;
    if (comptime !use_proxy_http3) return CURLE_NOT_BUILT_IN;
    std.debug.assert(transport_peer == TRNSPRT_QUIC);

    const raw = mem.calloc(1, @sizeOf(CfNgtcp2ProxyCtx)) orelse return CURLE_OUT_OF_MEMORY;
    const ctx: *CfNgtcp2ProxyCtx = @ptrCast(@alignCast(raw));
    var result = cf_ngtcp2_proxy_ctx_init(ctx, origin, peer, tunnel_peer, tunnel_transport);
    if (result != CURLE_OK) {
        mem.freeTyped(ctx);
        return result;
    }

    var cf_h3_proxy: ?*CurlCfilter = null;
    result = Curl_cf_create(&cf_h3_proxy, &Curl_cft_h3_proxy, ctx);
    if (result != CURLE_OK or cf_h3_proxy == null) {
        cf_ngtcp2_proxy_ctx_cleanup(ctx);
        mem.freeTyped(ctx);
        return result;
    }
    cf_h3_proxy.?.conn = conn;

    var cf_udp: ?*CurlCfilter = null;
    result = Curl_cf_udp_create(&cf_udp, data, origin, peer, TRNSPRT_QUIC, conn, addr, null, TRNSPRT_QUIC);
    if (result != CURLE_OK or cf_udp == null) {
        cf_ngtcp2_proxy_destroy(cf_h3_proxy.?, data);
        mem.freeTyped(cf_h3_proxy);
        return result;
    }

    cf_udp.?.conn = cf_h3_proxy.?.conn;
    cf_udp.?.sockindex = cf_h3_proxy.?.sockindex;
    cf_h3_proxy.?.next = cf_udp;
    pcf.* = cf_h3_proxy;
    return CURLE_OK;
}

comptime {
    if (use_ngtcp2) {
        @export(&Curl_cft_http3, .{ .name = "Curl_cft_http3", .linkage = .strong });
    }
    if (use_proxy_http3) {
        @export(&Curl_cft_h3_proxy, .{ .name = "Curl_cft_h3_proxy", .linkage = .strong });
    }
}

// ============================================================================
// 6. Unit Tests
// ============================================================================

test "Curl_cft_http3 and Curl_cft_h3_proxy vtable properties" {
    try std.testing.expectEqualStrings("HTTP/3", std.mem.span(Curl_cft_http3.name));
    try std.testing.expectEqual(
        CF_TYPE_IP_CONNECT | CF_TYPE_SSL | CF_TYPE_MULTIPLEX | CF_TYPE_HTTP,
        Curl_cft_http3.flags,
    );
    try std.testing.expect(@intFromPtr(Curl_cft_http3.do_connect) != 0);
    try std.testing.expect(@intFromPtr(Curl_cft_http3.do_send) != 0);
    try std.testing.expect(@intFromPtr(Curl_cft_http3.do_recv) != 0);
    try std.testing.expect(@intFromPtr(Curl_cft_http3.destroy) != 0);

    try std.testing.expectEqualStrings("H3-PROXY", std.mem.span(Curl_cft_h3_proxy.name));
    try std.testing.expectEqual(
        CF_TYPE_IP_CONNECT | CF_TYPE_PROXY | CF_TYPE_SSL,
        Curl_cft_h3_proxy.flags,
    );
    try std.testing.expect(@intFromPtr(Curl_cft_h3_proxy.do_connect) != 0);
    try std.testing.expect(@intFromPtr(Curl_cft_h3_proxy.do_send) != 0);
    try std.testing.expect(@intFromPtr(Curl_cft_h3_proxy.do_recv) != 0);
    try std.testing.expect(@intFromPtr(Curl_cft_h3_proxy.destroy) != 0);
}

test "CfNgtcp2Ctx init and cleanup lifecycle" {
    var ctx = CfNgtcp2Ctx{};
    const rc = Curl_cf_ngtcp2_ctx_init(&ctx, null, null, &cf_ngtcp2_cbs);
    try std.testing.expectEqual(CURLE_OK, rc);
    try std.testing.expect(ctx.initialized);
    try std.testing.expectEqual(@as(?*const CfNgtcp2Cbs, &cf_ngtcp2_cbs), ctx.cbs);
    Curl_cf_ngtcp2_ctx_cleanup(&ctx);
}

test "Curl_cf_quic_create and Curl_cf_h3_proxy_create filter initialization" {
    var cf: ?*CurlCfilter = null;
    var dummy_addr: CurlSockaddrEx = std.mem.zeroes(CurlSockaddrEx);
    const rc = vquic_core.Curl_cf_quic_create(
        &cf,
        null,
        null,
        null,
        TRNSPRT_QUIC,
        null,
        &dummy_addr,
        null,
        0,
    );
    if (comptime use_ngtcp2) {
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
        Curl_ngtcp2_ver(&ver_buf, ver_buf.len);
        const ver_str = std.mem.sliceTo(&ver_buf, 0);
        try std.testing.expect(std.mem.indexOf(u8, ver_str, "ngtcp2/") != null);
        try std.testing.expect(std.mem.indexOf(u8, ver_str, "nghttp3/") != null);
    } else if (comptime vquic_core.use_http3) {
        try std.testing.expectEqual(CURLE_OK, rc);
        try std.testing.expect(cf != null);
        const h3_cf = cf.?;
        if (h3_cf.next) |udp_cf| {
            udp_cf.cft.destroy(udp_cf, null);
            mem.freeTyped(udp_cf);
        }
        h3_cf.cft.destroy(h3_cf, null);
        mem.freeTyped(h3_cf);
    } else {
        try std.testing.expectEqual(CURLE_NOT_BUILT_IN, rc);
        try std.testing.expect(cf == null);
    }

    var cf_proxy: ?*CurlCfilter = null;
    const SchemeType = @typeInfo(@typeInfo(@FieldType(CurlPeer, "scheme")).optional.child).pointer.child;
    var dummy_scheme: SchemeType = std.mem.zeroes(SchemeType);
    dummy_scheme.name = "https";
    var dummy_peer: CurlPeer = std.mem.zeroes(CurlPeer);
    dummy_peer.scheme = &dummy_scheme;
    dummy_peer.hostname = @constCast("localhost");
    dummy_peer.port = 8443;
    dummy_peer.refcount = 10;
    const rc_proxy = vquic_core.Curl_cf_h3_proxy_create(
        &cf_proxy,
        null,
        &dummy_peer,
        &dummy_peer,
        TRNSPRT_QUIC,
        null,
        &dummy_addr,
        &dummy_peer,
        TRNSPRT_UDP,
    );
    if (comptime use_proxy_http3) {
        try std.testing.expectEqual(CURLE_OK, rc_proxy);
        try std.testing.expect(cf_proxy != null);
        const p_cf = cf_proxy.?;
        defer {
            if (p_cf.next) |udp_cf| {
                udp_cf.cft.destroy(udp_cf, null);
                mem.freeTyped(udp_cf);
            }
            p_cf.cft.destroy(p_cf, null);
            mem.freeTyped(p_cf);
        }
        try std.testing.expectEqual(&Curl_cft_h3_proxy, p_cf.cft);
        try std.testing.expect(p_cf.next != null);
    } else {
        try std.testing.expectEqual(CURLE_NOT_BUILT_IN, rc_proxy);
        try std.testing.expect(cf_proxy == null);
    }
}

test "vquic_ngtcp2 detached easyMid, magic/xfer_id stream validation, tunnel stream clearing, and H3StreamCtx freeTyped poisoning" {
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

    var ctx = CfNgtcp2Ctx{};
    try std.testing.expectEqual(CURLE_OK, Curl_cf_ngtcp2_ctx_init(&ctx, null, null, &cf_ngtcp2_cbs));
    defer Curl_cf_ngtcp2_ctx_cleanup(&ctx);

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
    try std.testing.expectEqual(@as(?*H3StreamCtx, null), h3StreamCtx(&ctx, easy));
    try std.testing.expectEqual(@as(?*H3StreamCtx, null), h3StreamCtx(&ctx, null));

    var setup_stream: ?*H3StreamCtx = null;
    try std.testing.expectEqual(
        CURLE_BAD_FUNCTION_ARGUMENT,
        Curl_cf_ngtcp2_h3_stream_setup(&dummy_cf, easy, &ctx, &setup_stream),
    );
    try std.testing.expectEqual(@as(?*H3StreamCtx, null), setup_stream);

    // 2. Attach to multi, setup stream, and verify lookup works when magic + mid + xfer_id match
    const multi = test_ext.curl_multi_init() orelse return error.OutOfMemory;
    defer _ = test_ext.curl_multi_cleanup(multi);
    try std.testing.expectEqual(@as(c_int, 0), test_ext.curl_multi_add_handle(multi, easy));
    defer _ = test_ext.curl_multi_remove_handle(multi, easy);

    test_ext.Curl_zig_url_data_set_i64(easy, 2, 101);
    const orig_mid = easyMid(easy);
    try std.testing.expect(orig_mid != std.math.maxInt(u32));

    try std.testing.expectEqual(
        CURLE_OK,
        Curl_cf_ngtcp2_h3_stream_setup(&dummy_cf, easy, &ctx, &setup_stream),
    );
    const stream = setup_stream.?;
    stream.id = 4;
    try std.testing.expectEqual(orig_mid, stream.mid);
    try std.testing.expectEqual(@as(i64, 101), stream.xfer_id);
    try std.testing.expectEqual(@as(?*H3StreamCtx, stream), h3StreamCtx(&ctx, easy));

    ctx.call_data.data = easy;
    try std.testing.expectEqual(@as(?*CurlEasy, easy), Curl_cf_ngtcp2_get_xfer(&ctx, 4));

    // Also verify visit_by_sid path when call_data is another valid handle on the same multi
    var other_opt: ?*CurlEasy = null;
    try std.testing.expectEqual(CURLE_OK, test_ext.Curl_open(&other_opt));
    defer _ = test_ext.Curl_close(&other_opt);
    const other = other_opt.?;
    try std.testing.expectEqual(@as(c_int, 0), test_ext.curl_multi_add_handle(multi, other));
    defer _ = test_ext.curl_multi_remove_handle(multi, other);
    test_ext.Curl_zig_url_data_set_i64(other, 2, 202);

    ctx.call_data.data = other;
    try std.testing.expectEqual(@as(?*CurlEasy, easy), Curl_cf_ngtcp2_get_xfer(&ctx, 4));

    // 3. Reject when xfer_id mismatches (simulating mid slot reuse after transfer teardown)
    ctx.call_data.data = other;
    test_ext.Curl_zig_url_data_set_i64(easy, 2, 999);
    try std.testing.expectEqual(@as(?*H3StreamCtx, null), h3StreamCtx(&ctx, easy));
    try std.testing.expectEqual(@as(?*CurlEasy, null), Curl_cf_ngtcp2_get_xfer(&ctx, 4));
    test_ext.Curl_zig_url_data_set_i64(easy, 2, 101);
    try std.testing.expectEqual(@as(?*CurlEasy, easy), Curl_cf_ngtcp2_get_xfer(&ctx, 4));

    // 4. Reject when magic != CURLEASY_MAGIC_NUMBER
    test_ext.Curl_zig_url_data_set_i64(easy, 1, 0);
    try std.testing.expect(!goodEasyHandle(easy));
    try std.testing.expectEqual(std.math.maxInt(u32), easyMid(easy));
    try std.testing.expectEqual(@as(?*H3StreamCtx, null), h3StreamCtx(&ctx, easy));
    try std.testing.expectEqual(@as(?*CurlEasy, null), Curl_cf_ngtcp2_get_xfer(&ctx, 4));
    ctx.call_data.data = easy;
    try std.testing.expectEqual(@as(?*CurlEasy, null), Curl_cf_ngtcp2_get_xfer(&ctx, 4));
    test_ext.Curl_zig_url_data_set_i64(easy, 1, CURLEASY_MAGIC_NUMBER);

    // 5. Verify H3TunnelStream.stream is cleared on stream close and cleanup
    var proxy_ctx = CfNgtcp2ProxyCtx{};
    proxy_ctx.ts.stream = stream;
    var proxy_cf: CurlCfilter = std.mem.zeroes(CurlCfilter);
    proxy_cf.cft = &Curl_cft_h3_proxy;
    proxy_cf.ctx = &proxy_ctx;
    Curl_cf_ngtcp2_h3_stream_close(&proxy_cf, easy, &proxy_ctx.q, stream);
    try std.testing.expectEqual(@as(?*H3StreamCtx, null), proxy_ctx.ts.stream);

    proxy_ctx.ts.stream = stream;
    h3_tunnel_stream_cleanup(&proxy_ctx.ts);
    try std.testing.expectEqual(@as(?*H3StreamCtx, null), proxy_ctx.ts.stream);

    // 6. Verify H3StreamCtx freed-memory poisoning via mem.freeTyped
    const expected_poison: u8 = switch (@import("builtin").mode) {
        .Debug, .ReleaseSafe => 0xaa,
        .ReleaseFast, .ReleaseSmall => 0x00,
    };
    const saved_cfree = test_ext.Curl_cfree;
    test_ext.Curl_cfree = test_ext.mockFree;
    defer test_ext.Curl_cfree = saved_cfree;

    const raw_s = mem.calloc(1, @sizeOf(H3StreamCtx)) orelse return error.OutOfMemory;
    const temp_s: *H3StreamCtx = @ptrCast(@alignCast(raw_s));
    temp_s.id = 77;
    temp_s.mid = 3;
    temp_s.xfer_id = 555;
    io_buffers.Curl_bufq_initp(&temp_s.sendbuf, &ctx.stream_bufcp, H3_STREAM_SEND_CHUNKS, BUFQ_OPT_NONE);
    http1_options.Curl_h1_req_parse_init(&temp_s.h1, 16 * 1024);

    @memset(&test_ext.captured_free_bytes, 0);
    test_ext.expected_free_ptr = @ptrCast(temp_s);
    test_ext.captured_stream_free = false;
    Curl_cf_ngtcp2_h3_stream_ctx_free(temp_s);
    try std.testing.expect(test_ext.captured_stream_free);
    for (test_ext.captured_free_bytes) |b| {
        try std.testing.expectEqual(expected_poison, b);
    }
}
