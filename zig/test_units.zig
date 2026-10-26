const std = @import("std");
const libcurl = @import("libcurl.zig");
const cli = @import("cli.zig");
const backends = @import("backends.zig");

pub const unit_names = [_][]const u8{
    "unit1300",
    "unit1302",
    "unit1303",
    "unit1304",
    "unit1305",
    "unit1307",
    "unit1309",
    "unit1323",
    "unit1330",
    "unit1395",
    "unit1397",
    "unit1399",
    "unit1600",
    "unit1601",
    "unit1602",
    "unit1603",
    "unit1606",
    "unit1607",
    "unit1608",
    "unit1610",
    "unit1611",
    "unit1612",
    "unit1614",
    "unit1615",
    "unit1620",
    "unit1625",
    "unit1626",
    "unit1627",
    "unit1636",
    "unit1650",
    "unit1651",
    "unit1652",
    "unit1653",
    "unit1654",
    "unit1655",
    "unit1656",
    "unit1657",
    "unit1658",
    "unit1660",
    "unit1661",
    "unit1663",
    "unit1664",
    "unit1666",
    "unit1667",
    "unit1668",
    "unit1669",
    "unit1674",
    "unit1675",
    "unit1676",
    "unit1693",
    "unit1961",
    "unit1979",
    "unit1980",
    "unit2413",
    "unit2600",
    "unit2601",
    "unit2602",
    "unit2603",
    "unit2604",
    "unit2605",
    "unit2606",
    "unit3200",
    "unit3205",
    "unit3211",
    "unit3212",
    "unit3213",
    "unit3214",
    "unit3216",
    "unit3219",
    "unit3227",
    "unit3230",
    "unit3271",
    "unit3300",
    "unit3301",
    "unit3302",
    "unit3303",
    "unit3304",
    "unit3306",
    "unit3400",
    "unit4781",
    "unit4782",
};

pub const tunit_names = [_][]const u8{
    "tool1394",
    "tool1604",
    "tool1621",
    "tool1622",
    "tool1623",
    "tool1720",
};

pub const UnitsBuild = struct {
    units_exe: *std.Build.Step.Compile,
    tunits_exe: *std.Build.Step.Compile,
    stage_units: *std.Build.Step.UpdateSourceFiles,
    stage_tunits: *std.Build.Step.UpdateSourceFiles,
    test_unit_step: *std.Build.Step,
    test_tunit_step: *std.Build.Step,
};

pub fn setupUnitTests(
    b: *std.Build,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
    libcurl_lib: *std.Build.Step.Compile,
    config_header: *std.Build.Step.ConfigHeader,
    backend_opts: backends.Options,
    backend_options_step: *std.Build.Step.Options,
    is_static_libcurl: bool,
) UnitsBuild {
    const os_tag = target.result.os.tag;
    const flags = if (os_tag != .windows) &libcurl.c_flags_posix else &libcurl.c_flags;

    // 1. Build `tests/unit/units`
    const gen_units_c = b.addSystemCommand(&.{"perl"});
    gen_units_c.addFileArg(b.path("scripts/mk-unity.pl"));
    gen_units_c.addArg("--test");
    for (unit_names) |name| {
        gen_units_c.addArg(b.fmt("{s}.c", .{name}));
    }
    const units_c = gen_units_c.captureStdOut(.{});

    const units_exe = b.addExecutable(.{
        .name = "units",
        .root_module = b.createModule(.{
            .target = target,
            .optimize = optimize,
            .link_libc = true,
        }),
        .use_llvm = true,
    });
    if (os_tag != .windows) {
        units_exe.pie = true;
        units_exe.root_module.pic = true;
    }
    units_exe.root_module.addCSourceFile(.{
        .file = units_c,
        .flags = flags,
        .language = .c,
    });
    units_exe.root_module.addIncludePath(b.path("zig"));
    units_exe.root_module.addIncludePath(b.path("include"));
    units_exe.root_module.addIncludePath(b.path("lib"));
    units_exe.root_module.addIncludePath(b.path("tests/libtest"));
    units_exe.root_module.addIncludePath(b.path("tests/unit"));
    units_exe.root_module.addConfigHeader(config_header);

    units_exe.root_module.addCMacro("HAVE_CONFIG_H", "1");
    if (is_static_libcurl) {
        units_exe.root_module.addCMacro("CURL_STATICLIB", "1");
    }
    units_exe.root_module.addCMacro("UNITTESTS", "1");
    units_exe.root_module.addCMacro("BUILDING_LIBCURL", "1");
    switch (os_tag) {
        .linux => units_exe.root_module.addCMacro("_GNU_SOURCE", "1"),
        .windows => units_exe.root_module.addCMacro("WIN32_LEAN_AND_MEAN", "1"),
        else => {},
    }
    backends.applyCMacros(units_exe.root_module, target, backend_opts);
    if (!is_static_libcurl) {
        backends.linkBackends(units_exe.root_module, target, backend_opts);
    }
    units_exe.root_module.linkLibrary(libcurl_lib);

    const stage_units = b.addUpdateSourceFiles();
    const units_rel = if (os_tag == .windows) "tests/unit/units.exe" else "tests/unit/units";
    stage_units.addCopyFileToSource(units_exe.getEmittedBin(), units_rel);

    // Prepare test data files for unit tests that expect a file argument
    const wf = b.addWriteFiles();
    const netrc_1304 = wf.add(
        "netrc1304",
        "machine example.com login admin password passwd\n" ++
            "machine curl.example.com login none password none\n",
    );
    const altsvc_1654 = wf.add(
        "altsvc1654",
        "h2 example.com 443 h3 shiny.example.com 8443 \"20191231 00:00:00\" 0 0\n" ++
            "h2 expired.com 443 h3 shiny.example.com 8443 \"20190122 00:00:00\" 0 0\n" ++
            "# a comment\n" ++
            "h2 foo.example.com 443 h3 shiny.example.com 8443 \"20291231 23:30:00\" 0 0\n" ++
            "  h1 example.com 443 h3 shiny.example.com 8443 \"20221231 00:00:01\" 0 0\n" ++
            "\th3 example.com 443 h3 shiny.example.com 8443 \"20231231 00:00:00\" 0 0\n" ++
            "    # also a comment\n" ++
            "bad example.com 443 h3 shiny.example.com 8443 \"20191231 00:00:00\" 0 0\n" ++
            "rubbish\n",
    );
    const hsts_1660 = wf.add(
        "hsts1660",
        "# Your HSTS cache. https://curl.se/docs/hsts.html\n" ++
            "# This file was generated by libcurl! Edit at your own risk.\n" ++
            ".readfrom.example \"20211001 04:47:41\"\n" ++
            ".old.example \"20161001 04:47:41\"\n" ++
            ".new.example \"unlimited\"\n",
    );
    const line_1669 = "h2 example.com 443 h3 shiny.example.com 8443 \"20191231 00:00:00\" 0 0\n";
    const content_1669 = b.allocator.alloc(u8, line_1669.len * 5010) catch @panic("OOM");
    for (0..5010) |i| {
        @memcpy(content_1669[i * line_1669.len .. (i + 1) * line_1669.len], line_1669);
    }
    const altsvc_1669 = wf.add("altsvc1669", content_1669);
    const out_1674 = wf.add("out1674", "");
    const out_3200 = wf.add("out3200", "");

    const test_unit_step = b.step("test-unit", "Build and run all 81 upstream internal unit tests");
    test_unit_step.dependOn(&stage_units.step);

    for (unit_names) |name| {
        const run_unit = b.addRunArtifact(units_exe);
        run_unit.setName(b.fmt("run {s}", .{name}));
        run_unit.addArg(name);
        if (std.mem.eql(u8, name, "unit1304")) {
            run_unit.addFileArg(netrc_1304);
        } else if (std.mem.eql(u8, name, "unit1654")) {
            run_unit.setEnvironmentVariable("CURL_TIME", "1548369261");
            run_unit.addFileArg(altsvc_1654);
        } else if (std.mem.eql(u8, name, "unit1660")) {
            run_unit.setEnvironmentVariable("CURL_TIME", "1548369261");
            run_unit.addFileArg(hsts_1660);
        } else if (std.mem.eql(u8, name, "unit1669")) {
            run_unit.setEnvironmentVariable("CURL_TIME", "1548369261");
            run_unit.addFileArg(altsvc_1669);
        } else if (std.mem.eql(u8, name, "unit1674")) {
            run_unit.setEnvironmentVariable("CURL_TIME", "1548369261");
            run_unit.addFileArg(out_1674);
        } else if (std.mem.eql(u8, name, "unit3200")) {
            run_unit.addFileArg(out_3200);
        } else if (std.mem.eql(u8, name, "unit3306")) {
            run_unit.setEnvironmentVariable("CURL_DBG_THRDPOOL_FAIL_STARTS", "5");
        }
        run_unit.expectExitCode(0);
        _ = run_unit.captureStdOut(.{});
        _ = run_unit.captureStdErr(.{});
        test_unit_step.dependOn(&run_unit.step);
    }

    // 2. Build `tests/tunit/tunits`
    const curltool_lib = cli.addCurlToolLib(b, target, optimize);
    curltool_lib.use_llvm = libcurl_lib.use_llvm;
    curltool_lib.root_module.addOptions("backend_options", backend_options_step);
    backends.applyCMacros(curltool_lib.root_module, target, backend_opts);

    const gen_tunits_c = b.addSystemCommand(&.{"perl"});
    gen_tunits_c.addFileArg(b.path("scripts/mk-unity.pl"));
    gen_tunits_c.addArg("--test");
    for (tunit_names) |name| {
        gen_tunits_c.addArg(b.fmt("{s}.c", .{name}));
    }
    const tunits_c = gen_tunits_c.captureStdOut(.{});

    const tunits_exe = b.addExecutable(.{
        .name = "tunits",
        .root_module = b.createModule(.{
            .target = target,
            .optimize = optimize,
            .link_libc = true,
        }),
        .use_llvm = true,
    });
    if (os_tag != .windows) {
        tunits_exe.pie = true;
        tunits_exe.root_module.pic = true;
    }
    tunits_exe.root_module.addCSourceFile(.{
        .file = tunits_c,
        .flags = flags,
        .language = .c,
    });
    tunits_exe.root_module.addIncludePath(b.path("include"));
    tunits_exe.root_module.addIncludePath(b.path("lib"));
    tunits_exe.root_module.addIncludePath(b.path("src"));
    tunits_exe.root_module.addIncludePath(b.path("tests/libtest"));
    tunits_exe.root_module.addIncludePath(b.path("tests/tunit"));
    tunits_exe.root_module.addConfigHeader(config_header);

    tunits_exe.root_module.addCMacro("HAVE_CONFIG_H", "1");
    if (is_static_libcurl) {
        tunits_exe.root_module.addCMacro("CURL_STATICLIB", "1");
    }
    tunits_exe.root_module.addCMacro("UNITTESTS", "1");
    switch (os_tag) {
        .linux => tunits_exe.root_module.addCMacro("_GNU_SOURCE", "1"),
        .windows => tunits_exe.root_module.addCMacro("WIN32_LEAN_AND_MEAN", "1"),
        else => {},
    }
    backends.applyCMacros(tunits_exe.root_module, target, backend_opts);
    if (!is_static_libcurl) {
        backends.linkBackends(tunits_exe.root_module, target, backend_opts);
    }
    tunits_exe.root_module.linkLibrary(curltool_lib);
    tunits_exe.root_module.linkLibrary(libcurl_lib);

    const stage_tunits = b.addUpdateSourceFiles();
    const tunits_rel = if (os_tag == .windows) "tests/tunit/tunits.exe" else "tests/tunit/tunits";
    stage_tunits.addCopyFileToSource(tunits_exe.getEmittedBin(), tunits_rel);

    const test_tunit_step = b.step("test-tunit", "Build and run all 6 upstream CLI tool unit tests");
    test_tunit_step.dependOn(&stage_tunits.step);

    for (tunit_names) |name| {
        const run_tunit = b.addRunArtifact(tunits_exe);
        run_tunit.setName(b.fmt("run {s}", .{name}));
        run_tunit.addArg(name);
        run_tunit.expectExitCode(0);
        _ = run_tunit.captureStdOut(.{});
        _ = run_tunit.captureStdErr(.{});
        test_tunit_step.dependOn(&run_tunit.step);
    }

    return .{
        .units_exe = units_exe,
        .tunits_exe = tunits_exe,
        .stage_units = stage_units,
        .stage_tunits = stage_tunits,
        .test_unit_step = test_unit_step,
        .test_tunit_step = test_tunit_step,
    };
}
