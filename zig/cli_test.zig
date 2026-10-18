const std = @import("std");
const builtin = @import("builtin");
const build_options = @import("build_options");

test "curl --version outputs version and protocols" {
    const gpa = std.testing.allocator;
    const io = std.testing.io;

    const result = try std.process.run(gpa, io, .{
        .argv = &.{ build_options.curl_exe_path, "--version" },
    });
    defer gpa.free(result.stdout);
    defer gpa.free(result.stderr);

    try std.testing.expectEqual(std.process.Child.Term{ .exited = 0 }, result.term);
    try std.testing.expect(std.mem.find(u8, result.stdout, "curl 8.23.1-DEV") != null);
    try std.testing.expect(std.mem.find(u8, result.stdout, "libcurl/8.23.1-DEV") != null);
    try std.testing.expect(std.mem.find(u8, result.stdout, "Protocols:") != null);
}

test "curl transfers local file:// URL" {
    const gpa = std.testing.allocator;
    const io = std.testing.io;

    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();

    const payload = "hello from curl zig cli smoke test\nline 2\n";
    try tmp.dir.writeFile(io, .{
        .sub_path = "payload.txt",
        .data = payload,
    });

    const abs_path = try tmp.dir.realPathFileAlloc(io, "payload.txt", gpa);
    defer gpa.free(abs_path);

    const url = if (builtin.os.tag == .windows) blk: {
        const normalized = try gpa.dupe(u8, abs_path);
        defer gpa.free(normalized);
        std.mem.replaceScalar(u8, normalized, '\\', '/');
        break :blk try std.fmt.allocPrint(gpa, "file:///{s}", .{normalized});
    } else try std.fmt.allocPrint(gpa, "file://{s}", .{abs_path});
    defer gpa.free(url);

    const result = try std.process.run(gpa, io, .{
        .argv = &.{ build_options.curl_exe_path, "-s", url },
    });
    defer gpa.free(result.stdout);
    defer gpa.free(result.stderr);

    try std.testing.expectEqual(std.process.Child.Term{ .exited = 0 }, result.term);
    try std.testing.expectEqualStrings(payload, result.stdout);
}
