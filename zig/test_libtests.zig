const std = @import("std");
const libcurl = @import("libcurl.zig");
const backends = @import("backends.zig");

pub const utils_c = [_][]const u8{
    "memptr.c",
    "testutil.c",
    "testtrace.c",
};

pub const tests_c = [_][]const u8{
    "cli_ev_download.c",
    "cli_ftp_upload.c",
    "cli_h2_pausing.c",
    "cli_h2_serverpush.c",
    "cli_h2_upgrade_extreme.c",
    "cli_hx_download.c",
    "cli_hx_upload.c",
    "cli_tls_session_reuse.c",
    "cli_upload_pausing.c",
    "cli_ws_data.c",
    "cli_ws_pause.c",
    "cli_ws_pingpong.c",
    "cli_ws_write_err.c",
    "lib464.c",
    "lib500.c",
    "lib501.c",
    "lib502.c",
    "lib503.c",
    "lib504.c",
    "lib505.c",
    "lib506.c",
    "lib507.c",
    "lib508.c",
    "lib509.c",
    "lib510.c",
    "lib511.c",
    "lib512.c",
    "lib513.c",
    "lib514.c",
    "lib515.c",
    "lib516.c",
    "lib517.c",
    "lib518.c",
    "lib519.c",
    "lib520.c",
    "lib521.c",
    "lib523.c",
    "lib524.c",
    "lib525.c",
    "lib526.c",
    "lib530.c",
    "lib533.c",
    "lib536.c",
    "lib537.c",
    "lib539.c",
    "lib540.c",
    "lib541.c",
    "lib542.c",
    "lib543.c",
    "lib544.c",
    "lib547.c",
    "lib549.c",
    "lib552.c",
    "lib553.c",
    "lib554.c",
    "lib555.c",
    "lib556.c",
    "lib557.c",
    "lib558.c",
    "lib559.c",
    "lib560.c",
    "lib562.c",
    "lib564.c",
    "lib566.c",
    "lib567.c",
    "lib568.c",
    "lib569.c",
    "lib570.c",
    "lib571.c",
    "lib572.c",
    "lib573.c",
    "lib574.c",
    "lib575.c",
    "lib576.c",
    "lib578.c",
    "lib579.c",
    "lib582.c",
    "lib583.c",
    "lib586.c",
    "lib589.c",
    "lib590.c",
    "lib591.c",
    "lib597.c",
    "lib598.c",
    "lib599.c",
    "lib643.c",
    "lib650.c",
    "lib651.c",
    "lib652.c",
    "lib653.c",
    "lib654.c",
    "lib655.c",
    "lib658.c",
    "lib659.c",
    "lib661.c",
    "lib666.c",
    "lib667.c",
    "lib668.c",
    "lib670.c",
    "lib674.c",
    "lib676.c",
    "lib677.c",
    "lib678.c",
    "lib694.c",
    "lib695.c",
    "lib751.c",
    "lib753.c",
    "lib757.c",
    "lib758.c",
    "lib766.c",
    "lib1156.c",
    "lib1301.c",
    "lib1308.c",
    "lib1396.c",
    "lib1398.c",
    "lib1451.c",
    "lib1485.c",
    "lib1500.c",
    "lib1501.c",
    "lib1502.c",
    "lib1506.c",
    "lib1507.c",
    "lib1508.c",
    "lib1509.c",
    "lib1510.c",
    "lib1511.c",
    "lib1512.c",
    "lib1513.c",
    "lib1514.c",
    "lib1515.c",
    "lib1517.c",
    "lib1518.c",
    "lib1520.c",
    "lib1522.c",
    "lib1523.c",
    "lib1525.c",
    "lib1526.c",
    "lib1527.c",
    "lib1528.c",
    "lib1529.c",
    "lib1530.c",
    "lib1531.c",
    "lib1532.c",
    "lib1533.c",
    "lib1534.c",
    "lib1535.c",
    "lib1536.c",
    "lib1537.c",
    "lib1538.c",
    "lib1540.c",
    "lib1541.c",
    "lib1542.c",
    "lib1545.c",
    "lib1549.c",
    "lib1550.c",
    "lib1551.c",
    "lib1552.c",
    "lib1553.c",
    "lib1554.c",
    "lib1555.c",
    "lib1556.c",
    "lib1557.c",
    "lib1558.c",
    "lib1559.c",
    "lib1560.c",
    "lib1564.c",
    "lib1565.c",
    "lib1567.c",
    "lib1568.c",
    "lib1569.c",
    "lib1571.c",
    "lib1576.c",
    "lib1582.c",
    "lib1587.c",
    "lib1588.c",
    "lib1589.c",
    "lib1591.c",
    "lib1592.c",
    "lib1593.c",
    "lib1594.c",
    "lib1597.c",
    "lib1598.c",
    "lib1599.c",
    "lib1605.c",
    "lib1616.c",
    "lib1647.c",
    "lib1648.c",
    "lib1649.c",
    "lib1662.c",
    "lib1678.c",
    "lib1686.c",
    "lib1742.c",
    "lib1744.c",
    "lib1745.c",
    "lib1791.c",
    "lib1900.c",
    "lib1901.c",
    "lib1902.c",
    "lib1903.c",
    "lib1905.c",
    "lib1906.c",
    "lib1907.c",
    "lib1908.c",
    "lib1910.c",
    "lib1911.c",
    "lib1912.c",
    "lib1913.c",
    "lib1915.c",
    "lib1916.c",
    "lib1918.c",
    "lib1919.c",
    "lib1920.c",
    "lib1921.c",
    "lib1922.c",
    "lib1933.c",
    "lib1934.c",
    "lib1935.c",
    "lib1936.c",
    "lib1937.c",
    "lib1938.c",
    "lib1939.c",
    "lib1940.c",
    "lib1945.c",
    "lib1947.c",
    "lib1948.c",
    "lib1955.c",
    "lib1956.c",
    "lib1957.c",
    "lib1958.c",
    "lib1959.c",
    "lib1960.c",
    "lib1964.c",
    "lib1965.c",
    "lib1967.c",
    "lib1970.c",
    "lib1971.c",
    "lib1972.c",
    "lib1973.c",
    "lib1974.c",
    "lib1975.c",
    "lib1977.c",
    "lib1978.c",
    "lib1985.c",
    "lib1989.c",
    "lib1990.c",
    "lib2023.c",
    "lib2032.c",
    "lib2082.c",
    "lib2095.c",
    "lib2118.c",
    "lib2270.c",
    "lib2301.c",
    "lib2302.c",
    "lib2304.c",
    "lib2306.c",
    "lib2308.c",
    "lib2309.c",
    "lib2380.c",
    "lib2397.c",
    "lib2402.c",
    "lib2404.c",
    "lib2405.c",
    "lib2412.c",
    "lib2414.c",
    "lib2453.c",
    "lib2502.c",
    "lib2504.c",
    "lib2505.c",
    "lib2506.c",
    "lib2700.c",
    "lib2805.c",
    "lib2924.c",
    "lib3010.c",
    "lib3025.c",
    "lib3026.c",
    "lib3027.c",
    "lib3033.c",
    "lib3034.c",
    "lib3100.c",
    "lib3101.c",
    "lib3102.c",
    "lib3103.c",
    "lib3104.c",
    "lib3105.c",
    "lib3107.c",
    "lib3207.c",
    "lib3208.c",
    "lib3231.c",
    "lib3233.c",
    "lib3234.c",
    "lib3595.c",
    "lib3596.c",
    "lib5000.c",
    "lib5004.c",
};

const tool_time_shim_c =
    \\#include "toolx/tool_time.h"
    \\#include "curlx/timeval.h"
    \\
    \\CURLcode toolx_localtime(time_t intime, struct tm *store)
    \\{
    \\#ifdef _WIN32
    \\  if(_localtime64_s(store, &intime))
    \\    return CURLE_BAD_FUNCTION_ARGUMENT;
    \\#elif defined(HAVE_LOCALTIME_R)
    \\  const struct tm *tm = localtime_r(&intime, store);
    \\  if(!tm)
    \\    return CURLE_BAD_FUNCTION_ARGUMENT;
    \\#else
    \\  const struct tm *tm = localtime(&intime);
    \\  if(tm)
    \\    *store = *tm;
    \\  else
    \\    return CURLE_BAD_FUNCTION_ARGUMENT;
    \\#endif
    \\  return CURLE_OK;
    \\}
    \\
    \\struct curltime tool_tvnow(void)
    \\{
    \\  return curlx_now();
    \\}
    \\
;

pub const standalone_tests = [_][]const u8{
    "lib509",
    "lib517",
    "lib543",
    "lib557",
    "lib558",
    "lib751",
    "lib758",
    "lib1301",
    "lib1506",
    "lib1508",
    "lib1521",
    "lib1537",
    "lib1538",
    "lib1550",
    "lib1559",
    "lib1560",
    "lib1564",
    "lib1587",
    "lib1597",
    "lib1791",
    "lib1911",
    "lib1912",
    "lib1918",
    "lib1921",
    "lib1965",
    "lib1967",
    "lib1990",
    "lib2380",
    "lib2412",
    "lib2414",
    "lib3026",
};

pub const LibtestsBuild = struct {
    exe: *std.Build.Step.Compile,
    stage: *std.Build.Step.UpdateSourceFiles,
    test_step: *std.Build.Step,
};

pub fn addLibtests(
    b: *std.Build,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
    libcurl_lib: *std.Build.Step.Compile,
    config_header: *std.Build.Step.ConfigHeader,
    backend_opts: backends.Options,
    is_static_libcurl: bool,
) LibtestsBuild {
    const gen_1521 = b.addSystemCommand(&.{"perl"});
    gen_1521.addFileArg2(b.path("tests/libtest/mk-lib1521.pl"), .{});
    gen_1521.setStdIn(.{ .lazy_path = b.path("include/curl/curl.h") });
    const lib1521_c = gen_1521.addOutputFileArg2("lib1521.c", .{});

    const gen_unity = b.addSystemCommand(&.{"perl"});
    gen_unity.addFileArg2(b.path("scripts/mk-unity.pl"), .{});
    gen_unity.addArg("--include");
    gen_unity.addArgs(&utils_c);
    gen_unity.addArg("--test");
    gen_unity.addArgs(&tests_c);
    gen_unity.addArg("lib1521.c");
    gen_unity.addFileInput(lib1521_c);
    gen_unity.addFileInput(b.path("tests/libtest/Makefile.inc"));
    gen_unity.addFileInput(b.path("tests/libtest/first.c"));
    gen_unity.addFileInput(b.path("tests/libtest/first.h"));
    const libtests_c = gen_unity.captureStdOut(.{ .basename = "libtests.c" });

    const wf = b.addWriteFiles();
    const shim_c = wf.add("tool_time_shim.c", tool_time_shim_c);

    const exe = b.addExecutable(.{
        .name = "libtests",
        .root_module = b.createModule(.{
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

    exe.root_module.addCSourceFile(.{
        .file = libtests_c,
        .flags = flags,
    });
    exe.root_module.addCSourceFile(.{
        .file = shim_c,
        .flags = flags,
    });

    exe.root_module.addIncludePath(b.path("include"));
    exe.root_module.addIncludePath(b.path("lib"));
    exe.root_module.addIncludePath(b.path("src"));
    exe.root_module.addIncludePath(b.path("tests/libtest"));
    exe.root_module.addIncludePath(lib1521_c.dirname());
    exe.root_module.addConfigHeader(config_header);

    exe.root_module.addCMacro("HAVE_CONFIG_H", "1");
    if (is_static_libcurl) {
        exe.root_module.addCMacro("CURL_STATICLIB", "1");
    }
    switch (os_tag) {
        .linux => {
            exe.root_module.addCMacro("_GNU_SOURCE", "1");
            exe.root_module.linkSystemLibrary("pthread", .{});
        },
        .macos => {
            exe.root_module.linkSystemLibrary("pthread", .{});
        },
        .windows => {
            exe.root_module.addCMacro("WIN32_LEAN_AND_MEAN", "1");
            exe.root_module.addCMacro("_WIN32_WINNT", "0x0600");
            exe.root_module.linkSystemLibrary("ws2_32", .{});
        },
        else => {
            exe.root_module.linkSystemLibrary("pthread", .{});
        },
    }

    backends.applyCMacros(exe.root_module, target, backend_opts);
    if (!is_static_libcurl) {
        backends.linkBackends(exe.root_module, target, backend_opts);
    }
    exe.root_module.linkLibrary(libcurl_lib);

    const stage = b.addUpdateSourceFiles();
    const staged_rel_path = if (os_tag == .windows) "tests/libtest/libtests.exe" else "tests/libtest/libtests";
    stage.addCopyFileToSource(exe.getEmittedBin(), staged_rel_path);

    const test_step = b.step("test-libtest", "Build tests/libtest/libtests and run standalone libtest programs");
    test_step.dependOn(&stage.step);

    for (standalone_tests) |test_name| {
        const run_test = b.addRunArtifact(exe);
        run_test.addArg(test_name);
        run_test.expectExitCode(0);
        run_test.expectStdErrMatch("Test ended with result 0");
        run_test.step.dependOn(&stage.step);
        test_step.dependOn(&run_test.step);
    }

    return .{
        .exe = exe,
        .stage = stage,
        .test_step = test_step,
    };
}
