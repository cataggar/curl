const std = @import("std");
pub const primitives = @import("primitives.zig");
pub const mem = @import("mem.zig");
pub const curlx_parse = @import("curlx_parse.zig");
pub const curlx_time_net = @import("curlx_time_net.zig");
pub const os_leaf = @import("os_leaf.zig");
pub const crypto = @import("crypto.zig");
pub const containers = @import("containers.zig");
pub const collections = @import("collections.zig");
pub const format_parse = @import("format_parse.zig");

// C executables (such as src/tool_main.c) provide their own C main().
pub extern fn main(argc: c_int, argv: [*][*:0]u8) callconv(.c) c_int;

comptime {
    _ = primitives;
    _ = mem;
    _ = curlx_parse;
    _ = curlx_time_net;
    _ = os_leaf;
    _ = crypto;
    _ = containers;
    _ = collections;
    _ = format_parse;
}

test {
    std.testing.refAllDecls(@This());
}
