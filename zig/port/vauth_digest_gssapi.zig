const std = @import("std");
const builtin = @import("builtin");
const backend_options = @import("backend_options");
const mem = @import("mem.zig");
const curlx_parse = @import("curlx_parse.zig");
const crypto = @import("crypto.zig");

const CURLcode = c_uint;
const CURLE_OK: CURLcode = 0;
const CURLE_COULDNT_RESOLVE_PROXY: CURLcode = 5;
const CURLE_COULDNT_CONNECT: CURLcode = 7;
const CURLE_OUT_OF_MEMORY: CURLcode = 27;
const CURLE_SEND_ERROR: CURLcode = 55;
const CURLE_RECV_ERROR: CURLcode = 56;
const CURLE_BAD_CONTENT_ENCODING: CURLcode = 61;
const CURLE_LOGIN_DENIED: CURLcode = 67;
const CURLE_AGAIN: CURLcode = 81;
const CURLE_AUTH_ERROR: CURLcode = 94;

pub const DIGEST_MAX_VALUE_LENGTH: usize = 256;
pub const DIGEST_MAX_CONTENT_LENGTH: usize = 1024;

const DIGEST_QOP_VALUE_AUTH: c_int = 1 << 0;
const DIGEST_QOP_VALUE_AUTH_INT: c_int = 1 << 1;
const DIGEST_QOP_VALUE_AUTH_CONF: c_int = 1 << 2;

const DIGEST_QOP_VALUE_STRING_AUTH = "auth";
const DIGEST_QOP_VALUE_STRING_AUTH_INT = "auth-int";
const DIGEST_QOP_VALUE_STRING_AUTH_CONF = "auth-conf";

pub const SESSION_ALGO: u8 = 1;
pub const ALGO_MD5: u8 = 0;
pub const ALGO_MD5SESS: u8 = ALGO_MD5 | SESSION_ALGO;
pub const ALGO_SHA256: u8 = 2;
pub const ALGO_SHA256SESS: u8 = ALGO_SHA256 | SESSION_ALGO;
pub const ALGO_SHA512_256: u8 = 4;
pub const ALGO_SHA512_256SESS: u8 = ALGO_SHA512_256 | SESSION_ALGO;

const DIGEST_HASH_LEN: usize = 32;
const DIGEST_HEX_LEN: usize = 2 * DIGEST_HASH_LEN + 1;

const Curl_str = curlx_parse.Curl_str;

pub const dynbuf = extern struct {
    bufr: ?[*]u8 = null,
    leng: usize = 0,
    allc: usize = 0,
    toobig: usize = 0,
};

pub const bufref = extern struct {
    dtor: ?*const fn (?*anyopaque) callconv(.c) void = null,
    ptr: ?[*]const u8 = null,
    len: usize = 0,
};

pub const Curl_creds = extern struct {
    user: ?[*:0]const u8 = null,
    passwd: ?[*:0]const u8 = null,
    oauth_bearer: ?[*:0]const u8 = null,
    sasl_authzid: ?[*:0]const u8 = null,
    sasl_service: ?[*:0]const u8 = null,
    refcount: u32 = 0,
    source: u8 = 0,
    bufsize: usize = 0,
    buf: [1]u8 = .{0},
};

pub const DigestDataRfc = extern struct {
    creds: ?*Curl_creds = null,
    origin: ?*anyopaque = null,
    nonce: ?[*:0]u8 = null,
    cnonce: ?[*:0]u8 = null,
    realm: ?[*:0]u8 = null,
    @"opaque": ?[*:0]u8 = null,
    qop: ?[*:0]u8 = null,
    algorithm: ?[*:0]u8 = null,
    nc: c_int = 0,
    algo: u8 = ALGO_MD5,
    flags: u8 = 0, // bit 0 = stale, bit 1 = userhash

    pub fn isStale(self: *const DigestDataRfc) bool {
        return (self.flags & 0x01) != 0;
    }

    pub fn setStale(self: *DigestDataRfc, val: bool) void {
        if (val) {
            self.flags |= 0x01;
        } else {
            self.flags &= ~@as(u8, 0x01);
        }
    }

    pub fn isUserhash(self: *const DigestDataRfc) bool {
        return (self.flags & 0x02) != 0;
    }

    pub fn setUserhash(self: *DigestDataRfc, val: bool) void {
        if (val) {
            self.flags |= 0x02;
        } else {
            self.flags &= ~@as(u8, 0x02);
        }
    }
};

extern fn curl_free(p: ?*anyopaque) callconv(.c) void;

extern fn curlx_str_until(linep: *[*:0]const u8, out: *Curl_str, max: usize, delim: u8) callconv(.c) c_int;
extern fn curlx_str_single(linep: *[*:0]const u8, expect: u8) callconv(.c) c_int;
extern fn curlx_str_word(linep: *[*:0]const u8, out: *Curl_str, max: usize) callconv(.c) c_int;
extern fn curlx_str_passblanks(linep: *[*:0]const u8) callconv(.c) void;
extern fn curlx_str_casecompare(str: *Curl_str, check: ?[*:0]const u8) callconv(.c) c_int;

extern fn curlx_dyn_init(s: *dynbuf, toobig: usize) callconv(.c) void;
extern fn curlx_dyn_addn(s: *dynbuf, mem_ptr: ?*const anyopaque, len: usize) callconv(.c) CURLcode;
extern fn curlx_dyn_add(s: *dynbuf, str: [*:0]const u8) callconv(.c) CURLcode;
extern fn curlx_dyn_addf(s: *dynbuf, fmt: [*:0]const u8, ...) callconv(.c) CURLcode;
extern fn curlx_dyn_ptr(s: *const dynbuf) callconv(.c) ?[*:0]u8;
extern fn curlx_dyn_len(s: *const dynbuf) callconv(.c) usize;

extern fn curlx_base64_encode(inputbuff: [*]const u8, insize: usize, outptr: *?[*]u8, outlen: *usize) callconv(.c) CURLcode;
extern fn curl_strequal(first: ?[*:0]const u8, second: ?[*:0]const u8) callconv(.c) c_int;
extern fn curlx_uztoui(uznum: usize) callconv(.c) c_uint;
extern fn curlx_uztoul(uznum: usize) callconv(.c) c_ulong;

extern fn Curl_rand_bytes(data: ?*anyopaque, rnd: [*]u8, num: usize) callconv(.c) CURLcode;
extern fn Curl_rand_hex(data: ?*anyopaque, rnd: [*]u8, num: usize) callconv(.c) CURLcode;
extern fn Curl_peer_unlink(peerp: *?*anyopaque) callconv(.c) void;
extern fn Curl_creds_unlink(credsp: *?*Curl_creds) callconv(.c) void;
extern fn Curl_bufref_set(br: *bufref, ptr: ?*const anyopaque, len: usize, dtor: ?*const fn (?*anyopaque) callconv(.c) void) callconv(.c) void;
extern fn Curl_bufref_ptr(br: *const bufref) callconv(.c) ?[*]const u8;
extern fn Curl_bufref_len(br: *const bufref) callconv(.c) usize;
extern fn Curl_infof(data: ?*anyopaque, fmt: [*:0]const u8, ...) callconv(.c) void;
extern fn Curl_failf(data: ?*anyopaque, fmt: [*:0]const u8, ...) callconv(.c) void;
extern fn curl_msnprintf(buffer: [*]u8, maxlength: usize, format: [*:0]const u8, ...) callconv(.c) c_int;
extern fn curl_maprintf(format: [*:0]const u8, ...) callconv(.c) ?[*:0]u8;
extern fn Curl_hexbyte(dest: [*]u8, val: u8) callconv(.c) void;

inline fn isBlank(c: u8) bool {
    return c == ' ' or c == '\t';
}

fn safeFreeStr(ptr: *?[*:0]u8) void {
    if (ptr.*) |p| {
        mem.free(@ptrCast(p));
        ptr.* = null;
    }
}

fn safeFreeBytes(ptr: *?[*]u8) void {
    if (ptr.*) |p| {
        mem.free(@ptrCast(p));
        ptr.* = null;
    }
}

// ============================================================================
// 1. lib/vauth/digest.c — RFC 2617 / RFC 7616 Digest Authentication
// ============================================================================

pub export fn Curl_auth_digest_get_pair(
    str_in: [*:0]const u8,
    value: *Curl_str,
    content: [*]u8,
    endptr: *[*:0]const u8,
) callconv(.c) bool {
    var str = str_in;
    var starts_with_quote = false;
    var escape = false;

    if (curlx_str_until(&str, value, DIGEST_MAX_VALUE_LENGTH, '=') != 0 or
        curlx_str_single(&str, '=') != 0)
    {
        return false;
    }

    if (str[0] == '"') {
        str += 1;
        starts_with_quote = true;
    }

    var content_length: usize = 0;
    var out = content;
    var c: c_int = @intCast(DIGEST_MAX_CONTENT_LENGTH);
    while (str[0] != 0 and blk: {
        const prev = c;
        c -= 1;
        break :blk prev != 0;
    }) : (str += 1) {
        const ch = str[0];
        if (!escape) {
            switch (ch) {
                '\\' => {
                    if (starts_with_quote) {
                        escape = true;
                        continue;
                    }
                },
                ',' => {
                    if (!starts_with_quote) {
                        c = 0;
                        continue;
                    }
                },
                '\r', '\n' => {
                    if (starts_with_quote) {
                        return false;
                    }
                    c = 0;
                    continue;
                },
                '"' => {
                    if (starts_with_quote) {
                        c = 0;
                        continue;
                    } else {
                        return false;
                    }
                },
                else => {},
            }
        }
        if (content_length >= DIGEST_MAX_CONTENT_LENGTH - 1) {
            return false;
        }
        escape = false;
        out[0] = ch;
        out += 1;
        content_length += 1;
    }

    if (escape) {
        return false;
    }

    out[0] = 0;
    endptr.* = str;

    return true;
}

const DigestToAsciiFn = *const fn ([*]const u8, [*]u8) callconv(.c) void;
const DigestHashFn = *const fn ([*]u8, [*]const u8, usize) callconv(.c) CURLcode;

fn authDigestMd5ToAscii(source: [*]const u8, dest: [*]u8) callconv(.c) void {
    const hex = "0123456789abcdef";
    for (0..16) |i| {
        const b = source[i];
        dest[i * 2] = hex[b >> 4];
        dest[i * 2 + 1] = hex[b & 0x0f];
    }
    dest[32] = 0;
}

fn authDigestSha256ToAscii(source: [*]const u8, dest: [*]u8) callconv(.c) void {
    const hex = "0123456789abcdef";
    for (0..32) |i| {
        const b = source[i];
        dest[i * 2] = hex[b >> 4];
        dest[i * 2 + 1] = hex[b & 0x0f];
    }
    dest[64] = 0;
}

fn authDigestStringQuoted(source: [*:0]const u8) ?[*:0]u8 {
    var out: dynbuf = .{};
    curlx_dyn_init(&out, 2048);
    if (source[0] == 0) {
        return mem.strdup("");
    }
    var s = source;
    while (s[0] != 0) : (s += 1) {
        const ch = s[0];
        var result: CURLcode = CURLE_OK;
        if (ch == '"' or ch == '\\') {
            result = curlx_dyn_addn(&out, "\\", 1);
            if (result == CURLE_OK) {
                result = curlx_dyn_addn(&out, s, 1);
            }
        } else if (ch < ' ' or ch > 0x7e) {
            var buf: [3]u8 = .{ '%', 0, 0 };
            Curl_hexbyte(buf[1..].ptr, ch);
            result = curlx_dyn_addn(&out, &buf, 3);
        } else {
            result = curlx_dyn_addn(&out, s, 1);
        }
        if (result != CURLE_OK) {
            return null;
        }
    }
    return curlx_dyn_ptr(&out);
}

fn authDigestGetKeyValue(
    chlg: [*:0]const u8,
    key: [*:0]const u8,
    value: [*]u8,
    max_val_len: usize,
    end_char: u8,
) bool {
    const chlg_slice = std.mem.span(chlg);
    const key_slice = std.mem.span(key);
    const idx = std.mem.indexOf(u8, chlg_slice, key_slice) orelse return false;

    var find_pos = chlg + idx + key_slice.len;
    var i: usize = 0;
    while (find_pos[0] != 0 and find_pos[0] != end_char and i < max_val_len - 1) : (i += 1) {
        value[i] = find_pos[0];
        find_pos += 1;
    }
    value[i] = 0;
    return true;
}

fn authDigestGetQopValues(options: [*:0]const u8, value: *c_int) CURLcode {
    value.* = 0;
    var ptr: [*:0]const u8 = options;
    var out = Curl_str{ .str = null, .len = 0 };
    while (curlx_str_word(&ptr, &out, 32) == 0) {
        if (curlx_str_casecompare(&out, DIGEST_QOP_VALUE_STRING_AUTH) != 0) {
            value.* |= DIGEST_QOP_VALUE_AUTH;
        } else if (curlx_str_casecompare(&out, DIGEST_QOP_VALUE_STRING_AUTH_INT) != 0) {
            value.* |= DIGEST_QOP_VALUE_AUTH_INT;
        } else if (curlx_str_casecompare(&out, DIGEST_QOP_VALUE_STRING_AUTH_CONF) != 0) {
            value.* |= DIGEST_QOP_VALUE_AUTH_CONF;
        }
        if (curlx_str_single(&ptr, ',') != 0) {
            break;
        }
    }
    return CURLE_OK;
}

fn authDecodeDigestMd5Message(
    chlg: *const bufref,
    nonce: [*]u8,
    nlen: usize,
    realm: [*]u8,
    rlen: usize,
    alg: [*]u8,
    alen: usize,
    qop: [*]u8,
    qlen: usize,
) CURLcode {
    const chlg_len = Curl_bufref_len(chlg);
    if (chlg_len == 0) {
        return CURLE_BAD_CONTENT_ENCODING;
    }
    const chlg_ptr: [*:0]const u8 = @ptrCast(Curl_bufref_ptr(chlg) orelse return CURLE_BAD_CONTENT_ENCODING);

    if (!authDigestGetKeyValue(chlg_ptr, "nonce=\"", nonce, nlen, '"')) {
        return CURLE_BAD_CONTENT_ENCODING;
    }

    if (!authDigestGetKeyValue(chlg_ptr, "realm=\"", realm, rlen, '"')) {
        realm[0] = 0;
    }

    if (!authDigestGetKeyValue(chlg_ptr, "algorithm=", alg, alen, ',')) {
        return CURLE_BAD_CONTENT_ENCODING;
    }

    if (!authDigestGetKeyValue(chlg_ptr, "qop=\"", qop, qlen, '"')) {
        return CURLE_BAD_CONTENT_ENCODING;
    }

    return CURLE_OK;
}

pub fn isDigestSupportedRfc() callconv(.c) bool {
    return true;
}

pub fn createDigestMd5MessageHostRfc(
    data: ?*anyopaque,
    hostname: [*:0]const u8,
    chlg: *const bufref,
    creds: *Curl_creds,
    default_service: [*:0]const u8,
    out: *bufref,
) callconv(.c) CURLcode {
    var digest: [16]u8 = undefined;
    var HA1_hex: [33]u8 = undefined;
    var HA2_hex: [33]u8 = undefined;
    var resp_hash_hex: [33]u8 = undefined;
    var nonce: [64]u8 = undefined;
    var realm: [128]u8 = undefined;
    var algorithm: [64]u8 = undefined;
    var qop_options: [64]u8 = undefined;
    var qop_values: c_int = 0;
    var cnonce: [33]u8 = undefined;
    const nc: c_uint = 1;
    const method: [*:0]const u8 = "AUTHENTICATE";
    const qop: [*:0]const u8 = DIGEST_QOP_VALUE_STRING_AUTH;

    var result = Curl_rand_hex(data, &cnonce, cnonce.len);
    if (result != CURLE_OK) {
        return result;
    }

    result = authDecodeDigestMd5Message(
        chlg,
        &nonce,
        nonce.len,
        &realm,
        realm.len,
        &algorithm,
        algorithm.len,
        &qop_options,
        qop_options.len,
    );
    if (result != CURLE_OK) {
        return result;
    }

    const alg_cstr: [*:0]const u8 = @ptrCast(&algorithm);
    if (!std.mem.eql(u8, std.mem.span(alg_cstr), "md5-sess")) {
        return CURLE_BAD_CONTENT_ENCODING;
    }

    const qop_opt_cstr: [*:0]const u8 = @ptrCast(&qop_options);
    result = authDigestGetQopValues(qop_opt_cstr, &qop_values);
    if (result != CURLE_OK) {
        return result;
    }

    if ((qop_values & DIGEST_QOP_VALUE_AUTH) == 0) {
        return CURLE_BAD_CONTENT_ENCODING;
    }

    var ctxt = crypto.Curl_MD5_init(&crypto.Curl_DIGEST_MD5[0]) orelse return CURLE_OUT_OF_MEMORY;
    const user_str: [*:0]const u8 = creds.user orelse "";
    const passwd_str: [*:0]const u8 = creds.passwd orelse "";
    const realm_cstr: [*:0]const u8 = @ptrCast(&realm);
    const nonce_cstr: [*:0]const u8 = @ptrCast(&nonce);
    const cnonce_cstr: [*:0]const u8 = @ptrCast(&cnonce);

    _ = crypto.Curl_MD5_update(ctxt, user_str, curlx_uztoui(std.mem.len(user_str)));
    _ = crypto.Curl_MD5_update(ctxt, ":", 1);
    _ = crypto.Curl_MD5_update(ctxt, realm_cstr, curlx_uztoui(std.mem.len(realm_cstr)));
    _ = crypto.Curl_MD5_update(ctxt, ":", 1);
    _ = crypto.Curl_MD5_update(ctxt, passwd_str, curlx_uztoui(std.mem.len(passwd_str)));
    _ = crypto.Curl_MD5_final(ctxt, &digest);

    ctxt = crypto.Curl_MD5_init(&crypto.Curl_DIGEST_MD5[0]) orelse return CURLE_OUT_OF_MEMORY;
    _ = crypto.Curl_MD5_update(ctxt, &digest, 16);
    _ = crypto.Curl_MD5_update(ctxt, ":", 1);
    _ = crypto.Curl_MD5_update(ctxt, nonce_cstr, curlx_uztoui(std.mem.len(nonce_cstr)));
    _ = crypto.Curl_MD5_update(ctxt, ":", 1);
    _ = crypto.Curl_MD5_update(ctxt, cnonce_cstr, curlx_uztoui(std.mem.len(cnonce_cstr)));
    _ = crypto.Curl_MD5_final(ctxt, &digest);

    for (0..16) |i| {
        _ = curl_msnprintf(HA1_hex[2 * i ..].ptr, 3, "%02x", @as(c_uint, digest[i]));
    }

    const service: [*:0]const u8 = creds.sasl_service orelse default_service;
    const spn = FormatSpn(service, hostname, null) orelse return CURLE_OUT_OF_MEMORY;

    ctxt = crypto.Curl_MD5_init(&crypto.Curl_DIGEST_MD5[0]) orelse {
        mem.free(@ptrCast(spn));
        return CURLE_OUT_OF_MEMORY;
    };
    _ = crypto.Curl_MD5_update(ctxt, method, curlx_uztoui(std.mem.len(method)));
    _ = crypto.Curl_MD5_update(ctxt, ":", 1);
    _ = crypto.Curl_MD5_update(ctxt, spn, curlx_uztoui(std.mem.len(spn)));
    _ = crypto.Curl_MD5_final(ctxt, &digest);

    for (0..16) |i| {
        _ = curl_msnprintf(HA2_hex[2 * i ..].ptr, 3, "%02x", @as(c_uint, digest[i]));
    }

    ctxt = crypto.Curl_MD5_init(&crypto.Curl_DIGEST_MD5[0]) orelse {
        mem.free(@ptrCast(spn));
        return CURLE_OUT_OF_MEMORY;
    };
    _ = crypto.Curl_MD5_update(ctxt, &HA1_hex, 32);
    _ = crypto.Curl_MD5_update(ctxt, ":", 1);
    _ = crypto.Curl_MD5_update(ctxt, nonce_cstr, curlx_uztoui(std.mem.len(nonce_cstr)));
    _ = crypto.Curl_MD5_update(ctxt, ":", 1);

    var nc_buf: [9]u8 = undefined;
    _ = curl_msnprintf(&nc_buf, nc_buf.len, "%08x", nc);
    const nc_cstr: [*:0]const u8 = @ptrCast(&nc_buf);
    _ = crypto.Curl_MD5_update(ctxt, nc_cstr, curlx_uztoui(std.mem.len(nc_cstr)));
    _ = crypto.Curl_MD5_update(ctxt, ":", 1);
    _ = crypto.Curl_MD5_update(ctxt, cnonce_cstr, curlx_uztoui(std.mem.len(cnonce_cstr)));
    _ = crypto.Curl_MD5_update(ctxt, ":", 1);
    _ = crypto.Curl_MD5_update(ctxt, qop, curlx_uztoui(std.mem.len(qop)));
    _ = crypto.Curl_MD5_update(ctxt, ":", 1);
    _ = crypto.Curl_MD5_update(ctxt, &HA2_hex, 32);
    _ = crypto.Curl_MD5_final(ctxt, &digest);

    for (0..16) |i| {
        _ = curl_msnprintf(resp_hash_hex[2 * i ..].ptr, 3, "%02x", @as(c_uint, digest[i]));
    }

    var uname: ?[*:0]u8 = authDigestStringQuoted(user_str);
    var rname: ?[*:0]u8 = authDigestStringQuoted(realm_cstr);
    var nname: ?[*:0]u8 = authDigestStringQuoted(nonce_cstr);
    var cname: ?[*:0]u8 = authDigestStringQuoted(cnonce_cstr);
    var suri: ?[*:0]u8 = authDigestStringQuoted(spn);
    var response: ?[*:0]u8 = null;

    if (uname != null and rname != null and nname != null and cname != null and suri != null) {
        const resp_hash_cstr: [*:0]const u8 = @ptrCast(&resp_hash_hex);
        response = curl_maprintf(
            "username=\"%s\",realm=\"%s\",nonce=\"%s\",cnonce=\"%s\",nc=\"%08x\",digest-uri=\"%s\",response=%s,qop=%s",
            uname.?,
            rname.?,
            nname.?,
            cname.?,
            nc,
            suri.?,
            resp_hash_cstr,
            qop,
        );
    }

    safeFreeStr(&uname);
    safeFreeStr(&rname);
    safeFreeStr(&nname);
    safeFreeStr(&cname);
    safeFreeStr(&suri);
    mem.free(@ptrCast(spn));

    const resp_ptr = response orelse return CURLE_OUT_OF_MEMORY;
    var b64_ptr: ?[*]u8 = null;
    var b64_len: usize = 0;
    result = curlx_base64_encode(resp_ptr, std.mem.len(resp_ptr), &b64_ptr, &b64_len);
    mem.free(@ptrCast(resp_ptr));
    if (result == CURLE_OK) {
        Curl_bufref_set(out, b64_ptr, b64_len, curl_free);
    }
    return result;
}

pub fn decodeDigestHttpMessageRfc(chlg_in: [*:0]const u8, digest: *DigestDataRfc) callconv(.c) CURLcode {
    var chlg = chlg_in;
    const before = (digest.nonce != null);
    var foundAuth = false;
    var foundAuthInt = false;
    var content: [DIGEST_MAX_CONTENT_LENGTH]u8 = undefined;

    while (chlg[0] != 0) {
        var value = Curl_str{ .str = null, .len = 0 };
        if (Curl_auth_digest_get_pair(chlg, &value, &content, &chlg)) {
            const content_cstr: [*:0]const u8 = @ptrCast(&content);
            if (curlx_str_casecompare(&value, "nonce") != 0) {
                safeFreeStr(&digest.nonce);
                digest.nonce = mem.strdup(content_cstr) orelse return CURLE_OUT_OF_MEMORY;
            } else if (curlx_str_casecompare(&value, "stale") != 0) {
                if (curl_strequal(content_cstr, "true") != 0) {
                    digest.setStale(true);
                    digest.nc = 1;
                }
            } else if (curlx_str_casecompare(&value, "realm") != 0) {
                safeFreeStr(&digest.realm);
                digest.realm = mem.strdup(content_cstr) orelse return CURLE_OUT_OF_MEMORY;
            } else if (curlx_str_casecompare(&value, "opaque") != 0) {
                safeFreeStr(&digest.@"opaque");
                digest.@"opaque" = mem.strdup(content_cstr) orelse return CURLE_OUT_OF_MEMORY;
            } else if (curlx_str_casecompare(&value, "qop") != 0) {
                var tok = Curl_str{ .str = null, .len = 0 };
                var ptr: [*:0]const u8 = content_cstr;
                while (ptr[0] != 0 and blk: {
                    curlx_str_passblanks(&ptr);
                    break :blk curlx_str_until(&ptr, &tok, 32, ',') == 0;
                }) {
                    if (curlx_str_casecompare(&tok, DIGEST_QOP_VALUE_STRING_AUTH) != 0) {
                        foundAuth = true;
                    } else if (curlx_str_casecompare(&tok, DIGEST_QOP_VALUE_STRING_AUTH_INT) != 0) {
                        foundAuthInt = true;
                    }
                    if (curlx_str_single(&ptr, ',') != 0) {
                        break;
                    }
                }

                if (foundAuth) {
                    safeFreeStr(&digest.qop);
                    digest.qop = mem.strdup(DIGEST_QOP_VALUE_STRING_AUTH) orelse return CURLE_OUT_OF_MEMORY;
                } else if (foundAuthInt) {
                    safeFreeStr(&digest.qop);
                    digest.qop = mem.strdup(DIGEST_QOP_VALUE_STRING_AUTH_INT) orelse return CURLE_OUT_OF_MEMORY;
                }
            } else if (curlx_str_casecompare(&value, "algorithm") != 0) {
                safeFreeStr(&digest.algorithm);
                digest.algorithm = mem.strdup(content_cstr) orelse return CURLE_OUT_OF_MEMORY;

                if (curl_strequal(content_cstr, "MD5-sess") != 0) {
                    digest.algo = ALGO_MD5SESS;
                } else if (curl_strequal(content_cstr, "MD5") != 0) {
                    digest.algo = ALGO_MD5;
                } else if (curl_strequal(content_cstr, "SHA-256") != 0) {
                    digest.algo = ALGO_SHA256;
                } else if (curl_strequal(content_cstr, "SHA-256-SESS") != 0) {
                    digest.algo = ALGO_SHA256SESS;
                } else if (curl_strequal(content_cstr, "SHA-512-256") != 0) {
                    digest.algo = ALGO_SHA512_256;
                } else if (curl_strequal(content_cstr, "SHA-512-256-SESS") != 0) {
                    digest.algo = ALGO_SHA512_256SESS;
                } else {
                    return CURLE_BAD_CONTENT_ENCODING;
                }
            } else if (curlx_str_casecompare(&value, "userhash") != 0) {
                if (curl_strequal(content_cstr, "true") != 0) {
                    digest.setUserhash(true);
                }
            } else {
                // Unknown specifier, ignore it!
            }
        } else {
            break;
        }

        while (chlg[0] != 0 and isBlank(chlg[0])) {
            chlg += 1;
        }
        if (chlg[0] == ',') {
            chlg += 1;
        }
        while (chlg[0] != 0 and isBlank(chlg[0])) {
            chlg += 1;
        }
    }

    if (before and !digest.isStale()) {
        return CURLE_LOGIN_DENIED;
    }

    if (digest.nonce == null) {
        return CURLE_BAD_CONTENT_ENCODING;
    }

    if (digest.qop == null and (digest.algo & SESSION_ALGO) != 0) {
        return CURLE_BAD_CONTENT_ENCODING;
    }

    return CURLE_OK;
}

fn authCreateDigestHttpMessage(
    data: ?*anyopaque,
    creds: *Curl_creds,
    uripath: [*:0]const u8,
    request: [*:0]const u8,
    body: ?[*]const u8,
    blen: usize,
    digest: *DigestDataRfc,
    outptr: *?[*:0]u8,
    outlen: *usize,
    convert_to_ascii: DigestToAsciiFn,
    hash: DigestHashFn,
) CURLcode {
    var result: CURLcode = CURLE_OK;
    var hashbuf: [32]u8 = @splat(0);
    var request_digest: [65]u8 = undefined;
    var ha1: [65]u8 = undefined;
    var ha2: [65]u8 = undefined;
    var userh: [65]u8 = undefined;
    var cnonce: ?[*:0]u8 = null;
    var cnonce_len: usize = 0;

    outlen.* = 0;
    outptr.* = null;

    if (digest.nc == 0) {
        digest.nc = 1;
    }

    if (digest.cnonce == null) {
        var cnoncebuf: [12]u8 = undefined;
        result = Curl_rand_bytes(data, &cnoncebuf, cnoncebuf.len);
        if (result != CURLE_OK) {
            return result;
        }

        var cnonce_raw: ?[*]u8 = null;
        result = curlx_base64_encode(&cnoncebuf, cnoncebuf.len, &cnonce_raw, &cnonce_len);
        if (result != CURLE_OK) {
            return result;
        }
        cnonce = if (cnonce_raw) |p| @ptrCast(p) else null;
        digest.cnonce = cnonce;
    }

    const userp: [*:0]const u8 = creds.user orelse "";
    const passwdp: [*:0]const u8 = creds.passwd orelse "";
    const realm_str: [*:0]const u8 = if (digest.realm) |r| r else "";
    const nonce_str: [*:0]const u8 = if (digest.nonce) |n| n else "";
    const cnonce_str: [*:0]const u8 = if (digest.cnonce) |cn| cn else "";

    if (digest.isUserhash()) {
        const hashthis = curl_maprintf("%s:%s", userp, realm_str) orelse return CURLE_OUT_OF_MEMORY;
        result = hash(&hashbuf, hashthis, std.mem.len(hashthis));
        mem.free(@ptrCast(hashthis));
        if (result != CURLE_OK) {
            return result;
        }
        convert_to_ascii(&hashbuf, &userh);
    }

    {
        const hashthis = curl_maprintf("%s:%s:%s", userp, realm_str, passwdp) orelse return CURLE_OUT_OF_MEMORY;
        result = hash(&hashbuf, hashthis, std.mem.len(hashthis));
        mem.free(@ptrCast(hashthis));
        if (result != CURLE_OK) {
            return result;
        }
        convert_to_ascii(&hashbuf, &ha1);

        if ((digest.algo & SESSION_ALGO) != 0) {
            const ha1_cstr: [*:0]const u8 = @ptrCast(&ha1);
            const sess_str = curl_maprintf("%s:%s:%s", ha1_cstr, nonce_str, cnonce_str) orelse return CURLE_OUT_OF_MEMORY;
            result = hash(&hashbuf, sess_str, std.mem.len(sess_str));
            mem.free(@ptrCast(sess_str));
            if (result != CURLE_OK) {
                return result;
            }
            convert_to_ascii(&hashbuf, &ha1);
        }
    }

    {
        var hashthis: ?[*:0]u8 = curl_maprintf("%s:%s", request, uripath);
        if (hashthis == null) {
            return CURLE_OUT_OF_MEMORY;
        }

        if (digest.qop) |qop_ptr| {
            if (curl_strequal(qop_ptr, "auth-int") != 0) {
                var hashed: [65]u8 = undefined;
                const body_ptr: [*]const u8 = body orelse "";
                result = hash(&hashbuf, body_ptr, blen);
                if (result == CURLE_OK) {
                    convert_to_ascii(&hashbuf, &hashed);
                    const hashed_cstr: [*:0]const u8 = @ptrCast(&hashed);
                    const prev = hashthis.?;
                    hashthis = curl_maprintf("%s:%s", prev, hashed_cstr);
                    mem.free(@ptrCast(prev));
                }
                if (result != CURLE_OK) {
                    safeFreeStr(&hashthis);
                    return result;
                }
            }
        }

        const ht = hashthis orelse return CURLE_OUT_OF_MEMORY;
        result = hash(&hashbuf, ht, std.mem.len(ht));
        mem.free(@ptrCast(ht));
        if (result != CURLE_OK) {
            return result;
        }
        convert_to_ascii(&hashbuf, &ha2);
    }

    {
        const ha1_cstr: [*:0]const u8 = @ptrCast(&ha1);
        const ha2_cstr: [*:0]const u8 = @ptrCast(&ha2);
        var hashthis: ?[*:0]u8 = null;
        if (digest.qop) |qop_ptr| {
            hashthis = curl_maprintf(
                "%s:%s:%08x:%s:%s:%s",
                ha1_cstr,
                nonce_str,
                @as(c_uint, @bitCast(digest.nc)),
                cnonce_str,
                qop_ptr,
                ha2_cstr,
            );
        } else {
            hashthis = curl_maprintf("%s:%s:%s", ha1_cstr, nonce_str, ha2_cstr);
        }
        const ht = hashthis orelse return CURLE_OUT_OF_MEMORY;
        result = hash(&hashbuf, ht, std.mem.len(ht));
        mem.free(@ptrCast(ht));
        if (result != CURLE_OK) {
            return result;
        }
        convert_to_ascii(&hashbuf, &request_digest);
    }

    digest.nc += 1;

    var response: dynbuf = .{};
    curlx_dyn_init(&response, 4096);

    const user_to_quote: [*:0]const u8 = if (digest.isUserhash()) @ptrCast(&userh) else userp;
    var userp_quoted: ?[*:0]u8 = authDigestStringQuoted(user_to_quote);
    var realm_quoted: ?[*:0]u8 = authDigestStringQuoted(realm_str);
    var nonce_quoted: ?[*:0]u8 = authDigestStringQuoted(nonce_str);
    var uripath_quoted: ?[*:0]u8 = authDigestStringQuoted(uripath);

    if (userp_quoted != null and realm_quoted != null and nonce_quoted != null and uripath_quoted != null) {
        result = curlx_dyn_addf(
            &response,
            "username=\"%s\", realm=\"%s\", nonce=\"%s\", uri=\"%s\"",
            userp_quoted.?,
            realm_quoted.?,
            nonce_quoted.?,
            uripath_quoted.?,
        );
    } else {
        result = CURLE_OUT_OF_MEMORY;
    }
    safeFreeStr(&userp_quoted);
    safeFreeStr(&realm_quoted);
    safeFreeStr(&nonce_quoted);
    safeFreeStr(&uripath_quoted);
    if (result != CURLE_OK) {
        return result;
    }

    if (digest.qop) |qop_ptr| {
        var cnonce_quoted: ?[*:0]u8 = authDigestStringQuoted(cnonce_str);
        if (cnonce_quoted) |cq| {
            result = curlx_dyn_addf(
                &response,
                ", cnonce=\"%s\", nc=%08x, qop=%s",
                cq,
                @as(c_uint, @bitCast(digest.nc - 1)),
                qop_ptr,
            );
            safeFreeStr(&cnonce_quoted);
        } else {
            result = CURLE_OUT_OF_MEMORY;
        }
        if (result != CURLE_OK) {
            return result;
        }
    }

    const req_digest_cstr: [*:0]const u8 = @ptrCast(&request_digest);
    result = curlx_dyn_addf(&response, ", response=\"%s\"", req_digest_cstr);
    if (result != CURLE_OK) {
        return result;
    }

    if (digest.@"opaque") |opaque_ptr| {
        var opaque_quoted: ?[*:0]u8 = authDigestStringQuoted(opaque_ptr);
        if (opaque_quoted) |oq| {
            result = curlx_dyn_addf(&response, ", opaque=\"%s\"", oq);
            safeFreeStr(&opaque_quoted);
        } else {
            result = CURLE_OUT_OF_MEMORY;
        }
        if (result != CURLE_OK) {
            return result;
        }
    }

    if (digest.algorithm) |algo_ptr| {
        result = curlx_dyn_addf(&response, ", algorithm=%s", algo_ptr);
        if (result != CURLE_OK) {
            return result;
        }
    }

    if (digest.isUserhash()) {
        result = curlx_dyn_add(&response, ", userhash=true");
        if (result != CURLE_OK) {
            return result;
        }
    }

    outptr.* = curlx_dyn_ptr(&response) orelse return CURLE_OUT_OF_MEMORY;
    outlen.* = curlx_dyn_len(&response);
    return CURLE_OK;
}

pub fn createDigestHttpMessageRfc(
    data: ?*anyopaque,
    creds: *Curl_creds,
    uripath: [*:0]const u8,
    request: [*:0]const u8,
    body: ?[*]const u8,
    blen: usize,
    digest: *DigestDataRfc,
    outptr: *?[*:0]u8,
    outlen: *usize,
) callconv(.c) CURLcode {
    if (digest.algo <= ALGO_MD5SESS) {
        return authCreateDigestHttpMessage(
            data,
            creds,
            uripath,
            request,
            body,
            blen,
            digest,
            outptr,
            outlen,
            authDigestMd5ToAscii,
            crypto.Curl_md5it,
        );
    }
    if (digest.algo <= ALGO_SHA256SESS) {
        return authCreateDigestHttpMessage(
            data,
            creds,
            uripath,
            request,
            body,
            blen,
            digest,
            outptr,
            outlen,
            authDigestSha256ToAscii,
            crypto.Curl_sha256it,
        );
    }
    return authCreateDigestHttpMessage(
        data,
        creds,
        uripath,
        request,
        body,
        blen,
        digest,
        outptr,
        outlen,
        authDigestSha256ToAscii,
        crypto.Curl_sha512_256it,
    );
}

pub fn digestCleanupRfc(digest: *DigestDataRfc) callconv(.c) void {
    safeFreeStr(&digest.nonce);
    safeFreeStr(&digest.cnonce);
    safeFreeStr(&digest.realm);
    safeFreeStr(&digest.@"opaque");
    safeFreeStr(&digest.qop);
    safeFreeStr(&digest.algorithm);

    Curl_peer_unlink(&digest.origin);
    Curl_creds_unlink(&digest.creds);
    digest.nc = 0;
    digest.algo = ALGO_MD5;
    digest.flags = 0;
}

fn FormatSpn(service: [*:0]const u8, host: [*:0]const u8, realm: ?[*:0]const u8) ?[*:0]u8 {
    if (builtin.os.tag == .windows) {
        return Curl_auth_build_spn(service, host, realm);
    }
    if (realm) |r| {
        return curl_maprintf("%s/%s@%s", service, host, r);
    }
    return curl_maprintf("%s/%s", service, host);
}

// ============================================================================
// 2. lib/vauth/digest_sspi.c & 5. lib/socks_sspi.c — Windows SSPI Auth
// ============================================================================

const SECURITY_STATUS = c_long;
const SEC_E_OK: SECURITY_STATUS = 0;
const SEC_E_INSUFFICIENT_MEMORY: SECURITY_STATUS = @bitCast(@as(c_ulong, 0x80090300));
const SEC_I_CONTINUE_NEEDED: SECURITY_STATUS = 0x00090312;
const SEC_I_COMPLETE_NEEDED: SECURITY_STATUS = 0x00090313;
const SEC_I_COMPLETE_AND_CONTINUE: SECURITY_STATUS = 0x00090314;

const SECPKG_CRED_OUTBOUND: c_ulong = 0x00000002;
const SECURITY_NATIVE_DREP: c_ulong = 0x00000010;
const SECPKG_ATTR_SIZES: c_ulong = 0;
const SECPKG_ATTR_NAMES: c_ulong = 1;

const ISC_REQ_REPLAY_DETECT: c_ulong = 0x00000004;
const ISC_REQ_SEQUENCE_DETECT: c_ulong = 0x00000008;
const ISC_REQ_CONFIDENTIALITY: c_ulong = 0x00000010;
const ISC_REQ_USE_SUPPLIED_CREDS: c_ulong = 0x00000080;
const ISC_REQ_ALLOCATE_MEMORY: c_ulong = 0x00000100;
const ISC_REQ_MUTUAL_AUTH: c_ulong = 0x00000002;
const ISC_REQ_INTEGRITY: c_ulong = 0x00010000;
const ISC_REQ_USE_HTTP_STYLE: c_ulong = 0x01000000;

const SECBUFFER_VERSION: c_ulong = 0;
const SECBUFFER_EMPTY: c_ulong = 0;
const SECBUFFER_DATA: c_ulong = 1;
const SECBUFFER_TOKEN: c_ulong = 2;
const SECBUFFER_PKG_PARAMS: c_ulong = 3;
const SECBUFFER_PADDING: c_ulong = 9;
const SECBUFFER_STREAM: c_ulong = 10;

pub const SecHandle = extern struct {
    dwLower: usize = 0,
    dwUpper: usize = 0,
};
pub const CredHandle = SecHandle;
pub const CtxtHandle = SecHandle;
pub const TimeStamp = i64;

pub const SecBuffer = extern struct {
    cbBuffer: c_ulong = 0,
    BufferType: c_ulong = 0,
    pvBuffer: ?*anyopaque = null,
};

pub const SecBufferDesc = extern struct {
    ulVersion: c_ulong = 0,
    cBuffers: c_ulong = 0,
    pBuffers: [*]SecBuffer = undefined,
};

pub const SecPkgContext_Sizes = extern struct {
    cbMaxToken: c_ulong = 0,
    cbMaxSignature: c_ulong = 0,
    cbBlockSize: c_ulong = 0,
    cbSecurityTrailer: c_ulong = 0,
};

pub const SecPkgContext_NamesA = extern struct {
    sUserName: ?[*:0]u8 = null,
};

pub const SEC_WINNT_AUTH_IDENTITY = extern struct {
    User: ?[*]u8 = null,
    UserLength: c_ulong = 0,
    Domain: ?[*]u8 = null,
    DomainLength: c_ulong = 0,
    Password: ?[*]u8 = null,
    PasswordLength: c_ulong = 0,
    Flags: c_ulong = 0,
};

pub const DigestDataSspi = extern struct {
    creds: ?*Curl_creds = null,
    origin: ?*anyopaque = null,
    input_token: ?[*]u8 = null,
    input_token_len: usize = 0,
    http_context: ?*CtxtHandle = null,
};

const AcquireCredentialsHandleFnA = *const fn (
    ?[*:0]u8,
    [*:0]const u8,
    c_ulong,
    ?*anyopaque,
    ?*anyopaque,
    ?*anyopaque,
    ?*anyopaque,
    *CredHandle,
    *TimeStamp,
) callconv(.winapi) SECURITY_STATUS;

const FreeCredentialsHandleFn = *const fn (*CredHandle) callconv(.winapi) SECURITY_STATUS;

const InitializeSecurityContextFnA = *const fn (
    *CredHandle,
    ?*CtxtHandle,
    ?[*:0]u8,
    c_ulong,
    c_ulong,
    c_ulong,
    ?*SecBufferDesc,
    c_ulong,
    ?*CtxtHandle,
    ?*SecBufferDesc,
    *c_ulong,
    *TimeStamp,
) callconv(.winapi) SECURITY_STATUS;

const CompleteAuthTokenFn = *const fn (*CtxtHandle, *SecBufferDesc) callconv(.winapi) SECURITY_STATUS;
const DeleteSecurityContextFn = *const fn (*CtxtHandle) callconv(.winapi) SECURITY_STATUS;
const QueryContextAttributesFnA = *const fn (*CtxtHandle, c_ulong, *anyopaque) callconv(.winapi) SECURITY_STATUS;
const FreeContextBufferFn = *const fn (?*anyopaque) callconv(.winapi) SECURITY_STATUS;
const EncryptMessageFn = *const fn (*CtxtHandle, c_ulong, *SecBufferDesc, c_ulong) callconv(.winapi) SECURITY_STATUS;
const DecryptMessageFn = *const fn (*CtxtHandle, *SecBufferDesc, c_ulong, *c_ulong) callconv(.winapi) SECURITY_STATUS;

pub const SecurityFunctionTableA = extern struct {
    dwVersion: c_ulong,
    EnumerateSecurityPackagesA: ?*const anyopaque,
    QueryCredentialsAttributesA: ?*const anyopaque,
    AcquireCredentialsHandleA: AcquireCredentialsHandleFnA,
    FreeCredentialsHandle: FreeCredentialsHandleFn,
    Reserved2: ?*anyopaque,
    InitializeSecurityContextA: InitializeSecurityContextFnA,
    AcceptSecurityContext: ?*const anyopaque,
    CompleteAuthToken: CompleteAuthTokenFn,
    DeleteSecurityContext: DeleteSecurityContextFn,
    ApplyControlToken: ?*const anyopaque,
    QueryContextAttributesA: QueryContextAttributesFnA,
    ImpersonateSecurityContext: ?*const anyopaque,
    RevertSecurityContext: ?*const anyopaque,
    MakeSignature: ?*const anyopaque,
    VerifySignature: ?*const anyopaque,
    FreeContextBuffer: FreeContextBufferFn,
    QuerySecurityPackageInfoA: ?*const anyopaque,
    Reserved3: ?*anyopaque,
    Reserved4: ?*anyopaque,
    ExportSecurityContext: ?*const anyopaque,
    ImportSecurityContextA: ?*const anyopaque,
    AddCredentialsA: ?*const anyopaque,
    Reserved8: ?*anyopaque,
    QuerySecurityContextToken: ?*const anyopaque,
    EncryptMessage: EncryptMessageFn,
    DecryptMessage: DecryptMessageFn,
    SetContextAttributesA: ?*const anyopaque,
    SetCredentialsAttributesA: ?*const anyopaque,
    ChangeAccountPasswordA: ?*const anyopaque,
    QueryContextAttributesExA: ?*const anyopaque,
    QueryCredentialsAttributesExA: ?*const anyopaque,
};

extern var Curl_pSecFn: ?*SecurityFunctionTableA;
extern fn Curl_create_sspi_identity(userp: [*:0]const u8, passwdp: [*:0]const u8, identity: *SEC_WINNT_AUTH_IDENTITY) callconv(.c) CURLcode;
extern fn Curl_sspi_free_identity(identity: ?*SEC_WINNT_AUTH_IDENTITY) callconv(.c) void;
extern fn Curl_auth_build_spn(service: [*:0]const u8, host: [*:0]const u8, realm: ?[*:0]const u8) callconv(.c) ?[*:0]u8;
extern fn Curl_sspi_strerror(err: c_int, buf: [*]u8, buflen: usize) callconv(.c) [*:0]const u8;

fn isDigestSupportedSspi() callconv(.c) bool {
    return true;
}

fn createDigestMd5MessageHostSspi(
    data: ?*anyopaque,
    hostname: [*:0]const u8,
    chlg: *const bufref,
    creds: *Curl_creds,
    service: [*:0]const u8,
    out: *bufref,
) callconv(.c) CURLcode {
    var result: CURLcode = CURLE_OK;
    var response: ?[*]u8 = null;
    var rlen: usize = 0;
    var handle: CredHandle = .{};
    var context: CtxtHandle = .{};
    var chlg_desc: SecBufferDesc = .{};
    var resp_desc: SecBufferDesc = .{};
    var chlg_buf: SecBuffer = .{};
    var resp_buf: SecBuffer = .{};
    var attrs: c_ulong = 0;
    var expiry: TimeStamp = 0;
    var identity: SEC_WINNT_AUTH_IDENTITY = .{};
    var p_identity: ?*SEC_WINNT_AUTH_IDENTITY = null;

    if (Curl_bufref_len(chlg) == 0) {
        Curl_failf(data, "DIGEST-MD5 handshake failure (empty challenge message)");
        return CURLE_BAD_CONTENT_ENCODING;
    }

    const spn = Curl_auth_build_spn(service, hostname, null) orelse return CURLE_OUT_OF_MEMORY;

    const userp: [*:0]const u8 = creds.user orelse "";
    const passwdp: [*:0]const u8 = creds.passwd orelse "";
    if (userp[0] != 0) {
        result = Curl_create_sspi_identity(userp, passwdp, &identity);
        if (result != CURLE_OK) {
            mem.free(@ptrCast(spn));
            return result;
        }
        p_identity = &identity;
    } else {
        p_identity = null;
    }

    const sec_fn = Curl_pSecFn orelse {
        Curl_sspi_free_identity(p_identity);
        mem.free(@ptrCast(spn));
        return CURLE_AUTH_ERROR;
    };

    var status = sec_fn.AcquireCredentialsHandleA(
        null,
        "WDigest",
        SECPKG_CRED_OUTBOUND,
        null,
        @ptrCast(p_identity),
        null,
        null,
        &handle,
        &expiry,
    );
    if (status != SEC_E_OK) {
        Curl_sspi_free_identity(p_identity);
        mem.free(@ptrCast(spn));
        return CURLE_LOGIN_DENIED;
    }

    chlg_desc.ulVersion = SECBUFFER_VERSION;
    chlg_desc.cBuffers = 1;
    chlg_desc.pBuffers = @ptrCast(&chlg_buf);
    chlg_buf.BufferType = SECBUFFER_TOKEN;
    chlg_buf.pvBuffer = @ptrCast(@constCast(Curl_bufref_ptr(chlg)));
    chlg_buf.cbBuffer = curlx_uztoul(Curl_bufref_len(chlg));

    resp_desc.ulVersion = SECBUFFER_VERSION;
    resp_desc.cBuffers = 1;
    resp_desc.pBuffers = @ptrCast(&resp_buf);
    resp_buf.BufferType = SECBUFFER_TOKEN;
    resp_buf.pvBuffer = null;
    resp_buf.cbBuffer = 0;

    status = sec_fn.InitializeSecurityContextA(
        &handle,
        null,
        spn,
        ISC_REQ_ALLOCATE_MEMORY,
        0,
        SECURITY_NATIVE_DREP,
        &chlg_desc,
        0,
        &context,
        &resp_desc,
        &attrs,
        &expiry,
    );

    if (status == SEC_I_COMPLETE_NEEDED or status == SEC_I_COMPLETE_AND_CONTINUE) {
        status = sec_fn.CompleteAuthToken(&context, &resp_desc);
    }

    mem.free(@ptrCast(spn));

    if (status != SEC_E_OK and status != SEC_I_CONTINUE_NEEDED) {
        _ = sec_fn.FreeCredentialsHandle(&handle);
        Curl_sspi_free_identity(p_identity);
        if (status == SEC_E_INSUFFICIENT_MEMORY) {
            return CURLE_OUT_OF_MEMORY;
        }
        return CURLE_AUTH_ERROR;
    }

    _ = sec_fn.DeleteSecurityContext(&context);
    _ = sec_fn.FreeCredentialsHandle(&handle);
    Curl_sspi_free_identity(p_identity);

    if (resp_buf.pvBuffer) |pv| {
        const pv_bytes: [*]const u8 = @ptrCast(pv);
        result = curlx_base64_encode(pv_bytes, resp_buf.cbBuffer, &response, &rlen);
        if (result == CURLE_OK) {
            Curl_bufref_set(out, response, rlen, curl_free);
        }
        _ = sec_fn.FreeContextBuffer(pv);
    }

    return result;
}

fn overrideSspiHttpRealm(chlg_in: [*:0]const u8, identity: *SEC_WINNT_AUTH_IDENTITY) callconv(.c) CURLcode {
    var chlg = chlg_in;
    var value = Curl_str{ .str = null, .len = 0 };
    var content: [DIGEST_MAX_CONTENT_LENGTH]u8 = undefined;

    if (identity.Domain == null or identity.DomainLength == 0) {
        while (chlg[0] != 0) {
            if (Curl_auth_digest_get_pair(chlg, &value, &content, &chlg)) {
                if (curlx_str_casecompare(&value, "realm") != 0) {
                    if (identity.Domain) |dom| {
                        mem.free(@ptrCast(dom));
                    }
                    const content_cstr: [*:0]const u8 = @ptrCast(&content);
                    const tchar_ptr = mem.strdup(content_cstr) orelse return CURLE_OUT_OF_MEMORY;
                    identity.Domain = tchar_ptr;
                    identity.DomainLength = curlx_uztoul(std.mem.len(@as([*:0]const u8, @ptrCast(tchar_ptr))));
                    identity.Flags = 0x1; // SEC_WINNT_AUTH_IDENTITY_ANSI
                }
            } else {
                break;
            }

            while (chlg[0] != 0 and isBlank(chlg[0])) {
                chlg += 1;
            }
            if (chlg[0] == ',') {
                chlg += 1;
            }
            while (chlg[0] != 0 and isBlank(chlg[0])) {
                chlg += 1;
            }
        }
    }

    return CURLE_OK;
}

fn decodeDigestHttpMessageSspi(chlg: [*:0]const u8, digest: *DigestDataSspi) callconv(.c) CURLcode {
    const chlg_len = std.mem.len(chlg);

    if (digest.input_token != null) {
        var stale = false;
        var value = Curl_str{ .str = null, .len = 0 };
        var content: [DIGEST_MAX_CONTENT_LENGTH]u8 = undefined;
        var p = chlg;

        while (p[0] != 0) {
            if (!Curl_auth_digest_get_pair(p, &value, &content, &p)) {
                break;
            }
            const content_cstr: [*:0]const u8 = @ptrCast(&content);
            if (curlx_str_casecompare(&value, "stale") != 0 and
                curl_strequal(content_cstr, "true") != 0)
            {
                stale = true;
                break;
            }

            while (p[0] != 0 and isBlank(p[0])) {
                p += 1;
            }
            if (p[0] == ',') {
                p += 1;
            }
            while (p[0] != 0 and isBlank(p[0])) {
                p += 1;
            }
        }

        if (stale) {
            digestCleanupSspi(digest);
        } else {
            return CURLE_LOGIN_DENIED;
        }
    }

    const tok = mem.malloc(chlg_len + 1) orelse return CURLE_OUT_OF_MEMORY;
    const tok_bytes: [*]u8 = @ptrCast(tok);
    @memcpy(tok_bytes[0 .. chlg_len + 1], chlg[0 .. chlg_len + 1]);
    digest.input_token = tok_bytes;
    digest.input_token_len = chlg_len;

    return CURLE_OK;
}

fn createDigestHttpMessageSspi(
    data: ?*anyopaque,
    creds: *Curl_creds,
    uripath: [*:0]const u8,
    request: [*:0]const u8,
    body: ?[*]const u8,
    blen: usize,
    digest: *DigestDataSspi,
    outptr: *?[*:0]u8,
    outlen: *usize,
) callconv(.c) CURLcode {
    _ = data;
    var token_max: usize = 0;
    var cred_handle: CredHandle = .{};
    var expiry: TimeStamp = 0;
    var sizes: SecPkgContext_Sizes = .{};
    var chlg_desc: SecBufferDesc = .{};
    var resp_desc: SecBufferDesc = .{};
    var chlg_buf: [5]SecBuffer = .{ .{}, .{}, .{}, .{}, .{} };
    var resp_buf: SecBuffer = .{};
    var attrs: c_ulong = 0;
    var identity: SEC_WINNT_AUTH_IDENTITY = .{};
    var p_identity: ?*SEC_WINNT_AUTH_IDENTITY = null;
    var has_input_token = false;

    outlen.* = 0;
    outptr.* = null;

    const userp_orig: [*:0]const u8 = creds.user orelse "";
    const passwdp: [*:0]const u8 = creds.passwd orelse "";
    var userp = userp_orig;

    if (userp[0] == 0) {
        userp = "\\";
    }

    var result = Curl_create_sspi_identity(userp, passwdp, &identity);
    if (result != CURLE_OK) {
        return result;
    }

    if (digest.input_token) |in_tok| {
        if (overrideSspiHttpRealm(@ptrCast(in_tok), &identity) != CURLE_OK) {
            Curl_sspi_free_identity(&identity);
            return CURLE_OUT_OF_MEMORY;
        }
    }

    p_identity = &identity;

    const target_uri = mem.strdup(uripath) orelse {
        Curl_sspi_free_identity(p_identity);
        return CURLE_OUT_OF_MEMORY;
    };
    const target_method = mem.strdup(request) orelse {
        mem.free(@ptrCast(target_uri));
        Curl_sspi_free_identity(p_identity);
        return CURLE_OUT_OF_MEMORY;
    };

    const sec_fn = Curl_pSecFn orelse {
        mem.free(@ptrCast(target_method));
        mem.free(@ptrCast(target_uri));
        Curl_sspi_free_identity(p_identity);
        return CURLE_AUTH_ERROR;
    };

    var status = sec_fn.AcquireCredentialsHandleA(
        null,
        "WDigest",
        SECPKG_CRED_OUTBOUND,
        null,
        @ptrCast(p_identity),
        null,
        null,
        &cred_handle,
        &expiry,
    );
    if (status != SEC_E_OK) {
        mem.free(@ptrCast(target_method));
        mem.free(@ptrCast(target_uri));
        Curl_sspi_free_identity(p_identity);
        return CURLE_LOGIN_DENIED;
    }

    chlg_desc.ulVersion = SECBUFFER_VERSION;
    chlg_desc.cBuffers = 5;
    chlg_desc.pBuffers = &chlg_buf;
    chlg_buf[0].BufferType = SECBUFFER_TOKEN;
    if (digest.input_token) |in_tok| {
        chlg_buf[0].pvBuffer = @ptrCast(in_tok);
        chlg_buf[0].cbBuffer = curlx_uztoul(digest.input_token_len);
        has_input_token = true;
    } else {
        chlg_buf[0].pvBuffer = null;
        chlg_buf[0].cbBuffer = 0;
    }
    chlg_buf[1].BufferType = SECBUFFER_PKG_PARAMS;
    chlg_buf[1].pvBuffer = @ptrCast(target_method);
    chlg_buf[1].cbBuffer = curlx_uztoul(std.mem.len(@as([*:0]const u8, @ptrCast(target_method))));
    chlg_buf[2].BufferType = SECBUFFER_PKG_PARAMS;
    chlg_buf[2].pvBuffer = null;
    chlg_buf[2].cbBuffer = 0;
    chlg_buf[3].BufferType = SECBUFFER_PKG_PARAMS;
    chlg_buf[3].pvBuffer = null;
    chlg_buf[3].cbBuffer = 0;
    chlg_buf[4].BufferType = SECBUFFER_PADDING;
    if (body != null and blen > 0) {
        var hashed: [33]u8 = undefined;
        var hashbuf: [16]u8 = undefined;
        result = crypto.Curl_md5it(&hashbuf, body.?, blen);
        if (result == CURLE_OK) {
            authDigestMd5ToAscii(&hashbuf, &hashed);
            const hashed_cstr: [*:0]const u8 = @ptrCast(&hashed);
            chlg_buf[4].pvBuffer = @ptrCast(mem.strdup(hashed_cstr));
            chlg_buf[4].cbBuffer = 32;
        }
    } else {
        chlg_buf[4].pvBuffer = null;
        chlg_buf[4].cbBuffer = 0;
    }

    resp_desc.ulVersion = SECBUFFER_VERSION;
    resp_desc.cBuffers = 1;
    resp_desc.pBuffers = @ptrCast(&resp_buf);
    resp_buf.BufferType = SECBUFFER_TOKEN;

    if (digest.http_context != null) {
        status = sec_fn.QueryContextAttributesA(digest.http_context.?, SECPKG_ATTR_SIZES, @ptrCast(&sizes));
        if (status != SEC_E_OK) {
            mem.free(@ptrCast(target_method));
            mem.free(@ptrCast(target_uri));
            mem.free(chlg_buf[4].pvBuffer);
            _ = sec_fn.FreeCredentialsHandle(&cred_handle);
            Curl_sspi_free_identity(p_identity);
            return CURLE_OUT_OF_MEMORY;
        }
        token_max = sizes.cbMaxToken;
    } else {
        token_max = 4096;
    }

    resp_buf.pvBuffer = mem.malloc(token_max);
    if (resp_buf.pvBuffer == null) {
        mem.free(@ptrCast(target_method));
        mem.free(@ptrCast(target_uri));
        mem.free(chlg_buf[4].pvBuffer);
        _ = sec_fn.FreeCredentialsHandle(&cred_handle);
        Curl_sspi_free_identity(p_identity);
        return CURLE_OUT_OF_MEMORY;
    }
    resp_buf.cbBuffer = curlx_uztoul(token_max);

    var output_context: CtxtHandle = .{};
    status = sec_fn.InitializeSecurityContextA(
        &cred_handle,
        digest.http_context,
        @ptrCast(target_uri),
        ISC_REQ_USE_HTTP_STYLE | ISC_REQ_USE_SUPPLIED_CREDS,
        0,
        SECURITY_NATIVE_DREP,
        &chlg_desc,
        0,
        &output_context,
        &resp_desc,
        &attrs,
        &expiry,
    );
    mem.free(@ptrCast(target_method));
    mem.free(@ptrCast(target_uri));
    mem.free(chlg_buf[4].pvBuffer);

    if (status == SEC_I_COMPLETE_NEEDED or status == SEC_I_COMPLETE_AND_CONTINUE) {
        status = sec_fn.CompleteAuthToken(&cred_handle, &resp_desc);
    }

    if (status != SEC_E_OK and status != SEC_I_CONTINUE_NEEDED) {
        _ = sec_fn.FreeCredentialsHandle(&cred_handle);
        mem.free(resp_buf.pvBuffer);
        Curl_sspi_free_identity(p_identity);
        digestCleanupSspi(digest);
        if (status == SEC_E_INSUFFICIENT_MEMORY) {
            return CURLE_OUT_OF_MEMORY;
        }
        return CURLE_AUTH_ERROR;
    }

    const out_len: usize = resp_buf.cbBuffer;
    const out_alloc = mem.malloc(out_len + 1) orelse {
        _ = sec_fn.FreeCredentialsHandle(&cred_handle);
        mem.free(resp_buf.pvBuffer);
        Curl_sspi_free_identity(p_identity);
        return CURLE_OUT_OF_MEMORY;
    };
    const out_bytes: [*]u8 = @ptrCast(out_alloc);
    if (resp_buf.pvBuffer) |pv| {
        const pv_bytes: [*]const u8 = @ptrCast(pv);
        @memcpy(out_bytes[0..out_len], pv_bytes[0..out_len]);
    }
    out_bytes[out_len] = 0;
    outptr.* = @ptrCast(out_bytes);
    outlen.* = out_len;

    mem.free(resp_buf.pvBuffer);

    if (digest.http_context == null) {
        const ctx_mem = mem.calloc(1, @sizeOf(CtxtHandle)) orelse {
            _ = sec_fn.DeleteSecurityContext(&output_context);
            _ = sec_fn.FreeCredentialsHandle(&cred_handle);
            Curl_sspi_free_identity(p_identity);
            return CURLE_OUT_OF_MEMORY;
        };
        digest.http_context = @ptrCast(@alignCast(ctx_mem));
    }
    digest.http_context.?.* = output_context;

    _ = sec_fn.FreeCredentialsHandle(&cred_handle);
    Curl_sspi_free_identity(p_identity);

    if (has_input_token) {
        safeFreeBytes(&digest.input_token);
        digest.input_token_len = 0;
    }

    return CURLE_OK;
}

fn digestCleanupSspi(digest: *DigestDataSspi) callconv(.c) void {
    safeFreeBytes(&digest.input_token);
    digest.input_token_len = 0;

    if (digest.http_context) |ctx| {
        if (Curl_pSecFn) |sec_fn| {
            _ = sec_fn.DeleteSecurityContext(ctx);
        }
        mem.free(@ptrCast(ctx));
        digest.http_context = null;
    }

    Curl_creds_unlink(&digest.creds);
    Curl_peer_unlink(&digest.origin);
}

// ============================================================================
// 5. lib/socks_sspi.c — Windows SOCKS5 SSPI Authentication
// ============================================================================

const curl_socket_t = if (builtin.os.tag == .windows) usize else c_int;
const CURL_SOCKET_BAD: curl_socket_t = if (builtin.os.tag == .windows) ~@as(usize, 0) else -1;
const timediff_t = i64;

extern fn Curl_socket_check(
    readfd0: curl_socket_t,
    readfd1: curl_socket_t,
    writefd: curl_socket_t,
    timeout_ms: timediff_t,
) callconv(.c) c_int;

extern fn Curl_conn_cf_send(
    cf: ?*anyopaque,
    data: ?*anyopaque,
    buf: [*]const u8,
    len: usize,
    eos: bool,
    pnwritten: *usize,
) callconv(.c) CURLcode;

extern fn Curl_conn_cf_recv(
    cf: ?*anyopaque,
    data: ?*anyopaque,
    buf: [*]u8,
    len: usize,
    pnread: *usize,
) callconv(.c) CURLcode;

extern fn Curl_blockread_all(
    cf: ?*anyopaque,
    data: ?*anyopaque,
    buf: [*]u8,
    blen: usize,
    pnread: *usize,
) callconv(.c) CURLcode;

extern fn curlx_nonblock(sockfd: curl_socket_t, nonblock: c_int) callconv(.c) c_int;
extern fn Curl_setopt_get_i64(data: ?*anyopaque, field_id: c_int) callconv(.c) i64;

const KERB_WRAP_NO_ENCRYPT: c_ulong = 0x80000001;
const FIELD_GSSAPI_DELEGATION: c_int = 64;
const CURLGSSAPI_DELEGATION_POLICY_FLAG: i64 = 1 << 0;
const CURLGSSAPI_DELEGATION_FLAG: i64 = 1 << 1;

fn checkSspiErr(data: ?*anyopaque, status: SECURITY_STATUS, function: [*:0]const u8) bool {
    if (status != SEC_E_OK and
        status != SEC_I_COMPLETE_AND_CONTINUE and
        status != SEC_I_COMPLETE_NEEDED and
        status != SEC_I_CONTINUE_NEEDED)
    {
        var err_buf: [256]u8 = undefined;
        Curl_infof(
            data,
            "SSPI error: %s failed: %s",
            function,
            Curl_sspi_strerror(@intCast(status), &err_buf, err_buf.len),
        );
        return true;
    }
    return false;
}

fn socks5SspiSend(
    cf_next: ?*anyopaque,
    data: ?*anyopaque,
    sock: curl_socket_t,
    buf: [*]const u8,
    len: usize,
) CURLcode {
    var remaining = len;
    var ptr = buf;
    while (remaining != 0) {
        var nwritten: usize = 0;
        const result = Curl_conn_cf_send(cf_next, data, ptr, remaining, false, &nwritten);
        if (result == CURLE_AGAIN) {
            if (Curl_socket_check(CURL_SOCKET_BAD, CURL_SOCKET_BAD, sock, 1000) <= 0) {
                return CURLE_COULDNT_CONNECT;
            }
            continue;
        }
        if (result != CURLE_OK) {
            return result;
        }
        if (remaining < nwritten) {
            return CURLE_SEND_ERROR;
        }
        remaining -= nwritten;
        ptr += nwritten;
    }
    return CURLE_OK;
}

fn socks5SspiRecv(
    cf_next: ?*anyopaque,
    data: ?*anyopaque,
    sock: curl_socket_t,
    buf: [*]u8,
    len: usize,
) CURLcode {
    var remaining = len;
    var ptr = buf;
    while (remaining != 0) {
        var nread: usize = 0;
        const result = Curl_conn_cf_recv(cf_next, data, ptr, remaining, &nread);
        if (result == CURLE_AGAIN) {
            if (Curl_socket_check(sock, CURL_SOCKET_BAD, CURL_SOCKET_BAD, 1000) <= 0) {
                return CURLE_COULDNT_CONNECT;
            }
            continue;
        }
        if (result != CURLE_OK) {
            return result;
        }
        if (nread == 0 or remaining < nread) {
            return CURLE_RECV_ERROR;
        }
        remaining -= nread;
        ptr += nread;
    }
    return CURLE_OK;
}

fn socks5EncodeTokenHeader(hdr: *[4]u8, msg_type: u8, token_len: usize) ?u16 {
    const len_u16 = std.math.cast(u16, token_len) orelse return null;
    hdr[0] = 1;
    hdr[1] = msg_type;
    std.mem.writeInt(u16, hdr[2..4], len_u16, .big);
    return len_u16;
}

fn socks5DecodeTokenLength(hdr: []const u8) ?u16 {
    if (hdr.len < 4) return null;
    const len_u16 = std.mem.readInt(u16, hdr[2..4], .big);
    if (len_u16 == 0) return null;
    return len_u16;
}

fn scrubAndFreeSecBuffer(buf: *SecBuffer) void {
    if (buf.pvBuffer) |ptr| {
        if (buf.cbBuffer > 0) {
            mem.secureZero(ptr, @intCast(buf.cbBuffer));
        }
        mem.free(ptr);
        buf.pvBuffer = null;
        buf.cbBuffer = 0;
    }
}

fn socks5GssapiNegotiateSspi(
    cf: ?*anyopaque,
    cf_next: ?*anyopaque,
    data: ?*anyopaque,
    creds: ?*Curl_creds,
    sock: curl_socket_t,
    service_name_opt: ?[*:0]const u8,
    proxy_hostname_opt: ?[*:0]const u8,
    socks5_gssapi_nec: bool,
    socks5_gssapi_enctype: *c_int,
) callconv(.c) CURLcode {
    _ = cf;
    var code: CURLcode = CURLE_OK;
    var status: SECURITY_STATUS = SEC_E_OK;
    var sspi_ret_flags: c_ulong = 0;
    var sspi_recv_token: [4]u8 = undefined;
    var us_length: u16 = 0;
    var qop: c_ulong = 0;
    var outbuf_desc: SecBufferDesc = .{};
    var out_sec_buf: SecBuffer = .{};
    var inbuf_desc: SecBufferDesc = .{};
    var in_sec_buf: SecBuffer = .{};
    var wrap_desc: SecBufferDesc = .{};
    var wrap_sec_buf: [3]SecBuffer = .{ .{}, .{}, .{} };
    var cred_handle: CredHandle = .{};
    var sspi_context: CtxtHandle = .{};
    var p_context: ?*CtxtHandle = null;
    var names: SecPkgContext_NamesA = .{};
    var sizes: SecPkgContext_Sizes = .{};
    var expiry: TimeStamp = 0;
    const service: [*:0]const u8 = if (service_name_opt) |s|
        (if (s[0] != 0) s else "rcmd")
    else if (creds) |cr|
        (if (cr.sasl_service) |ss| (if (ss[0] != 0) ss else "rcmd") else "rcmd")
    else
        "rcmd";

    const sec_fn = Curl_pSecFn orelse return CURLE_COULDNT_CONNECT;

    const proxy_hostname: [*:0]const u8 = proxy_hostname_opt orelse "";
    const service_Principal: [*:0]u8 = if (std.mem.indexOfScalar(u8, std.mem.span(service), '/') != null)
        (curl_maprintf("%s", service) orelse return CURLE_OUT_OF_MEMORY)
    else
        (Curl_auth_build_spn(service, proxy_hostname, null) orelse return CURLE_OUT_OF_MEMORY);

    @memset(std.mem.asBytes(&cred_handle), 0);
    @memset(std.mem.asBytes(&sspi_context), 0);

    status = sec_fn.AcquireCredentialsHandleA(
        null,
        "Kerberos",
        SECPKG_CRED_OUTBOUND,
        null,
        null,
        null,
        null,
        &cred_handle,
        &expiry,
    );
    if (checkSspiErr(data, status, "AcquireCredentialsHandle")) {
        Curl_failf(data, "Failed to acquire credentials.");
        mem.free(@ptrCast(service_Principal));
        _ = sec_fn.FreeCredentialsHandle(&cred_handle);
        return CURLE_COULDNT_CONNECT;
    }

    _ = curlx_nonblock(sock, 0);
    defer _ = curlx_nonblock(sock, 1);

    while (true) {
        outbuf_desc.ulVersion = SECBUFFER_VERSION;
        outbuf_desc.cBuffers = 1;
        outbuf_desc.pBuffers = @ptrCast(&out_sec_buf);
        out_sec_buf.BufferType = SECBUFFER_TOKEN;
        out_sec_buf.pvBuffer = null;
        out_sec_buf.cbBuffer = 0;

        const req_flags: c_ulong = ISC_REQ_MUTUAL_AUTH |
            ISC_REQ_REPLAY_DETECT |
            ISC_REQ_CONFIDENTIALITY |
            ISC_REQ_SEQUENCE_DETECT |
            ISC_REQ_ALLOCATE_MEMORY |
            ISC_REQ_INTEGRITY;

        status = sec_fn.InitializeSecurityContextA(
            &cred_handle,
            p_context,
            service_Principal,
            req_flags,
            0,
            SECURITY_NATIVE_DREP,
            if (p_context != null) &inbuf_desc else null,
            0,
            &sspi_context,
            &outbuf_desc,
            &sspi_ret_flags,
            &expiry,
        );

        if (in_sec_buf.pvBuffer != null) {
            scrubAndFreeSecBuffer(&in_sec_buf);
        }

        if (checkSspiErr(data, status, "InitializeSecurityContext")) {
            Curl_failf(data, "Failed to initialise security context.");
            mem.free(@ptrCast(service_Principal));
            _ = sec_fn.DeleteSecurityContext(&sspi_context);
            _ = sec_fn.FreeCredentialsHandle(&cred_handle);
            if (out_sec_buf.pvBuffer) |p| {
                if (out_sec_buf.cbBuffer > 0) mem.secureZero(p, @intCast(out_sec_buf.cbBuffer));
                _ = sec_fn.FreeContextBuffer(p);
            }
            return CURLE_COULDNT_CONNECT;
        }

        if (out_sec_buf.cbBuffer != 0) {
            us_length = socks5EncodeTokenHeader(&sspi_recv_token, 1, @intCast(out_sec_buf.cbBuffer)) orelse {
                Curl_failf(data, "Failed to send SSPI authentication token.");
                mem.free(@ptrCast(service_Principal));
                if (out_sec_buf.pvBuffer) |p| {
                    if (out_sec_buf.cbBuffer > 0) mem.secureZero(p, @intCast(out_sec_buf.cbBuffer));
                    _ = sec_fn.FreeContextBuffer(p);
                }
                _ = sec_fn.DeleteSecurityContext(&sspi_context);
                _ = sec_fn.FreeCredentialsHandle(&cred_handle);
                return CURLE_COULDNT_CONNECT;
            };

            code = socks5SspiSend(cf_next, data, sock, &sspi_recv_token, 4);
            if (code == CURLE_OK and out_sec_buf.pvBuffer != null) {
                code = socks5SspiSend(
                    cf_next,
                    data,
                    sock,
                    @ptrCast(out_sec_buf.pvBuffer),
                    out_sec_buf.cbBuffer,
                );
            }
            if (code != CURLE_OK) {
                Curl_failf(data, "Failed to send SSPI authentication token.");
                mem.free(@ptrCast(service_Principal));
                if (out_sec_buf.pvBuffer) |p| {
                    if (out_sec_buf.cbBuffer > 0) mem.secureZero(p, @intCast(out_sec_buf.cbBuffer));
                    _ = sec_fn.FreeContextBuffer(p);
                }
                _ = sec_fn.DeleteSecurityContext(&sspi_context);
                _ = sec_fn.FreeCredentialsHandle(&cred_handle);
                return CURLE_COULDNT_CONNECT;
            }
        }

        if (out_sec_buf.pvBuffer) |p| {
            if (out_sec_buf.cbBuffer > 0) mem.secureZero(p, @intCast(out_sec_buf.cbBuffer));
            _ = sec_fn.FreeContextBuffer(p);
        }
        out_sec_buf.pvBuffer = null;
        out_sec_buf.cbBuffer = 0;

        if (status != SEC_I_CONTINUE_NEEDED) {
            break;
        }

        code = socks5SspiRecv(cf_next, data, sock, &sspi_recv_token, 4);
        if (code != CURLE_OK) {
            Curl_failf(data, "Failed to receive SSPI authentication response.");
            mem.free(@ptrCast(service_Principal));
            _ = sec_fn.DeleteSecurityContext(&sspi_context);
            _ = sec_fn.FreeCredentialsHandle(&cred_handle);
            return CURLE_COULDNT_CONNECT;
        }

        if (sspi_recv_token[0] != 1) {
            Curl_failf(data, "Received invalid version in initial SOCKS5 response.");
            mem.free(@ptrCast(service_Principal));
            _ = sec_fn.DeleteSecurityContext(&sspi_context);
            _ = sec_fn.FreeCredentialsHandle(&cred_handle);
            return CURLE_COULDNT_CONNECT;
        }

        if (sspi_recv_token[1] == 255) {
            Curl_failf(data, "User was rejected by the SOCKS5 server (%u %u).", @as(c_uint, sspi_recv_token[0]), @as(c_uint, sspi_recv_token[1]));
            mem.free(@ptrCast(service_Principal));
            _ = sec_fn.DeleteSecurityContext(&sspi_context);
            _ = sec_fn.FreeCredentialsHandle(&cred_handle);
            return CURLE_COULDNT_CONNECT;
        }

        if (sspi_recv_token[1] != 1) {
            Curl_failf(data, "Invalid SSPI authentication response type (%u %u).", @as(c_uint, sspi_recv_token[0]), @as(c_uint, sspi_recv_token[1]));
            mem.free(@ptrCast(service_Principal));
            _ = sec_fn.DeleteSecurityContext(&sspi_context);
            _ = sec_fn.FreeCredentialsHandle(&cred_handle);
            return CURLE_COULDNT_CONNECT;
        }

        us_length = socks5DecodeTokenLength(sspi_recv_token[0..4]) orelse {
            Curl_failf(data, "Invalid zero-length SSPI authentication token.");
            mem.free(@ptrCast(service_Principal));
            _ = sec_fn.DeleteSecurityContext(&sspi_context);
            _ = sec_fn.FreeCredentialsHandle(&cred_handle);
            return CURLE_COULDNT_CONNECT;
        };

        inbuf_desc.cBuffers = 1;
        inbuf_desc.pBuffers = @ptrCast(&in_sec_buf);
        inbuf_desc.ulVersion = SECBUFFER_VERSION;
        in_sec_buf.BufferType = SECBUFFER_TOKEN;
        in_sec_buf.cbBuffer = us_length;
        in_sec_buf.pvBuffer = mem.malloc(in_sec_buf.cbBuffer);
        if (in_sec_buf.pvBuffer == null) {
            mem.free(@ptrCast(service_Principal));
            _ = sec_fn.DeleteSecurityContext(&sspi_context);
            _ = sec_fn.FreeCredentialsHandle(&cred_handle);
            return CURLE_OUT_OF_MEMORY;
        }

        code = socks5SspiRecv(cf_next, data, sock, @ptrCast(in_sec_buf.pvBuffer), in_sec_buf.cbBuffer);
        if (code != CURLE_OK) {
            Curl_failf(data, "Failed to receive SSPI authentication token.");
            mem.free(@ptrCast(service_Principal));
            scrubAndFreeSecBuffer(&in_sec_buf);
            _ = sec_fn.DeleteSecurityContext(&sspi_context);
            _ = sec_fn.FreeCredentialsHandle(&cred_handle);
            return CURLE_COULDNT_CONNECT;
        }
        p_context = &sspi_context;
    }

    mem.free(@ptrCast(service_Principal));

    status = sec_fn.QueryContextAttributesA(&sspi_context, SECPKG_ATTR_NAMES, @ptrCast(&names));
    _ = sec_fn.FreeCredentialsHandle(&cred_handle);
    if (checkSspiErr(data, status, "QueryContextAttribute")) {
        _ = sec_fn.DeleteSecurityContext(&sspi_context);
        _ = sec_fn.FreeContextBuffer(@ptrCast(names.sUserName));
        Curl_failf(data, "Failed to determine username.");
        return CURLE_COULDNT_CONNECT;
    }
    Curl_infof(data, "SOCKS5 server authenticated user %s with SSPI.", names.sUserName orelse "");
    _ = sec_fn.FreeContextBuffer(@ptrCast(names.sUserName));

    var gss_enc: u8 = 0;
    if ((sspi_ret_flags & ISC_REQ_CONFIDENTIALITY) != 0) {
        gss_enc = 2;
    } else if ((sspi_ret_flags & ISC_REQ_INTEGRITY) != 0) {
        gss_enc = 1;
    }

    const prot_str: [*:0]const u8 = if (gss_enc == 0) "none" else if (gss_enc == 1) "integrity" else "confidentiality";
    Curl_infof(data, "SOCKS5 SSPIaru protection: %s", prot_str);

    sspi_recv_token[0] = 1;
    sspi_recv_token[1] = 2;

    if (socks5_gssapi_nec) {
        _ = socks5EncodeTokenHeader(&sspi_recv_token, 2, 1);
        const send_buf = [5]u8{ sspi_recv_token[0], sspi_recv_token[1], sspi_recv_token[2], sspi_recv_token[3], gss_enc };
        code = socks5SspiSend(cf_next, data, sock, &send_buf, 5);
        if (code != CURLE_OK) {
            Curl_failf(data, "Failed to send SSPI encryption request.");
            _ = sec_fn.DeleteSecurityContext(&sspi_context);
            return CURLE_COULDNT_CONNECT;
        }
    } else {
        status = sec_fn.QueryContextAttributesA(&sspi_context, SECPKG_ATTR_SIZES, @ptrCast(&sizes));
        if (checkSspiErr(data, status, "QueryContextAttributes")) {
            _ = sec_fn.DeleteSecurityContext(&sspi_context);
            Curl_failf(data, "Failed to query security context attributes.");
            return CURLE_COULDNT_CONNECT;
        }

        wrap_sec_buf[0].cbBuffer = sizes.cbSecurityTrailer;
        wrap_sec_buf[0].BufferType = SECBUFFER_TOKEN;
        wrap_sec_buf[0].pvBuffer = mem.malloc(sizes.cbSecurityTrailer);
        if (wrap_sec_buf[0].pvBuffer == null) {
            _ = sec_fn.DeleteSecurityContext(&sspi_context);
            return CURLE_OUT_OF_MEMORY;
        }

        wrap_sec_buf[1].cbBuffer = 1;
        wrap_sec_buf[1].BufferType = SECBUFFER_DATA;
        wrap_sec_buf[1].pvBuffer = mem.malloc(1);
        if (wrap_sec_buf[1].pvBuffer == null) {
            scrubAndFreeSecBuffer(&wrap_sec_buf[0]);
            _ = sec_fn.DeleteSecurityContext(&sspi_context);
            return CURLE_OUT_OF_MEMORY;
        }
        @as(*u8, @ptrCast(wrap_sec_buf[1].pvBuffer.?)).* = gss_enc;

        wrap_sec_buf[2].cbBuffer = sizes.cbBlockSize;
        wrap_sec_buf[2].BufferType = SECBUFFER_PADDING;
        wrap_sec_buf[2].pvBuffer = mem.malloc(sizes.cbBlockSize);
        if (wrap_sec_buf[2].pvBuffer == null) {
            scrubAndFreeSecBuffer(&wrap_sec_buf[0]);
            scrubAndFreeSecBuffer(&wrap_sec_buf[1]);
            _ = sec_fn.DeleteSecurityContext(&sspi_context);
            return CURLE_OUT_OF_MEMORY;
        }

        wrap_desc.cBuffers = 3;
        wrap_desc.pBuffers = &wrap_sec_buf;
        wrap_desc.ulVersion = SECBUFFER_VERSION;

        status = sec_fn.EncryptMessage(&sspi_context, KERB_WRAP_NO_ENCRYPT, &wrap_desc, 0);
        if (checkSspiErr(data, status, "EncryptMessage")) {
            scrubAndFreeSecBuffer(&wrap_sec_buf[0]);
            scrubAndFreeSecBuffer(&wrap_sec_buf[1]);
            scrubAndFreeSecBuffer(&wrap_sec_buf[2]);
            _ = sec_fn.DeleteSecurityContext(&sspi_context);
            Curl_failf(data, "Failed to encrypt theic data for SOCKS5 SSPI.");
            return CURLE_COULDNT_CONNECT;
        }

        const total_len: usize = wrap_sec_buf[0].cbBuffer + wrap_sec_buf[1].cbBuffer + wrap_sec_buf[2].cbBuffer;
        us_length = socks5EncodeTokenHeader(&sspi_recv_token, 2, total_len) orelse {
            scrubAndFreeSecBuffer(&wrap_sec_buf[0]);
            scrubAndFreeSecBuffer(&wrap_sec_buf[1]);
            scrubAndFreeSecBuffer(&wrap_sec_buf[2]);
            _ = sec_fn.DeleteSecurityContext(&sspi_context);
            Curl_failf(data, "Failed to send SSPI encryption request.");
            return CURLE_COULDNT_CONNECT;
        };

        code = socks5SspiSend(cf_next, data, sock, &sspi_recv_token, 4);
        if (code == CURLE_OK) {
            for (0..3) |k| {
                if (wrap_sec_buf[k].cbBuffer != 0 and wrap_sec_buf[k].pvBuffer != null) {
                    code = socks5SspiSend(cf_next, data, sock, @ptrCast(wrap_sec_buf[k].pvBuffer), wrap_sec_buf[k].cbBuffer);
                    if (code != CURLE_OK) break;
                }
            }
        }

        scrubAndFreeSecBuffer(&wrap_sec_buf[0]);
        scrubAndFreeSecBuffer(&wrap_sec_buf[1]);
        scrubAndFreeSecBuffer(&wrap_sec_buf[2]);

        if (code != CURLE_OK) {
            Curl_failf(data, "Failed to send SSPI encryption request.");
            _ = sec_fn.DeleteSecurityContext(&sspi_context);
            return CURLE_COULDNT_CONNECT;
        }
    }

    code = socks5SspiRecv(cf_next, data, sock, &sspi_recv_token, 4);
    if (code != CURLE_OK) {
        Curl_failf(data, "Failed to receive SSPI encryption response.");
        _ = sec_fn.DeleteSecurityContext(&sspi_context);
        return CURLE_COULDNT_CONNECT;
    }

    if (sspi_recv_token[1] == 255) {
        Curl_failf(data, "User was rejected by the SOCKS5 server (%u %u).", @as(c_uint, sspi_recv_token[0]), @as(c_uint, sspi_recv_token[1]));
        _ = sec_fn.DeleteSecurityContext(&sspi_context);
        return CURLE_COULDNT_CONNECT;
    }

    if (sspi_recv_token[1] != 2) {
        Curl_failf(data, "Invalid SSPI encryption response type (%u %u).", @as(c_uint, sspi_recv_token[0]), @as(c_uint, sspi_recv_token[1]));
        _ = sec_fn.DeleteSecurityContext(&sspi_context);
        return CURLE_COULDNT_CONNECT;
    }

    us_length = socks5DecodeTokenLength(sspi_recv_token[0..4]) orelse {
        Curl_failf(data, "Invalid zero-length SSPI encryption token.");
        _ = sec_fn.DeleteSecurityContext(&sspi_context);
        return CURLE_COULDNT_CONNECT;
    };

    wrap_sec_buf[0].cbBuffer = us_length;
    wrap_sec_buf[0].pvBuffer = mem.malloc(us_length);
    if (wrap_sec_buf[0].pvBuffer == null) {
        _ = sec_fn.DeleteSecurityContext(&sspi_context);
        return CURLE_OUT_OF_MEMORY;
    }
    wrap_sec_buf[0].BufferType = SECBUFFER_STREAM;
    wrap_sec_buf[1].BufferType = SECBUFFER_DATA;
    wrap_sec_buf[1].cbBuffer = 0;
    wrap_sec_buf[1].pvBuffer = null;

    code = socks5SspiRecv(cf_next, data, sock, @ptrCast(wrap_sec_buf[0].pvBuffer), wrap_sec_buf[0].cbBuffer);
    if (code != CURLE_OK) {
        Curl_failf(data, "Failed to receive SSPI encryption type.");
        scrubAndFreeSecBuffer(&wrap_sec_buf[0]);
        _ = sec_fn.DeleteSecurityContext(&sspi_context);
        return CURLE_COULDNT_CONNECT;
    }

    if (!socks5_gssapi_nec) {
        wrap_desc.cBuffers = 2;
        wrap_desc.pBuffers = &wrap_sec_buf;
        wrap_desc.ulVersion = SECBUFFER_VERSION;
        status = sec_fn.DecryptMessage(&sspi_context, &wrap_desc, 0, &qop);

        if (checkSspiErr(data, status, "DecryptMessage")) {
            scrubAndFreeSecBuffer(&wrap_sec_buf[0]);
            scrubAndFreeSecBuffer(&wrap_sec_buf[1]);
            _ = sec_fn.DeleteSecurityContext(&sspi_context);
            Curl_failf(data, "Failed to query security context attributes.");
            return CURLE_COULDNT_CONNECT;
        }

        if (wrap_sec_buf[1].cbBuffer != 1 or wrap_sec_buf[1].pvBuffer == null) {
            Curl_failf(data, "Invalid SSPI encryption response length (%lu).", wrap_sec_buf[1].cbBuffer);
            scrubAndFreeSecBuffer(&wrap_sec_buf[0]);
            scrubAndFreeSecBuffer(&wrap_sec_buf[1]);
            _ = sec_fn.DeleteSecurityContext(&sspi_context);
            return CURLE_COULDNT_CONNECT;
        }

        const data_bytes: [*]const u8 = @ptrCast(wrap_sec_buf[1].pvBuffer.?);
        sspi_recv_token[1] = data_bytes[0];
        if (wrap_sec_buf[1].pvBuffer) |p1| {
            mem.secureZero(p1, @intCast(wrap_sec_buf[1].cbBuffer));
        }
        scrubAndFreeSecBuffer(&wrap_sec_buf[0]);
    } else {
        if (wrap_sec_buf[0].cbBuffer != 1) {
            Curl_failf(data, "Invalid SSPI encryption response length (%lu).", wrap_sec_buf[0].cbBuffer);
            scrubAndFreeSecBuffer(&wrap_sec_buf[0]);
            _ = sec_fn.DeleteSecurityContext(&sspi_context);
            return CURLE_COULDNT_CONNECT;
        }
        const data_bytes: [*]const u8 = @ptrCast(wrap_sec_buf[0].pvBuffer.?);
        sspi_recv_token[1] = data_bytes[0];
        scrubAndFreeSecBuffer(&wrap_sec_buf[0]);
    }

    _ = sec_fn.DeleteSecurityContext(&sspi_context);

    socks5_gssapi_enctype.* = sspi_recv_token[1];
    return CURLE_OK;
}

// ============================================================================
// 3. lib/curl_gssapi.c & 4. lib/socks_gssapi.c — GSS-API Helpers & SOCKS5
// ============================================================================

pub const have_gssapi: bool = if (@hasDecl(backend_options, "gssapi")) backend_options.gssapi else false;

pub const gss_OID_desc = extern struct {
    length: u32,
    elements: [*]const u8,
};
pub const gss_OID = ?*const gss_OID_desc;
pub const gss_OID_set_desc = extern struct {
    count: usize,
    elements: [*]gss_OID_desc,
};
pub const gss_OID_set = ?*gss_OID_set_desc;

pub const gss_buffer_desc = extern struct {
    length: usize = 0,
    value: ?*anyopaque = null,
};
pub const gss_buffer_t = *gss_buffer_desc;

const krb5_oid_bytes = "\x2a\x86\x48\x86\xf7\x12\x01\x02\x02";
const iakerb_oid_bytes = "\x2b\x06\x01\x05\x02\x05";
const spnego_oid_bytes = "\x2b\x06\x01\x05\x05\x02";
const ntlm_oid_bytes = "\x2b\x06\x01\x04\x01\x82\x37\x02\x02\x0a";

pub var curl_krb5_mech_oid = gss_OID_desc{ .length = 9, .elements = krb5_oid_bytes.ptr };
pub var curl_iakerb_mech_oid = gss_OID_desc{ .length = 6, .elements = iakerb_oid_bytes.ptr };
pub var curl_spnego_mech_oid = gss_OID_desc{ .length = 6, .elements = spnego_oid_bytes.ptr };
pub var curl_ntlm_mech_oid = gss_OID_desc{ .length = 10, .elements = ntlm_oid_bytes.ptr };

pub fn gssMechanismToOid(mech_opt: ?[*:0]const u8) callconv(.c) gss_OID {
    const mech = mech_opt orelse return null;
    if (curl_strequal(mech, "KRB5") != 0) {
        return &curl_krb5_mech_oid;
    }
    if (curl_strequal(mech, "IAKERB") != 0) {
        return &curl_iakerb_mech_oid;
    }
    if (curl_strequal(mech, "SPNEGO") != 0) {
        return &curl_spnego_mech_oid;
    }
    if (curl_strequal(mech, "NTLM") != 0) {
        return &curl_ntlm_mech_oid;
    }
    return null;
}

pub const OM_uint32 = u32;
pub const gss_qop_t = u32;
pub const gss_cred_usage_t = c_int;
pub const gss_ctx_id_t = ?*anyopaque;
pub const gss_name_t = ?*anyopaque;
pub const gss_cred_id_t = ?*anyopaque;
pub const gss_channel_bindings_t = ?*anyopaque;

const GSS_C_NO_CREDENTIAL: gss_cred_id_t = null;
const GSS_C_NO_CONTEXT: gss_ctx_id_t = null;
const GSS_C_NO_BUFFER: ?*gss_buffer_desc = null;
const GSS_C_NO_OID: gss_OID = null;
const GSS_C_NO_OID_SET: gss_OID_set = null;
const GSS_C_NO_CHANNEL_BINDINGS: gss_channel_bindings_t = null;
const GSS_C_INDEFINITE: OM_uint32 = 0xffffffff;
const GSS_C_QOP_DEFAULT: gss_qop_t = 0;

const GSS_C_DELEG_FLAG: OM_uint32 = 1;
const GSS_C_MUTUAL_FLAG: OM_uint32 = 2;
const GSS_C_REPLAY_FLAG: OM_uint32 = 4;
const GSS_C_SEQUENCE_FLAG: OM_uint32 = 8;
const GSS_C_CONF_FLAG: OM_uint32 = 16;
const GSS_C_INTEG_FLAG: OM_uint32 = 32;
const GSS_C_DELEG_POLICY_FLAG: OM_uint32 = 32768;

const GSS_C_GSS_CODE: c_int = 1;
const GSS_C_MECH_CODE: c_int = 2;
const GSS_S_COMPLETE: OM_uint32 = 0;
const GSS_S_CONTINUE_NEEDED: OM_uint32 = 1;
const GSS_S_FAILURE: OM_uint32 = @as(OM_uint32, 13) << 16;
const GSS_S_ERR_MASK: OM_uint32 = 0xffff0000;

extern fn gss_init_sec_context(
    minor_status: *OM_uint32,
    claimant_cred_handle: gss_cred_id_t,
    context_handle: *gss_ctx_id_t,
    target_name: gss_name_t,
    mech_type: gss_OID,
    req_flags: OM_uint32,
    time_req: OM_uint32,
    input_chan_bindings: gss_channel_bindings_t,
    input_token: ?*gss_buffer_desc,
    actual_mech_type: ?*gss_OID,
    output_token: gss_buffer_t,
    ret_flags: ?*OM_uint32,
    time_rec: ?*OM_uint32,
) callconv(.c) OM_uint32;

extern fn gss_display_status(
    minor_status: *OM_uint32,
    status_value: OM_uint32,
    status_type: c_int,
    mech_type: gss_OID,
    message_context: *OM_uint32,
    status_string: gss_buffer_t,
) callconv(.c) OM_uint32;

extern fn gss_release_buffer(
    minor_status: *OM_uint32,
    buffer: gss_buffer_t,
) callconv(.c) OM_uint32;

extern fn gss_delete_sec_context(
    minor_status: *OM_uint32,
    context_handle: *gss_ctx_id_t,
    output_token: ?*gss_buffer_desc,
) callconv(.c) OM_uint32;

extern fn gss_import_name(
    minor_status: *OM_uint32,
    input_name_buffer: gss_buffer_t,
    input_name_type: gss_OID,
    output_name: *gss_name_t,
) callconv(.c) OM_uint32;

extern fn gss_release_name(
    minor_status: *OM_uint32,
    input_name: *gss_name_t,
) callconv(.c) OM_uint32;

extern fn gss_inquire_context(
    minor_status: *OM_uint32,
    context_handle: gss_ctx_id_t,
    src_name: ?*gss_name_t,
    targ_name: ?*gss_name_t,
    lifetime_rec: ?*OM_uint32,
    mech_type: ?*gss_OID,
    ctx_flags: ?*OM_uint32,
    locally_initiated: ?*c_int,
    open: ?*c_int,
) callconv(.c) OM_uint32;

extern fn gss_display_name(
    minor_status: *OM_uint32,
    input_name: gss_name_t,
    output_name_buffer: gss_buffer_t,
    output_name_type: ?*gss_OID,
) callconv(.c) OM_uint32;

extern fn gss_wrap(
    minor_status: *OM_uint32,
    context_handle: gss_ctx_id_t,
    conf_req_flag: c_int,
    qop_req: gss_qop_t,
    input_message_buffer: gss_buffer_t,
    conf_state: ?*c_int,
    output_message_buffer: gss_buffer_t,
) callconv(.c) OM_uint32;

extern fn gss_unwrap(
    minor_status: *OM_uint32,
    context_handle: gss_ctx_id_t,
    input_message_buffer: gss_buffer_t,
    output_message_buffer: gss_buffer_t,
    conf_state: ?*c_int,
    qop_state: ?*gss_qop_t,
) callconv(.c) OM_uint32;

extern fn gss_acquire_cred(
    minor_status: *OM_uint32,
    desired_name: gss_name_t,
    time_req: OM_uint32,
    desired_mechs: gss_OID_set,
    cred_usage: gss_cred_usage_t,
    output_cred_handle: *gss_cred_id_t,
    actual_mechs: ?*gss_OID_set,
    time_rec: ?*OM_uint32,
) callconv(.c) OM_uint32;

extern fn gss_indicate_mechs(
    minor_status: *OM_uint32,
    mech_set: *gss_OID_set,
) callconv(.c) OM_uint32;

extern fn gss_set_neg_mechs(
    minor_status: *OM_uint32,
    cred_handle: gss_cred_id_t,
    mech_set: gss_OID_set,
) callconv(.c) OM_uint32;

extern fn gss_release_cred(
    minor_status: *OM_uint32,
    cred_handle: *gss_cred_id_t,
) callconv(.c) OM_uint32;

extern var GSS_C_NT_HOSTBASED_SERVICE: gss_OID;

const STUB_CTX_MAGIC: u64 = 0x4355524c53545542;
const MAX_CREDS_LENGTH: usize = 250;

const StubSent = enum(c_int) {
    none = 0,
    krb5 = 1,
    ntlm1 = 2,
    ntlm3 = 3,
};

const StubGssCtx = struct {
    magic: u64 = STUB_CTX_MAGIC,
    sent: StubSent = .none,
    have_krb5: bool = false,
    have_ntlm: bool = false,
    flags: OM_uint32 = 0,
    creds: [MAX_CREDS_LENGTH]u8 = @splat(0),
};

fn isStubGssActive() ?[*:0]const u8 {
    if (std.c.getenv("CURL_STUB_GSS_CREDS")) |env_ptr| {
        if (env_ptr[0] != 0) return env_ptr;
    }
    return null;
}

fn stubGssInitSecContext(
    creds_env: [*:0]const u8,
    minor_status: *OM_uint32,
    context_handle: *gss_ctx_id_t,
    target_name: gss_name_t,
    req_flags: OM_uint32,
    input_token: ?*gss_buffer_desc,
    output_token: gss_buffer_t,
    ret_flags: ?*OM_uint32,
) OM_uint32 {
    minor_status.* = 0;
    const has_input = if (input_token) |it| (it.length > 0 and it.value != null) else false;

    var ctx: *StubGssCtx = undefined;
    if (context_handle.* != null) {
        ctx = @ptrCast(@alignCast(context_handle.*.?));
        if (!has_input) return GSS_S_FAILURE;
        const first_byte = @as([*]const u8, @ptrCast(input_token.?.value.?))[0];
        if (first_byte == 'D') {
            if (ret_flags) |rf| rf.* = ctx.flags;
            output_token.value = null;
            output_token.length = 0;
            return GSS_S_COMPLETE;
        }
        if (first_byte != 'C') return GSS_S_FAILURE;
        if (ctx.sent == .krb5 and ctx.have_ntlm) {
            ctx.sent = .ntlm1;
        } else if (ctx.sent == .ntlm1) {
            ctx.sent = .ntlm3;
        } else {
            return GSS_S_FAILURE;
        }
    } else {
        if (has_input) return GSS_S_FAILURE;
        const raw = mem.calloc(1, @sizeOf(StubGssCtx)) orelse return GSS_S_FAILURE;
        ctx = @ptrCast(@alignCast(raw));
        ctx.* = .{};
        const creds_slice = std.mem.span(creds_env);
        if (creds_slice.len >= MAX_CREDS_LENGTH) {
            mem.free(raw);
            return GSS_S_FAILURE;
        }
        @memcpy(ctx.creds[0..creds_slice.len], creds_slice);
        ctx.creds[creds_slice.len] = 0;
        ctx.have_krb5 = std.mem.indexOf(u8, creds_slice, "KRB5") != null or std.mem.indexOf(u8, creds_slice, "krb5") != null;
        ctx.have_ntlm = std.mem.indexOf(u8, creds_slice, "NTLM") != null or std.mem.indexOf(u8, creds_slice, "ntlm") != null;
        if (ctx.have_krb5) {
            ctx.sent = .krb5;
        } else if (ctx.have_ntlm) {
            ctx.sent = .ntlm1;
        } else {
            mem.free(raw);
            return GSS_S_FAILURE;
        }
        ctx.flags = req_flags;
        if (std.mem.indexOf(u8, creds_slice, "SOCKS5_CONF") != null) {
            ctx.flags |= GSS_C_CONF_FLAG;
        } else if (std.mem.indexOf(u8, creds_slice, "SOCKS5_INTEG") != null) {
            ctx.flags |= GSS_C_INTEG_FLAG;
        }
        context_handle.* = ctx;
    }

    var target_buf = gss_buffer_desc{};
    var target_min: OM_uint32 = 0;
    if (target_name != null) {
        _ = gss_display_name(&target_min, target_name, &target_buf, null);
    }
    defer if (target_buf.value != null) {
        _ = gss_release_buffer(&target_min, &target_buf);
    };
    const target_slice: []const u8 = if (target_buf.value != null and target_buf.length > 0)
        @as([*]const u8, @ptrCast(target_buf.value.?))[0..target_buf.length]
    else
        "unknown";

    const tok_cap: usize = 256;
    const tok_raw = std.c.malloc(tok_cap) orelse return GSS_S_FAILURE;
    const tok_bytes: [*]u8 = @ptrCast(tok_raw);
    const creds_str: [*:0]const u8 = @ptrCast(&ctx.creds);
    var used: usize = 0;
    const hdr_len = curl_msnprintf(
        tok_bytes,
        tok_cap,
        "%s:%.*s:%d:",
        creds_str,
        @as(c_int, @intCast(target_slice.len)),
        target_slice.ptr,
        @as(c_int, @backingInt(ctx.sent)),
    );
    if (hdr_len <= 0) {
        std.c.free(tok_raw);
        return GSS_S_FAILURE;
    }
    used = @intCast(hdr_len);
    const pad_target: usize = 200;
    if (used < pad_target) {
        @memset(tok_bytes[used..pad_target], 'A');
        used = pad_target;
    }
    tok_bytes[used] = 0;
    output_token.value = tok_raw;
    output_token.length = used;
    if (ret_flags) |rf| rf.* = ctx.flags;
    return GSS_S_CONTINUE_NEEDED;
}

pub fn gssInitSecContext(
    data: ?*anyopaque,
    minor_status: *OM_uint32,
    context: *gss_ctx_id_t,
    target_name: gss_name_t,
    mech_type: gss_OID,
    input_chan_bindings: gss_channel_bindings_t,
    input_token: ?*gss_buffer_desc,
    output_token: gss_buffer_t,
    mutual_auth: bool,
    ret_flags: ?*OM_uint32,
    cred_handle: gss_cred_id_t,
) callconv(.c) OM_uint32 {
    var req_flags: OM_uint32 = GSS_C_REPLAY_FLAG;
    if (mutual_auth) {
        req_flags |= GSS_C_MUTUAL_FLAG;
    }
    if (data != null) {
        const deleg = Curl_setopt_get_i64(data, FIELD_GSSAPI_DELEGATION);
        if ((deleg & CURLGSSAPI_DELEGATION_POLICY_FLAG) != 0) {
            req_flags |= GSS_C_DELEG_POLICY_FLAG;
        }
        if ((deleg & CURLGSSAPI_DELEGATION_FLAG) != 0) {
            req_flags |= GSS_C_DELEG_FLAG;
        }
    }
    if (isStubGssActive()) |creds_env| {
        return stubGssInitSecContext(
            creds_env,
            minor_status,
            context,
            target_name,
            req_flags,
            input_token,
            output_token,
            ret_flags,
        );
    }
    return gss_init_sec_context(
        minor_status,
        cred_handle,
        context,
        target_name,
        mech_type,
        req_flags,
        GSS_C_INDEFINITE,
        input_chan_bindings,
        input_token,
        null,
        output_token,
        ret_flags,
        null,
    );
}

pub fn gssDeleteSecContext(
    min: *OM_uint32,
    context: *gss_ctx_id_t,
    output_token: ?*gss_buffer_desc,
) callconv(.c) OM_uint32 {
    if (isStubGssActive() != null) {
        min.* = 0;
        if (context.*) |ctx_ptr| {
            mem.free(ctx_ptr);
            context.* = null;
        }
        if (output_token) |ot| {
            ot.value = null;
            ot.length = 0;
        }
        return GSS_S_COMPLETE;
    }
    return gss_delete_sec_context(min, context, output_token);
}

pub fn gssInquireContext(
    minor_status: *OM_uint32,
    context: gss_ctx_id_t,
    mech_type: ?*gss_OID,
) callconv(.c) OM_uint32 {
    if (isStubGssActive() != null) {
        minor_status.* = 0;
        const ctx: *const StubGssCtx = @ptrCast(@alignCast(context orelse return GSS_S_FAILURE));
        if (mech_type) |mt| {
            mt.* = switch (ctx.sent) {
                .krb5 => &curl_krb5_mech_oid,
                .ntlm1, .ntlm3 => &curl_ntlm_mech_oid,
                .none => null,
            };
        }
        return GSS_S_COMPLETE;
    }
    return gss_inquire_context(minor_status, context, null, null, null, mech_type, null, null, null);
}

pub fn gssAcquireCred(
    minor_status: *OM_uint32,
    desired_name: gss_name_t,
    time_req: OM_uint32,
    desired_mechs: gss_OID_set,
    cred_usage: gss_cred_usage_t,
    output_cred_handle: *gss_cred_id_t,
    actual_mechs: ?*gss_OID_set,
    time_rec: ?*OM_uint32,
) callconv(.c) OM_uint32 {
    if (isStubGssActive() != null) {
        minor_status.* = 0;
        return GSS_S_COMPLETE;
    }
    return gss_acquire_cred(
        minor_status,
        desired_name,
        time_req,
        desired_mechs,
        cred_usage,
        output_cred_handle,
        actual_mechs,
        time_rec,
    );
}

pub fn gssIndicateMechs(
    minor_status: *OM_uint32,
    mech_set: *gss_OID_set,
) callconv(.c) OM_uint32 {
    if (isStubGssActive() != null) {
        minor_status.* = 0;
        mech_set.* = GSS_C_NO_OID_SET;
        return GSS_S_COMPLETE;
    }
    return gss_indicate_mechs(minor_status, mech_set);
}

pub fn gssSetNegMechs(
    minor_status: *OM_uint32,
    cred_handle: gss_cred_id_t,
    mech_set: gss_OID_set,
) callconv(.c) OM_uint32 {
    if (isStubGssActive() != null or comptime builtin.os.tag.isDarwin()) {
        minor_status.* = 0;
        return GSS_S_COMPLETE;
    }
    return gss_set_neg_mechs(minor_status, cred_handle, mech_set);
}

pub fn gssReleaseCred(
    minor_status: *OM_uint32,
    cred_handle: *gss_cred_id_t,
) callconv(.c) OM_uint32 {
    if (isStubGssActive() != null) {
        minor_status.* = 0;
        cred_handle.* = GSS_C_NO_CREDENTIAL;
        return GSS_S_COMPLETE;
    }
    return gss_release_cred(minor_status, cred_handle);
}

fn socks5GssWrap(
    minor_status: *OM_uint32,
    context_handle: gss_ctx_id_t,
    conf_req_flag: c_int,
    qop_req: gss_qop_t,
    input_message_buffer: gss_buffer_t,
    conf_state: ?*c_int,
    output_message_buffer: gss_buffer_t,
) OM_uint32 {
    if (isStubGssActive() != null) {
        minor_status.* = 0;
        if (conf_state) |cs| cs.* = conf_req_flag;
        if (input_message_buffer.length == 0 or input_message_buffer.value == null) {
            output_message_buffer.value = null;
            output_message_buffer.length = 0;
            return GSS_S_COMPLETE;
        }
        const out_raw = std.c.malloc(input_message_buffer.length) orelse return GSS_S_FAILURE;
        @memcpy(
            @as([*]u8, @ptrCast(out_raw))[0..input_message_buffer.length],
            @as([*]const u8, @ptrCast(input_message_buffer.value.?))[0..input_message_buffer.length],
        );
        output_message_buffer.value = out_raw;
        output_message_buffer.length = input_message_buffer.length;
        return GSS_S_COMPLETE;
    }
    return gss_wrap(minor_status, context_handle, conf_req_flag, qop_req, input_message_buffer, conf_state, output_message_buffer);
}

fn socks5GssUnwrap(
    minor_status: *OM_uint32,
    context_handle: gss_ctx_id_t,
    input_message_buffer: gss_buffer_t,
    output_message_buffer: gss_buffer_t,
    conf_state: ?*c_int,
    qop_state: ?*gss_qop_t,
) OM_uint32 {
    if (isStubGssActive() != null) {
        minor_status.* = 0;
        if (conf_state) |cs| cs.* = 0;
        if (qop_state) |qs| qs.* = GSS_C_QOP_DEFAULT;
        if (input_message_buffer.length == 0 or input_message_buffer.value == null) {
            output_message_buffer.value = null;
            output_message_buffer.length = 0;
            return GSS_S_COMPLETE;
        }
        const out_raw = std.c.malloc(input_message_buffer.length) orelse return GSS_S_FAILURE;
        @memcpy(
            @as([*]u8, @ptrCast(out_raw))[0..input_message_buffer.length],
            @as([*]const u8, @ptrCast(input_message_buffer.value.?))[0..input_message_buffer.length],
        );
        output_message_buffer.value = out_raw;
        output_message_buffer.length = input_message_buffer.length;
        return GSS_S_COMPLETE;
    }
    return gss_unwrap(minor_status, context_handle, input_message_buffer, output_message_buffer, conf_state, qop_state);
}

const GSS_LOG_BUFFER_LEN: usize = 1024;

fn displayGssError(status: OM_uint32, status_type: c_int, buf: [*]u8, pos_in: usize) usize {
    var maj_stat: OM_uint32 = 0;
    var min_stat: OM_uint32 = 0;
    var msg_ctx: OM_uint32 = 0;
    var pos = pos_in;

    while (true) {
        var status_string = gss_buffer_desc{};
        maj_stat = gss_display_status(
            &min_stat,
            status,
            status_type,
            GSS_C_NO_OID,
            &msg_ctx,
            &status_string,
        );
        if (maj_stat == GSS_S_COMPLETE and status_string.length > 0 and status_string.value != null) {
            if (GSS_LOG_BUFFER_LEN > pos + status_string.length + 3) {
                const n = curl_msnprintf(
                    buf + pos,
                    GSS_LOG_BUFFER_LEN - pos,
                    "%.*s. ",
                    @as(c_int, @intCast(status_string.length)),
                    @as([*]const u8, @ptrCast(status_string.value.?)),
                );
                if (n > 0) {
                    pos += @intCast(n);
                }
            }
        }
        _ = gss_release_buffer(&min_stat, &status_string);
        if (msg_ctx == 0) break;
    }
    return pos;
}

pub fn gssLogError(
    data: ?*anyopaque,
    prefix: [*:0]const u8,
    major: OM_uint32,
    minor: OM_uint32,
) callconv(.c) void {
    var buf: [GSS_LOG_BUFFER_LEN]u8 = undefined;
    var pos: usize = 0;

    if (major != GSS_S_FAILURE) {
        pos = displayGssError(major, GSS_C_GSS_CODE, &buf, pos);
    }
    _ = displayGssError(minor, GSS_C_MECH_CODE, &buf, pos);
    buf[pos] = 0;
    Curl_infof(data, "%s%s", prefix, @as([*:0]const u8, @ptrCast(&buf)));
}

fn gssScrubAndReleaseBuffer(minor_status: *OM_uint32, buf: *gss_buffer_desc) void {
    if (buf.value) |ptr| {
        if (buf.length > 0) {
            mem.secureZero(ptr, buf.length);
        }
    }
    _ = gss_release_buffer(minor_status, buf);
    buf.value = null;
    buf.length = 0;
}

fn checkGssErr(
    data: ?*anyopaque,
    major_status: OM_uint32,
    minor_status: OM_uint32,
    function: [*:0]const u8,
) bool {
    if ((major_status & GSS_S_ERR_MASK) != 0) {
        gssLogError(data, function, major_status, minor_status);
        return true;
    }
    return false;
}

pub fn socks5GssapiNegotiateGss(
    cf: ?*anyopaque,
    cf_next: ?*anyopaque,
    data: ?*anyopaque,
    creds: ?*Curl_creds,
    sock: curl_socket_t,
    service_name_opt: ?[*:0]const u8,
    proxy_hostname_opt: ?[*:0]const u8,
    socks5_gssapi_nec: bool,
    socks5_gssapi_enctype: *c_int,
) callconv(.c) CURLcode {
    var gss_major_status: OM_uint32 = 0;
    var gss_minor_status: OM_uint32 = 0;
    var gss_status: OM_uint32 = 0;
    var gss_ret_flags: OM_uint32 = 0;
    var gss_conf_state: c_int = 0;
    var gss_qop_state: gss_qop_t = GSS_C_QOP_DEFAULT;
    var gss_send_token = gss_buffer_desc{};
    var gss_recv_token = gss_buffer_desc{};
    var gss_w_token = gss_buffer_desc{};
    var gss_token: ?*gss_buffer_desc = GSS_C_NO_BUFFER;
    var gss_context: gss_ctx_id_t = GSS_C_NO_CONTEXT;
    var server: gss_name_t = null;
    var gss_client_name: gss_name_t = null;
    var us_length: u16 = 0;
    var rcvbuf: [4]u8 = undefined;
    const service: [*:0]const u8 = if (service_name_opt) |s|
        (if (s[0] != 0) s else "rcmd")
    else if (creds) |cr|
        (if (cr.sasl_service) |ss| (if (ss[0] != 0) ss else "rcmd") else "rcmd")
    else
        "rcmd";
    const service_length = std.mem.len(service);
    const proxy_hostname: [*:0]const u8 = proxy_hostname_opt orelse "";

    if (std.mem.indexOfScalar(u8, service[0..service_length], '/') != null) {
        var service_name_buf = gss_buffer_desc{
            .length = service_length,
            .value = @ptrCast(mem.malloc(service_length)),
        };
        if (service_name_buf.value == null) return CURLE_OUT_OF_MEMORY;
        @memcpy(@as([*]u8, @ptrCast(service_name_buf.value.?))[0..service_length], service[0..service_length]);
        gss_major_status = gss_import_name(&gss_minor_status, &service_name_buf, GSS_C_NO_OID, &server);
        mem.free(service_name_buf.value);
    } else {
        const host_len = std.mem.len(proxy_hostname);
        var service_name_buf = gss_buffer_desc{
            .length = service_length + 1 + host_len,
            .value = @ptrCast(mem.malloc(service_length + 1 + host_len + 1)),
        };
        if (service_name_buf.value == null) return CURLE_OUT_OF_MEMORY;
        _ = curl_msnprintf(@ptrCast(service_name_buf.value.?), service_name_buf.length + 1, "%s@%s", service, proxy_hostname);
        gss_major_status = gss_import_name(&gss_minor_status, &service_name_buf, GSS_C_NT_HOSTBASED_SERVICE, &server);
        mem.free(service_name_buf.value);
    }

    if (checkGssErr(data, gss_major_status, gss_minor_status, "gss_import_name() failed: ")) {
        Curl_failf(data, "Failed to create service name.");
        _ = gss_release_name(&gss_status, &server);
        return CURLE_COULDNT_CONNECT;
    }

    _ = curlx_nonblock(sock, 0);
    defer _ = curlx_nonblock(sock, 1);

    while (true) {
        gss_major_status = gssInitSecContext(
            data,
            &gss_minor_status,
            &gss_context,
            server,
            &curl_krb5_mech_oid,
            GSS_C_NO_CHANNEL_BINDINGS,
            gss_token,
            &gss_send_token,
            true,
            &gss_ret_flags,
            GSS_C_NO_CREDENTIAL,
        );

        if (gss_token != null) {
            gssScrubAndReleaseBuffer(&gss_status, &gss_recv_token);
            gss_token = GSS_C_NO_BUFFER;
        }

        if (checkGssErr(data, gss_major_status, gss_minor_status, "gss_init_sec_context() failed: ")) {
            _ = gss_release_name(&gss_status, &server);
            gssScrubAndReleaseBuffer(&gss_status, &gss_recv_token);
            gssScrubAndReleaseBuffer(&gss_status, &gss_send_token);
            _ = gssDeleteSecContext(&gss_status, &gss_context, GSS_C_NO_BUFFER);
            Curl_failf(data, "Failed to initial GSS-API token.");
            return CURLE_COULDNT_CONNECT;
        }

        if (gss_send_token.length != 0) {
            const send_len = socks5EncodeTokenHeader(&rcvbuf, 1, gss_send_token.length) orelse {
                Curl_failf(data, "Failed to send GSS-API authentication token.");
                _ = gss_release_name(&gss_status, &server);
                gssScrubAndReleaseBuffer(&gss_status, &gss_recv_token);
                gssScrubAndReleaseBuffer(&gss_status, &gss_send_token);
                _ = gssDeleteSecContext(&gss_status, &gss_context, GSS_C_NO_BUFFER);
                return CURLE_COULDNT_CONNECT;
            };

            var code = socks5SspiSend(cf_next, data, sock, &rcvbuf, 4);
            if (code == CURLE_OK and gss_send_token.value != null) {
                code = socks5SspiSend(cf_next, data, sock, @ptrCast(gss_send_token.value.?), send_len);
            }
            if (code != CURLE_OK) {
                Curl_failf(data, "Failed to send GSS-API authentication token.");
                _ = gss_release_name(&gss_status, &server);
                gssScrubAndReleaseBuffer(&gss_status, &gss_recv_token);
                gssScrubAndReleaseBuffer(&gss_status, &gss_send_token);
                _ = gssDeleteSecContext(&gss_status, &gss_context, GSS_C_NO_BUFFER);
                return CURLE_COULDNT_CONNECT;
            }
        }

        gssScrubAndReleaseBuffer(&gss_status, &gss_send_token);
        gssScrubAndReleaseBuffer(&gss_status, &gss_recv_token);
        if (gss_major_status != GSS_S_CONTINUE_NEEDED) break;

        var nread: usize = 0;
        var result = Curl_blockread_all(cf, data, &rcvbuf, 4, &nread);
        if (result != CURLE_OK or nread != 4) {
            Curl_failf(data, "Failed to receive GSS-API authentication response.");
            _ = gss_release_name(&gss_status, &server);
            _ = gssDeleteSecContext(&gss_status, &gss_context, GSS_C_NO_BUFFER);
            return CURLE_COULDNT_CONNECT;
        }

        if (rcvbuf[0] != 1) {
            Curl_failf(data, "Received invalid version in initial SOCKS5 response.");
            _ = gss_release_name(&gss_status, &server);
            _ = gssDeleteSecContext(&gss_status, &gss_context, GSS_C_NO_BUFFER);
            return CURLE_COULDNT_CONNECT;
        }

        if (rcvbuf[1] == 255) {
            Curl_failf(data, "User was rejected by the SOCKS5 server (%u %u).", @as(c_uint, rcvbuf[0]), @as(c_uint, rcvbuf[1]));
            _ = gss_release_name(&gss_status, &server);
            _ = gssDeleteSecContext(&gss_status, &gss_context, GSS_C_NO_BUFFER);
            return CURLE_COULDNT_CONNECT;
        }

        if (rcvbuf[1] != 1) {
            Curl_failf(data, "Invalid GSS-API authentication response type (%u %u).", @as(c_uint, rcvbuf[0]), @as(c_uint, rcvbuf[1]));
            _ = gss_release_name(&gss_status, &server);
            _ = gssDeleteSecContext(&gss_status, &gss_context, GSS_C_NO_BUFFER);
            return CURLE_COULDNT_CONNECT;
        }

        us_length = socks5DecodeTokenLength(rcvbuf[0..4]) orelse {
            Curl_failf(data, "Invalid zero-length GSS-API authentication token.");
            _ = gss_release_name(&gss_status, &server);
            _ = gssDeleteSecContext(&gss_status, &gss_context, GSS_C_NO_BUFFER);
            return CURLE_COULDNT_CONNECT;
        };

        gss_recv_token.length = us_length;
        gss_recv_token.value = std.c.malloc(us_length);
        if (gss_recv_token.value == null) {
            _ = gss_release_name(&gss_status, &server);
            _ = gssDeleteSecContext(&gss_status, &gss_context, GSS_C_NO_BUFFER);
            return CURLE_OUT_OF_MEMORY;
        }

        result = Curl_blockread_all(cf, data, @ptrCast(gss_recv_token.value.?), gss_recv_token.length, &nread);
        if (result != CURLE_OK or nread != us_length) {
            Curl_failf(data, "Failed to receive GSS-API authentication token.");
            _ = gss_release_name(&gss_status, &server);
            gssScrubAndReleaseBuffer(&gss_status, &gss_recv_token);
            _ = gssDeleteSecContext(&gss_status, &gss_context, GSS_C_NO_BUFFER);
            return CURLE_COULDNT_CONNECT;
        }
        gss_token = &gss_recv_token;
    }

    _ = gss_release_name(&gss_status, &server);

    if (isStubGssActive()) |creds_env| {
        const creds_slice = std.mem.span(creds_env);
        const colon_idx = std.mem.indexOfScalar(u8, creds_slice, ':') orelse creds_slice.len;
        Curl_infof(
            data,
            "SOCKS5 server authenticated user %.*s with GSS-API.",
            @as(c_int, @intCast(colon_idx)),
            creds_slice.ptr,
        );
    } else {
        gss_major_status = gss_inquire_context(
            &gss_minor_status,
            gss_context,
            &gss_client_name,
            null,
            null,
            null,
            &gss_ret_flags,
            null,
            null,
        );
        if (checkGssErr(data, gss_major_status, gss_minor_status, "gss_inquire_context() failed: ")) {
            _ = gssDeleteSecContext(&gss_status, &gss_context, GSS_C_NO_BUFFER);
            _ = gss_release_name(&gss_status, &gss_client_name);
            Curl_failf(data, "Failed to determine username.");
            return CURLE_COULDNT_CONNECT;
        }

        gss_major_status = gss_display_name(&gss_minor_status, gss_client_name, &gss_send_token, null);
        if (checkGssErr(data, gss_major_status, gss_minor_status, "gss_display_name() failed: ")) {
            _ = gssDeleteSecContext(&gss_status, &gss_context, GSS_C_NO_BUFFER);
            _ = gss_release_name(&gss_status, &gss_client_name);
            gssScrubAndReleaseBuffer(&gss_status, &gss_send_token);
            Curl_failf(data, "Failed to allocate memory.");
            return CURLE_COULDNT_CONNECT;
        }
        Curl_infof(
            data,
            "SOCKS5 server authenticated user %.*s with GSS-API.",
            @as(c_int, @intCast(gss_send_token.length)),
            if (gss_send_token.value) |v| @as([*]const u8, @ptrCast(v)) else @as([*]const u8, ""),
        );
        _ = gss_release_name(&gss_status, &gss_client_name);
        gssScrubAndReleaseBuffer(&gss_status, &gss_send_token);
    }

    var gss_enc: u8 = 0;
    if ((gss_ret_flags & GSS_C_CONF_FLAG) != 0) {
        gss_enc = 2;
    } else if ((gss_ret_flags & GSS_C_INTEG_FLAG) != 0) {
        gss_enc = 1;
    }

    const prot_str: [*:0]const u8 = if (gss_enc == 0) "none" else if (gss_enc == 1) "integrity" else "confidentiality";
    Curl_infof(data, "SOCKS5 GSS-API protection: %s", prot_str);

    if (socks5_gssapi_nec) {
        _ = socks5EncodeTokenHeader(&rcvbuf, 2, 1);
        const send_buf = [5]u8{ rcvbuf[0], rcvbuf[1], rcvbuf[2], rcvbuf[3], gss_enc };
        const code = socks5SspiSend(cf_next, data, sock, &send_buf, 5);
        if (code != CURLE_OK) {
            Curl_failf(data, "Failed to send GSS-API encryption request.");
            _ = gssDeleteSecContext(&gss_status, &gss_context, GSS_C_NO_BUFFER);
            return CURLE_COULDNT_CONNECT;
        }
    } else {
        var enc_byte: [1]u8 = .{gss_enc};
        gss_send_token.length = 1;
        gss_send_token.value = &enc_byte;
        gss_major_status = socks5GssWrap(&gss_minor_status, gss_context, 0, GSS_C_QOP_DEFAULT, &gss_send_token, &gss_conf_state, &gss_w_token);
        gss_send_token.value = null;
        gss_send_token.length = 0;
        if (checkGssErr(data, gss_major_status, gss_minor_status, "gss_wrap() failed: ")) {
            gssScrubAndReleaseBuffer(&gss_status, &gss_w_token);
            _ = gssDeleteSecContext(&gss_status, &gss_context, GSS_C_NO_BUFFER);
            Curl_failf(data, "Failed to wrap GSS-API encryption value into token.");
            return CURLE_COULDNT_CONNECT;
        }
        const wrap_len = socks5EncodeTokenHeader(&rcvbuf, 2, gss_w_token.length) orelse {
            gssScrubAndReleaseBuffer(&gss_status, &gss_w_token);
            _ = gssDeleteSecContext(&gss_status, &gss_context, GSS_C_NO_BUFFER);
            Curl_failf(data, "Failed to send GSS-API encryption request.");
            return CURLE_COULDNT_CONNECT;
        };
        var code = socks5SspiSend(cf_next, data, sock, &rcvbuf, 4);
        if (code == CURLE_OK and gss_w_token.value != null) {
            code = socks5SspiSend(cf_next, data, sock, @ptrCast(gss_w_token.value.?), wrap_len);
        }
        gssScrubAndReleaseBuffer(&gss_status, &gss_w_token);
        if (code != CURLE_OK) {
            Curl_failf(data, "Failed to send GSS-API encryption request.");
            _ = gssDeleteSecContext(&gss_status, &gss_context, GSS_C_NO_BUFFER);
            return CURLE_COULDNT_CONNECT;
        }
    }

    var nread: usize = 0;
    var result = Curl_blockread_all(cf, data, &rcvbuf, 4, &nread);
    if (result != CURLE_OK or nread != 4) {
        Curl_failf(data, "Failed to receive GSS-API encryption response.");
        _ = gssDeleteSecContext(&gss_status, &gss_context, GSS_C_NO_BUFFER);
        return CURLE_COULDNT_CONNECT;
    }

    if (rcvbuf[1] == 255) {
        Curl_failf(data, "User was rejected by the SOCKS5 server (%u %u).", @as(c_uint, rcvbuf[0]), @as(c_uint, rcvbuf[1]));
        _ = gssDeleteSecContext(&gss_status, &gss_context, GSS_C_NO_BUFFER);
        return CURLE_COULDNT_CONNECT;
    }

    if (rcvbuf[1] != 2) {
        Curl_failf(data, "Invalid GSS-API encryption response type (%u %u).", @as(c_uint, rcvbuf[0]), @as(c_uint, rcvbuf[1]));
        _ = gssDeleteSecContext(&gss_status, &gss_context, GSS_C_NO_BUFFER);
        return CURLE_COULDNT_CONNECT;
    }

    us_length = socks5DecodeTokenLength(rcvbuf[0..4]) orelse {
        Curl_failf(data, "Invalid zero-length GSS-API encryption token.");
        _ = gssDeleteSecContext(&gss_status, &gss_context, GSS_C_NO_BUFFER);
        return CURLE_COULDNT_CONNECT;
    };

    gss_recv_token.length = us_length;
    gss_recv_token.value = std.c.malloc(gss_recv_token.length);
    if (gss_recv_token.value == null) {
        _ = gssDeleteSecContext(&gss_status, &gss_context, GSS_C_NO_BUFFER);
        return CURLE_OUT_OF_MEMORY;
    }

    result = Curl_blockread_all(cf, data, @ptrCast(gss_recv_token.value.?), gss_recv_token.length, &nread);
    if (result != CURLE_OK or nread != us_length) {
        Curl_failf(data, "Failed to receive GSS-API encryption type.");
        gssScrubAndReleaseBuffer(&gss_status, &gss_recv_token);
        _ = gssDeleteSecContext(&gss_status, &gss_context, GSS_C_NO_BUFFER);
        return CURLE_COULDNT_CONNECT;
    }

    if (!socks5_gssapi_nec) {
        gss_major_status = socks5GssUnwrap(&gss_minor_status, gss_context, &gss_recv_token, &gss_w_token, &gss_conf_state, &gss_qop_state);
        gssScrubAndReleaseBuffer(&gss_status, &gss_recv_token);
        if (checkGssErr(data, gss_major_status, gss_minor_status, "gss_unwrap() failed: ")) {
            gssScrubAndReleaseBuffer(&gss_status, &gss_w_token);
            _ = gssDeleteSecContext(&gss_status, &gss_context, GSS_C_NO_BUFFER);
            Curl_failf(data, "Failed to unwrap GSS-API encryption value into token.");
            return CURLE_COULDNT_CONNECT;
        }
        if (gss_w_token.length != 1 or gss_w_token.value == null) {
            Curl_failf(data, "Invalid GSS-API encryption response length (%zu).", gss_w_token.length);
            gssScrubAndReleaseBuffer(&gss_status, &gss_w_token);
            _ = gssDeleteSecContext(&gss_status, &gss_context, GSS_C_NO_BUFFER);
            return CURLE_COULDNT_CONNECT;
        }
        rcvbuf[1] = @as([*]const u8, @ptrCast(gss_w_token.value.?))[0];
        gssScrubAndReleaseBuffer(&gss_status, &gss_w_token);
    } else {
        if (gss_recv_token.length != 1) {
            Curl_failf(data, "Invalid GSS-API encryption response length (%zu).", gss_recv_token.length);
            gssScrubAndReleaseBuffer(&gss_status, &gss_recv_token);
            _ = gssDeleteSecContext(&gss_status, &gss_context, GSS_C_NO_BUFFER);
            return CURLE_COULDNT_CONNECT;
        }
        rcvbuf[1] = @as([*]const u8, @ptrCast(gss_recv_token.value.?))[0];
        gssScrubAndReleaseBuffer(&gss_status, &gss_recv_token);
    }

    _ = gssDeleteSecContext(&gss_status, &gss_context, GSS_C_NO_BUFFER);
    socks5_gssapi_enctype.* = rcvbuf[1];
    return CURLE_OK;
}

comptime {
    if (builtin.os.tag == .windows) {
        @export(&isDigestSupportedSspi, .{ .name = "Curl_auth_is_digest_supported" });
        @export(&createDigestMd5MessageHostSspi, .{ .name = "Curl_auth_create_digest_md5_message_host" });
        @export(&overrideSspiHttpRealm, .{ .name = "Curl_override_sspi_http_realm" });
        @export(&decodeDigestHttpMessageSspi, .{ .name = "Curl_auth_decode_digest_http_message" });
        @export(&createDigestHttpMessageSspi, .{ .name = "Curl_auth_create_digest_http_message" });
        @export(&digestCleanupSspi, .{ .name = "Curl_auth_digest_cleanup" });
        @export(&socks5GssapiNegotiateSspi, .{ .name = "Curl_SOCKS5_gssapi_negotiate_ex" });
    } else {
        @export(&isDigestSupportedRfc, .{ .name = "Curl_auth_is_digest_supported" });
        @export(&createDigestMd5MessageHostRfc, .{ .name = "Curl_auth_create_digest_md5_message_host" });
        @export(&decodeDigestHttpMessageRfc, .{ .name = "Curl_auth_decode_digest_http_message" });
        @export(&createDigestHttpMessageRfc, .{ .name = "Curl_auth_create_digest_http_message" });
        @export(&digestCleanupRfc, .{ .name = "Curl_auth_digest_cleanup" });
    }
    if (have_gssapi) {
        @export(&curl_krb5_mech_oid, .{ .name = "Curl_krb5_mech_oid" });
        @export(&curl_spnego_mech_oid, .{ .name = "Curl_spnego_mech_oid" });
        @export(&gssMechanismToOid, .{ .name = "Curl_gss_MechanismToOID" });
        @export(&gssInitSecContext, .{ .name = "Curl_gss_init_sec_context" });
        @export(&gssDeleteSecContext, .{ .name = "Curl_gss_delete_sec_context" });
        @export(&gssInquireContext, .{ .name = "Curl_gss_inquire_context" });
        @export(&gssAcquireCred, .{ .name = "Curl_gss_acquire_cred" });
        @export(&gssIndicateMechs, .{ .name = "Curl_gss_indicate_mechs" });
        @export(&gssSetNegMechs, .{ .name = "Curl_gss_set_neg_mechs" });
        @export(&gssReleaseCred, .{ .name = "Curl_gss_release_cred" });
        @export(&gssLogError, .{ .name = "Curl_gss_log_error" });
        if (builtin.os.tag != .windows) {
            @export(&socks5GssapiNegotiateGss, .{ .name = "Curl_SOCKS5_gssapi_negotiate_ex" });
        }
    }
}

// ============================================================================
// Unit Tests
// ============================================================================

test "Curl_auth_digest_get_pair basic and quoted pairs" {
    const chlg: [*:0]const u8 = "realm=\"testrealm@host.com\", qop=\"auth,auth-int\", nonce=\"dcd98b7102dd2f0e8b11d0f600bfb0c093\", opaque=\"5ccc069c403ebaf9f0171e9517f40e41\", algorithm=MD5, stale=false";
    var p = chlg;
    var val = Curl_str{ .str = null, .len = 0 };
    var content: [DIGEST_MAX_CONTENT_LENGTH]u8 = undefined;

    try std.testing.expect(Curl_auth_digest_get_pair(p, &val, &content, &p));
    try std.testing.expect(curlx_str_casecompare(&val, "realm") != 0);
    try std.testing.expectEqualStrings("testrealm@host.com", std.mem.span(@as([*:0]const u8, @ptrCast(&content))));

    while (p[0] == ',' or p[0] == ' ') p += 1;
    try std.testing.expect(Curl_auth_digest_get_pair(p, &val, &content, &p));
    try std.testing.expect(curlx_str_casecompare(&val, "qop") != 0);
    try std.testing.expectEqualStrings("auth,auth-int", std.mem.span(@as([*:0]const u8, @ptrCast(&content))));

    while (p[0] == ',' or p[0] == ' ') p += 1;
    try std.testing.expect(Curl_auth_digest_get_pair(p, &val, &content, &p));
    try std.testing.expect(curlx_str_casecompare(&val, "nonce") != 0);
    try std.testing.expectEqualStrings("dcd98b7102dd2f0e8b11d0f600bfb0c093", std.mem.span(@as([*:0]const u8, @ptrCast(&content))));

    while (p[0] == ',' or p[0] == ' ') p += 1;
    try std.testing.expect(Curl_auth_digest_get_pair(p, &val, &content, &p));
    try std.testing.expect(curlx_str_casecompare(&val, "opaque") != 0);
    try std.testing.expectEqualStrings("5ccc069c403ebaf9f0171e9517f40e41", std.mem.span(@as([*:0]const u8, @ptrCast(&content))));

    while (p[0] == ',' or p[0] == ' ') p += 1;
    try std.testing.expect(Curl_auth_digest_get_pair(p, &val, &content, &p));
    try std.testing.expect(curlx_str_casecompare(&val, "algorithm") != 0);
    try std.testing.expectEqualStrings("MD5", std.mem.span(@as([*:0]const u8, @ptrCast(&content))));

    while (p[0] == ',' or p[0] == ' ') p += 1;
    try std.testing.expect(Curl_auth_digest_get_pair(p, &val, &content, &p));
    try std.testing.expect(curlx_str_casecompare(&val, "stale") != 0);
    try std.testing.expectEqualStrings("false", std.mem.span(@as([*:0]const u8, @ptrCast(&content))));
}

test "Curl_auth_digest_get_pair escapes and error cases" {
    var val = Curl_str{ .str = null, .len = 0 };
    var content: [DIGEST_MAX_CONTENT_LENGTH]u8 = undefined;
    var endp: [*:0]const u8 = undefined;

    // Escaped quote inside quoted string
    const escaped: [*:0]const u8 = "realm=\"a\\\"b\\\\c\"";
    try std.testing.expect(Curl_auth_digest_get_pair(escaped, &val, &content, &endp));
    try std.testing.expectEqualStrings("a\"b\\c", std.mem.span(@as([*:0]const u8, @ptrCast(&content))));

    // Quote inside unquoted value is invalid
    const bad_quote: [*:0]const u8 = "realm=ab\"c";
    try std.testing.expect(!Curl_auth_digest_get_pair(bad_quote, &val, &content, &endp));

    // Newline inside quoted value is invalid
    const bad_nl: [*:0]const u8 = "realm=\"ab\nc\"";
    try std.testing.expect(!Curl_auth_digest_get_pair(bad_nl, &val, &content, &endp));

    // Trailing backslash escape at end of input is invalid
    const bad_esc: [*:0]const u8 = "realm=\"abc\\";
    try std.testing.expect(!Curl_auth_digest_get_pair(bad_esc, &val, &content, &endp));
}

test "Curl_auth_decode_digest_http_message and RFC 2617 MD5 qop=auth vector" {
    var digest = DigestDataRfc{};
    defer digestCleanupRfc(&digest);

    const chlg: [*:0]const u8 =
        "realm=\"testrealm@host.com\", qop=\"auth,auth-int\", nonce=\"dcd98b7102dd2f0e8b11d0f600bfb0c093\", opaque=\"5ccc069c403ebaf9f0171e9517f40e41\"";
    try std.testing.expectEqual(CURLE_OK, decodeDigestHttpMessageRfc(chlg, &digest));
    try std.testing.expectEqualStrings("testrealm@host.com", std.mem.span(digest.realm.?));
    try std.testing.expectEqualStrings("dcd98b7102dd2f0e8b11d0f600bfb0c093", std.mem.span(digest.nonce.?));
    try std.testing.expectEqualStrings("5ccc069c403ebaf9f0171e9517f40e41", std.mem.span(digest.@"opaque".?));
    try std.testing.expectEqualStrings("auth", std.mem.span(digest.qop.?));
    try std.testing.expectEqual(ALGO_MD5, digest.algo);

    // Pre-populate RFC 2617 Section 3.5 cnonce "0a4f113b" to verify exact response hash
    digest.cnonce = @ptrCast(mem.strdup("0a4f113b").?);

    var creds = Curl_creds{
        .user = "Mufasa",
        .passwd = "Circle Of Life",
    };
    var outptr: ?[*:0]u8 = null;
    var outlen: usize = 0;
    try std.testing.expectEqual(
        CURLE_OK,
        createDigestHttpMessageRfc(null, &creds, "/dir/index.html", "GET", null, 0, &digest, &outptr, &outlen),
    );
    defer mem.free(@ptrCast(outptr));

    const resp = outptr.?[0..outlen];
    try std.testing.expect(std.mem.indexOf(u8, resp, "response=\"6629fae49393a05397450978507c4ef1\"") != null);
    try std.testing.expect(std.mem.indexOf(u8, resp, "nc=00000001, qop=auth") != null);
}

test "Digest HTTP message algorithms: MD5-sess, SHA-256, SHA-512-256, qop=auth-int, userhash=true" {
    var creds = Curl_creds{
        .user = "Mufasa",
        .passwd = "Circle Of Life",
    };

    // 1. MD5-sess + qop=auth-int + body
    {
        var digest = DigestDataRfc{};
        defer digestCleanupRfc(&digest);

        const chlg: [*:0]const u8 =
            "realm=\"testrealm@host.com\", qop=\"auth-int\", nonce=\"dcd98b7102dd2f0e8b11d0f600bfb0c093\", algorithm=MD5-sess";
        try std.testing.expectEqual(CURLE_OK, decodeDigestHttpMessageRfc(chlg, &digest));
        try std.testing.expectEqual(ALGO_MD5SESS, digest.algo);
        try std.testing.expectEqualStrings("auth-int", std.mem.span(digest.qop.?));

        digest.cnonce = @ptrCast(mem.strdup("0a4f113b").?);
        const body = "entity-body-payload";
        var outptr: ?[*:0]u8 = null;
        var outlen: usize = 0;
        try std.testing.expectEqual(
            CURLE_OK,
            createDigestHttpMessageRfc(null, &creds, "/dir/index.html", "POST", body.ptr, body.len, &digest, &outptr, &outlen),
        );
        defer mem.free(@ptrCast(outptr));

        const resp = outptr.?[0..outlen];
        try std.testing.expect(std.mem.indexOf(u8, resp, "qop=auth-int") != null);
        try std.testing.expect(std.mem.indexOf(u8, resp, "algorithm=MD5-sess") != null);
    }

    // 2. curl test2058 & test2059 SHA-256 test vectors
    {
        var digest = DigestDataRfc{};
        defer digestCleanupRfc(&digest);

        const chlg: [*:0]const u8 = "realm=\"testrealm\", algorithm=\"SHA-256\", nonce=\"1053604144\"";
        try std.testing.expectEqual(CURLE_OK, decodeDigestHttpMessageRfc(chlg, &digest));
        try std.testing.expectEqual(ALGO_SHA256, digest.algo);

        var sha256_creds = Curl_creds{
            .user = "auser",
            .passwd = "apasswd",
        };
        var outptr: ?[*:0]u8 = null;
        var outlen: usize = 0;
        try std.testing.expectEqual(
            CURLE_OK,
            createDigestHttpMessageRfc(null, &sha256_creds, "/2058", "GET", null, 0, &digest, &outptr, &outlen),
        );
        defer mem.free(@ptrCast(outptr));

        const resp = outptr.?[0..outlen];
        try std.testing.expectEqualStrings(
            "username=\"auser\", realm=\"testrealm\", nonce=\"1053604144\", uri=\"/2058\", response=\"fbed69f9f3fd304c8f1acb1a43eb32688b933c0e28055c16b926cbcec070aeed\", algorithm=SHA-256",
            resp,
        );
    }

    // 3. SHA-512-256 + userhash=true (RFC 7616 Section 3.9.2 userhash test vector)
    {
        var digest = DigestDataRfc{};
        defer digestCleanupRfc(&digest);

        const chlg: [*:0]const u8 =
            "realm=\"api@example.org\", qop=\"auth\", algorithm=SHA-512-256, nonce=\"5TsQWLVdgBdmrQ0XsxbDODV+57QdFR34I9HAbC/RVvkK\", userhash=true";
        try std.testing.expectEqual(CURLE_OK, decodeDigestHttpMessageRfc(chlg, &digest));
        try std.testing.expectEqual(ALGO_SHA512_256, digest.algo);
        try std.testing.expect(digest.isUserhash());

        var jdoe_creds = Curl_creds{
            .user = "Jäsøn Doe",
            .passwd = "Secret, or not?",
        };
        digest.cnonce = @ptrCast(mem.strdup("NTg6RKcb9boFIAS3KrFK9BGeh+iDa/sm6jUMp2wds69v").?);
        var outptr: ?[*:0]u8 = null;
        var outlen: usize = 0;
        try std.testing.expectEqual(
            CURLE_OK,
            createDigestHttpMessageRfc(null, &jdoe_creds, "/dir/index.html", "GET", null, 0, &digest, &outptr, &outlen),
        );
        defer mem.free(@ptrCast(outptr));

        const resp = outptr.?[0..outlen];
        // RFC 7616 Section 3.9.2 SHA-512-256 userhash of "Jäsøn Doe:api@example.org"
        try std.testing.expect(std.mem.indexOf(u8, resp, "username=\"793263caabb707a56211940d90411ea4a575adeccb7e360aeb624ed06ece9b0b\"") != null);
        try std.testing.expect(std.mem.indexOf(u8, resp, "algorithm=SHA-512-256, userhash=true") != null);
    }

    // 4. Stale handling & GSS mechanism OID lookup
    {
        var digest = DigestDataRfc{};
        defer digestCleanupRfc(&digest);

        const chlg1: [*:0]const u8 = "realm=\"r\", nonce=\"n1\"";
        try std.testing.expectEqual(CURLE_OK, decodeDigestHttpMessageRfc(chlg1, &digest));
        // Second challenge without stale=true should return CURLE_LOGIN_DENIED
        try std.testing.expectEqual(CURLE_LOGIN_DENIED, decodeDigestHttpMessageRfc(chlg1, &digest));
        // Challenge with stale=true succeeds and resets nc=1
        const chlg2: [*:0]const u8 = "realm=\"r\", nonce=\"n2\", stale=true";
        try std.testing.expectEqual(CURLE_OK, decodeDigestHttpMessageRfc(chlg2, &digest));
        try std.testing.expectEqualStrings("n2", std.mem.span(digest.nonce.?));
        try std.testing.expectEqual(@as(c_int, 1), digest.nc);

        try std.testing.expectEqual(@as(gss_OID, &curl_krb5_mech_oid), gssMechanismToOid("KRB5"));
        try std.testing.expectEqual(@as(gss_OID, &curl_iakerb_mech_oid), gssMechanismToOid("IAKERB"));
        try std.testing.expectEqual(@as(gss_OID, &curl_spnego_mech_oid), gssMechanismToOid("SPNEGO"));
        try std.testing.expectEqual(@as(gss_OID, &curl_ntlm_mech_oid), gssMechanismToOid("NTLM"));
        try std.testing.expectEqual(@as(gss_OID, null), gssMechanismToOid("UNKNOWN"));
        try std.testing.expectEqual(@as(gss_OID, null), gssMechanismToOid(null));
    }

    var hdr: [4]u8 = undefined;
    try std.testing.expectEqual(@as(?u16, 0x1234), socks5EncodeTokenHeader(&hdr, 1, 0x1234));
    try std.testing.expectEqualSlices(u8, &[_]u8{ 1, 1, 0x12, 0x34 }, &hdr);
    try std.testing.expectEqual(@as(?u16, 0x1234), socks5DecodeTokenLength(&hdr));
    try std.testing.expectEqual(@as(?u16, 0xffff), socks5EncodeTokenHeader(&hdr, 2, 0xffff));
    try std.testing.expectEqual(@as(?u16, null), socks5EncodeTokenHeader(&hdr, 2, 0x10000));
    try std.testing.expectEqual(@as(?u16, null), socks5DecodeTokenLength(hdr[0..3]));
    const zero_hdr = [_]u8{ 1, 1, 0, 0 };
    try std.testing.expectEqual(@as(?u16, null), socks5DecodeTokenLength(&zero_hdr));

    var sec_buf = SecBuffer{
        .cbBuffer = 4,
        .BufferType = SECBUFFER_DATA,
        .pvBuffer = mem.malloc(4),
    };
    try std.testing.expect(sec_buf.pvBuffer != null);
    @memcpy(@as([*]u8, @ptrCast(sec_buf.pvBuffer.?))[0..4], "tok!");
    scrubAndFreeSecBuffer(&sec_buf);
    try std.testing.expect(sec_buf.pvBuffer == null);
    try std.testing.expectEqual(@as(c_ulong, 0), sec_buf.cbBuffer);
}
