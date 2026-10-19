const std = @import("std");
pub const cli_utils = @import("cli_utils.zig");
pub const cli_callbacks = @import("cli_callbacks.zig");

// C main() in src/tool_main.c provides the executable entry point until tool_main.c is ported.
pub extern fn main(argc: c_int, argv: [*][*:0]u8) callconv(.c) c_int;

comptime {
    _ = cli_utils;
    _ = cli_callbacks;
}
