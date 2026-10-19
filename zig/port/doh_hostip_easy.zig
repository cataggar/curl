const std = @import("std");
const builtin = @import("builtin");
const backend_options = @import("backend_options");
const primitives = @import("primitives.zig");
const containers = @import("containers.zig");
const collections = @import("collections.zig");
const mem = @import("mem.zig");
const netrc_addr_idn = @import("netrc_addr_idn.zig");
const curlx_time_net = @import("curlx_time_net.zig");
const os_leaf = @import("os_leaf.zig");
const threads_psl = @import("threads_psl.zig");
const vdns_core = @import("vdns_core.zig");
const vdns_cfilters = @import("vdns_cfilters.zig");
const cookie_getinfo_trc = @import("cookie_getinfo_trc.zig");
const altsvc_hsts_peer = @import("altsvc_hsts_peer.zig");
const protocol_version_mime = @import("protocol_version_mime.zig");

const use_c_vastart = switch (builtin.cpu.arch) {
    .x86_64 => builtin.os.tag != .windows,
    .aarch64, .aarch64_be => builtin.os.tag.isDarwin(),
    else => false,
};

pub const CURLcode = c_uint;
pub const CURLMcode = c_int;
pub const CURLsslset = c_uint;
pub const CURLINFO = c_uint;
pub const DOHcode = c_uint;
pub const DNStype = u16;
pub const timediff_t = i64;
pub const curl_off_t = i64;
pub const curl_socket_t = if (builtin.os.tag == .windows) usize else c_int;
pub const curl_socklen_t = netrc_addr_idn.curl_socklen_t;

pub const CURLE_OK: CURLcode = 0;
pub const CURLE_UNSUPPORTED_PROTOCOL: CURLcode = 1;
pub const CURLE_FAILED_INIT: CURLcode = 2;
pub const CURLE_COULDNT_RESOLVE_PROXY: CURLcode = 5;
pub const CURLE_COULDNT_RESOLVE_HOST: CURLcode = 6;
pub const CURLE_OUT_OF_MEMORY: CURLcode = 27;
pub const CURLE_OPERATION_TIMEDOUT: CURLcode = 28;
pub const CURLE_ABORTED_BY_CALLBACK: CURLcode = 42;
pub const CURLE_BAD_FUNCTION_ARGUMENT: CURLcode = 43;
pub const CURLE_SEND_ERROR: CURLcode = 55;
pub const CURLE_AGAIN: CURLcode = 81;
pub const CURLE_RECURSIVE_API_CALL: CURLcode = 94;
pub const CURLE_UNRECOVERABLE_POLL: CURLcode = 99;
pub const CURLE_TOO_LARGE: CURLcode = 100;
pub const CURLE_NOT_BUILT_IN: CURLcode = 4;
pub const CURLE_UNKNOWN_OPTION: CURLcode = 48;

pub const CURLM_OK: CURLMcode = 0;
pub const CURLM_OUT_OF_MEMORY: CURLMcode = 3;

pub const CURLMSG_DONE: c_uint = 1;

pub const CURL_SOCKET_BAD: curl_socket_t = if (builtin.os.tag == .windows) ~@as(usize, 0) else -1;
pub const FIRSTSOCKET: c_int = 0;

pub const AF_INET = curlx_time_net.AF_INET;
pub const AF_INET6 = curlx_time_net.AF_INET6;
pub const SOCK_STREAM: c_int = 1;
pub const SOCK_DGRAM: c_int = 2;
pub const IPPROTO_TCP: c_int = 6;

pub const CURL_IPRESOLVE_WHATEVER: u8 = 0;
pub const CURL_IPRESOLVE_V4: u8 = 1;
pub const CURL_IPRESOLVE_V6: u8 = 2;

pub const CURL_DNSQ_NONE: u8 = 0;
pub const CURL_DNSQ_A: u8 = 1 << 0;
pub const CURL_DNSQ_AAAA: u8 = 1 << 1;
pub const CURL_DNSQ_HTTPS: u8 = 1 << 2;
pub const CURL_DNSQ_ADDR: u8 = CURL_DNSQ_A | CURL_DNSQ_AAAA;

pub const CURL_DNS_TYPE_A: DNStype = 1;
pub const CURL_DNS_TYPE_NS: DNStype = 2;
pub const CURL_DNS_TYPE_CNAME: DNStype = 5;
pub const CURL_DNS_TYPE_AAAA: DNStype = 28;
pub const CURL_DNS_TYPE_DNAME: DNStype = 39;
pub const CURL_DNS_TYPE_HTTPS: DNStype = 65;

pub const DNS_CLASS_IN: u16 = 0x01;

pub const DOH_OK: DOHcode = 0;
pub const DOH_DNS_BAD_LABEL: DOHcode = 1;
pub const DOH_DNS_OUT_OF_RANGE: DOHcode = 2;
pub const DOH_DNS_LABEL_LOOP: DOHcode = 3;
pub const DOH_TOO_SMALL_BUFFER: DOHcode = 4;
pub const DOH_OUT_OF_MEM: DOHcode = 5;
pub const DOH_DNS_RDATA_LEN: DOHcode = 6;
pub const DOH_DNS_MALFORMAT: DOHcode = 7;
pub const DOH_DNS_BAD_RCODE: DOHcode = 8;
pub const DOH_DNS_UNEXPECTED_TYPE: DOHcode = 9;
pub const DOH_DNS_UNEXPECTED_CLASS: DOHcode = 10;
pub const DOH_NO_CONTENT: DOHcode = 11;
pub const DOH_DNS_BAD_ID: DOHcode = 12;
pub const DOH_DNS_NAME_TOO_LONG: DOHcode = 13;
pub const DOH_DNS_NXDOMAIN: DOHcode = 14;
pub const DOH_HTTP_FAILED: DOHcode = 15;
pub const DOH_OOM: DOHcode = 16;

pub const DOH_SLOT_IPV4: usize = 0;
pub const DOH_SLOT_IPV6: usize = 1;
pub const DOH_SLOT_COUNT: usize = 2;

pub const DOH_MAX_ADDR: usize = 24;
pub const DOH_MAX_CNAME: usize = 4;
pub const DOH_MAX_DNSREQ_SIZE: usize = 256 + 16;
pub const DYN_DOH_RESPONSE: usize = 3000;
pub const MAX_DNS_TTL: u32 = 86400;

pub const CURL_TIMEOUT_RESOLVE_MS: timediff_t = 300 * 1000;
pub const CURL_MAX_HTTP_HEADER: usize = 100 * 1024;
pub const CURLEASY_MAGIC_NUMBER: u32 = 0xc0dedbad;

pub const CURL_GLOBAL_SSL: c_long = 1 << 0;
pub const CURL_GLOBAL_WIN32: c_long = 1 << 1;
pub const CURL_GLOBAL_ALL: c_long = CURL_GLOBAL_SSL | CURL_GLOBAL_WIN32;
pub const CURL_GLOBAL_DEFAULT: c_long = CURL_GLOBAL_ALL;
pub const CURL_GLOBAL_WINSOCK: c_long = if (builtin.os.tag == .windows) CURL_GLOBAL_WIN32 else 0;

pub const CURLPAUSE_RECV: c_int = 1 << 0;
pub const CURLPAUSE_SEND: c_int = 1 << 2;

pub const CURL_WRITEFUNC_ERROR: usize = 0xFFFFFFFF;

pub const CURLOPT_WRITEDATA: c_uint = 10001;
pub const CURLOPT_URL: c_uint = 10002;
pub const CURLOPT_POSTFIELDS: c_uint = 10015;
pub const CURLOPT_HTTPHEADER: c_uint = 10023;
pub const CURLOPT_STDERR: c_uint = 10037;
pub const CURLOPT_VERBOSE: c_uint = 41;
pub const CURLOPT_POSTFIELDSIZE: c_uint = 60;
pub const CURLOPT_SSL_VERIFYPEER: c_uint = 64;
pub const CURLOPT_CAINFO: c_uint = 10065;
pub const CURLOPT_SSL_VERIFYHOST: c_uint = 81;
pub const CURLOPT_HTTP_VERSION: c_uint = 84;
pub const CURLOPT_DEBUGFUNCTION: c_uint = 20094;
pub const CURLOPT_DEBUGDATA: c_uint = 10095;
pub const CURLOPT_CAPATH: c_uint = 10097;
pub const CURLOPT_NOSIGNAL: c_uint = 99;
pub const CURLOPT_SHARE: c_uint = 10100;
pub const CURLOPT_SSL_CTX_FUNCTION: c_uint = 20108;
pub const CURLOPT_SSL_CTX_DATA: c_uint = 10109;
pub const CURLOPT_TIMEOUT_MS: c_uint = 155;
pub const CURLOPT_CRLFILE: c_uint = 10169;
pub const CURLOPT_CERTINFO: c_uint = 172;
pub const CURLOPT_PROTOCOLS: c_uint = 181;
pub const CURLOPT_SSL_OPTIONS: c_uint = 216;
pub const CURLOPT_SSL_VERIFYSTATUS: c_uint = 232;
pub const CURLOPT_PIPEWAIT: c_uint = 237;
pub const CURLOPT_DEFAULT_PROTOCOL: c_uint = 10238;
pub const CURLOPT_CAINFO_BLOB: c_uint = 40292;
pub const CURLOPT_SSL_EC_CURVES: c_uint = 10298;
pub const CURLOPT_WRITEFUNCTION: c_uint = 20011;

pub const CURLMOPT_MAXCONNECTS: c_uint = 6;
pub const CURLMOPT_QUICK_EXIT: c_uint = 18;

pub const CURL_HTTP_VERSION_2TLS: c_long = 4;
pub const CURLPROTO_HTTPS: c_long = 1 << 1;
pub const CURLSSLOPT_AUTO_CLIENT_CERT: c_long = 1 << 5;

pub const CURL_EAPI_FN_easy_perform: c_uint = 1;
pub const CURL_EAPI_FN_easy_perform_ev: c_uint = 2;
pub const CURL_EAPI_FN_easy_cleanup: c_uint = 3;
pub const CURL_EAPI_FN_easy_getinfo: c_uint = 4;
pub const CURL_EAPI_FN_easy_duphandle: c_uint = 5;
pub const CURL_EAPI_FN_easy_reset: c_uint = 6;
pub const CURL_EAPI_FN_easy_pause: c_uint = 7;
pub const CURL_EAPI_FN_easy_recv: c_uint = 8;
pub const CURL_EAPI_FN_easy_send: c_uint = 9;
pub const CURL_EAPI_FN_easy_upkeep: c_uint = 10;

pub const CURL_CBAPI_FN_easy_resolver_start: c_uint = 42;

pub const Curl_easy = vdns_core.Curl_easy;
pub const Curl_multi = opaque {};
pub const connectdata = vdns_core.connectdata;
pub const Curl_peer = altsvc_hsts_peer.CurlPeer;
pub const Curl_dns_entry = vdns_core.Curl_dns_entry;
pub const Curl_addrinfo = netrc_addr_idn.Curl_addrinfo;
pub const Curltime = curlx_time_net.Curltime;
pub const Dynbuf = containers.dynbuf;
pub const Curl_slist = containers.curl_slist;
pub const Curl_llist = containers.Curl_llist;
pub const Curl_hash = collections.Curl_hash;
pub const Bufref = containers.bufref;
pub const StoreNetrc = netrc_addr_idn.StoreNetrc;

pub const Curl_resolv_async = extern struct {
    next: ?*Curl_resolv_async,
    peer: ?*Curl_peer,
    ai_A: ?*Curl_addrinfo,
    ai_AAAA: ?*Curl_addrinfo,
    thrdd: vdns_cfilters.async_thrdd_ctx,
    doh: ?*anyopaque,
    start: Curltime,
    interval_end: timediff_t,
    timeout_ms: timediff_t,
    result: CURLcode,
    poll_interval: u32,
    id: u32,
    dns_queries: u8,
    dns_responses: u8,
    transport: u8,
    queries_ongoing: u8,
    flags: packed struct(u32) {
        is_ipaddr: bool = false,
        is_ipv4addr: bool = false,
        for_proxy: bool = false,
        done: bool = false,
        shutdown: bool = false,
        negative_answer: bool = false,
        _pad: u26 = 0,
    },
};

pub const Curl_eapi_guard = extern struct {
    data: ?*Curl_easy,
    depth: u8,
};

pub const Curl_mapi_guard = extern struct {
    multi: ?*Curl_multi,
    depth: u8,
};

pub const CURLMsgData = extern union {
    whatever: ?*anyopaque,
    result: CURLcode,
};

pub const CURLMsg = extern struct {
    msg: c_uint,
    easy_handle: ?*Curl_easy,
    data: CURLMsgData,
};

pub const dohaddr_ip = extern union {
    v4: [4]u8,
    v6: [16]u8,
};

pub const dohaddr = extern struct {
    type: c_int,
    ip: dohaddr_ip,
};

pub const dohentry = extern struct {
    cname: [DOH_MAX_CNAME]Dynbuf,
    addr: [DOH_MAX_ADDR]dohaddr,
    numaddr: c_int,
    ttl: c_uint,
    numcname: c_int,
};

pub const doh_request = extern struct {
    req_body: [DOH_MAX_DNSREQ_SIZE]u8,
    req_body_len: usize,
    req_hds: ?*Curl_slist,
    resp_body: Dynbuf,
    resolv_id: u32,
    dnstype: DNStype,
};

pub const doh_probes = extern struct {
    probe_mid: [DOH_SLOT_COUNT]u32,
    probe_rc: [DOH_SLOT_COUNT]DOHcode,
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

pub const Curl_meta_dtor = *const fn (key: ?*const anyopaque, key_len: usize, meta_data: ?*anyopaque) callconv(.c) void;
pub const Curl_sub_xfer_done_cb = *const fn (easy: *Curl_easy, master: *Curl_easy, result: CURLcode) callconv(.c) void;
pub const curl_resolver_start_callback = *const fn (resolver_state: ?*anyopaque, reserved: ?*anyopaque, userdata: ?*anyopaque) callconv(.c) c_int;

pub const MallocCallback = *const fn (size: usize) callconv(.c) ?*anyopaque;
pub const FreeCallback = *const fn (ptr: ?*anyopaque) callconv(.c) void;
pub const ReallocCallback = *const fn (ptr: ?*anyopaque, size: usize) callconv(.c) ?*anyopaque;
pub const StrdupCallback = *const fn (str: [*:0]const u8) callconv(.c) ?[*:0]u8;
pub const CallocCallback = *const fn (nmemb: usize, size: usize) callconv(.c) ?*anyopaque;

const Curl_sigpipe_buf = extern struct {
    bytes: [256]u8 align(16) = @splat(0),
};

// External C functions
extern fn Curl_eapi_enter(guard: *Curl_eapi_guard, data: ?*Curl_easy, fn_id: c_uint, presult: ?*CURLcode) callconv(.c) bool;
extern fn Curl_eapi_leave(guard: *Curl_eapi_guard) callconv(.c) void;
extern fn Curl_cbapi_enter(guard: *Curl_mapi_guard, data: ?*Curl_easy, multi: ?*Curl_multi, fn_id: c_uint) callconv(.c) void;
extern fn Curl_cbapi_leave(guard: *Curl_mapi_guard) callconv(.c) void;
extern fn Curl_api_multi_is_in_callback(multi: ?*Curl_multi) callconv(.c) bool;

extern fn Curl_open(curl: *?*Curl_easy) callconv(.c) CURLcode;
extern fn Curl_close(datap: *?*Curl_easy) callconv(.c) CURLcode;
extern fn Curl_freeset(data: *Curl_easy) callconv(.c) void;
extern fn Curl_init_userdefined(data: *Curl_easy) callconv(.c) void;
extern fn Curl_1st_fatal(r1: CURLcode, r2: CURLcode) callconv(.c) CURLcode;

extern fn curl_easy_setopt(data: *Curl_easy, tag: c_uint, ...) callconv(.c) CURLcode;
extern fn curl_easy_strerror(err: CURLcode) callconv(.c) [*:0]const u8;
extern fn Curl_setblobopt(blobp: *?*anyopaque, blob: ?*const anyopaque) callconv(.c) CURLcode;

extern fn Curl_multi_handle(
    easy_size: u32,
    magic_size: u32,
    conn_size: u32,
    dnscache_size: u32,
    psl_size: u32,
) callconv(.c) ?*Curl_multi;
extern fn Curl_multi_add_handle(multi: *Curl_multi, data: *Curl_easy) callconv(.c) CURLMcode;
extern fn Curl_multi_remove_handle(multi: *Curl_multi, data: *Curl_easy) callconv(.c) CURLMcode;
extern fn Curl_multi_get_easy(multi: *Curl_multi, mid: u32) callconv(.c) ?*Curl_easy;
extern fn Curl_multi_mark_dirty(data: *Curl_easy) callconv(.c) void;
extern fn Curl_update_timer(multi: *Curl_multi) callconv(.c) CURLMcode;
extern fn Curl_multi_ev_assess_xfer(multi: *Curl_multi, data: *Curl_easy) callconv(.c) CURLMcode;
extern fn curl_multi_poll(multi: *Curl_multi, extra_fds: ?*anyopaque, extra_nfds: c_uint, timeout_ms: c_int, ret: ?*c_int) callconv(.c) CURLMcode;
extern fn curl_multi_perform(multi: *Curl_multi, running_handles: *c_int) callconv(.c) CURLMcode;
extern fn curl_multi_info_read(multi: *Curl_multi, msgs_in_queue: *c_int) callconv(.c) ?*CURLMsg;
extern fn curl_multi_setopt(multi: *Curl_multi, option: c_uint, ...) callconv(.c) CURLMcode;
extern fn curl_multi_cleanup(multi: *Curl_multi) callconv(.c) CURLMcode;

extern fn Curl_timeleft_ms(data: *Curl_easy) callconv(.c) timediff_t;
extern fn Curl_pgrs_now(data: *Curl_easy) callconv(.c) *const Curltime;
extern fn Curl_cpool_upkeep(data: *Curl_easy) callconv(.c) CURLcode;

extern fn Curl_xfer_recv_is_paused(data: *Curl_easy) callconv(.c) bool;
extern fn Curl_xfer_send_is_paused(data: *Curl_easy) callconv(.c) bool;
extern fn Curl_creader_is_paused(data: *Curl_easy) callconv(.c) bool;
extern fn Curl_xfer_pause_send(data: *Curl_easy, enable: bool) callconv(.c) CURLcode;
extern fn Curl_xfer_pause_recv(data: *Curl_easy, enable: bool) callconv(.c) CURLcode;
extern fn Curl_xfer_is_blocked(data: *Curl_easy) callconv(.c) bool;

extern fn Curl_getconnectinfo(data: *Curl_easy, connp: ?*?*connectdata) callconv(.c) curl_socket_t;
extern fn Curl_attach_connection(data: *Curl_easy, conn: *connectdata, keep_Alive: bool) callconv(.c) void;
extern fn Curl_detach_connection(data: *Curl_easy) callconv(.c) void;
extern fn Curl_conn_close(data: *Curl_easy, conn: *connectdata, aborted: bool) callconv(.c) void;
extern fn Curl_conn_recv(data: *Curl_easy, num: c_int, buf: ?*anyopaque, len: usize, pnread: *usize) callconv(.c) CURLcode;
extern fn Curl_conn_send(data: *Curl_easy, num: c_int, mem_ptr: ?*const anyopaque, len: usize, more: bool, pnwritten: *usize) callconv(.c) CURLcode;

extern fn Curl_async_take_result(data: *Curl_easy, async_ctx: *Curl_resolv_async, pdns: *?*Curl_dns_entry) callconv(.c) CURLcode;
extern fn Curl_async_failed(data: *Curl_easy, async_ctx: *Curl_resolv_async, msg: ?[*:0]const u8) callconv(.c) CURLcode;
extern fn Curl_async_getaddrinfo(data: *Curl_easy, async_ctx: *Curl_resolv_async) callconv(.c) CURLcode;
extern fn Curl_async_await(data: *Curl_easy, resolv_id: u32, pdns: *?*Curl_dns_entry) callconv(.c) CURLcode;
extern fn Curl_async_shutdown(data: *Curl_easy, async_ctx: *Curl_resolv_async) callconv(.c) void;
extern fn Curl_async_destroy(data: *Curl_easy, async_ctx: *Curl_resolv_async) callconv(.c) void;
extern fn Curl_async_pollset(data: *Curl_easy, async_ctx: *Curl_resolv_async, ps: *anyopaque) callconv(.c) CURLcode;
extern fn Curl_async_global_init() callconv(.c) c_int;
extern fn Curl_async_global_cleanup() callconv(.c) void;

extern fn Curl_init_sslset_nolock(id: c_uint, name: ?[*:0]const u8, avail: ?*?*?*const anyopaque) callconv(.c) CURLsslset;
extern fn Curl_ssl_init() callconv(.c) c_int;
extern fn Curl_ssl_cleanup() callconv(.c) void;
extern var Curl_cft_ssl: u8;
extern var Curl_cft_ssl_proxy: u8;

extern fn Curl_ssh_init() callconv(.c) CURLcode;
extern fn Curl_ssh_cleanup() callconv(.c) void;

extern fn Curl_sspi_global_init() callconv(.c) CURLcode;
extern fn Curl_sspi_global_cleanup() callconv(.c) void;

extern fn Curl_hash_global_init() callconv(.c) CURLcode;
extern fn Curl_hash_init(h: *Curl_hash, slots: usize, htype: c_uint, dtor: ?collections.Curl_hash_dtor) callconv(.c) void;
extern fn Curl_hash_add2(
    h: *Curl_hash,
    key: ?*const anyopaque,
    key_len: usize,
    p: ?*anyopaque,
    dtor: ?collections.Curl_hash_elem_dtor,
) callconv(.c) ?*anyopaque;
extern fn Curl_hash_delete(h: *Curl_hash, key: ?*const anyopaque, key_len: usize) callconv(.c) c_int;
extern fn Curl_hash_pick(h: ?*Curl_hash, key: ?*const anyopaque, key_len: usize) callconv(.c) ?*anyopaque;
extern fn Curl_hash_clean(h: ?*Curl_hash) callconv(.c) void;

extern fn Curl_u8_strset_init(s: *anyopaque) callconv(.c) void;
extern fn Curl_u8_strset_copy(dst: *anyopaque, src: *const anyopaque) callconv(.c) CURLcode;
extern fn curlx_memdup0(src: ?[*]const u8, length: usize) callconv(.c) ?[*:0]u8;

extern fn Curl_failf(data: ?*Curl_easy, fmt: [*:0]const u8, ...) callconv(.c) void;
extern fn Curl_infof(data: ?*Curl_easy, fmt: [*:0]const u8, ...) callconv(.c) void;
extern fn Curl_trc_dns(data: ?*Curl_easy, fmt: [*:0]const u8, ...) callconv(.c) void;
extern var Curl_trc_feat_dns: cookie_getinfo_trc.curl_trc_feat;
extern var Curl_trc_feat_doh: cookie_getinfo_trc.curl_trc_feat;
extern fn Curl_vdns_trc_is_verbose(data: ?*const Curl_easy) callconv(.c) bool;

inline fn trcIsVerbose(data: ?*const Curl_easy) bool {
    return Curl_vdns_trc_is_verbose(data);
}

inline fn trcDnsVerbose(data: ?*const Curl_easy) bool {
    return Curl_vdns_trc_is_verbose(data) and Curl_trc_feat_dns.log_level >= cookie_getinfo_trc.CURL_LOG_LVL_INFO;
}

inline fn trcDohVerbose(data: ?*const Curl_easy) bool {
    return Curl_vdns_trc_is_verbose(data) and Curl_trc_feat_doh.log_level >= cookie_getinfo_trc.CURL_LOG_LVL_INFO;
}

extern fn Curl_getinfo(data: ?*Curl_easy, info: CURLINFO, ...) callconv(.c) CURLcode;
extern fn Curl_initinfo(data: *Curl_easy) callconv(.c) CURLcode;

extern fn Curl_dnsc_mk_addr(
    data: *Curl_easy,
    dns_queries: u8,
    pai: *?*Curl_addrinfo,
    peer: *Curl_peer,
) callconv(.c) ?*Curl_dns_entry;
extern fn Curl_dnsc_mk_addr2(
    data: *Curl_easy,
    dns_queries: u8,
    pai4: *?*Curl_addrinfo,
    pai6: *?*Curl_addrinfo,
    peer: *Curl_peer,
) callconv(.c) ?*Curl_dns_entry;
extern fn Curl_dnscache_add(data: *Curl_easy, dns: *Curl_dns_entry) callconv(.c) CURLcode;
extern fn Curl_dnscache_get(
    data: *Curl_easy,
    dns_queries: u8,
    peer: *const Curl_peer,
    pdns: *?*Curl_dns_entry,
) callconv(.c) CURLcode;
extern fn Curl_dnscache_add_negative(
    data: *Curl_easy,
    dns_queries: u8,
    peer: *const Curl_peer,
) callconv(.c) CURLcode;
extern fn Curl_dns_entry_unlink(data: ?*Curl_easy, pdns: *?*Curl_dns_entry) callconv(.c) void;

extern fn Curl_bufref_init(br: *Bufref) callconv(.c) void;
extern fn Curl_bufref_ptr(br: *const Bufref) callconv(.c) ?[*:0]const u8;
extern fn Curl_bufref_len(br: *const Bufref) callconv(.c) usize;
extern fn Curl_bufref_memdup0(br: *Bufref, ptr: ?*const anyopaque, len: usize) callconv(.c) CURLcode;
extern fn curl_slist_append(list: ?*Curl_slist, data: ?[*:0]const u8) callconv(.c) ?*Curl_slist;
extern fn Curl_slist_duplicate(inlist: ?*Curl_slist) callconv(.c) ?*Curl_slist;
extern fn curl_slist_free_all(list: ?*Curl_slist) callconv(.c) void;

// Thin accessors in lib/url.c
extern fn Curl_vdns_data_conn(data: ?*const Curl_easy) callconv(.c) ?*connectdata;
extern fn Curl_easy_str_doh(data: ?*const Curl_easy) callconv(.c) ?[*:0]const u8;
extern fn Curl_easy_str_ssl_cafile(data: ?*const Curl_easy) callconv(.c) ?[*:0]const u8;
extern fn Curl_easy_str_ssl_capath(data: ?*const Curl_easy) callconv(.c) ?[*:0]const u8;
extern fn Curl_easy_str_ssl_crlfile(data: ?*const Curl_easy) callconv(.c) ?[*:0]const u8;
extern fn Curl_easy_str_ssl_ec_curves(data: ?*const Curl_easy) callconv(.c) ?[*:0]const u8;
extern fn Curl_easy_str_altsvc(data: ?*const Curl_easy) callconv(.c) ?[*:0]const u8;
extern fn Curl_easy_str_hsts(data: ?*const Curl_easy) callconv(.c) ?[*:0]const u8;
extern fn Curl_easy_blob_cainfo(data: ?*const Curl_easy) callconv(.c) ?*anyopaque;
extern fn Curl_easy_get_multi(data: ?*const Curl_easy) callconv(.c) ?*Curl_multi;
extern fn Curl_easy_get_multi_easy(data: ?*const Curl_easy) callconv(.c) ?*Curl_multi;
extern fn Curl_easy_set_multi_easy(data: ?*Curl_easy, multi: ?*Curl_multi) callconv(.c) void;
extern fn Curl_easy_get_mid(data: ?*const Curl_easy) callconv(.c) u32;
extern fn Curl_easy_get_httpcode(data: ?*const Curl_easy) callconv(.c) c_int;
extern fn Curl_easy_get_share(data: ?*const Curl_easy) callconv(.c) ?*anyopaque;
extern fn Curl_doh_data_custom_stderr(data: ?*const Curl_easy) callconv(.c) ?*anyopaque;
extern fn Curl_easy_get_no_signal(data: ?*const Curl_easy) callconv(.c) bool;
extern fn Curl_doh_data_fdebug(data: ?*const Curl_easy) callconv(.c) ?*anyopaque;
extern fn Curl_doh_data_debugdata(data: ?*const Curl_easy) callconv(.c) ?*anyopaque;
extern fn Curl_doh_data_verifyhost(data: ?*const Curl_easy) callconv(.c) bool;
extern fn Curl_doh_data_verifypeer(data: ?*const Curl_easy) callconv(.c) bool;
extern fn Curl_doh_data_verifystatus(data: ?*const Curl_easy) callconv(.c) bool;
extern fn Curl_doh_copy_ssl_custom_flags(doh: *Curl_easy, data: *const Curl_easy) callconv(.c) void;
extern fn Curl_doh_data_ssl_certinfo(data: ?*const Curl_easy) callconv(.c) bool;
extern fn Curl_doh_data_ssl_fsslctx(data: ?*const Curl_easy) callconv(.c) ?*anyopaque;
extern fn Curl_doh_data_ssl_fsslctxp(data: ?*const Curl_easy) callconv(.c) ?*anyopaque;
extern fn Curl_doh_data_ssl_options(data: ?*const Curl_easy) callconv(.c) u8;
extern fn Curl_doh_set_feat(doh: *Curl_easy) callconv(.c) void;
extern fn Curl_doh_init_probe_state(doh: *Curl_easy, data: *const Curl_easy, cb: Curl_sub_xfer_done_cb) callconv(.c) void;
extern fn Curl_doh_clear_sub_xfer_done(probe_data: *Curl_easy) callconv(.c) void;
extern fn Curl_multi_set_ipv6_works(multi: *Curl_multi, works: bool) callconv(.c) void;
extern fn Curl_easy_ipv6_works(data: ?*const Curl_easy) callconv(.c) bool;
extern fn Curl_easy_get_resolver_start(data: ?*const Curl_easy) callconv(.c) ?curl_resolver_start_callback;
extern fn Curl_easy_get_resolver_start_client(data: ?*const Curl_easy) callconv(.c) ?*anyopaque;
extern fn Curl_multi_next_resolv_id(multi: *Curl_multi) callconv(.c) u32;
extern fn Curl_easy_get_doh(data: ?*const Curl_easy) callconv(.c) bool;
extern fn Curl_easy_get_async_head(data: ?*const Curl_easy) callconv(.c) ?*Curl_resolv_async;
extern fn Curl_easy_set_async_head(data: *Curl_easy, async_ctx: ?*Curl_resolv_async) callconv(.c) void;
extern fn Curl_easy_get_conn_scheme(data: ?*const Curl_easy) callconv(.c) ?*const anyopaque;
extern fn Curl_easy_sigpipe_ignore(data: *Curl_easy, ctx_buf: *anyopaque) callconv(.c) void;
extern fn Curl_easy_sigpipe_restore(ctx_buf: *anyopaque) callconv(.c) void;
extern fn Curl_easy_clear_error_and_errno(data: *Curl_easy) callconv(.c) void;
extern fn Curl_easy_get_maxconnects(data: ?*const Curl_easy) callconv(.c) u32;
extern fn Curl_easy_get_quick_exit(data: ?*const Curl_easy) callconv(.c) bool;
extern fn Curl_easy_sizeof() callconv(.c) usize;
extern fn Curl_easy_dupset_init(dst: *Curl_easy, src: *const Curl_easy) callconv(.c) void;
extern fn Curl_easy_get_strings(data: *Curl_easy) callconv(.c) *anyopaque;
extern fn Curl_easy_blob_count() callconv(.c) c_uint;
extern fn Curl_easy_get_blob_slot(data: *Curl_easy, idx: c_uint) callconv(.c) *?*anyopaque;
extern fn Curl_easy_get_blob_at(data: *const Curl_easy, idx: c_uint) callconv(.c) ?*const anyopaque;
extern fn Curl_easy_get_copypostfields(data: *const Curl_easy) callconv(.c) ?[*:0]u8;
extern fn Curl_easy_get_postfieldsize(data: *const Curl_easy) callconv(.c) curl_off_t;
extern fn Curl_easy_set_copypostfields(data: *Curl_easy, p: ?[*:0]u8) callconv(.c) void;
extern fn Curl_easy_get_mimepostp(data: *const Curl_easy) callconv(.c) ?*protocol_version_mime.curl_mimepart;
extern fn Curl_easy_mimepart_sizeof() callconv(.c) usize;
extern fn Curl_easy_set_mimepostp(data: *Curl_easy, p: ?*protocol_version_mime.curl_mimepart) callconv(.c) void;
extern fn Curl_easy_sync_state_resolve(dst: *Curl_easy, src: *const Curl_easy) callconv(.c) void;
extern fn Curl_easy_dup_copy_buffer_size(outcurl: *Curl_easy, data: *const Curl_easy) callconv(.c) void;
extern fn Curl_easy_get_meta_hash(data: *Curl_easy) callconv(.c) ?*Curl_hash;
extern fn Curl_easy_get_headerb(data: *Curl_easy) callconv(.c) *Dynbuf;
extern fn Curl_easy_get_state_url(data: *Curl_easy) callconv(.c) *Bufref;
extern fn Curl_easy_get_state_referer(data: *Curl_easy) callconv(.c) *Bufref;
extern fn Curl_easy_get_state_netrc(data: *Curl_easy) callconv(.c) *StoreNetrc;
extern fn Curl_easy_get_state_httphdrs(data: *Curl_easy) callconv(.c) ?*Curl_llist;
extern fn Curl_easy_dup_init_ids(outcurl: *Curl_easy) callconv(.c) void;
extern fn Curl_easy_dup_copy_progress(outcurl: *Curl_easy, data: *const Curl_easy) callconv(.c) void;
extern fn Curl_easy_has_cookie_engine(data: *const Curl_easy) callconv(.c) bool;
extern fn Curl_easy_get_cookies(data: *const Curl_easy) callconv(.c) ?*cookie_getinfo_trc.CookieInfo;
extern fn Curl_easy_set_cookies_enabled(data: *Curl_easy, ci: ?*cookie_getinfo_trc.CookieInfo) callconv(.c) void;
extern fn Curl_easy_get_state_cookielist(data: *const Curl_easy) callconv(.c) ?*Curl_slist;
extern fn Curl_easy_set_state_cookielist(data: *Curl_easy, list: ?*Curl_slist) callconv(.c) void;
extern fn Curl_easy_get_asi(data: *const Curl_easy) callconv(.c) ?*altsvc_hsts_peer.Altsvcinfo;
extern fn Curl_easy_get_asi_slot(data: *Curl_easy) callconv(.c) *?*altsvc_hsts_peer.Altsvcinfo;
extern fn Curl_easy_get_hsts(data: *const Curl_easy) callconv(.c) ?*altsvc_hsts_peer.Hsts;
extern fn Curl_easy_get_hsts_slot(data: *Curl_easy) callconv(.c) *?*altsvc_hsts_peer.Hsts;
extern fn Curl_easy_hsts_loadcb(data: *Curl_easy, h: ?*altsvc_hsts_peer.Hsts) callconv(.c) CURLcode;
extern fn Curl_easy_set_magic(data: *Curl_easy, magic: u32) callconv(.c) void;
extern fn Curl_easy_reset_conn_ids(data: *Curl_easy) callconv(.c) void;
extern fn Curl_easy_req_hard_reset(data: *Curl_easy) callconv(.c) void;
extern fn Curl_easy_zero_set(data: *Curl_easy) callconv(.c) void;
extern fn Curl_easy_zero_progress(data: *Curl_easy) callconv(.c) void;
extern fn Curl_easy_reset_post_initinfo(data: *Curl_easy) callconv(.c) void;
extern fn Curl_easy_clear_keeps_speed_sec(data: *Curl_easy) callconv(.c) void;
extern fn Curl_easy_get_state_done(data: *const Curl_easy) callconv(.c) bool;
extern fn Curl_easy_get_connect_only(data: *const Curl_easy) callconv(.c) u8;
extern fn Curl_easy_get_last_conn_id(data: *const Curl_easy) callconv(.c) curl_off_t;

// ============================================================================
// 1. lib/vdns/doh.c — DNS-over-HTTPS
// ============================================================================

const doh_code_str = [_][*:0]const u8{
    "",
    "Bad label",
    "Out of range",
    "Label loop",
    "Too small",
    "Out of memory",
    "RDATA length",
    "Malformat",
    "Bad RCODE",
    "Unexpected TYPE",
    "Unexpected CLASS",
    "No content",
    "Bad ID",
    "Name too long",
    "No such name",
    "Transport failed",
    "Out Of Memory",
};

fn doh_strerror(code: DOHcode) [*:0]const u8 {
    if (code < doh_code_str.len)
        return doh_code_str[code];
    return "bad error code";
}

fn doh_type2name(dnstype: DNStype) [*:0]const u8 {
    return switch (dnstype) {
        CURL_DNS_TYPE_A => "A",
        CURL_DNS_TYPE_AAAA => "AAAA",
        else => "unknown",
    };
}

pub export fn doh_req_encode(
    host: [*:0]const u8,
    dnstype: DNStype,
    dnsp_in: [*]u8,
    len: usize,
    olen: *usize,
) callconv(.c) DOHcode {
    const hostlen = std.mem.len(host);
    var dnsp = dnsp_in;
    var hostp = host;

    var expected_len: usize = 12 + 1 + hostlen + 4;
    if (hostlen > 0 and host[hostlen - 1] != '.')
        expected_len += 1;

    if (expected_len > DOH_MAX_DNSREQ_SIZE)
        return DOH_DNS_NAME_TOO_LONG;

    if (len < expected_len)
        return DOH_TOO_SMALL_BUFFER;

    dnsp[0] = 0;
    dnsp[1] = 0;
    dnsp[2] = 0x01;
    dnsp[3] = 0;
    dnsp[4] = 0;
    dnsp[5] = 1;
    dnsp[6] = 0;
    dnsp[7] = 0;
    dnsp[8] = 0;
    dnsp[9] = 0;
    dnsp[10] = 0;
    dnsp[11] = 0;
    dnsp += 12;

    while (hostp[0] != 0) {
        const rem = std.mem.span(hostp);
        const dot_idx = std.mem.indexOfScalar(u8, rem, '.');
        const labellen = dot_idx orelse rem.len;
        if (labellen > 63 or labellen == 0) {
            olen.* = 0;
            return DOH_DNS_BAD_LABEL;
        }
        dnsp[0] = @intCast(labellen);
        dnsp += 1;
        @memcpy(dnsp[0..labellen], hostp[0..labellen]);
        dnsp += labellen;
        hostp += labellen;
        if (dot_idx != null)
            hostp += 1;
    }

    dnsp[0] = 0;
    dnsp[1] = @intCast((dnstype >> 8) & 0xff);
    dnsp[2] = @intCast(dnstype & 0xff);
    dnsp[3] = 0;
    dnsp[4] = @intCast(DNS_CLASS_IN);
    dnsp += 5;

    olen.* = @intFromPtr(dnsp) - @intFromPtr(dnsp_in);
    return DOH_OK;
}

fn doh_probe_write_cb(
    contents: [*]const u8,
    size: usize,
    nmemb: usize,
    userp: ?*anyopaque,
) callconv(.c) usize {
    const realsize = size * nmemb;
    const data: *Curl_easy = @ptrCast(userp orelse return CURL_WRITEFUNC_ERROR);
    const doh_req_raw = Curl_meta_get(data, "ezm:doh-probe") orelse return CURL_WRITEFUNC_ERROR;
    const doh_req: *doh_request = @ptrCast(@alignCast(doh_req_raw));

    if (containers.curlx_dyn_addn(&doh_req.resp_body, contents, realsize) != CURLE_OK)
        return 0;

    return realsize;
}

fn doh_probe_dtor(key: ?*const anyopaque, klen: usize, e: ?*anyopaque) callconv(.c) void {
    _ = key;
    _ = klen;
    if (e) |raw| {
        const doh_req: *doh_request = @ptrCast(@alignCast(raw));
        curl_slist_free_all(doh_req.req_hds);
        containers.curlx_dyn_free(&doh_req.resp_body);
        mem.free(raw);
    }
}

fn setoptChecked(doh: *Curl_easy, opt: c_uint, val: anytype, out_result: *CURLcode) bool {
    const rc = curl_easy_setopt(doh, opt, val);
    out_result.* = rc;
    return !(rc != CURLE_OK and rc != CURLE_NOT_BUILT_IN and rc != CURLE_UNKNOWN_OPTION);
}

fn doh_probe_run(
    data: *Curl_easy,
    dnstype: DNStype,
    host: [*:0]const u8,
    url: [*:0]const u8,
    multi: *Curl_multi,
    resolv_id: u32,
    pmid: *u32,
) CURLcode {
    var doh: ?*Curl_easy = null;
    var result: CURLcode = CURLE_OK;
    const maybe_https = primitives.curl_strnequal(url, "http:", 5) == 0;

    pmid.* = std.math.maxInt(u32);

    const raw_req = mem.calloc(1, @sizeOf(doh_request)) orelse return CURLE_OUT_OF_MEMORY;
    var doh_req: ?*doh_request = @ptrCast(@alignCast(raw_req));
    doh_req.?.resolv_id = resolv_id;
    doh_req.?.dnstype = dnstype;
    containers.curlx_dyn_init(&doh_req.?.resp_body, DYN_DOH_RESPONSE);

    const d = doh_req_encode(
        host,
        dnstype,
        &doh_req.?.req_body,
        doh_req.?.req_body.len,
        &doh_req.?.req_body_len,
    );
    if (d != DOH_OK) {
        Curl_failf(data, "Failed to encode DoH packet [%d]", @as(c_int, @intCast(d)));
        result = CURLE_OUT_OF_MEMORY;
        return doh_probe_run_error(&doh, doh_req, result);
    }

    const timeout_ms = Curl_timeleft_ms(data);
    if (timeout_ms < 0) {
        result = CURLE_OPERATION_TIMEDOUT;
        return doh_probe_run_error(&doh, doh_req, result);
    }

    doh_req.?.req_hds = curl_slist_append(null, "Content-Type: application/dns-message");
    if (doh_req.?.req_hds == null) {
        result = CURLE_OUT_OF_MEMORY;
        return doh_probe_run_error(&doh, doh_req, result);
    }

    result = Curl_open(&doh);
    if (result != CURLE_OK or doh == null)
        return doh_probe_run_error(&doh, doh_req, result);

    const doh_h = doh.?;
    Curl_doh_set_feat(doh_h);

    if (!setoptChecked(doh_h, CURLOPT_URL, url, &result)) return doh_probe_run_error(&doh, doh_req, result);
    if (!setoptChecked(doh_h, CURLOPT_DEFAULT_PROTOCOL, @as([*:0]const u8, "https"), &result)) return doh_probe_run_error(&doh, doh_req, result);
    if (!setoptChecked(doh_h, CURLOPT_WRITEFUNCTION, &doh_probe_write_cb, &result)) return doh_probe_run_error(&doh, doh_req, result);
    if (!setoptChecked(doh_h, CURLOPT_WRITEDATA, doh_h, &result)) return doh_probe_run_error(&doh, doh_req, result);
    if (!setoptChecked(doh_h, CURLOPT_POSTFIELDS, @as([*]const u8, &doh_req.?.req_body), &result)) return doh_probe_run_error(&doh, doh_req, result);
    if (!setoptChecked(doh_h, CURLOPT_POSTFIELDSIZE, @as(c_long, @intCast(doh_req.?.req_body_len)), &result)) return doh_probe_run_error(&doh, doh_req, result);
    if (!setoptChecked(doh_h, CURLOPT_HTTPHEADER, doh_req.?.req_hds, &result)) return doh_probe_run_error(&doh, doh_req, result);

    if (backend_options.nghttp2 and maybe_https) {
        if (!setoptChecked(doh_h, CURLOPT_HTTP_VERSION, CURL_HTTP_VERSION_2TLS, &result)) return doh_probe_run_error(&doh, doh_req, result);
        if (!setoptChecked(doh_h, CURLOPT_PIPEWAIT, @as(c_long, 1), &result)) return doh_probe_run_error(&doh, doh_req, result);
    }

    if (!setoptChecked(doh_h, CURLOPT_PROTOCOLS, CURLPROTO_HTTPS, &result)) return doh_probe_run_error(&doh, doh_req, result);
    if (!setoptChecked(doh_h, CURLOPT_TIMEOUT_MS, @as(c_long, @intCast(timeout_ms)), &result)) return doh_probe_run_error(&doh, doh_req, result);
    if (!setoptChecked(doh_h, CURLOPT_SHARE, Curl_easy_get_share(data), &result)) return doh_probe_run_error(&doh, doh_req, result);

    if (Curl_doh_data_custom_stderr(data)) |custom_err| {
        if (!setoptChecked(doh_h, CURLOPT_STDERR, custom_err, &result)) return doh_probe_run_error(&doh, doh_req, result);
    }
    if (trcDohVerbose(data)) {
        if (!setoptChecked(doh_h, CURLOPT_VERBOSE, @as(c_long, 1), &result)) return doh_probe_run_error(&doh, doh_req, result);
    }
    if (Curl_easy_get_no_signal(data)) {
        if (!setoptChecked(doh_h, CURLOPT_NOSIGNAL, @as(c_long, 1), &result)) return doh_probe_run_error(&doh, doh_req, result);
    }
    if (Curl_doh_data_fdebug(data)) |fdebug| {
        if (!setoptChecked(doh_h, CURLOPT_DEBUGFUNCTION, fdebug, &result)) return doh_probe_run_error(&doh, doh_req, result);
    }
    if (Curl_doh_data_debugdata(data)) |debugdata| {
        if (!setoptChecked(doh_h, CURLOPT_DEBUGDATA, debugdata, &result)) return doh_probe_run_error(&doh, doh_req, result);
    }

    if (maybe_https) {
        if (!setoptChecked(doh_h, CURLOPT_SSL_VERIFYHOST, @as(c_long, if (Curl_doh_data_verifyhost(data)) 2 else 0), &result))
            return doh_probe_run_error(&doh, doh_req, result);
        if (!setoptChecked(doh_h, CURLOPT_SSL_VERIFYPEER, @as(c_long, if (Curl_doh_data_verifypeer(data)) 1 else 0), &result))
            return doh_probe_run_error(&doh, doh_req, result);
        if (!setoptChecked(doh_h, CURLOPT_SSL_VERIFYSTATUS, @as(c_long, if (Curl_doh_data_verifystatus(data)) 1 else 0), &result))
            return doh_probe_run_error(&doh, doh_req, result);

        Curl_doh_copy_ssl_custom_flags(doh_h, data);

        if (Curl_easy_str_ssl_cafile(data)) |cafile| {
            if (!setoptChecked(doh_h, CURLOPT_CAINFO, cafile, &result)) return doh_probe_run_error(&doh, doh_req, result);
        }
        if (Curl_easy_blob_cainfo(data)) |cainfo_blob| {
            if (!setoptChecked(doh_h, CURLOPT_CAINFO_BLOB, cainfo_blob, &result)) return doh_probe_run_error(&doh, doh_req, result);
        }
        if (Curl_easy_str_ssl_capath(data)) |capath| {
            if (!setoptChecked(doh_h, CURLOPT_CAPATH, capath, &result)) return doh_probe_run_error(&doh, doh_req, result);
        }
        if (Curl_easy_str_ssl_crlfile(data)) |crlfile| {
            if (!setoptChecked(doh_h, CURLOPT_CRLFILE, crlfile, &result)) return doh_probe_run_error(&doh, doh_req, result);
        }
        if (Curl_doh_data_ssl_certinfo(data)) {
            if (!setoptChecked(doh_h, CURLOPT_CERTINFO, @as(c_long, 1), &result)) return doh_probe_run_error(&doh, doh_req, result);
        }
        if (Curl_doh_data_ssl_fsslctx(data)) |fsslctx| {
            if (!setoptChecked(doh_h, CURLOPT_SSL_CTX_FUNCTION, fsslctx, &result)) return doh_probe_run_error(&doh, doh_req, result);
        }
        if (Curl_doh_data_ssl_fsslctxp(data)) |fsslctxp| {
            if (!setoptChecked(doh_h, CURLOPT_SSL_CTX_DATA, fsslctxp, &result)) return doh_probe_run_error(&doh, doh_req, result);
        }
        if (Curl_easy_str_ssl_ec_curves(data)) |ec_curves| {
            if (!setoptChecked(doh_h, CURLOPT_SSL_EC_CURVES, ec_curves, &result)) return doh_probe_run_error(&doh, doh_req, result);
        }
        const ssl_opts: c_long = @as(c_long, Curl_doh_data_ssl_options(data)) & ~CURLSSLOPT_AUTO_CLIENT_CERT;
        _ = curl_easy_setopt(doh_h, CURLOPT_SSL_OPTIONS, ssl_opts);
    }

    Curl_doh_init_probe_state(doh_h, data, doh_probe_done);

    result = Curl_meta_set(doh_h, "ezm:doh-probe", @ptrCast(doh_req.?), doh_probe_dtor);
    doh_req = null;
    if (result != CURLE_OK)
        return doh_probe_run_error(&doh, doh_req, result);

    if (Curl_multi_add_handle(multi, doh_h) != CURLM_OK)
        return doh_probe_run_error(&doh, doh_req, result);

    pmid.* = Curl_easy_get_mid(doh_h);
    return CURLE_OK;
}

fn doh_probe_run_error(doh: *?*Curl_easy, doh_req: ?*doh_request, result: CURLcode) CURLcode {
    _ = Curl_close(doh);
    if (doh_req) |req|
        doh_probe_dtor(null, 0, @ptrCast(req));
    return result;
}

pub export fn Curl_doh(
    data: *Curl_easy,
    async_ctx: *Curl_resolv_async,
) callconv(.c) CURLcode {
    if (async_ctx.doh != null) {
        Curl_doh_cleanup(data, async_ctx);
    }

    if (async_ctx.dns_queries == 0)
        return CURLE_BAD_FUNCTION_ARGUMENT;
    if ((async_ctx.dns_queries & CURL_DNSQ_HTTPS) != 0)
        return CURLE_NOT_BUILT_IN;

    const raw_dohp = mem.calloc(1, @sizeOf(doh_probes)) orelse return CURLE_OUT_OF_MEMORY;
    const dohp: *doh_probes = @ptrCast(@alignCast(raw_dohp));
    async_ctx.doh = raw_dohp;

    for (0..DOH_SLOT_COUNT) |i| {
        dohp.probe_rc[i] = DOH_OK;
        dohp.probe_mid[i] = std.math.maxInt(u32);
    }

    const peer = async_ctx.peer orelse {
        Curl_doh_cleanup(data, async_ctx);
        return CURLE_BAD_FUNCTION_ARGUMENT;
    };
    const doh_url = Curl_easy_str_doh(data) orelse {
        Curl_doh_cleanup(data, async_ctx);
        return CURLE_BAD_FUNCTION_ARGUMENT;
    };
    const multi = Curl_easy_get_multi(data) orelse {
        Curl_doh_cleanup(data, async_ctx);
        return CURLE_FAILED_INIT;
    };

    if ((async_ctx.dns_queries & CURL_DNSQ_AAAA) != 0) {
        const result = doh_probe_run(
            data,
            CURL_DNS_TYPE_AAAA,
            peer.hostname,
            doh_url,
            multi,
            async_ctx.id,
            &dohp.probe_mid[DOH_SLOT_IPV6],
        );
        if (result != CURLE_OK) {
            Curl_doh_cleanup(data, async_ctx);
            return result;
        }
        async_ctx.queries_ongoing += 1;
    }

    if ((async_ctx.dns_queries & CURL_DNSQ_A) != 0) {
        const result = doh_probe_run(
            data,
            CURL_DNS_TYPE_A,
            peer.hostname,
            doh_url,
            multi,
            async_ctx.id,
            &dohp.probe_mid[DOH_SLOT_IPV4],
        );
        if (result != CURLE_OK) {
            Curl_doh_cleanup(data, async_ctx);
            return result;
        }
        async_ctx.queries_ongoing += 1;
    }

    return CURLE_OK;
}

fn doh_skipqname(doh: [*]const u8, dohlen: usize, indexp: *c_uint) DOHcode {
    while (true) {
        const idx: usize = indexp.*;
        if (dohlen < idx + 1)
            return DOH_DNS_OUT_OF_RANGE;
        const length = doh[idx];
        if ((length & 0xc0) == 0xc0) {
            if (dohlen < idx + 2)
                return DOH_DNS_OUT_OF_RANGE;
            indexp.* += 2;
            break;
        }
        if ((length & 0xc0) != 0)
            return DOH_DNS_BAD_LABEL;
        if (dohlen < idx + 1 + length)
            return DOH_DNS_OUT_OF_RANGE;
        indexp.* += @intCast(1 + @as(usize, length));
        if (length == 0)
            break;
    }
    return DOH_OK;
}

fn doh_get16bit(doh: [*]const u8, index: usize) u16 {
    return (@as(u16, doh[index]) << 8) | @as(u16, doh[index + 1]);
}

fn doh_get32bit(doh: [*]const u8, index: usize) u32 {
    const p = doh + index;
    return (@as(u32, p[0]) << 24) | (@as(u32, p[1]) << 16) | (@as(u32, p[2]) << 8) | @as(u32, p[3]);
}

fn doh_store_a(doh: [*]const u8, index: usize, d: *dohentry) void {
    if (d.numaddr < DOH_MAX_ADDR) {
        const a = &d.addr[@intCast(d.numaddr)];
        a.type = CURL_DNS_TYPE_A;
        @memcpy(&a.ip.v4, doh[index .. index + 4]);
        d.numaddr += 1;
    }
}

fn doh_store_aaaa(doh: [*]const u8, index: usize, d: *dohentry) void {
    if (d.numaddr < DOH_MAX_ADDR) {
        const a = &d.addr[@intCast(d.numaddr)];
        a.type = CURL_DNS_TYPE_AAAA;
        @memcpy(&a.ip.v6, doh[index .. index + 16]);
        d.numaddr += 1;
    }
}

fn doh_rdata(
    doh: [*]const u8,
    rdlength: u16,
    rtype: u16,
    index: usize,
    d: *dohentry,
) DOHcode {
    switch (rtype) {
        CURL_DNS_TYPE_A => {
            if (rdlength != 4)
                return DOH_DNS_RDATA_LEN;
            doh_store_a(doh, index, d);
        },
        CURL_DNS_TYPE_AAAA => {
            if (rdlength != 16)
                return DOH_DNS_RDATA_LEN;
            doh_store_aaaa(doh, index, d);
        },
        else => {},
    }
    return DOH_OK;
}

pub export fn de_init(de: *dohentry) callconv(.c) void {
    @memset(std.mem.asBytes(de), 0);
    de.ttl = std.math.maxInt(c_int);
}

pub export fn doh_resp_decode(
    doh_opt: ?[*]const u8,
    dohlen: usize,
    dnstype: DNStype,
    d: *dohentry,
) callconv(.c) DOHcode {
    if (dohlen < 12)
        return DOH_TOO_SMALL_BUFFER;
    const doh = doh_opt orelse return DOH_DNS_BAD_ID;
    if (doh[0] != 0 or doh[1] != 0)
        return DOH_DNS_BAD_ID;
    const rcode = doh[3] & 0x0f;
    if (rcode == 3)
        return DOH_DNS_NXDOMAIN;
    if (rcode != 0)
        return DOH_DNS_BAD_RCODE;

    var index: c_uint = 12;
    var qdcount = doh_get16bit(doh, 4);
    while (qdcount != 0) : (qdcount -= 1) {
        const rc = doh_skipqname(doh, dohlen, &index);
        if (rc != DOH_OK)
            return rc;
        if (dohlen < @as(usize, index) + 4)
            return DOH_DNS_OUT_OF_RANGE;
        index += 4;
    }

    var ancount = doh_get16bit(doh, 6);
    while (ancount != 0) : (ancount -= 1) {
        var rc = doh_skipqname(doh, dohlen, &index);
        if (rc != DOH_OK)
            return rc;

        if (dohlen < @as(usize, index) + 2)
            return DOH_DNS_OUT_OF_RANGE;
        const rtype = doh_get16bit(doh, index);
        if (rtype != CURL_DNS_TYPE_CNAME and rtype != CURL_DNS_TYPE_DNAME and rtype != dnstype)
            return DOH_DNS_UNEXPECTED_TYPE;
        index += 2;

        if (dohlen < @as(usize, index) + 2)
            return DOH_DNS_OUT_OF_RANGE;
        const dnsclass = doh_get16bit(doh, index);
        if (dnsclass != DNS_CLASS_IN)
            return DOH_DNS_UNEXPECTED_CLASS;
        index += 2;

        if (dohlen < @as(usize, index) + 4)
            return DOH_DNS_OUT_OF_RANGE;
        var ttl = doh_get32bit(doh, index);
        if (ttl > MAX_DNS_TTL)
            ttl = MAX_DNS_TTL;
        if (ttl < d.ttl)
            d.ttl = ttl;
        index += 4;

        if (dohlen < @as(usize, index) + 2)
            return DOH_DNS_OUT_OF_RANGE;
        const rdlength = doh_get16bit(doh, index);
        index += 2;
        if (dohlen < @as(usize, index) + rdlength)
            return DOH_DNS_OUT_OF_RANGE;

        rc = doh_rdata(doh, rdlength, rtype, index, d);
        if (rc != DOH_OK)
            return rc;
        index += rdlength;
    }

    var nscount = doh_get16bit(doh, 8);
    while (nscount != 0) : (nscount -= 1) {
        const rc = doh_skipqname(doh, dohlen, &index);
        if (rc != DOH_OK)
            return rc;
        if (dohlen < @as(usize, index) + 8)
            return DOH_DNS_OUT_OF_RANGE;
        index += 2 + 2 + 4;
        if (dohlen < @as(usize, index) + 2)
            return DOH_DNS_OUT_OF_RANGE;
        const rdlength = doh_get16bit(doh, index);
        index += 2;
        if (dohlen < @as(usize, index) + rdlength)
            return DOH_DNS_OUT_OF_RANGE;
        index += rdlength;
    }

    var arcount = doh_get16bit(doh, 10);
    while (arcount != 0) : (arcount -= 1) {
        const rc = doh_skipqname(doh, dohlen, &index);
        if (rc != DOH_OK)
            return rc;
        if (dohlen < @as(usize, index) + 8)
            return DOH_DNS_OUT_OF_RANGE;
        index += 2 + 2 + 4;
        if (dohlen < @as(usize, index) + 2)
            return DOH_DNS_OUT_OF_RANGE;
        const rdlength = doh_get16bit(doh, index);
        index += 2;
        if (dohlen < @as(usize, index) + rdlength)
            return DOH_DNS_OUT_OF_RANGE;
        index += rdlength;
    }

    if (index != dohlen)
        return DOH_DNS_MALFORMAT;

    return DOH_OK;
}

fn doh2ai(
    de: *const dohentry,
    hostname: [*:0]const u8,
    port: c_int,
    aip: *?*Curl_addrinfo,
) CURLcode {
    var prevai: ?*Curl_addrinfo = null;
    var firstai: ?*Curl_addrinfo = null;
    const hostlen = std.mem.len(hostname) + 1;
    var result: CURLcode = CURLE_OK;

    const count: usize = @intCast(@max(de.numaddr, 0));
    for (0..count) |i| {
        const is_v6 = de.addr[i].type == CURL_DNS_TYPE_AAAA;
        const ss_size: usize = if (is_v6) @sizeOf(SockaddrIn6) else @sizeOf(SockaddrIn);
        const addrtype: c_int = if (is_v6) AF_INET6 else AF_INET;

        const raw = mem.calloc(1, @sizeOf(Curl_addrinfo) + ss_size + hostlen) orelse {
            result = CURLE_OUT_OF_MEMORY;
            break;
        };
        const ai: *Curl_addrinfo = @ptrCast(@alignCast(raw));
        const addr_ptr = raw + @sizeOf(Curl_addrinfo);
        const cn_ptr = addr_ptr + ss_size;

        ai.ai_addr = @ptrCast(addr_ptr);
        ai.ai_canonname = @ptrCast(cn_ptr);
        @memcpy(cn_ptr[0..hostlen], hostname[0..hostlen]);

        if (firstai == null)
            firstai = ai;
        if (prevai) |prev|
            prev.ai_next = ai;

        ai.ai_family = addrtype;
        ai.ai_socktype = SOCK_STREAM;
        ai.ai_addrlen = @intCast(ss_size);

        const net_port = std.mem.nativeToBig(u16, @intCast(port & 0xffff));
        if (!is_v6) {
            const addr: *SockaddrIn = @ptrCast(@alignCast(addr_ptr));
            @memcpy(&addr.sin_addr, &de.addr[i].ip.v4);
            addr.sin_family = @intCast(addrtype);
            addr.sin_port = net_port;
        } else {
            const addr6: *SockaddrIn6 = @ptrCast(@alignCast(addr_ptr));
            @memcpy(&addr6.sin6_addr, &de.addr[i].ip.v6);
            addr6.sin6_family = @intCast(addrtype);
            addr6.sin6_port = net_port;
        }

        prevai = ai;
    }

    if (result != CURLE_OK) {
        netrc_addr_idn.Curl_freeaddrinfo(firstai);
        firstai = null;
    }
    aip.* = firstai;
    return result;
}

pub export fn de_cleanup(d: *dohentry) callconv(.c) void {
    _ = d;
}

fn doh_probe_done(doh: *Curl_easy, master: *Curl_easy, result_in: CURLcode) callconv(.c) void {
    var result = result_in;
    var de: dohentry = undefined;
    de_init(&de);
    defer {
        Curl_multi_mark_dirty(master);
        de_cleanup(&de);
        Curl_meta_remove(doh, "ezm:doh-probe");
    }

    const doh_req_raw = Curl_meta_get(doh, "ezm:doh-probe") orelse return;
    const doh_req: *doh_request = @ptrCast(@alignCast(doh_req_raw));

    const async_ctx = Curl_async_get(master, doh_req.resolv_id) orelse {
        if (trcDnsVerbose(master)) {
            Curl_trc_dns(master, "[%u] ignoring outdated DoH response", doh_req.resolv_id);
        }
        return;
    };
    const dohp_raw = async_ctx.doh orelse return;
    const dohp: *doh_probes = @ptrCast(@alignCast(dohp_raw));

    const doh_mid = Curl_easy_get_mid(doh);
    var slot: usize = 0;
    while (slot < DOH_SLOT_COUNT) : (slot += 1) {
        if (dohp.probe_mid[slot] == doh_mid)
            break;
    }
    if (slot >= DOH_SLOT_COUNT) {
        Curl_failf(master, "DoH: unknown sub request done");
        return;
    }

    async_ctx.queries_ongoing -= 1;
    const httpcode = Curl_easy_get_httpcode(doh);
    switch (slot) {
        DOH_SLOT_IPV4 => async_ctx.dns_responses |= CURL_DNSQ_A,
        DOH_SLOT_IPV6 => async_ctx.dns_responses |= CURL_DNSQ_AAAA,
        else => {},
    }

    if (result != CURLE_OK) {
        dohp.probe_rc[slot] = DOH_HTTP_FAILED;
        if (trcIsVerbose(doh)) {
            Curl_infof(
                doh,
                "[DoH] [%s] error: %s",
                doh_type2name(doh_req.dnstype),
                curl_easy_strerror(result),
            );
        }
        return;
    } else if (httpcode < 200 or httpcode >= 300) {
        dohp.probe_rc[slot] = DOH_HTTP_FAILED;
        if (trcIsVerbose(doh)) {
            Curl_infof(
                doh,
                "[DoH] [%s] error: HTTP status %d",
                doh_type2name(doh_req.dnstype),
                httpcode,
            );
        }
        return;
    }

    dohp.probe_rc[slot] = doh_resp_decode(
        containers.curlx_dyn_uptr(&doh_req.resp_body),
        containers.curlx_dyn_len(&doh_req.resp_body),
        doh_req.dnstype,
        &de,
    );
    if (dohp.probe_rc[slot] != DOH_OK) {
        if (trcIsVerbose(doh)) {
            Curl_infof(
                doh,
                "[DoH] [%s] error decoding response: %s",
                doh_type2name(doh_req.dnstype),
                doh_strerror(dohp.probe_rc[slot]),
            );
        }
        return;
    }

    const pdest_ai: ?*?*Curl_addrinfo = if (doh_req.dnstype == CURL_DNS_TYPE_A)
        &async_ctx.ai_A
    else if (doh_req.dnstype == CURL_DNS_TYPE_AAAA)
        &async_ctx.ai_AAAA
    else
        null;

    if (pdest_ai != null and de.numaddr > 0) {
        const dest = pdest_ai.?;
        if (dest.*) |existing| {
            netrc_addr_idn.Curl_freeaddrinfo(existing);
            dest.* = null;
        }
        const peer = async_ctx.peer.?;
        result = doh2ai(&de, peer.hostname, @intCast(peer.port), dest);
        if (result != CURLE_OK) {
            if (trcIsVerbose(doh)) {
                Curl_infof(
                    doh,
                    "[DoH] [%s] error creating addrinfo: %s",
                    doh_type2name(doh_req.dnstype),
                    curl_easy_strerror(result),
                );
            }
            dohp.probe_rc[slot] = DOH_OOM;
            async_ctx.result = result;
        }
    }

    if (trcIsVerbose(doh)) {
        Curl_infof(doh, "DoH request complete, %u to go", @as(c_uint, async_ctx.queries_ongoing));
    }
}

pub export fn Curl_doh_take_result(
    data: *Curl_easy,
    async_ctx: *Curl_resolv_async,
    pdns: *?*Curl_dns_entry,
) callconv(.c) CURLcode {
    pdns.* = null;
    const dohp_raw = async_ctx.doh orelse return CURLE_OUT_OF_MEMORY;
    const dohp: *doh_probes = @ptrCast(@alignCast(dohp_raw));
    var result: CURLcode = CURLE_OK;

    async_ctx.flags.negative_answer = false;
    if (async_ctx.result != CURLE_OK) {
        result = async_ctx.result;
        Curl_doh_cleanup(data, async_ctx);
        return result;
    }

    const peer = async_ctx.peer.?;
    if ((async_ctx.dns_queries & CURL_DNSQ_ADDR) != 0 and
        dohp.probe_mid[DOH_SLOT_IPV4] == std.math.maxInt(u32) and
        dohp.probe_mid[DOH_SLOT_IPV6] == std.math.maxInt(u32))
    {
        Curl_failf(data, "Could not DoH-resolve: %s", peer.hostname);
        return if (async_ctx.flags.for_proxy)
            CURLE_COULDNT_RESOLVE_PROXY
        else
            CURLE_COULDNT_RESOLVE_HOST;
    } else if (async_ctx.queries_ongoing == 0) {
        var dns: ?*Curl_dns_entry = null;
        var negative = true;

        doh_close(data, async_ctx);
        for (0..DOH_SLOT_COUNT) |slot| {
            if (dohp.probe_rc[slot] != DOH_OK and dohp.probe_rc[slot] != DOH_DNS_NXDOMAIN)
                negative = false;
        }

        if (async_ctx.ai_A != null or async_ctx.ai_AAAA != null) {
            dns = Curl_dnsc_mk_addr2(
                data,
                async_ctx.dns_queries,
                &async_ctx.ai_A,
                &async_ctx.ai_AAAA,
                peer,
            );
            if (dns == null) {
                Curl_doh_cleanup(data, async_ctx);
                return CURLE_OUT_OF_MEMORY;
            }
        } else {
            async_ctx.flags.negative_answer = negative;
            result = if (async_ctx.flags.for_proxy)
                CURLE_COULDNT_RESOLVE_PROXY
            else
                CURLE_COULDNT_RESOLVE_HOST;
        }

        if (dns) |d_entry|
            result = Curl_dnscache_add(data, d_entry);
        pdns.* = dns;
    } else {
        return CURLE_AGAIN;
    }

    Curl_doh_cleanup(data, async_ctx);
    return result;
}

fn doh_close(data: ?*Curl_easy, async_ctx: ?*Curl_resolv_async) void {
    const a = async_ctx orelse return;
    const dohp_raw = a.doh orelse return;
    const doh: *doh_probes = @ptrCast(@alignCast(dohp_raw));
    const d = data orelse return;
    const multi = Curl_easy_get_multi(d) orelse return;

    for (0..DOH_SLOT_COUNT) |slot| {
        const mid = doh.probe_mid[slot];
        if (mid == std.math.maxInt(u32))
            continue;
        doh.probe_mid[slot] = std.math.maxInt(u32);
        const probe_data = Curl_multi_get_easy(multi, mid) orelse continue;
        Curl_doh_clear_sub_xfer_done(probe_data);
        _ = Curl_multi_remove_handle(multi, probe_data);
        var pd_opt: ?*Curl_easy = probe_data;
        _ = Curl_close(&pd_opt);
    }
    if (trcDnsVerbose(d)) {
        Curl_trc_dns(d, "[DoH] probe done");
    }
}

pub export fn Curl_doh_cleanup(
    data: ?*Curl_easy,
    async_ctx: *Curl_resolv_async,
) callconv(.c) void {
    if (async_ctx.doh) |dohp| {
        doh_close(data, async_ctx);
        mem.free(dohp);
        async_ctx.doh = null;
    }
}

// ============================================================================
// 2. lib/vdns/hostip.c — Host IP / Resolver Core
// ============================================================================

inline fn resolvFail(for_proxy: bool) CURLcode {
    return if (for_proxy) CURLE_COULDNT_RESOLVE_PROXY else CURLE_COULDNT_RESOLVE_HOST;
}

inline fn isResolvFail(result: CURLcode) bool {
    return result == CURLE_COULDNT_RESOLVE_HOST or result == CURLE_COULDNT_RESOLVE_PROXY;
}

inline fn ipv6works(data: ?*Curl_easy) bool {
    return Curl_easy_ipv6_works(data);
}

pub export fn Curl_resolv_dns_queries(data: ?*Curl_easy, ip_version: u8) callconv(.c) u8 {
    return switch (ip_version) {
        CURL_IPRESOLVE_V6 => CURL_DNSQ_AAAA,
        CURL_IPRESOLVE_V4 => CURL_DNSQ_A,
        else => if (ipv6works(data)) (CURL_DNSQ_A | CURL_DNSQ_AAAA) else CURL_DNSQ_A,
    };
}

pub export fn Curl_resolv_query_str(dns_queries: u8) callconv(.c) [*:0]const u8 {
    return switch (dns_queries) {
        (CURL_DNSQ_A | CURL_DNSQ_AAAA | CURL_DNSQ_HTTPS) => "A+AAAA+HTTPS",
        (CURL_DNSQ_A | CURL_DNSQ_AAAA) => "A+AAAA",
        (CURL_DNSQ_AAAA | CURL_DNSQ_HTTPS) => "AAAA+HTTPS",
        CURL_DNSQ_AAAA => "AAAA",
        (CURL_DNSQ_A | CURL_DNSQ_HTTPS) => "A+HTTPS",
        CURL_DNSQ_A => "A",
        CURL_DNSQ_HTTPS => "HTTPS",
        0 => "-",
        else => "???",
    };
}

pub export fn Curl_printable_address(
    ai: *const Curl_addrinfo,
    buf: [*]u8,
    bufsize: usize,
) callconv(.c) void {
    buf[0] = 0;
    const addr_raw = ai.ai_addr orelse return;
    switch (ai.ai_family) {
        AF_INET => {
            const sa4: *const SockaddrIn = @ptrCast(@alignCast(addr_raw));
            _ = curlx_time_net.curlx_inet_ntop(ai.ai_family, @ptrCast(&sa4.sin_addr), buf, bufsize);
        },
        AF_INET6 => {
            const sa6: *const SockaddrIn6 = @ptrCast(@alignCast(addr_raw));
            _ = curlx_time_net.curlx_inet_ntop(ai.ai_family, @ptrCast(&sa6.sin6_addr), buf, bufsize);
        },
        else => {},
    }
}

fn get_localhost6(port: u16, name: [*:0]const u8) ?*Curl_addrinfo {
    const ss_size = @sizeOf(SockaddrIn6);
    const hostlen = std.mem.len(name);
    var sa6: SockaddrIn6 = std.mem.zeroes(SockaddrIn6);
    var ipv6: [16]u8 = undefined;

    const raw = mem.calloc(1, @sizeOf(Curl_addrinfo) + ss_size + hostlen + 1) orelse return null;
    const ca: *Curl_addrinfo = @ptrCast(@alignCast(raw));

    sa6.sin6_family = @intCast(AF_INET6);
    sa6.sin6_port = std.mem.nativeToBig(u16, port);
    _ = curlx_time_net.curlx_inet_pton(AF_INET6, "::1", @ptrCast(&ipv6));
    @memcpy(&sa6.sin6_addr, &ipv6);

    const addr_ptr = raw + @sizeOf(Curl_addrinfo);
    const cn_ptr = addr_ptr + ss_size;

    ca.ai_flags = 0;
    ca.ai_family = AF_INET6;
    ca.ai_socktype = SOCK_STREAM;
    ca.ai_protocol = IPPROTO_TCP;
    ca.ai_addrlen = @intCast(ss_size);
    ca.ai_next = null;
    ca.ai_addr = @ptrCast(addr_ptr);
    @memcpy(addr_ptr[0..ss_size], std.mem.asBytes(&sa6));
    ca.ai_canonname = @ptrCast(cn_ptr);
    primitives.curlx_strcopy(cn_ptr, hostlen + 1, name, hostlen);
    return ca;
}

fn get_localhost(port: u16, name: [*:0]const u8) ?*Curl_addrinfo {
    const ss_size = @sizeOf(SockaddrIn);
    const hostlen = std.mem.len(name);
    var sa: SockaddrIn = std.mem.zeroes(SockaddrIn);
    var ipv4: [4]u8 = undefined;

    sa.sin_family = @intCast(AF_INET);
    sa.sin_port = std.mem.nativeToBig(u16, port);
    if (curlx_time_net.curlx_inet_pton(AF_INET, "127.0.0.1", @ptrCast(&ipv4)) < 1)
        return null;
    @memcpy(&sa.sin_addr, &ipv4);

    const raw = mem.calloc(1, @sizeOf(Curl_addrinfo) + ss_size + hostlen + 1) orelse return null;
    const ca: *Curl_addrinfo = @ptrCast(@alignCast(raw));
    const addr_ptr = raw + @sizeOf(Curl_addrinfo);
    const cn_ptr = addr_ptr + ss_size;

    ca.ai_flags = 0;
    ca.ai_family = AF_INET;
    ca.ai_socktype = SOCK_STREAM;
    ca.ai_protocol = IPPROTO_TCP;
    ca.ai_addrlen = @intCast(ss_size);
    ca.ai_addr = @ptrCast(addr_ptr);
    @memcpy(addr_ptr[0..ss_size], std.mem.asBytes(&sa));
    ca.ai_canonname = @ptrCast(cn_ptr);
    primitives.curlx_strcopy(cn_ptr, hostlen + 1, name, hostlen);

    const ca6 = get_localhost6(port, name) orelse return ca;
    ca6.ai_next = ca;
    return ca6;
}

const net_probe = if (builtin.os.tag == .windows) struct {
    const WSA_NOT_ENOUGH_MEMORY: c_int = 8;
    extern "ws2_32" fn socket(af: c_int, sock_type: c_int, protocol: c_int) callconv(.winapi) curl_socket_t;
    extern "ws2_32" fn closesocket(s: curl_socket_t) callconv(.winapi) c_int;
    extern "ws2_32" fn WSAGetLastError() callconv(.winapi) c_int;
} else struct {
    extern "c" fn socket(domain: c_int, sock_type: c_int, protocol: c_int) c_int;
    extern "c" fn close(fd: c_int) c_int;
};

pub export fn Curl_probeipv6(multi: *Curl_multi) callconv(.c) CURLcode {
    const s = net_probe.socket(AF_INET6, SOCK_DGRAM, 0);
    Curl_multi_set_ipv6_works(multi, false);
    if (s == CURL_SOCKET_BAD) {
        const is_nomem = if (builtin.os.tag == .windows)
            net_probe.WSAGetLastError() == net_probe.WSA_NOT_ENOUGH_MEMORY
        else
            std.c._errno().* == @backingInt(std.c.E.NOMEM);
        if (is_nomem)
            return CURLE_OUT_OF_MEMORY;
    } else {
        Curl_multi_set_ipv6_works(multi, true);
        if (builtin.os.tag == .windows)
            _ = net_probe.closesocket(s)
        else
            _ = net_probe.close(s);
    }
    return CURLE_OK;
}

pub export fn Curl_host_is_ipnum(hostname: [*:0]const u8) callconv(.c) bool {
    var in4: [4]u8 = undefined;
    var in6: [16]u8 = undefined;
    if (curlx_time_net.curlx_inet_pton(AF_INET, hostname, @ptrCast(&in4)) > 0 or
        curlx_time_net.curlx_inet_pton(AF_INET6, hostname, @ptrCast(&in6)) > 0)
    {
        return true;
    }
    return false;
}

fn tailmatch(full: [*:0]const u8, flen: usize, part: [*:0]const u8, plen: usize) bool {
    if (plen > flen)
        return false;
    return primitives.curl_strnequal(part, full + (flen - plen), plen) != 0;
}

fn hostip_resolv_failed(data: *Curl_easy, peer: *Curl_peer, for_proxy: bool) CURLcode {
    const kind: [*:0]const u8 = if (for_proxy) "proxy" else "host";
    Curl_failf(data, "Could not resolve %s: %s", kind, peer.hostname);
    return resolvFail(for_proxy);
}

fn can_resolve_dns_queries(data: *Curl_easy, dns_queries: u8) bool {
    if ((dns_queries & CURL_DNSQ_ADDR) == CURL_DNSQ_AAAA and !ipv6works(data))
        return false;
    return true;
}

pub export fn Curl_resolv_announce_start(
    data: *Curl_easy,
    resolver: ?*anyopaque,
) callconv(.c) CURLcode {
    if (Curl_easy_get_resolver_start(data)) |cb| {
        var guard: Curl_mapi_guard = .{ .multi = null, .depth = 0 };
        if (trcDnsVerbose(data)) {
            Curl_trc_dns(data, "announcing resolve to application");
        }
        Curl_cbapi_enter(&guard, data, null, CURL_CBAPI_FN_easy_resolver_start);
        const rc = cb(resolver, null, Curl_easy_get_resolver_start_client(data));
        Curl_cbapi_leave(&guard);
        if (rc != 0) {
            if (trcDnsVerbose(data)) {
                Curl_trc_dns(data, "application aborted resolve");
            }
            return CURLE_ABORTED_BY_CALLBACK;
        }
    }
    return CURLE_OK;
}

fn hostip_async_new(
    data: *Curl_easy,
    dns_queries: u8,
    peer: *Curl_peer,
    transport: u8,
    for_proxy: bool,
    timeout_ms: timediff_t,
) ?*Curl_resolv_async {
    const multi = Curl_easy_get_multi(data) orelse return null;
    const raw = mem.calloc(1, @sizeOf(Curl_resolv_async)) orelse return null;
    const async_ctx: *Curl_resolv_async = @ptrCast(@alignCast(raw));

    async_ctx.id = Curl_multi_next_resolv_id(multi);
    altsvc_hsts_peer.Curl_peer_link(&async_ctx.peer, peer);
    async_ctx.dns_queries = dns_queries;
    async_ctx.transport = transport;
    async_ctx.flags.for_proxy = for_proxy;
    async_ctx.start = Curl_pgrs_now(data).*;
    async_ctx.timeout_ms = timeout_ms;
    async_ctx.flags.is_ipaddr = netrc_addr_idn.Curl_is_ipaddr(peer.hostname);
    if (async_ctx.flags.is_ipaddr)
        async_ctx.flags.is_ipv4addr = netrc_addr_idn.Curl_is_ipv4addr(peer.hostname);

    return async_ctx;
}

fn hostip_resolv_take_result(
    data: *Curl_easy,
    async_ctx_opt: ?*Curl_resolv_async,
    pdns: *?*Curl_dns_entry,
) CURLcode {
    const async_ctx = async_ctx_opt orelse return CURLE_FAILED_INIT;

    var result = if (async_ctx.doh != null)
        Curl_doh_take_result(data, async_ctx, pdns)
    else
        Curl_async_take_result(data, async_ctx, pdns);

    const peer = async_ctx.peer.?;
    if (result == CURLE_AGAIN) {
        if (trcDnsVerbose(data)) {
            Curl_trc_dns(
                data,
                "[%s] resolve incomplete, responses=%s, ongoing=%d for %s:%d",
                Curl_resolv_query_str(async_ctx.dns_queries),
                Curl_resolv_query_str(async_ctx.dns_responses),
                @as(c_int, async_ctx.queries_ongoing),
                peer.hostname,
                @as(c_int, peer.port),
            );
        }
        result = CURLE_OK;
    } else if (isResolvFail(result)) {
        result = Curl_async_failed(data, async_ctx, null);
    } else if (result != CURLE_OK) {
        if (trcDnsVerbose(data)) {
            Curl_trc_dns(
                data,
                "[%s] resolve error %d for %s:%u",
                Curl_resolv_query_str(async_ctx.dns_queries),
                @as(c_int, @intCast(result)),
                peer.hostname,
                @as(c_uint, peer.port),
            );
        }
    } else {
        if (trcDnsVerbose(data)) {
            Curl_trc_dns(
                data,
                "[%s] resolve complete for %s:%u",
                Curl_resolv_query_str(async_ctx.dns_queries),
                peer.hostname,
                @as(c_uint, peer.port),
            );
        }
    }

    return result;
}

pub export fn Curl_resolv_elapsed_ms(
    data: *Curl_easy,
    resolv_id: u32,
    pnow: *const Curltime,
) callconv(.c) timediff_t {
    const async_ctx = Curl_async_get(data, resolv_id) orelse return CURL_TIMEOUT_RESOLVE_MS;
    return curlx_time_net.curlx_ptimediff_ms(pnow, &async_ctx.start);
}

pub export fn Curl_resolv_has_answers(
    data: *Curl_easy,
    resolv_id: u32,
    dns_queries: u8,
) callconv(.c) bool {
    const async_ctx = Curl_async_get(data, resolv_id) orelse return true;
    if (async_ctx.flags.done)
        return true;
    const check_queries = dns_queries & async_ctx.dns_queries;
    return (check_queries & async_ctx.dns_responses) == check_queries;
}

pub export fn Curl_resolv_get_ai(
    data: *Curl_easy,
    resolv_id: u32,
    ai_family: c_int,
    index: c_uint,
) callconv(.c) ?*const Curl_addrinfo {
    const async_ctx = Curl_async_get(data, resolv_id) orelse return null;
    if ((async_ctx.dns_queries & CURL_DNSQ_ADDR) == 0)
        return null;
    return switch (ai_family) {
        AF_INET => netrc_addr_idn.Curl_addrinfo_get(async_ctx.ai_A, ai_family, index),
        AF_INET6 => netrc_addr_idn.Curl_addrinfo_get(async_ctx.ai_AAAA, ai_family, index),
        else => null,
    };
}

fn hostip_resolv_start(
    data: *Curl_easy,
    dns_queries: u8,
    peer: *Curl_peer,
    transport: u8,
    for_proxy: bool,
    timeout_ms: timediff_t,
    allowDOH: bool,
    presolv_id: *u32,
    pdns: *?*Curl_dns_entry,
    pnegative: *bool,
) CURLcode {
    var async_ctx: ?*Curl_resolv_async = null;
    var addr: ?*Curl_addrinfo = null;
    const addr_queries = (dns_queries & (CURL_DNSQ_A | CURL_DNSQ_AAAA)) != 0;
    var result: CURLcode = CURLE_OK;

    pnegative.* = false;
    presolv_id.* = 0;
    pdns.* = null;

    if (addr_queries) {
        if (netrc_addr_idn.Curl_is_ipaddr(peer.hostname)) {
            result = Curl_resolv_announce_start(data, null);
            if (result != CURLE_OK)
                return hostip_resolv_start_out(data, dns_queries, peer, result, addr, async_ctx, presolv_id, pdns, pnegative);
            result = netrc_addr_idn.Curl_str2addr(peer.hostname, peer.port, &addr);
            return hostip_resolv_start_out(data, dns_queries, peer, result, addr, async_ctx, presolv_id, pdns, pnegative);
        }

        const hostname_len = std.mem.len(peer.hostname);
        if (primitives.curl_strequal(peer.hostname, "localhost") != 0 or
            primitives.curl_strequal(peer.hostname, "localhost.") != 0 or
            tailmatch(peer.hostname, hostname_len, ".localhost", 10) or
            tailmatch(peer.hostname, hostname_len, ".localhost.", 11))
        {
            result = Curl_resolv_announce_start(data, null);
            if (result != CURLE_OK)
                return hostip_resolv_start_out(data, dns_queries, peer, result, addr, async_ctx, presolv_id, pdns, pnegative);
            addr = get_localhost(peer.port, peer.hostname);
            if (addr == null)
                result = CURLE_OUT_OF_MEMORY;
            return hostip_resolv_start_out(data, dns_queries, peer, result, addr, async_ctx, presolv_id, pdns, pnegative);
        }
    }

    if (!netrc_addr_idn.Curl_is_ipaddr(peer.hostname) and allowDOH and Curl_easy_get_doh(data)) {
        result = Curl_resolv_announce_start(data, null);
        if (result != CURLE_OK)
            return hostip_resolv_start_out(data, dns_queries, peer, result, addr, async_ctx, presolv_id, pdns, pnegative);
        async_ctx = hostip_async_new(data, dns_queries, peer, transport, for_proxy, timeout_ms);
        if (async_ctx == null) {
            return hostip_resolv_start_out(data, dns_queries, peer, CURLE_OUT_OF_MEMORY, addr, async_ctx, presolv_id, pdns, pnegative);
        }
        result = Curl_doh(data, async_ctx.?);
        return hostip_resolv_start_out(data, dns_queries, peer, result, addr, async_ctx, presolv_id, pdns, pnegative);
    }

    if (!can_resolve_dns_queries(data, dns_queries)) {
        result = resolvFail(for_proxy);
        return hostip_resolv_start_out(data, dns_queries, peer, result, addr, async_ctx, presolv_id, pdns, pnegative);
    }

    async_ctx = hostip_async_new(data, dns_queries, peer, transport, for_proxy, timeout_ms);
    if (async_ctx == null) {
        return hostip_resolv_start_out(data, dns_queries, peer, CURLE_OUT_OF_MEMORY, addr, async_ctx, presolv_id, pdns, pnegative);
    }
    result = Curl_async_getaddrinfo(data, async_ctx.?);
    if (result == CURLE_AGAIN) {
        const r2 = hostip_resolv_take_result(data, async_ctx, pdns);
        if (r2 != CURLE_OK)
            result = r2
        else if (pdns.* != null)
            result = CURLE_OK;
    }

    return hostip_resolv_start_out(data, dns_queries, peer, result, addr, async_ctx, presolv_id, pdns, pnegative);
}

fn hostip_resolv_start_out(
    data: *Curl_easy,
    dns_queries: u8,
    peer: *Curl_peer,
    result_in: CURLcode,
    addr_in: ?*Curl_addrinfo,
    async_ctx_opt: ?*Curl_resolv_async,
    presolv_id: *u32,
    pdns: *?*Curl_dns_entry,
    pnegative: *bool,
) CURLcode {
    var result = result_in;
    var addr = addr_in;

    if (result == CURLE_OK) {
        if (addr != null) {
            pdns.* = Curl_dnsc_mk_addr(data, dns_queries, &addr, peer);
            if (pdns.* == null)
                result = CURLE_OUT_OF_MEMORY;
        } else if (pdns.* == null) {
            result = CURLE_AGAIN;
        }
    } else if (pdns.* != null) {
        Curl_dns_entry_unlink(data, pdns);
    } else if (addr != null) {
        netrc_addr_idn.Curl_freeaddrinfo(addr);
    }

    if (async_ctx_opt) |async_ctx| {
        if (result == CURLE_AGAIN) {
            presolv_id.* = async_ctx.id;
            async_ctx.next = Curl_easy_get_async_head(data);
            Curl_easy_set_async_head(data, async_ctx);
        } else {
            pnegative.* = async_ctx.flags.negative_answer;
            Curl_async_destroy(data, async_ctx);
        }
    }
    return result;
}

fn hostip_resolv(
    data: *Curl_easy,
    dns_queries: u8,
    peer: *Curl_peer,
    transport: u8,
    for_proxy: bool,
    timeout_ms: timediff_t,
    allowDOH: bool,
    presolv_id: *u32,
    pdns: *?*Curl_dns_entry,
) CURLcode {
    var result: CURLcode = resolvFail(for_proxy);
    var cache_dns = false;
    var negative = false;

    presolv_id.* = 0;
    pdns.* = null;

    const hostname_len = std.mem.len(peer.hostname);
    if (hostname_len >= 7 and
        (primitives.curl_strequal(peer.hostname + (hostname_len - 6), ".onion") != 0 or
            primitives.curl_strequal(peer.hostname + (hostname_len - 7), ".onion.") != 0))
    {
        Curl_failf(data, "Not resolving .onion address (RFC 7686)");
        return hostip_resolv_out(data, dns_queries, peer, result, cache_dns, negative, pdns);
    }

    result = Curl_dnscache_get(data, dns_queries, peer, pdns);
    if (pdns.* != null) {
        if (trcIsVerbose(data)) {
            Curl_infof(data, "Hostname %s was found in DNS cache", peer.hostname);
        }
        result = CURLE_OK;
    } else if (result != CURLE_OK) {
        if (trcIsVerbose(data)) {
            Curl_infof(data, "Negative DNS entry");
        }
        result = hostip_resolv_failed(data, peer, for_proxy);
    } else {
        cache_dns = true;
        result = hostip_resolv_start(
            data,
            dns_queries,
            peer,
            transport,
            for_proxy,
            timeout_ms,
            allowDOH,
            presolv_id,
            pdns,
            &negative,
        );
        if (trcDnsVerbose(data)) {
            Curl_trc_dns(
                data,
                "[%s] hostip_resolv started -> %d",
                Curl_resolv_query_str(dns_queries),
                @as(c_int, @intCast(result)),
            );
        }
    }

    return hostip_resolv_out(data, dns_queries, peer, result, cache_dns, negative, pdns);
}

fn hostip_resolv_out(
    data: *Curl_easy,
    dns_queries: u8,
    peer: *Curl_peer,
    result_in: CURLcode,
    cache_dns: bool,
    negative: bool,
    pdns: *?*Curl_dns_entry,
) CURLcode {
    var result = result_in;
    if (result != CURLE_OK and result != CURLE_AGAIN) {
        Curl_dns_entry_unlink(data, pdns);
        if (isResolvFail(result)) {
            if (cache_dns and negative)
                _ = Curl_dnscache_add_negative(data, dns_queries, peer);
            if ((dns_queries & (CURL_DNSQ_A | CURL_DNSQ_AAAA)) != 0) {
                Curl_failf(
                    data,
                    "Could not resolve: %s:%u",
                    peer.hostname,
                    @as(c_uint, peer.port),
                );
            }
        } else {
            Curl_failf(
                data,
                "Error %d resolving %s:%u",
                @as(c_int, @intCast(result)),
                peer.hostname,
                @as(c_uint, peer.port),
            );
        }
    } else if (cache_dns and pdns.* != null) {
        result = Curl_dnscache_add(data, pdns.*.?);
        if (result != CURLE_OK)
            Curl_dns_entry_unlink(data, pdns);
    }
    return result;
}

pub export fn Curl_resolv_blocking(
    data: *Curl_easy,
    dns_queries: u8,
    hostname: [*:0]const u8,
    port: u16,
    transport: u8,
    pdns: *?*Curl_dns_entry,
) callconv(.c) CURLcode {
    var peer: ?*Curl_peer = null;
    var resolv_id: u32 = 0;

    pdns.* = null;

    var result = altsvc_hsts_peer.Curl_peer_create(
        data,
        @ptrCast(@alignCast(Curl_easy_get_conn_scheme(data))),
        hostname,
        port,
        &peer,
    );
    if (result != CURLE_OK) {
        altsvc_hsts_peer.Curl_peer_unlink(&peer);
        return result;
    }

    result = hostip_resolv(data, dns_queries, peer.?, transport, false, 0, false, &resolv_id, pdns);
    if (result == CURLE_AGAIN) {
        result = Curl_async_await(data, resolv_id, pdns);
        Curl_resolv_destroy(data, resolv_id);
    }

    altsvc_hsts_peer.Curl_peer_unlink(&peer);
    return result;
}

fn resolv_unix(
    data: *Curl_easy,
    peer: *Curl_peer,
    pdns: *?*Curl_dns_entry,
) CURLcode {
    var addr: ?*Curl_addrinfo = null;
    pdns.* = null;

    var result = netrc_addr_idn.Curl_unix2addr(peer.hostname, peer.abstractUds(), &addr);
    if (result != CURLE_OK) {
        if (result == CURLE_TOO_LARGE) {
            Curl_failf(data, "Unix socket path too long: '%s'", peer.hostname);
            result = CURLE_COULDNT_RESOLVE_HOST;
        }
        return result;
    }

    pdns.* = Curl_dnsc_mk_addr(data, 0, &addr, peer);
    return if (pdns.* != null) CURLE_OK else CURLE_OUT_OF_MEMORY;
}

pub export fn Curl_resolv(
    data: *Curl_easy,
    peer: *Curl_peer,
    dns_queries: u8,
    transport: u8,
    for_proxy: bool,
    timeout_ms_in: timediff_t,
    presolv_id: *u32,
    pdns: *?*Curl_dns_entry,
) callconv(.c) CURLcode {
    presolv_id.* = 0;
    pdns.* = null;

    var timeout_ms = timeout_ms_in;
    if (timeout_ms < 0)
        return CURLE_OPERATION_TIMEDOUT
    else if (timeout_ms == 0)
        timeout_ms = CURL_TIMEOUT_RESOLVE_MS;

    if ((dns_queries & CURL_DNSQ_ADDR) != 0 and peer.unixSocket())
        return resolv_unix(data, peer, pdns);

    return hostip_resolv(
        data,
        dns_queries,
        peer,
        transport,
        for_proxy,
        timeout_ms,
        true,
        presolv_id,
        pdns,
    );
}

pub export fn Curl_async_get(
    data: *Curl_easy,
    resolv_id: u32,
) callconv(.c) ?*Curl_resolv_async {
    var async_ctx = Curl_easy_get_async_head(data);
    while (async_ctx) |cur| : (async_ctx = cur.next) {
        if (cur.id == resolv_id)
            return cur;
    }
    return null;
}

pub export fn Curl_resolv_take_result(
    data: *Curl_easy,
    resolv_id: u32,
    pdns: *?*Curl_dns_entry,
) callconv(.c) CURLcode {
    const async_ctx = Curl_async_get(data, resolv_id) orelse return CURLE_FAILED_INIT;
    const peer = async_ctx.peer.?;

    var result = Curl_dnscache_get(data, async_ctx.dns_queries, peer, pdns);
    if (pdns.* != null) {
        if (trcIsVerbose(data)) {
            Curl_infof(data, "Hostname '%s' was found in DNS cache", peer.hostname);
        }
        Curl_async_shutdown(data, async_ctx);
        return CURLE_OK;
    } else if (result != CURLE_OK) {
        Curl_async_shutdown(data, async_ctx);
        return Curl_async_failed(data, async_ctx, null);
    }

    result = hostip_resolv_take_result(data, async_ctx, pdns);

    if (pdns.* != null) {
        result = Curl_dnscache_add(data, pdns.*.?);
        if (result != CURLE_OK)
            Curl_dns_entry_unlink(data, pdns);
    } else if (isResolvFail(result)) {
        if (async_ctx.flags.negative_answer)
            _ = Curl_dnscache_add_negative(data, async_ctx.dns_queries, peer);
        if ((async_ctx.dns_queries & (CURL_DNSQ_A | CURL_DNSQ_AAAA)) != 0) {
            Curl_failf(
                data,
                "Could not resolve: %s:%u",
                peer.hostname,
                @as(c_uint, peer.port),
            );
        }
    } else if (result != CURLE_OK) {
        Curl_failf(
            data,
            "Error %d resolving %s:%u",
            @as(c_int, @intCast(result)),
            peer.hostname,
            @as(c_uint, peer.port),
        );
    }
    return result;
}

pub export fn Curl_resolv_pollset(
    data: *Curl_easy,
    ps: *anyopaque,
) callconv(.c) CURLcode {
    var async_ctx = Curl_easy_get_async_head(data);
    var result: CURLcode = CURLE_OK;

    while (async_ctx) |cur| : (async_ctx = cur.next) {
        if (result != CURLE_OK)
            break;
        if (cur.doh != null)
            continue;
        result = Curl_async_pollset(data, cur, ps);
    }
    return result;
}

pub export fn Curl_resolv_destroy(data: *Curl_easy, resolv_id: u32) callconv(.c) void {
    var prev: ?*Curl_resolv_async = null;
    var cur = Curl_easy_get_async_head(data);
    while (cur) |node| {
        if (node.id == resolv_id) {
            if (prev) |p| {
                p.next = node.next;
            } else {
                Curl_easy_set_async_head(data, node.next);
            }
            Curl_async_destroy(data, node);
            break;
        }
        prev = node;
        cur = node.next;
    }
}

pub export fn Curl_resolv_shutdown_all(data: *Curl_easy) callconv(.c) void {
    var async_ctx = Curl_easy_get_async_head(data);
    while (async_ctx) |cur| : (async_ctx = cur.next) {
        Curl_async_shutdown(data, cur);
    }
}

pub export fn Curl_resolv_destroy_all(data: *Curl_easy) callconv(.c) void {
    while (Curl_easy_get_async_head(data)) |async_ctx| {
        Curl_easy_set_async_head(data, async_ctx.next);
        Curl_async_destroy(data, async_ctx);
    }
}

// ============================================================================
// 3. lib/easy.c — Global Init & Easy Interface
// ============================================================================

const c_alloc = struct {
    extern "c" fn malloc(size: usize) ?*anyopaque;
    extern "c" fn free(ptr: ?*anyopaque) void;
    extern "c" fn realloc(ptr: ?*anyopaque, size: usize) ?*anyopaque;
    extern "c" fn calloc(nmemb: usize, size: usize) ?*anyopaque;
    extern "c" fn strdup(str: [*:0]const u8) ?[*:0]u8;
    extern "c" fn _strdup(str: [*:0]const u8) ?[*:0]u8;
};

const default_strdup: StrdupCallback = if (builtin.os.tag == .windows)
    &c_alloc._strdup
else
    &c_alloc.strdup;

pub export var Curl_cmalloc: MallocCallback = &c_alloc.malloc;
pub export var Curl_cfree: FreeCallback = &c_alloc.free;
pub export var Curl_crealloc: ReallocCallback = &c_alloc.realloc;
pub export var Curl_cstrdup: StrdupCallback = default_strdup;
pub export var Curl_ccalloc: CallocCallback = &c_alloc.calloc;

var initialized: c_uint = 0;
var winsock_initialized: bool = false;
var s_lock: std.atomic.Value(bool) = .init(false);

inline fn global_init_lock() void {
    while (s_lock.cmpxchgWeak(false, true, .acquire, .monotonic) != null) {
        std.atomic.spinLoopHint();
    }
}

inline fn global_init_unlock() void {
    s_lock.store(false, .release);
}

const win_wsa = if (builtin.os.tag == .windows) struct {
    extern "ws2_32" fn WSAStartup(wVersionRequested: u16, lpWSAData: *anyopaque) callconv(.winapi) c_int;
    extern "ws2_32" fn WSACleanup() callconv(.winapi) c_int;
} else struct {};

fn registerSslTrcCfts() void {
    if (backend_options.ssl != .none) {
        cookie_getinfo_trc.Curl_trc_register_ssl_cfts(@ptrCast(&Curl_cft_ssl), @ptrCast(&Curl_cft_ssl_proxy));
    } else {
        cookie_getinfo_trc.Curl_trc_register_ssl_cfts(null, null);
    }
}

fn global_init(flags: c_long, memoryfuncs: bool) CURLcode {
    const prev = initialized;
    initialized += 1;
    if (prev != 0)
        return CURLE_OK;

    if (memoryfuncs) {
        Curl_cmalloc = &c_alloc.malloc;
        Curl_cfree = &c_alloc.free;
        Curl_crealloc = &c_alloc.realloc;
        Curl_cstrdup = default_strdup;
        Curl_ccalloc = &c_alloc.calloc;
    }

    if (builtin.os.tag == .windows) {
        os_leaf.win32.curlx_verify_windows_init();
        curlx_time_net.curlx_now_init();
    }

    registerSslTrcCfts();
    if (cookie_getinfo_trc.Curl_trc_init() != CURLE_OK)
        return global_init_fail();

    if (builtin.os.tag == .windows and backend_options.ssl == .schannel) {
        if (Curl_sspi_global_init() != CURLE_OK)
            return global_init_fail();
    }

    if (builtin.os.tag == .windows) {
        if ((flags & CURL_GLOBAL_WINSOCK) != 0) {
            var wsa_buf: [512]u8 align(8) = undefined;
            if (win_wsa.WSAStartup(0x0202, @ptrCast(&wsa_buf)) != 0)
                return global_init_fail();
            winsock_initialized = true;
        }
    }

    if (backend_options.ssl != .none) {
        if (Curl_ssl_init() == 0)
            return global_init_fail();
    }

    if (Curl_hash_global_init() != CURLE_OK)
        return global_init_fail();

    if (threads_psl.Curl_amiga_init() != CURLE_OK)
        return global_init_fail();

    if (threads_psl.Curl_macos_init() != CURLE_OK)
        return global_init_fail();

    if (Curl_async_global_init() != 0)
        return global_init_fail();

    return CURLE_OK;
}

fn global_init_fail() CURLcode {
    if (builtin.os.tag == .windows) {
        if (winsock_initialized) {
            _ = win_wsa.WSACleanup();
            winsock_initialized = false;
        }
    }
    initialized -= 1;
    return CURLE_FAILED_INIT;
}

pub export fn curl_global_init(flags: c_long) callconv(.c) CURLcode {
    global_init_lock();
    defer global_init_unlock();
    return global_init(flags, true);
}

pub export fn curl_global_init_mem(
    flags: c_long,
    m: ?MallocCallback,
    f: ?FreeCallback,
    r: ?ReallocCallback,
    s: ?StrdupCallback,
    c: ?CallocCallback,
) callconv(.c) CURLcode {
    const mc = m orelse return CURLE_FAILED_INIT;
    const fc = f orelse return CURLE_FAILED_INIT;
    const rc = r orelse return CURLE_FAILED_INIT;
    const sc = s orelse return CURLE_FAILED_INIT;
    const cc = c orelse return CURLE_FAILED_INIT;

    global_init_lock();
    defer global_init_unlock();

    if (initialized != 0) {
        initialized += 1;
        return CURLE_OK;
    }

    Curl_cmalloc = mc;
    Curl_cfree = fc;
    Curl_cstrdup = sc;
    Curl_crealloc = rc;
    Curl_ccalloc = cc;

    return global_init(flags, false);
}

pub export fn curl_global_cleanup() callconv(.c) void {
    global_init_lock();
    defer global_init_unlock();

    if (initialized == 0)
        return;

    initialized -= 1;
    if (initialized != 0)
        return;

    if (backend_options.ssl != .none)
        Curl_ssl_cleanup();
    Curl_async_global_cleanup();
    threads_psl.Curl_amiga_cleanup();

    if (builtin.os.tag == .windows) {
        if (winsock_initialized) {
            _ = win_wsa.WSACleanup();
            winsock_initialized = false;
        }
    }

    if (builtin.os.tag == .windows and backend_options.ssl == .schannel)
        Curl_sspi_global_cleanup();
}

pub export fn curl_global_trace(config: ?[*:0]const u8) callconv(.c) CURLcode {
    global_init_lock();
    defer global_init_unlock();

    registerSslTrcCfts();
    return cookie_getinfo_trc.Curl_trc_opt(config);
}

pub export fn curl_global_sslset(
    id: c_uint,
    name: ?[*:0]const u8,
    avail: ?*?*?*const anyopaque,
) callconv(.c) CURLsslset {
    global_init_lock();
    defer global_init_unlock();

    return Curl_init_sslset_nolock(id, name, avail);
}

pub export fn curl_easy_init() callconv(.c) ?*Curl_easy {
    var data: ?*Curl_easy = null;

    global_init_lock();
    if (initialized == 0) {
        const result = global_init(CURL_GLOBAL_DEFAULT, true);
        if (result != CURLE_OK) {
            global_init_unlock();
            return null;
        }
    }
    global_init_unlock();

    if (Curl_open(&data) != CURLE_OK)
        return null;

    return data;
}

fn easy_transfer(multi: *Curl_multi) CURLcode {
    var done = false;
    var mresult: CURLMcode = CURLM_OK;
    var result: CURLcode = CURLE_OK;

    while (!done and mresult == CURLM_OK) {
        var still_running: c_int = 0;

        mresult = curl_multi_poll(multi, null, 0, 1000, null);
        if (mresult == CURLM_OK)
            mresult = curl_multi_perform(multi, &still_running);

        if (mresult == CURLM_OK and still_running == 0) {
            var rc: c_int = 0;
            if (curl_multi_info_read(multi, &rc)) |msg| {
                result = msg.data.result;
                done = true;
            }
        }
    }

    if (mresult != CURLM_OK) {
        result = if (mresult == CURLM_OUT_OF_MEMORY)
            CURLE_OUT_OF_MEMORY
        else
            CURLE_BAD_FUNCTION_ARGUMENT;
    }

    return result;
}

fn easy_perform(data_opt: ?*Curl_easy, events: bool) CURLcode {
    const data = data_opt orelse return CURLE_BAD_FUNCTION_ARGUMENT;
    var sigpipe_ctx: Curl_sigpipe_buf = .{};

    Curl_easy_clear_error_and_errno(data);

    if (Curl_easy_get_multi(data) != null) {
        Curl_failf(data, "easy handle already used in multi handle");
        return CURLE_FAILED_INIT;
    }

    if (Curl_vdns_data_conn(data)) |conn| {
        Curl_detach_connection(data);
        Curl_conn_close(data, conn, true);
    }

    const multi = Curl_easy_get_multi_easy(data) orelse
        (Curl_multi_handle(16, 1, 3, 7, 3) orelse return CURLE_OUT_OF_MEMORY);

    if (Curl_api_multi_is_in_callback(multi))
        return CURLE_RECURSIVE_API_CALL;

    _ = curl_multi_setopt(multi, CURLMOPT_MAXCONNECTS, @as(c_long, @intCast(Curl_easy_get_maxconnects(data))));
    _ = curl_multi_setopt(multi, CURLMOPT_QUICK_EXIT, @as(c_long, if (Curl_easy_get_quick_exit(data)) 1 else 0));

    Curl_easy_set_multi_easy(data, null);
    const mresult = Curl_multi_add_handle(multi, data);
    if (mresult != CURLM_OK) {
        _ = curl_multi_cleanup(multi);
        if (mresult == CURLM_OUT_OF_MEMORY)
            return CURLE_OUT_OF_MEMORY;
        return CURLE_FAILED_INIT;
    }

    Curl_easy_set_multi_easy(data, multi);

    Curl_easy_sigpipe_ignore(data, @ptrCast(&sigpipe_ctx));

    const result = if (events) CURLE_NOT_BUILT_IN else easy_transfer(multi);

    _ = Curl_multi_remove_handle(multi, data);

    Curl_easy_sigpipe_restore(@ptrCast(&sigpipe_ctx));

    return result;
}

pub export fn curl_easy_perform(curl: ?*Curl_easy) callconv(.c) CURLcode {
    var guard: Curl_eapi_guard = .{ .data = null, .depth = 0 };
    var result: CURLcode = CURLE_OK;

    if (Curl_eapi_enter(&guard, curl, CURL_EAPI_FN_easy_perform, &result)) {
        result = easy_perform(curl, false);
    }
    Curl_eapi_leave(&guard);
    return result;
}

pub export fn curl_easy_perform_ev(easy: ?*Curl_easy) callconv(.c) CURLcode {
    var guard: Curl_eapi_guard = .{ .data = null, .depth = 0 };
    var result: CURLcode = CURLE_OK;

    if (Curl_eapi_enter(&guard, easy, CURL_EAPI_FN_easy_perform_ev, &result)) {
        result = easy_perform(easy, true);
    }
    Curl_eapi_leave(&guard);
    return result;
}

pub export fn curl_easy_cleanup(curl: ?*Curl_easy) callconv(.c) void {
    var guard: Curl_eapi_guard = .{ .data = null, .depth = 0 };

    if (Curl_eapi_enter(&guard, curl, CURL_EAPI_FN_easy_cleanup, null)) {
        var data = curl;
        var sigpipe_ctx: Curl_sigpipe_buf = .{};
        if (data) |d| {
            Curl_easy_sigpipe_ignore(d, @ptrCast(&sigpipe_ctx));
            _ = Curl_close(&data);
            Curl_easy_sigpipe_restore(@ptrCast(&sigpipe_ctx));
        }
    }
    Curl_eapi_leave(&guard);
}

fn easyGetinfoImpl(curl: ?*Curl_easy, info: CURLINFO, paramp: ?*anyopaque) CURLcode {
    var guard: Curl_eapi_guard = .{ .data = null, .depth = 0 };
    var result: CURLcode = CURLE_OK;

    if (Curl_eapi_enter(&guard, curl, CURL_EAPI_FN_easy_getinfo, &result)) {
        result = Curl_getinfo(curl, info, paramp);
    }
    Curl_eapi_leave(&guard);
    return result;
}

const easy_getinfo_variadic_impl = if (use_c_vastart) struct {
    pub fn curl_easy_getinfo(curl: ?*Curl_easy, info: CURLINFO, ...) callconv(.c) CURLcode {
        var ap = @cVaStart();
        defer @cVaEnd(&ap);
        const paramp = @cVaArg(&ap, ?*anyopaque);
        return easyGetinfoImpl(curl, info, paramp);
    }
} else struct {
    pub fn curl_easy_getinfo(curl: ?*Curl_easy, info: CURLINFO, paramp: ?*anyopaque) callconv(.c) CURLcode {
        return easyGetinfoImpl(curl, info, paramp);
    }
};

pub const curl_easy_getinfo = easy_getinfo_variadic_impl.curl_easy_getinfo;

comptime {
    @export(&easy_getinfo_variadic_impl.curl_easy_getinfo, .{ .name = "curl_easy_getinfo", .linkage = .strong });
}

fn dupset(dst: *Curl_easy, src: *const Curl_easy) CURLcode {
    Curl_easy_dupset_init(dst, src);

    const dst_strings = Curl_easy_get_strings(dst);
    const src_strings = Curl_easy_get_strings(@constCast(src));
    Curl_u8_strset_init(dst_strings);

    var result = Curl_u8_strset_copy(dst_strings, src_strings);
    if (result != CURLE_OK)
        return result;

    const blob_count = Curl_easy_blob_count();
    var j: c_uint = 0;
    while (j < blob_count) : (j += 1) {
        result = Curl_setblobopt(
            Curl_easy_get_blob_slot(dst, j),
            Curl_easy_get_blob_at(src, j),
        );
        if (result != CURLE_OK)
            return result;
    }

    if (Curl_easy_get_copypostfields(src)) |src_pf| {
        const pfsize = Curl_easy_get_postfieldsize(src);
        const dup_pf: ?[*:0]u8 = if (pfsize == -1)
            mem.strdup(src_pf)
        else
            curlx_memdup0(src_pf, @intCast(pfsize));
        if (dup_pf == null)
            return CURLE_OUT_OF_MEMORY;
        Curl_easy_set_copypostfields(dst, dup_pf);
    }

    if (Curl_easy_get_mimepostp(src)) |src_mp| {
        const mp_size = Curl_easy_mimepart_sizeof();
        const raw_mp = mem.malloc(mp_size) orelse return CURLE_OUT_OF_MEMORY;
        const dst_mp: *protocol_version_mime.curl_mimepart = @ptrCast(@alignCast(raw_mp));
        Curl_easy_set_mimepostp(dst, dst_mp);
        protocol_version_mime.Curl_mime_initpart(dst_mp);
        result = protocol_version_mime.Curl_mime_duppart(dst, dst_mp, src_mp);
        if (result != CURLE_OK)
            return result;
    }

    Curl_easy_sync_state_resolve(dst, src);
    return CURLE_OK;
}

fn dupeasy_meta_freeentry(p: ?*anyopaque) callconv(.c) void {
    _ = p;
}

pub export fn curl_easy_duphandle(curl: ?*Curl_easy) callconv(.c) ?*Curl_easy {
    var guard: Curl_eapi_guard = .{ .data = null, .depth = 0 };
    var outcurl: ?*Curl_easy = null;

    if (Curl_eapi_enter(&guard, curl, CURL_EAPI_FN_easy_duphandle, null)) {
        const data = curl.?;
        const raw = mem.calloc(1, Curl_easy_sizeof()) orelse {
            Curl_eapi_leave(&guard);
            return null;
        };
        const out: *Curl_easy = @ptrCast(raw);
        outcurl = out;

        Curl_easy_dup_copy_buffer_size(out, data);

        Curl_hash_init(
            Curl_easy_get_meta_hash(out).?,
            23,
            collections.CURL_HASH_TYPE_BYTES,
            dupeasy_meta_freeentry,
        );
        containers.curlx_dyn_init(Curl_easy_get_headerb(out), CURL_MAX_HTTP_HEADER);
        Curl_bufref_init(Curl_easy_get_state_url(out));
        Curl_bufref_init(Curl_easy_get_state_referer(out));
        netrc_addr_idn.Curl_netrc_init(Curl_easy_get_state_netrc(out));

        Curl_easy_dup_init_ids(out);

        if (Curl_easy_get_state_httphdrs(out)) |httphdrs| {
            containers.Curl_llist_init(httphdrs, null);
        }
        _ = Curl_initinfo(out);

        if (dupset(out, data) != CURLE_OK)
            return duphandle_fail(out, &guard);

        Curl_easy_dup_copy_progress(out, data);

        if (Curl_easy_has_cookie_engine(data)) {
            const ci = cookie_getinfo_trc.Curl_cookie_init() orelse return duphandle_fail(out, &guard);
            Curl_easy_set_cookies_enabled(out, ci);
        }

        if (Curl_easy_get_state_cookielist(data)) |src_cl| {
            const dup_cl = Curl_slist_duplicate(src_cl) orelse return duphandle_fail(out, &guard);
            Curl_easy_set_state_cookielist(out, dup_cl);
        }

        const data_url = Curl_easy_get_state_url(data);
        if (Curl_bufref_ptr(data_url)) |url_ptr| {
            const out_url = Curl_easy_get_state_url(out);
            if (Curl_bufref_memdup0(out_url, url_ptr, Curl_bufref_len(data_url)) != CURLE_OK)
                return duphandle_fail(out, &guard);
        }

        const data_ref = Curl_easy_get_state_referer(data);
        if (Curl_bufref_ptr(data_ref)) |ref_ptr| {
            const out_ref = Curl_easy_get_state_referer(out);
            if (Curl_bufref_memdup0(out_ref, ref_ptr, Curl_bufref_len(data_ref)) != CURLE_OK)
                return duphandle_fail(out, &guard);
        }

        if (Curl_easy_get_asi(data) != null) {
            const asi = altsvc_hsts_peer.Curl_altsvc_init() orelse return duphandle_fail(out, &guard);
            Curl_easy_get_asi_slot(out).* = asi;
            if (Curl_easy_str_altsvc(out)) |str| {
                _ = altsvc_hsts_peer.Curl_altsvc_load(asi, str);
            }
        }

        if (Curl_easy_get_hsts(data)) |src_hsts| {
            const hsts = altsvc_hsts_peer.Curl_hsts_init() orelse return duphandle_fail(out, &guard);
            Curl_easy_get_hsts_slot(out).* = hsts;
            if (Curl_easy_str_hsts(out)) |str| {
                _ = altsvc_hsts_peer.Curl_hsts_loadfile(out, hsts, str);
            }
            _ = Curl_easy_hsts_loadcb(out, hsts);
            if (altsvc_hsts_peer.Curl_hsts_copy(hsts, src_hsts) != CURLE_OK)
                return duphandle_fail(out, &guard);
        }

        Curl_easy_set_magic(out, CURLEASY_MAGIC_NUMBER);
    }
    Curl_eapi_leave(&guard);
    return outcurl;
}

fn duphandle_fail(out: *Curl_easy, guard: *Curl_eapi_guard) ?*Curl_easy {
    if (Curl_easy_get_cookies(out)) |ci| {
        mem.free(@ptrCast(ci));
    }
    containers.curlx_dyn_free(Curl_easy_get_headerb(out));
    altsvc_hsts_peer.Curl_altsvc_cleanup(Curl_easy_get_asi_slot(out));
    altsvc_hsts_peer.Curl_hsts_cleanup(Curl_easy_get_hsts_slot(out));
    Curl_freeset(out);
    mem.free(@ptrCast(out));
    Curl_eapi_leave(guard);
    return null;
}

pub export fn curl_easy_reset(curl: ?*Curl_easy) callconv(.c) void {
    var guard: Curl_eapi_guard = .{ .data = null, .depth = 0 };

    if (Curl_eapi_enter(&guard, curl, CURL_EAPI_FN_easy_reset, null)) {
        const data = curl.?;
        Curl_easy_reset_conn_ids(data);
        Curl_easy_req_hard_reset(data);
        Curl_hash_clean(Curl_easy_get_meta_hash(data));

        Curl_meta_reset(data);
        Curl_freeset(data);
        Curl_easy_zero_set(data);
        Curl_init_userdefined(data);

        Curl_easy_zero_progress(data);
        _ = Curl_initinfo(data);
        Curl_easy_reset_post_initinfo(data);
    }
    Curl_eapi_leave(&guard);
}

pub export fn curl_easy_pause(curl: ?*Curl_easy, action: c_int) callconv(.c) CURLcode {
    var guard: Curl_eapi_guard = .{ .data = null, .depth = 0 };
    var result: CURLcode = CURLE_OK;

    if (Curl_eapi_enter(&guard, curl, CURL_EAPI_FN_easy_pause, &result)) {
        const data = curl.?;
        if (Curl_vdns_data_conn(data) == null) {
            result = CURLE_BAD_FUNCTION_ARGUMENT;
        } else {
            var changed = false;
            const recv_paused = Curl_xfer_recv_is_paused(data);
            const recv_paused_new = (action & CURLPAUSE_RECV) != 0;
            const send_paused = Curl_xfer_send_is_paused(data);
            const send_paused_new = (action & CURLPAUSE_SEND) != 0;

            if ((send_paused != send_paused_new) or (send_paused_new != Curl_creader_is_paused(data))) {
                changed = true;
                result = Curl_1st_fatal(result, Curl_xfer_pause_send(data, send_paused_new));
            }

            if (recv_paused != recv_paused_new) {
                changed = true;
                result = Curl_1st_fatal(result, Curl_xfer_pause_recv(data, recv_paused_new));
            }

            if (!Curl_xfer_is_blocked(data)) {
                Curl_easy_clear_keeps_speed_sec(data);
                if (Curl_easy_get_multi(data)) |multi| {
                    Curl_multi_mark_dirty(data);
                    if (changed and Curl_update_timer(multi) != CURLM_OK and result == CURLE_OK)
                        result = CURLE_ABORTED_BY_CALLBACK;
                }
            }

            if (result == CURLE_OK and changed and !Curl_easy_get_state_done(data)) {
                if (Curl_easy_get_multi(data)) |multi| {
                    if (Curl_multi_ev_assess_xfer(multi, data) != CURLM_OK)
                        result = CURLE_ABORTED_BY_CALLBACK;
                }
            }
        }
    }
    Curl_eapi_leave(&guard);
    return result;
}

fn easy_connection(data_opt: ?*Curl_easy, connp: *?*connectdata) CURLcode {
    const data = data_opt orelse return CURLE_BAD_FUNCTION_ARGUMENT;

    if (Curl_easy_get_connect_only(data) == 0) {
        Curl_failf(data, "CONNECT_ONLY is required");
        return CURLE_UNSUPPORTED_PROTOCOL;
    }

    const sfd = Curl_getconnectinfo(data, connp);
    if (sfd == CURL_SOCKET_BAD) {
        Curl_failf(
            data,
            "Failed to get last socket used for connection #%lld",
            @as(c_longlong, Curl_easy_get_last_conn_id(data)),
        );
        return CURLE_UNSUPPORTED_PROTOCOL;
    }

    return CURLE_OK;
}

pub export fn Curl_easy_recv(
    data: ?*Curl_easy,
    buffer: ?*anyopaque,
    buflen: usize,
    n: *usize,
) callconv(.c) CURLcode {
    var c: ?*connectdata = null;
    const result = easy_connection(data, &c);
    if (result != CURLE_OK)
        return result;

    const d = data.?;
    if (Curl_vdns_data_conn(d) == null)
        Curl_attach_connection(d, c.?, true);

    n.* = 0;
    return Curl_conn_recv(d, FIRSTSOCKET, buffer, buflen, n);
}

pub export fn curl_easy_recv(
    curl: ?*Curl_easy,
    buffer: ?*anyopaque,
    buflen: usize,
    n: ?*usize,
) callconv(.c) CURLcode {
    var guard: Curl_eapi_guard = .{ .data = null, .depth = 0 };
    var result: CURLcode = CURLE_OK;

    if (Curl_eapi_enter(&guard, curl, CURL_EAPI_FN_easy_recv, &result)) {
        if (n == null or (buflen != 0 and buffer == null)) {
            result = CURLE_BAD_FUNCTION_ARGUMENT;
        } else {
            result = Curl_easy_recv(curl, buffer, buflen, n.?);
        }
    }
    Curl_eapi_leave(&guard);
    return result;
}

pub export fn Curl_connect_only_attach(data: ?*Curl_easy) callconv(.c) CURLcode {
    var c: ?*connectdata = null;
    const result = easy_connection(data, &c);
    if (result != CURLE_OK)
        return result;

    const d = data.?;
    if (Curl_vdns_data_conn(d) == null)
        Curl_attach_connection(d, c.?, true);

    return CURLE_OK;
}

pub export fn Curl_senddata(
    data: ?*Curl_easy,
    buffer: ?*const anyopaque,
    buflen: usize,
    n: *usize,
) callconv(.c) CURLcode {
    var c: ?*connectdata = null;
    var sigpipe_ctx: Curl_sigpipe_buf = .{};

    n.* = 0;
    var result = easy_connection(data, &c);
    if (result != CURLE_OK)
        return result;

    const d = data.?;
    if (Curl_vdns_data_conn(d) == null)
        Curl_attach_connection(d, c.?, true);

    Curl_easy_sigpipe_ignore(d, @ptrCast(&sigpipe_ctx));
    result = Curl_conn_send(d, FIRSTSOCKET, buffer, buflen, false, n);
    Curl_easy_sigpipe_restore(@ptrCast(&sigpipe_ctx));

    if (result != CURLE_OK and result != CURLE_AGAIN)
        return CURLE_SEND_ERROR;
    return result;
}

pub export fn curl_easy_send(
    curl: ?*Curl_easy,
    buffer: ?*const anyopaque,
    buflen: usize,
    n: ?*usize,
) callconv(.c) CURLcode {
    var guard: Curl_eapi_guard = .{ .data = null, .depth = 0 };
    var result: CURLcode = CURLE_OK;

    if (Curl_eapi_enter(&guard, curl, CURL_EAPI_FN_easy_send, &result)) {
        if (n == null or (buflen != 0 and buffer == null)) {
            result = CURLE_BAD_FUNCTION_ARGUMENT;
        } else {
            var written: usize = 0;
            result = Curl_senddata(curl, buffer, buflen, &written);
            n.?.* = written;
        }
    }
    Curl_eapi_leave(&guard);
    return result;
}

pub export fn curl_easy_upkeep(curl: ?*Curl_easy) callconv(.c) CURLcode {
    var guard: Curl_eapi_guard = .{ .data = null, .depth = 0 };
    var result: CURLcode = CURLE_OK;

    if (Curl_eapi_enter(&guard, curl, CURL_EAPI_FN_easy_upkeep, &result)) {
        result = Curl_cpool_upkeep(curl.?);
    }
    Curl_eapi_leave(&guard);
    return result;
}

pub export fn curl_easy_ssls_import(
    curl: ?*Curl_easy,
    session_key: ?[*:0]const u8,
    shmac: ?[*]const u8,
    shmac_len: usize,
    sdata: ?[*]const u8,
    sdata_len: usize,
) callconv(.c) CURLcode {
    _ = curl;
    _ = session_key;
    _ = shmac;
    _ = shmac_len;
    _ = sdata;
    _ = sdata_len;
    return CURLE_NOT_BUILT_IN;
}

pub export fn curl_easy_ssls_export(
    curl: ?*Curl_easy,
    export_fn: ?*const anyopaque,
    userptr: ?*anyopaque,
) callconv(.c) CURLcode {
    _ = curl;
    _ = export_fn;
    _ = userptr;
    return CURLE_NOT_BUILT_IN;
}

pub export fn Curl_meta_set(
    data: *Curl_easy,
    key: [*:0]const u8,
    meta_data: ?*anyopaque,
    meta_dtor: Curl_meta_dtor,
) callconv(.c) CURLcode {
    const key_len = std.mem.len(key);
    const mh = Curl_easy_get_meta_hash(data).?;
    if (Curl_hash_add2(mh, @ptrCast(key), key_len + 1, meta_data, meta_dtor) == null) {
        meta_dtor(@ptrCast(key), key_len + 1, meta_data);
        return CURLE_OUT_OF_MEMORY;
    }
    return CURLE_OK;
}

pub export fn Curl_meta_remove(data: *Curl_easy, key: [*:0]const u8) callconv(.c) void {
    const key_len = std.mem.len(key);
    _ = Curl_hash_delete(Curl_easy_get_meta_hash(data).?, @ptrCast(key), key_len + 1);
}

pub export fn Curl_meta_get(data: *Curl_easy, key: [*:0]const u8) callconv(.c) ?*anyopaque {
    const key_len = std.mem.len(key);
    return Curl_hash_pick(Curl_easy_get_meta_hash(data), @ptrCast(key), key_len + 1);
}

pub export fn Curl_meta_reset(data: *Curl_easy) callconv(.c) void {
    Curl_hash_clean(Curl_easy_get_meta_hash(data));
}

// ============================================================================
// Unit Tests
// ============================================================================

test "doh_req_encode and doh_resp_decode" {
    var buf: [DOH_MAX_DNSREQ_SIZE]u8 = undefined;
    var olen: usize = 0;

    try std.testing.expectEqual(
        DOH_OK,
        doh_req_encode("example.com", CURL_DNS_TYPE_A, &buf, buf.len, &olen),
    );
    try std.testing.expectEqual(@as(usize, 29), olen);

    try std.testing.expectEqual(
        DOH_DNS_BAD_LABEL,
        doh_req_encode(".example.com", CURL_DNS_TYPE_A, &buf, buf.len, &olen),
    );
    try std.testing.expectEqual(
        DOH_TOO_SMALL_BUFFER,
        doh_req_encode("example.com", CURL_DNS_TYPE_A, &buf, 10, &olen),
    );

    // Construct a minimal DNS A response for example.com -> 93.184.216.34
    const resp = [_]u8{
        0x00, 0x00, // ID = 0
        0x81, 0x80, // QR=1, RD=1, RA=1, RCODE=0
        0x00, 0x01, // QDCOUNT = 1
        0x00, 0x01, // ANCOUNT = 1
        0x00, 0x00, // NSCOUNT = 0
        0x00, 0x00, // ARCOUNT = 0
        // Question: 7example3com0, QTYPE=A(1), QCLASS=IN(1)
        0x07, 'e',
        'x',  'a',
        'm',  'p',
        'l',  'e',
        0x03, 'c',
        'o',  'm',
        0x00, 0x00,
        0x01, 0x00,
        0x01,
        // Answer: pointer 0xc00c, TYPE=A(1), CLASS=IN(1), TTL=300, RDLENGTH=4, 93.184.216.34
        0xc0,
        0x0c, 0x00,
        0x01, 0x00,
        0x01, 0x00,
        0x00, 0x01,
        0x2c, 0x00,
        0x04, 93,
        184,  216,
        34,
    };

    var de: dohentry = undefined;
    de_init(&de);
    defer de_cleanup(&de);

    try std.testing.expectEqual(
        DOH_OK,
        doh_resp_decode(&resp, resp.len, CURL_DNS_TYPE_A, &de),
    );
    try std.testing.expectEqual(@as(c_int, 1), de.numaddr);
    try std.testing.expectEqual(@as(c_uint, 300), de.ttl);
    try std.testing.expectEqualSlices(u8, &[_]u8{ 93, 184, 216, 34 }, &de.addr[0].ip.v4);
}

test "Curl_resolv_query_str, Curl_host_is_ipnum, and Curl_printable_address" {
    try std.testing.expectEqualStrings("A", std.mem.span(Curl_resolv_query_str(CURL_DNSQ_A)));
    try std.testing.expectEqualStrings("A+AAAA", std.mem.span(Curl_resolv_query_str(CURL_DNSQ_A | CURL_DNSQ_AAAA)));
    try std.testing.expectEqualStrings("-", std.mem.span(Curl_resolv_query_str(0)));

    try std.testing.expect(Curl_host_is_ipnum("127.0.0.1"));
    try std.testing.expect(Curl_host_is_ipnum("::1"));
    try std.testing.expect(!Curl_host_is_ipnum("example.com"));

    const ca = get_localhost(80, "localhost") orelse return error.OutOfMemory;
    defer netrc_addr_idn.Curl_freeaddrinfo(ca);

    var pbuf: [64]u8 = undefined;
    Curl_printable_address(ca, &pbuf, pbuf.len);
    try std.testing.expectEqualStrings("::1", std.mem.sliceTo(&pbuf, 0));
    if (ca.ai_next) |next_ai| {
        Curl_printable_address(next_ai, &pbuf, pbuf.len);
        try std.testing.expectEqualStrings("127.0.0.1", std.mem.sliceTo(&pbuf, 0));
    }
}

fn testMetaDtor(key: ?*const anyopaque, key_len: usize, meta_data: ?*anyopaque) callconv(.c) void {
    _ = key;
    _ = key_len;
    if (meta_data) |p| {
        const flag: *bool = @ptrCast(@alignCast(p));
        flag.* = true;
    }
}

test "curl_easy_init, curl_easy_duphandle, curl_easy_reset, and Curl_meta_*" {
    try std.testing.expectEqual(CURLE_OK, curl_global_init(CURL_GLOBAL_DEFAULT));
    defer curl_global_cleanup();

    const easy = curl_easy_init() orelse return error.OutOfMemory;
    defer curl_easy_cleanup(easy);

    var dtor_called = false;
    try std.testing.expectEqual(
        CURLE_OK,
        Curl_meta_set(easy, "test-meta-key", @ptrCast(&dtor_called), testMetaDtor),
    );
    try std.testing.expectEqual(@as(?*anyopaque, @ptrCast(&dtor_called)), Curl_meta_get(easy, "test-meta-key"));
    Curl_meta_remove(easy, "test-meta-key");
    try std.testing.expect(dtor_called);
    try std.testing.expectEqual(@as(?*anyopaque, null), Curl_meta_get(easy, "test-meta-key"));

    const dup = curl_easy_duphandle(easy) orelse return error.OutOfMemory;
    defer curl_easy_cleanup(dup);

    curl_easy_reset(easy);
}
