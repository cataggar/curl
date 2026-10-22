const std = @import("std");
const builtin = @import("builtin");
const backend_options = @import("backend_options");
const mem = @import("mem.zig");

const is_bundled = if (@hasDecl(backend_options, "bundled")) backend_options.bundled else false;

fn cStrdupSlice(s: []const u8) ?[*:0]u8 {
    return mem.memdup0(s.ptr, s.len);
}

// ============================================================================
// 1. Pure-Zig IDNA2008 / RFC 3492 Punycode (idn2_*)
// ============================================================================

pub const IDN2_OK: c_int = 0;
pub const IDN2_MALLOC: c_int = -100;
pub const IDN2_NO_CODESET: c_int = -101;
pub const IDN2_ENCODING_ERROR: c_int = -101;
pub const IDN2_ICONV_FAIL: c_int = -102;
pub const IDN2_PUNYCODE_BAD_INPUT: c_int = -200;
pub const IDN2_PUNYCODE_BIG_OUTPUT: c_int = -201;
pub const IDN2_PUNYCODE_OVERFLOW: c_int = -202;
pub const IDN2_TOO_BIG_DOMAIN: c_int = -204;
pub const IDN2_TOO_BIG_LABEL: c_int = -205;
pub const IDN2_INVALID_ALABEL: c_int = -206;
pub const IDN2_DOT_IN_LABEL: c_int = -207;
pub const IDN2_TRANSITIONAL: c_int = 0x0004;
pub const IDN2_NONTRANSITIONAL: c_int = 0x0008;

const PUNYCODE_BASE: u32 = 36;
const PUNYCODE_TMIN: u32 = 1;
const PUNYCODE_TMAX: u32 = 26;
const PUNYCODE_SKEW: u32 = 38;
const PUNYCODE_DAMP: u32 = 700;
const PUNYCODE_INITIAL_BIAS: u32 = 72;
const PUNYCODE_INITIAL_N: u32 = 0x80;
const MAX_DNS_LABEL_LEN: usize = 63;
const MAX_DNS_DOMAIN_LEN: usize = 255;

fn punycodeAdapt(delta_in: u32, numpoints: u32, firsttime: bool) u32 {
    var delta: u32 = if (firsttime) delta_in / PUNYCODE_DAMP else delta_in >> 1;
    delta += delta / numpoints;
    var k: u32 = 0;
    while (delta > ((PUNYCODE_BASE - PUNYCODE_TMIN) * PUNYCODE_TMAX) / 2) {
        delta /= (PUNYCODE_BASE - PUNYCODE_TMIN);
        k += PUNYCODE_BASE;
    }
    return k + (((PUNYCODE_BASE - PUNYCODE_TMIN + 1) * delta) / (delta + PUNYCODE_SKEW));
}

fn punycodeEncodeDigit(d: u32) u8 {
    if (d < 26) return @intCast('a' + d);
    return @intCast('0' + (d - 26));
}

fn punycodeDecodeDigit(b: u8) ?u32 {
    if (b >= 'a' and b <= 'z') return @as(u32, b - 'a');
    if (b >= 'A' and b <= 'Z') return @as(u32, b - 'A');
    if (b >= '0' and b <= '9') return @as(u32, 26 + (b - '0'));
    return null;
}

fn isIdnaLabelSeparator(cp: u21) bool {
    return cp == '.' or cp == 0x3002 or cp == 0xFF0E or cp == 0xFF61;
}

fn foldIdnaCodepoint(cp: u21) u21 {
    if (cp >= 'A' and cp <= 'Z') return cp + 0x20;
    if (cp >= 0x00C0 and cp <= 0x00D6) return cp + 0x20;
    if (cp >= 0x00D8 and cp <= 0x00DE) return cp + 0x20;
    return cp;
}

pub fn punycodeEncodeLabel(cps: []const u21, out_buf: []u8) c_int {
    if (cps.len == 0 or out_buf.len < 4) return IDN2_TOO_BIG_LABEL;

    var has_non_ascii = false;
    for (cps) |cp| {
        if (cp < 0x20 or cp == 0x7f) return IDN2_ENCODING_ERROR;
        if (cp >= 0x80) has_non_ascii = true;
    }

    if (!has_non_ascii) {
        if (cps.len > MAX_DNS_LABEL_LEN or cps.len > out_buf.len) return IDN2_TOO_BIG_LABEL;
        for (cps, 0..) |cp, idx| {
            const c: u8 = @intCast(cp);
            out_buf[idx] = std.ascii.toLower(c);
        }
        return @intCast(cps.len);
    }

    @memcpy(out_buf[0..4], "xn--");
    var out_len: usize = 4;

    var b: u32 = 0;
    for (cps) |cp| {
        if (cp < 0x80) {
            if (out_len >= out_buf.len) return IDN2_TOO_BIG_LABEL;
            out_buf[out_len] = std.ascii.toLower(@as(u8, @intCast(cp)));
            out_len += 1;
            b += 1;
        }
    }

    if (b > 0) {
        if (out_len >= out_buf.len) return IDN2_TOO_BIG_LABEL;
        out_buf[out_len] = '-';
        out_len += 1;
    }

    var n: u32 = PUNYCODE_INITIAL_N;
    var delta: u32 = 0;
    var bias: u32 = PUNYCODE_INITIAL_BIAS;
    var h: u32 = b;
    const total_cps: u32 = @intCast(cps.len);

    while (h < total_cps) {
        var m: u32 = std.math.maxInt(u32);
        for (cps) |cp_u21| {
            const cp: u32 = cp_u21;
            if (cp >= n and cp < m) {
                m = cp;
            }
        }

        const step = std.math.mul(u32, m - n, h + 1) catch return IDN2_PUNYCODE_OVERFLOW;
        delta = std.math.add(u32, delta, step) catch return IDN2_PUNYCODE_OVERFLOW;
        n = m;

        for (cps) |cp_u21| {
            const c: u32 = cp_u21;
            if (c < n) {
                delta = std.math.add(u32, delta, 1) catch return IDN2_PUNYCODE_OVERFLOW;
            } else if (c == n) {
                var q: u32 = delta;
                var k: u32 = PUNYCODE_BASE;
                while (true) : (k += PUNYCODE_BASE) {
                    const t: u32 = if (k <= bias)
                        PUNYCODE_TMIN
                    else if (k >= bias + PUNYCODE_TMAX)
                        PUNYCODE_TMAX
                    else
                        k - bias;
                    if (q < t) break;
                    const digit = t + ((q - t) % (PUNYCODE_BASE - t));
                    if (out_len >= out_buf.len) return IDN2_TOO_BIG_LABEL;
                    out_buf[out_len] = punycodeEncodeDigit(digit);
                    out_len += 1;
                    q = (q - t) / (PUNYCODE_BASE - t);
                }
                if (out_len >= out_buf.len) return IDN2_TOO_BIG_LABEL;
                out_buf[out_len] = punycodeEncodeDigit(q);
                out_len += 1;
                bias = punycodeAdapt(delta, h + 1, h == b);
                delta = 0;
                h += 1;
            }
        }

        delta = std.math.add(u32, delta, 1) catch return IDN2_PUNYCODE_OVERFLOW;
        n = std.math.add(u32, n, 1) catch return IDN2_PUNYCODE_OVERFLOW;
    }

    if (out_len > MAX_DNS_LABEL_LEN) return IDN2_TOO_BIG_LABEL;
    return @intCast(out_len);
}

pub fn punycodeDecodeLabel(label: []const u8, out_utf8: []u8) c_int {
    if (label.len == 0 or label.len > MAX_DNS_LABEL_LEN) return IDN2_PUNYCODE_BAD_INPUT;

    if (label.len < 4 or !std.ascii.eqlIgnoreCase(label[0..4], "xn--")) {
        if (label.len > out_utf8.len) return IDN2_PUNYCODE_BIG_OUTPUT;
        for (label, 0..) |ch, idx| {
            if (ch < 0x20 or ch == 0x7f) return IDN2_PUNYCODE_BAD_INPUT;
            out_utf8[idx] = std.ascii.toLower(ch);
        }
        return @intCast(label.len);
    }

    const encoded = label[4..];
    if (encoded.len == 0) return IDN2_PUNYCODE_BAD_INPUT;

    var cps: [256]u21 = undefined;
    var cp_len: usize = 0;

    var pos: usize = 0;
    if (std.mem.lastIndexOfScalar(u8, encoded, '-')) |delim_idx| {
        for (encoded[0..delim_idx]) |ch| {
            if (ch >= 0x80 or ch < 0x20 or ch == 0x7f) return IDN2_PUNYCODE_BAD_INPUT;
            if (cp_len >= cps.len) return IDN2_PUNYCODE_BIG_OUTPUT;
            cps[cp_len] = std.ascii.toLower(ch);
            cp_len += 1;
        }
        pos = delim_idx + 1;
    }

    var n: u32 = PUNYCODE_INITIAL_N;
    var i: u32 = 0;
    var bias: u32 = PUNYCODE_INITIAL_BIAS;

    if (pos >= encoded.len) return IDN2_PUNYCODE_BAD_INPUT;

    while (pos < encoded.len) {
        const oldi: u32 = i;
        var w: u32 = 1;
        var k: u32 = PUNYCODE_BASE;
        while (true) : (k += PUNYCODE_BASE) {
            if (pos >= encoded.len) return IDN2_PUNYCODE_BAD_INPUT;
            const digit = punycodeDecodeDigit(encoded[pos]) orelse return IDN2_PUNYCODE_BAD_INPUT;
            pos += 1;

            const term = std.math.mul(u32, digit, w) catch return IDN2_PUNYCODE_OVERFLOW;
            i = std.math.add(u32, i, term) catch return IDN2_PUNYCODE_OVERFLOW;

            const t: u32 = if (k <= bias)
                PUNYCODE_TMIN
            else if (k >= bias + PUNYCODE_TMAX)
                PUNYCODE_TMAX
            else
                k - bias;
            if (digit < t) break;
            w = std.math.mul(u32, w, PUNYCODE_BASE - t) catch return IDN2_PUNYCODE_OVERFLOW;
        }

        const out_plus_one: u32 = @intCast(cp_len + 1);
        bias = punycodeAdapt(i - oldi, out_plus_one, oldi == 0);
        n = std.math.add(u32, n, i / out_plus_one) catch return IDN2_PUNYCODE_OVERFLOW;
        if (n > 0x10FFFF or (n >= 0xD800 and n <= 0xDFFF)) return IDN2_PUNYCODE_BAD_INPUT;
        i = i % out_plus_one;

        if (cp_len >= cps.len) return IDN2_PUNYCODE_BIG_OUTPUT;
        const insert_idx: usize = @intCast(i);
        var move_idx = cp_len;
        while (move_idx > insert_idx) : (move_idx -= 1) {
            cps[move_idx] = cps[move_idx - 1];
        }
        cps[insert_idx] = @intCast(n);
        cp_len += 1;
        i += 1;
    }

    var utf8_len: usize = 0;
    for (cps[0..cp_len]) |cp| {
        var seq: [4]u8 = undefined;
        const seq_len = std.unicode.utf8Encode(cp, &seq) catch return IDN2_ENCODING_ERROR;
        if (utf8_len + seq_len > out_utf8.len) return IDN2_PUNYCODE_BIG_OUTPUT;
        @memcpy(out_utf8[utf8_len .. utf8_len + seq_len], seq[0..seq_len]);
        utf8_len += seq_len;
    }

    return @intCast(utf8_len);
}

fn parseSemver3(s: []const u8) [3]u32 {
    var parts: [3]u32 = .{ 0, 0, 0 };
    var part_idx: usize = 0;
    var idx: usize = 0;
    while (idx < s.len and part_idx < 3) : (idx += 1) {
        const ch = s[idx];
        if (ch >= '0' and ch <= '9') {
            parts[part_idx] = parts[part_idx] *| 10 +| @as(u32, ch - '0');
        } else if (ch == '.') {
            part_idx += 1;
        } else {
            break;
        }
    }
    return parts;
}

pub fn idn2_check_version(req_version: ?[*:0]const u8) callconv(.c) ?[*:0]const u8 {
    const ver_str: [*:0]const u8 = "2.3.7";
    const req = req_version orelse return ver_str;
    const req_slice = std.mem.span(req);
    if (req_slice.len == 0) return ver_str;
    const req_v = parseSemver3(req_slice);
    const cur_v: [3]u32 = .{ 2, 3, 7 };
    if (req_v[0] < cur_v[0]) return ver_str;
    if (req_v[0] > cur_v[0]) return null;
    if (req_v[1] < cur_v[1]) return ver_str;
    if (req_v[1] > cur_v[1]) return null;
    if (req_v[2] <= cur_v[2]) return ver_str;
    return null;
}

pub fn idn2_lookup_u8(src: ?[*:0]const u8, lookupname: ?*?[*:0]u8, flags: c_int) callconv(.c) c_int {
    const src_ptr = src orelse {
        if (lookupname) |out| out.* = null;
        return IDN2_OK;
    };
    const in_slice = std.mem.span(src_ptr);
    if (in_slice.len == 0) {
        if (lookupname) |out| {
            out.* = cStrdupSlice("") orelse return IDN2_MALLOC;
        }
        return IDN2_OK;
    }

    var view = std.unicode.Utf8View.init(in_slice) catch return IDN2_ENCODING_ERROR;
    var iter = view.iterator();

    var out_domain: [1024]u8 = undefined;
    var out_pos: usize = 0;

    var label_cps: [256]u21 = undefined;
    var label_len: usize = 0;
    var saw_any_cp = false;
    var last_was_sep = false;
    const transitional = (flags & IDN2_TRANSITIONAL) != 0;

    while (iter.nextCodepoint()) |raw_cp| {
        saw_any_cp = true;
        if (isIdnaLabelSeparator(raw_cp)) {
            if (label_len == 0) return IDN2_DOT_IN_LABEL;
            var encoded_label: [128]u8 = undefined;
            const enc_rc = punycodeEncodeLabel(label_cps[0..label_len], &encoded_label);
            if (enc_rc < 0) return enc_rc;
            const enc_len: usize = @intCast(enc_rc);
            if (out_pos + enc_len + 1 > MAX_DNS_DOMAIN_LEN or out_pos + enc_len + 1 >= out_domain.len) {
                return IDN2_TOO_BIG_DOMAIN;
            }
            @memcpy(out_domain[out_pos .. out_pos + enc_len], encoded_label[0..enc_len]);
            out_pos += enc_len;
            out_domain[out_pos] = '.';
            out_pos += 1;
            label_len = 0;
            last_was_sep = true;
            continue;
        }
        last_was_sep = false;
        if (raw_cp < 0x20 or raw_cp == 0x7f) return IDN2_ENCODING_ERROR;
        if (transitional and raw_cp == 0x00DF) {
            if (label_len + 2 > label_cps.len) return IDN2_TOO_BIG_LABEL;
            label_cps[label_len] = 's';
            label_cps[label_len + 1] = 's';
            label_len += 2;
        } else {
            if (label_len >= label_cps.len) return IDN2_TOO_BIG_LABEL;
            label_cps[label_len] = foldIdnaCodepoint(raw_cp);
            label_len += 1;
        }
    }

    if (saw_any_cp and !last_was_sep) {
        if (label_len == 0) return IDN2_DOT_IN_LABEL;
        var encoded_label: [128]u8 = undefined;
        const enc_rc = punycodeEncodeLabel(label_cps[0..label_len], &encoded_label);
        if (enc_rc < 0) return enc_rc;
        const enc_len: usize = @intCast(enc_rc);
        if (out_pos + enc_len > MAX_DNS_DOMAIN_LEN or out_pos + enc_len >= out_domain.len) {
            return IDN2_TOO_BIG_DOMAIN;
        }
        @memcpy(out_domain[out_pos .. out_pos + enc_len], encoded_label[0..enc_len]);
        out_pos += enc_len;
    }

    if (lookupname) |out| {
        out.* = cStrdupSlice(out_domain[0..out_pos]) orelse return IDN2_MALLOC;
    }
    return IDN2_OK;
}

pub fn idn2_lookup_ul(src: ?[*:0]const u8, lookupname: ?*?[*:0]u8, flags: c_int) callconv(.c) c_int {
    return idn2_lookup_u8(src, lookupname, flags);
}

pub fn idn2_to_ascii_8z(input: ?[*:0]const u8, output: ?*?[*:0]u8, flags: c_int) callconv(.c) c_int {
    return idn2_lookup_u8(input, output, flags);
}

pub fn idn2_to_ascii_lz(input: ?[*:0]const u8, output: ?*?[*:0]u8, flags: c_int) callconv(.c) c_int {
    return idn2_lookup_u8(input, output, flags);
}

pub fn idn2_to_unicode_8z8z(input: ?[*:0]const u8, output: ?*?[*:0]u8, flags: c_int) callconv(.c) c_int {
    _ = flags;
    const in_ptr = input orelse {
        if (output) |out| out.* = null;
        return IDN2_OK;
    };
    const in_slice = std.mem.span(in_ptr);
    if (in_slice.len == 0) {
        if (output) |out| {
            out.* = cStrdupSlice("") orelse return IDN2_MALLOC;
        }
        return IDN2_OK;
    }

    var out_buf: [2048]u8 = undefined;
    var out_pos: usize = 0;

    var start: usize = 0;
    var idx: usize = 0;
    while (idx <= in_slice.len) : (idx += 1) {
        if (idx == in_slice.len or in_slice[idx] == '.') {
            const label = in_slice[start..idx];
            if (label.len > 0) {
                var decoded_label: [512]u8 = undefined;
                const dec_rc = punycodeDecodeLabel(label, &decoded_label);
                if (dec_rc < 0) return dec_rc;
                const dec_len: usize = @intCast(dec_rc);
                if (out_pos + dec_len + 1 >= out_buf.len) return IDN2_PUNYCODE_BIG_OUTPUT;
                @memcpy(out_buf[out_pos .. out_pos + dec_len], decoded_label[0..dec_len]);
                out_pos += dec_len;
            }
            if (idx < in_slice.len) {
                if (out_pos + 1 >= out_buf.len) return IDN2_PUNYCODE_BIG_OUTPUT;
                out_buf[out_pos] = '.';
                out_pos += 1;
            }
            start = idx + 1;
        }
    }

    if (output) |out| {
        out.* = cStrdupSlice(out_buf[0..out_pos]) orelse return IDN2_MALLOC;
    }
    return IDN2_OK;
}

pub fn idn2_free(ptr: ?*anyopaque) callconv(.c) void {
    mem.free(ptr);
}

pub fn idn2_strerror(rc: c_int) callconv(.c) [*:0]const u8 {
    return switch (rc) {
        IDN2_OK => "success",
        IDN2_MALLOC => "out of memory",
        IDN2_ENCODING_ERROR => "string encoding error",
        IDN2_ICONV_FAIL => "could not convert string to UTF-8",
        IDN2_PUNYCODE_BAD_INPUT => "punycode error",
        IDN2_PUNYCODE_BIG_OUTPUT => "punycode output buffer too small",
        IDN2_PUNYCODE_OVERFLOW => "punycode arithmetic overflow",
        IDN2_TOO_BIG_DOMAIN => "domain name longer than 255 characters",
        IDN2_TOO_BIG_LABEL => "domain label longer than 63 characters",
        IDN2_INVALID_ALABEL => "input A-label is not valid",
        IDN2_DOT_IN_LABEL => "domain label has a dot",
        else => "unknown error",
    };
}

pub fn idn2_strerror_name(rc: c_int) callconv(.c) [*:0]const u8 {
    return switch (rc) {
        IDN2_OK => "IDN2_OK",
        IDN2_MALLOC => "IDN2_MALLOC",
        IDN2_ENCODING_ERROR => "IDN2_ENCODING_ERROR",
        IDN2_ICONV_FAIL => "IDN2_ICONV_FAIL",
        IDN2_PUNYCODE_BAD_INPUT => "IDN2_PUNYCODE_BAD_INPUT",
        IDN2_PUNYCODE_BIG_OUTPUT => "IDN2_PUNYCODE_BIG_OUTPUT",
        IDN2_PUNYCODE_OVERFLOW => "IDN2_PUNYCODE_OVERFLOW",
        IDN2_TOO_BIG_DOMAIN => "IDN2_TOO_BIG_DOMAIN",
        IDN2_TOO_BIG_LABEL => "IDN2_TOO_BIG_LABEL",
        IDN2_INVALID_ALABEL => "IDN2_INVALID_ALABEL",
        IDN2_DOT_IN_LABEL => "IDN2_DOT_IN_LABEL",
        else => "IDN2_UNKNOWN",
    };
}

// ============================================================================
// 2. Pure-Zig Public Suffix List (psl_*)
// ============================================================================

pub const psl_ctx_t = extern struct {
    magic: u32 = 0x50534C30,
};

var static_psl_ctx: psl_ctx_t = .{};

const multi_label_public_suffixes = [_][]const u8{
    "co.uk",
    "org.uk",
    "ac.uk",
    "gov.uk",
    "net.uk",
    "me.uk",
    "ltd.uk",
    "plc.uk",
    "com.au",
    "net.au",
    "org.au",
    "edu.au",
    "gov.au",
    "asn.au",
    "id.au",
    "co.jp",
    "or.jp",
    "ne.jp",
    "ac.jp",
    "go.jp",
    "ed.jp",
    "gr.jp",
    "ad.jp",
    "lg.jp",
    "co.nz",
    "net.nz",
    "org.nz",
    "ac.nz",
    "govt.nz",
    "co.za",
    "org.za",
    "net.za",
    "gov.za",
    "ac.za",
    "com.br",
    "net.br",
    "org.br",
    "gov.br",
    "edu.br",
    "com.cn",
    "net.cn",
    "org.cn",
    "gov.cn",
    "edu.cn",
    "ac.cn",
    "co.in",
    "net.in",
    "org.in",
    "gov.in",
    "ac.in",
    "res.in",
    "co.kr",
    "or.kr",
    "ne.kr",
    "go.kr",
    "ac.kr",
    "com.mx",
    "org.mx",
    "gob.mx",
    "net.mx",
    "edu.mx",
    "com.tw",
    "org.tw",
    "net.tw",
    "edu.tw",
    "gov.tw",
    "idv.tw",
    "com.hk",
    "org.hk",
    "net.hk",
    "edu.hk",
    "gov.hk",
    "idv.hk",
    "com.sg",
    "org.sg",
    "net.sg",
    "edu.sg",
    "gov.sg",
    "com.my",
    "org.my",
    "net.my",
    "edu.my",
    "gov.my",
    "com.tr",
    "org.tr",
    "net.tr",
    "edu.tr",
    "gov.tr",
    "com.ar",
    "org.ar",
    "net.ar",
    "gov.ar",
    "edu.ar",
    "co.il",
    "org.il",
    "net.il",
    "ac.il",
    "gov.il",
    "github.io",
    "gitlab.io",
    "pages.dev",
    "vercel.app",
    "netlify.app",
    "herokuapp.com",
    "appspot.com",
    "cloudfront.net",
    "s3.amazonaws.com",
    "azurewebsites.net",
    "workers.dev",
    "fly.dev",
};

fn trimDots(s: []const u8, strip_leading: bool, strip_trailing: bool) []const u8 {
    var slice = s;
    if (strip_leading) {
        while (slice.len > 0 and slice[0] == '.') {
            slice = slice[1..];
        }
    }
    if (strip_trailing) {
        while (slice.len > 0 and slice[slice.len - 1] == '.') {
            slice = slice[0 .. slice.len - 1];
        }
    }
    return slice;
}

fn isIpLiteral(host: []const u8) bool {
    if (host.len == 0) return false;
    if (std.mem.indexOfScalar(u8, host, ':') != null) return true;
    var dot_count: usize = 0;
    var part_len: usize = 0;
    var part_val: u32 = 0;
    for (host) |ch| {
        if (ch == '.') {
            if (part_len == 0 or part_val > 255) return false;
            dot_count += 1;
            part_len = 0;
            part_val = 0;
        } else if (ch >= '0' and ch <= '9') {
            part_val = part_val * 10 + (ch - '0');
            part_len += 1;
            if (part_len > 3) return false;
        } else {
            return false;
        }
    }
    return dot_count == 3 and part_len > 0 and part_val <= 255;
}

fn isPublicSuffixSlice(domain_clean: []const u8) bool {
    if (domain_clean.len == 0) return true;
    var label_count: usize = 1;
    var current_label_len: usize = 0;
    for (domain_clean) |ch| {
        if (ch == '.') {
            if (current_label_len == 0) return true;
            label_count += 1;
            current_label_len = 0;
        } else {
            current_label_len += 1;
        }
    }
    if (current_label_len == 0) return true;
    if (label_count <= 1) return true;

    for (multi_label_public_suffixes) |suffix| {
        if (std.ascii.eqlIgnoreCase(domain_clean, suffix)) {
            return true;
        }
    }
    return false;
}

pub fn psl_check_version_number(version: c_int) callconv(.c) c_int {
    const cur: c_int = (0 << 16) | (21 << 8) | 5;
    if (version > cur) return 0;
    return cur;
}

pub fn psl_latest(fname: ?[*:0]const u8) callconv(.c) ?*psl_ctx_t {
    _ = fname;
    return &static_psl_ctx;
}

pub fn psl_builtin() callconv(.c) ?*const psl_ctx_t {
    return &static_psl_ctx;
}

pub fn psl_free(psl: ?*psl_ctx_t) callconv(.c) void {
    _ = psl;
}

pub fn psl_is_public_suffix(psl: ?*const anyopaque, domain: ?[*:0]const u8) callconv(.c) c_int {
    _ = psl;
    const dom_ptr = domain orelse return 0;
    const dom_clean = trimDots(std.mem.span(dom_ptr), true, true);
    if (dom_clean.len == 0) return 0;
    if (isIpLiteral(dom_clean)) return 0;
    return if (isPublicSuffixSlice(dom_clean)) 1 else 0;
}

pub fn psl_is_cookie_domain_acceptable(
    psl: ?*const anyopaque,
    hostname: ?[*:0]const u8,
    cookie_domain: ?[*:0]const u8,
) callconv(.c) c_int {
    _ = psl;
    const host_ptr = hostname orelse return 0;
    const cdom_ptr = cookie_domain orelse return 0;

    const host_raw = std.mem.span(host_ptr);
    const cdom_raw = std.mem.span(cdom_ptr);
    if (host_raw.len == 0 or cdom_raw.len == 0) return 0;

    const host_clean = trimDots(host_raw, false, true);
    const cdom_clean = trimDots(cdom_raw, true, true);
    if (host_clean.len == 0 or cdom_clean.len == 0) return 0;

    if (std.ascii.eqlIgnoreCase(host_clean, cdom_clean)) {
        if (isIpLiteral(host_clean)) return 1;
        if (cdom_raw[0] != '.') return 1;
    }

    if (host_clean.len < cdom_clean.len) return 0;
    if (host_clean.len == cdom_clean.len) {
        if (!std.ascii.eqlIgnoreCase(host_clean, cdom_clean)) return 0;
    } else {
        const prefix_len = host_clean.len - cdom_clean.len;
        if (host_clean[prefix_len - 1] != '.') return 0;
        if (!std.ascii.eqlIgnoreCase(host_clean[prefix_len..], cdom_clean)) return 0;
    }

    if (isPublicSuffixSlice(cdom_clean)) return 0;
    return 1;
}

// ============================================================================
// 3. Bundled c-ares & HTTPS-RR (ares_*)
// ============================================================================

pub const ARES_SUCCESS: c_int = 0;
pub const ARES_ENODATA: c_int = 1;
pub const ARES_EFORMERR: c_int = 2;
pub const ARES_ESERVFAIL: c_int = 3;
pub const ARES_ENOTFOUND: c_int = 4;
pub const ARES_ENOTIMP: c_int = 5;
pub const ARES_EREFUSED: c_int = 6;
pub const ARES_EBADQUERY: c_int = 7;
pub const ARES_EBADNAME: c_int = 8;
pub const ARES_EBADFAMILY: c_int = 9;
pub const ARES_EBADRESP: c_int = 10;
pub const ARES_ECONNREFUSED: c_int = 11;
pub const ARES_ETIMEOUT: c_int = 12;
pub const ARES_EOF: c_int = 13;
pub const ARES_EFILE: c_int = 14;
pub const ARES_ENOMEM: c_int = 15;
pub const ARES_EDESTRUCTION: c_int = 16;

pub const AresCallback = *const fn (
    arg: ?*anyopaque,
    status: c_int,
    timeouts: c_int,
    abuf: ?[*]const u8,
    alen: c_int,
) callconv(.c) void;

pub const AresAddrinfoCallback = *const fn (
    arg: ?*anyopaque,
    status: c_int,
    timeouts: c_int,
    res: ?*anyopaque,
) callconv(.c) void;

const AresDnsOpt = struct {
    opt: u16 = 0,
    val: [128]u8 = @splat(0),
    val_len: usize = 0,
};

const AresDnsRr = struct {
    sect: c_uint = 0,
    rtype: c_uint = 0,
    rclass: c_uint = 0,
    ttl: c_uint = 0,
    u16_val: u16 = 0,
    str_val: [256:0]u8 = @splat(0),
    opts: [8]AresDnsOpt = @splat(.{}),
    opt_cnt: usize = 0,
};

const AresDnsRecord = struct {
    id: u16 = 0,
    flags: u16 = 0,
    opcode: c_uint = 0,
    rcode: c_uint = 0,
    rrs: [4]AresDnsRr = @splat(.{}),
    rr_cnt: usize = 0,
};

pub fn ares_version(version: ?*c_int) callconv(.c) [*:0]const u8 {
    if (version) |v| {
        v.* = (1 << 16) | (34 << 8) | 0;
    }
    return "1.34.0";
}

pub fn ares_library_init(flags: c_int) callconv(.c) c_int {
    _ = flags;
    return ARES_SUCCESS;
}

pub fn ares_library_cleanup() callconv(.c) void {}

pub fn ares_init_options(channelptr: ?*?*anyopaque, options: ?*anyopaque, optmask: c_int) callconv(.c) c_int {
    _ = options;
    _ = optmask;
    if (channelptr) |cp| {
        cp.* = @ptrFromInt(1);
    }
    return ARES_SUCCESS;
}

pub fn ares_init(channelptr: ?*?*anyopaque) callconv(.c) c_int {
    return ares_init_options(channelptr, null, 0);
}

pub fn ares_destroy(channel: ?*anyopaque) callconv(.c) void {
    _ = channel;
}

pub fn ares_cancel(channel: ?*anyopaque) callconv(.c) void {
    _ = channel;
}

pub fn ares_dup(dest: ?*?*anyopaque, src: ?*anyopaque) callconv(.c) c_int {
    if (dest) |d| {
        d.* = src orelse @ptrFromInt(1);
    }
    return ARES_SUCCESS;
}

pub fn ares_strerror(code: c_int) callconv(.c) [*:0]const u8 {
    return switch (code) {
        ARES_SUCCESS => "ARES_SUCCESS",
        ARES_ENODATA => "DNS server returned answer with no data",
        ARES_EFORMERR => "DNS server claims query was misformatted",
        ARES_ESERVFAIL => "DNS server returned general failure",
        ARES_ENOTFOUND => "Domain name not found",
        ARES_ENOTIMP => "DNS server does not implement requested operation",
        ARES_EREFUSED => "DNS server refused query",
        ARES_EBADQUERY => "Misformatted DNS query",
        ARES_EBADNAME => "Misformatted domain name",
        ARES_EBADFAMILY => "Unsupported address family",
        ARES_EBADRESP => "Misformatted DNS reply",
        ARES_ECONNREFUSED => "Could not contact DNS servers",
        ARES_ETIMEOUT => "Timeout while contacting DNS servers",
        ARES_EOF => "End of file",
        ARES_EFILE => "Error reading file",
        ARES_ENOMEM => "Out of memory",
        ARES_EDESTRUCTION => "Channel is being destroyed",
        else => "Unknown c-ares error",
    };
}

pub fn ares_getsock(channel: ?*anyopaque, socks: ?[*]c_int, numsocks: c_int) callconv(.c) c_int {
    _ = channel;
    _ = socks;
    _ = numsocks;
    return 0;
}

pub fn ares_timeout(channel: ?*anyopaque, maxtv: ?*anyopaque, tvbuf: ?*anyopaque) callconv(.c) ?*anyopaque {
    _ = channel;
    _ = tvbuf;
    return maxtv;
}

pub fn ares_process_fd(channel: ?*anyopaque, read_fd: c_int, write_fd: c_int) callconv(.c) void {
    _ = channel;
    _ = read_fd;
    _ = write_fd;
}

pub fn ares_set_local_ip4(channel: ?*anyopaque, local_ip: c_uint) callconv(.c) void {
    _ = channel;
    _ = local_ip;
}

pub fn ares_set_local_ip6(channel: ?*anyopaque, local_ip6: ?[*]const u8) callconv(.c) void {
    _ = channel;
    _ = local_ip6;
}

pub fn ares_set_local_dev(channel: ?*anyopaque, local_dev_name: ?[*:0]const u8) callconv(.c) void {
    _ = channel;
    _ = local_dev_name;
}

pub fn ares_set_servers_csv(channel: ?*anyopaque, servers: ?[*:0]const u8) callconv(.c) c_int {
    _ = channel;
    _ = servers;
    return ARES_SUCCESS;
}

pub fn ares_set_servers_ports_csv(channel: ?*anyopaque, servers: ?[*:0]const u8) callconv(.c) c_int {
    _ = channel;
    _ = servers;
    return ARES_SUCCESS;
}

pub fn ares_get_servers_csv(channel: ?*anyopaque) callconv(.c) ?[*:0]u8 {
    _ = channel;
    return cStrdupSlice("127.0.0.1");
}

pub fn ares_free_string(str: ?*anyopaque) callconv(.c) void {
    mem.free(str);
}

pub fn ares_getaddrinfo(
    channel: ?*anyopaque,
    name: ?[*:0]const u8,
    service: ?[*:0]const u8,
    hints: ?*const anyopaque,
    callback: ?AresAddrinfoCallback,
    arg: ?*anyopaque,
) callconv(.c) void {
    _ = channel;
    _ = name;
    _ = service;
    _ = hints;
    if (callback) |cb| {
        cb(arg, ARES_ENOTFOUND, 0, null);
    }
}

pub fn ares_freeaddrinfo(ai: ?*anyopaque) callconv(.c) void {
    _ = ai;
}

pub fn ares_query(
    channel: ?*anyopaque,
    name: ?[*:0]const u8,
    dnsclass: c_int,
    rtype: c_int,
    callback: ?AresCallback,
    arg: ?*anyopaque,
) callconv(.c) void {
    _ = channel;
    _ = name;
    _ = dnsclass;
    _ = rtype;
    if (callback) |cb| {
        cb(arg, ARES_ENOTFOUND, 0, null, 0);
    }
}

pub fn ares_send(
    channel: ?*anyopaque,
    qbuf: ?[*]const u8,
    qlen: c_int,
    callback: ?AresCallback,
    arg: ?*anyopaque,
) callconv(.c) void {
    _ = channel;
    _ = qbuf;
    _ = qlen;
    if (callback) |cb| {
        cb(arg, ARES_ENOTFOUND, 0, null, 0);
    }
}

fn createAresDnsRecord(id: u16, flags: u16, opcode: c_uint, rcode: c_uint) !*AresDnsRecord {
    const rec = mem.create(AresDnsRecord) orelse return error.OutOfMemory;
    errdefer mem.freeTyped(rec);
    rec.* = .{
        .id = id,
        .flags = flags,
        .opcode = opcode,
        .rcode = rcode,
    };
    return rec;
}

pub fn ares_dns_record_create(
    dnsrec: ?*?*AresDnsRecord,
    id: u16,
    flags: u16,
    opcode: c_uint,
    rcode: c_uint,
) callconv(.c) c_int {
    const out = dnsrec orelse return ARES_EBADQUERY;
    out.* = createAresDnsRecord(id, flags, opcode, rcode) catch return ARES_ENOMEM;
    return ARES_SUCCESS;
}

pub fn ares_dns_record_destroy(dnsrec: ?*AresDnsRecord) callconv(.c) void {
    mem.freeTyped(dnsrec);
}

pub fn ares_dns_record_query_add(
    dnsrec: ?*AresDnsRecord,
    name: ?[*:0]const u8,
    qtype: c_uint,
    qclass: c_uint,
) callconv(.c) c_int {
    _ = dnsrec;
    _ = name;
    _ = qtype;
    _ = qclass;
    return ARES_SUCCESS;
}

pub fn ares_dns_write(
    dnsrec: ?*const AresDnsRecord,
    buf: ?*?[*]u8,
    buf_len: ?*usize,
) callconv(.c) c_int {
    _ = dnsrec;
    const out_buf = buf orelse return ARES_EBADQUERY;
    const out_len = buf_len orelse return ARES_EBADQUERY;
    const raw = mem.callocMany(u8, 12) orelse return ARES_ENOMEM;
    out_buf.* = raw;
    out_len.* = 12;
    return ARES_SUCCESS;
}

pub fn ares_dns_parse(
    buf: ?[*]const u8,
    buf_len: usize,
    flags: c_uint,
    dnsrec: ?*?*AresDnsRecord,
) callconv(.c) c_int {
    _ = flags;
    const out = dnsrec orelse return ARES_EBADQUERY;
    if (buf == null or buf_len < 12) {
        out.* = null;
        return ARES_EBADRESP;
    }
    return ares_dns_record_create(out, 0, 0, 0, 0);
}

pub fn ares_dns_record_rr_add(
    rr_out: ?*?*AresDnsRr,
    dnsrec: ?*AresDnsRecord,
    sect: c_uint,
    name: ?[*:0]const u8,
    rtype: c_uint,
    rclass: c_uint,
    ttl: c_uint,
) callconv(.c) c_int {
    _ = name;
    const rec = dnsrec orelse return ARES_EBADQUERY;
    if (rec.rr_cnt >= rec.rrs.len) return ARES_ENOMEM;
    const rr = &rec.rrs[rec.rr_cnt];
    rr.* = .{
        .sect = sect,
        .rtype = rtype,
        .rclass = rclass,
        .ttl = ttl,
    };
    rec.rr_cnt += 1;
    if (rr_out) |out| {
        out.* = rr;
    }
    return ARES_SUCCESS;
}

pub fn ares_dns_record_rr_cnt(dnsrec: ?*const AresDnsRecord, sect: c_uint) callconv(.c) usize {
    const rec = dnsrec orelse return 0;
    var cnt: usize = 0;
    for (rec.rrs[0..rec.rr_cnt]) |rr| {
        if (rr.sect == sect) cnt += 1;
    }
    return cnt;
}

pub fn ares_dns_record_rr_get(dnsrec: ?*AresDnsRecord, sect: c_uint, idx: usize) callconv(.c) ?*AresDnsRr {
    const rec = dnsrec orelse return null;
    var cur: usize = 0;
    for (&rec.rrs, 0..) |*rr, i| {
        if (i >= rec.rr_cnt) break;
        if (rr.sect == sect) {
            if (cur == idx) return rr;
            cur += 1;
        }
    }
    return null;
}

pub fn ares_dns_rr_get_type(dns_rr: ?*const AresDnsRr) callconv(.c) c_uint {
    const rr = dns_rr orelse return 0;
    return rr.rtype;
}

pub fn ares_dns_rr_get_ttl(dns_rr: ?*const AresDnsRr) callconv(.c) c_uint {
    const rr = dns_rr orelse return 0;
    return rr.ttl;
}

pub fn ares_dns_rr_get_u16(dns_rr: ?*const AresDnsRr, key: c_uint) callconv(.c) u16 {
    _ = key;
    const rr = dns_rr orelse return 0;
    return rr.u16_val;
}

pub fn ares_dns_rr_get_str(dns_rr: ?*const AresDnsRr, key: c_uint) callconv(.c) ?[*:0]const u8 {
    _ = key;
    const rr = dns_rr orelse return null;
    return &rr.str_val;
}

pub fn ares_dns_rr_get_opt_cnt(dns_rr: ?*const AresDnsRr, key: c_uint) callconv(.c) usize {
    _ = key;
    const rr = dns_rr orelse return 0;
    return rr.opt_cnt;
}

pub fn ares_dns_rr_get_opt(
    dns_rr: ?*const AresDnsRr,
    key: c_uint,
    idx: usize,
    val: ?*?[*]const u8,
    val_len: ?*usize,
) callconv(.c) u16 {
    _ = key;
    const rr = dns_rr orelse return 0xffff;
    if (idx >= rr.opt_cnt) return 0xffff;
    const entry = &rr.opts[idx];
    if (val) |v| v.* = &entry.val;
    if (val_len) |vl| vl.* = entry.val_len;
    return entry.opt;
}

pub fn ares_dns_rr_get_opt_byid(
    dns_rr: ?*const AresDnsRr,
    key: c_uint,
    opt: u16,
    val: ?*?[*]const u8,
    val_len: ?*usize,
) callconv(.c) bool {
    _ = key;
    const rr = dns_rr orelse return false;
    for (rr.opts[0..rr.opt_cnt]) |*entry| {
        if (entry.opt == opt) {
            if (val) |v| v.* = &entry.val;
            if (val_len) |vl| vl.* = entry.val_len;
            return true;
        }
    }
    return false;
}

pub fn ares_dns_rr_set_u16(dns_rr: ?*AresDnsRr, key: c_uint, val: u16) callconv(.c) c_int {
    _ = key;
    const rr = dns_rr orelse return ARES_EBADQUERY;
    rr.u16_val = val;
    return ARES_SUCCESS;
}

pub fn ares_dns_rr_set_str(dns_rr: ?*AresDnsRr, key: c_uint, val: ?[*:0]const u8) callconv(.c) c_int {
    _ = key;
    const rr = dns_rr orelse return ARES_EBADQUERY;
    @memset(&rr.str_val, 0);
    if (val) |v| {
        const s = std.mem.span(v);
        const copy_len = @min(s.len, rr.str_val.len - 1);
        @memcpy(rr.str_val[0..copy_len], s[0..copy_len]);
        rr.str_val[copy_len] = 0;
    }
    return ARES_SUCCESS;
}

pub fn ares_dns_rr_set_opt(
    dns_rr: ?*AresDnsRr,
    key: c_uint,
    opt: u16,
    val: ?[*]const u8,
    val_len: usize,
) callconv(.c) c_int {
    _ = key;
    const rr = dns_rr orelse return ARES_EBADQUERY;
    if (rr.opt_cnt >= rr.opts.len) return ARES_ENOMEM;
    var entry = &rr.opts[rr.opt_cnt];
    entry.* = .{ .opt = opt };
    const copy_len = @min(val_len, entry.val.len);
    if (val) |v| {
        @memcpy(entry.val[0..copy_len], v[0..copy_len]);
    }
    entry.val_len = copy_len;
    rr.opt_cnt += 1;
    return ARES_SUCCESS;
}

// ============================================================================
// 4. Bundled nghttp2 (nghttp2_*)
// ============================================================================

pub const nghttp2_info = extern struct {
    age: c_int,
    version_num: c_int,
    version_str: [*:0]const u8,
    proto_str: [*:0]const u8,
};

var static_nghttp2_info: nghttp2_info = .{
    .age = 1,
    .version_num = 0x014000,
    .version_str = "1.64.0",
    .proto_str = "h2",
};

pub const nghttp2_priority_spec = extern struct {
    stream_id: i32,
    weight: i32,
    exclusive: u8,
};

pub const nghttp2_settings_entry = extern struct {
    settings_id: i32,
    value: u32,
};

const Nghttp2Option = struct {
    no_auto_window_update: c_int = 0,
    no_rfc9113_ws_validation: c_int = 0,
};

const Nghttp2Callbacks = struct {
    send_cb: ?*const anyopaque = null,
    on_frame_recv_cb: ?*const anyopaque = null,
    on_invalid_frame_recv_cb: ?*const anyopaque = null,
    on_data_chunk_recv_cb: ?*const anyopaque = null,
    before_frame_send_cb: ?*const anyopaque = null,
    on_frame_send_cb: ?*const anyopaque = null,
    on_frame_not_send_cb: ?*const anyopaque = null,
    on_stream_close_cb: ?*const anyopaque = null,
    on_begin_headers_cb: ?*const anyopaque = null,
    on_header_cb: ?*const anyopaque = null,
    error_cb2: ?*const anyopaque = null,
    send_data_cb: ?*const anyopaque = null,
};

const Nghttp2StreamEntry = struct {
    stream_id: i32 = 0,
    user_data: ?*anyopaque = null,
};

const Nghttp2Session = struct {
    callbacks: Nghttp2Callbacks = .{},
    user_data: ?*anyopaque = null,
    next_stream_id: i32 = 1,
    local_window_size: i32 = 65535,
    streams: [32]Nghttp2StreamEntry = @splat(.{}),
};

pub fn nghttp2_version(least_version: c_int) callconv(.c) ?*nghttp2_info {
    if (least_version > static_nghttp2_info.version_num) return null;
    return &static_nghttp2_info;
}

pub fn nghttp2_strerror(error_code: c_int) callconv(.c) [*:0]const u8 {
    if (error_code == 0) return "Success";
    return "nghttp2";
}

pub fn nghttp2_http2_strerror(error_code: u32) callconv(.c) [*:0]const u8 {
    _ = error_code;
    return "NO_ERROR";
}

pub fn nghttp2_is_fatal(error_code: c_int) callconv(.c) c_int {
    return if (error_code < -500) 1 else 0;
}

pub fn nghttp2_priority_spec_init(
    pri_spec: ?*nghttp2_priority_spec,
    stream_id: i32,
    weight: i32,
    exclusive: c_int,
) callconv(.c) void {
    if (pri_spec) |ps| {
        ps.stream_id = stream_id;
        ps.weight = weight;
        ps.exclusive = if (exclusive != 0) 1 else 0;
    }
}

pub fn nghttp2_option_new(option_ptr: ?*?*Nghttp2Option) callconv(.c) c_int {
    const out = option_ptr orelse return -501;
    const opt = mem.create(Nghttp2Option) orelse return -901;
    out.* = opt;
    return 0;
}

pub fn nghttp2_option_del(option: ?*Nghttp2Option) callconv(.c) void {
    mem.freeTyped(option);
}

pub fn nghttp2_option_set_no_auto_window_update(option: ?*Nghttp2Option, val: c_int) callconv(.c) void {
    const opt = option orelse return;
    opt.no_auto_window_update = val;
}

pub fn nghttp2_option_set_no_rfc9113_leading_and_trailing_ws_validation(option: ?*Nghttp2Option, val: c_int) callconv(.c) void {
    const opt = option orelse return;
    opt.no_rfc9113_ws_validation = val;
}

pub fn nghttp2_session_callbacks_new(callbacks_ptr: ?*?*Nghttp2Callbacks) callconv(.c) c_int {
    const out = callbacks_ptr orelse return -501;
    const cbs = mem.create(Nghttp2Callbacks) orelse return -901;
    out.* = cbs;
    return 0;
}

pub fn nghttp2_session_callbacks_del(callbacks: ?*Nghttp2Callbacks) callconv(.c) void {
    mem.freeTyped(callbacks);
}

pub fn nghttp2_session_callbacks_set_send_callback(cbs: ?*Nghttp2Callbacks, cb: ?*const anyopaque) callconv(.c) void {
    const c = cbs orelse return;
    c.send_cb = cb;
}

pub fn nghttp2_session_callbacks_set_on_frame_recv_callback(cbs: ?*Nghttp2Callbacks, cb: ?*const anyopaque) callconv(.c) void {
    const c = cbs orelse return;
    c.on_frame_recv_cb = cb;
}

pub fn nghttp2_session_callbacks_set_on_invalid_frame_recv_callback(cbs: ?*Nghttp2Callbacks, cb: ?*const anyopaque) callconv(.c) void {
    const c = cbs orelse return;
    c.on_invalid_frame_recv_cb = cb;
}

pub fn nghttp2_session_callbacks_set_on_data_chunk_recv_callback(cbs: ?*Nghttp2Callbacks, cb: ?*const anyopaque) callconv(.c) void {
    const c = cbs orelse return;
    c.on_data_chunk_recv_cb = cb;
}

pub fn nghttp2_session_callbacks_set_before_frame_send_callback(cbs: ?*Nghttp2Callbacks, cb: ?*const anyopaque) callconv(.c) void {
    const c = cbs orelse return;
    c.before_frame_send_cb = cb;
}

pub fn nghttp2_session_callbacks_set_on_frame_send_callback(cbs: ?*Nghttp2Callbacks, cb: ?*const anyopaque) callconv(.c) void {
    const c = cbs orelse return;
    c.on_frame_send_cb = cb;
}

pub fn nghttp2_session_callbacks_set_on_frame_not_send_callback(cbs: ?*Nghttp2Callbacks, cb: ?*const anyopaque) callconv(.c) void {
    const c = cbs orelse return;
    c.on_frame_not_send_cb = cb;
}

pub fn nghttp2_session_callbacks_set_on_stream_close_callback(cbs: ?*Nghttp2Callbacks, cb: ?*const anyopaque) callconv(.c) void {
    const c = cbs orelse return;
    c.on_stream_close_cb = cb;
}

pub fn nghttp2_session_callbacks_set_on_begin_headers_callback(cbs: ?*Nghttp2Callbacks, cb: ?*const anyopaque) callconv(.c) void {
    const c = cbs orelse return;
    c.on_begin_headers_cb = cb;
}

pub fn nghttp2_session_callbacks_set_on_header_callback(cbs: ?*Nghttp2Callbacks, cb: ?*const anyopaque) callconv(.c) void {
    const c = cbs orelse return;
    c.on_header_cb = cb;
}

pub fn nghttp2_session_callbacks_set_error_callback2(cbs: ?*Nghttp2Callbacks, cb: ?*const anyopaque) callconv(.c) void {
    const c = cbs orelse return;
    c.error_cb2 = cb;
}

pub fn nghttp2_session_callbacks_set_send_data_callback(cbs: ?*Nghttp2Callbacks, cb: ?*const anyopaque) callconv(.c) void {
    const c = cbs orelse return;
    c.send_data_cb = cb;
}

fn createNghttp2Session(callbacks: ?*const Nghttp2Callbacks, user_data: ?*anyopaque) !*Nghttp2Session {
    const sess = mem.create(Nghttp2Session) orelse return error.OutOfMemory;
    errdefer mem.freeTyped(sess);
    sess.* = .{
        .user_data = user_data,
    };
    if (callbacks) |cbs| {
        sess.callbacks = cbs.*;
    }
    return sess;
}

pub fn nghttp2_session_client_new3(
    session_ptr: ?*?*Nghttp2Session,
    callbacks: ?*const Nghttp2Callbacks,
    user_data: ?*anyopaque,
    option: ?*const Nghttp2Option,
    mem_arg: ?*anyopaque,
) callconv(.c) c_int {
    _ = option;
    _ = mem_arg;
    const out = session_ptr orelse return -501;
    out.* = createNghttp2Session(callbacks, user_data) catch return -901;
    return 0;
}

pub fn nghttp2_session_client_new2(
    session_ptr: ?*?*Nghttp2Session,
    callbacks: ?*const Nghttp2Callbacks,
    user_data: ?*anyopaque,
    option: ?*const Nghttp2Option,
) callconv(.c) c_int {
    return nghttp2_session_client_new3(session_ptr, callbacks, user_data, option, null);
}

pub fn nghttp2_session_client_new(
    session_ptr: ?*?*Nghttp2Session,
    callbacks: ?*const Nghttp2Callbacks,
    user_data: ?*anyopaque,
) callconv(.c) c_int {
    return nghttp2_session_client_new3(session_ptr, callbacks, user_data, null, null);
}

pub fn nghttp2_session_del(session: ?*Nghttp2Session) callconv(.c) void {
    mem.freeTyped(session);
}

pub fn nghttp2_session_send(session: ?*Nghttp2Session) callconv(.c) c_int {
    _ = session;
    return 0;
}

pub fn nghttp2_session_mem_recv(session: ?*Nghttp2Session, in_buf: ?[*]const u8, inlen: usize) callconv(.c) isize {
    _ = session;
    _ = in_buf;
    return @intCast(inlen);
}

pub fn nghttp2_session_mem_recv2(session: ?*Nghttp2Session, in_buf: ?[*]const u8, inlen: usize) callconv(.c) isize {
    return nghttp2_session_mem_recv(session, in_buf, inlen);
}

pub fn nghttp2_session_want_read(session: ?*Nghttp2Session) callconv(.c) c_int {
    _ = session;
    return 0;
}

pub fn nghttp2_session_want_write(session: ?*Nghttp2Session) callconv(.c) c_int {
    _ = session;
    return 0;
}

pub fn nghttp2_session_get_stream_user_data(session: ?*Nghttp2Session, stream_id: i32) callconv(.c) ?*anyopaque {
    const sess = session orelse return null;
    if (stream_id <= 0) return null;
    for (sess.streams) |entry| {
        if (entry.stream_id == stream_id) return entry.user_data;
    }
    return null;
}

pub fn nghttp2_session_set_stream_user_data(
    session: ?*Nghttp2Session,
    stream_id: i32,
    stream_user_data: ?*anyopaque,
) callconv(.c) c_int {
    const sess = session orelse return -501;
    if (stream_id <= 0) return -501;
    for (&sess.streams) |*entry| {
        if (entry.stream_id == stream_id or entry.stream_id == 0) {
            entry.stream_id = stream_id;
            entry.user_data = stream_user_data;
            return 0;
        }
    }
    sess.streams[0] = .{ .stream_id = stream_id, .user_data = stream_user_data };
    return 0;
}

pub fn nghttp2_session_get_remote_settings(session: ?*Nghttp2Session, id: c_int) callconv(.c) u32 {
    _ = session;
    return switch (id) {
        2 => 1,
        3 => 100,
        4 => 65535,
        5 => 16384,
        else => 4096,
    };
}

pub fn nghttp2_session_consume(session: ?*Nghttp2Session, stream_id: i32, size: usize) callconv(.c) c_int {
    _ = session;
    _ = stream_id;
    _ = size;
    return 0;
}

pub fn nghttp2_session_upgrade2(
    session: ?*Nghttp2Session,
    settings_payload: ?[*]const u8,
    settings_payloadlen: usize,
    head_request: c_int,
    stream_user_data: ?*anyopaque,
) callconv(.c) c_int {
    _ = settings_payload;
    _ = settings_payloadlen;
    _ = head_request;
    if (stream_user_data != null) {
        _ = nghttp2_session_set_stream_user_data(session, 1, stream_user_data);
    }
    return 0;
}

pub fn nghttp2_pack_settings_payload(
    buf: ?[*]u8,
    buflen: usize,
    iv: ?[*]const nghttp2_settings_entry,
    niv: usize,
) callconv(.c) isize {
    const needed = niv * 6;
    if (buflen < needed) return -522;
    if (needed == 0) return 0;
    const out = buf orelse return -501;
    const entries = iv orelse return -501;
    for (0..niv) |idx| {
        const off = idx * 6;
        const id_u16: u16 = @intCast(@as(u32, @bitCast(entries[idx].settings_id)) & 0xffff);
        std.mem.writeInt(u16, out[off..][0..2], id_u16, .big);
        std.mem.writeInt(u32, out[off + 2 ..][0..4], entries[idx].value, .big);
    }
    return @intCast(needed);
}

pub fn nghttp2_pack_settings_payload2(
    buf: ?[*]u8,
    buflen: usize,
    iv: ?[*]const nghttp2_settings_entry,
    niv: usize,
) callconv(.c) isize {
    return nghttp2_pack_settings_payload(buf, buflen, iv, niv);
}

pub fn nghttp2_submit_settings(
    session: ?*Nghttp2Session,
    flags: u8,
    iv: ?[*]const nghttp2_settings_entry,
    niv: usize,
) callconv(.c) c_int {
    _ = session;
    _ = flags;
    _ = iv;
    _ = niv;
    return 0;
}

pub fn nghttp2_submit_request(
    session: ?*Nghttp2Session,
    pri_spec: ?*const nghttp2_priority_spec,
    nva: ?*const anyopaque,
    nvlen: usize,
    data_prd: ?*const anyopaque,
    stream_user_data: ?*anyopaque,
) callconv(.c) i32 {
    _ = pri_spec;
    _ = nva;
    _ = nvlen;
    _ = data_prd;
    const sess = session orelse return -501;
    const sid = sess.next_stream_id;
    sess.next_stream_id += 2;
    _ = nghttp2_session_set_stream_user_data(sess, sid, stream_user_data);
    return sid;
}

pub fn nghttp2_submit_request2(
    session: ?*Nghttp2Session,
    pri_spec: ?*const nghttp2_priority_spec,
    nva: ?*const anyopaque,
    nvlen: usize,
    data_prd: ?*const anyopaque,
    stream_user_data: ?*anyopaque,
) callconv(.c) i32 {
    return nghttp2_submit_request(session, pri_spec, nva, nvlen, data_prd, stream_user_data);
}

pub fn nghttp2_submit_rst_stream(
    session: ?*Nghttp2Session,
    flags: u8,
    stream_id: i32,
    error_code: u32,
) callconv(.c) c_int {
    _ = session;
    _ = flags;
    _ = stream_id;
    _ = error_code;
    return 0;
}

pub fn nghttp2_submit_ping(
    session: ?*Nghttp2Session,
    flags: u8,
    opaque_data: ?[*]const u8,
) callconv(.c) c_int {
    _ = session;
    _ = flags;
    _ = opaque_data;
    return 0;
}

pub fn nghttp2_submit_goaway(
    session: ?*Nghttp2Session,
    flags: u8,
    last_stream_id: i32,
    error_code: u32,
    opaque_data: ?[*]const u8,
    opaque_data_len: usize,
) callconv(.c) c_int {
    _ = session;
    _ = flags;
    _ = last_stream_id;
    _ = error_code;
    _ = opaque_data;
    _ = opaque_data_len;
    return 0;
}

pub fn nghttp2_submit_priority(
    session: ?*Nghttp2Session,
    flags: u8,
    stream_id: i32,
    pri_spec: ?*const nghttp2_priority_spec,
) callconv(.c) c_int {
    _ = session;
    _ = flags;
    _ = stream_id;
    _ = pri_spec;
    return 0;
}

pub fn nghttp2_submit_window_update(
    session: ?*Nghttp2Session,
    flags: u8,
    stream_id: i32,
    window_size_increment: i32,
) callconv(.c) c_int {
    _ = session;
    _ = flags;
    _ = stream_id;
    _ = window_size_increment;
    return 0;
}

pub fn nghttp2_session_resume_data(session: ?*Nghttp2Session, stream_id: i32) callconv(.c) c_int {
    _ = session;
    _ = stream_id;
    return 0;
}

pub fn nghttp2_session_check_request_allowed(session: ?*Nghttp2Session) callconv(.c) c_int {
    _ = session;
    return 1;
}

pub fn nghttp2_session_get_stream_effective_recv_data_length(session: ?*Nghttp2Session, stream_id: i32) callconv(.c) i32 {
    _ = session;
    _ = stream_id;
    return 0;
}

pub fn nghttp2_session_get_stream_effective_local_window_size(session: ?*Nghttp2Session, stream_id: i32) callconv(.c) i32 {
    _ = stream_id;
    const sess = session orelse return 65535;
    return sess.local_window_size;
}

pub fn nghttp2_session_get_stream_local_window_size(session: ?*Nghttp2Session, stream_id: i32) callconv(.c) i32 {
    return nghttp2_session_get_stream_effective_local_window_size(session, stream_id);
}

pub fn nghttp2_session_set_local_window_size(
    session: ?*Nghttp2Session,
    flags: u8,
    stream_id: i32,
    window_size: i32,
) callconv(.c) c_int {
    _ = flags;
    _ = stream_id;
    const sess = session orelse return -501;
    sess.local_window_size = window_size;
    return 0;
}

pub fn nghttp2_session_get_local_window_size(session: ?*Nghttp2Session) callconv(.c) i32 {
    const sess = session orelse return 65535;
    return sess.local_window_size;
}

pub fn nghttp2_session_get_stream_remote_window_size(session: ?*Nghttp2Session, stream_id: i32) callconv(.c) i32 {
    _ = session;
    _ = stream_id;
    return 65535;
}

pub fn nghttp2_session_get_remote_window_size(session: ?*Nghttp2Session) callconv(.c) i32 {
    _ = session;
    return 65535;
}

// ============================================================================
// 5. Bundled ngtcp2 & nghttp3 (ngtcp2_*, nghttp3_*)
// ============================================================================

pub const ngtcp2_info = extern struct {
    age: c_int,
    version_num: c_int,
    version_str: [*:0]const u8,
};

pub const nghttp3_info = extern struct {
    age: c_int,
    version_num: c_int,
    version_str: [*:0]const u8,
};

var static_ngtcp2_info: ngtcp2_info = .{
    .age = 1,
    .version_num = 0x011000,
    .version_str = "1.16.0",
};

var static_nghttp3_info: nghttp3_info = .{
    .age = 1,
    .version_num = 0x010c00,
    .version_str = "1.12.0",
};

pub const NGTCP2_MAX_CIDLEN: usize = 20;
pub const NGTCP2_STATELESS_RESET_TOKENLEN: usize = 16;

pub const ngtcp2_cid = extern struct {
    datalen: usize = 0,
    data: [NGTCP2_MAX_CIDLEN]u8 = @splat(0),
};

pub const ngtcp2_vec = extern struct {
    base: ?[*]u8 = null,
    len: usize = 0,
};

pub const ngtcp2_addr = extern struct {
    addr: ?[*]u8 = null,
    addrlen: u32 = 0,
};

pub const ngtcp2_path = extern struct {
    local: ngtcp2_addr = .{},
    remote: ngtcp2_addr = .{},
    user_data: ?*anyopaque = null,
};

pub const ngtcp2_path_storage = extern struct {
    path: ngtcp2_path = .{},
    local_addrbuf: [128]u8 align(8) = @splat(0),
    remote_addrbuf: [128]u8 align(8) = @splat(0),
};

pub const ngtcp2_pkt_info = extern struct {
    ecn: u8 align(8) = 0,
};

pub const ngtcp2_ccerr = extern struct {
    type: c_uint = 0,
    error_code: u64 = 0,
    frame_type: u64 = 0,
    reason: ?[*]const u8 = null,
    reasonlen: usize = 0,
};

pub const ngtcp2_version_cid = extern struct {
    version: u32 = 0,
    dcid: ?[*]const u8 = null,
    dcidlen: usize = 0,
    scid: ?[*]const u8 = null,
    scidlen: usize = 0,
};

pub const nghttp3_buf = extern struct {
    begin: ?[*]u8 = null,
    pos: ?[*]u8 = null,
    last: ?[*]u8 = null,
    end: ?[*]u8 = null,
};

const Ngtcp2Conn = struct {
    path_storage: ngtcp2_path_storage = .{},
    dcid: ngtcp2_cid = .{},
    scid: ngtcp2_cid = .{},
    remote_params: [512]u8 align(8) = @splat(0),
    user_data: ?*anyopaque = null,
    tls_native_handle: ?*anyopaque = null,
    tls_alert: u8 = 0,
    handshake_completed: c_int = 0,
    initial_pkt_sent: bool = false,
    next_bidi_stream_id: i64 = 0,
    next_uni_stream_id: i64 = 2,
};

const Nghttp3Conn = struct {
    user_data: ?*anyopaque = null,
};

pub fn ngtcp2_version(least_version: c_int) callconv(.c) ?*const ngtcp2_info {
    if (least_version > static_ngtcp2_info.version_num) return null;
    return &static_ngtcp2_info;
}

pub fn nghttp3_version(least_version: c_int) callconv(.c) ?*const nghttp3_info {
    if (least_version > static_nghttp3_info.version_num) return null;
    return &static_nghttp3_info;
}

pub fn ngtcp2_cid_init(cid: ?*ngtcp2_cid, data: ?[*]const u8, datalen: usize) callconv(.c) void {
    const c = cid orelse return;
    c.* = .{};
    const copy_len = @min(datalen, NGTCP2_MAX_CIDLEN);
    c.datalen = copy_len;
    if (data) |d| {
        @memcpy(c.data[0..copy_len], d[0..copy_len]);
    }
}

pub fn ngtcp2_settings_default_versioned(settings_version: c_int, settings: ?*[128]u8) callconv(.c) void {
    _ = settings_version;
    const ptr = settings orelse return;
    @memset(ptr, 0);
}

pub fn ngtcp2_settings_default(settings: ?*[128]u8) callconv(.c) void {
    ngtcp2_settings_default_versioned(3, settings);
}

pub fn ngtcp2_transport_params_default_versioned(transport_params_version: c_int, params: ?*[256]u8) callconv(.c) void {
    _ = transport_params_version;
    const ptr = params orelse return;
    @memset(ptr, 0);
}

pub fn ngtcp2_transport_params_default(params: ?*[256]u8) callconv(.c) void {
    ngtcp2_transport_params_default_versioned(1, params);
}

pub fn ngtcp2_ccerr_default(ccerr: ?*ngtcp2_ccerr) callconv(.c) void {
    const c = ccerr orelse return;
    c.* = .{};
}

pub fn ngtcp2_ccerr_set_application_error(
    ccerr: ?*ngtcp2_ccerr,
    error_code: u64,
    reason: ?[*]const u8,
    reasonlen: usize,
) callconv(.c) void {
    const c = ccerr orelse return;
    c.* = .{
        .type = 1,
        .error_code = error_code,
        .frame_type = 0,
        .reason = reason,
        .reasonlen = reasonlen,
    };
}

pub fn ngtcp2_ccerr_set_transport_error(
    ccerr: ?*ngtcp2_ccerr,
    error_code: u64,
    reason: ?[*]const u8,
    reasonlen: usize,
) callconv(.c) void {
    const c = ccerr orelse return;
    c.* = .{
        .type = 0,
        .error_code = error_code,
        .frame_type = 0,
        .reason = reason,
        .reasonlen = reasonlen,
    };
}

pub fn ngtcp2_ccerr_set_tls_alert(
    ccerr: ?*ngtcp2_ccerr,
    alert: u8,
    reason: ?[*]const u8,
    reasonlen: usize,
) callconv(.c) void {
    const c = ccerr orelse return;
    c.* = .{
        .type = 0,
        .error_code = 0x100 | @as(u64, alert),
        .frame_type = 0,
        .reason = reason,
        .reasonlen = reasonlen,
    };
}

pub fn ngtcp2_ccerr_set_liberr(
    ccerr: ?*ngtcp2_ccerr,
    liberr: c_int,
    reason: ?[*]const u8,
    reasonlen: usize,
) callconv(.c) void {
    _ = liberr;
    const c = ccerr orelse return;
    c.* = .{
        .type = 0,
        .error_code = 0x01,
        .frame_type = 0,
        .reason = reason,
        .reasonlen = reasonlen,
    };
}

pub fn ngtcp2_path_storage_zero(ps: ?*ngtcp2_path_storage) callconv(.c) void {
    const p = ps orelse return;
    p.path = .{
        .local = .{ .addr = &p.local_addrbuf, .addrlen = 0 },
        .remote = .{ .addr = &p.remote_addrbuf, .addrlen = 0 },
        .user_data = null,
    };
}

pub fn ngtcp2_path_storage_init(
    ps: ?*ngtcp2_path_storage,
    local_addr: ?[*]const u8,
    local_addrlen: u32,
    remote_addr: ?[*]const u8,
    remote_addrlen: u32,
    user_data: ?*anyopaque,
) callconv(.c) void {
    const p = ps orelse return;
    ngtcp2_path_storage_zero(p);
    if (local_addr) |lsrc| {
        const lcopy = @min(@as(usize, local_addrlen), 28);
        @memcpy(p.local_addrbuf[0..lcopy], lsrc[0..lcopy]);
        p.path.local.addrlen = @intCast(lcopy);
    }
    if (remote_addr) |rsrc| {
        const rcopy = @min(@as(usize, remote_addrlen), 28);
        @memcpy(p.remote_addrbuf[0..rcopy], rsrc[0..rcopy]);
        p.path.remote.addrlen = @intCast(rcopy);
    }
    p.path.user_data = user_data;
}

fn createNgtcp2Conn(
    dcid: ?*const ngtcp2_cid,
    scid: ?*const ngtcp2_cid,
    path: ?*const ngtcp2_path,
    user_data: ?*anyopaque,
) !*Ngtcp2Conn {
    const conn = mem.create(Ngtcp2Conn) orelse return error.OutOfMemory;
    errdefer mem.freeTyped(conn);
    conn.* = .{
        .user_data = user_data,
    };
    if (dcid) |d| conn.dcid = d.*;
    if (scid) |s| conn.scid = s.*;
    if (path) |p| {
        ngtcp2_path_storage_init(
            &conn.path_storage,
            p.local.addr,
            p.local.addrlen,
            p.remote.addr,
            p.remote.addrlen,
            p.user_data,
        );
    } else {
        ngtcp2_path_storage_zero(&conn.path_storage);
    }
    return conn;
}

pub fn ngtcp2_conn_client_new_versioned(
    pconn: ?*?*Ngtcp2Conn,
    dcid: ?*const ngtcp2_cid,
    scid: ?*const ngtcp2_cid,
    path: ?*const ngtcp2_path,
    client_chosen_version: u32,
    callbacks_version: c_int,
    callbacks: ?*const anyopaque,
    settings_version: c_int,
    settings: ?*const anyopaque,
    transport_params_version: c_int,
    params: ?*const anyopaque,
    mem_arg: ?*const anyopaque,
    user_data: ?*anyopaque,
) callconv(.c) c_int {
    _ = client_chosen_version;
    _ = callbacks_version;
    _ = callbacks;
    _ = settings_version;
    _ = settings;
    _ = transport_params_version;
    _ = params;
    _ = mem_arg;
    const out = pconn orelse return -201;
    out.* = createNgtcp2Conn(dcid, scid, path, user_data) catch return -501;
    return 0;
}

pub fn ngtcp2_conn_client_new(
    pconn: ?*?*Ngtcp2Conn,
    dcid: ?*const ngtcp2_cid,
    scid: ?*const ngtcp2_cid,
    path: ?*const ngtcp2_path,
    client_chosen_version: u32,
    callbacks: ?*const anyopaque,
    settings: ?*const anyopaque,
    params: ?*const anyopaque,
    mem_arg: ?*const anyopaque,
    user_data: ?*anyopaque,
) callconv(.c) c_int {
    return ngtcp2_conn_client_new_versioned(
        pconn,
        dcid,
        scid,
        path,
        client_chosen_version,
        2,
        callbacks,
        3,
        settings,
        1,
        params,
        mem_arg,
        user_data,
    );
}

pub fn ngtcp2_conn_server_new_versioned(
    pconn: ?*?*Ngtcp2Conn,
    dcid: ?*const ngtcp2_cid,
    scid: ?*const ngtcp2_cid,
    path: ?*const ngtcp2_path,
    version: u32,
    callbacks_version: c_int,
    callbacks: ?*const anyopaque,
    settings_version: c_int,
    settings: ?*const anyopaque,
    transport_params_version: c_int,
    params: ?*const anyopaque,
    mem_arg: ?*const anyopaque,
    user_data: ?*anyopaque,
) callconv(.c) c_int {
    return ngtcp2_conn_client_new_versioned(
        pconn,
        dcid,
        scid,
        path,
        version,
        callbacks_version,
        callbacks,
        settings_version,
        settings,
        transport_params_version,
        params,
        mem_arg,
        user_data,
    );
}

pub fn ngtcp2_conn_server_new(
    pconn: ?*?*Ngtcp2Conn,
    dcid: ?*const ngtcp2_cid,
    scid: ?*const ngtcp2_cid,
    path: ?*const ngtcp2_path,
    version: u32,
    callbacks: ?*const anyopaque,
    settings: ?*const anyopaque,
    params: ?*const anyopaque,
    mem_arg: ?*const anyopaque,
    user_data: ?*anyopaque,
) callconv(.c) c_int {
    return ngtcp2_conn_client_new(
        pconn,
        dcid,
        scid,
        path,
        version,
        callbacks,
        settings,
        params,
        mem_arg,
        user_data,
    );
}

pub fn ngtcp2_conn_del(conn: ?*Ngtcp2Conn) callconv(.c) void {
    mem.freeTyped(conn);
}

pub fn ngtcp2_conn_set_tls_native_handle(conn: ?*Ngtcp2Conn, tls_native_handle: ?*anyopaque) callconv(.c) void {
    const c = conn orelse return;
    c.tls_native_handle = tls_native_handle;
}

pub fn ngtcp2_conn_get_tls_alert(conn: ?*const Ngtcp2Conn) callconv(.c) u8 {
    const c = conn orelse return 0;
    return c.tls_alert;
}

pub fn ngtcp2_conn_get_handshake_completed(conn: ?*const Ngtcp2Conn) callconv(.c) c_int {
    const c = conn orelse return 0;
    return c.handshake_completed;
}

pub fn ngtcp2_conn_install_rx_key(
    conn: ?*anyopaque,
    aead: ?*const anyopaque,
    iv: ?[*]const u8,
    ivlen: usize,
    hp: ?*const anyopaque,
) callconv(.c) c_int {
    _ = conn;
    _ = aead;
    _ = iv;
    _ = ivlen;
    _ = hp;
    return 0;
}

pub fn ngtcp2_conn_install_tx_key(
    conn: ?*anyopaque,
    aead: ?*const anyopaque,
    iv: ?[*]const u8,
    ivlen: usize,
    hp: ?*const anyopaque,
) callconv(.c) c_int {
    _ = conn;
    _ = aead;
    _ = iv;
    _ = ivlen;
    _ = hp;
    return 0;
}

pub fn ngtcp2_conn_install_initial_key(
    conn: ?*anyopaque,
    rx_aead: ?*const anyopaque,
    rx_iv: ?[*]const u8,
    rx_hp: ?*const anyopaque,
    tx_aead: ?*const anyopaque,
    tx_iv: ?[*]const u8,
    tx_hp: ?*const anyopaque,
    ivlen: usize,
) callconv(.c) c_int {
    _ = conn;
    _ = rx_aead;
    _ = rx_iv;
    _ = rx_hp;
    _ = tx_aead;
    _ = tx_iv;
    _ = tx_hp;
    _ = ivlen;
    return 0;
}

pub fn ngtcp2_conn_install_rx_handshake_key(
    conn: ?*anyopaque,
    aead: ?*const anyopaque,
    iv: ?[*]const u8,
    ivlen: usize,
    hp: ?*const anyopaque,
) callconv(.c) c_int {
    _ = conn;
    _ = aead;
    _ = iv;
    _ = ivlen;
    _ = hp;
    return 0;
}

pub fn ngtcp2_conn_install_tx_handshake_key(
    conn: ?*anyopaque,
    aead: ?*const anyopaque,
    iv: ?[*]const u8,
    ivlen: usize,
    hp: ?*const anyopaque,
) callconv(.c) c_int {
    _ = conn;
    _ = aead;
    _ = iv;
    _ = ivlen;
    _ = hp;
    return 0;
}

pub fn ngtcp2_conn_in_closing_period(conn: ?*anyopaque) callconv(.c) c_int {
    _ = conn;
    return 0;
}

pub fn ngtcp2_conn_in_draining_period(conn: ?*anyopaque) callconv(.c) c_int {
    _ = conn;
    return 0;
}

pub fn ngtcp2_conn_get_expiry(conn: ?*anyopaque) callconv(.c) u64 {
    _ = conn;
    return std.math.maxInt(u64);
}

pub fn ngtcp2_conn_handle_expiry(conn: ?*anyopaque, ts: u64) callconv(.c) c_int {
    _ = conn;
    _ = ts;
    return 0;
}

pub fn ngtcp2_conn_get_send_quantum(conn: ?*anyopaque) callconv(.c) usize {
    _ = conn;
    return 1452;
}

pub fn ngtcp2_conn_get_path(conn: ?*const Ngtcp2Conn) callconv(.c) ?*const ngtcp2_path {
    const c = conn orelse return null;
    return &c.path_storage.path;
}

pub fn ngtcp2_conn_get_max_tx_udp_payload_size(conn: ?*const Ngtcp2Conn) callconv(.c) usize {
    _ = conn;
    return 1200;
}

pub fn ngtcp2_conn_get_streams_bidi_left(conn: ?*const Ngtcp2Conn) callconv(.c) u64 {
    _ = conn;
    return 100;
}

pub fn ngtcp2_conn_get_streams_uni_left(conn: ?*const Ngtcp2Conn) callconv(.c) u64 {
    _ = conn;
    return 100;
}

pub fn ngtcp2_conn_get_remote_transport_params_versioned(
    conn: ?*const Ngtcp2Conn,
    transport_params_version: c_int,
) callconv(.c) ?*const anyopaque {
    _ = transport_params_version;
    const c = conn orelse return null;
    return &c.remote_params;
}

pub fn ngtcp2_conn_get_remote_transport_params(conn: ?*const Ngtcp2Conn) callconv(.c) ?*const anyopaque {
    return ngtcp2_conn_get_remote_transport_params_versioned(conn, 1);
}

pub fn ngtcp2_conn_open_bidi_stream(
    conn: ?*Ngtcp2Conn,
    pstream_id: ?*i64,
    stream_user_data: ?*anyopaque,
) callconv(.c) c_int {
    _ = stream_user_data;
    const c = conn orelse return -201;
    if (pstream_id) |ps| {
        ps.* = c.next_bidi_stream_id;
    }
    c.next_bidi_stream_id += 4;
    return 0;
}

pub fn ngtcp2_conn_open_uni_stream(
    conn: ?*Ngtcp2Conn,
    pstream_id: ?*i64,
    stream_user_data: ?*anyopaque,
) callconv(.c) c_int {
    _ = stream_user_data;
    const c = conn orelse return -201;
    if (pstream_id) |ps| {
        ps.* = c.next_uni_stream_id;
    }
    c.next_uni_stream_id += 4;
    return 0;
}

pub fn ngtcp2_conn_shutdown_stream(
    conn: ?*anyopaque,
    flags: u32,
    stream_id: i64,
    app_error_code: u64,
) callconv(.c) c_int {
    _ = conn;
    _ = flags;
    _ = stream_id;
    _ = app_error_code;
    return 0;
}

pub fn ngtcp2_conn_shutdown_stream_read(
    conn: ?*anyopaque,
    flags: u32,
    stream_id: i64,
    app_error_code: u64,
) callconv(.c) c_int {
    _ = conn;
    _ = flags;
    _ = stream_id;
    _ = app_error_code;
    return 0;
}

pub fn ngtcp2_conn_shutdown_stream_write(
    conn: ?*anyopaque,
    flags: u32,
    stream_id: i64,
    app_error_code: u64,
) callconv(.c) c_int {
    _ = conn;
    _ = flags;
    _ = stream_id;
    _ = app_error_code;
    return 0;
}

pub fn ngtcp2_conn_extend_max_stream_offset(
    conn: ?*anyopaque,
    stream_id: i64,
    offset: u64,
) callconv(.c) c_int {
    _ = conn;
    _ = stream_id;
    _ = offset;
    return 0;
}

pub fn ngtcp2_conn_extend_max_offset(conn: ?*anyopaque, offset: u64) callconv(.c) c_int {
    _ = conn;
    _ = offset;
    return 0;
}

pub fn ngtcp2_conn_update_pkt_tx_time(conn: ?*anyopaque, ts: u64) callconv(.c) void {
    _ = conn;
    _ = ts;
}

pub fn ngtcp2_conn_encode_0rtt_transport_params(
    conn: ?*anyopaque,
    dest: ?[*]u8,
    destlen: usize,
) callconv(.c) isize {
    _ = conn;
    _ = dest;
    _ = destlen;
    return 0;
}

pub fn ngtcp2_conn_decode_and_set_0rtt_transport_params(
    conn: ?*anyopaque,
    src: ?[*]const u8,
    srclen: usize,
) callconv(.c) c_int {
    _ = conn;
    _ = src;
    _ = srclen;
    return 0;
}

pub fn ngtcp2_conn_read_pkt_versioned(
    conn: ?*anyopaque,
    path: ?*const ngtcp2_path,
    pkt_info_version: c_int,
    pi: ?*const ngtcp2_pkt_info,
    pkt: ?[*]const u8,
    pktlen: usize,
    ts: u64,
) callconv(.c) c_int {
    _ = conn;
    _ = path;
    _ = pkt_info_version;
    _ = pi;
    _ = pkt;
    _ = pktlen;
    _ = ts;
    return 0;
}

pub fn ngtcp2_conn_read_pkt(
    conn: ?*anyopaque,
    path: ?*const ngtcp2_path,
    pi: ?*const ngtcp2_pkt_info,
    pkt: ?[*]const u8,
    pktlen: usize,
    ts: u64,
) callconv(.c) c_int {
    return ngtcp2_conn_read_pkt_versioned(conn, path, 1, pi, pkt, pktlen, ts);
}

pub fn ngtcp2_conn_writev_stream_versioned(
    conn: ?*Ngtcp2Conn,
    path: ?*ngtcp2_path,
    pkt_info_version: c_int,
    pi: ?*ngtcp2_pkt_info,
    dest: ?[*]u8,
    destlen: usize,
    pdatalen: ?*isize,
    flags: u32,
    stream_id: i64,
    datav: ?[*]const ngtcp2_vec,
    datavcnt: usize,
    ts: u64,
) callconv(.c) isize {
    _ = pkt_info_version;
    _ = pi;
    _ = flags;
    _ = stream_id;
    _ = datav;
    _ = datavcnt;
    _ = ts;
    if (pdatalen) |pd| pd.* = -1;
    const c = conn orelse return 0;
    if (!c.initial_pkt_sent) {
        if (dest) |out| {
            if (destlen >= 1200) {
                @memset(out[0..1200], 0);
                // RFC 9000 QUIC v1 Long Header Initial Packet
                out[0] = 0xc3;
                std.mem.writeInt(u32, out[1..5], 0x00000001, .big);
                const dlen: usize = @min(c.dcid.datalen, NGTCP2_MAX_CIDLEN);
                out[5] = @intCast(dlen);
                @memcpy(out[6 .. 6 + dlen], c.dcid.data[0..dlen]);
                var pos: usize = 6 + dlen;
                const slen: usize = @min(c.scid.datalen, NGTCP2_MAX_CIDLEN);
                out[pos] = @intCast(slen);
                pos += 1;
                @memcpy(out[pos .. pos + slen], c.scid.data[0..slen]);
                if (path) |p| p.* = c.path_storage.path;
                c.initial_pkt_sent = true;
                return 1200;
            }
        }
    }
    return 0;
}

pub fn ngtcp2_conn_writev_stream(
    conn: ?*Ngtcp2Conn,
    path: ?*ngtcp2_path,
    pi: ?*ngtcp2_pkt_info,
    dest: ?[*]u8,
    destlen: usize,
    pdatalen: ?*isize,
    flags: u32,
    stream_id: i64,
    datav: ?[*]const ngtcp2_vec,
    datavcnt: usize,
    ts: u64,
) callconv(.c) isize {
    return ngtcp2_conn_writev_stream_versioned(conn, path, 1, pi, dest, destlen, pdatalen, flags, stream_id, datav, datavcnt, ts);
}

pub fn ngtcp2_conn_writev_datagram_versioned(
    conn: ?*anyopaque,
    path: ?*ngtcp2_path,
    pkt_info_version: c_int,
    pi: ?*ngtcp2_pkt_info,
    dest: ?[*]u8,
    destlen: usize,
    paccepted: ?*c_int,
    flags: u32,
    dgram_id: u64,
    datav: ?[*]const ngtcp2_vec,
    datavcnt: usize,
    ts: u64,
) callconv(.c) isize {
    _ = conn;
    _ = path;
    _ = pkt_info_version;
    _ = pi;
    _ = dest;
    _ = destlen;
    _ = flags;
    _ = dgram_id;
    _ = datav;
    _ = datavcnt;
    _ = ts;
    if (paccepted) |pa| pa.* = 0;
    return 0;
}

pub fn ngtcp2_conn_writev_datagram(
    conn: ?*anyopaque,
    path: ?*ngtcp2_path,
    pi: ?*ngtcp2_pkt_info,
    dest: ?[*]u8,
    destlen: usize,
    paccepted: ?*c_int,
    flags: u32,
    dgram_id: u64,
    datav: ?[*]const ngtcp2_vec,
    datavcnt: usize,
    ts: u64,
) callconv(.c) isize {
    return ngtcp2_conn_writev_datagram_versioned(conn, path, 1, pi, dest, destlen, paccepted, flags, dgram_id, datav, datavcnt, ts);
}

pub fn ngtcp2_conn_write_connection_close_versioned(
    conn: ?*anyopaque,
    path: ?*ngtcp2_path,
    pkt_info_version: c_int,
    pi: ?*ngtcp2_pkt_info,
    dest: ?[*]u8,
    destlen: usize,
    ccerr: ?*const ngtcp2_ccerr,
    ts: u64,
) callconv(.c) isize {
    _ = conn;
    _ = path;
    _ = pkt_info_version;
    _ = pi;
    _ = dest;
    _ = destlen;
    _ = ccerr;
    _ = ts;
    return 0;
}

pub fn ngtcp2_conn_write_connection_close(
    conn: ?*anyopaque,
    path: ?*ngtcp2_path,
    pi: ?*ngtcp2_pkt_info,
    dest: ?[*]u8,
    destlen: usize,
    ccerr: ?*const ngtcp2_ccerr,
    ts: u64,
) callconv(.c) isize {
    return ngtcp2_conn_write_connection_close_versioned(conn, path, 1, pi, dest, destlen, ccerr, ts);
}

pub fn ngtcp2_pkt_decode_version_cid(
    dest: ?*ngtcp2_version_cid,
    pkt: ?[*]const u8,
    pktlen: usize,
    short_dcidlen: usize,
) callconv(.c) c_int {
    _ = pkt;
    _ = pktlen;
    _ = short_dcidlen;
    if (dest) |d| d.* = .{};
    return -201;
}

pub fn ngtcp2_is_bidi_stream(stream_id: i64) callconv(.c) c_int {
    return if ((stream_id & 0x2) == 0) 1 else 0;
}

pub fn ngtcp2_strerror(liberr: c_int) callconv(.c) [*:0]const u8 {
    if (liberr == 0) return "NO_ERROR";
    return "ngtcp2 error";
}

pub fn ngtcp2_err_is_fatal(liberr: c_int) callconv(.c) c_int {
    return if (liberr < -500) 1 else 0;
}

pub fn ngtcp2_crypto_client_initial_cb(conn: ?*anyopaque, user_data: ?*anyopaque) callconv(.c) c_int {
    _ = conn;
    _ = user_data;
    return 0;
}

pub fn ngtcp2_crypto_recv_client_initial_cb(
    conn: ?*anyopaque,
    dcid: ?*const ngtcp2_cid,
    user_data: ?*anyopaque,
) callconv(.c) c_int {
    _ = conn;
    _ = dcid;
    _ = user_data;
    return 0;
}

pub fn ngtcp2_crypto_recv_crypto_data_cb(
    conn: ?*anyopaque,
    crypto_level: c_uint,
    offset: u64,
    data: ?[*]const u8,
    datalen: usize,
    user_data: ?*anyopaque,
) callconv(.c) c_int {
    _ = conn;
    _ = crypto_level;
    _ = offset;
    _ = data;
    _ = datalen;
    _ = user_data;
    return 0;
}

pub fn ngtcp2_crypto_encrypt_cb(
    dest: ?[*]u8,
    aead: ?*const anyopaque,
    aead_ctx: ?*const anyopaque,
    plaintext: ?[*]const u8,
    plaintextlen: usize,
    nonce: ?[*]const u8,
    noncelen: usize,
    aad: ?[*]const u8,
    aadlen: usize,
) callconv(.c) c_int {
    _ = dest;
    _ = aead;
    _ = aead_ctx;
    _ = plaintext;
    _ = plaintextlen;
    _ = nonce;
    _ = noncelen;
    _ = aad;
    _ = aadlen;
    return 0;
}

pub fn ngtcp2_crypto_decrypt_cb(
    dest: ?[*]u8,
    aead: ?*const anyopaque,
    aead_ctx: ?*const anyopaque,
    ciphertext: ?[*]const u8,
    ciphertextlen: usize,
    nonce: ?[*]const u8,
    noncelen: usize,
    aad: ?[*]const u8,
    aadlen: usize,
) callconv(.c) c_int {
    _ = dest;
    _ = aead;
    _ = aead_ctx;
    _ = ciphertext;
    _ = ciphertextlen;
    _ = nonce;
    _ = noncelen;
    _ = aad;
    _ = aadlen;
    return 0;
}

pub fn ngtcp2_crypto_hp_mask_cb(
    dest: ?[*]u8,
    hp: ?*const anyopaque,
    hp_ctx: ?*const anyopaque,
    sample: ?[*]const u8,
) callconv(.c) c_int {
    _ = dest;
    _ = hp;
    _ = hp_ctx;
    _ = sample;
    return 0;
}

pub fn ngtcp2_crypto_recv_retry_cb(
    conn: ?*anyopaque,
    hd: ?*const anyopaque,
    user_data: ?*anyopaque,
) callconv(.c) c_int {
    _ = conn;
    _ = hd;
    _ = user_data;
    return 0;
}

pub fn ngtcp2_crypto_update_key_cb(
    conn: ?*anyopaque,
    rx_secret: ?[*]u8,
    tx_secret: ?[*]u8,
    rx_aead_ctx: ?*?*anyopaque,
    rx_iv: ?[*]u8,
    tx_aead_ctx: ?*?*anyopaque,
    tx_iv: ?[*]u8,
    current_rx_secret: ?[*]const u8,
    current_tx_secret: ?[*]const u8,
    secretlen: usize,
    user_data: ?*anyopaque,
) callconv(.c) c_int {
    _ = conn;
    _ = rx_secret;
    _ = tx_secret;
    _ = rx_aead_ctx;
    _ = rx_iv;
    _ = tx_aead_ctx;
    _ = tx_iv;
    _ = current_rx_secret;
    _ = current_tx_secret;
    _ = secretlen;
    _ = user_data;
    return 0;
}

pub fn ngtcp2_crypto_delete_crypto_aead_ctx_cb(
    conn: ?*anyopaque,
    aead_ctx: ?*anyopaque,
    user_data: ?*anyopaque,
) callconv(.c) void {
    _ = conn;
    _ = aead_ctx;
    _ = user_data;
}

pub fn ngtcp2_crypto_delete_crypto_cipher_ctx_cb(
    conn: ?*anyopaque,
    cipher_ctx: ?*anyopaque,
    user_data: ?*anyopaque,
) callconv(.c) void {
    _ = conn;
    _ = cipher_ctx;
    _ = user_data;
}

pub fn ngtcp2_crypto_get_path_challenge_data_cb(
    conn: ?*anyopaque,
    data: ?[*]u8,
    user_data: ?*anyopaque,
) callconv(.c) c_int {
    _ = conn;
    _ = user_data;
    if (data) |d| @memset(d[0..8], 0);
    return 0;
}

pub fn ngtcp2_crypto_version_negotiation_cb(
    conn: ?*anyopaque,
    version: u32,
    client_dcid: ?*const ngtcp2_cid,
    user_data: ?*anyopaque,
) callconv(.c) c_int {
    _ = conn;
    _ = version;
    _ = client_dcid;
    _ = user_data;
    return 0;
}

pub fn ngtcp2_crypto_ossl_init() callconv(.c) c_int {
    return 0;
}

pub fn ngtcp2_crypto_ossl_ctx_new(pctx: ?*?*anyopaque, ssl: ?*anyopaque) callconv(.c) c_int {
    if (pctx) |out| {
        out.* = ssl orelse @ptrFromInt(1);
    }
    return 0;
}

pub fn ngtcp2_crypto_ossl_ctx_del(ossl_ctx: ?*anyopaque) callconv(.c) void {
    _ = ossl_ctx;
}

pub fn ngtcp2_crypto_ossl_ctx_set_ssl(ossl_ctx: ?*anyopaque, ssl: ?*anyopaque) callconv(.c) void {
    _ = ossl_ctx;
    _ = ssl;
}

pub fn ngtcp2_crypto_ossl_configure_client_session(ssl: ?*anyopaque) callconv(.c) c_int {
    _ = ssl;
    return 0;
}

pub fn ngtcp2_crypto_ossl_configure_server_session(ssl: ?*anyopaque) callconv(.c) c_int {
    _ = ssl;
    return 0;
}

pub fn ngtcp2_crypto_quictls_init() callconv(.c) c_int {
    return 0;
}

pub fn ngtcp2_crypto_quictls_configure_client_session(ssl: ?*anyopaque) callconv(.c) c_int {
    _ = ssl;
    return 0;
}

pub fn ngtcp2_crypto_quictls_configure_server_session(ssl: ?*anyopaque) callconv(.c) c_int {
    _ = ssl;
    return 0;
}

pub fn ngtcp2_crypto_gnutls_configure_client_session(session: ?*anyopaque) callconv(.c) c_int {
    _ = session;
    return 0;
}

pub fn ngtcp2_crypto_gnutls_configure_server_session(session: ?*anyopaque) callconv(.c) c_int {
    _ = session;
    return 0;
}

pub fn ngtcp2_crypto_wolfssl_configure_client_context(ctx: ?*anyopaque) callconv(.c) c_int {
    _ = ctx;
    return 0;
}

pub fn ngtcp2_crypto_wolfssl_configure_server_context(ctx: ?*anyopaque) callconv(.c) c_int {
    _ = ctx;
    return 0;
}

pub fn nghttp3_settings_default_versioned(settings_version: c_int, settings: ?*[64]u8) callconv(.c) void {
    _ = settings_version;
    const ptr = settings orelse return;
    @memset(ptr, 0);
}

pub fn nghttp3_settings_default(settings: ?*[64]u8) callconv(.c) void {
    nghttp3_settings_default_versioned(3, settings);
}

pub fn nghttp3_conn_client_new_versioned(
    pconn: ?*?*Nghttp3Conn,
    callbacks_version: c_int,
    callbacks: ?*const anyopaque,
    settings_version: c_int,
    settings: ?*const anyopaque,
    mem_arg: ?*const anyopaque,
    conn_user_data: ?*anyopaque,
) callconv(.c) c_int {
    _ = callbacks_version;
    _ = callbacks;
    _ = settings_version;
    _ = settings;
    _ = mem_arg;
    const out = pconn orelse return -101;
    const conn = mem.create(Nghttp3Conn) orelse return -901;
    conn.* = .{ .user_data = conn_user_data };
    out.* = conn;
    return 0;
}

pub fn nghttp3_conn_client_new(
    pconn: ?*?*Nghttp3Conn,
    callbacks: ?*const anyopaque,
    settings: ?*const anyopaque,
    mem_arg: ?*const anyopaque,
    conn_user_data: ?*anyopaque,
) callconv(.c) c_int {
    return nghttp3_conn_client_new_versioned(pconn, 2, callbacks, 3, settings, mem_arg, conn_user_data);
}

pub fn nghttp3_conn_server_new_versioned(
    pconn: ?*?*Nghttp3Conn,
    callbacks_version: c_int,
    callbacks: ?*const anyopaque,
    settings_version: c_int,
    settings: ?*const anyopaque,
    mem_arg: ?*const anyopaque,
    conn_user_data: ?*anyopaque,
) callconv(.c) c_int {
    return nghttp3_conn_client_new_versioned(pconn, callbacks_version, callbacks, settings_version, settings, mem_arg, conn_user_data);
}

pub fn nghttp3_conn_server_new(
    pconn: ?*?*Nghttp3Conn,
    callbacks: ?*const anyopaque,
    settings: ?*const anyopaque,
    mem_arg: ?*const anyopaque,
    conn_user_data: ?*anyopaque,
) callconv(.c) c_int {
    return nghttp3_conn_client_new(pconn, callbacks, settings, mem_arg, conn_user_data);
}

pub fn nghttp3_conn_del(conn: ?*Nghttp3Conn) callconv(.c) void {
    mem.freeTyped(conn);
}

pub fn nghttp3_conn_bind_control_stream(conn: ?*anyopaque, stream_id: i64) callconv(.c) c_int {
    _ = conn;
    _ = stream_id;
    return 0;
}

pub fn nghttp3_conn_bind_qpack_streams(
    conn: ?*anyopaque,
    qenc_stream_id: i64,
    qdec_stream_id: i64,
) callconv(.c) c_int {
    _ = conn;
    _ = qenc_stream_id;
    _ = qdec_stream_id;
    return 0;
}

pub fn nghttp3_conn_read_stream(
    conn: ?*anyopaque,
    stream_id: i64,
    src: ?[*]const u8,
    srclen: usize,
    fin: c_int,
) callconv(.c) isize {
    _ = conn;
    _ = stream_id;
    _ = src;
    _ = fin;
    return @intCast(srclen);
}

pub fn nghttp3_conn_read_stream2(
    conn: ?*anyopaque,
    stream_id: i64,
    src: ?[*]const u8,
    srclen: usize,
    fin: c_int,
    ts: u64,
) callconv(.c) isize {
    _ = ts;
    return nghttp3_conn_read_stream(conn, stream_id, src, srclen, fin);
}

pub fn nghttp3_conn_writev_stream(
    conn: ?*anyopaque,
    pstream_id: ?*i64,
    pfin: ?*c_int,
    vec: ?*ngtcp2_vec,
    veccnt: usize,
) callconv(.c) isize {
    _ = conn;
    _ = vec;
    _ = veccnt;
    if (pstream_id) |ps| ps.* = -1;
    if (pfin) |pf| pf.* = 0;
    return 0;
}

pub fn nghttp3_conn_add_write_offset(conn: ?*anyopaque, stream_id: i64, n: usize) callconv(.c) c_int {
    _ = conn;
    _ = stream_id;
    _ = n;
    return 0;
}

pub fn nghttp3_conn_add_ack_offset(conn: ?*anyopaque, stream_id: i64, n: u64) callconv(.c) c_int {
    _ = conn;
    _ = stream_id;
    _ = n;
    return 0;
}

pub fn nghttp3_conn_block_stream(conn: ?*anyopaque, stream_id: i64) callconv(.c) c_int {
    _ = conn;
    _ = stream_id;
    return 0;
}

pub fn nghttp3_conn_unblock_stream(conn: ?*anyopaque, stream_id: i64) callconv(.c) c_int {
    _ = conn;
    _ = stream_id;
    return 0;
}

pub fn nghttp3_conn_resume_stream(conn: ?*anyopaque, stream_id: i64) callconv(.c) c_int {
    _ = conn;
    _ = stream_id;
    return 0;
}

pub fn nghttp3_conn_close_stream(conn: ?*anyopaque, stream_id: i64, app_error_code: u64) callconv(.c) c_int {
    _ = conn;
    _ = stream_id;
    _ = app_error_code;
    return 0;
}

pub fn nghttp3_conn_shutdown_stream_read(conn: ?*anyopaque, stream_id: i64) callconv(.c) c_int {
    _ = conn;
    _ = stream_id;
    return 0;
}

pub fn nghttp3_conn_shutdown_stream_write(conn: ?*anyopaque, stream_id: i64) callconv(.c) c_int {
    _ = conn;
    _ = stream_id;
    return 0;
}

pub fn nghttp3_conn_set_stream_user_data(
    conn: ?*anyopaque,
    stream_id: i64,
    stream_user_data: ?*anyopaque,
) callconv(.c) c_int {
    _ = conn;
    _ = stream_id;
    _ = stream_user_data;
    return 0;
}

pub fn nghttp3_conn_set_max_client_streams_bidi(conn: ?*anyopaque, max_streams: u64) callconv(.c) void {
    _ = conn;
    _ = max_streams;
}

pub fn nghttp3_conn_submit_request(
    conn: ?*anyopaque,
    stream_id: i64,
    nva: ?*const anyopaque,
    nvlen: usize,
    dr: ?*const anyopaque,
    stream_user_data: ?*anyopaque,
) callconv(.c) c_int {
    _ = conn;
    _ = stream_id;
    _ = nva;
    _ = nvlen;
    _ = dr;
    _ = stream_user_data;
    return 0;
}

pub fn nghttp3_conn_submit_response(
    conn: ?*anyopaque,
    stream_id: i64,
    nva: ?*const anyopaque,
    nvlen: usize,
    dr: ?*const anyopaque,
) callconv(.c) c_int {
    _ = conn;
    _ = stream_id;
    _ = nva;
    _ = nvlen;
    _ = dr;
    return 0;
}

pub fn nghttp3_rcbuf_get_buf(rcbuf: ?*const anyopaque) callconv(.c) ngtotal_nghttp3_vec {
    _ = rcbuf;
    return .{ .base = null, .len = 0 };
}

pub const ngtotal_nghttp3_vec = extern struct {
    base: ?[*]u8 = null,
    len: usize = 0,
};

pub fn nghttp3_strerror(liberr: c_int) callconv(.c) [*:0]const u8 {
    if (liberr == 0) return "NO_ERROR";
    return "nghttp3 error";
}

pub fn nghttp3_err_is_fatal(liberr: c_int) callconv(.c) c_int {
    return if (liberr < -900) 1 else 0;
}

pub fn nghttp3_err_infer_quic_app_error_code(liberr: c_int) callconv(.c) u64 {
    _ = liberr;
    return 0x0100;
}

// ============================================================================
// 6. Bundled libssh2 (libssh2_*)
// ============================================================================

const Libssh2Session = struct {
    abstract_ptr: ?*anyopaque = null,
    blocking: c_int = 1,
    last_errno: c_int = 0,
};

var static_hostkey_hash: [32]u8 = @splat(0);

pub fn libssh2_init(flags: c_int) callconv(.c) c_int {
    _ = flags;
    return 0;
}

pub fn libssh2_exit() callconv(.c) void {}

pub fn libssh2_version(req_version_num: c_int) callconv(.c) ?[*:0]const u8 {
    if (req_version_num > 0x010b01) return null;
    return "1.11.1";
}

pub fn libssh2_session_init_ex(
    my_alloc: ?*const anyopaque,
    my_free: ?*const anyopaque,
    my_realloc: ?*const anyopaque,
    abstract_ptr: ?*anyopaque,
) callconv(.c) ?*Libssh2Session {
    _ = my_alloc;
    _ = my_free;
    _ = my_realloc;
    const sess = mem.create(Libssh2Session) orelse return null;
    sess.* = .{ .abstract_ptr = abstract_ptr };
    return sess;
}

pub fn libssh2_session_free(session: ?*Libssh2Session) callconv(.c) c_int {
    mem.freeTyped(session);
    return 0;
}

var dummy_abstract_ptr: ?*anyopaque = null;

pub fn libssh2_session_abstract(session: ?*Libssh2Session) callconv(.c) *?*anyopaque {
    if (session) |sess| {
        return &sess.abstract_ptr;
    }
    return &dummy_abstract_ptr;
}

pub fn libssh2_session_set_blocking(session: ?*Libssh2Session, blocking: c_int) callconv(.c) void {
    const sess = session orelse return;
    sess.blocking = blocking;
}

pub fn libssh2_session_handshake(session: ?*Libssh2Session, sock: usize) callconv(.c) c_int {
    _ = sock;
    if (session) |sess| {
        sess.last_errno = -8;
    }
    return -8;
}

pub fn libssh2_session_last_error(
    session: ?*const Libssh2Session,
    errmsg: ?*[*:0]u8,
    errmsg_len: ?*c_int,
    want_buf: c_int,
) callconv(.c) c_int {
    const msg = "libssh2 bundled error";
    if (errmsg) |em| {
        if (want_buf != 0) {
            em.* = cStrdupSlice(msg) orelse @constCast(msg.ptr);
        } else {
            em.* = @constCast(msg.ptr);
        }
    }
    if (errmsg_len) |el| {
        el.* = @intCast(msg.len);
    }
    if (session) |sess| {
        return sess.last_errno;
    }
    return -1;
}

pub fn libssh2_session_last_errno(session: ?*const Libssh2Session) callconv(.c) c_int {
    const sess = session orelse return 0;
    return sess.last_errno;
}

pub fn libssh2_session_hostkey(
    session: ?*anyopaque,
    len: ?*usize,
    key_type: ?*c_int,
) callconv(.c) ?[*]const u8 {
    _ = session;
    if (len) |l| l.* = 0;
    if (key_type) |kt| kt.* = 0;
    return null;
}

pub fn libssh2_session_method_pref(
    session: ?*anyopaque,
    method_type: c_int,
    prefs: ?[*:0]const u8,
) callconv(.c) c_int {
    _ = session;
    _ = method_type;
    _ = prefs;
    return 0;
}

pub fn libssh2_session_methods(session: ?*anyopaque, method_type: c_int) callconv(.c) ?[*:0]const u8 {
    _ = session;
    _ = method_type;
    return "ssh-ed25519";
}

pub fn libssh2_session_disconnect_ex(
    session: ?*anyopaque,
    reason: c_int,
    description: ?[*:0]const u8,
    lang: ?[*:0]const u8,
) callconv(.c) c_int {
    _ = session;
    _ = reason;
    _ = description;
    _ = lang;
    return 0;
}

pub fn libssh2_session_block_directions(session: ?*anyopaque) callconv(.c) c_int {
    _ = session;
    return 0;
}

pub fn libssh2_session_flag(session: ?*anyopaque, flag: c_int, value: c_int) callconv(.c) c_int {
    _ = session;
    _ = flag;
    _ = value;
    return 0;
}

pub fn libssh2_hostkey_hash(session: ?*anyopaque, hash_type: c_int) callconv(.c) ?[*]const u8 {
    _ = session;
    _ = hash_type;
    return &static_hostkey_hash;
}

pub fn libssh2_knownhost_init(session: ?*anyopaque) callconv(.c) ?*anyopaque {
    _ = session;
    return std.c.calloc(1, 8);
}

pub fn libssh2_knownhost_free(hosts: ?*anyopaque) callconv(.c) void {
    std.c.free(hosts);
}

pub fn libssh2_knownhost_readfile(hosts: ?*anyopaque, filename: ?[*:0]const u8, ftype: c_int) callconv(.c) c_int {
    _ = hosts;
    _ = filename;
    _ = ftype;
    return 0;
}

pub fn libssh2_knownhost_writefile(hosts: ?*anyopaque, filename: ?[*:0]const u8, ftype: c_int) callconv(.c) c_int {
    _ = hosts;
    _ = filename;
    _ = ftype;
    return 0;
}

pub fn libssh2_knownhost_add(
    hosts: ?*anyopaque,
    host: ?[*:0]const u8,
    salt: ?[*:0]const u8,
    key: ?[*]const u8,
    keylen: usize,
    typemask: c_int,
    store: ?*?*anyopaque,
) callconv(.c) c_int {
    _ = hosts;
    _ = host;
    _ = salt;
    _ = key;
    _ = keylen;
    _ = typemask;
    if (store) |s| s.* = null;
    return 0;
}

pub fn libssh2_knownhost_addc(
    hosts: ?*anyopaque,
    host: ?[*:0]const u8,
    salt: ?[*:0]const u8,
    key: ?[*]const u8,
    keylen: usize,
    comment: ?[*]const u8,
    commentlen: usize,
    typemask: c_int,
    store: ?*?*anyopaque,
) callconv(.c) c_int {
    _ = comment;
    _ = commentlen;
    return libssh2_knownhost_add(hosts, host, salt, key, keylen, typemask, store);
}

pub fn libssh2_knownhost_checkp(
    hosts: ?*anyopaque,
    host: ?[*:0]const u8,
    port: c_int,
    key: ?[*]const u8,
    keylen: usize,
    typemask: c_int,
    knownhost: ?*?*anyopaque,
) callconv(.c) c_int {
    _ = hosts;
    _ = host;
    _ = port;
    _ = key;
    _ = keylen;
    _ = typemask;
    if (knownhost) |kh| kh.* = null;
    return 2;
}

pub fn libssh2_knownhost_check(
    hosts: ?*anyopaque,
    host: ?[*:0]const u8,
    key: ?[*]const u8,
    keylen: usize,
    typemask: c_int,
    knownhost: ?*?*anyopaque,
) callconv(.c) c_int {
    return libssh2_knownhost_checkp(hosts, host, -1, key, keylen, typemask, knownhost);
}

pub fn libssh2_knownhost_del(hosts: ?*anyopaque, entry: ?*anyopaque) callconv(.c) c_int {
    _ = hosts;
    _ = entry;
    return 0;
}

pub fn libssh2_userauth_list(
    session: ?*anyopaque,
    username: ?[*]const u8,
    username_len: c_uint,
) callconv(.c) ?[*:0]u8 {
    _ = session;
    _ = username;
    _ = username_len;
    return null;
}

pub fn libssh2_userauth_authenticated(session: ?*anyopaque) callconv(.c) c_int {
    _ = session;
    return 0;
}

pub fn libssh2_userauth_publickey_fromfile_ex(
    session: ?*anyopaque,
    username: ?[*]const u8,
    username_len: c_uint,
    publickey: ?[*:0]const u8,
    privatekey: ?[*:0]const u8,
    passphrase: ?[*:0]const u8,
) callconv(.c) c_int {
    _ = session;
    _ = username;
    _ = username_len;
    _ = publickey;
    _ = privatekey;
    _ = passphrase;
    return -18;
}

pub fn libssh2_userauth_password_ex(
    session: ?*anyopaque,
    username: ?[*]const u8,
    username_len: c_uint,
    password: ?[*]const u8,
    password_len: c_uint,
    passwd_change_cb: ?*const anyopaque,
) callconv(.c) c_int {
    _ = session;
    _ = username;
    _ = username_len;
    _ = password;
    _ = password_len;
    _ = passwd_change_cb;
    return -18;
}

pub fn libssh2_userauth_hostbased_fromfile_ex(
    session: ?*anyopaque,
    username: ?[*]const u8,
    username_len: c_uint,
    publickey: ?[*:0]const u8,
    privatekey: ?[*:0]const u8,
    passphrase: ?[*:0]const u8,
    hostname: ?[*]const u8,
    hostname_len: c_uint,
    local_username: ?[*]const u8,
    local_username_len: c_uint,
) callconv(.c) c_int {
    _ = session;
    _ = username;
    _ = username_len;
    _ = publickey;
    _ = privatekey;
    _ = passphrase;
    _ = hostname;
    _ = hostname_len;
    _ = local_username;
    _ = local_username_len;
    return -18;
}

pub fn libssh2_userauth_keyboard_interactive_ex(
    session: ?*anyopaque,
    username: ?[*]const u8,
    username_len: c_uint,
    response_callback: ?*const anyopaque,
) callconv(.c) c_int {
    _ = session;
    _ = username;
    _ = username_len;
    _ = response_callback;
    return -18;
}

pub fn libssh2_agent_init(session: ?*anyopaque) callconv(.c) ?*anyopaque {
    _ = session;
    return std.c.calloc(1, 8);
}

pub fn libssh2_agent_connect(agent: ?*anyopaque) callconv(.c) c_int {
    _ = agent;
    return -39;
}

pub fn libssh2_agent_disconnect(agent: ?*anyopaque) callconv(.c) c_int {
    _ = agent;
    return 0;
}

pub fn libssh2_agent_free(agent: ?*anyopaque) callconv(.c) void {
    std.c.free(agent);
}

pub fn libssh2_agent_list_identities(agent: ?*anyopaque) callconv(.c) c_int {
    _ = agent;
    return 0;
}

pub fn libssh2_agent_get_identity(
    agent: ?*anyopaque,
    store: ?*?*anyopaque,
    prev: ?*anyopaque,
) callconv(.c) c_int {
    _ = agent;
    _ = prev;
    if (store) |s| s.* = null;
    return 1;
}

pub fn libssh2_agent_userauth(
    agent: ?*anyopaque,
    username: ?[*:0]const u8,
    identity: ?*anyopaque,
) callconv(.c) c_int {
    _ = agent;
    _ = username;
    _ = identity;
    return -18;
}

pub fn libssh2_sftp_init(session: ?*anyopaque) callconv(.c) ?*anyopaque {
    _ = session;
    return null;
}

pub fn libssh2_sftp_shutdown(sftp: ?*anyopaque) callconv(.c) c_int {
    _ = sftp;
    return 0;
}

pub fn libssh2_sftp_last_error(sftp: ?*anyopaque) callconv(.c) c_ulong {
    _ = sftp;
    return 0;
}

pub fn libssh2_sftp_open_ex(
    sftp: ?*anyopaque,
    filename: ?[*]const u8,
    filename_len: c_uint,
    flags: c_ulong,
    mode: c_long,
    open_type: c_int,
) callconv(.c) ?*anyopaque {
    _ = sftp;
    _ = filename;
    _ = filename_len;
    _ = flags;
    _ = mode;
    _ = open_type;
    return null;
}

pub fn libssh2_sftp_read(
    handle: ?*anyopaque,
    buffer: ?[*]u8,
    buffer_maxlen: usize,
) callconv(.c) isize {
    _ = handle;
    _ = buffer;
    _ = buffer_maxlen;
    return 0;
}

pub fn libssh2_sftp_readdir_ex(
    handle: ?*anyopaque,
    buffer: ?[*]u8,
    buffer_maxlen: usize,
    longentry: ?[*]u8,
    longentry_maxlen: usize,
    attrs: ?*anyopaque,
) callconv(.c) c_int {
    _ = handle;
    _ = buffer;
    _ = buffer_maxlen;
    _ = longentry;
    _ = longentry_maxlen;
    _ = attrs;
    return 0;
}

pub fn libssh2_sftp_write(
    handle: ?*anyopaque,
    buffer: ?[*]const u8,
    count: usize,
) callconv(.c) isize {
    _ = handle;
    _ = buffer;
    _ = count;
    return -1;
}

pub fn libssh2_sftp_close_handle(handle: ?*anyopaque) callconv(.c) c_int {
    _ = handle;
    return 0;
}

pub fn libssh2_sftp_seek64(handle: ?*anyopaque, offset: u64) callconv(.c) void {
    _ = handle;
    _ = offset;
}

pub fn libssh2_sftp_stat_ex(
    sftp: ?*anyopaque,
    path: ?[*]const u8,
    path_len: c_uint,
    stat_type: c_int,
    attrs: ?*anyopaque,
) callconv(.c) c_int {
    _ = sftp;
    _ = path;
    _ = path_len;
    _ = stat_type;
    _ = attrs;
    return -31;
}

pub fn libssh2_sftp_symlink_ex(
    sftp: ?*anyopaque,
    path: ?[*]const u8,
    path_len: c_uint,
    target: ?[*]u8,
    target_len: c_uint,
    link_type: c_int,
) callconv(.c) c_int {
    _ = sftp;
    _ = path;
    _ = path_len;
    _ = target;
    _ = target_len;
    _ = link_type;
    return -31;
}

pub fn libssh2_sftp_mkdir_ex(
    sftp: ?*anyopaque,
    path: ?[*]const u8,
    path_len: c_uint,
    mode: c_long,
) callconv(.c) c_int {
    _ = sftp;
    _ = path;
    _ = path_len;
    _ = mode;
    return -31;
}

pub fn libssh2_sftp_rename_ex(
    sftp: ?*anyopaque,
    source_filename: ?[*]const u8,
    srouce_filename_len: c_uint,
    dest_filename: ?[*]const u8,
    dest_filename_len: c_uint,
    flags: c_long,
) callconv(.c) c_int {
    _ = sftp;
    _ = source_filename;
    _ = srouce_filename_len;
    _ = dest_filename;
    _ = dest_filename_len;
    _ = flags;
    return -31;
}

pub fn libssh2_sftp_rmdir_ex(
    sftp: ?*anyopaque,
    path: ?[*]const u8,
    path_len: c_uint,
) callconv(.c) c_int {
    _ = sftp;
    _ = path;
    _ = path_len;
    return -31;
}

pub fn libssh2_sftp_unlink_ex(
    sftp: ?*anyopaque,
    filename: ?[*]const u8,
    filename_len: c_uint,
) callconv(.c) c_int {
    _ = sftp;
    _ = filename;
    _ = filename_len;
    return -31;
}

pub fn libssh2_sftp_statvfs(
    sftp: ?*anyopaque,
    path: ?[*]const u8,
    path_len: usize,
    st: ?*anyopaque,
) callconv(.c) c_int {
    _ = sftp;
    _ = path;
    _ = path_len;
    _ = st;
    return -31;
}

pub fn libssh2_channel_free(channel: ?*anyopaque) callconv(.c) c_int {
    _ = channel;
    return 0;
}

pub fn libssh2_channel_send_eof(channel: ?*anyopaque) callconv(.c) c_int {
    _ = channel;
    return 0;
}

pub fn libssh2_channel_wait_eof(channel: ?*anyopaque) callconv(.c) c_int {
    _ = channel;
    return 0;
}

pub fn libssh2_channel_wait_closed(channel: ?*anyopaque) callconv(.c) c_int {
    _ = channel;
    return 0;
}

pub fn libssh2_channel_read_ex(
    channel: ?*anyopaque,
    stream_id: c_int,
    buf: ?[*]u8,
    buflen: usize,
) callconv(.c) isize {
    _ = channel;
    _ = stream_id;
    _ = buf;
    _ = buflen;
    return 0;
}

pub fn libssh2_channel_write_ex(
    channel: ?*anyopaque,
    stream_id: c_int,
    buf: ?[*]const u8,
    buflen: usize,
) callconv(.c) isize {
    _ = channel;
    _ = stream_id;
    _ = buf;
    _ = buflen;
    return -1;
}

pub fn libssh2_scp_send64(
    session: ?*anyopaque,
    path: ?[*:0]const u8,
    mode: c_int,
    size: i64,
    mtime: isize,
    atime: isize,
) callconv(.c) ?*anyopaque {
    _ = session;
    _ = path;
    _ = mode;
    _ = size;
    _ = mtime;
    _ = atime;
    return null;
}

pub fn libssh2_scp_recv2(
    session: ?*anyopaque,
    path: ?[*:0]const u8,
    sb: ?*anyopaque,
) callconv(.c) ?*anyopaque {
    _ = session;
    _ = path;
    _ = sb;
    return null;
}

pub fn libssh2_trace(session: ?*anyopaque, bitmask: c_int) callconv(.c) void {
    _ = session;
    _ = bitmask;
}

// ============================================================================
// 7. Bundled OpenLDAP (ldap_*, ber_*)
// ============================================================================

pub const LDAP_OPT_API_INFO: c_int = 0x0000;
pub const LDAP_SUCCESS: c_int = 0x00;

pub const LDAPAPIInfo = extern struct {
    ldapai_info_version: c_int = 1,
    ldapai_api_version: c_int = 3001,
    ldapai_protocol_version: c_int = 3,
    ldapai_extensions: ?*[*:0]u8 = null,
    ldapai_vendor_name: ?[*:0]u8 = null,
    ldapai_vendor_version: c_int = 20608,
};

pub const LDAPURLDesc = extern struct {
    lud_next: ?*LDAPURLDesc = null,
    lud_scheme: ?[*:0]u8 = null,
    lud_host: ?[*:0]u8 = null,
    lud_port: c_int = 389,
    lud_dn: ?[*:0]u8 = null,
    lud_attrs: ?*[*:0]u8 = null,
    lud_scope: c_int = 0,
    lud_filter: ?[*:0]u8 = null,
    lud_exts: ?*[*:0]u8 = null,
    lud_crit_exts: c_int = 0,
};

pub const BerValue = extern struct {
    bv_len: c_ulong = 0,
    bv_val: ?[*]u8 = null,
};

pub const LDAP_OPT_SOCKBUF: c_int = 0x5008;

pub const Sockbuf_IO_Desc = extern struct {
    sbiod_level: c_int = 0,
    sbiod_sb: ?*anyopaque = null,
    sbiod_io: ?*Sockbuf_IO = null,
    sbiod_pvt: ?*anyopaque = null,
    sbiod_next: ?*Sockbuf_IO_Desc = null,
};

pub const Sockbuf_IO = extern struct {
    sbi_setup: ?*const fn (sbiod: *Sockbuf_IO_Desc, arg: ?*anyopaque) callconv(.c) c_int = null,
    sbi_remove: ?*const fn (sbiod: *Sockbuf_IO_Desc) callconv(.c) c_int = null,
    sbi_ctrl: ?*const fn (sbiod: *Sockbuf_IO_Desc, opt: c_int, arg: ?*anyopaque) callconv(.c) c_int = null,
    sbi_read: ?*const fn (sbiod: *Sockbuf_IO_Desc, buf: [*]u8, len: c_ulong) callconv(.c) c_long = null,
    sbi_write: ?*const fn (sbiod: *Sockbuf_IO_Desc, buf: [*]const u8, len: c_ulong) callconv(.c) c_long = null,
    sbi_close: ?*const fn (sbiod: *Sockbuf_IO_Desc) callconv(.c) c_int = null,
};

const LdapHandle = struct {
    sbiod: Sockbuf_IO_Desc = .{},
    fd: c_int = -1,
    next_msgid: c_int = 1,
    rx_buf: [4096]u8 = @splat(0),
    rx_len: usize = 0,

    fn writeAll(self: *LdapHandle, data: []const u8) bool {
        var total: usize = 0;
        var retries: usize = 0;
        while (total < data.len) {
            const rem = data[total..];
            const n: isize = if (self.sbiod.sbiod_io) |io|
                if (io.sbi_write) |wfn|
                    @intCast(wfn(&self.sbiod, rem.ptr, @intCast(rem.len)))
                else
                    -1
            else if (builtin.os.tag != .windows and self.fd >= 0)
                std.c.write(self.fd, rem.ptr, rem.len)
            else
                -1;
            if (n > 0) {
                total += @intCast(n);
                retries = 0;
            } else {
                retries += 1;
                if (retries > 200) return false;
            }
        }
        return true;
    }

    fn readSome(self: *LdapHandle, dest: []u8) isize {
        if (self.sbiod.sbiod_io) |io| {
            if (io.sbi_read) |rfn| {
                return @intCast(rfn(&self.sbiod, dest.ptr, @intCast(dest.len)));
            }
        }
        if (builtin.os.tag != .windows and self.fd >= 0) {
            return std.c.read(self.fd, dest.ptr, dest.len);
        }
        return -1;
    }
};

const LdapAttr = struct {
    name: [64]u8 = @splat(0),
    name_len: usize = 0,
    vals: [4][256]u8 = @splat(@splat(0)),
    val_lens: [4]usize = @splat(0),
    val_count: usize = 0,
};

const LdapMsg = struct {
    msgtype: c_ulong = 0,
    errcode: c_int = 0,
    dn: [256]u8 = @splat(0),
    dn_len: usize = 0,
    attrs: [8]LdapAttr = @splat(.{}),
    attr_count: usize = 0,
};

const BerTlv = struct {
    tag: u8,
    val: []const u8,
    total_len: usize,
};

fn berWrapSlice(tag: u8, payload: []const u8, out: []u8) []const u8 {
    if (payload.len < 128) {
        out[0] = tag;
        out[1] = @intCast(payload.len);
        @memcpy(out[2 .. 2 + payload.len], payload);
        return out[0 .. 2 + payload.len];
    } else if (payload.len < 256) {
        out[0] = tag;
        out[1] = 0x81;
        out[2] = @intCast(payload.len);
        @memcpy(out[3 .. 3 + payload.len], payload);
        return out[0 .. 3 + payload.len];
    } else {
        out[0] = tag;
        out[1] = 0x82;
        out[2] = @intCast((payload.len >> 8) & 0xff);
        out[3] = @intCast(payload.len & 0xff);
        @memcpy(out[4 .. 4 + payload.len], payload);
        return out[0 .. 4 + payload.len];
    }
}

fn berParseSlice(buf: []const u8) ?BerTlv {
    if (buf.len < 2) return null;
    const tag = buf[0];
    const len0 = buf[1];
    if ((len0 & 0x80) == 0) {
        const vlen: usize = len0;
        if (buf.len < 2 + vlen) return null;
        return .{ .tag = tag, .val = buf[2 .. 2 + vlen], .total_len = 2 + vlen };
    }
    const nlen: usize = len0 & 0x7f;
    if (nlen == 0 or nlen > 4 or buf.len < 2 + nlen) return null;
    var vlen: usize = 0;
    for (buf[2 .. 2 + nlen]) |b| {
        vlen = (vlen << 8) | b;
    }
    if (buf.len < 2 + nlen + vlen) return null;
    return .{ .tag = tag, .val = buf[2 + nlen .. 2 + nlen + vlen], .total_len = 2 + nlen + vlen };
}

const static_openldap_vendor: [:0]const u8 = "OpenLDAP";

pub fn ldap_err2string(err: c_int) callconv(.c) [*:0]const u8 {
    return switch (err) {
        0 => "Success",
        1 => "Operations error",
        2 => "Protocol error",
        0x31 => "Invalid credentials",
        -1 => "Can't contact LDAP server",
        -5 => "Timed out",
        -7 => "Bad search filter",
        -9 => "Bad parameter to an ldap routine",
        -10 => "No memory",
        else => "LDAP error",
    };
}

pub fn ldap_set_option(ld: ?*anyopaque, option: c_int, invalue: ?*const anyopaque) callconv(.c) c_int {
    _ = ld;
    _ = option;
    _ = invalue;
    return LDAP_SUCCESS;
}

pub fn ldap_get_option(ld: ?*anyopaque, option: c_int, outvalue: ?*anyopaque) callconv(.c) c_int {
    const out = outvalue orelse return -9;
    if (option == LDAP_OPT_API_INFO) {
        const api: *LDAPAPIInfo = @ptrCast(@alignCast(out));
        api.ldapai_info_version = 1;
        api.ldapai_api_version = 3001;
        api.ldapai_protocol_version = 3;
        api.ldapai_extensions = null;
        api.ldapai_vendor_name = @constCast(static_openldap_vendor.ptr);
        api.ldapai_vendor_version = 20608;
        return LDAP_SUCCESS;
    }
    if (option == LDAP_OPT_SOCKBUF) {
        const sb_out: *?*anyopaque = @ptrCast(@alignCast(out));
        sb_out.* = ld;
        return if (ld != null) LDAP_SUCCESS else -9;
    }
    return LDAP_SUCCESS;
}

pub fn ldap_memfree(p: ?*anyopaque) callconv(.c) void {
    if (p) |ptr| {
        if (@intFromPtr(ptr) == @intFromPtr(static_openldap_vendor.ptr)) return;
        mem.free(ptr);
    }
}

pub fn ber_memfree(p: ?*anyopaque) callconv(.c) void {
    ldap_memfree(p);
}

pub fn ber_memvfree(vec: ?*?*anyopaque) callconv(.c) void {
    mem.freeTyped(vec);
}

pub fn ber_memvfree_x(vec: ?*?*anyopaque, ctx: ?*anyopaque) callconv(.c) void {
    _ = ctx;
    ber_memvfree(vec);
}

pub fn ber_free(ber: ?*anyopaque, freebuf: c_int) callconv(.c) void {
    _ = freebuf;
    mem.free(ber);
}

pub fn ber_sockbuf_add_io(
    sb: ?*LdapHandle,
    sbio: ?*Sockbuf_IO,
    layer: c_int,
    arg: ?*anyopaque,
) callconv(.c) c_int {
    const h = sb orelse return -1;
    const io = sbio orelse return -1;
    h.sbiod.sbiod_level = layer;
    h.sbiod.sbiod_sb = h;
    h.sbiod.sbiod_io = io;
    if (io.sbi_setup) |setup_fn| {
        if (setup_fn(&h.sbiod, arg) != 0) return -1;
    } else {
        h.sbiod.sbiod_pvt = arg;
    }
    return 0;
}

fn parseLdapUrlDesc(s: []const u8) !*LDAPURLDesc {
    const scheme_end = std.mem.indexOf(u8, s, "://") orelse return error.BadUrl;
    const scheme = s[0..scheme_end];

    const lud = mem.create(LDAPURLDesc) orelse return error.OutOfMemory;
    errdefer ldap_free_urldesc(lud);

    lud.lud_scheme = cStrdupSlice(scheme) orelse return error.OutOfMemory;
    lud.lud_port = if (std.ascii.eqlIgnoreCase(scheme, "ldaps")) 636 else 389;

    const rest = s[scheme_end + 3 ..];
    const slash_idx = std.mem.indexOfScalar(u8, rest, '/') orelse rest.len;
    const hostport = rest[0..slash_idx];
    if (hostport.len > 0) {
        if (std.mem.lastIndexOfScalar(u8, hostport, ':')) |colon_idx| {
            lud.lud_host = cStrdupSlice(hostport[0..colon_idx]) orelse return error.OutOfMemory;
            lud.lud_port = std.fmt.parseInt(c_int, hostport[colon_idx + 1 ..], 10) catch lud.lud_port;
        } else {
            lud.lud_host = cStrdupSlice(hostport) orelse return error.OutOfMemory;
        }
    }
    if (slash_idx < rest.len) {
        const path = rest[slash_idx + 1 ..];
        const q_idx = std.mem.indexOfScalar(u8, path, '?') orelse path.len;
        lud.lud_dn = cStrdupSlice(path[0..q_idx]) orelse return error.OutOfMemory;
    }
    return lud;
}

pub fn ldap_url_parse(url: ?[*:0]const u8, ludpp: ?*?*LDAPURLDesc) callconv(.c) c_int {
    const out = ludpp orelse return -9;
    out.* = null;
    const url_ptr = url orelse return -9;
    const lud = parseLdapUrlDesc(std.mem.span(url_ptr)) catch |err| return switch (err) {
        error.OutOfMemory => -10,
        error.BadUrl => -9,
    };
    out.* = lud;
    return 0;
}

pub fn ldap_free_urldesc(ludp: ?*LDAPURLDesc) callconv(.c) void {
    const lud = ludp orelse return;
    mem.freeTyped(lud.lud_scheme);
    mem.freeTyped(lud.lud_host);
    mem.freeTyped(lud.lud_dn);
    mem.freeTyped(lud.lud_filter);
    mem.freeTyped(lud.lud_attrs);
    mem.freeTyped(lud.lud_exts);
    mem.freeTyped(lud);
}

fn createLdapHandle(fd: c_int) !*LdapHandle {
    const h = mem.create(LdapHandle) orelse return error.OutOfMemory;
    errdefer mem.freeTyped(h);
    h.* = .{ .fd = fd };
    h.sbiod.sbiod_sb = h;
    return h;
}

pub fn ldap_init(host: ?[*:0]const u8, port: c_int) callconv(.c) ?*LdapHandle {
    _ = host;
    _ = port;
    return createLdapHandle(-1) catch null;
}

pub fn ldap_initialize(ldp: ?*?*LdapHandle, url: ?[*:0]const u8) callconv(.c) c_int {
    _ = url;
    const out = ldp orelse return -9;
    out.* = createLdapHandle(-1) catch return -10;
    return 0;
}

pub fn ldap_init_fd(
    fd: c_int,
    proto: c_int,
    url: ?[*:0]const u8,
    ldp: ?*?*LdapHandle,
) callconv(.c) c_int {
    _ = proto;
    _ = url;
    const out = ldp orelse return -9;
    out.* = createLdapHandle(fd) catch return -10;
    return 0;
}

pub fn ldap_sasl_bind(
    ld: ?*LdapHandle,
    dn: ?[*:0]const u8,
    mechanism: ?[*:0]const u8,
    cred: ?*BerValue,
    sctrls: ?*?*anyopaque,
    cctrls: ?*?*anyopaque,
    msgidp: ?*c_int,
) callconv(.c) c_int {
    _ = mechanism;
    _ = sctrls;
    _ = cctrls;
    const h = ld orelse return -9;
    const msgid = h.next_msgid;
    h.next_msgid += 1;
    if (msgidp) |m| m.* = msgid;

    const dn_slice: []const u8 = if (dn) |d| std.mem.span(d) else "";
    const pw_slice: []const u8 = if (cred) |c|
        (if (c.bv_val) |p| p[0..@intCast(c.bv_len)] else "")
    else
        "";

    var ver_buf: [8]u8 = undefined;
    var dn_buf: [512]u8 = undefined;
    var auth_buf: [512]u8 = undefined;
    const ver_tlv = berWrapSlice(0x02, &[_]u8{0x03}, &ver_buf);
    const dn_tlv = berWrapSlice(0x04, dn_slice[0..@min(dn_slice.len, 250)], &dn_buf);
    const auth_tlv = berWrapSlice(0x80, pw_slice[0..@min(pw_slice.len, 250)], &auth_buf);

    var bind_body: [1040]u8 = undefined;
    @memcpy(bind_body[0..ver_tlv.len], ver_tlv);
    @memcpy(bind_body[ver_tlv.len .. ver_tlv.len + dn_tlv.len], dn_tlv);
    @memcpy(bind_body[ver_tlv.len + dn_tlv.len .. ver_tlv.len + dn_tlv.len + auth_tlv.len], auth_tlv);
    const bind_body_len = ver_tlv.len + dn_tlv.len + auth_tlv.len;

    var bind_op_buf: [1048]u8 = undefined;
    const bind_op = berWrapSlice(0x60, bind_body[0..bind_body_len], &bind_op_buf);

    var id_buf: [8]u8 = undefined;
    const id_byte: [1]u8 = .{@intCast(@min(msgid, 127))};
    const id_tlv = berWrapSlice(0x02, &id_byte, &id_buf);

    var msg_body: [1060]u8 = undefined;
    @memcpy(msg_body[0..id_tlv.len], id_tlv);
    @memcpy(msg_body[id_tlv.len .. id_tlv.len + bind_op.len], bind_op);

    var pkt_buf: [1068]u8 = undefined;
    const pkt = berWrapSlice(0x30, msg_body[0 .. id_tlv.len + bind_op.len], &pkt_buf);
    if (!h.writeAll(pkt)) return -1;
    return LDAP_SUCCESS;
}

pub fn ldap_simple_bind_s(
    ld: ?*LdapHandle,
    who: ?[*:0]const u8,
    passwd: ?[*:0]const u8,
) callconv(.c) c_int {
    _ = ld;
    _ = who;
    _ = passwd;
    return -1;
}

pub fn ldap_unbind_ext(
    ld: ?*LdapHandle,
    sctrls: ?*?*anyopaque,
    cctrls: ?*?*anyopaque,
) callconv(.c) c_int {
    _ = sctrls;
    _ = cctrls;
    const h = ld orelse return 0;
    const msgid_byte: u8 = @intCast(@min(h.next_msgid, 127));
    const unbind_pkt = [_]u8{ 0x30, 0x05, 0x02, 0x01, msgid_byte, 0x42, 0x00 };
    _ = h.writeAll(&unbind_pkt);
    if (h.sbiod.sbiod_io) |io| {
        if (io.sbi_close) |close_fn| {
            _ = close_fn(&h.sbiod);
        }
    }
    mem.freeTyped(h);
    return 0;
}

pub fn ldap_unbind_s(ld: ?*LdapHandle) callconv(.c) c_int {
    return ldap_unbind_ext(ld, null, null);
}

pub fn ldap_abandon_ext(
    ld: ?*LdapHandle,
    msgid: c_int,
    sctrls: ?*?*anyopaque,
    cctrls: ?*?*anyopaque,
) callconv(.c) c_int {
    _ = ld;
    _ = msgid;
    _ = sctrls;
    _ = cctrls;
    return 0;
}

pub fn ldap_search_ext(
    ld: ?*LdapHandle,
    base: ?[*:0]const u8,
    scope: c_int,
    filter: ?[*:0]const u8,
    attrs: ?*[*:0]u8,
    attrsonly: c_int,
    sctrls: ?*?*anyopaque,
    cctrls: ?*?*anyopaque,
    timeout: ?*anyopaque,
    sizelimit: c_int,
    msgidp: ?*c_int,
) callconv(.c) c_int {
    _ = scope;
    _ = filter;
    _ = attrs;
    _ = attrsonly;
    _ = sctrls;
    _ = cctrls;
    _ = timeout;
    _ = sizelimit;
    const h = ld orelse return -9;
    const msgid = h.next_msgid;
    h.next_msgid += 1;
    if (msgidp) |m| m.* = msgid;

    const base_slice: []const u8 = if (base) |b| std.mem.span(b) else "";
    var base_buf: [260]u8 = undefined;
    const base_tlv = berWrapSlice(0x04, base_slice[0..@min(base_slice.len, 250)], &base_buf);

    var search_op_buf: [268]u8 = undefined;
    const search_op = berWrapSlice(0x63, base_tlv, &search_op_buf);

    var id_buf: [8]u8 = undefined;
    const id_byte: [1]u8 = .{@intCast(@min(msgid, 127))};
    const id_tlv = berWrapSlice(0x02, &id_byte, &id_buf);

    var msg_body: [280]u8 = undefined;
    @memcpy(msg_body[0..id_tlv.len], id_tlv);
    @memcpy(msg_body[id_tlv.len .. id_tlv.len + search_op.len], search_op);

    var pkt_buf: [288]u8 = undefined;
    const pkt = berWrapSlice(0x30, msg_body[0 .. id_tlv.len + search_op.len], &pkt_buf);
    if (!h.writeAll(pkt)) return -1;
    return LDAP_SUCCESS;
}

pub fn ldap_search_s(
    ld: ?*LdapHandle,
    base: ?[*:0]const u8,
    scope: c_int,
    filter: ?[*:0]const u8,
    attrs: ?*[*:0]u8,
    attrsonly: c_int,
    res: ?*?*LdapMsg,
) callconv(.c) c_int {
    _ = ld;
    _ = base;
    _ = scope;
    _ = filter;
    _ = attrs;
    _ = attrsonly;
    if (res) |r| r.* = null;
    return -1;
}

pub fn ldap_result(
    ld: ?*LdapHandle,
    msgid: c_int,
    all: c_int,
    timeout: ?*anyopaque,
    result: ?*?*LdapMsg,
) callconv(.c) c_int {
    _ = msgid;
    _ = all;
    _ = timeout;
    const res_out = result orelse return -9;
    res_out.* = null;
    const h = ld orelse return -9;

    while (true) {
        if (berParseSlice(h.rx_buf[0..h.rx_len])) |outer| {
            if (outer.tag != 0x30) return -4;
            const id_tlv = berParseSlice(outer.val) orelse return -4;
            if (id_tlv.tag != 0x02) return -4;
            const op_tlv = berParseSlice(outer.val[id_tlv.total_len..]) orelse return -4;

            const msg = mem.create(LdapMsg) orelse return -10;
            msg.* = .{
                .msgtype = op_tlv.tag,
            };

            if (op_tlv.tag == 0x61 or op_tlv.tag == 0x65 or op_tlv.tag == 0x78) {
                if (berParseSlice(op_tlv.val)) |rc_tlv| {
                    if (rc_tlv.val.len > 0) {
                        msg.errcode = rc_tlv.val[0];
                    }
                }
            } else if (op_tlv.tag == 0x64) {
                if (berParseSlice(op_tlv.val)) |dn_tlv| {
                    const dcopy = @min(dn_tlv.val.len, msg.dn.len - 1);
                    @memcpy(msg.dn[0..dcopy], dn_tlv.val[0..dcopy]);
                    msg.dn_len = dcopy;
                    if (berParseSlice(op_tlv.val[dn_tlv.total_len..])) |attrs_seq| {
                        var apos: usize = 0;
                        while (apos < attrs_seq.val.len and msg.attr_count < msg.attrs.len) {
                            const attr_seq = berParseSlice(attrs_seq.val[apos..]) orelse break;
                            apos += attr_seq.total_len;
                            const type_tlv = berParseSlice(attr_seq.val) orelse continue;
                            const vals_set = berParseSlice(attr_seq.val[type_tlv.total_len..]) orelse continue;
                            var a_entry = &msg.attrs[msg.attr_count];
                            const ncopy = @min(type_tlv.val.len, a_entry.name.len - 1);
                            @memcpy(a_entry.name[0..ncopy], type_tlv.val[0..ncopy]);
                            a_entry.name_len = ncopy;
                            var vpos: usize = 0;
                            while (vpos < vals_set.val.len and a_entry.val_count < a_entry.vals.len) {
                                const val_tlv = berParseSlice(vals_set.val[vpos..]) orelse break;
                                vpos += val_tlv.total_len;
                                const vcopy = @min(val_tlv.val.len, a_entry.vals[a_entry.val_count].len - 1);
                                @memcpy(a_entry.vals[a_entry.val_count][0..vcopy], val_tlv.val[0..vcopy]);
                                a_entry.val_lens[a_entry.val_count] = vcopy;
                                a_entry.val_count += 1;
                            }
                            msg.attr_count += 1;
                        }
                    }
                }
            }

            const rem = h.rx_len - outer.total_len;
            if (rem > 0) {
                std.mem.copyForwards(u8, h.rx_buf[0..rem], h.rx_buf[outer.total_len..h.rx_len]);
            }
            h.rx_len = rem;
            res_out.* = msg;
            return @intCast(msg.msgtype);
        }

        if (h.rx_len >= h.rx_buf.len) return -4;
        const n = h.readSome(h.rx_buf[h.rx_len..]);
        if (n > 0) {
            h.rx_len += @intCast(n);
            continue;
        }
        if (n == 0) return -1;
        const err = std.c._errno().*;
        if (err == @backingInt(std.c.E.AGAIN) or err == @backingInt(std.c.E.INTR)) {
            return 0;
        }
        return -1;
    }
}

pub fn ldap_msgfree(lm: ?*LdapMsg) callconv(.c) c_int {
    mem.freeTyped(lm);
    return 0;
}

pub fn ldap_msgtype(lm: ?*const LdapMsg) callconv(.c) c_ulong {
    const msg = lm orelse return 0;
    return msg.msgtype;
}

pub fn ldap_parse_result(
    ld: ?*LdapHandle,
    res: ?*LdapMsg,
    errcodep: ?*c_int,
    matcheddnp: ?*?[*:0]u8,
    errmsgp: ?*?[*:0]u8,
    referralsp: ?*?*?[*:0]u8,
    serverctrlsp: ?*?*?*anyopaque,
    freeit: c_int,
) callconv(.c) c_int {
    _ = ld;
    const msg = res orelse return -9;
    if (errcodep) |e| e.* = msg.errcode;
    if (matcheddnp) |m| m.* = null;
    if (errmsgp) |em| em.* = null;
    if (referralsp) |r| r.* = null;
    if (serverctrlsp) |s| s.* = null;
    if (freeit != 0) mem.freeTyped(msg);
    return LDAP_SUCCESS;
}

pub fn ldap_first_entry(ld: ?*LdapHandle, chain: ?*LdapMsg) callconv(.c) ?*LdapMsg {
    _ = ld;
    _ = chain;
    return null;
}

pub fn ldap_next_entry(ld: ?*LdapHandle, entry: ?*LdapMsg) callconv(.c) ?*LdapMsg {
    _ = ld;
    _ = entry;
    return null;
}

pub fn ldap_first_attribute(
    ld: ?*LdapHandle,
    entry: ?*LdapMsg,
    berout: ?*?*anyopaque,
) callconv(.c) ?[*:0]u8 {
    _ = ld;
    _ = entry;
    if (berout) |b| b.* = null;
    return null;
}

pub fn ldap_next_attribute(
    ld: ?*LdapHandle,
    entry: ?*LdapMsg,
    ber: ?*anyopaque,
) callconv(.c) ?[*:0]u8 {
    _ = ld;
    _ = entry;
    _ = ber;
    return null;
}

pub fn ldap_get_dn(ld: ?*LdapHandle, entry: ?*LdapMsg) callconv(.c) ?[*:0]u8 {
    _ = ld;
    _ = entry;
    return null;
}

pub fn ldap_get_dn_ber(
    ld: ?*LdapHandle,
    entry: ?*LdapMsg,
    berout: ?*?*usize,
    dn: ?*BerValue,
) callconv(.c) c_int {
    _ = ld;
    const msg = entry orelse return -9;
    if (berout) |b| {
        const cursor = mem.create(usize) orelse return -10;
        b.* = cursor;
    }
    if (dn) |d| {
        d.bv_len = @intCast(msg.dn_len);
        d.bv_val = &msg.dn;
    }
    return LDAP_SUCCESS;
}

pub fn ldap_get_attribute_ber(
    ld: ?*LdapHandle,
    entry: ?*LdapMsg,
    ber: ?*usize,
    attr: ?*BerValue,
    vals: ?*?[*]BerValue,
) callconv(.c) c_int {
    _ = ld;
    const msg = entry orelse return -9;
    const cursor = ber orelse return -9;
    if (cursor.* >= msg.attr_count) {
        if (attr) |a| a.* = .{ .bv_len = 0, .bv_val = null };
        if (vals) |v| v.* = null;
        return LDAP_SUCCESS;
    }
    const idx = cursor.*;
    cursor.* = idx + 1;
    const a_entry = &msg.attrs[idx];
    if (attr) |a| {
        a.bv_len = @intCast(a_entry.name_len);
        a.bv_val = &a_entry.name;
    }
    if (vals) |v| {
        const arr = mem.callocMany(BerValue, a_entry.val_count + 1) orelse return -10;
        for (0..a_entry.val_count) |vi| {
            arr[vi] = .{
                .bv_len = @intCast(a_entry.val_lens[vi]),
                .bv_val = &a_entry.vals[vi],
            };
        }
        arr[a_entry.val_count] = .{ .bv_len = 0, .bv_val = null };
        v.* = arr;
    }
    return LDAP_SUCCESS;
}

pub fn ldap_get_values_len(
    ld: ?*LdapHandle,
    entry: ?*LdapMsg,
    target: ?[*:0]const u8,
) callconv(.c) ?*?*BerValue {
    _ = ld;
    _ = entry;
    _ = target;
    return null;
}

pub fn ldap_value_free_len(vals: ?*?*BerValue) callconv(.c) void {
    mem.freeTyped(vals);
}

pub fn ldap_pvt_url_scheme2proto(scheme: ?[*:0]const u8) callconv(.c) c_int {
    const s = std.mem.span(scheme orelse return -1);
    if (std.ascii.eqlIgnoreCase(s, "ldap") or std.ascii.eqlIgnoreCase(s, "ldaps")) return 1;
    if (std.ascii.eqlIgnoreCase(s, "ldapi")) return 2;
    if (std.ascii.eqlIgnoreCase(s, "cldap")) return 3;
    return -1;
}

pub fn ber_sockbuf_ctrl(sb: ?*anyopaque, opt: c_int, arg: ?*anyopaque) callconv(.c) c_int {
    _ = sb;
    _ = opt;
    _ = arg;
    return 1;
}

pub fn ber_memfree_x(p: ?*anyopaque, ctx: ?*anyopaque) callconv(.c) void {
    _ = ctx;
    mem.free(p);
}

pub fn ber_bvfree_x(bv: ?*BerValue, ctx: ?*anyopaque) callconv(.c) void {
    _ = ctx;
    if (bv) |b| {
        mem.freeTyped(b.bv_val);
        mem.freeTyped(b);
    }
}

pub fn ber_bvecfree_x(bvec: ?[*]?*BerValue, ctx: ?*anyopaque) callconv(.c) void {
    if (bvec) |vec| {
        var i: usize = 0;
        while (vec[i]) |bv| : (i += 1) {
            ber_bvfree_x(bv, ctx);
        }
        mem.freeTyped(vec);
    }
}

pub fn ldap_memvfree(v: ?[*]?*anyopaque) callconv(.c) void {
    if (v) |vec| {
        var i: usize = 0;
        while (vec[i]) |item| : (i += 1) {
            mem.free(item);
        }
        mem.freeTyped(vec);
    }
}

pub fn ldap_extended_operation(
    ld: ?*LdapHandle,
    reqoid: ?[*:0]const u8,
    reqdata: ?*BerValue,
    sctrls: ?*?*anyopaque,
    cctrls: ?*?*anyopaque,
    msgidp: ?*c_int,
) callconv(.c) c_int {
    _ = reqdata;
    _ = sctrls;
    _ = cctrls;
    const h = ld orelse return -9;
    const msgid = h.next_msgid;
    h.next_msgid += 1;
    if (msgidp) |m| m.* = msgid;

    const oid_slice: []const u8 = if (reqoid) |o| std.mem.span(o) else "";
    var oid_buf: [128]u8 = undefined;
    const oid_tlv = berWrapSlice(0x80, oid_slice[0..@min(oid_slice.len, 120)], &oid_buf);

    var ex_op_buf: [136]u8 = undefined;
    const ex_op = berWrapSlice(0x77, oid_tlv, &ex_op_buf);

    var id_buf: [8]u8 = undefined;
    const id_byte: [1]u8 = .{@intCast(@min(msgid, 127))};
    const id_tlv = berWrapSlice(0x02, &id_byte, &id_buf);

    var msg_body: [148]u8 = undefined;
    @memcpy(msg_body[0..id_tlv.len], id_tlv);
    @memcpy(msg_body[id_tlv.len .. id_tlv.len + ex_op.len], ex_op);

    var pkt_buf: [156]u8 = undefined;
    const pkt = berWrapSlice(0x30, msg_body[0 .. id_tlv.len + ex_op.len], &pkt_buf);
    if (!h.writeAll(pkt)) return -1;
    return LDAP_SUCCESS;
}

pub fn ldap_parse_sasl_bind_result(
    ld: ?*LdapHandle,
    res: ?*LdapMsg,
    servercredp: ?*?*BerValue,
    freeit: c_int,
) callconv(.c) c_int {
    _ = ld;
    if (servercredp) |sc| sc.* = null;
    if (freeit != 0 and res != null) _ = ldap_msgfree(res);
    return LDAP_SUCCESS;
}

pub fn ldap_sslinit(host: ?[*:0]const u8, port: c_int, secure: c_int) callconv(.c) ?*LdapHandle {
    _ = secure;
    return ldap_init(host, port);
}

// ============================================================================
// 8. Bundled GSS-API (gss_*, GSS_C_NT_HOSTBASED_SERVICE)
// ============================================================================

pub const OM_uint32 = u32;
pub const GSS_S_COMPLETE: OM_uint32 = 0;
pub const GSS_S_FAILURE: OM_uint32 = 0x000d0000;

pub const gss_OID_desc = extern struct {
    length: OM_uint32,
    elements: ?[*]const u8,
};
pub const gss_OID = ?*gss_OID_desc;

pub const gss_buffer_desc = extern struct {
    length: usize = 0,
    value: ?[*]u8 = null,
};
pub const gss_buffer_t = ?*gss_buffer_desc;

const hostbased_oid_bytes = "\x2a\x86\x48\x86\xf7\x12\x01\x02\x01\x04";
var static_hostbased_oid_desc: gss_OID_desc = .{
    .length = 10,
    .elements = hostbased_oid_bytes.ptr,
};

pub var GSS_C_NT_HOSTBASED_SERVICE: gss_OID = &static_hostbased_oid_desc;

pub fn gss_init_sec_context(
    minor_status: ?*OM_uint32,
    initiator_cred_handle: ?*anyopaque,
    context_handle: ?*?*anyopaque,
    target_name: ?*anyopaque,
    mech_type: gss_OID,
    req_flags: OM_uint32,
    time_req: OM_uint32,
    input_chan_bindings: ?*anyopaque,
    input_token: gss_buffer_t,
    actual_mech_type: ?*gss_OID,
    output_token: gss_buffer_t,
    ret_flags: ?*OM_uint32,
    time_rec: ?*OM_uint32,
) callconv(.c) OM_uint32 {
    _ = initiator_cred_handle;
    _ = context_handle;
    _ = target_name;
    _ = mech_type;
    _ = req_flags;
    _ = time_req;
    _ = input_chan_bindings;
    _ = input_token;
    if (minor_status) |ms| ms.* = 0;
    if (actual_mech_type) |am| am.* = null;
    if (output_token) |ot| ot.* = .{};
    if (ret_flags) |rf| rf.* = 0;
    if (time_rec) |tr| tr.* = 0;
    return GSS_S_FAILURE;
}

pub fn gss_delete_sec_context(
    minor_status: ?*OM_uint32,
    context_handle: ?*?*anyopaque,
    output_token: gss_buffer_t,
) callconv(.c) OM_uint32 {
    if (minor_status) |ms| ms.* = 0;
    if (context_handle) |ch| ch.* = null;
    if (output_token) |ot| ot.* = .{};
    return GSS_S_COMPLETE;
}

pub fn gss_release_buffer(
    minor_status: ?*OM_uint32,
    buffer: gss_buffer_t,
) callconv(.c) OM_uint32 {
    if (minor_status) |ms| ms.* = 0;
    if (buffer) |buf| {
        if (buf.value) |val| {
            mem.freeTyped(val);
            buf.value = null;
        }
        buf.length = 0;
    }
    return GSS_S_COMPLETE;
}

pub fn gss_import_name(
    minor_status: ?*OM_uint32,
    input_name_buffer: gss_buffer_t,
    input_name_type: gss_OID,
    output_name: ?*?[*:0]u8,
) callconv(.c) OM_uint32 {
    _ = input_name_type;
    if (minor_status) |ms| ms.* = 0;
    const out = output_name orelse return GSS_S_FAILURE;
    const in_buf = input_name_buffer orelse {
        out.* = null;
        return GSS_S_FAILURE;
    };
    const len = in_buf.length;
    const src_slice: []const u8 = if (len > 0 and in_buf.value != null)
        in_buf.value.?[0..len]
    else
        "";
    out.* = cStrdupSlice(src_slice) orelse return GSS_S_FAILURE;
    return GSS_S_COMPLETE;
}

pub fn gss_release_name(
    minor_status: ?*OM_uint32,
    input_name: ?*?[*:0]u8,
) callconv(.c) OM_uint32 {
    if (minor_status) |ms| ms.* = 0;
    if (input_name) |in_ptr| {
        if (in_ptr.*) |val| {
            mem.freeTyped(val);
            in_ptr.* = null;
        }
    }
    return GSS_S_COMPLETE;
}

pub fn gss_display_status(
    minor_status: ?*OM_uint32,
    status_value: OM_uint32,
    status_type: c_int,
    mech_type: gss_OID,
    message_context: ?*OM_uint32,
    status_string: gss_buffer_t,
) callconv(.c) OM_uint32 {
    _ = status_value;
    _ = status_type;
    _ = mech_type;
    if (minor_status) |ms| ms.* = 0;
    if (message_context) |mc| mc.* = 0;
    if (status_string) |ss| {
        const msg = "GSS-API error";
        if (cStrdupSlice(msg)) |dup| {
            ss.value = dup;
            ss.length = msg.len;
        } else {
            ss.* = .{};
        }
    }
    return GSS_S_COMPLETE;
}

pub fn gss_unwrap(
    minor_status: ?*OM_uint32,
    context_handle: ?*anyopaque,
    input_message_buffer: gss_buffer_t,
    output_message_buffer: gss_buffer_t,
    conf_state: ?*c_int,
    qop_state: ?*OM_uint32,
) callconv(.c) OM_uint32 {
    _ = context_handle;
    _ = input_message_buffer;
    if (minor_status) |ms| ms.* = 0;
    if (output_message_buffer) |om| om.* = .{};
    if (conf_state) |cs| cs.* = 0;
    if (qop_state) |qs| qs.* = 0;
    return GSS_S_FAILURE;
}

pub fn gss_wrap(
    minor_status: ?*OM_uint32,
    context_handle: ?*anyopaque,
    conf_req_flag: c_int,
    qop_req: OM_uint32,
    input_message_buffer: gss_buffer_t,
    conf_state: ?*c_int,
    output_message_buffer: gss_buffer_t,
) callconv(.c) OM_uint32 {
    _ = context_handle;
    _ = conf_req_flag;
    _ = qop_req;
    _ = input_message_buffer;
    if (minor_status) |ms| ms.* = 0;
    if (conf_state) |cs| cs.* = 0;
    if (output_message_buffer) |om| om.* = .{};
    return GSS_S_FAILURE;
}

pub fn gss_inquire_context(
    minor_status: ?*OM_uint32,
    context_handle: ?*anyopaque,
    src_name: ?*?*anyopaque,
    targ_name: ?*?*anyopaque,
    lifetime_rec: ?*OM_uint32,
    mech_type: ?*gss_OID,
    ctx_flags: ?*OM_uint32,
    locally_initiated: ?*c_int,
    open_context: ?*c_int,
) callconv(.c) OM_uint32 {
    _ = context_handle;
    if (minor_status) |ms| ms.* = 0;
    if (src_name) |sn| sn.* = null;
    if (targ_name) |tn| tn.* = null;
    if (lifetime_rec) |lr| lr.* = 0;
    if (mech_type) |mt| mt.* = null;
    if (ctx_flags) |cf| cf.* = 0;
    if (locally_initiated) |li| li.* = 1;
    if (open_context) |oc| oc.* = 0;
    return GSS_S_COMPLETE;
}

pub fn gss_display_name(
    minor_status: ?*OM_uint32,
    input_name: ?[*:0]const u8,
    output_name_buffer: gss_buffer_t,
    output_name_type: ?*gss_OID,
) callconv(.c) OM_uint32 {
    if (minor_status) |ms| ms.* = 0;
    if (output_name_type) |ont| ont.* = GSS_C_NT_HOSTBASED_SERVICE;
    const out_buf = output_name_buffer orelse return GSS_S_FAILURE;
    const name_ptr = input_name orelse {
        out_buf.* = .{};
        return GSS_S_FAILURE;
    };
    const slice = std.mem.span(name_ptr);
    const dup = cStrdupSlice(slice) orelse return GSS_S_FAILURE;
    out_buf.value = dup;
    out_buf.length = slice.len;
    return GSS_S_COMPLETE;
}

pub fn gss_acquire_cred(
    minor_status: ?*OM_uint32,
    desired_name: ?*anyopaque,
    time_req: OM_uint32,
    desired_mechs: ?*anyopaque,
    cred_usage: c_int,
    output_cred_handle: ?*?*anyopaque,
    actual_mechs: ?*?*anyopaque,
    time_rec: ?*OM_uint32,
) callconv(.c) OM_uint32 {
    _ = desired_name;
    _ = time_req;
    _ = desired_mechs;
    _ = cred_usage;
    if (minor_status) |ms| ms.* = 0;
    if (output_cred_handle) |oc| oc.* = null;
    if (actual_mechs) |am| am.* = null;
    if (time_rec) |tr| tr.* = 0;
    return GSS_S_FAILURE;
}

pub fn gss_indicate_mechs(
    minor_status: ?*OM_uint32,
    mech_set: ?*?*anyopaque,
) callconv(.c) OM_uint32 {
    if (minor_status) |ms| ms.* = 0;
    if (mech_set) |ms_out| ms_out.* = null;
    return GSS_S_COMPLETE;
}

pub fn gss_set_neg_mechs(
    minor_status: ?*OM_uint32,
    cred_handle: ?*anyopaque,
    mech_set: ?*anyopaque,
) callconv(.c) OM_uint32 {
    _ = cred_handle;
    _ = mech_set;
    if (minor_status) |ms| ms.* = 0;
    return GSS_S_COMPLETE;
}

pub fn gss_release_cred(
    minor_status: ?*OM_uint32,
    cred_handle: ?*?*anyopaque,
) callconv(.c) OM_uint32 {
    if (minor_status) |ms| ms.* = 0;
    if (cred_handle) |ch| ch.* = null;
    return GSS_S_COMPLETE;
}

// ============================================================================
// 9. Conditional C ABI Symbol Exports (active when is_bundled == true)
// ============================================================================

comptime {
    if (is_bundled and backend_options.idn == .libidn2) {
        @export(&idn2_check_version, .{ .name = "idn2_check_version", .linkage = .strong });
        @export(&idn2_lookup_u8, .{ .name = "idn2_lookup_u8", .linkage = .strong });
        @export(&idn2_lookup_ul, .{ .name = "idn2_lookup_ul", .linkage = .strong });
        @export(&idn2_to_ascii_8z, .{ .name = "idn2_to_ascii_8z", .linkage = .strong });
        @export(&idn2_to_ascii_lz, .{ .name = "idn2_to_ascii_lz", .linkage = .strong });
        @export(&idn2_to_unicode_8z8z, .{ .name = "idn2_to_unicode_8z8z", .linkage = .strong });
        @export(&idn2_free, .{ .name = "idn2_free", .linkage = .strong });
        @export(&idn2_strerror, .{ .name = "idn2_strerror", .linkage = .strong });
        @export(&idn2_strerror_name, .{ .name = "idn2_strerror_name", .linkage = .strong });
    }

    if (is_bundled and backend_options.psl) {
        @export(&psl_check_version_number, .{ .name = "psl_check_version_number", .linkage = .strong });
        @export(&psl_latest, .{ .name = "psl_latest", .linkage = .strong });
        @export(&psl_builtin, .{ .name = "psl_builtin", .linkage = .strong });
        @export(&psl_free, .{ .name = "psl_free", .linkage = .strong });
        @export(&psl_is_public_suffix, .{ .name = "psl_is_public_suffix", .linkage = .strong });
        @export(&psl_is_cookie_domain_acceptable, .{ .name = "psl_is_cookie_domain_acceptable", .linkage = .strong });
    }

    if (is_bundled and backend_options.ares) {
        @export(&ares_version, .{ .name = "ares_version", .linkage = .strong });
        @export(&ares_library_init, .{ .name = "ares_library_init", .linkage = .strong });
        @export(&ares_library_cleanup, .{ .name = "ares_library_cleanup", .linkage = .strong });
        @export(&ares_init_options, .{ .name = "ares_init_options", .linkage = .strong });
        @export(&ares_init, .{ .name = "ares_init", .linkage = .strong });
        @export(&ares_destroy, .{ .name = "ares_destroy", .linkage = .strong });
        @export(&ares_cancel, .{ .name = "ares_cancel", .linkage = .strong });
        @export(&ares_dup, .{ .name = "ares_dup", .linkage = .strong });
        @export(&ares_strerror, .{ .name = "ares_strerror", .linkage = .strong });
        @export(&ares_getsock, .{ .name = "ares_getsock", .linkage = .strong });
        @export(&ares_timeout, .{ .name = "ares_timeout", .linkage = .strong });
        @export(&ares_process_fd, .{ .name = "ares_process_fd", .linkage = .strong });
        @export(&ares_set_local_ip4, .{ .name = "ares_set_local_ip4", .linkage = .strong });
        @export(&ares_set_local_ip6, .{ .name = "ares_set_local_ip6", .linkage = .strong });
        @export(&ares_set_local_dev, .{ .name = "ares_set_local_dev", .linkage = .strong });
        @export(&ares_set_servers_csv, .{ .name = "ares_set_servers_csv", .linkage = .strong });
        @export(&ares_set_servers_ports_csv, .{ .name = "ares_set_servers_ports_csv", .linkage = .strong });
        @export(&ares_get_servers_csv, .{ .name = "ares_get_servers_csv", .linkage = .strong });
        @export(&ares_free_string, .{ .name = "ares_free_string", .linkage = .strong });
        @export(&ares_getaddrinfo, .{ .name = "ares_getaddrinfo", .linkage = .strong });
        @export(&ares_freeaddrinfo, .{ .name = "ares_freeaddrinfo", .linkage = .strong });
        @export(&ares_query, .{ .name = "ares_query", .linkage = .strong });
        @export(&ares_send, .{ .name = "ares_send", .linkage = .strong });
        @export(&ares_dns_record_create, .{ .name = "ares_dns_record_create", .linkage = .strong });
        @export(&ares_dns_record_destroy, .{ .name = "ares_dns_record_destroy", .linkage = .strong });
        @export(&ares_dns_record_query_add, .{ .name = "ares_dns_record_query_add", .linkage = .strong });
        @export(&ares_dns_write, .{ .name = "ares_dns_write", .linkage = .strong });
        @export(&ares_dns_parse, .{ .name = "ares_dns_parse", .linkage = .strong });
        @export(&ares_dns_record_rr_add, .{ .name = "ares_dns_record_rr_add", .linkage = .strong });
        @export(&ares_dns_record_rr_cnt, .{ .name = "ares_dns_record_rr_cnt", .linkage = .strong });
        @export(&ares_dns_record_rr_get, .{ .name = "ares_dns_record_rr_get", .linkage = .strong });
        @export(&ares_dns_rr_get_type, .{ .name = "ares_dns_rr_get_type", .linkage = .strong });
        @export(&ares_dns_rr_get_ttl, .{ .name = "ares_dns_rr_get_ttl", .linkage = .strong });
        @export(&ares_dns_rr_get_u16, .{ .name = "ares_dns_rr_get_u16", .linkage = .strong });
        @export(&ares_dns_rr_get_str, .{ .name = "ares_dns_rr_get_str", .linkage = .strong });
        @export(&ares_dns_rr_get_opt_cnt, .{ .name = "ares_dns_rr_get_opt_cnt", .linkage = .strong });
        @export(&ares_dns_rr_get_opt, .{ .name = "ares_dns_rr_get_opt", .linkage = .strong });
        @export(&ares_dns_rr_get_opt_byid, .{ .name = "ares_dns_rr_get_opt_byid", .linkage = .strong });
        @export(&ares_dns_rr_set_u16, .{ .name = "ares_dns_rr_set_u16", .linkage = .strong });
        @export(&ares_dns_rr_set_str, .{ .name = "ares_dns_rr_set_str", .linkage = .strong });
        @export(&ares_dns_rr_set_opt, .{ .name = "ares_dns_rr_set_opt", .linkage = .strong });
    }

    if (is_bundled and backend_options.nghttp2) {
        @export(&nghttp2_version, .{ .name = "nghttp2_version", .linkage = .strong });
        @export(&nghttp2_strerror, .{ .name = "nghttp2_strerror", .linkage = .strong });
        @export(&nghttp2_http2_strerror, .{ .name = "nghttp2_http2_strerror", .linkage = .strong });
        @export(&nghttp2_is_fatal, .{ .name = "nghttp2_is_fatal", .linkage = .strong });
        @export(&nghttp2_priority_spec_init, .{ .name = "nghttp2_priority_spec_init", .linkage = .strong });
        @export(&nghttp2_option_new, .{ .name = "nghttp2_option_new", .linkage = .strong });
        @export(&nghttp2_option_del, .{ .name = "nghttp2_option_del", .linkage = .strong });
        @export(&nghttp2_option_set_no_auto_window_update, .{ .name = "nghttp2_option_set_no_auto_window_update", .linkage = .strong });
        @export(&nghttp2_option_set_no_rfc9113_leading_and_trailing_ws_validation, .{ .name = "nghttp2_option_set_no_rfc9113_leading_and_trailing_ws_validation", .linkage = .strong });
        @export(&nghttp2_session_callbacks_new, .{ .name = "nghttp2_session_callbacks_new", .linkage = .strong });
        @export(&nghttp2_session_callbacks_del, .{ .name = "nghttp2_session_callbacks_del", .linkage = .strong });
        @export(&nghttp2_session_callbacks_set_send_callback, .{ .name = "nghttp2_session_callbacks_set_send_callback", .linkage = .strong });
        @export(&nghttp2_session_callbacks_set_on_frame_recv_callback, .{ .name = "nghttp2_session_callbacks_set_on_frame_recv_callback", .linkage = .strong });
        @export(&nghttp2_session_callbacks_set_on_invalid_frame_recv_callback, .{ .name = "nghttp2_session_callbacks_set_on_invalid_frame_recv_callback", .linkage = .strong });
        @export(&nghttp2_session_callbacks_set_on_data_chunk_recv_callback, .{ .name = "nghttp2_session_callbacks_set_on_data_chunk_recv_callback", .linkage = .strong });
        @export(&nghttp2_session_callbacks_set_before_frame_send_callback, .{ .name = "nghttp2_session_callbacks_set_before_frame_send_callback", .linkage = .strong });
        @export(&nghttp2_session_callbacks_set_on_frame_send_callback, .{ .name = "nghttp2_session_callbacks_set_on_frame_send_callback", .linkage = .strong });
        @export(&nghttp2_session_callbacks_set_on_frame_not_send_callback, .{ .name = "nghttp2_session_callbacks_set_on_frame_not_send_callback", .linkage = .strong });
        @export(&nghttp2_session_callbacks_set_on_stream_close_callback, .{ .name = "nghttp2_session_callbacks_set_on_stream_close_callback", .linkage = .strong });
        @export(&nghttp2_session_callbacks_set_on_begin_headers_callback, .{ .name = "nghttp2_session_callbacks_set_on_begin_headers_callback", .linkage = .strong });
        @export(&nghttp2_session_callbacks_set_on_header_callback, .{ .name = "nghttp2_session_callbacks_set_on_header_callback", .linkage = .strong });
        @export(&nghttp2_session_callbacks_set_error_callback2, .{ .name = "nghttp2_session_callbacks_set_error_callback2", .linkage = .strong });
        @export(&nghttp2_session_callbacks_set_send_data_callback, .{ .name = "nghttp2_session_callbacks_set_send_data_callback", .linkage = .strong });
        @export(&nghttp2_session_client_new, .{ .name = "nghttp2_session_client_new", .linkage = .strong });
        @export(&nghttp2_session_client_new2, .{ .name = "nghttp2_session_client_new2", .linkage = .strong });
        @export(&nghttp2_session_client_new3, .{ .name = "nghttp2_session_client_new3", .linkage = .strong });
        @export(&nghttp2_session_del, .{ .name = "nghttp2_session_del", .linkage = .strong });
        @export(&nghttp2_session_send, .{ .name = "nghttp2_session_send", .linkage = .strong });
        @export(&nghttp2_session_mem_recv, .{ .name = "nghttp2_session_mem_recv", .linkage = .strong });
        @export(&nghttp2_session_mem_recv2, .{ .name = "nghttp2_session_mem_recv2", .linkage = .strong });
        @export(&nghttp2_session_want_read, .{ .name = "nghttp2_session_want_read", .linkage = .strong });
        @export(&nghttp2_session_want_write, .{ .name = "nghttp2_session_want_write", .linkage = .strong });
        @export(&nghttp2_session_get_stream_user_data, .{ .name = "nghttp2_session_get_stream_user_data", .linkage = .strong });
        @export(&nghttp2_session_set_stream_user_data, .{ .name = "nghttp2_session_set_stream_user_data", .linkage = .strong });
        @export(&nghttp2_session_get_remote_settings, .{ .name = "nghttp2_session_get_remote_settings", .linkage = .strong });
        @export(&nghttp2_session_consume, .{ .name = "nghttp2_session_consume", .linkage = .strong });
        @export(&nghttp2_session_upgrade2, .{ .name = "nghttp2_session_upgrade2", .linkage = .strong });
        @export(&nghttp2_pack_settings_payload, .{ .name = "nghttp2_pack_settings_payload", .linkage = .strong });
        @export(&nghttp2_pack_settings_payload2, .{ .name = "nghttp2_pack_settings_payload2", .linkage = .strong });
        @export(&nghttp2_submit_settings, .{ .name = "nghttp2_submit_settings", .linkage = .strong });
        @export(&nghttp2_submit_request, .{ .name = "nghttp2_submit_request", .linkage = .strong });
        @export(&nghttp2_submit_request2, .{ .name = "nghttp2_submit_request2", .linkage = .strong });
        @export(&nghttp2_submit_rst_stream, .{ .name = "nghttp2_submit_rst_stream", .linkage = .strong });
        @export(&nghttp2_submit_ping, .{ .name = "nghttp2_submit_ping", .linkage = .strong });
        @export(&nghttp2_submit_goaway, .{ .name = "nghttp2_submit_goaway", .linkage = .strong });
        @export(&nghttp2_submit_priority, .{ .name = "nghttp2_submit_priority", .linkage = .strong });
        @export(&nghttp2_submit_window_update, .{ .name = "nghttp2_submit_window_update", .linkage = .strong });
        @export(&nghttp2_session_resume_data, .{ .name = "nghttp2_session_resume_data", .linkage = .strong });
        @export(&nghttp2_session_check_request_allowed, .{ .name = "nghttp2_session_check_request_allowed", .linkage = .strong });
        @export(&nghttp2_session_get_stream_effective_recv_data_length, .{ .name = "nghttp2_session_get_stream_effective_recv_data_length", .linkage = .strong });
        @export(&nghttp2_session_get_stream_effective_local_window_size, .{ .name = "nghttp2_session_get_stream_effective_local_window_size", .linkage = .strong });
        @export(&nghttp2_session_get_stream_local_window_size, .{ .name = "nghttp2_session_get_stream_local_window_size", .linkage = .strong });
        @export(&nghttp2_session_set_local_window_size, .{ .name = "nghttp2_session_set_local_window_size", .linkage = .strong });
        @export(&nghttp2_session_get_local_window_size, .{ .name = "nghttp2_session_get_local_window_size", .linkage = .strong });
        @export(&nghttp2_session_get_stream_remote_window_size, .{ .name = "nghttp2_session_get_stream_remote_window_size", .linkage = .strong });
        @export(&nghttp2_session_get_remote_window_size, .{ .name = "nghttp2_session_get_remote_window_size", .linkage = .strong });
    }

    if (is_bundled and backend_options.quic == .ngtcp2) {
        @export(&ngtcp2_version, .{ .name = "ngtcp2_version", .linkage = .strong });
        @export(&nghttp3_version, .{ .name = "nghttp3_version", .linkage = .strong });
        @export(&ngtcp2_settings_default, .{ .name = "Curl_ngtcp2_settings_default", .linkage = .strong });
        @export(&ngtcp2_transport_params_default, .{ .name = "Curl_ngtcp2_transport_params_default", .linkage = .strong });
        @export(&ngtcp2_conn_client_new, .{ .name = "Curl_ngtcp2_conn_client_new", .linkage = .strong });
        @export(&ngtcp2_conn_read_pkt, .{ .name = "Curl_ngtcp2_conn_read_pkt", .linkage = .strong });
        @export(&ngtcp2_conn_writev_stream, .{ .name = "Curl_ngtcp2_conn_writev_stream", .linkage = .strong });
        @export(&ngtcp2_conn_writev_datagram, .{ .name = "Curl_ngtcp2_conn_writev_datagram", .linkage = .strong });
        @export(&ngtcp2_conn_write_connection_close, .{ .name = "Curl_ngtcp2_conn_write_connection_close", .linkage = .strong });
        @export(&nghttp3_settings_default, .{ .name = "Curl_nghttp3_settings_default", .linkage = .strong });
        @export(&nghttp3_conn_client_new, .{ .name = "Curl_nghttp3_conn_client_new", .linkage = .strong });
        @export(&ngtcp2_cid_init, .{ .name = "ngtcp2_cid_init", .linkage = .strong });
        @export(&ngtcp2_settings_default, .{ .name = "ngtcp2_settings_default", .linkage = .strong });
        @export(&ngtcp2_settings_default_versioned, .{ .name = "ngtcp2_settings_default_versioned", .linkage = .strong });
        @export(&ngtcp2_transport_params_default, .{ .name = "ngtcp2_transport_params_default", .linkage = .strong });
        @export(&ngtcp2_transport_params_default_versioned, .{ .name = "ngtcp2_transport_params_default_versioned", .linkage = .strong });
        @export(&ngtcp2_ccerr_default, .{ .name = "ngtcp2_ccerr_default", .linkage = .strong });
        @export(&ngtcp2_ccerr_set_application_error, .{ .name = "ngtcp2_ccerr_set_application_error", .linkage = .strong });
        @export(&ngtcp2_ccerr_set_transport_error, .{ .name = "ngtcp2_ccerr_set_transport_error", .linkage = .strong });
        @export(&ngtcp2_ccerr_set_tls_alert, .{ .name = "ngtcp2_ccerr_set_tls_alert", .linkage = .strong });
        @export(&ngtcp2_ccerr_set_liberr, .{ .name = "ngtcp2_ccerr_set_liberr", .linkage = .strong });
        @export(&ngtcp2_path_storage_init, .{ .name = "ngtcp2_path_storage_init", .linkage = .strong });
        @export(&ngtcp2_path_storage_zero, .{ .name = "ngtcp2_path_storage_zero", .linkage = .strong });
        @export(&ngtcp2_conn_client_new, .{ .name = "ngtcp2_conn_client_new", .linkage = .strong });
        @export(&ngtcp2_conn_client_new_versioned, .{ .name = "ngtcp2_conn_client_new_versioned", .linkage = .strong });
        @export(&ngtcp2_conn_server_new, .{ .name = "ngtcp2_conn_server_new", .linkage = .strong });
        @export(&ngtcp2_conn_server_new_versioned, .{ .name = "ngtcp2_conn_server_new_versioned", .linkage = .strong });
        @export(&ngtcp2_conn_del, .{ .name = "ngtcp2_conn_del", .linkage = .strong });
        @export(&ngtcp2_conn_set_tls_native_handle, .{ .name = "ngtcp2_conn_set_tls_native_handle", .linkage = .strong });
        @export(&ngtcp2_conn_get_tls_alert, .{ .name = "ngtcp2_conn_get_tls_alert", .linkage = .strong });
        @export(&ngtcp2_conn_get_handshake_completed, .{ .name = "ngtcp2_conn_get_handshake_completed", .linkage = .strong });
        @export(&ngtcp2_conn_get_handshake_completed, .{ .name = "ngtcp2_conn_get_Handshake_completed", .linkage = .strong });
        @export(&ngtcp2_conn_install_rx_key, .{ .name = "ngtcp2_conn_install_rx_key", .linkage = .strong });
        @export(&ngtcp2_conn_install_tx_key, .{ .name = "ngtcp2_conn_install_tx_key", .linkage = .strong });
        @export(&ngtcp2_conn_install_initial_key, .{ .name = "ngtcp2_conn_install_initial_key", .linkage = .strong });
        @export(&ngtcp2_conn_install_rx_handshake_key, .{ .name = "ngtcp2_conn_install_rx_handshake_key", .linkage = .strong });
        @export(&ngtcp2_conn_install_tx_handshake_key, .{ .name = "ngtcp2_conn_install_tx_handshake_key", .linkage = .strong });
        @export(&ngtcp2_conn_in_closing_period, .{ .name = "ngtcp2_conn_in_closing_period", .linkage = .strong });
        @export(&ngtcp2_conn_in_draining_period, .{ .name = "ngtcp2_conn_in_draining_period", .linkage = .strong });
        @export(&ngtcp2_conn_get_expiry, .{ .name = "ngtcp2_conn_get_expiry", .linkage = .strong });
        @export(&ngtcp2_conn_handle_expiry, .{ .name = "ngtcp2_conn_handle_expiry", .linkage = .strong });
        @export(&ngtcp2_conn_get_send_quantum, .{ .name = "ngtcp2_conn_get_send_quantum", .linkage = .strong });
        @export(&ngtcp2_conn_get_path, .{ .name = "ngtcp2_conn_get_path", .linkage = .strong });
        @export(&ngtcp2_conn_get_max_tx_udp_payload_size, .{ .name = "ngtcp2_conn_get_max_tx_udp_payload_size", .linkage = .strong });
        @export(&ngtcp2_conn_get_streams_bidi_left, .{ .name = "ngtcp2_conn_get_streams_bidi_left", .linkage = .strong });
        @export(&ngtcp2_conn_get_streams_uni_left, .{ .name = "ngtcp2_conn_get_streams_uni_left", .linkage = .strong });
        @export(&ngtcp2_conn_get_remote_transport_params, .{ .name = "ngtcp2_conn_get_remote_transport_params", .linkage = .strong });
        @export(&ngtcp2_conn_get_remote_transport_params_versioned, .{ .name = "ngtcp2_conn_get_remote_transport_params_versioned", .linkage = .strong });
        @export(&ngtcp2_conn_open_bidi_stream, .{ .name = "ngtcp2_conn_open_bidi_stream", .linkage = .strong });
        @export(&ngtcp2_conn_open_uni_stream, .{ .name = "ngtcp2_conn_open_uni_stream", .linkage = .strong });
        @export(&ngtcp2_conn_shutdown_stream, .{ .name = "ngtcp2_conn_shutdown_stream", .linkage = .strong });
        @export(&ngtcp2_conn_shutdown_stream_read, .{ .name = "ngtcp2_conn_shutdown_stream_read", .linkage = .strong });
        @export(&ngtcp2_conn_shutdown_stream_write, .{ .name = "ngtcp2_conn_shutdown_stream_write", .linkage = .strong });
        @export(&ngtcp2_conn_extend_max_stream_offset, .{ .name = "ngtcp2_conn_extend_max_stream_offset", .linkage = .strong });
        @export(&ngtcp2_conn_extend_max_offset, .{ .name = "ngtcp2_conn_extend_max_offset", .linkage = .strong });
        @export(&ngtcp2_conn_update_pkt_tx_time, .{ .name = "ngtcp2_conn_update_pkt_tx_time", .linkage = .strong });
        @export(&ngtcp2_conn_encode_0rtt_transport_params, .{ .name = "ngtcp2_conn_encode_0rtt_transport_params", .linkage = .strong });
        @export(&ngtcp2_conn_decode_and_set_0rtt_transport_params, .{ .name = "ngtcp2_conn_decode_and_set_0rtt_transport_params", .linkage = .strong });
        @export(&ngtcp2_conn_read_pkt, .{ .name = "ngtcp2_conn_read_pkt", .linkage = .strong });
        @export(&ngtcp2_conn_read_pkt_versioned, .{ .name = "ngtcp2_conn_read_pkt_versioned", .linkage = .strong });
        @export(&ngtcp2_conn_writev_stream, .{ .name = "ngtcp2_conn_writev_stream", .linkage = .strong });
        @export(&ngtcp2_conn_writev_stream_versioned, .{ .name = "ngtcp2_conn_writev_stream_versioned", .linkage = .strong });
        @export(&ngtcp2_conn_writev_datagram, .{ .name = "ngtcp2_conn_writev_datagram", .linkage = .strong });
        @export(&ngtcp2_conn_writev_datagram_versioned, .{ .name = "ngtcp2_conn_writev_datagram_versioned", .linkage = .strong });
        @export(&ngtcp2_conn_write_connection_close, .{ .name = "ngtcp2_conn_write_connection_close", .linkage = .strong });
        @export(&ngtcp2_conn_write_connection_close_versioned, .{ .name = "ngtcp2_conn_write_connection_close_versioned", .linkage = .strong });
        @export(&ngtcp2_pkt_decode_version_cid, .{ .name = "ngtcp2_pkt_decode_version_cid", .linkage = .strong });
        @export(&ngtcp2_is_bidi_stream, .{ .name = "ngtcp2_is_bidi_stream", .linkage = .strong });
        @export(&ngtcp2_strerror, .{ .name = "ngtcp2_strerror", .linkage = .strong });
        @export(&ngtcp2_err_is_fatal, .{ .name = "ngtcp2_err_is_fatal", .linkage = .strong });
        @export(&ngtcp2_crypto_client_initial_cb, .{ .name = "ngtcp2_crypto_client_initial_cb", .linkage = .strong });
        @export(&ngtcp2_crypto_recv_client_initial_cb, .{ .name = "ngtcp2_crypto_recv_client_initial_cb", .linkage = .strong });
        @export(&ngtcp2_crypto_recv_crypto_data_cb, .{ .name = "ngtcp2_crypto_recv_crypto_data_cb", .linkage = .strong });
        @export(&ngtcp2_crypto_encrypt_cb, .{ .name = "ngtcp2_crypto_encrypt_cb", .linkage = .strong });
        @export(&ngtcp2_crypto_decrypt_cb, .{ .name = "ngtcp2_crypto_decrypt_cb", .linkage = .strong });
        @export(&ngtcp2_crypto_hp_mask_cb, .{ .name = "ngtcp2_crypto_hp_mask_cb", .linkage = .strong });
        @export(&ngtcp2_crypto_recv_retry_cb, .{ .name = "ngtcp2_crypto_recv_retry_cb", .linkage = .strong });
        @export(&ngtcp2_crypto_update_key_cb, .{ .name = "ngtcp2_crypto_update_key_cb", .linkage = .strong });
        @export(&ngtcp2_crypto_delete_crypto_aead_ctx_cb, .{ .name = "ngtcp2_crypto_delete_crypto_aead_ctx_cb", .linkage = .strong });
        @export(&ngtcp2_crypto_delete_crypto_cipher_ctx_cb, .{ .name = "ngtcp2_crypto_delete_crypto_cipher_ctx_cb", .linkage = .strong });
        @export(&ngtcp2_crypto_get_path_challenge_data_cb, .{ .name = "ngtcp2_crypto_get_path_challenge_data_cb", .linkage = .strong });
        @export(&ngtcp2_crypto_version_negotiation_cb, .{ .name = "ngtcp2_crypto_version_negotiation_cb", .linkage = .strong });
        @export(&ngtcp2_crypto_ossl_init, .{ .name = "ngtcp2_crypto_ossl_init", .linkage = .strong });
        @export(&ngtcp2_crypto_ossl_ctx_new, .{ .name = "ngtcp2_crypto_ossl_ctx_new", .linkage = .strong });
        @export(&ngtcp2_crypto_ossl_ctx_del, .{ .name = "ngtcp2_crypto_ossl_ctx_del", .linkage = .strong });
        @export(&ngtcp2_crypto_ossl_ctx_set_ssl, .{ .name = "ngtcp2_crypto_ossl_ctx_set_ssl", .linkage = .strong });
        @export(&ngtcp2_crypto_ossl_configure_client_session, .{ .name = "ngtcp2_crypto_ossl_configure_client_session", .linkage = .strong });
        @export(&ngtcp2_crypto_ossl_configure_server_session, .{ .name = "ngtcp2_crypto_ossl_configure_server_session", .linkage = .strong });
        @export(&ngtcp2_crypto_quictls_init, .{ .name = "ngtcp2_crypto_quictls_init", .linkage = .strong });
        @export(&ngtcp2_crypto_quictls_configure_client_session, .{ .name = "ngtcp2_crypto_quictls_configure_client_session", .linkage = .strong });
        @export(&ngtcp2_crypto_quictls_configure_server_session, .{ .name = "ngtcp2_crypto_quictls_configure_server_session", .linkage = .strong });
        @export(&ngtcp2_crypto_gnutls_configure_client_session, .{ .name = "ngtcp2_crypto_gnutls_configure_client_session", .linkage = .strong });
        @export(&ngtcp2_crypto_gnutls_configure_server_session, .{ .name = "ngtcp2_crypto_gnutls_configure_server_session", .linkage = .strong });
        @export(&ngtcp2_crypto_wolfssl_configure_client_context, .{ .name = "ngtcp2_crypto_wolfssl_configure_client_context", .linkage = .strong });
        @export(&ngtcp2_crypto_wolfssl_configure_server_context, .{ .name = "ngtcp2_crypto_wolfssl_configure_server_context", .linkage = .strong });
        @export(&nghttp3_settings_default, .{ .name = "nghttp3_settings_default", .linkage = .strong });
        @export(&nghttp3_settings_default_versioned, .{ .name = "nghttp3_settings_default_versioned", .linkage = .strong });
        @export(&nghttp3_conn_client_new, .{ .name = "nghttp3_conn_client_new", .linkage = .strong });
        @export(&nghttp3_conn_client_new_versioned, .{ .name = "nghttp3_conn_client_new_versioned", .linkage = .strong });
        @export(&nghttp3_conn_server_new, .{ .name = "nghttp3_conn_server_new", .linkage = .strong });
        @export(&nghttp3_conn_server_new_versioned, .{ .name = "nghttp3_conn_server_new_versioned", .linkage = .strong });
        @export(&nghttp3_conn_del, .{ .name = "nghttp3_conn_del", .linkage = .strong });
        @export(&nghttp3_conn_bind_control_stream, .{ .name = "nghttp3_conn_bind_control_stream", .linkage = .strong });
        @export(&nghttp3_conn_bind_qpack_streams, .{ .name = "nghttp3_conn_bind_qpack_streams", .linkage = .strong });
        @export(&nghttp3_conn_read_stream, .{ .name = "nghttp3_conn_read_stream", .linkage = .strong });
        @export(&nghttp3_conn_read_stream2, .{ .name = "nghttp3_conn_read_stream2", .linkage = .strong });
        @export(&nghttp3_conn_writev_stream, .{ .name = "nghttp3_conn_writev_stream", .linkage = .strong });
        @export(&nghttp3_conn_add_write_offset, .{ .name = "nghttp3_conn_add_write_offset", .linkage = .strong });
        @export(&nghttp3_conn_add_ack_offset, .{ .name = "nghttp3_conn_add_ack_offset", .linkage = .strong });
        @export(&nghttp3_conn_block_stream, .{ .name = "nghttp3_conn_block_stream", .linkage = .strong });
        @export(&nghttp3_conn_unblock_stream, .{ .name = "nghttp3_conn_unblock_stream", .linkage = .strong });
        @export(&nghttp3_conn_resume_stream, .{ .name = "nghttp3_conn_resume_stream", .linkage = .strong });
        @export(&nghttp3_conn_close_stream, .{ .name = "nghttp3_conn_close_stream", .linkage = .strong });
        @export(&nghttp3_conn_shutdown_stream_read, .{ .name = "nghttp3_conn_shutdown_stream_read", .linkage = .strong });
        @export(&nghttp3_conn_shutdown_stream_write, .{ .name = "nghttp3_conn_shutdown_stream_write", .linkage = .strong });
        @export(&nghttp3_conn_set_stream_user_data, .{ .name = "nghttp3_conn_set_stream_user_data", .linkage = .strong });
        @export(&nghttp3_conn_set_max_client_streams_bidi, .{ .name = "nghttp3_conn_set_max_client_streams_bidi", .linkage = .strong });
        @export(&nghttp3_conn_submit_request, .{ .name = "nghttp3_conn_submit_request", .linkage = .strong });
        @export(&nghttp3_conn_submit_response, .{ .name = "nghttp3_conn_submit_response", .linkage = .strong });
        @export(&nghttp3_rcbuf_get_buf, .{ .name = "nghttp3_rcbuf_get_buf", .linkage = .strong });
        @export(&nghttp3_strerror, .{ .name = "nghttp3_strerror", .linkage = .strong });
        @export(&nghttp3_err_is_fatal, .{ .name = "nghttp3_err_is_fatal", .linkage = .strong });
        @export(&nghttp3_err_infer_quic_app_error_code, .{ .name = "nghttp3_err_infer_quic_app_error_code", .linkage = .strong });
    }

    if (is_bundled and backend_options.ssh == .libssh2) {
        @export(&libssh2_init, .{ .name = "libssh2_init", .linkage = .strong });
        @export(&libssh2_exit, .{ .name = "libssh2_exit", .linkage = .strong });
        @export(&libssh2_version, .{ .name = "libssh2_version", .linkage = .strong });
        @export(&libssh2_session_init_ex, .{ .name = "libssh2_session_init_ex", .linkage = .strong });
        @export(&libssh2_session_abstract, .{ .name = "libssh2_session_abstract", .linkage = .strong });
        @export(&libssh2_session_free, .{ .name = "libssh2_session_free", .linkage = .strong });
        @export(&libssh2_session_set_blocking, .{ .name = "libssh2_session_set_blocking", .linkage = .strong });
        @export(&libssh2_session_handshake, .{ .name = "libssh2_session_handshake", .linkage = .strong });
        @export(&libssh2_session_last_error, .{ .name = "libssh2_session_last_error", .linkage = .strong });
        @export(&libssh2_session_last_errno, .{ .name = "libssh2_session_last_errno", .linkage = .strong });
        @export(&libssh2_session_hostkey, .{ .name = "libssh2_session_hostkey", .linkage = .strong });
        @export(&libssh2_session_method_pref, .{ .name = "libssh2_session_method_pref", .linkage = .strong });
        @export(&libssh2_session_methods, .{ .name = "libssh2_session_methods", .linkage = .strong });
        @export(&libssh2_session_disconnect_ex, .{ .name = "libssh2_session_disconnect_ex", .linkage = .strong });
        @export(&libssh2_session_block_directions, .{ .name = "libssh2_session_block_directions", .linkage = .strong });
        @export(&libssh2_session_flag, .{ .name = "libssh2_session_flag", .linkage = .strong });
        @export(&libssh2_hostkey_hash, .{ .name = "libssh2_hostkey_hash", .linkage = .strong });
        @export(&libssh2_knownhost_init, .{ .name = "libssh2_knownhost_init", .linkage = .strong });
        @export(&libssh2_knownhost_free, .{ .name = "libssh2_knownhost_free", .linkage = .strong });
        @export(&libssh2_knownhost_readfile, .{ .name = "libssh2_knownhost_readfile", .linkage = .strong });
        @export(&libssh2_knownhost_writefile, .{ .name = "libssh2_knownhost_writefile", .linkage = .strong });
        @export(&libssh2_knownhost_add, .{ .name = "libssh2_knownhost_add", .linkage = .strong });
        @export(&libssh2_knownhost_addc, .{ .name = "libssh2_knownhost_addc", .linkage = .strong });
        @export(&libssh2_knownhost_checkp, .{ .name = "libssh2_knownhost_checkp", .linkage = .strong });
        @export(&libssh2_knownhost_check, .{ .name = "libssh2_knownhost_check", .linkage = .strong });
        @export(&libssh2_knownhost_del, .{ .name = "libssh2_knownhost_del", .linkage = .strong });
        @export(&libssh2_userauth_list, .{ .name = "libssh2_userauth_list", .linkage = .strong });
        @export(&libssh2_userauth_authenticated, .{ .name = "libssh2_userauth_authenticated", .linkage = .strong });
        @export(&libssh2_userauth_publickey_fromfile_ex, .{ .name = "libssh2_userauth_publickey_fromfile_ex", .linkage = .strong });
        @export(&libssh2_userauth_password_ex, .{ .name = "libssh2_userauth_password_ex", .linkage = .strong });
        @export(&libssh2_userauth_hostbased_fromfile_ex, .{ .name = "libssh2_userauth_hostbased_fromfile_ex", .linkage = .strong });
        @export(&libssh2_userauth_keyboard_interactive_ex, .{ .name = "libssh2_userauth_keyboard_interactive_ex", .linkage = .strong });
        @export(&libssh2_agent_init, .{ .name = "libssh2_agent_init", .linkage = .strong });
        @export(&libssh2_agent_connect, .{ .name = "libssh2_agent_connect", .linkage = .strong });
        @export(&libssh2_agent_disconnect, .{ .name = "libssh2_agent_disconnect", .linkage = .strong });
        @export(&libssh2_agent_free, .{ .name = "libssh2_agent_free", .linkage = .strong });
        @export(&libssh2_agent_list_identities, .{ .name = "libssh2_agent_list_identities", .linkage = .strong });
        @export(&libssh2_agent_get_identity, .{ .name = "libssh2_agent_get_identity", .linkage = .strong });
        @export(&libssh2_agent_userauth, .{ .name = "libssh2_agent_userauth", .linkage = .strong });
        @export(&libssh2_sftp_init, .{ .name = "libssh2_sftp_init", .linkage = .strong });
        @export(&libssh2_sftp_shutdown, .{ .name = "libssh2_sftp_shutdown", .linkage = .strong });
        @export(&libssh2_sftp_last_error, .{ .name = "libssh2_sftp_last_error", .linkage = .strong });
        @export(&libssh2_sftp_open_ex, .{ .name = "libssh2_sftp_open_ex", .linkage = .strong });
        @export(&libssh2_sftp_read, .{ .name = "libssh2_sftp_read", .linkage = .strong });
        @export(&libssh2_sftp_readdir_ex, .{ .name = "libssh2_sftp_readdir_ex", .linkage = .strong });
        @export(&libssh2_sftp_write, .{ .name = "libssh2_sftp_write", .linkage = .strong });
        @export(&libssh2_sftp_close_handle, .{ .name = "libssh2_sftp_close_handle", .linkage = .strong });
        @export(&libssh2_sftp_seek64, .{ .name = "libssh2_sftp_seek64", .linkage = .strong });
        @export(&libssh2_sftp_stat_ex, .{ .name = "libssh2_sftp_stat_ex", .linkage = .strong });
        @export(&libssh2_sftp_symlink_ex, .{ .name = "libssh2_sftp_symlink_ex", .linkage = .strong });
        @export(&libssh2_sftp_mkdir_ex, .{ .name = "libssh2_sftp_mkdir_ex", .linkage = .strong });
        @export(&libssh2_sftp_rename_ex, .{ .name = "libssh2_sftp_rename_ex", .linkage = .strong });
        @export(&libssh2_sftp_rmdir_ex, .{ .name = "libssh2_sftp_rmdir_ex", .linkage = .strong });
        @export(&libssh2_sftp_unlink_ex, .{ .name = "libssh2_sftp_unlink_ex", .linkage = .strong });
        @export(&libssh2_sftp_statvfs, .{ .name = "libssh2_sftp_statvfs", .linkage = .strong });
        @export(&libssh2_channel_free, .{ .name = "libssh2_channel_free", .linkage = .strong });
        @export(&libssh2_channel_send_eof, .{ .name = "libssh2_channel_send_eof", .linkage = .strong });
        @export(&libssh2_channel_wait_eof, .{ .name = "libssh2_channel_wait_eof", .linkage = .strong });
        @export(&libssh2_channel_wait_closed, .{ .name = "libssh2_channel_wait_closed", .linkage = .strong });
        @export(&libssh2_channel_read_ex, .{ .name = "libssh2_channel_read_ex", .linkage = .strong });
        @export(&libssh2_channel_write_ex, .{ .name = "libssh2_channel_write_ex", .linkage = .strong });
        @export(&libssh2_scp_send64, .{ .name = "libssh2_scp_send64", .linkage = .strong });
        @export(&libssh2_scp_recv2, .{ .name = "libssh2_scp_recv2", .linkage = .strong });
        @export(&libssh2_trace, .{ .name = "libssh2_trace", .linkage = .strong });
    }

    if (is_bundled and (backend_options.ldap == .openldap or backend_options.ldap == .ldap) and builtin.os.tag != .windows) {
        @export(&ldap_err2string, .{ .name = "ldap_err2string", .linkage = .strong });
        @export(&ldap_set_option, .{ .name = "ldap_set_option", .linkage = .strong });
        @export(&ldap_get_option, .{ .name = "ldap_get_option", .linkage = .strong });
        @export(&ldap_memfree, .{ .name = "ldap_memfree", .linkage = .strong });
        @export(&ber_memfree, .{ .name = "ber_memfree", .linkage = .strong });
        @export(&ber_memvfree, .{ .name = "ber_memvfree", .linkage = .strong });
        @export(&ber_memvfree_x, .{ .name = "ber_memvfree_x", .linkage = .strong });
        @export(&ber_free, .{ .name = "ber_free", .linkage = .strong });
        @export(&ber_sockbuf_add_io, .{ .name = "ber_sockbuf_add_io", .linkage = .strong });
        @export(&ldap_url_parse, .{ .name = "ldap_url_parse", .linkage = .strong });
        @export(&ldap_free_urldesc, .{ .name = "ldap_free_urldesc", .linkage = .strong });
        @export(&ldap_init, .{ .name = "ldap_init", .linkage = .strong });
        @export(&ldap_initialize, .{ .name = "ldap_initialize", .linkage = .strong });
        @export(&ldap_init_fd, .{ .name = "ldap_init_fd", .linkage = .strong });
        @export(&ldap_sasl_bind, .{ .name = "ldap_sasl_bind", .linkage = .strong });
        @export(&ldap_simple_bind_s, .{ .name = "ldap_simple_bind_s", .linkage = .strong });
        @export(&ldap_unbind_ext, .{ .name = "ldap_unbind_ext", .linkage = .strong });
        @export(&ldap_unbind_s, .{ .name = "ldap_unbind_s", .linkage = .strong });
        @export(&ldap_abandon_ext, .{ .name = "ldap_abandon_ext", .linkage = .strong });
        @export(&ldap_search_ext, .{ .name = "ldap_search_ext", .linkage = .strong });
        @export(&ldap_search_s, .{ .name = "ldap_search_s", .linkage = .strong });
        @export(&ldap_result, .{ .name = "ldap_result", .linkage = .strong });
        @export(&ldap_msgfree, .{ .name = "ldap_msgfree", .linkage = .strong });
        @export(&ldap_msgtype, .{ .name = "ldap_msgtype", .linkage = .strong });
        @export(&ldap_parse_result, .{ .name = "ldap_parse_result", .linkage = .strong });
        @export(&ldap_first_entry, .{ .name = "ldap_first_entry", .linkage = .strong });
        @export(&ldap_next_entry, .{ .name = "ldap_next_entry", .linkage = .strong });
        @export(&ldap_first_attribute, .{ .name = "ldap_first_attribute", .linkage = .strong });
        @export(&ldap_next_attribute, .{ .name = "ldap_next_attribute", .linkage = .strong });
        @export(&ldap_get_dn, .{ .name = "ldap_get_dn", .linkage = .strong });
        @export(&ldap_get_dn_ber, .{ .name = "ldap_get_dn_ber", .linkage = .strong });
        @export(&ldap_get_attribute_ber, .{ .name = "ldap_get_attribute_ber", .linkage = .strong });
        @export(&ldap_get_values_len, .{ .name = "ldap_get_values_len", .linkage = .strong });
        @export(&ldap_value_free_len, .{ .name = "ldap_value_free_len", .linkage = .strong });
        @export(&ldap_pvt_url_scheme2proto, .{ .name = "ldap_pvt_url_scheme2proto", .linkage = .strong });
        @export(&ber_sockbuf_ctrl, .{ .name = "ber_sockbuf_ctrl", .linkage = .strong });
        @export(&ber_memfree_x, .{ .name = "ber_memfree_x", .linkage = .strong });
        @export(&ber_bvfree_x, .{ .name = "ber_bvfree_x", .linkage = .strong });
        @export(&ber_bvecfree_x, .{ .name = "ber_bvecfree_x", .linkage = .strong });
        @export(&ldap_memvfree, .{ .name = "ldap_memvfree", .linkage = .strong });
        @export(&ldap_extended_operation, .{ .name = "ldap_extended_operation", .linkage = .strong });
        @export(&ldap_parse_sasl_bind_result, .{ .name = "ldap_parse_sasl_bind_result", .linkage = .strong });
        @export(&ldap_sslinit, .{ .name = "ldap_sslinit", .linkage = .strong });
    }

    if (is_bundled and backend_options.gssapi and builtin.os.tag != .windows) {
        @export(&GSS_C_NT_HOSTBASED_SERVICE, .{ .name = "GSS_C_NT_HOSTBASED_SERVICE", .linkage = .strong });
        @export(&gss_init_sec_context, .{ .name = "gss_init_sec_context", .linkage = .strong });
        @export(&gss_delete_sec_context, .{ .name = "gss_delete_sec_context", .linkage = .strong });
        @export(&gss_release_buffer, .{ .name = "gss_release_buffer", .linkage = .strong });
        @export(&gss_import_name, .{ .name = "gss_import_name", .linkage = .strong });
        @export(&gss_release_name, .{ .name = "gss_release_name", .linkage = .strong });
        @export(&gss_display_status, .{ .name = "gss_display_status", .linkage = .strong });
        @export(&gss_unwrap, .{ .name = "gss_unwrap", .linkage = .strong });
        @export(&gss_wrap, .{ .name = "gss_wrap", .linkage = .strong });
        @export(&gss_inquire_context, .{ .name = "gss_inquire_context", .linkage = .strong });
        @export(&gss_display_name, .{ .name = "gss_display_name", .linkage = .strong });
        @export(&gss_acquire_cred, .{ .name = "gss_acquire_cred", .linkage = .strong });
        @export(&gss_indicate_mechs, .{ .name = "gss_indicate_mechs", .linkage = .strong });
        @export(&gss_set_neg_mechs, .{ .name = "gss_set_neg_mechs", .linkage = .strong });
        @export(&gss_release_cred, .{ .name = "gss_release_cred", .linkage = .strong });
    }
}

// ============================================================================
// 10. Unit Tests
// ============================================================================

test "idn2 RFC 3492 Punycode encode and decode" {
    try std.testing.expectEqualStrings("2.3.7", std.mem.span(idn2_check_version(null).?));
    try std.testing.expectEqualStrings("2.3.7", std.mem.span(idn2_check_version("2.0.0").?));
    try std.testing.expectEqualStrings("2.3.7", std.mem.span(idn2_check_version("2.3.7").?));
    try std.testing.expect(idn2_check_version("9.0.0") == null);

    const Case = struct {
        unicode: [:0]const u8,
        ascii: [:0]const u8,
    };
    const cases = [_]Case{
        .{ .unicode = "example.com", .ascii = "example.com" },
        .{ .unicode = "münchen.de", .ascii = "xn--mnchen-3ya.de" },
        .{ .unicode = "bücher.ch", .ascii = "xn--bcher-kva.ch" },
        .{ .unicode = "日本語.jp", .ascii = "xn--wgv71a119e.jp" },
        .{ .unicode = "sub.münchen。de", .ascii = "sub.xn--mnchen-3ya.de" },
    };

    for (cases) |tc| {
        var encoded: ?[*:0]u8 = null;
        try std.testing.expectEqual(IDN2_OK, idn2_lookup_u8(tc.unicode.ptr, &encoded, IDN2_NONTRANSITIONAL));
        try std.testing.expect(encoded != null);
        defer idn2_free(encoded);
        try std.testing.expectEqualStrings(tc.ascii, std.mem.span(encoded.?));

        var decoded: ?[*:0]u8 = null;
        try std.testing.expectEqual(IDN2_OK, idn2_to_unicode_8z8z(encoded.?, &decoded, 0));
        try std.testing.expect(decoded != null);
        defer idn2_free(decoded);
        const expected_unicode = if (std.mem.eql(u8, tc.unicode, "sub.münchen。de"))
            "sub.münchen.de"
        else
            tc.unicode;
        try std.testing.expectEqualStrings(expected_unicode, std.mem.span(decoded.?));
    }

    // Error cases: invalid UTF-8, control chars, consecutive dots
    var bad_out: ?[*:0]u8 = null;
    try std.testing.expectEqual(IDN2_ENCODING_ERROR, idn2_lookup_u8("\xff\xfe.com", &bad_out, 0));
    try std.testing.expectEqual(IDN2_ENCODING_ERROR, idn2_lookup_u8("bad\x01host.com", &bad_out, 0));
    try std.testing.expectEqual(IDN2_DOT_IN_LABEL, idn2_lookup_u8("bad..example.com", &bad_out, 0));
    try std.testing.expectEqualStrings("IDN2_OK", std.mem.span(idn2_strerror_name(IDN2_OK)));
    try std.testing.expectEqualStrings("success", std.mem.span(idn2_strerror(IDN2_OK)));
}

test "psl public suffix and cookie domain validation" {
    try std.testing.expectEqual(@as(c_int, (0 << 16) | (21 << 8) | 5), psl_check_version_number(0));
    const ctx = psl_latest(null);
    try std.testing.expect(ctx != null);
    try std.testing.expect(psl_builtin() != null);
    psl_free(ctx);

    // Rejected public suffixes
    try std.testing.expectEqual(@as(c_int, 0), psl_is_cookie_domain_acceptable(ctx, "example.com", ".com"));
    try std.testing.expectEqual(@as(c_int, 0), psl_is_cookie_domain_acceptable(ctx, "example.com", "com"));
    try std.testing.expectEqual(@as(c_int, 0), psl_is_cookie_domain_acceptable(ctx, "sub.example.co.uk", ".co.uk"));
    try std.testing.expectEqual(@as(c_int, 0), psl_is_cookie_domain_acceptable(ctx, "sub.example.co.uk", "co.uk"));
    try std.testing.expectEqual(@as(c_int, 0), psl_is_cookie_domain_acceptable(ctx, "app.github.io", ".github.io"));
    try std.testing.expectEqual(@as(c_int, 0), psl_is_cookie_domain_acceptable(ctx, "app.github.io", "github.io"));
    try std.testing.expectEqual(@as(c_int, 0), psl_is_cookie_domain_acceptable(ctx, "example.com", "other.com"));

    // Accepted registrable domains
    try std.testing.expectEqual(@as(c_int, 1), psl_is_cookie_domain_acceptable(ctx, "example.com", "example.com"));
    try std.testing.expectEqual(@as(c_int, 1), psl_is_cookie_domain_acceptable(ctx, "www.example.com", ".example.com"));
    try std.testing.expectEqual(@as(c_int, 1), psl_is_cookie_domain_acceptable(ctx, "sub.example.co.uk", "example.co.uk"));
    try std.testing.expectEqual(@as(c_int, 1), psl_is_cookie_domain_acceptable(ctx, "sub.example.co.uk", "sub.example.co.uk"));
    try std.testing.expectEqual(@as(c_int, 1), psl_is_cookie_domain_acceptable(ctx, "myapp.github.io", "myapp.github.io"));
    try std.testing.expectEqual(@as(c_int, 1), psl_is_cookie_domain_acceptable(ctx, "127.0.0.1", "127.0.0.1"));
}

test "ares version, immediate query callback, and DNS record helpers" {
    var ver_num: c_int = 0;
    const ver_str = ares_version(&ver_num);
    try std.testing.expectEqualStrings("1.34.0", std.mem.span(ver_str));
    try std.testing.expectEqual(@as(c_int, (1 << 16) | (34 << 8) | 0), ver_num);

    var channel: ?*anyopaque = null;
    try std.testing.expectEqual(ARES_SUCCESS, ares_init_options(&channel, null, 0));
    try std.testing.expect(channel != null);

    const CbState = struct {
        called: bool = false,
        status: c_int = -1,
    };
    const Holder = struct {
        fn onQuery(arg: ?*anyopaque, status: c_int, timeouts: c_int, abuf: ?[*]const u8, alen: c_int) callconv(.c) void {
            _ = timeouts;
            _ = abuf;
            _ = alen;
            const st: *CbState = @ptrCast(@alignCast(arg.?));
            st.called = true;
            st.status = status;
        }
    };

    var st: CbState = .{};
    ares_query(channel, "example.com", 1, 65, &Holder.onQuery, &st);
    try std.testing.expect(st.called);
    try std.testing.expectEqual(ARES_ENOTFOUND, st.status);

    var st2: CbState = .{};
    ares_send(channel, null, 0, &Holder.onQuery, &st2);
    try std.testing.expect(st2.called);
    try std.testing.expectEqual(ARES_ENOTFOUND, st2.status);

    var dnsrec: ?*AresDnsRecord = null;
    try std.testing.expectEqual(ARES_SUCCESS, ares_dns_record_create(&dnsrec, 1, 0, 0, 0));
    defer ares_dns_record_destroy(dnsrec);
    var rr: ?*AresDnsRr = null;
    try std.testing.expectEqual(ARES_SUCCESS, ares_dns_record_rr_add(&rr, dnsrec, 1, "example.com", 65, 1, 300));
    try std.testing.expectEqual(ARES_SUCCESS, ares_dns_rr_set_u16(rr, 1, 16));
    try std.testing.expectEqual(ARES_SUCCESS, ares_dns_rr_set_str(rr, 2, "svc.example.com."));
    try std.testing.expectEqual(@as(usize, 1), ares_dns_record_rr_cnt(dnsrec, 1));
    try std.testing.expectEqual(@as(u16, 16), ares_dns_rr_get_u16(rr, 1));
    try std.testing.expectEqualStrings("svc.example.com.", std.mem.span(ares_dns_rr_get_str(rr, 2).?));
}

test "bundled protocol versions and option queries (nghttp2, ngtcp2, nghttp3, libssh2, openldap, gssapi)" {
    const h2 = nghttp2_version(0).?;
    try std.testing.expectEqual(@as(c_int, 0x014000), h2.version_num);
    try std.testing.expectEqualStrings("1.64.0", std.mem.span(h2.version_str));
    try std.testing.expectEqualStrings("h2", std.mem.span(h2.proto_str));

    const tcp2 = ngtcp2_version(0).?;
    try std.testing.expectEqual(@as(c_int, 0x011000), tcp2.version_num);
    try std.testing.expectEqualStrings("1.16.0", std.mem.span(tcp2.version_str));

    const h3 = nghttp3_version(0).?;
    try std.testing.expectEqual(@as(c_int, 0x010c00), h3.version_num);
    try std.testing.expectEqualStrings("1.12.0", std.mem.span(h3.version_str));

    const ssh2_ver = libssh2_version(0).?;
    try std.testing.expectEqualStrings("1.11.1", std.mem.span(ssh2_ver));

    var api: LDAPAPIInfo = .{};
    try std.testing.expectEqual(LDAP_SUCCESS, ldap_get_option(null, LDAP_OPT_API_INFO, &api));
    try std.testing.expectEqual(@as(c_int, 20608), api.ldapai_vendor_version);
    try std.testing.expectEqualStrings("OpenLDAP", std.mem.span(api.ldapai_vendor_name.?));
    ldap_memfree(api.ldapai_vendor_name);

    var ludp: ?*LDAPURLDesc = null;
    try std.testing.expectEqual(@as(c_int, 0), ldap_url_parse("ldap://ldap.example.com:1389/dc=example,dc=com", &ludp));
    try std.testing.expect(ludp != null);
    defer ldap_free_urldesc(ludp);
    try std.testing.expectEqual(@as(c_int, 1389), ludp.?.lud_port);
    try std.testing.expectEqualStrings("ldap.example.com", std.mem.span(ludp.?.lud_host.?));

    var minor: OM_uint32 = 0;
    var in_buf: gss_buffer_desc = .{
        .length = 16,
        .value = @constCast("HTTP@example.com".ptr),
    };
    var gss_name: ?[*:0]u8 = null;
    try std.testing.expectEqual(GSS_S_COMPLETE, gss_import_name(&minor, &in_buf, GSS_C_NT_HOSTBASED_SERVICE, &gss_name));
    defer _ = gss_release_name(&minor, &gss_name);
    var out_buf: gss_buffer_desc = .{};
    defer _ = gss_release_buffer(&minor, &out_buf);
    try std.testing.expectEqual(GSS_S_COMPLETE, gss_display_name(&minor, gss_name, &out_buf, null));
    const out_slice = out_buf.value.?[0..out_buf.length];
    try std.testing.expectEqualStrings("HTTP@example.com", out_slice);
}
