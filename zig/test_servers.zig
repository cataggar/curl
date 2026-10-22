const std = @import("std");
const libcurl = @import("libcurl.zig");
const backends = @import("backends.zig");

pub const server_utils_c = [_][]const u8{
    "getpart.c",
    "util.c",
};

pub const server_tests_c = [_][]const u8{
    "dnsd.c",
    "mqttd.c",
    "resolve.c",
    "rtspd.c",
    "sockfilt.c",
    "socksd.c",
    "sws.c",
    "tftpd.c",
};

pub const cert_configs = [_][]const u8{
    "test-client-cert.prm",
    "test-client-eku-only.prm",
    "test-localhost.prm",
    "test-localhost.nn.prm",
    "test-localhost0h.prm",
    "test-localhost-san-first.prm",
    "test-localhost-san-last.prm",
};

const tool_time_c_source =
    \\#include "toolx/tool_time.h"
    \\
    \\#if defined(__MINGW32__) && (__MINGW64_VERSION_MAJOR <= 3)
    \\#include <sec_api/time_s.h>
    \\#ifdef _USE_32BIT_TIME_T
    \\#define localtime_s _localtime32_s
    \\#else
    \\#define localtime_s _localtime64_s
    \\#endif
    \\#endif
    \\
    \\CURLcode toolx_localtime(time_t intime, struct tm *store)
    \\{
    \\#ifdef _WIN32
    \\  if(localtime_s(store, &intime))
    \\    return CURLE_BAD_FUNCTION_ARGUMENT;
    \\#elif defined(HAVE_LOCALTIME_R)
    \\  const struct tm *tm;
    \\  tm = localtime_r(&intime, store);
    \\  if(!tm)
    \\    return CURLE_BAD_FUNCTION_ARGUMENT;
    \\#else
    \\  const struct tm *tm;
    \\  tm = localtime(&intime);
    \\  if(tm)
    \\    *store = *tm;
    \\  else
    \\    return CURLE_BAD_FUNCTION_ARGUMENT;
    \\#endif
    \\
    \\  return CURLE_OK;
    \\}
    \\
;

const tests_config_contents =
    \\NGHTTPX: 
    \\
;

const configurehelp_pm_contents =
    \\package configurehelp;
    \\
    \\use strict;
    \\use warnings;
    \\use Exporter;
    \\
    \\use vars qw(
    \\    @ISA
    \\    @EXPORT_OK
    \\    $Cpreprocessor
    \\    );
    \\
    \\@ISA = qw(Exporter);
    \\
    \\@EXPORT_OK = qw(
    \\    $Cpreprocessor
    \\    );
    \\
    \\$Cpreprocessor = "zig cc -E -I../include";
    \\
    \\1;
    \\
;

pub fn addCurlInfoExe(
    b: *std.Build,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
    backend_options_step: *std.Build.Step.Options,
) *std.Build.Step.Compile {
    const mod = b.createModule(.{
        .root_source_file = b.path("zig/curlinfo.zig"),
        .target = target,
        .optimize = optimize,
    });
    mod.addOptions("backend_options", backend_options_step);

    return b.addExecutable(.{
        .name = "curlinfo",
        .root_module = mod,
    });
}

pub fn addServersExe(
    b: *std.Build,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
    libcurl_lib: *std.Build.Step.Compile,
    config_header: *std.Build.Step.ConfigHeader,
    backend_opts: backends.Options,
    shared: bool,
) *std.Build.Step.Compile {
    const mk_unity = b.addSystemCommand(&.{"perl"});
    mk_unity.addFileArg(b.path("scripts/mk-unity.pl"));
    mk_unity.addArg("--include");
    for (server_utils_c) |f| {
        mk_unity.addArg(f);
        mk_unity.addFileInput(b.path(b.fmt("tests/server/{s}", .{f})));
    }
    mk_unity.addArg("--test");
    for (server_tests_c) |f| {
        mk_unity.addArg(f);
        mk_unity.addFileInput(b.path(b.fmt("tests/server/{s}", .{f})));
    }
    mk_unity.addFileInput(b.path("tests/server/first.c"));
    mk_unity.addFileInput(b.path("tests/server/first.h"));
    const servers_c = mk_unity.captureStdOut(.{ .basename = "servers.c" });

    const wf = b.addWriteFiles();
    const tool_time_c = wf.add("tool_time.c", tool_time_c_source);

    const mod = b.createModule(.{
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });

    const os_tag = target.result.os.tag;
    const use_fortify = optimize != .debug and os_tag == .linux and target.result.abi.isGnu();
    const flags = if (use_fortify)
        &libcurl.c_flags_fortify
    else if (os_tag != .windows)
        &libcurl.c_flags_posix
    else
        &libcurl.c_flags;

    mod.addCSourceFile(.{
        .file = servers_c,
        .flags = flags,
    });
    mod.addCSourceFile(.{
        .file = tool_time_c,
        .flags = flags,
    });

    mod.addIncludePath(b.path("include"));
    mod.addIncludePath(b.path("lib"));
    mod.addIncludePath(b.path("src"));
    mod.addIncludePath(b.path("tests/server"));
    mod.addConfigHeader(config_header);

    mod.addCMacro("HAVE_CONFIG_H", "1");
    mod.addCMacro("CURL_STATICLIB", "1");
    switch (os_tag) {
        .linux => {
            mod.addCMacro("_GNU_SOURCE", "1");
        },
        .windows => {
            mod.addCMacro("WIN32_LEAN_AND_MEAN", "1");
            mod.addCMacro("_WIN32_WINNT", "0x0600");
        },
        else => {},
    }

    backends.applyCMacros(mod, target, backend_opts);
    if (shared) {
        backends.linkBackends(mod, target, backend_opts);
    }
    mod.linkLibrary(libcurl_lib);

    const exe = b.addExecutable(.{
        .name = "servers",
        .root_module = mod,
    });
    if (os_tag != .windows) {
        exe.pie = true;
        exe.root_module.pic = true;
        if (optimize != .debug) {
            exe.root_module.stack_protector = true;
        }
    }
    if (os_tag == .linux) {
        exe.link_z_relro = true;
        exe.link_z_lazy = false;
    }

    return exe;
}

pub fn addCertsStep(b: *std.Build) *std.Build.Step {
    const gen_certs = b.addSystemCommand(&.{
        "perl",
        "-e",
        "exit 0 if -f 'test-localhost.pem'; exec $^X, 'genserv.pl', @ARGV or die $!",
        "test",
    });
    for (cert_configs) |cfg| {
        gen_certs.addArg(cfg);
    }
    gen_certs.setCwd(b.path("tests/certs"));
    gen_certs.has_side_effects = true;

    const certs_step = b.step("test-certs", "Generate test TLS certificates in tests/certs");
    certs_step.dependOn(&gen_certs.step);
    return certs_step;
}

pub fn addTestServersStep(
    b: *std.Build,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
    curl_exe: *std.Build.Step.Compile,
    libcurl_lib: *std.Build.Step.Compile,
    config_header: *std.Build.Step.ConfigHeader,
    backend_opts: backends.Options,
    backend_options_step: *std.Build.Step.Options,
    shared: bool,
) *std.Build.Step {
    const curlinfo_exe = addCurlInfoExe(b, target, optimize, backend_options_step);
    b.installArtifact(curlinfo_exe);

    const servers_exe = addServersExe(
        b,
        target,
        optimize,
        libcurl_lib,
        config_header,
        backend_opts,
        shared,
    );

    const certs_step = addCertsStep(b);

    const exe_ext = target.result.exeFileExt();
    const stage_files = b.addUpdateSourceFiles();
    stage_files.addCopyFileToSource(curl_exe.getEmittedBin(), b.fmt("src/curl{s}", .{exe_ext}));
    stage_files.addCopyFileToSource(curlinfo_exe.getEmittedBin(), b.fmt("src/curlinfo{s}", .{exe_ext}));
    stage_files.addCopyFileToSource(servers_exe.getEmittedBin(), b.fmt("tests/server/servers{s}", .{exe_ext}));
    stage_files.addBytesToSource(tests_config_contents, "tests/config");
    stage_files.addBytesToSource(configurehelp_pm_contents, "tests/configurehelp.pm");

    const test_servers_step = b.step(
        "test-servers",
        "Build and stage curl, curlinfo, test servers, config, and certs",
    );
    test_servers_step.dependOn(b.getInstallStep());
    test_servers_step.dependOn(&stage_files.step);
    test_servers_step.dependOn(certs_step);

    return test_servers_step;
}
