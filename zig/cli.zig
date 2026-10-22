const std = @import("std");
const libcurl = @import("libcurl.zig");

pub const c_sources = [_][]const u8{};

pub const curlx_c_sources = [_][]const u8{};

pub fn addCurlExe(
    b: *std.Build,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
    libcurl_lib: *std.Build.Step.Compile,
    config_header: *std.Build.Step.ConfigHeader,
    is_static_libcurl: bool,
) *std.Build.Step.Compile {
    const exe = b.addExecutable(.{
        .name = "curl",
        .root_module = b.createModule(.{
            .root_source_file = b.path("zig/port/cli_root.zig"),
            .target = target,
            .optimize = optimize,
            .link_libc = true,
        }),
    });

    const os_tag = target.result.os.tag;
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

    const use_fortify = optimize != .debug and os_tag == .linux and target.result.abi.isGnu();
    const flags = if (use_fortify)
        &libcurl.c_flags_fortify
    else if (os_tag != .windows)
        &libcurl.c_flags_posix
    else
        &libcurl.c_flags;

    exe.root_module.addCSourceFiles(.{
        .files = &c_sources,
        .flags = flags,
    });
    if (!is_static_libcurl) {
        exe.root_module.addCSourceFiles(.{
            .files = &curlx_c_sources,
            .flags = flags,
        });
    }

    exe.root_module.addIncludePath(b.path("include"));
    exe.root_module.addIncludePath(b.path("lib"));
    exe.root_module.addIncludePath(b.path("src"));
    exe.root_module.addConfigHeader(config_header);

    exe.root_module.addCMacro("HAVE_CONFIG_H", "1");
    if (is_static_libcurl) {
        exe.root_module.addCMacro("CURL_STATICLIB", "1");
    }
    switch (target.result.os.tag) {
        .linux => {
            exe.root_module.addCMacro("_GNU_SOURCE", "1");
        },
        .windows => {
            exe.root_module.addCMacro("WIN32_LEAN_AND_MEAN", "1");
            if (!is_static_libcurl) {
                exe.root_module.linkSystemLibrary("secur32", .{});
            }
        },
        else => {},
    }

    exe.root_module.linkLibrary(libcurl_lib);

    return exe;
}

pub fn addCurlToolLib(
    b: *std.Build,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
) *std.Build.Step.Compile {
    const lib = b.addLibrary(.{
        .name = "curltool",
        .linkage = .static,
        .root_module = b.createModule(.{
            .root_source_file = b.path("zig/port/cli_root.zig"),
            .target = target,
            .optimize = optimize,
            .link_libc = true,
        }),
    });
    if (target.result.os.tag != .windows) {
        lib.root_module.pic = true;
    }
    return lib;
}
