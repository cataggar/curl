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
pub const io_buffers = @import("io_buffers.zig");
pub const urlapi = @import("urlapi.zig");
pub const headers_sock = @import("headers_sock.zig");
pub const netrc_addr_idn = @import("netrc_addr_idn.zig");
pub const threads_psl = @import("threads_psl.zig");
pub const http1_options = @import("http1_options.zig");
pub const vauth_core = @import("vauth_core.zig");

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
    _ = io_buffers;
    _ = urlapi;
    _ = headers_sock;
    _ = netrc_addr_idn;
    _ = threads_psl;
    _ = http1_options;
    _ = vauth_core;
}

test {
    std.testing.refAllDecls(@This());
}
