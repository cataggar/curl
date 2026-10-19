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

fn makeFileUrl(gpa: std.mem.Allocator, abs_path: []const u8) ![]u8 {
    if (builtin.os.tag == .windows) {
        const normalized = try gpa.dupe(u8, abs_path);
        defer gpa.free(normalized);
        std.mem.replaceScalar(u8, normalized, '\\', '/');
        return std.fmt.allocPrint(gpa, "file:///{s}", .{normalized});
    }
    return std.fmt.allocPrint(gpa, "file://{s}", .{abs_path});
}

test "cli_utils: URL globbing set and numeric range with #1/#2 match output" {
    const gpa = std.testing.allocator;
    const io = std.testing.io;

    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();

    try tmp.dir.writeFile(io, .{ .sub_path = "alpha_1.txt", .data = "A1\n" });
    try tmp.dir.writeFile(io, .{ .sub_path = "alpha_2.txt", .data = "A2\n" });
    try tmp.dir.writeFile(io, .{ .sub_path = "beta_1.txt", .data = "B1\n" });
    try tmp.dir.writeFile(io, .{ .sub_path = "beta_2.txt", .data = "B2\n" });

    const dir_path = try tmp.dir.realPathFileAlloc(io, ".", gpa);
    defer gpa.free(dir_path);

    const base_url = try makeFileUrl(gpa, dir_path);
    defer gpa.free(base_url);

    const glob_url_arg = try std.fmt.allocPrint(gpa, "{s}/{{alpha,beta}}_[1-2].txt", .{base_url});
    defer gpa.free(glob_url_arg);

    const out_pattern = try std.fmt.allocPrint(gpa, "{s}/out_#1_#2.txt", .{dir_path});
    defer gpa.free(out_pattern);

    const result = try std.process.run(gpa, io, .{
        .argv = &.{ build_options.curl_exe_path, "-s", glob_url_arg, "-o", out_pattern },
    });
    defer gpa.free(result.stdout);
    defer gpa.free(result.stderr);

    try std.testing.expectEqual(std.process.Child.Term{ .exited = 0 }, result.term);

    const a1 = try tmp.dir.readFileAlloc(io, "out_alpha_1.txt", gpa, .limited(64));
    defer gpa.free(a1);
    try std.testing.expectEqualStrings("A1\n", a1);

    const b2 = try tmp.dir.readFileAlloc(io, "out_beta_2.txt", gpa, .limited(64));
    defer gpa.free(b2);
    try std.testing.expectEqualStrings("B2\n", b2);
}

test "cli_utils: variable expansion, config file parsing, create-dirs, and remote time" {
    const gpa = std.testing.allocator;
    const io = std.testing.io;

    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();

    const payload = "config + variable + dirhie test\n";
    try tmp.dir.writeFile(io, .{ .sub_path = "src_file.txt", .data = payload });

    const dir_path = try tmp.dir.realPathFileAlloc(io, ".", gpa);
    defer gpa.free(dir_path);

    const base_url = try makeFileUrl(gpa, dir_path);
    defer gpa.free(base_url);

    const out_file = try std.fmt.allocPrint(gpa, "{s}/nested/sub/result.txt", .{dir_path});
    defer gpa.free(out_file);

    const cfg_content = try std.fmt.allocPrint(
        gpa,
        "# test config file\nsilent\nremote-time\ncreate-dirs\nvariable = \"raw_name=  src_file.txt  \"\nexpand-variable = \"clean={{{{raw_name:trim}}}}\"\nexpand-url = \"{s}/{{{{clean}}}}\"\noutput = \"{s}\"\n",
        .{ base_url, out_file },
    );
    defer gpa.free(cfg_content);

    try tmp.dir.writeFile(io, .{ .sub_path = "test.curlrc", .data = cfg_content });
    const cfg_path = try tmp.dir.realPathFileAlloc(io, "test.curlrc", gpa);
    defer gpa.free(cfg_path);

    const result = try std.process.run(gpa, io, .{
        .argv = &.{ build_options.curl_exe_path, "--trace-time", "-K", cfg_path },
    });
    defer gpa.free(result.stdout);
    defer gpa.free(result.stderr);

    try std.testing.expectEqual(std.process.Child.Term{ .exited = 0 }, result.term);

    const written = try tmp.dir.readFileAlloc(io, "nested/sub/result.txt", gpa, .limited(128));
    defer gpa.free(written);
    try std.testing.expectEqualStrings(payload, written);
}
