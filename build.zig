const std = @import("std");
const libcurl = @import("zig/libcurl.zig");
const cli = @import("zig/cli.zig");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const shared = b.option(bool, "shared", "Build shared libcurl library instead of static") orelse false;

    const config_header = libcurl.createConfigHeader(b, target);
    const lib = libcurl.addLibcurl(b, .{
        .target = target,
        .optimize = optimize,
        .linkage = if (shared) .dynamic else .static,
        .config_header = config_header,
    });
    b.installArtifact(lib);

    const exe = cli.addCurlExe(b, target, optimize, lib, config_header, !shared);
    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    run_cmd.addPassthruArgs();
    const run_step = b.step("run", "Run the curl CLI");
    run_step.dependOn(&run_cmd.step);

    const translate_c = b.addTranslateC(.{
        .root_source_file = b.path("include/curl/curl.h"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    translate_c.addIncludePath(b.path("include"));
    if (!shared) {
        translate_c.defineCMacro("CURL_STATICLIB", "1");
    }

    const curl_mod = b.addModule("curl", .{
        .root_source_file = b.path("zig/root.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
        .imports = &.{
            .{ .name = "curl_c", .module = translate_c.createModule() },
        },
    });
    curl_mod.linkLibrary(lib);

    const unit_tests = b.addTest(.{
        .root_module = curl_mod,
    });
    const run_unit_tests = b.addRunArtifact(unit_tests);

    const cli_test_opts = b.addOptions();
    cli_test_opts.addOptionPath("curl_exe_path", exe.getEmittedBin());

    const cli_test_mod = b.createModule(.{
        .root_source_file = b.path("zig/cli_test.zig"),
        .target = target,
        .optimize = optimize,
    });
    cli_test_mod.addOptions("build_options", cli_test_opts);

    const cli_tests = b.addTest(.{
        .root_module = cli_test_mod,
    });
    const run_cli_tests = b.addRunArtifact(cli_tests);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_unit_tests.step);
    test_step.dependOn(&run_cli_tests.step);
}
