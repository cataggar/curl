const std = @import("std");
const builtin = @import("builtin");
const backend_options = @import("backend_options");

const is_windows = builtin.os.tag == .windows;
const use_xattr = switch (builtin.os.tag) {
    .linux, .windows, .macos, .freebsd => true,
    else => false,
};
const use_cert_status = !backend_options.bundled and
    (backend_options.ssl == .openssl or backend_options.ssl == .gnutls);

pub const lines = [_][]const u8{
    "bindlocal: ON",
    "cookies: ON",
    "basic-auth: ON",
    "bearer-auth: ON",
    "digest: ON",
    "negotiate-auth: ON",
    "aws: ON",
    "httpsig: ON",
    "DoH: ON",
    "HTTP-auth: ON",
    "Mime: ON",
    "netrc: ON",
    "parsedate: ON",
    "proxy: ON",
    "shuffle-dns: ON",
    if (backend_options.use_resolv_threaded) "resolv-threaded: ON" else "resolv-threaded: OFF",
    "typecheck: ON",
    "verbose-strings: ON",
    if (!is_windows) "wakeup: ON" else "wakeup: OFF",
    "headers-api: ON",
    if (use_xattr) "xattr: ON" else "xattr: OFF",
    "form-api: ON",
    "large-time: ON",
    if (@sizeOf(usize) >= 5) "large-size: ON" else "large-size: OFF",
    "sha512-256: ON",
    if (is_windows) "win32-ca-searchpath: ON" else "win32-ca-searchpath: OFF",
    "win32-ca-search-safe: OFF",
    "--libcurl: ON",
    "override-dns: OFF",
    "ssl-sessions: OFF",
    if (use_cert_status) "cert-status: ON" else "cert-status: OFF",
    if (!is_windows) "getrlimit: ON" else "getrlimit: OFF",
};

pub fn main(init: std.process.Init) !void {
    var stdout_buffer: [2048]u8 = undefined;
    var stdout_file: std.Io.File.Writer = .init(.stdout(), init.io, &stdout_buffer);
    const stdout = &stdout_file.interface;
    for (lines) |line| {
        try stdout.print("{s}\n", .{line});
    }
    try stdout.flush();
}

test "curlinfo emits all 32 expected feature lines" {
    try std.testing.expectEqual(@as(usize, 32), lines.len);
    for (lines) |line| {
        try std.testing.expect(std.mem.endsWith(u8, line, ": ON") or std.mem.endsWith(u8, line, ": OFF"));
    }
}
