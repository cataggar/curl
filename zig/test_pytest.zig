const std = @import("std");

const gen_config_py =
    \\import os, shutil, sys
    \\
    \\template_path, out_path, top_srcdir = sys.argv[1], sys.argv[2], os.path.abspath(sys.argv[3])
    \\exe_ext = sys.argv[4] if len(sys.argv) > 4 else ""
    \\
    \\def find_prog(names, extra_dirs):
    \\    path_env = os.environ.get("PATH", "")
    \\    search_path = os.pathsep.join(extra_dirs + ([path_env] if path_env else []))
    \\    for name in names:
    \\        if os.path.isabs(name):
    \\            if os.path.isfile(name) and os.access(name, os.X_OK):
    \\                return name
    \\        else:
    \\            found = shutil.which(name, path=search_path)
    \\            if found:
    \\                return found
    \\    return ""
    \\
    \\std_dirs = ["/usr/sbin", "/usr/bin", "/usr/local/bin", "/usr/local/sbin"]
    \\replacements = {
    \\    "@APXS@": find_prog(["apxs", "apxs2"], std_dirs),
    \\    "@HTTPD@": find_prog(["/usr/sbin/apache2", "httpd", "apache2"], std_dirs),
    \\    "@HTTPD_NGHTTPX@": find_prog(["nghttpx"], std_dirs),
    \\    "@CADDY@": find_prog(["caddy"], std_dirs),
    \\    "@VSFTPD@": find_prog(["vsftpd"], std_dirs),
    \\    "@DANTED@": find_prog(["danted"], std_dirs),
    \\    "@SSHD@": find_prog(["sshd"], std_dirs),
    \\    "@SFTPD@": find_prog(["sftp-server"], ["/usr/libexec", "/usr/lib/openssh", "/usr/lib/ssh"] + std_dirs),
    \\    "@H2O@": find_prog(["h2o"], std_dirs),
    \\}
    \\
    \\with open(template_path, "r", encoding="utf-8") as f:
    \\    content = f.read()
    \\
    \\for k, v in replacements.items():
    \\    content = content.replace(k, v)
    \\
    \\curl_bin = os.path.join(top_srcdir, "src", f"curl{exe_ext}")
    \\curlinfo_bin = os.path.join(top_srcdir, "src", f"curlinfo{exe_ext}")
    \\srcdir = os.path.join(top_srcdir, "tests", "http")
    \\global_block = (
    \\    "[global]\n"
    \\    f"CURL = {curl_bin}\n"
    \\    f"CURLINFO = {curlinfo_bin}\n"
    \\    f"TOP_SRCDIR = {top_srcdir}\n"
    \\    f"SRCDIR = {srcdir}\n"
    \\)
    \\content = content.replace("[global]\n", global_block, 1)
    \\
    \\with open(out_path, "w", encoding="utf-8") as f:
    \\    f.write(content)
;

const run_pytest_py =
    \\import os, sys, time, pytest
    \\sys.path.insert(0, os.getcwd())
    \\try:
    \\    from testenv.curl import RunTcpDump
    \\    _orig_start = RunTcpDump.start
    \\    def _start_and_wait(self):
    \\        _orig_start(self)
    \\        deadline = time.monotonic() + 2.0
    \\        while time.monotonic() < deadline:
    \\            if os.path.exists(self._stderrfile):
    \\                with open(self._stderrfile, "r", errors="ignore") as f:
    \\                    if "listening on" in f.read():
    \\                        break
    \\            time.sleep(0.01)
    \\    RunTcpDump.start = _start_and_wait
    \\except Exception:
    \\    pass
    \\sys.exit(pytest.main(sys.argv[1:]))
;

pub fn addTestPytestStep(
    b: *std.Build,
    target: std.Build.ResolvedTarget,
    test_servers_step: *std.Build.Step,
    libtests_stage_step: *std.Build.Step,
) *std.Build.Step {
    const exe_ext = target.result.exeFileExt();

    const gen_config = b.addSystemCommand(&.{
        "python3",
        "-c",
        gen_config_py,
    });
    gen_config.addFileArg2(b.path("tests/http/config.ini.in"), .{});
    const config_ini = gen_config.addOutputFileArg2("config.ini", .{});
    gen_config.addDirectoryArg(b.path("."));
    gen_config.addArg(exe_ext);

    const stage_config = b.addUpdateSourceFiles();
    stage_config.addCopyFileToSource(config_ini, "tests/http/config.ini");

    const run_pytest = b.addSystemCommand(&.{
        "python3",
        "-c",
        run_pytest_py,
    });
    run_pytest.addPassthruArgs();
    run_pytest.setCwd(b.path("tests/http"));
    run_pytest.has_side_effects = true;
    run_pytest.step.dependOn(&stage_config.step);
    run_pytest.step.dependOn(test_servers_step);
    run_pytest.step.dependOn(libtests_stage_step);

    const test_pytest_step = b.step(
        "test-pytest",
        "Generate tests/http/config.ini and run the pytest HTTP integration suite",
    );
    test_pytest_step.dependOn(&run_pytest.step);

    return test_pytest_step;
}
