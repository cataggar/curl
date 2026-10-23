// ============================================================================
// Port of:
//   - lib/vquic/vquic.c
//   - lib/vquic/vquic.h
//   - lib/vquic/vquic_int.h
//   - lib/vquic/vquic-tls.c
//   - lib/vquic/vquic-tls.h
// ============================================================================

const std = @import("std");
const builtin = @import("builtin");
const backend_options = @import("backend_options");
const mem = @import("mem.zig");
const primitives = @import("primitives.zig");
const containers = @import("containers.zig");
const io_buffers = @import("io_buffers.zig");
const curlx_time_net = @import("curlx_time_net.zig");
const os_leaf = @import("os_leaf.zig");
const headers_sock = @import("headers_sock.zig");
const netrc_addr_idn = @import("netrc_addr_idn.zig");
const cfilters_progress = @import("cfilters_progress.zig");
const cfsocket_transfer = @import("cfsocket_transfer.zig");
const altsvc_hsts_peer = @import("altsvc_hsts_peer.zig");
const protocol_version_mime = @import("protocol_version_mime.zig");
const vtls_core = @import("vtls_core.zig");
const vtls_scache_asn1 = @import("vtls_scache_asn1.zig");
const vtls_backends = @import("vtls_backends.zig");
const vtls_gtls = @import("vtls_gtls.zig");
const vtls_wolfssl = @import("vtls_wolfssl.zig");
const http1_options = @import("http1_options.zig");
const vquic_ngtcp2 = @import("vquic_ngtcp2.zig");
const vquic_quiche = @import("vquic_quiche.zig");
const ossl_backend = vtls_backends.openssl_backend;

const is_windows = builtin.os.tag == .windows;
const is_linux = builtin.os.tag == .linux;
const has_sendmsg = !is_windows;

pub const use_http3 = if (@hasDecl(backend_options, "http3")) backend_options.http3 else false;
pub const use_proxy_http3 = if (@hasDecl(backend_options, "proxy_http3")) backend_options.proxy_http3 else false;

pub const CURLcode = c_uint;
pub const CURLE_OK: CURLcode = 0;
pub const CURLE_UNSUPPORTED_PROTOCOL: CURLcode = 1;
pub const CURLE_FAILED_INIT: CURLcode = 2;
pub const CURLE_URL_MALFORMAT: CURLcode = 3;
pub const CURLE_NOT_BUILT_IN: CURLcode = 4;
pub const CURLE_COULDNT_CONNECT: CURLcode = 7;
pub const CURLE_OUT_OF_MEMORY: CURLcode = 27;
pub const CURLE_BAD_FUNCTION_ARGUMENT: CURLcode = 43;
pub const CURLE_SEND_ERROR: CURLcode = 55;
pub const CURLE_RECV_ERROR: CURLcode = 56;
pub const CURLE_SSL_CERTPROBLEM: CURLcode = 58;
pub const CURLE_SSL_CIPHER: CURLcode = 59;
pub const CURLE_PEER_FAILED_VERIFICATION: CURLcode = 60;
pub const CURLE_AGAIN: CURLcode = 81;
pub const CURLE_SSL_PINNEDPUBKEYNOTMATCH: CURLcode = 90;
pub const CURLE_HTTP3: CURLcode = 95;
pub const CURLE_QUIC_CONNECT_ERROR: CURLcode = 96;

pub const curl_socket_t = headers_sock.curl_socket_t;
pub const CURL_SOCKET_BAD = headers_sock.CURL_SOCKET_BAD;
pub const socklen_t = c_uint;
pub const curltime = curlx_time_net.Curltime;
pub const timediff_t = curlx_time_net.timediff_t;

pub const CurlEasy = vtls_backends.CurlEasy;
pub const ConnectData = vtls_backends.ConnectData;
pub const CurlCfilter = vtls_backends.CurlCfilter;
pub const CurlCftype = vtls_backends.CurlCftype;
pub const CurlPeer = altsvc_hsts_peer.CurlPeer;
pub const SslPeer = vtls_scache_asn1.SslPeer;
pub const SslFilterConfig = vtls_scache_asn1.SslFilterConfig;
pub const SslEasyConfig = vtls_scache_asn1.SslEasyConfig;
pub const AlpnSpec = vtls_backends.AlpnSpec;
pub const CurlSslSession = vtls_core.CurlSslSession;
pub const CurlSockaddrEx = cfsocket_transfer.CurlSockaddrEx;
pub const CurlAddrinfo = netrc_addr_idn.Curl_addrinfo;
pub const bufq = io_buffers.bufq;
pub const dynbuf = containers.dynbuf;

pub const FIRSTSOCKET: i8 = 0;
pub const TRNSPRT_TCP: u8 = 3;
pub const TRNSPRT_UDP: u8 = 4;
pub const TRNSPRT_QUIC: u8 = 5;
pub const TRNSPRT_UNIX: u8 = 6;

pub const PROTOPT_SSL: u32 = protocol_version_mime.PROTOPT_SSL;
pub const CURLPROXY_HTTPS3: u8 = 8;

pub const NW_CHUNK_SIZE: usize = 64 * 1024;
pub const NW_SEND_CHUNKS: usize = 1;
pub const MAX_PKT_BURST: usize = 10;
pub const MAX_UDP_PAYLOAD_SIZE: usize = 1452;
pub const CMSG_BUF_SIZE: usize = 64;
pub const DYN_QLOG_NAME: usize = 1024;
pub const STRERROR_LEN: usize = 256;

pub const CURL_HTTP3_WEIGHT_MAX: c_int = 256;
pub const CURL_HTTP3_WEIGHT_DEFAULT: c_int = 16;

// HTTP/3 error codes defined in RFC 9114, ch. 8.1
pub const CURL_H3_ERR_NO_ERROR: u64 = 0x0100;
pub const CURL_H3_ERR_GENERAL_PROTOCOL_ERROR: u64 = 0x0101;
pub const CURL_H3_ERR_INTERNAL_ERROR: u64 = 0x0102;
pub const CURL_H3_ERR_STREAM_CREATION_ERROR: u64 = 0x0103;
pub const CURL_H3_ERR_CLOSED_CRITICAL_STREAM: u64 = 0x0104;
pub const CURL_H3_ERR_FRAME_UNEXPECTED: u64 = 0x0105;
pub const CURL_H3_ERR_FRAME_ERROR: u64 = 0x0106;
pub const CURL_H3_ERR_EXCESSIVE_LOAD: u64 = 0x0107;
pub const CURL_H3_ERR_ID_ERROR: u64 = 0x0108;
pub const CURL_H3_ERR_SETTINGS_ERROR: u64 = 0x0109;
pub const CURL_H3_ERR_MISSING_SETTINGS: u64 = 0x010a;
pub const CURL_H3_ERR_REQUEST_REJECTED: u64 = 0x010b;
pub const CURL_H3_ERR_REQUEST_CANCELLED: u64 = 0x010c;
pub const CURL_H3_ERR_REQUEST_INCOMPLETE: u64 = 0x010d;
pub const CURL_H3_ERR_MESSAGE_ERROR: u64 = 0x010e;
pub const CURL_H3_ERR_CONNECT_ERROR: u64 = 0x010f;
pub const CURL_H3_ERR_VERSION_FALLBACK: u64 = 0x0110;

pub const SockaddrStorage = extern struct {
    ss_family: u16 = 0,
    __ss_padding: [126]u8 = @splat(0),
};

const SockaddrIn = extern struct {
    sin_family: u16,
    sin_port: u16,
    sin_addr: [4]u8,
    sin_zero: [8]u8 = @splat(0),
};

const SockaddrIn6 = extern struct {
    sin6_family: u16,
    sin6_port: u16,
    sin6_flowinfo: u32,
    sin6_addr: [16]u8,
    sin6_scope_id: u32,
};

const InPktinfo = extern struct {
    ipi_ifindex: c_int,
    ipi_spec_dst: [4]u8,
    ipi_addr: [4]u8,
};

const In6Pktinfo = extern struct {
    ipi6_addr: [16]u8,
    ipi6_ifindex: c_uint,
};

const Iovec = extern struct {
    iov_base: ?*anyopaque,
    iov_len: usize,
};

const Msghdr = extern struct {
    msg_name: ?*anyopaque = null,
    msg_namelen: socklen_t = 0,
    msg_iov: ?[*]Iovec = null,
    msg_iovlen: usize = 0,
    msg_control: ?*anyopaque = null,
    msg_controllen: usize = 0,
    msg_flags: c_int = 0,
};

const Cmsghdr = extern struct {
    cmsg_len: usize,
    cmsg_level: c_int,
    cmsg_type: c_int,
};

const AF_INET: u16 = 2;
const AF_INET6: u16 = switch (builtin.os.tag) {
    .windows => 23,
    .macos, .ios, .tvos, .watchos, .visionos => 30,
    else => 10,
};

const IPPROTO_IP: c_int = 0;
const IPPROTO_IPV6: c_int = 41;
const SOL_UDP: c_int = 17;
const UDP_SEGMENT: c_int = 103;

const IP_TOS: c_int = 1;
const IP_PKTINFO: c_int = 8;
const IP_RECVTOS: c_int = 13;
const IPV6_PKTINFO: c_int = if (is_linux) 50 else 46;
const IPV6_TCLASS: c_int = if (is_linux) 67 else 36;

const SOCKEINTR: c_int = if (is_windows) 10004 else @backingInt(std.c.E.INTR);
const SOCKEAGAIN: c_int = if (is_windows) 10035 else @backingInt(std.c.E.AGAIN);
const SOCKEWOULDBLOCK: c_int = SOCKEAGAIN;
const SOCKEINVAL: c_int = if (is_windows) 10022 else @backingInt(std.c.E.INVAL);

inline fn sockerrno() c_int {
    if (is_windows) return 0;
    return std.c._errno().*;
}

inline fn fromOpaque(comptime T: type, raw: anytype) if (@typeInfo(T) == .pointer) ?T else ?*T {
    const p = mem.toRawPtr(raw) orelse return null;
    return @ptrCast(@alignCast(p));
}

fn cmsgAlign(len: usize) usize {
    const a: usize = @sizeOf(usize);
    return (len + a - 1) & ~(a - 1);
}

fn cmsgSpace(len: usize) usize {
    return cmsgAlign(@sizeOf(Cmsghdr)) + cmsgAlign(len);
}

fn cmsgLen(len: usize) usize {
    return cmsgAlign(@sizeOf(Cmsghdr)) + len;
}

fn cmsgData(cmsg: *Cmsghdr) [*]u8 {
    return fromOpaque([*]u8, cmsg).? + cmsgAlign(@sizeOf(Cmsghdr));
}

fn cmsgFirstHdr(msg: *const Msghdr) ?*Cmsghdr {
    if (msg.msg_controllen < @sizeOf(Cmsghdr)) return null;
    return fromOpaque(Cmsghdr, msg.msg_control);
}

fn cmsgNxtHdr(msg: *const Msghdr, cmsg: *Cmsghdr) ?*Cmsghdr {
    if (cmsg.cmsg_len < @sizeOf(Cmsghdr)) return null;
    const ctrl_base = fromOpaque([*]u8, msg.msg_control) orelse return null;
    const cur_base = fromOpaque([*]u8, cmsg).?;
    const next_offset = (@intFromPtr(cur_base) - @intFromPtr(ctrl_base)) + cmsgAlign(cmsg.cmsg_len);
    if (next_offset + @sizeOf(Cmsghdr) > msg.msg_controllen) return null;
    return fromOpaque(Cmsghdr, ctrl_base + next_offset);
}

const ProxyInfo = extern struct {
    peer: ?*CurlPeer,
    creds: ?*anyopaque,
    proxytype: u8,
};

// External C & Zig helpers
extern fn Curl_failf(data: ?*anyopaque, fmt: [*:0]const u8, ...) callconv(.c) void;
extern fn Curl_infof(data: ?*anyopaque, fmt: [*:0]const u8, ...) callconv(.c) void;
extern fn Curl_trc_cf_infof(data: ?*anyopaque, cf: ?*anyopaque, fmt: [*:0]const u8, ...) callconv(.c) void;
extern fn Curl_pgrs_now(data: ?*anyopaque) callconv(.c) *const curltime;
extern fn Curl_rand_bytes(data: ?*anyopaque, rnd: [*]u8, num: usize) callconv(.c) CURLcode;
extern fn curlx_str_number(linep: *?[*:0]const u8, nump: *i64, max: i64) callconv(.c) c_int;
extern fn Curl_conn_get_first_peer(conn: ?*anyopaque, sockindex: i8) callconv(.c) ?*CurlPeer;
extern fn Curl_conn_cf_insert_after(cf_at: *CurlCfilter, cf_new: *CurlCfilter) callconv(.c) void;

extern fn Curl_zig_url_data_get_ptr(data: *const anyopaque, ptr_id: c_int) callconv(.c) ?*anyopaque;
extern fn Curl_zig_url_conn_get_bit(conn: *const anyopaque, bit_id: c_int) callconv(.c) bool;
extern fn Curl_zig_url_conn_get_i64(conn: *const anyopaque, field_id: c_int) callconv(.c) i64;
extern fn Curl_zig_url_conn_get_ptr(conn: *const anyopaque, ptr_id: c_int) callconv(.c) ?*anyopaque;
extern fn Curl_setopt_get_i64(data: *const anyopaque, field_id: c_int) callconv(.c) i64;
extern fn Curl_easy_str_ptr(data: *anyopaque, idx: c_uint) callconv(.c) *?[*:0]u8;
extern fn Curl_ssl_EasyConfigPtr(data: ?*anyopaque) callconv(.c) ?*SslEasyConfig;

const DATA_PTR_STATE_ORIGIN: c_int = 5;
const CONN_BIT_TLS_ENABLE_ALPN: c_int = 16;
const CONN_I64_TRANSPORT_WANTED: c_int = 14;
const CONN_PTR_REF_HTTP_PROXY: c_int = 21;
const CONN_PTR_REF_SOCKS_PROXY: c_int = 22;
const FIELD_NEW_FILE_PERMS: c_int = 51;

const posix_net = if (!is_windows) struct {
    extern "c" fn sendmsg(sockfd: c_int, msg: *const Msghdr, flags: c_int) isize;
    extern "c" fn recvmsg(sockfd: c_int, msg: *Msghdr, flags: c_int) isize;
    extern "c" fn send(sockfd: c_int, buf: *const anyopaque, len: usize, flags: c_int) isize;
    extern "c" fn recvfrom(sockfd: c_int, buf: *anyopaque, len: usize, flags: c_int, src_addr: ?*anyopaque, addrlen: ?*socklen_t) isize;
    extern "c" fn open(path: [*:0]const u8, oflag: c_int, ...) c_int;
} else struct {};

// ============================================================================
// 1. ngtcp2 / nghttp3 / quiche C library bindings
// ============================================================================

pub const ngtcp2_info = extern struct {
    age: c_int,
    version_num: c_int,
    version_str: [*:0]const u8,
};

pub const nghttp3_info = extern struct {
    age: c_int,
    version_num: c_int,
    version_str: [*:0]const u8,
};

pub const ngtcp2_mem = extern struct {
    user_data: ?*anyopaque,
    malloc: ?*const fn (size: usize, user_data: ?*anyopaque) callconv(.c) ?*anyopaque,
    free: ?*const fn (ptr: ?*anyopaque, user_data: ?*anyopaque) callconv(.c) void,
    calloc: ?*const fn (nmemb: usize, size: usize, user_data: ?*anyopaque) callconv(.c) ?*anyopaque,
    realloc: ?*const fn (ptr: ?*anyopaque, size: usize, user_data: ?*anyopaque) callconv(.c) ?*anyopaque,
};

pub const nghttp3_mem = extern struct {
    user_data: ?*anyopaque,
    malloc: ?*const fn (size: usize, user_data: ?*anyopaque) callconv(.c) ?*anyopaque,
    free: ?*const fn (ptr: ?*anyopaque, user_data: ?*anyopaque) callconv(.c) void,
    calloc: ?*const fn (nmemb: usize, size: usize, user_data: ?*anyopaque) callconv(.c) ?*anyopaque,
    realloc: ?*const fn (ptr: ?*anyopaque, size: usize, user_data: ?*anyopaque) callconv(.c) ?*anyopaque,
};

const ngtcp2_ext = if (backend_options.quic == .ngtcp2) struct {
    extern fn ngtcp2_version(least_version: c_int) callconv(.c) *const ngtcp2_info;
    extern fn nghttp3_version(least_version: c_int) callconv(.c) *const nghttp3_info;
} else struct {};

const ngtcp2_ossl_ext = if (backend_options.quic == .ngtcp2 and backend_options.ssl == .openssl and !backend_options.bundled) struct {
    extern fn ngtcp2_crypto_ossl_init() callconv(.c) c_int;
} else struct {};

const quiche_ext = if (backend_options.quic == .quiche) struct {
    extern fn quiche_version() callconv(.c) [*:0]const u8;
} else struct {};

fn quic_malloc(size: usize, user_data: ?*anyopaque) callconv(.c) ?*anyopaque {
    _ = user_data;
    return mem.malloc(size);
}

fn quic_free(ptr: ?*anyopaque, user_data: ?*anyopaque) callconv(.c) void {
    _ = user_data;
    mem.free(ptr);
}

fn quic_calloc(nmemb: usize, size: usize, user_data: ?*anyopaque) callconv(.c) ?*anyopaque {
    _ = user_data;
    return mem.calloc(nmemb, size);
}

fn quic_realloc(ptr: ?*anyopaque, size: usize, user_data: ?*anyopaque) callconv(.c) ?*anyopaque {
    _ = user_data;
    return mem.realloc(ptr, size);
}

const curl_ngtcp2_mem_instance = ngtcp2_mem{
    .user_data = null,
    .malloc = quic_malloc,
    .free = quic_free,
    .calloc = quic_calloc,
    .realloc = quic_realloc,
};

const curl_nghttp3_mem_instance = nghttp3_mem{
    .user_data = null,
    .malloc = quic_malloc,
    .free = quic_free,
    .calloc = quic_calloc,
    .realloc = quic_realloc,
};

pub fn Curl_ngtcp2_mem() callconv(.c) *const ngtcp2_mem {
    return &curl_ngtcp2_mem_instance;
}

pub fn Curl_nghttp3_mem() callconv(.c) *const nghttp3_mem {
    return &curl_nghttp3_mem_instance;
}

// ============================================================================
// 2. Global Init / Cleanup & Version Strings (lib/vquic/vquic.c)
// ============================================================================

/// Initialize QUIC backend (`Curl_vquic_init` in `lib/vquic/vquic.c`).
/// Returns 1 on success, 0 on failure.
pub fn Curl_vquic_init() callconv(.c) c_int {
    if (comptime (backend_options.quic == .ngtcp2 and backend_options.ssl == .openssl and !backend_options.bundled)) {
        if (ngtcp2_ossl_ext.ngtcp2_crypto_ossl_init() != 0)
            return 0;
    }
    return 1;
}

/// Clean up QUIC backend (`Curl_vquic_cleanup` in `lib/vquic/vquic.c`).
/// Note: ngtcp2 1.16.0 on Ubuntu 24.04 does not have `ngtcp2_crypto_ossl_free`
/// (added in 1.24.0), so this is a safe no-op.
pub fn Curl_vquic_cleanup() callconv(.c) void {}

/// Format ngtcp2 + nghttp3 version string (`Curl_cf_ngtcp2_ver` in `lib/vquic/cf-ngtcp2.c`).
pub fn Curl_cf_ngtcp2_ver(p: [*]u8, len: usize) callconv(.c) void {
    if (len == 0) return;
    if (comptime (backend_options.quic == .ngtcp2)) {
        const ng2 = ngtcp2_ext.ngtcp2_version(0);
        const ht3 = ngtcp2_ext.nghttp3_version(0);
        const ng2_str = std.mem.span(ng2.version_str);
        const ht3_str = std.mem.span(ht3.version_str);
        const s = std.fmt.bufPrint(p[0 .. len - 1], "ngtcp2/{s} nghttp3/{s}", .{ ng2_str, ht3_str }) catch {
            p[0] = 0;
            return;
        };
        p[s.len] = 0;
    } else {
        p[0] = 0;
    }
}

/// Format quiche version string (`Curl_cf_quiche_ver` in `lib/vquic/cf-quiche.c`).
pub const Curl_cf_quiche_ver = vquic_quiche.Curl_quiche_ver;

/// Format QUIC version string (`Curl_quic_ver` in `lib/vquic/vquic.c`).
pub fn Curl_quic_ver(p: [*]u8, len: usize) callconv(.c) void {
    if (len == 0) return;
    switch (comptime backend_options.quic) {
        .ngtcp2 => Curl_cf_ngtcp2_ver(p, len),
        .quiche => vquic_quiche.Curl_quiche_ver(p, len),
        .none => p[0] = 0,
    }
}

/// Map HTTP/3 error codes to human-readable strings (`Curl_vquic_h3_err_str` in `lib/vquic/vquic.c`).
pub fn Curl_vquic_h3_err_str(error_code: u64) callconv(.c) [*:0]const u8 {
    if (error_code <= std.math.maxInt(c_uint)) {
        switch (@as(c_uint, @intCast(error_code))) {
            CURL_H3_ERR_NO_ERROR => return "NO_ERROR",
            CURL_H3_ERR_GENERAL_PROTOCOL_ERROR => return "GENERAL_PROTOCOL_ERROR",
            CURL_H3_ERR_INTERNAL_ERROR => return "INTERNAL_ERROR",
            CURL_H3_ERR_STREAM_CREATION_ERROR => return "STREAM_CREATION_ERROR",
            CURL_H3_ERR_CLOSED_CRITICAL_STREAM => return "CLOSED_CRITICAL_STREAM",
            CURL_H3_ERR_FRAME_UNEXPECTED => return "FRAME_UNEXPECTED",
            CURL_H3_ERR_FRAME_ERROR => return "FRAME_ERROR",
            CURL_H3_ERR_EXCESSIVE_LOAD => return "EXCESSIVE_LOAD",
            CURL_H3_ERR_ID_ERROR => return "ID_ERROR",
            CURL_H3_ERR_SETTINGS_ERROR => return "SETTINGS_ERROR",
            CURL_H3_ERR_MISSING_SETTINGS => return "MISSING_SETTINGS",
            CURL_H3_ERR_REQUEST_REJECTED => return "REQUEST_REJECTED",
            CURL_H3_ERR_REQUEST_CANCELLED => return "REQUEST_CANCELLED",
            CURL_H3_ERR_REQUEST_INCOMPLETE => return "REQUEST_INCOMPLETE",
            CURL_H3_ERR_MESSAGE_ERROR => return "MESSAGE_ERROR",
            CURL_H3_ERR_CONNECT_ERROR => return "CONNECT_ERROR",
            CURL_H3_ERR_VERSION_FALLBACK => return "VERSION_FALLBACK",
            else => {},
        }
    }
    if (error_code >= 0x21 and ((error_code - 0x21) % 0x1f) == 0) {
        return "NO_ERROR";
    }
    return "unknown";
}

// ============================================================================
// 3. QLOG Directory Handling & Packet/Socket I/O (lib/vquic/vquic.c)
// ============================================================================

/// Open a `.sqlog` file in `QLOGDIR` if the environment variable is set.
/// Matches `Curl_qlogdir` in `lib/vquic/vquic.c`.
pub export fn Curl_qlogdir(
    data: ?*anyopaque,
    scid: [*]const u8,
    scidlen: usize,
    qlogfdp: *c_int,
) callconv(.c) void {
    const qlog_dir = os_leaf.curl_getenv("QLOGDIR") orelse return;
    defer mem.free(qlog_dir);

    var fname: dynbuf = undefined;
    containers.curlx_dyn_init(&fname, DYN_QLOG_NAME);
    defer containers.curlx_dyn_free(&fname);

    var result = containers.curlx_dyn_add(&fname, qlog_dir);
    if (result == CURLE_OK) {
        const dir_slice = std.mem.span(qlog_dir);
        const needs_sep = if (dir_slice.len == 0)
            false
        else if (is_windows)
            (dir_slice[dir_slice.len - 1] != '/' and dir_slice[dir_slice.len - 1] != '\\')
        else
            (dir_slice[dir_slice.len - 1] != '/');
        if (needs_sep) {
            result = containers.curlx_dyn_add(&fname, "/");
        }
    }

    const hex = "0123456789abcdef";
    for (0..scidlen) |i| {
        if (result != CURLE_OK) break;
        var entries: [2]u8 = .{
            hex[scid[i] >> 4],
            hex[scid[i] & 0x0f],
        };
        result = containers.curlx_dyn_addn(&fname, &entries, 2);
    }

    if (result == CURLE_OK) {
        result = containers.curlx_dyn_add(&fname, ".sqlog");
    }

    if (result == CURLE_OK) {
        if (containers.curlx_dyn_ptr(&fname)) |path_ptr| {
            const perms: c_uint = if (data) |d|
                @intCast(Curl_setopt_get_i64(d, FIELD_NEW_FILE_PERMS))
            else
                0o644;
            if (!is_windows) {
                const O_WRONLY: c_int = 1;
                const O_CREAT: c_int = 0o100;
                const O_EXCL: c_int = 0o200;
                var qlogfd = posix_net.open(path_ptr, O_WRONLY | O_CREAT | O_EXCL, perms);
                if (qlogfd == -1) {
                    qlogfd = posix_net.open(path_ptr, O_WRONLY | O_CREAT, perms);
                }
                if (qlogfd != -1) {
                    qlogfdp.* = qlogfd;
                }
            }
        }
    }
}

pub const CfQuicPkt = extern struct {
    pkt: [*]const u8 = undefined,
    pktlen: usize = 0,
    gsolen: usize = 0,
};

pub const CfQuicCtx = struct {
    sockfd: curl_socket_t = CURL_SOCKET_BAD,
    local_addr: SockaddrStorage = .{},
    local_addrlen: socklen_t = 0,
    sendbuf: bufq = undefined,
    first_byte_at: curltime = .{ .tv_sec = 0, .tv_usec = 0 },
    last_op: curltime = .{ .tv_sec = 0, .tv_usec = 0 },
    last_io: curltime = .{ .tv_sec = 0, .tv_usec = 0 },
    gsolen: usize = 0,
    split_len: usize = 0,
    split_gsolen: usize = 0,
    blocked_pkt: [2]CfQuicPkt = .{ .{}, .{} },
    blocked_pkt_count: u8 = 0,
    wblock_percent: u8 = 0,
    got_first_byte: bool = false,
    no_gso: bool = false,
    has_gso: bool = false,
};

pub const vquic_pkt_rcvd_cb = *const fn (
    pkt: [*]const u8,
    pktlen: usize,
    remote_addr: *const SockaddrStorage,
    remote_addrlen: socklen_t,
    ifindex: c_int,
    ecn: u8,
    userp: ?*anyopaque,
) callconv(.c) CURLcode;

pub const Curl_QuicPktRcvd = vquic_pkt_rcvd_cb;

/// Initialize QUIC packet context (`vquic_ctx_init` in `lib/vquic/vquic.c`).
pub fn vquic_ctx_init(data: ?*anyopaque, qctx: *CfQuicCtx) callconv(.c) CURLcode {
    qctx.* = .{};
    io_buffers.Curl_bufq_init2(
        &qctx.sendbuf,
        NW_CHUNK_SIZE,
        NW_SEND_CHUNKS,
        io_buffers.BUFQ_OPT_SOFT_LIMIT,
    );
    qctx.has_gso = is_linux;
    if (os_leaf.curl_getenv("CURL_DBG_QUIC_WBLOCK")) |p| {
        defer mem.free(p);
        var l: i64 = 0;
        var ptr: ?[*:0]const u8 = p;
        if (curlx_str_number(&ptr, &l, 100) == 0 and l >= 0 and l <= 100) {
            qctx.wblock_percent = @intCast(l);
        }
    }
    vquic_ctx_update_time(qctx, data);
    return CURLE_OK;
}

pub const Curl_vquic_ctx_init = vquic_ctx_init;

/// Free QUIC packet context (`vquic_ctx_free` in `lib/vquic/vquic.c`).
pub fn vquic_ctx_free(qctx: *CfQuicCtx) callconv(.c) void {
    io_buffers.Curl_bufq_free(&qctx.sendbuf);
    qctx.blocked_pkt = .{ .{}, .{} };
    qctx.blocked_pkt_count = 0;
}

pub const Curl_vquic_ctx_free = vquic_ctx_free;

pub fn vquic_ctx_set_time(qctx: *CfQuicCtx, pnow: *const curltime) callconv(.c) void {
    qctx.last_op = pnow.*;
}

pub const Curl_vquic_ctx_set_time = vquic_ctx_set_time;

pub fn vquic_ctx_update_time(qctx: *CfQuicCtx, data: ?*anyopaque) callconv(.c) void {
    if (data) |d| {
        qctx.last_op = Curl_pgrs_now(d).*;
    } else {
        curlx_time_net.curlx_pnow(&qctx.last_op);
    }
}

pub const Curl_vquic_ctx_update_time = vquic_ctx_update_time;

pub fn vquic_push_blocked_pkt(
    cf: ?*CurlCfilter,
    qctx: *CfQuicCtx,
    pkt: [*]const u8,
    pktlen: usize,
    gsolen: usize,
) callconv(.c) void {
    _ = cf;
    std.debug.assert(qctx.blocked_pkt_count < qctx.blocked_pkt.len);
    qctx.blocked_pkt[qctx.blocked_pkt_count] = .{
        .pkt = pkt,
        .pktlen = pktlen,
        .gsolen = gsolen,
    };
    qctx.blocked_pkt_count += 1;
}

fn do_sendmsg(
    cf: ?*CurlCfilter,
    data: ?*anyopaque,
    qctx: *CfQuicCtx,
    pkt: [*]const u8,
    pktlen: usize,
    gsolen: usize,
    psent: *usize,
) CURLcode {
    psent.* = 0;
    if (comptime !has_sendmsg) {
        return send_packet_no_gso(cf, data, qctx, pkt, pktlen, gsolen, psent);
    } else {
        var msg_iov = [1]Iovec{.{
            .iov_base = @constCast(pkt),
            .iov_len = pktlen,
        }};
        var msg: Msghdr = .{
            .msg_iov = &msg_iov,
            .msg_iovlen = 1,
        };
        var cmsg_buf: [CMSG_BUF_SIZE]u8 align(@alignOf(Cmsghdr)) = @splat(0);

        if (is_linux and pktlen > gsolen and gsolen > 0) {
            msg.msg_control = &cmsg_buf;
            msg.msg_controllen = cmsgSpace(@sizeOf(u16));
            if (cmsgFirstHdr(&msg)) |cmhdr| {
                cmhdr.cmsg_level = SOL_UDP;
                cmhdr.cmsg_type = UDP_SEGMENT;
                cmhdr.cmsg_len = cmsgLen(@sizeOf(u16));
                const gso_u16: u16 = @intCast(gsolen);
                @memcpy(cmsgData(cmhdr)[0..@sizeOf(u16)], std.mem.asBytes(&gso_u16));
            }
        }

        var s: isize = -1;
        while (true) {
            s = posix_net.sendmsg(qctx.sockfd, &msg, 0);
            if (s >= 0) break;
            if (sockerrno() != SOCKEINTR) break;
        }

        if (s == -1) {
            const err = sockerrno();
            if (err == SOCKEAGAIN or err == SOCKEWOULDBLOCK) {
                return CURLE_AGAIN;
            } else if (err == @backingInt(std.c.E.MSGSIZE)) {
                return CURLE_SEND_ERROR;
            } else if (is_linux and (err == @backingInt(std.c.E.IO) or err == SOCKEINVAL)) {
                qctx.no_gso = true;
                return send_packet_no_gso(cf, data, qctx, pkt, pktlen, gsolen, psent);
            } else {
                var errbuf: [STRERROR_LEN]u8 = undefined;
                Curl_failf(
                    data,
                    "sendmsg()=%zd (errno %d: %s)",
                    s,
                    err,
                    curlx_time_net.curlx_strerror(err, &errbuf, errbuf.len),
                );
                return CURLE_SEND_ERROR;
            }
        }

        psent.* = @intCast(s);
        return CURLE_OK;
    }
}

fn send_packet_no_gso(
    cf: ?*CurlCfilter,
    data: ?*anyopaque,
    qctx: *CfQuicCtx,
    pkt: [*]const u8,
    pktlen: usize,
    gsolen: usize,
    psent: *usize,
) CURLcode {
    var offset: usize = 0;
    const step = if (gsolen > 0) gsolen else pktlen;
    psent.* = 0;

    while (offset < pktlen) {
        const len = @min(step, pktlen - offset);
        var sent: usize = 0;
        if (comptime has_sendmsg) {
            var msg_iov = [1]Iovec{.{
                .iov_base = @constCast(pkt + offset),
                .iov_len = len,
            }};
            var msg: Msghdr = .{
                .msg_iov = &msg_iov,
                .msg_iovlen = 1,
            };
            var s: isize = -1;
            while (true) {
                s = posix_net.sendmsg(qctx.sockfd, &msg, 0);
                if (s >= 0) break;
                if (sockerrno() != SOCKEINTR) break;
            }
            if (s == -1) {
                const err = sockerrno();
                if (err == SOCKEAGAIN or err == SOCKEWOULDBLOCK) {
                    return CURLE_AGAIN;
                } else if (err == @backingInt(std.c.E.MSGSIZE)) {
                    return CURLE_SEND_ERROR;
                } else {
                    var errbuf: [STRERROR_LEN]u8 = undefined;
                    Curl_failf(
                        data,
                        "sendmsg()=%zd (errno %d: %s)",
                        s,
                        err,
                        curlx_time_net.curlx_strerror(err, &errbuf, errbuf.len),
                    );
                    return CURLE_SEND_ERROR;
                }
            }
            sent = @intCast(s);
        } else {
            _ = cf;
            return CURLE_SEND_ERROR;
        }
        offset += sent;
        psent.* += sent;
    }
    return CURLE_OK;
}

pub fn vquic_send_packets(
    cf: ?*CurlCfilter,
    data: ?*anyopaque,
    qctx: *CfQuicCtx,
    pkt: [*]const u8,
    pktlen: usize,
    gsolen: usize,
    psent: *usize,
) callconv(.c) CURLcode {
    vquic_ctx_update_time(qctx, data);
    if (qctx.wblock_percent > 0) {
        var r: [1]u8 = .{0};
        _ = Curl_rand_bytes(data, &r, 1);
        if (r[0] >= (@as(u16, 100 - qctx.wblock_percent) * 256) / 100) {
            return CURLE_AGAIN;
        }
    }
    const result = if (!qctx.no_gso and qctx.has_gso)
        do_sendmsg(cf, data, qctx, pkt, pktlen, gsolen, psent)
    else
        send_packet_no_gso(cf, data, qctx, pkt, pktlen, gsolen, psent);
    if (result == CURLE_OK and psent.* > 0) {
        qctx.last_io = qctx.last_op;
    }
    return result;
}

pub const Curl_vquic_send_packets = vquic_send_packets;

pub fn vquic_send_blocked_pkts(
    cf: ?*CurlCfilter,
    data: ?*anyopaque,
    qctx: *CfQuicCtx,
) callconv(.c) CURLcode {
    var result: CURLcode = CURLE_OK;
    while (qctx.blocked_pkt_count > 0) {
        var sent: usize = 0;
        const b = qctx.blocked_pkt[0];
        result = vquic_send_packets(cf, data, qctx, b.pkt, b.pktlen, b.gsolen, &sent);
        if (result != CURLE_OK) {
            if (result == CURLE_AGAIN) {
                std.debug.assert(sent <= b.pktlen);
                if (b.gsolen > 0) {
                    std.debug.assert((sent % b.gsolen) == 0);
                }
                qctx.blocked_pkt[0].pkt += sent;
                qctx.blocked_pkt[0].pktlen -= sent;
            }
            break;
        }
        io_buffers.Curl_bufq_skip(&qctx.sendbuf, b.pktlen);
        if (qctx.blocked_pkt_count > 1) {
            qctx.blocked_pkt[0] = qctx.blocked_pkt[1];
        }
        qctx.blocked_pkt_count -= 1;
    }
    return result;
}

pub const Curl_vquic_send_blocked_pkts = vquic_send_blocked_pkts;

pub fn vquic_send(
    cf: ?*CurlCfilter,
    data: ?*anyopaque,
    qctx: *CfQuicCtx,
    gsolen: usize,
) callconv(.c) CURLcode {
    var pkt: ?[*]const u8 = null;
    var pktlen: usize = 0;
    var sent: usize = 0;

    std.debug.assert(!io_buffers.Curl_bufq_is_empty(&qctx.sendbuf));
    if (!io_buffers.Curl_bufq_peek(&qctx.sendbuf, &pkt, &pktlen)) {
        return CURLE_INTERNAL_ERROR;
    }

    const result = vquic_send_packets(cf, data, qctx, pkt.?, pktlen, gsolen, &sent);
    if (result != CURLE_OK) {
        if (result == CURLE_AGAIN) {
            io_buffers.Curl_bufq_skip(&qctx.sendbuf, sent);
            if (pktlen > sent) {
                vquic_push_blocked_pkt(cf, qctx, pkt.? + sent, pktlen - sent, gsolen);
            }
        }
        return result;
    }
    io_buffers.Curl_bufq_skip(&qctx.sendbuf, pktlen);
    return CURLE_OK;
}

const CURLE_INTERNAL_ERROR: CURLcode = 43;
pub const Curl_vquic_send = vquic_send;

pub fn vquic_send_tail_split(
    cf: ?*CurlCfilter,
    data: ?*anyopaque,
    qctx: *CfQuicCtx,
    gsolen: usize,
    tail_len: usize,
    tail_gsolen: usize,
) callconv(.c) CURLcode {
    var pkt: ?[*]const u8 = null;
    var pktlen: usize = 0;
    var sent: usize = 0;

    std.debug.assert(io_buffers.Curl_bufq_len(&qctx.sendbuf) > tail_len);
    if (!io_buffers.Curl_bufq_peek(&qctx.sendbuf, &pkt, &pktlen)) {
        return CURLE_INTERNAL_ERROR;
    }

    std.debug.assert(pktlen > tail_len);
    pktlen -= tail_len;

    var result = vquic_send_packets(cf, data, qctx, pkt.?, pktlen, gsolen, &sent);
    if (result != CURLE_OK) {
        if (result == CURLE_AGAIN) {
            io_buffers.Curl_bufq_skip(&qctx.sendbuf, sent);
            vquic_push_blocked_pkt(cf, qctx, pkt.? + sent, pktlen - sent, gsolen);
            vquic_push_blocked_pkt(cf, qctx, pkt.? + pktlen, tail_len, tail_gsolen);
        }
        return result;
    }
    io_buffers.Curl_bufq_skip(&qctx.sendbuf, pktlen);

    sent = 0;
    result = vquic_send_packets(cf, data, qctx, pkt.? + pktlen, tail_len, tail_gsolen, &sent);
    if (result != CURLE_OK) {
        if (result == CURLE_AGAIN) {
            io_buffers.Curl_bufq_skip(&qctx.sendbuf, sent);
            vquic_push_blocked_pkt(cf, qctx, pkt.? + pktlen + sent, tail_len - sent, tail_gsolen);
        }
        return result;
    }
    io_buffers.Curl_bufq_skip(&qctx.sendbuf, tail_len);
    return CURLE_OK;
}

pub const Curl_vquic_send_tail_split = vquic_send_tail_split;

pub fn vquic_flush(
    cf: ?*CurlCfilter,
    data: ?*anyopaque,
    qctx: *CfQuicCtx,
) callconv(.c) CURLcode {
    if (qctx.blocked_pkt_count > 0) {
        const result = vquic_send_blocked_pkts(cf, data, qctx);
        if (result != CURLE_OK) {
            return result;
        }
    }
    if (!io_buffers.Curl_bufq_is_empty(&qctx.sendbuf)) {
        if (qctx.split_len > 0) {
            return vquic_send_tail_split(
                cf,
                data,
                qctx,
                qctx.gsolen,
                qctx.split_len,
                qctx.split_gsolen,
            );
        }
        return vquic_send(cf, data, qctx, qctx.gsolen);
    }
    return CURLE_OK;
}

pub const Curl_vquic_flush = vquic_flush;

/// Receive UDP packets and invoke `pkt_rcvd_cb` with packet payload, remote address,
/// local interface index (`IP_PKTINFO` / `IPV6_PKTINFO`), and ECN bits (`IP_TOS` / `IPV6_TCLASS`).
/// Matches `vquic_recv_packets` in `lib/vquic/vquic.c`.
pub fn vquic_recv_packets(
    cf: ?*CurlCfilter,
    data: ?*anyopaque,
    qctx: *CfQuicCtx,
    max_pkts: usize,
    pkt_rcvd_cb: vquic_pkt_rcvd_cb,
    userp: ?*anyopaque,
) callconv(.c) CURLcode {
    _ = cf;
    var buf: [64 * 1024]u8 = undefined;
    var result: CURLcode = CURLE_OK;
    var pkts: usize = 0;

    vquic_ctx_update_time(qctx, data);

    if (comptime has_sendmsg) {
        var raddr: SockaddrStorage = .{};
        var msg_iov = [1]Iovec{.{
            .iov_base = &buf,
            .iov_len = buf.len,
        }};
        var cmsg_buf: [512]u8 align(@alignOf(Cmsghdr)) = @splat(0);

        while (pkts < max_pkts) {
            raddr = .{};
            msg_iov[0] = .{
                .iov_base = &buf,
                .iov_len = buf.len,
            };
            var msg: Msghdr = .{
                .msg_name = &raddr,
                .msg_namelen = @sizeOf(SockaddrStorage),
                .msg_iov = &msg_iov,
                .msg_iovlen = 1,
                .msg_control = &cmsg_buf,
                .msg_controllen = cmsg_buf.len,
                .msg_flags = 0,
            };

            var rc: isize = -1;
            while (true) {
                rc = posix_net.recvmsg(qctx.sockfd, &msg, 0);
                if (rc >= 0) break;
                if (sockerrno() != SOCKEINTR) break;
            }
            if (rc < 0) {
                const err = sockerrno();
                if (err == SOCKEAGAIN or err == SOCKEWOULDBLOCK) {
                    break;
                }
                var errbuf: [STRERROR_LEN]u8 = undefined;
                Curl_failf(
                    data,
                    "recvmsg()=%zd (errno %d: %s)",
                    rc,
                    err,
                    curlx_time_net.curlx_strerror(err, &errbuf, errbuf.len),
                );
                return CURLE_RECV_ERROR;
            }

            const rlen: usize = @intCast(rc);
            if (!qctx.got_first_byte) {
                qctx.first_byte_at = qctx.last_op;
                qctx.got_first_byte = true;
            }
            qctx.last_io = qctx.last_op;
            pkts += 1;

            var ecn: u8 = 0;
            var ifindex: c_int = 0;
            var cmsg_opt = cmsgFirstHdr(&msg);
            while (cmsg_opt) |cmsg| : (cmsg_opt = cmsgNxtHdr(&msg, cmsg)) {
                const payload = cmsgData(cmsg);
                switch (cmsg.cmsg_level) {
                    IPPROTO_IP => {
                        if (cmsg.cmsg_type == IP_TOS or cmsg.cmsg_type == IP_RECVTOS) {
                            ecn = payload[0];
                        } else if (cmsg.cmsg_type == IP_PKTINFO and cmsg.cmsg_len >= cmsgLen(@sizeOf(InPktinfo))) {
                            var pktinfo: InPktinfo = undefined;
                            @memcpy(std.mem.asBytes(&pktinfo), payload[0..@sizeOf(InPktinfo)]);
                            ifindex = pktinfo.ipi_ifindex;
                            var sa4 = fromOpaque(SockaddrIn, &qctx.local_addr).?;
                            sa4.sin_family = AF_INET;
                            sa4.sin_addr = pktinfo.ipi_addr;
                            qctx.local_addrlen = @sizeOf(SockaddrIn);
                        }
                    },
                    IPPROTO_IPV6 => {
                        if (cmsg.cmsg_type == IPV6_TCLASS and cmsg.cmsg_len >= cmsgLen(@sizeOf(c_int))) {
                            var tclass: c_int = 0;
                            @memcpy(std.mem.asBytes(&tclass), payload[0..@sizeOf(c_int)]);
                            ecn = @truncate(@as(c_uint, @bitCast(tclass)));
                        } else if (cmsg.cmsg_type == IPV6_PKTINFO and cmsg.cmsg_len >= cmsgLen(@sizeOf(In6Pktinfo))) {
                            var pktinfo6: In6Pktinfo = undefined;
                            @memcpy(std.mem.asBytes(&pktinfo6), payload[0..@sizeOf(In6Pktinfo)]);
                            ifindex = @intCast(pktinfo6.ipi6_ifindex);
                            var sa6 = fromOpaque(SockaddrIn6, &qctx.local_addr).?;
                            sa6.sin6_family = AF_INET6;
                            sa6.sin6_addr = pktinfo6.ipi6_addr;
                            qctx.local_addrlen = @sizeOf(SockaddrIn6);
                        }
                    },
                    else => {},
                }
            }

            result = pkt_rcvd_cb(&buf, rlen, &raddr, msg.msg_namelen, ifindex, ecn, userp);
            if (result != CURLE_OK) {
                break;
            }
        }
    }

    return result;
}

pub const Curl_vquic_recv_packets = vquic_recv_packets;

// ============================================================================
// 4. Connection Eligibility & Cfilter Creation (lib/vquic/vquic.c)
// ============================================================================

/// Check whether `conn` may use HTTP/3 (`Curl_conn_may_http3` in `lib/vquic/vquic.c`).
pub export fn Curl_conn_may_http3(
    data: ?*anyopaque,
    conn: ?*anyopaque,
) callconv(.c) CURLcode {
    if (!use_http3) {
        return CURLE_NOT_BUILT_IN;
    }
    const c = conn orelse return CURLE_QUIC_CONNECT_ERROR;

    if (Curl_conn_get_first_peer(c, FIRSTSOCKET)) |first_peer| {
        if (first_peer.unixSocket()) {
            Curl_failf(data, "HTTP/3 cannot be used over UNIX domain sockets");
            return CURLE_QUIC_CONNECT_ERROR;
        }
    }
    if (Curl_zig_url_conn_get_i64(c, CONN_I64_TRANSPORT_WANTED) == TRNSPRT_UNIX) {
        Curl_failf(data, "HTTP/3 cannot be used over UNIX domain sockets");
        return CURLE_QUIC_CONNECT_ERROR;
    }

    if (data) |d| {
        if (fromOpaque(*const CurlPeer, Curl_zig_url_data_get_ptr(d, DATA_PTR_STATE_ORIGIN))) |origin| {
            const scheme_flags = if (origin.scheme) |sc| sc.flags else 0;
            if ((scheme_flags & PROTOPT_SSL) == 0) {
                Curl_failf(data, "HTTP/3 requested for non-HTTPS URL");
                return CURLE_URL_MALFORMAT;
            }
        }
    }

    if (fromOpaque(*const ProxyInfo, Curl_zig_url_conn_get_ptr(c, CONN_PTR_REF_SOCKS_PROXY))) |sp| {
        if (sp.peer != null) {
            Curl_failf(data, "HTTP/3 is not supported over a SOCKS proxy");
            return CURLE_URL_MALFORMAT;
        }
    }

    return CURLE_OK;
}

pub const Curl_cf_ngtcp2_create = vquic_ngtcp2.Curl_cf_ngtcp2_create;
pub const Curl_cf_ngtcp2_insert_after = vquic_ngtcp2.Curl_cf_ngtcp2_insert_after;
pub const Curl_cf_ngtcp2_proxy_create = vquic_ngtcp2.Curl_cf_ngtcp2_proxy_create;
pub const Curl_cf_ngtcp2_proxy_insert_after = vquic_ngtcp2.Curl_cf_ngtcp2_proxy_insert_after;

pub const Curl_cf_quiche_create = vquic_quiche.Curl_cf_quiche_create;
pub const Curl_cf_quiche_insert_after = vquic_quiche.Curl_cf_quiche_insert_after;

pub const Curl_cft_http3 = switch (backend_options.quic) {
    .ngtcp2 => &vquic_ngtcp2.Curl_cft_http3,
    .quiche => &vquic_quiche.Curl_cft_http3,
    .none => null,
};

/// Create QUIC connection filter (`Curl_cf_quic_create` in `lib/vquic/vquic.c`).
pub export fn Curl_cf_quic_create(
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
    if (!use_http3) return CURLE_NOT_BUILT_IN;

    _ = tunnel_peer;
    _ = tunnel_transport;
    std.debug.assert(transport_peer == TRNSPRT_QUIC);
    return switch (comptime backend_options.quic) {
        .ngtcp2 => vquic_ngtcp2.Curl_cf_ngtcp2_create(pcf, data, origin, peer, conn, addr),
        .quiche => vquic_quiche.Curl_cf_quiche_create(pcf, data, origin, peer, conn, addr),
        .none => CURLE_NOT_BUILT_IN,
    };
}

/// Insert QUIC connection filter after `cf_at` (`Curl_cf_quic_insert_after` in `lib/vquic/vquic.c`).
pub export fn Curl_cf_quic_insert_after(
    cf_at: *CurlCfilter,
    data: ?*CurlEasy,
    origin: ?*CurlPeer,
    peer: ?*CurlPeer,
) callconv(.c) CURLcode {
    _ = data;
    var cf: ?*CurlCfilter = null;
    return switch (comptime backend_options.quic) {
        .ngtcp2 => vquic_ngtcp2.Curl_cf_ngtcp2_insert_after(cf_at, origin, peer, &cf),
        .quiche => vquic_quiche.Curl_cf_quiche_insert_after(cf_at, origin, peer, &cf),
        .none => CURLE_NOT_BUILT_IN,
    };
}

/// Create HTTP/3 proxy tunnel connection filter (`Curl_cf_h3_proxy_create` in `lib/vquic/vquic.c`).
pub export fn Curl_cf_h3_proxy_create(
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
    if (!use_proxy_http3) return CURLE_NOT_BUILT_IN;

    std.debug.assert(transport_peer == TRNSPRT_QUIC);
    return switch (comptime backend_options.quic) {
        .ngtcp2 => vquic_ngtcp2.Curl_cf_ngtcp2_proxy_create(
            pcf,
            data,
            origin,
            peer,
            transport_peer,
            conn,
            addr,
            tunnel_peer,
            tunnel_transport,
        ),
        .quiche, .none => CURLE_NOT_BUILT_IN,
    };
}

/// Insert HTTP/3 proxy tunnel filter after `cf_at` (`Curl_cf_h3_proxy_insert_after` in `lib/vquic/vquic.c`).
pub export fn Curl_cf_h3_proxy_insert_after(
    cf_at: *CurlCfilter,
    data: ?*CurlEasy,
    origin: ?*CurlPeer,
    peer: ?*CurlPeer,
    tunnel_peer: ?*CurlPeer,
    tunnel_transport: u8,
) callconv(.c) CURLcode {
    if (!use_proxy_http3) return CURLE_NOT_BUILT_IN;
    return switch (comptime backend_options.quic) {
        .ngtcp2 => vquic_ngtcp2.Curl_cf_ngtcp2_proxy_insert_after(
            cf_at,
            data,
            origin,
            peer,
            tunnel_peer,
            tunnel_transport,
        ),
        .quiche, .none => CURLE_NOT_BUILT_IN,
    };
}

// ============================================================================
// 5. QUIC TLS Bridge (lib/vquic/vquic-tls.c + lib/vquic/vquic-tls.h)
// ============================================================================

pub const CurlTlsCtx = struct {
    ossl: ossl_backend.OsslCtx = .{},
    gtls: vtls_gtls.GtlsCtx = .{},
    wssl: vtls_wolfssl.WsslCtx = .{},
};

pub const Curl_vquic_tls_ctx_setup = *const fn (
    cf: *CurlCfilter,
    data: ?*CurlEasy,
    cb_user_data: ?*anyopaque,
) callconv(.c) CURLcode;

pub const Curl_vquic_session_reuse_cb = *const fn (
    cf: *CurlCfilter,
    data: ?*CurlEasy,
    alpns: *AlpnSpec,
    scs: *CurlSslSession,
    do_early_data: *bool,
) callconv(.c) CURLcode;

pub fn Curl_vquic_tls_peer_init(
    origin: ?*CurlPeer,
    peer: ?*CurlPeer,
    sslc: ?*SslFilterConfig,
    ssl_peer: *SslPeer,
) CURLcode {
    var tls_id: [79:0]u8 = @splat(0);
    _ = vtls_backends.vtls_impl.Curl_ssl_version(&tls_id, @sizeOf(@TypeOf(tls_id)));
    if (ssl_peer.origin != null or ssl_peer.peer != null) {
        vtls_backends.vtls_impl.Curl_ssl_peer_cleanup(ssl_peer);
    }
    if (origin == null and peer == null) return CURLE_OK;
    var dummy_sslc = std.mem.zeroes(SslFilterConfig);
    return vtls_backends.vtls_impl.Curl_ssl_peer_init(
        ssl_peer,
        fromOpaque(vtls_scache_asn1.CurlPeer, origin),
        fromOpaque(vtls_scache_asn1.CurlPeer, peer),
        sslc orelse &dummy_sslc,
        &tls_id,
        TRNSPRT_QUIC,
    );
}

/// Initialize QUIC TLS context (`Curl_vquic_tls_init` in `lib/vquic/vquic-tls.c`).
pub fn Curl_vquic_tls_init(
    ctx: *CurlTlsCtx,
    cf: *CurlCfilter,
    data: ?*CurlEasy,
    ssl_peer: *SslPeer,
    alpns: ?*const AlpnSpec,
    cb_setup: ?Curl_vquic_tls_ctx_setup,
    cb_user_data: ?*anyopaque,
    ssl_user_data: ?*anyopaque,
    session_reuse_cb: ?Curl_vquic_session_reuse_cb,
) CURLcode {
    var result: CURLcode = CURLE_OK;
    initVquicTlsInner(ctx, cf, data, ssl_peer, alpns, cb_setup, cb_user_data, ssl_user_data, session_reuse_cb, &result) catch return result;
    return CURLE_OK;
}

fn initVquicTlsInner(
    ctx: *CurlTlsCtx,
    cf: *CurlCfilter,
    data: ?*CurlEasy,
    ssl_peer: *SslPeer,
    alpns: ?*const AlpnSpec,
    cb_setup: ?Curl_vquic_tls_ctx_setup,
    cb_user_data: ?*anyopaque,
    ssl_user_data: ?*anyopaque,
    session_reuse_cb: ?Curl_vquic_session_reuse_cb,
    out_result: *CURLcode,
) error{InitFailed}!void {
    errdefer Curl_vquic_tls_cleanup(ctx);
    const rc: CURLcode = switch (comptime backend_options.ssl) {
        .openssl => blk: {
            if (comptime backend_options.bundled) {
                if (cb_setup) |cb| {
                    break :blk cb(cf, data, cb_user_data);
                }
                break :blk CURLE_OK;
            }
            break :blk ossl_backend.Curl_ossl_ctx_init(
                &ctx.ossl,
                cf,
                data,
                ssl_peer,
                alpns,
                cb_setup,
                cb_user_data,
                null,
                ssl_user_data,
                session_reuse_cb,
            );
        },
        .gnutls => vtls_gtls.Curl_gtls_ctx_init(
            &ctx.gtls,
            cf,
            data,
            ssl_peer,
            alpns,
            cb_setup,
            cb_user_data,
            ssl_user_data,
            fromOpaque(vtls_gtls.CurlGtlsInitSessionReuseCb, session_reuse_cb),
        ),
        .wolfssl => vtls_wolfssl.Curl_wssl_ctx_init(
            &ctx.wssl,
            cf,
            data,
            ssl_peer,
            alpns,
            cb_setup,
            cb_user_data,
            ssl_user_data,
            fromOpaque(vtls_wolfssl.CurlWsslInitSessionReuseCb, session_reuse_cb),
        ),
        else => CURLE_NOT_BUILT_IN,
    };
    if (rc != CURLE_OK) {
        out_result.* = rc;
        return error.InitFailed;
    }
}

/// Clean up QUIC TLS context (`Curl_vquic_tls_cleanup` in `lib/vquic/vquic-tls.c`).
pub fn Curl_vquic_tls_cleanup(ctx: *CurlTlsCtx) void {
    switch (comptime backend_options.ssl) {
        .openssl => {
            if (comptime !backend_options.bundled) {
                ossl_backend.Curl_osslctx_cleanup(&ctx.ossl);
            }
        },
        .gnutls => {
            if (ctx.gtls.session) |s| {
                vtls_gtls.gtls_ext.gnutls_deinit(s);
            }
            vtls_gtls.Curl_gtls_shared_creds_free(&ctx.gtls.shared_creds);
        },
        .wolfssl => {
            if (ctx.wssl.ssl) |s| {
                vtls_wolfssl.wssl_ext.wolfSSL_free(s);
            }
            if (ctx.wssl.ssl_ctx) |c| {
                vtls_wolfssl.wssl_ext.wolfSSL_CTX_free(c);
            }
        },
        else => {},
    }
    ctx.* = .{};
}

/// Set up X.509 trust store before receiving TLS data (`Curl_vquic_tls_before_recv` in `lib/vquic/vquic-tls.c`).
pub fn Curl_vquic_tls_before_recv(
    ctx: *CurlTlsCtx,
    cf: *CurlCfilter,
    data: ?*CurlEasy,
) CURLcode {
    switch (comptime backend_options.ssl) {
        .openssl => {
            if (comptime !backend_options.bundled) {
                if (!ctx.ossl.x509_store_setup()) {
                    if (ctx.ossl.ssl_ctx == null) return CURLE_FAILED_INIT;
                    const result = ossl_backend.Curl_ossl_setup_x509_store(cf, data, &ctx.ossl);
                    if (result != CURLE_OK)
                        return result;
                    ctx.ossl.set_x509_store_setup(true);
                }
            }
        },
        .wolfssl => {
            if (!ctx.wssl.x509_store_setup()) {
                const result = vtls_wolfssl.Curl_wssl_setup_x509_store(cf, data, &ctx.wssl);
                if (result != CURLE_OK)
                    return result;
            }
        },
        .gnutls => {
            if (ctx.gtls.shared_creds) |sc| {
                if (!sc.trust_setup) {
                    const result = vtls_gtls.Curl_gtls_client_trust_setup(cf, data, &ctx.gtls);
                    if (result != CURLE_OK)
                        return result;
                }
            }
        },
        else => {},
    }
    return CURLE_OK;
}

/// Verify peer certificate after QUIC TLS handshake (`Curl_vquic_tls_verify_peer` in `lib/vquic/vquic-tls.c`).
pub fn Curl_vquic_tls_verify_peer(
    ctx: *CurlTlsCtx,
    cf: *CurlCfilter,
    data: ?*CurlEasy,
    peer: *SslPeer,
) CURLcode {
    const conn_config = vtls_backends.vtls_impl.Curl_ssl_cf_get_filter_config(cf) orelse return CURLE_FAILED_INIT;
    var result: CURLcode = CURLE_OK;

    switch (comptime backend_options.ssl) {
        .openssl => {
            if (comptime !backend_options.bundled) {
                result = ossl_backend.Curl_ossl_check_peer_cert(cf, data, &ctx.ossl, peer);
            }
        },
        .gnutls => {
            const easy_ssl = vtls_backends.vtls_impl.Curl_ssl_cf_get_easy_config(cf, data);
            const is_proxy = vtls_backends.vtls_impl.Curl_ssl_cf_is_proxy(cf);
            const pinned_key = vtls_backends.c_ext.Curl_vtls_acc_pinned_pubkey(data, is_proxy);
            result = vtls_gtls.Curl_gtls_verifyserver(
                cf,
                data,
                ctx.gtls.session,
                conn_config,
                easy_ssl,
                peer,
                pinned_key,
            );
        },
        .wolfssl => {
            if (conn_config.verifyhost()) {
                if (ctx.wssl.ssl) |ssl| {
                    const cert = vtls_wolfssl.wssl_ext.wolfSSL_get_peer_certificate(ssl);
                    if (cert == null) {
                        result = CURLE_OUT_OF_MEMORY;
                    } else {
                        defer vtls_wolfssl.wssl_ext.wolfSSL_X509_free(cert);
                        if (peer.sni) |sni| {
                            const sni_len = std.mem.len(sni);
                            if (vtls_wolfssl.wssl_ext.wolfSSL_X509_check_host(cert, sni, sni_len, 0, null) == vtls_wolfssl.WOLFSSL_FAILURE) {
                                result = CURLE_PEER_FAILED_VERIFICATION;
                            }
                        } else if (peer.origin) |orig| {
                            if (vtls_wolfssl.wssl_ext.wolfSSL_X509_check_ip_asc(cert, orig.hostname, 0) == vtls_wolfssl.WOLFSSL_FAILURE) {
                                result = CURLE_PEER_FAILED_VERIFICATION;
                            }
                        }
                    }
                } else {
                    result = CURLE_PEER_FAILED_VERIFICATION;
                }
            }
            if (result == CURLE_OK) {
                result = vtls_wolfssl.Curl_wssl_verify_pinned(cf, data, &ctx.wssl);
            }
        },
        else => {},
    }

    if (result != CURLE_OK) {
        if (peer.scache_key) |skey| {
            var scache: ?*vtls_backends.CurlSslScache = null;
            var has_share_scache = false;
            var trc_feat: ?*vtls_backends.CurlTrcFeat = null;
            vtls_backends.c_ext.Curl_vtls_acc_scache_params(data, &scache, &has_share_scache, &trc_feat);
            vtls_scache_asn1.Curl_ssl_scache_remove_all_zig(cf, data, scache, has_share_scache, null, trc_feat, skey);
        }
    }
    return result;
}

/// Populate `curl_tlssessioninfo` from `CurlTlsCtx` (`Curl_vquic_tls_get_ssl_info` in `lib/vquic/vquic-tls.c`).
pub fn Curl_vquic_tls_get_ssl_info(
    ctx: *CurlTlsCtx,
    give_ssl_ctx: bool,
    info: *vtls_backends.CurlTlsSessionInfo,
) bool {
    switch (comptime backend_options.ssl) {
        .openssl => {
            info.backend = vtls_backends.CURLSSLBACKEND_OPENSSL;
            info.internals = if (give_ssl_ctx) ctx.ossl.ssl_ctx else ctx.ossl.ssl;
            return true;
        },
        .gnutls => {
            info.backend = vtls_backends.CURLSSLBACKEND_GNUTLS;
            info.internals = ctx.gtls.session;
            return true;
        },
        .wolfssl => {
            info.backend = vtls_backends.CURLSSLBACKEND_WOLFSSL;
            info.internals = if (give_ssl_ctx) ctx.wssl.ssl_ctx else ctx.wssl.ssl;
            return true;
        },
        else => return false,
    }
}

pub fn Curl_vquic_report_handshake(
    ctx: *CurlTlsCtx,
    cf: *CurlCfilter,
    data: ?*CurlEasy,
) void {
    _ = cf;
    switch (comptime backend_options.ssl) {
        .openssl => {
            if (comptime !backend_options.bundled) {
                ossl_backend.Curl_ossl_report_handshake(data, &ctx.ossl);
            }
        },
        .gnutls => {
            vtls_gtls.Curl_gtls_report_handshake(data, &ctx.gtls);
        },
        .wolfssl => {
            vtls_wolfssl.Curl_wssl_report_handshake(data, &ctx.wssl);
        },
        else => {},
    }
}

/// Handle TLS handshake completion (`Curl_vquic_tls_on_handshake` in `lib/vquic/vquic-tls.c`).
pub fn Curl_vquic_tls_on_handshake(
    ctx: *CurlTlsCtx,
    cf: *CurlCfilter,
    data: ?*CurlEasy,
    peer: *SslPeer,
    verify_peer: bool,
) CURLcode {
    Curl_vquic_report_handshake(ctx, cf, data);
    return if (verify_peer)
        Curl_vquic_tls_verify_peer(ctx, cf, data, peer)
    else
        CURLE_OK;
}

/// Check if client's key exchange is supported on HRR (`Curl_vquic_tls_is_ke_supported` in `lib/vquic/vquic-tls.c`).
pub fn Curl_vquic_tls_is_ke_supported(
    ctx: *CurlTlsCtx,
    cf: *CurlCfilter,
    data: ?*CurlEasy,
) bool {
    _ = data;
    const conn_config = vtls_backends.vtls_impl.Curl_ssl_cf_get_filter_config(cf) orelse return false;
    if (conn_config.curves == null) {
        // The client used the default curves.
        return true;
    }

    if (comptime (backend_options.ssl == .openssl and !backend_options.bundled)) {
        const ssl = ctx.ossl.ssl orelse return false;
        const SSL_CTRL_GET_SHARED_GROUP: c_int = 93;
        var idx: c_long = 0;
        while (true) : (idx += 1) {
            const group_id = ossl_backend.ossl_ext.SSL_ctrl(ssl, SSL_CTRL_GET_SHARED_GROUP, idx, null);
            if (group_id < 0) break;
            if (group_id == 0) return true;
        }
    }

    return false;
}

// ============================================================================
// Unit Tests
// ============================================================================

test "vquic_ctx_init, vquic_push_blocked_pkt, and vquic_ctx_free" {
    var qctx: CfQuicCtx = .{};
    try std.testing.expectEqual(CURLE_OK, vquic_ctx_init(null, &qctx));
    defer vquic_ctx_free(&qctx);

    try std.testing.expectEqual(CURL_SOCKET_BAD, qctx.sockfd);
    try std.testing.expectEqual(@as(u8, 0), qctx.blocked_pkt_count);
    try std.testing.expectEqual(is_linux, qctx.has_gso);

    const pkt1 = "hello-quic-1";
    const pkt2 = "hello-quic-2";
    vquic_push_blocked_pkt(null, &qctx, pkt1.ptr, pkt1.len, 1200);
    try std.testing.expectEqual(@as(u8, 1), qctx.blocked_pkt_count);
    try std.testing.expectEqual(pkt1.len, qctx.blocked_pkt[0].pktlen);
    try std.testing.expectEqual(@as(usize, 1200), qctx.blocked_pkt[0].gsolen);

    vquic_push_blocked_pkt(null, &qctx, pkt2.ptr, pkt2.len, 600);
    try std.testing.expectEqual(@as(u8, 2), qctx.blocked_pkt_count);
    try std.testing.expectEqual(pkt2.len, qctx.blocked_pkt[1].pktlen);
    try std.testing.expectEqual(@as(usize, 600), qctx.blocked_pkt[1].gsolen);

    const heap_qctx = mem.create(CfQuicCtx) orelse return error.OutOfMemory;
    try std.testing.expectEqual(CURLE_OK, vquic_ctx_init(null, heap_qctx));
    vquic_ctx_free(heap_qctx);
    mem.destroy(heap_qctx);
}

test "Curl_qlogdir creates sqlog file when QLOGDIR is set" {
    if (is_windows) return;

    const c_env = struct {
        extern "c" fn setenv(name: [*:0]const u8, value: [*:0]const u8, overwrite: c_int) c_int;
        extern "c" fn unsetenv(name: [*:0]const u8) c_int;
        extern "c" fn mkdir(path: [*:0]const u8, mode: c_uint) c_int;
        extern "c" fn unlink(path: [*:0]const u8) c_int;
        extern "c" fn rmdir(path: [*:0]const u8) c_int;
        extern "c" fn access(path: [*:0]const u8, mode: c_int) c_int;
    };

    const qlog_dir_path = ".zig-cache/curl-qlog-test";
    const expected_file = ".zig-cache/curl-qlog-test/deadbeef.sqlog";
    _ = c_env.mkdir(".zig-cache", 0o755);
    _ = c_env.unlink(expected_file);
    _ = c_env.mkdir(qlog_dir_path, 0o755);
    defer {
        _ = c_env.unlink(expected_file);
        _ = c_env.rmdir(qlog_dir_path);
    }

    _ = c_env.setenv("QLOGDIR", qlog_dir_path, 1);
    defer _ = c_env.unsetenv("QLOGDIR");

    const scid = [_]u8{ 0xde, 0xad, 0xbe, 0xef };
    var qlogfd: c_int = -1;
    Curl_qlogdir(null, &scid, scid.len, &qlogfd);
    defer if (qlogfd != -1) {
        _ = std.c.close(qlogfd);
    };

    try std.testing.expect(qlogfd >= 0);
    try std.testing.expectEqual(@as(c_int, 0), c_env.access(expected_file, 0));
}

test "Curl_vquic_h3_err_str maps standard and RFC 9114 reserved HTTP/3 error codes" {
    try std.testing.expectEqualStrings("NO_ERROR", std.mem.span(Curl_vquic_h3_err_str(0x0100)));
    try std.testing.expectEqualStrings("GENERAL_PROTOCOL_ERROR", std.mem.span(Curl_vquic_h3_err_str(0x0101)));
    try std.testing.expectEqualStrings("VERSION_FALLBACK", std.mem.span(Curl_vquic_h3_err_str(0x0110)));
    try std.testing.expectEqualStrings("NO_ERROR", std.mem.span(Curl_vquic_h3_err_str(0x21)));
    try std.testing.expectEqualStrings("NO_ERROR", std.mem.span(Curl_vquic_h3_err_str(0x40)));
    try std.testing.expectEqualStrings("unknown", std.mem.span(Curl_vquic_h3_err_str(0x22)));
}

test "Curl_quic_ver formats version string when QUIC backend enabled" {
    var buf: [80]u8 = @splat(0);
    Curl_quic_ver(&buf, buf.len);
    const ver = std.mem.sliceTo(&buf, 0);
    switch (backend_options.quic) {
        .ngtcp2 => {
            try std.testing.expect(std.mem.indexOf(u8, ver, "ngtcp2/") != null);
            try std.testing.expect(std.mem.indexOf(u8, ver, "nghttp3/") != null);
        },
        .quiche => {
            try std.testing.expect(std.mem.indexOf(u8, ver, "quiche/") != null);
        },
        .none => {
            try std.testing.expectEqual(@as(usize, 0), ver.len);
        },
    }
}
