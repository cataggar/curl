const std = @import("std");
const builtin = @import("builtin");
const mem = @import("mem.zig");
const primitives = @import("primitives.zig");
const crypto = @import("crypto.zig");
const containers = @import("containers.zig");

pub const CURLcode = c_uint;
pub const CURLE_OK: CURLcode = 0;
pub const CURLE_OUT_OF_MEMORY: CURLcode = 27;
pub const CURLE_BAD_FUNCTION_ARGUMENT: CURLcode = 43;
pub const CURLE_BAD_CONTENT_ENCODING: CURLcode = 61;
pub const CURLE_TOO_LARGE: CURLcode = 100;

pub const CURL_MAX_INPUT_LENGTH: usize = 8_000_000;

pub const bufref = containers.bufref;
pub const BufrefDtor = containers.BufrefDtor;

extern fn Curl_bufref_init(br: *bufref) callconv(.c) void;
extern fn Curl_bufref_set(br: *bufref, ptr: ?*const anyopaque, len: usize, dtor: ?BufrefDtor) callconv(.c) void;
extern fn Curl_bufref_uptr(br: *const bufref) callconv(.c) ?[*]const u8;
extern fn Curl_bufref_ptr(br: *const bufref) callconv(.c) ?[*:0]const u8;
extern fn Curl_bufref_len(br: *const bufref) callconv(.c) usize;
extern fn Curl_bufref_memdup0(br: *bufref, ptr: ?*const anyopaque, len: usize) callconv(.c) CURLcode;
extern fn Curl_bufref_free(br: *bufref) callconv(.c) void;

const c_trc = struct {
    extern fn Curl_failf(data: *anyopaque, fmt: [*:0]const u8, ...) callconv(.c) void;
    extern fn Curl_infof(data: *anyopaque, fmt: [*:0]const u8, ...) callconv(.c) void;
};

const c_rand = struct {
    extern fn Curl_rand_bytes(data: ?*anyopaque, rnd: [*]u8, num: usize) callconv(.c) CURLcode;
};

inline fn failf(data: ?*anyopaque, msg: [*:0]const u8) void {
    if (builtin.output_mode == .Lib) {
        if (data) |d| {
            c_trc.Curl_failf(d, "%s", msg);
        }
    }
}

inline fn infof(data: ?*anyopaque, msg: [*:0]const u8) void {
    if (builtin.output_mode == .Lib) {
        if (data) |d| {
            c_trc.Curl_infof(d, "%s", msg);
        }
    }
}

fn bufrefFreeCallback(ptr: ?*anyopaque) callconv(.c) void {
    mem.free(ptr);
}

pub const Curl_creds = extern struct {
    user: ?[*:0]const u8 = null,
    passwd: ?[*:0]const u8 = null,
    oauth_bearer: ?[*:0]const u8 = null,
    sasl_authzid: ?[*:0]const u8 = null,
    sasl_service: ?[*:0]const u8 = null,
    refcount: u32 = 1,
    source: u8 = 0,
    bufsize: usize = 0,
    buf: [1]u8 = .{0},
};

inline fn credsUser(creds: ?*const Curl_creds) []const u8 {
    if (creds) |c| {
        if (c.user) |p| return std.mem.span(p);
    }
    return "";
}

inline fn credsPasswd(creds: ?*const Curl_creds) []const u8 {
    if (creds) |c| {
        if (c.passwd) |p| return std.mem.span(p);
    }
    return "";
}

inline fn credsOauthBearer(creds: ?*const Curl_creds) []const u8 {
    if (creds) |c| {
        if (c.oauth_bearer) |p| return std.mem.span(p);
    }
    return "";
}

inline fn credsSaslAuthzid(creds: ?*const Curl_creds) []const u8 {
    if (creds) |c| {
        if (c.sasl_authzid) |p| return std.mem.span(p);
    }
    return "";
}

// ============================================================================
// 1. lib/vauth/cleartext.c
// ============================================================================

pub export fn Curl_auth_create_plain_message(
    creds: ?*const Curl_creds,
    out: *bufref,
) callconv(.c) CURLcode {
    const authzid = credsSaslAuthzid(creds);
    const user = credsUser(creds);
    const passwd = credsPasswd(creds);

    const zlen = authzid.len;
    const clen = user.len;
    const plen = passwd.len;

    if (zlen > CURL_MAX_INPUT_LENGTH or clen > CURL_MAX_INPUT_LENGTH or plen > CURL_MAX_INPUT_LENGTH) {
        return CURLE_TOO_LARGE;
    }

    const len = zlen + clen + plen + 2;
    const auth = mem.malloc(len + 1) orelse return CURLE_OUT_OF_MEMORY;

    if (zlen > 0) @memcpy(auth[0..zlen], authzid);
    auth[zlen] = 0;
    if (clen > 0) @memcpy(auth[zlen + 1 .. zlen + 1 + clen], user);
    auth[zlen + 1 + clen] = 0;
    if (plen > 0) @memcpy(auth[zlen + 1 + clen + 1 .. len], passwd);
    auth[len] = 0;

    Curl_bufref_set(out, auth, len, &bufrefFreeCallback);
    return CURLE_OK;
}

pub export fn Curl_auth_create_login_message(
    value: [*:0]const u8,
    out: *bufref,
) callconv(.c) void {
    Curl_bufref_set(out, value, std.mem.len(value), null);
}

pub export fn Curl_auth_create_external_message(
    user: [*:0]const u8,
    out: *bufref,
) callconv(.c) void {
    Curl_auth_create_login_message(user, out);
}

// ============================================================================
// 2. lib/vauth/cram.c
// ============================================================================

pub export fn Curl_auth_create_cram_md5_message(
    chlg: *const bufref,
    creds: ?*const Curl_creds,
    out: *bufref,
) callconv(.c) CURLcode {
    const user = credsUser(creds);
    const passwd = credsPasswd(creds);

    const ctxt = crypto.Curl_HMAC_init(
        &crypto.Curl_HMAC_MD5[0],
        passwd.ptr,
        @truncate(passwd.len),
    ) orelse return CURLE_OUT_OF_MEMORY;

    const chlg_len = Curl_bufref_len(chlg);
    if (chlg_len > 0) {
        crypto.Curl_HMAC_update(ctxt, Curl_bufref_uptr(chlg), @truncate(chlg_len));
    }

    var digest: [crypto.MD5_DIGEST_LEN]u8 = undefined;
    _ = crypto.Curl_HMAC_final(ctxt, &digest);

    const resp_len = std.math.add(usize, user.len, 1 + (crypto.MD5_DIGEST_LEN * 2)) catch return CURLE_OUT_OF_MEMORY;
    const alloc_len = std.math.add(usize, resp_len, 1) catch return CURLE_OUT_OF_MEMORY;
    const response = mem.malloc(alloc_len) orelse return CURLE_OUT_OF_MEMORY;

    if (user.len > 0) {
        @memcpy(response[0..user.len], user);
    }
    response[user.len] = ' ';
    const hex_chars = "0123456789abcdef";
    for (digest, 0..) |b, i| {
        response[user.len + 1 + i * 2] = hex_chars[b >> 4];
        response[user.len + 1 + i * 2 + 1] = hex_chars[b & 0x0f];
    }
    response[resp_len] = 0;

    Curl_bufref_set(out, response, resp_len, &bufrefFreeCallback);
    return CURLE_OK;
}

// ============================================================================
// 3. lib/vauth/oauth2.c
// ============================================================================

fn concatSlicesAllocZ(parts: []const []const u8) ?struct { ptr: [*]u8, len: usize } {
    var total_len: usize = 0;
    for (parts) |part| {
        total_len = std.math.add(usize, total_len, part.len) catch return null;
    }
    const alloc_len = std.math.add(usize, total_len, 1) catch return null;
    const buf = mem.malloc(alloc_len) orelse return null;
    var offset: usize = 0;
    for (parts) |part| {
        if (part.len > 0) {
            @memcpy(buf[offset .. offset + part.len], part);
            offset += part.len;
        }
    }
    buf[total_len] = 0;
    return .{ .ptr = buf, .len = total_len };
}

pub export fn Curl_auth_create_oauth_bearer_message(
    creds: ?*const Curl_creds,
    host: [*:0]const u8,
    port: c_long,
    out: *bufref,
) callconv(.c) CURLcode {
    const user = credsUser(creds);
    const host_slice = std.mem.span(host);
    const bearer = credsOauthBearer(creds);
    const auth_prefix = "\x01auth=" ++ "Bearer ";
    const auth_suffix = "\x01\x01";

    if (port == 0 or port == 80) {
        const res = concatSlicesAllocZ(&.{
            "n,a=",
            user,
            ",\x01host=",
            host_slice,
            auth_prefix,
            bearer,
            auth_suffix,
        }) orelse return CURLE_OUT_OF_MEMORY;
        Curl_bufref_set(out, res.ptr, res.len, &bufrefFreeCallback);
        return CURLE_OK;
    } else {
        var port_buf: [32]u8 = undefined;
        const port_slice = std.fmt.bufPrint(&port_buf, "{d}", .{port}) catch return CURLE_OUT_OF_MEMORY;
        const res = concatSlicesAllocZ(&.{
            "n,a=",
            user,
            ",\x01host=",
            host_slice,
            "\x01port=",
            port_slice,
            auth_prefix,
            bearer,
            auth_suffix,
        }) orelse return CURLE_OUT_OF_MEMORY;
        Curl_bufref_set(out, res.ptr, res.len, &bufrefFreeCallback);
        return CURLE_OK;
    }
}

pub export fn Curl_auth_create_xoauth_bearer_message(
    creds: ?*const Curl_creds,
    out: *bufref,
) callconv(.c) CURLcode {
    const user = credsUser(creds);
    const bearer = credsOauthBearer(creds);
    const auth_prefix = "\x01auth=" ++ "Bearer ";
    const auth_suffix = "\x01\x01";

    const res = concatSlicesAllocZ(&.{
        "user=",
        user,
        auth_prefix,
        bearer,
        auth_suffix,
    }) orelse return CURLE_OUT_OF_MEMORY;
    Curl_bufref_set(out, res.ptr, res.len, &bufrefFreeCallback);
    return CURLE_OK;
}

// ============================================================================
// 4. lib/vauth/gsasl.c (active only when USE_GSASL is enabled)
// ============================================================================

const use_gsasl = false;

pub const gsasldata = extern struct {
    ctx: ?*anyopaque = null,
    client: ?*anyopaque = null,
};

comptime {
    if (use_gsasl) {
        _ = gsasl_impl;
    }
}

const gsasl_impl = struct {
    const GSASL_OK: c_int = 0;
    const GSASL_NEEDS_MORE: c_int = 1;
    const GSASL_AUTHID: c_int = 1;
    const GSASL_PASSWORD: c_int = 3;

    extern fn gsasl_init(ctx: *?*anyopaque) callconv(.c) c_int;
    extern fn gsasl_done(ctx: ?*anyopaque) callconv(.c) void;
    extern fn gsasl_client_start(ctx: ?*anyopaque, mech: [*:0]const u8, session: *?*anyopaque) callconv(.c) c_int;
    extern fn gsasl_property_set(session: ?*anyopaque, prop: c_int, data: ?[*:0]const u8) callconv(.c) c_int;
    extern fn gsasl_step(session: ?*anyopaque, input: ?[*:0]const u8, input_len: usize, output: *?[*]u8, output_len: *usize) callconv(.c) c_int;
    extern fn gsasl_finish(session: ?*anyopaque) callconv(.c) void;
    extern fn gsasl_free(ptr: ?*anyopaque) callconv(.c) void;

    pub export fn Curl_auth_gsasl_is_supported(
        data: ?*anyopaque,
        mech: [*:0]const u8,
        gsasl: *gsasldata,
    ) callconv(.c) bool {
        _ = data;
        var res = gsasl_init(&gsasl.ctx);
        if (res != GSASL_OK) {
            return false;
        }
        res = gsasl_client_start(gsasl.ctx, mech, &gsasl.client);
        if (res != GSASL_OK) {
            gsasl_done(gsasl.ctx);
            gsasl.ctx = null;
            return false;
        }
        return true;
    }

    pub export fn Curl_auth_gsasl_start(
        data: ?*anyopaque,
        creds: *const Curl_creds,
        gsasl: *gsasldata,
    ) callconv(.c) CURLcode {
        _ = data;
        if (gsasl_property_set(gsasl.client, GSASL_AUTHID, creds.user) != GSASL_OK) {
            return CURLE_OUT_OF_MEMORY;
        }
        if (gsasl_property_set(gsasl.client, GSASL_PASSWORD, creds.passwd) != GSASL_OK) {
            return CURLE_OUT_OF_MEMORY;
        }
        return CURLE_OK;
    }

    pub export fn Curl_auth_gsasl_token(
        data: ?*anyopaque,
        chlg: *const bufref,
        gsasl: *gsasldata,
        out: *bufref,
    ) callconv(.c) CURLcode {
        _ = data;
        var response: ?[*]u8 = null;
        var outlen: usize = 0;
        const res = gsasl_step(gsasl.client, Curl_bufref_ptr(chlg), Curl_bufref_len(chlg), &response, &outlen);
        if (res != GSASL_OK and res != GSASL_NEEDS_MORE) {
            return CURLE_BAD_CONTENT_ENCODING;
        }
        Curl_bufref_set(out, response, outlen, &gsasl_free);
        return CURLE_OK;
    }

    pub export fn Curl_auth_gsasl_cleanup(gsasl: *gsasldata) callconv(.c) void {
        gsasl_finish(gsasl.client);
        gsasl.client = null;
        gsasl_done(gsasl.ctx);
        gsasl.ctx = null;
    }
};

// ============================================================================
// 5. lib/curl_ntlm_core.c — Pure-Zig DES & NTLM v1/v2 Cryptographic Primitives
// ============================================================================

const des = struct {
    const pc1 = [56]u6{
        57, 49, 41, 33, 25, 17, 9,
        1,  58, 50, 42, 34, 26, 18,
        10, 2,  59, 51, 43, 35, 27,
        19, 11, 3,  60, 52, 44, 36,
        63, 55, 47, 39, 31, 23, 15,
        7,  62, 54, 46, 38, 30, 22,
        14, 6,  61, 53, 45, 37, 29,
        21, 13, 5,  28, 20, 12, 4,
    };

    const pc2 = [48]u6{
        14, 17, 11, 24, 1,  5,
        3,  28, 15, 6,  21, 10,
        23, 19, 12, 4,  26, 8,
        16, 7,  27, 20, 13, 2,
        41, 52, 31, 37, 47, 55,
        30, 40, 51, 45, 33, 48,
        44, 49, 39, 56, 34, 53,
        46, 42, 50, 36, 29, 32,
    };

    const shifts = [16]u5{ 1, 1, 2, 2, 2, 2, 2, 2, 1, 2, 2, 2, 2, 2, 2, 1 };

    const ip = [64]u6{
        58, 50, 42, 34, 26, 18, 10, 2,
        60, 52, 44, 36, 28, 20, 12, 4,
        62, 54, 46, 38, 30, 22, 14, 6,
        0,  56, 48, 40, 32, 24, 16, 8, // note: 64 stored as 0, handled via 1-based helper
        57, 49, 41, 33, 25, 17, 9,  1,
        59, 51, 43, 35, 27, 19, 11, 3,
        61, 53, 45, 37, 29, 21, 13, 5,
        63, 55, 47, 39, 31, 23, 15, 7,
    };

    const fp = [64]u7{
        40, 8, 48, 16, 56, 24, 64, 32,
        39, 7, 47, 15, 55, 23, 63, 31,
        38, 6, 46, 14, 54, 22, 62, 30,
        37, 5, 45, 13, 53, 21, 61, 29,
        36, 4, 44, 12, 52, 20, 60, 28,
        35, 3, 43, 11, 51, 19, 59, 27,
        34, 2, 42, 10, 50, 18, 58, 26,
        33, 1, 41, 9,  49, 17, 57, 25,
    };

    const exp_e = [48]u6{
        32, 1,  2,  3,  4,  5,
        4,  5,  6,  7,  8,  9,
        8,  9,  10, 11, 12, 13,
        12, 13, 14, 15, 16, 17,
        16, 17, 18, 19, 20, 21,
        20, 21, 22, 23, 24, 25,
        24, 25, 26, 27, 28, 29,
        28, 29, 30, 31, 32, 1,
    };

    const sbox = [8][64]u4{
        .{
            14, 4,  13, 1, 2,  15, 11, 8,  3,  10, 6,  12, 5,  9,  0, 7,
            0,  15, 7,  4, 14, 2,  13, 1,  10, 6,  12, 11, 9,  5,  3, 8,
            4,  1,  14, 8, 13, 6,  2,  11, 15, 12, 9,  7,  3,  10, 5, 0,
            15, 12, 8,  2, 4,  9,  1,  7,  5,  11, 3,  14, 10, 0,  6, 13,
        },
        .{
            15, 1,  8,  14, 6,  11, 3,  4,  9,  7, 2,  13, 12, 0, 5,  10,
            3,  13, 4,  7,  15, 2,  8,  14, 12, 0, 1,  10, 6,  9, 11, 5,
            0,  14, 7,  11, 10, 4,  13, 1,  5,  8, 12, 6,  9,  3, 2,  15,
            13, 8,  10, 1,  3,  15, 4,  2,  11, 6, 7,  12, 0,  5, 14, 9,
        },
        .{
            10, 0,  9,  14, 6, 3,  15, 5,  1,  13, 12, 7,  11, 4,  2,  8,
            13, 7,  0,  9,  3, 4,  6,  10, 2,  8,  5,  14, 12, 11, 15, 1,
            13, 6,  4,  9,  8, 15, 3,  0,  11, 1,  2,  12, 5,  10, 14, 7,
            1,  10, 13, 0,  6, 9,  8,  7,  4,  15, 14, 3,  11, 5,  2,  12,
        },
        .{
            7,  13, 14, 3, 0,  6,  9,  10, 1,  2, 8, 5,  11, 12, 4,  15,
            13, 8,  11, 5, 6,  15, 0,  3,  4,  7, 2, 12, 1,  10, 14, 9,
            10, 6,  9,  0, 12, 11, 7,  13, 15, 1, 3, 14, 5,  2,  8,  4,
            3,  15, 0,  6, 10, 1,  13, 8,  9,  4, 5, 11, 12, 7,  2,  14,
        },
        .{
            2,  12, 4,  1,  7,  10, 11, 6,  8,  5,  3,  15, 13, 0, 14, 9,
            14, 11, 2,  12, 4,  7,  13, 1,  5,  0,  15, 10, 3,  9, 8,  6,
            4,  2,  1,  11, 10, 13, 7,  8,  15, 9,  12, 5,  6,  3, 0,  14,
            11, 8,  12, 7,  1,  14, 2,  13, 6,  15, 0,  9,  10, 4, 5,  3,
        },
        .{
            12, 1,  10, 15, 9, 2,  6,  8,  0,  13, 3,  4,  14, 7,  5,  11,
            10, 15, 4,  2,  7, 12, 9,  5,  6,  1,  13, 14, 0,  11, 3,  8,
            9,  14, 15, 5,  2, 8,  12, 3,  7,  0,  4,  10, 1,  13, 11, 6,
            4,  3,  2,  12, 9, 5,  15, 10, 11, 14, 1,  7,  6,  0,  8,  13,
        },
        .{
            4,  11, 2,  14, 15, 0, 8,  13, 3,  12, 9, 7,  5,  10, 6, 1,
            13, 0,  11, 7,  4,  9, 1,  10, 14, 3,  5, 12, 2,  15, 8, 6,
            1,  4,  11, 13, 12, 3, 7,  14, 10, 15, 6, 8,  0,  5,  9, 2,
            6,  11, 13, 8,  1,  4, 10, 7,  9,  5,  0, 15, 14, 2,  3, 12,
        },
        .{
            13, 2,  8,  4, 6,  15, 11, 1,  10, 9,  3,  14, 5,  0,  12, 7,
            1,  15, 13, 8, 10, 3,  7,  4,  12, 5,  6,  11, 0,  14, 9,  2,
            7,  11, 4,  1, 9,  12, 14, 2,  0,  6,  10, 13, 15, 3,  5,  8,
            2,  1,  14, 7, 4,  10, 8,  13, 15, 12, 9,  0,  3,  5,  6,  11,
        },
    };

    const perm_p = [32]u6{
        16, 7,  20, 21, 29, 12, 28, 17,
        1,  15, 23, 26, 5,  18, 31, 10,
        2,  8,  24, 14, 32, 27, 3,  9,
        19, 13, 30, 6,  22, 11, 4,  25,
    };

    const ip_full = [64]u7{
        58, 50, 42, 34, 26, 18, 10, 2,
        60, 52, 44, 36, 28, 20, 12, 4,
        62, 54, 46, 38, 30, 22, 14, 6,
        64, 56, 48, 40, 32, 24, 16, 8,
        57, 49, 41, 33, 25, 17, 9,  1,
        59, 51, 43, 35, 27, 19, 11, 3,
        61, 53, 45, 37, 29, 21, 13, 5,
        63, 55, 47, 39, 31, 23, 15, 7,
    };

    fn extendKey56To64(key56: *const [7]u8) [8]u8 {
        return .{
            key56[0],
            ((key56[0] << 7) & 0xFF) | (key56[1] >> 1),
            ((key56[1] << 6) & 0xFF) | (key56[2] >> 2),
            ((key56[2] << 5) & 0xFF) | (key56[3] >> 3),
            ((key56[3] << 4) & 0xFF) | (key56[4] >> 4),
            ((key56[4] << 3) & 0xFF) | (key56[5] >> 5),
            ((key56[5] << 2) & 0xFF) | (key56[6] >> 6),
            (key56[6] << 1) & 0xFF,
        };
    }

    fn rotl28(val: u32, shift: u5) u32 {
        return ((val << shift) | (val >> @intCast(@as(u6, 28) - shift))) & 0x0FFF_FFFF;
    }

    pub fn encryptBlock(key56: *const [7]u8, block: *const [8]u8) [8]u8 {
        const key_bytes = extendKey56To64(key56);
        const key64 = std.mem.readInt(u64, &key_bytes, .big);

        var cd: u64 = 0;
        for (pc1) |pos| {
            const shift: u6 = @intCast(@as(u7, 64) - pos);
            cd = (cd << 1) | ((key64 >> shift) & 1);
        }
        var c: u32 = @truncate((cd >> 28) & 0x0FFF_FFFF);
        var d: u32 = @truncate(cd & 0x0FFF_FFFF);

        const blk64 = std.mem.readInt(u64, block, .big);
        var lr: u64 = 0;
        for (ip_full) |pos| {
            const shift: u6 = @intCast(@as(u7, 64) - pos);
            lr = (lr << 1) | ((blk64 >> shift) & 1);
        }
        var l: u32 = @truncate(lr >> 32);
        var r: u32 = @truncate(lr & 0xFFFF_FFFF);

        for (shifts) |s| {
            c = rotl28(c, s);
            d = rotl28(d, s);
            const cd_round: u64 = (@as(u64, c) << 28) | @as(u64, d);
            var subkey: u64 = 0;
            for (pc2) |pos| {
                const shift: u6 = @intCast(@as(u7, 56) - pos);
                subkey = (subkey << 1) | ((cd_round >> shift) & 1);
            }

            var exp_r: u64 = 0;
            for (exp_e) |pos| {
                const shift: u5 = @intCast(@as(u6, 32) - pos);
                exp_r = (exp_r << 1) | @as(u64, (r >> shift) & 1);
            }
            const xored = exp_r ^ subkey;

            var s_out: u32 = 0;
            inline for (0..8) |i| {
                const b6: u8 = @truncate((xored >> @intCast(42 - 6 * i)) & 0x3F);
                const row: usize = @as(usize, (b6 >> 4) & 2) | @as(usize, b6 & 1);
                const col: usize = @as(usize, (b6 >> 1) & 0x0F);
                s_out = (s_out << 4) | @as(u32, sbox[i][row * 16 + col]);
            }

            var f_out: u32 = 0;
            for (perm_p) |pos| {
                const shift: u5 = @intCast(@as(u6, 32) - pos);
                f_out = (f_out << 1) | ((s_out >> shift) & 1);
            }

            const next_l = r;
            r = l ^ f_out;
            l = next_l;
        }

        const rl: u64 = (@as(u64, r) << 32) | @as(u64, l);
        var out64: u64 = 0;
        for (fp) |pos| {
            const shift: u6 = @intCast(@as(u7, 64) - pos);
            out64 = (out64 << 1) | ((rl >> shift) & 1);
        }

        var out: [8]u8 = undefined;
        std.mem.writeInt(u64, &out, out64, .big);
        return out;
    }
};

fn asciiToUnicodeLe(dest: [*]u8, src: [*]const u8, srclen: usize) void {
    var i: usize = 0;
    while (i < srclen) : (i += 1) {
        dest[2 * i] = src[i];
        dest[2 * i + 1] = 0;
    }
}

fn asciiUppercaseToUnicodeLe(dest: [*]u8, src: [*]const u8, srclen: usize) void {
    var i: usize = 0;
    while (i < srclen) : (i += 1) {
        dest[2 * i] = primitives.rawToupper(src[i]);
        dest[2 * i + 1] = 0;
    }
}

const c_time = struct {
    const time_t = if (builtin.os.tag == .windows) i64 else std.c.time_t;
    extern "c" fn _time64(tloc: ?*i64) callconv(.c) i64;
    extern "c" fn time(tloc: ?*time_t) callconv(.c) time_t;

    fn now() i64 {
        if (builtin.os.tag == .windows) {
            return _time64(null);
        } else {
            return @intCast(time(null));
        }
    }
};

fn time2filetime(t_sec: i64) u64 {
    const biased: i64 = (t_sec +% 11644473600) *% 10000000;
    return @bitCast(biased);
}

pub export fn Curl_ntlm_core_lm_resp(
    keys: [*]const u8,
    plaintext: [*]const u8,
    results: [*]u8,
) callconv(.c) void {
    const pt: *const [8]u8 = plaintext[0..8];
    results[0..8].* = des.encryptBlock(keys[0..7], pt);
    results[8..16].* = des.encryptBlock(keys[7..14], pt);
    results[16..24].* = des.encryptBlock(keys[14..21], pt);
}

pub export fn Curl_ntlm_core_mk_lm_hash(
    password: [*:0]const u8,
    lmbuffer: [*]u8,
) callconv(.c) CURLcode {
    const magic = [8]u8{ 0x4B, 0x47, 0x53, 0x21, 0x40, 0x23, 0x24, 0x25 };
    const len = @min(std.mem.len(password), 14);
    var pw: [14]u8 = @splat(0);
    primitives.Curl_strntoupper(&pw, password, len);

    lmbuffer[0..8].* = des.encryptBlock(pw[0..7], &magic);
    lmbuffer[8..16].* = des.encryptBlock(pw[7..14], &magic);
    @memset(lmbuffer[16..21], 0);
    return CURLE_OK;
}

pub export fn Curl_ntlm_core_mk_nt_hash(
    password: [*:0]const u8,
    ntbuffer: [*]u8,
) callconv(.c) CURLcode {
    const len = std.mem.len(password);
    if (len > std.math.maxInt(usize) / 2) {
        return CURLE_OUT_OF_MEMORY;
    }
    const pw: [*]u8 = if (len > 0)
        (mem.malloc(len * 2) orelse return CURLE_OUT_OF_MEMORY)
    else
        @ptrCast(mem.strdup("") orelse return CURLE_OUT_OF_MEMORY);
    defer mem.free(pw);

    asciiToUnicodeLe(pw, password, len);

    const result = crypto.Curl_md4it(ntbuffer, pw, 2 * len);
    if (result == CURLE_OK) {
        @memset(ntbuffer[16..21], 0);
    }
    return result;
}

pub export fn Curl_hmac_md5(
    key: [*]const u8,
    keylen: c_uint,
    data: [*]const u8,
    datalen: c_uint,
    output: [*]u8,
) callconv(.c) CURLcode {
    return crypto.Curl_hmacit(&crypto.Curl_HMAC_MD5[0], key, keylen, data, datalen, output);
}

pub export fn Curl_ntlm_core_mk_ntlmv2_hash(
    user: [*]const u8,
    userlen: usize,
    domain: [*]const u8,
    domlen: usize,
    ntlmhash: [*]u8,
    ntlmv2hash: [*]u8,
) callconv(.c) CURLcode {
    if (userlen > CURL_MAX_INPUT_LENGTH or domlen > CURL_MAX_INPUT_LENGTH) {
        return CURLE_OUT_OF_MEMORY;
    }

    const identity_len = (userlen + domlen) * 2;
    const identity = mem.malloc(identity_len + 1) orelse return CURLE_OUT_OF_MEMORY;
    defer mem.free(identity);

    asciiUppercaseToUnicodeLe(identity, user, userlen);
    asciiToUnicodeLe(identity + (userlen << 1), domain, domlen);

    return crypto.Curl_hmacit(
        &crypto.Curl_HMAC_MD5[0],
        ntlmhash,
        16,
        identity,
        identity_len,
        ntlmv2hash,
    );
}

pub export fn Curl_ntlm_core_mk_ntlmv2_resp(
    ntlmv2hash: [*]const u8,
    challenge_client: [*]const u8,
    ntlm: *const ntlmdata,
    ntresp: *?[*]u8,
    ntresp_len: *c_uint,
) callconv(.c) CURLcode {
    const blob_len: u32 = 32 +% ntlm.target_info_len;
    const len: u32 = @as(u32, crypto.HMAC_MD5_LENGTH) +% blob_len;

    const ptr = mem.calloc(1, len) orelse return CURLE_OUT_OF_MEMORY;

    const filetime = time2filetime(c_time.now());
    ptr[16] = 0x01;
    ptr[17] = 0x01;
    ptr[18] = 0x00;
    ptr[19] = 0x00;
    std.mem.writeInt(u64, ptr[24..32], filetime, .little);
    @memcpy(ptr[32..40], challenge_client[0..8]);
    if (ntlm.target_info_len > 0) {
        if (ntlm.target_info) |ti| {
            const ti_bytes: [*]const u8 = @ptrCast(ti);
            @memcpy(ptr[44 .. 44 + ntlm.target_info_len], ti_bytes[0..ntlm.target_info_len]);
        }
    }

    @memcpy(ptr[8..16], &ntlm.nonce);
    var hmac_output: [crypto.HMAC_MD5_LENGTH]u8 = undefined;
    const result = crypto.Curl_hmacit(
        &crypto.Curl_HMAC_MD5[0],
        ntlmv2hash,
        crypto.HMAC_MD5_LENGTH,
        ptr + 8,
        blob_len + 8,
        &hmac_output,
    );
    if (result != CURLE_OK) {
        mem.free(ptr);
        return result;
    }

    @memcpy(ptr[0..crypto.HMAC_MD5_LENGTH], &hmac_output);
    ntresp.* = ptr;
    ntresp_len.* = len;
    return CURLE_OK;
}

pub export fn Curl_ntlm_core_mk_lmv2_resp(
    ntlmv2hash: [*]const u8,
    challenge_client: [*]const u8,
    challenge_server: [*]const u8,
    lmresp: [*]u8,
) callconv(.c) CURLcode {
    var data: [16]u8 = undefined;
    var hmac_output: [16]u8 = undefined;

    @memcpy(data[0..8], challenge_server[0..8]);
    @memcpy(data[8..16], challenge_client[0..8]);

    const result = crypto.Curl_hmacit(
        &crypto.Curl_HMAC_MD5[0],
        ntlmv2hash,
        16,
        &data,
        16,
        &hmac_output,
    );
    if (result != CURLE_OK) return result;

    @memcpy(lmresp[0..16], &hmac_output);
    @memcpy(lmresp[16..24], challenge_client[0..8]);
    return CURLE_OK;
}

// ============================================================================
// 6. lib/vauth/ntlm.c — NTLM Type 1, Type 2, Type 3 Message Decoding/Encoding
// ============================================================================

pub const NTLMSSP_SIGNATURE = "NTLMSSP\x00";
pub const NTLM_BUFSIZE: usize = 1024;

pub const NTLMFLAG_NEGOTIATE_UNICODE: c_uint = 1 << 0;
pub const NTLMFLAG_NEGOTIATE_OEM: c_uint = 1 << 1;
pub const NTLMFLAG_REQUEST_TARGET: c_uint = 1 << 2;
pub const NTLMFLAG_NEGOTIATE_NTLM_KEY: c_uint = 1 << 9;
pub const NTLMFLAG_NEGOTIATE_ALWAYS_SIGN: c_uint = 1 << 15;
pub const NTLMFLAG_NEGOTIATE_NTLM2_KEY: c_uint = 1 << 19;
pub const NTLMFLAG_NEGOTIATE_TARGET_INFO: c_uint = 1 << 23;

pub const ntlmdata = extern struct {
    flags: c_uint = 0,
    nonce: [8]u8 = @splat(0),
    target_info_len: c_uint = 0,
    target_info: ?*anyopaque = null,
};

fn ntlmDecodeType2Target(
    data: ?*anyopaque,
    type2ref: *const bufref,
    ntlm: *ntlmdata,
) CURLcode {
    var target_info_len: u16 = 0;
    var target_info_offset: u32 = 0;
    const type2 = Curl_bufref_uptr(type2ref) orelse return CURLE_BAD_CONTENT_ENCODING;
    const type2len = Curl_bufref_len(type2ref);

    if (type2len >= 48) {
        target_info_len = primitives.Curl_read16_le(type2 + 40);
        target_info_offset = primitives.Curl_read32_le(type2 + 44);
        if (target_info_len > 0) {
            if (target_info_offset > type2len or
                (@as(usize, target_info_offset) + @as(usize, target_info_len)) > type2len or
                target_info_offset < 48)
            {
                infof(data, "NTLM handshake failure (bad type-2 message). Target Info Offset Len is set incorrect by the peer");
                return CURLE_BAD_CONTENT_ENCODING;
            }

            mem.free(ntlm.target_info);
            const dup = mem.malloc(target_info_len) orelse {
                ntlm.target_info = null;
                return CURLE_OUT_OF_MEMORY;
            };
            @memcpy(dup[0..target_info_len], type2[target_info_offset .. target_info_offset + target_info_len]);
            ntlm.target_info = @ptrCast(dup);
        }
    }

    ntlm.target_info_len = target_info_len;
    return CURLE_OK;
}

pub export fn Curl_auth_is_ntlm_supported() callconv(.c) bool {
    return true;
}

pub export fn Curl_auth_decode_ntlm_type2_message(
    data: ?*anyopaque,
    type2ref: *const bufref,
    ntlm: *ntlmdata,
) callconv(.c) CURLcode {
    const type2_marker = [4]u8{ 0x02, 0x00, 0x00, 0x00 };
    const type2 = Curl_bufref_uptr(type2ref);
    const type2len = Curl_bufref_len(type2ref);

    ntlm.flags = 0;

    if (type2len < 32 or type2 == null or
        !std.mem.eql(u8, type2.?[0..8], NTLMSSP_SIGNATURE) or
        !std.mem.eql(u8, type2.?[8..12], &type2_marker))
    {
        infof(data, "NTLM handshake failure (bad type-2 message)");
        return CURLE_BAD_CONTENT_ENCODING;
    }

    const bytes = type2.?;
    ntlm.flags = primitives.Curl_read32_le(bytes + 20);
    @memcpy(&ntlm.nonce, bytes[24..32]);

    if ((ntlm.flags & NTLMFLAG_NEGOTIATE_TARGET_INFO) != 0) {
        const result = ntlmDecodeType2Target(data, type2ref, ntlm);
        if (result != CURLE_OK) {
            infof(data, "NTLM handshake failure (bad type-2 message)");
            return result;
        }
    }

    return CURLE_OK;
}

pub export fn Curl_auth_create_ntlm_type1_message(
    data: ?*anyopaque,
    creds: ?*const Curl_creds,
    default_service: ?[*:0]const u8,
    host: ?[*:0]const u8,
    ntlm: *ntlmdata,
    out: *bufref,
) callconv(.c) CURLcode {
    _ = data;
    _ = creds;
    _ = default_service;
    _ = host;

    Curl_auth_cleanup_ntlm(ntlm);

    const size: usize = 32;
    const ntlmbuf = mem.malloc(size + 1) orelse return CURLE_OUT_OF_MEMORY;
    @memset(ntlmbuf[0 .. size + 1], 0);

    @memcpy(ntlmbuf[0..8], NTLMSSP_SIGNATURE);
    ntlmbuf[8] = 0x01;

    const flags: u32 = NTLMFLAG_NEGOTIATE_OEM |
        NTLMFLAG_REQUEST_TARGET |
        NTLMFLAG_NEGOTIATE_NTLM_KEY |
        NTLMFLAG_NEGOTIATE_NTLM2_KEY |
        NTLMFLAG_NEGOTIATE_ALWAYS_SIGN;
    std.mem.writeInt(u32, ntlmbuf[12..16], flags, .little);

    Curl_bufref_set(out, ntlmbuf, size, &bufrefFreeCallback);
    return CURLE_OK;
}

fn writeSecurityBuffer(dest: *[8]u8, len: usize, offset: usize) void {
    const l16: u16 = @truncate(len);
    const o16: u16 = @truncate(offset);
    std.mem.writeInt(u16, dest[0..2], l16, .little);
    std.mem.writeInt(u16, dest[2..4], l16, .little);
    std.mem.writeInt(u16, dest[4..6], o16, .little);
    dest[6] = 0;
    dest[7] = 0;
}

pub export fn Curl_auth_create_ntlm_type3_message(
    data: ?*anyopaque,
    creds: ?*const Curl_creds,
    ntlm: *ntlmdata,
    out: *bufref,
) callconv(.c) CURLcode {
    var result: CURLcode = CURLE_OK;
    var ntlmbuf: [NTLM_BUFSIZE]u8 = @splat(0);
    var lmresp: [24]u8 = @splat(0);
    var ntresplen: c_uint = 24;
    var ntresp: [24]u8 = @splat(0);
    var ptr_ntresp: [*]const u8 = &ntresp;
    var ntlmv2resp: ?[*]u8 = null;
    defer {
        if (ntlmv2resp) |p| mem.free(p);
        Curl_auth_cleanup_ntlm(ntlm);
    }

    const unicode = (ntlm.flags & NTLMFLAG_NEGOTIATE_UNICODE) != 0;
    const host = "WORKSTATION";
    const userp = credsUser(creds);
    const passwdp: [*:0]const u8 = if (creds) |c| (c.passwd orelse "") else "";

    var domain: []const u8 = "";
    var user: []const u8 = userp;
    if (std.mem.indexOfScalar(u8, userp, '\\') orelse std.mem.indexOfScalar(u8, userp, '/')) |sep| {
        domain = userp[0..sep];
        user = userp[sep + 1 ..];
    }

    var domlen: usize = domain.len;
    var userlen: usize = user.len;
    var hostlen: usize = host.len;

    if ((ntlm.flags & NTLMFLAG_NEGOTIATE_NTLM2_KEY) != 0) {
        var ntbuffer: [0x18]u8 = @splat(0);
        var entropy: [8]u8 = undefined;
        var ntlmv2hash: [0x18]u8 = @splat(0);

        result = c_rand.Curl_rand_bytes(data, &entropy, 8);
        if (result != CURLE_OK) return result;

        result = Curl_ntlm_core_mk_nt_hash(passwdp, &ntbuffer);
        if (result != CURLE_OK) return result;

        result = Curl_ntlm_core_mk_ntlmv2_hash(user.ptr, userlen, domain.ptr, domlen, &ntbuffer, &ntlmv2hash);
        if (result != CURLE_OK) return result;

        result = Curl_ntlm_core_mk_lmv2_resp(&ntlmv2hash, &entropy, &ntlm.nonce, &lmresp);
        if (result != CURLE_OK) return result;

        result = Curl_ntlm_core_mk_ntlmv2_resp(&ntlmv2hash, &entropy, ntlm, &ntlmv2resp, &ntresplen);
        if (result != CURLE_OK) return result;

        ptr_ntresp = ntlmv2resp.?;
    } else {
        var ntbuffer: [0x18]u8 = @splat(0);
        var lmbuffer: [0x18]u8 = @splat(0);

        result = Curl_ntlm_core_mk_nt_hash(passwdp, &ntbuffer);
        if (result != CURLE_OK) return result;

        Curl_ntlm_core_lm_resp(&ntbuffer, &ntlm.nonce, &ntresp);

        result = Curl_ntlm_core_mk_lm_hash(passwdp, &lmbuffer);
        if (result != CURLE_OK) return result;

        Curl_ntlm_core_lm_resp(&lmbuffer, &ntlm.nonce, &lmresp);
        ntlm.flags &= ~NTLMFLAG_NEGOTIATE_NTLM2_KEY;
    }

    if (unicode) {
        domlen *= 2;
        userlen *= 2;
        hostlen *= 2;
    }

    const lmrespoff: usize = 64;
    const ntrespoff: usize = lmrespoff + 0x18;
    const domoff: usize = ntrespoff + @as(usize, ntresplen);
    const useroff: usize = domoff + domlen;
    const hostoff: usize = useroff + userlen;

    @memcpy(ntlmbuf[0..8], NTLMSSP_SIGNATURE);
    ntlmbuf[8] = 0x03;
    writeSecurityBuffer(ntlmbuf[12..20], 0x18, lmrespoff);
    writeSecurityBuffer(ntlmbuf[20..28], ntresplen, ntrespoff);
    writeSecurityBuffer(ntlmbuf[28..36], domlen, domoff);
    writeSecurityBuffer(ntlmbuf[36..44], userlen, useroff);
    writeSecurityBuffer(ntlmbuf[44..52], hostlen, hostoff);
    // Session key security buffer at 52..60 is already 0
    std.mem.writeInt(u32, ntlmbuf[60..64], ntlm.flags, .little);

    var size: usize = 64;
    @memcpy(ntlmbuf[size .. size + 0x18], &lmresp);
    size += 0x18;

    if (@as(usize, ntresplen) + size > ntlmbuf.len) {
        failf(data, "incoming NTLM message too big");
        return CURLE_TOO_LARGE;
    }
    @memcpy(ntlmbuf[size .. size + ntresplen], ptr_ntresp[0..ntresplen]);
    size += ntresplen;

    if (size + userlen + domlen + hostlen >= NTLM_BUFSIZE) {
        failf(data, "user + domain + hostname too big for NTLM");
        return CURLE_TOO_LARGE;
    }

    if (unicode) {
        asciiToUnicodeLe(ntlmbuf[size..].ptr, domain.ptr, domlen / 2);
    } else if (domlen > 0) {
        @memcpy(ntlmbuf[size .. size + domlen], domain);
    }
    size += domlen;

    if (unicode) {
        asciiToUnicodeLe(ntlmbuf[size..].ptr, user.ptr, userlen / 2);
    } else if (userlen > 0) {
        @memcpy(ntlmbuf[size .. size + userlen], user);
    }
    size += userlen;

    if (unicode) {
        asciiToUnicodeLe(ntlmbuf[size..].ptr, host.ptr, hostlen / 2);
    } else {
        @memcpy(ntlmbuf[size .. size + hostlen], host);
    }
    size += hostlen;

    return Curl_bufref_memdup0(out, &ntlmbuf, size);
}

pub export fn Curl_auth_cleanup_ntlm(ntlm: *ntlmdata) callconv(.c) void {
    if (ntlm.target_info) |ti| {
        mem.free(ti);
        ntlm.target_info = null;
    }
    ntlm.target_info_len = 0;
}

// ============================================================================
// Unit Tests
// ============================================================================

test "PLAIN, LOGIN, and EXTERNAL cleartext messages" {
    var out: bufref = undefined;
    Curl_bufref_init(&out);
    defer Curl_bufref_free(&out);

    var creds = Curl_creds{
        .user = "alice",
        .passwd = "secret123",
        .sasl_authzid = "admin",
    };

    try std.testing.expectEqual(CURLE_OK, Curl_auth_create_plain_message(&creds, &out));
    try std.testing.expectEqual(@as(usize, 5 + 1 + 5 + 1 + 9), Curl_bufref_len(&out));
    const plain_slice = Curl_bufref_uptr(&out).?[0..Curl_bufref_len(&out)];
    try std.testing.expectEqualSlices(u8, "admin\x00alice\x00secret123", plain_slice);

    Curl_auth_create_login_message("alice", &out);
    try std.testing.expectEqual(@as(usize, 5), Curl_bufref_len(&out));
    try std.testing.expectEqualStrings("alice", std.mem.span(Curl_bufref_ptr(&out).?));

    Curl_auth_create_external_message("bob", &out);
    try std.testing.expectEqual(@as(usize, 3), Curl_bufref_len(&out));
    try std.testing.expectEqualStrings("bob", std.mem.span(Curl_bufref_ptr(&out).?));
}

test "CRAM-MD5 RFC 2195 test vector" {
    // RFC 2195 Section 2 example:
    // Challenge: <1896.697170952@postoffice.reston.mci.net>
    // User: tim, Secret: tanstaaftanstaaf
    // Expected: tim b913a602c7eda7a495b4e6e7334d3890
    var chlg: bufref = undefined;
    Curl_bufref_init(&chlg);
    defer Curl_bufref_free(&chlg);

    const challenge_str = "<1896.697170952@postoffice.reston.mci.net>";
    Curl_bufref_set(&chlg, challenge_str.ptr, challenge_str.len, null);

    var creds = Curl_creds{
        .user = "tim",
        .passwd = "tanstaaftanstaaf",
    };

    var out: bufref = undefined;
    Curl_bufref_init(&out);
    defer Curl_bufref_free(&out);

    try std.testing.expectEqual(CURLE_OK, Curl_auth_create_cram_md5_message(&chlg, &creds, &out));
    const got = Curl_bufref_uptr(&out).?[0..Curl_bufref_len(&out)];
    try std.testing.expectEqualStrings("tim b913a602c7eda7a495b4e6e7334d3890", got);
}

test "OAuth2 and XOAuth2 bearer messages" {
    var creds = Curl_creds{
        .user = "user@example.com",
        .oauth_bearer = "ya29.token123",
    };

    var out: bufref = undefined;
    Curl_bufref_init(&out);
    defer Curl_bufref_free(&out);

    try std.testing.expectEqual(CURLE_OK, Curl_auth_create_oauth_bearer_message(&creds, "mail.example.com", 80, &out));
    const oauth80 = Curl_bufref_uptr(&out).?[0..Curl_bufref_len(&out)];
    const expected80 = "n,a=user@example.com,\x01host=mail.example.com\x01auth=" ++ "Bearer ya29.token123\x01\x01";
    try std.testing.expectEqualStrings(expected80, oauth80);

    try std.testing.expectEqual(CURLE_OK, Curl_auth_create_oauth_bearer_message(&creds, "mail.example.com", 993, &out));
    const oauth993 = Curl_bufref_uptr(&out).?[0..Curl_bufref_len(&out)];
    const expected993 = "n,a=user@example.com,\x01host=mail.example.com\x01port=993\x01auth=" ++ "Bearer ya29.token123\x01\x01";
    try std.testing.expectEqualStrings(expected993, oauth993);

    try std.testing.expectEqual(CURLE_OK, Curl_auth_create_xoauth_bearer_message(&creds, &out));
    const xoauth = Curl_bufref_uptr(&out).?[0..Curl_bufref_len(&out)];
    const expected_xoauth = "user=user@example.com\x01auth=" ++ "Bearer ya29.token123\x01\x01";
    try std.testing.expectEqualStrings(expected_xoauth, xoauth);
}

test "NTLM core hashes and DES responses (unit1600 and Davenport vectors)" {
    var output: [21]u8 = undefined;

    // unit1600 vectors for Curl_ntlm_core_mk_nt_hash
    try std.testing.expectEqual(CURLE_OK, Curl_ntlm_core_mk_nt_hash("1", &output));
    try std.testing.expectEqualSlices(
        u8,
        "\x69\x94\x3c\x5e\x63\xb4\xd2\xc1\x04\xdb\xbc\xc1\x51\x38\xb7\x2b\x00\x00\x00\x00\x00",
        &output,
    );

    try std.testing.expectEqual(CURLE_OK, Curl_ntlm_core_mk_nt_hash("hello-you-fool", &output));
    try std.testing.expectEqualSlices(
        u8,
        "\x39\xaf\x87\xa6\x75\x0a\x7a\x00\xba\xa0\xd3\x4f\x04\x9e\xc1\xd0\x00\x00\x00\x00\x00",
        &output,
    );

    const long_a =
        "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" ++
        "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" ++
        "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" ++
        "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA" ++
        "AAAAAAAA";
    try std.testing.expectEqual(CURLE_OK, Curl_ntlm_core_mk_nt_hash(long_a, &output));
    try std.testing.expectEqualSlices(
        u8,
        "\x36\x9d\xae\x06\x84\x7e\xe1\xc1\x4a\x94\x39\xea\x6f\x44\x8c\x65\x00\x00\x00\x00\x00",
        &output,
    );

    // Davenport NTLM specification test vector for "SecREt01"
    var lm_hash: [21]u8 = undefined;
    try std.testing.expectEqual(CURLE_OK, Curl_ntlm_core_mk_lm_hash("SecREt01", &lm_hash));
    try std.testing.expectEqualSlices(
        u8,
        "\xff\x37\x50\xbc\xc2\xb2\x24\x12\xc2\x26\x5b\x23\x73\x4e\x0d\xac\x00\x00\x00\x00\x00",
        &lm_hash,
    );

    const challenge = [8]u8{ 0x01, 0x23, 0x45, 0x67, 0x89, 0xab, 0xcd, 0xef };
    var lm_resp: [24]u8 = undefined;
    Curl_ntlm_core_lm_resp(&lm_hash, &challenge, &lm_resp);
    try std.testing.expectEqualSlices(
        u8,
        "\xc3\x37\xcd\x5c\xbd\x44\xfc\x97\x82\xa6\x67\xaf\x6d\x42\x7c\x6d\xe6\x7c\x20\xc2\xd3\xe7\x7c\x56",
        &lm_resp,
    );
}

test "NTLM Type 1, Type 2, and Type 3 message handling" {
    try std.testing.expect(Curl_auth_is_ntlm_supported());

    var ntlm = ntlmdata{};
    defer Curl_auth_cleanup_ntlm(&ntlm);

    var out: bufref = undefined;
    Curl_bufref_init(&out);
    defer Curl_bufref_free(&out);

    var creds = Curl_creds{
        .user = "DOMAIN\\user",
        .passwd = "SecREt01",
    };

    // 1. Type 1 message
    try std.testing.expectEqual(
        CURLE_OK,
        Curl_auth_create_ntlm_type1_message(null, &creds, "HTTP", "example.com", &ntlm, &out),
    );
    try std.testing.expectEqual(@as(usize, 32), Curl_bufref_len(&out));
    const type1 = Curl_bufref_uptr(&out).?[0..32];
    try std.testing.expectEqualSlices(u8, "NTLMSSP\x00\x01\x00\x00\x00\x06\x82\x08\x00", type1[0..16]);

    // 2. Type 2 message decode (NTLMv1 unicode + target info)
    var type2_raw: [56]u8 = @splat(0);
    @memcpy(type2_raw[0..8], "NTLMSSP\x00");
    type2_raw[8] = 0x02;
    const t2_flags: u32 = NTLMFLAG_NEGOTIATE_UNICODE | NTLMFLAG_NEGOTIATE_NTLM_KEY | NTLMFLAG_NEGOTIATE_TARGET_INFO;
    std.mem.writeInt(u32, type2_raw[20..24], t2_flags, .little);
    const server_nonce = [8]u8{ 0x01, 0x23, 0x45, 0x67, 0x89, 0xab, 0xcd, 0xef };
    @memcpy(type2_raw[24..32], &server_nonce);
    // Target info: 8 bytes at offset 48
    std.mem.writeInt(u16, type2_raw[40..42], 8, .little);
    std.mem.writeInt(u16, type2_raw[42..44], 8, .little);
    std.mem.writeInt(u32, type2_raw[44..48], 48, .little);
    @memcpy(type2_raw[48..56], "\x02\x00\x04\x00D\x00\x00\x00");

    var type2ref: bufref = undefined;
    Curl_bufref_init(&type2ref);
    Curl_bufref_set(&type2ref, &type2_raw, type2_raw.len, null);

    try std.testing.expectEqual(CURLE_OK, Curl_auth_decode_ntlm_type2_message(null, &type2ref, &ntlm));
    try std.testing.expectEqual(t2_flags, ntlm.flags);
    try std.testing.expectEqualSlices(u8, &server_nonce, &ntlm.nonce);
    try std.testing.expectEqual(@as(c_uint, 8), ntlm.target_info_len);

    // 3. Type 3 message (NTLMv1)
    try std.testing.expectEqual(CURLE_OK, Curl_auth_create_ntlm_type3_message(null, &creds, &ntlm, &out));
    const type3 = Curl_bufref_uptr(&out).?[0..Curl_bufref_len(&out)];
    // 64 header + 24 LM + 24 NT + 12 domain ("DOMAIN" UTF-16LE) + 8 user ("user" UTF-16LE) + 22 host ("WORKSTATION" UTF-16LE) = 154
    try std.testing.expectEqual(@as(usize, 154), type3.len);
    try std.testing.expectEqualSlices(u8, "NTLMSSP\x00\x03\x00\x00\x00", type3[0..12]);
    try std.testing.expectEqualSlices(
        u8,
        "\xc3\x37\xcd\x5c\xbd\x44\xfc\x97\x82\xa6\x67\xaf\x6d\x42\x7c\x6d\xe6\x7c\x20\xc2\xd3\xe7\x7c\x56",
        type3[64..88],
    );
}
