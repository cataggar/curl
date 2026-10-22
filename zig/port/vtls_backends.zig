const std = @import("std");
const builtin = @import("builtin");
const backend_options = @import("backend_options");
const mem = @import("mem.zig");
const containers = @import("containers.zig");
const primitives = @import("primitives.zig");
const io_buffers = @import("io_buffers.zig");
const os_leaf = @import("os_leaf.zig");
const curlx_time_net = @import("curlx_time_net.zig");
const vtls_core = @import("vtls_core.zig");
const vtls_scache_asn1 = @import("vtls_scache_asn1.zig");
const cfilters_progress = @import("cfilters_progress.zig");
pub const vtls_gtls = @import("vtls_gtls.zig");
pub const vtls_rustls = @import("vtls_rustls.zig");
pub const vtls_wolfssl = @import("vtls_wolfssl.zig");
pub const bundled_tls = @import("bundled_tls.zig");

pub const is_windows = builtin.os.tag == .windows;
pub const use_ssl = switch (backend_options.ssl) {
    .openssl, .mbedtls, .schannel, .gnutls, .rustls, .wolfssl => true,
    .none => false,
};
pub const has_ssl = use_ssl;
pub const use_apple_sectrust = backend_options.apple_sectrust orelse (backend_options.ssl == .openssl and !backend_options.bundled and builtin.os.tag.isDarwin());

// ============================================================================
// Constants & Error Codes
// ============================================================================

pub const CURLcode = c_uint;
pub const CURLE_OK: CURLcode = 0;
pub const CURLE_UNSUPPORTED_PROTOCOL: CURLcode = 1;
pub const CURLE_FAILED_INIT: CURLcode = 2;
pub const CURLE_NOT_BUILT_IN: CURLcode = 4;
pub const CURLE_COULDNT_CONNECT: CURLcode = 7;
pub const CURLE_OUT_OF_MEMORY: CURLcode = 27;
pub const CURLE_OPERATION_TIMEDOUT: CURLcode = 28;
pub const CURLE_SSL_CONNECT_ERROR: CURLcode = 35;
pub const CURLE_BAD_FUNCTION_ARGUMENT: CURLcode = 43;
pub const CURLE_SEND_ERROR: CURLcode = 55;
pub const CURLE_RECV_ERROR: CURLcode = 56;
pub const CURLE_SSL_CERTPROBLEM: CURLcode = 58;
pub const CURLE_SSL_CIPHER: CURLcode = 59;
pub const CURLE_PEER_FAILED_VERIFICATION: CURLcode = 60;
pub const CURLE_BAD_CONTENT_ENCODING: CURLcode = 61;
pub const CURLE_SSL_ENGINE_INITFAILED: CURLcode = 66;
pub const CURLE_SSL_SHUTDOWN_FAILED: CURLcode = 80;
pub const CURLE_AGAIN: CURLcode = 81;
pub const CURLE_SSL_CRL_BADFILE: CURLcode = 82;
pub const CURLE_SSL_ISSUER_ERROR: CURLcode = 83;
pub const CURLE_SSL_PINNEDPUBKEYNOTMATCH: CURLcode = 90;
pub const CURLE_SSL_INVALIDCERTSTATUS: CURLcode = 91;
pub const CURLE_SSL_CLIENTCERT: CURLcode = 98;

pub const CURLSSLBACKEND_NONE: c_uint = 0;
pub const CURLSSLBACKEND_OPENSSL: c_uint = 1;
pub const CURLSSLBACKEND_GNUTLS: c_uint = 2;
pub const CURLSSLBACKEND_WOLFSSL: c_uint = 7;
pub const CURLSSLBACKEND_SCHANNEL: c_uint = 8;
pub const CURLSSLBACKEND_SECURETRANSPORT: c_uint = 9;
pub const CURLSSLBACKEND_MBEDTLS: c_uint = 11;
pub const CURLSSLBACKEND_RUSTLS: c_uint = 14;

pub const CURLSSLSET_OK: c_uint = 0;
pub const CURLSSLSET_UNKNOWN_BACKEND: c_uint = 1;
pub const CURLSSLSET_TOO_LATE: c_uint = 2;
pub const CURLSSLSET_NO_BACKENDS: c_uint = 3;

pub const SSLSUPP_CA_PATH: c_uint = 1 << 0;
pub const SSLSUPP_CERTINFO: c_uint = 1 << 1;
pub const SSLSUPP_PINNEDPUBKEY: c_uint = 1 << 2;
pub const SSLSUPP_SSL_CTX: c_uint = 1 << 3;
pub const SSLSUPP_HTTPS_PROXY: c_uint = 1 << 4;
pub const SSLSUPP_TLS13_CIPHERSUITES: c_uint = 1 << 5;
pub const SSLSUPP_CAINFO_BLOB: c_uint = 1 << 6;
pub const SSLSUPP_ECH: c_uint = 1 << 7;
pub const SSLSUPP_CA_CACHE: c_uint = 1 << 8;
pub const SSLSUPP_CIPHER_LIST: c_uint = 1 << 9;
pub const SSLSUPP_SIGNATURE_ALGORITHMS: c_uint = 1 << 10;
pub const SSLSUPP_ISSUERCERT: c_uint = 1 << 11;
pub const SSLSUPP_SSL_EC_CURVES: c_uint = 1 << 12;
pub const SSLSUPP_CRLFILE: c_uint = 1 << 13;
pub const SSLSUPP_ISSUERCERT_BLOB: c_uint = 1 << 14;

pub const CURL_SSLVERSION_DEFAULT: u8 = 0;
pub const CURL_SSLVERSION_TLSv1: u8 = 1;
pub const CURL_SSLVERSION_SSLv2: u8 = 2;
pub const CURL_SSLVERSION_SSLv3: u8 = 3;
pub const CURL_SSLVERSION_TLSv1_0: u8 = 4;
pub const CURL_SSLVERSION_TLSv1_1: u8 = 5;
pub const CURL_SSLVERSION_TLSv1_2: u8 = 6;
pub const CURL_SSLVERSION_TLSv1_3: u8 = 7;
pub const CURL_SSLVERSION_LAST: u8 = 8;

pub const CURL_SSLVERSION_MAX_NONE: u32 = 0;
pub const CURL_SSLVERSION_MAX_DEFAULT: u32 = @as(u32, CURL_SSLVERSION_TLSv1) << 16;
pub const CURL_SSLVERSION_MAX_TLSv1_0: u32 = @as(u32, CURL_SSLVERSION_TLSv1_0) << 16;
pub const CURL_SSLVERSION_MAX_TLSv1_1: u32 = @as(u32, CURL_SSLVERSION_TLSv1_1) << 16;
pub const CURL_SSLVERSION_MAX_TLSv1_2: u32 = @as(u32, CURL_SSLVERSION_MAX_DEFAULT) | (@as(u32, CURL_SSLVERSION_TLSv1_2) << 16);
pub const CURL_SSLVERSION_MAX_TLSv1_3: u32 = @as(u32, CURL_SSLVERSION_TLSv1_3) << 16;
pub const CURL_SSLVERSION_MAX_LAST: u32 = @as(u32, CURL_SSLVERSION_LAST) << 16;

pub const CURLSSLOPT_ALLOW_BEAST: u8 = 1 << 0;
pub const CURLSSLOPT_NO_REVOKE: u8 = 1 << 1;
pub const CURLSSLOPT_NO_PARTIALCHAIN: u8 = 1 << 2;
pub const CURLSSLOPT_REVOKE_BEST_EFFORT: u8 = 1 << 3;
pub const CURLSSLOPT_NATIVE_CA: u8 = 1 << 4;
pub const CURLSSLOPT_AUTO_CLIENT_CERT: u8 = 1 << 5;
pub const CURLSSLOPT_EARLYDATA: u8 = 1 << 6;

pub const CF_TYPE_SSL: c_int = 1 << 1;
pub const CF_TYPE_PROXY: c_int = 1 << 3;
pub const CF_LVL_SSL: c_int = 2;

pub const CF_CTRL_DATA_SETUP: c_int = 4;
pub const CF_CTRL_CONN_INFO_UPDATE: c_int = 256 + 0;
pub const CF_CTRL_REPORT_STATS: c_int = 256 + 3;

pub const CF_QUERY_MAX_CONCURRENT: c_int = 1;
pub const CF_QUERY_CONNECT_REPLY_MS: c_int = 2;
pub const CF_QUERY_SOCKET: c_int = 3;
pub const CF_QUERY_TIMER_CONNECT: c_int = 4;
pub const CF_QUERY_TIMER_APPCONNECT: c_int = 5;
pub const CF_QUERY_HTTP_VERSION: c_int = 9;
pub const CF_QUERY_SSL_INFO: c_int = 12;
pub const CF_QUERY_SSL_CTX_INFO: c_int = 13;
pub const CF_QUERY_ALPN_NEGOTIATED: c_int = 15;

pub const CURLINFO_TLS_SESSION: c_uint = 0x400000 + 43;
pub const CURLINFO_TLS_SSL_PTR: c_uint = 0x400000 + 45;

pub const CURL_HTTP_V1x: u8 = 1 << 0;
pub const CURL_HTTP_V2x: u8 = 1 << 1;
pub const CURL_HTTP_V3x: u8 = 1 << 2;

pub const CURLPROXY_HTTPS: u8 = 2;
pub const CURLPROXY_HTTPS2: u8 = 3;

pub const TRNSPRT_TCP: u8 = 3;
pub const TRNSPRT_UDP: u8 = 4;
pub const TRNSPRT_QUIC: u8 = 5;
pub const FIRSTSOCKET: i8 = 0;

pub const TIMER_APPCONNECT: c_int = 6;
pub const CURL_X509_STR_MAX: usize = 100000;
pub const MAX_PINNED_PUBKEY_SIZE: usize = 1048576;
pub const CURL_SHA256_DIGEST_LENGTH: usize = 32;
pub const CURL_SSL_EARLY_MAX: usize = 64 * 1024;
pub const BUFQ_OPT_NO_SPARES: c_int = 1;

pub const CURL_SSL_IO_NEED_NONE: c_int = 0;
pub const CURL_SSL_IO_NEED_RECV: c_int = 1 << 0;
pub const CURL_SSL_IO_NEED_SEND: c_int = 1 << 1;

pub const ssl_connection_none: c_uint = 0;
pub const ssl_connection_deferred: c_uint = 1;
pub const ssl_connection_negotiating: c_uint = 2;
pub const ssl_connection_complete: c_uint = 3;

pub const ssl_connect_1: c_uint = 0;
pub const ssl_connect_2: c_uint = 1;
pub const ssl_connect_3: c_uint = 2;
pub const ssl_connect_done: c_uint = 3;

pub const ssl_earlydata_none: c_uint = 0;
pub const ssl_earlydata_await: c_uint = 1;
pub const ssl_earlydata_sending: c_uint = 2;
pub const ssl_earlydata_sent: c_uint = 3;
pub const ssl_earlydata_accepted: c_uint = 4;
pub const ssl_earlydata_rejected: c_uint = 5;

pub const ALPN_ENTRIES_MAX: usize = 3;
pub const ALPN_NAME_MAX: usize = 10;
pub const ALPN_PROTO_BUF_MAX: usize = ALPN_ENTRIES_MAX * (ALPN_NAME_MAX + 1);

// ============================================================================
// Shared C ABI Structs
// ============================================================================

pub const CurlEasy = opaque {};
pub const ConnectData = opaque {};
pub const EasyPollset = opaque {};
pub const CurlSslScache = vtls_scache_asn1.CurlSslScache;
pub const CurlSslSession = vtls_core.CurlSslSession;
pub const CurlTrcFeat = vtls_scache_asn1.CurlTrcFeat;
pub const SslEasyConfig = vtls_scache_asn1.SslEasyConfig;
pub const SslFilterConfig = vtls_scache_asn1.SslFilterConfig;
pub const SslPeer = vtls_scache_asn1.SslPeer;
pub const CurlPeer = vtls_scache_asn1.CurlPeer;
pub const CurlBlob = vtls_core.CurlBlob;
pub const DynBuf = containers.dynbuf;
pub const curl_slist = containers.curl_slist;
pub const bufq = io_buffers.bufq;
pub const CurlTime = curlx_time_net.Curltime;
pub const curl_socket_t = if (is_windows) u64 else c_int;
pub const CURL_SOCKET_BAD: curl_socket_t = if (is_windows) ~@as(u64, 0) else -1;
const AF_INET6_VAL: c_int = if (is_windows) 23 else if (builtin.os.tag.isDarwin()) 30 else 10;

pub const SSL_PEER_DNS: c_uint = 0;
pub const SSL_PEER_IPV4: c_uint = 1;
pub const SSL_PEER_IPV6: c_uint = 2;

pub const CurlCertinfo = extern struct {
    num_of_certs: c_int,
    certinfo: ?[*]?*curl_slist,
};

pub const AlpnSpec = extern struct {
    entries: [ALPN_ENTRIES_MAX][ALPN_NAME_MAX]u8,
    count: usize,
};

pub const AlpnProtoBuf = extern struct {
    data: [ALPN_PROTO_BUF_MAX]u8,
    len: c_int,
};

pub const CurlSslBackendInfo = extern struct {
    id: c_uint,
    name: [*:0]const u8,
};

pub const CurlSsl = extern struct {
    info: CurlSslBackendInfo,
    supports: c_uint,
    sizeof_ssl_backend_data: usize,
    init: ?*const fn () callconv(.c) c_int,
    cleanup: ?*const fn () callconv(.c) void,
    version: *const fn (buffer: [*]u8, size: usize) callconv(.c) usize,
    shut_down: ?*const fn (cf: *CurlCfilter, data: ?*CurlEasy, send_shutdown: bool, done: *bool) callconv(.c) CURLcode,
    data_pending: ?*const fn (cf: *CurlCfilter, data: ?*const CurlEasy) callconv(.c) bool,
    random: ?*const fn (data: ?*CurlEasy, entropy: [*]u8, length: usize) callconv(.c) CURLcode,
    cert_status_request: ?*const fn () callconv(.c) bool,
    do_connect: *const fn (cf: *CurlCfilter, data: ?*CurlEasy, done: *bool) callconv(.c) CURLcode,
    adjust_pollset: *const fn (cf: *CurlCfilter, data: ?*CurlEasy, ps: ?*EasyPollset) callconv(.c) CURLcode,
    get_internals: ?*const fn (connssl: *SslConnectData, info: c_uint) callconv(.c) ?*anyopaque,
    close: *const fn (cf: *CurlCfilter, data: ?*CurlEasy) callconv(.c) void,
    close_all: ?*const fn (data: ?*CurlEasy) callconv(.c) void,
    engines_list: ?*const fn (data: ?*CurlEasy) callconv(.c) ?*curl_slist,
    sha256sum: ?*const fn (input: [*]const u8, inputlen: usize, sha256sum: [*]u8, sha256len: usize) callconv(.c) CURLcode,
    recv_plain: *const fn (cf: *CurlCfilter, data: ?*CurlEasy, buf: [*]u8, len: usize, pnread: *usize) callconv(.c) CURLcode,
    send_plain: *const fn (cf: *CurlCfilter, data: ?*CurlEasy, mem_ptr: ?*const anyopaque, len: usize, pnwritten: *usize) callconv(.c) CURLcode,
    get_channel_binding: ?*const fn (data: ?*CurlEasy, sockindex: i8, binding: *DynBuf) callconv(.c) CURLcode,
};

pub const SslConnectData = extern struct {
    const FlagsType = if (is_windows) u32 else u8;

    ssl_impl: *const CurlSsl,
    peer: SslPeer,
    alpn: ?*const AlpnSpec,
    backend: ?*anyopaque,
    call_data: ?*CurlEasy,
    session: ?*CurlSslSession,
    handshake_done: CurlTime,
    negotiated_alpn: ?[*:0]u8,
    earlydata: bufq,
    earlydata_max: usize,
    earlydata_skip: usize,
    state: c_uint,
    connecting_state: c_uint,
    earlydata_state: c_uint,
    io_need: c_int,
    flags: FlagsType,

    pub fn peer_closed(self: *const SslConnectData) bool {
        return (self.flags & 1) != 0;
    }
    pub fn set_peer_closed(self: *SslConnectData, v: bool) void {
        if (v) self.flags |= 1 else self.flags &= ~@as(FlagsType, 1);
    }
    pub fn prefs_checked(self: *const SslConnectData) bool {
        return (self.flags & 2) != 0;
    }
    pub fn set_prefs_checked(self: *SslConnectData, v: bool) void {
        if (v) self.flags |= 2 else self.flags &= ~@as(FlagsType, 2);
    }
    pub fn input_pending(self: *const SslConnectData) bool {
        return (self.flags & 4) != 0;
    }
    pub fn set_input_pending(self: *SslConnectData, v: bool) void {
        if (v) self.flags |= 4 else self.flags &= ~@as(FlagsType, 4);
    }
    pub fn stats_reported(self: *const SslConnectData) bool {
        return (self.flags & 8) != 0;
    }
    pub fn set_stats_reported(self: *SslConnectData, v: bool) void {
        if (v) self.flags |= 8 else self.flags &= ~@as(FlagsType, 8);
    }
};

pub const CurlCftype = extern struct {
    name: [*:0]const u8,
    flags: c_int,
    log_level: c_int,
    destroy: *const fn (cf: *CurlCfilter, data: ?*CurlEasy) callconv(.c) void,
    do_connect: *const fn (cf: *CurlCfilter, data: ?*CurlEasy, done: *bool) callconv(.c) CURLcode,
    do_shutdown: *const fn (cf: *CurlCfilter, data: ?*CurlEasy, done: *bool) callconv(.c) CURLcode,
    adjust_pollset: *const fn (cf: *CurlCfilter, data: ?*CurlEasy, ps: ?*EasyPollset) callconv(.c) CURLcode,
    has_data_pending: *const fn (cf: *CurlCfilter, data: ?*const CurlEasy) callconv(.c) bool,
    do_send: *const fn (cf: *CurlCfilter, data: ?*CurlEasy, buf: ?*const anyopaque, len: usize, eos: bool, pnwritten: *usize) callconv(.c) CURLcode,
    do_recv: *const fn (cf: *CurlCfilter, data: ?*CurlEasy, buf: [*]u8, len: usize, pnread: *usize) callconv(.c) CURLcode,
    cntrl: *const fn (cf: *CurlCfilter, data: ?*CurlEasy, event: c_int, arg1: c_int, arg2: ?*anyopaque) callconv(.c) CURLcode,
    is_alive: *const fn (cf: *CurlCfilter, data: ?*CurlEasy, input_pending: *bool) callconv(.c) bool,
    keep_alive: *const fn (cf: *CurlCfilter, data: ?*CurlEasy) callconv(.c) CURLcode,
    query: *const fn (cf: *CurlCfilter, data: ?*CurlEasy, query: c_int, pres1: ?*c_int, pres2: ?*anyopaque) callconv(.c) CURLcode,
};

pub const CurlCfilter = if (is_windows) extern struct {
    cft: *const CurlCftype,
    next: ?*CurlCfilter,
    ctx: ?*anyopaque,
    conn: ?*ConnectData,
    sockindex: i8,
    _pad: [3]u8 = .{ 0, 0, 0 },
    flags: u32,

    pub fn isConnected(self: *const CurlCfilter) bool {
        return (self.flags & 1) != 0;
    }
    pub fn setConnected(self: *CurlCfilter, v: bool) void {
        if (v) self.flags |= 1 else self.flags &= ~@as(u32, 1);
    }
    pub fn isShutdown(self: *const CurlCfilter) bool {
        return (self.flags & 2) != 0;
    }
    pub fn setShutdown(self: *CurlCfilter, v: bool) void {
        if (v) self.flags |= 2 else self.flags &= ~@as(u32, 2);
    }
} else extern struct {
    cft: *const CurlCftype,
    next: ?*CurlCfilter,
    ctx: ?*anyopaque,
    conn: ?*ConnectData,
    sockindex: i8,
    flags: u8,

    pub fn isConnected(self: *const CurlCfilter) bool {
        return (self.flags & 1) != 0;
    }
    pub fn setConnected(self: *CurlCfilter, v: bool) void {
        if (v) self.flags |= 1 else self.flags &= ~@as(u8, 1);
    }
    pub fn isShutdown(self: *const CurlCfilter) bool {
        return (self.flags & 2) != 0;
    }
    pub fn setShutdown(self: *CurlCfilter, v: bool) void {
        if (v) self.flags |= 2 else self.flags &= ~@as(u8, 2);
    }
};

pub const CurlTlsSessionInfo = extern struct {
    backend: c_uint,
    internals: ?*anyopaque,
};
pub const CurlTlssessioninfo = CurlTlsSessionInfo;

pub const c_ext = struct {
    pub extern fn Curl_failf(data: ?*CurlEasy, fmt: [*:0]const u8, ...) callconv(.c) void;
    pub extern fn Curl_infof(data: ?*CurlEasy, fmt: [*:0]const u8, ...) callconv(.c) void;
    pub extern fn Curl_trc_cf_infof(data: ?*CurlEasy, cf: ?*CurlCfilter, fmt: [*:0]const u8, ...) callconv(.c) void;
    pub extern fn Curl_trc_is_verbose_fn(data: ?*CurlEasy) callconv(.c) bool;
    pub extern fn Curl_pgrsTime(data: ?*CurlEasy, id: c_int) callconv(.c) void;
    pub extern fn Curl_pgrsTimeWas(data: ?*CurlEasy, timer: c_int, timestamp: CurlTime) callconv(.c) void;
    pub extern fn Curl_pgrs_now(data: ?*CurlEasy) callconv(.c) *const CurlTime;
    pub extern fn Curl_pgrsEarlyData(data: ?*CurlEasy, sent: i64) callconv(.c) void;
    pub extern fn Curl_pgrsUpdate(data: ?*CurlEasy) callconv(.c) CURLcode;
    pub extern fn Curl_peer_link(pdest: *?*CurlPeer, src: ?*CurlPeer) callconv(.c) void;
    pub extern fn Curl_peer_unlink(ppeer: *?*CurlPeer) callconv(.c) void;
    pub extern fn curlx_inet_pton(af: c_int, src: [*:0]const u8, dst: *anyopaque) callconv(.c) c_int;
    pub extern "c" fn fopen(filename: [*:0]const u8, mode: [*:0]const u8) callconv(.c) ?*std.c.FILE;
    pub extern "c" fn fclose(file: *std.c.FILE) callconv(.c) c_int;
    pub extern "c" fn fseek(stream: *std.c.FILE, offset: c_long, whence: c_int) callconv(.c) c_int;
    pub extern "c" fn ftell(stream: *std.c.FILE) callconv(.c) c_long;
    pub extern "c" fn fread(ptr: *anyopaque, size: usize, nmemb: usize, stream: *std.c.FILE) callconv(.c) usize;
    pub extern fn Curl_slist_append_nodup(list: ?*curl_slist, data: [*:0]u8) callconv(.c) ?*curl_slist;
    pub extern fn curl_slist_free_all(list: ?*curl_slist) callconv(.c) void;
    pub extern fn curlx_base64_decode(src: [*:0]const u8, outptr: *?[*]u8, outlen: *usize) callconv(.c) CURLcode;
    pub extern fn curlx_base64_encode(inputbuff: ?[*]const u8, insize: usize, outptr: *?[*:0]u8, outlen: *usize) callconv(.c) CURLcode;
    pub extern fn curl_msnprintf(buffer: [*]u8, maxlength: usize, format: [*:0]const u8, ...) callconv(.c) c_int;
    pub extern fn curlx_strerror(err: c_int, buf: [*]u8, buflen: usize) callconv(.c) [*:0]const u8;
    pub extern fn Curl_cert_hostcheck(match_pattern: [*:0]const u8, match_len: usize, hostname: [*:0]const u8, hostlen: usize) callconv(.c) bool;
    pub extern fn Curl_timeleft_ms(data: ?*CurlEasy) callconv(.c) i64;
    pub extern fn Curl_socket_check(readfd0: curl_socket_t, readfd1: curl_socket_t, writefd: curl_socket_t, timeout_ms: i64) callconv(.c) c_int;

    pub extern fn Curl_cf_create(pcf: *?*CurlCfilter, cft: *const CurlCftype, ctx: ?*anyopaque) callconv(.c) CURLcode;
    pub extern fn Curl_cf_def_cntrl(cf: *CurlCfilter, data: ?*CurlEasy, event: c_int, arg1: c_int, arg2: ?*anyopaque) callconv(.c) CURLcode;
    pub extern fn Curl_cf_def_conn_is_alive(cf: *CurlCfilter, data: ?*CurlEasy, input_pending: *bool) callconv(.c) bool;
    pub extern fn Curl_cf_def_conn_keep_alive(cf: *CurlCfilter, data: ?*CurlEasy) callconv(.c) CURLcode;
    pub extern fn Curl_cf_def_query(cf: *CurlCfilter, data: ?*CurlEasy, query: c_int, pres1: ?*c_int, pres2: ?*anyopaque) callconv(.c) CURLcode;

    pub extern fn Curl_conn_cf_add(data: ?*CurlEasy, conn: ?*ConnectData, sockindex: i8, cf: *CurlCfilter) callconv(.c) void;
    pub extern fn Curl_conn_cf_insert_after(cf_at: *CurlCfilter, cf_new: *CurlCfilter) callconv(.c) void;
    pub extern fn Curl_conn_cf_discard(pcf: *?*CurlCfilter, data: ?*CurlEasy) callconv(.c) void;
    pub extern fn Curl_conn_cf_discard_chain(pcf: *?*CurlCfilter, data: ?*CurlEasy) callconv(.c) void;
    pub extern fn Curl_conn_cf_connect(cf: ?*CurlCfilter, data: ?*CurlEasy, done: *bool) callconv(.c) CURLcode;
    pub extern fn Curl_conn_cf_adjust_pollset(cf: ?*CurlCfilter, data: ?*CurlEasy, ps: ?*EasyPollset) callconv(.c) void;
    pub extern fn Curl_conn_cf_data_pending(cf: ?*CurlCfilter, data: ?*const CurlEasy) callconv(.c) bool;
    pub extern fn Curl_conn_cf_send(cf: ?*CurlCfilter, data: ?*CurlEasy, buf: ?*const anyopaque, len: usize, eos: bool, pnwritten: *usize) callconv(.c) CURLcode;
    pub extern fn Curl_conn_cf_recv(cf: ?*CurlCfilter, data: ?*CurlEasy, buf: [*]u8, len: usize, pnread: *usize) callconv(.c) CURLcode;
    pub extern fn Curl_conn_cf_cntrl(cf: ?*CurlCfilter, data: ?*CurlEasy, ignore_result: bool, event: c_int, arg1: c_int, arg2: ?*anyopaque) callconv(.c) CURLcode;
    pub extern fn Curl_conn_cf_get_socket(cf: ?*CurlCfilter, data: ?*CurlEasy) callconv(.c) curl_socket_t;
    pub extern fn Curl_conn_cf_get_transport(cf: ?*CurlCfilter, data: ?*CurlEasy) callconv(.c) u8;
    pub extern fn Curl_conn_cf_poll(cf: *CurlCfilter, data: ?*CurlEasy, timeout_ms: i64) callconv(.c) c_int;
    pub extern fn Curl_conn_get_origin(conn: ?*ConnectData, sockindex: i8) callconv(.c) ?*CurlPeer;
    pub extern fn Curl_conn_get_first_peer(conn: ?*ConnectData, sockindex: i8) callconv(.c) ?*CurlPeer;
    pub extern fn Curl_conn_is_ip_connected(data: ?*CurlEasy, sockindex: i8) callconv(.c) bool;
    pub extern fn Curl_conn_is_connect_only(conn: ?*const ConnectData) callconv(.c) bool;
    pub extern fn Curl_h2_conn_is_connect_only(conn: ?*const ConnectData) callconv(.c) bool;
    pub extern fn Curl_http_acc_conn_scheme_family(conn: ?*const ConnectData) callconv(.c) u64;

    pub extern fn Curl_pollset_set(data: ?*CurlEasy, ps: ?*EasyPollset, sock: curl_socket_t, do_in: bool, do_out: bool) callconv(.c) CURLcode;

    pub extern fn Curl_cshutdn_timeleft_ms(data: ?*CurlEasy, conn: ?*ConnectData, sockindex: i8) callconv(.c) i64;
    pub extern fn Curl_cshutdn_start_timer(data: ?*CurlEasy, sockindex: i8, timeout_ms: i64) callconv(.c) void;
    pub extern fn Curl_cshutdn_clear_timer(data: ?*CurlEasy, sockindex: i8) callconv(.c) void;

    pub extern fn Curl_hash_pick(h: ?*anyopaque, key: ?*const anyopaque, key_len: usize) callconv(.c) ?*anyopaque;
    pub extern fn Curl_hash_add(h: ?*anyopaque, key: ?*const anyopaque, key_len: usize, p: ?*anyopaque) callconv(.c) ?*anyopaque;
    pub extern fn Curl_hash_add2(
        h: ?*anyopaque,
        key: ?*const anyopaque,
        key_len: usize,
        p: ?*anyopaque,
        dtor: ?*const fn (key: *const anyopaque, key_len: usize, p: *anyopaque) callconv(.c) void,
    ) callconv(.c) ?*anyopaque;
    pub extern fn curlx_str_newline(linep: *?[*:0]const u8) callconv(.c) c_int;
    pub extern fn curlx_str_number(linep: *[*:0]const u8, nump: *i64, max: i64) callconv(.c) c_int;
    pub extern fn curlx_gmtime(t: i64, store: *anyopaque) callconv(.c) CURLcode;
    pub extern fn Curl_extract_certinfo(data: ?*CurlEasy, certnum: c_int, beg: ?[*]const u8, end: ?[*]const u8) callconv(.c) CURLcode;
    pub extern fn Curl_vtls_apple_verify(
        cf: *CurlCfilter,
        data: ?*CurlEasy,
        peer: *const SslPeer,
        num_certs: usize,
        der_cb: *const fn (*CurlCfilter, ?*CurlEasy, ?*anyopaque, usize, *?[*]u8, *usize) callconv(.c) CURLcode,
        cb_user_data: ?*anyopaque,
        ocsp_buf: ?[*]const u8,
        ocsp_len: usize,
        require_ocsp: bool,
    ) callconv(.c) CURLcode;
    pub extern fn Curl_rand_bytes(data: ?*anyopaque, rnd: [*]u8, num: usize) callconv(.c) CURLcode;
    pub extern fn Curl_rand_alnum(data: ?*anyopaque, rnd: [*]u8, num: usize) callconv(.c) CURLcode;

    pub fn Curl_safefree(ptr: ?*?*anyopaque) callconv(.c) void {
        if (ptr) |p| {
            if (p.*) |val| {
                mem.free(val);
                p.* = null;
            }
        }
    }

    // Accessor helpers in lib/url.c (#ifdef USE_SSL)
    pub extern fn Curl_vtls_acc_data_certs(data: ?*CurlEasy) callconv(.c) ?*CurlCertinfo;
    pub extern fn Curl_vtls_acc_data_conn(data: ?*CurlEasy) callconv(.c) ?*ConnectData;
    pub extern fn Curl_vtls_acc_conn_cfilter(conn: ?*ConnectData, sockindex: i8) callconv(.c) ?*CurlCfilter;
    pub extern fn Curl_vtls_acc_multi_proto_hash(data: ?*CurlEasy) callconv(.c) ?*anyopaque;
    pub extern fn Curl_vtls_acc_conn_get_ssl_context(conn: ?*ConnectData) callconv(.c) ?*anyopaque;
    pub extern fn Curl_vtls_acc_conn_set_ssl_context(conn: ?*ConnectData, ctx: ?*anyopaque) callconv(.c) void;
    pub extern fn Curl_vtls_acc_data_ssl_easy_config(data: ?*CurlEasy, is_proxy: bool) callconv(.c) ?*SslEasyConfig;
    pub extern fn Curl_vtls_acc_conn_ssl_filter_config(conn: ?*ConnectData, is_proxy: bool) callconv(.c) ?*SslFilterConfig;
    pub extern fn Curl_vtls_acc_cf_ssl_create_params(data: ?*CurlEasy, conn: ?*ConnectData, wanted: *u8, preferred: *u8, only_10: *bool, use_alpn: *bool) callconv(.c) void;
    pub extern fn Curl_vtls_acc_cf_proxy_create_params(data: ?*CurlEasy, conn: ?*ConnectData, wanted: *u8, use_alpn: *bool) callconv(.c) void;
    pub extern fn Curl_vtls_acc_conn_via_peer(conn: ?*ConnectData, sockindex: i8) callconv(.c) ?*CurlPeer;
    pub extern fn Curl_vtls_acc_conn_set_multiplex(conn: ?*ConnectData, val: bool) callconv(.c) void;
    pub extern fn Curl_vtls_acc_conn_set_httpversion_seen(conn: ?*ConnectData, ver: u8) callconv(.c) void;
    pub extern fn Curl_vtls_acc_conn_set_proxy_ssl_connected(conn: ?*ConnectData, sockindex: i8, val: bool) callconv(.c) void;
    pub extern fn Curl_vtls_acc_scache_params(data: ?*CurlEasy, pscache: *?*CurlSslScache, has_share_scache: *bool, ptrc_feat: *?*CurlTrcFeat) callconv(.c) void;
    pub extern fn Curl_vtls_acc_get_scache(data: ?*CurlEasy) callconv(.c) ?*CurlSslScache;
    pub extern fn Curl_vtls_acc_pinned_pubkey(data: ?*CurlEasy, is_proxy: bool) callconv(.c) ?[*:0]const u8;
    pub extern fn Curl_vtls_acc_ssl_certinfo(data: ?*CurlEasy) callconv(.c) bool;
    pub extern fn Curl_vtls_acc_ssl_fsslctx(data: ?*CurlEasy, pfsslctx: *?*const anyopaque, pfsslctxp: *?*anyopaque) callconv(.c) bool;
    pub extern fn Curl_vtls_acc_ssl_key_passwd(data: ?*CurlEasy, is_proxy: bool) callconv(.c) ?[*:0]const u8;
    pub extern fn Curl_vtls_acc_ssl_key(data: ?*CurlEasy, is_proxy: bool) callconv(.c) ?[*:0]const u8;
    pub extern fn Curl_vtls_acc_ssl_key_type(data: ?*CurlEasy, is_proxy: bool) callconv(.c) ?[*:0]const u8;
    pub extern fn Curl_vtls_acc_ssl_cert(data: ?*CurlEasy, is_proxy: bool) callconv(.c) ?[*:0]const u8;
    pub extern fn Curl_vtls_acc_ssl_cert_type(data: ?*CurlEasy, is_proxy: bool) callconv(.c) ?[*:0]const u8;
    pub extern fn Curl_vtls_acc_ssl_cert_blob(data: ?*CurlEasy, is_proxy: bool) callconv(.c) ?*const CurlBlob;
    pub extern fn Curl_vtls_acc_ssl_ca_info_blob(data: ?*CurlEasy, is_proxy: bool) callconv(.c) ?*const CurlBlob;
    pub extern fn Curl_vtls_acc_ssl_cainfo(data: ?*CurlEasy, is_proxy: bool) callconv(.c) ?[*:0]const u8;
    pub extern fn Curl_vtls_acc_ssl_capath(data: ?*CurlEasy, is_proxy: bool) callconv(.c) ?[*:0]const u8;
    pub extern fn Curl_vtls_acc_ssl_cipher_list(data: ?*CurlEasy, is_proxy: bool) callconv(.c) ?[*:0]const u8;
    pub extern fn Curl_vtls_acc_ssl_cipher13_list(data: ?*CurlEasy, is_proxy: bool) callconv(.c) ?[*:0]const u8;
    pub extern fn Curl_vtls_acc_ssl_ec_curves(data: ?*CurlEasy) callconv(.c) ?[*:0]const u8;
    pub extern fn Curl_vtls_acc_ssl_signature_algorithms(data: ?*CurlEasy) callconv(.c) ?[*:0]const u8;
    pub extern fn Curl_vtls_acc_ssl_crlfile(data: ?*CurlEasy, is_proxy: bool) callconv(.c) ?[*:0]const u8;
    pub extern fn Curl_vtls_acc_ssl_issuercert(data: ?*CurlEasy, is_proxy: bool) callconv(.c) ?[*:0]const u8;
    pub extern fn Curl_vtls_acc_ssl_issuercert_blob(data: ?*CurlEasy, is_proxy: bool) callconv(.c) ?*const CurlBlob;
    pub extern fn Curl_vtls_acc_ssl_username(data: ?*CurlEasy, is_proxy: bool) callconv(.c) ?[*:0]const u8;
    pub extern fn Curl_vtls_acc_ssl_password(data: ?*CurlEasy, is_proxy: bool) callconv(.c) ?[*:0]const u8;
    pub extern fn Curl_vtls_acc_ssl_engine(data: ?*CurlEasy) callconv(.c) ?[*:0]const u8;
    pub extern fn Curl_vtls_acc_ssl_engine_default(data: ?*CurlEasy) callconv(.c) bool;
    pub extern fn Curl_vtls_acc_ssl_buffer_size(data: ?*CurlEasy) callconv(.c) c_int;
    pub extern fn Curl_vtls_acc_ssl_ca_cache_timeout(data: ?*CurlEasy) callconv(.c) c_int;
};

// ============================================================================
// 1. lib/vtls/vtls.c — Generic SSL Layer & Connection Filters
// ============================================================================

fn makeAlpnEntry(comptime str: []const u8) [ALPN_NAME_MAX]u8 {
    var entry: [ALPN_NAME_MAX]u8 = @splat(0);
    @memcpy(entry[0..str.len], str);
    return entry;
}

const ALPN_SPEC_H11 = AlpnSpec{
    .entries = .{
        makeAlpnEntry("http/1.1"),
        @splat(0),
        @splat(0),
    },
    .count = 1,
};

const ALPN_SPEC_H10_H11 = AlpnSpec{
    .entries = .{
        makeAlpnEntry("http/1.0"),
        makeAlpnEntry("http/1.1"),
        @splat(0),
    },
    .count = 2,
};

const ALPN_SPEC_H2 = AlpnSpec{
    .entries = .{
        makeAlpnEntry("h2"),
        @splat(0),
        @splat(0),
    },
    .count = 1,
};

const ALPN_SPEC_H2_H11 = AlpnSpec{
    .entries = .{
        makeAlpnEntry("h2"),
        makeAlpnEntry("http/1.1"),
        @splat(0),
    },
    .count = 2,
};

const ALPN_SPEC_H11_H2 = AlpnSpec{
    .entries = .{
        makeAlpnEntry("http/1.1"),
        makeAlpnEntry("h2"),
        @splat(0),
    },
    .count = 2,
};

fn alpnGetSpec(wanted: u8, preferred: u8, only_http_10: bool, use_alpn: bool) ?*const AlpnSpec {
    if (!use_alpn) return null;
    if (only_http_10 and (wanted & CURL_HTTP_V1x) != 0)
        return &ALPN_SPEC_H10_H11;
    if (backend_options.nghttp2) {
        if ((wanted & CURL_HTTP_V2x) != 0) {
            if ((wanted & CURL_HTTP_V1x) != 0) {
                return if (preferred == CURL_HTTP_V1x) &ALPN_SPEC_H11_H2 else &ALPN_SPEC_H2_H11;
            }
            return &ALPN_SPEC_H2;
        }
    }
    return &ALPN_SPEC_H11;
}

const empty_backends = [1]?*const CurlSslBackendInfo{null};

var active_backends = [2]?*const CurlSslBackendInfo{
    null,
    null,
};

var init_ssl: bool = false;

pub export fn Curl_ssl_backend() callconv(.c) c_uint {
    if (comptime use_ssl) {
        _ = multisslSetup(null);
        return vtls_impl.Curl_ssl.info.id;
    } else {
        return CURLSSLBACKEND_NONE;
    }
}

pub export fn Curl_init_sslset_nolock(
    id: c_uint,
    name: ?[*:0]const u8,
    avail: ?*?[*]?*const CurlSslBackendInfo,
) callconv(.c) c_uint {
    if (comptime use_ssl) {
        if (avail) |a| {
            active_backends[0] = &vtls_impl.Curl_ssl.info;
            active_backends[1] = null;
            a.* = &active_backends;
        }
        if (id == CURLSSLBACKEND_NONE and name == null)
            return CURLSSLSET_OK;
        const b = vtls_impl.Curl_ssl;
        if (b.info.id == id or (name != null and primitives.curl_strequal(b.info.name, name.?) != 0)) {
            _ = multisslSetup(b);
            return CURLSSLSET_OK;
        }
        return CURLSSLSET_UNKNOWN_BACKEND;
    } else {
        if (avail) |a| {
            a.* = @constCast(&empty_backends);
        }
        return CURLSSLSET_NO_BACKENDS;
    }
}

fn multisslSetup(backend: ?*const CurlSsl) c_int {
    if (comptime use_ssl) {
        if (vtls_impl.Curl_ssl != &vtls_impl.Curl_ssl_multi)
            return 1;
        if (backend) |b| {
            vtls_impl.Curl_ssl = b;
            return 0;
        }
        vtls_impl.Curl_ssl = switch (backend_options.ssl) {
            .schannel => &schannel_backend.Curl_ssl_schannel,
            .openssl => if (backend_options.bundled) &bundled_tls.Curl_ssl_zig_tls else &openssl_backend.Curl_ssl_openssl,
            .mbedtls => &mbedtls_backend.Curl_ssl_mbedtls,
            .gnutls => &vtls_gtls.Curl_ssl_gnutls,
            .rustls => &vtls_rustls.Curl_ssl_rustls,
            .wolfssl => &vtls_wolfssl.Curl_ssl_wolfssl,
            else => unreachable,
        };
        return 0;
    } else {
        return 1;
    }
}

pub export fn Curl_ssl_supports(data: ?*CurlEasy, ssl_option: c_uint) callconv(.c) bool {
    _ = data;
    if (comptime use_ssl) {
        return (vtls_impl.Curl_ssl.supports & ssl_option) != 0;
    } else {
        return false;
    }
}

pub export fn Curl_cf_ssl_insert_after(
    cf_at: *CurlCfilter,
    data: ?*CurlEasy,
    origin: ?*CurlPeer,
    peer: ?*CurlPeer,
) callconv(.c) CURLcode {
    if (comptime use_ssl) {
        return vtls_impl.cfSslInsertAfter(cf_at, data, origin, peer);
    } else {
        return CURLE_NOT_BUILT_IN;
    }
}

pub export fn Curl_cf_ssl_proxy_insert_after(
    cf_at: *CurlCfilter,
    data: ?*CurlEasy,
    peer: ?*CurlPeer,
) callconv(.c) CURLcode {
    if (comptime use_ssl) {
        return vtls_impl.cfSslProxyInsertAfter(cf_at, data, peer);
    } else {
        return CURLE_NOT_BUILT_IN;
    }
}

// ============================================================================
// Pure ALPN & PEM-to-DER Helpers (available for unit tests and USE_SSL)
// ============================================================================

pub fn alpnToProtoBuf(buf: *AlpnProtoBuf, spec_opt: ?*const AlpnSpec) CURLcode {
    @memset(std.mem.asBytes(buf), 0);
    const spec = spec_opt orelse return CURLE_OK;
    var off: usize = 0;
    var i: usize = 0;
    while (i < spec.count) : (i += 1) {
        const entry_ptr: [*:0]const u8 = @ptrCast(&spec.entries[i]);
        const len = std.mem.len(entry_ptr);
        if (len >= ALPN_NAME_MAX)
            return CURLE_FAILED_INIT;
        const blen: u8 = @intCast(len);
        if (off + blen + 1 >= buf.data.len)
            return CURLE_FAILED_INIT;
        buf.data[off] = blen;
        off += 1;
        @memcpy(buf.data[off .. off + blen], entry_ptr[0..blen]);
        off += blen;
    }
    buf.len = @intCast(off);
    return CURLE_OK;
}

pub fn alpnToProtoStr(buf: *AlpnProtoBuf, spec_opt: ?*const AlpnSpec) CURLcode {
    @memset(std.mem.asBytes(buf), 0);
    const spec = spec_opt orelse return CURLE_OK;
    var off: usize = 0;
    var i: usize = 0;
    while (i < spec.count) : (i += 1) {
        const entry_ptr: [*:0]const u8 = @ptrCast(&spec.entries[i]);
        const len = std.mem.len(entry_ptr);
        if (len >= ALPN_NAME_MAX)
            return CURLE_FAILED_INIT;
        if (off + len + 2 >= buf.data.len)
            return CURLE_FAILED_INIT;
        if (off > 0) {
            buf.data[off] = ',';
            off += 1;
        }
        @memcpy(buf.data[off .. off + len], entry_ptr[0..len]);
        off += len;
    }
    buf.data[off] = 0;
    buf.len = @intCast(off);
    return CURLE_OK;
}

pub fn alpnContainsProto(spec_opt: ?*const AlpnSpec, proto_opt: ?[*:0]const u8) bool {
    const spec = spec_opt orelse return false;
    const proto = proto_opt orelse return false;
    const plen = std.mem.len(proto);
    if (plen == 0) return false;
    var i: usize = 0;
    while (i < spec.count) : (i += 1) {
        const entry_ptr: [*:0]const u8 = @ptrCast(&spec.entries[i]);
        const slen = std.mem.len(entry_ptr);
        if (slen == plen and std.mem.eql(u8, proto[0..plen], entry_ptr[0..plen]))
            return true;
    }
    return false;
}

pub fn alpnRestrictTo(spec: *AlpnSpec, proto: [*:0]const u8) void {
    const plen = std.mem.len(proto);
    if (plen < ALPN_NAME_MAX) {
        @memcpy(spec.entries[0][0 .. plen + 1], proto[0 .. plen + 1]);
        spec.count = 1;
    }
}

pub fn alpnCopy(dest: *AlpnSpec, src_opt: ?*const AlpnSpec) void {
    if (src_opt) |src| {
        dest.* = src.*;
    } else {
        @memset(std.mem.asBytes(dest), 0);
    }
}

pub fn pubkeyPemToDer(pem_opt: ?[*:0]const u8, der: *?[*]u8, der_len: *usize) CURLcode {
    const pem = pem_opt orelse return CURLE_BAD_CONTENT_ENCODING;
    const pem_slice = std.mem.span(pem);

    const begin_marker = "-----BEGIN PUBLIC KEY-----";
    const end_marker = "\n-----END PUBLIC KEY-----";

    const begin_idx = std.mem.indexOf(u8, pem_slice, begin_marker) orelse return CURLE_BAD_CONTENT_ENCODING;
    if (begin_idx > 0 and pem_slice[begin_idx - 1] != '\n')
        return CURLE_BAD_CONTENT_ENCODING;

    var pem_count = begin_idx + begin_marker.len;
    const rel_end = std.mem.indexOf(u8, pem_slice[pem_count..], end_marker) orelse return CURLE_BAD_CONTENT_ENCODING;
    const pem_len = pem_count + rel_end;

    var pbuf: DynBuf = undefined;
    containers.curlx_dyn_init(&pbuf, MAX_PINNED_PUBKEY_SIZE);

    while (pem_count < pem_len) : (pem_count += 1) {
        const ch = pem_slice[pem_count];
        if (ch != '\n' and ch != '\r') {
            const result = containers.curlx_dyn_addn(&pbuf, &pem_slice[pem_count], 1);
            if (result != CURLE_OK)
                return result;
        }
    }

    var result: CURLcode = CURLE_BAD_CONTENT_ENCODING;
    if (containers.curlx_dyn_len(&pbuf) > 0) {
        if (containers.curlx_dyn_ptr(&pbuf)) |ptr| {
            result = c_ext.curlx_base64_decode(ptr, der, der_len);
        }
        containers.curlx_dyn_free(&pbuf);
    }
    return result;
}

// ============================================================================
// USE_SSL Implementation
// ============================================================================

const vtls_core_impl = struct {
    pub fn Curl_ssl_init() callconv(.c) c_int {
        if (init_ssl) return 1;
        init_ssl = true;
        if (vtls_impl.Curl_ssl.init) |init_fn| {
            return init_fn();
        }
        return 1;
    }

    pub fn Curl_ssl_cleanup() callconv(.c) void {
        if (init_ssl) {
            if (vtls_impl.Curl_ssl.cleanup) |cleanup_fn| {
                cleanup_fn();
            }
            init_ssl = false;
        }
    }

    pub fn Curl_ssl_version(buffer: [*]u8, size: usize) callconv(.c) void {
        _ = vtls_impl.Curl_ssl.version(buffer, size);
    }

    pub fn Curl_ssl_check_cxn(conn: ?*ConnectData) callconv(.c) c_int {
        _ = conn;
        return 1;
    }

    pub fn Curl_ssl_Shutdown(data: ?*CurlEasy, sockindex: i8) callconv(.c) CURLcode {
        return Curl_ssl_cfilter_remove(data, sockindex, true);
    }

    pub fn Curl_ssl_data_pending(conn: ?*const ConnectData, sockindex: c_int) callconv(.c) bool {
        var cf = c_ext.Curl_vtls_acc_conn_cfilter(@constCast(conn), @intCast(sockindex));
        while (cf) |cur| : (cf = cur.next) {
            if (cur.cft == &vtls_impl.Curl_cft_ssl or cur.cft == &vtls_impl.Curl_cft_ssl_proxy) {
                if (vtls_impl.Curl_ssl.data_pending) |dp| {
                    return dp(cur, null);
                }
            }
        }
        return false;
    }

    pub fn Curl_ssl_get_internals(connssl: *SslConnectData, info: c_uint) callconv(.c) ?*anyopaque {
        if (vtls_impl.Curl_ssl.get_internals) |gi| {
            return gi(connssl, info);
        }
        return null;
    }

    pub fn Curl_ssl_engines_list(data: ?*CurlEasy) callconv(.c) ?*curl_slist {
        if (vtls_impl.Curl_ssl.engines_list) |el| {
            return el(data);
        }
        return null;
    }

    pub fn Curl_ssl_initsessions(data: ?*CurlEasy, amount: usize) callconv(.c) CURLcode {
        _ = data;
        _ = amount;
        return CURLE_OK;
    }

    pub fn Curl_ssl_free_certinfo(data: ?*CurlEasy) callconv(.c) void {
        const ci = c_ext.Curl_vtls_acc_data_certs(data) orelse return;
        if (ci.num_of_certs != 0) {
            if (ci.certinfo) |table| {
                const count: usize = @intCast(ci.num_of_certs);
                for (0..count) |i| {
                    c_ext.curl_slist_free_all(table[i]);
                    table[i] = null;
                }
                mem.free(@ptrCast(table));
            }
            ci.certinfo = null;
            ci.num_of_certs = 0;
        }
    }

    pub fn Curl_ssl_init_certinfo(data: ?*CurlEasy, num: c_int) callconv(.c) CURLcode {
        const ci = c_ext.Curl_vtls_acc_data_certs(data) orelse return CURLE_BAD_FUNCTION_ARGUMENT;
        Curl_ssl_free_certinfo(data);
        const raw = mem.calloc(@intCast(num), @sizeOf(?*curl_slist)) orelse return CURLE_OUT_OF_MEMORY;
        ci.num_of_certs = num;
        ci.certinfo = @ptrCast(@alignCast(raw));
        return CURLE_OK;
    }

    pub fn Curl_ssl_push_certinfo_len(
        data: ?*CurlEasy,
        certnum: c_int,
        label: [*:0]const u8,
        value: [*]const u8,
        valuelen: usize,
    ) callconv(.c) CURLcode {
        const ci = c_ext.Curl_vtls_acc_data_certs(data) orelse return CURLE_BAD_FUNCTION_ARGUMENT;
        const table = ci.certinfo orelse return CURLE_BAD_FUNCTION_ARGUMENT;
        const idx: usize = @intCast(certnum);

        var build: DynBuf = undefined;
        containers.curlx_dyn_init(&build, CURL_X509_STR_MAX);

        if (containers.curlx_dyn_add(&build, label) != CURLE_OK or
            containers.curlx_dyn_addn(&build, ":", 1) != CURLE_OK or
            containers.curlx_dyn_addn(&build, value, valuelen) != CURLE_OK)
        {
            return CURLE_OUT_OF_MEMORY;
        }

        const ptr = containers.curlx_dyn_ptr(&build) orelse {
            containers.curlx_dyn_free(&build);
            return CURLE_OUT_OF_MEMORY;
        };
        const nl = c_ext.Curl_slist_append_nodup(table[idx], ptr);
        if (nl == null) {
            containers.curlx_dyn_free(&build);
            c_ext.curl_slist_free_all(table[idx]);
            table[idx] = null;
            return CURLE_OUT_OF_MEMORY;
        }
        table[idx] = nl;
        return CURLE_OK;
    }

    pub fn Curl_ssl_push_certinfo(
        data: ?*CurlEasy,
        certnum: c_int,
        label: [*:0]const u8,
        value: [*:0]const u8,
    ) callconv(.c) CURLcode {
        return Curl_ssl_push_certinfo_len(data, certnum, label, value, std.mem.len(value));
    }

    pub fn Curl_ssl_random(data: ?*CurlEasy, buffer: [*]u8, length: usize) callconv(.c) CURLcode {
        if (vtls_impl.Curl_ssl.random) |rand_fn| {
            return rand_fn(data, buffer, length);
        }
        return CURLE_NOT_BUILT_IN;
    }

    pub fn Curl_ssl_md5sum(input: [*]const u8, inputlen: usize, md5sum: [*]u8, md5len: usize) callconv(.c) CURLcode {
        if (md5len < 16) return CURLE_BAD_FUNCTION_ARGUMENT;
        var digest: [16]u8 = undefined;
        std.crypto.hash.Md5.hash(input[0..inputlen], &digest, .{});
        @memcpy(md5sum[0..16], &digest);
        return CURLE_OK;
    }

    pub fn Curl_ssl_sha256sum(input: [*]const u8, inputlen: usize, sha256sum: [*]u8, sha256len: usize) callconv(.c) CURLcode {
        if (vtls_impl.Curl_ssl.sha256sum) |sha_fn| {
            return sha_fn(input, inputlen, sha256sum, sha256len);
        }
        if (sha256len < 32) return CURLE_BAD_FUNCTION_ARGUMENT;
        var digest: [32]u8 = undefined;
        std.crypto.hash.sha2.Sha256.hash(input[0..inputlen], &digest, .{});
        @memcpy(sha256sum[0..32], &digest);
        return CURLE_OK;
    }

    pub fn Curl_pin_peer_pubkey(
        data: ?*CurlEasy,
        pinnedpubkey_opt: ?[*:0]const u8,
        pubkey_opt: ?[*]const u8,
        pubkeylen: usize,
    ) callconv(.c) CURLcode {
        const pinnedpubkey = pinnedpubkey_opt orelse return CURLE_OK;
        const pubkey = pubkey_opt orelse return CURLE_SSL_PINNEDPUBKEYNOTMATCH;
        if (pubkeylen == 0) return CURLE_SSL_PINNEDPUBKEYNOTMATCH;

        const pinned_slice = std.mem.span(pinnedpubkey);
        var result: CURLcode = CURLE_SSL_PINNEDPUBKEYNOTMATCH;

        if (std.mem.startsWith(u8, pinned_slice, "sha256//")) {
            const sha_fn = vtls_impl.Curl_ssl.sha256sum orelse return result;
            const raw_digest = mem.malloc(CURL_SHA256_DIGEST_LENGTH) orelse return CURLE_OUT_OF_MEMORY;
            const sha256sumdigest: [*]u8 = @ptrCast(raw_digest);

            var encode = sha_fn(pubkey, pubkeylen, sha256sumdigest, CURL_SHA256_DIGEST_LENGTH);
            var cert_hash: ?[*:0]u8 = null;
            var cert_hash_len: usize = 0;

            if (encode == CURLE_OK) {
                encode = c_ext.curlx_base64_encode(sha256sumdigest, CURL_SHA256_DIGEST_LENGTH, &cert_hash, &cert_hash_len);
            }
            mem.free(raw_digest);
            if (encode != CURLE_OK) return encode;

            if (cert_hash) |ch| {
                c_ext.Curl_infof(data, " public key hash: sha256//%s", ch);
                var rest: []const u8 = pinned_slice;
                while (std.mem.startsWith(u8, rest, "sha256//")) {
                    rest = rest["sha256//".len..];
                    const semi = std.mem.indexOfScalar(u8, rest, ';');
                    const pinned_hash = if (semi) |idx| rest[0..idx] else rest;
                    if (cert_hash_len == pinned_hash.len and std.mem.eql(u8, ch[0..cert_hash_len], pinned_hash)) {
                        result = CURLE_OK;
                        break;
                    }
                    if (semi) |idx| {
                        rest = rest[idx + 1 ..];
                    } else {
                        break;
                    }
                }
                mem.free(ch);
            }
        } else {
            const fp = c_ext.fopen(pinnedpubkey, "rb") orelse return result;
            defer _ = c_ext.fclose(fp);

            var buf: DynBuf = undefined;
            containers.curlx_dyn_init(&buf, MAX_PINNED_PUBKEY_SIZE);
            defer containers.curlx_dyn_free(&buf);

            var pem_ptr: ?[*]u8 = null;
            defer if (pem_ptr) |p| mem.free(p);

            if (c_ext.fseek(fp, 0, 2) != 0) return result;
            const filesize = c_ext.ftell(fp);
            if (c_ext.fseek(fp, 0, 0) != 0) return result;
            if (filesize < 0 or filesize > @as(c_long, @intCast(MAX_PINNED_PUBKEY_SIZE))) return result;

            const size: usize = @intCast(filesize);
            if (pubkeylen > size) return result;

            var left = size;
            while (left > 0) {
                var buffer: [1024]u8 = undefined;
                const want = @min(left, buffer.len);
                if (c_ext.fread(&buffer, 1, want, fp) != want) return result;
                if (containers.curlx_dyn_addn(&buf, &buffer, want) != CURLE_OK) return result;
                left -= want;
            }

            if (pubkeylen == size) {
                if (containers.curlx_dyn_ptr(&buf)) |bptr| {
                    if (std.mem.eql(u8, pubkey[0..pubkeylen], bptr[0..pubkeylen])) {
                        result = CURLE_OK;
                    }
                }
                return result;
            }

            var pem_len: usize = 0;
            const pem_read = pubkeyPemToDer(containers.curlx_dyn_ptr(&buf), &pem_ptr, &pem_len);
            if (pem_read != CURLE_OK) return result;

            if (pubkeylen == pem_len) {
                if (pem_ptr) |pptr| {
                    if (std.mem.eql(u8, pubkey[0..pubkeylen], pptr[0..pubkeylen])) {
                        result = CURLE_OK;
                    }
                }
            }
        }
        return result;
    }

    pub fn Curl_ssl_cert_status_request() callconv(.c) bool {
        if (vtls_impl.Curl_ssl.cert_status_request) |csr| {
            return csr();
        }
        return false;
    }

    pub fn Curl_ssl_false_start(data: ?*CurlEasy) callconv(.c) bool {
        _ = data;
        return false;
    }

    pub fn Curl_ssl_setup_x509_store(cf: *CurlCfilter, data: ?*CurlEasy, ssl_ctx: ?*anyopaque) callconv(.c) CURLcode {
        if (comptime (backend_options.ssl == .openssl and !backend_options.bundled)) {
            return openssl_backend.Curl_ossl_setup_x509_store(cf, data, ssl_ctx);
        } else if (comptime backend_options.ssl == .wolfssl) {
            return vtls_wolfssl.Curl_wssl_setup_x509_store(cf, data, ssl_ctx);
        }
        return CURLE_OK;
    }

    pub fn Curl_ssl_get_x509_store(cf: *CurlCfilter, data: ?*CurlEasy) callconv(.c) ?*anyopaque {
        if (comptime (backend_options.ssl == .openssl and !backend_options.bundled)) {
            if (@hasDecl(openssl_backend, "Curl_ossl_get_x509_store")) {
                return openssl_backend.Curl_ossl_get_x509_store(cf, data);
            }
            if (@hasDecl(openssl_backend, "Curl_ssl_get_x509_store")) {
                return openssl_backend.Curl_ssl_get_x509_store(cf, data);
            }
            const connssl: *SslConnectData = @ptrCast(@alignCast(cf.ctx orelse return null));
            const octx: *openssl_backend.OsslCtx = @ptrCast(@alignCast(connssl.backend orelse return null));
            if (octx.ssl_ctx) |ctx| {
                return openssl_backend.ossl_ext.SSL_CTX_get_cert_store(ctx);
            }
        }
        return null;
    }

    pub fn Curl_ssl_get_channel_binding(data: ?*CurlEasy, sockindex: i8, binding: *DynBuf) callconv(.c) CURLcode {
        if (vtls_impl.Curl_ssl.get_channel_binding) |cb| {
            return cb(data, sockindex, binding);
        }
        return CURLE_OK;
    }

    pub fn Curl_ssl_close_all(data: ?*CurlEasy) callconv(.c) void {
        if (vtls_impl.Curl_ssl.close_all) |ca| {
            ca(data);
        }
    }

    pub fn Curl_ssl_adjust_pollset(cf: *CurlCfilter, data: ?*CurlEasy, ps: ?*EasyPollset) callconv(.c) CURLcode {
        const connssl: *SslConnectData = @ptrCast(@alignCast(cf.ctx orelse return CURLE_OK));
        if (connssl.io_need != 0) {
            const sock = c_ext.Curl_conn_cf_get_socket(cf.next, data);
            if (sock != CURL_SOCKET_BAD) {
                if ((connssl.io_need & CURL_SSL_IO_NEED_SEND) != 0) {
                    return c_ext.Curl_pollset_set(data, ps, sock, false, true);
                } else {
                    return c_ext.Curl_pollset_set(data, ps, sock, true, false);
                }
            }
        }
        return CURLE_OK;
    }

    pub fn multisslInit() callconv(.c) c_int {
        if (multisslSetup(null) != 0) return 1;
        if (vtls_impl.Curl_ssl.init) |init_fn| return init_fn();
        return 1;
    }

    pub fn multisslVersion(buffer: [*]u8, size: usize) callconv(.c) usize {
        if (multisslSetup(null) != 0) return 0;
        return vtls_impl.Curl_ssl.version(buffer, size);
    }

    pub fn multisslRandom(data: ?*CurlEasy, entropy: [*]u8, length: usize) callconv(.c) CURLcode {
        if (multisslSetup(null) != 0) return CURLE_FAILED_INIT;
        if (vtls_impl.Curl_ssl.random) |rand_fn| return rand_fn(data, entropy, length);
        return CURLE_NOT_BUILT_IN;
    }

    pub fn multisslConnect(cf: *CurlCfilter, data: ?*CurlEasy, done: *bool) callconv(.c) CURLcode {
        if (multisslSetup(null) != 0) return CURLE_FAILED_INIT;
        return vtls_impl.Curl_ssl.do_connect(cf, data, done);
    }

    pub fn multisslAdjustPollset(cf: *CurlCfilter, data: ?*CurlEasy, ps: ?*EasyPollset) callconv(.c) CURLcode {
        if (multisslSetup(null) != 0) return CURLE_OK;
        return vtls_impl.Curl_ssl.adjust_pollset(cf, data, ps);
    }

    pub fn multisslGetInternals(connssl: *SslConnectData, info: c_uint) callconv(.c) ?*anyopaque {
        if (multisslSetup(null) != 0) return null;
        if (vtls_impl.Curl_ssl.get_internals) |gi| return gi(connssl, info);
        return null;
    }

    pub fn multisslClose(cf: *CurlCfilter, data: ?*CurlEasy) callconv(.c) void {
        if (multisslSetup(null) != 0) return;
        vtls_impl.Curl_ssl.close(cf, data);
    }

    pub fn multisslRecvPlain(cf: *CurlCfilter, data: ?*CurlEasy, buf: [*]u8, len: usize, pnread: *usize) callconv(.c) CURLcode {
        if (multisslSetup(null) != 0) return CURLE_FAILED_INIT;
        return vtls_impl.Curl_ssl.recv_plain(cf, data, buf, len, pnread);
    }

    pub fn multisslSendPlain(cf: *CurlCfilter, data: ?*CurlEasy, mem_ptr: ?*const anyopaque, len: usize, pnwritten: *usize) callconv(.c) CURLcode {
        if (multisslSetup(null) != 0) return CURLE_FAILED_INIT;
        return vtls_impl.Curl_ssl.send_plain(cf, data, mem_ptr, len, pnwritten);
    }

    pub fn Curl_multissl_init() callconv(.c) c_int {
        return multisslInit();
    }

    pub fn Curl_multissl_version(buffer: [*]u8, size: usize) callconv(.c) usize {
        return multisslVersion(buffer, size);
    }

    pub fn Curl_multissl_set(backend: ?*const CurlSsl) callconv(.c) c_int {
        return multisslSetup(backend);
    }

    fn sslPrefsCheck(cf: *CurlCfilter, data: ?*CurlEasy) bool {
        const conn_config = Curl_ssl_cf_get_filter_config(cf) orelse return false;
        if (conn_config.version >= CURL_SSLVERSION_LAST) {
            c_ext.Curl_failf(data, "Unrecognized parameter value passed via CURLOPT_SSLVERSION");
            return false;
        }
        switch (conn_config.version_max) {
            CURL_SSLVERSION_MAX_NONE, CURL_SSLVERSION_MAX_DEFAULT => {},
            else => {
                if ((conn_config.version_max >> 16) < conn_config.version) {
                    c_ext.Curl_failf(data, "CURL_SSLVERSION_MAX incompatible with CURLOPT_SSLVERSION");
                    return false;
                }
            },
        }
        return true;
    }

    fn cfCtxNew(data: ?*CurlEasy, alpn: ?*const AlpnSpec) ?*SslConnectData {
        _ = data;
        const raw = mem.calloc(1, @sizeOf(SslConnectData)) orelse return null;
        const ctx: *SslConnectData = @ptrCast(@alignCast(raw));
        ctx.ssl_impl = vtls_impl.Curl_ssl;
        ctx.alpn = alpn;
        io_buffers.Curl_bufq_init2(&ctx.earlydata, CURL_SSL_EARLY_MAX, 1, BUFQ_OPT_NO_SPARES);
        ctx.backend = mem.calloc(1, ctx.ssl_impl.sizeof_ssl_backend_data);
        if (ctx.backend == null) {
            mem.freeSized(ctx, @sizeOf(SslConnectData));
            return null;
        }
        return ctx;
    }

    fn cfCtxFree(ctx_opt: ?*SslConnectData) void {
        const ctx = ctx_opt orelse return;
        if (ctx.negotiated_alpn) |alpn| {
            mem.free(alpn);
            ctx.negotiated_alpn = null;
        }
        io_buffers.Curl_bufq_free(&ctx.earlydata);
        mem.freeSized(ctx.backend, ctx.ssl_impl.sizeof_ssl_backend_data);
        ctx.backend = null;
        mem.freeSized(ctx, @sizeOf(SslConnectData));
    }

    pub fn Curl_ssl_peer_cleanup(peer: *SslPeer) callconv(.c) void {
        c_ext.Curl_peer_unlink(&peer.origin);
        c_ext.Curl_peer_unlink(&peer.peer);
        if (peer.sni) |sni| {
            mem.free(sni);
            peer.sni = null;
        }
        if (peer.scache_key) |key| {
            mem.free(key);
            peer.scache_key = null;
        }
        peer.type = SSL_PEER_DNS;
    }

    pub fn Curl_ssl_peer_init(
        ssl_peer: *SslPeer,
        origin_opt: ?*CurlPeer,
        peer_opt: ?*CurlPeer,
        sslc: *SslFilterConfig,
        tls_id: [*:0]const u8,
        transport: u8,
    ) callconv(.c) CURLcode {
        Curl_ssl_peer_cleanup(ssl_peer);
        c_ext.Curl_peer_link(&ssl_peer.origin, origin_opt);
        c_ext.Curl_peer_link(&ssl_peer.peer, peer_opt);
        ssl_peer.transport = transport;
        const origin = ssl_peer.origin orelse {
            return CURLE_FAILED_INIT;
        };

        var ipv4_addr: [4]u8 = undefined;
        var ipv6_addr: [16]u8 = undefined;
        if (c_ext.curlx_inet_pton(2, origin.hostname, &ipv4_addr) == 1) {
            ssl_peer.type = SSL_PEER_IPV4;
        } else if (c_ext.curlx_inet_pton(AF_INET6_VAL, origin.hostname, &ipv6_addr) == 1) {
            ssl_peer.type = SSL_PEER_IPV6;
        } else {
            ssl_peer.type = SSL_PEER_DNS;
        }

        if (ssl_peer.type == SSL_PEER_DNS) {
            const host_len = std.mem.len(origin.hostname);
            if (host_len > 0) {
                var sni_len = host_len;
                while (sni_len > 0 and origin.hostname[sni_len - 1] == '.') {
                    sni_len -= 1;
                }
                if (sni_len > 0) {
                    const sni = mem.calloc(1, sni_len + 1) orelse {
                        Curl_ssl_peer_cleanup(ssl_peer);
                        return CURLE_OUT_OF_MEMORY;
                    };
                    const sni_bytes: [*:0]u8 = @ptrCast(sni);
                    primitives.Curl_strntolower(sni_bytes, origin.hostname, sni_len);
                    sni_bytes[sni_len] = 0;
                    ssl_peer.sni = sni_bytes;
                }
            }
        }

        const result = vtls_scache_asn1.Curl_ssl_peer_key_make(ssl_peer, sslc, tls_id, &ssl_peer.scache_key);
        if (result != CURLE_OK) {
            Curl_ssl_peer_cleanup(ssl_peer);
        }
        return result;
    }

    fn cfSslPeerInit(
        cf: *CurlCfilter,
        origin_opt: ?*CurlPeer,
        peer_opt: ?*CurlPeer,
        conn_config: *SslFilterConfig,
    ) CURLcode {
        const connssl: *SslConnectData = @ptrCast(@alignCast(cf.ctx orelse return CURLE_FAILED_INIT));
        var tls_id: [80]u8 = @splat(0);
        _ = connssl.ssl_impl.version(&tls_id, tls_id.len - 1);
        return Curl_ssl_peer_init(
            &connssl.peer,
            origin_opt,
            peer_opt,
            conn_config,
            @ptrCast(&tls_id),
            TRNSPRT_TCP,
        );
    }

    pub fn Curl_cf_ssl_create(pcf: *?*CurlCfilter, data: ?*CurlEasy, conn: ?*ConnectData) callconv(.c) CURLcode {
        var wanted: u8 = 0;
        var preferred: u8 = 0;
        var only_http_10 = false;
        var use_alpn = false;
        c_ext.Curl_vtls_acc_cf_ssl_create_params(data, conn, &wanted, &preferred, &only_http_10, &use_alpn);

        const ctx = cfCtxNew(data, alpnGetSpec(wanted, preferred, only_http_10, use_alpn)) orelse {
            pcf.* = null;
            return CURLE_OUT_OF_MEMORY;
        };

        var cf: ?*CurlCfilter = null;
        const result = c_ext.Curl_cf_create(&cf, &vtls_impl.Curl_cft_ssl, ctx);
        if (result != CURLE_OK) {
            cfCtxFree(ctx);
            pcf.* = null;
        } else {
            pcf.* = cf;
        }
        return result;
    }

    pub fn cfSslInsertAfter(
        cf_at: *CurlCfilter,
        data: ?*CurlEasy,
        origin: ?*CurlPeer,
        peer: ?*CurlPeer,
    ) CURLcode {
        var cf: ?*CurlCfilter = null;
        var result = Curl_cf_ssl_create(&cf, data, cf_at.conn);
        if (result == CURLE_OK) {
            if (c_ext.Curl_vtls_acc_conn_ssl_filter_config(cf_at.conn, false)) |cfg| {
                result = cfSslPeerInit(cf.?, origin, peer, cfg);
            } else {
                result = CURLE_FAILED_INIT;
            }
        }
        if (result == CURLE_OK) {
            c_ext.Curl_conn_cf_insert_after(cf_at, cf.?);
        } else if (cf != null) {
            c_ext.Curl_conn_cf_discard_chain(&cf, data);
        }
        return result;
    }

    pub fn Curl_cf_ssl_proxy_create(pcf: *?*CurlCfilter, data: ?*CurlEasy, conn: ?*ConnectData) callconv(.c) CURLcode {
        var wanted: u8 = CURL_HTTP_V1x;
        var use_alpn = false;
        c_ext.Curl_vtls_acc_cf_proxy_create_params(data, conn, &wanted, &use_alpn);

        const ctx = cfCtxNew(data, alpnGetSpec(wanted, 0, false, use_alpn)) orelse {
            pcf.* = null;
            return CURLE_OUT_OF_MEMORY;
        };

        var cf: ?*CurlCfilter = null;
        const result = c_ext.Curl_cf_create(&cf, &vtls_impl.Curl_cft_ssl_proxy, ctx);
        if (result != CURLE_OK) {
            cfCtxFree(ctx);
            pcf.* = null;
        } else {
            pcf.* = cf;
        }
        return result;
    }

    pub fn cfSslProxyInsertAfter(
        cf_at: *CurlCfilter,
        data: ?*CurlEasy,
        peer: ?*CurlPeer,
    ) CURLcode {
        var cf: ?*CurlCfilter = null;
        var result = Curl_cf_ssl_proxy_create(&cf, data, cf_at.conn);
        if (result == CURLE_OK) {
            if (c_ext.Curl_vtls_acc_conn_ssl_filter_config(cf_at.conn, true)) |cfg| {
                result = cfSslPeerInit(cf.?, peer, null, cfg);
            } else {
                result = CURLE_FAILED_INIT;
            }
        }
        if (result == CURLE_OK) {
            c_ext.Curl_conn_cf_insert_after(cf_at, cf.?);
        } else if (cf != null) {
            c_ext.Curl_conn_cf_discard_chain(&cf, data);
        }
        return result;
    }

    pub fn Curl_ssl_cfilter_add(
        data: ?*CurlEasy,
        origin: ?*CurlPeer,
        conn: ?*ConnectData,
        sockindex: i8,
    ) callconv(.c) CURLcode {
        var cf: ?*CurlCfilter = null;
        var result = Curl_cf_ssl_create(&cf, data, conn);
        if (result == CURLE_OK) {
            const peer = c_ext.Curl_vtls_acc_conn_via_peer(conn, sockindex);
            if (c_ext.Curl_vtls_acc_conn_ssl_filter_config(conn, false)) |cfg| {
                result = cfSslPeerInit(cf.?, origin, peer, cfg);
            } else {
                result = CURLE_FAILED_INIT;
            }
        }
        if (result == CURLE_OK) {
            c_ext.Curl_conn_cf_add(data, conn, sockindex, cf.?);
        } else if (cf != null) {
            c_ext.Curl_conn_cf_discard_chain(&cf, data);
        }
        return result;
    }

    fn vtlsShutdownBlocking(cf: *CurlCfilter, data: ?*CurlEasy, send_shutdown: bool, done: *bool) CURLcode {
        const connssl: *SslConnectData = @ptrCast(@alignCast(cf.ctx orelse return CURLE_OK));
        var result: CURLcode = CURLE_OK;
        var loop: c_int = 10;

        if (cf.isShutdown()) {
            done.* = true;
            return CURLE_OK;
        }

        done.* = false;
        const saved_call_data = connssl.call_data;
        connssl.call_data = data;
        defer connssl.call_data = saved_call_data;

        while (result == CURLE_OK and !done.* and loop > 0) : (loop -= 1) {
            const timeout_ms = c_ext.Curl_cshutdn_timeleft_ms(data, cf.conn, cf.sockindex);
            if (timeout_ms < 0) {
                c_ext.Curl_failf(data, "SSL shutdown timeout");
                result = CURLE_OPERATION_TIMEDOUT;
                break;
            }

            if (connssl.ssl_impl.shut_down) |sd| {
                result = sd(cf, data, send_shutdown, done);
            } else {
                done.* = true;
            }
            if (result != CURLE_OK or done.*)
                break;

            if (connssl.io_need != 0) {
                const what = c_ext.Curl_conn_cf_poll(cf, data, timeout_ms);
                if (what < 0) {
                    c_ext.Curl_failf(data, "select/poll on SSL socket");
                    result = CURLE_RECV_ERROR;
                    break;
                } else if (what == 0) {
                    c_ext.Curl_failf(data, "SSL shutdown timeout");
                    result = CURLE_OPERATION_TIMEDOUT;
                    break;
                }
            }
        }
        cf.setShutdown(result != CURLE_OK or done.*);
        return result;
    }

    pub fn Curl_ssl_cfilter_remove(data: ?*CurlEasy, sockindex: i8, send_shutdown: bool) callconv(.c) CURLcode {
        var result: CURLcode = CURLE_OK;
        const conn = c_ext.Curl_vtls_acc_data_conn(data);
        var cf = c_ext.Curl_vtls_acc_conn_cfilter(conn, sockindex);
        while (cf) |cur| : (cf = cur.next) {
            if (cur.cft == &vtls_impl.Curl_cft_ssl) {
                var done = false;
                c_ext.Curl_cshutdn_start_timer(data, sockindex, 0);
                result = vtlsShutdownBlocking(cur, data, send_shutdown, &done);
                c_ext.Curl_cshutdn_clear_timer(data, sockindex);
                if (result == CURLE_OK and !done)
                    result = CURLE_SSL_SHUTDOWN_FAILED;
                var cf_discard: ?*CurlCfilter = cur;
                c_ext.Curl_conn_cf_discard(&cf_discard, data);
                break;
            }
        }
        return result;
    }

    pub fn Curl_ssl_cf_is_proxy(cf: *CurlCfilter) callconv(.c) bool {
        return (cf.cft.flags & CF_TYPE_SSL) != 0 and (cf.cft.flags & CF_TYPE_PROXY) != 0;
    }

    pub fn Curl_ssl_cf_get_easy_config(cf: *CurlCfilter, data: ?*CurlEasy) callconv(.c) ?*SslEasyConfig {
        return c_ext.Curl_vtls_acc_data_ssl_easy_config(data, Curl_ssl_cf_is_proxy(cf));
    }

    pub fn Curl_ssl_cf_get_filter_config(cf: *CurlCfilter) callconv(.c) ?*SslFilterConfig {
        return c_ext.Curl_vtls_acc_conn_ssl_filter_config(cf.conn, Curl_ssl_cf_is_proxy(cf));
    }

    pub fn Curl_ssl_cf_get_ssl(cf_opt: ?*CurlCfilter) callconv(.c) ?*const CurlSsl {
        const cf = cf_opt orelse return null;
        const ctx: *SslConnectData = @ptrCast(@alignCast(cf.ctx orelse return null));
        return ctx.ssl_impl;
    }

    pub fn Curl_conn_get_ssl_info(
        data: ?*CurlEasy,
        conn: ?*ConnectData,
        sockindex: c_int,
        tls_backend_info: *CurlTlsSessionInfo,
    ) callconv(.c) bool {
        return cfilters_progress.Curl_conn_get_ssl_info_zig(
            @ptrCast(data),
            @ptrCast(conn),
            sockindex,
            @ptrCast(tls_backend_info),
        );
    }

    pub fn Curl_alpn_to_proto_buf(buf: *AlpnProtoBuf, spec: ?*const AlpnSpec) callconv(.c) CURLcode {
        return alpnToProtoBuf(buf, spec);
    }

    pub fn Curl_alpn_to_proto_str(buf: *AlpnProtoBuf, spec: ?*const AlpnSpec) callconv(.c) CURLcode {
        return alpnToProtoStr(buf, spec);
    }

    pub fn Curl_alpn_contains_proto(spec: ?*const AlpnSpec, proto: ?[*:0]const u8) callconv(.c) bool {
        return alpnContainsProto(spec, proto);
    }

    pub fn Curl_alpn_restrict_to(spec: *AlpnSpec, proto: [*:0]const u8) callconv(.c) void {
        alpnRestrictTo(spec, proto);
    }

    pub fn Curl_alpn_copy(dest: *AlpnSpec, src: ?*const AlpnSpec) callconv(.c) void {
        alpnCopy(dest, src);
    }

    pub fn Curl_alpn_set_negotiated(
        cf: *CurlCfilter,
        data: ?*CurlEasy,
        connssl: *SslConnectData,
        proto_opt: ?[*]const u8,
        proto_len: usize,
    ) callconv(.c) CURLcode {
        _ = cf;
        if (connssl.negotiated_alpn) |existing| {
            if (proto_len == 0) {
                c_ext.Curl_failf(data, "ALPN: asked for '%s' from previous session, but server did not confirm it. Refusing to continue.", existing);
                return CURLE_SSL_CONNECT_ERROR;
            }
            const proto = proto_opt orelse return CURLE_SSL_CONNECT_ERROR;
            const existing_len = std.mem.len(existing);
            if (existing_len != proto_len or !std.mem.eql(u8, existing[0..existing_len], proto[0..proto_len])) {
                c_ext.Curl_failf(data, "ALPN: asked for '%s' from previous session, but server selected '%.*s'. Refusing to continue.", existing, @as(c_int, @intCast(proto_len)), proto);
                return CURLE_SSL_CONNECT_ERROR;
            }
            c_ext.Curl_infof(data, "ALPN: server confirmed to use '%s'", existing);
            return CURLE_OK;
        }

        if (proto_opt != null and proto_len > 0) {
            const proto = proto_opt.?;
            if (std.mem.indexOfScalar(u8, proto[0..proto_len], 0) != null) {
                c_ext.Curl_failf(data, "ALPN: server selected protocol contains NUL. Refusing to continue.");
                return CURLE_SSL_CONNECT_ERROR;
            }
            const dup_raw = mem.malloc(proto_len + 1) orelse return CURLE_OUT_OF_MEMORY;
            @memcpy(dup_raw[0..proto_len], proto[0..proto_len]);
            dup_raw[proto_len] = 0;
            connssl.negotiated_alpn = @ptrCast(dup_raw);
            if (connssl.state == ssl_connection_deferred) {
                c_ext.Curl_infof(data, "ALPN: condensed to %.*s for early data", @as(c_int, @intCast(proto_len)), proto);
            } else {
                c_ext.Curl_infof(data, "ALPN: server accepted %.*s", @as(c_int, @intCast(proto_len)), proto);
            }
        } else {
            if (connssl.state == ssl_connection_deferred) {
                c_ext.Curl_infof(data, "ALPN: not condensed for early data");
            } else {
                c_ext.Curl_infof(data, "ALPN: server did not agree on a protocol. Uses default.");
            }
        }
        return CURLE_OK;
    }

    pub fn Curl_on_session_reuse(
        cf: *CurlCfilter,
        data: ?*CurlEasy,
        alpns: ?*const AlpnSpec,
        scs: *CurlSslSession,
        do_early_data: *bool,
        early_data_allowed: bool,
    ) callconv(.c) CURLcode {
        const connssl: *SslConnectData = @ptrCast(@alignCast(cf.ctx orelse return CURLE_FAILED_INIT));
        do_early_data.* = false;

        if (!early_data_allowed) {
            return CURLE_OK;
        }
        if (!alpnContainsProto(alpns, scs.alpn)) {
            return CURLE_OK;
        }

        const alpn_str: [*:0]const u8 = scs.alpn orelse "";
        c_ext.Curl_infof(data, "SSL session allows %zu bytes of early data, reusing ALPN '%s'", connssl.earlydata_max, alpn_str);
        connssl.earlydata_state = ssl_earlydata_await;
        connssl.state = ssl_connection_deferred;
        const alpn_len = if (scs.alpn) |a| std.mem.len(a) else 0;
        const result = Curl_alpn_set_negotiated(cf, data, connssl, if (scs.alpn) |a| a else null, alpn_len);
        do_early_data.* = (result == CURLE_OK);
        return result;
    }

    pub fn Curl_ssl_get_cf_session(
        data: ?*CurlEasy,
        cft: *const CurlCftype,
        sockindex: i8,
    ) callconv(.c) ?*CurlSslSession {
        const conn = c_ext.Curl_vtls_acc_data_conn(data) orelse return null;
        if (cft == &vtls_impl.Curl_cft_ssl or cft == &vtls_impl.Curl_cft_ssl_proxy) {
            var cf1 = c_ext.Curl_vtls_acc_conn_cfilter(conn, sockindex);
            while (cf1) |cur| : (cf1 = cur.next) {
                if (cur.cft == cft) {
                    if (cur.ctx) |raw_ctx| {
                        const connssl: *SslConnectData = @ptrCast(@alignCast(raw_ctx));
                        return connssl.session;
                    }
                    break;
                }
            }
        }
        return null;
    }

    // Connection filter callbacks
    fn sslCfConnectFinish(cf: *CurlCfilter, data: ?*CurlEasy) void {
        const connssl: *SslConnectData = @ptrCast(@alignCast(cf.ctx orelse return));
        cf.setConnected(true);
        connssl.state = ssl_connection_complete;
        connssl.connecting_state = ssl_connect_done;
        if (!Curl_ssl_cf_is_proxy(cf)) {
            connssl.handshake_done = c_ext.Curl_pgrs_now(data).*;
        }
        if (cf.sockindex == FIRSTSOCKET) {
            _ = c_ext.Curl_conn_cf_cntrl(cf, data, true, CF_CTRL_CONN_INFO_UPDATE, 0, null);
            _ = c_ext.Curl_conn_cf_cntrl(cf, data, true, CF_CTRL_REPORT_STATS, 0, null);
        }
    }

    fn sslCfConnectDeferred(cf: *CurlCfilter, data: ?*CurlEasy, done: *bool) CURLcode {
        const connssl: *SslConnectData = @ptrCast(@alignCast(cf.ctx orelse return CURLE_FAILED_INIT));
        done.* = true;
        c_ext.Curl_infof(data, "SSL connection is deferred,vroom!");
        if (cf.sockindex == FIRSTSOCKET) {
            _ = c_ext.Curl_conn_cf_cntrl(cf.next, data, true, CF_CTRL_CONN_INFO_UPDATE, 0, null);
        }
        connssl.connecting_state = ssl_connect_2;
        return CURLE_OK;
    }

    fn sslCfConnect(cf: *CurlCfilter, data: ?*CurlEasy, done: *bool) CURLcode {
        const connssl: *SslConnectData = @ptrCast(@alignCast(cf.ctx orelse return CURLE_FAILED_INIT));

        if (cf.isConnected() or connssl.state == ssl_connection_complete) {
            done.* = true;
            return CURLE_OK;
        }
        if (connssl.state == ssl_connection_deferred) {
            done.* = true;
            return CURLE_OK;
        }
        const saved_call_data = connssl.call_data;
        connssl.call_data = data;
        defer connssl.call_data = saved_call_data;

        if (!connssl.prefs_checked()) {
            if (!sslPrefsCheck(cf, data))
                return CURLE_SSL_CONNECT_ERROR;
            connssl.set_prefs_checked(true);
        }
        if (connssl.state == ssl_connection_none) {
            connssl.state = ssl_connection_negotiating;
        }

        const result = connssl.ssl_impl.do_connect(cf, data, done);
        if (result == CURLE_OK and done.*) {
            if (connssl.state == ssl_connection_deferred) {
                return sslCfConnectDeferred(cf, data, done);
            } else {
                sslCfConnectFinish(cf, data);
            }
        }
        return result;
    }

    pub fn cfSslConnect(cf: *CurlCfilter, data: ?*CurlEasy, done: *bool) callconv(.c) CURLcode {
        const connssl: *SslConnectData = @ptrCast(@alignCast(cf.ctx orelse return CURLE_FAILED_INIT));
        if (cf.isConnected() and connssl.state == ssl_connection_complete) {
            done.* = true;
            return CURLE_OK;
        }
        if (cf.next == null) {
            done.* = false;
            return CURLE_FAILED_INIT;
        }
        if (!cf.next.?.isConnected()) {
            const r = c_ext.Curl_conn_cf_connect(cf.next, data, done);
            if (r != CURLE_OK or !done.*)
                return r;
        }

        done.* = false;
        const result = sslCfConnect(cf, data, done);
        return result;
    }

    pub fn cfSslShutdown(cf: *CurlCfilter, data: ?*CurlEasy, done: *bool) callconv(.c) CURLcode {
        const connssl: *SslConnectData = @ptrCast(@alignCast(cf.ctx orelse return CURLE_OK));
        if (cf.isShutdown() or !cf.isConnected() or connssl.state != ssl_connection_complete) {
            done.* = true;
            return CURLE_OK;
        }
        done.* = false;
        connssl.io_need = CURL_SSL_IO_NEED_NONE;
        const saved_call_data = connssl.call_data;
        connssl.call_data = data;
        defer connssl.call_data = saved_call_data;

        var result: CURLcode = CURLE_OK;
        if (connssl.ssl_impl.shut_down) |sd| {
            result = sd(cf, data, true, done);
        } else {
            done.* = true;
        }
        cf.setShutdown(result != CURLE_OK or done.*);
        return result;
    }

    pub fn cfSslDataPending(cf: *CurlCfilter, data: ?*const CurlEasy) callconv(.c) bool {
        const connssl: *SslConnectData = @ptrCast(@alignCast(cf.ctx orelse return false));
        const saved_call_data = connssl.call_data;
        connssl.call_data = @constCast(data);
        defer connssl.call_data = saved_call_data;

        if (connssl.ssl_impl.data_pending) |dp| {
            if (dp(cf, data)) return true;
        }
        if (cf.next) |next| {
            return next.cft.has_data_pending(next, data);
        }
        return false;
    }

    pub fn cfSslAdjustPollset(cf: *CurlCfilter, data: ?*CurlEasy, ps: ?*EasyPollset) callconv(.c) CURLcode {
        const connssl: *SslConnectData = @ptrCast(@alignCast(cf.ctx orelse return CURLE_OK));
        const saved_call_data = connssl.call_data;
        connssl.call_data = data;
        defer connssl.call_data = saved_call_data;

        var result: CURLcode = CURLE_OK;
        if (!cf.isConnected()) {
            result = connssl.ssl_impl.adjust_pollset(cf, data, ps);
            c_ext.Curl_conn_cf_adjust_pollset(cf.next, data, ps);
        } else if (connssl.state != ssl_connection_complete or !cf.isShutdown()) {
            result = connssl.ssl_impl.adjust_pollset(cf, data, ps);
        }
        return result;
    }

    pub fn cfSslSend(
        cf: *CurlCfilter,
        data: ?*CurlEasy,
        buf: ?*const anyopaque,
        len: usize,
        eos: bool,
        pnwritten: *usize,
    ) callconv(.c) CURLcode {
        const connssl: *SslConnectData = @ptrCast(@alignCast(cf.ctx orelse return CURLE_FAILED_INIT));
        _ = eos;
        pnwritten.* = 0;
        const saved_call_data = connssl.call_data;
        connssl.call_data = data;
        defer connssl.call_data = saved_call_data;

        if (connssl.state == ssl_connection_deferred) {
            if (connssl.earlydata_state == ssl_earlydata_await) {
                var result: CURLcode = CURLE_OK;
                if (len > 0 and buf != null) {
                    const bptr: [*]const u8 = @ptrCast(buf.?);
                    result = io_buffers.Curl_bufq_write(&connssl.earlydata, bptr, len, pnwritten);
                    if (result != CURLE_OK and result != CURLE_AGAIN)
                        return result;
                }
                if (len == 0 or result == CURLE_AGAIN) {
                    connssl.earlydata_state = ssl_earlydata_sending;
                } else {
                    connssl.earlydata_skip += pnwritten.*;
                    return CURLE_OK;
                }
            }
            var done = false;
            const result = sslCfConnect(cf, data, &done);
            if (result != CURLE_OK) return result;
            if (!done) return CURLE_AGAIN;
        }

        if (connssl.earlydata_state == ssl_earlydata_accepted) {
            if (connssl.earlydata_skip >= len) {
                connssl.earlydata_skip -= len;
                if (connssl.earlydata_skip == 0) {
                    connssl.earlydata_state = ssl_earlydata_none;
                }
                pnwritten.* = len;
                return CURLE_OK;
            } else {
                pnwritten.* = connssl.earlydata_skip;
                connssl.earlydata_skip = 0;
                connssl.earlydata_state = ssl_earlydata_none;
                return CURLE_OK;
            }
        } else if (connssl.earlydata_state == ssl_earlydata_rejected) {
            c_ext.Curl_infof(data, "SSL server rejected %zu bytes of early data, resending", connssl.earlydata_skip);
            connssl.earlydata_skip = 0;
            connssl.earlydata_state = ssl_earlydata_none;
        }

        if (len == 0) return CURLE_OK;
        return connssl.ssl_impl.send_plain(cf, data, buf, len, pnwritten);
    }

    pub fn cfSslRecv(
        cf: *CurlCfilter,
        data: ?*CurlEasy,
        buf: [*]u8,
        len: usize,
        pnread: *usize,
    ) callconv(.c) CURLcode {
        const connssl: *SslConnectData = @ptrCast(@alignCast(cf.ctx orelse return CURLE_FAILED_INIT));
        pnread.* = 0;
        const saved_call_data = connssl.call_data;
        connssl.call_data = data;
        defer connssl.call_data = saved_call_data;

        if (connssl.state == ssl_connection_deferred) {
            if (connssl.earlydata_state == ssl_earlydata_await) {
                connssl.earlydata_state = ssl_earlydata_sending;
            }
            var done = false;
            const result = sslCfConnect(cf, data, &done);
            if (result != CURLE_OK) return result;
            if (!done) return CURLE_AGAIN;
        }

        return connssl.ssl_impl.recv_plain(cf, data, buf, len, pnread);
    }

    fn cfSslClose(cf: *CurlCfilter, data: ?*CurlEasy) void {
        const connssl: *SslConnectData = @ptrCast(@alignCast(cf.ctx orelse return));
        connssl.ssl_impl.close(cf, data);
        connssl.state = ssl_connection_none;
        connssl.connecting_state = ssl_connect_1;
        if (connssl.negotiated_alpn) |alpn| {
            mem.free(alpn);
            connssl.negotiated_alpn = null;
        }
        if (connssl.session != null and connssl.peer.scache_key != null) {
            if (Curl_ssl_cf_get_filter_config(cf)) |cfg| {
                var scache: ?*CurlSslScache = null;
                var has_share_scache = false;
                var trc_feat: ?*CurlTrcFeat = null;
                c_ext.Curl_vtls_acc_scache_params(data, &scache, &has_share_scache, &trc_feat);
                _ = vtls_scache_asn1.Curl_ssl_scache_return_zig(
                    cf,
                    data,
                    scache,
                    has_share_scache,
                    cfg,
                    trc_feat,
                    connssl.peer.scache_key.?,
                    connssl.session.?,
                );
            }
        }
        connssl.session = null;
        cf.setConnected(false);
    }

    pub fn cfSslDestroy(cf: *CurlCfilter, data: ?*CurlEasy) callconv(.c) void {
        if (cf.ctx) |raw_ctx| {
            const ctx: *SslConnectData = @ptrCast(@alignCast(raw_ctx));
            cfSslClose(cf, data);
            Curl_ssl_peer_cleanup(&ctx.peer);
            cfCtxFree(ctx);
            cf.ctx = null;
        }
    }

    pub fn cfSslCntrl(
        cf: *CurlCfilter,
        data: ?*CurlEasy,
        event: c_int,
        arg1: c_int,
        arg2: ?*anyopaque,
    ) callconv(.c) CURLcode {
        _ = arg1;
        _ = arg2;
        const connssl: *SslConnectData = @ptrCast(@alignCast(cf.ctx orelse return CURLE_OK));
        switch (event) {
            CF_CTRL_CONN_INFO_UPDATE => {
                if (cf.sockindex == FIRSTSOCKET and !Curl_ssl_cf_is_proxy(cf)) {
                    if (connssl.negotiated_alpn) |alpn| {
                        const s = std.mem.span(alpn);
                        if (backend_options.nghttp2 and std.mem.eql(u8, s, "h2")) {
                            c_ext.Curl_vtls_acc_conn_set_httpversion_seen(cf.conn, 20);
                            c_ext.Curl_vtls_acc_conn_set_multiplex(cf.conn, true);
                        } else if (std.mem.eql(u8, s, "http/1.1")) {
                            c_ext.Curl_vtls_acc_conn_set_httpversion_seen(cf.conn, 11);
                        } else if (std.mem.eql(u8, s, "http/1.0")) {
                            c_ext.Curl_vtls_acc_conn_set_httpversion_seen(cf.conn, 10);
                        }
                    }
                }
            },
            CF_CTRL_REPORT_STATS => {
                if (cf.sockindex == FIRSTSOCKET and !Curl_ssl_cf_is_proxy(cf)) {
                    if (!connssl.stats_reported() and (connssl.handshake_done.tv_sec != 0 or connssl.handshake_done.tv_usec != 0)) {
                        connssl.set_stats_reported(true);
                        c_ext.Curl_pgrsTimeWas(data, TIMER_APPCONNECT, connssl.handshake_done);
                    }
                }
            },
            else => {},
        }
        return CURLE_OK;
    }

    pub fn cfSslIsAlive(cf: *CurlCfilter, data: ?*CurlEasy, input_pending: *bool) callconv(.c) bool {
        if (cf.next) |next| {
            return next.cft.is_alive(next, data, input_pending);
        }
        return false;
    }

    pub fn cfSslQuery(
        cf: *CurlCfilter,
        data: ?*CurlEasy,
        query: c_int,
        pres1: ?*c_int,
        pres2: ?*anyopaque,
    ) callconv(.c) CURLcode {
        const connssl: *SslConnectData = @ptrCast(@alignCast(cf.ctx orelse return CURLE_FAILED_INIT));
        switch (query) {
            CF_QUERY_TIMER_APPCONNECT => {
                if (!Curl_ssl_cf_is_proxy(cf)) {
                    return c_ext.Curl_cf_def_query(cf, data, query, pres1, pres2);
                }
            },
            CF_QUERY_SSL_INFO, CF_QUERY_SSL_CTX_INFO => {
                if (!Curl_ssl_cf_is_proxy(cf)) {
                    const info: *CurlTlsSessionInfo = @ptrCast(@alignCast(pres2 orelse return CURLE_BAD_FUNCTION_ARGUMENT));
                    info.backend = Curl_ssl_backend();
                    if (connssl.ssl_impl.get_internals) |gi| {
                        info.internals = gi(
                            connssl,
                            if (query == CF_QUERY_SSL_INFO) CURLINFO_TLS_SSL_PTR else CURLINFO_TLS_SESSION,
                        );
                    } else {
                        info.internals = null;
                    }
                    return CURLE_OK;
                }
            },
            CF_QUERY_ALPN_NEGOTIATED => {
                const palpn: *?[*:0]const u8 = @ptrCast(@alignCast(pres2 orelse return CURLE_BAD_FUNCTION_ARGUMENT));
                palpn.* = connssl.negotiated_alpn;
                return CURLE_OK;
            },
            else => {},
        }
        if (cf.next) |next| {
            return next.cft.query(next, data, query, pres1, pres2);
        }
        return CURLE_UNKNOWN_OPTION;
    }
};

pub const vtls_impl = struct {
    const root_self = @import("vtls_backends.zig");

    pub var Curl_ssl: *const root_self.CurlSsl = switch (backend_options.ssl) {
        .schannel => &schannel_backend.Curl_ssl_schannel,
        .openssl => if (backend_options.bundled) &bundled_tls.Curl_ssl_zig_tls else &openssl_backend.Curl_ssl_openssl,
        .mbedtls => &mbedtls_backend.Curl_ssl_mbedtls,
        .gnutls => &vtls_gtls.Curl_ssl_gnutls,
        .rustls => &vtls_rustls.Curl_ssl_rustls,
        .wolfssl => &vtls_wolfssl.Curl_ssl_wolfssl,
        else => &Curl_ssl_multi,
    };

    pub const Curl_ssl_multi = root_self.CurlSsl{
        .info = .{ .id = root_self.CURLSSLBACKEND_NONE, .name = "multi" },
        .supports = 0,
        .sizeof_ssl_backend_data = std.math.maxInt(usize),
        .init = vtls_core_impl.multisslInit,
        .cleanup = null,
        .version = vtls_core_impl.multisslVersion,
        .shut_down = null,
        .data_pending = null,
        .random = vtls_core_impl.multisslRandom,
        .cert_status_request = null,
        .do_connect = vtls_core_impl.multisslConnect,
        .adjust_pollset = vtls_core_impl.multisslAdjustPollset,
        .get_internals = vtls_core_impl.multisslGetInternals,
        .close = vtls_core_impl.multisslClose,
        .close_all = null,
        .engines_list = null,
        .sha256sum = null,
        .recv_plain = vtls_core_impl.multisslRecvPlain,
        .send_plain = vtls_core_impl.multisslSendPlain,
        .get_channel_binding = null,
    };

    pub var Curl_cft_ssl = root_self.CurlCftype{
        .name = "SSL",
        .flags = root_self.CF_TYPE_SSL,
        .log_level = root_self.CF_LVL_SSL,
        .destroy = vtls_core_impl.cfSslDestroy,
        .do_connect = vtls_core_impl.cfSslConnect,
        .do_shutdown = vtls_core_impl.cfSslShutdown,
        .adjust_pollset = vtls_core_impl.cfSslAdjustPollset,
        .has_data_pending = vtls_core_impl.cfSslDataPending,
        .do_send = vtls_core_impl.cfSslSend,
        .do_recv = vtls_core_impl.cfSslRecv,
        .cntrl = vtls_core_impl.cfSslCntrl,
        .is_alive = vtls_core_impl.cfSslIsAlive,
        .keep_alive = c_ext.Curl_cf_def_conn_keep_alive,
        .query = vtls_core_impl.cfSslQuery,
    };

    pub var Curl_cft_ssl_proxy = root_self.CurlCftype{
        .name = "SSL-PROXY",
        .flags = root_self.CF_TYPE_SSL | root_self.CF_TYPE_PROXY,
        .log_level = root_self.CF_LVL_SSL,
        .destroy = vtls_core_impl.cfSslDestroy,
        .do_connect = vtls_core_impl.cfSslConnect,
        .do_shutdown = vtls_core_impl.cfSslShutdown,
        .adjust_pollset = vtls_core_impl.cfSslAdjustPollset,
        .has_data_pending = vtls_core_impl.cfSslDataPending,
        .do_send = vtls_core_impl.cfSslSend,
        .do_recv = vtls_core_impl.cfSslRecv,
        .cntrl = vtls_core_impl.cfSslCntrl,
        .is_alive = vtls_core_impl.cfSslIsAlive,
        .keep_alive = c_ext.Curl_cf_def_conn_keep_alive,
        .query = vtls_core_impl.cfSslQuery,
    };

    pub const Curl_ssl_init = vtls_core_impl.Curl_ssl_init;
    pub const Curl_ssl_cleanup = vtls_core_impl.Curl_ssl_cleanup;
    pub const Curl_ssl_version = vtls_core_impl.Curl_ssl_version;
    pub const Curl_ssl_check_cxn = vtls_core_impl.Curl_ssl_check_cxn;
    pub const Curl_ssl_Shutdown = vtls_core_impl.Curl_ssl_Shutdown;
    pub const Curl_ssl_data_pending = vtls_core_impl.Curl_ssl_data_pending;
    pub const Curl_ssl_get_internals = vtls_core_impl.Curl_ssl_get_internals;
    pub const Curl_ssl_engines_list = vtls_core_impl.Curl_ssl_engines_list;
    pub const Curl_ssl_initsessions = vtls_core_impl.Curl_ssl_initsessions;
    pub const Curl_ssl_free_certinfo = vtls_core_impl.Curl_ssl_free_certinfo;
    pub const Curl_ssl_init_certinfo = vtls_core_impl.Curl_ssl_init_certinfo;
    pub const Curl_ssl_push_certinfo_len = vtls_core_impl.Curl_ssl_push_certinfo_len;
    pub const Curl_ssl_push_certinfo = vtls_core_impl.Curl_ssl_push_certinfo;
    pub const Curl_ssl_random = vtls_core_impl.Curl_ssl_random;
    pub const Curl_ssl_md5sum = vtls_core_impl.Curl_ssl_md5sum;
    pub const Curl_ssl_sha256sum = vtls_core_impl.Curl_ssl_sha256sum;
    pub const Curl_pin_peer_pubkey = vtls_core_impl.Curl_pin_peer_pubkey;
    pub const Curl_ssl_cert_status_request = vtls_core_impl.Curl_ssl_cert_status_request;
    pub const Curl_ssl_false_start = vtls_core_impl.Curl_ssl_false_start;
    pub const Curl_ssl_setup_x509_store = vtls_core_impl.Curl_ssl_setup_x509_store;
    pub const Curl_ssl_get_x509_store = vtls_core_impl.Curl_ssl_get_x509_store;
    pub const Curl_ssl_get_channel_binding = vtls_core_impl.Curl_ssl_get_channel_binding;
    pub const Curl_ssl_close_all = vtls_core_impl.Curl_ssl_close_all;
    pub const Curl_ssl_adjust_pollset = vtls_core_impl.Curl_ssl_adjust_pollset;
    pub const Curl_multissl_init = vtls_core_impl.Curl_multissl_init;
    pub const Curl_multissl_version = vtls_core_impl.Curl_multissl_version;
    pub const Curl_multissl_set = vtls_core_impl.Curl_multissl_set;
    pub const Curl_ssl_peer_cleanup = vtls_core_impl.Curl_ssl_peer_cleanup;
    pub const Curl_ssl_peer_init = vtls_core_impl.Curl_ssl_peer_init;
    pub const Curl_cf_ssl_create = vtls_core_impl.Curl_cf_ssl_create;
    pub const cfSslInsertAfter = vtls_core_impl.cfSslInsertAfter;
    pub const Curl_cf_ssl_proxy_create = vtls_core_impl.Curl_cf_ssl_proxy_create;
    pub const cfSslProxyInsertAfter = vtls_core_impl.cfSslProxyInsertAfter;
    pub const Curl_ssl_cfilter_add = vtls_core_impl.Curl_ssl_cfilter_add;
    pub const Curl_ssl_cfilter_remove = vtls_core_impl.Curl_ssl_cfilter_remove;
    pub const Curl_ssl_cf_is_proxy = vtls_core_impl.Curl_ssl_cf_is_proxy;
    pub const Curl_ssl_cf_get_easy_config = vtls_core_impl.Curl_ssl_cf_get_easy_config;
    pub const Curl_ssl_cf_get_filter_config = vtls_core_impl.Curl_ssl_cf_get_filter_config;
    pub const Curl_ssl_cf_get_ssl = vtls_core_impl.Curl_ssl_cf_get_ssl;
    pub const Curl_conn_get_ssl_info = vtls_core_impl.Curl_conn_get_ssl_info;
    pub const Curl_alpn_to_proto_buf = vtls_core_impl.Curl_alpn_to_proto_buf;
    pub const Curl_alpn_to_proto_str = vtls_core_impl.Curl_alpn_to_proto_str;
    pub const Curl_alpn_contains_proto = vtls_core_impl.Curl_alpn_contains_proto;
    pub const Curl_alpn_restrict_to = vtls_core_impl.Curl_alpn_restrict_to;
    pub const Curl_alpn_copy = vtls_core_impl.Curl_alpn_copy;
    pub const Curl_alpn_set_negotiated = vtls_core_impl.Curl_alpn_set_negotiated;
    pub const Curl_on_session_reuse = vtls_core_impl.Curl_on_session_reuse;
    pub const Curl_ssl_get_cf_session = vtls_core_impl.Curl_ssl_get_cf_session;

    // Re-exported types, constants, and helpers for modular SSL backend files
    pub const CURLcode = root_self.CURLcode;
    pub const CURLE_OK = root_self.CURLE_OK;
    pub const CURLE_UNSUPPORTED_PROTOCOL = root_self.CURLE_UNSUPPORTED_PROTOCOL;
    pub const CURLE_FAILED_INIT = root_self.CURLE_FAILED_INIT;
    pub const CURLE_NOT_BUILT_IN = root_self.CURLE_NOT_BUILT_IN;
    pub const CURLE_COULDNT_CONNECT = root_self.CURLE_COULDNT_CONNECT;
    pub const CURLE_OUT_OF_MEMORY = root_self.CURLE_OUT_OF_MEMORY;
    pub const CURLE_OPERATION_TIMEDOUT = root_self.CURLE_OPERATION_TIMEDOUT;
    pub const CURLE_SSL_CONNECT_ERROR = root_self.CURLE_SSL_CONNECT_ERROR;
    pub const CURLE_ABORTED_BY_CALLBACK = root_self.CURLE_ABORTED_BY_CALLBACK;
    pub const CURLE_BAD_FUNCTION_ARGUMENT = root_self.CURLE_BAD_FUNCTION_ARGUMENT;
    pub const CURLE_TOO_MANY_REDIRECTS = root_self.CURLE_TOO_MANY_REDIRECTS;
    pub const CURLE_UNKNOWN_OPTION = root_self.CURLE_UNKNOWN_OPTION;
    pub const CURLE_SETOPT_OPTION_SYNTAX = root_self.CURLE_SETOPT_OPTION_SYNTAX;
    pub const CURLE_GOT_NOTHING = root_self.CURLE_GOT_NOTHING;
    pub const CURLE_SSL_ENGINE_NOTFOUND = root_self.CURLE_SSL_ENGINE_NOTFOUND;
    pub const CURLE_SSL_ENGINE_SETFAILED = root_self.CURLE_SSL_ENGINE_SETFAILED;
    pub const CURLE_SEND_ERROR = root_self.CURLE_SEND_ERROR;
    pub const CURLE_RECV_ERROR = root_self.CURLE_RECV_ERROR;
    pub const CURLE_SSL_CERTPROBLEM = root_self.CURLE_SSL_CERTPROBLEM;
    pub const CURLE_SSL_CIPHER = root_self.CURLE_SSL_CIPHER;
    pub const CURLE_PEER_FAILED_VERIFICATION = root_self.CURLE_PEER_FAILED_VERIFICATION;
    pub const CURLE_BAD_CONTENT_ENCODING = root_self.CURLE_BAD_CONTENT_ENCODING;
    pub const CURLE_SSL_ENGINE_INITFAILED = root_self.CURLE_SSL_ENGINE_INITFAILED;
    pub const CURLE_READ_ERROR = root_self.CURLE_READ_ERROR;
    pub const CURLE_SSL_CACERT_BADFILE = root_self.CURLE_SSL_CACERT_BADFILE;
    pub const CURLE_SSL_SHUTDOWN_FAILED = root_self.CURLE_SSL_SHUTDOWN_FAILED;
    pub const CURLE_AGAIN = root_self.CURLE_AGAIN;
    pub const CURLE_SSL_CRL_BADFILE = root_self.CURLE_SSL_CRL_BADFILE;
    pub const CURLE_SSL_ISSUER_ERROR = root_self.CURLE_SSL_ISSUER_ERROR;
    pub const CURLE_SSL_PINNEDPUBKEYNOTMATCH = root_self.CURLE_SSL_PINNEDPUBKEYNOTMATCH;
    pub const CURLE_SSL_INVALIDCERTSTATUS = root_self.CURLE_SSL_INVALIDCERTSTATUS;
    pub const CURLE_SSL_CLIENTCERT = root_self.CURLE_SSL_CLIENTCERT;
    pub const CURLE_ECH_REQUIRED = root_self.CURLE_ECH_REQUIRED;

    pub const CURLSSLBACKEND_NONE = root_self.CURLSSLBACKEND_NONE;
    pub const CURLSSLBACKEND_OPENSSL = root_self.CURLSSLBACKEND_OPENSSL;
    pub const CURLSSLBACKEND_GNUTLS = root_self.CURLSSLBACKEND_GNUTLS;
    pub const CURLSSLBACKEND_WOLFSSL = root_self.CURLSSLBACKEND_WOLFSSL;
    pub const CURLSSLBACKEND_SCHANNEL = root_self.CURLSSLBACKEND_SCHANNEL;
    pub const CURLSSLBACKEND_MBEDTLS = root_self.CURLSSLBACKEND_MBEDTLS;
    pub const CURLSSLBACKEND_RUSTLS = root_self.CURLSSLBACKEND_RUSTLS;

    pub const SSLSUPP_CA_PATH = root_self.SSLSUPP_CA_PATH;
    pub const SSLSUPP_CERTINFO = root_self.SSLSUPP_CERTINFO;
    pub const SSLSUPP_PINNEDPUBKEY = root_self.SSLSUPP_PINNEDPUBKEY;
    pub const SSLSUPP_SSL_CTX = root_self.SSLSUPP_SSL_CTX;
    pub const SSLSUPP_HTTPS_PROXY = root_self.SSLSUPP_HTTPS_PROXY;
    pub const SSLSUPP_TLS13_CIPHERSUITES = root_self.SSLSUPP_TLS13_CIPHERSUITES;
    pub const SSLSUPP_CAINFO_BLOB = root_self.SSLSUPP_CAINFO_BLOB;
    pub const SSLSUPP_ISSUERCERT = root_self.SSLSUPP_ISSUERCERT;
    pub const SSLSUPP_ISSUERCERT_BLOB = root_self.SSLSUPP_ISSUERCERT_BLOB;
    pub const SSLSUPP_CA_CACHE = root_self.SSLSUPP_CA_CACHE;
    pub const SSLSUPP_CIPHER_LIST = root_self.SSLSUPP_CIPHER_LIST;
    pub const SSLSUPP_CRLFILE = root_self.SSLSUPP_CRLFILE;
    pub const SSLSUPP_ECH = root_self.SSLSUPP_ECH;
    pub const SSLSUPP_SSL_EC_CURVES = root_self.SSLSUPP_SSL_EC_CURVES;
    pub const SSLSUPP_SIGNATURE_ALGORITHMS = root_self.SSLSUPP_SIGNATURE_ALGORITHMS;
    pub const SSLSUPP_OCSP_STAPLING = root_self.SSLSUPP_OCSP_STAPLING;

    pub const CURL_SSLVERSION_DEFAULT = root_self.CURL_SSLVERSION_DEFAULT;
    pub const CURL_SSLVERSION_TLSv1 = root_self.CURL_SSLVERSION_TLSv1;
    pub const CURL_SSLVERSION_SSLv2 = root_self.CURL_SSLVERSION_SSLv2;
    pub const CURL_SSLVERSION_SSLv3 = root_self.CURL_SSLVERSION_SSLv3;
    pub const CURL_SSLVERSION_TLSv1_0 = root_self.CURL_SSLVERSION_TLSv1_0;
    pub const CURL_SSLVERSION_TLSv1_1 = root_self.CURL_SSLVERSION_TLSv1_1;
    pub const CURL_SSLVERSION_TLSv1_2 = root_self.CURL_SSLVERSION_TLSv1_2;
    pub const CURL_SSLVERSION_TLSv1_3 = root_self.CURL_SSLVERSION_TLSv1_3;
    pub const CURL_SSLVERSION_LAST = root_self.CURL_SSLVERSION_LAST;

    pub const CURL_SSLVERSION_MAX_NONE = root_self.CURL_SSLVERSION_MAX_NONE;
    pub const CURL_SSLVERSION_MAX_DEFAULT = root_self.CURL_SSLVERSION_MAX_DEFAULT;
    pub const CURL_SSLVERSION_MAX_TLSv1_0 = root_self.CURL_SSLVERSION_MAX_TLSv1_0;
    pub const CURL_SSLVERSION_MAX_TLSv1_1 = root_self.CURL_SSLVERSION_MAX_TLSv1_1;
    pub const CURL_SSLVERSION_MAX_TLSv1_2 = root_self.CURL_SSLVERSION_MAX_TLSv1_2;
    pub const CURL_SSLVERSION_MAX_TLSv1_3 = root_self.CURL_SSLVERSION_MAX_TLSv1_3;
    pub const CURL_SSLVERSION_MAX_LAST = root_self.CURL_SSLVERSION_MAX_LAST;

    pub const CURL_TLSAUTH_NONE = root_self.CURL_TLSAUTH_NONE;
    pub const CURL_TLSAUTH_SRP = root_self.CURL_TLSAUTH_SRP;

    pub const FIRSTSOCKET = root_self.FIRSTSOCKET;
    pub const SECONDARYSOCKET: i8 = 1;
    pub const CURLPROTO_FTP: u64 = 1 << 2;
    pub const TRNSPRT_TCP = root_self.TRNSPRT_TCP;
    pub const TRNSPRT_UDP = root_self.TRNSPRT_UDP;
    pub const TRNSPRT_QUIC = root_self.TRNSPRT_QUIC;
    pub const TRNSPRT_UNIX = root_self.TRNSPRT_UNIX;

    pub const ssl_connection_none = root_self.ssl_connection_none;
    pub const ssl_connection_deferred = root_self.ssl_connection_deferred;
    pub const ssl_connection_negotiating = root_self.ssl_connection_negotiating;
    pub const ssl_connection_complete = root_self.ssl_connection_complete;

    pub const ssl_connect_1 = root_self.ssl_connect_1;
    pub const ssl_connect_2 = root_self.ssl_connect_2;
    pub const ssl_connect_3 = root_self.ssl_connect_3;
    pub const ssl_connect_done = root_self.ssl_connect_done;

    pub const ssl_earlydata_none = root_self.ssl_earlydata_none;
    pub const ssl_earlydata_await = root_self.ssl_earlydata_await;
    pub const ssl_earlydata_sending = root_self.ssl_earlydata_sending;
    pub const ssl_earlydata_sent = root_self.ssl_earlydata_sent;
    pub const ssl_earlydata_accepted = root_self.ssl_earlydata_accepted;
    pub const ssl_earlydata_rejected = root_self.ssl_earlydata_rejected;

    pub const CURLINFO_TLS_SESSION = root_self.CURLINFO_TLS_SESSION;
    pub const CURLINFO_TLS_SSL_PTR = root_self.CURLINFO_TLS_SSL_PTR;

    pub const curl_socket_t = root_self.curl_socket_t;
    pub const CURL_SOCKET_BAD = root_self.CURL_SOCKET_BAD;
    pub const SOCKET_READABLE = root_self.SOCKET_READABLE;
    pub const SOCKET_WRITABLE = root_self.SOCKET_WRITABLE;
    pub const SOCKET_ERROR = root_self.SOCKET_ERROR;

    pub const CurlTime = root_self.CurlTime;
    pub const CurlEasy = root_self.CurlEasy;
    pub const ConnectData = root_self.ConnectData;
    pub const CurlPeer = root_self.CurlPeer;
    pub const CurlSslScache = root_self.CurlSslScache;
    pub const CurlTrcFeat = root_self.CurlTrcFeat;
    pub const EasyPollset = root_self.EasyPollset;
    pub const CurlCertinfo = root_self.CurlCertinfo;
    pub const curl_slist = root_self.curl_slist;
    pub const CurlBlob = root_self.CurlBlob;
    pub const SslConfigBlob = root_self.SslConfigBlob;
    pub const SslEasyConfig = root_self.SslEasyConfig;
    pub const SslFilterConfig = root_self.SslFilterConfig;
    pub const SslPrimaryConfig = root_self.SslFilterConfig;
    pub const SslConfigData = root_self.SslEasyConfig;
    pub const AlpnSpec = root_self.AlpnSpec;
    pub const ALPN_ENTRIES_MAX = root_self.ALPN_ENTRIES_MAX;
    pub const ALPN_NAME_MAX = root_self.ALPN_NAME_MAX;
    pub const SslPeer = root_self.SslPeer;
    pub const CurlScachePeer = root_self.SslPeer;
    pub const SslConnectData = root_self.SslConnectData;
    pub const CurlSslInfo = root_self.CurlSslInfo;
    pub const CurlSsl = root_self.CurlSsl;
    pub const CurlCftype = root_self.CurlCftype;
    pub const CurlCfilter = root_self.CurlCfilter;
    pub const CurlTlsSessionInfo = root_self.CurlTlsSessionInfo;
    pub const CurlTlssessioninfo = root_self.CurlTlssessioninfo;

    pub const Curl_ssl_peer_key_make = vtls_scache_asn1.Curl_ssl_peer_key_make;

    pub const Curl_ssl_cf_get_config = vtls_core_impl.Curl_ssl_cf_get_filter_config;
    pub const Curl_ssl_cf_get_primary_config = vtls_core_impl.Curl_ssl_cf_get_filter_config;
    pub const Curl_ssl_cf_get_peer_config = vtls_core_impl.Curl_ssl_cf_get_filter_config;

    pub fn Curl_ssl_scache_put(
        cf: *root_self.CurlCfilter,
        data: ?*root_self.CurlEasy,
        ssl_peer_key: [*:0]const u8,
        ssession: *vtls_scache_asn1.CurlSslSession,
    ) root_self.CURLcode {
        const cfg = vtls_core_impl.Curl_ssl_cf_get_filter_config(cf) orelse return root_self.CURLE_FAILED_INIT;
        var scache: ?*root_self.CurlSslScache = null;
        var has_share_scache = false;
        var trc_feat: ?*root_self.CurlTrcFeat = null;
        c_ext.Curl_vtls_acc_scache_params(data, &scache, &has_share_scache, &trc_feat);
        return vtls_scache_asn1.Curl_ssl_scache_put_zig(cf, data, scache, has_share_scache, cfg, trc_feat, ssl_peer_key, ssession);
    }

    pub fn Curl_ssl_scache_take(
        cf: *root_self.CurlCfilter,
        data: ?*root_self.CurlEasy,
        ssl_peer_key: [*:0]const u8,
        pssession: *?*vtls_scache_asn1.CurlSslSession,
    ) root_self.CURLcode {
        var scache: ?*root_self.CurlSslScache = null;
        var has_share_scache = false;
        var trc_feat: ?*root_self.CurlTrcFeat = null;
        c_ext.Curl_vtls_acc_scache_params(data, &scache, &has_share_scache, &trc_feat);
        return vtls_scache_asn1.Curl_ssl_scache_take_zig(cf, data, scache, trc_feat, ssl_peer_key, pssession);
    }

    pub fn Curl_ssl_scache_get(
        cf: *root_self.CurlCfilter,
        data: ?*root_self.CurlEasy,
        ssl_peer_key: [*:0]const u8,
        psess_id: *?*anyopaque,
    ) root_self.CURLcode {
        var scache: ?*root_self.CurlSslScache = null;
        var has_share_scache = false;
        var trc_feat: ?*root_self.CurlTrcFeat = null;
        c_ext.Curl_vtls_acc_scache_params(data, &scache, &has_share_scache, &trc_feat);
        return vtls_scache_asn1.Curl_ssl_scache_get_zig(cf, data, scache, trc_feat, ssl_peer_key, psess_id);
    }

    pub fn Curl_ssl_scache_add_obj(
        cf: *root_self.CurlCfilter,
        data: ?*root_self.CurlEasy,
        ssl_peer_key: [*:0]const u8,
        so_data: ?*anyopaque,
        so_destroy_cb: vtls_scache_asn1.CurlSslScacheObjDtor,
    ) root_self.CURLcode {
        const cfg = vtls_core_impl.Curl_ssl_cf_get_filter_config(cf) orelse return root_self.CURLE_FAILED_INIT;
        var scache: ?*root_self.CurlSslScache = null;
        var has_share_scache = false;
        var trc_feat: ?*root_self.CurlTrcFeat = null;
        c_ext.Curl_vtls_acc_scache_params(data, &scache, &has_share_scache, &trc_feat);
        return vtls_scache_asn1.Curl_ssl_scache_add_obj_zig(cf, data, scache, has_share_scache, cfg, ssl_peer_key, so_data, so_destroy_cb);
    }

    pub fn Curl_ssl_scache_get_obj(
        cf: *root_self.CurlCfilter,
        data: ?*root_self.CurlEasy,
        ssl_peer_key: [*:0]const u8,
    ) ?*anyopaque {
        _ = cf;
        var scache: ?*root_self.CurlSslScache = null;
        var has_share_scache = false;
        var trc_feat: ?*root_self.CurlTrcFeat = null;
        c_ext.Curl_vtls_acc_scache_params(data, &scache, &has_share_scache, &trc_feat);
        return vtls_scache_asn1.Curl_ssl_scache_get_obj_zig(data, scache, ssl_peer_key);
    }

    pub fn Curl_ssl_scache_remove_all(
        cf: *root_self.CurlCfilter,
        data: ?*root_self.CurlEasy,
        ssl_peer_key: [*:0]const u8,
    ) void {
        _ = cf;
        var scache: ?*root_self.CurlSslScache = null;
        var has_share_scache = false;
        var trc_feat: ?*root_self.CurlTrcFeat = null;
        c_ext.Curl_vtls_acc_scache_params(data, &scache, &has_share_scache, &trc_feat);
        vtls_scache_asn1.Curl_ssl_scache_remove_all_zig(data, scache, ssl_peer_key);
    }

    pub fn Curl_ssl_scache_lock(data: ?*root_self.CurlEasy) void {
        vtls_scache_asn1.Curl_ssl_scache_lock_zig(data);
    }

    pub fn Curl_ssl_scache_unlock(data: ?*root_self.CurlEasy) void {
        vtls_scache_asn1.Curl_ssl_scache_unlock_zig(data);
    }

    pub const Curl_Rand = c_ext.Curl_rand_bytes;
    pub const Curl_Rand_alnum = c_ext.Curl_rand_alnum;
    pub const Curl_ssl_certchain = c_ext.Curl_extract_certinfo;
    pub const infof = c_ext.Curl_infof;
    pub const failf = c_ext.Curl_failf;
    pub const traceSsl = c_ext.Curl_trc_cf_infof;
    pub const Curl_multi_waitset_add_sock = c_ext.Curl_pollset_set;
};

pub const CURLE_UNKNOWN_OPTION: CURLcode = 48;

// ============================================================================
// 2. lib/vtls/schannel.c — Windows Schannel Backend
// ============================================================================

const schannel_backend = struct {
    const DWORD = u32;
    const ULONG = c_ulong;
    const LONG = i32;
    const BOOL = i32;
    const BYTE = u8;
    const WORD = u16;
    const ALG_ID = c_uint;
    const SECURITY_STATUS = i32;
    const NTSTATUS = i32;
    const HCERTSTORE = ?*anyopaque;
    const HCRYPTPROV = usize;
    const BCRYPT_ALG_HANDLE = ?*anyopaque;
    const BCRYPT_HASH_HANDLE = ?*anyopaque;
    const HLOCAL = ?*anyopaque;

    const sspi_cc: std.builtin.CallingConvention = if (is_windows) .winapi else .c;

    const SEC_E_OK: SECURITY_STATUS = 0x00000000;
    const SEC_I_CONTINUE_NEEDED: SECURITY_STATUS = 0x00090312;
    const SEC_I_CONTEXT_EXPIRED: SECURITY_STATUS = 0x00090317;
    const SEC_I_INCOMPLETE_CREDENTIALS: SECURITY_STATUS = 0x00090320;
    const SEC_I_RENEGOTIATE: SECURITY_STATUS = 0x00090321;
    const SEC_E_INCOMPLETE_MESSAGE: SECURITY_STATUS = @bitCast(@as(u32, 0x80090318));
    const SEC_E_INSUFFICIENT_MEMORY: SECURITY_STATUS = @bitCast(@as(u32, 0x80090300));
    const SEC_E_UNTRUSTED_ROOT: SECURITY_STATUS = @bitCast(@as(u32, 0x80090325));
    const SEC_E_CERT_EXPIRED: SECURITY_STATUS = @bitCast(@as(u32, 0x80090328));
    const SEC_E_WRONG_PRINCIPAL: SECURITY_STATUS = @bitCast(@as(u32, 0x80090322));
    const SEC_E_ALGORITHM_MISMATCH: SECURITY_STATUS = @bitCast(@as(u32, 0x80090331));
    const CRYPT_E_NO_REVOCATION_CHECK: SECURITY_STATUS = @bitCast(@as(u32, 0x80092012));
    const CRYPT_E_REVOCATION_OFFLINE: SECURITY_STATUS = @bitCast(@as(u32, 0x80092013));
    const CRYPT_E_REVOKED: SECURITY_STATUS = @bitCast(@as(u32, 0x80092010));

    const ERROR_INVALID_PASSWORD: DWORD = 86;
    const CP_UTF8: c_uint = 65001;
    const MB_ERR_INVALID_CHARS: DWORD = 0x00000008;
    const CURL_MAX_INPUT_LENGTH: usize = 8000000;
    const SEEK_SET: c_int = 0;
    const SEEK_END: c_int = 2;

    const SECPKG_CRED_OUTBOUND: ULONG = 0x00000002;
    const SECURITY_NETWORK_DREP: ULONG = 0x00000000;

    const ISC_REQ_SEQUENCE_DETECT: ULONG = 0x00000008;
    const ISC_REQ_REPLAY_DETECT: ULONG = 0x00000004;
    const ISC_REQ_CONFIDENTIALITY: ULONG = 0x00000010;
    const ISC_REQ_ALLOCATE_MEMORY: ULONG = 0x00000100;
    const ISC_REQ_STREAM: ULONG = 0x00008000;
    const ISC_REQ_USE_SUPPLIED_CREDS: ULONG = 0x00000080;
    const ISC_REQ_MANUAL_CRED_VALIDATION: ULONG = 0x00080000;

    const ISC_RET_REPLAY_DETECT: ULONG = 0x00000004;
    const ISC_RET_SEQUENCE_DETECT: ULONG = 0x00000008;
    const ISC_RET_CONFIDENTIALITY: ULONG = 0x00000010;
    const ISC_RET_ALLOCATED_MEMORY: ULONG = 0x00000100;
    const ISC_RET_STREAM: ULONG = 0x00008000;

    const SECBUFFER_EMPTY: ULONG = 0;
    const SECBUFFER_DATA: ULONG = 1;
    const SECBUFFER_TOKEN: ULONG = 2;
    const SECBUFFER_EXTRA: ULONG = 5;
    const SECBUFFER_STREAM_TRAILER: ULONG = 6;
    const SECBUFFER_STREAM_HEADER: ULONG = 7;
    const SECBUFFER_ALERT: ULONG = 17;
    const SECBUFFER_APPLICATION_PROTOCOLS: ULONG = 18;
    const SECBUFFER_VERSION: ULONG = 0;

    const SECPKG_ATTR_STREAM_SIZES: ULONG = 4;
    const SECPKG_ATTR_ENDPOINT_BINDINGS: ULONG = 26;
    const SECPKG_ATTR_APPLICATION_PROTOCOL: ULONG = 35;
    const SECPKG_ATTR_REMOTE_CERT_CONTEXT: ULONG = 0x53;

    const SecApplicationProtocolNegotiationExt_ALPN: u32 = 2;
    const SecApplicationProtocolNegotiationStatus_Success: u32 = 1;

    const SCHANNEL_SHUTDOWN: DWORD = 1;
    const UNISP_NAME_A: [*:0]const u8 = "Microsoft Unified Security Protocol Provider";
    const CURLE_SSL_CACERT_BADFILE: CURLcode = 77;

    const SCH_CRED_VERSION: DWORD = 0x00000004;
    const SCHANNEL_CRED_VERSION: DWORD = 0x00000004;
    const SCH_CREDENTIALS_VERSION: DWORD = 0x00000005;
    const SCH_CRED_MANUAL_CRED_VALIDATION: DWORD = 0x00000008;
    const SCH_CRED_NO_DEFAULT_CREDS: DWORD = 0x00000010;
    const SCH_CRED_AUTO_CRED_VALIDATION: DWORD = 0x00000020;
    const SCH_CRED_USE_DEFAULT_CREDS: DWORD = 0x00000040;
    const SCH_CRED_NO_SERVERNAME_CHECK: DWORD = 0x00000004;
    const SCH_CRED_IGNORE_NO_REVOCATION_CHECK: DWORD = 0x00000800;
    const SCH_CRED_IGNORE_REVOCATION_OFFLINE: DWORD = 0x00001000;
    const SCH_CRED_REVOCATION_CHECK_CHAIN: DWORD = 0x00000200;
    const SCH_USE_STRONG_CRYPTO: DWORD = 0x00400000;

    const SP_PROT_TLS1_0_CLIENT: DWORD = 0x00000080;
    const SP_PROT_TLS1_1_CLIENT: DWORD = 0x00000200;
    const SP_PROT_TLS1_2_CLIENT: DWORD = 0x00000800;
    const SP_PROT_TLS1_3_CLIENT: DWORD = 0x00002000;

    const CURL_SCHANNEL_BUFFER_INIT_SIZE: usize = 4096;
    const CURL_SCHANNEL_BUFFER_FREE_SIZE: usize = 1024;
    const CERT_THUMBPRINT_STR_LEN: usize = 40;
    const CERT_THUMBPRINT_DATA_LEN: usize = 20;
    const MAX_ALLOWED_CERT_AMOUNT: c_int = 100;
    const STRERROR_LEN: usize = 256;

    const PKCS12_NO_PERSIST_KEY: DWORD = 0x00008000;
    const CERT_STORE_PROV_SYSTEM_A: usize = 9;
    const CERT_STORE_OPEN_EXISTING_FLAG: DWORD = 0x00004000;
    const CERT_SYSTEM_STORE_CURRENT_USER: DWORD = 1 << 16;
    const CERT_SYSTEM_STORE_LOCAL_MACHINE: DWORD = 2 << 16;
    const CERT_SYSTEM_STORE_CURRENT_SERVICE: DWORD = 4 << 16;
    const CERT_SYSTEM_STORE_SERVICES: DWORD = 5 << 16;
    const CERT_SYSTEM_STORE_USERS: DWORD = 6 << 16;
    const CERT_SYSTEM_STORE_CURRENT_USER_GROUP_POLICY: DWORD = 7 << 16;
    const CERT_SYSTEM_STORE_LOCAL_MACHINE_GROUP_POLICY: DWORD = 8 << 16;
    const CERT_SYSTEM_STORE_LOCAL_MACHINE_ENTERPRISE: DWORD = 9 << 16;

    const CRYPT_STRING_HEX: DWORD = 0x00000004;
    const CERT_FIND_ANY: DWORD = 0;
    const CERT_FIND_HASH: DWORD = 1 << 16;
    const CERT_FIND_HAS_PRIVATE_KEY: DWORD = 21 << 16;

    const X509_ASN_ENCODING: DWORD = 0x00000001;
    const PKCS_7_ASN_ENCODING: DWORD = 0x00010000;

    const PLATFORM_WINNT: c_int = 2;
    const VERSION_GREATER_THAN_EQUAL: c_int = 3;

    const MPROTO_SCHANNEL_CERT_SHARE_KEY = "tls:schannel:cert:share";

    var s_win_has_alpn: bool = false;

    pub const SecHandle = extern struct {
        dwLower: usize,
        dwUpper: usize,
    };
    pub const CredHandle = SecHandle;
    pub const CtxtHandle = SecHandle;

    pub const TimeStamp = extern struct {
        LowPart: u32,
        HighPart: i32,
    };

    pub const SecBuffer = extern struct {
        cbBuffer: ULONG,
        BufferType: ULONG,
        pvBuffer: ?*anyopaque,
    };

    pub const SecBufferDesc = extern struct {
        ulVersion: ULONG,
        cBuffers: ULONG,
        pBuffers: ?[*]SecBuffer,
    };

    pub const SecPkgContext_StreamSizes = extern struct {
        cbHeader: ULONG,
        cbTrailer: ULONG,
        cbMaximumMessage: ULONG,
        cBuffers: ULONG,
        cbBlockSize: ULONG,
    };

    pub const SecPkgContext_ApplicationProtocol = extern struct {
        ProtoNegoStatus: u32,
        ProtoNegoExt: u32,
        ProtocolIdSize: u8,
        ProtocolId: [255]u8,
    };

    pub const SCHANNEL_CRED = extern struct {
        dwVersion: DWORD,
        cCreds: DWORD,
        paCred: ?*?*const CERT_CONTEXT,
        hRootStore: HCERTSTORE,
        cMappers: DWORD,
        aphMappers: ?*anyopaque,
        cSupportedAlgs: DWORD,
        palgSupportedAlgs: ?[*]ALG_ID,
        grbitEnabledProtocols: DWORD,
        dwMinimumCipherStrength: DWORD,
        dwMaximumCipherStrength: DWORD,
        dwSessionLifespan: DWORD,
        dwFlags: DWORD,
        dwCredFormat: DWORD,
    };

    pub const UNICODE_STRING = extern struct {
        Length: WORD = 0,
        MaximumLength: WORD = 0,
        Buffer: ?[*]u16 = null,
    };

    pub const CRYPTO_SETTINGS = extern struct {
        eAlgorithmUsage: c_int = 0,
        strCngAlgId: UNICODE_STRING = .{},
        cChainingModes: DWORD = 0,
        rgstrChainingModes: ?*UNICODE_STRING = null,
        dwMinBitLength: DWORD = 0,
        dwMaxBitLength: DWORD = 0,
    };

    pub const TLS_PARAMETERS = extern struct {
        cAlpnIds: DWORD = 0,
        rgstrAlpnIds: ?*UNICODE_STRING = null,
        grbitDisabledProtocols: DWORD = 0,
        cDisabledCrypto: DWORD = 0,
        pDisabledCrypto: ?[*]CRYPTO_SETTINGS = null,
        dwFlags: DWORD = 0,
    };

    pub const SCH_CREDENTIALS = extern struct {
        dwVersion: DWORD = SCH_CREDENTIALS_VERSION,
        dwCredFormat: DWORD = 0,
        cCreds: DWORD = 0,
        paCred: ?*?*const CERT_CONTEXT = null,
        hRootStore: HCERTSTORE = null,
        cMappers: DWORD = 0,
        aphMappers: ?*anyopaque = null,
        dwSessionLifespan: DWORD = 0,
        dwFlags: DWORD = 0,
        cTlsParameters: DWORD = 0,
        pTlsParameters: ?*TLS_PARAMETERS = null,
    };

    pub const CRYPT_DATA_BLOB = extern struct {
        cbData: DWORD,
        pbData: ?[*]u8,
    };
    pub const CRYPT_HASH_BLOB = CRYPT_DATA_BLOB;

    pub const CRYPT_BIT_BLOB = extern struct {
        cbData: DWORD,
        pbData: ?[*]u8,
        cUnusedBits: DWORD,
    };

    pub const CRYPT_ALGORITHM_IDENTIFIER = extern struct {
        pszObjId: ?[*:0]u8,
        Parameters: CRYPT_DATA_BLOB,
    };

    pub const FILETIME = extern struct {
        dwLowDateTime: DWORD,
        dwHighDateTime: DWORD,
    };

    pub const CERT_PUBLIC_KEY_INFO = extern struct {
        Algorithm: CRYPT_ALGORITHM_IDENTIFIER,
        PublicKey: CRYPT_BIT_BLOB,
    };

    pub const CERT_INFO = extern struct {
        dwVersion: DWORD,
        SerialNumber: CRYPT_DATA_BLOB,
        SignatureAlgorithm: CRYPT_ALGORITHM_IDENTIFIER,
        Issuer: CRYPT_DATA_BLOB,
        NotBefore: FILETIME,
        NotAfter: FILETIME,
        Subject: CRYPT_DATA_BLOB,
        SubjectPublicKeyInfo: CERT_PUBLIC_KEY_INFO,
        IssuerUniqueId: CRYPT_BIT_BLOB,
        SubjectUniqueId: CRYPT_BIT_BLOB,
        cExtension: DWORD,
        rgExtension: ?*anyopaque,
    };

    pub const CERT_CONTEXT = extern struct {
        dwCertEncodingType: DWORD,
        pbCertEncoded: ?[*]u8,
        cbCertEncoded: DWORD,
        pCertInfo: ?*CERT_INFO,
        hCertStore: HCERTSTORE,
    };

    pub const CurlSchannelCred = extern struct {
        cred_handle: CredHandle,
        sni_hostname: ?[*:0]u8,
        client_cert_store: HCERTSTORE,
        refcount: c_int,
    };

    pub const CurlSchannelCtxt = extern struct {
        ctxt_handle: CtxtHandle,
    };

    const SecPkgContext_Bindings = extern struct {
        BindingsLength: ULONG,
        Bindings: ?*anyopaque,
    };

    pub const SBuffer = extern struct {
        length: usize,
        offset: usize,
        buffer: ?[*]u8,
    };

    pub const SchannelRenegotiateState = extern struct {
        started: bool,
        start_time: CurlTime,
        io_need: c_int,
    };

    pub const SchannelSslBackendData = extern struct {
        send_buffer: ?[*]u8,
        send_buffer_len: usize,
        encdata: SBuffer,
        decdata: SBuffer,
        cred: ?*CurlSchannelCred,
        ctxt: ?*CurlSchannelCtxt,
        shutdown_token: SecBuffer,
        shutdown_offset: usize,
        stream_sizes: SecPkgContext_StreamSizes,
        req_flags: ULONG,
        ret_flags: ULONG,
        recv_unrecoverable_err: CURLcode,
        renegotiate_state: SchannelRenegotiateState,
        flags: c_uint,

        pub fn recv_sspi_close_notify(self: *const SchannelSslBackendData) bool {
            return (self.flags & (1 << 0)) != 0;
        }
        pub fn set_recv_sspi_close_notify(self: *SchannelSslBackendData, v: bool) void {
            if (v) self.flags |= (1 << 0) else self.flags &= ~@as(c_uint, 1 << 0);
        }
        pub fn recv_connection_closed(self: *const SchannelSslBackendData) bool {
            return (self.flags & (1 << 1)) != 0;
        }
        pub fn set_recv_connection_closed(self: *SchannelSslBackendData, v: bool) void {
            if (v) self.flags |= (1 << 1) else self.flags &= ~@as(c_uint, 1 << 1);
        }
        pub fn recv_renegotiating(self: *const SchannelSslBackendData) bool {
            return (self.flags & (1 << 2)) != 0;
        }
        pub fn set_recv_renegotiating(self: *SchannelSslBackendData, v: bool) void {
            if (v) self.flags |= (1 << 2) else self.flags &= ~@as(c_uint, 1 << 2);
        }
        pub fn use_alpn(self: *const SchannelSslBackendData) bool {
            return (self.flags & (1 << 3)) != 0;
        }
        pub fn set_use_alpn(self: *SchannelSslBackendData, v: bool) void {
            if (v) self.flags |= (1 << 3) else self.flags &= ~@as(c_uint, 1 << 3);
        }
        pub fn use_manual_cred_validation(self: *const SchannelSslBackendData) bool {
            return (self.flags & (1 << 4)) != 0;
        }
        pub fn set_use_manual_cred_validation(self: *SchannelSslBackendData, v: bool) void {
            if (v) self.flags |= (1 << 4) else self.flags &= ~@as(c_uint, 1 << 4);
        }
        pub fn sent_shutdown(self: *const SchannelSslBackendData) bool {
            return (self.flags & (1 << 5)) != 0;
        }
        pub fn set_sent_shutdown(self: *SchannelSslBackendData, v: bool) void {
            if (v) self.flags |= (1 << 5) else self.flags &= ~@as(c_uint, 1 << 5);
        }
        pub fn shutdown_generated(self: *const SchannelSslBackendData) bool {
            return (self.flags & (1 << 6)) != 0;
        }
        pub fn set_shutdown_generated(self: *SchannelSslBackendData, v: bool) void {
            if (v) self.flags |= (1 << 6) else self.flags &= ~@as(c_uint, 1 << 6);
        }
        pub fn encdata_is_incomplete(self: *const SchannelSslBackendData) bool {
            return (self.flags & (1 << 7)) != 0;
        }
        pub fn set_encdata_is_incomplete(self: *SchannelSslBackendData, v: bool) void {
            if (v) self.flags |= (1 << 7) else self.flags &= ~@as(c_uint, 1 << 7);
        }
    };

    const SchCertShare = extern struct {
        CAinfo_blob_digest: [CURL_SHA256_DIGEST_LENGTH]u8,
        CAinfo_blob_size: usize,
        CAfile: ?[*:0]u8,
        cert_store: HCERTSTORE,
        time: CurlTime,
    };

    pub const SecurityFunctionTableA = extern struct {
        dwVersion: ULONG,
        EnumerateSecurityPackagesA: ?*const anyopaque,
        QueryCredentialsAttributesA: ?*const anyopaque,
        AcquireCredentialsHandleA: *const fn (
            pszPrincipal: ?[*:0]const u8,
            pszPackage: [*:0]const u8,
            fCredentialUse: ULONG,
            pvLogonId: ?*anyopaque,
            pAuthData: ?*anyopaque,
            pGetKeyFn: ?*const anyopaque,
            pvGetKeyArgument: ?*anyopaque,
            phCredential: *CredHandle,
            ptsExpiry: ?*TimeStamp,
        ) callconv(sspi_cc) SECURITY_STATUS,
        FreeCredentialsHandle: *const fn (phCredential: *CredHandle) callconv(sspi_cc) SECURITY_STATUS,
        Reserved2: ?*anyopaque,
        InitializeSecurityContextA: *const fn (
            phCredential: ?*CredHandle,
            phContext: ?*CtxtHandle,
            pszTargetName: ?[*:0]const u8,
            fContextReq: ULONG,
            Reserved1: ULONG,
            TargetDataRep: ULONG,
            pInput: ?*SecBufferDesc,
            Reserved2: ULONG,
            phNewContext: ?*CtxtHandle,
            pOutput: ?*SecBufferDesc,
            pfContextAttr: *ULONG,
            ptsExpiry: ?*TimeStamp,
        ) callconv(sspi_cc) SECURITY_STATUS,
        AcceptSecurityContext: ?*const anyopaque,
        CompleteAuthToken: ?*const anyopaque,
        DeleteSecurityContext: *const fn (phContext: *CtxtHandle) callconv(sspi_cc) SECURITY_STATUS,
        ApplyControlToken: *const fn (phContext: *CtxtHandle, pInput: *SecBufferDesc) callconv(sspi_cc) SECURITY_STATUS,
        QueryContextAttributesA: *const fn (phContext: *CtxtHandle, ulAttribute: ULONG, pBuffer: *anyopaque) callconv(sspi_cc) SECURITY_STATUS,
        ImpersonateSecurityContext: ?*const anyopaque,
        RevertSecurityContext: ?*const anyopaque,
        MakeSignature: ?*const anyopaque,
        VerifySignature: ?*const anyopaque,
        FreeContextBuffer: *const fn (pvContextBuffer: ?*anyopaque) callconv(sspi_cc) SECURITY_STATUS,
        QuerySecurityPackageInfoA: ?*const anyopaque,
        Reserved3: ?*anyopaque,
        Reserved4: ?*anyopaque,
        ExportSecurityContext: ?*const anyopaque,
        ImportSecurityContextA: ?*const anyopaque,
        AddCredentialsA: ?*const anyopaque,
        Reserved8: ?*anyopaque,
        QuerySecurityContextToken: ?*const anyopaque,
        EncryptMessage: *const fn (phContext: *CtxtHandle, fQOP: ULONG, pMessage: *SecBufferDesc, MessageSeqNo: ULONG) callconv(sspi_cc) SECURITY_STATUS,
        DecryptMessage: *const fn (phContext: *CtxtHandle, pMessage: *SecBufferDesc, MessageSeqNo: ULONG, pfQOP: ?*ULONG) callconv(sspi_cc) SECURITY_STATUS,
        SetContextAttributesA: ?*const anyopaque,
    };

    const win_ext = struct {
        extern var Curl_pSecFn: ?*SecurityFunctionTableA;
        extern "ws2_32" fn WSAGetLastError() callconv(sspi_cc) c_int;
        extern "crypt32" fn CertOpenStore(
            lpszStoreProvider: usize,
            dwEncodingType: DWORD,
            hCryptProv: HCRYPTPROV,
            dwFlags: DWORD,
            pvPara: ?*const anyopaque,
        ) callconv(sspi_cc) HCERTSTORE;
        extern "crypt32" fn CertCloseStore(hCertStore: HCERTSTORE, dwFlags: DWORD) callconv(sspi_cc) BOOL;
        extern "crypt32" fn CertFreeCertificateContext(pCertContext: ?*const CERT_CONTEXT) callconv(sspi_cc) BOOL;
        extern "crypt32" fn CertFindCertificateInStore(
            hCertStore: HCERTSTORE,
            dwCertEncodingType: DWORD,
            dwFindFlags: DWORD,
            dwFindType: DWORD,
            pvFindPara: ?*const anyopaque,
            pPrevCertContext: ?*const CERT_CONTEXT,
        ) callconv(sspi_cc) ?*const CERT_CONTEXT;
        extern "crypt32" fn CertEnumCertificatesInStore(
            hCertStore: HCERTSTORE,
            pPrevCertContext: ?*const CERT_CONTEXT,
        ) callconv(sspi_cc) ?*const CERT_CONTEXT;
        extern "crypt32" fn CryptStringToBinaryA(
            pszString: [*]const u8,
            cchString: DWORD,
            dwFlags: DWORD,
            pbBinary: ?[*]u8,
            pcbBinary: *DWORD,
            pdwSkip: ?*DWORD,
            pdwFlags: ?*DWORD,
        ) callconv(sspi_cc) BOOL;
        extern "crypt32" fn PFXImportCertStore(
            pPFX: *const CRYPT_DATA_BLOB,
            szPassword: ?[*:0]const u16,
            dwFlags: DWORD,
        ) callconv(sspi_cc) HCERTSTORE;
        extern "kernel32" fn GetLastError() callconv(sspi_cc) DWORD;
        extern "kernel32" fn GetModuleHandleA(lpModuleName: ?[*:0]const u8) callconv(sspi_cc) ?*anyopaque;
        extern "kernel32" fn GetProcAddress(hModule: ?*anyopaque, lpProcName: [*:0]const u8) callconv(sspi_cc) ?*const anyopaque;
        extern "kernel32" fn MultiByteToWideChar(
            CodePage: c_uint,
            dwFlags: DWORD,
            lpMultiByteStr: [*]const u8,
            cbMultiByte: c_int,
            lpWideCharStr: ?[*]u16,
            cchWideChar: c_int,
        ) callconv(sspi_cc) c_int;
        extern fn fseek(stream: *anyopaque, offset: c_long, whence: c_int) callconv(.c) c_int;
        extern fn ftell(stream: *anyopaque) callconv(.c) c_long;
        extern fn fread(ptr: [*]u8, size: usize, nmemb: usize, stream: *anyopaque) callconv(.c) usize;
        extern fn fclose(stream: *anyopaque) callconv(.c) c_int;
        extern fn Curl_verify_certificate(cf: *CurlCfilter, data: ?*CurlEasy) callconv(.c) CURLcode;
        extern fn Curl_verify_host(cf: *CurlCfilter, data: ?*CurlEasy) callconv(.c) CURLcode;
        extern fn curlx_verify_windows_version(majorVersion: c_uint, minorVersion: c_uint, buildVersion: c_uint, platform: c_int, condition: c_int) callconv(.c) bool;
        extern fn Curl_sspi_strerror(err: i32, buf: [*]u8, buflen: usize) callconv(.c) [*:0]const u8;
        extern fn Curl_sspi_global_init() callconv(.c) CURLcode;
        extern fn Curl_sspi_global_cleanup() callconv(.c) void;
        extern fn curlx_str_number(linep: *[*:0]const u8, nump: *i64, max: i64) callconv(.c) c_int;
        extern fn Curl_pgrsUpdate(data: ?*CurlEasy) callconv(.c) CURLcode;
        extern fn Curl_vtls_acc_multi_proto_hash(data: ?*CurlEasy) callconv(.c) ?*anyopaque;
        extern fn Curl_vtls_acc_conn_get_ssl_context(conn: ?*ConnectData) callconv(.c) ?*anyopaque;
        extern fn Curl_vtls_acc_conn_set_ssl_context(conn: ?*ConnectData, ctx: ?*anyopaque) callconv(.c) void;
        extern fn Curl_hash_pick(h: *anyopaque, key: *const anyopaque, key_len: usize) callconv(.c) ?*anyopaque;
        extern fn Curl_hash_add2(
            h: *anyopaque,
            key: *const anyopaque,
            key_len: usize,
            p: *anyopaque,
            dtor: *const fn (key: *const anyopaque, key_len: usize, p: *anyopaque) callconv(.c) void,
        ) callconv(.c) ?*anyopaque;
    };

    inline fn initSecBuffer(buf: *SecBuffer, buf_type: ULONG, pv: ?*anyopaque, cb: ULONG) void {
        buf.cbBuffer = cb;
        buf.BufferType = buf_type;
        buf.pvBuffer = pv;
    }

    inline fn initSecBufferDesc(desc: *SecBufferDesc, buffers: [*]SecBuffer, count: ULONG) void {
        desc.ulVersion = SECBUFFER_VERSION;
        desc.cBuffers = count;
        desc.pBuffers = buffers;
    }

    fn schannelMemdup0(src: [*]const u8, len: usize) ?[*:0]u8 {
        const buf = mem.malloc(len + 1) orelse return null;
        if (len > 0) @memcpy(buf[0..len], src[0..len]);
        buf[len] = 0;
        return @ptrCast(buf);
    }

    fn setSslVersionMinMax(enabled_protocols: *DWORD, cf: *CurlCfilter, data: ?*CurlEasy) CURLcode {
        const conn_config = vtls_impl.Curl_ssl_cf_get_filter_config(cf) orelse return CURLE_SSL_CONNECT_ERROR;
        const ssl_version: u32 = conn_config.version;
        var ssl_version_max: u32 = @intCast(conn_config.version_max);

        switch (ssl_version_max) {
            CURL_SSLVERSION_MAX_NONE, CURL_SSLVERSION_MAX_DEFAULT => {
                if (win_ext.curlx_verify_windows_version(10, 0, 20348, PLATFORM_WINNT, VERSION_GREATER_THAN_EQUAL)) {
                    ssl_version_max = CURL_SSLVERSION_MAX_TLSv1_3;
                } else {
                    ssl_version_max = CURL_SSLVERSION_MAX_TLSv1_2;
                }
            },
            else => {},
        }

        var i: u32 = ssl_version;
        while (i <= (ssl_version_max >> 16)) : (i += 1) {
            switch (@as(u8, @intCast(i))) {
                CURL_SSLVERSION_TLSv1_0 => enabled_protocols.* |= SP_PROT_TLS1_0_CLIENT,
                CURL_SSLVERSION_TLSv1_1 => enabled_protocols.* |= SP_PROT_TLS1_1_CLIENT,
                CURL_SSLVERSION_TLSv1_2 => enabled_protocols.* |= SP_PROT_TLS1_2_CLIENT,
                CURL_SSLVERSION_TLSv1_3 => {
                    if (win_ext.curlx_verify_windows_version(10, 0, 20348, PLATFORM_WINNT, VERSION_GREATER_THAN_EQUAL)) {
                        enabled_protocols.* |= SP_PROT_TLS1_3_CLIENT;
                    } else {
                        c_ext.Curl_failf(data, "schannel: TLS 1.3 not supported on Windows 10 or older");
                        return CURLE_SSL_CONNECT_ERROR;
                    }
                },
                else => {},
            }
        }
        return CURLE_OK;
    }

    const Algo = struct {
        name: []const u8,
        id: c_int,
    };

    const NUM_CIPHERS: usize = 47;

    const algs = [NUM_CIPHERS]Algo{
        .{ .name = "CALG_MD2", .id = 0x00008001 },
        .{ .name = "CALG_MD4", .id = 0x00008002 },
        .{ .name = "CALG_MD5", .id = 0x00008003 },
        .{ .name = "CALG_SHA", .id = 0x00008004 },
        .{ .name = "CALG_SHA1", .id = 0x00008004 },
        .{ .name = "CALG_MAC", .id = 0x00008005 },
        .{ .name = "CALG_RSA_SIGN", .id = 0x00002400 },
        .{ .name = "CALG_DSS_SIGN", .id = 0x00002200 },
        .{ .name = "CALG_NO_SIGN", .id = 0x00002000 },
        .{ .name = "CALG_RSA_KEYX", .id = 0x0000a400 },
        .{ .name = "CALG_DES", .id = 0x00006601 },
        .{ .name = "CALG_3DES_112", .id = 0x00006609 },
        .{ .name = "CALG_3DES", .id = 0x00006603 },
        .{ .name = "CALG_DESX", .id = 0x00006604 },
        .{ .name = "CALG_RC2", .id = 0x00006602 },
        .{ .name = "CALG_RC4", .id = 0x00006801 },
        .{ .name = "CALG_SEAL", .id = 0x00006802 },
        .{ .name = "CALG_DH_SF", .id = 0x0000aa01 },
        .{ .name = "CALG_DH_EPHEM", .id = 0x0000aa02 },
        .{ .name = "CALG_AGREEDKEY_ANY", .id = 0x0000aa03 },
        .{ .name = "CALG_HUGHES_MD5", .id = 0x0000a003 },
        .{ .name = "CALG_SKIPJACK", .id = 0x0000660a },
        .{ .name = "CALG_TEK", .id = 0x0000660b },
        .{ .name = "CALG_CYLINK_MEK", .id = 0x0000660c },
        .{ .name = "CALG_SSL3_SHAMD5", .id = 0x00008008 },
        .{ .name = "CALG_SSL3_MASTER", .id = 0x00004c01 },
        .{ .name = "CALG_SCHANNEL_MASTER_HASH", .id = 0x00004c02 },
        .{ .name = "CALG_SCHANNEL_MAC_KEY", .id = 0x00004c03 },
        .{ .name = "CALG_SCHANNEL_ENC_KEY", .id = 0x00004c07 },
        .{ .name = "CALG_PCT1_MASTER", .id = 0x00004c04 },
        .{ .name = "CALG_SSL2_MASTER", .id = 0x00004c05 },
        .{ .name = "CALG_TLS1_MASTER", .id = 0x00004c06 },
        .{ .name = "CALG_RC5", .id = 0x0000660d },
        .{ .name = "CALG_HMAC", .id = 0x00008009 },
        .{ .name = "CALG_TLS1PRF", .id = 0x0000800a },
        .{ .name = "CALG_HASH_REPLACE_OWF", .id = 0x0000800b },
        .{ .name = "CALG_AES_128", .id = 0x0000660e },
        .{ .name = "CALG_AES_192", .id = 0x0000660f },
        .{ .name = "CALG_AES_256", .id = 0x00006610 },
        .{ .name = "CALG_AES", .id = 0x00006611 },
        .{ .name = "CALG_SHA_256", .id = 0x0000800c },
        .{ .name = "CALG_SHA_384", .id = 0x0000800d },
        .{ .name = "CALG_SHA_512", .id = 0x0000800e },
        .{ .name = "CALG_ECDH", .id = 0x0000aa05 },
        .{ .name = "CALG_ECMQV", .id = 0x0000a001 },
        .{ .name = "CALG_ECDSA", .id = 0x00002203 },
        .{ .name = "CALG_ECDH_EPHEM", .id = 0x0000ae06 },
    };

    fn getAlgIdByName(name: [*:0]const u8) c_int {
        const s = std.mem.span(name);
        const n = std.mem.indexOfScalar(u8, s, ':') orelse s.len;
        for (algs) |entry| {
            if (entry.name.len == n and std.mem.eql(u8, entry.name, s[0..n])) {
                return entry.id;
            }
        }
        return 0;
    }

    fn setSslCiphers(schannel_cred: *SCHANNEL_CRED, ciphers: [*:0]const u8, alg_ids: *[NUM_CIPHERS]ALG_ID) CURLcode {
        var start_cur: ?[*:0]const u8 = ciphers;
        var alg_count: usize = 0;
        while (start_cur) |cur_init| {
            if (cur_init[0] == 0 or alg_count >= NUM_CIPHERS) break;
            var cur: [*:0]const u8 = cur_init;
            var alg: i64 = 0;
            if (win_ext.curlx_str_number(&cur, &alg, std.math.maxInt(c_int)) != 0 or alg == 0) {
                alg = getAlgIdByName(cur);
            }
            if (alg != 0) {
                alg_ids[alg_count] = @intCast(alg);
                alg_count += 1;
            } else {
                const cur_slice = std.mem.span(cur);
                if (std.mem.startsWith(u8, cur_slice, "USE_STRONG_CRYPTO") or
                    std.mem.startsWith(u8, cur_slice, "SCH_USE_STRONG_CRYPTO"))
                {
                    schannel_cred.dwFlags |= SCH_USE_STRONG_CRYPTO;
                } else {
                    return CURLE_SSL_CIPHER;
                }
            }
            const rest = std.mem.span(cur);
            if (std.mem.indexOfScalar(u8, rest, ':')) |colon_idx| {
                start_cur = cur + colon_idx + 1;
            } else {
                start_cur = null;
            }
        }
        schannel_cred.palgSupportedAlgs = alg_ids;
        schannel_cred.cSupportedAlgs = @intCast(alg_count);
        return CURLE_OK;
    }

    fn getCertLocation(
        path: [*:0]const u8,
        store_name: *DWORD,
        store_path: *?[*:0]u8,
        thumbprint: *?[*:0]const u8,
    ) CURLcode {
        const path_slice = std.mem.span(path);
        const first_sep = std.mem.indexOfScalar(u8, path_slice, '\\') orelse return CURLE_SSL_CERTPROBLEM;
        const store_name_slice = path_slice[0..first_sep];

        if (std.mem.eql(u8, store_name_slice, "CurrentUser")) {
            store_name.* = CERT_SYSTEM_STORE_CURRENT_USER;
        } else if (std.mem.eql(u8, store_name_slice, "LocalMachine")) {
            store_name.* = CERT_SYSTEM_STORE_LOCAL_MACHINE;
        } else if (std.mem.eql(u8, store_name_slice, "CurrentService")) {
            store_name.* = CERT_SYSTEM_STORE_CURRENT_SERVICE;
        } else if (std.mem.eql(u8, store_name_slice, "Services")) {
            store_name.* = CERT_SYSTEM_STORE_SERVICES;
        } else if (std.mem.eql(u8, store_name_slice, "Users")) {
            store_name.* = CERT_SYSTEM_STORE_USERS;
        } else if (std.mem.eql(u8, store_name_slice, "CurrentUserGroupPolicy")) {
            store_name.* = CERT_SYSTEM_STORE_CURRENT_USER_GROUP_POLICY;
        } else if (std.mem.eql(u8, store_name_slice, "LocalMachineGroupPolicy")) {
            store_name.* = CERT_SYSTEM_STORE_LOCAL_MACHINE_GROUP_POLICY;
        } else if (std.mem.eql(u8, store_name_slice, "LocalMachineEnterprise")) {
            store_name.* = CERT_SYSTEM_STORE_LOCAL_MACHINE_ENTERPRISE;
        } else {
            return CURLE_SSL_CERTPROBLEM;
        }

        const remainder = path_slice[first_sep + 1 ..];
        const second_sep = std.mem.indexOfScalar(u8, remainder, '\\') orelse return CURLE_SSL_CERTPROBLEM;

        const tp_offset = first_sep + 1 + second_sep + 1;
        const tp_ptr: [*:0]const u8 = path + tp_offset;
        if (std.mem.len(tp_ptr) != CERT_THUMBPRINT_STR_LEN) {
            return CURLE_SSL_CERTPROBLEM;
        }
        thumbprint.* = tp_ptr;

        const sp_slice = remainder[0..second_sep];
        const raw_sp = mem.malloc(sp_slice.len + 1) orelse return CURLE_OUT_OF_MEMORY;
        const sp_buf: [*]u8 = @ptrCast(raw_sp);
        if (sp_slice.len > 0) {
            @memcpy(sp_buf[0..sp_slice.len], sp_slice);
        }
        sp_buf[sp_slice.len] = 0;
        store_path.* = @ptrCast(sp_buf);

        return CURLE_OK;
    }

    fn getClientCert(
        cf: *CurlCfilter,
        data: ?*CurlEasy,
        out_cert_store: *HCERTSTORE,
        out_cert_context: *?*const CERT_CONTEXT,
    ) CURLcode {
        const sslc = vtls_impl.Curl_ssl_cf_get_filter_config(cf) orelse return CURLE_SSL_CONNECT_ERROR;
        var client_cert: ?*const CERT_CONTEXT = null;
        var client_cert_store: HCERTSTORE = null;
        var result: CURLcode = CURLE_OK;

        if (sslc.clientcert != null or sslc.cert_blob != null) {
            var cert_store_name: DWORD = 0;
            var cert_store_path: ?[*:0]u8 = null;
            var cert_thumbprint_str: ?[*:0]const u8 = null;
            var cert_thumbprint_buf: [CERT_THUMBPRINT_STR_LEN + 1]u8 = @splat(0);
            var cert_store: HCERTSTORE = null;
            var fInCert: ?*anyopaque = null;
            var certdata: ?[*]u8 = null;
            var certsize: usize = 0;
            const blob = sslc.cert_blob != null;

            if (blob) {
                const cb = sslc.cert_blob.?;
                certdata = @ptrCast(@constCast(cb.data));
                certsize = cb.len;
            } else {
                const clientcert = sslc.clientcert.?;
                const cert_path = mem.strdup(clientcert) orelse return CURLE_OUT_OF_MEMORY;
                result = getCertLocation(cert_path, &cert_store_name, &cert_store_path, &cert_thumbprint_str);
                if (result == CURLE_OK and cert_thumbprint_str != null) {
                    @memcpy(cert_thumbprint_buf[0 .. CERT_THUMBPRINT_STR_LEN + 1], cert_thumbprint_str.?[0 .. CERT_THUMBPRINT_STR_LEN + 1]);
                    cert_thumbprint_str = @ptrCast(&cert_thumbprint_buf);
                }
                mem.free(cert_path);
                if (result != CURLE_OK and clientcert[0] != 0) {
                    fInCert = os_leaf.win32.curlx_win32_fopen(clientcert, "rb");
                }
                if (result != CURLE_OK and fInCert == null) {
                    c_ext.Curl_failf(
                        data,
                        "schannel: Failed to get certificate location or file for %s",
                        clientcert,
                    );
                    return result;
                }
            }

            if ((fInCert != null or blob) and sslc.cert_type != null and
                primitives.curl_strequal(sslc.cert_type.?, "P12") == 0)
            {
                c_ext.Curl_failf(
                    data,
                    "schannel: certificate format compatibility error for %s",
                    if (blob) @as([*:0]const u8, "(memory blob)") else @as([*:0]const u8, sslc.clientcert.?),
                );
                if (cert_store_path) |sp| mem.free(sp);
                if (fInCert) |f| _ = win_ext.fclose(f);
                return CURLE_SSL_CERTPROBLEM;
            }

            if (fInCert != null or blob) {
                const cert_showfilename_error: [*:0]const u8 = if (blob) "(memory blob)" else sslc.clientcert.?;
                if (cert_store_path) |sp| {
                    mem.free(sp);
                    cert_store_path = null;
                }
                if (fInCert) |f| {
                    var continue_reading = (win_ext.fseek(f, 0, SEEK_END) == 0);
                    if (continue_reading) {
                        const cert_tell = win_ext.ftell(f);
                        if (cert_tell < 0) {
                            continue_reading = false;
                        } else {
                            certsize = @intCast(cert_tell);
                        }
                    }
                    if (continue_reading) {
                        continue_reading = (win_ext.fseek(f, 0, SEEK_SET) == 0);
                    }
                    if (continue_reading and certsize < CURL_MAX_INPUT_LENGTH) {
                        if (mem.malloc(certsize + 1)) |raw_cd| {
                            certdata = @ptrCast(raw_cd);
                        }
                    }
                    if (certdata == null or win_ext.fread(certdata.?, certsize, 1, f) != 1) {
                        continue_reading = false;
                    }
                    _ = win_ext.fclose(f);
                    if (!continue_reading) {
                        c_ext.Curl_failf(data, "schannel: Failed to read cert file %s", sslc.clientcert.?);
                        if (certdata) |cd| {
                            mem.secureZero(cd, certsize + 1);
                            mem.freeSized(cd, certsize + 1);
                        }
                        return CURLE_SSL_CERTPROBLEM;
                    }
                }

                const datablob = CRYPT_DATA_BLOB{
                    .pbData = certdata,
                    .cbData = @intCast(certsize),
                };

                const pwd_len: usize = if (sslc.key_passwd) |kp| std.mem.len(kp) else 0;
                if (mem.malloc(@sizeOf(u16) * (pwd_len + 1))) |raw_pw| {
                    const pszPassword: [*]u16 = @ptrCast(@alignCast(raw_pw));
                    var str_w_len: c_int = 0;
                    if (pwd_len > 0) {
                        str_w_len = win_ext.MultiByteToWideChar(
                            CP_UTF8,
                            MB_ERR_INVALID_CHARS,
                            sslc.key_passwd.?,
                            @intCast(pwd_len),
                            pszPassword,
                            @intCast(pwd_len + 1),
                        );
                    }
                    if (str_w_len >= 0 and @as(usize, @intCast(str_w_len)) <= pwd_len) {
                        pszPassword[@intCast(str_w_len)] = 0;
                    } else {
                        pszPassword[0] = 0;
                    }

                    cert_store = win_ext.PFXImportCertStore(
                        &datablob,
                        @ptrCast(pszPassword),
                        PKCS12_NO_PERSIST_KEY,
                    );
                    mem.secureZero(@ptrCast(pszPassword), @sizeOf(u16) * (pwd_len + 1));
                    mem.freeSized(raw_pw, @sizeOf(u16) * (pwd_len + 1));
                }

                if (!blob) {
                    if (certdata) |cd| {
                        mem.secureZero(cd, certsize + 1);
                        mem.freeSized(cd, certsize + 1);
                    }
                }

                if (cert_store == null) {
                    const errorcode = win_ext.GetLastError();
                    if (errorcode == ERROR_INVALID_PASSWORD) {
                        c_ext.Curl_failf(
                            data,
                            "schannel: Failed to import cert file %s, password is bad",
                            cert_showfilename_error,
                        );
                    } else {
                        c_ext.Curl_failf(
                            data,
                            "schannel: Failed to import cert file %s, last error is 0x%08lx",
                            cert_showfilename_error,
                            @as(c_ulong, errorcode),
                        );
                    }
                    return CURLE_SSL_CERTPROBLEM;
                }

                const cert_find_flags: DWORD = if (win_ext.curlx_verify_windows_version(
                    6,
                    2,
                    0,
                    PLATFORM_WINNT,
                    VERSION_GREATER_THAN_EQUAL,
                )) CERT_FIND_HAS_PRIVATE_KEY else CERT_FIND_ANY;

                client_cert = win_ext.CertFindCertificateInStore(
                    cert_store,
                    X509_ASN_ENCODING | PKCS_7_ASN_ENCODING,
                    0,
                    cert_find_flags,
                    null,
                    null,
                );

                if (client_cert == null) {
                    c_ext.Curl_failf(
                        data,
                        "schannel: Failed to get certificate from file %s, last error is 0x%08lx",
                        cert_showfilename_error,
                        @as(c_ulong, win_ext.GetLastError()),
                    );
                    _ = win_ext.CertCloseStore(cert_store, 0);
                    return CURLE_SSL_CERTPROBLEM;
                }
            } else {
                cert_store = win_ext.CertOpenStore(
                    CERT_STORE_PROV_SYSTEM_A,
                    0,
                    0,
                    CERT_STORE_OPEN_EXISTING_FLAG | cert_store_name,
                    cert_store_path,
                );
                if (cert_store == null) {
                    c_ext.Curl_failf(
                        data,
                        "schannel: Failed to open cert store %lx %s, last error is 0x%08lx",
                        @as(c_ulong, cert_store_name),
                        if (cert_store_path) |sp| @as([*:0]const u8, sp) else "(unknown)",
                        @as(c_ulong, win_ext.GetLastError()),
                    );
                    if (cert_store_path) |sp| mem.free(sp);
                    return CURLE_SSL_CERTPROBLEM;
                }
                if (cert_store_path) |sp| {
                    mem.free(sp);
                    cert_store_path = null;
                }

                var cert_thumbprint_data: [CERT_THUMBPRINT_DATA_LEN]u8 = undefined;
                var cert_thumbprint = CRYPT_HASH_BLOB{
                    .pbData = &cert_thumbprint_data,
                    .cbData = CERT_THUMBPRINT_DATA_LEN,
                };

                if (win_ext.CryptStringToBinaryA(
                    cert_thumbprint_str.?,
                    CERT_THUMBPRINT_STR_LEN,
                    CRYPT_STRING_HEX,
                    &cert_thumbprint_data,
                    &cert_thumbprint.cbData,
                    null,
                    null,
                ) == 0) {
                    _ = win_ext.CertCloseStore(cert_store, 0);
                    return CURLE_SSL_CERTPROBLEM;
                }

                client_cert = win_ext.CertFindCertificateInStore(
                    cert_store,
                    X509_ASN_ENCODING | PKCS_7_ASN_ENCODING,
                    0,
                    CERT_FIND_HASH,
                    &cert_thumbprint,
                    null,
                );
                if (client_cert == null) {
                    _ = win_ext.CertCloseStore(cert_store, 0);
                    c_ext.Curl_failf(data, "schannel: client cert not found in cert store");
                    return CURLE_SSL_CERTPROBLEM;
                }
            }
            client_cert_store = cert_store;
        }

        out_cert_store.* = client_cert_store;
        out_cert_context.* = client_cert;
        return CURLE_OK;
    }

    fn acquireSspiHandle(
        cf: *CurlCfilter,
        data: ?*CurlEasy,
        backend: *SchannelSslBackendData,
        client_cert: ?*const CERT_CONTEXT,
        flags: DWORD,
        enabled_protocols: DWORD,
    ) CURLcode {
        const conn_config = vtls_impl.Curl_ssl_cf_get_filter_config(cf) orelse return CURLE_SSL_CONNECT_ERROR;
        const sec_fn = win_ext.Curl_pSecFn orelse return CURLE_SSL_CONNECT_ERROR;
        const cred = backend.cred orelse return CURLE_SSL_CONNECT_ERROR;
        var sspi_status: SECURITY_STATUS = SEC_E_OK;

        if (conn_config.cipher_list == null and
            win_ext.curlx_verify_windows_version(10, 0, 20348, PLATFORM_WINNT, VERSION_GREATER_THAN_EQUAL))
        {
            var credentials = SCH_CREDENTIALS{};
            var tls_parameters = TLS_PARAMETERS{};
            var crypto_settings: [1]CRYPTO_SETTINGS = .{.{}};
            var client_certs: [1]?*const CERT_CONTEXT = .{client_cert};

            tls_parameters.pDisabledCrypto = &crypto_settings;
            tls_parameters.cDisabledCrypto = 0;
            tls_parameters.grbitDisabledProtocols = ~enabled_protocols;

            credentials.pTlsParameters = &tls_parameters;
            credentials.cTlsParameters = 1;
            credentials.dwVersion = SCH_CREDENTIALS_VERSION;
            credentials.dwFlags = flags | SCH_USE_STRONG_CRYPTO;

            if (client_certs[0] != null) {
                credentials.cCreds = 1;
                credentials.paCred = &client_certs[0];
            }

            sspi_status = sec_fn.AcquireCredentialsHandleA(
                null,
                UNISP_NAME_A,
                SECPKG_CRED_OUTBOUND,
                null,
                &credentials,
                null,
                null,
                &cred.cred_handle,
                null,
            );
        } else {
            var alg_ids: [NUM_CIPHERS]ALG_ID = undefined;
            var schannel_cred = std.mem.zeroes(SCHANNEL_CRED);
            var client_certs: [1]?*const CERT_CONTEXT = .{client_cert};

            schannel_cred.dwVersion = SCHANNEL_CRED_VERSION;
            schannel_cred.dwFlags = flags;
            schannel_cred.grbitEnabledProtocols = enabled_protocols;

            if (conn_config.cipher_list) |ciphers| {
                if ((enabled_protocols & SP_PROT_TLS1_3_CLIENT) != 0) {
                    if ((enabled_protocols & ~SP_PROT_TLS1_3_CLIENT) == 0) {
                        c_ext.Curl_failf(
                            data,
                            "schannel: TLS 1.3 is not supported with a cipher list; remove the cipher list or allow a lower TLS version",
                        );
                        return CURLE_SSL_CONNECT_ERROR;
                    }
                    c_ext.Curl_infof(
                        data,
                        "schannel: WARNING: This version of Schannel negotiates a less-secure TLS version than TLS 1.3 because the user set an algorithm cipher list.",
                    );
                }
                const result = setSslCiphers(&schannel_cred, ciphers, &alg_ids);
                if (result != CURLE_OK) {
                    c_ext.Curl_failf(data, "schannel: Failed setting algorithm cipher list");
                    return result;
                }
            } else {
                schannel_cred.dwFlags = flags | SCH_USE_STRONG_CRYPTO;
            }

            if (client_certs[0] != null) {
                schannel_cred.cCreds = 1;
                schannel_cred.paCred = &client_certs[0];
            }

            sspi_status = sec_fn.AcquireCredentialsHandleA(
                null,
                UNISP_NAME_A,
                SECPKG_CRED_OUTBOUND,
                null,
                &schannel_cred,
                null,
                null,
                &cred.cred_handle,
                null,
            );
        }

        if (sspi_status != SEC_E_OK) {
            var buffer: [STRERROR_LEN]u8 = undefined;
            c_ext.Curl_failf(
                data,
                "schannel: AcquireCredentialsHandle failed: %s",
                win_ext.Curl_sspi_strerror(sspi_status, &buffer, buffer.len),
            );
            return switch (sspi_status) {
                SEC_E_INSUFFICIENT_MEMORY => CURLE_OUT_OF_MEMORY,
                else => CURLE_SSL_CONNECT_ERROR,
            };
        }

        return CURLE_OK;
    }

    fn schannelAcquireCredentialHandle(cf: *CurlCfilter, data: ?*CurlEasy) CURLcode {
        const connssl: *SslConnectData = @ptrCast(@alignCast(cf.ctx orelse return CURLE_SSL_CONNECT_ERROR));
        const backend: *SchannelSslBackendData = @ptrCast(@alignCast(connssl.backend orelse return CURLE_SSL_CONNECT_ERROR));
        const conn_config = vtls_impl.Curl_ssl_cf_get_filter_config(cf) orelse return CURLE_SSL_CONNECT_ERROR;

        var client_cert: ?*const CERT_CONTEXT = null;
        var client_cert_store: HCERTSTORE = null;
        var flags: DWORD = 0;
        var enabled_protocols: DWORD = 0;

        if (conn_config.verifypeer()) {
            if (backend.use_manual_cred_validation()) {
                flags = SCH_CRED_MANUAL_CRED_VALIDATION;
            } else {
                flags = SCH_CRED_AUTO_CRED_VALIDATION;
            }

            if (conn_config.no_revoke()) {
                flags |= SCH_CRED_IGNORE_NO_REVOCATION_CHECK | SCH_CRED_IGNORE_REVOCATION_OFFLINE;
            } else if (conn_config.revoke_best_effort()) {
                flags |= SCH_CRED_IGNORE_NO_REVOCATION_CHECK |
                    SCH_CRED_IGNORE_REVOCATION_OFFLINE |
                    SCH_CRED_REVOCATION_CHECK_CHAIN;
            } else {
                flags |= SCH_CRED_REVOCATION_CHECK_CHAIN;
            }
        } else {
            flags = SCH_CRED_MANUAL_CRED_VALIDATION |
                SCH_CRED_IGNORE_NO_REVOCATION_CHECK |
                SCH_CRED_IGNORE_REVOCATION_OFFLINE;
        }

        if (!conn_config.verifyhost()) {
            flags |= SCH_CRED_NO_SERVERNAME_CHECK;
        }

        if (!conn_config.auto_client_cert()) {
            flags &= ~SCH_CRED_USE_DEFAULT_CREDS;
            flags |= SCH_CRED_NO_DEFAULT_CREDS;
            c_ext.Curl_infof(data, "schannel: disabled automatic use of client certificate");
        } else {
            c_ext.Curl_infof(data, "schannel: enabled automatic use of client certificate");
        }

        switch (conn_config.version) {
            CURL_SSLVERSION_TLSv1,
            CURL_SSLVERSION_TLSv1_0,
            CURL_SSLVERSION_TLSv1_1,
            CURL_SSLVERSION_TLSv1_2,
            CURL_SSLVERSION_TLSv1_3,
            => {
                const result = setSslVersionMinMax(&enabled_protocols, cf, data);
                if (result != CURLE_OK) return result;
            },
            CURL_SSLVERSION_SSLv3, CURL_SSLVERSION_SSLv2 => {
                c_ext.Curl_failf(data, "SSL versions not supported");
                return CURLE_NOT_BUILT_IN;
            },
            else => {
                c_ext.Curl_failf(data, "Unrecognized parameter passed via CURLOPT_SSLVERSION");
                return CURLE_SSL_CONNECT_ERROR;
            },
        }

        var result = getClientCert(cf, data, &client_cert_store, &client_cert);
        if (result != CURLE_OK) return result;

        const raw_cred = mem.calloc(1, @sizeOf(CurlSchannelCred)) orelse {
            c_ext.Curl_failf(data, "schannel: unable to allocate memory");
            if (client_cert) |cc| _ = win_ext.CertFreeCertificateContext(cc);
            if (client_cert_store) |cs| _ = win_ext.CertCloseStore(cs, 0);
            return CURLE_OUT_OF_MEMORY;
        };
        const cred: *CurlSchannelCred = @ptrCast(@alignCast(raw_cred));
        cred.refcount = 1;
        cred.client_cert_store = client_cert_store;
        backend.cred = cred;

        result = acquireSspiHandle(cf, data, backend, client_cert, flags, enabled_protocols);

        if (client_cert) |cc| {
            _ = win_ext.CertFreeCertificateContext(cc);
        }

        return result;
    }

    fn schannelSessionFree(ptr: ?*anyopaque) callconv(.c) void {
        const cred_opt: ?*CurlSchannelCred = if (ptr) |p| @ptrCast(@alignCast(p)) else null;
        if (cred_opt) |cred| {
            cred.refcount -= 1;
            if (cred.refcount == 0) {
                if (win_ext.Curl_pSecFn) |sec_fn| {
                    _ = sec_fn.FreeCredentialsHandle(&cred.cred_handle);
                }
                if (cred.sni_hostname) |sni| {
                    mem.free(sni);
                }
                if (cred.client_cert_store) |cs| {
                    _ = win_ext.CertCloseStore(cs, 0);
                    cred.client_cert_store = null;
                }
                mem.freeSized(cred, @sizeOf(CurlSchannelCred));
            }
        }
    }

    fn schannelConnectStep1(cf: *CurlCfilter, data: ?*CurlEasy) CURLcode {
        const connssl: *SslConnectData = @ptrCast(@alignCast(cf.ctx orelse return CURLE_SSL_CONNECT_ERROR));
        const backend: *SchannelSslBackendData = @ptrCast(@alignCast(connssl.backend orelse return CURLE_SSL_CONNECT_ERROR));
        const conn_config = vtls_impl.Curl_ssl_cf_get_filter_config(cf) orelse return CURLE_SSL_CONNECT_ERROR;
        const sec_fn = win_ext.Curl_pSecFn orelse return CURLE_SSL_CONNECT_ERROR;

        var result: CURLcode = CURLE_OK;

        backend.set_use_alpn(connssl.alpn != null and s_win_has_alpn);

        if (conn_config.CAfile != null or conn_config.ca_info_blob != null) {
            if (win_ext.curlx_verify_windows_version(6, 1, 0, PLATFORM_WINNT, VERSION_GREATER_THAN_EQUAL)) {
                backend.set_use_manual_cred_validation(true);
            } else {
                c_ext.Curl_failf(
                    data,
                    "schannel: this version of Windows is too old to support certificate verification via CA bundle file.",
                );
                return CURLE_SSL_CACERT_BADFILE;
            }
        } else {
            backend.set_use_manual_cred_validation(false);
        }

        backend.cred = null;
        var scache: ?*CurlSslScache = null;
        var has_share_scache = false;
        var trc_feat: ?*CurlTrcFeat = null;
        c_ext.Curl_vtls_acc_scache_params(data, &scache, &has_share_scache, &trc_feat);

        if (conn_config.primary_cache_session() and connssl.peer.scache_key != null) {
            vtls_scache_asn1.Curl_ssl_scache_lock_zig(data, scache, has_share_scache);
            const raw_old = vtls_scache_asn1.Curl_ssl_scache_get_obj_zig(cf, data, scache, conn_config, trc_feat, connssl.peer.scache_key.?);
            if (raw_old) |p| {
                const old_cred: *CurlSchannelCred = @ptrCast(@alignCast(p));
                backend.cred = old_cred;
                old_cred.refcount += 1;
            }
            vtls_scache_asn1.Curl_ssl_scache_unlock_zig(data, scache, has_share_scache);
        }

        if (backend.cred == null) {
            result = schannelAcquireCredentialHandle(cf, data);
            if (result != CURLE_OK or backend.cred == null) return result;

            const snihost: ?[*:0]const u8 = connssl.peer.sni orelse connssl.peer.origin.?.hostname;
            if (snihost) |sh| {
                backend.cred.?.sni_hostname = mem.strdup(sh) orelse return CURLE_OUT_OF_MEMORY;
            } else {
                return CURLE_OUT_OF_MEMORY;
            }
        }

        if (connssl.peer.type != SSL_PEER_DNS) {
            c_ext.Curl_infof(data, "schannel: using IP address, SNI is not supported by OS.");
        }

        var alpn_buffer: [128]u8 = undefined;
        var inbuf: SecBuffer = undefined;
        var inbuf_desc: SecBufferDesc = undefined;
        var outbuf: SecBuffer = undefined;
        var outbuf_desc: SecBufferDesc = undefined;

        if (backend.use_alpn()) {
            var proto: AlpnProtoBuf = undefined;
            result = alpnToProtoBuf(&proto, connssl.alpn);
            if (result != CURLE_OK) {
                c_ext.Curl_failf(data, "Error setting ALPN");
                return CURLE_SSL_CONNECT_ERROR;
            }
            const proto_len: usize = @intCast(proto.len);
            const list_len: u16 = @intCast(proto_len);
            const ext_len: u32 = @as(u32, list_len) + @sizeOf(u32) + @sizeOf(u16);
            const ui_alpn: u32 = SecApplicationProtocolNegotiationExt_ALPN;
            @memcpy(alpn_buffer[0..4], std.mem.asBytes(&ext_len));
            @memcpy(alpn_buffer[4..8], std.mem.asBytes(&ui_alpn));
            @memcpy(alpn_buffer[8..10], std.mem.asBytes(&list_len));
            if (proto_len > 0) {
                @memcpy(alpn_buffer[10 .. 10 + proto_len], proto.data[0..proto_len]);
            }
            initSecBuffer(&inbuf, SECBUFFER_APPLICATION_PROTOCOLS, &alpn_buffer, @intCast(10 + proto_len));
            initSecBufferDesc(&inbuf_desc, @ptrCast(&inbuf), 1);

            _ = alpnToProtoStr(&proto, connssl.alpn);
            c_ext.Curl_infof(data, "ALPN: curl offers %s", @as([*:0]const u8, @ptrCast(&proto.data)));
        } else {
            initSecBuffer(&inbuf, SECBUFFER_EMPTY, null, 0);
            initSecBufferDesc(&inbuf_desc, @ptrCast(&inbuf), 1);
        }

        initSecBuffer(&outbuf, SECBUFFER_EMPTY, null, 0);
        initSecBufferDesc(&outbuf_desc, @ptrCast(&outbuf), 1);

        backend.req_flags = ISC_REQ_SEQUENCE_DETECT |
            ISC_REQ_REPLAY_DETECT |
            ISC_REQ_CONFIDENTIALITY |
            ISC_REQ_ALLOCATE_MEMORY |
            ISC_REQ_STREAM |
            (if (!conn_config.auto_client_cert()) ISC_REQ_USE_SUPPLIED_CREDS else 0);

        const raw_ctxt = mem.calloc(1, @sizeOf(CurlSchannelCtxt)) orelse {
            c_ext.Curl_failf(data, "schannel: unable to allocate memory");
            return CURLE_OUT_OF_MEMORY;
        };
        backend.ctxt = @ptrCast(@alignCast(raw_ctxt));

        const sspi_status = sec_fn.InitializeSecurityContextA(
            &backend.cred.?.cred_handle,
            null,
            backend.cred.?.sni_hostname,
            backend.req_flags,
            0,
            0,
            if (backend.use_alpn()) &inbuf_desc else null,
            0,
            &backend.ctxt.?.ctxt_handle,
            &outbuf_desc,
            &backend.ret_flags,
            null,
        );

        if (sspi_status != SEC_I_CONTINUE_NEEDED) {
            var buffer: [STRERROR_LEN]u8 = undefined;
            mem.free(backend.ctxt);
            backend.ctxt = null;
            switch (sspi_status) {
                SEC_E_INSUFFICIENT_MEMORY => {
                    c_ext.Curl_failf(
                        data,
                        "schannel: initial InitializeSecurityContext failed: %s",
                        win_ext.Curl_sspi_strerror(sspi_status, &buffer, buffer.len),
                    );
                    return CURLE_OUT_OF_MEMORY;
                },
                SEC_E_WRONG_PRINCIPAL => {
                    c_ext.Curl_failf(
                        data,
                        "schannel: SNI or certificate check failed: %s",
                        win_ext.Curl_sspi_strerror(sspi_status, &buffer, buffer.len),
                    );
                    return CURLE_PEER_FAILED_VERIFICATION;
                },
                else => {
                    c_ext.Curl_failf(
                        data,
                        "schannel: initial InitializeSecurityContext failed: %s",
                        win_ext.Curl_sspi_strerror(sspi_status, &buffer, buffer.len),
                    );
                    return CURLE_SSL_CONNECT_ERROR;
                },
            }
        }

        var written: usize = 0;
        result = c_ext.Curl_conn_cf_send(
            cf.next,
            data,
            outbuf.pvBuffer,
            outbuf.cbBuffer,
            false,
            &written,
        );
        _ = sec_fn.FreeContextBuffer(outbuf.pvBuffer);
        if (result != CURLE_OK or outbuf.cbBuffer != written) {
            c_ext.Curl_failf(
                data,
                "schannel: failed to send initial handshake data: sent %zu of %lu bytes",
                written,
                outbuf.cbBuffer,
            );
            return CURLE_SSL_CONNECT_ERROR;
        }

        backend.recv_unrecoverable_err = CURLE_OK;
        backend.set_recv_sspi_close_notify(false);
        backend.set_recv_connection_closed(false);
        backend.set_recv_renegotiating(false);
        backend.renegotiate_state.started = false;
        backend.set_encdata_is_incomplete(false);
        backend.set_shutdown_generated(false);
        backend.shutdown_offset = 0;
        backend.shutdown_token = std.mem.zeroes(SecBuffer);

        connssl.connecting_state = ssl_connect_2;
        return CURLE_OK;
    }

    fn schannelError(data: ?*CurlEasy, sspi_status: SECURITY_STATUS) CURLcode {
        var buffer: [STRERROR_LEN]u8 = undefined;
        switch (sspi_status) {
            SEC_E_INSUFFICIENT_MEMORY => {
                c_ext.Curl_failf(
                    data,
                    "schannel: next InitializeSecurityContext failed: %s",
                    win_ext.Curl_sspi_strerror(sspi_status, &buffer, buffer.len),
                );
                return CURLE_OUT_OF_MEMORY;
            },
            SEC_E_WRONG_PRINCIPAL => {
                c_ext.Curl_failf(
                    data,
                    "schannel: SNI or certificate check failed: %s",
                    win_ext.Curl_sspi_strerror(sspi_status, &buffer, buffer.len),
                );
                return CURLE_PEER_FAILED_VERIFICATION;
            },
            SEC_E_UNTRUSTED_ROOT => {
                c_ext.Curl_failf(
                    data,
                    "schannel: %s",
                    win_ext.Curl_sspi_strerror(sspi_status, &buffer, buffer.len),
                );
                return CURLE_PEER_FAILED_VERIFICATION;
            },
            else => {
                c_ext.Curl_failf(
                    data,
                    "schannel: next InitializeSecurityContext failed: %s",
                    win_ext.Curl_sspi_strerror(sspi_status, &buffer, buffer.len),
                );
                return CURLE_SSL_CONNECT_ERROR;
            },
        }
    }

    fn schannelPkpPinPeerPubkey(cf: *CurlCfilter, data: ?*CurlEasy, pinnedpubkey: ?[*:0]const u8) CURLcode {
        const pinned = pinnedpubkey orelse return CURLE_OK;
        const connssl: *SslConnectData = @ptrCast(@alignCast(cf.ctx orelse return CURLE_SSL_PINNEDPUBKEYNOTMATCH));
        const backend: *SchannelSslBackendData = @ptrCast(@alignCast(connssl.backend orelse return CURLE_SSL_PINNEDPUBKEYNOTMATCH));
        const sec_fn = win_ext.Curl_pSecFn orelse return CURLE_SSL_PINNEDPUBKEYNOTMATCH;

        var pCertContextServer: ?*CERT_CONTEXT = null;
        var result: CURLcode = CURLE_SSL_PINNEDPUBKEYNOTMATCH;

        while (true) {
            const sspi_status = sec_fn.QueryContextAttributesA(
                &backend.ctxt.?.ctxt_handle,
                SECPKG_ATTR_REMOTE_CERT_CONTEXT,
                @ptrCast(&pCertContextServer),
            );
            if (sspi_status != SEC_E_OK or pCertContextServer == null) {
                var buffer: [STRERROR_LEN]u8 = undefined;
                c_ext.Curl_failf(
                    data,
                    "schannel: Failed to read remote certificate context: %s",
                    win_ext.Curl_sspi_strerror(sspi_status, &buffer, buffer.len),
                );
                break;
            }

            const cert_ctx = pCertContextServer.?;
            if ((cert_ctx.dwCertEncodingType & X509_ASN_ENCODING) == 0 or
                cert_ctx.cbCertEncoded == 0 or
                cert_ctx.pbCertEncoded == null)
            {
                break;
            }

            const x509_der = cert_ctx.pbCertEncoded.?;
            const x509_der_len: usize = cert_ctx.cbCertEncoded;
            var x509_parsed = std.mem.zeroes(vtls_scache_asn1.CurlX509certificate);
            if (vtls_scache_asn1.Curl_parseX509(&x509_parsed, x509_der, x509_der + x509_der_len) != 0) {
                break;
            }

            const pubkey = &x509_parsed.subjectPublicKeyInfo;
            if (pubkey.header == null or pubkey.end == null or @intFromPtr(pubkey.end.?) <= @intFromPtr(pubkey.header.?)) {
                c_ext.Curl_failf(data, "SSL: failed retrieving public key from server certificate");
                break;
            }

            result = vtls_impl.Curl_pin_peer_pubkey(
                data,
                pinned,
                pubkey.header.?,
                @intFromPtr(pubkey.end.?) - @intFromPtr(pubkey.header.?),
            );
            if (result != CURLE_OK) {
                c_ext.Curl_failf(data, "SSL: public key does not match pinned public key");
            }
            break;
        }

        if (pCertContextServer) |cc| {
            _ = win_ext.CertFreeCertificateContext(cc);
        }

        return result;
    }

    fn ensureEncodingSize(data: ?*CurlEasy, encdata: *SBuffer, min_length: usize) CURLcode {
        if (encdata.length < encdata.offset) return CURLE_FAILED_INIT;
        const size = encdata.length - encdata.offset;
        if (size < CURL_SCHANNEL_BUFFER_FREE_SIZE or encdata.length < min_length) {
            var length = encdata.offset + CURL_SCHANNEL_BUFFER_FREE_SIZE;
            if (length < min_length) length = min_length;
            const raw = mem.realloc(encdata.buffer, length) orelse {
                c_ext.Curl_failf(data, "schannel: unable to re-allocate memory");
                return CURLE_OUT_OF_MEMORY;
            };
            encdata.buffer = @ptrCast(raw);
            encdata.length = length;
        }
        return CURLE_OK;
    }

    fn ensureDecodingSize(data: ?*CurlEasy, decdata: *SBuffer, nowsize: usize, len: usize) CURLcode {
        const size = if (nowsize > CURL_SCHANNEL_BUFFER_FREE_SIZE) nowsize else CURL_SCHANNEL_BUFFER_FREE_SIZE;
        if (decdata.length < decdata.offset) return CURLE_FAILED_INIT;
        if (decdata.length - decdata.offset < size or decdata.length < len) {
            var length = decdata.offset + size;
            if (length < len) length = len;
            const raw = mem.realloc(decdata.buffer, length) orelse {
                c_ext.Curl_failf(data, "schannel: unable to re-allocate memory");
                return CURLE_OUT_OF_MEMORY;
            };
            decdata.buffer = @ptrCast(raw);
            decdata.length = length;
        }
        return CURLE_OK;
    }

    fn schannelConnectStep2(cf: *CurlCfilter, data: ?*CurlEasy) CURLcode {
        const connssl: *SslConnectData = @ptrCast(@alignCast(cf.ctx orelse return CURLE_SSL_CONNECT_ERROR));
        const backend: *SchannelSslBackendData = @ptrCast(@alignCast(connssl.backend orelse return CURLE_SSL_CONNECT_ERROR));
        const conn_config = vtls_impl.Curl_ssl_cf_get_filter_config(cf) orelse return CURLE_SSL_CONNECT_ERROR;
        const sec_fn = win_ext.Curl_pSecFn orelse return CURLE_SSL_CONNECT_ERROR;

        var doread = (connssl.io_need & CURL_SSL_IO_NEED_SEND) == 0;
        connssl.io_need = CURL_SSL_IO_NEED_NONE;

        if (backend.cred == null or backend.ctxt == null) {
            return CURLE_SSL_CONNECT_ERROR;
        }

        if (backend.decdata.buffer == null) {
            backend.decdata.offset = 0;
            backend.decdata.length = CURL_SCHANNEL_BUFFER_INIT_SIZE;
            const raw = mem.malloc(backend.decdata.length) orelse {
                c_ext.Curl_failf(data, "schannel: unable to allocate memory");
                return CURLE_OUT_OF_MEMORY;
            };
            backend.decdata.buffer = @ptrCast(raw);
        }

        if (backend.encdata.buffer == null) {
            backend.set_encdata_is_incomplete(false);
            backend.encdata.offset = 0;
            backend.encdata.length = CURL_SCHANNEL_BUFFER_INIT_SIZE;
            const raw = mem.malloc(backend.encdata.length) orelse {
                c_ext.Curl_failf(data, "schannel: unable to allocate memory");
                return CURLE_OUT_OF_MEMORY;
            };
            backend.encdata.buffer = @ptrCast(raw);
        }

        var result = ensureEncodingSize(data, &backend.encdata, 0);
        if (result != CURLE_OK) return result;

        var sspi_status: SECURITY_STATUS = SEC_E_OK;

        while (true) {
            if (doread) {
                var nread: usize = 0;
                result = c_ext.Curl_conn_cf_recv(
                    cf.next,
                    data,
                    backend.encdata.buffer.? + backend.encdata.offset,
                    backend.encdata.length - backend.encdata.offset,
                    &nread,
                );
                if (result == CURLE_AGAIN) {
                    if (backend.encdata.offset == 0 or backend.encdata_is_incomplete()) {
                        connssl.io_need = CURL_SSL_IO_NEED_RECV;
                        return CURLE_OK;
                    }
                } else if (result != CURLE_OK or nread == 0) {
                    c_ext.Curl_failf(data, "schannel: failed to receive handshake, SSL/TLS connection failed");
                    return CURLE_SSL_CONNECT_ERROR;
                } else {
                    backend.encdata.offset += nread;
                    backend.set_encdata_is_incomplete(false);
                }
            }

            var inbuf: [2]SecBuffer = undefined;
            var inbuf_desc: SecBufferDesc = undefined;
            const dup_buf = schannelMemdup0(backend.encdata.buffer.?, backend.encdata.offset);
            initSecBuffer(&inbuf[0], SECBUFFER_TOKEN, if (dup_buf) |db| @ptrCast(db) else null, @intCast(backend.encdata.offset));
            initSecBuffer(&inbuf[1], SECBUFFER_EMPTY, null, 0);
            initSecBufferDesc(&inbuf_desc, &inbuf, 2);

            var outbuf: [3]SecBuffer = undefined;
            var outbuf_desc: SecBufferDesc = undefined;
            initSecBuffer(&outbuf[0], SECBUFFER_TOKEN, null, 0);
            initSecBuffer(&outbuf[1], SECBUFFER_ALERT, null, 0);
            initSecBuffer(&outbuf[2], SECBUFFER_EMPTY, null, 0);
            initSecBufferDesc(&outbuf_desc, &outbuf, 3);

            if (inbuf[0].pvBuffer == null) {
                c_ext.Curl_failf(data, "schannel: unable to allocate memory");
                return CURLE_OUT_OF_MEMORY;
            }

            const sockfd = c_ext.Curl_conn_cf_get_socket(cf, data);
            if (c_ext.Curl_socket_check(CURL_SOCKET_BAD, CURL_SOCKET_BAD, sockfd, 0) == 0) {
                connssl.io_need = CURL_SSL_IO_NEED_SEND;
                mem.free(inbuf[0].pvBuffer);
                return CURLE_OK;
            }

            sspi_status = sec_fn.InitializeSecurityContextA(
                &backend.cred.?.cred_handle,
                &backend.ctxt.?.ctxt_handle,
                backend.cred.?.sni_hostname,
                backend.req_flags,
                0,
                0,
                &inbuf_desc,
                0,
                null,
                &outbuf_desc,
                &backend.ret_flags,
                null,
            );

            mem.free(inbuf[0].pvBuffer);
            inbuf[0].pvBuffer = null;

            switch (sspi_status) {
                SEC_E_INCOMPLETE_MESSAGE => {
                    backend.set_encdata_is_incomplete(true);
                    connssl.io_need = CURL_SSL_IO_NEED_RECV;
                    return CURLE_OK;
                },
                SEC_I_CONTINUE_NEEDED, SEC_E_OK => {
                    result = CURLE_OK;
                    for (0..3) |i| {
                        if (outbuf[i].BufferType == SECBUFFER_TOKEN and outbuf[i].cbBuffer > 0) {
                            var written: usize = 0;
                            result = c_ext.Curl_conn_cf_send(
                                cf.next,
                                data,
                                outbuf[i].pvBuffer,
                                outbuf[i].cbBuffer,
                                false,
                                &written,
                            );
                            if (result != CURLE_OK or outbuf[i].cbBuffer != written) {
                                c_ext.Curl_failf(
                                    data,
                                    "schannel: failed to send next handshake data: sent %zu of %lu bytes",
                                    written,
                                    outbuf[i].cbBuffer,
                                );
                                result = CURLE_SSL_CONNECT_ERROR;
                            }
                        }
                    }
                    for (0..3) |i| {
                        if (outbuf[i].pvBuffer) |pv| {
                            _ = sec_fn.FreeContextBuffer(pv);
                        }
                    }
                    if (result != CURLE_OK) return result;
                },
                SEC_I_INCOMPLETE_CREDENTIALS => {
                    if ((backend.req_flags & ISC_REQ_USE_SUPPLIED_CREDS) == 0) {
                        backend.req_flags |= ISC_REQ_USE_SUPPLIED_CREDS;
                        connssl.io_need = CURL_SSL_IO_NEED_SEND;
                        return CURLE_OK;
                    }
                    return schannelError(data, sspi_status);
                },
                else => return schannelError(data, sspi_status),
            }

            if (inbuf[1].BufferType == SECBUFFER_EXTRA and inbuf[1].cbBuffer > 0) {
                const extra_len: usize = inbuf[1].cbBuffer;
                if (backend.encdata.offset > extra_len) {
                    const src_off = backend.encdata.offset - extra_len;
                    std.mem.copyForwards(
                        u8,
                        backend.encdata.buffer.?[0..extra_len],
                        backend.encdata.buffer.?[src_off .. src_off + extra_len],
                    );
                    backend.encdata.offset = extra_len;
                    if (sspi_status == SEC_I_CONTINUE_NEEDED) {
                        doread = false;
                        continue;
                    }
                }
            } else {
                backend.encdata.offset = 0;
            }
            break;
        }

        if (sspi_status == SEC_I_CONTINUE_NEEDED) {
            connssl.io_need = CURL_SSL_IO_NEED_RECV;
            return CURLE_OK;
        }

        if (sspi_status == SEC_E_OK) {
            connssl.connecting_state = ssl_connect_3;
        }

        if (c_ext.Curl_vtls_acc_pinned_pubkey(data, vtls_impl.Curl_ssl_cf_is_proxy(cf))) |pubkey_ptr| {
            result = schannelPkpPinPeerPubkey(cf, data, pubkey_ptr);
            if (result != CURLE_OK) {
                c_ext.Curl_failf(data, "SSL: public key does not match pinned public key");
                return result;
            }
        }

        if (conn_config.verifypeer() and backend.use_manual_cred_validation()) {
            return win_ext.Curl_verify_certificate(cf, data);
        }

        if (!conn_config.verifypeer() and conn_config.verifyhost()) {
            return win_ext.Curl_verify_host(cf, data);
        }

        return CURLE_OK;
    }

    fn validCertEncoding(cert_context: ?*const CERT_CONTEXT) bool {
        const ctx = cert_context orelse return false;
        return (ctx.dwCertEncodingType & X509_ASN_ENCODING) != 0 and
            ctx.pbCertEncoded != null and
            ctx.cbCertEncoded > 0;
    }

    const ReadCrtFunc = *const fn (ccert_context: *const CERT_CONTEXT, reverse_order: bool, arg: *anyopaque) bool;

    fn traverseCertStore(context: *const CERT_CONTEXT, func: ReadCrtFunc, arg: *anyopaque) void {
        var current_context: ?*const CERT_CONTEXT = null;
        var should_continue = true;
        var first = true;
        var reverse_order = false;
        while (should_continue) {
            current_context = win_ext.CertEnumCertificatesInStore(context.hCertStore, current_context);
            const cur = current_context orelse break;
            if (first and context.pbCertEncoded != cur.pbCertEncoded) {
                reverse_order = true;
            }
            should_continue = func(cur, reverse_order, arg);
            first = false;
        }
        if (current_context) |cur| {
            _ = win_ext.CertFreeCertificateContext(cur);
        }
    }

    fn certCounterCallback(ccert_context: *const CERT_CONTEXT, reverse_order: bool, certs_count_raw: *anyopaque) bool {
        _ = reverse_order;
        const certs_count: *c_int = @ptrCast(@alignCast(certs_count_raw));
        if (validCertEncoding(ccert_context)) {
            certs_count.* += 1;
        }
        if (certs_count.* > MAX_ALLOWED_CERT_AMOUNT) {
            return false;
        }
        return true;
    }

    const AdderArgs = struct {
        data: ?*CurlEasy,
        result: CURLcode,
        idx: c_int,
        certs_count: c_int,
    };

    fn addCertToCertinfo(ccert_context: *const CERT_CONTEXT, reverse_order: bool, raw_arg: *anyopaque) bool {
        const args: *AdderArgs = @ptrCast(@alignCast(raw_arg));
        args.result = CURLE_OK;
        if (validCertEncoding(ccert_context)) {
            const insert_index: c_int = if (reverse_order) (args.certs_count - 1) - args.idx else args.idx;
            const pb = ccert_context.pbCertEncoded.?;
            args.result = vtls_scache_asn1.Curl_extract_certinfo_zig(
                args.data,
                insert_index,
                pb,
                pb + ccert_context.cbCertEncoded,
                true,
                @ptrCast(&vtls_impl.Curl_ssl_push_certinfo_len),
            );
            args.idx += 1;
        }
        return args.result == CURLE_OK;
    }

    fn cStrncmpDiff(a: [*:0]const u8, b: [*]const u8, n: usize) bool {
        var i: usize = 0;
        while (i < n) : (i += 1) {
            if (a[i] != b[i]) return true;
            if (a[i] == 0) return false;
        }
        return false;
    }

    fn schannelConnectStep3(cf: *CurlCfilter, data: ?*CurlEasy) CURLcode {
        const connssl: *SslConnectData = @ptrCast(@alignCast(cf.ctx orelse return CURLE_SSL_CONNECT_ERROR));
        const backend: *SchannelSslBackendData = @ptrCast(@alignCast(connssl.backend orelse return CURLE_SSL_CONNECT_ERROR));
        const sec_fn = win_ext.Curl_pSecFn orelse return CURLE_SSL_CONNECT_ERROR;

        if (backend.cred == null) {
            return CURLE_SSL_CONNECT_ERROR;
        }

        if (backend.ret_flags != backend.req_flags) {
            if ((backend.ret_flags & ISC_RET_SEQUENCE_DETECT) == 0) {
                c_ext.Curl_failf(data, "schannel: failed to setup sequence detection");
            }
            if ((backend.ret_flags & ISC_RET_REPLAY_DETECT) == 0) {
                c_ext.Curl_failf(data, "schannel: failed to setup replay detection");
            }
            if ((backend.ret_flags & ISC_RET_CONFIDENTIALITY) == 0) {
                c_ext.Curl_failf(data, "schannel: failed to setup confidentiality");
            }
            if ((backend.ret_flags & ISC_RET_ALLOCATED_MEMORY) == 0) {
                c_ext.Curl_failf(data, "schannel: failed to setup memory allocation");
            }
            if ((backend.ret_flags & ISC_RET_STREAM) == 0) {
                c_ext.Curl_failf(data, "schannel: failed to setup stream orientation");
            }
            return CURLE_SSL_CONNECT_ERROR;
        }

        if (backend.use_alpn()) {
            var alpn_result: SecPkgContext_ApplicationProtocol = std.mem.zeroes(SecPkgContext_ApplicationProtocol);
            const sspi_status = sec_fn.QueryContextAttributesA(
                &backend.ctxt.?.ctxt_handle,
                SECPKG_ATTR_APPLICATION_PROTOCOL,
                @ptrCast(&alpn_result),
            );
            if (sspi_status != SEC_E_OK) {
                c_ext.Curl_failf(data, "schannel: failed to retrieve ALPN result");
                return CURLE_SSL_CONNECT_ERROR;
            }
            if (alpn_result.ProtoNegoStatus == SecApplicationProtocolNegotiationStatus_Success) {
                if (backend.recv_renegotiating()) {
                    if (connssl.negotiated_alpn) |neg_alpn| {
                        if (cStrncmpDiff(neg_alpn, &alpn_result.ProtocolId, alpn_result.ProtocolIdSize)) {
                            c_ext.Curl_failf(data, "schannel: server selected an ALPN protocol too late");
                            return CURLE_SSL_CONNECT_ERROR;
                        }
                    }
                }
                _ = vtls_impl.Curl_alpn_set_negotiated(
                    cf,
                    data,
                    connssl,
                    &alpn_result.ProtocolId,
                    alpn_result.ProtocolIdSize,
                );
            } else {
                if (!backend.recv_renegotiating()) {
                    _ = vtls_impl.Curl_alpn_set_negotiated(cf, data, connssl, null, 0);
                }
            }
        }

        var result: CURLcode = CURLE_OK;
        const conn_config = vtls_impl.Curl_ssl_cf_get_filter_config(cf);
        if (conn_config != null and conn_config.?.primary_cache_session() and connssl.peer.scache_key != null) {
            var scache: ?*CurlSslScache = null;
            var has_share_scache = false;
            var trc_feat: ?*CurlTrcFeat = null;
            c_ext.Curl_vtls_acc_scache_params(data, &scache, &has_share_scache, &trc_feat);
            vtls_scache_asn1.Curl_ssl_scache_lock_zig(data, scache, has_share_scache);
            backend.cred.?.refcount += 1;
            result = vtls_scache_asn1.Curl_ssl_scache_add_obj_zig(
                cf,
                data,
                scache,
                conn_config,
                trc_feat,
                connssl.peer.scache_key.?,
                backend.cred.?,
                schannelSessionFree,
            );
            vtls_scache_asn1.Curl_ssl_scache_unlock_zig(data, scache, has_share_scache);
            if (result != CURLE_OK) return result;
        }

        if (c_ext.Curl_vtls_acc_ssl_certinfo(data)) {
            var certs_count: c_int = 0;
            var ccert_context: ?*CERT_CONTEXT = null;
            const sspi_status = sec_fn.QueryContextAttributesA(
                &backend.ctxt.?.ctxt_handle,
                SECPKG_ATTR_REMOTE_CERT_CONTEXT,
                @ptrCast(&ccert_context),
            );
            if (sspi_status != SEC_E_OK or ccert_context == null) {
                c_ext.Curl_failf(data, "schannel: failed to retrieve remote cert context");
                return CURLE_PEER_FAILED_VERIFICATION;
            }

            traverseCertStore(ccert_context.?, certCounterCallback, @ptrCast(&certs_count));
            if (certs_count > MAX_ALLOWED_CERT_AMOUNT) {
                c_ext.Curl_failf(
                    data,
                    "%d certificates is more than allowed (%d)",
                    certs_count,
                    MAX_ALLOWED_CERT_AMOUNT,
                );
                _ = win_ext.CertFreeCertificateContext(ccert_context);
                return CURLE_SSL_CONNECT_ERROR;
            }

            result = vtls_impl.Curl_ssl_init_certinfo(data, certs_count);
            if (result == CURLE_OK) {
                var args = AdderArgs{
                    .data = data,
                    .idx = 0,
                    .certs_count = certs_count,
                    .result = CURLE_OK,
                };
                traverseCertStore(ccert_context.?, addCertToCertinfo, @ptrCast(&args));
                result = args.result;
            }
            _ = win_ext.CertFreeCertificateContext(ccert_context);
            if (result != CURLE_OK) return result;
        }

        connssl.connecting_state = ssl_connect_done;
        return CURLE_OK;
    }

    fn schannelConnect(cf: *CurlCfilter, data: ?*CurlEasy, done: *bool) callconv(.c) CURLcode {
        const connssl: *SslConnectData = @ptrCast(@alignCast(cf.ctx orelse return CURLE_SSL_CONNECT_ERROR));
        if (connssl.state == ssl_connection_complete) {
            done.* = true;
            return CURLE_OK;
        }
        done.* = false;

        if (connssl.connecting_state == ssl_connect_1) {
            const rc = schannelConnectStep1(cf, data);
            if (rc != CURLE_OK) return rc;
        }
        if (connssl.connecting_state == ssl_connect_2) {
            const rc = schannelConnectStep2(cf, data);
            if (rc != CURLE_OK) return rc;
        }
        if (connssl.connecting_state == ssl_connect_3) {
            const rc = schannelConnectStep3(cf, data);
            if (rc != CURLE_OK) return rc;
        }
        if (connssl.connecting_state == ssl_connect_done) {
            const backend: *SchannelSslBackendData = @ptrCast(@alignCast(connssl.backend orelse return CURLE_SSL_CONNECT_ERROR));
            const sec_fn = win_ext.Curl_pSecFn orelse return CURLE_SSL_CONNECT_ERROR;
            if (sec_fn.QueryContextAttributesA(
                &backend.ctxt.?.ctxt_handle,
                SECPKG_ATTR_STREAM_SIZES,
                @ptrCast(&backend.stream_sizes),
            ) != SEC_E_OK) {
                c_ext.Curl_failf(data, "schannel: failed getting stream sizes");
                return CURLE_SSL_CONNECT_ERROR;
            }
            connssl.state = ssl_connection_complete;
            win_ext.Curl_vtls_acc_conn_set_ssl_context(cf.conn, &backend.ctxt.?.ctxt_handle);
            done.* = true;
        }
        return CURLE_OK;
    }

    const SchannelRenegotiateCaller = enum(c_uint) {
        recv = 0,
        send = 1,
    };

    const MAX_RENEG_BLOCK_TIME: i64 = 60 * 1000;

    fn schannelRecvRenegotiate(
        cf: *CurlCfilter,
        data: ?*CurlEasy,
        caller: SchannelRenegotiateCaller,
    ) CURLcode {
        const connssl: *SslConnectData = @ptrCast(@alignCast(cf.ctx orelse return CURLE_SSL_CONNECT_ERROR));
        const backend_opt: ?*SchannelSslBackendData = if (connssl.backend) |b| @ptrCast(@alignCast(b)) else null;
        if (backend_opt == null or !backend_opt.?.recv_renegotiating()) {
            c_ext.Curl_failf(data, "schannel: unexpected call to schannel_recv_renegotiate");
            return CURLE_SSL_CONNECT_ERROR;
        }
        const backend = backend_opt.?;
        const rs = &backend.renegotiate_state;

        const sockfd = c_ext.Curl_conn_cf_get_socket(cf, data);
        if (sockfd == CURL_SOCKET_BAD) {
            c_ext.Curl_failf(data, "schannel: renegotiation missing socket");
            return CURLE_SSL_CONNECT_ERROR;
        }

        if (!rs.started) {
            c_ext.Curl_infof(data, "schannel: renegotiating SSL/TLS connection");
            connssl.state = ssl_connection_negotiating;
            connssl.connecting_state = ssl_connect_2;
            rs.* = std.mem.zeroes(SchannelRenegotiateState);
            rs.io_need = CURL_SSL_IO_NEED_SEND;
            rs.start_time = c_ext.Curl_pgrs_now(data).*;
            rs.started = true;
        }

        var result: CURLcode = CURLE_OK;
        while (true) {
            var elapsed = curlx_time_net.curlx_ptimediff_ms(c_ext.Curl_pgrs_now(data), &rs.start_time);
            if (elapsed >= MAX_RENEG_BLOCK_TIME) {
                c_ext.Curl_failf(data, "schannel: renegotiation timeout");
                result = CURLE_SSL_CONNECT_ERROR;
                break;
            }

            connssl.io_need = rs.io_need;
            var done = false;
            result = schannelConnect(cf, data, &done);
            rs.io_need = connssl.io_need;

            if (result == CURLE_OK and !done) {
                result = CURLE_AGAIN;
            }
            if (result != CURLE_AGAIN) {
                break;
            }

            const readfd: curl_socket_t = if ((rs.io_need & CURL_SSL_IO_NEED_RECV) != 0) sockfd else CURL_SOCKET_BAD;
            const writefd: curl_socket_t = if ((rs.io_need & CURL_SSL_IO_NEED_SEND) != 0) sockfd else CURL_SOCKET_BAD;

            if (readfd == CURL_SOCKET_BAD and writefd == CURL_SOCKET_BAD) {
                continue;
            }

            const block_read = (caller == .send);
            const block_write = (caller == .recv);
            const blocking = (block_read and readfd != CURL_SOCKET_BAD) or
                (block_write and writefd != CURL_SOCKET_BAD);

            while (true) {
                result = win_ext.Curl_pgrsUpdate(data);
                if (result != CURLE_OK) break;

                elapsed = curlx_time_net.curlx_ptimediff_ms(c_ext.Curl_pgrs_now(data), &rs.start_time);
                if (elapsed >= MAX_RENEG_BLOCK_TIME) {
                    c_ext.Curl_failf(data, "schannel: renegotiation timeout");
                    result = CURLE_SSL_CONNECT_ERROR;
                    break;
                }

                const remaining = MAX_RENEG_BLOCK_TIME - elapsed;
                var timeout_ms: i64 = 0;
                if (blocking) {
                    timeout_ms = c_ext.Curl_timeleft_ms(data);
                    if (timeout_ms < 0) {
                        result = CURLE_OPERATION_TIMEDOUT;
                        break;
                    }
                    if (timeout_ms == 0 or timeout_ms > 1000) {
                        timeout_ms = 1000;
                    }
                    if (timeout_ms > remaining) {
                        timeout_ms = remaining;
                    }
                }

                const what = c_ext.Curl_socket_check(readfd, CURL_SOCKET_BAD, writefd, timeout_ms);
                if (what > 0 and (what & (0x01 | 0x02)) != 0) {
                    result = CURLE_AGAIN;
                    break;
                } else if (what == 0) {
                    if (blocking) {
                        continue;
                    } else {
                        return CURLE_AGAIN;
                    }
                }

                c_ext.Curl_failf(data, "schannel: socket error during renegotiation");
                result = CURLE_SSL_CONNECT_ERROR;
                break;
            }
            if (result != CURLE_AGAIN) {
                break;
            }
        }

        rs.started = false;
        backend.set_recv_renegotiating(false);
        connssl.io_need = CURL_SSL_IO_NEED_NONE;

        if (result != CURLE_OK) {
            c_ext.Curl_failf(data, "schannel: renegotiation failed");
        } else {
            c_ext.Curl_infof(data, "schannel: SSL/TLS connection renegotiated");
        }

        return result;
    }

    fn schannelSend(
        cf: *CurlCfilter,
        data: ?*CurlEasy,
        buf_opt: ?*const anyopaque,
        len_in: usize,
        pnwritten: *usize,
    ) callconv(.c) CURLcode {
        const connssl: *SslConnectData = @ptrCast(@alignCast(cf.ctx orelse return CURLE_SEND_ERROR));
        const backend: *SchannelSslBackendData = @ptrCast(@alignCast(connssl.backend orelse return CURLE_SEND_ERROR));
        const sec_fn = win_ext.Curl_pSecFn orelse return CURLE_SEND_ERROR;

        pnwritten.* = 0;

        if (backend.recv_renegotiating()) {
            const rres = schannelRecvRenegotiate(cf, data, .send);
            if (rres != CURLE_OK) return rres;
        }

        var len = len_in;
        if (len > backend.stream_sizes.cbMaximumMessage) {
            len = backend.stream_sizes.cbMaximumMessage;
        }

        const data_len: usize = @as(usize, backend.stream_sizes.cbHeader) + len + @as(usize, backend.stream_sizes.cbTrailer);
        var ptr: [*]u8 = undefined;
        if (data_len > backend.send_buffer_len) {
            const raw = mem.realloc(backend.send_buffer, data_len) orelse return CURLE_OUT_OF_MEMORY;
            ptr = @ptrCast(raw);
            backend.send_buffer = ptr;
            backend.send_buffer_len = data_len;
        } else {
            ptr = backend.send_buffer.?;
        }

        var outbuf: [4]SecBuffer = undefined;
        var outbuf_desc: SecBufferDesc = undefined;
        initSecBuffer(&outbuf[0], SECBUFFER_STREAM_HEADER, ptr, backend.stream_sizes.cbHeader);
        initSecBuffer(&outbuf[1], SECBUFFER_DATA, ptr + backend.stream_sizes.cbHeader, @intCast(len));
        initSecBuffer(&outbuf[2], SECBUFFER_STREAM_TRAILER, ptr + backend.stream_sizes.cbHeader + len, backend.stream_sizes.cbTrailer);
        initSecBuffer(&outbuf[3], SECBUFFER_EMPTY, null, 0);
        initSecBufferDesc(&outbuf_desc, &outbuf, 4);

        if (buf_opt != null and len > 0) {
            const src: [*]const u8 = @ptrCast(buf_opt.?);
            const dst: [*]u8 = @ptrCast(outbuf[1].pvBuffer.?);
            @memcpy(dst[0..len], src[0..len]);
        }

        const sspi_status = sec_fn.EncryptMessage(&backend.ctxt.?.ctxt_handle, 0, &outbuf_desc, 0);
        var result: CURLcode = CURLE_OK;

        if (sspi_status == SEC_E_OK) {
            len = outbuf[0].cbBuffer + outbuf[1].cbBuffer + outbuf[2].cbBuffer;
            while (len > pnwritten.*) {
                var this_write: usize = 0;
                var timeout_ms = c_ext.Curl_timeleft_ms(data);
                if (timeout_ms < 0) {
                    c_ext.Curl_failf(data, "schannel: timed out sending data (bytes sent: %zu)", pnwritten.*);
                    result = CURLE_OPERATION_TIMEDOUT;
                    break;
                } else if (timeout_ms == 0) {
                    timeout_ms = std.math.maxInt(i64);
                }
                const sockfd = c_ext.Curl_conn_cf_get_socket(cf, data);
                const what = c_ext.Curl_socket_check(CURL_SOCKET_BAD, CURL_SOCKET_BAD, sockfd, timeout_ms);
                if (what < 0) {
                    c_ext.Curl_failf(data, "select/poll on SSL socket, errno: %d", win_ext.WSAGetLastError());
                    result = CURLE_SEND_ERROR;
                    break;
                } else if (what == 0) {
                    c_ext.Curl_failf(data, "schannel: timed out sending data (bytes sent: %zu)", pnwritten.*);
                    result = CURLE_OPERATION_TIMEDOUT;
                    break;
                }

                result = c_ext.Curl_conn_cf_send(
                    cf.next,
                    data,
                    ptr + pnwritten.*,
                    len - pnwritten.*,
                    false,
                    &this_write,
                );
                if (result == CURLE_AGAIN) {
                    continue;
                } else if (result != CURLE_OK) {
                    break;
                }
                pnwritten.* += this_write;
            }
        } else if (sspi_status == SEC_E_INSUFFICIENT_MEMORY) {
            result = CURLE_OUT_OF_MEMORY;
        } else {
            result = CURLE_SEND_ERROR;
        }

        if (len == pnwritten.*) {
            pnwritten.* = outbuf[1].cbBuffer;
        }

        return result;
    }

    fn schannelRecv(
        cf: *CurlCfilter,
        data: ?*CurlEasy,
        buf: [*]u8,
        len: usize,
        pnread: *usize,
    ) callconv(.c) CURLcode {
        const connssl: *SslConnectData = @ptrCast(@alignCast(cf.ctx orelse return CURLE_RECV_ERROR));
        const backend: *SchannelSslBackendData = @ptrCast(@alignCast(connssl.backend orelse return CURLE_RECV_ERROR));
        const sec_fn = win_ext.Curl_pSecFn orelse return CURLE_RECV_ERROR;

        pnread.* = 0;
        var result: CURLcode = CURLE_OK;
        var sspi_status: SECURITY_STATUS = SEC_E_OK;

        if (backend.recv_renegotiating()) {
            result = schannelRecvRenegotiate(cf, data, .recv);
            if (result != CURLE_OK) return result;
        }

        cleanup: {
            if (len > 0 and len <= backend.decdata.offset) {
                break :cleanup;
            } else if (backend.recv_unrecoverable_err != CURLE_OK) {
                result = backend.recv_unrecoverable_err;
                c_ext.Curl_infof(data, "schannel: an unrecoverable error occurred in a prior call");
                break :cleanup;
            } else if (backend.recv_sspi_close_notify()) {
                c_ext.Curl_infof(data, "schannel: server indicated shutdown in a prior call");
                break :cleanup;
            } else if (len > 0 and !backend.recv_connection_closed()) {
                const min_encdata_length = len + CURL_SCHANNEL_BUFFER_FREE_SIZE;
                result = ensureEncodingSize(data, &backend.encdata, min_encdata_length);
                if (result != CURLE_OK) break :cleanup;

                var nread: usize = 0;
                result = c_ext.Curl_conn_cf_recv(
                    cf.next,
                    data,
                    backend.encdata.buffer.? + backend.encdata.offset,
                    backend.encdata.length - backend.encdata.offset,
                    &nread,
                );
                if (result != CURLE_OK) {
                    if (result != CURLE_AGAIN) {
                        c_ext.Curl_infof(data, "schannel: recv returned error %d", @as(c_int, @intCast(result)));
                        backend.recv_unrecoverable_err = result;
                    }
                } else if (nread == 0) {
                    backend.set_recv_connection_closed(true);
                } else {
                    backend.encdata.offset += nread;
                    backend.set_encdata_is_incomplete(false);
                }
            }

            while (backend.encdata.offset > 0 and sspi_status == SEC_E_OK and
                (len == 0 or backend.decdata.offset < len or backend.recv_connection_closed()))
            {
                var inbuf: [4]SecBuffer = undefined;
                var inbuf_desc: SecBufferDesc = undefined;
                initSecBuffer(&inbuf[0], SECBUFFER_DATA, backend.encdata.buffer, @intCast(backend.encdata.offset));
                initSecBuffer(&inbuf[1], SECBUFFER_EMPTY, null, 0);
                initSecBuffer(&inbuf[2], SECBUFFER_EMPTY, null, 0);
                initSecBuffer(&inbuf[3], SECBUFFER_EMPTY, null, 0);
                initSecBufferDesc(&inbuf_desc, &inbuf, 4);

                sspi_status = sec_fn.DecryptMessage(&backend.ctxt.?.ctxt_handle, &inbuf_desc, 0, null);

                if (sspi_status == SEC_E_OK or sspi_status == SEC_I_RENEGOTIATE or sspi_status == SEC_I_CONTEXT_EXPIRED) {
                    if (inbuf[1].BufferType == SECBUFFER_DATA) {
                        result = ensureDecodingSize(data, &backend.decdata, inbuf[1].cbBuffer, len);
                        if (result != CURLE_OK) break :cleanup;

                        const dsize: usize = inbuf[1].cbBuffer;
                        if (dsize > 0 and inbuf[1].pvBuffer != null) {
                            const src: [*]const u8 = @ptrCast(inbuf[1].pvBuffer.?);
                            @memcpy(backend.decdata.buffer.?[backend.decdata.offset .. backend.decdata.offset + dsize], src[0..dsize]);
                            backend.decdata.offset += dsize;
                        }
                    }

                    if (inbuf[3].BufferType == SECBUFFER_EXTRA and inbuf[3].cbBuffer > 0) {
                        const extra_len: usize = inbuf[3].cbBuffer;
                        if (backend.encdata.offset > extra_len) {
                            const src_off = backend.encdata.offset - extra_len;
                            std.mem.copyForwards(
                                u8,
                                backend.encdata.buffer.?[0..extra_len],
                                backend.encdata.buffer.?[src_off .. src_off + extra_len],
                            );
                            backend.encdata.offset = extra_len;
                        }
                    } else {
                        backend.encdata.offset = 0;
                    }

                    if (sspi_status == SEC_I_RENEGOTIATE) {
                        c_ext.Curl_infof(data, "schannel: remote party requests renegotiation");
                        if (result != CURLE_OK and result != CURLE_AGAIN) {
                            c_ext.Curl_infof(data, "schannel: cannot renegotiate, an error is pending");
                            break :cleanup;
                        }

                        backend.set_recv_renegotiating(true);
                        result = schannelRecvRenegotiate(cf, data, .recv);
                        if (result != CURLE_OK) break :cleanup;

                        sspi_status = SEC_E_OK;
                        continue;
                    } else if (sspi_status == SEC_I_CONTEXT_EXPIRED) {
                        backend.set_recv_sspi_close_notify(true);
                        if (!backend.recv_connection_closed()) {
                            backend.set_recv_connection_closed(true);
                        }
                        if (result == CURLE_RECV_ERROR) {
                            result = CURLE_OK;
                        }
                        c_ext.Curl_infof(data, "schannel: server close notification received (close_notify)");
                        break :cleanup;
                    }
                } else if (sspi_status == SEC_E_INCOMPLETE_MESSAGE) {
                    backend.set_encdata_is_incomplete(true);
                    if (result == CURLE_OK) {
                        result = CURLE_AGAIN;
                    }
                    break :cleanup;
                } else {
                    var buffer: [STRERROR_LEN]u8 = undefined;
                    c_ext.Curl_failf(
                        data,
                        "schannel: failed to read data from server: %s",
                        win_ext.Curl_sspi_strerror(sspi_status, &buffer, buffer.len),
                    );
                    result = CURLE_RECV_ERROR;
                    break :cleanup;
                }
            }
        }

        if (len > 0 and backend.decdata.offset == 0 and backend.recv_connection_closed() and !backend.recv_sspi_close_notify()) {
            result = CURLE_RECV_ERROR;
            c_ext.Curl_failf(data, "schannel: server closed abruptly (missing close_notify)");
        }

        if (result != CURLE_OK and result != CURLE_AGAIN) {
            backend.recv_unrecoverable_err = result;
        }

        const copy_size = @min(len, backend.decdata.offset);
        if (copy_size > 0) {
            @memcpy(buf[0..copy_size], backend.decdata.buffer.?[0..copy_size]);
            const rem = backend.decdata.offset - copy_size;
            if (rem > 0) {
                std.mem.copyForwards(u8, backend.decdata.buffer.?[0..rem], backend.decdata.buffer.?[copy_size .. copy_size + rem]);
            }
            backend.decdata.offset = rem;
            pnread.* = copy_size;
            return CURLE_OK;
        }

        if (result == CURLE_OK and !backend.recv_connection_closed()) {
            result = CURLE_AGAIN;
        }

        if (len == 0) {
            return CURLE_OK;
        }

        return result;
    }

    fn schannelDataPending(cf: *CurlCfilter, data: ?*const CurlEasy) callconv(.c) bool {
        _ = data;
        const connssl: *SslConnectData = @ptrCast(@alignCast(cf.ctx orelse return false));
        const backend: *SchannelSslBackendData = @ptrCast(@alignCast(connssl.backend orelse return false));
        if (backend.ctxt != null) {
            return backend.decdata.offset > 0 or
                (backend.encdata.offset > 0 and !backend.encdata_is_incomplete()) or
                backend.recv_connection_closed() or
                backend.recv_sspi_close_notify() or
                backend.recv_unrecoverable_err != CURLE_OK;
        }
        return false;
    }

    fn schannelShutdown(cf: *CurlCfilter, data: ?*CurlEasy, send_shutdown: bool, done: *bool) callconv(.c) CURLcode {
        _ = send_shutdown;
        if (cf.isShutdown()) {
            done.* = true;
            return CURLE_OK;
        }

        const connssl: *SslConnectData = @ptrCast(@alignCast(cf.ctx orelse return CURLE_OK));
        const backend: *SchannelSslBackendData = @ptrCast(@alignCast(connssl.backend orelse return CURLE_OK));
        const sec_fn = win_ext.Curl_pSecFn orelse return CURLE_SEND_ERROR;
        var result: CURLcode = CURLE_OK;

        done.* = false;
        if (backend.ctxt != null) {
            if (connssl.peer.origin) |orig| {
                c_ext.Curl_infof(
                    data,
                    "schannel: shutting down SSL/TLS connection with %s port %d",
                    orig.hostname,
                    orig.port,
                );
            }
        }

        out: {
            if (backend.ctxt == null or cf.isShutdown()) {
                done.* = true;
                break :out;
            }

            if (backend.cred != null and backend.ctxt != null and !backend.sent_shutdown() and !backend.shutdown_generated()) {
                var BuffDesc: SecBufferDesc = undefined;
                var Buffer: SecBuffer = undefined;
                var outbuf: SecBuffer = undefined;
                var outbuf_desc: SecBufferDesc = undefined;
                var dwshut: DWORD = SCHANNEL_SHUTDOWN;

                initSecBuffer(&Buffer, SECBUFFER_TOKEN, &dwshut, @sizeOf(DWORD));
                initSecBufferDesc(&BuffDesc, @ptrCast(&Buffer), 1);

                var sspi_status = sec_fn.ApplyControlToken(&backend.ctxt.?.ctxt_handle, &BuffDesc);
                if (sspi_status != SEC_E_OK) {
                    var buffer: [STRERROR_LEN]u8 = undefined;
                    c_ext.Curl_failf(
                        data,
                        "schannel: ApplyControlToken failure: %s",
                        win_ext.Curl_sspi_strerror(sspi_status, &buffer, buffer.len),
                    );
                    result = CURLE_SEND_ERROR;
                    break :out;
                }

                initSecBuffer(&outbuf, SECBUFFER_EMPTY, null, 0);
                initSecBufferDesc(&outbuf_desc, @ptrCast(&outbuf), 1);

                sspi_status = sec_fn.InitializeSecurityContextA(
                    &backend.cred.?.cred_handle,
                    &backend.ctxt.?.ctxt_handle,
                    backend.cred.?.sni_hostname,
                    backend.req_flags,
                    0,
                    0,
                    null,
                    0,
                    &backend.ctxt.?.ctxt_handle,
                    &outbuf_desc,
                    &backend.ret_flags,
                    null,
                );

                if (sspi_status == SEC_E_OK or sspi_status == SEC_I_CONTEXT_EXPIRED) {
                    backend.shutdown_token = outbuf;
                    backend.set_shutdown_generated(true);
                } else {
                    var buffer: [STRERROR_LEN]u8 = undefined;
                    if (outbuf.pvBuffer) |pv| {
                        _ = sec_fn.FreeContextBuffer(pv);
                    }
                    c_ext.Curl_failf(
                        data,
                        "schannel: generating close msg failed: %s",
                        win_ext.Curl_sspi_strerror(sspi_status, &buffer, buffer.len),
                    );
                    result = CURLE_SEND_ERROR;
                    break :out;
                }
            }

            if (backend.shutdown_generated() and !backend.sent_shutdown()) {
                var written: usize = 0;
                const remaining: usize = @as(usize, backend.shutdown_token.cbBuffer) - backend.shutdown_offset;
                if (remaining > 0) {
                    const token_ptr: [*]const u8 = @ptrCast(backend.shutdown_token.pvBuffer.?);
                    result = c_ext.Curl_conn_cf_send(
                        cf.next,
                        data,
                        token_ptr + backend.shutdown_offset,
                        remaining,
                        false,
                        &written,
                    );
                    if (result == CURLE_OK) {
                        backend.shutdown_offset += written;
                    }
                    if (result == CURLE_AGAIN or (result == CURLE_OK and written < remaining)) {
                        connssl.io_need = CURL_SSL_IO_NEED_SEND;
                        result = CURLE_OK;
                        break :out;
                    }
                } else {
                    result = CURLE_OK;
                }
                if (result != CURLE_OK) {
                    if (backend.recv_connection_closed()) {
                        done.* = true;
                        result = CURLE_OK;
                    } else {
                        c_ext.Curl_failf(data, "schannel: error sending close msg: %d", @as(c_int, @intCast(result)));
                        result = CURLE_SEND_ERROR;
                    }
                    break :out;
                }
                if (backend.shutdown_token.pvBuffer) |pv| {
                    _ = sec_fn.FreeContextBuffer(pv);
                }
                backend.shutdown_token = std.mem.zeroes(SecBuffer);
                backend.shutdown_offset = 0;
                backend.set_sent_shutdown(true);
                done.* = true;
            }

            if (backend.cred != null and backend.ctxt != null and
                !backend.recv_sspi_close_notify() and !backend.recv_connection_closed())
            {
                var buffer: [1024]u8 = undefined;
                var nread: usize = 0;
                result = schannelRecv(cf, data, &buffer, buffer.len, &nread);
                if (result == CURLE_AGAIN) {
                    connssl.io_need = CURL_SSL_IO_NEED_RECV;
                } else if (result != CURLE_OK) {
                    result = CURLE_RECV_ERROR;
                } else if (nread == 0) {
                    backend.set_recv_connection_closed(true);
                    done.* = true;
                }
            }
        }

        cf.setShutdown(result != CURLE_OK or done.*);
        return result;
    }

    fn schannelClose(cf: *CurlCfilter, data: ?*CurlEasy) callconv(.c) void {
        const connssl: *SslConnectData = @ptrCast(@alignCast(cf.ctx orelse return));
        const backend: *SchannelSslBackendData = @ptrCast(@alignCast(connssl.backend orelse return));

        if (backend.shutdown_token.pvBuffer) |pv| {
            if (win_ext.Curl_pSecFn) |sec_fn| {
                _ = sec_fn.FreeContextBuffer(pv);
            }
        }
        backend.shutdown_token = std.mem.zeroes(SecBuffer);
        backend.shutdown_offset = 0;

        if (backend.ctxt) |ctxt| {
            if (win_ext.Curl_vtls_acc_conn_get_ssl_context(cf.conn) == @as(?*anyopaque, @ptrCast(&ctxt.ctxt_handle))) {
                win_ext.Curl_vtls_acc_conn_set_ssl_context(cf.conn, null);
            }
            if (win_ext.Curl_pSecFn) |sec_fn| {
                _ = sec_fn.DeleteSecurityContext(&ctxt.ctxt_handle);
            }
            mem.freeSized(ctxt, @sizeOf(CurlSchannelCtxt));
            backend.ctxt = null;
        }

        if (backend.cred) |cred| {
            var scache: ?*CurlSslScache = null;
            var has_share_scache = false;
            var trc_feat: ?*CurlTrcFeat = null;
            c_ext.Curl_vtls_acc_scache_params(data, &scache, &has_share_scache, &trc_feat);
            vtls_scache_asn1.Curl_ssl_scache_lock_zig(data, scache, has_share_scache);
            schannelSessionFree(cred);
            vtls_scache_asn1.Curl_ssl_scache_unlock_zig(data, scache, has_share_scache);
            backend.cred = null;
        }

        if (backend.send_buffer) |b| {
            mem.secureZero(b, backend.send_buffer_len);
            mem.freeSized(b, backend.send_buffer_len);
            backend.send_buffer = null;
        }
        backend.send_buffer_len = 0;

        if (backend.encdata.buffer) |b| {
            mem.secureZero(b, backend.encdata.length);
            mem.freeSized(b, backend.encdata.length);
            backend.encdata.buffer = null;
            backend.encdata.length = 0;
            backend.encdata.offset = 0;
            backend.set_encdata_is_incomplete(false);
        }
        if (backend.decdata.buffer) |b| {
            mem.secureZero(b, backend.decdata.length);
            mem.freeSized(b, backend.decdata.length);
            backend.decdata.buffer = null;
            backend.decdata.length = 0;
            backend.decdata.offset = 0;
        }
    }

    fn schannelInit() callconv(.c) c_int {
        const WineGetVersionFn = *const fn () callconv(sspi_cc) ?[*:0]const u8;
        const hmod = win_ext.GetModuleHandleA("ntdll");
        const proc = if (hmod != null) win_ext.GetProcAddress(hmod, "wine_get_version") else null;
        if (proc) |p| {
            const p_wine_get_version: WineGetVersionFn = @ptrCast(@alignCast(p));
            var ver: i64 = 0;
            if (p_wine_get_version()) |wv_init| {
                var wv: [*:0]const u8 = wv_init;
                _ = win_ext.curlx_str_number(&wv, &ver, 20);
            }
            s_win_has_alpn = (ver >= 6);
        } else {
            s_win_has_alpn = win_ext.curlx_verify_windows_version(6, 3, 0, PLATFORM_WINNT, VERSION_GREATER_THAN_EQUAL);
        }

        return if (win_ext.Curl_sspi_global_init() == CURLE_OK) 1 else 0;
    }

    fn schannelCleanup() callconv(.c) void {
        win_ext.Curl_sspi_global_cleanup();
    }

    fn schannelGetInternals(connssl: *SslConnectData, info: c_uint) callconv(.c) ?*anyopaque {
        _ = info;
        const backend: *SchannelSslBackendData = @ptrCast(@alignCast(connssl.backend orelse return null));
        if (backend.ctxt) |ctxt| {
            return &ctxt.ctxt_handle;
        }
        return null;
    }

    fn schannelVersion(buffer: [*]u8, size: usize) callconv(.c) usize {
        const v = "Schannel";
        if (size == 0) return 0;
        const n = @min(v.len, size - 1);
        @memcpy(buffer[0..n], v[0..n]);
        buffer[n] = 0;
        return n;
    }

    fn schannelRandom(data: ?*CurlEasy, entropy: [*]u8, length: usize) callconv(.c) CURLcode {
        _ = data;
        return os_leaf.win32.curlx_win32_random(entropy, length);
    }

    fn schannelSha256sum(input: [*]const u8, inputlen: usize, sha256sum: [*]u8, sha256len: usize) callconv(.c) CURLcode {
        @memset(sha256sum[0..sha256len], 0);
        if (sha256len < CURL_SHA256_DIGEST_LENGTH) return CURLE_BAD_FUNCTION_ARGUMENT;
        var digest: [CURL_SHA256_DIGEST_LENGTH]u8 = undefined;
        std.crypto.hash.sha2.Sha256.hash(input[0..inputlen], &digest, .{});
        @memcpy(sha256sum[0..CURL_SHA256_DIGEST_LENGTH], &digest);
        return CURLE_OK;
    }

    pub fn Curl_schannel_get_cached_cert_store(cf: *CurlCfilter, data: ?*CurlEasy) callconv(.c) HCERTSTORE {
        const conn_config = vtls_impl.Curl_ssl_cf_get_filter_config(cf) orelse return null;
        const proto_hash = win_ext.Curl_vtls_acc_multi_proto_hash(data) orelse return null;

        const raw_share = win_ext.Curl_hash_pick(
            proto_hash,
            MPROTO_SCHANNEL_CERT_SHARE_KEY.ptr,
            MPROTO_SCHANNEL_CERT_SHARE_KEY.len,
        ) orelse return null;
        const share: *SchCertShare = @ptrCast(@alignCast(raw_share));
        if (share.cert_store == null) return null;

        const ca_cache_timeout = c_ext.Curl_vtls_acc_ssl_ca_cache_timeout(data);
        if (ca_cache_timeout == 0) {
            return null;
        }

        const timeout_ms: i64 = @as(i64, ca_cache_timeout) * 1000;
        if (timeout_ms >= 0) {
            const elapsed_ms = curlx_time_net.curlx_ptimediff_ms(c_ext.Curl_pgrs_now(data), &share.time);
            if (elapsed_ms >= timeout_ms) {
                return null;
            }
        }

        if (conn_config.ca_info_blob) |ca_info_blob| {
            if (share.CAinfo_blob_size != ca_info_blob.len) {
                return null;
            }
            var info_blob_digest: [CURL_SHA256_DIGEST_LENGTH]u8 = undefined;
            const blob_ptr: [*]const u8 = if (ca_info_blob.data) |d| @ptrCast(d) else (&info_blob_digest);
            if (schannelSha256sum(blob_ptr, ca_info_blob.len, &info_blob_digest, CURL_SHA256_DIGEST_LENGTH) != CURLE_OK) {
                return null;
            }
            if (!std.mem.eql(u8, &share.CAinfo_blob_digest, &info_blob_digest)) {
                return null;
            }
        } else {
            if (conn_config.CAfile == null or share.CAfile == null or
                !std.mem.eql(u8, std.mem.span(share.CAfile.?), std.mem.span(conn_config.CAfile.?)))
            {
                return null;
            }
        }

        return share.cert_store;
    }

    fn schannelCertShareFree(key: *const anyopaque, key_len: usize, p: *anyopaque) callconv(.c) void {
        _ = key;
        _ = key_len;
        const share: *SchCertShare = @ptrCast(@alignCast(p));
        if (share.cert_store) |cs| {
            _ = win_ext.CertCloseStore(cs, 0);
        }
        if (share.CAfile) |caf| {
            mem.free(caf);
        }
        mem.free(share);
    }

    pub fn Curl_schannel_set_cached_cert_store(cf: *CurlCfilter, data: ?*CurlEasy, cert_store: HCERTSTORE) callconv(.c) bool {
        const conn_config = vtls_impl.Curl_ssl_cf_get_filter_config(cf) orelse return false;
        const proto_hash = win_ext.Curl_vtls_acc_multi_proto_hash(data) orelse return false;

        var digest: [CURL_SHA256_DIGEST_LENGTH]u8 = undefined;
        var CAfile: ?[*:0]u8 = null;

        if (conn_config.ca_info_blob) |ca_info_blob| {
            const blob_ptr: [*]const u8 = if (ca_info_blob.data) |d| @ptrCast(d) else (&digest);
            if (schannelSha256sum(blob_ptr, ca_info_blob.len, &digest, CURL_SHA256_DIGEST_LENGTH) != CURLE_OK) {
                return false;
            }
        } else if (conn_config.CAfile) |caf| {
            CAfile = mem.strdup(caf) orelse return false;
        }

        var share: *SchCertShare = undefined;
        if (win_ext.Curl_hash_pick(
            proto_hash,
            MPROTO_SCHANNEL_CERT_SHARE_KEY.ptr,
            MPROTO_SCHANNEL_CERT_SHARE_KEY.len,
        )) |raw_share| {
            share = @ptrCast(@alignCast(raw_share));
        } else {
            const raw_new = mem.calloc(1, @sizeOf(SchCertShare)) orelse {
                if (CAfile) |caf| mem.free(caf);
                return false;
            };
            share = @ptrCast(@alignCast(raw_new));
            if (win_ext.Curl_hash_add2(
                proto_hash,
                MPROTO_SCHANNEL_CERT_SHARE_KEY.ptr,
                MPROTO_SCHANNEL_CERT_SHARE_KEY.len,
                share,
                schannelCertShareFree,
            ) == null) {
                mem.free(share);
                if (CAfile) |caf| mem.free(caf);
                return false;
            }
        }

        if (share.cert_store) |cs| {
            _ = win_ext.CertCloseStore(cs, 0);
        }
        if (share.CAfile) |old_caf| {
            mem.free(old_caf);
        }

        if (conn_config.ca_info_blob) |ca_info_blob| {
            @memcpy(&share.CAinfo_blob_digest, &digest);
            share.CAinfo_blob_size = ca_info_blob.len;
        } else {
            share.CAinfo_blob_size = 0;
        }

        share.time = curlx_time_net.curlx_now();
        share.cert_store = cert_store;
        share.CAfile = CAfile;
        return true;
    }

    fn schannelChannelBinding(data: ?*CurlEasy, sockindex: i8, binding: *DynBuf) callconv(.c) CURLcode {
        const conn = c_ext.Curl_vtls_acc_data_conn(data) orelse return CURLE_OK;
        var cf = c_ext.Curl_vtls_acc_conn_cfilter(conn, sockindex);
        while (cf) |cur| : (cf = cur.next) {
            if (cur.cft == &vtls_impl.Curl_cft_ssl or cur.cft == &vtls_impl.Curl_cft_ssl_proxy) {
                const connssl: *SslConnectData = @ptrCast(@alignCast(cur.ctx orelse return CURLE_OK));
                const backend: *SchannelSslBackendData = @ptrCast(@alignCast(connssl.backend orelse return CURLE_OK));
                if (backend.ctxt) |ctxt| {
                    const sec_fn = win_ext.Curl_pSecFn orelse return CURLE_SSL_CONNECT_ERROR;
                    var bindings: SecPkgContext_Bindings = std.mem.zeroes(SecPkgContext_Bindings);
                    const st = sec_fn.QueryContextAttributesA(&ctxt.ctxt_handle, SECPKG_ATTR_ENDPOINT_BINDINGS, @ptrCast(&bindings));
                    if (st != SEC_E_OK) return CURLE_SSL_CONNECT_ERROR;
                    defer if (bindings.Bindings) |b| {
                        _ = sec_fn.FreeContextBuffer(b);
                    };
                    if (bindings.BindingsLength > 32 and bindings.Bindings != null) {
                        const bptr: [*]const u8 = @ptrCast(bindings.Bindings.?);
                        return containers.curlx_dyn_addn(binding, bptr + 32, bindings.BindingsLength - 32);
                    }
                }
                break;
            }
        }
        return CURLE_OK;
    }

    pub const Curl_ssl_schannel = CurlSsl{
        .info = .{ .id = CURLSSLBACKEND_SCHANNEL, .name = "schannel" },
        .supports = SSLSUPP_CERTINFO | SSLSUPP_PINNEDPUBKEY | SSLSUPP_CAINFO_BLOB | SSLSUPP_HTTPS_PROXY | SSLSUPP_CIPHER_LIST | SSLSUPP_CA_CACHE,
        .sizeof_ssl_backend_data = @sizeOf(SchannelSslBackendData),
        .init = schannelInit,
        .cleanup = schannelCleanup,
        .version = schannelVersion,
        .shut_down = schannelShutdown,
        .data_pending = schannelDataPending,
        .random = schannelRandom,
        .cert_status_request = null,
        .do_connect = schannelConnect,
        .adjust_pollset = vtls_impl.Curl_ssl_adjust_pollset,
        .get_internals = schannelGetInternals,
        .close = schannelClose,
        .close_all = null,
        .engines_list = null,
        .sha256sum = schannelSha256sum,
        .recv_plain = schannelRecv,
        .send_plain = schannelSend,
        .get_channel_binding = schannelChannelBinding,
    };
};

// ============================================================================
// 3. lib/vtls/openssl.c — OpenSSL Backend
// ============================================================================

pub const openssl_backend = struct {
    const SSL_CTX = opaque {};
    const SSL = opaque {};
    const SSL_METHOD = opaque {};
    const SSL_SESSION = opaque {};
    const BIO = opaque {};
    const BIO_METHOD = opaque {};
    const X509 = opaque {};
    const X509_CRL = opaque {};
    const X509_STORE = opaque {};
    const X509_NAME = opaque {};
    const X509_NAME_ENTRY = opaque {};
    const X509_EXTENSION = opaque {};
    const X509_PUBKEY = opaque {};
    const X509_ALGOR = opaque {};
    const X509_LOOKUP = opaque {};
    const X509_LOOKUP_METHOD = opaque {};
    const ASN1_OBJECT = opaque {};
    const ASN1_STRING = opaque {};
    const ASN1_INTEGER = ASN1_STRING;
    const ASN1_BIT_STRING = ASN1_STRING;
    const ASN1_TIME = ASN1_STRING;
    const EVP_PKEY = opaque {};
    const EVP_MD = opaque {};
    const BIGNUM = opaque {};
    const OPENSSL_STACK = opaque {};
    const OCSP_RESPONSE = opaque {};
    const OCSP_BASICRESP = opaque {};
    const OCSP_SINGLERESP = opaque {};
    const OSSL_LIB_CTX = opaque {};
    const OSSL_PROVIDER = opaque {};

    const SSL_ERROR_NONE: c_int = 0;
    const SSL_ERROR_SSL: c_int = 1;
    const SSL_ERROR_WANT_READ: c_int = 2;
    const SSL_ERROR_WANT_WRITE: c_int = 3;
    const SSL_ERROR_WANT_X509_LOOKUP: c_int = 4;
    const SSL_ERROR_SYSCALL: c_int = 5;
    const SSL_ERROR_ZERO_RETURN: c_int = 6;
    const SSL_ERROR_WANT_CONNECT: c_int = 7;
    const SSL_ERROR_WANT_ACCEPT: c_int = 8;

    const BIO_TYPE_MEM: c_int = 1 | 0x0400;
    const BIO_CTRL_RESET: c_int = 1;
    const BIO_CTRL_EOF: c_int = 2;
    const BIO_CTRL_INFO: c_int = 3;
    const BIO_CTRL_GET_CLOSE: c_int = 8;
    const BIO_CTRL_SET_CLOSE: c_int = 9;
    const BIO_CTRL_FLUSH: c_int = 11;
    const BIO_CTRL_DUP: c_int = 12;
    const BIO_FLAGS_READ: c_int = 0x01;
    const BIO_FLAGS_WRITE: c_int = 0x02;
    const BIO_FLAGS_IO_SPECIAL: c_int = 0x04;
    const BIO_FLAGS_RWS: c_int = BIO_FLAGS_READ | BIO_FLAGS_WRITE | BIO_FLAGS_IO_SPECIAL;
    const BIO_FLAGS_SHOULD_RETRY: c_int = 0x08;

    const SSL_VERIFY_NONE: c_int = 0x00;
    const SSL_VERIFY_PEER: c_int = 0x01;
    const SSL_VERIFY_FAIL_IF_NO_PEER_CERT: c_int = 0x02;
    const X509_V_OK: c_long = 0;
    const X509_V_FLAG_CRL_CHECK: c_ulong = 0x4;
    const X509_V_FLAG_CRL_CHECK_ALL: c_ulong = 0x8;
    const X509_V_FLAG_TRUSTED_FIRST: c_ulong = 0x8000;
    const X509_V_FLAG_PARTIAL_CHAIN: c_ulong = 0x80000;

    const SSL_FILETYPE_PEM: c_int = 1;
    const SSL_FILETYPE_ASN1: c_int = 2;
    const SSL_FILETYPE_ENGINE: c_int = 42;
    const SSL_FILETYPE_PKCS12: c_int = 43;
    const SSL_FILETYPE_PROVIDER: c_int = 44;

    const SSL_SENT_SHUTDOWN: c_int = 1;
    const SSL_RECEIVED_SHUTDOWN: c_int = 2;

    const SSL_SESS_CACHE_OFF: c_long = 0x0000;
    const SSL_SESS_CACHE_CLIENT: c_long = 0x0001;
    const SSL_SESS_CACHE_NO_INTERNAL_LOOKUP: c_long = 0x0100;
    const SSL_SESS_CACHE_NO_INTERNAL_STORE: c_long = 0x0200;
    const SSL_SESS_CACHE_NO_INTERNAL: c_long = SSL_SESS_CACHE_NO_INTERNAL_LOOKUP | SSL_SESS_CACHE_NO_INTERNAL_STORE;

    const SSL_CTRL_MODE: c_int = 33;
    const SSL_CTRL_SET_READ_AHEAD: c_int = 41;
    const SSL_CTRL_SET_SESS_CACHE_MODE: c_int = 44;
    const SSL_CTRL_SET_TLSEXT_HOSTNAME: c_int = 55;
    const SSL_CTRL_SET_TLSEXT_STATUS_REQ_TYPE: c_int = 65;
    const SSL_CTRL_GET_TLSEXT_STATUS_REQ_OCSP_RESP: c_int = 70;
    const SSL_CTRL_CLEAR_CHAIN_CERTS: c_int = 83;
    const SSL_CTRL_CHAIN_CERT: c_int = 89;
    const SSL_CTRL_SET_GROUPS_LIST: c_int = 92;
    const SSL_CTRL_SET_SIGALGS_LIST: c_int = 98;
    const SSL_CTRL_SET_MIN_PROTO_VERSION: c_int = 123;
    const SSL_CTRL_SET_MAX_PROTO_VERSION: c_int = 124;
    const SSL_CTRL_GET_NEGOTIATED_GROUP: c_int = 134;

    const TLSEXT_NAMETYPE_host_name: c_long = 0;
    const TLSEXT_STATUSTYPE_ocsp: c_long = 1;

    const TLS1_VERSION: c_long = 0x0301;
    const TLS1_1_VERSION: c_long = 0x0302;
    const TLS1_2_VERSION: c_long = 0x0303;
    const TLS1_3_VERSION: c_long = 0x0304;

    const SSL_OP_LEGACY_SERVER_CONNECT: u64 = 0x00000004;
    const SSL_OP_NETSCAPE_REUSE_CIPHER_CHANGE_BUG: u64 = 0x00000008;
    const SSL_OP_TLSEXT_PADDING: u64 = 0x00000010;
    const SSL_OP_DONT_INSERT_EMPTY_FRAGMENTS: u64 = 0x00000800;
    const SSL_OP_NO_TICKET: u64 = 0x00004000;
    const SSL_OP_NO_COMPRESSION: u64 = 0x00020000;
    const SSL_OP_NO_SSLv3: u64 = 1 << 25;
    const SSL_OP_ALL: u64 = 0x80000054;
    const SSL_MODE_ACCEPT_MOVING_WRITE_BUFFER: c_long = 0x00000002;
    const SSL_MODE_RELEASE_BUFFERS: c_long = 0x00000010;

    const NID_undef: c_int = 0;
    const NID_md5: c_int = 4;
    const NID_commonName: c_int = 13;
    const NID_sha1: c_int = 64;
    const NID_subject_alt_name: c_int = 85;

    const GEN_OTHERNAME: c_int = 0;
    const GEN_EMAIL: c_int = 1;
    const GEN_DNS: c_int = 2;
    const GEN_X400: c_int = 3;
    const GEN_DIRNAME: c_int = 4;
    const GEN_EDIPARTY: c_int = 5;
    const GEN_URI: c_int = 6;
    const GEN_IPADD: c_int = 7;
    const GEN_RID: c_int = 8;

    const V_ASN1_UTF8STRING: c_int = 12;
    const V_ASN1_NEG_INTEGER: c_int = 0x0102;
    const XN_FLAG_ONELINE: c_ulong = 0x0082001f;

    const EVP_PKEY_RSA: c_int = 6;
    const EVP_PKEY_DSA: c_int = 116;
    const EVP_PKEY_DH: c_int = 28;

    const OCSP_RESPONSE_STATUS_SUCCESSFUL: c_int = 0;
    const V_OCSP_CERTSTATUS_GOOD: c_int = 0;
    const V_OCSP_CERTSTATUS_REVOKED: c_int = 1;
    const V_OCSP_CERTSTATUS_UNKNOWN: c_int = 2;

    const ERR_LIB_PEM: c_ulong = 9;
    const PEM_R_NO_START_LINE: c_ulong = 108;

    const CURLE_SSL_ENGINE_NOTFOUND: CURLcode = 53;
    const CURLE_SSL_ENGINE_SETFAILED: CURLcode = 54;
    const CURLE_SSL_CACERT_BADFILE: CURLcode = 77;
    const MAX_ALLOWED_CERT_AMOUNT: c_int = 100;

    const GENERAL_NAME = extern struct {
        type: c_int,
        d: extern union {
            ptr: ?*anyopaque,
            dNSName: ?*ASN1_STRING,
            iPAddress: ?*ASN1_STRING,
            ia5: ?*ASN1_STRING,
            ip: ?*ASN1_STRING,
        },
    };

    const X509_INFO = extern struct {
        x509: ?*X509,
        crl: ?*X509_CRL,
    };

    pub const OsslProvider = extern struct {
        engine: ?*anyopaque = null,
        provider: ?*OSSL_PROVIDER = null,
        baseprov: ?*OSSL_PROVIDER = null,
        libctx: ?*OSSL_LIB_CTX = null,
        propq: ?[*:0]u8 = null,
        flags: c_uint = 0,

        pub fn provider_loaded(self: *const OsslProvider) bool {
            return (self.flags & 1) != 0;
        }
        pub fn set_provider_loaded(self: *OsslProvider, v: bool) void {
            if (v) self.flags |= 1 else self.flags &= ~@as(c_uint, 1);
        }
    };

    pub const OsslCtx = extern struct {
        ssl_ctx: ?*SSL_CTX = null,
        ssl: ?*SSL = null,
        bio_method: ?*BIO_METHOD = null,
        p: OsslProvider = .{},
        io_result: CURLcode = CURLE_OK,
        blocked_ssl_write_len: c_int = 0,
        flags: c_uint = 0,

        pub fn x509_store_setup(self: *const OsslCtx) bool {
            return (self.flags & 1) != 0;
        }
        pub fn set_x509_store_setup(self: *OsslCtx, v: bool) void {
            if (v) self.flags |= 1 else self.flags &= ~@as(c_uint, 1);
        }
        pub fn store_is_empty(self: *const OsslCtx) bool {
            return (self.flags & 2) != 0;
        }
        pub fn set_store_is_empty(self: *OsslCtx, v: bool) void {
            if (v) self.flags |= 2 else self.flags &= ~@as(c_uint, 2);
        }
        pub fn reused_session(self: *const OsslCtx) bool {
            return (self.flags & 4) != 0;
        }
        pub fn set_reused_session(self: *OsslCtx, v: bool) void {
            if (v) self.flags |= 4 else self.flags &= ~@as(c_uint, 4);
        }
        pub fn sectrust_verified(self: *const OsslCtx) bool {
            return (self.flags & 8) != 0;
        }
        pub fn set_sectrust_verified(self: *OsslCtx, v: bool) void {
            if (v) self.flags |= 8 else self.flags &= ~@as(c_uint, 8);
        }
        pub fn sectrust_session(self: *const OsslCtx) bool {
            return (self.flags & 16) != 0;
        }
        pub fn set_sectrust_session(self: *OsslCtx, v: bool) void {
            if (v) self.flags |= 16 else self.flags &= ~@as(c_uint, 16);
        }
    };

    const PemPasswordCb = *const fn ([*]u8, c_int, c_int, ?*anyopaque) callconv(.c) c_int;
    const KeylogCb = *const fn (*const SSL, [*:0]const u8) callconv(.c) void;
    pub const NewSessionCb = *const fn (*SSL, *SSL_SESSION) callconv(.c) c_int;
    pub const OsslCtxSetupCb = *const fn (*CurlCfilter, ?*CurlEasy, ?*anyopaque) callconv(.c) CURLcode;
    pub const OsslInitSessionReuseCb = *const fn (*CurlCfilter, ?*CurlEasy, *AlpnSpec, *CurlSslSession, *bool) callconv(.c) CURLcode;
    const SSL_CIPHER = opaque {};

    pub const ossl_ext = struct {
        extern fn TLS_method() callconv(.c) ?*const SSL_METHOD;
        extern fn TLS_client_method() callconv(.c) ?*const SSL_METHOD;
        extern fn SSL_CTX_new(meth: ?*const SSL_METHOD) callconv(.c) ?*SSL_CTX;
        extern fn SSL_CTX_new_ex(libctx: ?*OSSL_LIB_CTX, propq: ?[*:0]const u8, meth: ?*const SSL_METHOD) callconv(.c) ?*SSL_CTX;
        extern fn SSL_CTX_free(ctx: ?*SSL_CTX) callconv(.c) void;
        extern fn SSL_CTX_set_options(ctx: *SSL_CTX, op: u64) callconv(.c) u64;
        extern fn SSL_CTX_clear_options(ctx: *SSL_CTX, op: u64) callconv(.c) u64;
        extern fn SSL_CTX_ctrl(ctx: *SSL_CTX, cmd: c_int, larg: c_long, parg: ?*anyopaque) callconv(.c) c_long;
        extern fn SSL_CTX_set_verify(ctx: *SSL_CTX, mode: c_int, callback: ?*const anyopaque) callconv(.c) void;
        extern fn SSL_CTX_set_default_verify_paths(ctx: *SSL_CTX) callconv(.c) c_int;
        extern fn SSL_CTX_load_verify_locations(ctx: *SSL_CTX, CAfile: ?[*:0]const u8, CApath: ?[*:0]const u8) callconv(.c) c_int;
        extern fn SSL_CTX_get_cert_store(ctx: *const SSL_CTX) callconv(.c) ?*X509_STORE;
        extern fn SSL_CTX_set_cert_store(ctx: *SSL_CTX, store: *X509_STORE) callconv(.c) void;
        extern fn SSL_CTX_set_cipher_list(ctx: *SSL_CTX, str: [*:0]const u8) callconv(.c) c_int;
        extern fn SSL_CTX_set_ciphersuites(ctx: *SSL_CTX, str: [*:0]const u8) callconv(.c) c_int;
        extern fn SSL_CTX_set_post_handshake_auth(ctx: *SSL_CTX, val: c_int) callconv(.c) void;
        extern fn SSL_CTX_set_alpn_protos(ctx: *SSL_CTX, protos: [*]const u8, protos_len: c_uint) callconv(.c) c_int;
        extern fn SSL_set_alpn_protos(ssl: *SSL, protos: [*]const u8, protos_len: c_uint) callconv(.c) c_int;
        extern fn SSL_CTX_set_keylog_callback(ctx: *SSL_CTX, cb: ?KeylogCb) callconv(.c) void;
        extern fn SSL_CTX_set_default_passwd_cb(ctx: *SSL_CTX, cb: ?PemPasswordCb) callconv(.c) void;
        extern fn SSL_CTX_set_default_passwd_cb_userdata(ctx: *SSL_CTX, u: ?*anyopaque) callconv(.c) void;
        extern fn SSL_CTX_use_certificate(ctx: *SSL_CTX, x: *X509) callconv(.c) c_int;
        extern fn SSL_CTX_use_certificate_file(ctx: *SSL_CTX, file: [*:0]const u8, type_: c_int) callconv(.c) c_int;
        extern fn SSL_CTX_use_certificate_chain_file(ctx: *SSL_CTX, file: [*:0]const u8) callconv(.c) c_int;
        extern fn SSL_CTX_use_PrivateKey(ctx: *SSL_CTX, pkey: *EVP_PKEY) callconv(.c) c_int;
        extern fn SSL_CTX_use_PrivateKey_file(ctx: *SSL_CTX, file: [*:0]const u8, type_: c_int) callconv(.c) c_int;
        extern fn SSL_CTX_check_private_key(ctx: *const SSL_CTX) callconv(.c) c_int;
        extern fn SSL_CTX_sess_set_new_cb(ctx: *SSL_CTX, new_session_cb: ?NewSessionCb) callconv(.c) void;

        extern fn SSL_new(ctx: *SSL_CTX) callconv(.c) ?*SSL;
        extern fn SSL_free(ssl: ?*SSL) callconv(.c) void;
        extern fn SSL_set_bio(ssl: *SSL, rbio: ?*BIO, wbio: ?*BIO) callconv(.c) void;
        extern fn SSL_get_rbio(ssl: *const SSL) callconv(.c) ?*BIO;
        extern fn SSL_set_ex_data(ssl: *SSL, idx: c_int, data: ?*anyopaque) callconv(.c) c_int;
        extern fn SSL_get_ex_data(ssl: *const SSL, idx: c_int) callconv(.c) ?*anyopaque;
        extern fn SSL_set_connect_state(ssl: *SSL) callconv(.c) void;
        extern fn SSL_connect(ssl: *SSL) callconv(.c) c_int;
        extern fn SSL_read(ssl: *SSL, buf: ?*anyopaque, num: c_int) callconv(.c) c_int;
        extern fn SSL_write(ssl: *SSL, buf: ?*const anyopaque, num: c_int) callconv(.c) c_int;
        extern fn SSL_shutdown(ssl: *SSL) callconv(.c) c_int;
        extern fn SSL_get_shutdown(ssl: *const SSL) callconv(.c) c_int;
        extern fn SSL_pending(ssl: *const SSL) callconv(.c) c_int;
        extern fn SSL_get_error(ssl: *const SSL, ret_code: c_int) callconv(.c) c_int;
        pub extern fn SSL_ctrl(ssl: *SSL, cmd: c_int, larg: c_long, parg: ?*anyopaque) callconv(.c) c_long;
        extern fn SSL_get0_alpn_selected(ssl: *const SSL, data: *?[*]const u8, len: *c_uint) callconv(.c) void;
        extern fn SSL_get_verify_result(ssl: *const SSL) callconv(.c) c_long;
        extern fn SSL_get1_peer_certificate(ssl: *const SSL) callconv(.c) ?*X509;
        const SSL_get_peer_certificate = SSL_get1_peer_certificate;
        extern fn SSL_get_peer_cert_chain(ssl: *const SSL) callconv(.c) ?*OPENSSL_STACK;
        extern fn SSL_session_reused(ssl: *const SSL) callconv(.c) c_int;
        extern fn SSL_set_session(ssl: *SSL, session: ?*SSL_SESSION) callconv(.c) c_int;
        extern fn SSL_version(ssl: *const SSL) callconv(.c) c_int;
        extern fn SSL_get_version(ssl: *const SSL) callconv(.c) ?[*:0]const u8;
        extern fn SSL_get_current_cipher(ssl: *const SSL) callconv(.c) ?*const SSL_CIPHER;
        extern fn SSL_CIPHER_get_name(c: ?*const SSL_CIPHER) callconv(.c) ?[*:0]const u8;
        extern fn SSL_get_peer_signature_type_nid(ssl: *const SSL, pnid: *c_int) callconv(.c) c_int;
        extern fn SSL_SESSION_free(ses: ?*SSL_SESSION) callconv(.c) void;
        extern fn SSL_SESSION_get_timeout(s: *const SSL_SESSION) callconv(.c) c_long;
        extern fn SSL_SESSION_get_max_early_data(s: *const SSL_SESSION) callconv(.c) u32;
        extern fn i2d_SSL_SESSION(in: *SSL_SESSION, pp: ?*?[*]u8) callconv(.c) c_int;
        extern fn d2i_SSL_SESSION(a: ?*?*SSL_SESSION, pp: *?[*]const u8, length: c_long) callconv(.c) ?*SSL_SESSION;

        extern fn X509_free(a: ?*X509) callconv(.c) void;
        extern fn X509_INFO_free(a: ?*anyopaque) callconv(.c) void;
        extern fn X509_get_ext_d2i(x: *const X509, nid: c_int, crit: ?*c_int, idx: ?*c_int) callconv(.c) ?*anyopaque;
        extern fn GENERAL_NAMES_free(a: ?*OPENSSL_STACK) callconv(.c) void;
        extern fn X509_get_subject_name(a: *const X509) callconv(.c) ?*X509_NAME;
        extern fn X509_get_issuer_name(a: *const X509) callconv(.c) ?*X509_NAME;
        extern fn X509_NAME_get_index_by_NID(name: *const X509_NAME, nid: c_int, lastpos: c_int) callconv(.c) c_int;
        extern fn X509_NAME_get_entry(name: *const X509_NAME, loc: c_int) callconv(.c) ?*X509_NAME_ENTRY;
        extern fn X509_NAME_ENTRY_get_data(ne: *const X509_NAME_ENTRY) callconv(.c) ?*ASN1_STRING;
        extern fn X509_NAME_print_ex(out: *BIO, nm: *const X509_NAME, indent: c_int, flags: c_ulong) callconv(.c) c_int;
        extern fn X509_get_version(x: *const X509) callconv(.c) c_long;
        extern fn X509_get_serialNumber(x: *X509) callconv(.c) ?*ASN1_INTEGER;
        extern fn X509_get0_signature(psig: *?*const ASN1_BIT_STRING, palg: *?*const X509_ALGOR, x: *const X509) callconv(.c) void;
        extern fn X509_ALGOR_get0(paobj: *?*const ASN1_OBJECT, pptype: ?*c_int, ppval: ?*?*const anyopaque, algor: *const X509_ALGOR) callconv(.c) void;
        extern fn X509_get_X509_PUBKEY(x: *const X509) callconv(.c) ?*const X509_PUBKEY;
        extern fn X509_PUBKEY_get0_param(ppkalg: *?*ASN1_OBJECT, pk: ?*?*const u8, ppklen: ?*c_int, pa: ?*?*X509_ALGOR, pubkey: *const X509_PUBKEY) callconv(.c) c_int;
        extern fn X509_get0_extensions(x: *const X509) callconv(.c) ?*const OPENSSL_STACK;
        extern fn X509_EXTENSION_get_object(ex: *X509_EXTENSION) callconv(.c) ?*ASN1_OBJECT;
        extern fn X509_EXTENSION_get_data(ne: *X509_EXTENSION) callconv(.c) ?*ASN1_STRING;
        extern fn X509V3_EXT_print(out: *BIO, ext: *X509_EXTENSION, flag: c_ulong, indent: c_int) callconv(.c) c_int;
        extern fn X509_get0_notBefore(x: *const X509) callconv(.c) ?*const ASN1_TIME;
        extern fn X509_get0_notAfter(x: *const X509) callconv(.c) ?*const ASN1_TIME;
        extern fn X509_get_pubkey(x: *X509) callconv(.c) ?*EVP_PKEY;
        extern fn X509_verify_cert_error_string(n: c_long) callconv(.c) [*:0]const u8;
        extern fn X509_check_issued(issuer: *X509, subject: *X509) callconv(.c) c_int;
        extern fn X509_get_signature_nid(x: *const X509) callconv(.c) c_int;
        extern fn X509_digest(data: *const X509, type_: *const EVP_MD, md: [*]u8, len: *c_uint) callconv(.c) c_int;
        extern fn i2d_X509(a: *X509, ppOut: ?*?[*]u8) callconv(.c) c_int;
        extern fn i2d_X509_PUBKEY(a: *const X509_PUBKEY, pp: ?*?[*]u8) callconv(.c) c_int;
        extern fn d2i_X509_bio(bp: *BIO, x509: ?*?*X509) callconv(.c) ?*X509;
        extern fn d2i_PrivateKey_bio(bp: *BIO, a: ?*?*EVP_PKEY) callconv(.c) ?*EVP_PKEY;

        extern fn X509_STORE_add_cert(ctx: *X509_STORE, x: *X509) callconv(.c) c_int;
        extern fn X509_STORE_add_crl(ctx: *X509_STORE, x: *X509_CRL) callconv(.c) c_int;
        extern fn X509_STORE_set_flags(ctx: *X509_STORE, flags: c_ulong) callconv(.c) c_int;
        extern fn X509_STORE_load_locations(ctx: *X509_STORE, file: ?[*:0]const u8, dir: ?[*:0]const u8) callconv(.c) c_int;
        extern fn X509_STORE_up_ref(v: *X509_STORE) callconv(.c) c_int;
        extern fn X509_STORE_free(v: ?*X509_STORE) callconv(.c) void;
        extern fn X509_STORE_add_lookup(v: *X509_STORE, m: ?*const X509_LOOKUP_METHOD) callconv(.c) ?*X509_LOOKUP;
        extern fn X509_LOOKUP_file() callconv(.c) ?*const X509_LOOKUP_METHOD;
        extern fn X509_load_crl_file(ctx: *X509_LOOKUP, file: [*:0]const u8, type_: c_int) callconv(.c) c_int;

        extern fn PEM_write_bio_X509(bp: *BIO, x: *X509) callconv(.c) c_int;
        extern fn PEM_read_bio_X509(bp: *BIO, x: ?*?*X509, cb: ?PemPasswordCb, u: ?*anyopaque) callconv(.c) ?*X509;
        extern fn PEM_read_bio_X509_AUX(bp: *BIO, x: ?*?*X509, cb: ?PemPasswordCb, u: ?*anyopaque) callconv(.c) ?*X509;
        extern fn PEM_read_bio_PrivateKey(bp: *BIO, x: ?*?*EVP_PKEY, cb: ?PemPasswordCb, u: ?*anyopaque) callconv(.c) ?*EVP_PKEY;
        extern fn PEM_X509_INFO_read_bio(bp: *BIO, sk: ?*OPENSSL_STACK, cb: ?PemPasswordCb, u: ?*anyopaque) callconv(.c) ?*OPENSSL_STACK;

        extern fn OPENSSL_sk_num(st: ?*const OPENSSL_STACK) callconv(.c) c_int;
        extern fn OPENSSL_sk_value(st: ?*const OPENSSL_STACK, i: c_int) callconv(.c) ?*anyopaque;
        extern fn OPENSSL_sk_pop_free(st: ?*OPENSSL_STACK, func: *const fn (?*anyopaque) callconv(.c) void) callconv(.c) void;

        extern fn ASN1_STRING_get0_data(x: *const ASN1_STRING) callconv(.c) ?[*]const u8;
        extern fn ASN1_STRING_length(x: *const ASN1_STRING) callconv(.c) c_int;
        extern fn ASN1_STRING_type(x: *const ASN1_STRING) callconv(.c) c_int;
        extern fn ASN1_STRING_to_UTF8(out: *?[*:0]u8, in: *const ASN1_STRING) callconv(.c) c_int;
        extern fn ASN1_STRING_print(bp: *BIO, v: *const ASN1_STRING) callconv(.c) c_int;
        extern fn ASN1_TIME_print(bp: *BIO, tm: *const ASN1_TIME) callconv(.c) c_int;
        extern fn i2a_ASN1_OBJECT(bp: *BIO, a: ?*const ASN1_OBJECT) callconv(.c) c_int;
        extern fn i2t_ASN1_OBJECT(buf: [*]u8, buf_len: c_int, a: ?*const ASN1_OBJECT) callconv(.c) c_int;

        extern fn EVP_PKEY_get_id(pkey: *const EVP_PKEY) callconv(.c) c_int;
        extern fn EVP_PKEY_free(pkey: ?*EVP_PKEY) callconv(.c) void;
        extern fn EVP_PKEY_get_bn_param(pkey: *const EVP_PKEY, key_name: [*:0]const u8, bn: *?*BIGNUM) callconv(.c) c_int;
        extern fn BN_num_bits(a: *const BIGNUM) callconv(.c) c_int;
        extern fn BN_print(fp: *BIO, a: *const BIGNUM) callconv(.c) c_int;
        extern fn BN_clear_free(a: ?*BIGNUM) callconv(.c) void;
        extern fn EVP_sha256() callconv(.c) *const EVP_MD;
        extern fn EVP_get_digestbyname(name: ?[*:0]const u8) callconv(.c) ?*const EVP_MD;
        extern fn OBJ_nid2sn(n: c_int) callconv(.c) ?[*:0]const u8;
        extern fn OBJ_find_sigid_algs(signid: c_int, pdig_nid: *c_int, ppkey_nid: ?*c_int) callconv(.c) c_int;

        extern fn d2i_OCSP_RESPONSE(a: ?*?*OCSP_RESPONSE, in: *?[*]const u8, len: c_long) callconv(.c) ?*OCSP_RESPONSE;
        extern fn OCSP_RESPONSE_free(a: ?*OCSP_RESPONSE) callconv(.c) void;
        extern fn OCSP_response_status(resp: *OCSP_RESPONSE) callconv(.c) c_int;
        extern fn OCSP_response_status_str(s: c_long) callconv(.c) [*:0]const u8;
        extern fn OCSP_response_get1_basic(resp: *OCSP_RESPONSE) callconv(.c) ?*OCSP_BASICRESP;
        extern fn OCSP_BASICRESP_free(a: ?*OCSP_BASICRESP) callconv(.c) void;
        extern fn OCSP_basic_verify(bs: *OCSP_BASICRESP, certs: ?*OPENSSL_STACK, st: ?*X509_STORE, flags: c_ulong) callconv(.c) c_int;
        extern fn OCSP_resp_count(bs: *OCSP_BASICRESP) callconv(.c) c_int;
        extern fn OCSP_resp_get0(bs: *OCSP_BASICRESP, idx: c_int) callconv(.c) ?*OCSP_SINGLERESP;
        extern fn OCSP_single_get0_status(single: *OCSP_SINGLERESP, reason: *c_int, revtime: *?*ASN1_TIME, thisupd: *?*ASN1_TIME, nextupd: *?*ASN1_TIME) callconv(.c) c_int;
        extern fn OCSP_check_validity(thisupd: ?*ASN1_TIME, nextupd: ?*ASN1_TIME, sec: c_long, maxsec: c_long) callconv(.c) c_int;
        extern fn OCSP_cert_status_str(s: c_long) callconv(.c) [*:0]const u8;
        extern fn OCSP_crl_reason_str(s: c_long) callconv(.c) [*:0]const u8;

        extern fn OSSL_LIB_CTX_new() callconv(.c) ?*OSSL_LIB_CTX;
        extern fn OSSL_LIB_CTX_free(ctx: ?*OSSL_LIB_CTX) callconv(.c) void;
        extern fn OSSL_LIB_CTX_load_config(ctx: *OSSL_LIB_CTX, config_file: ?[*:0]const u8) callconv(.c) c_int;
        extern fn OSSL_PROVIDER_available(libctx: ?*OSSL_LIB_CTX, name: [*:0]const u8) callconv(.c) c_int;
        extern fn OSSL_PROVIDER_try_load(libctx: ?*OSSL_LIB_CTX, name: [*:0]const u8, retain_fallbacks: c_int) callconv(.c) ?*OSSL_PROVIDER;
        extern fn OSSL_PROVIDER_unload(prov: *OSSL_PROVIDER) callconv(.c) c_int;

        extern fn BIO_meth_new(btype: c_int, name: [*:0]const u8) callconv(.c) ?*BIO_METHOD;
        extern fn BIO_meth_free(biom: ?*BIO_METHOD) callconv(.c) void;
        extern fn BIO_meth_set_write(biom: *BIO_METHOD, write_fn: *const fn (*BIO, ?[*]const u8, c_int) callconv(.c) c_int) callconv(.c) c_int;
        extern fn BIO_meth_set_read(biom: *BIO_METHOD, read_fn: *const fn (*BIO, ?[*]u8, c_int) callconv(.c) c_int) callconv(.c) c_int;
        extern fn BIO_meth_set_ctrl(biom: *BIO_METHOD, ctrl_fn: *const fn (*BIO, c_int, c_long, ?*anyopaque) callconv(.c) c_long) callconv(.c) c_int;
        extern fn BIO_meth_set_create(biom: *BIO_METHOD, create_fn: *const fn (*BIO) callconv(.c) c_int) callconv(.c) c_int;
        extern fn BIO_meth_set_destroy(biom: *BIO_METHOD, destroy_fn: *const fn (*BIO) callconv(.c) c_int) callconv(.c) c_int;
        extern fn BIO_s_mem() callconv(.c) *const BIO_METHOD;
        extern fn BIO_new(method: *const BIO_METHOD) callconv(.c) ?*BIO;
        extern fn BIO_new_mem_buf(buf: ?*const anyopaque, len: c_int) callconv(.c) ?*BIO;
        extern fn BIO_new_file(filename: [*:0]const u8, mode: [*:0]const u8) callconv(.c) ?*BIO;
        extern fn BIO_free(a: ?*BIO) callconv(.c) c_int;
        extern fn BIO_ctrl(bp: *BIO, cmd: c_int, larg: c_long, parg: ?*anyopaque) callconv(.c) c_long;
        extern fn BIO_puts(bp: *BIO, buf: [*:0]const u8) callconv(.c) c_int;
        extern fn BIO_printf(bio: *BIO, format: [*:0]const u8, ...) callconv(.c) c_int;
        extern fn BIO_set_data(a: *BIO, ptr: ?*anyopaque) callconv(.c) void;
        extern fn BIO_get_data(a: *BIO) callconv(.c) ?*anyopaque;
        extern fn BIO_set_init(a: *BIO, init: c_int) callconv(.c) void;
        extern fn BIO_set_shutdown(a: *BIO, shut: c_int) callconv(.c) void;
        extern fn BIO_get_shutdown(a: *BIO) callconv(.c) c_int;
        extern fn BIO_set_flags(b: *BIO, flags: c_int) callconv(.c) void;
        extern fn BIO_clear_flags(b: *BIO, flags: c_int) callconv(.c) void;

        extern fn CRYPTO_free(ptr: ?*anyopaque, file: [*:0]const u8, line: c_int) callconv(.c) void;
        extern fn ERR_get_error() callconv(.c) c_ulong;
        extern fn ERR_peek_error() callconv(.c) c_ulong;
        extern fn ERR_peek_last_error() callconv(.c) c_ulong;
        extern fn ERR_clear_error() callconv(.c) void;
        extern fn ERR_error_string_n(e: c_ulong, buf: [*]u8, len: usize) callconv(.c) void;
        extern fn RAND_status() callconv(.c) c_int;
        extern fn RAND_bytes(buf: [*]u8, num: c_int) callconv(.c) c_int;
        extern fn OpenSSL_version_num() callconv(.c) c_ulong;

        extern fn Curl_vtls_apple_verify(
            cf: *CurlCfilter,
            data: ?*CurlEasy,
            peer: *const SslPeer,
            num_certs: usize,
            der_cb: *const fn (*CurlCfilter, ?*CurlEasy, ?*anyopaque, usize, *?[*]u8, *usize) callconv(.c) CURLcode,
            cb_user_data: ?*anyopaque,
            ocsp_buf: ?[*]const u8,
            ocsp_len: usize,
            require_ocsp: bool,
        ) callconv(.c) CURLcode;
        extern fn Curl_vtls_apple_verifies_ocsp(cf: ?*CurlCfilter, data: ?*CurlEasy) callconv(.c) bool;
    };

    fn osslStrerror(err: c_ulong, buf: [*]u8, size: usize) [*:0]const u8 {
        if (size == 0) return "";
        buf[0] = 0;
        if (err == 0) {
            const msg = "No error";
            const n = @min(msg.len, size - 1);
            @memcpy(buf[0..n], msg[0..n]);
            buf[n] = 0;
            return @ptrCast(buf);
        }
        ossl_ext.ERR_error_string_n(err, buf, size);
        if (buf[0] == 0) {
            const msg = "Unknown error";
            const n = @min(msg.len, size - 1);
            @memcpy(buf[0..n], msg[0..n]);
            buf[n] = 0;
        }
        return @ptrCast(buf);
    }

    fn sslErrorToStr(err: c_int) [*:0]const u8 {
        return switch (err) {
            SSL_ERROR_NONE => "SSL_ERROR_NONE",
            SSL_ERROR_SSL => "SSL_ERROR_SSL",
            SSL_ERROR_WANT_READ => "SSL_ERROR_WANT_READ",
            SSL_ERROR_WANT_WRITE => "SSL_ERROR_WANT_WRITE",
            SSL_ERROR_WANT_X509_LOOKUP => "SSL_ERROR_WANT_X509_LOOKUP",
            SSL_ERROR_SYSCALL => "SSL_ERROR_SYSCALL",
            SSL_ERROR_ZERO_RETURN => "SSL_ERROR_ZERO_RETURN",
            SSL_ERROR_WANT_CONNECT => "SSL_ERROR_WANT_CONNECT",
            SSL_ERROR_WANT_ACCEPT => "SSL_ERROR_WANT_ACCEPT",
            else => "SSL_ERROR unknown",
        };
    }

    fn peerDispname(peer: *const SslPeer) [*:0]const u8 {
        if (peer.origin) |orig| {
            if (orig.user_hostname[0] != 0) {
                return @ptrCast(&orig.user_hostname[0]);
            }
            return orig.hostname;
        }
        if (peer.sni) |sni| return sni;
        return "";
    }

    fn peerHostname(peer: *const SslPeer) [*:0]const u8 {
        if (peer.origin) |orig| return orig.hostname;
        if (peer.sni) |sni| return sni;
        return "";
    }

    // Pure helper for DNS SAN / CN matching with embedded-NUL rejection
    pub fn matchDnsNameBytes(cert_name: ?[*]const u8, cert_len: usize, host: []const u8) bool {
        const cn = cert_name orelse return false;
        if (cert_len == 0 or host.len == 0) return false;
        const san_slice = cn[0..cert_len];
        if (std.mem.indexOfScalar(u8, san_slice, 0) != null) return false;
        if (std.mem.indexOfScalar(u8, host, 0) != null) return false;
        var host_buf: [256]u8 = undefined;
        if (host.len >= host_buf.len) return false;
        @memcpy(host_buf[0..host.len], host);
        host_buf[host.len] = 0;
        var pat_buf: [256]u8 = undefined;
        if (cert_len >= pat_buf.len) return false;
        @memcpy(pat_buf[0..cert_len], san_slice);
        pat_buf[cert_len] = 0;
        return vtls_core.Curl_cert_hostcheck(@ptrCast(&pat_buf), cert_len, @ptrCast(&host_buf), host.len);
    }

    // Pure helper for IP SAN matching using curlx_inet_pton
    pub fn matchIpSanBytes(san_ip: ?[*]const u8, san_len: usize, peer_type: c_uint, hostname_cstr: [*:0]const u8) bool {
        const ip_bytes = san_ip orelse return false;
        var addr_buf: [16]u8 = @splat(0);
        var addrlen: usize = 0;
        if (peer_type == SSL_PEER_IPV4) {
            if (curlx_time_net.curlx_inet_pton(curlx_time_net.AF_INET, hostname_cstr, &addr_buf) == 1) {
                addrlen = 4;
            }
        } else if (peer_type == SSL_PEER_IPV6) {
            if (curlx_time_net.curlx_inet_pton(AF_INET6_VAL, hostname_cstr, &addr_buf) == 1) {
                addrlen = 16;
            }
        }
        if (addrlen == 0 or san_len != addrlen) return false;
        return std.mem.eql(u8, ip_bytes[0..san_len], addr_buf[0..addrlen]);
    }

    pub const SanEntry = struct {
        san_type: c_int,
        data: ?[*]const u8,
        len: usize,
    };

    pub const HostVerifyOutcome = enum {
        matched_dns_san,
        matched_ip_san,
        matched_cn,
        san_mismatch,
        no_san_for_ip,
        cn_missing,
        cn_embedded_nul,
        cn_mismatch,
    };

    // Pure helper exercising the full RFC 2818 SAN + CN fallback verification flow
    pub fn verifyHostSynthetic(
        peer_type: c_uint,
        hostname_cstr: [*:0]const u8,
        sans: ?[]const SanEntry,
        cn_bytes: ?[]const u8,
    ) HostVerifyOutcome {
        const host_len = std.mem.len(hostname_cstr);
        const host_slice = hostname_cstr[0..host_len];

        if (sans) |entries| {
            for (entries) |entry| {
                if (entry.san_type == GEN_DNS) {
                    if (peer_type == SSL_PEER_DNS and matchDnsNameBytes(entry.data, entry.len, host_slice)) {
                        return .matched_dns_san;
                    }
                } else if (entry.san_type == GEN_IPADD) {
                    if (peer_type != SSL_PEER_DNS and matchIpSanBytes(entry.data, entry.len, peer_type, hostname_cstr)) {
                        return .matched_ip_san;
                    }
                }
            }
            return .san_mismatch;
        }

        if (peer_type != SSL_PEER_DNS) {
            return .no_san_for_ip;
        }

        const cn = cn_bytes orelse return .cn_missing;
        if (cn.len == 0) return .cn_missing;
        if (std.mem.indexOfScalar(u8, cn, 0) != null) return .cn_embedded_nul;
        if (matchDnsNameBytes(cn.ptr, cn.len, host_slice)) {
            return .matched_cn;
        }
        return .cn_mismatch;
    }

    pub const TlsVersionRange = struct {
        min_ver: c_long,
        max_ver: c_long,
    };

    pub fn mapTlsVersionMinMax(version: u8, version_max: u32) ?TlsVersionRange {
        const min_ver: c_long = switch (version) {
            CURL_SSLVERSION_DEFAULT, CURL_SSLVERSION_TLSv1, CURL_SSLVERSION_TLSv1_0 => TLS1_VERSION,
            CURL_SSLVERSION_TLSv1_1 => TLS1_1_VERSION,
            CURL_SSLVERSION_TLSv1_2 => TLS1_2_VERSION,
            CURL_SSLVERSION_TLSv1_3 => TLS1_3_VERSION,
            else => return null,
        };
        const max_code: u32 = version_max >> 16;
        const max_ver: c_long = switch (max_code) {
            0, CURL_SSLVERSION_TLSv1 => 0,
            CURL_SSLVERSION_TLSv1_0 => TLS1_VERSION,
            CURL_SSLVERSION_TLSv1_1 => TLS1_1_VERSION,
            CURL_SSLVERSION_TLSv1_2 => TLS1_2_VERSION,
            CURL_SSLVERSION_TLSv1_3 => TLS1_3_VERSION,
            else => return null,
        };
        if (max_ver != 0 and min_ver > max_ver) return null;
        return .{ .min_ver = min_ver, .max_ver = max_ver };
    }

    pub fn osslDoFileType(type_str: ?[*:0]const u8) c_int {
        const t = type_str orelse return SSL_FILETYPE_PEM;
        if (t[0] == 0) return SSL_FILETYPE_PEM;
        if (primitives.curl_strequal(t, "PEM") != 0) return SSL_FILETYPE_PEM;
        if (primitives.curl_strequal(t, "DER") != 0) return SSL_FILETYPE_ASN1;
        if (primitives.curl_strequal(t, "PROV") != 0) return SSL_FILETYPE_PROVIDER;
        if (primitives.curl_strequal(t, "ENG") != 0) return SSL_FILETYPE_ENGINE;
        if (primitives.curl_strequal(t, "P12") != 0) return SSL_FILETYPE_PKCS12;
        return -1;
    }

    pub fn passwdCallback(buf: [*]u8, num: c_int, encrypting: c_int, password_ptr: ?*anyopaque) callconv(.c) c_int {
        if (encrypting == 0 and num >= 0 and password_ptr != null) {
            const pw: [*:0]const u8 = @ptrCast(password_ptr.?);
            const klen = std.mem.len(pw);
            if (klen < @as(usize, @intCast(num))) {
                @memcpy(buf[0 .. klen + 1], pw[0 .. klen + 1]);
                return @intCast(klen);
            }
        }
        return 0;
    }

    fn osslBioCfCreate(bio: *BIO) callconv(.c) c_int {
        ossl_ext.BIO_set_shutdown(bio, 1);
        ossl_ext.BIO_set_init(bio, 1);
        ossl_ext.BIO_set_data(bio, null);
        return 1;
    }

    fn osslBioCfDestroy(bio: *BIO) callconv(.c) c_int {
        _ = bio;
        return 1;
    }

    fn osslBioCfCtrl(bio: *BIO, cmd: c_int, num: c_long, ptr: ?*anyopaque) callconv(.c) c_long {
        _ = ptr;
        return switch (cmd) {
            BIO_CTRL_GET_CLOSE => @intCast(ossl_ext.BIO_get_shutdown(bio)),
            BIO_CTRL_SET_CLOSE => blk: {
                ossl_ext.BIO_set_shutdown(bio, @intCast(num));
                break :blk 1;
            },
            BIO_CTRL_FLUSH, BIO_CTRL_DUP => 1,
            BIO_CTRL_EOF => blk: {
                const cf: *CurlCfilter = @ptrCast(@alignCast(ossl_ext.BIO_get_data(bio) orelse break :blk 0));
                const connssl: *SslConnectData = @ptrCast(@alignCast(cf.ctx orelse break :blk 0));
                break :blk @intFromBool(connssl.peer_closed());
            },
            else => 0,
        };
    }

    fn osslBioCfOutWrite(bio: *BIO, buf_opt: ?[*]const u8, blen: c_int) callconv(.c) c_int {
        const cf: *CurlCfilter = @ptrCast(@alignCast(ossl_ext.BIO_get_data(bio) orelse return -1));
        const connssl: *SslConnectData = @ptrCast(@alignCast(cf.ctx orelse return -1));
        const octx: *OsslCtx = @ptrCast(@alignCast(connssl.backend orelse return -1));
        const data = connssl.call_data;
        if (blen < 0) return 0;

        var nwritten: usize = 0;
        const result = c_ext.Curl_conn_cf_send(cf.next, data, buf_opt, @intCast(blen), false, &nwritten);
        ossl_ext.BIO_clear_flags(bio, BIO_FLAGS_RWS | BIO_FLAGS_SHOULD_RETRY);
        octx.io_result = result;
        if (result != CURLE_OK) {
            if (result == CURLE_AGAIN) {
                ossl_ext.BIO_set_flags(bio, BIO_FLAGS_WRITE | BIO_FLAGS_SHOULD_RETRY);
            }
            return -1;
        }
        return @intCast(nwritten);
    }

    fn osslBioCfInRead(bio: *BIO, buf_opt: ?[*]u8, blen: c_int) callconv(.c) c_int {
        const cf: *CurlCfilter = @ptrCast(@alignCast(ossl_ext.BIO_get_data(bio) orelse return -1));
        const connssl: *SslConnectData = @ptrCast(@alignCast(cf.ctx orelse return -1));
        const octx: *OsslCtx = @ptrCast(@alignCast(connssl.backend orelse return -1));
        const data = connssl.call_data;
        const buf = buf_opt orelse return 0;
        if (blen <= 0) return 0;

        var nread: usize = 0;
        const result = c_ext.Curl_conn_cf_recv(cf.next, data, buf, @intCast(blen), &nread);
        ossl_ext.BIO_clear_flags(bio, BIO_FLAGS_RWS | BIO_FLAGS_SHOULD_RETRY);
        octx.io_result = result;
        if (result != CURLE_OK) {
            if (result == CURLE_AGAIN) {
                ossl_ext.BIO_set_flags(bio, BIO_FLAGS_READ | BIO_FLAGS_SHOULD_RETRY);
            }
        } else {
            connssl.set_input_pending(true);
            if (nread == 0) {
                connssl.set_peer_closed(true);
            }
        }

        if (!octx.x509_store_setup()) {
            const r2 = Curl_ossl_setup_x509_store(cf, data, octx);
            if (r2 != CURLE_OK) {
                ossl_ext.BIO_clear_flags(bio, BIO_FLAGS_RWS | BIO_FLAGS_SHOULD_RETRY);
                octx.io_result = r2;
                return -1;
            }
            octx.set_x509_store_setup(true);
        }
        return if (result != CURLE_OK) -1 else @intCast(nread);
    }

    fn osslKeylogCallback(ssl: *const SSL, line: [*:0]const u8) callconv(.c) void {
        _ = ssl;
        _ = vtls_core.Curl_tls_keylog_write_line(line);
    }

    pub fn Curl_ossl_init() callconv(.c) c_int {
        vtls_core.Curl_tls_keylog_open();
        return 1;
    }

    pub fn Curl_ossl_cleanup() callconv(.c) void {
        vtls_core.Curl_tls_keylog_close();
    }

    pub fn Curl_ossl_version(buffer: [*]u8, size: usize) callconv(.c) usize {
        const num = ossl_ext.OpenSSL_version_num();
        const major: c_uint = @intCast((num >> 28) & 0xF);
        const minor: c_uint = @intCast((num >> 20) & 0xFF);
        const patch: c_uint = @intCast((num >> 4) & 0xFF);
        const rc = c_ext.curl_msnprintf(buffer, size, "OpenSSL/%u.%u.%u", major, minor, patch);
        return if (rc > 0) @intCast(rc) else 0;
    }

    fn osslProviderCleanup(octx: *OsslCtx) void {
        if (octx.p.baseprov) |bp| {
            _ = ossl_ext.OSSL_PROVIDER_unload(bp);
            octx.p.baseprov = null;
        }
        if (octx.p.provider) |prov| {
            _ = ossl_ext.OSSL_PROVIDER_unload(prov);
            octx.p.provider = null;
        }
        if (octx.p.libctx) |lctx| {
            ossl_ext.OSSL_LIB_CTX_free(lctx);
            octx.p.libctx = null;
        }
        if (octx.p.propq) |pq| {
            mem.free(pq);
            octx.p.propq = null;
        }
        octx.p.set_provider_loaded(false);
    }

    fn osslSetProvider(data: ?*CurlEasy, octx: *OsslCtx, iname_opt: ?[*:0]const u8) CURLcode {
        const iname = iname_opt orelse {
            osslProviderCleanup(octx);
            return CURLE_OK;
        };
        const full = iname[0..std.mem.len(iname)];
        const colon_idx = std.mem.indexOfScalar(u8, full, ':');
        const prov_len = colon_idx orelse full.len;
        if (prov_len == 0 or prov_len > 128) return CURLE_BAD_FUNCTION_ARGUMENT;

        var name_buf: [129]u8 = @splat(0);
        @memcpy(name_buf[0..prov_len], full[0..prov_len]);
        name_buf[prov_len] = 0;

        const propq_cstr: ?[*:0]const u8 = if (colon_idx) |ci| @ptrCast(iname + ci + 1) else null;

        if (octx.p.libctx == null) {
            const libctx = ossl_ext.OSSL_LIB_CTX_new() orelse return CURLE_OUT_OF_MEMORY;
            if (propq_cstr) |pq| {
                const dup_pq = mem.strdup(pq) orelse {
                    ossl_ext.OSSL_LIB_CTX_free(libctx);
                    return CURLE_OUT_OF_MEMORY;
                };
                octx.p.propq = dup_pq;
            }
            octx.p.libctx = libctx;
        }

        _ = ossl_ext.OSSL_LIB_CTX_load_config(octx.p.libctx.?, null);

        if (ossl_ext.OSSL_PROVIDER_available(octx.p.libctx, @ptrCast(&name_buf)) != 0) {
            octx.p.set_provider_loaded(true);
            return CURLE_OK;
        }

        octx.p.provider = ossl_ext.OSSL_PROVIDER_try_load(octx.p.libctx, @ptrCast(&name_buf), 1);
        if (octx.p.provider == null) {
            var err_buf: [256]u8 = @splat(0);
            c_ext.Curl_failf(data, "Failed to initialize provider: %s", osslStrerror(ossl_ext.ERR_get_error(), &err_buf, err_buf.len));
            osslProviderCleanup(octx);
            return CURLE_SSL_ENGINE_NOTFOUND;
        }

        octx.p.baseprov = ossl_ext.OSSL_PROVIDER_try_load(octx.p.libctx, "base", 1);
        if (octx.p.baseprov == null) {
            osslProviderCleanup(octx);
            c_ext.Curl_failf(data, "Failed to load base");
            return CURLE_SSL_ENGINE_NOTFOUND;
        }
        octx.p.set_provider_loaded(true);
        return CURLE_OK;
    }

    fn resolveOsslCtxAndSslCtx(cf: *CurlCfilter, arg: ?*anyopaque) struct { octx: ?*OsslCtx, ssl_ctx: ?*SSL_CTX } {
        var octx: ?*OsslCtx = null;
        if (cf.cft == &vtls_impl.Curl_cft_ssl or cf.cft == &vtls_impl.Curl_cft_ssl_proxy) {
            if (cf.ctx) |ctx_raw| {
                const connssl: *SslConnectData = @ptrCast(@alignCast(ctx_raw));
                if (connssl.backend) |b_raw| {
                    octx = @ptrCast(@alignCast(b_raw));
                }
            }
        }
        if (octx) |oc| {
            if (arg == null or arg == @as(?*anyopaque, @ptrCast(oc))) {
                return .{ .octx = oc, .ssl_ctx = oc.ssl_ctx };
            }
            return .{ .octx = oc, .ssl_ctx = @ptrCast(@alignCast(arg.?)) };
        }
        if (arg) |a| {
            const oc: *OsslCtx = @ptrCast(@alignCast(a));
            return .{ .octx = oc, .ssl_ctx = oc.ssl_ctx };
        }
        return .{ .octx = null, .ssl_ctx = null };
    }

    pub fn Curl_ossl_setup_x509_store(cf: *CurlCfilter, data: ?*CurlEasy, octx_or_ctx_raw: ?*anyopaque) callconv(.c) CURLcode {
        const resolved = resolveOsslCtxAndSslCtx(cf, octx_or_ctx_raw);
        const octx = resolved.octx;
        const ssl_ctx = resolved.ssl_ctx orelse return CURLE_SSL_CONNECT_ERROR;

        if (octx != null and octx.?.x509_store_setup()) {
            return CURLE_OK;
        }

        const store = ossl_ext.SSL_CTX_get_cert_store(ssl_ctx) orelse return CURLE_SSL_CONNECT_ERROR;
        const conn_config = vtls_impl.Curl_ssl_cf_get_filter_config(cf);
        const is_proxy = vtls_impl.Curl_ssl_cf_is_proxy(cf);

        const verifypeer = if (conn_config) |cc| cc.verifypeer() else true;
        const native_ca_store = if (conn_config) |cc| cc.native_ca_store() else false;
        const no_partialchain = if (conn_config) |cc| cc.no_partialchain() else false;

        const ca_info_blob: ?*const CurlBlob = if (conn_config != null and conn_config.?.ca_info_blob != null)
            conn_config.?.ca_info_blob
        else
            c_ext.Curl_vtls_acc_ssl_ca_info_blob(data, is_proxy);

        const ssl_cafile: ?[*:0]const u8 = if (conn_config != null and conn_config.?.CAfile != null)
            conn_config.?.CAfile
        else
            c_ext.Curl_vtls_acc_ssl_cainfo(data, is_proxy);

        const ssl_capath: ?[*:0]const u8 = if (conn_config != null and conn_config.?.CApath != null)
            conn_config.?.CApath
        else
            c_ext.Curl_vtls_acc_ssl_capath(data, is_proxy);

        const ssl_crlfile: ?[*:0]const u8 = if (conn_config != null and conn_config.?.CRLfile != null)
            conn_config.?.CRLfile
        else
            c_ext.Curl_vtls_acc_ssl_crlfile(data, is_proxy);

        var imported_ca_info_blob = false;
        var imported_ca = false;

        if (ca_info_blob) |blob| {
            if (blob.data != null and blob.len > 0) {
                const bio = ossl_ext.BIO_new_mem_buf(blob.data, @intCast(blob.len)) orelse return CURLE_OUT_OF_MEMORY;
                defer _ = ossl_ext.BIO_free(bio);

                const inf = ossl_ext.PEM_X509_INFO_read_bio(bio, null, null, null) orelse {
                    if (!verifypeer) {
                        ossl_ext.ERR_clear_error();
                    } else {
                        c_ext.Curl_failf(data, "error reading ca cert file from memory blob");
                        return CURLE_SSL_CACERT_BADFILE;
                    }
                    return CURLE_OK;
                };
                defer ossl_ext.OPENSSL_sk_pop_free(inf, &ossl_ext.X509_INFO_free);

                const count = ossl_ext.OPENSSL_sk_num(inf);
                var i: c_int = 0;
                while (i < count) : (i += 1) {
                    const it: *const X509_INFO = @ptrCast(@alignCast(ossl_ext.OPENSSL_sk_value(inf, i) orelse continue));
                    if (it.x509) |x| {
                        if (ossl_ext.X509_STORE_add_cert(store, x) == 0) {
                            if (verifypeer) {
                                c_ext.Curl_failf(data, "error adding ca cert from memory blob");
                                return CURLE_SSL_CACERT_BADFILE;
                            }
                            ossl_ext.ERR_clear_error();
                        }
                    }
                    if (it.crl) |crl| {
                        if (ossl_ext.X509_STORE_add_crl(store, crl) == 0) {
                            if (verifypeer) {
                                c_ext.Curl_failf(data, "error adding crl from memory blob");
                                return CURLE_SSL_CACERT_BADFILE;
                            }
                            ossl_ext.ERR_clear_error();
                        }
                    }
                }
                ossl_ext.ERR_clear_error();
                imported_ca_info_blob = true;
            }
        }

        const load_file: ?[*:0]const u8 = if (!imported_ca_info_blob) ssl_cafile else null;
        if (load_file != null or ssl_capath != null) {
            if (ossl_ext.SSL_CTX_load_verify_locations(ssl_ctx, load_file, ssl_capath) != 1) {
                if (verifypeer and !native_ca_store and !imported_ca_info_blob) {
                    c_ext.Curl_failf(
                        data,
                        "error setting certificate verify locations:  CAfile: %s CApath: %s",
                        load_file orelse "none",
                        ssl_capath orelse "none",
                    );
                    return CURLE_SSL_CACERT_BADFILE;
                }
                ossl_ext.ERR_clear_error();
            } else {
                imported_ca = true;
            }
        }

        if ((backend_options.ca_fallback or (load_file == null and ssl_capath == null)) and
            !imported_ca and !imported_ca_info_blob)
        {
            _ = ossl_ext.SSL_CTX_set_default_verify_paths(ssl_ctx);
        }

        if (ssl_crlfile) |crlfile| {
            if (builtin.os.tag.isDarwin() and native_ca_store) {
                c_ext.Curl_failf(data, "Darwin native CA store does not support CRLfile");
                return CURLE_NOT_BUILT_IN;
            }
            const lookup = ossl_ext.X509_STORE_add_lookup(store, ossl_ext.X509_LOOKUP_file());
            if (lookup == null or ossl_ext.X509_load_crl_file(lookup.?, crlfile, SSL_FILETYPE_PEM) == 0) {
                c_ext.Curl_failf(data, "error loading CRL file: %s", crlfile);
                return CURLE_SSL_CRL_BADFILE;
            }
            _ = ossl_ext.X509_STORE_set_flags(store, X509_V_FLAG_CRL_CHECK | X509_V_FLAG_CRL_CHECK_ALL);
        }

        if (verifypeer) {
            _ = ossl_ext.X509_STORE_set_flags(store, X509_V_FLAG_TRUSTED_FIRST);
            if (!no_partialchain) {
                _ = ossl_ext.X509_STORE_set_flags(store, X509_V_FLAG_PARTIAL_CHAIN);
            }
        }

        if (octx) |oc| {
            oc.set_store_is_empty(!imported_ca and !imported_ca_info_blob and ssl_crlfile == null);
            oc.set_x509_store_setup(true);
        }
        return CURLE_OK;
    }

    pub fn Curl_ossl_verifyhost(data: ?*CurlEasy, conn: ?*ConnectData, peer: *SslPeer, server_cert_raw: ?*anyopaque) callconv(.c) CURLcode {
        if (conn) |c| {
            if (c_ext.Curl_vtls_acc_conn_ssl_filter_config(c, false)) |cfg| {
                if (!cfg.verifyhost()) return CURLE_OK;
            }
        }
        const server_cert: *X509 = @ptrCast(@alignCast(server_cert_raw orelse return CURLE_PEER_FAILED_VERIFICATION));
        const dispname = peerDispname(peer);
        const hostname_cstr = peerHostname(peer);
        const host_len = std.mem.len(hostname_cstr);
        const host_slice = hostname_cstr[0..host_len];

        const altnames_raw = ossl_ext.X509_get_ext_d2i(server_cert, NID_subject_alt_name, null, null);
        if (altnames_raw) |raw_sk| {
            const altnames: *OPENSSL_STACK = @ptrCast(@alignCast(raw_sk));
            defer ossl_ext.GENERAL_NAMES_free(altnames);

            const numalts = ossl_ext.OPENSSL_sk_num(altnames);
            var dnsmatched = false;
            var ipmatched = false;

            var i: c_int = 0;
            while (i < numalts and !dnsmatched and !ipmatched) : (i += 1) {
                const check: *const GENERAL_NAME = @ptrCast(@alignCast(ossl_ext.OPENSSL_sk_value(altnames, i) orelse continue));
                if (check.type == GEN_DNS and peer.type == SSL_PEER_DNS) {
                    const dns_str = check.d.ia5 orelse continue;
                    const altptr = ossl_ext.ASN1_STRING_get0_data(dns_str);
                    const altlen_int = ossl_ext.ASN1_STRING_length(dns_str);
                    const altlen: usize = if (altlen_int >= 0) @intCast(altlen_int) else 0;
                    if (matchDnsNameBytes(altptr, altlen, host_slice)) {
                        dnsmatched = true;
                        c_ext.Curl_infof(data, "  subjectAltName: host \"%s\" matched cert's \"%s\"", dispname, altptr.?);
                    }
                } else if (check.type == GEN_IPADD and peer.type != SSL_PEER_DNS) {
                    const ip_str = check.d.ip orelse continue;
                    const altptr = ossl_ext.ASN1_STRING_get0_data(ip_str);
                    const altlen_int = ossl_ext.ASN1_STRING_length(ip_str);
                    const altlen: usize = if (altlen_int >= 0) @intCast(altlen_int) else 0;
                    if (matchIpSanBytes(altptr, altlen, peer.type, hostname_cstr)) {
                        ipmatched = true;
                        c_ext.Curl_infof(data, "  subjectAltName: host \"%s\" matched cert's IP address!", dispname);
                    }
                }
            }

            if (!dnsmatched and !ipmatched) {
                c_ext.Curl_failf(data, "SSL: no alternative certificate subject name matches target host name '%s'", dispname);
                return CURLE_PEER_FAILED_VERIFICATION;
            }
            return CURLE_OK;
        }

        if (peer.type != SSL_PEER_DNS) {
            c_ext.Curl_failf(data, "SSL: no alternative certificate subject name matches target IP address '%s'", dispname);
            return CURLE_PEER_FAILED_VERIFICATION;
        }

        var peer_cn: ?[*:0]u8 = null;
        var cn_size: c_int = -1;
        if (ossl_ext.X509_get_subject_name(server_cert)) |name| {
            var i: c_int = -1;
            var j: c_int = -1;
            while (true) {
                j = i;
                i = ossl_ext.X509_NAME_get_index_by_NID(name, NID_commonName, i);
                if (i < 0) break;
            }
            if (j >= 0) {
                if (ossl_ext.X509_NAME_get_entry(name, j)) |entry| {
                    if (ossl_ext.X509_NAME_ENTRY_get_data(entry)) |tmp| {
                        cn_size = ossl_ext.ASN1_STRING_to_UTF8(&peer_cn, tmp);
                    }
                }
            }
        }
        defer if (peer_cn) |cn| ossl_ext.CRYPTO_free(cn, "", 0);

        if (peer_cn == null or cn_size < 0) {
            if (cn_size == 0) {
                c_ext.Curl_failf(data, "SSL: unable to obtain common name from peer certificate");
                return CURLE_PEER_FAILED_VERIFICATION;
            }
            c_ext.Curl_failf(data, "SSL: unable to obtain common name from peer certificate");
            return CURLE_PEER_FAILED_VERIFICATION;
        }

        const cn_ptr = peer_cn.?;
        const cn_len: usize = @intCast(cn_size);
        if (cn_len != std.mem.len(cn_ptr) or std.mem.indexOfScalar(u8, cn_ptr[0..cn_len], 0) != null) {
            c_ext.Curl_failf(data, "SSL: illegal cert name field");
            return CURLE_PEER_FAILED_VERIFICATION;
        }

        if (!matchDnsNameBytes(cn_ptr, cn_len, host_slice)) {
            c_ext.Curl_failf(data, "SSL: certificate subject name '%s' does not match target host name '%s'", cn_ptr, dispname);
            return CURLE_PEER_FAILED_VERIFICATION;
        }

        c_ext.Curl_infof(data, "  common name: %s (matched)", cn_ptr);
        return CURLE_OK;
    }

    fn pushCertinfo(data: ?*CurlEasy, mem_bio: *BIO, label: [*:0]const u8, num: c_int) CURLcode {
        var ptr: ?[*]const u8 = null;
        const len = ossl_ext.BIO_ctrl(mem_bio, BIO_CTRL_INFO, 0, @ptrCast(&ptr));
        const res = if (ptr != null and len >= 0)
            vtls_impl.Curl_ssl_push_certinfo_len(data, num, label, ptr.?, @intCast(len))
        else
            CURLE_OK;
        _ = ossl_ext.BIO_ctrl(mem_bio, BIO_CTRL_RESET, 0, null);
        return res;
    }

    fn pubkeyShow(data: ?*CurlEasy, mem_bio: *BIO, num: c_int, key_type: [*:0]const u8, name: [*:0]const u8, bn: ?*const BIGNUM) CURLcode {
        var namebuf: [32]u8 = @splat(0);
        _ = c_ext.curl_msnprintf(&namebuf, namebuf.len, "%s(%s)", key_type, name);
        if (bn) |b| {
            _ = ossl_ext.BN_print(mem_bio, b);
        }
        return pushCertinfo(data, mem_bio, @ptrCast(&namebuf), num);
    }

    fn dumpX509V3Ext(data: ?*CurlEasy, certnum: c_int, exts_opt: ?*const OPENSSL_STACK) CURLcode {
        const exts = exts_opt orelse return CURLE_OK;
        const count = ossl_ext.OPENSSL_sk_num(exts);
        if (count <= 0) return CURLE_OK;

        var i: c_int = 0;
        while (i < count) : (i += 1) {
            const ext: *X509_EXTENSION = @ptrCast(@alignCast(ossl_ext.OPENSSL_sk_value(exts, i) orelse continue));
            const bio_out = ossl_ext.BIO_new(ossl_ext.BIO_s_mem()) orelse return CURLE_OUT_OF_MEMORY;
            defer _ = ossl_ext.BIO_free(bio_out);

            var namebuf: [128]u8 = @splat(0);
            if (ossl_ext.X509_EXTENSION_get_object(ext)) |obj| {
                const n = ossl_ext.i2t_ASN1_OBJECT(&namebuf, @intCast(namebuf.len), obj);
                if (n >= @as(c_int, @intCast(namebuf.len))) {
                    namebuf[namebuf.len - 1] = 0;
                }
            }

            if (ossl_ext.X509V3_EXT_print(bio_out, ext, 0, 0) == 0) {
                if (ossl_ext.X509_EXTENSION_get_data(ext)) |ext_data| {
                    _ = ossl_ext.ASN1_STRING_print(bio_out, ext_data);
                }
            }

            var ptr: ?[*]const u8 = null;
            const len = ossl_ext.BIO_ctrl(bio_out, BIO_CTRL_INFO, 0, @ptrCast(&ptr));
            if (ptr != null and len >= 0) {
                const rc = vtls_impl.Curl_ssl_push_certinfo_len(data, certnum, @ptrCast(&namebuf), ptr.?, @intCast(len));
                if (rc != CURLE_OK) return rc;
            }
        }
        return CURLE_OK;
    }

    fn getPkeyRsa(data: ?*CurlEasy, pubkey: *EVP_PKEY, mem_bio: *BIO, i: c_int) CURLcode {
        var n: ?*BIGNUM = null;
        var e: ?*BIGNUM = null;
        defer ossl_ext.BN_clear_free(n);
        defer ossl_ext.BN_clear_free(e);

        _ = ossl_ext.EVP_PKEY_get_bn_param(pubkey, "n", &n);
        _ = ossl_ext.EVP_PKEY_get_bn_param(pubkey, "e", &e);
        const bits: c_int = if (n) |bn_n| ossl_ext.BN_num_bits(bn_n) else 0;
        _ = ossl_ext.BIO_printf(mem_bio, "%d", bits);
        var result = pushCertinfo(data, mem_bio, "RSA Public Key", i);
        if (result == CURLE_OK) {
            result = pubkeyShow(data, mem_bio, i, "rsa", "n", n);
            if (result == CURLE_OK) {
                result = pubkeyShow(data, mem_bio, i, "rsa", "e", e);
            }
        }
        return result;
    }

    fn getPkeyDsaOrDh(data: ?*CurlEasy, pubkey: *EVP_PKEY, mem_bio: *BIO, i: c_int, label: [*:0]const u8) CURLcode {
        var p: ?*BIGNUM = null;
        var q: ?*BIGNUM = null;
        var g: ?*BIGNUM = null;
        var pub_key: ?*BIGNUM = null;
        defer ossl_ext.BN_clear_free(p);
        defer ossl_ext.BN_clear_free(q);
        defer ossl_ext.BN_clear_free(g);
        defer ossl_ext.BN_clear_free(pub_key);

        _ = ossl_ext.EVP_PKEY_get_bn_param(pubkey, "p", &p);
        _ = ossl_ext.EVP_PKEY_get_bn_param(pubkey, "q", &q);
        _ = ossl_ext.EVP_PKEY_get_bn_param(pubkey, "g", &g);
        _ = ossl_ext.EVP_PKEY_get_bn_param(pubkey, "pub", &pub_key);

        var result = pubkeyShow(data, mem_bio, i, label, "p", p);
        if (result == CURLE_OK) result = pubkeyShow(data, mem_bio, i, label, "q", q);
        if (result == CURLE_OK) result = pubkeyShow(data, mem_bio, i, label, "g", g);
        if (result == CURLE_OK) result = pubkeyShow(data, mem_bio, i, label, "pub_key", pub_key);
        return result;
    }

    pub fn Curl_ossl_certchain(data: ?*CurlEasy, ssl_raw: ?*anyopaque) callconv(.c) CURLcode {
        const ssl: *SSL = @ptrCast(@alignCast(ssl_raw orelse return CURLE_SSL_CONNECT_ERROR));
        const sk = ossl_ext.SSL_get_peer_cert_chain(ssl) orelse return CURLE_SSL_CONNECT_ERROR;
        const numcerts = ossl_ext.OPENSSL_sk_num(sk);
        if (numcerts <= 0) return CURLE_SSL_CONNECT_ERROR;
        if (numcerts > MAX_ALLOWED_CERT_AMOUNT) {
            c_ext.Curl_failf(data, "%d certificates is more than allowed (%d)", numcerts, MAX_ALLOWED_CERT_AMOUNT);
            return CURLE_SSL_CONNECT_ERROR;
        }

        var result = vtls_impl.Curl_ssl_init_certinfo(data, numcerts);
        if (result != CURLE_OK) return result;

        const mem_bio = ossl_ext.BIO_new(ossl_ext.BIO_s_mem()) orelse {
            vtls_impl.Curl_ssl_free_certinfo(data);
            return CURLE_OUT_OF_MEMORY;
        };
        defer _ = ossl_ext.BIO_free(mem_bio);

        var i: c_int = 0;
        while (result == CURLE_OK and i < numcerts) : (i += 1) {
            const x: *X509 = @ptrCast(@alignCast(ossl_ext.OPENSSL_sk_value(sk, i) orelse continue));

            if (ossl_ext.X509_get_subject_name(x)) |subj| {
                _ = ossl_ext.X509_NAME_print_ex(mem_bio, subj, 0, XN_FLAG_ONELINE);
            }
            result = pushCertinfo(data, mem_bio, "Subject", i);
            if (result != CURLE_OK) break;

            if (ossl_ext.X509_get_issuer_name(x)) |iss| {
                _ = ossl_ext.X509_NAME_print_ex(mem_bio, iss, 0, XN_FLAG_ONELINE);
            }
            result = pushCertinfo(data, mem_bio, "Issuer", i);
            if (result != CURLE_OK) break;

            _ = ossl_ext.BIO_printf(mem_bio, "%lx", @as(c_ulong, @intCast(ossl_ext.X509_get_version(x))));
            result = pushCertinfo(data, mem_bio, "Version", i);
            if (result != CURLE_OK) break;

            if (ossl_ext.X509_get_serialNumber(x)) |num| {
                const numdata = ossl_ext.ASN1_STRING_get0_data(num);
                const numlen_int = ossl_ext.ASN1_STRING_length(num);
                const numlen: usize = if (numlen_int >= 0) @intCast(numlen_int) else 0;
                if (ossl_ext.ASN1_STRING_type(num) == V_ASN1_NEG_INTEGER) {
                    _ = ossl_ext.BIO_puts(mem_bio, "-");
                }
                if (numdata) |nd| {
                    for (0..numlen) |j| {
                        _ = ossl_ext.BIO_printf(mem_bio, "%02x", @as(c_uint, nd[j]));
                    }
                }
            }
            result = pushCertinfo(data, mem_bio, "Serial Number", i);
            if (result != CURLE_OK) break;

            var psig: ?*const ASN1_BIT_STRING = null;
            var sigalg: ?*const X509_ALGOR = null;
            ossl_ext.X509_get0_signature(&psig, &sigalg, x);
            if (sigalg) |sa| {
                var sigalgoid: ?*const ASN1_OBJECT = null;
                ossl_ext.X509_ALGOR_get0(&sigalgoid, null, null, sa);
                if (sigalgoid) |oid| {
                    _ = ossl_ext.i2a_ASN1_OBJECT(mem_bio, oid);
                    result = pushCertinfo(data, mem_bio, "Signature Algorithm", i);
                    if (result != CURLE_OK) break;
                }
            }

            if (ossl_ext.X509_get_X509_PUBKEY(x)) |xpubkey| {
                var pubkeyoid: ?*ASN1_OBJECT = null;
                _ = ossl_ext.X509_PUBKEY_get0_param(&pubkeyoid, null, null, null, xpubkey);
                if (pubkeyoid) |oid| {
                    _ = ossl_ext.i2a_ASN1_OBJECT(mem_bio, oid);
                    result = pushCertinfo(data, mem_bio, "Public Key Algorithm", i);
                    if (result != CURLE_OK) break;
                }
            }

            result = dumpX509V3Ext(data, i, ossl_ext.X509_get0_extensions(x));
            if (result != CURLE_OK) break;

            if (ossl_ext.X509_get0_notBefore(x)) |nb| {
                _ = ossl_ext.ASN1_TIME_print(mem_bio, nb);
            }
            result = pushCertinfo(data, mem_bio, "Start date", i);
            if (result != CURLE_OK) break;

            if (ossl_ext.X509_get0_notAfter(x)) |na| {
                _ = ossl_ext.ASN1_TIME_print(mem_bio, na);
            }
            result = pushCertinfo(data, mem_bio, "Expire date", i);
            if (result != CURLE_OK) break;

            const pubkey = ossl_ext.X509_get_pubkey(x);
            if (pubkey == null) {
                c_ext.Curl_infof(data, "   Unable to load public key");
            } else {
                defer ossl_ext.EVP_PKEY_free(pubkey);
                switch (ossl_ext.EVP_PKEY_get_id(pubkey.?)) {
                    EVP_PKEY_RSA => result = getPkeyRsa(data, pubkey.?, mem_bio, i),
                    EVP_PKEY_DSA => result = getPkeyDsaOrDh(data, pubkey.?, mem_bio, i, "dsa"),
                    EVP_PKEY_DH => result = getPkeyDsaOrDh(data, pubkey.?, mem_bio, i, "dh"),
                    else => {},
                }
                if (result != CURLE_OK) break;
            }

            if (psig) |sig| {
                const psigdata = ossl_ext.ASN1_STRING_get0_data(sig);
                const psiglen_int = ossl_ext.ASN1_STRING_length(sig);
                const psiglen: usize = if (psiglen_int >= 0) @intCast(psiglen_int) else 0;
                if (psigdata) |sd| {
                    for (0..psiglen) |j| {
                        _ = ossl_ext.BIO_printf(mem_bio, "%02x:", @as(c_uint, sd[j]));
                    }
                }
                result = pushCertinfo(data, mem_bio, "Signature", i);
                if (result != CURLE_OK) break;
            }

            _ = ossl_ext.PEM_write_bio_X509(mem_bio, x);
            result = pushCertinfo(data, mem_bio, "Cert", i);
            if (result != CURLE_OK) break;
        }

        if (result != CURLE_OK) {
            vtls_impl.Curl_ssl_free_certinfo(data);
        }
        return result;
    }

    const OsslCertsDer = struct {
        sk: *OPENSSL_STACK,
        buf: ?[*]u8 = null,
        buf_max: usize = 0,
    };

    fn osslCertDerCb(
        cf: *CurlCfilter,
        data: ?*CurlEasy,
        cb_user_data: ?*anyopaque,
        cert_idx: usize,
        pder: *?[*]u8,
        pder_len: *usize,
    ) callconv(.c) CURLcode {
        _ = cf;
        _ = data;
        const cder: *OsslCertsDer = @ptrCast(@alignCast(cb_user_data orelse return CURLE_BAD_FUNCTION_ARGUMENT));
        pder.* = null;
        pder_len.* = 0;

        const x: *X509 = @ptrCast(@alignCast(ossl_ext.OPENSSL_sk_value(cder.sk, @intCast(cert_idx)) orelse return CURLE_BAD_FUNCTION_ARGUMENT));
        const der_len_int = ossl_ext.i2d_X509(x, null);
        if (der_len_int <= 0) return CURLE_SSL_CERTPROBLEM;
        const der_len: usize = @intCast(der_len_int);

        if (der_len > cder.buf_max) {
            if (cder.buf) |old| {
                mem.free(old);
                cder.buf = null;
                cder.buf_max = 0;
            }
            const new_buf: [*]u8 = @ptrCast(mem.calloc(1, der_len) orelse return CURLE_OUT_OF_MEMORY);
            cder.buf = new_buf;
            cder.buf_max = der_len;
        }

        var p: ?[*]u8 = cder.buf orelse return CURLE_OUT_OF_MEMORY;
        if (ossl_ext.i2d_X509(x, &p) != der_len_int) {
            return CURLE_SSL_CERTPROBLEM;
        }
        pder.* = cder.buf;
        pder_len.* = der_len;
        return CURLE_OK;
    }

    fn osslAppleVerify(cf: *CurlCfilter, data: ?*CurlEasy, octx: *OsslCtx, peer: *const SslPeer) CURLcode {
        const ssl = octx.ssl orelse return CURLE_SSL_CONNECT_ERROR;
        const conn_config = vtls_impl.Curl_ssl_cf_get_filter_config(cf) orelse return CURLE_SSL_CONNECT_ERROR;
        const sk = ossl_ext.SSL_get_peer_cert_chain(ssl) orelse return CURLE_PEER_FAILED_VERIFICATION;
        const num_certs = ossl_ext.OPENSSL_sk_num(sk);
        if (num_certs <= 0) return CURLE_PEER_FAILED_VERIFICATION;

        var cder = OsslCertsDer{ .sk = sk };
        defer if (cder.buf) |b| mem.free(b);

        var ocsp_buf: ?[*]const u8 = null;
        var ocsp_len: usize = 0;
        if (conn_config.verifystatus()) {
            const len = ossl_ext.SSL_ctrl(ssl, SSL_CTRL_GET_TLSEXT_STATUS_REQ_OCSP_RESP, 0, @ptrCast(&ocsp_buf));
            if (ocsp_buf != null and len > 0) {
                ocsp_len = @intCast(len);
            }
        }

        return ossl_ext.Curl_vtls_apple_verify(
            cf,
            data,
            peer,
            @intCast(num_certs),
            &osslCertDerCb,
            &cder,
            ocsp_buf,
            ocsp_len,
            conn_config.verifystatus(),
        );
    }

    fn osslVerifyStatus(cf: *CurlCfilter, data: ?*CurlEasy, octx: *OsslCtx) CURLcode {
        _ = cf;
        const ssl = octx.ssl orelse return CURLE_SSL_INVALIDCERTSTATUS;
        const ssl_ctx = octx.ssl_ctx orelse return CURLE_SSL_INVALIDCERTSTATUS;

        var p: ?[*]const u8 = null;
        const len = ossl_ext.SSL_ctrl(ssl, SSL_CTRL_GET_TLSEXT_STATUS_REQ_OCSP_RESP, 0, @ptrCast(&p));
        if (p == null or len <= 0) {
            c_ext.Curl_failf(data, "No OCSP response received");
            return CURLE_SSL_INVALIDCERTSTATUS;
        }

        const rsp = ossl_ext.d2i_OCSP_RESPONSE(null, &p, len) orelse {
            c_ext.Curl_failf(data, "Invalid OCSP response");
            return CURLE_SSL_INVALIDCERTSTATUS;
        };
        defer ossl_ext.OCSP_RESPONSE_free(rsp);

        const ostatus = ossl_ext.OCSP_response_status(rsp);
        if (ostatus != OCSP_RESPONSE_STATUS_SUCCESSFUL) {
            c_ext.Curl_failf(data, "Invalid OCSP response status: %s (%d)", ossl_ext.OCSP_response_status_str(ostatus), ostatus);
            return CURLE_SSL_INVALIDCERTSTATUS;
        }

        const br = ossl_ext.OCSP_response_get1_basic(rsp) orelse {
            c_ext.Curl_failf(data, "Invalid OCSP response");
            return CURLE_SSL_INVALIDCERTSTATUS;
        };
        defer ossl_ext.OCSP_BASICRESP_free(br);

        const ch = ossl_ext.SSL_get_peer_cert_chain(ssl);
        const st = ossl_ext.SSL_CTX_get_cert_store(ssl_ctx);

        if (ossl_ext.OCSP_basic_verify(br, ch, st, 0) <= 0) {
            var err_buf: [256]u8 = @splat(0);
            c_ext.Curl_failf(data, "OCSP response verification failed: %s", osslStrerror(ossl_ext.ERR_get_error(), &err_buf, err_buf.len));
            return CURLE_SSL_INVALIDCERTSTATUS;
        }

        const resp_count = ossl_ext.OCSP_resp_count(br);
        var i: c_int = 0;
        while (i < resp_count) : (i += 1) {
            const single = ossl_ext.OCSP_resp_get0(br, i) orelse continue;
            var crl_reason: c_int = -1;
            var revtime: ?*ASN1_TIME = null;
            var thisupd: ?*ASN1_TIME = null;
            var nextupd: ?*ASN1_TIME = null;

            const cert_status = ossl_ext.OCSP_single_get0_status(single, &crl_reason, &revtime, &thisupd, &nextupd);
            if (ossl_ext.OCSP_check_validity(thisupd, nextupd, 300, -1) == 0) {
                c_ext.Curl_failf(data, "OCSP response has expired");
                return CURLE_SSL_INVALIDCERTSTATUS;
            }

            c_ext.Curl_infof(data, "SSL certificate status: %s (%d)", ossl_ext.OCSP_cert_status_str(cert_status), cert_status);
            switch (cert_status) {
                V_OCSP_CERTSTATUS_GOOD => {},
                V_OCSP_CERTSTATUS_REVOKED => {
                    if (crl_reason != -1) {
                        c_ext.Curl_failf(data, "SSL certificate revocation reason: %s (%d)", ossl_ext.OCSP_crl_reason_str(crl_reason), crl_reason);
                    }
                    return CURLE_SSL_INVALIDCERTSTATUS;
                },
                else => return CURLE_SSL_INVALIDCERTSTATUS,
            }
        }
        return CURLE_OK;
    }

    fn osslCheckIssuer(cf: *CurlCfilter, data: ?*CurlEasy, server_cert: *X509) CURLcode {
        const conn_config = vtls_impl.Curl_ssl_cf_get_filter_config(cf);
        const is_proxy = vtls_impl.Curl_ssl_cf_is_proxy(cf);

        const issuer_blob: ?*const CurlBlob = if (conn_config != null and conn_config.?.issuercert_blob != null)
            conn_config.?.issuercert_blob
        else
            c_ext.Curl_vtls_acc_ssl_issuercert_blob(data, is_proxy);

        const issuer_file: ?[*:0]const u8 = if (conn_config != null and conn_config.?.issuercert != null)
            conn_config.?.issuercert
        else
            c_ext.Curl_vtls_acc_ssl_issuercert(data, is_proxy);

        if (issuer_blob == null and issuer_file == null) return CURLE_OK;

        const fp: *BIO = if (issuer_blob) |blob|
            ossl_ext.BIO_new_mem_buf(blob.data, @intCast(blob.len)) orelse return CURLE_OUT_OF_MEMORY
        else
            ossl_ext.BIO_new_file(issuer_file.?, "r") orelse {
                c_ext.Curl_failf(data, "SSL: Unable to open issuer cert (%s)", issuer_file.?);
                return CURLE_SSL_ISSUER_ERROR;
            };
        defer _ = ossl_ext.BIO_free(fp);

        const issuer = ossl_ext.PEM_read_bio_X509(fp, null, null, null) orelse {
            c_ext.Curl_failf(data, "SSL: Unable to read issuer cert (%s)", issuer_file orelse "blob");
            return CURLE_SSL_ISSUER_ERROR;
        };
        defer ossl_ext.X509_free(issuer);

        if (ossl_ext.X509_check_issued(issuer, server_cert) != X509_V_OK) {
            c_ext.Curl_failf(data, "SSL: Certificate issuer check failed (%s)", issuer_file orelse "blob");
            return CURLE_SSL_ISSUER_ERROR;
        }

        c_ext.Curl_infof(data, " SSL certificate issuer check ok (%s)", issuer_file orelse "blob");
        return CURLE_OK;
    }

    fn osslCheckPinnedKey(cf: *CurlCfilter, data: ?*CurlEasy, server_cert: *X509) CURLcode {
        const conn_config = vtls_impl.Curl_ssl_cf_get_filter_config(cf);
        const is_proxy = vtls_impl.Curl_ssl_cf_is_proxy(cf);
        const pinned_key: ?[*:0]const u8 = if (conn_config != null and conn_config.?.pinned_key != null)
            conn_config.?.pinned_key
        else
            c_ext.Curl_vtls_acc_pinned_pubkey(data, is_proxy);

        const pinned = pinned_key orelse return CURLE_OK;

        const xpubkey = ossl_ext.X509_get_X509_PUBKEY(server_cert) orelse {
            c_ext.Curl_failf(data, "SSL: failed retrieving public key from server certificate");
            return CURLE_SSL_PINNEDPUBKEYNOTMATCH;
        };
        const len_int = ossl_ext.i2d_X509_PUBKEY(xpubkey, null);
        if (len_int <= 0 or len_int > @as(c_int, @intCast(MAX_PINNED_PUBKEY_SIZE))) {
            c_ext.Curl_failf(data, "SSL: failed retrieving public key from server certificate");
            return CURLE_SSL_PINNEDPUBKEYNOTMATCH;
        }
        const len: usize = @intCast(len_int);
        const buff1_raw = mem.malloc(len) orelse return CURLE_OUT_OF_MEMORY;
        defer mem.free(buff1_raw);

        var temp: ?[*]u8 = @ptrCast(buff1_raw);
        const enc_len = ossl_ext.i2d_X509_PUBKEY(xpubkey, &temp);
        if (enc_len != len_int) {
            c_ext.Curl_failf(data, "SSL: failed retrieving public key from server certificate");
            return CURLE_SSL_PINNEDPUBKEYNOTMATCH;
        }
        return vtls_impl.Curl_pin_peer_pubkey(data, pinned, @ptrCast(buff1_raw), len);
    }

    pub fn Curl_ossl_check_peer_cert(cf: *CurlCfilter, data: ?*CurlEasy, octx: *OsslCtx, peer: *SslPeer) callconv(.c) CURLcode {
        const conn_config = vtls_impl.Curl_ssl_cf_get_filter_config(cf) orelse return CURLE_SSL_CONNECT_ERROR;
        const ssl_config = vtls_impl.Curl_ssl_cf_get_easy_config(cf, data);
        const ssl = octx.ssl orelse return CURLE_SSL_CONNECT_ERROR;

        const server_cert = ossl_ext.SSL_get1_peer_certificate(ssl) orelse {
            if (!conn_config.verifypeer() and !conn_config.verifyhost()) return CURLE_OK;
            c_ext.Curl_failf(data, "SSL: couldn't get peer certificate!");
            return CURLE_PEER_FAILED_VERIFICATION;
        };
        defer ossl_ext.X509_free(server_cert);

        var verified = false;
        if (builtin.os.tag.isDarwin()) {
            verified = octx.sectrust_session();
        }

        if (c_ext.Curl_vtls_acc_ssl_certinfo(data) and !octx.reused_session()) {
            const rc = Curl_ossl_certchain(data, ssl);
            if (rc != CURLE_OK) return rc;
        }

        if (conn_config.verifyhost()) {
            const rc = Curl_ossl_verifyhost(data, cf.conn, peer, server_cert);
            if (rc != CURLE_OK) return rc;
        }

        var result: CURLcode = CURLE_OK;
        var ossl_verify: c_long = 0;

        if (!verified and !octx.store_is_empty()) {
            ossl_verify = ossl_ext.SSL_get_verify_result(ssl);
            if (ssl_config) |sc| {
                sc.certverifyresult = ossl_verify;
            }
            if (ossl_verify == X509_V_OK) {
                verified = true;
                c_ext.Curl_infof(data, " SSL certificate verify ok.");
            }
        }

        if (builtin.os.tag.isDarwin()) {
            if (conn_config.verifypeer() and conn_config.native_ca_store() and !verified) {
                result = osslAppleVerify(cf, data, octx, peer);
                if (result != CURLE_OK) return result;
                octx.set_sectrust_verified(true);
                verified = true;
            }
        }

        if (!verified) {
            if (ossl_verify == X509_V_OK) {
                ossl_verify = ossl_ext.SSL_get_verify_result(ssl);
                if (ssl_config) |sc| {
                    sc.certverifyresult = ossl_verify;
                }
            }
            const reason = ossl_ext.X509_verify_cert_error_string(ossl_verify);
            if (conn_config.verifypeer()) {
                c_ext.Curl_failf(data, "SSL certificate problem: %s", reason);
                return CURLE_PEER_FAILED_VERIFICATION;
            } else {
                c_ext.Curl_infof(data, " SSL certificate verify result: %s (%ld), continuing anyway.", reason, ossl_verify);
            }
        }

        if (conn_config.verifystatus() and !octx.reused_session()) {
            const apple_verified_ocsp = if (builtin.os.tag.isDarwin())
                (octx.sectrust_verified() and ossl_ext.Curl_vtls_apple_verifies_ocsp(cf, data))
            else
                false;
            if (!apple_verified_ocsp) {
                result = osslVerifyStatus(cf, data, octx);
                if (result != CURLE_OK) return result;
            }
        }

        result = osslCheckIssuer(cf, data, server_cert);
        if (result != CURLE_OK) return result;

        result = osslCheckPinnedKey(cf, data, server_cert);
        if (result != CURLE_OK) return result;

        return CURLE_OK;
    }

    fn useCertificateBlob(ctx: *SSL_CTX, blob: *const CurlBlob, file_type: c_int, key_passwd: ?[*:0]const u8) c_int {
        const in = ossl_ext.BIO_new_mem_buf(blob.data, @intCast(blob.len)) orelse return 0;
        defer _ = ossl_ext.BIO_free(in);

        const x: ?*X509 = switch (file_type) {
            SSL_FILETYPE_ASN1 => ossl_ext.d2i_X509_bio(in, null),
            SSL_FILETYPE_PEM => ossl_ext.PEM_read_bio_X509(in, null, &passwdCallback, @ptrCast(@constCast(key_passwd))),
            else => null,
        };
        const cert = x orelse return 0;
        defer ossl_ext.X509_free(cert);
        return ossl_ext.SSL_CTX_use_certificate(ctx, cert);
    }

    fn usePrivateKeyBlob(ctx: *SSL_CTX, blob: *const CurlBlob, file_type: c_int, key_passwd: ?[*:0]const u8) c_int {
        const in = ossl_ext.BIO_new_mem_buf(blob.data, @intCast(blob.len)) orelse return 0;
        defer _ = ossl_ext.BIO_free(in);

        const pkey: ?*EVP_PKEY = switch (file_type) {
            SSL_FILETYPE_PEM => ossl_ext.PEM_read_bio_PrivateKey(in, null, &passwdCallback, @ptrCast(@constCast(key_passwd))),
            SSL_FILETYPE_ASN1 => ossl_ext.d2i_PrivateKey_bio(in, null),
            else => null,
        };
        const pk = pkey orelse return 0;
        defer ossl_ext.EVP_PKEY_free(pk);
        return ossl_ext.SSL_CTX_use_PrivateKey(ctx, pk);
    }

    fn useCertificateChainBlob(ctx: *SSL_CTX, blob: *const CurlBlob, key_passwd: ?[*:0]const u8) c_int {
        const in = ossl_ext.BIO_new_mem_buf(blob.data, @intCast(blob.len)) orelse return 0;
        defer _ = ossl_ext.BIO_free(in);

        ossl_ext.ERR_clear_error();
        const x = ossl_ext.PEM_read_bio_X509_AUX(in, null, &passwdCallback, @ptrCast(@constCast(key_passwd))) orelse return 0;
        defer ossl_ext.X509_free(x);

        var ret = ossl_ext.SSL_CTX_use_certificate(ctx, x);
        if (ossl_ext.ERR_peek_error() != 0) ret = 0;

        if (ret != 0) {
            if (ossl_ext.SSL_CTX_ctrl(ctx, SSL_CTRL_CLEAR_CHAIN_CERTS, 0, null) == 0) {
                return 0;
            }
            while (ossl_ext.PEM_read_bio_X509(in, null, &passwdCallback, @ptrCast(@constCast(key_passwd)))) |ca| {
                if (ossl_ext.SSL_CTX_ctrl(ctx, SSL_CTRL_CHAIN_CERT, 0, ca) == 0) {
                    ossl_ext.X509_free(ca);
                    return 0;
                }
            }
            const err = ossl_ext.ERR_peek_last_error();
            const lib_id = (err >> 23) & 0xFF;
            const reason = err & 0x7FFFFF;
            if ((lib_id == ERR_LIB_PEM or ((err >> 24) & 0xFF) == ERR_LIB_PEM) and reason == PEM_R_NO_START_LINE) {
                ossl_ext.ERR_clear_error();
            } else if (err != 0) {
                ossl_ext.ERR_clear_error();
            }
        }
        return ret;
    }

    fn configureClientCertAndKey(
        cf: *CurlCfilter,
        data: ?*CurlEasy,
        ctx: *SSL_CTX,
        conn_config: *const SslFilterConfig,
    ) CURLcode {
        const is_proxy = vtls_impl.Curl_ssl_cf_is_proxy(cf);
        const cert_file: ?[*:0]const u8 = if (conn_config.clientcert) |p| p else c_ext.Curl_vtls_acc_ssl_cert(data, is_proxy);
        const cert_blob: ?*const CurlBlob = if (conn_config.cert_blob) |b| b else c_ext.Curl_vtls_acc_ssl_cert_blob(data, is_proxy);
        const cert_type_str: ?[*:0]const u8 = if (conn_config.cert_type) |t| t else c_ext.Curl_vtls_acc_ssl_cert_type(data, is_proxy);
        var key_file: ?[*:0]const u8 = if (conn_config.key) |k| k else c_ext.Curl_vtls_acc_ssl_key(data, is_proxy);
        var key_blob: ?*const CurlBlob = conn_config.key_blob;
        const key_type_str: ?[*:0]const u8 = if (conn_config.key_type) |kt| kt else c_ext.Curl_vtls_acc_ssl_key_type(data, is_proxy);
        const key_passwd: ?[*:0]const u8 = if (conn_config.key_passwd) |kp| kp else c_ext.Curl_vtls_acc_ssl_key_passwd(data, is_proxy);

        if (cert_file == null and cert_blob == null and key_file == null and key_blob == null) {
            return CURLE_OK;
        }

        if (key_passwd) |pw| {
            ossl_ext.SSL_CTX_set_default_passwd_cb_userdata(ctx, @ptrCast(@constCast(pw)));
            ossl_ext.SSL_CTX_set_default_passwd_cb(ctx, &passwdCallback);
        }

        const cert_file_type = osslDoFileType(cert_type_str);
        if (cert_file != null or cert_blob != null) {
            switch (cert_file_type) {
                SSL_FILETYPE_PEM => {
                    const ok = if (cert_blob) |cb|
                        useCertificateChainBlob(ctx, cb, key_passwd) == 1
                    else
                        ossl_ext.SSL_CTX_use_certificate_chain_file(ctx, cert_file.?) == 1;
                    if (!ok) {
                        var err_buf: [256]u8 = @splat(0);
                        c_ext.Curl_failf(data, "could not load PEM client certificate: %s", osslStrerror(ossl_ext.ERR_get_error(), &err_buf, err_buf.len));
                        return CURLE_SSL_CERTPROBLEM;
                    }
                },
                SSL_FILETYPE_ASN1 => {
                    const ok = if (cert_blob) |cb|
                        useCertificateBlob(ctx, cb, cert_file_type, key_passwd) == 1
                    else
                        ossl_ext.SSL_CTX_use_certificate_file(ctx, cert_file.?, cert_file_type) == 1;
                    if (!ok) {
                        var err_buf: [256]u8 = @splat(0);
                        c_ext.Curl_failf(data, "could not load ASN1 client certificate: %s", osslStrerror(ossl_ext.ERR_get_error(), &err_buf, err_buf.len));
                        return CURLE_SSL_CERTPROBLEM;
                    }
                },
                else => {
                    c_ext.Curl_failf(data, "not supported file type '%s' for certificate", cert_type_str orelse "");
                    return CURLE_SSL_CERTPROBLEM;
                },
            }
        }

        if (key_file == null and key_blob == null and cert_file_type != SSL_FILETYPE_PKCS12) {
            key_file = cert_file;
            key_blob = cert_blob;
        }

        if (key_file != null or key_blob != null) {
            const key_file_type = osslDoFileType(key_type_str);
            switch (key_file_type) {
                SSL_FILETYPE_PEM, SSL_FILETYPE_ASN1 => {
                    const ok = if (key_blob) |kb|
                        usePrivateKeyBlob(ctx, kb, key_file_type, key_passwd) == 1
                    else
                        ossl_ext.SSL_CTX_use_PrivateKey_file(ctx, key_file.?, key_file_type) == 1;
                    if (!ok) {
                        var err_buf: [256]u8 = @splat(0);
                        c_ext.Curl_failf(data, "unable to set private key: %s", osslStrerror(ossl_ext.ERR_get_error(), &err_buf, err_buf.len));
                        return CURLE_SSL_CERTPROBLEM;
                    }
                },
                else => {
                    c_ext.Curl_failf(data, "not supported file type for private key");
                    return CURLE_SSL_CERTPROBLEM;
                },
            }

            if (ossl_ext.SSL_CTX_check_private_key(ctx) == 0) {
                c_ext.Curl_failf(data, "Private key does not match the certificate public key");
                return CURLE_SSL_CERTPROBLEM;
            }
        }
        return CURLE_OK;
    }

    pub fn Curl_ossl_add_session(
        cf: *CurlCfilter,
        data: ?*CurlEasy,
        octx: *OsslCtx,
        ssl_peer_key: ?[*:0]const u8,
        session: *SSL_SESSION,
        alpn: ?[*:0]const u8,
        quic_tp: ?[*]u8,
        quic_tp_len: usize,
        psession: ?*?*CurlSslSession,
    ) callconv(.c) CURLcode {
        if (psession) |ps| ps.* = null;
        const conn_config = vtls_impl.Curl_ssl_cf_get_filter_config(cf) orelse return CURLE_OK;
        if (!conn_config.primary_cache_session()) return CURLE_OK;
        const peer_key = ssl_peer_key orelse return CURLE_OK;

        const sess_len = ossl_ext.i2d_SSL_SESSION(session, null);
        if (sess_len <= 0) return CURLE_OUT_OF_MEMORY;
        const sess_buf_raw = mem.malloc(@intCast(sess_len)) orelse return CURLE_OUT_OF_MEMORY;
        var sess_ptr: ?[*]u8 = @ptrCast(sess_buf_raw);
        const enc_len = ossl_ext.i2d_SSL_SESSION(session, &sess_ptr);
        if (enc_len <= 0 or enc_len > sess_len) {
            mem.secureZero(sess_buf_raw, @intCast(sess_len));
            mem.freeSized(sess_buf_raw, @intCast(sess_len));
            return CURLE_OUT_OF_MEMORY;
        }

        var qtp_clone: ?[*]u8 = null;
        if (quic_tp != null and quic_tp_len > 0) {
            const qtp_raw = mem.malloc(quic_tp_len + 1) orelse {
                mem.secureZero(sess_buf_raw, @intCast(sess_len));
                mem.freeSized(sess_buf_raw, @intCast(sess_len));
                return CURLE_OUT_OF_MEMORY;
            };
            const qtp_bytes: [*]u8 = @ptrCast(qtp_raw);
            @memcpy(qtp_bytes[0..quic_tp_len], quic_tp.?[0..quic_tp_len]);
            qtp_bytes[quic_tp_len] = 0;
            qtp_clone = qtp_bytes;
        }

        const timeout = ossl_ext.SSL_SESSION_get_timeout(session);
        const valid_until = if (timeout > 0) c_ext.Curl_pgrs_now(data).tv_sec + @as(i64, @intCast(timeout)) else 0;
        const ietf_tls_id = if (octx.ssl) |s| ossl_ext.SSL_version(s) else TLS1_3_VERSION;
        const earlydata_max: usize = ossl_ext.SSL_SESSION_get_max_early_data(session);

        var sc_session: ?*CurlSslSession = null;
        const res = vtls_scache_asn1.Curl_ssl_session_create2(
            @ptrCast(sess_buf_raw),
            @intCast(enc_len),
            @intCast(ietf_tls_id),
            alpn,
            valid_until,
            earlydata_max,
            qtp_clone,
            quic_tp_len,
            &sc_session,
        );
        if (res != CURLE_OK or sc_session == null) return res;
        if (builtin.os.tag.isDarwin() and octx.sectrust_verified()) {
            sc_session.?.setSectrustVerified(true);
        }

        var scache: ?*CurlSslScache = null;
        var has_share_scache = false;
        var trc_feat: ?*CurlTrcFeat = null;
        c_ext.Curl_vtls_acc_scache_params(data, &scache, &has_share_scache, &trc_feat);
        return vtls_scache_asn1.Curl_ssl_scache_put_zig(
            cf,
            data,
            scache,
            has_share_scache,
            @ptrCast(conn_config),
            trc_feat,
            peer_key,
            sc_session.?,
        );
    }

    pub fn Curl_ossl_report_handshake(data: ?*CurlEasy, octx: *OsslCtx) callconv(.c) void {
        const ssl = octx.ssl orelse return;
        var psigtype_nid: c_int = NID_undef;
        _ = ossl_ext.SSL_get_peer_signature_type_nid(ssl, &psigtype_nid);
        const group_nid: c_int = @intCast(ossl_ext.SSL_ctrl(ssl, SSL_CTRL_GET_NEGOTIATED_GROUP, 0, null) & 0x0000FFFF);
        const negotiated_group_name = ossl_ext.OBJ_nid2sn(group_nid) orelse "[blank]";
        const ver_str = ossl_ext.SSL_get_version(ssl) orelse "unknown";
        const cipher_str = ossl_ext.SSL_CIPHER_get_name(ossl_ext.SSL_get_current_cipher(ssl)) orelse "unknown";
        const sig_str = ossl_ext.OBJ_nid2sn(psigtype_nid) orelse "unknown";
        c_ext.Curl_infof(
            data,
            "SSL connection using %s / %s / %s / %s",
            ver_str,
            cipher_str,
            negotiated_group_name,
            sig_str,
        );
    }

    pub fn Curl_ossl_ctx_init(
        octx: *OsslCtx,
        cf: *CurlCfilter,
        data: ?*CurlEasy,
        peer: *SslPeer,
        alpns_requested: ?*const AlpnSpec,
        cb_setup: ?OsslCtxSetupCb,
        cb_user_data: ?*anyopaque,
        cb_new_session: ?NewSessionCb,
        ssl_user_data: ?*anyopaque,
        sess_reuse_cb: ?OsslInitSessionReuseCb,
    ) callconv(.c) CURLcode {
        const conn_config = vtls_impl.Curl_ssl_cf_get_filter_config(cf) orelse return CURLE_SSL_CONNECT_ERROR;
        const ssl_config = vtls_impl.Curl_ssl_cf_get_easy_config(cf, data);
        const is_proxy = vtls_impl.Curl_ssl_cf_is_proxy(cf);

        if (ossl_ext.RAND_status() == 0) {
            c_ext.Curl_failf(data, "Insufficient randomness");
            return CURLE_SSL_CONNECT_ERROR;
        }

        if (c_ext.Curl_vtls_acc_ssl_engine(data)) |eng_name| {
            const prov_rc = osslSetProvider(data, octx, eng_name);
            if (prov_rc != CURLE_OK) return prov_rc;
        }

        if (ssl_config) |sc| {
            sc.certverifyresult = 1;
        }

        var ssl_version_min: u8 = conn_config.version;
        var req_method: ?*const SSL_METHOD = null;
        if (peer.transport == TRNSPRT_QUIC) {
            ssl_version_min = CURL_SSLVERSION_TLSv1_3;
            if (conn_config.version_max != 0 and
                conn_config.version_max != CURL_SSLVERSION_MAX_DEFAULT and
                conn_config.version_max != CURL_SSLVERSION_MAX_TLSv1_3)
            {
                c_ext.Curl_failf(data, "QUIC needs at least TLS version 1.3");
                return CURLE_SSL_CONNECT_ERROR;
            }
            req_method = ossl_ext.TLS_method();
        } else if (peer.transport == TRNSPRT_TCP) {
            switch (ssl_version_min) {
                CURL_SSLVERSION_DEFAULT,
                CURL_SSLVERSION_TLSv1,
                CURL_SSLVERSION_TLSv1_0,
                CURL_SSLVERSION_TLSv1_1,
                CURL_SSLVERSION_TLSv1_2,
                CURL_SSLVERSION_TLSv1_3,
                => req_method = ossl_ext.TLS_client_method(),
                CURL_SSLVERSION_SSLv2 => {
                    c_ext.Curl_failf(data, "No SSLv2 support");
                    return CURLE_NOT_BUILT_IN;
                },
                CURL_SSLVERSION_SSLv3 => {
                    c_ext.Curl_failf(data, "No SSLv3 support");
                    return CURLE_NOT_BUILT_IN;
                },
                else => {
                    c_ext.Curl_failf(data, "Unrecognized parameter passed via CURLOPT_SSLVERSION");
                    return CURLE_SSL_CONNECT_ERROR;
                },
            }
        } else {
            c_ext.Curl_failf(data, "unsupported transport %d in SSL init", @as(c_int, peer.transport));
            return CURLE_SSL_CONNECT_ERROR;
        }
        const method = req_method orelse return CURLE_SSL_CONNECT_ERROR;

        if (octx.ssl_ctx) |old| ossl_ext.SSL_CTX_free(old);
        octx.set_x509_store_setup(false);
        octx.ssl_ctx = if (octx.p.libctx != null)
            ossl_ext.SSL_CTX_new_ex(octx.p.libctx, octx.p.propq, method)
        else
            ossl_ext.SSL_CTX_new(method);
        const ssl_ctx = octx.ssl_ctx orelse return CURLE_OUT_OF_MEMORY;

        if (cb_setup) |setup_fn| {
            const rc = setup_fn(cf, data, cb_user_data);
            if (rc != CURLE_OK) return rc;
        }

        const ver_range = mapTlsVersionMinMax(ssl_version_min, conn_config.version_max) orelse {
            c_ext.Curl_failf(data, "OpenSSL: unsupported SSL version range");
            return CURLE_NOT_BUILT_IN;
        };

        var ctx_options: u64 = SSL_OP_ALL | SSL_OP_NO_TICKET | SSL_OP_NO_COMPRESSION | SSL_OP_NO_SSLv3;
        ctx_options &= ~SSL_OP_NETSCAPE_REUSE_CIPHER_CHANGE_BUG;
        if (!conn_config.enable_beast()) {
            ctx_options &= ~SSL_OP_DONT_INSERT_EMPTY_FRAGMENTS;
        }
        _ = ossl_ext.SSL_CTX_set_options(ssl_ctx, ctx_options);
        _ = ossl_ext.SSL_CTX_ctrl(ssl_ctx, SSL_CTRL_SET_READ_AHEAD, 1, null);
        _ = ossl_ext.SSL_CTX_ctrl(ssl_ctx, SSL_CTRL_MODE, SSL_MODE_ACCEPT_MOVING_WRITE_BUFFER, null);

        if (ossl_ext.SSL_CTX_ctrl(ssl_ctx, SSL_CTRL_SET_MIN_PROTO_VERSION, ver_range.min_ver, null) == 0) {
            return CURLE_SSL_CONNECT_ERROR;
        }
        if (ver_range.max_ver != 0) {
            if (ossl_ext.SSL_CTX_ctrl(ssl_ctx, SSL_CTRL_SET_MAX_PROTO_VERSION, ver_range.max_ver, null) == 0) {
                return CURLE_SSL_CONNECT_ERROR;
            }
        }

        if (ssl_version_min < CURL_SSLVERSION_TLSv1_3) {
            const ciphers: ?[*:0]const u8 = if (conn_config.cipher_list) |c| c else if (peer.transport != TRNSPRT_QUIC) c_ext.Curl_vtls_acc_ssl_cipher_list(data, is_proxy) else null;
            if (ciphers) |c_str| {
                if (ossl_ext.SSL_CTX_set_cipher_list(ssl_ctx, c_str) == 0) {
                    c_ext.Curl_failf(data, "failed setting cipher list: %s", c_str);
                    return CURLE_SSL_CIPHER;
                }
            }
        }

        const ciphers13: ?[*:0]const u8 = if (conn_config.cipher_list13) |c| c else c_ext.Curl_vtls_acc_ssl_cipher13_list(data, is_proxy);
        if (ciphers13) |c13_str| {
            if (ossl_ext.SSL_CTX_set_ciphersuites(ssl_ctx, c13_str) == 0) {
                c_ext.Curl_failf(data, "failed setting TLS 1.3 cipher suite: %s", c13_str);
                return CURLE_SSL_CIPHER;
            }
        }

        const cert_rc = configureClientCertAndKey(cf, data, ssl_ctx, conn_config);
        if (cert_rc != CURLE_OK) return cert_rc;

        ossl_ext.SSL_CTX_set_post_handshake_auth(ssl_ctx, 1);

        const curves: ?[*:0]const u8 = if (conn_config.curves) |c| c else c_ext.Curl_vtls_acc_ssl_ec_curves(data);
        if (curves) |curves_str| {
            if (ossl_ext.SSL_CTX_ctrl(ssl_ctx, SSL_CTRL_SET_GROUPS_LIST, 0, @ptrCast(@constCast(curves_str))) == 0) {
                c_ext.Curl_failf(data, "failed setting curves list: '%s'", curves_str);
                return CURLE_SSL_CIPHER;
            }
        }

        const sigalgs: ?[*:0]const u8 = if (conn_config.signature_algorithms) |s| s else c_ext.Curl_vtls_acc_ssl_signature_algorithms(data);
        if (sigalgs) |sigalgs_str| {
            if (ossl_ext.SSL_CTX_ctrl(ssl_ctx, SSL_CTRL_SET_SIGALGS_LIST, 0, @ptrCast(@constCast(sigalgs_str))) == 0) {
                c_ext.Curl_failf(data, "failed setting signature algorithms list: '%s'", sigalgs_str);
                return CURLE_SSL_CIPHER;
            }
        }

        ossl_ext.SSL_CTX_set_verify(ssl_ctx, SSL_VERIFY_NONE, null);

        vtls_core.Curl_tls_keylog_open();
        if (vtls_core.Curl_tls_keylog_enabled()) {
            ossl_ext.SSL_CTX_set_keylog_callback(ssl_ctx, &osslKeylogCallback);
        }

        if (cb_new_session) |new_sess_fn| {
            _ = ossl_ext.SSL_CTX_ctrl(ssl_ctx, SSL_CTRL_SET_SESS_CACHE_MODE, SSL_SESS_CACHE_CLIENT | SSL_SESS_CACHE_NO_INTERNAL, null);
            ossl_ext.SSL_CTX_sess_set_new_cb(ssl_ctx, new_sess_fn);
        }

        var fsslctx: ?*const anyopaque = null;
        var fsslctxp: ?*anyopaque = null;
        if (c_ext.Curl_vtls_acc_ssl_fsslctx(data, &fsslctx, &fsslctxp)) {
            if (!octx.x509_store_setup()) {
                const store_rc = Curl_ossl_setup_x509_store(cf, data, octx);
                if (store_rc != CURLE_OK) return store_rc;
                octx.set_x509_store_setup(true);
            }
            const cb: *const fn (?*CurlEasy, ?*anyopaque, ?*anyopaque) callconv(.c) CURLcode = @ptrCast(@alignCast(fsslctx.?));
            const rc = cb(data, ssl_ctx, fsslctxp);
            if (rc != CURLE_OK) {
                c_ext.Curl_failf(data, "error signaled by ssl ctx callback");
                return rc;
            }
        }

        if (octx.ssl) |old| ossl_ext.SSL_free(old);
        const ssl = ossl_ext.SSL_new(ssl_ctx) orelse return CURLE_OUT_OF_MEMORY;
        octx.ssl = ssl;
        _ = ossl_ext.SSL_set_ex_data(ssl, 0, ssl_user_data);
        if (conn_config.verifystatus()) {
            _ = ossl_ext.SSL_ctrl(ssl, SSL_CTRL_SET_TLSEXT_STATUS_REQ_TYPE, TLSEXT_STATUSTYPE_ocsp, null);
        }
        ossl_ext.SSL_set_connect_state(ssl);

        if (peer.sni) |sni| {
            if (ossl_ext.SSL_ctrl(ssl, SSL_CTRL_SET_TLSEXT_HOSTNAME, TLSEXT_NAMETYPE_host_name, @ptrCast(@constCast(sni))) == 0) {
                c_ext.Curl_failf(data, "Failed set SNI");
                return CURLE_SSL_CONNECT_ERROR;
            }
        }

        var alpns: AlpnSpec = undefined;
        vtls_impl.Curl_alpn_copy(&alpns, alpns_requested);
        octx.set_reused_session(false);

        if (conn_config.primary_cache_session() and !conn_config.verifystatus()) {
            if (peer.scache_key) |peer_key| {
                var scache: ?*CurlSslScache = null;
                var has_share_scache = false;
                var trc_feat: ?*CurlTrcFeat = null;
                c_ext.Curl_vtls_acc_scache_params(data, &scache, &has_share_scache, &trc_feat);
                var sc_session: ?*CurlSslSession = null;
                _ = vtls_scache_asn1.Curl_ssl_scache_take_zig(
                    cf,
                    data,
                    scache,
                    has_share_scache,
                    @ptrCast(conn_config),
                    trc_feat,
                    peer_key,
                    &sc_session,
                );
                if (sc_session) |scs| {
                    defer _ = vtls_scache_asn1.Curl_ssl_scache_put_zig(
                        cf,
                        data,
                        scache,
                        has_share_scache,
                        @ptrCast(conn_config),
                        trc_feat,
                        peer_key,
                        scs,
                    );
                    if (scs.sdata != null and scs.sdata_len > 0) {
                        var sdata_ptr: ?[*]const u8 = scs.sdata;
                        if (ossl_ext.d2i_SSL_SESSION(null, &sdata_ptr, @intCast(scs.sdata_len))) |sess| {
                            defer ossl_ext.SSL_SESSION_free(sess);
                            if (ossl_ext.SSL_set_session(ssl, sess) == 1) {
                                octx.set_reused_session(true);
                                if (builtin.os.tag.isDarwin()) {
                                    octx.set_sectrust_session(scs.isSectrustVerified());
                                    octx.set_sectrust_verified(scs.isSectrustVerified());
                                }
                                if (conn_config.earlydata() and scs.alpn != null and ossl_ext.SSL_SESSION_get_max_early_data(sess) > 0) {
                                    var do_early_data = false;
                                    if (sess_reuse_cb) |reuse_fn| {
                                        _ = reuse_fn(cf, data, &alpns, scs, &do_early_data);
                                    }
                                    if (do_early_data) {
                                        vtls_impl.Curl_alpn_restrict_to(&alpns, scs.alpn.?);
                                    }
                                }
                            } else {
                                ossl_ext.ERR_clear_error();
                            }
                        }
                    }
                }
            }
        }

        if (alpns.count > 0) {
            var proto: AlpnProtoBuf = undefined;
            if (alpnToProtoBuf(&proto, &alpns) != CURLE_OK) {
                c_ext.Curl_failf(data, "Error determining ALPN");
                return CURLE_SSL_CONNECT_ERROR;
            }
            if (ossl_ext.SSL_set_alpn_protos(ssl, &proto.data, @intCast(proto.len)) != 0) {
                c_ext.Curl_failf(data, "Error setting ALPN");
                return CURLE_SSL_CONNECT_ERROR;
            }
        }

        return CURLE_OK;
    }

    fn osslNewSessionCb(ssl: *SSL, ssl_sessionid: *SSL_SESSION) callconv(.c) c_int {
        const cf_raw = ossl_ext.SSL_get_ex_data(ssl, 0) orelse blk: {
            const rbio = ossl_ext.SSL_get_rbio(ssl) orelse return 0;
            break :blk ossl_ext.BIO_get_data(rbio) orelse return 0;
        };
        const cf: *CurlCfilter = @ptrCast(@alignCast(cf_raw));
        const connssl: *SslConnectData = @ptrCast(@alignCast(cf.ctx orelse return 0));
        const octx: *OsslCtx = @ptrCast(@alignCast(connssl.backend orelse return 0));
        const data = connssl.call_data orelse return 0;
        const conn_config = vtls_impl.Curl_ssl_cf_get_filter_config(cf) orelse return 0;
        if (!conn_config.primary_cache_session()) return 0;
        const peer_key = connssl.peer.scache_key orelse return 0;

        const sess_len = ossl_ext.i2d_SSL_SESSION(ssl_sessionid, null);
        if (sess_len <= 0) return 0;
        const sess_buf_raw = mem.calloc(1, @intCast(sess_len)) orelse return 0;
        var sess_ptr: ?[*]u8 = @ptrCast(sess_buf_raw);
        const enc_len = ossl_ext.i2d_SSL_SESSION(ssl_sessionid, &sess_ptr);
        if (enc_len <= 0 or enc_len > sess_len) {
            mem.secureZero(sess_buf_raw, @intCast(sess_len));
            mem.freeSized(sess_buf_raw, @intCast(sess_len));
            return 0;
        }

        const timeout = ossl_ext.SSL_SESSION_get_timeout(ssl_sessionid);
        const valid_until = if (timeout > 0) c_ext.Curl_pgrs_now(data).tv_sec + @as(i64, @intCast(timeout)) else 0;
        const ietf_tls_id = ossl_ext.SSL_version(ssl);
        var sc_session: ?*CurlSslSession = null;
        const res = vtls_scache_asn1.Curl_ssl_session_create2(
            @ptrCast(sess_buf_raw),
            @intCast(enc_len),
            ietf_tls_id,
            connssl.negotiated_alpn,
            valid_until,
            0,
            null,
            0,
            &sc_session,
        );
        if (res != CURLE_OK or sc_session == null) return 0;
        if (builtin.os.tag.isDarwin() and octx.sectrust_verified()) {
            sc_session.?.setSectrustVerified(true);
        }

        var scache: ?*CurlSslScache = null;
        var has_share_scache = false;
        var trc_feat: ?*CurlTrcFeat = null;
        c_ext.Curl_vtls_acc_scache_params(data, &scache, &has_share_scache, &trc_feat);
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

    fn osslConnectStep1(cf: *CurlCfilter, data: ?*CurlEasy) CURLcode {
        const connssl: *SslConnectData = @ptrCast(@alignCast(cf.ctx orelse return CURLE_SSL_CONNECT_ERROR));
        const octx: *OsslCtx = @ptrCast(@alignCast(connssl.backend orelse return CURLE_SSL_CONNECT_ERROR));
        const conn_config = vtls_impl.Curl_ssl_cf_get_filter_config(cf) orelse return CURLE_SSL_CONNECT_ERROR;
        const is_proxy = vtls_impl.Curl_ssl_cf_is_proxy(cf);

        if (ossl_ext.RAND_status() == 0) {
            c_ext.Curl_failf(data, "Insufficient randomness");
            return CURLE_SSL_CONNECT_ERROR;
        }

        if (c_ext.Curl_vtls_acc_ssl_engine(data)) |eng_name| {
            const prov_rc = osslSetProvider(data, octx, eng_name);
            if (prov_rc != CURLE_OK) return prov_rc;
        }

        const ver_range = mapTlsVersionMinMax(conn_config.version, conn_config.version_max) orelse {
            c_ext.Curl_failf(data, "OpenSSL: unsupported SSL version range");
            return CURLE_NOT_BUILT_IN;
        };

        const method = ossl_ext.TLS_client_method() orelse return CURLE_SSL_CONNECT_ERROR;
        if (octx.ssl_ctx) |old| ossl_ext.SSL_CTX_free(old);
        octx.set_x509_store_setup(false);
        octx.ssl_ctx = if (octx.p.libctx != null)
            ossl_ext.SSL_CTX_new_ex(octx.p.libctx, octx.p.propq, method)
        else
            ossl_ext.SSL_CTX_new(method);
        const ssl_ctx = octx.ssl_ctx orelse return CURLE_OUT_OF_MEMORY;

        _ = ossl_ext.SSL_CTX_ctrl(ssl_ctx, SSL_CTRL_MODE, SSL_MODE_RELEASE_BUFFERS, null);

        var ctx_options: u64 = SSL_OP_ALL | SSL_OP_NO_TICKET | SSL_OP_NO_COMPRESSION;
        _ = ossl_ext.SSL_CTX_set_options(ssl_ctx, ctx_options);
        ctx_options = SSL_OP_NETSCAPE_REUSE_CIPHER_CHANGE_BUG;
        if (conn_config.enable_beast()) {
            ctx_options |= SSL_OP_DONT_INSERT_EMPTY_FRAGMENTS;
        }
        _ = ossl_ext.SSL_CTX_clear_options(ssl_ctx, ctx_options);

        if (ossl_ext.SSL_CTX_ctrl(ssl_ctx, SSL_CTRL_SET_MIN_PROTO_VERSION, ver_range.min_ver, null) == 0) {
            return CURLE_SSL_CONNECT_ERROR;
        }
        if (ver_range.max_ver != 0) {
            if (ossl_ext.SSL_CTX_ctrl(ssl_ctx, SSL_CTRL_SET_MAX_PROTO_VERSION, ver_range.max_ver, null) == 0) {
                return CURLE_SSL_CONNECT_ERROR;
            }
        }

        const ciphers: ?[*:0]const u8 = if (conn_config.cipher_list) |c| c else c_ext.Curl_vtls_acc_ssl_cipher_list(data, is_proxy);
        if (ciphers) |c_str| {
            if (ossl_ext.SSL_CTX_set_cipher_list(ssl_ctx, c_str) == 0) {
                c_ext.Curl_failf(data, "failed setting cipher list: %s", c_str);
                return CURLE_SSL_CIPHER;
            }
        }

        const ciphers13: ?[*:0]const u8 = if (conn_config.cipher_list13) |c| c else c_ext.Curl_vtls_acc_ssl_cipher13_list(data, is_proxy);
        if (ciphers13) |c13_str| {
            if (ossl_ext.SSL_CTX_set_ciphersuites(ssl_ctx, c13_str) == 0) {
                c_ext.Curl_failf(data, "failed setting TLS 1.3 cipher suite: %s", c13_str);
                return CURLE_SSL_CIPHER;
            }
        }

        ossl_ext.SSL_CTX_set_post_handshake_auth(ssl_ctx, 1);

        const curves: ?[*:0]const u8 = if (conn_config.curves) |c| c else c_ext.Curl_vtls_acc_ssl_ec_curves(data);
        if (curves) |curves_str| {
            if (ossl_ext.SSL_CTX_ctrl(ssl_ctx, SSL_CTRL_SET_GROUPS_LIST, 0, @ptrCast(@constCast(curves_str))) == 0) {
                c_ext.Curl_failf(data, "failed setting curves list: '%s'", curves_str);
                return CURLE_SSL_CIPHER;
            }
        }

        const sigalgs: ?[*:0]const u8 = if (conn_config.signature_algorithms) |s| s else c_ext.Curl_vtls_acc_ssl_signature_algorithms(data);
        if (sigalgs) |sigalgs_str| {
            if (ossl_ext.SSL_CTX_ctrl(ssl_ctx, SSL_CTRL_SET_SIGALGS_LIST, 0, @ptrCast(@constCast(sigalgs_str))) == 0) {
                c_ext.Curl_failf(data, "failed setting signature algorithms list: '%s'", sigalgs_str);
                return CURLE_SSL_CIPHER;
            }
        }

        vtls_core.Curl_tls_keylog_open();
        if (vtls_core.Curl_tls_keylog_enabled()) {
            ossl_ext.SSL_CTX_set_keylog_callback(ssl_ctx, &osslKeylogCallback);
        }

        const cert_rc = configureClientCertAndKey(cf, data, ssl_ctx, conn_config);
        if (cert_rc != CURLE_OK) return cert_rc;

        if (connssl.alpn) |alpn| {
            var proto: AlpnProtoBuf = undefined;
            if (alpnToProtoBuf(&proto, alpn) == CURLE_OK and proto.len > 0) {
                _ = ossl_ext.SSL_CTX_set_alpn_protos(ssl_ctx, &proto.data, @intCast(proto.len));
            }
        }

        ossl_ext.SSL_CTX_set_verify(ssl_ctx, SSL_VERIFY_NONE, null);

        _ = ossl_ext.SSL_CTX_ctrl(ssl_ctx, SSL_CTRL_SET_SESS_CACHE_MODE, SSL_SESS_CACHE_CLIENT | SSL_SESS_CACHE_NO_INTERNAL, null);
        ossl_ext.SSL_CTX_sess_set_new_cb(ssl_ctx, &osslNewSessionCb);

        var fsslctx: ?*const anyopaque = null;
        var fsslctxp: ?*anyopaque = null;
        if (c_ext.Curl_vtls_acc_ssl_fsslctx(data, &fsslctx, &fsslctxp)) {
            const store_rc = Curl_ossl_setup_x509_store(cf, data, octx);
            if (store_rc != CURLE_OK) return store_rc;
            const cb: *const fn (?*CurlEasy, ?*anyopaque, ?*anyopaque) callconv(.c) CURLcode = @ptrCast(@alignCast(fsslctx.?));
            const rc = cb(data, ssl_ctx, fsslctxp);
            if (rc != CURLE_OK) {
                c_ext.Curl_failf(data, "error signaled by ssl ctx callback");
                return rc;
            }
        }

        if (octx.ssl) |old| ossl_ext.SSL_free(old);
        const ssl = ossl_ext.SSL_new(ssl_ctx) orelse return CURLE_OUT_OF_MEMORY;
        octx.ssl = ssl;
        _ = ossl_ext.SSL_set_ex_data(ssl, 0, cf);
        ossl_ext.SSL_set_connect_state(ssl);

        if (connssl.peer.sni) |sni| {
            _ = ossl_ext.SSL_ctrl(ssl, SSL_CTRL_SET_TLSEXT_HOSTNAME, TLSEXT_NAMETYPE_host_name, @ptrCast(@constCast(sni)));
        }

        if (conn_config.verifystatus()) {
            if (ossl_ext.SSL_ctrl(ssl, SSL_CTRL_SET_TLSEXT_STATUS_REQ_TYPE, TLSEXT_STATUSTYPE_ocsp, null) == 0) {
                return CURLE_SSL_CONNECT_ERROR;
            }
        }

        if (conn_config.primary_cache_session()) {
            if (connssl.peer.scache_key) |peer_key| {
                var scache: ?*CurlSslScache = null;
                var has_share_scache = false;
                var trc_feat: ?*CurlTrcFeat = null;
                c_ext.Curl_vtls_acc_scache_params(data, &scache, &has_share_scache, &trc_feat);
                var sc_session: ?*CurlSslSession = null;
                _ = vtls_scache_asn1.Curl_ssl_scache_take_zig(
                    cf,
                    data,
                    scache,
                    has_share_scache,
                    @ptrCast(conn_config),
                    trc_feat,
                    peer_key,
                    &sc_session,
                );
                if (sc_session) |scs| {
                    defer vtls_scache_asn1.Curl_ssl_session_destroy(scs);
                    if (scs.sdata != null and scs.sdata_len > 0) {
                        var sdata_ptr: ?[*]const u8 = scs.sdata;
                        if (ossl_ext.d2i_SSL_SESSION(null, &sdata_ptr, @intCast(scs.sdata_len))) |sess| {
                            defer ossl_ext.SSL_SESSION_free(sess);
                            if (ossl_ext.SSL_set_session(ssl, sess) == 1) {
                                if (builtin.os.tag.isDarwin()) {
                                    octx.set_sectrust_session(scs.isSectrustVerified());
                                    octx.set_sectrust_verified(scs.isSectrustVerified());
                                }
                            } else {
                                ossl_ext.ERR_clear_error();
                            }
                        }
                    }
                }
            }
        }

        if (octx.bio_method == null) {
            const bm = ossl_ext.BIO_meth_new(BIO_TYPE_MEM, "OpenSSL CF BIO") orelse return CURLE_OUT_OF_MEMORY;
            _ = ossl_ext.BIO_meth_set_write(bm, &osslBioCfOutWrite);
            _ = ossl_ext.BIO_meth_set_read(bm, &osslBioCfInRead);
            _ = ossl_ext.BIO_meth_set_ctrl(bm, &osslBioCfCtrl);
            _ = ossl_ext.BIO_meth_set_create(bm, &osslBioCfCreate);
            _ = ossl_ext.BIO_meth_set_destroy(bm, &osslBioCfDestroy);
            octx.bio_method = bm;
        }

        const bio = ossl_ext.BIO_new(octx.bio_method.?) orelse return CURLE_OUT_OF_MEMORY;
        ossl_ext.BIO_set_data(bio, cf);
        ossl_ext.SSL_set_bio(ssl, bio, bio);

        connssl.connecting_state = ssl_connect_2;
        return CURLE_OK;
    }

    fn osslConnectStep2(cf: *CurlCfilter, data: ?*CurlEasy) CURLcode {
        const connssl: *SslConnectData = @ptrCast(@alignCast(cf.ctx orelse return CURLE_SSL_CONNECT_ERROR));
        const octx: *OsslCtx = @ptrCast(@alignCast(connssl.backend orelse return CURLE_SSL_CONNECT_ERROR));
        const ssl = octx.ssl orelse return CURLE_SSL_CONNECT_ERROR;

        if (!octx.x509_store_setup()) {
            const store_rc = Curl_ossl_setup_x509_store(cf, data, octx);
            if (store_rc != CURLE_OK) return store_rc;
        }

        ossl_ext.ERR_clear_error();
        const ret = ossl_ext.SSL_connect(ssl);
        if (ret != 1) {
            const detail = ossl_ext.SSL_get_error(ssl, ret);
            if (detail == SSL_ERROR_WANT_READ) {
                connssl.io_need = CURL_SSL_IO_NEED_RECV;
                return CURLE_OK;
            } else if (detail == SSL_ERROR_WANT_WRITE) {
                connssl.io_need = CURL_SSL_IO_NEED_SEND;
                return CURLE_OK;
            }
            if (octx.io_result != CURLE_OK and octx.io_result != CURLE_AGAIN) {
                return octx.io_result;
            }
            var err_buf: [256]u8 = @splat(0);
            const ssl_err = ossl_ext.ERR_get_error();
            if (ssl_err != 0) {
                c_ext.Curl_failf(data, "OpenSSL SSL_connect: %s in connection to %s", osslStrerror(ssl_err, &err_buf, err_buf.len), peerDispname(&connssl.peer));
            }
            return CURLE_SSL_CONNECT_ERROR;
        }

        connssl.connecting_state = ssl_connect_3;
        if (ossl_ext.SSL_session_reused(ssl) != 0) {
            octx.set_reused_session(true);
            c_ext.Curl_infof(data, "SSL reusing session ID");
        } else {
            octx.set_reused_session(false);
        }

        if (connssl.alpn != null) {
            var next_proto: ?[*]const u8 = null;
            var next_proto_len: c_uint = 0;
            ossl_ext.SSL_get0_alpn_selected(ssl, &next_proto, &next_proto_len);
            const rc = vtls_impl.Curl_alpn_set_negotiated(cf, data, connssl, next_proto, next_proto_len);
            if (rc != CURLE_OK) return rc;
        }
        return CURLE_OK;
    }

    fn osslConnect(cf: *CurlCfilter, data: ?*CurlEasy, done: *bool) callconv(.c) CURLcode {
        const connssl: *SslConnectData = @ptrCast(@alignCast(cf.ctx orelse return CURLE_SSL_CONNECT_ERROR));
        const octx: *OsslCtx = @ptrCast(@alignCast(connssl.backend orelse return CURLE_SSL_CONNECT_ERROR));

        if (connssl.state == ssl_connection_complete) {
            done.* = true;
            return CURLE_OK;
        }
        done.* = false;
        connssl.io_need = CURL_SSL_IO_NEED_NONE;
        connssl.call_data = data;
        defer connssl.call_data = null;

        if (connssl.connecting_state == ssl_connect_1) {
            const rc = osslConnectStep1(cf, data);
            if (rc != CURLE_OK) return rc;
        }
        if (connssl.connecting_state == ssl_connect_2) {
            const rc = osslConnectStep2(cf, data);
            if (rc != CURLE_OK) return rc;
        }
        if (connssl.connecting_state == ssl_connect_3) {
            const rc = Curl_ossl_check_peer_cert(cf, data, octx, &connssl.peer);
            if (rc != CURLE_OK) return rc;
            connssl.connecting_state = ssl_connect_done;
        }
        if (connssl.connecting_state == ssl_connect_done) {
            connssl.state = ssl_connection_complete;
            done.* = true;
        }
        return CURLE_OK;
    }

    fn osslDataPending(cf: *CurlCfilter, data: ?*const CurlEasy) callconv(.c) bool {
        _ = data;
        const connssl: *SslConnectData = @ptrCast(@alignCast(cf.ctx orelse return false));
        const octx: *OsslCtx = @ptrCast(@alignCast(connssl.backend orelse return false));
        if (octx.ssl) |ssl| {
            if (ossl_ext.SSL_pending(ssl) > 0) return true;
        }
        return connssl.input_pending();
    }

    fn osslSend(
        cf: *CurlCfilter,
        data: ?*CurlEasy,
        mem_ptr: ?*const anyopaque,
        len: usize,
        pnwritten: *usize,
    ) callconv(.c) CURLcode {
        const connssl: *SslConnectData = @ptrCast(@alignCast(cf.ctx orelse return CURLE_SEND_ERROR));
        const octx: *OsslCtx = @ptrCast(@alignCast(connssl.backend orelse return CURLE_SEND_ERROR));
        const ssl = octx.ssl orelse return CURLE_SEND_ERROR;

        pnwritten.* = 0;
        ossl_ext.ERR_clear_error();
        connssl.io_need = CURL_SSL_IO_NEED_NONE;
        connssl.call_data = data;
        defer connssl.call_data = null;

        var memlen: c_int = if (len > std.math.maxInt(c_int)) std.math.maxInt(c_int) else @intCast(len);
        if (octx.blocked_ssl_write_len > 0 and octx.blocked_ssl_write_len < memlen) {
            memlen = octx.blocked_ssl_write_len;
        }
        octx.blocked_ssl_write_len = 0;

        const nwritten = ossl_ext.SSL_write(ssl, mem_ptr, memlen);
        if (nwritten > 0) {
            pnwritten.* = @intCast(nwritten);
            return CURLE_OK;
        }
        const err = ossl_ext.SSL_get_error(ssl, nwritten);
        return switch (err) {
            SSL_ERROR_WANT_READ => blk: {
                connssl.io_need = CURL_SSL_IO_NEED_RECV;
                octx.blocked_ssl_write_len = memlen;
                break :blk CURLE_AGAIN;
            },
            SSL_ERROR_WANT_WRITE => blk: {
                connssl.io_need = CURL_SSL_IO_NEED_SEND;
                octx.blocked_ssl_write_len = memlen;
                break :blk CURLE_AGAIN;
            },
            SSL_ERROR_SYSCALL => if (octx.io_result == CURLE_AGAIN) blk: {
                octx.blocked_ssl_write_len = memlen;
                break :blk CURLE_AGAIN;
            } else CURLE_SEND_ERROR,
            else => CURLE_SEND_ERROR,
        };
    }

    fn osslRecv(
        cf: *CurlCfilter,
        data: ?*CurlEasy,
        buf: [*]u8,
        buffersize: usize,
        pnread: *usize,
    ) callconv(.c) CURLcode {
        const connssl: *SslConnectData = @ptrCast(@alignCast(cf.ctx orelse return CURLE_RECV_ERROR));
        const octx: *OsslCtx = @ptrCast(@alignCast(connssl.backend orelse return CURLE_RECV_ERROR));
        const ssl = octx.ssl orelse return CURLE_RECV_ERROR;

        pnread.* = 0;
        ossl_ext.ERR_clear_error();
        connssl.io_need = CURL_SSL_IO_NEED_NONE;
        connssl.call_data = data;
        defer connssl.call_data = null;

        const buffsize: c_int = if (buffersize > std.math.maxInt(c_int)) std.math.maxInt(c_int) else @intCast(buffersize);
        const nread = ossl_ext.SSL_read(ssl, buf, buffsize);
        if (nread > 0) {
            pnread.* = @intCast(nread);
            return CURLE_OK;
        }
        const err = ossl_ext.SSL_get_error(ssl, nread);
        return switch (err) {
            SSL_ERROR_NONE, SSL_ERROR_ZERO_RETURN => blk: {
                connssl.set_input_pending(false);
                break :blk CURLE_OK;
            },
            SSL_ERROR_WANT_READ => blk: {
                connssl.io_need = CURL_SSL_IO_NEED_RECV;
                break :blk CURLE_AGAIN;
            },
            SSL_ERROR_WANT_WRITE => blk: {
                connssl.io_need = CURL_SSL_IO_NEED_SEND;
                break :blk CURLE_AGAIN;
            },
            SSL_ERROR_SYSCALL => if (octx.io_result == CURLE_AGAIN) CURLE_AGAIN else if (connssl.peer_closed() and ossl_ext.ERR_peek_error() == 0) CURLE_OK else CURLE_RECV_ERROR,
            else => CURLE_RECV_ERROR,
        };
    }

    fn osslShutdown(cf: *CurlCfilter, data: ?*CurlEasy, send_shutdown: bool, done: *bool) callconv(.c) CURLcode {
        const connssl: *SslConnectData = @ptrCast(@alignCast(cf.ctx orelse {
            done.* = true;
            return CURLE_OK;
        }));
        const octx: *OsslCtx = @ptrCast(@alignCast(connssl.backend orelse {
            done.* = true;
            return CURLE_OK;
        }));
        const ssl = octx.ssl orelse {
            done.* = true;
            cf.setShutdown(true);
            return CURLE_OK;
        };
        if (cf.isShutdown()) {
            done.* = true;
            return CURLE_OK;
        }

        connssl.io_need = CURL_SSL_IO_NEED_NONE;
        connssl.call_data = data;
        defer connssl.call_data = null;
        done.* = false;

        var buf: [1024]u8 = undefined;
        var nread: c_int = -1;
        var err: c_int = SSL_ERROR_NONE;
        var result: CURLcode = CURLE_OK;

        if ((ossl_ext.SSL_get_shutdown(ssl) & SSL_SENT_SHUTDOWN) == 0) {
            ossl_ext.ERR_clear_error();
            for (0..10) |_| {
                nread = ossl_ext.SSL_read(ssl, &buf, @intCast(buf.len));
                if (nread <= 0) break;
            }
            err = ossl_ext.SSL_get_error(ssl, nread);
            if (nread == 0 and err == SSL_ERROR_ZERO_RETURN) {
                var input_pending = false;
                if (!send_shutdown) {
                    done.* = true;
                    cf.setShutdown(true);
                    connssl.set_input_pending(false);
                    return CURLE_OK;
                } else if (cf.next != null and !cf.next.?.cft.is_alive(cf.next.?, data, &input_pending)) {
                    connssl.set_peer_closed(true);
                    done.* = true;
                    cf.setShutdown(true);
                    connssl.set_input_pending(false);
                    return CURLE_OK;
                }
            }
        }

        if (send_shutdown and (ossl_ext.SSL_get_shutdown(ssl) & SSL_SENT_SHUTDOWN) == 0) {
            ossl_ext.ERR_clear_error();
            const rc = ossl_ext.SSL_shutdown(ssl);
            if (rc == 1) {
                done.* = true;
                cf.setShutdown(true);
                connssl.set_input_pending(false);
                return CURLE_OK;
            }
            if (ossl_ext.SSL_get_error(ssl, rc) == SSL_ERROR_WANT_WRITE) {
                connssl.io_need = CURL_SSL_IO_NEED_SEND;
                connssl.set_input_pending(false);
                return CURLE_OK;
            }
        }

        for (0..10) |_| {
            ossl_ext.ERR_clear_error();
            nread = ossl_ext.SSL_read(ssl, &buf, @intCast(buf.len));
            if (nread <= 0) break;
        }
        err = ossl_ext.SSL_get_error(ssl, nread);
        switch (err) {
            SSL_ERROR_ZERO_RETURN => {
                _ = ossl_ext.SSL_shutdown(ssl);
                done.* = true;
            },
            SSL_ERROR_NONE, SSL_ERROR_WANT_READ => {
                connssl.io_need = CURL_SSL_IO_NEED_RECV;
            },
            SSL_ERROR_WANT_WRITE => {
                connssl.io_need = CURL_SSL_IO_NEED_SEND;
            },
            else => {
                _ = sslErrorToStr(err);
                done.* = true;
                result = CURLE_OK;
            },
        }

        cf.setShutdown(result != CURLE_OK or done.*);
        if (cf.isShutdown() or connssl.io_need != CURL_SSL_IO_NEED_NONE) {
            connssl.set_input_pending(false);
        }
        return result;
    }

    pub fn Curl_osslctx_cleanup(octx: *OsslCtx) callconv(.c) void {
        if (octx.ssl) |ssl| {
            ossl_ext.SSL_free(ssl);
            octx.ssl = null;
        }
        if (octx.ssl_ctx) |ctx| {
            ossl_ext.SSL_CTX_free(ctx);
            octx.ssl_ctx = null;
            octx.set_x509_store_setup(false);
        }
        if (octx.bio_method) |bm| {
            ossl_ext.BIO_meth_free(bm);
            octx.bio_method = null;
        }
        osslProviderCleanup(octx);
    }

    fn osslClose(cf: *CurlCfilter, data: ?*CurlEasy) callconv(.c) void {
        _ = data;
        const connssl: *SslConnectData = @ptrCast(@alignCast(cf.ctx orelse return));
        const octx: *OsslCtx = @ptrCast(@alignCast(connssl.backend orelse return));
        Curl_osslctx_cleanup(octx);
    }

    fn osslCloseAll(data: ?*CurlEasy) callconv(.c) void {
        _ = data;
    }

    fn osslGetInternals(connssl: *SslConnectData, info: c_uint) callconv(.c) ?*anyopaque {
        const octx: *OsslCtx = @ptrCast(@alignCast(connssl.backend orelse return null));
        return if (info == CURLINFO_TLS_SESSION) @ptrCast(octx.ssl_ctx) else @ptrCast(octx.ssl);
    }

    fn osslRandom(data: ?*CurlEasy, entropy: [*]u8, length: usize) callconv(.c) CURLcode {
        _ = data;
        if (ossl_ext.RAND_bytes(entropy, @intCast(length)) != 1)
            return CURLE_FAILED_INIT;
        return CURLE_OK;
    }

    fn osslSha256sum(input: [*]const u8, inputlen: usize, sha256sum: [*]u8, sha256len: usize) callconv(.c) CURLcode {
        if (sha256len < 32) return CURLE_BAD_FUNCTION_ARGUMENT;
        var digest: [32]u8 = undefined;
        std.crypto.hash.sha2.Sha256.hash(input[0..inputlen], &digest, .{});
        @memcpy(sha256sum[0..32], &digest);
        return CURLE_OK;
    }

    fn osslCertStatusRequest() callconv(.c) bool {
        return true;
    }

    fn osslGetChannelBinding(data: ?*CurlEasy, sockindex: i8, binding: *DynBuf) callconv(.c) CURLcode {
        const conn = c_ext.Curl_vtls_acc_data_conn(data) orelse return CURLE_OK;
        var cf = c_ext.Curl_vtls_acc_conn_cfilter(conn, sockindex);
        while (cf) |cur| : (cf = cur.next) {
            if (cur.cft == &vtls_impl.Curl_cft_ssl) {
                const connssl: *SslConnectData = @ptrCast(@alignCast(cur.ctx orelse return CURLE_OK));
                const octx: *OsslCtx = @ptrCast(@alignCast(connssl.backend orelse return CURLE_OK));
                const ssl = octx.ssl orelse return CURLE_OK;
                const server_cert = ossl_ext.SSL_get1_peer_certificate(ssl) orelse return CURLE_OK;
                defer ossl_ext.X509_free(server_cert);

                const sig_nid = ossl_ext.X509_get_signature_nid(server_cert);
                var digest_nid: c_int = NID_undef;
                var digest_algo: *const EVP_MD = ossl_ext.EVP_sha256();
                if (ossl_ext.OBJ_find_sigid_algs(sig_nid, &digest_nid, null) != 0 and
                    digest_nid != NID_md5 and digest_nid != NID_sha1 and digest_nid != NID_undef)
                {
                    if (ossl_ext.OBJ_nid2sn(digest_nid)) |sn| {
                        if (ossl_ext.EVP_get_digestbyname(sn)) |md| {
                            digest_algo = md;
                        }
                    }
                }

                const prefix = "tls-server-end-point:";
                const rc = containers.curlx_dyn_addn(binding, prefix.ptr, prefix.len);
                if (rc != CURLE_OK) return rc;

                var hash_buf: [64]u8 = @splat(0);
                var hash_len: c_uint = 0;
                if (ossl_ext.X509_digest(server_cert, digest_algo, &hash_buf, &hash_len) == 0 or hash_len == 0) {
                    return CURLE_SSL_CONNECT_ERROR;
                }
                return containers.curlx_dyn_addn(binding, &hash_buf, hash_len);
            }
        }
        return CURLE_OK;
    }

    pub const Curl_ssl_openssl = CurlSsl{
        .info = .{ .id = CURLSSLBACKEND_OPENSSL, .name = "openssl" },
        .supports = SSLSUPP_CA_PATH | SSLSUPP_CERTINFO | SSLSUPP_PINNEDPUBKEY | SSLSUPP_SSL_CTX | SSLSUPP_HTTPS_PROXY | SSLSUPP_TLS13_CIPHERSUITES | SSLSUPP_CAINFO_BLOB | SSLSUPP_CIPHER_LIST | SSLSUPP_CA_CACHE | SSLSUPP_CRLFILE | SSLSUPP_ISSUERCERT | SSLSUPP_ISSUERCERT_BLOB | SSLSUPP_SSL_EC_CURVES | SSLSUPP_SIGNATURE_ALGORITHMS,
        .sizeof_ssl_backend_data = @sizeOf(OsslCtx),
        .init = Curl_ossl_init,
        .cleanup = Curl_ossl_cleanup,
        .version = Curl_ossl_version,
        .shut_down = osslShutdown,
        .data_pending = osslDataPending,
        .random = osslRandom,
        .cert_status_request = osslCertStatusRequest,
        .do_connect = osslConnect,
        .adjust_pollset = vtls_impl.Curl_ssl_adjust_pollset,
        .get_internals = osslGetInternals,
        .close = osslClose,
        .close_all = osslCloseAll,
        .engines_list = null,
        .sha256sum = osslSha256sum,
        .recv_plain = osslRecv,
        .send_plain = osslSend,
        .get_channel_binding = osslGetChannelBinding,
    };

    test "openssl_backend DNS SAN, wildcard SAN, embedded NUL, IPv4/IPv6 SAN, and CN fallback" {
        const exact_dns = "example.com";
        const wildcard_dns = "*.example.com";
        const embedded_nul_dns = "example.com\x00.evil.com";

        // Exact & wildcard DNS matching
        try std.testing.expect(matchDnsNameBytes(exact_dns.ptr, exact_dns.len, "example.com"));
        try std.testing.expect(!matchDnsNameBytes(exact_dns.ptr, exact_dns.len, "sub.example.com"));
        try std.testing.expect(matchDnsNameBytes(wildcard_dns.ptr, wildcard_dns.len, "sub.example.com"));
        try std.testing.expect(!matchDnsNameBytes(wildcard_dns.ptr, wildcard_dns.len, "a.b.example.com"));

        // Embedded NUL rejection in DNS SAN
        try std.testing.expect(!matchDnsNameBytes(embedded_nul_dns.ptr, embedded_nul_dns.len, "example.com"));

        // IPv4 and IPv6 SAN matching
        const ipv4_bytes = [_]u8{ 192, 0, 2, 1 };
        try std.testing.expect(matchIpSanBytes(&ipv4_bytes, ipv4_bytes.len, SSL_PEER_IPV4, "192.0.2.1"));
        try std.testing.expect(!matchIpSanBytes(&ipv4_bytes, ipv4_bytes.len, SSL_PEER_IPV4, "192.0.2.2"));
        try std.testing.expect(!matchIpSanBytes(&ipv4_bytes, ipv4_bytes.len, SSL_PEER_IPV6, "192.0.2.1"));

        const ipv6_bytes = [_]u8{
            0x20, 0x01, 0x0d, 0xb8, 0, 0, 0, 0,
            0,    0,    0,    0,    0, 0, 0, 1,
        };
        try std.testing.expect(matchIpSanBytes(&ipv6_bytes, ipv6_bytes.len, SSL_PEER_IPV6, "2001:db8::1"));
        try std.testing.expect(!matchIpSanBytes(&ipv6_bytes, ipv6_bytes.len, SSL_PEER_IPV6, "2001:db8::2"));

        // Synthetic RFC 2818 SAN + CN fallback flow:
        // 1. Matching wildcard DNS SAN
        const san_list = [_]SanEntry{
            .{ .san_type = GEN_DNS, .data = wildcard_dns.ptr, .len = wildcard_dns.len },
            .{ .san_type = GEN_IPADD, .data = &ipv4_bytes, .len = ipv4_bytes.len },
        };
        try std.testing.expectEqual(HostVerifyOutcome.matched_dns_san, verifyHostSynthetic(SSL_PEER_DNS, "api.example.com", &san_list, "ignored.example.com"));
        try std.testing.expectEqual(HostVerifyOutcome.matched_ip_san, verifyHostSynthetic(SSL_PEER_IPV4, "192.0.2.1", &san_list, null));

        // 2. When SANs exist but do not match, must NOT fall back to matching CN!
        try std.testing.expectEqual(HostVerifyOutcome.san_mismatch, verifyHostSynthetic(SSL_PEER_DNS, "other.org", &san_list, "other.org"));

        // 3. When no SANs exist: IP peer fails, DNS peer falls back to CN (and rejects embedded NUL in CN)
        try std.testing.expectEqual(HostVerifyOutcome.no_san_for_ip, verifyHostSynthetic(SSL_PEER_IPV4, "192.0.2.1", null, "192.0.2.1"));
        try std.testing.expectEqual(HostVerifyOutcome.matched_cn, verifyHostSynthetic(SSL_PEER_DNS, "example.com", null, "example.com"));
        try std.testing.expectEqual(HostVerifyOutcome.cn_embedded_nul, verifyHostSynthetic(SSL_PEER_DNS, "example.com", null, embedded_nul_dns));
        try std.testing.expectEqual(HostVerifyOutcome.cn_mismatch, verifyHostSynthetic(SSL_PEER_DNS, "example.com", null, "wrong.example.com"));
        try std.testing.expectEqual(HostVerifyOutcome.cn_missing, verifyHostSynthetic(SSL_PEER_DNS, "example.com", null, null));
    }

    test "openssl_backend TLS version range, file type, password cb, and SHA-256 helpers" {
        const def_range = mapTlsVersionMinMax(CURL_SSLVERSION_DEFAULT, CURL_SSLVERSION_MAX_DEFAULT).?;
        try std.testing.expectEqual(TLS1_VERSION, def_range.min_ver);
        try std.testing.expectEqual(@as(c_long, 0), def_range.max_ver);

        const v12_v13 = mapTlsVersionMinMax(CURL_SSLVERSION_TLSv1_2, CURL_SSLVERSION_MAX_TLSv1_3).?;
        try std.testing.expectEqual(TLS1_2_VERSION, v12_v13.min_ver);
        try std.testing.expectEqual(TLS1_3_VERSION, v12_v13.max_ver);

        try std.testing.expect(mapTlsVersionMinMax(CURL_SSLVERSION_SSLv3, CURL_SSLVERSION_MAX_DEFAULT) == null);
        try std.testing.expect(mapTlsVersionMinMax(CURL_SSLVERSION_TLSv1_3, @as(u32, CURL_SSLVERSION_TLSv1_2) << 16) == null);

        try std.testing.expectEqual(SSL_FILETYPE_PEM, osslDoFileType(null));
        try std.testing.expectEqual(SSL_FILETYPE_PEM, osslDoFileType("PEM"));
        try std.testing.expectEqual(SSL_FILETYPE_ASN1, osslDoFileType("DER"));
        try std.testing.expectEqual(SSL_FILETYPE_PKCS12, osslDoFileType("P12"));
        try std.testing.expectEqual(@as(c_int, -1), osslDoFileType("UNKNOWN"));

        var pw_buf: [16]u8 = @splat(0);
        const secret: [*:0]const u8 = "s3cr3t";
        try std.testing.expectEqual(@as(c_int, 6), passwdCallback(&pw_buf, pw_buf.len, 0, @ptrCast(@constCast(secret))));
        try std.testing.expectEqualStrings("s3cr3t", pw_buf[0..6]);

        var sha_out: [32]u8 = undefined;
        try std.testing.expectEqual(CURLE_OK, osslSha256sum("abc", 3, &sha_out, sha_out.len));
        try std.testing.expectEqual(@as(u8, 0xba), sha_out[0]);
    }
};
comptime {
    _ = openssl_backend;
}

// ============================================================================
// 4. lib/vtls/mbedtls.c — mbedTLS Backend
// ============================================================================

const mbedtls_backend = struct {
    const use_mbedtls = backend_options.ssl == .mbedtls;
    pub const CURLE_SSL_CACERT_BADFILE: CURLcode = 77;
    pub const MBED_SSLVERSION_MAX_TLSv1_2: u32 = @as(u32, CURL_SSLVERSION_TLSv1_2) << 16;

    pub const MBEDTLS_ERR_SSL_WANT_READ: c_int = -0x6900;
    pub const MBEDTLS_ERR_SSL_WANT_WRITE: c_int = -0x6880;
    pub const MBEDTLS_ERR_SSL_PEER_CLOSE_NOTIFY: c_int = -0x7880;
    pub const MBEDTLS_ERR_SSL_RECEIVED_NEW_SESSION_TICKET: c_int = -0x7B00;
    pub const MBEDTLS_ERR_SSL_BAD_INPUT_DATA: c_int = -0x7100;
    pub const MBEDTLS_ERR_SSL_ALLOC_FAILED: c_int = -0x7F00;
    pub const MBEDTLS_ERR_X509_CERT_VERIFY_FAILED: c_int = -0x2700;
    pub const MBEDTLS_ERR_PK_KEY_INVALID_FORMAT: c_int = -0x3D00;
    pub const MBEDTLS_ERR_PK_TYPE_MISMATCH: c_int = -0x3F00;

    pub const MBEDTLS_SSL_VERSION_TLS1_2: c_int = 0x0303;
    pub const MBEDTLS_SSL_VERSION_TLS1_3: c_int = 0x0304;

    pub const MBEDTLS_SSL_IS_CLIENT: c_int = 0;
    pub const MBEDTLS_SSL_TRANSPORT_STREAM: c_int = 0;
    pub const MBEDTLS_SSL_PRESET_DEFAULT: c_int = 0;

    pub const MBEDTLS_SSL_VERIFY_NONE: c_int = 0;
    pub const MBEDTLS_SSL_VERIFY_OPTIONAL: c_int = 1;
    pub const MBEDTLS_SSL_VERIFY_REQUIRED: c_int = 2;

    pub const MBEDTLS_X509_BADCERT_EXPIRED: u32 = 0x01;
    pub const MBEDTLS_X509_BADCERT_REVOKED: u32 = 0x02;
    pub const MBEDTLS_X509_BADCERT_CN_MISMATCH: u32 = 0x04;
    pub const MBEDTLS_X509_BADCERT_NOT_TRUSTED: u32 = 0x08;
    pub const MBEDTLS_X509_BADCRL_NOT_TRUSTED: u32 = 0x10;
    pub const MBEDTLS_X509_BADCRL_EXPIRED: u32 = 0x20;

    pub const MBEDTLS_PK_RSA: c_int = 1;
    pub const MBEDTLS_PK_ECKEY: c_int = 2;
    pub const MBEDTLS_PK_ECDSA: c_int = 4;

    pub const MBEDTLS_TLS_ECJPAKE_WITH_AES_128_CCM_8: u16 = 0xC0FF;
    const PUB_DER_MAX_BYTES: usize = 38 + (2 * 1024);
    const MAX_ALLOWED_CERT_AMOUNT: c_int = 100;

    pub const mbedtls_asn1_buf = extern struct {
        tag: c_int = 0,
        len: usize = 0,
        p: ?[*]u8 = null,
    };
    pub const mbedtls_x509_buf = mbedtls_asn1_buf;

    pub const mbedtls_asn1_bitstring = extern struct {
        len: usize = 0,
        unused_bits: u8 = 0,
        p: ?[*]u8 = null,
    };
    pub const mbedtls_x509_bitstring = mbedtls_asn1_bitstring;

    pub const mbedtls_asn1_sequence = extern struct {
        buf: mbedtls_asn1_buf = .{},
        next: ?*mbedtls_asn1_sequence = null,
    };
    pub const mbedtls_x509_sequence = mbedtls_asn1_sequence;

    pub const mbedtls_asn1_named_data = extern struct {
        oid: mbedtls_asn1_buf = .{},
        val: mbedtls_asn1_buf = .{},
        next: ?*mbedtls_asn1_named_data = null,
        next_merged: u8 = 0,
    };
    pub const mbedtls_x509_name = mbedtls_asn1_named_data;

    pub const mbedtls_x509_time = extern struct {
        year: c_int = 0,
        mon: c_int = 0,
        day: c_int = 0,
        hour: c_int = 0,
        min: c_int = 0,
        sec: c_int = 0,
    };

    pub const mbedtls_x509_authority = extern struct {
        keyIdentifier: mbedtls_x509_buf = .{},
        authorityCertIssuer: mbedtls_x509_sequence = .{},
        authorityCertSerialNumber: mbedtls_x509_buf = .{},
        raw: mbedtls_x509_buf = .{},
    };

    pub const mbedtls_pk_context = extern struct {
        pk_info: ?*const anyopaque = null,
        pk_ctx: ?*anyopaque = null,
    };

    pub const mbedtls_x509_crt = extern struct {
        own_buffer: c_int = 0,
        raw: mbedtls_x509_buf = .{},
        tbs: mbedtls_x509_buf = .{},
        version: c_int = 0,
        serial: mbedtls_x509_buf = .{},
        sig_oid: mbedtls_x509_buf = .{},
        issuer_raw: mbedtls_x509_buf = .{},
        subject_raw: mbedtls_x509_buf = .{},
        issuer: mbedtls_x509_name = .{},
        subject: mbedtls_x509_name = .{},
        valid_from: mbedtls_x509_time = .{},
        valid_to: mbedtls_x509_time = .{},
        pk_raw: mbedtls_x509_buf = .{},
        pk: mbedtls_pk_context = .{},
        issuer_id: mbedtls_x509_bitstring = .{},
        subject_id: mbedtls_x509_bitstring = .{},
        v3_ext: mbedtls_x509_buf = .{},
        subject_alt_names: mbedtls_x509_sequence = .{},
        subject_key_id: mbedtls_x509_buf = .{},
        authority_key_id: mbedtls_x509_authority = .{},
        certificate_policies: mbedtls_x509_sequence = .{},
        ext_types: c_int = 0,
        ca_istrue: c_int = 0,
        max_pathlen: c_int = 0,
        key_usage: c_uint = 0,
        ext_key_usage: mbedtls_x509_sequence = .{},
        ns_cert_type: u8 = 0,
        sig: mbedtls_x509_buf = .{},
        sig_md: c_int = 0,
        sig_pk: c_int = 0,
        sig_opts: ?*anyopaque = null,
        next: ?*mbedtls_x509_crt = null,
        _extra_pad: [256]u8 = @splat(0),
    };

    pub const mbedtls_x509_crl = extern struct {
        _data: [128]u64 = @splat(0),
    };

    pub const mbedtls_ssl_config = extern struct {
        max_tls_version: c_int = 0,
        min_tls_version: c_int = 0,
        endpoint: u8 = 0,
        transport: u8 = 0,
        authmode: u8 = 0,
        allow_legacy_renegotiation: u8 = 0,
        _pad0: u32 = 0,
        _data: [80]u64 = @splat(0),
    };

    pub const mbedtls_ssl_context = extern struct {
        conf: ?*const mbedtls_ssl_config = null,
        state: c_int = 0,
        renego_status: c_int = 0,
        renego_records_seen: c_int = 0,
        tls_version: c_int = 0,
        _data: [128]u64 = @splat(0),
    };

    pub const mbedtls_ssl_session = extern struct {
        _data: [80]u64 = @splat(0),
    };

    pub const mbedtls_entropy_context = extern struct {
        _data: [4800]u64 = @splat(0),
    };

    pub const mbedtls_ctr_drbg_context = extern struct {
        _data: [64]u64 = @splat(0),
    };

    pub const MbedSslBackendData = extern struct {
        ctr_drbg: mbedtls_ctr_drbg_context,
        entropy: mbedtls_entropy_context,
        ssl: mbedtls_ssl_context,
        cacert: mbedtls_x509_crt,
        clicert: mbedtls_x509_crt,
        crl: mbedtls_x509_crl,
        pk: mbedtls_pk_context,
        _pk_pad: [64]u8,
        config: mbedtls_ssl_config,
        protocols: [5]?[*:0]const u8,
        ciphersuites: ?[*]c_int,
        send_blocked_len: usize,
        flags: packed struct(u8) {
            initialized: bool = false,
            sent_shutdown: bool = false,
            pkt_enc_key_set: bool = false,
            send_blocked: bool = false,
            _pad: u4 = 0,
        },
    };

    const mbed_ext = struct {
        extern fn psa_crypto_init() callconv(.c) c_int;
        extern fn mbedtls_version_get_number() callconv(.c) c_uint;
        extern fn mbedtls_strerror(ret: c_int, buf: [*]u8, buflen: usize) callconv(.c) void;

        extern fn mbedtls_ssl_init(ssl: *mbedtls_ssl_context) callconv(.c) void;
        extern fn mbedtls_ssl_free(ssl: *mbedtls_ssl_context) callconv(.c) void;
        extern fn mbedtls_ssl_setup(ssl: *mbedtls_ssl_context, conf: *const mbedtls_ssl_config) callconv(.c) c_int;
        extern fn mbedtls_ssl_config_init(conf: *mbedtls_ssl_config) callconv(.c) void;
        extern fn mbedtls_ssl_config_free(conf: *mbedtls_ssl_config) callconv(.c) void;
        extern fn mbedtls_ssl_config_defaults(conf: *mbedtls_ssl_config, endpoint: c_int, transport: c_int, preset: c_int) callconv(.c) c_int;

        extern fn mbedtls_ssl_conf_rng(conf: *mbedtls_ssl_config, f_rng: ?*const fn (?*anyopaque, [*]u8, usize) callconv(.c) c_int, p_rng: ?*anyopaque) callconv(.c) void;
        extern fn mbedtls_ssl_conf_authmode(conf: *mbedtls_ssl_config, authmode: c_int) callconv(.c) void;
        extern fn mbedtls_ssl_conf_ca_chain(conf: *mbedtls_ssl_config, ca_chain: ?*mbedtls_x509_crt, ca_crl: ?*mbedtls_x509_crl) callconv(.c) void;
        extern fn mbedtls_ssl_conf_own_cert(conf: *mbedtls_ssl_config, own_cert: *mbedtls_x509_crt, pk_key: *mbedtls_pk_context) callconv(.c) c_int;
        extern fn mbedtls_ssl_conf_verify(conf: *mbedtls_ssl_config, f_vrfy: ?*const fn (?*anyopaque, *mbedtls_x509_crt, c_int, *u32) callconv(.c) c_int, p_vrfy: ?*anyopaque) callconv(.c) void;
        extern fn mbedtls_ssl_conf_ciphersuites(conf: *mbedtls_ssl_config, ciphersuites: [*]const c_int) callconv(.c) void;
        extern fn mbedtls_ssl_conf_alpn_protocols(conf: *mbedtls_ssl_config, protos: [*]?[*:0]const u8) callconv(.c) c_int;
        fn mbedtls_ssl_conf_min_tls_version(conf: *mbedtls_ssl_config, min_tls_version: c_int) void {
            if (comptime use_mbedtls) {
                if (mbedtls_version_get_number() < 0x03000000) {
                    const bytes: [*]u8 = @ptrCast(conf);
                    bytes[2] = @intCast((min_tls_version >> 8) & 0xFF);
                    bytes[3] = @intCast(min_tls_version & 0xFF);
                    return;
                }
            }
            conf.min_tls_version = min_tls_version;
        }
        fn mbedtls_ssl_conf_max_tls_version(conf: *mbedtls_ssl_config, max_tls_version: c_int) void {
            if (comptime use_mbedtls) {
                if (mbedtls_version_get_number() < 0x03000000) {
                    const bytes: [*]u8 = @ptrCast(conf);
                    bytes[0] = @intCast((max_tls_version >> 8) & 0xFF);
                    bytes[1] = @intCast(@min(max_tls_version & 0xFF, 3));
                    return;
                }
            }
            conf.max_tls_version = max_tls_version;
        }

        extern fn mbedtls_ssl_set_bio(
            ssl: *mbedtls_ssl_context,
            p_bio: ?*anyopaque,
            f_send: ?*const fn (?*anyopaque, [*]const u8, usize) callconv(.c) c_int,
            f_recv: ?*const fn (?*anyopaque, ?[*]u8, usize) callconv(.c) c_int,
            f_recv_timeout: ?*const anyopaque,
        ) callconv(.c) void;
        extern fn mbedtls_ssl_set_hostname(ssl: *mbedtls_ssl_context, hostname: ?[*:0]const u8) callconv(.c) c_int;
        extern fn mbedtls_ssl_handshake(ssl: *mbedtls_ssl_context) callconv(.c) c_int;
        extern fn mbedtls_ssl_read(ssl: *mbedtls_ssl_context, buf: [*]u8, len: usize) callconv(.c) c_int;
        extern fn mbedtls_ssl_write(ssl: *mbedtls_ssl_context, buf: [*]const u8, len: usize) callconv(.c) c_int;
        extern fn mbedtls_ssl_close_notify(ssl: *mbedtls_ssl_context) callconv(.c) c_int;
        extern fn mbedtls_ssl_get_bytes_avail(ssl: *const mbedtls_ssl_context) callconv(.c) usize;
        extern fn mbedtls_ssl_get_verify_result(ssl: *const mbedtls_ssl_context) callconv(.c) u32;
        extern fn mbedtls_ssl_get_alpn_protocol(ssl: *const mbedtls_ssl_context) callconv(.c) ?[*:0]const u8;
        extern fn mbedtls_ssl_get_version(ssl: *const mbedtls_ssl_context) callconv(.c) ?[*:0]const u8;
        extern fn mbedtls_ssl_get_ciphersuite(ssl: *const mbedtls_ssl_context) callconv(.c) ?[*:0]const u8;
        extern fn mbedtls_ssl_get_peer_cert(ssl: *const mbedtls_ssl_context) callconv(.c) ?*const mbedtls_x509_crt;
        extern fn mbedtls_ssl_ciphersuite_from_id(ciphersuite_id: c_int) callconv(.c) ?*const anyopaque;

        extern fn mbedtls_ssl_session_init(session: *mbedtls_ssl_session) callconv(.c) void;
        extern fn mbedtls_ssl_session_free(session: *mbedtls_ssl_session) callconv(.c) void;
        extern fn mbedtls_ssl_get_session(ssl: *const mbedtls_ssl_context, session: *mbedtls_ssl_session) callconv(.c) c_int;
        extern fn mbedtls_ssl_set_session(ssl: *mbedtls_ssl_context, session: *const mbedtls_ssl_session) callconv(.c) c_int;
        extern fn mbedtls_ssl_session_load(session: *mbedtls_ssl_session, buf: [*]const u8, len: usize) callconv(.c) c_int;
        extern fn mbedtls_ssl_session_save(session: *const mbedtls_ssl_session, buf: ?[*]u8, buf_len: usize, olen: *usize) callconv(.c) c_int;

        extern fn mbedtls_x509_crt_init(crt: *mbedtls_x509_crt) callconv(.c) void;
        extern fn mbedtls_x509_crt_free(crt: *mbedtls_x509_crt) callconv(.c) void;
        extern fn mbedtls_x509_crt_parse(chain: *mbedtls_x509_crt, buf: [*]const u8, buflen: usize) callconv(.c) c_int;
        extern fn mbedtls_x509_crt_parse_der(chain: *mbedtls_x509_crt, buf: [*]const u8, buflen: usize) callconv(.c) c_int;
        extern fn mbedtls_x509_crt_parse_file(chain: *mbedtls_x509_crt, path: [*:0]const u8) callconv(.c) c_int;
        extern fn mbedtls_x509_crt_parse_path(chain: *mbedtls_x509_crt, path: [*:0]const u8) callconv(.c) c_int;
        extern fn mbedtls_x509_crt_verify_info(buf: [*]u8, size: usize, prefix: [*:0]const u8, flags: u32) callconv(.c) c_int;

        extern fn mbedtls_x509_crl_init(crl: *mbedtls_x509_crl) callconv(.c) void;
        extern fn mbedtls_x509_crl_free(crl: *mbedtls_x509_crl) callconv(.c) void;
        extern fn mbedtls_x509_crl_parse_file(chain: *mbedtls_x509_crl, path: [*:0]const u8) callconv(.c) c_int;

        extern fn mbedtls_pk_init(ctx: *mbedtls_pk_context) callconv(.c) void;
        extern fn mbedtls_pk_free(ctx: *mbedtls_pk_context) callconv(.c) void;
        extern fn mbedtls_pk_can_do(ctx: *const mbedtls_pk_context, pk_type: c_int) callconv(.c) c_int;
        extern fn mbedtls_pk_parse_key(
            ctx: *mbedtls_pk_context,
            key: [*]const u8,
            keylen: usize,
            pwd: ?[*]const u8,
            pwdlen: usize,
            f_rng: ?*const fn (?*anyopaque, [*]u8, usize) callconv(.c) c_int,
            p_rng: ?*anyopaque,
        ) callconv(.c) c_int;
        extern fn mbedtls_pk_parse_keyfile(
            ctx: *mbedtls_pk_context,
            path: [*:0]const u8,
            password: ?[*:0]const u8,
            f_rng: ?*const fn (?*anyopaque, [*]u8, usize) callconv(.c) c_int,
            p_rng: ?*anyopaque,
        ) callconv(.c) c_int;
        extern fn mbedtls_pk_write_pubkey_der(ctx: *mbedtls_pk_context, buf: [*]u8, size: usize) callconv(.c) c_int;

        extern fn mbedtls_entropy_init(ctx: *mbedtls_entropy_context) callconv(.c) void;
        extern fn mbedtls_entropy_free(ctx: *mbedtls_entropy_context) callconv(.c) void;
        extern fn mbedtls_entropy_func(data: ?*anyopaque, output: [*]u8, len: usize) callconv(.c) c_int;

        extern fn mbedtls_ctr_drbg_init(ctx: *mbedtls_ctr_drbg_context) callconv(.c) void;
        extern fn mbedtls_ctr_drbg_free(ctx: *mbedtls_ctr_drbg_context) callconv(.c) void;
        extern fn mbedtls_ctr_drbg_seed(
            ctx: *mbedtls_ctr_drbg_context,
            f_entropy: ?*const fn (?*anyopaque, [*]u8, usize) callconv(.c) c_int,
            p_entropy: ?*anyopaque,
            custom: ?[*]const u8,
            len: usize,
        ) callconv(.c) c_int;
        extern fn mbedtls_ctr_drbg_random(p_rng: ?*anyopaque, output: [*]u8, output_len: usize) callconv(.c) c_int;

        extern fn mbedtls_sha256(input: [*]const u8, ilen: usize, output: [*]u8, is224: c_int) callconv(.c) c_int;
    };

    fn error_strerror(err: c_int, buf: []u8) [*:0]const u8 {
        if (buf.len == 0) return "";
        buf[0] = 0;
        if (comptime use_mbedtls) {
            mbed_ext.mbedtls_strerror(err, buf.ptr, buf.len);
        }
        return @ptrCast(buf.ptr);
    }

    pub fn mapBioWriteResult(result: CURLcode, nwritten: usize) c_int {
        if (result == CURLE_AGAIN) return MBEDTLS_ERR_SSL_WANT_WRITE;
        return if (result != CURLE_OK) -1 else @intCast(nwritten);
    }

    pub fn mapBioReadResult(result: CURLcode, nread: usize) c_int {
        if (result == CURLE_AGAIN) return MBEDTLS_ERR_SSL_WANT_READ;
        return if (result != CURLE_OK) -1 else @intCast(nread);
    }

    pub fn mbedtls_bio_cf_write(bio: ?*anyopaque, buf: [*]const u8, blen: usize) callconv(.c) c_int {
        const cf: *CurlCfilter = @ptrCast(@alignCast(bio orelse return 0));
        const connssl: *SslConnectData = @ptrCast(@alignCast(cf.ctx orelse return 0));
        const data = connssl.call_data orelse return 0;
        var nwritten: usize = 0;
        const result = c_ext.Curl_conn_cf_send(cf.next, data, buf, blen, false, &nwritten);
        c_ext.Curl_trc_cf_infof(data, cf, "mbedtls_bio_cf_out_write(len=%zu) -> %d, %zu", blen, result, nwritten);
        return mapBioWriteResult(result, nwritten);
    }

    pub fn mbedtls_bio_cf_read(bio: ?*anyopaque, buf: ?[*]u8, blen: usize) callconv(.c) c_int {
        const cf: *CurlCfilter = @ptrCast(@alignCast(bio orelse return 0));
        const connssl: *SslConnectData = @ptrCast(@alignCast(cf.ctx orelse return 0));
        const data = connssl.call_data orelse return 0;
        const out_buf = buf orelse return 0;
        var nread: usize = 0;
        const result = c_ext.Curl_conn_cf_recv(cf.next, data, out_buf, blen, &nread);
        c_ext.Curl_trc_cf_infof(data, cf, "mbedtls_bio_cf_in_read(len=%zu) -> %d, %zu", blen, result, nread);
        return mapBioReadResult(result, nread);
    }

    pub fn mbed_set_ssl_version_min_max(
        data: ?*CurlEasy,
        backend: *MbedSslBackendData,
        conn_config: *const SslFilterConfig,
    ) CURLcode {
        var ver_min: c_int = MBEDTLS_SSL_VERSION_TLS1_2;
        var ver_max: c_int = MBEDTLS_SSL_VERSION_TLS1_3;

        switch (conn_config.version) {
            CURL_SSLVERSION_DEFAULT,
            CURL_SSLVERSION_TLSv1,
            CURL_SSLVERSION_TLSv1_0,
            CURL_SSLVERSION_TLSv1_1,
            CURL_SSLVERSION_TLSv1_2,
            => {
                ver_min = MBEDTLS_SSL_VERSION_TLS1_2;
            },
            CURL_SSLVERSION_TLSv1_3 => {
                ver_min = MBEDTLS_SSL_VERSION_TLS1_3;
            },
            CURL_SSLVERSION_SSLv2, CURL_SSLVERSION_SSLv3 => {
                if (data) |d| c_ext.Curl_failf(d, "Not supported SSL version");
                return CURLE_NOT_BUILT_IN;
            },
            else => {
                if (data) |d| c_ext.Curl_failf(d, "mbedTLS: unsupported minimum TLS version value: %x", @as(c_uint, conn_config.version));
                return CURLE_SSL_CONNECT_ERROR;
            },
        }

        switch (conn_config.version_max) {
            CURL_SSLVERSION_MAX_DEFAULT,
            CURL_SSLVERSION_MAX_NONE,
            CURL_SSLVERSION_MAX_TLSv1_3,
            => {
                ver_max = MBEDTLS_SSL_VERSION_TLS1_3;
            },
            MBED_SSLVERSION_MAX_TLSv1_2 => {
                ver_max = MBEDTLS_SSL_VERSION_TLS1_2;
            },
            CURL_SSLVERSION_MAX_TLSv1_1,
            CURL_SSLVERSION_MAX_TLSv1_0,
            => {
                if (data) |d| c_ext.Curl_failf(d, "mbedTLS: unsupported maximum TLS version value");
                return CURLE_SSL_CONNECT_ERROR;
            },
            else => {
                if (data) |d| c_ext.Curl_failf(d, "mbedTLS: unsupported maximum TLS version value");
                return CURLE_SSL_CONNECT_ERROR;
            },
        }

        if (ver_min > ver_max) {
            if (data) |d| c_ext.Curl_failf(d, "mbedTLS: minimum TLS version exceeds maximum TLS version");
            return CURLE_SSL_CONNECT_ERROR;
        }

        backend.config.min_tls_version = ver_min;
        backend.config.max_tls_version = ver_max;
        return CURLE_OK;
    }

    fn mbed_cipher_suite_walk_str(str: *?[*:0]const u8, end: *?[*:0]const u8) u16 {
        var id = vtls_core.Curl_cipher_suite_walk_str(str, end);
        if (id == 0) {
            if (str.*) |s| {
                if (end.*) |e| {
                    const len = @intFromPtr(e) - @intFromPtr(s);
                    const ecjpake = "TLS_ECJPAKE_WITH_AES_128_CCM_8";
                    if (len == ecjpake.len and primitives.curl_strnequal(ecjpake, s, len) != 0) {
                        id = MBEDTLS_TLS_ECJPAKE_WITH_AES_128_CCM_8;
                    }
                }
            }
        }
        return id;
    }

    fn validateCiphersuiteId(id: c_int) bool {
        if (comptime use_mbedtls) {
            return mbed_ext.mbedtls_ssl_ciphersuite_from_id(id) != null;
        }
        return id != 0;
    }

    fn configureCiphersuites(conf: *mbedtls_ssl_config, ciphersuites: [*]const c_int) void {
        if (comptime use_mbedtls) {
            mbed_ext.mbedtls_ssl_conf_ciphersuites(conf, ciphersuites);
        }
    }

    fn countCipherTokens(ciphers: [*:0]const u8) usize {
        var count: usize = 1;
        var i: usize = 0;
        while (ciphers[i] != 0) : (i += 1) {
            switch (ciphers[i]) {
                ',', ':', ';', ' ', '\t' => count += 1,
                else => {},
            }
        }
        return count;
    }

    pub fn mbed_set_selected_ciphers(
        data: ?*CurlEasy,
        backend: *MbedSslBackendData,
        ciphers12: ?[*:0]const u8,
        ciphers13: ?[*:0]const u8,
    ) CURLcode {
        if (ciphers12 == null and ciphers13 == null) return CURLE_OK;

        const max_entries = (if (ciphers13) |c13| countCipherTokens(c13) else 0) +
            (if (ciphers12) |c12| countCipherTokens(c12) else 0);

        const raw = mem.calloc(max_entries + 1, @sizeOf(c_int)) orelse return CURLE_OUT_OF_MEMORY;
        const selected: [*]c_int = @ptrCast(@alignCast(raw));
        var count: usize = 0;

        const lists = [2]?[*:0]const u8{ ciphers13, ciphers12 };
        for (lists) |maybe_list| {
            const list = maybe_list orelse continue;
            var ptr: ?[*:0]const u8 = list;
            var end: ?[*:0]const u8 = null;

            while (ptr != null and ptr.?[0] != 0) : (ptr = end) {
                var id = mbed_cipher_suite_walk_str(&ptr, &end);
                if (id != 0 and !validateCiphersuiteId(@intCast(id))) {
                    id = 0;
                }
                if (id == 0) {
                    if (ptr != null and ptr.?[0] != 0 and data != null) {
                        const tok_len: c_int = if (end) |e| @intCast(@intFromPtr(e) - @intFromPtr(ptr.?)) else 0;
                        c_ext.Curl_infof(data, "mbedTLS: unknown cipher in list: \"%.*s\"", tok_len, ptr.?);
                    }
                    continue;
                }

                var dup = false;
                for (0..count) |i| {
                    if (selected[i] == @as(c_int, id)) {
                        dup = true;
                        break;
                    }
                }
                if (dup) continue;

                selected[count] = @intCast(id);
                count += 1;
            }
        }

        selected[count] = 0;
        if (count == 0) {
            mem.free(raw);
            if (data) |d| c_ext.Curl_failf(d, "mbedTLS: no supported cipher in list");
            return CURLE_SSL_CIPHER;
        }

        if (backend.ciphersuites) |old| {
            mem.free(old);
        }
        backend.ciphersuites = selected;
        configureCiphersuites(&backend.config, selected);
        return CURLE_OK;
    }

    fn mbed_dump_cert_info(data: ?*CurlEasy, crt: *const mbedtls_x509_crt) void {
        _ = data;
        _ = crt;
    }

    fn crtNext(crt: *const mbedtls_x509_crt) ?*const mbedtls_x509_crt {
        if (comptime use_mbedtls) {
            if (mbed_ext.mbedtls_version_get_number() < 0x03000000) {
                const base: [*]const u8 = @ptrCast(crt);
                const next_ptr: *align(8) const ?*const mbedtls_x509_crt = @ptrCast(@alignCast(base + 608));
                return next_ptr.*;
            }
        }
        return crt.next;
    }

    fn sslTlsVersion(ssl: *const mbedtls_ssl_context) c_int {
        if (comptime use_mbedtls) {
            if (mbed_ext.mbedtls_version_get_number() < 0x03000000) {
                return MBEDTLS_SSL_VERSION_TLS1_2;
            }
        }
        return ssl.tls_version;
    }

    fn mbed_extract_certinfo(data: ?*CurlEasy, crt_opt: ?*const mbedtls_x509_crt) void {
        var cur = crt_opt;
        var cert_count: c_int = 0;
        while (cur != null and cert_count <= MAX_ALLOWED_CERT_AMOUNT) : (cur = crtNext(cur.?)) {
            cert_count += 1;
        }
        if (cert_count == 0) return;
        if (cert_count > MAX_ALLOWED_CERT_AMOUNT) {
            c_ext.Curl_infof(data, "More certificates than allowed (%d), skipping certinfo", MAX_ALLOWED_CERT_AMOUNT);
            return;
        }

        var result = vtls_impl.Curl_ssl_init_certinfo(data, cert_count);
        var i: c_int = 0;
        cur = crt_opt;
        while (result == CURLE_OK and cur != null) : ({
            i += 1;
            cur = crtNext(cur.?);
        }) {
            if (cur.?.raw.p) |raw_p| {
                result = vtls_scache_asn1.Curl_extract_certinfo_zig(
                    data,
                    i,
                    raw_p,
                    raw_p + cur.?.raw.len,
                    true,
                    @ptrCast(&vtls_impl.Curl_ssl_push_certinfo_len),
                );
            }
        }
    }

    fn mbed_verify_cb(ptr: ?*anyopaque, crt: *mbedtls_x509_crt, depth: c_int, flags: *u32) callconv(.c) c_int {
        const cf: *CurlCfilter = @ptrCast(@alignCast(ptr orelse return 0));
        const conn_config = vtls_impl.Curl_ssl_cf_get_filter_config(cf) orelse return 0;
        const connssl: *SslConnectData = @ptrCast(@alignCast(cf.ctx orelse return 0));
        const data = connssl.call_data;

        if (depth == 0) {
            if (c_ext.Curl_trc_is_verbose_fn(data)) {
                mbed_dump_cert_info(data, crt);
            }
            if (c_ext.Curl_vtls_acc_ssl_certinfo(data)) {
                mbed_extract_certinfo(data, crt);
            }
        }

        if (!conn_config.verifypeer()) {
            flags.* &= MBEDTLS_X509_BADCERT_CN_MISMATCH;
        }
        if (!conn_config.verifyhost()) {
            flags.* &= ~MBEDTLS_X509_BADCERT_CN_MISMATCH;
        }

        if (flags.* != 0) {
            var buf: [128]u8 = @splat(0);
            _ = mbed_ext.mbedtls_x509_crt_verify_info(&buf, buf.len, "", flags.*);
            c_ext.Curl_failf(data, "mbedTLS: %s", @as([*:0]const u8, @ptrCast(&buf)));
        }

        return 0;
    }

    fn dupNullTerminatedBlob(blob_data: [*]const u8, len: usize) ?[*]u8 {
        const buf = mem.malloc(len + 1) orelse return null;
        if (len > 0) {
            @memcpy(buf[0..len], blob_data[0..len]);
        }
        buf[len] = 0;
        return buf;
    }

    fn mbed_load_cacert(cf: *CurlCfilter, data: ?*CurlEasy) CURLcode {
        const connssl: *SslConnectData = @ptrCast(@alignCast(cf.ctx orelse return CURLE_SSL_CONNECT_ERROR));
        const backend: *MbedSslBackendData = @ptrCast(@alignCast(connssl.backend orelse return CURLE_SSL_CONNECT_ERROR));
        const conn_config = vtls_impl.Curl_ssl_cf_get_filter_config(cf) orelse return CURLE_SSL_CONNECT_ERROR;
        const ca_info_blob = conn_config.ca_info_blob;
        const ssl_cafile: ?[*:0]const u8 = if (ca_info_blob != null) null else conn_config.CAfile;
        const verifypeer = conn_config.verifypeer();
        const ssl_capath: ?[*:0]const u8 = conn_config.CApath;
        const ssl_cert_type: ?[*:0]const u8 = conn_config.cert_type;
        var errorbuf: [128]u8 = @splat(0);

        mbed_ext.mbedtls_x509_crt_init(&backend.cacert);

        if (ca_info_blob != null and verifypeer) {
            const blob = ca_info_blob.?;
            const blob_ptr: [*]const u8 = @ptrCast(blob.data orelse return CURLE_SSL_CERTPROBLEM);
            var ret: c_int = -1;
            const is_der = ssl_cert_type != null and primitives.curl_strequal(ssl_cert_type, "DER") != 0;
            if (is_der or (blob.len > 0 and blob_ptr[blob.len - 1] == 0)) {
                ret = mbed_ext.mbedtls_x509_crt_parse(&backend.cacert, blob_ptr, blob.len);
            } else {
                const newblob = dupNullTerminatedBlob(blob_ptr, blob.len) orelse return CURLE_OUT_OF_MEMORY;
                defer mem.free(newblob);
                ret = mbed_ext.mbedtls_x509_crt_parse(&backend.cacert, newblob, blob.len + 1);
            }

            if (ret < 0) {
                c_ext.Curl_failf(
                    data,
                    "mbedTLS: error importing CA cert blob: (-0x%04X) %s",
                    @as(c_uint, @intCast(-ret)),
                    error_strerror(ret, &errorbuf),
                );
                return CURLE_SSL_CERTPROBLEM;
            }
        }

        if (ssl_cafile != null and verifypeer) {
            const ret = mbed_ext.mbedtls_x509_crt_parse_file(&backend.cacert, ssl_cafile.?);
            if (ret < 0) {
                c_ext.Curl_failf(
                    data,
                    "mbedTLS: error reading CA cert file %s: (-0x%04X) %s",
                    ssl_cafile.?,
                    @as(c_uint, @intCast(-ret)),
                    error_strerror(ret, &errorbuf),
                );
                return CURLE_SSL_CACERT_BADFILE;
            }
        }

        if (ssl_capath) |capath| {
            const ret = mbed_ext.mbedtls_x509_crt_parse_path(&backend.cacert, capath);
            if (ret < 0) {
                c_ext.Curl_failf(
                    data,
                    "mbedTLS: error reading CA cert path %s: (-0x%04X) %s",
                    capath,
                    @as(c_uint, @intCast(-ret)),
                    error_strerror(ret, &errorbuf),
                );
                if (verifypeer) return CURLE_SSL_CACERT_BADFILE;
            }
        }

        return CURLE_OK;
    }

    fn mbed_load_clicert(cf: *CurlCfilter, data: ?*CurlEasy) CURLcode {
        const connssl: *SslConnectData = @ptrCast(@alignCast(cf.ctx orelse return CURLE_SSL_CONNECT_ERROR));
        const backend: *MbedSslBackendData = @ptrCast(@alignCast(connssl.backend orelse return CURLE_SSL_CONNECT_ERROR));
        const conn_config = vtls_impl.Curl_ssl_cf_get_filter_config(cf) orelse return CURLE_SSL_CONNECT_ERROR;
        const ssl_cert: ?[*:0]const u8 = conn_config.clientcert;
        const ssl_cert_blob = conn_config.cert_blob;
        const ssl_cert_type: ?[*:0]const u8 = conn_config.cert_type;
        var errorbuf: [128]u8 = @splat(0);

        mbed_ext.mbedtls_x509_crt_init(&backend.clicert);

        if (ssl_cert) |cert_file| {
            const ret = mbed_ext.mbedtls_x509_crt_parse_file(&backend.clicert, cert_file);
            if (ret != 0) {
                c_ext.Curl_failf(
                    data,
                    "mbedTLS: error reading client cert file %s: (-0x%04X) %s",
                    cert_file,
                    @as(c_uint, @intCast(-ret)),
                    error_strerror(ret, &errorbuf),
                );
                return CURLE_SSL_CERTPROBLEM;
            }
        }

        if (ssl_cert_blob) |blob| {
            const blob_ptr: [*]const u8 = @ptrCast(blob.data orelse return CURLE_SSL_CERTPROBLEM);
            var ret: c_int = -1;
            const is_der = ssl_cert_type != null and primitives.curl_strequal(ssl_cert_type, "DER") != 0;
            if (is_der or (blob.len > 0 and blob_ptr[blob.len - 1] == 0)) {
                ret = mbed_ext.mbedtls_x509_crt_parse(&backend.clicert, blob_ptr, blob.len);
            } else {
                const newblob = dupNullTerminatedBlob(blob_ptr, blob.len) orelse return CURLE_OUT_OF_MEMORY;
                defer mem.free(newblob);
                ret = mbed_ext.mbedtls_x509_crt_parse(&backend.clicert, newblob, blob.len + 1);
            }

            if (ret != 0) {
                c_ext.Curl_failf(
                    data,
                    "mbedTLS: error reading client cert blob: (-0x%04X) %s",
                    @as(c_uint, @intCast(-ret)),
                    error_strerror(ret, &errorbuf),
                );
                return CURLE_SSL_CERTPROBLEM;
            }
        }

        return CURLE_OK;
    }

    fn mbed_load_privkey(cf: *CurlCfilter, data: ?*CurlEasy) CURLcode {
        const connssl: *SslConnectData = @ptrCast(@alignCast(cf.ctx orelse return CURLE_SSL_CONNECT_ERROR));
        const backend: *MbedSslBackendData = @ptrCast(@alignCast(connssl.backend orelse return CURLE_SSL_CONNECT_ERROR));
        const conn_config = vtls_impl.Curl_ssl_cf_get_filter_config(cf) orelse return CURLE_SSL_CONNECT_ERROR;
        var errorbuf: [128]u8 = @splat(0);

        mbed_ext.mbedtls_pk_init(&backend.pk);

        if (conn_config.key != null or conn_config.key_blob != null) {
            if (conn_config.key) |key_file| {
                var ret = mbed_ext.mbedtls_pk_parse_keyfile(
                    &backend.pk,
                    key_file,
                    conn_config.key_passwd,
                    mbed_ext.mbedtls_ctr_drbg_random,
                    &backend.ctr_drbg,
                );
                if (ret == 0 and
                    mbed_ext.mbedtls_pk_can_do(&backend.pk, MBEDTLS_PK_RSA) == 0 and
                    mbed_ext.mbedtls_pk_can_do(&backend.pk, MBEDTLS_PK_ECKEY) == 0)
                {
                    ret = MBEDTLS_ERR_PK_TYPE_MISMATCH;
                }
                if (ret != 0) {
                    c_ext.Curl_failf(
                        data,
                        "mbedTLS: error reading private key %s: (-0x%04X) %s",
                        key_file,
                        @as(c_uint, @intCast(-ret)),
                        error_strerror(ret, &errorbuf),
                    );
                    return CURLE_SSL_CERTPROBLEM;
                }
            } else if (conn_config.key_blob) |blob| {
                const blob_ptr: [*]const u8 = @ptrCast(blob.data orelse return CURLE_SSL_CERTPROBLEM);
                const passwd: ?[*:0]const u8 = conn_config.key_passwd;
                const pwd_ptr: ?[*]const u8 = if (passwd) |p| p else null;
                const pwd_len: usize = if (passwd) |p| std.mem.len(p) else 0;
                const is_der = conn_config.key_type != null and primitives.curl_strequal(conn_config.key_type, "DER") != 0;
                const newblob = dupNullTerminatedBlob(blob_ptr, blob.len) orelse return CURLE_OUT_OF_MEMORY;
                defer {
                    mem.secureZero(newblob, blob.len + 1);
                    mem.freeSized(newblob, blob.len + 1);
                }
                const keylen: usize = if (is_der) blob.len else blob.len + 1;

                var ret = mbed_ext.mbedtls_pk_parse_key(
                    &backend.pk,
                    newblob,
                    keylen,
                    pwd_ptr,
                    pwd_len,
                    mbed_ext.mbedtls_ctr_drbg_random,
                    &backend.ctr_drbg,
                );
                if (ret == 0 and
                    mbed_ext.mbedtls_pk_can_do(&backend.pk, MBEDTLS_PK_RSA) == 0 and
                    mbed_ext.mbedtls_pk_can_do(&backend.pk, MBEDTLS_PK_ECKEY) == 0)
                {
                    ret = MBEDTLS_ERR_PK_TYPE_MISMATCH;
                }
                if (ret != 0) {
                    c_ext.Curl_failf(
                        data,
                        "mbedTLS: error parsing private key: (-0x%04X) %s",
                        @as(c_uint, @intCast(-ret)),
                        error_strerror(ret, &errorbuf),
                    );
                    return CURLE_SSL_CERTPROBLEM;
                }
            }
        }

        return CURLE_OK;
    }

    fn mbed_load_crl(cf: *CurlCfilter, data: ?*CurlEasy) CURLcode {
        const connssl: *SslConnectData = @ptrCast(@alignCast(cf.ctx orelse return CURLE_SSL_CONNECT_ERROR));
        const backend: *MbedSslBackendData = @ptrCast(@alignCast(connssl.backend orelse return CURLE_SSL_CONNECT_ERROR));
        const conn_config = vtls_impl.Curl_ssl_cf_get_filter_config(cf) orelse return CURLE_SSL_CONNECT_ERROR;
        var errorbuf: [128]u8 = @splat(0);

        mbed_ext.mbedtls_x509_crl_init(&backend.crl);

        if (conn_config.CRLfile) |ssl_crlfile| {
            const ret = mbed_ext.mbedtls_x509_crl_parse_file(&backend.crl, ssl_crlfile);
            if (ret != 0) {
                c_ext.Curl_failf(
                    data,
                    "mbedTLS: error reading CRL file %s: (-0x%04X) %s",
                    ssl_crlfile,
                    @as(c_uint, @intCast(-ret)),
                    error_strerror(ret, &errorbuf),
                );
                return CURLE_SSL_CRL_BADFILE;
            }
        }

        return CURLE_OK;
    }

    fn mbed_apply_session(cf: *CurlCfilter, data: ?*CurlEasy, sc_session: ?*CurlSslSession) bool {
        const connssl: *SslConnectData = @ptrCast(@alignCast(cf.ctx orelse return false));
        const backend: *MbedSslBackendData = @ptrCast(@alignCast(connssl.backend orelse return false));
        const sess = sc_session orelse return false;
        const sdata: [*]const u8 = @ptrCast(sess.sdata orelse return false);
        if (sess.sdata_len == 0) return false;

        var session: mbedtls_ssl_session = .{};
        mbed_ext.mbedtls_ssl_session_init(&session);
        defer mbed_ext.mbedtls_ssl_session_free(&session);

        var ret = mbed_ext.mbedtls_ssl_session_load(&session, sdata, sess.sdata_len);
        if (ret != 0) {
            c_ext.Curl_failf(data, "SSL session error loading: -0x%x", @as(c_uint, @intCast(-ret)));
            return false;
        }
        ret = mbed_ext.mbedtls_ssl_set_session(&backend.ssl, &session);
        if (ret != 0) {
            c_ext.Curl_failf(data, "SSL session error setting: -0x%x", @as(c_uint, @intCast(-ret)));
            return false;
        }
        c_ext.Curl_infof(data, "SSL reusing session ID");
        return true;
    }

    fn mbed_new_session(cf: *CurlCfilter, data: ?*CurlEasy) CURLcode {
        const connssl: *SslConnectData = @ptrCast(@alignCast(cf.ctx orelse return CURLE_SSL_CONNECT_ERROR));
        const backend: *MbedSslBackendData = @ptrCast(@alignCast(connssl.backend orelse return CURLE_SSL_CONNECT_ERROR));
        const conn_config = vtls_impl.Curl_ssl_cf_get_filter_config(cf);
        const scache_key = connssl.peer.scache_key orelse return CURLE_OK;

        var scache: ?*CurlSslScache = null;
        var has_share_scache = false;
        var trc_feat: ?*CurlTrcFeat = null;
        c_ext.Curl_vtls_acc_scache_params(data, &scache, &has_share_scache, &trc_feat);
        if (!vtls_scache_asn1.Curl_ssl_scache_use_zig(data, scache, conn_config)) {
            return CURLE_OK;
        }

        var session: mbedtls_ssl_session = .{};
        mbed_ext.mbedtls_ssl_session_init(&session);
        var ret = mbed_ext.mbedtls_ssl_get_session(&backend.ssl, &session);
        const msession_alloced = (ret != MBEDTLS_ERR_SSL_ALLOC_FAILED);
        defer if (msession_alloced) mbed_ext.mbedtls_ssl_session_free(&session);

        if (ret != 0) {
            c_ext.Curl_failf(data, "mbedtls_ssl_get_session returned -0x%x", @as(c_uint, @intCast(-ret)));
            return CURLE_SSL_CONNECT_ERROR;
        }

        var slen: usize = 0;
        _ = mbed_ext.mbedtls_ssl_session_save(&session, null, 0, &slen);
        if (slen == 0) {
            c_ext.Curl_failf(data, "failed to serialize session: length is 0");
            return CURLE_OK;
        }

        const sdata = mem.malloc(slen) orelse return CURLE_OUT_OF_MEMORY;
        ret = mbed_ext.mbedtls_ssl_session_save(&session, sdata, slen, &slen);
        if (ret != 0) {
            mem.secureZero(sdata, slen);
            mem.freeSized(sdata, slen);
            c_ext.Curl_failf(data, "failed to serialize session: -0x%x", @as(c_uint, @intCast(-ret)));
            return CURLE_OK;
        }

        const ietf_tls_id = sslTlsVersion(&backend.ssl);
        var sc_session: ?*CurlSslSession = null;
        var result = vtls_scache_asn1.Curl_ssl_session_create(
            sdata,
            slen,
            ietf_tls_id,
            connssl.negotiated_alpn,
            0,
            0,
            &sc_session,
        );
        if (result == CURLE_OK) {
            result = vtls_scache_asn1.Curl_ssl_scache_put_zig(
                cf,
                data,
                scache,
                has_share_scache,
                conn_config,
                trc_feat,
                scache_key,
                sc_session,
            );
        } else {
            vtls_scache_asn1.Curl_ssl_session_destroy(sc_session);
        }
        return result;
    }

    fn mbed_configure_ssl(cf: *CurlCfilter, data: ?*CurlEasy) CURLcode {
        const connssl: *SslConnectData = @ptrCast(@alignCast(cf.ctx orelse return CURLE_SSL_CONNECT_ERROR));
        const backend: *MbedSslBackendData = @ptrCast(@alignCast(connssl.backend orelse return CURLE_SSL_CONNECT_ERROR));
        const conn_config = vtls_impl.Curl_ssl_cf_get_filter_config(cf) orelse return CURLE_SSL_CONNECT_ERROR;
        var errorbuf: [128]u8 = @splat(0);

        if (connssl.peer.origin) |orig| {
            c_ext.Curl_infof(data, "mbedTLS: Connecting to %s:%d", orig.hostname, @as(c_int, orig.port));
        }

        var result = mbed_set_ssl_version_min_max(data, backend, conn_config);
        if (result != CURLE_OK) return result;
        const ver_min = backend.config.min_tls_version;
        const ver_max = backend.config.max_tls_version;

        mbed_ext.mbedtls_ssl_config_init(&backend.config);
        var ret = mbed_ext.mbedtls_ssl_config_defaults(
            &backend.config,
            MBEDTLS_SSL_IS_CLIENT,
            MBEDTLS_SSL_TRANSPORT_STREAM,
            MBEDTLS_SSL_PRESET_DEFAULT,
        );
        if (ret != 0) {
            c_ext.Curl_failf(data, "mbedTLS: ssl_config failed");
            return CURLE_SSL_CONNECT_ERROR;
        }

        mbed_ext.mbedtls_ssl_conf_verify(&backend.config, mbed_verify_cb, cf);
        mbed_ext.mbedtls_ssl_conf_authmode(&backend.config, MBEDTLS_SSL_VERIFY_OPTIONAL);

        mbed_ext.mbedtls_ssl_init(&backend.ssl);
        backend.flags.initialized = true;

        mbed_ext.mbedtls_ssl_conf_min_tls_version(&backend.config, ver_min);
        mbed_ext.mbedtls_ssl_conf_max_tls_version(&backend.config, ver_max);

        mbed_ext.mbedtls_ssl_conf_rng(&backend.config, mbed_ext.mbedtls_ctr_drbg_random, &backend.ctr_drbg);

        ret = mbed_ext.mbedtls_ssl_setup(&backend.ssl, &backend.config);
        if (ret != 0) {
            c_ext.Curl_failf(
                data,
                "mbedTLS: ssl_setup failed: (-0x%04X) %s",
                @as(c_uint, @intCast(-ret)),
                error_strerror(ret, &errorbuf),
            );
            return CURLE_SSL_CONNECT_ERROR;
        }

        mbed_ext.mbedtls_ssl_set_bio(&backend.ssl, cf, mbedtls_bio_cf_write, mbedtls_bio_cf_read, null);

        if (conn_config.cipher_list != null or conn_config.cipher_list13 != null) {
            result = mbed_set_selected_ciphers(data, backend, conn_config.cipher_list, conn_config.cipher_list13);
            if (result != CURLE_OK) {
                c_ext.Curl_failf(data, "mbedTLS: failed to set cipher suites");
                return result;
            }
        }

        if (connssl.peer.scache_key) |scache_key| {
            var scache: ?*CurlSslScache = null;
            var has_share_scache = false;
            var trc_feat: ?*CurlTrcFeat = null;
            c_ext.Curl_vtls_acc_scache_params(data, &scache, &has_share_scache, &trc_feat);
            if (vtls_scache_asn1.Curl_ssl_scache_use_zig(data, scache, conn_config)) {
                var sc_session: ?*CurlSslSession = null;
                const sresult = vtls_scache_asn1.Curl_ssl_scache_take_zig(
                    cf,
                    data,
                    scache,
                    has_share_scache,
                    conn_config,
                    trc_feat,
                    scache_key,
                    &sc_session,
                );
                if (sresult == CURLE_OK and sc_session != null) {
                    _ = mbed_apply_session(cf, data, sc_session);
                }
                vtls_scache_asn1.Curl_ssl_scache_return_zig(
                    cf,
                    data,
                    scache,
                    has_share_scache,
                    conn_config,
                    trc_feat,
                    scache_key,
                    sc_session,
                );
            }
        }

        mbed_ext.mbedtls_ssl_conf_ca_chain(&backend.config, &backend.cacert, &backend.crl);

        if (conn_config.key != null or conn_config.key_blob != null or
            conn_config.clientcert != null or conn_config.cert_blob != null)
        {
            _ = mbed_ext.mbedtls_ssl_conf_own_cert(&backend.config, &backend.clicert, &backend.pk);
            backend.flags.pkt_enc_key_set = true;
        }

        const hostname: ?[*:0]const u8 = if (connssl.peer.sni) |sni|
            sni
        else if (connssl.peer.origin) |orig|
            orig.hostname
        else
            null;
        if (mbed_ext.mbedtls_ssl_set_hostname(&backend.ssl, hostname) != 0) {
            c_ext.Curl_failf(data, "Failed to set SNI");
            return CURLE_SSL_CONNECT_ERROR;
        }

        if (connssl.alpn) |alpn| {
            var i: usize = 0;
            while (i < alpn.count and i < ALPN_ENTRIES_MAX) : (i += 1) {
                backend.protocols[i] = @ptrCast(&alpn.entries[i]);
            }
            backend.protocols[i] = null;
            if (mbed_ext.mbedtls_ssl_conf_alpn_protocols(&backend.config, &backend.protocols) != 0) {
                c_ext.Curl_failf(data, "Failed setting ALPN protocols");
                return CURLE_SSL_CONNECT_ERROR;
            }
            var proto: AlpnProtoBuf = undefined;
            _ = vtls_impl.Curl_alpn_to_proto_str(&proto, alpn);
            c_ext.Curl_infof(data, "ALPN: curl offers %s", @as([*:0]const u8, @ptrCast(&proto.data)));
        }

        var fsslctx: ?*const anyopaque = null;
        var fsslctxp: ?*anyopaque = null;
        if (c_ext.Curl_vtls_acc_ssl_fsslctx(data, &fsslctx, &fsslctxp)) {
            const cb: *const fn (?*CurlEasy, ?*anyopaque, ?*anyopaque) callconv(.c) CURLcode = @ptrCast(@alignCast(fsslctx.?));
            result = cb(data, &backend.config, fsslctxp);
            if (result != CURLE_OK) {
                c_ext.Curl_failf(data, "error signaled by SSL ctx callback");
                return result;
            }
        }

        return CURLE_OK;
    }

    fn mbed_connect_step1(cf: *CurlCfilter, data: ?*CurlEasy) CURLcode {
        const connssl: *SslConnectData = @ptrCast(@alignCast(cf.ctx orelse return CURLE_SSL_CONNECT_ERROR));
        const backend: *MbedSslBackendData = @ptrCast(@alignCast(connssl.backend orelse return CURLE_SSL_CONNECT_ERROR));
        const conn_config = vtls_impl.Curl_ssl_cf_get_filter_config(cf) orelse return CURLE_SSL_CONNECT_ERROR;

        if (conn_config.version == CURL_SSLVERSION_SSLv2 or conn_config.version == CURL_SSLVERSION_SSLv3) {
            c_ext.Curl_failf(data, "Not supported SSL version");
            return CURLE_NOT_BUILT_IN;
        }

        mbed_ext.mbedtls_ctr_drbg_init(&backend.ctr_drbg);
        mbed_ext.mbedtls_entropy_init(&backend.entropy);
        const custom = "curl";
        const seed_ret = mbed_ext.mbedtls_ctr_drbg_seed(
            &backend.ctr_drbg,
            mbed_ext.mbedtls_entropy_func,
            &backend.entropy,
            custom.ptr,
            custom.len,
        );
        if (seed_ret != 0) {
            var errorbuf: [128]u8 = @splat(0);
            c_ext.Curl_failf(
                data,
                "mbedtls_ctr_drbg_seed returned (-0x%04X) %s",
                @as(c_uint, @intCast(-seed_ret)),
                error_strerror(seed_ret, &errorbuf),
            );
            return CURLE_SSL_CONNECT_ERROR;
        }

        var result = mbed_load_cacert(cf, data);
        if (result == CURLE_OK) result = mbed_load_clicert(cf, data);
        if (result == CURLE_OK) result = mbed_load_privkey(cf, data);
        if (result == CURLE_OK) result = mbed_load_crl(cf, data);
        if (result == CURLE_OK) result = mbed_configure_ssl(cf, data);
        if (result != CURLE_OK) return result;

        connssl.connecting_state = ssl_connect_2;
        return CURLE_OK;
    }

    fn mbed_connect_step2(cf: *CurlCfilter, data: ?*CurlEasy) CURLcode {
        const connssl: *SslConnectData = @ptrCast(@alignCast(cf.ctx orelse return CURLE_SSL_CONNECT_ERROR));
        const backend: *MbedSslBackendData = @ptrCast(@alignCast(connssl.backend orelse return CURLE_SSL_CONNECT_ERROR));
        const conn_config = vtls_impl.Curl_ssl_cf_get_filter_config(cf) orelse return CURLE_SSL_CONNECT_ERROR;

        var ret: c_int = 0;
        while (true) {
            ret = mbed_ext.mbedtls_ssl_handshake(&backend.ssl);
            if (ret == MBEDTLS_ERR_SSL_RECEIVED_NEW_SESSION_TICKET) {
                const sres = mbed_new_session(cf, data);
                if (sres != CURLE_OK) return sres;
                continue;
            }
            break;
        }

        if (ret == MBEDTLS_ERR_SSL_WANT_READ) {
            connssl.io_need = CURL_SSL_IO_NEED_RECV;
            return CURLE_OK;
        } else if (ret == MBEDTLS_ERR_SSL_WANT_WRITE) {
            connssl.io_need = CURL_SSL_IO_NEED_SEND;
            return CURLE_OK;
        }

        const verify_result = mbed_ext.mbedtls_ssl_get_verify_result(&backend.ssl);
        if (vtls_impl.Curl_ssl_cf_get_easy_config(cf, data)) |ssl_config| {
            ssl_config.certverifyresult = @intCast(verify_result);
        }

        if (ret == MBEDTLS_ERR_X509_CERT_VERIFY_FAILED or
            (verify_result != 0 and (conn_config.verifypeer() or conn_config.verifyhost())))
        {
            if (!conn_config.verifyhost() and (verify_result & ~MBEDTLS_X509_BADCERT_CN_MISMATCH) == 0) {
                // Only CN mismatch occurred and verifyhost is disabled
            } else if (!conn_config.verifypeer() and (verify_result & MBEDTLS_X509_BADCERT_CN_MISMATCH) == 0) {
                // Only peer trust errors occurred and verifypeer is disabled
            } else {
                if ((verify_result & MBEDTLS_X509_BADCERT_EXPIRED) != 0)
                    c_ext.Curl_failf(data, "Cert verify failed: BADCERT_EXPIRED");
                if ((verify_result & MBEDTLS_X509_BADCERT_REVOKED) != 0)
                    c_ext.Curl_failf(data, "Cert verify failed: BADCERT_REVOKED");
                if ((verify_result & MBEDTLS_X509_BADCERT_CN_MISMATCH) != 0)
                    c_ext.Curl_failf(data, "Cert verify failed: BADCERT_CN_MISMATCH");
                if ((verify_result & MBEDTLS_X509_BADCERT_NOT_TRUSTED) != 0)
                    c_ext.Curl_failf(data, "Cert verify failed: BADCERT_NOT_TRUSTED");
                if ((verify_result & MBEDTLS_X509_BADCRL_NOT_TRUSTED) != 0)
                    c_ext.Curl_failf(data, "Cert verify failed: BADCRL_NOT_TRUSTED");
                if ((verify_result & MBEDTLS_X509_BADCRL_EXPIRED) != 0)
                    c_ext.Curl_failf(data, "Cert verify failed: BADCRL_EXPIRED");
                return CURLE_PEER_FAILED_VERIFICATION;
            }
        }

        if (ret != 0) {
            var errorbuf: [128]u8 = @splat(0);
            c_ext.Curl_failf(
                data,
                "ssl_handshake returned: (-0x%04X) %s",
                @as(c_uint, @intCast(-ret)),
                error_strerror(ret, &errorbuf),
            );
            return CURLE_SSL_CONNECT_ERROR;
        }

        c_ext.Curl_infof(
            data,
            "mbedTLS: %s Handshake complete, cipher is %s",
            mbed_ext.mbedtls_ssl_get_version(&backend.ssl) orelse "unknown",
            mbed_ext.mbedtls_ssl_get_ciphersuite(&backend.ssl) orelse "unknown",
        );

        if (c_ext.Curl_vtls_acc_ssl_certinfo(data)) {
            mbed_extract_certinfo(data, mbed_ext.mbedtls_ssl_get_peer_cert(&backend.ssl));
        }

        if (c_ext.Curl_vtls_acc_pinned_pubkey(data, vtls_impl.Curl_ssl_cf_is_proxy(cf))) |pinnedpubkey| {
            const peercert = mbed_ext.mbedtls_ssl_get_peer_cert(&backend.ssl) orelse {
                c_ext.Curl_failf(data, "Failed due to missing peer certificate");
                return CURLE_SSL_PINNEDPUBKEYNOTMATCH;
            };
            const raw_p = peercert.raw.p orelse {
                c_ext.Curl_failf(data, "Failed due to missing peer certificate");
                return CURLE_SSL_PINNEDPUBKEYNOTMATCH;
            };
            if (peercert.raw.len == 0) {
                c_ext.Curl_failf(data, "Failed due to missing peer certificate");
                return CURLE_SSL_PINNEDPUBKEYNOTMATCH;
            }

            const p_raw = mem.calloc(1, @sizeOf(mbedtls_x509_crt)) orelse return CURLE_OUT_OF_MEMORY;
            const p: *mbedtls_x509_crt = @ptrCast(@alignCast(p_raw));
            const pubkey = mem.malloc(PUB_DER_MAX_BYTES) orelse {
                mem.free(p_raw);
                return CURLE_OUT_OF_MEMORY;
            };
            mbed_ext.mbedtls_x509_crt_init(p);
            defer {
                mbed_ext.mbedtls_x509_crt_free(p);
                mem.free(p_raw);
                mem.free(pubkey);
            }

            if (mbed_ext.mbedtls_x509_crt_parse(p, raw_p, peercert.raw.len) != 0) {
                c_ext.Curl_failf(data, "Failed copying peer certificate");
                return CURLE_SSL_PINNEDPUBKEYNOTMATCH;
            }

            const size = mbed_ext.mbedtls_pk_write_pubkey_der(&p.pk, pubkey, PUB_DER_MAX_BYTES);
            if (size <= 0) {
                c_ext.Curl_failf(data, "Failed copying public key from peer certificate");
                return CURLE_SSL_PINNEDPUBKEYNOTMATCH;
            }
            const usize_len: usize = @intCast(size);
            const result = vtls_impl.Curl_pin_peer_pubkey(
                data,
                pinnedpubkey,
                pubkey + (PUB_DER_MAX_BYTES - usize_len),
                usize_len,
            );
            if (result != CURLE_OK) return result;
        }

        if (connssl.alpn != null) {
            const proto = mbed_ext.mbedtls_ssl_get_alpn_protocol(&backend.ssl);
            const proto_len: usize = if (proto) |p| std.mem.len(p) else 0;
            const result = vtls_impl.Curl_alpn_set_negotiated(
                cf,
                data,
                connssl,
                if (proto) |p| p else null,
                proto_len,
            );
            if (result != CURLE_OK) return result;
        }

        connssl.connecting_state = ssl_connect_3;
        c_ext.Curl_infof(data, "SSL connected");
        return CURLE_OK;
    }

    fn mbedInit() callconv(.c) c_int {
        if (comptime use_mbedtls) {
            if (mbed_ext.psa_crypto_init() != 0) return 0;
        }
        return 1;
    }

    fn mbedCleanup() callconv(.c) void {}

    fn mbedVersion(buffer: [*]u8, size: usize) callconv(.c) usize {
        const version: c_uint = if (comptime use_mbedtls) mbed_ext.mbedtls_version_get_number() else 0x03060000;
        const rc = c_ext.curl_msnprintf(
            buffer,
            size,
            "mbedTLS/%u.%u.%u",
            version >> 24,
            (version >> 16) & 0xFF,
            (version >> 8) & 0xFF,
        );
        return if (rc > 0) @intCast(rc) else 0;
    }

    fn mbedConnect(cf: *CurlCfilter, data: ?*CurlEasy, done: *bool) callconv(.c) CURLcode {
        const connssl: *SslConnectData = @ptrCast(@alignCast(cf.ctx orelse return CURLE_SSL_CONNECT_ERROR));

        if (connssl.state == ssl_connection_complete) {
            done.* = true;
            return CURLE_OK;
        }

        done.* = false;
        connssl.io_need = CURL_SSL_IO_NEED_NONE;
        const saved_call_data = connssl.call_data;
        connssl.call_data = data;
        defer connssl.call_data = saved_call_data;

        if (connssl.connecting_state == ssl_connect_1) {
            const result = mbed_connect_step1(cf, data);
            if (result != CURLE_OK) return result;
        }

        if (connssl.connecting_state == ssl_connect_2) {
            const result = mbed_connect_step2(cf, data);
            if (result != CURLE_OK) return result;
        }

        if (connssl.connecting_state == ssl_connect_3) {
            const backend: *MbedSslBackendData = @ptrCast(@alignCast(connssl.backend orelse return CURLE_SSL_CONNECT_ERROR));
            if (sslTlsVersion(&backend.ssl) <= MBEDTLS_SSL_VERSION_TLS1_2) {
                const result = mbed_new_session(cf, data);
                if (result != CURLE_OK) return result;
            }
            connssl.connecting_state = ssl_connect_done;
        }

        if (connssl.connecting_state == ssl_connect_done) {
            connssl.state = ssl_connection_complete;
            done.* = true;
        }

        return CURLE_OK;
    }

    fn mbedDataPending(cf: *CurlCfilter, data: ?*const CurlEasy) callconv(.c) bool {
        _ = data;
        const connssl: *SslConnectData = @ptrCast(@alignCast(cf.ctx orelse return false));
        const backend: *MbedSslBackendData = @ptrCast(@alignCast(connssl.backend orelse return false));
        return mbed_ext.mbedtls_ssl_get_bytes_avail(&backend.ssl) != 0;
    }

    fn mbedSend(cf: *CurlCfilter, data: ?*CurlEasy, mem_ptr: ?*const anyopaque, len_in: usize, pnwritten: *usize) callconv(.c) CURLcode {
        const connssl: *SslConnectData = @ptrCast(@alignCast(cf.ctx orelse return CURLE_SEND_ERROR));
        const backend: *MbedSslBackendData = @ptrCast(@alignCast(connssl.backend orelse return CURLE_SEND_ERROR));
        const buf: [*]const u8 = @ptrCast(mem_ptr orelse return CURLE_BAD_FUNCTION_ARGUMENT);
        var len = len_in;
        var result: CURLcode = CURLE_OK;
        const saved_call_data = connssl.call_data;
        connssl.call_data = data;
        defer connssl.call_data = saved_call_data;

        while (true) {
            pnwritten.* = 0;
            connssl.io_need = CURL_SSL_IO_NEED_NONE;

            if (backend.flags.send_blocked) {
                if (backend.send_blocked_len > len) {
                    c_ext.Curl_failf(data, "re-send data shorter than previously");
                    return CURLE_BAD_FUNCTION_ARGUMENT;
                }
                c_ext.Curl_trc_cf_infof(
                    data,
                    cf,
                    "mbedtls_ssl_write(len=%zu) -> previously blocked on %zu bytes",
                    len,
                    backend.send_blocked_len,
                );
                len = backend.send_blocked_len;
            }

            const nwritten = mbed_ext.mbedtls_ssl_write(&backend.ssl, buf, len);
            if (nwritten >= 0) {
                pnwritten.* = @intCast(nwritten);
                backend.flags.send_blocked = false;
                backend.send_blocked_len = 0;
                result = CURLE_OK;
                break;
            } else {
                c_ext.Curl_trc_cf_infof(
                    data,
                    cf,
                    "mbedtls_ssl_write(len=%zu) -> -0x%04X",
                    len,
                    @as(c_uint, @intCast(-nwritten)),
                );
                switch (nwritten) {
                    MBEDTLS_ERR_SSL_RECEIVED_NEW_SESSION_TICKET => {
                        result = mbed_new_session(cf, data);
                        if (result == CURLE_OK) continue;
                    },
                    MBEDTLS_ERR_SSL_WANT_READ => {
                        connssl.io_need = CURL_SSL_IO_NEED_RECV;
                        result = CURLE_AGAIN;
                    },
                    MBEDTLS_ERR_SSL_WANT_WRITE => {
                        connssl.io_need = CURL_SSL_IO_NEED_SEND;
                        result = CURLE_AGAIN;
                    },
                    else => {
                        result = CURLE_SEND_ERROR;
                    },
                }
                if (result == CURLE_AGAIN and !backend.flags.send_blocked) {
                    backend.flags.send_blocked = true;
                    backend.send_blocked_len = len;
                }
                break;
            }
        }

        c_ext.Curl_trc_cf_infof(data, cf, "mbedtls_ssl_write(len=%zu) -> %d, %zu", len, result, pnwritten.*);
        return result;
    }

    fn mbedRecv(cf: *CurlCfilter, data: ?*CurlEasy, buf: [*]u8, len: usize, pnread: *usize) callconv(.c) CURLcode {
        const connssl: *SslConnectData = @ptrCast(@alignCast(cf.ctx orelse return CURLE_RECV_ERROR));
        const backend: *MbedSslBackendData = @ptrCast(@alignCast(connssl.backend orelse return CURLE_RECV_ERROR));
        var result: CURLcode = CURLE_OK;
        const saved_call_data = connssl.call_data;
        connssl.call_data = data;
        defer connssl.call_data = saved_call_data;

        while (true) {
            pnread.* = 0;
            connssl.io_need = CURL_SSL_IO_NEED_NONE;

            const nread = mbed_ext.mbedtls_ssl_read(&backend.ssl, buf, len);
            if (nread > 0) {
                pnread.* = @intCast(nread);
                return CURLE_OK;
            } else if (nread == 0) {
                return CURLE_OK;
            } else {
                var errorbuf: [128]u8 = @splat(0);
                c_ext.Curl_trc_cf_infof(
                    data,
                    cf,
                    "mbedtls_ssl_read(len=%zu) -> -0x%04X",
                    len,
                    @as(c_uint, @intCast(-nread)),
                );
                switch (nread) {
                    MBEDTLS_ERR_SSL_RECEIVED_NEW_SESSION_TICKET => {
                        result = mbed_new_session(cf, data);
                        if (result == CURLE_OK) continue;
                    },
                    MBEDTLS_ERR_SSL_WANT_READ => {
                        connssl.io_need = CURL_SSL_IO_NEED_RECV;
                        result = CURLE_AGAIN;
                    },
                    MBEDTLS_ERR_SSL_WANT_WRITE => {
                        connssl.io_need = CURL_SSL_IO_NEED_SEND;
                        result = CURLE_AGAIN;
                    },
                    MBEDTLS_ERR_SSL_PEER_CLOSE_NOTIFY => {
                        result = CURLE_OK;
                    },
                    else => {
                        c_ext.Curl_failf(
                            data,
                            "ssl_read returned: (-0x%04X) %s",
                            @as(c_uint, @intCast(-nread)),
                            error_strerror(nread, &errorbuf),
                        );
                        result = CURLE_RECV_ERROR;
                    },
                }
                return result;
            }
        }
    }

    fn mbedShutdown(cf: *CurlCfilter, data: ?*CurlEasy, send_shutdown: bool, done: *bool) callconv(.c) CURLcode {
        const connssl: *SslConnectData = @ptrCast(@alignCast(cf.ctx orelse {
            done.* = true;
            return CURLE_OK;
        }));
        const backend: *MbedSslBackendData = @ptrCast(@alignCast(connssl.backend orelse {
            done.* = true;
            return CURLE_OK;
        }));
        var buf: [1024]u8 = undefined;
        var result: CURLcode = CURLE_OK;
        var ret: c_int = 0;

        if (!backend.flags.initialized or cf.isShutdown()) {
            done.* = true;
            return CURLE_OK;
        }

        connssl.io_need = CURL_SSL_IO_NEED_NONE;
        done.* = false;
        const saved_call_data = connssl.call_data;
        connssl.call_data = data;
        defer connssl.call_data = saved_call_data;

        if (!backend.flags.sent_shutdown) {
            backend.flags.sent_shutdown = true;
            if (send_shutdown) {
                ret = mbed_ext.mbedtls_ssl_close_notify(&backend.ssl);
                switch (ret) {
                    0 => {},
                    MBEDTLS_ERR_SSL_PEER_CLOSE_NOTIFY => {
                        done.* = true;
                        cf.setShutdown(true);
                        return CURLE_OK;
                    },
                    MBEDTLS_ERR_SSL_WANT_READ => {
                        connssl.io_need = CURL_SSL_IO_NEED_RECV;
                        return CURLE_OK;
                    },
                    MBEDTLS_ERR_SSL_WANT_WRITE => {
                        connssl.io_need = CURL_SSL_IO_NEED_SEND;
                        return CURLE_OK;
                    },
                    else => {
                        c_ext.Curl_trc_cf_infof(data, cf, "mbedtls_shutdown error -0x%04X", @as(c_uint, @intCast(-ret)));
                        cf.setShutdown(true);
                        return CURLE_RECV_ERROR;
                    },
                }
            }
        }

        var i: usize = 0;
        while (i < 10) : (i += 1) {
            ret = mbed_ext.mbedtls_ssl_read(&backend.ssl, &buf, buf.len);
            if (ret == MBEDTLS_ERR_SSL_WANT_READ) {
                ret = mbed_ext.mbedtls_ssl_read(&backend.ssl, &buf, buf.len);
            }
            if (ret == MBEDTLS_ERR_SSL_RECEIVED_NEW_SESSION_TICKET) {
                continue;
            }
            if (ret <= 0) break;
        }

        if (ret > 0) {
            c_ext.Curl_trc_cf_infof(data, cf, "mbedtls_shutdown, still getting data");
        } else if (ret == 0 or ret == MBEDTLS_ERR_SSL_PEER_CLOSE_NOTIFY) {
            c_ext.Curl_trc_cf_infof(data, cf, "mbedtls_shutdown done");
            done.* = true;
        } else if (ret == MBEDTLS_ERR_SSL_WANT_READ) {
            c_ext.Curl_trc_cf_infof(data, cf, "mbedtls_shutdown, need RECV");
            connssl.io_need = CURL_SSL_IO_NEED_RECV;
        } else if (ret == MBEDTLS_ERR_SSL_WANT_WRITE) {
            c_ext.Curl_trc_cf_infof(data, cf, "mbedtls_shutdown, need SEND");
            connssl.io_need = CURL_SSL_IO_NEED_SEND;
        } else {
            c_ext.Curl_trc_cf_infof(data, cf, "mbedtls_shutdown error -0x%04X", @as(c_uint, @intCast(-ret)));
            result = CURLE_RECV_ERROR;
        }

        if (result != CURLE_OK or done.*) {
            cf.setShutdown(true);
        }
        return result;
    }

    fn mbedClose(cf: *CurlCfilter, data: ?*CurlEasy) callconv(.c) void {
        _ = data;
        const connssl: *SslConnectData = @ptrCast(@alignCast(cf.ctx orelse return));
        const backend: *MbedSslBackendData = @ptrCast(@alignCast(connssl.backend orelse return));
        if (backend.flags.initialized) {
            mbed_ext.mbedtls_pk_free(&backend.pk);
            mbed_ext.mbedtls_x509_crt_free(&backend.clicert);
            mbed_ext.mbedtls_x509_crt_free(&backend.cacert);
            mbed_ext.mbedtls_x509_crl_free(&backend.crl);
            if (backend.ciphersuites) |cs| {
                mem.free(cs);
                backend.ciphersuites = null;
            }
            mbed_ext.mbedtls_ssl_config_free(&backend.config);
            mbed_ext.mbedtls_ssl_free(&backend.ssl);
            mbed_ext.mbedtls_ctr_drbg_free(&backend.ctr_drbg);
            mbed_ext.mbedtls_entropy_free(&backend.entropy);
            backend.flags.initialized = false;
        } else if (backend.ciphersuites) |cs| {
            mem.free(cs);
            backend.ciphersuites = null;
        }
    }

    fn mbedGetInternals(connssl: *SslConnectData, info: c_uint) callconv(.c) ?*anyopaque {
        const backend: *MbedSslBackendData = @ptrCast(@alignCast(connssl.backend orelse return null));
        return if (info == CURLINFO_TLS_SESSION) @ptrCast(&backend.config) else @ptrCast(&backend.ssl);
    }

    fn mbedRandom(data: ?*CurlEasy, entropy: [*]u8, length: usize) callconv(.c) CURLcode {
        if (comptime use_mbedtls) {
            var ctr_drbg: mbedtls_ctr_drbg_context = .{};
            var my_entropy: mbedtls_entropy_context = .{};
            var errorbuf: [128]u8 = @splat(0);

            mbed_ext.mbedtls_entropy_init(&my_entropy);
            mbed_ext.mbedtls_ctr_drbg_init(&ctr_drbg);
            defer {
                mbed_ext.mbedtls_ctr_drbg_free(&ctr_drbg);
                mbed_ext.mbedtls_entropy_free(&my_entropy);
            }

            const custom = "curl";
            var ret = mbed_ext.mbedtls_ctr_drbg_seed(
                &ctr_drbg,
                mbed_ext.mbedtls_entropy_func,
                &my_entropy,
                custom.ptr,
                custom.len,
            );
            if (ret != 0) {
                c_ext.Curl_failf(
                    data,
                    "mbedtls_ctr_drbg_seed returned (-0x%04X) %s",
                    @as(c_uint, @intCast(-ret)),
                    error_strerror(ret, &errorbuf),
                );
                return CURLE_FAILED_INIT;
            }

            ret = mbed_ext.mbedtls_ctr_drbg_random(&ctr_drbg, entropy, length);
            if (ret != 0) {
                c_ext.Curl_failf(
                    data,
                    "mbedtls_ctr_drbg_random returned (-0x%04X) %s",
                    @as(c_uint, @intCast(-ret)),
                    error_strerror(ret, &errorbuf),
                );
                return CURLE_FAILED_INIT;
            }
            return CURLE_OK;
        }
        std.crypto.random.bytes(entropy[0..length]);
        return CURLE_OK;
    }

    fn mbedSha256sum(input: [*]const u8, inputlen: usize, sha256sum: [*]u8, sha256len: usize) callconv(.c) CURLcode {
        if (sha256len < 32) return CURLE_BAD_FUNCTION_ARGUMENT;
        if (comptime use_mbedtls) {
            const ret = mbed_ext.mbedtls_sha256(input, inputlen, sha256sum, 0);
            return if (ret == 0) CURLE_OK else CURLE_BAD_FUNCTION_ARGUMENT;
        }
        var digest: [32]u8 = undefined;
        std.crypto.hash.sha2.Sha256.hash(input[0..inputlen], &digest, .{});
        @memcpy(sha256sum[0..32], &digest);
        return CURLE_OK;
    }

    pub const Curl_ssl_mbedtls = CurlSsl{
        .info = .{ .id = CURLSSLBACKEND_MBEDTLS, .name = "mbedtls" },
        .supports = SSLSUPP_CA_PATH | SSLSUPP_CERTINFO | SSLSUPP_PINNEDPUBKEY | SSLSUPP_SSL_CTX | SSLSUPP_HTTPS_PROXY | SSLSUPP_CAINFO_BLOB | SSLSUPP_CIPHER_LIST | SSLSUPP_TLS13_CIPHERSUITES | SSLSUPP_CRLFILE | SSLSUPP_SSL_EC_CURVES,
        .sizeof_ssl_backend_data = @sizeOf(MbedSslBackendData),
        .init = mbedInit,
        .cleanup = mbedCleanup,
        .version = mbedVersion,
        .shut_down = mbedShutdown,
        .data_pending = mbedDataPending,
        .random = mbedRandom,
        .cert_status_request = null,
        .do_connect = mbedConnect,
        .adjust_pollset = vtls_impl.Curl_ssl_adjust_pollset,
        .get_internals = mbedGetInternals,
        .close = mbedClose,
        .close_all = null,
        .engines_list = null,
        .sha256sum = mbedSha256sum,
        .recv_plain = mbedRecv,
        .send_plain = mbedSend,
        .get_channel_binding = null,
    };

    test "mbedTLS version min/max mapping" {
        var backend = std.mem.zeroes(MbedSslBackendData);
        var cfg = std.mem.zeroes(SslFilterConfig);

        // Default -> TLS 1.2 .. TLS 1.3
        cfg.version = CURL_SSLVERSION_DEFAULT;
        cfg.version_max = CURL_SSLVERSION_MAX_DEFAULT;
        try std.testing.expectEqual(CURLE_OK, mbed_set_ssl_version_min_max(null, &backend, &cfg));
        try std.testing.expectEqual(MBEDTLS_SSL_VERSION_TLS1_2, backend.config.min_tls_version);
        try std.testing.expectEqual(MBEDTLS_SSL_VERSION_TLS1_3, backend.config.max_tls_version);

        // TLS 1.2 min, TLS 1.2 max
        cfg.version = CURL_SSLVERSION_TLSv1_2;
        cfg.version_max = MBED_SSLVERSION_MAX_TLSv1_2;
        try std.testing.expectEqual(CURLE_OK, mbed_set_ssl_version_min_max(null, &backend, &cfg));
        try std.testing.expectEqual(MBEDTLS_SSL_VERSION_TLS1_2, backend.config.min_tls_version);
        try std.testing.expectEqual(MBEDTLS_SSL_VERSION_TLS1_2, backend.config.max_tls_version);

        // TLS 1.3 min, TLS 1.3 max
        cfg.version = CURL_SSLVERSION_TLSv1_3;
        cfg.version_max = CURL_SSLVERSION_MAX_TLSv1_3;
        try std.testing.expectEqual(CURLE_OK, mbed_set_ssl_version_min_max(null, &backend, &cfg));
        try std.testing.expectEqual(MBEDTLS_SSL_VERSION_TLS1_3, backend.config.min_tls_version);
        try std.testing.expectEqual(MBEDTLS_SSL_VERSION_TLS1_3, backend.config.max_tls_version);

        // Reject SSLv2 and SSLv3 with CURLE_NOT_BUILT_IN
        cfg.version = CURL_SSLVERSION_SSLv2;
        cfg.version_max = CURL_SSLVERSION_MAX_DEFAULT;
        try std.testing.expectEqual(CURLE_NOT_BUILT_IN, mbed_set_ssl_version_min_max(null, &backend, &cfg));

        cfg.version = CURL_SSLVERSION_SSLv3;
        try std.testing.expectEqual(CURLE_NOT_BUILT_IN, mbed_set_ssl_version_min_max(null, &backend, &cfg));

        // Reject max TLS 1.0 / 1.1 with CURLE_SSL_CONNECT_ERROR
        cfg.version = CURL_SSLVERSION_TLSv1_2;
        cfg.version_max = CURL_SSLVERSION_MAX_TLSv1_1;
        try std.testing.expectEqual(CURLE_SSL_CONNECT_ERROR, mbed_set_ssl_version_min_max(null, &backend, &cfg));

        cfg.version_max = CURL_SSLVERSION_MAX_TLSv1_0;
        try std.testing.expectEqual(CURLE_SSL_CONNECT_ERROR, mbed_set_ssl_version_min_max(null, &backend, &cfg));

        // Reject min TLS 1.3 > max TLS 1.2
        cfg.version = CURL_SSLVERSION_TLSv1_3;
        cfg.version_max = MBED_SSLVERSION_MAX_TLSv1_2;
        try std.testing.expectEqual(CURLE_SSL_CONNECT_ERROR, mbed_set_ssl_version_min_max(null, &backend, &cfg));
    }

    test "mbedTLS cipher suite parsing and deduplication" {
        var ecjpake_str: ?[*:0]const u8 = "TLS_ECJPAKE_WITH_AES_128_CCM_8";
        var ecjpake_end: ?[*:0]const u8 = null;
        try std.testing.expectEqual(@as(u16, 0xC0FF), mbed_cipher_suite_walk_str(&ecjpake_str, &ecjpake_end));

        var backend = std.mem.zeroes(MbedSslBackendData);
        defer if (backend.ciphersuites) |cs| mem.free(cs);

        try std.testing.expectEqual(
            CURLE_OK,
            mbed_set_selected_ciphers(
                null,
                &backend,
                "ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES128-GCM-SHA256",
                "TLS_AES_128_GCM_SHA256",
            ),
        );
        try std.testing.expect(backend.ciphersuites != null);
        const cs = backend.ciphersuites.?;
        if (validateCiphersuiteId(0x1301)) {
            try std.testing.expectEqual(@as(c_int, 0x1301), cs[0]);
            try std.testing.expectEqual(@as(c_int, 0xC02F), cs[1]);
            try std.testing.expectEqual(@as(c_int, 0xC02B), cs[2]);
            try std.testing.expectEqual(@as(c_int, 0), cs[3]);
        } else {
            try std.testing.expectEqual(@as(c_int, 0xC02F), cs[0]);
            try std.testing.expectEqual(@as(c_int, 0xC02B), cs[1]);
            try std.testing.expectEqual(@as(c_int, 0), cs[2]);
        }

        // All invalid cipher names -> CURLE_SSL_CIPHER
        try std.testing.expectEqual(
            CURLE_SSL_CIPHER,
            mbed_set_selected_ciphers(null, &backend, "NOT-A-VALID-CIPHER", null),
        );
    }

    test "mbedTLS BIO error code mapping" {
        try std.testing.expectEqual(@as(c_int, 42), mapBioWriteResult(CURLE_OK, 42));
        try std.testing.expectEqual(MBEDTLS_ERR_SSL_WANT_WRITE, mapBioWriteResult(CURLE_AGAIN, 0));
        try std.testing.expectEqual(@as(c_int, -1), mapBioWriteResult(CURLE_SEND_ERROR, 0));

        try std.testing.expectEqual(@as(c_int, 128), mapBioReadResult(CURLE_OK, 128));
        try std.testing.expectEqual(MBEDTLS_ERR_SSL_WANT_READ, mapBioReadResult(CURLE_AGAIN, 0));
        try std.testing.expectEqual(@as(c_int, -1), mapBioReadResult(CURLE_RECV_ERROR, 0));

        // Null bio / null call_data / null buffer guards
        const dummy = "hello";
        try std.testing.expectEqual(@as(c_int, 0), mbedtls_bio_cf_write(null, dummy.ptr, dummy.len));
        try std.testing.expectEqual(@as(c_int, 0), mbedtls_bio_cf_read(null, null, 0));
    }
};

test {
    _ = mbedtls_backend;
}

// ============================================================================
// Conditional Symbol Exports
// ============================================================================

comptime {
    if (use_ssl) {
        @export(&vtls_impl.Curl_cft_ssl, .{ .name = "Curl_cft_ssl" });
        @export(&vtls_impl.Curl_cft_ssl_proxy, .{ .name = "Curl_cft_ssl_proxy" });
        @export(&vtls_impl.Curl_ssl, .{ .name = "Curl_ssl" });
        @export(&vtls_impl.Curl_ssl_init, .{ .name = "Curl_ssl_init" });
        @export(&vtls_impl.Curl_ssl_cleanup, .{ .name = "Curl_ssl_cleanup" });
        @export(&vtls_impl.Curl_ssl_version, .{ .name = "Curl_ssl_version" });
        @export(&vtls_impl.Curl_ssl_check_cxn, .{ .name = "Curl_ssl_check_cxn" });
        @export(&vtls_impl.Curl_ssl_Shutdown, .{ .name = "Curl_ssl_Shutdown" });
        @export(&vtls_impl.Curl_ssl_data_pending, .{ .name = "Curl_ssl_data_pending" });
        @export(&vtls_impl.Curl_ssl_get_internals, .{ .name = "Curl_ssl_get_internals" });
        @export(&vtls_impl.Curl_ssl_engines_list, .{ .name = "Curl_ssl_engines_list" });
        @export(&vtls_impl.Curl_ssl_initsessions, .{ .name = "Curl_ssl_initsessions" });
        @export(&vtls_impl.Curl_ssl_init_certinfo, .{ .name = "Curl_ssl_init_certinfo" });
        @export(&vtls_impl.Curl_ssl_init_certinfo, .{ .name = "Curl_ssl_Init_certinfo" });
        @export(&vtls_impl.Curl_ssl_push_certinfo_len, .{ .name = "Curl_ssl_push_certinfo_len" });
        @export(&vtls_impl.Curl_ssl_push_certinfo, .{ .name = "Curl_ssl_push_certinfo" });
        @export(&vtls_impl.Curl_ssl_free_certinfo, .{ .name = "Curl_ssl_free_certinfo" });
        @export(&vtls_impl.Curl_ssl_random, .{ .name = "Curl_ssl_random" });
        @export(&vtls_impl.Curl_ssl_md5sum, .{ .name = "Curl_ssl_md5sum" });
        @export(&vtls_impl.Curl_ssl_sha256sum, .{ .name = "Curl_ssl_sha256sum" });
        @export(&vtls_impl.Curl_pin_peer_pubkey, .{ .name = "Curl_pin_peer_pubkey" });
        @export(&vtls_impl.Curl_ssl_cert_status_request, .{ .name = "Curl_ssl_cert_status_request" });
        @export(&vtls_impl.Curl_ssl_false_start, .{ .name = "Curl_ssl_false_start" });
        @export(&vtls_impl.Curl_ssl_setup_x509_store, .{ .name = "Curl_ssl_setup_x509_store" });
        @export(&vtls_impl.Curl_ssl_get_x509_store, .{ .name = "Curl_ssl_get_x509_store" });
        @export(&vtls_impl.Curl_cf_ssl_create, .{ .name = "Curl_cf_ssl_create" });
        @export(&vtls_impl.Curl_cf_ssl_proxy_create, .{ .name = "Curl_cf_ssl_proxy_create" });
        @export(&vtls_impl.Curl_ssl_cfilter_add, .{ .name = "Curl_ssl_cfilter_add" });
        @export(&vtls_impl.Curl_ssl_cfilter_remove, .{ .name = "Curl_ssl_cfilter_remove" });
        @export(&vtls_impl.Curl_ssl_cf_get_ssl, .{ .name = "Curl_ssl_cf_get_ssl" });
        @export(&vtls_impl.Curl_ssl_cf_get_easy_config, .{ .name = "Curl_ssl_cf_get_easy_config" });
        @export(&vtls_impl.Curl_ssl_cf_get_filter_config, .{ .name = "Curl_ssl_cf_get_filter_config" });
        @export(&vtls_impl.Curl_ssl_cf_is_proxy, .{ .name = "Curl_ssl_cf_is_proxy" });
        @export(&vtls_impl.Curl_ssl_peer_init, .{ .name = "Curl_ssl_peer_init" });
        @export(&vtls_impl.Curl_ssl_peer_cleanup, .{ .name = "Curl_ssl_peer_cleanup" });
        @export(&vtls_impl.Curl_alpn_to_proto_buf, .{ .name = "Curl_alpn_to_proto_buf" });
        @export(&vtls_impl.Curl_alpn_to_proto_str, .{ .name = "Curl_alpn_to_proto_str" });
        @export(&vtls_impl.Curl_alpn_set_negotiated, .{ .name = "Curl_alpn_set_negotiated" });
        @export(&vtls_impl.Curl_alpn_contains_proto, .{ .name = "Curl_alpn_contains_proto" });
        @export(&vtls_impl.Curl_alpn_restrict_to, .{ .name = "Curl_alpn_restrict_to" });
        @export(&vtls_impl.Curl_alpn_copy, .{ .name = "Curl_alpn_copy" });
        @export(&vtls_impl.Curl_on_session_reuse, .{ .name = "Curl_on_session_reuse" });
        @export(&vtls_impl.Curl_ssl_get_cf_session, .{ .name = "Curl_ssl_get_cf_session" });
        @export(&vtls_impl.Curl_ssl_get_channel_binding, .{ .name = "Curl_ssl_get_channel_binding" });
        @export(&vtls_impl.Curl_ssl_close_all, .{ .name = "Curl_ssl_close_all" });
        @export(&vtls_impl.Curl_ssl_adjust_pollset, .{ .name = "Curl_ssl_adjust_pollset" });
        @export(&vtls_impl.Curl_multissl_init, .{ .name = "Curl_multissl_init" });
        @export(&vtls_impl.Curl_multissl_version, .{ .name = "Curl_multissl_version" });
        @export(&vtls_impl.Curl_multissl_set, .{ .name = "Curl_multissl_set" });

        if (backend_options.ssl == .schannel) {
            @export(&schannel_backend.Curl_ssl_schannel, .{ .name = "Curl_ssl_schannel" });
            @export(&schannel_backend.Curl_schannel_get_cached_cert_store, .{ .name = "Curl_schannel_get_cached_cert_store" });
            @export(&schannel_backend.Curl_schannel_set_cached_cert_store, .{ .name = "Curl_schannel_set_cached_cert_store" });
        } else if (backend_options.ssl == .openssl) {
            if (backend_options.bundled) {
                @export(&bundled_tls.Curl_ssl_zig_tls, .{ .name = "Curl_ssl_openssl" });
            } else {
                @export(&openssl_backend.Curl_ssl_openssl, .{ .name = "Curl_ssl_openssl" });
                @export(&openssl_backend.Curl_ossl_init, .{ .name = "Curl_ossl_init" });
                @export(&openssl_backend.Curl_ossl_cleanup, .{ .name = "Curl_ossl_cleanup" });
                @export(&openssl_backend.Curl_ossl_version, .{ .name = "Curl_ossl_version" });
                @export(&openssl_backend.Curl_ossl_verifyhost, .{ .name = "Curl_ossl_verifyhost" });
                @export(&openssl_backend.Curl_ossl_certchain, .{ .name = "Curl_ossl_certchain" });
                @export(&openssl_backend.Curl_ossl_check_peer_cert, .{ .name = "Curl_ossl_check_peer_cert" });
                @export(&openssl_backend.Curl_ossl_setup_x509_store, .{ .name = "Curl_ossl_setup_x509_store" });
                @export(&openssl_backend.Curl_ossl_ctx_init, .{ .name = "Curl_ossl_ctx_init" });
                @export(&openssl_backend.Curl_osslctx_cleanup, .{ .name = "Curl_osslctx_cleanup" });
                @export(&openssl_backend.Curl_ossl_report_handshake, .{ .name = "Curl_ossl_report_handshake" });
                @export(&openssl_backend.Curl_ossl_add_session, .{ .name = "Curl_ossl_add_session" });
            }
        } else if (backend_options.ssl == .mbedtls) {
            @export(&mbedtls_backend.Curl_ssl_mbedtls, .{ .name = "Curl_ssl_mbedtls" });
        }
    }
}

pub const MbedsslBackendData = mbedtls_backend.MbedSslBackendData;
pub const SchannelBackendData = schannel_backend.SchannelSslBackendData;
pub const GtlsSslBackendData = vtls_gtls.GtlsSslBackendData;
pub const RustlsSslBackendData = vtls_rustls.RustlsSslBackendData;
pub const WolfsslBackendData = vtls_wolfssl.WolfsslBackendData;

pub fn freeOsslCtx(ptr: ?*openssl_backend.OsslCtx) void {
    mem.freeSized(ptr, @sizeOf(openssl_backend.OsslCtx));
}

pub fn freeMbedsslBackendData(ptr: ?*MbedsslBackendData) void {
    mem.freeSized(ptr, @sizeOf(MbedsslBackendData));
}

pub fn freeSchannelBackendData(ptr: ?*SchannelBackendData) void {
    mem.freeSized(ptr, @sizeOf(SchannelBackendData));
}

// ============================================================================
// Unit Tests
// ============================================================================

test "X.509 SAN and CN embedded-NUL rejection and backend context poisoning" {
    const evil_san = "evil.com\x00.example.com";
    try std.testing.expect(!openssl_backend.matchDnsNameBytes(evil_san.ptr, evil_san.len, "evil.com"));
    try std.testing.expect(!openssl_backend.matchDnsNameBytes("*.example.com", 13, evil_san));
    try std.testing.expectEqual(
        openssl_backend.HostVerifyOutcome.cn_embedded_nul,
        openssl_backend.verifyHostSynthetic(SSL_PEER_DNS, "evil.com", null, evil_san),
    );
    try std.testing.expect(!vtls_gtls.gtlsVerifyHostSlice(evil_san.ptr, evil_san.len, "evil.com"));
    try std.testing.expect(!vtls_wolfssl.wsslVerifyHostSlice(evil_san.ptr, evil_san.len, "evil.com"));
    try std.testing.expect(!vtls_rustls.rustlsVerifyHostSlice(evil_san.ptr, evil_san.len, "evil.com"));

    // Verify mem.freeSized poisoning (0xaa) on backend context structs in Debug/ReleaseSafe
    var ossl_ctx = std.mem.zeroes(openssl_backend.OsslCtx);
    var mbed_ctx = std.mem.zeroes(MbedsslBackendData);
    var schan_ctx = std.mem.zeroes(SchannelBackendData);
    var gtls_ctx = std.mem.zeroes(GtlsSslBackendData);
    var rustls_ctx = std.mem.zeroes(RustlsSslBackendData);
    var wssl_ctx = std.mem.zeroes(WolfsslBackendData);

    const expected_poison: u8 = switch (builtin.mode) {
        .Debug, .ReleaseSafe => 0xaa,
        .ReleaseFast, .ReleaseSmall => 0x00,
    };
    mem.poison(&ossl_ctx, @sizeOf(openssl_backend.OsslCtx));
    mem.poison(&mbed_ctx, @sizeOf(MbedsslBackendData));
    mem.poison(&schan_ctx, @sizeOf(SchannelBackendData));
    mem.poison(&gtls_ctx, @sizeOf(GtlsSslBackendData));
    mem.poison(&rustls_ctx, @sizeOf(RustlsSslBackendData));
    mem.poison(&wssl_ctx, @sizeOf(WolfsslBackendData));
    try std.testing.expectEqual(expected_poison, std.mem.asBytes(&ossl_ctx)[0]);
    try std.testing.expectEqual(expected_poison, std.mem.asBytes(&mbed_ctx)[0]);
    try std.testing.expectEqual(expected_poison, std.mem.asBytes(&schan_ctx)[0]);
    try std.testing.expectEqual(expected_poison, std.mem.asBytes(&gtls_ctx)[0]);
    try std.testing.expectEqual(expected_poison, std.mem.asBytes(&rustls_ctx)[0]);
    try std.testing.expectEqual(expected_poison, std.mem.asBytes(&wssl_ctx)[0]);

    const heap_ossl: *openssl_backend.OsslCtx = @ptrCast(@alignCast(mem.calloc(1, @sizeOf(openssl_backend.OsslCtx)).?));
    freeOsslCtx(heap_ossl);
    const heap_mbed: *MbedsslBackendData = @ptrCast(@alignCast(mem.calloc(1, @sizeOf(MbedsslBackendData)).?));
    freeMbedsslBackendData(heap_mbed);
    const heap_schan: *SchannelBackendData = @ptrCast(@alignCast(mem.calloc(1, @sizeOf(SchannelBackendData)).?));
    freeSchannelBackendData(heap_schan);
    const heap_gtls: *GtlsSslBackendData = @ptrCast(@alignCast(mem.calloc(1, @sizeOf(GtlsSslBackendData)).?));
    vtls_gtls.freeGtlsBackendData(heap_gtls);
    const heap_rustls: *RustlsSslBackendData = @ptrCast(@alignCast(mem.calloc(1, @sizeOf(RustlsSslBackendData)).?));
    vtls_rustls.freeRustlsBackendData(heap_rustls);
    const heap_wssl: *WolfsslBackendData = @ptrCast(@alignCast(mem.calloc(1, @sizeOf(WolfsslBackendData)).?));
    vtls_wolfssl.freeWolfsslBackendData(heap_wssl);
}

test "ALPN wire buffer and comma string conversion" {
    var proto_buf: AlpnProtoBuf = undefined;
    try std.testing.expectEqual(CURLE_OK, alpnToProtoBuf(&proto_buf, &ALPN_SPEC_H10_H11));
    try std.testing.expectEqual(@as(c_int, 18), proto_buf.len);
    try std.testing.expectEqual(@as(u8, 8), proto_buf.data[0]);
    try std.testing.expectEqualStrings("http/1.0", proto_buf.data[1..9]);
    try std.testing.expectEqual(@as(u8, 8), proto_buf.data[9]);
    try std.testing.expectEqualStrings("http/1.1", proto_buf.data[10..18]);

    var proto_str: AlpnProtoBuf = undefined;
    try std.testing.expectEqual(CURLE_OK, alpnToProtoStr(&proto_str, &ALPN_SPEC_H10_H11));
    try std.testing.expectEqual(@as(c_int, 17), proto_str.len);
    try std.testing.expectEqualStrings("http/1.0,http/1.1", proto_str.data[0..17]);
}

test "ALPN contains, copy, and restrict" {
    try std.testing.expect(alpnContainsProto(&ALPN_SPEC_H2_H11, "h2"));
    try std.testing.expect(alpnContainsProto(&ALPN_SPEC_H2_H11, "http/1.1"));
    try std.testing.expect(!alpnContainsProto(&ALPN_SPEC_H2_H11, "http/1.0"));
    try std.testing.expect(!alpnContainsProto(null, "h2"));

    var copy_spec: AlpnSpec = undefined;
    alpnCopy(&copy_spec, &ALPN_SPEC_H2_H11);
    try std.testing.expectEqual(@as(usize, 2), copy_spec.count);
    alpnRestrictTo(&copy_spec, "http/1.1");
    try std.testing.expectEqual(@as(usize, 1), copy_spec.count);
    try std.testing.expect(alpnContainsProto(&copy_spec, "http/1.1"));
    try std.testing.expect(!alpnContainsProto(&copy_spec, "h2"));
}

test "pubkeyPemToDer rejects invalid PEM headers" {
    var der: ?[*]u8 = null;
    var der_len: usize = 0;
    try std.testing.expectEqual(CURLE_BAD_CONTENT_ENCODING, pubkeyPemToDer(null, &der, &der_len));
    try std.testing.expectEqual(CURLE_BAD_CONTENT_ENCODING, pubkeyPemToDer("not a pem", &der, &der_len));
    try std.testing.expectEqual(CURLE_BAD_CONTENT_ENCODING, pubkeyPemToDer("X-----BEGIN PUBLIC KEY-----\nAAAA\n-----END PUBLIC KEY-----", &der, &der_len));
}

test "VTLS backend dispatch and non-SSL fallbacks" {
    if (!use_ssl) {
        try std.testing.expectEqual(CURLSSLBACKEND_NONE, Curl_ssl_backend());
        try std.testing.expect(!Curl_ssl_supports(null, SSLSUPP_CERTINFO));
        var dummy_cf: CurlCfilter = undefined;
        try std.testing.expectEqual(CURLE_NOT_BUILT_IN, Curl_cf_ssl_insert_after(&dummy_cf, null, null, null));
        try std.testing.expectEqual(CURLE_NOT_BUILT_IN, Curl_cf_ssl_proxy_insert_after(&dummy_cf, null, null));
    } else {
        try std.testing.expect(Curl_ssl_backend() != CURLSSLBACKEND_NONE);
        try std.testing.expect(Curl_ssl_supports(null, SSLSUPP_CAINFO_BLOB));
        try std.testing.expectEqual(backend_options.ssl != .wolfssl, Curl_ssl_supports(null, SSLSUPP_CERTINFO));
    }
}

test "SSLSUPP_* bit constants match lib/vtls/vtls.h" {
    try std.testing.expectEqual(@as(c_uint, 1 << 0), SSLSUPP_CA_PATH);
    try std.testing.expectEqual(@as(c_uint, 1 << 1), SSLSUPP_CERTINFO);
    try std.testing.expectEqual(@as(c_uint, 1 << 2), SSLSUPP_PINNEDPUBKEY);
    try std.testing.expectEqual(@as(c_uint, 1 << 3), SSLSUPP_SSL_CTX);
    try std.testing.expectEqual(@as(c_uint, 1 << 4), SSLSUPP_HTTPS_PROXY);
    try std.testing.expectEqual(@as(c_uint, 1 << 5), SSLSUPP_TLS13_CIPHERSUITES);
    try std.testing.expectEqual(@as(c_uint, 1 << 6), SSLSUPP_CAINFO_BLOB);
    try std.testing.expectEqual(@as(c_uint, 1 << 7), SSLSUPP_ECH);
    try std.testing.expectEqual(@as(c_uint, 1 << 8), SSLSUPP_CA_CACHE);
    try std.testing.expectEqual(@as(c_uint, 1 << 9), SSLSUPP_CIPHER_LIST);
    try std.testing.expectEqual(@as(c_uint, 1 << 10), SSLSUPP_SIGNATURE_ALGORITHMS);
    try std.testing.expectEqual(@as(c_uint, 1 << 11), SSLSUPP_ISSUERCERT);
    try std.testing.expectEqual(@as(c_uint, 1 << 12), SSLSUPP_SSL_EC_CURVES);
    try std.testing.expectEqual(@as(c_uint, 1 << 13), SSLSUPP_CRLFILE);
    try std.testing.expectEqual(@as(c_uint, 1 << 14), SSLSUPP_ISSUERCERT_BLOB);
}
