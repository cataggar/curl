const std = @import("std");
const builtin = @import("builtin");
const mem = @import("mem.zig");
const headers_sock = @import("headers_sock.zig");
const cfilters_progress = @import("cfilters_progress.zig");

const CURLcode = c_uint;
const CURLE_OK: CURLcode = 0;
const CURLE_UNSUPPORTED_PROTOCOL: CURLcode = 1;
const CURLE_FAILED_INIT: CURLcode = 2;
const CURLE_URL_MALFORMAT: CURLcode = 3;
const CURLE_COULDNT_CONNECT: CURLcode = 7;
const CURLE_FTP_ACCEPT_FAILED: CURLcode = 10;
const CURLE_FTP_ACCEPT_TIMEOUT: CURLcode = 12;
const CURLE_PARTIAL_FILE: CURLcode = 18;
const CURLE_WRITE_ERROR: CURLcode = 23;
const CURLE_OUT_OF_MEMORY: CURLcode = 27;
const CURLE_OPERATION_TIMEDOUT: CURLcode = 28;
const CURLE_ABORTED_BY_CALLBACK: CURLcode = 42;
const CURLE_BAD_FUNCTION_ARGUMENT: CURLcode = 43;
const CURLE_INTERFACE_FAILED: CURLcode = 45;
const CURLE_UNKNOWN_OPTION: CURLcode = 48;
const CURLE_SEND_ERROR: CURLcode = 55;
const CURLE_RECV_ERROR: CURLcode = 56;
const CURLE_AGAIN: CURLcode = 81;
const CURLE_TOO_LARGE: CURLcode = 100;

const curl_socket_t = headers_sock.curl_socket_t;
const CURL_SOCKET_BAD = headers_sock.CURL_SOCKET_BAD;
const curl_socklen_t = c_uint;
const timediff_t = i64;
const curl_off_t = i64;
const time_t = i64;

const CurlEasy = cfilters_progress.CurlEasy;
const ConnectData = cfilters_progress.ConnectData;
const CurlTime = headers_sock.Curltime;
const CurlRlimit = headers_sock.CurlRlimit;
const EasyPollset = headers_sock.EasyPollset;
const CurlCfilter = cfilters_progress.CurlCfilter;
const CurlCftype = cfilters_progress.CurlCftype;
const CurlPeer = opaque {};
const SingleRequest = opaque {};

pub const CurlSlist = extern struct {
    data: ?[*:0]u8,
    next: ?*CurlSlist,
};

pub const MAX_IPADR_LEN: usize = 46;
const STRERROR_LEN: usize = 256;

const FIRSTSOCKET: i8 = 0;
const SECONDARYSOCKET: i8 = 1;

const TRNSPRT_TCP: u8 = 3;
const TRNSPRT_UDP: u8 = 4;
const TRNSPRT_QUIC: u8 = 5;
const TRNSPRT_UNIX: u8 = 6;

const AF_UNIX: c_int = 1;
const AF_INET: c_int = 2;
const AF_INET6: c_int = switch (builtin.os.tag) {
    .windows => 23,
    .macos, .ios, .tvos, .watchos, .visionos => 30,
    else => 10,
};

const CF_TYPE_IP_CONNECT: c_uint = 1 << 0;
const CURL_LOG_LVL_NONE: c_int = 0;

const CF_CTRL_DATA_SETUP: c_int = 4;
const CF_CTRL_CONN_INFO_UPDATE: c_int = 256;
const CF_CTRL_FORGET_SOCKET: c_int = 257;
const CF_CTRL_REPORT_STATS: c_int = 259;

const CF_QUERY_CONNECT_REPLY_MS: c_int = 2;
const CF_QUERY_SOCKET: c_int = 3;
const CF_QUERY_IP_INFO: c_int = 8;
const CF_QUERY_REMOTE_ADDR: c_int = 10;
const CF_QUERY_TRANSPORT: c_int = 14;
const CF_QUERY_REALLY_CONNECTED: c_int = 16;

const TIMER_STARTSINGLE: c_uint = 2;
const TIMER_CONNECT: c_uint = 5;

const CLIENTWRITE_BODY: c_int = 1 << 0;
const CLIENTWRITE_EOS: c_int = 1 << 7;

const CURL_TIMECOND_IFMODSINCE: u8 = 1;
const CURL_TIMECOND_IFUNMODSINCE: u8 = 2;

const CURLPROTO_FTP: u32 = 1 << 2;
const CURLPROTO_FTPS: u32 = 1 << 3;
const PROTO_FAMILY_FTP: u32 = CURLPROTO_FTP | CURLPROTO_FTPS;
const CURLPROTO_SCP: u32 = 1 << 4;
const CURLPROTO_SFTP: u32 = 1 << 5;

const CONN_MAX_RETRIES: u8 = 5;

pub const CurlSockaddrStorage = extern struct {
    buffer: [128]u8 align(8),
};

pub const CurlSockaddrEx = extern struct {
    family: c_int,
    socktype: c_int,
    protocol: c_int,
    addrlen: c_uint,
    sa_addr: [128]u8 align(8),
};

pub const CurlAddrinfo = extern struct {
    ai_flags: c_int,
    ai_family: c_int,
    ai_socktype: c_int,
    ai_protocol: c_int,
    ai_addrlen: curl_socklen_t,
    ai_canonname: ?[*:0]u8,
    ai_addr: ?*anyopaque,
    ai_next: ?*CurlAddrinfo,
};

pub const IpQuadruple = extern struct {
    remote_ip: [MAX_IPADR_LEN]u8,
    local_ip: [MAX_IPADR_LEN]u8,
    remote_port: u16,
    local_port: u16,
    transport: u8,

    pub inline fn remoteIpPtr(self: *const IpQuadruple) [*]const u8 {
        return &self.remote_ip;
    }

    pub inline fn localIpPtr(self: *const IpQuadruple) [*]const u8 {
        return &self.local_ip;
    }
};

inline fn fromOpaque(comptime T: type, raw: anytype) *T {
    return @ptrCast(@alignCast(raw));
}

inline fn cfSocketCtx(cf: *CurlCfilter) *CfSocketCtx {
    return fromOpaque(CfSocketCtx, cf.ctx.?);
}

const CfSocketCtx = struct {
    peer: ?*CurlPeer,
    addr: CurlSockaddrEx,
    sock: curl_socket_t,
    ip: IpQuadruple,
    started_at: CurlTime,
    connected_at: CurlTime,
    first_byte_at: CurlTime,
    last_sndbuf_query_at: CurlTime,
    sndbuf_size: c_uint,
    sockerr: c_int,
    transport: u8,
    got_first_byte: bool,
    listening: bool,
    accepted: bool,
    sock_connected: bool,
    active: bool,
    stats_reported: bool,
};

// External C / Zig-ported functions
extern fn Curl_trc_bind_c(data: ?*CurlEasy) callconv(.c) void;
extern fn Curl_failf(data: ?*CurlEasy, fmt: [*:0]const u8, ...) callconv(.c) void;
extern fn Curl_infof(data: ?*CurlEasy, fmt: [*:0]const u8, ...) callconv(.c) void;
extern fn Curl_trc_is_verbose_fn(data: ?*CurlEasy) callconv(.c) bool;
extern fn Curl_trc_ft_is_verbose_fn(data: ?*CurlEasy, ft: *const anyopaque) callconv(.c) bool;

inline fn Curl_trc_cf_is_verbose_fn(cf: ?*const CurlCfilter, data: ?*CurlEasy) bool {
    const c = cf orelse return false;
    return Curl_trc_is_verbose_fn(data) and c.cft.log_level >= 1;
}
extern fn Curl_trc_cf_infof(data: ?*CurlEasy, cf: ?*CurlCfilter, fmt: [*:0]const u8, ...) callconv(.c) void;
extern fn Curl_trc_multi(data: ?*CurlEasy, fmt: [*:0]const u8, ...) callconv(.c) void;
extern fn Curl_trc_write(data: ?*CurlEasy, fmt: [*:0]const u8, ...) callconv(.c) void;
extern const Curl_trc_feat_multi: u8;
extern const Curl_trc_feat_write: u8;

extern fn curl_msnprintf(buffer: [*c]u8, maxlength: usize, format: [*:0]const u8, ...) callconv(.c) c_int;
extern fn curlx_inet_ntop(af: c_int, src: *const anyopaque, dst: [*c]u8, size: usize) callconv(.c) CURLcode;
extern fn curlx_strerror(err: c_int, buf: [*c]u8, buflen: usize) callconv(.c) [*:0]const u8;
extern fn curlx_strcopy(dest: [*c]u8, dsize: usize, src: [*:0]const u8, slen: usize) callconv(.c) void;
extern fn curlx_memdup0(src: ?[*]const u8, length: usize) callconv(.c) ?[*:0]u8;
extern fn curlx_nonblock(sockfd: curl_socket_t, nonblock: c_int) callconv(.c) c_int;
extern fn curlx_ptimediff_ms(newer: *const CurlTime, older: *const CurlTime) callconv(.c) timediff_t;
extern fn curlx_sotouz_range(val: curl_off_t, min: usize, max: usize) callconv(.c) usize;
extern fn curlx_sztouz(val: isize, out: *usize) callconv(.c) bool;
extern fn curl_strnequal(s1: [*:0]const u8, s2: [*:0]const u8, max: usize) callconv(.c) c_int;
extern fn Curl_conn_cf_add(data: ?*CurlEasy, conn: ?*ConnectData, sockindex: i8, cf: *CurlCfilter) callconv(.c) void;
extern fn Curl_conn_cf_discard_all(data: ?*CurlEasy, conn: ?*ConnectData, sockindex: i8) callconv(.c) void;

extern fn Curl_socktype_for_transport(transport: u8) callconv(.c) c_int;
extern fn Curl_protocol_for_transport(transport: u8) callconv(.c) c_int;
extern fn Curl_peer_link(ppeer: *?*CurlPeer, peer: ?*CurlPeer) callconv(.c) void;
extern fn Curl_peer_unlink(ppeer: *?*CurlPeer) callconv(.c) void;
extern fn Curl_timeleft_ms(data: ?*CurlEasy) callconv(.c) timediff_t;
extern fn Curl_timeleft_now_ms(data: ?*CurlEasy, pnow: ?*const CurlTime) callconv(.c) timediff_t;

extern fn Curl_pgrs_now(data: ?*CurlEasy) callconv(.c) *const CurlTime;
extern fn Curl_pgrsTimeWas(data: ?*CurlEasy, timer: c_uint, timestamp: CurlTime) callconv(.c) void;
extern fn Curl_pgrsSetDownloadSize(data: ?*CurlEasy, size: curl_off_t) callconv(.c) void;
extern fn Curl_pgrs_since_ms(data: ?*CurlEasy, pnow: ?*const CurlTime, timer: c_uint) callconv(.c) timediff_t;
extern fn Curl_pgrsCheckX(data: ?*CurlEasy, pnow: ?*const CurlTime) callconv(.c) CURLcode;
extern fn Curl_pgrsSendPause(data: ?*CurlEasy, enable: bool) callconv(.c) void;
extern fn Curl_pgrsRecvPause(data: ?*CurlEasy, enable: bool) callconv(.c) void;

extern fn Curl_cshutdn_try_once_idx(data: ?*CurlEasy, sockindex: i8, done: *bool) callconv(.c) CURLcode;
extern fn Curl_multi_xfer_buf_borrow(data: ?*CurlEasy, pbuf: *?[*]u8, pbuflen: *usize) callconv(.c) CURLcode;
extern fn Curl_multi_xfer_buf_release(data: ?*CurlEasy, buf: ?[*]u8) callconv(.c) void;
extern fn Curl_multi_mark_dirty(data: ?*CurlEasy) callconv(.c) void;

extern fn Curl_conn_is_multiplex(conn: ?*ConnectData, sockindex: i8) callconv(.c) bool;
extern fn Curl_conn_data_pending(data: ?*CurlEasy, sockindex: i8) callconv(.c) bool;
extern fn Curl_conn_needs_flush(data: ?*CurlEasy, sockindex: i8) callconv(.c) bool;
extern fn Curl_conn_flush(data: ?*CurlEasy, sockindex: i8) callconv(.c) CURLcode;
extern fn Curl_conn_send(data: ?*CurlEasy, sockindex: i8, buf: ?*const anyopaque, len: usize, eos: bool, pnwritten: *usize) callconv(.c) CURLcode;
extern fn Curl_conn_recv(data: ?*CurlEasy, sockindex: i8, buf: [*]u8, len: usize, pnread: *usize) callconv(.c) CURLcode;
extern fn Curl_conn_ev_data_done_send(data: ?*CurlEasy) callconv(.c) void;
extern fn Curl_conn_ev_data_pause(data: ?*CurlEasy, do_pause: bool) callconv(.c) CURLcode;

extern fn Curl_req_stop_send_recv(data: ?*CurlEasy) callconv(.c) CURLcode;
extern fn Curl_req_abort_sending(data: ?*CurlEasy) callconv(.c) CURLcode;
extern fn Curl_req_done_sending(data: ?*CurlEasy) callconv(.c) bool;
extern fn Curl_req_send_more(data: ?*CurlEasy) callconv(.c) CURLcode;
extern fn Curl_req_want_send(data: ?*CurlEasy) callconv(.c) bool;

extern fn Curl_client_write(data: ?*CurlEasy, type_: c_int, buf: ?[*]const u8, len: usize) callconv(.c) CURLcode;
extern fn Curl_cw_out_done(data: ?*CurlEasy) callconv(.c) CURLcode;
extern fn Curl_cwriter_unpause(data: ?*CurlEasy) callconv(.c) CURLcode;
extern fn Curl_creader_set_rewind(data: ?*CurlEasy, enable: bool) callconv(.c) void;
extern fn Curl_creader_is_paused(data: ?*CurlEasy) callconv(.c) bool;
extern fn Curl_creader_unpause(data: ?*CurlEasy) callconv(.c) CURLcode;

// Helpers in lib/sendf.c
extern fn Curl_cfsock_get_errno() callconv(.c) c_int;
extern fn Curl_cfsock_set_errno(err: c_int) callconv(.c) void;
extern fn Curl_cfsock_set_data_os_errno(data: ?*CurlEasy, err: c_int) callconv(.c) void;
extern fn Curl_cfsock_get_eafnosupport() callconv(.c) c_int;
extern fn Curl_cfsock_is_einprogress_or_eagain(sockerr: c_int) callconv(.c) bool;
extern fn Curl_cfsock_is_send_eagain(sockerr: c_int) callconv(.c) bool;
extern fn Curl_cfsock_is_recv_eagain(sockerr: c_int) callconv(.c) bool;
extern fn Curl_cfsock_is_dgram(socktype: c_int) callconv(.c) bool;
extern fn Curl_cfsock_open_fd(data: ?*CurlEasy, addr: *CurlSockaddrEx, sockfd: *curl_socket_t) callconv(.c) CURLcode;
extern fn Curl_cfsock_close_fd(data: ?*CurlEasy, conn: ?*ConnectData, use_callback: c_int, sock: curl_socket_t) callconv(.c) c_int;
extern fn Curl_cfsock_tuck_nonblock(data: ?*CurlEasy, addr: *CurlSockaddrEx, set: bool) callconv(.c) void;
extern fn Curl_cfsock_needs_nonblock_call(data: ?*CurlEasy) callconv(.c) bool;
extern fn Curl_cfsock_post_open_opts(cf: *CurlCfilter, data: ?*CurlEasy, sock: curl_socket_t, addr: *const CurlSockaddrEx, ip: *const IpQuadruple, transport: u8, isconnected_out: *bool) callconv(.c) CURLcode;
extern fn Curl_cfsock_do_connect(cf: *CurlCfilter, data: ?*CurlEasy, sock: curl_socket_t, addr: *CurlSockaddrEx, is_tcp_fastopen: bool) callconv(.c) c_int;
extern fn Curl_cfsock_verifyconnect(sockfd: curl_socket_t, psockerr: ?*c_int) callconv(.c) bool;
extern fn Curl_cfsock_getsockname(data: ?*CurlEasy, sock: curl_socket_t, ssloc: *CurlSockaddrStorage, slen: *curl_socklen_t, sockerr_out: *c_int) callconv(.c) c_int;
extern fn Curl_cfsock_getpeername(sock: curl_socket_t, ssrem: *CurlSockaddrStorage, plen: *curl_socklen_t, sockerr_out: *c_int) callconv(.c) c_int;
extern fn Curl_cfsock_swrite(conn: ?*ConnectData, sock: curl_socket_t, buf: [*]const u8, len: usize, addr: *const CurlSockaddrEx, sockerr_out: *c_int) callconv(.c) isize;
extern fn Curl_cfsock_sread(sock: curl_socket_t, buf: [*]u8, len: usize, sockerr_out: *c_int) callconv(.c) isize;
extern fn Curl_cfsock_win_update_sndbuf(data: ?*CurlEasy, sock: curl_socket_t, last_query_at: *CurlTime, sndbuf_size: *c_uint) callconv(.c) void;
extern fn Curl_cfsock_quic_opts(sock: curl_socket_t, addr_family: c_int) callconv(.c) void;
extern fn Curl_cfsock_get_accepttimeout(data: ?*CurlEasy) callconv(.c) timediff_t;
extern fn Curl_cfsock_accept_fd(data: ?*CurlEasy, conn: ?*ConnectData, listen_sock: curl_socket_t, s_accepted_out: *curl_socket_t) callconv(.c) CURLcode;
extern fn Curl_cfsock_call_fsockopt_accept(data: ?*CurlEasy, sock: curl_socket_t) callconv(.c) CURLcode;
extern fn Curl_cfsock_get_conn_sock(conn: ?*ConnectData, sockindex: i8) callconv(.c) curl_socket_t;
extern fn Curl_cfsock_set_conn_sock(conn: ?*ConnectData, sockindex: i8, sock: curl_socket_t) callconv(.c) void;
extern fn Curl_cfsock_get_conn_cfilter(data: ?*CurlEasy, sockindex: i8) callconv(.c) ?*CurlCfilter;
extern fn Curl_cfsock_is_tcp_fastopen(conn: ?*ConnectData) callconv(.c) bool;
extern fn Curl_cfsock_set_conn_ipv6(conn: ?*ConnectData, sockindex: i8, addr_family: c_int) callconv(.c) void;
extern fn Curl_cfsock_set_data_primary_ip(data: ?*CurlEasy, ip: *const IpQuadruple) callconv(.c) void;

extern fn Curl_xfer_get_set_headers(data: ?*const CurlEasy) callconv(.c) ?*CurlSlist;
extern fn Curl_xfer_get_conn(data: ?*CurlEasy) callconv(.c) ?*ConnectData;
extern fn Curl_xfer_get_send_idx(data: ?*CurlEasy) callconv(.c) i8;
extern fn Curl_xfer_get_recv_idx(data: ?*CurlEasy) callconv(.c) i8;
extern fn Curl_xfer_in_recv_shutdown(data: ?*CurlEasy) callconv(.c) bool;
extern fn Curl_xfer_get_scheme_protocol(data: ?*CurlEasy) callconv(.c) u32;
extern fn Curl_xfer_get_timecond_info(data: ?*CurlEasy, timevalue: *curl_off_t, timecondition: *u8) callconv(.c) void;
extern fn Curl_xfer_set_timecond_met(data: ?*CurlEasy) callconv(.c) void;
extern fn Curl_xfer_get_recv_resp_state(data: ?*CurlEasy, size: *curl_off_t, bytecount: *curl_off_t, header: *bool, shutdown: *bool) callconv(.c) void;
extern fn Curl_xfer_get_dl_rlimit(data: ?*CurlEasy) callconv(.c) *CurlRlimit;
extern fn Curl_xfer_get_ul_rlimit(data: ?*CurlEasy) callconv(.c) *CurlRlimit;
extern fn Curl_xfer_can_skip_eagain_eos(data: ?*CurlEasy) callconv(.c) bool;
extern fn Curl_xfer_is_eos_written(data: ?*CurlEasy) callconv(.c) bool;
extern fn Curl_xfer_is_req_done(data: ?*CurlEasy) callconv(.c) bool;
extern fn Curl_xfer_set_req_done(data: ?*CurlEasy, done: bool) callconv(.c) void;
extern fn Curl_xfer_is_download_done(data: ?*CurlEasy) callconv(.c) bool;
extern fn Curl_xfer_clear_req_recv(data: ?*CurlEasy) callconv(.c) void;
extern fn Curl_xfer_req_want_recv(data: ?*CurlEasy) callconv(.c) bool;
extern fn Curl_xfer_req_want_send(data: ?*CurlEasy) callconv(.c) bool;
extern fn Curl_xfer_req_want_io(data: ?*CurlEasy) callconv(.c) bool;
extern fn Curl_xfer_is_conn_close(data: ?*CurlEasy) callconv(.c) bool;
extern fn Curl_xfer_get_final_check_info(data: ?*CurlEasy, no_body: *bool, size: *curl_off_t, bytecount: *curl_off_t, has_newurl: *bool) callconv(.c) void;
extern fn Curl_xfer_init_connect_c(data: ?*CurlEasy) callconv(.c) void;
extern fn Curl_xfer_pretransfer_c(data: ?*CurlEasy) callconv(.c) CURLcode;
extern fn Curl_xfer_check_retry(data: ?*CurlEasy, retrycount_out: *u8) callconv(.c) c_int;
extern fn Curl_xfer_set_retrycount(data: ?*CurlEasy, val: u8) callconv(.c) void;
extern fn Curl_xfer_apply_retry(data: ?*CurlEasy, url: *?[*:0]u8) callconv(.c) CURLcode;
extern fn Curl_xfer_setup_fields(data: ?*CurlEasy, send_idx: i8, recv_idx: i8, recv_size: curl_off_t, is_header_out: *bool) callconv(.c) void;
extern fn Curl_xfer_set_shutdown_fields(data: ?*CurlEasy, shutdown: bool, ignore_errors: bool) callconv(.c) void;
extern fn Curl_xfer_scheme_write_resp(data: ?*CurlEasy, buf: ?[*]const u8, blen: usize, is_eos: bool, handled_out: *bool) callconv(.c) CURLcode;
extern fn Curl_xfer_mark_eos_written(data: ?*CurlEasy) callconv(.c) void;
extern fn Curl_xfer_is_cwriter_paused(data: ?*CurlEasy) callconv(.c) bool;
extern fn Curl_xfer_scheme_write_resp_hd(data: ?*CurlEasy, hd0: [*:0]const u8, hdlen: usize, is_eos: bool, handled_out: *bool) callconv(.c) CURLcode;
extern fn Curl_xfer_add_request_size(data: ?*CurlEasy, nwritten: usize) callconv(.c) void;
extern fn Curl_xfer_get_buffer_size(data: ?*CurlEasy) callconv(.c) usize;
extern fn Curl_xfer_check_is_secure(data: ?*CurlEasy) callconv(.c) bool;

inline fn readSaFamily(sa_bytes: [*]const u8) c_int {
    if (comptime builtin.os.tag.isDarwin()) {
        return @as(c_int, sa_bytes[1]);
    } else {
        const fam = std.mem.readInt(u16, sa_bytes[0..2], .little);
        return @as(c_int, fam);
    }
}

pub export fn sockaddr2string(
    sa: ?*anyopaque,
    salen: curl_socklen_t,
    addr: [*c]u8,
    port: *u16,
) callconv(.c) CURLcode {
    const sa_bytes = fromOpaque([256]u8, sa orelse {
        addr[0] = 0;
        port.* = 0;
        return CURLE_UNSUPPORTED_PROTOCOL;
    });
    const family = readSaFamily(sa_bytes);
    var result: CURLcode = CURLE_UNSUPPORTED_PROTOCOL;

    if (family == AF_INET) {
        // struct sockaddr_in: family (2), sin_port (2..4), sin_addr (4..8)
        result = curlx_inet_ntop(family, &sa_bytes[4], addr, MAX_IPADR_LEN);
        if (result == CURLE_OK) {
            port.* = std.mem.readInt(u16, sa_bytes[2..4], .big);
            return result;
        }
    } else if (family == AF_INET6) {
        // struct sockaddr_in6: family (2), sin6_port (2..4), sin6_flowinfo (4..8), sin6_addr (8..24)
        result = curlx_inet_ntop(family, &sa_bytes[8], addr, MAX_IPADR_LEN);
        if (result == CURLE_OK) {
            port.* = std.mem.readInt(u16, sa_bytes[2..4], .big);
            return result;
        }
    } else if (family == AF_UNIX) {
        const sa_family_size: curl_socklen_t = if (comptime builtin.os.tag.isDarwin()) 1 else 2;
        if (salen > sa_family_size) {
            const sun_path: [*]const u8 = sa_bytes[2..].ptr;
            _ = curl_msnprintf(addr, MAX_IPADR_LEN, "%s", sun_path);
        } else {
            addr[0] = 0;
        }
        port.* = 0;
        return CURLE_OK;
    }

    addr[0] = 0;
    port.* = 0;
    return result;
}

pub export fn Curl_socket_addr_from_ai(
    addr: *CurlSockaddrEx,
    ai: *const CurlAddrinfo,
    transport: u8,
) callconv(.c) CURLcode {
    addr.family = ai.ai_family;
    addr.socktype = Curl_socktype_for_transport(transport);
    addr.protocol = Curl_protocol_for_transport(transport);
    addr.addrlen = ai.ai_addrlen;

    if (addr.addrlen > addr.sa_addr.len)
        return CURLE_TOO_LARGE;

    if (ai.ai_addr) |src_any| {
        const src = fromOpaque([128]u8, src_any);
        @memcpy(addr.sa_addr[0..addr.addrlen], src[0..addr.addrlen]);
    }
    return CURLE_OK;
}

pub export fn Curl_socket_open(
    data: ?*CurlEasy,
    ai: *const CurlAddrinfo,
    addr_opt: ?*CurlSockaddrEx,
    transport: u8,
    sockfd: *curl_socket_t,
) callconv(.c) CURLcode {
    var dummy: CurlSockaddrEx = std.mem.zeroes(CurlSockaddrEx);
    const addr = addr_opt orelse &dummy;

    const result = Curl_socket_addr_from_ai(addr, ai, transport);
    if (result != CURLE_OK)
        return result;

    return Curl_cfsock_open_fd(data, addr, sockfd);
}

pub export fn Curl_socket_close(
    data: ?*CurlEasy,
    conn: ?*ConnectData,
    sock: curl_socket_t,
) callconv(.c) c_int {
    return Curl_cfsock_close_fd(data, conn, 0, sock);
}

fn parseInterfaceChecked(
    input: [*:0]const u8,
    dev: ?*?[*:0]u8,
    iface: ?*?[*:0]u8,
    host: ?*?[*:0]u8,
) !void {
    const if_prefix = "if!";
    const host_prefix = "host!";
    const if_host_prefix = "ifhost!";

    const len = std.mem.len(input);
    if (len > 512)
        return error.BadFunctionArgument;

    if (dev) |d| d.* = null;
    if (iface) |i| i.* = null;
    if (host) |h| h.* = null;

    const slice = input[0..len];
    if (std.mem.startsWith(u8, slice, if_prefix)) {
        const rest = slice[if_prefix.len..];
        if (rest.len == 0)
            return error.BadFunctionArgument;
        if (iface) |i| {
            i.* = curlx_memdup0(rest.ptr, rest.len) orelse return error.OutOfMemory;
        }
        return;
    } else if (std.mem.startsWith(u8, slice, host_prefix)) {
        const rest = slice[host_prefix.len..];
        if (rest.len == 0)
            return error.BadFunctionArgument;
        if (host) |h| {
            h.* = curlx_memdup0(rest.ptr, rest.len) orelse return error.OutOfMemory;
        }
        return;
    } else if (std.mem.startsWith(u8, slice, if_host_prefix)) {
        const rest = slice[if_host_prefix.len..];
        const bang_idx = std.mem.indexOfScalar(u8, rest, '!') orelse return error.BadFunctionArgument;
        const iface_part = rest[0..bang_idx];
        const host_part = rest[bang_idx + 1 ..];
        if (host_part.len == 0)
            return error.BadFunctionArgument;
        var dup_iface: ?[*:0]u8 = null;
        errdefer if (dup_iface) |ptr| {
            mem.freeTyped(ptr);
            if (iface) |i| i.* = null;
        };
        if (iface) |i| {
            dup_iface = curlx_memdup0(iface_part.ptr, iface_part.len) orelse return error.OutOfMemory;
            i.* = dup_iface;
        }
        if (host) |h| {
            h.* = curlx_memdup0(host_part.ptr, host_part.len) orelse return error.OutOfMemory;
        }
        return;
    }

    if (len == 0)
        return error.BadFunctionArgument;
    if (dev) |d| {
        d.* = curlx_memdup0(slice.ptr, len) orelse return error.OutOfMemory;
    }
}

pub export fn Curl_parse_interface(
    input: [*:0]const u8,
    dev: ?*?[*:0]u8,
    iface: ?*?[*:0]u8,
    host: ?*?[*:0]u8,
) callconv(.c) CURLcode {
    parseInterfaceChecked(input, dev, iface, host) catch |err| switch (err) {
        error.BadFunctionArgument => return CURLE_BAD_FUNCTION_ARGUMENT,
        error.OutOfMemory => return CURLE_OUT_OF_MEMORY,
    };
    return CURLE_OK;
}

fn socketConnectResult(data: ?*CurlEasy, ipaddress: [*]const u8, sockerr: c_int) CURLcode {
    if (Curl_cfsock_is_einprogress_or_eagain(sockerr))
        return CURLE_OK;

    if (Curl_trc_is_verbose_fn(data)) {
        var buffer: [STRERROR_LEN]u8 = undefined;
        Curl_infof(data, "Immediate connect fail for %s: %s", ipaddress, curlx_strerror(sockerr, &buffer, buffer.len));
    }
    Curl_cfsock_set_data_os_errno(data, sockerr);
    return CURLE_COULDNT_CONNECT;
}

fn cfSocketCtxInit(ctx: *CfSocketCtx, peer: ?*CurlPeer, addr: *const CurlSockaddrEx, transport: u8) CURLcode {
    ctx.* = std.mem.zeroes(CfSocketCtx);
    Curl_peer_link(&ctx.peer, peer);
    ctx.sock = CURL_SOCKET_BAD;
    ctx.transport = transport;
    ctx.addr = addr.*;
    return CURLE_OK;
}

fn cfSocketCtxFree(ctx_opt: ?*CfSocketCtx) void {
    if (ctx_opt) |ctx| {
        Curl_peer_unlink(&ctx.peer);
        mem.destroy(ctx);
    }
}

fn cfSocketShutdown(cf: *CurlCfilter, data: ?*CurlEasy, done: *bool) callconv(.c) CURLcode {
    const c = cf;
    const d = done;
    if (c.flags & 1 != 0) {
        const ctx = cfSocketCtx(c);
        if (Curl_trc_cf_is_verbose_fn(c, data)) {
            Curl_trc_cf_infof(data, c, "cf_socket_shutdown, fd=%lld", @as(c_longlong, @intCast(ctx.sock)));
        }
        if (ctx.sock != CURL_SOCKET_BAD and ctx.transport == TRNSPRT_TCP and curlx_nonblock(ctx.sock, 1) >= 0) {
            var buf: [1024]u8 = undefined;
            var sockerr: c_int = 0;
            _ = Curl_cfsock_sread(ctx.sock, &buf, buf.len, &sockerr);
        }
    }
    d.* = true;
    return CURLE_OK;
}

fn cfSocketDestroy(cf: *CurlCfilter, data: ?*CurlEasy) callconv(.c) void {
    const c = cf;
    if (Curl_trc_cf_is_verbose_fn(c, data)) {
        Curl_trc_cf_infof(data, c, "destroy");
    }
    if (c.ctx) |ctx_any| {
        const ctx = fromOpaque(CfSocketCtx, ctx_any);
        if (ctx.sock != CURL_SOCKET_BAD) {
            if (Curl_trc_cf_is_verbose_fn(c, data)) {
                Curl_trc_cf_infof(data, c, "cf_socket_close, fd=%lld", @as(c_longlong, @intCast(ctx.sock)));
            }
            if (ctx.sock == Curl_cfsock_get_conn_sock(c.conn, c.sockindex)) {
                Curl_cfsock_set_conn_sock(c.conn, c.sockindex, CURL_SOCKET_BAD);
            }
            _ = Curl_cfsock_close_fd(data, c.conn, if (!ctx.accepted) 1 else 0, ctx.sock);
        }
        cfSocketCtxFree(ctx);
        c.ctx = null;
    }
}

fn setLocalIp(cf: *CurlCfilter, data: ?*CurlEasy) void {
    const ctx = cfSocketCtx(cf);
    ctx.ip.local_ip[0] = 0;
    ctx.ip.local_port = 0;

    var ssloc: CurlSockaddrStorage = undefined;
    var slen: curl_socklen_t = @sizeOf(CurlSockaddrStorage);
    var sockerr: c_int = 0;
    const rc = Curl_cfsock_getsockname(data, ctx.sock, &ssloc, &slen, &sockerr);
    if (rc < 0) {
        if (Curl_trc_is_verbose_fn(data)) {
            var buffer: [STRERROR_LEN]u8 = undefined;
            Curl_infof(data, "getsockname() failed with errno %d: %s", sockerr, curlx_strerror(sockerr, &buffer, buffer.len));
        }
    } else if (rc > 0) {
        const result = sockaddr2string(&ssloc, slen, &ctx.ip.local_ip, &ctx.ip.local_port);
        if (result != CURLE_OK and Curl_trc_is_verbose_fn(data)) {
            Curl_infof(data, "ssloc inet_ntop() failed with %d", @as(c_int, @intCast(result)));
        }
    }
}

fn setRemoteIp(cf: *CurlCfilter, data: ?*CurlEasy) CURLcode {
    const ctx = cfSocketCtx(cf);
    ctx.ip.transport = ctx.transport;
    const result = sockaddr2string(&ctx.addr.sa_addr, ctx.addr.addrlen, &ctx.ip.remote_ip, &ctx.ip.remote_port);
    if (result != CURLE_OK) {
        ctx.sockerr = Curl_cfsock_get_eafnosupport();
        Curl_trc_bind_c(data);
        Curl_failf(data, "curl_sa_addr inet_ntop() failed with %d", @as(c_int, @intCast(result)));
        return CURLE_FAILED_INIT;
    }
    return CURLE_OK;
}

fn cfSocketOpen(cf: *CurlCfilter, data: ?*CurlEasy) CURLcode {
    const ctx = cfSocketCtx(cf);
    var isconnected: bool = false;
    var result: CURLcode = CURLE_COULDNT_CONNECT;

    ctx.started_at = Curl_pgrs_now(data).*;
    Curl_cfsock_tuck_nonblock(data, &ctx.addr, true);
    result = Curl_cfsock_open_fd(data, &ctx.addr, &ctx.sock);
    Curl_cfsock_tuck_nonblock(data, &ctx.addr, false);
    if (result == CURLE_OK) {
        result = setRemoteIp(cf, data);
    }
    if (result == CURLE_OK) {
        result = Curl_cfsock_post_open_opts(cf, data, ctx.sock, &ctx.addr, &ctx.ip, ctx.transport, &isconnected);
    }
    if (result == CURLE_OK and Curl_cfsock_needs_nonblock_call(data)) {
        if (curlx_nonblock(ctx.sock, 1) < 0) {
            result = CURLE_UNSUPPORTED_PROTOCOL;
            ctx.sockerr = Curl_cfsock_get_errno();
        }
    }
    if (result == CURLE_OK) {
        ctx.sock_connected = !Curl_cfsock_is_dgram(ctx.addr.socktype);
    }

    if (result != CURLE_OK) {
        if (ctx.sock != CURL_SOCKET_BAD) {
            _ = Curl_cfsock_close_fd(data, cf.conn, 1, ctx.sock);
            ctx.sock = CURL_SOCKET_BAD;
        }
    } else if (isconnected) {
        setLocalIp(cf, data);
        ctx.connected_at = Curl_pgrs_now(data).*;
        cf.flags |= 1;
    }
    if (Curl_trc_cf_is_verbose_fn(cf, data)) {
        Curl_trc_cf_infof(data, cf, "cf_socket_open() -> %d, fd=%lld", @as(c_int, @intCast(result)), @as(c_longlong, @intCast(ctx.sock)));
    }
    return result;
}

fn cfTcpConnect(cf: *CurlCfilter, data: ?*CurlEasy, done: *bool) callconv(.c) CURLcode {
    const c = cf;
    const d = done;
    const ctx = cfSocketCtx(c);
    var result: CURLcode = CURLE_COULDNT_CONNECT;
    var rc: c_int = 0;

    if (c.flags & 1 != 0) {
        d.* = true;
        return CURLE_OK;
    }

    d.* = false;
    if (ctx.sock == CURL_SOCKET_BAD) {
        result = cfSocketOpen(c, data);
        if (result != CURLE_OK)
            return finishTcpConnectErr(c, data, ctx, d, result);

        if (c.flags & 1 != 0) {
            d.* = true;
            return CURLE_OK;
        }

        rc = Curl_cfsock_do_connect(c, data, ctx.sock, &ctx.addr, Curl_cfsock_is_tcp_fastopen(c.conn));
        const sockerr = Curl_cfsock_get_errno();
        setLocalIp(c, data);
        if (Curl_trc_cf_is_verbose_fn(c, data)) {
            Curl_trc_cf_infof(data, c, "local address %s port %d...", ctx.ip.localIpPtr(), @as(c_int, ctx.ip.local_port));
        }
        if (rc == -1) {
            ctx.sockerr = sockerr;
            result = socketConnectResult(data, ctx.ip.remoteIpPtr(), sockerr);
            if (result != CURLE_OK)
                return finishTcpConnectErr(c, data, ctx, d, result);
            return CURLE_OK;
        }
    }

    rc = headers_sock.Curl_socket_check(CURL_SOCKET_BAD, CURL_SOCKET_BAD, ctx.sock, 0);
    if (rc == 0) {
        if (Curl_trc_cf_is_verbose_fn(c, data)) {
            Curl_trc_cf_infof(data, c, "not connected yet on fd=%lld", @as(c_longlong, @intCast(ctx.sock)));
        }
        return CURLE_OK;
    } else if (rc == headers_sock.CURL_CSELECT_OUT or Curl_cfsock_is_tcp_fastopen(c.conn)) {
        if (Curl_cfsock_verifyconnect(ctx.sock, &ctx.sockerr)) {
            ctx.connected_at = Curl_pgrs_now(data).*;
            setLocalIp(c, data);
            d.* = true;
            c.flags |= 1;
            if (Curl_trc_cf_is_verbose_fn(c, data)) {
                Curl_trc_cf_infof(data, c, "connected on fd=%lld", @as(c_longlong, @intCast(ctx.sock)));
            }
            return CURLE_OK;
        }
    } else if ((rc & headers_sock.CURL_CSELECT_ERR) != 0) {
        if (Curl_trc_cf_is_verbose_fn(c, data)) {
            Curl_trc_cf_infof(data, c, "poll/select error on fd=%lld", @as(c_longlong, @intCast(ctx.sock)));
        }
        _ = Curl_cfsock_verifyconnect(ctx.sock, &ctx.sockerr);
        result = CURLE_COULDNT_CONNECT;
    }

    return finishTcpConnectErr(c, data, ctx, d, result);
}

fn finishTcpConnectErr(cf: *CurlCfilter, data: ?*CurlEasy, ctx: *CfSocketCtx, done: *bool, result: CURLcode) CURLcode {
    if (result != CURLE_OK) {
        var buffer: [STRERROR_LEN:0]u8 = undefined;
        setLocalIp(cf, data);
        if (ctx.sockerr != 0) {
            Curl_cfsock_set_data_os_errno(data, ctx.sockerr);
            Curl_cfsock_set_errno(ctx.sockerr);
        } else {
            curlx_strcopy(&buffer, buffer.len, "peer closed", "peer closed".len);
        }
        if (ctx.sock != CURL_SOCKET_BAD) {
            _ = Curl_cfsock_close_fd(data, cf.conn, 1, ctx.sock);
            ctx.sock = CURL_SOCKET_BAD;
        }
        if (Curl_trc_is_verbose_fn(data)) {
            const err_msg: [*:0]const u8 = if (ctx.sockerr != 0)
                curlx_strerror(ctx.sockerr, &buffer, buffer.len)
            else
                &buffer;
            Curl_infof(
                data,
                "connect to %s port %u from %s port %d failed: %s",
                ctx.ip.remoteIpPtr(),
                @as(c_uint, ctx.ip.remote_port),
                ctx.ip.localIpPtr(),
                @as(c_int, ctx.ip.local_port),
                err_msg,
            );
        }
        done.* = false;
    }
    return result;
}

fn cfSocketAdjustPollset(cf: *CurlCfilter, data: ?*CurlEasy, ps: *EasyPollset) callconv(.c) CURLcode {
    const c = cf;
    const ctx = cfSocketCtx(c);
    var result: CURLcode = CURLE_OK;

    if (ctx.sock != CURL_SOCKET_BAD) {
        if (ctx.listening) {
            result = headers_sock.Curl_pollset_change(data, ps, ctx.sock, headers_sock.CURL_POLL_IN, headers_sock.CURL_POLL_OUT);
            if (Curl_trc_cf_is_verbose_fn(c, data)) {
                Curl_trc_cf_infof(data, c, "adjust_pollset, listening, POLLIN fd=%lld", @as(c_longlong, @intCast(ctx.sock)));
            }
        } else if ((c.flags & 1) == 0) {
            result = headers_sock.Curl_pollset_change(data, ps, ctx.sock, headers_sock.CURL_POLL_OUT, headers_sock.CURL_POLL_IN);
            if (Curl_trc_cf_is_verbose_fn(c, data)) {
                Curl_trc_cf_infof(data, c, "adjust_pollset, !connected, POLLOUT fd=%lld", @as(c_longlong, @intCast(ctx.sock)));
            }
        } else if (!ctx.active) {
            result = headers_sock.Curl_pollset_change(data, ps, ctx.sock, headers_sock.CURL_POLL_IN, 0);
            if (Curl_trc_cf_is_verbose_fn(c, data)) {
                Curl_trc_cf_infof(data, c, "adjust_pollset, !active, POLLIN fd=%lld", @as(c_longlong, @intCast(ctx.sock)));
            }
        }
    }
    return result;
}

fn cfSocketSend(
    cf: *CurlCfilter,
    data: ?*CurlEasy,
    buf: [*]const u8,
    len: usize,
    eos: bool,
    pnwritten: *usize,
) callconv(.c) CURLcode {
    _ = eos;
    const c = cf;
    const ctx = cfSocketCtx(c);
    const pnw = pnwritten;
    pnw.* = 0;

    const fdsave = Curl_cfsock_get_conn_sock(c.conn, c.sockindex);
    Curl_cfsock_set_conn_sock(c.conn, c.sockindex, ctx.sock);

    var sockerr: c_int = 0;
    const rv = Curl_cfsock_swrite(c.conn, ctx.sock, buf, len, &ctx.addr, &sockerr);
    var result: CURLcode = CURLE_OK;

    if (!curlx_sztouz(rv, pnw)) {
        if (Curl_cfsock_is_send_eagain(sockerr)) {
            result = CURLE_AGAIN;
        } else {
            var buffer: [STRERROR_LEN]u8 = undefined;
            Curl_trc_bind_c(data);
            Curl_failf(data, "Send failure: %s", curlx_strerror(sockerr, &buffer, buffer.len));
            Curl_cfsock_set_data_os_errno(data, sockerr);
            result = CURLE_SEND_ERROR;
        }
    }

    if (result == CURLE_OK) {
        Curl_cfsock_win_update_sndbuf(data, ctx.sock, &ctx.last_sndbuf_query_at, &ctx.sndbuf_size);
    }

    if (Curl_trc_cf_is_verbose_fn(c, data)) {
        Curl_trc_cf_infof(data, c, "send(len=%zu) -> %d, %zu", len, @as(c_int, @intCast(result)), pnw.*);
    }
    Curl_cfsock_set_conn_sock(c.conn, c.sockindex, fdsave);
    return result;
}

fn cfSocketRecv(
    cf: *CurlCfilter,
    data: ?*CurlEasy,
    buf: [*]u8,
    len: usize,
    pnread: *usize,
) callconv(.c) CURLcode {
    const c = cf;
    const ctx = cfSocketCtx(c);
    const pnr = pnread;
    pnr.* = 0;

    var sockerr: c_int = 0;
    const rv = Curl_cfsock_sread(ctx.sock, buf, len, &sockerr);
    var result: CURLcode = CURLE_OK;

    if (!curlx_sztouz(rv, pnr)) {
        if (Curl_cfsock_is_recv_eagain(sockerr)) {
            result = CURLE_AGAIN;
        } else {
            var buffer: [STRERROR_LEN]u8 = undefined;
            Curl_trc_bind_c(data);
            Curl_failf(data, "Recv failure: %s", curlx_strerror(sockerr, &buffer, buffer.len));
            Curl_cfsock_set_data_os_errno(data, sockerr);
            result = CURLE_RECV_ERROR;
        }
    }

    if (Curl_trc_cf_is_verbose_fn(c, data)) {
        Curl_trc_cf_infof(data, c, "recv(len=%zu) -> %d, %zu", len, @as(c_int, @intCast(result)), pnr.*);
    }
    if (result == CURLE_OK and !ctx.got_first_byte) {
        ctx.first_byte_at = Curl_pgrs_now(data).*;
        ctx.got_first_byte = true;
    }
    return result;
}

fn cfSocketUpdateData(cf: *CurlCfilter, data: ?*CurlEasy) void {
    if ((cf.flags & 1) != 0 and cf.sockindex == FIRSTSOCKET) {
        const ctx = cfSocketCtx(cf);
        Curl_cfsock_set_data_primary_ip(data, &ctx.ip);
    }
}

fn cfSocketActive(cf: *CurlCfilter, data: ?*CurlEasy) void {
    const ctx = cfSocketCtx(cf);
    Curl_cfsock_set_conn_sock(cf.conn, cf.sockindex, ctx.sock);
    setLocalIp(cf, data);
    Curl_cfsock_set_conn_ipv6(cf.conn, cf.sockindex, ctx.addr.family);
    ctx.active = true;
}

fn cfSocketCntrl(
    cf: *CurlCfilter,
    data: ?*CurlEasy,
    event: c_int,
    arg1: c_int,
    arg2: ?*anyopaque,
) callconv(.c) CURLcode {
    _ = arg1;
    _ = arg2;
    const c = cf;
    const ctx = cfSocketCtx(c);

    switch (event) {
        CF_CTRL_CONN_INFO_UPDATE => {
            cfSocketActive(c, data);
            cfSocketUpdateData(c, data);
        },
        CF_CTRL_DATA_SETUP => {
            cfSocketUpdateData(c, data);
        },
        CF_CTRL_FORGET_SOCKET => {
            ctx.sock = CURL_SOCKET_BAD;
        },
        CF_CTRL_REPORT_STATS => {
            if ((c.flags & 1) != 0 and !ctx.stats_reported) {
                var ts_opt: ?*const CurlTime = null;
                if (ctx.transport == TRNSPRT_UDP or ctx.transport == TRNSPRT_QUIC) {
                    if (ctx.got_first_byte)
                        ts_opt = &ctx.first_byte_at;
                } else {
                    ts_opt = &ctx.connected_at;
                }
                if (ts_opt) |ts| {
                    Curl_pgrsTimeWas(data, TIMER_CONNECT, ts.*);
                    ctx.stats_reported = true;
                }
            }
        },
        else => {},
    }
    return CURLE_OK;
}

fn cfSocketConnIsAlive(cf: *CurlCfilter, data: ?*CurlEasy, input_pending: *bool) callconv(.c) bool {
    const c = cf;
    const ip = input_pending;
    ip.* = false;

    const ctx_any = c.ctx orelse return false;
    const ctx = fromOpaque(CfSocketCtx, ctx_any);
    if (ctx.sock == CURL_SOCKET_BAD)
        return false;

    var pfd: [1]headers_sock.Pollfd = .{.{
        .fd = ctx.sock,
        .events = headers_sock.POLLRDNORM | headers_sock.POLLIN | headers_sock.POLLRDBAND | headers_sock.POLLPRI,
        .revents = 0,
    }};

    const r = headers_sock.Curl_poll(&pfd, 1, 0);
    if (r < 0) {
        if (Curl_trc_cf_is_verbose_fn(c, data)) {
            Curl_trc_cf_infof(data, c, "is_alive: poll error, assume dead");
        }
        return false;
    } else if (r == 0) {
        if (Curl_trc_cf_is_verbose_fn(c, data)) {
            Curl_trc_cf_infof(data, c, "is_alive: poll timeout, assume alive");
        }
        return true;
    } else if ((pfd[0].revents & (headers_sock.POLLERR | headers_sock.POLLHUP | headers_sock.POLLPRI | headers_sock.POLLNVAL)) != 0) {
        if (Curl_trc_cf_is_verbose_fn(c, data)) {
            Curl_trc_cf_infof(data, c, "is_alive: err/hup/etc events, assume dead");
        }
        return false;
    }

    if (Curl_trc_cf_is_verbose_fn(c, data)) {
        Curl_trc_cf_infof(data, c, "is_alive: valid events, looks alive");
    }
    ip.* = true;
    return true;
}

fn cfSocketQuery(
    cf: *CurlCfilter,
    data: ?*CurlEasy,
    query: c_int,
    pres1: ?*c_int,
    pres2: ?*anyopaque,
) callconv(.c) CURLcode {
    const c = cf;
    const ctx = cfSocketCtx(c);

    switch (query) {
        CF_QUERY_SOCKET => {
            const out = fromOpaque(curl_socket_t, pres2.?);
            out.* = ctx.sock;
            return CURLE_OK;
        },
        CF_QUERY_TRANSPORT => {
            pres1.?.* = ctx.transport;
            return CURLE_OK;
        },
        CF_QUERY_REMOTE_ADDR => {
            const out = fromOpaque(?*const CurlSockaddrEx, pres2.?);
            out.* = if ((c.flags & 1) != 0) &ctx.addr else null;
            return CURLE_OK;
        },
        CF_QUERY_CONNECT_REPLY_MS => {
            if (ctx.got_first_byte) {
                const ms = curlx_ptimediff_ms(&ctx.first_byte_at, &ctx.started_at);
                pres1.?.* = if (ms < std.math.maxInt(c_int)) @intCast(ms) else std.math.maxInt(c_int);
            } else {
                pres1.?.* = -1;
            }
            return CURLE_OK;
        },
        CF_QUERY_IP_INFO => {
            pres1.?.* = if (ctx.addr.family == AF_INET6) 1 else 0;
            const out = fromOpaque(IpQuadruple, pres2.?);
            out.* = ctx.ip;
            return CURLE_OK;
        },
        CF_QUERY_REALLY_CONNECTED => {
            if (c.cft != &Curl_cft_udp) {
                pres1.?.* = if ((c.flags & 1) != 0) 1 else 0;
            } else {
                pres1.?.* = if (ctx.got_first_byte) 1 else 0;
            }
            return CURLE_OK;
        },
        else => {},
    }
    if (c.next) |next| {
        if (next.cft.query) |qfn| {
            return qfn(next, data, query, pres1, pres2);
        }
    }
    return CURLE_UNKNOWN_OPTION;
}

pub export var Curl_cft_tcp: CurlCftype = .{
    .name = "TCP",
    .flags = CF_TYPE_IP_CONNECT,
    .log_level = CURL_LOG_LVL_NONE,
    .destroy = cfSocketDestroy,
    .do_connect = cfTcpConnect,
    .do_shutdown = cfSocketShutdown,
    .adjust_pollset = cfSocketAdjustPollset,
    .has_data_pending = cfilters_progress.Curl_cf_def_data_pending,
    .do_send = cfSocketSend,
    .do_recv = cfSocketRecv,
    .cntrl = cfSocketCntrl,
    .is_alive = cfSocketConnIsAlive,
    .keep_alive = cfilters_progress.Curl_cf_def_conn_keep_alive,
    .query = cfSocketQuery,
};

fn createSocketFilterChecked(
    pcf: *?*CurlCfilter,
    peer: ?*CurlPeer,
    transport_peer: u8,
    addr_opt: ?*const CurlSockaddrEx,
    cft: *const CurlCftype,
    require_addr: bool,
    out_result: *CURLcode,
) !void {
    pcf.* = null;
    if (require_addr and addr_opt == null) {
        out_result.* = CURLE_BAD_FUNCTION_ARGUMENT;
        return error.BadFunctionArgument;
    }

    const ctx = mem.create(CfSocketCtx) orelse {
        out_result.* = CURLE_OUT_OF_MEMORY;
        return error.OutOfMemory;
    };
    errdefer cfSocketCtxFree(ctx);
    const addr = addr_opt.?;

    var result = cfSocketCtxInit(ctx, peer, addr, transport_peer);
    if (result != CURLE_OK) {
        out_result.* = result;
        return error.InitFailed;
    }

    var cf: ?*CurlCfilter = null;
    result = cfilters_progress.Curl_cf_create(&cf, cft, ctx);
    if (result != CURLE_OK) {
        if (cf) |c| mem.destroy(c);
        out_result.* = result;
        return error.CreateFailed;
    }
    pcf.* = cf;
    out_result.* = CURLE_OK;
}

fn createSocketFilter(
    pcf: *?*CurlCfilter,
    peer: ?*CurlPeer,
    transport_peer: u8,
    addr_opt: ?*const CurlSockaddrEx,
    cft: *const CurlCftype,
    require_addr: bool,
) CURLcode {
    var result: CURLcode = CURLE_OK;
    createSocketFilterChecked(pcf, peer, transport_peer, addr_opt, cft, require_addr, &result) catch return result;
    return CURLE_OK;
}

pub export fn Curl_cf_tcp_create(
    pcf: *?*CurlCfilter,
    data: ?*CurlEasy,
    origin: ?*CurlPeer,
    peer: ?*CurlPeer,
    transport_peer: u8,
    conn: ?*ConnectData,
    addr: ?*const CurlSockaddrEx,
    tunnel_peer: ?*CurlPeer,
    tunnel_transport: u8,
) callconv(.c) CURLcode {
    _ = data;
    _ = origin;
    _ = conn;
    _ = tunnel_peer;
    _ = tunnel_transport;
    return createSocketFilter(pcf, peer, transport_peer, addr, &Curl_cft_tcp, true);
}

fn cfUdpSetupQuic(cf: *CurlCfilter, data: ?*CurlEasy) CURLcode {
    const ctx = cfSocketCtx(cf);
    const rc = Curl_cfsock_do_connect(cf, data, ctx.sock, &ctx.addr, false);
    if (rc == -1) {
        return socketConnectResult(data, ctx.ip.remoteIpPtr(), Curl_cfsock_get_errno());
    }
    ctx.sock_connected = true;
    setLocalIp(cf, data);
    if (Curl_trc_cf_is_verbose_fn(cf, data)) {
        const label: [*:0]const u8 = if (ctx.transport == TRNSPRT_QUIC) "QUIC" else "UDP";
        Curl_trc_cf_infof(
            data,
            cf,
            "%s socket %lld connected: [%s:%d] -> [%s:%d]",
            label,
            @as(c_longlong, @intCast(ctx.sock)),
            ctx.ip.localIpPtr(),
            @as(c_int, ctx.ip.local_port),
            ctx.ip.remoteIpPtr(),
            @as(c_int, ctx.ip.remote_port),
        );
    }
    Curl_cfsock_quic_opts(ctx.sock, ctx.addr.family);
    return CURLE_OK;
}

fn cfUdpConnect(cf: *CurlCfilter, data: ?*CurlEasy, done: *bool) callconv(.c) CURLcode {
    const c = cf;
    const d = done;
    const ctx = cfSocketCtx(c);
    var result: CURLcode = CURLE_COULDNT_CONNECT;

    if ((c.flags & 1) != 0) {
        d.* = true;
        return CURLE_OK;
    }

    d.* = false;
    if (ctx.sock == CURL_SOCKET_BAD) {
        result = cfSocketOpen(c, data);
        if (result != CURLE_OK) {
            if (Curl_trc_cf_is_verbose_fn(c, data)) {
                Curl_trc_cf_infof(data, c, "cf_udp_connect(), open failed -> %d", @as(c_int, @intCast(result)));
            }
            return result;
        }

        if (ctx.transport == TRNSPRT_QUIC) {
            result = cfUdpSetupQuic(c, data);
            if (result != CURLE_OK)
                return result;
            if (Curl_trc_cf_is_verbose_fn(c, data)) {
                Curl_trc_cf_infof(
                    data,
                    c,
                    "cf_udp_connect(), opened socket=%lld (%s:%d)",
                    @as(c_longlong, @intCast(ctx.sock)),
                    ctx.ip.localIpPtr(),
                    @as(c_int, ctx.ip.local_port),
                );
            }
        }
        d.* = true;
        c.flags |= 1;
    }
    return result;
}

pub export var Curl_cft_udp: CurlCftype = .{
    .name = "UDP",
    .flags = CF_TYPE_IP_CONNECT,
    .log_level = CURL_LOG_LVL_NONE,
    .destroy = cfSocketDestroy,
    .do_connect = cfUdpConnect,
    .do_shutdown = cfSocketShutdown,
    .adjust_pollset = cfSocketAdjustPollset,
    .has_data_pending = cfilters_progress.Curl_cf_def_data_pending,
    .do_send = cfSocketSend,
    .do_recv = cfSocketRecv,
    .cntrl = cfSocketCntrl,
    .is_alive = cfSocketConnIsAlive,
    .keep_alive = cfilters_progress.Curl_cf_def_conn_keep_alive,
    .query = cfSocketQuery,
};

pub export fn Curl_cf_udp_create(
    pcf: *?*CurlCfilter,
    data: ?*CurlEasy,
    origin: ?*CurlPeer,
    peer: ?*CurlPeer,
    transport_peer: u8,
    conn: ?*ConnectData,
    addr: ?*const CurlSockaddrEx,
    tunnel_peer: ?*CurlPeer,
    tunnel_transport: u8,
) callconv(.c) CURLcode {
    _ = data;
    _ = origin;
    _ = conn;
    _ = tunnel_peer;
    _ = tunnel_transport;
    return createSocketFilter(pcf, peer, transport_peer, addr, &Curl_cft_udp, false);
}

pub export var Curl_cft_unix: CurlCftype = .{
    .name = "UNIX",
    .flags = CF_TYPE_IP_CONNECT,
    .log_level = CURL_LOG_LVL_NONE,
    .destroy = cfSocketDestroy,
    .do_connect = cfTcpConnect,
    .do_shutdown = cfSocketShutdown,
    .adjust_pollset = cfSocketAdjustPollset,
    .has_data_pending = cfilters_progress.Curl_cf_def_data_pending,
    .do_send = cfSocketSend,
    .do_recv = cfSocketRecv,
    .cntrl = cfSocketCntrl,
    .is_alive = cfSocketConnIsAlive,
    .keep_alive = cfilters_progress.Curl_cf_def_conn_keep_alive,
    .query = cfSocketQuery,
};

pub export fn Curl_cf_unix_create(
    pcf: *?*CurlCfilter,
    data: ?*CurlEasy,
    origin: ?*CurlPeer,
    peer: ?*CurlPeer,
    transport_peer: u8,
    conn: ?*ConnectData,
    addr: ?*const CurlSockaddrEx,
    tunnel_peer: ?*CurlPeer,
    tunnel_transport: u8,
) callconv(.c) CURLcode {
    _ = data;
    _ = origin;
    _ = conn;
    _ = tunnel_peer;
    _ = tunnel_transport;
    return createSocketFilter(pcf, peer, transport_peer, addr, &Curl_cft_unix, false);
}

fn cfTcpAcceptTimeleft(cf: *CurlCfilter, data: ?*CurlEasy) timediff_t {
    const ctx = cfSocketCtx(cf);
    var timeout_ms = Curl_cfsock_get_accepttimeout(data);
    const other_ms = Curl_timeleft_ms(data);
    if (other_ms != 0 and other_ms < timeout_ms) {
        timeout_ms = other_ms;
    } else {
        timeout_ms -= curlx_ptimediff_ms(Curl_pgrs_now(data), &ctx.started_at);
        if (timeout_ms == 0)
            timeout_ms = -1;
    }
    return timeout_ms;
}

fn cfTcpSetAcceptedRemoteIp(cf: *CurlCfilter, data: ?*CurlEasy) void {
    const ctx = cfSocketCtx(cf);
    ctx.ip.remote_ip[0] = 0;
    ctx.ip.remote_port = 0;

    var ssrem: CurlSockaddrStorage = undefined;
    var plen: curl_socklen_t = @sizeOf(CurlSockaddrStorage);
    var sockerr: c_int = 0;
    const rc = Curl_cfsock_getpeername(ctx.sock, &ssrem, &plen, &sockerr);
    if (rc < 0) {
        var buffer: [STRERROR_LEN]u8 = undefined;
        Curl_trc_bind_c(data);
        Curl_failf(data, "getpeername() failed with errno %d: %s", sockerr, curlx_strerror(sockerr, &buffer, buffer.len));
        return;
    } else if (rc > 0) {
        const result = sockaddr2string(&ssrem, plen, &ctx.ip.remote_ip, &ctx.ip.remote_port);
        if (result != CURLE_OK) {
            Curl_trc_bind_c(data);
            Curl_failf(data, "ssrem inet_ntop() failed with %d", @as(c_int, @intCast(result)));
            return;
        }
    }
}

fn cfTcpAcceptConnect(cf: *CurlCfilter, data: ?*CurlEasy, done: *bool) callconv(.c) CURLcode {
    const c = cf;
    const d = done;
    const ctx = cfSocketCtx(c);

    if ((c.flags & 1) != 0) {
        d.* = true;
        return CURLE_OK;
    }

    d.* = false;
    const timeout_ms = cfTcpAcceptTimeleft(c, data);
    if (timeout_ms < 0) {
        Curl_trc_bind_c(data);
        Curl_failf(data, "Accept timeout occurred while waiting server connect");
        return CURLE_FTP_ACCEPT_TIMEOUT;
    }

    if (Curl_trc_cf_is_verbose_fn(c, data)) {
        Curl_trc_cf_infof(
            data,
            c,
            "Checking for incoming on fd=%lld ip=%s:%d",
            @as(c_longlong, @intCast(ctx.sock)),
            ctx.ip.localIpPtr(),
            @as(c_int, ctx.ip.local_port),
        );
    }
    const socketstate = headers_sock.Curl_socket_check(ctx.sock, CURL_SOCKET_BAD, CURL_SOCKET_BAD, 0);
    if (Curl_trc_cf_is_verbose_fn(c, data)) {
        Curl_trc_cf_infof(data, c, "socket_check -> %x", @as(c_uint, @bitCast(socketstate)));
    }
    var incoming = false;
    if (socketstate == -1) {
        Curl_trc_bind_c(data);
        Curl_failf(data, "Error while waiting for server connect");
        return CURLE_FTP_ACCEPT_FAILED;
    } else if ((socketstate & headers_sock.CURL_CSELECT_IN) != 0) {
        if (Curl_trc_is_verbose_fn(data)) {
            Curl_infof(data, "Ready to accept data connection from server");
        }
        incoming = true;
    }

    if (!incoming) {
        if (Curl_trc_cf_is_verbose_fn(c, data)) {
            Curl_trc_cf_infof(data, c, "nothing heard from the server yet");
        }
        return CURLE_OK;
    }

    var s_accepted: curl_socket_t = CURL_SOCKET_BAD;
    const accept_res = Curl_cfsock_accept_fd(data, c.conn, ctx.sock, &s_accepted);
    if (accept_res != CURLE_OK)
        return accept_res;

    if (Curl_trc_is_verbose_fn(data)) {
        Curl_infof(data, "Connection accepted from server");
    }

    ctx.listening = false;
    ctx.accepted = true;
    _ = Curl_cfsock_close_fd(data, c.conn, 1, ctx.sock);
    ctx.sock = s_accepted;

    Curl_cfsock_set_conn_sock(c.conn, c.sockindex, ctx.sock);
    cfTcpSetAcceptedRemoteIp(c, data);
    setLocalIp(c, data);
    ctx.active = true;
    ctx.connected_at = Curl_pgrs_now(data).*;
    c.flags |= 1;
    if (Curl_trc_cf_is_verbose_fn(c, data)) {
        Curl_trc_cf_infof(
            data,
            c,
            "accepted_set(sock=%lld, remote=%s port=%d)",
            @as(c_longlong, @intCast(ctx.sock)),
            ctx.ip.remoteIpPtr(),
            @as(c_int, ctx.ip.remote_port),
        );
    }

    const opt_res = Curl_cfsock_call_fsockopt_accept(data, ctx.sock);
    if (opt_res != CURLE_OK)
        return opt_res;

    d.* = true;
    return CURLE_OK;
}

pub export var Curl_cft_tcp_accept: CurlCftype = .{
    .name = "TCP-ACCEPT",
    .flags = CF_TYPE_IP_CONNECT,
    .log_level = CURL_LOG_LVL_NONE,
    .destroy = cfSocketDestroy,
    .do_connect = cfTcpAcceptConnect,
    .do_shutdown = cfSocketShutdown,
    .adjust_pollset = cfSocketAdjustPollset,
    .has_data_pending = cfilters_progress.Curl_cf_def_data_pending,
    .do_send = cfSocketSend,
    .do_recv = cfSocketRecv,
    .cntrl = cfSocketCntrl,
    .is_alive = cfSocketConnIsAlive,
    .keep_alive = cfilters_progress.Curl_cf_def_conn_keep_alive,
    .query = cfSocketQuery,
};

fn connTcpListenSetChecked(
    data: ?*CurlEasy,
    conn: ?*ConnectData,
    sockindex: i8,
    s: *const curl_socket_t,
    out_result: *CURLcode,
) !void {
    Curl_conn_cf_discard_all(data, conn, sockindex);

    const ctx = mem.create(CfSocketCtx) orelse {
        out_result.* = CURLE_OUT_OF_MEMORY;
        return error.OutOfMemory;
    };
    errdefer cfSocketCtxFree(ctx);
    ctx.transport = TRNSPRT_TCP;
    ctx.sock = s.*;
    ctx.listening = true;
    ctx.accepted = false;

    var cf: ?*CurlCfilter = null;
    const result = cfilters_progress.Curl_cf_create(&cf, &Curl_cft_tcp_accept, ctx);
    if (result != CURLE_OK) {
        if (cf) |c| mem.destroy(c);
        out_result.* = result;
        return error.CreateFailed;
    }

    const c = cf.?;
    Curl_conn_cf_add(data, conn, sockindex, c);
    ctx.started_at = Curl_pgrs_now(data).*;
    Curl_cfsock_set_conn_sock(conn, sockindex, ctx.sock);
    setLocalIp(c, data);
    if (Curl_trc_cf_is_verbose_fn(c, data)) {
        Curl_trc_cf_infof(
            data,
            c,
            "set filter for listen socket fd=%lld ip=%s:%d",
            @as(c_longlong, @intCast(ctx.sock)),
            ctx.ip.localIpPtr(),
            @as(c_int, ctx.ip.local_port),
        );
    }
    out_result.* = CURLE_OK;
}

pub export fn Curl_conn_tcp_listen_set(
    data: ?*CurlEasy,
    conn: ?*ConnectData,
    sockindex: i8,
    s: *const curl_socket_t,
) callconv(.c) CURLcode {
    var result: CURLcode = CURLE_OK;
    connTcpListenSetChecked(data, conn, sockindex, s, &result) catch return result;
    return CURLE_OK;
}

pub export fn Curl_conn_is_tcp_listen(data: ?*CurlEasy, sockindex: i8) callconv(.c) bool {
    var cf = Curl_cfsock_get_conn_cfilter(data, sockindex);
    while (cf) |c| : (cf = c.next) {
        if (c.cft == &Curl_cft_tcp_accept)
            return true;
    }
    return false;
}

fn cfIsSocket(cf_opt: ?*CurlCfilter) bool {
    const cf = cf_opt orelse return false;
    return cf.cft == &Curl_cft_tcp or
        cf.cft == &Curl_cft_udp or
        cf.cft == &Curl_cft_unix or
        cf.cft == &Curl_cft_tcp_accept;
}

pub export fn Curl_cf_socket_peek(
    cf: ?*CurlCfilter,
    data: ?*CurlEasy,
    psock: ?*curl_socket_t,
    paddr: ?*?*const CurlSockaddrEx,
    pip: ?*IpQuadruple,
) callconv(.c) CURLcode {
    _ = data;
    if (cfIsSocket(cf)) {
        if (cf.?.ctx) |ctx_any| {
            const ctx = fromOpaque(CfSocketCtx, ctx_any);
            if (psock) |ps| ps.* = ctx.sock;
            if (paddr) |pa| pa.* = &ctx.addr;
            if (pip) |pi| pi.* = ctx.ip;
            return CURLE_OK;
        }
    }
    return CURLE_FAILED_INIT;
}

// ============================================================================
// Transfer functions (lib/transfer.c)
// ============================================================================

inline fn isHeaderSep(c: u8) bool {
    return c == ':' or c == ';';
}

pub export fn Curl_checkheaders(
    data: ?*const CurlEasy,
    thisheader: [*:0]const u8,
    thislen: usize,
) callconv(.c) ?[*:0]u8 {
    var head = Curl_xfer_get_set_headers(data);
    while (head) |node| : (head = node.next) {
        if (node.data) |hdata| {
            if (curl_strnequal(hdata, thisheader, thislen) != 0 and isHeaderSep(hdata[thislen])) {
                return hdata;
            }
        }
    }
    return null;
}

fn dataPending(data: ?*CurlEasy, rcvd_eagain: bool) bool {
    const proto = Curl_xfer_get_scheme_protocol(data);
    if ((proto & PROTO_FAMILY_FTP) != 0)
        return Curl_conn_data_pending(data, SECONDARYSOCKET);

    return (!rcvd_eagain and (proto & (CURLPROTO_SCP | CURLPROTO_SFTP)) != 0) or
        Curl_conn_data_pending(data, FIRSTSOCKET);
}

pub export fn Curl_meets_timecondition(data: ?*CurlEasy, timeofdoc: time_t) callconv(.c) bool {
    var timevalue: curl_off_t = 0;
    var timecondition: u8 = 0;
    Curl_xfer_get_timecond_info(data, &timevalue, &timecondition);

    if (timeofdoc == 0 or timevalue == 0)
        return true;

    if (timecondition == CURL_TIMECOND_IFUNMODSINCE) {
        if (timeofdoc >= timevalue) {
            if (Curl_trc_is_verbose_fn(data)) {
                Curl_infof(data, "The requested document is not old enough");
            }
            Curl_xfer_set_timecond_met(data);
            return false;
        }
    } else {
        if (timeofdoc <= timevalue) {
            if (Curl_trc_is_verbose_fn(data)) {
                Curl_infof(data, "The requested document is not new enough");
            }
            Curl_xfer_set_timecond_met(data);
            return false;
        }
    }
    return true;
}

fn xferRecvShutdown(data: ?*CurlEasy, done: *bool) CURLcode {
    if (Curl_xfer_get_conn(data) == null)
        return CURLE_FAILED_INIT;
    return Curl_cshutdn_try_once_idx(data, Curl_xfer_get_recv_idx(data), done);
}

fn xferRecvShutdownStarted(data: ?*CurlEasy) bool {
    return Curl_xfer_in_recv_shutdown(data);
}

pub export fn Curl_xfer_send_shutdown(data: ?*CurlEasy, done: *bool) callconv(.c) CURLcode {
    if (Curl_xfer_get_conn(data) == null)
        return CURLE_FAILED_INIT;
    return Curl_cshutdn_try_once_idx(data, Curl_xfer_get_send_idx(data), done);
}

fn xferRecvResp(
    data: ?*CurlEasy,
    buf: [*]u8,
    blen_in: usize,
    eos_reliable: bool,
    pnread: *usize,
) CURLcode {
    var blen = blen_in;
    pnread.* = 0;

    var req_size: curl_off_t = -1;
    var req_bytecount: curl_off_t = 0;
    var req_header: bool = false;
    var req_shutdown: bool = false;
    Curl_xfer_get_recv_resp_state(data, &req_size, &req_bytecount, &req_header, &req_shutdown);

    if (!eos_reliable and !req_header and req_size != -1) {
        blen = curlx_sotouz_range(req_size - req_bytecount, 0, blen);
    } else if (xferRecvShutdownStarted(data)) {
        blen = 0;
    }

    if (blen != 0) {
        const result = Curl_xfer_recv(data, buf, blen, pnread);
        if (result != CURLE_OK)
            return result;
    }

    if (pnread.* == 0 and req_shutdown) {
        var done: bool = false;
        const result = xferRecvShutdown(data, &done);
        if (result != CURLE_OK)
            return result;
        if (!done)
            return CURLE_AGAIN;
    }
    return CURLE_OK;
}

fn sendrecvDl(data: ?*CurlEasy) CURLcode {
    const conn = Curl_xfer_get_conn(data);
    var result: CURLcode = CURLE_OK;
    var xfer_buf: ?[*]u8 = null;
    var xfer_blen: usize = 0;
    var blen: usize = 0;
    var maxloops: c_int = 10;
    var is_multiplex: bool = false;
    var rcvd_eagain: bool = false;
    var is_eos: bool = false;
    var rate_limited: bool = false;

    result = Curl_multi_xfer_buf_borrow(data, &xfer_buf, &xfer_blen);
    if (result != CURLE_OK) {
        Curl_multi_xfer_buf_release(data, xfer_buf);
        return result;
    }

    const dl_rlimit = Curl_xfer_get_dl_rlimit(data);

    while (true) {
        if (!is_multiplex) {
            is_multiplex = Curl_conn_is_multiplex(conn, FIRSTSOCKET);
        }

        const buf = xfer_buf.?;
        var bytestoread = xfer_blen;

        if (bytestoread != 0 and headers_sock.Curl_rlimit_active(dl_rlimit)) {
            const dl_avail = headers_sock.Curl_rlimit_avail(dl_rlimit, null);
            if (dl_avail <= 0) {
                rate_limited = true;
                break;
            }
            if (dl_avail < @as(curl_off_t, @intCast(bytestoread))) {
                bytestoread = @intCast(dl_avail);
            }
        }

        rcvd_eagain = false;
        result = xferRecvResp(data, buf, bytestoread, is_multiplex, &blen);
        if (result != CURLE_OK) {
            if (result != CURLE_AGAIN) {
                Curl_multi_xfer_buf_release(data, xfer_buf);
                return result;
            }
            rcvd_eagain = true;
            result = CURLE_OK;
            if (Curl_xfer_can_skip_eagain_eos(data)) {
                blen = 0;
            } else {
                break;
            }
        }

        is_eos = (blen == 0);

        if (blen == 0) {
            result = Curl_req_stop_send_recv(data);
            if (result != CURLE_OK) {
                Curl_multi_xfer_buf_release(data, xfer_buf);
                return result;
            }
            if (Curl_xfer_is_eos_written(data))
                break;
        }

        result = Curl_xfer_write_resp(data, buf, blen, is_eos);
        if (result != CURLE_OK or Curl_xfer_is_req_done(data)) {
            Curl_multi_xfer_buf_release(data, xfer_buf);
            return result;
        }

        if ((!is_multiplex and Curl_xfer_is_download_done(data)) or is_eos) {
            Curl_xfer_clear_req_recv(data);
        }
        if (!Curl_xfer_req_want_recv(data))
            break;

        if (maxloops == 0)
            break;
        maxloops -= 1;
    }

    if (!is_eos and !rate_limited and Curl_xfer_req_want_recv(data) and
        (!rcvd_eagain or dataPending(data, rcvd_eagain)))
    {
        Curl_multi_mark_dirty(data);
        if (Curl_trc_ft_is_verbose_fn(data, &Curl_trc_feat_multi)) {
            Curl_trc_multi(data, "sendrecv_dl() no EAGAIN/pending data, mark as dirty");
        }
    }

    if (!Curl_xfer_req_want_recv(data) and Curl_xfer_req_want_send(data) and
        (Curl_xfer_is_conn_close(data) or is_multiplex))
    {
        if (Curl_trc_is_verbose_fn(data)) {
            Curl_infof(data, "we are done reading and this is set to close, stop send");
        }
        _ = Curl_req_abort_sending(data);
    }

    Curl_multi_xfer_buf_release(data, xfer_buf);
    return result;
}

fn sendrecvUl(data: ?*CurlEasy) CURLcode {
    if (!Curl_req_done_sending(data))
        return Curl_req_send_more(data);
    return CURLE_OK;
}

pub export fn Curl_sendrecv(data: ?*CurlEasy) callconv(.c) CURLcode {
    if (Curl_xfer_is_blocked(data))
        return CURLE_OK;

    if (Curl_xfer_req_want_recv(data)) {
        const result = sendrecvDl(data);
        if (result != CURLE_OK or Curl_xfer_is_req_done(data))
            return result;
    }

    if (Curl_req_want_send(data)) {
        const result = sendrecvUl(data);
        if (result != CURLE_OK)
            return result;
    }

    const pnow = Curl_pgrs_now(data);
    if (Curl_xfer_req_want_io(data)) {
        if (Curl_timeleft_now_ms(data, pnow) < 0) {
            var no_body: bool = false;
            var size: curl_off_t = -1;
            var bytecount: curl_off_t = 0;
            var has_newurl: bool = false;
            Curl_xfer_get_final_check_info(data, &no_body, &size, &bytecount, &has_newurl);
            const elapsed = Curl_pgrs_since_ms(data, null, TIMER_STARTSINGLE);
            Curl_trc_bind_c(data);
            if (size != -1) {
                Curl_failf(
                    data,
                    "Operation timed out after %lld milliseconds with %lld out of %lld bytes received",
                    @as(c_longlong, elapsed),
                    @as(c_longlong, bytecount),
                    @as(c_longlong, size),
                );
            } else {
                Curl_failf(
                    data,
                    "Operation timed out after %lld milliseconds with %lld bytes received",
                    @as(c_longlong, elapsed),
                    @as(c_longlong, bytecount),
                );
            }
            return CURLE_OPERATION_TIMEDOUT;
        }
    } else {
        var no_body: bool = false;
        var size: curl_off_t = -1;
        var bytecount: curl_off_t = 0;
        var has_newurl: bool = false;
        Curl_xfer_get_final_check_info(data, &no_body, &size, &bytecount, &has_newurl);
        if (!no_body and size != -1 and bytecount != size and !has_newurl) {
            Curl_trc_bind_c(data);
            Curl_failf(
                data,
                "transfer closed with %lld bytes remaining to read",
                @as(c_longlong, size - bytecount),
            );
            return CURLE_PARTIAL_FILE;
        }
    }

    if (!Curl_xfer_req_want_io(data))
        Curl_xfer_set_req_done(data, true);

    return Curl_pgrsCheckX(data, pnow);
}

pub export fn Curl_init_CONNECT(data: ?*CurlEasy) callconv(.c) void {
    Curl_xfer_init_connect_c(data);
}

pub export fn Curl_pretransfer(data: ?*CurlEasy) callconv(.c) CURLcode {
    return Curl_xfer_pretransfer_c(data);
}

pub export fn Curl_retry_request(data: ?*CurlEasy, url: *?[*:0]u8) callconv(.c) CURLcode {
    url.* = null;
    var retrycount: u8 = 0;
    const reason = Curl_xfer_check_retry(data, &retrycount);
    if (reason == 2) {
        if (Curl_trc_is_verbose_fn(data)) {
            Curl_infof(data, "REFUSED_STREAM, retrying a fresh connect");
        }
    }
    if (reason != 0) {
        if (retrycount >= CONN_MAX_RETRIES) {
            Curl_trc_bind_c(data);
            Curl_failf(data, "Connection died, tried %d times before giving up", @as(c_int, CONN_MAX_RETRIES));
            Curl_xfer_set_retrycount(data, 0);
            return CURLE_SEND_ERROR;
        }
        const next_count = retrycount + 1;
        Curl_xfer_set_retrycount(data, next_count);
        if (Curl_trc_is_verbose_fn(data)) {
            Curl_infof(data, "Connection died, retrying a fresh connect (retry count: %d)", @as(c_int, next_count));
        }
        const result = Curl_xfer_apply_retry(data, url);
        if (result != CURLE_OK)
            return result;
        Curl_creader_set_rewind(data, true);
    }
    return CURLE_OK;
}

fn xferSetup(data: ?*CurlEasy, send_idx: i8, recv_idx: i8, recv_size: curl_off_t) void {
    var is_header: bool = false;
    Curl_xfer_setup_fields(data, send_idx, recv_idx, recv_size, &is_header);
    if (!is_header and recv_size > 0) {
        Curl_pgrsSetDownloadSize(data, recv_size);
    }
    if (Curl_trc_ft_is_verbose_fn(data, &Curl_trc_feat_multi)) {
        Curl_trc_multi(data, "xfer_setup: recv_idx=%d, send_idx=%d", @as(c_int, recv_idx), @as(c_int, send_idx));
    }
}

pub export fn Curl_xfer_setup_nop(data: ?*CurlEasy) callconv(.c) void {
    xferSetup(data, -1, -1, -1);
}

pub export fn Curl_xfer_setup_sendrecv(data: ?*CurlEasy, sockindex: i8, recv_size: curl_off_t) callconv(.c) void {
    xferSetup(data, sockindex, sockindex, recv_size);
}

pub export fn Curl_xfer_setup_send(data: ?*CurlEasy, sockindex: i8) callconv(.c) void {
    xferSetup(data, sockindex, -1, -1);
}

pub export fn Curl_xfer_setup_recv(data: ?*CurlEasy, sockindex: i8, recv_size: curl_off_t) callconv(.c) void {
    xferSetup(data, -1, sockindex, recv_size);
}

pub export fn Curl_xfer_set_shutdown(data: ?*CurlEasy, shutdown: bool, ignore_errors: bool) callconv(.c) void {
    Curl_xfer_set_shutdown_fields(data, shutdown, ignore_errors);
}

pub export fn Curl_xfer_write_resp(
    data: ?*CurlEasy,
    buf: ?[*]const u8,
    blen: usize,
    is_eos: bool,
) callconv(.c) CURLcode {
    var handled: bool = false;
    var result = Curl_xfer_scheme_write_resp(data, buf, blen, is_eos, &handled);
    if (!handled) {
        if (blen != 0 or is_eos) {
            var cwtype: c_int = CLIENTWRITE_BODY;
            if (is_eos)
                cwtype |= CLIENTWRITE_EOS;
            result = Curl_client_write(data, cwtype, buf, blen);
        }
    }

    if (result == CURLE_OK and is_eos) {
        Curl_xfer_mark_eos_written(data);
    }
    if (Curl_trc_ft_is_verbose_fn(data, &Curl_trc_feat_write)) {
        Curl_trc_write(
            data,
            "xfer_write_resp(len=%zu, eos=%d) -> %d",
            blen,
            @as(c_int, @intFromBool(is_eos)),
            @as(c_int, @intCast(result)),
        );
    }
    return result;
}

pub export fn Curl_xfer_write_is_paused(data: ?*CurlEasy) callconv(.c) bool {
    return Curl_xfer_is_cwriter_paused(data);
}

pub export fn Curl_xfer_write_resp_hd(
    data: ?*CurlEasy,
    hd0: [*:0]const u8,
    hdlen: usize,
    is_eos: bool,
) callconv(.c) CURLcode {
    var handled: bool = false;
    const result = Curl_xfer_scheme_write_resp_hd(data, hd0, hdlen, is_eos, &handled);
    if (handled)
        return result;
    return Curl_xfer_write_resp(data, hd0, hdlen, is_eos);
}

pub export fn Curl_xfer_write_done(data: ?*CurlEasy, premature: bool) callconv(.c) CURLcode {
    _ = premature;
    return Curl_cw_out_done(data);
}

pub export fn Curl_xfer_needs_flush(data: ?*CurlEasy) callconv(.c) bool {
    return Curl_conn_needs_flush(data, Curl_xfer_get_send_idx(data));
}

pub export fn Curl_xfer_flush(data: ?*CurlEasy) callconv(.c) CURLcode {
    return Curl_conn_flush(data, Curl_xfer_get_send_idx(data));
}

pub export fn Curl_xfer_send(
    data: ?*CurlEasy,
    buf: ?*const anyopaque,
    blen: usize,
    eos: bool,
    pnwritten: *usize,
) callconv(.c) CURLcode {
    var result = Curl_conn_send(data, Curl_xfer_get_send_idx(data), buf, blen, eos, pnwritten);
    if (result == CURLE_AGAIN) {
        result = CURLE_OK;
        pnwritten.* = 0;
    } else if (result == CURLE_OK and pnwritten.* != 0) {
        Curl_xfer_add_request_size(data, pnwritten.*);
    }
    return result;
}

pub export fn Curl_xfer_recv(
    data: ?*CurlEasy,
    buf: [*]u8,
    blen_in: usize,
    pnrcvd: *usize,
) callconv(.c) CURLcode {
    var blen = blen_in;
    const buf_size = Curl_xfer_get_buffer_size(data);
    if (buf_size < blen)
        blen = buf_size;
    return Curl_conn_recv(data, Curl_xfer_get_recv_idx(data), buf, blen, pnrcvd);
}

pub export fn Curl_xfer_send_close(data: ?*CurlEasy) callconv(.c) CURLcode {
    Curl_conn_ev_data_done_send(data);
    return CURLE_OK;
}

pub export fn Curl_xfer_is_blocked(data: ?*CurlEasy) callconv(.c) bool {
    const want_send = Curl_xfer_req_want_send(data);
    const want_recv = Curl_xfer_req_want_recv(data);
    if (!want_send)
        return want_recv and Curl_xfer_recv_is_paused(data);
    if (!want_recv)
        return want_send and Curl_xfer_send_is_paused(data);
    return Curl_xfer_recv_is_paused(data) and Curl_xfer_send_is_paused(data);
}

pub export fn Curl_xfer_send_is_paused(data: ?*CurlEasy) callconv(.c) bool {
    return headers_sock.Curl_rlimit_is_blocked(Curl_xfer_get_ul_rlimit(data));
}

pub export fn Curl_xfer_recv_is_paused(data: ?*CurlEasy) callconv(.c) bool {
    return headers_sock.Curl_rlimit_is_blocked(Curl_xfer_get_dl_rlimit(data));
}

pub export fn Curl_xfer_pause_send(data: ?*CurlEasy, enable: bool) callconv(.c) CURLcode {
    var result: CURLcode = CURLE_OK;
    headers_sock.Curl_rlimit_block(Curl_xfer_get_ul_rlimit(data), enable, Curl_pgrs_now(data));
    if (!enable and Curl_creader_is_paused(data))
        result = Curl_creader_unpause(data);
    Curl_pgrsSendPause(data, enable);
    return result;
}

pub export fn Curl_xfer_pause_recv(data: ?*CurlEasy, enable: bool) callconv(.c) CURLcode {
    var result: CURLcode = CURLE_OK;
    headers_sock.Curl_rlimit_block(Curl_xfer_get_dl_rlimit(data), enable, Curl_pgrs_now(data));
    if (!enable and Curl_xfer_is_cwriter_paused(data))
        result = Curl_cwriter_unpause(data);
    _ = Curl_conn_ev_data_pause(data, enable);
    Curl_pgrsRecvPause(data, enable);
    return result;
}

pub export fn Curl_xfer_is_secure(data: ?*CurlEasy) callconv(.c) bool {
    return Curl_xfer_check_is_secure(data);
}

// ============================================================================
// Unit Tests
// ============================================================================

test "Curl_parse_interface parses dev, iface, and host variants" {
    var dev: ?[*:0]u8 = null;
    var iface: ?[*:0]u8 = null;
    var host: ?[*:0]u8 = null;

    // Plain device/host
    try std.testing.expectEqual(CURLE_OK, Curl_parse_interface("eth0", &dev, &iface, &host));
    try std.testing.expect(dev != null);
    try std.testing.expect(iface == null);
    try std.testing.expect(host == null);
    try std.testing.expectEqualStrings("eth0", std.mem.span(dev.?));
    mem.freeTyped(dev.?);

    // if!<iface>
    try std.testing.expectEqual(CURLE_OK, Curl_parse_interface("if!wlan0", &dev, &iface, &host));
    try std.testing.expect(dev == null);
    try std.testing.expect(iface != null);
    try std.testing.expect(host == null);
    try std.testing.expectEqualStrings("wlan0", std.mem.span(iface.?));
    mem.freeTyped(iface.?);

    // host!<host>
    try std.testing.expectEqual(CURLE_OK, Curl_parse_interface("host!127.0.0.1", &dev, &iface, &host));
    try std.testing.expect(dev == null);
    try std.testing.expect(iface == null);
    try std.testing.expect(host != null);
    try std.testing.expectEqualStrings("127.0.0.1", std.mem.span(host.?));
    mem.freeTyped(host.?);

    // ifhost!<iface>!<host>
    try std.testing.expectEqual(CURLE_OK, Curl_parse_interface("ifhost!eth0!10.0.0.1", &dev, &iface, &host));
    try std.testing.expect(dev == null);
    try std.testing.expect(iface != null);
    try std.testing.expect(host != null);
    try std.testing.expectEqualStrings("eth0", std.mem.span(iface.?));
    try std.testing.expectEqualStrings("10.0.0.1", std.mem.span(host.?));
    mem.freeTyped(iface.?);
    mem.freeTyped(host.?);

    // Invalid empty forms
    try std.testing.expectEqual(CURLE_BAD_FUNCTION_ARGUMENT, Curl_parse_interface("", &dev, &iface, &host));
    try std.testing.expectEqual(CURLE_BAD_FUNCTION_ARGUMENT, Curl_parse_interface("if!", &dev, &iface, &host));
    try std.testing.expectEqual(CURLE_BAD_FUNCTION_ARGUMENT, Curl_parse_interface("host!", &dev, &iface, &host));
    try std.testing.expectEqual(CURLE_BAD_FUNCTION_ARGUMENT, Curl_parse_interface("ifhost!eth0!", &dev, &iface, &host));
}

test "sockaddr2string formats AF_UNIX and rejects unknown family" {
    var sa_buf: [32]u8 align(8) = std.mem.zeroes([32]u8);
    if (comptime builtin.os.tag.isDarwin()) {
        sa_buf[1] = @intCast(AF_UNIX);
    } else {
        std.mem.writeInt(u16, sa_buf[0..2], @intCast(AF_UNIX), .little);
    }
    const path = "/var/run/test.sock";
    @memcpy(sa_buf[2 .. 2 + path.len], path);

    var addr: [MAX_IPADR_LEN]u8 = std.mem.zeroes([MAX_IPADR_LEN]u8);
    var port: u16 = 999;
    try std.testing.expectEqual(CURLE_OK, sockaddr2string(&sa_buf, @intCast(2 + path.len + 1), &addr, &port));
    try std.testing.expectEqual(@as(u16, 0), port);
    try std.testing.expectEqualStrings(path, std.mem.sliceTo(&addr, 0));

    // Unknown family
    @memset(&sa_buf, 0);
    try std.testing.expectEqual(CURLE_UNSUPPORTED_PROTOCOL, sockaddr2string(&sa_buf, 16, &addr, &port));
}
