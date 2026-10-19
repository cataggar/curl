const std = @import("std");

pub const SslBackend = enum {
    none,
    openssl,
    mbedtls,
    schannel,
};

pub const Options = struct {
    ssl: SslBackend = .none,
    apple_sectrust: ?bool = null,
    zstd: bool = false,
    zlib: bool = false,
    nghttp2: bool = false,
    ca_bundle: ?[]const u8 = null,
    ca_fallback: bool = false,

    pub fn useAppleSectrust(self: Options, os_tag: std.Target.Os.Tag) bool {
        return self.apple_sectrust orelse (self.ssl == .openssl and os_tag.isDarwin());
    }

    pub fn isValidForTarget(self: Options, os_tag: std.Target.Os.Tag) bool {
        if (self.ssl == .schannel and os_tag != .windows) return false;
        if (self.apple_sectrust == true and (self.ssl != .openssl or !os_tag.isDarwin())) return false;
        return true;
    }

    pub fn validateForTarget(self: Options, os_tag: std.Target.Os.Tag) void {
        if (self.ssl == .schannel and os_tag != .windows) {
            @panic("Schannel SSL backend (-Dssl=schannel) is only supported on Windows targets");
        }
        if (self.apple_sectrust == true and (self.ssl != .openssl or !os_tag.isDarwin())) {
            @panic("Apple SecTrust (-Dapple-sectrust=true) requires -Dssl=openssl on a Darwin target");
        }
    }
};

pub fn fromBuild(b: *std.Build) Options {
    return .{
        .ssl = b.option(SslBackend, "ssl", "TLS/SSL backend (default: none)") orelse .none,
        .apple_sectrust = b.option(bool, "apple-sectrust", "Enable Apple SecTrust native certificate verification with OpenSSL on Darwin"),
        .zstd = b.option(bool, "zstd", "Enable zstd compression via system libzstd (default: false)") orelse false,
        .zlib = b.option(bool, "zlib", "Enable zlib compression via system libz (default: false)") orelse false,
        .nghttp2 = b.option(bool, "nghttp2", "Enable HTTP/2 via system libnghttp2 (default: false)") orelse false,
        .ca_bundle = b.option([]const u8, "ca-bundle", "Custom CA certificate bundle path"),
        .ca_fallback = b.option(bool, "ca-fallback", "Use TLS backend built-in CA store fallback (default: false)") orelse false,
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
        },
        .schannel => {
            mod.addCMacro("USE_SCHANNEL", "1");
            mod.addCMacro("USE_WINDOWS_SSPI", "1");
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
    if (opts.nghttp2) {
        mod.addCMacro("USE_NGHTTP2", "1");
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
    }

    if (opts.zstd) {
        mod.linkSystemLibrary("zstd", .{});
    }
    if (opts.zlib) {
        mod.linkSystemLibrary("z", .{});
    }
    if (opts.nghttp2) {
        mod.linkSystemLibrary("nghttp2", .{});
    }
}

pub fn createOptionsStep(b: *std.Build, opts: Options) *std.Build.Step.Options {
    const step = b.addOptions();
    step.addOption(SslBackend, "ssl", opts.ssl);
    step.addOption(?bool, "apple_sectrust", opts.apple_sectrust);
    step.addOption(bool, "zstd", opts.zstd);
    step.addOption(bool, "zlib", opts.zlib);
    step.addOption(bool, "nghttp2", opts.nghttp2);
    step.addOption(?[]const u8, "ca_bundle", opts.ca_bundle);
    step.addOption(bool, "ca_fallback", opts.ca_fallback);
    return step;
}
