const std = @import("std");
const builtin = @import("builtin");

pub const timediff_t = i64;
pub const TIMEDIFF_T_MAX: timediff_t = std.math.maxInt(timediff_t);
pub const TIMEDIFF_T_MIN: timediff_t = std.math.minInt(timediff_t);

pub const Timeval = std.c.timeval;
pub const time_t = if (builtin.os.tag == .windows) i64 else std.c.time_t;
pub const curl_socket_t = if (builtin.os.tag == .windows) usize else c_int;

pub const CURLE_OK: c_uint = 0;
pub const CURLE_UNSUPPORTED_PROTOCOL: c_uint = 1;
pub const CURLE_BAD_FUNCTION_ARGUMENT: c_uint = 43;
pub const CURLE_TOO_LARGE: c_uint = 100;

pub const AF_INET: c_int = 2;
pub const AF_INET6: c_int = switch (builtin.os.tag) {
    .windows => 23,
    .macos, .ios, .tvos, .watchos, .visionos => 30,
    else => std.c.AF.INET6,
};

pub const Curltime = extern struct {
    tv_sec: time_t,
    tv_usec: c_int,
};

const win32 = struct {
    const WSAEINTR: c_int = 10004;
    const WSAEBADF: c_int = 10009;
    const WSAEACCES: c_int = 10013;
    const WSAEFAULT: c_int = 10014;
    const WSAEINVAL: c_int = 10022;
    const WSAEMFILE: c_int = 10024;
    const WSAEWOULDBLOCK: c_int = 10035;
    const WSAEINPROGRESS: c_int = 10036;
    const WSAEALREADY: c_int = 10037;
    const WSAENOTSOCK: c_int = 10038;
    const WSAEDESTADDRREQ: c_int = 10039;
    const WSAEMSGSIZE: c_int = 10040;
    const WSAEPROTOTYPE: c_int = 10041;
    const WSAENOPROTOOPT: c_int = 10042;
    const WSAEPROTONOSUPPORT: c_int = 10043;
    const WSAESOCKTNOSUPPORT: c_int = 10044;
    const WSAEOPNOTSUPP: c_int = 10045;
    const WSAEPFNOSUPPORT: c_int = 10046;
    const WSAEAFNOSUPPORT: c_int = 10047;
    const WSAEADDRINUSE: c_int = 10048;
    const WSAEADDRNOTAVAIL: c_int = 10049;
    const WSAENETDOWN: c_int = 10050;
    const WSAENETUNREACH: c_int = 10051;
    const WSAENETRESET: c_int = 10052;
    const WSAECONNABORTED: c_int = 10053;
    const WSAECONNRESET: c_int = 10054;
    const WSAENOBUFS: c_int = 10055;
    const WSAEISCONN: c_int = 10056;
    const WSAENOTCONN: c_int = 10057;
    const WSAESHUTDOWN: c_int = 10058;
    const WSAETOOMANYREFS: c_int = 10059;
    const WSAETIMEDOUT: c_int = 10060;
    const WSAECONNREFUSED: c_int = 10061;
    const WSAELOOP: c_int = 10062;
    const WSAENAMETOOLONG: c_int = 10063;
    const WSAEHOSTDOWN: c_int = 10064;
    const WSAEHOSTUNREACH: c_int = 10065;
    const WSAENOTEMPTY: c_int = 10066;
    const WSAEPROCLIM: c_int = 10067;
    const WSAEUSERS: c_int = 10068;
    const WSAEDQUOT: c_int = 10069;
    const WSAESTALE: c_int = 10070;
    const WSAEREMOTE: c_int = 10071;
    const WSASYSNOTREADY: c_int = 10091;
    const WSAVERNOTSUPPORTED: c_int = 10092;
    const WSANOTINITIALISED: c_int = 10093;
    const WSAEDISCON: c_int = 10101;
    const WSAHOST_NOT_FOUND: c_int = 11001;
    const WSATRY_AGAIN: c_int = 11002;
    const WSANO_RECOVERY: c_int = 11003;
    const WSANO_DATA: c_int = 11004;

    const FORMAT_MESSAGE_IGNORE_INSERTS: u32 = 0x00000200;
    const FORMAT_MESSAGE_FROM_SYSTEM: u32 = 0x00001000;
    const LANG_NEUTRAL: u32 = 0x00;

    extern "kernel32" fn QueryPerformanceFrequency(lpFrequency: *i64) callconv(.winapi) c_int;
    extern "kernel32" fn QueryPerformanceCounter(lpPerformanceCount: *i64) callconv(.winapi) c_int;
    extern "kernel32" fn Sleep(dwMilliseconds: u32) callconv(.winapi) void;
    extern "kernel32" fn GetLastError() callconv(.winapi) u32;
    extern "kernel32" fn SetLastError(dwErrCode: u32) callconv(.winapi) void;
    extern "kernel32" fn FormatMessageA(
        dwFlags: u32,
        lpSource: ?*const anyopaque,
        dwMessageId: u32,
        dwLanguageId: u32,
        lpBuffer: [*]u8,
        nSize: u32,
        Arguments: ?*anyopaque,
    ) callconv(.winapi) u32;
    extern "ws2_32" fn WSASetLastError(iError: c_int) callconv(.winapi) void;
    extern "ws2_32" fn ioctlsocket(s: curl_socket_t, cmd: c_long, argp: *c_ulong) callconv(.winapi) c_int;
    extern "c" fn _gmtime64_s(tm: ?*anyopaque, time: *const time_t) c_int;
    extern "c" fn strerror_s(buf: [*]u8, size_in_bytes: usize, errnum: c_int) c_int;
};

const posix_c = struct {
    extern "c" fn gmtime_r(time: *const time_t, tm: ?*anyopaque) ?*anyopaque;
    extern "c" fn select(
        nfds: c_int,
        readfds: ?*anyopaque,
        writefds: ?*anyopaque,
        errorfds: ?*anyopaque,
        timeout: ?*Timeval,
    ) c_int;
};

const glibc_strerr = struct {
    extern "c" fn strerror_r(errnum: c_int, buf: [*]u8, buflen: usize) ?[*:0]const u8;
};

const posix_strerr = struct {
    extern "c" fn strerror_r(errnum: c_int, buf: [*]u8, buflen: usize) c_int;
};

// ============================================================================
// 1. timediff.c: curlx_mstotv, curlx_tvtoms
// ============================================================================

pub export fn curlx_mstotv(tv_opt: ?*Timeval, ms: timediff_t) ?*Timeval {
    const tv = tv_opt orelse return null;
    if (ms < 0) return null;

    if (ms > 0) {
        var tv_sec: timediff_t = @divTrunc(ms, 1000);
        const tv_usec: timediff_t = @rem(ms, 1000) * 1000;
        const SecType = @TypeOf(tv.sec);
        const max_sec: timediff_t = std.math.maxInt(SecType);
        if (tv_sec > max_sec) {
            tv_sec = max_sec;
        }
        tv.sec = @intCast(tv_sec);
        tv.usec = @intCast(tv_usec);
    } else {
        tv.sec = 0;
        tv.usec = 0;
    }

    return tv;
}

pub export fn curlx_tvtoms(tv: *Timeval) timediff_t {
    return (@as(timediff_t, tv.sec) *% 1000) +% @divTrunc(@as(timediff_t, tv.usec), 1000);
}

// ============================================================================
// 2. timeval.c: curlx_now, curlx_pnow, curlx_timediff*, curlx_gmtime
// ============================================================================

var s_time_freq: i64 = 0;

pub export fn curlx_now_init() void {
    if (builtin.os.tag == .windows) {
        _ = win32.QueryPerformanceFrequency(&s_time_freq);
    }
}

pub export fn curlx_pnow(pnow: *Curltime) void {
    if (builtin.os.tag == .windows) {
        var freq = s_time_freq;
        if (freq == 0) {
            _ = win32.QueryPerformanceFrequency(&freq);
            s_time_freq = freq;
        }
        var count: i64 = 0;
        _ = win32.QueryPerformanceCounter(&count);
        pnow.tv_sec = @divTrunc(count, freq);
        pnow.tv_usec = @intCast(@divTrunc(@rem(count, freq) * 1000000, freq));
    } else {
        var tsnow: std.c.timespec = undefined;
        if (std.c.clock_gettime(std.c.CLOCK.MONOTONIC, &tsnow) == 0) {
            pnow.tv_sec = tsnow.sec;
            pnow.tv_usec = @intCast(@divTrunc(tsnow.nsec, 1000));
        } else {
            var now: Timeval = undefined;
            _ = std.c.gettimeofday(&now, null);
            pnow.tv_sec = now.sec;
            pnow.tv_usec = @intCast(now.usec);
        }
    }
}

pub export fn curlx_now() Curltime {
    var now: Curltime = undefined;
    curlx_pnow(&now);
    return now;
}

pub export fn curlx_ptimediff_ms(newer: *const Curltime, older: *const Curltime) timediff_t {
    const diff: timediff_t = @as(timediff_t, newer.tv_sec) -% @as(timediff_t, older.tv_sec);
    if (diff >= @divTrunc(TIMEDIFF_T_MAX, 1000)) {
        return TIMEDIFF_T_MAX;
    } else if (diff <= @divTrunc(TIMEDIFF_T_MIN, 1000)) {
        return TIMEDIFF_T_MIN;
    }
    return (diff * 1000) + @divTrunc(@as(timediff_t, newer.tv_usec) - @as(timediff_t, older.tv_usec), 1000);
}

pub export fn curlx_timediff_ms(newer: Curltime, older: Curltime) timediff_t {
    return curlx_ptimediff_ms(&newer, &older);
}

pub export fn curlx_timediff_ceil_ms(newer: Curltime, older: Curltime) timediff_t {
    const diff: timediff_t = @as(timediff_t, newer.tv_sec) -% @as(timediff_t, older.tv_sec);
    if (diff >= @divTrunc(TIMEDIFF_T_MAX, 1000)) {
        return TIMEDIFF_T_MAX;
    } else if (diff <= @divTrunc(TIMEDIFF_T_MIN, 1000)) {
        return TIMEDIFF_T_MIN;
    }
    return (diff * 1000) + @divTrunc(@as(timediff_t, newer.tv_usec) - @as(timediff_t, older.tv_usec) + 999, 1000);
}

pub export fn curlx_us_to_ceil_ms(us: timediff_t) timediff_t {
    return @divTrunc(us, 1000) + @as(timediff_t, if (us > 0 and @rem(us, 1000) != 0) 1 else 0);
}

pub export fn curlx_ptimediff_us(newer: *const Curltime, older: *const Curltime) timediff_t {
    const diff: timediff_t = @as(timediff_t, newer.tv_sec) -% @as(timediff_t, older.tv_sec);
    if (diff >= @divTrunc(TIMEDIFF_T_MAX, 1000000)) {
        return TIMEDIFF_T_MAX;
    } else if (diff <= @divTrunc(TIMEDIFF_T_MIN, 1000000)) {
        return TIMEDIFF_T_MIN;
    }
    return (diff * 1000000) + @as(timediff_t, newer.tv_usec) - @as(timediff_t, older.tv_usec);
}

pub export fn curlx_timediff_us(newer: Curltime, older: Curltime) timediff_t {
    return curlx_ptimediff_us(&newer, &older);
}

pub export fn curlx_gmtime(intime: time_t, store: ?*anyopaque) c_uint {
    var t = intime;
    if (builtin.os.tag == .windows) {
        if (win32._gmtime64_s(store, &t) != 0) {
            return CURLE_BAD_FUNCTION_ARGUMENT;
        }
    } else {
        if (posix_c.gmtime_r(&t, store) == null) {
            return CURLE_BAD_FUNCTION_ARGUMENT;
        }
    }
    return CURLE_OK;
}

// ============================================================================
// 3. wait.c: curlx_wait_ms
// ============================================================================

pub export fn curlx_wait_ms(timeout_ms: timediff_t) c_int {
    if (timeout_ms == 0) return 0;
    if (timeout_ms < 0) {
        if (builtin.os.tag == .windows) {
            win32.WSASetLastError(win32.WSAEINVAL);
        } else {
            std.c._errno().* = @backingInt(std.c.E.INVAL);
        }
        return -1;
    }

    if (builtin.os.tag == .windows) {
        const max_dword: timediff_t = std.math.maxInt(u32);
        const ms: u32 = if (timeout_ms >= max_dword) std.math.maxInt(u32) - 1 else @intCast(timeout_ms);
        win32.Sleep(ms);
        return 0;
    } else {
        var pending_tv: Timeval = undefined;
        var r = posix_c.select(0, null, null, null, curlx_mstotv(&pending_tv, timeout_ms));
        if (r != 0) {
            if (r == -1 and std.c._errno().* == @backingInt(std.c.E.INTR)) {
                r = 0;
            } else {
                r = -1;
            }
        }
        return r;
    }
}

// ============================================================================
// 4. nonblock.c: curlx_nonblock
// ============================================================================

pub export fn curlx_nonblock(sockfd: curl_socket_t, nonblock: c_int) c_int {
    if (builtin.os.tag == .windows) {
        const FIONBIO: c_long = @bitCast(@as(u32, 0x8004667e));
        var flags: c_ulong = if (nonblock != 0) 1 else 0;
        return win32.ioctlsocket(sockfd, FIONBIO, &flags);
    } else {
        const flags = std.c.fcntl(sockfd, std.c.F.GETFL, @as(c_int, 0));
        if (flags < 0) return -1;
        const o_nonblock: c_int = @bitCast(@as(u32, @bitCast(std.c.O{ .NONBLOCK = true })));
        if (((flags & o_nonblock) != 0) == (nonblock != 0)) {
            return 0;
        }
        const new_flags: c_int = if (nonblock != 0) (flags | o_nonblock) else (flags & ~o_nonblock);
        return std.c.fcntl(sockfd, std.c.F.SETFL, new_flags);
    }
}

// ============================================================================
// 5. inet_ntop.c: curlx_inet_ntop
// ============================================================================

fn strcopySlice(dst: [*]u8, dsize: usize, src: []const u8) void {
    if (src.len < dsize) {
        @memcpy(dst[0..src.len], src);
        dst[src.len] = 0;
    } else if (dsize > 0) {
        dst[0] = 0;
    }
}

fn inetNtop4(src: [*]const u8, dst: [*]u8, size: usize) c_uint {
    var tmp: [16]u8 = undefined;
    const formatted = std.fmt.bufPrint(&tmp, "{d}.{d}.{d}.{d}", .{
        src[0],
        src[1],
        src[2],
        src[3],
    }) catch return CURLE_TOO_LARGE;

    if (formatted.len == 0 or formatted.len >= size) {
        return CURLE_TOO_LARGE;
    }
    strcopySlice(dst, size, formatted);
    return CURLE_OK;
}

fn inetNtop6(src: [*]const u8, dst: [*]u8, size: usize) c_uint {
    const IN6ADDRSZ = 16;
    const INT16SZ = 2;
    const NUM_WORDS = IN6ADDRSZ / INT16SZ;

    var tmp: [46]u8 = @splat(0);
    var words: [NUM_WORDS]u32 = @splat(0);

    for (0..IN6ADDRSZ) |i| {
        const shift: u5 = @intCast((1 - (i % 2)) * 8);
        words[i / 2] |= @as(u32, src[i]) << shift;
    }

    const Run = struct {
        base: isize = -1,
        len: usize = 0,
    };
    var best = Run{};
    var cur = Run{};

    for (0..NUM_WORDS) |i| {
        if (words[i] == 0) {
            if (cur.base == -1) {
                cur.base = @intCast(i);
                cur.len = 1;
            } else {
                cur.len += 1;
            }
        } else if (cur.base != -1) {
            if (best.base == -1 or cur.len > best.len) {
                best = cur;
            }
            cur.base = -1;
        }
    }
    if (cur.base != -1 and (best.base == -1 or cur.len > best.len)) {
        best = cur;
    }
    if (best.base != -1 and best.len < 2) {
        best.base = -1;
    }

    var tp: usize = 0;
    const ldigits = "0123456789abcdef";

    for (0..NUM_WORDS) |i| {
        const i_signed: isize = @intCast(i);
        if (best.base != -1 and i_signed >= best.base and i_signed < best.base + @as(isize, @intCast(best.len))) {
            if (i_signed == best.base) {
                tmp[tp] = ':';
                tp += 1;
            }
            continue;
        }

        if (i > 0) {
            tmp[tp] = ':';
            tp += 1;
        }

        if (i == 6 and best.base == 0 and (best.len == 6 or (best.len == 5 and words[5] == 0xffff))) {
            const rc = inetNtop4(src + 12, tmp[tp..].ptr, tmp.len - tp);
            if (rc != CURLE_OK) return rc;
            const sub_len = std.mem.indexOfScalar(u8, tmp[tp..], 0) orelse 0;
            tp += sub_len;
            break;
        } else {
            const w = words[i];
            if ((w & 0xf000) != 0) {
                tmp[tp] = ldigits[(w >> 12) & 0x0f];
                tp += 1;
            }
            if ((w & 0xff00) != 0) {
                tmp[tp] = ldigits[(w >> 8) & 0x0f];
                tp += 1;
            }
            if ((w & 0xfff0) != 0) {
                tmp[tp] = ldigits[(w >> 4) & 0x0f];
                tp += 1;
            }
            tmp[tp] = ldigits[w & 0x0f];
            tp += 1;
        }
    }

    if (best.base != -1 and (best.base + @as(isize, @intCast(best.len))) == NUM_WORDS) {
        tmp[tp] = ':';
        tp += 1;
    }

    if (tp >= size) {
        return CURLE_TOO_LARGE;
    }
    strcopySlice(dst, size, tmp[0..tp]);
    return CURLE_OK;
}

pub export fn curlx_inet_ntop(af: c_int, src: *const anyopaque, buf: [*]u8, size: usize) c_uint {
    const src_bytes: [*]const u8 = @ptrCast(src);
    if (af == AF_INET) {
        return inetNtop4(src_bytes, buf, size);
    } else if (af == AF_INET6) {
        return inetNtop6(src_bytes, buf, size);
    } else {
        return CURLE_UNSUPPORTED_PROTOCOL;
    }
}

// ============================================================================
// 6. inet_pton.c: curlx_inet_pton
// ============================================================================

fn hexVal(ch: u8) ?u8 {
    return switch (ch) {
        '0'...'9' => ch - '0',
        'a'...'f' => ch - 'a' + 10,
        'A'...'F' => ch - 'A' + 10,
        else => null,
    };
}

fn inetPton4(src_in: [*:0]const u8, dst: [*]u8) c_int {
    const INADDRSZ = 4;
    var tmp: [INADDRSZ]u8 = @splat(0);
    var tp: usize = 0;
    var saw_digit = false;
    var octets: usize = 0;
    var src = src_in;

    while (src[0] != 0) : (src += 1) {
        const ch = src[0];
        if (ch >= '0' and ch <= '9') {
            const val: u32 = (@as(u32, tmp[tp]) * 10) + (ch - '0');
            if (saw_digit and tmp[tp] == 0) return 0;
            if (val > 255) return 0;
            tmp[tp] = @intCast(val);
            if (!saw_digit) {
                octets += 1;
                if (octets > 4) return 0;
                saw_digit = true;
            }
        } else if (ch == '.' and saw_digit) {
            if (octets == 4) return 0;
            tp += 1;
            tmp[tp] = 0;
            saw_digit = false;
        } else {
            return 0;
        }
    }
    if (octets < 4) return 0;
    @memcpy(dst[0..INADDRSZ], &tmp);
    return 1;
}

fn inetPton6(src_in: [*:0]const u8, dst: [*]u8) c_int {
    const IN6ADDRSZ = 16;
    const INADDRSZ = 4;
    const INT16SZ = 2;

    var tmp: [IN6ADDRSZ]u8 = @splat(0);
    var tp: usize = 0;
    const endp: usize = IN6ADDRSZ;
    var colonp: ?usize = null;
    var src = src_in;

    if (src[0] == ':') {
        src += 1;
        if (src[0] != ':') return 0;
    }

    var curtok: [*:0]const u8 = src;
    var saw_xdigit: usize = 0;
    var val: usize = 0;

    while (src[0] != 0) {
        const ch = src[0];
        src += 1;
        if (hexVal(ch)) |hv| {
            val = (val << 4) | hv;
            saw_xdigit += 1;
            if (saw_xdigit > 4) return 0;
            continue;
        }
        if (ch == ':') {
            curtok = src;
            if (saw_xdigit == 0) {
                if (colonp != null) return 0;
                colonp = tp;
                continue;
            }
            if (src[0] == 0) return 0;
            if (tp + INT16SZ > endp) return 0;
            tmp[tp] = @intCast((val >> 8) & 0xff);
            tp += 1;
            tmp[tp] = @intCast(val & 0xff);
            tp += 1;
            saw_xdigit = 0;
            val = 0;
            continue;
        }
        if (ch == '.' and (tp + INADDRSZ <= endp) and inetPton4(curtok, tmp[tp..].ptr) > 0) {
            tp += INADDRSZ;
            saw_xdigit = 0;
            break;
        }
        return 0;
    }

    if (saw_xdigit != 0) {
        if (tp + INT16SZ > endp) return 0;
        tmp[tp] = @intCast((val >> 8) & 0xff);
        tp += 1;
        tmp[tp] = @intCast(val & 0xff);
        tp += 1;
    }

    if (colonp) |cp| {
        const n = tp - cp;
        if (tp == endp) return 0;
        var i: usize = 1;
        while (i <= n) : (i += 1) {
            tmp[endp - i] = tmp[cp + n - i];
            tmp[cp + n - i] = 0;
        }
        tp = endp;
    }

    if (tp != endp) return 0;
    @memcpy(dst[0..IN6ADDRSZ], &tmp);
    return 1;
}

pub export fn curlx_inet_pton(af: c_int, src: [*:0]const u8, dst: *anyopaque) c_int {
    const dst_bytes: [*]u8 = @ptrCast(dst);
    if (af == AF_INET) {
        return inetPton4(src, dst_bytes);
    } else if (af == AF_INET6) {
        return inetPton6(src, dst_bytes);
    } else {
        return -1;
    }
}

// ============================================================================
// 7. strerr.c: curlx_strerror
// ============================================================================

fn bufToZSlice(buf: [*]u8, max_len: usize) [:0]u8 {
    var len: usize = 0;
    while (len < max_len and buf[len] != 0) : (len += 1) {}
    if (len == max_len) len = 0;
    buf[len] = 0;
    return buf[0..len :0];
}

fn getWinsockError(err: c_int, buf: [*]u8, len: usize) ?[*:0]const u8 {
    if (len == 0) return null;
    buf[0] = 0;

    const p: []const u8 = switch (err) {
        win32.WSAEINTR => "Call interrupted",
        win32.WSAEBADF => "Bad file",
        win32.WSAEACCES => "Bad access",
        win32.WSAEFAULT => "Bad argument",
        win32.WSAEINVAL => "Invalid arguments",
        win32.WSAEMFILE => "Out of file descriptors",
        win32.WSAEWOULDBLOCK => "Call would block",
        win32.WSAEINPROGRESS, win32.WSAEALREADY => "Blocking call in progress",
        win32.WSAENOTSOCK => "Descriptor is not a socket",
        win32.WSAEDESTADDRREQ => "Need destination address",
        win32.WSAEMSGSIZE => "Bad message size",
        win32.WSAEPROTOTYPE => "Bad protocol",
        win32.WSAENOPROTOOPT => "Protocol option is unsupported",
        win32.WSAEPROTONOSUPPORT => "Protocol is unsupported",
        win32.WSAESOCKTNOSUPPORT => "Socket is unsupported",
        win32.WSAEOPNOTSUPP => "Operation not supported",
        win32.WSAEAFNOSUPPORT => "Address family not supported",
        win32.WSAEPFNOSUPPORT => "Protocol family not supported",
        win32.WSAEADDRINUSE => "Address already in use",
        win32.WSAEADDRNOTAVAIL => "Address not available",
        win32.WSAENETDOWN => "Network down",
        win32.WSAENETUNREACH => "Network unreachable",
        win32.WSAENETRESET => "Network has been reset",
        win32.WSAECONNABORTED => "Connection was aborted",
        win32.WSAECONNRESET => "Connection was reset",
        win32.WSAENOBUFS => "No buffer space",
        win32.WSAEISCONN => "Socket is already connected",
        win32.WSAENOTCONN => "Socket is not connected",
        win32.WSAESHUTDOWN => "Socket has been shut down",
        win32.WSAETOOMANYREFS => "Too many references",
        win32.WSAETIMEDOUT => "Timed out",
        win32.WSAECONNREFUSED => "Connection refused",
        win32.WSAELOOP => "Loop??",
        win32.WSAENAMETOOLONG => "Name too long",
        win32.WSAEHOSTDOWN => "Host down",
        win32.WSAEHOSTUNREACH => "Host unreachable",
        win32.WSAENOTEMPTY => "Not empty",
        win32.WSAEPROCLIM => "Process limit reached",
        win32.WSAEUSERS => "Too many users",
        win32.WSAEDQUOT => "Bad quota",
        win32.WSAESTALE => "Something is stale",
        win32.WSAEREMOTE => "Remote error",
        win32.WSAEDISCON => "Disconnected",
        win32.WSASYSNOTREADY => "Winsock library is not ready",
        win32.WSANOTINITIALISED => "Winsock library not initialized",
        win32.WSAVERNOTSUPPORTED => "Winsock version not supported",
        win32.WSAHOST_NOT_FOUND => "Host not found",
        win32.WSATRY_AGAIN => "Host not found, try again",
        win32.WSANO_RECOVERY => "Unrecoverable error in call to nameserver",
        win32.WSANO_DATA => "No data record of requested type",
        else => return null,
    };

    strcopySlice(buf, len, p);
    return bufToZSlice(buf, len).ptr;
}

fn getWinapiError(err: u32, buf: [*]u8, buflen: usize) ?[*:0]const u8 {
    if (buflen == 0) return null;
    if (win32.FormatMessageA(
        win32.FORMAT_MESSAGE_FROM_SYSTEM | win32.FORMAT_MESSAGE_IGNORE_INSERTS,
        null,
        err,
        win32.LANG_NEUTRAL,
        buf,
        @intCast(buflen),
        null,
    ) == 0) {
        buf[0] = 0;
        return null;
    }

    const slice = bufToZSlice(buf, buflen);
    if (std.mem.indexOfScalar(u8, slice, '\n')) |nl_idx| {
        if (nl_idx > 0 and buf[nl_idx - 1] == '\r') {
            buf[nl_idx - 1] = 0;
        } else {
            buf[nl_idx] = 0;
        }
    }

    return if (buf[0] != 0) bufToZSlice(buf, buflen).ptr else null;
}

fn writeTruncated(buf: [*]u8, buflen: usize, src: []const u8) void {
    if (buflen == 0) return;
    const copy_len = @min(src.len, buflen - 1);
    @memcpy(buf[0..copy_len], src[0..copy_len]);
    buf[copy_len] = 0;
}

fn formatUnknownErrorPosix(err: c_int, buf: [*]u8, buflen: usize) void {
    var tmp: [64]u8 = undefined;
    const s = std.fmt.bufPrint(&tmp, "Unknown error {d}", .{err}) catch return;
    writeTruncated(buf, buflen, s);
}

fn formatUnknownErrorWindows(err: c_int, buf: [*]u8, buflen: usize) void {
    var tmp: [64]u8 = undefined;
    const u_err: c_uint = @bitCast(err);
    const s = if (u_err == 0)
        std.fmt.bufPrint(&tmp, "Unknown error {d} (0)", .{err}) catch return
    else
        std.fmt.bufPrint(&tmp, "Unknown error {d} (0x{x})", .{ err, u_err }) catch return;
    writeTruncated(buf, buflen, s);
}

pub export fn curlx_strerror(err: c_int, buf: [*]u8, buflen: usize) ?[*:0]const u8 {
    if (buflen == 0) return null;

    const old_win_err = if (builtin.os.tag == .windows) win32.GetLastError() else 0;
    const old_errno = std.c._errno().*;

    @memset(buf[0..buflen], 0);

    if (builtin.os.tag == .windows) {
        const crt_failed = win32.strerror_s(buf, buflen, err) != 0 or
            std.mem.eql(u8, bufToZSlice(buf, buflen), "Unknown error");
        if (crt_failed and
            getWinsockError(err, buf, buflen) == null and
            getWinapiError(@bitCast(err), buf, buflen) == null)
        {
            formatUnknownErrorWindows(err, buf, buflen);
        }
    } else if (builtin.os.tag == .linux and builtin.abi.isGnu()) {
        var buffer: [256]u8 = @splat(0);
        const msg = glibc_strerr.strerror_r(err, &buffer, buffer.len);
        if (msg) |m| {
            if (buflen > 1) {
                writeTruncated(buf, buflen, std.mem.span(m));
            }
        } else if (buflen > "Unknown error ".len + 1 + 20) {
            formatUnknownErrorPosix(err, buf, buflen);
        }
    } else {
        if (posix_strerr.strerror_r(err, buf, buflen) != 0 and
            buflen > "Unknown error ".len + 1 + 20)
        {
            if (buf[0] == 0) {
                formatUnknownErrorPosix(err, buf, buflen);
            }
        }
    }

    // Strip trailing '\r\n' or '\n' matching strerr.c
    const slice1 = bufToZSlice(buf, buflen);
    if (std.mem.lastIndexOfScalar(u8, slice1, '\n')) |nl_idx| {
        if (nl_idx >= 2) {
            buf[nl_idx] = 0;
        }
    }
    const slice2 = bufToZSlice(buf, buflen);
    if (std.mem.lastIndexOfScalar(u8, slice2, '\r')) |cr_idx| {
        if (cr_idx >= 1) {
            buf[cr_idx] = 0;
        }
    }

    if (std.c._errno().* != old_errno) {
        std.c._errno().* = old_errno;
    }
    if (builtin.os.tag == .windows) {
        if (old_win_err != win32.GetLastError()) {
            win32.SetLastError(old_win_err);
        }
    }

    return bufToZSlice(buf, buflen).ptr;
}

// ============================================================================
// Unit Tests
// ============================================================================

test "curlx_mstotv and curlx_tvtoms roundtrip and edge cases" {
    var tv: Timeval = undefined;

    try std.testing.expectEqual(@as(?*Timeval, null), curlx_mstotv(null, 100));
    try std.testing.expectEqual(@as(?*Timeval, null), curlx_mstotv(&tv, -1));

    const zero_res = curlx_mstotv(&tv, 0);
    try std.testing.expect(zero_res == &tv);
    try std.testing.expectEqual(@as(@TypeOf(tv.sec), 0), tv.sec);
    try std.testing.expectEqual(@as(@TypeOf(tv.usec), 0), tv.usec);
    try std.testing.expectEqual(@as(timediff_t, 0), curlx_tvtoms(&tv));

    const pos_res = curlx_mstotv(&tv, 12345);
    try std.testing.expect(pos_res == &tv);
    try std.testing.expectEqual(@as(@TypeOf(tv.sec), 12), tv.sec);
    try std.testing.expectEqual(@as(@TypeOf(tv.usec), 345000), tv.usec);
    try std.testing.expectEqual(@as(timediff_t, 12345), curlx_tvtoms(&tv));
}

test "curlx_now and curlx_timediff functions (unit1323)" {
    curlx_now_init();
    const t1 = curlx_now();
    _ = curlx_wait_ms(1);
    var t2: Curltime = undefined;
    curlx_pnow(&t2);
    try std.testing.expect(curlx_timediff_us(t2, t1) >= 0);
    try std.testing.expect(curlx_timediff_ms(t2, t1) >= 0);

    const Case = struct {
        first: Curltime,
        second: Curltime,
        result: timediff_t,
    };
    const cases = [_]Case{
        .{ .first = .{ .tv_sec = 36762, .tv_usec = 8345 }, .second = .{ .tv_sec = 36761, .tv_usec = 995926 }, .result = 13 },
        .{ .first = .{ .tv_sec = 36761, .tv_usec = 995926 }, .second = .{ .tv_sec = 36762, .tv_usec = 8345 }, .result = -13 },
        .{ .first = .{ .tv_sec = 36761, .tv_usec = 995926 }, .second = .{ .tv_sec = 0, .tv_usec = 0 }, .result = 36761995 },
        .{ .first = .{ .tv_sec = 0, .tv_usec = 0 }, .second = .{ .tv_sec = 36761, .tv_usec = 995926 }, .result = -36761995 },
    };

    for (cases) |tc| {
        try std.testing.expectEqual(tc.result, curlx_timediff_ms(tc.first, tc.second));
        try std.testing.expectEqual(tc.result, curlx_ptimediff_ms(&tc.first, &tc.second));
    }

    try std.testing.expectEqual(
        @as(timediff_t, 14),
        curlx_timediff_ceil_ms(.{ .tv_sec = 36762, .tv_usec = 8345 }, .{ .tv_sec = 36761, .tv_usec = 995926 }),
    );
    try std.testing.expectEqual(@as(timediff_t, 0), curlx_us_to_ceil_ms(0));
    try std.testing.expectEqual(@as(timediff_t, 1), curlx_us_to_ceil_ms(1));
    try std.testing.expectEqual(@as(timediff_t, 1), curlx_us_to_ceil_ms(1000));
    try std.testing.expectEqual(@as(timediff_t, 2), curlx_us_to_ceil_ms(1001));
    try std.testing.expectEqual(
        @as(timediff_t, 12419),
        curlx_timediff_us(.{ .tv_sec = 36762, .tv_usec = 8345 }, .{ .tv_sec = 36761, .tv_usec = 995926 }),
    );
}

test "curlx_inet_pton and curlx_inet_ntop IPv4 and IPv6 (unit1961)" {
    var ipv4res: [16]u8 = @splat(0);
    var ipv4a = [5]u8{ 0xc0, 0xa8, 0x64, 0x01, 0x01 };
    try std.testing.expectEqual(CURLE_OK, curlx_inet_ntop(AF_INET, &ipv4a, &ipv4res, ipv4res.len));
    try std.testing.expectEqualStrings("192.168.100.1", std.mem.sliceTo(&ipv4res, 0));

    var ipv6res: [46]u8 = @splat(0);
    var ipv6a: [26]u8 = @splat(0);
    ipv6a[0] = 0xfe;
    ipv6a[1] = 0x80;
    ipv6a[8] = 0x02;
    ipv6a[9] = 0x14;
    ipv6a[10] = 0x4f;
    ipv6a[11] = 0xff;
    ipv6a[12] = 0xfe;
    ipv6a[13] = 0x0b;
    ipv6a[14] = 0x76;
    ipv6a[15] = 0xc8;
    ipv6a[25] = 0x01;
    try std.testing.expectEqual(CURLE_OK, curlx_inet_ntop(AF_INET6, &ipv6a, &ipv6res, ipv6res.len));
    try std.testing.expectEqualStrings("fe80::214:4fff:fe0b:76c8", std.mem.sliceTo(&ipv6res, 0));

    @memset(&ipv6a, 0);
    ipv6a[12] = 0x7f;
    ipv6a[15] = 0x01;
    try std.testing.expectEqual(CURLE_OK, curlx_inet_ntop(AF_INET6, &ipv6a, &ipv6res, ipv6res.len));
    try std.testing.expectEqualStrings("::127.0.0.1", std.mem.sliceTo(&ipv6res, 0));

    // pton + roundtrip
    var parsed4 = [5]u8{ 1, 1, 1, 1, 1 };
    try std.testing.expectEqual(@as(c_int, 1), curlx_inet_pton(AF_INET, "192.168.100.1", &parsed4));
    try std.testing.expectEqualSlices(u8, &.{ 0xc0, 0xa8, 0x64, 0x01, 0x01 }, &parsed4);

    var parsed6: [17]u8 = @splat(1);
    try std.testing.expectEqual(@as(c_int, 1), curlx_inet_pton(AF_INET6, "fe80::214:4fff:fe0b:76c8", &parsed6));
    try std.testing.expectEqual(@as(u8, 0xfe), parsed6[0]);
    try std.testing.expectEqual(@as(u8, 0x80), parsed6[1]);
    try std.testing.expectEqual(@as(u8, 0x00), parsed6[2]);
    try std.testing.expectEqual(@as(u8, 0xc8), parsed6[15]);
    try std.testing.expectEqual(@as(u8, 0x01), parsed6[16]);

    const Pton6Case = struct {
        addr: [:0]const u8,
        valid: bool,
    };
    const pton6_cases = [_]Pton6Case{
        .{ .addr = "1:2:3:4:5:6:7:8:", .valid = false },
        .{ .addr = "::1:", .valid = false },
        .{ .addr = "1:2:3:", .valid = false },
        .{ .addr = "1:", .valid = false },
        .{ .addr = ":1", .valid = false },
        .{ .addr = ":::", .valid = false },
        .{ .addr = "1:2:3:4:5:6:7:8::", .valid = false },
        .{ .addr = "1:2:3:4:5:6:7::8:9", .valid = false },
        .{ .addr = "", .valid = false },
        .{ .addr = "::", .valid = true },
        .{ .addr = "::1", .valid = true },
        .{ .addr = "1::", .valid = true },
        .{ .addr = "1::8", .valid = true },
        .{ .addr = "1:2:3:4:5:6:7:8", .valid = true },
        .{ .addr = "1:2:3:4:5:6::", .valid = true },
        .{ .addr = "1:2:3:4:5:6::8", .valid = true },
        .{ .addr = "fe80::1", .valid = true },
        .{ .addr = "::ffff:192.0.2.1", .valid = true },
        .{ .addr = "::127.0.0.1", .valid = true },
    };

    for (pton6_cases) |tc| {
        var out6: [16]u8 = undefined;
        const rc = curlx_inet_pton(AF_INET6, tc.addr.ptr, &out6);
        try std.testing.expectEqual(tc.valid, rc == 1);
    }
}

test "curlx_strerror" {
    var buf: [256]u8 = undefined;
    try std.testing.expectEqual(@as(?[*:0]const u8, null), curlx_strerror(1, &buf, 0));

    const res = curlx_strerror(@backingInt(std.c.E.INVAL), &buf, buf.len);
    try std.testing.expect(res != null);
    const msg = std.mem.span(res.?);
    try std.testing.expect(msg.len > 0);
}
