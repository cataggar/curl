const std = @import("std");
const builtin = @import("builtin");
pub const cli_utils = @import("cli_utils.zig");
pub const cli_callbacks = @import("cli_callbacks.zig");
pub const cli_help_params = @import("cli_help_params.zig");
pub const cli_getparam_setopt = @import("cli_getparam_setopt.zig");
pub const cli_main_operate = @import("cli_main_operate.zig");

pub const main = cli_main_operate.main;

comptime {
    _ = cli_utils;
    _ = cli_callbacks;
    _ = cli_help_params;
    _ = cli_getparam_setopt;
    _ = cli_main_operate;
    if (builtin.output_mode == .Exe) {
        @export(&cli_main_operate.main, .{ .name = "main" });
    }
}
