const std = @import("std");

pub const SslBackend = enum {
    none,
    openssl,
    mbedtls,
    schannel,
    gnutls,
    rustls,
    wolfssl,
};

pub const IdnBackend = enum {
    none,
    libidn2,
    winidn,
    appleidn,
};

pub const QuicBackend = enum {
    none,
    ngtcp2,
    quiche,
};

pub const SshBackend = enum {
    none,
    libssh2,
    libssh,
};

pub const LdapBackend = enum {
    none,
    openldap,
    ldap,
    winldap,
};

pub const Options = struct {
    ssl: SslBackend = .none,
    apple_sectrust: ?bool = null,
    zstd: bool = false,
    zlib: bool = false,
    brotli: bool = false,
    psl: bool = false,
    idn: IdnBackend = .none,
    nghttp2: bool = false,
    ares: bool = false,
    httpsrr: bool = false,
    threaded_resolver: ?bool = null,
    ca_bundle: ?[]const u8 = null,
    ca_fallback: bool = false,
    quic: QuicBackend = .none,
    quiche_include_dir: ?[]const u8 = null,
    quiche_lib_dir: ?[]const u8 = null,
    ssh: SshBackend = .none,
    ldap: LdapBackend = .none,
    gssapi: bool = false,
    sspi: ?bool = null,

    pub fn useThreadedResolver(self: Options) bool {
        return self.threaded_resolver orelse !self.ares;
    }

    pub fn useResolvAres(self: Options) bool {
        return self.ares and !self.useThreadedResolver();
    }

    pub fn useAppleSectrust(self: Options, os_tag: std.Target.Os.Tag) bool {
        return self.apple_sectrust orelse (self.ssl == .openssl and os_tag.isDarwin());
    }

    pub fn useSspi(self: Options, os_tag: std.Target.Os.Tag) bool {
        return os_tag == .windows and (self.sspi orelse (self.ssl == .schannel));
    }

    pub fn hasHttp3(self: Options) bool {
        return self.quic != .none;
    }

    pub fn hasProxyHttp3(self: Options) bool {
        return self.quic == .ngtcp2 and self.ssl == .openssl;
    }

    pub fn hasLdap(self: Options) bool {
        return self.ldap != .none;
    }

    pub fn hasLdaps(self: Options) bool {
        return switch (self.ldap) {
            .none => false,
            .openldap => self.ssl != .none,
            .ldap, .winldap => true,
        };
    }

    pub fn isValidForTarget(self: Options, os_tag: std.Target.Os.Tag) bool {
        if (self.ssl == .schannel and os_tag != .windows) return false;
        if (self.apple_sectrust == true and (self.ssl != .openssl or !os_tag.isDarwin())) return false;
        if (self.idn == .winidn and os_tag != .windows) return false;
        if (self.idn == .appleidn and !os_tag.isDarwin()) return false;
        if (self.quic == .ngtcp2 and self.ssl != .openssl and self.ssl != .gnutls and self.ssl != .wolfssl) return false;
        if (self.ldap == .winldap and os_tag != .windows) return false;
        if (self.ldap == .openldap and os_tag == .windows) return false;
        if (self.sspi == true and os_tag != .windows) return false;
        if (self.gssapi and os_tag == .windows) return false;
        return true;
    }

    pub fn validateForTarget(self: Options, os_tag: std.Target.Os.Tag) void {
        if (self.ssl == .schannel and os_tag != .windows) {
            @panic("Schannel SSL backend (-Dssl=schannel) is only supported on Windows targets");
        }
        if (self.apple_sectrust == true and (self.ssl != .openssl or !os_tag.isDarwin())) {
            @panic("Apple SecTrust (-Dapple-sectrust=true) requires -Dssl=openssl on a Darwin target");
        }
        if (self.idn == .winidn and os_tag != .windows) {
            @panic("WinIDN backend (-Didn=winidn) is only supported on Windows targets");
        }
        if (self.idn == .appleidn and !os_tag.isDarwin()) {
            @panic("AppleIDN backend (-Didn=appleidn) is only supported on Darwin targets");
        }
        if (self.quic == .ngtcp2 and self.ssl != .openssl and self.ssl != .gnutls and self.ssl != .wolfssl) {
            @panic("ngtcp2 requires -Dssl=openssl, -Dssl=gnutls, or -Dssl=wolfssl");
        }
        if (self.ldap == .winldap and os_tag != .windows) {
            @panic("WinLDAP backend (-Dldap=winldap) is only supported on Windows targets");
        }
        if (self.ldap == .openldap and os_tag == .windows) {
            @panic("OpenLDAP backend (-Dldap=openldap) is not supported on Windows targets; use -Dldap=winldap");
        }
        if (self.sspi == true and os_tag != .windows) {
            @panic("Windows SSPI (-Dsspi=true) is only supported on Windows targets");
        }
        if (self.gssapi and os_tag == .windows) {
            @panic("GSS-API (-Dgssapi=true) is not supported on Windows targets; use -Dsspi=true");
        }
    }

    pub fn addOptionsModule(self: Options, b: *std.Build) *std.Build.Module {
        return createOptionsStep(b, self).createModule();
    }
};

pub fn fromBuild(b: *std.Build) Options {
    return .{
        .ssl = b.option(SslBackend, "ssl", "TLS/SSL backend (default: none)") orelse .none,
        .apple_sectrust = b.option(bool, "apple-sectrust", "Enable Apple SecTrust native certificate verification with OpenSSL on Darwin"),
        .zstd = b.option(bool, "zstd", "Enable zstd compression via system libzstd (default: false)") orelse false,
        .zlib = b.option(bool, "zlib", "Enable zlib compression via system libz (default: false)") orelse false,
        .brotli = b.option(bool, "brotli", "Enable brotli compression via system libbrotlidec (default: false)") orelse false,
        .psl = b.option(bool, "psl", "Enable Public Suffix List support via system libpsl (default: false)") orelse false,
        .idn = b.option(IdnBackend, "idn", "IDN backend (default: none)") orelse .none,
        .nghttp2 = b.option(bool, "nghttp2", "Enable HTTP/2 via system libnghttp2 (default: false)") orelse false,
        .ares = b.option(bool, "ares", "Enable c-ares DNS resolver / HTTPS-RR support (default: false)") orelse false,
        .httpsrr = b.option(bool, "httpsrr", "Enable HTTPS DNS resource record (HTTPS-RR) support (default: false)") orelse false,
        .threaded_resolver = b.option(bool, "threaded-resolver", "Use threaded DNS resolver (default: !ares; set true with -Dares=true for hybrid threaded+c-ares HTTPS-RR)"),
        .ca_bundle = b.option([]const u8, "ca-bundle", "Custom CA certificate bundle path"),
        .ca_fallback = b.option(bool, "ca-fallback", "Use TLS backend built-in CA store fallback (default: false)") orelse false,
        .quic = b.option(QuicBackend, "quic", "QUIC/HTTP3 backend (none, ngtcp2, quiche; default: none)") orelse .none,
        .quiche_include_dir = b.option([]const u8, "quiche-include", "Custom include directory for quiche"),
        .quiche_lib_dir = b.option([]const u8, "quiche-lib", "Custom library directory for quiche"),
        .ssh = b.option(SshBackend, "ssh", "SSH/SFTP/SCP backend (none, libssh2, libssh; default: none)") orelse .none,
        .ldap = b.option(LdapBackend, "ldap", "LDAP/LDAPS backend (none, openldap, ldap, winldap; default: none)") orelse .none,
        .gssapi = b.option(bool, "gssapi", "Enable GSS-API / Kerberos5 / SPNEGO via system libgssapi_krb5 or Apple GSS (default: false)") orelse false,
        .sspi = b.option(bool, "sspi", "Enable Windows SSPI authentication (default: true with -Dssl=schannel on Windows)"),
    };
}

pub fn applyCMacros(mod: *std.Build.Module, target: std.Build.ResolvedTarget, opts: Options) void {
    const b = mod.owner;
    opts.validateForTarget(target.result.os.tag);

    switch (opts.ssl) {
        .none => {
            mod.addCMacro("CURL_DISABLE_HSTS", "1");
        },
        .openssl => {
            mod.addCMacro("USE_OPENSSL", "1");
            mod.addCMacro("HAVE_SSL_SET0_WBIO", "1");
            if (opts.useAppleSectrust(target.result.os.tag)) {
                mod.addCMacro("USE_APPLE_SECTRUST", "1");
            }
            if (opts.ca_bundle == null and !opts.ca_fallback and target.result.os.tag == .linux) {
                mod.addCMacro("CURL_CA_BUNDLE", "\"/etc/ssl/certs/ca-certificates.crt\"");
            }
        },
        .mbedtls => {
            mod.addCMacro("USE_MBEDTLS", "1");
            if (opts.ca_bundle == null and !opts.ca_fallback and target.result.os.tag == .linux) {
                mod.addCMacro("CURL_CA_BUNDLE", "\"/etc/ssl/certs/ca-certificates.crt\"");
            }
        },
        .schannel => {
            mod.addCMacro("USE_SCHANNEL", "1");
            mod.addCMacro("USE_WINDOWS_SSPI", "1");
        },
        .gnutls => {
            mod.addCMacro("USE_GNUTLS", "1");
            if (opts.ca_bundle == null and !opts.ca_fallback and target.result.os.tag == .linux) {
                mod.addCMacro("CURL_CA_BUNDLE", "\"/etc/ssl/certs/ca-certificates.crt\"");
            }
        },
        .rustls => {
            mod.addCMacro("USE_RUSTLS", "1");
            if (opts.ca_bundle == null and !opts.ca_fallback and target.result.os.tag == .linux) {
                mod.addCMacro("CURL_CA_BUNDLE", "\"/etc/ssl/certs/ca-certificates.crt\"");
            }
        },
        .wolfssl => {
            mod.addCMacro("USE_WOLFSSL", "1");
            if (opts.ca_bundle == null and !opts.ca_fallback and target.result.os.tag == .linux) {
                mod.addCMacro("CURL_CA_BUNDLE", "\"/etc/ssl/certs/ca-certificates.crt\"");
            }
        },
    }

    if (opts.ca_bundle) |bundle| {
        mod.addCMacro("CURL_CA_BUNDLE", b.fmt("\"{s}\"", .{bundle}));
    }
    if (opts.ca_fallback) {
        mod.addCMacro("CURL_CA_FALLBACK", "1");
    }

    if (opts.zstd) {
        mod.addCMacro("HAVE_ZSTD", "1");
    }
    if (opts.zlib) {
        mod.addCMacro("HAVE_LIBZ", "1");
    }
    if (opts.brotli) {
        mod.addCMacro("HAVE_BROTLI", "1");
    }
    if (opts.psl) {
        mod.addCMacro("USE_LIBPSL", "1");
    }
    switch (opts.idn) {
        .none => {},
        .libidn2 => mod.addCMacro("USE_LIBIDN2", "1"),
        .winidn => mod.addCMacro("USE_WIN32_IDN", "1"),
        .appleidn => mod.addCMacro("USE_APPLE_IDN", "1"),
    }
    if (opts.nghttp2) {
        mod.addCMacro("USE_NGHTTP2", "1");
    }

    if (opts.useThreadedResolver()) {
        mod.addCMacro("USE_RESOLV_THREADED", "1");
    }

    if (opts.useResolvAres()) {
        mod.addCMacro("USE_RESOLV_ARES", "1");
    }

    if (opts.ares) {
        mod.addCMacro("USE_ARES", "1");
    }

    if (opts.httpsrr) {
        mod.addCMacro("USE_HTTPSRR", "1");
    }

    switch (opts.quic) {
        .none => {},
        .ngtcp2 => {
            if (opts.ssl != .openssl and opts.ssl != .gnutls and opts.ssl != .wolfssl) {
                @panic("ngtcp2 requires -Dssl=openssl, -Dssl=gnutls, or -Dssl=wolfssl");
            }
            mod.addCMacro("USE_NGTCP2", "1");
            mod.addCMacro("USE_NGHTTP3", "1");
            if (opts.hasProxyHttp3()) {
                mod.addCMacro("USE_PROXY_HTTP3", "1");
            }
            mod.addCMacro("NGTCP2_STATICLIB", "1");
            mod.addCMacro("NGHTTP3_STATICLIB", "1");
            if (opts.ssl == .openssl) {
                mod.addCMacro("OPENSSL_QUIC_API2", "1");
            }
        },
        .quiche => {
            mod.addCMacro("USE_QUICHE", "1");
            mod.addCMacro("HAVE_QUICHE_CONN_SET_QLOG_FD", "1");
        },
    }

    switch (opts.ssh) {
        .none => {},
        .libssh2 => mod.addCMacro("USE_LIBSSH2", "1"),
        .libssh => mod.addCMacro("USE_LIBSSH", "1"),
    }

    switch (opts.ldap) {
        .none => {
            mod.addCMacro("CURL_DISABLE_LDAP", "1");
            mod.addCMacro("CURL_DISABLE_LDAPS", "1");
        },
        .openldap => {
            mod.addCMacro("USE_OPENLDAP", "1");
            if (!opts.hasLdaps()) {
                mod.addCMacro("CURL_DISABLE_LDAPS", "1");
            }
        },
        .ldap, .winldap => {
            mod.addCMacro("HAVE_LDAP_SSL", "1");
            if (target.result.os.tag == .windows or opts.ldap == .winldap) {
                mod.addCMacro("USE_WIN32_LDAP", "1");
            } else {
                mod.addCMacro("HAVE_LBER_H", "1");
                mod.addCMacro("HAVE_LDAP_URL_PARSE", "1");
            }
        },
    }

    if (opts.useSspi(target.result.os.tag) and opts.ssl != .schannel) {
        mod.addCMacro("USE_WINDOWS_SSPI", "1");
    }

    if (opts.gssapi) {
        mod.addCMacro("HAVE_GSSAPI", "1");
        if (target.result.os.tag.isDarwin()) {
            mod.addCMacro("HAVE_GSSAPPLE", "1");
        } else {
            mod.addCMacro("HAVE_GSS_SET_NEG_MECHS", "1");
        }
    }
}

pub fn linkBackends(mod: *std.Build.Module, target: std.Build.ResolvedTarget, opts: Options) void {
    opts.validateForTarget(target.result.os.tag);

    switch (opts.ssl) {
        .none => {},
        .openssl => {
            mod.linkSystemLibrary("ssl", .{});
            mod.linkSystemLibrary("crypto", .{});
            if (opts.useAppleSectrust(target.result.os.tag)) {
                mod.linkFramework("Security", .{});
                mod.linkFramework("CoreFoundation", .{});
            }
        },
        .mbedtls => {
            mod.linkSystemLibrary("mbedtls", .{});
            mod.linkSystemLibrary("mbedx509", .{});
            mod.linkSystemLibrary("mbedcrypto", .{});
        },
        .schannel => {
            mod.linkSystemLibrary("secur32", .{});
            mod.linkSystemLibrary("crypt32", .{});
            mod.linkSystemLibrary("advapi32", .{});
            mod.linkSystemLibrary("bcrypt", .{});
        },
        .gnutls => {
            mod.linkSystemLibrary("gnutls", .{});
            mod.linkSystemLibrary("nettle", .{});
        },
        .rustls => {
            mod.linkSystemLibrary("rustls", .{});
            if (target.result.os.tag == .linux) {
                mod.linkSystemLibrary("gcc_s", .{});
            }
        },
        .wolfssl => {
            mod.linkSystemLibrary("wolfssl", .{});
        },
    }

    if (opts.zstd) {
        mod.linkSystemLibrary("zstd", .{});
    }
    if (opts.zlib) {
        mod.linkSystemLibrary("z", .{});
    }
    if (opts.brotli) {
        mod.linkSystemLibrary("brotlidec", .{});
    }
    if (opts.psl) {
        mod.linkSystemLibrary("psl", .{});
    }
    switch (opts.idn) {
        .none => {},
        .libidn2 => mod.linkSystemLibrary("idn2", .{}),
        .winidn => mod.linkSystemLibrary("normaliz", .{}),
        .appleidn => {
            mod.linkSystemLibrary("icucore", .{});
            mod.linkSystemLibrary("iconv", .{});
        },
    }
    if (opts.nghttp2) {
        mod.linkSystemLibrary("nghttp2", .{});
    }

    if (opts.ares) {
        mod.linkSystemLibrary("cares", .{});
    }

    switch (opts.quic) {
        .none => {},
        .ngtcp2 => {
            mod.linkSystemLibrary("ngtcp2", .{});
            mod.linkSystemLibrary("nghttp3", .{});
            switch (opts.ssl) {
                .openssl => mod.linkSystemLibrary("ngtcp2_crypto_ossl", .{}),
                .gnutls => mod.linkSystemLibrary("ngtcp2_crypto_gnutls", .{}),
                .wolfssl => mod.linkSystemLibrary("ngtcp2_crypto_wolfssl", .{}),
                else => unreachable,
            }
        },
        .quiche => {
            if (opts.quiche_include_dir) |inc_dir| {
                mod.addIncludePath(.{ .cwd_relative = inc_dir });
            }
            if (opts.quiche_lib_dir) |lib_dir| {
                mod.addLibraryPath(.{ .cwd_relative = lib_dir });
            }
            mod.linkSystemLibrary("quiche", .{});
        },
    }

    switch (opts.ssh) {
        .none => {},
        .libssh2 => mod.linkSystemLibrary("ssh2", .{}),
        .libssh => mod.linkSystemLibrary("ssh", .{}),
    }

    switch (opts.ldap) {
        .none => {},
        .openldap, .ldap => {
            if (target.result.os.tag == .windows) {
                mod.linkSystemLibrary("wldap32", .{});
            } else {
                mod.linkSystemLibrary("ldap", .{});
                mod.linkSystemLibrary("lber", .{});
            }
        },
        .winldap => mod.linkSystemLibrary("wldap32", .{}),
    }

    if (opts.useSspi(target.result.os.tag) and opts.ssl != .schannel) {
        mod.linkSystemLibrary("secur32", .{});
        mod.linkSystemLibrary("crypt32", .{});
        mod.linkSystemLibrary("advapi32", .{});
    }

    if (opts.gssapi) {
        if (target.result.os.tag.isDarwin()) {
            mod.linkFramework("GSS", .{});
        } else {
            mod.linkSystemLibrary("gssapi_krb5", .{});
            mod.linkSystemLibrary("krb5", .{});
        }
    }
}

pub fn createOptionsStep(b: *std.Build, opts: Options) *std.Build.Step.Options {
    const step = b.addOptions();
    step.addOption(SslBackend, "ssl", opts.ssl);
    step.addOption(?bool, "apple_sectrust", opts.apple_sectrust);
    step.addOption(bool, "zstd", opts.zstd);
    step.addOption(bool, "zlib", opts.zlib);
    step.addOption(bool, "brotli", opts.brotli);
    step.addOption(bool, "psl", opts.psl);
    step.addOption(IdnBackend, "idn", opts.idn);
    step.addOption(bool, "nghttp2", opts.nghttp2);
    step.addOption(bool, "ares", opts.ares);
    step.addOption(bool, "httpsrr", opts.httpsrr);
    step.addOption(bool, "use_resolv_ares", opts.useResolvAres());
    step.addOption(bool, "use_resolv_threaded", opts.useThreadedResolver());
    step.addOption(?[]const u8, "ca_bundle", opts.ca_bundle);
    step.addOption(bool, "ca_fallback", opts.ca_fallback);
    step.addOption(QuicBackend, "quic", opts.quic);
    step.addOption(bool, "http3", opts.hasHttp3());
    step.addOption(bool, "proxy_http3", opts.hasProxyHttp3());
    step.addOption(SshBackend, "ssh", opts.ssh);
    step.addOption(LdapBackend, "ldap", opts.ldap);
    step.addOption(bool, "has_ldap", opts.hasLdap());
    step.addOption(bool, "has_ldaps", opts.hasLdaps());
    step.addOption(bool, "gssapi", opts.gssapi);
    step.addOption(?bool, "sspi", opts.sspi);
    return step;
}
