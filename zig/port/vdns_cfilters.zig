const std = @import("std");
const builtin = @import("builtin");
const backend_options = @import("backend_options");
const mem = @import("mem.zig");
const containers = @import("containers.zig");
const collections = @import("collections.zig");
const io_buffers = @import("io_buffers.zig");
const curlx_time_net = @import("curlx_time_net.zig");
const headers_sock = @import("headers_sock.zig");
const netrc_addr_idn = @import("netrc_addr_idn.zig");

pub const use_ares = if (@hasDecl(backend_options, "ares")) backend_options.ares else false;
pub const use_httpsrr = if (@hasDecl(backend_options, "httpsrr")) backend_options.httpsrr else false;
pub const use_resolv_ares = if (@hasDecl(backend_options, "use_resolv_ares")) backend_options.use_resolv_ares else false;
pub const use_resolv_threaded = if (@hasDecl(backend_options, "use_resolv_threaded")) backend_options.use_resolv_threaded else true;

pub const CURLcode = c_uint;
pub const CURLE_OK: CURLcode = 0;
pub const CURLE_FAILED_INIT: CURLcode = 2;
pub const CURLE_COULDNT_RESOLVE_PROXY: CURLcode = 5;
pub const CURLE_COULDNT_RESOLVE_HOST: CURLcode = 6;
pub const CURLE_WRITE_ERROR: CURLcode = 23;
pub const CURLE_OUT_OF_MEMORY: CURLcode = 27;
pub const CURLE_BAD_FUNCTION_ARGUMENT: CURLcode = 43;
pub const CURLE_SEND_ERROR: CURLcode = 55;
pub const CURLE_RECV_ERROR: CURLcode = 56;
pub const CURLE_AGAIN: CURLcode = 81;

pub const timediff_t = curlx_time_net.timediff_t;
pub const Curltime = curlx_time_net.Curltime;
pub const curl_socket_t = if (builtin.os.tag == .windows) u64 else c_int;
pub const CURL_SOCKET_BAD: curl_socket_t = if (builtin.os.tag == .windows)
    std.math.maxInt(u64)
else
    -1;

pub const CURL_LOG_LVL_NONE: c_int = 0;
pub const CURL_LOG_LVL_INFO: c_int = 1;

pub const CURL_DNSQ_A: u8 = 1 << 0;
pub const CURL_DNSQ_AAAA: u8 = 1 << 1;

pub const TRNSPRT_TCP: u8 = 3;
pub const TRNSPRT_UDP: u8 = 4;

pub const PF_UNSPEC: c_int = 0;
pub const PF_INET: c_int = 2;
pub const AF_INET: c_int = curlx_time_net.AF_INET;
pub const AF_INET6: c_int = curlx_time_net.AF_INET6;
pub const SOCK_STREAM: c_int = 1;
pub const SOCK_DGRAM: c_int = 2;
pub const AI_NUMERICHOST: c_int = 4;

pub const CURL_POLL_IN: c_int = 1;
pub const CURL_POLL_OUT: c_int = 2;

pub const CF_TYPE_PROXY: c_int = 1 << 3;
pub const CF_TYPE_SETUP: c_int = 1 << 5;

pub const CF_CTRL_FLUSH: c_int = 258;
pub const CF_QUERY_NEED_FLUSH: c_int = 7;

pub const DYN_HAXPROXY: usize = 2048;

pub const CLIENTWRITE_BODY: c_int = 1 << 0;
pub const CLIENTWRITE_EOS: c_int = 1 << 7;
pub const CURL_CW_CONTENT_DECODE: c_uint = 4;

pub const MAX_IPADR_LEN: usize = 46;

// ============================================================================
// Shared C ABI Struct Layouts & External Declarations
// ============================================================================

pub const Curl_easy = opaque {};
pub const connectdata = opaque {};
pub const easy_pollset = opaque {};

pub const curl_trc_feat = extern struct {
    name: [*:0]const u8,
    log_level: c_int,
};

extern var Curl_trc_feat_dns: curl_trc_feat;
extern var Curl_trc_feat_write: curl_trc_feat;

extern fn Curl_infof(data: ?*Curl_easy, fmt: [*:0]const u8, ...) callconv(.c) void;
extern fn Curl_failf(data: ?*Curl_easy, fmt: [*:0]const u8, ...) callconv(.c) void;
extern fn Curl_trc_dns(data: ?*Curl_easy, fmt: [*:0]const u8, ...) callconv(.c) void;
extern fn Curl_trc_write(data: ?*Curl_easy, fmt: [*:0]const u8, ...) callconv(.c) void;
extern fn Curl_trc_cf_infof(data: ?*Curl_easy, cf: *const Curl_cfilter, fmt: [*:0]const u8, ...) callconv(.c) void;

inline fn trcCf(data: ?*Curl_easy, cf: *const Curl_cfilter, fmt: [*:0]const u8, args: anytype) void {
    if (data != null and cf.cft.log_level >= CURL_LOG_LVL_INFO) {
        @call(.auto, Curl_trc_cf_infof, .{ data, cf, fmt } ++ args);
    }
}

inline fn trcWrite(data: ?*Curl_easy, fmt: [*:0]const u8, args: anytype) void {
    if (data != null and Curl_trc_feat_write.log_level >= CURL_LOG_LVL_INFO) {
        @call(.auto, Curl_trc_write, .{ data, fmt } ++ args);
    }
}

inline fn trcDns(data: ?*Curl_easy, fmt: [*:0]const u8, args: anytype) void {
    if (data != null and Curl_trc_feat_dns.log_level >= CURL_LOG_LVL_INFO) {
        @call(.auto, Curl_trc_dns, .{ data, fmt } ++ args);
    }
}

inline fn failf(data: ?*Curl_easy, fmt: [*:0]const u8, args: anytype) void {
    if (data != null) {
        @call(.auto, Curl_failf, .{ data, fmt } ++ args);
    }
}

pub const CAddrinfo = extern struct {
    ai_flags: c_int = 0,
    ai_family: c_int = 0,
    ai_socktype: c_int = 0,
    ai_protocol: c_int = 0,
    ai_addrlen: usize = 0,
    ai_ptr1: ?*anyopaque = null,
    ai_ptr2: ?*anyopaque = null,
    ai_next: ?*anyopaque = null,
};

pub const Curl_addrinfo = netrc_addr_idn.Curl_addrinfo;

extern fn Curl_getaddrinfo_ex(
    nodename: ?[*:0]const u8,
    servname: ?[*:0]const u8,
    hints: *const CAddrinfo,
    result: *?*Curl_addrinfo,
) callconv(.c) c_int;
extern fn Curl_freeaddrinfo(cahead: ?*Curl_addrinfo) callconv(.c) void;
extern fn Curl_is_ipv4addr(address: [*:0]const u8) callconv(.c) bool;
extern fn curl_msnprintf(buffer: [*]u8, maxlength: usize, format: [*:0]const u8, ...) callconv(.c) c_int;

pub const Curl_peer = if (builtin.os.tag == .windows)
    extern struct {
        scheme: ?*const anyopaque,
        hostname: ?[*:0]u8,
        zoneid: ?[*:0]u8,
        refcount: u32,
        scopeid: u32,
        port: u16,
        _pad0: [2]u8 = .{ 0, 0 },
        flags: c_uint,
        user_hostname: [1]u8,
        _pad1: [7]u8 = .{ 0, 0, 0, 0, 0, 0, 0 },

        pub inline fn isUnixSocket(self: *const @This()) bool {
            return (self.flags & 0x01) != 0;
        }
    }
else
    extern struct {
        scheme: ?*const anyopaque,
        hostname: ?[*:0]u8,
        zoneid: ?[*:0]u8,
        refcount: u32,
        scopeid: u32,
        port: u16,
        flags: u8,
        user_hostname: [1]u8,
        _pad: [4]u8 = .{ 0, 0, 0, 0 },

        pub inline fn isUnixSocket(self: *const @This()) bool {
            return (self.flags & 0x01) != 0;
        }
    };

pub const MAX_HTTPSRR_ALPNS: usize = 4;

pub const Curl_https_rrinfo = extern struct {
    target: ?[*:0]u8,
    ipv4hints: ?[*]u8,
    ipv4hints_len: usize,
    echconfiglist: ?[*]u8,
    echconfiglist_len: usize,
    ipv6hints: ?[*]u8,
    ipv6hints_len: usize,
    alpns: [MAX_HTTPSRR_ALPNS]u8,
    port: u16,
    priority: u16,
    flags: u32,
    _pad: u32 = 0,

    pub inline fn noDefAlpn(self: *const Curl_https_rrinfo) bool {
        return (self.flags & 1) != 0;
    }

    pub inline fn setNoDefAlpn(self: *Curl_https_rrinfo, val: bool) void {
        if (val) self.flags |= 1 else self.flags &= ~@as(u32, 1);
    }

    pub inline fn mandatory(self: *const Curl_https_rrinfo) bool {
        return (self.flags & 2) != 0;
    }

    pub inline fn setMandatory(self: *Curl_https_rrinfo, val: bool) void {
        if (val) self.flags |= 2 else self.flags &= ~@as(u32, 2);
    }

    pub inline fn portSet(self: *const Curl_https_rrinfo) bool {
        return (self.flags & 4) != 0;
    }

    pub inline fn setPortSet(self: *Curl_https_rrinfo, val: bool) void {
        if (val) self.flags |= 4 else self.flags &= ~@as(u32, 4);
    }
};

pub const CURL_ASYN_ITEM_DESC_LEN: usize = 64;

pub const async_thrdd_item = extern struct {
    res: ?*Curl_addrinfo = null,
    description: [CURL_ASYN_ITEM_DESC_LEN]u8 = @splat(0),
    sockerr: c_int = 0,
    mid: u32 = 0,
    resolv_id: u32 = 0,
    port: u16 = 0,
    transport: u8 = 0,
    dns_queries: u8 = 0,
    negative: bool = false,
    hostname: [1]u8 = .{0},

    pub inline fn hostnamePtr(self: *async_thrdd_item) [*:0]u8 {
        return @ptrCast(&self.hostname);
    }

    pub inline fn hostnameConstPtr(self: *const async_thrdd_item) [*:0]const u8 {
        return @ptrCast(&self.hostname);
    }

    pub inline fn descriptionPtr(self: *async_thrdd_item) [*:0]u8 {
        return @ptrCast(&self.description);
    }
};

pub const async_ares_ctx = extern struct {
    channel: ?*anyopaque = null,
    ares_status: c_int = 0,
    result: CURLcode = CURLE_OK,
    flags: c_uint = 0,

    pub const FLAG_TRANSIENT_ERR: c_uint = 1 << 0;

    pub inline fn transientErr(self: *const async_ares_ctx) bool {
        return (self.flags & FLAG_TRANSIENT_ERR) != 0;
    }

    pub inline fn setTransientErr(self: *async_ares_ctx, val: bool) void {
        if (val) {
            self.flags |= FLAG_TRANSIENT_ERR;
        } else {
            self.flags &= ~FLAG_TRANSIENT_ERR;
        }
    }
};

pub const async_thrdd_rr_ctx = extern struct {
    channel: ?*anyopaque = null,
};

pub const async_thrdd_ctx = extern struct {
    res_A: ?*async_thrdd_item = null,
    res_AAAA: ?*async_thrdd_item = null,
    rr: if (use_httpsrr and use_ares) async_thrdd_rr_ctx else void = if (use_httpsrr and use_ares) .{} else {},
    flags: c_uint = 0,

    pub const FLAG_PROCESSED_A: c_uint = 1 << 0;
    pub const FLAG_PROCESSED_AAAA: c_uint = 1 << 1;
    pub const FLAG_TRANSIENT_ERR: c_uint = 1 << 2;

    pub inline fn isProcessedA(self: *const async_thrdd_ctx) bool {
        return (self.flags & FLAG_PROCESSED_A) != 0;
    }

    pub inline fn processedA(self: *const async_thrdd_ctx) bool {
        return (self.flags & FLAG_PROCESSED_A) != 0;
    }

    pub inline fn setProcessedA(self: *async_thrdd_ctx, val: bool) void {
        if (val) {
            self.flags |= FLAG_PROCESSED_A;
        } else {
            self.flags &= ~FLAG_PROCESSED_A;
        }
    }

    pub inline fn isProcessedAAAA(self: *const async_thrdd_ctx) bool {
        return (self.flags & FLAG_PROCESSED_AAAA) != 0;
    }

    pub inline fn processedAAAA(self: *const async_thrdd_ctx) bool {
        return (self.flags & FLAG_PROCESSED_AAAA) != 0;
    }

    pub inline fn setProcessedAAAA(self: *async_thrdd_ctx, val: bool) void {
        if (val) {
            self.flags |= FLAG_PROCESSED_AAAA;
        } else {
            self.flags &= ~FLAG_PROCESSED_AAAA;
        }
    }

    pub inline fn transientErr(self: *const async_thrdd_ctx) bool {
        return (self.flags & FLAG_TRANSIENT_ERR) != 0;
    }

    pub inline fn setTransientErr(self: *async_thrdd_ctx, val: bool) void {
        if (val) {
            self.flags |= FLAG_TRANSIENT_ERR;
        } else {
            self.flags &= ~FLAG_TRANSIENT_ERR;
        }
    }
};

pub const Curl_resolv_async = extern struct {
    next: ?*Curl_resolv_async = null,
    peer: ?*Curl_peer = null,
    ai_A: ?*Curl_addrinfo = null,
    ai_AAAA: ?*Curl_addrinfo = null,
    httpsrr: if (use_httpsrr) ?*Curl_https_rrinfo else void = if (use_httpsrr) null else {},
    ares: if (use_resolv_ares) async_ares_ctx else void = if (use_resolv_ares) .{} else {},
    thrdd: if (use_resolv_threaded) async_thrdd_ctx else void = if (use_resolv_threaded) .{} else {},
    doh: ?*anyopaque = null,
    start: Curltime = .{ .tv_sec = 0, .tv_usec = 0 },
    interval_end: timediff_t = 0,
    timeout_ms: timediff_t = 0,
    result: CURLcode = CURLE_OK,
    poll_interval: u32 = 0,
    id: u32 = 0,
    dns_queries: u8 = 0,
    dns_responses: u8 = 0,
    transport: u8 = 0,
    queries_ongoing: u8 = 0,
    flags: c_uint = 0,

    pub const FLAG_IS_IPADDR: c_uint = 1 << 0;
    pub const FLAG_IS_IPV4ADDR: c_uint = 1 << 1;
    pub const FLAG_FOR_PROXY: c_uint = 1 << 2;
    pub const FLAG_DONE: c_uint = 1 << 3;
    pub const FLAG_SHUTDOWN: c_uint = 1 << 4;
    pub const FLAG_NEGATIVE_ANSWER: c_uint = 1 << 5;

    pub inline fn isIpaddr(self: *const Curl_resolv_async) bool {
        return (self.flags & FLAG_IS_IPADDR) != 0;
    }

    pub inline fn setIsIpaddr(self: *Curl_resolv_async, val: bool) void {
        if (val) {
            self.flags |= FLAG_IS_IPADDR;
        } else {
            self.flags &= ~FLAG_IS_IPADDR;
        }
    }

    pub inline fn isIpv4Addr(self: *const Curl_resolv_async) bool {
        return (self.flags & FLAG_IS_IPV4ADDR) != 0;
    }

    pub inline fn setIsIpv4Addr(self: *Curl_resolv_async, val: bool) void {
        if (val) {
            self.flags |= FLAG_IS_IPV4ADDR;
        } else {
            self.flags &= ~FLAG_IS_IPV4ADDR;
        }
    }

    pub inline fn forProxy(self: *const Curl_resolv_async) bool {
        return (self.flags & FLAG_FOR_PROXY) != 0;
    }

    pub inline fn isForProxy(self: *const Curl_resolv_async) bool {
        return (self.flags & FLAG_FOR_PROXY) != 0;
    }

    pub inline fn setForProxy(self: *Curl_resolv_async, val: bool) void {
        if (val) {
            self.flags |= FLAG_FOR_PROXY;
        } else {
            self.flags &= ~FLAG_FOR_PROXY;
        }
    }

    pub inline fn isDone(self: *const Curl_resolv_async) bool {
        return (self.flags & FLAG_DONE) != 0;
    }

    pub inline fn setDone(self: *Curl_resolv_async, val: bool) void {
        if (val) {
            self.flags |= FLAG_DONE;
        } else {
            self.flags &= ~FLAG_DONE;
        }
    }

    pub inline fn isShutdown(self: *const Curl_resolv_async) bool {
        return (self.flags & FLAG_SHUTDOWN) != 0;
    }

    pub inline fn setShutdown(self: *Curl_resolv_async, val: bool) void {
        if (val) {
            self.flags |= FLAG_SHUTDOWN;
        } else {
            self.flags &= ~FLAG_SHUTDOWN;
        }
    }

    pub inline fn negativeAnswer(self: *const Curl_resolv_async) bool {
        return (self.flags & FLAG_NEGATIVE_ANSWER) != 0;
    }

    pub inline fn setNegativeAnswer(self: *Curl_resolv_async, val: bool) void {
        if (val) {
            self.flags |= FLAG_NEGATIVE_ANSWER;
        } else {
            self.flags &= ~FLAG_NEGATIVE_ANSWER;
        }
    }
};

extern fn Curl_pgrs_now(data: ?*Curl_easy) callconv(.c) *const Curltime;
extern fn Curl_timeleft_ms(data: ?*Curl_easy) callconv(.c) timediff_t;
extern fn Curl_async_thrdd_shutdown(data: ?*Curl_easy, async_ctx: *Curl_resolv_async) callconv(.c) void;
extern fn Curl_async_thrdd_destroy(data: ?*Curl_easy, async_ctx: *Curl_resolv_async) callconv(.c) void;
extern fn Curl_async_ares_shutdown(data: ?*Curl_easy, async_ctx: *Curl_resolv_async) callconv(.c) void;
extern fn Curl_async_ares_destroy(data: ?*Curl_easy, async_ctx: *Curl_resolv_async) callconv(.c) void;
extern fn Curl_httpsrr_destroy(hinfo: ?*Curl_https_rrinfo) callconv(.c) void;
extern fn Curl_doh_cleanup(data: ?*Curl_easy, async_ctx: *Curl_resolv_async) callconv(.c) void;
extern fn Curl_peer_unlink(ppeer: *?*Curl_peer) callconv(.c) void;

pub const Curl_cftype = extern struct {
    name: [*:0]const u8,
    flags: c_int,
    log_level: c_int,
    destroy: *const fn (cf: *Curl_cfilter, data: ?*Curl_easy) callconv(.c) void,
    do_connect: *const fn (cf: *Curl_cfilter, data: ?*Curl_easy, done: *bool) callconv(.c) CURLcode,
    do_shutdown: *const fn (cf: *Curl_cfilter, data: ?*Curl_easy, done: *bool) callconv(.c) CURLcode,
    adjust_pollset: *const fn (cf: *Curl_cfilter, data: ?*Curl_easy, ps: *easy_pollset) callconv(.c) CURLcode,
    has_data_pending: *const fn (cf: *Curl_cfilter, data: ?*const Curl_easy) callconv(.c) bool,
    do_send: *const fn (cf: *Curl_cfilter, data: ?*Curl_easy, buf: [*]const u8, len: usize, eos: bool, pnwritten: *usize) callconv(.c) CURLcode,
    do_recv: *const fn (cf: *Curl_cfilter, data: ?*Curl_easy, buf: [*]u8, len: usize, pnread: *usize) callconv(.c) CURLcode,
    cntrl: *const fn (cf: *Curl_cfilter, data: ?*Curl_easy, event: c_int, arg1: c_int, arg2: ?*anyopaque) callconv(.c) CURLcode,
    is_alive: *const fn (cf: *Curl_cfilter, data: ?*Curl_easy, input_pending: *bool) callconv(.c) bool,
    keep_alive: *const fn (cf: *Curl_cfilter, data: ?*Curl_easy) callconv(.c) CURLcode,
    query: *const fn (cf: *Curl_cfilter, data: ?*Curl_easy, query_id: c_int, pres1: ?*c_int, pres2: ?*anyopaque) callconv(.c) CURLcode,
};

pub const Curl_cfilter = if (builtin.os.tag == .windows)
    extern struct {
        cft: *const Curl_cftype,
        next: ?*Curl_cfilter,
        ctx: ?*anyopaque,
        conn: ?*connectdata,
        sockindex: i8,
        _pad: [3]u8 = .{ 0, 0, 0 },
        flags: c_uint,

        pub inline fn isConnected(self: *const @This()) bool {
            return (self.flags & 0x01) != 0;
        }

        pub inline fn setConnected(self: *@This(), val: bool) void {
            if (val) {
                self.flags |= 0x01;
            } else {
                self.flags &= ~@as(c_uint, 0x01);
            }
        }

        pub inline fn isShutdown(self: *const @This()) bool {
            return (self.flags & 0x02) != 0;
        }

        pub inline fn setShutdown(self: *@This(), val: bool) void {
            if (val) {
                self.flags |= 0x02;
            } else {
                self.flags &= ~@as(c_uint, 0x02);
            }
        }
    }
else
    extern struct {
        cft: *const Curl_cftype,
        next: ?*Curl_cfilter,
        ctx: ?*anyopaque,
        conn: ?*connectdata,
        sockindex: i8,
        flags: u8,
        _pad: [6]u8 = .{ 0, 0, 0, 0, 0, 0 },

        pub inline fn isConnected(self: *const @This()) bool {
            return (self.flags & 0x01) != 0;
        }

        pub inline fn setConnected(self: *@This(), val: bool) void {
            if (val) {
                self.flags |= 0x01;
            } else {
                self.flags &= ~@as(u8, 0x01);
            }
        }

        pub inline fn isShutdown(self: *const @This()) bool {
            return (self.flags & 0x02) != 0;
        }

        pub inline fn setShutdown(self: *@This(), val: bool) void {
            if (val) {
                self.flags |= 0x02;
            } else {
                self.flags &= ~@as(u8, 0x02);
            }
        }
    };

extern fn Curl_cf_def_connect(cf: *Curl_cfilter, data: ?*Curl_easy, done: *bool) callconv(.c) CURLcode;
extern fn Curl_cf_def_shutdown(cf: *Curl_cfilter, data: ?*Curl_easy, done: *bool) callconv(.c) CURLcode;
extern fn Curl_cf_def_adjust_pollset(cf: *Curl_cfilter, data: ?*Curl_easy, ps: *easy_pollset) callconv(.c) CURLcode;
extern fn Curl_cf_def_data_pending(cf: *Curl_cfilter, data: ?*const Curl_easy) callconv(.c) bool;
extern fn Curl_cf_def_send(cf: *Curl_cfilter, data: ?*Curl_easy, buf: [*]const u8, len: usize, eos: bool, pnwritten: *usize) callconv(.c) CURLcode;
extern fn Curl_cf_def_recv(cf: *Curl_cfilter, data: ?*Curl_easy, buf: [*]u8, len: usize, pnread: *usize) callconv(.c) CURLcode;
extern fn Curl_cf_def_cntrl(cf: *Curl_cfilter, data: ?*Curl_easy, event: c_int, arg1: c_int, arg2: ?*anyopaque) callconv(.c) CURLcode;
extern fn Curl_cf_def_conn_is_alive(cf: *Curl_cfilter, data: ?*Curl_easy, input_pending: *bool) callconv(.c) bool;
extern fn Curl_cf_def_conn_keep_alive(cf: *Curl_cfilter, data: ?*Curl_easy) callconv(.c) CURLcode;
extern fn Curl_cf_def_query(cf: *Curl_cfilter, data: ?*Curl_easy, query_id: c_int, pres1: ?*c_int, pres2: ?*anyopaque) callconv(.c) CURLcode;

extern fn Curl_cf_create(pcf: *?*Curl_cfilter, cft: *const Curl_cftype, ctx: ?*anyopaque) callconv(.c) CURLcode;
extern fn Curl_conn_cf_add(data: ?*Curl_easy, conn: ?*connectdata, index: i8, cf: *Curl_cfilter) callconv(.c) void;
extern fn Curl_conn_cf_insert_after(cf_at: *Curl_cfilter, cf_new: *Curl_cfilter) callconv(.c) void;
extern fn Curl_conn_cf_send(cf: *Curl_cfilter, data: ?*Curl_easy, buf: [*]const u8, len: usize, eos: bool, pnwritten: *usize) callconv(.c) CURLcode;
extern fn Curl_conn_cf_recv(cf: *Curl_cfilter, data: ?*Curl_easy, buf: [*]u8, len: usize, pnread: *usize) callconv(.c) CURLcode;
extern fn Curl_conn_cf_get_socket(cf: *Curl_cfilter, data: ?*Curl_easy) callconv(.c) curl_socket_t;
extern fn Curl_conn_cf_get_ip_info(cf: ?*Curl_cfilter, data: ?*Curl_easy, is_ipv6: *bool, ipquad: *ip_quadruple) callconv(.c) CURLcode;
extern fn Curl_conn_is_connected(conn: ?*connectdata, sockindex: i8) callconv(.c) bool;
extern fn Curl_conn_get_first_peer(conn: ?*connectdata, sockindex: i8) callconv(.c) *Curl_peer;
extern fn Curl_pollset_change(data: ?*Curl_easy, ps: *easy_pollset, sock: curl_socket_t, add_flags: c_int, remove_flags: c_int) callconv(.c) CURLcode;
extern fn Curl_cf_recv_bufq(cf: *Curl_cfilter, data: ?*Curl_easy, bufq: *io_buffers.bufq, maxlen: usize, pnread: *usize) callconv(.c) CURLcode;
extern fn Curl_cf_send_bufq(cf: *Curl_cfilter, data: ?*Curl_easy, bufq: *io_buffers.bufq, buf: ?[*]const u8, blen: usize, pnwritten: *usize) callconv(.c) CURLcode;
extern fn curlx_dyn_init(s: *containers.dynbuf, toobig: usize) callconv(.c) void;
extern fn curlx_dyn_free(s: *containers.dynbuf) callconv(.c) void;
extern fn curlx_dyn_reset(s: *containers.dynbuf) callconv(.c) void;
extern fn curlx_dyn_tail(s: *containers.dynbuf, trail: usize) callconv(.c) CURLcode;
extern fn curlx_dyn_addn(s: *containers.dynbuf, mem_ptr: ?*const anyopaque, len: usize) callconv(.c) CURLcode;
extern fn curlx_dyn_uptr(s: *const containers.dynbuf) callconv(.c) ?[*]u8;
extern fn curlx_dyn_len(s: *const containers.dynbuf) callconv(.c) usize;
extern fn curlx_dyn_addf(s: *containers.dynbuf, fmt: [*:0]const u8, ...) callconv(.c) CURLcode;
extern fn Curl_u8_strset_get(set: *collections.u8_strset, id: u8) callconv(.c) ?[*:0]const u8;

pub const ip_quadruple = extern struct {
    remote_ip: [MAX_IPADR_LEN]u8,
    local_ip: [MAX_IPADR_LEN]u8,
    remote_port: u16,
    local_port: u16,
    transport: u8,
    _pad: [1]u8 = .{0},
};

pub const Curl_cwtype = extern struct {
    name: [*:0]const u8,
    alias: ?[*:0]const u8,
    flags: u8,
    do_init: *const fn (data: ?*Curl_easy, writer: *Curl_cwriter) callconv(.c) CURLcode,
    do_write: *const fn (data: ?*Curl_easy, writer: *Curl_cwriter, wtype: c_int, buf: [*]const u8, nbytes: usize) callconv(.c) CURLcode,
    do_flush: *const fn (data: ?*Curl_easy, writer: *Curl_cwriter) callconv(.c) CURLcode,
    do_close: *const fn (data: ?*Curl_easy, writer: *Curl_cwriter) callconv(.c) void,
    cwriter_size: usize,
};

pub const Curl_cwriter = extern struct {
    cwt: *const Curl_cwtype,
    next: ?*Curl_cwriter,
    ctx: ?*anyopaque,
    phase: c_uint,
    _pad: c_uint = 0,
};

extern fn Curl_cwriter_count(data: ?*Curl_easy, phase: c_uint) callconv(.c) usize;

inline fn cwriterWrite(data: ?*Curl_easy, writer: ?*Curl_cwriter, wtype: c_int, buf: [*]const u8, nbytes: usize) CURLcode {
    const w = writer orelse return CURLE_WRITE_ERROR;
    return w.cwt.do_write(data, w, wtype, buf, nbytes);
}

inline fn cwriterFlush(data: ?*Curl_easy, writer: ?*Curl_cwriter) CURLcode {
    const w = writer orelse return CURLE_WRITE_ERROR;
    return w.cwt.do_flush(data, w);
}

// ============================================================================
// Minimal Curl_easy Accessors (req.writer.paused and set.strings)
// ============================================================================

const use_ssh = if (@hasDecl(backend_options, "ssh")) backend_options.ssh != .none else false;
const enable_hsts = if (@hasDecl(backend_options, "ssl")) backend_options.ssl != .none else false;
const ssh_off: u8 = if (use_ssh) 5 else 0;
const hsts_off: u8 = if (enable_hsts) 1 else 0;
const ares_off: u8 = if (use_ares) 4 else 0;
const STRING_HAPROXY_CLIENT_IP: u8 = 65 + ssh_off + hsts_off + ares_off;
extern fn Curl_easy_strset_ptr(data: *Curl_easy) callconv(.c) *collections.u8_strset;
extern fn Curl_cw_out_is_paused(data: ?*const Curl_easy) callconv(.c) bool;
extern fn Curl_cw_out_set_paused(data: ?*Curl_easy, paused: bool) callconv(.c) void;

inline fn cwriterIsPaused(data: ?*const Curl_easy) bool {
    return Curl_cw_out_is_paused(data);
}

inline fn cwriterSetPaused(data: ?*Curl_easy, paused: bool) void {
    Curl_cw_out_set_paused(data, paused);
}

inline fn isValidU8Strset(set: *const collections.u8_strset) bool {
    if (set.slotbits < 3 or set.slotbits > 8) return false;
    const nslots: usize = @as(usize, 1) << @intCast(set.slotbits);
    if (set.slotmask != @as(u8, @truncate(nslots - 1))) return false;
    if (set.count > nslots) return false;
    const data_addr = @intFromPtr(set.data);
    const ids_addr = @intFromPtr(set.ids);
    const psl_addr = @intFromPtr(set.psl);
    return (ids_addr == data_addr +% (nslots * @sizeOf(?[*:0]u8))) and
        (psl_addr == ids_addr +% nslots);
}

inline fn getHaproxyClientIp(data: ?*Curl_easy) ?[*:0]const u8 {
    const d = data orelse return null;
    const set = Curl_easy_strset_ptr(d);
    if (isValidU8Strset(set)) {
        return Curl_u8_strset_get(set, STRING_HAPROXY_CLIENT_IP);
    }
    return null;
}

// ============================================================================
// 1. lib/vdns/hostip4.c
// ============================================================================

export fn Curl_ipv4_resolve_r(hostname: ?[*:0]const u8, port: u16) callconv(.c) ?*Curl_addrinfo {
    var ai: ?*Curl_addrinfo = null;
    var hints: CAddrinfo = .{
        .ai_family = PF_INET,
        .ai_socktype = SOCK_STREAM,
    };
    var sbuf: [12]u8 = undefined;
    var sbufptr: ?[*:0]const u8 = null;

    if (port != 0) {
        _ = curl_msnprintf(&sbuf, sbuf.len, "%d", @as(c_int, port));
        sbufptr = @ptrCast(&sbuf);
    }

    _ = Curl_getaddrinfo_ex(hostname, sbufptr, &hints, &ai);
    return ai;
}

pub fn ipv4SyncGetaddrinfo(
    data: ?*Curl_easy,
    dns_queries: u8,
    hostname: [*:0]const u8,
    port: u16,
    transport: u8,
) ?*Curl_addrinfo {
    _ = dns_queries;
    _ = transport;

    const ai = Curl_ipv4_resolve_r(hostname, port);
    if (ai == null and data != null) {
        Curl_infof(data, "Curl_ipv4_resolve_r failed for %s", hostname);
    }
    return ai;
}

// ============================================================================
// 2. lib/vdns/hostip6.c
// ============================================================================

export fn Curl_sync_getaddrinfo(
    data: ?*Curl_easy,
    dns_queries: u8,
    hostname: [*:0]const u8,
    port: u16,
    transport: u8,
) callconv(.c) ?*Curl_addrinfo {
    var hints: CAddrinfo = .{
        .ai_family = if ((dns_queries & CURL_DNSQ_AAAA) != 0) PF_UNSPEC else PF_INET,
        .ai_socktype = if (transport == TRNSPRT_TCP) SOCK_STREAM else SOCK_DGRAM,
    };
    var res: ?*Curl_addrinfo = null;
    var sbuf: [12]u8 = undefined;
    var sbufptr: ?[*:0]const u8 = null;
    var addrbuf: [128]u8 = undefined;

    if (curlx_time_net.curlx_inet_pton(AF_INET, hostname, &addrbuf) == 1 or
        curlx_time_net.curlx_inet_pton(AF_INET6, hostname, &addrbuf) == 1)
    {
        hints.ai_flags = AI_NUMERICHOST;
    }

    if (port != 0) {
        _ = curl_msnprintf(&sbuf, sbuf.len, "%d", @as(c_int, port));
        sbufptr = @ptrCast(&sbuf);
    }

    const err = Curl_getaddrinfo_ex(hostname, sbufptr, &hints, &res);
    if (err != 0) {
        if (data != null) {
            Curl_infof(data, "getaddrinfo(3) failed for %s:%d", hostname, @as(c_int, port));
        }
        return null;
    }

    return res;
}

// ============================================================================
// 3. lib/vdns/asyn-base.c
// ============================================================================

const ARES_GETSOCK_MAXNUM: usize = 16;
const ARES_SOCKET_BAD: curl_socket_t = CURL_SOCKET_BAD;
const CURL_TIMEOUT_RESOLVE_MS: timediff_t = 300 * 1000;

pub const ares_timeval = extern struct {
    tv_sec: c_long,
    tv_usec: c_long,
};
pub const AresTimeval = ares_timeval;

extern fn ares_getsock(channel: ?*const anyopaque, socks: [*]curl_socket_t, numsocks: c_int) callconv(.c) c_int;
extern fn ares_timeout(channel: ?*const anyopaque, maxtv: ?*ares_timeval, tv: *ares_timeval) callconv(.c) ?*ares_timeval;
extern fn ares_process_fd(channel: ?*anyopaque, read_fd: curl_socket_t, write_fd: curl_socket_t) callconv(.c) void;

pub fn Curl_ares_pollset(
    data: ?*Curl_easy,
    channel: ?*anyopaque,
    ps: *easy_pollset,
) callconv(.c) CURLcode {
    if (channel == null) return CURLE_FAILED_INIT;
    var socks: [ARES_GETSOCK_MAXNUM]curl_socket_t = undefined;
    const max: c_uint = @bitCast(ares_getsock(channel, &socks, @intCast(ARES_GETSOCK_MAXNUM)));
    for (0..ARES_GETSOCK_MAXNUM) |i| {
        var flags: c_int = 0;
        const shift: u5 = @intCast(i);
        const wshift: u5 = @intCast(i + ARES_GETSOCK_MAXNUM);
        if ((max & (@as(c_uint, 1) << shift)) != 0) {
            flags |= CURL_POLL_IN;
        }
        if ((max & (@as(c_uint, 1) << wshift)) != 0) {
            flags |= CURL_POLL_OUT;
        }
        if (flags == 0) break;
        const result = Curl_pollset_change(data, ps, socks[i], flags, 0);
        if (result != CURLE_OK) return result;
    }
    return CURLE_OK;
}

pub fn Curl_ares_timeout_ms(
    data: ?*Curl_easy,
    async_ctx: *Curl_resolv_async,
    channel: ?*anyopaque,
) callconv(.c) timediff_t {
    if (channel == null) return -1;
    const async_timeout_ms = Curl_async_timeleft_ms(data, async_ctx);
    if (async_timeout_ms > 0 and async_timeout_ms < std.math.maxInt(c_int)) {
        const itimeout_ms: c_int = @intCast(async_timeout_ms);
        var max_tv: ares_timeval = .{
            .tv_sec = @divTrunc(itimeout_ms, 1000),
            .tv_usec = @rem(itimeout_ms, 1000) * 1000,
        };
        var tv_buf: ares_timeval = .{ .tv_sec = 0, .tv_usec = 0 };
        if (ares_timeout(channel, &max_tv, &tv_buf)) |tv| {
            return @as(timediff_t, tv.tv_sec) * 1000 + @divTrunc(@as(timediff_t, tv.tv_usec), 1000);
        }
    }
    return async_timeout_ms;
}

pub fn Curl_ares_perform(
    channel: ?*anyopaque,
    timeout_ms: timediff_t,
) callconv(.c) c_int {
    var nfds: c_int = undefined;
    var bitmask: c_uint = undefined;
    var socks: [ARES_GETSOCK_MAXNUM]curl_socket_t = undefined;
    var pfd: [ARES_GETSOCK_MAXNUM]headers_sock.Pollfd = undefined;
    var num: usize = 0;

    if (channel == null) return 0;

    bitmask = @bitCast(ares_getsock(channel, &socks, @intCast(ARES_GETSOCK_MAXNUM)));

    for (0..ARES_GETSOCK_MAXNUM) |i| {
        pfd[i].events = 0;
        pfd[i].revents = 0;
        const shift: u5 = @intCast(i);
        const wshift: u5 = @intCast(i + ARES_GETSOCK_MAXNUM);
        if ((bitmask & (@as(c_uint, 1) << shift)) != 0) {
            pfd[i].fd = socks[i];
            pfd[i].events |= headers_sock.POLLRDNORM | headers_sock.POLLIN;
        }
        if ((bitmask & (@as(c_uint, 1) << wshift)) != 0) {
            pfd[i].fd = socks[i];
            pfd[i].events |= headers_sock.POLLWRNORM | headers_sock.POLLOUT;
        }
        if (pfd[i].events != 0) {
            num += 1;
        } else {
            break;
        }
    }

    if (num > 0) {
        nfds = headers_sock.Curl_poll(&pfd, @intCast(num), timeout_ms);
        if (nfds < 0) return -1;
    } else {
        nfds = 0;
    }

    if (nfds == 0) {
        ares_process_fd(channel, ARES_SOCKET_BAD, ARES_SOCKET_BAD);
    } else {
        for (0..num) |i| {
            ares_process_fd(
                channel,
                if ((pfd[i].revents & (headers_sock.POLLRDNORM | headers_sock.POLLIN)) != 0) pfd[i].fd else ARES_SOCKET_BAD,
                if ((pfd[i].revents & (headers_sock.POLLWRNORM | headers_sock.POLLOUT)) != 0) pfd[i].fd else ARES_SOCKET_BAD,
            );
        }
    }
    return nfds;
}

comptime {
    if (use_ares) {
        @export(&Curl_ares_pollset, .{ .name = "Curl_ares_pollset", .linkage = .strong });
        @export(&Curl_ares_timeout_ms, .{ .name = "Curl_ares_timeout_ms", .linkage = .strong });
        @export(&Curl_ares_perform, .{ .name = "Curl_ares_perform", .linkage = .strong });
    }
}

export fn Curl_async_timeleft_ms(data: ?*Curl_easy, async_ctx: *Curl_resolv_async) callconv(.c) timediff_t {
    if (async_ctx.timeout_ms != 0) {
        const elapsed_ms = curlx_time_net.curlx_ptimediff_ms(Curl_pgrs_now(data), &async_ctx.start);
        return async_ctx.timeout_ms - elapsed_ms;
    }
    return Curl_timeleft_ms(data);
}

export fn Curl_async_shutdown(data: ?*Curl_easy, async_ctx: ?*Curl_resolv_async) callconv(.c) void {
    const a = async_ctx orelse return;
    trcDns(data, "[%u] shutdown async", .{a.id});
    a.setShutdown(true);
    if (use_resolv_ares) {
        Curl_async_ares_shutdown(data, a);
    }
    if (use_resolv_threaded) {
        Curl_async_thrdd_shutdown(data, a);
    }
    Curl_doh_cleanup(data, a);
}

export fn Curl_async_destroy(data: ?*Curl_easy, async_ctx: ?*Curl_resolv_async) callconv(.c) void {
    const a = async_ctx orelse return;
    trcDns(data, "[%u] destroy async", .{a.id});
    a.setShutdown(true);
    if (use_resolv_ares) {
        Curl_async_ares_destroy(data, a);
    }
    if (use_resolv_threaded) {
        Curl_async_thrdd_destroy(data, a);
    }
    Curl_doh_cleanup(data, a);
    if (a.ai_A) |ai_a| {
        Curl_freeaddrinfo(ai_a);
    }
    if (a.ai_AAAA) |ai_aaaa| {
        Curl_freeaddrinfo(ai_aaaa);
    }
    if (use_httpsrr) {
        Curl_httpsrr_destroy(a.httpsrr);
        a.httpsrr = null;
    }
    Curl_peer_unlink(&a.peer);
    mem.freeSized(a, @sizeOf(Curl_resolv_async));
}

export fn Curl_async_failed(
    data: ?*Curl_easy,
    async_ctx: *Curl_resolv_async,
    detail: ?[*:0]const u8,
) callconv(.c) CURLcode {
    const host_or_proxy: [*:0]const u8 = if (async_ctx.isForProxy()) "proxy" else "host";
    const result: CURLcode = if (async_ctx.isForProxy())
        CURLE_COULDNT_RESOLVE_PROXY
    else
        CURLE_COULDNT_RESOLVE_HOST;

    if ((async_ctx.dns_queries & (CURL_DNSQ_A | CURL_DNSQ_AAAA)) != 0) {
        const hostname: [*:0]const u8 = if (async_ctx.peer) |peer|
            (peer.hostname orelse "")
        else
            "";
        const prefix: [*:0]const u8 = if (detail != null) " (" else "";
        const body: [*:0]const u8 = if (detail) |d| d else "";
        const suffix: [*:0]const u8 = if (detail != null) ")" else "";
        failf(data, "Could not resolve %s: %s%s%s%s", .{ host_or_proxy, hostname, prefix, body, suffix });
    }
    return result;
}

// ============================================================================
// 4. lib/cf-recvbuf.c
// ============================================================================

const CURL_CF_RECVBUF_CHUNK: usize = 16 * 1024;

const cf_recvbuf_ctx = extern struct {
    recvbuf: io_buffers.bufq,
};

fn cf_recvbuf_destroy(cf: *Curl_cfilter, data: ?*Curl_easy) callconv(.c) void {
    trcCf(data, cf, "destroy", .{});
    if (cf.ctx) |raw| {
        const ctx: *cf_recvbuf_ctx = @ptrCast(@alignCast(raw));
        io_buffers.Curl_bufq_free(&ctx.recvbuf);
        mem.freeSized(ctx, @sizeOf(cf_recvbuf_ctx));
        cf.ctx = null;
    }
}

fn cf_recvbuf_recv(
    cf: *Curl_cfilter,
    data: ?*Curl_easy,
    buf: [*]u8,
    len: usize,
    pnread: *usize,
) callconv(.c) CURLcode {
    const ctx: *cf_recvbuf_ctx = @ptrCast(@alignCast(cf.ctx.?));
    if (!io_buffers.Curl_bufq_is_empty(&ctx.recvbuf)) {
        return io_buffers.Curl_bufq_cread(&ctx.recvbuf, buf, len, pnread);
    } else if (cf.next) |next| {
        return next.cft.do_recv(next, data, buf, len, pnread);
    }
    pnread.* = 0;
    return CURLE_RECV_ERROR;
}

fn cf_recvbuf_data_pending(cf: *Curl_cfilter, data: ?*const Curl_easy) callconv(.c) bool {
    const ctx: *cf_recvbuf_ctx = @ptrCast(@alignCast(cf.ctx.?));
    if (!io_buffers.Curl_bufq_is_empty(&ctx.recvbuf)) {
        return true;
    }
    return if (cf.next) |next| next.cft.has_data_pending(next, data) else false;
}

pub export var Curl_cft_recvbuf: Curl_cftype = .{
    .name = "RECVBUF",
    .flags = 0,
    .log_level = CURL_LOG_LVL_NONE,
    .destroy = cf_recvbuf_destroy,
    .do_connect = Curl_cf_def_connect,
    .do_shutdown = Curl_cf_def_shutdown,
    .adjust_pollset = Curl_cf_def_adjust_pollset,
    .has_data_pending = cf_recvbuf_data_pending,
    .do_send = Curl_cf_def_send,
    .do_recv = cf_recvbuf_recv,
    .cntrl = Curl_cf_def_cntrl,
    .is_alive = Curl_cf_def_conn_is_alive,
    .keep_alive = Curl_cf_def_conn_keep_alive,
    .query = Curl_cf_def_query,
};

export fn Curl_cf_recvbuf_add(
    data: ?*Curl_easy,
    conn: ?*connectdata,
    sockindex: i8,
    buf: [*]const u8,
    blen: usize,
) callconv(.c) CURLcode {
    if (blen == 0)
        return CURLE_OK;

    var cf: ?*Curl_cfilter = null;
    var nwritten: usize = 0;

    const raw = mem.calloc(1, @sizeOf(cf_recvbuf_ctx)) orelse return CURLE_OUT_OF_MEMORY;
    const ctx: *cf_recvbuf_ctx = @ptrCast(@alignCast(raw));

    io_buffers.Curl_bufq_init2(
        &ctx.recvbuf,
        CURL_CF_RECVBUF_CHUNK,
        (blen / CURL_CF_RECVBUF_CHUNK) + 1,
        io_buffers.BUFQ_OPT_SOFT_LIMIT | io_buffers.BUFQ_OPT_NO_SPARES,
    );
    var result = io_buffers.Curl_bufq_write(&ctx.recvbuf, buf, blen, &nwritten);
    if (result == CURLE_OK and nwritten != blen) {
        result = CURLE_FAILED_INIT;
    }
    if (result == CURLE_OK) {
        result = Curl_cf_create(&cf, &Curl_cft_recvbuf, ctx);
    }
    if (result != CURLE_OK) {
        io_buffers.Curl_bufq_free(&ctx.recvbuf);
        mem.freeSized(ctx, @sizeOf(cf_recvbuf_ctx));
        return result;
    }

    const filter = cf.?;
    filter.setConnected(Curl_conn_is_connected(conn, sockindex));
    Curl_conn_cf_add(data, conn, sockindex, filter);
    trcCf(data, filter, "added with %zu bytes", .{blen});
    return CURLE_OK;
}

// ============================================================================
// 5. lib/cf-haproxy.c
// ============================================================================

const HAPROXY_INIT: c_int = 0;
const HAPROXY_SEND: c_int = 1;
const HAPROXY_DONE: c_int = 2;

const cf_haproxy_ctx = extern struct {
    state: c_int,
    data_out: containers.dynbuf,
};

fn cf_haproxy_ctx_reset(ctx: *cf_haproxy_ctx) void {
    ctx.state = HAPROXY_INIT;
    curlx_dyn_reset(&ctx.data_out);
}

fn cf_haproxy_ctx_free(ctx: ?*cf_haproxy_ctx) void {
    if (ctx) |c| {
        curlx_dyn_free(&c.data_out);
        mem.freeSized(c, @sizeOf(cf_haproxy_ctx));
    }
}

fn cf_haproxy_date_out_set(cf: *Curl_cfilter, data: ?*Curl_easy) CURLcode {
    const ctx: *cf_haproxy_ctx = @ptrCast(@alignCast(cf.ctx.?));
    var ipquad: ip_quadruple = std.mem.zeroes(ip_quadruple);
    var is_ipv6: bool = false;

    if (cf.conn) |conn| {
        if (Curl_conn_get_first_peer(conn, cf.sockindex).isUnixSocket()) {
            const unknown = "PROXY UNKNOWN\r\n";
            return curlx_dyn_addn(&ctx.data_out, unknown.ptr, unknown.len);
        }
    }

    const result = Curl_conn_cf_get_ip_info(cf.next, data, &is_ipv6, &ipquad);
    if (result != CURLE_OK)
        return result;

    var client_source_ip: [*:0]const u8 = undefined;
    var client_dest_ip: [*:0]const u8 = undefined;
    if (getHaproxyClientIp(data)) |custom_ip| {
        client_source_ip = custom_ip;
        client_dest_ip = custom_ip;
        is_ipv6 = !Curl_is_ipv4addr(client_source_ip);
    } else {
        client_source_ip = @ptrCast(&ipquad.local_ip[0]);
        client_dest_ip = @ptrCast(&ipquad.remote_ip[0]);
    }

    return curlx_dyn_addf(
        &ctx.data_out,
        "PROXY %s %s %s %d %d\r\n",
        @as([*:0]const u8, if (is_ipv6) "TCP6" else "TCP4"),
        client_source_ip,
        client_dest_ip,
        @as(c_int, ipquad.local_port),
        @as(c_int, ipquad.remote_port),
    );
}

fn cf_haproxy_connect(cf: *Curl_cfilter, data: ?*Curl_easy, done: *bool) callconv(.c) CURLcode {
    const ctx: *cf_haproxy_ctx = @ptrCast(@alignCast(cf.ctx.?));

    if (cf.isConnected()) {
        done.* = true;
        return CURLE_OK;
    }

    const next = cf.next orelse return CURLE_FAILED_INIT;
    var result = next.cft.do_connect(next, data, done);
    if (result != CURLE_OK or !done.*)
        return result;

    switch (ctx.state) {
        HAPROXY_INIT => {
            result = cf_haproxy_date_out_set(cf, data);
            if (result != CURLE_OK)
                return result;
            ctx.state = HAPROXY_SEND;
            const len = curlx_dyn_len(&ctx.data_out);
            if (len > 0) {
                var nwritten: usize = 0;
                result = Curl_conn_cf_send(
                    next,
                    data,
                    curlx_dyn_uptr(&ctx.data_out).?,
                    len,
                    false,
                    &nwritten,
                );
                if (result != CURLE_OK) {
                    if (result != CURLE_AGAIN)
                        return result;
                    done.* = false;
                    return CURLE_OK;
                }
                _ = curlx_dyn_tail(&ctx.data_out, len - nwritten);
                if (curlx_dyn_len(&ctx.data_out) > 0) {
                    done.* = false;
                    return CURLE_OK;
                }
            }
            ctx.state = HAPROXY_DONE;
            curlx_dyn_free(&ctx.data_out);
        },
        HAPROXY_SEND => {
            const len = curlx_dyn_len(&ctx.data_out);
            if (len > 0) {
                var nwritten: usize = 0;
                result = Curl_conn_cf_send(
                    next,
                    data,
                    curlx_dyn_uptr(&ctx.data_out).?,
                    len,
                    false,
                    &nwritten,
                );
                if (result != CURLE_OK) {
                    if (result != CURLE_AGAIN)
                        return result;
                    done.* = false;
                    return CURLE_OK;
                }
                _ = curlx_dyn_tail(&ctx.data_out, len - nwritten);
                if (curlx_dyn_len(&ctx.data_out) > 0) {
                    done.* = false;
                    return CURLE_OK;
                }
            }
            ctx.state = HAPROXY_DONE;
            curlx_dyn_free(&ctx.data_out);
        },
        else => {
            curlx_dyn_free(&ctx.data_out);
        },
    }

    done.* = (result == CURLE_OK) and (ctx.state == HAPROXY_DONE);
    cf.setConnected(done.*);
    return result;
}

fn cf_haproxy_destroy(cf: *Curl_cfilter, data: ?*Curl_easy) callconv(.c) void {
    trcCf(data, cf, "destroy", .{});
    if (cf.ctx) |raw| {
        cf_haproxy_ctx_free(@ptrCast(@alignCast(raw)));
    }
}

fn cf_haproxy_adjust_pollset(
    cf: *Curl_cfilter,
    data: ?*Curl_easy,
    ps: *easy_pollset,
) callconv(.c) CURLcode {
    if (cf.next) |next| {
        if (next.isConnected() and !cf.isConnected()) {
            return Curl_pollset_change(
                data,
                ps,
                Curl_conn_cf_get_socket(cf, data),
                CURL_POLL_OUT,
                CURL_POLL_IN,
            );
        }
    }
    return CURLE_OK;
}

pub export var Curl_cft_haproxy: Curl_cftype = .{
    .name = "HAPROXY",
    .flags = CF_TYPE_PROXY | CF_TYPE_SETUP,
    .log_level = CURL_LOG_LVL_NONE,
    .destroy = cf_haproxy_destroy,
    .do_connect = cf_haproxy_connect,
    .do_shutdown = Curl_cf_def_shutdown,
    .adjust_pollset = cf_haproxy_adjust_pollset,
    .has_data_pending = Curl_cf_def_data_pending,
    .do_send = Curl_cf_def_send,
    .do_recv = Curl_cf_def_recv,
    .cntrl = Curl_cf_def_cntrl,
    .is_alive = Curl_cf_def_conn_is_alive,
    .keep_alive = Curl_cf_def_conn_keep_alive,
    .query = Curl_cf_def_query,
};

fn cf_haproxy_create(pcf: *?*Curl_cfilter, data: ?*Curl_easy) CURLcode {
    _ = data;
    var cf: ?*Curl_cfilter = null;
    const raw = mem.calloc(1, @sizeOf(cf_haproxy_ctx)) orelse {
        pcf.* = null;
        return CURLE_OUT_OF_MEMORY;
    };
    const ctx: *cf_haproxy_ctx = @ptrCast(@alignCast(raw));
    cf_haproxy_ctx_reset(ctx);
    curlx_dyn_init(&ctx.data_out, DYN_HAXPROXY);

    const result = Curl_cf_create(&cf, &Curl_cft_haproxy, ctx);
    if (result != CURLE_OK) {
        cf_haproxy_ctx_free(ctx);
        pcf.* = null;
        return result;
    }
    pcf.* = cf;
    return CURLE_OK;
}

export fn Curl_cf_haproxy_insert_after(cf_at: *Curl_cfilter, data: ?*Curl_easy) callconv(.c) CURLcode {
    var cf: ?*Curl_cfilter = null;
    const result = cf_haproxy_create(&cf, data);
    if (result != CURLE_OK)
        return result;

    Curl_conn_cf_insert_after(cf_at, cf.?);
    return CURLE_OK;
}

// ============================================================================
// 6. lib/cw-pause.c
// ============================================================================

const CW_PAUSE_BUF_CHUNK: usize = 16 * 1024;
const CW_PAUSE_DEC_WRITE_CHUNK: usize = 4096;

const cw_pause_buf = extern struct {
    next: ?*cw_pause_buf,
    b: io_buffers.bufq,
    wtype: c_int,
};

const cw_pause_ctx = extern struct {
    super: Curl_cwriter,
    buf: ?*cw_pause_buf,
    tail: ?*cw_pause_buf,
    buf_total: usize,
};

fn cw_pause_buf_create(wtype: c_int, buflen: usize) ?*cw_pause_buf {
    const raw = mem.calloc(1, @sizeOf(cw_pause_buf)) orelse return null;
    const cwbuf: *cw_pause_buf = @ptrCast(@alignCast(raw));
    cwbuf.wtype = wtype;
    if ((wtype & CLIENTWRITE_BODY) != 0) {
        io_buffers.Curl_bufq_init2(
            &cwbuf.b,
            CW_PAUSE_BUF_CHUNK,
            1,
            io_buffers.BUFQ_OPT_SOFT_LIMIT | io_buffers.BUFQ_OPT_NO_SPARES,
        );
    } else {
        io_buffers.Curl_bufq_init(&cwbuf.b, @max(buflen, 1), 1);
    }
    return cwbuf;
}

fn cw_pause_buf_free(cwbuf: ?*cw_pause_buf) void {
    if (cwbuf) |b| {
        io_buffers.Curl_bufq_free(&b.b);
        mem.freeSized(b, @sizeOf(cw_pause_buf));
    }
}

inline fn cwriterCtx(writer: *Curl_cwriter) *cw_pause_ctx {
    if (writer.ctx) |p| {
        return @ptrCast(@alignCast(p));
    }
    return @ptrCast(@alignCast(writer));
}

fn cw_pause_init(data: ?*Curl_easy, writer: *Curl_cwriter) callconv(.c) CURLcode {
    _ = data;
    const ctx = cwriterCtx(writer);
    ctx.buf = null;
    ctx.tail = null;
    return CURLE_OK;
}

fn cw_pause_clean(ctx: *cw_pause_ctx) void {
    while (ctx.buf) |head| {
        ctx.buf = head.next;
        cw_pause_buf_free(head);
    }
    ctx.tail = null;
}

fn cw_pause_close(data: ?*Curl_easy, writer: *Curl_cwriter) callconv(.c) void {
    _ = data;
    const ctx = cwriterCtx(writer);
    cw_pause_clean(ctx);
}

fn cw_pause_flush(data: ?*Curl_easy, writer: *Curl_cwriter) callconv(.c) CURLcode {
    const ctx = cwriterCtx(writer);
    var result: CURLcode = CURLE_OK;

    while (ctx.buf != null and !cwriterIsPaused(data)) {
        const first = ctx.buf.?;
        var buf: ?[*]const u8 = null;
        var blen: usize = 0;

        if (io_buffers.Curl_bufq_peek(&first.b, &buf, &blen)) {
            const wlen: usize = if ((first.wtype & CLIENTWRITE_BODY) != 0)
                @min(blen, CW_PAUSE_DEC_WRITE_CHUNK)
            else
                blen;
            var chunk_wtype = first.wtype;
            if (wlen < blen)
                chunk_wtype &= ~CLIENTWRITE_EOS;
            result = cwriterWrite(data, writer.next, chunk_wtype, buf.?, wlen);
            trcWrite(
                data,
                "[PAUSE] flushed %zu/%zu bytes, type=%x -> %d",
                .{ wlen, ctx.buf_total, first.wtype, result },
            );
            io_buffers.Curl_bufq_skip(&first.b, wlen);
            ctx.buf_total -= wlen;
            if (result != CURLE_OK)
                return result;
        } else if ((first.wtype & CLIENTWRITE_EOS) != 0) {
            const empty = [_]u8{0};
            result = cwriterWrite(data, writer.next, first.wtype, &empty, 0);
            trcWrite(
                data,
                "[PAUSE] flushed 0/%zu bytes, type=%x -> %d",
                .{ ctx.buf_total, first.wtype, result },
            );
            if (result != CURLE_OK)
                return result;
        }

        if (io_buffers.Curl_bufq_is_empty(&first.b)) {
            ctx.buf = first.next;
            if (ctx.buf == null)
                ctx.tail = null;
            cw_pause_buf_free(first);
        }
    }

    if (result == CURLE_OK) {
        result = cwriterFlush(data, writer.next);
    }

    return result;
}

fn cw_pause_write(
    data: ?*Curl_easy,
    writer: *Curl_cwriter,
    wtype: c_int,
    buf_in: [*]const u8,
    nbytes_in: usize,
) callconv(.c) CURLcode {
    const ctx = cwriterCtx(writer);
    var result: CURLcode = CURLE_OK;
    var buf = buf_in;
    var nbytes = nbytes_in;

    if (ctx.buf != null and !cwriterIsPaused(data)) {
        result = cw_pause_flush(data, writer);
        if (result != CURLE_OK)
            return result;
    }

    while (ctx.buf == null and !cwriterIsPaused(data)) {
        var chunk_wtype = wtype;
        const wlen: usize = if ((wtype & CLIENTWRITE_BODY) != 0)
            @min(nbytes, CW_PAUSE_DEC_WRITE_CHUNK)
        else
            nbytes;
        if (wlen < nbytes)
            chunk_wtype &= ~CLIENTWRITE_EOS;
        result = cwriterWrite(data, writer.next, chunk_wtype, buf, wlen);
        trcWrite(data, "[PAUSE] wrote %zu/%zu bytes of type %x -> %d", .{ wlen, nbytes, chunk_wtype, result });
        if (result != CURLE_OK)
            return result;
        buf += wlen;
        nbytes -= wlen;
        if (nbytes == 0)
            return result;
    }

    while (true) {
        var nwrote: usize = 0;
        if (ctx.tail != null and ctx.tail.?.wtype == wtype and (wtype & CLIENTWRITE_BODY) != 0) {
            if (nbytes > 0) {
                result = io_buffers.Curl_bufq_write(&ctx.tail.?.b, buf, nbytes, &nwrote);
            }
        } else {
            const cwbuf = cw_pause_buf_create(wtype, nbytes) orelse return CURLE_OUT_OF_MEMORY;
            if (ctx.tail) |t| {
                t.next = cwbuf;
            } else {
                ctx.buf = cwbuf;
            }
            ctx.tail = cwbuf;
            if (nbytes > 0) {
                result = io_buffers.Curl_bufq_write(&ctx.tail.?.b, buf, nbytes, &nwrote);
            }
        }
        trcWrite(data, "[PAUSE] buffered %zu bytes of type %x -> %d", .{ nwrote, wtype, result });
        if (result != CURLE_OK)
            return result;
        ctx.buf_total += nwrote;
        buf += nwrote;
        nbytes -= nwrote;
        if (nbytes == 0)
            break;
    }
    return result;
}

pub export var Curl_cwt_pause: Curl_cwtype = .{
    .name = "cw-pause",
    .alias = null,
    .flags = 0,
    .do_init = cw_pause_init,
    .do_write = cw_pause_write,
    .do_flush = cw_pause_flush,
    .do_close = cw_pause_close,
    .cwriter_size = @sizeOf(cw_pause_ctx),
};

// ============================================================================
// 7. lib/vquic/cf-capsule.c
// ============================================================================

const CAPSULE_RECV_CHUNKS: usize = 4;
const CAPSULE_SEND_CHUNKS: usize = 4;
const CAPSULE_CHUNK_SIZE: usize = 16 * 1024;

extern fn Curl_capsule_encap_udp_datagram(
    q: *io_buffers.bufq,
    buf: *const anyopaque,
    blen: usize,
) callconv(.c) CURLcode;

extern fn Curl_capsule_process_udp_raw(
    cf: *Curl_cfilter,
    data: ?*Curl_easy,
    recvbufq: *io_buffers.bufq,
    buf: [*]u8,
    len: usize,
    err: *CURLcode,
) callconv(.c) usize;

const cf_capsule_ctx = extern struct {
    recvbuf: io_buffers.bufq,
    sendbuf: io_buffers.bufq,
};

fn cf_capsule_ctx_init(ctx: *cf_capsule_ctx) void {
    io_buffers.Curl_bufq_init2(
        &ctx.recvbuf,
        CAPSULE_CHUNK_SIZE,
        CAPSULE_RECV_CHUNKS,
        io_buffers.BUFQ_OPT_NONE,
    );
    io_buffers.Curl_bufq_init2(
        &ctx.sendbuf,
        CAPSULE_CHUNK_SIZE,
        CAPSULE_SEND_CHUNKS,
        io_buffers.BUFQ_OPT_NONE,
    );
}

fn cf_capsule_ctx_clear(ctx: *cf_capsule_ctx) void {
    io_buffers.Curl_bufq_free(&ctx.recvbuf);
    io_buffers.Curl_bufq_free(&ctx.sendbuf);
}

fn cf_capsule_destroy(cf: *Curl_cfilter, data: ?*Curl_easy) callconv(.c) void {
    const ctx: ?*cf_capsule_ctx = if (cf.ctx) |raw| @ptrCast(@alignCast(raw)) else null;
    trcCf(data, cf, "destroy", .{});
    if (ctx) |c| {
        cf_capsule_ctx_clear(c);
        mem.freeSized(c, @sizeOf(cf_capsule_ctx));
        cf.ctx = null;
    }
}

fn cf_capsule_connect(cf: *Curl_cfilter, data: ?*Curl_easy, done: *bool) callconv(.c) CURLcode {
    if (cf.isConnected()) {
        done.* = true;
        return CURLE_OK;
    }

    const next = cf.next orelse return CURLE_FAILED_INIT;
    const result = next.cft.do_connect(next, data, done);
    if (result == CURLE_OK and done.*) {
        cf.setConnected(true);
    }
    return result;
}

fn cf_capsule_out_flush(cf: *Curl_cfilter, data: ?*Curl_easy, pempty: *bool) CURLcode {
    const ctx: *cf_capsule_ctx = @ptrCast(@alignCast(cf.ctx.?));
    var nwritten: usize = 0;

    if (io_buffers.Curl_bufq_is_empty(&ctx.sendbuf)) {
        pempty.* = true;
        return CURLE_OK;
    }

    const next = cf.next orelse return CURLE_SEND_ERROR;
    var result = Curl_cf_send_bufq(next, data, &ctx.sendbuf, null, 0, &nwritten);
    if (result == CURLE_AGAIN) {
        result = CURLE_OK;
    } else if (result != CURLE_OK) {
        trcCf(data, cf, "out_flush() -> %d", .{result});
    }
    pempty.* = io_buffers.Curl_bufq_is_empty(&ctx.sendbuf);
    return result;
}

fn cf_capsule_shutdown(cf: *Curl_cfilter, data: ?*Curl_easy, done: *bool) callconv(.c) CURLcode {
    if (!cf.isConnected()) {
        done.* = true;
        return CURLE_OK;
    }

    const result = cf_capsule_out_flush(cf, data, done);
    if (result != CURLE_OK or !done.*) {
        return result;
    }
    return if (cf.next) |next| next.cft.do_shutdown(next, data, done) else CURLE_OK;
}

fn cf_capsule_adjust_pollset(
    cf: *Curl_cfilter,
    data: ?*Curl_easy,
    ps: *easy_pollset,
) callconv(.c) CURLcode {
    const ctx: *cf_capsule_ctx = @ptrCast(@alignCast(cf.ctx.?));
    const next = cf.next orelse return CURLE_OK;
    var result = next.cft.adjust_pollset(next, data, ps);
    if (result == CURLE_OK and !io_buffers.Curl_bufq_is_empty(&ctx.sendbuf)) {
        const sock = Curl_conn_cf_get_socket(cf, data);
        if (sock != CURL_SOCKET_BAD) {
            result = Curl_pollset_change(data, ps, sock, CURL_POLL_OUT, 0);
        }
    }
    return result;
}

fn cf_capsule_data_pending(cf: *Curl_cfilter, data: ?*const Curl_easy) callconv(.c) bool {
    const ctx: *cf_capsule_ctx = @ptrCast(@alignCast(cf.ctx.?));
    if (!io_buffers.Curl_bufq_is_empty(&ctx.recvbuf))
        return true;
    return if (cf.next) |next| next.cft.has_data_pending(next, data) else false;
}

fn cf_capsule_send(
    cf: *Curl_cfilter,
    data: ?*Curl_easy,
    buf: [*]const u8,
    len: usize,
    eos: bool,
    pnwritten: *usize,
) callconv(.c) CURLcode {
    const ctx: *cf_capsule_ctx = @ptrCast(@alignCast(cf.ctx.?));
    var flushed: bool = false;

    _ = eos;
    pnwritten.* = 0;

    var result = cf_capsule_out_flush(cf, data, &flushed);
    if (result != CURLE_OK) {
        return result;
    } else if (!flushed) {
        return CURLE_AGAIN;
    }

    if (len == 0) {
        pnwritten.* = 0;
        return CURLE_OK;
    }

    result = Curl_capsule_encap_udp_datagram(&ctx.sendbuf, buf, len);
    if (result != CURLE_OK)
        return result;

    result = cf_capsule_out_flush(cf, data, &flushed);
    if (result != CURLE_OK and result != CURLE_AGAIN) {
        io_buffers.Curl_bufq_reset(&ctx.sendbuf);
        return result;
    }

    pnwritten.* = len;
    return CURLE_OK;
}

fn cf_capsule_recv(
    cf: *Curl_cfilter,
    data: ?*Curl_easy,
    buf: [*]u8,
    len: usize,
    pnread: *usize,
) callconv(.c) CURLcode {
    const ctx: *cf_capsule_ctx = @ptrCast(@alignCast(cf.ctx.?));
    var result: CURLcode = CURLE_OK;
    var nread: usize = 0;

    pnread.* = 0;
    while (true) {
        if (!io_buffers.Curl_bufq_is_empty(&ctx.recvbuf)) {
            nread = Curl_capsule_process_udp_raw(cf, data, &ctx.recvbuf, buf, len, &result);
            if (result != CURLE_OK and result != CURLE_AGAIN)
                return result;
            if (nread > 0) {
                pnread.* = nread;
                return CURLE_OK;
            }
        }

        result = Curl_cf_recv_bufq(cf.next.?, data, &ctx.recvbuf, 0, &nread);
        if (result != CURLE_OK)
            return result;
        if (nread == 0)
            return CURLE_OK;
    }
}

fn cf_capsule_cntrl(
    cf: *Curl_cfilter,
    data: ?*Curl_easy,
    event: c_int,
    arg1: c_int,
    arg2: ?*anyopaque,
) callconv(.c) CURLcode {
    var result: CURLcode = CURLE_OK;
    var flushed: bool = false;

    _ = arg1;
    _ = arg2;

    if (event == CF_CTRL_FLUSH) {
        result = cf_capsule_out_flush(cf, data, &flushed);
        if (result == CURLE_OK and !flushed) {
            result = CURLE_AGAIN;
        }
    }
    return result;
}

fn cf_capsule_query(
    cf: *Curl_cfilter,
    data: ?*Curl_easy,
    query_id: c_int,
    pres1: ?*c_int,
    pres2: ?*anyopaque,
) callconv(.c) CURLcode {
    const ctx: *cf_capsule_ctx = @ptrCast(@alignCast(cf.ctx.?));
    if (query_id == CF_QUERY_NEED_FLUSH) {
        if (!io_buffers.Curl_bufq_is_empty(&ctx.sendbuf)) {
            if (pres1) |p| p.* = 1;
            return CURLE_OK;
        }
    }
    return if (cf.next) |next| next.cft.query(next, data, query_id, pres1, pres2) else CURLE_OK;
}

pub export var Curl_cft_capsule: Curl_cftype = .{
    .name = "CAPSULE",
    .flags = 0,
    .log_level = CURL_LOG_LVL_NONE,
    .destroy = cf_capsule_destroy,
    .do_connect = cf_capsule_connect,
    .do_shutdown = cf_capsule_shutdown,
    .adjust_pollset = cf_capsule_adjust_pollset,
    .has_data_pending = cf_capsule_data_pending,
    .do_send = cf_capsule_send,
    .do_recv = cf_capsule_recv,
    .cntrl = cf_capsule_cntrl,
    .is_alive = Curl_cf_def_conn_is_alive,
    .keep_alive = Curl_cf_def_conn_keep_alive,
    .query = cf_capsule_query,
};

export fn Curl_cf_capsule_insert_after(cf_at: *Curl_cfilter, data: ?*Curl_easy) callconv(.c) CURLcode {
    var cf: ?*Curl_cfilter = null;
    const raw = mem.calloc(1, @sizeOf(cf_capsule_ctx)) orelse return CURLE_OUT_OF_MEMORY;
    const ctx: *cf_capsule_ctx = @ptrCast(@alignCast(raw));
    cf_capsule_ctx_init(ctx);

    const result = Curl_cf_create(&cf, &Curl_cft_capsule, ctx);
    if (result != CURLE_OK) {
        cf_capsule_ctx_clear(ctx);
        mem.freeSized(ctx, @sizeOf(cf_capsule_ctx));
        return result;
    }

    const filter = cf.?;
    Curl_conn_cf_insert_after(cf_at, filter);
    trcCf(data, filter, "created", .{});
    return CURLE_OK;
}

// ============================================================================
// Unit Tests
// ============================================================================

extern fn curl_easy_init() callconv(.c) ?*Curl_easy;
extern fn curl_easy_cleanup(handle: ?*Curl_easy) callconv(.c) void;
extern fn curl_easy_setopt(handle: ?*Curl_easy, option: c_int, ...) callconv(.c) CURLcode;

test "Curl_ipv4_resolve_r and Curl_sync_getaddrinfo numeric IPv4/IPv6" {
    const ai4 = Curl_ipv4_resolve_r("127.0.0.1", 8080);
    try std.testing.expect(ai4 != null);
    defer Curl_freeaddrinfo(ai4);
    try std.testing.expectEqual(AF_INET, ai4.?.ai_family);

    const sync4 = Curl_sync_getaddrinfo(null, CURL_DNSQ_A, "127.0.0.1", 443, TRNSPRT_TCP);
    try std.testing.expect(sync4 != null);
    defer Curl_freeaddrinfo(sync4);
    try std.testing.expectEqual(AF_INET, sync4.?.ai_family);

    const sync6 = Curl_sync_getaddrinfo(null, CURL_DNSQ_A | CURL_DNSQ_AAAA, "::1", 8443, TRNSPRT_UDP);
    try std.testing.expect(sync6 != null);
    defer Curl_freeaddrinfo(sync6);
    try std.testing.expectEqual(AF_INET6, sync6.?.ai_family);
}

test "Curl_async_failed host and proxy error codes" {
    var host_buf = "example.invalid".*;
    var peer: Curl_peer = std.mem.zeroes(Curl_peer);
    peer.hostname = &host_buf;

    var async_ctx: Curl_resolv_async = std.mem.zeroes(Curl_resolv_async);
    async_ctx.peer = &peer;
    async_ctx.dns_queries = CURL_DNSQ_A;

    const rc = Curl_async_failed(null, &async_ctx, "NXDOMAIN");
    try std.testing.expectEqual(CURLE_COULDNT_RESOLVE_HOST, rc);

    var proxy_async: Curl_resolv_async = std.mem.zeroes(Curl_resolv_async);
    proxy_async.peer = &peer;
    proxy_async.flags = Curl_resolv_async.FLAG_FOR_PROXY;
    proxy_async.dns_queries = CURL_DNSQ_A | CURL_DNSQ_AAAA;
    const prc = Curl_async_failed(null, &proxy_async, null);
    try std.testing.expectEqual(CURLE_COULDNT_RESOLVE_PROXY, prc);
}

test "Curl_cfilter recvbuf read and data_pending" {
    const raw_ctx = mem.calloc(1, @sizeOf(cf_recvbuf_ctx)).?;
    const ctx: *cf_recvbuf_ctx = @ptrCast(@alignCast(raw_ctx));
    const payload = "hello recvbuf";
    var nwritten: usize = 0;
    io_buffers.Curl_bufq_init2(
        &ctx.recvbuf,
        CURL_CF_RECVBUF_CHUNK,
        1,
        io_buffers.BUFQ_OPT_SOFT_LIMIT | io_buffers.BUFQ_OPT_NO_SPARES,
    );
    try std.testing.expectEqual(CURLE_OK, io_buffers.Curl_bufq_write(&ctx.recvbuf, payload.ptr, payload.len, &nwritten));
    try std.testing.expectEqual(payload.len, nwritten);

    var cf: Curl_cfilter = std.mem.zeroes(Curl_cfilter);
    cf.cft = &Curl_cft_recvbuf;
    cf.ctx = ctx;
    cf.setConnected(true);
    try std.testing.expect(cf.isConnected());

    try std.testing.expect(Curl_cft_recvbuf.has_data_pending(&cf, null));

    var out: [32]u8 = undefined;
    var nread: usize = 0;
    try std.testing.expectEqual(CURLE_OK, Curl_cft_recvbuf.do_recv(&cf, null, &out, 5, &nread));
    try std.testing.expectEqual(@as(usize, 5), nread);
    try std.testing.expectEqualStrings("hello", out[0..nread]);
    try std.testing.expect(Curl_cft_recvbuf.has_data_pending(&cf, null));

    try std.testing.expectEqual(CURLE_OK, Curl_cft_recvbuf.do_recv(&cf, null, &out, out.len, &nread));
    try std.testing.expectEqual(@as(usize, 8), nread);
    try std.testing.expectEqualStrings(" recvbuf", out[0..nread]);
    try std.testing.expect(!Curl_cft_recvbuf.has_data_pending(&cf, null));

    Curl_cft_recvbuf.destroy(&cf, null);
}

test "getHaproxyClientIp with curl_easy_setopt" {
    const easy = curl_easy_init() orelse return error.OutOfMemory;
    defer curl_easy_cleanup(easy);

    try std.testing.expect(getHaproxyClientIp(easy) == null);

    const CURLOPT_HAPROXY_CLIENT_IP: c_int = 10323;
    try std.testing.expectEqual(CURLE_OK, curl_easy_setopt(easy, CURLOPT_HAPROXY_CLIENT_IP, "192.0.2.42"));

    const ip = getHaproxyClientIp(easy);
    try std.testing.expect(ip != null);
    try std.testing.expectEqualStrings("192.0.2.42", std.mem.span(ip.?));
}

test "Curl_cwt_pause init, write, flush, and close" {
    const easy = curl_easy_init() orelse return error.OutOfMemory;
    defer curl_easy_cleanup(easy);

    const raw = mem.calloc(1, Curl_cwt_pause.cwriter_size).?;
    defer mem.free(raw);
    const writer: *Curl_cwriter = @ptrCast(@alignCast(raw));
    writer.cwt = &Curl_cwt_pause;
    writer.ctx = raw;

    try std.testing.expectEqual(CURLE_OK, Curl_cwt_pause.do_init(easy, writer));

    var sink_called: usize = 0;
    const MockSink = struct {
        fn doInit(_: ?*Curl_easy, _: *Curl_cwriter) callconv(.c) CURLcode {
            return CURLE_OK;
        }
        fn doWrite(_: ?*Curl_easy, w: *Curl_cwriter, _: c_int, _: [*]const u8, nbytes: usize) callconv(.c) CURLcode {
            const counter: *usize = @ptrCast(@alignCast(w.ctx.?));
            counter.* += nbytes;
            return CURLE_OK;
        }
        fn doFlush(_: ?*Curl_easy, _: *Curl_cwriter) callconv(.c) CURLcode {
            return CURLE_OK;
        }
        fn doClose(_: ?*Curl_easy, _: *Curl_cwriter) callconv(.c) void {}
    };
    const mock_cwt = Curl_cwtype{
        .name = "mock",
        .alias = null,
        .flags = 0,
        .do_init = MockSink.doInit,
        .do_write = MockSink.doWrite,
        .do_flush = MockSink.doFlush,
        .do_close = MockSink.doClose,
        .cwriter_size = @sizeOf(Curl_cwriter),
    };
    var sink_writer = Curl_cwriter{
        .cwt = &mock_cwt,
        .next = null,
        .ctx = &sink_called,
        .phase = 0,
    };
    writer.next = &sink_writer;

    cwriterSetPaused(easy, true);
    try std.testing.expect(cwriterIsPaused(easy));

    const chunk = "paused-payload";
    try std.testing.expectEqual(CURLE_OK, Curl_cwt_pause.do_write(easy, writer, 1, chunk.ptr, chunk.len));
    try std.testing.expectEqual(@as(usize, 0), sink_called);

    cwriterSetPaused(easy, false);
    try std.testing.expectEqual(CURLE_OK, Curl_cwt_pause.do_flush(easy, writer));
    try std.testing.expectEqual(chunk.len, sink_called);

    Curl_cwt_pause.do_close(easy, writer);
}

test "Curl_cft_capsule insert_after, encap, process_udp_raw, and destroy" {
    var base_cf: Curl_cfilter = std.mem.zeroes(Curl_cfilter);
    base_cf.cft = &Curl_cft_recvbuf;

    try std.testing.expectEqual(CURLE_OK, Curl_cf_capsule_insert_after(&base_cf, null));
    try std.testing.expect(base_cf.next != null);
    const cap_cf = base_cf.next.?;
    try std.testing.expectEqual(&Curl_cft_capsule, cap_cf.cft);
    try std.testing.expect(!Curl_cft_capsule.has_data_pending(cap_cf, null));

    const ctx: *cf_capsule_ctx = @ptrCast(@alignCast(cap_cf.ctx.?));
    const msg = "ping";
    try std.testing.expectEqual(CURLE_OK, Curl_capsule_encap_udp_datagram(&ctx.recvbuf, msg.ptr, msg.len));
    try std.testing.expect(Curl_cft_capsule.has_data_pending(cap_cf, null));

    var out: [16]u8 = undefined;
    var nread: usize = 0;
    try std.testing.expectEqual(CURLE_OK, Curl_cft_capsule.do_recv(cap_cf, null, &out, out.len, &nread));
    try std.testing.expectEqual(@as(usize, 4), nread);
    try std.testing.expectEqualStrings("ping", out[0..nread]);
    try std.testing.expect(!Curl_cft_capsule.has_data_pending(cap_cf, null));

    Curl_cft_capsule.destroy(cap_cf, null);
    mem.free(cap_cf);
}

// ============================================================================
// C-Zig ABI & Struct Layout Verification
// ============================================================================

comptime {
    std.debug.assert(@alignOf(Curl_peer) == 8);
    std.debug.assert(@offsetOf(Curl_peer, "scheme") == 0);
    std.debug.assert(@offsetOf(Curl_peer, "hostname") == 8);
    std.debug.assert(@offsetOf(Curl_peer, "zoneid") == 16);
    std.debug.assert(@offsetOf(Curl_peer, "refcount") == 24);
    std.debug.assert(@offsetOf(Curl_peer, "scopeid") == 28);
    std.debug.assert(@offsetOf(Curl_peer, "port") == 32);
    if (builtin.os.tag == .windows) {
        std.debug.assert(@sizeOf(Curl_peer) == 48);
        std.debug.assert(@offsetOf(Curl_peer, "user_hostname") == 40);
    } else {
        std.debug.assert(@sizeOf(Curl_peer) == 40);
        std.debug.assert(@offsetOf(Curl_peer, "user_hostname") == 35);
    }

    const httpsrr_off: usize = if (use_httpsrr) 8 else 0;
    const resolv_ctx_size: usize = if (use_resolv_threaded and use_httpsrr and use_ares)
        32
    else if (use_resolv_threaded or use_resolv_ares)
        24
    else
        0;
    std.debug.assert(@sizeOf(Curl_resolv_async) == 96 + httpsrr_off + resolv_ctx_size);
    std.debug.assert(@alignOf(Curl_resolv_async) == 8);
    std.debug.assert(@offsetOf(Curl_resolv_async, "next") == 0);
    std.debug.assert(@offsetOf(Curl_resolv_async, "peer") == 8);
    std.debug.assert(@offsetOf(Curl_resolv_async, "ai_A") == 16);
    std.debug.assert(@offsetOf(Curl_resolv_async, "ai_AAAA") == 24);
    if (use_httpsrr) {
        std.debug.assert(@offsetOf(Curl_resolv_async, "httpsrr") == 32);
    }
    if (use_resolv_ares) {
        std.debug.assert(@sizeOf(async_ares_ctx) == 24);
        std.debug.assert(@offsetOf(Curl_resolv_async, "ares") == 32 + httpsrr_off);
    }
    if (use_resolv_threaded) {
        std.debug.assert(@sizeOf(async_thrdd_ctx) == resolv_ctx_size);
        std.debug.assert(@offsetOf(Curl_resolv_async, "thrdd") == 32 + httpsrr_off);
    }
    std.debug.assert(@offsetOf(Curl_resolv_async, "doh") == 32 + httpsrr_off + resolv_ctx_size);
    std.debug.assert(@offsetOf(Curl_resolv_async, "start") == 40 + httpsrr_off + resolv_ctx_size);
    std.debug.assert(@offsetOf(Curl_resolv_async, "interval_end") == 56 + httpsrr_off + resolv_ctx_size);
    std.debug.assert(@offsetOf(Curl_resolv_async, "timeout_ms") == 64 + httpsrr_off + resolv_ctx_size);
    std.debug.assert(@offsetOf(Curl_resolv_async, "result") == 72 + httpsrr_off + resolv_ctx_size);
    std.debug.assert(@offsetOf(Curl_resolv_async, "poll_interval") == 76 + httpsrr_off + resolv_ctx_size);
    std.debug.assert(@offsetOf(Curl_resolv_async, "id") == 80 + httpsrr_off + resolv_ctx_size);
    std.debug.assert(@offsetOf(Curl_resolv_async, "dns_queries") == 84 + httpsrr_off + resolv_ctx_size);
    std.debug.assert(@offsetOf(Curl_resolv_async, "dns_responses") == 85 + httpsrr_off + resolv_ctx_size);
    std.debug.assert(@offsetOf(Curl_resolv_async, "transport") == 86 + httpsrr_off + resolv_ctx_size);
    std.debug.assert(@offsetOf(Curl_resolv_async, "queries_ongoing") == 87 + httpsrr_off + resolv_ctx_size);

    std.debug.assert(@sizeOf(Curl_cftype) == 104);
    std.debug.assert(@alignOf(Curl_cftype) == 8);
    std.debug.assert(@offsetOf(Curl_cftype, "name") == 0);
    std.debug.assert(@offsetOf(Curl_cftype, "flags") == 8);
    std.debug.assert(@offsetOf(Curl_cftype, "log_level") == 12);
    std.debug.assert(@offsetOf(Curl_cftype, "destroy") == 16);
    std.debug.assert(@offsetOf(Curl_cftype, "do_connect") == 24);
    std.debug.assert(@offsetOf(Curl_cftype, "do_shutdown") == 32);
    std.debug.assert(@offsetOf(Curl_cftype, "adjust_pollset") == 40);
    std.debug.assert(@offsetOf(Curl_cftype, "has_data_pending") == 48);
    std.debug.assert(@offsetOf(Curl_cftype, "do_send") == 56);
    std.debug.assert(@offsetOf(Curl_cftype, "do_recv") == 64);
    std.debug.assert(@offsetOf(Curl_cftype, "cntrl") == 72);
    std.debug.assert(@offsetOf(Curl_cftype, "is_alive") == 80);
    std.debug.assert(@offsetOf(Curl_cftype, "keep_alive") == 88);
    std.debug.assert(@offsetOf(Curl_cftype, "query") == 96);

    std.debug.assert(@sizeOf(Curl_cfilter) == 40);
    std.debug.assert(@alignOf(Curl_cfilter) == 8);
    std.debug.assert(@offsetOf(Curl_cfilter, "cft") == 0);
    std.debug.assert(@offsetOf(Curl_cfilter, "next") == 8);
    std.debug.assert(@offsetOf(Curl_cfilter, "ctx") == 16);
    std.debug.assert(@offsetOf(Curl_cfilter, "conn") == 24);
    std.debug.assert(@offsetOf(Curl_cfilter, "sockindex") == 32);

    std.debug.assert(@sizeOf(ip_quadruple) == 98);
    std.debug.assert(@alignOf(ip_quadruple) == 2);
    std.debug.assert(@offsetOf(ip_quadruple, "remote_ip") == 0);
    std.debug.assert(@offsetOf(ip_quadruple, "local_ip") == 46);
    std.debug.assert(@offsetOf(ip_quadruple, "remote_port") == 92);
    std.debug.assert(@offsetOf(ip_quadruple, "local_port") == 94);
    std.debug.assert(@offsetOf(ip_quadruple, "transport") == 96);

    std.debug.assert(@sizeOf(Curl_cwtype) == 64);
    std.debug.assert(@alignOf(Curl_cwtype) == 8);
    std.debug.assert(@offsetOf(Curl_cwtype, "name") == 0);
    std.debug.assert(@offsetOf(Curl_cwtype, "alias") == 8);
    std.debug.assert(@offsetOf(Curl_cwtype, "flags") == 16);
    std.debug.assert(@offsetOf(Curl_cwtype, "do_init") == 24);
    std.debug.assert(@offsetOf(Curl_cwtype, "do_write") == 32);
    std.debug.assert(@offsetOf(Curl_cwtype, "do_flush") == 40);
    std.debug.assert(@offsetOf(Curl_cwtype, "do_close") == 48);
    std.debug.assert(@offsetOf(Curl_cwtype, "cwriter_size") == 56);

    std.debug.assert(@sizeOf(Curl_cwriter) == 32);
    std.debug.assert(@alignOf(Curl_cwriter) == 8);
    std.debug.assert(@offsetOf(Curl_cwriter, "cwt") == 0);
    std.debug.assert(@offsetOf(Curl_cwriter, "next") == 8);
    std.debug.assert(@offsetOf(Curl_cwriter, "ctx") == 16);
    std.debug.assert(@offsetOf(Curl_cwriter, "phase") == 24);
}

extern fn Curl_zig_abi_sizeof_peer() callconv(.c) usize;
extern fn Curl_zig_abi_sizeof_resolv_async() callconv(.c) usize;
extern fn Curl_zig_abi_sizeof_cftype() callconv(.c) usize;
extern fn Curl_zig_abi_sizeof_cfilter() callconv(.c) usize;
extern fn Curl_zig_abi_sizeof_ip_quadruple() callconv(.c) usize;
extern fn Curl_zig_abi_sizeof_cwtype() callconv(.c) usize;
extern fn Curl_zig_abi_sizeof_cwriter() callconv(.c) usize;

test "C-Zig ABI struct sizes in vdns_cfilters" {
    try std.testing.expectEqual(@sizeOf(Curl_peer), Curl_zig_abi_sizeof_peer());
    try std.testing.expectEqual(@sizeOf(Curl_resolv_async), Curl_zig_abi_sizeof_resolv_async());
    try std.testing.expectEqual(@sizeOf(Curl_cftype), Curl_zig_abi_sizeof_cftype());
    try std.testing.expectEqual(@sizeOf(Curl_cfilter), Curl_zig_abi_sizeof_cfilter());
    try std.testing.expectEqual(@sizeOf(ip_quadruple), Curl_zig_abi_sizeof_ip_quadruple());
    try std.testing.expectEqual(@sizeOf(Curl_cwtype), Curl_zig_abi_sizeof_cwtype());
    try std.testing.expectEqual(@sizeOf(Curl_cwriter), Curl_zig_abi_sizeof_cwriter());
}
