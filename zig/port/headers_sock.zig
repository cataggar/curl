const std = @import("std");
const builtin = @import("builtin");
const mem = @import("mem.zig");
const curlx_time_net = @import("curlx_time_net.zig");

pub const timediff_t = curlx_time_net.timediff_t;
pub const TIMEDIFF_T_MAX = curlx_time_net.TIMEDIFF_T_MAX;
pub const curl_socket_t = curlx_time_net.curl_socket_t;
pub const Curltime = curlx_time_net.Curltime;
pub const Timeval = curlx_time_net.Timeval;

pub const CURL_SOCKET_BAD: curl_socket_t = if (builtin.os.tag == .windows)
    std.math.maxInt(curl_socket_t)
else
    -1;

pub const CURLE_OK: c_uint = 0;
pub const CURLE_READ_ERROR: c_uint = 26;
pub const CURLE_OUT_OF_MEMORY: c_uint = 27;
pub const CURLE_BAD_FUNCTION_ARGUMENT: c_uint = 43;

pub const CURL_POLL_NONE: u8 = 0;
pub const CURL_POLL_IN: u8 = 1;
pub const CURL_POLL_OUT: u8 = 2;
pub const CURL_POLL_INOUT: u8 = 3;
pub const CURL_POLL_REMOVE: u8 = 4;

pub const CURL_WAIT_POLLIN: c_short = 0x0001;
pub const CURL_WAIT_POLLPRI: c_short = 0x0002;
pub const CURL_WAIT_POLLOUT: c_short = 0x0004;

pub const CURL_CSELECT_IN: c_int = 0x01;
pub const CURL_CSELECT_OUT: c_int = 0x02;
pub const CURL_CSELECT_ERR: c_int = 0x04;
pub const CURL_CSELECT_IN2: c_int = CURL_CSELECT_ERR << 1;

// Platform-matched poll constants (matching <winsock2.h> on Windows and <poll.h> on POSIX)
pub const POLLIN: c_short = if (builtin.os.tag == .windows) 0x0300 else 0x0001;
pub const POLLPRI: c_short = if (builtin.os.tag == .windows) 0x0400 else 0x0002;
pub const POLLOUT: c_short = if (builtin.os.tag == .windows) 0x0010 else 0x0004;
pub const POLLERR: c_short = if (builtin.os.tag == .windows) 0x0001 else 0x0008;
pub const POLLHUP: c_short = if (builtin.os.tag == .windows) 0x0002 else 0x0010;
pub const POLLNVAL: c_short = if (builtin.os.tag == .windows) 0x0004 else 0x0020;
pub const POLLRDNORM: c_short = if (builtin.os.tag == .windows) 0x0100 else 0x0040;
pub const POLLRDBAND: c_short = if (builtin.os.tag == .windows) 0x0200 else 0x0080;
pub const POLLWRNORM: c_short = switch (builtin.os.tag) {
    .windows => 0x0010,
    .macos, .ios, .tvos, .watchos, .visionos => 0x0004,
    else => 0x0100,
};

pub const Pollfd = extern struct {
    fd: curl_socket_t,
    events: c_short,
    revents: c_short,
};

pub const CurlWaitfd = extern struct {
    fd: curl_socket_t,
    events: c_short,
    revents: c_short,
};

pub const EZ_POLLSET_DEF_COUNT = 2;

pub const EasyPollset = extern struct {
    sockets: ?[*]curl_socket_t,
    actions: ?[*]u8,
    n: c_uint,
    count: c_uint,
    def_sockets: [EZ_POLLSET_DEF_COUNT]curl_socket_t,
    def_actions: [EZ_POLLSET_DEF_COUNT]u8,
};

pub const CurlPollfds = extern struct {
    pfds: ?[*]Pollfd,
    n: c_uint,
    count: c_uint,
    allocated_pfds: c_uint,
};

pub const CurlWaitfds = extern struct {
    wfds: ?[*]CurlWaitfd,
    n: c_uint,
    count: c_uint,
};

const WIN_FD_SETSIZE = 64;

const WinFdSet = extern struct {
    fd_count: c_uint,
    fd_array: [WIN_FD_SETSIZE]curl_socket_t,
};

const WinSockaddrIn = extern struct {
    sin_family: i16,
    sin_port: u16,
    sin_addr: u32,
    sin_zero: [8]u8,
};

const win32 = struct {
    const WSAEINTR: c_int = 10004;
    const WSAEINVAL: c_int = 10022;
    const WSAEWOULDBLOCK: c_int = 10035;
    const SOCK_STREAM: c_int = 1;
    const IPPROTO_TCP: c_int = 6;
    const SOL_SOCKET: c_int = 0xffff;
    const SO_EXCLUSIVEADDRUSE: c_int = @bitCast(@as(u32, 0xfffffffb));

    extern "ws2_32" fn WSAGetLastError() callconv(.winapi) c_int;
    extern "ws2_32" fn WSASetLastError(iError: c_int) callconv(.winapi) void;
    extern "ws2_32" fn select(
        nfds: c_int,
        readfds: ?*WinFdSet,
        writefds: ?*WinFdSet,
        exceptfds: ?*WinFdSet,
        timeout: ?*const Timeval,
    ) callconv(.winapi) c_int;
    extern "ws2_32" fn __WSAFDIsSet(fd: curl_socket_t, set: *WinFdSet) callconv(.winapi) c_int;
    extern "ws2_32" fn socket(af: c_int, sock_type: c_int, protocol: c_int) callconv(.winapi) curl_socket_t;
    extern "ws2_32" fn closesocket(s: curl_socket_t) callconv(.winapi) c_int;
    extern "ws2_32" fn setsockopt(
        s: curl_socket_t,
        level: c_int,
        optname: c_int,
        optval: *const anyopaque,
        optlen: c_int,
    ) callconv(.winapi) c_int;
    extern "ws2_32" fn bind(s: curl_socket_t, name: *const anyopaque, namelen: c_int) callconv(.winapi) c_int;
    extern "ws2_32" fn getsockname(s: curl_socket_t, name: *anyopaque, namelen: *c_int) callconv(.winapi) c_int;
    extern "ws2_32" fn listen(s: curl_socket_t, backlog: c_int) callconv(.winapi) c_int;
    extern "ws2_32" fn connect(s: curl_socket_t, name: *const anyopaque, namelen: c_int) callconv(.winapi) c_int;
    extern "ws2_32" fn accept(s: curl_socket_t, addr: ?*anyopaque, addrlen: ?*c_int) callconv(.winapi) curl_socket_t;
    extern "ws2_32" fn send(s: curl_socket_t, buf: [*]const u8, len: c_int, flags: c_int) callconv(.winapi) c_int;
    extern "ws2_32" fn recv(s: curl_socket_t, buf: [*]u8, len: c_int, flags: c_int) callconv(.winapi) c_int;
};

const posix_c = struct {
    const nfds_t = if (builtin.os.tag.isDarwin()) c_uint else c_ulong;

    extern "c" fn poll(fds: ?[*]Pollfd, nfds: nfds_t, timeout: c_int) c_int;
    extern "c" fn pipe(pipefd: *[2]c_int) c_int;
    extern "c" fn read(fd: c_int, buf: [*]u8, count: usize) isize;
    extern "c" fn write(fd: c_int, buf: *const anyopaque, count: usize) isize;
    extern "c" fn close(fd: c_int) c_int;
};

const linux_c = struct {
    const EFD_CLOEXEC: c_int = 0o2000000;
    const EFD_NONBLOCK: c_int = 0o0004000;

    extern "c" fn eventfd(initval: c_uint, flags: c_int) c_int;
};

extern fn Curl_rand_bytes(data: ?*anyopaque, rnd: [*]u8, num: usize) callconv(.c) c_uint;

inline fn validSock(s: curl_socket_t) bool {
    if (builtin.os.tag == .windows) {
        return s < CURL_SOCKET_BAD;
    } else {
        return s >= 0;
    }
}

inline fn getSockErrno() c_int {
    if (builtin.os.tag == .windows) {
        return win32.WSAGetLastError();
    } else {
        return std.c._errno().*;
    }
}

inline fn setSockErrno(err: c_int) void {
    if (builtin.os.tag == .windows) {
        win32.WSASetLastError(err);
    } else {
        std.c._errno().* = err;
    }
}

inline fn isSockEintr(err: c_int) bool {
    if (builtin.os.tag == .windows) {
        return err == win32.WSAEINTR;
    } else {
        return err == @backingInt(std.c.E.INTR);
    }
}

inline fn isSockEagain(err: c_int) bool {
    if (builtin.os.tag == .windows) {
        return err == win32.WSAEWOULDBLOCK;
    } else {
        return err == @backingInt(std.c.E.AGAIN);
    }
}

// ============================================================================
// 1. lib/select.c (lib/select.h)
// ============================================================================

fn winFdSetAdd(fd: curl_socket_t, set: *WinFdSet) void {
    var i: c_uint = 0;
    while (i < set.fd_count) : (i += 1) {
        if (set.fd_array[i] == fd) return;
    }
    if (set.fd_count < WIN_FD_SETSIZE) {
        set.fd_array[set.fd_count] = fd;
        set.fd_count += 1;
    }
}

fn ourSelectWin(
    maxfd: curl_socket_t,
    fds_read: ?*WinFdSet,
    fds_write: ?*WinFdSet,
    fds_err: ?*WinFdSet,
    timeout_ms: timediff_t,
) c_int {
    const has_read = if (fds_read) |r| r.fd_count != 0 else false;
    const has_write = if (fds_write) |w| w.fd_count != 0 else false;
    const has_err = if (fds_err) |e| e.fd_count != 0 else false;

    if (!has_read and !has_write and !has_err) {
        return curlx_time_net.curlx_wait_ms(timeout_ms);
    }

    var pending_tv: Timeval = undefined;
    const ptimeout = curlx_time_net.curlx_mstotv(&pending_tv, timeout_ms);
    const nfds: c_int = @as(c_int, @truncate(@as(isize, @bitCast(maxfd)))) +% 1;

    return win32.select(
        nfds,
        if (has_read) fds_read else null,
        if (has_write) fds_write else null,
        if (has_err) fds_err else null,
        ptimeout,
    );
}

pub export fn Curl_socket_check(
    readfd0: curl_socket_t,
    readfd1: curl_socket_t,
    writefd: curl_socket_t,
    timeout_ms: timediff_t,
) callconv(.c) c_int {
    var pfd: [3]Pollfd = undefined;
    var num: usize = 0;

    if (readfd0 == CURL_SOCKET_BAD and readfd1 == CURL_SOCKET_BAD and writefd == CURL_SOCKET_BAD) {
        return curlx_time_net.curlx_wait_ms(timeout_ms);
    }

    if (readfd0 != CURL_SOCKET_BAD) {
        pfd[num].fd = readfd0;
        pfd[num].events = POLLRDNORM | POLLIN | POLLRDBAND | POLLPRI;
        pfd[num].revents = 0;
        num += 1;
    }
    if (readfd1 != CURL_SOCKET_BAD) {
        pfd[num].fd = readfd1;
        pfd[num].events = POLLRDNORM | POLLIN | POLLRDBAND | POLLPRI;
        pfd[num].revents = 0;
        num += 1;
    }
    if (writefd != CURL_SOCKET_BAD) {
        pfd[num].fd = writefd;
        pfd[num].events = POLLWRNORM | POLLOUT | POLLPRI;
        pfd[num].revents = 0;
        num += 1;
    }

    var r = Curl_poll(&pfd, @intCast(num), timeout_ms);
    if (r <= 0)
        return r;

    r = 0;
    num = 0;
    if (readfd0 != CURL_SOCKET_BAD) {
        if ((pfd[num].revents & (POLLRDNORM | POLLIN | POLLERR | POLLHUP)) != 0)
            r |= CURL_CSELECT_IN;
        if ((pfd[num].revents & (POLLPRI | POLLNVAL)) != 0)
            r |= CURL_CSELECT_ERR;
        num += 1;
    }
    if (readfd1 != CURL_SOCKET_BAD) {
        if ((pfd[num].revents & (POLLRDNORM | POLLIN | POLLERR | POLLHUP)) != 0)
            r |= CURL_CSELECT_IN2;
        if ((pfd[num].revents & (POLLPRI | POLLNVAL)) != 0)
            r |= CURL_CSELECT_ERR;
        num += 1;
    }
    if (writefd != CURL_SOCKET_BAD) {
        if ((pfd[num].revents & (POLLWRNORM | POLLOUT)) != 0)
            r |= CURL_CSELECT_OUT;
        if ((pfd[num].revents & (POLLERR | POLLHUP | POLLPRI | POLLNVAL)) != 0)
            r |= CURL_CSELECT_ERR;
    }

    return r;
}

pub export fn Curl_poll(ufds_opt: ?[*]Pollfd, nfds: c_uint, timeout_ms: timediff_t) callconv(.c) c_int {
    var fds_none = true;

    if (ufds_opt) |ufds| {
        var i: c_uint = 0;
        while (i < nfds) : (i += 1) {
            if (ufds[i].fd != CURL_SOCKET_BAD) {
                fds_none = false;
                break;
            }
        }
    }
    if (fds_none) {
        return curlx_time_net.curlx_wait_ms(timeout_ms);
    }

    const ufds = ufds_opt.?;

    if (builtin.os.tag != .windows) {
        var clamped_ms = timeout_ms;
        if (clamped_ms > std.math.maxInt(c_int)) {
            clamped_ms = std.math.maxInt(c_int);
        }
        const pending_ms: c_int = if (clamped_ms > 0)
            @intCast(clamped_ms)
        else if (clamped_ms < 0)
            -1
        else
            0;

        var r = posix_c.poll(ufds, @intCast(nfds), pending_ms);
        if (r <= 0) {
            if (r == -1 and isSockEintr(getSockErrno())) {
                r = 0;
            }
            return r;
        }

        var i: c_uint = 0;
        while (i < nfds) : (i += 1) {
            if (ufds[i].fd == CURL_SOCKET_BAD)
                continue;
            if ((ufds[i].revents & POLLHUP) != 0)
                ufds[i].revents |= POLLIN;
            if ((ufds[i].revents & POLLERR) != 0)
                ufds[i].revents |= POLLIN | POLLOUT;
        }
        return r;
    } else {
        var fds_read: WinFdSet = .{ .fd_count = 0, .fd_array = undefined };
        var fds_write: WinFdSet = .{ .fd_count = 0, .fd_array = undefined };
        var fds_err: WinFdSet = .{ .fd_count = 0, .fd_array = undefined };
        var maxfd: curl_socket_t = CURL_SOCKET_BAD;

        var i: c_uint = 0;
        while (i < nfds) : (i += 1) {
            ufds[i].revents = 0;
            if (ufds[i].fd == CURL_SOCKET_BAD)
                continue;
            if (!validSock(ufds[i].fd)) {
                setSockErrno(win32.WSAEINVAL);
                return -1;
            }
            if ((ufds[i].events & (POLLIN | POLLOUT | POLLPRI | POLLRDNORM | POLLWRNORM | POLLRDBAND)) != 0) {
                if (ufds[i].fd > maxfd)
                    maxfd = ufds[i].fd;
                if ((ufds[i].events & (POLLRDNORM | POLLIN)) != 0)
                    winFdSetAdd(ufds[i].fd, &fds_read);
                if ((ufds[i].events & (POLLWRNORM | POLLOUT)) != 0)
                    winFdSetAdd(ufds[i].fd, &fds_write);
                if ((ufds[i].events & (POLLRDBAND | POLLPRI)) != 0)
                    winFdSetAdd(ufds[i].fd, &fds_err);
            }
        }

        var r = ourSelectWin(maxfd, &fds_read, &fds_write, &fds_err, timeout_ms);
        if (r <= 0) {
            if (r == -1 and isSockEintr(getSockErrno())) {
                r = 0;
            }
            return r;
        }

        r = 0;
        i = 0;
        while (i < nfds) : (i += 1) {
            ufds[i].revents = 0;
            if (ufds[i].fd == CURL_SOCKET_BAD)
                continue;
            if (win32.__WSAFDIsSet(ufds[i].fd, &fds_read) != 0) {
                if ((ufds[i].events & POLLRDNORM) != 0)
                    ufds[i].revents |= POLLRDNORM;
                if ((ufds[i].events & POLLIN) != 0)
                    ufds[i].revents |= POLLIN;
            }
            if (win32.__WSAFDIsSet(ufds[i].fd, &fds_write) != 0) {
                if ((ufds[i].events & POLLWRNORM) != 0)
                    ufds[i].revents |= POLLWRNORM;
                if ((ufds[i].events & POLLOUT) != 0)
                    ufds[i].revents |= POLLOUT;
            }
            if (win32.__WSAFDIsSet(ufds[i].fd, &fds_err) != 0) {
                if ((ufds[i].events & POLLRDBAND) != 0)
                    ufds[i].revents |= POLLRDBAND;
                if ((ufds[i].events & POLLPRI) != 0)
                    ufds[i].revents |= POLLPRI;
            }
            if (ufds[i].revents != 0)
                r += 1;
        }
        return r;
    }
}

pub export fn Curl_pollfds_init(
    cpfds: *CurlPollfds,
    static_pfds: ?[*]Pollfd,
    static_count: c_uint,
) callconv(.c) void {
    cpfds.* = .{
        .pfds = null,
        .n = 0,
        .count = 0,
        .allocated_pfds = 0,
    };
    if (static_pfds != null and static_count != 0) {
        cpfds.pfds = static_pfds;
        cpfds.count = static_count;
    }
}

pub export fn Curl_pollfds_reset(cpfds: *CurlPollfds) callconv(.c) void {
    cpfds.n = 0;
}

pub export fn Curl_pollfds_cleanup(cpfds: *CurlPollfds) callconv(.c) void {
    if ((cpfds.allocated_pfds & 1) != 0) {
        mem.freeTyped(cpfds.pfds);
        cpfds.pfds = null;
        cpfds.count = 0;
        cpfds.allocated_pfds = 0;
    }
    cpfds.n = 0;
}

fn cpfdsIncrease(cpfds: *CurlPollfds, inc: c_uint) c_uint {
    const new_count: c_uint = cpfds.count + inc;
    const new_fds = mem.callocMany(Pollfd, new_count) orelse return CURLE_OUT_OF_MEMORY;

    if (cpfds.count > 0) {
        if (cpfds.pfds) |old_pfds| {
            @memcpy(new_fds[0..cpfds.count], old_pfds[0..cpfds.count]);
        }
    }
    if ((cpfds.allocated_pfds & 1) != 0) {
        mem.freeTyped(cpfds.pfds);
    }
    cpfds.pfds = new_fds;
    cpfds.count = new_count;
    cpfds.allocated_pfds = 1;
    return CURLE_OK;
}

fn cpfdsAddSock(cpfds: *CurlPollfds, sock: curl_socket_t, events: c_short, fold: bool) c_uint {
    if (fold and cpfds.n <= @as(c_uint, @intCast(std.math.maxInt(c_int)))) {
        const pfds = cpfds.pfds.?;
        var i: c_int = @as(c_int, @intCast(cpfds.n)) - 1;
        while (i >= 0) : (i -= 1) {
            const idx: usize = @intCast(i);
            if (sock == pfds[idx].fd) {
                pfds[idx].events |= events;
                return CURLE_OK;
            }
        }
    }
    if (cpfds.n >= cpfds.count and cpfdsIncrease(cpfds, 100) != CURLE_OK) {
        return CURLE_OUT_OF_MEMORY;
    }
    const pfds = cpfds.pfds.?;
    pfds[cpfds.n].fd = sock;
    pfds[cpfds.n].events = events;
    cpfds.n += 1;
    return CURLE_OK;
}

pub export fn Curl_pollfds_add_sock(
    cpfds: *CurlPollfds,
    sock: curl_socket_t,
    events: c_short,
) callconv(.c) c_uint {
    return cpfdsAddSock(cpfds, sock, events, false);
}

pub export fn Curl_pollfds_add_ps(cpfds: *CurlPollfds, ps: *EasyPollset) callconv(.c) c_uint {
    const actions = ps.actions orelse return CURLE_OK;
    const sockets = ps.sockets orelse return CURLE_OK;
    var i: usize = 0;
    while (i < ps.n) : (i += 1) {
        var events: c_short = 0;
        if ((actions[i] & CURL_POLL_IN) != 0)
            events |= POLLIN;
        if ((actions[i] & CURL_POLL_OUT) != 0)
            events |= POLLOUT;
        if (events != 0 and cpfdsAddSock(cpfds, sockets[i], events, true) != CURLE_OK)
            return CURLE_OUT_OF_MEMORY;
    }
    return CURLE_OK;
}

pub export fn Curl_waitfds_init(
    cwfds: *CurlWaitfds,
    static_wfds: ?[*]CurlWaitfd,
    static_count: c_uint,
) callconv(.c) void {
    cwfds.* = .{
        .wfds = static_wfds,
        .n = 0,
        .count = static_count,
    };
}

fn cwfdsAddSock(cwfds: *CurlWaitfds, sock: curl_socket_t, events: c_short) c_uint {
    const wfds = cwfds.wfds orelse return 1;
    if (cwfds.n <= @as(c_uint, @intCast(std.math.maxInt(c_int)))) {
        var i: c_int = @as(c_int, @intCast(cwfds.n)) - 1;
        while (i >= 0) : (i -= 1) {
            const idx: usize = @intCast(i);
            if (sock == wfds[idx].fd) {
                wfds[idx].events |= events;
                return 0;
            }
        }
    }
    if (cwfds.n < cwfds.count) {
        wfds[cwfds.n].fd = sock;
        wfds[cwfds.n].events = events;
        cwfds.n += 1;
    }
    return 1;
}

pub export fn Curl_waitfds_add_ps(cwfds: *CurlWaitfds, ps: *EasyPollset) callconv(.c) c_uint {
    var need: c_uint = 0;
    const actions = ps.actions orelse return 0;
    const sockets = ps.sockets orelse return 0;
    var i: usize = 0;
    while (i < ps.n) : (i += 1) {
        var events: c_short = 0;
        if ((actions[i] & CURL_POLL_IN) != 0)
            events |= CURL_WAIT_POLLIN;
        if ((actions[i] & CURL_POLL_OUT) != 0)
            events |= CURL_WAIT_POLLOUT;
        if (events != 0)
            need += cwfdsAddSock(cwfds, sockets[i], events);
    }
    return need;
}

pub export fn Curl_pollset_reset(ps: *EasyPollset) callconv(.c) void {
    ps.n = 0;
}

pub export fn Curl_pollset_init(ps: *EasyPollset) callconv(.c) void {
    ps.sockets = &ps.def_sockets;
    ps.actions = &ps.def_actions;
    ps.count = EZ_POLLSET_DEF_COUNT;
    ps.n = 0;
    Curl_pollset_reset(ps);
}

pub export fn Curl_pollset_create() callconv(.c) ?*EasyPollset {
    const ps = mem.create(EasyPollset) orelse return null;
    Curl_pollset_init(ps);
    return ps;
}

pub export fn Curl_pollset_cleanup(ps: *EasyPollset) callconv(.c) void {
    const def_sockets_ptr: [*]curl_socket_t = &ps.def_sockets;
    if (ps.sockets != def_sockets_ptr) {
        mem.freeTyped(ps.sockets);
        ps.sockets = def_sockets_ptr;
    }
    const def_actions_ptr: [*]u8 = &ps.def_actions;
    if (ps.actions != def_actions_ptr) {
        mem.freeTyped(ps.actions);
        ps.actions = def_actions_ptr;
    }
    ps.count = EZ_POLLSET_DEF_COUNT;
    Curl_pollset_reset(ps);
}

pub export fn Curl_pollset_move(to: *EasyPollset, from: *EasyPollset) callconv(.c) void {
    Curl_pollset_cleanup(to);
    const from_def_sockets: [*]curl_socket_t = &from.def_sockets;
    if (from.sockets != from_def_sockets) {
        to.sockets = from.sockets;
        to.actions = from.actions;
        to.count = from.count;
        to.n = from.n;
        Curl_pollset_init(from);
    } else {
        const to_sockets = to.sockets.?;
        const from_sockets = from.sockets.?;
        const to_actions = to.actions.?;
        const from_actions = from.actions.?;
        @memcpy(to_sockets[0..to.count], from_sockets[0..to.count]);
        @memcpy(to_actions[0..to.count], from_actions[0..to.count]);
        to.n = from.n;
        Curl_pollset_init(from);
    }
}

fn pollsetGrow(ps: *EasyPollset) error{OutOfMemory}!void {
    const doubled = ps.count *% 2;
    const new_count: c_uint = if (doubled > 8) doubled else 8;
    if (new_count <= ps.count)
        return error.OutOfMemory;
    const nsockets = mem.callocMany(curl_socket_t, new_count) orelse return error.OutOfMemory;
    errdefer mem.freeTyped(nsockets);
    const nactions = mem.callocMany(u8, new_count) orelse return error.OutOfMemory;

    @memcpy(nsockets[0..ps.count], ps.sockets.?[0..ps.count]);
    @memcpy(nactions[0..ps.count], ps.actions.?[0..ps.count]);
    const def_sockets_ptr: [*]curl_socket_t = &ps.def_sockets;
    if (ps.sockets != def_sockets_ptr)
        mem.freeTyped(ps.sockets);
    ps.sockets = nsockets;
    const def_actions_ptr: [*]u8 = &ps.def_actions;
    if (ps.actions != def_actions_ptr)
        mem.freeTyped(ps.actions);
    ps.actions = nactions;
    ps.count = new_count;
}

pub export fn Curl_pollset_change(
    data: ?*anyopaque,
    ps: *EasyPollset,
    sock: curl_socket_t,
    add_flags: c_int,
    remove_flags: c_int,
) callconv(.c) c_uint {
    _ = data;
    if (!validSock(sock))
        return CURLE_BAD_FUNCTION_ARGUMENT;

    const sockets = ps.sockets.?;
    const actions = ps.actions.?;
    var i: c_uint = 0;
    while (i < ps.n) : (i += 1) {
        if (sockets[i] == sock) {
            const rem_mask: u8 = @truncate(@as(c_uint, @bitCast(remove_flags)));
            const add_mask: u8 = @truncate(@as(c_uint, @bitCast(add_flags)));
            actions[i] &= ~rem_mask;
            actions[i] |= add_mask;
            if (actions[i] == 0) {
                if ((i + 1) < ps.n) {
                    const count_move = ps.n - (i + 1);
                    std.mem.copyForwards(curl_socket_t, sockets[i .. i + count_move], sockets[i + 1 .. i + 1 + count_move]);
                    std.mem.copyForwards(u8, actions[i .. i + count_move], actions[i + 1 .. i + 1 + count_move]);
                }
                ps.n -= 1;
            }
            return CURLE_OK;
        }
    }

    if (add_flags != 0) {
        if (i >= ps.count) {
            pollsetGrow(ps) catch return CURLE_OUT_OF_MEMORY;
        }
        if (i < ps.count) {
            ps.sockets.?[i] = sock;
            ps.actions.?[i] = @truncate(@as(c_uint, @bitCast(add_flags)));
            ps.n = i + 1;
        }
    }
    return CURLE_OK;
}

pub export fn Curl_pollset_set(
    data: ?*anyopaque,
    ps: *EasyPollset,
    sock: curl_socket_t,
    do_in: bool,
    do_out: bool,
) callconv(.c) c_uint {
    const add_flags: c_int = (if (do_in) @as(c_int, CURL_POLL_IN) else 0) |
        (if (do_out) @as(c_int, CURL_POLL_OUT) else 0);
    const remove_flags: c_int = (if (!do_in) @as(c_int, CURL_POLL_IN) else 0) |
        (if (!do_out) @as(c_int, CURL_POLL_OUT) else 0);
    return Curl_pollset_change(data, ps, sock, add_flags, remove_flags);
}

pub export fn Curl_pollset_remove(ps: *EasyPollset, sock: curl_socket_t) callconv(.c) void {
    const sockets = ps.sockets orelse return;
    const actions = ps.actions orelse return;
    var i: c_uint = 0;
    while (i < ps.n) : (i += 1) {
        if (sockets[i] == sock) {
            if ((i + 1) < ps.n) {
                const count_move = ps.n - (i + 1);
                std.mem.copyForwards(curl_socket_t, sockets[i .. i + count_move], sockets[i + 1 .. i + 1 + count_move]);
                std.mem.copyForwards(u8, actions[i .. i + count_move], actions[i + 1 .. i + 1 + count_move]);
            }
            ps.n -= 1;
            return;
        }
    }
}

pub export fn Curl_pollset_poll(
    data: ?*anyopaque,
    ps: *EasyPollset,
    timeout_ms: timediff_t,
) callconv(.c) c_int {
    _ = data;
    if (ps.n == 0)
        return curlx_time_net.curlx_wait_ms(timeout_ms);

    const pfds = mem.callocMany(Pollfd, ps.n) orelse return -1;
    defer mem.freeTyped(pfds);

    const sockets = ps.sockets.?;
    const actions = ps.actions.?;
    var npfds: c_uint = 0;
    var i: c_uint = 0;
    while (i < ps.n) : (i += 1) {
        var events: c_short = 0;
        if ((actions[i] & CURL_POLL_IN) != 0)
            events |= POLLIN;
        if ((actions[i] & CURL_POLL_OUT) != 0)
            events |= POLLOUT;
        if (events != 0) {
            pfds[npfds].fd = sockets[i];
            pfds[npfds].events = events;
            npfds += 1;
        }
    }

    return Curl_poll(pfds, npfds, timeout_ms);
}

pub export fn Curl_pollset_check(
    data: ?*anyopaque,
    ps: *EasyPollset,
    sock: curl_socket_t,
    pwant_read: *bool,
    pwant_write: *bool,
) callconv(.c) void {
    _ = data;
    const sockets = ps.sockets orelse {
        pwant_read.* = false;
        pwant_write.* = false;
        return;
    };
    const actions = ps.actions.?;
    var i: c_uint = 0;
    while (i < ps.n) : (i += 1) {
        if (sockets[i] == sock) {
            pwant_read.* = (actions[i] & CURL_POLL_IN) != 0;
            pwant_write.* = (actions[i] & CURL_POLL_OUT) != 0;
            return;
        }
    }
    pwant_read.* = false;
    pwant_write.* = false;
}

pub export fn Curl_pollset_want_recv(
    data: ?*anyopaque,
    ps: *EasyPollset,
    sock: curl_socket_t,
) callconv(.c) bool {
    _ = data;
    const sockets = ps.sockets orelse return false;
    const actions = ps.actions.?;
    var i: c_uint = 0;
    while (i < ps.n) : (i += 1) {
        if (sockets[i] == sock and (actions[i] & CURL_POLL_IN) != 0)
            return true;
    }
    return false;
}

pub export fn Curl_pollset_want_send(
    data: ?*anyopaque,
    ps: *EasyPollset,
    sock: curl_socket_t,
) callconv(.c) bool {
    _ = data;
    const sockets = ps.sockets orelse return false;
    const actions = ps.actions.?;
    var i: c_uint = 0;
    while (i < ps.n) : (i += 1) {
        if (sockets[i] == sock and (actions[i] & CURL_POLL_OUT) != 0)
            return true;
    }
    return false;
}

// ============================================================================
// 2. lib/socketpair.c (lib/socketpair.h)
// ============================================================================

fn wakeupEventfd(socks: *[2]curl_socket_t, nonblocking: bool) c_int {
    const flags: c_int = if (nonblocking)
        linux_c.EFD_CLOEXEC | linux_c.EFD_NONBLOCK
    else
        linux_c.EFD_CLOEXEC;
    const efd = linux_c.eventfd(0, flags);
    if (efd == -1) {
        socks[0] = CURL_SOCKET_BAD;
        socks[1] = CURL_SOCKET_BAD;
        return -1;
    }
    socks[0] = efd;
    socks[1] = efd;
    return 0;
}

fn wakeupPipeImpl(socks: *[2]curl_socket_t, nonblocking: bool) error{WakeupFailed}!void {
    if (posix_c.pipe(socks) != 0)
        return error.WakeupFailed;
    errdefer {
        _ = posix_c.close(socks[0]);
        _ = posix_c.close(socks[1]);
        socks[0] = CURL_SOCKET_BAD;
        socks[1] = CURL_SOCKET_BAD;
    }

    const F_SETFD: c_int = 2;
    const FD_CLOEXEC: c_int = 1;
    if (std.c.fcntl(socks[0], F_SETFD, FD_CLOEXEC) != 0 or
        std.c.fcntl(socks[1], F_SETFD, FD_CLOEXEC) != 0)
    {
        return error.WakeupFailed;
    }

    if (nonblocking) {
        if (curlx_time_net.curlx_nonblock(socks[0], 1) < 0 or
            curlx_time_net.curlx_nonblock(socks[1], 1) < 0)
        {
            return error.WakeupFailed;
        }
    }
}

fn wakeupPipe(socks: *[2]curl_socket_t, nonblocking: bool) c_int {
    wakeupPipeImpl(socks, nonblocking) catch return -1;
    return 0;
}

fn wakeupInetImpl(socks: *[2]curl_socket_t, nonblocking: bool) error{WakeupFailed}!void {
    const listener = win32.socket(curlx_time_net.AF_INET, win32.SOCK_STREAM, win32.IPPROTO_TCP);
    if (listener == CURL_SOCKET_BAD)
        return error.WakeupFailed;
    defer _ = win32.closesocket(listener);

    var inaddr: WinSockaddrIn = .{
        .sin_family = @intCast(curlx_time_net.AF_INET),
        .sin_port = 0,
        .sin_addr = std.mem.nativeToBig(u32, 0x7f000001),
        .sin_zero = .{ 0, 0, 0, 0, 0, 0, 0, 0 },
    };
    var addrlen: c_int = @sizeOf(WinSockaddrIn);

    socks[0] = CURL_SOCKET_BAD;
    socks[1] = CURL_SOCKET_BAD;
    errdefer {
        _ = win32.closesocket(socks[0]);
        _ = win32.closesocket(socks[1]);
        socks[0] = CURL_SOCKET_BAD;
        socks[1] = CURL_SOCKET_BAD;
    }

    var exclusive: c_int = 1;
    if (win32.setsockopt(
        listener,
        win32.SOL_SOCKET,
        win32.SO_EXCLUSIVEADDRUSE,
        &exclusive,
        @sizeOf(c_int),
    ) == -1) {
        return error.WakeupFailed;
    }

    if (win32.bind(listener, &inaddr, @sizeOf(WinSockaddrIn)) == -1)
        return error.WakeupFailed;
    if (win32.getsockname(listener, &inaddr, &addrlen) == -1 or addrlen < @sizeOf(WinSockaddrIn))
        return error.WakeupFailed;
    if (win32.listen(listener, 1) == -1)
        return error.WakeupFailed;

    socks[0] = win32.socket(curlx_time_net.AF_INET, win32.SOCK_STREAM, 0);
    if (socks[0] == CURL_SOCKET_BAD)
        return error.WakeupFailed;
    if (win32.connect(socks[0], &inaddr, @sizeOf(WinSockaddrIn)) == -1)
        return error.WakeupFailed;

    if (curlx_time_net.curlx_nonblock(listener, 1) < 0)
        return error.WakeupFailed;

    var pfd: [1]Pollfd = .{.{
        .fd = listener,
        .events = POLLIN,
        .revents = 0,
    }};
    _ = Curl_poll(&pfd, 1, 1000);
    socks[1] = win32.accept(listener, null, null);
    if (socks[1] == CURL_SOCKET_BAD)
        return error.WakeupFailed;

    const start = curlx_time_net.curlx_now();
    var rnd: [9]u8 = undefined;
    var check: [9]u8 = undefined;
    var offset: usize = 0;

    if (Curl_rand_bytes(null, &rnd, rnd.len) != CURLE_OK)
        return error.WakeupFailed;

    _ = win32.send(socks[0], &rnd, @intCast(rnd.len), 0);

    while (true) {
        if (curlx_time_net.curlx_timediff_ms(curlx_time_net.curlx_now(), start) > 60 * 1000)
            return error.WakeupFailed;

        pfd[0].fd = socks[1];
        pfd[0].events = POLLIN;
        pfd[0].revents = 0;
        _ = Curl_poll(&pfd, 1, 1000);

        const rem = check.len - offset;
        const nread = win32.recv(socks[1], check[offset..].ptr, @intCast(rem), 0);
        if (nread == 0) {
            return error.WakeupFailed;
        } else if (nread == -1) {
            const sockerr = getSockErrno();
            if (isSockEagain(sockerr))
                continue;
            return error.WakeupFailed;
        }
        offset += @intCast(nread);
        if (offset < check.len)
            continue;
        if (!std.mem.eql(u8, &rnd, &check))
            return error.WakeupFailed;
        break;
    }

    if (nonblocking) {
        if (curlx_time_net.curlx_nonblock(socks[0], 1) < 0 or
            curlx_time_net.curlx_nonblock(socks[1], 1) < 0)
        {
            return error.WakeupFailed;
        }
    }
}

fn wakeupInet(socks: *[2]curl_socket_t, nonblocking: bool) c_int {
    wakeupInetImpl(socks, nonblocking) catch return -1;
    return 0;
}

pub export fn Curl_wakeup_init(socks: *[2]curl_socket_t, nonblocking: bool) callconv(.c) c_int {
    return switch (builtin.os.tag) {
        .linux => wakeupEventfd(socks, nonblocking),
        .windows => wakeupInet(socks, nonblocking),
        else => wakeupPipe(socks, nonblocking),
    };
}

pub export fn Curl_wakeup_signal(socks: *[2]curl_socket_t) callconv(.c) c_int {
    var sockerr: c_int = 0;

    while (true) {
        sockerr = 0;
        const rc: isize = switch (builtin.os.tag) {
            .linux => blk: {
                const buf: [1]u64 = .{1};
                break :blk posix_c.write(socks[1], &buf, @sizeOf(@TypeOf(buf)));
            },
            .windows => blk: {
                const buf: [1]u8 = .{1};
                break :blk @as(isize, win32.send(socks[1], &buf, 1, 0));
            },
            else => blk: {
                const buf: [1]u8 = .{1};
                break :blk posix_c.write(socks[1], &buf, 1);
            },
        };

        if (rc < 0) {
            sockerr = getSockErrno();
            if (builtin.os.tag != .windows and isSockEintr(sockerr))
                continue;
            if (isSockEagain(sockerr))
                sockerr = 0;
        }
        break;
    }
    return sockerr;
}

pub export fn Curl_wakeup_consume(socks: *[2]curl_socket_t, all: bool) callconv(.c) c_uint {
    var buf: [64]u8 = undefined;
    var result: c_uint = CURLE_OK;

    while (true) {
        const rc: isize = if (builtin.os.tag == .windows)
            @as(isize, win32.recv(socks[0], &buf, @intCast(buf.len), 0))
        else
            posix_c.read(socks[0], &buf, buf.len);

        if (rc == 0) {
            break;
        } else if (rc < 0) {
            const sockerr = getSockErrno();
            if (builtin.os.tag != .windows and isSockEintr(sockerr))
                continue;
            if (isSockEagain(sockerr))
                break;
            result = CURLE_READ_ERROR;
            break;
        }
        if (!all) break;
    }
    return result;
}

pub export fn Curl_wakeup_destroy(socks: *[2]curl_socket_t) callconv(.c) void {
    if (builtin.os.tag != .linux) {
        if (socks[1] != CURL_SOCKET_BAD) {
            if (builtin.os.tag == .windows) {
                _ = win32.closesocket(socks[1]);
            } else {
                _ = posix_c.close(socks[1]);
            }
        }
    }
    if (socks[0] != CURL_SOCKET_BAD) {
        if (builtin.os.tag == .windows) {
            _ = win32.closesocket(socks[0]);
        } else {
            _ = posix_c.close(socks[0]);
        }
    }
    socks[0] = CURL_SOCKET_BAD;
    socks[1] = CURL_SOCKET_BAD;
}

// ============================================================================
// 3. lib/ratelimit.c (lib/ratelimit.h)
// ============================================================================

const CURL_US_PER_SEC: timediff_t = 1000000;
const CURL_RLIMIT_MIN_RATE: i64 = 4 * 1024;
const CURL_RLIMIT_STEP_MIN_MS: i64 = 2;

pub const CurlRlimit = extern struct {
    rate_per_sec: i64,
    burst_per_sec: i64,
    rate_per_step: i64,
    burst_per_step: i64,
    step_us: timediff_t,
    tokens: i64,
    spare_us: timediff_t,
    ts: Curltime,
    blocked: c_uint,
};

fn rlimitUpdate(r: *CurlRlimit, pts: *const Curltime) void {
    if (r.ts.tv_sec == pts.tv_sec and r.ts.tv_usec == pts.tv_usec)
        return;

    var elapsed_us: timediff_t = curlx_time_net.curlx_ptimediff_us(pts, &r.ts);
    if (elapsed_us < 0)
        return;

    elapsed_us += r.spare_us;
    if (elapsed_us < r.step_us)
        return;

    r.ts = pts.*;
    const elapsed_steps: timediff_t = @divTrunc(elapsed_us, r.step_us);
    r.spare_us = @rem(elapsed_us, r.step_us);

    const token_gain: i64 = if (r.rate_per_step > @divTrunc(std.math.maxInt(i64), elapsed_steps))
        std.math.maxInt(i64)
    else
        r.rate_per_step * elapsed_steps;

    if ((std.math.maxInt(i64) - token_gain) > r.tokens)
        r.tokens += token_gain
    else
        r.tokens = std.math.maxInt(i64);

    if (r.burst_per_step != 0 and (r.tokens > r.burst_per_step)) {
        r.tokens = r.burst_per_step;
    }
}

fn rlimitTuneSteps(r: *CurlRlimit, tokens_total: i64) void {
    if (r.rate_per_step == 0 or
        tokens_total <= 1 or
        tokens_total > @divTrunc(std.math.maxInt(i64), 1000))
        return;

    var tokens_last: i64 = @divTrunc(tokens_total, 100);
    if (tokens_last == 0)
        tokens_last = 1
    else if (tokens_last > CURL_RLIMIT_MIN_RATE)
        tokens_last = CURL_RLIMIT_MIN_RATE;
    const tokens_main: i64 = tokens_total - tokens_last;

    const msteps: i64 = @divTrunc(tokens_main * 1000, r.rate_per_step);
    if (msteps < CURL_RLIMIT_STEP_MIN_MS) {
        return;
    } else if (msteps < 1000) {
        r.step_us = msteps * 1000;
        r.rate_per_step = tokens_main;
        r.tokens = r.rate_per_step;
    } else {
        const ms_unaccounted: i64 = @rem(msteps, 1000);
        const mstep_inc: i64 = @divTrunc(ms_unaccounted, @divTrunc(msteps, 1000));
        if (mstep_inc != 0) {
            const rate_inc: i64 = @divTrunc(r.rate_per_step * mstep_inc, 1000);
            if (rate_inc != 0) {
                r.step_us = CURL_US_PER_SEC + (mstep_inc * 1000);
                r.rate_per_step += rate_inc;
                r.tokens = r.rate_per_step;
                if (r.burst_per_step != 0) {
                    const burst_inc: i64 = @divTrunc(r.burst_per_step * mstep_inc, 1000);
                    if (burst_inc != 0)
                        r.burst_per_step += burst_inc;
                }
            }
        }
    }
}

pub export fn Curl_rlimit_init(
    r: *CurlRlimit,
    rate_per_sec: i64,
    burst_per_sec: i64,
    pts: *const Curltime,
) callconv(.c) void {
    r.rate_per_sec = rate_per_sec;
    r.rate_per_step = rate_per_sec;
    r.burst_per_sec = burst_per_sec;
    r.burst_per_step = burst_per_sec;
    r.step_us = CURL_US_PER_SEC;
    r.spare_us = 0;
    r.tokens = r.rate_per_step;
    r.ts = pts.*;
    r.blocked = 0;
}

pub export fn Curl_rlimit_start(
    r: *CurlRlimit,
    pts: *const Curltime,
    total_tokens: i64,
) callconv(.c) void {
    r.rate_per_step = r.rate_per_sec;
    r.burst_per_step = r.burst_per_sec;
    r.step_us = CURL_US_PER_SEC;
    r.spare_us = 0;
    r.tokens = r.rate_per_step;
    r.ts = pts.*;
    rlimitTuneSteps(r, total_tokens);
}

pub export fn Curl_rlimit_per_step(r: *CurlRlimit) callconv(.c) i64 {
    return r.rate_per_step;
}

pub export fn Curl_rlimit_active(r: *CurlRlimit) callconv(.c) bool {
    return (r.rate_per_step > 0) or ((r.blocked & 1) != 0);
}

pub export fn Curl_rlimit_is_blocked(r: *CurlRlimit) callconv(.c) bool {
    return (r.blocked & 1) != 0;
}

pub export fn Curl_rlimit_avail(r: *CurlRlimit, pts_opt: ?*const Curltime) callconv(.c) i64 {
    var ts: Curltime = undefined;

    if ((r.blocked & 1) != 0) {
        return 0;
    } else if (r.rate_per_step != 0) {
        const pts: *const Curltime = pts_opt orelse blk: {
            curlx_time_net.curlx_pnow(&ts);
            break :blk &ts;
        };
        rlimitUpdate(r, pts);
        return r.tokens;
    } else {
        return std.math.maxInt(i64);
    }
}

pub export fn Curl_rlimit_drain(
    r: *CurlRlimit,
    tokens: usize,
    pts_opt: ?*const Curltime,
) callconv(.c) void {
    var ts: Curltime = undefined;

    if ((r.blocked & 1) != 0 or r.rate_per_step == 0)
        return;

    const pts: *const Curltime = pts_opt orelse blk: {
        curlx_time_net.curlx_pnow(&ts);
        break :blk &ts;
    };
    rlimitUpdate(r, pts);

    if (@sizeOf(usize) >= 8 and tokens > @as(usize, @intCast(std.math.maxInt(i64)))) {
        r.tokens = std.math.maxInt(i64);
    } else {
        const val: i64 = @intCast(tokens);
        if ((std.math.minInt(i64) + val) < r.tokens)
            r.tokens -= val
        else
            r.tokens = std.math.minInt(i64);
    }
}

pub export fn Curl_rlimit_wait_ms(r: *CurlRlimit, pts: *const Curltime) callconv(.c) timediff_t {
    if ((r.blocked & 1) != 0 or r.rate_per_step == 0)
        return 0;
    rlimitUpdate(r, pts);
    if (r.tokens > 0)
        return 0;

    var wait_us: timediff_t = r.step_us - r.spare_us;
    if (r.tokens < 0) {
        const debt_pct: i64 = @divTrunc((-%r.tokens) *% 100, r.rate_per_step);
        if (debt_pct != 0)
            wait_us += @divTrunc(r.step_us * debt_pct, 100);
    }

    const elapsed_us: timediff_t = curlx_time_net.curlx_ptimediff_us(pts, &r.ts);
    if (elapsed_us >= wait_us)
        return 0;
    wait_us -= elapsed_us;
    return @divTrunc(wait_us + 999, 1000);
}

pub export fn Curl_rlimit_next_step_ms(r: *CurlRlimit, pts: *const Curltime) callconv(.c) timediff_t {
    if ((r.blocked & 1) == 0 and r.rate_per_step != 0) {
        const elapsed_us: timediff_t = curlx_time_net.curlx_ptimediff_us(pts, &r.ts) + r.spare_us;
        if (r.step_us > elapsed_us) {
            const next_us: timediff_t = r.step_us - elapsed_us;
            return @divTrunc(next_us + 999, 1000);
        }
    }
    return 0;
}

pub export fn Curl_rlimit_block(
    r: *CurlRlimit,
    activate: bool,
    pts: *const Curltime,
) callconv(.c) void {
    const is_blocked = (r.blocked & 1) != 0;
    if (activate == is_blocked)
        return;

    r.ts = pts.*;
    r.blocked = if (activate) 1 else 0;
    if (!activate) {
        Curl_rlimit_start(r, pts, -1);
    } else {
        r.tokens = 0;
    }
}

// ============================================================================
// 4. lib/if2ip.c (lib/if2ip.h)
// ============================================================================

pub const IPV6_SCOPE_GLOBAL: c_uint = 0;
pub const IPV6_SCOPE_LINKLOCAL: c_uint = 1;
pub const IPV6_SCOPE_SITELOCAL: c_uint = 2;
pub const IPV6_SCOPE_UNIQUELOCAL: c_uint = 3;
pub const IPV6_SCOPE_NODELOCAL: c_uint = 4;

pub const IF2IP_NOT_FOUND: c_uint = 0;
pub const IF2IP_AF_NOT_SUPPORTED: c_uint = 1;
pub const IF2IP_FOUND: c_uint = 2;

const is_darwin = builtin.os.tag.isDarwin();

pub const Sockaddr = if (is_darwin)
    extern struct {
        sa_len: u8,
        sa_family: u8,
        sa_data: [14]u8,
    }
else
    extern struct {
        sa_family: u16,
        sa_data: [14]u8,
    };

pub const SockaddrIn = if (is_darwin)
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

pub const SockaddrIn6 = if (is_darwin)
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

const IfaSockaddr = extern union {
    sa: Sockaddr,
    in4: SockaddrIn,
    in6: SockaddrIn6,
};

const Ifaddrs = extern struct {
    ifa_next: ?*Ifaddrs,
    ifa_name: ?[*:0]const u8,
    ifa_flags: c_uint,
    ifa_addr: ?*const IfaSockaddr,
};

const ifaddrs_c = struct {
    extern "c" fn getifaddrs(ifap: *?*Ifaddrs) c_int;
    extern "c" fn freeifaddrs(ifa: ?*Ifaddrs) void;
};

pub export fn Curl_ipv6_scope(sa_raw: *const anyopaque) callconv(.c) c_uint {
    const addr: *const IfaSockaddr = @ptrCast(@alignCast(sa_raw));
    if (@as(c_int, addr.sa.sa_family) == curlx_time_net.AF_INET6) {
        const b = &addr.in6.sin6_addr;
        var w: u16 = (@as(u16, b[0]) << 8) | @as(u16, b[1]);

        if ((b[0] & 0xFE) == 0xFC)
            return IPV6_SCOPE_UNIQUELOCAL;
        switch (w & 0xFFC0) {
            0xFE80 => return IPV6_SCOPE_LINKLOCAL,
            0xFEC0 => return IPV6_SCOPE_SITELOCAL,
            0x0000 => {
                w = @as(u16, b[1] | b[2] | b[3] | b[4] | b[5] | b[6] | b[7] | b[8] | b[9] |
                    b[10] | b[11] | b[12] | b[13] | b[14]);
                if (w != 0 or b[15] != 0x01)
                    return IPV6_SCOPE_GLOBAL;
                return IPV6_SCOPE_NODELOCAL;
            },
            else => {},
        }
    }
    return IPV6_SCOPE_GLOBAL;
}

pub export fn Curl_if2ip(
    af: c_int,
    remote_scope: c_uint,
    local_scope_id: c_uint,
    interf: [*:0]const u8,
    buf: [*]u8,
    buf_size: usize,
) callconv(.c) c_uint {
    if (builtin.os.tag == .windows) {
        return IF2IP_NOT_FOUND;
    } else {
        var head: ?*Ifaddrs = null;
        var res: c_uint = IF2IP_NOT_FOUND;

        if (ifaddrs_c.getifaddrs(&head) >= 0) {
            var iface_opt = head;
            while (iface_opt) |iface| : (iface_opt = iface.ifa_next) {
                if (iface.ifa_addr) |ifa_addr| {
                    const ifa_name = iface.ifa_name orelse continue;
                    if (@as(c_int, ifa_addr.sa.sa_family) == af) {
                        if (std.mem.orderZ(u8, ifa_name, interf) == .eq) {
                            var addr: *const anyopaque = undefined;
                            var scope_buf: [12]u8 = undefined;
                            var scope_slice: []const u8 = "";
                            var ipstr: [64]u8 = undefined;

                            if (af == curlx_time_net.AF_INET6) {
                                const ifscope = Curl_ipv6_scope(ifa_addr);
                                if (ifscope != remote_scope) {
                                    if (res == IF2IP_NOT_FOUND)
                                        res = IF2IP_AF_NOT_SUPPORTED;
                                    continue;
                                }

                                const sa6 = &ifa_addr.in6;
                                addr = &sa6.sin6_addr;
                                const scopeid: c_uint = sa6.sin6_scope_id;
                                if (local_scope_id != 0 and scopeid != local_scope_id) {
                                    if (res == IF2IP_NOT_FOUND)
                                        res = IF2IP_AF_NOT_SUPPORTED;
                                    continue;
                                }
                                if (scopeid != 0) {
                                    scope_slice = std.fmt.bufPrint(&scope_buf, "%{d}", .{scopeid}) catch "";
                                }
                            } else {
                                const sa4 = &ifa_addr.in4;
                                addr = &sa4.sin_addr;
                            }

                            res = IF2IP_FOUND;
                            const result = curlx_time_net.curlx_inet_ntop(af, addr, &ipstr, ipstr.len);
                            const ip_slice: []const u8 = if (result != CURLE_OK)
                                ""
                            else
                                std.mem.sliceTo(&ipstr, 0);

                            if (buf_size > 0) {
                                var pos: usize = 0;
                                const max_write = buf_size - 1;
                                const n1 = @min(ip_slice.len, max_write);
                                @memcpy(buf[0..n1], ip_slice[0..n1]);
                                pos += n1;
                                const n2 = @min(scope_slice.len, max_write - pos);
                                @memcpy(buf[pos .. pos + n2], scope_slice[0..n2]);
                                pos += n2;
                                buf[pos] = 0;
                            }
                            break;
                        }
                    } else if (res == IF2IP_NOT_FOUND and std.mem.orderZ(u8, ifa_name, interf) == .eq) {
                        res = IF2IP_AF_NOT_SUPPORTED;
                    }
                }
            }
            ifaddrs_c.freeifaddrs(head);
        }
        return res;
    }
}

// ============================================================================
// Unit Tests
// ============================================================================

test "Curl_wakeup_init, signal, consume, destroy and Curl_socket_check / Curl_poll" {
    var socks: [2]curl_socket_t = .{ CURL_SOCKET_BAD, CURL_SOCKET_BAD };
    try std.testing.expectEqual(@as(c_int, 0), Curl_wakeup_init(&socks, true));
    defer Curl_wakeup_destroy(&socks);

    try std.testing.expect(socks[0] != CURL_SOCKET_BAD);
    try std.testing.expect(socks[1] != CURL_SOCKET_BAD);

    // Initially not readable
    try std.testing.expectEqual(@as(c_int, 0), Curl_socket_check(socks[0], CURL_SOCKET_BAD, CURL_SOCKET_BAD, 0));

    // Signal wakeup
    try std.testing.expectEqual(@as(c_int, 0), Curl_wakeup_signal(&socks));

    // Now readable via Curl_socket_check and Curl_poll
    const check_rc = Curl_socket_check(socks[0], CURL_SOCKET_BAD, CURL_SOCKET_BAD, 100);
    try std.testing.expect((check_rc & CURL_CSELECT_IN) != 0);

    var pfd: [1]Pollfd = .{.{
        .fd = socks[0],
        .events = POLLIN,
        .revents = 0,
    }};
    try std.testing.expectEqual(@as(c_int, 1), Curl_poll(&pfd, 1, 100));
    try std.testing.expect((pfd[0].revents & POLLIN) != 0);

    // Consume wakeup
    try std.testing.expectEqual(CURLE_OK, Curl_wakeup_consume(&socks, true));

    // No longer readable
    try std.testing.expectEqual(@as(c_int, 0), Curl_socket_check(socks[0], CURL_SOCKET_BAD, CURL_SOCKET_BAD, 0));
}

test "EasyPollset and CurlPollfds operations" {
    var ps: EasyPollset = undefined;
    Curl_pollset_init(&ps);
    defer Curl_pollset_cleanup(&ps);

    const s1: curl_socket_t = 10;
    const s2: curl_socket_t = 20;
    const s3: curl_socket_t = 30;

    try std.testing.expectEqual(CURLE_OK, Curl_pollset_set(null, &ps, s1, true, false));
    try std.testing.expect(Curl_pollset_want_recv(null, &ps, s1));
    try std.testing.expect(!Curl_pollset_want_send(null, &ps, s1));

    try std.testing.expectEqual(CURLE_OK, Curl_pollset_set(null, &ps, s2, false, true));
    try std.testing.expectEqual(CURLE_OK, Curl_pollset_set(null, &ps, s3, true, true));
    try std.testing.expectEqual(@as(c_uint, 3), ps.n);

    var want_r = false;
    var want_w = false;
    Curl_pollset_check(null, &ps, s3, &want_r, &want_w);
    try std.testing.expect(want_r and want_w);

    var static_pfds: [2]Pollfd = undefined;
    var cpfds: CurlPollfds = undefined;
    Curl_pollfds_init(&cpfds, &static_pfds, 2);
    defer Curl_pollfds_cleanup(&cpfds);

    try std.testing.expectEqual(CURLE_OK, Curl_pollfds_add_ps(&cpfds, &ps));
    try std.testing.expectEqual(@as(c_uint, 3), cpfds.n);
    try std.testing.expectEqual(@as(c_uint, 1), cpfds.allocated_pfds);

    Curl_pollset_remove(&ps, s2);
    try std.testing.expectEqual(@as(c_uint, 2), ps.n);
}

test "Curl_rlimit token bucket lifecycle" {
    var r: CurlRlimit = undefined;
    var now: Curltime = .{ .tv_sec = 100, .tv_usec = 0 };

    Curl_rlimit_init(&r, 1000, 1500, &now);
    try std.testing.expect(Curl_rlimit_active(&r));
    try std.testing.expect(!Curl_rlimit_is_blocked(&r));
    try std.testing.expectEqual(@as(i64, 1000), Curl_rlimit_avail(&r, &now));

    Curl_rlimit_drain(&r, 1000, &now);
    try std.testing.expectEqual(@as(i64, 0), Curl_rlimit_avail(&r, &now));
    try std.testing.expectEqual(@as(timediff_t, 1000), Curl_rlimit_wait_ms(&r, &now));

    // Advance 1 second -> 1000 tokens restored
    now.tv_sec = 101;
    try std.testing.expectEqual(@as(i64, 1000), Curl_rlimit_avail(&r, &now));

    // Advance another 1 second without draining -> capped at burst 1500
    now.tv_sec = 102;
    try std.testing.expectEqual(@as(i64, 1500), Curl_rlimit_avail(&r, &now));

    // Block and unblock
    Curl_rlimit_block(&r, true, &now);
    try std.testing.expect(Curl_rlimit_is_blocked(&r));
    try std.testing.expectEqual(@as(i64, 0), Curl_rlimit_avail(&r, &now));

    Curl_rlimit_block(&r, false, &now);
    try std.testing.expect(!Curl_rlimit_is_blocked(&r));
    try std.testing.expectEqual(@as(i64, 1000), Curl_rlimit_avail(&r, &now));
}

test "Curl_ipv6_scope classification" {
    var sa6: SockaddrIn6 = std.mem.zeroes(SockaddrIn6);
    sa6.sin6_family = @intCast(curlx_time_net.AF_INET6);

    // Loopback ::1 -> NODELOCAL
    sa6.sin6_addr[15] = 1;
    try std.testing.expectEqual(IPV6_SCOPE_NODELOCAL, Curl_ipv6_scope(&sa6));

    // Link-local fe80::1 -> LINKLOCAL
    sa6.sin6_addr[0] = 0xfe;
    sa6.sin6_addr[1] = 0x80;
    try std.testing.expectEqual(IPV6_SCOPE_LINKLOCAL, Curl_ipv6_scope(&sa6));

    // Unique-local fd00::1 -> UNIQUELOCAL
    sa6.sin6_addr[0] = 0xfd;
    sa6.sin6_addr[1] = 0x00;
    try std.testing.expectEqual(IPV6_SCOPE_UNIQUELOCAL, Curl_ipv6_scope(&sa6));
}
