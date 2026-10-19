const backend_options = @import("backend_options");
const vtls_backends = @import("vtls_backends.zig");
const vtls_impl = vtls_backends.vtls_impl;
const c_ext = vtls_backends.c_ext;

pub const use_rustls = backend_options.ssl == .rustls;

pub const RustlsStr = extern struct {
    data: ?[*]const u8,
    len: usize,
};

pub const RUSTLS_RESULT_OK: u32 = 7000;

pub const rustls_ext = struct {
    pub extern fn rustls_version() callconv(.c) RustlsStr;
    pub extern fn rustls_default_crypto_provider_random(buf: [*]u8, len: usize) callconv(.c) u32;
};

pub const RustlsSslBackendData = extern struct {
    config: ?*const anyopaque = null,
    conn: ?*anyopaque = null,
    plain_out_buffered: usize = 0,
    data_in_pending: bool = false,
    sent_shutdown: bool = false,
};

fn crVersion(buffer: [*]u8, size: usize) callconv(.c) usize {
    if (comptime use_rustls) {
        const ver = rustls_ext.rustls_version();
        const ptr = ver.data orelse "";
        const n = c_ext.curl_msnprintf(buffer, size, "%.*s", @as(c_int, @intCast(ver.len)), ptr);
        return if (n > 0) @intCast(n) else 0;
    }
    return 0;
}

fn crShutdown(
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

fn crDataPending(cf: *vtls_impl.CurlCfilter, data: ?*const vtls_impl.CurlEasy) callconv(.c) bool {
    _ = cf;
    _ = data;
    return false;
}

fn crRandom(
    data: ?*vtls_impl.CurlEasy,
    entropy: [*]u8,
    length: usize,
) callconv(.c) vtls_impl.CURLcode {
    _ = data;
    if (comptime use_rustls) {
        const rr = rustls_ext.rustls_default_crypto_provider_random(entropy, length);
        return if (rr == RUSTLS_RESULT_OK) vtls_impl.CURLE_OK else vtls_impl.CURLE_FAILED_INIT;
    }
    return vtls_impl.CURLE_NOT_BUILT_IN;
}

fn crConnect(
    cf: *vtls_impl.CurlCfilter,
    data: ?*vtls_impl.CurlEasy,
    done: *bool,
) callconv(.c) vtls_impl.CURLcode {
    _ = cf;
    _ = data;
    done.* = false;
    return vtls_impl.CURLE_SSL_CONNECT_ERROR;
}

fn crGetInternals(connssl: *vtls_impl.SslConnectData, info: c_uint) callconv(.c) ?*anyopaque {
    if (info != vtls_impl.CURLINFO_TLS_SSL_PTR) return null;
    const backend: *RustlsSslBackendData = @ptrCast(@alignCast(connssl.backend orelse return null));
    return backend.conn;
}

fn crClose(cf: *vtls_impl.CurlCfilter, data: ?*vtls_impl.CurlEasy) callconv(.c) void {
    _ = cf;
    _ = data;
}

fn crRecv(
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

fn crSend(
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

pub const Curl_ssl_rustls = vtls_impl.CurlSsl{
    .info = .{
        .id = vtls_impl.CURLSSLBACKEND_RUSTLS,
        .name = "rustls",
    },
    .supports = vtls_impl.SSLSUPP_CAINFO_BLOB |
        vtls_impl.SSLSUPP_HTTPS_PROXY |
        vtls_impl.SSLSUPP_CIPHER_LIST |
        vtls_impl.SSLSUPP_TLS13_CIPHERSUITES |
        vtls_impl.SSLSUPP_CERTINFO |
        vtls_impl.SSLSUPP_CRLFILE,
    .sizeof_ssl_backend_data = @sizeOf(RustlsSslBackendData),
    .init = null,
    .cleanup = null,
    .version = crVersion,
    .shut_down = crShutdown,
    .data_pending = crDataPending,
    .random = crRandom,
    .cert_status_request = null,
    .do_connect = crConnect,
    .adjust_pollset = vtls_impl.Curl_ssl_adjust_pollset,
    .get_internals = crGetInternals,
    .close = crClose,
    .close_all = null,
    .engines_list = null,
    .sha256sum = null,
    .recv_plain = crRecv,
    .send_plain = crSend,
    .get_channel_binding = null,
};

comptime {
    if (use_rustls) {
        @export(&Curl_ssl_rustls, .{ .name = "Curl_ssl_rustls" });
    }
}
