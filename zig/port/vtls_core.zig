const std = @import("std");
const builtin = @import("builtin");
const backend_options = @import("backend_options");
const mem = @import("mem.zig");
const primitives = @import("primitives.zig");
const containers = @import("containers.zig");
const curlx_time_net = @import("curlx_time_net.zig");

extern fn Curl_hexbyte(dest: [*]u8, val: u8) callconv(.c) void;
extern fn curlx_memdup0(src: ?[*]const u8, length: usize) callconv(.c) ?*anyopaque;
extern fn curlx_dyn_init(s: *containers.dynbuf, toobig: usize) callconv(.c) void;
extern fn curlx_dyn_free(s: *containers.dynbuf) callconv(.c) void;
extern fn curlx_dyn_addn(s: *containers.dynbuf, mem_ptr: ?*const anyopaque, len: usize) callconv(.c) c_uint;
extern fn curlx_dyn_uptr(s: *const containers.dynbuf) callconv(.c) ?[*]u8;
extern fn curlx_dyn_len(s: *const containers.dynbuf) callconv(.c) usize;
extern fn curlx_win32_fopen(filename: ?[*:0]const u8, mode: [*:0]const u8) callconv(.c) ?*anyopaque;

const CURLE_OK: c_uint = 0;
const CURLE_NOT_BUILT_IN: c_uint = 4;
const CURLE_OUT_OF_MEMORY: c_uint = 27;
const CURLE_READ_ERROR: c_uint = 26;
const CURLE_BAD_FUNCTION_ARGUMENT: c_uint = 43;
const CURLE_PEER_FAILED_VERIFICATION: c_uint = 60;
const CURLE_SSL_CACERT_BADFILE: c_uint = 77;
const CURLE_SSL_INVALIDCERTSTATUS: c_uint = 91;

const AF_INET: c_int = 2;
const AF_INET6: c_int = switch (builtin.os.tag) {
    .windows => 23,
    .macos, .ios, .tvos, .watchos, .visionos => 30,
    .freebsd, .netbsd, .openbsd, .dragonfly => 28,
    else => 10,
};

// ============================================================================
// 1. lib/vtls/hostcheck.c — Curl_cert_hostcheck
// ============================================================================

fn pmatch(hostname: [*]const u8, hostlen: usize, pattern: [*]const u8, patternlen: usize) bool {
    if (hostlen != patternlen)
        return false;
    return primitives.curl_strnequal(@ptrCast(hostname), @ptrCast(pattern), hostlen) != 0;
}

fn hostIsIpnum(hostname: [*]const u8) bool {
    var in4: [4]u8 = undefined;
    var in6: [16]u8 = undefined;
    const host_cstr: [*:0]const u8 = @ptrCast(hostname);
    if (curlx_time_net.curlx_inet_pton(AF_INET, host_cstr, &in4) > 0 or
        curlx_time_net.curlx_inet_pton(AF_INET6, host_cstr, &in6) > 0)
    {
        return true;
    }
    return false;
}

fn hostmatch(
    hostname: [*]const u8,
    in_hostlen: usize,
    pattern: [*]const u8,
    in_patternlen: usize,
) bool {
    var hostlen = in_hostlen;
    var patternlen = in_patternlen;

    if (hostlen > 0 and hostname[hostlen - 1] == '.')
        hostlen -= 1;
    if (patternlen > 0 and pattern[patternlen - 1] == '.')
        patternlen -= 1;

    if (patternlen > 2 and !(pattern[0] == '*' and pattern[1] == '.')) {
        return pmatch(hostname, hostlen, pattern, patternlen);
    } else if (hostIsIpnum(hostname) or (hostlen > 0 and hostname[0] == '.')) {
        return false;
    }

    const pattern_slice = pattern[0..patternlen];
    const first_dot = std.mem.indexOfScalar(u8, pattern_slice, '.') orelse
        return pmatch(hostname, hostlen, pattern, patternlen);
    const last_dot = std.mem.lastIndexOfScalar(u8, pattern_slice, '.') orelse unreachable;
    if (last_dot == first_dot) {
        return pmatch(hostname, hostlen, pattern, patternlen);
    }

    const host_slice = hostname[0..hostlen];
    if (std.mem.indexOfScalar(u8, host_slice, '.')) |skiphost| {
        return pmatch(
            hostname + skiphost,
            hostlen - skiphost,
            pattern + first_dot,
            patternlen - first_dot,
        );
    }
    return false;
}

pub export fn Curl_cert_hostcheck(
    match: ?[*]const u8,
    matchlen: usize,
    hostname: ?[*]const u8,
    hostlen: usize,
) callconv(.c) bool {
    const m = match orelse return false;
    const h = hostname orelse return false;
    if (matchlen > 0 and hostlen > 0)
        return hostmatch(h, hostlen, m, matchlen);
    return false;
}

// ============================================================================
// 2. lib/vtls/keylog.c — Curl_tls_keylog_*
// ============================================================================

const KEYLOG_LABEL_MAXLEN: usize = 31;
const CLIENT_RANDOM_SIZE: usize = 32;
const SECRET_MAXLEN: usize = 48;

const keylog_c = struct {
    extern "c" fn getenv(name: [*:0]const u8) ?[*:0]u8;
    extern "c" fn fopen(filename: [*:0]const u8, mode: [*:0]const u8) ?*anyopaque;
    extern "c" fn fclose(stream: *anyopaque) c_int;
    extern "c" fn setvbuf(stream: *anyopaque, buffer: ?[*]u8, mode: c_int, size: usize) c_int;
    extern "c" fn fputs(s: [*:0]const u8, stream: *anyopaque) c_int;
};

var keylog_file_fp: ?*anyopaque = null;
var keylog_file_name: ?[*:0]u8 = null;

pub export fn Curl_tls_keylog_open() callconv(.c) void {
    if (keylog_file_fp == null) {
        keylog_file_name = keylog_c.getenv("SSLKEYLOGFILE");
        if (keylog_file_name) |name| {
            const fp_opt = if (builtin.os.tag == .windows)
                curlx_win32_fopen(name, "at")
            else
                keylog_c.fopen(name, "a");

            if (fp_opt) |fp| {
                const vbuf_rc = if (builtin.os.tag == .windows)
                    keylog_c.setvbuf(fp, null, 0x0004, 0) // _IONBF on Windows CRT
                else
                    keylog_c.setvbuf(fp, null, 1, 4096); // _IOLBF on POSIX

                if (vbuf_rc != 0) {
                    _ = keylog_c.fclose(fp);
                    keylog_file_fp = null;
                } else {
                    keylog_file_fp = fp;
                }
            }
        }
    }
}

pub export fn Curl_tls_keylog_close() callconv(.c) void {
    if (keylog_file_fp) |fp| {
        _ = keylog_c.fclose(fp);
        keylog_file_fp = null;
    }
}

pub export fn Curl_tls_keylog_enabled() callconv(.c) bool {
    return keylog_file_fp != null;
}

pub export fn Curl_tls_keylog_file_name() callconv(.c) ?[*:0]const u8 {
    return keylog_file_name;
}

pub export fn Curl_tls_keylog_write_line(line: ?[*:0]const u8) callconv(.c) bool {
    const fp = keylog_file_fp orelse return false;
    const l = line orelse return false;

    var linelen = std.mem.len(l);
    var buf: [256]u8 = undefined;
    if (linelen == 0 or linelen > buf.len - 2) {
        return false;
    }

    @memcpy(buf[0..linelen], l[0..linelen]);
    if (l[linelen - 1] != '\n') {
        buf[linelen] = '\n';
        linelen += 1;
    }
    buf[linelen] = 0;

    _ = keylog_c.fputs(@ptrCast(&buf), fp);
    return true;
}

pub export fn Curl_tls_keylog_write(
    label: ?[*:0]const u8,
    client_random: ?[*]const u8,
    random_size: usize,
    secret: ?[*]const u8,
    secretlen: usize,
) callconv(.c) bool {
    if (random_size < CLIENT_RANDOM_SIZE)
        return false;
    const fp = keylog_file_fp orelse return false;
    const lbl = label orelse return false;
    const crand = client_random orelse return false;
    const sec = secret orelse return false;

    var pos = std.mem.len(lbl);
    if (pos > KEYLOG_LABEL_MAXLEN or secretlen == 0 or secretlen > SECRET_MAXLEN) {
        return false;
    }

    var line: [KEYLOG_LABEL_MAXLEN + 1 + (2 * CLIENT_RANDOM_SIZE) + 1 + (2 * SECRET_MAXLEN) + 1 + 1]u8 = undefined;
    @memcpy(line[0..pos], lbl[0..pos]);
    line[pos] = ' ';
    pos += 1;

    var i: usize = 0;
    while (i < CLIENT_RANDOM_SIZE) : (i += 1) {
        Curl_hexbyte(@ptrCast(line[pos..].ptr), crand[i]);
        pos += 2;
    }
    line[pos] = ' ';
    pos += 1;

    i = 0;
    while (i < secretlen) : (i += 1) {
        Curl_hexbyte(@ptrCast(line[pos..].ptr), sec[i]);
        pos += 2;
    }
    line[pos] = '\n';
    pos += 1;
    line[pos] = 0;

    _ = keylog_c.fputs(@ptrCast(&line), fp);
    return true;
}

// ============================================================================
// 3. lib/vtls/vtls_spack.c — Curl_ssl_session_pack / Curl_ssl_session_unpack
// ============================================================================

pub const CurlLlistNode = containers.Curl_llist_node;

const bit0_mask: c_uint = if (builtin.cpu.arch.endian() == .little)
    1
else
    (@as(c_uint, 1) << (@bitSizeOf(c_uint) - 1));

pub const CurlSslSession = extern struct {
    sdata: ?[*]u8,
    sdata_len: usize,
    valid_until: i64,
    ietf_tls_id: c_int,
    alpn: ?[*:0]u8,
    earlydata_max: usize,
    quic_tp: ?[*]u8,
    quic_tp_len: usize,
    list: CurlLlistNode,
    flags: c_uint,

    pub fn isSectrustVerified(self: *const CurlSslSession) bool {
        return (self.flags & bit0_mask) != 0;
    }

    pub fn setSectrustVerified(self: *CurlSslSession, val: bool) void {
        if (val) {
            self.flags |= bit0_mask;
        } else {
            self.flags &= ~bit0_mask;
        }
    }
};

const CURL_SPACK_VERSION: u8 = 0x01;
const CURL_SPACK_IETF_ID: u8 = 0x02;
const CURL_SPACK_VALID_UNTIL: u8 = 0x03;
const CURL_SPACK_TICKET: u8 = 0x04;
const CURL_SPACK_ALPN: u8 = 0x05;
const CURL_SPACK_EARLYDATA: u8 = 0x06;
const CURL_SPACK_QUICTP: u8 = 0x07;
const CURL_SPACK_SECTRUST: u8 = 0x08;

fn spack_enc8(buf: *containers.dynbuf, b: u8) c_uint {
    var byte = b;
    return curlx_dyn_addn(buf, &byte, 1);
}

fn spack_dec8(val: *u8, src: *[*]const u8, end: [*]const u8) c_uint {
    if (@intFromPtr(end) - @intFromPtr(src.*) < 1)
        return CURLE_READ_ERROR;
    val.* = src.*[0];
    src.* += 1;
    return CURLE_OK;
}

fn spack_enc16(buf: *containers.dynbuf, val: u16) c_uint {
    var nval: [2]u8 = .{
        @truncate(val >> 8),
        @truncate(val),
    };
    return curlx_dyn_addn(buf, &nval, nval.len);
}

fn spack_dec16(val: *u16, src: *[*]const u8, end: [*]const u8) c_uint {
    if (@intFromPtr(end) - @intFromPtr(src.*) < 2)
        return CURLE_READ_ERROR;
    val.* = (@as(u16, src.*[0]) << 8) | @as(u16, src.*[1]);
    src.* += 2;
    return CURLE_OK;
}

fn spack_enc32(buf: *containers.dynbuf, val: u32) c_uint {
    var nval: [4]u8 = .{
        @truncate(val >> 24),
        @truncate(val >> 16),
        @truncate(val >> 8),
        @truncate(val),
    };
    return curlx_dyn_addn(buf, &nval, nval.len);
}

fn spack_dec32(val: *u32, src: *[*]const u8, end: [*]const u8) c_uint {
    if (@intFromPtr(end) - @intFromPtr(src.*) < 4)
        return CURLE_READ_ERROR;
    val.* = (@as(u32, src.*[0]) << 24) |
        (@as(u32, src.*[1]) << 16) |
        (@as(u32, src.*[2]) << 8) |
        @as(u32, src.*[3]);
    src.* += 4;
    return CURLE_OK;
}

fn spack_enc64(buf: *containers.dynbuf, val: u64) c_uint {
    var nval: [8]u8 = .{
        @truncate(val >> 56),
        @truncate(val >> 48),
        @truncate(val >> 40),
        @truncate(val >> 32),
        @truncate(val >> 24),
        @truncate(val >> 16),
        @truncate(val >> 8),
        @truncate(val),
    };
    return curlx_dyn_addn(buf, &nval, nval.len);
}

fn spack_dec64(val: *u64, src: *[*]const u8, end: [*]const u8) c_uint {
    if (@intFromPtr(end) - @intFromPtr(src.*) < 8)
        return CURLE_READ_ERROR;
    val.* = (@as(u64, src.*[0]) << 56) |
        (@as(u64, src.*[1]) << 48) |
        (@as(u64, src.*[2]) << 40) |
        (@as(u64, src.*[3]) << 32) |
        (@as(u64, src.*[4]) << 24) |
        (@as(u64, src.*[5]) << 16) |
        (@as(u64, src.*[6]) << 8) |
        @as(u64, src.*[7]);
    src.* += 8;
    return CURLE_OK;
}

fn spack_encstr16(buf: *containers.dynbuf, s: [*:0]const u8) c_uint {
    const slen = std.mem.len(s);
    if (slen > std.math.maxInt(u16))
        return CURLE_BAD_FUNCTION_ARGUMENT;
    var result = spack_enc16(buf, @intCast(slen));
    if (result == CURLE_OK) {
        result = curlx_dyn_addn(buf, s, slen);
    }
    return result;
}

fn spack_decstr16(val: *?[*:0]u8, src: *[*]const u8, end: [*]const u8) c_uint {
    var slen: u16 = 0;
    val.* = null;
    const result = spack_dec16(&slen, src, end);
    if (result != CURLE_OK)
        return result;
    if (@intFromPtr(end) - @intFromPtr(src.*) < slen)
        return CURLE_READ_ERROR;
    const dup = curlx_memdup0(src.*, slen);
    val.* = if (dup) |p| @ptrCast(p) else null;
    src.* += slen;
    return if (val.* != null) CURLE_OK else CURLE_OUT_OF_MEMORY;
}

fn spack_encdata16(buf: *containers.dynbuf, data: [*]const u8, data_len: usize) c_uint {
    if (data_len > std.math.maxInt(u16))
        return CURLE_BAD_FUNCTION_ARGUMENT;
    var result = spack_enc16(buf, @intCast(data_len));
    if (result == CURLE_OK) {
        result = curlx_dyn_addn(buf, data, data_len);
    }
    return result;
}

fn spack_decdata16(val: *?[*]u8, val_len: *usize, src: *[*]const u8, end: [*]const u8) c_uint {
    var data_len: u16 = 0;
    val.* = null;
    const result = spack_dec16(&data_len, src, end);
    if (result != CURLE_OK)
        return result;
    if (@intFromPtr(end) - @intFromPtr(src.*) < data_len)
        return CURLE_READ_ERROR;
    const dup = curlx_memdup0(src.*, data_len);
    val.* = if (dup) |p| @ptrCast(p) else null;
    val_len.* = data_len;
    src.* += data_len;
    return if (val.* != null) CURLE_OK else CURLE_OUT_OF_MEMORY;
}

pub export fn Curl_ssl_session_pack(
    data: ?*anyopaque,
    s: *CurlSslSession,
    buf: *containers.dynbuf,
) callconv(.c) c_uint {
    _ = data;
    if (s.valid_until < 0)
        return CURLE_BAD_FUNCTION_ARGUMENT;
    const sdata = s.sdata orelse return CURLE_BAD_FUNCTION_ARGUMENT;

    var result = spack_enc8(buf, CURL_SPACK_VERSION);
    if (result == CURLE_OK)
        result = spack_enc8(buf, CURL_SPACK_TICKET);
    if (result == CURLE_OK)
        result = spack_encdata16(buf, sdata, s.sdata_len);
    if (result == CURLE_OK)
        result = spack_enc8(buf, CURL_SPACK_IETF_ID);
    if (result == CURLE_OK)
        result = spack_enc16(buf, @bitCast(@as(i16, @truncate(s.ietf_tls_id))));
    if (result == CURLE_OK)
        result = spack_enc8(buf, CURL_SPACK_VALID_UNTIL);
    if (result == CURLE_OK)
        result = spack_enc64(buf, @intCast(s.valid_until));
    if (result == CURLE_OK) {
        if (s.alpn) |alpn| {
            result = spack_enc8(buf, CURL_SPACK_ALPN);
            if (result == CURLE_OK)
                result = spack_encstr16(buf, alpn);
        }
    }
    if (result == CURLE_OK and s.earlydata_max != 0) {
        if (s.earlydata_max > std.math.maxInt(u32))
            result = CURLE_BAD_FUNCTION_ARGUMENT;
        if (result == CURLE_OK)
            result = spack_enc8(buf, CURL_SPACK_EARLYDATA);
        if (result == CURLE_OK)
            result = spack_enc32(buf, @intCast(s.earlydata_max));
    }
    if (result == CURLE_OK and s.isSectrustVerified()) {
        result = spack_enc8(buf, CURL_SPACK_SECTRUST);
    }
    if (result == CURLE_OK and s.quic_tp != null and s.quic_tp_len != 0) {
        result = spack_enc8(buf, CURL_SPACK_QUICTP);
        if (result == CURLE_OK)
            result = spack_encdata16(buf, s.quic_tp.?, s.quic_tp_len);
    }

    return result;
}

fn destroyUnpackedSession(s: ?*CurlSslSession) void {
    const sess = s orelse return;
    if (sess.sdata) |p| mem.free(p);
    if (sess.quic_tp) |p| mem.free(p);
    if (sess.alpn) |p| mem.free(@ptrCast(p));
    mem.free(sess);
}

pub export fn Curl_ssl_session_unpack(
    data: ?*anyopaque,
    bufv: ?*const anyopaque,
    buflen: usize,
    ps: *?*CurlSslSession,
) callconv(.c) c_uint {
    _ = data;
    ps.* = null;
    const raw = bufv orelse return CURLE_BAD_FUNCTION_ARGUMENT;
    var buf: [*]const u8 = @ptrCast(raw);
    const end: [*]const u8 = buf + buflen;

    var val8: u8 = 0;
    var pval8: ?[*]u8 = null;
    var val16: u16 = 0;
    var val32: u32 = 0;
    var val64: u64 = 0;
    var dlen: usize = 0;

    var result = spack_dec8(&val8, &buf, end);
    if (result != CURLE_OK)
        return result;
    if (val8 != CURL_SPACK_VERSION)
        return CURLE_READ_ERROR;

    const raw_s = mem.calloc(1, @sizeOf(CurlSslSession)) orelse return CURLE_OUT_OF_MEMORY;
    const s: *CurlSslSession = @ptrCast(@alignCast(raw_s));

    while (@intFromPtr(buf) < @intFromPtr(end)) {
        result = spack_dec8(&val8, &buf, end);
        if (result != CURLE_OK)
            break;

        switch (val8) {
            CURL_SPACK_ALPN => {
                if (s.alpn) |p| mem.free(@ptrCast(p));
                result = spack_decstr16(&s.alpn, &buf, end);
                if (result != CURLE_OK)
                    break;
            },
            CURL_SPACK_EARLYDATA => {
                result = spack_dec32(&val32, &buf, end);
                if (result != CURLE_OK)
                    break;
                s.earlydata_max = val32;
            },
            CURL_SPACK_IETF_ID => {
                result = spack_dec16(&val16, &buf, end);
                if (result != CURLE_OK)
                    break;
                s.ietf_tls_id = val16;
            },
            CURL_SPACK_QUICTP => {
                result = spack_decdata16(&pval8, &dlen, &buf, end);
                if (result != CURLE_OK)
                    break;
                if (s.quic_tp) |p| mem.free(p);
                s.quic_tp = pval8;
                s.quic_tp_len = dlen;
            },
            CURL_SPACK_TICKET => {
                result = spack_decdata16(&pval8, &dlen, &buf, end);
                if (result != CURLE_OK)
                    break;
                if (s.sdata) |p| mem.free(p);
                s.sdata = pval8;
                s.sdata_len = dlen;
            },
            CURL_SPACK_VALID_UNTIL => {
                result = spack_dec64(&val64, &buf, end);
                if (result != CURLE_OK)
                    break;
                s.valid_until = @bitCast(val64);
            },
            CURL_SPACK_SECTRUST => {
                s.setSectrustVerified(true);
            },
            else => {
                result = CURLE_READ_ERROR;
                break;
            },
        }
    }

    if (result != CURLE_OK) {
        destroyUnpackedSession(s);
    } else {
        ps.* = s;
    }
    return result;
}

// ============================================================================
// 4. lib/vtls/cipher_suite.c — IANA/OpenSSL TLS cipher suite lookup table
// ============================================================================

const CsTxtIdx = enum(u8) {
    none = 0,
    TLS,
    WITH,
    @"128",
    @"256",
    @"3DES",
    @"8",
    AES,
    AES128,
    AES256,
    CBC,
    CBC3,
    CCM,
    CCM8,
    CHACHA20,
    DES,
    DHE,
    ECDH,
    ECDHE,
    ECDSA,
    EDE,
    GCM,
    MD5,
    NULL,
    POLY1305,
    PSK,
    RSA,
    SHA,
    SHA256,
    SHA384,
    ARIA,
    ARIA128,
    ARIA256,
    CAMELLIA,
    CAMELLIA128,
    CAMELLIA256,
};

const cs_parts = [_][]const u8{
    "",
    "TLS",
    "WITH",
    "128",
    "256",
    "3DES",
    "8",
    "AES",
    "AES128",
    "AES256",
    "CBC",
    "CBC3",
    "CCM",
    "CCM8",
    "CHACHA20",
    "DES",
    "DHE",
    "ECDH",
    "ECDHE",
    "ECDSA",
    "EDE",
    "GCM",
    "MD5",
    "NULL",
    "POLY1305",
    "PSK",
    "RSA",
    "SHA",
    "SHA256",
    "SHA384",
    "ARIA",
    "ARIA128",
    "ARIA256",
    "CAMELLIA",
    "CAMELLIA128",
    "CAMELLIA256",
};

const CsEntry = struct {
    id: u16,
    zip: [6]u8,
};

fn csZipIdx(a: CsTxtIdx, b: CsTxtIdx, c: CsTxtIdx, d: CsTxtIdx, e: CsTxtIdx, f: CsTxtIdx, g: CsTxtIdx, h: CsTxtIdx) [6]u8 {
    const ia: u8 = @backingInt(a);
    const ib: u8 = @backingInt(b);
    const ic: u8 = @backingInt(c);
    const id: u8 = @backingInt(d);
    const ie: u8 = @backingInt(e);
    const iff: u8 = @backingInt(f);
    const ig: u8 = @backingInt(g);
    const ih: u8 = @backingInt(h);
    return .{
        ((ia << 2) & 0xFF) | ((ib & 0x3F) >> 4),
        ((ib << 4) & 0xFF) | ((ic & 0x3F) >> 2),
        ((ic << 6) & 0xFF) | (id & 0x3F),
        ((ie << 2) & 0xFF) | ((iff & 0x3F) >> 4),
        ((iff << 4) & 0xFF) | ((ig & 0x3F) >> 2),
        ((ig << 6) & 0xFF) | (ih & 0x3F),
    };
}

fn csEntry(id: u16, a: CsTxtIdx, b: CsTxtIdx, c: CsTxtIdx, d: CsTxtIdx, e: CsTxtIdx, f: CsTxtIdx, g: CsTxtIdx, h: CsTxtIdx) CsEntry {
    return .{
        .id = id,
        .zip = csZipIdx(a, b, c, d, e, f, g, h),
    };
}

const cs_list = [_]CsEntry{
    // TLS 1.3 ciphers
    csEntry(0x1301, .TLS, .AES, .@"128", .GCM, .SHA256, .none, .none, .none),
    csEntry(0x1302, .TLS, .AES, .@"256", .GCM, .SHA384, .none, .none, .none),
    csEntry(0x1303, .TLS, .CHACHA20, .POLY1305, .SHA256, .none, .none, .none, .none),
    csEntry(0x1304, .TLS, .AES, .@"128", .CCM, .SHA256, .none, .none, .none),
    csEntry(0x1305, .TLS, .AES, .@"128", .CCM, .@"8", .SHA256, .none, .none),
    // TLS 1.2 ciphers
    csEntry(0xC02B, .TLS, .ECDHE, .ECDSA, .WITH, .AES, .@"128", .GCM, .SHA256),
    csEntry(0xC02B, .ECDHE, .ECDSA, .AES128, .GCM, .SHA256, .none, .none, .none),
    csEntry(0xC02C, .TLS, .ECDHE, .ECDSA, .WITH, .AES, .@"256", .GCM, .SHA384),
    csEntry(0xC02C, .ECDHE, .ECDSA, .AES256, .GCM, .SHA384, .none, .none, .none),
    csEntry(0xC02F, .TLS, .ECDHE, .RSA, .WITH, .AES, .@"128", .GCM, .SHA256),
    csEntry(0xC02F, .ECDHE, .RSA, .AES128, .GCM, .SHA256, .none, .none, .none),
    csEntry(0xC030, .TLS, .ECDHE, .RSA, .WITH, .AES, .@"256", .GCM, .SHA384),
    csEntry(0xC030, .ECDHE, .RSA, .AES256, .GCM, .SHA384, .none, .none, .none),
    csEntry(0xCCA8, .TLS, .ECDHE, .RSA, .WITH, .CHACHA20, .POLY1305, .SHA256, .none),
    csEntry(0xCCA8, .ECDHE, .RSA, .CHACHA20, .POLY1305, .none, .none, .none, .none),
    csEntry(0xCCA9, .TLS, .ECDHE, .ECDSA, .WITH, .CHACHA20, .POLY1305, .SHA256, .none),
    csEntry(0xCCA9, .ECDHE, .ECDSA, .CHACHA20, .POLY1305, .none, .none, .none, .none),
    csEntry(0x002F, .TLS, .RSA, .WITH, .AES, .@"128", .CBC, .SHA, .none),
    csEntry(0x002F, .AES128, .SHA, .none, .none, .none, .none, .none, .none),
    csEntry(0x0035, .TLS, .RSA, .WITH, .AES, .@"256", .CBC, .SHA, .none),
    csEntry(0x0035, .AES256, .SHA, .none, .none, .none, .none, .none, .none),
    csEntry(0x003C, .TLS, .RSA, .WITH, .AES, .@"128", .CBC, .SHA256, .none),
    csEntry(0x003C, .AES128, .SHA256, .none, .none, .none, .none, .none, .none),
    csEntry(0x003D, .TLS, .RSA, .WITH, .AES, .@"256", .CBC, .SHA256, .none),
    csEntry(0x003D, .AES256, .SHA256, .none, .none, .none, .none, .none, .none),
    csEntry(0x009C, .TLS, .RSA, .WITH, .AES, .@"128", .GCM, .SHA256, .none),
    csEntry(0x009C, .AES128, .GCM, .SHA256, .none, .none, .none, .none, .none),
    csEntry(0x009D, .TLS, .RSA, .WITH, .AES, .@"256", .GCM, .SHA384, .none),
    csEntry(0x009D, .AES256, .GCM, .SHA384, .none, .none, .none, .none, .none),
    csEntry(0xC004, .TLS, .ECDH, .ECDSA, .WITH, .AES, .@"128", .CBC, .SHA),
    csEntry(0xC004, .ECDH, .ECDSA, .AES128, .SHA, .none, .none, .none, .none),
    csEntry(0xC005, .TLS, .ECDH, .ECDSA, .WITH, .AES, .@"256", .CBC, .SHA),
    csEntry(0xC005, .ECDH, .ECDSA, .AES256, .SHA, .none, .none, .none, .none),
    csEntry(0xC009, .TLS, .ECDHE, .ECDSA, .WITH, .AES, .@"128", .CBC, .SHA),
    csEntry(0xC009, .ECDHE, .ECDSA, .AES128, .SHA, .none, .none, .none, .none),
    csEntry(0xC00A, .TLS, .ECDHE, .ECDSA, .WITH, .AES, .@"256", .CBC, .SHA),
    csEntry(0xC00A, .ECDHE, .ECDSA, .AES256, .SHA, .none, .none, .none, .none),
    csEntry(0xC00E, .TLS, .ECDH, .RSA, .WITH, .AES, .@"128", .CBC, .SHA),
    csEntry(0xC00E, .ECDH, .RSA, .AES128, .SHA, .none, .none, .none, .none),
    csEntry(0xC00F, .TLS, .ECDH, .RSA, .WITH, .AES, .@"256", .CBC, .SHA),
    csEntry(0xC00F, .ECDH, .RSA, .AES256, .SHA, .none, .none, .none, .none),
    csEntry(0xC013, .TLS, .ECDHE, .RSA, .WITH, .AES, .@"128", .CBC, .SHA),
    csEntry(0xC013, .ECDHE, .RSA, .AES128, .SHA, .none, .none, .none, .none),
    csEntry(0xC014, .TLS, .ECDHE, .RSA, .WITH, .AES, .@"256", .CBC, .SHA),
    csEntry(0xC014, .ECDHE, .RSA, .AES256, .SHA, .none, .none, .none, .none),
    csEntry(0xC023, .TLS, .ECDHE, .ECDSA, .WITH, .AES, .@"128", .CBC, .SHA256),
    csEntry(0xC023, .ECDHE, .ECDSA, .AES128, .SHA256, .none, .none, .none, .none),
    csEntry(0xC024, .TLS, .ECDHE, .ECDSA, .WITH, .AES, .@"256", .CBC, .SHA384),
    csEntry(0xC024, .ECDHE, .ECDSA, .AES256, .SHA384, .none, .none, .none, .none),
    csEntry(0xC025, .TLS, .ECDH, .ECDSA, .WITH, .AES, .@"128", .CBC, .SHA256),
    csEntry(0xC025, .ECDH, .ECDSA, .AES128, .SHA256, .none, .none, .none, .none),
    csEntry(0xC026, .TLS, .ECDH, .ECDSA, .WITH, .AES, .@"256", .CBC, .SHA384),
    csEntry(0xC026, .ECDH, .ECDSA, .AES256, .SHA384, .none, .none, .none, .none),
    csEntry(0xC027, .TLS, .ECDHE, .RSA, .WITH, .AES, .@"128", .CBC, .SHA256),
    csEntry(0xC027, .ECDHE, .RSA, .AES128, .SHA256, .none, .none, .none, .none),
    csEntry(0xC028, .TLS, .ECDHE, .RSA, .WITH, .AES, .@"256", .CBC, .SHA384),
    csEntry(0xC028, .ECDHE, .RSA, .AES256, .SHA384, .none, .none, .none, .none),
    csEntry(0xC029, .TLS, .ECDH, .RSA, .WITH, .AES, .@"128", .CBC, .SHA256),
    csEntry(0xC029, .ECDH, .RSA, .AES128, .SHA256, .none, .none, .none, .none),
    csEntry(0xC02A, .TLS, .ECDH, .RSA, .WITH, .AES, .@"256", .CBC, .SHA384),
    csEntry(0xC02A, .ECDH, .RSA, .AES256, .SHA384, .none, .none, .none, .none),
    csEntry(0xC02D, .TLS, .ECDH, .ECDSA, .WITH, .AES, .@"128", .GCM, .SHA256),
    csEntry(0xC02D, .ECDH, .ECDSA, .AES128, .GCM, .SHA256, .none, .none, .none),
    csEntry(0xC02E, .TLS, .ECDH, .ECDSA, .WITH, .AES, .@"256", .GCM, .SHA384),
    csEntry(0xC02E, .ECDH, .ECDSA, .AES256, .GCM, .SHA384, .none, .none, .none),
    csEntry(0xC031, .TLS, .ECDH, .RSA, .WITH, .AES, .@"128", .GCM, .SHA256),
    csEntry(0xC031, .ECDH, .RSA, .AES128, .GCM, .SHA256, .none, .none, .none),
    csEntry(0xC032, .TLS, .ECDH, .RSA, .WITH, .AES, .@"256", .GCM, .SHA384),
    csEntry(0xC032, .ECDH, .RSA, .AES256, .GCM, .SHA384, .none, .none, .none),
    csEntry(0x0001, .TLS, .RSA, .WITH, .NULL, .MD5, .none, .none, .none),
    csEntry(0x0001, .NULL, .MD5, .none, .none, .none, .none, .none, .none),
    csEntry(0x0002, .TLS, .RSA, .WITH, .NULL, .SHA, .none, .none, .none),
    csEntry(0x0002, .NULL, .SHA, .none, .none, .none, .none, .none, .none),
    csEntry(0x002C, .TLS, .PSK, .WITH, .NULL, .SHA, .none, .none, .none),
    csEntry(0x002C, .PSK, .NULL, .SHA, .none, .none, .none, .none, .none),
    csEntry(0x002D, .TLS, .DHE, .PSK, .WITH, .NULL, .SHA, .none, .none),
    csEntry(0x002D, .DHE, .PSK, .NULL, .SHA, .none, .none, .none, .none),
    csEntry(0x002E, .TLS, .RSA, .PSK, .WITH, .NULL, .SHA, .none, .none),
    csEntry(0x002E, .RSA, .PSK, .NULL, .SHA, .none, .none, .none, .none),
    csEntry(0x0033, .TLS, .DHE, .RSA, .WITH, .AES, .@"128", .CBC, .SHA),
    csEntry(0x0033, .DHE, .RSA, .AES128, .SHA, .none, .none, .none, .none),
    csEntry(0x0039, .TLS, .DHE, .RSA, .WITH, .AES, .@"256", .CBC, .SHA),
    csEntry(0x0039, .DHE, .RSA, .AES256, .SHA, .none, .none, .none, .none),
    csEntry(0x003B, .TLS, .RSA, .WITH, .NULL, .SHA256, .none, .none, .none),
    csEntry(0x003B, .NULL, .SHA256, .none, .none, .none, .none, .none, .none),
    csEntry(0x0067, .TLS, .DHE, .RSA, .WITH, .AES, .@"128", .CBC, .SHA256),
    csEntry(0x0067, .DHE, .RSA, .AES128, .SHA256, .none, .none, .none, .none),
    csEntry(0x006B, .TLS, .DHE, .RSA, .WITH, .AES, .@"256", .CBC, .SHA256),
    csEntry(0x006B, .DHE, .RSA, .AES256, .SHA256, .none, .none, .none, .none),
    csEntry(0x008C, .TLS, .PSK, .WITH, .AES, .@"128", .CBC, .SHA, .none),
    csEntry(0x008C, .PSK, .AES128, .CBC, .SHA, .none, .none, .none, .none),
    csEntry(0x008D, .TLS, .PSK, .WITH, .AES, .@"256", .CBC, .SHA, .none),
    csEntry(0x008D, .PSK, .AES256, .CBC, .SHA, .none, .none, .none, .none),
    csEntry(0x0090, .TLS, .DHE, .PSK, .WITH, .AES, .@"128", .CBC, .SHA),
    csEntry(0x0090, .DHE, .PSK, .AES128, .CBC, .SHA, .none, .none, .none),
    csEntry(0x0091, .TLS, .DHE, .PSK, .WITH, .AES, .@"256", .CBC, .SHA),
    csEntry(0x0091, .DHE, .PSK, .AES256, .CBC, .SHA, .none, .none, .none),
    csEntry(0x0094, .TLS, .RSA, .PSK, .WITH, .AES, .@"128", .CBC, .SHA),
    csEntry(0x0094, .RSA, .PSK, .AES128, .CBC, .SHA, .none, .none, .none),
    csEntry(0x0095, .TLS, .RSA, .PSK, .WITH, .AES, .@"256", .CBC, .SHA),
    csEntry(0x0095, .RSA, .PSK, .AES256, .CBC, .SHA, .none, .none, .none),
    csEntry(0x009E, .TLS, .DHE, .RSA, .WITH, .AES, .@"128", .GCM, .SHA256),
    csEntry(0x009E, .DHE, .RSA, .AES128, .GCM, .SHA256, .none, .none, .none),
    csEntry(0x009F, .TLS, .DHE, .RSA, .WITH, .AES, .@"256", .GCM, .SHA384),
    csEntry(0x009F, .DHE, .RSA, .AES256, .GCM, .SHA384, .none, .none, .none),
    csEntry(0x00A8, .TLS, .PSK, .WITH, .AES, .@"128", .GCM, .SHA256, .none),
    csEntry(0x00A8, .PSK, .AES128, .GCM, .SHA256, .none, .none, .none, .none),
    csEntry(0x00A9, .TLS, .PSK, .WITH, .AES, .@"256", .GCM, .SHA384, .none),
    csEntry(0x00A9, .PSK, .AES256, .GCM, .SHA384, .none, .none, .none, .none),
    csEntry(0x00AA, .TLS, .DHE, .PSK, .WITH, .AES, .@"128", .GCM, .SHA256),
    csEntry(0x00AA, .DHE, .PSK, .AES128, .GCM, .SHA256, .none, .none, .none),
    csEntry(0x00AB, .TLS, .DHE, .PSK, .WITH, .AES, .@"256", .GCM, .SHA384),
    csEntry(0x00AB, .DHE, .PSK, .AES256, .GCM, .SHA384, .none, .none, .none),
    csEntry(0x00AC, .TLS, .RSA, .PSK, .WITH, .AES, .@"128", .GCM, .SHA256),
    csEntry(0x00AC, .RSA, .PSK, .AES128, .GCM, .SHA256, .none, .none, .none),
    csEntry(0x00AD, .TLS, .RSA, .PSK, .WITH, .AES, .@"256", .GCM, .SHA384),
    csEntry(0x00AD, .RSA, .PSK, .AES256, .GCM, .SHA384, .none, .none, .none),
    csEntry(0x00AE, .TLS, .PSK, .WITH, .AES, .@"128", .CBC, .SHA256, .none),
    csEntry(0x00AE, .PSK, .AES128, .CBC, .SHA256, .none, .none, .none, .none),
    csEntry(0x00AF, .TLS, .PSK, .WITH, .AES, .@"256", .CBC, .SHA384, .none),
    csEntry(0x00AF, .PSK, .AES256, .CBC, .SHA384, .none, .none, .none, .none),
    csEntry(0x00B0, .TLS, .PSK, .WITH, .NULL, .SHA256, .none, .none, .none),
    csEntry(0x00B0, .PSK, .NULL, .SHA256, .none, .none, .none, .none, .none),
    csEntry(0x00B1, .TLS, .PSK, .WITH, .NULL, .SHA384, .none, .none, .none),
    csEntry(0x00B1, .PSK, .NULL, .SHA384, .none, .none, .none, .none, .none),
    csEntry(0x00B2, .TLS, .DHE, .PSK, .WITH, .AES, .@"128", .CBC, .SHA256),
    csEntry(0x00B2, .DHE, .PSK, .AES128, .CBC, .SHA256, .none, .none, .none),
    csEntry(0x00B3, .TLS, .DHE, .PSK, .WITH, .AES, .@"256", .CBC, .SHA384),
    csEntry(0x00B3, .DHE, .PSK, .AES256, .CBC, .SHA384, .none, .none, .none),
    csEntry(0x00B4, .TLS, .DHE, .PSK, .WITH, .NULL, .SHA256, .none, .none),
    csEntry(0x00B4, .DHE, .PSK, .NULL, .SHA256, .none, .none, .none, .none),
    csEntry(0x00B5, .TLS, .DHE, .PSK, .WITH, .NULL, .SHA384, .none, .none),
    csEntry(0x00B5, .DHE, .PSK, .NULL, .SHA384, .none, .none, .none, .none),
    csEntry(0x00B6, .TLS, .RSA, .PSK, .WITH, .AES, .@"128", .CBC, .SHA256),
    csEntry(0x00B6, .RSA, .PSK, .AES128, .CBC, .SHA256, .none, .none, .none),
    csEntry(0x00B7, .TLS, .RSA, .PSK, .WITH, .AES, .@"256", .CBC, .SHA384),
    csEntry(0x00B7, .RSA, .PSK, .AES256, .CBC, .SHA384, .none, .none, .none),
    csEntry(0x00B8, .TLS, .RSA, .PSK, .WITH, .NULL, .SHA256, .none, .none),
    csEntry(0x00B8, .RSA, .PSK, .NULL, .SHA256, .none, .none, .none, .none),
    csEntry(0x00B9, .TLS, .RSA, .PSK, .WITH, .NULL, .SHA384, .none, .none),
    csEntry(0x00B9, .RSA, .PSK, .NULL, .SHA384, .none, .none, .none, .none),
    csEntry(0xC001, .TLS, .ECDH, .ECDSA, .WITH, .NULL, .SHA, .none, .none),
    csEntry(0xC001, .ECDH, .ECDSA, .NULL, .SHA, .none, .none, .none, .none),
    csEntry(0xC006, .TLS, .ECDHE, .ECDSA, .WITH, .NULL, .SHA, .none, .none),
    csEntry(0xC006, .ECDHE, .ECDSA, .NULL, .SHA, .none, .none, .none, .none),
    csEntry(0xC00B, .TLS, .ECDH, .RSA, .WITH, .NULL, .SHA, .none, .none),
    csEntry(0xC00B, .ECDH, .RSA, .NULL, .SHA, .none, .none, .none, .none),
    csEntry(0xC010, .TLS, .ECDHE, .RSA, .WITH, .NULL, .SHA, .none, .none),
    csEntry(0xC010, .ECDHE, .RSA, .NULL, .SHA, .none, .none, .none, .none),
    csEntry(0xC035, .TLS, .ECDHE, .PSK, .WITH, .AES, .@"128", .CBC, .SHA),
    csEntry(0xC035, .ECDHE, .PSK, .AES128, .CBC, .SHA, .none, .none, .none),
    csEntry(0xC036, .TLS, .ECDHE, .PSK, .WITH, .AES, .@"256", .CBC, .SHA),
    csEntry(0xC036, .ECDHE, .PSK, .AES256, .CBC, .SHA, .none, .none, .none),
    csEntry(0xCCAB, .TLS, .PSK, .WITH, .CHACHA20, .POLY1305, .SHA256, .none, .none),
    csEntry(0xCCAB, .PSK, .CHACHA20, .POLY1305, .none, .none, .none, .none, .none),
    csEntry(0xC09C, .TLS, .RSA, .WITH, .AES, .@"128", .CCM, .none, .none),
    csEntry(0xC09C, .AES128, .CCM, .none, .none, .none, .none, .none, .none),
    csEntry(0xC09D, .TLS, .RSA, .WITH, .AES, .@"256", .CCM, .none, .none),
    csEntry(0xC09D, .AES256, .CCM, .none, .none, .none, .none, .none, .none),
    csEntry(0xC0A0, .TLS, .RSA, .WITH, .AES, .@"128", .CCM, .@"8", .none),
    csEntry(0xC0A0, .AES128, .CCM8, .none, .none, .none, .none, .none, .none),
    csEntry(0xC0A1, .TLS, .RSA, .WITH, .AES, .@"256", .CCM, .@"8", .none),
    csEntry(0xC0A1, .AES256, .CCM8, .none, .none, .none, .none, .none, .none),
    csEntry(0xC0AC, .TLS, .ECDHE, .ECDSA, .WITH, .AES, .@"128", .CCM, .none),
    csEntry(0xC0AC, .ECDHE, .ECDSA, .AES128, .CCM, .none, .none, .none, .none),
    csEntry(0xC0AD, .TLS, .ECDHE, .ECDSA, .WITH, .AES, .@"256", .CCM, .none),
    csEntry(0xC0AD, .ECDHE, .ECDSA, .AES256, .CCM, .none, .none, .none, .none),
    csEntry(0xC0AE, .TLS, .ECDHE, .ECDSA, .WITH, .AES, .@"128", .CCM, .@"8"),
    csEntry(0xC0AE, .ECDHE, .ECDSA, .AES128, .CCM8, .none, .none, .none, .none),
    csEntry(0xC0AF, .TLS, .ECDHE, .ECDSA, .WITH, .AES, .@"256", .CCM, .@"8"),
    csEntry(0xC0AF, .ECDHE, .ECDSA, .AES256, .CCM8, .none, .none, .none, .none),
    csEntry(0x0041, .TLS, .RSA, .WITH, .CAMELLIA, .@"128", .CBC, .SHA, .none),
    csEntry(0x0041, .CAMELLIA128, .SHA, .none, .none, .none, .none, .none, .none),
    csEntry(0x0045, .TLS, .DHE, .RSA, .WITH, .CAMELLIA, .@"128", .CBC, .SHA),
    csEntry(0x0045, .DHE, .RSA, .CAMELLIA128, .SHA, .none, .none, .none, .none),
    csEntry(0x0084, .TLS, .RSA, .WITH, .CAMELLIA, .@"256", .CBC, .SHA, .none),
    csEntry(0x0084, .CAMELLIA256, .SHA, .none, .none, .none, .none, .none, .none),
    csEntry(0x0088, .TLS, .DHE, .RSA, .WITH, .CAMELLIA, .@"256", .CBC, .SHA),
    csEntry(0x0088, .DHE, .RSA, .CAMELLIA256, .SHA, .none, .none, .none, .none),
    csEntry(0x00BA, .TLS, .RSA, .WITH, .CAMELLIA, .@"128", .CBC, .SHA256, .none),
    csEntry(0x00BA, .CAMELLIA128, .SHA256, .none, .none, .none, .none, .none, .none),
    csEntry(0x00BE, .TLS, .DHE, .RSA, .WITH, .CAMELLIA, .@"128", .CBC, .SHA256),
    csEntry(0x00BE, .DHE, .RSA, .CAMELLIA128, .SHA256, .none, .none, .none, .none),
    csEntry(0x00C0, .TLS, .RSA, .WITH, .CAMELLIA, .@"256", .CBC, .SHA256, .none),
    csEntry(0x00C0, .CAMELLIA256, .SHA256, .none, .none, .none, .none, .none, .none),
    csEntry(0x00C4, .TLS, .DHE, .RSA, .WITH, .CAMELLIA, .@"256", .CBC, .SHA256),
    csEntry(0x00C4, .DHE, .RSA, .CAMELLIA256, .SHA256, .none, .none, .none, .none),
    csEntry(0xC037, .TLS, .ECDHE, .PSK, .WITH, .AES, .@"128", .CBC, .SHA256),
    csEntry(0xC037, .ECDHE, .PSK, .AES128, .CBC, .SHA256, .none, .none, .none),
    csEntry(0xC038, .TLS, .ECDHE, .PSK, .WITH, .AES, .@"256", .CBC, .SHA384),
    csEntry(0xC038, .ECDHE, .PSK, .AES256, .CBC, .SHA384, .none, .none, .none),
    csEntry(0xC039, .TLS, .ECDHE, .PSK, .WITH, .NULL, .SHA, .none, .none),
    csEntry(0xC039, .ECDHE, .PSK, .NULL, .SHA, .none, .none, .none, .none),
    csEntry(0xC03A, .TLS, .ECDHE, .PSK, .WITH, .NULL, .SHA256, .none, .none),
    csEntry(0xC03A, .ECDHE, .PSK, .NULL, .SHA256, .none, .none, .none, .none),
    csEntry(0xC03B, .TLS, .ECDHE, .PSK, .WITH, .NULL, .SHA384, .none, .none),
    csEntry(0xC03B, .ECDHE, .PSK, .NULL, .SHA384, .none, .none, .none, .none),
    csEntry(0xC03C, .TLS, .RSA, .WITH, .ARIA, .@"128", .CBC, .SHA256, .none),
    csEntry(0xC03C, .ARIA128, .SHA256, .none, .none, .none, .none, .none, .none),
    csEntry(0xC03D, .TLS, .RSA, .WITH, .ARIA, .@"256", .CBC, .SHA384, .none),
    csEntry(0xC03D, .ARIA256, .SHA384, .none, .none, .none, .none, .none, .none),
    csEntry(0xC044, .TLS, .DHE, .RSA, .WITH, .ARIA, .@"128", .CBC, .SHA256),
    csEntry(0xC044, .DHE, .RSA, .ARIA128, .SHA256, .none, .none, .none, .none),
    csEntry(0xC045, .TLS, .DHE, .RSA, .WITH, .ARIA, .@"256", .CBC, .SHA384),
    csEntry(0xC045, .DHE, .RSA, .ARIA256, .SHA384, .none, .none, .none, .none),
    csEntry(0xC048, .TLS, .ECDHE, .ECDSA, .WITH, .ARIA, .@"128", .CBC, .SHA256),
    csEntry(0xC048, .ECDHE, .ECDSA, .ARIA128, .SHA256, .none, .none, .none, .none),
    csEntry(0xC049, .TLS, .ECDHE, .ECDSA, .WITH, .ARIA, .@"256", .CBC, .SHA384),
    csEntry(0xC049, .ECDHE, .ECDSA, .ARIA256, .SHA384, .none, .none, .none, .none),
    csEntry(0xC04A, .TLS, .ECDH, .ECDSA, .WITH, .ARIA, .@"128", .CBC, .SHA256),
    csEntry(0xC04A, .ECDH, .ECDSA, .ARIA128, .SHA256, .none, .none, .none, .none),
    csEntry(0xC04B, .TLS, .ECDH, .ECDSA, .WITH, .ARIA, .@"256", .CBC, .SHA384),
    csEntry(0xC04B, .ECDH, .ECDSA, .ARIA256, .SHA384, .none, .none, .none, .none),
    csEntry(0xC04C, .TLS, .ECDHE, .RSA, .WITH, .ARIA, .@"128", .CBC, .SHA256),
    csEntry(0xC04C, .ECDHE, .ARIA128, .SHA256, .none, .none, .none, .none, .none),
    csEntry(0xC04D, .TLS, .ECDHE, .RSA, .WITH, .ARIA, .@"256", .CBC, .SHA384),
    csEntry(0xC04D, .ECDHE, .ARIA256, .SHA384, .none, .none, .none, .none, .none),
    csEntry(0xC04E, .TLS, .ECDH, .RSA, .WITH, .ARIA, .@"128", .CBC, .SHA256),
    csEntry(0xC04E, .ECDH, .ARIA128, .SHA256, .none, .none, .none, .none, .none),
    csEntry(0xC04F, .TLS, .ECDH, .RSA, .WITH, .ARIA, .@"256", .CBC, .SHA384),
    csEntry(0xC04F, .ECDH, .ARIA256, .SHA384, .none, .none, .none, .none, .none),
    csEntry(0xC050, .TLS, .RSA, .WITH, .ARIA, .@"128", .GCM, .SHA256, .none),
    csEntry(0xC050, .ARIA128, .GCM, .SHA256, .none, .none, .none, .none, .none),
    csEntry(0xC051, .TLS, .RSA, .WITH, .ARIA, .@"256", .GCM, .SHA384, .none),
    csEntry(0xC051, .ARIA256, .GCM, .SHA384, .none, .none, .none, .none, .none),
    csEntry(0xC052, .TLS, .DHE, .RSA, .WITH, .ARIA, .@"128", .GCM, .SHA256),
    csEntry(0xC052, .DHE, .RSA, .ARIA128, .GCM, .SHA256, .none, .none, .none),
    csEntry(0xC053, .TLS, .DHE, .RSA, .WITH, .ARIA, .@"256", .GCM, .SHA384),
    csEntry(0xC053, .DHE, .RSA, .ARIA256, .GCM, .SHA384, .none, .none, .none),
    csEntry(0xC05C, .TLS, .ECDHE, .ECDSA, .WITH, .ARIA, .@"128", .GCM, .SHA256),
    csEntry(0xC05C, .ECDHE, .ECDSA, .ARIA128, .GCM, .SHA256, .none, .none, .none),
    csEntry(0xC05D, .TLS, .ECDHE, .ECDSA, .WITH, .ARIA, .@"256", .GCM, .SHA384),
    csEntry(0xC05D, .ECDHE, .ECDSA, .ARIA256, .GCM, .SHA384, .none, .none, .none),
    csEntry(0xC05E, .TLS, .ECDH, .ECDSA, .WITH, .ARIA, .@"128", .GCM, .SHA256),
    csEntry(0xC05E, .ECDH, .ECDSA, .ARIA128, .GCM, .SHA256, .none, .none, .none),
    csEntry(0xC05F, .TLS, .ECDH, .ECDSA, .WITH, .ARIA, .@"256", .GCM, .SHA384),
    csEntry(0xC05F, .ECDH, .ECDSA, .ARIA256, .GCM, .SHA384, .none, .none, .none),
    csEntry(0xC060, .TLS, .ECDHE, .RSA, .WITH, .ARIA, .@"128", .GCM, .SHA256),
    csEntry(0xC060, .ECDHE, .ARIA128, .GCM, .SHA256, .none, .none, .none, .none),
    csEntry(0xC061, .TLS, .ECDHE, .RSA, .WITH, .ARIA, .@"256", .GCM, .SHA384),
    csEntry(0xC061, .ECDHE, .ARIA256, .GCM, .SHA384, .none, .none, .none, .none),
    csEntry(0xC062, .TLS, .ECDH, .RSA, .WITH, .ARIA, .@"128", .GCM, .SHA256),
    csEntry(0xC062, .ECDH, .ARIA128, .GCM, .SHA256, .none, .none, .none, .none),
    csEntry(0xC063, .TLS, .ECDH, .RSA, .WITH, .ARIA, .@"256", .GCM, .SHA384),
    csEntry(0xC063, .ECDH, .ARIA256, .GCM, .SHA384, .none, .none, .none, .none),
    csEntry(0xC064, .TLS, .PSK, .WITH, .ARIA, .@"128", .CBC, .SHA256, .none),
    csEntry(0xC064, .PSK, .ARIA128, .SHA256, .none, .none, .none, .none, .none),
    csEntry(0xC065, .TLS, .PSK, .WITH, .ARIA, .@"256", .CBC, .SHA384, .none),
    csEntry(0xC065, .PSK, .ARIA256, .SHA384, .none, .none, .none, .none, .none),
    csEntry(0xC066, .TLS, .DHE, .PSK, .WITH, .ARIA, .@"128", .CBC, .SHA256),
    csEntry(0xC066, .DHE, .PSK, .ARIA128, .SHA256, .none, .none, .none, .none),
    csEntry(0xC067, .TLS, .DHE, .PSK, .WITH, .ARIA, .@"256", .CBC, .SHA384),
    csEntry(0xC067, .DHE, .PSK, .ARIA256, .SHA384, .none, .none, .none, .none),
    csEntry(0xC068, .TLS, .RSA, .PSK, .WITH, .ARIA, .@"128", .CBC, .SHA256),
    csEntry(0xC068, .RSA, .PSK, .ARIA128, .SHA256, .none, .none, .none, .none),
    csEntry(0xC069, .TLS, .RSA, .PSK, .WITH, .ARIA, .@"256", .CBC, .SHA384),
    csEntry(0xC069, .RSA, .PSK, .ARIA256, .SHA384, .none, .none, .none, .none),
    csEntry(0xC06A, .TLS, .PSK, .WITH, .ARIA, .@"128", .GCM, .SHA256, .none),
    csEntry(0xC06A, .PSK, .ARIA128, .GCM, .SHA256, .none, .none, .none, .none),
    csEntry(0xC06B, .TLS, .PSK, .WITH, .ARIA, .@"256", .GCM, .SHA384, .none),
    csEntry(0xC06B, .PSK, .ARIA256, .GCM, .SHA384, .none, .none, .none, .none),
    csEntry(0xC06C, .TLS, .DHE, .PSK, .WITH, .ARIA, .@"128", .GCM, .SHA256),
    csEntry(0xC06C, .DHE, .PSK, .ARIA128, .GCM, .SHA256, .none, .none, .none),
    csEntry(0xC06D, .TLS, .DHE, .PSK, .WITH, .ARIA, .@"256", .GCM, .SHA384),
    csEntry(0xC06D, .DHE, .PSK, .ARIA256, .GCM, .SHA384, .none, .none, .none),
    csEntry(0xC06E, .TLS, .RSA, .PSK, .WITH, .ARIA, .@"128", .GCM, .SHA256),
    csEntry(0xC06E, .RSA, .PSK, .ARIA128, .GCM, .SHA256, .none, .none, .none),
    csEntry(0xC06F, .TLS, .RSA, .PSK, .WITH, .ARIA, .@"256", .GCM, .SHA384),
    csEntry(0xC06F, .RSA, .PSK, .ARIA256, .GCM, .SHA384, .none, .none, .none),
    csEntry(0xC070, .TLS, .ECDHE, .PSK, .WITH, .ARIA, .@"128", .CBC, .SHA256),
    csEntry(0xC070, .ECDHE, .PSK, .ARIA128, .SHA256, .none, .none, .none, .none),
    csEntry(0xC071, .TLS, .ECDHE, .PSK, .WITH, .ARIA, .@"256", .CBC, .SHA384),
    csEntry(0xC071, .ECDHE, .PSK, .ARIA256, .SHA384, .none, .none, .none, .none),
    csEntry(0xC072, .TLS, .ECDHE, .ECDSA, .WITH, .CAMELLIA, .@"128", .CBC, .SHA256),
    csEntry(0xC072, .ECDHE, .ECDSA, .CAMELLIA128, .SHA256, .none, .none, .none, .none),
    csEntry(0xC073, .TLS, .ECDHE, .ECDSA, .WITH, .CAMELLIA, .@"256", .CBC, .SHA384),
    csEntry(0xC073, .ECDHE, .ECDSA, .CAMELLIA256, .SHA384, .none, .none, .none, .none),
    csEntry(0xC074, .TLS, .ECDH, .ECDSA, .WITH, .CAMELLIA, .@"128", .CBC, .SHA256),
    csEntry(0xC074, .ECDH, .ECDSA, .CAMELLIA128, .SHA256, .none, .none, .none, .none),
    csEntry(0xC075, .TLS, .ECDH, .ECDSA, .WITH, .CAMELLIA, .@"256", .CBC, .SHA384),
    csEntry(0xC075, .ECDH, .ECDSA, .CAMELLIA256, .SHA384, .none, .none, .none, .none),
    csEntry(0xC076, .TLS, .ECDHE, .RSA, .WITH, .CAMELLIA, .@"128", .CBC, .SHA256),
    csEntry(0xC076, .ECDHE, .RSA, .CAMELLIA128, .SHA256, .none, .none, .none, .none),
    csEntry(0xC077, .TLS, .ECDHE, .RSA, .WITH, .CAMELLIA, .@"256", .CBC, .SHA384),
    csEntry(0xC077, .ECDHE, .RSA, .CAMELLIA256, .SHA384, .none, .none, .none, .none),
    csEntry(0xC078, .TLS, .ECDH, .RSA, .WITH, .CAMELLIA, .@"128", .CBC, .SHA256),
    csEntry(0xC078, .ECDH, .CAMELLIA128, .SHA256, .none, .none, .none, .none, .none),
    csEntry(0xC079, .TLS, .ECDH, .RSA, .WITH, .CAMELLIA, .@"256", .CBC, .SHA384),
    csEntry(0xC079, .ECDH, .CAMELLIA256, .SHA384, .none, .none, .none, .none, .none),
    csEntry(0xC07A, .TLS, .RSA, .WITH, .CAMELLIA, .@"128", .GCM, .SHA256, .none),
    csEntry(0xC07A, .CAMELLIA128, .GCM, .SHA256, .none, .none, .none, .none, .none),
    csEntry(0xC07B, .TLS, .RSA, .WITH, .CAMELLIA, .@"256", .GCM, .SHA384, .none),
    csEntry(0xC07B, .CAMELLIA256, .GCM, .SHA384, .none, .none, .none, .none, .none),
    csEntry(0xC07C, .TLS, .DHE, .RSA, .WITH, .CAMELLIA, .@"128", .GCM, .SHA256),
    csEntry(0xC07C, .DHE, .RSA, .CAMELLIA128, .GCM, .SHA256, .none, .none, .none),
    csEntry(0xC07D, .TLS, .DHE, .RSA, .WITH, .CAMELLIA, .@"256", .GCM, .SHA384),
    csEntry(0xC07D, .DHE, .RSA, .CAMELLIA256, .GCM, .SHA384, .none, .none, .none),
    csEntry(0xC086, .TLS, .ECDHE, .ECDSA, .WITH, .CAMELLIA, .@"128", .GCM, .SHA256),
    csEntry(0xC086, .ECDHE, .ECDSA, .CAMELLIA128, .GCM, .SHA256, .none, .none, .none),
    csEntry(0xC087, .TLS, .ECDHE, .ECDSA, .WITH, .CAMELLIA, .@"256", .GCM, .SHA384),
    csEntry(0xC087, .ECDHE, .ECDSA, .CAMELLIA256, .GCM, .SHA384, .none, .none, .none),
    csEntry(0xC088, .TLS, .ECDH, .ECDSA, .WITH, .CAMELLIA, .@"128", .GCM, .SHA256),
    csEntry(0xC088, .ECDH, .ECDSA, .CAMELLIA128, .GCM, .SHA256, .none, .none, .none),
    csEntry(0xC089, .TLS, .ECDH, .ECDSA, .WITH, .CAMELLIA, .@"256", .GCM, .SHA384),
    csEntry(0xC089, .ECDH, .ECDSA, .CAMELLIA256, .GCM, .SHA384, .none, .none, .none),
    csEntry(0xC08A, .TLS, .ECDHE, .RSA, .WITH, .CAMELLIA, .@"128", .GCM, .SHA256),
    csEntry(0xC08A, .ECDHE, .CAMELLIA128, .GCM, .SHA256, .none, .none, .none, .none),
    csEntry(0xC08B, .TLS, .ECDHE, .RSA, .WITH, .CAMELLIA, .@"256", .GCM, .SHA384),
    csEntry(0xC08B, .ECDHE, .CAMELLIA256, .GCM, .SHA384, .none, .none, .none, .none),
    csEntry(0xC08C, .TLS, .ECDH, .RSA, .WITH, .CAMELLIA, .@"128", .GCM, .SHA256),
    csEntry(0xC08C, .ECDH, .CAMELLIA128, .GCM, .SHA256, .none, .none, .none, .none),
    csEntry(0xC08D, .TLS, .ECDH, .RSA, .WITH, .CAMELLIA, .@"256", .GCM, .SHA384),
    csEntry(0xC08D, .ECDH, .CAMELLIA256, .GCM, .SHA384, .none, .none, .none, .none),
    csEntry(0xC08E, .TLS, .PSK, .WITH, .CAMELLIA, .@"128", .GCM, .SHA256, .none),
    csEntry(0xC08E, .PSK, .CAMELLIA128, .GCM, .SHA256, .none, .none, .none, .none),
    csEntry(0xC08F, .TLS, .PSK, .WITH, .CAMELLIA, .@"256", .GCM, .SHA384, .none),
    csEntry(0xC08F, .PSK, .CAMELLIA256, .GCM, .SHA384, .none, .none, .none, .none),
    csEntry(0xC090, .TLS, .DHE, .PSK, .WITH, .CAMELLIA, .@"128", .GCM, .SHA256),
    csEntry(0xC090, .DHE, .PSK, .CAMELLIA128, .GCM, .SHA256, .none, .none, .none),
    csEntry(0xC091, .TLS, .DHE, .PSK, .WITH, .CAMELLIA, .@"256", .GCM, .SHA384),
    csEntry(0xC091, .DHE, .PSK, .CAMELLIA256, .GCM, .SHA384, .none, .none, .none),
    csEntry(0xC092, .TLS, .RSA, .PSK, .WITH, .CAMELLIA, .@"128", .GCM, .SHA256),
    csEntry(0xC092, .RSA, .PSK, .CAMELLIA128, .GCM, .SHA256, .none, .none, .none),
    csEntry(0xC093, .TLS, .RSA, .PSK, .WITH, .CAMELLIA, .@"256", .GCM, .SHA384),
    csEntry(0xC093, .RSA, .PSK, .CAMELLIA256, .GCM, .SHA384, .none, .none, .none),
    csEntry(0xC094, .TLS, .PSK, .WITH, .CAMELLIA, .@"128", .CBC, .SHA256, .none),
    csEntry(0xC094, .PSK, .CAMELLIA128, .SHA256, .none, .none, .none, .none, .none),
    csEntry(0xC095, .TLS, .PSK, .WITH, .CAMELLIA, .@"256", .CBC, .SHA384, .none),
    csEntry(0xC095, .PSK, .CAMELLIA256, .SHA384, .none, .none, .none, .none, .none),
    csEntry(0xC096, .TLS, .DHE, .PSK, .WITH, .CAMELLIA, .@"128", .CBC, .SHA256),
    csEntry(0xC096, .DHE, .PSK, .CAMELLIA128, .SHA256, .none, .none, .none, .none),
    csEntry(0xC097, .TLS, .DHE, .PSK, .WITH, .CAMELLIA, .@"256", .CBC, .SHA384),
    csEntry(0xC097, .DHE, .PSK, .CAMELLIA256, .SHA384, .none, .none, .none, .none),
    csEntry(0xC098, .TLS, .RSA, .PSK, .WITH, .CAMELLIA, .@"128", .CBC, .SHA256),
    csEntry(0xC098, .RSA, .PSK, .CAMELLIA128, .SHA256, .none, .none, .none, .none),
    csEntry(0xC099, .TLS, .RSA, .PSK, .WITH, .CAMELLIA, .@"256", .CBC, .SHA384),
    csEntry(0xC099, .RSA, .PSK, .CAMELLIA256, .SHA384, .none, .none, .none, .none),
    csEntry(0xC09A, .TLS, .ECDHE, .PSK, .WITH, .CAMELLIA, .@"128", .CBC, .SHA256),
    csEntry(0xC09A, .ECDHE, .PSK, .CAMELLIA128, .SHA256, .none, .none, .none, .none),
    csEntry(0xC09B, .TLS, .ECDHE, .PSK, .WITH, .CAMELLIA, .@"256", .CBC, .SHA384),
    csEntry(0xC09B, .ECDHE, .PSK, .CAMELLIA256, .SHA384, .none, .none, .none, .none),
    csEntry(0xC09E, .TLS, .DHE, .RSA, .WITH, .AES, .@"128", .CCM, .none),
    csEntry(0xC09E, .DHE, .RSA, .AES128, .CCM, .none, .none, .none, .none),
    csEntry(0xC09F, .TLS, .DHE, .RSA, .WITH, .AES, .@"256", .CCM, .none),
    csEntry(0xC09F, .DHE, .RSA, .AES256, .CCM, .none, .none, .none, .none),
    csEntry(0xC0A2, .TLS, .DHE, .RSA, .WITH, .AES, .@"128", .CCM, .@"8"),
    csEntry(0xC0A2, .DHE, .RSA, .AES128, .CCM8, .none, .none, .none, .none),
    csEntry(0xC0A3, .TLS, .DHE, .RSA, .WITH, .AES, .@"256", .CCM, .@"8"),
    csEntry(0xC0A3, .DHE, .RSA, .AES256, .CCM8, .none, .none, .none, .none),
    csEntry(0xC0A4, .TLS, .PSK, .WITH, .AES, .@"128", .CCM, .none, .none),
    csEntry(0xC0A4, .PSK, .AES128, .CCM, .none, .none, .none, .none, .none),
    csEntry(0xC0A5, .TLS, .PSK, .WITH, .AES, .@"256", .CCM, .none, .none),
    csEntry(0xC0A5, .PSK, .AES256, .CCM, .none, .none, .none, .none, .none),
    csEntry(0xC0A6, .TLS, .DHE, .PSK, .WITH, .AES, .@"128", .CCM, .none),
    csEntry(0xC0A6, .DHE, .PSK, .AES128, .CCM, .none, .none, .none, .none),
    csEntry(0xC0A7, .TLS, .DHE, .PSK, .WITH, .AES, .@"256", .CCM, .none),
    csEntry(0xC0A7, .DHE, .PSK, .AES256, .CCM, .none, .none, .none, .none),
    csEntry(0xC0A8, .TLS, .PSK, .WITH, .AES, .@"128", .CCM, .@"8", .none),
    csEntry(0xC0A8, .PSK, .AES128, .CCM8, .none, .none, .none, .none, .none),
    csEntry(0xC0A9, .TLS, .PSK, .WITH, .AES, .@"256", .CCM, .@"8", .none),
    csEntry(0xC0A9, .PSK, .AES256, .CCM8, .none, .none, .none, .none, .none),
    csEntry(0xC0AA, .TLS, .PSK, .DHE, .WITH, .AES, .@"128", .CCM, .@"8"),
    csEntry(0xC0AA, .DHE, .PSK, .AES128, .CCM8, .none, .none, .none, .none),
    csEntry(0xC0AB, .TLS, .PSK, .DHE, .WITH, .AES, .@"256", .CCM, .@"8"),
    csEntry(0xC0AB, .DHE, .PSK, .AES256, .CCM8, .none, .none, .none, .none),
    csEntry(0xCCAA, .TLS, .DHE, .RSA, .WITH, .CHACHA20, .POLY1305, .SHA256, .none),
    csEntry(0xCCAA, .DHE, .RSA, .CHACHA20, .POLY1305, .none, .none, .none, .none),
    csEntry(0xCCAC, .TLS, .ECDHE, .PSK, .WITH, .CHACHA20, .POLY1305, .SHA256, .none),
    csEntry(0xCCAC, .ECDHE, .PSK, .CHACHA20, .POLY1305, .none, .none, .none, .none),
    csEntry(0xCCAD, .TLS, .DHE, .PSK, .WITH, .CHACHA20, .POLY1305, .SHA256, .none),
    csEntry(0xCCAD, .DHE, .PSK, .CHACHA20, .POLY1305, .none, .none, .none, .none),
    csEntry(0xCCAE, .TLS, .RSA, .PSK, .WITH, .CHACHA20, .POLY1305, .SHA256, .none),
    csEntry(0xCCAE, .RSA, .PSK, .CHACHA20, .POLY1305, .none, .none, .none, .none),
};

fn cs_str_to_zip(cs_str: [*]const u8, cs_len: usize, zip: *[6]u8) c_int {
    var indexes: [8]u8 = .{ 0, 0, 0, 0, 0, 0, 0, 0 };
    var nxt: usize = 0;
    const separator: u8 = if (cs_len >= 3 and primitives.curl_strnequal(@ptrCast(cs_str), "TLS", 3) != 0) '_' else '-';
    var i: usize = 0;

    while (true) {
        if (i == 8)
            return -1;

        const cur = nxt;
        while (nxt < cs_len and cs_str[nxt] != 0 and cs_str[nxt] != separator) : (nxt += 1) {}
        const len = nxt - cur;

        var found_idx: usize = cs_parts.len;
        for (cs_parts[1..], 1..) |part, idx| {
            if (part.len == len and primitives.curl_strnequal(@ptrCast(part.ptr), @ptrCast(cs_str + cur), len) != 0) {
                found_idx = idx;
                break;
            }
        }
        if (found_idx == cs_parts.len)
            return -1;

        indexes[i] = @intCast(found_idx);
        i += 1;

        if (nxt < cs_len and cs_str[nxt] != 0) {
            nxt += 1;
        } else {
            break;
        }
    }

    zip[0] = (indexes[0] << 2) | ((indexes[1] & 0x3F) >> 4);
    zip[1] = (indexes[1] << 4) | ((indexes[2] & 0x3F) >> 2);
    zip[2] = (indexes[2] << 6) | (indexes[3] & 0x3F);
    zip[3] = (indexes[4] << 2) | ((indexes[5] & 0x3F) >> 4);
    zip[4] = (indexes[5] << 4) | ((indexes[6] & 0x3F) >> 2);
    zip[5] = (indexes[6] << 6) | (indexes[7] & 0x3F);

    return 0;
}

fn appendBounded(buf: [*]u8, max_len: usize, src: []const u8) usize {
    if (max_len == 0) return 0;
    const n = @min(src.len, max_len - 1);
    @memcpy(buf[0..n], src[0..n]);
    buf[n] = 0;
    return n;
}

fn cs_zip_to_str(zip: *const [6]u8, buf: [*]u8, buf_size: usize) c_int {
    const indexes = [8]u8{
        zip[0] >> 2,
        ((zip[0] << 4) & 0x3F) | (zip[1] >> 4),
        ((zip[1] << 2) & 0x3F) | (zip[2] >> 6),
        zip[2] & 0x3F,
        zip[3] >> 2,
        ((zip[3] << 4) & 0x3F) | (zip[4] >> 4),
        ((zip[4] << 2) & 0x3F) | (zip[5] >> 6),
        zip[5] & 0x3F,
    };

    const separator: u8 = if (indexes[0] == @backingInt(CsTxtIdx.TLS)) '_' else '-';
    var len: usize = 0;
    var i: usize = 0;

    while (i < 8 and indexes[i] != 0 and len < buf_size) : (i += 1) {
        if (indexes[i] >= cs_parts.len)
            return -1;
        const entry = cs_parts[indexes[i]];
        if (i > 0) {
            var tmp: [32]u8 = undefined;
            tmp[0] = separator;
            @memcpy(tmp[1 .. 1 + entry.len], entry);
            len += appendBounded(buf + len, buf_size - len, tmp[0 .. 1 + entry.len]);
        } else {
            len += appendBounded(buf + len, buf_size - len, entry);
        }
    }

    return 0;
}

pub export fn Curl_cipher_suite_lookup_id(cs_str: ?[*]const u8, cs_len: usize) callconv(.c) u16 {
    const s = cs_str orelse return 0;
    var zip: [6]u8 = undefined;
    if (cs_len > 0 and cs_str_to_zip(s, cs_len, &zip) == 0) {
        for (cs_list) |item| {
            if (std.mem.eql(u8, &item.zip, &zip))
                return item.id;
        }
    }
    return 0;
}

fn cs_is_separator(c: u8) bool {
    return switch (c) {
        ' ', '\t', ':', ',', ';' => true,
        else => false,
    };
}

pub export fn Curl_cipher_suite_walk_str(str: *?[*:0]const u8, end: *?[*:0]const u8) callconv(.c) u16 {
    var s = str.* orelse {
        end.* = null;
        return 0;
    };

    while (cs_is_separator(s[0])) {
        s += 1;
    }
    str.* = s;

    var e = s;
    while (e[0] != 0 and !cs_is_separator(e[0])) {
        e += 1;
    }
    end.* = e;

    return Curl_cipher_suite_lookup_id(s, @intFromPtr(e) - @intFromPtr(s));
}

pub export fn Curl_cipher_suite_get_str(
    id: u16,
    buf: ?[*]u8,
    buf_size: usize,
    prefer_rfc: bool,
) callconv(.c) c_int {
    const b = buf orelse return -1;
    var j: usize = cs_list.len;
    var r: c_int = -1;

    for (cs_list, 0..) |item, i| {
        if (item.id != id)
            continue;
        if (((item.zip[0] >> 2) != @backingInt(CsTxtIdx.TLS)) == !prefer_rfc) {
            j = i;
            break;
        }
        if (j == cs_list.len)
            j = i;
    }

    if (j < cs_list.len)
        r = cs_zip_to_str(&cs_list[j].zip, b, buf_size);

    if (r < 0) {
        var tmp: [32]u8 = undefined;
        const formatted = std.fmt.bufPrint(&tmp, "TLS_UNKNOWN_0x{x:0>4}", .{id}) catch "TLS_UNKNOWN";
        _ = appendBounded(b, buf_size, formatted);
    }

    return r;
}

// ============================================================================
// Shared CFilter / SSL peer / SSL config types for Apple & Schannel verify
// ============================================================================

pub const CurlPeer = extern struct {
    scheme: ?*const anyopaque,
    hostname: [*:0]const u8,
    zoneid: ?[*:0]u8,
    refcount: u32,
    scopeid: u32,
    port: u16,
    flags: c_uint,
    user_hostname: [1]u8,
};

pub const SslPeer = extern struct {
    origin: *CurlPeer,
    peer: ?*CurlPeer,
    sni: ?[*:0]const u8,
    scache_key: ?[*:0]u8,
    type: c_uint,
    transport: u8,
};

pub const CurlCfilter = extern struct {
    cft: ?*const anyopaque,
    next: ?*CurlCfilter,
    ctx: ?*anyopaque,
    conn: ?*anyopaque,
    sockindex: i8,
    flags: c_uint,
};

pub const CurlBlob = extern struct {
    data: ?[*]const u8,
    len: usize,
    flags: c_uint,
};

// ============================================================================
// 5. lib/vtls/apple.c — macOS/iOS SecTrust certificate verification helper
// ============================================================================

const apple = struct {
    pub const SslFilterConfig = @import("vtls_scache_asn1.zig").SslFilterConfig;

    pub const CFTypeRef = *const anyopaque;
    pub const CFDataRef = *const anyopaque;
    pub const CFStringRef = *const anyopaque;
    pub const CFErrorRef = *const anyopaque;
    pub const CFMutableArrayRef = *anyopaque;
    pub const SecTrustRef = *anyopaque;
    pub const SecPolicyRef = *anyopaque;
    pub const SecCertificateRef = *anyopaque;
    pub const CFIndex = isize;
    pub const CFStringEncoding = u32;
    pub const CFOptionFlags = usize;
    pub const OSStatus = i32;

    pub const kCFStringEncodingUTF8: CFStringEncoding = 0x08000100;
    pub const noErr: OSStatus = 0;
    pub const kSecRevocationOCSPMethod: CFOptionFlags = (1 << 0);
    pub const kSecRevocationCRLMethod: CFOptionFlags = (1 << 1);
    pub const kSecRevocationUseAnyAvailableMethod: CFOptionFlags = kSecRevocationOCSPMethod | kSecRevocationCRLMethod;
    pub const kSecRevocationRequirePositiveResponse: CFOptionFlags = (1 << 3);
    pub const errSecIncompleteCertRevocationCheck: CFIndex = -67635;

    pub const CurlVtlsGetCertDerFn = *const fn (
        cf: *CurlCfilter,
        data: ?*anyopaque,
        cb_user_data: ?*anyopaque,
        cert_index: usize,
        out_der: *?[*]u8,
        out_der_len: *usize,
    ) callconv(.c) c_uint;

    pub const SecTrustApi = struct {
        get_filter_config: *const fn (*CurlCfilter) callconv(.c) ?*SslFilterConfig,
        CFStringCreateWithCString: *const fn (?*const anyopaque, [*:0]const u8, CFStringEncoding) callconv(.c) ?CFStringRef,
        CFArrayCreateMutable: *const fn (?*const anyopaque, CFIndex, ?*const anyopaque) callconv(.c) ?CFMutableArrayRef,
        CFArrayAppendValue: *const fn (CFMutableArrayRef, *const anyopaque) callconv(.c) void,
        CFRelease: *const fn (*const anyopaque) callconv(.c) void,
        CFDataCreate: *const fn (?*const anyopaque, ?[*]const u8, CFIndex) callconv(.c) ?CFDataRef,
        CFErrorGetCode: *const fn (CFErrorRef) callconv(.c) CFIndex,
        CFErrorCopyDescription: *const fn (CFErrorRef) callconv(.c) ?CFStringRef,
        CFStringGetLength: *const fn (CFStringRef) callconv(.c) CFIndex,
        CFStringGetMaximumSizeForEncoding: *const fn (CFIndex, CFStringEncoding) callconv(.c) CFIndex,
        CFStringGetCString: *const fn (CFStringRef, [*]u8, CFIndex, CFStringEncoding) callconv(.c) u8,
        SecPolicyCreateSSL: *const fn (bool, ?CFStringRef) callconv(.c) ?SecPolicyRef,
        SecPolicyCreateRevocation: *const fn (CFOptionFlags) callconv(.c) ?SecPolicyRef,
        SecCertificateCreateWithData: *const fn (?*const anyopaque, CFDataRef) callconv(.c) ?SecCertificateRef,
        SecTrustCreateWithCertificates: *const fn (*const anyopaque, *const anyopaque, *?SecTrustRef) callconv(.c) OSStatus,
        SecTrustSetOCSPResponse: *const fn (SecTrustRef, *const anyopaque) callconv(.c) OSStatus,
        SecTrustEvaluateWithError: *const fn (SecTrustRef, *?CFErrorRef) callconv(.c) bool,
        kCFTypeArrayCallBacks: ?*const anyopaque,
        failf_hook: ?*const fn (data: ?*anyopaque, msg: []const u8) void = null,
    };

    pub var mock_api: ?SecTrustApi = null;

    const darwin_extern = struct {
        extern "c" fn Curl_ssl_cf_get_filter_config(cf: *CurlCfilter) ?*SslFilterConfig;
        extern "c" fn CFStringCreateWithCString(alloc: ?*const anyopaque, cStr: [*:0]const u8, encoding: CFStringEncoding) ?CFStringRef;
        extern "c" fn CFArrayCreateMutable(allocator: ?*const anyopaque, capacity: CFIndex, callBacks: ?*const anyopaque) ?CFMutableArrayRef;
        extern "c" fn CFArrayAppendValue(theArray: CFMutableArrayRef, value: *const anyopaque) void;
        extern "c" fn CFRelease(cf: *const anyopaque) void;
        extern "c" fn CFDataCreate(allocator: ?*const anyopaque, bytes: ?[*]const u8, length: CFIndex) ?CFDataRef;
        extern "c" fn CFErrorGetCode(err: CFErrorRef) CFIndex;
        extern "c" fn CFErrorCopyDescription(err: CFErrorRef) ?CFStringRef;
        extern "c" fn CFStringGetLength(theString: CFStringRef) CFIndex;
        extern "c" fn CFStringGetMaximumSizeForEncoding(length: CFIndex, encoding: CFStringEncoding) CFIndex;
        extern "c" fn CFStringGetCString(theString: CFStringRef, buffer: [*]u8, bufferSize: CFIndex, encoding: CFStringEncoding) u8;
        extern "c" fn SecPolicyCreateSSL(server: bool, hostname: ?CFStringRef) ?SecPolicyRef;
        extern "c" fn SecPolicyCreateRevocation(revocationFlags: CFOptionFlags) ?SecPolicyRef;
        extern "c" fn SecCertificateCreateWithData(allocator: ?*const anyopaque, data: CFDataRef) ?SecCertificateRef;
        extern "c" fn SecTrustCreateWithCertificates(certificates: *const anyopaque, policies: *const anyopaque, trust: *?SecTrustRef) OSStatus;
        extern "c" fn SecTrustSetOCSPResponse(trust: SecTrustRef, responseData: *const anyopaque) OSStatus;
        extern "c" fn SecTrustEvaluateWithError(trust: SecTrustRef, @"error": *?CFErrorRef) bool;
        extern "c" const kCFTypeArrayCallBacks: anyopaque;
    };

    extern "c" fn dlopen(path: ?[*:0]const u8, mode: c_int) ?*anyopaque;
    extern "c" fn dlsym(handle: ?*anyopaque, symbol: [*:0]const u8) ?*anyopaque;
    extern "c" fn Curl_failf(data: ?*anyopaque, fmt: [*:0]const u8, ...) void;

    const RTLD_LAZY: c_int = 1;
    const RTLD_DEFAULT: ?*anyopaque = @ptrFromInt(@as(usize, @bitCast(@as(isize, -2))));

    fn lookupRawSym(name: [*:0]const u8) ?*anyopaque {
        if (dlsym(RTLD_DEFAULT, name)) |p| return p;
        if (builtin.os.tag.isDarwin()) {
            const S = struct {
                var sec_handle: ?*anyopaque = null;
                var cf_handle: ?*anyopaque = null;
            };
            if (S.sec_handle == null) {
                S.sec_handle = dlopen("/System/Library/Frameworks/Security.framework/Security", RTLD_LAZY);
            }
            if (S.sec_handle) |h| {
                if (dlsym(h, name)) |p| return p;
            }
            if (S.cf_handle == null) {
                S.cf_handle = dlopen("/System/Library/Frameworks/CoreFoundation.framework/CoreFoundation", RTLD_LAZY);
            }
            if (S.cf_handle) |h| {
                if (dlsym(h, name)) |p| return p;
            }
        }
        return null;
    }

    fn sym(comptime T: type, name: [*:0]const u8) ?T {
        const p = lookupRawSym(name) orelse return null;
        return @ptrCast(@alignCast(p));
    }

    fn resolveApi() ?SecTrustApi {
        if (mock_api) |api| return api;
        if (!builtin.os.tag.isDarwin()) return null;

        if (builtin.output_mode == .Lib and backend_options.ssl == .sectransport) {
            return .{
                .get_filter_config = &darwin_extern.Curl_ssl_cf_get_filter_config,
                .CFStringCreateWithCString = &darwin_extern.CFStringCreateWithCString,
                .CFArrayCreateMutable = &darwin_extern.CFArrayCreateMutable,
                .CFArrayAppendValue = &darwin_extern.CFArrayAppendValue,
                .CFRelease = &darwin_extern.CFRelease,
                .CFDataCreate = &darwin_extern.CFDataCreate,
                .CFErrorGetCode = &darwin_extern.CFErrorGetCode,
                .CFErrorCopyDescription = &darwin_extern.CFErrorCopyDescription,
                .CFStringGetLength = &darwin_extern.CFStringGetLength,
                .CFStringGetMaximumSizeForEncoding = &darwin_extern.CFStringGetMaximumSizeForEncoding,
                .CFStringGetCString = &darwin_extern.CFStringGetCString,
                .SecPolicyCreateSSL = &darwin_extern.SecPolicyCreateSSL,
                .SecPolicyCreateRevocation = &darwin_extern.SecPolicyCreateRevocation,
                .SecCertificateCreateWithData = &darwin_extern.SecCertificateCreateWithData,
                .SecTrustCreateWithCertificates = &darwin_extern.SecTrustCreateWithCertificates,
                .SecTrustSetOCSPResponse = &darwin_extern.SecTrustSetOCSPResponse,
                .SecTrustEvaluateWithError = &darwin_extern.SecTrustEvaluateWithError,
                .kCFTypeArrayCallBacks = &darwin_extern.kCFTypeArrayCallBacks,
            };
        }

        const get_filter_config = if (builtin.output_mode == .Lib and backend_options.ssl != .none)
            &darwin_extern.Curl_ssl_cf_get_filter_config
        else
            (sym(*const fn (*CurlCfilter) callconv(.c) ?*SslFilterConfig, "Curl_ssl_cf_get_filter_config") orelse return null);

        return .{
            .get_filter_config = get_filter_config,
            .CFStringCreateWithCString = sym(*const fn (?*const anyopaque, [*:0]const u8, CFStringEncoding) callconv(.c) ?CFStringRef, "CFStringCreateWithCString") orelse return null,
            .CFArrayCreateMutable = sym(*const fn (?*const anyopaque, CFIndex, ?*const anyopaque) callconv(.c) ?CFMutableArrayRef, "CFArrayCreateMutable") orelse return null,
            .CFArrayAppendValue = sym(*const fn (CFMutableArrayRef, *const anyopaque) callconv(.c) void, "CFArrayAppendValue") orelse return null,
            .CFRelease = sym(*const fn (*const anyopaque) callconv(.c) void, "CFRelease") orelse return null,
            .CFDataCreate = sym(*const fn (?*const anyopaque, ?[*]const u8, CFIndex) callconv(.c) ?CFDataRef, "CFDataCreate") orelse return null,
            .CFErrorGetCode = sym(*const fn (CFErrorRef) callconv(.c) CFIndex, "CFErrorGetCode") orelse return null,
            .CFErrorCopyDescription = sym(*const fn (CFErrorRef) callconv(.c) ?CFStringRef, "CFErrorCopyDescription") orelse return null,
            .CFStringGetLength = sym(*const fn (CFStringRef) callconv(.c) CFIndex, "CFStringGetLength") orelse return null,
            .CFStringGetMaximumSizeForEncoding = sym(*const fn (CFIndex, CFStringEncoding) callconv(.c) CFIndex, "CFStringGetMaximumSizeForEncoding") orelse return null,
            .CFStringGetCString = sym(*const fn (CFStringRef, [*]u8, CFIndex, CFStringEncoding) callconv(.c) u8, "CFStringGetCString") orelse return null,
            .SecPolicyCreateSSL = sym(*const fn (bool, ?CFStringRef) callconv(.c) ?SecPolicyRef, "SecPolicyCreateSSL") orelse return null,
            .SecPolicyCreateRevocation = sym(*const fn (CFOptionFlags) callconv(.c) ?SecPolicyRef, "SecPolicyCreateRevocation") orelse return null,
            .SecCertificateCreateWithData = sym(*const fn (?*const anyopaque, CFDataRef) callconv(.c) ?SecCertificateRef, "SecCertificateCreateWithData") orelse return null,
            .SecTrustCreateWithCertificates = sym(*const fn (*const anyopaque, *const anyopaque, *?SecTrustRef) callconv(.c) OSStatus, "SecTrustCreateWithCertificates") orelse return null,
            .SecTrustSetOCSPResponse = sym(*const fn (SecTrustRef, *const anyopaque) callconv(.c) OSStatus, "SecTrustSetOCSPResponse") orelse return null,
            .SecTrustEvaluateWithError = sym(*const fn (SecTrustRef, *?CFErrorRef) callconv(.c) bool, "SecTrustEvaluateWithError") orelse return null,
            .kCFTypeArrayCallBacks = lookupRawSym("kCFTypeArrayCallBacks"),
        };
    }

    pub fn Curl_vtls_apple_verify(
        cf: *CurlCfilter,
        data: ?*anyopaque,
        peer: *SslPeer,
        num_certs: usize,
        der_cb: CurlVtlsGetCertDerFn,
        cb_user_data: ?*anyopaque,
        ocsp_buf: ?[*]const u8,
        ocsp_len: usize,
        require_ocsp: bool,
    ) callconv(.c) c_uint {
        const api = resolveApi() orelse return CURLE_NOT_BUILT_IN;
        const conn_config = api.get_filter_config(cf) orelse return CURLE_BAD_FUNCTION_ARGUMENT;
        var result: c_uint = CURLE_OK;
        var trust: ?SecTrustRef = null;
        var policy: ?SecPolicyRef = null;
        var policies: ?CFMutableArrayRef = null;
        var cert_array: ?CFMutableArrayRef = null;
        var host_str: ?CFStringRef = null;
        var err: ?CFErrorRef = null;
        var error_ref: ?CFStringRef = null;
        var err_desc: ?[*]u8 = null;

        defer {
            if (err_desc) |p| mem.free(p);
            if (error_ref) |r| api.CFRelease(r);
            if (err) |r| api.CFRelease(r);
            if (host_str) |r| api.CFRelease(r);
            if (policies) |r| api.CFRelease(r);
            if (policy) |r| api.CFRelease(r);
            if (cert_array) |r| api.CFRelease(r);
            if (trust) |r| api.CFRelease(r);
        }

        if (conn_config.verifyhost()) {
            const hname = peer.sni orelse peer.origin.hostname;
            host_str = api.CFStringCreateWithCString(null, hname, kCFStringEncodingUTF8);
            if (host_str == null) {
                return CURLE_OUT_OF_MEMORY;
            }
        }

        policies = api.CFArrayCreateMutable(null, 2, api.kCFTypeArrayCallBacks);
        if (policies == null) {
            return CURLE_OUT_OF_MEMORY;
        }

        policy = api.SecPolicyCreateSSL(true, host_str);
        if (policy == null) {
            return CURLE_OUT_OF_MEMORY;
        }

        api.CFArrayAppendValue(policies.?, policy.?);
        api.CFRelease(policy.?);
        policy = null;

        if (!conn_config.no_revoke()) {
            var revocation_flags: CFOptionFlags = kSecRevocationUseAnyAvailableMethod;
            if (require_ocsp)
                revocation_flags |= kSecRevocationRequirePositiveResponse;
            policy = api.SecPolicyCreateRevocation(revocation_flags);
            if (policy == null) {
                return CURLE_OUT_OF_MEMORY;
            }
            api.CFArrayAppendValue(policies.?, policy.?);
            api.CFRelease(policy.?);
            policy = null;
        }

        cert_array = api.CFArrayCreateMutable(null, @intCast(num_certs), api.kCFTypeArrayCallBacks);
        if (cert_array == null) {
            return CURLE_OUT_OF_MEMORY;
        }

        var i: usize = 0;
        while (i < num_certs) : (i += 1) {
            var der: ?[*]u8 = null;
            var der_len: usize = 0;
            result = der_cb(cf, data, cb_user_data, i, &der, &der_len);
            if (result != CURLE_OK)
                return result;

            const certdata = api.CFDataCreate(null, der, @intCast(der_len)) orelse return CURLE_OUT_OF_MEMORY;
            const cert = api.SecCertificateCreateWithData(null, certdata);
            api.CFRelease(certdata);
            if (cert == null) {
                return CURLE_OUT_OF_MEMORY;
            }
            api.CFArrayAppendValue(cert_array.?, cert.?);
            api.CFRelease(cert.?);
        }

        var status = api.SecTrustCreateWithCertificates(cert_array.?, policies.?, &trust);
        if (status != noErr or trust == null) {
            if (api.failf_hook) |hook| {
                hook(data, "Apple SecTrust: failed to create validation trust");
            } else if (builtin.output_mode == .Lib) {
                Curl_failf(data, "Apple SecTrust: failed to create validation trust");
            }
            return CURLE_PEER_FAILED_VERIFICATION;
        }

        if (ocsp_len > 0 and ocsp_buf != null) {
            const ocspdata = api.CFDataCreate(null, ocsp_buf, @intCast(ocsp_len)) orelse return CURLE_OUT_OF_MEMORY;
            status = api.SecTrustSetOCSPResponse(trust.?, ocspdata);
            api.CFRelease(ocspdata);
            if (status != noErr) {
                if (api.failf_hook) |hook| {
                    var msg_buf: [128]u8 = undefined;
                    const msg = std.fmt.bufPrint(&msg_buf, "Apple SecTrust: failed to set OCSP response: {d}", .{status}) catch "Apple SecTrust: failed to set OCSP response";
                    hook(data, msg);
                } else if (builtin.output_mode == .Lib) {
                    Curl_failf(data, "Apple SecTrust: failed to set OCSP response: %d", @as(c_int, status));
                }
                return CURLE_PEER_FAILED_VERIFICATION;
            }
        }

        result = if (api.SecTrustEvaluateWithError(trust.?, &err))
            CURLE_OK
        else
            CURLE_PEER_FAILED_VERIFICATION;

        if (err) |e| {
            const code = api.CFErrorGetCode(e);
            error_ref = api.CFErrorCopyDescription(e);
            if (error_ref) |eref| {
                const size = api.CFStringGetMaximumSizeForEncoding(api.CFStringGetLength(eref), kCFStringEncodingUTF8);
                if (size >= 0) {
                    if (mem.malloc(@intCast(size + 1))) |raw_buf| {
                        const buf_ptr: [*]u8 = @ptrCast(raw_buf);
                        if (api.CFStringGetCString(eref, buf_ptr, size, kCFStringEncodingUTF8) != 0) {
                            err_desc = buf_ptr;
                        } else {
                            mem.free(raw_buf);
                        }
                    }
                }
            }
            const sep: [*:0]const u8 = if (err_desc != null) ": " else "";
            const desc: [*:0]const u8 = if (err_desc) |p| @ptrCast(p) else "";
            if (api.failf_hook) |hook| {
                var msg_buf: [512]u8 = undefined;
                const msg = std.fmt.bufPrint(&msg_buf, "Apple SecTrust failure {d}{s}{s}", .{ code, std.mem.span(sep), std.mem.span(desc) }) catch "Apple SecTrust failure";
                hook(data, msg);
            } else if (builtin.output_mode == .Lib) {
                Curl_failf(data, "Apple SecTrust failure %ld%s%s", @as(c_long, code), sep, desc);
            }
            if (code == errSecIncompleteCertRevocationCheck)
                result = CURLE_SSL_INVALIDCERTSTATUS;
        }

        return result;
    }

    pub fn Curl_vtls_apple_verifies_ocsp(cf: ?*CurlCfilter, data: ?*anyopaque) callconv(.c) bool {
        _ = cf;
        _ = data;
        return true;
    }
};

comptime {
    if (builtin.os.tag.isDarwin()) {
        @export(&apple.Curl_vtls_apple_verify, .{ .name = "Curl_vtls_apple_verify" });
        @export(&apple.Curl_vtls_apple_verifies_ocsp, .{ .name = "Curl_vtls_apple_verifies_ocsp" });
    }
}

// ============================================================================
// 6. lib/vtls/schannel_verify.c — Windows Schannel certificate verification
// ============================================================================

const schannel_verify = struct {
    const DWORD = u32;
    const BOOL = i32;
    const SECURITY_STATUS = i32;
    const HCERTSTORE = ?*anyopaque;
    const HCERTCHAINENGINE = ?*anyopaque;
    const HCRYPTPROV = usize;
    const HLOCAL = ?*anyopaque;

    const SEC_E_OK: SECURITY_STATUS = 0;
    const SECPKG_ATTR_REMOTE_CERT_CONTEXT: DWORD = 0x53;
    const WINAPI_ERROR_LEN: usize = 256;
    const MAX_CAFILE_SIZE: c_long = 1024 * 1024;
    const BEGIN_CERT = "-----BEGIN CERTIFICATE-----";
    const END_CERT = "\n-----END CERTIFICATE-----";

    const PLATFORM_WINNT: c_int = 2;
    const VERSION_LESS_THAN: c_int = 0;
    const VERSION_GREATER_THAN_EQUAL: c_int = 3;

    const CERT_QUERY_OBJECT_BLOB: DWORD = 0x2;
    const CERT_QUERY_CONTENT_FLAG_CERT: DWORD = 1 << 1;
    const CERT_QUERY_FORMAT_FLAG_BASE64_ENCODED: DWORD = 1 << 2;
    const CERT_STORE_ADD_ALWAYS: DWORD = 4;
    const CERT_STORE_CREATE_NEW_FLAG: DWORD = 0x2000;
    const CERT_STORE_PROV_MEMORY: [*:0]const u8 = @ptrFromInt(2);
    const CERT_CHAIN_EXCLUSIVE_ENABLE_CA_FLAG: DWORD = 0x00000001;

    const CERT_NAME_DNS_TYPE: DWORD = 6;
    const CERT_NAME_DISABLE_IE4_UTF8_FLAG: DWORD = 0x10000;
    const CERT_NAME_SEARCH_ALL_NAMES_FLAG: DWORD = 0x2;

    const CERT_ALT_NAME_DNS_NAME: DWORD = 3;
    const CERT_ALT_NAME_IP_ADDRESS: DWORD = 8;

    const X509_ASN_ENCODING: DWORD = 0x1;
    const PKCS_7_ASN_ENCODING: DWORD = 0x10000;
    const CRYPT_DECODE_NOCOPY_FLAG: DWORD = 0x1;
    const CRYPT_DECODE_ALLOC_FLAG: DWORD = 0x8000;

    const szOID_SUBJECT_ALT_NAME2: [*:0]const u8 = "2.5.29.17";
    const szOID_PKIX_KP_SERVER_AUTH: [*:0]const u8 = "1.3.6.1.5.5.7.3.1";

    const USAGE_MATCH_TYPE_AND: DWORD = 0x0;
    const CERT_CHAIN_REVOCATION_CHECK_CHAIN: DWORD = 0x20000000;

    const CERT_TRUST_IS_NOT_TIME_VALID: DWORD = 0x1;
    const CERT_TRUST_IS_NOT_TIME_NESTED: DWORD = 0x2;
    const CERT_TRUST_IS_REVOKED: DWORD = 0x4;
    const CERT_TRUST_IS_UNTRUSTED_ROOT: DWORD = 0x20;
    const CERT_TRUST_REVOCATION_STATUS_UNKNOWN: DWORD = 0x40;
    const CERT_TRUST_IS_PARTIAL_CHAIN: DWORD = 0x10000;
    const CERT_TRUST_IS_OFFLINE_REVOCATION: DWORD = 0x1000000;

    const SEEK_SET: c_int = 0;
    const SEEK_END: c_int = 2;

    const CRYPT_DATA_BLOB = extern struct {
        cbData: DWORD,
        pbData: ?[*]u8,
    };

    const CRYPT_BIT_BLOB = extern struct {
        cbData: DWORD,
        pbData: ?[*]u8,
        cUnusedBits: DWORD,
    };

    const CRYPT_ALGORITHM_IDENTIFIER = extern struct {
        pszObjId: ?[*:0]u8,
        Parameters: CRYPT_DATA_BLOB,
    };

    const FILETIME = extern struct {
        dwLowDateTime: DWORD,
        dwHighDateTime: DWORD,
    };

    const CERT_PUBLIC_KEY_INFO = extern struct {
        Algorithm: CRYPT_ALGORITHM_IDENTIFIER,
        PublicKey: CRYPT_BIT_BLOB,
    };

    const CERT_EXTENSION = extern struct {
        pszObjId: ?[*:0]u8,
        fCritical: BOOL,
        Value: CRYPT_DATA_BLOB,
    };

    const CERT_INFO = extern struct {
        dwVersion: DWORD,
        SerialNumber: CRYPT_DATA_BLOB,
        SignatureAlgorithm: CRYPT_ALGORITHM_IDENTIFIER,
        Issuer: CRYPT_DATA_BLOB,
        NotBefore: FILETIME,
        NotAfter: FILETIME,
        Subject: CRYPT_DATA_BLOB,
        SubjectPublicKeyInfo: CERT_PUBLIC_KEY_INFO,
        IssuerUniqueId: CRYPT_BIT_BLOB,
        SubjectUniqueId: CRYPT_BIT_BLOB,
        cExtension: DWORD,
        rgExtension: ?[*]CERT_EXTENSION,
    };

    const CERT_CONTEXT = extern struct {
        dwCertEncodingType: DWORD,
        pbCertEncoded: ?[*]u8,
        cbCertEncoded: DWORD,
        pCertInfo: ?*CERT_INFO,
        hCertStore: HCERTSTORE,
    };

    const CERT_ALT_NAME_ENTRY_UNION = extern union {
        pwszDNSName: ?[*:0]const u16,
        IPAddress: CRYPT_DATA_BLOB,
    };

    const CERT_ALT_NAME_ENTRY = extern struct {
        dwAltNameChoice: DWORD,
        u: CERT_ALT_NAME_ENTRY_UNION,
    };

    const CERT_ALT_NAME_INFO = extern struct {
        cAltEntry: DWORD,
        rgAltEntry: [*]CERT_ALT_NAME_ENTRY,
    };

    const CRYPT_DECODE_PARA = extern struct {
        cbSize: DWORD,
        pfnAlloc: ?*const anyopaque,
        pfnFree: ?*const anyopaque,
    };

    const CERT_TRUST_STATUS = extern struct {
        dwErrorStatus: DWORD,
        dwInfoStatus: DWORD,
    };

    const CERT_SIMPLE_CHAIN = extern struct {
        cbSize: DWORD,
        TrustStatus: CERT_TRUST_STATUS,
        cElement: DWORD,
        rgpElement: ?*anyopaque,
        pTrustListInfo: ?*anyopaque,
        fHasRevocationFreshnessTime: BOOL,
        dwRevocationFreshnessTime: DWORD,
    };

    const CERT_CHAIN_CONTEXT = extern struct {
        cbSize: DWORD,
        TrustStatus: CERT_TRUST_STATUS,
        cChain: DWORD,
        rgpChain: [*]*CERT_SIMPLE_CHAIN,
    };

    const CERT_ENHKEY_USAGE = extern struct {
        cUsageIdentifier: DWORD,
        rgpszUsageIdentifier: *?[*:0]const u8,
    };

    const CERT_USAGE_MATCH = extern struct {
        dwType: DWORD,
        Usage: CERT_ENHKEY_USAGE,
    };

    const CERT_CHAIN_PARA = extern struct {
        cbSize: DWORD,
        RequestedUsage: CERT_USAGE_MATCH,
    };

    const CertChainEngineConfigWin7 = extern struct {
        cbSize: DWORD = 0,
        hRestrictedRoot: HCERTSTORE = null,
        hRestrictedTrust: HCERTSTORE = null,
        hRestrictedOther: HCERTSTORE = null,
        cAdditionalStore: DWORD = 0,
        rghAdditionalStore: ?*HCERTSTORE = null,
        dwFlags: DWORD = 0,
        dwUrlRetrievalTimeout: DWORD = 0,
        MaximumCachedCertificates: DWORD = 0,
        CycleDetectionModulus: DWORD = 0,
        hExclusiveRoot: HCERTSTORE = null,
        hExclusiveTrustedPeople: HCERTSTORE = null,
    };

    const CertChainEngineConfigWin8 = extern struct {
        cbSize: DWORD = 0,
        hRestrictedRoot: HCERTSTORE = null,
        hRestrictedTrust: HCERTSTORE = null,
        hRestrictedOther: HCERTSTORE = null,
        cAdditionalStore: DWORD = 0,
        rghAdditionalStore: ?*HCERTSTORE = null,
        dwFlags: DWORD = 0,
        dwUrlRetrievalTimeout: DWORD = 0,
        MaximumCachedCertificates: DWORD = 0,
        CycleDetectionModulus: DWORD = 0,
        hExclusiveRoot: HCERTSTORE = null,
        hExclusiveTrustedPeople: HCERTSTORE = null,
        dwExclusiveFlags: DWORD = 0,
    };

    const SecHandle = extern struct {
        dwLower: usize,
        dwUpper: usize,
    };

    const CurlSchannelCtxt = extern struct {
        ctxt_handle: SecHandle,
    };

    const SBuffer = extern struct {
        length: usize,
        offset: usize,
        buffer: ?[*]u8,
    };

    const SecBuffer = extern struct {
        cbBuffer: c_ulong,
        BufferType: c_ulong,
        pvBuffer: ?*anyopaque,
    };

    const SecPkgContext_StreamSizes = extern struct {
        cbHeader: c_ulong,
        cbTrailer: c_ulong,
        cbMaximumMessage: c_ulong,
        cBuffers: c_ulong,
        cbBlockSize: c_ulong,
    };

    const CurlTime = extern struct {
        tv_sec: i64,
        tv_usec: c_int,
    };

    const SchannelRenegotiateState = extern struct {
        started: bool,
        start_time: CurlTime,
        io_need: c_int,
    };

    const SchannelSslBackendData = extern struct {
        send_buffer: ?[*]u8,
        send_buffer_len: usize,
        encdata: SBuffer,
        decdata: SBuffer,
        cred: ?*anyopaque,
        ctxt: *CurlSchannelCtxt,
        shutdown_token: SecBuffer,
        shutdown_offset: usize,
        stream_sizes: SecPkgContext_StreamSizes,
        req_flags: c_ulong,
        ret_flags: c_ulong,
        recv_unrecoverable_err: c_uint,
        renegotiate_state: SchannelRenegotiateState,
        flags: c_uint,

        fn use_manual_cred_validation(self: *const SchannelSslBackendData) bool {
            return (self.flags & (1 << 4)) != 0;
        }
    };

    const SslConnectData = extern struct {
        ssl_impl: ?*const anyopaque,
        peer: SslPeer,
        alpn: ?*const anyopaque,
        backend: *SchannelSslBackendData,
    };

    // On Windows (MS bitfields ABI), `uint8_t ssl_options; uint8_t version;` is followed by
    // 2 bytes of padding before the `unsigned int` bitfield storage unit `flags`.
    const SslFilterConfigWin = extern struct {
        CApath: ?[*:0]u8,
        CAfile: ?[*:0]const u8,
        issuercert: ?[*:0]u8,
        clientcert: ?[*:0]u8,
        cipher_list: ?[*:0]u8,
        cipher_list13: ?[*:0]u8,
        signature_algorithms: ?[*:0]u8,
        pinned_key: ?[*:0]u8,
        CRLfile: ?[*:0]u8,
        cert_type: ?[*:0]u8,
        key: ?[*:0]u8,
        key_type: ?[*:0]u8,
        key_passwd: ?[*:0]u8,
        cert_blob: ?*CurlBlob,
        ca_info_blob: ?*const CurlBlob,
        issuercert_blob: ?*CurlBlob,
        key_blob: ?*CurlBlob,
        curves: ?[*:0]u8,
        version_max: u32,
        ssl_options: u8,
        version: u8,
        _pad: u16,
        flags: u32,

        fn verifyhost(self: *const SslFilterConfigWin) bool {
            return (self.flags & (1 << 1)) != 0;
        }
        fn no_partialchain(self: *const SslFilterConfigWin) bool {
            return (self.flags & (1 << 9)) != 0;
        }
        fn no_revoke(self: *const SslFilterConfigWin) bool {
            return (self.flags & (1 << 10)) != 0;
        }
        fn revoke_best_effort(self: *const SslFilterConfigWin) bool {
            return (self.flags & (1 << 11)) != 0;
        }
    };

    const SecurityFunctionTableA = extern struct {
        dwVersion: c_ulong,
        EnumerateSecurityPackagesA: ?*const anyopaque,
        QueryCredentialsAttributesA: ?*const anyopaque,
        AcquireCredentialsHandleA: ?*const anyopaque,
        FreeCredentialsHandle: ?*const anyopaque,
        Reserved2: ?*const anyopaque,
        InitializeSecurityContextA: ?*const anyopaque,
        AcceptSecurityContext: ?*const anyopaque,
        CompleteAuthToken: ?*const anyopaque,
        DeleteSecurityContext: ?*const anyopaque,
        ApplyControlToken: ?*const anyopaque,
        QueryContextAttributesA: *const fn (
            phContext: *SecHandle,
            ulAttribute: c_ulong,
            pBuffer: *anyopaque,
        ) callconv(.winapi) SECURITY_STATUS,
    };

    const NumIpData = extern struct {
        size: DWORD = 0,
        bData: [16]u8 = @splat(0),
    };

    extern var Curl_pSecFn: *SecurityFunctionTableA;
    extern "c" fn Curl_sspi_strerror(err: SECURITY_STATUS, buf: [*]u8, buflen: usize) ?[*:0]const u8;
    extern "c" fn Curl_schannel_get_cached_cert_store(cf: *CurlCfilter, data: ?*anyopaque) HCERTSTORE;
    extern "c" fn Curl_schannel_set_cached_cert_store(cf: *CurlCfilter, data: ?*anyopaque, cert_store: HCERTSTORE) bool;
    extern "c" fn Curl_ssl_cf_get_filter_config(cf: *CurlCfilter) *SslFilterConfigWin;
    extern "c" fn Curl_failf(data: ?*anyopaque, fmt: [*:0]const u8, ...) void;
    extern "c" fn Curl_infof(data: ?*anyopaque, fmt: [*:0]const u8, ...) void;

    extern "c" fn ftell(stream: *anyopaque) c_long;
    extern "c" fn fread(ptr: [*]u8, size: usize, nmemb: usize, stream: *anyopaque) usize;
    extern "c" fn ferror(stream: *anyopaque) c_int;
    extern "c" fn fclose(stream: *anyopaque) c_int;
    extern "c" fn curlx_fseek(stream: ?*anyopaque, offset: i64, whence: c_int) c_int;
    extern "c" fn curlx_winapi_strerror(err: DWORD, buf: [*]u8, buflen: usize) [*:0]const u8;
    extern "c" fn curlx_verify_windows_version(
        majorVersion: c_uint,
        minorVersion: c_uint,
        buildVersion: c_uint,
        platform: c_uint,
        condition: c_uint,
    ) bool;

    extern "kernel32" fn GetLastError() callconv(.winapi) DWORD;
    extern "kernel32" fn LocalFree(hMem: HLOCAL) callconv(.winapi) HLOCAL;

    extern "crypt32" fn CryptQueryObject(
        dwObjectType: DWORD,
        pvObject: *const anyopaque,
        dwExpectedContentTypeFlags: DWORD,
        dwExpectedFormatTypeFlags: DWORD,
        dwFlags: DWORD,
        pdwMsgAndCertEncodingType: ?*DWORD,
        pdwContentType: ?*DWORD,
        pdwFormatType: ?*DWORD,
        phCertStore: ?*HCERTSTORE,
        phMsg: ?*anyopaque,
        ppvContext: *?*const CERT_CONTEXT,
    ) callconv(.winapi) BOOL;

    extern "crypt32" fn CertAddCertificateContextToStore(
        hCertStore: HCERTSTORE,
        pCertContext: *const CERT_CONTEXT,
        dwAddDisposition: DWORD,
        ppStoreContext: ?*?*const CERT_CONTEXT,
    ) callconv(.winapi) BOOL;

    extern "crypt32" fn CertFreeCertificateContext(
        pCertContext: *const CERT_CONTEXT,
    ) callconv(.winapi) BOOL;

    extern "crypt32" fn CertGetNameStringA(
        pCertContext: *const CERT_CONTEXT,
        dwType: DWORD,
        dwFlags: DWORD,
        pvTypePara: ?*anyopaque,
        pszNameString: ?[*]u8,
        cchNameString: DWORD,
    ) callconv(.winapi) DWORD;

    extern "crypt32" fn CertFindExtension(
        pszObjId: [*:0]const u8,
        cExtensions: DWORD,
        rgExtensions: ?[*]CERT_EXTENSION,
    ) callconv(.winapi) ?*CERT_EXTENSION;

    extern "crypt32" fn CryptDecodeObjectEx(
        dwCertEncodingType: DWORD,
        lpszStructType: [*:0]const u8,
        pbEncoded: ?[*]const u8,
        cbEncoded: DWORD,
        dwFlags: DWORD,
        pDecodePara: ?*CRYPT_DECODE_PARA,
        pvStructInfo: *?*CERT_ALT_NAME_INFO,
        pcbStructInfo: *DWORD,
    ) callconv(.winapi) BOOL;

    extern "crypt32" fn CertOpenStore(
        lpszStoreProvider: [*:0]const u8,
        dwEncodingType: DWORD,
        hCryptProv: HCRYPTPROV,
        dwFlags: DWORD,
        pvPara: ?*const anyopaque,
    ) callconv(.winapi) HCERTSTORE;

    extern "crypt32" fn CertCreateCertificateChainEngine(
        pConfig: *const anyopaque,
        phChainEngine: *HCERTCHAINENGINE,
    ) callconv(.winapi) BOOL;

    extern "crypt32" fn CertGetCertificateChain(
        hChainEngine: HCERTCHAINENGINE,
        pCertContext: *const CERT_CONTEXT,
        pTime: ?*const FILETIME,
        hAdditionalStore: HCERTSTORE,
        pChainPara: *const CERT_CHAIN_PARA,
        dwFlags: DWORD,
        pvReserved: ?*anyopaque,
        ppChainContext: *?*const CERT_CHAIN_CONTEXT,
    ) callconv(.winapi) BOOL;

    extern "crypt32" fn CertFreeCertificateChainEngine(
        hChainEngine: HCERTCHAINENGINE,
    ) callconv(.winapi) void;

    extern "crypt32" fn CertCloseStore(
        hCertStore: HCERTSTORE,
        dwFlags: DWORD,
    ) callconv(.winapi) BOOL;

    extern "crypt32" fn CertFreeCertificateChain(
        pChainContext: *const CERT_CHAIN_CONTEXT,
    ) callconv(.winapi) void;

    fn c_memmem(haystack: [*]const u8, haystacklen: usize, needle: []const u8) ?[*]const u8 {
        if (needle.len == 0 or needle.len > haystacklen)
            return null;
        if (std.mem.indexOf(u8, haystack[0..haystacklen], needle)) |idx| {
            return haystack + idx;
        }
        return null;
    }

    fn isNewline(c: u8) bool {
        return c == '\r' or c == '\n';
    }

    fn add_certs_data_to_store(
        trust_store: HCERTSTORE,
        ca_buffer: [*]const u8,
        ca_buffer_size: usize,
        ca_file_text: [*:0]const u8,
        data: ?*anyopaque,
    ) c_uint {
        var result: c_uint = CURLE_OK;
        var num_certs: c_int = 0;
        var more_certs: bool = true;
        var current_ca_file_ptr: [*]const u8 = ca_buffer;
        const ca_buffer_limit: [*]const u8 = ca_buffer + ca_buffer_size;

        while (more_certs and (@intFromPtr(current_ca_file_ptr) < @intFromPtr(ca_buffer_limit))) {
            const rem = @intFromPtr(ca_buffer_limit) - @intFromPtr(current_ca_file_ptr);
            const search_len = if (rem > 0) rem - 1 else 0;
            const begin_cert_ptr = c_memmem(current_ca_file_ptr, search_len, BEGIN_CERT);
            if (begin_cert_ptr == null or !isNewline(begin_cert_ptr.?[BEGIN_CERT.len])) {
                more_certs = false;
            } else {
                const bptr = begin_cert_ptr.?;
                const end_cert_ptr = c_memmem(bptr, @intFromPtr(ca_buffer_limit) - @intFromPtr(bptr), END_CERT);
                if (end_cert_ptr == null) {
                    Curl_failf(data, "schannel: CA file '%s' is not correctly formatted", ca_file_text);
                    result = CURLE_SSL_CACERT_BADFILE;
                    more_certs = false;
                } else {
                    const eptr = end_cert_ptr.?;
                    const cert_size: DWORD = @intCast((@intFromPtr(eptr) + END_CERT.len) - @intFromPtr(bptr));
                    var cert_blob = CRYPT_DATA_BLOB{
                        .cbData = cert_size,
                        .pbData = @constCast(bptr),
                    };
                    var cert_context: ?*const CERT_CONTEXT = null;
                    if (CryptQueryObject(
                        CERT_QUERY_OBJECT_BLOB,
                        &cert_blob,
                        CERT_QUERY_CONTENT_FLAG_CERT,
                        CERT_QUERY_FORMAT_FLAG_BASE64_ENCODED,
                        0,
                        null,
                        null,
                        null,
                        null,
                        null,
                        &cert_context,
                    ) == 0) {
                        var buffer: [WINAPI_ERROR_LEN]u8 = undefined;
                        Curl_failf(
                            data,
                            "schannel: failed to extract certificate from CA file '%s': %s",
                            ca_file_text,
                            curlx_winapi_strerror(GetLastError(), &buffer, buffer.len),
                        );
                        result = CURLE_SSL_CACERT_BADFILE;
                        more_certs = false;
                    } else {
                        current_ca_file_ptr = bptr + cert_size;
                        if (CertAddCertificateContextToStore(
                            trust_store,
                            cert_context.?,
                            CERT_STORE_ADD_ALWAYS,
                            null,
                        ) == 0) {
                            var buffer: [WINAPI_ERROR_LEN]u8 = undefined;
                            Curl_failf(
                                data,
                                "schannel: failed to add certificate from CA file '%s' to certificate store: %s",
                                ca_file_text,
                                curlx_winapi_strerror(GetLastError(), &buffer, buffer.len),
                            );
                            result = CURLE_SSL_CACERT_BADFILE;
                            more_certs = false;
                        } else {
                            num_certs += 1;
                        }
                        _ = CertFreeCertificateContext(cert_context.?);
                    }
                }
            }
        }

        if (result == CURLE_OK) {
            if (num_certs == 0) {
                Curl_infof(data, "schannel: did not add any certificates from CA file '%s'", ca_file_text);
            } else {
                Curl_infof(data, "schannel: added %d certificate(s) from CA file '%s'", num_certs, ca_file_text);
            }
        }
        return result;
    }

    fn add_certs_file_to_store(
        trust_store: HCERTSTORE,
        ca_file: ?[*:0]const u8,
        data: ?*anyopaque,
    ) c_uint {
        const fname = ca_file orelse return CURLE_SSL_CACERT_BADFILE;
        const ca_file_handle = curlx_win32_fopen(fname, "rb") orelse {
            Curl_failf(data, "schannel: failed to open CA file '%s'", fname);
            return CURLE_SSL_CACERT_BADFILE;
        };
        defer _ = fclose(ca_file_handle);

        if (curlx_fseek(ca_file_handle, 0, SEEK_END) != 0) {
            Curl_failf(data, "schannel: failed seeking to end of CA file '%s'", fname);
            return CURLE_SSL_CACERT_BADFILE;
        }

        var ca_file_bufsize = ftell(ca_file_handle);

        if (curlx_fseek(ca_file_handle, 0, SEEK_SET) != 0) {
            Curl_failf(data, "schannel: failed seeking to beginning of CA file '%s'", fname);
            return CURLE_SSL_CACERT_BADFILE;
        }

        if (ca_file_bufsize < 0) {
            Curl_failf(data, "schannel: failed to get length of CA file '%s'", fname);
            return CURLE_SSL_CACERT_BADFILE;
        }

        if (ca_file_bufsize > MAX_CAFILE_SIZE) {
            Curl_failf(data, "schannel: CA file exceeds max size of %d bytes", @as(c_int, MAX_CAFILE_SIZE));
            return CURLE_SSL_CACERT_BADFILE;
        }

        const buf_alloc = mem.malloc(@intCast(ca_file_bufsize + 1)) orelse return CURLE_OUT_OF_MEMORY;
        defer mem.free(buf_alloc);
        const ca_file_buffer: [*]u8 = @ptrCast(buf_alloc);

        var total_bytes_read: c_long = 0;
        while (total_bytes_read < ca_file_bufsize) {
            const nread = fread(
                ca_file_buffer + @as(usize, @intCast(total_bytes_read)),
                1,
                @intCast(ca_file_bufsize - total_bytes_read),
                ca_file_handle,
            );
            if (ferror(ca_file_handle) != 0) {
                Curl_failf(data, "schannel: failed to read from CA file '%s'", fname);
                return CURLE_SSL_CACERT_BADFILE;
            }
            if (nread == 0) {
                ca_file_bufsize = total_bytes_read;
            } else {
                total_bytes_read += @intCast(nread);
            }
        }

        const final_size: usize = @intCast(ca_file_bufsize);
        ca_file_buffer[final_size] = 0;

        return add_certs_data_to_store(trust_store, ca_file_buffer, final_size, fname, data);
    }

    fn cert_get_name_string(
        data: ?*anyopaque,
        cert_context: *CERT_CONTEXT,
        host_names: ?[*]u8,
        length: DWORD,
        alt_name_info: ?*CERT_ALT_NAME_INFO,
        Win8_compat: bool,
    ) DWORD {
        if (Win8_compat) {
            const name_flags: DWORD = CERT_NAME_DISABLE_IE4_UTF8_FLAG | CERT_NAME_SEARCH_ALL_NAMES_FLAG;
            return CertGetNameStringA(
                cert_context,
                CERT_NAME_DNS_TYPE,
                name_flags,
                null,
                host_names,
                length,
            );
        }

        const ani = alt_name_info orelse return 0;
        const compute_content = (host_names != null and length != 0);

        var actual_length: DWORD = 1;
        if (compute_content) {
            host_names.?[0] = 0;
        }
        var current_pos: usize = 0;

        var i: DWORD = 0;
        while (i < ani.cAltEntry) : (i += 1) {
            const entry = &ani.rgAltEntry[i];
            if (entry.dwAltNameChoice != CERT_ALT_NAME_DNS_NAME)
                continue;
            if (entry.u.pwszDNSName == null) {
                Curl_infof(data, "schannel: Empty DNS name.");
                continue;
            }
            const dns_w = entry.u.pwszDNSName.?;
            var wlen: usize = 0;
            while (dns_w[wlen] != 0) : (wlen += 1) {}
            const current_length = wlen + 1;
            if (!compute_content) {
                actual_length += @intCast(current_length);
                continue;
            }
            if ((actual_length + current_length) > length) {
                Curl_failf(data, "schannel: Not enough memory to list all hostnames.");
                break;
            }
            var j: usize = 0;
            while (j < wlen) : (j += 1) {
                host_names.?[current_pos] = @truncate(dns_w[j]);
                current_pos += 1;
            }
            host_names.?[current_pos] = 0;
            current_pos += 1;
            actual_length += @intCast(current_length);
        }
        if (compute_content) {
            host_names.?[current_pos] = 0;
        }
        return actual_length;
    }

    fn get_num_host_info(ip_blob: *NumIpData, hostname: [*:0]const u8) bool {
        var ia: [4]u8 = undefined;
        if (curlx_time_net.curlx_inet_pton(AF_INET, hostname, &ia) != 0) {
            ip_blob.size = 4;
            @memcpy(ip_blob.bData[0..4], &ia);
            return true;
        }
        var ia6: [16]u8 = undefined;
        if (curlx_time_net.curlx_inet_pton(AF_INET6, hostname, &ia6) != 0) {
            ip_blob.size = 16;
            @memcpy(ip_blob.bData[0..16], &ia6);
            return true;
        }
        return false;
    }

    fn get_alt_name_info(
        data: ?*anyopaque,
        ctx: ?*const CERT_CONTEXT,
        alt_name_info: *?*CERT_ALT_NAME_INFO,
        alt_name_info_size: *DWORD,
    ) bool {
        const cert_ctx = ctx orelse {
            Curl_failf(data, "schannel: Null certificate context.");
            return false;
        };
        const cert_info = cert_ctx.pCertInfo orelse {
            Curl_failf(data, "schannel: Null certificate info.");
            return false;
        };
        const extension = CertFindExtension(
            szOID_SUBJECT_ALT_NAME2,
            cert_info.cExtension,
            cert_info.rgExtension,
        ) orelse {
            Curl_failf(data, "schannel: CertFindExtension() returned no extension.");
            return false;
        };

        var decode_para = CRYPT_DECODE_PARA{
            .cbSize = @sizeOf(CRYPT_DECODE_PARA),
            .pfnAlloc = null,
            .pfnFree = null,
        };

        if (CryptDecodeObjectEx(
            X509_ASN_ENCODING | PKCS_7_ASN_ENCODING,
            szOID_SUBJECT_ALT_NAME2,
            extension.Value.pbData,
            extension.Value.cbData,
            CRYPT_DECODE_ALLOC_FLAG | CRYPT_DECODE_NOCOPY_FLAG,
            &decode_para,
            alt_name_info,
            alt_name_info_size,
        ) == 0) {
            Curl_failf(data, "schannel: CryptDecodeObjectEx() returned no alternate name information.");
            return false;
        }
        return true;
    }

    pub fn Curl_verify_host(cf: *CurlCfilter, data: ?*anyopaque) callconv(.c) c_uint {
        var result: c_uint = CURLE_PEER_FAILED_VERIFICATION;
        const connssl: *SslConnectData = @ptrCast(@alignCast(cf.ctx.?));
        var pCertContextServer: ?*CERT_CONTEXT = null;
        var cert_hostname_buff: ?[*]u8 = null;
        var cert_hostname_buff_index: usize = 0;
        const conn_hostname = connssl.peer.origin.hostname;
        const hostlen = std.mem.len(conn_hostname);
        var len: DWORD = 0;
        var actual_len: DWORD = 0;
        var alt_name_info: ?*CERT_ALT_NAME_INFO = null;
        var alt_name_info_size: DWORD = 0;
        var ip_blob = NumIpData{};

        defer {
            if (alt_name_info) |ani| _ = LocalFree(@ptrCast(ani));
            if (cert_hostname_buff) |b| mem.free(b);
            if (pCertContextServer) |c| _ = CertFreeCertificateContext(c);
        }

        const sspi_status = Curl_pSecFn.QueryContextAttributesA(
            &connssl.backend.ctxt.ctxt_handle,
            SECPKG_ATTR_REMOTE_CERT_CONTEXT,
            @ptrCast(&pCertContextServer),
        );

        if (sspi_status != SEC_E_OK or pCertContextServer == null) {
            var buffer: [WINAPI_ERROR_LEN]u8 = undefined;
            Curl_failf(
                data,
                "schannel: Failed to read remote certificate context: %s",
                Curl_sspi_strerror(sspi_status, &buffer, buffer.len),
            );
            return result;
        }

        const Win8_compat = curlx_verify_windows_version(
            6,
            2,
            0,
            PLATFORM_WINNT,
            VERSION_GREATER_THAN_EQUAL,
        );
        if (get_num_host_info(&ip_blob, conn_hostname) or !Win8_compat) {
            if (!get_alt_name_info(data, pCertContextServer, &alt_name_info, &alt_name_info_size)) {
                return result;
            }
        }

        if (ip_blob.size != 0 and alt_name_info != null) {
            const ani = alt_name_info.?;
            var i: DWORD = 0;
            while (i < ani.cAltEntry) : (i += 1) {
                const entry = &ani.rgAltEntry[i];
                if (entry.dwAltNameChoice == CERT_ALT_NAME_IP_ADDRESS) {
                    if (entry.u.IPAddress.cbData == ip_blob.size) {
                        if (entry.u.IPAddress.pbData) |pb| {
                            if (std.mem.eql(u8, pb[0..ip_blob.size], ip_blob.bData[0..ip_blob.size])) {
                                result = CURLE_OK;
                                Curl_infof(
                                    data,
                                    "schannel: connection hostname (%s) matched cert's IP address!",
                                    conn_hostname,
                                );
                                break;
                            }
                        }
                    }
                }
            }
        } else {
            len = cert_get_name_string(data, pCertContextServer.?, null, 0, alt_name_info, Win8_compat);
            if (len == 0) {
                Curl_failf(
                    data,
                    "schannel: CertGetNameString() returned no certificate name information",
                );
                return result;
            }

            const raw_buf = mem.malloc(len) orelse return CURLE_OUT_OF_MEMORY;
            cert_hostname_buff = @ptrCast(raw_buf);
            actual_len = cert_get_name_string(
                data,
                pCertContextServer.?,
                cert_hostname_buff,
                len,
                alt_name_info,
                Win8_compat,
            );

            if (actual_len != len) {
                Curl_failf(
                    data,
                    "schannel: CertGetNameString() returned certificate name information of unexpected size",
                );
                return result;
            }

            const hbuf = cert_hostname_buff.?;
            while (cert_hostname_buff_index < len and
                hbuf[cert_hostname_buff_index] != 0 and
                result == CURLE_PEER_FAILED_VERIFICATION)
            {
                const current_name: [*:0]const u8 = @ptrCast(hbuf + cert_hostname_buff_index);
                const cert_hostname = mem.strdup(current_name);
                if (cert_hostname == null) {
                    result = CURLE_OUT_OF_MEMORY;
                } else {
                    const chost = cert_hostname.?;
                    const chost_len = std.mem.len(chost);
                    if (Curl_cert_hostcheck(chost, chost_len, conn_hostname, hostlen)) {
                        Curl_infof(
                            data,
                            "schannel: connection hostname (%s) validated against certificate name (%s)",
                            conn_hostname,
                            chost,
                        );
                        result = CURLE_OK;
                    } else {
                        Curl_infof(
                            data,
                            "schannel: connection hostname (%s) did not match against certificate name (%s)",
                            conn_hostname,
                            chost,
                        );
                        cert_hostname_buff_index += std.mem.len(current_name) + 1;
                        result = CURLE_PEER_FAILED_VERIFICATION;
                    }
                    mem.free(@ptrCast(chost));
                }
            }

            if (result == CURLE_PEER_FAILED_VERIFICATION) {
                Curl_failf(
                    data,
                    "schannel: CertGetNameString() failed to match connection hostname (%s) against server certificate names",
                    conn_hostname,
                );
            } else if (result != CURLE_OK) {
                Curl_failf(data, "schannel: server certificate name verification failed");
            }
        }

        return result;
    }

    pub fn Curl_verify_certificate(cf: *CurlCfilter, data: ?*anyopaque) callconv(.c) c_uint {
        const connssl: *SslConnectData = @ptrCast(@alignCast(cf.ctx.?));
        const conn_config = Curl_ssl_cf_get_filter_config(cf);
        var result: c_uint = CURLE_OK;
        var pCertContextServer: ?*CERT_CONTEXT = null;
        var pChainContext: ?*const CERT_CHAIN_CONTEXT = null;
        var cert_chain_engine: HCERTCHAINENGINE = null;
        var trust_store: HCERTSTORE = null;
        var own_trust_store: HCERTSTORE = null;

        defer {
            if (cert_chain_engine) |eng| CertFreeCertificateChainEngine(eng);
            if (own_trust_store) |st| _ = CertCloseStore(st, 0);
            if (pChainContext) |cc| CertFreeCertificateChain(cc);
            if (pCertContextServer) |cs| _ = CertFreeCertificateContext(cs);
        }

        const sspi_status = Curl_pSecFn.QueryContextAttributesA(
            &connssl.backend.ctxt.ctxt_handle,
            SECPKG_ATTR_REMOTE_CERT_CONTEXT,
            @ptrCast(&pCertContextServer),
        );

        if (sspi_status != SEC_E_OK or pCertContextServer == null) {
            var buffer: [WINAPI_ERROR_LEN]u8 = undefined;
            Curl_failf(
                data,
                "schannel: Failed to read remote certificate context: %s",
                Curl_sspi_strerror(sspi_status, &buffer, buffer.len),
            );
            result = CURLE_PEER_FAILED_VERIFICATION;
        }

        if (result == CURLE_OK and
            (conn_config.CAfile != null or conn_config.ca_info_blob != null) and
            connssl.backend.use_manual_cred_validation())
        {
            if (curlx_verify_windows_version(6, 1, 0, PLATFORM_WINNT, VERSION_LESS_THAN)) {
                Curl_failf(
                    data,
                    "schannel: this version of Windows is too old to support certificate verification via CA bundle file.",
                );
                result = CURLE_SSL_CACERT_BADFILE;
            } else {
                trust_store = Curl_schannel_get_cached_cert_store(cf, data);
                if (trust_store != null) {
                    Curl_infof(data, "schannel: reusing certificate store from cache");
                } else {
                    trust_store = CertOpenStore(
                        CERT_STORE_PROV_MEMORY,
                        0,
                        0,
                        CERT_STORE_CREATE_NEW_FLAG,
                        null,
                    );
                    if (trust_store == null) {
                        var buffer: [WINAPI_ERROR_LEN]u8 = undefined;
                        Curl_failf(
                            data,
                            "schannel: failed to create certificate store: %s",
                            curlx_winapi_strerror(GetLastError(), &buffer, buffer.len),
                        );
                        result = CURLE_SSL_CACERT_BADFILE;
                    } else {
                        own_trust_store = trust_store;
                        if (conn_config.ca_info_blob) |ca_info_blob| {
                            if (ca_info_blob.data) |bdata| {
                                result = add_certs_data_to_store(
                                    trust_store,
                                    bdata,
                                    ca_info_blob.len,
                                    "(memory blob)",
                                    data,
                                );
                            }
                        } else {
                            result = add_certs_file_to_store(trust_store, conn_config.CAfile, data);
                        }
                        if (result == CURLE_OK) {
                            if (Curl_schannel_set_cached_cert_store(cf, data, trust_store)) {
                                own_trust_store = null;
                            }
                        }
                    }
                }
            }

            if (result == CURLE_OK) {
                var engine_config = CertChainEngineConfigWin8{
                    .hExclusiveRoot = trust_store,
                };
                if (curlx_verify_windows_version(
                    6,
                    2,
                    0,
                    PLATFORM_WINNT,
                    VERSION_GREATER_THAN_EQUAL,
                ) and !conn_config.no_partialchain()) {
                    engine_config.cbSize = @sizeOf(CertChainEngineConfigWin8);
                    engine_config.dwExclusiveFlags = CERT_CHAIN_EXCLUSIVE_ENABLE_CA_FLAG;
                } else {
                    engine_config.cbSize = @sizeOf(CertChainEngineConfigWin7);
                }

                if (CertCreateCertificateChainEngine(&engine_config, &cert_chain_engine) == 0) {
                    var buffer: [WINAPI_ERROR_LEN]u8 = undefined;
                    Curl_failf(
                        data,
                        "schannel: failed to create certificate chain engine: %s",
                        curlx_winapi_strerror(GetLastError(), &buffer, buffer.len),
                    );
                    result = CURLE_SSL_CACERT_BADFILE;
                }
            }
        }

        if (result == CURLE_OK) {
            var serverAuthOID: ?[*:0]const u8 = szOID_PKIX_KP_SERVER_AUTH;
            var ChainPara = CERT_CHAIN_PARA{
                .cbSize = @sizeOf(CERT_CHAIN_PARA),
                .RequestedUsage = .{
                    .dwType = USAGE_MATCH_TYPE_AND,
                    .Usage = .{
                        .cUsageIdentifier = 1,
                        .rgpszUsageIdentifier = &serverAuthOID,
                    },
                },
            };

            const chain_flags: DWORD = if (conn_config.no_revoke()) 0 else CERT_CHAIN_REVOCATION_CHECK_CHAIN;
            if (CertGetCertificateChain(
                cert_chain_engine,
                pCertContextServer.?,
                null,
                pCertContextServer.?.hCertStore,
                &ChainPara,
                chain_flags,
                null,
                &pChainContext,
            ) == 0) {
                var buffer: [WINAPI_ERROR_LEN]u8 = undefined;
                Curl_failf(
                    data,
                    "schannel: failed to get the certificate chain: %s",
                    curlx_winapi_strerror(GetLastError(), &buffer, buffer.len),
                );
                pChainContext = null;
                result = CURLE_PEER_FAILED_VERIFICATION;
            }

            if (result == CURLE_OK) {
                const pSimpleChain = pChainContext.?.rgpChain[0];
                var dwTrustErrorMask: DWORD = ~CERT_TRUST_IS_NOT_TIME_NESTED;
                dwTrustErrorMask &= pSimpleChain.TrustStatus.dwErrorStatus;

                if (conn_config.revoke_best_effort()) {
                    dwTrustErrorMask &= ~(CERT_TRUST_REVOCATION_STATUS_UNKNOWN | CERT_TRUST_IS_OFFLINE_REVOCATION);
                }

                if (dwTrustErrorMask != 0) {
                    if ((dwTrustErrorMask & CERT_TRUST_IS_REVOKED) != 0) {
                        Curl_failf(
                            data,
                            "schannel: trust for this certificate or one of the certificates in the certificate chain has been revoked",
                        );
                    } else if ((dwTrustErrorMask & CERT_TRUST_IS_PARTIAL_CHAIN) != 0) {
                        Curl_failf(data, "schannel: the certificate chain is incomplete");
                    } else if ((dwTrustErrorMask & CERT_TRUST_IS_UNTRUSTED_ROOT) != 0) {
                        Curl_failf(
                            data,
                            "schannel: the certificate or certificate chain is based on an untrusted root",
                        );
                    } else if ((dwTrustErrorMask & CERT_TRUST_IS_NOT_TIME_VALID) != 0) {
                        Curl_failf(
                            data,
                            "schannel: this certificate or one of the certificates in the certificate chain is not time valid",
                        );
                    } else if ((dwTrustErrorMask & CERT_TRUST_REVOCATION_STATUS_UNKNOWN) != 0) {
                        Curl_failf(data, "schannel: the revocation status is unknown");
                    } else {
                        Curl_failf(data, "schannel: error 0x%08lx", @as(c_ulong, dwTrustErrorMask));
                    }
                    result = CURLE_PEER_FAILED_VERIFICATION;
                }
            }
        }

        if (result == CURLE_OK) {
            if (conn_config.verifyhost()) {
                result = Curl_verify_host(cf, data);
            }
        }

        return result;
    }
};

comptime {
    if (builtin.os.tag == .windows and backend_options.ssl == .schannel) {
        @export(&schannel_verify.Curl_verify_host, .{ .name = "Curl_verify_host" });
        @export(&schannel_verify.Curl_verify_certificate, .{ .name = "Curl_verify_certificate" });
    }
}

// ============================================================================
// Unit Tests
// ============================================================================

test "Curl_cert_hostcheck exact, wildcard, trailing dots, and IP literals" {
    const TestCase = struct {
        host: []const u8,
        pattern: []const u8,
        expected: bool,
    };

    const cases = [_]TestCase{
        .{ .host = "", .pattern = "", .expected = false },
        .{ .host = "a", .pattern = "", .expected = false },
        .{ .host = "", .pattern = "b", .expected = false },
        .{ .host = "a", .pattern = "b", .expected = false },
        .{ .host = "ba", .pattern = "bb", .expected = false },
        .{ .host = "\xff", .pattern = "\xff", .expected = true },
        .{ .host = "aa.aa.aa", .pattern = "aa.aa.bb", .expected = false },
        .{ .host = "aa.aa.aa", .pattern = "aa.aa.aa", .expected = true },
        .{ .host = "aa.aa.aa", .pattern = "*.aa.bb", .expected = false },
        .{ .host = "aa.aa.aa", .pattern = "*.aa.aa", .expected = true },
        .{ .host = "192.168.0.1", .pattern = "192.168.0.1", .expected = true },
        .{ .host = "192.168.0.1", .pattern = "*.168.0.1", .expected = false },
        .{ .host = "192.168.0.1", .pattern = "*.0.1", .expected = false },
        .{ .host = "h.ello", .pattern = "*.ello", .expected = false },
        .{ .host = "h.ello.", .pattern = "*.ello", .expected = false },
        .{ .host = "h.ello", .pattern = "*.ello.", .expected = false },
        .{ .host = "h.e.llo", .pattern = "*.e.llo", .expected = true },
        .{ .host = "h.e.llo", .pattern = " *.e.llo", .expected = false },
        .{ .host = " h.e.llo", .pattern = "*.e.llo", .expected = true },
        .{ .host = "h.e.llo.", .pattern = "*.e.llo", .expected = true },
        .{ .host = "h.e.llo", .pattern = "*.e.llo.", .expected = true },
        .{ .host = ".h.e.llo", .pattern = "*.e.llo.", .expected = false },
        .{ .host = "h.e.llo", .pattern = "*.*.llo.", .expected = false },
        .{ .host = "h.e.llo", .pattern = "h.*.llo.", .expected = false },
        .{ .host = "h.e.llo", .pattern = "h.e.*", .expected = false },
        .{ .host = "hello", .pattern = "*.ello", .expected = false },
        .{ .host = "hello", .pattern = "**", .expected = false },
        .{ .host = "bar.foo.example.com", .pattern = "*.example.com", .expected = false },
        .{ .host = "foo.example.com", .pattern = "*.example.com", .expected = true },
        .{ .host = "baz.example.net", .pattern = "b*z.example.net", .expected = false },
        .{ .host = "foobaz.example.net", .pattern = "*baz.example.net", .expected = false },
        .{ .host = "buzz.example.net", .pattern = "b*.example.net", .expected = false },
        .{ .host = "foo.example.com", .pattern = "*.eXample.Com", .expected = true },
        .{ .host = "foo.example.com.", .pattern = "*.example.com", .expected = true },
        .{ .host = "foo.example.com", .pattern = "*.example.com.", .expected = true },
        .{ .host = "foo.example.com.", .pattern = "foo.example.com", .expected = true },
        .{ .host = "foo.example.com", .pattern = "foo.example.com.", .expected = true },
        .{ .host = "xn--l8j.example.local", .pattern = "x*.example.local", .expected = false },
        .{ .host = "xn--l8j.example.net", .pattern = "*.example.net", .expected = true },
        .{ .host = "xn--l8j.example.net", .pattern = "*j.example.net", .expected = false },
        .{ .host = "xn--l8j.example.net", .pattern = "xn--l8j.example.net", .expected = true },
        .{ .host = "xn--l8j.example.net", .pattern = "xn--l8j.*.net", .expected = false },
        .{ .host = "xl8j.example.net", .pattern = "*.example.net", .expected = true },
        .{ .host = "fe80::3285:a9ff:fe46:b619", .pattern = "*.a9ff:fe46:b619", .expected = false },
        .{ .host = "fe80::3285:a9ff:fe46:b619", .pattern = "*::3285:a9ff:fe46:b619", .expected = false },
        .{ .host = "fe80::3285:a9ff:fe46:b619", .pattern = "fe80::3285:a9ff:fe46:b619", .expected = true },
        // Embedded NULs in pattern or hostname
        .{ .host = "foo", .pattern = "foo\x00bar", .expected = false },
        .{ .host = "foo.bar", .pattern = "foo\x00bar", .expected = false },
    };

    for (cases) |tc| {
        var host_buf: [64]u8 = @splat(0);
        var pat_buf: [64]u8 = @splat(0);
        @memcpy(host_buf[0..tc.host.len], tc.host);
        @memcpy(pat_buf[0..tc.pattern.len], tc.pattern);
        const actual = Curl_cert_hostcheck(&pat_buf, tc.pattern.len, &host_buf, tc.host.len);
        try std.testing.expectEqual(tc.expected, actual);
    }
}

test "Curl_cipher_suite_lookup_id, walk_str, and get_str" {
    try std.testing.expectEqual(@as(u16, 0x1301), Curl_cipher_suite_lookup_id("TLS_AES_128_GCM_SHA256", "TLS_AES_128_GCM_SHA256".len));
    try std.testing.expectEqual(@as(u16, 0x1302), Curl_cipher_suite_lookup_id("TLS_AES_256_GCM_SHA384", "TLS_AES_256_GCM_SHA384".len));
    try std.testing.expectEqual(@as(u16, 0x1303), Curl_cipher_suite_lookup_id("TLS_CHACHA20_POLY1305_SHA256", "TLS_CHACHA20_POLY1305_SHA256".len));
    try std.testing.expectEqual(@as(u16, 0x1305), Curl_cipher_suite_lookup_id("TLS_AES_128_CCM_8_SHA256", "TLS_AES_128_CCM_8_SHA256".len));

    // OpenSSL and IANA names for the same cipher suite
    try std.testing.expectEqual(@as(u16, 0xC02F), Curl_cipher_suite_lookup_id("ECDHE-RSA-AES128-GCM-SHA256", "ECDHE-RSA-AES128-GCM-SHA256".len));
    try std.testing.expectEqual(@as(u16, 0xC02F), Curl_cipher_suite_lookup_id("TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256", "TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256".len));
    try std.testing.expectEqual(@as(u16, 0xC02F), Curl_cipher_suite_lookup_id("ecdhe-rsa-aes128-gcm-sha256", "ecdhe-rsa-aes128-gcm-sha256".len));
    try std.testing.expectEqual(@as(u16, 0), Curl_cipher_suite_lookup_id("INVALID-CIPHER-NAME", "INVALID-CIPHER-NAME".len));

    var buf: [64]u8 = undefined;
    try std.testing.expectEqual(@as(c_int, 0), Curl_cipher_suite_get_str(0xC02F, &buf, buf.len, true));
    try std.testing.expectEqualStrings("TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256", std.mem.sliceTo(&buf, 0));

    try std.testing.expectEqual(@as(c_int, 0), Curl_cipher_suite_get_str(0xC02F, &buf, buf.len, false));
    try std.testing.expectEqualStrings("ECDHE-RSA-AES128-GCM-SHA256", std.mem.sliceTo(&buf, 0));

    try std.testing.expectEqual(@as(c_int, -1), Curl_cipher_suite_get_str(0xFFFF, &buf, buf.len, true));
    try std.testing.expectEqualStrings("TLS_UNKNOWN_0xffff", std.mem.sliceTo(&buf, 0));

    // Walk cipher suite list separated by ':', ',', ';', ' ', '\t'
    const list_str: [*:0]const u8 = " :TLS_AES_128_GCM_SHA256,ECDHE-RSA-AES128-GCM-SHA256;\tAES256-SHA ";
    var p: ?[*:0]const u8 = list_str;
    var end: ?[*:0]const u8 = null;

    try std.testing.expectEqual(@as(u16, 0x1301), Curl_cipher_suite_walk_str(&p, &end));
    p = end;
    try std.testing.expectEqual(@as(u16, 0xC02F), Curl_cipher_suite_walk_str(&p, &end));
    p = end;
    try std.testing.expectEqual(@as(u16, 0x0035), Curl_cipher_suite_walk_str(&p, &end));
    p = end;
    try std.testing.expectEqual(@as(u16, 0), Curl_cipher_suite_walk_str(&p, &end));
}

test "Curl_ssl_session_pack and Curl_ssl_session_unpack round-trip" {
    var ticket = [_]u8{ 0xDE, 0xAD, 0xBE, 0xEF, 0x01, 0x02, 0x03 };
    var quic_tp = [_]u8{ 0xAA, 0xBB, 0xCC };
    const alpn_lit: [*:0]const u8 = "h2";

    var session = std.mem.zeroes(CurlSslSession);
    session.sdata = &ticket;
    session.sdata_len = ticket.len;
    session.valid_until = 1700000000;
    session.ietf_tls_id = 0x0304;
    session.alpn = @constCast(alpn_lit);
    session.earlydata_max = 16384;
    session.quic_tp = &quic_tp;
    session.quic_tp_len = quic_tp.len;
    session.setSectrustVerified(true);

    var dbuf: containers.dynbuf = undefined;
    curlx_dyn_init(&dbuf, 64 * 1024);
    defer curlx_dyn_free(&dbuf);

    try std.testing.expectEqual(CURLE_OK, Curl_ssl_session_pack(null, &session, &dbuf));
    const packed_ptr = curlx_dyn_uptr(&dbuf) orelse return error.UnexpectedNull;
    const packed_len = curlx_dyn_len(&dbuf);
    try std.testing.expect(packed_len > 0);

    var unpacked: ?*CurlSslSession = null;
    try std.testing.expectEqual(CURLE_OK, Curl_ssl_session_unpack(null, packed_ptr, packed_len, &unpacked));
    defer destroyUnpackedSession(unpacked);

    const u = unpacked orelse return error.UnexpectedNull;
    try std.testing.expectEqual(ticket.len, u.sdata_len);
    try std.testing.expectEqualSlices(u8, &ticket, u.sdata.?[0..u.sdata_len]);
    try std.testing.expectEqual(@as(i64, 1700000000), u.valid_until);
    try std.testing.expectEqual(@as(c_int, 0x0304), u.ietf_tls_id);
    try std.testing.expectEqualStrings("h2", std.mem.sliceTo(u.alpn.?, 0));
    try std.testing.expectEqual(@as(usize, 16384), u.earlydata_max);
    try std.testing.expectEqual(quic_tp.len, u.quic_tp_len);
    try std.testing.expectEqualSlices(u8, &quic_tp, u.quic_tp.?[0..u.quic_tp_len]);
    try std.testing.expect(u.isSectrustVerified());

    // Negative valid_until rejected
    session.valid_until = -1;
    try std.testing.expectEqual(CURLE_BAD_FUNCTION_ARGUMENT, Curl_ssl_session_pack(null, &session, &dbuf));

    // Invalid version byte rejected
    const bad_buf = [_]u8{ 0x99, 0x00 };
    var bad_out: ?*CurlSslSession = null;
    try std.testing.expectEqual(CURLE_READ_ERROR, Curl_ssl_session_unpack(null, &bad_buf, bad_buf.len, &bad_out));
    try std.testing.expect(bad_out == null);
}

test "Curl_tls_keylog write_line and write" {
    const c_stdio = struct {
        extern "c" fn fread(ptr: [*]u8, size: usize, nmemb: usize, stream: *anyopaque) usize;
        extern "c" fn remove(pathname: [*:0]const u8) c_int;
    };

    try std.testing.expect(!Curl_tls_keylog_enabled());
    try std.testing.expect(!Curl_tls_keylog_write_line("CLIENT_RANDOM 00 11"));

    const path_cstr: [*:0]const u8 = ".zig-cache/test_sslkeylog.txt";
    _ = c_stdio.remove(path_cstr);
    defer _ = c_stdio.remove(path_cstr);

    const fp = keylog_c.fopen(path_cstr, "w") orelse return error.OpenFailed;
    keylog_file_fp = fp;
    keylog_file_name = @constCast(path_cstr);
    defer {
        Curl_tls_keylog_close();
        keylog_file_name = null;
    }

    try std.testing.expect(Curl_tls_keylog_enabled());
    try std.testing.expectEqualStrings(".zig-cache/test_sslkeylog.txt", std.mem.sliceTo(Curl_tls_keylog_file_name().?, 0));

    try std.testing.expect(Curl_tls_keylog_write_line("LINE_ONE"));
    try std.testing.expect(Curl_tls_keylog_write_line("LINE_TWO\n"));
    try std.testing.expect(!Curl_tls_keylog_write_line(""));

    var crand: [32]u8 = undefined;
    for (&crand, 0..) |*b, idx| b.* = @intCast(idx);
    const secret = [_]u8{ 0xAB, 0xCD, 0xEF, 0x01 };
    try std.testing.expect(Curl_tls_keylog_write("CLIENT_RANDOM", &crand, crand.len, &secret, secret.len));
    try std.testing.expect(!Curl_tls_keylog_write("CLIENT_RANDOM", &crand, 16, &secret, secret.len));

    Curl_tls_keylog_close();
    try std.testing.expect(!Curl_tls_keylog_enabled());

    const rfp = keylog_c.fopen(path_cstr, "r") orelse return error.OpenFailed;
    defer _ = keylog_c.fclose(rfp);
    var rbuf: [512]u8 = undefined;
    const nread = c_stdio.fread(&rbuf, 1, rbuf.len, rfp);
    const content = rbuf[0..nread];
    try std.testing.expect(std.mem.startsWith(u8, content, "LINE_ONE\nLINE_TWO\nCLIENT_RANDOM 00010203"));
    try std.testing.expect(std.mem.endsWith(u8, content, " ABCDEF01\n"));
}

const apple_test_harness = struct {
    const ObjKind = enum {
        string,
        array,
        ssl_policy,
        rev_policy,
        data,
        cert,
        trust,
        err,
    };

    const CfObj = struct {
        kind: ObjKind = .string,
        refcount: isize = 0,
        str_buf: [128]u8 = @splat(0),
        str_len: usize = 0,
        items: [16]*CfObj = undefined,
        item_count: usize = 0,
        retains_items: bool = false,
        ssl_server: bool = false,
        ssl_host: ?*CfObj = null,
        rev_flags: apple.CFOptionFlags = 0,
        data_buf: [128]u8 = @splat(0),
        data_len: usize = 0,
        err_code: apple.CFIndex = 0,
        err_desc: []const u8 = "",
    };

    var objs: [64]CfObj = undefined;
    var obj_count: usize = 0;
    var refcount_underflow: bool = false;
    var callbacks_sentinel: u8 = 0xAA;

    const BIT_VERIFYHOST: @FieldType(apple.SslFilterConfig, "flags") = 1 << 1;
    const BIT_NO_REVOKE: @FieldType(apple.SslFilterConfig, "flags") = 1 << 10;

    var conn_config: apple.SslFilterConfig = std.mem.zeroes(apple.SslFilterConfig);
    var return_null_config: bool = false;
    var cert_create_calls: usize = 0;
    var fail_cert_create_at: ?usize = null;
    var trust_create_status: apple.OSStatus = apple.noErr;
    var ocsp_set_status: apple.OSStatus = apple.noErr;
    var eval_succeeds: bool = true;
    var eval_error_code: ?apple.CFIndex = null;
    var eval_error_desc: ?[]const u8 = null;

    var last_ssl_policy_server: bool = false;
    var last_ssl_policy_has_host: bool = false;
    var last_ssl_policy_host_buf: [128]u8 = @splat(0);
    var last_ssl_policy_host_len: usize = 0;
    var revocation_policy_count: usize = 0;
    var last_revocation_flags: apple.CFOptionFlags = 0;
    var trust_policy_count: usize = 0;
    var trust_cert_count: usize = 0;
    var ocsp_set_called: bool = false;
    var last_ocsp_buf: [128]u8 = @splat(0);
    var last_ocsp_len: usize = 0;
    var last_failf_buf: [256]u8 = @splat(0);
    var last_failf_len: usize = 0;

    fn reset() void {
        obj_count = 0;
        refcount_underflow = false;
        conn_config = std.mem.zeroes(apple.SslFilterConfig);
        return_null_config = false;
        cert_create_calls = 0;
        fail_cert_create_at = null;
        trust_create_status = apple.noErr;
        ocsp_set_status = apple.noErr;
        eval_succeeds = true;
        eval_error_code = null;
        eval_error_desc = null;

        last_ssl_policy_server = false;
        last_ssl_policy_has_host = false;
        last_ssl_policy_host_buf = @splat(0);
        last_ssl_policy_host_len = 0;
        revocation_policy_count = 0;
        last_revocation_flags = 0;
        trust_policy_count = 0;
        trust_cert_count = 0;
        ocsp_set_called = false;
        last_ocsp_buf = @splat(0);
        last_ocsp_len = 0;
        last_failf_buf = @splat(0);
        last_failf_len = 0;
    }

    fn allocObj(kind: ObjKind) ?*CfObj {
        if (obj_count >= objs.len) return null;
        const o = &objs[obj_count];
        obj_count += 1;
        o.* = .{
            .kind = kind,
            .refcount = 1,
        };
        return o;
    }

    fn fromOpaque(ptr: *const anyopaque) *CfObj {
        return @ptrCast(@alignCast(@constCast(ptr)));
    }

    fn releaseObj(o: *CfObj) void {
        if (o.refcount <= 0) {
            refcount_underflow = true;
            return;
        }
        o.refcount -= 1;
        if (o.refcount == 0 and o.kind == .array and o.retains_items) {
            for (o.items[0..o.item_count]) |item| {
                releaseObj(item);
            }
        }
    }

    fn expectZeroLeaks() !void {
        try std.testing.expect(!refcount_underflow);
        try std.testing.expect(obj_count > 0);
        for (objs[0..obj_count]) |o| {
            try std.testing.expectEqual(@as(isize, 0), o.refcount);
        }
    }

    fn lastSslHost() ?[]const u8 {
        if (!last_ssl_policy_has_host) return null;
        return last_ssl_policy_host_buf[0..last_ssl_policy_host_len];
    }

    fn lastFailf() []const u8 {
        return last_failf_buf[0..last_failf_len];
    }

    fn mockGetFilterConfig(cf: *CurlCfilter) callconv(.c) ?*apple.SslFilterConfig {
        _ = cf;
        if (return_null_config) return null;
        return &conn_config;
    }

    fn mockCFStringCreateWithCString(
        alloc: ?*const anyopaque,
        c_str: [*:0]const u8,
        encoding: apple.CFStringEncoding,
    ) callconv(.c) ?apple.CFStringRef {
        _ = alloc;
        if (encoding != apple.kCFStringEncodingUTF8) return null;
        const o = allocObj(.string) orelse return null;
        const slice = std.mem.span(c_str);
        const n = @min(slice.len, o.str_buf.len);
        @memcpy(o.str_buf[0..n], slice[0..n]);
        o.str_len = n;
        return @ptrCast(o);
    }

    fn mockCFArrayCreateMutable(
        alloc: ?*const anyopaque,
        capacity: apple.CFIndex,
        callbacks: ?*const anyopaque,
    ) callconv(.c) ?apple.CFMutableArrayRef {
        _ = alloc;
        _ = capacity;
        const o = allocObj(.array) orelse return null;
        o.retains_items = (callbacks != null);
        return @ptrCast(o);
    }

    fn mockCFArrayAppendValue(arr_ref: apple.CFMutableArrayRef, val_ref: *const anyopaque) callconv(.c) void {
        const arr = fromOpaque(arr_ref);
        const val = fromOpaque(val_ref);
        if (arr.item_count < arr.items.len) {
            arr.items[arr.item_count] = val;
            arr.item_count += 1;
            if (arr.retains_items) {
                val.refcount += 1;
            }
        }
    }

    fn mockCFRelease(cf_ref: *const anyopaque) callconv(.c) void {
        releaseObj(fromOpaque(cf_ref));
    }

    fn mockCFDataCreate(
        alloc: ?*const anyopaque,
        bytes: ?[*]const u8,
        length: apple.CFIndex,
    ) callconv(.c) ?apple.CFDataRef {
        _ = alloc;
        if (length < 0) return null;
        const o = allocObj(.data) orelse return null;
        const ulen: usize = @intCast(length);
        const n = @min(ulen, o.data_buf.len);
        if (bytes) |b| {
            @memcpy(o.data_buf[0..n], b[0..n]);
        }
        o.data_len = n;
        return @ptrCast(o);
    }

    fn mockCFErrorGetCode(err_ref: apple.CFErrorRef) callconv(.c) apple.CFIndex {
        return fromOpaque(err_ref).err_code;
    }

    fn mockCFErrorCopyDescription(err_ref: apple.CFErrorRef) callconv(.c) ?apple.CFStringRef {
        const err_obj = fromOpaque(err_ref);
        const s = allocObj(.string) orelse return null;
        const n = @min(err_obj.err_desc.len, s.str_buf.len);
        @memcpy(s.str_buf[0..n], err_obj.err_desc[0..n]);
        s.str_len = n;
        return @ptrCast(s);
    }

    fn mockCFStringGetLength(str_ref: apple.CFStringRef) callconv(.c) apple.CFIndex {
        return @intCast(fromOpaque(str_ref).str_len);
    }

    fn mockCFStringGetMaximumSizeForEncoding(
        length: apple.CFIndex,
        encoding: apple.CFStringEncoding,
    ) callconv(.c) apple.CFIndex {
        _ = encoding;
        return length * 4 + 1;
    }

    fn mockCFStringGetCString(
        str_ref: apple.CFStringRef,
        buffer: [*]u8,
        buffer_size: apple.CFIndex,
        encoding: apple.CFStringEncoding,
    ) callconv(.c) u8 {
        _ = encoding;
        const s = fromOpaque(str_ref);
        if (buffer_size <= @as(apple.CFIndex, @intCast(s.str_len))) return 0;
        @memcpy(buffer[0..s.str_len], s.str_buf[0..s.str_len]);
        buffer[s.str_len] = 0;
        return 1;
    }

    fn mockSecPolicyCreateSSL(
        server: bool,
        hostname: ?apple.CFStringRef,
    ) callconv(.c) ?apple.SecPolicyRef {
        const o = allocObj(.ssl_policy) orelse return null;
        o.ssl_server = server;
        last_ssl_policy_server = server;
        if (hostname) |h_ref| {
            const h_obj = fromOpaque(h_ref);
            o.ssl_host = h_obj;
            last_ssl_policy_has_host = true;
            @memcpy(last_ssl_policy_host_buf[0..h_obj.str_len], h_obj.str_buf[0..h_obj.str_len]);
            last_ssl_policy_host_len = h_obj.str_len;
        } else {
            last_ssl_policy_has_host = false;
            last_ssl_policy_host_len = 0;
        }
        return @ptrCast(o);
    }

    fn mockSecPolicyCreateRevocation(flags: apple.CFOptionFlags) callconv(.c) ?apple.SecPolicyRef {
        const o = allocObj(.rev_policy) orelse return null;
        o.rev_flags = flags;
        revocation_policy_count += 1;
        last_revocation_flags = flags;
        return @ptrCast(o);
    }

    fn mockSecCertificateCreateWithData(
        alloc: ?*const anyopaque,
        data_ref: apple.CFDataRef,
    ) callconv(.c) ?apple.SecCertificateRef {
        _ = alloc;
        const call_idx = cert_create_calls;
        cert_create_calls += 1;
        if (fail_cert_create_at) |fail_idx| {
            if (call_idx == fail_idx) return null;
        }
        const d_obj = fromOpaque(data_ref);
        if (d_obj.data_len == 0) return null;
        const c_obj = allocObj(.cert) orelse return null;
        @memcpy(c_obj.data_buf[0..d_obj.data_len], d_obj.data_buf[0..d_obj.data_len]);
        c_obj.data_len = d_obj.data_len;
        return @ptrCast(c_obj);
    }

    fn mockSecTrustCreateWithCertificates(
        certs_ref: *const anyopaque,
        policies_ref: *const anyopaque,
        out_trust: *?apple.SecTrustRef,
    ) callconv(.c) apple.OSStatus {
        if (trust_create_status != apple.noErr) {
            out_trust.* = null;
            return trust_create_status;
        }
        const certs_arr = fromOpaque(certs_ref);
        const policies_arr = fromOpaque(policies_ref);
        trust_cert_count = certs_arr.item_count;
        trust_policy_count = policies_arr.item_count;
        const t_obj = allocObj(.trust) orelse {
            out_trust.* = null;
            return -1;
        };
        out_trust.* = @ptrCast(t_obj);
        return apple.noErr;
    }

    fn mockSecTrustSetOCSPResponse(
        trust_ref: apple.SecTrustRef,
        ocsp_ref: *const anyopaque,
    ) callconv(.c) apple.OSStatus {
        _ = trust_ref;
        ocsp_set_called = true;
        const d_obj = fromOpaque(ocsp_ref);
        @memcpy(last_ocsp_buf[0..d_obj.data_len], d_obj.data_buf[0..d_obj.data_len]);
        last_ocsp_len = d_obj.data_len;
        return ocsp_set_status;
    }

    fn mockSecTrustEvaluateWithError(
        trust_ref: apple.SecTrustRef,
        out_err: *?apple.CFErrorRef,
    ) callconv(.c) bool {
        _ = trust_ref;
        if (eval_succeeds) {
            out_err.* = null;
            return true;
        }
        if (eval_error_code) |code| {
            if (allocObj(.err)) |e_obj| {
                e_obj.err_code = code;
                e_obj.err_desc = eval_error_desc orelse "mock SecTrust evaluation error";
                out_err.* = @ptrCast(e_obj);
            } else {
                out_err.* = null;
            }
        } else {
            out_err.* = null;
        }
        return false;
    }

    fn mockFailf(data: ?*anyopaque, msg: []const u8) void {
        _ = data;
        const n = @min(msg.len, last_failf_buf.len);
        @memcpy(last_failf_buf[0..n], msg[0..n]);
        last_failf_len = n;
    }

    fn api() apple.SecTrustApi {
        return .{
            .get_filter_config = &mockGetFilterConfig,
            .CFStringCreateWithCString = &mockCFStringCreateWithCString,
            .CFArrayCreateMutable = &mockCFArrayCreateMutable,
            .CFArrayAppendValue = &mockCFArrayAppendValue,
            .CFRelease = &mockCFRelease,
            .CFDataCreate = &mockCFDataCreate,
            .CFErrorGetCode = &mockCFErrorGetCode,
            .CFErrorCopyDescription = &mockCFErrorCopyDescription,
            .CFStringGetLength = &mockCFStringGetLength,
            .CFStringGetMaximumSizeForEncoding = &mockCFStringGetMaximumSizeForEncoding,
            .CFStringGetCString = &mockCFStringGetCString,
            .SecPolicyCreateSSL = &mockSecPolicyCreateSSL,
            .SecPolicyCreateRevocation = &mockSecPolicyCreateRevocation,
            .SecCertificateCreateWithData = &mockSecCertificateCreateWithData,
            .SecTrustCreateWithCertificates = &mockSecTrustCreateWithCertificates,
            .SecTrustSetOCSPResponse = &mockSecTrustSetOCSPResponse,
            .SecTrustEvaluateWithError = &mockSecTrustEvaluateWithError,
            .kCFTypeArrayCallBacks = @ptrCast(&callbacks_sentinel),
            .failf_hook = &mockFailf,
        };
    }

    const CertChainCtx = struct {
        ders: []const []const u8,
        fail_at_index: ?usize = null,
        fail_code: c_uint = CURLE_SSL_CACERT_BADFILE,
        calls: usize = 0,
    };

    fn testDerCallback(
        cf: *CurlCfilter,
        data: ?*anyopaque,
        cb_user_data: ?*anyopaque,
        cert_index: usize,
        out_der: *?[*]u8,
        out_der_len: *usize,
    ) callconv(.c) c_uint {
        _ = cf;
        _ = data;
        const ctx: *CertChainCtx = @ptrCast(@alignCast(cb_user_data.?));
        ctx.calls += 1;
        if (ctx.fail_at_index) |fail_idx| {
            if (cert_index == fail_idx) return ctx.fail_code;
        }
        const slice = ctx.ders[cert_index];
        out_der.* = @constCast(slice.ptr);
        out_der_len.* = slice.len;
        return CURLE_OK;
    }
};

test "Curl_vtls_apple_verify host selection, revocation policy flags, OCSP stapling, and leak-free error paths" {
    apple.mock_api = apple_test_harness.api();
    defer apple.mock_api = null;

    var cf: CurlCfilter = std.mem.zeroes(CurlCfilter);
    var origin: CurlPeer = std.mem.zeroes(CurlPeer);
    origin.hostname = "origin.example.com";
    var peer: SslPeer = std.mem.zeroes(SslPeer);
    peer.origin = &origin;

    const cert0 = [_]u8{ 0x30, 0x82, 0x01, 0x0A, 0x01 };
    const cert1 = [_]u8{ 0x30, 0x82, 0x01, 0x0B, 0x02 };
    const cert_slices = [_][]const u8{ &cert0, &cert1 };

    // 1. Trusted chain with verifyhost = true (prefers peer.sni over origin.hostname) and no_revoke = false
    {
        apple_test_harness.reset();
        apple_test_harness.conn_config.setFlag(apple_test_harness.BIT_VERIFYHOST, true);
        apple_test_harness.conn_config.setFlag(apple_test_harness.BIT_NO_REVOKE, false);
        try std.testing.expect(apple_test_harness.conn_config.verifyhost());
        try std.testing.expect(!apple_test_harness.conn_config.no_revoke());
        peer.sni = "sni.example.com";

        var chain_ctx = apple_test_harness.CertChainCtx{ .ders = &cert_slices };
        const rc = apple.Curl_vtls_apple_verify(
            &cf,
            null,
            &peer,
            cert_slices.len,
            &apple_test_harness.testDerCallback,
            &chain_ctx,
            null,
            0,
            false,
        );
        try std.testing.expectEqual(CURLE_OK, rc);
        try std.testing.expect(apple_test_harness.last_ssl_policy_server);
        try std.testing.expectEqualStrings("sni.example.com", apple_test_harness.lastSslHost().?);
        try std.testing.expectEqual(@as(usize, 1), apple_test_harness.revocation_policy_count);
        try std.testing.expectEqual(apple.kSecRevocationUseAnyAvailableMethod, apple_test_harness.last_revocation_flags);
        try std.testing.expectEqual(@as(usize, 2), apple_test_harness.trust_policy_count);
        try std.testing.expectEqual(@as(usize, 2), apple_test_harness.trust_cert_count);
        try std.testing.expect(!apple_test_harness.ocsp_set_called);
        try apple_test_harness.expectZeroLeaks();
    }

    // 2. Fallback to origin.hostname when peer.sni is null, and verifyhost = false passes null host_str
    {
        apple_test_harness.reset();
        apple_test_harness.conn_config.setFlag(apple_test_harness.BIT_VERIFYHOST, true);
        peer.sni = null;

        var chain_ctx = apple_test_harness.CertChainCtx{ .ders = &cert_slices };
        try std.testing.expectEqual(
            CURLE_OK,
            apple.Curl_vtls_apple_verify(&cf, null, &peer, cert_slices.len, &apple_test_harness.testDerCallback, &chain_ctx, null, 0, false),
        );
        try std.testing.expectEqualStrings("origin.example.com", apple_test_harness.lastSslHost().?);
        try apple_test_harness.expectZeroLeaks();

        apple_test_harness.reset();
        apple_test_harness.conn_config.setFlag(apple_test_harness.BIT_VERIFYHOST, false);
        peer.sni = "ignored-sni.example.com";
        chain_ctx.calls = 0;
        try std.testing.expectEqual(
            CURLE_OK,
            apple.Curl_vtls_apple_verify(&cf, null, &peer, cert_slices.len, &apple_test_harness.testDerCallback, &chain_ctx, null, 0, false),
        );
        try std.testing.expect(apple_test_harness.lastSslHost() == null);
        try apple_test_harness.expectZeroLeaks();
    }

    // 3. Revocation policy flags: require_ocsp = true adds kSecRevocationRequirePositiveResponse; no_revoke = true omits revocation policy
    {
        apple_test_harness.reset();
        apple_test_harness.conn_config.setFlag(apple_test_harness.BIT_VERIFYHOST, true);
        apple_test_harness.conn_config.setFlag(apple_test_harness.BIT_NO_REVOKE, false);
        peer.sni = "ocsp.example.com";

        var chain_ctx = apple_test_harness.CertChainCtx{ .ders = &cert_slices };
        try std.testing.expectEqual(
            CURLE_OK,
            apple.Curl_vtls_apple_verify(&cf, null, &peer, cert_slices.len, &apple_test_harness.testDerCallback, &chain_ctx, null, 0, true),
        );
        try std.testing.expectEqual(@as(usize, 1), apple_test_harness.revocation_policy_count);
        try std.testing.expectEqual(
            apple.kSecRevocationUseAnyAvailableMethod | apple.kSecRevocationRequirePositiveResponse,
            apple_test_harness.last_revocation_flags,
        );
        try std.testing.expectEqual(@as(usize, 2), apple_test_harness.trust_policy_count);
        try apple_test_harness.expectZeroLeaks();

        apple_test_harness.reset();
        apple_test_harness.conn_config.setFlag(apple_test_harness.BIT_VERIFYHOST, true);
        apple_test_harness.conn_config.setFlag(apple_test_harness.BIT_NO_REVOKE, true);
        try std.testing.expect(apple_test_harness.conn_config.no_revoke());
        chain_ctx.calls = 0;
        try std.testing.expectEqual(
            CURLE_OK,
            apple.Curl_vtls_apple_verify(&cf, null, &peer, cert_slices.len, &apple_test_harness.testDerCallback, &chain_ctx, null, 0, true),
        );
        try std.testing.expectEqual(@as(usize, 0), apple_test_harness.revocation_policy_count);
        try std.testing.expectEqual(@as(usize, 1), apple_test_harness.trust_policy_count);
        try apple_test_harness.expectZeroLeaks();
    }

    // 4. Stapled OCSP response attachment and SecTrustSetOCSPResponse error handling
    {
        const ocsp_staple = [_]u8{ 0x30, 0x03, 0x0A, 0x01, 0x00 };
        apple_test_harness.reset();
        apple_test_harness.conn_config.setFlag(apple_test_harness.BIT_VERIFYHOST, true);

        var chain_ctx = apple_test_harness.CertChainCtx{ .ders = &cert_slices };
        try std.testing.expectEqual(
            CURLE_OK,
            apple.Curl_vtls_apple_verify(&cf, null, &peer, cert_slices.len, &apple_test_harness.testDerCallback, &chain_ctx, &ocsp_staple, ocsp_staple.len, true),
        );
        try std.testing.expect(apple_test_harness.ocsp_set_called);
        try std.testing.expectEqualSlices(u8, &ocsp_staple, apple_test_harness.last_ocsp_buf[0..apple_test_harness.last_ocsp_len]);
        try apple_test_harness.expectZeroLeaks();

        apple_test_harness.reset();
        apple_test_harness.conn_config.setFlag(apple_test_harness.BIT_VERIFYHOST, true);
        apple_test_harness.ocsp_set_status = -50;
        chain_ctx.calls = 0;
        try std.testing.expectEqual(
            CURLE_PEER_FAILED_VERIFICATION,
            apple.Curl_vtls_apple_verify(&cf, null, &peer, cert_slices.len, &apple_test_harness.testDerCallback, &chain_ctx, &ocsp_staple, ocsp_staple.len, true),
        );
        try std.testing.expect(apple_test_harness.ocsp_set_called);
        try std.testing.expectEqualStrings("Apple SecTrust: failed to set OCSP response: -50", apple_test_harness.lastFailf());
        try apple_test_harness.expectZeroLeaks();
    }

    // 5. errSecIncompleteCertRevocationCheck (-67635) -> CURLE_SSL_INVALIDCERTSTATUS vs untrusted root -> CURLE_PEER_FAILED_VERIFICATION
    {
        apple_test_harness.reset();
        apple_test_harness.conn_config.setFlag(apple_test_harness.BIT_VERIFYHOST, true);
        apple_test_harness.eval_succeeds = false;
        apple_test_harness.eval_error_code = apple.errSecIncompleteCertRevocationCheck;
        apple_test_harness.eval_error_desc = "Incomplete revocation check";

        var chain_ctx = apple_test_harness.CertChainCtx{ .ders = &cert_slices };
        try std.testing.expectEqual(
            CURLE_SSL_INVALIDCERTSTATUS,
            apple.Curl_vtls_apple_verify(&cf, null, &peer, cert_slices.len, &apple_test_harness.testDerCallback, &chain_ctx, null, 0, true),
        );
        try std.testing.expectEqualStrings("Apple SecTrust failure -67635: Incomplete revocation check", apple_test_harness.lastFailf());
        try apple_test_harness.expectZeroLeaks();

        apple_test_harness.reset();
        apple_test_harness.conn_config.setFlag(apple_test_harness.BIT_VERIFYHOST, true);
        apple_test_harness.eval_succeeds = false;
        apple_test_harness.eval_error_code = -67843; // errSecNotTrusted
        apple_test_harness.eval_error_desc = "Root certificate is not trusted";
        chain_ctx.calls = 0;
        try std.testing.expectEqual(
            CURLE_PEER_FAILED_VERIFICATION,
            apple.Curl_vtls_apple_verify(&cf, null, &peer, cert_slices.len, &apple_test_harness.testDerCallback, &chain_ctx, null, 0, false),
        );
        try std.testing.expectEqualStrings("Apple SecTrust failure -67843: Root certificate is not trusted", apple_test_harness.lastFailf());
        try apple_test_harness.expectZeroLeaks();
    }

    // 6. der_cb error propagation and SecCertificateCreateWithData failure cleanup with zero CF object leaks
    {
        apple_test_harness.reset();
        apple_test_harness.conn_config.setFlag(apple_test_harness.BIT_VERIFYHOST, true);

        var failing_chain = apple_test_harness.CertChainCtx{
            .ders = &cert_slices,
            .fail_at_index = 1,
            .fail_code = CURLE_SSL_CACERT_BADFILE,
        };
        try std.testing.expectEqual(
            CURLE_SSL_CACERT_BADFILE,
            apple.Curl_vtls_apple_verify(&cf, null, &peer, cert_slices.len, &apple_test_harness.testDerCallback, &failing_chain, null, 0, false),
        );
        try std.testing.expectEqual(@as(usize, 2), failing_chain.calls);
        try apple_test_harness.expectZeroLeaks();

        apple_test_harness.reset();
        apple_test_harness.conn_config.setFlag(apple_test_harness.BIT_VERIFYHOST, true);
        apple_test_harness.fail_cert_create_at = 1;

        var ok_chain = apple_test_harness.CertChainCtx{ .ders = &cert_slices };
        try std.testing.expectEqual(
            CURLE_OUT_OF_MEMORY,
            apple.Curl_vtls_apple_verify(&cf, null, &peer, cert_slices.len, &apple_test_harness.testDerCallback, &ok_chain, null, 0, false),
        );
        try std.testing.expectEqual(@as(usize, 2), ok_chain.calls);
        try apple_test_harness.expectZeroLeaks();
    }

    // 7. Curl_vtls_apple_verifies_ocsp returns true
    try std.testing.expect(apple.Curl_vtls_apple_verifies_ocsp(&cf, null));
}
