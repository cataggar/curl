const std = @import("std");
pub const primitives = @import("primitives.zig");
pub const curlx_time_net = @import("curlx_time_net.zig");

// C executables (such as src/tool_main.c) provide their own C main().
pub extern fn main(argc: c_int, argv: [*][*:0]u8) callconv(.c) c_int;

comptime {
    _ = primitives;
    _ = curlx_time_net;
}

test {
    std.testing.refAllDecls(@This());
}
