const std = @import("std");
const builtin = @import("builtin");

pub const MallocCallback = *const fn (usize) callconv(.c) ?*anyopaque;
pub const FreeCallback = *const fn (?*anyopaque) callconv(.c) void;
pub const ReallocCallback = *const fn (?*anyopaque, usize) callconv(.c) ?*anyopaque;
pub const StrdupCallback = *const fn ([*:0]const u8) callconv(.c) ?[*:0]u8;
pub const CallocCallback = *const fn (usize, usize) callconv(.c) ?*anyopaque;

pub const max_alloc_size: usize = std.math.maxInt(isize);

const use_libcurl_callbacks = (builtin.output_mode == .Lib or builtin.is_test);

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

pub fn curl_malloc_fn(size: usize) callconv(.c) ?*anyopaque {
    if (size == 0 or size > max_alloc_size) return null;
    return c.malloc(size);
}

pub fn curl_calloc_fn(nmemb: usize, size: usize) callconv(.c) ?*anyopaque {
    if (nmemb == 0 or size == 0) return null;
    const total = std.math.mul(usize, nmemb, size) catch return null;
    if (total > max_alloc_size) return null;
    return c.calloc(nmemb, size);
}

pub fn curl_realloc_fn(ptr: ?*anyopaque, size: usize) callconv(.c) ?*anyopaque {
    if (size > max_alloc_size) return null;
    return c.realloc(ptr, size);
}

pub fn curl_free_fn(ptr: ?*anyopaque) callconv(.c) void {
    c.free(ptr);
}

pub fn curl_strdup_fn(s: [*:0]const u8) callconv(.c) ?[*:0]u8 {
    const len = std.mem.len(s);
    if (len >= max_alloc_size) return null;
    const total = len + 1;
    const raw = c.malloc(total) orelse return null;
    const dst: [*]u8 = @ptrCast(raw);
    @memcpy(dst[0..total], s[0..total]);
    return @ptrCast(dst);
}

pub fn malloc(size: usize) ?[*]u8 {
    if (size == 0 or size > max_alloc_size) return null;
    const raw = if (use_libcurl_callbacks) libcurl_cb.Curl_cmalloc(size) else c.malloc(size);
    return if (raw) |p| @ptrCast(p) else null;
}

pub fn calloc(nmemb: usize, size: usize) ?[*]u8 {
    if (nmemb == 0 or size == 0) return null;
    const total = std.math.mul(usize, nmemb, size) catch return null;
    if (total > max_alloc_size) return null;
    const raw = if (use_libcurl_callbacks) libcurl_cb.Curl_ccalloc(nmemb, size) else c.calloc(nmemb, size);
    return if (raw) |p| @ptrCast(p) else null;
}

pub fn realloc(ptr: ?*anyopaque, size: usize) ?[*]u8 {
    if (size > max_alloc_size) return null;
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
    const len = std.mem.len(s);
    if (len >= max_alloc_size) return null;
    if (use_libcurl_callbacks) {
        return libcurl_cb.Curl_cstrdup(s);
    }
    const total = len + 1;
    const raw = c.malloc(total) orelse return null;
    const dst: [*]u8 = @ptrCast(raw);
    @memcpy(dst[0..total], s[0..total]);
    return @ptrCast(dst);
}

pub fn secureZero(ptr: ?*anyopaque, len: usize) void {
    if (ptr) |p| {
        if (len > 0) {
            const bytes: [*]u8 = @ptrCast(p);
            std.crypto.secureZero(u8, bytes[0..len]);
        }
    }
}

pub fn poison(ptr: ?*anyopaque, len: usize) void {
    if (ptr) |p| {
        if (len > 0) {
            const fill_byte: u8 = switch (builtin.mode) {
                .Debug, .ReleaseSafe => 0xaa,
                .ReleaseFast, .ReleaseSmall => 0x00,
            };
            const vbytes: [*]volatile u8 = @ptrCast(p);
            for (0..len) |i| {
                vbytes[i] = fill_byte;
            }
        }
    }
}

pub fn freeSized(ptr: ?*anyopaque, len: usize) void {
    if (ptr) |p| {
        poison(p, len);
        free(p);
    }
}

pub fn freeSecretZ(ptr: ?[*:0]u8) void {
    if (ptr) |s| {
        const len = std.mem.len(s);
        secureZero(@ptrCast(s), len);
        free(@ptrCast(s));
    }
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

const mock_mem_cb = struct {
    var calloc_calls: usize = 0;
    var malloc_calls: usize = 0;
    var realloc_calls: usize = 0;
    var free_calls: usize = 0;
    var last_freed_bytes: [16]u8 = @splat(0);
    var last_freed_capture_len: usize = 0;

    fn reset() void {
        calloc_calls = 0;
        malloc_calls = 0;
        realloc_calls = 0;
        free_calls = 0;
        last_freed_bytes = @splat(0);
        last_freed_capture_len = 0;
    }

    fn mockMalloc(size: usize) callconv(.c) ?*anyopaque {
        malloc_calls += 1;
        return c.malloc(size);
    }

    fn mockFree(ptr: ?*anyopaque) callconv(.c) void {
        free_calls += 1;
        if (ptr) |p| {
            if (last_freed_capture_len > 0) {
                const n = @min(last_freed_capture_len, last_freed_bytes.len);
                const src: [*]const u8 = @ptrCast(p);
                @memcpy(last_freed_bytes[0..n], src[0..n]);
            }
        }
        c.free(ptr);
    }

    fn mockRealloc(ptr: ?*anyopaque, size: usize) callconv(.c) ?*anyopaque {
        realloc_calls += 1;
        return c.realloc(ptr, size);
    }

    fn mockStrdup(s: [*:0]const u8) callconv(.c) ?[*:0]u8 {
        return curl_strdup_fn(s);
    }

    fn mockCalloc(nmemb: usize, size: usize) callconv(.c) ?*anyopaque {
        calloc_calls += 1;
        // Intentionally naive multiplication without overflow check to verify
        // that mem.calloc catches overflow BEFORE invoking Curl_ccalloc.
        return c.calloc(nmemb, size);
    }
};

extern fn curl_global_init_mem(
    flags: c_long,
    m: ?MallocCallback,
    f: ?FreeCallback,
    r: ?ReallocCallback,
    s: ?StrdupCallback,
    c_cb: ?CallocCallback,
) callconv(.c) c_int;
extern fn curl_global_init(flags: c_long) callconv(.c) c_int;
extern fn curl_global_cleanup() callconv(.c) void;

test "mem checked allocation bounds and calloc overflow with default and custom callbacks" {
    const half_overflow: usize = @as(usize, 1) << (@bitSizeOf(usize) / 2 + 1);

    // 1. Default allocator bounds & overflow checks
    try std.testing.expectEqual(@as(?[*]u8, null), malloc(0));
    try std.testing.expectEqual(@as(?[*]u8, null), malloc(max_alloc_size + 1));
    try std.testing.expectEqual(@as(?[*]u8, null), malloc(std.math.maxInt(usize)));
    try std.testing.expectEqual(@as(?*anyopaque, null), curl_malloc_fn(0));
    try std.testing.expectEqual(@as(?*anyopaque, null), curl_malloc_fn(max_alloc_size + 1));

    try std.testing.expectEqual(@as(?[*]u8, null), calloc(0, 16));
    try std.testing.expectEqual(@as(?[*]u8, null), calloc(16, 0));
    try std.testing.expectEqual(@as(?[*]u8, null), calloc(std.math.maxInt(usize), 2));
    try std.testing.expectEqual(@as(?[*]u8, null), calloc(2, std.math.maxInt(usize)));
    try std.testing.expectEqual(@as(?[*]u8, null), calloc(std.math.maxInt(usize), std.math.maxInt(usize)));
    try std.testing.expectEqual(@as(?[*]u8, null), calloc(half_overflow, half_overflow));
    try std.testing.expectEqual(@as(?[*]u8, null), calloc(1, max_alloc_size + 1));
    try std.testing.expectEqual(@as(?*anyopaque, null), curl_calloc_fn(std.math.maxInt(usize), 2));
    try std.testing.expectEqual(@as(?*anyopaque, null), curl_calloc_fn(half_overflow, half_overflow));

    // realloc exceeding max_alloc_size returns null and leaves existing allocation intact
    const initial = malloc(16) orelse return error.OutOfMemory;
    defer free(initial);
    @memset(initial[0..16], 0x5a);
    try std.testing.expectEqual(@as(?[*]u8, null), realloc(initial, max_alloc_size + 1));
    try std.testing.expectEqual(@as(?[*]u8, null), realloc(initial, std.math.maxInt(usize)));
    for (initial[0..16]) |b| {
        try std.testing.expectEqual(@as(u8, 0x5a), b);
    }

    // 2. Custom curl_global_init_mem callbacks: verify overflow is rejected before callback invocation
    mock_mem_cb.reset();
    try std.testing.expectEqual(
        @as(c_int, 0),
        curl_global_init_mem(
            0,
            mock_mem_cb.mockMalloc,
            mock_mem_cb.mockFree,
            mock_mem_cb.mockRealloc,
            mock_mem_cb.mockStrdup,
            mock_mem_cb.mockCalloc,
        ),
    );
    defer {
        curl_global_cleanup();
        // Re-init and cleanup once so default callbacks are restored on Curl_c*
        _ = curl_global_init(0);
        curl_global_cleanup();
    }

    mock_mem_cb.reset();
    try std.testing.expectEqual(@as(?[*]u8, null), calloc(std.math.maxInt(usize), 2));
    try std.testing.expectEqual(@as(?[*]u8, null), calloc(half_overflow, half_overflow));
    try std.testing.expectEqual(@as(?[*]u8, null), calloc(1, max_alloc_size + 1));
    try std.testing.expectEqual(@as(usize, 0), mock_mem_cb.calloc_calls);

    try std.testing.expectEqual(@as(?[*]u8, null), malloc(max_alloc_size + 1));
    try std.testing.expectEqual(@as(usize, 0), mock_mem_cb.malloc_calls);

    try std.testing.expectEqual(@as(?[*]u8, null), realloc(initial, max_alloc_size + 1));
    try std.testing.expectEqual(@as(usize, 0), mock_mem_cb.realloc_calls);

    // Valid calloc goes through the registered callback
    const valid_cb_buf = calloc(4, 8) orelse return error.OutOfMemory;
    try std.testing.expectEqual(@as(usize, 1), mock_mem_cb.calloc_calls);
    free(valid_cb_buf);
    try std.testing.expectEqual(@as(usize, 1), mock_mem_cb.free_calls);
}

test "mem secureZero, poison, freeSized, and freeSecretZ" {
    var buf = [_]u8{ 0xde, 0xad, 0xbe, 0xef, 0xca, 0xfe, 0xba, 0xbe };
    secureZero(&buf, buf.len);
    for (buf) |b| {
        try std.testing.expectEqual(@as(u8, 0), b);
    }
    secureZero(null, 16);
    secureZero(&buf, 0);

    poison(&buf, buf.len);
    const expected_poison: u8 = switch (builtin.mode) {
        .Debug, .ReleaseSafe => 0xaa,
        .ReleaseFast, .ReleaseSmall => 0x00,
    };
    for (buf) |b| {
        try std.testing.expectEqual(expected_poison, b);
    }
    poison(null, 16);
    poison(&buf, 0);

    // Verify freeSized poisons memory before invoking the underlying free callback
    mock_mem_cb.reset();
    try std.testing.expectEqual(
        @as(c_int, 0),
        curl_global_init_mem(
            0,
            mock_mem_cb.mockMalloc,
            mock_mem_cb.mockFree,
            mock_mem_cb.mockRealloc,
            mock_mem_cb.mockStrdup,
            mock_mem_cb.mockCalloc,
        ),
    );
    defer {
        curl_global_cleanup();
        _ = curl_global_init(0);
        curl_global_cleanup();
    }

    const sized_buf = malloc(8) orelse return error.OutOfMemory;
    @memset(sized_buf[0..8], 0x42);
    mock_mem_cb.last_freed_capture_len = 8;
    freeSized(sized_buf, 8);
    for (mock_mem_cb.last_freed_bytes[0..8]) |b| {
        try std.testing.expectEqual(expected_poison, b);
    }
    freeSized(null, 8);

    // Verify freeSecretZ zeroes the secret string before invoking free
    const secret = strdup("s3cr3tP@ss!") orelse return error.OutOfMemory;
    const secret_len = std.mem.len(secret);
    mock_mem_cb.last_freed_capture_len = secret_len;
    @memset(&mock_mem_cb.last_freed_bytes, 0xff);
    freeSecretZ(secret);
    for (mock_mem_cb.last_freed_bytes[0..secret_len]) |b| {
        try std.testing.expectEqual(@as(u8, 0), b);
    }
    freeSecretZ(null);
}
