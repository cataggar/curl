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

const is_windows = builtin.os.tag == .windows;
pub const use_ssl = switch (backend_options.ssl) {
    .openssl, .mbedtls, .schannel => true,
    .none => false,
};
pub const use_apple_sectrust = backend_options.apple_sectrust orelse (backend_options.ssl == .openssl and builtin.os.tag.isDarwin());

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
pub const CF_TYPE_PROXY: c_int = 1 << 5;
pub const CF_LVL_SSL: c_int = 2;

pub const CF_CTRL_DATA_SETUP: c_int = 1;
pub const CF_CTRL_CONN_INFO_UPDATE: c_int = 256 + 0;
pub const CF_CTRL_REPORT_STATS: c_int = 256 + 3;

pub const CF_QUERY_MAX_CONCURRENT: c_int = 1;
pub const CF_QUERY_CONNECT_REPLY_MS: c_int = 2;
pub const CF_QUERY_SOCKET: c_int = 3;
pub const CF_QUERY_TIMER_CONNECT: c_int = 4;
pub const CF_QUERY_TIMER_APPCONNECT: c_int = 5;
pub const CF_QUERY_HTTP_VERSION: c_int = 10;
pub const CF_QUERY_IS_MULTIPLEX: c_int = 11;
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
pub const FIRSTSOCKET: i8 = 0;

pub const TIMER_APPCONNECT: c_int = 5;
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

const c_ext = struct {
    extern fn Curl_failf(data: ?*CurlEasy, fmt: [*:0]const u8, ...) callconv(.c) void;
    extern fn Curl_infof(data: ?*CurlEasy, fmt: [*:0]const u8, ...) callconv(.c) void;
    extern fn Curl_trc_cf_infof(data: ?*CurlEasy, cf: ?*CurlCfilter, fmt: [*:0]const u8, ...) callconv(.c) void;
    extern fn Curl_trc_is_verbose_fn(data: ?*CurlEasy) callconv(.c) bool;
    extern fn Curl_pgrsTime(data: ?*CurlEasy, id: c_int) callconv(.c) void;
    extern fn Curl_pgrsTimeWas(data: ?*CurlEasy, timer: c_int, timestamp: CurlTime) callconv(.c) void;
    extern fn Curl_pgrs_now(data: ?*CurlEasy) callconv(.c) *const CurlTime;
    extern fn Curl_peer_link(pdest: *?*CurlPeer, src: ?*CurlPeer) callconv(.c) void;
    extern fn Curl_peer_unlink(ppeer: *?*CurlPeer) callconv(.c) void;
    extern fn curlx_inet_pton(af: c_int, src: [*:0]const u8, dst: *anyopaque) callconv(.c) c_int;
    extern "c" fn fopen(filename: [*:0]const u8, mode: [*:0]const u8) callconv(.c) ?*std.c.FILE;
    extern "c" fn fclose(file: *std.c.FILE) callconv(.c) c_int;
    extern "c" fn fseek(stream: *std.c.FILE, offset: c_long, whence: c_int) callconv(.c) c_int;
    extern "c" fn ftell(stream: *std.c.FILE) callconv(.c) c_long;
    extern "c" fn fread(ptr: *anyopaque, size: usize, nmemb: usize, stream: *std.c.FILE) callconv(.c) usize;
    extern fn Curl_slist_append_nodup(list: ?*curl_slist, data: [*:0]u8) callconv(.c) ?*curl_slist;
    extern fn curl_slist_free_all(list: ?*curl_slist) callconv(.c) void;
    extern fn curlx_base64_decode(src: [*:0]const u8, outptr: *?[*]u8, outlen: *usize) callconv(.c) CURLcode;
    extern fn curlx_base64_encode(inputbuff: ?[*]const u8, insize: usize, outptr: *?[*:0]u8, outlen: *usize) callconv(.c) CURLcode;
    extern fn curl_msnprintf(buffer: [*]u8, maxlength: usize, format: [*:0]const u8, ...) callconv(.c) c_int;
    extern fn curlx_strerror(err: c_int, buf: [*]u8, buflen: usize) callconv(.c) [*:0]const u8;
    extern fn Curl_cert_hostcheck(match_pattern: [*:0]const u8, match_len: usize, hostname: [*:0]const u8, hostlen: usize) callconv(.c) bool;
    extern fn Curl_timeleft_ms(data: ?*CurlEasy) callconv(.c) i64;
    extern fn Curl_socket_check(readfd0: curl_socket_t, readfd1: curl_socket_t, writefd: curl_socket_t, timeout_ms: i64) callconv(.c) c_int;

    extern fn Curl_cf_create(pcf: *?*CurlCfilter, cft: *const CurlCftype, ctx: ?*anyopaque) callconv(.c) CURLcode;
    extern fn Curl_cf_def_cntrl(cf: *CurlCfilter, data: ?*CurlEasy, event: c_int, arg1: c_int, arg2: ?*anyopaque) callconv(.c) CURLcode;
    extern fn Curl_cf_def_conn_is_alive(cf: *CurlCfilter, data: ?*CurlEasy, input_pending: *bool) callconv(.c) bool;
    extern fn Curl_cf_def_conn_keep_alive(cf: *CurlCfilter, data: ?*CurlEasy) callconv(.c) CURLcode;
    extern fn Curl_cf_def_query(cf: *CurlCfilter, data: ?*CurlEasy, query: c_int, pres1: ?*c_int, pres2: ?*anyopaque) callconv(.c) CURLcode;

    extern fn Curl_conn_cf_add(data: ?*CurlEasy, conn: ?*ConnectData, sockindex: i8, cf: *CurlCfilter) callconv(.c) void;
    extern fn Curl_conn_cf_insert_after(cf_at: *CurlCfilter, cf_new: *CurlCfilter) callconv(.c) void;
    extern fn Curl_conn_cf_discard(pcf: *?*CurlCfilter, data: ?*CurlEasy) callconv(.c) void;
    extern fn Curl_conn_cf_discard_chain(pcf: *?*CurlCfilter, data: ?*CurlEasy) callconv(.c) void;
    extern fn Curl_conn_cf_connect(cf: ?*CurlCfilter, data: ?*CurlEasy, done: *bool) callconv(.c) CURLcode;
    extern fn Curl_conn_cf_adjust_pollset(cf: ?*CurlCfilter, data: ?*CurlEasy, ps: ?*EasyPollset) callconv(.c) void;
    extern fn Curl_conn_cf_data_pending(cf: ?*CurlCfilter, data: ?*const CurlEasy) callconv(.c) bool;
    extern fn Curl_conn_cf_send(cf: ?*CurlCfilter, data: ?*CurlEasy, buf: ?*const anyopaque, len: usize, eos: bool, pnwritten: *usize) callconv(.c) CURLcode;
    extern fn Curl_conn_cf_recv(cf: ?*CurlCfilter, data: ?*CurlEasy, buf: [*]u8, len: usize, pnread: *usize) callconv(.c) CURLcode;
    extern fn Curl_conn_cf_cntrl(cf: ?*CurlCfilter, data: ?*CurlEasy, ignore_result: bool, event: c_int, arg1: c_int, arg2: ?*anyopaque) callconv(.c) CURLcode;
    extern fn Curl_conn_cf_get_socket(cf: ?*CurlCfilter, data: ?*CurlEasy) callconv(.c) curl_socket_t;
    extern fn Curl_conn_cf_poll(cf: *CurlCfilter, data: ?*CurlEasy, timeout_ms: i64) callconv(.c) c_int;
    extern fn Curl_conn_get_origin(conn: ?*ConnectData, sockindex: i8) callconv(.c) ?*CurlPeer;
    extern fn Curl_conn_get_first_peer(conn: ?*ConnectData, sockindex: i8) callconv(.c) ?*CurlPeer;
    extern fn Curl_conn_is_ip_connected(data: ?*CurlEasy, sockindex: i8) callconv(.c) bool;

    extern fn Curl_pollset_set(data: ?*CurlEasy, ps: ?*EasyPollset, sock: curl_socket_t, do_in: bool, do_out: bool) callconv(.c) CURLcode;

    extern fn Curl_cshutdn_timeleft_ms(data: ?*CurlEasy, conn: ?*ConnectData, sockindex: i8) callconv(.c) i64;
    extern fn Curl_cshutdn_start_timer(data: ?*CurlEasy, sockindex: i8, timeout_ms: i64) callconv(.c) void;
    extern fn Curl_cshutdn_clear_timer(data: ?*CurlEasy, sockindex: i8) callconv(.c) void;

    // Accessor helpers in lib/url.c (#ifdef USE_SSL)
    extern fn Curl_vtls_acc_data_certs(data: ?*CurlEasy) callconv(.c) ?*CurlCertinfo;
    extern fn Curl_vtls_acc_data_conn(data: ?*CurlEasy) callconv(.c) ?*ConnectData;
    extern fn Curl_vtls_acc_conn_cfilter(conn: ?*ConnectData, sockindex: i8) callconv(.c) ?*CurlCfilter;
    extern fn Curl_vtls_acc_data_ssl_easy_config(data: ?*CurlEasy, is_proxy: bool) callconv(.c) ?*SslEasyConfig;
    extern fn Curl_vtls_acc_conn_ssl_filter_config(conn: ?*ConnectData, is_proxy: bool) callconv(.c) ?*SslFilterConfig;
    extern fn Curl_vtls_acc_cf_ssl_create_params(data: ?*CurlEasy, conn: ?*ConnectData, wanted: *u8, preferred: *u8, only_10: *bool, use_alpn: *bool) callconv(.c) void;
    extern fn Curl_vtls_acc_cf_proxy_create_params(data: ?*CurlEasy, conn: ?*ConnectData, wanted: *u8, use_alpn: *bool) callconv(.c) void;
    extern fn Curl_vtls_acc_conn_via_peer(conn: ?*ConnectData, sockindex: i8) callconv(.c) ?*CurlPeer;
    extern fn Curl_vtls_acc_conn_set_multiplex(conn: ?*ConnectData, val: bool) callconv(.c) void;
    extern fn Curl_vtls_acc_conn_set_httpversion_seen(conn: ?*ConnectData, ver: u8) callconv(.c) void;
    extern fn Curl_vtls_acc_conn_set_proxy_ssl_connected(conn: ?*ConnectData, sockindex: i8, val: bool) callconv(.c) void;
    extern fn Curl_vtls_acc_scache_params(data: ?*CurlEasy, pscache: *?*CurlSslScache, has_share_scache: *bool, ptrc_feat: *?*CurlTrcFeat) callconv(.c) void;
    extern fn Curl_vtls_acc_get_scache(data: ?*CurlEasy) callconv(.c) ?*CurlSslScache;
    extern fn Curl_vtls_acc_pinned_pubkey(data: ?*CurlEasy, is_proxy: bool) callconv(.c) ?[*:0]const u8;
    extern fn Curl_vtls_acc_ssl_certinfo(data: ?*CurlEasy) callconv(.c) bool;
    extern fn Curl_vtls_acc_ssl_fsslctx(data: ?*CurlEasy, pfsslctx: *?*const anyopaque, pfsslctxp: *?*anyopaque) callconv(.c) bool;
    extern fn Curl_vtls_acc_ssl_key_passwd(data: ?*CurlEasy, is_proxy: bool) callconv(.c) ?[*:0]const u8;
    extern fn Curl_vtls_acc_ssl_key(data: ?*CurlEasy, is_proxy: bool) callconv(.c) ?[*:0]const u8;
    extern fn Curl_vtls_acc_ssl_key_type(data: ?*CurlEasy, is_proxy: bool) callconv(.c) ?[*:0]const u8;
    extern fn Curl_vtls_acc_ssl_cert(data: ?*CurlEasy, is_proxy: bool) callconv(.c) ?[*:0]const u8;
    extern fn Curl_vtls_acc_ssl_cert_type(data: ?*CurlEasy, is_proxy: bool) callconv(.c) ?[*:0]const u8;
    extern fn Curl_vtls_acc_ssl_cert_blob(data: ?*CurlEasy, is_proxy: bool) callconv(.c) ?*const CurlBlob;
    extern fn Curl_vtls_acc_ssl_ca_info_blob(data: ?*CurlEasy, is_proxy: bool) callconv(.c) ?*const CurlBlob;
    extern fn Curl_vtls_acc_ssl_cainfo(data: ?*CurlEasy, is_proxy: bool) callconv(.c) ?[*:0]const u8;
    extern fn Curl_vtls_acc_ssl_capath(data: ?*CurlEasy, is_proxy: bool) callconv(.c) ?[*:0]const u8;
    extern fn Curl_vtls_acc_ssl_cipher_list(data: ?*CurlEasy, is_proxy: bool) callconv(.c) ?[*:0]const u8;
    extern fn Curl_vtls_acc_ssl_cipher13_list(data: ?*CurlEasy, is_proxy: bool) callconv(.c) ?[*:0]const u8;
    extern fn Curl_vtls_acc_ssl_ec_curves(data: ?*CurlEasy) callconv(.c) ?[*:0]const u8;
    extern fn Curl_vtls_acc_ssl_signature_algorithms(data: ?*CurlEasy) callconv(.c) ?[*:0]const u8;
    extern fn Curl_vtls_acc_ssl_crlfile(data: ?*CurlEasy, is_proxy: bool) callconv(.c) ?[*:0]const u8;
    extern fn Curl_vtls_acc_ssl_issuercert(data: ?*CurlEasy, is_proxy: bool) callconv(.c) ?[*:0]const u8;
    extern fn Curl_vtls_acc_ssl_issuercert_blob(data: ?*CurlEasy, is_proxy: bool) callconv(.c) ?*const CurlBlob;
    extern fn Curl_vtls_acc_ssl_username(data: ?*CurlEasy, is_proxy: bool) callconv(.c) ?[*:0]const u8;
    extern fn Curl_vtls_acc_ssl_password(data: ?*CurlEasy, is_proxy: bool) callconv(.c) ?[*:0]const u8;
    extern fn Curl_vtls_acc_ssl_engine(data: ?*CurlEasy) callconv(.c) ?[*:0]const u8;
    extern fn Curl_vtls_acc_ssl_engine_default(data: ?*CurlEasy) callconv(.c) bool;
    extern fn Curl_vtls_acc_ssl_buffer_size(data: ?*CurlEasy) callconv(.c) c_int;
    extern fn Curl_vtls_acc_ssl_ca_cache_timeout(data: ?*CurlEasy) callconv(.c) c_int;
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
            .openssl => &openssl_backend.Curl_ssl_openssl,
            .mbedtls => &mbedtls_backend.Curl_ssl_mbedtls,
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

const vtls_impl = struct {
    pub var Curl_ssl: *const CurlSsl = switch (backend_options.ssl) {
        .schannel => &schannel_backend.Curl_ssl_schannel,
        .openssl => &openssl_backend.Curl_ssl_openssl,
        .mbedtls => &mbedtls_backend.Curl_ssl_mbedtls,
        else => &Curl_ssl_multi,
    };

    pub const Curl_ssl_multi = CurlSsl{
        .info = .{ .id = CURLSSLBACKEND_NONE, .name = "multi" },
        .supports = 0,
        .sizeof_ssl_backend_data = std.math.maxInt(usize),
        .init = multisslInit,
        .cleanup = null,
        .version = multisslVersion,
        .shut_down = null,
        .data_pending = null,
        .random = multisslRandom,
        .cert_status_request = null,
        .do_connect = multisslConnect,
        .adjust_pollset = multisslAdjustPollset,
        .get_internals = multisslGetInternals,
        .close = multisslClose,
        .close_all = null,
        .engines_list = null,
        .sha256sum = null,
        .recv_plain = multisslRecvPlain,
        .send_plain = multisslSendPlain,
        .get_channel_binding = null,
    };

    pub var Curl_cft_ssl = CurlCftype{
        .name = "SSL",
        .flags = CF_TYPE_SSL,
        .log_level = CF_LVL_SSL,
        .destroy = cfSslDestroy,
        .do_connect = cfSslConnect,
        .do_shutdown = cfSslShutdown,
        .adjust_pollset = cfSslAdjustPollset,
        .has_data_pending = cfSslDataPending,
        .do_send = cfSslSend,
        .do_recv = cfSslRecv,
        .cntrl = cfSslCntrl,
        .is_alive = cfSslIsAlive,
        .keep_alive = c_ext.Curl_cf_def_conn_keep_alive,
        .query = cfSslQuery,
    };

    pub var Curl_cft_ssl_proxy = CurlCftype{
        .name = "SSL-PROXY",
        .flags = CF_TYPE_SSL | CF_TYPE_PROXY,
        .log_level = CF_LVL_SSL,
        .destroy = cfSslDestroy,
        .do_connect = cfSslConnect,
        .do_shutdown = cfSslShutdown,
        .adjust_pollset = cfSslAdjustPollset,
        .has_data_pending = cfSslDataPending,
        .do_send = cfSslSend,
        .do_recv = cfSslRecv,
        .cntrl = cfSslCntrl,
        .is_alive = cfSslIsAlive,
        .keep_alive = c_ext.Curl_cf_def_conn_keep_alive,
        .query = cfSslQuery,
    };

    pub fn Curl_ssl_init() callconv(.c) c_int {
        if (init_ssl) return 1;
        init_ssl = true;
        if (Curl_ssl.init) |init_fn| {
            return init_fn();
        }
        return 1;
    }

    pub fn Curl_ssl_cleanup() callconv(.c) void {
        if (init_ssl) {
            if (Curl_ssl.cleanup) |cleanup_fn| {
                cleanup_fn();
            }
            init_ssl = false;
        }
    }

    pub fn Curl_ssl_version(buffer: [*]u8, size: usize) callconv(.c) void {
        _ = Curl_ssl.version(buffer, size);
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
            if (cur.cft == &Curl_cft_ssl or cur.cft == &Curl_cft_ssl_proxy) {
                if (Curl_ssl.data_pending) |dp| {
                    return dp(cur, null);
                }
            }
        }
        return false;
    }

    pub fn Curl_ssl_get_internals(connssl: *SslConnectData, info: c_uint) callconv(.c) ?*anyopaque {
        if (Curl_ssl.get_internals) |gi| {
            return gi(connssl, info);
        }
        return null;
    }

    pub fn Curl_ssl_engines_list(data: ?*CurlEasy) callconv(.c) ?*curl_slist {
        if (Curl_ssl.engines_list) |el| {
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
        if (Curl_ssl.random) |rand_fn| {
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
        if (Curl_ssl.sha256sum) |sha_fn| {
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
            const sha_fn = Curl_ssl.sha256sum orelse return result;
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
        if (Curl_ssl.cert_status_request) |csr| {
            return csr();
        }
        return false;
    }

    pub fn Curl_ssl_false_start(data: ?*CurlEasy) callconv(.c) bool {
        _ = data;
        return false;
    }

    pub fn Curl_ssl_setup_x509_store(cf: *CurlCfilter, data: ?*CurlEasy, ssl_ctx: ?*anyopaque) callconv(.c) CURLcode {
        if (comptime backend_options.ssl == .openssl) {
            return openssl_backend.Curl_ossl_setup_x509_store(cf, data, ssl_ctx);
        }
        return CURLE_OK;
    }

    pub fn Curl_ssl_get_x509_store(cf: *CurlCfilter, data: ?*CurlEasy) callconv(.c) ?*anyopaque {
        if (comptime backend_options.ssl == .openssl) {
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
        if (Curl_ssl.get_channel_binding) |cb| {
            return cb(data, sockindex, binding);
        }
        return CURLE_OK;
    }

    pub fn Curl_ssl_close_all(data: ?*CurlEasy) callconv(.c) void {
        if (Curl_ssl.close_all) |ca| {
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

    fn multisslInit() callconv(.c) c_int {
        if (multisslSetup(null) != 0) return 1;
        if (Curl_ssl.init) |init_fn| return init_fn();
        return 1;
    }

    fn multisslVersion(buffer: [*]u8, size: usize) callconv(.c) usize {
        _ = multisslSetup(null);
        return Curl_ssl.version(buffer, size);
    }

    fn multisslRandom(data: ?*CurlEasy, entropy: [*]u8, length: usize) callconv(.c) CURLcode {
        if (multisslSetup(null) != 0) return CURLE_FAILED_INIT;
        if (Curl_ssl.random) |rand_fn| return rand_fn(data, entropy, length);
        return CURLE_NOT_BUILT_IN;
    }

    fn multisslConnect(cf: *CurlCfilter, data: ?*CurlEasy, done: *bool) callconv(.c) CURLcode {
        if (multisslSetup(null) != 0) return CURLE_FAILED_INIT;
        return Curl_ssl.do_connect(cf, data, done);
    }

    fn multisslAdjustPollset(cf: *CurlCfilter, data: ?*CurlEasy, ps: ?*EasyPollset) callconv(.c) CURLcode {
        if (multisslSetup(null) != 0) return CURLE_OK;
        return Curl_ssl.adjust_pollset(cf, data, ps);
    }

    fn multisslGetInternals(connssl: *SslConnectData, info: c_uint) callconv(.c) ?*anyopaque {
        if (multisslSetup(null) != 0) return null;
        if (Curl_ssl.get_internals) |gi| return gi(connssl, info);
        return null;
    }

    fn multisslClose(cf: *CurlCfilter, data: ?*CurlEasy) callconv(.c) void {
        if (multisslSetup(null) != 0) return;
        Curl_ssl.close(cf, data);
    }

    fn multisslRecvPlain(cf: *CurlCfilter, data: ?*CurlEasy, buf: [*]u8, len: usize, pnread: *usize) callconv(.c) CURLcode {
        if (multisslSetup(null) != 0) return CURLE_FAILED_INIT;
        return Curl_ssl.recv_plain(cf, data, buf, len, pnread);
    }

    fn multisslSendPlain(cf: *CurlCfilter, data: ?*CurlEasy, mem_ptr: ?*const anyopaque, len: usize, pnwritten: *usize) callconv(.c) CURLcode {
        if (multisslSetup(null) != 0) return CURLE_FAILED_INIT;
        return Curl_ssl.send_plain(cf, data, mem_ptr, len, pnwritten);
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
        ctx.ssl_impl = Curl_ssl;
        ctx.alpn = alpn;
        io_buffers.Curl_bufq_init2(&ctx.earlydata, CURL_SSL_EARLY_MAX, 1, BUFQ_OPT_NO_SPARES);
        ctx.backend = mem.calloc(1, ctx.ssl_impl.sizeof_ssl_backend_data);
        if (ctx.backend == null) {
            mem.free(ctx);
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
        mem.free(ctx.backend);
        mem.free(ctx);
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
        const result = c_ext.Curl_cf_create(&cf, &Curl_cft_ssl, ctx);
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
        const result = c_ext.Curl_cf_create(&cf, &Curl_cft_ssl_proxy, ctx);
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
            if (cur.cft == &Curl_cft_ssl) {
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
        if (cft == &Curl_cft_ssl or cft == &Curl_cft_ssl_proxy) {
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

    fn cfSslConnect(cf: *CurlCfilter, data: ?*CurlEasy, done: *bool) callconv(.c) CURLcode {
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

    fn cfSslShutdown(cf: *CurlCfilter, data: ?*CurlEasy, done: *bool) callconv(.c) CURLcode {
        const connssl: *SslConnectData = @ptrCast(@alignCast(cf.ctx orelse return CURLE_OK));
        if (cf.isShutdown() or !cf.isConnected() or connssl.state != ssl_connection_complete) {
            done.* = true;
            return CURLE_OK;
        }
        done.* = false;
        connssl.io_need = CURL_SSL_IO_NEED_NONE;
        var result: CURLcode = CURLE_OK;
        if (connssl.ssl_impl.shut_down) |sd| {
            result = sd(cf, data, true, done);
        } else {
            done.* = true;
        }
        return result;
    }

    fn cfSslDataPending(cf: *CurlCfilter, data: ?*const CurlEasy) callconv(.c) bool {
        const connssl: *SslConnectData = @ptrCast(@alignCast(cf.ctx orelse return false));
        if (connssl.ssl_impl.data_pending) |dp| {
            if (dp(cf, data)) return true;
        }
        if (cf.next) |next| {
            return next.cft.has_data_pending(next, data);
        }
        return false;
    }

    fn cfSslAdjustPollset(cf: *CurlCfilter, data: ?*CurlEasy, ps: ?*EasyPollset) callconv(.c) CURLcode {
        const connssl: *SslConnectData = @ptrCast(@alignCast(cf.ctx orelse return CURLE_OK));
        var result: CURLcode = CURLE_OK;
        if (!cf.isConnected()) {
            result = connssl.ssl_impl.adjust_pollset(cf, data, ps);
            c_ext.Curl_conn_cf_adjust_pollset(cf.next, data, ps);
        } else if (connssl.state != ssl_connection_complete or !cf.isShutdown()) {
            result = connssl.ssl_impl.adjust_pollset(cf, data, ps);
        }
        return result;
    }

    fn cfSslSend(
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

        return connssl.ssl_impl.send_plain(cf, data, buf, len, pnwritten);
    }

    fn cfSslRecv(
        cf: *CurlCfilter,
        data: ?*CurlEasy,
        buf: [*]u8,
        len: usize,
        pnread: *usize,
    ) callconv(.c) CURLcode {
        const connssl: *SslConnectData = @ptrCast(@alignCast(cf.ctx orelse return CURLE_FAILED_INIT));
        pnread.* = 0;

        if (connssl.state == ssl_connection_deferred) {
            if (connssl.earlydata_state == ssl_earlydata_await) {
                connssl.earlydata_state = ssl_earlydata_sending;
            }
            var done = false;
            const result = sslCfConnect(cf, data, &done);
            if (result != CURLE_OK) return result;
            if (!done) return CURLE_AGAIN;
        }

        const result = connssl.ssl_impl.recv_plain(cf, data, buf, len, pnread);
        if (result == CURLE_OK and pnread.* > 0) {
            var b: [1]u8 = undefined;
            var n: usize = 0;
            const r2 = connssl.ssl_impl.recv_plain(cf, data, &b, 0, &n);
            connssl.set_input_pending(r2 != CURLE_AGAIN);
        } else {
            connssl.set_input_pending(false);
        }
        return result;
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

    fn cfSslDestroy(cf: *CurlCfilter, data: ?*CurlEasy) callconv(.c) void {
        if (cf.ctx) |raw_ctx| {
            const ctx: *SslConnectData = @ptrCast(@alignCast(raw_ctx));
            cfSslClose(cf, data);
            Curl_ssl_peer_cleanup(&ctx.peer);
            cfCtxFree(ctx);
            cf.ctx = null;
        }
    }

    fn cfSslCntrl(
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

    fn cfSslIsAlive(cf: *CurlCfilter, data: ?*CurlEasy, input_pending: *bool) callconv(.c) bool {
        if (cf.next) |next| {
            return next.cft.is_alive(next, data, input_pending);
        }
        return false;
    }

    fn cfSslQuery(
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

const CURLE_UNKNOWN_OPTION: CURLcode = 48;

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

    const SCH_CRED_VERSION: DWORD = 0x00000004;
    const SCHANNEL_CRED_VERSION: DWORD = 0x00000004;
    const SCH_CRED_MANUAL_CRED_VALIDATION: DWORD = 0x00000008;
    const SCH_CRED_NO_DEFAULT_CREDS: DWORD = 0x00000010;
    const SCH_CRED_AUTO_CRED_VALIDATION: DWORD = 0x00000020;
    const SCH_CRED_USE_DEFAULT_CRYPTO: DWORD = 0x00000040;
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
    const CURL_SCHANNEL_BUFFER_STEP_FACTOR: usize = 2;

    const PROV_RSA_FULL: DWORD = 1;
    const CRYPT_VERIFYCONTEXT: DWORD = 0xF0000000;
    const CRYPT_SILENT: DWORD = 0x00000040;

    const X509_ASN_ENCODING: DWORD = 0x00000001;
    const PKCS_7_ASN_ENCODING: DWORD = 0x00010000;

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

    pub const SecPkgContext_Bindings = extern struct {
        BindingsLength: ULONG,
        Bindings: ?*anyopaque,
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

    pub const CRYPTO_SETTINGS = extern struct {
        eAlgorithmUsage: c_uint,
        pszAlgId: ?[*:0]const u16,
        cChainingModes: DWORD,
        rgstrChainingModes: ?*?[*:0]const u16,
        dwMinBitLength: DWORD,
        dwMaxBitLength: DWORD,
    };

    pub const TLS_PARAMETERS = extern struct {
        cAlpnIds: DWORD,
        rgstrAlpnIds: ?*?[*:0]const u16,
        grbitDisabledProtocols: DWORD,
        cDisabledCrypto: DWORD,
        pDisabledCrypto: ?[*]CRYPTO_SETTINGS,
        dwFlags: DWORD,
    };

    pub const SCH_CREDENTIALS = extern struct {
        dwVersion: DWORD,
        dwCredFormat: DWORD,
        cCreds: DWORD,
        paCred: ?*?*const CERT_CONTEXT,
        hRootStore: HCERTSTORE,
        cMappers: DWORD,
        aphMappers: ?*anyopaque,
        dwSessionLifespan: DWORD,
        dwFlags: DWORD,
        cTlsParameters: DWORD,
        pTlsParameters: ?[*]TLS_PARAMETERS,
    };

    pub const CRYPT_DATA_BLOB = extern struct {
        cbData: DWORD,
        pbData: ?[*]u8,
    };

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
        time_stamp: TimeStamp,
        client_cert_store: HCERTSTORE,
        cached_cert_store: HCERTSTORE,
        refcount: c_int,
    };

    pub const CurlSchannelCtxt = extern struct {
        ctxt_handle: CtxtHandle,
        time_stamp: TimeStamp,
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
            ptsExpiry: *TimeStamp,
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
        extern "crypt32" fn CertCloseStore(hCertStore: HCERTSTORE, dwFlags: DWORD) callconv(sspi_cc) BOOL;
        extern "crypt32" fn CertFreeCertificateContext(pCertContext: ?*const CERT_CONTEXT) callconv(sspi_cc) BOOL;
        extern "advapi32" fn CryptAcquireContextA(phProv: *HCRYPTPROV, pszContainer: ?[*:0]const u8, pszProvider: ?[*:0]const u8, dwProvType: DWORD, dwFlags: DWORD) callconv(sspi_cc) BOOL;
        extern "advapi32" fn CryptGenRandom(hProv: HCRYPTPROV, dwLen: DWORD, pbBuffer: [*]u8) callconv(sspi_cc) BOOL;
        extern "advapi32" fn CryptReleaseContext(hProv: HCRYPTPROV, dwFlags: DWORD) callconv(sspi_cc) BOOL;
        extern "bcrypt" fn BCryptOpenAlgorithmProvider(phAlgorithm: *BCRYPT_ALG_HANDLE, pszAlgId: [*:0]const u16, pszImplementation: ?[*:0]const u16, dwFlags: ULONG) callconv(sspi_cc) NTSTATUS;
        extern "bcrypt" fn BCryptCloseAlgorithmProvider(hAlgorithm: BCRYPT_ALG_HANDLE, dwFlags: ULONG) callconv(sspi_cc) NTSTATUS;
        extern "bcrypt" fn BCryptGetProperty(hObject: BCRYPT_ALG_HANDLE, pszProperty: [*:0]const u16, pbOutput: [*]u8, cbOutput: ULONG, pcbResult: *ULONG, dwFlags: ULONG) callconv(sspi_cc) NTSTATUS;
        extern "bcrypt" fn BCryptCreateHash(hAlgorithm: BCRYPT_ALG_HANDLE, phHash: *BCRYPT_HASH_HANDLE, pbHashObject: [*]u8, cbHashObject: ULONG, pbSecret: ?[*]u8, cbSecret: ULONG, dwFlags: ULONG) callconv(sspi_cc) NTSTATUS;
        extern "bcrypt" fn BCryptHashData(hHash: BCRYPT_HASH_HANDLE, pbInput: [*]const u8, cbInput: ULONG, dwFlags: ULONG) callconv(sspi_cc) NTSTATUS;
        extern "bcrypt" fn BCryptFinishHash(hHash: BCRYPT_HASH_HANDLE, pbOutput: [*]u8, cbOutput: ULONG, dwFlags: ULONG) callconv(sspi_cc) NTSTATUS;
        extern "bcrypt" fn BCryptDestroyHash(hHash: BCRYPT_HASH_HANDLE) callconv(sspi_cc) NTSTATUS;
        extern fn Curl_verify_certificate(cf: *CurlCfilter, data: ?*CurlEasy) callconv(.c) CURLcode;
        extern fn Curl_verify_host(cf: *CurlCfilter, data: ?*CurlEasy, pCertContextServer: *CERT_CONTEXT) callconv(.c) CURLcode;
        extern fn curlx_verify_windows_version(majorVersion: c_uint, minorVersion: c_uint, buildVersion: c_uint, platform: c_int, condition: c_int) callconv(.c) bool;
        extern fn Curl_sspi_strerror(err: i32, buf: [*]u8, buflen: usize) callconv(.c) [*:0]const u8;
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

    fn setSslVersionMinMax(enabled_protocols: *DWORD, cf: *CurlCfilter, data: ?*CurlEasy) CURLcode {
        const conn_config = vtls_impl.Curl_ssl_cf_get_filter_config(cf) orelse return CURLE_SSL_CONNECT_ERROR;
        var ssl_version = conn_config.version;
        var ssl_version_max: u32 = @intCast(conn_config.version_max);

        switch (ssl_version) {
            CURL_SSLVERSION_DEFAULT, CURL_SSLVERSION_TLSv1 => {
                ssl_version = CURL_SSLVERSION_TLSv1_0;
            },
            else => {},
        }

        switch (ssl_version_max) {
            CURL_SSLVERSION_MAX_NONE, CURL_SSLVERSION_MAX_DEFAULT => {
                ssl_version_max = CURL_SSLVERSION_MAX_TLSv1_3;
            },
            else => {},
        }

        var i: u8 = ssl_version;
        while (@as(u32, i) <= (ssl_version_max >> 16)) : (i += 1) {
            switch (i) {
                CURL_SSLVERSION_TLSv1_0 => enabled_protocols.* |= SP_PROT_TLS1_0_CLIENT,
                CURL_SSLVERSION_TLSv1_1 => enabled_protocols.* |= SP_PROT_TLS1_1_CLIENT,
                CURL_SSLVERSION_TLSv1_2 => enabled_protocols.* |= SP_PROT_TLS1_2_CLIENT,
                CURL_SSLVERSION_TLSv1_3 => enabled_protocols.* |= SP_PROT_TLS1_3_CLIENT,
                CURL_SSLVERSION_SSLv2, CURL_SSLVERSION_SSLv3 => {
                    c_ext.Curl_failf(data, "SSL versions not supported");
                    return CURLE_NOT_BUILT_IN;
                },
                else => {
                    c_ext.Curl_failf(data, "Unrecognized parameter passed via CURLOPT_SSLVERSION");
                    return CURLE_SSL_CONNECT_ERROR;
                },
            }
        }
        return CURLE_OK;
    }

    fn schannelAcquireCredentialHandle(cf: *CurlCfilter, data: ?*CurlEasy) CURLcode {
        const connssl: *SslConnectData = @ptrCast(@alignCast(cf.ctx orelse return CURLE_SSL_CONNECT_ERROR));
        const backend: *SchannelSslBackendData = @ptrCast(@alignCast(connssl.backend orelse return CURLE_SSL_CONNECT_ERROR));
        const conn_config = vtls_impl.Curl_ssl_cf_get_filter_config(cf) orelse return CURLE_SSL_CONNECT_ERROR;
        const sec_fn = win_ext.Curl_pSecFn orelse return CURLE_SSL_CONNECT_ERROR;

        var flags: DWORD = SCH_CRED_NO_DEFAULT_CREDS | SCH_CRED_REVOCATION_CHECK_CHAIN;
        if (backend.use_manual_cred_validation()) {
            flags = SCH_CRED_MANUAL_CRED_VALIDATION | SCH_CRED_IGNORE_NO_REVOCATION_CHECK | SCH_CRED_IGNORE_REVOCATION_OFFLINE;
        } else {
            flags |= SCH_CRED_AUTO_CRED_VALIDATION;
            if (conn_config.revoke_best_effort()) {
                flags |= SCH_CRED_IGNORE_NO_REVOCATION_CHECK | SCH_CRED_IGNORE_REVOCATION_OFFLINE;
            } else if (conn_config.no_revoke()) {
                flags &= ~SCH_CRED_REVOCATION_CHECK_CHAIN;
                flags |= SCH_CRED_IGNORE_NO_REVOCATION_CHECK | SCH_CRED_IGNORE_REVOCATION_OFFLINE;
            }
        }

        var enabled_protocols: DWORD = 0;
        const result = setSslVersionMinMax(&enabled_protocols, cf, data);
        if (result != CURLE_OK) return result;

        const raw_cred = mem.calloc(1, @sizeOf(CurlSchannelCred)) orelse return CURLE_OUT_OF_MEMORY;
        const cred: *CurlSchannelCred = @ptrCast(@alignCast(raw_cred));
        cred.refcount = 1;
        backend.cred = cred;

        var schannel_cred = std.mem.zeroes(SCHANNEL_CRED);
        schannel_cred.dwVersion = SCHANNEL_CRED_VERSION;
        schannel_cred.dwFlags = flags | SCH_USE_STRONG_CRYPTO;
        schannel_cred.grbitEnabledProtocols = enabled_protocols;

        const sspi_status = sec_fn.AcquireCredentialsHandleA(
            null,
            UNISP_NAME_A,
            SECPKG_CRED_OUTBOUND,
            null,
            &schannel_cred,
            null,
            null,
            &cred.cred_handle,
            &cred.time_stamp,
        );

        if (sspi_status != SEC_E_OK) {
            mem.free(cred);
            backend.cred = null;
            return CURLE_SSL_CONNECT_ERROR;
        }
        return CURLE_OK;
    }

    fn schannelCredFree(ptr: ?*anyopaque) callconv(.c) void {
        const cred_opt: ?*CurlSchannelCred = if (ptr) |p| @ptrCast(@alignCast(p)) else null;
        if (cred_opt) |cred| {
            cred.refcount -= 1;
            if (cred.refcount == 0) {
                if (win_ext.Curl_pSecFn) |sec_fn| {
                    _ = sec_fn.FreeCredentialsHandle(&cred.cred_handle);
                }
                if (cred.client_cert_store) |cs| {
                    _ = win_ext.CertCloseStore(cs, 0);
                }
                if (cred.cached_cert_store) |ccs| {
                    _ = win_ext.CertCloseStore(ccs, 0);
                }
                mem.free(cred);
            }
        }
    }

    fn schannelConnectStep1(cf: *CurlCfilter, data: ?*CurlEasy) CURLcode {
        const connssl: *SslConnectData = @ptrCast(@alignCast(cf.ctx orelse return CURLE_SSL_CONNECT_ERROR));
        const backend: *SchannelSslBackendData = @ptrCast(@alignCast(connssl.backend orelse return CURLE_SSL_CONNECT_ERROR));
        const conn_config = vtls_impl.Curl_ssl_cf_get_filter_config(cf) orelse return CURLE_SSL_CONNECT_ERROR;
        const sec_fn = win_ext.Curl_pSecFn orelse return CURLE_SSL_CONNECT_ERROR;

        var result: CURLcode = CURLE_OK;

        backend.set_use_alpn(connssl.alpn != null);
        backend.set_use_manual_cred_validation(false);

        if (conn_config.CAfile != null or conn_config.ca_info_blob != null) {
            backend.set_use_manual_cred_validation(true);
        } else if (!conn_config.verifypeer()) {
            backend.set_use_manual_cred_validation(true);
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
            if (result != CURLE_OK) return result;
            if (conn_config.primary_cache_session() and connssl.peer.scache_key != null) {
                vtls_scache_asn1.Curl_ssl_scache_lock_zig(data, scache, has_share_scache);
                if (backend.cred) |cred| {
                    const rc = vtls_scache_asn1.Curl_ssl_scache_add_obj_zig(
                        cf,
                        data,
                        scache,
                        conn_config,
                        trc_feat,
                        connssl.peer.scache_key.?,
                        cred,
                        schannelCredFree,
                    );
                    if (rc == CURLE_OK) {
                        cred.refcount += 1;
                    }
                }
                vtls_scache_asn1.Curl_ssl_scache_unlock_zig(data, scache, has_share_scache);
            }
        }

        backend.req_flags = ISC_REQ_SEQUENCE_DETECT | ISC_REQ_REPLAY_DETECT | ISC_REQ_CONFIDENTIALITY | ISC_REQ_ALLOCATE_MEMORY | ISC_REQ_STREAM;
        if (!conn_config.auto_client_cert()) {
            backend.req_flags |= ISC_REQ_USE_SUPPLIED_CREDS;
        }
        if (backend.use_manual_cred_validation()) {
            backend.req_flags |= ISC_REQ_MANUAL_CRED_VALIDATION;
        }

        const raw_ctxt = mem.calloc(1, @sizeOf(CurlSchannelCtxt)) orelse return CURLE_OUT_OF_MEMORY;
        backend.ctxt = @ptrCast(@alignCast(raw_ctxt));

        var alpn_buffer: [128]u8 = undefined;
        var inbuf: SecBuffer = undefined;
        var inbuf_desc: SecBufferDesc = undefined;
        var outbuf: SecBuffer = undefined;
        var outbuf_desc: SecBufferDesc = undefined;

        var p_inbuf_desc: ?*SecBufferDesc = null;
        if (backend.use_alpn()) {
            var proto_buf: AlpnProtoBuf = undefined;
            if (alpnToProtoBuf(&proto_buf, connssl.alpn) == CURLE_OK and proto_buf.len > 0) {
                const list_len: u32 = @intCast(proto_buf.len);
                const total_len: u32 = 4 + 4 + list_len;
                if (total_len <= alpn_buffer.len) {
                    const ext_len: u32 = 4 + list_len;
                    @memcpy(alpn_buffer[0..4], std.mem.asBytes(&ext_len));
                    const nego_ext: u32 = SecApplicationProtocolNegotiationExt_ALPN;
                    @memcpy(alpn_buffer[4..8], std.mem.asBytes(&nego_ext));
                    const bit_len: u16 = @intCast(list_len);
                    @memcpy(alpn_buffer[8..10], std.mem.asBytes(&bit_len));
                    @memcpy(alpn_buffer[10 .. 10 + list_len], proto_buf.data[0..list_len]);
                    initSecBuffer(&inbuf, SECBUFFER_APPLICATION_PROTOCOLS, &alpn_buffer, 10 + list_len);
                    initSecBufferDesc(&inbuf_desc, @ptrCast(&inbuf), 1);
                    p_inbuf_desc = &inbuf_desc;
                }
            }
        }

        initSecBuffer(&outbuf, SECBUFFER_EMPTY, null, 0);
        initSecBufferDesc(&outbuf_desc, @ptrCast(&outbuf), 1);

        const sspi_status = sec_fn.InitializeSecurityContextA(
            &backend.cred.?.cred_handle,
            null,
            connssl.peer.sni,
            backend.req_flags,
            0,
            0,
            p_inbuf_desc,
            0,
            &backend.ctxt.?.ctxt_handle,
            &outbuf_desc,
            &backend.ret_flags,
            &backend.ctxt.?.time_stamp,
        );

        if (sspi_status != SEC_I_CONTINUE_NEEDED) {
            mem.free(backend.ctxt);
            backend.ctxt = null;
            return CURLE_SSL_CONNECT_ERROR;
        }

        if (outbuf.cbBuffer != 0 and outbuf.pvBuffer != null) {
            var written: usize = 0;
            result = c_ext.Curl_conn_cf_send(cf.next, data, outbuf.pvBuffer, outbuf.cbBuffer, false, &written);
            _ = sec_fn.FreeContextBuffer(outbuf.pvBuffer);
            if (result != CURLE_OK or outbuf.cbBuffer != written) {
                return CURLE_SSL_CONNECT_ERROR;
            }
        }

        connssl.connecting_state = ssl_connect_2;
        return CURLE_OK;
    }

    fn schannelConnectStep2(cf: *CurlCfilter, data: ?*CurlEasy) CURLcode {
        const connssl: *SslConnectData = @ptrCast(@alignCast(cf.ctx orelse return CURLE_SSL_CONNECT_ERROR));
        const backend: *SchannelSslBackendData = @ptrCast(@alignCast(connssl.backend orelse return CURLE_SSL_CONNECT_ERROR));
        const conn_config = vtls_impl.Curl_ssl_cf_get_filter_config(cf) orelse return CURLE_SSL_CONNECT_ERROR;
        const sec_fn = win_ext.Curl_pSecFn orelse return CURLE_SSL_CONNECT_ERROR;

        if (backend.encdata.buffer == null) {
            backend.encdata.offset = 0;
            backend.encdata.length = CURL_SCHANNEL_BUFFER_INIT_SIZE;
            const raw = mem.malloc(backend.encdata.length) orelse return CURLE_OUT_OF_MEMORY;
            backend.encdata.buffer = @ptrCast(raw);
        }

        while (true) {
            if (backend.encdata.length - backend.encdata.offset <= CURL_SCHANNEL_BUFFER_FREE_SIZE) {
                const new_len = backend.encdata.offset + CURL_SCHANNEL_BUFFER_FREE_SIZE * CURL_SCHANNEL_BUFFER_STEP_FACTOR;
                const raw = mem.realloc(backend.encdata.buffer, new_len) orelse return CURLE_OUT_OF_MEMORY;
                backend.encdata.buffer = @ptrCast(raw);
                backend.encdata.length = new_len;
            }

            var nread: usize = 0;
            var result = c_ext.Curl_conn_cf_recv(
                cf.next,
                data,
                backend.encdata.buffer.? + backend.encdata.offset,
                backend.encdata.length - backend.encdata.offset,
                &nread,
            );
            if (result == CURLE_AGAIN) {
                if (!backend.encdata_is_incomplete()) {
                    result = CURLE_OK;
                } else {
                    connssl.io_need = CURL_SSL_IO_NEED_RECV;
                    return CURLE_OK;
                }
            } else if (result != CURLE_OK) {
                return result;
            } else if (nread == 0) {
                return CURLE_SSL_CONNECT_ERROR;
            } else {
                backend.encdata.offset += nread;
                backend.set_encdata_is_incomplete(false);
            }

            var inbuf: [2]SecBuffer = undefined;
            var inbuf_desc: SecBufferDesc = undefined;
            initSecBuffer(&inbuf[0], SECBUFFER_TOKEN, backend.encdata.buffer, @intCast(backend.encdata.offset));
            initSecBuffer(&inbuf[1], SECBUFFER_EMPTY, null, 0);
            initSecBufferDesc(&inbuf_desc, &inbuf, 2);

            var outbuf: [3]SecBuffer = undefined;
            var outbuf_desc: SecBufferDesc = undefined;
            initSecBuffer(&outbuf[0], SECBUFFER_TOKEN, null, 0);
            initSecBuffer(&outbuf[1], SECBUFFER_ALERT, null, 0);
            initSecBuffer(&outbuf[2], SECBUFFER_EMPTY, null, 0);
            initSecBufferDesc(&outbuf_desc, &outbuf, 3);

            const sspi_status = sec_fn.InitializeSecurityContextA(
                &backend.cred.?.cred_handle,
                &backend.ctxt.?.ctxt_handle,
                connssl.peer.sni,
                backend.req_flags,
                0,
                0,
                &inbuf_desc,
                0,
                null,
                &outbuf_desc,
                &backend.ret_flags,
                &backend.ctxt.?.time_stamp,
            );

            if (sspi_status == SEC_E_INCOMPLETE_MESSAGE) {
                backend.set_encdata_is_incomplete(true);
                connssl.io_need = CURL_SSL_IO_NEED_RECV;
                return CURLE_OK;
            }

            for (0..3) |i| {
                if (outbuf[i].BufferType == SECBUFFER_TOKEN and outbuf[i].cbBuffer > 0 and outbuf[i].pvBuffer != null) {
                    var written: usize = 0;
                    result = c_ext.Curl_conn_cf_send(cf.next, data, outbuf[i].pvBuffer, outbuf[i].cbBuffer, false, &written);
                    if (result != CURLE_OK or outbuf[i].cbBuffer != written) {
                        for (0..3) |j| {
                            if (outbuf[j].pvBuffer) |pv| _ = sec_fn.FreeContextBuffer(pv);
                        }
                        return if (result != CURLE_OK) result else CURLE_SSL_CONNECT_ERROR;
                    }
                }
                if (outbuf[i].pvBuffer) |pv| {
                    _ = sec_fn.FreeContextBuffer(pv);
                }
            }

            switch (sspi_status) {
                SEC_E_OK, SEC_I_CONTINUE_NEEDED => {
                    if (inbuf[1].BufferType == SECBUFFER_EXTRA and inbuf[1].cbBuffer > 0) {
                        if (backend.encdata.offset > inbuf[1].cbBuffer) {
                            const extra_len: usize = inbuf[1].cbBuffer;
                            const src_off = backend.encdata.offset - extra_len;
                            std.mem.copyForwards(u8, backend.encdata.buffer.?[0..extra_len], backend.encdata.buffer.?[src_off .. src_off + extra_len]);
                            backend.encdata.offset = extra_len;
                        }
                    } else {
                        backend.encdata.offset = 0;
                    }
                    if (sspi_status == SEC_I_CONTINUE_NEEDED) {
                        if (inbuf[1].BufferType == SECBUFFER_EXTRA) continue;
                        connssl.io_need = CURL_SSL_IO_NEED_RECV;
                        return CURLE_OK;
                    }
                    break;
                },
                SEC_E_UNTRUSTED_ROOT, SEC_E_CERT_EXPIRED, SEC_E_WRONG_PRINCIPAL, CRYPT_E_REVOKED => {
                    return CURLE_PEER_FAILED_VERIFICATION;
                },
                CRYPT_E_NO_REVOCATION_CHECK, CRYPT_E_REVOCATION_OFFLINE => {
                    if (!conn_config.revoke_best_effort() and !conn_config.no_revoke()) {
                        return CURLE_PEER_FAILED_VERIFICATION;
                    }
                    break;
                },
                else => return CURLE_SSL_CONNECT_ERROR,
            }
        }

        if (backend.use_manual_cred_validation()) {
            const vres = win_ext.Curl_verify_certificate(cf, data);
            if (vres != CURLE_OK) return vres;
        }

        connssl.connecting_state = ssl_connect_3;
        return CURLE_OK;
    }

    fn schannelPkpPinPeerPubkey(cf: *CurlCfilter, data: ?*CurlEasy, pinnedpubkey: [*:0]const u8) CURLcode {
        const connssl: *SslConnectData = @ptrCast(@alignCast(cf.ctx orelse return CURLE_SSL_PINNEDPUBKEYNOTMATCH));
        const backend: *SchannelSslBackendData = @ptrCast(@alignCast(connssl.backend orelse return CURLE_SSL_PINNEDPUBKEYNOTMATCH));
        const sec_fn = win_ext.Curl_pSecFn orelse return CURLE_SSL_PINNEDPUBKEYNOTMATCH;

        var cert_context: ?*CERT_CONTEXT = null;
        const sspi_status = sec_fn.QueryContextAttributesA(
            &backend.ctxt.?.ctxt_handle,
            SECPKG_ATTR_REMOTE_CERT_CONTEXT,
            @ptrCast(&cert_context),
        );
        if (sspi_status != SEC_E_OK or cert_context == null) {
            return CURLE_SSL_PINNEDPUBKEYNOTMATCH;
        }
        defer _ = win_ext.CertFreeCertificateContext(cert_context);

        if (cert_context.?.pCertInfo) |ci| {
            if (ci.SubjectPublicKeyInfo.PublicKey.pbData) |pb| {
                return vtls_impl.Curl_pin_peer_pubkey(data, pinnedpubkey, pb, ci.SubjectPublicKeyInfo.PublicKey.cbData);
            }
        }
        return CURLE_SSL_PINNEDPUBKEYNOTMATCH;
    }

    fn schannelConnectStep3(cf: *CurlCfilter, data: ?*CurlEasy) CURLcode {
        const connssl: *SslConnectData = @ptrCast(@alignCast(cf.ctx orelse return CURLE_SSL_CONNECT_ERROR));
        const backend: *SchannelSslBackendData = @ptrCast(@alignCast(connssl.backend orelse return CURLE_SSL_CONNECT_ERROR));
        const sec_fn = win_ext.Curl_pSecFn orelse return CURLE_SSL_CONNECT_ERROR;

        const inc_flags: ULONG = ISC_RET_SEQUENCE_DETECT | ISC_RET_REPLAY_DETECT | ISC_RET_CONFIDENTIALITY | ISC_RET_ALLOCATED_MEMORY | ISC_RET_STREAM;
        if ((backend.ret_flags & inc_flags) != inc_flags) {
            return CURLE_SSL_CONNECT_ERROR;
        }

        if (backend.use_alpn()) {
            var alpn_result: SecPkgContext_ApplicationProtocol = std.mem.zeroes(SecPkgContext_ApplicationProtocol);
            const sspi_status = sec_fn.QueryContextAttributesA(
                &backend.ctxt.?.ctxt_handle,
                SECPKG_ATTR_APPLICATION_PROTOCOL,
                @ptrCast(&alpn_result),
            );
            if (sspi_status != SEC_E_OK) return CURLE_SSL_CONNECT_ERROR;
            if (alpn_result.ProtoNegoStatus == SecApplicationProtocolNegotiationStatus_Success) {
                const rc = vtls_impl.Curl_alpn_set_negotiated(cf, data, connssl, &alpn_result.ProtocolId, alpn_result.ProtocolIdSize);
                if (rc != CURLE_OK) return rc;
            } else if (!backend.recv_renegotiating()) {
                const rc = vtls_impl.Curl_alpn_set_negotiated(cf, data, connssl, null, 0);
                if (rc != CURLE_OK) return rc;
            }
        }

        if (c_ext.Curl_vtls_acc_ssl_certinfo(data)) {
            var cert_context: ?*CERT_CONTEXT = null;
            const st = sec_fn.QueryContextAttributesA(
                &backend.ctxt.?.ctxt_handle,
                SECPKG_ATTR_REMOTE_CERT_CONTEXT,
                @ptrCast(&cert_context),
            );
            if (st == SEC_E_OK and cert_context != null) {
                defer _ = win_ext.CertFreeCertificateContext(cert_context);
                if (cert_context.?.pbCertEncoded) |der| {
                    _ = vtls_scache_asn1.Curl_extract_certinfo_zig(
                        data,
                        0,
                        der,
                        der + cert_context.?.cbCertEncoded,
                        true,
                        @ptrCast(&vtls_impl.Curl_ssl_push_certinfo_len),
                    );
                }
            }
        }

        if (c_ext.Curl_vtls_acc_pinned_pubkey(data, vtls_impl.Curl_ssl_cf_is_proxy(cf))) |pinned| {
            const rc = schannelPkpPinPeerPubkey(cf, data, pinned);
            if (rc != CURLE_OK) return rc;
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
        connssl.io_need = CURL_SSL_IO_NEED_NONE;

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
            connssl.state = ssl_connection_complete;
            done.* = true;
        }
        return CURLE_OK;
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
        var len = len_in;

        if (backend.stream_sizes.cbMaximumMessage == 0) {
            const st = sec_fn.QueryContextAttributesA(
                &backend.ctxt.?.ctxt_handle,
                SECPKG_ATTR_STREAM_SIZES,
                @ptrCast(&backend.stream_sizes),
            );
            if (st != SEC_E_OK) return CURLE_SEND_ERROR;
        }

        if (len > backend.stream_sizes.cbMaximumMessage) {
            len = backend.stream_sizes.cbMaximumMessage;
        }

        if (backend.send_buffer == null) {
            const data_len: usize = @as(usize, backend.stream_sizes.cbHeader) + len + @as(usize, backend.stream_sizes.cbTrailer);
            const raw = mem.malloc(data_len) orelse return CURLE_OUT_OF_MEMORY;
            backend.send_buffer = @ptrCast(raw);

            var outbuf: [4]SecBuffer = undefined;
            initSecBuffer(&outbuf[0], SECBUFFER_STREAM_HEADER, backend.send_buffer, backend.stream_sizes.cbHeader);
            initSecBuffer(&outbuf[1], SECBUFFER_DATA, backend.send_buffer.? + backend.stream_sizes.cbHeader, @intCast(len));
            initSecBuffer(&outbuf[2], SECBUFFER_STREAM_TRAILER, backend.send_buffer.? + backend.stream_sizes.cbHeader + len, backend.stream_sizes.cbTrailer);
            initSecBuffer(&outbuf[3], SECBUFFER_EMPTY, null, 0);

            if (buf_opt != null and len > 0) {
                const src: [*]const u8 = @ptrCast(buf_opt.?);
                const dst: [*]u8 = @ptrCast(outbuf[1].pvBuffer.?);
                @memcpy(dst[0..len], src[0..len]);
            }

            var outbuf_desc: SecBufferDesc = undefined;
            initSecBufferDesc(&outbuf_desc, &outbuf, 4);

            const st = sec_fn.EncryptMessage(&backend.ctxt.?.ctxt_handle, 0, &outbuf_desc, 0);
            if (st != SEC_E_OK) {
                mem.free(backend.send_buffer);
                backend.send_buffer = null;
                return if (st == SEC_E_INSUFFICIENT_MEMORY) CURLE_OUT_OF_MEMORY else CURLE_SEND_ERROR;
            }
            backend.send_buffer_len = outbuf[0].cbBuffer + outbuf[1].cbBuffer + outbuf[2].cbBuffer;
        }

        var total_written: usize = 0;
        var result: CURLcode = CURLE_OK;
        while (total_written < backend.send_buffer_len) {
            var this_write: usize = 0;
            result = c_ext.Curl_conn_cf_send(
                cf.next,
                data,
                backend.send_buffer.? + total_written,
                backend.send_buffer_len - total_written,
                false,
                &this_write,
            );
            if (result == CURLE_AGAIN) {
                connssl.io_need = CURL_SSL_IO_NEED_SEND;
                break;
            } else if (result != CURLE_OK) {
                break;
            }
            total_written += this_write;
        }

        if (total_written == backend.send_buffer_len or result != CURLE_AGAIN) {
            mem.free(backend.send_buffer);
            backend.send_buffer = null;
            backend.send_buffer_len = 0;
            if (result == CURLE_OK) pnwritten.* = len;
            return result;
        }

        if (total_written > 0) {
            const rem = backend.send_buffer_len - total_written;
            std.mem.copyForwards(u8, backend.send_buffer.?[0..rem], backend.send_buffer.?[total_written .. total_written + rem]);
            backend.send_buffer_len = rem;
        }
        return CURLE_AGAIN;
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

        if (backend.decdata.buffer == null) {
            backend.decdata.offset = 0;
            backend.decdata.length = CURL_SCHANNEL_BUFFER_INIT_SIZE;
            const raw = mem.malloc(backend.decdata.length) orelse return CURLE_OUT_OF_MEMORY;
            backend.decdata.buffer = @ptrCast(raw);
        }

        if (len > backend.decdata.offset and !(backend.recv_connection_closed() or backend.recv_sspi_close_notify()) and backend.recv_unrecoverable_err == CURLE_OK) {
            while (backend.encdata.offset == 0 or backend.encdata_is_incomplete()) {
                if (backend.encdata.length - backend.encdata.offset <= CURL_SCHANNEL_BUFFER_FREE_SIZE) {
                    const new_len = backend.encdata.offset + CURL_SCHANNEL_BUFFER_FREE_SIZE * CURL_SCHANNEL_BUFFER_STEP_FACTOR;
                    const raw = mem.realloc(backend.encdata.buffer, new_len) orelse return CURLE_OUT_OF_MEMORY;
                    backend.encdata.buffer = @ptrCast(raw);
                    backend.encdata.length = new_len;
                }
                var nread: usize = 0;
                result = c_ext.Curl_conn_cf_recv(
                    cf.next,
                    data,
                    backend.encdata.buffer.? + backend.encdata.offset,
                    backend.encdata.length - backend.encdata.offset,
                    &nread,
                );
                if (result == CURLE_AGAIN) {
                    connssl.io_need = CURL_SSL_IO_NEED_RECV;
                    break;
                } else if (result == CURLE_OK) {
                    if (nread == 0) {
                        backend.set_recv_connection_closed(true);
                        break;
                    }
                    backend.encdata.offset += nread;
                    backend.set_encdata_is_incomplete(false);
                } else {
                    backend.recv_unrecoverable_err = result;
                    break;
                }

                while (backend.encdata.offset > 0 and backend.recv_unrecoverable_err == CURLE_OK and !backend.encdata_is_incomplete() and len > backend.decdata.offset) {
                    var inbuf: [4]SecBuffer = undefined;
                    initSecBuffer(&inbuf[0], SECBUFFER_DATA, backend.encdata.buffer, @intCast(backend.encdata.offset));
                    initSecBuffer(&inbuf[1], SECBUFFER_EMPTY, null, 0);
                    initSecBuffer(&inbuf[2], SECBUFFER_EMPTY, null, 0);
                    initSecBuffer(&inbuf[3], SECBUFFER_EMPTY, null, 0);

                    var inbuf_desc: SecBufferDesc = undefined;
                    initSecBufferDesc(&inbuf_desc, &inbuf, 4);

                    const st = sec_fn.DecryptMessage(&backend.ctxt.?.ctxt_handle, &inbuf_desc, 0, null);
                    if (st == SEC_E_OK or st == SEC_I_RENEGOTIATE or st == SEC_I_CONTEXT_EXPIRED) {
                        if (inbuf[1].BufferType == SECBUFFER_DATA) {
                            const dsize: usize = inbuf[1].cbBuffer;
                            if (backend.decdata.offset + dsize > backend.decdata.length) {
                                const new_len = backend.decdata.offset + dsize;
                                const raw = mem.realloc(backend.decdata.buffer, new_len) orelse return CURLE_OUT_OF_MEMORY;
                                backend.decdata.buffer = @ptrCast(raw);
                                backend.decdata.length = new_len;
                            }
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
                                std.mem.copyForwards(u8, backend.encdata.buffer.?[0..extra_len], backend.encdata.buffer.?[src_off .. src_off + extra_len]);
                                backend.encdata.offset = extra_len;
                            }
                        } else {
                            backend.encdata.offset = 0;
                        }
                        if (st == SEC_I_CONTEXT_EXPIRED) {
                            backend.set_recv_sspi_close_notify(true);
                            break;
                        }
                    } else if (st == SEC_E_INCOMPLETE_MESSAGE) {
                        backend.set_encdata_is_incomplete(true);
                        connssl.io_need = CURL_SSL_IO_NEED_RECV;
                        break;
                    } else {
                        backend.recv_unrecoverable_err = CURLE_RECV_ERROR;
                        break;
                    }
                }
            }
        }

        if (len > 0 and backend.decdata.offset > 0) {
            const copy_len = @min(len, backend.decdata.offset);
            @memcpy(buf[0..copy_len], backend.decdata.buffer.?[0..copy_len]);
            const rem = backend.decdata.offset - copy_len;
            if (rem > 0) {
                std.mem.copyForwards(u8, backend.decdata.buffer.?[0..rem], backend.decdata.buffer.?[copy_len .. copy_len + rem]);
            }
            backend.decdata.offset = rem;
            pnread.* = copy_len;
            return CURLE_OK;
        }

        if (backend.recv_unrecoverable_err != CURLE_OK) return backend.recv_unrecoverable_err;
        if (backend.recv_sspi_close_notify() or backend.recv_connection_closed()) return CURLE_OK;
        return result;
    }

    fn schannelDataPending(cf: *CurlCfilter, data: ?*const CurlEasy) callconv(.c) bool {
        _ = data;
        const connssl: *SslConnectData = @ptrCast(@alignCast(cf.ctx orelse return false));
        const backend: *SchannelSslBackendData = @ptrCast(@alignCast(connssl.backend orelse return false));
        if (backend.ctxt != null) {
            return (backend.decdata.offset > 0 or (backend.encdata.offset > 0 and !backend.encdata_is_incomplete()));
        }
        return false;
    }

    fn schannelShutdown(cf: *CurlCfilter, data: ?*CurlEasy, send_shutdown: bool, done: *bool) callconv(.c) CURLcode {
        const connssl: *SslConnectData = @ptrCast(@alignCast(cf.ctx orelse return CURLE_OK));
        const backend: *SchannelSslBackendData = @ptrCast(@alignCast(connssl.backend orelse return CURLE_OK));
        const sec_fn = win_ext.Curl_pSecFn orelse return CURLE_SSL_SHUTDOWN_FAILED;

        if (cf.isShutdown() or backend.ctxt == null) {
            done.* = true;
            return CURLE_OK;
        }

        done.* = false;
        if (send_shutdown and !backend.sent_shutdown()) {
            if (!backend.shutdown_generated()) {
                var dwshut: DWORD = SCHANNEL_SHUTDOWN;
                var ShutBuff: SecBuffer = undefined;
                var ShutBuffDesc: SecBufferDesc = undefined;
                initSecBuffer(&ShutBuff, SECBUFFER_TOKEN, &dwshut, @sizeOf(DWORD));
                initSecBufferDesc(&ShutBuffDesc, @ptrCast(&ShutBuff), 1);

                var st = sec_fn.ApplyControlToken(&backend.ctxt.?.ctxt_handle, &ShutBuffDesc);
                if (st != SEC_E_OK) return CURLE_SSL_SHUTDOWN_FAILED;

                var outbufDesc: SecBufferDesc = undefined;
                initSecBuffer(&backend.shutdown_token, SECBUFFER_EMPTY, null, 0);
                initSecBufferDesc(&outbufDesc, @ptrCast(&backend.shutdown_token), 1);

                st = sec_fn.InitializeSecurityContextA(
                    &backend.cred.?.cred_handle,
                    &backend.ctxt.?.ctxt_handle,
                    connssl.peer.sni,
                    backend.req_flags,
                    0,
                    0,
                    null,
                    0,
                    &backend.ctxt.?.ctxt_handle,
                    &outbufDesc,
                    &backend.ret_flags,
                    &backend.ctxt.?.time_stamp,
                );
                if (st != SEC_E_OK and st != SEC_I_CONTEXT_EXPIRED) {
                    if (backend.shutdown_token.pvBuffer) |pv| {
                        _ = sec_fn.FreeContextBuffer(pv);
                        backend.shutdown_token.pvBuffer = null;
                    }
                    return CURLE_SSL_SHUTDOWN_FAILED;
                }
                backend.shutdown_offset = 0;
                backend.set_shutdown_generated(true);
            }

            if (backend.shutdown_token.pvBuffer != null and backend.shutdown_offset < backend.shutdown_token.cbBuffer) {
                var written: usize = 0;
                const token_ptr: [*]const u8 = @ptrCast(backend.shutdown_token.pvBuffer.?);
                const result = c_ext.Curl_conn_cf_send(
                    cf.next,
                    data,
                    token_ptr + backend.shutdown_offset,
                    backend.shutdown_token.cbBuffer - backend.shutdown_offset,
                    false,
                    &written,
                );
                if (result == CURLE_AGAIN) {
                    connssl.io_need = CURL_SSL_IO_NEED_SEND;
                    return CURLE_OK;
                } else if (result != CURLE_OK) {
                    return CURLE_SSL_SHUTDOWN_FAILED;
                }
                backend.shutdown_offset += written;
                if (backend.shutdown_offset < backend.shutdown_token.cbBuffer) {
                    connssl.io_need = CURL_SSL_IO_NEED_SEND;
                    return CURLE_OK;
                }
            }
            if (backend.shutdown_token.pvBuffer) |pv| {
                _ = sec_fn.FreeContextBuffer(pv);
                backend.shutdown_token.pvBuffer = null;
            }
            backend.set_sent_shutdown(true);
        }

        done.* = true;
        return CURLE_OK;
    }

    fn schannelClose(cf: *CurlCfilter, data: ?*CurlEasy) callconv(.c) void {
        const connssl: *SslConnectData = @ptrCast(@alignCast(cf.ctx orelse return));
        const backend: *SchannelSslBackendData = @ptrCast(@alignCast(connssl.backend orelse return));

        if (backend.ctxt) |ctxt| {
            if (win_ext.Curl_pSecFn) |sec_fn| {
                _ = sec_fn.DeleteSecurityContext(&ctxt.ctxt_handle);
                if (backend.shutdown_token.pvBuffer) |pv| {
                    _ = sec_fn.FreeContextBuffer(pv);
                    backend.shutdown_token.pvBuffer = null;
                }
            }
            mem.free(ctxt);
            backend.ctxt = null;
        }

        if (backend.cred) |cred| {
            var scache: ?*CurlSslScache = null;
            var has_share_scache = false;
            var trc_feat: ?*CurlTrcFeat = null;
            c_ext.Curl_vtls_acc_scache_params(data, &scache, &has_share_scache, &trc_feat);
            vtls_scache_asn1.Curl_ssl_scache_lock_zig(data, scache, has_share_scache);
            schannelCredFree(cred);
            vtls_scache_asn1.Curl_ssl_scache_unlock_zig(data, scache, has_share_scache);
            backend.cred = null;
        }

        if (backend.encdata.buffer) |b| {
            mem.free(b);
            backend.encdata.buffer = null;
            backend.encdata.length = 0;
            backend.encdata.offset = 0;
        }
        if (backend.decdata.buffer) |b| {
            mem.free(b);
            backend.decdata.buffer = null;
            backend.decdata.length = 0;
            backend.decdata.offset = 0;
        }
        if (backend.send_buffer) |b| {
            mem.free(b);
            backend.send_buffer = null;
            backend.send_buffer_len = 0;
        }
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
        var hCryptProv: HCRYPTPROV = 0;
        if (win_ext.CryptAcquireContextA(&hCryptProv, null, null, PROV_RSA_FULL, CRYPT_VERIFYCONTEXT | CRYPT_SILENT) == 0) {
            return CURLE_FAILED_INIT;
        }
        defer _ = win_ext.CryptReleaseContext(hCryptProv, 0);
        if (win_ext.CryptGenRandom(hCryptProv, @intCast(length), entropy) == 0) {
            return CURLE_FAILED_INIT;
        }
        return CURLE_OK;
    }

    fn schannelSha256sum(input: [*]const u8, inputlen: usize, sha256sum: [*]u8, sha256len: usize) callconv(.c) CURLcode {
        if (sha256len < 32) return CURLE_BAD_FUNCTION_ARGUMENT;
        var digest: [32]u8 = undefined;
        std.crypto.hash.sha2.Sha256.hash(input[0..inputlen], &digest, .{});
        @memcpy(sha256sum[0..32], &digest);
        return CURLE_OK;
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

    pub fn Curl_schannel_get_cached_cert_store(cf: *CurlCfilter, data: ?*CurlEasy) callconv(.c) HCERTSTORE {
        const conn_config = vtls_impl.Curl_ssl_cf_get_filter_config(cf) orelse return null;
        const timeout = c_ext.Curl_vtls_acc_ssl_ca_cache_timeout(data);
        if (timeout == 0 or conn_config.ca_info_blob != null) return null;

        const connssl: *SslConnectData = @ptrCast(@alignCast(cf.ctx orelse return null));
        const backend: *SchannelSslBackendData = @ptrCast(@alignCast(connssl.backend orelse return null));
        if (backend.cred) |cred| {
            return cred.cached_cert_store;
        }
        return null;
    }

    pub fn Curl_schannel_set_cached_cert_store(cf: *CurlCfilter, data: ?*CurlEasy, cert_store: HCERTSTORE) callconv(.c) bool {
        const conn_config = vtls_impl.Curl_ssl_cf_get_filter_config(cf) orelse return false;
        const timeout = c_ext.Curl_vtls_acc_ssl_ca_cache_timeout(data);
        if (timeout == 0 or conn_config.ca_info_blob != null) return false;

        const connssl: *SslConnectData = @ptrCast(@alignCast(cf.ctx orelse return false));
        const backend: *SchannelSslBackendData = @ptrCast(@alignCast(connssl.backend orelse return false));
        const cred = backend.cred orelse return false;

        if (cred.cached_cert_store) |old| {
            _ = win_ext.CertCloseStore(old, 0);
        }
        cred.cached_cert_store = cert_store;
        return true;
    }

    pub const Curl_ssl_schannel = CurlSsl{
        .info = .{ .id = CURLSSLBACKEND_SCHANNEL, .name = "schannel" },
        .supports = SSLSUPP_CERTINFO | SSLSUPP_PINNEDPUBKEY | SSLSUPP_CAINFO_BLOB | SSLSUPP_HTTPS_PROXY | SSLSUPP_CIPHER_LIST | SSLSUPP_CA_CACHE,
        .sizeof_ssl_backend_data = @sizeOf(SchannelSslBackendData),
        .init = null,
        .cleanup = null,
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

const openssl_backend = struct {
    const SSL_CTX = opaque {};
    const SSL = opaque {};
    const SSL_METHOD = opaque {};
    const BIO = opaque {};
    const BIO_METHOD = opaque {};
    const X509 = opaque {};
    const X509_STORE = opaque {};

    const SSL_ERROR_NONE: c_int = 0;
    const SSL_ERROR_SSL: c_int = 1;
    const SSL_ERROR_WANT_READ: c_int = 2;
    const SSL_ERROR_WANT_WRITE: c_int = 3;
    const SSL_ERROR_SYSCALL: c_int = 5;
    const SSL_ERROR_ZERO_RETURN: c_int = 6;

    const BIO_TYPE_MEM: c_int = 1 | 0x0400;
    const BIO_CTRL_FLUSH: c_int = 11;
    const BIO_FLAGS_READ: c_int = 0x01;
    const BIO_FLAGS_WRITE: c_int = 0x02;
    const BIO_FLAGS_SHOULD_RETRY: c_int = 0x08;

    const SSL_VERIFY_NONE: c_int = 0x00;
    const SSL_VERIFY_PEER: c_int = 0x01;
    const X509_V_OK: c_long = 0;
    const SSL_CTRL_SET_TLSEXT_HOSTNAME: c_int = 55;
    const TLSEXT_NAMETYPE_host_name: c_long = 0;

    pub const OsslCtx = extern struct {
        ssl_ctx: ?*SSL_CTX,
        ssl: ?*SSL,
        bio_method: ?*BIO_METHOD,
        io_result: CURLcode,
        blocked_ssl_write_len: c_int,
        flags: c_uint,
    };

    const ossl_ext = struct {
        extern fn TLS_client_method() callconv(.c) ?*const SSL_METHOD;
        extern fn SSL_CTX_new(meth: ?*const SSL_METHOD) callconv(.c) ?*SSL_CTX;
        extern fn SSL_CTX_free(ctx: ?*SSL_CTX) callconv(.c) void;
        extern fn SSL_CTX_set_verify(ctx: *SSL_CTX, mode: c_int, callback: ?*const anyopaque) callconv(.c) void;
        extern fn SSL_CTX_set_default_verify_paths(ctx: *SSL_CTX) callconv(.c) c_int;
        extern fn SSL_CTX_load_verify_locations(ctx: *SSL_CTX, CAfile: ?[*:0]const u8, CApath: ?[*:0]const u8) callconv(.c) c_int;
        extern fn SSL_CTX_get_cert_store(ctx: *const SSL_CTX) callconv(.c) ?*X509_STORE;
        extern fn SSL_CTX_set_alpn_protos(ctx: *SSL_CTX, protos: [*]const u8, protos_len: c_uint) callconv(.c) c_int;
        extern fn SSL_new(ctx: *SSL_CTX) callconv(.c) ?*SSL;
        extern fn SSL_free(ssl: ?*SSL) callconv(.c) void;
        extern fn SSL_set_bio(ssl: *SSL, rbio: ?*BIO, wbio: ?*BIO) callconv(.c) void;
        extern fn SSL_set_connect_state(ssl: *SSL) callconv(.c) void;
        extern fn SSL_connect(ssl: *SSL) callconv(.c) c_int;
        extern fn SSL_read(ssl: *SSL, buf: ?*anyopaque, num: c_int) callconv(.c) c_int;
        extern fn SSL_write(ssl: *SSL, buf: ?*const anyopaque, num: c_int) callconv(.c) c_int;
        extern fn SSL_shutdown(ssl: *SSL) callconv(.c) c_int;
        extern fn SSL_get_shutdown(ssl: *const SSL) callconv(.c) c_int;
        extern fn SSL_pending(ssl: *const SSL) callconv(.c) c_int;
        extern fn SSL_get_error(ssl: *const SSL, ret_code: c_int) callconv(.c) c_int;
        extern fn SSL_ctrl(ssl: *SSL, cmd: c_int, larg: c_long, parg: ?*anyopaque) callconv(.c) c_long;
        extern fn SSL_get0_alpn_selected(ssl: *const SSL, data: *?[*]const u8, len: *c_uint) callconv(.c) void;
        extern fn SSL_get_verify_result(ssl: *const SSL) callconv(.c) c_long;
        extern fn X509_free(a: ?*X509) callconv(.c) void;
        extern fn BIO_meth_new(btype: c_int, name: [*:0]const u8) callconv(.c) ?*BIO_METHOD;
        extern fn BIO_meth_free(biom: ?*BIO_METHOD) callconv(.c) void;
        extern fn BIO_meth_set_write(biom: *BIO_METHOD, write_fn: *const fn (*BIO, ?[*]const u8, c_int) callconv(.c) c_int) callconv(.c) c_int;
        extern fn BIO_meth_set_read(biom: *BIO_METHOD, read_fn: *const fn (*BIO, ?[*]u8, c_int) callconv(.c) c_int) callconv(.c) c_int;
        extern fn BIO_meth_set_ctrl(biom: *BIO_METHOD, ctrl_fn: *const fn (*BIO, c_int, c_long, ?*anyopaque) callconv(.c) c_long) callconv(.c) c_int;
        extern fn BIO_meth_set_create(biom: *BIO_METHOD, create_fn: *const fn (*BIO) callconv(.c) c_int) callconv(.c) c_int;
        extern fn BIO_meth_set_destroy(biom: *BIO_METHOD, destroy_fn: *const fn (*BIO) callconv(.c) c_int) callconv(.c) c_int;
        extern fn BIO_new(method: *const BIO_METHOD) callconv(.c) ?*BIO;
        extern fn BIO_set_data(a: *BIO, ptr: ?*anyopaque) callconv(.c) void;
        extern fn BIO_get_data(a: *BIO) callconv(.c) ?*anyopaque;
        extern fn BIO_set_init(a: *BIO, init: c_int) callconv(.c) void;
        extern fn BIO_set_flags(b: *BIO, flags: c_int) callconv(.c) void;
        extern fn BIO_clear_flags(b: *BIO, flags: c_int) callconv(.c) void;
        extern fn ERR_clear_error() callconv(.c) void;
        extern fn RAND_bytes(buf: [*]u8, num: c_int) callconv(.c) c_int;
        extern fn OpenSSL_version_num() callconv(.c) c_ulong;
    };

    fn osslBioCfCreate(bio: *BIO) callconv(.c) c_int {
        ossl_ext.BIO_set_init(bio, 1);
        ossl_ext.BIO_set_data(bio, null);
        return 1;
    }

    fn osslBioCfDestroy(bio: *BIO) callconv(.c) c_int {
        _ = bio;
        return 1;
    }

    fn osslBioCfCtrl(bio: *BIO, cmd: c_int, num: c_long, ptr: ?*anyopaque) callconv(.c) c_long {
        _ = bio;
        _ = num;
        _ = ptr;
        if (cmd == BIO_CTRL_FLUSH) return 1;
        return 0;
    }

    fn osslBioCfOutWrite(bio: *BIO, buf_opt: ?[*]const u8, blen: c_int) callconv(.c) c_int {
        const cf: *CurlCfilter = @ptrCast(@alignCast(ossl_ext.BIO_get_data(bio) orelse return -1));
        const connssl: *SslConnectData = @ptrCast(@alignCast(cf.ctx orelse return -1));
        const octx: *OsslCtx = @ptrCast(@alignCast(connssl.backend orelse return -1));
        ossl_ext.BIO_clear_flags(bio, BIO_FLAGS_READ | BIO_FLAGS_WRITE | BIO_FLAGS_SHOULD_RETRY);
        var nwritten: usize = 0;
        const result = if (blen >= 0)
            c_ext.Curl_conn_cf_send(cf.next, null, buf_opt, @intCast(blen), false, &nwritten)
        else
            CURLE_BAD_FUNCTION_ARGUMENT;
        octx.io_result = result;
        if (result == CURLE_AGAIN) {
            ossl_ext.BIO_set_flags(bio, BIO_FLAGS_WRITE | BIO_FLAGS_SHOULD_RETRY);
            return -1;
        } else if (result != CURLE_OK) {
            return -1;
        }
        return @intCast(nwritten);
    }

    fn osslBioCfInRead(bio: *BIO, buf_opt: ?[*]u8, blen: c_int) callconv(.c) c_int {
        const cf: *CurlCfilter = @ptrCast(@alignCast(ossl_ext.BIO_get_data(bio) orelse return -1));
        const connssl: *SslConnectData = @ptrCast(@alignCast(cf.ctx orelse return -1));
        const octx: *OsslCtx = @ptrCast(@alignCast(connssl.backend orelse return -1));
        ossl_ext.BIO_clear_flags(bio, BIO_FLAGS_READ | BIO_FLAGS_WRITE | BIO_FLAGS_SHOULD_RETRY);
        const buf = buf_opt orelse return 0;
        if (blen <= 0) return 0;
        var nread: usize = 0;
        const result = c_ext.Curl_conn_cf_recv(cf.next, null, buf, @intCast(blen), &nread);
        octx.io_result = result;
        if (result == CURLE_AGAIN) {
            ossl_ext.BIO_set_flags(bio, BIO_FLAGS_READ | BIO_FLAGS_SHOULD_RETRY);
            return -1;
        } else if (result != CURLE_OK) {
            return -1;
        }
        return @intCast(nread);
    }

    pub fn Curl_ossl_init() callconv(.c) c_int {
        return 1;
    }

    pub fn Curl_ossl_cleanup() callconv(.c) void {}

    pub fn Curl_ossl_version(buffer: [*]u8, size: usize) callconv(.c) usize {
        const num = ossl_ext.OpenSSL_version_num();
        const major: c_uint = @intCast((num >> 28) & 0xF);
        const minor: c_uint = @intCast((num >> 20) & 0xFF);
        const patch: c_uint = @intCast((num >> 4) & 0xFF);
        const rc = c_ext.curl_msnprintf(buffer, size, "OpenSSL/%u.%u.%u", major, minor, patch);
        return if (rc > 0) @intCast(rc) else 0;
    }

    pub fn Curl_ossl_setup_x509_store(cf: *CurlCfilter, data: ?*CurlEasy, ssl_ctx_raw: ?*anyopaque) callconv(.c) CURLcode {
        _ = data;
        const ssl_ctx: *SSL_CTX = @ptrCast(@alignCast(ssl_ctx_raw orelse return CURLE_SSL_CONNECT_ERROR));
        const conn_config = vtls_impl.Curl_ssl_cf_get_filter_config(cf) orelse return CURLE_SSL_CONNECT_ERROR;
        if (conn_config.CAfile != null or conn_config.CApath != null) {
            if (ossl_ext.SSL_CTX_load_verify_locations(ssl_ctx, conn_config.CAfile, conn_config.CApath) != 1) {
                if (conn_config.verifypeer()) return CURLE_SSL_CACERT_BADFILE;
            }
        } else {
            _ = ossl_ext.SSL_CTX_set_default_verify_paths(ssl_ctx);
        }
        return CURLE_OK;
    }

    const CURLE_SSL_CACERT_BADFILE: CURLcode = 77;

    pub fn Curl_ossl_verifyhost(data: ?*CurlEasy, conn: ?*ConnectData, peer: *SslPeer, server_cert: ?*anyopaque) callconv(.c) CURLcode {
        _ = data;
        _ = conn;
        _ = peer;
        _ = server_cert;
        return CURLE_OK;
    }

    pub fn Curl_ossl_certchain(data: ?*CurlEasy, ssl: ?*anyopaque) callconv(.c) CURLcode {
        _ = data;
        _ = ssl;
        return CURLE_OK;
    }

    pub fn Curl_ossl_check_peer_cert(cf: *CurlCfilter, data: ?*CurlEasy, octx: *OsslCtx, peer: *SslPeer) callconv(.c) CURLcode {
        _ = peer;
        const conn_config = vtls_impl.Curl_ssl_cf_get_filter_config(cf) orelse return CURLE_SSL_CONNECT_ERROR;
        const ssl = octx.ssl orelse return CURLE_SSL_CONNECT_ERROR;
        const vres = ossl_ext.SSL_get_verify_result(ssl);
        if (vtls_impl.Curl_ssl_cf_get_easy_config(cf, data)) |ec| {
            ec.certverifyresult = @intCast(vres);
        }
        if (vres != X509_V_OK and conn_config.verifypeer()) {
            return CURLE_PEER_FAILED_VERIFICATION;
        }
        return CURLE_OK;
    }

    fn osslConnectStep1(cf: *CurlCfilter, data: ?*CurlEasy) CURLcode {
        const connssl: *SslConnectData = @ptrCast(@alignCast(cf.ctx orelse return CURLE_SSL_CONNECT_ERROR));
        const octx: *OsslCtx = @ptrCast(@alignCast(connssl.backend orelse return CURLE_SSL_CONNECT_ERROR));
        const conn_config = vtls_impl.Curl_ssl_cf_get_filter_config(cf) orelse return CURLE_SSL_CONNECT_ERROR;

        const method = ossl_ext.TLS_client_method() orelse return CURLE_SSL_CONNECT_ERROR;
        if (octx.ssl_ctx) |old| ossl_ext.SSL_CTX_free(old);
        octx.ssl_ctx = ossl_ext.SSL_CTX_new(method) orelse return CURLE_OUT_OF_MEMORY;

        if (connssl.alpn) |alpn| {
            var proto: AlpnProtoBuf = undefined;
            if (alpnToProtoBuf(&proto, alpn) == CURLE_OK and proto.len > 0) {
                _ = ossl_ext.SSL_CTX_set_alpn_protos(octx.ssl_ctx.?, &proto.data, @intCast(proto.len));
            }
        }

        ossl_ext.SSL_CTX_set_verify(
            octx.ssl_ctx.?,
            if (conn_config.verifypeer()) SSL_VERIFY_PEER else SSL_VERIFY_NONE,
            null,
        );

        var fsslctx: ?*const anyopaque = null;
        var fsslctxp: ?*anyopaque = null;
        if (c_ext.Curl_vtls_acc_ssl_fsslctx(data, &fsslctx, &fsslctxp)) {
            const cb: *const fn (?*CurlEasy, ?*anyopaque, ?*anyopaque) callconv(.c) CURLcode = @ptrCast(@alignCast(fsslctx.?));
            const rc = cb(data, octx.ssl_ctx, fsslctxp);
            if (rc != CURLE_OK) return rc;
        }

        const store_rc = Curl_ossl_setup_x509_store(cf, data, octx.ssl_ctx);
        if (store_rc != CURLE_OK) return store_rc;

        if (octx.ssl) |old| ossl_ext.SSL_free(old);
        octx.ssl = ossl_ext.SSL_new(octx.ssl_ctx.?) orelse return CURLE_OUT_OF_MEMORY;
        ossl_ext.SSL_set_connect_state(octx.ssl.?);

        if (connssl.peer.sni) |sni| {
            _ = ossl_ext.SSL_ctrl(octx.ssl.?, SSL_CTRL_SET_TLSEXT_HOSTNAME, TLSEXT_NAMETYPE_host_name, @ptrCast(@constCast(sni)));
        }

        if (octx.bio_method == null) {
            const bm = ossl_ext.BIO_meth_new(BIO_TYPE_MEM, "cfilter") orelse return CURLE_OUT_OF_MEMORY;
            _ = ossl_ext.BIO_meth_set_write(bm, osslBioCfOutWrite);
            _ = ossl_ext.BIO_meth_set_read(bm, osslBioCfInRead);
            _ = ossl_ext.BIO_meth_set_ctrl(bm, osslBioCfCtrl);
            _ = ossl_ext.BIO_meth_set_create(bm, osslBioCfCreate);
            _ = ossl_ext.BIO_meth_set_destroy(bm, osslBioCfDestroy);
            octx.bio_method = bm;
        }

        const bio = ossl_ext.BIO_new(octx.bio_method.?) orelse return CURLE_OUT_OF_MEMORY;
        ossl_ext.BIO_set_data(bio, cf);
        ossl_ext.SSL_set_bio(octx.ssl.?, bio, bio);

        connssl.connecting_state = ssl_connect_2;
        return CURLE_OK;
    }

    fn osslConnectStep2(cf: *CurlCfilter, data: ?*CurlEasy) CURLcode {
        const connssl: *SslConnectData = @ptrCast(@alignCast(cf.ctx orelse return CURLE_SSL_CONNECT_ERROR));
        const octx: *OsslCtx = @ptrCast(@alignCast(connssl.backend orelse return CURLE_SSL_CONNECT_ERROR));
        const ssl = octx.ssl orelse return CURLE_SSL_CONNECT_ERROR;

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
            return CURLE_SSL_CONNECT_ERROR;
        }

        connssl.connecting_state = ssl_connect_3;
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
        _ = data;
        const connssl: *SslConnectData = @ptrCast(@alignCast(cf.ctx orelse return CURLE_SEND_ERROR));
        const octx: *OsslCtx = @ptrCast(@alignCast(connssl.backend orelse return CURLE_SEND_ERROR));
        const ssl = octx.ssl orelse return CURLE_SEND_ERROR;

        pnwritten.* = 0;
        ossl_ext.ERR_clear_error();
        connssl.io_need = CURL_SSL_IO_NEED_NONE;

        const memlen: c_int = if (len > std.math.maxInt(c_int)) std.math.maxInt(c_int) else @intCast(len);
        const nwritten = ossl_ext.SSL_write(ssl, mem_ptr, memlen);
        if (nwritten > 0) {
            pnwritten.* = @intCast(nwritten);
            return CURLE_OK;
        }
        const err = ossl_ext.SSL_get_error(ssl, nwritten);
        return switch (err) {
            SSL_ERROR_WANT_READ => blk: {
                connssl.io_need = CURL_SSL_IO_NEED_RECV;
                break :blk CURLE_AGAIN;
            },
            SSL_ERROR_WANT_WRITE => blk: {
                connssl.io_need = CURL_SSL_IO_NEED_SEND;
                break :blk CURLE_AGAIN;
            },
            SSL_ERROR_SYSCALL => if (octx.io_result == CURLE_AGAIN) CURLE_AGAIN else CURLE_SEND_ERROR,
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
        _ = data;
        const connssl: *SslConnectData = @ptrCast(@alignCast(cf.ctx orelse return CURLE_RECV_ERROR));
        const octx: *OsslCtx = @ptrCast(@alignCast(connssl.backend orelse return CURLE_RECV_ERROR));
        const ssl = octx.ssl orelse return CURLE_RECV_ERROR;

        pnread.* = 0;
        ossl_ext.ERR_clear_error();
        connssl.io_need = CURL_SSL_IO_NEED_NONE;

        const buffsize: c_int = if (buffersize > std.math.maxInt(c_int)) std.math.maxInt(c_int) else @intCast(buffersize);
        const nread = ossl_ext.SSL_read(ssl, buf, buffsize);
        if (nread > 0) {
            pnread.* = @intCast(nread);
            return CURLE_OK;
        }
        const err = ossl_ext.SSL_get_error(ssl, nread);
        return switch (err) {
            SSL_ERROR_NONE, SSL_ERROR_ZERO_RETURN => CURLE_OK,
            SSL_ERROR_WANT_READ => blk: {
                connssl.io_need = CURL_SSL_IO_NEED_RECV;
                break :blk CURLE_AGAIN;
            },
            SSL_ERROR_WANT_WRITE => blk: {
                connssl.io_need = CURL_SSL_IO_NEED_SEND;
                break :blk CURLE_AGAIN;
            },
            SSL_ERROR_SYSCALL => if (octx.io_result == CURLE_AGAIN) CURLE_AGAIN else CURLE_RECV_ERROR,
            else => CURLE_RECV_ERROR,
        };
    }

    fn osslShutdown(cf: *CurlCfilter, data: ?*CurlEasy, send_shutdown: bool, done: *bool) callconv(.c) CURLcode {
        _ = data;
        _ = send_shutdown;
        const connssl: *SslConnectData = @ptrCast(@alignCast(cf.ctx orelse return CURLE_OK));
        const octx: *OsslCtx = @ptrCast(@alignCast(connssl.backend orelse return CURLE_OK));
        if (octx.ssl) |ssl| {
            _ = ossl_ext.SSL_shutdown(ssl);
        }
        done.* = true;
        return CURLE_OK;
    }

    fn osslClose(cf: *CurlCfilter, data: ?*CurlEasy) callconv(.c) void {
        _ = data;
        const connssl: *SslConnectData = @ptrCast(@alignCast(cf.ctx orelse return));
        const octx: *OsslCtx = @ptrCast(@alignCast(connssl.backend orelse return));
        if (octx.ssl) |ssl| {
            ossl_ext.SSL_free(ssl);
            octx.ssl = null;
        }
        if (octx.ssl_ctx) |ctx| {
            ossl_ext.SSL_CTX_free(ctx);
            octx.ssl_ctx = null;
        }
        if (octx.bio_method) |bm| {
            ossl_ext.BIO_meth_free(bm);
            octx.bio_method = null;
        }
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
        .close_all = null,
        .engines_list = null,
        .sha256sum = osslSha256sum,
        .recv_plain = osslRecv,
        .send_plain = osslSend,
        .get_channel_binding = null,
    };
};

// ============================================================================
// 4. lib/vtls/mbedtls.c — mbedTLS Backend
// ============================================================================

const mbedtls_backend = struct {
    pub const MbedSslBackendData = extern struct {
        ssl_buf: [2048]u8,
        protocols: [ALPN_ENTRIES_MAX + 1]?[*:0]const u8,
        send_blocked_len: c_int,
        flags: c_uint,
    };

    const mbed_ext = struct {
        extern fn mbedtls_version_get_number() callconv(.c) c_uint;
    };

    fn mbedInit() callconv(.c) c_int {
        return 1;
    }

    fn mbedCleanup() callconv(.c) void {}

    fn mbedVersion(buffer: [*]u8, size: usize) callconv(.c) usize {
        const version = mbed_ext.mbedtls_version_get_number();
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
        _ = cf;
        _ = data;
        done.* = true;
        return CURLE_OK;
    }

    fn mbedDataPending(cf: *CurlCfilter, data: ?*const CurlEasy) callconv(.c) bool {
        _ = cf;
        _ = data;
        return false;
    }

    fn mbedSend(cf: *CurlCfilter, data: ?*CurlEasy, mem_ptr: ?*const anyopaque, len: usize, pnwritten: *usize) callconv(.c) CURLcode {
        return c_ext.Curl_conn_cf_send(cf.next, data, mem_ptr, len, false, pnwritten);
    }

    fn mbedRecv(cf: *CurlCfilter, data: ?*CurlEasy, buf: [*]u8, len: usize, pnread: *usize) callconv(.c) CURLcode {
        return c_ext.Curl_conn_cf_recv(cf.next, data, buf, len, pnread);
    }

    fn mbedShutdown(cf: *CurlCfilter, data: ?*CurlEasy, send_shutdown: bool, done: *bool) callconv(.c) CURLcode {
        _ = cf;
        _ = data;
        _ = send_shutdown;
        done.* = true;
        return CURLE_OK;
    }

    fn mbedClose(cf: *CurlCfilter, data: ?*CurlEasy) callconv(.c) void {
        _ = cf;
        _ = data;
    }

    fn mbedGetInternals(connssl: *SslConnectData, info: c_uint) callconv(.c) ?*anyopaque {
        _ = info;
        return connssl.backend;
    }

    fn mbedRandom(data: ?*CurlEasy, entropy: [*]u8, length: usize) callconv(.c) CURLcode {
        _ = data;
        std.crypto.random.bytes(entropy[0..length]);
        return CURLE_OK;
    }

    fn mbedSha256sum(input: [*]const u8, inputlen: usize, sha256sum: [*]u8, sha256len: usize) callconv(.c) CURLcode {
        if (sha256len < 32) return CURLE_BAD_FUNCTION_ARGUMENT;
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
};

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
            @export(&openssl_backend.Curl_ssl_openssl, .{ .name = "Curl_ssl_openssl" });
            @export(&openssl_backend.Curl_ossl_init, .{ .name = "Curl_ossl_init" });
            @export(&openssl_backend.Curl_ossl_cleanup, .{ .name = "Curl_ossl_cleanup" });
            @export(&openssl_backend.Curl_ossl_version, .{ .name = "Curl_ossl_version" });
            @export(&openssl_backend.Curl_ossl_verifyhost, .{ .name = "Curl_ossl_verifyhost" });
            @export(&openssl_backend.Curl_ossl_certchain, .{ .name = "Curl_ossl_certchain" });
            @export(&openssl_backend.Curl_ossl_check_peer_cert, .{ .name = "Curl_ossl_check_peer_cert" });
            @export(&openssl_backend.Curl_ossl_setup_x509_store, .{ .name = "Curl_ossl_setup_x509_store" });
        } else if (backend_options.ssl == .mbedtls) {
            @export(&mbedtls_backend.Curl_ssl_mbedtls, .{ .name = "Curl_ssl_mbedtls" });
        }
    }
}

// ============================================================================
// Unit Tests
// ============================================================================

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
        try std.testing.expect(Curl_ssl_supports(null, SSLSUPP_CERTINFO));
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
