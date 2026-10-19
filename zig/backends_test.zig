const std = @import("std");
const builtin = @import("builtin");
const testing = std.testing;
const backend_options = @import("backend_options");
const backends = @import("backends.zig");

const c = struct {
    pub const CURLversion = c_uint;
    pub const CURLVERSION_TWELFTH: CURLversion = 11;
    pub const CURLVERSION_NOW: CURLversion = CURLVERSION_TWELFTH;

    pub const CURL_VERSION_IPV6: c_int = 1 << 0;
    pub const CURL_VERSION_SSL: c_int = 1 << 2;
    pub const CURL_VERSION_LIBZ: c_int = 1 << 3;
    pub const CURL_VERSION_NTLM: c_int = 1 << 4;
    pub const CURL_VERSION_ASYNCHDNS: c_int = 1 << 7;
    pub const CURL_VERSION_SPNEGO: c_int = 1 << 8;
    pub const CURL_VERSION_LARGEFILE: c_int = 1 << 9;
    pub const CURL_VERSION_IDN: c_int = 1 << 10;
    pub const CURL_VERSION_SSPI: c_int = 1 << 11;
    pub const CURL_VERSION_HTTP2: c_int = 1 << 16;
    pub const CURL_VERSION_GSSAPI: c_int = 1 << 17;
    pub const CURL_VERSION_KERBEROS5: c_int = 1 << 18;
    pub const CURL_VERSION_UNIX_SOCKETS: c_int = 1 << 19;
    pub const CURL_VERSION_PSL: c_int = 1 << 20;
    pub const CURL_VERSION_HTTPS_PROXY: c_int = 1 << 21;
    pub const CURL_VERSION_MULTI_SSL: c_int = 1 << 22;
    pub const CURL_VERSION_BROTLI: c_int = 1 << 23;
    pub const CURL_VERSION_ALTSVC: c_int = 1 << 24;
    pub const CURL_VERSION_HTTP3: c_int = 1 << 25;
    pub const CURL_VERSION_ZSTD: c_int = 1 << 26;
    pub const CURL_VERSION_UNICODE: c_int = 1 << 27;
    pub const CURL_VERSION_HSTS: c_int = 1 << 28;
    pub const CURL_VERSION_GSASL: c_int = 1 << 29;
    pub const CURL_VERSION_THREADSAFE: c_int = 1 << 30;

    pub const curl_version_info_data = extern struct {
        age: CURLversion,
        version: ?[*:0]const u8,
        version_num: c_uint,
        host: ?[*:0]const u8,
        features: c_int,
        ssl_version: ?[*:0]const u8,
        ssl_version_num: c_long,
        libz_version: ?[*:0]const u8,
        protocols: ?[*:null]const ?[*:0]const u8,
        ares: ?[*:0]const u8,
        ares_num: c_int,
        libidn: ?[*:0]const u8,
        iconv_ver_num: c_int,
        libssh_version: ?[*:0]const u8,
        brotli_ver_num: c_uint,
        brotli_version: ?[*:0]const u8,
        nghttp2_ver_num: c_uint,
        nghttp2_version: ?[*:0]const u8,
        quic_version: ?[*:0]const u8,
        cainfo: ?[*:0]const u8,
        capath: ?[*:0]const u8,
        zstd_ver_num: c_uint,
        zstd_version: ?[*:0]const u8,
        hyper_version: ?[*:0]const u8,
        gsasl_version: ?[*:0]const u8,
        feature_names: ?[*:null]const ?[*:0]const u8,
        rtmp_version: ?[*:0]const u8,
    };
};

extern fn curl_version_info(stamp: c.CURLversion) ?*const c.curl_version_info_data;

test "curl_version_info feature bits match backend_options" {
    const info = curl_version_info(c.CURLVERSION_NOW) orelse return error.NullVersionInfo;

    try testing.expect((info.*.features & c.CURL_VERSION_ZSTD != 0) == backend_options.zstd);
    try testing.expect((info.*.features & c.CURL_VERSION_LIBZ != 0) == backend_options.zlib);
    try testing.expect((info.*.features & c.CURL_VERSION_SSL != 0) == (backend_options.ssl != .none));
    try testing.expect((info.*.features & c.CURL_VERSION_HTTP2 != 0) == backend_options.nghttp2);
    try testing.expect((info.*.features & c.CURL_VERSION_HSTS != 0) == (backend_options.ssl != .none));
    try testing.expect((info.*.features & c.CURL_VERSION_SSPI != 0) == (backend_options.ssl == .schannel));

    if (backend_options.zstd) {
        try testing.expect(info.*.zstd_version != null);
        try testing.expect(info.*.zstd_ver_num != 0);
    }
    if (backend_options.zlib) {
        try testing.expect(info.*.libz_version != null);
    }
    if (backend_options.ssl != .none) {
        try testing.expect(info.*.ssl_version != null);
    }
    if (backend_options.nghttp2) {
        try testing.expect(info.*.nghttp2_version != null);
        try testing.expect(info.*.nghttp2_ver_num != 0);
    }

    const expect_apple_sectrust = backend_options.apple_sectrust orelse
        (backend_options.ssl == .openssl and builtin.os.tag.isDarwin());
    var found_apple_sectrust = false;
    if (info.*.feature_names) |names| {
        var idx: usize = 0;
        while (names[idx]) |feat_name| : (idx += 1) {
            if (std.mem.eql(u8, std.mem.span(feat_name), "AppleSecTrust")) {
                found_apple_sectrust = true;
            }
        }
    }
    try testing.expectEqual(backend_options.ssl != .none and expect_apple_sectrust, found_apple_sectrust);
}

test "SslBackend and Apple SecTrust target validation" {
    try testing.expectEqual(@as(usize, 4), std.enums.values(backends.SslBackend).len);

    const default_openssl = backends.Options{ .ssl = .openssl };
    try testing.expect(default_openssl.useAppleSectrust(.macos));
    try testing.expect(!default_openssl.useAppleSectrust(.linux));
    try testing.expect(default_openssl.isValidForTarget(.macos));
    try testing.expect(default_openssl.isValidForTarget(.linux));

    const disabled_sectrust = backends.Options{ .ssl = .openssl, .apple_sectrust = false };
    try testing.expect(!disabled_sectrust.useAppleSectrust(.macos));
    try testing.expect(disabled_sectrust.isValidForTarget(.macos));

    const invalid_sectrust_os = backends.Options{ .ssl = .openssl, .apple_sectrust = true };
    try testing.expect(invalid_sectrust_os.isValidForTarget(.macos));
    try testing.expect(!invalid_sectrust_os.isValidForTarget(.linux));

    const invalid_sectrust_backend = backends.Options{ .ssl = .mbedtls, .apple_sectrust = true };
    try testing.expect(!invalid_sectrust_backend.isValidForTarget(.macos));

    const schannel_opts = backends.Options{ .ssl = .schannel };
    try testing.expect(schannel_opts.isValidForTarget(.windows));
    try testing.expect(!schannel_opts.isValidForTarget(.linux));
    try testing.expect(!schannel_opts.isValidForTarget(.macos));
}
