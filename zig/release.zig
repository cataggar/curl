//! `curl_release`: fail-closed packaging, archive inspection, SHA-256 manifest
//! generation, asset allowlist verification, and draft-first GitHub release
//! publication for the 6-platform curl Zig-port distribution (#63).

const std = @import("std");
const builtin = @import("builtin");

const Allocator = std.mem.Allocator;
const Dir = std.Io.Dir;
const File = std.Io.File;
const Io = std.Io;
const Sha256 = std.crypto.hash.sha2.Sha256;
const Value = std.json.Value;

pub const default_repository = "cataggar/curl";
pub const message_capacity = 512;
const block_bytes = 1024 * 1024;
const maximum_asset_bytes: u64 = 512 * 1024 * 1024;
const maximum_gh_output_bytes: usize = 16 * 1024 * 1024;

pub const Digest = [Sha256.digest_length]u8;
pub const Hex = [Sha256.digest_length * 2]u8;

pub const Error = error{
    Usage,
    Failed,
    OutOfMemory,
};

pub const Diagnostic = struct {
    buffer: [message_capacity]u8 = undefined,
    length: usize = 0,

    pub fn message(self: *const Diagnostic) []const u8 {
        return self.buffer[0..self.length];
    }

    pub fn set(self: *Diagnostic, comptime fmt: []const u8, args: anytype) void {
        const written = std.fmt.bufPrint(&self.buffer, fmt, args) catch blk: {
            break :blk self.buffer[0..];
        };
        self.length = written.len;
    }

    pub fn fail(
        self: *Diagnostic,
        err: anytype,
        comptime fmt: []const u8,
        args: anytype,
    ) @TypeOf(err) {
        self.set(fmt, args);
        return err;
    }
};

pub const default_release_optimize_mode: std.builtin.OptimizeMode = .ReleaseSafe;
pub const default_release_optimize_flag = "-Doptimize=ReleaseSafe";

pub const expected_release_protocols = [_][]const u8{
    "dict",
    "file",
    "ftp",
    "ftps",
    "gopher",
    "gophers",
    "http",
    "https",
    "imap",
    "imaps",
    "ldap",
    "ldaps",
    "mqtt",
    "mqtts",
    "pop3",
    "pop3s",
    "rtsp",
    "scp",
    "sftp",
    "smtp",
    "smtps",
    "telnet",
    "tftp",
    "ws",
    "wss",
};

pub const expected_common_release_features = [_][]const u8{
    "alt-svc",
    "asyn-rr",
    "AsynchDNS",
    "brotli",
    "HSTS",
    "HTTP2",
    "HTTP3",
    "HTTPS-proxy",
    "HTTPSIG",
    "HTTPSRR",
    "IDN",
    "IPv6",
    "Kerberos",
    "Largefile",
    "libz",
    "proxy-HTTP3",
    "PSL",
    "SPNEGO",
    "SSL",
    "threadsafe",
    "UnixSockets",
    "zstd",
};

pub const Platform = struct {
    suffix: []const u8,
    zig_target: []const u8,
    executable: []const u8,
    runtime_notes: []const u8,
    enabled_features: []const u8,
    optimize_mode: std.builtin.OptimizeMode = default_release_optimize_mode,

    pub fn zigBuildArgv(self: Platform, allocator: Allocator) Allocator.Error![][]const u8 {
        const target_arg = try std.fmt.allocPrint(allocator, "-Dtarget={s}", .{self.zig_target});
        errdefer allocator.free(target_arg);

        const optimize_str = switch (self.optimize_mode) {
            .Debug => "-Doptimize=Debug",
            .ReleaseSafe => "-Doptimize=ReleaseSafe",
            .ReleaseFast => "-Doptimize=ReleaseFast",
            .ReleaseSmall => "-Doptimize=ReleaseSmall",
        };
        const optimize_arg = try allocator.dupe(u8, optimize_str);
        errdefer allocator.free(optimize_arg);

        const is_windows = std.mem.startsWith(u8, self.suffix, "windows-");
        const is_macos = std.mem.startsWith(u8, self.suffix, "macos-");

        const backend_flags: []const []const u8 = if (is_windows)
            &.{
                "-Dssl=schannel",
                "-Dapple-sectrust=false",
                "-Dzstd=true",
                "-Dzlib=true",
                "-Dbrotli=true",
                "-Dpsl=true",
                "-Didn=winidn",
                "-Dnghttp2=true",
                "-Dares=true",
                "-Dhttpsrr=true",
                "-Dquic=ngtcp2",
                "-Dssh=libssh2",
                "-Dldap=winldap",
                "-Dgssapi=false",
                "-Dsspi=true",
            }
        else if (is_macos)
            &.{
                "-Dssl=openssl",
                "-Dapple-sectrust=true",
                "-Dzstd=true",
                "-Dzlib=true",
                "-Dbrotli=true",
                "-Dpsl=true",
                "-Didn=libidn2",
                "-Dnghttp2=true",
                "-Dares=true",
                "-Dhttpsrr=true",
                "-Dquic=ngtcp2",
                "-Dssh=libssh2",
                "-Dldap=openldap",
                "-Dgssapi=true",
                "-Dsspi=false",
            }
        else
            &.{
                "-Dssl=openssl",
                "-Dapple-sectrust=false",
                "-Dzstd=true",
                "-Dzlib=true",
                "-Dbrotli=true",
                "-Dpsl=true",
                "-Didn=libidn2",
                "-Dnghttp2=true",
                "-Dares=true",
                "-Dhttpsrr=true",
                "-Dquic=ngtcp2",
                "-Dssh=libssh2",
                "-Dldap=openldap",
                "-Dgssapi=true",
                "-Dsspi=false",
            };

        const count: usize = 5 + backend_flags.len;
        var argv = try allocator.alloc([]const u8, count);
        var initialized: usize = 0;
        errdefer {
            for (argv[0..initialized]) |arg| allocator.free(arg);
            allocator.free(argv);
        }

        argv[0] = try allocator.dupe(u8, "zig");
        initialized = 1;
        argv[1] = try allocator.dupe(u8, "build");
        initialized = 2;
        argv[2] = target_arg;
        initialized = 3;
        argv[3] = optimize_arg;
        initialized = 4;
        argv[4] = try allocator.dupe(u8, "-Dbundled=true");
        initialized = 5;

        for (backend_flags) |flag| {
            argv[initialized] = try allocator.dupe(u8, flag);
            initialized += 1;
        }
        return argv;
    }

    pub fn freeZigBuildArgv(allocator: Allocator, argv: [][]const u8) void {
        for (argv) |arg| allocator.free(arg);
        allocator.free(argv);
    }
};

pub fn runCapture(
    allocator: Allocator,
    io: Io,
    argv: []const []const u8,
) !std.process.RunResult {
    return std.process.run(allocator, io, .{
        .argv = argv,
        .stdout_limit = .limited(maximum_gh_output_bytes),
        .stderr_limit = .limited(maximum_gh_output_bytes),
    });
}

pub const platforms = [_]Platform{
    .{
        .suffix = "linux-musl-x64",
        .zig_target = "x86_64-linux-musl",
        .executable = "curl",
        .runtime_notes = "Static musl executable; no external shared library dependencies.",
        .enabled_features = "Protocols: DICT, FILE, FTP, FTPS, GOPHER, GOPHERS, HTTP, HTTPS, IMAP, IMAPS, LDAP, LDAPS, MQTT, MQTTS, POP3, POP3S, RTSP, SCP, SFTP, SMTP, SMTPS, TELNET, TFTP, WS, WSS. Features: SSL, HSTS, HTTP2, HTTP3, HTTPS-proxy, HTTPSIG, HTTPSRR, AsynchDNS, asyn-rr, IDN, IPv6, Kerberos, Largefile, libz, brotli, zstd, PSL, SPNEGO, GSS-API, alt-svc, proxy-HTTP3, threadsafe, UnixSockets",
    },
    .{
        .suffix = "linux-musl-arm64",
        .zig_target = "aarch64-linux-musl",
        .executable = "curl",
        .runtime_notes = "Static musl executable; no external shared library dependencies.",
        .enabled_features = "Protocols: DICT, FILE, FTP, FTPS, GOPHER, GOPHERS, HTTP, HTTPS, IMAP, IMAPS, LDAP, LDAPS, MQTT, MQTTS, POP3, POP3S, RTSP, SCP, SFTP, SMTP, SMTPS, TELNET, TFTP, WS, WSS. Features: SSL, HSTS, HTTP2, HTTP3, HTTPS-proxy, HTTPSIG, HTTPSRR, AsynchDNS, asyn-rr, IDN, IPv6, Kerberos, Largefile, libz, brotli, zstd, PSL, SPNEGO, GSS-API, alt-svc, proxy-HTTP3, threadsafe, UnixSockets",
    },
    .{
        .suffix = "macos-x64",
        .zig_target = "x86_64-macos",
        .executable = "curl",
        .runtime_notes = "Links macOS system `libSystem.B.dylib` and Apple `Security`/`CoreFoundation` frameworks only; no Homebrew or third-party dylibs required.",
        .enabled_features = "Protocols: DICT, FILE, FTP, FTPS, GOPHER, GOPHERS, HTTP, HTTPS, IMAP, IMAPS, LDAP, LDAPS, MQTT, MQTTS, POP3, POP3S, RTSP, SCP, SFTP, SMTP, SMTPS, TELNET, TFTP, WS, WSS. Features: SSL, AppleSecTrust, HSTS, HTTP2, HTTP3, HTTPS-proxy, HTTPSIG, HTTPSRR, AsynchDNS, asyn-rr, IDN, IPv6, Kerberos, Largefile, libz, brotli, zstd, PSL, SPNEGO, GSS-API, alt-svc, proxy-HTTP3, threadsafe, UnixSockets",
    },
    .{
        .suffix = "macos-arm64",
        .zig_target = "aarch64-macos",
        .executable = "curl",
        .runtime_notes = "Links macOS system `libSystem.B.dylib` and Apple `Security`/`CoreFoundation` frameworks only; no Homebrew or third-party dylibs required.",
        .enabled_features = "Protocols: DICT, FILE, FTP, FTPS, GOPHER, GOPHERS, HTTP, HTTPS, IMAP, IMAPS, LDAP, LDAPS, MQTT, MQTTS, POP3, POP3S, RTSP, SCP, SFTP, SMTP, SMTPS, TELNET, TFTP, WS, WSS. Features: SSL, AppleSecTrust, HSTS, HTTP2, HTTP3, HTTPS-proxy, HTTPSIG, HTTPSRR, AsynchDNS, asyn-rr, IDN, IPv6, Kerberos, Largefile, libz, brotli, zstd, PSL, SPNEGO, GSS-API, alt-svc, proxy-HTTP3, threadsafe, UnixSockets",
    },
    .{
        .suffix = "windows-x64",
        .zig_target = "x86_64-windows-gnu",
        .executable = "curl.exe",
        .runtime_notes = "Links standard Windows OS DLLs only (`ws2_32.dll`, `secur32.dll`, `crypt32.dll`, `advapi32.dll`, `bcrypt.dll`, `normaliz.dll`, `wldap32.dll`).",
        .enabled_features = "Protocols: DICT, FILE, FTP, FTPS, GOPHER, GOPHERS, HTTP, HTTPS, IMAP, IMAPS, LDAP, LDAPS, MQTT, MQTTS, POP3, POP3S, RTSP, SCP, SFTP, SMTP, SMTPS, TELNET, TFTP, WS, WSS. Features: SSL, SSPI, Unicode, HSTS, HTTP2, HTTP3, HTTPS-proxy, HTTPSIG, HTTPSRR, AsynchDNS, asyn-rr, IDN, IPv6, Kerberos, Largefile, libz, brotli, zstd, PSL, SPNEGO, alt-svc, proxy-HTTP3, threadsafe, UnixSockets",
    },
    .{
        .suffix = "windows-arm64",
        .zig_target = "aarch64-windows-gnu",
        .executable = "curl.exe",
        .runtime_notes = "Links standard Windows OS DLLs only (`ws2_32.dll`, `secur32.dll`, `crypt32.dll`, `advapi32.dll`, `bcrypt.dll`, `normaliz.dll`, `wldap32.dll`).",
        .enabled_features = "Protocols: DICT, FILE, FTP, FTPS, GOPHER, GOPHERS, HTTP, HTTPS, IMAP, IMAPS, LDAP, LDAPS, MQTT, MQTTS, POP3, POP3S, RTSP, SCP, SFTP, SMTP, SMTPS, TELNET, TFTP, WS, WSS. Features: SSL, SSPI, Unicode, HSTS, HTTP2, HTTP3, HTTPS-proxy, HTTPSIG, HTTPSRR, AsynchDNS, asyn-rr, IDN, IPv6, Kerberos, Largefile, libz, brotli, zstd, PSL, SPNEGO, alt-svc, proxy-HTTP3, threadsafe, UnixSockets",
    },
};

pub fn findPlatform(suffix: []const u8) ?Platform {
    for (platforms) |p| {
        if (std.mem.eql(u8, p.suffix, suffix)) return p;
    }
    return null;
}

const usage =
    \\usage:
    \\  curl_release verify-version --tag TAG [--manifest PATH] [--github-output PATH]
    \\  curl_release package --version VERSION --platform PLATFORM --executable PATH
    \\      --copying PATH --output-dir PATH
    \\  curl_release inspect-archive --archive PATH --version VERSION --platform PLATFORM
    \\  curl_release generate-checksums --assets-directory PATH --version VERSION
    \\      [--output PATH]
    \\  curl_release verify-assets --assets-directory PATH --version VERSION
    \\  curl_release render-notes --repository OWNER/REPO --tag TAG --version VERSION
    \\      [--previous-tag TAG] [--output PATH]
    \\  curl_release publish --repository OWNER/REPO --tag TAG --version VERSION
    \\      --commit SHA --assets-directory PATH --workspace PATH
    \\      [--github-step-summary PATH]
    \\
;

const Options = struct {
    names: [16][]const u8 = undefined,
    values: [16][]const u8 = undefined,
    len: usize = 0,

    fn parse(argv: []const []const u8) !Options {
        var options: Options = .{};
        if (argv.len % 2 != 0) return error.Usage;
        var index: usize = 0;
        while (index < argv.len) : (index += 2) {
            if (!std.mem.startsWith(u8, argv[index], "--") or
                argv[index].len == 2 or options.len == options.names.len)
            {
                return error.Usage;
            }
            for (options.names[0..options.len]) |name| {
                if (std.mem.eql(u8, name, argv[index])) return error.Usage;
            }
            options.names[options.len] = argv[index];
            options.values[options.len] = argv[index + 1];
            options.len += 1;
        }
        return options;
    }

    fn get(self: *const Options, name: []const u8) ?[]const u8 {
        for (self.names[0..self.len], self.values[0..self.len]) |actual, value| {
            if (std.mem.eql(u8, actual, name)) return value;
        }
        return null;
    }

    fn require(self: *const Options, name: []const u8) ![]const u8 {
        return self.get(name) orelse error.Usage;
    }

    fn only(self: *const Options, allowed: []const []const u8) !void {
        for (self.names[0..self.len]) |actual| {
            var found = false;
            for (allowed) |name| {
                if (std.mem.eql(u8, actual, name)) found = true;
            }
            if (!found) return error.Usage;
        }
    }
};

pub const Identity = struct {
    inode: File.INode,
    nlink: File.NLink,
    size: u64,
    mtime_nanoseconds: i96,
    ctime_nanoseconds: i96,

    pub fn of(stat: File.Stat) Identity {
        return .{
            .inode = stat.inode,
            .nlink = stat.nlink,
            .size = stat.size,
            .mtime_nanoseconds = stat.mtime.nanoseconds,
            .ctime_nanoseconds = stat.ctime.nanoseconds,
        };
    }

    pub fn eql(self: Identity, other: Identity) bool {
        return self.inode == other.inode and
            self.nlink == other.nlink and
            self.size == other.size and
            self.mtime_nanoseconds == other.mtime_nanoseconds and
            self.ctime_nanoseconds == other.ctime_nanoseconds;
    }
};

pub const FileDigest = struct {
    digest: Digest,
    hex: Hex,
    size: u64,
    identity: Identity,
};

pub fn hashBytes(bytes: []const u8) Digest {
    var digest: Digest = undefined;
    Sha256.hash(bytes, &digest, .{});
    return digest;
}

pub fn hex(digest: Digest) Hex {
    return std.fmt.bytesToHex(digest, .lower);
}

pub fn hexBytes(bytes: []const u8) Hex {
    return hex(hashBytes(bytes));
}

pub fn isLowerSha256(text: []const u8) bool {
    if (text.len != 64) return false;
    for (text) |character| switch (character) {
        '0'...'9', 'a'...'f' => {},
        else => return false,
    };
    return true;
}

pub fn validCommit(text: []const u8) bool {
    if (text.len != 40) return false;
    for (text) |character| switch (character) {
        '0'...'9', 'a'...'f' => {},
        else => return false,
    };
    return true;
}

pub fn hashRegularNoSymlink(io: Io, path: []const u8) !FileDigest {
    const file = try Dir.cwd().openFile(io, path, .{
        .mode = .read_only,
        .allow_directory = false,
        .follow_symlinks = false,
    });
    defer file.close(io);

    const before = try file.stat(io);
    if (before.kind != .file) return error.NotRegularFile;
    if (before.size > maximum_asset_bytes) return error.FileTooLarge;

    var hash = Sha256.init(.{});
    var buffer: [block_bytes]u8 = undefined;
    var offset: u64 = 0;
    while (offset < before.size) {
        const length: usize = @intCast(@min(before.size - offset, buffer.len));
        if (try file.readPositionalAll(io, buffer[0..length], offset) != length) {
            return error.ShortRead;
        }
        hash.update(buffer[0..length]);
        offset += length;
    }

    const after = try file.stat(io);
    const identity = Identity.of(before);
    if (!identity.eql(Identity.of(after))) return error.FileChangedDuringRead;

    var digest: Digest = undefined;
    hash.final(&digest);
    return .{
        .digest = digest,
        .hex = hex(digest),
        .size = before.size,
        .identity = identity,
    };
}

pub fn readBounded(
    allocator: Allocator,
    io: Io,
    path: []const u8,
    max_bytes: u64,
) ![]u8 {
    const file = try Dir.cwd().openFile(io, path, .{
        .mode = .read_only,
        .allow_directory = false,
        .follow_symlinks = true,
    });
    defer file.close(io);

    const before = try file.stat(io);
    if (before.kind != .file) return error.NotRegularFile;
    if (before.size > max_bytes) return error.FileTooLarge;

    const length = std.math.cast(usize, before.size) orelse return error.FileTooLarge;
    const bytes = try allocator.alloc(u8, length);
    errdefer allocator.free(bytes);
    if (try file.readPositionalAll(io, bytes, 0) != length) {
        return error.ShortRead;
    }

    const after = try file.stat(io);
    if (!Identity.of(before).eql(Identity.of(after))) return error.FileChangedDuringRead;
    return bytes;
}

pub fn writeAtomic(io: Io, path: []const u8, data: []const u8) !void {
    var stage = try Dir.cwd().createFileAtomic(io, path, .{
        .replace = true,
        .make_path = true,
    });
    defer stage.deinit(io);
    try stage.file.writeStreamingAll(io, data);
    try stage.replace(io);
}

/// Validates a fork prerelease SemVer string (e.g. `8.23.0-zig.1` or `8.23.0-rc.1`).
/// Rejects bare upstream versions without a prerelease suffix and rejects `-dev`/`-DEV`.
pub fn validateReleaseVersion(
    version: []const u8,
    diagnostic: *Diagnostic,
) Error!void {
    const sem = std.SemanticVersion.parse(version) catch return diagnostic.fail(
        error.Failed,
        "release version {s} is not valid SemVer",
        .{version},
    );
    if (sem.build != null) {
        return diagnostic.fail(
            error.Failed,
            "release version {s} must not include SemVer build metadata (+...)",
            .{version},
        );
    }
    const pre = sem.pre orelse return diagnostic.fail(
        error.Failed,
        "release version {s} must carry a fork prerelease identifier (e.g. {s}-zig.1), not a bare upstream version",
        .{ version, version },
    );
    if (std.ascii.eqlIgnoreCase(pre, "dev") or
        std.ascii.startsWithIgnoreCase(pre, "dev."))
    {
        return diagnostic.fail(
            error.Failed,
            "development version {s} must not be published as a release; choose a deliberate prerelease version",
            .{version},
        );
    }
}

pub fn versionFromTag(
    tag: []const u8,
    diagnostic: *Diagnostic,
) Error![]const u8 {
    if (tag.len < 2 or tag[0] != 'v') return diagnostic.fail(
        error.Failed,
        "release tag {s} is not a v-prefixed SemVer tag",
        .{tag},
    );
    const version = tag[1..];
    try validateReleaseVersion(version, diagnostic);
    return version;
}

pub fn validateVersionTag(
    version: []const u8,
    tag: []const u8,
    diagnostic: *Diagnostic,
) Error!void {
    const tag_version = try versionFromTag(tag, diagnostic);
    if (!std.mem.eql(u8, tag_version, version)) {
        return diagnostic.fail(
            error.Failed,
            "release tag {s} does not exactly match version {s}",
            .{ tag, version },
        );
    }
}

pub fn extractZonVersion(zon_text: []const u8) ?[]const u8 {
    const needle = ".version";
    var pos: usize = 0;
    while (std.mem.indexOfPos(u8, zon_text, pos, needle)) |idx| {
        pos = idx + needle.len;
        while (pos < zon_text.len and (zon_text[pos] == ' ' or zon_text[pos] == '\t')) : (pos += 1) {}
        if (pos >= zon_text.len or zon_text[pos] != '=') continue;
        pos += 1;
        while (pos < zon_text.len and (zon_text[pos] == ' ' or zon_text[pos] == '\t')) : (pos += 1) {}
        if (pos >= zon_text.len or zon_text[pos] != '"') continue;
        pos += 1;
        const end = std.mem.indexOfScalarPos(u8, zon_text, pos, '"') orelse return null;
        return zon_text[pos..end];
    }
    return null;
}

pub fn validateManifestVersionFile(
    allocator: Allocator,
    io: Io,
    manifest_path: []const u8,
    expected_version: []const u8,
    diagnostic: *Diagnostic,
) Error!void {
    const zon_bytes = readBounded(allocator, io, manifest_path, 256 * 1024) catch |err|
        return diagnostic.fail(
            error.Failed,
            "cannot read package manifest {s}: {t}",
            .{ manifest_path, err },
        );
    defer allocator.free(zon_bytes);

    const zon_ver = extractZonVersion(zon_bytes) orelse return diagnostic.fail(
        error.Failed,
        "package manifest {s} is missing .version",
        .{manifest_path},
    );
    if (!std.mem.eql(u8, zon_ver, expected_version)) {
        return diagnostic.fail(
            error.Failed,
            "package manifest {s} version {s} does not match release version {s}",
            .{ manifest_path, zon_ver, expected_version },
        );
    }
}

/// Validates that a tar archive entry path is a safe, normalized relative POSIX path.
/// Strictly rejects:
/// - Empty paths or paths starting with `/` or `\`
/// - Windows drive prefixes (e.g. `C:`) or backslashes
/// - Any path component equal to `..` or `.` (or empty `//` components)
/// - Embedded NUL bytes (`\0`) or ASCII control characters (`< 0x20` or `0x7f`)
pub fn isSafeArchiveEntryPath(entry_path: []const u8) bool {
    if (entry_path.len == 0) return false;
    if (entry_path[0] == '/' or entry_path[0] == '\\') return false;
    if (std.fs.path.isAbsolutePosix(entry_path) or std.fs.path.isAbsoluteWindows(entry_path)) {
        return false;
    }
    if (entry_path.len >= 2 and std.ascii.isAlphabetic(entry_path[0]) and entry_path[1] == ':') {
        return false;
    }

    for (entry_path) |ch| {
        if (ch == 0 or ch < 0x20 or ch == 0x7f) return false;
        if (ch == '\\' or ch == ':') return false;
    }

    const trimmed = if (entry_path[entry_path.len - 1] == '/')
        entry_path[0 .. entry_path.len - 1]
    else
        entry_path;
    if (trimmed.len == 0) return false;
    if (trimmed[trimmed.len - 1] == '/') return false;

    var iter = std.mem.splitScalar(u8, trimmed, '/');
    while (iter.next()) |component| {
        if (component.len == 0) return false;
        if (std.mem.eql(u8, component, ".") or std.mem.eql(u8, component, "..")) {
            return false;
        }
    }

    return true;
}

/// Checks whether a filename or archive entry path is an SBOM or SPDX file.
pub fn isSbOmOrSpdxPath(path: []const u8) bool {
    const base = std.fs.path.basename(path);
    return containsAsciiIgnoreCase(base, "sbom") or
        containsAsciiIgnoreCase(base, "spdx");
}

/// Checks whether an archive entry path looks like a libcurl development file
/// (headers, static/shared libraries, pkg-config, cmake configs) that is outside
/// the initial CLI-only release scope.
pub fn isLibcurlDevPath(rel_path: []const u8) bool {
    if (std.mem.startsWith(u8, rel_path, "include/") or
        std.mem.startsWith(u8, rel_path, "lib/") or
        std.mem.startsWith(u8, rel_path, "share/pkgconfig/"))
    {
        return true;
    }
    const base = std.fs.path.basename(rel_path);
    const dev_exts = [_][]const u8{
        ".h",
        ".a",
        ".so",
        ".dylib",
        ".dll",
        ".lib",
        ".pc",
        ".cmake",
    };
    for (dev_exts) |ext| {
        if (std.ascii.endsWithIgnoreCase(base, ext)) return true;
    }
    return false;
}

fn containsAsciiIgnoreCase(haystack: []const u8, needle: []const u8) bool {
    if (needle.len == 0) return true;
    if (haystack.len < needle.len) return false;
    var i: usize = 0;
    while (i + needle.len <= haystack.len) : (i += 1) {
        if (std.ascii.eqlIgnoreCase(haystack[i .. i + needle.len], needle)) return true;
    }
    return false;
}

pub fn renderPackageReadme(
    allocator: Allocator,
    version: []const u8,
    platform: Platform,
) ![]u8 {
    return std.fmt.allocPrint(
        allocator,
        \\# curl {s} ({s}) — Zig-Port Distribution
        \\
        \\This archive contains the `{s}` command-line binary built from the
        \\[{s}](https://github.com/{s}) Zig port of curl (`{s}`).
        \\
        \\> **Note:** This is a Zig-port prerelease distribution, **not** an official
        \\> upstream release from https://curl.se. It provides a focused subset of
        \\> platforms and features and does not promise full upstream feature parity.
        \\> `libcurl` C development headers and libraries are not included in this
        \\> binary package.
        \\
        \\## Layout
        \\
        \\- `{s}` — curl command-line executable
        \\- `COPYING` — curl license and copyright notice
        \\- `README.md` — this usage and capability summary
        \\
        \\## Installation
        \\
        \\With `ghr`:
        \\
        \\```console
        \\ghr install {s}@v{s}
        \\```
        \\
        \\Or extract directly and run from the current directory or add to your `PATH`:
        \\
        \\```console
        \\tar xzf curl-{s}-{s}.tar.gz
        \\./{s} --version
        \\```
        \\
        \\## Platform & Runtime Requirements
        \\
        \\- **Platform archive:** `{s}`
        \\- **Zig target:** `{s}`
        \\- **Runtime dependencies:** {s}
        \\- **Built-in capabilities:** {s}
        \\
        \\## Basic Usage
        \\
        \\```console
        \\{s} --version
        \\{s} -fsSL https://example.com -o index.html
        \\{s} -I https://example.com
        \\```
        \\
        \\## License & Dependency Notices
        \\
        \\curl is licensed under the curl license; see `COPYING` in this archive.
        \\{s}
        \\
    ,
        .{
            version,
            platform.suffix,
            platform.executable,
            default_repository,
            default_repository,
            platform.zig_target,
            platform.executable,
            default_repository,
            version,
            version,
            platform.suffix,
            platform.executable,
            platform.suffix,
            platform.zig_target,
            platform.runtime_notes,
            platform.enabled_features,
            platform.executable,
            platform.executable,
            platform.executable,
            platform.runtime_notes,
        },
    );
}

pub fn packageArchive(
    allocator: Allocator,
    io: Io,
    version: []const u8,
    platform_suffix: []const u8,
    executable_path: []const u8,
    copying_path: []const u8,
    output_dir: []const u8,
    diagnostic: *Diagnostic,
) Error!void {
    try validateReleaseVersion(version, diagnostic);
    const platform = findPlatform(platform_suffix) orelse return diagnostic.fail(
        error.Failed,
        "platform {s} is not in the 6-platform release allowlist",
        .{platform_suffix},
    );

    const exe_bytes = readBounded(allocator, io, executable_path, maximum_asset_bytes) catch |err|
        return diagnostic.fail(
            error.Failed,
            "cannot read executable {s}: {t}",
            .{ executable_path, err },
        );
    defer allocator.free(exe_bytes);
    if (exe_bytes.len == 0) {
        return diagnostic.fail(
            error.Failed,
            "executable {s} is empty",
            .{executable_path},
        );
    }

    const copying_bytes = readBounded(allocator, io, copying_path, 1024 * 1024) catch |err|
        return diagnostic.fail(
            error.Failed,
            "cannot read COPYING file {s}: {t}",
            .{ copying_path, err },
        );
    defer allocator.free(copying_bytes);
    if (copying_bytes.len == 0) {
        return diagnostic.fail(
            error.Failed,
            "COPYING file {s} is empty",
            .{copying_path},
        );
    }

    const readme_bytes = renderPackageReadme(allocator, version, platform) catch
        return error.OutOfMemory;
    defer allocator.free(readme_bytes);

    Dir.cwd().createDirPath(io, output_dir) catch |err| return diagnostic.fail(
        error.Failed,
        "cannot create output directory {s}: {t}",
        .{ output_dir, err },
    );

    const pkg_name = std.fmt.allocPrint(
        allocator,
        "curl-{s}-{s}",
        .{ version, platform.suffix },
    ) catch return error.OutOfMemory;
    defer allocator.free(pkg_name);

    const stage_root = std.fs.path.join(allocator, &.{ output_dir, pkg_name }) catch
        return error.OutOfMemory;
    defer allocator.free(stage_root);

    Dir.cwd().deleteTree(io, stage_root) catch {};
    defer Dir.cwd().deleteTree(io, stage_root) catch {};

    Dir.cwd().createDirPath(io, stage_root) catch |err| return diagnostic.fail(
        error.Failed,
        "cannot create staging directory {s}: {t}",
        .{ stage_root, err },
    );

    const staged_exe_path = std.fs.path.join(
        allocator,
        &.{ stage_root, platform.executable },
    ) catch return error.OutOfMemory;
    defer allocator.free(staged_exe_path);

    {
        var exe_file = Dir.cwd().createFile(io, staged_exe_path, .{
            .truncate = true,
            .permissions = .executable_file,
        }) catch |err| return diagnostic.fail(
            error.Failed,
            "cannot create staged executable {s}: {t}",
            .{ staged_exe_path, err },
        );
        defer exe_file.close(io);
        exe_file.writeStreamingAll(io, exe_bytes) catch |err| return diagnostic.fail(
            error.Failed,
            "cannot write staged executable {s}: {t}",
            .{ staged_exe_path, err },
        );
    }

    const staged_copying_path = std.fs.path.join(
        allocator,
        &.{ stage_root, "COPYING" },
    ) catch return error.OutOfMemory;
    defer allocator.free(staged_copying_path);
    writeAtomic(io, staged_copying_path, copying_bytes) catch |err| return diagnostic.fail(
        error.Failed,
        "cannot write staged COPYING: {t}",
        .{err},
    );

    const staged_readme_path = std.fs.path.join(
        allocator,
        &.{ stage_root, "README.md" },
    ) catch return error.OutOfMemory;
    defer allocator.free(staged_readme_path);
    writeAtomic(io, staged_readme_path, readme_bytes) catch |err| return diagnostic.fail(
        error.Failed,
        "cannot write staged README.md: {t}",
        .{err},
    );

    const archive_name = std.fmt.allocPrint(
        allocator,
        "{s}.tar.gz",
        .{pkg_name},
    ) catch return error.OutOfMemory;
    defer allocator.free(archive_name);

    const archive_path = std.fs.path.join(allocator, &.{ output_dir, archive_name }) catch
        return error.OutOfMemory;
    defer allocator.free(archive_path);

    const tar_res = runCapture(
        allocator,
        io,
        &.{ "tar", "-czf", archive_path, "-C", stage_root, platform.executable, "COPYING", "README.md" },
    ) catch |err| return diagnostic.fail(
        error.Failed,
        "cannot execute tar to create {s}: {t}",
        .{ archive_name, err },
    );
    defer allocator.free(tar_res.stdout);
    defer allocator.free(tar_res.stderr);
    const tar_ok = switch (tar_res.term) {
        .exited => |code| code == 0,
        else => false,
    };
    if (!tar_ok) {
        return diagnostic.fail(
            error.Failed,
            "tar failed creating {s}: {s}",
            .{ archive_name, std.mem.trim(u8, tar_res.stderr, " \t\r\n") },
        );
    }

    try inspectArchive(allocator, io, archive_path, version, platform_suffix, diagnostic);
}

pub fn inspectArchiveListText(
    entries_text: []const u8,
    version: []const u8,
    platform_suffix: []const u8,
    diagnostic: *Diagnostic,
) Error!void {
    try validateReleaseVersion(version, diagnostic);
    const platform = findPlatform(platform_suffix) orelse return diagnostic.fail(
        error.Failed,
        "platform {s} is not in the 6-platform release allowlist",
        .{platform_suffix},
    );

    var has_exe = false;
    var has_copying = false;
    var has_readme = false;
    var exe_count: usize = 0;

    var lines = std.mem.splitScalar(u8, entries_text, '\n');
    while (lines.next()) |raw_line| {
        const line = std.mem.trimEnd(u8, raw_line, "\r");
        if (line.len == 0) continue;

        if (!isSafeArchiveEntryPath(line)) {
            return diagnostic.fail(
                error.Failed,
                "archive contains unsafe path entry: {s}",
                .{line},
            );
        }

        if (isSbOmOrSpdxPath(line)) {
            return diagnostic.fail(
                error.Failed,
                "archive contains prohibited SBOM/SPDX entry: {s}",
                .{line},
            );
        }

        if (isLibcurlDevPath(line)) {
            return diagnostic.fail(
                error.Failed,
                "archive contains out-of-scope libcurl development entry: {s}",
                .{line},
            );
        }

        if (std.mem.indexOfScalar(u8, line, '/') != null) {
            return diagnostic.fail(
                error.Failed,
                "archive entry {s} must be at the top level of the archive",
                .{line},
            );
        }

        if (std.mem.eql(u8, line, platform.executable)) {
            exe_count += 1;
            has_exe = true;
        } else if (std.mem.eql(u8, line, "COPYING")) {
            if (has_copying) {
                return diagnostic.fail(
                    error.Failed,
                    "archive contains duplicate COPYING entry",
                    .{},
                );
            }
            has_copying = true;
        } else if (std.mem.eql(u8, line, "README.md")) {
            if (has_readme) {
                return diagnostic.fail(
                    error.Failed,
                    "archive contains duplicate README.md entry",
                    .{},
                );
            }
            has_readme = true;
        } else {
            return diagnostic.fail(
                error.Failed,
                "archive contains unexpected entry: {s}",
                .{line},
            );
        }
    }

    if (exe_count != 1 or !has_exe) {
        return diagnostic.fail(
            error.Failed,
            "archive for {s} must contain exactly one executable ({s})",
            .{ platform.suffix, platform.executable },
        );
    }
    if (!has_copying) {
        return diagnostic.fail(
            error.Failed,
            "archive for {s} is missing COPYING",
            .{platform.suffix},
        );
    }
    if (!has_readme) {
        return diagnostic.fail(
            error.Failed,
            "archive for {s} is missing README.md",
            .{platform.suffix},
        );
    }
}

pub fn inspectArchive(
    allocator: Allocator,
    io: Io,
    archive_path: []const u8,
    version: []const u8,
    platform_suffix: []const u8,
    diagnostic: *Diagnostic,
) Error!void {
    try validateReleaseVersion(version, diagnostic);
    const platform = findPlatform(platform_suffix) orelse return diagnostic.fail(
        error.Failed,
        "platform {s} is not in the 6-platform release allowlist",
        .{platform_suffix},
    );

    const base_name = std.fs.path.basename(archive_path);
    var expected_name_buf: [256]u8 = undefined;
    const expected_name = std.fmt.bufPrint(
        &expected_name_buf,
        "curl-{s}-{s}.tar.gz",
        .{ version, platform.suffix },
    ) catch return diagnostic.fail(error.Failed, "archive name is too long", .{});

    if (!std.mem.eql(u8, base_name, expected_name)) {
        return diagnostic.fail(
            error.Failed,
            "archive filename {s} does not match expected {s}",
            .{ base_name, expected_name },
        );
    }

    const hashed = hashRegularNoSymlink(io, archive_path) catch |err| return diagnostic.fail(
        error.Failed,
        "archive {s} is not a valid regular file: {t}",
        .{ archive_path, err },
    );
    if (hashed.size == 0) {
        return diagnostic.fail(
            error.Failed,
            "archive {s} is empty",
            .{archive_path},
        );
    }

    const tar_res = runCapture(
        allocator,
        io,
        &.{ "tar", "-tzf", archive_path },
    ) catch |err| return diagnostic.fail(
        error.Failed,
        "cannot execute tar to inspect {s}: {t}",
        .{ archive_path, err },
    );
    defer allocator.free(tar_res.stdout);
    defer allocator.free(tar_res.stderr);
    const tar_ok = switch (tar_res.term) {
        .exited => |code| code == 0,
        else => false,
    };
    if (!tar_ok) {
        return diagnostic.fail(
            error.Failed,
            "tar -tzf failed on {s}: {s}",
            .{ archive_path, std.mem.trim(u8, tar_res.stderr, " \t\r\n") },
        );
    }

    try inspectArchiveListText(tar_res.stdout, version, platform_suffix, diagnostic);
}

pub const verifyArchive = inspectArchive;

fn readU16Le(bytes: []const u8, offset: usize) ?u16 {
    if (offset + 2 > bytes.len) return null;
    return std.mem.readInt(u16, bytes[offset..][0..2], .little);
}

fn readU32Le(bytes: []const u8, offset: usize) ?u32 {
    if (offset + 4 > bytes.len) return null;
    return std.mem.readInt(u32, bytes[offset..][0..4], .little);
}

fn readU64Le(bytes: []const u8, offset: usize) ?u64 {
    if (offset + 8 > bytes.len) return null;
    return std.mem.readInt(u64, bytes[offset..][0..8], .little);
}

fn isAllowedWindowsSystemDll(name: []const u8) bool {
    const allowed = [_][]const u8{
        "kernel32.dll",
        "ntdll.dll",
        "ws2_32.dll",
        "advapi32.dll",
        "crypt32.dll",
        "secur32.dll",
        "normaliz.dll",
        "wldap32.dll",
        "msvcrt.dll",
        "ucrtbase.dll",
        "bcrypt.dll",
        "user32.dll",
        "shell32.dll",
        "iphlpapi.dll",
    };
    for (allowed) |item| {
        if (std.ascii.eqlIgnoreCase(name, item)) return true;
    }
    if (name.len > 11 and std.ascii.eqlIgnoreCase(name[0..11], "api-ms-win-")) return true;
    if (name.len > 11 and std.ascii.eqlIgnoreCase(name[0..11], "ext-ms-win-")) return true;
    return false;
}

pub fn inspectBinaryFormatAndDependencies(
    binary_bytes: []const u8,
    platform_suffix: []const u8,
    diagnostic: *Diagnostic,
) Error!void {
    if (std.mem.eql(u8, platform_suffix, "linux-musl-x64") or
        std.mem.eql(u8, platform_suffix, "linux-musl-arm64"))
    {
        if (binary_bytes.len < 64 or !std.mem.eql(u8, binary_bytes[0..4], "\x7fELF")) {
            return diagnostic.fail(
                error.Failed,
                "expected ELF64 binary for {s}",
                .{platform_suffix},
            );
        }
        if (binary_bytes[4] != 2 or binary_bytes[5] != 1) {
            return diagnostic.fail(
                error.Failed,
                "expected 64-bit little-endian ELF binary for {s}",
                .{platform_suffix},
            );
        }
        const e_machine = readU16Le(binary_bytes, 18) orelse return diagnostic.fail(
            error.Failed,
            "truncated ELF header for {s}",
            .{platform_suffix},
        );
        const expected_machine: u16 = if (std.mem.eql(u8, platform_suffix, "linux-musl-x64")) 62 else 183;
        if (e_machine != expected_machine) {
            return diagnostic.fail(
                error.Failed,
                "ELF e_machine mismatch for {s}: got {d}, expected {d}",
                .{ platform_suffix, e_machine, expected_machine },
            );
        }
        const e_phoff = readU64Le(binary_bytes, 32) orelse return diagnostic.fail(
            error.Failed,
            "truncated ELF e_phoff for {s}",
            .{platform_suffix},
        );
        const e_phentsize = readU16Le(binary_bytes, 54) orelse return diagnostic.fail(
            error.Failed,
            "truncated ELF e_phentsize for {s}",
            .{platform_suffix},
        );
        const e_phnum = readU16Le(binary_bytes, 56) orelse return diagnostic.fail(
            error.Failed,
            "truncated ELF e_phnum for {s}",
            .{platform_suffix},
        );
        var idx: usize = 0;
        while (idx < e_phnum) : (idx += 1) {
            const ph_offset = @as(usize, @intCast(e_phoff)) + idx * @as(usize, e_phentsize);
            const p_type = readU32Le(binary_bytes, ph_offset) orelse return diagnostic.fail(
                error.Failed,
                "truncated ELF program header in {s}",
                .{platform_suffix},
            );
            // PT_INTERP == 3 indicates a dynamically linked binary requiring an external loader.
            if (p_type == 3) {
                return diagnostic.fail(
                    error.Failed,
                    "{s} binary contains PT_INTERP (must be statically linked with musl)",
                    .{platform_suffix},
                );
            }
        }
        return;
    }

    if (std.mem.eql(u8, platform_suffix, "macos-x64") or
        std.mem.eql(u8, platform_suffix, "macos-arm64"))
    {
        if (binary_bytes.len < 32) {
            return diagnostic.fail(
                error.Failed,
                "truncated Mach-O binary for {s}",
                .{platform_suffix},
            );
        }
        const magic = readU32Le(binary_bytes, 0) orelse unreachable;
        if (magic != 0xfeedfacf) {
            return diagnostic.fail(
                error.Failed,
                "expected 64-bit Mach-O magic (0xfeedfacf) for {s}, got 0x{x}",
                .{ platform_suffix, magic },
            );
        }
        const cputype = readU32Le(binary_bytes, 4) orelse unreachable;
        const expected_cputype: u32 = if (std.mem.eql(u8, platform_suffix, "macos-x64"))
            0x01000007
        else
            0x0100000c;
        if (cputype != expected_cputype) {
            return diagnostic.fail(
                error.Failed,
                "Mach-O cputype mismatch for {s}: got 0x{x}, expected 0x{x}",
                .{ platform_suffix, cputype, expected_cputype },
            );
        }
        const ncmds = readU32Le(binary_bytes, 16) orelse unreachable;
        var cmd_offset: usize = 32;
        var cmd_idx: u32 = 0;
        while (cmd_idx < ncmds) : (cmd_idx += 1) {
            const cmd = readU32Le(binary_bytes, cmd_offset) orelse return diagnostic.fail(
                error.Failed,
                "truncated Mach-O load command in {s}",
                .{platform_suffix},
            );
            const cmdsize = readU32Le(binary_bytes, cmd_offset + 4) orelse return diagnostic.fail(
                error.Failed,
                "truncated Mach-O load command size in {s}",
                .{platform_suffix},
            );
            if (cmdsize < 8 or cmd_offset + cmdsize > binary_bytes.len) {
                return diagnostic.fail(
                    error.Failed,
                    "invalid Mach-O load command size in {s}",
                    .{platform_suffix},
                );
            }
            // LC_LOAD_DYLIB (0xc), LC_LOAD_WEAK_DYLIB (0x80000018), LC_REEXPORT_DYLIB (0x8000001f),
            // LC_LAZY_LOAD_DYLIB (0x20), LC_LOAD_UPWARD_DYLIB (0x80000023)
            if (cmd == 0x0c or cmd == 0x80000018 or cmd == 0x8000001f or cmd == 0x20 or cmd == 0x80000023) {
                const name_offset = readU32Le(binary_bytes, cmd_offset + 8) orelse return diagnostic.fail(
                    error.Failed,
                    "invalid Mach-O dylib command in {s}",
                    .{platform_suffix},
                );
                if (name_offset >= cmdsize) {
                    return diagnostic.fail(
                        error.Failed,
                        "Mach-O dylib name offset out of range in {s}",
                        .{platform_suffix},
                    );
                }
                const str_slice = binary_bytes[cmd_offset + name_offset .. cmd_offset + cmdsize];
                const nul_idx = std.mem.indexOfScalar(u8, str_slice, 0) orelse str_slice.len;
                const dylib_name = str_slice[0..nul_idx];
                if (!std.mem.startsWith(u8, dylib_name, "/usr/lib/") and
                    !std.mem.startsWith(u8, dylib_name, "/System/Library/"))
                {
                    return diagnostic.fail(
                        error.Failed,
                        "{s} links non-system dylib: {s}",
                        .{ platform_suffix, dylib_name },
                    );
                }
            }
            cmd_offset += cmdsize;
        }
        return;
    }

    if (std.mem.eql(u8, platform_suffix, "windows-x64") or
        std.mem.eql(u8, platform_suffix, "windows-arm64"))
    {
        if (binary_bytes.len < 0x40 or !std.mem.eql(u8, binary_bytes[0..2], "MZ")) {
            return diagnostic.fail(
                error.Failed,
                "expected PE MZ header for {s}",
                .{platform_suffix},
            );
        }
        const pe_offset = readU32Le(binary_bytes, 0x3c) orelse return diagnostic.fail(
            error.Failed,
            "truncated DOS header for {s}",
            .{platform_suffix},
        );
        const pe_pos: usize = @intCast(pe_offset);
        if (pe_pos + 24 > binary_bytes.len or !std.mem.eql(u8, binary_bytes[pe_pos .. pe_pos + 4], "PE\x00\x00")) {
            return diagnostic.fail(
                error.Failed,
                "invalid PE signature for {s}",
                .{platform_suffix},
            );
        }
        const machine = readU16Le(binary_bytes, pe_pos + 4) orelse unreachable;
        const expected_machine: u16 = if (std.mem.eql(u8, platform_suffix, "windows-x64")) 0x8664 else 0xaa64;
        if (machine != expected_machine) {
            return diagnostic.fail(
                error.Failed,
                "PE machine mismatch for {s}: got 0x{x}, expected 0x{x}",
                .{ platform_suffix, machine, expected_machine },
            );
        }
        const num_sections = readU16Le(binary_bytes, pe_pos + 6) orelse unreachable;
        const opt_hdr_size = readU16Le(binary_bytes, pe_pos + 20) orelse unreachable;
        const opt_pos = pe_pos + 24;
        if (opt_pos + opt_hdr_size > binary_bytes.len or opt_hdr_size < 120) {
            return diagnostic.fail(
                error.Failed,
                "invalid PE32+ optional header for {s}",
                .{platform_suffix},
            );
        }
        const opt_magic = readU16Le(binary_bytes, opt_pos) orelse unreachable;
        if (opt_magic != 0x020b) {
            return diagnostic.fail(
                error.Failed,
                "expected PE32+ magic (0x020b) for {s}, got 0x{x}",
                .{ platform_suffix, opt_magic },
            );
        }
        // DataDirectory[1] (Import Table) is at opt_pos + 112 + 8 = opt_pos + 120
        const import_rva = readU32Le(binary_bytes, opt_pos + 120) orelse 0;
        const sect_table_pos = opt_pos + opt_hdr_size;
        if (import_rva != 0 and sect_table_pos + @as(usize, num_sections) * 40 <= binary_bytes.len) {
            const rvaToOffset = struct {
                fn resolve(bytes: []const u8, sect_base: usize, count: u16, rva: u32) ?usize {
                    var s_idx: usize = 0;
                    while (s_idx < count) : (s_idx += 1) {
                        const sh = sect_base + s_idx * 40;
                        const vsize = readU32Le(bytes, sh + 8) orelse return null;
                        const vaddr = readU32Le(bytes, sh + 12) orelse return null;
                        const raw_size = readU32Le(bytes, sh + 16) orelse return null;
                        const raw_ptr = readU32Le(bytes, sh + 20) orelse return null;
                        const span = @max(vsize, raw_size);
                        if (rva >= vaddr and rva < vaddr + span) {
                            const off = @as(usize, raw_ptr) + @as(usize, rva - vaddr);
                            if (off < bytes.len) return off;
                        }
                    }
                    return null;
                }
            }.resolve;

            if (rvaToOffset(binary_bytes, sect_table_pos, num_sections, import_rva)) |imp_base| {
                var desc_off = imp_base;
                while (desc_off + 20 <= binary_bytes.len) : (desc_off += 20) {
                    const name_rva = readU32Le(binary_bytes, desc_off + 12) orelse break;
                    const first_thunk = readU32Le(binary_bytes, desc_off + 16) orelse break;
                    if (name_rva == 0 and first_thunk == 0) break;
                    if (name_rva != 0) {
                        if (rvaToOffset(binary_bytes, sect_table_pos, num_sections, name_rva)) |name_off| {
                            const rem = binary_bytes[name_off..];
                            const nul = std.mem.indexOfScalar(u8, rem, 0) orelse rem.len;
                            const dll_name = rem[0..nul];
                            if (!isAllowedWindowsSystemDll(dll_name)) {
                                return diagnostic.fail(
                                    error.Failed,
                                    "{s} imports non-system DLL: {s}",
                                    .{ platform_suffix, dll_name },
                                );
                            }
                        }
                    }
                }
            }
        }
        return;
    }

    return diagnostic.fail(error.Failed, "unknown platform suffix: {s}", .{platform_suffix});
}

fn runSmokeLoopbackHttpServer(server: *Io.net.Server, io: Io) void {
    var req_idx: usize = 0;
    while (req_idx < 2) : (req_idx += 1) {
        var stream = server.accept(io) catch return;
        defer stream.close(io);

        var rbuf: [1024]u8 = undefined;
        var reader = stream.reader(io, &rbuf);
        var req_buf: [2048]u8 = undefined;
        var req_len: usize = 0;
        while (req_len < req_buf.len) {
            var slice = [_][]u8{req_buf[req_len..]};
            const n = reader.interface.readVec(&slice) catch break;
            if (n == 0) break;
            req_len += n;
            if (std.mem.indexOf(u8, req_buf[0..req_len], "\r\n\r\n") != null) break;
        }

        const resp: []const u8 = if (req_idx == 0)
            "HTTP/1.1 302 Found\r\nLocation: /final\r\nX-Release-Hop: 1\r\nContent-Length: 0\r\nConnection: close\r\n\r\n"
        else
            "HTTP/1.1 200 OK\r\nX-Release-Check: passed\r\nContent-Type: text/plain\r\nContent-Length: 23\r\nConnection: close\r\n\r\nrelease-http-smoke-body";

        var wbuf: [1024]u8 = undefined;
        var writer = stream.writer(io, &wbuf);
        writer.interface.writeAll(resp) catch return;
        writer.interface.flush() catch return;
    }
}

fn hasWhitespaceToken(text: []const u8, expected: []const u8) bool {
    var iter = std.mem.tokenizeAny(u8, text, " \t\r\n");
    while (iter.next()) |token| {
        if (std.mem.eql(u8, token, expected)) return true;
    }
    return false;
}

pub fn verifyVersionOutputProtocolsAndFeatures(
    stdout: []const u8,
    platform_suffix: []const u8,
    diagnostic: *Diagnostic,
) Error!void {
    var protocols_line: ?[]const u8 = null;
    var features_line: ?[]const u8 = null;

    var lines = std.mem.splitScalar(u8, stdout, '\n');
    while (lines.next()) |raw_line| {
        const line = std.mem.trim(u8, raw_line, " \t\r");
        if (std.mem.startsWith(u8, line, "Protocols:")) {
            protocols_line = line;
        } else if (std.mem.startsWith(u8, line, "Features:")) {
            features_line = line;
        }
    }

    const p_line = protocols_line orelse return diagnostic.fail(
        error.Failed,
        "missing Protocols: line in --version output for {s}: {s}",
        .{ platform_suffix, std.mem.trim(u8, stdout, " \t\r\n") },
    );
    const f_line = features_line orelse return diagnostic.fail(
        error.Failed,
        "missing Features: line in --version output for {s}: {s}",
        .{ platform_suffix, std.mem.trim(u8, stdout, " \t\r\n") },
    );

    const p_tokens = p_line["Protocols:".len..];
    for (expected_release_protocols) |proto| {
        if (!hasWhitespaceToken(p_tokens, proto)) {
            return diagnostic.fail(
                error.Failed,
                "missing protocol '{s}' in --version output for {s}: {s}",
                .{ proto, platform_suffix, p_line },
            );
        }
    }

    const f_tokens = f_line["Features:".len..];
    for (expected_common_release_features) |feat| {
        if (!hasWhitespaceToken(f_tokens, feat)) {
            return diagnostic.fail(
                error.Failed,
                "missing feature '{s}' in --version output for {s}: {s}",
                .{ feat, platform_suffix, f_line },
            );
        }
    }

    if (std.mem.startsWith(u8, platform_suffix, "linux-")) {
        if (!hasWhitespaceToken(f_tokens, "GSS-API")) {
            return diagnostic.fail(
                error.Failed,
                "missing feature '{s}' in --version output for {s}: {s}",
                .{ "GSS-API", platform_suffix, f_line },
            );
        }
    } else if (std.mem.startsWith(u8, platform_suffix, "macos-")) {
        const macos_features = [_][]const u8{ "GSS-API", "AppleSecTrust" };
        for (macos_features) |feat| {
            if (!hasWhitespaceToken(f_tokens, feat)) {
                return diagnostic.fail(
                    error.Failed,
                    "missing feature '{s}' in --version output for {s}: {s}",
                    .{ feat, platform_suffix, f_line },
                );
            }
        }
    } else if (std.mem.startsWith(u8, platform_suffix, "windows-")) {
        const windows_features = [_][]const u8{ "SSPI", "Unicode" };
        for (windows_features) |feat| {
            if (!hasWhitespaceToken(f_tokens, feat)) {
                return diagnostic.fail(
                    error.Failed,
                    "missing feature '{s}' in --version output for {s}: {s}",
                    .{ feat, platform_suffix, f_line },
                );
            }
        }
    } else {
        return diagnostic.fail(
            error.Failed,
            "unsupported platform suffix: {s}",
            .{platform_suffix},
        );
    }
}

pub fn verifyPackage(
    allocator: Allocator,
    io: Io,
    archive_path: []const u8,
    version: []const u8,
    platform_suffix: []const u8,
    run_smoke: bool,
    diagnostic: *Diagnostic,
) Error!void {
    try validateReleaseVersion(version, diagnostic);
    const platform = findPlatform(platform_suffix) orelse return diagnostic.fail(
        error.Failed,
        "unsupported platform suffix: {s}",
        .{platform_suffix},
    );

    try inspectArchive(allocator, io, archive_path, version, platform_suffix, diagnostic);

    var rand_bytes: [8]u8 = undefined;
    io.random(&rand_bytes);
    const rand_hex = std.fmt.bytesToHex(rand_bytes, .lower);
    const temp_dir = std.fmt.allocPrint(
        allocator,
        "{s}.verify-{s}",
        .{ archive_path, &rand_hex },
    ) catch return error.OutOfMemory;
    defer allocator.free(temp_dir);

    Dir.cwd().deleteTree(io, temp_dir) catch {};
    Dir.cwd().createDirPath(io, temp_dir) catch |err| return diagnostic.fail(
        error.Failed,
        "cannot create verification directory {s}: {t}",
        .{ temp_dir, err },
    );
    defer Dir.cwd().deleteTree(io, temp_dir) catch {};

    const untar_res = runCapture(
        allocator,
        io,
        &.{ "tar", "-xzf", archive_path, "-C", temp_dir },
    ) catch |err| return diagnostic.fail(
        error.Failed,
        "cannot extract archive {s}: {t}",
        .{ archive_path, err },
    );
    defer allocator.free(untar_res.stdout);
    defer allocator.free(untar_res.stderr);
    const untar_ok = switch (untar_res.term) {
        .exited => |code| code == 0,
        else => false,
    };
    if (!untar_ok) {
        return diagnostic.fail(
            error.Failed,
            "tar -xzf failed on {s}: {s}",
            .{ archive_path, std.mem.trim(u8, untar_res.stderr, " \t\r\n") },
        );
    }

    const unpacked_copying = std.fs.path.join(
        allocator,
        &.{ temp_dir, "COPYING" },
    ) catch return error.OutOfMemory;
    defer allocator.free(unpacked_copying);

    const unpacked_readme = std.fs.path.join(
        allocator,
        &.{ temp_dir, "README.md" },
    ) catch return error.OutOfMemory;
    defer allocator.free(unpacked_readme);

    const unpacked_exe = std.fs.path.join(
        allocator,
        &.{ temp_dir, platform.executable },
    ) catch return error.OutOfMemory;
    defer allocator.free(unpacked_exe);

    const copying_bytes = readBounded(
        allocator,
        io,
        unpacked_copying,
        1024 * 1024,
    ) catch |err| return diagnostic.fail(
        error.Failed,
        "cannot read unpacked COPYING {s}: {t}",
        .{ unpacked_copying, err },
    );
    defer allocator.free(copying_bytes);
    if (std.mem.indexOf(u8, copying_bytes, "Copyright") == null) {
        return diagnostic.fail(
            error.Failed,
            "unpacked COPYING {s} is missing copyright notice",
            .{unpacked_copying},
        );
    }

    const readme_bytes = readBounded(
        allocator,
        io,
        unpacked_readme,
        1024 * 1024,
    ) catch |err| return diagnostic.fail(
        error.Failed,
        "cannot read unpacked README.md {s}: {t}",
        .{ unpacked_readme, err },
    );
    defer allocator.free(readme_bytes);
    if (readme_bytes.len == 0) {
        return diagnostic.fail(
            error.Failed,
            "unpacked README.md {s} is empty",
            .{unpacked_readme},
        );
    }

    const binary_bytes = readBounded(
        allocator,
        io,
        unpacked_exe,
        128 * 1024 * 1024,
    ) catch |err| return diagnostic.fail(
        error.Failed,
        "cannot read unpacked executable {s}: {t}",
        .{ unpacked_exe, err },
    );
    defer allocator.free(binary_bytes);

    try inspectBinaryFormatAndDependencies(binary_bytes, platform.suffix, diagnostic);

    if (!run_smoke) return;

    // 1. Verify `curl --version` reports the expected release version and features
    const ver_res = runCapture(
        allocator,
        io,
        &.{ unpacked_exe, "--version" },
    ) catch |err| return diagnostic.fail(
        error.Failed,
        "cannot run unpacked {s} --version: {t}",
        .{ unpacked_exe, err },
    );
    defer allocator.free(ver_res.stdout);
    defer allocator.free(ver_res.stderr);
    const ver_ok = switch (ver_res.term) {
        .exited => |code| code == 0,
        else => false,
    };
    if (!ver_ok) {
        return diagnostic.fail(
            error.Failed,
            "unpacked {s} --version exited non-zero: {s}",
            .{ unpacked_exe, std.mem.trim(u8, ver_res.stderr, " \t\r\n") },
        );
    }
    const expected_prefix = std.fmt.allocPrint(allocator, "curl {s} ", .{version}) catch
        return error.OutOfMemory;
    defer allocator.free(expected_prefix);
    const expected_libcurl = std.fmt.allocPrint(allocator, "libcurl/{s}", .{version}) catch
        return error.OutOfMemory;
    defer allocator.free(expected_libcurl);
    if (!std.mem.startsWith(u8, ver_res.stdout, expected_prefix) or
        std.mem.indexOf(u8, ver_res.stdout, expected_libcurl) == null or
        std.mem.indexOf(u8, ver_res.stdout, "Protocols:") == null or
        std.mem.indexOf(u8, ver_res.stdout, "Features:") == null)
    {
        return diagnostic.fail(
            error.Failed,
            "unexpected --version output from unpacked {s}: {s}",
            .{ unpacked_exe, std.mem.trim(u8, ver_res.stdout, " \t\r\n") },
        );
    }
    try verifyVersionOutputProtocolsAndFeatures(ver_res.stdout, platform.suffix, diagnostic);

    // 2. Verify real `file://` transfer from unpacked binary
    const payload_rel = std.fs.path.join(allocator, &.{ temp_dir, "payload.txt" }) catch
        return error.OutOfMemory;
    defer allocator.free(payload_rel);
    const payload_expected = "curl-zig-release-file-transfer-ok\n";
    writeAtomic(io, payload_rel, payload_expected) catch |err| return diagnostic.fail(
        error.Failed,
        "cannot write file:// test payload: {t}",
        .{err},
    );
    const payload_abs = Dir.realPathFileAlloc(Dir.cwd(), io, payload_rel, allocator) catch |err|
        return diagnostic.fail(error.Failed, "cannot resolve payload path: {t}", .{err});
    defer allocator.free(payload_abs);

    const normalized_path = allocator.dupe(u8, payload_abs) catch return error.OutOfMemory;
    defer allocator.free(normalized_path);
    for (normalized_path) |*ch| {
        if (ch.* == '\\') ch.* = '/';
    }
    const file_url = if (std.mem.startsWith(u8, normalized_path, "/"))
        std.fmt.allocPrint(allocator, "file://{s}", .{normalized_path}) catch return error.OutOfMemory
    else
        std.fmt.allocPrint(allocator, "file:///{s}", .{normalized_path}) catch return error.OutOfMemory;
    defer allocator.free(file_url);

    const file_res = runCapture(
        allocator,
        io,
        &.{ unpacked_exe, "-fsS", file_url },
    ) catch |err| return diagnostic.fail(
        error.Failed,
        "cannot run unpacked {s} file:// transfer: {t}",
        .{ unpacked_exe, err },
    );
    defer allocator.free(file_res.stdout);
    defer allocator.free(file_res.stderr);
    const file_ok = switch (file_res.term) {
        .exited => |code| code == 0,
        else => false,
    };
    if (!file_ok or !std.mem.eql(u8, file_res.stdout, payload_expected)) {
        return diagnostic.fail(
            error.Failed,
            "unpacked {s} file:// transfer failed (stdout='{s}', stderr='{s}')",
            .{ unpacked_exe, file_res.stdout, std.mem.trim(u8, file_res.stderr, " \t\r\n") },
        );
    }

    // 3. Verify real loopback `http://127.0.0.1` transfer (status code, headers, and redirect)
    const bind_addr = Io.net.IpAddress.parseIp4("127.0.0.1", 0) catch unreachable;
    var server = bind_addr.listen(io, .{ .reuse_address = true }) catch |err|
        return diagnostic.fail(error.Failed, "cannot listen on loopback socket: {t}", .{err});
    defer server.deinit(io);
    const http_port = server.socket.address.getPort();

    const server_thread = std.Thread.spawn(.{}, runSmokeLoopbackHttpServer, .{ &server, io }) catch |err|
        return diagnostic.fail(error.Failed, "cannot spawn loopback HTTP server thread: {t}", .{err});
    var thread_joined = false;
    defer if (!thread_joined) server_thread.join();

    const headers_path = std.fs.path.join(allocator, &.{ temp_dir, "headers.txt" }) catch
        return error.OutOfMemory;
    defer allocator.free(headers_path);
    const http_url = std.fmt.allocPrint(
        allocator,
        "http://127.0.0.1:{d}/redirect",
        .{http_port},
    ) catch return error.OutOfMemory;
    defer allocator.free(http_url);

    const http_res = runCapture(
        allocator,
        io,
        &.{ unpacked_exe, "-fsSL", "-D", headers_path, http_url },
    ) catch |err| return diagnostic.fail(
        error.Failed,
        "cannot run unpacked {s} loopback HTTP transfer: {t}",
        .{ unpacked_exe, err },
    );
    defer allocator.free(http_res.stdout);
    defer allocator.free(http_res.stderr);
    server_thread.join();
    thread_joined = true;

    const http_ok = switch (http_res.term) {
        .exited => |code| code == 0,
        else => false,
    };
    if (!http_ok or !std.mem.eql(u8, http_res.stdout, "release-http-smoke-body")) {
        return diagnostic.fail(
            error.Failed,
            "unpacked {s} loopback HTTP transfer failed (stdout='{s}', stderr='{s}')",
            .{ unpacked_exe, http_res.stdout, std.mem.trim(u8, http_res.stderr, " \t\r\n") },
        );
    }
    const headers_bytes = readBounded(allocator, io, headers_path, 64 * 1024) catch |err|
        return diagnostic.fail(error.Failed, "cannot read HTTP headers dump: {t}", .{err});
    defer allocator.free(headers_bytes);
    if (std.mem.indexOf(u8, headers_bytes, "302 Found") == null or
        std.mem.indexOf(u8, headers_bytes, "200 OK") == null or
        std.mem.indexOf(u8, headers_bytes, "X-Release-Check: passed") == null)
    {
        return diagnostic.fail(
            error.Failed,
            "unexpected HTTP headers from loopback smoke test: {s}",
            .{headers_bytes},
        );
    }

    // 4. Verify expected failure behavior and non-zero exit code on malformed URL
    const fail_res = std.process.run(allocator, io, .{
        .argv = &.{ unpacked_exe, "--silent", "--show-error", "http://127.0.0.1:0/unreachable" },
    }) catch |err| return diagnostic.fail(
        error.Failed,
        "cannot run unpacked {s} failure check: {t}",
        .{ unpacked_exe, err },
    );
    defer allocator.free(fail_res.stdout);
    defer allocator.free(fail_res.stderr);
    const failed_as_expected = switch (fail_res.term) {
        .exited => |code| code != 0,
        else => false,
    };
    if (!failed_as_expected) {
        return diagnostic.fail(
            error.Failed,
            "expected non-zero exit code from unpacked {s} on unreachable endpoint",
            .{unpacked_exe},
        );
    }

    // 5. Verify `--proto '=https' --tlsv1.2` is accepted (HTTPS protocol and TLS 1.2 enabled)
    const https_res = runCapture(
        allocator,
        io,
        &.{ unpacked_exe, "--proto", "=https", "--tlsv1.2", "--silent", "--show-error", "https://127.0.0.1:0/unreachable" },
    ) catch |err| return diagnostic.fail(
        error.Failed,
        "cannot run unpacked {s} https/tlsv1.2 check: {t}",
        .{ unpacked_exe, err },
    );
    defer allocator.free(https_res.stdout);
    defer allocator.free(https_res.stderr);
    const https_failed_as_expected = switch (https_res.term) {
        .exited => |code| code != 0,
        else => false,
    };
    if (!https_failed_as_expected) {
        return diagnostic.fail(
            error.Failed,
            "expected non-zero exit code from unpacked {s} on unreachable https endpoint",
            .{unpacked_exe},
        );
    }
    if (std.mem.indexOf(u8, https_res.stderr, "unrecognized protocol") != null or
        std.mem.indexOf(u8, https_res.stderr, "is badly used here") != null or
        std.mem.indexOf(u8, https_res.stderr, "is disabled") != null)
    {
        return diagnostic.fail(
            error.Failed,
            "unpacked {s} rejected --proto '=https' --tlsv1.2: {s}",
            .{ unpacked_exe, std.mem.trim(u8, https_res.stderr, " \t\r\n") },
        );
    }
}

pub fn checksumManifestName(allocator: Allocator, version: []const u8) ![]u8 {
    return std.fmt.allocPrint(allocator, "curl-{s}-SHA256SUMS.txt", .{version});
}

pub fn generateChecksums(
    allocator: Allocator,
    io: Io,
    assets_directory: []const u8,
    version: []const u8,
    output_path_override: ?[]const u8,
    diagnostic: *Diagnostic,
) Error!void {
    try validateReleaseVersion(version, diagnostic);

    const manifest_name = checksumManifestName(allocator, version) catch
        return error.OutOfMemory;
    defer allocator.free(manifest_name);

    const default_output_path = std.fs.path.join(
        allocator,
        &.{ assets_directory, manifest_name },
    ) catch return error.OutOfMemory;
    defer allocator.free(default_output_path);

    const output_path = output_path_override orelse default_output_path;

    var out_buf: std.ArrayList(u8) = .empty;
    defer out_buf.deinit(allocator);

    for (platforms) |platform| {
        const archive_name = std.fmt.allocPrint(
            allocator,
            "curl-{s}-{s}.tar.gz",
            .{ version, platform.suffix },
        ) catch return error.OutOfMemory;
        defer allocator.free(archive_name);

        const archive_path = std.fs.path.join(
            allocator,
            &.{ assets_directory, archive_name },
        ) catch return error.OutOfMemory;
        defer allocator.free(archive_path);

        try inspectArchive(allocator, io, archive_path, version, platform.suffix, diagnostic);

        const hashed = hashRegularNoSymlink(io, archive_path) catch |err| return diagnostic.fail(
            error.Failed,
            "cannot hash archive {s}: {t}",
            .{ archive_name, err },
        );

        var line_buf: [512]u8 = undefined;
        const line = std.fmt.bufPrint(
            &line_buf,
            "{s}  {s}\n",
            .{ &hashed.hex, archive_name },
        ) catch return diagnostic.fail(error.Failed, "checksum line is too long", .{});
        out_buf.appendSlice(allocator, line) catch return error.OutOfMemory;
    }

    writeAtomic(io, output_path, out_buf.items) catch |err| return diagnostic.fail(
        error.Failed,
        "cannot write SHA-256 manifest {s}: {t}",
        .{ output_path, err },
    );
}

pub const Asset = struct {
    name: []u8,
    path: []u8,
    digest_hex: Hex,
    size: u64,
    identity: Identity,
    remote_id: i64 = 0,
};

pub fn freeAssets(allocator: Allocator, assets: []Asset) void {
    for (assets) |asset| {
        allocator.free(asset.name);
        allocator.free(asset.path);
    }
    allocator.free(assets);
}

/// Validates the local release assets directory against the strict 6-archive allowlist:
/// - The 6 `curl-<version>-<platform>.tar.gz` archives (inspected for layout and no SBOM/SPDX)
/// Rejects any other file in `assets_directory`, including `SHA256SUMS.txt` or any SBOM or SPDX file.
pub fn verifyAssetsDirectory(
    allocator: Allocator,
    io: Io,
    assets_directory: []const u8,
    version: []const u8,
    diagnostic: *Diagnostic,
) Error![]Asset {
    try validateReleaseVersion(version, diagnostic);

    var expected_archives: [platforms.len][]u8 = undefined;
    var expected_archives_init: usize = 0;
    defer for (expected_archives[0..expected_archives_init]) |name| allocator.free(name);
    for (platforms) |platform| {
        expected_archives[expected_archives_init] = std.fmt.allocPrint(
            allocator,
            "curl-{s}-{s}.tar.gz",
            .{ version, platform.suffix },
        ) catch return error.OutOfMemory;
        expected_archives_init += 1;
    }

    var directory = Dir.cwd().openDir(io, assets_directory, .{
        .iterate = true,
    }) catch |err| return diagnostic.fail(
        error.Failed,
        "cannot open release assets directory {s}: {t}",
        .{ assets_directory, err },
    );
    defer directory.close(io);

    var iterator = directory.iterate();
    while (iterator.next(io) catch |err| return diagnostic.fail(
        error.Failed,
        "cannot enumerate release assets directory: {t}",
        .{err},
    )) |entry| {
        if (isSbOmOrSpdxPath(entry.name)) {
            return diagnostic.fail(
                error.Failed,
                "prohibited SBOM/SPDX file in release assets directory: {s}",
                .{entry.name},
            );
        }
        if (entry.kind != .file) {
            return diagnostic.fail(
                error.Failed,
                "non-regular file entry in release assets directory: {s}",
                .{entry.name},
            );
        }

        var is_allowed = false;
        for (expected_archives) |arch_name| {
            if (std.mem.eql(u8, entry.name, arch_name)) {
                is_allowed = true;
                break;
            }
        }

        if (!is_allowed) {
            return diagnostic.fail(
                error.Failed,
                "unexpected file outside release upload allowlist: {s}",
                .{entry.name},
            );
        }
    }

    var list: std.ArrayList(Asset) = .empty;
    errdefer {
        for (list.items) |asset| {
            allocator.free(asset.name);
            allocator.free(asset.path);
        }
        list.deinit(allocator);
    }

    for (platforms, expected_archives) |platform, archive_name| {
        const archive_path = std.fs.path.join(
            allocator,
            &.{ assets_directory, archive_name },
        ) catch return error.OutOfMemory;
        errdefer allocator.free(archive_path);

        try inspectArchive(allocator, io, archive_path, version, platform.suffix, diagnostic);

        const hashed = hashRegularNoSymlink(io, archive_path) catch |err| return diagnostic.fail(
            error.Failed,
            "release asset {s} is not a stable regular file: {t}",
            .{ archive_name, err },
        );
        if (hashed.size == 0) {
            return diagnostic.fail(
                error.Failed,
                "release asset is empty: {s}",
                .{archive_name},
            );
        }

        const dup_name = allocator.dupe(u8, archive_name) catch return error.OutOfMemory;
        errdefer allocator.free(dup_name);

        list.append(allocator, .{
            .name = dup_name,
            .path = archive_path,
            .digest_hex = hashed.hex,
            .size = hashed.size,
            .identity = hashed.identity,
        }) catch return error.OutOfMemory;
    }

    return list.toOwnedSlice(allocator) catch return error.OutOfMemory;
}

pub fn renderReleaseNotes(
    allocator: Allocator,
    repository_name: []const u8,
    tag: []const u8,
    version: []const u8,
    previous_tag: ?[]const u8,
    diagnostic: *Diagnostic,
) Error![]u8 {
    try validateVersionTag(version, tag, diagnostic);

    const comparison_line = if (previous_tag) |prev|
        std.fmt.allocPrint(
            allocator,
            "**Full comparison:** https://github.com/{s}/compare/{s}...{s}\n",
            .{ repository_name, prev, tag },
        ) catch return error.OutOfMemory
    else
        std.fmt.allocPrint(
            allocator,
            "**Commits:** https://github.com/{s}/commits/{s}\n",
            .{ repository_name, tag },
        ) catch return error.OutOfMemory;
    defer allocator.free(comparison_line);

    return std.fmt.allocPrint(
        allocator,
        \\**Install:**
        \\
        \\```console
        \\ghr install {s}@{s}
        \\```
        \\
        \\> **Distribution Identity:** `{s}` is a prerelease of the **curl Zig-port distribution**
        \\> maintained in [`{s}`](https://github.com/{s}), **not** an official upstream curl
        \\> release from https://curl.se. It targets the six-platform subset below and does
        \\> not promise upstream platform or feature parity.
        \\
        \\## Highlights
        \\
        \\- **Six-platform Zig-built `curl` CLI archives.** Publishes `linux-musl-x64`, `linux-musl-arm64`, `macos-x64`, `macos-arm64`, `windows-x64`, and `windows-arm64` archives (`curl-{s}-<platform>.tar.gz`) with GitHub build provenance attestations and zero SBOM or SPDX assets.
        \\- **All 25 protocols and full feature set across all 6 platforms.** Supports `DICT, FILE, FTP, FTPS, GOPHER, GOPHERS, HTTP, HTTPS, IMAP, IMAPS, LDAP, LDAPS, MQTT, MQTTS, POP3, POP3S, RTSP, SCP, SFTP, SMTP, SMTPS, TELNET, TFTP, WS, WSS` and features `SSL, HSTS, HTTP2, HTTP3, HTTPS-proxy, HTTPSIG, HTTPSRR, AsynchDNS, asyn-rr, IDN, IPv6, Kerberos, Largefile, libz, brotli, zstd, PSL, SPNEGO, alt-svc, proxy-HTTP3, threadsafe, UnixSockets` (`GSS-API` on Linux/macOS, `AppleSecTrust` on macOS, `SSPI` and `Unicode` on Windows).
        \\- **Native Windows OS integration on Windows x64 and Arm64.** Windows archives enable Schannel TLS (`-Dssl=schannel`), WinIDN (`-Didn=winidn`), WinLDAP (`-Dldap=winldap`), and Windows SSPI (`-Dsspi=true`) alongside bundled compression, HTTP/2, HTTP/3, SSH, PSL, and c-ares backends.
        \\- **Zero external third-party shared library dependencies.** Linux musl binaries are statically linked; macOS binaries link only system `libSystem.B.dylib` and Apple `Security`/`CoreFoundation` frameworks.
        \\
        \\## Platform Coverage & Runtime Requirements
        \\
        \\| Archive | Zig target | Binary | Runtime dependencies |
        \\|---|---|---|---|
        \\| `curl-{s}-linux-musl-x64.tar.gz` | `x86_64-linux-musl` | `curl` | Static musl binary (none) |
        \\| `curl-{s}-linux-musl-arm64.tar.gz` | `aarch64-linux-musl` | `curl` | Static musl binary (none) |
        \\| `curl-{s}-macos-x64.tar.gz` | `x86_64-macos` | `curl` | macOS `libSystem.B.dylib` + `Security`/`CoreFoundation` frameworks |
        \\| `curl-{s}-macos-arm64.tar.gz` | `aarch64-macos` | `curl` | macOS `libSystem.B.dylib` + `Security`/`CoreFoundation` frameworks |
        \\| `curl-{s}-windows-x64.tar.gz` | `x86_64-windows-gnu` | `curl.exe` | Windows system DLLs (`ws2_32`, `secur32`, `crypt32`, `advapi32`, `bcrypt`, `normaliz`, `wldap32`) |
        \\| `curl-{s}-windows-arm64.tar.gz` | `aarch64-windows-gnu` | `curl.exe` | Windows system DLLs (`ws2_32`, `secur32`, `crypt32`, `advapi32`, `bcrypt`, `normaliz`, `wldap32`) |
        \\
        \\## Known Limitations
        \\
        \\- **CLI-only binary packages:** `libcurl` C development headers and static/shared libraries are outside the scope of these release archives.
        \\
        \\{s}
    ,
        .{
            repository_name,
            tag,
            tag,
            repository_name,
            repository_name,
            version,
            version,
            version,
            version,
            version,
            version,
            version,
            comparison_line,
        },
    ) catch return error.OutOfMemory;
}

pub const ExpectedMetadata = struct {
    tag: []const u8,
    commit: []const u8,
    title: []const u8,
    body: []const u8,
    prerelease: bool,
};

const RemoteAsset = struct {
    id: i64,
    name: []const u8,
    size: u64,
    digest_text: ?[]const u8,
    state: AssetState,
};

const AssetState = enum {
    starter,
    uploaded,
};

const AssetPolicy = enum {
    allow_incomplete,
    require_uploaded,
};

const DeleteReason = enum {
    unexpected,
    duplicate,
    incomplete,
    wrong_size,
    wrong_digest,
};

const Release = struct {
    id: i64,
    draft: bool,
    body: []const u8,
    assets: []RemoteAsset,

    fn deinit(self: *Release, allocator: Allocator) void {
        allocator.free(self.body);
        for (self.assets) |asset| {
            allocator.free(asset.name);
            if (asset.digest_text) |text| allocator.free(text);
        }
        allocator.free(self.assets);
        self.* = undefined;
    }
};

pub const PublishOptions = struct {
    repository_name: []const u8,
    tag: []const u8,
    version: []const u8,
    commit: []const u8,
    assets_directory: []const u8,
    workspace: []const u8,
    gh_executable: []const u8 = "gh",
    summary_path: ?[]const u8 = null,
    environment: std.process.Environ,
};

const GhResult = struct {
    stdout: []u8,
    stderr: []u8,

    fn deinit(self: GhResult, allocator: Allocator) void {
        allocator.free(self.stdout);
        allocator.free(self.stderr);
    }
};

const Publisher = struct {
    allocator: Allocator,
    io: Io,
    diagnostic: *Diagnostic,
    options: PublishOptions,
    metadata: ExpectedMetadata,
    assets: []Asset,
    release_id: i64 = 0,
    previous_tag: ?[]u8 = null,

    fn fail(
        self: *Publisher,
        comptime format: []const u8,
        arguments: anytype,
    ) Error {
        self.diagnostic.set(format, arguments);
        return error.Failed;
    }

    fn gh(self: *Publisher, arguments: []const []const u8) Error!GhResult {
        var argv: std.ArrayList([]const u8) = .empty;
        defer argv.deinit(self.allocator);
        argv.append(self.allocator, self.options.gh_executable) catch
            return error.OutOfMemory;
        argv.appendSlice(self.allocator, arguments) catch
            return error.OutOfMemory;
        var environment = std.process.Environ.createMap(
            self.options.environment,
            self.allocator,
        ) catch return error.OutOfMemory;
        defer environment.deinit();
        const result = std.process.run(self.allocator, self.io, .{
            .argv = argv.items,
            .environ_map = &environment,
            .stdout_limit = .limited(maximum_gh_output_bytes),
            .stderr_limit = .limited(maximum_gh_output_bytes),
        }) catch |err| return self.fail(
            "cannot execute GitHub CLI: {t}",
            .{err},
        );
        const succeeded = switch (result.term) {
            .exited => |code| code == 0,
            else => false,
        };
        if (!succeeded) {
            defer self.allocator.free(result.stdout);
            defer self.allocator.free(result.stderr);
            return self.fail(
                "GitHub CLI command failed: {s}",
                .{std.mem.trim(u8, result.stderr, " \t\r\n")},
            );
        }
        return .{ .stdout = result.stdout, .stderr = result.stderr };
    }

    fn ghJson(self: *Publisher, arguments: []const []const u8) Error!std.json.Parsed(Value) {
        const result = try self.gh(arguments);
        defer result.deinit(self.allocator);
        return std.json.parseFromSlice(
            Value,
            self.allocator,
            result.stdout,
            .{},
        ) catch |err| self.fail("GitHub CLI returned invalid JSON: {t}", .{err});
    }

    fn verifyTag(self: *Publisher) Error!void {
        var endpoint_buffer: [512]u8 = undefined;
        const endpoint = std.fmt.bufPrint(
            &endpoint_buffer,
            "repos/{s}/git/ref/tags/{s}",
            .{ self.options.repository_name, self.options.tag },
        ) catch return self.fail("release tag is too long", .{});
        var ref = try self.ghJson(&.{ "api", endpoint });
        defer ref.deinit();
        var object = try self.objectField(&ref.value, "object", "tag ref object");
        var object_type = self.allocator.dupe(
            u8,
            try self.stringField(object, "type", "tag ref object type"),
        ) catch return error.OutOfMemory;
        defer self.allocator.free(object_type);
        var object_sha = self.allocator.dupe(
            u8,
            try self.stringField(object, "sha", "tag ref object SHA"),
        ) catch return error.OutOfMemory;
        defer self.allocator.free(object_sha);

        var depth: usize = 0;
        while (std.mem.eql(u8, object_type, "tag")) : (depth += 1) {
            if (depth == 8) return self.fail(
                "release tag annotation chain is too deep",
                .{},
            );
            var object_endpoint_buffer: [512]u8 = undefined;
            const object_endpoint = std.fmt.bufPrint(
                &object_endpoint_buffer,
                "repos/{s}/git/tags/{s}",
                .{ self.options.repository_name, object_sha },
            ) catch return self.fail("tag object endpoint is too long", .{});
            var tag_object = try self.ghJson(&.{ "api", object_endpoint });
            defer tag_object.deinit();
            object = try self.objectField(&tag_object.value, "object", "annotated tag target");
            const next_type = self.allocator.dupe(
                u8,
                try self.stringField(object, "type", "annotated tag target type"),
            ) catch return error.OutOfMemory;
            const next_sha = self.allocator.dupe(
                u8,
                try self.stringField(object, "sha", "annotated tag target SHA"),
            ) catch return error.OutOfMemory;
            self.allocator.free(object_type);
            self.allocator.free(object_sha);
            object_type = next_type;
            object_sha = next_sha;
        }
        if (!std.mem.eql(u8, object_type, "commit") or
            !std.mem.eql(u8, object_sha, self.options.commit))
        {
            return self.fail(
                "release tag resolves to {s} {s}, not workflow commit {s}",
                .{ object_type, object_sha, self.options.commit },
            );
        }
    }

    fn discover(self: *Publisher) Error!?Release {
        var endpoint_buffer: [512]u8 = undefined;
        const endpoint = std.fmt.bufPrint(
            &endpoint_buffer,
            "repos/{s}/releases?per_page=100",
            .{self.options.repository_name},
        ) catch return self.fail("repository name is too long", .{});
        var pages = try self.ghJson(&.{ "api", "--paginate", "--slurp", endpoint });
        defer pages.deinit();
        if (pages.value != .array) return self.fail(
            "paginated release listing is not an array",
            .{},
        );

        var exact: ?Release = null;
        const current_version = std.SemanticVersion.parse(self.options.version) catch unreachable;
        for (pages.value.array.items) |page| {
            if (page != .array) return self.fail(
                "paginated release page is not an array",
                .{},
            );
            for (page.array.items) |candidate| {
                if (candidate != .object) return self.fail(
                    "release listing entry is not an object",
                    .{},
                );
                const draft = try self.boolField(&candidate.object, "draft", "release draft state");
                const tag_value = candidate.object.get("tag_name");
                if (draft and (tag_value == null or tag_value.? == .null or
                    (tag_value.? == .string and tag_value.?.string.len == 0)))
                {
                    continue;
                }
                const tag = if (tag_value) |value| blk: {
                    if (value != .string) return self.fail("release tag is not a string", .{});
                    break :blk value.string;
                } else return self.fail("release tag is missing", .{});

                if (std.mem.eql(u8, tag, self.metadata.tag)) {
                    if (exact) |*previous| {
                        previous.deinit(self.allocator);
                        return self.fail(
                            "more than one release has exact tag {s}",
                            .{self.metadata.tag},
                        );
                    }
                    exact = try self.parseRelease(candidate, .allow_incomplete);
                    continue;
                }
                if (draft) continue;
                if (!std.mem.startsWith(u8, tag, "v")) continue;
                const candidate_version = std.SemanticVersion.parse(tag[1..]) catch continue;
                if (candidate_version.order(current_version) != .lt) continue;
                if (self.previous_tag) |previous| {
                    const previous_version = std.SemanticVersion.parse(previous[1..]) catch unreachable;
                    if (candidate_version.order(previous_version) != .gt) continue;
                    self.allocator.free(previous);
                }
                self.previous_tag = self.allocator.dupe(u8, tag) catch return error.OutOfMemory;
            }
        }
        if (exact) |release| {
            if (!release.draft) return self.fail(
                "release {s} is already published and immutable",
                .{self.metadata.tag},
            );
        }
        return exact;
    }

    fn createDraft(self: *Publisher) Error!Release {
        var endpoint_buffer: [512]u8 = undefined;
        const endpoint = std.fmt.bufPrint(
            &endpoint_buffer,
            "repos/{s}/releases",
            .{self.options.repository_name},
        ) catch return self.fail("repository name is too long", .{});
        const tag_field = try self.fieldAlloc("tag_name", self.metadata.tag);
        defer self.allocator.free(tag_field);
        const target_field = try self.fieldAlloc("target_commitish", self.options.commit);
        defer self.allocator.free(target_field);
        const name_field = try self.fieldAlloc("name", self.metadata.title);
        defer self.allocator.free(name_field);
        const body_field = try self.fieldAlloc("body", self.metadata.body);
        defer self.allocator.free(body_field);
        var result = try self.ghJson(&.{
            "api",
            "--method",
            "POST",
            endpoint,
            "-f",
            tag_field,
            "-f",
            target_field,
            "-f",
            name_field,
            "-f",
            body_field,
            "-F",
            "draft=true",
            "-F",
            "prerelease=true",
            "-F",
            "generate_release_notes=false",
            "-f",
            "make_latest=false",
        });
        defer result.deinit();
        const release = try self.parseRelease(result.value, .require_uploaded);
        if (!release.draft) return self.fail(
            "GitHub did not create release {s} as a draft",
            .{self.metadata.tag},
        );
        return release;
    }

    fn fetch(
        self: *Publisher,
        expected_draft: bool,
        asset_policy: AssetPolicy,
    ) Error!Release {
        var endpoint_buffer: [512]u8 = undefined;
        const endpoint = std.fmt.bufPrint(
            &endpoint_buffer,
            "repos/{s}/releases/{d}",
            .{ self.options.repository_name, self.release_id },
        ) catch return self.fail("release endpoint is too long", .{});
        var result = try self.ghJson(&.{ "api", endpoint });
        defer result.deinit();
        const release = try self.parseRelease(result.value, asset_policy);
        if (release.id != self.release_id) return self.fail(
            "GitHub returned release {d}, expected {d}",
            .{ release.id, self.release_id },
        );
        if (release.draft != expected_draft) return self.fail(
            "release {s} changed publication state unexpectedly",
            .{self.metadata.tag},
        );
        return release;
    }

    fn parseRelease(
        self: *Publisher,
        value: Value,
        asset_policy: AssetPolicy,
    ) Error!Release {
        if (value != .object) return self.fail("release response is not an object", .{});
        const object = &value.object;
        const id = try self.integerField(object, "id", "release id");
        if (id <= 0) return self.fail("release id is invalid", .{});
        const draft = try self.boolField(object, "draft", "release draft");
        const prerelease = try self.boolField(object, "prerelease", "release prerelease");
        if (!prerelease) return self.fail("release must be marked as a prerelease", .{});
        const tag_name = try self.stringField(object, "tag_name", "release tag");
        if (!std.mem.eql(u8, tag_name, self.metadata.tag)) {
            return self.fail("release tag does not match publication contract", .{});
        }
        const body = try self.stringField(object, "body", "release body");

        const assets_value = object.get("assets") orelse return self.fail(
            "release assets are missing",
            .{},
        );
        if (assets_value != .array) return self.fail(
            "release assets are not an array",
            .{},
        );
        const assets = self.allocator.alloc(
            RemoteAsset,
            assets_value.array.items.len,
        ) catch return error.OutOfMemory;
        var initialized: usize = 0;
        errdefer {
            for (assets[0..initialized]) |asset| {
                self.allocator.free(asset.name);
                if (asset.digest_text) |text| self.allocator.free(text);
            }
            self.allocator.free(assets);
        }
        for (assets_value.array.items, assets) |asset_value, *asset| {
            if (asset_value != .object) return self.fail("release asset is not an object", .{});
            const size = try self.integerField(&asset_value.object, "size", "release asset size");
            if (size < 0) return self.fail("release asset size is invalid", .{});
            const name = try self.stringField(&asset_value.object, "name", "release asset name");
            if (isSbOmOrSpdxPath(name)) {
                return self.fail("remote release contains prohibited SBOM/SPDX asset: {s}", .{name});
            }
            const digest_text = try self.optionalStringField(&asset_value.object, "digest", "release asset digest");
            const state = try self.stringField(&asset_value.object, "state", "release asset state");
            const parsed_state: AssetState = if (std.mem.eql(u8, state, "uploaded"))
                .uploaded
            else if (std.mem.eql(u8, state, "starter"))
                .starter
            else
                return self.fail("release asset {s} has unknown state {s}", .{ name, state });
            if (asset_policy == .require_uploaded and parsed_state != .uploaded) {
                return self.fail("release asset {s} is not fully uploaded", .{name});
            }
            const asset_id = try self.integerField(&asset_value.object, "id", "release asset id");
            if (asset_id <= 0) return self.fail("release asset id is invalid", .{});
            asset.* = .{
                .id = asset_id,
                .name = self.allocator.dupe(u8, name) catch return error.OutOfMemory,
                .size = @intCast(size),
                .digest_text = if (digest_text) |text|
                    self.allocator.dupe(u8, text) catch return error.OutOfMemory
                else
                    null,
                .state = parsed_state,
            };
            initialized += 1;
        }
        return .{
            .id = id,
            .draft = draft,
            .body = self.allocator.dupe(u8, body) catch return error.OutOfMemory,
            .assets = assets,
        };
    }

    fn revalidateLocal(self: *Publisher, asset: *const Asset) Error!void {
        const current = hashRegularNoSymlink(self.io, asset.path) catch |err|
            return self.fail("cannot revalidate {s}: {t}", .{ asset.name, err });
        if (!asset.identity.eql(current.identity) or
            asset.size != current.size or
            !std.mem.eql(u8, &asset.digest_hex, &current.hex))
        {
            return self.fail("local release asset changed after validation: {s}", .{asset.name});
        }
    }

    fn upload(self: *Publisher, asset: *const Asset) Error!void {
        var draft = try self.fetch(true, .allow_incomplete);
        defer draft.deinit(self.allocator);
        var same_name_count: usize = 0;
        var matching_remote: ?RemoteAsset = null;
        for (draft.assets) |remote| {
            if (!std.mem.eql(u8, remote.name, asset.name)) continue;
            same_name_count += 1;
            matching_remote = remote;
        }
        try self.revalidateLocal(asset);
        if (same_name_count == 1 and remoteMatchesLocal(matching_remote.?, asset)) return;
        if (same_name_count != 0) return self.fail(
            "draft asset {s} changed before upload",
            .{asset.name},
        );
        if (!safeUploadAssetName(asset.name)) return self.fail(
            "release asset name is not safe for upload URL: {s}",
            .{asset.name},
        );
        var endpoint_buffer: [1024]u8 = undefined;
        const endpoint = std.fmt.bufPrint(
            &endpoint_buffer,
            "https://uploads.github.com/repos/{s}/releases/{d}/assets?name={s}",
            .{ self.options.repository_name, self.release_id, asset.name },
        ) catch return self.fail("asset upload endpoint is too long", .{});
        const result = try self.gh(&.{
            "api",
            "--method",
            "POST",
            "-H",
            "Content-Type: application/octet-stream",
            "--input",
            asset.path,
            endpoint,
        });
        result.deinit(self.allocator);
    }

    fn deleteRemoteAsset(self: *Publisher, asset_id: i64) Error!void {
        var endpoint_buffer: [512]u8 = undefined;
        const endpoint = std.fmt.bufPrint(
            &endpoint_buffer,
            "repos/{s}/releases/assets/{d}",
            .{ self.options.repository_name, asset_id },
        ) catch return self.fail("asset endpoint is too long", .{});
        const result = try self.gh(&.{ "api", "--method", "DELETE", endpoint });
        result.deinit(self.allocator);
    }

    fn repairDraftAssets(self: *Publisher) Error!void {
        while (true) {
            var release = try self.fetch(true, .allow_incomplete);
            defer release.deinit(self.allocator);
            var delete_id: ?i64 = null;
            for (release.assets) |remote| {
                if (classifyRemoteAsset(self.assets, release.assets, remote) != null) {
                    delete_id = remote.id;
                    break;
                }
            }
            if (delete_id) |id| {
                try self.deleteRemoteAsset(id);
                continue;
            }
            return;
        }
    }

    fn validateRemoteAssets(self: *Publisher, release: *const Release) Error!void {
        if (release.assets.len != self.assets.len) return self.fail(
            "remote release has {d} assets, expected {d}",
            .{ release.assets.len, self.assets.len },
        );
        for (self.assets) |*local| {
            var match: ?RemoteAsset = null;
            for (release.assets) |remote| {
                if (!std.mem.eql(u8, local.name, remote.name)) continue;
                if (match != null) return self.fail(
                    "remote release has duplicate asset {s}",
                    .{local.name},
                );
                match = remote;
            }
            const remote = match orelse return self.fail(
                "remote release is missing asset {s}",
                .{local.name},
            );
            if (!remoteMatchesLocal(remote, local)) {
                return self.fail(
                    "remote release asset {s} does not match expected size or SHA-256 digest",
                    .{local.name},
                );
            }
            local.remote_id = remote.id;
        }
    }

    fn downloadAndVerify(self: *Publisher, asset: *const Asset) Error!void {
        if (asset.remote_id <= 0) return self.fail(
            "remote id for {s} was not validated",
            .{asset.name},
        );
        const remote_directory = std.fs.path.join(
            self.allocator,
            &.{ self.options.workspace, "remote" },
        ) catch return error.OutOfMemory;
        defer self.allocator.free(remote_directory);
        Dir.cwd().createDirPath(self.io, remote_directory) catch |err|
            return self.fail("cannot create release verification directory: {t}", .{err});
        const output_path = std.fs.path.join(
            self.allocator,
            &.{ remote_directory, asset.name },
        ) catch return error.OutOfMemory;
        defer self.allocator.free(output_path);
        var endpoint_buffer: [512]u8 = undefined;
        const endpoint = std.fmt.bufPrint(
            &endpoint_buffer,
            "repos/{s}/releases/assets/{d}",
            .{ self.options.repository_name, asset.remote_id },
        ) catch return self.fail("asset endpoint is too long", .{});

        var argv: std.ArrayList([]const u8) = .empty;
        defer argv.deinit(self.allocator);
        argv.appendSlice(self.allocator, &.{
            self.options.gh_executable,
            "api",
            "-H",
            "Accept: application/octet-stream",
            endpoint,
        }) catch return error.OutOfMemory;

        var environment = std.process.Environ.createMap(
            self.options.environment,
            self.allocator,
        ) catch return error.OutOfMemory;
        defer environment.deinit();

        var child = std.process.spawn(self.io, .{
            .argv = argv.items,
            .environ_map = &environment,
            .stdin = .ignore,
            .stdout = .pipe,
            .stderr = .pipe,
        }) catch |err| return self.fail("cannot execute GitHub CLI: {t}", .{err});
        var child_alive = true;
        defer if (child_alive) child.kill(self.io);

        var output = Dir.cwd().createFile(self.io, output_path, .{
            .truncate = true,
            .exclusive = false,
        }) catch |err| return self.fail("cannot create downloaded asset {s}: {t}", .{ output_path, err });
        defer output.close(self.io);

        var stdout_buffer: [64 * 1024]u8 = undefined;
        var stdout = child.stdout.?.readerStreaming(self.io, &stdout_buffer);
        var copy_buffer: [64 * 1024]u8 = undefined;
        while (true) {
            const count = stdout.interface.readSliceShort(&copy_buffer) catch |err|
                return self.fail("cannot download release asset: {t}", .{err});
            if (count == 0) break;
            output.writeStreamingAll(self.io, copy_buffer[0..count]) catch |err|
                return self.fail("cannot write downloaded release asset: {t}", .{err});
        }

        var stderr_buffer: [16 * 1024]u8 = undefined;
        var stderr = child.stderr.?.readerStreaming(self.io, &stderr_buffer);
        const stderr_text = stderr.interface.allocRemaining(
            self.allocator,
            .limited(stderr_buffer.len),
        ) catch |err| return self.fail("cannot read GitHub CLI diagnostics: {t}", .{err});
        defer self.allocator.free(stderr_text);

        const term = child.wait(self.io) catch |err|
            return self.fail("cannot wait for GitHub CLI: {t}", .{err});
        child_alive = false;
        const succeeded = switch (term) {
            .exited => |code| code == 0,
            else => false,
        };
        if (!succeeded) return self.fail(
            "GitHub CLI download failed: {s}",
            .{std.mem.trim(u8, stderr_text, " \t\r\n")},
        );

        const downloaded = hashRegularNoSymlink(self.io, output_path) catch |err|
            return self.fail("cannot hash downloaded asset {s}: {t}", .{ asset.name, err });
        if (downloaded.size != asset.size or
            !std.mem.eql(u8, &downloaded.hex, &asset.digest_hex))
        {
            return self.fail("downloaded release asset does not match local revision: {s}", .{asset.name});
        }
    }

    fn publishDraft(self: *Publisher) Error!void {
        var draft = try self.fetch(true, .require_uploaded);
        defer draft.deinit(self.allocator);
        try self.validateRemoteAssets(&draft);
        for (self.assets) |*asset| try self.revalidateLocal(asset);

        var endpoint_buffer: [512]u8 = undefined;
        const endpoint = std.fmt.bufPrint(
            &endpoint_buffer,
            "repos/{s}/releases/{d}",
            .{ self.options.repository_name, self.release_id },
        ) catch return self.fail("release endpoint is too long", .{});
        const tag_field = try self.fieldAlloc("tag_name", self.metadata.tag);
        defer self.allocator.free(tag_field);
        const target_field = try self.fieldAlloc("target_commitish", self.options.commit);
        defer self.allocator.free(target_field);
        const name_field = try self.fieldAlloc("name", self.metadata.title);
        defer self.allocator.free(name_field);
        const body_field = try self.fieldAlloc("body", self.metadata.body);
        defer self.allocator.free(body_field);
        try self.verifyTag();
        var result = try self.ghJson(&.{
            "api",
            "--method",
            "PATCH",
            endpoint,
            "-f",
            tag_field,
            "-f",
            target_field,
            "-f",
            name_field,
            "-f",
            body_field,
            "-F",
            "draft=false",
            "-F",
            "prerelease=true",
            "-f",
            "make_latest=false",
        });
        defer result.deinit();
        var published = try self.parseRelease(result.value, .require_uploaded);
        defer published.deinit(self.allocator);
        if (published.draft) return self.fail(
            "GitHub did not publish release {s}",
            .{self.metadata.tag},
        );
        try self.validateRemoteAssets(&published);
    }

    fn writeSummary(self: *Publisher) Error!void {
        const path = self.options.summary_path orelse return;
        var file = Dir.cwd().openFile(self.io, path, .{
            .mode = .write_only,
        }) catch |err| return self.fail("cannot open GitHub step summary: {t}", .{err});
        defer file.close(self.io);
        const size = file.stat(self.io) catch |err| return self.fail(
            "cannot stat GitHub step summary: {t}",
            .{err},
        );
        var buffer: [4096]u8 = undefined;
        const text = std.fmt.bufPrint(
            &buffer,
            "### curl Zig-port release published\n\n- Release: https://github.com/{s}/releases/tag/{s}\n- Commit: `{s}`\n- Assets: {d} allowlisted platform archives (zero SBOM/SPDX assets), independently downloaded and verified\n",
            .{
                self.options.repository_name,
                self.metadata.tag,
                self.options.commit,
                self.assets.len,
            },
        ) catch return self.fail("release summary is too long", .{});
        file.writePositionalAll(self.io, text, size.size) catch |err|
            return self.fail("cannot write GitHub step summary: {t}", .{err});
    }

    fn fieldAlloc(self: *Publisher, name: []const u8, value: []const u8) Error![]u8 {
        return std.fmt.allocPrint(self.allocator, "{s}={s}", .{ name, value }) catch error.OutOfMemory;
    }

    fn objectField(
        self: *Publisher,
        value: *const Value,
        name: []const u8,
        label: []const u8,
    ) Error!*const std.json.ObjectMap {
        if (value.* != .object) return self.fail("{s} parent is not an object", .{label});
        const field = value.object.getPtr(name) orelse return self.fail("{s} is missing", .{label});
        if (field.* != .object) return self.fail("{s} is not an object", .{label});
        return &field.object;
    }

    fn stringField(
        self: *Publisher,
        object: *const std.json.ObjectMap,
        name: []const u8,
        label: []const u8,
    ) Error![]const u8 {
        const value = object.get(name) orelse return self.fail("{s} is missing", .{label});
        if (value != .string) return self.fail("{s} is not a string", .{label});
        return value.string;
    }

    fn optionalStringField(
        self: *Publisher,
        object: *const std.json.ObjectMap,
        name: []const u8,
        label: []const u8,
    ) Error!?[]const u8 {
        const value = object.get(name) orelse return null;
        if (value == .null) return null;
        if (value != .string) return self.fail("{s} is not a string", .{label});
        return value.string;
    }

    fn integerField(
        self: *Publisher,
        object: *const std.json.ObjectMap,
        name: []const u8,
        label: []const u8,
    ) Error!i64 {
        const value = object.get(name) orelse return self.fail("{s} is missing", .{label});
        if (value != .integer) return self.fail("{s} is not an integer", .{label});
        return value.integer;
    }

    fn boolField(
        self: *Publisher,
        object: *const std.json.ObjectMap,
        name: []const u8,
        label: []const u8,
    ) Error!bool {
        const value = object.get(name) orelse return self.fail("{s} is missing", .{label});
        if (value != .bool) return self.fail("{s} is not a boolean", .{label});
        return value.bool;
    }
};

fn remoteMatchesLocal(remote: RemoteAsset, local: *const Asset) bool {
    if (remote.state != .uploaded or remote.size != local.size) return false;
    const remote_digest = remote.digest_text orelse return false;
    if (!std.mem.startsWith(u8, remote_digest, "sha256:")) return false;
    return std.mem.eql(u8, remote_digest["sha256:".len..], &local.digest_hex);
}

fn findAsset(assets: []const Asset, name: []const u8) ?usize {
    for (assets, 0..) |asset, index| {
        if (std.mem.eql(u8, asset.name, name)) return index;
    }
    return null;
}

fn classifyRemoteAsset(
    local_assets: []const Asset,
    remote_assets: []const RemoteAsset,
    remote: RemoteAsset,
) ?DeleteReason {
    const local_index = findAsset(local_assets, remote.name) orelse return .unexpected;
    var same_name_count: usize = 0;
    var exact_same_name_count: usize = 0;
    for (remote_assets) |candidate| {
        if (!std.mem.eql(u8, candidate.name, remote.name)) continue;
        same_name_count += 1;
        if (remoteMatchesLocal(candidate, &local_assets[local_index])) {
            exact_same_name_count += 1;
        }
    }
    const local = &local_assets[local_index];
    if (same_name_count > 1 and remoteMatchesLocal(remote, local)) {
        if (exact_same_name_count == 1) return null;
        return .duplicate;
    }
    if (remote.state != .uploaded) return .incomplete;
    if (remote.size != local.size) return .wrong_size;
    const remote_digest = remote.digest_text orelse return .wrong_digest;
    if (!std.mem.startsWith(u8, remote_digest, "sha256:") or
        !std.mem.eql(u8, remote_digest["sha256:".len..], &local.digest_hex))
    {
        return .wrong_digest;
    }
    return null;
}

pub fn safeUploadAssetName(name: []const u8) bool {
    if (name.len == 0) return false;
    for (name) |character| switch (character) {
        'a'...'z', 'A'...'Z', '0'...'9', '.', '_', '-' => {},
        else => return false,
    };
    return true;
}

pub fn publish(
    allocator: Allocator,
    io: Io,
    options: PublishOptions,
    diagnostic: *Diagnostic,
) Error!void {
    if (options.repository_name.len == 0 or
        std.mem.indexOfScalar(u8, options.repository_name, '/') == null)
    {
        return diagnostic.fail(
            error.Failed,
            "release repository must be in OWNER/REPO format",
            .{},
        );
    }
    if (!validCommit(options.commit)) return diagnostic.fail(
        error.Failed,
        "workflow commit must be a lowercase 40-character SHA",
        .{},
    );
    try validateVersionTag(options.version, options.tag, diagnostic);

    const assets = try verifyAssetsDirectory(
        allocator,
        io,
        options.assets_directory,
        options.version,
        diagnostic,
    );
    defer freeAssets(allocator, assets);

    const title = std.fmt.allocPrint(
        allocator,
        "curl {s} (Zig port)",
        .{options.version},
    ) catch return error.OutOfMemory;
    defer allocator.free(title);

    const remote_directory = std.fs.path.join(
        allocator,
        &.{ options.workspace, "remote" },
    ) catch return error.OutOfMemory;
    defer allocator.free(remote_directory);
    Dir.cwd().deleteTree(io, remote_directory) catch |err| return diagnostic.fail(
        error.Failed,
        "cannot reset release workspace: {t}",
        .{err},
    );
    Dir.cwd().createDirPath(io, remote_directory) catch |err| return diagnostic.fail(
        error.Failed,
        "cannot create release workspace: {t}",
        .{err},
    );

    var publisher: Publisher = .{
        .allocator = allocator,
        .io = io,
        .diagnostic = diagnostic,
        .options = options,
        .metadata = .{
            .tag = options.tag,
            .commit = options.commit,
            .title = title,
            .body = "",
            .prerelease = true,
        },
        .assets = assets,
    };
    defer if (publisher.previous_tag) |tag| allocator.free(tag);

    try publisher.verifyTag();
    const discovered = try publisher.discover();
    const notes_body = try renderReleaseNotes(
        allocator,
        options.repository_name,
        options.tag,
        options.version,
        publisher.previous_tag,
        diagnostic,
    );
    defer allocator.free(notes_body);
    publisher.metadata.body = notes_body;

    var release: Release = if (discovered) |existing| existing else try publisher.createDraft();
    defer release.deinit(allocator);
    publisher.release_id = release.id;
    if (!release.draft) return publisher.fail(
        "release {s} is not a draft",
        .{options.tag},
    );

    try publisher.repairDraftAssets();
    for (assets) |*asset| try publisher.upload(asset);
    var uploaded = try publisher.fetch(true, .require_uploaded);
    defer uploaded.deinit(allocator);
    try publisher.validateRemoteAssets(&uploaded);
    for (assets) |*asset| try publisher.downloadAndVerify(asset);
    try publisher.publishDraft();
    try publisher.writeSummary();
}

pub fn main(init: std.process.Init) !void {
    const allocator = init.gpa;
    const io = init.io;
    const argv = try init.minimal.args.toSlice(init.arena.allocator());
    var stdout_buffer: [4096]u8 = undefined;
    var stdout_file: File.Writer = .init(.stdout(), io, &stdout_buffer);
    const stdout = &stdout_file.interface;
    var stderr_buffer: [4096]u8 = undefined;
    var stderr_file: File.Writer = .init(.stderr(), io, &stderr_buffer);
    const stderr = &stderr_file.interface;
    var diagnostic: Diagnostic = .{};

    run(
        allocator,
        io,
        init.environ_map.get("CURL_RELEASE_GH") orelse "gh",
        init.minimal.environ,
        stdout,
        argv[1..],
        &diagnostic,
    ) catch |err| switch (err) {
        error.Usage => {
            try stderr.writeAll(usage);
            try stderr.flush();
            std.process.exit(2);
        },
        error.Failed => {
            try stderr.print("{s}\n", .{diagnostic.message()});
            try stderr.flush();
            std.process.exit(1);
        },
        else => return err,
    };
    try stdout.flush();
}

pub fn run(
    allocator: Allocator,
    io: Io,
    gh_executable: []const u8,
    environment: std.process.Environ,
    out: *std.Io.Writer,
    argv: []const []const u8,
    diagnostic: *Diagnostic,
) Error!void {
    if (argv.len == 0) return error.Usage;
    const options = try Options.parse(argv[1..]);

    if (std.mem.eql(u8, argv[0], "verify-version")) {
        try options.only(&.{ "--tag", "--manifest", "--github-output" });
        const tag = try options.require("--tag");
        const version = try versionFromTag(tag, diagnostic);
        if (options.get("--manifest")) |manifest_path| {
            try validateManifestVersionFile(allocator, io, manifest_path, version, diagnostic);
        }
        if (options.get("--github-output")) |output_path| {
            var output = Dir.cwd().openFile(io, output_path, .{
                .mode = .write_only,
            }) catch |err| return diagnostic.fail(
                error.Failed,
                "cannot open github-output {s}: {t}",
                .{ output_path, err },
            );
            defer output.close(io);
            const stat = output.stat(io) catch |err| return diagnostic.fail(
                error.Failed,
                "cannot stat github-output {s}: {t}",
                .{ output_path, err },
            );
            var buffer: [512]u8 = undefined;
            const text = std.fmt.bufPrint(
                &buffer,
                "version={s}\nprerelease=true\n",
                .{version},
            ) catch return diagnostic.fail(error.Failed, "github-output text is too long", .{});
            output.writePositionalAll(io, text, stat.size) catch |err| return diagnostic.fail(
                error.Failed,
                "cannot write github-output {s}: {t}",
                .{ output_path, err },
            );
        } else {
            out.print("{s}\n", .{version}) catch return diagnostic.fail(
                error.Failed,
                "cannot write verified version",
                .{},
            );
        }
        return;
    }

    if (std.mem.eql(u8, argv[0], "package")) {
        try options.only(&.{
            "--version",
            "--platform",
            "--executable",
            "--copying",
            "--output-dir",
        });
        return packageArchive(
            allocator,
            io,
            try options.require("--version"),
            try options.require("--platform"),
            try options.require("--executable"),
            try options.require("--copying"),
            try options.require("--output-dir"),
            diagnostic,
        );
    }

    if (std.mem.eql(u8, argv[0], "inspect-archive")) {
        try options.only(&.{ "--archive", "--version", "--platform" });
        return inspectArchive(
            allocator,
            io,
            try options.require("--archive"),
            try options.require("--version"),
            try options.require("--platform"),
            diagnostic,
        );
    }

    if (std.mem.eql(u8, argv[0], "verify-package")) {
        try options.only(&.{ "--archive", "--version", "--platform", "--run-smoke" });
        const run_smoke_str = options.get("--run-smoke") orelse "true";
        const run_smoke = if (std.mem.eql(u8, run_smoke_str, "true"))
            true
        else if (std.mem.eql(u8, run_smoke_str, "false"))
            false
        else
            return diagnostic.fail(error.Failed, "invalid --run-smoke value: {s}", .{run_smoke_str});
        return verifyPackage(
            allocator,
            io,
            try options.require("--archive"),
            try options.require("--version"),
            try options.require("--platform"),
            run_smoke,
            diagnostic,
        );
    }

    if (std.mem.eql(u8, argv[0], "generate-checksums")) {
        try options.only(&.{ "--assets-directory", "--version", "--output" });
        return generateChecksums(
            allocator,
            io,
            try options.require("--assets-directory"),
            try options.require("--version"),
            options.get("--output"),
            diagnostic,
        );
    }

    if (std.mem.eql(u8, argv[0], "verify-assets")) {
        try options.only(&.{ "--assets-directory", "--version" });
        const assets = try verifyAssetsDirectory(
            allocator,
            io,
            try options.require("--assets-directory"),
            try options.require("--version"),
            diagnostic,
        );
        defer freeAssets(allocator, assets);
        out.print("verified {d} release assets\n", .{assets.len}) catch return diagnostic.fail(
            error.Failed,
            "cannot write verification summary",
            .{},
        );
        return;
    }

    if (std.mem.eql(u8, argv[0], "render-notes")) {
        try options.only(&.{
            "--repository",
            "--tag",
            "--version",
            "--previous-tag",
            "--output",
        });
        const notes = try renderReleaseNotes(
            allocator,
            try options.require("--repository"),
            try options.require("--tag"),
            try options.require("--version"),
            options.get("--previous-tag"),
            diagnostic,
        );
        defer allocator.free(notes);
        if (options.get("--output")) |output_path| {
            writeAtomic(io, output_path, notes) catch |err| return diagnostic.fail(
                error.Failed,
                "cannot write release notes to {s}: {t}",
                .{ output_path, err },
            );
        } else {
            out.writeAll(notes) catch return diagnostic.fail(
                error.Failed,
                "cannot write release notes",
                .{},
            );
        }
        return;
    }

    if (std.mem.eql(u8, argv[0], "publish")) {
        try options.only(&.{
            "--repository",
            "--tag",
            "--version",
            "--commit",
            "--assets-directory",
            "--workspace",
            "--github-step-summary",
        });
        return publish(allocator, io, .{
            .repository_name = try options.require("--repository"),
            .tag = try options.require("--tag"),
            .version = try options.require("--version"),
            .commit = try options.require("--commit"),
            .assets_directory = try options.require("--assets-directory"),
            .workspace = try options.require("--workspace"),
            .gh_executable = gh_executable,
            .summary_path = options.get("--github-step-summary"),
            .environment = environment,
        }, diagnostic);
    }

    return error.Usage;
}

// ============================================================================
// Unit & Contract Tests
// ============================================================================

test "version contract accepts fork prereleases and rejects dev or stable upstream versions" {
    var diagnostic: Diagnostic = .{};

    try std.testing.expectEqualStrings(
        "8.23.0-zig.1",
        try versionFromTag("v8.23.0-zig.1", &diagnostic),
    );
    try std.testing.expectEqualStrings(
        "8.23.0-rc.1",
        try versionFromTag("v8.23.0-rc.1", &diagnostic),
    );
    try validateVersionTag("8.23.0-zig.1", "v8.23.0-zig.1", &diagnostic);

    // Reject missing 'v' prefix
    try std.testing.expectError(
        error.Failed,
        versionFromTag("8.23.0-zig.1", &diagnostic),
    );
    // Reject bare upstream version without prerelease suffix
    try std.testing.expectError(
        error.Failed,
        versionFromTag("v8.23.0", &diagnostic),
    );
    // Reject -dev / -DEV
    try std.testing.expectError(
        error.Failed,
        versionFromTag("v8.23.0-dev", &diagnostic),
    );
    try std.testing.expectError(
        error.Failed,
        versionFromTag("v8.23.0-DEV", &diagnostic),
    );
    // Reject +build metadata
    try std.testing.expectError(
        error.Failed,
        versionFromTag("v8.23.0-zig.1+20261021", &diagnostic),
    );
}

test "extractZonVersion and manifest validation" {
    const sample =
        \\.{
        \\    .name = .curl,
        \\    .version = "8.23.0-zig.1",
        \\    .minimum_zig_version = "0.17.0",
        \\}
    ;
    try std.testing.expectEqualStrings("8.23.0-zig.1", extractZonVersion(sample).?);
}

test "SBOM, SPDX, and libcurl dev path detectors reject prohibited entries" {
    try std.testing.expect(isSbOmOrSpdxPath("curl-8.23.0-zig.1-linux-musl-x64.sbom.json"));
    try std.testing.expect(isSbOmOrSpdxPath("curl-8.23.0-zig.1.spdx.json"));
    try std.testing.expect(isSbOmOrSpdxPath("SBOM.txt"));
    try std.testing.expect(!isSbOmOrSpdxPath("COPYING"));
    try std.testing.expect(!isSbOmOrSpdxPath("curl-8.23.0-zig.1-linux-musl-x64.tar.gz"));

    try std.testing.expect(isLibcurlDevPath("include/curl/curl.h"));
    try std.testing.expect(isLibcurlDevPath("lib/libcurl.a"));
    try std.testing.expect(isLibcurlDevPath("libcurl.so"));
    try std.testing.expect(isLibcurlDevPath("libcurl.pc"));
    try std.testing.expect(!isLibcurlDevPath("curl"));
    try std.testing.expect(!isLibcurlDevPath("curl.exe"));
    try std.testing.expect(!isLibcurlDevPath("COPYING"));
    try std.testing.expect(!isLibcurlDevPath("README.md"));
}

test "inspectArchiveListText validates exact layout and rejects SBOM, SPDX, and dev files" {
    var diagnostic: Diagnostic = .{};
    const valid_unix =
        \\curl
        \\COPYING
        \\README.md
        \\
    ;
    try inspectArchiveListText(valid_unix, "8.23.0-zig.1", "linux-musl-x64", &diagnostic);

    const valid_win =
        \\curl.exe
        \\COPYING
        \\README.md
        \\
    ;
    try inspectArchiveListText(valid_win, "8.23.0-zig.1", "windows-x64", &diagnostic);

    // Reject nested directory entries
    const nested =
        \\curl-8.23.0-zig.1-linux-musl-x64/bin/curl
        \\curl-8.23.0-zig.1-linux-musl-x64/COPYING
        \\curl-8.23.0-zig.1-linux-musl-x64/README.md
        \\
    ;
    try std.testing.expectError(
        error.Failed,
        inspectArchiveListText(nested, "8.23.0-zig.1", "linux-musl-x64", &diagnostic),
    );

    // Reject SBOM inside archive
    const with_sbom = valid_unix ++ "curl.spdx.json\n";
    try std.testing.expectError(
        error.Failed,
        inspectArchiveListText(with_sbom, "8.23.0-zig.1", "linux-musl-x64", &diagnostic),
    );

    // Reject libcurl dev header inside archive
    const with_header = valid_unix ++ "include/curl/curl.h\n";
    try std.testing.expectError(
        error.Failed,
        inspectArchiveListText(with_header, "8.23.0-zig.1", "linux-musl-x64", &diagnostic),
    );

    // Reject second executable
    const with_extra_bin = valid_unix ++ "curl-config\n";
    try std.testing.expectError(
        error.Failed,
        inspectArchiveListText(with_extra_bin, "8.23.0-zig.1", "linux-musl-x64", &diagnostic),
    );
}

test "isSafeArchiveEntryPath rejects traversal, absolute, drive, dot, NUL, and control chars" {
    // Reject traversal, absolute, Windows drive, dot components, NUL bytes, and control chars
    const unsafe_paths = [_][]const u8{
        "",
        "/",
        "\\",
        "../",
        "..",
        ".",
        "./",
        "a/../../b",
        "/etc/passwd",
        "\\Windows\\System32\\cmd.exe",
        "C:\\foo",
        "C:/foo",
        "d:bar",
        "bin/curl\x00.txt",
        "curl-8.23.0-zig.1-linux-musl-x64/bin/curl\x00.txt",
        "curl-8.23.0-zig.1-linux-musl-x64/../etc/passwd",
        "curl-8.23.0-zig.1-linux-musl-x64/./bin/curl",
        "curl-8.23.0-zig.1-linux-musl-x64/bin//curl",
        "curl-8.23.0-zig.1-linux-musl-x64//",
        "curl-8.23.0-zig.1-linux-musl-x64/bin/curl\x01",
        "curl-8.23.0-zig.1-linux-musl-x64/bin/curl\x1f",
        "curl-8.23.0-zig.1-linux-musl-x64/bin/curl\x7f",
        "curl-8.23.0-zig.1-linux-musl-x64/bin\\curl",
    };
    for (unsafe_paths) |p| {
        try std.testing.expect(!isSafeArchiveEntryPath(p));
    }

    // Accept valid archive relative paths
    const valid_paths = [_][]const u8{
        "curl",
        "curl.exe",
        "COPYING",
        "README.md",
        "curl-8.23.0-zig.1-linux-musl-x64",
        "curl-8.23.0-zig.1-linux-musl-x64/",
        "curl-8.23.0-zig.1-linux-musl-x64/bin",
        "curl-8.23.0-zig.1-linux-musl-x64/bin/",
        "curl-8.23.0-zig.1-linux-musl-x64/bin/curl",
        "curl-8.23.0-zig.1-windows-x64/bin/curl.exe",
        "curl-8.23.0-zig.1-linux-musl-x64/COPYING",
        "curl-8.23.0-zig.1-linux-musl-x64/README.md",
    };
    for (valid_paths) |p| {
        try std.testing.expect(isSafeArchiveEntryPath(p));
    }

    // Ensure inspectArchiveListText deterministically fails on unsafe tar entries
    var diagnostic: Diagnostic = .{};
    const base_listing =
        \\curl
        \\COPYING
        \\README.md
        \\
    ;
    const unsafe_listings = [_][]const u8{
        base_listing ++ "../\n",
        base_listing ++ "a/../../b\n",
        base_listing ++ "/etc/passwd\n",
        base_listing ++ "C:\\foo\n",
        base_listing ++ "curl\x00.txt\n",
        base_listing ++ "./COPYING\n",
        base_listing ++ "../COPYING\n",
        base_listing ++ "curl\x7f\n",
    };
    for (unsafe_listings) |listing| {
        diagnostic = .{};
        try std.testing.expectError(
            error.Failed,
            inspectArchiveListText(listing, "8.23.0-zig.1", "linux-musl-x64", &diagnostic),
        );
        try std.testing.expect(std.mem.indexOf(u8, diagnostic.message(), "unsafe path entry") != null);
    }
}

test "release platform zig build args default to ReleaseSafe optimize mode and full bundled backends" {
    const allocator = std.testing.allocator;
    try std.testing.expectEqual(std.builtin.OptimizeMode.ReleaseSafe, default_release_optimize_mode);
    try std.testing.expectEqualStrings("-Doptimize=ReleaseSafe", default_release_optimize_flag);

    for (platforms) |platform| {
        try std.testing.expectEqual(std.builtin.OptimizeMode.ReleaseSafe, platform.optimize_mode);
        const argv = try platform.zigBuildArgv(allocator);
        defer Platform.freeZigBuildArgv(allocator, argv);

        try std.testing.expectEqual(@as(usize, 20), argv.len);
        try std.testing.expectEqualStrings("zig", argv[0]);
        try std.testing.expectEqualStrings("build", argv[1]);
        try std.testing.expectEqualStrings("-Doptimize=ReleaseSafe", argv[3]);
        try std.testing.expectEqualStrings("-Dbundled=true", argv[4]);
    }

    const linux_x64 = findPlatform("linux-musl-x64").?;
    const linux_argv = try linux_x64.zigBuildArgv(allocator);
    defer Platform.freeZigBuildArgv(allocator, linux_argv);
    const expected_linux = [_][]const u8{
        "zig",
        "build",
        "-Dtarget=x86_64-linux-musl",
        "-Doptimize=ReleaseSafe",
        "-Dbundled=true",
        "-Dssl=openssl",
        "-Dapple-sectrust=false",
        "-Dzstd=true",
        "-Dzlib=true",
        "-Dbrotli=true",
        "-Dpsl=true",
        "-Didn=libidn2",
        "-Dnghttp2=true",
        "-Dares=true",
        "-Dhttpsrr=true",
        "-Dquic=ngtcp2",
        "-Dssh=libssh2",
        "-Dldap=openldap",
        "-Dgssapi=true",
        "-Dsspi=false",
    };
    for (expected_linux, linux_argv) |exp, actual| {
        try std.testing.expectEqualStrings(exp, actual);
    }

    const macos_arm64 = findPlatform("macos-arm64").?;
    const macos_argv = try macos_arm64.zigBuildArgv(allocator);
    defer Platform.freeZigBuildArgv(allocator, macos_argv);
    const expected_macos = [_][]const u8{
        "zig",
        "build",
        "-Dtarget=aarch64-macos",
        "-Doptimize=ReleaseSafe",
        "-Dbundled=true",
        "-Dssl=openssl",
        "-Dapple-sectrust=true",
        "-Dzstd=true",
        "-Dzlib=true",
        "-Dbrotli=true",
        "-Dpsl=true",
        "-Didn=libidn2",
        "-Dnghttp2=true",
        "-Dares=true",
        "-Dhttpsrr=true",
        "-Dquic=ngtcp2",
        "-Dssh=libssh2",
        "-Dldap=openldap",
        "-Dgssapi=true",
        "-Dsspi=false",
    };
    for (expected_macos, macos_argv) |exp, actual| {
        try std.testing.expectEqualStrings(exp, actual);
    }

    const windows_x64 = findPlatform("windows-x64").?;
    const windows_argv = try windows_x64.zigBuildArgv(allocator);
    defer Platform.freeZigBuildArgv(allocator, windows_argv);
    const expected_windows = [_][]const u8{
        "zig",
        "build",
        "-Dtarget=x86_64-windows-gnu",
        "-Doptimize=ReleaseSafe",
        "-Dbundled=true",
        "-Dssl=schannel",
        "-Dapple-sectrust=false",
        "-Dzstd=true",
        "-Dzlib=true",
        "-Dbrotli=true",
        "-Dpsl=true",
        "-Didn=winidn",
        "-Dnghttp2=true",
        "-Dares=true",
        "-Dhttpsrr=true",
        "-Dquic=ngtcp2",
        "-Dssh=libssh2",
        "-Dldap=winldap",
        "-Dgssapi=false",
        "-Dsspi=true",
    };
    for (expected_windows, windows_argv) |exp, actual| {
        try std.testing.expectEqualStrings(exp, actual);
    }
}

test "verifyVersionOutputProtocolsAndFeatures validates all 25 protocols and platform features" {
    var diagnostic: Diagnostic = .{};

    const all_protocols_line = "Protocols: dict file ftp ftps gopher gophers http https imap imaps ldap ldaps mqtt mqtts pop3 pop3s rtsp scp sftp smtp smtps telnet tftp ws wss";
    const common_features = "alt-svc asyn-rr AsynchDNS brotli HSTS HTTP2 HTTP3 HTTPS-proxy HTTPSIG HTTPSRR IDN IPv6 Kerberos Largefile libz proxy-HTTP3 PSL SPNEGO SSL threadsafe UnixSockets zstd";

    const valid_linux =
        "curl 8.23.0-zig.1 (x86_64-unknown-linux-musl) libcurl/8.23.0-zig.1\n" ++
        all_protocols_line ++ "\n" ++
        "Features: " ++ common_features ++ " GSS-API\n";
    try verifyVersionOutputProtocolsAndFeatures(valid_linux, "linux-musl-x64", &diagnostic);
    try verifyVersionOutputProtocolsAndFeatures(valid_linux, "linux-musl-arm64", &diagnostic);

    const valid_macos =
        "curl 8.23.0-zig.1 (aarch64-apple-darwin) libcurl/8.23.0-zig.1\n" ++
        all_protocols_line ++ "\n" ++
        "Features: " ++ common_features ++ " AppleSecTrust GSS-API\n";
    try verifyVersionOutputProtocolsAndFeatures(valid_macos, "macos-x64", &diagnostic);
    try verifyVersionOutputProtocolsAndFeatures(valid_macos, "macos-arm64", &diagnostic);

    const valid_windows =
        "curl 8.23.0-zig.1 (x86_64-pc-windows-gnu) libcurl/8.23.0-zig.1\n" ++
        all_protocols_line ++ "\n" ++
        "Features: " ++ common_features ++ " SSPI Unicode\n";
    try verifyVersionOutputProtocolsAndFeatures(valid_windows, "windows-x64", &diagnostic);
    try verifyVersionOutputProtocolsAndFeatures(valid_windows, "windows-arm64", &diagnostic);

    // Reject macOS output missing AppleSecTrust
    diagnostic = .{};
    try std.testing.expectError(
        error.Failed,
        verifyVersionOutputProtocolsAndFeatures(valid_linux, "macos-arm64", &diagnostic),
    );
    try std.testing.expect(std.mem.indexOf(u8, diagnostic.message(), "missing feature 'AppleSecTrust'") != null);

    // Reject Windows output missing SSPI or Unicode
    diagnostic = .{};
    try std.testing.expectError(
        error.Failed,
        verifyVersionOutputProtocolsAndFeatures(valid_linux, "windows-x64", &diagnostic),
    );
    try std.testing.expect(std.mem.indexOf(u8, diagnostic.message(), "missing feature 'SSPI'") != null);

    // Reject output missing each required protocol (e.g. https, ftps, scp, sftp, ldap, ldaps)
    const tested_missing_protocols = [_][]const u8{
        "https",
        "ftps",
        "scp",
        "sftp",
        "ldap",
        "ldaps",
        "mqtts",
        "wss",
    };
    for (tested_missing_protocols) |missing_proto| {
        var proto_buf: std.ArrayList(u8) = .empty;
        defer proto_buf.deinit(std.testing.allocator);
        try proto_buf.appendSlice(std.testing.allocator, "curl 8.23.0-zig.1 libcurl/8.23.0-zig.1\nProtocols:");
        for (expected_release_protocols) |p| {
            if (std.mem.eql(u8, p, missing_proto)) continue;
            try proto_buf.append(std.testing.allocator, ' ');
            try proto_buf.appendSlice(std.testing.allocator, p);
        }
        try proto_buf.appendSlice(std.testing.allocator, "\nFeatures: " ++ common_features ++ " GSS-API\n");

        diagnostic = .{};
        try std.testing.expectError(
            error.Failed,
            verifyVersionOutputProtocolsAndFeatures(proto_buf.items, "linux-musl-x64", &diagnostic),
        );
        try std.testing.expect(std.mem.indexOf(u8, diagnostic.message(), missing_proto) != null);
    }

    // Reject output missing each required feature (e.g. SSL, HTTP2, HTTP3, libz, brotli, zstd, IDN, PSL)
    const tested_missing_features = [_][]const u8{
        "SSL",
        "HTTP2",
        "HTTP3",
        "libz",
        "brotli",
        "zstd",
        "IDN",
        "PSL",
        "HTTPSRR",
        "AsynchDNS",
    };
    for (tested_missing_features) |missing_feat| {
        var feat_buf: std.ArrayList(u8) = .empty;
        defer feat_buf.deinit(std.testing.allocator);
        try feat_buf.appendSlice(std.testing.allocator, "curl 8.23.0-zig.1 libcurl/8.23.0-zig.1\n" ++ all_protocols_line ++ "\nFeatures: GSS-API");
        for (expected_common_release_features) |f| {
            if (std.mem.eql(u8, f, missing_feat)) continue;
            try feat_buf.append(std.testing.allocator, ' ');
            try feat_buf.appendSlice(std.testing.allocator, f);
        }
        try feat_buf.append(std.testing.allocator, '\n');

        diagnostic = .{};
        try std.testing.expectError(
            error.Failed,
            verifyVersionOutputProtocolsAndFeatures(feat_buf.items, "linux-musl-x64", &diagnostic),
        );
        try std.testing.expect(std.mem.indexOf(u8, diagnostic.message(), missing_feat) != null);
    }
}

test "end-to-end packaging, allowlist verification, and SBOM/sidecar rejection" {
    const allocator = std.testing.allocator;
    const io = std.testing.io;
    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();

    const root = try tmp.dir.realPathFileAlloc(io, ".", allocator);
    defer allocator.free(root);

    const fake_unix_exe = try std.fs.path.join(allocator, &.{ root, "fake-curl" });
    defer allocator.free(fake_unix_exe);
    const fake_win_exe = try std.fs.path.join(allocator, &.{ root, "fake-curl.exe" });
    defer allocator.free(fake_win_exe);
    const fake_copying = try std.fs.path.join(allocator, &.{ root, "COPYING" });
    defer allocator.free(fake_copying);
    const assets_dir = try std.fs.path.join(allocator, &.{ root, "assets" });
    defer allocator.free(assets_dir);

    try writeAtomic(io, fake_unix_exe, "#!/bin/sh\necho 'curl 8.23.0-zig.1'\n");
    try writeAtomic(io, fake_win_exe, "MZ-fake-windows-curl-binary");
    try writeAtomic(io, fake_copying, "Copyright (C) Daniel Stenberg\nSPDX-License-Identifier: curl\n");

    const version = "8.23.0-zig.1";
    var diagnostic: Diagnostic = .{};

    for (platforms) |platform| {
        const exe_src = if (std.mem.endsWith(u8, platform.executable, ".exe"))
            fake_win_exe
        else
            fake_unix_exe;
        try packageArchive(
            allocator,
            io,
            version,
            platform.suffix,
            exe_src,
            fake_copying,
            assets_dir,
            &diagnostic,
        );
    }

    // Verify the strict 6-archive allowlist
    const assets = try verifyAssetsDirectory(allocator, io, assets_dir, version, &diagnostic);
    defer freeAssets(allocator, assets);
    try std.testing.expectEqual(@as(usize, 6), assets.len);

    // Adding an SBOM file in the assets directory must fail closed
    const sbom_path = try std.fs.path.join(
        allocator,
        &.{ assets_dir, "curl-8.23.0-zig.1-linux-musl-x64.sbom.spdx.json" },
    );
    defer allocator.free(sbom_path);
    try writeAtomic(io, sbom_path, "{}");
    try std.testing.expectError(
        error.Failed,
        verifyAssetsDirectory(allocator, io, assets_dir, version, &diagnostic),
    );
    try std.testing.expect(std.mem.indexOf(u8, diagnostic.message(), "SBOM/SPDX") != null);
    try Dir.cwd().deleteFile(io, sbom_path);

    // Adding SHA256SUMS.txt in the assets directory must fail closed
    const checksums_path = try std.fs.path.join(
        allocator,
        &.{ assets_dir, "curl-8.23.0-zig.1-SHA256SUMS.txt" },
    );
    defer allocator.free(checksums_path);
    try generateChecksums(allocator, io, assets_dir, version, checksums_path, &diagnostic);
    try std.testing.expectError(
        error.Failed,
        verifyAssetsDirectory(allocator, io, assets_dir, version, &diagnostic),
    );
    try Dir.cwd().deleteFile(io, checksums_path);

    // Verify release notes rendering
    const notes = try renderReleaseNotes(
        allocator,
        default_repository,
        "v8.23.0-zig.1",
        version,
        null,
        &diagnostic,
    );
    defer allocator.free(notes);
    try std.testing.expect(std.mem.indexOf(u8, notes, "ghr install cataggar/curl@v8.23.0-zig.1") != null);
    try std.testing.expect(std.mem.indexOf(u8, notes, "Zig-port distribution") != null);
    try std.testing.expect(std.mem.indexOf(u8, notes, "curl-8.23.0-zig.1-windows-arm64.tar.gz") != null);
    try std.testing.expect(std.mem.indexOf(u8, notes, "| `curl-8.23.0-zig.1-linux-musl-x64.tar.gz` | `x86_64-linux-musl` | `curl` |") != null);
    try std.testing.expect(std.mem.indexOf(u8, notes, "| `curl-8.23.0-zig.1-windows-x64.tar.gz` | `x86_64-windows-gnu` | `curl.exe` |") != null);
}

test "Publisher.parseRelease and validateRemoteAssets enforce draft-first publication contract" {
    const allocator = std.testing.allocator;
    const io = std.testing.io;

    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();

    const root = try Dir.realPathFileAlloc(tmp.dir, io, ".", allocator);
    defer allocator.free(root);

    const fake_unix_exe = try std.fs.path.join(allocator, &.{ root, "fake-curl" });
    defer allocator.free(fake_unix_exe);
    const fake_win_exe = try std.fs.path.join(allocator, &.{ root, "fake-curl.exe" });
    defer allocator.free(fake_win_exe);
    const fake_copying = try std.fs.path.join(allocator, &.{ root, "COPYING" });
    defer allocator.free(fake_copying);
    const assets_dir = try std.fs.path.join(allocator, &.{ root, "assets" });
    defer allocator.free(assets_dir);

    try writeAtomic(io, fake_unix_exe, "#!/bin/sh\necho 'curl 8.23.0-zig.1'\n");
    try writeAtomic(io, fake_win_exe, "MZ-fake-windows-curl-binary");
    try writeAtomic(io, fake_copying, "Copyright (C) Daniel Stenberg\nSPDX-License-Identifier: curl\n");

    const version = "8.23.0-zig.1";
    var diagnostic: Diagnostic = .{};
    for (platforms) |platform| {
        const exe_src = if (std.mem.endsWith(u8, platform.executable, ".exe"))
            fake_win_exe
        else
            fake_unix_exe;
        try packageArchive(
            allocator,
            io,
            version,
            platform.suffix,
            exe_src,
            fake_copying,
            assets_dir,
            &diagnostic,
        );
    }
    const assets = try verifyAssetsDirectory(allocator, io, assets_dir, version, &diagnostic);
    defer freeAssets(allocator, assets);

    var publisher: Publisher = .{
        .allocator = allocator,
        .io = io,
        .diagnostic = &diagnostic,
        .options = .{
            .repository_name = default_repository,
            .tag = "v8.23.0-zig.1",
            .version = version,
            .commit = "0123456789abcdef0123456789abcdef01234567",
            .assets_directory = assets_dir,
            .workspace = root,
            .environment = .empty,
        },
        .assets = assets,
        .metadata = .{
            .tag = "v8.23.0-zig.1",
            .commit = "0123456789abcdef0123456789abcdef01234567",
            .prerelease = true,
            .title = "v8.23.0-zig.1",
            .body = "release body",
        },
    };

    // Build valid draft JSON matching all 6 local assets
    var json_buf: std.Io.Writer.Allocating = .init(allocator);
    defer json_buf.deinit();
    try json_buf.writer.writeAll(
        "{\"id\":42,\"draft\":true,\"prerelease\":true,\"tag_name\":\"v8.23.0-zig.1\",\"body\":\"release body\",\"assets\":[",
    );
    for (assets, 0..) |asset, idx| {
        if (idx > 0) try json_buf.writer.writeAll(",");
        try json_buf.writer.print(
            "{{\"id\":{d},\"name\":\"{s}\",\"size\":{d},\"digest\":\"sha256:{s}\",\"state\":\"uploaded\"}}",
            .{ 100 + idx, asset.name, asset.size, asset.digest_hex },
        );
    }
    try json_buf.writer.writeAll("]}");

    const parsed_json = try std.json.parseFromSlice(Value, allocator, json_buf.written(), .{});
    defer parsed_json.deinit();

    var release = try publisher.parseRelease(parsed_json.value, .require_uploaded);
    defer release.deinit(allocator);
    try std.testing.expect(release.draft);
    try publisher.validateRemoteAssets(&release);
    try std.testing.expectEqual(@as(?i64, 100), assets[0].remote_id);

    // Non-prerelease must be rejected
    const bad_prerelease = try std.json.parseFromSlice(
        Value,
        allocator,
        "{\"id\":42,\"draft\":true,\"prerelease\":false,\"tag_name\":\"v8.23.0-zig.1\",\"body\":\"release body\",\"assets\":[]}",
        .{},
    );
    defer bad_prerelease.deinit();
    try std.testing.expectError(
        error.Failed,
        publisher.parseRelease(bad_prerelease.value, .require_uploaded),
    );

    // Remote SBOM/SPDX asset must be rejected before undrafting
    const bad_sbom = try std.json.parseFromSlice(
        Value,
        allocator,
        "{\"id\":42,\"draft\":true,\"prerelease\":true,\"tag_name\":\"v8.23.0-zig.1\",\"body\":\"release body\",\"assets\":[{\"id\":1,\"name\":\"curl.spdx.json\",\"size\":10,\"digest\":null,\"state\":\"uploaded\"}]}",
        .{},
    );
    defer bad_sbom.deinit();
    try std.testing.expectError(
        error.Failed,
        publisher.parseRelease(bad_sbom.value, .require_uploaded),
    );
}

test "inspectBinaryFormatAndDependencies enforces static musl ELF, system Mach-O, and system PE imports" {
    var diagnostic: Diagnostic = .{};

    // 1. Valid static ELF64 x86_64 (1 PT_LOAD program header, no PT_INTERP)
    var elf_buf: [128]u8 = @splat(0);
    @memcpy(elf_buf[0..4], "\x7fELF");
    elf_buf[4] = 2; // ELFCLASS64
    elf_buf[5] = 1; // ELFDATA2LSB
    std.mem.writeInt(u16, elf_buf[18..20], 62, .little); // EM_X86_64
    std.mem.writeInt(u64, elf_buf[32..40], 64, .little); // e_phoff = 64
    std.mem.writeInt(u16, elf_buf[54..56], 56, .little); // e_phentsize = 56
    std.mem.writeInt(u16, elf_buf[56..58], 1, .little); // e_phnum = 1
    std.mem.writeInt(u32, elf_buf[64..68], 1, .little); // PT_LOAD = 1
    try inspectBinaryFormatAndDependencies(&elf_buf, "linux-musl-x64", &diagnostic);

    // Wrong architecture (linux-musl-arm64 expects 183) must fail
    try std.testing.expectError(
        error.Failed,
        inspectBinaryFormatAndDependencies(&elf_buf, "linux-musl-arm64", &diagnostic),
    );

    // Dynamic ELF64 with PT_INTERP (p_type == 3) must fail for linux-musl-x64
    std.mem.writeInt(u32, elf_buf[64..68], 3, .little); // PT_INTERP = 3
    try std.testing.expectError(
        error.Failed,
        inspectBinaryFormatAndDependencies(&elf_buf, "linux-musl-x64", &diagnostic),
    );

    // 2. Valid 64-bit Mach-O arm64 linking /usr/lib/libSystem.B.dylib
    var macho_buf: [96]u8 = @splat(0);
    std.mem.writeInt(u32, macho_buf[0..4], 0xfeedfacf, .little);
    std.mem.writeInt(u32, macho_buf[4..8], 0x0100000c, .little); // CPU_TYPE_ARM64
    std.mem.writeInt(u32, macho_buf[16..20], 1, .little); // ncmds = 1
    std.mem.writeInt(u32, macho_buf[32..36], 0x0c, .little); // LC_LOAD_DYLIB
    std.mem.writeInt(u32, macho_buf[36..40], 56, .little); // cmdsize = 56
    std.mem.writeInt(u32, macho_buf[40..44], 24, .little); // name offset = 24
    const sys_dylib = "/usr/lib/libSystem.B.dylib";
    @memcpy(macho_buf[56 .. 56 + sys_dylib.len], sys_dylib);
    try inspectBinaryFormatAndDependencies(&macho_buf, "macos-arm64", &diagnostic);

    // Non-system Homebrew dylib must fail
    @memset(macho_buf[56..88], 0);
    const brew_dylib = "/opt/homebrew/lib/libssl.3.dylib";
    @memcpy(macho_buf[56 .. 56 + brew_dylib.len], brew_dylib);
    try std.testing.expectError(
        error.Failed,
        inspectBinaryFormatAndDependencies(&macho_buf, "macos-arm64", &diagnostic),
    );
}
