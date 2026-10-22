const std = @import("std");
const builtin = @import("builtin");
const mem = @import("mem.zig");
const curlx_parse = @import("curlx_parse.zig");

pub const CURLcode = curlx_parse.CURLcode;
pub const CURLE_OK = curlx_parse.CURLE_OK;
pub const CURLE_URL_MALFORMAT: CURLcode = 3;
pub const CURLE_OUT_OF_MEMORY = curlx_parse.CURLE_OUT_OF_MEMORY;
pub const CURLE_BAD_FUNCTION_ARGUMENT = curlx_parse.CURLE_BAD_FUNCTION_ARGUMENT;

// ============================================================================
// ASCII ctype helpers (matching lib/curl_ctype.h)
// ============================================================================

inline fn isUpper(c: u8) bool {
    return c >= 'A' and c <= 'Z';
}

inline fn isLower(c: u8) bool {
    return c >= 'a' and c <= 'z';
}

inline fn isDigit(c: u8) bool {
    return c >= '0' and c <= '9';
}

inline fn isAlpha(c: u8) bool {
    return isLower(c) or isUpper(c);
}

inline fn isAlnum(c: u8) bool {
    return isDigit(c) or isLower(c) or isUpper(c);
}

inline fn isXdigit(c: u8) bool {
    return isDigit(c) or (c >= 'a' and c <= 'f') or (c >= 'A' and c <= 'F');
}

inline fn isPrint(c: u8) bool {
    return c >= ' ' and c <= 0x7e;
}

inline fn isGraph(c: u8) bool {
    return c > ' ' and c <= 0x7e;
}

inline fn isBlank(c: u8) bool {
    return c == ' ' or c == '\t';
}

// ============================================================================
// lib/escape.c
// ============================================================================

pub const REJECT_NADA: c_uint = 2;
pub const REJECT_CTRL: c_uint = 3;
pub const REJECT_ZERO: c_uint = 4;

const NOPE: u8 = 0xff;
const OK: u8 = 0x1f;

const hextable = [256]u8{
    NOPE, NOPE, NOPE, NOPE, NOPE, NOPE, NOPE, NOPE, // 00
    NOPE, NOPE, NOPE, NOPE, NOPE, NOPE, NOPE, NOPE, // 08
    NOPE, NOPE, NOPE, NOPE, NOPE, NOPE, NOPE, NOPE, // 10
    NOPE, NOPE, NOPE, NOPE, NOPE, NOPE, NOPE, NOPE, // 18
    NOPE, NOPE, NOPE, NOPE, NOPE, NOPE, NOPE, NOPE, // 20
    NOPE, NOPE, NOPE, NOPE, NOPE, OK, OK, NOPE, // 28
    0, 1, 2, 3, 4, 5, 6, 7, // 30
    8, 9, NOPE, NOPE, NOPE, NOPE, NOPE, NOPE, // 38
    NOPE, 0x0a, 0x0b, 0x0c, 0x0d, 0x0e, 0x0f, OK, // 40
    OK, OK, OK, OK, OK, OK, OK, OK, // 48
    OK, OK, OK, OK, OK, OK, OK, OK, // 50
    OK, OK, OK, NOPE, NOPE, NOPE, NOPE, OK, // 58
    NOPE, 0x0a, 0x0b, 0x0c, 0x0d, 0x0e, 0x0f, OK, // 60
    OK, OK, OK, OK, OK, OK, OK, OK, // 68
    OK, OK, OK, OK, OK, OK, OK, OK, // 70
    OK, OK, OK, NOPE, NOPE, NOPE, OK, NOPE, // 78
    NOPE, NOPE, NOPE, NOPE, NOPE, NOPE, NOPE, NOPE, // 80 - not ASCII
    NOPE, NOPE, NOPE, NOPE, NOPE, NOPE, NOPE, NOPE,
    NOPE, NOPE, NOPE, NOPE, NOPE, NOPE, NOPE, NOPE,
    NOPE, NOPE, NOPE, NOPE, NOPE, NOPE, NOPE, NOPE,
    NOPE, NOPE, NOPE, NOPE, NOPE, NOPE, NOPE, NOPE,
    NOPE, NOPE, NOPE, NOPE, NOPE, NOPE, NOPE, NOPE,
    NOPE, NOPE, NOPE, NOPE, NOPE, NOPE, NOPE, NOPE,
    NOPE, NOPE, NOPE, NOPE, NOPE, NOPE, NOPE, NOPE,
    NOPE, NOPE, NOPE, NOPE, NOPE, NOPE, NOPE, NOPE,
    NOPE, NOPE, NOPE, NOPE, NOPE, NOPE, NOPE, NOPE,
    NOPE, NOPE, NOPE, NOPE, NOPE, NOPE, NOPE, NOPE,
    NOPE, NOPE, NOPE, NOPE, NOPE, NOPE, NOPE, NOPE,
    NOPE, NOPE, NOPE, NOPE, NOPE, NOPE, NOPE, NOPE,
    NOPE, NOPE, NOPE, NOPE, NOPE, NOPE, NOPE, NOPE,
    NOPE, NOPE, NOPE, NOPE, NOPE, NOPE, NOPE, NOPE,
    NOPE, NOPE, NOPE, NOPE, NOPE, NOPE, NOPE, NOPE,
};

const ldigits = "0123456789abcdef";
const udigits = "0123456789ABCDEF";

export fn curl_escape(string: ?[*]const u8, length: c_int) callconv(.c) ?[*:0]u8 {
    return curl_easy_escape(null, string, length);
}

export fn curl_unescape(string: ?[*]const u8, length: c_int) callconv(.c) ?[*:0]u8 {
    return curl_easy_unescape(null, string, length, null);
}

export fn curl_easy_escape(curl: ?*anyopaque, string: ?[*]const u8, length: c_int) callconv(.c) ?[*:0]u8 {
    _ = curl;
    const s = string orelse return null;
    if (length < 0) return null;

    const len: usize = if (length != 0)
        @intCast(length)
    else
        std.mem.len(@as([*:0]const u8, @ptrCast(s)));

    if (len == 0) {
        return mem.strdup("");
    }
    if (len > std.math.maxInt(usize) / 16) {
        return null;
    }

    const encoded = mem.malloc((len * 3) + 1) orelse return null;
    var target: usize = 0;
    var src_idx: usize = 0;
    var f_idx: usize = 0;
    var nappend: usize = 0;

    while (src_idx < len) {
        const in = s[src_idx];
        src_idx += 1;

        if ((hextable[in] & 0x80) == 0) {
            nappend += 1;
        } else {
            if (nappend != 0) {
                @memcpy(encoded[target .. target + nappend], s[f_idx .. f_idx + nappend]);
                target += nappend;
                nappend = 0;
            }
            f_idx = src_idx;
            encoded[target] = '%';
            encoded[target + 1] = udigits[in >> 4];
            encoded[target + 2] = udigits[in & 0x0f];
            target += 3;
        }
    }
    if (nappend != 0) {
        @memcpy(encoded[target .. target + nappend], s[f_idx .. f_idx + nappend]);
        target += nappend;
    }
    encoded[target] = 0;
    return @ptrCast(encoded);
}

export fn Curl_urldecode(
    string: ?[*]const u8,
    length: usize,
    ostring: *?[*:0]u8,
    olen: ?*usize,
    ctrl: c_uint,
) callconv(.c) CURLcode {
    const s = string orelse return CURLE_BAD_FUNCTION_ARGUMENT;
    var alloc: usize = if (length != 0)
        length
    else
        std.mem.len(@as([*:0]const u8, @ptrCast(s)));

    const alloc_plus_one = std.math.add(usize, alloc, 1) catch return CURLE_OUT_OF_MEMORY;
    const ns_base = mem.malloc(alloc_plus_one) orelse return CURLE_OUT_OF_MEMORY;
    ostring.* = @ptrCast(ns_base);

    const reject_limit: u8 = if (ctrl == REJECT_CTRL)
        0x20
    else if (ctrl == REJECT_ZERO)
        1
    else
        0;

    var cur: [*]const u8 = s;
    var out_idx: usize = 0;

    while (alloc != 0) {
        if (cur[0] == '%') {
            if (alloc > 2) {
                const h1 = hextable[cur[1]];
                const h2 = hextable[cur[2]];
                if (((h1 | h2) & 0xf0) == 0) {
                    const in: u8 = (h1 << 4) | h2;
                    cur += 3;
                    alloc -= 3;
                    if (in < reject_limit) {
                        mem.free(ns_base);
                        ostring.* = null;
                        return CURLE_URL_MALFORMAT;
                    }
                    ns_base[out_idx] = in;
                    out_idx += 1;
                    continue;
                }
            }
            ns_base[out_idx] = '%';
            out_idx += 1;
            cur += 1;
            alloc -= 1;
            continue;
        } else {
            const rel = std.mem.indexOfScalar(u8, cur[1..alloc], '%');
            const n: usize = if (rel) |r| r + 1 else alloc;

            if (reject_limit != 0) {
                if (reject_limit == 1) {
                    if (std.mem.indexOfScalar(u8, cur[0..n], 0) != null) {
                        mem.free(ns_base);
                        ostring.* = null;
                        return CURLE_URL_MALFORMAT;
                    }
                } else {
                    for (cur[0..n]) |b| {
                        if (b < 0x20) {
                            mem.free(ns_base);
                            ostring.* = null;
                            return CURLE_URL_MALFORMAT;
                        }
                    }
                }
            }

            @memcpy(ns_base[out_idx .. out_idx + n], cur[0..n]);
            out_idx += n;
            cur += n;
            alloc -= n;
        }
    }
    ns_base[out_idx] = 0;

    if (olen) |ol| {
        ol.* = out_idx;
    }
    return CURLE_OK;
}

export fn curl_easy_unescape(
    curl: ?*anyopaque,
    string: ?[*]const u8,
    inlength: c_int,
    outlength: ?*c_int,
) callconv(.c) ?[*:0]u8 {
    _ = curl;
    var str: ?[*:0]u8 = null;
    if (string != null and inlength >= 0) {
        const inputlen: usize = @intCast(inlength);
        var outputlen: usize = 0;
        const res = Curl_urldecode(string, inputlen, &str, &outputlen, REJECT_NADA);
        if (res != CURLE_OK) {
            return null;
        }
        if (outlength) |ol| {
            if (outputlen <= @as(usize, @intCast(std.math.maxInt(c_int)))) {
                ol.* = @intCast(outputlen);
            } else {
                mem.free(str);
                str = null;
            }
        }
    }
    return str;
}

export fn curl_free(p: ?*anyopaque) callconv(.c) void {
    mem.free(p);
}

export fn Curl_hexencode(
    src: ?[*]const u8,
    len: usize,
    out: ?[*]u8,
    olen: usize,
) callconv(.c) void {
    if (src != null and len != 0 and out != null and olen >= 3) {
        const s = src.?;
        const o = out.?;
        var rem_len = len;
        var rem_olen = olen;
        var s_idx: usize = 0;
        var o_idx: usize = 0;
        while (rem_len != 0 and rem_olen >= 3) {
            rem_len -= 1;
            const b = s[s_idx];
            s_idx += 1;
            o[o_idx] = ldigits[b >> 4];
            o[o_idx + 1] = ldigits[b & 0x0f];
            o_idx += 2;
            rem_olen -= 2;
        }
        o[o_idx] = 0;
    } else if (out != null and olen != 0) {
        out.?[0] = 0;
    }
}

export fn Curl_hexbyte(dest: [*]u8, val: u8) callconv(.c) void {
    dest[0] = udigits[val >> 4];
    dest[1] = udigits[val & 0x0f];
}

// ============================================================================
// lib/curl_fnmatch.c
// ============================================================================

pub const CURL_FNMATCH_MATCH: c_int = 0;
pub const CURL_FNMATCH_NOMATCH: c_int = 1;
pub const CURL_FNMATCH_FAIL: c_int = 2;

const CURLFNM_CHARSET_LEN: usize = 256;
const CURLFNM_CHSET_SIZE: usize = CURLFNM_CHARSET_LEN + 15;

const CURLFNM_NEGATE: usize = CURLFNM_CHARSET_LEN;
const CURLFNM_ALNUM: usize = CURLFNM_CHARSET_LEN + 1;
const CURLFNM_DIGIT: usize = CURLFNM_CHARSET_LEN + 2;
const CURLFNM_XDIGIT: usize = CURLFNM_CHARSET_LEN + 3;
const CURLFNM_ALPHA: usize = CURLFNM_CHARSET_LEN + 4;
const CURLFNM_PRINT: usize = CURLFNM_CHARSET_LEN + 5;
const CURLFNM_BLANK: usize = CURLFNM_CHARSET_LEN + 6;
const CURLFNM_LOWER: usize = CURLFNM_CHARSET_LEN + 7;
const CURLFNM_GRAPH: usize = CURLFNM_CHARSET_LEN + 8;
const CURLFNM_SPACE: usize = CURLFNM_CHARSET_LEN + 9;
const CURLFNM_UPPER: usize = CURLFNM_CHARSET_LEN + 10;

const SetCharsetState = enum {
    default,
    rightbr,
    rightbrleftbr,
};

const ParseKeyState = enum {
    init,
    ddot,
};

const CharClass = enum {
    other,
    digit,
    upper,
    lower,
};

fn parsekeyword(pattern: *[*]const u8, charset: *[CURLFNM_CHSET_SIZE]u8) bool {
    var state: ParseKeyState = .init;
    var keyword: [10]u8 = @splat(0);
    var p = pattern.*;
    var found = false;
    var i: usize = 0;
    while (!found) : (i += 1) {
        const c = p[0];
        p += 1;
        if (i >= keyword.len) {
            return false;
        }
        switch (state) {
            .init => {
                if (isLower(c)) {
                    keyword[i] = c;
                } else if (c == ':') {
                    state = .ddot;
                } else {
                    return false;
                }
            },
            .ddot => {
                if (c == ']') {
                    found = true;
                } else {
                    return false;
                }
            },
        }
    }

    pattern.* = p;
    const kw = std.mem.sliceTo(&keyword, 0);
    if (std.mem.eql(u8, kw, "digit")) {
        charset[CURLFNM_DIGIT] = 1;
    } else if (std.mem.eql(u8, kw, "alnum")) {
        charset[CURLFNM_ALNUM] = 1;
    } else if (std.mem.eql(u8, kw, "alpha")) {
        charset[CURLFNM_ALPHA] = 1;
    } else if (std.mem.eql(u8, kw, "xdigit")) {
        charset[CURLFNM_XDIGIT] = 1;
    } else if (std.mem.eql(u8, kw, "print")) {
        charset[CURLFNM_PRINT] = 1;
    } else if (std.mem.eql(u8, kw, "graph")) {
        charset[CURLFNM_GRAPH] = 1;
    } else if (std.mem.eql(u8, kw, "space")) {
        charset[CURLFNM_SPACE] = 1;
    } else if (std.mem.eql(u8, kw, "blank")) {
        charset[CURLFNM_BLANK] = 1;
    } else if (std.mem.eql(u8, kw, "upper")) {
        charset[CURLFNM_UPPER] = 1;
    } else if (std.mem.eql(u8, kw, "lower")) {
        charset[CURLFNM_LOWER] = 1;
    } else {
        return false;
    }
    return true;
}

fn charclass(c: u8) CharClass {
    if (isUpper(c)) return .upper;
    if (isLower(c)) return .lower;
    if (isDigit(c)) return .digit;
    return .other;
}

fn setcharorrange(pp: *[*]const u8, charset: *[CURLFNM_CHSET_SIZE]u8) void {
    var p = pp.*;
    pp.* = p + 1;
    var c = p[0];
    p += 1;

    charset[c] = 1;
    if (isAlnum(c) and p[0] == '-') {
        p += 1;
        const cc = charclass(c);
        var endrange = p[0];
        if (endrange == 0) return;
        p += 1;

        if (endrange == '\\') {
            endrange = p[0];
            if (endrange == 0) return;
            p += 1;
        }
        if (endrange >= c and charclass(endrange) == cc) {
            while (c != endrange) {
                c +%= 1;
                if (charclass(c) == cc) {
                    charset[c] = 1;
                }
            }
            pp.* = p;
        }
    }
}

fn setcharset(p: *[*]const u8, charset: *[CURLFNM_CHSET_SIZE]u8) bool {
    var state: SetCharsetState = .default;
    var something_found = false;

    @memset(charset, 0);
    while (true) {
        const c = p.*[0];
        if (c == 0) {
            return false;
        }

        switch (state) {
            .default => {
                if (c == ']') {
                    if (something_found) {
                        return true;
                    }
                    something_found = true;
                    state = .rightbr;
                    charset[c] = 1;
                    p.* += 1;
                } else if (c == '[') {
                    var pp = p.* + 1;
                    if (pp[0] == ':') {
                        pp += 1;
                        if (parsekeyword(&pp, charset)) {
                            p.* = pp;
                        } else {
                            charset[c] = 1;
                            p.* += 1;
                        }
                    } else {
                        charset[c] = 1;
                        p.* += 1;
                    }
                    something_found = true;
                } else if (c == '^' or c == '!') {
                    if (!something_found) {
                        if (charset[CURLFNM_NEGATE] != 0) {
                            charset[c] = 1;
                            something_found = true;
                        } else {
                            charset[CURLFNM_NEGATE] = 1;
                        }
                    } else {
                        charset[c] = 1;
                    }
                    p.* += 1;
                } else if (c == '\\') {
                    p.* += 1;
                    const escaped = p.*[0];
                    if (escaped != 0) {
                        setcharorrange(p, charset);
                    } else {
                        charset['\\'] = 1;
                    }
                    something_found = true;
                } else {
                    setcharorrange(p, charset);
                    something_found = true;
                }
            },
            .rightbr => {
                if (c == '[') {
                    state = .rightbrleftbr;
                    charset[c] = 1;
                    p.* += 1;
                } else if (c == ']') {
                    return true;
                } else if (isPrint(c)) {
                    charset[c] = 1;
                    p.* += 1;
                    state = .default;
                } else {
                    return false;
                }
            },
            .rightbrleftbr => {
                if (c == ']') {
                    return true;
                }
                state = .default;
                charset[c] = 1;
                p.* += 1;
            },
        }
    }
}

fn matchtoken(pp: *[*]const u8, sp: *[*]const u8) i32 {
    var p = pp.*;
    const s = sp.*;

    switch (p[0]) {
        '?' => {},
        '\\' => {
            if (p[1] != 0) {
                p += 1;
            }
            if (s[0] != p[0]) {
                return 0;
            }
        },
        '[' => {
            var charset: [CURLFNM_CHSET_SIZE]u8 = undefined;
            var pp2 = p + 1;
            var found = false;
            if (!setcharset(&pp2, &charset)) {
                return -1;
            }
            const sc = s[0];
            if (charset[sc] != 0) {
                found = true;
            } else if (charset[CURLFNM_ALNUM] != 0) {
                found = isAlnum(sc);
            } else if (charset[CURLFNM_ALPHA] != 0) {
                found = isAlpha(sc);
            } else if (charset[CURLFNM_DIGIT] != 0) {
                found = isDigit(sc);
            } else if (charset[CURLFNM_XDIGIT] != 0) {
                found = isXdigit(sc);
            } else if (charset[CURLFNM_PRINT] != 0) {
                found = isPrint(sc);
            } else if (charset[CURLFNM_SPACE] != 0) {
                found = isBlank(sc);
            } else if (charset[CURLFNM_UPPER] != 0) {
                found = isUpper(sc);
            } else if (charset[CURLFNM_LOWER] != 0) {
                found = isLower(sc);
            } else if (charset[CURLFNM_BLANK] != 0) {
                found = isBlank(sc);
            } else if (charset[CURLFNM_GRAPH] != 0) {
                found = isGraph(sc);
            }

            if (charset[CURLFNM_NEGATE] != 0) {
                found = !found;
            }
            if (!found) {
                return 0;
            }
            pp.* = pp2 + 1;
            sp.* = s + 1;
            return 1;
        },
        else => {
            if (p[0] != s[0]) {
                return 0;
            }
        },
    }
    pp.* = p + 1;
    sp.* = s + 1;
    return 1;
}

fn fnmatchLoop(pattern: [*]const u8, string: [*]const u8) c_int {
    var p = pattern;
    var s = string;
    var star_p: ?[*]const u8 = null;
    var star_s: ?[*]const u8 = null;
    var maxstars: i32 = 2;

    while (s[0] != 0) {
        if (p[0] == '*') {
            if (maxstars == 0) {
                return CURL_FNMATCH_NOMATCH;
            }
            maxstars -= 1;
            while (true) {
                p += 1;
                if (p[0] == 0) {
                    return CURL_FNMATCH_MATCH;
                }
                if (p[0] == '?') {
                    if (s[0] == 0) {
                        return CURL_FNMATCH_NOMATCH;
                    }
                    s += 1;
                } else if (p[0] != '*') {
                    break;
                }
            }
            star_p = p;
            star_s = s;
        } else if (p[0] != 0) {
            var np = p;
            var ns = s;
            const r = matchtoken(&np, &ns);
            if (r < 0) {
                return CURL_FNMATCH_NOMATCH;
            }
            if (r != 0) {
                p = np;
                s = ns;
                continue;
            }
            const sp = star_p orelse return CURL_FNMATCH_NOMATCH;
            p = sp;
            star_s = star_s.? + 1;
            s = star_s.?;
        } else if (star_p) |sp| {
            p = sp;
            star_s = star_s.? + 1;
            s = star_s.?;
        } else {
            return CURL_FNMATCH_NOMATCH;
        }
    }
    while (p[0] == '*') {
        if (maxstars == 0) {
            return CURL_FNMATCH_NOMATCH;
        }
        maxstars -= 1;
        while (true) {
            p += 1;
            if (p[0] == '?') {
                return CURL_FNMATCH_NOMATCH;
            }
            if (p[0] != '*') break;
        }
    }
    return if (p[0] != 0) CURL_FNMATCH_NOMATCH else CURL_FNMATCH_MATCH;
}

export fn Curl_fnmatch(ptr: ?*anyopaque, pattern: ?[*:0]const u8, string: ?[*:0]const u8) callconv(.c) c_int {
    _ = ptr;
    const pat = pattern orelse return CURL_FNMATCH_FAIL;
    const str = string orelse return CURL_FNMATCH_FAIL;
    return fnmatchLoop(pat, str);
}

// ============================================================================
// lib/parsedate.c
// ============================================================================

pub const time_t = i64;

export const Curl_wkday = [7][*:0]const u8{
    "Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun",
};

export const Curl_month = [12][*:0]const u8{
    "Jan", "Feb", "Mar", "Apr", "May", "Jun",
    "Jul", "Aug", "Sep", "Oct", "Nov", "Dec",
};

const PARSEDATE_OK: c_int = 0;
const PARSEDATE_FAIL: c_int = -1;

const TzInfo = struct {
    tz: u32,
    offset: i16,
};

const DST: i16 = -60;

const tzone = [26]i16{
    -1 * 60, // Alpha
    -2 * 60, // Bravo
    -3 * 60, // Charlie
    -4 * 60, // Delta
    -5 * 60, // Echo
    -6 * 60, // Foxtrot
    -7 * 60, // Golf
    -8 * 60, // Hotel
    -9 * 60, // India
    -1, // J - not a timezone
    -10 * 60, // Kilo
    -11 * 60, // Lima
    -12 * 60, // Mike
    60, // November
    2 * 60, // Oscar
    3 * 60, // Papa
    4 * 60, // Quebec
    5 * 60, // Romeo
    6 * 60, // Sierra
    7 * 60, // Tango
    8 * 60, // Uniform
    9 * 60, // Victor
    10 * 60, // Whiskey
    11 * 60, // X-ray
    12 * 60, // Yankee
    0, // Zulu, zero meridian, a.k.a. UTC
};

fn mktz(a: u8, b: u8, c: u8, d: u8) u32 {
    return (@as(u32, a) << 24) | (@as(u32, b) << 16) | (@as(u32, c) << 8) | @as(u32, d);
}

const tzthree = [_]TzInfo{
    .{ .tz = mktz('A', 'D', 'T', 0), .offset = 240 + DST },
    .{ .tz = mktz('A', 'S', 'T', 0), .offset = 240 },
    .{ .tz = mktz('B', 'S', 'T', 0), .offset = 0 + DST },
    .{ .tz = mktz('C', 'A', 'T', 0), .offset = 600 },
    .{ .tz = mktz('C', 'C', 'T', 0), .offset = -480 },
    .{ .tz = mktz('C', 'D', 'T', 0), .offset = 360 + DST },
    .{ .tz = mktz('C', 'E', 'T', 0), .offset = -60 },
    .{ .tz = mktz('C', 'S', 'T', 0), .offset = 360 },
    .{ .tz = mktz('E', 'D', 'T', 0), .offset = 300 + DST },
    .{ .tz = mktz('E', 'E', 'T', 0), .offset = -120 },
    .{ .tz = mktz('E', 'S', 'T', 0), .offset = 300 },
    .{ .tz = mktz('F', 'S', 'T', 0), .offset = -60 + DST },
    .{ .tz = mktz('F', 'W', 'T', 0), .offset = -60 },
    .{ .tz = mktz('G', 'M', 'T', 0), .offset = 0 },
    .{ .tz = mktz('G', 'S', 'T', 0), .offset = -600 },
    .{ .tz = mktz('H', 'D', 'T', 0), .offset = 600 + DST },
    .{ .tz = mktz('H', 'S', 'T', 0), .offset = 600 },
    .{ .tz = mktz('J', 'S', 'T', 0), .offset = -540 },
    .{ .tz = mktz('M', 'D', 'T', 0), .offset = 420 + DST },
    .{ .tz = mktz('M', 'E', 'T', 0), .offset = -60 },
    .{ .tz = mktz('M', 'S', 'T', 0), .offset = 420 },
    .{ .tz = mktz('N', 'Z', 'T', 0), .offset = -720 },
    .{ .tz = mktz('P', 'D', 'T', 0), .offset = 480 + DST },
    .{ .tz = mktz('P', 'S', 'T', 0), .offset = 480 },
    .{ .tz = mktz('U', 'T', 'C', 0), .offset = 0 },
    .{ .tz = mktz('W', 'A', 'T', 0), .offset = 60 },
    .{ .tz = mktz('W', 'E', 'T', 0), .offset = 0 },
    .{ .tz = mktz('Y', 'D', 'T', 0), .offset = 540 + DST },
    .{ .tz = mktz('Y', 'S', 'T', 0), .offset = 540 },
};

const tzfoura = [_]TzInfo{
    .{ .tz = mktz('A', 'H', 'S', 'T'), .offset = 600 },
    .{ .tz = mktz('C', 'E', 'S', 'T'), .offset = -60 + DST },
    .{ .tz = mktz('E', 'A', 'D', 'T'), .offset = -600 + DST },
    .{ .tz = mktz('E', 'A', 'S', 'T'), .offset = -600 },
    .{ .tz = mktz('I', 'D', 'L', 'E'), .offset = -720 },
    .{ .tz = mktz('I', 'D', 'L', 'W'), .offset = 720 },
    .{ .tz = mktz('M', 'E', 'S', 'T'), .offset = -60 + DST },
    .{ .tz = mktz('M', 'E', 'S', 'Z'), .offset = -60 + DST },
    .{ .tz = mktz('M', 'E', 'W', 'T'), .offset = -60 },
    .{ .tz = mktz('N', 'Z', 'D', 'T'), .offset = -720 + DST },
    .{ .tz = mktz('N', 'Z', 'S', 'T'), .offset = -720 },
    .{ .tz = mktz('W', 'A', 'D', 'T'), .offset = -420 + DST },
    .{ .tz = mktz('W', 'A', 'S', 'T'), .offset = -420 },
};

inline fn lowercase(x: u8) u8 {
    return x | 0x20;
}

pub export fn checkday(check: [*]const u8, len: usize) callconv(.c) i32 {
    var day: i32 = -1;
    if (len < 3) return -1;

    switch (lowercase(check[1])) {
        'o' => {
            if (lowercase(check[0]) == 'm' and lowercase(check[2]) == 'n') {
                day = 0;
            }
        },
        'u' => {
            if (lowercase(check[0]) == 't' and lowercase(check[2]) == 'e') {
                day = 1;
            } else if (lowercase(check[0]) == 's' and lowercase(check[2]) == 'n') {
                day = 6;
            }
        },
        'e' => {
            if (lowercase(check[0]) == 'w' and lowercase(check[2]) == 'd') {
                day = 2;
            }
        },
        'h' => {
            if (lowercase(check[0]) == 't' and lowercase(check[2]) == 'u') {
                day = 3;
            }
        },
        'r' => {
            if (lowercase(check[0]) == 'f' and lowercase(check[2]) == 'i') {
                day = 4;
            }
        },
        'a' => {
            if (lowercase(check[0]) == 's' and lowercase(check[2]) == 't') {
                day = 5;
            }
        },
        else => {},
    }
    if (len > 3 and day != -1) {
        const daysuffix = [_][]const u8{
            "day", "sday", "nesday", "rsday", "day", "urday", "day",
        };
        const suffix = daysuffix[@intCast(day)];
        if ((len - 3) != suffix.len or !std.ascii.eqlIgnoreCase(check[3..len], suffix)) {
            return -1;
        }
    }
    return day;
}

pub export fn checkmonth(check: [*]const u8, len: usize) callconv(.c) i32 {
    if (len != 3) return -1;

    switch (lowercase(check[2])) {
        'n' => {
            if (lowercase(check[0]) == 'j') {
                const c2 = lowercase(check[1]);
                if (c2 == 'a') return 0;
                if (c2 == 'u') return 5;
            }
        },
        'b' => {
            if (lowercase(check[0]) == 'f' and lowercase(check[1]) == 'e') return 1;
        },
        'r' => {
            if (lowercase(check[0]) == 'm') {
                if (lowercase(check[1]) == 'a') return 2;
            } else if (lowercase(check[0]) == 'a' and lowercase(check[1]) == 'p') {
                return 3;
            }
        },
        'y' => {
            if (lowercase(check[0]) == 'm' and lowercase(check[1]) == 'a') return 4;
        },
        'l' => {
            if (lowercase(check[0]) == 'j' and lowercase(check[1]) == 'u') return 6;
        },
        'g' => {
            if (lowercase(check[0]) == 'a' and lowercase(check[1]) == 'u') return 7;
        },
        'p' => {
            if (lowercase(check[0]) == 's' and lowercase(check[1]) == 'e') return 8;
        },
        't' => {
            if (lowercase(check[0]) == 'o' and lowercase(check[1]) == 'c') return 9;
        },
        'v' => {
            if (lowercase(check[0]) == 'n' and lowercase(check[1]) == 'o') return 10;
        },
        'c' => {
            if (lowercase(check[0]) == 'd' and lowercase(check[1]) == 'e') return 11;
        },
        else => {},
    }
    return -1;
}

pub export fn checktz(check: [*]const u8, len: usize) callconv(.c) i32 {
    if (len == 0 or len > 4) return -1;
    const first = check[0];
    if (first < 'A') return -1;
    if (len == 1) {
        if (first > 'Z' or first == 'J') return -1;
        return @as(i32, tzone[first - 'A']) * 60;
    } else if (len == 2) {
        if (check[1] == 'T') {
            if (first == 'N') return 11 * 60 * 60;
            if (first == 'U') return 0;
        }
        return -1;
    } else if (len == 3) {
        if (first > 'Y') return -1;
        const key = mktz(first, check[1], check[2], 0);
        for (tzthree) |entry| {
            if (entry.tz == key) return @as(i32, entry.offset) * 60;
        }
    } else {
        if (first > 'W') return -1;
        const key = mktz(first, check[1], check[2], check[3]);
        for (tzfoura) |entry| {
            if (entry.tz == key) return @as(i32, entry.offset) * 60;
        }
    }
    return -1;
}

fn skipNonAlnum(date: *[*:0]const u8) void {
    while (date.*[0] != 0 and !isAlnum(date.*[0])) {
        date.* += 1;
    }
}

const When = struct {
    wday: i32 = -1,
    mon: i32 = -1,
    mday: i32 = -1,
    dsecs: i32 = -1,
    year: i32 = -1,
    tzoff: i32 = -1,
};

const LEAP_DAYS_BEFORE_1969: i64 = 477;
const SECONDS_PER_DAY: i64 = 86400;

fn time2epoch(w: *const When) i64 {
    const cumulative_days = [12]i64{
        0, 31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334,
    };
    const y: i64 = @as(i64, w.year) - @as(i64, @intFromBool(w.mon <= 1));
    const leap_days: i64 = @divTrunc(y, 4) - @divTrunc(y, 100) + @divTrunc(y, 400) - LEAP_DAYS_BEFORE_1969;
    const days: i64 = (@as(i64, w.year) - 1970) * 365 + leap_days +
        cumulative_days[@intCast(w.mon)] + @as(i64, w.mday) - 1;
    return (days * SECONDS_PER_DAY) + @as(i64, w.dsecs);
}

fn oneortwodigit(date: [*:0]const u8, endp: *[*:0]const u8) i32 {
    const num: i32 = @as(i32, date[0] - '0');
    if (isDigit(date[1])) {
        endp.* = date + 2;
        return (num * 10) + @as(i32, date[1] - '0');
    }
    endp.* = date + 1;
    return num;
}

fn matchTime(date: [*:0]const u8, w: *When, endp: *[*:0]const u8) bool {
    var p: [*:0]const u8 = date;
    var ss: i32 = 0;
    const hh = oneortwodigit(date, &p);
    if (hh < 24 and p[0] == ':' and isDigit(p[1])) {
        const mm = oneortwodigit(p + 1, &p);
        if (mm < 60) {
            if (p[0] == ':' and isDigit(p[1])) {
                ss = oneortwodigit(p + 1, &p);
                if (ss <= 60) {
                    w.dsecs = (hh * 3600) + (mm * 60) + ss;
                    endp.* = p;
                    return true;
                }
            } else {
                w.dsecs = (hh * 3600) + (mm * 60) + ss;
                endp.* = p;
                return true;
            }
        }
    }
    return false;
}

const NAME_LEN: usize = 10;

extern fn curlx_str_number(linep: *[*:0]const u8, nump: *i64, max: i64) callconv(.c) c_int;

fn datestring(datep: *[*:0]const u8, w: *When) c_int {
    var len: usize = 0;
    const p = datep.*;
    while (isAlpha(p[len]) and len < NAME_LEN) {
        len += 1;
    }

    if (len != NAME_LEN) {
        if (w.wday == -1) {
            w.wday = checkday(p, len);
            if (w.wday != -1) {
                datep.* += len;
                return PARSEDATE_OK;
            }
        }
        if (w.mon == -1) {
            w.mon = checkmonth(p, len);
            if (w.mon != -1) {
                datep.* += len;
                return PARSEDATE_OK;
            }
        }
        if (w.tzoff == -1) {
            w.tzoff = checktz(p, len);
            if (w.tzoff != -1) {
                datep.* += len;
                return PARSEDATE_OK;
            }
        }
    }
    return PARSEDATE_FAIL;
}

fn datenum(indate: [*:0]const u8, datep: *[*:0]const u8, w: *When) c_int {
    var date = datep.*;
    var end: [*:0]const u8 = date;

    if (w.dsecs == -1 and matchTime(date, w, &end)) {
        date = end;
    } else {
        var found = false;
        var lval: i64 = 0;
        var p: [*:0]const u8 = datep.*;
        if (curlx_str_number(&p, &lval, 99999999) != 0) {
            return PARSEDATE_FAIL;
        }
        const p_after = p;
        const num_digits: usize = @intFromPtr(p_after) - @intFromPtr(datep.*);
        const val: u32 = @intCast(lval);

        if (w.tzoff == -1 and
            num_digits == 4 and
            val <= 1400 and
            @intFromPtr(indate) < @intFromPtr(date))
        {
            const prev_ptr: [*]const u8 = @ptrFromInt(@intFromPtr(date) - 1);
            const prev = prev_ptr[0];
            if (prev == '+' or prev == '-') {
                found = true;
                const off: i32 = @intCast(((val / 100 * 60) + (val % 100)) * 60);
                w.tzoff = if (prev == '+') -off else off;
            }
        } else if (num_digits == 8 and w.year == -1 and w.mon == -1 and w.mday == -1) {
            found = true;
            w.year = @intCast(val / 10000);
            w.mon = @as(i32, @intCast((val % 10000) / 100)) - 1;
            if (w.mon > 11) {
                return PARSEDATE_FAIL;
            }
            w.mday = @intCast(val % 100);
        }

        if (!found and w.mday == -1) {
            if (val > 0 and val < 32) {
                w.mday = @intCast(val);
                found = true;
            }
        }

        if (!found and w.year == -1) {
            w.year = @intCast(val);
            found = true;
            if (w.year < 100) {
                if (w.year > 70) {
                    w.year += 1900;
                } else {
                    w.year += 2000;
                }
            }
        }

        if (!found) {
            return PARSEDATE_FAIL;
        }

        date = p_after;
    }
    datep.* = date;
    return PARSEDATE_OK;
}

fn datecheck(w: *When) bool {
    if (w.dsecs == -1) {
        w.dsecs = 0;
    }
    if (w.mday == -1 or w.mon == -1 or w.year == -1 or w.year < 1583 or w.mday > 31) {
        return true;
    }
    return false;
}

fn tzadjust(tp: *i64, w: *When) void {
    if (w.tzoff == -1) {
        w.tzoff = 0;
    }
    const tzoff64: i64 = w.tzoff;
    if (tzoff64 > 0 and tp.* > (curlx_parse.CURL_OFF_T_MAX - tzoff64)) {
        tp.* = curlx_parse.CURL_OFF_T_MAX;
    } else {
        tp.* += tzoff64;
    }
}

fn parsedate(date_in: [*:0]const u8, output: *time_t) c_int {
    var date = date_in;
    const indate = date_in;
    var part: usize = 0;
    var rc: c_int = 0;
    var w = When{};

    while (date[0] != 0 and part < 6) {
        skipNonAlnum(&date);
        if (isAlpha(date[0])) {
            rc = datestring(&date, &w);
        } else if (isDigit(date[0])) {
            rc = datenum(indate, &date, &w);
        }
        if (rc != 0) {
            return rc;
        }
        part += 1;
    }

    if (datecheck(&w)) {
        return PARSEDATE_FAIL;
    }

    var seconds = time2epoch(&w);
    tzadjust(&seconds, &w);
    output.* = seconds;
    return PARSEDATE_OK;
}

export fn curl_getdate(p: ?[*:0]const u8, unused: ?*const time_t) callconv(.c) time_t {
    _ = unused;
    const date_str = p orelse return -1;
    var parsed: time_t = -1;
    const rc = parsedate(date_str, &parsed);
    if (rc == PARSEDATE_OK) {
        if (parsed == -1) {
            parsed += 1;
        }
        return parsed;
    }
    return -1;
}

export fn Curl_getdate_capped(p: ?[*:0]const u8, tp: *time_t) callconv(.c) c_int {
    const date_str = p orelse return 1;
    const rc = parsedate(date_str, tp);
    return @intFromBool(rc == PARSEDATE_FAIL);
}

// ============================================================================
// lib/strerror.c
// ============================================================================

pub const CURLMcode = c_int;
pub const CURLSHcode = c_uint;
pub const CURLUcode = c_uint;

export fn curl_easy_strerror(err: CURLcode) callconv(.c) [*:0]const u8 {
    return switch (err) {
        0 => "No error",
        1 => "Unsupported protocol",
        2 => "Failed initialization",
        3 => "URL using bad/illegal format or missing URL",
        4 => "A requested feature, protocol or option was not found built-in in this libcurl due to a build-time decision.",
        5 => "Could not resolve proxy name",
        6 => "Could not resolve hostname",
        7 => "Could not connect to server",
        8 => "Weird server reply",
        9 => "Access denied to remote resource",
        10 => "FTP: The server failed to connect to data port",
        11 => "FTP: unknown PASS reply",
        12 => "FTP: Accepting server connect has timed out",
        13 => "FTP: unknown PASV reply",
        14 => "FTP: unknown 227 response format",
        15 => "FTP: cannot figure out the host in the PASV response",
        16 => "Error in the HTTP2 framing layer",
        17 => "FTP: could not set file type",
        18 => "Transferred a partial file",
        19 => "FTP: could not retrieve (RETR failed) the specified file",
        21 => "Quote command returned error",
        22 => "HTTP response code said error",
        23 => "Failed writing received data to disk/application",
        25 => "Upload failed (at start/before it took off)",
        26 => "Failed to open/read local data from file/application",
        27 => "Out of memory",
        28 => "Timeout was reached",
        30 => "FTP: command PORT failed",
        31 => "FTP: command REST failed",
        33 => "Requested range was not delivered by the server",
        35 => "SSL connect error",
        36 => "Could not resume download",
        37 => "Could not read a file:// file",
        38 => "LDAP: cannot bind",
        39 => "LDAP: search failed",
        42 => "Operation was aborted by an application callback",
        43 => "A libcurl function was given a bad argument",
        45 => "Failed binding local connection end",
        47 => "Number of redirects hit maximum amount",
        48 => "An unknown option was passed in to libcurl",
        49 => "Malformed option provided in a setopt",
        52 => "Server returned nothing (no headers, no data)",
        53 => "SSL crypto engine not found",
        54 => "Can not set SSL crypto engine as default",
        55 => "Failed sending data to the peer",
        56 => "Failure when receiving data from the peer",
        58 => "Problem with the local SSL certificate",
        59 => "Could not use specified SSL cipher",
        60 => "SSL peer certificate or SSH remote key was not OK",
        61 => "Unrecognized or bad HTTP Content or Transfer-Encoding",
        63 => "Maximum file size exceeded",
        64 => "Requested SSL level failed",
        65 => "Send failed since rewinding of the data stream failed",
        66 => "Failed to initialize SSL crypto engine",
        67 => "Login denied",
        68 => "TFTP: File Not Found",
        69 => "TFTP: Access Violation",
        70 => "Disk full or allocation exceeded",
        71 => "TFTP: Illegal operation",
        72 => "TFTP: Unknown transfer ID",
        73 => "Remote file already exists",
        74 => "TFTP: No such user",
        77 => "Problem with the SSL CA cert (path? access rights?)",
        78 => "Remote file not found",
        79 => "Error in the SSH layer",
        80 => "Failed to shut down the SSL connection",
        81 => "Socket not ready for send/recv",
        82 => "Failed to load CRL file (path? access rights?, format?)",
        83 => "Issuer check against peer certificate failed",
        84 => "FTP: The server did not accept the PRET command.",
        85 => "RTSP CSeq mismatch or invalid CSeq",
        86 => "RTSP session error",
        87 => "Unable to parse FTP file list",
        88 => "Chunk callback failed",
        89 => "The max connection limit is reached",
        90 => "SSL public key does not match pinned public key",
        91 => "SSL server certificate status verification FAILED",
        92 => "Stream error in the HTTP/2 framing layer",
        93 => "API function called from within callback",
        94 => "An authentication function returned an error",
        95 => "HTTP/3 error",
        96 => "QUIC connection error",
        97 => "proxy handshake error",
        98 => "SSL Client Certificate required",
        99 => "Unrecoverable error in select/poll",
        100 => "A value or data field grew larger than allowed",
        101 => "ECH attempted but failed",
        else => "Unknown error",
    };
}

export fn curl_multi_strerror(err: CURLMcode) callconv(.c) [*:0]const u8 {
    return switch (err) {
        -1 => "Please call curl_multi_perform() soon",
        0 => "No error",
        1 => "Invalid multi handle",
        2 => "Invalid easy handle",
        3 => "Out of memory",
        4 => "Internal error",
        5 => "Invalid socket argument",
        6 => "Unknown option",
        7 => "The easy handle is already added to a multi handle",
        8 => "API function called from within callback",
        9 => "Wakeup is unavailable or failed",
        10 => "A libcurl function was given a bad argument",
        11 => "Operation was aborted by an application callback",
        12 => "Unrecoverable error in select/poll",
        else => "Unknown error",
    };
}

export fn curl_share_strerror(err: CURLSHcode) callconv(.c) [*:0]const u8 {
    return switch (err) {
        0 => "No error",
        1 => "Unknown share option",
        2 => "Share currently in use",
        3 => "Invalid share handle",
        4 => "Out of memory",
        5 => "Feature not enabled in this library",
        else => "CURLSHcode unknown",
    };
}

export fn curl_url_strerror(err: CURLUcode) callconv(.c) [*:0]const u8 {
    return switch (err) {
        0 => "No error",
        1 => "An invalid CURLU pointer was passed as argument",
        2 => "An invalid 'part' argument was passed as argument",
        3 => "Malformed input to a URL function",
        4 => "Port number was not a decimal number between 0 and 65535",
        5 => "Unsupported URL scheme",
        6 => "URL decode error, most likely because of rubbish in the input",
        7 => "A memory function failed",
        8 => "Credentials was passed in the URL when prohibited",
        9 => "An unknown part ID was passed to a URL API function",
        10 => "No scheme present",
        11 => "No user present",
        12 => "No password present",
        13 => "No options present",
        14 => "No host present",
        15 => "No port number present",
        16 => "No query present",
        17 => "No fragment present",
        18 => "No zoneid present",
        19 => "Bad file:// URL",
        20 => "Bad fragment",
        21 => "Bad hostname",
        22 => "Bad IPv6 address",
        23 => "Bad login",
        24 => "Bad password",
        25 => "Bad path",
        26 => "Bad query",
        27 => "Bad scheme",
        28 => "Unsupported number of slashes following scheme",
        29 => "Bad user",
        30 => "libcurl lacks IDN support",
        31 => "A value or data field is larger than allowed",
        32 => "Found a backslash where a forward slash was expected",
        else => "CURLUcode unknown",
    };
}

const sspi_win = struct {
    extern "kernel32" fn GetLastError() callconv(.winapi) u32;
    extern "kernel32" fn SetLastError(dwErrCode: u32) callconv(.winapi) void;
    extern "c" fn _errno() callconv(.c) *c_int;
    extern fn curlx_get_winapi_error(err: u32, buf: [*]u8, buflen: usize) callconv(.c) ?[*:0]const u8;
};

fn sspiErrorText(code: u32) []const u8 {
    return switch (code) {
        0x00000000 => "No error",
        0x80092010 => "CRYPT_E_REVOKED",
        0x80092011 => "CRYPT_E_NO_REVOCATION_DLL",
        0x80092012 => "CRYPT_E_NO_REVOCATION_CHECK",
        0x80092013 => "CRYPT_E_REVOCATION_OFFLINE",
        0x80092014 => "CRYPT_E_NOT_IN_REVOCATION_DATABASE",
        0x80090331 => "SEC_E_ALGORITHM_MISMATCH",
        0x80090346 => "SEC_E_BAD_BINDINGS",
        0x80090316 => "SEC_E_BAD_PKGID",
        0x80090321 => "SEC_E_BUFFER_TOO_SMALL",
        0x80090307 => "SEC_E_CANNOT_INSTALL",
        0x80090309 => "SEC_E_CANNOT_PACK",
        0x80090328 => "SEC_E_CERT_EXPIRED",
        0x80090327 => "SEC_E_CERT_UNKNOWN",
        0x80090349 => "SEC_E_CERT_WRONG_USAGE",
        0x80090317 => "SEC_E_CONTEXT_EXPIRED",
        0x80090357 => "SEC_E_CROSSREALM_DELEGATION_FAILURE",
        0x80090337 => "SEC_E_CRYPTO_SYSTEM_INVALID",
        0x80090330 => "SEC_E_DECRYPT_FAILURE",
        0x8009035E => "SEC_E_DELEGATION_POLICY",
        0x80090345 => "SEC_E_DELEGATION_REQUIRED",
        0x80090350 => "SEC_E_DOWNGRADE_DETECTED",
        0x80090329 => "SEC_E_ENCRYPT_FAILURE",
        0x80090326 => "SEC_E_ILLEGAL_MESSAGE",
        0x80090320 => "SEC_E_INCOMPLETE_CREDENTIALS",
        0x80090318 => "SEC_E_INCOMPLETE_MESSAGE",
        0x80090300 => "SEC_E_INSUFFICIENT_MEMORY",
        0x80090304 => "SEC_E_INTERNAL_ERROR",
        0x80090301 => "SEC_E_INVALID_HANDLE",
        0x8009035D => "SEC_E_INVALID_PARAMETER",
        0x80090308 => "SEC_E_INVALID_TOKEN",
        0x80090352 => "SEC_E_ISSUING_CA_UNTRUSTED",
        0x80090359 => "SEC_E_ISSUING_CA_UNTRUSTED_KDC",
        0x8009035A => "SEC_E_KDC_CERT_EXPIRED",
        0x8009035B => "SEC_E_KDC_CERT_REVOKED",
        0x80090340 => "SEC_E_KDC_INVALID_REQUEST",
        0x80090341 => "SEC_E_KDC_UNABLE_TO_REFER",
        0x80090342 => "SEC_E_KDC_UNKNOWN_ETYPE",
        0x8009030C => "SEC_E_LOGON_DENIED",
        0x80090338 => "SEC_E_MAX_REFERRALS_EXCEEDED",
        0x8009030F => "SEC_E_MESSAGE_ALTERED",
        0x80090347 => "SEC_E_MULTIPLE_ACCOUNTS",
        0x80090339 => "SEC_E_MUST_BE_KDC",
        0x80090306 => "SEC_E_NOT_OWNER",
        0x80090311 => "SEC_E_NO_AUTHENTICATING_AUTHORITY",
        0x8009030E => "SEC_E_NO_CREDENTIALS",
        0x8009030B => "SEC_E_NO_IMPERSONATION",
        0x80090335 => "SEC_E_NO_IP_ADDRESSES",
        0x80090348 => "SEC_E_NO_KERB_KEY",
        0x8009033C => "SEC_E_NO_PA_DATA",
        0x80090356 => "SEC_E_NO_S4U_PROT_SUPPORT",
        0x80090334 => "SEC_E_NO_TGT_REPLY",
        0x80090310 => "SEC_E_OUT_OF_SEQUENCE",
        0x80090354 => "SEC_E_PKINIT_CLIENT_FAILURE",
        0x8009033D => "SEC_E_PKINIT_NAME_MISMATCH",
        0x8009035F => "SEC_E_POLICY_NLTM_ONLY",
        0x8009030A => "SEC_E_QOP_NOT_SUPPORTED",
        0x80090353 => "SEC_E_REVOCATION_OFFLINE_C",
        0x80090358 => "SEC_E_REVOCATION_OFFLINE_KDC",
        0x80090305 => "SEC_E_SECPKG_NOT_FOUND",
        0x80090332 => "SEC_E_SECURITY_QOS_FAILED",
        0x8009033F => "SEC_E_SHUTDOWN_IN_PROGRESS",
        0x80090355 => "SEC_E_SMARTCARD_CERT_EXPIRED",
        0x80090351 => "SEC_E_SMARTCARD_CERT_REVOKED",
        0x8009033E => "SEC_E_SMARTCARD_LOGON_REQUIRED",
        0x8009033A => "SEC_E_STRONG_CRYPTO_NOT_SUPPORTED",
        0x80090303 => "SEC_E_TARGET_UNKNOWN",
        0x80090324 => "SEC_E_TIME_SKEW",
        0x8009033B => "SEC_E_TOO_MANY_PRINCIPALS",
        0x80090333 => "SEC_E_UNFINISHED_CONTEXT_DELETED",
        0x8009030D => "SEC_E_UNKNOWN_CREDENTIALS",
        0x80090302 => "SEC_E_UNSUPPORTED_FUNCTION",
        0x80090343 => "SEC_E_UNSUPPORTED_PREAUTH",
        0x80090325 => "SEC_E_UNTRUSTED_ROOT",
        0x80090336 => "SEC_E_WRONG_CREDENTIAL_HANDLE",
        0x80090322 => "SEC_E_WRONG_PRINCIPAL",
        0x00090314 => "SEC_I_COMPLETE_AND_CONTINUE",
        0x00090313 => "SEC_I_COMPLETE_NEEDED",
        0x00090317 => "SEC_I_CONTEXT_EXPIRED",
        0x00090312 => "SEC_I_CONTINUE_NEEDED",
        0x00090320 => "SEC_I_INCOMPLETE_CREDENTIALS",
        0x00090315 => "SEC_I_LOCAL_LOGON",
        0x00090323 => "SEC_I_NO_LSA_CONTEXT",
        0x00090321 => "SEC_I_RENEGOTIATE",
        0x0009035C => "SEC_I_SIGNATURE_NEEDED",
        else => "Unknown error",
    };
}

fn curlSspiStrerrorImpl(err: c_long, buf: ?[*]u8, buflen: usize) callconv(.c) ?[*:0]const u8 {
    const old_win_err = sspi_win.GetLastError();
    const old_errno = sspi_win._errno().*;

    const out = buf orelse return null;
    if (buflen == 0) return null;
    out[0] = 0;

    const uerr: u32 = @bitCast(@as(i32, @intCast(err)));
    const txt = sspiErrorText(uerr);

    var scratch: [512]u8 = undefined;
    const formatted: []const u8 = if (uerr == 0x80090326)
        std.fmt.bufPrint(
            &scratch,
            "SEC_E_ILLEGAL_MESSAGE (0x{x:0>8}) - This error usually occurs when a fatal SSL/TLS alert is received (e.g. handshake failed). More detail may be available in the Windows System event log.",
            .{uerr},
        ) catch ""
    else blk: {
        var msgbuf: [256]u8 = undefined;
        const win_msg = if (builtin.output_mode == .Lib)
            sspi_win.curlx_get_winapi_error(uerr, &msgbuf, msgbuf.len)
        else
            null;
        if (win_msg) |m| {
            break :blk std.fmt.bufPrint(&scratch, "{s} (0x{x:0>8}) - {s}", .{ txt, uerr, std.mem.span(m) }) catch "";
        } else {
            break :blk std.fmt.bufPrint(&scratch, "{s} (0x{x:0>8})", .{ txt, uerr }) catch "";
        }
    };

    const copy_len = @min(formatted.len, buflen - 1);
    @memcpy(out[0..copy_len], formatted[0..copy_len]);
    out[copy_len] = 0;

    if (sspi_win._errno().* != old_errno) {
        sspi_win._errno().* = old_errno;
    }
    if (old_win_err != sspi_win.GetLastError()) {
        sspi_win.SetLastError(old_win_err);
    }

    return @ptrCast(out);
}

comptime {
    if (builtin.os.tag == .windows) {
        @export(&curlSspiStrerrorImpl, .{ .name = "Curl_sspi_strerror" });
    }
}

// ============================================================================
// Unit Tests
// ============================================================================

test "curl_easy_escape, curl_easy_unescape, and Curl_urldecode" {
    const escaped = curl_easy_escape(null, "hello world! ~-._09azAZ/:", 0) orelse return error.OutOfMemory;
    defer curl_free(escaped);
    try std.testing.expectEqualStrings("hello%20world%21%20~-._09azAZ%2F%3A", std.mem.span(escaped));

    var out_len: c_int = 0;
    const unescaped = curl_easy_unescape(null, escaped, 0, &out_len) orelse return error.OutOfMemory;
    defer curl_free(unescaped);
    try std.testing.expectEqual(@as(c_int, 25), out_len);
    try std.testing.expectEqualStrings("hello world! ~-._09azAZ/:", std.mem.span(unescaped));

    // Embedded NUL byte handling
    const raw_with_nul = "ab\x00cd";
    const esc_nul = curl_easy_escape(null, raw_with_nul.ptr, 5) orelse return error.OutOfMemory;
    defer curl_free(esc_nul);
    try std.testing.expectEqualStrings("ab%00cd", std.mem.span(esc_nul));

    var unesc_nul_len: c_int = 0;
    const unesc_nul = curl_easy_unescape(null, esc_nul, 0, &unesc_nul_len) orelse return error.OutOfMemory;
    defer curl_free(unesc_nul);
    try std.testing.expectEqual(@as(c_int, 5), unesc_nul_len);
    try std.testing.expectEqualSlices(u8, raw_with_nul, @as([*]const u8, unesc_nul)[0..5]);

    // Curl_urldecode REJECT_ZERO and REJECT_CTRL
    var dec: ?[*:0]u8 = null;
    var dec_len: usize = 0;
    try std.testing.expectEqual(CURLE_URL_MALFORMAT, Curl_urldecode("ab%00cd", 0, &dec, &dec_len, REJECT_ZERO));
    try std.testing.expectEqual(CURLE_URL_MALFORMAT, Curl_urldecode("ab%1fcd", 0, &dec, &dec_len, REJECT_CTRL));
    try std.testing.expectEqual(CURLE_OK, Curl_urldecode("ab%20cd%ZZ%", 0, &dec, &dec_len, REJECT_CTRL));
    defer curl_free(dec);
    try std.testing.expectEqual(@as(usize, 9), dec_len);
    try std.testing.expectEqualStrings("ab cd%ZZ%", std.mem.span(dec.?));

    // Curl_hexencode & Curl_hexbyte
    var hex_buf: [7]u8 = undefined;
    Curl_hexencode("XYZ", 3, &hex_buf, hex_buf.len);
    try std.testing.expectEqualStrings("58595a", std.mem.sliceTo(&hex_buf, 0));

    var byte_hex: [2]u8 = undefined;
    Curl_hexbyte(&byte_hex, 0xab);
    try std.testing.expectEqualSlices(u8, "AB", &byte_hex);
}

test "Curl_fnmatch wildcards, ranges, and POSIX classes" {
    try std.testing.expectEqual(CURL_FNMATCH_FAIL, Curl_fnmatch(null, null, "abc"));
    try std.testing.expectEqual(CURL_FNMATCH_FAIL, Curl_fnmatch(null, "abc", null));

    try std.testing.expectEqual(CURL_FNMATCH_MATCH, Curl_fnmatch(null, "*.txt", "readme.txt"));
    try std.testing.expectEqual(CURL_FNMATCH_NOMATCH, Curl_fnmatch(null, "*.txt", "readme.md"));
    try std.testing.expectEqual(CURL_FNMATCH_MATCH, Curl_fnmatch(null, "f??e.*", "file.c"));
    try std.testing.expectEqual(CURL_FNMATCH_MATCH, Curl_fnmatch(null, "[a-z][0-9][A-Z]", "m7Q"));
    try std.testing.expectEqual(CURL_FNMATCH_NOMATCH, Curl_fnmatch(null, "[a-z][0-9][A-Z]", "M7Q"));
    try std.testing.expectEqual(CURL_FNMATCH_MATCH, Curl_fnmatch(null, "[^0-9][!a-z]", "A5"));
    try std.testing.expectEqual(CURL_FNMATCH_NOMATCH, Curl_fnmatch(null, "[^0-9]", "5"));
    try std.testing.expectEqual(CURL_FNMATCH_MATCH, Curl_fnmatch(null, "[[:alpha:]][[:digit:]][[:xdigit:]]", "z9f"));
    try std.testing.expectEqual(CURL_FNMATCH_MATCH, Curl_fnmatch(null, "[[:upper:]][[:lower:]][[:space:]]", "Qa "));
    try std.testing.expectEqual(CURL_FNMATCH_MATCH, Curl_fnmatch(null, "[]a]", "]"));
    try std.testing.expectEqual(CURL_FNMATCH_MATCH, Curl_fnmatch(null, "\\*\\?", "*?"));
    try std.testing.expectEqual(CURL_FNMATCH_NOMATCH, Curl_fnmatch(null, "\\*\\?", "ab"));
}

test "curl_getdate RFC 822, RFC 850, asctime, compact, timezones, and leap years" {
    // Sun, 06 Nov 1994 08:49:37 GMT -> 784111777
    try std.testing.expectEqual(@as(time_t, 784111777), curl_getdate("Sun, 06 Nov 1994 08:49:37 GMT", null));
    try std.testing.expectEqual(@as(time_t, 784111777), curl_getdate("Sunday, 06-Nov-94 08:49:37 GMT", null));
    try std.testing.expectEqual(@as(time_t, 784111777), curl_getdate("Sun Nov  6 08:49:37 1994", null));

    // Epoch 1970-01-01 00:00:00 GMT -> 0
    try std.testing.expectEqual(@as(time_t, 0), curl_getdate("Thu, 01 Jan 1970 00:00:00 GMT", null));

    // Timezone offset: +0200 and CET (-60 min offset -> subtract 3600s)
    try std.testing.expectEqual(@as(time_t, 784111777 - 3600), curl_getdate("Sun, 06 Nov 1994 08:49:37 CET", null));
    try std.testing.expectEqual(@as(time_t, 784111777 - 7200), curl_getdate("Sun, 06 Nov 1994 08:49:37 +0200", null));

    // Compact YYYYMMDD
    try std.testing.expectEqual(@as(time_t, 0), curl_getdate("19700101 00:00:00 GMT", null));

    // Leap year: 2000-02-29 00:00:00 GMT -> 951782400
    try std.testing.expectEqual(@as(time_t, 951782400), curl_getdate("Tue, 29 Feb 2000 00:00:00 GMT", null));

    // Invalid date
    try std.testing.expectEqual(@as(time_t, -1), curl_getdate("not a valid date", null));
    try std.testing.expectEqual(@as(time_t, -1), curl_getdate(null, null));

    var capped: time_t = 0;
    try std.testing.expectEqual(@as(c_int, 0), Curl_getdate_capped("Sun, 06 Nov 1994 08:49:37 GMT", &capped));
    try std.testing.expectEqual(@as(time_t, 784111777), capped);
}

test "curl_*_strerror lookups" {
    try std.testing.expectEqualStrings("No error", std.mem.span(curl_easy_strerror(0)));
    try std.testing.expectEqualStrings("Out of memory", std.mem.span(curl_easy_strerror(27)));
    try std.testing.expectEqualStrings("Unknown error", std.mem.span(curl_easy_strerror(9999)));

    try std.testing.expectEqualStrings("No error", std.mem.span(curl_multi_strerror(0)));
    try std.testing.expectEqualStrings("Please call curl_multi_perform() soon", std.mem.span(curl_multi_strerror(-1)));
    try std.testing.expectEqualStrings("Unknown error", std.mem.span(curl_multi_strerror(999)));

    try std.testing.expectEqualStrings("No error", std.mem.span(curl_share_strerror(0)));
    try std.testing.expectEqualStrings("CURLSHcode unknown", std.mem.span(curl_share_strerror(999)));

    try std.testing.expectEqualStrings("No error", std.mem.span(curl_url_strerror(0)));
    try std.testing.expectEqualStrings("CURLUcode unknown", std.mem.span(curl_url_strerror(999)));
}
