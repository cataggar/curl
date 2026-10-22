const std = @import("std");
const builtin = @import("builtin");
const mem = @import("mem.zig");

pub const CURLcode = c_uint;
pub const CURLE_OK: CURLcode = 0;
pub const CURLE_FAILED_INIT: CURLcode = 2;
pub const CURLE_OUT_OF_MEMORY: CURLcode = 27;
pub const CURLE_BAD_FUNCTION_ARGUMENT: CURLcode = 43;

// ============================================================================
// Generic Hash Context Adapter (unaligned-safe for C callers and HMAC_context)
// ============================================================================

fn HashAdapter(comptime Hasher: type) type {
    return struct {
        const ctx_size = @sizeOf(Hasher);

        fn ctxBytes(context: ?*anyopaque) *[ctx_size]u8 {
            return @ptrCast(context.?);
        }

        fn init(context: ?*anyopaque) callconv(.c) CURLcode {
            const bytes = ctxBytes(context);
            const h = Hasher.init(.{});
            @memcpy(bytes, std.mem.asBytes(&h));
            return CURLE_OK;
        }

        fn update(context: ?*anyopaque, data: ?[*]const u8, len: c_uint) callconv(.c) void {
            if (len == 0) return;
            const d = data orelse return;
            const bytes = ctxBytes(context);
            var h: Hasher = undefined;
            @memcpy(std.mem.asBytes(&h), bytes);
            h.update(d[0..len]);
            @memcpy(bytes, std.mem.asBytes(&h));
        }

        fn final(result: [*]u8, context: ?*anyopaque) callconv(.c) void {
            const bytes = ctxBytes(context);
            var h: Hasher = undefined;
            @memcpy(std.mem.asBytes(&h), bytes);
            h.final(result[0..Hasher.digest_length]);
            @memset(bytes, 0);
        }
    };
}

// ============================================================================
// 1. lib/hmac.c (lib/curl_hmac.h)
// ============================================================================

pub const HMAC_MD5_LENGTH: usize = 16;

pub const HMAC_hinit = *const fn (context: ?*anyopaque) callconv(.c) CURLcode;
pub const HMAC_hupdate = *const fn (context: ?*anyopaque, data: ?[*]const u8, len: c_uint) callconv(.c) void;
pub const HMAC_hfinal = *const fn (result: [*]u8, context: ?*anyopaque) callconv(.c) void;

pub const HMAC_params = extern struct {
    hinit: HMAC_hinit,
    hupdate: HMAC_hupdate,
    hfinal: HMAC_hfinal,
    ctxtsize: c_uint,
    maxkeylen: c_uint,
    resultlen: c_uint,
};

pub const HMAC_context = extern struct {
    hash: *const HMAC_params,
    hashctxt1: ?[*]u8,
    hashctxt2: ?[*]u8,
};

const hmac_ipad: u8 = 0x36;
const hmac_opad: u8 = 0x5C;
const hmac_ipad_arr = [1]u8{hmac_ipad};
const hmac_opad_arr = [1]u8{hmac_opad};

fn hmacInitInner(
    hashparams: *const HMAC_params,
    key: ?[*]const u8,
    keylen: c_uint,
) error{ InitFailed, OutOfMemory }!*HMAC_context {
    const total_size = @sizeOf(HMAC_context) +
        (@as(usize, 2) * @as(usize, hashparams.ctxtsize)) +
        @as(usize, hashparams.resultlen);
    const base = mem.allocMany(u8, total_size) orelse return error.OutOfMemory;
    errdefer mem.destroy(base);

    const ctxt: *HMAC_context = @ptrCast(@alignCast(base));
    const ctxt1_ptr: [*]u8 = base + @sizeOf(HMAC_context);
    const ctxt2_ptr: [*]u8 = ctxt1_ptr + @as(usize, hashparams.ctxtsize);
    const hkey_ptr: [*]u8 = ctxt2_ptr + @as(usize, hashparams.ctxtsize);

    ctxt.hash = hashparams;
    ctxt.hashctxt1 = ctxt1_ptr;
    ctxt.hashctxt2 = ctxt2_ptr;

    var effective_key = key;
    var effective_keylen = keylen;

    if (effective_keylen > hashparams.maxkeylen) {
        if (hashparams.hinit(ctxt.hashctxt1) != CURLE_OK) {
            return error.InitFailed;
        }
        hashparams.hupdate(ctxt.hashctxt1, effective_key, effective_keylen);
        hashparams.hfinal(hkey_ptr, ctxt.hashctxt1);
        effective_key = hkey_ptr;
        effective_keylen = hashparams.resultlen;
    }

    if (hashparams.hinit(ctxt.hashctxt1) != CURLE_OK or
        hashparams.hinit(ctxt.hashctxt2) != CURLE_OK)
    {
        return error.InitFailed;
    }

    var i: c_uint = 0;
    while (i < effective_keylen) : (i += 1) {
        const kbyte: u8 = if (effective_key) |k| k[i] else 0;
        var b = [1]u8{kbyte ^ hmac_ipad};
        hashparams.hupdate(ctxt.hashctxt1, &b, 1);
        b[0] = kbyte ^ hmac_opad;
        hashparams.hupdate(ctxt.hashctxt2, &b, 1);
    }

    while (i < hashparams.maxkeylen) : (i += 1) {
        hashparams.hupdate(ctxt.hashctxt1, &hmac_ipad_arr, 1);
        hashparams.hupdate(ctxt.hashctxt2, &hmac_opad_arr, 1);
    }

    return ctxt;
}

pub export fn Curl_HMAC_init(
    hashparams: *const HMAC_params,
    key: ?[*]const u8,
    keylen: c_uint,
) callconv(.c) ?*HMAC_context {
    return hmacInitInner(hashparams, key, keylen) catch null;
}

pub export fn Curl_HMAC_update(
    ctxt: *HMAC_context,
    data: ?[*]const u8,
    len: c_uint,
) callconv(.c) void {
    ctxt.hash.hupdate(ctxt.hashctxt1, data, len);
}

pub export fn Curl_HMAC_final(
    ctxt: *HMAC_context,
    output: ?[*]u8,
) callconv(.c) c_int {
    const hashparams = ctxt.hash;
    const out: [*]u8 = output orelse (ctxt.hashctxt2.? + @as(usize, hashparams.ctxtsize));

    hashparams.hfinal(out, ctxt.hashctxt1);
    hashparams.hupdate(ctxt.hashctxt2, out, hashparams.resultlen);
    hashparams.hfinal(out, ctxt.hashctxt2);
    mem.free(ctxt);
    return 0;
}

pub export fn Curl_hmacit(
    hashparams: *const HMAC_params,
    key: ?[*]const u8,
    keylen: usize,
    data: ?[*]const u8,
    datalen: usize,
    output: [*]u8,
) callconv(.c) CURLcode {
    if (keylen > @as(usize, std.math.maxInt(c_uint))) {
        return CURLE_BAD_FUNCTION_ARGUMENT;
    }
    const ctxt = Curl_HMAC_init(hashparams, key, @intCast(keylen)) orelse return CURLE_OUT_OF_MEMORY;

    var rem = datalen;
    var cur = data;
    while (true) {
        const ilen: c_uint = @intCast(@min(rem, @as(usize, std.math.maxInt(c_uint))));
        Curl_HMAC_update(ctxt, cur, ilen);
        rem -= ilen;
        if (rem == 0) break;
        if (cur) |p| {
            cur = p + ilen;
        }
    }

    _ = Curl_HMAC_final(ctxt, output);
    return CURLE_OK;
}

// ============================================================================
// 2. lib/md4.c (lib/curl_md4.h) — RFC 1320
// ============================================================================

pub const MD4_DIGEST_LENGTH: usize = 16;

pub const Md4 = struct {
    pub const block_length = 64;
    pub const digest_length = 16;
    pub const Options = struct {};

    a: u32 = 0x67452301,
    b: u32 = 0xefcdab89,
    c: u32 = 0x98badcfe,
    d: u32 = 0x10325476,
    buf: [64]u8 = undefined,
    buf_len: u8 = 0,
    total_len: u64 = 0,

    pub fn init(_: Options) Md4 {
        return .{};
    }

    fn f(x: u32, y: u32, z: u32) u32 {
        return z ^ (x & (y ^ z));
    }

    fn g(x: u32, y: u32, z: u32) u32 {
        return (x & (y | z)) | (y & z);
    }

    fn h(x: u32, y: u32, z: u32) u32 {
        return x ^ y ^ z;
    }

    inline fn step(comptime func: fn (u32, u32, u32) u32, a: *u32, b: u32, c: u32, d: u32, x: u32, comptime s: u5) void {
        a.* = std.math.rotl(u32, a.* +% func(b, c, d) +% x, s);
    }

    fn transform(self: *Md4, block: *const [64]u8) void {
        var x: [16]u32 = undefined;
        inline for (0..16) |i| {
            x[i] = std.mem.readInt(u32, block[i * 4 ..][0..4], .little);
        }

        var a = self.a;
        var b = self.b;
        var c = self.c;
        var d = self.d;

        // Round 1
        step(f, &a, b, c, d, x[0], 3);
        step(f, &d, a, b, c, x[1], 7);
        step(f, &c, d, a, b, x[2], 11);
        step(f, &b, c, d, a, x[3], 19);
        step(f, &a, b, c, d, x[4], 3);
        step(f, &d, a, b, c, x[5], 7);
        step(f, &c, d, a, b, x[6], 11);
        step(f, &b, c, d, a, x[7], 19);
        step(f, &a, b, c, d, x[8], 3);
        step(f, &d, a, b, c, x[9], 7);
        step(f, &c, d, a, b, x[10], 11);
        step(f, &b, c, d, a, x[11], 19);
        step(f, &a, b, c, d, x[12], 3);
        step(f, &d, a, b, c, x[13], 7);
        step(f, &c, d, a, b, x[14], 11);
        step(f, &b, c, d, a, x[15], 19);

        // Round 2
        const k2: u32 = 0x5a827999;
        step(g, &a, b, c, d, x[0] +% k2, 3);
        step(g, &d, a, b, c, x[4] +% k2, 5);
        step(g, &c, d, a, b, x[8] +% k2, 9);
        step(g, &b, c, d, a, x[12] +% k2, 13);
        step(g, &a, b, c, d, x[1] +% k2, 3);
        step(g, &d, a, b, c, x[5] +% k2, 5);
        step(g, &c, d, a, b, x[9] +% k2, 9);
        step(g, &b, c, d, a, x[13] +% k2, 13);
        step(g, &a, b, c, d, x[2] +% k2, 3);
        step(g, &d, a, b, c, x[6] +% k2, 5);
        step(g, &c, d, a, b, x[10] +% k2, 9);
        step(g, &b, c, d, a, x[14] +% k2, 13);
        step(g, &a, b, c, d, x[3] +% k2, 3);
        step(g, &d, a, b, c, x[7] +% k2, 5);
        step(g, &c, d, a, b, x[11] +% k2, 9);
        step(g, &b, c, d, a, x[15] +% k2, 13);

        // Round 3
        const k3: u32 = 0x6ed9eba1;
        step(h, &a, b, c, d, x[0] +% k3, 3);
        step(h, &d, a, b, c, x[8] +% k3, 9);
        step(h, &c, d, a, b, x[4] +% k3, 11);
        step(h, &b, c, d, a, x[12] +% k3, 15);
        step(h, &a, b, c, d, x[2] +% k3, 3);
        step(h, &d, a, b, c, x[10] +% k3, 9);
        step(h, &c, d, a, b, x[6] +% k3, 11);
        step(h, &b, c, d, a, x[14] +% k3, 15);
        step(h, &a, b, c, d, x[1] +% k3, 3);
        step(h, &d, a, b, c, x[9] +% k3, 9);
        step(h, &c, d, a, b, x[5] +% k3, 11);
        step(h, &b, c, d, a, x[13] +% k3, 15);
        step(h, &a, b, c, d, x[3] +% k3, 3);
        step(h, &d, a, b, c, x[11] +% k3, 9);
        step(h, &c, d, a, b, x[7] +% k3, 11);
        step(h, &b, c, d, a, x[15] +% k3, 15);

        self.a +%= a;
        self.b +%= b;
        self.c +%= c;
        self.d +%= d;
    }

    pub fn update(self: *Md4, input: []const u8) void {
        var rest = input;
        self.total_len +%= rest.len;

        if (self.buf_len > 0) {
            const avail: usize = 64 - @as(usize, self.buf_len);
            if (rest.len < avail) {
                @memcpy(self.buf[self.buf_len..][0..rest.len], rest);
                self.buf_len += @intCast(rest.len);
                return;
            }
            @memcpy(self.buf[self.buf_len..64], rest[0..avail]);
            self.transform(&self.buf);
            rest = rest[avail..];
            self.buf_len = 0;
        }

        while (rest.len >= 64) {
            self.transform(rest[0..64]);
            rest = rest[64..];
        }

        if (rest.len > 0) {
            @memcpy(self.buf[0..rest.len], rest);
            self.buf_len = @intCast(rest.len);
        }
    }

    pub fn final(self: *Md4, out: *[16]u8) void {
        var used: usize = self.buf_len;
        self.buf[used] = 0x80;
        used += 1;

        if (used > 56) {
            @memset(self.buf[used..64], 0);
            self.transform(&self.buf);
            used = 0;
        }

        @memset(self.buf[used..56], 0);
        std.mem.writeInt(u64, self.buf[56..64], self.total_len *% 8, .little);
        self.transform(&self.buf);

        std.mem.writeInt(u32, out[0..4], self.a, .little);
        std.mem.writeInt(u32, out[4..8], self.b, .little);
        std.mem.writeInt(u32, out[8..12], self.c, .little);
        std.mem.writeInt(u32, out[12..16], self.d, .little);
        self.* = .{};
    }
};

pub export fn Curl_md4it(output: [*]u8, input: ?[*]const u8, len: usize) callconv(.c) CURLcode {
    var ctx = Md4.init(.{});
    if (len > 0) {
        if (input) |in| {
            ctx.update(in[0..len]);
        }
    }
    ctx.final(output[0..MD4_DIGEST_LENGTH]);
    return CURLE_OK;
}

// ============================================================================
// 3. lib/md5.c (lib/curl_md5.h)
// ============================================================================

pub const MD5_DIGEST_LEN: usize = 16;

pub const Curl_MD5_init_func = *const fn (context: ?*anyopaque) callconv(.c) CURLcode;
pub const Curl_MD5_update_func = *const fn (context: ?*anyopaque, data: ?[*]const u8, len: c_uint) callconv(.c) void;
pub const Curl_MD5_final_func = *const fn (result: [*]u8, context: ?*anyopaque) callconv(.c) void;

pub const MD5_params = extern struct {
    md5_init_func: Curl_MD5_init_func,
    md5_update_func: Curl_MD5_update_func,
    md5_final_func: Curl_MD5_final_func,
    md5_ctxtsize: c_uint,
    md5_resultlen: c_uint,
};

pub const MD5_context = extern struct {
    md5_hash: *const MD5_params,
    md5_hashctx: ?*anyopaque,
};

const Md5Adapter = HashAdapter(std.crypto.hash.Md5);

pub export const Curl_HMAC_MD5: [1]HMAC_params = .{.{
    .hinit = Md5Adapter.init,
    .hupdate = Md5Adapter.update,
    .hfinal = Md5Adapter.final,
    .ctxtsize = @sizeOf(std.crypto.hash.Md5),
    .maxkeylen = std.crypto.hash.Md5.block_length,
    .resultlen = std.crypto.hash.Md5.digest_length,
}};

pub export const Curl_DIGEST_MD5: [1]MD5_params = .{.{
    .md5_init_func = Md5Adapter.init,
    .md5_update_func = Md5Adapter.update,
    .md5_final_func = Md5Adapter.final,
    .md5_ctxtsize = @sizeOf(std.crypto.hash.Md5),
    .md5_resultlen = std.crypto.hash.Md5.digest_length,
}};

pub export fn Curl_md5it(output: [*]u8, input: ?[*]const u8, len: usize) callconv(.c) CURLcode {
    var h = std.crypto.hash.Md5.init(.{});
    if (len > 0) {
        if (input) |in| {
            h.update(in[0..len]);
        }
    }
    h.final(output[0..MD5_DIGEST_LEN]);
    return CURLE_OK;
}

fn md5InitInner(md5params: *const MD5_params) error{ InitFailed, OutOfMemory }!*MD5_context {
    const ctxt = mem.alloc(MD5_context) orelse return error.OutOfMemory;
    errdefer mem.destroy(ctxt);

    const hashctx = mem.malloc(md5params.md5_ctxtsize) orelse return error.OutOfMemory;
    errdefer mem.destroy(hashctx);

    ctxt.md5_hash = md5params;
    ctxt.md5_hashctx = hashctx;

    if (md5params.md5_init_func(hashctx) != CURLE_OK) {
        return error.InitFailed;
    }

    return ctxt;
}

pub export fn Curl_MD5_init(md5params: *const MD5_params) callconv(.c) ?*MD5_context {
    return md5InitInner(md5params) catch null;
}

pub export fn Curl_MD5_update(
    context: *MD5_context,
    input: ?[*]const u8,
    len: c_uint,
) callconv(.c) CURLcode {
    context.md5_hash.md5_update_func(context.md5_hashctx, input, len);
    return CURLE_OK;
}

pub export fn Curl_MD5_final(
    context: *MD5_context,
    result: [*]u8,
) callconv(.c) CURLcode {
    context.md5_hash.md5_final_func(result, context.md5_hashctx);
    mem.free(context.md5_hashctx);
    mem.destroy(context);
    return CURLE_OK;
}

// ============================================================================
// 4. lib/sha256.c (lib/curl_sha256.h)
// ============================================================================

pub const CURL_SHA256_DIGEST_LENGTH: usize = 32;

const Sha256 = std.crypto.hash.sha2.Sha256;
const Sha256Adapter = HashAdapter(Sha256);

pub export const Curl_HMAC_SHA256: [1]HMAC_params = .{.{
    .hinit = Sha256Adapter.init,
    .hupdate = Sha256Adapter.update,
    .hfinal = Sha256Adapter.final,
    .ctxtsize = @sizeOf(Sha256),
    .maxkeylen = Sha256.block_length,
    .resultlen = Sha256.digest_length,
}};

pub export fn Curl_sha256it(output: [*]u8, input: ?[*]const u8, len: usize) callconv(.c) CURLcode {
    var h = Sha256.init(.{});
    if (len > 0) {
        if (input) |in| {
            h.update(in[0..len]);
        }
    }
    h.final(output[0..CURL_SHA256_DIGEST_LENGTH]);
    return CURLE_OK;
}

// ============================================================================
// 5. lib/curl_sha512_256.c (lib/curl_sha512_256.h)
// ============================================================================

pub const CURL_SHA512_256_DIGEST_LENGTH: usize = 32;

const Sha512_256 = std.crypto.hash.sha2.Sha512_256;
const Sha512_256Adapter = HashAdapter(Sha512_256);

pub export const Curl_HMAC_SHA512_256: [1]HMAC_params = .{.{
    .hinit = Sha512_256Adapter.init,
    .hupdate = Sha512_256Adapter.update,
    .hfinal = Sha512_256Adapter.final,
    .ctxtsize = @sizeOf(Sha512_256),
    .maxkeylen = Sha512_256.block_length,
    .resultlen = Sha512_256.digest_length,
}};

pub export fn Curl_sha512_256it(
    output: [*]u8,
    input: ?[*]const u8,
    input_size: usize,
) callconv(.c) CURLcode {
    var h = Sha512_256.init(.{});
    if (input_size > 0) {
        if (input) |in| {
            h.update(in[0..input_size]);
        }
    }
    h.final(output[0..CURL_SHA512_256_DIGEST_LENGTH]);
    return CURLE_OK;
}

// ============================================================================
// Unit Tests
// ============================================================================

test "Curl_md4it RFC 1320 and curl unit1611 vectors" {
    const vectors = [_]struct { input: []const u8, hex: *const [32]u8 }{
        // RFC 1320 test suite
        .{ .input = "", .hex = "31d6cfe0d16ae931b73c59d7e0c089c0" },
        .{ .input = "a", .hex = "bde52cb31de33e46245e05fbdbd6fb24" },
        .{ .input = "abc", .hex = "a448017aaf21d8525fc10ae87aa6729d" },
        .{ .input = "message digest", .hex = "d9130a8164549fe818874806e1c7014b" },
        .{ .input = "abcdefghijklmnopqrstuvwxyz", .hex = "d79e1c308aa5bbcdeea8ed63df412da9" },
        .{
            .input = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789",
            .hex = "043f8582f241db351ce627e153e7f0e4",
        },
        .{
            .input = "12345678901234567890123456789012345678901234567890123456789012345678901234567890",
            .hex = "e33b4ddc9c38f2199c3e7b164fcc0536",
        },
        // tests/unit/unit1611.c vectors
        .{ .input = "1", .hex = "8be1ec697b14ad3a53b371436120641d" },
        .{ .input = "hello-you-fool", .hex = "a7161cad7ebedbbcf8c723102d2ce20b" },
    };

    for (vectors) |v| {
        var out: [MD4_DIGEST_LENGTH]u8 = undefined;
        var expected: [MD4_DIGEST_LENGTH]u8 = undefined;
        _ = try std.fmt.hexToBytes(&expected, v.hex);
        try std.testing.expectEqual(CURLE_OK, Curl_md4it(&out, v.input.ptr, v.input.len));
        try std.testing.expectEqualSlices(u8, &expected, &out);
    }
}

test "Curl_md5it and Curl_MD5_* RFC 1321 and curl unit1601 vectors" {
    const vectors = [_]struct { input: []const u8, hex: *const [32]u8 }{
        // RFC 1321 test suite
        .{ .input = "", .hex = "d41d8cd98f00b204e9800998ecf8427e" },
        .{ .input = "a", .hex = "0cc175b9c0f1b6a831c399e269772661" },
        .{ .input = "abc", .hex = "900150983cd24fb0d6963f7d28e17f72" },
        .{ .input = "message digest", .hex = "f96b697d7cb7938d525a2f31aaf161d0" },
        .{ .input = "abcdefghijklmnopqrstuvwxyz", .hex = "c3fcd3d76192e4007dfb496cca67e13b" },
        // tests/unit/unit1601.c vectors
        .{ .input = "1", .hex = "c4ca4238a0b923820dcc509a6f75849b" },
        .{ .input = "hello-you-fool", .hex = "88670b6d5d742fada5cdf9b682875f22" },
    };

    for (vectors) |v| {
        var out: [MD5_DIGEST_LEN]u8 = undefined;
        var expected: [MD5_DIGEST_LEN]u8 = undefined;
        _ = try std.fmt.hexToBytes(&expected, v.hex);
        try std.testing.expectEqual(CURLE_OK, Curl_md5it(&out, v.input.ptr, v.input.len));
        try std.testing.expectEqualSlices(u8, &expected, &out);

        // Also verify streaming via Curl_MD5_init / Curl_MD5_update / Curl_MD5_final
        const ctxt = Curl_MD5_init(&Curl_DIGEST_MD5[0]).?;
        if (v.input.len >= 3) {
            try std.testing.expectEqual(CURLE_OK, Curl_MD5_update(ctxt, v.input.ptr, 2));
            try std.testing.expectEqual(
                CURLE_OK,
                Curl_MD5_update(ctxt, v.input.ptr + 2, @intCast(v.input.len - 2)),
            );
        } else {
            try std.testing.expectEqual(
                CURLE_OK,
                Curl_MD5_update(ctxt, v.input.ptr, @intCast(v.input.len)),
            );
        }
        var stream_out: [MD5_DIGEST_LEN]u8 = undefined;
        try std.testing.expectEqual(CURLE_OK, Curl_MD5_final(ctxt, &stream_out));
        try std.testing.expectEqualSlices(u8, &expected, &stream_out);
    }
}

test "Curl_sha256it FIPS 180-4 and curl unit1610 vectors" {
    const vectors = [_]struct { input: []const u8, hex: *const [64]u8 }{
        .{
            .input = "",
            .hex = "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855",
        },
        .{
            .input = "abc",
            .hex = "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad",
        },
        .{
            .input = "abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq",
            .hex = "248d6a61d20638b8e5c026930c3e6039a33ce45964ff2167f6ecedd419db06c1",
        },
        // tests/unit/unit1610.c vectors
        .{
            .input = "1",
            .hex = "6b86b273ff34fce19d6b804eff5a3f5747ada4eaa22f1d49c01e52ddb7875b4b",
        },
        .{
            .input = "hello-you-fool",
            .hex = "cbb16a8ab9cbb935a8cba02e28c02630d1199c1f0217f47c9620f3efe82715ae",
        },
    };

    for (vectors) |v| {
        var out: [CURL_SHA256_DIGEST_LENGTH]u8 = undefined;
        var expected: [CURL_SHA256_DIGEST_LENGTH]u8 = undefined;
        _ = try std.fmt.hexToBytes(&expected, v.hex);
        try std.testing.expectEqual(CURLE_OK, Curl_sha256it(&out, v.input.ptr, v.input.len));
        try std.testing.expectEqualSlices(u8, &expected, &out);
    }
}

test "Curl_sha512_256it FIPS 180-4 and curl unit1615 vectors" {
    const vectors = [_]struct { input: []const u8, hex: *const [64]u8 }{
        .{
            .input = "",
            .hex = "c672b8d1ef56ed28ab87c3622c5114069bdd3ad7b8f9737498d0c01ecef0967a",
        },
        .{
            .input = "abc",
            .hex = "53048e2681941ef99b2e29b76b4c7dabe4c2d0c634fc6d46e0e2f13107e7af23",
        },
        .{
            .input = "1",
            .hex = "18d27566bd1ac66b2332d8c54ad43f7bb22079c906d05f491f3f07a28d5c6990",
        },
        .{
            .input = "hello-you-fool",
            .hex = "af6fb4b0139bee13d1953cb8c7cd5b19f9cdcd21efdfa7425c0713eacc1a3976",
        },
        .{
            .input = "abcdefghijklmnopqrstuvwxyzzyxwvutsrqponMLKJIHGFEDCBA" ++
                "abcdefghijklmnopqrstuvwxyzzyxwvutsrqponMLKJIHGFEDCBA",
            .hex = "ade95d553b9e4569db53a40492e78794ffc9985f93038645e19717727cbc3115",
        },
        .{
            .input = "Simple string.",
            .hex = "decb3c81654ba0f5f0456b7e61f50df538a4fcb18a95ff59bc0482cf23b23256",
        },
    };

    for (vectors) |v| {
        var out: [CURL_SHA512_256_DIGEST_LENGTH]u8 = undefined;
        var expected: [CURL_SHA512_256_DIGEST_LENGTH]u8 = undefined;
        _ = try std.fmt.hexToBytes(&expected, v.hex);
        try std.testing.expectEqual(CURLE_OK, Curl_sha512_256it(&out, v.input.ptr, v.input.len));
        try std.testing.expectEqualSlices(u8, &expected, &out);
    }
}

test "Curl_hmacit and Curl_HMAC_* with MD5, SHA256, and SHA512/256" {
    // 1. HMAC-MD5: tests/unit/unit1612.c + RFC 2104 vectors (including key > 64 bytes)
    {
        const password = "Pa55worD";
        var out: [HMAC_MD5_LENGTH]u8 = undefined;
        var expected: [HMAC_MD5_LENGTH]u8 = undefined;

        _ = try std.fmt.hexToBytes(&expected, "d129754358dcab78dfcd7f2b29311337");
        try std.testing.expectEqual(
            CURLE_OK,
            Curl_hmacit(&Curl_HMAC_MD5[0], password.ptr, password.len, "1", 1, &out),
        );
        try std.testing.expectEqualSlices(u8, &expected, &out);

        const msg2 = "hello-you-fool";
        _ = try std.fmt.hexToBytes(&expected, "75f1a7b9f540e5a498839f645a276dd0");
        try std.testing.expectEqual(
            CURLE_OK,
            Curl_hmacit(&Curl_HMAC_MD5[0], password.ptr, password.len, msg2.ptr, msg2.len, &out),
        );
        try std.testing.expectEqualSlices(u8, &expected, &out);

        // RFC 2104 Test Case 2: key = "Jefe", data = "what do ya want for nothing?"
        const jefe = "Jefe";
        const data2 = "what do ya want for nothing?";
        _ = try std.fmt.hexToBytes(&expected, "750c783e6ab0b503eaa86e310a5db738");
        try std.testing.expectEqual(
            CURLE_OK,
            Curl_hmacit(&Curl_HMAC_MD5[0], jefe.ptr, jefe.len, data2.ptr, data2.len, &out),
        );
        try std.testing.expectEqualSlices(u8, &expected, &out);

        // RFC 2202 Test Case 6: key = 80 bytes of 0xaa (> 64 byte block size)
        const long_key: [80]u8 = @splat(0xaa);
        const data6 = "Test Using Larger Than Block-Size Key - Hash Key First";
        _ = try std.fmt.hexToBytes(&expected, "6b1ab7fe4bd7bf8f0b62e6ce61b9d0cd");
        try std.testing.expectEqual(
            CURLE_OK,
            Curl_hmacit(&Curl_HMAC_MD5[0], &long_key, long_key.len, data6.ptr, data6.len, &out),
        );
        try std.testing.expectEqualSlices(u8, &expected, &out);
    }

    // 2. HMAC-SHA256: RFC 4231 Test Case 2 & Test Case 6 (key > 64 bytes)
    {
        var out: [CURL_SHA256_DIGEST_LENGTH]u8 = undefined;
        var expected: [CURL_SHA256_DIGEST_LENGTH]u8 = undefined;

        const jefe = "Jefe";
        const data2 = "what do ya want for nothing?";
        _ = try std.fmt.hexToBytes(
            &expected,
            "5bdcc146bf60754e6a042426089575c75a003f089d2739839dec58b964ec3843",
        );
        try std.testing.expectEqual(
            CURLE_OK,
            Curl_hmacit(&Curl_HMAC_SHA256[0], jefe.ptr, jefe.len, data2.ptr, data2.len, &out),
        );
        try std.testing.expectEqualSlices(u8, &expected, &out);

        const long_key: [131]u8 = @splat(0xaa);
        const data6 = "Test Using Larger Than Block-Size Key - Hash Key First";
        _ = try std.fmt.hexToBytes(
            &expected,
            "60e431591ee0b67f0d8a26aacbf5b77f8e0bc6213728c5140546040f0ee37f54",
        );
        try std.testing.expectEqual(
            CURLE_OK,
            Curl_hmacit(&Curl_HMAC_SHA256[0], &long_key, long_key.len, data6.ptr, data6.len, &out),
        );
        try std.testing.expectEqualSlices(u8, &expected, &out);
    }

    // 3. HMAC-SHA512/256: compare against std.crypto.auth.hmac.Hmac(Sha512_256) (including key > 128 bytes)
    {
        const StdHmac512_256 = std.crypto.auth.hmac.Hmac(Sha512_256);
        var out: [CURL_SHA512_256_DIGEST_LENGTH]u8 = undefined;
        var expected: [CURL_SHA512_256_DIGEST_LENGTH]u8 = undefined;

        const key1 = "Jefe";
        const msg1 = "what do ya want for nothing?";
        StdHmac512_256.create(&expected, msg1, key1);
        try std.testing.expectEqual(
            CURLE_OK,
            Curl_hmacit(&Curl_HMAC_SHA512_256[0], key1.ptr, key1.len, msg1.ptr, msg1.len, &out),
        );
        try std.testing.expectEqualSlices(u8, &expected, &out);

        const long_key: [200]u8 = @splat(0xaa);
        const msg2 = "Test Using Larger Than 128-Byte Block-Size Key";
        StdHmac512_256.create(&expected, msg2, &long_key);
        try std.testing.expectEqual(
            CURLE_OK,
            Curl_hmacit(&Curl_HMAC_SHA512_256[0], &long_key, long_key.len, msg2.ptr, msg2.len, &out),
        );
        try std.testing.expectEqualSlices(u8, &expected, &out);

        // Verify Curl_HMAC_final with null output (cleanup-only path)
        const ctxt = Curl_HMAC_init(&Curl_HMAC_SHA512_256[0], key1.ptr, @intCast(key1.len)).?;
        Curl_HMAC_update(ctxt, msg1.ptr, @intCast(msg1.len));
        try std.testing.expectEqual(@as(c_int, 0), Curl_HMAC_final(ctxt, null));
    }
}
