const std = @import("std");
const backend_options = @import("backend_options");
const vtls_backends = @import("vtls_backends.zig");
const vtls_impl = vtls_backends.vtls_impl;
const c_ext = vtls_backends.c_ext;

pub const use_wolfssl = backend_options.ssl == .wolfssl;

pub const WOLFSSL_SUCCESS: c_int = 1;

pub const wssl_ext = struct {
    pub extern fn wolfSSL_Init() callconv(.c) c_int;
    pub extern fn wolfSSL_Cleanup() callconv(.c) c_int;
    pub extern fn wolfSSL_lib_version() callconv(.c) ?[*:0]const u8;
    pub extern fn wc_InitRng(rng: *anyopaque) callconv(.c) c_int;
    pub extern fn wc_RNG_GenerateBlock(rng: *anyopaque, output: [*]u8, sz: c_uint) callconv(.c) c_int;
    pub extern fn wc_FreeRng(rng: *anyopaque) callconv(.c) c_int;
    pub extern fn wc_InitSha256(sha: *anyopaque) callconv(.c) c_int;
    pub extern fn wc_Sha256Update(sha: *anyopaque, data: ?[*]const u8, len: u32) callconv(.c) c_int;
    pub extern fn wc_Sha256Final(sha: *anyopaque, hash: [*]u8) callconv(.c) c_int;
};

pub const WsslSslBackendData = extern struct {
    ssl_ctx: ?*anyopaque = null,
    ssl: ?*anyopaque = null,
    io_result: c_int = 0,
    io_flags: u8 = 0,
};

pub fn Curl_wssl_setup_x509_store(
    cf: *vtls_impl.CurlCfilter,
    data: ?*vtls_impl.CurlEasy,
    ssl_ctx: ?*anyopaque,
) callconv(.c) vtls_impl.CURLcode {
    _ = cf;
    _ = data;
    _ = ssl_ctx;
    return vtls_impl.CURLE_OK;
}

fn wsslInit() callconv(.c) c_int {
    if (comptime use_wolfssl) {
        return if (wssl_ext.wolfSSL_Init() == WOLFSSL_SUCCESS) 1 else 0;
    }
    return 0;
}

fn wsslCleanup() callconv(.c) void {
    if (comptime use_wolfssl) {
        _ = wssl_ext.wolfSSL_Cleanup();
    }
}

fn wsslVersion(buffer: [*]u8, size: usize) callconv(.c) usize {
    if (comptime use_wolfssl) {
        const ver = wssl_ext.wolfSSL_lib_version() orelse "";
        const n = c_ext.curl_msnprintf(buffer, size, "wolfSSL/%s", ver);
        return if (n > 0) @intCast(n) else 0;
    }
    return 0;
}

fn wsslShutdown(
    cf: *vtls_impl.CurlCfilter,
    data: ?*vtls_impl.CurlEasy,
    send_shutdown: bool,
    done: *bool,
) callconv(.c) vtls_impl.CURLcode {
    _ = cf;
    _ = data;
    _ = send_shutdown;
    done.* = true;
    return vtls_impl.CURLE_OK;
}

fn wsslDataPending(cf: *vtls_impl.CurlCfilter, data: ?*const vtls_impl.CurlEasy) callconv(.c) bool {
    _ = cf;
    _ = data;
    return false;
}

fn wsslRandom(
    data: ?*vtls_impl.CurlEasy,
    entropy: [*]u8,
    length: usize,
) callconv(.c) vtls_impl.CURLcode {
    _ = data;
    if (comptime use_wolfssl) {
        var rng_buf: [512]u8 align(16) = std.mem.zeroes([512]u8);
        if (wssl_ext.wc_InitRng(&rng_buf) != 0) {
            return vtls_impl.CURLE_FAILED_INIT;
        }
        defer _ = wssl_ext.wc_FreeRng(&rng_buf);
        if (length > std.math.maxInt(c_uint)) {
            return vtls_impl.CURLE_FAILED_INIT;
        }
        if (wssl_ext.wc_RNG_GenerateBlock(&rng_buf, entropy, @intCast(length)) != 0) {
            return vtls_impl.CURLE_FAILED_INIT;
        }
        return vtls_impl.CURLE_OK;
    }
    return vtls_impl.CURLE_NOT_BUILT_IN;
}

fn wsslConnect(
    cf: *vtls_impl.CurlCfilter,
    data: ?*vtls_impl.CurlEasy,
    done: *bool,
) callconv(.c) vtls_impl.CURLcode {
    _ = cf;
    _ = data;
    done.* = false;
    return vtls_impl.CURLE_SSL_CONNECT_ERROR;
}

fn wsslGetInternals(connssl: *vtls_impl.SslConnectData, info: c_uint) callconv(.c) ?*anyopaque {
    const backend: *WsslSslBackendData = @ptrCast(@alignCast(connssl.backend orelse return null));
    return if (info == vtls_impl.CURLINFO_TLS_SESSION) backend.ssl_ctx else backend.ssl;
}

fn wsslClose(cf: *vtls_impl.CurlCfilter, data: ?*vtls_impl.CurlEasy) callconv(.c) void {
    _ = cf;
    _ = data;
}

fn wsslSha256sum(
    input: ?[*]const u8,
    inputlen: usize,
    sha256sum: [*]u8,
    sha256len: usize,
) callconv(.c) vtls_impl.CURLcode {
    _ = sha256len;
    if (comptime use_wolfssl) {
        var sha_buf: [512]u8 align(16) = std.mem.zeroes([512]u8);
        if (wssl_ext.wc_InitSha256(&sha_buf) != 0) {
            return vtls_impl.CURLE_FAILED_INIT;
        }
        if (wssl_ext.wc_Sha256Update(&sha_buf, input, @intCast(inputlen)) != 0) {
            return vtls_impl.CURLE_FAILED_INIT;
        }
        if (wssl_ext.wc_Sha256Final(&sha_buf, sha256sum) != 0) {
            return vtls_impl.CURLE_FAILED_INIT;
        }
        return vtls_impl.CURLE_OK;
    }
    return vtls_impl.CURLE_NOT_BUILT_IN;
}

fn wsslRecv(
    cf: *vtls_impl.CurlCfilter,
    data: ?*vtls_impl.CurlEasy,
    buf: [*]u8,
    len: usize,
    pnread: *usize,
) callconv(.c) vtls_impl.CURLcode {
    _ = cf;
    _ = data;
    _ = buf;
    _ = len;
    pnread.* = 0;
    return vtls_impl.CURLE_RECV_ERROR;
}

fn wsslSend(
    cf: *vtls_impl.CurlCfilter,
    data: ?*vtls_impl.CurlEasy,
    mem_ptr: ?*const anyopaque,
    len: usize,
    pnwritten: *usize,
) callconv(.c) vtls_impl.CURLcode {
    _ = cf;
    _ = data;
    _ = mem_ptr;
    _ = len;
    pnwritten.* = 0;
    return vtls_impl.CURLE_SEND_ERROR;
}

pub const Curl_ssl_wolfssl = vtls_impl.CurlSsl{
    .info = .{
        .id = vtls_impl.CURLSSLBACKEND_WOLFSSL,
        .name = "wolfssl",
    },
    .supports = vtls_impl.SSLSUPP_PINNEDPUBKEY |
        vtls_impl.SSLSUPP_HTTPS_PROXY |
        vtls_impl.SSLSUPP_CA_PATH |
        vtls_impl.SSLSUPP_CAINFO_BLOB |
        vtls_impl.SSLSUPP_SSL_CTX |
        vtls_impl.SSLSUPP_TLS13_CIPHERSUITES |
        vtls_impl.SSLSUPP_CA_CACHE |
        vtls_impl.SSLSUPP_CIPHER_LIST |
        vtls_impl.SSLSUPP_SSL_EC_CURVES,
    .sizeof_ssl_backend_data = @sizeOf(WsslSslBackendData),
    .init = wsslInit,
    .cleanup = wsslCleanup,
    .version = wsslVersion,
    .shut_down = wsslShutdown,
    .data_pending = wsslDataPending,
    .random = wsslRandom,
    .cert_status_request = null,
    .do_connect = wsslConnect,
    .adjust_pollset = vtls_impl.Curl_ssl_adjust_pollset,
    .get_internals = wsslGetInternals,
    .close = wsslClose,
    .close_all = null,
    .engines_list = null,
    .sha256sum = wsslSha256sum,
    .recv_plain = wsslRecv,
    .send_plain = wsslSend,
    .get_channel_binding = null,
};

comptime {
    if (use_wolfssl) {
        @export(&Curl_ssl_wolfssl, .{ .name = "Curl_ssl_wolfssl" });
        @export(&Curl_wssl_setup_x509_store, .{ .name = "Curl_wssl_setup_x509_store" });
    }
}
