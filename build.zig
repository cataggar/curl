const std = @import("std");
const libcurl = @import("zig/libcurl.zig");
const cli = @import("zig/cli.zig");
const backends = @import("zig/backends.zig");
const test_servers = @import("zig/test_servers.zig");
const test_libtests = @import("zig/test_libtests.zig");
const test_units = @import("zig/test_units.zig");
const test_conformance = @import("zig/test_conformance.zig");
const test_pytest = @import("zig/test_pytest.zig");

pub fn build(b: *std.Build) void {
    var target_query = b.standardTargetOptionsQueryOnly(.{});
    if ((target_query.cpu_arch orelse b.graph.host.result.cpu.arch) == .x86_64 and
        !std.Target.x86.featureSetHas(target_query.cpu_features_add, .avx512f))
    {
        target_query.cpu_features_sub.addFeature(@backingInt(std.Target.x86.Feature.avx512f));
    }
    const target = b.resolveTargetQuery(target_query);
    if (b.graph.release_mode == .any) {
        b.graph.release_mode = .safe;
    }
    const optimize = b.standardOptimizeOption(.{});
    const shared = b.option(bool, "shared", "Build shared libcurl library instead of static") orelse false;
    const backend_opts = backends.fromBuild(b);

    const config_header = libcurl.createConfigHeader(b, target);
    const lib = libcurl.addLibcurl(b, .{
        .target = target,
        .optimize = optimize,
        .linkage = if (shared) .dynamic else .static,
        .config_header = config_header,
    });
    backends.applyCMacros(lib.root_module, target, backend_opts);
    backends.linkBackends(lib.root_module, target, backend_opts);
    b.installArtifact(lib);

    const exe = cli.addCurlExe(b, target, optimize, lib, config_header, !shared);
    backends.applyCMacros(exe.root_module, target, backend_opts);
    if (shared) {
        backends.linkBackends(exe.root_module, target, backend_opts);
    }
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

    const backend_options_step = backends.createOptionsStep(b, backend_opts);
    lib.root_module.addOptions("backend_options", backend_options_step);
    exe.root_module.addOptions("backend_options", backend_options_step);
    curl_mod.addOptions("backend_options", backend_options_step);
    cli_test_mod.addOptions("backend_options", backend_options_step);

    const backend_test_mod = b.createModule(.{
        .root_source_file = b.path("zig/backends_test.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    backend_test_mod.linkLibrary(lib);
    backend_test_mod.addOptions("backend_options", backend_options_step);

    const backend_tests = b.addTest(.{
        .root_module = backend_test_mod,
    });
    const run_backend_tests = b.addRunArtifact(backend_tests);

    const test_backends_step = b.step("test-backends", "Run backend tests");
    test_backends_step.dependOn(&run_backend_tests.step);

    const port_test_mod = b.createModule(.{
        .root_source_file = b.path("zig/port/root.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });
    port_test_mod.addOptions("backend_options", backend_options_step);
    backends.applyCMacros(port_test_mod, target, backend_opts);
    backends.linkBackends(port_test_mod, target, backend_opts);
    port_test_mod.linkLibrary(lib);
    const port_tests = b.addTest(.{
        .root_module = port_test_mod,
    });
    const run_port_tests = b.addRunArtifact(port_tests);

    const test_port_step = b.step("test-port", "Run Zig port unit tests");
    test_port_step.dependOn(&run_port_tests.step);

    const release_mod = b.createModule(.{
        .root_source_file = b.path("zig/release.zig"),
        .target = b.graph.host,
        .optimize = optimize,
    });
    const release_exe = b.addExecutable(.{
        .name = "curl_release",
        .root_module = release_mod,
    });
    const install_release = b.addInstallArtifact(release_exe, .{});
    const install_release_step = b.step(
        "install-curl-release",
        "Install the curl Zig-port release contract and publication tool",
    );
    install_release_step.dependOn(&install_release.step);

    const release_tests = b.addTest(.{
        .root_module = release_mod,
    });
    const run_release_tests = b.addRunArtifact(release_tests);
    const test_release_step = b.step("test-release", "Run release tooling tests");
    test_release_step.dependOn(&run_release_tests.step);

    const test_servers_step = test_servers.addTestServersStep(
        b,
        target,
        optimize,
        exe,
        lib,
        config_header,
        backend_opts,
        backend_options_step,
        shared,
    );
    const libtests = test_libtests.addLibtests(b, target, optimize, lib, config_header, backend_opts, !shared);
    const units = test_units.setupUnitTests(
        b,
        target,
        optimize,
        lib,
        config_header,
        backend_opts,
        backend_options_step,
        !shared,
    );
    _ = test_conformance.addConformanceStep(b, &.{
        test_servers_step,
        &units.stage_units.step,
        &units.stage_tunits.step,
        &libtests.stage.step,
    });
    _ = test_pytest.addTestPytestStep(b, target, test_servers_step, &libtests.stage.step);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(b.getInstallStep());
    test_step.dependOn(&run_unit_tests.step);
    test_step.dependOn(&run_cli_tests.step);
    test_step.dependOn(&run_backend_tests.step);
    test_step.dependOn(&run_port_tests.step);
    test_step.dependOn(&run_release_tests.step);
}
