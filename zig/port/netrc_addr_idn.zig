const std = @import("std");
const builtin = @import("builtin");
const backend_options = @import("backend_options");
const mem = @import("mem.zig");
const primitives = @import("primitives.zig");
const containers = @import("containers.zig");
const curlx_parse = @import("curlx_parse.zig");
const curlx_time_net = @import("curlx_time_net.zig");
const os_leaf = @import("os_leaf.zig");

pub const CURLcode = c_uint;
const CURLE_OK: CURLcode = 0;
const CURLE_FAILED_INIT: CURLcode = 2;
const CURLE_URL_MALFORMAT: CURLcode = 3;
const CURLE_NOT_BUILT_IN: CURLcode = 4;
const CURLE_OUT_OF_MEMORY: CURLcode = 27;
const CURLE_BAD_FUNCTION_ARGUMENT: CURLcode = 43;
const CURLE_TOO_LARGE: CURLcode = 100;

const AF_UNIX: c_int = 1;
const AF_INET: c_int = curlx_time_net.AF_INET;
const AF_INET6: c_int = curlx_time_net.AF_INET6;
const SOCK_STREAM: c_int = 1;

const EAI_MEMORY: c_int = switch (builtin.os.tag) {
    .windows => 8,
    .macos, .ios, .tvos, .watchos, .visionos => 6,
    else => -10,
};

const EAI_NONAME: c_int = switch (builtin.os.tag) {
    .windows => 11001,
    .macos, .ios, .tvos, .watchos, .visionos => 8,
    else => -2,
};

// ============================================================================
// 1. lib/idn.c (lib/idn.h)
// ============================================================================

pub const Hostname = extern struct {
    rawalloc: ?[*:0]u8,
    encalloc: ?[*:0]u8,
    name: ?[*:0]u8,
    dispname: ?[*:0]const u8,
};

pub export fn Curl_is_ASCII_str(s_opt: ?*const curlx_parse.Curl_str) callconv(.c) bool {
    const s = s_opt orelse return true;
    if (s.len > 0) {
        const ch = s.str orelse return true;
        for (0..s.len) |i| {
            if ((ch[i] & 0x80) != 0) {
                return false;
            }
        }
    }
    return true;
}

pub export fn Curl_is_ASCII_name(hostname_opt: ?[*:0]const u8) callconv(.c) bool {
    if (hostname_opt) |hostname| {
        var s = curlx_parse.Curl_str{
            .str = hostname,
            .len = std.mem.len(hostname),
        };
        return Curl_is_ASCII_str(&s);
    }
    return true;
}

const libidn2 = struct {
    const IDN2_VERSION: [*:0]const u8 = "2.0.0";
    const IDN2_NFC_INPUT: c_int = 1;
    const IDN2_TRANSITIONAL: c_int = 4;
    const IDN2_NONTRANSITIONAL: c_int = 8;
    const IDN2_OK: c_int = 0;
    const IDN2_MALLOC: c_int = -100;

    extern fn idn2_check_version(req_version: ?[*:0]const u8) callconv(.c) ?[*:0]const u8;
    extern fn idn2_lookup_ul(src: [*:0]const u8, lookupname: *?[*:0]u8, flags: c_int) callconv(.c) c_int;
    extern fn idn2_to_unicode_8z8z(input: [*:0]const u8, output: *?[*:0]u8, flags: c_int) callconv(.c) c_int;
    extern fn idn2_free(ptr: ?*anyopaque) callconv(.c) void;
};

const winidn = struct {
    const CP_UTF8: u32 = 65001;
    const MB_ERR_INVALID_CHARS: u32 = 0x00000008;
    const IDN_MAX_LENGTH: c_int = 255;

    extern "kernel32" fn MultiByteToWideChar(
        CodePage: u32,
        dwFlags: u32,
        lpMultiByteStr: [*:0]const u8,
        cbMultiByte: c_int,
        lpWideCharStr: ?[*]u16,
        cchWideChar: c_int,
    ) callconv(.winapi) c_int;

    extern "kernel32" fn WideCharToMultiByte(
        CodePage: u32,
        dwFlags: u32,
        lpWideCharStr: [*]const u16,
        cchWideChar: c_int,
        lpMultiByteStr: ?[*]u8,
        cbMultiByte: c_int,
        lpDefaultChar: ?[*:0]const u8,
        lpUsedDefaultChar: ?*c_int,
    ) callconv(.winapi) c_int;

    extern "normaliz" fn IdnToAscii(
        dwFlags: u32,
        lpUnicodeCharStr: [*]const u16,
        cchUnicodeChar: c_int,
        lpASCIICharStr: ?[*]u16,
        cchASCIIChar: c_int,
    ) callconv(.winapi) c_int;

    extern "normaliz" fn IdnToUnicode(
        dwFlags: u32,
        lpASCIICharStr: [*]const u16,
        cchASCIIChar: c_int,
        lpUnicodeCharStr: ?[*]u16,
        cchUnicodeChar: c_int,
    ) callconv(.winapi) c_int;

    fn convertWcharToUtf8(str_w: [*]const u16, chars: c_int) ?[*:0]u8 {
        const bytes = WideCharToMultiByte(CP_UTF8, 0, str_w, chars, null, 0, null, null);
        if (bytes > 0) {
            const str_utf8 = mem.malloc(@intCast(bytes)) orelse return null;
            if (WideCharToMultiByte(CP_UTF8, 0, str_w, chars, str_utf8, bytes, null, null) == 0) {
                mem.free(str_utf8);
                return null;
            }
            return @ptrCast(str_utf8);
        }
        return null;
    }

    fn win32_idn_to_ascii(in: [*:0]const u8, out: *?[*:0]u8) CURLcode {
        var in_w: [IDN_MAX_LENGTH]u16 = undefined;
        out.* = null;
        const in_w_len = MultiByteToWideChar(CP_UTF8, MB_ERR_INVALID_CHARS, in, -1, &in_w, IDN_MAX_LENGTH);
        if (in_w_len != 0) {
            var punycode: [IDN_MAX_LENGTH]u16 = undefined;
            const chars = IdnToAscii(0, &in_w, in_w_len, &punycode, IDN_MAX_LENGTH);
            if (chars > 0) {
                out.* = convertWcharToUtf8(&punycode, chars) orelse return CURLE_OUT_OF_MEMORY;
                return CURLE_OK;
            }
        }
        return CURLE_URL_MALFORMAT;
    }

    fn win32_ascii_to_idn(in: [*:0]const u8, out: *?[*:0]u8) CURLcode {
        var in_w: [IDN_MAX_LENGTH]u16 = undefined;
        out.* = null;
        const in_w_len = MultiByteToWideChar(CP_UTF8, MB_ERR_INVALID_CHARS, in, -1, &in_w, IDN_MAX_LENGTH);
        if (in_w_len != 0) {
            var idn: [IDN_MAX_LENGTH]u16 = undefined;
            const chars = IdnToUnicode(0, &in_w, in_w_len, &idn, IDN_MAX_LENGTH);
            if (chars > 0) {
                out.* = convertWcharToUtf8(&idn, chars) orelse return CURLE_OUT_OF_MEMORY;
                return CURLE_OK;
            }
        }
        return CURLE_URL_MALFORMAT;
    }
};

const appleidn = struct {
    const CODESET: c_int = 0;
    const MAX_HOST_LENGTH: usize = 512;
    const U_ZERO_ERROR: c_int = 0;
    const UIDNA_CHECK_BIDI: u32 = 4;
    const UIDNA_CHECK_CONTEXTJ: u32 = 8;
    const UIDNA_NONTRANSITIONAL_TO_ASCII: u32 = 0x10;
    const UIDNA_NONTRANSITIONAL_TO_UNICODE: u32 = 0x20;
    const UIDNA_ERROR_EMPTY_LABEL: u32 = 1;

    const UIDNAInfo = extern struct {
        size: i16 = @sizeOf(UIDNAInfo),
        isTransitionalDifferent: i8 = 0,
        errors: u32 = 0,
        reservedI2: i32 = 0,
        reservedI3: i32 = 0,
    };

    extern fn nl_langinfo(item: c_int) callconv(.c) [*:0]const u8;
    extern fn iconv_open(tocode: [*:0]const u8, fromcode: [*:0]const u8) callconv(.c) usize;
    extern fn iconv(cd: usize, inbuf: *?[*]const u8, inbytesleft: *usize, outbuf: *?[*]u8, outbytesleft: *usize) callconv(.c) usize;
    extern fn iconv_close(cd: usize) callconv(.c) c_int;
    extern fn uidna_openUTS46(options: u32, pErrorCode: *c_int) callconv(.c) ?*anyopaque;
    extern fn uidna_close(idna: ?*anyopaque) callconv(.c) void;
    extern fn uidna_nameToASCII_UTF8(
        idna: ?*anyopaque,
        name: [*]const u8,
        length: c_int,
        dest: [*]u8,
        capacity: c_int,
        pInfo: *UIDNAInfo,
        pErrorCode: *c_int,
    ) callconv(.c) c_int;
    extern fn uidna_nameToUnicodeUTF8(
        idna: ?*anyopaque,
        name: [*]const u8,
        length: c_int,
        dest: [*]u8,
        capacity: c_int,
        pInfo: *UIDNAInfo,
        pErrorCode: *c_int,
    ) callconv(.c) c_int;

    fn iconvToUtf8(in: [*]const u8, inlen: usize, out: *?[*]u8, outlen: *usize) CURLcode {
        const invalid_cd: usize = std.math.maxInt(usize);
        const cd = iconv_open("UTF-8", nl_langinfo(CODESET));
        if (cd != invalid_cd) {
            var iconv_outlen = outlen.*;
            var iconv_in: ?[*]const u8 = in;
            var iconv_inlen = inlen;
            const iconv_result = iconv(cd, &iconv_in, &iconv_inlen, out, &iconv_outlen);
            outlen.* -= iconv_outlen;
            _ = iconv_close(cd);
            if (iconv_result == invalid_cd) {
                return if (std.c._errno().* == @backingInt(std.c.E.NOMEM))
                    CURLE_OUT_OF_MEMORY
                else
                    CURLE_URL_MALFORMAT;
            }
            return CURLE_OK;
        } else {
            return if (std.c._errno().* == @backingInt(std.c.E.NOMEM))
                CURLE_OUT_OF_MEMORY
            else
                CURLE_FAILED_INIT;
        }
    }

    fn mac_idn_to_ascii(in: [*:0]const u8, out: *?[*:0]u8) CURLcode {
        const inlen = std.mem.len(in);
        if (inlen < MAX_HOST_LENGTH) {
            var iconv_buffer: [MAX_HOST_LENGTH]u8 = @splat(0);
            var iconv_outptr: ?[*]u8 = &iconv_buffer;
            var iconv_outlen: usize = iconv_buffer.len;
            const iconv_result = iconvToUtf8(in, inlen, &iconv_outptr, &iconv_outlen);
            if (iconv_result == CURLE_OK) {
                var err: c_int = U_ZERO_ERROR;
                const idna = uidna_openUTS46(UIDNA_CHECK_BIDI | UIDNA_NONTRANSITIONAL_TO_ASCII, &err);
                if (err <= U_ZERO_ERROR) {
                    var info: UIDNAInfo = .{};
                    var buffer: [MAX_HOST_LENGTH]u8 = @splat(0);
                    _ = uidna_nameToASCII_UTF8(
                        idna,
                        &iconv_buffer,
                        @intCast(iconv_outlen),
                        &buffer,
                        @intCast(buffer.len - 1),
                        &info,
                        &err,
                    );
                    uidna_close(idna);
                    if (err <= U_ZERO_ERROR and info.errors == 0) {
                        out.* = mem.strdup(@ptrCast(&buffer)) orelse return CURLE_OUT_OF_MEMORY;
                        return CURLE_OK;
                    }
                }
            } else {
                return iconv_result;
            }
        }
        return CURLE_URL_MALFORMAT;
    }

    fn mac_ascii_to_idn(in: [*:0]const u8, out: *?[*:0]u8) CURLcode {
        const inlen = std.mem.len(in);
        if (inlen < MAX_HOST_LENGTH) {
            var err: c_int = U_ZERO_ERROR;
            const idna = uidna_openUTS46(UIDNA_CHECK_BIDI | UIDNA_NONTRANSITIONAL_TO_UNICODE, &err);
            if (err <= U_ZERO_ERROR) {
                var info: UIDNAInfo = .{};
                var buffer: [MAX_HOST_LENGTH]u8 = @splat(0);
                _ = uidna_nameToUnicodeUTF8(
                    idna,
                    in,
                    -1,
                    &buffer,
                    @intCast(buffer.len - 1),
                    &info,
                    &err,
                );
                uidna_close(idna);
                if (err <= U_ZERO_ERROR) {
                    out.* = mem.strdup(@ptrCast(&buffer)) orelse return CURLE_OUT_OF_MEMORY;
                    return CURLE_OK;
                }
            }
        }
        return CURLE_URL_MALFORMAT;
    }
};

fn idn_decode(input: [*:0]const u8, output: *?[*:0]u8) CURLcode {
    if (comptime (backend_options.idn == .libidn2)) {
        if (libidn2.idn2_check_version(null) != null) {
            var decoded: ?[*:0]u8 = null;
            const flags: c_int = libidn2.IDN2_NFC_INPUT | libidn2.IDN2_NONTRANSITIONAL;
            var rc = libidn2.idn2_lookup_ul(input, &decoded, flags);
            if (rc != libidn2.IDN2_OK) {
                rc = libidn2.idn2_lookup_ul(input, &decoded, libidn2.IDN2_TRANSITIONAL);
            }
            if (rc == libidn2.IDN2_OK) {
                output.* = decoded;
                return CURLE_OK;
            } else if (rc == libidn2.IDN2_MALLOC) {
                return CURLE_OUT_OF_MEMORY;
            } else {
                return CURLE_URL_MALFORMAT;
            }
        }
        return CURLE_NOT_BUILT_IN;
    } else if (comptime (backend_options.idn == .winidn and builtin.os.tag == .windows)) {
        return winidn.win32_idn_to_ascii(input, output);
    } else if (comptime (backend_options.idn == .appleidn and builtin.os.tag.isDarwin())) {
        return appleidn.mac_idn_to_ascii(input, output);
    } else {
        return CURLE_NOT_BUILT_IN;
    }
}

fn idn_encode(puny: [*:0]const u8, output: *?[*:0]u8) CURLcode {
    if (comptime (backend_options.idn == .libidn2)) {
        var enc: ?[*:0]u8 = null;
        const rc = libidn2.idn2_to_unicode_8z8z(puny, &enc, 0);
        if (rc == libidn2.IDN2_OK) {
            output.* = enc;
            return CURLE_OK;
        } else if (rc == libidn2.IDN2_MALLOC) {
            return CURLE_OUT_OF_MEMORY;
        } else {
            return CURLE_URL_MALFORMAT;
        }
    } else if (comptime (backend_options.idn == .winidn and builtin.os.tag == .windows)) {
        return winidn.win32_ascii_to_idn(puny, output);
    } else if (comptime (backend_options.idn == .appleidn and builtin.os.tag.isDarwin())) {
        return appleidn.mac_ascii_to_idn(puny, output);
    } else {
        return CURLE_NOT_BUILT_IN;
    }
}

pub export fn Curl_idn_decode(input: [*:0]const u8, output: *?[*:0]u8) callconv(.c) CURLcode {
    if (comptime (backend_options.idn != .none)) {
        var d: ?[*:0]u8 = null;
        var result = idn_decode(input, &d);
        if (result == CURLE_OK) {
            if (comptime (backend_options.idn == .libidn2)) {
                const c = mem.strdup(d.?);
                libidn2.idn2_free(d);
                if (c != null) {
                    d = c;
                } else {
                    result = CURLE_OUT_OF_MEMORY;
                }
            }
            if (result == CURLE_OK and d.?[0] == 0) {
                mem.free(d);
                return CURLE_URL_MALFORMAT;
            }
        }
        if (result == CURLE_OK) {
            output.* = d;
        }
        return result;
    } else {
        return CURLE_NOT_BUILT_IN;
    }
}

pub export fn Curl_idn_encode(puny: [*:0]const u8, output: *?[*:0]u8) callconv(.c) CURLcode {
    if (comptime (backend_options.idn != .none)) {
        var d: ?[*:0]u8 = null;
        var result = idn_encode(puny, &d);
        if (result == CURLE_OK and comptime (backend_options.idn == .libidn2)) {
            const c = mem.strdup(d.?);
            libidn2.idn2_free(d);
            if (c != null) {
                d = c;
            } else {
                result = CURLE_OUT_OF_MEMORY;
            }
        }
        if (result == CURLE_OK) {
            output.* = d;
        }
        return result;
    } else {
        return CURLE_NOT_BUILT_IN;
    }
}

pub export fn Curl_idnconvert_hostname(host: ?*Hostname) callconv(.c) CURLcode {
    const h = host orelse return CURLE_OK;
    const name = h.name orelse return CURLE_OK;
    h.dispname = name;
    if (comptime (backend_options.idn != .none)) {
        if (!Curl_is_ASCII_name(name)) {
            var decoded: ?[*:0]u8 = null;
            const result = Curl_idn_decode(name, &decoded);
            if (result == CURLE_OK) {
                h.encalloc = decoded;
                h.name = decoded;
            }
            return result;
        }
    }
    return CURLE_OK;
}

pub export fn Curl_free_idnconverted_hostname(host: ?*Hostname) callconv(.c) void {
    if (comptime (backend_options.idn != .none)) {
        if (host) |h| {
            if (h.encalloc) |p| {
                mem.free(p);
                h.encalloc = null;
            }
        }
    }
}

// ============================================================================
// 2. lib/curl_addrinfo.c & lib/fake_addrinfo.c
// ============================================================================

pub const curl_socklen_t = if (builtin.os.tag == .windows) c_int else u32;

pub const Curl_addrinfo = extern struct {
    ai_flags: c_int,
    ai_family: c_int,
    ai_socktype: c_int,
    ai_protocol: c_int,
    ai_addrlen: curl_socklen_t,
    ai_canonname: ?[*:0]u8,
    ai_addr: ?*anyopaque,
    ai_next: ?*Curl_addrinfo,
};

pub const SysAddrinfo = if (builtin.os.tag == .windows)
    extern struct {
        ai_flags: c_int,
        ai_family: c_int,
        ai_socktype: c_int,
        ai_protocol: c_int,
        ai_addrlen: usize,
        ai_canonname: ?[*:0]u8,
        ai_addr: ?*anyopaque,
        ai_next: ?*SysAddrinfo,
    }
else if (builtin.os.tag.isDarwin())
    extern struct {
        ai_flags: c_int,
        ai_family: c_int,
        ai_socktype: c_int,
        ai_protocol: c_int,
        ai_addrlen: u32,
        ai_canonname: ?[*:0]u8,
        ai_addr: ?*anyopaque,
        ai_next: ?*SysAddrinfo,
    }
else
    extern struct {
        ai_flags: c_int,
        ai_family: c_int,
        ai_socktype: c_int,
        ai_protocol: c_int,
        ai_addrlen: u32,
        ai_addr: ?*anyopaque,
        ai_canonname: ?[*:0]u8,
        ai_next: ?*SysAddrinfo,
    };

const SockaddrIn = if (builtin.os.tag.isDarwin())
    extern struct {
        sin_len: u8,
        sin_family: u8,
        sin_port: u16,
        sin_addr: [4]u8,
        sin_zero: [8]u8,
    }
else
    extern struct {
        sin_family: u16,
        sin_port: u16,
        sin_addr: [4]u8,
        sin_zero: [8]u8,
    };

const SockaddrIn6 = if (builtin.os.tag.isDarwin())
    extern struct {
        sin6_len: u8,
        sin6_family: u8,
        sin6_port: u16,
        sin6_flowinfo: u32,
        sin6_addr: [16]u8,
        sin6_scope_id: u32,
    }
else
    extern struct {
        sin6_family: u16,
        sin6_port: u16,
        sin6_flowinfo: u32,
        sin6_addr: [16]u8,
        sin6_scope_id: u32,
    };

const SockaddrUn = if (builtin.os.tag.isDarwin())
    extern struct {
        sun_len: u8,
        sun_family: u8,
        sun_path: [104]u8,
    }
else
    extern struct {
        sun_family: u16,
        sun_path: [108]u8,
    };

const win32_net = struct {
    extern "ws2_32" fn getaddrinfo(
        nodename: ?[*:0]const u8,
        servname: ?[*:0]const u8,
        hints: ?*const SysAddrinfo,
        res: *?*SysAddrinfo,
    ) callconv(.winapi) c_int;
    extern "ws2_32" fn freeaddrinfo(ai: ?*SysAddrinfo) callconv(.winapi) void;
    extern "ws2_32" fn WSASetLastError(iError: c_int) callconv(.winapi) void;
};

const posix_net = struct {
    extern "c" fn getaddrinfo(
        nodename: ?[*:0]const u8,
        servname: ?[*:0]const u8,
        hints: ?*const SysAddrinfo,
        res: *?*SysAddrinfo,
    ) callconv(.c) c_int;
    extern "c" fn freeaddrinfo(ai: ?*SysAddrinfo) callconv(.c) void;
};

pub export fn Curl_freeaddrinfo(cahead: ?*Curl_addrinfo) callconv(.c) void {
    var ca = cahead;
    while (ca) |curr| {
        const canext = curr.ai_next;
        mem.free(@ptrCast(curr));
        ca = canext;
    }
}

pub export fn Curl_addrinfo_get(ai_head: ?*Curl_addrinfo, ai_family: c_int, n: c_uint) callconv(.c) ?*Curl_addrinfo {
    var i: c_uint = 0;
    var ai = ai_head;
    while (ai) |curr| : (ai = curr.ai_next) {
        if (curr.ai_family == ai_family) {
            if (i == n) return curr;
            i += 1;
        }
    }
    return null;
}

pub export fn Curl_getaddrinfo_ex(
    nodename: ?[*:0]const u8,
    servname: ?[*:0]const u8,
    hints: ?*const SysAddrinfo,
    result: *?*Curl_addrinfo,
) callconv(.c) c_int {
    var aihead: ?*SysAddrinfo = null;
    var cafirst: ?*Curl_addrinfo = null;
    var calast: ?*Curl_addrinfo = null;

    result.* = null;

    var err: c_int = if (builtin.os.tag == .windows)
        win32_net.getaddrinfo(nodename, servname, hints, &aihead)
    else
        posix_net.getaddrinfo(nodename, servname, hints, &aihead);
    if (err != 0) return err;

    var ai_opt = aihead;
    while (ai_opt) |ai| : (ai_opt = ai.ai_next) {
        const namelen: usize = if (ai.ai_canonname) |cn| std.mem.len(cn) + 1 else 0;
        const ss_size: usize = if (ai.ai_family == AF_INET)
            @sizeOf(SockaddrIn)
        else if (ai.ai_family == AF_INET6)
            @sizeOf(SockaddrIn6)
        else
            continue;

        const ai_addr = ai.ai_addr orelse continue;
        if (ai.ai_addrlen <= 0) continue;
        if (@as(usize, @intCast(ai.ai_addrlen)) < ss_size) continue;

        const total_size = @sizeOf(Curl_addrinfo) + ss_size + namelen;
        const raw = mem.malloc(total_size) orelse {
            err = EAI_MEMORY;
            break;
        };
        const ca: *Curl_addrinfo = @ptrCast(@alignCast(raw));

        ca.ai_flags = ai.ai_flags;
        ca.ai_family = ai.ai_family;
        ca.ai_socktype = ai.ai_socktype;
        ca.ai_protocol = ai.ai_protocol;
        ca.ai_addrlen = @intCast(ss_size);
        ca.ai_addr = null;
        ca.ai_canonname = null;
        ca.ai_next = null;

        const addr_ptr = raw + @sizeOf(Curl_addrinfo);
        ca.ai_addr = @ptrCast(addr_ptr);
        const src_addr: [*]const u8 = @ptrCast(ai_addr);
        @memcpy(addr_ptr[0..ss_size], src_addr[0..ss_size]);

        if (namelen > 0) {
            const cn_ptr = addr_ptr + ss_size;
            ca.ai_canonname = @ptrCast(cn_ptr);
            const src_cn: [*]const u8 = @ptrCast(ai.ai_canonname.?);
            @memcpy(cn_ptr[0..namelen], src_cn[0..namelen]);
        }

        if (cafirst == null) {
            cafirst = ca;
        }
        if (calast) |last| {
            last.ai_next = ca;
        }
        calast = ca;
    }

    if (aihead) |head| {
        if (builtin.os.tag == .windows)
            win32_net.freeaddrinfo(head)
        else
            posix_net.freeaddrinfo(head);
    }

    if (err != 0) {
        Curl_freeaddrinfo(cafirst);
        cafirst = null;
    } else if (cafirst == null) {
        err = EAI_NONAME;
        if (builtin.os.tag == .windows) {
            win32_net.WSASetLastError(err);
        }
    }

    result.* = cafirst;
    return err;
}

fn ip2addr(
    addrp: *?*Curl_addrinfo,
    af: c_int,
    inaddr: *const anyopaque,
    hostname: [*:0]const u8,
    port: u16,
) c_uint {
    const namelen = std.mem.len(hostname) + 1;
    addrp.* = null;

    const addrsize: usize = if (af == AF_INET)
        @sizeOf(SockaddrIn)
    else if (af == AF_INET6)
        @sizeOf(SockaddrIn6)
    else
        return CURLE_BAD_FUNCTION_ARGUMENT;

    const raw = mem.calloc(1, @sizeOf(Curl_addrinfo) + addrsize + namelen) orelse return CURLE_OUT_OF_MEMORY;
    const ai: *Curl_addrinfo = @ptrCast(@alignCast(raw));
    const addr_ptr = raw + @sizeOf(Curl_addrinfo);
    const cn_ptr = addr_ptr + addrsize;

    ai.ai_addr = @ptrCast(addr_ptr);
    ai.ai_canonname = @ptrCast(cn_ptr);
    @memcpy(cn_ptr[0..namelen], hostname[0..namelen]);
    ai.ai_family = af;
    ai.ai_socktype = SOCK_STREAM;
    ai.ai_addrlen = @intCast(addrsize);

    const net_port = std.mem.nativeToBig(u16, port);
    const in_bytes: [*]const u8 = @ptrCast(inaddr);

    if (af == AF_INET) {
        const addr: *SockaddrIn = @ptrCast(@alignCast(addr_ptr));
        @memcpy(&addr.sin_addr, in_bytes[0..4]);
        addr.sin_family = @intCast(af);
        addr.sin_port = net_port;
    } else if (af == AF_INET6) {
        const addr6: *SockaddrIn6 = @ptrCast(@alignCast(addr_ptr));
        @memcpy(&addr6.sin6_addr, in_bytes[0..16]);
        addr6.sin6_family = @intCast(af);
        addr6.sin6_port = net_port;
    }

    addrp.* = ai;
    return CURLE_OK;
}

pub export fn Curl_str2addr(dotted: [*:0]const u8, port: u16, addrp: *?*Curl_addrinfo) callconv(.c) c_uint {
    var in4: [4]u8 = undefined;
    if (curlx_time_net.curlx_inet_pton(AF_INET, dotted, &in4) > 0) {
        return ip2addr(addrp, AF_INET, &in4, dotted, port);
    }
    var in6: [16]u8 = undefined;
    if (curlx_time_net.curlx_inet_pton(AF_INET6, dotted, &in6) > 0) {
        return ip2addr(addrp, AF_INET6, &in6, dotted, port);
    }
    return CURLE_BAD_FUNCTION_ARGUMENT;
}

pub export fn Curl_is_ipv4addr(address: [*:0]const u8) callconv(.c) bool {
    var in4: [4]u8 = undefined;
    return curlx_time_net.curlx_inet_pton(AF_INET, address, &in4) > 0;
}

pub export fn Curl_is_ipaddr(address: [*:0]const u8) callconv(.c) bool {
    if (Curl_is_ipv4addr(address)) return true;
    var in6: [16]u8 = undefined;
    if (curlx_time_net.curlx_inet_pton(AF_INET6, address, &in6) > 0) return true;
    return false;
}

pub export fn Curl_looks_like_ipv6(
    s: [*]const u8,
    len: usize,
    maybe_url_encoded: bool,
    host_opt: ?*curlx_parse.Curl_str,
    zone_opt: ?*curlx_parse.Curl_str,
) callconv(.c) bool {
    var zonep: ?[*]const u8 = null;
    var i: usize = 0;
    var hlen: usize = 0;
    var zlen: usize = 0;

    if (host_opt) |host| {
        host.str = null;
        host.len = 0;
    }
    if (zone_opt) |zone| {
        zone.str = null;
        zone.len = 0;
    }

    while (i < len) : ({
        i += 1;
        hlen += 1;
    }) {
        const c = s[i];
        if (c == 0 or !(std.ascii.isHex(c) or c == ':' or c == '.'))
            break;
    }

    if (i < len and s[i] == '%') {
        i += 1;
        if (maybe_url_encoded and i + 2 <= len and s[i] == '2' and s[i + 1] == '5') {
            i += 2;
        }
        zonep = s + i;
        while (i < len) : ({
            i += 1;
            zlen += 1;
        }) {
            const c = s[i];
            if (c == 0 or !(std.ascii.isAlphabetic(c) or std.ascii.isHex(c) or c == '-' or c == '.' or c == '_' or c == '~'))
                break;
        }
    }

    if (i != len)
        return false;
    if (host_opt) |host| {
        if (hlen > 0) {
            host.str = s;
            host.len = hlen;
        }
    }
    if (zone_opt) |zone| {
        if (zlen > 0) {
            zone.str = zonep;
            zone.len = zlen;
        }
    }
    return true;
}

pub export fn Curl_unix2addr(path: [*:0]const u8, abstract: bool, paddr: *?*Curl_addrinfo) callconv(.c) c_uint {
    paddr.* = null;

    const path_len = std.mem.len(path) + 1;
    const max_sun_path = @sizeOf(@FieldType(SockaddrUn, "sun_path"));
    if (path_len > max_sun_path)
        return CURLE_TOO_LARGE;

    const raw = mem.calloc(1, @sizeOf(Curl_addrinfo) + @sizeOf(SockaddrUn)) orelse return CURLE_OUT_OF_MEMORY;
    const ai: *Curl_addrinfo = @ptrCast(@alignCast(raw));
    const addr_ptr = raw + @sizeOf(Curl_addrinfo);

    ai.ai_addr = @ptrCast(addr_ptr);
    const sa_un: *SockaddrUn = @ptrCast(@alignCast(addr_ptr));
    sa_un.sun_family = @intCast(AF_UNIX);

    ai.ai_family = AF_UNIX;
    ai.ai_socktype = SOCK_STREAM;
    ai.ai_addrlen = @intCast((@offsetOf(SockaddrUn, "sun_path") + path_len) & 0x7FFFFFFF);

    if (abstract) {
        if (path_len > 1) {
            @memcpy(sa_un.sun_path[1..path_len], path[0 .. path_len - 1]);
        }
    } else {
        @memcpy(sa_un.sun_path[0..path_len], path[0..path_len]);
    }

    paddr.* = ai;
    return CURLE_OK;
}

pub export fn Curl_addrinfo_set_port(addrinfo: ?*Curl_addrinfo, port: c_int) callconv(.c) void {
    const net_port = std.mem.nativeToBig(u16, @truncate(@as(c_uint, @bitCast(port))));
    var ca = addrinfo;
    while (ca) |curr| : (ca = curr.ai_next) {
        const addr_ptr = curr.ai_addr orelse continue;
        if (curr.ai_family == AF_INET) {
            const addr: *SockaddrIn = @ptrCast(@alignCast(addr_ptr));
            addr.sin_port = net_port;
        } else if (curr.ai_family == AF_INET6) {
            const addr6: *SockaddrIn6 = @ptrCast(@alignCast(addr_ptr));
            addr6.sin6_port = net_port;
        }
    }
}

// ============================================================================
// 3. lib/netrc.c (lib/netrc.h)
// ============================================================================

const MAX_NETRC_LINE: usize = 16384;
const MAX_NETRC_FILE: usize = 128 * 1024;
const MAX_NETRC_TOKEN: usize = 4096;

pub const NETRC_OK: c_uint = 0;
pub const NETRC_NO_MATCH: c_uint = 1;
pub const NETRC_SYNTAX_ERROR: c_uint = 2;
pub const NETRC_FILE_MISSING: c_uint = 3;
pub const NETRC_OUT_OF_MEMORY: c_uint = 4;
pub const NETRC_LAST: c_uint = 5;

const CREDS_NETRC: u8 = 3;

pub const StoreNetrc = extern struct {
    filebuf: os_leaf.Dynbuf,
    filename: ?[*:0]u8,
    loaded_bits: c_uint,
};

extern fn curlx_dyn_init(s: *os_leaf.Dynbuf, toobig: usize) callconv(.c) void;
extern fn curlx_dyn_free(s: *os_leaf.Dynbuf) callconv(.c) void;
extern fn curlx_dyn_reset(s: *os_leaf.Dynbuf) callconv(.c) void;
extern fn curlx_dyn_addn(s: *os_leaf.Dynbuf, mem: *const anyopaque, len: usize) callconv(.c) c_uint;
extern fn curlx_dyn_add(s: *os_leaf.Dynbuf, str: [*:0]const u8) callconv(.c) c_uint;
extern fn curlx_dyn_len(s: *const os_leaf.Dynbuf) callconv(.c) usize;
extern fn curlx_dyn_ptr(s: *const os_leaf.Dynbuf) callconv(.c) ?[*:0]u8;

extern fn Curl_creds_create(
    user: ?[*:0]const u8,
    passwd: ?[*:0]const u8,
    oauth_bearer: ?[*:0]const u8,
    sasl_authzid: ?[*:0]const u8,
    sasl_service: ?[*:0]const u8,
    source: u8,
    pcreds: *?*anyopaque,
) callconv(.c) c_uint;
extern fn Curl_creds_link(pdest: *?*anyopaque, src: ?*anyopaque) callconv(.c) void;
extern fn Curl_creds_unlink(pcreds: *?*anyopaque) callconv(.c) void;
extern fn Curl_trc_multi(data: ?*anyopaque, fmt: [*:0]const u8, ...) callconv(.c) void;

const Passwd = if (builtin.os.tag.isDarwin())
    extern struct {
        pw_name: ?[*:0]u8,
        pw_passwd: ?[*:0]u8,
        pw_uid: u32,
        pw_gid: u32,
        pw_change: isize,
        pw_class: ?[*:0]u8,
        pw_gecos: ?[*:0]u8,
        pw_dir: ?[*:0]u8,
        pw_shell: ?[*:0]u8,
        pw_expire: isize,
        pw_fields: c_int,
    }
else
    extern struct {
        pw_name: ?[*:0]u8,
        pw_passwd: ?[*:0]u8,
        pw_uid: u32,
        pw_gid: u32,
        pw_gecos: ?[*:0]u8,
        pw_dir: ?[*:0]u8,
        pw_shell: ?[*:0]u8,
    };

const netrc_posix_c = struct {
    extern "c" fn fopen(pathname: [*:0]const u8, mode: [*:0]const u8) ?*anyopaque;
    extern "c" fn fclose(stream: ?*anyopaque) c_int;
    extern "c" fn opendir(name: [*:0]const u8) ?*anyopaque;
    extern "c" fn closedir(dirp: *anyopaque) c_int;
    extern "c" fn geteuid() u32;
    extern "c" fn getpwuid_r(uid: u32, pwd: *Passwd, buf: [*]u8, buflen: usize, result: *?*Passwd) c_int;
};

const netrc_win32_c = struct {
    extern "c" fn fclose(stream: ?*anyopaque) c_int;
    extern "c" fn _fileno(stream: ?*anyopaque) c_int;
    extern "c" fn _fstati64(fd: c_int, buffer: *Win32Stat64) c_int;
    extern fn curlx_win32_fopen(filename: ?[*:0]const u8, mode: ?[*:0]const u8) callconv(.c) ?*anyopaque;

    const Win32Stat64 = extern struct {
        st_dev: u32,
        st_ino: u16,
        st_mode: u16,
        st_nlink: i16,
        st_uid: i16,
        st_gid: i16,
        st_rdev: u32,
        st_size: i64,
        st_atime: i64,
        st_mtime: i64,
        st_ctime: i64,
    };
};

inline fn curl2netrc(r: c_uint) c_uint {
    if (r == CURLE_OK) return NETRC_OK;
    return if (r == CURLE_OUT_OF_MEMORY) NETRC_OUT_OF_MEMORY else NETRC_SYNTAX_ERROR;
}

inline fn isBlank(c: u8) bool {
    return c == ' ' or c == '\t';
}

inline fn isNewline(c: u8) bool {
    return c == '\r' or c == '\n';
}

fn passBlanks(s: *[*:0]const u8) void {
    var p = s.*;
    while (isBlank(p[0])) {
        p += 1;
    }
    s.* = p;
}

const NetrcToken = enum(c_uint) {
    eof = 0,
    literal,
    machine,
    default_tok,
    account,
    login,
    passwd,
    macdef,
    junk,
};

const NetrcLexer = struct {
    data: ?*anyopaque,
    content: [*:0]const u8,
    pos: [*:0]const u8,
    literal: os_leaf.Dynbuf,
    token: NetrcToken,
    pushed: bool,
};

fn netrcLexerInit(lexer: *NetrcLexer, data: ?*anyopaque, content: [*:0]const u8) void {
    lexer.data = data;
    lexer.content = content;
    lexer.pos = content;
    lexer.literal = std.mem.zeroes(os_leaf.Dynbuf);
    curlx_dyn_init(&lexer.literal, MAX_NETRC_TOKEN);
    lexer.token = .eof;
    lexer.pushed = false;
}

fn netrcLexerCleanup(lexer: *NetrcLexer) void {
    lexer.data = null;
    curlx_dyn_free(&lexer.literal);
}

fn netrcSkipBlanks(lexer: *NetrcLexer) void {
    var s = lexer.pos;
    while (s[0] != 0) {
        passBlanks(&s);
        while (s[0] == '\r') {
            s += 1;
        }
        if (s[0] == '\n') {
            s += 1;
        } else {
            break;
        }
    }
    lexer.pos = s;
}

fn netrcSkipToEmptyLine(lexer: *NetrcLexer) void {
    var s = lexer.pos;
    while (s[0] != 0) {
        if (s[0] == '\r') {
            s += 1;
        } else if (s[0] == '\n') {
            s += 1;
            while (s[0] == '\r') {
                s += 1;
            }
            if (s[0] == '\n') {
                break;
            }
        } else {
            s += 1;
        }
    }
    lexer.pos = s;
}

fn netrcLexerQuoted(lexer: *NetrcLexer) c_uint {
    var rc: c_uint = NETRC_SYNTAX_ERROR;
    var s = lexer.pos;
    var escape = false;

    s += 1; // pass leading quote
    while (s[0] != 0) {
        var c = s[0];
        if (escape) {
            escape = false;
            switch (c) {
                'n' => c = '\n',
                'r' => c = '\r',
                't' => c = '\t',
                else => {},
            }
        } else if (c == '\\') {
            escape = true;
            s += 1;
            continue;
        } else if (c == '\"') {
            s += 1; // pass ending quote
            const result = curlx_dyn_addn(&lexer.literal, "", 0);
            rc = curl2netrc(result);
            break;
        }
        const result = curlx_dyn_addn(&lexer.literal, @ptrCast(&c), 1);
        if (result != CURLE_OK) {
            rc = curl2netrc(result);
            break;
        }
        s += 1;
    }
    lexer.pos = s;
    return rc;
}

fn netrcLexerPush(lexer: *NetrcLexer) void {
    lexer.pushed = true;
}

fn netrcLexerNext(lexer: *NetrcLexer, want_literal: bool) c_uint {
    var s = lexer.pos;
    var rc: c_uint = NETRC_OK;

    if (lexer.pushed) {
        lexer.pushed = false;
        lexer.pos = s;
        return rc;
    }

    curlx_dyn_reset(&lexer.literal);
    netrcSkipBlanks(lexer);
    s = lexer.pos;

    switch (s[0]) {
        0 => {
            lexer.token = .eof;
        },
        '\"' => {
            rc = netrcLexerQuoted(lexer);
            lexer.token = .literal;
            s = lexer.pos;
        },
        else => {
            const start = s;
            var slen: usize = 0;
            while (s[0] != 0 and !isBlank(s[0]) and !isNewline(s[0])) {
                s += 1;
                slen += 1;
            }
            if (slen == 0) {
                rc = NETRC_SYNTAX_ERROR;
            }
            if (want_literal) {
                lexer.token = .literal;
                const result = curlx_dyn_addn(&lexer.literal, start, slen);
                rc = curl2netrc(result);
            } else if (slen == 7 and primitives.curl_strnequal(start, "machine", slen) != 0) {
                lexer.token = .machine;
            } else if (slen == 7 and primitives.curl_strnequal(start, "default", slen) != 0) {
                lexer.token = .default_tok;
            } else if (slen == 7 and primitives.curl_strnequal(start, "account", slen) != 0) {
                lexer.token = .account;
            } else if (slen == 5 and primitives.curl_strnequal(start, "login", slen) != 0) {
                lexer.token = .login;
            } else if (slen == 8 and primitives.curl_strnequal(start, "password", slen) != 0) {
                lexer.token = .passwd;
            } else if (slen == 6 and primitives.curl_strnequal(start, "macdef", slen) != 0) {
                lexer.token = .macdef;
            } else {
                lexer.token = .junk;
            }
        },
    }

    lexer.pos = s;
    return rc;
}

const NetrcScanner = struct {
    lexer: NetrcLexer,
    hostname: [*:0]const u8,
    user: ?[*:0]const u8,
    login: ?[*:0]u8,
    passwd: ?[*:0]u8,
    creds: ?*anyopaque,
    matches_host: bool,
    found: bool,
};

fn netrcScanReset(sc: *NetrcScanner) void {
    if (sc.login) |l| {
        mem.free(@ptrCast(l));
        sc.login = null;
    }
    if (sc.passwd) |p| {
        mem.free(@ptrCast(p));
        sc.passwd = null;
    }
    sc.matches_host = false;
}

fn netrcScanInit(
    sc: *NetrcScanner,
    data: ?*anyopaque,
    content: [*:0]const u8,
    hostname: [*:0]const u8,
    user: ?[*:0]const u8,
) void {
    sc.* = .{
        .lexer = undefined,
        .hostname = hostname,
        .user = if (user != null and user.?[0] != 0) user else null,
        .login = null,
        .passwd = null,
        .creds = null,
        .matches_host = false,
        .found = false,
    };
    netrcLexerInit(&sc.lexer, data, content);
}

fn netrcScanCleanup(sc: *NetrcScanner) void {
    netrcScanReset(sc);
    Curl_creds_unlink(&sc.creds);
    netrcLexerCleanup(&sc.lexer);
}

fn netrcScanLiteral(sc: *NetrcScanner, pdest: ?*?[*:0]u8) c_uint {
    var rc = netrcLexerNext(&sc.lexer, true);
    if (rc == NETRC_OK) {
        if (sc.lexer.token == .literal) {
            if (pdest != null and sc.matches_host) {
                const dest = pdest.?;
                if (dest.*) |old| {
                    mem.free(@ptrCast(old));
                }
                const lit_ptr = curlx_dyn_ptr(&sc.lexer.literal) orelse "";
                dest.* = mem.strdup(lit_ptr);
                if (dest.* == null) {
                    rc = NETRC_OUT_OF_MEMORY;
                }
            }
        } else {
            netrcLexerPush(&sc.lexer);
        }
    }
    return rc;
}

fn netrcScanEndEntry(sc: *NetrcScanner) c_uint {
    var rc: c_uint = NETRC_OK;
    if (sc.matches_host) {
        var check_found = true;
        if (sc.login) |login| {
            if (sc.user) |user| {
                if (primitives.Curl_timestrcmp(user, login) != 0) {
                    check_found = false;
                } else {
                    sc.found = (sc.passwd != null);
                }
            } else {
                sc.found = true;
            }
        } else if (sc.passwd != null) {
            sc.found = true;
        }
        if (check_found and sc.found) {
            const effective_user: ?[*:0]const u8 = if (sc.user) |u| u else sc.login;
            if (Curl_creds_create(effective_user, sc.passwd, null, null, null, CREDS_NETRC, &sc.creds) != CURLE_OK) {
                rc = NETRC_OUT_OF_MEMORY;
            }
        }
    }
    netrcScanReset(sc);
    return rc;
}

fn netrcScan(
    data: ?*anyopaque,
    content: [*:0]const u8,
    hostname: [*:0]const u8,
    user: ?[*:0]const u8,
    pcreds: *?*anyopaque,
) c_uint {
    var sc: NetrcScanner = undefined;
    var rc: c_uint = NETRC_OK;

    Curl_creds_unlink(pcreds);
    netrcScanInit(&sc, data, content, hostname, user);

    while (rc == NETRC_OK and !sc.found) {
        rc = netrcLexerNext(&sc.lexer, false);
        if (rc == NETRC_OK) {
            switch (sc.lexer.token) {
                .eof, .machine, .default_tok, .macdef => {
                    rc = netrcScanEndEntry(&sc);
                    if (rc != NETRC_OK or sc.found) break;
                },
                else => {},
            }

            switch (sc.lexer.token) {
                .eof => break,
                .machine => {
                    rc = netrcLexerNext(&sc.lexer, true);
                    if (rc == NETRC_OK) {
                        if (sc.lexer.token == .literal) {
                            const lit_ptr = curlx_dyn_ptr(&sc.lexer.literal);
                            sc.matches_host = (primitives.curl_strequal(sc.hostname, lit_ptr) != 0);
                        } else {
                            sc.matches_host = false;
                            netrcLexerPush(&sc.lexer);
                        }
                    }
                },
                .default_tok => {
                    sc.matches_host = true;
                },
                .account => {
                    rc = netrcScanLiteral(&sc, null);
                },
                .login => {
                    rc = netrcScanLiteral(&sc, &sc.login);
                },
                .passwd => {
                    rc = netrcScanLiteral(&sc, &sc.passwd);
                },
                .macdef => {
                    netrcSkipToEmptyLine(&sc.lexer);
                },
                .literal, .junk => {},
            }
        }
    }

    if (rc == NETRC_OK) {
        if (sc.creds) |creds| {
            Curl_creds_link(pcreds, creds);
        } else {
            rc = NETRC_NO_MATCH;
        }
    }
    netrcScanCleanup(&sc);
    return rc;
}

fn isFileNotDir(filename: [*:0]const u8, file: *anyopaque) bool {
    if (builtin.os.tag == .windows) {
        var st: netrc_win32_c.Win32Stat64 = undefined;
        const fd = netrc_win32_c._fileno(file);
        if (netrc_win32_c._fstati64(fd, &st) == -1) return true;
        return (st.st_mode & 0xF000) != 0x4000;
    } else {
        if (netrc_posix_c.opendir(filename)) |dir| {
            _ = netrc_posix_c.closedir(dir);
            return false;
        }
        return true;
    }
}

fn file2memory(filename: [*:0]const u8, filebuf: *os_leaf.Dynbuf) c_uint {
    var ret: c_uint = NETRC_FILE_MISSING;
    const file_opt = if (builtin.os.tag == .windows)
        netrc_win32_c.curlx_win32_fopen(filename, "rt")
    else
        netrc_posix_c.fopen(filename, "r");

    curlx_dyn_reset(filebuf);
    if (file_opt) |file| {
        if (isFileNotDir(filename, file)) {
            var eof = false;
            var linebuf: os_leaf.Dynbuf = std.mem.zeroes(os_leaf.Dynbuf);
            curlx_dyn_init(&linebuf, MAX_NETRC_LINE);
            ret = NETRC_OK;
            while (true) {
                var result = os_leaf.Curl_get_line(&linebuf, file, &eof);
                if (result == CURLE_OK) {
                    if (curlx_dyn_ptr(&linebuf)) |raw_line| {
                        var line: [*:0]const u8 = raw_line;
                        passBlanks(&line);
                        if (line[0] == '#') {
                            if (eof) break;
                            continue;
                        }
                        result = curlx_dyn_add(filebuf, line);
                    }
                }
                if (result != CURLE_OK) {
                    curlx_dyn_free(filebuf);
                    ret = curl2netrc(result);
                    break;
                }
                if (eof) break;
            }
            curlx_dyn_free(&linebuf);
        }
        if (builtin.os.tag == .windows) {
            _ = netrc_win32_c.fclose(file);
        } else {
            _ = netrc_posix_c.fclose(file);
        }
    }
    return ret;
}

fn netrcScanFile(
    data: ?*anyopaque,
    store: *StoreNetrc,
    hostname: [*:0]const u8,
    user: ?[*:0]const u8,
    netrcfile: [*:0]const u8,
    pcreds: *?*anyopaque,
) c_uint {
    const filebuf = &store.filebuf;
    const loaded = (store.loaded_bits & 1) != 0;
    const same_file = if (store.filename) |fn_ptr|
        std.mem.orderZ(u8, netrcfile, fn_ptr) == .eq
    else
        false;

    if (!loaded or !same_file) {
        store.loaded_bits &= ~@as(c_uint, 1);
        const ret = file2memory(netrcfile, filebuf);
        if (ret != NETRC_OK) {
            Curl_trc_multi(data, "[NETRC] could not load '%s'", netrcfile);
            return ret;
        }
        if (store.filename) |old_fn| {
            mem.free(@ptrCast(old_fn));
        }
        store.filename = mem.strdup(netrcfile);
        if (store.filename == null) {
            curlx_dyn_reset(&store.filebuf);
            return NETRC_OUT_OF_MEMORY;
        }
        store.loaded_bits |= 1;
    }

    if (curlx_dyn_len(filebuf) == 0)
        return NETRC_NO_MATCH;

    const content = curlx_dyn_ptr(filebuf) orelse return NETRC_NO_MATCH;
    return netrcScan(data, content, hostname, user, pcreds);
}

fn joinNetrcPath(home: [*:0]const u8, suffix: []const u8) ?[*:0]u8 {
    const dir_char = if (builtin.os.tag == .windows) "\\" else "/";
    const home_len = std.mem.len(home);
    const total = home_len + dir_char.len + suffix.len;
    const buf = mem.malloc(total + 1) orelse return null;
    @memcpy(buf[0..home_len], home[0..home_len]);
    @memcpy(buf[home_len .. home_len + dir_char.len], dir_char);
    @memcpy(buf[home_len + dir_char.len .. total], suffix);
    buf[total] = 0;
    return @ptrCast(buf);
}

pub export fn Curl_netrc_scan(
    data: ?*anyopaque,
    store: *StoreNetrc,
    hostname: [*:0]const u8,
    user: ?[*:0]const u8,
    netrcfile_opt: ?[*:0]const u8,
    pcreds: *?*anyopaque,
) callconv(.c) c_uint {
    var retcode: c_uint = NETRC_OK;

    Curl_trc_multi(data, "[NETRC] scanning '%s' for host '%s' user '%s'", netrcfile_opt, hostname, user);
    Curl_creds_unlink(pcreds);

    if (netrcfile_opt) |netrcfile| {
        retcode = netrcScanFile(data, store, hostname, user, netrcfile, pcreds);
    } else {
        var home: ?[*:0]const u8 = null;
        var homea: ?[*:0]u8 = null;
        var filealloc: ?[*:0]u8 = null;
        var pwbuf: [1024]u8 = undefined;

        filealloc = os_leaf.curl_getenv("NETRC");
        if (filealloc == null) {
            homea = os_leaf.curl_getenv("HOME");
            if (homea) |h| {
                home = h;
            } else if (builtin.os.tag == .windows) {
                homea = os_leaf.curl_getenv("USERPROFILE");
                if (homea) |h| {
                    home = h;
                }
            } else {
                var pw: Passwd = undefined;
                var pw_res: ?*Passwd = null;
                if (netrc_posix_c.getpwuid_r(netrc_posix_c.geteuid(), &pw, &pwbuf, pwbuf.len, &pw_res) == 0 and pw_res != null) {
                    home = pw.pw_dir;
                }
            }

            if (home == null) {
                return NETRC_FILE_MISSING;
            }

            filealloc = joinNetrcPath(home.?, ".netrc");
            if (filealloc == null) {
                if (homea) |ha| mem.free(@ptrCast(ha));
                Curl_creds_unlink(pcreds);
                return NETRC_OUT_OF_MEMORY;
            }
        }

        retcode = netrcScanFile(data, store, hostname, user, filealloc.?, pcreds);
        mem.free(@ptrCast(filealloc.?));

        if (builtin.os.tag == .windows) {
            if (retcode == NETRC_FILE_MISSING and home != null) {
                filealloc = joinNetrcPath(home.?, "_netrc");
                if (filealloc == null) {
                    if (homea) |ha| mem.free(@ptrCast(ha));
                    return NETRC_OUT_OF_MEMORY;
                }
                retcode = netrcScanFile(data, store, hostname, user, filealloc.?, pcreds);
                mem.free(@ptrCast(filealloc.?));
            }
        }

        if (homea) |ha| mem.free(@ptrCast(ha));
    }

    if (retcode != NETRC_OK) {
        Curl_creds_unlink(pcreds);
    }
    return retcode;
}

pub export fn Curl_netrc_init(store: *StoreNetrc) callconv(.c) void {
    curlx_dyn_init(&store.filebuf, MAX_NETRC_FILE);
    store.loaded_bits &= ~@as(c_uint, 1);
    store.filename = null;
}

pub export fn Curl_netrc_cleanup(store: *StoreNetrc) callconv(.c) void {
    curlx_dyn_free(&store.filebuf);
    if (store.filename) |f| {
        mem.free(@ptrCast(f));
        store.filename = null;
    }
    store.loaded_bits &= ~@as(c_uint, 1);
}

pub export fn Curl_netrc_strerror(ret: c_uint) callconv(.c) [*:0]const u8 {
    return switch (ret) {
        NETRC_FILE_MISSING => "no such file",
        NETRC_NO_MATCH => "no matching entry",
        NETRC_OUT_OF_MEMORY => "out of memory",
        NETRC_SYNTAX_ERROR => "syntax error",
        else => "",
    };
}

// ============================================================================
// Unit Tests
// ============================================================================

test "idn: Curl_is_ASCII_name, Curl_is_ASCII_str, Curl_idnconvert_hostname" {
    try std.testing.expect(Curl_is_ASCII_name(null));
    try std.testing.expect(Curl_is_ASCII_name(""));
    try std.testing.expect(Curl_is_ASCII_name("example.com"));
    try std.testing.expect(!Curl_is_ASCII_name("m\xc3\xbcnchen.de"));

    var s = curlx_parse.Curl_str{ .str = "ascii.host", .len = 10 };
    try std.testing.expect(Curl_is_ASCII_str(&s));
    var s_non = curlx_parse.Curl_str{ .str = "non\x80ascii", .len = 9 };
    try std.testing.expect(!Curl_is_ASCII_str(&s_non));

    var host_name_buf = "example.org".*;
    var host = Hostname{
        .rawalloc = null,
        .encalloc = null,
        .name = &host_name_buf,
        .dispname = null,
    };
    try std.testing.expectEqual(CURLE_OK, Curl_idnconvert_hostname(&host));
    try std.testing.expectEqualStrings("example.org", std.mem.span(host.dispname.?));

    if (comptime (backend_options.idn != .none)) {
        if (comptime (builtin.os.tag != .windows)) {
            const c_locale = struct {
                extern fn setlocale(category: c_int, locale: ?[*:0]const u8) callconv(.c) ?[*:0]u8;
            };
            _ = c_locale.setlocale(0, "C.UTF-8") orelse c_locale.setlocale(0, "");
        }
        var encoded: ?[*:0]u8 = null;
        try std.testing.expectEqual(CURLE_OK, Curl_idn_encode("xn--mnchen-3ya.de", &encoded));
        defer mem.free(encoded);
        try std.testing.expectEqualStrings("m\xc3\xbcnchen.de", std.mem.span(encoded.?));

        var decoded: ?[*:0]u8 = null;
        try std.testing.expectEqual(CURLE_OK, Curl_idn_decode("m\xc3\xbcnchen.de", &decoded));
        defer mem.free(decoded);
        try std.testing.expectEqualStrings("xn--mnchen-3ya.de", std.mem.span(decoded.?));

        var idn_name_buf = "m\xc3\xbcnchen.de".*;
        var idn_host = Hostname{
            .rawalloc = null,
            .encalloc = null,
            .name = &idn_name_buf,
            .dispname = null,
        };
        try std.testing.expectEqual(CURLE_OK, Curl_idnconvert_hostname(&idn_host));
        defer Curl_free_idnconverted_hostname(&idn_host);
        try std.testing.expectEqualStrings("m\xc3\xbcnchen.de", std.mem.span(idn_host.dispname.?));
        try std.testing.expectEqualStrings("xn--mnchen-3ya.de", std.mem.span(idn_host.name.?));
        try std.testing.expect(idn_host.encalloc != null);
    } else {
        var out: ?[*:0]u8 = null;
        try std.testing.expectEqual(CURLE_NOT_BUILT_IN, Curl_idn_decode("m\xc3\xbcnchen.de", &out));
        try std.testing.expectEqual(CURLE_NOT_BUILT_IN, Curl_idn_encode("xn--mnchen-3ya.de", &out));
    }
}

test "curl_addrinfo: Curl_is_ipv4addr, Curl_is_ipaddr, Curl_looks_like_ipv6" {
    try std.testing.expect(Curl_is_ipv4addr("127.0.0.1"));
    try std.testing.expect(!Curl_is_ipv4addr("999.0.0.1"));
    try std.testing.expect(!Curl_is_ipv4addr("::1"));

    try std.testing.expect(Curl_is_ipaddr("192.168.1.1"));
    try std.testing.expect(Curl_is_ipaddr("::1"));
    try std.testing.expect(Curl_is_ipaddr("fe80::1ff:fe23:4567:890a"));
    try std.testing.expect(!Curl_is_ipaddr("example.com"));

    var host = curlx_parse.Curl_str{ .str = null, .len = 0 };
    var zone = curlx_parse.Curl_str{ .str = null, .len = 0 };
    const v6 = "fe80::1%25eth0";
    try std.testing.expect(Curl_looks_like_ipv6(v6.ptr, v6.len, true, &host, &zone));
    try std.testing.expectEqualStrings("fe80::1", host.str.?[0..host.len]);
    try std.testing.expectEqualStrings("eth0", zone.str.?[0..zone.len]);

    const bad_v6 = "fe80::1%eth0/bad";
    try std.testing.expect(!Curl_looks_like_ipv6(bad_v6.ptr, bad_v6.len, false, &host, &zone));
}

test "curl_addrinfo: Curl_str2addr, Curl_addrinfo_get, Curl_addrinfo_set_port, Curl_unix2addr, Curl_freeaddrinfo" {
    var ai4: ?*Curl_addrinfo = null;
    try std.testing.expectEqual(CURLE_OK, Curl_str2addr("127.0.0.1", 8080, &ai4));
    defer Curl_freeaddrinfo(ai4);
    try std.testing.expect(ai4 != null);
    try std.testing.expectEqual(AF_INET, ai4.?.ai_family);
    try std.testing.expectEqualStrings("127.0.0.1", std.mem.span(ai4.?.ai_canonname.?));
    try std.testing.expect(Curl_addrinfo_get(ai4, AF_INET, 0) == ai4);
    try std.testing.expect(Curl_addrinfo_get(ai4, AF_INET, 1) == null);
    try std.testing.expect(Curl_addrinfo_get(ai4, AF_INET6, 0) == null);

    Curl_addrinfo_set_port(ai4, 9090);
    const sin: *const SockaddrIn = @ptrCast(@alignCast(ai4.?.ai_addr.?));
    try std.testing.expectEqual(std.mem.nativeToBig(u16, 9090), sin.sin_port);

    var ai6: ?*Curl_addrinfo = null;
    try std.testing.expectEqual(CURLE_OK, Curl_str2addr("::1", 443, &ai6));
    defer Curl_freeaddrinfo(ai6);
    try std.testing.expect(ai6 != null);
    try std.testing.expectEqual(AF_INET6, ai6.?.ai_family);

    var ai_unix: ?*Curl_addrinfo = null;
    try std.testing.expectEqual(CURLE_OK, Curl_unix2addr("test.sock", false, &ai_unix));
    defer Curl_freeaddrinfo(ai_unix);
    try std.testing.expect(ai_unix != null);
    try std.testing.expectEqual(AF_UNIX, ai_unix.?.ai_family);
}

test "netrc: Curl_netrc_strerror and in-memory scan" {
    try std.testing.expectEqualStrings("no such file", std.mem.span(Curl_netrc_strerror(NETRC_FILE_MISSING)));
    try std.testing.expectEqualStrings("no matching entry", std.mem.span(Curl_netrc_strerror(NETRC_NO_MATCH)));
    try std.testing.expectEqualStrings("out of memory", std.mem.span(Curl_netrc_strerror(NETRC_OUT_OF_MEMORY)));
    try std.testing.expectEqualStrings("syntax error", std.mem.span(Curl_netrc_strerror(NETRC_SYNTAX_ERROR)));
    try std.testing.expectEqualStrings("", std.mem.span(Curl_netrc_strerror(NETRC_OK)));

    var store: StoreNetrc = std.mem.zeroes(StoreNetrc);
    Curl_netrc_init(&store);
    defer Curl_netrc_cleanup(&store);

    const netrc_content =
        \\machine example.com login "alice" password "secret\npass"
        \\macdef init
        \\cd /pub
        \\
        \\default login bob password defaultpass
    ;
    try std.testing.expectEqual(CURLE_OK, curlx_dyn_add(&store.filebuf, netrc_content));
    store.filename = mem.strdup("mock.netrc");
    store.loaded_bits |= 1;

    var creds: ?*anyopaque = null;
    defer Curl_creds_unlink(&creds);

    try std.testing.expectEqual(
        NETRC_OK,
        Curl_netrc_scan(null, &store, "example.com", null, "mock.netrc", &creds),
    );
    try std.testing.expect(creds != null);

    try std.testing.expectEqual(
        NETRC_NO_MATCH,
        Curl_netrc_scan(null, &store, "example.com", "wronguser", "mock.netrc", &creds),
    );
    try std.testing.expect(creds == null);

    try std.testing.expectEqual(
        NETRC_OK,
        Curl_netrc_scan(null, &store, "other.example.org", null, "mock.netrc", &creds),
    );
    try std.testing.expect(creds != null);

    try std.testing.expectEqual(
        NETRC_FILE_MISSING,
        Curl_netrc_scan(null, &store, "example.com", null, ".", &creds),
    );
    try std.testing.expectEqual(
        NETRC_FILE_MISSING,
        Curl_netrc_scan(null, &store, "example.com", null, "nonexistent_file_12345.netrc", &creds),
    );
}
