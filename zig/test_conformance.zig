const std = @import("std");

pub fn addConformanceStep(
    b: *std.Build,
    staging_steps: []const *std.Build.Step,
) *std.Build.Step {
    const test_range = b.option(
        []const u8,
        "test-range",
        "Optional test range or arguments passed to runtests.pl (e.g. \"1 to 399\")",
    );
    const valgrind = b.option(
        bool,
        "valgrind",
        "Enable Valgrind memcheck in conformance tests (pass false to pass -n to runtests.pl)",
    ) orelse true;
    const test_jobs = b.option(
        usize,
        "test-jobs",
        "Number of parallel jobs (-jN) for runtests.pl",
    ) orelse 2;

    const run_cmd = b.addSystemCommand(&.{
        "perl",
        "./runtests.pl",
        "-a",
        b.fmt("-j{d}", .{test_jobs}),
    });
    if (!valgrind) {
        run_cmd.addArg("-n");
    }
    if (test_range) |range| {
        var it = std.mem.tokenizeAny(u8, range, " \t");
        while (it.next()) |arg| {
            run_cmd.addArg(arg);
        }
    }
    run_cmd.setCwd(b.path("tests"));
    run_cmd.has_side_effects = true;

    for (staging_steps) |step| {
        run_cmd.step.dependOn(step);
    }

    const conformance_step = b.step(
        "test-conformance",
        "Run upstream curl conformance test suite via tests/runtests.pl",
    );
    conformance_step.dependOn(&run_cmd.step);
    return conformance_step;
}
