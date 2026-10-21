//! `curl_release`: fail-closed packaging, archive inspection, SHA-256 manifest
//! generation, asset allowlist verification, and draft-first GitHub release
//! publication for the 6-platform curl Zig-port distribution (#63).

const std = @import("std");

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

pub const Platform = struct {
    suffix: []const u8,
    zig_target: []const u8,
    executable: []const u8,
    runtime_notes: []const u8,
    enabled_features: []const u8,
};

pub const platforms = [_]Platform{
    .{
        .suffix = "linux-musl-x64",
        .zig_target = "x86_64-linux-musl",
        .executable = "curl",
        .runtime_notes = "Static musl executable; no external shared library dependencies.",
        .enabled_features = "HTTP/1.1, FTP, FILE, DICT, GOPHER, IMAP, MQTT, POP3, RTSP,ich/SMTP, TELNET, TFTP, WS, IPv6, AsynchDNS, Largefile, alt-svc, HSTS (when built with TLS), NTLM, Digest, Basic, Bearer, OAuth2",
    },
    .{
        .suffix = "linux-musl-arm64",
        .zig_target = "aarch64-linux-musl",
        .executable = "curl",
        .runtime_notes = "Static musl executable; no external shared library dependencies.",
        .enabled_features = "HTTP/1.1, FTP, FILE, DICT, GOPHER, IMAP, MQTT, POP3, RTSP, SMTP, TELNET, TFTP, WS, IPv6, AsynchDNS, Largefile, alt-svc, NTLM, Digest, Basic, Bearer, OAuth2",
    },
    .{
        .suffix = "macos-x64",
        .zig_target = "x86_64-macos",
        .executable = "curl",
        .runtime_notes = "Links macOS system `libSystem.B.dylib` only; no Homebrew or third-party dylibs required.",
        .enabled_features = "HTTP/1.1, FTP, FILE, DICT, GOPHER, IMAP, MQTT, POP3, RTSP, SMTP, TELNET, TFTP, WS, IPv6, AsynchDNS, Largefile, alt-svc, NTLM, Digest, Basic, Bearer, OAuth2",
    },
    .{
        .suffix = "macos-arm64",
        .zig_target = "aarch64-macos",
        .executable = "curl",
        .runtime_notes = "Links macOS system `libSystem.B.dylib` only; no Homebrew or third-party dylibs required.",
        .enabled_features = "HTTP/1.1, FTP, FILE, DICT, GOPHER, IMAP, MQTT, POP3, RTSP, SMTP, TELNET, TFTP, WS, IPv6, AsynchDNS, Largefile, alt-svc, NTLM, Digest, Basic, Bearer, OAuth2",
    },
    .{
        .suffix = "windows-x64",
        .zig_target = "x86_64-windows-gnu",
        .executable = "curl.exe",
        .runtime_notes = "Links standard Windows OS DLLs only (`ws2_32.dll`, `secur32.dll`, `crypt32.dll`, `advapi32.dll`, `bcrypt.dll`, `normaliz.dll`, `wldap32.dll`).",
        .enabled_features = "HTTPS/TLS (Schannel), WinIDN, WinLDAP (LDAP/LDAPS), Windows SSPI (Kerberos/SPNEGO/NTLM), HTTP/1.1, FTP/FTPS, FILE, DICT, GOPHER/GOPHERS, IMAP/IMAPS, MQTT, POP3/POP3S, RTSP, SMTP/SMTPS, TELNET, TFTP, WS/WSS, IPv6, AsynchDNS, HSTS, HTTPS-proxy",
    },
    .{
        .suffix = "windows-arm64",
        .zig_target = "aarch64-windows-gnu",
        .executable = "curl.exe",
        .runtime_notes = "Links standard Windows OS DLLs only (`ws2_32.dll`, `secur32.dll`, `crypt32.dll`, `advapi32.dll`, `bcrypt.dll`, `normaliz.dll`, `wldap32.dll`).",
        .enabled_features = "HTTPS/TLS (Schannel), WinIDN, WinLDAP (LDAP/LDAPS), Windows SSPI (Kerberos/SPNEGO/NTLM), HTTP/1.1, FTP/FTPS, FILE, DICT, GOPHER/GOPHERS, IMAP/IMAPS, MQTT, POP3/POP3S, RTSP, SMTP/SMTPS, TELNET, TFTP, WS/WSS, IPv6, AsynchDNS, HSTS, HTTPS-proxy",
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

/// Validates a fork prerelease SemVer string (e.g. `8.23.1-zig.1` or `8.23.1-rc.1`).
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
        \\- `bin/{s}` — curl command-line executable
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
        \\Or extract directly and add `bin/` to your `PATH`:
        \\
        \\```console
        \\tar xzf curl-{s}-{s}.tar.gz
        \\./curl-{s}-{s}/bin/{s} --version
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

    const stage_bin = std.fs.path.join(allocator, &.{ stage_root, "bin" }) catch
        return error.OutOfMemory;
    defer allocator.free(stage_bin);
    Dir.cwd().createDirPath(io, stage_bin) catch |err| return diagnostic.fail(
        error.Failed,
        "cannot create staging directory {s}: {t}",
        .{ stage_bin, err },
    );

    const staged_exe_path = std.fs.path.join(
        allocator,
        &.{ stage_bin, platform.executable },
    ) catch return error.OutOfMemory;
    defer allocator.free(staged_exe_path);

    {
        var exe_file = Dir.cwd().createFile(io, staged_exe_path, .{
            .truncate = true,
            .permissions = .fromMode(0o755),
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

    const tar_res = std.process.run(allocator, io, .{
        .argv = &.{ "tar", "-czf", archive_path, "-C", output_dir, pkg_name },
    }) catch |err| return diagnostic.fail(
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

    var prefix_buf: [256]u8 = undefined;
    const prefix = std.fmt.bufPrint(
        &prefix_buf,
        "curl-{s}-{s}/",
        .{ version, platform.suffix },
    ) catch return diagnostic.fail(error.Failed, "archive prefix is too long", .{});

    var expected_bin_buf: [256]u8 = undefined;
    const expected_bin = std.fmt.bufPrint(
        &expected_bin_buf,
        "bin/{s}",
        .{platform.executable},
    ) catch return diagnostic.fail(error.Failed, "executable path is too long", .{});

    var has_exe = false;
    var has_copying = false;
    var has_readme = false;
    var bin_file_count: usize = 0;

    var lines = std.mem.splitScalar(u8, entries_text, '\n');
    while (lines.next()) |raw_line| {
        const line = std.mem.trimEnd(u8, raw_line, "\r");
        if (line.len == 0) continue;

        if (std.mem.indexOf(u8, line, "..") != null or std.mem.startsWith(u8, line, "/")) {
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

        const root_dir = prefix[0 .. prefix.len - 1];
        if (std.mem.eql(u8, line, root_dir) or std.mem.eql(u8, line, prefix)) {
            continue;
        }
        if (!std.mem.startsWith(u8, line, prefix)) {
            return diagnostic.fail(
                error.Failed,
                "archive entry {s} is outside expected root {s}",
                .{ line, prefix },
            );
        }

        const rel = line[prefix.len..];
        if (rel.len == 0 or std.mem.eql(u8, rel, "bin") or std.mem.eql(u8, rel, "bin/")) {
            continue;
        }

        if (isLibcurlDevPath(rel)) {
            return diagnostic.fail(
                error.Failed,
                "archive contains out-of-scope libcurl development entry: {s}",
                .{line},
            );
        }

        if (std.mem.startsWith(u8, rel, "bin/")) {
            bin_file_count += 1;
            if (std.mem.eql(u8, rel, expected_bin)) {
                has_exe = true;
            } else {
                return diagnostic.fail(
                    error.Failed,
                    "archive contains unexpected executable under bin/: {s}",
                    .{line},
                );
            }
        } else if (std.mem.eql(u8, rel, "COPYING")) {
            has_copying = true;
        } else if (std.mem.eql(u8, rel, "README.md")) {
            has_readme = true;
        } else {
            return diagnostic.fail(
                error.Failed,
                "archive contains unexpected entry: {s}",
                .{line},
            );
        }
    }

    if (bin_file_count != 1 or !has_exe) {
        return diagnostic.fail(
            error.Failed,
            "archive for {s} must contain exactly one executable ({s})",
            .{ platform.suffix, expected_bin },
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

    const tar_res = std.process.run(allocator, io, .{
        .argv = &.{ "tar", "-tzf", archive_path },
    }) catch |err| return diagnostic.fail(
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

/// Validates the local release assets directory against the strict #63 allowlist:
/// - The 6 `curl-<version>-<platform>.tar.gz` archives (inspected for layout and no SBOM/SPDX)
/// - The `curl-<version>-SHA256SUMS.txt` manifest (verified against the 6 archives)
/// - Optional detached signature `curl-<version>-SHA256SUMS.txt.asc` or `.sig`
/// Rejects any other file in `assets_directory`, including any SBOM or SPDX file.
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

    const manifest_name = checksumManifestName(allocator, version) catch
        return error.OutOfMemory;
    defer allocator.free(manifest_name);

    const sig_asc_name = std.fmt.allocPrint(
        allocator,
        "{s}.asc",
        .{manifest_name},
    ) catch return error.OutOfMemory;
    defer allocator.free(sig_asc_name);

    const sig_bin_name = std.fmt.allocPrint(
        allocator,
        "{s}.sig",
        .{manifest_name},
    ) catch return error.OutOfMemory;
    defer allocator.free(sig_bin_name);

    var directory = Dir.cwd().openDir(io, assets_directory, .{
        .iterate = true,
    }) catch |err| return diagnostic.fail(
        error.Failed,
        "cannot open release assets directory {s}: {t}",
        .{ assets_directory, err },
    );
    defer directory.close(io);

    var found_sig_name: ?[]const u8 = null;
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
        if (std.mem.eql(u8, entry.name, manifest_name)) {
            is_allowed = true;
        } else if (std.mem.eql(u8, entry.name, sig_asc_name)) {
            if (found_sig_name != null) {
                return diagnostic.fail(
                    error.Failed,
                    "multiple manifest signatures present in release assets directory",
                    .{},
                );
            }
            found_sig_name = sig_asc_name;
            is_allowed = true;
        } else if (std.mem.eql(u8, entry.name, sig_bin_name)) {
            if (found_sig_name != null) {
                return diagnostic.fail(
                    error.Failed,
                    "multiple manifest signatures present in release assets directory",
                    .{},
                );
            }
            found_sig_name = sig_bin_name;
            is_allowed = true;
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

    var expected_manifest_text: std.ArrayList(u8) = .empty;
    defer expected_manifest_text.deinit(allocator);

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

        var line_buf: [512]u8 = undefined;
        const line = std.fmt.bufPrint(
            &line_buf,
            "{s}  {s}\n",
            .{ &hashed.hex, archive_name },
        ) catch unreachable;
        expected_manifest_text.appendSlice(allocator, line) catch return error.OutOfMemory;
    }

    // Validate the SHA-256 checksum manifest
    const manifest_path = std.fs.path.join(
        allocator,
        &.{ assets_directory, manifest_name },
    ) catch return error.OutOfMemory;
    errdefer allocator.free(manifest_path);

    const manifest_bytes = readBounded(allocator, io, manifest_path, 64 * 1024) catch |err|
        return diagnostic.fail(
            error.Failed,
            "cannot read SHA-256 manifest {s}: {t}",
            .{ manifest_name, err },
        );
    defer allocator.free(manifest_bytes);

    if (!std.mem.eql(u8, manifest_bytes, expected_manifest_text.items)) {
        return diagnostic.fail(
            error.Failed,
            "SHA-256 manifest {s} does not match the exact 6 release archives",
            .{manifest_name},
        );
    }

    const manifest_hashed = hashRegularNoSymlink(io, manifest_path) catch |err|
        return diagnostic.fail(
            error.Failed,
            "SHA-256 manifest {s} is not a stable regular file: {t}",
            .{ manifest_name, err },
        );
    const dup_manifest_name = allocator.dupe(u8, manifest_name) catch return error.OutOfMemory;
    errdefer allocator.free(dup_manifest_name);

    list.append(allocator, .{
        .name = dup_manifest_name,
        .path = manifest_path,
        .digest_hex = manifest_hashed.hex,
        .size = manifest_hashed.size,
        .identity = manifest_hashed.identity,
    }) catch return error.OutOfMemory;

    if (found_sig_name) |sig_name| {
        const sig_path = std.fs.path.join(
            allocator,
            &.{ assets_directory, sig_name },
        ) catch return error.OutOfMemory;
        errdefer allocator.free(sig_path);

        const sig_hashed = hashRegularNoSymlink(io, sig_path) catch |err|
            return diagnostic.fail(
                error.Failed,
                "manifest signature {s} is not a stable regular file: {t}",
                .{ sig_name, err },
            );
        if (sig_hashed.size == 0) {
            return diagnostic.fail(
                error.Failed,
                "manifest signature is empty: {s}",
                .{sig_name},
            );
        }
        const dup_sig_name = allocator.dupe(u8, sig_name) catch return error.OutOfMemory;
        errdefer allocator.free(dup_sig_name);

        list.append(allocator, .{
            .name = dup_sig_name,
            .path = sig_path,
            .digest_hex = sig_hashed.hex,
            .size = sig_hashed.size,
            .identity = sig_hashed.identity,
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
        \\- **Six-platform Zig-built `curl` CLI archives.** Publishes `linux-musl-x64`, `linux-musl-arm64`, `macos-x64`, `macos-arm64`, `windows-x64`, and `windows-arm64` archives (`curl-{s}-<platform>.tar.gz`) with a verified `curl-{s}-SHA256SUMS.txt` manifest and zero SBOM or SPDX assets.
        \\- **Pure Zig port of `libcurl` and the `curl` CLI.** Core transfer engine, HTTP/1.1, SOCKS4/5, DNS resolver, MIME, cookie engine, HSTS, alt-svc, WebSockets, FTP, SMTP, IMAP, POP3, RTSP, TFTP, DICT, GOPHER, MQTT, TELNET, and FILE are compiled directly via `zig build`.
        \\- **Native Windows OS integration on Windows x64 and Arm64.** Windows archives enable Schannel TLS (`-Dssl=schannel`), WinIDN (`-Didn=winidn`), WinLDAP (`-Dldap=winldap`), and Windows SSPI (`-Dsspi=true`) out of the box using standard Windows system DLLs.
        \\- **Zero external shared library dependencies on Linux musl and macOS.** Linux musl binaries are statically linked; macOS binaries link only system `libSystem.B.dylib`.
        \\
        \\## Platform Coverage & Runtime Requirements
        \\
        \\| Archive | Zig target | Binary | Runtime dependencies |
        \\|---|---|---|---|
        \\| `curl-{s}-linux-musl-x64.tar.gz` | `x86_64-linux-musl` | `bin/curl` | Static musl binary (none) |
        \\| `curl-{s}-linux-musl-arm64.tar.gz` | `aarch64-linux-musl` | `bin/curl` | Static musl binary (none) |
        \\| `curl-{s}-macos-x64.tar.gz` | `x86_64-macos` | `bin/curl` | macOS `libSystem.B.dylib` |
        \\| `curl-{s}-macos-arm64.tar.gz` | `aarch64-macos` | `bin/curl` | macOS `libSystem.B.dylib` |
        \\| `curl-{s}-windows-x64.tar.gz` | `x86_64-windows-gnu` | `bin/curl.exe` | Windows system DLLs (`ws2_32`, `secur32`, `crypt32`, `advapi32`, `bcrypt`, `normaliz`, `wldap32`) |
        \\| `curl-{s}-windows-arm64.tar.gz` | `aarch64-windows-gnu` | `bin/curl.exe` | Windows system DLLs (`ws2_32`, `secur32`, `crypt32`, `advapi32`, `bcrypt`, `normaliz`, `wldap32`) |
        \\
        \\## Known Limitations
        \\
        \\- **CLI-only binary packages:** `libcurl` C development headers and static/shared libraries are outside the scope of these release archives.
        \\- **Optional system backends on Linux and macOS:** To keep the prebuilt Linux musl and macOS binaries self-contained without bundling third-party C/Rust libraries, optional external backends (`-Dssl=openssl|gnutls|mbedtls|wolfssl|rustls`, `-Dquic=ngtcp2|quiche`, `-Dssh=libssh2|libssh`, `-Dldap=openldap`, `-Dares=true`, `-Dgssapi=true`, `-Dzstd=true`, `-Dzlib=true`, `-Dbrotli=true`, `-Dnghttp2=true`, `-Dpsl=true`, `-Didn=libidn2`) are disabled in the prebuilt Unix archives and can be enabled when building from source with `zig build`.
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
            "### curl Zig-port release published\n\n- Release: https://github.com/{s}/releases/tag/{s}\n- Commit: `{s}`\n- Assets: {d} allowlisted files (6 platform archives + SHA-256 manifest, zero SBOM/SPDX assets), independently downloaded and verified\n",
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

    Dir.cwd().deleteTree(io, options.workspace) catch |err| return diagnostic.fail(
        error.Failed,
        "cannot reset release workspace: {t}",
        .{err},
    );
    Dir.cwd().createDirPath(io, options.workspace) catch |err| return diagnostic.fail(
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
        "8.23.1-zig.1",
        try versionFromTag("v8.23.1-zig.1", &diagnostic),
    );
    try std.testing.expectEqualStrings(
        "8.23.1-rc.1",
        try versionFromTag("v8.23.1-rc.1", &diagnostic),
    );
    try validateVersionTag("8.23.1-zig.1", "v8.23.1-zig.1", &diagnostic);

    // Reject missing 'v' prefix
    try std.testing.expectError(
        error.Failed,
        versionFromTag("8.23.1-zig.1", &diagnostic),
    );
    // Reject bare upstream version without prerelease suffix
    try std.testing.expectError(
        error.Failed,
        versionFromTag("v8.23.1", &diagnostic),
    );
    // Reject -dev / -DEV
    try std.testing.expectError(
        error.Failed,
        versionFromTag("v8.23.1-dev", &diagnostic),
    );
    try std.testing.expectError(
        error.Failed,
        versionFromTag("v8.23.1-DEV", &diagnostic),
    );
    // Reject +build metadata
    try std.testing.expectError(
        error.Failed,
        versionFromTag("v8.23.1-zig.1+20261021", &diagnostic),
    );
}

test "extractZonVersion and manifest validation" {
    const sample =
        \\.{
        \\    .name = .curl,
        \\    .version = "8.23.1-zig.1",
        \\    .minimum_zig_version = "0.17.0",
        \\}
    ;
    try std.testing.expectEqualStrings("8.23.1-zig.1", extractZonVersion(sample).?);
}

test "SBOM, SPDX, and libcurl dev path detectors reject prohibited entries" {
    try std.testing.expect(isSbOmOrSpdxPath("curl-8.23.1-zig.1-linux-musl-x64.sbom.json"));
    try std.testing.expect(isSbOmOrSpdxPath("curl-8.23.1-zig.1.spdx.json"));
    try std.testing.expect(isSbOmOrSpdxPath("curl-8.23.1-zig.1-linux-musl-x64/SBOM.txt"));
    try std.testing.expect(!isSbOmOrSpdxPath("curl-8.23.1-zig.1-linux-musl-x64/COPYING"));
    try std.testing.expect(!isSbOmOrSpdxPath("curl-8.23.1-zig.1-linux-musl-x64.tar.gz"));

    try std.testing.expect(isLibcurlDevPath("include/curl/curl.h"));
    try std.testing.expect(isLibcurlDevPath("lib/libcurl.a"));
    try std.testing.expect(isLibcurlDevPath("libcurl.so"));
    try std.testing.expect(isLibcurlDevPath("libcurl.pc"));
    try std.testing.expect(!isLibcurlDevPath("bin/curl"));
    try std.testing.expect(!isLibcurlDevPath("bin/curl.exe"));
    try std.testing.expect(!isLibcurlDevPath("COPYING"));
    try std.testing.expect(!isLibcurlDevPath("README.md"));
}

test "inspectArchiveListText validates exact layout and rejects SBOM, SPDX, and dev files" {
    var diagnostic: Diagnostic = .{};
    const valid_unix =
        \\curl-8.23.1-zig.1-linux-musl-x64/
        \\curl-8.23.1-zig.1-linux-musl-x64/bin/
        \\curl-8.23.1-zig.1-linux-musl-x64/bin/curl
        \\curl-8.23.1-zig.1-linux-musl-x64/COPYING
        \\curl-8.23.1-zig.1-linux-musl-x64/README.md
        \\
    ;
    try inspectArchiveListText(valid_unix, "8.23.1-zig.1", "linux-musl-x64", &diagnostic);

    const valid_win =
        \\curl-8.23.1-zig.1-windows-x64/
        \\curl-8.23.1-zig.1-windows-x64/bin/
        \\curl-8.23.1-zig.1-windows-x64/bin/curl.exe
        \\curl-8.23.1-zig.1-windows-x64/COPYING
        \\curl-8.23.1-zig.1-windows-x64/README.md
        \\
    ;
    try inspectArchiveListText(valid_win, "8.23.1-zig.1", "windows-x64", &diagnostic);

    // Reject SBOM inside archive
    const with_sbom = valid_unix ++ "curl-8.23.1-zig.1-linux-musl-x64/curl.spdx.json\n";
    try std.testing.expectError(
        error.Failed,
        inspectArchiveListText(with_sbom, "8.23.1-zig.1", "linux-musl-x64", &diagnostic),
    );

    // Reject libcurl dev header inside archive
    const with_header = valid_unix ++ "curl-8.23.1-zig.1-linux-musl-x64/include/curl/curl.h\n";
    try std.testing.expectError(
        error.Failed,
        inspectArchiveListText(with_header, "8.23.1-zig.1", "linux-musl-x64", &diagnostic),
    );

    // Reject second executable under bin/
    const with_extra_bin = valid_unix ++ "curl-8.23.1-zig.1-linux-musl-x64/bin/curl-config\n";
    try std.testing.expectError(
        error.Failed,
        inspectArchiveListText(with_extra_bin, "8.23.1-zig.1", "linux-musl-x64", &diagnostic),
    );
}

test "end-to-end packaging, checksum manifest generation, allowlist verification, and SBOM rejection" {
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

    try writeAtomic(io, fake_unix_exe, "#!/bin/sh\necho 'curl 8.23.1-zig.1'\n");
    try writeAtomic(io, fake_win_exe, "MZ-fake-windows-curl-binary");
    try writeAtomic(io, fake_copying, "Copyright (C) Daniel Stenberg\nSPDX-License-Identifier: curl\n");

    const version = "8.23.1-zig.1";
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

    try generateChecksums(allocator, io, assets_dir, version, null, &diagnostic);

    // Verify the complete 7-file allowlist (6 archives + SHA256SUMS.txt)
    const assets = try verifyAssetsDirectory(allocator, io, assets_dir, version, &diagnostic);
    defer freeAssets(allocator, assets);
    try std.testing.expectEqual(@as(usize, 7), assets.len);

    // Adding an SBOM file in the assets directory must fail closed
    const sbom_path = try std.fs.path.join(
        allocator,
        &.{ assets_dir, "curl-8.23.1-zig.1-linux-musl-x64.sbom.spdx.json" },
    );
    defer allocator.free(sbom_path);
    try writeAtomic(io, sbom_path, "{}");
    try std.testing.expectError(
        error.Failed,
        verifyAssetsDirectory(allocator, io, assets_dir, version, &diagnostic),
    );
    try std.testing.expect(std.mem.indexOf(u8, diagnostic.message(), "SBOM/SPDX") != null);
    try Dir.cwd().deleteFile(io, sbom_path);

    // Optional detached signature on the checksum manifest is allowed
    const sig_path = try std.fs.path.join(
        allocator,
        &.{ assets_dir, "curl-8.23.1-zig.1-SHA256SUMS.txt.asc" },
    );
    defer allocator.free(sig_path);
    try writeAtomic(io, sig_path, "-----BEGIN PGP SIGNATURE-----\nfake\n-----END PGP SIGNATURE-----\n");
    const assets_with_sig = try verifyAssetsDirectory(allocator, io, assets_dir, version, &diagnostic);
    defer freeAssets(allocator, assets_with_sig);
    try std.testing.expectEqual(@as(usize, 8), assets_with_sig.len);

    // Verify release notes rendering
    const notes = try renderReleaseNotes(
        allocator,
        default_repository,
        "v8.23.1-zig.1",
        version,
        null,
        &diagnostic,
    );
    defer allocator.free(notes);
    try std.testing.expect(std.mem.indexOf(u8, notes, "ghr install cataggar/curl@v8.23.1-zig.1") != null);
    try std.testing.expect(std.mem.indexOf(u8, notes, "Zig-port distribution") != null);
    try std.testing.expect(std.mem.indexOf(u8, notes, "curl-8.23.1-zig.1-windows-arm64.tar.gz") != null);
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

    try writeAtomic(io, fake_unix_exe, "#!/bin/sh\necho 'curl 8.23.1-zig.1'\n");
    try writeAtomic(io, fake_win_exe, "MZ-fake-windows-curl-binary");
    try writeAtomic(io, fake_copying, "Copyright (C) Daniel Stenberg\nSPDX-License-Identifier: curl\n");

    const version = "8.23.1-zig.1";
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
    try generateChecksums(allocator, io, assets_dir, version, null, &diagnostic);
    const assets = try verifyAssetsDirectory(allocator, io, assets_dir, version, &diagnostic);
    defer freeAssets(allocator, assets);

    var publisher: Publisher = .{
        .allocator = allocator,
        .io = io,
        .diagnostic = &diagnostic,
        .options = .{
            .repository_name = default_repository,
            .tag = "v8.23.1-zig.1",
            .version = version,
            .commit = "0123456789abcdef0123456789abcdef01234567",
            .assets_directory = assets_dir,
            .workspace = root,
            .environment = .empty,
        },
        .assets = assets,
        .metadata = .{
            .tag = "v8.23.1-zig.1",
            .commit = "0123456789abcdef0123456789abcdef01234567",
            .prerelease = true,
            .title = "v8.23.1-zig.1",
            .body = "release body",
        },
    };

    // Build valid draft JSON matching all 7 local assets
    var json_buf: std.Io.Writer.Allocating = .init(allocator);
    defer json_buf.deinit();
    try json_buf.writer.writeAll(
        "{\"id\":42,\"draft\":true,\"prerelease\":true,\"tag_name\":\"v8.23.1-zig.1\",\"body\":\"release body\",\"assets\":[",
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
        "{\"id\":42,\"draft\":true,\"prerelease\":false,\"tag_name\":\"v8.23.1-zig.1\",\"body\":\"release body\",\"assets\":[]}",
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
        "{\"id\":42,\"draft\":true,\"prerelease\":true,\"tag_name\":\"v8.23.1-zig.1\",\"body\":\"release body\",\"assets\":[{\"id\":1,\"name\":\"curl.spdx.json\",\"size\":10,\"digest\":null,\"state\":\"uploaded\"}]}",
        .{},
    );
    defer bad_sbom.deinit();
    try std.testing.expectError(
        error.Failed,
        publisher.parseRelease(bad_sbom.value, .require_uploaded),
    );
}
