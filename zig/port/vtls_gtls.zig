const std = @import("std");
const backend_options = @import("backend_options");
const vtls_backends = @import("vtls_backends.zig");
const vtls_impl = vtls_backends.vtls_impl;
const c_ext = vtls_backends.c_ext;

pub const use_gnutls = backend_options.ssl == .gnutls;

pub const Sha256Ctx = extern struct {
    state: [8]u32,
    count: u64,
    index: c_uint,
    block: [64]u8,
};

pub const gtls_ext = struct {
    pub extern fn gnutls_global_init() callconv(.c) c_int;
    pub extern fn gnutls_global_deinit() callconv(.c) void;
    pub extern fn gnutls_check_version(req_version: ?[*:0]const u8) callconv(.c) ?[*:0]const u8;
    pub extern fn gnutls_rnd(level: c_uint, data: *anyopaque, len: usize) callconv(.c) c_int;
    pub extern fn nettle_sha256_init(ctx: *Sha256Ctx) callconv(.c) void;
    pub extern fn nettle_sha256_update(ctx: *Sha256Ctx, length: usize, data: [*]const u8) callconv(.c) void;
    pub extern fn nettle_sha256_digest(ctx: *Sha256Ctx, length: usize, digest: [*]u8) callconv(.c) void;
};

pub const GtlsSslBackendData = extern struct {
    session: ?*anyopaque = null,
    cred: ?*anyopaque = null,
    shared_creds: ?*anyopaque = null,
    srp_client_cred: ?*anyopaque = null,
    io_result: c_int = 0,
    sent_shutdown: bool = false,
};

fn gtlsInit() callconv(.c) c_int {
    if (comptime use_gnutls) {
        return if (gtls_ext.gnutls_global_init() == 0) 1 else 0;
    }
    return 0;
}

fn gtlsCleanup() callconv(.c) void {
    if (comptime use_gnutls) {
        gtls_ext.gnutls_global_deinit();
    }
}

fn gtlsVersion(buffer: [*]u8, size: usize) callconv(.c) usize {
    if (comptime use_gnutls) {
        const ver = gtls_ext.gnutls_check_version(null) orelse "";
        const n = c_ext.curl_msnprintf(buffer, size, "GnuTLS/%s", ver);
        return if (n > 0) @intCast(n) else 0;
    }
    return 0;
}

fn gtlsShutdown(
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

fn gtlsDataPending(cf: *vtls_impl.CurlCfilter, data: ?*const vtls_impl.CurlEasy) callconv(.c) bool {
    _ = cf;
    _ = data;
    return false;
}

fn gtlsRandom(
    data: ?*vtls_impl.CurlEasy,
    entropy: [*]u8,
    length: usize,
) callconv(.c) vtls_impl.CURLcode {
    _ = data;
    if (comptime use_gnutls) {
        const rc = gtls_ext.gnutls_rnd(1, entropy, length);
        return if (rc == 0) vtls_impl.CURLE_OK else vtls_impl.CURLE_FAILED_INIT;
    }
    return vtls_impl.CURLE_NOT_BUILT_IN;
}

fn gtlsCertStatusRequest() callconv(.c) bool {
    return true;
}

fn gtlsConnect(
    cf: *vtls_impl.CurlCfilter,
    data: ?*vtls_impl.CurlEasy,
    done: *bool,
) callconv(.c) vtls_impl.CURLcode {
    _ = cf;
    _ = data;
    done.* = false;
    return vtls_impl.CURLE_SSL_CONNECT_ERROR;
}

fn gtlsGetInternals(connssl: *vtls_impl.SslConnectData, info: c_uint) callconv(.c) ?*anyopaque {
    _ = info;
    const backend: *GtlsSslBackendData = @ptrCast(@alignCast(connssl.backend orelse return null));
    return backend.session;
}

fn gtlsClose(cf: *vtls_impl.CurlCfilter, data: ?*vtls_impl.CurlEasy) callconv(.c) void {
    _ = cf;
    _ = data;
}

fn gtlsSha256sum(
    input: ?[*]const u8,
    inputlen: usize,
    sha256sum: [*]u8,
    sha256len: usize,
) callconv(.c) vtls_impl.CURLcode {
    if (comptime use_gnutls) {
        var ctx: Sha256Ctx = std.mem.zeroes(Sha256Ctx);
        gtls_ext.nettle_sha256_init(&ctx);
        if (input) |in_ptr| {
            if (inputlen > 0) {
                gtls_ext.nettle_sha256_update(&ctx, inputlen, in_ptr);
            }
        }
        gtls_ext.nettle_sha256_digest(&ctx, sha256len, sha256sum);
        return vtls_impl.CURLE_OK;
    }
    return vtls_impl.CURLE_NOT_BUILT_IN;
}

fn gtlsRecv(
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

fn gtlsSend(
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

pub const Curl_ssl_gnutls = vtls_impl.CurlSsl{
    .info = .{
        .id = vtls_impl.CURLSSLBACKEND_GNUTLS,
        .name = "gnutls",
    },
    .supports = vtls_impl.SSLSUPP_CA_PATH |
        vtls_impl.SSLSUPP_CERTINFO |
        vtls_impl.SSLSUPP_PINNEDPUBKEY |
        vtls_impl.SSLSUPP_HTTPS_PROXY |
        vtls_impl.SSLSUPP_CAINFO_BLOB |
        vtls_impl.SSLSUPP_CIPHER_LIST |
        vtls_impl.SSLSUPP_CA_CACHE |
        vtls_impl.SSLSUPP_ISSUERCERT |
        vtls_impl.SSLSUPP_CRLFILE,
    .sizeof_ssl_backend_data = @sizeOf(GtlsSslBackendData),
    .init = gtlsInit,
    .cleanup = gtlsCleanup,
    .version = gtlsVersion,
    .shut_down = gtlsShutdown,
    .data_pending = gtlsDataPending,
    .random = gtlsRandom,
    .cert_status_request = gtlsCertStatusRequest,
    .do_connect = gtlsConnect,
    .adjust_pollset = vtls_impl.Curl_ssl_adjust_pollset,
    .get_internals = gtlsGetInternals,
    .close = gtlsClose,
    .close_all = null,
    .engines_list = null,
    .sha256sum = gtlsSha256sum,
    .recv_plain = gtlsRecv,
    .send_plain = gtlsSend,
    .get_channel_binding = null,
};

comptime {
    if (use_gnutls) {
        @export(&Curl_ssl_gnutls, .{ .name = "Curl_ssl_gnutls" });
    }
}
