const std = @import("std");
const libcurl = @import("libcurl.zig");

pub const c_sources = [_][]const u8{
    "src/config2setopts.c",
    "src/slist_wc.c",
    "src/terminal.c",
    "src/tool_cb_dbg.c",
    "src/tool_cb_hdr.c",
    "src/tool_cb_prg.c",
    "src/tool_cb_rea.c",
    "src/tool_cb_see.c",
    "src/tool_cb_soc.c",
    "src/tool_cb_wrt.c",
    "src/tool_cfgable.c",
    "src/tool_dirhie.c",
    "src/tool_doswin.c",
    "src/tool_easysrc.c",
    "src/tool_filetime.c",
    "src/tool_findfile.c",
    "src/tool_formparse.c",
    "src/tool_getparam.c",
    "src/tool_getpass.c",
    "src/tool_help.c",
    "src/tool_helpers.c",
    "src/tool_ipfs.c",
    "src/tool_libinfo.c",
    "src/tool_listhelp.c",
    "src/tool_main.c",
    "src/tool_msgs.c",
    "src/tool_operate.c",
    "src/tool_operhlp.c",
    "src/tool_paramhlp.c",
    "src/tool_parsecfg.c",
    "src/tool_progress.c",
    "src/tool_setopt.c",
    "src/tool_ssls.c",
    "src/tool_stderr.c",
    "src/tool_urlglob.c",
    "src/tool_util.c",
    "src/tool_vms.c",
    "src/tool_writeout.c",
    "src/tool_writeout_json.c",
    "src/tool_xattr.c",
    "src/var.c",
    "src/toolx/tool_time.c",
};

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
            .root_source_file = if (!is_static_libcurl) b.path("zig/port/root.zig") else null,
            .target = target,
            .optimize = optimize,
            .link_libc = true,
        }),
    });

    exe.root_module.addCSourceFiles(.{
        .files = &c_sources,
        .flags = &libcurl.c_flags,
    });
    if (!is_static_libcurl) {
        exe.root_module.addCSourceFiles(.{
            .files = &curlx_c_sources,
            .flags = &libcurl.c_flags,
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
        },
        else => {},
    }

    exe.root_module.linkLibrary(libcurl_lib);

    return exe;
}
