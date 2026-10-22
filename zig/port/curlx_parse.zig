const std = @import("std");
const mem = @import("mem.zig");

// ============================================================================
// CURLcode constants used by curlx
// ============================================================================
pub const CURLcode = c_uint;
pub const CURLE_OK: CURLcode = 0;
pub const CURLE_OUT_OF_MEMORY: CURLcode = 27;
pub const CURLE_BAD_FUNCTION_ARGUMENT: CURLcode = 43;
pub const CURLE_BAD_CONTENT_ENCODING: CURLcode = 61;
pub const CURLE_TOO_LARGE: CURLcode = 100;

// ============================================================================
// lib/curlx/strdup.c
// ============================================================================

export fn curlx_memdup(src: ?[*]const u8, length: usize) callconv(.c) ?[*]u8 {
    const buffer = mem.allocMany(u8, length) orelse return null;
    if (length > 0) {
        if (src) |s| {
            @memcpy(buffer[0..length], s[0..length]);
        }
    }
    return buffer;
}

export fn curlx_memdup0(src: ?[*]const u8, length: usize) callconv(.c) ?[*:0]u8 {
    if (length >= std.math.maxInt(usize)) return null;
    const buf = mem.allocMany(u8, length + 1) orelse return null;
    if (length > 0) {
        const s = src orelse unreachable;
        @memcpy(buf[0..length], s[0..length]);
    }
    buf[length] = 0;
    return buf[0..length :0].ptr;
}

export fn curlx_wcsdup(src: [*:0]const u16) callconv(.c) ?[*:0]u16 {
    const length = std.mem.len(src);
    if (length > (std.math.maxInt(usize) / @sizeOf(u16)) - 1) {
        return null;
    }
    const dst = mem.allocMany(u16, length + 1) orelse return null;
    @memcpy(dst[0 .. length + 1], src[0 .. length + 1]);
    return dst[0..length :0].ptr;
}

export fn curlx_memzero_low(buf: ?[*]u8, size: usize) callconv(.c) void {
    if (buf) |p| {
        if (size > 0) {
            std.crypto.secureZero(u8, p[0..size]);
        }
    }
}

export fn curlx_memzero(buf: ?[*]u8, size: usize) callconv(.c) void {
    curlx_memzero_low(buf, size);
}

export fn curlx_strzero(buf: ?[*:0]u8) callconv(.c) void {
    if (buf) |s| {
        const len = std.mem.len(s);
        if (len > 0) {
            std.crypto.secureZero(u8, s[0..len]);
        }
    }
}

// ============================================================================
// lib/curlx/basename.c
// ============================================================================

export fn curlx_basename(path: [*:0]u8) callconv(.c) [*:0]u8 {
    const slice = std.mem.span(path);
    const s1 = std.mem.lastIndexOfScalar(u8, slice, '/');
    const s2 = std.mem.lastIndexOfScalar(u8, slice, '\\');
    const idx: ?usize = if (s1 != null and s2 != null)
        @max(s1.?, s2.?)
    else if (s1 != null)
        s1
    else
        s2;
    if (idx) |i| {
        return path + i + 1;
    }
    return path;
}

// ============================================================================
// lib/curlx/strparse.c
// ============================================================================

pub const STRE_OK: c_int = 0;
pub const STRE_BIG: c_int = 1;
pub const STRE_SHORT: c_int = 2;
pub const STRE_BEGQUOTE: c_int = 3;
pub const STRE_ENDQUOTE: c_int = 4;
pub const STRE_BYTE: c_int = 5;
pub const STRE_NEWLINE: c_int = 6;
pub const STRE_OVERFLOW: c_int = 7;
pub const STRE_NO_NUM: c_int = 8;

pub const CURL_OFF_T_MAX: i64 = std.math.maxInt(i64);

pub const Curl_str = extern struct {
    str: ?[*]const u8,
    len: usize,
};

export const curlx_hexasciitable = [55]u8{
    16, 1, 2, 3, 4, 5, 6, 7, 8, 9, // 0x30: 0 - 9
    0,  0, 0, 0, 0, 0, 0,
    10, 11, 12, 13, 14, 15, // 0x41: A - F
    0,  0,  0,  0,  0,  0,
    0,  0,  0,  0,  0,  0,
    0,  0,  0,  0,  0,  0,
    0,  0,  0,  0,  0,  0,
    0,  0,
    10, 11, 12, 13, 14, 15, // 0x61: a - f
};

inline fn isBlank(c: u8) bool {
    return c == ' ' or c == '\t';
}

inline fn isNewline(c: u8) bool {
    return c == '\n' or c == '\r';
}

inline fn validDigit(x: u8, m: u8) bool {
    return x >= '0' and x <= m and curlx_hexasciitable[x - '0'] != 0;
}

inline fn hexVal(x: u8) u8 {
    return curlx_hexasciitable[x - '0'] & 0x0f;
}

export fn curlx_str_init(out: *Curl_str) callconv(.c) void {
    out.str = null;
    out.len = 0;
}

export fn curlx_str_assign(out: *Curl_str, str: ?[*]const u8, len: usize) callconv(.c) void {
    out.str = str;
    out.len = len;
}

export fn curlx_str_trim(out: *Curl_str, len: usize) callconv(.c) void {
    out.len -= len;
}

export fn curlx_str_until(linep: *[*:0]const u8, out: *Curl_str, max: usize, delim: u8) callconv(.c) c_int {
    var s = linep.*;
    var len: usize = 0;

    curlx_str_init(out);
    while (s[0] != 0 and s[0] != delim) {
        s += 1;
        len += 1;
        if (len > max) {
            return STRE_BIG;
        }
    }
    if (len == 0) {
        return STRE_SHORT;
    }
    out.str = linep.*;
    out.len = len;
    linep.* = s;
    return STRE_OK;
}

export fn curlx_str_word(linep: *[*:0]const u8, out: *Curl_str, max: usize) callconv(.c) c_int {
    return curlx_str_until(linep, out, max, ' ');
}

export fn curlx_str_untilnl(linep: *[*:0]const u8, out: *Curl_str, max: usize) callconv(.c) c_int {
    var s = linep.*;
    var len: usize = 0;

    curlx_str_init(out);
    while (s[0] != 0 and !isNewline(s[0])) {
        s += 1;
        len += 1;
        if (len > max) {
            return STRE_BIG;
        }
    }
    if (len == 0) {
        return STRE_SHORT;
    }
    out.str = linep.*;
    out.len = len;
    linep.* = s;
    return STRE_OK;
}

export fn curlx_str_quotedword(linep: *[*:0]const u8, out: *Curl_str, max: usize) callconv(.c) c_int {
    var s = linep.*;
    var len: usize = 0;

    curlx_str_init(out);
    if (s[0] != '"') {
        return STRE_BEGQUOTE;
    }
    s += 1;
    while (s[0] != 0 and s[0] != '"') {
        if (s[0] == '\\' and s[1] != 0) {
            s += 1;
            len += 1;
            if (len > max) {
                return STRE_BIG;
            }
        }
        s += 1;
        len += 1;
        if (len > max) {
            return STRE_BIG;
        }
    }
    if (s[0] != '"') {
        return STRE_ENDQUOTE;
    }
    out.str = linep.* + 1;
    out.len = len;
    linep.* = s + 1;
    return STRE_OK;
}

export fn curlx_str_single(linep: *[*:0]const u8, byte: u8) callconv(.c) c_int {
    if (linep.*[0] != byte) {
        return STRE_BYTE;
    }
    linep.* += 1;
    return STRE_OK;
}

export fn curlx_str_singlespace(linep: *[*:0]const u8) callconv(.c) c_int {
    return curlx_str_single(linep, ' ');
}

fn strNumBase(linep: *[*:0]const u8, nump: *i64, max: i64, base: i64) c_int {
    var num: i64 = 0;
    const m: u8 = if (base == 10) '9' else if (base == 16) 'f' else '7';
    nump.* = 0;
    var p = linep.*;
    if (!validDigit(p[0], m)) {
        return STRE_NO_NUM;
    }
    if (max < base) {
        while (true) {
            const n: i64 = hexVal(p[0]);
            p += 1;
            num = (num * base) + n;
            if (num > max) {
                return STRE_OVERFLOW;
            }
            if (!validDigit(p[0], m)) break;
        }
    } else {
        const cutoff: i64 = @divTrunc(max - (base - 1), base);
        while (validDigit(p[0], m)) {
            if (num <= cutoff) {
                num = (num * base) + @as(i64, hexVal(p[0]));
                p += 1;
            } else {
                const n: i64 = hexVal(p[0]);
                p += 1;
                if (num > @divTrunc(max - n, base)) {
                    return STRE_OVERFLOW;
                }
                num = (num * base) + n;
            }
        }
    }
    nump.* = num;
    linep.* = p;
    return STRE_OK;
}

export fn curlx_str_number(linep: *[*:0]const u8, nump: *i64, max: i64) callconv(.c) c_int {
    return strNumBase(linep, nump, max, 10);
}

export fn curlx_str_hex(linep: *[*:0]const u8, nump: *i64, max: i64) callconv(.c) c_int {
    return strNumBase(linep, nump, max, 16);
}

export fn curlx_str_octal(linep: *[*:0]const u8, nump: *i64, max: i64) callconv(.c) c_int {
    return strNumBase(linep, nump, max, 8);
}

export fn curlx_str_numblanks(str: *[*:0]const u8, num: *i64) callconv(.c) c_int {
    curlx_str_passblanks(str);
    return curlx_str_number(str, num, CURL_OFF_T_MAX);
}

export fn curlx_str_newline(linep: *[*:0]const u8) callconv(.c) c_int {
    if (isNewline(linep.*[0])) {
        linep.* += 1;
        return STRE_OK;
    }
    return STRE_NEWLINE;
}

export fn curlx_str_casecompare(str: *Curl_str, check: ?[*:0]const u8) callconv(.c) c_int {
    const c_str = check orelse return 0;
    const s = str.str orelse return 0;
    const clen = std.mem.len(c_str);
    if (str.len != clen) return 0;
    return @intFromBool(std.ascii.eqlIgnoreCase(s[0..clen], c_str[0..clen]));
}

export fn curlx_str_cmp(str: *Curl_str, check: ?[*:0]const u8) callconv(.c) c_int {
    if (check) |c_str| {
        const clen = std.mem.len(c_str);
        if (str.len != clen) return 0;
        if (clen == 0) return 1;
        const s = str.str orelse return 0;
        return @intFromBool(std.mem.eql(u8, s[0..clen], c_str[0..clen]));
    }
    return @intFromBool(str.len != 0);
}

export fn curlx_str_nudge(str: *Curl_str, num: usize) callconv(.c) c_int {
    if (num <= str.len) {
        if (str.str) |s| {
            str.str = s + num;
        }
        str.len -= num;
        return STRE_OK;
    }
    return STRE_OVERFLOW;
}

export fn curlx_str_cspn(linep: *[*:0]const u8, out: *Curl_str, reject: [*:0]const u8) callconv(.c) c_int {
    const s = linep.*;
    const rej_slice = std.mem.span(reject);
    var len: usize = 0;
    while (s[len] != 0) : (len += 1) {
        if (std.mem.indexOfScalar(u8, rej_slice, s[len]) != null) break;
    }
    if (len > 0) {
        out.str = s;
        out.len = len;
        linep.* = s + len;
        return STRE_OK;
    }
    curlx_str_init(out);
    return STRE_SHORT;
}

export fn curlx_str_trimblanks(out: *Curl_str) callconv(.c) void {
    while (out.len > 0) {
        const s = out.str orelse break;
        if (!isBlank(s[0])) break;
        _ = curlx_str_nudge(out, 1);
    }
    while (out.len > 0) {
        const s = out.str orelse break;
        if (!isBlank(s[out.len - 1])) break;
        out.len -= 1;
    }
}

export fn curlx_str_passblanks(linep: *[*:0]const u8) callconv(.c) void {
    while (isBlank(linep.*[0])) {
        linep.* += 1;
    }
}

// ============================================================================
// lib/curlx/base64.c
// ============================================================================

pub const CURL_MAX_BASE64_INPUT: usize = 16000000;

export const curlx_base64encdec: [65]u8 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/\x00".*;

const base64url: *const [64:0]u8 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_";

const decodetable = [256]u8{
    0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
    0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
    0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
    0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
    0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
    0xff, 0xff, 0xff, 62,   0xff, 0xff, 0xff, 63,
    52,   53,   54,   55,   56,   57,   58,   59,
    60,   61,   0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
    0xff, 0,    1,    2,    3,    4,    5,    6,
    7,    8,    9,    10,   11,   12,   13,   14,
    15,   16,   17,   18,   19,   20,   21,   22,
    23,   24,   25,   0xff, 0xff, 0xff, 0xff, 0xff,
    0xff, 26,   27,   28,   29,   30,   31,   32,
    33,   34,   35,   36,   37,   38,   39,   40,
    41,   42,   43,   44,   45,   46,   47,   48,
    49,   50,   51,   0xff, 0xff, 0xff, 0xff, 0xff,
    0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
    0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
    0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
    0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
    0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
    0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
    0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
    0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
    0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
    0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
    0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
    0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
    0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
    0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
    0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
    0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
};

fn base64DecodeInner(src_in: [*:0]const u8) error{ OutOfMemory, BadContentEncoding }![:0]u8 {
    var src: [*]const u8 = src_in;
    const srclen = std.mem.len(src_in);

    if (srclen == 0 or (srclen % 4) != 0) {
        return error.BadContentEncoding;
    }

    var padding: usize = 0;
    while (src[srclen - 1 - padding] == '=') {
        padding += 1;
        if (padding > 2) {
            return error.BadContentEncoding;
        }
    }

    const num_quantums = srclen / 4;
    const full_quantums = num_quantums - (if (padding != 0) @as(usize, 1) else 0);
    const rawlen = (num_quantums * 3) - padding;

    const newstr = mem.allocMany(u8, rawlen + 1) orelse return error.OutOfMemory;
    errdefer mem.destroy(newstr);
    var pos: [*]u8 = newstr;

    var i: usize = 0;
    while (i < full_quantums) : (i += 1) {
        const v0 = decodetable[src[0]];
        const v1 = decodetable[src[1]];
        const v2 = decodetable[src[2]];
        const v3 = decodetable[src[3]];
        if (((v0 | v1 | v2 | v3) & 0x80) != 0) {
            return error.BadContentEncoding;
        }
        pos[0] = (v0 << 2) | (v1 >> 4);
        pos[1] = (v1 << 4) | (v2 >> 2);
        pos[2] = (v2 << 6) | v3;
        pos += 3;
        src += 4;
    }

    if (padding != 0) {
        var x: u32 = 0;
        var padc: usize = 0;
        var j: usize = 0;
        while (j < 4) : (j += 1) {
            if (src[0] == '=') {
                x <<= 6;
                src += 1;
                padc += 1;
                if (padc > padding) {
                    return error.BadContentEncoding;
                }
            } else {
                const val = decodetable[src[0]];
                src += 1;
                if (val == 0xff) {
                    return error.BadContentEncoding;
                }
                x = (x << 6) | val;
            }
        }
        if (padding == 1) {
            pos[1] = @truncate((x >> 8) & 0xff);
        }
        pos[0] = @truncate((x >> 16) & 0xff);
        pos += 3 - padding;
    }

    pos[0] = 0;
    return newstr[0..rawlen :0];
}

pub export fn curlx_base64_decode(
    src_in: [*:0]const u8,
    outptr: *?[*:0]u8,
    outlen: *usize,
) callconv(.c) CURLcode {
    outptr.* = null;
    outlen.* = 0;

    const decoded = base64DecodeInner(src_in) catch |err| return switch (err) {
        error.OutOfMemory => CURLE_OUT_OF_MEMORY,
        error.BadContentEncoding => CURLE_BAD_CONTENT_ENCODING,
    };
    outptr.* = decoded.ptr;
    outlen.* = decoded.len;
    return CURLE_OK;
}

fn base64Encode(
    table64: [*]const u8,
    padbyte: u8,
    inputbuff: ?[*]const u8,
    insize_in: usize,
    outptr: *?[*:0]u8,
    outlen: *usize,
) CURLcode {
    outptr.* = null;
    outlen.* = 0;

    var insize = insize_in;
    if (insize == 0) {
        return CURLE_OK;
    }

    if (insize > CURL_MAX_BASE64_INPUT) {
        return CURLE_TOO_LARGE;
    }

    const alloc_len = ((insize + 2) / 3 * 4) + 1;
    const base64data = mem.malloc(alloc_len) orelse return CURLE_OUT_OF_MEMORY;
    var output: [*]u8 = base64data;
    var in: [*]const u8 = inputbuff.?;

    while (insize >= 3) {
        const bits: u32 = (@as(u32, in[0]) << 16) | (@as(u32, in[1]) << 8) | @as(u32, in[2]);
        output[0] = table64[bits >> 18];
        output[1] = table64[(bits >> 12) & 0x3F];
        output[2] = table64[(bits >> 6) & 0x3F];
        output[3] = table64[bits & 0x3F];
        output += 4;
        insize -= 3;
        in += 3;
    }

    if (insize != 0) {
        output[0] = table64[in[0] >> 2];
        output += 1;
        if (insize == 1) {
            output[0] = table64[(in[0] & 0x03) << 4];
            output += 1;
            if (padbyte != 0) {
                output[0] = padbyte;
                output[1] = padbyte;
                output += 2;
            }
        } else {
            output[0] = table64[((in[0] & 0x03) << 4) | ((in[1] & 0xF0) >> 4)];
            output[1] = table64[(in[1] & 0x0F) << 2];
            output += 2;
            if (padbyte != 0) {
                output[0] = padbyte;
                output += 1;
            }
        }
    }

    output[0] = 0;
    const encoded_len = @intFromPtr(output) - @intFromPtr(base64data);
    outptr.* = base64data[0..encoded_len :0].ptr;
    outlen.* = encoded_len;
    return CURLE_OK;
}

pub export fn curlx_base64_encode(
    inputbuff: ?[*]const u8,
    insize: usize,
    outptr: *?[*:0]u8,
    outlen: *usize,
) callconv(.c) CURLcode {
    return base64Encode(&curlx_base64encdec, '=', inputbuff, insize, outptr, outlen);
}

export fn curlx_base64url_encode(
    inputbuff: ?[*]const u8,
    insize: usize,
    outptr: *?[*:0]u8,
    outlen: *usize,
) callconv(.c) CURLcode {
    return base64Encode(base64url, 0, inputbuff, insize, outptr, outlen);
}

// ============================================================================
// Unit Tests
// ============================================================================

test "curlx_memdup, curlx_memdup0, curlx_wcsdup, curlx_memzero, curlx_strzero" {
    const src = "abcdef";
    const dup_bytes = curlx_memdup(src.ptr, src.len) orelse return error.OutOfMemory;
    defer mem.free(dup_bytes);
    try std.testing.expectEqualStrings("abcdef", dup_bytes[0..src.len]);

    const dup0_str = curlx_memdup0(src.ptr, 3) orelse return error.OutOfMemory;
    defer mem.free(dup0_str);
    try std.testing.expectEqualStrings("abc", std.mem.span(dup0_str));

    const empty0_str = curlx_memdup0(null, 0) orelse return error.OutOfMemory;
    defer mem.free(empty0_str);
    try std.testing.expectEqualStrings("", std.mem.span(empty0_str));

    try std.testing.expect(curlx_memdup0(src.ptr, std.math.maxInt(usize)) == null);

    curlx_strzero(dup0_str);
    try std.testing.expectEqual(@as(u8, 0), dup0_str[0]);
    try std.testing.expectEqual(@as(u8, 0), dup0_str[1]);
    try std.testing.expectEqual(@as(u8, 0), dup0_str[2]);

    curlx_memzero(dup_bytes, src.len);
    for (dup_bytes[0..src.len]) |b| {
        try std.testing.expectEqual(@as(u8, 0), b);
    }

    const wsrc = [_:0]u16{ 'c', 'u', 'r', 'l' };
    const wdup = curlx_wcsdup(&wsrc) orelse return error.OutOfMemory;
    defer mem.free(wdup);
    try std.testing.expectEqualSlices(u16, &wsrc, std.mem.span(wdup));
}

test "curlx_basename" {
    var p1 = "foo/bar/baz.txt".*;
    try std.testing.expectEqualStrings("baz.txt", std.mem.span(curlx_basename(&p1)));

    var p2 = "C:\\dir\\sub\\file.exe".*;
    try std.testing.expectEqualStrings("file.exe", std.mem.span(curlx_basename(&p2)));

    var p3 = "mixed/path\\to/leaf".*;
    try std.testing.expectEqualStrings("leaf", std.mem.span(curlx_basename(&p3)));

    var p4 = "mixed\\path/to\\winleaf".*;
    try std.testing.expectEqualStrings("winleaf", std.mem.span(curlx_basename(&p4)));

    var p5 = "trailing/".*;
    try std.testing.expectEqualStrings("", std.mem.span(curlx_basename(&p5)));

    var p6 = "noslash".*;
    try std.testing.expectEqualStrings("noslash", std.mem.span(curlx_basename(&p6)));
}

test "curlx_str_word, curlx_str_until, curlx_str_untilnl, curlx_str_quotedword" {
    var out: Curl_str = undefined;

    var line: [*:0]const u8 = "hello world\r\n";
    try std.testing.expectEqual(STRE_OK, curlx_str_word(&line, &out, 10));
    try std.testing.expectEqual(@as(usize, 5), out.len);
    try std.testing.expectEqualStrings("hello", out.str.?[0..out.len]);
    try std.testing.expectEqual(STRE_OK, curlx_str_singlespace(&line));

    try std.testing.expectEqual(STRE_OK, curlx_str_untilnl(&line, &out, 10));
    try std.testing.expectEqualStrings("world", out.str.?[0..out.len]);
    try std.testing.expectEqual(STRE_OK, curlx_str_newline(&line));
    try std.testing.expectEqual(STRE_OK, curlx_str_newline(&line));
    try std.testing.expectEqual(STRE_NEWLINE, curlx_str_newline(&line));

    // STRE_BIG and STRE_SHORT
    line = "longerth";
    try std.testing.expectEqual(STRE_BIG, curlx_str_word(&line, &out, 7));
    try std.testing.expectEqualStrings("longerth", std.mem.span(line));
    line = " leading";
    try std.testing.expectEqual(STRE_SHORT, curlx_str_word(&line, &out, 7));

    // Quoted words (from unit1664)
    line = "\"perfect\" rest";
    try std.testing.expectEqual(STRE_OK, curlx_str_quotedword(&line, &out, 7));
    try std.testing.expectEqualStrings("perfect", out.str.?[0..out.len]);
    try std.testing.expectEqualStrings(" rest", std.mem.span(line));

    line = "\"trail\\\"\"";
    try std.testing.expectEqual(STRE_OK, curlx_str_quotedword(&line, &out, 7));
    try std.testing.expectEqualStrings("trail\\\"", out.str.?[0..out.len]);

    line = "\"trail2\\\"\"";
    try std.testing.expectEqual(STRE_BIG, curlx_str_quotedword(&line, &out, 7));

    line = "\"perfec\\\"";
    try std.testing.expectEqual(STRE_BIG, curlx_str_quotedword(&line, &out, 7));

    line = "\"word";
    try std.testing.expectEqual(STRE_ENDQUOTE, curlx_str_quotedword(&line, &out, 7));

    line = "noquote\"";
    try std.testing.expectEqual(STRE_BEGQUOTE, curlx_str_quotedword(&line, &out, 7));

    line = "\"\"";
    try std.testing.expectEqual(STRE_OK, curlx_str_quotedword(&line, &out, 7));
    try std.testing.expectEqual(@as(usize, 0), out.len);
}

test "curlx_str_number, curlx_str_hex, curlx_str_octal, curlx_str_numblanks" {
    var num: i64 = -1;
    var line: [*:0]const u8 = "1234";
    try std.testing.expectEqual(STRE_OK, curlx_str_number(&line, &num, 1235));
    try std.testing.expectEqual(@as(i64, 1234), num);
    try std.testing.expectEqual(@as(u8, 0), line[0]);

    line = "1236";
    try std.testing.expectEqual(STRE_OVERFLOW, curlx_str_number(&line, &num, 1235));
    try std.testing.expectEqualStrings("1236", std.mem.span(line));

    line = "-12";
    try std.testing.expectEqual(STRE_NO_NUM, curlx_str_number(&line, &num, 1235));

    // Low max (< base) edge cases from unit1664
    line = "000000000000000000000006";
    try std.testing.expectEqual(STRE_OK, curlx_str_number(&line, &num, 6));
    try std.testing.expectEqual(@as(i64, 6), num);

    line = "7";
    try std.testing.expectEqual(STRE_OVERFLOW, curlx_str_number(&line, &num, 6));

    // 63-bit boundary (CURL_OFF_T_MAX)
    line = "9223372036854775807";
    try std.testing.expectEqual(STRE_OK, curlx_str_number(&line, &num, CURL_OFF_T_MAX));
    try std.testing.expectEqual(CURL_OFF_T_MAX, num);

    line = "9223372036854775808";
    try std.testing.expectEqual(STRE_OVERFLOW, curlx_str_number(&line, &num, CURL_OFF_T_MAX));

    // Hex
    line = "7FFFFFFFFFFFFFFF";
    try std.testing.expectEqual(STRE_OK, curlx_str_hex(&line, &num, CURL_OFF_T_MAX));
    try std.testing.expectEqual(CURL_OFF_T_MAX, num);

    line = "8000000000000000";
    try std.testing.expectEqual(STRE_OVERFLOW, curlx_str_hex(&line, &num, CURL_OFF_T_MAX));

    line = "f";
    try std.testing.expectEqual(STRE_OVERFLOW, curlx_str_hex(&line, &num, 14));
    try std.testing.expectEqual(STRE_OK, curlx_str_hex(&line, &num, 15));
    try std.testing.expectEqual(@as(i64, 15), num);

    // Octal
    line = "777777777777777777777";
    try std.testing.expectEqual(STRE_OK, curlx_str_octal(&line, &num, CURL_OFF_T_MAX));
    try std.testing.expectEqual(CURL_OFF_T_MAX, num);

    line = "1000000000000000000000";
    try std.testing.expectEqual(STRE_OVERFLOW, curlx_str_octal(&line, &num, CURL_OFF_T_MAX));

    line = "8";
    try std.testing.expectEqual(STRE_NO_NUM, curlx_str_octal(&line, &num, 10));

    // numblanks
    line = " \t  42abc";
    try std.testing.expectEqual(STRE_OK, curlx_str_numblanks(&line, &num));
    try std.testing.expectEqual(@as(i64, 42), num);
    try std.testing.expectEqualStrings("abc", std.mem.span(line));
}

test "curlx_str_casecompare, curlx_str_cmp, curlx_str_cspn, curlx_str_trimblanks" {
    var s: Curl_str = undefined;
    var line: [*:0]const u8 = "  \tHello,World;next";
    curlx_str_assign(&s, line, 14);
    curlx_str_trimblanks(&s);
    try std.testing.expectEqual(@as(usize, 11), s.len);
    try std.testing.expectEqualStrings("Hello,World", s.str.?[0..s.len]);

    try std.testing.expectEqual(@as(c_int, 1), curlx_str_casecompare(&s, "hello,world"));
    try std.testing.expectEqual(@as(c_int, 0), curlx_str_casecompare(&s, "hello,worl"));
    try std.testing.expectEqual(@as(c_int, 1), curlx_str_cmp(&s, "Hello,World"));
    try std.testing.expectEqual(@as(c_int, 0), curlx_str_cmp(&s, "hello,world"));

    curlx_str_trim(&s, 6);
    try std.testing.expectEqual(@as(c_int, 1), curlx_str_cmp(&s, "Hello"));

    line = "token1;token2";
    try std.testing.expectEqual(STRE_OK, curlx_str_cspn(&line, &s, ";:"));
    try std.testing.expectEqualStrings("token1", s.str.?[0..s.len]);
    try std.testing.expectEqual(STRE_SHORT, curlx_str_cspn(&line, &s, ";:"));
}

test "curlx_base64_encode, curlx_base64url_encode, curlx_base64_decode (unit1302)" {
    const ETest = struct {
        input: []const u8,
        output: [:0]const u8,
    };

    const encode_cases = [_]ETest{
        .{ .input = "i", .output = "aQ==" },
        .{ .input = "ii", .output = "aWk=" },
        .{ .input = "iii", .output = "aWlp" },
        .{ .input = "iiii", .output = "aWlpaQ==" },
        .{ .input = "iiiii", .output = "aWlpaWk=" },
        .{ .input = "iiiiii", .output = "aWlpaWlp" },
        .{ .input = "\xff\x01\xfe\x02", .output = "/wH+Ag==" },
        .{ .input = "\xff\xff\xff\xff", .output = "/////w==" },
        .{ .input = "\x00\x00\x00\x00", .output = "AAAAAA==" },
        .{ .input = "\x00", .output = "AA==" },
    };

    for (encode_cases) |tc| {
        var out: ?[*:0]u8 = null;
        var olen: usize = 0;
        try std.testing.expectEqual(CURLE_OK, curlx_base64_encode(tc.input.ptr, tc.input.len, &out, &olen));
        defer mem.free(out);
        try std.testing.expectEqual(tc.output.len, olen);
        try std.testing.expectEqualStrings(tc.output, out.?[0..olen]);

        var decoded: ?[*:0]u8 = null;
        var dlen: usize = 0;
        try std.testing.expectEqual(CURLE_OK, curlx_base64_decode(tc.output.ptr, &decoded, &dlen));
        defer mem.free(decoded);
        try std.testing.expectEqual(tc.input.len, dlen);
        try std.testing.expectEqualSlices(u8, tc.input, decoded.?[0..dlen]);
    }

    // Round-trip all 256 byte values across lengths 1..256
    var binary: [256]u8 = undefined;
    for (&binary, 0..) |*b, idx| {
        b.* = @truncate(idx);
    }
    var length: usize = 1;
    while (length <= binary.len) : (length += 1) {
        var encoded: ?[*:0]u8 = null;
        var enclen: usize = 0;
        try std.testing.expectEqual(CURLE_OK, curlx_base64_encode(&binary, length, &encoded, &enclen));
        try std.testing.expectEqual((length + 2) / 3 * 4, enclen);
        try std.testing.expectEqual(@as(u8, 0), encoded.?[enclen]);

        var decoded: ?[*:0]u8 = null;
        var declen: usize = 0;
        try std.testing.expectEqual(CURLE_OK, curlx_base64_decode(encoded.?, &decoded, &declen));
        mem.free(encoded);
        defer mem.free(decoded);
        try std.testing.expectEqual(length, declen);
        try std.testing.expectEqualSlices(u8, binary[0..length], decoded.?[0..declen]);
        try std.testing.expectEqual(@as(u8, 0), decoded.?[declen]);
    }

    const url_cases = [_]ETest{
        .{ .input = "", .output = "" },
        .{ .input = "i", .output = "aQ" },
        .{ .input = "ii", .output = "aWk" },
        .{ .input = "iii", .output = "aWlp" },
        .{ .input = "\xff\x01\xfe\x02", .output = "_wH-Ag" },
        .{ .input = "\xff\xff\xff\xff", .output = "_____w" },
        .{ .input = "\xff\x00\xff\x00", .output = "_wD_AA" },
        .{ .input = "\x00\xff\x00\xff", .output = "AP8A_w" },
    };

    for (url_cases) |tc| {
        var out: ?[*:0]u8 = null;
        var olen: usize = 0;
        try std.testing.expectEqual(CURLE_OK, curlx_base64url_encode(tc.input.ptr, tc.input.len, &out, &olen));
        defer mem.free(out);
        try std.testing.expectEqual(tc.output.len, olen);
        if (olen > 0) {
            try std.testing.expectEqualStrings(tc.output, out.?[0..olen]);
        } else {
            try std.testing.expect(out == null);
        }
    }

    const bad_inputs = [_][:0]const u8{
        "",
        "a",
        "aQ",
        "aQ=",
        "====",
        "a===",
        "a=Q=",
        "aWlpa=Q=",
        "a\x1f==",
        "abcd ",
        "abcd  ",
        " abcd",
        "_abcd",
        "abcd-",
        "abcd_",
        "aWlpaWlpaQ==-",
        "aWlpaWlpaQ==_",
        "aWlpaWlpaQ== ",
        "aWlpaWlpaQ=",
    };

    for (bad_inputs) |bad| {
        var decoded: ?[*:0]u8 = null;
        var dlen: usize = 0;
        try std.testing.expectEqual(CURLE_BAD_CONTENT_ENCODING, curlx_base64_decode(bad.ptr, &decoded, &dlen));
        try std.testing.expect(decoded == null);
        try std.testing.expectEqual(@as(usize, 0), dlen);
    }
}
