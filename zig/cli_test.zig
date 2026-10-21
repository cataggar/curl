const std = @import("std");
const builtin = @import("builtin");
const build_options = @import("build_options");
const backend_options = @import("backend_options");

test "curl --version outputs version and protocols" {
    const gpa = std.testing.allocator;
    const io = std.testing.io;

    const result = try std.process.run(gpa, io, .{
        .argv = &.{ build_options.curl_exe_path, "--version" },
    });
    defer gpa.free(result.stdout);
    defer gpa.free(result.stderr);

    try std.testing.expectEqual(std.process.Child.Term{ .exited = 0 }, result.term);
    try std.testing.expect(std.mem.find(u8, result.stdout, "curl " ++ backend_options.version) != null);
    try std.testing.expect(std.mem.find(u8, result.stdout, "libcurl/" ++ backend_options.version) != null);
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

test "curl --write-out formats variables and %{json}" {
    const gpa = std.testing.allocator;
    const io = std.testing.io;

    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();

    const payload = "writeout test payload 12345\n";
    try tmp.dir.writeFile(io, .{
        .sub_path = "writeout.txt",
        .data = payload,
    });

    const abs_path = try tmp.dir.realPathFileAlloc(io, "writeout.txt", gpa);
    defer gpa.free(abs_path);
    const url = try makeFileUrl(gpa, abs_path);
    defer gpa.free(url);

    const out_path = try std.fmt.allocPrint(gpa, "{s}.out", .{abs_path});
    defer gpa.free(out_path);

    const result = try std.process.run(gpa, io, .{
        .argv = &.{
            build_options.curl_exe_path,
            "-s",
            "-o",
            out_path,
            "-w",
            "size=%{size_download} code=%{exitcode} scheme=%{scheme} idx=%{urlnum}\\n%{json}",
            url,
        },
    });
    defer gpa.free(result.stdout);
    defer gpa.free(result.stderr);

    try std.testing.expectEqual(std.process.Child.Term{ .exited = 0 }, result.term);
    try std.testing.expect(std.mem.find(u8, result.stdout, "size=28 code=0 scheme=file idx=0\n") != null);
    try std.testing.expect(std.mem.find(u8, result.stdout, "\"size_download\":28") != null);
    try std.testing.expect(std.mem.find(u8, result.stdout, "\"exitcode\":0") != null);
    try std.testing.expect(std.mem.find(u8, result.stdout, "\"scheme\":\"file\"") != null);
}

test "curl debug trace, progress bar, stderr redirection, and file upload callbacks" {
    const gpa = std.testing.allocator;
    const io = std.testing.io;

    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();

    const payload = "callback test data\r\nsecond line\r\n";
    try tmp.dir.writeFile(io, .{
        .sub_path = "input.txt",
        .data = payload,
    });

    const abs_in = try tmp.dir.realPathFileAlloc(io, "input.txt", gpa);
    defer gpa.free(abs_in);
    const in_url = try makeFileUrl(gpa, abs_in);
    defer gpa.free(in_url);

    // Test --trace-ascii - --trace-time --trace-ids (tool_debug_cb)
    const trace_res = try std.process.run(gpa, io, .{
        .argv = &.{
            build_options.curl_exe_path,
            "-s",
            "--trace-ascii",
            "-",
            "--trace-time",
            "--trace-ids",
            in_url,
        },
    });
    defer gpa.free(trace_res.stdout);
    defer gpa.free(trace_res.stderr);

    try std.testing.expectEqual(std.process.Child.Term{ .exited = 0 }, trace_res.term);
    try std.testing.expect(std.mem.find(u8, trace_res.stdout, "[0-0] <= Recv data") != null);
    try std.testing.expect(std.mem.find(u8, trace_res.stdout, "0000: callback test data") != null);

    // Test -T upload (tool_read_cb / tool_seek_cb) and -# progress bar (tool_progress_cb)
    const abs_uploaded = try std.fmt.allocPrint(gpa, "{s}.uploaded", .{abs_in});
    defer gpa.free(abs_uploaded);
    const upload_url = try makeFileUrl(gpa, abs_uploaded);
    defer gpa.free(upload_url);

    const upload_res = try std.process.run(gpa, io, .{
        .argv = &.{
            build_options.curl_exe_path,
            "-#",
            "-T",
            abs_in,
            upload_url,
        },
    });
    defer gpa.free(upload_res.stdout);
    defer gpa.free(upload_res.stderr);

    try std.testing.expectEqual(std.process.Child.Term{ .exited = 0 }, upload_res.term);

    // Verify --stderr redirection and errorf/warnf formatting
    const err_path = try std.fmt.allocPrint(gpa, "{s}.stderr", .{abs_in});
    defer gpa.free(err_path);
    const missing_url = try std.fmt.allocPrint(gpa, "{s}.nonexistent", .{in_url});
    defer gpa.free(missing_url);

    const err_res = try std.process.run(gpa, io, .{
        .argv = &.{
            build_options.curl_exe_path,
            "--stderr",
            err_path,
            missing_url,
        },
    });
    defer gpa.free(err_res.stdout);
    defer gpa.free(err_res.stderr);

    try std.testing.expect(err_res.term != .exited or err_res.term.exited != 0);
    const err_file_data = try tmp.dir.readFileAlloc(io, "input.txt.stderr", gpa, .limited(4096));
    defer gpa.free(err_file_data);
    try std.testing.expect(std.mem.find(u8, err_file_data, "curl: (") != null);
}

test "cli_help_params: --help, --help category, --help http, and --help all" {
    const gpa = std.testing.allocator;
    const io = std.testing.io;

    const help_res = try std.process.run(gpa, io, .{
        .argv = &.{ build_options.curl_exe_path, "--help" },
    });
    defer gpa.free(help_res.stdout);
    defer gpa.free(help_res.stderr);
    try std.testing.expectEqual(std.process.Child.Term{ .exited = 0 }, help_res.term);
    try std.testing.expect(std.mem.find(u8, help_res.stdout, "Usage: curl [options...] <url>") != null);
    try std.testing.expect(std.mem.find(u8, help_res.stdout, "--help category") != null);

    const cat_res = try std.process.run(gpa, io, .{
        .argv = &.{ build_options.curl_exe_path, "--help", "category" },
    });
    defer gpa.free(cat_res.stdout);
    defer gpa.free(cat_res.stderr);
    try std.testing.expectEqual(std.process.Child.Term{ .exited = 0 }, cat_res.term);
    try std.testing.expect(std.mem.find(u8, cat_res.stdout, "http") != null);
    try std.testing.expect(std.mem.find(u8, cat_res.stdout, "tls") != null);

    const http_res = try std.process.run(gpa, io, .{
        .argv = &.{ build_options.curl_exe_path, "--help", "http" },
    });
    defer gpa.free(http_res.stdout);
    defer gpa.free(http_res.stderr);
    try std.testing.expectEqual(std.process.Child.Term{ .exited = 0 }, http_res.term);
    try std.testing.expect(std.mem.find(u8, http_res.stdout, "--header") != null);

    const all_res = try std.process.run(gpa, io, .{
        .argv = &.{ build_options.curl_exe_path, "--help", "all" },
    });
    defer gpa.free(all_res.stdout);
    defer gpa.free(all_res.stderr);
    try std.testing.expectEqual(std.process.Child.Term{ .exited = 0 }, all_res.term);
    try std.testing.expect(std.mem.find(u8, all_res.stdout, "--libcurl") != null);
}

test "cli_help_params: --libcurl codegen, -F formparse, -O remote-name, and param helpers" {
    const gpa = std.testing.allocator;
    const io = std.testing.io;

    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();

    const payload = "remote-name and libcurl test payload\n";
    try tmp.dir.writeFile(io, .{ .sub_path = "remote_item.txt", .data = payload });
    try tmp.dir.writeFile(io, .{ .sub_path = "hdrs.txt", .data = "X-Form-File-Hdr: from-file\r\n" });

    const dir_path = try tmp.dir.realPathFileAlloc(io, ".", gpa);
    defer gpa.free(dir_path);

    const base_url = try makeFileUrl(gpa, dir_path);
    defer gpa.free(base_url);

    const file_url = try std.fmt.allocPrint(gpa, "{s}/remote_item.txt?ignored_query=1", .{base_url});
    defer gpa.free(file_url);

    const libcurl_c_path = try std.fmt.allocPrint(gpa, "{s}/generated_client.c", .{dir_path});
    defer gpa.free(libcurl_c_path);

    const hdr_file_arg = try std.fmt.allocPrint(
        gpa,
        "meta=value1;type=text/plain;headers=X-Inline: 1;headers=@{s}/hdrs.txt",
        .{dir_path},
    );
    defer gpa.free(hdr_file_arg);

    const result = try std.process.run(gpa, io, .{
        .argv = &.{
            build_options.curl_exe_path,
            "-s",
            "--output-dir",
            dir_path,
            "-O",
            file_url,
            "--libcurl",
            libcurl_c_path,
            "--connect-timeout",
            "2.5",
            "--max-redirs",
            "5",
            "--proto",
            "=file,http",
            "-F",
            hdr_file_arg,
            "-F",
            "nested=(;type=multipart/alternative",
            "-F",
            "inner=hello world;encoder=8bit",
            "-F",
            "=)",
        },
    });
    defer gpa.free(result.stdout);
    defer gpa.free(result.stderr);

    try std.testing.expectEqual(std.process.Child.Term{ .exited = 0 }, result.term);

    const saved_remote = try tmp.dir.readFileAlloc(io, "remote_item.txt", gpa, .limited(256));
    defer gpa.free(saved_remote);
    try std.testing.expectEqualStrings(payload, saved_remote);

    const gen_c = try tmp.dir.readFileAlloc(io, "generated_client.c", gpa, .limited(16384));
    defer gpa.free(gen_c);
    try std.testing.expect(std.mem.find(u8, gen_c, "#include <curl/curl.h>") != null);
    try std.testing.expect(std.mem.find(u8, gen_c, "curl_mime_init(") != null);
    try std.testing.expect(std.mem.find(u8, gen_c, "curl_mime_subparts(") != null);
    try std.testing.expect(std.mem.find(u8, gen_c, "X-Form-File-Hdr: from-file") != null);
    try std.testing.expect(std.mem.find(u8, gen_c, "CURLOPT_CONNECTTIMEOUT_MS") != null);
    try std.testing.expect(std.mem.find(u8, gen_c, "curl_easy_perform(curl)") != null);
}

test "cli_help_params: ipfs_gateway URL rewrite with --ipfs-gateway" {
    const gpa = std.testing.allocator;
    const io = std.testing.io;

    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();

    const dir_path = try tmp.dir.realPathFileAlloc(io, ".", gpa);
    defer gpa.free(dir_path);

    const libcurl_c_path = try std.fmt.allocPrint(gpa, "{s}/ipfs_client.c", .{dir_path});
    defer gpa.free(libcurl_c_path);

    const result = try std.process.run(gpa, io, .{
        .argv = &.{
            build_options.curl_exe_path,
            "-s",
            "--ipfs-gateway",
            "http://127.0.0.1:1/",
            "--connect-timeout",
            "0.05",
            "--libcurl",
            libcurl_c_path,
            "ipfs://bafybeigdyrzt5sfp7udm7hu76uh7y26nf3efuylqabf3oclgtqy55fbzdi/hello.txt",
        },
    });
    defer gpa.free(result.stdout);
    defer gpa.free(result.stderr);

    const gen_c = try tmp.dir.readFileAlloc(io, "ipfs_client.c", gpa, .limited(16384));
    defer gpa.free(gen_c);
    try std.testing.expect(
        std.mem.find(
            u8,
            gen_c,
            "\"http://127.0.0.1:1/ipfs/bafybeigdyrzt5sfp7udm7hu76uh7y26nf3efuylqabf3oclgtqy55fbzdi/hello.txt\"",
        ) != null,
    );
}

test "cli_getparam_setopt: --help category listing and --help all" {
    const gpa = std.testing.allocator;
    const io = std.testing.io;

    const help_default = try std.process.run(gpa, io, .{
        .argv = &.{ build_options.curl_exe_path, "--help" },
    });
    defer gpa.free(help_default.stdout);
    defer gpa.free(help_default.stderr);

    try std.testing.expectEqual(std.process.Child.Term{ .exited = 0 }, help_default.term);
    try std.testing.expect(std.mem.find(u8, help_default.stdout, "--data <data>") != null);
    try std.testing.expect(std.mem.find(u8, help_default.stdout, "--user-agent <name>") != null);

    const help_http = try std.process.run(gpa, io, .{
        .argv = &.{ build_options.curl_exe_path, "--help", "http" },
    });
    defer gpa.free(help_http.stdout);
    defer gpa.free(help_http.stderr);

    try std.testing.expectEqual(std.process.Child.Term{ .exited = 0 }, help_http.term);
    try std.testing.expect(std.mem.find(u8, help_http.stdout, "--cookie <data|filename>") != null);
    try std.testing.expect(std.mem.find(u8, help_http.stdout, "--location") != null);
}

test "cli_getparam_setopt: --libcurl generates C source and parse_args handles --next" {
    const gpa = std.testing.allocator;
    const io = std.testing.io;

    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();

    try tmp.dir.writeFile(io, .{ .sub_path = "part1.txt", .data = "first-" });
    try tmp.dir.writeFile(io, .{ .sub_path = "part2.txt", .data = "second" });

    const dir_path = try tmp.dir.realPathFileAlloc(io, ".", gpa);
    defer gpa.free(dir_path);

    const base_url = try makeFileUrl(gpa, dir_path);
    defer gpa.free(base_url);

    const url1 = try std.fmt.allocPrint(gpa, "{s}/part1.txt", .{base_url});
    defer gpa.free(url1);
    const url2 = try std.fmt.allocPrint(gpa, "{s}/part2.txt", .{base_url});
    defer gpa.free(url2);
    const libcurl_c = try std.fmt.allocPrint(gpa, "{s}/gen.c", .{dir_path});
    defer gpa.free(libcurl_c);

    const result = try std.process.run(gpa, io, .{
        .argv = &.{
            build_options.curl_exe_path,
            "-sS",
            "-A",
            "ZigAgent/1.0",
            "-H",
            "X-Test: one\ttwo",
            "--max-filesize",
            "10K",
            "--libcurl",
            libcurl_c,
            url1,
            "-:",
            "-s",
            url2,
        },
    });
    defer gpa.free(result.stdout);
    defer gpa.free(result.stderr);

    try std.testing.expectEqual(std.process.Child.Term{ .exited = 0 }, result.term);
    try std.testing.expectEqualStrings("first-second", result.stdout);

    const generated = try tmp.dir.readFileAlloc(io, "gen.c", gpa, .limited(16384));
    defer gpa.free(generated);

    try std.testing.expect(std.mem.find(u8, generated, "CURLOPT_USERAGENT, \"ZigAgent/1.0\"") != null);
    try std.testing.expect(std.mem.find(u8, generated, "curl_slist_append(slist1, \"X-Test: one\\ttwo\")") != null);
    try std.testing.expect(std.mem.find(u8, generated, "CURLOPT_HTTPHEADER, slist1") != null);
    try std.testing.expect(std.mem.find(u8, generated, "CURLOPT_MAXFILESIZE_LARGE, (curl_off_t)10240") != null);
}

test "cli_main_operate: parallel transfers (-Z), --parallel-max, and config2setopts" {
    const gpa = std.testing.allocator;
    const io = std.testing.io;

    var tmp = std.testing.tmpDir(.{});
    defer tmp.cleanup();

    try tmp.dir.writeFile(io, .{ .sub_path = "p1.txt", .data = "parallel-one\n" });
    try tmp.dir.writeFile(io, .{ .sub_path = "p2.txt", .data = "parallel-two\n" });
    try tmp.dir.writeFile(io, .{ .sub_path = "p3.txt", .data = "parallel-three\n" });

    const dir_path = try tmp.dir.realPathFileAlloc(io, ".", gpa);
    defer gpa.free(dir_path);

    const base_url = try makeFileUrl(gpa, dir_path);
    defer gpa.free(base_url);

    const url1 = try std.fmt.allocPrint(gpa, "{s}/p1.txt", .{base_url});
    defer gpa.free(url1);
    const url2 = try std.fmt.allocPrint(gpa, "{s}/p2.txt", .{base_url});
    defer gpa.free(url2);
    const url3 = try std.fmt.allocPrint(gpa, "{s}/p3.txt", .{base_url});
    defer gpa.free(url3);

    const out1 = try std.fmt.allocPrint(gpa, "{s}/out1.txt", .{dir_path});
    defer gpa.free(out1);
    const out2 = try std.fmt.allocPrint(gpa, "{s}/out2.txt", .{dir_path});
    defer gpa.free(out2);
    const out3 = try std.fmt.allocPrint(gpa, "{s}/out3.txt", .{dir_path});
    defer gpa.free(out3);

    const result = try std.process.run(gpa, io, .{
        .argv = &.{
            build_options.curl_exe_path,
            "-sS",
            "--parallel",
            "--parallel-max",
            "2",
            "--parallel-immediate",
            url1,
            "-o",
            out1,
            url2,
            "-o",
            out2,
            url3,
            "-o",
            out3,
        },
    });
    defer gpa.free(result.stdout);
    defer gpa.free(result.stderr);

    try std.testing.expectEqual(std.process.Child.Term{ .exited = 0 }, result.term);

    const d1 = try tmp.dir.readFileAlloc(io, "out1.txt", gpa, .limited(256));
    defer gpa.free(d1);
    try std.testing.expectEqualStrings("parallel-one\n", d1);

    const d2 = try tmp.dir.readFileAlloc(io, "out2.txt", gpa, .limited(256));
    defer gpa.free(d2);
    try std.testing.expectEqualStrings("parallel-two\n", d2);

    const d3 = try tmp.dir.readFileAlloc(io, "out3.txt", gpa, .limited(256));
    defer gpa.free(d3);
    try std.testing.expectEqualStrings("parallel-three\n", d3);
}
