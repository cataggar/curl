const std = @import("std");
const builtin = @import("builtin");

pub const MallocCallback = *const fn (usize) callconv(.c) ?*anyopaque;
pub const FreeCallback = *const fn (?*anyopaque) callconv(.c) void;
pub const ReallocCallback = *const fn (?*anyopaque, usize) callconv(.c) ?*anyopaque;
pub const StrdupCallback = *const fn ([*:0]const u8) callconv(.c) ?[*:0]u8;
pub const CallocCallback = *const fn (usize, usize) callconv(.c) ?*anyopaque;

const use_libcurl_callbacks = (builtin.output_mode == .Lib);

const libcurl_cb = struct {
    extern var Curl_cmalloc: MallocCallback;
    extern var Curl_cfree: FreeCallback;
    extern var Curl_crealloc: ReallocCallback;
    extern var Curl_cstrdup: StrdupCallback;
    extern var Curl_ccalloc: CallocCallback;
};

const c = struct {
    extern "c" fn malloc(size: usize) ?*anyopaque;
    extern "c" fn calloc(nmemb: usize, size: usize) ?*anyopaque;
    extern "c" fn realloc(ptr: ?*anyopaque, size: usize) ?*anyopaque;
    extern "c" fn free(ptr: ?*anyopaque) void;
};

pub fn malloc(size: usize) ?[*]u8 {
    const raw = if (use_libcurl_callbacks) libcurl_cb.Curl_cmalloc(size) else c.malloc(size);
    return if (raw) |p| @ptrCast(p) else null;
}

pub fn calloc(nmemb: usize, size: usize) ?[*]u8 {
    const raw = if (use_libcurl_callbacks) libcurl_cb.Curl_ccalloc(nmemb, size) else c.calloc(nmemb, size);
    return if (raw) |p| @ptrCast(p) else null;
}

pub fn realloc(ptr: ?*anyopaque, size: usize) ?[*]u8 {
    const raw = if (use_libcurl_callbacks) libcurl_cb.Curl_crealloc(ptr, size) else c.realloc(ptr, size);
    return if (raw) |p| @ptrCast(p) else null;
}

pub fn free(ptr: ?*anyopaque) void {
    if (use_libcurl_callbacks) {
        libcurl_cb.Curl_cfree(ptr);
    } else {
        c.free(ptr);
    }
}

pub fn strdup(s: [*:0]const u8) ?[*:0]u8 {
    if (use_libcurl_callbacks) {
        return libcurl_cb.Curl_cstrdup(s);
    }
    const len = std.mem.len(s);
    const total = std.math.add(usize, len, 1) catch return null;
    const raw = c.malloc(total) orelse return null;
    const dst: [*]u8 = @ptrCast(raw);
    @memcpy(dst[0..total], s[0..total]);
    return @ptrCast(dst);
}

test "mem bridge malloc, calloc, realloc, strdup, free" {
    const buf = malloc(16) orelse return error.OutOfMemory;
    @memset(buf[0..16], 0xaa);
    const grown = realloc(buf, 32) orelse {
        free(buf);
        return error.OutOfMemory;
    };
    for (grown[0..16]) |b| {
        try std.testing.expectEqual(@as(u8, 0xaa), b);
    }
    free(grown);

    const zeroed = calloc(8, 4) orelse return error.OutOfMemory;
    defer free(zeroed);
    for (zeroed[0..32]) |b| {
        try std.testing.expectEqual(@as(u8, 0), b);
    }

    const dup = strdup("hello curlx") orelse return error.OutOfMemory;
    defer free(dup);
    try std.testing.expectEqualStrings("hello curlx", std.mem.span(dup));
}
