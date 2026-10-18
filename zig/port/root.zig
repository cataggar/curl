const std = @import("std");
pub const primitives = @import("primitives.zig");

// C executables (such as src/tool_main.c) provide their own C main().
pub extern fn main(argc: c_int, argv: [*][*:0]u8) callconv(.c) c_int;

comptime {
    _ = primitives;
}

test {
    std.testing.refAllDecls(@This());
}
