const std = @import("std");
const builtin = @import("builtin");
const mem = @import("mem.zig");
const containers = @import("containers.zig");
const io_buffers = @import("io_buffers.zig");
const primitives = @import("primitives.zig");
const curlx_parse_mod = @import("curlx_parse.zig");
const curlx_time_net = @import("curlx_time_net.zig");
const headers_sock = @import("headers_sock.zig");
const vdns_cfilters = @import("vdns_cfilters.zig");

const curlx_parse = struct {
    pub const STRE_OVERFLOW = curlx_parse_mod.STRE_OVERFLOW;
    pub extern fn curlx_str_number(linep: *?[*:0]const u8, nump: *i64, max: i64) callconv(.c) c_int;
    pub extern fn curlx_str_single(linep: *?[*:0]const u8, byte: u8) callconv(.c) c_int;
};

const is_windows = builtin.os.tag == .windows;

pub const CURLcode = c_uint;
pub const CURLproxycode = c_uint;
pub const curl_socket_t = curlx_time_net.curl_socket_t;
pub const timediff_t = curlx_time_net.timediff_t;
pub const curl_socklen_t = c_int;
pub const Curl_easy = vdns_cfilters.Curl_easy;
pub const connectdata = vdns_cfilters.connectdata;
pub const easy_pollset = vdns_cfilters.easy_pollset;
pub const Curl_cfilter = vdns_cfilters.Curl_cfilter;
pub const Curl_cftype = vdns_cfilters.Curl_cftype;
pub const Curl_peer = vdns_cfilters.Curl_peer;
pub const Curl_addrinfo = vdns_cfilters.Curl_addrinfo;
pub const ip_quadruple = vdns_cfilters.ip_quadruple;

pub const CurlProtocol = extern struct {
    setup_connection: ?*const fn (data: *Curl_easy, conn: *connectdata) callconv(.c) CURLcode,
    do_it: ?*const fn (data: *Curl_easy, done: *bool) callconv(.c) CURLcode,
    done: ?*const fn (data: *Curl_easy, status: CURLcode, premature: bool) callconv(.c) CURLcode,
    do_more: ?*const fn (data: *Curl_easy, domore_out: *c_int) callconv(.c) CURLcode,
    connect_it: ?*const fn (data: *Curl_easy, done: *bool) callconv(.c) CURLcode,
    connecting: ?*const fn (data: *Curl_easy, done: *bool) callconv(.c) CURLcode,
    doing: ?*const fn (data: *Curl_easy, done: *bool) callconv(.c) CURLcode,
    proto_pollset: ?*const fn (data: *Curl_easy, ps: *easy_pollset) callconv(.c) CURLcode,
    doing_pollset: ?*const fn (data: *Curl_easy, ps: *easy_pollset) callconv(.c) CURLcode,
    domore_pollset: ?*const fn (data: *Curl_easy, ps: *easy_pollset) callconv(.c) CURLcode,
    perform_pollset: ?*const fn (data: *Curl_easy, ps: *easy_pollset) callconv(.c) CURLcode,
    disconnect: ?*const fn (data: *Curl_easy, conn: *connectdata, dead_connection: bool) callconv(.c) CURLcode,
    write_resp: ?*const fn (data: *Curl_easy, buf: [*]const u8, blen: usize, is_eos: bool) callconv(.c) CURLcode,
    write_resp_hd: ?*const fn (data: *Curl_easy, hd: [*]const u8, hdlen: usize, is_eos: bool) callconv(.c) CURLcode,
    connection_is_dead: ?*const fn (data: *Curl_easy, conn: *connectdata) callconv(.c) bool,
    attach: ?*const fn (data: *Curl_easy, conn: *connectdata) callconv(.c) void,
    follow: ?*const fn (data: *Curl_easy, newurl: [*:0]const u8, ftype: c_uint) callconv(.c) CURLcode,
};

// CURLcode constants
pub const CURLE_OK: CURLcode = 0;
pub const CURLE_FAILED_INIT: CURLcode = 2;
pub const CURLE_COULDNT_RESOLVE_PROXY: CURLcode = 5;
pub const CURLE_COULDNT_RESOLVE_HOST: CURLcode = 6;
pub const CURLE_COULDNT_CONNECT: CURLcode = 7;
pub const CURLE_WRITE_ERROR: CURLcode = 23;
pub const CURLE_READ_ERROR: CURLcode = 26;
pub const CURLE_OUT_OF_MEMORY: CURLcode = 27;
pub const CURLE_OPERATION_TIMEDOUT: CURLcode = 28;
pub const CURLE_ABORTED_BY_CALLBACK: CURLcode = 42;
pub const CURLE_BAD_FUNCTION_ARGUMENT: CURLcode = 43;
pub const CURLE_UNKNOWN_OPTION: CURLcode = 48;
pub const CURLE_SETOPT_OPTION_SYNTAX: CURLcode = 49;
pub const CURLE_SEND_ERROR: CURLcode = 55;
pub const CURLE_RECV_ERROR: CURLcode = 56;
pub const CURLE_TFTP_NOTFOUND: CURLcode = 68;
pub const CURLE_TFTP_PERM: CURLcode = 69;
pub const CURLE_REMOTE_DISK_FULL: CURLcode = 70;
pub const CURLE_TFTP_ILLEGAL: CURLcode = 71;
pub const CURLE_TFTP_UNKNOWNID: CURLcode = 72;
pub const CURLE_REMOTE_FILE_EXISTS: CURLcode = 73;
pub const CURLE_TFTP_NOSUCHUSER: CURLcode = 74;
pub const CURLE_AGAIN: CURLcode = 81;
pub const CURLE_PROXY: CURLcode = 97;
pub const CURLE_TOO_LARGE: CURLcode = 100;

// CURLproxycode constants
pub const CURLPX_OK: CURLproxycode = 0;
pub const CURLPX_BAD_ADDRESS_TYPE: CURLproxycode = 1;
pub const CURLPX_BAD_VERSION: CURLproxycode = 2;
pub const CURLPX_CLOSED: CURLproxycode = 3;
pub const CURLPX_GSSAPI: CURLproxycode = 4;
pub const CURLPX_GSSAPI_PERMSG: CURLproxycode = 5;
pub const CURLPX_GSSAPI_PROTECTION: CURLproxycode = 6;
pub const CURLPX_IDENTD: CURLproxycode = 7;
pub const CURLPX_IDENTD_DIFFER: CURLproxycode = 8;
pub const CURLPX_LONG_HOSTNAME: CURLproxycode = 9;
pub const CURLPX_LONG_PASSWD: CURLproxycode = 10;
pub const CURLPX_LONG_USER: CURLproxycode = 11;
pub const CURLPX_NO_AUTH: CURLproxycode = 12;
pub const CURLPX_RECV_ADDRESS: CURLproxycode = 13;
pub const CURLPX_RECV_AUTH: CURLproxycode = 14;
pub const CURLPX_RECV_CONNECT: CURLproxycode = 15;
pub const CURLPX_RECV_REQACK: CURLproxycode = 16;
pub const CURLPX_REPLY_ADDRESS_TYPE_NOT_SUPPORTED: CURLproxycode = 17;
pub const CURLPX_REPLY_COMMAND_NOT_SUPPORTED: CURLproxycode = 18;
pub const CURLPX_REPLY_CONNECTION_REFUSED: CURLproxycode = 19;
pub const CURLPX_REPLY_GENERAL_SERVER_FAILURE: CURLproxycode = 20;
pub const CURLPX_REPLY_HOST_UNREACHABLE: CURLproxycode = 21;
pub const CURLPX_REPLY_NETWORK_UNREACHABLE: CURLproxycode = 22;
pub const CURLPX_REPLY_NOT_ALLOWED: CURLproxycode = 23;
pub const CURLPX_REPLY_TTL_EXPIRED: CURLproxycode = 24;
pub const CURLPX_REPLY_UNASSIGNED: CURLproxycode = 25;
pub const CURLPX_REQUEST_FAILED: CURLproxycode = 26;
pub const CURLPX_RESOLVE_HOST: CURLproxycode = 27;
pub const CURLPX_SEND_AUTH: CURLproxycode = 28;
pub const CURLPX_SEND_CONNECT: CURLproxycode = 29;
pub const CURLPX_SEND_REQUEST: CURLproxycode = 30;
pub const CURLPX_UNKNOWN_FAIL: CURLproxycode = 31;
pub const CURLPX_UNKNOWN_MODE: CURLproxycode = 32;
pub const CURLPX_USER_REJECTED: CURLproxycode = 33;

pub const FIRSTSOCKET: i8 = 0;
pub const SECONDARYSOCKET: i8 = 1;
pub const TRNSPRT_TCP: u8 = 3;
pub const TRNSPRT_UDP: u8 = 4;

pub const AF_INET: c_int = curlx_time_net.AF_INET;
pub const AF_INET6: c_int = curlx_time_net.AF_INET6;

pub const CLIENTWRITE_BODY: c_int = 1 << 0;
pub const CONNCTRL_CONN_CLOSE: c_int = 1;
pub const REJECT_ZERO: c_uint = 4;
pub const STRERROR_LEN: usize = 256;

// ============================================================================
// External C Helpers & Accessors
// ============================================================================

extern fn Curl_infof(data: ?*Curl_easy, fmt: [*:0]const u8, ...) callconv(.c) void;
extern fn Curl_failf(data: ?*Curl_easy, fmt: [*:0]const u8, ...) callconv(.c) void;
extern fn Curl_trc_cf_infof(data: ?*Curl_easy, cf: *const Curl_cfilter, fmt: [*:0]const u8, ...) callconv(.c) void;
extern fn curl_msnprintf(buffer: [*]u8, maxlength: usize, format: [*:0]const u8, ...) callconv(.c) c_int;
extern fn curl_easy_strerror(err: CURLcode) callconv(.c) [*:0]const u8;

extern fn Curl_easy_get_conn(data: *Curl_easy) callconv(.c) ?*connectdata;
extern fn Curl_conn_get_sock(conn: *const connectdata, sockindex: c_int) callconv(.c) curl_socket_t;
extern fn Curl_easy_get_verbose(data: *const Curl_easy) callconv(.c) bool;

extern fn Curl_tftp_is_upload(data: *const Curl_easy) callconv(.c) bool;
extern fn Curl_tftp_prefer_ascii(data: *const Curl_easy) callconv(.c) bool;
extern fn Curl_tftp_set_prefer_ascii(data: *Curl_easy, val: bool) callconv(.c) void;
extern fn Curl_tftp_infilesize(data: *const Curl_easy) callconv(.c) i64;
extern fn Curl_tftp_up_path(data: *Curl_easy) callconv(.c) ?[*:0]u8;
extern fn Curl_tftp_no_options(data: *const Curl_easy) callconv(.c) bool;
extern fn Curl_tftp_blksize(data: *const Curl_easy) callconv(.c) c_uint;
extern fn Curl_tftp_add_writebytecount(data: *Curl_easy, nbytes: usize) callconv(.c) i64;
extern fn Curl_conn_is_bound(conn: *const connectdata) callconv(.c) bool;
extern fn Curl_conn_set_bound(conn: *connectdata, val: bool) callconv(.c) void;
extern fn Curl_conn_set_transport_wanted(conn: *connectdata, transport: u8) callconv(.c) void;

extern fn Curl_socks_get_socks5auth(data: *const Curl_easy) callconv(.c) u8;
extern fn Curl_socks_is_auth_only(data: *const Curl_easy) callconv(.c) bool;
extern fn Curl_socks_get_ipver(data: *const Curl_easy) callconv(.c) u8;
extern fn Curl_socks_set_pxcode(data: *Curl_easy, pxcode: u8) callconv(.c) void;
extern fn Curl_conn_set_socks5_authenticated(conn: *connectdata, val: bool) callconv(.c) void;
extern fn Curl_socks5_has_gssapi() callconv(.c) bool;
extern fn Curl_socks5_gssapi_negotiate(cf: *Curl_cfilter, data: ?*Curl_easy, creds: ?*Curl_creds) callconv(.c) CURLcode;
extern fn Curl_conn_socks5_gssapi_enctype(conn: *const connectdata) callconv(.c) bool;

extern fn Curl_telnet_has_creds(data: *const Curl_easy) callconv(.c) bool;
extern fn Curl_telnet_creds_user(data: *const Curl_easy) callconv(.c) [*:0]const u8;
extern fn Curl_telnet_get_options(data: *const Curl_easy) callconv(.c) ?*containers.curl_slist;
extern fn Curl_telnet_is_fread_set(data: *const Curl_easy) callconv(.c) bool;
extern fn Curl_telnet_invoke_fread(data: *Curl_easy, buf: [*]u8, size: usize) callconv(.c) usize;
extern fn Curl_telnet_get_in_fd(data: *const Curl_easy) callconv(.c) c_int;
extern fn curl_slist_append(list: ?*containers.curl_slist, data: ?[*:0]const u8) callconv(.c) ?*containers.curl_slist;
extern fn curl_slist_free_all(list: ?*containers.curl_slist) callconv(.c) void;

extern fn Curl_timeleft_ms(data: ?*Curl_easy) callconv(.c) timediff_t;
extern fn Curl_pgrs_now(data: *Curl_easy) callconv(.c) ?*const anyopaque;
extern fn Curl_pgrsDone(data: *Curl_easy, pnow: ?*const anyopaque) callconv(.c) c_int;
extern fn Curl_pgrsSetDownloadSize(data: *Curl_easy, size: i64) callconv(.c) void;
extern fn Curl_pgrsSetUploadSize(data: *Curl_easy, size: i64) callconv(.c) void;
extern fn Curl_pgrsSetUploadCounter(data: *Curl_easy, size: i64) callconv(.c) void;
extern fn Curl_pgrs_upload_inc(data: *Curl_easy, delta: usize) callconv(.c) void;
extern fn Curl_pgrs_download_inc(data: *Curl_easy, delta: usize) callconv(.c) void;
extern fn Curl_pgrsUpdate(data: *Curl_easy) callconv(.c) CURLcode;
extern fn Curl_pgrsCheck(data: *Curl_easy) callconv(.c) CURLcode;

extern fn Curl_client_write(data: *Curl_easy, flags: c_int, ptr: [*]const u8, len: usize) callconv(.c) CURLcode;
extern fn Curl_client_read(data: *Curl_easy, buf: [*]u8, blen: usize, nread: *usize, eos: *bool) callconv(.c) CURLcode;
extern fn Curl_xfer_setup_nop(data: *Curl_easy) callconv(.c) void;
extern fn Curl_xfer_send(data: *Curl_easy, buf: *const anyopaque, blen: usize, eos: bool, pnwritten: *usize) callconv(.c) CURLcode;
extern fn Curl_xfer_recv(data: *Curl_easy, buf: [*]u8, blen: usize, pnrcvd: *usize) callconv(.c) CURLcode;

extern fn Curl_conncontrol(conn: *connectdata, ctrl: c_int) callconv(.c) void;
extern fn Curl_urldecode(string: [*:0]const u8, length: usize, ostring: *?[*:0]u8, olen: ?*usize, ctrl: c_uint) callconv(.c) CURLcode;

const HashDtor = *const fn (key: ?*const anyopaque, klen: usize, entry: ?*anyopaque) callconv(.c) void;
extern fn Curl_conn_meta_set(conn: *connectdata, key: [*:0]const u8, entry: ?*anyopaque, dtor: HashDtor) callconv(.c) CURLcode;
extern fn Curl_conn_meta_get(conn: *connectdata, key: [*:0]const u8) callconv(.c) ?*anyopaque;
extern fn Curl_meta_set(data: *Curl_easy, key: [*:0]const u8, entry: ?*anyopaque, dtor: HashDtor) callconv(.c) CURLcode;
extern fn Curl_meta_get(data: *Curl_easy, key: [*:0]const u8) callconv(.c) ?*anyopaque;
extern fn Curl_meta_remove(data: *Curl_easy, key: [*:0]const u8) callconv(.c) void;

inline fn infof(data: ?*Curl_easy, fmt: [*:0]const u8, args: anytype) void {
    if (data) |d| {
        if (Curl_easy_get_verbose(d)) {
            @call(.auto, Curl_infof, .{ d, fmt } ++ args);
        }
    }
}

inline fn failf(data: ?*Curl_easy, fmt: [*:0]const u8, args: anytype) void {
    if (data != null) {
        @call(.auto, Curl_failf, .{ data, fmt } ++ args);
    }
}

inline fn trcCf(data: ?*Curl_easy, cf: *const Curl_cfilter, fmt: [*:0]const u8, args: anytype) void {
    if (data != null and cf.cft.log_level >= vdns_cfilters.CURL_LOG_LVL_INFO) {
        @call(.auto, Curl_trc_cf_infof, .{ data, cf, fmt } ++ args);
    }
}

// ============================================================================
// Platform Socket / Time Wrappers
// ============================================================================

const win_ws2 = struct {
    extern "ws2_32" fn sendto(
        s: curl_socket_t,
        buf: [*]const u8,
        len: c_int,
        flags: c_int,
        to: ?*const anyopaque,
        tolen: c_int,
    ) callconv(.winapi) c_int;
    extern "ws2_32" fn recvfrom(
        s: curl_socket_t,
        buf: [*]u8,
        len: c_int,
        flags: c_int,
        from: ?*anyopaque,
        fromlen: ?*c_int,
    ) callconv(.winapi) c_int;
    extern "ws2_32" fn bind(
        s: curl_socket_t,
        name: *const anyopaque,
        namelen: c_int,
    ) callconv(.winapi) c_int;
    extern "ws2_32" fn WSACreateEvent() callconv(.winapi) ?*anyopaque;
    extern "ws2_32" fn WSAEventSelect(
        s: curl_socket_t,
        hEventObject: ?*anyopaque,
        lNetworkEvents: c_long,
    ) callconv(.winapi) c_int;
    extern "ws2_32" fn WSAEnumNetworkEvents(
        s: curl_socket_t,
        hEventObject: ?*anyopaque,
        lpNetworkEvents: *WSANETWORKEVENTS,
    ) callconv(.winapi) c_int;
    extern "ws2_32" fn WSACloseEvent(hEvent: ?*anyopaque) callconv(.winapi) c_int;
    extern "ws2_32" fn WSAGetLastError() callconv(.winapi) c_int;
};

const win_kernel32 = struct {
    extern "kernel32" fn GetStdHandle(nStdHandle: u32) callconv(.winapi) ?*anyopaque;
    extern "kernel32" fn GetFileType(hFile: ?*anyopaque) callconv(.winapi) u32;
    extern "kernel32" fn WaitForMultipleObjects(
        nCount: u32,
        lpHandles: [*]const ?*anyopaque,
        bWaitAll: c_int,
        dwMilliseconds: u32,
    ) callconv(.winapi) u32;
    extern "kernel32" fn PeekNamedPipe(
        hNamedPipe: ?*anyopaque,
        lpBuffer: ?*anyopaque,
        nBufferSize: u32,
        lpBytesRead: ?*u32,
        lpTotalBytesAvail: ?*u32,
        lpBytesLeftThisMessage: ?*u32,
    ) callconv(.winapi) c_int;
    extern "kernel32" fn ReadFile(
        hFile: ?*anyopaque,
        lpBuffer: [*]u8,
        nNumberOfBytesToRead: u32,
        lpNumberOfBytesRead: ?*u32,
        lpOverlapped: ?*anyopaque,
    ) callconv(.winapi) c_int;
    extern "c" fn _time64(timer: ?*i64) callconv(.c) i64;
};

const posix_c = struct {
    extern "c" fn sendto(
        sockfd: c_int,
        buf: *const anyopaque,
        len: usize,
        flags: c_int,
        dest_addr: ?*const anyopaque,
        addrlen: curl_socklen_t,
    ) callconv(.c) isize;
    extern "c" fn recvfrom(
        sockfd: c_int,
        buf: *anyopaque,
        len: usize,
        flags: c_int,
        src_addr: ?*anyopaque,
        addrlen: ?*curl_socklen_t,
    ) callconv(.c) isize;
    extern "c" fn bind(
        sockfd: c_int,
        addr: *const anyopaque,
        addrlen: curl_socklen_t,
    ) callconv(.c) c_int;
    extern "c" fn read(fd: c_int, buf: *anyopaque, count: usize) callconv(.c) isize;
    extern "c" fn time(tloc: ?*isize) callconv(.c) isize;
};

fn currentTime() i64 {
    if (is_windows) {
        return win_kernel32._time64(null);
    } else {
        return @intCast(posix_c.time(null));
    }
}

inline fn lastSocketError() c_int {
    if (is_windows) {
        return win_ws2.WSAGetLastError();
    } else {
        return std.c._errno().*;
    }
}

fn sysSendto(
    s: curl_socket_t,
    buf: [*]const u8,
    len: usize,
    to: ?*const anyopaque,
    tolen: curl_socklen_t,
) isize {
    if (is_windows) {
        return @intCast(win_ws2.sendto(s, buf, @intCast(len), 0, to, tolen));
    } else {
        return posix_c.sendto(s, buf, len, 0, to, tolen);
    }
}

fn sysRecvfrom(
    s: curl_socket_t,
    buf: [*]u8,
    len: usize,
    from: ?*anyopaque,
    fromlen: *curl_socklen_t,
) isize {
    if (is_windows) {
        return @intCast(win_ws2.recvfrom(s, buf, @intCast(len), 0, from, fromlen));
    } else {
        return posix_c.recvfrom(s, buf, len, 0, from, fromlen);
    }
}

fn sysBind(s: curl_socket_t, addr: *const anyopaque, addrlen: curl_socklen_t) c_int {
    if (is_windows) {
        return win_ws2.bind(s, addr, addrlen);
    } else {
        return posix_c.bind(s, addr, addrlen);
    }
}

// ============================================================================
// 1. lib/tftp.c — TFTP Protocol Handler
// ============================================================================

const TFTP_BLKSIZE_DEFAULT: u32 = 512;
const TFTP_BLKSIZE_MIN: i64 = 8;
const TFTP_BLKSIZE_MAX: i64 = 65464;
const TFTP_OPTION_BLKSIZE = "blksize";
const TFTP_OPTION_TSIZE = "tsize";
const TFTP_OPTION_INTERVAL = "timeout";
const CURL_META_TFTP_CONN = "meta:proto:tftp:conn";

const TftpMode = enum(c_int) {
    TFTP_MODE_NETASCII = 0,
    TFTP_MODE_OCTET = 1,
};

const TftpState = enum(c_int) {
    TFTP_STATE_START = 0,
    TFTP_STATE_RX = 1,
    TFTP_STATE_TX = 2,
    TFTP_STATE_FIN = 3,
    _,
};

const TftpEvent = enum(c_int) {
    TFTP_EVENT_NONE = -1,
    TFTP_EVENT_INIT = 0,
    TFTP_EVENT_RRQ = 1,
    TFTP_EVENT_WRQ = 2,
    TFTP_EVENT_DATA = 3,
    TFTP_EVENT_ACK = 4,
    TFTP_EVENT_ERROR = 5,
    TFTP_EVENT_OACK = 6,
    TFTP_EVENT_TIMEOUT = 7,
    _,
};

const TftpError = enum(c_int) {
    TFTP_ERR_NONE = -100,
    TFTP_ERR_TIMEOUT = -99,
    TFTP_ERR_NORESPONSE = -98,
    TFTP_ERR_UNDEF = 0,
    TFTP_ERR_NOTFOUND = 1,
    TFTP_ERR_PERM = 2,
    TFTP_ERR_DISKFULL = 3,
    TFTP_ERR_ILLEGAL = 4,
    TFTP_ERR_UNKNOWNID = 5,
    TFTP_ERR_EXISTS = 6,
    TFTP_ERR_NOSUCHUSER = 7,
    _,
};

const TftpPacket = extern struct {
    data: ?[*]u8 = null,
};

const CurlSockaddrStorage = extern struct {
    buffer: [256]u8 align(8) = @splat(0),

    fn setFamily(self: *CurlSockaddrStorage, family: c_int) void {
        if (builtin.os.tag.isDarwin()) {
            self.buffer[1] = @intCast(family);
        } else {
            const fam_u16: u16 = @intCast(family);
            const ptr: *u16 = @ptrCast(@alignCast(&self.buffer[0]));
            ptr.* = fam_u16;
        }
    }
};

const CurlSockaddrEx = extern struct {
    family: c_int,
    socktype: c_int,
    protocol: c_int,
    addrlen: c_uint,
    addr: CurlSockaddrStorage,
};

extern fn Curl_conn_get_remote_addr(data: *Curl_easy, sockindex: i8) callconv(.c) ?*const CurlSockaddrEx;

const TftpConn = struct {
    local_addr: CurlSockaddrStorage,
    remote_addr: CurlSockaddrStorage,
    rpacket: TftpPacket,
    spacket: TftpPacket,
    state: TftpState,
    mode: TftpMode,
    err: TftpError,
    event: TftpEvent,
    data: *Curl_easy,
    sockfd: curl_socket_t,
    retries: c_int,
    retry_time: c_int,
    retry_max: c_int,
    rx_time: i64,
    remote_addrlen: curl_socklen_t,
    rbytes: c_int,
    sbytes: usize,
    blksize: u32,
    requested_blksize: u32,
    block: u16,
    remote_pinned: bool,
};

inline fn nextBlocknum(x: u16) u16 {
    return x +% 1;
}

fn setpacketevent(packet: *TftpPacket, num: u16) void {
    const d = packet.data.?;
    d[0] = @intCast((num >> 8) & 0xff);
    d[1] = @intCast(num & 0xff);
}

fn setpacketblock(packet: *TftpPacket, num: u16) void {
    const d = packet.data.?;
    d[2] = @intCast((num >> 8) & 0xff);
    d[3] = @intCast(num & 0xff);
}

fn getrpacketevent(packet: *const TftpPacket) u16 {
    const d = packet.data.?;
    return (@as(u16, d[0]) << 8) | @as(u16, d[1]);
}

fn getrpacketblock(packet: *const TftpPacket) u16 {
    const d = packet.data.?;
    return (@as(u16, d[2]) << 8) | @as(u16, d[3]);
}

fn tftp_strnlen(string: [*]const u8, maxlen: usize) usize {
    if (std.mem.indexOfScalar(u8, string[0..maxlen], 0)) |idx| {
        return idx;
    }
    return maxlen;
}

fn tftp_option_get(
    buf: [*]const u8,
    len: usize,
    option: *?[*:0]const u8,
    value: *?[*:0]const u8,
) ?[*]const u8 {
    const slice = buf[0..len];
    const key_nul = std.mem.indexOfScalar(u8, slice, 0) orelse return null;
    const after_key = key_nul + 1;
    if (after_key >= slice.len) return null;
    const val_rel = std.mem.indexOfScalar(u8, slice[after_key..], 0) orelse return null;
    const next_idx = after_key + val_rel + 1;
    option.* = @ptrCast(slice.ptr);
    value.* = @ptrCast(slice[after_key..].ptr);
    return slice.ptr + next_idx;
}

fn tftp_parse_option_ack(state: *TftpConn, ptr: [*]const u8, len: c_int) CURLcode {
    const data = state.data;
    const ulen = std.math.cast(usize, len) orelse {
        failf(data, "Malformed ACK packet, rejecting", .{});
        return CURLE_TFTP_ILLEGAL;
    };
    const opt_slice: []const u8 = ptr[0..ulen];
    var rem: []const u8 = opt_slice;

    state.blksize = TFTP_BLKSIZE_DEFAULT;

    while (rem.len > 0) {
        const key_nul = std.mem.indexOfScalar(u8, rem, 0) orelse {
            failf(data, "Malformed ACK packet, rejecting", .{});
            return CURLE_TFTP_ILLEGAL;
        };
        const key_slice = rem[0..key_nul];
        const opt_str: [*:0]const u8 = @ptrCast(rem.ptr);
        const after_key = key_nul + 1;
        if (after_key >= rem.len) {
            failf(data, "Malformed ACK packet, rejecting", .{});
            return CURLE_TFTP_ILLEGAL;
        }
        const val_rem = rem[after_key..];
        const val_nul = std.mem.indexOfScalar(u8, val_rem, 0) orelse {
            failf(data, "Malformed ACK packet, rejecting", .{});
            return CURLE_TFTP_ILLEGAL;
        };
        const val_str: [*:0]const u8 = @ptrCast(val_rem.ptr);
        rem = val_rem[val_nul + 1 ..];
        const olen = key_slice.len;

        infof(data, "got option=(%s) value=(%s)", .{ opt_str, val_str });

        if (olen == TFTP_OPTION_BLKSIZE.len and
            primitives.curl_strnequal(TFTP_OPTION_BLKSIZE, opt_str, TFTP_OPTION_BLKSIZE.len) != 0)
        {
            var val_p: ?[*:0]const u8 = val_str;
            var blksize: i64 = 0;
            if (curlx_parse.curlx_str_number(&val_p, &blksize, TFTP_BLKSIZE_MAX) != 0) {
                failf(data, "%s (%d)", .{ "blksize is larger than max supported", @as(c_int, TFTP_BLKSIZE_MAX) });
                return CURLE_TFTP_ILLEGAL;
            }
            if (blksize == 0) {
                failf(data, "invalid blocksize value in OACK packet", .{});
                return CURLE_TFTP_ILLEGAL;
            } else if (blksize < TFTP_BLKSIZE_MIN) {
                failf(data, "%s (%d)", .{ "blksize is smaller than min supported", @as(c_int, TFTP_BLKSIZE_MIN) });
                return CURLE_TFTP_ILLEGAL;
            } else if (blksize > @as(i64, state.requested_blksize)) {
                failf(data, "server requested blksize larger than allocated (%lld)", .{@as(c_longlong, blksize)});
                return CURLE_TFTP_ILLEGAL;
            }

            state.blksize = std.math.cast(u32, blksize) orelse return CURLE_TFTP_ILLEGAL;
            infof(data, "blksize parsed from OACK (%u) requested (%u)", .{ state.blksize, state.requested_blksize });
        } else if (olen == TFTP_OPTION_TSIZE.len and
            primitives.curl_strnequal(TFTP_OPTION_TSIZE, opt_str, TFTP_OPTION_TSIZE.len) != 0)
        {
            var val_p: ?[*:0]const u8 = val_str;
            var tsize: i64 = 0;
            if (!builtin.is_test and !Curl_tftp_is_upload(data) and
                curlx_parse.curlx_str_number(&val_p, &tsize, std.math.maxInt(i64)) == 0)
            {
                if (tsize == 0) {
                    failf(data, "invalid tsize -:%s:- value in OACK packet", .{val_str});
                    return CURLE_TFTP_ILLEGAL;
                }
                infof(data, "tsize parsed from OACK (%lld)", .{@as(c_longlong, tsize)});
                Curl_pgrsSetDownloadSize(data, tsize);
            }
        }
    }

    return CURLE_OK;
}

fn tftp_option_add(state: *TftpConn, csize: *usize, index: usize, option: [*:0]const u8) CURLcode {
    const oplen = std.mem.len(option);
    if (state.blksize <= index or (oplen + 1) > (state.blksize - index)) {
        return CURLE_TFTP_ILLEGAL;
    }
    const blen = state.blksize - index;
    const buf = state.spacket.data.? + index;
    primitives.curlx_strcopy(buf, blen, option, oplen);
    csize.* += oplen + 1;
    return CURLE_OK;
}

fn tftp_set_timeouts(state: *TftpConn) CURLcode {
    const timeout_ms = Curl_timeleft_ms(state.data);
    if (timeout_ms < 0) {
        failf(state.data, "Connection time-out", .{});
        return CURLE_OPERATION_TIMEDOUT;
    }

    const timeout: i64 = if (timeout_ms > 0 and timeout_ms < 3600000)
        @divTrunc(timeout_ms + 500, 1000)
    else
        15;

    state.retry_max = @intCast(@divTrunc(timeout, 5));
    if (state.retry_max < 3) state.retry_max = 3;
    if (state.retry_max > 50) state.retry_max = 50;

    state.retry_time = @intCast(@divTrunc(timeout, state.retry_max));
    if (state.retry_time < 1) state.retry_time = 1;

    infof(
        state.data,
        "set timeouts for state %d; Total %lld, retry %d maxtry %d",
        .{ @backingInt(state.state), @as(c_longlong, timeout_ms), state.retry_time, state.retry_max },
    );

    state.rx_time = currentTime();
    return CURLE_OK;
}

fn tftp_tx(state: *TftpConn, event: TftpEvent) CURLcode {
    const data = state.data;
    var result: CURLcode = CURLE_OK;
    var buffer: [STRERROR_LEN]u8 = undefined;

    if (!Curl_tftp_is_upload(data)) return CURLE_TFTP_ILLEGAL;

    switch (event) {
        .TFTP_EVENT_ACK, .TFTP_EVENT_OACK => {
            if (event == .TFTP_EVENT_ACK) {
                const rblock = getrpacketblock(&state.rpacket);
                if (rblock != state.block and !(state.block == 0 and rblock == 65535)) {
                    infof(data, "Received ACK for block %d, expecting %d", .{ @as(c_int, rblock), @as(c_int, state.block) });
                    state.retries += 1;
                    if (state.retries > state.retry_max) {
                        failf(data, "tftp_tx: giving up waiting for block %d ack", .{@as(c_int, state.block)});
                        result = CURLE_SEND_ERROR;
                    } else {
                        const sbytes = sysSendto(
                            state.sockfd,
                            state.spacket.data.?,
                            4 + state.sbytes,
                            &state.remote_addr,
                            state.remote_addrlen,
                        );
                        if (sbytes < 0) {
                            failf(data, "%s", .{curlx_time_net.curlx_strerror(lastSocketError(), &buffer, buffer.len)});
                            result = CURLE_SEND_ERROR;
                        }
                    }
                    return result;
                }
                state.rx_time = currentTime();
                state.block +%= 1;
            } else {
                state.block = 1;
            }

            state.retries = 0;
            setpacketevent(&state.spacket, @intCast(@backingInt(TftpEvent.TFTP_EVENT_DATA)));
            setpacketblock(&state.spacket, state.block);
            if (state.block > 1 and state.sbytes < state.blksize) {
                state.state = .TFTP_STATE_FIN;
                return CURLE_OK;
            }

            state.sbytes = 0;
            var bufptr: [*]u8 = state.spacket.data.? + 4;
            while (true) {
                var cb: usize = 0;
                var eos: bool = false;
                result = Curl_client_read(data, bufptr, state.blksize - state.sbytes, &cb, &eos);
                if (result != CURLE_OK) return result;
                state.sbytes += cb;
                bufptr += cb;
                if (!(state.sbytes < state.blksize and cb != 0)) break;
            }

            const sbytes = sysSendto(
                state.sockfd,
                state.spacket.data.?,
                4 + state.sbytes,
                &state.remote_addr,
                state.remote_addrlen,
            );
            if (sbytes < 0) {
                failf(data, "%s", .{curlx_time_net.curlx_strerror(lastSocketError(), &buffer, buffer.len)});
                return CURLE_SEND_ERROR;
            }
            _ = Curl_tftp_add_writebytecount(data, state.sbytes);
            Curl_pgrs_upload_inc(data, state.sbytes);
        },

        .TFTP_EVENT_TIMEOUT => {
            state.retries += 1;
            infof(
                data,
                "Timeout waiting for block %d ACK. Retries = %d",
                .{ @as(c_int, nextBlocknum(state.block)), state.retries },
            );
            if (state.retries > state.retry_max) {
                state.err = .TFTP_ERR_TIMEOUT;
                state.state = .TFTP_STATE_FIN;
            } else {
                const sbytes = sysSendto(
                    state.sockfd,
                    state.spacket.data.?,
                    4 + state.sbytes,
                    &state.remote_addr,
                    state.remote_addrlen,
                );
                if (sbytes < 0) {
                    failf(data, "%s", .{curlx_time_net.curlx_strerror(lastSocketError(), &buffer, buffer.len)});
                    return CURLE_SEND_ERROR;
                }
                const wb = Curl_tftp_add_writebytecount(data, 0);
                Curl_pgrsSetUploadCounter(data, wb);
            }
        },

        .TFTP_EVENT_ERROR => {
            state.state = .TFTP_STATE_FIN;
            setpacketevent(&state.spacket, @intCast(@backingInt(TftpEvent.TFTP_EVENT_ERROR)));
            setpacketblock(&state.spacket, state.block);
            _ = sysSendto(
                state.sockfd,
                state.spacket.data.?,
                4,
                &state.remote_addr,
                state.remote_addrlen,
            );
            state.state = .TFTP_STATE_FIN;
        },

        else => {
            failf(data, "tftp_tx: internal error, event: %d", .{@backingInt(event)});
        },
    }

    return result;
}

fn tftp_connect_for_tx(state: *TftpConn, event: TftpEvent) CURLcode {
    infof(state.data, "%s", .{"Connected for transmit"});
    state.state = .TFTP_STATE_TX;
    const result = tftp_set_timeouts(state);
    if (result != CURLE_OK) return result;
    return tftp_tx(state, event);
}

fn tftp_rx(state: *TftpConn, event: TftpEvent) CURLcode {
    const data = state.data;
    var buffer: [STRERROR_LEN]u8 = undefined;

    switch (event) {
        .TFTP_EVENT_DATA => {
            const rblock = getrpacketblock(&state.rpacket);
            if (nextBlocknum(state.block) == rblock) {
                state.retries = 0;
            } else if (state.block == rblock) {
                infof(data, "Received last DATA packet block %d again.", .{@as(c_int, rblock)});
            } else {
                infof(
                    data,
                    "Received unexpected DATA packet block %d, expecting block %d",
                    .{ @as(c_int, rblock), @as(c_int, nextBlocknum(state.block)) },
                );
                return CURLE_OK;
            }

            state.block = rblock;
            setpacketevent(&state.spacket, @intCast(@backingInt(TftpEvent.TFTP_EVENT_ACK)));
            setpacketblock(&state.spacket, state.block);
            const sbytes = sysSendto(
                state.sockfd,
                state.spacket.data.?,
                4,
                &state.remote_addr,
                state.remote_addrlen,
            );
            if (sbytes < 0) {
                failf(data, "%s", .{curlx_time_net.curlx_strerror(lastSocketError(), &buffer, buffer.len)});
                return CURLE_SEND_ERROR;
            }

            if (state.rbytes < @as(c_int, @intCast(state.blksize)) + 4) {
                state.state = .TFTP_STATE_FIN;
            } else {
                state.state = .TFTP_STATE_RX;
            }
            state.rx_time = currentTime();
        },

        .TFTP_EVENT_OACK => {
            state.block = 0;
            state.retries = 0;
            setpacketevent(&state.spacket, @intCast(@backingInt(TftpEvent.TFTP_EVENT_ACK)));
            setpacketblock(&state.spacket, state.block);
            const sbytes = sysSendto(
                state.sockfd,
                state.spacket.data.?,
                4,
                &state.remote_addr,
                state.remote_addrlen,
            );
            if (sbytes < 0) {
                failf(data, "%s", .{curlx_time_net.curlx_strerror(lastSocketError(), &buffer, buffer.len)});
                return CURLE_SEND_ERROR;
            }
            state.state = .TFTP_STATE_RX;
            state.rx_time = currentTime();
        },

        .TFTP_EVENT_TIMEOUT => {
            state.retries += 1;
            infof(
                data,
                "Timeout waiting for block %d ACK. Retries = %d",
                .{ @as(c_int, nextBlocknum(state.block)), state.retries },
            );
            if (state.retries > state.retry_max) {
                state.err = .TFTP_ERR_TIMEOUT;
                state.state = .TFTP_STATE_FIN;
            } else {
                const sbytes = sysSendto(
                    state.sockfd,
                    state.spacket.data.?,
                    4,
                    &state.remote_addr,
                    state.remote_addrlen,
                );
                if (sbytes < 0) {
                    failf(data, "%s", .{curlx_time_net.curlx_strerror(lastSocketError(), &buffer, buffer.len)});
                    return CURLE_SEND_ERROR;
                }
            }
        },

        .TFTP_EVENT_ERROR => {
            setpacketevent(&state.spacket, @intCast(@backingInt(TftpEvent.TFTP_EVENT_ERROR)));
            setpacketblock(&state.spacket, state.block);
            _ = sysSendto(
                state.sockfd,
                state.spacket.data.?,
                4,
                &state.remote_addr,
                state.remote_addrlen,
            );
            state.state = .TFTP_STATE_FIN;
        },

        else => {
            failf(data, "%s", .{"tftp_rx: internal error"});
            return CURLE_TFTP_ILLEGAL;
        },
    }

    return CURLE_OK;
}

fn tftp_connect_for_rx(state: *TftpConn, event: TftpEvent) CURLcode {
    infof(state.data, "%s", .{"Connected for receive"});
    state.state = .TFTP_STATE_RX;
    const result = tftp_set_timeouts(state);
    if (result != CURLE_OK) return result;
    return tftp_rx(state, event);
}

fn tftp_send_first(state: *TftpConn, event: TftpEvent) CURLcode {
    const data = state.data;
    const mode: [*:0]const u8 = if (Curl_tftp_prefer_ascii(data)) "netascii" else "octet";
    var result: CURLcode = CURLE_OK;

    switch (event) {
        .TFTP_EVENT_INIT, .TFTP_EVENT_TIMEOUT => {
            state.retries += 1;
            if (state.retries > state.retry_max) {
                state.err = .TFTP_ERR_NORESPONSE;
                state.state = .TFTP_STATE_FIN;
                return result;
            }

            const is_upload = Curl_tftp_is_upload(data);
            const infilesize = Curl_tftp_infilesize(data);
            if (is_upload) {
                setpacketevent(&state.spacket, @intCast(@backingInt(TftpEvent.TFTP_EVENT_WRQ)));
                if (infilesize != -1) {
                    Curl_pgrsSetUploadSize(data, infilesize);
                }
            } else {
                setpacketevent(&state.spacket, @intCast(@backingInt(TftpEvent.TFTP_EVENT_RRQ)));
            }

            const up_path = Curl_tftp_up_path(data) orelse {
                failf(data, "Missing filename", .{});
                return CURLE_TFTP_ILLEGAL;
            };
            if (up_path[0] == 0 or up_path[1] == 0) {
                failf(data, "Missing filename", .{});
                return CURLE_TFTP_ILLEGAL;
            }

            var filename: ?[*:0]u8 = null;
            result = Curl_urldecode(up_path + 1, 0, &filename, null, REJECT_ZERO);
            if (result != CURLE_OK) return result;
            const fn_ptr = filename.?;

            if (std.mem.len(fn_ptr) + std.mem.len(mode) + 4 > state.blksize) {
                failf(data, "TFTP filename too long", .{});
                mem.free(fn_ptr);
                return CURLE_TFTP_ILLEGAL;
            }

            const n_printed = curl_msnprintf(
                state.spacket.data.? + 2,
                state.blksize,
                "%s%c%s%c",
                fn_ptr,
                @as(c_int, 0),
                mode,
                @as(c_int, 0),
            );
            var sbytes: usize = 2 + @as(usize, @intCast(@max(0, n_printed)));
            mem.free(fn_ptr);

            if (!Curl_tftp_no_options(data)) {
                var buf: [64]u8 = undefined;
                const tsize_val: i64 = if (is_upload and infilesize != -1) infilesize else 0;
                _ = curl_msnprintf(&buf, buf.len, "%lld", @as(c_longlong, tsize_val));
                const buf_cstr: [*:0]const u8 = @ptrCast(&buf);

                result = tftp_option_add(state, &sbytes, sbytes, TFTP_OPTION_TSIZE);
                if (result == CURLE_OK) {
                    result = tftp_option_add(state, &sbytes, sbytes, buf_cstr);
                }

                _ = curl_msnprintf(&buf, buf.len, "%u", state.requested_blksize);
                if (result == CURLE_OK) {
                    result = tftp_option_add(state, &sbytes, sbytes, TFTP_OPTION_BLKSIZE);
                }
                if (result == CURLE_OK) {
                    result = tftp_option_add(state, &sbytes, sbytes, buf_cstr);
                }

                _ = curl_msnprintf(&buf, buf.len, "%d", state.retry_time);
                if (result == CURLE_OK) {
                    result = tftp_option_add(state, &sbytes, sbytes, TFTP_OPTION_INTERVAL);
                }
                if (result == CURLE_OK) {
                    result = tftp_option_add(state, &sbytes, sbytes, buf_cstr);
                }

                if (result != CURLE_OK) {
                    failf(data, "TFTP buffer too small for options", .{});
                    return CURLE_TFTP_ILLEGAL;
                }
            }

            const remote_addr = Curl_conn_get_remote_addr(data, FIRSTSOCKET) orelse return CURLE_FAILED_INIT;
            const senddata = sysSendto(
                state.sockfd,
                state.spacket.data.?,
                sbytes,
                &remote_addr.addr,
                @intCast(remote_addr.addrlen),
            );
            if (senddata != @as(isize, @intCast(sbytes))) {
                var buffer: [STRERROR_LEN]u8 = undefined;
                failf(data, "%s", .{curlx_time_net.curlx_strerror(lastSocketError(), &buffer, buffer.len)});
                return CURLE_SEND_ERROR;
            }
        },

        .TFTP_EVENT_OACK => {
            if (Curl_tftp_is_upload(data)) {
                result = tftp_connect_for_tx(state, event);
            } else {
                result = tftp_connect_for_rx(state, event);
            }
        },

        .TFTP_EVENT_ACK => {
            if (!Curl_tftp_is_upload(data)) return CURLE_TFTP_ILLEGAL;
            result = tftp_connect_for_tx(state, event);
        },

        .TFTP_EVENT_DATA => {
            if (Curl_tftp_is_upload(data)) return CURLE_TFTP_ILLEGAL;
            result = tftp_connect_for_rx(state, event);
        },

        .TFTP_EVENT_ERROR => {
            state.state = .TFTP_STATE_FIN;
        },

        else => {
            failf(state.data, "tftp_send_first: internal error", .{});
            return CURLE_TFTP_ILLEGAL;
        },
    }

    return result;
}

fn tftp_translate_code(err: TftpError) CURLcode {
    if (err == .TFTP_ERR_NONE) return CURLE_OK;
    return switch (err) {
        .TFTP_ERR_NOTFOUND => CURLE_TFTP_NOTFOUND,
        .TFTP_ERR_PERM => CURLE_TFTP_PERM,
        .TFTP_ERR_DISKFULL => CURLE_REMOTE_DISK_FULL,
        .TFTP_ERR_UNDEF, .TFTP_ERR_ILLEGAL => CURLE_TFTP_ILLEGAL,
        .TFTP_ERR_UNKNOWNID => CURLE_TFTP_UNKNOWNID,
        .TFTP_ERR_EXISTS => CURLE_REMOTE_FILE_EXISTS,
        .TFTP_ERR_NOSUCHUSER => CURLE_TFTP_NOSUCHUSER,
        .TFTP_ERR_TIMEOUT => CURLE_OPERATION_TIMEDOUT,
        .TFTP_ERR_NORESPONSE => CURLE_COULDNT_CONNECT,
        else => CURLE_ABORTED_BY_CALLBACK,
    };
}

fn tftp_state_machine(state: *TftpConn, event: TftpEvent) CURLcode {
    const data = state.data;
    return switch (state.state) {
        .TFTP_STATE_START => tftp_send_first(state, event),
        .TFTP_STATE_RX => tftp_rx(state, event),
        .TFTP_STATE_TX => tftp_tx(state, event),
        .TFTP_STATE_FIN => blk: {
            infof(data, "%s", .{"TFTP finished"});
            break :blk CURLE_OK;
        },
        else => blk: {
            failf(data, "%s", .{"Internal state machine error"});
            break :blk CURLE_TFTP_ILLEGAL;
        },
    };
}

fn tftp_conn_dtor(key: ?*const anyopaque, klen: usize, entry: ?*anyopaque) callconv(.c) void {
    _ = key;
    _ = klen;
    if (entry) |ptr| {
        const state: *TftpConn = @ptrCast(@alignCast(ptr));
        mem.free(state.rpacket.data);
        state.rpacket.data = null;
        mem.free(state.spacket.data);
        state.spacket.data = null;
        mem.freeSized(state, @sizeOf(TftpConn));
    }
}

fn tftp_connect(data: *Curl_easy, done: *bool) callconv(.c) CURLcode {
    const conn = Curl_easy_get_conn(data) orelse return CURLE_FAILED_INIT;

    const raw = mem.calloc(1, @sizeOf(TftpConn)) orelse return CURLE_OUT_OF_MEMORY;
    const state: *TftpConn = @ptrCast(@alignCast(raw));
    if (Curl_conn_meta_set(conn, CURL_META_TFTP_CONN, state, tftp_conn_dtor) != CURLE_OK) {
        return CURLE_OUT_OF_MEMORY;
    }

    var blksize: u32 = TFTP_BLKSIZE_DEFAULT;
    const opt_blksize = Curl_tftp_blksize(data);
    if (opt_blksize != 0) {
        blksize = opt_blksize;
    }

    var need_blksize: usize = blksize;
    if (need_blksize < TFTP_BLKSIZE_DEFAULT) {
        need_blksize = TFTP_BLKSIZE_DEFAULT;
    }

    if (state.rpacket.data == null) {
        const rbuf = mem.calloc(1, need_blksize + 2 + 2) orelse return CURLE_OUT_OF_MEMORY;
        state.rpacket.data = @ptrCast(rbuf);
    }
    if (state.spacket.data == null) {
        const sbuf = mem.calloc(1, need_blksize + 2 + 2) orelse return CURLE_OUT_OF_MEMORY;
        state.spacket.data = @ptrCast(sbuf);
    }

    Curl_conncontrol(conn, CONNCTRL_CONN_CLOSE);

    state.data = data;
    state.sockfd = Curl_conn_get_sock(conn, FIRSTSOCKET);
    state.state = .TFTP_STATE_START;
    state.err = .TFTP_ERR_NONE;
    state.blksize = TFTP_BLKSIZE_DEFAULT;
    state.requested_blksize = blksize;

    const remote_addr = Curl_conn_get_remote_addr(data, FIRSTSOCKET) orelse return CURLE_FAILED_INIT;
    state.local_addr.setFamily(remote_addr.family);

    const result = tftp_set_timeouts(state);
    if (result != CURLE_OK) return result;

    if (!Curl_conn_is_bound(conn)) {
        const rc = sysBind(state.sockfd, &state.local_addr, @intCast(remote_addr.addrlen));
        if (rc != 0) {
            var buffer: [STRERROR_LEN]u8 = undefined;
            failf(data, "bind() failed; %s", .{curlx_time_net.curlx_strerror(lastSocketError(), &buffer, buffer.len)});
            return CURLE_COULDNT_CONNECT;
        }
        Curl_conn_set_bound(conn, true);
    }

    done.* = true;
    return CURLE_OK;
}

fn tftp_done(data: *Curl_easy, status: CURLcode, premature: bool) callconv(.c) CURLcode {
    _ = status;
    _ = premature;
    const conn = Curl_easy_get_conn(data) orelse return CURLE_OK;
    const state_raw = Curl_conn_meta_get(conn, CURL_META_TFTP_CONN);

    if (Curl_pgrsDone(data, Curl_pgrs_now(data)) != 0) {
        return CURLE_ABORTED_BY_CALLBACK;
    }

    if (state_raw) |ptr| {
        const state: *TftpConn = @ptrCast(@alignCast(ptr));
        return tftp_translate_code(state.err);
    }
    return CURLE_OK;
}

fn tftp_pollset(data: *Curl_easy, ps: *easy_pollset) callconv(.c) CURLcode {
    const conn = Curl_easy_get_conn(data) orelse return CURLE_FAILED_INIT;
    return headers_sock.Curl_pollset_change(
        data,
        @ptrCast(@alignCast(ps)),
        Curl_conn_get_sock(conn, FIRSTSOCKET),
        headers_sock.CURL_POLL_IN,
        0,
    );
}

fn tftp_receive_packet(data: *Curl_easy, state: *TftpConn) CURLcode {
    var result: CURLcode = CURLE_OK;
    var remote_addr: CurlSockaddrStorage = .{};
    var fromlen: curl_socklen_t = @sizeOf(CurlSockaddrStorage);

    state.rbytes = @intCast(sysRecvfrom(
        state.sockfd,
        state.rpacket.data.?,
        state.blksize + 4,
        &remote_addr,
        &fromlen,
    ));
    if (state.rbytes >= 0 and fromlen > 0) {
        const flen: usize = @intCast(fromlen);
        if (state.remote_pinned) {
            if (state.remote_addrlen != fromlen or
                !std.mem.eql(u8, remote_addr.buffer[0..flen], state.remote_addr.buffer[0..flen]))
            {
                failf(data, "Data received from another address", .{});
                return CURLE_RECV_ERROR;
            }
        } else {
            state.remote_pinned = true;
            state.remote_addrlen = fromlen;
            @memcpy(state.remote_addr.buffer[0..flen], remote_addr.buffer[0..flen]);
        }
    }

    if (state.rbytes < 4) {
        failf(data, "Received too short packet", .{});
        state.event = .TFTP_EVENT_TIMEOUT;
    } else {
        const ev_u16 = getrpacketevent(&state.rpacket);
        state.event = @fromBackingInt(@intCast(@as(c_int, ev_u16)));

        switch (state.event) {
            .TFTP_EVENT_DATA => {
                if (Curl_tftp_is_upload(data)) return CURLE_TFTP_ILLEGAL;
                if (state.rbytes > 4 and nextBlocknum(state.block) == getrpacketblock(&state.rpacket)) {
                    result = Curl_client_write(
                        data,
                        CLIENTWRITE_BODY,
                        state.rpacket.data.? + 4,
                        @intCast(state.rbytes - 4),
                    );
                    if (result != CURLE_OK) {
                        _ = tftp_state_machine(state, .TFTP_EVENT_ERROR);
                        return result;
                    }
                }
            },
            .TFTP_EVENT_ERROR => {
                const err_u16 = getrpacketblock(&state.rpacket);
                const str: [*]const u8 = state.rpacket.data.? + 4;
                const strn: usize = @intCast(state.rbytes - 4);
                state.err = @fromBackingInt(@intCast(@as(c_int, err_u16)));
                if (tftp_strnlen(str, strn) < strn) {
                    const cstr: [*:0]const u8 = @ptrCast(str);
                    infof(data, "TFTP error: %s", .{cstr});
                }
            },
            .TFTP_EVENT_ACK => {},
            .TFTP_EVENT_OACK => {
                result = tftp_parse_option_ack(state, state.rpacket.data.? + 2, state.rbytes - 2);
                if (result != CURLE_OK) return result;
            },
            else => {
                failf(data, "%s", .{"Internal error: Unexpected packet"});
            },
        }

        result = Curl_pgrsUpdate(data);
        if (result != CURLE_OK) {
            _ = tftp_state_machine(state, .TFTP_EVENT_ERROR);
            return result;
        }
    }
    return result;
}

fn tftp_state_timeout(state: *TftpConn, event: ?*TftpEvent) timediff_t {
    if (event) |ev| ev.* = .TFTP_EVENT_NONE;

    const timeout_ms = Curl_timeleft_ms(state.data);
    if (timeout_ms < 0) {
        state.err = .TFTP_ERR_TIMEOUT;
        state.state = .TFTP_STATE_FIN;
        return timeout_ms;
    }
    const current = currentTime();
    if (current > state.rx_time + @as(i64, state.retry_time)) {
        if (event) |ev| ev.* = .TFTP_EVENT_TIMEOUT;
        state.rx_time = currentTime();
    }
    return timeout_ms;
}

fn tftp_multi_statemach(data: *Curl_easy, done: *bool) callconv(.c) CURLcode {
    const conn = Curl_easy_get_conn(data) orelse return CURLE_FAILED_INIT;
    const state_raw = Curl_conn_meta_get(conn, CURL_META_TFTP_CONN) orelse {
        done.* = false;
        return CURLE_FAILED_INIT;
    };
    const state: *TftpConn = @ptrCast(@alignCast(state_raw));

    done.* = false;

    var event: TftpEvent = .TFTP_EVENT_NONE;
    const timeout_ms = tftp_state_timeout(state, &event);
    if (timeout_ms < 0) {
        failf(data, "TFTP response timeout", .{});
        return CURLE_OPERATION_TIMEDOUT;
    }
    if (event != .TFTP_EVENT_NONE) {
        const result = tftp_state_machine(state, event);
        if (result != CURLE_OK) return result;
        done.* = (state.state == .TFTP_STATE_FIN);
        if (done.*) {
            Curl_xfer_setup_nop(data);
        }
        return CURLE_OK;
    } else {
        const rc = headers_sock.Curl_socket_check(
            state.sockfd,
            headers_sock.CURL_SOCKET_BAD,
            headers_sock.CURL_SOCKET_BAD,
            0,
        );
        if (rc == -1) {
            const sockerr = lastSocketError();
            var buffer: [STRERROR_LEN]u8 = undefined;
            failf(data, "%s", .{curlx_time_net.curlx_strerror(sockerr, &buffer, buffer.len)});
            state.event = .TFTP_EVENT_ERROR;
            return CURLE_OK;
        } else if (rc != 0) {
            var result = tftp_receive_packet(data, state);
            if (result != CURLE_OK) return result;
            result = tftp_state_machine(state, state.event);
            if (result != CURLE_OK) return result;
            done.* = (state.state == .TFTP_STATE_FIN);
            if (done.*) {
                Curl_xfer_setup_nop(data);
            }
            return CURLE_OK;
        }
    }
    return CURLE_OK;
}

fn tftp_doing(data: *Curl_easy, dophase_done: *bool) callconv(.c) CURLcode {
    var result = tftp_multi_statemach(data, dophase_done);
    if (!dophase_done.* and result == CURLE_OK) {
        result = Curl_pgrsCheck(data);
    }
    return result;
}

fn tftp_perform(data: *Curl_easy, dophase_done: *bool) CURLcode {
    const conn = Curl_easy_get_conn(data) orelse {
        dophase_done.* = false;
        return CURLE_FAILED_INIT;
    };
    const state_raw = Curl_conn_meta_get(conn, CURL_META_TFTP_CONN) orelse {
        dophase_done.* = false;
        return CURLE_FAILED_INIT;
    };
    const state: *TftpConn = @ptrCast(@alignCast(state_raw));

    dophase_done.* = false;
    const result = tftp_state_machine(state, .TFTP_EVENT_INIT);
    if (state.state == .TFTP_STATE_FIN or result != CURLE_OK) {
        return result;
    }
    return tftp_multi_statemach(data, dophase_done);
}

fn tftp_do(data: *Curl_easy, done: *bool) callconv(.c) CURLcode {
    const conn = Curl_easy_get_conn(data) orelse {
        done.* = false;
        return CURLE_FAILED_INIT;
    };
    var state_raw = Curl_conn_meta_get(conn, CURL_META_TFTP_CONN);
    done.* = false;

    if (state_raw == null) {
        const c_res = tftp_connect(data, done);
        if (c_res != CURLE_OK) return c_res;
        state_raw = Curl_conn_meta_get(conn, CURL_META_TFTP_CONN);
        if (state_raw == null) return CURLE_TFTP_ILLEGAL;
    }
    const state: *TftpConn = @ptrCast(@alignCast(state_raw.?));

    var result = tftp_perform(data, done);
    if (result == CURLE_OK) {
        result = tftp_translate_code(state.err);
    }
    return result;
}

fn tftp_setup_connection(data: *Curl_easy, conn: *connectdata) callconv(.c) CURLcode {
    const path = Curl_tftp_up_path(data) orelse return CURLE_OK;
    const len = std.mem.len(path);

    Curl_conn_set_transport_wanted(conn, TRNSPRT_UDP);

    if (len >= 14 and std.mem.eql(u8, path[len - 14 .. len], ";mode=netascii")) {
        Curl_tftp_set_prefer_ascii(data, true);
        path[len - 14] = 0;
    } else if (len >= 11 and std.mem.eql(u8, path[len - 11 .. len], ";mode=octet")) {
        Curl_tftp_set_prefer_ascii(data, false);
        path[len - 11] = 0;
    }

    return CURLE_OK;
}

pub export const Curl_protocol_tftp: CurlProtocol = .{
    .setup_connection = tftp_setup_connection,
    .do_it = tftp_do,
    .done = tftp_done,
    .do_more = null,
    .connect_it = tftp_connect,
    .connecting = tftp_multi_statemach,
    .doing = tftp_doing,
    .proto_pollset = tftp_pollset,
    .doing_pollset = tftp_pollset,
    .domore_pollset = null,
    .perform_pollset = null,
    .disconnect = null,
    .write_resp = null,
    .write_resp_hd = null,
    .connection_is_dead = null,
    .attach = null,
    .follow = null,
};

// ============================================================================
// 2. lib/socks.c — SOCKS4 / SOCKS4a / SOCKS5 / SOCKS5h Proxy Connection Filter
// ============================================================================

const SOCKS_CHUNK_SIZE: usize = 1024;
const SOCKS_CHUNKS: usize = 1;
const BUFQ_OPT_SOFT_LIMIT: u8 = 1 << 0;

const CURLPROXY_SOCKS4: u8 = 4;
const CURLPROXY_SOCKS5: u8 = 5;
const CURLPROXY_SOCKS4A: u8 = 6;
const CURLPROXY_SOCKS5_HOSTNAME: u8 = 7;

const CURL_IPRESOLVE_V4: u8 = 1;
const CURLAUTH_BASIC: u8 = 1 << 0;
const CURLAUTH_GSSAPI: u8 = 1 << 2;

const CF_TYPE_IP_CONNECT: c_int = 1 << 0;
const CF_TYPE_PROXY: c_int = 1 << 3;
const CF_QUERY_HOST_PORT: c_int = 11;
const CF_QUERY_ALPN_NEGOTIATED: c_int = 15;

pub const Curl_creds = extern struct {
    user: [*:0]const u8,
    passwd: [*:0]const u8,
    oauth_bearer: [*:0]const u8,
    sasl_authzid: [*:0]const u8,
    sasl_service: [*:0]const u8,
    refcount: u32,
    source: u8,
    bufsize: usize,
    buf: [1]u8,
};

extern fn Curl_peer_link(pdest: *?*Curl_peer, src: ?*Curl_peer) callconv(.c) void;
extern fn Curl_peer_unlink(ppeer: *?*Curl_peer) callconv(.c) void;
extern fn Curl_creds_link(pdest: *?*Curl_creds, src: ?*Curl_creds) callconv(.c) void;
extern fn Curl_creds_unlink(pcreds: *?*Curl_creds) callconv(.c) void;

extern fn Curl_cf_def_shutdown(cf: *Curl_cfilter, data: ?*Curl_easy, done: *bool) callconv(.c) CURLcode;
extern fn Curl_cf_def_data_pending(cf: *Curl_cfilter, data: ?*const Curl_easy) callconv(.c) bool;
extern fn Curl_cf_def_send(cf: *Curl_cfilter, data: ?*Curl_easy, buf: [*]const u8, len: usize, eos: bool, pnwritten: *usize) callconv(.c) CURLcode;
extern fn Curl_cf_def_recv(cf: *Curl_cfilter, data: ?*Curl_easy, buf: [*]u8, len: usize, pnread: *usize) callconv(.c) CURLcode;
extern fn Curl_cf_def_cntrl(cf: *Curl_cfilter, data: ?*Curl_easy, event: c_int, arg1: c_int, arg2: ?*anyopaque) callconv(.c) CURLcode;
extern fn Curl_cf_def_conn_is_alive(cf: *Curl_cfilter, data: ?*Curl_easy, input_pending: *bool) callconv(.c) bool;
extern fn Curl_cf_def_conn_keep_alive(cf: *Curl_cfilter, data: ?*Curl_easy) callconv(.c) CURLcode;

extern fn Curl_cf_create(pcf: *?*Curl_cfilter, cft: *const Curl_cftype, ctx: ?*anyopaque) callconv(.c) CURLcode;
extern fn Curl_conn_cf_insert_after(cf_at: *Curl_cfilter, cf_new: *Curl_cfilter) callconv(.c) void;
extern fn Curl_conn_cf_recv(cf: ?*Curl_cfilter, data: ?*Curl_easy, buf: [*]u8, len: usize, pnread: *usize) callconv(.c) CURLcode;
extern fn Curl_conn_cf_get_socket(cf: *Curl_cfilter, data: ?*Curl_easy) callconv(.c) curl_socket_t;
extern fn Curl_conn_cf_get_ip_info(cf: ?*Curl_cfilter, data: ?*Curl_easy, is_ipv6: *bool, ipquad: *ip_quadruple) callconv(.c) CURLcode;
extern fn Curl_cf_recv_bufq(cf: ?*Curl_cfilter, data: ?*Curl_easy, bufq: *io_buffers.bufq, maxlen: usize, pnread: *usize) callconv(.c) CURLcode;
extern fn Curl_cf_send_bufq(cf: ?*Curl_cfilter, data: ?*Curl_easy, bufq: *io_buffers.bufq, buf: ?[*]const u8, blen: usize, pnwritten: *usize) callconv(.c) CURLcode;

extern fn Curl_resolv_dns_queries(data: ?*Curl_easy, ip_version: u8) callconv(.c) u8;
extern fn Curl_conn_dns_add_addr_resolve(data: ?*Curl_easy, conn: ?*connectdata, sockindex: i8, peer: *Curl_peer, dns_queries: u8, transport: u8) callconv(.c) CURLcode;
extern fn Curl_conn_dns_addr_result(conn: ?*connectdata, sockindex: i8, peer: *Curl_peer) callconv(.c) CURLcode;
extern fn Curl_conn_dns_get_ai(data: ?*Curl_easy, peer: *Curl_peer, sockindex: i8, ai_family: c_int, index: c_uint) callconv(.c) ?*const Curl_addrinfo;
extern fn Curl_printable_address(ai: *const Curl_addrinfo, buf: [*]u8, bufsize: usize) callconv(.c) void;

const SocksState = enum(c_int) {
    SOCKS_ST_INIT = 0,
    SOCKS4_ST_START = 1,
    SOCKS4_ST_RESOLVING = 2,
    SOCKS4_ST_SEND = 3,
    SOCKS4_ST_RECV = 4,
    SOCKS5_ST_START = 5,
    SOCKS5_ST_REQ0_SEND = 6,
    SOCKS5_ST_RESP0_RECV = 7,
    SOCKS5_ST_GSSAPI_INIT = 8,
    SOCKS5_ST_AUTH_INIT = 9,
    SOCKS5_ST_AUTH_SEND = 10,
    SOCKS5_ST_AUTH_RECV = 11,
    SOCKS5_ST_REQ1_INIT = 12,
    SOCKS5_ST_RESOLVING = 13,
    SOCKS5_ST_REQ1_SEND = 14,
    SOCKS5_ST_RESP1_RECV = 15,
    SOCKS_ST_SUCCESS = 16,
    SOCKS_ST_FAILED = 17,
};

const SocksCtx = struct {
    state: SocksState,
    iobuf: io_buffers.bufq,
    dest: ?*Curl_peer,
    creds: ?*Curl_creds,
    presult: CURLproxycode,
    resolv_id: u32,
    ip_version: u8,
    proxy_type: u8,
    version: u8,
    resolve_local: bool,
    socks4a: bool,
};

pub export fn Curl_blockread_all(
    cf: *Curl_cfilter,
    data: ?*Curl_easy,
    buf_in: [*]u8,
    blen_in: usize,
    pnread: *usize,
) callconv(.c) CURLcode {
    var buf = buf_in;
    var blen = blen_in;
    pnread.* = 0;

    while (true) {
        var timeout_ms = Curl_timeleft_ms(data);
        const sock = Curl_conn_cf_get_socket(cf, data);

        if (timeout_ms < 0) return CURLE_OPERATION_TIMEDOUT;
        if (timeout_ms == 0) timeout_ms = curlx_time_net.TIMEDIFF_T_MAX;
        if (headers_sock.Curl_socket_check(
            sock,
            headers_sock.CURL_SOCKET_BAD,
            headers_sock.CURL_SOCKET_BAD,
            timeout_ms,
        ) <= 0) {
            return CURLE_OPERATION_TIMEDOUT;
        }

        var nread: usize = 0;
        const result = Curl_conn_cf_recv(cf.next, data, buf, blen, &nread);
        if (result == CURLE_AGAIN) continue;
        if (result != CURLE_OK) return result;

        if (blen == nread) {
            pnread.* += nread;
            return CURLE_OK;
        }
        if (nread == 0) return CURLE_RECV_ERROR;

        buf += nread;
        blen -= nread;
        pnread.* += nread;
    }
}

inline fn sxstate(sx: *SocksCtx, cf: *Curl_cfilter, data: ?*Curl_easy, state: SocksState) void {
    _ = cf;
    _ = data;
    sx.state = state;
}

fn socks_failed(sx: *SocksCtx, cf: *Curl_cfilter, data: ?*Curl_easy, presult: CURLproxycode) CURLproxycode {
    sxstate(sx, cf, data, .SOCKS_ST_FAILED);
    sx.presult = presult;
    return presult;
}

fn socks_flush(sx: *SocksCtx, cf: *Curl_cfilter, data: ?*Curl_easy, done: *bool) CURLproxycode {
    done.* = false;
    while (!io_buffers.Curl_bufq_is_empty(&sx.iobuf)) {
        var nwritten: usize = 0;
        const result = Curl_cf_send_bufq(cf.next, data, &sx.iobuf, null, 0, &nwritten);
        if (result == CURLE_AGAIN) {
            return CURLPX_OK;
        } else if (result != CURLE_OK) {
            failf(data, "Failed to send SOCKS request: %s", .{curl_easy_strerror(result)});
            return socks_failed(sx, cf, data, CURLPX_SEND_CONNECT);
        }
    }
    done.* = true;
    return CURLPX_OK;
}

fn socks_recv(
    sx: *SocksCtx,
    cf: *Curl_cfilter,
    data: ?*Curl_easy,
    min_bytes: usize,
    done: *bool,
) CURLproxycode {
    done.* = false;
    while (io_buffers.Curl_bufq_len(&sx.iobuf) < min_bytes) {
        var nread: usize = 0;
        const rem = min_bytes - io_buffers.Curl_bufq_len(&sx.iobuf);
        const result = Curl_cf_recv_bufq(cf.next, data, &sx.iobuf, rem, &nread);
        if (result == CURLE_AGAIN) {
            return CURLPX_OK;
        } else if (result != CURLE_OK) {
            failf(data, "Failed to receive SOCKS response: %s", .{curl_easy_strerror(result)});
            return CURLPX_RECV_CONNECT;
        } else if (nread == 0) {
            if (io_buffers.Curl_bufq_len(&sx.iobuf) < min_bytes) {
                failf(data, "Failed to receive SOCKS response, proxy closed connection", .{});
                return CURLPX_RECV_CONNECT;
            }
            break;
        }
    }
    done.* = true;
    return CURLPX_OK;
}

fn socks4_req_add_hd(sx: *SocksCtx) CURLproxycode {
    const port = sx.dest.?.port;
    const buf: [4]u8 = .{
        4,
        1,
        @intCast((port >> 8) & 0xff),
        @intCast(port & 0xff),
    };
    var nwritten: usize = 0;
    const result = io_buffers.Curl_bufq_write(&sx.iobuf, &buf, 4, &nwritten);
    if (result != CURLE_OK or nwritten != 4) return CURLPX_SEND_REQUEST;
    return CURLPX_OK;
}

fn socks4_req_add_user(sx: *SocksCtx, data: ?*Curl_easy) CURLproxycode {
    var nwritten: usize = 0;
    if (sx.creds) |creds| {
        const plen = std.mem.len(creds.user);
        if (plen > 255) {
            failf(data, "Too long SOCKS proxy username", .{});
            return CURLPX_LONG_USER;
        }
        const result = io_buffers.Curl_bufq_cwrite(&sx.iobuf, creds.user, plen + 1, &nwritten);
        if (result != CURLE_OK or nwritten != (plen + 1)) return CURLPX_SEND_REQUEST;
    } else {
        const b: [1]u8 = .{0};
        const result = io_buffers.Curl_bufq_write(&sx.iobuf, &b, 1, &nwritten);
        if (result != CURLE_OK or nwritten != 1) return CURLPX_SEND_REQUEST;
    }
    return CURLPX_OK;
}

fn socks4_resolving(sx: *SocksCtx, cf: *Curl_cfilter, data: ?*Curl_easy, done: *bool) CURLproxycode {
    done.* = false;
    const dest = sx.dest.?;
    const result = Curl_conn_dns_addr_result(cf.conn, cf.sockindex, dest);
    if (result != CURLE_OK) {
        if (result != CURLE_AGAIN) {
            failf(data, "error %d resolving SOCKS destination %s:%u", .{
                @as(c_int, @intCast(result)),
                dest.hostname.?,
                @as(c_uint, dest.port),
            });
            return CURLPX_RESOLVE_HOST;
        }
        return CURLPX_OK;
    }

    const ai = Curl_conn_dns_get_ai(data, dest, cf.sockindex, AF_INET, 0);
    if (ai) |addrinfo| {
        var ipbuf: [64]u8 = undefined;
        Curl_printable_address(addrinfo, &ipbuf, ipbuf.len);
        const ip_cstr: [*:0]const u8 = @ptrCast(&ipbuf);
        trcCf(data, cf, "SOCKS4 connect to IPv4 %s (locally resolved)", .{ip_cstr});

        const addr_bytes: [*]const u8 = @ptrCast(addrinfo.ai_addr.?);
        var nwritten: usize = 0;
        const wres = io_buffers.Curl_bufq_write(&sx.iobuf, addr_bytes + 4, 4, &nwritten);
        if (wres != CURLE_OK or nwritten != 4) return CURLPX_SEND_REQUEST;
    } else {
        failf(data, "SOCKS4 connection to %s not supported", .{dest.hostname.?});
        return CURLPX_RESOLVE_HOST;
    }

    done.* = true;
    return CURLPX_OK;
}

fn socks4_check_resp(sx: *SocksCtx, cf: *Curl_cfilter, data: ?*Curl_easy) CURLproxycode {
    var resp_opt: ?[*]const u8 = null;
    var rlen: usize = 0;
    if (!io_buffers.Curl_bufq_peek(&sx.iobuf, &resp_opt, &rlen) or rlen < 8) {
        failf(data, "SOCKS4 reply is incomplete.", .{});
        return CURLPX_RECV_CONNECT;
    }
    const resp = resp_opt.?;

    if (resp[0] != 0) {
        failf(data, "SOCKS4 reply has wrong version, version should be 0.", .{});
        return CURLPX_BAD_VERSION;
    }

    const port_val: c_uint = (@as(c_uint, resp[2]) << 8) | @as(c_uint, resp[3]);
    switch (resp[1]) {
        90 => {
            const s4a_str: [*:0]const u8 = if (sx.socks4a) "a" else "";
            trcCf(data, cf, "SOCKS4%s request granted.", .{s4a_str});
            io_buffers.Curl_bufq_skip(&sx.iobuf, 8);
            return CURLPX_OK;
        },
        91 => {
            failf(
                data,
                "[SOCKS] cannot complete SOCKS4 connection to %u.%u.%u.%u:%u. (%u), request rejected or failed.",
                .{ @as(c_uint, resp[4]), @as(c_uint, resp[5]), @as(c_uint, resp[6]), @as(c_uint, resp[7]), port_val, @as(c_uint, resp[1]) },
            );
            return CURLPX_REQUEST_FAILED;
        },
        92 => {
            failf(
                data,
                "[SOCKS] cannot complete SOCKS4 connection to %u.%u.%u.%u:%u. (%u), request rejected because SOCKS server cannot connect to identd on the client.",
                .{ @as(c_uint, resp[4]), @as(c_uint, resp[5]), @as(c_uint, resp[6]), @as(c_uint, resp[7]), port_val, @as(c_uint, resp[1]) },
            );
            return CURLPX_IDENTD;
        },
        93 => {
            failf(
                data,
                "[SOCKS] cannot complete SOCKS4 connection to %u.%u.%u.%u:%u. (%u), request rejected because the client program and identd report different user-ids.",
                .{ @as(c_uint, resp[4]), @as(c_uint, resp[5]), @as(c_uint, resp[6]), @as(c_uint, resp[7]), port_val, @as(c_uint, resp[1]) },
            );
            return CURLPX_IDENTD_DIFFER;
        },
        else => {
            failf(
                data,
                "[SOCKS] cannot complete SOCKS4 connection to %u.%u.%u.%u:%u. (%u), Unknown.",
                .{ @as(c_uint, resp[4]), @as(c_uint, resp[5]), @as(c_uint, resp[6]), @as(c_uint, resp[7]), port_val, @as(c_uint, resp[1]) },
            );
            return CURLPX_UNKNOWN_FAIL;
        },
    }
}

fn socks4_connect(cf: *Curl_cfilter, sx: *SocksCtx, data: ?*Curl_easy) CURLproxycode {
    var done: bool = false;

    while (true) {
        switch (sx.state) {
            .SOCKS_ST_INIT => {
                sx.version = 4;
                sxstate(sx, cf, data, .SOCKS4_ST_START);
                continue;
            },
            .SOCKS4_ST_START => {
                io_buffers.Curl_bufq_reset(&sx.iobuf);
                sx.socks4a = (sx.proxy_type == CURLPROXY_SOCKS4A);
                sx.presult = CURLPX_OK;
                sx.ip_version = CURL_IPRESOLVE_V4;

                const s4a_str: [*:0]const u8 = if (sx.socks4a) "a" else "";
                trcCf(data, cf, "SOCKS4%s connecting to %s:%u", .{
                    s4a_str,
                    sx.dest.?.hostname.?,
                    @as(c_uint, sx.dest.?.port),
                });

                var presult = socks4_req_add_hd(sx);
                if (presult != CURLPX_OK) return socks_failed(sx, cf, data, presult);

                if (!sx.resolve_local) {
                    const buf: [4]u8 = .{ 0, 0, 0, 1 };
                    const hlen = std.mem.len(sx.dest.?.hostname.?) + 1;
                    if (hlen > 255) {
                        failf(data, "SOCKS4: too long hostname", .{});
                        return socks_failed(sx, cf, data, CURLPX_LONG_HOSTNAME);
                    }
                    var nwritten: usize = 0;
                    var result = io_buffers.Curl_bufq_write(&sx.iobuf, &buf, 4, &nwritten);
                    if (result != CURLE_OK or nwritten != 4) {
                        return socks_failed(sx, cf, data, CURLPX_SEND_REQUEST);
                    }
                    presult = socks4_req_add_user(sx, data);
                    if (presult != CURLPX_OK) return socks_failed(sx, cf, data, presult);
                    result = io_buffers.Curl_bufq_cwrite(&sx.iobuf, sx.dest.?.hostname.?, hlen, &nwritten);
                    if (result != CURLE_OK or nwritten != hlen) {
                        return socks_failed(sx, cf, data, CURLPX_SEND_REQUEST);
                    }
                    sxstate(sx, cf, data, .SOCKS4_ST_SEND);
                    continue;
                }
                sxstate(sx, cf, data, .SOCKS4_ST_RESOLVING);
                continue;
            },
            .SOCKS4_ST_RESOLVING => {
                var presult = socks4_resolving(sx, cf, data, &done);
                if (presult != CURLPX_OK) return socks_failed(sx, cf, data, presult);
                if (!done) return CURLPX_OK;
                presult = socks4_req_add_user(sx, data);
                if (presult != CURLPX_OK) return socks_failed(sx, cf, data, presult);
                sxstate(sx, cf, data, .SOCKS4_ST_SEND);
                continue;
            },
            .SOCKS4_ST_SEND => {
                const presult = socks_flush(sx, cf, data, &done);
                if (presult != CURLPX_OK) return socks_failed(sx, cf, data, presult);
                if (!done) return CURLPX_OK;
                sxstate(sx, cf, data, .SOCKS4_ST_RECV);
                continue;
            },
            .SOCKS4_ST_RECV => {
                var presult = socks_recv(sx, cf, data, 8, &done);
                if (presult != CURLPX_OK) return socks_failed(sx, cf, data, presult);
                if (!done) return CURLPX_OK;
                presult = socks4_check_resp(sx, cf, data);
                if (presult != CURLPX_OK) return socks_failed(sx, cf, data, presult);
                sxstate(sx, cf, data, .SOCKS_ST_SUCCESS);
                continue;
            },
            .SOCKS_ST_SUCCESS => return CURLPX_OK,
            .SOCKS_ST_FAILED => return sx.presult,
            else => return socks_failed(sx, cf, data, CURLPX_SEND_REQUEST),
        }
    }
}

fn socks5_req0_init(cf: *Curl_cfilter, sx: *SocksCtx, data: ?*Curl_easy) CURLproxycode {
    const auth: u8 = if (data) |d| Curl_socks_get_socks5auth(d) else 0;
    const auth_only: bool = if (data) |d| Curl_socks_is_auth_only(d) else false;
    var req: [5]u8 = undefined;
    var nauths: u8 = 0;

    if (!sx.resolve_local and std.mem.len(sx.dest.?.hostname.?) > 255) {
        failf(data, "SOCKS5: the destination hostname is too long to be resolved remotely by the proxy.", .{});
        return CURLPX_LONG_HOSTNAME;
    }

    if ((auth & ~(CURLAUTH_BASIC | CURLAUTH_GSSAPI)) != 0) {
        infof(data, "warning: unsupported value passed to CURLOPT_SOCKS5_AUTH: %u", .{@as(c_uint, auth)});
    }
    if ((auth & CURLAUTH_BASIC) == 0) {
        Curl_creds_unlink(&sx.creds);
    }

    if (cf.sockindex == FIRSTSOCKET) {
        if (cf.conn) |conn| {
            Curl_conn_set_socks5_authenticated(conn, false);
        }
    }

    req[0] = 5;
    if (!auth_only) {
        nauths += 1;
        req[1 + nauths] = 0;
    }
    if (Curl_socks5_has_gssapi() and (auth & CURLAUTH_GSSAPI) != 0) {
        nauths += 1;
        req[1 + nauths] = 1;
    }
    if (sx.creds != null) {
        nauths += 1;
        req[1 + nauths] = 2;
    }
    if (nauths == 0) {
        failf(data, "SOCKS5: no acceptable authentication method is available.", .{});
        return CURLPX_NO_AUTH;
    }
    req[1] = nauths;
    const req_len: usize = 2 + @as(usize, nauths);

    var nwritten: usize = 0;
    const result = io_buffers.Curl_bufq_write(&sx.iobuf, &req, req_len, &nwritten);
    if (result != CURLE_OK or nwritten != req_len) return CURLPX_SEND_REQUEST;
    return CURLPX_OK;
}

fn socks5_check_resp0(sx: *SocksCtx, cf: *Curl_cfilter, data: ?*Curl_easy) CURLproxycode {
    var resp_opt: ?[*]const u8 = null;
    var rlen: usize = 0;
    if (!io_buffers.Curl_bufq_peek(&sx.iobuf, &resp_opt, &rlen) or rlen < 2) {
        failf(data, "SOCKS5 initial reply is incomplete.", .{});
        return CURLPX_RECV_CONNECT;
    }
    const resp = resp_opt.?;

    if (resp[0] != 5) {
        failf(data, "Received invalid version in initial SOCKS5 response.", .{});
        return CURLPX_BAD_VERSION;
    }

    const auth_mode = resp[1];
    io_buffers.Curl_bufq_skip(&sx.iobuf, 2);

    const auth: u8 = if (data) |d| Curl_socks_get_socks5auth(d) else 0;
    const auth_only: bool = if (data) |d| Curl_socks_is_auth_only(d) else false;

    switch (auth_mode) {
        0 => {
            if (auth_only) {
                failf(data, "SOCKS5 proxy selected no authentication.", .{});
                return CURLPX_NO_AUTH;
            }
            sxstate(sx, cf, data, .SOCKS5_ST_REQ1_INIT);
            return CURLPX_OK;
        },
        1 => {
            if ((auth & CURLAUTH_GSSAPI) != 0) {
                if (cf.sockindex == FIRSTSOCKET) {
                    if (cf.conn) |conn| Curl_conn_set_socks5_authenticated(conn, true);
                }
                sxstate(sx, cf, data, .SOCKS5_ST_GSSAPI_INIT);
                return CURLPX_OK;
            }
            failf(data, "SOCKS5 GSSAPI per-message authentication is not enabled.", .{});
            return CURLPX_GSSAPI_PERMSG;
        },
        2 => {
            if ((auth & CURLAUTH_BASIC) != 0) {
                if (cf.sockindex == FIRSTSOCKET) {
                    if (cf.conn) |conn| Curl_conn_set_socks5_authenticated(conn, true);
                }
                sxstate(sx, cf, data, .SOCKS5_ST_AUTH_INIT);
                return CURLPX_OK;
            }
            failf(data, "BASIC authentication proposed but not enabled.", .{});
            return CURLPX_NO_AUTH;
        },
        255 => {
            failf(data, "No authentication method was acceptable.", .{});
            return CURLPX_NO_AUTH;
        },
        else => {
            failf(data, "Unknown SOCKS5 mode attempted to be used by server.", .{});
            return CURLPX_UNKNOWN_MODE;
        },
    }
}

fn socks5_auth_init(cf: *Curl_cfilter, sx: *SocksCtx, data: ?*Curl_easy) CURLproxycode {
    var ulen: usize = 0;
    var plen: usize = 0;

    if (sx.creds) |creds| {
        ulen = std.mem.len(creds.user);
        plen = std.mem.len(creds.passwd);
        if (ulen > 255) {
            failf(data, "Excessive username length for proxy auth", .{});
            return CURLPX_LONG_USER;
        }
        if (plen > 255) {
            failf(data, "Excessive password length for proxy auth", .{});
            return CURLPX_LONG_PASSWD;
        }
    }

    var buf: [2]u8 = .{ 1, @intCast(ulen) };
    var nwritten: usize = 0;
    var result = io_buffers.Curl_bufq_write(&sx.iobuf, &buf, 2, &nwritten);
    if (result != CURLE_OK or nwritten != 2) return CURLPX_SEND_REQUEST;

    if (ulen != 0) {
        result = io_buffers.Curl_bufq_cwrite(&sx.iobuf, sx.creds.?.user, ulen, &nwritten);
        if (result != CURLE_OK or nwritten != ulen) return CURLPX_SEND_REQUEST;
    }

    buf[0] = @intCast(plen);
    result = io_buffers.Curl_bufq_write(&sx.iobuf, &buf, 1, &nwritten);
    if (result != CURLE_OK or nwritten != 1) return CURLPX_SEND_REQUEST;

    if (plen != 0) {
        result = io_buffers.Curl_bufq_cwrite(&sx.iobuf, sx.creds.?.passwd, plen, &nwritten);
        if (result != CURLE_OK or nwritten != plen) return CURLPX_SEND_REQUEST;
    }

    sxstate(sx, cf, data, .SOCKS5_ST_AUTH_SEND);
    return CURLPX_OK;
}

fn socks5_check_auth_resp(sx: *SocksCtx, cf: *Curl_cfilter, data: ?*Curl_easy) CURLproxycode {
    _ = cf;
    var resp_opt: ?[*]const u8 = null;
    var rlen: usize = 0;
    if (!io_buffers.Curl_bufq_peek(&sx.iobuf, &resp_opt, &rlen) or rlen < 2) {
        failf(data, "SOCKS5 sub-negotiation response incomplete.", .{});
        return CURLPX_RECV_CONNECT;
    }
    const resp = resp_opt.?;

    if (resp[1] != 0) {
        failf(data, "User was rejected by the SOCKS5 server (%d %d).", .{ @as(c_int, resp[0]), @as(c_int, resp[1]) });
        return CURLPX_USER_REJECTED;
    }
    io_buffers.Curl_bufq_skip(&sx.iobuf, 2);
    return CURLPX_OK;
}

fn socks5_req1_init(sx: *SocksCtx, cf: *Curl_cfilter, data: ?*Curl_easy) CURLproxycode {
    var req: [5]u8 = .{ 5, 1, 0, 0, 0 };
    var ipbuf: [16]u8 = undefined;
    var nwritten: usize = 0;

    if (sx.resolve_local) {
        const result = io_buffers.Curl_bufq_write(&sx.iobuf, &req, 3, &nwritten);
        if (result != CURLE_OK or nwritten != 3) return CURLPX_SEND_REQUEST;
        return CURLPX_OK;
    }

    const hostname = sx.dest.?.hostname.?;
    const hostname_slice = std.mem.span(hostname);
    var destination: [*]const u8 = undefined;
    var desttype: u8 = 0;
    var destlen: u8 = 0;

    if (std.mem.indexOfScalar(u8, hostname_slice, ':') != null) {
        desttype = 4;
        destination = &ipbuf;
        destlen = 16;
        if (curlx_time_net.curlx_inet_pton(AF_INET6, hostname, &ipbuf) != 1) {
            return CURLPX_BAD_ADDRESS_TYPE;
        }
    } else if (curlx_time_net.curlx_inet_pton(AF_INET, hostname, &ipbuf) == 1) {
        desttype = 1;
        destination = &ipbuf;
        destlen = 4;
    } else {
        desttype = 3;
        destination = hostname;
        destlen = std.math.cast(u8, hostname_slice.len) orelse return CURLPX_LONG_HOSTNAME;
    }

    req[3] = desttype;
    req[4] = destlen;
    const hdlen: usize = if (desttype == 3) 5 else 4;
    var result = io_buffers.Curl_bufq_write(&sx.iobuf, &req, hdlen, &nwritten);
    if (result != CURLE_OK or nwritten != hdlen) return CURLPX_SEND_REQUEST;

    const dest_slice = destination[0..destlen];
    result = io_buffers.Curl_bufq_write(&sx.iobuf, dest_slice.ptr, dest_slice.len, &nwritten);
    if (result != CURLE_OK or nwritten != dest_slice.len) return CURLPX_SEND_REQUEST;

    const port = sx.dest.?.port;
    const port_u16 = std.math.cast(u16, port) orelse return CURLPX_SEND_REQUEST;
    std.mem.writeInt(u16, req[0..2], port_u16, .big);
    result = io_buffers.Curl_bufq_write(&sx.iobuf, &req, 2, &nwritten);
    if (result != CURLE_OK or nwritten != 2) return CURLPX_SEND_REQUEST;

    trcCf(data, cf, "SOCKS5 connect to %s:%u (remotely resolved)", .{ hostname, @as(c_uint, port) });
    return CURLPX_OK;
}

fn socks5_resolving(sx: *SocksCtx, cf: *Curl_cfilter, data: ?*Curl_easy, done: *bool) CURLproxycode {
    done.* = false;
    const dest_peer = sx.dest.?;
    var result = Curl_conn_dns_addr_result(cf.conn, cf.sockindex, dest_peer);
    if (result != CURLE_OK) {
        if (result != CURLE_AGAIN) {
            failf(data, "error %d resolving SOCKS destination %s:%u", .{
                @as(c_int, @intCast(result)),
                dest_peer.hostname.?,
                @as(c_uint, dest_peer.port),
            });
            return CURLPX_RESOLVE_HOST;
        }
        return CURLPX_OK;
    }

    var ai: ?*const Curl_addrinfo = null;
    const ipver: u8 = if (data) |d| Curl_socks_get_ipver(d) else 0;
    if (ipver != CURL_IPRESOLVE_V4) {
        ai = Curl_conn_dns_get_ai(data, dest_peer, cf.sockindex, AF_INET6, 0);
    }
    if (ai == null) {
        ai = Curl_conn_dns_get_ai(data, dest_peer, cf.sockindex, AF_INET, 0);
    }

    const addrinfo = ai orelse {
        failf(data, "Failed to resolve \"%s\" for SOCKS5 connect.", .{dest_peer.hostname.?});
        done.* = false;
        return CURLPX_RESOLVE_HOST;
    };

    var dest_ip: [vdns_cfilters.MAX_IPADR_LEN]u8 = undefined;
    Curl_printable_address(addrinfo, &dest_ip, dest_ip.len);
    const dest_ip_cstr: [*:0]const u8 = @ptrCast(&dest_ip);

    var destination: ?[*]const u8 = null;
    var desttype: u8 = 1;
    var destlen: u8 = 4;

    if (addrinfo.ai_family == AF_INET) {
        desttype = 1;
        destlen = 4;
        const addr_bytes: [*]const u8 = @ptrCast(addrinfo.ai_addr.?);
        destination = addr_bytes + 4;
        trcCf(data, cf, "SOCKS5 connect to %s:%u (locally resolved)", .{ dest_ip_cstr, @as(c_uint, dest_peer.port) });
    } else if (addrinfo.ai_family == AF_INET6) {
        desttype = 4;
        destlen = 16;
        const addr_bytes: [*]const u8 = @ptrCast(addrinfo.ai_addr.?);
        destination = addr_bytes + 8;
        trcCf(data, cf, "SOCKS5 connect to [%s]:%u (locally resolved)", .{ dest_ip_cstr, @as(c_uint, dest_peer.port) });
    }

    const dest_bytes = destination orelse {
        failf(data, "SOCKS5 connection to %s not supported", .{dest_ip_cstr});
        done.* = false;
        return CURLPX_RESOLVE_HOST;
    };

    var req: [2]u8 = .{ desttype, 0 };
    var nwritten: usize = 0;
    result = io_buffers.Curl_bufq_write(&sx.iobuf, &req, 1, &nwritten);
    if (result != CURLE_OK or nwritten != 1) {
        done.* = false;
        return CURLPX_SEND_REQUEST;
    }

    result = io_buffers.Curl_bufq_write(&sx.iobuf, dest_bytes, destlen, &nwritten);
    if (result != CURLE_OK or nwritten != destlen) {
        done.* = false;
        return CURLPX_SEND_REQUEST;
    }

    const port = dest_peer.port;
    req[0] = @intCast((port >> 8) & 0xff);
    req[1] = @intCast(port & 0xff);
    result = io_buffers.Curl_bufq_write(&sx.iobuf, &req, 2, &nwritten);
    if (result != CURLE_OK or nwritten != 2) {
        done.* = false;
        return CURLPX_SEND_REQUEST;
    }

    done.* = true;
    return CURLPX_OK;
}

fn socks5_recv_resp1(sx: *SocksCtx, cf: *Curl_cfilter, data: ?*Curl_easy, done: *bool) CURLproxycode {
    var resp_opt: ?[*]const u8 = null;
    var rlen: usize = 0;
    var resp_len: usize = 8;

    var presult = socks_recv(sx, cf, data, resp_len, done);
    if (presult != CURLPX_OK) return presult;
    if (!done.*) return CURLPX_OK;

    if (!io_buffers.Curl_bufq_peek(&sx.iobuf, &resp_opt, &rlen) or rlen < resp_len) {
        failf(data, "SOCKS5 response is incomplete.", .{});
        return CURLPX_RECV_CONNECT;
    }
    var resp = resp_opt.?;

    if (resp[0] != 5) {
        failf(data, "SOCKS5 reply has wrong version, version should be 5.", .{});
        return CURLPX_BAD_VERSION;
    } else if (resp[1] != 0) {
        const code: usize = resp[1];
        failf(data, "cannot complete SOCKS5 connection to %s. (%d)", .{ sx.dest.?.hostname.?, @as(c_int, @intCast(code)) });
        const lookup = [_]CURLproxycode{
            CURLPX_OK,
            CURLPX_REPLY_GENERAL_SERVER_FAILURE,
            CURLPX_REPLY_NOT_ALLOWED,
            CURLPX_REPLY_NETWORK_UNREACHABLE,
            CURLPX_REPLY_HOST_UNREACHABLE,
            CURLPX_REPLY_CONNECTION_REFUSED,
            CURLPX_REPLY_TTL_EXPIRED,
            CURLPX_REPLY_COMMAND_NOT_SUPPORTED,
            CURLPX_REPLY_ADDRESS_TYPE_NOT_SUPPORTED,
        };
        if (code < lookup.len) return lookup[code];
        return CURLPX_REPLY_UNASSIGNED;
    }

    switch (resp[3]) {
        1 => resp_len = 4 + 4 + 2,
        3 => resp_len = 4 + 1 + @as(usize, resp[4]) + 2,
        4 => resp_len = 4 + 16 + 2,
        else => {
            failf(data, "SOCKS5 reply has wrong address type.", .{});
            return CURLPX_BAD_ADDRESS_TYPE;
        },
    }

    presult = socks_recv(sx, cf, data, resp_len, done);
    if (presult != CURLPX_OK) return presult;
    if (!done.*) return CURLPX_OK;

    if (!io_buffers.Curl_bufq_peek(&sx.iobuf, &resp_opt, &rlen) or rlen < resp_len) {
        failf(data, "SOCKS5 response is incomplete.", .{});
        return CURLPX_RECV_CONNECT;
    }
    resp = resp_opt.?;
    done.* = true;
    return CURLPX_OK;
}

fn socks5_connect(cf: *Curl_cfilter, sx: *SocksCtx, data: ?*Curl_easy) CURLproxycode {
    var done: bool = false;

    while (true) {
        switch (sx.state) {
            .SOCKS_ST_INIT => {
                sx.version = 5;
                sxstate(sx, cf, data, .SOCKS5_ST_START);
                continue;
            },
            .SOCKS5_ST_START => {
                trcCf(data, cf, "SOCKS5: connecting to %s:%u", .{ sx.dest.?.hostname.?, @as(c_uint, sx.dest.?.port) });
                const presult = socks5_req0_init(cf, sx, data);
                if (presult != CURLPX_OK) return socks_failed(sx, cf, data, presult);
                sxstate(sx, cf, data, .SOCKS5_ST_REQ0_SEND);
                continue;
            },
            .SOCKS5_ST_REQ0_SEND => {
                const presult = socks_flush(sx, cf, data, &done);
                if (presult != CURLPX_OK) return socks_failed(sx, cf, data, presult);
                if (!done) return CURLPX_OK;
                sxstate(sx, cf, data, .SOCKS5_ST_RESP0_RECV);
                continue;
            },
            .SOCKS5_ST_RESP0_RECV => {
                var presult = socks_recv(sx, cf, data, 2, &done);
                if (presult != CURLPX_OK) return socks_failed(sx, cf, data, presult);
                if (!done) return CURLPX_OK;
                presult = socks5_check_resp0(sx, cf, data);
                if (presult != CURLPX_OK) return socks_failed(sx, cf, data, presult);
                continue;
            },
            .SOCKS5_ST_GSSAPI_INIT => {
                if (Curl_socks5_has_gssapi()) {
                    const result = Curl_socks5_gssapi_negotiate(cf, data, sx.creds);
                    if (result != CURLE_OK) {
                        failf(data, "Unable to negotiate SOCKS5 GSS-API context.", .{});
                        return CURLPX_GSSAPI;
                    }
                    sxstate(sx, cf, data, .SOCKS5_ST_REQ1_INIT);
                    continue;
                } else {
                    failf(data, "SOCKS5 GSSAPI per-message authentication is not supported.", .{});
                    return socks_failed(sx, cf, data, CURLPX_GSSAPI_PERMSG);
                }
            },
            .SOCKS5_ST_AUTH_INIT => {
                const presult = socks5_auth_init(cf, sx, data);
                if (presult != CURLPX_OK) return socks_failed(sx, cf, data, presult);
                sxstate(sx, cf, data, .SOCKS5_ST_AUTH_SEND);
                continue;
            },
            .SOCKS5_ST_AUTH_SEND => {
                const presult = socks_flush(sx, cf, data, &done);
                if (presult != CURLPX_OK) return socks_failed(sx, cf, data, presult);
                if (!done) return CURLPX_OK;
                sxstate(sx, cf, data, .SOCKS5_ST_AUTH_RECV);
                continue;
            },
            .SOCKS5_ST_AUTH_RECV => {
                var presult = socks_recv(sx, cf, data, 2, &done);
                if (presult != CURLPX_OK) return socks_failed(sx, cf, data, presult);
                if (!done) return CURLPX_OK;
                presult = socks5_check_auth_resp(sx, cf, data);
                if (presult != CURLPX_OK) return socks_failed(sx, cf, data, presult);
                sxstate(sx, cf, data, .SOCKS5_ST_REQ1_INIT);
                continue;
            },
            .SOCKS5_ST_REQ1_INIT => {
                const presult = socks5_req1_init(sx, cf, data);
                if (presult != CURLPX_OK) return socks_failed(sx, cf, data, presult);
                if (!sx.resolve_local) {
                    sxstate(sx, cf, data, .SOCKS5_ST_REQ1_SEND);
                    continue;
                }
                sxstate(sx, cf, data, .SOCKS5_ST_RESOLVING);
                continue;
            },
            .SOCKS5_ST_RESOLVING => {
                const presult = socks5_resolving(sx, cf, data, &done);
                if (presult != CURLPX_OK) return socks_failed(sx, cf, data, presult);
                if (!done) return CURLPX_OK;
                sxstate(sx, cf, data, .SOCKS5_ST_REQ1_SEND);
                continue;
            },
            .SOCKS5_ST_REQ1_SEND => {
                const presult = socks_flush(sx, cf, data, &done);
                if (presult != CURLPX_OK) return socks_failed(sx, cf, data, presult);
                if (!done) return CURLPX_OK;
                if (cf.conn) |conn| {
                    if (Curl_conn_socks5_gssapi_enctype(conn)) {
                        failf(data, "SOCKS5 GSS-API protection not yet implemented.", .{});
                        return CURLPX_GSSAPI_PROTECTION;
                    }
                }
                sxstate(sx, cf, data, .SOCKS5_ST_RESP1_RECV);
                continue;
            },
            .SOCKS5_ST_RESP1_RECV => {
                const presult = socks5_recv_resp1(sx, cf, data, &done);
                if (presult != CURLPX_OK) return socks_failed(sx, cf, data, presult);
                if (!done) return CURLPX_OK;
                trcCf(data, cf, "SOCKS5 request granted.", .{});
                sxstate(sx, cf, data, .SOCKS_ST_SUCCESS);
                continue;
            },
            .SOCKS_ST_SUCCESS => return CURLPX_OK,
            .SOCKS_ST_FAILED => return sx.presult,
            else => return socks_failed(sx, cf, data, CURLPX_UNKNOWN_FAIL),
        }
    }
}

fn socks_proxy_ctx_free(ctx: ?*SocksCtx) void {
    if (ctx) |c| {
        Curl_peer_unlink(&c.dest);
        Curl_creds_unlink(&c.creds);
        io_buffers.Curl_bufq_free(&c.iobuf);
        mem.freeSized(c, @sizeOf(SocksCtx));
    }
}

fn socks_proxy_cf_connect(cf: *Curl_cfilter, data: ?*Curl_easy, done: *bool) callconv(.c) CURLcode {
    const ctx: *SocksCtx = @ptrCast(@alignCast(cf.ctx.?));
    var pxresult: CURLproxycode = CURLPX_OK;

    if (cf.isConnected()) {
        done.* = true;
        return CURLE_OK;
    }

    var result = cf.next.?.cft.do_connect(cf.next.?, data, done);
    if (result != CURLE_OK or !done.*) return result;

    switch (ctx.proxy_type) {
        CURLPROXY_SOCKS5, CURLPROXY_SOCKS5_HOSTNAME => {
            pxresult = socks5_connect(cf, ctx, data);
        },
        CURLPROXY_SOCKS4, CURLPROXY_SOCKS4A => {
            pxresult = socks4_connect(cf, ctx, data);
        },
        else => {
            result = CURLE_COULDNT_CONNECT;
            done.* = cf.isConnected();
            Curl_creds_unlink(&ctx.creds);
            return result;
        },
    }

    if (pxresult != CURLPX_OK) {
        result = CURLE_PROXY;
        if (data) |d| Curl_socks_set_pxcode(d, @intCast(pxresult));
    } else if (ctx.state == .SOCKS_ST_SUCCESS) {
        if (data) |d| {
            if (Curl_easy_get_verbose(d)) {
                var ipquad: ip_quadruple = std.mem.zeroes(ip_quadruple);
                var is_ipv6: bool = false;
                const second_str: [*:0]const u8 = if (cf.sockindex == SECONDARYSOCKET) "2nd " else "";
                if (Curl_conn_cf_get_ip_info(cf.next, data, &is_ipv6, &ipquad) == CURLE_OK) {
                    const local_ip: [*:0]const u8 = @ptrCast(&ipquad.local_ip);
                    const remote_ip: [*:0]const u8 = @ptrCast(&ipquad.remote_ip);
                    infof(
                        data,
                        "Opened %sSOCKS connection from %s port %d to %s port %d (via %s port %u)",
                        .{
                            second_str,
                            local_ip,
                            @as(c_int, ipquad.local_port),
                            ctx.dest.?.hostname.?,
                            @as(c_int, ctx.dest.?.port),
                            remote_ip,
                            @as(c_uint, ipquad.remote_port),
                        },
                    );
                } else {
                    infof(data, "Opened %sSOCKS connection", .{second_str});
                }
            }
        }
        cf.setConnected(true);
    }

    done.* = cf.isConnected();
    if (done.* or result != CURLE_OK) {
        Curl_creds_unlink(&ctx.creds);
    }
    return result;
}

fn socks_cf_adjust_pollset(cf: *Curl_cfilter, data: ?*Curl_easy, ps: *easy_pollset) callconv(.c) CURLcode {
    if (!cf.isConnected()) {
        if (cf.ctx) |ctx_raw| {
            const sx: *SocksCtx = @ptrCast(@alignCast(ctx_raw));
            const sock = Curl_conn_cf_get_socket(cf, data);
            const hps: *headers_sock.EasyPollset = @ptrCast(@alignCast(ps));
            switch (sx.state) {
                .SOCKS4_ST_SEND, .SOCKS5_ST_REQ0_SEND, .SOCKS5_ST_AUTH_SEND, .SOCKS5_ST_REQ1_SEND => {
                    trcCf(data, cf, "adjust pollset out (%d)", .{@backingInt(sx.state)});
                    return headers_sock.Curl_pollset_change(
                        data,
                        hps,
                        sock,
                        headers_sock.CURL_POLL_OUT,
                        headers_sock.CURL_POLL_IN,
                    );
                },
                else => {
                    trcCf(data, cf, "adjust pollset in (%d)", .{@backingInt(sx.state)});
                    return headers_sock.Curl_pollset_change(
                        data,
                        hps,
                        sock,
                        headers_sock.CURL_POLL_IN,
                        headers_sock.CURL_POLL_OUT,
                    );
                },
            }
        }
    }
    return CURLE_OK;
}

fn socks_proxy_cf_destroy(cf: *Curl_cfilter, data: ?*Curl_easy) callconv(.c) void {
    _ = data;
    if (cf.ctx) |ctx_raw| {
        const ctx: *SocksCtx = @ptrCast(@alignCast(ctx_raw));
        socks_proxy_ctx_free(ctx);
        cf.ctx = null;
    }
}

fn socks_cf_query(
    cf: *Curl_cfilter,
    data: ?*Curl_easy,
    query: c_int,
    pres1: ?*c_int,
    pres2: ?*anyopaque,
) callconv(.c) CURLcode {
    if (query == CF_QUERY_HOST_PORT) {
        if (cf.ctx) |ctx_raw| {
            const sx: *SocksCtx = @ptrCast(@alignCast(ctx_raw));
            if (pres1) |p1| p1.* = @intCast(sx.dest.?.port);
            if (pres2) |p2| {
                const p_host: *?[*:0]const u8 = @ptrCast(@alignCast(p2));
                p_host.* = sx.dest.?.hostname;
            }
            return CURLE_OK;
        }
    } else if (query == CF_QUERY_ALPN_NEGOTIATED) {
        if (pres2) |p2| {
            const palpn: *?[*:0]const u8 = @ptrCast(@alignCast(p2));
            palpn.* = null;
        }
        return CURLE_OK;
    }

    if (cf.next) |next_cf| {
        return next_cf.cft.query(next_cf, data, query, pres1, pres2);
    }
    return CURLE_UNKNOWN_OPTION;
}

pub export var Curl_cft_socks_proxy: Curl_cftype = .{
    .name = "SOCKS",
    .flags = CF_TYPE_IP_CONNECT | CF_TYPE_PROXY,
    .log_level = 0,
    .destroy = socks_proxy_cf_destroy,
    .do_connect = socks_proxy_cf_connect,
    .do_shutdown = Curl_cf_def_shutdown,
    .adjust_pollset = socks_cf_adjust_pollset,
    .has_data_pending = Curl_cf_def_data_pending,
    .do_send = Curl_cf_def_send,
    .do_recv = Curl_cf_def_recv,
    .cntrl = Curl_cf_def_cntrl,
    .is_alive = Curl_cf_def_conn_is_alive,
    .keep_alive = Curl_cf_def_conn_keep_alive,
    .query = socks_cf_query,
};

pub export fn Curl_cf_socks_proxy_insert_after(
    cf_at: *Curl_cfilter,
    data: ?*Curl_easy,
    dest_opt: ?*Curl_peer,
    ip_version: u8,
    proxy_type: u8,
    creds: ?*Curl_creds,
) callconv(.c) CURLcode {
    const dest = dest_opt orelse return CURLE_FAILED_INIT;
    var resolve_local = false;
    var dns_queries = Curl_resolv_dns_queries(data, ip_version);

    switch (proxy_type) {
        CURLPROXY_SOCKS5 => resolve_local = true,
        CURLPROXY_SOCKS5_HOSTNAME => {},
        CURLPROXY_SOCKS4 => {
            resolve_local = true;
            dns_queries &= ~vdns_cfilters.CURL_DNSQ_AAAA;
        },
        CURLPROXY_SOCKS4A => {},
        else => {
            failf(data, "unknown proxytype %d option given", .{@as(c_int, proxy_type)});
            return CURLE_COULDNT_CONNECT;
        },
    }

    const raw = mem.calloc(1, @sizeOf(SocksCtx)) orelse return CURLE_OUT_OF_MEMORY;
    const ctx: *SocksCtx = @ptrCast(@alignCast(raw));

    Curl_peer_link(&ctx.dest, dest);
    ctx.ip_version = ip_version;
    ctx.proxy_type = proxy_type;
    ctx.resolve_local = resolve_local;
    Curl_creds_link(&ctx.creds, creds);
    io_buffers.Curl_bufq_init2(&ctx.iobuf, SOCKS_CHUNK_SIZE, SOCKS_CHUNKS, BUFQ_OPT_SOFT_LIMIT);

    var cf: ?*Curl_cfilter = null;
    var result = Curl_cf_create(&cf, &Curl_cft_socks_proxy, ctx);
    if (result == CURLE_OK) {
        Curl_conn_cf_insert_after(cf_at, cf.?);
        if (ctx.resolve_local) {
            result = Curl_conn_dns_add_addr_resolve(
                data,
                cf_at.conn,
                cf_at.sockindex,
                ctx.dest.?,
                dns_queries,
                TRNSPRT_TCP,
            );
        }
    } else {
        socks_proxy_ctx_free(ctx);
    }
    return result;
}

// ============================================================================
// 3. lib/telnet.c — TELNET Protocol Handler
// ============================================================================

const SUBBUFSIZE: usize = 512;

const CURL_NO: c_int = 0;
const CURL_YES: c_int = 1;
const CURL_WANTYES: c_int = 2;
const CURL_WANTNO: c_int = 3;

const CURL_EMPTY: c_int = 0;
const CURL_OPPOSITE: c_int = 1;

const CURL_META_TELNET_EASY = "meta:proto:telnet:easy";

const CURL_TELOPT_BINARY: usize = 0;
const CURL_TELOPT_ECHO: usize = 1;
const CURL_TELOPT_SGA: usize = 3;
const CURL_TELOPT_TTYPE: usize = 24;
const CURL_TELOPT_NAWS: usize = 31;
const CURL_TELOPT_XDISPLOC: usize = 35;
const CURL_TELOPT_NEW_ENVIRON: usize = 39;
const CURL_TELOPT_EXOPL: usize = 255;
const CURL_TELOPT_MAXIMUM: usize = CURL_TELOPT_NEW_ENVIRON;
const CURL_NTELOPTS: usize = 40;

const CURL_NEW_ENV_VAR: u8 = 0;
const CURL_NEW_ENV_VALUE: u8 = 1;

const CURL_xEOF: u8 = 236;
const CURL_SE: u8 = 240;
const CURL_NOP: u8 = 241;
const CURL_DM: u8 = 242;
const CURL_GA: u8 = 249;
const CURL_SB: u8 = 250;
const CURL_WILL: u8 = 251;
const CURL_WONT: u8 = 252;
const CURL_DO: u8 = 253;
const CURL_DONT: u8 = 254;
const CURL_IAC: u8 = 255;

const CURL_TELCMD_MINIMUM: usize = CURL_xEOF;
const CURL_TELCMD_MAXIMUM: usize = CURL_IAC;

const CURL_TELQUAL_IS: u8 = 0;
const CURL_TELQUAL_SEND: u8 = 1;
const CURL_TELQUAL_INFO: u8 = 2;
const CURL_TELQUAL_NAME: u8 = 3;

const CURL_READFUNC_ABORT: usize = 0x10000000;
const CURL_READFUNC_PAUSE: usize = 0x10000001;

const telnetoptions = [CURL_NTELOPTS][*:0]const u8{
    "BINARY",      "ECHO",           "RCP",           "SUPPRESS GO AHEAD",
    "NAME",        "STATUS",         "TIMING MARK",   "RCTE",
    "NAOL",        "NAOP",           "NAOCRD",        "NAOHTS",
    "NAOHTD",      "NAOFFD",         "NAOVTS",        "NAOVTD",
    "NAOLFD",      "EXTEND ASCII",   "LOGOUT",        "BYTE MACRO",
    "DE TERMINAL", "SUPDUP",         "SUPDUP OUTPUT", "SEND LOCATION",
    "TERM TYPE",   "END OF RECORD",  "TACACS UID",    "OUTPUT MARKING",
    "TTYLOC",      "3270 REGIME",    "X3 PAD",        "NAWS",
    "TERM SPEED",  "LFLOW",          "LINEMODE",      "XDISPLOC",
    "OLD-ENVIRON", "AUTHENTICATION", "ENCRYPT",       "NEW-ENVIRON",
};

const telnetcmds = [_][*:0]const u8{
    "EOF",  "SUSP",  "ABORT", "EOR",  "SE",
    "NOP",  "DMARK", "BRK",   "IP",   "AO",
    "AYT",  "EC",    "EL",    "GA",   "SB",
    "WILL", "WONT",  "DO",    "DONT", "IAC",
};

inline fn curlTeloptOk(x: usize) bool {
    return x <= CURL_TELOPT_MAXIMUM;
}

inline fn curlTelopt(x: usize) [*:0]const u8 {
    return telnetoptions[x];
}

inline fn curlTelcmdOk(x: usize) bool {
    return x >= CURL_TELCMD_MINIMUM and x <= CURL_TELCMD_MAXIMUM;
}

inline fn curlTelcmd(x: usize) [*:0]const u8 {
    return telnetcmds[x - CURL_TELCMD_MINIMUM];
}

const TelnetReceive = enum(c_int) {
    CURL_TS_DATA = 0,
    CURL_TS_IAC = 1,
    CURL_TS_WILL = 2,
    CURL_TS_WONT = 3,
    CURL_TS_DO = 4,
    CURL_TS_DONT = 5,
    CURL_TS_CR = 6,
    CURL_TS_SB = 7,
    CURL_TS_SE = 8,
};

const TELNET = struct {
    please_negotiate: c_int,
    already_negotiated: c_int,
    us: [256]c_int,
    usq: [256]c_int,
    us_preferred: [256]c_int,
    him: [256]c_int,
    himq: [256]c_int,
    him_preferred: [256]c_int,
    subnegotiation: [256]c_int,
    subopt_ttype: ?[*:0]const u8,
    subopt_xdisploc: ?[*:0]const u8,
    subopt_wsx: u16,
    subopt_wsy: u16,
    telrcv_state: TelnetReceive,
    telnet_vars: ?*containers.curl_slist,
    out: containers.dynbuf,
    subbuffer: [SUBBUFSIZE]u8,
    subpointer: usize,
    subend: usize,

    fn sbClear(self: *TELNET) void {
        self.subpointer = 0;
        self.subend = 0;
    }

    fn sbTerm(self: *TELNET) void {
        self.subend = @min(self.subpointer, self.subbuffer.len);
        self.subpointer = 0;
    }

    fn sbAccum(self: *TELNET, c: u8) void {
        if (self.subpointer < self.subbuffer.len) {
            self.subbuffer[self.subpointer] = c;
            self.subpointer += 1;
        }
    }

    fn sbGet(self: *TELNET) u8 {
        if (self.subpointer >= self.subend or self.subpointer >= self.subbuffer.len) {
            return 0;
        }
        const c = self.subbuffer[self.subpointer];
        self.subpointer += 1;
        return c;
    }

    fn sbLen(self: *const TELNET) usize {
        return if (self.subend >= self.subpointer) self.subend - self.subpointer else 0;
    }
};

fn printoption(data: *Curl_easy, direction: [*:0]const u8, cmd: c_int, option: c_int) void {
    if (Curl_easy_get_verbose(data)) {
        const opt_u: usize = @intCast(@as(c_uint, @bitCast(option)));
        if (cmd == CURL_IAC) {
            if (curlTelcmdOk(opt_u)) {
                infof(data, "%s IAC %s", .{ direction, curlTelcmd(opt_u) });
            } else {
                infof(data, "%s IAC %d", .{ direction, option });
            }
        } else {
            const fmt_opt: ?[*:0]const u8 = if (cmd == CURL_WILL)
                "WILL"
            else if (cmd == CURL_WONT)
                "WONT"
            else if (cmd == CURL_DO)
                "DO"
            else if (cmd == CURL_DONT)
                "DONT"
            else
                null;

            if (fmt_opt) |fmt| {
                const opt_name: ?[*:0]const u8 = if (curlTeloptOk(opt_u))
                    curlTelopt(opt_u)
                else if (opt_u == CURL_TELOPT_EXOPL)
                    "EXOPL"
                else
                    null;

                if (opt_name) |oname| {
                    infof(data, "%s %s %s", .{ direction, fmt, oname });
                } else {
                    infof(data, "%s %s %d", .{ direction, fmt, option });
                }
            } else {
                infof(data, "%s %d %d", .{ direction, cmd, option });
            }
        }
    }
}

fn telnet_easy_dtor(key: ?*const anyopaque, klen: usize, entry: ?*anyopaque) callconv(.c) void {
    _ = key;
    _ = klen;
    if (entry) |ptr| {
        const tn: *TELNET = @ptrCast(@alignCast(ptr));
        curl_slist_free_all(tn.telnet_vars);
        containers.curlx_dyn_free(&tn.out);
        mem.freeSized(tn, @sizeOf(TELNET));
    }
}

fn init_telnet(data: *Curl_easy) CURLcode {
    const raw = mem.calloc(1, @sizeOf(TELNET)) orelse return CURLE_OUT_OF_MEMORY;
    const tn: *TELNET = @ptrCast(@alignCast(raw));

    containers.curlx_dyn_init(&tn.out, 0xffff);
    tn.telrcv_state = .CURL_TS_DATA;
    tn.sbClear();

    tn.us_preferred[CURL_TELOPT_SGA] = CURL_YES;
    tn.him_preferred[CURL_TELOPT_SGA] = CURL_YES;
    tn.us_preferred[CURL_TELOPT_BINARY] = CURL_YES;
    tn.him_preferred[CURL_TELOPT_BINARY] = CURL_YES;
    tn.him_preferred[CURL_TELOPT_ECHO] = CURL_YES;
    tn.subnegotiation[CURL_TELOPT_NAWS] = CURL_YES;

    return Curl_meta_set(data, CURL_META_TELNET_EASY, tn, telnet_easy_dtor);
}

fn send_negotiation(data: *Curl_easy, cmd: c_int, option: c_int) void {
    const buf: [3]u8 = .{
        CURL_IAC,
        @intCast(cmd & 0xff),
        @intCast(option & 0xff),
    };
    var nwritten: usize = 0;
    const result = Curl_xfer_send(data, &buf, 3, false, &nwritten);
    if (result != CURLE_OK) {
        failf(data, "Sending data failed: %s", .{curl_easy_strerror(result)});
    }
    printoption(data, "SENT", cmd, option);
}

fn set_remote_option(data: *Curl_easy, tn: *TELNET, option: usize, newstate: c_int) void {
    if (newstate == CURL_YES) {
        switch (tn.him[option]) {
            CURL_NO => {
                tn.him[option] = CURL_WANTYES;
                send_negotiation(data, CURL_DO, @intCast(option));
            },
            CURL_YES => {},
            CURL_WANTNO => {
                if (tn.himq[option] == CURL_EMPTY) {
                    tn.himq[option] = CURL_OPPOSITE;
                }
            },
            CURL_WANTYES => {
                if (tn.himq[option] == CURL_OPPOSITE) {
                    tn.himq[option] = CURL_EMPTY;
                }
            },
            else => {},
        }
    } else {
        switch (tn.him[option]) {
            CURL_NO => {},
            CURL_YES => {
                tn.him[option] = CURL_WANTNO;
                send_negotiation(data, CURL_DONT, @intCast(option));
            },
            CURL_WANTNO => {
                if (tn.himq[option] == CURL_OPPOSITE) {
                    tn.himq[option] = CURL_EMPTY;
                }
            },
            CURL_WANTYES => {
                if (tn.himq[option] == CURL_EMPTY) {
                    tn.himq[option] = CURL_OPPOSITE;
                }
            },
            else => {},
        }
    }
}

fn set_local_option(data: *Curl_easy, tn: *TELNET, option: usize, newstate: c_int) void {
    if (newstate == CURL_YES) {
        switch (tn.us[option]) {
            CURL_NO => {
                tn.us[option] = CURL_WANTYES;
                send_negotiation(data, CURL_WILL, @intCast(option));
            },
            CURL_YES => {},
            CURL_WANTNO => {
                if (tn.usq[option] == CURL_EMPTY) {
                    tn.usq[option] = CURL_OPPOSITE;
                }
            },
            CURL_WANTYES => {
                if (tn.usq[option] == CURL_OPPOSITE) {
                    tn.usq[option] = CURL_EMPTY;
                }
            },
            else => {},
        }
    } else {
        switch (tn.us[option]) {
            CURL_NO => {},
            CURL_YES => {
                tn.us[option] = CURL_WANTNO;
                send_negotiation(data, CURL_WONT, @intCast(option));
            },
            CURL_WANTNO => {
                if (tn.usq[option] == CURL_OPPOSITE) {
                    tn.usq[option] = CURL_EMPTY;
                }
            },
            CURL_WANTYES => {
                if (tn.usq[option] == CURL_EMPTY) {
                    tn.usq[option] = CURL_OPPOSITE;
                }
            },
            else => {},
        }
    }
}

fn telnet_negotiate(data: *Curl_easy, tn: *TELNET) void {
    for (0..CURL_NTELOPTS) |i| {
        if (i == CURL_TELOPT_ECHO) continue;
        if (tn.us_preferred[i] == CURL_YES) {
            set_local_option(data, tn, i, CURL_YES);
        }
        if (tn.him_preferred[i] == CURL_YES) {
            set_remote_option(data, tn, i, CURL_YES);
        }
    }
}

fn rec_will(data: *Curl_easy, tn: *TELNET, option: usize) void {
    switch (tn.him[option]) {
        CURL_NO => {
            if (tn.him_preferred[option] == CURL_YES) {
                tn.him[option] = CURL_YES;
                send_negotiation(data, CURL_DO, @intCast(option));
            } else {
                send_negotiation(data, CURL_DONT, @intCast(option));
            }
        },
        CURL_YES => {},
        CURL_WANTNO => {
            switch (tn.himq[option]) {
                CURL_EMPTY => tn.him[option] = CURL_NO,
                CURL_OPPOSITE => {
                    tn.him[option] = CURL_YES;
                    tn.himq[option] = CURL_EMPTY;
                },
                else => {},
            }
        },
        CURL_WANTYES => {
            switch (tn.himq[option]) {
                CURL_EMPTY => tn.him[option] = CURL_YES,
                CURL_OPPOSITE => {
                    tn.him[option] = CURL_WANTNO;
                    tn.himq[option] = CURL_EMPTY;
                    send_negotiation(data, CURL_DONT, @intCast(option));
                },
                else => {},
            }
        },
        else => {},
    }
}

fn rec_wont(data: *Curl_easy, tn: *TELNET, option: usize) void {
    switch (tn.him[option]) {
        CURL_NO => {},
        CURL_YES => {
            tn.him[option] = CURL_NO;
            send_negotiation(data, CURL_DONT, @intCast(option));
        },
        CURL_WANTNO => {
            switch (tn.himq[option]) {
                CURL_EMPTY => tn.him[option] = CURL_NO,
                CURL_OPPOSITE => {
                    tn.him[option] = CURL_WANTYES;
                    tn.himq[option] = CURL_EMPTY;
                    send_negotiation(data, CURL_DO, @intCast(option));
                },
                else => {},
            }
        },
        CURL_WANTYES => {
            switch (tn.himq[option]) {
                CURL_EMPTY => tn.him[option] = CURL_NO,
                CURL_OPPOSITE => {
                    tn.him[option] = CURL_NO;
                    tn.himq[option] = CURL_EMPTY;
                },
                else => {},
            }
        },
        else => {},
    }
}

fn printsub(data: *Curl_easy, direction: u8, pointer: [*]const u8, length_in: usize) void {
    if (!Curl_easy_get_verbose(data)) return;
    var sub_slice: []const u8 = pointer[0..length_in];

    if (direction != 0) {
        const dir_str: [*:0]const u8 = if (direction == '<') "RCVD" else "SENT";
        infof(data, "%s IAC SB ", .{dir_str});
        if (sub_slice.len >= 3) {
            const i: usize = sub_slice[sub_slice.len - 2];
            const j: usize = sub_slice[sub_slice.len - 1];
            if (i != CURL_IAC or j != CURL_SE) {
                infof(data, "(terminated by ", .{});
                if (curlTeloptOk(i)) {
                    infof(data, "%s ", .{curlTelopt(i)});
                } else if (curlTelcmdOk(i)) {
                    infof(data, "%s ", .{curlTelcmd(i)});
                } else {
                    infof(data, "%u ", .{@as(c_uint, @intCast(i))});
                }
                if (curlTeloptOk(j)) {
                    infof(data, "%s", .{curlTelopt(j)});
                } else if (curlTelcmdOk(j)) {
                    infof(data, "%s", .{curlTelcmd(j)});
                } else {
                    infof(data, "%d", .{@as(c_int, @intCast(j))});
                }
                infof(data, ", not IAC SE) ", .{});
            }
        }
        if (sub_slice.len >= 2) {
            sub_slice = sub_slice[0 .. sub_slice.len - 2];
        } else {
            return;
        }
    }
    if (sub_slice.len <= 1) {
        infof(data, "(Empty suboption?)", .{});
        return;
    }

    const p0: usize = sub_slice[0];
    if (curlTeloptOk(p0)) {
        switch (p0) {
            CURL_TELOPT_TTYPE, CURL_TELOPT_XDISPLOC, CURL_TELOPT_NEW_ENVIRON, CURL_TELOPT_NAWS => {
                infof(data, "%s", .{curlTelopt(p0)});
            },
            else => {
                infof(data, "%s (unsupported)", .{curlTelopt(p0)});
            },
        }
    } else {
        infof(data, "%d (unknown)", .{@as(c_int, @intCast(p0))});
    }

    switch (p0) {
        CURL_TELOPT_NAWS => {
            if (sub_slice.len > 4) {
                const w: c_int = (@as(c_int, sub_slice[1]) << 8) | @as(c_int, sub_slice[2]);
                const h: c_int = (@as(c_int, sub_slice[3]) << 8) | @as(c_int, sub_slice[4]);
                infof(data, "Width: %d ; Height: %d", .{ w, h });
            }
        },
        else => {
            switch (sub_slice[1]) {
                CURL_TELQUAL_IS => infof(data, " IS", .{}),
                CURL_TELQUAL_SEND => infof(data, " SEND", .{}),
                CURL_TELQUAL_INFO => infof(data, " INFO/REPLY", .{}),
                CURL_TELQUAL_NAME => infof(data, " NAME", .{}),
                else => {},
            }

            switch (p0) {
                CURL_TELOPT_TTYPE, CURL_TELOPT_XDISPLOC => {
                    const payload = if (sub_slice.len > 2) sub_slice[2..] else sub_slice[0..0];
                    const slen: c_int = std.math.cast(c_int, payload.len) orelse 0;
                    infof(data, " \"%.*s\"", .{ slen, payload.ptr });
                },
                CURL_TELOPT_NEW_ENVIRON => {
                    if (sub_slice[1] == CURL_TELQUAL_IS) {
                        infof(data, " ", .{});
                        if (sub_slice.len > 3) {
                            for (sub_slice[3..]) |ch| {
                                switch (ch) {
                                    CURL_NEW_ENV_VAR => infof(data, ", ", .{}),
                                    CURL_NEW_ENV_VALUE => infof(data, " = ", .{}),
                                    else => infof(data, "%c", .{@as(c_int, ch)}),
                                }
                            }
                        }
                    }
                },
                else => {
                    for (sub_slice[2..]) |ch| {
                        infof(data, " %.2x", .{@as(c_uint, ch)});
                    }
                },
            }
        },
    }
}

fn send_telnet_data(data: *Curl_easy, tn: *TELNET, buffer: [*]const u8, nread: isize) CURLcode {
    if (nread < 0) return CURLE_TOO_LARGE;
    const len: usize = @intCast(nread);
    const conn = Curl_easy_get_conn(data) orelse return CURLE_SEND_ERROR;

    var result: CURLcode = CURLE_OK;
    var outlen: usize = 0;
    var outbuf: [*]const u8 = buffer;

    if (std.mem.indexOfScalar(u8, buffer[0..len], CURL_IAC) != null) {
        containers.curlx_dyn_reset(&tn.out);
        var i: usize = 0;
        while (i < len and result == CURLE_OK) : (i += 1) {
            result = containers.curlx_dyn_addn(&tn.out, buffer + i, 1);
            if (result == CURLE_OK and buffer[i] == CURL_IAC) {
                const ff: [1]u8 = .{0xff};
                result = containers.curlx_dyn_addn(&tn.out, &ff, 1);
            }
        }
        outlen = containers.curlx_dyn_len(&tn.out);
        if (containers.curlx_dyn_uptr(&tn.out)) |uptr| {
            outbuf = uptr;
        }
    } else {
        outlen = len;
        outbuf = buffer;
    }

    var total_written: usize = 0;
    while (result == CURLE_OK and total_written < outlen) {
        var pfd: [1]headers_sock.Pollfd = .{.{
            .fd = Curl_conn_get_sock(conn, FIRSTSOCKET),
            .events = headers_sock.POLLOUT,
            .revents = 0,
        }};
        const timeout_ms = Curl_timeleft_ms(data);
        if (timeout_ms < 0) return CURLE_OPERATION_TIMEDOUT;

        const poll_res = headers_sock.Curl_poll(&pfd, 1, if (timeout_ms != 0) timeout_ms else -1);
        switch (poll_res) {
            -1 => result = CURLE_SEND_ERROR,
            0 => result = CURLE_OPERATION_TIMEDOUT,
            else => {
                var bytes_written: usize = 0;
                result = Curl_xfer_send(
                    data,
                    outbuf + total_written,
                    outlen - total_written,
                    false,
                    &bytes_written,
                );
                total_written += bytes_written;
            },
        }
    }

    return result;
}

fn sendsuboption(data: *Curl_easy, tn: *TELNET, option: usize) void {
    if (option == CURL_TELOPT_NAWS) {
        tn.sbClear();
        tn.sbAccum(CURL_IAC);
        tn.sbAccum(CURL_SB);
        tn.sbAccum(@intCast(CURL_TELOPT_NAWS));

        const x = std.mem.nativeToBig(u16, tn.subopt_wsx);
        const y = std.mem.nativeToBig(u16, tn.subopt_wsy);
        const uc1: *const [2]u8 = @ptrCast(&x);
        const uc2: *const [2]u8 = @ptrCast(&y);
        tn.sbAccum(uc1[0]);
        tn.sbAccum(uc1[1]);
        tn.sbAccum(uc2[0]);
        tn.sbAccum(uc2[1]);

        tn.sbAccum(CURL_IAC);
        tn.sbAccum(CURL_SE);
        tn.sbTerm();

        printsub(data, '>', @as([*]const u8, &tn.subbuffer) + 2, tn.sbLen() - 2);

        var nwritten: usize = 0;
        var result = Curl_xfer_send(data, &tn.subbuffer, 3, false, &nwritten);
        if (result != CURLE_OK) {
            failf(data, "Sending data failed: %s", .{curl_easy_strerror(result)});
        }

        _ = send_telnet_data(data, tn, @as([*]const u8, &tn.subbuffer) + 3, 4);

        result = Curl_xfer_send(data, @as([*]const u8, &tn.subbuffer) + 7, 2, false, &nwritten);
        if (result != CURLE_OK) {
            failf(data, "Sending data failed: %s", .{curl_easy_strerror(result)});
        }
    }
}

fn rec_do(data: *Curl_easy, tn: *TELNET, option: usize) void {
    switch (tn.us[option]) {
        CURL_NO => {
            if (tn.us_preferred[option] == CURL_YES) {
                tn.us[option] = CURL_YES;
                send_negotiation(data, CURL_WILL, @intCast(option));
                if (tn.subnegotiation[option] == CURL_YES) {
                    sendsuboption(data, tn, option);
                }
            } else if (tn.subnegotiation[option] == CURL_YES) {
                tn.us[option] = CURL_YES;
                send_negotiation(data, CURL_WILL, @intCast(option));
                sendsuboption(data, tn, option);
            } else {
                send_negotiation(data, CURL_WONT, @intCast(option));
            }
        },
        CURL_YES => {},
        CURL_WANTNO => {
            switch (tn.usq[option]) {
                CURL_EMPTY => tn.us[option] = CURL_NO,
                CURL_OPPOSITE => {
                    tn.us[option] = CURL_YES;
                    tn.usq[option] = CURL_EMPTY;
                },
                else => {},
            }
        },
        CURL_WANTYES => {
            switch (tn.usq[option]) {
                CURL_EMPTY => {
                    tn.us[option] = CURL_YES;
                    if (tn.subnegotiation[option] == CURL_YES) {
                        sendsuboption(data, tn, option);
                    }
                },
                CURL_OPPOSITE => {
                    tn.us[option] = CURL_WANTNO;
                    tn.usq[option] = CURL_EMPTY;
                    send_negotiation(data, CURL_WONT, @intCast(option));
                },
                else => {},
            }
        },
        else => {},
    }
}

fn rec_dont(data: *Curl_easy, tn: *TELNET, option: usize) void {
    switch (tn.us[option]) {
        CURL_NO => {},
        CURL_YES => {
            tn.us[option] = CURL_NO;
            send_negotiation(data, CURL_WONT, @intCast(option));
        },
        CURL_WANTNO => {
            switch (tn.usq[option]) {
                CURL_EMPTY => tn.us[option] = CURL_NO,
                CURL_OPPOSITE => {
                    tn.us[option] = CURL_WANTYES;
                    tn.usq[option] = CURL_EMPTY;
                    send_negotiation(data, CURL_WILL, @intCast(option));
                },
                else => {},
            }
        },
        CURL_WANTYES => {
            switch (tn.usq[option]) {
                CURL_EMPTY => tn.us[option] = CURL_NO,
                CURL_OPPOSITE => {
                    tn.us[option] = CURL_NO;
                    tn.usq[option] = CURL_EMPTY;
                },
                else => {},
            }
        },
        else => {},
    }
}

fn str_is_nonascii(str: [*:0]const u8) bool {
    var p = str;
    while (p[0] != 0) : (p += 1) {
        if ((p[0] & 0x80) != 0) return true;
    }
    return false;
}

fn check_telnet_options(data: *Curl_easy, tn: *TELNET) CURLcode {
    var result: CURLcode = CURLE_OK;

    if (Curl_telnet_has_creds(data)) {
        var buffer: [256]u8 = undefined;
        const user = Curl_telnet_creds_user(data);
        if (str_is_nonascii(user)) {
            return CURLE_BAD_FUNCTION_ARGUMENT;
        }
        _ = curl_msnprintf(&buffer, buffer.len, "USER,%s", user);
        const beg = curl_slist_append(tn.telnet_vars, @ptrCast(&buffer)) orelse {
            curl_slist_free_all(tn.telnet_vars);
            tn.telnet_vars = null;
            return CURLE_OUT_OF_MEMORY;
        };
        tn.telnet_vars = beg;
        tn.us_preferred[CURL_TELOPT_NEW_ENVIRON] = CURL_YES;
    }

    var head = Curl_telnet_get_options(data);
    while (head != null and result == CURLE_OK) : (head = head.?.next) {
        const option = head.?.data orelse continue;
        const opt_slice = std.mem.span(option);
        if (std.mem.indexOfScalar(u8, opt_slice, '=')) |eq_idx| {
            const olen = eq_idx;
            const arg: [*:0]const u8 = option + eq_idx + 1;
            if (str_is_nonascii(arg)) continue;

            switch (olen) {
                5 => {
                    if (primitives.curl_strnequal(option, "TTYPE", 5) != 0) {
                        tn.subopt_ttype = arg;
                        tn.us_preferred[CURL_TELOPT_TTYPE] = CURL_YES;
                    } else {
                        result = CURLE_UNKNOWN_OPTION;
                    }
                },
                8 => {
                    if (primitives.curl_strnequal(option, "XDISPLOC", 8) != 0) {
                        tn.subopt_xdisploc = arg;
                        tn.us_preferred[CURL_TELOPT_XDISPLOC] = CURL_YES;
                    } else {
                        result = CURLE_UNKNOWN_OPTION;
                    }
                },
                7 => {
                    if (primitives.curl_strnequal(option, "NEW_ENV", 7) != 0) {
                        const beg = curl_slist_append(tn.telnet_vars, arg) orelse {
                            result = CURLE_OUT_OF_MEMORY;
                            break;
                        };
                        tn.telnet_vars = beg;
                        tn.us_preferred[CURL_TELOPT_NEW_ENVIRON] = CURL_YES;
                    } else {
                        result = CURLE_UNKNOWN_OPTION;
                    }
                },
                2 => {
                    if (primitives.curl_strnequal(option, "WS", 2) != 0) {
                        var p: ?[*:0]const u8 = arg;
                        var x: i64 = 0;
                        var y: i64 = 0;
                        if (curlx_parse.curlx_str_number(&p, &x, 0xffff) != 0 or
                            curlx_parse.curlx_str_single(&p, 'x') != 0 or
                            curlx_parse.curlx_str_number(&p, &y, 0xffff) != 0)
                        {
                            failf(data, "Syntax error in telnet option: %s", .{option});
                            result = CURLE_SETOPT_OPTION_SYNTAX;
                        } else {
                            tn.subopt_wsx = @intCast(x);
                            tn.subopt_wsy = @intCast(y);
                            tn.us_preferred[CURL_TELOPT_NAWS] = CURL_YES;
                        }
                    } else {
                        result = CURLE_UNKNOWN_OPTION;
                    }
                },
                6 => {
                    if (primitives.curl_strnequal(option, "BINARY", 6) != 0) {
                        var p: ?[*:0]const u8 = arg;
                        var binary_option: i64 = 0;
                        if (curlx_parse.curlx_str_number(&p, &binary_option, 1) == 0 and binary_option != 1) {
                            tn.us_preferred[CURL_TELOPT_BINARY] = CURL_NO;
                            tn.him_preferred[CURL_TELOPT_BINARY] = CURL_NO;
                        }
                    } else {
                        result = CURLE_UNKNOWN_OPTION;
                    }
                },
                else => {
                    failf(data, "Unknown telnet option %s", .{option});
                    result = CURLE_UNKNOWN_OPTION;
                },
            }
        } else {
            failf(data, "Syntax error in telnet option: %s", .{option});
            result = CURLE_SETOPT_OPTION_SYNTAX;
        }
    }

    if (result != CURLE_OK) {
        curl_slist_free_all(tn.telnet_vars);
        tn.telnet_vars = null;
    }

    return result;
}

fn bad_option(opt_data: ?[*:0]const u8) bool {
    const d = opt_data orelse return true;
    return std.mem.indexOfScalar(u8, std.mem.span(d), CURL_IAC) != null;
}

fn suboption(data: *Curl_easy, tn: *TELNET) CURLcode {
    var temp: [2048]u8 = undefined;
    var nwritten: usize = 0;

    if (tn.sbLen() == 0) return CURLE_OK;

    const sub_print_len = @min(tn.sbLen() + 2, tn.subbuffer.len);
    const sub_print_slice = tn.subbuffer[0..sub_print_len];
    printsub(data, '<', sub_print_slice.ptr, sub_print_slice.len);
    switch (@as(usize, tn.sbGet())) {
        CURL_TELOPT_TTYPE => {
            if (bad_option(tn.subopt_ttype)) return CURLE_BAD_FUNCTION_ARGUMENT;
            const ttype = tn.subopt_ttype.?;
            if (std.mem.len(ttype) > 1000) {
                failf(data, "Too long telnet TTYPE", .{});
                return CURLE_SEND_ERROR;
            }
            const len_c = curl_msnprintf(
                &temp,
                temp.len,
                "%c%c%c%c%s%c%c",
                @as(c_int, CURL_IAC),
                @as(c_int, CURL_SB),
                @as(c_int, CURL_TELOPT_TTYPE),
                @as(c_int, CURL_TELQUAL_IS),
                ttype,
                @as(c_int, CURL_IAC),
                @as(c_int, CURL_SE),
            );
            const len: usize = @intCast(@max(0, len_c));
            const result = Curl_xfer_send(data, &temp, len, false, &nwritten);
            if (result != CURLE_OK) {
                failf(data, "Sending data failed: %s", .{curl_easy_strerror(result)});
                return result;
            }
            printsub(data, '>', @as([*]const u8, &temp) + 2, len - 2);
        },
        CURL_TELOPT_XDISPLOC => {
            if (bad_option(tn.subopt_xdisploc)) return CURLE_BAD_FUNCTION_ARGUMENT;
            const xdisp = tn.subopt_xdisploc.?;
            if (std.mem.len(xdisp) > 1000) {
                failf(data, "Too long telnet XDISPLOC", .{});
                return CURLE_SEND_ERROR;
            }
            const len_c = curl_msnprintf(
                &temp,
                temp.len,
                "%c%c%c%c%s%c%c",
                @as(c_int, CURL_IAC),
                @as(c_int, CURL_SB),
                @as(c_int, CURL_TELOPT_XDISPLOC),
                @as(c_int, CURL_TELQUAL_IS),
                xdisp,
                @as(c_int, CURL_IAC),
                @as(c_int, CURL_SE),
            );
            const len: usize = @intCast(@max(0, len_c));
            const result = Curl_xfer_send(data, &temp, len, false, &nwritten);
            if (result != CURLE_OK) {
                failf(data, "Sending data failed: %s", .{curl_easy_strerror(result)});
                return result;
            }
            printsub(data, '>', @as([*]const u8, &temp) + 2, len - 2);
        },
        CURL_TELOPT_NEW_ENVIRON => {
            const len_init = curl_msnprintf(
                &temp,
                temp.len,
                "%c%c%c%c",
                @as(c_int, CURL_IAC),
                @as(c_int, CURL_SB),
                @as(c_int, CURL_TELOPT_NEW_ENVIRON),
                @as(c_int, CURL_TELQUAL_IS),
            );
            var len: usize = @intCast(@max(0, len_init));
            var v = tn.telnet_vars;
            while (v) |node| : (v = node.next) {
                if (bad_option(node.data)) return CURLE_BAD_FUNCTION_ARGUMENT;
                const vdata = node.data.?;
                const vslice = std.mem.span(vdata);
                const tmplen = vslice.len + 1;
                if (len + tmplen < temp.len - 6) {
                    if (std.mem.indexOfScalar(u8, vslice, ',')) |comma_idx| {
                        const add_c = curl_msnprintf(
                            @as([*]u8, &temp) + len,
                            temp.len - len,
                            "%c%.*s%c%s",
                            @as(c_int, CURL_NEW_ENV_VAR),
                            @as(c_int, @intCast(comma_idx)),
                            vdata,
                            @as(c_int, CURL_NEW_ENV_VALUE),
                            vdata + comma_idx + 1,
                        );
                        len += @intCast(@max(0, add_c));
                    } else {
                        const add_c = curl_msnprintf(
                            @as([*]u8, &temp) + len,
                            temp.len - len,
                            "%c%s",
                            @as(c_int, CURL_NEW_ENV_VAR),
                            vdata,
                        );
                        len += @intCast(@max(0, add_c));
                    }
                }
            }
            _ = curl_msnprintf(
                @as([*]u8, &temp) + len,
                temp.len - len,
                "%c%c",
                @as(c_int, CURL_IAC),
                @as(c_int, CURL_SE),
            );
            len += 2;
            const result = Curl_xfer_send(data, &temp, len, false, &nwritten);
            if (result != CURLE_OK) {
                failf(data, "Sending data failed: %s", .{curl_easy_strerror(result)});
                return result;
            }
            printsub(data, '>', @as([*]const u8, &temp) + 2, len - 2);
        },
        else => {},
    }
    return CURLE_OK;
}

fn telrcv(data: *Curl_easy, tn: *TELNET, inbuf: [*]const u8, count_in: usize) CURLcode {
    var in_idx: usize = 0;
    var startwrite: isize = -1;

    while (in_idx < count_in) : (in_idx += 1) {
        const c = inbuf[in_idx];

        switch (tn.telrcv_state) {
            .CURL_TS_CR => {
                tn.telrcv_state = .CURL_TS_DATA;
                if (c == 0) {
                    if (startwrite >= 0) {
                        const sw: usize = @intCast(startwrite);
                        const result = Curl_client_write(data, CLIENTWRITE_BODY, inbuf + sw, in_idx - sw);
                        if (result != CURLE_OK) return result;
                    }
                    startwrite = -1;
                    continue;
                }
                if (startwrite < 0) startwrite = @intCast(in_idx);
            },
            .CURL_TS_DATA => {
                if (c == CURL_IAC) {
                    tn.telrcv_state = .CURL_TS_IAC;
                    if (startwrite >= 0) {
                        const sw: usize = @intCast(startwrite);
                        const result = Curl_client_write(data, CLIENTWRITE_BODY, inbuf + sw, in_idx - sw);
                        if (result != CURLE_OK) return result;
                    }
                    startwrite = -1;
                    continue;
                } else if (c == '\r') {
                    tn.telrcv_state = .CURL_TS_CR;
                }
                if (startwrite < 0) startwrite = @intCast(in_idx);
            },
            .CURL_TS_IAC => {
                switch (c) {
                    CURL_WILL => tn.telrcv_state = .CURL_TS_WILL,
                    CURL_WONT => tn.telrcv_state = .CURL_TS_WONT,
                    CURL_DO => tn.telrcv_state = .CURL_TS_DO,
                    CURL_DONT => tn.telrcv_state = .CURL_TS_DONT,
                    CURL_SB => {
                        tn.sbClear();
                        tn.telrcv_state = .CURL_TS_SB;
                    },
                    CURL_IAC => {
                        tn.telrcv_state = .CURL_TS_DATA;
                        if (startwrite < 0) startwrite = @intCast(in_idx);
                    },
                    else => {
                        tn.telrcv_state = .CURL_TS_DATA;
                        printoption(data, "RCVD", CURL_IAC, c);
                    },
                }
            },
            .CURL_TS_WILL => {
                printoption(data, "RCVD", CURL_WILL, c);
                tn.please_negotiate = 1;
                rec_will(data, tn, c);
                tn.telrcv_state = .CURL_TS_DATA;
            },
            .CURL_TS_WONT => {
                printoption(data, "RCVD", CURL_WONT, c);
                tn.please_negotiate = 1;
                rec_wont(data, tn, c);
                tn.telrcv_state = .CURL_TS_DATA;
            },
            .CURL_TS_DO => {
                printoption(data, "RCVD", CURL_DO, c);
                tn.please_negotiate = 1;
                rec_do(data, tn, c);
                tn.telrcv_state = .CURL_TS_DATA;
            },
            .CURL_TS_DONT => {
                printoption(data, "RCVD", CURL_DONT, c);
                tn.please_negotiate = 1;
                rec_dont(data, tn, c);
                tn.telrcv_state = .CURL_TS_DATA;
            },
            .CURL_TS_SB => {
                if (c == CURL_IAC) {
                    tn.telrcv_state = .CURL_TS_SE;
                } else {
                    tn.sbAccum(c);
                }
            },
            .CURL_TS_SE => {
                if (c != CURL_SE) {
                    if (c != CURL_IAC) {
                        failf(data, "telnet: suboption error", .{});
                        return CURLE_RECV_ERROR;
                    }
                    tn.sbAccum(c);
                    tn.telrcv_state = .CURL_TS_SB;
                } else {
                    if (tn.subpointer > tn.subbuffer.len - 2) {
                        tn.subpointer = tn.subbuffer.len - 2;
                    }
                    tn.sbAccum(CURL_IAC);
                    tn.sbAccum(CURL_SE);
                    tn.subpointer -= 2;
                    tn.sbTerm();
                    const result = suboption(data, tn);
                    if (result != CURLE_OK) return result;
                    tn.telrcv_state = .CURL_TS_DATA;
                }
            },
        }
    }

    if (startwrite >= 0) {
        const sw: usize = @intCast(startwrite);
        const result = Curl_client_write(data, CLIENTWRITE_BODY, inbuf + sw, in_idx - sw);
        if (result != CURLE_OK) return result;
    }
    return CURLE_OK;
}

fn telnet_done(data: *Curl_easy, status: CURLcode, premature: bool) callconv(.c) CURLcode {
    _ = status;
    _ = premature;
    Curl_meta_remove(data, CURL_META_TELNET_EASY);
    return CURLE_OK;
}

const WSANETWORKEVENTS = extern struct {
    lNetworkEvents: c_long = 0,
    iErrorCode: [10]c_int = @splat(0),
};

fn telnet_do(data: *Curl_easy, done: *bool) callconv(.c) CURLcode {
    const conn = Curl_easy_get_conn(data) orelse {
        done.* = true;
        return CURLE_FAILED_INIT;
    };
    const sockfd = Curl_conn_get_sock(conn, FIRSTSOCKET);
    var keepon = true;
    var buffer: [4 * 1024]u8 = undefined;

    done.* = true;

    var result = init_telnet(data);
    if (result != CURLE_OK) return result;

    const tn_raw = Curl_meta_get(data, CURL_META_TELNET_EASY) orelse return CURLE_FAILED_INIT;
    const tn: *TELNET = @ptrCast(@alignCast(tn_raw));

    result = check_telnet_options(data, tn);
    if (result != CURLE_OK) return result;

    if (is_windows) {
        const FD_READ: c_long = 1 << 0;
        const FD_CLOSE: c_long = 1 << 5;
        const STD_INPUT_HANDLE: u32 = @bitCast(@as(i32, -10));
        const FILE_TYPE_PIPE: u32 = 0x0003;
        const WAIT_OBJECT_0: u32 = 0;
        const WAIT_TIMEOUT: u32 = 258;
        const SOCKEINPROGRESS: c_int = 10036;

        const event_handle = win_ws2.WSACreateEvent() orelse {
            failf(data, "WSACreateEvent failed (%d)", .{lastSocketError()});
            return CURLE_FAILED_INIT;
        };

        if (win_ws2.WSAEventSelect(sockfd, event_handle, FD_READ | FD_CLOSE) != 0) {
            _ = win_ws2.WSACloseEvent(event_handle);
            return CURLE_RECV_ERROR;
        }

        const stdin_handle = win_kernel32.GetStdHandle(STD_INPUT_HANDLE);
        var objs: [2]?*anyopaque = .{ event_handle, stdin_handle };
        var obj_count: u32 = 2;
        var wait_timeout: u32 = 1000;

        if (win_kernel32.GetFileType(stdin_handle) == FILE_TYPE_PIPE or Curl_telnet_is_fread_set(data)) {
            obj_count = 1;
            wait_timeout = 100;
        }

        while (keepon) {
            const buf_size: u32 = @intCast(buffer.len);
            const waitret = win_kernel32.WaitForMultipleObjects(obj_count, &objs, 0, wait_timeout);
            switch (waitret) {
                WAIT_TIMEOUT => {
                    while (true) {
                        var readfile_read: u32 = 0;
                        if (Curl_telnet_is_fread_set(data)) {
                            const n = Curl_telnet_invoke_fread(data, &buffer, buf_size);
                            if (n == CURL_READFUNC_ABORT) {
                                keepon = false;
                                result = CURLE_READ_ERROR;
                                break;
                            }
                            if (n == CURL_READFUNC_PAUSE or n == 0) break;
                            readfile_read = @intCast(n);
                        } else {
                            if (win_kernel32.PeekNamedPipe(stdin_handle, null, 0, null, &readfile_read, null) == 0) {
                                keepon = false;
                                result = CURLE_READ_ERROR;
                                break;
                            }
                            if (readfile_read == 0) break;
                            if (win_kernel32.ReadFile(stdin_handle, &buffer, buf_size, &readfile_read, null) == 0) {
                                keepon = false;
                                result = CURLE_READ_ERROR;
                                break;
                            }
                        }

                        result = send_telnet_data(data, tn, &buffer, @intCast(readfile_read));
                        if (result != CURLE_OK) {
                            keepon = false;
                            break;
                        }
                    }
                },
                WAIT_OBJECT_0 + 1 => {
                    var readfile_read: u32 = 0;
                    if (win_kernel32.ReadFile(stdin_handle, &buffer, buf_size, &readfile_read, null) == 0) {
                        keepon = false;
                        result = CURLE_READ_ERROR;
                    } else {
                        result = send_telnet_data(data, tn, &buffer, @intCast(readfile_read));
                        if (result != CURLE_OK) keepon = false;
                    }
                },
                WAIT_OBJECT_0 => {
                    var events: WSANETWORKEVENTS = .{};
                    if (win_ws2.WSAEnumNetworkEvents(sockfd, event_handle, &events) != 0) {
                        const sockerr = lastSocketError();
                        if (sockerr != SOCKEINPROGRESS) {
                            infof(data, "WSAEnumNetworkEvents failed (%d)", .{sockerr});
                            keepon = false;
                            result = CURLE_READ_ERROR;
                        }
                    } else {
                        if ((events.lNetworkEvents & FD_READ) != 0) {
                            var nread: usize = 0;
                            result = Curl_xfer_recv(data, &buffer, buffer.len, &nread);
                            if (result == CURLE_AGAIN) {
                                // would block
                            } else if (result != CURLE_OK) {
                                keepon = false;
                            } else if (nread == 0) {
                                keepon = false;
                            } else {
                                result = telrcv(data, tn, &buffer, nread);
                                if (result != CURLE_OK) {
                                    keepon = false;
                                } else if (tn.please_negotiate != 0 and tn.already_negotiated == 0) {
                                    telnet_negotiate(data, tn);
                                    tn.already_negotiated = 1;
                                }
                            }
                        }
                        if ((events.lNetworkEvents & FD_CLOSE) != 0) {
                            keepon = false;
                        }
                    }
                },
                else => {},
            }

            if (Curl_timeleft_ms(data) < 0) {
                failf(data, "Time-out", .{});
                result = CURLE_OPERATION_TIMEDOUT;
                keepon = false;
            }
        }

        if (win_ws2.WSACloseEvent(event_handle) == 0) {
            infof(data, "WSACloseEvent failed (%d)", .{lastSocketError()});
        }
    } else {
        var pfd: [2]headers_sock.Pollfd = .{
            .{ .fd = sockfd, .events = headers_sock.POLLIN, .revents = 0 },
            .{ .fd = -1, .events = 0, .revents = 0 },
        };
        var poll_cnt: c_uint = 1;
        var interval_ms: timediff_t = 100;

        if (!Curl_telnet_is_fread_set(data)) {
            pfd[1].fd = Curl_telnet_get_in_fd(data);
            pfd[1].events = headers_sock.POLLIN;
            poll_cnt = 2;
            interval_ms = 1000;
            if (pfd[1].fd < 0) {
                failf(data, "cannot read input", .{});
                result = CURLE_RECV_ERROR;
                keepon = false;
            }
        }

        while (keepon) {
            const poll_rc = headers_sock.Curl_poll(&pfd, poll_cnt, interval_ms);
            if (poll_rc == -1) {
                keepon = false;
                continue;
            }
            if (poll_rc == 0) {
                pfd[0].revents = 0;
                pfd[1].revents = 0;
            }

            fetch_block: {
                if ((pfd[0].revents & headers_sock.POLLIN) != 0) {
                    var nread: usize = 0;
                    result = Curl_xfer_recv(data, &buffer, buffer.len, &nread);
                    if (result == CURLE_AGAIN) {
                        break :fetch_block;
                    }
                    if (result != CURLE_OK) {
                        keepon = false;
                        break :fetch_block;
                    } else if (nread == 0) {
                        keepon = false;
                        break :fetch_block;
                    }

                    Curl_pgrs_download_inc(data, nread);
                    result = telrcv(data, tn, &buffer, nread);
                    if (result != CURLE_OK) {
                        keepon = false;
                        break :fetch_block;
                    }

                    if (tn.please_negotiate != 0 and tn.already_negotiated == 0) {
                        telnet_negotiate(data, tn);
                        tn.already_negotiated = 1;
                    }
                }

                var snread: isize = 0;
                if (poll_cnt == 2) {
                    if ((pfd[1].revents & headers_sock.POLLIN) != 0) {
                        snread = posix_c.read(pfd[1].fd, &buffer, buffer.len);
                    }
                } else {
                    const n_fread = Curl_telnet_invoke_fread(data, &buffer, buffer.len);
                    if (n_fread == CURL_READFUNC_ABORT) {
                        keepon = false;
                        break :fetch_block;
                    }
                    if (n_fread == CURL_READFUNC_PAUSE) {
                        break :fetch_block;
                    }
                    snread = @intCast(@as(c_int, @truncate(@as(isize, @bitCast(n_fread)))));
                }

                if (snread > 0) {
                    result = send_telnet_data(data, tn, &buffer, snread);
                    if (result != CURLE_OK) {
                        keepon = false;
                        break :fetch_block;
                    }
                    Curl_pgrs_upload_inc(data, @intCast(snread));
                } else if (snread < 0) {
                    keepon = false;
                }
            }

            if (Curl_timeleft_ms(data) < 0) {
                failf(data, "Time-out", .{});
                result = CURLE_OPERATION_TIMEDOUT;
                keepon = false;
            }

            if (result == CURLE_OK) {
                result = Curl_pgrsUpdate(data);
                if (result != CURLE_OK) {
                    keepon = false;
                }
            }
        }
    }

    Curl_xfer_setup_nop(data);
    return result;
}

pub export const Curl_protocol_telnet: CurlProtocol = .{
    .setup_connection = null,
    .do_it = telnet_do,
    .done = telnet_done,
    .do_more = null,
    .connect_it = null,
    .connecting = null,
    .doing = null,
    .proto_pollset = null,
    .doing_pollset = null,
    .domore_pollset = null,
    .perform_pollset = null,
    .disconnect = null,
    .write_resp = null,
    .write_resp_hd = null,
    .connection_is_dead = null,
    .attach = null,
    .follow = null,
};

// ============================================================================
// Unit Tests
// ============================================================================

test "TFTP packet helpers and error code translation" {
    var raw: [8]u8 = @splat(0);
    var pkt: TftpPacket = .{ .data = &raw };

    setpacketevent(&pkt, @intCast(@backingInt(TftpEvent.TFTP_EVENT_DATA)));
    setpacketblock(&pkt, 0x1234);

    try std.testing.expectEqual(@as(u16, 3), getrpacketevent(&pkt));
    try std.testing.expectEqual(@as(u16, 0x1234), getrpacketblock(&pkt));
    try std.testing.expectEqual(@as(u16, 0), nextBlocknum(0xffff));

    try std.testing.expectEqual(CURLE_OK, tftp_translate_code(.TFTP_ERR_NONE));
    try std.testing.expectEqual(CURLE_TFTP_NOTFOUND, tftp_translate_code(.TFTP_ERR_NOTFOUND));
    try std.testing.expectEqual(CURLE_TFTP_PERM, tftp_translate_code(.TFTP_ERR_PERM));
    try std.testing.expectEqual(CURLE_REMOTE_DISK_FULL, tftp_translate_code(.TFTP_ERR_DISKFULL));
    try std.testing.expectEqual(CURLE_TFTP_ILLEGAL, tftp_translate_code(.TFTP_ERR_ILLEGAL));
    try std.testing.expectEqual(CURLE_TFTP_UNKNOWNID, tftp_translate_code(.TFTP_ERR_UNKNOWNID));
    try std.testing.expectEqual(CURLE_REMOTE_FILE_EXISTS, tftp_translate_code(.TFTP_ERR_EXISTS));
    try std.testing.expectEqual(CURLE_TFTP_NOSUCHUSER, tftp_translate_code(.TFTP_ERR_NOSUCHUSER));
    try std.testing.expectEqual(CURLE_OPERATION_TIMEDOUT, tftp_translate_code(.TFTP_ERR_TIMEOUT));
    try std.testing.expectEqual(CURLE_COULDNT_CONNECT, tftp_translate_code(.TFTP_ERR_NORESPONSE));
}

test "TFTP option parsing helper" {
    const buf = "blksize\x001428\x00tsize\x004096\x00";
    var opt: ?[*:0]const u8 = null;
    var val: ?[*:0]const u8 = null;

    const next1 = tftp_option_get(buf.ptr, buf.len, &opt, &val);
    try std.testing.expect(next1 != null);
    try std.testing.expectEqualStrings("blksize", std.mem.span(opt.?));
    try std.testing.expectEqualStrings("1428", std.mem.span(val.?));

    const rem = (@intFromPtr(buf.ptr) + buf.len) - @intFromPtr(next1.?);
    const next2 = tftp_option_get(next1.?, rem, &opt, &val);
    try std.testing.expect(next2 != null);
    try std.testing.expectEqualStrings("tsize", std.mem.span(opt.?));
    try std.testing.expectEqualStrings("4096", std.mem.span(val.?));
}

test "TELNET subbuffer helpers and option validation" {
    var tn: TELNET = std.mem.zeroes(TELNET);
    tn.sbClear();
    tn.sbAccum(CURL_TELOPT_NAWS);
    tn.sbAccum(0x00);
    tn.sbAccum(0x50);
    tn.sbTerm();

    try std.testing.expectEqual(@as(usize, 3), tn.sbLen());
    try std.testing.expectEqual(@as(u8, CURL_TELOPT_NAWS), tn.sbGet());
    try std.testing.expectEqual(@as(usize, 2), tn.sbLen());

    try std.testing.expect(!str_is_nonascii("alice"));
    try std.testing.expect(str_is_nonascii("al\x80ce"));
    try std.testing.expect(bad_option(null));
    try std.testing.expect(!bad_option("vt100"));
    try std.testing.expect(bad_option("vt\xff100"));
}

test "tftp_parse_option_ack rejects unterminated OACK buffers without OOB read" {
    var state: TftpConn = undefined;
    @memset(std.mem.asBytes(&state), 0);
    state.requested_blksize = 1428;

    // Valid NUL-terminated OACK packet
    const valid_oack = "blksize\x001024\x00";
    try std.testing.expectEqual(
        CURLE_OK,
        tftp_parse_option_ack(&state, valid_oack.ptr, @intCast(valid_oack.len)),
    );
    try std.testing.expectEqual(@as(u32, 1024), state.blksize);

    // Unterminated OACK buffer (no '\0' byte within len)
    const no_nul = [_]u8{ 'b', 'l', 'k', 's', 'i', 'z', 'e' };
    try std.testing.expectEqual(
        CURLE_TFTP_ILLEGAL,
        tftp_parse_option_ack(&state, &no_nul, @intCast(no_nul.len)),
    );

    // Key terminated with '\0', but value lacks trailing '\0' within len
    const unterminated_val = [_]u8{ 'b', 'l', 'k', 's', 'i', 'z', 'e', 0, '5', '1', '2' };
    try std.testing.expectEqual(
        CURLE_TFTP_ILLEGAL,
        tftp_parse_option_ack(&state, &unterminated_val, @intCast(unterminated_val.len)),
    );

    // Negative length rejected cleanly
    try std.testing.expectEqual(
        CURLE_TFTP_ILLEGAL,
        tftp_parse_option_ack(&state, &no_nul, -1),
    );
}

test "Protocol and cfilter vtable exports" {
    try std.testing.expect(Curl_protocol_tftp.do_it != null);
    try std.testing.expect(Curl_protocol_tftp.connect_it != null);
    try std.testing.expect(Curl_protocol_telnet.do_it != null);
    try std.testing.expect(Curl_protocol_telnet.done != null);
    try std.testing.expectEqualStrings("SOCKS", std.mem.span(Curl_cft_socks_proxy.name));
    try std.testing.expectEqual(CF_TYPE_IP_CONNECT | CF_TYPE_PROXY, Curl_cft_socks_proxy.flags);
}
