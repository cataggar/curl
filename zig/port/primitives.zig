const std = @import("std");
const builtin = @import("builtin");

// ============================================================================
// 1. lib/strcase.c (lib/strcase.h)
// ============================================================================

pub export const Curl_touppermap: [256]u8 = .{
    0,   1,   2,   3,   4,   5,   6,   7,   8,   9,   10,  11,  12,  13,  14,  15,
    16,  17,  18,  19,  20,  21,  22,  23,  24,  25,  26,  27,  28,  29,  30,  31,
    32,  33,  34,  35,  36,  37,  38,  39,  40,  41,  42,  43,  44,  45,  46,  47,
    48,  49,  50,  51,  52,  53,  54,  55,  56,  57,  58,  59,  60,  61,  62,  63,
    64,  65,  66,  67,  68,  69,  70,  71,  72,  73,  74,  75,  76,  77,  78,  79,
    80,  81,  82,  83,  84,  85,  86,  87,  88,  89,  90,  91,  92,  93,  94,  95,
    96,  65,  66,  67,  68,  69,  70,  71,  72,  73,  74,  75,  76,  77,  78,  79,
    80,  81,  82,  83,  84,  85,  86,  87,  88,  89,  90,  123, 124, 125, 126, 127,
    128, 129, 130, 131, 132, 133, 134, 135, 136, 137, 138, 139, 140, 141, 142, 143,
    144, 145, 146, 147, 148, 149, 150, 151, 152, 153, 154, 155, 156, 157, 158, 159,
    160, 161, 162, 163, 164, 165, 166, 167, 168, 169, 170, 171, 172, 173, 174, 175,
    176, 177, 178, 179, 180, 181, 182, 183, 184, 185, 186, 187, 188, 189, 190, 191,
    192, 193, 194, 195, 196, 197, 198, 199, 200, 201, 202, 203, 204, 205, 206, 207,
    208, 209, 210, 211, 212, 213, 214, 215, 216, 217, 218, 219, 220, 221, 222, 223,
    224, 225, 226, 227, 228, 229, 230, 231, 232, 233, 234, 235, 236, 237, 238, 239,
    240, 241, 242, 243, 244, 245, 246, 247, 248, 249, 250, 251, 252, 253, 254, 255,
};

pub export const Curl_tolowermap: [256]u8 = .{
    0,   1,   2,   3,   4,   5,   6,   7,   8,   9,   10,  11,  12,  13,  14,  15,
    16,  17,  18,  19,  20,  21,  22,  23,  24,  25,  26,  27,  28,  29,  30,  31,
    32,  33,  34,  35,  36,  37,  38,  39,  40,  41,  42,  43,  44,  45,  46,  47,
    48,  49,  50,  51,  52,  53,  54,  55,  56,  57,  58,  59,  60,  61,  62,  63,
    64,  97,  98,  99,  100, 101, 102, 103, 104, 105, 106, 107, 108, 109, 110, 111,
    112, 113, 114, 115, 116, 117, 118, 119, 120, 121, 122, 91,  92,  93,  94,  95,
    96,  97,  98,  99,  100, 101, 102, 103, 104, 105, 106, 107, 108, 109, 110, 111,
    112, 113, 114, 115, 116, 117, 118, 119, 120, 121, 122, 123, 124, 125, 126, 127,
    128, 129, 130, 131, 132, 133, 134, 135, 136, 137, 138, 139, 140, 141, 142, 143,
    144, 145, 146, 147, 148, 149, 150, 151, 152, 153, 154, 155, 156, 157, 158, 159,
    160, 161, 162, 163, 164, 165, 166, 167, 168, 169, 170, 171, 172, 173, 174, 175,
    176, 177, 178, 179, 180, 181, 182, 183, 184, 185, 186, 187, 188, 189, 190, 191,
    192, 193, 194, 195, 196, 197, 198, 199, 200, 201, 202, 203, 204, 205, 206, 207,
    208, 209, 210, 211, 212, 213, 214, 215, 216, 217, 218, 219, 220, 221, 222, 223,
    224, 225, 226, 227, 228, 229, 230, 231, 232, 233, 234, 235, 236, 237, 238, 239,
    240, 241, 242, 243, 244, 245, 246, 247, 248, 249, 250, 251, 252, 253, 254, 255,
};

pub inline fn rawToupper(in: u8) u8 {
    return Curl_touppermap[in];
}

pub inline fn rawTolower(in: u8) u8 {
    return Curl_tolowermap[in];
}

pub export fn Curl_strntoupper(dest: [*]u8, src: [*]const u8, n: usize) callconv(.c) void {
    if (n < 1) return;
    var rem = n;
    var i: usize = 0;
    while (true) {
        const ch = src[i];
        dest[i] = Curl_touppermap[ch];
        i += 1;
        rem -= 1;
        if (ch == 0 or rem == 0) break;
    }
}

pub export fn Curl_strntolower(dest: [*]u8, src: [*]const u8, n: usize) callconv(.c) void {
    if (n < 1) return;
    var rem = n;
    var i: usize = 0;
    while (true) {
        const ch = src[i];
        dest[i] = Curl_tolowermap[ch];
        i += 1;
        rem -= 1;
        if (ch == 0 or rem == 0) break;
    }
}

pub export fn Curl_safecmp(a: ?[*:0]const u8, b: ?[*:0]const u8) callconv(.c) bool {
    if (a) |pa| {
        if (b) |pb| {
            return std.mem.orderZ(u8, pa, pb) == .eq;
        }
        return false;
    }
    return b == null;
}

pub export fn Curl_timestrcmp(a: ?[*:0]const u8, b: ?[*:0]const u8) callconv(.c) c_int {
    if (a) |pa| {
        if (b) |pb| {
            var match: c_int = 0;
            var i: usize = 0;
            while (true) : (i += 1) {
                match |= @as(c_int, pa[i] ^ pb[i]);
                if (pa[i] == 0 or pb[i] == 0)
                    break;
            }
            return match;
        }
        return 1;
    }
    return if (b != null) 1 else 0;
}

// ============================================================================
// 2. lib/strequal.c (include/curl/curl.h)
// ============================================================================

fn casecompare(first: [*:0]const u8, second: [*:0]const u8) c_int {
    var i: usize = 0;
    while (first[i] != 0) : (i += 1) {
        if (Curl_touppermap[first[i]] != Curl_touppermap[second[i]]) {
            return 0;
        }
    }
    return @intFromBool((first[i] == 0) == (second[i] == 0));
}

fn ncasecompare(first: [*:0]const u8, second: [*:0]const u8, max: usize) c_int {
    var rem = max;
    var i: usize = 0;
    while (first[i] != 0 and rem != 0) {
        if (Curl_touppermap[first[i]] != Curl_touppermap[second[i]]) {
            return 0;
        }
        rem -= 1;
        i += 1;
    }
    if (rem == 0) {
        return 1;
    }
    return @intFromBool(Curl_touppermap[first[i]] == Curl_touppermap[second[i]]);
}

pub export fn curl_strequal(s1: ?[*:0]const u8, s2: ?[*:0]const u8) callconv(.c) c_int {
    if (s1) |p1| {
        if (s2) |p2| {
            return casecompare(p1, p2);
        }
        return 0;
    }
    return @intFromBool(s2 == null);
}

pub export fn curl_strnequal(s1: ?[*:0]const u8, s2: ?[*:0]const u8, n: usize) callconv(.c) c_int {
    if (s1) |p1| {
        if (s2) |p2| {
            return ncasecompare(p1, p2, n);
        }
        return 0;
    }
    return @intFromBool(s2 == null and n != 0);
}

// ============================================================================
// 3. lib/curl_endian.c (lib/curl_endian.h)
// ============================================================================

pub export fn Curl_read16_le(buf: [*]const u8) callconv(.c) c_ushort {
    return @as(c_ushort, std.mem.readInt(u16, buf[0..2], .little));
}

pub export fn Curl_read32_le(buf: [*]const u8) callconv(.c) c_uint {
    return @as(c_uint, std.mem.readInt(u32, buf[0..4], .little));
}

pub export fn Curl_read16_be(buf: [*]const u8) callconv(.c) c_ushort {
    return @as(c_ushort, std.mem.readInt(u16, buf[0..2], .big));
}

// ============================================================================
// 4. lib/curl_memrchr.c (lib/curl_memrchr.h)
// ============================================================================

pub export fn Curl_memrchr(s: ?[*]const u8, c: c_int, n: usize) callconv(.c) ?*anyopaque {
    if (n > 0) {
        if (s) |bytes| {
            const target: u8 = @truncate(@as(c_uint, @bitCast(c)));
            var i: usize = n;
            while (i > 0) {
                i -= 1;
                if (bytes[i] == target) {
                    return @constCast(&bytes[i]);
                }
            }
        }
    }
    return null;
}

// ============================================================================
// 5. lib/curlx/strcopy.c (lib/curlx/strcopy.h)
// ============================================================================

pub export fn curlx_strcopy(dest: ?[*]u8, dsize: usize, src: ?[*]const u8, slen: usize) callconv(.c) void {
    if (slen < dsize) {
        if (dest) |d| {
            if (slen > 0) {
                if (src) |s| {
                    @memcpy(d[0..slen], s[0..slen]);
                }
            }
            d[slen] = 0;
        }
    } else if (dsize != 0) {
        if (dest) |d| {
            d[0] = 0;
        }
    }
}

// ============================================================================
// 6. lib/curlx/warnless.c (lib/curlx/warnless.h)
// ============================================================================

pub export fn curlx_ultouc(ulnum: c_ulong) callconv(.c) u8 {
    return @intCast(ulnum & @as(c_ulong, std.math.maxInt(u8)));
}

pub export fn curlx_uztosi(uznum: usize) callconv(.c) c_int {
    return @intCast(uznum & @as(usize, @intCast(std.math.maxInt(c_int))));
}

pub export fn curlx_uztoul(uznum: usize) callconv(.c) c_ulong {
    return @intCast(uznum & @as(usize, @intCast(std.math.maxInt(c_ulong))));
}

pub export fn curlx_uztoui(uznum: usize) callconv(.c) c_uint {
    return @intCast(uznum & @as(usize, @intCast(std.math.maxInt(c_uint))));
}

pub export fn curlx_sltosi(slnum: c_long) callconv(.c) c_int {
    const ul: c_ulong = @bitCast(slnum);
    return @intCast(ul & @as(c_ulong, @intCast(std.math.maxInt(c_int))));
}

pub export fn curlx_sltoui(slnum: c_long) callconv(.c) c_uint {
    const ul: c_ulong = @bitCast(slnum);
    return @intCast(ul & @as(c_ulong, @intCast(std.math.maxInt(c_uint))));
}

pub export fn curlx_sltous(slnum: c_long) callconv(.c) c_ushort {
    const ul: c_ulong = @bitCast(slnum);
    return @intCast(ul & @as(c_ulong, @intCast(std.math.maxInt(c_ushort))));
}

pub export fn curlx_uztosz(uznum: usize) callconv(.c) isize {
    return @intCast(uznum & @as(usize, @intCast(std.math.maxInt(isize))));
}

pub export fn curlx_sotouz(sonum: i64) callconv(.c) usize {
    const u: u64 = @bitCast(sonum);
    return @intCast(u & @as(u64, @intCast(std.math.maxInt(usize))));
}

pub export fn curlx_sztosi(sznum: isize) callconv(.c) c_int {
    const u: usize = @bitCast(sznum);
    return @intCast(u & @as(usize, @intCast(std.math.maxInt(c_int))));
}

pub export fn curlx_uitous(uinum: c_uint) callconv(.c) c_ushort {
    return @intCast(uinum & @as(c_uint, @intCast(std.math.maxInt(c_ushort))));
}

pub export fn curlx_sitouz(sinum: c_int) callconv(.c) usize {
    return @bitCast(@as(isize, sinum));
}

pub export fn curlx_uitouz(uinum: c_uint) callconv(.c) usize {
    return @intCast(uinum);
}

pub export fn curlx_sotouz_range(sonum: i64, uzmin: usize, uzmax: usize) callconv(.c) usize {
    if (sonum < 0) return uzmin;
    const u: u64 = @intCast(sonum);
    if (u > @as(u64, std.math.maxInt(usize))) return uzmax;
    const val: usize = @intCast(u);
    return @min(@max(val, uzmin), uzmax);
}

pub export fn curlx_sztouz(sznum: isize, puznum: *usize) callconv(.c) bool {
    if (sznum < 0) {
        puznum.* = 0;
        return false;
    }
    puznum.* = @intCast(sznum);
    return true;
}

pub export fn curlx_sotouz_fits(sonum: i64, puznum: *usize) callconv(.c) bool {
    if (sonum < 0) {
        puznum.* = 0;
        return false;
    }
    const u: u64 = @intCast(sonum);
    if (u > @as(u64, std.math.maxInt(usize))) {
        puznum.* = 0;
        return false;
    }
    puznum.* = @intCast(u);
    return true;
}

pub export fn curlx_sltouz(slnum: c_long, puznum: *usize) callconv(.c) bool {
    if (slnum < 0) {
        puznum.* = 0;
        return false;
    }
    puznum.* = @intCast(slnum);
    return true;
}

pub export fn curlx_uztoso(uznum: usize) callconv(.c) i64 {
    const max_off: u64 = @intCast(std.math.maxInt(i64));
    if (@as(u64, @intCast(uznum)) > max_off) {
        return std.math.maxInt(i64);
    }
    return @intCast(uznum);
}

// ============================================================================
// 7. lib/curlx/snprintf.c (lib/curlx/snprintf.h)
// ============================================================================

const win32_snprintf = if (builtin.os.tag == .windows) struct {
    extern fn vsnprintf(buf: [*]u8, maxlen: usize, fmt: [*:0]const u8, ap: [*]usize) callconv(.c) c_int;

    pub fn curlx_win32_snprintf(
        buf: [*]u8,
        maxlen: usize,
        fmt: [*:0]const u8,
        a0: usize,
        a1: usize,
        a2: usize,
        a3: usize,
    ) callconv(.c) void {
        if (maxlen == 0) return;
        var va_args = [_]usize{ a0, a1, a2, a3 };
        _ = vsnprintf(buf, maxlen, fmt, &va_args);
        buf[maxlen - 1] = 0;
    }
} else struct {};

comptime {
    if (builtin.os.tag == .windows) {
        @export(&win32_snprintf.curlx_win32_snprintf, .{ .name = "curlx_win32_snprintf", .linkage = .strong });
    }
}

// ============================================================================
// Unit Tests
// ============================================================================

test "Curl_touppermap and Curl_tolowermap" {
    for (0..256) |i| {
        const b: u8 = @intCast(i);
        if (b >= 'a' and b <= 'z') {
            try std.testing.expectEqual(b - 32, Curl_touppermap[i]);
        } else {
            try std.testing.expectEqual(b, Curl_touppermap[i]);
        }
        if (b >= 'A' and b <= 'Z') {
            try std.testing.expectEqual(b + 32, Curl_tolowermap[i]);
        } else {
            try std.testing.expectEqual(b, Curl_tolowermap[i]);
        }
    }
}

test "Curl_strntoupper and Curl_strntolower" {
    var buf: [16]u8 = @splat(0xAA);
    const src = "Hello, World! 123";

    // n == 0 should not modify dest
    Curl_strntoupper(&buf, src.ptr, 0);
    try std.testing.expectEqual(@as(u8, 0xAA), buf[0]);

    // Truncated copy (no NUL written if limit reached)
    Curl_strntoupper(&buf, src.ptr, 5);
    try std.testing.expectEqualStrings("HELLO", buf[0..5]);
    try std.testing.expectEqual(@as(u8, 0xAA), buf[5]);

    // Copy with NUL termination when n > src.len
    var buf2: [32]u8 = @splat(0xBB);
    Curl_strntolower(&buf2, "AbCdEf", buf2.len);
    try std.testing.expectEqualStrings("abcdef", std.mem.sliceTo(&buf2, 0));
    try std.testing.expectEqual(@as(u8, 0), buf2[6]);
    try std.testing.expectEqual(@as(u8, 0xBB), buf2[7]);

    // In-place (overlapping) conversion
    var inplace = "MiXeD_CaSe_99\x00".*;
    Curl_strntoupper(&inplace, &inplace, inplace.len);
    try std.testing.expectEqualStrings("MIXED_CASE_99", inplace[0..13]);
    Curl_strntolower(&inplace, &inplace, inplace.len);
    try std.testing.expectEqualStrings("mixed_case_99", inplace[0..13]);
}

test "Curl_safecmp and Curl_timestrcmp" {
    try std.testing.expect(Curl_safecmp(null, null));
    try std.testing.expect(!Curl_safecmp("abc", null));
    try std.testing.expect(!Curl_safecmp(null, "abc"));
    try std.testing.expect(Curl_safecmp("abc", "abc"));
    try std.testing.expect(!Curl_safecmp("abc", "ABC"));
    try std.testing.expect(!Curl_safecmp("abc", "abcd"));

    try std.testing.expectEqual(@as(c_int, 0), Curl_timestrcmp(null, null));
    try std.testing.expect(Curl_timestrcmp("abc", null) != 0);
    try std.testing.expect(Curl_timestrcmp(null, "abc") != 0);
    try std.testing.expectEqual(@as(c_int, 0), Curl_timestrcmp("", ""));
    try std.testing.expectEqual(@as(c_int, 0), Curl_timestrcmp("secret", "secret"));
    try std.testing.expect(Curl_timestrcmp("secret", "secreT") != 0);
    try std.testing.expect(Curl_timestrcmp("secret", "secret2") != 0);
    try std.testing.expect(Curl_timestrcmp("secret2", "secret") != 0);
}

test "curl_strequal and curl_strnequal" {
    try std.testing.expectEqual(@as(c_int, 1), curl_strequal(null, null));
    try std.testing.expectEqual(@as(c_int, 0), curl_strequal("a", null));
    try std.testing.expectEqual(@as(c_int, 0), curl_strequal(null, "a"));
    try std.testing.expectEqual(@as(c_int, 1), curl_strequal("Content-Type", "content-type"));
    try std.testing.expectEqual(@as(c_int, 0), curl_strequal("Content-Type", "content-type-x"));
    try std.testing.expectEqual(@as(c_int, 0), curl_strequal("Content-Type-x", "content-type"));

    // Turkish 'i' / 'I' ASCII-only check
    try std.testing.expectEqual(@as(c_int, 1), curl_strequal("iI", "Ii"));

    // curl_strnequal edge cases
    try std.testing.expectEqual(@as(c_int, 1), curl_strnequal(null, null, 5));
    try std.testing.expectEqual(@as(c_int, 0), curl_strnequal(null, null, 0));
    try std.testing.expectEqual(@as(c_int, 0), curl_strnequal("a", null, 0));
    try std.testing.expectEqual(@as(c_int, 0), curl_strnequal(null, "a", 0));
    try std.testing.expectEqual(@as(c_int, 1), curl_strnequal("abc", "xyz", 0));
    try std.testing.expectEqual(@as(c_int, 1), curl_strnequal("HTTP/1.1", "http/2", 5));
    try std.testing.expectEqual(@as(c_int, 0), curl_strnequal("HTTP/1.1", "http/2", 6));
    try std.testing.expectEqual(@as(c_int, 0), curl_strnequal("ab", "abc", 5));
    try std.testing.expectEqual(@as(c_int, 1), curl_strnequal("ab", "ab", 5));
}

test "Curl_read16_le, Curl_read32_le, Curl_read16_be" {
    const bytes = [_]u8{ 0x12, 0x34, 0x56, 0x78 };
    try std.testing.expectEqual(@as(c_ushort, 0x3412), Curl_read16_le(&bytes));
    try std.testing.expectEqual(@as(c_ushort, 0x1234), Curl_read16_be(&bytes));
    try std.testing.expectEqual(@as(c_uint, 0x78563412), Curl_read32_le(&bytes));
}

test "Curl_memrchr" {
    const data = "abca_bc_a";
    try std.testing.expectEqual(@as(?*anyopaque, null), Curl_memrchr(data.ptr, 'a', 0));
    try std.testing.expectEqual(@as(?*anyopaque, null), Curl_memrchr(null, 'a', 5));
    try std.testing.expectEqual(@as(?*anyopaque, null), Curl_memrchr(data.ptr, 'z', data.len));

    const last_a = Curl_memrchr(data.ptr, 'a', data.len);
    try std.testing.expectEqual(@as(?*anyopaque, @constCast(&data[8])), last_a);

    const mid_a = Curl_memrchr(data.ptr, 'a', 8);
    try std.testing.expectEqual(@as(?*anyopaque, @constCast(&data[3])), mid_a);

    const first_a = Curl_memrchr(data.ptr, 'a', 3);
    try std.testing.expectEqual(@as(?*anyopaque, @constCast(&data[0])), first_a);
}

test "curlx_strcopy" {
    var dest: [6]u8 = @splat(0xFF);
    curlx_strcopy(&dest, dest.len, "hello", 5);
    try std.testing.expectEqualStrings("hello", dest[0..5]);
    try std.testing.expectEqual(@as(u8, 0), dest[5]);

    // slen == dsize -> too small, writes NUL at dest[0]
    dest = @splat(0xFF);
    curlx_strcopy(&dest, 5, "hello", 5);
    try std.testing.expectEqual(@as(u8, 0), dest[0]);
    try std.testing.expectEqual(@as(u8, 0xFF), dest[1]);

    // dsize == 0 -> does not touch dest
    dest = @splat(0xFF);
    curlx_strcopy(&dest, 0, "hello", 5);
    try std.testing.expectEqual(@as(u8, 0xFF), dest[0]);

    // slen == 0, dsize > 0 -> writes NUL at dest[0]
    dest = @splat(0xFF);
    curlx_strcopy(&dest, dest.len, "", 0);
    try std.testing.expectEqual(@as(u8, 0), dest[0]);
}

test "curlx_warnless conversions" {
    try std.testing.expectEqual(@as(u8, 0xFE), curlx_ultouc(0x1FE));
    try std.testing.expectEqual(@as(c_int, 12345), curlx_uztosi(12345));
    try std.testing.expectEqual(@as(c_ulong, 67890), curlx_uztoul(67890));
    try std.testing.expectEqual(@as(c_uint, 54321), curlx_uztoui(54321));
    try std.testing.expectEqual(@as(c_int, 42), curlx_sltosi(42));
    try std.testing.expectEqual(@as(c_uint, 42), curlx_sltoui(42));
    try std.testing.expectEqual(@as(c_ushort, 65535), curlx_sltous(65535));
    try std.testing.expectEqual(@as(isize, 1024), curlx_uztosz(1024));
    try std.testing.expectEqual(@as(usize, 2048), curlx_sotouz(2048));
    try std.testing.expectEqual(@as(c_int, 99), curlx_sztosi(99));
    try std.testing.expectEqual(@as(c_ushort, 1000), curlx_uitous(1000));
    try std.testing.expectEqual(@as(usize, 77), curlx_sitouz(77));
    try std.testing.expectEqual(@as(usize, 88), curlx_uitouz(88));

    try std.testing.expectEqual(@as(usize, 10), curlx_sotouz_range(-5, 10, 100));
    try std.testing.expectEqual(@as(usize, 50), curlx_sotouz_range(50, 10, 100));
    try std.testing.expectEqual(@as(usize, 100), curlx_sotouz_range(500, 10, 100));

    var out: usize = 999;
    try std.testing.expect(!curlx_sztouz(-1, &out));
    try std.testing.expectEqual(@as(usize, 0), out);
    try std.testing.expect(curlx_sztouz(42, &out));
    try std.testing.expectEqual(@as(usize, 42), out);

    try std.testing.expect(!curlx_sotouz_fits(-10, &out));
    try std.testing.expectEqual(@as(usize, 0), out);
    try std.testing.expect(curlx_sotouz_fits(1234, &out));
    try std.testing.expectEqual(@as(usize, 1234), out);

    try std.testing.expect(!curlx_sltouz(-1, &out));
    try std.testing.expectEqual(@as(usize, 0), out);
    try std.testing.expect(curlx_sltouz(567, &out));
    try std.testing.expectEqual(@as(usize, 567), out);

    try std.testing.expectEqual(@as(i64, 123456), curlx_uztoso(123456));
    if (@sizeOf(usize) >= @sizeOf(i64)) {
        try std.testing.expectEqual(std.math.maxInt(i64), curlx_uztoso(std.math.maxInt(usize)));
    }
}
