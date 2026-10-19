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

    pub const CURLcode = c_uint;
    pub const CURLE_OK: CURLcode = 0;
    pub const CURLE_NOT_BUILT_IN: CURLcode = 4;
    pub const CURLE_UNKNOWN_OPTION: CURLcode = 48;
    pub const CURLE_PEER_FAILED_VERIFICATION: CURLcode = 60;
    pub const CURLE_SSL_PINNEDPUBKEYNOTMATCH: CURLcode = 90;

    pub const CURLsslset = c_uint;
    pub const CURLSSLSET_OK: CURLsslset = 0;
    pub const CURLSSLSET_UNKNOWN_BACKEND: CURLsslset = 1;
    pub const CURLSSLSET_TOO_LATE: CURLsslset = 2;
    pub const CURLSSLSET_NO_BACKENDS: CURLsslset = 3;

    pub const CURLSSLBACKEND_NONE: c_uint = 0;
    pub const CURLSSLBACKEND_OPENSSL: c_uint = 1;
    pub const CURLSSLBACKEND_GNUTLS: c_uint = 2;
    pub const CURLSSLBACKEND_WOLFSSL: c_uint = 7;
    pub const CURLSSLBACKEND_SCHANNEL: c_uint = 8;
    pub const CURLSSLBACKEND_MBEDTLS: c_uint = 11;
    pub const CURLSSLBACKEND_RUSTLS: c_uint = 14;

    pub const curl_ssl_backend = extern struct {
        id: c_uint,
        name: [*:0]const u8,
    };

    pub const SSLSUPP_CA_PATH: c_uint = 1 << 0;
    pub const SSLSUPP_CERTINFO: c_uint = 1 << 1;
    pub const SSLSUPP_PINNEDPUBKEY: c_uint = 1 << 2;
    pub const SSLSUPP_SSL_CTX: c_uint = 1 << 3;
    pub const SSLSUPP_HTTPS_PROXY: c_uint = 1 << 4;
    pub const SSLSUPP_TLS13_CIPHERSUITES: c_uint = 1 << 5;
    pub const SSLSUPP_CAINFO_BLOB: c_uint = 1 << 6;
    pub const SSLSUPP_CA_CACHE: c_uint = 1 << 8;
    pub const SSLSUPP_CIPHER_LIST: c_uint = 1 << 9;
    pub const SSLSUPP_SIGNATURE_ALGORITHMS: c_uint = 1 << 10;
    pub const SSLSUPP_ISSUERCERT: c_uint = 1 << 11;
    pub const SSLSUPP_SSL_EC_CURVES: c_uint = 1 << 12;
    pub const SSLSUPP_CRLFILE: c_uint = 1 << 13;
    pub const SSLSUPP_ISSUERCERT_BLOB: c_uint = 1 << 14;

    pub const CURLoption = c_uint;
    pub const CURLOPTTYPE_LONG: CURLoption = 0;
    pub const CURLOPTTYPE_OBJECTPOINT: CURLoption = 10000;
    pub const CURLOPTTYPE_FUNCTIONPOINT: CURLoption = 20000;
    pub const CURLOPTTYPE_BLOB: CURLoption = 40000;

    pub const CURLOPT_WRITEDATA: CURLoption = CURLOPTTYPE_OBJECTPOINT + 1;
    pub const CURLOPT_URL: CURLoption = CURLOPTTYPE_OBJECTPOINT + 2;
    pub const CURLOPT_SSL_VERIFYPEER: CURLoption = CURLOPTTYPE_LONG + 64;
    pub const CURLOPT_CAINFO: CURLoption = CURLOPTTYPE_OBJECTPOINT + 65;
    pub const CURLOPT_SSL_VERIFYHOST: CURLoption = CURLOPTTYPE_LONG + 81;
    pub const CURLOPT_SSL_CIPHER_LIST: CURLoption = CURLOPTTYPE_OBJECTPOINT + 83;
    pub const CURLOPT_NOSIGNAL: CURLoption = CURLOPTTYPE_LONG + 99;
    pub const CURLOPT_TIMEOUT_MS: CURLoption = CURLOPTTYPE_LONG + 155;
    pub const CURLOPT_CRLFILE: CURLoption = CURLOPTTYPE_OBJECTPOINT + 169;
    pub const CURLOPT_ISSUERCERT: CURLoption = CURLOPTTYPE_OBJECTPOINT + 170;
    pub const CURLOPT_CERTINFO: CURLoption = CURLOPTTYPE_LONG + 172;
    pub const CURLOPT_RESOLVE: CURLoption = CURLOPTTYPE_OBJECTPOINT + 203;
    pub const CURLOPT_PINNEDPUBLICKEY: CURLoption = CURLOPTTYPE_OBJECTPOINT + 230;
    pub const CURLOPT_TLS13_CIPHERS: CURLoption = CURLOPTTYPE_OBJECTPOINT + 276;
    pub const CURLOPT_SSL_EC_CURVES: CURLoption = CURLOPTTYPE_OBJECTPOINT + 298;
    pub const CURLOPT_CAINFO_BLOB: CURLoption = CURLOPTTYPE_BLOB + 309;
    pub const CURLOPT_SSL_SIGNATURE_ALGORITHMS: CURLoption = CURLOPTTYPE_OBJECTPOINT + 328;
    pub const CURLOPT_WRITEFUNCTION: CURLoption = CURLOPTTYPE_FUNCTIONPOINT + 11;

    pub const CURLINFO = c_uint;
    pub const CURLINFO_LONG: CURLINFO = 0x200000;
    pub const CURLINFO_SLIST: CURLINFO = 0x400000;
    pub const CURLINFO_PTR: CURLINFO = 0x400000;
    pub const CURLINFO_RESPONSE_CODE: CURLINFO = CURLINFO_LONG + 2;
    pub const CURLINFO_CERTINFO: CURLINFO = CURLINFO_SLIST + 34;
    pub const CURLINFO_TLS_SESSION: CURLINFO = CURLINFO_PTR + 43;
    pub const CURLINFO_TLS_SSL_PTR: CURLINFO = CURLINFO_PTR + 45;

    pub const curl_tlssessioninfo = extern struct {
        backend: c_uint,
        internals: ?*anyopaque,
    };

    pub const CURL_BLOB_COPY: c_uint = 1;
    pub const curl_blob = extern struct {
        data: ?*anyopaque,
        len: usize,
        flags: c_uint,
    };

    pub const curl_slist = extern struct {
        data: ?[*:0]u8,
        next: ?*curl_slist,
    };

    pub const curl_certinfo = extern struct {
        num_of_certs: c_int,
        certinfo: ?[*]?*curl_slist,
    };
};

extern fn curl_version_info(stamp: c.CURLversion) ?*const c.curl_version_info_data;
extern fn curl_global_sslset(
    id: c_uint,
    name: ?[*:0]const u8,
    avail: ?*?[*:null]const ?*const c.curl_ssl_backend,
) callconv(.c) c.CURLsslset;
extern fn curl_easy_init() callconv(.c) ?*anyopaque;
extern fn curl_easy_cleanup(handle: ?*anyopaque) callconv(.c) void;
extern fn curl_easy_setopt(handle: ?*anyopaque, option: c.CURLoption, ...) callconv(.c) c.CURLcode;
extern fn curl_easy_perform(handle: ?*anyopaque) callconv(.c) c.CURLcode;
extern fn curl_easy_getinfo(handle: ?*anyopaque, info: c.CURLINFO, ...) callconv(.c) c.CURLcode;
extern fn curl_slist_append(list: ?*c.curl_slist, data: [*:0]const u8) callconv(.c) ?*c.curl_slist;
extern fn curl_slist_free_all(list: ?*c.curl_slist) callconv(.c) void;
extern fn Curl_ssl_supports(data: ?*anyopaque, ssl_option: c_uint) callconv(.c) bool;

test "curl_version_info feature bits match backend_options" {
    const info = curl_version_info(c.CURLVERSION_NOW) orelse return error.NullVersionInfo;

    try testing.expect((info.*.features & c.CURL_VERSION_ZSTD != 0) == backend_options.zstd);
    try testing.expect((info.*.features & c.CURL_VERSION_LIBZ != 0) == backend_options.zlib);
    try testing.expect((info.*.features & c.CURL_VERSION_SSL != 0) == (backend_options.ssl != .none));
    try testing.expect((info.*.features & c.CURL_VERSION_HTTP2 != 0) == backend_options.nghttp2);
    try testing.expect((info.*.features & c.CURL_VERSION_HSTS != 0) == (backend_options.ssl != .none));
    try testing.expect((info.*.features & c.CURL_VERSION_HTTPS_PROXY != 0) == (backend_options.ssl != .none));
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
        const ssl_ver = std.mem.span(info.*.ssl_version.?);
        const expected_prefix = switch (backend_options.ssl) {
            .openssl => "OpenSSL",
            .mbedtls => "mbedTLS",
            .schannel => "Schannel",
            .gnutls => "GnuTLS",
            .rustls => "rustls-ffi",
            .wolfssl => "wolfSSL",
            .none => unreachable,
        };
        try testing.expect(std.mem.startsWith(u8, ssl_ver, expected_prefix));
    } else {
        try testing.expect(info.*.ssl_version == null);
    }
    if (backend_options.nghttp2) {
        try testing.expect(info.*.nghttp2_version != null);
        try testing.expect(info.*.nghttp2_ver_num != 0);
    }

    const expect_apple_sectrust = backend_options.apple_sectrust orelse
        (backend_options.ssl == .openssl and builtin.os.tag.isDarwin());
    var found_apple_sectrust = false;
    var found_ssl_feat = false;
    var found_hsts_feat = false;
    var found_https_proxy_feat = false;
    if (info.*.feature_names) |names| {
        var idx: usize = 0;
        while (names[idx]) |feat_name| : (idx += 1) {
            const name_slice = std.mem.span(feat_name);
            if (std.mem.eql(u8, name_slice, "AppleSecTrust")) found_apple_sectrust = true;
            if (std.mem.eql(u8, name_slice, "SSL")) found_ssl_feat = true;
            if (std.mem.eql(u8, name_slice, "HSTS")) found_hsts_feat = true;
            if (std.mem.eql(u8, name_slice, "HTTPS-proxy")) found_https_proxy_feat = true;
        }
    }
    try testing.expectEqual(backend_options.ssl != .none and expect_apple_sectrust, found_apple_sectrust);
    try testing.expectEqual(backend_options.ssl != .none, found_ssl_feat);
    try testing.expectEqual(backend_options.ssl != .none, found_hsts_feat);
    try testing.expectEqual(backend_options.ssl != .none, found_https_proxy_feat);
}

test "curl_global_sslset and curl_easy_setopt TLS capability matrix" {
    var avail: ?[*:null]const ?*const c.curl_ssl_backend = null;
    if (backend_options.ssl == .none) {
        try testing.expectEqual(c.CURLSSLSET_NO_BACKENDS, curl_global_sslset(c.CURLSSLBACKEND_NONE, null, &avail));
        try testing.expect(avail != null);
        try testing.expect(avail.?[0] == null);
    } else {
        const expected_id: c_uint = switch (backend_options.ssl) {
            .openssl => c.CURLSSLBACKEND_OPENSSL,
            .mbedtls => c.CURLSSLBACKEND_MBEDTLS,
            .schannel => c.CURLSSLBACKEND_SCHANNEL,
            .gnutls => c.CURLSSLBACKEND_GNUTLS,
            .rustls => c.CURLSSLBACKEND_RUSTLS,
            .wolfssl => c.CURLSSLBACKEND_WOLFSSL,
            .none => unreachable,
        };
        const expected_name: [*:0]const u8 = switch (backend_options.ssl) {
            .openssl => "openssl",
            .mbedtls => "mbedtls",
            .schannel => "schannel",
            .gnutls => "gnutls",
            .rustls => "rustls",
            .wolfssl => "wolfssl",
            .none => unreachable,
        };

        try testing.expectEqual(c.CURLSSLSET_OK, curl_global_sslset(c.CURLSSLBACKEND_NONE, null, &avail));
        try testing.expect(avail != null);
        try testing.expect(avail.?[0] != null);
        try testing.expectEqual(expected_id, avail.?[0].?.id);
        try testing.expect(std.mem.eql(u8, std.mem.span(avail.?[0].?.name), std.mem.span(expected_name)));
        try testing.expect(avail.?[1] == null);

        try testing.expectEqual(c.CURLSSLSET_OK, curl_global_sslset(expected_id, null, null));
        try testing.expectEqual(c.CURLSSLSET_OK, curl_global_sslset(c.CURLSSLBACKEND_NONE, expected_name, null));
        try testing.expectEqual(c.CURLSSLSET_UNKNOWN_BACKEND, curl_global_sslset(999, null, null));
        try testing.expectEqual(c.CURLSSLSET_UNKNOWN_BACKEND, curl_global_sslset(c.CURLSSLBACKEND_NONE, "nonexistent-ssl", null));
    }

    const easy = curl_easy_init() orelse return error.EasyInitFailed;
    defer curl_easy_cleanup(easy);

    // Verify backend capability bitmask matches expected backend table
    const expect_ca_path = switch (backend_options.ssl) {
        .openssl, .mbedtls, .gnutls, .wolfssl => true,
        .none, .schannel, .rustls => false,
    };
    const expect_certinfo = switch (backend_options.ssl) {
        .openssl, .mbedtls, .schannel, .gnutls, .rustls => true,
        .none, .wolfssl => false,
    };
    const expect_pinnedpubkey = switch (backend_options.ssl) {
        .openssl, .mbedtls, .schannel, .gnutls, .wolfssl => true,
        .none, .rustls => false,
    };
    const expect_ssl_ctx = switch (backend_options.ssl) {
        .openssl, .mbedtls, .wolfssl => true,
        .none, .schannel, .gnutls, .rustls => false,
    };
    const expect_https_proxy = backend_options.ssl != .none;
    const expect_tls13_ciphers = switch (backend_options.ssl) {
        .openssl, .mbedtls, .rustls, .wolfssl => true,
        .none, .schannel, .gnutls => false,
    };
    const expect_cainfo_blob = backend_options.ssl != .none;
    const expect_cipher_list = backend_options.ssl != .none;
    const expect_ec_curves = switch (backend_options.ssl) {
        .openssl, .mbedtls, .wolfssl => true,
        .none, .schannel, .gnutls, .rustls => false,
    };
    const expect_sig_algs = backend_options.ssl == .openssl;
    const expect_crlfile = switch (backend_options.ssl) {
        .openssl, .mbedtls, .schannel, .gnutls, .rustls => true,
        .none, .wolfssl => false,
    };
    const expect_issuercert = switch (backend_options.ssl) {
        .openssl, .gnutls => true,
        .none, .mbedtls, .schannel, .rustls, .wolfssl => false,
    };

    try testing.expectEqual(expect_ca_path, Curl_ssl_supports(easy, c.SSLSUPP_CA_PATH));
    try testing.expectEqual(expect_certinfo, Curl_ssl_supports(easy, c.SSLSUPP_CERTINFO));
    try testing.expectEqual(expect_pinnedpubkey, Curl_ssl_supports(easy, c.SSLSUPP_PINNEDPUBKEY));
    try testing.expectEqual(expect_ssl_ctx, Curl_ssl_supports(easy, c.SSLSUPP_SSL_CTX));
    try testing.expectEqual(expect_https_proxy, Curl_ssl_supports(easy, c.SSLSUPP_HTTPS_PROXY));
    try testing.expectEqual(expect_tls13_ciphers, Curl_ssl_supports(easy, c.SSLSUPP_TLS13_CIPHERSUITES));
    try testing.expectEqual(expect_cainfo_blob, Curl_ssl_supports(easy, c.SSLSUPP_CAINFO_BLOB));
    try testing.expectEqual(expect_cipher_list, Curl_ssl_supports(easy, c.SSLSUPP_CIPHER_LIST));
    try testing.expectEqual(expect_ec_curves, Curl_ssl_supports(easy, c.SSLSUPP_SSL_EC_CURVES));
    try testing.expectEqual(expect_sig_algs, Curl_ssl_supports(easy, c.SSLSUPP_SIGNATURE_ALGORITHMS));
    try testing.expectEqual(expect_crlfile, Curl_ssl_supports(easy, c.SSLSUPP_CRLFILE));
    try testing.expectEqual(expect_issuercert, Curl_ssl_supports(easy, c.SSLSUPP_ISSUERCERT));

    // Verify curl_easy_setopt TLS option acceptance matches supports bitmask
    try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_SSL_VERIFYPEER, @as(c_long, 1)));
    try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_SSL_VERIFYHOST, @as(c_long, 2)));

    try testing.expectEqual(
        if (backend_options.ssl != .none) c.CURLE_OK else c.CURLE_UNKNOWN_OPTION,
        curl_easy_setopt(easy, c.CURLOPT_CAINFO, @as([*:0]const u8, "dummy-ca.pem")),
    );

    const dummy_pem = "-----BEGIN CERTIFICATE-----\n-----END CERTIFICATE-----\n";
    var blob = c.curl_blob{
        .data = @ptrCast(@constCast(dummy_pem.ptr)),
        .len = dummy_pem.len,
        .flags = c.CURL_BLOB_COPY,
    };
    try testing.expectEqual(
        if (expect_cainfo_blob) c.CURLE_OK else c.CURLE_NOT_BUILT_IN,
        curl_easy_setopt(easy, c.CURLOPT_CAINFO_BLOB, &blob),
    );

    try testing.expectEqual(
        if (expect_certinfo) c.CURLE_OK else c.CURLE_NOT_BUILT_IN,
        curl_easy_setopt(easy, c.CURLOPT_CERTINFO, @as(c_long, 1)),
    );

    const cptrExpected = struct {
        fn code(supported: bool) c.CURLcode {
            if (backend_options.ssl == .none) return c.CURLE_UNKNOWN_OPTION;
            return if (supported) c.CURLE_OK else c.CURLE_NOT_BUILT_IN;
        }
    }.code;

    try testing.expectEqual(
        cptrExpected(expect_pinnedpubkey),
        curl_easy_setopt(easy, c.CURLOPT_PINNEDPUBLICKEY, @as([*:0]const u8, "sha256//AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=")),
    );
    try testing.expectEqual(
        cptrExpected(expect_cipher_list),
        curl_easy_setopt(easy, c.CURLOPT_SSL_CIPHER_LIST, @as([*:0]const u8, "DEFAULT")),
    );
    try testing.expectEqual(
        cptrExpected(expect_tls13_ciphers),
        curl_easy_setopt(easy, c.CURLOPT_TLS13_CIPHERS, @as([*:0]const u8, "TLS_AES_128_GCM_SHA256")),
    );
    try testing.expectEqual(
        cptrExpected(expect_ec_curves),
        curl_easy_setopt(easy, c.CURLOPT_SSL_EC_CURVES, @as([*:0]const u8, "P-256")),
    );
    try testing.expectEqual(
        cptrExpected(expect_sig_algs),
        curl_easy_setopt(easy, c.CURLOPT_SSL_SIGNATURE_ALGORITHMS, @as([*:0]const u8, "ecdsa_secp256r1_sha256")),
    );
    try testing.expectEqual(
        cptrExpected(expect_crlfile),
        curl_easy_setopt(easy, c.CURLOPT_CRLFILE, @as([*:0]const u8, "dummy-crl.pem")),
    );
    try testing.expectEqual(
        cptrExpected(expect_issuercert),
        curl_easy_setopt(easy, c.CURLOPT_ISSUERCERT, @as([*:0]const u8, "dummy-issuer.pem")),
    );

    var tls_info: ?*const c.curl_tlssessioninfo = null;
    try testing.expectEqual(c.CURLE_OK, curl_easy_getinfo(easy, c.CURLINFO_TLS_SSL_PTR, &tls_info));
    try testing.expect(tls_info != null);
    const expected_tls_backend: c_uint = switch (backend_options.ssl) {
        .none => c.CURLSSLBACKEND_NONE,
        .openssl => c.CURLSSLBACKEND_OPENSSL,
        .mbedtls => c.CURLSSLBACKEND_MBEDTLS,
        .schannel => c.CURLSSLBACKEND_SCHANNEL,
        .gnutls => c.CURLSSLBACKEND_GNUTLS,
        .rustls => c.CURLSSLBACKEND_RUSTLS,
        .wolfssl => c.CURLSSLBACKEND_WOLFSSL,
    };
    try testing.expectEqual(expected_tls_backend, tls_info.?.backend);
    try testing.expectEqual(@as(?*anyopaque, null), tls_info.?.internals);
}

test "SslBackend and Apple SecTrust target validation" {
    try testing.expectEqual(@as(usize, 7), std.enums.values(backends.SslBackend).len);

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

    inline for (.{ backends.SslBackend.gnutls, backends.SslBackend.rustls, backends.SslBackend.wolfssl }) |ssl_backend| {
        const opts = backends.Options{ .ssl = ssl_backend };
        try testing.expect(opts.isValidForTarget(.linux));
        try testing.expect(opts.isValidForTarget(.macos));
        try testing.expect(!opts.useAppleSectrust(.macos));
    }
}

const loopback_tls = struct {
    // Root CA (CN=curl-zig-test-ca, valid 2020..2049)
    const test_ca_cert_pem: [:0]const u8 =
        \\-----BEGIN CERTIFICATE-----
        \\MIIBmjCCAUGgAwIBAgIUfQZTbIpX8IFrj+WYZ+0OmKXNqk4wCgYIKoZIzj0EAwIw
        \\GzEZMBcGA1UEAwwQY3VybC16aWctdGVzdC1jYTAeFw0yMDAxMDEwMDAwMDBaFw00
        \\OTEyMzEyMzU5NTlaMBsxGTAXBgNVBAMMEGN1cmwtemlnLXRlc3QtY2EwWTATBgcq
        \\hkjOPQIBBggqhkjOPQMBBwNCAAQoTpIGrJFs0dVUkOluncBTMmEbofWLFURcdyou
        \\sb+FzrsceHhEEl4h55xtljCG6XNC8cpTq0bccAdq0HGuUmsjo2MwYTAdBgNVHQ4E
        \\FgQUUp9GU1TG6cFp+dqw5YaKTmZlcGYwHwYDVR0jBBgwFoAUUp9GU1TG6cFp+dqw
        \\5YaKTmZlcGYwDwYDVR0TAQH/BAUwAwEB/zAOBgNVHQ8BAf8EBAMCAQYwCgYIKoZI
        \\zj0EAwIDRwAwRAIgOCcUaHTn5/FKJKRznvWWZ+IXT0mFBVLaSyBF6ZWJhDoCICuQ
        \\tCNyaA71GDSYE4P7BYPmYgtZvbiLrZWmtUwQTaPW
        \\-----END CERTIFICATE-----
        \\
    ;

    // Leaf server cert signed by test_ca_cert_pem (CN=localhost, SAN=DNS:localhost, valid 2020..2049)
    const test_server_cert_pem: [:0]const u8 =
        \\-----BEGIN CERTIFICATE-----
        \\MIIBvjCCAWSgAwIBAgIUDGM3QqxgD+aktmk/PZC3V+UmcRMwCgYIKoZIzj0EAwIw
        \\GzEZMBcGA1UEAwwQY3VybC16aWctdGVzdC1jYTAeFw0yMDAxMDEwMDAwMDBaFw00
        \\OTEyMzEyMzU5NTlaMBQxEjAQBgNVBAMMCWxvY2FsaG9zdDBZMBMGByqGSM49AgEG
        \\CCqGSM49AwEHA0IABH2/lUFJsfqzBJujZlnCUhST3sZ6pgEYWr2xUtHfgufM9mP5
        \\i9zf0FS2D8pY8U1suMaK5OGoRqF1uNwD8LjbCbyjgYwwgYkwDAYDVR0TAQH/BAIw
        \\ADAOBgNVHQ8BAf8EBAMCBaAwEwYDVR0lBAwwCgYIKwYBBQUHAwEwFAYDVR0RBA0w
        \\C4IJbG9jYWxob3N0MB0GA1UdDgQWBBQL/sY8G/6M1bRs9oCzusjRxAdNWjAfBgNV
        \\HSMEGDAWgBRSn0ZTVMbpwWn52rDlhopOZmVwZjAKBggqhkjOPQQDAgNIADBFAiBp
        \\ZjwF2DyqZdSBmM/3+z7UqjFuWf6iIqSi8Yy1xPsySAIhAMPz4B3Wi/NRC8OkffDo
        \\rAa4SYs5WWQ4DwgS6XWjGlcz
        \\-----END CERTIFICATE-----
        \\
    ;

    const test_server_key_pem: [:0]const u8 =
        \\-----BEGIN EC PRIVATE KEY-----
        \\MHcCAQEEIOax4UqvKuoDsEOgbNodLAuWNZExlnybWGMLt9HPI72eoAoGCCqGSM49
        \\AwEHoUQDQgAEfb+VQUmx+rMEm6NmWcJSFJPexnqmARhavbFS0d+C58z2Y/mL3N/Q
        \\VLYPyljxTWy4xork4ahGoXW43APwuNsJvA==
        \\-----END EC PRIVATE KEY-----
        \\
    ;

    // Separate untrusted Root CA (CN=curl-zig-untrusted-ca, valid 2020..2049)
    const test_untrusted_ca_cert_pem: [:0]const u8 =
        \\-----BEGIN CERTIFICATE-----
        \\MIIBpDCCAUugAwIBAgIUK1tdYusyCHZyruJw0TlYuTB+jWQwCgYIKoZIzj0EAwIw
        \\IDEeMBwGA1UEAwwVY3VybC16aWctdW50cnVzdGVkLWNhMB4XDTIwMDEwMTAwMDAw
        \\MFoXDTQ5MTIzMTIzNTk1OVowIDEeMBwGA1UEAwwVY3VybC16aWctdW50cnVzdGVk
        \\LWNhMFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAEBAN7h+PJuafFmclAXY9TdehT
        \\k0lCIKEVedYCVNdcqyivGEKobi3ggX2XczEz2tkuBYhgX1xSu5rAp7Qh8EdiXqNj
        \\MGEwHQYDVR0OBBYEFLmTzCbGW9eoesCGa0YkVyWMAvLhMB8GA1UdIwQYMBaAFLmT
        \\zCbGW9eoesCGa0YkVyWMAvLhMA8GA1UdEwEB/wQFMAMBAf8wDgYDVR0PAQH/BAQD
        \\AgEGMAoGCCqGSM49BAMCA0cAMEQCICw+8kVkXGTV0Y3KJGGCJTyO81HVwzzvrrZh
        \\7JiUJ/mhAiAgmXm9IXO+LnpgDToIFLISTMmovuVmX9dYPksZAfpz+g==
        \\-----END CERTIFICATE-----
        \\
    ;

    const test_server_pubkey_pin: [*:0]const u8 = "sha256//J5gIj+3IzbJ3r9lrFIvGtH1RgZOmPQNTuxxtsDkCOpc=";
    const test_wrong_pubkey_pin: [*:0]const u8 = "sha256//AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";

    const ossl = struct {
        extern fn TLS_server_method() callconv(.c) ?*const anyopaque;
        extern fn SSL_CTX_new(method: ?*const anyopaque) callconv(.c) ?*anyopaque;
        extern fn SSL_CTX_free(ctx: ?*anyopaque) callconv(.c) void;
        extern fn BIO_new_mem_buf(buf: ?*const anyopaque, len: c_int) callconv(.c) ?*anyopaque;
        extern fn BIO_free(bio: ?*anyopaque) callconv(.c) c_int;
        extern fn PEM_read_bio_X509(bio: ?*anyopaque, x: ?*?*anyopaque, cb: ?*const anyopaque, u: ?*anyopaque) callconv(.c) ?*anyopaque;
        extern fn PEM_read_bio_PrivateKey(bio: ?*anyopaque, x: ?*?*anyopaque, cb: ?*const anyopaque, u: ?*anyopaque) callconv(.c) ?*anyopaque;
        extern fn X509_free(x: ?*anyopaque) callconv(.c) void;
        extern fn EVP_PKEY_free(pkey: ?*anyopaque) callconv(.c) void;
        extern fn SSL_CTX_use_certificate(ctx: ?*anyopaque, x: ?*anyopaque) callconv(.c) c_int;
        extern fn SSL_CTX_use_PrivateKey(ctx: ?*anyopaque, pkey: ?*anyopaque) callconv(.c) c_int;
        extern fn SSL_new(ctx: ?*anyopaque) callconv(.c) ?*anyopaque;
        extern fn SSL_free(ssl: ?*anyopaque) callconv(.c) void;
        extern fn SSL_set_fd(ssl: ?*anyopaque, fd: c_int) callconv(.c) c_int;
        extern fn SSL_accept(ssl: ?*anyopaque) callconv(.c) c_int;
        extern fn SSL_read(ssl: ?*anyopaque, buf: [*]u8, num: c_int) callconv(.c) c_int;
        extern fn SSL_write(ssl: ?*anyopaque, buf: [*]const u8, num: c_int) callconv(.c) c_int;
        extern fn SSL_shutdown(ssl: ?*anyopaque) callconv(.c) c_int;
    };

    const mbed = struct {
        const MBEDTLS_SSL_IS_SERVER: c_int = 1;
        const MBEDTLS_SSL_TRANSPORT_STREAM: c_int = 0;
        const MBEDTLS_SSL_PRESET_DEFAULT: c_int = 0;
        const MBEDTLS_ERR_SSL_WANT_READ: c_int = -0x6900;
        const MBEDTLS_ERR_SSL_WANT_WRITE: c_int = -0x6880;

        const SslContext = extern struct { data: [144]u64 = @splat(0) };
        const SslConfig = extern struct { data: [80]u64 = @splat(0) };
        const X509Crt = extern struct { data: [128]u64 = @splat(0) };
        const PkContext = extern struct { data: [16]u64 = @splat(0) };
        const EntropyContext = extern struct { data: [4800]u64 = @splat(0) };
        const CtrDrbgContext = extern struct { data: [64]u64 = @splat(0) };

        extern fn psa_crypto_init() callconv(.c) c_int;
        extern fn mbedtls_ssl_init(ssl: *SslContext) callconv(.c) void;
        extern fn mbedtls_ssl_free(ssl: *SslContext) callconv(.c) void;
        extern fn mbedtls_ssl_config_init(conf: *SslConfig) callconv(.c) void;
        extern fn mbedtls_ssl_config_free(conf: *SslConfig) callconv(.c) void;
        extern fn mbedtls_ssl_config_defaults(conf: *SslConfig, endpoint: c_int, transport: c_int, preset: c_int) callconv(.c) c_int;
        extern fn mbedtls_ssl_conf_rng(conf: *SslConfig, f_rng: *const fn (?*anyopaque, [*]u8, usize) callconv(.c) c_int, p_rng: ?*anyopaque) callconv(.c) void;
        extern fn mbedtls_ssl_conf_own_cert(conf: *SslConfig, own_cert: *X509Crt, pk_key: *PkContext) callconv(.c) c_int;
        extern fn mbedtls_ssl_setup(ssl: *SslContext, conf: *const SslConfig) callconv(.c) c_int;
        extern fn mbedtls_ssl_set_bio(
            ssl: *SslContext,
            p_bio: ?*anyopaque,
            f_send: *const fn (?*anyopaque, [*]const u8, usize) callconv(.c) c_int,
            f_recv: *const fn (?*anyopaque, [*]u8, usize) callconv(.c) c_int,
            f_recv_timeout: ?*const anyopaque,
        ) callconv(.c) void;
        extern fn mbedtls_ssl_handshake(ssl: *SslContext) callconv(.c) c_int;
        extern fn mbedtls_ssl_read(ssl: *SslContext, buf: [*]u8, len: usize) callconv(.c) c_int;
        extern fn mbedtls_ssl_write(ssl: *SslContext, buf: [*]const u8, len: usize) callconv(.c) c_int;
        extern fn mbedtls_ssl_close_notify(ssl: *SslContext) callconv(.c) c_int;
        extern fn mbedtls_x509_crt_init(crt: *X509Crt) callconv(.c) void;
        extern fn mbedtls_x509_crt_free(crt: *X509Crt) callconv(.c) void;
        extern fn mbedtls_x509_crt_parse(chain: *X509Crt, buf: [*]const u8, buflen: usize) callconv(.c) c_int;
        extern fn mbedtls_pk_init(ctx: *PkContext) callconv(.c) void;
        extern fn mbedtls_pk_free(ctx: *PkContext) callconv(.c) void;
        extern fn mbedtls_pk_parse_key(
            ctx: *PkContext,
            key: [*]const u8,
            keylen: usize,
            pwd: ?[*]const u8,
            pwdlen: usize,
            f_rng: *const fn (?*anyopaque, [*]u8, usize) callconv(.c) c_int,
            p_rng: ?*anyopaque,
        ) callconv(.c) c_int;
        extern fn mbedtls_entropy_init(ctx: *EntropyContext) callconv(.c) void;
        extern fn mbedtls_entropy_free(ctx: *EntropyContext) callconv(.c) void;
        extern fn mbedtls_entropy_func(data: ?*anyopaque, output: [*]u8, len: usize) callconv(.c) c_int;
        extern fn mbedtls_ctr_drbg_init(ctx: *CtrDrbgContext) callconv(.c) void;
        extern fn mbedtls_ctr_drbg_free(ctx: *CtrDrbgContext) callconv(.c) void;
        extern fn mbedtls_ctr_drbg_seed(
            ctx: *CtrDrbgContext,
            f_entropy: *const fn (?*anyopaque, [*]u8, usize) callconv(.c) c_int,
            p_entropy: ?*anyopaque,
            custom: ?[*]const u8,
            len: usize,
        ) callconv(.c) c_int;
        extern fn mbedtls_ctr_drbg_random(p_rng: ?*anyopaque, output: [*]u8, output_len: usize) callconv(.c) c_int;

        fn bioSend(ctx: ?*anyopaque, buf: [*]const u8, len: usize) callconv(.c) c_int {
            const fd_ptr: *const c_int = @ptrCast(@alignCast(ctx.?));
            const n = sock_c.send(fd_ptr.*, buf, len, 0);
            return if (n < 0) -1 else @intCast(n);
        }

        fn bioRecv(ctx: ?*anyopaque, buf: [*]u8, len: usize) callconv(.c) c_int {
            const fd_ptr: *const c_int = @ptrCast(@alignCast(ctx.?));
            const n = sock_c.recv(fd_ptr.*, buf, len, 0);
            return if (n < 0) -1 else @intCast(n);
        }
    };

    const sock_c = struct {
        const AF_INET: c_int = 2;
        const SOCK_STREAM: c_int = 1;
        const SOL_SOCKET: c_int = 1;
        const SO_REUSEADDR: c_int = 2;
        const SO_RCVTIMEO: c_int = 20;
        const SO_SNDTIMEO: c_int = 21;

        const sockaddr_in = extern struct {
            sin_family: u16 = AF_INET,
            sin_port: u16 = 0,
            sin_addr: u32 = 0,
            sin_zero: [8]u8 = @splat(0),
        };

        const timeval = extern struct {
            tv_sec: c_long,
            tv_usec: c_long,
        };

        extern "c" fn socket(domain: c_int, sock_type: c_int, protocol: c_int) c_int;
        extern "c" fn setsockopt(sockfd: c_int, level: c_int, optname: c_int, optval: *const anyopaque, optlen: u32) c_int;
        extern "c" fn bind(sockfd: c_int, addr: *const sockaddr_in, addrlen: u32) c_int;
        extern "c" fn listen(sockfd: c_int, backlog: c_int) c_int;
        extern "c" fn getsockname(sockfd: c_int, addr: *sockaddr_in, addrlen: *u32) c_int;
        extern "c" fn accept(sockfd: c_int, addr: ?*anyopaque, addrlen: ?*u32) c_int;
        extern "c" fn recv(sockfd: c_int, buf: [*]u8, len: usize, flags: c_int) isize;
        extern "c" fn send(sockfd: c_int, buf: [*]const u8, len: usize, flags: c_int) isize;
        extern "c" fn close(fd: c_int) c_int;
    };

    const http_response = "HTTP/1.1 200 OK\r\nContent-Length: 2\r\nConnection: close\r\n\r\nok";

    fn setSocketTimeouts(fd: c_int) void {
        if (builtin.os.tag == .linux) {
            const tv = sock_c.timeval{ .tv_sec = 5, .tv_usec = 0 };
            _ = sock_c.setsockopt(fd, sock_c.SOL_SOCKET, sock_c.SO_RCVTIMEO, &tv, @sizeOf(sock_c.timeval));
            _ = sock_c.setsockopt(fd, sock_c.SOL_SOCKET, sock_c.SO_SNDTIMEO, &tv, @sizeOf(sock_c.timeval));
        }
    }

    fn openLoopbackListener(port_out: *u16) !c_int {
        const fd = sock_c.socket(sock_c.AF_INET, sock_c.SOCK_STREAM, 0);
        if (fd < 0) return error.SocketFailed;
        errdefer _ = sock_c.close(fd);

        const one: c_int = 1;
        _ = sock_c.setsockopt(fd, sock_c.SOL_SOCKET, sock_c.SO_REUSEADDR, &one, @sizeOf(c_int));

        var addr = sock_c.sockaddr_in{
            .sin_family = sock_c.AF_INET,
            .sin_port = 0,
            .sin_addr = std.mem.nativeToBig(u32, 0x7f000001),
        };
        if (sock_c.bind(fd, &addr, @sizeOf(sock_c.sockaddr_in)) != 0) return error.BindFailed;
        if (sock_c.listen(fd, 4) != 0) return error.ListenFailed;

        var bound_addr = sock_c.sockaddr_in{};
        var addr_len: u32 = @sizeOf(sock_c.sockaddr_in);
        if (sock_c.getsockname(fd, &bound_addr, &addr_len) != 0) return error.GetsocknameFailed;
        port_out.* = std.mem.bigToNative(u16, bound_addr.sin_port);
        return fd;
    }

    fn serveOpenSslOnce(listen_fd: c_int) void {
        const client_fd = sock_c.accept(listen_fd, null, null);
        if (client_fd < 0) return;
        defer _ = sock_c.close(client_fd);
        setSocketTimeouts(client_fd);

        const method = ossl.TLS_server_method() orelse return;
        const ctx = ossl.SSL_CTX_new(method) orelse return;
        defer ossl.SSL_CTX_free(ctx);

        const cert_bio = ossl.BIO_new_mem_buf(test_server_cert_pem.ptr, @intCast(test_server_cert_pem.len)) orelse return;
        defer _ = ossl.BIO_free(cert_bio);
        const x509 = ossl.PEM_read_bio_X509(cert_bio, null, null, null) orelse return;
        defer ossl.X509_free(x509);
        if (ossl.SSL_CTX_use_certificate(ctx, x509) != 1) return;

        const key_bio = ossl.BIO_new_mem_buf(test_server_key_pem.ptr, @intCast(test_server_key_pem.len)) orelse return;
        defer _ = ossl.BIO_free(key_bio);
        const pkey = ossl.PEM_read_bio_PrivateKey(key_bio, null, null, null) orelse return;
        defer ossl.EVP_PKEY_free(pkey);
        if (ossl.SSL_CTX_use_PrivateKey(ctx, pkey) != 1) return;

        const ssl = ossl.SSL_new(ctx) orelse return;
        defer ossl.SSL_free(ssl);
        if (ossl.SSL_set_fd(ssl, client_fd) != 1) return;

        if (ossl.SSL_accept(ssl) != 1) return;

        var req_buf: [1024]u8 = undefined;
        const nread = ossl.SSL_read(ssl, &req_buf, @intCast(req_buf.len));
        if (nread > 0) {
            _ = ossl.SSL_write(ssl, http_response.ptr, @intCast(http_response.len));
            _ = ossl.SSL_shutdown(ssl);
        }
    }

    fn serveMbedTlsOnce(listen_fd: c_int) void {
        var client_fd = sock_c.accept(listen_fd, null, null);
        if (client_fd < 0) return;
        defer _ = sock_c.close(client_fd);
        setSocketTimeouts(client_fd);

        _ = mbed.psa_crypto_init();

        var ssl: mbed.SslContext = .{};
        var conf: mbed.SslConfig = .{};
        var srvcert: mbed.X509Crt = .{};
        var pkey: mbed.PkContext = .{};
        var entropy: mbed.EntropyContext = .{};
        var ctr_drbg: mbed.CtrDrbgContext = .{};

        mbed.mbedtls_ssl_init(&ssl);
        defer mbed.mbedtls_ssl_free(&ssl);
        mbed.mbedtls_ssl_config_init(&conf);
        defer mbed.mbedtls_ssl_config_free(&conf);
        mbed.mbedtls_x509_crt_init(&srvcert);
        defer mbed.mbedtls_x509_crt_free(&srvcert);
        mbed.mbedtls_pk_init(&pkey);
        defer mbed.mbedtls_pk_free(&pkey);
        mbed.mbedtls_entropy_init(&entropy);
        defer mbed.mbedtls_entropy_free(&entropy);
        mbed.mbedtls_ctr_drbg_init(&ctr_drbg);
        defer mbed.mbedtls_ctr_drbg_free(&ctr_drbg);

        const pers = "curl-test-srv";
        if (mbed.mbedtls_ctr_drbg_seed(&ctr_drbg, mbed.mbedtls_entropy_func, &entropy, pers.ptr, pers.len) != 0) return;
        if (mbed.mbedtls_x509_crt_parse(&srvcert, test_server_cert_pem.ptr, test_server_cert_pem.len + 1) != 0) return;
        if (mbed.mbedtls_pk_parse_key(&pkey, test_server_key_pem.ptr, test_server_key_pem.len + 1, null, 0, mbed.mbedtls_ctr_drbg_random, &ctr_drbg) != 0) return;
        if (mbed.mbedtls_ssl_config_defaults(&conf, mbed.MBEDTLS_SSL_IS_SERVER, mbed.MBEDTLS_SSL_TRANSPORT_STREAM, mbed.MBEDTLS_SSL_PRESET_DEFAULT) != 0) return;

        mbed.mbedtls_ssl_conf_rng(&conf, mbed.mbedtls_ctr_drbg_random, &ctr_drbg);
        if (mbed.mbedtls_ssl_conf_own_cert(&conf, &srvcert, &pkey) != 0) return;
        if (mbed.mbedtls_ssl_setup(&ssl, &conf) != 0) return;

        mbed.mbedtls_ssl_set_bio(&ssl, &client_fd, mbed.bioSend, mbed.bioRecv, null);

        while (true) {
            const rc = mbed.mbedtls_ssl_handshake(&ssl);
            if (rc == 0) break;
            if (rc == mbed.MBEDTLS_ERR_SSL_WANT_READ or rc == mbed.MBEDTLS_ERR_SSL_WANT_WRITE) continue;
            return;
        }

        var req_buf: [1024]u8 = undefined;
        const nread = mbed.mbedtls_ssl_read(&ssl, &req_buf, req_buf.len);
        if (nread > 0) {
            _ = mbed.mbedtls_ssl_write(&ssl, http_response.ptr, http_response.len);
            _ = mbed.mbedtls_ssl_close_notify(&ssl);
        }
    }

    fn serveOnce(listen_fd: c_int) void {
        switch (backend_options.ssl) {
            .openssl => serveOpenSslOnce(listen_fd),
            .mbedtls => serveMbedTlsOnce(listen_fd),
            else => unreachable,
        }
    }

    const ResponseBuf = struct {
        data: [256]u8 = undefined,
        len: usize = 0,
    };

    fn writeCallback(ptr: [*]const u8, size: usize, nmemb: usize, userdata: ?*anyopaque) callconv(.c) usize {
        const total = size * nmemb;
        const rbuf: *ResponseBuf = @ptrCast(@alignCast(userdata orelse return total));
        const avail = rbuf.data.len - rbuf.len;
        const copy_len = @min(total, avail);
        if (copy_len > 0) {
            @memcpy(rbuf.data[rbuf.len .. rbuf.len + copy_len], ptr[0..copy_len]);
            rbuf.len += copy_len;
        }
        return total;
    }

    const TransferOpts = struct {
        hostname: []const u8 = "localhost",
        ca_pem_blob: ?[:0]const u8 = test_ca_cert_pem,
        cainfo_path: ?[*:0]const u8 = null,
        verifypeer: c_long = 1,
        verifyhost: c_long = 2,
        certinfo: bool = false,
        pinnedpubkey: ?[*:0]const u8 = null,
    };

    const TransferOutcome = struct {
        code: c.CURLcode,
        status_code: c_long = 0,
        body_ok: bool = false,
        certinfo_certs: c_int = 0,
        certinfo_has_subject: bool = false,
    };

    fn runLoopbackTransfer(opts: TransferOpts) !TransferOutcome {
        var port: u16 = 0;
        const listen_fd = try openLoopbackListener(&port);
        defer _ = sock_c.close(listen_fd);

        const server_thread = try std.Thread.spawn(.{}, serveOnce, .{listen_fd});
        defer server_thread.join();

        const easy = curl_easy_init() orelse return error.EasyInitFailed;
        defer curl_easy_cleanup(easy);

        var url_buf: [128]u8 = undefined;
        const url = try std.fmt.bufPrint(&url_buf, "https://{s}:{d}/test\x00", .{ opts.hostname, port });

        var resolve_buf: [128]u8 = undefined;
        const resolve_entry = try std.fmt.bufPrint(&resolve_buf, "{s}:{d}:127.0.0.1\x00", .{ opts.hostname, port });
        const resolve_list = curl_slist_append(null, @ptrCast(resolve_entry.ptr)) orelse return error.SlistFailed;
        defer curl_slist_free_all(resolve_list);

        var resp_buf = ResponseBuf{};

        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_URL, @as([*:0]const u8, @ptrCast(url.ptr))));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_RESOLVE, resolve_list));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_NOSIGNAL, @as(c_long, 1)));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_TIMEOUT_MS, @as(c_long, 5000)));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_WRITEFUNCTION, &writeCallback));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_WRITEDATA, &resp_buf));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_SSL_VERIFYPEER, opts.verifypeer));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_SSL_VERIFYHOST, opts.verifyhost));

        if (opts.ca_pem_blob) |ca_pem| {
            var blob = c.curl_blob{
                .data = @ptrCast(@constCast(ca_pem.ptr)),
                .len = ca_pem.len,
                .flags = c.CURL_BLOB_COPY,
            };
            try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_CAINFO_BLOB, &blob));
        }
        if (opts.cainfo_path) |ca_path| {
            try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_CAINFO, ca_path));
        }
        if (opts.certinfo) {
            try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_CERTINFO, @as(c_long, 1)));
        }
        if (opts.pinnedpubkey) |pin| {
            try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_PINNEDPUBLICKEY, pin));
        }

        const code = curl_easy_perform(easy);
        var outcome = TransferOutcome{
            .code = code,
            .body_ok = std.mem.eql(u8, resp_buf.data[0..resp_buf.len], "ok"),
        };

        if (code == c.CURLE_OK) {
            _ = curl_easy_getinfo(easy, c.CURLINFO_RESPONSE_CODE, &outcome.status_code);
            if (opts.certinfo) {
                var ci_ptr: ?*c.curl_certinfo = null;
                if (curl_easy_getinfo(easy, c.CURLINFO_CERTINFO, &ci_ptr) == c.CURLE_OK) {
                    if (ci_ptr) |ci| {
                        outcome.certinfo_certs = ci.num_of_certs;
                        if (ci.num_of_certs > 0 and ci.certinfo != null) {
                            var node = ci.certinfo.?[0];
                            while (node) |cur| : (node = cur.next) {
                                if (cur.data) |entry| {
                                    const entry_str = std.mem.span(entry);
                                    if (std.mem.startsWith(u8, entry_str, "Subject:") or
                                        std.mem.startsWith(u8, entry_str, "Cert:"))
                                    {
                                        outcome.certinfo_has_subject = true;
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        return outcome;
    }
};

test "local loopback HTTPS handshake and certificate verification matrix" {
    if (comptime (backend_options.ssl != .openssl and backend_options.ssl != .mbedtls)) return;

    // 1a. Trusted CA via CURLOPT_CAINFO_BLOB + CURLOPT_CERTINFO -> CURLE_OK & populated certinfo chain
    {
        const res = try loopback_tls.runLoopbackTransfer(.{
            .ca_pem_blob = loopback_tls.test_ca_cert_pem,
            .certinfo = true,
        });
        try testing.expectEqual(c.CURLE_OK, res.code);
        try testing.expectEqual(@as(c_long, 200), res.status_code);
        try testing.expect(res.body_ok);
        try testing.expect(res.certinfo_certs >= 1);
        try testing.expect(res.certinfo_has_subject);
    }

    // 1b. Trusted CA via CURLOPT_CAINFO file -> CURLE_OK
    {
        var tmp = testing.tmpDir(.{});
        defer tmp.cleanup();

        try tmp.dir.writeFile(testing.io, .{
            .sub_path = "ca.pem",
            .data = loopback_tls.test_ca_cert_pem,
        });
        const abs_path = try tmp.dir.realPathFileAlloc(testing.io, "ca.pem", testing.allocator);
        defer testing.allocator.free(abs_path);
        const abs_path_z = try std.fmt.allocPrint(testing.allocator, "{s}\x00", .{abs_path});
        defer testing.allocator.free(abs_path_z);

        const res = try loopback_tls.runLoopbackTransfer(.{
            .ca_pem_blob = null,
            .cainfo_path = @ptrCast(abs_path_z.ptr),
        });
        try testing.expectEqual(c.CURLE_OK, res.code);
        try testing.expectEqual(@as(c_long, 200), res.status_code);
        try testing.expect(res.body_ok);
    }

    // 2a. Untrusted CA with CURLOPT_SSL_VERIFYPEER = 1 -> CURLE_PEER_FAILED_VERIFICATION
    {
        const res = try loopback_tls.runLoopbackTransfer(.{
            .ca_pem_blob = loopback_tls.test_untrusted_ca_cert_pem,
            .verifypeer = 1,
        });
        try testing.expectEqual(c.CURLE_PEER_FAILED_VERIFICATION, res.code);
    }

    // 2b. Untrusted CA with CURLOPT_SSL_VERIFYPEER = 0 -> CURLE_OK
    {
        const res = try loopback_tls.runLoopbackTransfer(.{
            .ca_pem_blob = loopback_tls.test_untrusted_ca_cert_pem,
            .verifypeer = 0,
        });
        try testing.expectEqual(c.CURLE_OK, res.code);
        try testing.expectEqual(@as(c_long, 200), res.status_code);
        try testing.expect(res.body_ok);
    }

    // 3. Wrong hostname with CURLOPT_SSL_VERIFYHOST = 2 -> CURLE_PEER_FAILED_VERIFICATION
    {
        const res = try loopback_tls.runLoopbackTransfer(.{
            .hostname = "wrong.localhost",
            .ca_pem_blob = loopback_tls.test_ca_cert_pem,
            .verifypeer = 1,
            .verifyhost = 2,
        });
        try testing.expectEqual(c.CURLE_PEER_FAILED_VERIFICATION, res.code);
    }

    // 4a. CURLOPT_PINNEDPUBLICKEY with matching sha256//... pin -> CURLE_OK
    {
        const res = try loopback_tls.runLoopbackTransfer(.{
            .ca_pem_blob = loopback_tls.test_ca_cert_pem,
            .pinnedpubkey = loopback_tls.test_server_pubkey_pin,
        });
        try testing.expectEqual(c.CURLE_OK, res.code);
        try testing.expectEqual(@as(c_long, 200), res.status_code);
        try testing.expect(res.body_ok);
    }

    // 4b. CURLOPT_PINNEDPUBLICKEY with mismatched sha256//... pin -> CURLE_SSL_PINNEDPUBKEYNOTMATCH
    {
        const res = try loopback_tls.runLoopbackTransfer(.{
            .ca_pem_blob = loopback_tls.test_ca_cert_pem,
            .pinnedpubkey = loopback_tls.test_wrong_pubkey_pin,
        });
        try testing.expectEqual(c.CURLE_SSL_PINNEDPUBKEYNOTMATCH, res.code);
    }
}
