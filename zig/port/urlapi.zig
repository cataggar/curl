const std = @import("std");
const builtin = @import("builtin");
const mem = @import("mem.zig");
const primitives = @import("primitives.zig");
const curlx_parse = @import("curlx_parse.zig");
const curlx_time_net = @import("curlx_time_net.zig");

pub const CURLUcode = enum(c_uint) {
    CURLUE_OK = 0,
    CURLUE_BAD_HANDLE, // 1
    CURLUE_BAD_PARTPOINTER, // 2
    CURLUE_MALFORMED_INPUT, // 3
    CURLUE_BAD_PORT_NUMBER, // 4
    CURLUE_UNSUPPORTED_SCHEME, // 5
    CURLUE_URLDECODE, // 6
    CURLUE_OUT_OF_MEMORY, // 7
    CURLUE_USER_NOT_ALLOWED, // 8
    CURLUE_UNKNOWN_PART, // 9
    CURLUE_NO_SCHEME, // 10
    CURLUE_NO_USER, // 11
    CURLUE_NO_PASSWORD, // 12
    CURLUE_NO_OPTIONS, // 13
    CURLUE_NO_HOST, // 14
    CURLUE_NO_PORT, // 15
    CURLUE_NO_QUERY, // 16
    CURLUE_NO_FRAGMENT, // 17
    CURLUE_NO_ZONEID, // 18
    CURLUE_BAD_FILE_URL, // 19
    CURLUE_BAD_FRAGMENT, // 20
    CURLUE_BAD_HOSTNAME, // 21
    CURLUE_BAD_IPV6, // 22
    CURLUE_BAD_LOGIN, // 23
    CURLUE_BAD_PASSWORD, // 24
    CURLUE_BAD_PATH, // 25
    CURLUE_BAD_QUERY, // 26
    CURLUE_BAD_SCHEME, // 27
    CURLUE_BAD_SLASHES, // 28
    CURLUE_BAD_USER, // 29
    CURLUE_LACKS_IDN, // 30
    CURLUE_TOO_LARGE, // 31
    CURLUE_BACKSLASH, // 32
    CURLUE_LAST,
};

pub const CURLUPart = enum(c_uint) {
    CURLUPART_URL = 0,
    CURLUPART_SCHEME,
    CURLUPART_USER,
    CURLUPART_PASSWORD,
    CURLUPART_OPTIONS,
    CURLUPART_HOST,
    CURLUPART_PORT,
    CURLUPART_PATH,
    CURLUPART_QUERY,
    CURLUPART_FRAGMENT,
    CURLUPART_ZONEID,
    _,
};

pub const CURLU_DEFAULT_PORT: c_uint = 1 << 0;
pub const CURLU_NO_DEFAULT_PORT: c_uint = 1 << 1;
pub const CURLU_DEFAULT_SCHEME: c_uint = 1 << 2;
pub const CURLU_NON_SUPPORT_SCHEME: c_uint = 1 << 3;
pub const CURLU_PATH_AS_IS: c_uint = 1 << 4;
pub const CURLU_DISALLOW_USER: c_uint = 1 << 5;
pub const CURLU_URLDECODE: c_uint = 1 << 6;
pub const CURLU_URLENCODE: c_uint = 1 << 7;
pub const CURLU_APPENDQUERY: c_uint = 1 << 8;
pub const CURLU_GUESS_SCHEME: c_uint = 1 << 9;
pub const CURLU_NO_AUTHORITY: c_uint = 1 << 10;
pub const CURLU_ALLOW_SPACE: c_uint = 1 << 11;
pub const CURLU_PUNYCODE: c_uint = 1 << 12;
pub const CURLU_PUNY2IDN: c_uint = 1 << 13;
pub const CURLU_GET_EMPTY: c_uint = 1 << 14;
pub const CURLU_NO_GUESS_SCHEME: c_uint = 1 << 15;

const DEFAULT_SCHEME: [*:0]const u8 = "https";
const MAX_SCHEME_LEN: usize = 40;
const MAX_ZONEID_LEN: usize = 16;
const CURL_MAX_INPUT_LENGTH: usize = 8000000;

const PROTOPT_URLOPTIONS: u32 = 1 << 10;
const REJECT_CTRL: c_uint = 3;

const CURLE_OK: c_uint = 0;
const CURLE_OUT_OF_MEMORY: c_uint = 27;
const CURLE_TOO_LARGE: c_uint = 100;

pub const HOST_ERROR: c_int = -1;
pub const HOST_NAME: c_int = 1;
pub const HOST_IPV4: c_int = 2;
pub const HOST_IPV6: c_int = 3;

pub const QUERY_NO: c_uint = 2;
pub const QUERY_NOT_YET: c_uint = 3;
pub const QUERY_YES: c_uint = 4;

pub const Curl_URL = extern struct {
    scheme: ?[*:0]u8 = null,
    user: ?[*:0]u8 = null,
    password: ?[*:0]u8 = null,
    options: ?[*:0]u8 = null,
    host: ?[*:0]u8 = null,
    zoneid: ?[*:0]u8 = null,
    path: ?[*:0]u8 = null,
    query: ?[*:0]u8 = null,
    fragment: ?[*:0]u8 = null,
    portnum: u16 = 0,
    port_present: bool = false,
    query_present: bool = false,
    fragment_present: bool = false,
    guessed_scheme: bool = false,
};

pub const Dynbuf = extern struct {
    bufr: ?[*]u8,
    leng: usize,
    allc: usize,
    toobig: usize,
};

const Curl_scheme = extern struct {
    name: [*:0]const u8,
    run: ?*const anyopaque,
    protocol: i64,
    family: i64,
    flags: u32,
    defport: u16,
};

// External C functions from libcurl
extern fn curlx_dyn_init(s: *Dynbuf, toobig: usize) callconv(.c) void;
extern fn curlx_dyn_free(s: *Dynbuf) callconv(.c) void;
extern fn curlx_dyn_reset(s: *Dynbuf) callconv(.c) void;
extern fn curlx_dyn_addn(s: *Dynbuf, mem_ptr: ?*const anyopaque, len: usize) callconv(.c) c_uint;
extern fn curlx_dyn_add(s: *Dynbuf, str: [*:0]const u8) callconv(.c) c_uint;
extern fn curlx_dyn_addf(s: *Dynbuf, fmt: [*:0]const u8, ...) callconv(.c) c_uint;
extern fn curlx_dyn_setlen(s: *Dynbuf, set: usize) callconv(.c) c_uint;
extern fn curlx_dyn_ptr(s: *const Dynbuf) callconv(.c) ?[*:0]u8;
extern fn curlx_dyn_len(s: *const Dynbuf) callconv(.c) usize;

extern fn Curl_get_scheme(scheme: [*:0]const u8) callconv(.c) ?*const Curl_scheme;
extern fn Curl_getn_scheme(scheme: [*]const u8, len: usize) callconv(.c) ?*const Curl_scheme;
extern fn Curl_parse_login_details(
    login: [*]const u8,
    len: usize,
    userp: *?[*:0]u8,
    passwdp: *?[*:0]u8,
    optionsp: ?*?[*:0]u8,
) callconv(.c) c_uint;
extern fn Curl_urldecode(
    string: [*]const u8,
    length: usize,
    ostring: *?[*:0]u8,
    olen: ?*usize,
    ctrl: c_uint,
) callconv(.c) c_uint;
extern fn Curl_hexbyte(dest: [*]u8, val: u8) callconv(.c) void;
extern fn curl_easy_escape(curl: ?*anyopaque, string: [*:0]const u8, length: c_int) callconv(.c) ?[*:0]u8;
extern fn Curl_is_ASCII_name(hostname: ?[*:0]const u8) callconv(.c) bool;
extern fn curl_maprintf(format: [*:0]const u8, ...) callconv(.c) ?[*:0]u8;
extern fn curl_msnprintf(buffer: [*]u8, maxlength: usize, format: [*:0]const u8, ...) callconv(.c) c_int;
extern fn curlx_strzero(buf: ?[*:0]u8) callconv(.c) void;
extern fn curlx_memdup0(src: ?[*]const u8, length: usize) callconv(.c) ?[*:0]u8;
extern fn curlx_str_number(linep: *[*:0]const u8, nump: *i64, max: i64) callconv(.c) c_int;
extern fn curlx_str_hex(linep: *[*:0]const u8, nump: *i64, max: i64) callconv(.c) c_int;
extern fn curlx_str_octal(linep: *[*:0]const u8, nump: *i64, max: i64) callconv(.c) c_int;

inline fn isAlpha(c: u8) bool {
    return (c >= 'a' and c <= 'z') or (c >= 'A' and c <= 'Z');
}

inline fn isDigit(c: u8) bool {
    return c >= '0' and c <= '9';
}

inline fn isAlnum(c: u8) bool {
    return isAlpha(c) or isDigit(c);
}

inline fn isXdigit(c: u8) bool {
    return isDigit(c) or (c >= 'a' and c <= 'f') or (c >= 'A' and c <= 'F');
}

inline fn isLower(c: u8) bool {
    return c >= 'a' and c <= 'z';
}

inline fn isSchemeChar(c: u8) bool {
    return isAlnum(c) or c == '+' or c == '-' or c == '.';
}

inline fn isUnreserved(c: u8) bool {
    return isAlnum(c) or c == '-' or c == '.' or c == '_' or c == '~';
}

inline fn isIpv6Char(c: u8) bool {
    return isXdigit(c) or c == ':' or c == '.';
}

inline fn startsWithDrivePrefix(str: [*]const u8) bool {
    return isAlpha(str[0]) and str[1] == ':';
}

inline fn startsWithUrlDrivePrefix(str: [*]const u8) bool {
    return isAlpha(str[0]) and (str[1] == ':' or str[1] == '|') and
        (str[2] == '/' or str[2] == '\\' or str[2] == 0);
}

inline fn cc2cu(x: c_uint) CURLUcode {
    return if (x == CURLE_TOO_LARGE) .CURLUE_TOO_LARGE else .CURLUE_OUT_OF_MEMORY;
}

fn cStrLen(s: [*:0]const u8) usize {
    return std.mem.span(s).len;
}

fn cStrChr(s: [*:0]const u8, ch: u8) ?[*:0]const u8 {
    var p = s;
    while (p[0] != 0) : (p += 1) {
        if (p[0] == ch) return p;
    }
    return null;
}

fn cMemChr(buf: [*]const u8, ch: u8, len: usize) ?[*]const u8 {
    var i: usize = 0;
    while (i < len) : (i += 1) {
        if (buf[i] == ch) return buf + i;
    }
    return null;
}

fn checkPrefix(comptime prefix: [:0]const u8, str: [*:0]const u8) bool {
    return primitives.curl_strnequal(prefix.ptr, str, prefix.len) != 0;
}

fn free_urlhandle(u: *Curl_URL) void {
    mem.free(u.scheme);
    mem.free(u.user);
    if (u.password) |pw| {
        curlx_strzero(pw);
        mem.free(pw);
    }
    mem.free(u.options);
    mem.free(u.host);
    mem.free(u.zoneid);
    mem.free(u.path);
    mem.free(u.query);
    mem.free(u.fragment);
}

// Find the separator at the end of the hostname, or the '?' in cases like
// http://www.example.com?id=2380
fn find_host_sep(url: [*]const u8, len: usize) [*]const u8 {
    var sep_idx: usize = 0;
    var i: usize = 0;
    while (i + 1 < len and url[i] != 0) : (i += 1) {
        if (url[i] == '/' and url[i + 1] == '/') {
            sep_idx = i + 2;
            break;
        }
    }
    while (sep_idx < len and url[sep_idx] != 0 and url[sep_idx] != '/' and url[sep_idx] != '?') : (sep_idx += 1) {}
    return url + sep_idx;
}

// urlencode_str() writes data into an output dynbuf and URL-encodes the
// spaces in the source URL accordingly.
pub fn urlencode_str(
    o: *Dynbuf,
    url: [*]const u8,
    len_in: usize,
    relative: bool,
    query_in: c_uint,
) CURLUcode {
    var len = len_in;
    var query = query_in;
    var host_sep: [*]const u8 = url;
    var result: c_uint = CURLE_OK;

    if (!relative) {
        host_sep = find_host_sep(url, len);
        const n: usize = @intFromPtr(host_sep) - @intFromPtr(url);
        result = curlx_dyn_addn(o, url, n);
        len -= n;
    }

    var iptr: [*]const u8 = host_sep;
    while (len != 0 and result == CURLE_OK) {
        if (iptr[0] == ' ') {
            if (query != QUERY_YES) {
                result = curlx_dyn_addn(o, "%20", 3);
            } else {
                result = curlx_dyn_addn(o, "+", 1);
            }
            iptr += 1;
            len -= 1;
        } else if (iptr[0] < ' ' or iptr[0] >= 0x7f) {
            var out: [3]u8 = .{ '%', 0, 0 };
            Curl_hexbyte(out[1..].ptr, iptr[0]);
            result = curlx_dyn_addn(o, &out, 3);
            iptr += 1;
            len -= 1;
        } else if (iptr[0] == '%' and len >= 3 and
            isXdigit(iptr[1]) and isXdigit(iptr[2]) and
            (isLower(iptr[1]) or isLower(iptr[2])))
        {
            var out: [3]u8 = .{ '%', primitives.rawToupper(iptr[1]), primitives.rawToupper(iptr[2]) };
            result = curlx_dyn_addn(o, &out, 3);
            iptr += 3;
            len -= 3;
        } else {
            const start = iptr;
            while (len != 0) {
                if (iptr[0] == ' ' or iptr[0] < ' ' or iptr[0] >= 0x7f)
                    break;
                if (iptr[0] == '%' and len >= 3 and
                    isXdigit(iptr[1]) and isXdigit(iptr[2]) and
                    (isLower(iptr[1]) or isLower(iptr[2])))
                    break;
                if (iptr[0] == '?') {
                    if (query == QUERY_NOT_YET) {
                        iptr += 1;
                        len -= 1;
                        query = QUERY_YES;
                        break;
                    }
                }
                iptr += 1;
                len -= 1;
            }
            result = curlx_dyn_addn(o, start, @intFromPtr(iptr) - @intFromPtr(start));
        }
    }

    if (result != CURLE_OK)
        return cc2cu(result);
    return .CURLUE_OK;
}

// Returns the length of the scheme if the given URL is absolute (as opposed
// to relative). Stores the scheme in the buffer if TRUE and 'buf' is
// non-NULL. The buflen must be larger than MAX_SCHEME_LEN if buf is set.
pub export fn Curl_is_absolute_url(
    url: [*:0]const u8,
    buf: ?[*]u8,
    buflen: usize,
    do_guess_scheme: bool,
) callconv(.c) usize {
    if (buf) |b| {
        if (buflen == 0) return 0;
        b[0] = 0;
    }
    if (builtin.os.tag == .windows) {
        if (do_guess_scheme and startsWithDrivePrefix(url))
            return 0;
    }
    const max_len: usize = if (buf != null) @min(MAX_SCHEME_LEN, buflen -| 1) else MAX_SCHEME_LEN;
    var i: usize = 0;
    if (max_len > 0 and isAlpha(url[0])) {
        if (buf) |b| {
            b[0] = primitives.rawTolower(url[0]);
        }
        i = 1;
        while (i < max_len) : (i += 1) {
            const s = url[i];
            if (s != 0 and isSchemeChar(s)) {
                if (buf) |b| {
                    b[i] = primitives.rawTolower(s);
                }
            } else {
                break;
            }
        }
    }
    if (i != 0 and url[i] == ':' and (url[i + 1] == '/' or !do_guess_scheme)) {
        if (buf) |b| {
            b[i] = 0;
        }
        return i;
    }
    if (buf) |b| {
        b[0] = 0;
    }
    return 0;
}

// Scan for byte values <= 31, 127 and maybe space
fn badoctets(input: [*]const u8, n_in: usize, flags: c_uint) bool {
    var p = input;
    var n = n_in;
    const control: u8 = if ((flags & CURLU_ALLOW_SPACE) != 0) 0x1f else 0x20;
    while (n != 0) : (n -= 1) {
        if (p[0] <= control or p[0] == 127)
            return true;
        p += 1;
    }
    return false;
}

fn clearLoginOut(
    u: *Curl_URL,
    userp: ?[*:0]u8,
    passwdp: ?[*:0]u8,
    optionsp: ?[*:0]u8,
    ures: CURLUcode,
) CURLUcode {
    mem.free(userp);
    if (passwdp) |pp| {
        curlx_strzero(pp);
        mem.free(pp);
    }
    mem.free(optionsp);
    mem.free(u.user);
    u.user = null;
    if (u.password) |pw| {
        curlx_strzero(pw);
        mem.free(pw);
        u.password = null;
    }
    mem.free(u.options);
    u.options = null;
    return ures;
}

// Parse the login details (username, password and options) from the URL and
// strip them out of the hostname.
pub fn parse_hostname_login(
    u: *Curl_URL,
    login: [*]const u8,
    len: usize,
    flags: c_uint,
    hostname_offset: *usize,
) CURLUcode {
    var ures: CURLUcode = .CURLUE_OK;
    var userp: ?[*:0]u8 = null;
    var passwdp: ?[*:0]u8 = null;
    var optionsp: ?[*:0]u8 = null;
    var h: ?*const Curl_scheme = null;

    hostname_offset.* = 0;
    const at_ptr = cMemChr(login, '@', len) orelse return clearLoginOut(u, userp, passwdp, optionsp, ures);
    const ptr = at_ptr + 1;

    if (u.scheme) |sc| {
        h = Curl_get_scheme(sc);
    }

    const parse_opts = if (h) |scheme_h| (scheme_h.flags & PROTOPT_URLOPTIONS) != 0 else false;
    const result = Curl_parse_login_details(
        login,
        (@intFromPtr(ptr) - @intFromPtr(login)) - 1,
        &userp,
        &passwdp,
        if (parse_opts) &optionsp else null,
    );
    if (result != CURLE_OK) {
        ures = .CURLUE_OUT_OF_MEMORY;
        return clearLoginOut(u, userp, passwdp, optionsp, ures);
    }

    if (userp) |up| {
        if ((flags & CURLU_DISALLOW_USER) != 0) {
            ures = .CURLUE_USER_NOT_ALLOWED;
            return clearLoginOut(u, userp, passwdp, optionsp, ures);
        }
        mem.free(u.user);
        u.user = up;
    }

    if (passwdp) |pp| {
        if (u.password) |old_pw| {
            curlx_strzero(old_pw);
            mem.free(old_pw);
        }
        u.password = pp;
    }

    if (optionsp) |op| {
        mem.free(u.options);
        u.options = op;
    }

    if (userp) |up| {
        if (badoctets(up, cStrLen(up), flags))
            ures = .CURLUE_BAD_USER;
    }
    if (ures == .CURLUE_OK) {
        if (passwdp) |pp| {
            if (badoctets(pp, cStrLen(pp), flags))
                ures = .CURLUE_BAD_PASSWORD;
        }
    }
    if (ures == .CURLUE_OK) {
        if (optionsp) |op| {
            if (badoctets(op, cStrLen(op), flags))
                ures = .CURLUE_MALFORMED_INPUT;
        }
    }

    userp = null;
    passwdp = null;
    optionsp = null;

    if (ures == .CURLUE_OK) {
        hostname_offset.* = @intFromPtr(ptr) - @intFromPtr(login);
        return .CURLUE_OK;
    }

    return clearLoginOut(u, userp, passwdp, optionsp, ures);
}

pub fn parse_port(u: *Curl_URL, host: *Dynbuf, has_scheme: bool) CURLUcode {
    const hostname = curlx_dyn_ptr(host) orelse return .CURLUE_OK;
    const hlen = curlx_dyn_len(host);
    var portptr: ?[*]const u8 = null;

    u.portnum = 0;
    u.port_present = false;
    if (hostname[0] == '[') {
        if (hlen < 1) return .CURLUE_BAD_IPV6;
        const close_bracket = cMemChr(@as([*]const u8, hostname) + 1, ']', hlen - 1) orelse return .CURLUE_BAD_IPV6;
        const after_bracket = close_bracket + 1;
        if (after_bracket[0] != 0) {
            if (after_bracket[0] != ':')
                return .CURLUE_BAD_PORT_NUMBER;
            portptr = after_bracket;
        } else {
            portptr = null;
        }
    } else {
        portptr = cMemChr(hostname, ':', hlen);
    }

    if (portptr) |pp| {
        var port: i64 = 0;
        const keep: usize = @intFromPtr(pp) - @intFromPtr(hostname);

        _ = curlx_dyn_setlen(host, keep);
        var p: [*:0]const u8 = @ptrCast(pp + 1);
        if (p[0] == 0)
            return if (has_scheme) .CURLUE_OK else .CURLUE_BAD_PORT_NUMBER;
        if (p[0] == '\\')
            return .CURLUE_BACKSLASH;
        const rc = curlx_str_number(&p, &port, 0xffff);
        if (rc != 0)
            return .CURLUE_BAD_PORT_NUMBER;
        if (p[0] == '\\')
            return .CURLUE_BACKSLASH;
        if (p[0] != 0)
            return .CURLUE_BAD_PORT_NUMBER;

        u.portnum = @intCast(port);
        u.port_present = true;
    }

    return .CURLUE_OK;
}

// Characters not allowed in hostnames:
// " \r\n\t/:#?!@{}[]\\$\'\"^`*<>=;,+&()%|"
// Bytes 0x80..0xFF are false (allowed for UTF-8 / IDN).
const invalid_host_char: [256]bool = blk: {
    var table: [256]bool = @splat(false);
    const low128 = [128]bool{
        // 0x00-0x0F
        true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  true,
        // 0x10-0x1F
        true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  true,
        // 0x20-0x2F
        true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  true,  false, false, true,
        // 0x30-0x3F
        false, false, false, false, false, false, false, false, false, false, true,  true,  true,  true,  true,  true,
        // 0x40-0x4F
        true,  false, false, false, false, false, false, false, false, false, false, false, false, false, false, false,
        // 0x50-0x5F
        false, false, false, false, false, false, false, false, false, false, false, true,  true,  true,  true,  false,
        // 0x60-0x6F
        true,  false, false, false, false, false, false, false, false, false, false, false, false, false, false, false,
        // 0x70-0x7F
        false, false, false, false, false, false, false, false, false, false, false, true,  true,  true,  false, true,
    };
    @memcpy(table[0..128], &low128);
    break :blk table;
};

// This function assumes 'hostname' now starts with [. It trims 'hostname' in
// place and it sets u->zoneid if present.
pub fn ipv6_parse(u: *Curl_URL, hostname: [*:0]u8, hlen_in: usize) CURLUcode {
    var hlen = hlen_in;
    if (hlen < 4 or hostname[0] != '[' or hostname[hlen - 1] != ']') // '[::]' is the shortest possible valid string
        return .CURLUE_BAD_IPV6;
    const host_inner: [*:0]u8 = hostname + 1;
    hlen -= 2;

    // only valid IPv6 letters are ok
    var len: usize = 0;
    while (host_inner[len] != 0 and isIpv6Char(host_inner[len])) : (len += 1) {}

    if (hlen != len) {
        hlen = len;
        if (host_inner[len] == '%') {
            // this could now be '%[zone id]'
            var zoneid: [MAX_ZONEID_LEN]u8 = undefined;
            var i: usize = 0;
            var h: [*:0]const u8 = host_inner + len + 1;
            // pass '25' if present and is a URL encoded percent sign
            if (h[0] == '2' and h[1] == '5' and h[2] != 0 and h[2] != ']') {
                h += 2;
            }
            while (!invalid_host_char[h[0]] and h[0] != ']' and i < (MAX_ZONEID_LEN - 1)) {
                zoneid[i] = h[0];
                i += 1;
                h += 1;
            }
            if (i == 0 or h[0] != ']' or h[1] != 0)
                return .CURLUE_BAD_IPV6;
            zoneid[i] = 0;
            const zdup = mem.strdup(@ptrCast(&zoneid)) orelse return .CURLUE_OUT_OF_MEMORY;
            mem.free(u.zoneid);
            u.zoneid = zdup;
            host_inner[len] = ']'; // insert end bracket
            host_inner[len + 1] = 0; // terminate the hostname
        } else {
            return .CURLUE_BAD_IPV6;
        }
    }

    // Normalize the IPv6 address
    var dest: [16]u8 = undefined;
    host_inner[hlen] = 0; // end the address there
    if (curlx_time_net.curlx_inet_pton(curlx_time_net.AF_INET6, host_inner, &dest) != 1)
        return .CURLUE_BAD_IPV6;
    if (curlx_time_net.curlx_inet_ntop(curlx_time_net.AF_INET6, &dest, host_inner, hlen + 1) == CURLE_OK) {
        hlen = cStrLen(host_inner); // might be shorter now
        host_inner[hlen + 1] = 0;
    }
    host_inner[hlen] = ']'; // restore ending bracket
    return .CURLUE_OK;
}

// The input is a confirmed hostname, never an IPv6 address
fn hostname_check(hostname: [*]const u8, hlen: usize) CURLUcode {
    var i: usize = 0;
    while (i < hlen) : (i += 1) {
        if (invalid_host_char[hostname[i]])
            return .CURLUE_BAD_HOSTNAME;
    }
    if (hlen >= 2 and hostname[hlen - 1] == '.' and hostname[hlen - 2] == '.') {
        // more than one trailing dot is not allowed
        return .CURLUE_BAD_HOSTNAME;
    } else if (hlen == 1 and hostname[0] == '.') {
        // a single dot alone is not allowed
        return .CURLUE_BAD_HOSTNAME;
    }
    return .CURLUE_OK;
}

// The input is a hostname or perhaps an IPv6 address
fn hostname_check6(u: *Curl_URL, hostname: [*:0]u8, hlen: usize) CURLUcode {
    if (hlen == 0)
        return .CURLUE_NO_HOST;
    if (hostname[0] == '[')
        return ipv6_parse(u, hostname, hlen);

    return hostname_check(hostname, hlen);
}

// Handle partial IPv4 numerical addresses and different bases, like
// '16843009', '0x7f', '0x7f.1', '0177.1.1.1' etc.
pub fn ipv4_normalize(host: *Dynbuf) c_int {
    var done = false;
    var n: usize = 0;
    var c: [*:0]const u8 = curlx_dyn_ptr(host) orelse return HOST_NAME;
    var parts: [4]u32 = .{ 0, 0, 0, 0 };
    var result: c_uint = CURLE_OK;

    if (!isDigit(c[0]))
        return HOST_NAME;

    while (!done) {
        var rc: c_int = 0;
        var l: i64 = 0;
        if (c[0] == '0') {
            if ((c[1] | 0x20) == 'x') {
                c += 2; // skip the prefix
                rc = curlx_str_hex(&c, &l, std.math.maxInt(c_uint));
                if (rc != 0)
                    return HOST_NAME;
            } else {
                rc = curlx_str_octal(&c, &l, std.math.maxInt(c_uint));
            }
        } else {
            rc = curlx_str_number(&c, &l, std.math.maxInt(c_uint));
        }

        if (rc != 0) {
            if (n == 0 or rc != curlx_parse.STRE_NO_NUM or c[0] != 0)
                return HOST_NAME;
            n -= 1;
        } else {
            parts[n] = @intCast(l);
        }

        switch (c[0]) {
            '.' => {
                if (n == 3) {
                    if (c[1] != 0)
                        return HOST_NAME;
                    done = true;
                } else {
                    n += 1;
                    c += 1;
                }
            },
            0 => {
                done = true;
            },
            else => return HOST_NAME,
        }
    }

    switch (n) {
        0 => { // a -- 32 bits
            curlx_dyn_reset(host);
            result = curlx_dyn_addf(
                host,
                "%u.%u.%u.%u",
                @as(c_uint, parts[0] >> 24),
                @as(c_uint, (parts[0] >> 16) & 0xff),
                @as(c_uint, (parts[0] >> 8) & 0xff),
                @as(c_uint, parts[0] & 0xff),
            );
        },
        1 => { // a.b -- 8.24 bits
            if (parts[0] > 0xff or parts[1] > 0xffffff)
                return HOST_NAME;
            curlx_dyn_reset(host);
            result = curlx_dyn_addf(
                host,
                "%u.%u.%u.%u",
                @as(c_uint, parts[0]),
                @as(c_uint, (parts[1] >> 16) & 0xff),
                @as(c_uint, (parts[1] >> 8) & 0xff),
                @as(c_uint, parts[1] & 0xff),
            );
        },
        2 => { // a.b.c -- 8.8.16 bits
            if (parts[0] > 0xff or parts[1] > 0xff or parts[2] > 0xffff)
                return HOST_NAME;
            curlx_dyn_reset(host);
            result = curlx_dyn_addf(
                host,
                "%u.%u.%u.%u",
                @as(c_uint, parts[0]),
                @as(c_uint, parts[1]),
                @as(c_uint, (parts[2] >> 8) & 0xff),
                @as(c_uint, parts[2] & 0xff),
            );
        },
        3 => { // a.b.c.d -- 8.8.8.8 bits
            if (parts[0] > 0xff or parts[1] > 0xff or parts[2] > 0xff or parts[3] > 0xff)
                return HOST_NAME;
            curlx_dyn_reset(host);
            result = curlx_dyn_addf(
                host,
                "%u.%u.%u.%u",
                @as(c_uint, parts[0]),
                @as(c_uint, parts[1]),
                @as(c_uint, parts[2]),
                @as(c_uint, parts[3]),
            );
        },
        else => unreachable,
    }
    if (result != CURLE_OK)
        return HOST_ERROR;
    return HOST_IPV4;
}

// If necessary, replace the host content with a URL decoded version
fn urldecode_host(host: *Dynbuf) CURLUcode {
    const hostname = curlx_dyn_ptr(host) orelse return .CURLUE_OK;
    const per = cMemChr(hostname, '%', curlx_dyn_len(host));
    if (per == null)
        return .CURLUE_OK;

    var dlen: usize = 0;
    var decoded: ?[*:0]u8 = null;
    var result = Curl_urldecode(hostname, 0, &decoded, &dlen, REJECT_CTRL);
    if (result != CURLE_OK)
        return .CURLUE_BAD_HOSTNAME;
    curlx_dyn_reset(host);
    result = curlx_dyn_addn(host, decoded, dlen);
    mem.free(decoded);
    if (result != CURLE_OK)
        return cc2cu(result);

    return .CURLUE_OK;
}

fn parse_authority(
    u: *Curl_URL,
    auth: [*]const u8,
    authlen: usize,
    flags: c_uint,
    host: *Dynbuf,
    has_scheme: bool,
) CURLUcode {
    var offset: usize = 0;
    var uc = parse_hostname_login(u, auth, authlen, flags, &offset);
    if (uc != .CURLUE_OK)
        return uc;

    const result = curlx_dyn_addn(host, auth + offset, authlen - offset);
    if (result != CURLE_OK)
        return cc2cu(result);

    uc = parse_port(u, host, has_scheme);

    if (curlx_dyn_len(host) == 0)
        uc = .CURLUE_NO_HOST;
    if (uc == .CURLUE_OK)
        uc = urldecode_host(host);
    if (uc != .CURLUE_OK) {
        // keep error
    } else if (auth[offset] == '[') {
        if (curlx_dyn_ptr(host)) |hp| {
            uc = ipv6_parse(u, hp, curlx_dyn_len(host));
        } else {
            uc = .CURLUE_BAD_IPV6;
        }
    } else {
        const host_type = ipv4_normalize(host);
        if (host_type == HOST_NAME) {
            if (curlx_dyn_ptr(host)) |hp| {
                uc = hostname_check(hp, curlx_dyn_len(host));
            } else {
                uc = .CURLUE_NO_HOST;
            }
        } else if (host_type == HOST_ERROR) {
            uc = .CURLUE_OUT_OF_MEMORY;
        }
    }

    return uc;
}

// Used for HTTP/2 server push
pub export fn Curl_url_set_authority(u: *Curl_URL, authority: [*:0]const u8) callconv(.c) CURLUcode {
    var host: Dynbuf = undefined;
    curlx_dyn_init(&host, CURL_MAX_INPUT_LENGTH);

    const ures = parse_authority(
        u,
        authority,
        cStrLen(authority),
        CURLU_DISALLOW_USER,
        &host,
        u.scheme != null,
    );
    if (ures != .CURLUE_OK) {
        curlx_dyn_free(&host);
    } else {
        mem.free(u.host);
        u.host = curlx_dyn_ptr(&host);
    }
    return ures;
}

// "Remove Dot Segments"
// https://datatracker.ietf.org/doc/html/rfc3986#section-5.2.4
fn is_dot(str: *[*]const u8, clen: *usize) bool {
    const p = str.*;
    if (p[0] == '.') {
        str.* += 1;
        clen.* -= 1;
        return true;
    } else if (clen.* >= 3 and p[0] == '%' and p[1] == '2' and (p[2] | 0x20) == 'e') {
        str.* += 3;
        clen.* -= 3;
        return true;
    }
    return false;
}

fn needs_dedotdot(p_in: [*]const u8, pn_in: usize) bool {
    var p = p_in;
    var pn = pn_in;
    if (pn < 2)
        return false;
    if (cMemChr(p, '.', pn) == null and cMemChr(p, '%', pn) == null)
        return false;
    while (pn != 0) {
        if (is_dot(&p, &pn)) {
            if (pn == 0 or p[0] == '/')
                return true;
            if (is_dot(&p, &pn) and (pn == 0 or p[0] == '/'))
                return true;
        } else {
            p += 1;
            pn -= 1;
        }
    }
    return false;
}

pub fn dedotdotify(input_in: [*]const u8, clen_in: usize, outp: *?[*:0]u8) c_int {
    var out: Dynbuf = undefined;
    var result: c_uint = CURLE_OK;
    var input = input_in;
    var clen = clen_in;
    var dinput = input;
    var dlen = clen;

    outp.* = null;
    if (!needs_dedotdot(input, clen))
        return 0;

    curlx_dyn_init(&out, clen + 1);

    // If the input buffer begins with a prefix of "../" or "./", then remove
    // that prefix from the input buffer; otherwise,
    var skip_loop = false;
    if (is_dot(&dinput, &dlen)) {
        if (dlen != 0 and dinput[0] == '/') {
            input = dinput + 1;
            clen = dlen - 1;
        } else if (is_dot(&dinput, &dlen)) {
            if (dlen == 0) {
                skip_loop = true;
            } else if (dinput[0] == '/') {
                input = dinput + 1;
                clen = dlen - 1;
            }
        }
    }

    if (!skip_loop) {
        while (clen != 0 and result == CURLE_OK) {
            if (input[0] == '/') {
                var p: [*]const u8 = input + 1;
                var blen: usize = clen - 1;
                if (is_dot(&p, &blen)) {
                    if (blen == 0) { // /.
                        result = curlx_dyn_addn(&out, "/", 1);
                        break;
                    } else if (p[0] == '/') { // /./
                        input = p;
                        clen = blen;
                        continue;
                    } else if (is_dot(&p, &blen) and (blen == 0 or p[0] == '/')) {
                        // remove the last segment from the output buffer
                        const len = curlx_dyn_len(&out);
                        if (len != 0) {
                            if (curlx_dyn_ptr(&out)) |ptr| {
                                if (primitives.Curl_memrchr(ptr, '/', len)) |last_void| {
                                    const last: [*]const u8 = @ptrCast(last_void);
                                    _ = curlx_dyn_setlen(&out, @intFromPtr(last) - @intFromPtr(ptr));
                                }
                            }
                        }

                        if (blen != 0) { // /../
                            input = p;
                            clen = blen;
                            continue;
                        }
                        result = curlx_dyn_addn(&out, "/", 1);
                        break;
                    }
                }
            }

            result = curlx_dyn_addn(&out, input, 1);
            input += 1;
            clen -= 1;
        }
    }

    if (result == CURLE_OK) {
        if (curlx_dyn_len(&out) != 0) {
            outp.* = curlx_dyn_ptr(&out);
        } else {
            curlx_dyn_free(&out);
            outp.* = mem.strdup("");
            if (outp.* == null)
                return 1;
        }
    }
    return if (result != CURLE_OK) 1 else 0;
}

pub fn parse_file(
    url: [*:0]const u8,
    urllen: usize,
    u: *Curl_URL,
    pathp: *?[*:0]const u8,
    pathlenp: *usize,
) CURLUcode {
    pathp.* = null;
    pathlenp.* = 0;
    if (urllen <= 6)
        return .CURLUE_BAD_FILE_URL;

    var path: [*:0]const u8 = url + 5;
    var pathlen: usize = urllen - 5;

    if (path[0] != '/')
        return .CURLUE_BAD_FILE_URL;

    if (path[1] == '/') {
        var ptr: [*:0]const u8 = path + 2;
        if (ptr[0] != '/' and !startsWithUrlDrivePrefix(ptr)) {
            if (checkPrefix("localhost/", ptr) or checkPrefix("127.0.0.1/", ptr)) {
                ptr += 9;
            } else {
                return .CURLUE_BAD_FILE_URL;
            }
        }
        path = ptr;
        pathlen = urllen - (@intFromPtr(ptr) - @intFromPtr(url));
    }

    if (builtin.os.tag == .windows) {
        if (path[0] == '/' and startsWithUrlDrivePrefix(path + 1)) {
            path += 1;
            pathlen -= 1;
        }
    } else {
        if ((path[0] == '/' and startsWithUrlDrivePrefix(path + 1)) or
            startsWithUrlDrivePrefix(path))
        {
            return .CURLUE_BAD_FILE_URL;
        }
    }

    u.scheme = mem.strdup("file") orelse return .CURLUE_OUT_OF_MEMORY;
    pathp.* = path;
    pathlenp.* = pathlen;
    return .CURLUE_OK;
}

fn parse_scheme(
    url: [*:0]const u8,
    u: *Curl_URL,
    schemebuf: [*:0]const u8,
    schemelen: usize,
    flags: c_uint,
    hostpp: *?[*:0]const u8,
) CURLUcode {
    var schemep: ?[*:0]const u8 = null;

    if (schemelen != 0) {
        var num_slashes: usize = 0;
        var p: [*:0]const u8 = url + schemelen + 1;
        if (Curl_getn_scheme(schemebuf, schemelen) == null and
            (flags & CURLU_NON_SUPPORT_SCHEME) == 0)
        {
            return .CURLUE_UNSUPPORTED_SCHEME;
        }

        if (p[0] != '/')
            return .CURLUE_BAD_SLASHES;
        if ((flags & CURLU_NO_AUTHORITY) != 0) {
            while (p[0] == '/' and num_slashes < 2) {
                p += 1;
                num_slashes += 1;
            }
        } else {
            while (p[0] == '/' and num_slashes < 4) {
                p += 1;
                num_slashes += 1;
            }
            if (num_slashes > 3)
                return .CURLUE_BAD_SLASHES;
        }

        schemep = schemebuf;
        hostpp.* = p;
    } else {
        if ((flags & (CURLU_DEFAULT_SCHEME | CURLU_GUESS_SCHEME)) == 0)
            return .CURLUE_BAD_SCHEME;

        if ((flags & CURLU_DEFAULT_SCHEME) != 0)
            schemep = DEFAULT_SCHEME;

        hostpp.* = url;
    }

    if (schemep) |sp| {
        u.scheme = mem.strdup(sp) orelse return .CURLUE_OUT_OF_MEMORY;
    }
    return .CURLUE_OK;
}

fn guess_scheme(u: *Curl_URL, host: *Dynbuf) CURLUcode {
    const hostname = curlx_dyn_ptr(host) orelse "";
    const schemep: [*:0]const u8 = if (checkPrefix("ftp.", hostname))
        "ftp"
    else if (checkPrefix("dict.", hostname))
        "dict"
    else if (checkPrefix("ldap.", hostname))
        "ldap"
    else if (checkPrefix("imap.", hostname))
        "imap"
    else if (checkPrefix("smtp.", hostname))
        "smtp"
    else if (checkPrefix("pop3.", hostname))
        "pop3"
    else
        "http";

    u.scheme = mem.strdup(schemep) orelse return .CURLUE_OUT_OF_MEMORY;
    u.guessed_scheme = true;
    return .CURLUE_OK;
}

fn handle_fragment(u: *Curl_URL, fragment: [*]const u8, fraglen: usize, flags: c_uint) CURLUcode {
    u.fragment_present = true;
    if (fraglen > 1) {
        if ((flags & CURLU_URLENCODE) != 0) {
            var enc: Dynbuf = undefined;
            curlx_dyn_init(&enc, CURL_MAX_INPUT_LENGTH);
            const ures = urlencode_str(&enc, fragment + 1, fraglen - 1, true, QUERY_NO);
            if (ures != .CURLUE_OK)
                return ures;
            u.fragment = curlx_dyn_ptr(&enc);
        } else {
            if (badoctets(fragment, fraglen, flags))
                return .CURLUE_BAD_FRAGMENT;
            u.fragment = curlx_memdup0(fragment + 1, fraglen - 1) orelse return .CURLUE_OUT_OF_MEMORY;
        }
    }
    return .CURLUE_OK;
}

fn handle_query(u: *Curl_URL, query: [*]const u8, qlen: usize, flags: c_uint) CURLUcode {
    u.query_present = true;
    if (qlen > 1) {
        if ((flags & CURLU_URLENCODE) != 0) {
            var enc: Dynbuf = undefined;
            curlx_dyn_init(&enc, CURL_MAX_INPUT_LENGTH);
            const ures = urlencode_str(&enc, query + 1, qlen - 1, true, QUERY_YES);
            if (ures != .CURLUE_OK)
                return ures;
            u.query = curlx_dyn_ptr(&enc);
        } else {
            if (badoctets(query, qlen, flags))
                return .CURLUE_BAD_QUERY;
            u.query = curlx_memdup0(query + 1, qlen - 1) orelse return .CURLUE_OUT_OF_MEMORY;
        }
    } else {
        u.query = mem.strdup("") orelse return .CURLUE_OUT_OF_MEMORY;
    }
    return .CURLUE_OK;
}

fn handle_path(u: *Curl_URL, path_in: [*]const u8, pathlen_in: usize, flags: c_uint, is_file: bool) CURLUcode {
    var path = path_in;
    var pathlen = pathlen_in;

    if (pathlen != 0 and (flags & CURLU_URLENCODE) != 0) {
        var enc: Dynbuf = undefined;
        curlx_dyn_init(&enc, CURL_MAX_INPUT_LENGTH);
        const ures = urlencode_str(&enc, path, pathlen, true, QUERY_NO);
        if (ures != .CURLUE_OK)
            return ures;
        pathlen = curlx_dyn_len(&enc);
        u.path = curlx_dyn_ptr(&enc);
        if (u.path) |up| {
            path = up;
        }
    }

    const min_len: usize = if (is_file) 1 else 2;
    if (pathlen >= min_len) {
        if (badoctets(path, pathlen, flags))
            return .CURLUE_BAD_PATH;

        if (u.path == null) {
            const dup = curlx_memdup0(path, pathlen) orelse return .CURLUE_OUT_OF_MEMORY;
            u.path = dup;
            path = dup;
        } else if ((flags & CURLU_URLENCODE) != 0) {
            if (u.path) |up| {
                up[pathlen] = 0;
            }
        }

        if ((flags & CURLU_PATH_AS_IS) == 0) {
            var dedot: ?[*:0]u8 = null;
            const err = dedotdotify(path, pathlen, &dedot);
            if (err != 0)
                return .CURLUE_OUT_OF_MEMORY;
            if (dedot) |dd| {
                mem.free(u.path);
                u.path = dd;
            }
        }
    }
    return .CURLUE_OK;
}

fn parseurl(url: [*:0]const u8, u: *Curl_URL, flags: c_uint) CURLUcode {
    var path: [*:0]const u8 = url;
    var pathlen: usize = 0;
    var schemebuf: [MAX_SCHEME_LEN + 1]u8 = undefined;
    var ures: CURLUcode = .CURLUE_OK;
    var host: Dynbuf = undefined;
    var is_file = false;

    const urllen = cStrLen(url);
    if (urllen > CURL_MAX_INPUT_LENGTH)
        return .CURLUE_MALFORMED_INPUT;

    curlx_dyn_init(&host, CURL_MAX_INPUT_LENGTH);

    const schemelen = Curl_is_absolute_url(
        url,
        &schemebuf,
        schemebuf.len,
        (flags & (CURLU_GUESS_SCHEME | CURLU_DEFAULT_SCHEME)) != 0,
    );

    if (schemelen == 4 and std.mem.eql(u8, schemebuf[0..4], "file")) {
        is_file = true;
        var file_path: ?[*:0]const u8 = null;
        ures = parse_file(url, urllen, u, &file_path, &pathlen);
        if (file_path) |fp| {
            path = fp;
        }
    } else {
        var hostp_opt: ?[*:0]const u8 = null;
        ures = parse_scheme(url, u, @ptrCast(&schemebuf), schemelen, flags, &hostp_opt);
        if (ures != .CURLUE_OK) {
            curlx_dyn_free(&host);
            free_urlhandle(u);
            return ures;
        }
        const hostp = hostp_opt.?;

        var p = hostp;
        while (p[0] != 0 and p[0] != '/' and p[0] != '?' and p[0] != '#') : (p += 1) {}
        const hostlen: usize = @intFromPtr(p) - @intFromPtr(hostp);
        path = p;

        pathlen = urllen - (@intFromPtr(path) - @intFromPtr(url));
        if (hostlen != 0) {
            ures = parse_authority(u, hostp, hostlen, flags, &host, u.scheme != null);
            if (ures == .CURLUE_OK and (flags & CURLU_GUESS_SCHEME) != 0 and u.scheme == null)
                ures = guess_scheme(u, &host);
        } else if ((flags & CURLU_NO_AUTHORITY) != 0) {
            if (curlx_dyn_add(&host, "") != CURLE_OK)
                ures = .CURLUE_OUT_OF_MEMORY;
        } else {
            ures = .CURLUE_NO_HOST;
        }
    }

    if (ures == .CURLUE_OK) {
        if (cMemChr(path, '#', pathlen)) |fragment| {
            const fraglen: usize = pathlen - (@intFromPtr(fragment) - @intFromPtr(path));
            ures = handle_fragment(u, fragment, fraglen, flags);
            pathlen -= fraglen;
        }
    }
    if (ures == .CURLUE_OK) {
        if (cMemChr(path, '?', pathlen)) |query| {
            const qlen: usize = pathlen - (@intFromPtr(query) - @intFromPtr(path));
            ures = handle_query(u, query, qlen, flags);
            pathlen -= qlen;
        }
    }
    if (ures == .CURLUE_OK) {
        ures = handle_path(u, path, pathlen, flags, is_file);
    }
    if (ures == .CURLUE_OK) {
        u.host = curlx_dyn_ptr(&host);
        return .CURLUE_OK;
    }

    curlx_dyn_free(&host);
    free_urlhandle(u);
    return ures;
}

fn parseurl_and_replace(url: [*:0]const u8, u: *Curl_URL, flags: c_uint) CURLUcode {
    var tmpurl: Curl_URL = .{};
    const ures = parseurl(url, &tmpurl, flags);
    if (ures == .CURLUE_OK) {
        free_urlhandle(u);
        u.* = tmpurl;
    }
    return ures;
}

fn redirect_url(base: [*:0]const u8, relurl: [*:0]const u8, u: *Curl_URL, flags: c_uint) CURLUcode {
    var urlbuf: Dynbuf = undefined;
    var host_changed = false;
    var useurl: [*:0]const u8 = relurl;
    var cutoff: ?[*]const u8 = null;
    const scheme: [*:0]const u8 = u.scheme orelse DEFAULT_SCHEME;
    const sep_off = cStrLen(scheme) + 3;
    if (cStrLen(base) < sep_off)
        return .CURLUE_MALFORMED_INPUT;

    const protsep: [*:0]const u8 = base + sep_off;

    switch (relurl[0]) {
        '/' => {
            if (relurl[1] == '/') {
                cutoff = protsep;
                useurl = relurl + 2;
                host_changed = true;
            } else {
                if (cStrChr(protsep, '/')) |s| cutoff = s;
            }
        },
        '#' => {
            if (u.fragment_present) {
                if (cStrChr(protsep, '#')) |s| cutoff = s;
            }
        },
        else => {
            if (u.query_present) {
                if (cStrChr(protsep, '?')) |s| cutoff = s;
            } else if (u.fragment_present) {
                if (cStrChr(protsep, '#')) |s| cutoff = s;
            }

            if (relurl[0] != '?') {
                const search_len: usize = if (cutoff) |co|
                    @intFromPtr(co) - @intFromPtr(protsep)
                else
                    cStrLen(protsep);
                if (primitives.Curl_memrchr(protsep, '/', search_len)) |last_slash| {
                    cutoff = @as([*]const u8, @ptrCast(last_slash)) + 1;
                } else {
                    cutoff = null;
                }
            }
        },
    }

    const prelen: usize = if (cutoff) |co|
        @intFromPtr(co) - @intFromPtr(base)
    else
        cStrLen(base);

    curlx_dyn_init(&urlbuf, CURL_MAX_INPUT_LENGTH);

    var uc: CURLUcode = undefined;
    if (curlx_dyn_addn(&urlbuf, base, prelen) == CURLE_OK and
        urlencode_str(&urlbuf, useurl, cStrLen(useurl), !host_changed, QUERY_NOT_YET) == .CURLUE_OK)
    {
        const combined = curlx_dyn_ptr(&urlbuf) orelse "";
        uc = parseurl_and_replace(combined, u, flags & ~CURLU_PATH_AS_IS);
    } else {
        uc = .CURLUE_OUT_OF_MEMORY;
    }

    curlx_dyn_free(&urlbuf);
    return uc;
}

pub export fn curl_url() callconv(.c) ?*Curl_URL {
    const raw = mem.calloc(1, @sizeOf(Curl_URL)) orelse return null;
    return @ptrCast(@alignCast(raw));
}

pub export fn curl_url_cleanup(u: ?*Curl_URL) callconv(.c) void {
    if (u) |handle| {
        free_urlhandle(handle);
        mem.free(handle);
    }
}

fn dupField(src: ?[*:0]u8, dest: *?[*:0]u8) bool {
    if (src) |s| {
        const d = mem.strdup(s) orelse return false;
        dest.* = d;
    }
    return true;
}

pub export fn curl_url_dup(in_u: ?*const Curl_URL) callconv(.c) ?*Curl_URL {
    const in = in_u orelse return null;
    const u = curl_url() orelse return null;

    if (!dupField(in.scheme, &u.scheme) or
        !dupField(in.user, &u.user) or
        !dupField(in.password, &u.password) or
        !dupField(in.options, &u.options) or
        !dupField(in.host, &u.host) or
        !dupField(in.path, &u.path) or
        !dupField(in.query, &u.query) or
        !dupField(in.fragment, &u.fragment) or
        !dupField(in.zoneid, &u.zoneid))
    {
        curl_url_cleanup(u);
        return null;
    }

    u.portnum = in.portnum;
    u.port_present = in.port_present;
    u.fragment_present = in.fragment_present;
    u.query_present = in.query_present;
    u.guessed_scheme = in.guessed_scheme;
    return u;
}

fn host_decode(host: [*:0]const u8, allochost: *?[*:0]u8) CURLUcode {
    _ = host;
    _ = allochost;
    return .CURLUE_LACKS_IDN;
}

fn host_encode(host: [*:0]const u8, allochost: *?[*:0]u8) CURLUcode {
    _ = host;
    _ = allochost;
    return .CURLUE_LACKS_IDN;
}

fn urlget_format(
    u: *const Curl_URL,
    what: CURLUPart,
    ptr: [*:0]const u8,
    partp: *?[*:0]u8,
    plusdecode: bool,
    flags: c_uint,
) CURLUcode {
    var uc: CURLUcode = .CURLUE_OK;
    var partlen = cStrLen(ptr);
    const urldecode = (flags & CURLU_URLDECODE) != 0;
    const urlencode = (flags & CURLU_URLENCODE) != 0;
    const punycode = (flags & CURLU_PUNYCODE) != 0 and what == .CURLUPART_HOST;
    const depunyfy = (flags & CURLU_PUNY2IDN) != 0 and what == .CURLUPART_HOST;

    var part: ?[*:0]u8 = curlx_memdup0(ptr, partlen);
    partp.* = null;
    if (part == null)
        return .CURLUE_OUT_OF_MEMORY;

    if (plusdecode) {
        const p = part.?;
        var i: usize = 0;
        while (i < partlen) : (i += 1) {
            if (p[i] == '+')
                p[i] = ' ';
        }
    }
    if (urldecode) {
        var decoded: ?[*:0]u8 = null;
        var dlen: usize = 0;
        const result = Curl_urldecode(part.?, partlen, &decoded, &dlen, REJECT_CTRL);
        mem.free(part);
        if (result != CURLE_OK)
            return .CURLUE_URLDECODE;
        part = decoded;
        partlen = dlen;
    }
    if (urlencode) {
        var enc: Dynbuf = undefined;
        curlx_dyn_init(&enc, CURL_MAX_INPUT_LENGTH);
        uc = urlencode_str(
            &enc,
            part.?,
            partlen,
            true,
            if (what == .CURLUPART_QUERY) QUERY_YES else QUERY_NO,
        );
        mem.free(part);
        if (uc != .CURLUE_OK)
            return uc;
        part = curlx_dyn_ptr(&enc);
    } else if (punycode) {
        if (!Curl_is_ASCII_name(u.host)) {
            var punyversion: ?[*:0]u8 = null;
            uc = host_decode(part.?, &punyversion);
            mem.free(part);
            if (uc != .CURLUE_OK)
                return uc;
            part = punyversion;
        }
    } else if (depunyfy and Curl_is_ASCII_name(u.host)) {
        var unpunified: ?[*:0]u8 = null;
        uc = host_encode(part.?, &unpunified);
        mem.free(part);
        if (uc != .CURLUE_OK)
            return uc;
        part = unpunified;
    }
    partp.* = part;
    return .CURLUE_OK;
}

fn file_url(
    u: *const Curl_URL,
    part: *?[*:0]u8,
    fragmentsep: [*:0]const u8,
    querysep: [*:0]const u8,
) CURLUcode {
    const empty: [*:0]const u8 = "";
    const url = curl_maprintf(
        "file://%s%s%s%s%s",
        u.path,
        querysep,
        u.query orelse empty,
        fragmentsep,
        u.fragment orelse empty,
    ) orelse return .CURLUE_OUT_OF_MEMORY;

    part.* = url;
    return .CURLUE_OK;
}

fn urlget_url(u: *const Curl_URL, part: *?[*:0]u8, flags: c_uint) CURLUcode {
    var allochost: ?[*:0]u8 = null;
    const empty: [*:0]const u8 = "";
    const fragmentsep: [*:0]const u8 = if (u.fragment != null or (u.fragment_present and (flags & CURLU_GET_EMPTY) != 0))
        "#"
    else
        "";
    const querysep: [*:0]const u8 = if ((u.query != null and u.query.?[0] != 0) or
        (u.query_present and (flags & CURLU_GET_EMPTY) != 0))
        "?"
    else
        "";
    var portbuf: [7]u8 = undefined;

    if (primitives.curl_strequal("file", u.scheme) != 0) {
        return file_url(u, part, fragmentsep, querysep);
    } else if (u.host == null) {
        return .CURLUE_NO_HOST;
    } else {
        const host_str = u.host.?;
        const scheme: [*:0]const u8 = if (u.scheme) |sc|
            sc
        else if ((flags & CURLU_DEFAULT_SCHEME) != 0)
            DEFAULT_SCHEME
        else
            return .CURLUE_NO_SCHEME;

        var options: ?[*:0]u8 = u.options;
        var port: ?[*:0]const u8 = null;
        var schemebuf: [MAX_SCHEME_LEN + 5]u8 = undefined;

        if (u.port_present) {
            _ = curl_msnprintf(&portbuf, portbuf.len, "%u", @as(c_uint, u.portnum));
            port = @ptrCast(&portbuf);
        }

        if (Curl_get_scheme(scheme)) |h| {
            if (!u.port_present and (flags & CURLU_DEFAULT_PORT) != 0) {
                _ = curl_msnprintf(&portbuf, portbuf.len, "%u", @as(c_uint, h.defport));
                port = @ptrCast(&portbuf);
            } else if (u.port_present and h.defport == u.portnum and (flags & CURLU_NO_DEFAULT_PORT) != 0) {
                port = null;
            }

            if ((h.flags & PROTOPT_URLOPTIONS) == 0) {
                options = null;
            }
        }

        if (host_str[0] == '[') {
            if (u.zoneid) |zid| {
                var enc: Dynbuf = undefined;
                const hostlen = cStrLen(host_str);
                curlx_dyn_init(&enc, CURL_MAX_INPUT_LENGTH);
                if (curlx_dyn_addf(&enc, "%.*s%%25%s]", @as(c_int, @intCast(hostlen - 1)), host_str, zid) != CURLE_OK)
                    return .CURLUE_OUT_OF_MEMORY;
                allochost = curlx_dyn_ptr(&enc);
            }
        } else if ((flags & CURLU_URLENCODE) != 0) {
            allochost = curl_easy_escape(null, host_str, 0) orelse return .CURLUE_OUT_OF_MEMORY;
        } else if ((flags & CURLU_PUNYCODE) != 0) {
            if (!Curl_is_ASCII_name(host_str)) {
                const ret = host_decode(host_str, &allochost);
                if (ret != .CURLUE_OK)
                    return ret;
            }
        } else if ((flags & CURLU_PUNY2IDN) != 0) {
            if (Curl_is_ASCII_name(host_str)) {
                const ret = host_encode(host_str, &allochost);
                if (ret != .CURLUE_OK)
                    return ret;
            }
        }

        if ((flags & CURLU_NO_GUESS_SCHEME) == 0 or !u.guessed_scheme) {
            _ = curl_msnprintf(&schemebuf, schemebuf.len, "%s://", scheme);
        } else {
            schemebuf[0] = 0;
        }

        const colon: [*:0]const u8 = ":";
        const semicolon: [*:0]const u8 = ";";
        const at_sign: [*:0]const u8 = "@";
        const default_path: [*:0]const u8 = "/";

        const url = curl_maprintf(
            "%s%s%s%s%s%s%s%s%s%s%s%s%s%s%s",
            @as([*:0]const u8, @ptrCast(&schemebuf)),
            u.user orelse empty,
            if (u.password != null) colon else empty,
            u.password orelse empty,
            if (options != null) semicolon else empty,
            options orelse empty,
            if (u.user != null or u.password != null or options != null) at_sign else empty,
            allochost orelse host_str,
            if (port != null) colon else empty,
            port orelse empty,
            u.path orelse default_path,
            querysep,
            u.query orelse empty,
            fragmentsep,
            u.fragment orelse empty,
        );
        mem.free(allochost);
        if (url == null)
            return .CURLUE_OUT_OF_MEMORY;
        part.* = url;
        return .CURLUE_OK;
    }
}

pub export fn curl_url_get(
    u_opt: ?*const Curl_URL,
    what: CURLUPart,
    part_opt: ?*?[*:0]u8,
    flags_in: c_uint,
) callconv(.c) CURLUcode {
    const u = u_opt orelse return .CURLUE_BAD_HANDLE;
    const part = part_opt orelse return .CURLUE_BAD_PARTPOINTER;
    var flags = flags_in;
    var ptr: ?[*:0]const u8 = null;
    var ifmissing: CURLUcode = .CURLUE_UNKNOWN_PART;
    var portbuf: [7]u8 = undefined;
    var plusdecode = false;

    part.* = null;

    switch (what) {
        .CURLUPART_SCHEME => {
            ptr = u.scheme;
            ifmissing = .CURLUE_NO_SCHEME;
            flags &= ~CURLU_URLDECODE;
            if ((flags & CURLU_NO_GUESS_SCHEME) != 0 and u.guessed_scheme)
                return .CURLUE_NO_SCHEME;
        },
        .CURLUPART_USER => {
            ptr = u.user;
            ifmissing = .CURLUE_NO_USER;
        },
        .CURLUPART_PASSWORD => {
            ptr = u.password;
            ifmissing = .CURLUE_NO_PASSWORD;
        },
        .CURLUPART_OPTIONS => {
            ptr = u.options;
            ifmissing = .CURLUE_NO_OPTIONS;
        },
        .CURLUPART_HOST => {
            ptr = u.host;
            ifmissing = .CURLUE_NO_HOST;
        },
        .CURLUPART_ZONEID => {
            ptr = u.zoneid;
            ifmissing = .CURLUE_NO_ZONEID;
        },
        .CURLUPART_PORT => {
            ptr = null;
            ifmissing = .CURLUE_NO_PORT;
            flags &= ~CURLU_URLDECODE;
            if (u.port_present) {
                const h: ?*const Curl_scheme = if (u.scheme) |sc| Curl_get_scheme(sc) else null;
                if (h != null and h.?.defport == u.portnum and (flags & CURLU_NO_DEFAULT_PORT) != 0) {
                    ptr = null;
                } else {
                    _ = curl_msnprintf(&portbuf, portbuf.len, "%u", @as(c_uint, u.portnum));
                    ptr = @ptrCast(&portbuf);
                }
            } else if ((flags & CURLU_DEFAULT_PORT) != 0 and u.scheme != null) {
                if (Curl_get_scheme(u.scheme.?)) |h| {
                    _ = curl_msnprintf(&portbuf, portbuf.len, "%u", @as(c_uint, h.defport));
                    ptr = @ptrCast(&portbuf);
                }
            }
        },
        .CURLUPART_PATH => {
            ptr = u.path orelse "/";
        },
        .CURLUPART_QUERY => {
            ptr = u.query;
            ifmissing = .CURLUE_NO_QUERY;
            plusdecode = (flags & CURLU_URLDECODE) != 0;
            if (ptr != null and ptr.?[0] == 0 and (flags & CURLU_GET_EMPTY) == 0) {
                ptr = null;
            }
        },
        .CURLUPART_FRAGMENT => {
            ptr = u.fragment;
            ifmissing = .CURLUE_NO_FRAGMENT;
            if (ptr == null and u.fragment_present and (flags & CURLU_GET_EMPTY) != 0) {
                ptr = "";
            }
        },
        .CURLUPART_URL => {
            return urlget_url(u, part, flags);
        },
        _ => {
            ptr = null;
        },
    }
    if (ptr) |p| {
        return urlget_format(u, what, p, part, plusdecode, flags);
    }
    return ifmissing;
}

fn set_url_scheme(u: *Curl_URL, scheme: [*:0]const u8, flags: c_uint) CURLUcode {
    var plen = cStrLen(scheme);
    if (plen > MAX_SCHEME_LEN or plen < 1)
        return .CURLUE_BAD_SCHEME;
    const h = Curl_get_scheme(scheme);
    if ((flags & CURLU_NON_SUPPORT_SCHEME) == 0 and (h == null or h.?.run == null))
        return .CURLUE_UNSUPPORTED_SCHEME;
    if (h == null) {
        var s = scheme;
        if (isAlpha(s[0])) {
            s += 1;
            plen -= 1;
            while (plen != 0) : (plen -= 1) {
                if (isSchemeChar(s[0])) {
                    s += 1;
                } else {
                    return .CURLUE_BAD_SCHEME;
                }
            }
        } else {
            return .CURLUE_BAD_SCHEME;
        }
    }
    u.guessed_scheme = false;
    return .CURLUE_OK;
}

fn set_url_port(u: *Curl_URL, provided_port: [*:0]const u8) CURLUcode {
    var p = provided_port;
    var port: i64 = 0;
    if (!isDigit(p[0]))
        return .CURLUE_BAD_PORT_NUMBER;
    if (curlx_str_number(&p, &port, 0xffff) != 0 or p[0] != 0)
        return .CURLUE_BAD_PORT_NUMBER;
    u.portnum = @intCast(port);
    u.port_present = true;
    return .CURLUE_OK;
}

fn set_url(u: *Curl_URL, url: [*:0]const u8, part_size: usize, flags: c_uint) CURLUcode {
    var oldurl: ?[*:0]u8 = null;

    if (part_size == 0) {
        const uc = curl_url_get(u, .CURLUPART_URL, &oldurl, flags);
        if (uc == .CURLUE_OK) {
            mem.free(u.fragment);
            u.fragment = null;
            u.fragment_present = false;
            mem.free(oldurl);
            return .CURLUE_OK;
        }
        if (uc == .CURLUE_OUT_OF_MEMORY)
            return uc;
        return .CURLUE_MALFORMED_INPUT;
    }

    if (Curl_is_absolute_url(
        url,
        null,
        0,
        (flags & (CURLU_GUESS_SCHEME | CURLU_DEFAULT_SCHEME)) != 0,
    ) != 0) {
        return parseurl_and_replace(url, u, flags);
    }

    var uc = curl_url_get(
        u,
        .CURLUPART_URL,
        &oldurl,
        (flags & ~CURLU_NO_GUESS_SCHEME) | CURLU_GET_EMPTY,
    );
    if (uc == .CURLUE_OUT_OF_MEMORY)
        return uc;
    if (uc != .CURLUE_OK)
        return parseurl_and_replace(url, u, flags);

    uc = redirect_url(oldurl.?, url, u, flags);
    mem.free(oldurl);
    return uc;
}

fn urlset_clear(u: *Curl_URL, what: CURLUPart) CURLUcode {
    switch (what) {
        .CURLUPART_URL => {
            free_urlhandle(u);
            u.* = .{};
        },
        .CURLUPART_SCHEME => {
            mem.free(u.scheme);
            u.scheme = null;
            u.guessed_scheme = false;
        },
        .CURLUPART_USER => {
            mem.free(u.user);
            u.user = null;
        },
        .CURLUPART_PASSWORD => {
            if (u.password) |pw| {
                curlx_strzero(pw);
                mem.free(pw);
                u.password = null;
            }
        },
        .CURLUPART_OPTIONS => {
            mem.free(u.options);
            u.options = null;
        },
        .CURLUPART_HOST => {
            mem.free(u.host);
            u.host = null;
        },
        .CURLUPART_ZONEID => {
            mem.free(u.zoneid);
            u.zoneid = null;
        },
        .CURLUPART_PORT => {
            u.portnum = 0;
            u.port_present = false;
        },
        .CURLUPART_PATH => {
            mem.free(u.path);
            u.path = null;
        },
        .CURLUPART_QUERY => {
            mem.free(u.query);
            u.query = null;
            u.query_present = false;
        },
        .CURLUPART_FRAGMENT => {
            mem.free(u.fragment);
            u.fragment = null;
            u.fragment_present = false;
        },
        _ => return .CURLUE_UNKNOWN_PART,
    }
    return .CURLUE_OK;
}

fn allowed_in_path(x: u8) bool {
    return switch (x) {
        '!', '$', '&', '\'', '(', ')', '{', '}', '[', ']', '*', '+', ',', ';', '=', ':', '@', '/' => true,
        else => false,
    };
}

fn url_encode_part(
    encp: *Dynbuf,
    part: [*:0]const u8,
    plusencode: bool,
    pathmode: bool,
    equalsencode_in: bool,
) CURLUcode {
    var equalsencode = equalsencode_in;
    var i: [*:0]const u8 = part;

    while (i[0] != 0) : (i += 1) {
        const c = i[0];
        var result: c_uint = CURLE_OK;
        if (c == ' ' and plusencode) {
            result = curlx_dyn_addn(encp, "+", 1);
        } else if (isUnreserved(c) or
            (pathmode and allowed_in_path(c)) or
            (c == '=' and equalsencode))
        {
            if (c == '=' and equalsencode)
                equalsencode = false;
            result = curlx_dyn_addn(encp, i, 1);
        } else {
            var out: [3]u8 = .{ '%', 0, 0 };
            Curl_hexbyte(out[1..].ptr, c);
            result = curlx_dyn_addn(encp, &out, 3);
        }
        if (result != CURLE_OK)
            return cc2cu(result);
    }
    return .CURLUE_OK;
}

fn url_uppercasehex_part(encp: *Dynbuf, part: [*:0]const u8) CURLUcode {
    const result = curlx_dyn_add(encp, part);
    if (result != CURLE_OK)
        return cc2cu(result);
    var p = curlx_dyn_ptr(encp) orelse return .CURLUE_OK;
    while (p[0] != 0) {
        if (p[0] == '%' and isXdigit(p[1]) and isXdigit(p[2]) and
            (isLower(p[1]) or isLower(p[2])))
        {
            p[1] = primitives.rawToupper(p[1]);
            p[2] = primitives.rawToupper(p[2]);
            p += 3;
        } else {
            p += 1;
        }
    }
    return .CURLUE_OK;
}

fn url_append_query(u: *Curl_URL, encp: *Dynbuf) CURLUcode {
    const querylen: usize = if (u.query) |q| cStrLen(q) else 0;
    const addamperand = querylen != 0 and u.query.?[querylen - 1] != '&';
    if (querylen != 0) {
        var qbuf: Dynbuf = undefined;
        const newp = curlx_dyn_ptr(encp) orelse "";
        curlx_dyn_init(&qbuf, CURL_MAX_INPUT_LENGTH);

        var result = curlx_dyn_addn(&qbuf, u.query.?, querylen);
        if (result == CURLE_OK and addamperand)
            result = curlx_dyn_addn(&qbuf, "&", 1);
        if (result == CURLE_OK)
            result = curlx_dyn_add(&qbuf, newp);
        if (result != CURLE_OK) {
            curlx_dyn_free(&qbuf);
            curlx_dyn_free(encp);
            return cc2cu(result);
        }
        curlx_dyn_free(encp);
        mem.free(u.query);
        u.query = curlx_dyn_ptr(&qbuf);
        return .CURLUE_OK;
    } else {
        mem.free(u.query);
        u.query = curlx_dyn_ptr(encp);
    }
    return .CURLUE_OK;
}

fn url_sethost(u: *Curl_URL, encp: *Dynbuf, urlencode: bool, flags: c_uint) CURLUcode {
    const n = curlx_dyn_len(encp);
    var bad = false;
    const newp_opt = curlx_dyn_ptr(encp);
    if (n == 0) {
        bad = (flags & CURLU_NO_AUTHORITY) == 0;
    } else if (!urlencode) {
        const newp = newp_opt.?;
        var dlen: usize = 0;
        var decoded: ?[*:0]u8 = null;
        const result = Curl_urldecode(newp, n, &decoded, &dlen, REJECT_CTRL);
        if (result != CURLE_OK or hostname_check6(u, decoded.?, dlen) != .CURLUE_OK) {
            bad = true;
        } else {
            var dbuf: Dynbuf = undefined;
            curlx_dyn_init(&dbuf, CURL_MAX_INPUT_LENGTH);
            if (curlx_dyn_addn(&dbuf, decoded, dlen) != CURLE_OK) {
                bad = true;
            } else if (ipv4_normalize(&dbuf) == HOST_IPV4) {
                curlx_dyn_reset(encp);
                if (curlx_dyn_addn(encp, curlx_dyn_ptr(&dbuf), curlx_dyn_len(&dbuf)) != CURLE_OK)
                    bad = true;
            }
            curlx_dyn_free(&dbuf);
        }
        mem.free(decoded);
    } else if (hostname_check6(u, newp_opt.?, n) != .CURLUE_OK) {
        bad = true;
    } else if (ipv4_normalize(encp) == HOST_ERROR) {
        bad = true;
    }
    if (bad) {
        curlx_dyn_free(encp);
        return .CURLUE_BAD_HOSTNAME;
    }
    return .CURLUE_OK;
}

pub export fn curl_url_set(
    u_opt: ?*Curl_URL,
    what: CURLUPart,
    part_opt: ?[*:0]const u8,
    flags: c_uint,
) callconv(.c) CURLUcode {
    const u = u_opt orelse return .CURLUE_BAD_HANDLE;
    const part = part_opt orelse return urlset_clear(u, what);

    var storep: *?[*:0]u8 = undefined;
    var urlencode = (flags & CURLU_URLENCODE) != 0;
    var plusencode = false;
    var pathmode = false;
    var leadingslash = false;
    var appendquery = false;
    var equalsencode = false;

    const nalloc = cStrLen(part);
    if (nalloc > CURL_MAX_INPUT_LENGTH)
        return .CURLUE_MALFORMED_INPUT;

    switch (what) {
        .CURLUPART_SCHEME => {
            const status = set_url_scheme(u, part, flags);
            if (status != .CURLUE_OK)
                return status;
            storep = &u.scheme;
            urlencode = false;
        },
        .CURLUPART_USER => {
            storep = &u.user;
        },
        .CURLUPART_PASSWORD => {
            storep = &u.password;
        },
        .CURLUPART_OPTIONS => {
            storep = &u.options;
        },
        .CURLUPART_HOST => {
            storep = &u.host;
            mem.free(u.zoneid);
            u.zoneid = null;
        },
        .CURLUPART_ZONEID => {
            storep = &u.zoneid;
        },
        .CURLUPART_PORT => {
            return set_url_port(u, part);
        },
        .CURLUPART_PATH => {
            pathmode = true;
            leadingslash = true;
            storep = &u.path;
        },
        .CURLUPART_QUERY => {
            plusencode = urlencode;
            appendquery = (flags & CURLU_APPENDQUERY) != 0;
            equalsencode = appendquery;
            storep = &u.query;
            u.query_present = true;
        },
        .CURLUPART_FRAGMENT => {
            storep = &u.fragment;
            u.fragment_present = true;
        },
        .CURLUPART_URL => {
            return set_url(u, part, nalloc, flags);
        },
        _ => return .CURLUE_UNKNOWN_PART,
    }

    var newp: ?[*:0]u8 = null;
    var enc: Dynbuf = undefined;
    const max_len = (nalloc * 3) + 1 + @as(usize, @intFromBool(leadingslash));
    curlx_dyn_init(&enc, if (what == .CURLUPART_HOST) @max(max_len, 16) else max_len);

    if (leadingslash and part[0] != '/') {
        const result = curlx_dyn_addn(&enc, "/", 1);
        if (result != CURLE_OK)
            return cc2cu(result);
    }

    var status = if (urlencode)
        url_encode_part(&enc, part, plusencode, pathmode, equalsencode)
    else
        url_uppercasehex_part(&enc, part);

    if (status == .CURLUE_OK) {
        newp = curlx_dyn_ptr(&enc);
        if (appendquery and newp != null) {
            return url_append_query(u, &enc);
        } else if (what == .CURLUPART_HOST) {
            status = url_sethost(u, &enc, urlencode, flags);
            if (status == .CURLUE_OK) {
                newp = curlx_dyn_ptr(&enc);
            }
        }
    }
    if (status != .CURLUE_OK)
        return status;

    if (what == .CURLUPART_PASSWORD) {
        if (storep.*) |pw| {
            curlx_strzero(pw);
        }
    }
    mem.free(storep.*);
    storep.* = newp;
    return .CURLUE_OK;
}

pub export fn Curl_url_same_origin(base: *Curl_URL, href: *Curl_URL) callconv(.c) bool {
    if (base.scheme == null or base.host == null)
        return false;
    if (href.scheme != null and primitives.curl_strequal(base.scheme, href.scheme) == 0)
        return false;
    if (href.host != null) {
        if (primitives.curl_strequal(base.host, href.host) == 0)
            return false;

        if (base.port_present != href.port_present) {
            const s = Curl_get_scheme(base.scheme.?) orelse return false;
            if ((base.port_present and base.portnum != s.defport) or
                (href.port_present and href.portnum != s.defport))
            {
                return false;
            }
        } else if (base.portnum != href.portnum) {
            return false;
        }

        const empty: [*:0]const u8 = "";
        if (primitives.curl_strequal(base.zoneid orelse empty, href.zoneid orelse empty) == 0)
            return false;
    } else if (href.port_present) {
        return false;
    }
    return true;
}

pub export fn Curl_url_get_port(u: *Curl_URL, pport: *u16) callconv(.c) CURLUcode {
    if (u.port_present) {
        pport.* = u.portnum;
        return .CURLUE_OK;
    } else if (u.scheme) |sc| {
        if (Curl_get_scheme(sc)) |s| {
            if (s.defport != 0) {
                pport.* = s.defport;
                return .CURLUE_OK;
            }
        }
    }
    pport.* = 0;
    return .CURLUE_NO_PORT;
}

// ============================================================================
// Unit Tests
// ============================================================================

fn expectUrl(
    input: [:0]const u8,
    set_flags: c_uint,
    get_flags: c_uint,
    expected_set_code: CURLUcode,
    expected_url: ?[]const u8,
) !void {
    const u = curl_url() orelse return error.OutOfMemory;
    defer curl_url_cleanup(u);

    const rc = curl_url_set(u, .CURLUPART_URL, input.ptr, set_flags);
    try std.testing.expectEqual(expected_set_code, rc);

    if (expected_url) |exp| {
        var out: ?[*:0]u8 = null;
        const grc = curl_url_get(u, .CURLUPART_URL, &out, get_flags);
        try std.testing.expectEqual(CURLUcode.CURLUE_OK, grc);
        defer mem.free(out);
        try std.testing.expectEqualStrings(exp, std.mem.span(out.?));
    }
}

fn expectPart(
    u: *const Curl_URL,
    part: CURLUPart,
    flags: c_uint,
    expected_code: CURLUcode,
    expected_val: ?[]const u8,
) !void {
    var out: ?[*:0]u8 = null;
    const rc = curl_url_get(u, part, &out, flags);
    defer mem.free(out);
    try std.testing.expectEqual(expected_code, rc);
    if (expected_val) |exp| {
        try std.testing.expect(out != null);
        try std.testing.expectEqualStrings(exp, std.mem.span(out.?));
    } else {
        try std.testing.expect(out == null);
    }
}

test "dedotdotify RFC 3986 path normalization (unit1395)" {
    const Case = struct {
        input: [:0]const u8,
        output: ?[]const u8,
    };
    const cases = [_]Case{
        .{ .input = "/a/b/c/./../../g", .output = "/a/g" },
        .{ .input = "mid/content=5/../6", .output = "mid/6" },
        .{ .input = "/hello/../moo", .output = "/moo" },
        .{ .input = "/1/../1", .output = "/1" },
        .{ .input = "/1/./1", .output = "/1/1" },
        .{ .input = "/1/..", .output = "/" },
        .{ .input = "/1/.", .output = "/1/" },
        .{ .input = "/1/%2e", .output = "/1/" },
        .{ .input = "/1/%2E", .output = "/1/" },
        .{ .input = "/1/./..", .output = "/" },
        .{ .input = "/1/%2e/.%2E", .output = "/" },
        .{ .input = "/1/./%2e.", .output = "/" },
        .{ .input = "/1/./../2", .output = "/2" },
        .{ .input = "/hello/1/./../2", .output = "/hello/2" },
        .{ .input = "test/this", .output = null },
        .{ .input = "test/this/../now", .output = "test/now" },
        .{ .input = ".", .output = null },
        .{ .input = "..", .output = "" },
        .{ .input = "./", .output = "" },
        .{ .input = "../", .output = "" },
        .{ .input = "../a", .output = "a" },
        .{ .input = "/.", .output = "/" },
        .{ .input = "/..", .output = "/" },
        .{ .input = "/./", .output = "/" },
        .{ .input = "/../..", .output = "/" },
        .{ .input = "/../../", .output = "/" },
        .{ .input = "/a/b/c/./../../g/", .output = "/a/g/" },
        .{ .input = "/a/b/.", .output = "/a/b/" },
        .{ .input = "/a/b/..", .output = "/a/" },
        .{ .input = "/a/%2e/g", .output = "/a/g" },
        .{ .input = "/a/%2E%2e/b", .output = "/b" },
        .{ .input = "/a/%2e./b", .output = "/b" },
        .{ .input = "/a/.%2e/b", .output = "/b" },
        .{ .input = "/%2f..%2f", .output = null },
        .{ .input = "../.well-known", .output = ".well-known" },
    };

    for (cases) |tc| {
        var out: ?[*:0]u8 = null;
        const err = dedotdotify(tc.input.ptr, tc.input.len, &out);
        defer mem.free(out);
        try std.testing.expectEqual(@as(c_int, 0), err);
        if (tc.output) |exp| {
            try std.testing.expect(out != null);
            try std.testing.expectEqualStrings(exp, std.mem.span(out.?));
        } else {
            try std.testing.expect(out == null);
        }
    }
}

test "parse_port and IPv6 bracket port parsing (unit1653)" {
    const Case = struct {
        input: [:0]const u8,
        has_scheme: bool,
        exp_code: CURLUcode,
        exp_host: []const u8,
        exp_port: u16,
        exp_present: bool,
    };
    const cases = [_]Case{
        .{ .input = "[::1]", .has_scheme = true, .exp_code = .CURLUE_OK, .exp_host = "[::1]", .exp_port = 0, .exp_present = false },
        .{ .input = "[::1]:80", .has_scheme = true, .exp_code = .CURLUE_OK, .exp_host = "[::1]", .exp_port = 80, .exp_present = true },
        .{ .input = "[::1]:", .has_scheme = true, .exp_code = .CURLUE_OK, .exp_host = "[::1]", .exp_port = 0, .exp_present = false },
        .{ .input = "[::1]:", .has_scheme = false, .exp_code = .CURLUE_BAD_PORT_NUMBER, .exp_host = "[::1]", .exp_port = 0, .exp_present = false },
        .{ .input = "[::1]:65535", .has_scheme = true, .exp_code = .CURLUE_OK, .exp_host = "[::1]", .exp_port = 65535, .exp_present = true },
        .{ .input = "[::1]:65536", .has_scheme = true, .exp_code = .CURLUE_BAD_PORT_NUMBER, .exp_host = "[::1]", .exp_port = 0, .exp_present = false },
        .{ .input = "[::1]80", .has_scheme = true, .exp_code = .CURLUE_BAD_PORT_NUMBER, .exp_host = "[::1]80", .exp_port = 0, .exp_present = false },
        .{ .input = "[::1", .has_scheme = true, .exp_code = .CURLUE_BAD_IPV6, .exp_host = "[::1", .exp_port = 0, .exp_present = false },
        .{ .input = "example.com:8080", .has_scheme = true, .exp_code = .CURLUE_OK, .exp_host = "example.com", .exp_port = 8080, .exp_present = true },
        .{ .input = "example.com:\\80", .has_scheme = true, .exp_code = .CURLUE_BACKSLASH, .exp_host = "example.com", .exp_port = 0, .exp_present = false },
        .{ .input = "example.com:80\\", .has_scheme = true, .exp_code = .CURLUE_BACKSLASH, .exp_host = "example.com", .exp_port = 0, .exp_present = false },
    };

    for (cases) |tc| {
        var u: Curl_URL = .{};
        var host: Dynbuf = undefined;
        curlx_dyn_init(&host, 1000);
        defer curlx_dyn_free(&host);
        try std.testing.expectEqual(CURLE_OK, curlx_dyn_add(&host, tc.input.ptr));

        const rc = parse_port(&u, &host, tc.has_scheme);
        try std.testing.expectEqual(tc.exp_code, rc);
        if (rc == .CURLUE_OK) {
            try std.testing.expectEqualStrings(tc.exp_host, std.mem.span(curlx_dyn_ptr(&host).?));
            try std.testing.expectEqual(tc.exp_port, u.portnum);
            try std.testing.expectEqual(tc.exp_present, u.port_present);
        }
    }
}

test "ipv4_normalize and ipv6_parse (unit1675)" {
    const V4Case = struct {
        input: [:0]const u8,
        expected_type: c_int,
        expected_host: []const u8,
    };
    const v4_cases = [_]V4Case{
        .{ .input = "192.168.0.1", .expected_type = HOST_IPV4, .expected_host = "192.168.0.1" },
        .{ .input = "192.168.0.1.", .expected_type = HOST_IPV4, .expected_host = "192.168.0.1" },
        .{ .input = "192.168.0.1..", .expected_type = HOST_NAME, .expected_host = "192.168.0.1.." },
        .{ .input = "16843009", .expected_type = HOST_IPV4, .expected_host = "1.1.1.1" },
        .{ .input = "16843009.", .expected_type = HOST_IPV4, .expected_host = "1.1.1.1" },
        .{ .input = "0x7f.1", .expected_type = HOST_IPV4, .expected_host = "127.0.0.1" },
        .{ .input = "0177.1", .expected_type = HOST_IPV4, .expected_host = "127.0.0.1" },
        .{ .input = "0177.0.0.1", .expected_type = HOST_IPV4, .expected_host = "127.0.0.1" },
        .{ .input = "127.0.1", .expected_type = HOST_IPV4, .expected_host = "127.0.0.1" },
        .{ .input = "256.0.0.1", .expected_type = HOST_NAME, .expected_host = "256.0.0.1" },
        .{ .input = "08.0.0.1", .expected_type = HOST_NAME, .expected_host = "08.0.0.1" },
        .{ .input = "example.com", .expected_type = HOST_NAME, .expected_host = "example.com" },
    };

    for (v4_cases) |tc| {
        var host: Dynbuf = undefined;
        curlx_dyn_init(&host, 1000);
        defer curlx_dyn_free(&host);
        try std.testing.expectEqual(CURLE_OK, curlx_dyn_add(&host, tc.input.ptr));
        const res = ipv4_normalize(&host);
        try std.testing.expectEqual(tc.expected_type, res);
        try std.testing.expectEqualStrings(tc.expected_host, std.mem.span(curlx_dyn_ptr(&host).?));
    }

    const V6Case = struct {
        input: [:0]const u8,
        exp_code: CURLUcode,
        exp_host: ?[]const u8,
        exp_zone: ?[]const u8,
    };
    const v6_cases = [_]V6Case{
        .{ .input = "[::1]", .exp_code = .CURLUE_OK, .exp_host = "[::1]", .exp_zone = null },
        .{ .input = "[2001:0db8:0000:0000:0000:0000:1428:57ab]", .exp_code = .CURLUE_OK, .exp_host = "[2001:db8::1428:57ab]", .exp_zone = null },
        .{ .input = "[fe80::1%eth0]", .exp_code = .CURLUE_OK, .exp_host = "[fe80::1]", .exp_zone = "eth0" },
        .{ .input = "[fe80::1%25eth0]", .exp_code = .CURLUE_OK, .exp_host = "[fe80::1]", .exp_zone = "eth0" },
        .{ .input = "[fe80::1%25]", .exp_code = .CURLUE_OK, .exp_host = "[fe80::1]", .exp_zone = "25" },
        .{ .input = "[fe80::1%]", .exp_code = .CURLUE_BAD_IPV6, .exp_host = null, .exp_zone = null },
        .{ .input = "[::]", .exp_code = .CURLUE_OK, .exp_host = "[::]", .exp_zone = null },
        .{ .input = "[:]", .exp_code = .CURLUE_BAD_IPV6, .exp_host = null, .exp_zone = null },
    };

    for (v6_cases) |tc| {
        var u: Curl_URL = .{};
        defer free_urlhandle(&u);
        var buf: [128]u8 = undefined;
        @memcpy(buf[0..tc.input.len], tc.input);
        buf[tc.input.len] = 0;

        const rc = ipv6_parse(&u, @ptrCast(&buf), tc.input.len);
        try std.testing.expectEqual(tc.exp_code, rc);
        if (tc.exp_host) |eh| {
            try std.testing.expectEqualStrings(eh, std.mem.span(@as([*:0]const u8, @ptrCast(&buf))));
        }
        if (tc.exp_zone) |ez| {
            try std.testing.expect(u.zoneid != null);
            try std.testing.expectEqualStrings(ez, std.mem.span(u.zoneid.?));
        } else {
            try std.testing.expect(u.zoneid == null);
        }
    }
}

test "URL parsing, flags, normalization, and error codes (lib1560)" {
    try expectUrl("http://example.com", 0, 0, .CURLUE_OK, "http://example.com/");
    try expectUrl("http://example.com/path/to/resource?foo=bar#frag", 0, 0, .CURLUE_OK, "http://example.com/path/to/resource?foo=bar#frag");
    try expectUrl("HTTP://EXAMPLE.COM:80/a/b/../c", 0, CURLU_NO_DEFAULT_PORT, .CURLUE_OK, "http://EXAMPLE.COM/a/c");
    try expectUrl("http://example.com/a/b/../c", CURLU_PATH_AS_IS, 0, .CURLUE_OK, "http://example.com/a/b/../c");
    try expectUrl("http://example.com", 0, CURLU_DEFAULT_PORT, .CURLUE_OK, "http://example.com:80/");
    try expectUrl("example.com/path", CURLU_DEFAULT_SCHEME, 0, .CURLUE_OK, "https://example.com/path");
    try expectUrl("ftp.example.com/path", CURLU_GUESS_SCHEME, 0, .CURLUE_OK, "ftp://ftp.example.com/path");
    try expectUrl("example.com/path", CURLU_GUESS_SCHEME, CURLU_NO_GUESS_SCHEME, .CURLUE_OK, "example.com/path");
    try expectUrl("customscheme://example.com/", 0, 0, .CURLUE_UNSUPPORTED_SCHEME, null);
    try expectUrl("customscheme://example.com/", CURLU_NON_SUPPORT_SCHEME, 0, .CURLUE_OK, "customscheme://example.com/");
    try expectUrl("http://user:pass@example.com/", CURLU_DISALLOW_USER, 0, .CURLUE_USER_NOT_ALLOWED, null);
    try expectUrl("http://127.1/path", 0, 0, .CURLUE_OK, "http://127.0.0.1/path");
    try expectUrl("http://0x7f.0x0.0x0.0x1/path", 0, 0, .CURLUE_OK, "http://127.0.0.1/path");
    try expectUrl("http://[fe80::1%25eth0]:8080/path", 0, 0, .CURLUE_OK, "http://[fe80::1%25eth0]:8080/path");
    try expectUrl("http://host/path with space?a b#c d", CURLU_URLENCODE, 0, .CURLUE_OK, "http://host/path%20with%20space?a+b#c%20d");
    try expectUrl("http://host/path with space", 0, 0, .CURLUE_BAD_PATH, null);
    try expectUrl("http://host/path with space", CURLU_ALLOW_SPACE, 0, .CURLUE_OK, "http://host/path with space");
    try expectUrl("http://host/?#", 0, 0, .CURLUE_OK, "http://host/");
    try expectUrl("http://host/?#", 0, CURLU_GET_EMPTY, .CURLUE_OK, "http://host/?#");
    try expectUrl("file:///path/to/file", 0, 0, .CURLUE_OK, "file:///path/to/file");
    try expectUrl("file://localhost/path/to/file", 0, 0, .CURLUE_OK, "file:///path/to/file");
    try expectUrl("file://badhost/path/to/file", 0, 0, .CURLUE_BAD_FILE_URL, null);
    try expectUrl("http://./", 0, 0, .CURLUE_BAD_HOSTNAME, null);
    try expectUrl("http://example.com../", 0, 0, .CURLUE_BAD_HOSTNAME, null);
    try expectUrl("http://host:65536/", 0, 0, .CURLUE_BAD_PORT_NUMBER, null);
    try expectUrl("http://host:00080/", 0, 0, .CURLUE_OK, "http://host:80/");
}

test "relative URL resolution (redirect_url)" {
    const Case = struct {
        base: [:0]const u8,
        rel: [:0]const u8,
        expected: []const u8,
    };
    const cases = [_]Case{
        .{ .base = "http://example.com/a/b/c?q=1#frag", .rel = "d/e", .expected = "http://example.com/a/b/d/e" },
        .{ .base = "http://example.com/a/b/c?q=1#frag", .rel = "/root/path", .expected = "http://example.com/root/path" },
        .{ .base = "http://example.com/a/b/c?q=1#frag", .rel = "//other.org/new", .expected = "http://other.org/new" },
        .{ .base = "http://example.com/a/b/c?q=1#frag", .rel = "?newquery", .expected = "http://example.com/a/b/c?newquery" },
        .{ .base = "http://example.com/a/b/c?q=1#frag", .rel = "#newfrag", .expected = "http://example.com/a/b/c?q=1#newfrag" },
        .{ .base = "http://example.com/a/b/c?q=1#frag", .rel = "", .expected = "http://example.com/a/b/c?q=1" },
        .{ .base = "http://example.com/a/b/c", .rel = "../g", .expected = "http://example.com/a/g" },
        .{ .base = "http://example.com/a/b/c", .rel = "../../g", .expected = "http://example.com/g" },
        .{ .base = "http://example.com/a/b/c", .rel = "../../../g", .expected = "http://example.com/g" },
    };

    for (cases) |tc| {
        const u = curl_url() orelse return error.OutOfMemory;
        defer curl_url_cleanup(u);

        try std.testing.expectEqual(CURLUcode.CURLUE_OK, curl_url_set(u, .CURLUPART_URL, tc.base.ptr, 0));
        try std.testing.expectEqual(CURLUcode.CURLUE_OK, curl_url_set(u, .CURLUPART_URL, tc.rel.ptr, 0));

        var out: ?[*:0]u8 = null;
        try std.testing.expectEqual(CURLUcode.CURLUE_OK, curl_url_get(u, .CURLUPART_URL, &out, 0));
        defer mem.free(out);
        try std.testing.expectEqualStrings(tc.expected, std.mem.span(out.?));
    }
}

test "curl_url_set, curl_url_get, curl_url_dup, query appending, and same_origin" {
    const u = curl_url() orelse return error.OutOfMemory;
    defer curl_url_cleanup(u);

    try std.testing.expectEqual(CURLUcode.CURLUE_OK, curl_url_set(u, .CURLUPART_URL, "https://user:pass@example.com:8443/p/a?k1=v1#sec", 0));
    try expectPart(u, .CURLUPART_SCHEME, 0, .CURLUE_OK, "https");
    try expectPart(u, .CURLUPART_USER, 0, .CURLUE_OK, "user");
    try expectPart(u, .CURLUPART_PASSWORD, 0, .CURLUE_OK, "pass");
    try expectPart(u, .CURLUPART_HOST, 0, .CURLUE_OK, "example.com");
    try expectPart(u, .CURLUPART_PORT, 0, .CURLUE_OK, "8443");
    try expectPart(u, .CURLUPART_PATH, 0, .CURLUE_OK, "/p/a");
    try expectPart(u, .CURLUPART_QUERY, 0, .CURLUE_OK, "k1=v1");
    try expectPart(u, .CURLUPART_FRAGMENT, 0, .CURLUE_OK, "sec");

    // Append query with URL encoding
    try std.testing.expectEqual(
        CURLUcode.CURLUE_OK,
        curl_url_set(u, .CURLUPART_QUERY, "k2=hello world&extra=1=2", CURLU_APPENDQUERY | CURLU_URLENCODE),
    );
    try expectPart(u, .CURLUPART_QUERY, 0, .CURLUE_OK, "k1=v1&k2=hello+world%26extra%3D1%3D2");
    try expectPart(u, .CURLUPART_QUERY, CURLU_URLDECODE, .CURLUE_OK, "k1=v1&k2=hello world&extra=1=2");

    // Duplicate handle and verify parts
    const dup = curl_url_dup(u) orelse return error.OutOfMemory;
    defer curl_url_cleanup(dup);
    try expectPart(dup, .CURLUPART_URL, 0, .CURLUE_OK, "https://user:pass@example.com:8443/p/a?k1=v1&k2=hello+world%26extra%3D1%3D2#sec");

    // Same origin checks
    try std.testing.expect(Curl_url_same_origin(u, dup));
    try std.testing.expectEqual(CURLUcode.CURLUE_OK, curl_url_set(dup, .CURLUPART_PORT, "443", 0));
    try std.testing.expect(!Curl_url_same_origin(u, dup));
    try std.testing.expectEqual(CURLUcode.CURLUE_OK, curl_url_set(u, .CURLUPART_PORT, null, 0));
    try std.testing.expect(Curl_url_same_origin(u, dup));

    // Port extraction
    var port: u16 = 0;
    try std.testing.expectEqual(CURLUcode.CURLUE_OK, Curl_url_get_port(u, &port));
    try std.testing.expectEqual(@as(u16, 443), port);

    // Authority update
    try std.testing.expectEqual(CURLUcode.CURLUE_OK, Curl_url_set_authority(u, "sub.example.com:9443"));
    try expectPart(u, .CURLUPART_HOST, 0, .CURLUE_OK, "sub.example.com");
    try expectPart(u, .CURLUPART_PORT, 0, .CURLUE_OK, "9443");
    try expectPart(u, .CURLUPART_USER, 0, .CURLUE_NO_USER, null);

    // Clear URL
    try std.testing.expectEqual(CURLUcode.CURLUE_OK, curl_url_set(u, .CURLUPART_URL, null, 0));
    try expectPart(u, .CURLUPART_HOST, 0, .CURLUE_NO_HOST, null);
}

test "adversarial urlapi inputs: ipv6 brackets/zones, port overflow, percent escapes, control chars" {
    const u = curl_url() orelse return error.OutOfMemory;
    defer curl_url_cleanup(u);

    // Malformed IPv6 brackets and zone IDs
    const bad_ipv6_urls = [_][*:0]const u8{
        "http://[::1/path",
        "http://[::1x]/path",
        "http://[]/path",
        "http://[fe80::1%]/path",
        "http://[fe80::1%25]/path",
        "http://[fe80::1%eth0%extra]/path",
    };
    for (bad_ipv6_urls) |bad_url| {
        try std.testing.expectEqual(CURLUcode.CURLUE_BAD_IPV6, curl_url_set(u, .CURLUPART_URL, bad_url, 0));
    }
    try std.testing.expectEqual(CURLUcode.CURLUE_BAD_PORT_NUMBER, curl_url_set(u, .CURLUPART_URL, "http://[fe80::1%eth0]extra]/path", 0));

    // Valid IPv6 with zone ID
    try std.testing.expectEqual(CURLUcode.CURLUE_OK, curl_url_set(u, .CURLUPART_URL, "http://[fe80::1%25eth0]:8080/p", 0));
    try expectPart(u, .CURLUPART_HOST, 0, .CURLUE_OK, "[fe80::1]");
    try expectPart(u, .CURLUPART_ZONEID, 0, .CURLUE_OK, "eth0");
    try expectPart(u, .CURLUPART_PORT, 0, .CURLUE_OK, "8080");

    // Port overflow: 65536 and 99999999999 and trailing garbage
    try std.testing.expectEqual(CURLUcode.CURLUE_BAD_PORT_NUMBER, curl_url_set(u, .CURLUPART_URL, "http://example.com:65536/p", 0));
    try std.testing.expectEqual(CURLUcode.CURLUE_BAD_PORT_NUMBER, curl_url_set(u, .CURLUPART_URL, "http://example.com:99999999999/p", 0));
    try std.testing.expectEqual(CURLUcode.CURLUE_BAD_PORT_NUMBER, curl_url_set(u, .CURLUPART_URL, "http://example.com:80abc/p", 0));
    try std.testing.expectEqual(CURLUcode.CURLUE_BAD_PORT_NUMBER, curl_url_set(u, .CURLUPART_PORT, "65536", 0));
    try std.testing.expectEqual(CURLUcode.CURLUE_BAD_PORT_NUMBER, curl_url_set(u, .CURLUPART_PORT, "99999999999", 0));

    // Truncated / malformed percent escapes in hostname and URL-decoded parts
    try std.testing.expectEqual(CURLUcode.CURLUE_BAD_HOSTNAME, curl_url_set(u, .CURLUPART_URL, "http://exam%ple.com/", 0));
    try std.testing.expectEqual(CURLUcode.CURLUE_BAD_HOSTNAME, curl_url_set(u, .CURLUPART_URL, "http://exam%4.com/", 0));
    try std.testing.expectEqual(CURLUcode.CURLUE_BAD_HOSTNAME, curl_url_set(u, .CURLUPART_URL, "http://exam%GGple.com/", 0));
    // Percent-encoded NUL or control char in hostname must fail
    try std.testing.expectEqual(CURLUcode.CURLUE_BAD_HOSTNAME, curl_url_set(u, .CURLUPART_URL, "http://exam%00ple.com/", 0));
    try std.testing.expectEqual(CURLUcode.CURLUE_BAD_HOSTNAME, curl_url_set(u, .CURLUPART_URL, "http://exam%0d%0aple.com/", 0));

    // Truncated percent escapes in path are preserved literally when not hex, or rejected if decoded to NUL
    try std.testing.expectEqual(CURLUcode.CURLUE_OK, curl_url_set(u, .CURLUPART_URL, "http://example.com/a%2fb%4%GG%", 0));
    try expectPart(u, .CURLUPART_PATH, 0, .CURLUE_OK, "/a%2fb%4%GG%");
    try expectPart(u, .CURLUPART_PATH, CURLU_URLDECODE, .CURLUE_OK, "/a/b%4%GG%");
    try std.testing.expectEqual(CURLUcode.CURLUE_OK, curl_url_set(u, .CURLUPART_URL, "http://example.com/nul%00byte", 0));
    try expectPart(u, .CURLUPART_PATH, CURLU_URLDECODE, .CURLUE_URLDECODE, null);

    // Control characters in URL path must be rejected with CURLUE_BAD_PATH
    try std.testing.expectEqual(CURLUcode.CURLUE_BAD_PATH, curl_url_set(u, .CURLUPART_URL, "http://example.com/path\r\ninjected", 0));
    try std.testing.expectEqual(CURLUcode.CURLUE_BAD_PATH, curl_url_set(u, .CURLUPART_URL, "http://example.com/path\x01", 0));
    try std.testing.expectEqual(CURLUcode.CURLUE_BAD_PATH, curl_url_set(u, .CURLUPART_URL, "http://example.com/path with space", 0));

    // Curl_is_absolute_url respects small buflen
    var small_buf: [3]u8 = .{ 0xAA, 0xAA, 0xAA };
    try std.testing.expectEqual(@as(usize, 0), Curl_is_absolute_url("https://example.com", &small_buf, small_buf.len, false));
    try std.testing.expectEqual(@as(u8, 0), small_buf[0]);
}
