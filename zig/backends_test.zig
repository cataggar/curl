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
    pub const CURLE_WRITE_ERROR: CURLcode = 23;
    pub const CURLE_LDAP_CANNOT_BIND: CURLcode = 38;
    pub const CURLE_LDAP_SEARCH_FAILED: CURLcode = 39;
    pub const CURLE_UNKNOWN_OPTION: CURLcode = 48;
    pub const CURLE_PEER_FAILED_VERIFICATION: CURLcode = 60;
    pub const CURLE_BAD_CONTENT_ENCODING: CURLcode = 61;
    pub const CURLE_LOGIN_DENIED: CURLcode = 67;
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
    pub const CURLOPTTYPE_OFF_T: CURLoption = 30000;
    pub const CURLOPTTYPE_BLOB: CURLoption = 40000;

    pub const CURLOPT_WRITEDATA: CURLoption = CURLOPTTYPE_OBJECTPOINT + 1;
    pub const CURLOPT_URL: CURLoption = CURLOPTTYPE_OBJECTPOINT + 2;
    pub const CURLOPT_PROXY: CURLoption = CURLOPTTYPE_OBJECTPOINT + 4;
    pub const CURLOPT_USERPWD: CURLoption = CURLOPTTYPE_OBJECTPOINT + 5;
    pub const CURLOPT_RANGE: CURLoption = CURLOPTTYPE_OBJECTPOINT + 7;
    pub const CURLOPT_READDATA: CURLoption = CURLOPTTYPE_OBJECTPOINT + 9;
    pub const CURLOPT_READFUNCTION: CURLoption = CURLOPTTYPE_FUNCTIONPOINT + 12;
    pub const CURLOPT_POSTFIELDS: CURLoption = CURLOPTTYPE_OBJECTPOINT + 15;
    pub const CURLOPT_QUOTE: CURLoption = CURLOPTTYPE_OBJECTPOINT + 28;
    pub const CURLOPT_COOKIEFILE: CURLoption = 10031;
    pub const CURLOPT_POSTQUOTE: CURLoption = CURLOPTTYPE_OBJECTPOINT + 39;
    pub const CURLOPT_UPLOAD: CURLoption = CURLOPTTYPE_LONG + 46;
    pub const CURLOPT_POSTFIELDSIZE: CURLoption = CURLOPTTYPE_LONG + 60;
    pub const CURLOPT_SSL_VERIFYPEER: CURLoption = CURLOPTTYPE_LONG + 64;
    pub const CURLOPT_CAINFO: CURLoption = CURLOPTTYPE_OBJECTPOINT + 65;
    pub const CURLOPT_SSL_VERIFYHOST: CURLoption = CURLOPTTYPE_LONG + 81;
    pub const CURLOPT_SSL_CIPHER_LIST: CURLoption = CURLOPTTYPE_OBJECTPOINT + 83;
    pub const CURLOPT_HTTP_VERSION: CURLoption = CURLOPTTYPE_LONG + 84;
    pub const CURLOPT_NOSIGNAL: CURLoption = CURLOPTTYPE_LONG + 99;
    pub const CURLOPT_PROXYTYPE: CURLoption = CURLOPTTYPE_LONG + 101;
    pub const CURLOPT_ACCEPT_ENCODING: CURLoption = CURLOPTTYPE_OBJECTPOINT + 102;
    pub const CURLOPT_INFILESIZE_LARGE: CURLoption = CURLOPTTYPE_OFF_T + 115;
    pub const CURLOPT_USE_SSL: CURLoption = CURLOPTTYPE_LONG + 119;
    pub const CURLOPT_SSH_AUTH_TYPES: CURLoption = CURLOPTTYPE_LONG + 151;

    pub const CURLUSESSL_ALL: c_long = 3;
    pub const CURLOPT_SSH_PUBLIC_KEYFILE: CURLoption = CURLOPTTYPE_OBJECTPOINT + 152;
    pub const CURLOPT_SSH_PRIVATE_KEYFILE: CURLoption = CURLOPTTYPE_OBJECTPOINT + 153;
    pub const CURLOPT_SSH_HOST_PUBLIC_KEY_MD5: CURLoption = CURLOPTTYPE_OBJECTPOINT + 162;
    pub const CURLOPT_SSH_KNOWNHOSTS: CURLoption = CURLOPTTYPE_OBJECTPOINT + 183;
    pub const CURLOPT_PIPEWAIT: CURLoption = CURLOPTTYPE_LONG + 237;
    pub const CURLOPT_PROXY_SSL_VERIFYPEER: CURLoption = CURLOPTTYPE_LONG + 248;
    pub const CURLOPT_PROXY_SSL_VERIFYHOST: CURLoption = CURLOPTTYPE_LONG + 249;
    pub const CURLOPT_SSH_HOST_PUBLIC_KEY_SHA256: CURLoption = CURLOPTTYPE_OBJECTPOINT + 311;

    pub const CURLSSH_AUTH_PUBLICKEY: c_long = 1 << 0;

    pub const CURL_HTTP_VERSION_3: c_long = 30;
    pub const CURL_HTTP_VERSION_3ONLY: c_long = 31;
    pub const CURLPROXY_HTTPS3: c_long = 8;
    pub const CURLOPT_COOKIELIST: CURLoption = 10135;
    pub const CURLOPT_TIMEOUT_MS: CURLoption = CURLOPTTYPE_LONG + 155;
    pub const CURLOPT_CRLFILE: CURLoption = CURLOPTTYPE_OBJECTPOINT + 169;
    pub const CURLOPT_ISSUERCERT: CURLoption = CURLOPTTYPE_OBJECTPOINT + 170;
    pub const CURLOPT_CERTINFO: CURLoption = CURLOPTTYPE_LONG + 172;
    pub const CURLOPT_RESOLVE: CURLoption = CURLOPTTYPE_OBJECTPOINT + 203;
    pub const CURLOPT_DNS_SERVERS: CURLoption = CURLOPTTYPE_OBJECTPOINT + 211;
    pub const CURLOPT_DNS_INTERFACE: CURLoption = CURLOPTTYPE_OBJECTPOINT + 221;
    pub const CURLOPT_DNS_LOCAL_IP4: CURLoption = CURLOPTTYPE_OBJECTPOINT + 222;
    pub const CURLOPT_DNS_LOCAL_IP6: CURLoption = CURLOPTTYPE_OBJECTPOINT + 223;
    pub const CURLOPT_PINNEDPUBLICKEY: CURLoption = CURLOPTTYPE_OBJECTPOINT + 230;
    pub const CURLOPT_TLS13_CIPHERS: CURLoption = CURLOPTTYPE_OBJECTPOINT + 276;
    pub const CURLOPT_DOH_URL: CURLoption = CURLOPTTYPE_OBJECTPOINT + 279;
    pub const CURLOPT_SSL_EC_CURVES: CURLoption = CURLOPTTYPE_OBJECTPOINT + 298;
    pub const CURLOPT_CAINFO_BLOB: CURLoption = CURLOPTTYPE_BLOB + 309;
    pub const CURLOPT_SSL_SIGNATURE_ALGORITHMS: CURLoption = CURLOPTTYPE_OBJECTPOINT + 328;
    pub const CURLOPT_WRITEFUNCTION: CURLoption = CURLOPTTYPE_FUNCTIONPOINT + 11;

    pub const CURLINFO = c_uint;
    pub const CURLINFO_LONG: CURLINFO = 0x200000;
    pub const CURLINFO_SLIST: CURLINFO = 0x400000;
    pub const CURLINFO_PTR: CURLINFO = 0x400000;
    pub const CURLINFO_RESPONSE_CODE: CURLINFO = CURLINFO_LONG + 2;
    pub const CURLINFO_COOKIELIST: CURLINFO = 0x400000 + 28;
    pub const CURLINFO_CERTINFO: CURLINFO = CURLINFO_SLIST + 34;
    pub const CURLINFO_TLS_SESSION: CURLINFO = CURLINFO_PTR + 43;
    pub const CURLINFO_TLS_SSL_PTR: CURLINFO = CURLINFO_PTR + 45;
    pub const CURLINFO_HTTP_VERSION: CURLINFO = CURLINFO_LONG + 46;

    pub const CURLMcode = c_uint;
    pub const CURLM_OK: CURLMcode = 0;

    pub const CURLMSG = c_uint;
    pub const CURLMSG_DONE: CURLMSG = 1;

    pub const CURLMsg = extern struct {
        msg: CURLMSG,
        easy_handle: ?*anyopaque,
        data: extern union {
            whatever: ?*anyopaque,
            result: CURLcode,
        },
    };

    pub const CURLSHcode = c_uint;
    pub const CURLSHE_OK: CURLSHcode = 0;
    pub const CURLSHE_NOT_BUILT_IN: CURLSHcode = 5;

    pub const CURLSHoption = c_uint;
    pub const CURLSHOPT_SHARE: CURLSHoption = 1;
    pub const CURL_LOCK_DATA_PSL: c_int = 6;

    pub const CURLU = anyopaque;
    pub const CURLUcode = c_uint;
    pub const CURLUE_OK: CURLUcode = 0;
    pub const CURLUE_BAD_HOSTNAME: CURLUcode = 21;
    pub const CURLUE_LACKS_IDN: CURLUcode = 30;

    pub const CURLUPart = c_uint;
    pub const CURLUPART_URL: CURLUPart = 0;
    pub const CURLUPART_HOST: CURLUPart = 5;

    pub const CURLU_PUNYCODE: c_uint = 1 << 12;
    pub const CURLU_PUNY2IDN: c_uint = 1 << 13;

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

extern fn curl_version() callconv(.c) ?[*:0]const u8;
extern fn curl_version_info(stamp: c.CURLversion) ?*const c.curl_version_info_data;
extern fn curl_free(p: ?*anyopaque) callconv(.c) void;
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
extern fn curl_multi_init() callconv(.c) ?*anyopaque;
extern fn curl_multi_cleanup(multi_handle: ?*anyopaque) callconv(.c) c.CURLMcode;
extern fn curl_multi_add_handle(multi_handle: ?*anyopaque, curl_handle: ?*anyopaque) callconv(.c) c.CURLMcode;
extern fn curl_multi_remove_handle(multi_handle: ?*anyopaque, curl_handle: ?*anyopaque) callconv(.c) c.CURLMcode;
extern fn curl_multi_perform(multi_handle: ?*anyopaque, running_handles: *c_int) callconv(.c) c.CURLMcode;
extern fn curl_multi_poll(
    multi_handle: ?*anyopaque,
    extra_fds: ?*anyopaque,
    extra_nfds: c_uint,
    timeout_ms: c_int,
    ret: ?*c_int,
) callconv(.c) c.CURLMcode;
extern fn curl_multi_info_read(multi_handle: ?*anyopaque, msgs_in_queue: *c_int) callconv(.c) ?*c.CURLMsg;
extern fn curl_slist_append(list: ?*c.curl_slist, data: [*:0]const u8) callconv(.c) ?*c.curl_slist;
extern fn curl_slist_free_all(list: ?*c.curl_slist) callconv(.c) void;
extern fn curl_share_init() callconv(.c) ?*anyopaque;
extern fn curl_share_setopt(sh: ?*anyopaque, option: c.CURLSHoption, ...) callconv(.c) c.CURLSHcode;
extern fn curl_share_cleanup(sh: ?*anyopaque) callconv(.c) c.CURLSHcode;
extern fn curl_url() callconv(.c) ?*c.CURLU;
extern fn curl_url_cleanup(handle: ?*c.CURLU) callconv(.c) void;
extern fn curl_url_set(handle: ?*c.CURLU, what: c.CURLUPart, part: ?[*:0]const u8, flags: c_uint) callconv(.c) c.CURLUcode;
extern fn curl_url_get(handle: ?*c.CURLU, what: c.CURLUPart, part: *?[*:0]u8, flags: c_uint) callconv(.c) c.CURLUcode;
extern fn Curl_ssl_supports(data: ?*anyopaque, ssl_option: c_uint) callconv(.c) bool;

fn hasFeature(names: [*:null]const ?[*:0]const u8, target: []const u8) bool {
    var idx: usize = 0;
    while (names[idx]) |feat_name| : (idx += 1) {
        if (std.mem.eql(u8, std.mem.span(feat_name), target)) return true;
    }
    return false;
}

test "curl_version_info feature flags match build options" {
    const info = curl_version_info(c.CURLVERSION_NOW) orelse return error.NullVersionInfo;

    try testing.expect((info.*.features & c.CURL_VERSION_ZSTD != 0) == backend_options.zstd);
    try testing.expect((info.*.features & c.CURL_VERSION_LIBZ != 0) == backend_options.zlib);
    try testing.expect((info.*.features & c.CURL_VERSION_BROTLI != 0) == backend_options.brotli);
    try testing.expect((info.*.features & c.CURL_VERSION_PSL != 0) == backend_options.psl);
    try testing.expect((info.*.features & c.CURL_VERSION_IDN != 0) == (backend_options.idn != .none));
    try testing.expect((info.*.features & c.CURL_VERSION_SSL != 0) == (backend_options.ssl != .none));
    try testing.expect((info.*.features & c.CURL_VERSION_HTTP2 != 0) == backend_options.nghttp2);
    try testing.expect((info.*.features & c.CURL_VERSION_HTTP3 != 0) == backend_options.http3);
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
    if (backend_options.brotli) {
        try testing.expect(info.*.brotli_version != null);
        try testing.expect(info.*.brotli_ver_num != 0);
    } else {
        try testing.expect(info.*.brotli_version == null);
        try testing.expectEqual(@as(c_uint, 0), info.*.brotli_ver_num);
    }
    if (backend_options.idn == .libidn2) {
        try testing.expect(info.*.libidn != null);
    } else {
        try testing.expect(info.*.libidn == null);
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
    if (backend_options.http3) {
        try testing.expect(info.*.quic_version != null);
        const qver = std.mem.span(info.*.quic_version.?);
        if (backend_options.quic == .ngtcp2) {
            try testing.expect(std.mem.indexOf(u8, qver, "ngtcp2/") != null);
            try testing.expect(std.mem.indexOf(u8, qver, "nghttp3/") != null);
        } else if (backend_options.quic == .quiche) {
            try testing.expect(std.mem.indexOf(u8, qver, "quiche/") != null);
        }
    } else {
        try testing.expect(info.*.quic_version == null);
    }
    if (backend_options.ares) {
        try testing.expect(info.*.ares != null);
        try testing.expect(info.*.ares_num > 0);
    } else {
        try testing.expect(info.*.ares == null);
        try testing.expectEqual(@as(c_int, 0), info.*.ares_num);
    }
    if (backend_options.ssh != .none) {
        try testing.expect(info.*.libssh_version != null);
        const ssh_ver = std.mem.span(info.*.libssh_version.?);
        if (backend_options.ssh == .libssh2) {
            try testing.expect(std.mem.startsWith(u8, ssh_ver, "libssh2/"));
        } else if (backend_options.ssh == .libssh) {
            try testing.expect(std.mem.startsWith(u8, ssh_ver, "libssh/"));
        }
    } else {
        try testing.expect(info.*.libssh_version == null);
    }
    if (info.*.protocols) |protos| {
        try testing.expectEqual(backend_options.ssh != .none, hasFeature(protos, "scp"));
        try testing.expectEqual(backend_options.ssh != .none, hasFeature(protos, "sftp"));
        try testing.expectEqual(backend_options.has_ldap, hasFeature(protos, "ldap"));
        try testing.expectEqual(backend_options.has_ldaps, hasFeature(protos, "ldaps"));
    }
}

test "curl_version_info feature_names list matches build options" {
    const info = curl_version_info(c.CURLVERSION_NOW) orelse return error.NullVersionInfo;
    const names = info.*.feature_names orelse return error.NullFeatureNames;

    const expect_apple_sectrust = backend_options.apple_sectrust orelse
        (backend_options.ssl == .openssl and builtin.os.tag.isDarwin());

    try testing.expectEqual(backend_options.ssl != .none and expect_apple_sectrust, hasFeature(names, "AppleSecTrust"));
    try testing.expectEqual(backend_options.ssl != .none, hasFeature(names, "SSL"));
    try testing.expectEqual(backend_options.ssl != .none, hasFeature(names, "HSTS"));
    try testing.expectEqual(backend_options.ssl != .none, hasFeature(names, "HTTPS-proxy"));
    try testing.expectEqual(backend_options.zstd, hasFeature(names, "zstd"));
    try testing.expectEqual(backend_options.zlib, hasFeature(names, "libz"));
    try testing.expectEqual(backend_options.brotli, hasFeature(names, "brotli"));
    try testing.expectEqual(backend_options.psl, hasFeature(names, "PSL"));
    try testing.expectEqual(backend_options.idn != .none, hasFeature(names, "IDN"));
    try testing.expectEqual(backend_options.nghttp2, hasFeature(names, "HTTP2"));
    try testing.expectEqual(backend_options.http3, hasFeature(names, "HTTP3"));
    try testing.expectEqual(backend_options.proxy_http3, hasFeature(names, "proxy-HTTP3"));
    try testing.expectEqual(backend_options.httpsrr, hasFeature(names, "HTTPSRR"));
    try testing.expectEqual(
        backend_options.ares and backend_options.httpsrr and backend_options.use_resolv_threaded,
        hasFeature(names, "asyn-rr"),
    );
    try testing.expectEqual(
        backend_options.use_resolv_ares or backend_options.use_resolv_threaded,
        hasFeature(names, "AsynchDNS"),
    );
}

test "curl_version string reflects enabled backends" {
    const ver_ptr = curl_version() orelse return error.NullVersionString;
    const ver = std.mem.span(ver_ptr);

    try testing.expectEqual(backend_options.brotli, std.mem.indexOf(u8, ver, "brotli/") != null);
    try testing.expectEqual(backend_options.psl, std.mem.indexOf(u8, ver, "libpsl/") != null);
    try testing.expectEqual(backend_options.idn == .libidn2, std.mem.indexOf(u8, ver, "libidn2/") != null);
    try testing.expectEqual(backend_options.idn == .winidn, std.mem.indexOf(u8, ver, "WinIDN") != null);
    try testing.expectEqual(backend_options.idn == .appleidn, std.mem.indexOf(u8, ver, "AppleIDN") != null);
    try testing.expectEqual(backend_options.zlib, std.mem.indexOf(u8, ver, "zlib/") != null);
    try testing.expectEqual(backend_options.zstd, std.mem.indexOf(u8, ver, "zstd/") != null);
    try testing.expectEqual(backend_options.nghttp2, std.mem.indexOf(u8, ver, "nghttp2/") != null);
    try testing.expectEqual(backend_options.quic == .ngtcp2, std.mem.indexOf(u8, ver, "ngtcp2/") != null);
    try testing.expectEqual(backend_options.quic == .ngtcp2, std.mem.indexOf(u8, ver, "nghttp3/") != null);
    try testing.expectEqual(backend_options.quic == .quiche, std.mem.indexOf(u8, ver, "quiche/") != null);
    try testing.expectEqual(backend_options.ares, std.mem.indexOf(u8, ver, "c-ares/") != null);
    try testing.expectEqual(backend_options.ssh == .libssh2, std.mem.indexOf(u8, ver, "libssh2/") != null);
    try testing.expectEqual(backend_options.ssh == .libssh, std.mem.indexOf(u8, ver, "libssh/") != null);
    try testing.expectEqual(
        backend_options.ldap == .openldap or backend_options.ldap == .ldap,
        std.mem.indexOf(u8, ver, "OpenLDAP") != null or std.mem.indexOf(u8, ver, "LDAP/") != null,
    );
    try testing.expectEqual(backend_options.ldap == .winldap, std.mem.indexOf(u8, ver, "WinLDAP") != null);
}

test "HTTP/3 CURLOPT_HTTP_VERSION and CURLOPT_PROXYTYPE match build options" {
    const easy = curl_easy_init() orelse return error.EasyInitFailed;
    defer curl_easy_cleanup(easy);

    const expected_h3: c.CURLcode = if (backend_options.http3) c.CURLE_OK else c.CURLE_NOT_BUILT_IN;
    try testing.expectEqual(expected_h3, curl_easy_setopt(easy, c.CURLOPT_HTTP_VERSION, c.CURL_HTTP_VERSION_3));
    try testing.expectEqual(expected_h3, curl_easy_setopt(easy, c.CURLOPT_HTTP_VERSION, c.CURL_HTTP_VERSION_3ONLY));

    const expected_proxy_h3: c.CURLcode = if (backend_options.proxy_http3) c.CURLE_OK else c.CURLE_NOT_BUILT_IN;
    try testing.expectEqual(expected_proxy_h3, curl_easy_setopt(easy, c.CURLOPT_PROXYTYPE, c.CURLPROXY_HTTPS3));
}

test "c-ares CURLOPT_DNS_* options match use_resolv_ares" {
    const easy = curl_easy_init() orelse return error.EasyInitFailed;
    defer curl_easy_cleanup(easy);

    const expected: c.CURLcode = if (backend_options.use_resolv_ares) c.CURLE_OK else c.CURLE_UNKNOWN_OPTION;
    try testing.expectEqual(expected, curl_easy_setopt(easy, c.CURLOPT_DNS_SERVERS, @as([*:0]const u8, "127.0.0.1")));
    try testing.expectEqual(expected, curl_easy_setopt(easy, c.CURLOPT_DNS_INTERFACE, @as([*:0]const u8, "lo")));
    try testing.expectEqual(expected, curl_easy_setopt(easy, c.CURLOPT_DNS_LOCAL_IP4, @as([*:0]const u8, "127.0.0.1")));
    try testing.expectEqual(expected, curl_easy_setopt(easy, c.CURLOPT_DNS_LOCAL_IP6, @as([*:0]const u8, "::1")));
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

    try testing.expectEqual(@as(usize, 4), std.enums.values(backends.IdnBackend).len);

    const libidn2_opts = backends.Options{ .idn = .libidn2 };
    try testing.expect(libidn2_opts.isValidForTarget(.linux));
    try testing.expect(libidn2_opts.isValidForTarget(.macos));
    try testing.expect(libidn2_opts.isValidForTarget(.windows));

    const winidn_opts = backends.Options{ .idn = .winidn };
    try testing.expect(winidn_opts.isValidForTarget(.windows));
    try testing.expect(!winidn_opts.isValidForTarget(.linux));
    try testing.expect(!winidn_opts.isValidForTarget(.macos));

    const appleidn_opts = backends.Options{ .idn = .appleidn };
    try testing.expect(appleidn_opts.isValidForTarget(.macos));
    try testing.expect(!appleidn_opts.isValidForTarget(.linux));
    try testing.expect(!appleidn_opts.isValidForTarget(.windows));
}

const loopback_tls = struct {
    // Root CA (CN=curl-zig-test-ca, valid 2020..2049)
    pub const test_ca_cert_pem: [:0]const u8 =
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
    pub const test_server_cert_pem: [:0]const u8 =
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

    pub const test_server_key_pem: [:0]const u8 =
        \\-----BEGIN EC PRIVATE KEY-----
        \\MHcCAQEEIOax4UqvKuoDsEOgbNodLAuWNZExlnybWGMLt9HPI72eoAoGCCqGSM49
        \\AwEHoUQDQgAEfb+VQUmx+rMEm6NmWcJSFJPexnqmARhavbFS0d+C58z2Y/mL3N/Q
        \\VLYPyljxTWy4xork4ahGoXW43APwuNsJvA==
        \\-----END EC PRIVATE KEY-----
        \\
    ;

    // Separate untrusted Root CA (CN=curl-zig-untrusted-ca, valid 2020..2049)
    pub const test_untrusted_ca_cert_pem: [:0]const u8 =
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

    pub const ossl = struct {
        pub extern fn TLS_server_method() callconv(.c) ?*const anyopaque;
        pub extern fn SSL_CTX_new(method: ?*const anyopaque) callconv(.c) ?*anyopaque;
        pub extern fn SSL_CTX_free(ctx: ?*anyopaque) callconv(.c) void;
        pub extern fn BIO_new_mem_buf(buf: ?*const anyopaque, len: c_int) callconv(.c) ?*anyopaque;
        pub extern fn BIO_free(bio: ?*anyopaque) callconv(.c) c_int;
        pub extern fn PEM_read_bio_X509(bio: ?*anyopaque, x: ?*?*anyopaque, cb: ?*const anyopaque, u: ?*anyopaque) callconv(.c) ?*anyopaque;
        pub extern fn PEM_read_bio_PrivateKey(bio: ?*anyopaque, x: ?*?*anyopaque, cb: ?*const anyopaque, u: ?*anyopaque) callconv(.c) ?*anyopaque;
        pub extern fn X509_free(x: ?*anyopaque) callconv(.c) void;
        pub extern fn EVP_PKEY_free(pkey: ?*anyopaque) callconv(.c) void;
        pub extern fn SSL_CTX_use_certificate(ctx: ?*anyopaque, x: ?*anyopaque) callconv(.c) c_int;
        pub extern fn SSL_CTX_use_PrivateKey(ctx: ?*anyopaque, pkey: ?*anyopaque) callconv(.c) c_int;
        pub extern fn SSL_new(ctx: ?*anyopaque) callconv(.c) ?*anyopaque;
        pub extern fn SSL_free(ssl: ?*anyopaque) callconv(.c) void;
        pub extern fn SSL_set_fd(ssl: ?*anyopaque, fd: c_int) callconv(.c) c_int;
        pub extern fn SSL_accept(ssl: ?*anyopaque) callconv(.c) c_int;
        pub extern fn SSL_read(ssl: ?*anyopaque, buf: [*]u8, num: c_int) callconv(.c) c_int;
        pub extern fn SSL_write(ssl: ?*anyopaque, buf: [*]const u8, num: c_int) callconv(.c) c_int;
        pub extern fn SSL_shutdown(ssl: ?*anyopaque) callconv(.c) c_int;
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

    const gtls = struct {
        const GNUTLS_SERVER: c_uint = 1;
        const GNUTLS_CRD_CERTIFICATE: c_uint = 1;
        const GNUTLS_X509_FMT_PEM: c_uint = 1;
        const GNUTLS_SHUT_WR: c_uint = 1;
        const GNUTLS_E_AGAIN: c_int = -28;
        const GNUTLS_E_INTERRUPTED: c_int = -52;

        const gnutls_datum_t = extern struct {
            data: ?[*]u8 = null,
            size: c_uint = 0,
        };

        extern fn gnutls_certificate_allocate_credentials(res: *?*anyopaque) callconv(.c) c_int;
        extern fn gnutls_certificate_free_credentials(sc: ?*anyopaque) callconv(.c) void;
        extern fn gnutls_certificate_set_x509_key_mem(
            res: ?*anyopaque,
            cert: *const gnutls_datum_t,
            key: *const gnutls_datum_t,
            fmt: c_uint,
        ) callconv(.c) c_int;
        extern fn gnutls_init(session: *?*anyopaque, flags: c_uint) callconv(.c) c_int;
        extern fn gnutls_deinit(session: ?*anyopaque) callconv(.c) void;
        extern fn gnutls_priority_set_direct(
            session: ?*anyopaque,
            priorities: [*:0]const u8,
            err_pos: ?*?[*:0]const u8,
        ) callconv(.c) c_int;
        extern fn gnutls_credentials_set(session: ?*anyopaque, cred_type: c_uint, cred: ?*anyopaque) callconv(.c) c_int;
        extern fn gnutls_transport_set_int2(session: ?*anyopaque, r: c_int, s: c_int) callconv(.c) void;
        extern fn gnutls_handshake(session: ?*anyopaque) callconv(.c) c_int;
        extern fn gnutls_record_recv(session: ?*anyopaque, data: ?*anyopaque, data_size: usize) callconv(.c) isize;
        extern fn gnutls_record_send(session: ?*anyopaque, data: ?*const anyopaque, data_size: usize) callconv(.c) isize;
        extern fn gnutls_bye(session: ?*anyopaque, how: c_uint) callconv(.c) c_int;
    };

    const rls = struct {
        const RUSTLS_RESULT_OK: c_uint = 7000;
        const RUSTLS_RESULT_PLAINTEXT_EMPTY: c_uint = 7011;
        const EINVAL_VAL: c_int = 22;

        const ReadCb = ?*const fn (userdata: ?*anyopaque, buf: [*]u8, n: usize, out_n: *usize) callconv(.c) c_int;
        const WriteCb = ?*const fn (userdata: ?*anyopaque, buf: [*]const u8, n: usize, out_n: *usize) callconv(.c) c_int;

        extern fn rustls_certified_key_build(
            cert_chain: [*]const u8,
            cert_chain_len: usize,
            private_key: [*]const u8,
            private_key_len: usize,
            certified_key_out: *?*const anyopaque,
        ) callconv(.c) c_uint;
        extern fn rustls_certified_key_free(key: ?*const anyopaque) callconv(.c) void;
        extern fn rustls_server_config_builder_new() callconv(.c) ?*anyopaque;
        extern fn rustls_server_config_builder_free(config: ?*anyopaque) callconv(.c) void;
        extern fn rustls_server_config_builder_set_certified_keys(
            builder: *anyopaque,
            certified_keys: [*]const *const anyopaque,
            certified_keys_len: usize,
        ) callconv(.c) c_uint;
        extern fn rustls_server_config_builder_build(
            builder: *anyopaque,
            config_out: *?*const anyopaque,
        ) callconv(.c) c_uint;
        extern fn rustls_server_config_free(config: ?*const anyopaque) callconv(.c) void;
        extern fn rustls_server_connection_new(
            config: *const anyopaque,
            conn_out: *?*anyopaque,
        ) callconv(.c) c_uint;
        extern fn rustls_connection_free(conn: ?*anyopaque) callconv(.c) void;
        extern fn rustls_connection_is_handshaking(conn: *const anyopaque) callconv(.c) bool;
        extern fn rustls_connection_wants_read(conn: *const anyopaque) callconv(.c) bool;
        extern fn rustls_connection_wants_write(conn: *const anyopaque) callconv(.c) bool;
        extern fn rustls_connection_read_tls(
            conn: *anyopaque,
            cb: ReadCb,
            userdata: ?*anyopaque,
            out_n: *usize,
        ) callconv(.c) c_int;
        extern fn rustls_connection_write_tls(
            conn: *anyopaque,
            cb: WriteCb,
            userdata: ?*anyopaque,
            out_n: *usize,
        ) callconv(.c) c_int;
        extern fn rustls_connection_process_new_packets(conn: *anyopaque) callconv(.c) c_uint;
        extern fn rustls_connection_read(
            conn: *anyopaque,
            buf: [*]u8,
            count: usize,
            out_n: *usize,
        ) callconv(.c) c_uint;
        extern fn rustls_connection_write(
            conn: *anyopaque,
            buf: [*]const u8,
            count: usize,
            out_n: *usize,
        ) callconv(.c) c_uint;
        extern fn rustls_connection_send_close_notify(conn: *anyopaque) callconv(.c) void;

        fn srvReadCb(userdata: ?*anyopaque, buf: [*]u8, n: usize, out_n: *usize) callconv(.c) c_int {
            const fd_ptr: *const c_int = @ptrCast(@alignCast(userdata.?));
            const r = sock_c.recv(fd_ptr.*, buf, n, 0);
            if (r < 0) {
                out_n.* = 0;
                return EINVAL_VAL;
            }
            out_n.* = @intCast(r);
            return 0;
        }

        fn srvWriteCb(userdata: ?*anyopaque, buf: [*]const u8, n: usize, out_n: *usize) callconv(.c) c_int {
            const fd_ptr: *const c_int = @ptrCast(@alignCast(userdata.?));
            const w = sock_c.send(fd_ptr.*, buf, n, 0);
            if (w < 0) {
                out_n.* = 0;
                return EINVAL_VAL;
            }
            out_n.* = @intCast(w);
            return 0;
        }
    };

    const wssl = struct {
        const SSL_FILETYPE_PEM: c_int = 1;
        const WOLFSSL_SUCCESS: c_int = 1;

        extern fn wolfSSL_Init() callconv(.c) c_int;
        extern fn wolfSSLv23_server_method() callconv(.c) ?*anyopaque;
        extern fn wolfSSL_CTX_new(method: ?*anyopaque) callconv(.c) ?*anyopaque;
        extern fn wolfSSL_CTX_free(ctx: ?*anyopaque) callconv(.c) void;
        extern fn wolfSSL_CTX_use_certificate_buffer(
            ctx: ?*anyopaque,
            in: [*]const u8,
            sz: c_long,
            format: c_int,
        ) callconv(.c) c_int;
        extern fn wolfSSL_CTX_use_PrivateKey_buffer(
            ctx: ?*anyopaque,
            in: [*]const u8,
            sz: c_long,
            format: c_int,
        ) callconv(.c) c_int;
        extern fn wolfSSL_new(ctx: ?*anyopaque) callconv(.c) ?*anyopaque;
        extern fn wolfSSL_free(ssl: ?*anyopaque) callconv(.c) void;
        extern fn wolfSSL_set_fd(ssl: ?*anyopaque, fd: c_int) callconv(.c) c_int;
        extern fn wolfSSL_accept(ssl: ?*anyopaque) callconv(.c) c_int;
        extern fn wolfSSL_read(ssl: ?*anyopaque, data: [*]u8, sz: c_int) callconv(.c) c_int;
        extern fn wolfSSL_write(ssl: ?*anyopaque, data: [*]const u8, sz: c_int) callconv(.c) c_int;
        extern fn wolfSSL_shutdown(ssl: ?*anyopaque) callconv(.c) c_int;
    };

    pub const sock_c = struct {
        pub const AF_INET: c_int = 2;
        pub const SOCK_STREAM: c_int = 1;
        pub const SOL_SOCKET: c_int = 1;
        pub const SO_REUSEADDR: c_int = 2;
        pub const SO_RCVTIMEO: c_int = 20;
        pub const SO_SNDTIMEO: c_int = 21;

        pub const sockaddr_in = extern struct {
            sin_family: u16 = AF_INET,
            sin_port: u16 = 0,
            sin_addr: u32 = 0,
            sin_zero: [8]u8 = @splat(0),
        };

        pub const timeval = extern struct {
            tv_sec: c_long,
            tv_usec: c_long,
        };

        pub extern "c" fn socket(domain: c_int, sock_type: c_int, protocol: c_int) c_int;
        pub extern "c" fn setsockopt(sockfd: c_int, level: c_int, optname: c_int, optval: *const anyopaque, optlen: u32) c_int;
        pub extern "c" fn bind(sockfd: c_int, addr: *const sockaddr_in, addrlen: u32) c_int;
        pub extern "c" fn listen(sockfd: c_int, backlog: c_int) c_int;
        pub extern "c" fn getsockname(sockfd: c_int, addr: *sockaddr_in, addrlen: *u32) c_int;
        pub extern "c" fn accept(sockfd: c_int, addr: ?*anyopaque, addrlen: ?*u32) c_int;
        pub extern "c" fn recv(sockfd: c_int, buf: [*]u8, len: usize, flags: c_int) isize;
        pub extern "c" fn send(sockfd: c_int, buf: [*]const u8, len: usize, flags: c_int) isize;
        pub extern "c" fn close(fd: c_int) c_int;
    };

    const http_response = "HTTP/1.1 200 OK\r\nContent-Length: 2\r\nConnection: close\r\n\r\nok";

    pub fn setSocketTimeouts(fd: c_int) void {
        if (builtin.os.tag == .linux) {
            const tv = sock_c.timeval{ .tv_sec = 5, .tv_usec = 0 };
            _ = sock_c.setsockopt(fd, sock_c.SOL_SOCKET, sock_c.SO_RCVTIMEO, &tv, @sizeOf(sock_c.timeval));
            _ = sock_c.setsockopt(fd, sock_c.SOL_SOCKET, sock_c.SO_SNDTIMEO, &tv, @sizeOf(sock_c.timeval));
        }
    }

    pub fn openLoopbackListener(port_out: *u16) !c_int {
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

    fn serveGnuTlsOnce(listen_fd: c_int) void {
        const client_fd = sock_c.accept(listen_fd, null, null);
        if (client_fd < 0) return;
        defer _ = sock_c.close(client_fd);
        setSocketTimeouts(client_fd);

        var creds: ?*anyopaque = null;
        if (gtls.gnutls_certificate_allocate_credentials(&creds) != 0) return;
        defer gtls.gnutls_certificate_free_credentials(creds);

        const cert_d = gtls.gnutls_datum_t{
            .data = @constCast(test_server_cert_pem.ptr),
            .size = @intCast(test_server_cert_pem.len),
        };
        const key_d = gtls.gnutls_datum_t{
            .data = @constCast(test_server_key_pem.ptr),
            .size = @intCast(test_server_key_pem.len),
        };
        if (gtls.gnutls_certificate_set_x509_key_mem(creds, &cert_d, &key_d, gtls.GNUTLS_X509_FMT_PEM) < 0) return;

        var session: ?*anyopaque = null;
        if (gtls.gnutls_init(&session, gtls.GNUTLS_SERVER) != 0) return;
        defer gtls.gnutls_deinit(session);

        if (gtls.gnutls_priority_set_direct(session, "NORMAL", null) != 0) return;
        if (gtls.gnutls_credentials_set(session, gtls.GNUTLS_CRD_CERTIFICATE, creds) != 0) return;

        gtls.gnutls_transport_set_int2(session, client_fd, client_fd);

        while (true) {
            const rc = gtls.gnutls_handshake(session);
            if (rc == 0) break;
            if (rc == gtls.GNUTLS_E_AGAIN or rc == gtls.GNUTLS_E_INTERRUPTED) continue;
            return;
        }

        var req_buf: [1024]u8 = undefined;
        const nread = gtls.gnutls_record_recv(session, &req_buf, req_buf.len);
        if (nread > 0) {
            _ = gtls.gnutls_record_send(session, http_response.ptr, http_response.len);
            _ = gtls.gnutls_bye(session, gtls.GNUTLS_SHUT_WR);
        }
    }

    fn serveRustlsOnce(listen_fd: c_int) void {
        var client_fd = sock_c.accept(listen_fd, null, null);
        if (client_fd < 0) return;
        defer _ = sock_c.close(client_fd);
        setSocketTimeouts(client_fd);

        var ckey: ?*const anyopaque = null;
        if (rls.rustls_certified_key_build(
            test_server_cert_pem.ptr,
            test_server_cert_pem.len,
            test_server_key_pem.ptr,
            test_server_key_pem.len,
            &ckey,
        ) != rls.RUSTLS_RESULT_OK or ckey == null) return;
        defer rls.rustls_certified_key_free(ckey);

        const sbuilder = rls.rustls_server_config_builder_new() orelse return;
        const ckeys = [1]*const anyopaque{ckey.?};
        if (rls.rustls_server_config_builder_set_certified_keys(sbuilder, &ckeys, 1) != rls.RUSTLS_RESULT_OK) {
            rls.rustls_server_config_builder_free(sbuilder);
            return;
        }

        var sconfig: ?*const anyopaque = null;
        if (rls.rustls_server_config_builder_build(sbuilder, &sconfig) != rls.RUSTLS_RESULT_OK or sconfig == null) {
            return;
        }
        defer rls.rustls_server_config_free(sconfig);

        var sconn: ?*anyopaque = null;
        if (rls.rustls_server_connection_new(sconfig.?, &sconn) != rls.RUSTLS_RESULT_OK or sconn == null) return;
        defer rls.rustls_connection_free(sconn);

        const conn = sconn.?;
        while (rls.rustls_connection_is_handshaking(conn)) {
            while (rls.rustls_connection_wants_write(conn)) {
                var nw: usize = 0;
                if (rls.rustls_connection_write_tls(conn, rls.srvWriteCb, &client_fd, &nw) != 0) return;
            }
            if (rls.rustls_connection_wants_read(conn)) {
                var nr: usize = 0;
                if (rls.rustls_connection_read_tls(conn, rls.srvReadCb, &client_fd, &nr) != 0 or nr == 0) return;
                if (rls.rustls_connection_process_new_packets(conn) != rls.RUSTLS_RESULT_OK) {
                    while (rls.rustls_connection_wants_write(conn)) {
                        var nw: usize = 0;
                        _ = rls.rustls_connection_write_tls(conn, rls.srvWriteCb, &client_fd, &nw);
                    }
                    return;
                }
            }
        }
        while (rls.rustls_connection_wants_write(conn)) {
            var nw: usize = 0;
            if (rls.rustls_connection_write_tls(conn, rls.srvWriteCb, &client_fd, &nw) != 0) return;
        }

        var req_buf: [512]u8 = undefined;
        var req_n: usize = 0;
        while (req_n == 0) {
            if (rls.rustls_connection_wants_read(conn)) {
                var nr: usize = 0;
                if (rls.rustls_connection_read_tls(conn, rls.srvReadCb, &client_fd, &nr) != 0 or nr == 0) return;
                if (rls.rustls_connection_process_new_packets(conn) != rls.RUSTLS_RESULT_OK) return;
            }
            const rr = rls.rustls_connection_read(conn, &req_buf, req_buf.len, &req_n);
            if (rr == rls.RUSTLS_RESULT_PLAINTEXT_EMPTY) continue;
            if (rr != rls.RUSTLS_RESULT_OK) return;
        }

        var plain_nw: usize = 0;
        if (rls.rustls_connection_write(conn, http_response.ptr, http_response.len, &plain_nw) != rls.RUSTLS_RESULT_OK) return;
        rls.rustls_connection_send_close_notify(conn);
        while (rls.rustls_connection_wants_write(conn)) {
            var nw: usize = 0;
            if (rls.rustls_connection_write_tls(conn, rls.srvWriteCb, &client_fd, &nw) != 0) return;
        }
    }

    fn serveWolfSslOnce(listen_fd: c_int) void {
        const client_fd = sock_c.accept(listen_fd, null, null);
        if (client_fd < 0) return;
        defer _ = sock_c.close(client_fd);
        setSocketTimeouts(client_fd);

        _ = wssl.wolfSSL_Init();

        const method = wssl.wolfSSLv23_server_method() orelse return;
        const ctx = wssl.wolfSSL_CTX_new(method) orelse return;
        defer wssl.wolfSSL_CTX_free(ctx);

        if (wssl.wolfSSL_CTX_use_certificate_buffer(
            ctx,
            test_server_cert_pem.ptr,
            @intCast(test_server_cert_pem.len),
            wssl.SSL_FILETYPE_PEM,
        ) != wssl.WOLFSSL_SUCCESS) return;

        if (wssl.wolfSSL_CTX_use_PrivateKey_buffer(
            ctx,
            test_server_key_pem.ptr,
            @intCast(test_server_key_pem.len),
            wssl.SSL_FILETYPE_PEM,
        ) != wssl.WOLFSSL_SUCCESS) return;

        const ssl = wssl.wolfSSL_new(ctx) orelse return;
        defer wssl.wolfSSL_free(ssl);
        if (wssl.wolfSSL_set_fd(ssl, client_fd) != wssl.WOLFSSL_SUCCESS) return;

        if (wssl.wolfSSL_accept(ssl) != wssl.WOLFSSL_SUCCESS) return;

        var req_buf: [1024]u8 = undefined;
        const nread = wssl.wolfSSL_read(ssl, &req_buf, @intCast(req_buf.len));
        if (nread > 0) {
            _ = wssl.wolfSSL_write(ssl, http_response.ptr, @intCast(http_response.len));
            _ = wssl.wolfSSL_shutdown(ssl);
        }
    }

    fn serveOnce(listen_fd: c_int) void {
        switch (backend_options.ssl) {
            .openssl => serveOpenSslOnce(listen_fd),
            .mbedtls => serveMbedTlsOnce(listen_fd),
            .gnutls => serveGnuTlsOnce(listen_fd),
            .rustls => serveRustlsOnce(listen_fd),
            .wolfssl => serveWolfSslOnce(listen_fd),
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
    if (comptime (backend_options.ssl == .none or backend_options.ssl == .schannel)) return;

    // 1a. Trusted CA via CURLOPT_CAINFO_BLOB + CURLOPT_CERTINFO -> CURLE_OK & populated certinfo chain
    {
        const want_certinfo = backend_options.ssl != .wolfssl;
        const res = try loopback_tls.runLoopbackTransfer(.{
            .ca_pem_blob = loopback_tls.test_ca_cert_pem,
            .certinfo = want_certinfo,
        });
        try testing.expectEqual(c.CURLE_OK, res.code);
        try testing.expectEqual(@as(c_long, 200), res.status_code);
        try testing.expect(res.body_ok);
        if (want_certinfo) {
            try testing.expect(res.certinfo_certs >= 1);
            try testing.expect(res.certinfo_has_subject);
        }
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
    if (backend_options.ssl != .rustls) {
        const res = try loopback_tls.runLoopbackTransfer(.{
            .ca_pem_blob = loopback_tls.test_ca_cert_pem,
            .pinnedpubkey = loopback_tls.test_server_pubkey_pin,
        });
        try testing.expectEqual(c.CURLE_OK, res.code);
        try testing.expectEqual(@as(c_long, 200), res.status_code);
        try testing.expect(res.body_ok);
    }

    // 4b. CURLOPT_PINNEDPUBLICKEY with mismatched sha256//... pin -> CURLE_SSL_PINNEDPUBKEYNOTMATCH
    if (backend_options.ssl != .rustls) {
        const res = try loopback_tls.runLoopbackTransfer(.{
            .ca_pem_blob = loopback_tls.test_ca_cert_pem,
            .pinnedpubkey = loopback_tls.test_wrong_pubkey_pin,
        });
        try testing.expectEqual(c.CURLE_SSL_PINNEDPUBKEYNOTMATCH, res.code);
    }
}

const loopback_http = struct {
    const net = std.Io.net;

    const BodySink = struct {
        buf: [4096]u8 = undefined,
        len: usize = 0,

        fn slice(self: *const BodySink) []const u8 {
            return self.buf[0..self.len];
        }
    };

    fn writeCallback(
        ptr: [*c]const u8,
        size: usize,
        nmemb: usize,
        userdata: ?*anyopaque,
    ) callconv(.c) usize {
        const total = size * nmemb;
        const sink: *BodySink = @ptrCast(@alignCast(userdata orelse return 0));
        if (sink.len + total <= sink.buf.len) {
            @memcpy(sink.buf[sink.len .. sink.len + total], ptr[0..total]);
            sink.len += total;
        }
        return total;
    }

    const SingleResponseServer = struct {
        server: *net.Server,
        response: []const u8,
        chunks: ?[]const []const u8 = null,
        request_buf: [2048]u8 = undefined,
        request_len: usize = 0,

        fn run(ctx: *SingleResponseServer) void {
            const io = std.Io.Threaded.global_single_threaded.io();
            var stream = ctx.server.accept(io) catch return;
            defer stream.close(io);

            var rbuf: [1024]u8 = undefined;
            var reader = stream.reader(io, &rbuf);
            while (ctx.request_len < ctx.request_buf.len) {
                var slice = [_][]u8{ctx.request_buf[ctx.request_len..]};
                const n = reader.interface.readVec(&slice) catch break;
                if (n == 0) break;
                ctx.request_len += n;
                if (std.mem.indexOf(u8, ctx.request_buf[0..ctx.request_len], "\r\n\r\n") != null) break;
            }

            var wbuf: [1024]u8 = undefined;
            var writer = stream.writer(io, &wbuf);
            writer.interface.writeAll(ctx.response) catch return;
            writer.interface.flush() catch return;

            if (ctx.chunks) |chunks| {
                for (chunks) |chunk| {
                    std.Thread.yield() catch {};
                    writer.interface.writeAll(chunk) catch return;
                    writer.interface.flush() catch return;
                }
            }
        }

        fn requestSlice(self: *const SingleResponseServer) []const u8 {
            return self.request_buf[0..self.request_len];
        }
    };

    const SequentialServer = struct {
        server: *net.Server,
        responses: []const []const u8,

        fn run(ctx: *SequentialServer) void {
            const io = std.Io.Threaded.global_single_threaded.io();
            for (ctx.responses) |resp| {
                var stream = ctx.server.accept(io) catch return;
                defer stream.close(io);

                var req_buf: [2048]u8 = undefined;
                var req_len: usize = 0;
                var rbuf: [1024]u8 = undefined;
                var reader = stream.reader(io, &rbuf);
                while (req_len < req_buf.len) {
                    var slice = [_][]u8{req_buf[req_len..]};
                    const n = reader.interface.readVec(&slice) catch break;
                    if (n == 0) break;
                    req_len += n;
                    if (std.mem.indexOf(u8, req_buf[0..req_len], "\r\n\r\n") != null) break;
                }

                var wbuf: [1024]u8 = undefined;
                var writer = stream.writer(io, &wbuf);
                writer.interface.writeAll(resp) catch return;
                writer.interface.flush() catch return;
            }
        }
    };

    fn hasAcceptEncodingToken(raw_request: []const u8, token: []const u8) bool {
        var lines = std.mem.splitSequence(u8, raw_request, "\r\n");
        while (lines.next()) |line| {
            const prefix = "Accept-Encoding:";
            if (line.len >= prefix.len and std.ascii.eqlIgnoreCase(line[0..prefix.len], prefix)) {
                const value = std.mem.trim(u8, line[prefix.len..], " \t");
                var parts = std.mem.splitScalar(u8, value, ',');
                while (parts.next()) |part| {
                    const trimmed = std.mem.trim(u8, part, " \t");
                    if (std.mem.eql(u8, trimmed, token)) return true;
                }
            }
        }
        return false;
    }

    fn hasCookie(list: ?*c.curl_slist, name: []const u8, value: []const u8) bool {
        var cur = list;
        while (cur) |node| : (cur = node.next) {
            const data_ptr = node.data orelse continue;
            const line = std.mem.span(data_ptr);
            var cols = std.mem.splitScalar(u8, line, '\t');
            var col_idx: usize = 0;
            var matched_name = false;
            while (cols.next()) |col| : (col_idx += 1) {
                if (col_idx == 5 and std.mem.eql(u8, col, name)) {
                    matched_name = true;
                } else if (col_idx == 6 and matched_name and std.mem.eql(u8, col, value)) {
                    return true;
                }
            }
        }
        return false;
    }

    fn hasCookieLinePrefix(list: ?*c.curl_slist, prefix: []const u8, name: []const u8, value: []const u8) bool {
        var cur = list;
        while (cur) |node| : (cur = node.next) {
            const data_ptr = node.data orelse continue;
            const line = std.mem.span(data_ptr);
            if (!std.mem.startsWith(u8, line, prefix)) continue;
            var cols = std.mem.splitScalar(u8, line, '\t');
            var col_idx: usize = 0;
            var matched_name = false;
            while (cols.next()) |col| : (col_idx += 1) {
                if (col_idx == 5 and std.mem.eql(u8, col, name)) {
                    matched_name = true;
                } else if (col_idx == 6 and matched_name and std.mem.eql(u8, col, value)) {
                    return true;
                }
            }
        }
        return false;
    }

    fn bufPrintZ(buf: []u8, comptime fmt: []const u8, args: anytype) ![*:0]const u8 {
        const s = try std.fmt.bufPrint(buf, fmt ++ "\x00", args);
        return @ptrCast(s.ptr);
    }

    fn ensureUtf8Locale() void {
        if (comptime (builtin.os.tag != .windows)) {
            const c_locale = struct {
                extern fn setlocale(category: c_int, locale: ?[*:0]const u8) callconv(.c) ?[*:0]u8;
            };
            _ = c_locale.setlocale(0, "C.UTF-8") orelse
                c_locale.setlocale(0, "en_US.UTF-8") orelse
                c_locale.setlocale(0, "");
        }
    }
};

test "Brotli Accept-Encoding negotiation and Content-Encoding decompression" {
    const io = std.Io.Threaded.global_single_threaded.io();
    const bind_addr = try std.Io.net.IpAddress.parseIp4("127.0.0.1", 0);

    // 1. Automatic CURLOPT_ACCEPT_ENCODING = "" includes "br" iff backend_options.brotli is true
    {
        var server = try bind_addr.listen(io, .{ .reuse_address = true });
        defer server.deinit(io);
        const port = server.socket.address.getPort();

        var srv_ctx = loopback_http.SingleResponseServer{
            .server = &server,
            .response = "HTTP/1.1 200 OK\r\nContent-Length: 2\r\nConnection: close\r\n\r\nok",
        };
        const thread = try std.Thread.spawn(.{}, loopback_http.SingleResponseServer.run, .{&srv_ctx});
        defer thread.join();

        const easy = curl_easy_init() orelse return error.EasyInitFailed;
        defer curl_easy_cleanup(easy);

        var url_buf: [128]u8 = undefined;
        const url = try loopback_http.bufPrintZ(&url_buf, "http://127.0.0.1:{d}/accept-encoding", .{port});
        var sink = loopback_http.BodySink{};

        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_NOSIGNAL, @as(c_long, 1)));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_TIMEOUT_MS, @as(c_long, 10_000)));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_URL, url));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_ACCEPT_ENCODING, @as([*:0]const u8, "")));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_WRITEFUNCTION, &loopback_http.writeCallback));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_WRITEDATA, @as(?*anyopaque, @ptrCast(&sink))));

        try testing.expectEqual(c.CURLE_OK, curl_easy_perform(easy));
        try testing.expectEqualStrings("ok", sink.slice());
        try testing.expectEqual(
            backend_options.brotli,
            loopback_http.hasAcceptEncodingToken(srv_ctx.requestSlice(), "br"),
        );
    }

    if (!backend_options.brotli) return;

    // 23-byte Brotli stream encoding "hello brotlihello brotlihello brotli" (36 bytes)
    const br_payload = "\x1b\x23\x00\x00\x04\x1c\x87\xd7\xbb\xfb\xee\x8b\x88\x54\x83\xd0\x53\x8b\xe7\xf4\x42\xeb\x63";
    const expected_plain = "hello brotlihello brotlihello brotli";

    // 2. Single-chunk Content-Encoding: br response decompresses to original plaintext
    {
        var server = try bind_addr.listen(io, .{ .reuse_address = true });
        defer server.deinit(io);
        const port = server.socket.address.getPort();

        const resp = "HTTP/1.1 200 OK\r\nContent-Encoding: br\r\nContent-Length: 23\r\nConnection: close\r\n\r\n" ++ br_payload;
        var srv_ctx = loopback_http.SingleResponseServer{
            .server = &server,
            .response = resp,
        };
        const thread = try std.Thread.spawn(.{}, loopback_http.SingleResponseServer.run, .{&srv_ctx});
        defer thread.join();

        const easy = curl_easy_init() orelse return error.EasyInitFailed;
        defer curl_easy_cleanup(easy);

        var url_buf: [128]u8 = undefined;
        const url = try loopback_http.bufPrintZ(&url_buf, "http://127.0.0.1:{d}/single-br", .{port});
        var sink = loopback_http.BodySink{};

        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_NOSIGNAL, @as(c_long, 1)));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_TIMEOUT_MS, @as(c_long, 10_000)));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_URL, url));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_ACCEPT_ENCODING, @as([*:0]const u8, "br")));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_WRITEFUNCTION, &loopback_http.writeCallback));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_WRITEDATA, @as(?*anyopaque, @ptrCast(&sink))));

        try testing.expectEqual(c.CURLE_OK, curl_easy_perform(easy));
        try testing.expectEqualStrings(expected_plain, sink.slice());
    }

    // 3. Multi-chunk streaming Content-Encoding: br response decompresses to original plaintext
    {
        var server = try bind_addr.listen(io, .{ .reuse_address = true });
        defer server.deinit(io);
        const port = server.socket.address.getPort();

        const chunks = [_][]const u8{
            br_payload[0..5],
            br_payload[5..13],
            br_payload[13..23],
        };
        var srv_ctx = loopback_http.SingleResponseServer{
            .server = &server,
            .response = "HTTP/1.1 200 OK\r\nContent-Encoding: br\r\nContent-Length: 23\r\nConnection: close\r\n\r\n",
            .chunks = &chunks,
        };
        const thread = try std.Thread.spawn(.{}, loopback_http.SingleResponseServer.run, .{&srv_ctx});
        defer thread.join();

        const easy = curl_easy_init() orelse return error.EasyInitFailed;
        defer curl_easy_cleanup(easy);

        var url_buf: [128]u8 = undefined;
        const url = try loopback_http.bufPrintZ(&url_buf, "http://127.0.0.1:{d}/chunked-br", .{port});
        var sink = loopback_http.BodySink{};

        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_NOSIGNAL, @as(c_long, 1)));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_TIMEOUT_MS, @as(c_long, 10_000)));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_URL, url));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_ACCEPT_ENCODING, @as([*:0]const u8, "br")));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_WRITEFUNCTION, &loopback_http.writeCallback));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_WRITEDATA, @as(?*anyopaque, @ptrCast(&sink))));

        try testing.expectEqual(c.CURLE_OK, curl_easy_perform(easy));
        try testing.expectEqualStrings(expected_plain, sink.slice());
    }

    // 4. Corrupt Content-Encoding: br response returns CURLE_BAD_CONTENT_ENCODING
    {
        var server = try bind_addr.listen(io, .{ .reuse_address = true });
        defer server.deinit(io);
        const port = server.socket.address.getPort();

        var srv_ctx = loopback_http.SingleResponseServer{
            .server = &server,
            .response = "HTTP/1.1 200 OK\r\nContent-Encoding: br\r\nContent-Length: 8\r\nConnection: close\r\n\r\n\xff\xff\xff\xff\xff\xff\xff\xff",
        };
        const thread = try std.Thread.spawn(.{}, loopback_http.SingleResponseServer.run, .{&srv_ctx});
        defer thread.join();

        const easy = curl_easy_init() orelse return error.EasyInitFailed;
        defer curl_easy_cleanup(easy);

        var url_buf: [128]u8 = undefined;
        const url = try loopback_http.bufPrintZ(&url_buf, "http://127.0.0.1:{d}/corrupt-br", .{port});
        var sink = loopback_http.BodySink{};

        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_NOSIGNAL, @as(c_long, 1)));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_TIMEOUT_MS, @as(c_long, 10_000)));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_URL, url));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_ACCEPT_ENCODING, @as([*:0]const u8, "br")));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_WRITEFUNCTION, &loopback_http.writeCallback));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_WRITEDATA, @as(?*anyopaque, @ptrCast(&sink))));

        try testing.expectEqual(c.CURLE_BAD_CONTENT_ENCODING, curl_easy_perform(easy));
    }

    // 5. Trailing garbage bytes after a completed Brotli stream return CURLE_WRITE_ERROR
    {
        var server = try bind_addr.listen(io, .{ .reuse_address = true });
        defer server.deinit(io);
        const port = server.socket.address.getPort();

        const resp = "HTTP/1.1 200 OK\r\nContent-Encoding: br\r\nContent-Length: 30\r\nConnection: close\r\n\r\n" ++ br_payload ++ "GARBAGE";
        var srv_ctx = loopback_http.SingleResponseServer{
            .server = &server,
            .response = resp,
        };
        const thread = try std.Thread.spawn(.{}, loopback_http.SingleResponseServer.run, .{&srv_ctx});
        defer thread.join();

        const easy = curl_easy_init() orelse return error.EasyInitFailed;
        defer curl_easy_cleanup(easy);

        var url_buf: [128]u8 = undefined;
        const url = try loopback_http.bufPrintZ(&url_buf, "http://127.0.0.1:{d}/trailing-garbage-br", .{port});
        var sink = loopback_http.BodySink{};

        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_NOSIGNAL, @as(c_long, 1)));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_TIMEOUT_MS, @as(c_long, 10_000)));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_URL, url));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_ACCEPT_ENCODING, @as([*:0]const u8, "br")));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_WRITEFUNCTION, &loopback_http.writeCallback));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_WRITEDATA, @as(?*anyopaque, @ptrCast(&sink))));

        try testing.expectEqual(c.CURLE_WRITE_ERROR, curl_easy_perform(easy));
    }
}

test "PSL share lock option and cookie domain filtering for multi-label public suffix" {
    // 1. curl_share_setopt(sh, CURLSHOPT_SHARE, CURL_LOCK_DATA_PSL) matches backend_options.psl
    {
        const sh = curl_share_init() orelse return error.ShareInitFailed;
        defer _ = curl_share_cleanup(sh);

        const rc = curl_share_setopt(sh, c.CURLSHOPT_SHARE, @as(c_int, c.CURL_LOCK_DATA_PSL));
        try testing.expectEqual(
            if (backend_options.psl) c.CURLSHE_OK else c.CURLSHE_NOT_BUILT_IN,
            rc,
        );
    }

    // 2. Loopback HTTP cookie engine test with multi-label public suffix co.uk
    const io = std.Io.Threaded.global_single_threaded.io();
    const bind_addr = try std.Io.net.IpAddress.parseIp4("127.0.0.1", 0);
    var server = try bind_addr.listen(io, .{ .reuse_address = true });
    defer server.deinit(io);
    const port = server.socket.address.getPort();

    const responses = [_][]const u8{
        "HTTP/1.1 200 OK\r\n" ++
            "Set-Cookie: pub=1; Domain=co.uk; Path=/\r\n" ++
            "Set-Cookie: reg=2; Domain=example.co.uk; Path=/\r\n" ++
            "Content-Length: 2\r\n" ++
            "Connection: close\r\n\r\nok",
        "HTTP/1.1 200 OK\r\n" ++
            "Set-Cookie: hostonly=3; Path=/\r\n" ++
            "Content-Length: 2\r\n" ++
            "Connection: close\r\n\r\nok",
    };

    var srv_ctx = loopback_http.SequentialServer{
        .server = &server,
        .responses = &responses,
    };
    const thread = try std.Thread.spawn(.{}, loopback_http.SequentialServer.run, .{&srv_ctx});
    defer thread.join();

    const easy = curl_easy_init() orelse return error.EasyInitFailed;
    defer curl_easy_cleanup(easy);

    var resolve_sub_buf: [128]u8 = undefined;
    const resolve_sub = try loopback_http.bufPrintZ(&resolve_sub_buf, "sub.example.co.uk:{d}:127.0.0.1", .{port});
    var resolve_psl_buf: [128]u8 = undefined;
    const resolve_psl = try loopback_http.bufPrintZ(&resolve_psl_buf, "co.uk:{d}:127.0.0.1", .{port});

    var resolve_list = curl_slist_append(null, resolve_sub) orelse return error.SlistAppendFailed;
    defer curl_slist_free_all(resolve_list);
    resolve_list = curl_slist_append(resolve_list, resolve_psl) orelse return error.SlistAppendFailed;

    var sink = loopback_http.BodySink{};
    try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_NOSIGNAL, @as(c_long, 1)));
    try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_TIMEOUT_MS, @as(c_long, 10_000)));
    try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_COOKIEFILE, @as([*:0]const u8, "")));
    try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_RESOLVE, resolve_list));
    try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_WRITEFUNCTION, &loopback_http.writeCallback));
    try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_WRITEDATA, @as(?*anyopaque, @ptrCast(&sink))));

    var url1_buf: [128]u8 = undefined;
    const url1 = try loopback_http.bufPrintZ(&url1_buf, "http://sub.example.co.uk:{d}/", .{port});
    try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_URL, url1));
    try testing.expectEqual(c.CURLE_OK, curl_easy_perform(easy));

    var url2_buf: [128]u8 = undefined;
    const url2 = try loopback_http.bufPrintZ(&url2_buf, "http://co.uk:{d}/", .{port});
    try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_URL, url2));
    try testing.expectEqual(c.CURLE_OK, curl_easy_perform(easy));

    var cookies: ?*c.curl_slist = null;
    try testing.expectEqual(c.CURLE_OK, curl_easy_getinfo(easy, c.CURLINFO_COOKIELIST, &cookies));
    defer if (cookies) |list| curl_slist_free_all(list);

    // Domain=co.uk from sub.example.co.uk is rejected when PSL is enabled, accepted when disabled
    try testing.expectEqual(!backend_options.psl, loopback_http.hasCookie(cookies, "pub", "1"));
    // Domain=example.co.uk from sub.example.co.uk is accepted
    try testing.expect(loopback_http.hasCookie(cookies, "reg", "2"));
    // Host-only Set-Cookie from http://co.uk:<port>/ is accepted and stored as host-only (tailmatch = FALSE)
    try testing.expect(loopback_http.hasCookieLinePrefix(cookies, "co.uk\tFALSE\t", "hostonly", "3"));
}

test "IDN URL API punycode conversions and loopback HTTP transfer" {
    loopback_http.ensureUtf8Locale();

    // 1. URL API curl_url_set / curl_url_get with CURLU_PUNYCODE and CURLU_PUNY2IDN
    if (backend_options.idn != .none) {
        {
            const u = curl_url() orelse return error.UrlInitFailed;
            defer curl_url_cleanup(u);

            try testing.expectEqual(c.CURLUE_OK, curl_url_set(u, c.CURLUPART_URL, "https://m\xc3\xbcnchen.de/test", 0));
            var host: ?[*:0]u8 = null;
            try testing.expectEqual(c.CURLUE_OK, curl_url_get(u, c.CURLUPART_HOST, &host, c.CURLU_PUNYCODE));
            defer curl_free(@ptrCast(host));
            try testing.expect(host != null);
            try testing.expectEqualStrings("xn--mnchen-3ya.de", std.mem.span(host.?));
        }

        {
            const u = curl_url() orelse return error.UrlInitFailed;
            defer curl_url_cleanup(u);

            try testing.expectEqual(c.CURLUE_OK, curl_url_set(u, c.CURLUPART_URL, "https://xn--mnchen-3ya.de/test", 0));
            var host: ?[*:0]u8 = null;
            try testing.expectEqual(c.CURLUE_OK, curl_url_get(u, c.CURLUPART_HOST, &host, c.CURLU_PUNY2IDN));
            defer curl_free(@ptrCast(host));
            try testing.expect(host != null);
            try testing.expectEqualStrings("m\xc3\xbcnchen.de", std.mem.span(host.?));
        }

        if (backend_options.idn != .appleidn) {
            const u = curl_url() orelse return error.UrlInitFailed;
            defer curl_url_cleanup(u);

            try testing.expectEqual(c.CURLUE_OK, curl_url_set(u, c.CURLUPART_URL, "https://xn---.com/", 0));
            var host: ?[*:0]u8 = null;
            try testing.expectEqual(c.CURLUE_BAD_HOSTNAME, curl_url_get(u, c.CURLUPART_HOST, &host, c.CURLU_PUNY2IDN));
        }
    } else {
        {
            const u = curl_url() orelse return error.UrlInitFailed;
            defer curl_url_cleanup(u);

            try testing.expectEqual(c.CURLUE_OK, curl_url_set(u, c.CURLUPART_URL, "https://m\xc3\xbcnchen.de/test", 0));
            var host: ?[*:0]u8 = null;
            try testing.expectEqual(c.CURLUE_LACKS_IDN, curl_url_get(u, c.CURLUPART_HOST, &host, c.CURLU_PUNYCODE));
        }

        {
            const u = curl_url() orelse return error.UrlInitFailed;
            defer curl_url_cleanup(u);

            try testing.expectEqual(c.CURLUE_OK, curl_url_set(u, c.CURLUPART_URL, "https://xn--mnchen-3ya.de/test", 0));
            var host: ?[*:0]u8 = null;
            try testing.expectEqual(c.CURLUE_LACKS_IDN, curl_url_get(u, c.CURLUPART_HOST, &host, c.CURLU_PUNY2IDN));
        }
    }

    // 2. Loopback HTTP transfer to an IDN hostname verifying Host header uses Punycode
    if (backend_options.idn == .none) return;

    const io = std.Io.Threaded.global_single_threaded.io();
    const bind_addr = try std.Io.net.IpAddress.parseIp4("127.0.0.1", 0);
    var server = try bind_addr.listen(io, .{ .reuse_address = true });
    defer server.deinit(io);
    const port = server.socket.address.getPort();

    var srv_ctx = loopback_http.SingleResponseServer{
        .server = &server,
        .response = "HTTP/1.1 200 OK\r\nContent-Length: 2\r\nConnection: close\r\n\r\nok",
    };
    const thread = try std.Thread.spawn(.{}, loopback_http.SingleResponseServer.run, .{&srv_ctx});
    defer thread.join();

    const easy = curl_easy_init() orelse return error.EasyInitFailed;
    defer curl_easy_cleanup(easy);

    var resolve_buf: [128]u8 = undefined;
    const resolve_entry = try loopback_http.bufPrintZ(&resolve_buf, "xn--mnchen-3ya.de:{d}:127.0.0.1", .{port});
    const resolve_list = curl_slist_append(null, resolve_entry) orelse return error.SlistAppendFailed;
    defer curl_slist_free_all(resolve_list);

    var url_buf: [128]u8 = undefined;
    const url = try loopback_http.bufPrintZ(&url_buf, "http://m\xc3\xbcnchen.de:{d}/hello", .{port});
    var sink = loopback_http.BodySink{};

    try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_NOSIGNAL, @as(c_long, 1)));
    try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_TIMEOUT_MS, @as(c_long, 10_000)));
    try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_RESOLVE, resolve_list));
    try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_URL, url));
    try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_WRITEFUNCTION, &loopback_http.writeCallback));
    try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_WRITEDATA, @as(?*anyopaque, @ptrCast(&sink))));

    try testing.expectEqual(c.CURLE_OK, curl_easy_perform(easy));
    try testing.expectEqualStrings("ok", sink.slice());

    var expected_host_buf: [128]u8 = undefined;
    const expected_host = try std.fmt.bufPrint(&expected_host_buf, "Host: xn--mnchen-3ya.de:{d}\r\n", .{port});
    try testing.expect(std.mem.indexOf(u8, srv_ctx.requestSlice(), expected_host) != null);
}

const loopback_dns = struct {
    const AF_INET: c_int = 2;
    const SOCK_STREAM: c_int = 1;
    const SOCK_DGRAM: c_int = 2;
    const SOL_SOCKET: c_int = 1;
    const SO_REUSEADDR: c_int = 2;
    const SO_RCVTIMEO: c_int = 20;
    const SO_SNDTIMEO: c_int = 21;

    const ALPN_none: u8 = 0;
    const ALPN_h1: u8 = 1 << 3;
    const ALPN_h2: u8 = 1 << 4;

    const Curl_https_rrinfo = extern struct {
        target: ?[*:0]u8,
        ipv4hints: ?[*]u8,
        ipv4hints_len: usize,
        echconfiglist: ?[*]u8,
        echconfiglist_len: usize,
        ipv6hints: ?[*]u8,
        ipv6hints_len: usize,
        alpns: [4]u8,
        port: u16,
        priority: u16,
        flags: u32,
        _pad: u32 = 0,

        fn portSet(self: *const Curl_https_rrinfo) bool {
            return (self.flags & 4) != 0;
        }
    };

    const httpsrr_c = struct {
        extern fn doh_resp_decode_httpsrr(
            data: ?*anyopaque,
            cp: [*]const u8,
            len: usize,
            hrr: *?*Curl_https_rrinfo,
        ) callconv(.c) c.CURLcode;
        extern fn Curl_httpsrr_destroy(rrinfo: ?*Curl_https_rrinfo) callconv(.c) void;
    };

    const sockaddr_in = if (builtin.os.tag == .macos or
        builtin.os.tag == .ios or
        builtin.os.tag == .freebsd or
        builtin.os.tag == .netbsd or
        builtin.os.tag == .openbsd)
        extern struct {
            sin_len: u8 = 16,
            sin_family: u8 = @intCast(AF_INET),
            sin_port: u16 = 0,
            sin_addr: u32 = 0,
            sin_zero: [8]u8 = @splat(0),
        }
    else
        extern struct {
            sin_family: u16 = @intCast(AF_INET),
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
    extern "c" fn connect(sockfd: c_int, addr: *const sockaddr_in, addrlen: u32) c_int;
    extern "c" fn recv(sockfd: c_int, buf: [*]u8, len: usize, flags: c_int) isize;
    extern "c" fn send(sockfd: c_int, buf: [*]const u8, len: usize, flags: c_int) isize;
    extern "c" fn recvfrom(sockfd: c_int, buf: [*]u8, len: usize, flags: c_int, src_addr: ?*sockaddr_in, addrlen: ?*u32) isize;
    extern "c" fn sendto(sockfd: c_int, buf: [*]const u8, len: usize, flags: c_int, dest_addr: *const sockaddr_in, addrlen: u32) isize;
    extern "c" fn close(fd: c_int) c_int;

    fn setSocketTimeouts(fd: c_int) void {
        if (builtin.os.tag == .linux) {
            const tv = timeval{ .tv_sec = 5, .tv_usec = 0 };
            _ = setsockopt(fd, SOL_SOCKET, SO_RCVTIMEO, &tv, @sizeOf(timeval));
            _ = setsockopt(fd, SOL_SOCKET, SO_SNDTIMEO, &tv, @sizeOf(timeval));
        }
    }

    fn buildDnsReply(
        query: []const u8,
        out_buf: []u8,
        saw_a: *std.atomic.Value(bool),
        saw_aaaa: *std.atomic.Value(bool),
        saw_https: *std.atomic.Value(bool),
        https_alpn_h3: bool,
    ) ?[]const u8 {
        if (query.len < 17) return null;
        var pos: usize = 12;
        while (pos < query.len and query[pos] != 0) {
            const llen: usize = query[pos];
            if ((llen & 0xc0) != 0) return null;
            pos += 1 + llen;
        }
        if (pos + 5 > query.len) return null;
        pos += 1; // skip root label 0x00
        const qtype: u16 = (@as(u16, query[pos]) << 8) | @as(u16, query[pos + 1]);
        const qend: usize = pos + 4;
        const question = query[12..qend];
        if (12 + question.len + 32 > out_buf.len) return null;

        // DNS Header: QR=1, RD=1, RA=1, QDCOUNT=1
        out_buf[0] = query[0];
        out_buf[1] = query[1];
        out_buf[2] = 0x81;
        out_buf[3] = 0x80;
        out_buf[4] = 0x00;
        out_buf[5] = 0x01;
        out_buf[6] = 0x00;
        out_buf[7] = if (qtype == 1 or qtype == 65) 0x01 else 0x00;
        out_buf[8] = 0x00;
        out_buf[9] = 0x00;
        out_buf[10] = 0x00;
        out_buf[11] = 0x00;

        @memcpy(out_buf[12 .. 12 + question.len], question);
        var wpos: usize = 12 + question.len;

        switch (qtype) {
            1 => {
                saw_a.store(true, .release);
                const ans_a = [_]u8{
                    0xc0, 0x0c, // name pointer to offset 12
                    0x00, 0x01, // TYPE = A (1)
                    0x00, 0x01, // CLASS = IN (1)
                    0x00, 0x00, 0x00, 0x3c, // TTL = 60
                    0x00, 0x04, // RDLENGTH = 4
                    127, 0, 0, 1, // RDATA = 127.0.0.1
                };
                @memcpy(out_buf[wpos .. wpos + ans_a.len], &ans_a);
                wpos += ans_a.len;
            },
            28 => {
                saw_aaaa.store(true, .release);
            },
            65 => {
                saw_https.store(true, .release);
                if (https_alpn_h3) {
                    const ans_https_h3 = [_]u8{
                        0xc0, 0x0c, // name pointer to offset 12
                        0x00, 0x41, // TYPE = HTTPS (65)
                        0x00, 0x01, // CLASS = IN (1)
                        0x00, 0x00, 0x00, 0x3c, // TTL = 60
                        0x00, 0x0a, // RDLENGTH = 10
                        0x00, 0x01, // priority = 1
                        0x00, // target = "."
                        0x00, 0x01, // SvcParamKey = alpn (1)
                        0x00, 0x03, // SvcParamValueLen = 3
                        0x02, 'h',
                        '3',
                    };
                    @memcpy(out_buf[wpos .. wpos + ans_https_h3.len], &ans_https_h3);
                    wpos += ans_https_h3.len;
                } else {
                    const ans_https = [_]u8{
                        0xc0, 0x0c, // name pointer to offset 12
                        0x00, 0x41, // TYPE = HTTPS (65)
                        0x00, 0x01, // CLASS = IN (1)
                        0x00, 0x00, 0x00, 0x3c, // TTL = 60
                        0x00, 0x10, // RDLENGTH = 16
                        0x00, 0x01, // priority = 1
                        0x00, // target = "."
                        0x00, 0x01, // SvcParamKey = alpn (1)
                        0x00, 0x09, // SvcParamValueLen = 9
                        0x08, 'h',
                        't',  't',
                        'p',  '/',
                        '1',  '.',
                        '1',
                    };
                    @memcpy(out_buf[wpos .. wpos + ans_https.len], &ans_https);
                    wpos += ans_https.len;
                }
            },
            else => {},
        }
        return out_buf[0..wpos];
    }

    const UdpDnsServer = struct {
        udp_fd: c_int,
        port: u16,
        stop: std.atomic.Value(bool) = std.atomic.Value(bool).init(false),
        saw_a: std.atomic.Value(bool) = std.atomic.Value(bool).init(false),
        saw_aaaa: std.atomic.Value(bool) = std.atomic.Value(bool).init(false),
        saw_https: std.atomic.Value(bool) = std.atomic.Value(bool).init(false),
        https_alpn_h3: bool = false,

        fn init() !UdpDnsServer {
            const fd = socket(AF_INET, SOCK_DGRAM, 0);
            if (fd < 0) return error.SocketFailed;
            errdefer _ = close(fd);

            setSocketTimeouts(fd);

            var addr = sockaddr_in{
                .sin_port = 0,
                .sin_addr = std.mem.nativeToBig(u32, 0x7f000001),
            };
            if (bind(fd, &addr, @sizeOf(sockaddr_in)) != 0) return error.BindFailed;

            var bound_addr = sockaddr_in{};
            var addr_len: u32 = @sizeOf(sockaddr_in);
            if (getsockname(fd, &bound_addr, &addr_len) != 0) return error.GetsocknameFailed;

            return .{
                .udp_fd = fd,
                .port = std.mem.bigToNative(u16, bound_addr.sin_port),
            };
        }

        fn deinit(self: *UdpDnsServer) void {
            _ = close(self.udp_fd);
        }

        fn run(self: *UdpDnsServer) void {
            while (!self.stop.load(.acquire)) {
                var pkt: [512]u8 = undefined;
                var peer_addr = sockaddr_in{};
                var peer_len: u32 = @sizeOf(sockaddr_in);
                const n = recvfrom(self.udp_fd, &pkt, pkt.len, 0, &peer_addr, &peer_len);
                if (n <= 0) continue;
                if (self.stop.load(.acquire)) break;

                var reply_buf: [512]u8 = undefined;
                if (buildDnsReply(
                    pkt[0..@intCast(n)],
                    &reply_buf,
                    &self.saw_a,
                    &self.saw_aaaa,
                    &self.saw_https,
                    self.https_alpn_h3,
                )) |reply| {
                    _ = sendto(self.udp_fd, reply.ptr, reply.len, 0, &peer_addr, peer_len);
                }
            }
        }

        fn stopAndJoin(self: *UdpDnsServer, thread: std.Thread) void {
            self.stop.store(true, .release);
            const wake_fd = socket(AF_INET, SOCK_DGRAM, 0);
            if (wake_fd >= 0) {
                defer _ = close(wake_fd);
                var dst = sockaddr_in{
                    .sin_port = std.mem.nativeToBig(u16, self.port),
                    .sin_addr = std.mem.nativeToBig(u32, 0x7f000001),
                };
                const dummy = [_]u8{0};
                _ = sendto(wake_fd, &dummy, dummy.len, 0, &dst, @sizeOf(sockaddr_in));
            }
            thread.join();
        }
    };

    fn parseContentLength(headers: []const u8) ?usize {
        var lines = std.mem.splitSequence(u8, headers, "\r\n");
        while (lines.next()) |line| {
            const prefix = "Content-Length:";
            if (line.len >= prefix.len and std.ascii.eqlIgnoreCase(line[0..prefix.len], prefix)) {
                const val_str = std.mem.trim(u8, line[prefix.len..], " \t");
                return std.fmt.parseInt(usize, val_str, 10) catch null;
            }
        }
        return null;
    }

    const DohHttpServer = struct {
        listen_fd: c_int,
        port: u16,
        stop: std.atomic.Value(bool) = std.atomic.Value(bool).init(false),
        saw_a: std.atomic.Value(bool) = std.atomic.Value(bool).init(false),
        saw_aaaa: std.atomic.Value(bool) = std.atomic.Value(bool).init(false),
        saw_https: std.atomic.Value(bool) = std.atomic.Value(bool).init(false),
        https_alpn_h3: bool = false,

        fn init() !DohHttpServer {
            const fd = socket(AF_INET, SOCK_STREAM, 0);
            if (fd < 0) return error.SocketFailed;
            errdefer _ = close(fd);

            const one: c_int = 1;
            _ = setsockopt(fd, SOL_SOCKET, SO_REUSEADDR, &one, @sizeOf(c_int));
            setSocketTimeouts(fd);

            var addr = sockaddr_in{
                .sin_port = 0,
                .sin_addr = std.mem.nativeToBig(u32, 0x7f000001),
            };
            if (bind(fd, &addr, @sizeOf(sockaddr_in)) != 0) return error.BindFailed;
            if (listen(fd, 16) != 0) return error.ListenFailed;

            var bound_addr = sockaddr_in{};
            var addr_len: u32 = @sizeOf(sockaddr_in);
            if (getsockname(fd, &bound_addr, &addr_len) != 0) return error.GetsocknameFailed;

            return .{
                .listen_fd = fd,
                .port = std.mem.bigToNative(u16, bound_addr.sin_port),
            };
        }

        fn deinit(self: *DohHttpServer) void {
            _ = close(self.listen_fd);
        }

        fn run(self: *DohHttpServer) void {
            while (!self.stop.load(.acquire)) {
                const client_fd = accept(self.listen_fd, null, null);
                if (client_fd < 0) continue;
                defer _ = close(client_fd);
                if (self.stop.load(.acquire)) break;
                setSocketTimeouts(client_fd);

                var req_buf: [4096]u8 = undefined;
                var req_len: usize = 0;
                var header_end: ?usize = null;
                var content_len: usize = 0;

                while (req_len < req_buf.len) {
                    const n = recv(client_fd, req_buf[req_len..].ptr, req_buf.len - req_len, 0);
                    if (n <= 0) break;
                    req_len += @intCast(n);
                    if (header_end == null) {
                        if (std.mem.indexOf(u8, req_buf[0..req_len], "\r\n\r\n")) |idx| {
                            header_end = idx + 4;
                            content_len = parseContentLength(req_buf[0..idx]) orelse 0;
                        }
                    }
                    if (header_end) |hend| {
                        if (req_len >= hend + content_len) break;
                    }
                }

                const hend = header_end orelse continue;
                if (req_len < hend + content_len) continue;
                const body = req_buf[hend .. hend + content_len];

                var dns_reply_buf: [512]u8 = undefined;
                const dns_reply = buildDnsReply(
                    body,
                    &dns_reply_buf,
                    &self.saw_a,
                    &self.saw_aaaa,
                    &self.saw_https,
                    self.https_alpn_h3,
                ) orelse continue;

                var resp_buf: [1024]u8 = undefined;
                const hdr = std.fmt.bufPrint(
                    &resp_buf,
                    "HTTP/1.1 200 OK\r\nContent-Type: application/dns-message\r\nContent-Length: {d}\r\nConnection: close\r\n\r\n",
                    .{dns_reply.len},
                ) catch continue;
                _ = send(client_fd, hdr.ptr, hdr.len, 0);
                _ = send(client_fd, dns_reply.ptr, dns_reply.len, 0);
            }
        }

        fn stopAndJoin(self: *DohHttpServer, thread: std.Thread) void {
            self.stop.store(true, .release);
            const wake_fd = socket(AF_INET, SOCK_STREAM, 0);
            if (wake_fd >= 0) {
                defer _ = close(wake_fd);
                var dst = sockaddr_in{
                    .sin_port = std.mem.nativeToBig(u16, self.port),
                    .sin_addr = std.mem.nativeToBig(u32, 0x7f000001),
                };
                _ = connect(wake_fd, &dst, @sizeOf(sockaddr_in));
            }
            thread.join();
        }
    };
};

test "c-ares loopback UDP DNS server resolution via CURLOPT_DNS_SERVERS" {
    if (comptime (!backend_options.use_resolv_ares or builtin.os.tag == .windows)) return;

    var dns_srv = try loopback_dns.UdpDnsServer.init();
    defer dns_srv.deinit();
    const dns_thread = try std.Thread.spawn(.{}, loopback_dns.UdpDnsServer.run, .{&dns_srv});
    defer dns_srv.stopAndJoin(dns_thread);

    var dns_servers_buf: [64]u8 = undefined;
    const dns_servers = try loopback_http.bufPrintZ(&dns_servers_buf, "127.0.0.1:{d}", .{dns_srv.port});

    // 1. Resolve http://ares-loopback.test:<http_port>/hello via loopback UDP DNS server (no CURLOPT_RESOLVE)
    {
        const io = std.Io.Threaded.global_single_threaded.io();
        const bind_addr = try std.Io.net.IpAddress.parseIp4("127.0.0.1", 0);
        var server = try bind_addr.listen(io, .{ .reuse_address = true });
        defer server.deinit(io);
        const http_port = server.socket.address.getPort();

        var srv_ctx = loopback_http.SingleResponseServer{
            .server = &server,
            .response = "HTTP/1.1 200 OK\r\nContent-Length: 2\r\nConnection: close\r\n\r\nok",
        };
        const http_thread = try std.Thread.spawn(.{}, loopback_http.SingleResponseServer.run, .{&srv_ctx});
        defer http_thread.join();

        const easy = curl_easy_init() orelse return error.EasyInitFailed;
        defer curl_easy_cleanup(easy);

        var url_buf: [128]u8 = undefined;
        const url = try loopback_http.bufPrintZ(&url_buf, "http://ares-loopback.test:{d}/hello", .{http_port});
        var sink = loopback_http.BodySink{};

        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_NOSIGNAL, @as(c_long, 1)));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_TIMEOUT_MS, @as(c_long, 10_000)));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_DNS_SERVERS, dns_servers));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_URL, url));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_WRITEFUNCTION, &loopback_http.writeCallback));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_WRITEDATA, @as(?*anyopaque, @ptrCast(&sink))));

        try testing.expectEqual(c.CURLE_OK, curl_easy_perform(easy));
        try testing.expectEqualStrings("ok", sink.slice());
        try testing.expect(dns_srv.saw_a.load(.acquire));
    }

    // 2. When HTTPS-RR and OpenSSL are enabled, perform an https:// transfer and verify QTYPE 65 (HTTPS) query
    if (comptime (backend_options.httpsrr and backend_options.ssl == .openssl)) {
        var https_port: u16 = 0;
        const listen_fd = try loopback_tls.openLoopbackListener(&https_port);
        defer _ = loopback_tls.sock_c.close(listen_fd);
        loopback_tls.setSocketTimeouts(listen_fd);

        const tls_thread = try std.Thread.spawn(.{}, loopback_tls.serveOpenSslOnce, .{listen_fd});
        defer tls_thread.join();

        const easy = curl_easy_init() orelse return error.EasyInitFailed;
        defer curl_easy_cleanup(easy);

        var url_buf: [128]u8 = undefined;
        const url = try loopback_http.bufPrintZ(&url_buf, "https://ares-httpsrr.test:{d}/hello", .{https_port});
        var sink = loopback_http.BodySink{};

        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_NOSIGNAL, @as(c_long, 1)));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_TIMEOUT_MS, @as(c_long, 10_000)));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_DNS_SERVERS, dns_servers));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_SSL_VERIFYPEER, @as(c_long, 0)));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_SSL_VERIFYHOST, @as(c_long, 0)));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_URL, url));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_WRITEFUNCTION, &loopback_http.writeCallback));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_WRITEDATA, @as(?*anyopaque, @ptrCast(&sink))));

        try testing.expectEqual(c.CURLE_OK, curl_easy_perform(easy));
        try testing.expectEqualStrings("ok", sink.slice());
        try testing.expect(dns_srv.saw_https.load(.acquire));
    }
}

test "DoH loopback DNS-over-HTTPS resolution with HTTPS-RR" {
    // 1. Direct HTTPS-RR wire format decode via doh_resp_decode_httpsrr
    if (comptime backend_options.httpsrr) {
        const https_rdata = [_]u8{
            0x00, 0x01, // priority = 1
            0x00, // target = "."
            // SvcParam 1: alpn = "h2,http/1.1"
            0x00, 0x01, // key = 1 (alpn)
            0x00, 0x0c, // len = 12
            0x02, 'h',
            '2',  0x08,
            'h',  't',
            't',  'p',
            '/',  '1',
            '.',  '1',
            // SvcParam 2: port = 8443 (0x20fb)
            0x00, 0x03, // key = 3 (port)
            0x00, 0x02, // len = 2
            0x20, 0xfb,
            // SvcParam 3: ipv4hint = 127.0.0.1
            0x00, 0x04, // key = 4 (ipv4hint)
            0x00, 0x04, // len = 4
            127,  0,
            0,    1,
        };

        var hrr: ?*loopback_dns.Curl_https_rrinfo = null;
        try testing.expectEqual(
            c.CURLE_OK,
            loopback_dns.httpsrr_c.doh_resp_decode_httpsrr(null, &https_rdata, https_rdata.len, &hrr),
        );
        defer loopback_dns.httpsrr_c.Curl_httpsrr_destroy(hrr);

        const rr = hrr orelse return error.NullHttpsRrInfo;
        try testing.expectEqual(@as(u16, 1), rr.priority);
        try testing.expect(rr.target != null);
        try testing.expectEqualStrings(".", std.mem.span(rr.target.?));
        try testing.expect(rr.portSet());
        try testing.expectEqual(@as(u16, 8443), rr.port);
        try testing.expectEqual(loopback_dns.ALPN_h2, rr.alpns[0]);
        try testing.expectEqual(loopback_dns.ALPN_h1, rr.alpns[1]);
        try testing.expectEqual(loopback_dns.ALPN_none, rr.alpns[2]);
        try testing.expectEqual(@as(usize, 4), rr.ipv4hints_len);
        try testing.expect(rr.ipv4hints != null);
        try testing.expectEqualSlices(u8, &[_]u8{ 127, 0, 0, 1 }, rr.ipv4hints.?[0..4]);
    }

    // 2. End-to-end loopback DoH HTTP server + target HTTP server via CURLOPT_DOH_URL
    if (comptime (builtin.os.tag == .windows)) return;

    var doh_srv = try loopback_dns.DohHttpServer.init();
    defer doh_srv.deinit();
    const doh_thread = try std.Thread.spawn(.{}, loopback_dns.DohHttpServer.run, .{&doh_srv});
    defer doh_srv.stopAndJoin(doh_thread);

    var doh_url_buf: [128]u8 = undefined;
    const doh_url = try loopback_http.bufPrintZ(&doh_url_buf, "http://127.0.0.1:{d}/dns-query", .{doh_srv.port});

    const io = std.Io.Threaded.global_single_threaded.io();
    const bind_addr = try std.Io.net.IpAddress.parseIp4("127.0.0.1", 0);
    var target_server = try bind_addr.listen(io, .{ .reuse_address = true });
    defer target_server.deinit(io);
    const target_port = target_server.socket.address.getPort();

    var srv_ctx = loopback_http.SingleResponseServer{
        .server = &target_server,
        .response = "HTTP/1.1 200 OK\r\nContent-Length: 2\r\nConnection: close\r\n\r\nok",
    };
    const target_thread = try std.Thread.spawn(.{}, loopback_http.SingleResponseServer.run, .{&srv_ctx});
    defer target_thread.join();

    const easy = curl_easy_init() orelse return error.EasyInitFailed;
    defer curl_easy_cleanup(easy);

    var url_buf: [128]u8 = undefined;
    const url = try loopback_http.bufPrintZ(&url_buf, "http://doh-test.example:{d}/", .{target_port});
    var sink = loopback_http.BodySink{};

    try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_NOSIGNAL, @as(c_long, 1)));
    try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_TIMEOUT_MS, @as(c_long, 10_000)));
    try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_DOH_URL, doh_url));
    try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_URL, url));
    try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_WRITEFUNCTION, &loopback_http.writeCallback));
    try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_WRITEDATA, @as(?*anyopaque, @ptrCast(&sink))));

    try testing.expectEqual(c.CURLE_OK, curl_easy_perform(easy));
    try testing.expectEqualStrings("ok", sink.slice());
    try testing.expect(doh_srv.saw_a.load(.acquire));
}

const loopback_quic = struct {
    const c_cf = struct {
        const CurlCftype = extern struct {
            name: [*:0]const u8,
            flags: c_uint,
            log_level: c_int,
            destroy: *const fn (cf: *CurlCfilter, data: ?*anyopaque) callconv(.c) void,
            do_connect: *const anyopaque,
            do_shutdown: *const anyopaque,
            adjust_pollset: *const anyopaque,
            has_data_pending: *const anyopaque,
            do_send: *const anyopaque,
            do_recv: *const anyopaque,
            cntrl: *const anyopaque,
            is_alive: *const anyopaque,
            keep_alive: *const anyopaque,
            query: *const anyopaque,
        };

        const CurlCfilter = extern struct {
            cft: *const CurlCftype,
            next: ?*CurlCfilter,
            ctx: ?*anyopaque,
            conn: ?*anyopaque,
            sockindex: c_int,
            bits: u8,
        };

        extern fn Curl_cf_quic_create(
            pcf: *?*CurlCfilter,
            data: ?*anyopaque,
            origin: ?*anyopaque,
            peer: ?*anyopaque,
            transport_peer: u8,
            conn: ?*anyopaque,
            addr: ?*anyopaque,
            tunnel_peer: ?*anyopaque,
            tunnel_transport: u8,
        ) callconv(.c) c.CURLcode;
    };

    const UdpQuicInitialServer = struct {
        udp_fd: c_int,
        port: u16,
        pkt_buf: [2048]u8 = @splat(0),
        pkt_len: std.atomic.Value(usize) = std.atomic.Value(usize).init(0),

        fn init() !UdpQuicInitialServer {
            const fd = loopback_dns.socket(loopback_dns.AF_INET, loopback_dns.SOCK_DGRAM, 0);
            if (fd < 0) return error.SocketFailed;
            errdefer _ = loopback_dns.close(fd);

            loopback_dns.setSocketTimeouts(fd);

            var addr = loopback_dns.sockaddr_in{
                .sin_port = 0,
                .sin_addr = std.mem.nativeToBig(u32, 0x7f000001),
            };
            if (loopback_dns.bind(fd, &addr, @sizeOf(loopback_dns.sockaddr_in)) != 0) return error.BindFailed;

            var bound_addr = loopback_dns.sockaddr_in{};
            var addr_len: u32 = @sizeOf(loopback_dns.sockaddr_in);
            if (loopback_dns.getsockname(fd, &bound_addr, &addr_len) != 0) return error.GetsocknameFailed;

            return .{
                .udp_fd = fd,
                .port = std.mem.bigToNative(u16, bound_addr.sin_port),
            };
        }

        fn deinit(self: *UdpQuicInitialServer) void {
            _ = loopback_dns.close(self.udp_fd);
        }

        fn runOnce(self: *UdpQuicInitialServer) void {
            var peer_addr = loopback_dns.sockaddr_in{};
            var peer_len: u32 = @sizeOf(loopback_dns.sockaddr_in);
            const n = loopback_dns.recvfrom(self.udp_fd, &self.pkt_buf, self.pkt_buf.len, 0, &peer_addr, &peer_len);
            if (n <= 0) return;
            const pkt_n: usize = @intCast(n);
            self.pkt_len.store(pkt_n, .release);

            // Send back a QUIC Version Negotiation packet (RFC 9000 Section 17.2.1)
            // with an unsupported version so ngtcp2 terminates the handshake immediately.
            if (pkt_n >= 7) {
                const dcid_len: usize = self.pkt_buf[5];
                if (6 + dcid_len < pkt_n) {
                    const dcid = self.pkt_buf[6 .. 6 + dcid_len];
                    const scid_len: usize = self.pkt_buf[6 + dcid_len];
                    if (7 + dcid_len + scid_len <= pkt_n) {
                        const scid = self.pkt_buf[7 + dcid_len .. 7 + dcid_len + scid_len];
                        var vn_pkt: [128]u8 = @splat(0);
                        if (7 + scid_len + dcid_len + 4 <= vn_pkt.len) {
                            vn_pkt[0] = 0xc0; // Long Header Form | Fixed Bit
                            // Version = 0x00000000 (bytes 1..5)
                            vn_pkt[5] = @intCast(scid_len);
                            @memcpy(vn_pkt[6 .. 6 + scid_len], scid);
                            vn_pkt[6 + scid_len] = @intCast(dcid_len);
                            @memcpy(vn_pkt[7 + scid_len .. 7 + scid_len + dcid_len], dcid);
                            const v_off = 7 + scid_len + dcid_len;
                            vn_pkt[v_off + 0] = 0x0a;
                            vn_pkt[v_off + 1] = 0x0a;
                            vn_pkt[v_off + 2] = 0x0a;
                            vn_pkt[v_off + 3] = 0x0a;
                            _ = loopback_dns.sendto(
                                self.udp_fd,
                                &vn_pkt,
                                v_off + 4,
                                0,
                                &peer_addr,
                                peer_len,
                            );
                        }
                    }
                }
            }
        }
    };

    extern fn Curl_test_h3_server_serve(
        udp_fd: c_int,
        cert_file: [*:0]const u8,
        key_file: [*:0]const u8,
        stop_flag: *volatile c_int,
    ) callconv(.c) c_int;

    const LocalH3Server = struct {
        udp_fd: c_int,
        port: u16,
        stop_flag: c_int = 0,
        rc: c_int = 0,
        cert_path: [*:0]const u8,
        key_path: [*:0]const u8,

        fn init(cert_file: [*:0]const u8, key_file: [*:0]const u8) !LocalH3Server {
            const fd = loopback_dns.socket(loopback_dns.AF_INET, loopback_dns.SOCK_DGRAM, 0);
            if (fd < 0) return error.SocketFailed;
            errdefer _ = loopback_dns.close(fd);

            if (builtin.os.tag == .linux) {
                const tv = loopback_dns.timeval{ .tv_sec = 0, .tv_usec = 100_000 };
                _ = loopback_dns.setsockopt(fd, loopback_dns.SOL_SOCKET, loopback_dns.SO_RCVTIMEO, &tv, @sizeOf(loopback_dns.timeval));
                _ = loopback_dns.setsockopt(fd, loopback_dns.SOL_SOCKET, loopback_dns.SO_SNDTIMEO, &tv, @sizeOf(loopback_dns.timeval));
            }

            var addr = loopback_dns.sockaddr_in{
                .sin_port = 0,
                .sin_addr = std.mem.nativeToBig(u32, 0x7f000001),
            };
            if (loopback_dns.bind(fd, &addr, @sizeOf(loopback_dns.sockaddr_in)) != 0) return error.BindFailed;

            var bound_addr = loopback_dns.sockaddr_in{};
            var addr_len: u32 = @sizeOf(loopback_dns.sockaddr_in);
            if (loopback_dns.getsockname(fd, &bound_addr, &addr_len) != 0) return error.GetsocknameFailed;

            return LocalH3Server{
                .udp_fd = fd,
                .port = std.mem.bigToNative(u16, bound_addr.sin_port),
                .cert_path = cert_file,
                .key_path = key_file,
            };
        }

        fn deinit(self: *LocalH3Server) void {
            _ = loopback_dns.close(self.udp_fd);
        }

        fn run(self: *LocalH3Server) void {
            self.rc = Curl_test_h3_server_serve(
                self.udp_fd,
                self.cert_path,
                self.key_path,
                &self.stop_flag,
            );
        }

        fn stopAndJoin(self: *LocalH3Server, thread: std.Thread) void {
            @atomicStore(c_int, &self.stop_flag, 1, .release);
            const wake_fd = loopback_dns.socket(loopback_dns.AF_INET, loopback_dns.SOCK_DGRAM, 0);
            if (wake_fd >= 0) {
                defer _ = loopback_dns.close(wake_fd);
                var dst = loopback_dns.sockaddr_in{
                    .sin_port = std.mem.nativeToBig(u16, self.port),
                    .sin_addr = std.mem.nativeToBig(u32, 0x7f000001),
                };
                const dummy = [_]u8{0};
                _ = loopback_dns.sendto(wake_fd, &dummy, dummy.len, 0, &dst, @sizeOf(loopback_dns.sockaddr_in));
            }
            thread.join();
        }
    };
};

test "HTTP/3 QUIC filter creation and UDP loopback QUIC Initial packet generation" {
    // 1. Direct Curl_cf_quic_create filter creation verification
    {
        var cf: ?*loopback_quic.c_cf.CurlCfilter = null;
        var dummy_addr: [256]u8 align(8) = @splat(0);
        const rc = loopback_quic.c_cf.Curl_cf_quic_create(&cf, null, null, null, 5, null, &dummy_addr, null, 0);
        if (backend_options.quic != .none) {
            try testing.expectEqual(c.CURLE_OK, rc);
            try testing.expect(cf != null);
            const h3_cf = cf.?;
            defer {
                if (h3_cf.next) |udp_cf| {
                    udp_cf.cft.destroy(udp_cf, null);
                    curl_free(udp_cf);
                }
                h3_cf.cft.destroy(h3_cf, null);
                curl_free(h3_cf);
            }
            try testing.expectEqualStrings("HTTP/3", std.mem.span(h3_cf.cft.name));
            try testing.expect(h3_cf.next != null);
            try testing.expectEqualStrings("UDP", std.mem.span(h3_cf.next.?.cft.name));
        } else {
            try testing.expectEqual(c.CURLE_NOT_BUILT_IN, rc);
            try testing.expect(cf == null);
        }
    }

    if (comptime (backend_options.quic == .none or builtin.os.tag == .windows)) return;

    // 2. End-to-end HTTP/3 (CURL_HTTP_VERSION_3ONLY) UDP loopback QUIC v1 Initial packet generation
    {
        var quic_srv = try loopback_quic.UdpQuicInitialServer.init();
        defer quic_srv.deinit();
        const srv_thread = try std.Thread.spawn(.{}, loopback_quic.UdpQuicInitialServer.runOnce, .{&quic_srv});
        defer srv_thread.join();

        const easy = curl_easy_init() orelse return error.EasyInitFailed;
        defer curl_easy_cleanup(easy);

        var resolve_buf: [128]u8 = undefined;
        const resolve_entry = try loopback_http.bufPrintZ(&resolve_buf, "localhost:{d}:127.0.0.1", .{quic_srv.port});
        const resolve_list = curl_slist_append(null, resolve_entry) orelse return error.SlistAppendFailed;
        defer curl_slist_free_all(resolve_list);

        var url_buf: [128]u8 = undefined;
        const url = try loopback_http.bufPrintZ(&url_buf, "https://localhost:{d}/h3-initial", .{quic_srv.port});

        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_NOSIGNAL, @as(c_long, 1)));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_TIMEOUT_MS, @as(c_long, 1500)));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_HTTP_VERSION, c.CURL_HTTP_VERSION_3ONLY));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_SSL_VERIFYPEER, @as(c_long, 0)));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_SSL_VERIFYHOST, @as(c_long, 0)));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_RESOLVE, resolve_list));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_URL, url));

        _ = curl_easy_perform(easy);

        const pkt_len = quic_srv.pkt_len.load(.acquire);
        // RFC 9000 Section 14.1: QUIC Initial UDP datagram must be at least 1200 bytes
        try testing.expect(pkt_len >= 1200);
        const pkt = quic_srv.pkt_buf[0..pkt_len];
        // Long header form (bit 7 = 1) and Fixed bit (bit 6 = 1)
        try testing.expectEqual(@as(u8, 0xc0), pkt[0] & 0xc0);
        // QUIC v1 version (0x00000001)
        const version = std.mem.readInt(u32, pkt[1..5], .big);
        try testing.expectEqual(@as(u32, 0x00000001), version);
        const dcid_len = pkt[5];
        try testing.expect(dcid_len >= 8 and dcid_len <= 20);
        const scid_len = pkt[6 + dcid_len];
        try testing.expectEqual(@as(u8, 20), scid_len);
    }

    // 3. When proxy-HTTP3 is enabled, verify CURLPROXY_HTTPS3 emits a QUIC v1 Initial UDP datagram via Curl_cft_h3_proxy
    if (comptime backend_options.proxy_http3) {
        var proxy_srv = try loopback_quic.UdpQuicInitialServer.init();
        defer proxy_srv.deinit();
        const srv_thread = try std.Thread.spawn(.{}, loopback_quic.UdpQuicInitialServer.runOnce, .{&proxy_srv});
        defer srv_thread.join();

        const easy = curl_easy_init() orelse return error.EasyInitFailed;
        defer curl_easy_cleanup(easy);

        var resolve_buf: [128]u8 = undefined;
        const resolve_entry = try loopback_http.bufPrintZ(&resolve_buf, "localhost:{d}:127.0.0.1", .{proxy_srv.port});
        const resolve_list = curl_slist_append(null, resolve_entry) orelse return error.SlistAppendFailed;
        defer curl_slist_free_all(resolve_list);

        var proxy_buf: [128]u8 = undefined;
        const proxy_url = try loopback_http.bufPrintZ(&proxy_buf, "https://localhost:{d}", .{proxy_srv.port});

        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_NOSIGNAL, @as(c_long, 1)));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_TIMEOUT_MS, @as(c_long, 1500)));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_PROXYTYPE, c.CURLPROXY_HTTPS3));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_PROXY, proxy_url));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_PROXY_SSL_VERIFYPEER, @as(c_long, 0)));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_PROXY_SSL_VERIFYHOST, @as(c_long, 0)));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_RESOLVE, resolve_list));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_URL, @as([*:0]const u8, "https://example.com/")));

        _ = curl_easy_perform(easy);

        const pkt_len = proxy_srv.pkt_len.load(.acquire);
        try testing.expect(pkt_len >= 1200);
        const pkt = proxy_srv.pkt_buf[0..pkt_len];
        try testing.expectEqual(@as(u8, 0xc0), pkt[0] & 0xc0);
        const version = std.mem.readInt(u32, pkt[1..5], .big);
        try testing.expectEqual(@as(u32, 0x00000001), version);
    }
}

test "HTTP/3 end-to-end local UDP server: GET, POST, concurrent streams, cert/host verification, and HTTPS-RR alpn=h3" {
    if (comptime (backend_options.quic == .none or builtin.os.tag == .windows)) return;

    var tmp = testing.tmpDir(.{});
    defer tmp.cleanup();

    try tmp.dir.writeFile(testing.io, .{ .sub_path = "ca.pem", .data = loopback_tls.test_ca_cert_pem });
    try tmp.dir.writeFile(testing.io, .{ .sub_path = "server.pem", .data = loopback_tls.test_server_cert_pem });
    try tmp.dir.writeFile(testing.io, .{ .sub_path = "server.key", .data = loopback_tls.test_server_key_pem });

    const ca_abs = try tmp.dir.realPathFileAlloc(testing.io, "ca.pem", testing.allocator);
    defer testing.allocator.free(ca_abs);
    const ca_z = try std.fmt.allocPrint(testing.allocator, "{s}\x00", .{ca_abs});
    defer testing.allocator.free(ca_z);
    const ca_file: [*:0]const u8 = @ptrCast(ca_z.ptr);

    const cert_abs = try tmp.dir.realPathFileAlloc(testing.io, "server.pem", testing.allocator);
    defer testing.allocator.free(cert_abs);
    const cert_z = try std.fmt.allocPrint(testing.allocator, "{s}\x00", .{cert_abs});
    defer testing.allocator.free(cert_z);
    const cert_file: [*:0]const u8 = @ptrCast(cert_z.ptr);

    const key_abs = try tmp.dir.realPathFileAlloc(testing.io, "server.key", testing.allocator);
    defer testing.allocator.free(key_abs);
    const key_z = try std.fmt.allocPrint(testing.allocator, "{s}\x00", .{key_abs});
    defer testing.allocator.free(key_z);
    const key_file: [*:0]const u8 = @ptrCast(key_z.ptr);

    // 1. End-to-end HTTP/3 GET with CA verification + hostname verification (localhost)
    {
        var srv = try loopback_quic.LocalH3Server.init(cert_file, key_file);
        defer srv.deinit();
        const srv_thread = try std.Thread.spawn(.{}, loopback_quic.LocalH3Server.run, .{&srv});
        defer srv.stopAndJoin(srv_thread);

        const easy = curl_easy_init() orelse return error.EasyInitFailed;
        defer curl_easy_cleanup(easy);

        var url_buf: [128]u8 = undefined;
        const url = try loopback_http.bufPrintZ(&url_buf, "https://localhost:{d}/get", .{srv.port});

        var resolve_buf: [128]u8 = undefined;
        const resolve_entry = try loopback_http.bufPrintZ(&resolve_buf, "localhost:{d}:127.0.0.1", .{srv.port});
        const resolve_list = curl_slist_append(null, resolve_entry) orelse return error.SlistAppendFailed;
        defer curl_slist_free_all(resolve_list);

        var cap = loopback_http.BodySink{};
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_NOSIGNAL, @as(c_long, 1)));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_TIMEOUT_MS, @as(c_long, 5000)));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_HTTP_VERSION, c.CURL_HTTP_VERSION_3ONLY));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_SSL_VERIFYPEER, @as(c_long, 1)));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_SSL_VERIFYHOST, @as(c_long, 2)));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_CAINFO, ca_file));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_RESOLVE, resolve_list));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_WRITEFUNCTION, &loopback_http.writeCallback));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_WRITEDATA, &cap));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_URL, url));

        try testing.expectEqual(c.CURLE_OK, curl_easy_perform(easy));

        var status_code: c_long = 0;
        try testing.expectEqual(c.CURLE_OK, curl_easy_getinfo(easy, c.CURLINFO_RESPONSE_CODE, &status_code));
        try testing.expectEqual(@as(c_long, 200), status_code);

        var http_version: c_long = 0;
        try testing.expectEqual(c.CURLE_OK, curl_easy_getinfo(easy, c.CURLINFO_HTTP_VERSION, &http_version));
        try testing.expectEqual(c.CURL_HTTP_VERSION_3, http_version);
        try testing.expectEqualStrings("hello-http3", cap.slice());
    }

    // 2. End-to-end HTTP/3 POST with request body echo
    {
        var srv = try loopback_quic.LocalH3Server.init(cert_file, key_file);
        defer srv.deinit();
        const srv_thread = try std.Thread.spawn(.{}, loopback_quic.LocalH3Server.run, .{&srv});
        defer srv.stopAndJoin(srv_thread);

        const easy = curl_easy_init() orelse return error.EasyInitFailed;
        defer curl_easy_cleanup(easy);

        var url_buf: [128]u8 = undefined;
        const url = try loopback_http.bufPrintZ(&url_buf, "https://localhost:{d}/post", .{srv.port});

        var resolve_buf: [128]u8 = undefined;
        const resolve_entry = try loopback_http.bufPrintZ(&resolve_buf, "localhost:{d}:127.0.0.1", .{srv.port});
        const resolve_list = curl_slist_append(null, resolve_entry) orelse return error.SlistAppendFailed;
        defer curl_slist_free_all(resolve_list);

        const payload: [*:0]const u8 = "zig-http3-post-payload";
        var cap = loopback_http.BodySink{};
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_NOSIGNAL, @as(c_long, 1)));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_TIMEOUT_MS, @as(c_long, 5000)));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_HTTP_VERSION, c.CURL_HTTP_VERSION_3ONLY));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_SSL_VERIFYPEER, @as(c_long, 1)));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_SSL_VERIFYHOST, @as(c_long, 2)));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_CAINFO, ca_file));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_RESOLVE, resolve_list));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_POSTFIELDS, payload));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_POSTFIELDSIZE, @as(c_long, 22)));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_WRITEFUNCTION, &loopback_http.writeCallback));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_WRITEDATA, &cap));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_URL, url));

        try testing.expectEqual(c.CURLE_OK, curl_easy_perform(easy));

        var status_code: c_long = 0;
        try testing.expectEqual(c.CURLE_OK, curl_easy_getinfo(easy, c.CURLINFO_RESPONSE_CODE, &status_code));
        try testing.expectEqual(@as(c_long, 200), status_code);
        try testing.expectEqualStrings("post-echo:zig-http3-post-payload", cap.slice());
    }

    // 3. Concurrent HTTP/3 streams multiplexed over a single QUIC connection via curl_multi
    {
        var srv = try loopback_quic.LocalH3Server.init(cert_file, key_file);
        defer srv.deinit();
        const srv_thread = try std.Thread.spawn(.{}, loopback_quic.LocalH3Server.run, .{&srv});
        defer srv.stopAndJoin(srv_thread);

        const multi = curl_multi_init() orelse return error.MultiInitFailed;
        defer _ = curl_multi_cleanup(multi);

        const easy1 = curl_easy_init() orelse return error.EasyInitFailed;
        defer curl_easy_cleanup(easy1);
        const easy2 = curl_easy_init() orelse return error.EasyInitFailed;
        defer curl_easy_cleanup(easy2);

        var resolve_buf: [128]u8 = undefined;
        const resolve_entry = try loopback_http.bufPrintZ(&resolve_buf, "localhost:{d}:127.0.0.1", .{srv.port});
        const resolve_list1 = curl_slist_append(null, resolve_entry) orelse return error.SlistAppendFailed;
        defer curl_slist_free_all(resolve_list1);
        const resolve_list2 = curl_slist_append(null, resolve_entry) orelse return error.SlistAppendFailed;
        defer curl_slist_free_all(resolve_list2);

        var url1_buf: [128]u8 = undefined;
        const url1 = try loopback_http.bufPrintZ(&url1_buf, "https://localhost:{d}/stream1", .{srv.port});
        var url2_buf: [128]u8 = undefined;
        const url2 = try loopback_http.bufPrintZ(&url2_buf, "https://localhost:{d}/stream2", .{srv.port});

        var cap1 = loopback_http.BodySink{};
        var cap2 = loopback_http.BodySink{};

        for ([_]?*anyopaque{ easy1, easy2 }, [_][*:0]const u8{ url1, url2 }, [_]*loopback_http.BodySink{ &cap1, &cap2 }, [_]?*c.curl_slist{ resolve_list1, resolve_list2 }) |easy, url, cap, rlist| {
            try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_NOSIGNAL, @as(c_long, 1)));
            try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_TIMEOUT_MS, @as(c_long, 5000)));
            try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_PIPEWAIT, @as(c_long, 1)));
            try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_HTTP_VERSION, c.CURL_HTTP_VERSION_3ONLY));
            try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_SSL_VERIFYPEER, @as(c_long, 1)));
            try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_SSL_VERIFYHOST, @as(c_long, 2)));
            try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_CAINFO, ca_file));
            try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_RESOLVE, rlist));
            try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_WRITEFUNCTION, &loopback_http.writeCallback));
            try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_WRITEDATA, cap));
            try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_URL, url));
            try testing.expectEqual(c.CURLM_OK, curl_multi_add_handle(multi, easy));
        }
        defer {
            _ = curl_multi_remove_handle(multi, easy1);
            _ = curl_multi_remove_handle(multi, easy2);
        }

        var still_running: c_int = 1;
        while (still_running > 0) {
            try testing.expectEqual(c.CURLM_OK, curl_multi_perform(multi, &still_running));
            if (still_running > 0) {
                try testing.expectEqual(c.CURLM_OK, curl_multi_poll(multi, null, 0, 50, null));
            }
        }

        var msgs_left: c_int = 0;
        var done_count: usize = 0;
        while (curl_multi_info_read(multi, &msgs_left)) |msg| {
            if (msg.msg == c.CURLMSG_DONE) {
                try testing.expectEqual(c.CURLE_OK, msg.data.result);
                done_count += 1;
            }
        }
        try testing.expectEqual(@as(usize, 2), done_count);
        try testing.expectEqualStrings("h3-stream-1-ok", cap1.slice());
        try testing.expectEqualStrings("h3-stream-2-ok", cap2.slice());
    }

    // 4. Peer certificate verification failure (untrusted self-signed cert without CAINFO)
    {
        var srv = try loopback_quic.LocalH3Server.init(cert_file, key_file);
        defer srv.deinit();
        const srv_thread = try std.Thread.spawn(.{}, loopback_quic.LocalH3Server.run, .{&srv});
        defer srv.stopAndJoin(srv_thread);

        const easy = curl_easy_init() orelse return error.EasyInitFailed;
        defer curl_easy_cleanup(easy);

        var url_buf: [128]u8 = undefined;
        const url = try loopback_http.bufPrintZ(&url_buf, "https://localhost:{d}/untrusted", .{srv.port});

        var resolve_buf: [128]u8 = undefined;
        const resolve_entry = try loopback_http.bufPrintZ(&resolve_buf, "localhost:{d}:127.0.0.1", .{srv.port});
        const resolve_list = curl_slist_append(null, resolve_entry) orelse return error.SlistAppendFailed;
        defer curl_slist_free_all(resolve_list);

        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_NOSIGNAL, @as(c_long, 1)));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_TIMEOUT_MS, @as(c_long, 5000)));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_HTTP_VERSION, c.CURL_HTTP_VERSION_3ONLY));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_SSL_VERIFYPEER, @as(c_long, 1)));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_SSL_VERIFYHOST, @as(c_long, 2)));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_RESOLVE, resolve_list));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_URL, url));

        const rc = curl_easy_perform(easy);
        try testing.expectEqual(c.CURLE_PEER_FAILED_VERIFICATION, rc);
    }

    // 5. Hostname verification failure (trusted CAINFO, but hostname wrong.host.test != localhost)
    {
        var srv = try loopback_quic.LocalH3Server.init(cert_file, key_file);
        defer srv.deinit();
        const srv_thread = try std.Thread.spawn(.{}, loopback_quic.LocalH3Server.run, .{&srv});
        defer srv.stopAndJoin(srv_thread);

        const easy = curl_easy_init() orelse return error.EasyInitFailed;
        defer curl_easy_cleanup(easy);

        var url_buf: [128]u8 = undefined;
        const url = try loopback_http.bufPrintZ(&url_buf, "https://wrong.host.test:{d}/badhost", .{srv.port});

        var resolve_buf: [128]u8 = undefined;
        const resolve_entry = try loopback_http.bufPrintZ(&resolve_buf, "wrong.host.test:{d}:127.0.0.1", .{srv.port});
        const resolve_list = curl_slist_append(null, resolve_entry) orelse return error.SlistAppendFailed;
        defer curl_slist_free_all(resolve_list);

        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_NOSIGNAL, @as(c_long, 1)));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_TIMEOUT_MS, @as(c_long, 5000)));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_HTTP_VERSION, c.CURL_HTTP_VERSION_3ONLY));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_SSL_VERIFYPEER, @as(c_long, 1)));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_SSL_VERIFYHOST, @as(c_long, 2)));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_CAINFO, ca_file));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_RESOLVE, resolve_list));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_URL, url));

        const rc = curl_easy_perform(easy);
        try testing.expectEqual(c.CURLE_PEER_FAILED_VERIFICATION, rc);
    }

    // 6. HTTPS-RR alpn=h3 negotiation via DoH (default CURLOPT_HTTP_VERSION upgrades to HTTP/3 via HTTPS RR)
    if (comptime backend_options.httpsrr) {
        var doh_srv = try loopback_dns.DohHttpServer.init();
        doh_srv.https_alpn_h3 = true;
        defer doh_srv.deinit();
        const doh_thread = try std.Thread.spawn(.{}, loopback_dns.DohHttpServer.run, .{&doh_srv});
        defer doh_srv.stopAndJoin(doh_thread);

        var h3_srv = try loopback_quic.LocalH3Server.init(cert_file, key_file);
        defer h3_srv.deinit();
        const h3_thread = try std.Thread.spawn(.{}, loopback_quic.LocalH3Server.run, .{&h3_srv});
        defer h3_srv.stopAndJoin(h3_thread);

        const easy = curl_easy_init() orelse return error.EasyInitFailed;
        defer curl_easy_cleanup(easy);

        var doh_url_buf: [128]u8 = undefined;
        const doh_url = try loopback_http.bufPrintZ(&doh_url_buf, "http://127.0.0.1:{d}/dns-query", .{doh_srv.port});

        var url_buf: [128]u8 = undefined;
        const url = try loopback_http.bufPrintZ(&url_buf, "https://h3-doh.test:{d}/get", .{h3_srv.port});

        var cap = loopback_http.BodySink{};
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_NOSIGNAL, @as(c_long, 1)));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_TIMEOUT_MS, @as(c_long, 5000)));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_DOH_URL, doh_url));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_SSL_VERIFYPEER, @as(c_long, 1)));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_SSL_VERIFYHOST, @as(c_long, 0)));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_CAINFO, ca_file));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_WRITEFUNCTION, &loopback_http.writeCallback));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_WRITEDATA, &cap));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_URL, url));

        try testing.expectEqual(c.CURLE_OK, curl_easy_perform(easy));
        try testing.expect(doh_srv.saw_a.load(.acquire));
        try testing.expect(doh_srv.saw_https.load(.acquire));

        var http_version: c_long = 0;
        try testing.expectEqual(c.CURLE_OK, curl_easy_getinfo(easy, c.CURLINFO_HTTP_VERSION, &http_version));
        try testing.expectEqual(c.CURL_HTTP_VERSION_3, http_version);
        try testing.expectEqualStrings("hello-http3", cap.slice());
    }

    // 7. CURL_HTTP_VERSION_3 happy-eyeballs fallback to HTTP/1.1 TLS when UDP HTTP/3 port is unreachable
    {
        var tcp_port: u16 = 0;
        const listen_fd = try loopback_tls.openLoopbackListener(&tcp_port);
        defer _ = loopback_tls.sock_c.close(listen_fd);
        const tcp_thread = try std.Thread.spawn(.{}, loopback_tls.serveOnce, .{listen_fd});
        defer tcp_thread.join();

        const easy = curl_easy_init() orelse return error.EasyInitFailed;
        defer curl_easy_cleanup(easy);

        var url_buf: [128]u8 = undefined;
        const url = try loopback_http.bufPrintZ(&url_buf, "https://localhost:{d}/fallback", .{tcp_port});

        var resolve_buf: [128]u8 = undefined;
        const resolve_entry = try loopback_http.bufPrintZ(&resolve_buf, "localhost:{d}:127.0.0.1", .{tcp_port});
        const resolve_list = curl_slist_append(null, resolve_entry) orelse return error.SlistAppendFailed;
        defer curl_slist_free_all(resolve_list);

        var cap = loopback_http.BodySink{};
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_NOSIGNAL, @as(c_long, 1)));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_TIMEOUT_MS, @as(c_long, 5000)));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_HTTP_VERSION, c.CURL_HTTP_VERSION_3));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_SSL_VERIFYPEER, @as(c_long, 1)));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_SSL_VERIFYHOST, @as(c_long, 2)));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_CAINFO, ca_file));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_RESOLVE, resolve_list));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_WRITEFUNCTION, &loopback_http.writeCallback));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_WRITEDATA, &cap));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_URL, url));

        try testing.expectEqual(c.CURLE_OK, curl_easy_perform(easy));

        var status_code: c_long = 0;
        try testing.expectEqual(c.CURLE_OK, curl_easy_getinfo(easy, c.CURLINFO_RESPONSE_CODE, &status_code));
        try testing.expectEqual(@as(c_long, 200), status_code);
        try testing.expectEqualStrings("ok", cap.slice());
    }
}

const UploadReader = struct {
    data: []const u8,
    pos: usize = 0,

    fn readCallback(ptr: [*]u8, size: usize, nmemb: usize, userdata: ?*anyopaque) callconv(.c) usize {
        const self: *UploadReader = @ptrCast(@alignCast(userdata orelse return 0));
        const max_bytes = size * nmemb;
        const rem = self.data.len - self.pos;
        const n = @min(max_bytes, rem);
        if (n > 0) {
            @memcpy(ptr[0..n], self.data[self.pos .. self.pos + n]);
            self.pos += n;
        }
        return n;
    }
};

test "SFTP and SCP end-to-end local sshd server: download, upload, quote, range, known_hosts, and host_public_key_sha256" {
    if (comptime (backend_options.ssh == .none or builtin.os.tag != .linux)) return;

    const gpa = testing.allocator;
    const io = testing.io;

    var tmp = testing.tmpDir(.{});
    defer tmp.cleanup();

    const dir_abs = try tmp.dir.realPathFileAlloc(io, ".", gpa);
    defer gpa.free(dir_abs);

    // Pick an available ephemeral loopback port
    var port: u16 = 0;
    {
        const fd = try loopback_tls.openLoopbackListener(&port);
        _ = loopback_tls.sock_c.close(fd);
    }

    const host_key_path = try std.fmt.allocPrintSentinel(gpa, "{s}/host_key", .{dir_abs}, 0);
    defer gpa.free(host_key_path);
    const user_key_path = try std.fmt.allocPrintSentinel(gpa, "{s}/user_key", .{dir_abs}, 0);
    defer gpa.free(user_key_path);
    const user_pub_path = try std.fmt.allocPrintSentinel(gpa, "{s}/user_key.pub", .{dir_abs}, 0);
    defer gpa.free(user_pub_path);
    const known_hosts_path = try std.fmt.allocPrintSentinel(gpa, "{s}/known_hosts", .{dir_abs}, 0);
    defer gpa.free(known_hosts_path);
    const sshd_cfg_path = try std.fmt.allocPrintSentinel(gpa, "{s}/sshd_config", .{dir_abs}, 0);
    defer gpa.free(sshd_cfg_path);
    const sshd_log_path = try std.fmt.allocPrintSentinel(gpa, "{s}/sshd.log", .{dir_abs}, 0);
    defer gpa.free(sshd_log_path);

    const kg_host = try std.process.run(gpa, io, .{
        .argv = &.{ "ssh-keygen", "-q", "-t", "ed25519", "-N", "", "-f", host_key_path },
    });
    defer gpa.free(kg_host.stdout);
    defer gpa.free(kg_host.stderr);
    try testing.expectEqual(std.process.Child.Term{ .exited = 0 }, kg_host.term);

    const kg_user = try std.process.run(gpa, io, .{
        .argv = &.{ "ssh-keygen", "-q", "-t", "ed25519", "-N", "", "-f", user_key_path },
    });
    defer gpa.free(kg_user.stdout);
    defer gpa.free(kg_user.stderr);
    try testing.expectEqual(std.process.Child.Term{ .exited = 0 }, kg_user.term);

    const host_pub_content = try tmp.dir.readFileAlloc(io, "host_key.pub", gpa, .limited(4096));
    defer gpa.free(host_pub_content);

    // Compute SHA256 base64 fingerprint of the host public key blob
    var tok_it = std.mem.tokenizeAny(u8, host_pub_content, " \t\r\n");
    _ = tok_it.next(); // key type ("ssh-ed25519")
    const host_pub_b64 = tok_it.next() orelse return error.InvalidHostPubKey;
    var raw_key_buf: [512]u8 = undefined;
    const decoded_len = try std.base64.standard.Decoder.calcSizeForSlice(host_pub_b64);
    try std.base64.standard.Decoder.decode(raw_key_buf[0..decoded_len], host_pub_b64);
    var sha256_digest: [32]u8 = undefined;
    std.crypto.hash.sha2.Sha256.hash(raw_key_buf[0..decoded_len], &sha256_digest, .{});
    var sha256_b64_buf: [64]u8 = undefined;
    const sha256_b64 = std.base64.standard.Encoder.encode(&sha256_b64_buf, &sha256_digest);
    var sha256_z_buf: [65]u8 = undefined;
    const host_sha256_z = try loopback_http.bufPrintZ(&sha256_z_buf, "{s}", .{sha256_b64});

    const kh_data = try std.fmt.allocPrint(
        gpa,
        "[127.0.0.1]:{d} {s}127.0.0.1 {s}",
        .{ port, host_pub_content, host_pub_content },
    );
    defer gpa.free(kh_data);
    try tmp.dir.writeFile(io, .{ .sub_path = "known_hosts", .data = kh_data });

    const download_payload = "hello-zig-sftp-download-payload\n";
    try tmp.dir.writeFile(io, .{ .sub_path = "hello.txt", .data = download_payload });

    const sshd_cfg = try std.fmt.allocPrint(
        gpa,
        "ListenAddress 127.0.0.1:{d}\n" ++
            "HostKey {s}\n" ++
            "AuthorizedKeysFile {s}\n" ++
            "PasswordAuthentication no\n" ++
            "PubkeyAuthentication yes\n" ++
            "UsePAM no\n" ++
            "StrictModes no\n" ++
            "PidFile {s}/sshd.pid\n" ++
            "Subsystem sftp internal-sftp\n",
        .{ port, host_key_path, user_pub_path, dir_abs },
    );
    defer gpa.free(sshd_cfg);
    try tmp.dir.writeFile(io, .{ .sub_path = "sshd_config", .data = sshd_cfg });

    var sshd_child = try std.process.spawn(io, .{
        .argv = &.{ "/usr/sbin/sshd", "-D", "-f", sshd_cfg_path, "-E", sshd_log_path },
        .stdin = .ignore,
        .stdout = .ignore,
        .stderr = .ignore,
    });
    defer {
        sshd_child.kill(io);
    }

    // Wait for sshd to start listening on 127.0.0.1:port
    {
        var ready = false;
        var attempt: usize = 0;
        while (attempt < 60) : (attempt += 1) {
            const probe_fd = loopback_tls.sock_c.socket(loopback_tls.sock_c.AF_INET, loopback_tls.sock_c.SOCK_STREAM, 0);
            if (probe_fd >= 0) {
                var addr = loopback_tls.sock_c.sockaddr_in{
                    .sin_family = loopback_tls.sock_c.AF_INET,
                    .sin_port = std.mem.nativeToBig(u16, port),
                    .sin_addr = std.mem.nativeToBig(u32, 0x7f000001),
                };
                const connect_fn = struct {
                    extern "c" fn connect(sockfd: c_int, addr: *const loopback_tls.sock_c.sockaddr_in, addrlen: u32) c_int;
                }.connect;
                const rc = connect_fn(probe_fd, &addr, @sizeOf(loopback_tls.sock_c.sockaddr_in));
                _ = loopback_tls.sock_c.close(probe_fd);
                if (rc == 0) {
                    ready = true;
                    break;
                }
            }
            var ts = std.os.linux.timespec{ .sec = 0, .nsec = 50 * std.time.ns_per_ms };
            _ = std.os.linux.nanosleep(&ts, null);
        }
        try testing.expect(ready);
    }

    const user_c = std.c.getenv("USER") orelse std.c.getenv("LOGNAME") orelse "root";
    const user_str = std.mem.span(user_c);
    var userpwd_buf: [128]u8 = undefined;
    const userpwd_z = try loopback_http.bufPrintZ(&userpwd_buf, "{s}:", .{user_str});

    const user_key_z = user_key_path;
    const user_pub_z = user_pub_path;
    const known_hosts_z = known_hosts_path;

    // 1. SFTP download with CURLOPT_SSH_KNOWNHOSTS
    {
        const easy = curl_easy_init() orelse return error.EasyInitFailed;
        defer curl_easy_cleanup(easy);

        const url_z = try std.fmt.allocPrintSentinel(gpa, "sftp://127.0.0.1:{d}{s}/hello.txt", .{ port, dir_abs }, 0);
        defer gpa.free(url_z);

        var cap = loopback_http.BodySink{};
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_NOSIGNAL, @as(c_long, 1)));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_TIMEOUT_MS, @as(c_long, 5000)));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_USERPWD, userpwd_z));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_SSH_AUTH_TYPES, c.CURLSSH_AUTH_PUBLICKEY));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_SSH_PRIVATE_KEYFILE, user_key_z.ptr));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_SSH_PUBLIC_KEYFILE, user_pub_z.ptr));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_SSH_KNOWNHOSTS, known_hosts_z.ptr));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_WRITEFUNCTION, &loopback_http.writeCallback));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_WRITEDATA, &cap));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_URL, url_z.ptr));

        try testing.expectEqual(c.CURLE_OK, curl_easy_perform(easy));
        try testing.expectEqualStrings(download_payload, cap.slice());
    }

    // 2. SFTP download with CURLOPT_SSH_HOST_PUBLIC_KEY_SHA256 (matching + mismatched fingerprint rejection)
    {
        const easy = curl_easy_init() orelse return error.EasyInitFailed;
        defer curl_easy_cleanup(easy);

        const url_z = try std.fmt.allocPrintSentinel(gpa, "sftp://127.0.0.1:{d}{s}/hello.txt", .{ port, dir_abs }, 0);
        defer gpa.free(url_z);

        var cap = loopback_http.BodySink{};
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_NOSIGNAL, @as(c_long, 1)));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_TIMEOUT_MS, @as(c_long, 5000)));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_USERPWD, userpwd_z));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_SSH_AUTH_TYPES, c.CURLSSH_AUTH_PUBLICKEY));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_SSH_PRIVATE_KEYFILE, user_key_z.ptr));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_SSH_PUBLIC_KEYFILE, user_pub_z.ptr));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_SSH_HOST_PUBLIC_KEY_SHA256, host_sha256_z));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_WRITEFUNCTION, &loopback_http.writeCallback));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_WRITEDATA, &cap));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_URL, url_z.ptr));

        try testing.expectEqual(c.CURLE_OK, curl_easy_perform(easy));
        try testing.expectEqualStrings(download_payload, cap.slice());

        // Mismatched SHA256 fingerprint must fail verification
        const bad_easy = curl_easy_init() orelse return error.EasyInitFailed;
        defer curl_easy_cleanup(bad_easy);
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(bad_easy, c.CURLOPT_NOSIGNAL, @as(c_long, 1)));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(bad_easy, c.CURLOPT_TIMEOUT_MS, @as(c_long, 5000)));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(bad_easy, c.CURLOPT_USERPWD, userpwd_z));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(bad_easy, c.CURLOPT_SSH_AUTH_TYPES, c.CURLSSH_AUTH_PUBLICKEY));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(bad_easy, c.CURLOPT_SSH_PRIVATE_KEYFILE, user_key_z.ptr));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(bad_easy, c.CURLOPT_SSH_PUBLIC_KEYFILE, user_pub_z.ptr));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(bad_easy, c.CURLOPT_SSH_HOST_PUBLIC_KEY_SHA256, @as([*:0]const u8, "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=")));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(bad_easy, c.CURLOPT_URL, url_z.ptr));

        try testing.expectEqual(c.CURLE_PEER_FAILED_VERIFICATION, curl_easy_perform(bad_easy));
    }

    // 3. SFTP byte-range download (CURLOPT_RANGE = "6-13" -> "zig-sftp")
    {
        const easy = curl_easy_init() orelse return error.EasyInitFailed;
        defer curl_easy_cleanup(easy);

        const url_z = try std.fmt.allocPrintSentinel(gpa, "sftp://127.0.0.1:{d}{s}/hello.txt", .{ port, dir_abs }, 0);
        defer gpa.free(url_z);

        var cap = loopback_http.BodySink{};
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_NOSIGNAL, @as(c_long, 1)));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_TIMEOUT_MS, @as(c_long, 5000)));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_USERPWD, userpwd_z));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_SSH_AUTH_TYPES, c.CURLSSH_AUTH_PUBLICKEY));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_SSH_PRIVATE_KEYFILE, user_key_z.ptr));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_SSH_PUBLIC_KEYFILE, user_pub_z.ptr));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_SSH_KNOWNHOSTS, known_hosts_z.ptr));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_RANGE, @as([*:0]const u8, "6-13")));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_WRITEFUNCTION, &loopback_http.writeCallback));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_WRITEDATA, &cap));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_URL, url_z.ptr));

        try testing.expectEqual(c.CURLE_OK, curl_easy_perform(easy));
        try testing.expectEqualStrings("zig-sftp", cap.slice());
    }

    // 4. SFTP upload + QUOTE (mkdir) + POSTQUOTE (rename)
    {
        const easy = curl_easy_init() orelse return error.EasyInitFailed;
        defer curl_easy_cleanup(easy);

        const upload_data = "uploaded-via-zig-sftp-with-quote-commands\n";
        var reader = UploadReader{ .data = upload_data };

        const url_z = try std.fmt.allocPrintSentinel(gpa, "sftp://127.0.0.1:{d}{s}/sub_q/upload_tmp.txt", .{ port, dir_abs }, 0);
        defer gpa.free(url_z);

        const mkdir_cmd = try std.fmt.allocPrintSentinel(gpa, "mkdir {s}/sub_q", .{dir_abs}, 0);
        defer gpa.free(mkdir_cmd);
        const rename_cmd = try std.fmt.allocPrintSentinel(gpa, "rename {s}/sub_q/upload_tmp.txt {s}/sub_q/upload_final.txt", .{ dir_abs, dir_abs }, 0);
        defer gpa.free(rename_cmd);

        const quote_list = curl_slist_append(null, mkdir_cmd.ptr) orelse return error.SlistAppendFailed;
        defer curl_slist_free_all(quote_list);
        const postquote_list = curl_slist_append(null, rename_cmd.ptr) orelse return error.SlistAppendFailed;
        defer curl_slist_free_all(postquote_list);

        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_NOSIGNAL, @as(c_long, 1)));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_TIMEOUT_MS, @as(c_long, 5000)));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_USERPWD, userpwd_z));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_SSH_AUTH_TYPES, c.CURLSSH_AUTH_PUBLICKEY));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_SSH_PRIVATE_KEYFILE, user_key_z.ptr));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_SSH_PUBLIC_KEYFILE, user_pub_z.ptr));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_SSH_KNOWNHOSTS, known_hosts_z.ptr));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_QUOTE, quote_list));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_POSTQUOTE, postquote_list));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_UPLOAD, @as(c_long, 1)));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_READFUNCTION, &UploadReader.readCallback));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_READDATA, &reader));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_INFILESIZE_LARGE, @as(i64, @intCast(upload_data.len))));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_URL, url_z.ptr));

        try testing.expectEqual(c.CURLE_OK, curl_easy_perform(easy));

        const written = try tmp.dir.readFileAlloc(io, "sub_q/upload_final.txt", gpa, .limited(256));
        defer gpa.free(written);
        try testing.expectEqualStrings(upload_data, written);
    }

    // 5. SFTP directory listing
    {
        const easy = curl_easy_init() orelse return error.EasyInitFailed;
        defer curl_easy_cleanup(easy);

        const url_z = try std.fmt.allocPrintSentinel(gpa, "sftp://127.0.0.1:{d}{s}/", .{ port, dir_abs }, 0);
        defer gpa.free(url_z);

        var cap = loopback_http.BodySink{};
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_NOSIGNAL, @as(c_long, 1)));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_TIMEOUT_MS, @as(c_long, 5000)));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_USERPWD, userpwd_z));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_SSH_AUTH_TYPES, c.CURLSSH_AUTH_PUBLICKEY));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_SSH_PRIVATE_KEYFILE, user_key_z.ptr));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_SSH_PUBLIC_KEYFILE, user_pub_z.ptr));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_SSH_KNOWNHOSTS, known_hosts_z.ptr));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_WRITEFUNCTION, &loopback_http.writeCallback));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_WRITEDATA, &cap));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_URL, url_z.ptr));

        try testing.expectEqual(c.CURLE_OK, curl_easy_perform(easy));
        try testing.expect(std.mem.indexOf(u8, cap.slice(), "hello.txt") != null);
    }

    // 6. SCP download and upload
    {
        const easy_dl = curl_easy_init() orelse return error.EasyInitFailed;
        defer curl_easy_cleanup(easy_dl);

        const dl_url_z = try std.fmt.allocPrintSentinel(gpa, "scp://127.0.0.1:{d}{s}/hello.txt", .{ port, dir_abs }, 0);
        defer gpa.free(dl_url_z);

        var cap = loopback_http.BodySink{};
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy_dl, c.CURLOPT_NOSIGNAL, @as(c_long, 1)));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy_dl, c.CURLOPT_TIMEOUT_MS, @as(c_long, 5000)));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy_dl, c.CURLOPT_USERPWD, userpwd_z));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy_dl, c.CURLOPT_SSH_AUTH_TYPES, c.CURLSSH_AUTH_PUBLICKEY));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy_dl, c.CURLOPT_SSH_PRIVATE_KEYFILE, user_key_z.ptr));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy_dl, c.CURLOPT_SSH_PUBLIC_KEYFILE, user_pub_z.ptr));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy_dl, c.CURLOPT_SSH_KNOWNHOSTS, known_hosts_z.ptr));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy_dl, c.CURLOPT_WRITEFUNCTION, &loopback_http.writeCallback));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy_dl, c.CURLOPT_WRITEDATA, &cap));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy_dl, c.CURLOPT_URL, dl_url_z.ptr));

        try testing.expectEqual(c.CURLE_OK, curl_easy_perform(easy_dl));
        try testing.expectEqualStrings(download_payload, cap.slice());

        const easy_ul = curl_easy_init() orelse return error.EasyInitFailed;
        defer curl_easy_cleanup(easy_ul);

        const scp_upload_data = "uploaded-via-zig-scp-protocol\n";
        var reader = UploadReader{ .data = scp_upload_data };
        const ul_url_z = try std.fmt.allocPrintSentinel(gpa, "scp://127.0.0.1:{d}{s}/scp_uploaded.txt", .{ port, dir_abs }, 0);
        defer gpa.free(ul_url_z);

        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy_ul, c.CURLOPT_NOSIGNAL, @as(c_long, 1)));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy_ul, c.CURLOPT_TIMEOUT_MS, @as(c_long, 5000)));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy_ul, c.CURLOPT_USERPWD, userpwd_z));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy_ul, c.CURLOPT_SSH_AUTH_TYPES, c.CURLSSH_AUTH_PUBLICKEY));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy_ul, c.CURLOPT_SSH_PRIVATE_KEYFILE, user_key_z.ptr));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy_ul, c.CURLOPT_SSH_PUBLIC_KEYFILE, user_pub_z.ptr));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy_ul, c.CURLOPT_SSH_KNOWNHOSTS, known_hosts_z.ptr));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy_ul, c.CURLOPT_UPLOAD, @as(c_long, 1)));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy_ul, c.CURLOPT_READFUNCTION, &UploadReader.readCallback));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy_ul, c.CURLOPT_READDATA, &reader));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy_ul, c.CURLOPT_INFILESIZE_LARGE, @as(i64, @intCast(scp_upload_data.len))));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy_ul, c.CURLOPT_URL, ul_url_z.ptr));

        try testing.expectEqual(c.CURLE_OK, curl_easy_perform(easy_ul));

        const scp_written = try tmp.dir.readFileAlloc(io, "scp_uploaded.txt", gpa, .limited(256));
        defer gpa.free(scp_written);
        try testing.expectEqualStrings(scp_upload_data, scp_written);
    }
}

// ============================================================================
// Local Loopback LDAPv3 / LDAPS / StartTLS Tests (#71)
// ============================================================================

const loopback_ldap = struct {
    const Mode = enum {
        plain,
        ldaps,
        starttls,
    };

    const ServerConfig = struct {
        listen_fd: c_int,
        mode: Mode = .plain,
        expected_dn: ?[]const u8 = null,
        expected_pw: ?[]const u8 = null,
    };

    const Tlv = struct {
        tag: u8,
        val: []const u8,
        total_len: usize,
    };

    fn berWrap(tag: u8, payload: []const u8, out: []u8) []const u8 {
        if (payload.len < 128) {
            out[0] = tag;
            out[1] = @intCast(payload.len);
            @memcpy(out[2 .. 2 + payload.len], payload);
            return out[0 .. 2 + payload.len];
        } else if (payload.len < 256) {
            out[0] = tag;
            out[1] = 0x81;
            out[2] = @intCast(payload.len);
            @memcpy(out[3 .. 3 + payload.len], payload);
            return out[0 .. 3 + payload.len];
        } else {
            out[0] = tag;
            out[1] = 0x82;
            out[2] = @intCast((payload.len >> 8) & 0xff);
            out[3] = @intCast(payload.len & 0xff);
            @memcpy(out[4 .. 4 + payload.len], payload);
            return out[0 .. 4 + payload.len];
        }
    }

    fn berWrap2(tag: u8, a: []const u8, b: []const u8, out: []u8) []const u8 {
        var tmp: [1024]u8 = undefined;
        @memcpy(tmp[0..a.len], a);
        @memcpy(tmp[a.len .. a.len + b.len], b);
        return berWrap(tag, tmp[0 .. a.len + b.len], out);
    }

    fn berParseTlv(buf: []const u8) ?Tlv {
        if (buf.len < 2) return null;
        const tag = buf[0];
        const len0 = buf[1];
        if ((len0 & 0x80) == 0) {
            const vlen: usize = len0;
            if (buf.len < 2 + vlen) return null;
            return .{ .tag = tag, .val = buf[2 .. 2 + vlen], .total_len = 2 + vlen };
        }
        const nlen: usize = len0 & 0x7f;
        if (nlen == 0 or nlen > 4 or buf.len < 2 + nlen) return null;
        var vlen: usize = 0;
        for (buf[2 .. 2 + nlen]) |b| {
            vlen = (vlen << 8) | b;
        }
        if (buf.len < 2 + nlen + vlen) return null;
        return .{ .tag = tag, .val = buf[2 + nlen .. 2 + nlen + vlen], .total_len = 2 + nlen + vlen };
    }

    const IoStream = struct {
        fd: c_int,
        ssl: ?*anyopaque = null,

        fn readExact(self: *IoStream, buf: []u8) bool {
            var total: usize = 0;
            while (total < buf.len) {
                const n: isize = if (self.ssl) |s|
                    @intCast(loopback_tls.ossl.SSL_read(s, buf[total..].ptr, @intCast(buf.len - total)))
                else
                    loopback_tls.sock_c.recv(self.fd, buf[total..].ptr, buf.len - total, 0);
                if (n <= 0) return false;
                total += @intCast(n);
            }
            return true;
        }

        fn writeAll(self: *IoStream, data: []const u8) bool {
            var total: usize = 0;
            while (total < data.len) {
                const n: isize = if (self.ssl) |s|
                    @intCast(loopback_tls.ossl.SSL_write(s, data[total..].ptr, @intCast(data.len - total)))
                else
                    loopback_tls.sock_c.send(self.fd, data[total..].ptr, data.len - total, 0);
                if (n <= 0) return false;
                total += @intCast(n);
            }
            return true;
        }
    };

    fn readLdapMessage(stream: *IoStream, buf: []u8) ?[]const u8 {
        var hdr: [2]u8 = undefined;
        if (!stream.readExact(&hdr)) return null;
        if (hdr[0] != 0x30) return null;

        var vlen: usize = 0;
        if ((hdr[1] & 0x80) == 0) {
            vlen = hdr[1];
        } else {
            const nlen: usize = hdr[1] & 0x7f;
            if (nlen == 0 or nlen > 4) return null;
            var len_bytes: [4]u8 = undefined;
            if (!stream.readExact(len_bytes[0..nlen])) return null;
            for (len_bytes[0..nlen]) |b| {
                vlen = (vlen << 8) | b;
            }
        }
        if (vlen > buf.len) return null;
        if (!stream.readExact(buf[0..vlen])) return null;
        return buf[0..vlen];
    }

    fn buildAttr(attr_type: []const u8, attr_val: []const u8, out: []u8) []const u8 {
        var t_buf: [128]u8 = undefined;
        var v_buf: [256]u8 = undefined;
        var set_buf: [256]u8 = undefined;
        const t_tlv = berWrap(0x04, attr_type, &t_buf);
        const v_tlv = berWrap(0x04, attr_val, &v_buf);
        const set_tlv = berWrap(0x31, v_tlv, &set_buf);
        return berWrap2(0x30, t_tlv, set_tlv, out);
    }

    fn buildSearchResultEntry(msg_id_raw: []const u8, out: []u8) []const u8 {
        var dn_buf: [128]u8 = undefined;
        const dn_tlv = berWrap(0x04, "cn=Alice,dc=example,dc=com", &dn_buf);

        var a1_buf: [128]u8 = undefined;
        var a2_buf: [128]u8 = undefined;
        var a3_buf: [128]u8 = undefined;
        var a4_buf: [128]u8 = undefined;
        const a1 = buildAttr("cn", "Alice", &a1_buf);
        const a2 = buildAttr("mail", "alice@example.com", &a2_buf);
        const a3 = buildAttr("description", ":secret-note", &a3_buf);
        const a4 = buildAttr("userCertificate;binary", "CERT", &a4_buf);

        var attrs_cat: [512]u8 = undefined;
        var pos: usize = 0;
        for ([_][]const u8{ a1, a2, a3, a4 }) |a| {
            @memcpy(attrs_cat[pos .. pos + a.len], a);
            pos += a.len;
        }

        var attrs_seq_buf: [512]u8 = undefined;
        const attrs_seq = berWrap(0x30, attrs_cat[0..pos], &attrs_seq_buf);

        var entry_op_buf: [768]u8 = undefined;
        const entry_op = berWrap2(0x64, dn_tlv, attrs_seq, &entry_op_buf);

        return berWrap2(0x30, msg_id_raw, entry_op, out);
    }

    fn buildLdapResultMsg(msg_id_raw: []const u8, op_tag: u8, result_code: u8, out: []u8) []const u8 {
        const res_body = [_]u8{ 0x0a, 0x01, result_code, 0x04, 0x00, 0x04, 0x00 };
        var op_buf: [32]u8 = undefined;
        const op_tlv = berWrap(op_tag, &res_body, &op_buf);
        return berWrap2(0x30, msg_id_raw, op_tlv, out);
    }

    fn createOpenSslServerCtx() ?*anyopaque {
        if (comptime backend_options.ssl != .openssl) return null;
        const method = loopback_tls.ossl.TLS_server_method() orelse return null;
        const ctx = loopback_tls.ossl.SSL_CTX_new(method) orelse return null;

        const cert_bio = loopback_tls.ossl.BIO_new_mem_buf(
            loopback_tls.test_server_cert_pem.ptr,
            @intCast(loopback_tls.test_server_cert_pem.len),
        ) orelse {
            loopback_tls.ossl.SSL_CTX_free(ctx);
            return null;
        };
        defer _ = loopback_tls.ossl.BIO_free(cert_bio);
        const x509 = loopback_tls.ossl.PEM_read_bio_X509(cert_bio, null, null, null) orelse {
            loopback_tls.ossl.SSL_CTX_free(ctx);
            return null;
        };
        defer loopback_tls.ossl.X509_free(x509);
        if (loopback_tls.ossl.SSL_CTX_use_certificate(ctx, x509) != 1) {
            loopback_tls.ossl.SSL_CTX_free(ctx);
            return null;
        }

        const key_bio = loopback_tls.ossl.BIO_new_mem_buf(
            loopback_tls.test_server_key_pem.ptr,
            @intCast(loopback_tls.test_server_key_pem.len),
        ) orelse {
            loopback_tls.ossl.SSL_CTX_free(ctx);
            return null;
        };
        defer _ = loopback_tls.ossl.BIO_free(key_bio);
        const pkey = loopback_tls.ossl.PEM_read_bio_PrivateKey(key_bio, null, null, null) orelse {
            loopback_tls.ossl.SSL_CTX_free(ctx);
            return null;
        };
        defer loopback_tls.ossl.EVP_PKEY_free(pkey);
        if (loopback_tls.ossl.SSL_CTX_use_PrivateKey(ctx, pkey) != 1) {
            loopback_tls.ossl.SSL_CTX_free(ctx);
            return null;
        }
        return ctx;
    }

    fn serveOnce(cfg: ServerConfig) void {
        var dummy_fd: c_int = -1;
        defer if (dummy_fd >= 0) {
            _ = loopback_tls.sock_c.close(dummy_fd);
        };
        var dummy_ssl: ?*anyopaque = null;
        defer if (dummy_ssl) |s| {
            if (comptime backend_options.ssl == .openssl) {
                loopback_tls.ossl.SSL_free(s);
            }
        };

        var ssl_ctx: ?*anyopaque = null;
        defer if (ssl_ctx) |ctx| {
            if (comptime backend_options.ssl == .openssl) loopback_tls.ossl.SSL_CTX_free(ctx);
        };

        if (comptime backend_options.ldap == .ldap) {
            // Legacy lib/ldap.c connects conn->sock[FIRSTSOCKET] during Curl_connect
            // and then opens a second socket inside ldap_init() during legacyLdapDo.
            dummy_fd = loopback_tls.sock_c.accept(cfg.listen_fd, null, null);
            if (dummy_fd < 0) return;
            loopback_tls.setSocketTimeouts(dummy_fd);
            if (cfg.mode == .ldaps) {
                if (comptime backend_options.ssl != .openssl) return;
                ssl_ctx = createOpenSslServerCtx() orelse return;
                dummy_ssl = loopback_tls.ossl.SSL_new(ssl_ctx.?) orelse return;
                if (loopback_tls.ossl.SSL_set_fd(dummy_ssl.?, dummy_fd) != 1) return;
                if (loopback_tls.ossl.SSL_accept(dummy_ssl.?) != 1) return;
            }
        }

        const client_fd = loopback_tls.sock_c.accept(cfg.listen_fd, null, null);
        if (client_fd < 0) return;
        defer _ = loopback_tls.sock_c.close(client_fd);
        loopback_tls.setSocketTimeouts(client_fd);

        var ssl_handle: ?*anyopaque = null;
        defer if (ssl_handle) |s| {
            if (comptime backend_options.ssl == .openssl) {
                _ = loopback_tls.ossl.SSL_shutdown(s);
                loopback_tls.ossl.SSL_free(s);
            }
        };

        var stream = IoStream{ .fd = client_fd };

        if (cfg.mode == .ldaps) {
            if (comptime backend_options.ssl != .openssl) return;
            if (ssl_ctx == null) {
                ssl_ctx = createOpenSslServerCtx() orelse return;
            }
            ssl_handle = loopback_tls.ossl.SSL_new(ssl_ctx.?) orelse return;
            if (loopback_tls.ossl.SSL_set_fd(ssl_handle.?, client_fd) != 1) return;
            if (loopback_tls.ossl.SSL_accept(ssl_handle.?) != 1) return;
            stream.ssl = ssl_handle;
        }

        var msg_buf: [2048]u8 = undefined;
        while (readLdapMessage(&stream, &msg_buf)) |body| {
            const id_tlv = berParseTlv(body) orelse break;
            if (id_tlv.tag != 0x02) break;
            const msg_id_raw = body[0..id_tlv.total_len];
            const op_tlv = berParseTlv(body[id_tlv.total_len..]) orelse break;

            switch (op_tlv.tag) {
                0x77 => {
                    // ExtendedRequest (StartTLS)
                    var out_buf: [128]u8 = undefined;
                    const resp = buildLdapResultMsg(msg_id_raw, 0x78, 0x00, &out_buf);
                    if (!stream.writeAll(resp)) break;
                    if (cfg.mode == .starttls and stream.ssl == null) {
                        if (comptime backend_options.ssl != .openssl) break;
                        ssl_ctx = createOpenSslServerCtx() orelse break;
                        ssl_handle = loopback_tls.ossl.SSL_new(ssl_ctx.?) orelse break;
                        if (loopback_tls.ossl.SSL_set_fd(ssl_handle.?, client_fd) != 1) break;
                        if (loopback_tls.ossl.SSL_accept(ssl_handle.?) != 1) break;
                        stream.ssl = ssl_handle;
                    }
                },
                0x60 => {
                    // BindRequest
                    const ver_tlv = berParseTlv(op_tlv.val) orelse break;
                    const dn_tlv = berParseTlv(op_tlv.val[ver_tlv.total_len..]) orelse break;
                    const auth_tlv = berParseTlv(op_tlv.val[ver_tlv.total_len + dn_tlv.total_len ..]) orelse break;

                    var creds_ok = true;
                    if (cfg.expected_dn) |exp_dn| {
                        if (!std.mem.eql(u8, dn_tlv.val, exp_dn)) creds_ok = false;
                    }
                    if (cfg.expected_pw) |exp_pw| {
                        if (auth_tlv.tag != 0x80 or !std.mem.eql(u8, auth_tlv.val, exp_pw)) creds_ok = false;
                    }

                    const result_code: u8 = if (creds_ok) 0x00 else 0x31; // 49 = invalidCredentials
                    var out_buf: [128]u8 = undefined;
                    const resp = buildLdapResultMsg(msg_id_raw, 0x61, result_code, &out_buf);
                    if (!stream.writeAll(resp)) break;
                },
                0x63 => {
                    // SearchRequest -> send SearchResultEntry + SearchResultDone
                    var entry_buf: [1024]u8 = undefined;
                    const entry_msg = buildSearchResultEntry(msg_id_raw, &entry_buf);
                    if (!stream.writeAll(entry_msg)) break;

                    var done_buf: [128]u8 = undefined;
                    const done_msg = buildLdapResultMsg(msg_id_raw, 0x65, 0x00, &done_buf);
                    if (!stream.writeAll(done_msg)) break;
                },
                0x42 => break, // UnbindRequest
                else => break,
            }
        }
    }
};

test "LDAP loopback: anonymous search with plain, unsafe, and ;binary attributes" {
    if (!backend_options.has_ldap) return;
    if (builtin.os.tag == .windows) return;

    var port: u16 = 0;
    const listen_fd = try loopback_tls.openLoopbackListener(&port);
    defer _ = loopback_tls.sock_c.close(listen_fd);

    const server_thread = try std.Thread.spawn(.{}, loopback_ldap.serveOnce, .{loopback_ldap.ServerConfig{
        .listen_fd = listen_fd,
        .mode = .plain,
    }});
    defer server_thread.join();

    const easy = curl_easy_init() orelse return error.EasyInitFailed;
    defer curl_easy_cleanup(easy);

    const gpa = testing.allocator;
    const url_z = try std.fmt.allocPrintSentinel(
        gpa,
        "ldap://127.0.0.1:{d}/dc=example,dc=com?cn,mail,description,userCertificate;binary?sub?(objectClass=*)",
        .{port},
        0,
    );
    defer gpa.free(url_z);

    var cap = loopback_http.BodySink{};
    try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_NOSIGNAL, @as(c_long, 1)));
    try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_TIMEOUT_MS, @as(c_long, 5000)));
    try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_WRITEFUNCTION, &loopback_http.writeCallback));
    try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_WRITEDATA, &cap));
    try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_URL, url_z.ptr));

    try testing.expectEqual(c.CURLE_OK, curl_easy_perform(easy));

    const expected_ldif =
        "DN: cn=Alice,dc=example,dc=com\n" ++
        "\tcn: Alice\n\n" ++
        "\tmail: alice@example.com\n\n" ++
        "\tdescription:: OnNlY3JldC1ub3Rl\n\n" ++
        "\tuserCertificate;binary:: Q0VSVA==\n\n" ++
        if (backend_options.ldap == .openldap) "\n" else "";
    try testing.expectEqualStrings(expected_ldif, cap.slice());
}

test "LDAP loopback: authenticated simple bind and invalid credentials rejection" {
    if (!backend_options.has_ldap) return;
    if (builtin.os.tag == .windows) return;

    const gpa = testing.allocator;

    // 1. Valid credentials succeed
    {
        var port: u16 = 0;
        const listen_fd = try loopback_tls.openLoopbackListener(&port);
        defer _ = loopback_tls.sock_c.close(listen_fd);

        const server_thread = try std.Thread.spawn(.{}, loopback_ldap.serveOnce, .{loopback_ldap.ServerConfig{
            .listen_fd = listen_fd,
            .mode = .plain,
            .expected_dn = "cn=admin,dc=example,dc=com",
            .expected_pw = "secret",
        }});
        defer server_thread.join();

        const easy = curl_easy_init() orelse return error.EasyInitFailed;
        defer curl_easy_cleanup(easy);

        const url_z = try std.fmt.allocPrintSentinel(gpa, "ldap://127.0.0.1:{d}/dc=example,dc=com?cn?sub?(cn=Alice)", .{port}, 0);
        defer gpa.free(url_z);

        var cap = loopback_http.BodySink{};
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_NOSIGNAL, @as(c_long, 1)));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_TIMEOUT_MS, @as(c_long, 5000)));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_USERPWD, "cn=admin,dc=example,dc=com:secret"));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_WRITEFUNCTION, &loopback_http.writeCallback));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_WRITEDATA, &cap));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_URL, url_z.ptr));

        try testing.expectEqual(c.CURLE_OK, curl_easy_perform(easy));
        try testing.expect(std.mem.indexOf(u8, cap.slice(), "DN: cn=Alice,dc=example,dc=com\n") != null);
    }

    // 2. Invalid password fails with CURLE_LOGIN_DENIED (or CURLE_LDAP_CANNOT_BIND)
    {
        var port: u16 = 0;
        const listen_fd = try loopback_tls.openLoopbackListener(&port);
        defer _ = loopback_tls.sock_c.close(listen_fd);

        const server_thread = try std.Thread.spawn(.{}, loopback_ldap.serveOnce, .{loopback_ldap.ServerConfig{
            .listen_fd = listen_fd,
            .mode = .plain,
            .expected_dn = "cn=admin,dc=example,dc=com",
            .expected_pw = "secret",
        }});
        defer server_thread.join();

        const easy = curl_easy_init() orelse return error.EasyInitFailed;
        defer curl_easy_cleanup(easy);

        const url_z = try std.fmt.allocPrintSentinel(gpa, "ldap://127.0.0.1:{d}/dc=example,dc=com?cn?sub?(cn=Alice)", .{port}, 0);
        defer gpa.free(url_z);

        var cap = loopback_http.BodySink{};
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_NOSIGNAL, @as(c_long, 1)));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_TIMEOUT_MS, @as(c_long, 5000)));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_USERPWD, "cn=admin,dc=example,dc=com:wrong"));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_WRITEFUNCTION, &loopback_http.writeCallback));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_WRITEDATA, &cap));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_URL, url_z.ptr));

        const rc = curl_easy_perform(easy);
        try testing.expect(rc == c.CURLE_LOGIN_DENIED or rc == c.CURLE_LDAP_CANNOT_BIND);
    }
}

test "LDAPS loopback: TLS search with trusted CA and untrusted CA rejection" {
    if (backend_options.ldap != .openldap) return;
    if (!backend_options.has_ldaps) return;
    if (comptime backend_options.ssl != .openssl) return;
    if (builtin.os.tag == .windows) return;

    const gpa = testing.allocator;
    const io = testing.io;
    var tmp = testing.tmpDir(.{});
    defer tmp.cleanup();

    const dir_abs = try tmp.dir.realPathFileAlloc(io, ".", gpa);
    defer gpa.free(dir_abs);

    try tmp.dir.writeFile(io, .{ .sub_path = "ca.pem", .data = loopback_tls.test_ca_cert_pem });
    try tmp.dir.writeFile(io, .{ .sub_path = "untrusted_ca.pem", .data = loopback_tls.test_untrusted_ca_cert_pem });

    const ca_path_z = try std.fmt.allocPrintSentinel(gpa, "{s}/ca.pem", .{dir_abs}, 0);
    defer gpa.free(ca_path_z);
    const untrusted_ca_path_z = try std.fmt.allocPrintSentinel(gpa, "{s}/untrusted_ca.pem", .{dir_abs}, 0);
    defer gpa.free(untrusted_ca_path_z);

    // 1. Trusted CA succeeds over LDAPS
    {
        var port: u16 = 0;
        const listen_fd = try loopback_tls.openLoopbackListener(&port);
        defer _ = loopback_tls.sock_c.close(listen_fd);

        const server_thread = try std.Thread.spawn(.{}, loopback_ldap.serveOnce, .{loopback_ldap.ServerConfig{
            .listen_fd = listen_fd,
            .mode = .ldaps,
        }});
        defer server_thread.join();

        const easy = curl_easy_init() orelse return error.EasyInitFailed;
        defer curl_easy_cleanup(easy);

        const url_z = try std.fmt.allocPrintSentinel(gpa, "ldaps://localhost:{d}/dc=example,dc=com?cn?sub?(cn=Alice)", .{port}, 0);
        defer gpa.free(url_z);

        var cap = loopback_http.BodySink{};
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_NOSIGNAL, @as(c_long, 1)));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_TIMEOUT_MS, @as(c_long, 5000)));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_CAINFO, ca_path_z.ptr));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_WRITEFUNCTION, &loopback_http.writeCallback));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_WRITEDATA, &cap));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_URL, url_z.ptr));

        try testing.expectEqual(c.CURLE_OK, curl_easy_perform(easy));
        try testing.expect(std.mem.indexOf(u8, cap.slice(), "DN: cn=Alice,dc=example,dc=com\n") != null);
    }

    // 2. Untrusted CA is rejected
    {
        var port: u16 = 0;
        const listen_fd = try loopback_tls.openLoopbackListener(&port);
        defer _ = loopback_tls.sock_c.close(listen_fd);

        const server_thread = try std.Thread.spawn(.{}, loopback_ldap.serveOnce, .{loopback_ldap.ServerConfig{
            .listen_fd = listen_fd,
            .mode = .ldaps,
        }});
        defer server_thread.join();

        const easy = curl_easy_init() orelse return error.EasyInitFailed;
        defer curl_easy_cleanup(easy);

        const url_z = try std.fmt.allocPrintSentinel(gpa, "ldaps://localhost:{d}/dc=example,dc=com?cn?sub?(cn=Alice)", .{port}, 0);
        defer gpa.free(url_z);

        var cap = loopback_http.BodySink{};
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_NOSIGNAL, @as(c_long, 1)));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_TIMEOUT_MS, @as(c_long, 5000)));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_CAINFO, untrusted_ca_path_z.ptr));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_WRITEFUNCTION, &loopback_http.writeCallback));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_WRITEDATA, &cap));
        try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_URL, url_z.ptr));

        const rc = curl_easy_perform(easy);
        try testing.expect(rc == c.CURLE_PEER_FAILED_VERIFICATION or rc == c.CURLE_LDAP_CANNOT_BIND);
    }
}

test "LDAP StartTLS loopback: upgrade cleartext ldap:// to TLS before search" {
    if (backend_options.ldap != .openldap) return;
    if (!backend_options.has_ldaps) return;
    if (comptime backend_options.ssl != .openssl) return;
    if (builtin.os.tag == .windows) return;

    const gpa = testing.allocator;
    const io = testing.io;
    var tmp = testing.tmpDir(.{});
    defer tmp.cleanup();

    const dir_abs = try tmp.dir.realPathFileAlloc(io, ".", gpa);
    defer gpa.free(dir_abs);

    try tmp.dir.writeFile(io, .{ .sub_path = "ca.pem", .data = loopback_tls.test_ca_cert_pem });
    const ca_path_z = try std.fmt.allocPrintSentinel(gpa, "{s}/ca.pem", .{dir_abs}, 0);
    defer gpa.free(ca_path_z);

    var port: u16 = 0;
    const listen_fd = try loopback_tls.openLoopbackListener(&port);
    defer _ = loopback_tls.sock_c.close(listen_fd);

    const server_thread = try std.Thread.spawn(.{}, loopback_ldap.serveOnce, .{loopback_ldap.ServerConfig{
        .listen_fd = listen_fd,
        .mode = .starttls,
        .expected_dn = "cn=admin,dc=example,dc=com",
        .expected_pw = "secret",
    }});
    defer server_thread.join();

    const easy = curl_easy_init() orelse return error.EasyInitFailed;
    defer curl_easy_cleanup(easy);

    const url_z = try std.fmt.allocPrintSentinel(gpa, "ldap://localhost:{d}/dc=example,dc=com?cn?sub?(cn=Alice)", .{port}, 0);
    defer gpa.free(url_z);

    var cap = loopback_http.BodySink{};
    try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_NOSIGNAL, @as(c_long, 1)));
    try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_TIMEOUT_MS, @as(c_long, 5000)));
    try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_USE_SSL, c.CURLUSESSL_ALL));
    try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_CAINFO, ca_path_z.ptr));
    try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_USERPWD, "cn=admin,dc=example,dc=com:secret"));
    try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_WRITEFUNCTION, &loopback_http.writeCallback));
    try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_WRITEDATA, &cap));
    try testing.expectEqual(c.CURLE_OK, curl_easy_setopt(easy, c.CURLOPT_URL, url_z.ptr));

    try testing.expectEqual(c.CURLE_OK, curl_easy_perform(easy));
    try testing.expect(std.mem.indexOf(u8, cap.slice(), "DN: cn=Alice,dc=example,dc=com\n") != null);
}
