// Ported from:
//   lib/vdns/httpsrr.c   (324 LOC) — HTTPS Resource Record parsing, printing, tracing, peer matching
//   lib/vdns/cf-dns.c    (691 LOC) — DNS resolution connection filter (Curl_cft_dns)
//   lib/vdns/dnscache.c  (1040 LOC) — DNS cache management and CURLOPT_RESOLVE host pairs
//   lib/vdns/asyn-ares.c (788 LOC) — c-ares asynchronous DNS resolver backend

const std = @import("std");
const builtin = @import("builtin");
const mem = @import("mem.zig");
const primitives = @import("primitives.zig");
const containers = @import("containers.zig");
const collections = @import("collections.zig");
const curlx_parse_mod = @import("curlx_parse.zig");
const curlx_time_net = @import("curlx_time_net.zig");
const vdns_cfilters = @import("vdns_cfilters.zig");

pub const Curl_str = curlx_parse_mod.Curl_str;

const curlx_parse = struct {
    pub extern fn curlx_str_assign(out: *Curl_str, str: ?[*]const u8, len: usize) callconv(.c) void;
    pub extern fn curlx_str_until(linep: *[*:0]const u8, out: *Curl_str, max: usize, delim: u8) callconv(.c) c_int;
    pub extern fn curlx_str_single(linep: *[*:0]const u8, byte: u8) callconv(.c) c_int;
    pub extern fn curlx_str_number(linep: *[*:0]const u8, nump: *i64, max: i64) callconv(.c) c_int;
    pub extern fn curlx_str_casecompare(str: *Curl_str, check: ?[*:0]const u8) callconv(.c) c_int;
    pub extern fn curlx_memdup(src: ?[*]const u8, length: usize) callconv(.c) ?*anyopaque;

    pub inline fn curlx_strlen(s: *const Curl_str) usize {
        return s.len;
    }

    pub inline fn curlx_str(s: *const Curl_str) ?[*]const u8 {
        return s.str;
    }
};

fn memdupBytes(src: ?[*]const u8, len: usize) ?[*]u8 {
    if (src == null) return null;
    const raw = curlx_parse.curlx_memdup(src, len) orelse return null;
    return @ptrCast(raw);
}

pub const CURLcode = c_uint;
pub const CURLE_OK: CURLcode = 0;
pub const CURLE_UNSUPPORTED_PROTOCOL: CURLcode = 1;
pub const CURLE_FAILED_INIT: CURLcode = 2;
pub const CURLE_URL_MALFORMAT: CURLcode = 3;
pub const CURLE_NOT_BUILT_IN: CURLcode = 4;
pub const CURLE_COULDNT_RESOLVE_PROXY: CURLcode = 5;
pub const CURLE_COULDNT_RESOLVE_HOST: CURLcode = 6;
pub const CURLE_COULDNT_CONNECT: CURLcode = 7;
pub const CURLE_OUT_OF_MEMORY: CURLcode = 27;
pub const CURLE_OPERATION_TIMEDOUT: CURLcode = 28;
pub const CURLE_BAD_FUNCTION_ARGUMENT: CURLcode = 43;
pub const CURLE_ABORTED_BY_CALLBACK: CURLcode = 42;
pub const CURLE_BAD_CONTENT_ENCODING: CURLcode = 61;
pub const CURLE_AGAIN: CURLcode = 81;
pub const CURLE_SETOPT_OPTION_SYNTAX: CURLcode = 49;
pub const CURLE_UNRECOVERABLE_POLL: CURLcode = 99;

pub const timediff_t = i64;
pub const Curltime = curlx_time_net.Curltime;

pub const Curl_easy = vdns_cfilters.Curl_easy;
pub const connectdata = vdns_cfilters.connectdata;
pub const easy_pollset = vdns_cfilters.easy_pollset;

pub const CurlPeer = vdns_cfilters.Curl_peer;
pub const Curl_addrinfo = vdns_cfilters.Curl_addrinfo;
pub const Curl_cfilter = vdns_cfilters.Curl_cfilter;
pub const Curl_cftype = vdns_cfilters.Curl_cftype;

pub const curl_slist = extern struct {
    data: ?[*:0]u8,
    next: ?*curl_slist,
};

const AF_INET: c_int = 2;
const AF_INET6: c_int = switch (builtin.os.tag) {
    .windows => 23,
    .macos, .ios, .tvos, .watchos, .visionos => 30,
    .freebsd, .netbsd, .openbsd, .dragonfly => 28,
    else => 10,
};
const PF_INET: c_int = AF_INET;
const PF_INET6: c_int = AF_INET6;

const MAX_IPADR_LEN: usize = 46;
const FIRSTSOCKET: i8 = 0;

// DNS query flags (lib/vdns/hostip.h)
pub const CURL_DNSQ_A: u8 = 1 << 0;
pub const CURL_DNSQ_AAAA: u8 = 1 << 1;
pub const CURL_DNSQ_HTTPS: u8 = 1 << 2;
pub const CURL_DNSQ_ADDR: u8 = CURL_DNSQ_A | CURL_DNSQ_AAAA;

inline fn curlDnsqIsAddr(x: u8) u8 {
    return x & CURL_DNSQ_ADDR;
}

// ALPN IDs (lib/vdns/hostip.h & lib/curl/curl.h)
pub const ALPN_none: c_uint = 0;
pub const ALPN_h1: c_uint = 1 << 3;
pub const ALPN_h2: c_uint = 1 << 4;
pub const ALPN_h3: c_uint = 1 << 5;

// Connection filter flags and controls (lib/cfilters.h)
const CF_TYPE_SETUP: c_int = 1 << 5;
const CF_TYPE_DNS: c_int = 1 << 6;
const CURL_LOG_LVL_NONE: c_int = 0;
const CF_CTRL_DATA_DONE: c_int = 7;

// Timers and expirations (lib/progress.h & lib/urldata.h)
const TIMER_STARTSINGLE: c_uint = 2;
const TIMER_NAMELOOKUP: c_uint = 4;
const EXPIRE_ASYNC_NAME: c_uint = 1;
const EXPIRE_HAPPY_EYEBALLS: c_uint = 3;
const CURL_TIMEOUT_RESOLVE_MS: timediff_t = 300 * 1000;

const TRNSPRT_TCP: u8 = 3;
const CURL_HE_AAAA_AWAIT_MS: timediff_t = 25;

// Feature flags matching curl_config.h
const use_ipv6 = true;
const use_unix_sockets = true;
const use_curl_async = true;
pub const use_ares = vdns_cfilters.use_ares;
pub const use_httpsrr = vdns_cfilters.use_httpsrr;
pub const use_resolv_ares = vdns_cfilters.use_resolv_ares;
pub const Curl_resolv_async = vdns_cfilters.Curl_resolv_async;
pub const async_ares_ctx = vdns_cfilters.async_ares_ctx;

// ============================================================================
// External C / Zig helpers
// ============================================================================

extern fn Curl_alpn2alpnid(name: [*]const u8, len: usize) callconv(.c) c_uint;
extern fn Curl_infof(data: ?*Curl_easy, fmt: [*:0]const u8, ...) callconv(.c) void;
extern fn Curl_failf(data: ?*Curl_easy, fmt: [*:0]const u8, ...) callconv(.c) void;
extern fn Curl_trc_dns(data: ?*Curl_easy, fmt: [*:0]const u8, ...) callconv(.c) void;
extern fn Curl_trc_cf_infof(data: ?*Curl_easy, cf: *const Curl_cfilter, fmt: [*:0]const u8, ...) callconv(.c) void;

inline fn Curl_trc_cf_is_verbose(cf: ?*const Curl_cfilter, data: ?*const Curl_easy) bool {
    const c = cf orelse return false;
    return Curl_vdns_trc_is_verbose(data) and c.cft.log_level >= 1;
}

extern fn curlx_dyn_addf(s: *containers.dynbuf, fmt: [*:0]const u8, ...) callconv(.c) CURLcode;

extern fn Curl_freeaddrinfo(cahead: ?*Curl_addrinfo) callconv(.c) void;
extern fn Curl_addrinfo_get(ai: ?*Curl_addrinfo, ai_family: c_int, n: c_uint) callconv(.c) ?*Curl_addrinfo;
extern fn Curl_is_ipv4addr(address: [*:0]const u8) callconv(.c) bool;
extern fn Curl_is_ipaddr(address: [*:0]const u8) callconv(.c) bool;
extern fn Curl_str2addr(dotted: [*:0]const u8, port: u16, addrp: *?*Curl_addrinfo) callconv(.c) CURLcode;
extern fn Curl_printable_address(ai: *const Curl_addrinfo, buf: [*]u8, bufsize: usize) callconv(.c) void;
extern fn Curl_host_is_ipnum(hostname: [*:0]const u8) callconv(.c) bool;
extern fn Curl_resolv_query_str(dns_queries: u8) callconv(.c) [*:0]const u8;

extern fn Curl_peer_link(pdest: *?*CurlPeer, src: ?*CurlPeer) callconv(.c) void;
extern fn Curl_peer_unlink(ppeer: *?*CurlPeer) callconv(.c) void;
extern fn Curl_peer_same_destination(p1: ?*const CurlPeer, p2: ?*const CurlPeer) callconv(.c) bool;

extern fn Curl_pgrs_now(data: ?*Curl_easy) callconv(.c) *const Curltime;
extern fn Curl_pgrs_since_ms(data: ?*Curl_easy, pnow: ?*const Curltime, timer: c_uint) callconv(.c) timediff_t;
extern fn Curl_pgrsTime(data: ?*Curl_easy, timer: c_uint) callconv(.c) void;
extern fn Curl_timeleft_ms(data: ?*Curl_easy) callconv(.c) timediff_t;
extern fn Curl_expire_set(data: ?*Curl_easy, eid: c_uint, ms: timediff_t, pnow: *const Curltime) callconv(.c) void;
extern fn Curl_multi_mark_dirty(data: ?*Curl_easy) callconv(.c) void;
extern fn Curl_rand_bytes(data: ?*Curl_easy, rnd: [*]u8, num: usize) callconv(.c) CURLcode;

extern fn Curl_resolv(
    data: ?*Curl_easy,
    peer: *CurlPeer,
    dns_queries: u8,
    transport: u8,
    for_proxy: bool,
    timeout_ms: timediff_t,
    presolv_id: *u32,
    pdns: *?*Curl_dns_entry,
) callconv(.c) CURLcode;
extern fn Curl_resolv_take_result(
    data: ?*Curl_easy,
    resolv_id: u32,
    pdns: *?*Curl_dns_entry,
) callconv(.c) CURLcode;
extern fn Curl_resolv_destroy(data: ?*Curl_easy, resolv_id: u32) callconv(.c) void;
extern fn Curl_resolv_elapsed_ms(
    data: ?*Curl_easy,
    resolv_id: u32,
    pnow: *const Curltime,
) callconv(.c) timediff_t;
extern fn Curl_resolv_has_answers(
    data: ?*Curl_easy,
    resolv_id: u32,
    dns_queries: u8,
) callconv(.c) bool;
extern fn Curl_resolv_get_ai(
    data: ?*Curl_easy,
    resolv_id: u32,
    ai_family: c_int,
    index: c_uint,
) callconv(.c) ?*const Curl_addrinfo;
extern fn Curl_resolv_pollset(data: ?*Curl_easy, ps: *easy_pollset) callconv(.c) CURLcode;

extern fn Curl_cf_create(
    pcf: *?*Curl_cfilter,
    cft: *const Curl_cftype,
    ctx: ?*anyopaque,
) callconv(.c) CURLcode;
extern fn Curl_conn_cf_add(
    data: ?*Curl_easy,
    conn: ?*connectdata,
    index: i8,
    cf: *Curl_cfilter,
) callconv(.c) void;
extern fn Curl_conn_cf_insert_after(cf_at: *Curl_cfilter, cf_new: ?*Curl_cfilter) callconv(.c) void;
extern fn Curl_conn_cf_connect(cf: ?*Curl_cfilter, data: ?*Curl_easy, done: *bool) callconv(.c) CURLcode;

extern fn Curl_cf_def_shutdown(cf: *Curl_cfilter, data: ?*Curl_easy, done: *bool) callconv(.c) CURLcode;
extern fn Curl_cf_def_data_pending(cf: *Curl_cfilter, data: ?*const Curl_easy) callconv(.c) bool;
extern fn Curl_cf_def_send(
    cf: *Curl_cfilter,
    data: ?*Curl_easy,
    buf: [*]const u8,
    len: usize,
    eos: bool,
    pnwritten: *usize,
) callconv(.c) CURLcode;
extern fn Curl_cf_def_recv(
    cf: *Curl_cfilter,
    data: ?*Curl_easy,
    buf: [*]u8,
    len: usize,
    pnread: *usize,
) callconv(.c) CURLcode;
extern fn Curl_cf_def_conn_is_alive(
    cf: *Curl_cfilter,
    data: ?*Curl_easy,
    input_pending: *bool,
) callconv(.c) bool;
extern fn Curl_cf_def_conn_keep_alive(cf: *Curl_cfilter, data: ?*Curl_easy) callconv(.c) CURLcode;
extern fn Curl_cf_def_query(
    cf: *Curl_cfilter,
    data: ?*Curl_easy,
    query: c_int,
    pres1: ?*c_int,
    pres2: ?*anyopaque,
) callconv(.c) CURLcode;

// Hash table functions (exported by zig/port/collections.zig)
extern fn Curl_hash_init(
    h: *collections.Curl_hash,
    slots: usize,
    hash_type: collections.Curl_hash_type,
    dtor: ?collections.Curl_hash_dtor,
) callconv(.c) void;
extern fn Curl_hash_destroy(h: *collections.Curl_hash) callconv(.c) void;
extern fn Curl_hash_clean(h: ?*collections.Curl_hash) callconv(.c) void;
extern fn Curl_hash_clean_with_criterium(
    h: ?*collections.Curl_hash,
    user: ?*anyopaque,
    comp: ?collections.Curl_hash_criterium_fn,
) callconv(.c) void;
extern fn Curl_hash_count(h: *collections.Curl_hash) callconv(.c) usize;
extern fn Curl_hash_pick(
    h: *collections.Curl_hash,
    key: ?*const anyopaque,
    key_len: usize,
) callconv(.c) ?*anyopaque;
extern fn Curl_hash_add(
    h: *collections.Curl_hash,
    key: ?*const anyopaque,
    key_len: usize,
    p: ?*anyopaque,
) callconv(.c) ?*anyopaque;
extern fn Curl_hash_delete(
    h: *collections.Curl_hash,
    key: ?*const anyopaque,
    key_len: usize,
) callconv(.c) c_int;

// Thin C accessors in lib/vdns/hostip.c
extern fn Curl_vdns_data_conn_origin(data: ?*const Curl_easy) callconv(.c) ?*CurlPeer;
extern fn Curl_vdns_trc_is_verbose(data: ?*const Curl_easy) callconv(.c) bool;
extern fn Curl_vdns_trc_dns_is_verbose(data: ?*const Curl_easy) callconv(.c) bool;
extern fn Curl_vdns_data_conn(data: ?*const Curl_easy) callconv(.c) ?*connectdata;
extern fn Curl_vdns_conn_cfilter(conn: ?*const connectdata, sockindex: i8) callconv(.c) ?*Curl_cfilter;
extern fn Curl_vdns_conn_transport_wanted(conn: ?*const connectdata) callconv(.c) u8;
extern fn Curl_vdns_conn_set_dns_resolved(conn: ?*connectdata) callconv(.c) void;
extern fn Curl_vdns_conn_is_proxy_peer(conn: ?*const connectdata, peer: ?*const CurlPeer) callconv(.c) bool;
extern fn Curl_vdns_dnscache_get(data: ?*const Curl_easy) callconv(.c) ?*Curl_dnscache;
extern fn Curl_vdns_dnscache_lock(data: ?*Curl_easy, dnscache: ?*Curl_dnscache) callconv(.c) void;
extern fn Curl_vdns_dnscache_unlock(data: ?*Curl_easy, dnscache: ?*Curl_dnscache) callconv(.c) void;
extern fn Curl_vdns_data_dns_cache_timeout_ms(data: ?*const Curl_easy) callconv(.c) timediff_t;
extern fn Curl_vdns_data_get_wildcard_resolve(data: ?*const Curl_easy) callconv(.c) bool;
extern fn Curl_vdns_data_set_wildcard_resolve(data: ?*Curl_easy, val: bool) callconv(.c) void;
extern fn Curl_vdns_data_dns_shuffle_addresses(data: ?*const Curl_easy) callconv(.c) bool;
extern fn Curl_vdns_data_get_resolve(data: ?*const Curl_easy) callconv(.c) ?*curl_slist;
extern fn Curl_vdns_data_clear_resolve(data: ?*Curl_easy) callconv(.c) void;

// ============================================================================
// 1. lib/vdns/httpsrr.c — HTTPS Resource Record (RFC 9460)
// ============================================================================

pub const CURL_MAXLEN_HOST_NAME: usize = 253;
pub const MAX_HTTPSRR_ALPNS = vdns_cfilters.MAX_HTTPSRR_ALPNS;

pub const HTTPS_RR_CODE_MANDATORY: u16 = 0x00;
pub const HTTPS_RR_CODE_ALPN: u16 = 0x01;
pub const HTTPS_RR_CODE_NO_DEF_ALPN: u16 = 0x02;
pub const HTTPS_RR_CODE_PORT: u16 = 0x03;
pub const HTTPS_RR_CODE_IPV4: u16 = 0x04;
pub const HTTPS_RR_CODE_ECH: u16 = 0x05;
pub const HTTPS_RR_CODE_IPV6: u16 = 0x06;

pub const Curl_https_rrinfo = vdns_cfilters.Curl_https_rrinfo;

fn httpsrr_decode_alpn(
    cp_opt: ?[*]const u8,
    len_in: usize,
    alpns: *[MAX_HTTPSRR_ALPNS]u8,
) CURLcode {
    var idnum: usize = 0;
    var len = len_in;
    var cp = cp_opt orelse {
        if (len > 0) return CURLE_BAD_CONTENT_ENCODING;
        alpns[0] = @intCast(ALPN_none);
        return CURLE_OK;
    };

    while (len > 0) {
        const tlen: usize = cp[0];
        cp += 1;
        len -= 1;
        if (tlen > len) {
            return CURLE_BAD_CONTENT_ENCODING;
        }

        const id = Curl_alpn2alpnid(cp, tlen);
        if (id != ALPN_none) {
            if (idnum == MAX_HTTPSRR_ALPNS) {
                break;
            }
            const id_u8: u8 = @intCast(id);
            if (idnum > 0 and std.mem.indexOfScalar(u8, alpns[0..idnum], id_u8) != null) {
                // this ALPN id is already stored
            } else {
                alpns[idnum] = id_u8;
                idnum += 1;
            }
        }
        cp += tlen;
        len -= tlen;
    }
    if (idnum < MAX_HTTPSRR_ALPNS) {
        alpns[idnum] = @intCast(ALPN_none);
    }
    return CURLE_OK;
}

fn httpsrr_print_addr(
    dyn: *containers.dynbuf,
    ai_family: c_int,
    addr: [*]const u8,
    total_len: usize,
) CURLcode {
    var buf: [MAX_IPADR_LEN]u8 = undefined;
    const alen: usize = if (ai_family == AF_INET6) 16 else 4;
    var sep: [*:0]const u8 = "";
    var result: CURLcode = CURLE_OK;
    var i: usize = 0;

    while (i < (total_len / alen) and result == CURLE_OK) : (i += 1) {
        if (curlx_time_net.curlx_inet_ntop(ai_family, addr + (i * alen), &buf, buf.len) != CURLE_OK) {
            result = containers.curlx_dyn_add(dyn, "<error parsing address>");
        } else {
            result = curlx_dyn_addf(dyn, "%s%s", sep, @as([*:0]const u8, @ptrCast(&buf)));
        }
        sep = ",";
    }
    return result;
}

pub export fn Curl_httpsrr_trace(
    data: ?*Curl_easy,
    rr_opt: ?*Curl_https_rrinfo,
) callconv(.c) void {
    const rr = rr_opt orelse {
        if (Curl_vdns_trc_dns_is_verbose(data)) {
            Curl_trc_dns(data, "[HTTPS] no record available");
        }
        return;
    };

    var tmp: containers.dynbuf = undefined;
    containers.curlx_dyn_init(&tmp, 1024);
    const result = Curl_httpsrr_print(&tmp, rr);
    if (result == CURLE_OK) {
        if (Curl_vdns_trc_dns_is_verbose(data)) {
            Curl_trc_dns(data, "[HTTPS] record: %s", containers.curlx_dyn_ptr(&tmp));
        }
    } else {
        if (Curl_vdns_trc_dns_is_verbose(data)) {
            Curl_trc_dns(data, "[HTTPS] error printing information");
        }
    }
    containers.curlx_dyn_free(&tmp);
}

pub export fn Curl_httpsrr_print(
    tmp: *containers.dynbuf,
    rr: *Curl_https_rrinfo,
) callconv(.c) CURLcode {
    containers.curlx_dyn_reset(tmp);
    const target_str: [*:0]const u8 = if (rr.target) |t| t else ".";
    var result = curlx_dyn_addf(tmp, "%u %s", @as(c_uint, rr.priority), target_str);
    if (result == CURLE_OK and rr.mandatory()) {
        result = containers.curlx_dyn_add(tmp, " mandatory-keys(ignored)");
    }
    if (result == CURLE_OK and rr.alpns[0] != 0) {
        var sep: [*:0]const u8 = "";
        result = containers.curlx_dyn_add(tmp, " alpn=");
        var i: usize = 0;
        while (result == CURLE_OK and i < 4) : (i += 1) {
            const name: ?[*:0]const u8 = switch (rr.alpns[i]) {
                ALPN_h1 => "http/1.1",
                ALPN_h2 => "h2",
                ALPN_h3 => "h3",
                else => null,
            };
            if (name) |n| {
                result = curlx_dyn_addf(tmp, "%s%s", sep, n);
                sep = ",";
            }
        }
    }
    if (result == CURLE_OK and rr.portSet()) {
        result = curlx_dyn_addf(tmp, " port=%u", @as(c_uint, rr.port));
    }
    if (result == CURLE_OK and rr.noDefAlpn()) {
        result = containers.curlx_dyn_add(tmp, " no-default-alpn");
    }
    if (result == CURLE_OK and rr.ipv6hints_len != 0) {
        result = containers.curlx_dyn_add(tmp, " ipv6hint=");
        if (result == CURLE_OK) {
            result = httpsrr_print_addr(tmp, AF_INET6, rr.ipv6hints.?, rr.ipv6hints_len);
        }
    }
    if (result == CURLE_OK and rr.ipv4hints_len != 0) {
        result = containers.curlx_dyn_add(tmp, " ipv4hint=");
        if (result == CURLE_OK) {
            result = httpsrr_print_addr(tmp, AF_INET, rr.ipv4hints.?, rr.ipv4hints_len);
        }
    }
    if (result == CURLE_OK and rr.echconfiglist_len != 0) {
        result = curlx_dyn_addf(tmp, " ech=<%zu bytes>", rr.echconfiglist_len);
    }
    return result;
}

pub export fn Curl_httpsrr_set(
    rr: *Curl_https_rrinfo,
    rrkey: u16,
    val: ?[*]const u8,
    vlen: usize,
) callconv(.c) CURLcode {
    var result: CURLcode = CURLE_OK;
    switch (rrkey) {
        HTTPS_RR_CODE_MANDATORY => {
            rr.setMandatory(true);
        },
        HTTPS_RR_CODE_ALPN => {
            result = httpsrr_decode_alpn(val, vlen, &rr.alpns);
        },
        HTTPS_RR_CODE_NO_DEF_ALPN => {
            if (vlen != 0) return CURLE_BAD_FUNCTION_ARGUMENT;
            rr.setNoDefAlpn(true);
        },
        HTTPS_RR_CODE_IPV4 => {
            if (vlen == 0 or (vlen & 3) != 0) return CURLE_BAD_FUNCTION_ARGUMENT;
            mem.free(@ptrCast(rr.ipv4hints));
            rr.ipv4hints = null;
            rr.ipv4hints_len = 0;
            const dup = memdupBytes(val, vlen) orelse return CURLE_OUT_OF_MEMORY;
            rr.ipv4hints = @ptrCast(dup);
            rr.ipv4hints_len = vlen;
        },
        HTTPS_RR_CODE_ECH => {
            if (vlen == 0) return CURLE_BAD_FUNCTION_ARGUMENT;
            if (rr.echconfiglist) |ech| {
                mem.secureZero(@ptrCast(ech), rr.echconfiglist_len);
                mem.free(@ptrCast(ech));
            }
            rr.echconfiglist = null;
            rr.echconfiglist_len = 0;
            const dup = memdupBytes(val, vlen) orelse return CURLE_OUT_OF_MEMORY;
            rr.echconfiglist = @ptrCast(dup);
            rr.echconfiglist_len = vlen;
        },
        HTTPS_RR_CODE_IPV6 => {
            if (vlen == 0 or (vlen & 15) != 0) return CURLE_BAD_FUNCTION_ARGUMENT;
            mem.free(@ptrCast(rr.ipv6hints));
            rr.ipv6hints = null;
            rr.ipv6hints_len = 0;
            const dup = memdupBytes(val, vlen) orelse return CURLE_OUT_OF_MEMORY;
            rr.ipv6hints = @ptrCast(dup);
            rr.ipv6hints_len = vlen;
        },
        HTTPS_RR_CODE_PORT => {
            if (vlen != 2) return CURLE_BAD_FUNCTION_ARGUMENT;
            const v = val orelse return CURLE_BAD_FUNCTION_ARGUMENT;
            rr.port = (@as(u16, v[0]) << 8) | @as(u16, v[1]);
            rr.setPortSet(true);
        },
        else => {},
    }
    return result;
}

pub export fn Curl_httpsrr_destroy(rrinfo_opt: ?*Curl_https_rrinfo) callconv(.c) void {
    if (rrinfo_opt) |rrinfo| {
        mem.free(@ptrCast(rrinfo.target));
        if (rrinfo.echconfiglist) |ech| {
            mem.secureZero(@ptrCast(ech), rrinfo.echconfiglist_len);
            mem.free(@ptrCast(ech));
        }
        mem.free(@ptrCast(rrinfo.ipv4hints));
        mem.free(@ptrCast(rrinfo.ipv6hints));
        mem.freeSized(@ptrCast(rrinfo), @sizeOf(Curl_https_rrinfo));
    }
}

pub export fn Curl_httpsrr_applicable(
    data: ?*Curl_easy,
    rr: ?*const Curl_https_rrinfo,
) callconv(.c) bool {
    const origin = Curl_vdns_data_conn_origin(data) orelse return false;
    return Curl_httpsrr_is_for_peer(origin, rr);
}

pub export fn Curl_httpsrr_is_for_peer(
    peer_opt: ?*CurlPeer,
    rr_opt: ?*const Curl_https_rrinfo,
) callconv(.c) bool {
    const peer = peer_opt orelse return false;
    const rr = rr_opt orelse return false;
    const target_ok = if (rr.target) |t|
        (t[0] == 0 or (t[0] == '.' and t[1] == 0))
    else
        true;
    return target_ok and (!rr.portSet() or rr.port == peer.port);
}

const ARES_SECTION_ANSWER: c_uint = 1;
const ARES_CLASS_IN: c_uint = 1;
const ARES_REC_TYPE_HTTPS: c_uint = 65;
const ARES_RR_HTTPS_PRIORITY: c_uint = 6501;
const ARES_RR_HTTPS_TARGET: c_uint = 6502;
const ARES_RR_HTTPS_PARAMS: c_uint = 6503;

const ares_dns_c = struct {
    extern fn ares_dns_record_rr_cnt(dnsrec: ?*const anyopaque, sect: c_uint) callconv(.c) usize;
    extern fn ares_dns_record_rr_get(dnsrec: ?*anyopaque, sect: c_uint, idx: usize) callconv(.c) ?*const anyopaque;
    extern fn ares_dns_rr_get_type(dns_rr: ?*const anyopaque) callconv(.c) c_uint;
    extern fn ares_dns_rr_get_str(dns_rr: ?*const anyopaque, key: c_uint) callconv(.c) ?[*:0]const u8;
    extern fn ares_dns_rr_get_u16(dns_rr: ?*const anyopaque, key: c_uint) callconv(.c) u16;
    extern fn ares_dns_rr_get_opt_cnt(dns_rr: ?*const anyopaque, key: c_uint) callconv(.c) usize;
    extern fn ares_dns_rr_get_opt(
        dns_rr: ?*const anyopaque,
        key: c_uint,
        idx: usize,
        val: *?[*]const u8,
        val_len: *usize,
    ) callconv(.c) u16;
};

fn httpsrr_opt(
    rr: ?*const anyopaque,
    key: c_uint,
    idx: usize,
    hinfo: *Curl_https_rrinfo,
) CURLcode {
    var val: ?[*]const u8 = null;
    var len: usize = 0;
    const code = ares_dns_c.ares_dns_rr_get_opt(rr, key, idx, &val, &len);
    return Curl_httpsrr_set(hinfo, code, val, len);
}

pub fn Curl_httpsrr_from_ares(
    dnsrec: ?*const anyopaque,
    phinfo: *?*Curl_https_rrinfo,
) callconv(.c) CURLcode {
    const raw = mem.calloc(1, @sizeOf(Curl_https_rrinfo)) orelse {
        phinfo.* = null;
        return CURLE_OUT_OF_MEMORY;
    };
    const hinfo: *Curl_https_rrinfo = @ptrCast(@alignCast(raw));
    var result: CURLcode = CURLE_OUT_OF_MEMORY;

    const rr_cnt = ares_dns_c.ares_dns_record_rr_cnt(dnsrec, ARES_SECTION_ANSWER);
    for (0..rr_cnt) |i| {
        const rr = ares_dns_c.ares_dns_record_rr_get(@constCast(dnsrec), ARES_SECTION_ANSWER, i);
        if (ares_dns_c.ares_dns_rr_get_type(rr) != ARES_REC_TYPE_HTTPS)
            continue;
        if (ares_dns_c.ares_dns_rr_get_str(rr, ARES_RR_HTTPS_TARGET)) |target| {
            if (target[0] != 0) {
                mem.free(@ptrCast(hinfo.target));
                hinfo.target = mem.strdup(target);
                if (hinfo.target == null) {
                    phinfo.* = null;
                    Curl_httpsrr_destroy(hinfo);
                    return CURLE_OUT_OF_MEMORY;
                }
            }
        }
        hinfo.priority = ares_dns_c.ares_dns_rr_get_u16(rr, ARES_RR_HTTPS_PRIORITY);
        const opt_cnt = ares_dns_c.ares_dns_rr_get_opt_cnt(rr, ARES_RR_HTTPS_PARAMS);
        for (0..opt_cnt) |opt| {
            result = httpsrr_opt(rr, ARES_RR_HTTPS_PARAMS, opt, hinfo);
            if (result != CURLE_OK) {
                phinfo.* = null;
                Curl_httpsrr_destroy(hinfo);
                return result;
            }
        }
    }
    phinfo.* = hinfo;
    return CURLE_OK;
}

comptime {
    if (use_ares and use_httpsrr) {
        @export(&Curl_httpsrr_from_ares, .{ .name = "Curl_httpsrr_from_ares" });
    }
}

// ============================================================================
// 2. lib/vdns/dnscache.c — DNS Cache Management & CURLOPT_RESOLVE
// ============================================================================

pub const CURL_DNST_INIT: u8 = 0;
pub const CURL_DNST_ADDR: u8 = 'A';
pub const CURL_DNST_HTTPS: u8 = 'H';

pub const MAX_HOSTCACHE_LEN: usize = 255 + 3;
const MAX_DNS_CACHE_SIZE: usize = 29999;

pub const dnsc_id = extern struct {
    name: Curl_str,
    port: u16,
    type: u8,
};

pub const dnsc_key = extern struct {
    data: [MAX_HOSTCACHE_LEN]u8,
    len: usize,
};

pub const Curl_dns_entry = if (builtin.os.tag == .windows)
    (if (use_httpsrr) extern struct {
        addr: ?*Curl_addrinfo,
        hinfo: ?*Curl_https_rrinfo,
        added: Curltime,
        refcount: u32,
        hostlen: u16,
        port: u16,
        type: u8,
        dns_queries: u8,
        dns_responses: u8,
        _pad0: u8 = 0,
        flags: u32,
        hostname: [1]u8,

        pub inline fn permanent(self: *const Curl_dns_entry) bool {
            return (self.flags & 1) != 0;
        }

        pub inline fn setPermanent(self: *Curl_dns_entry, val: bool) void {
            if (val) self.flags |= 1 else self.flags &= ~@as(u32, 1);
        }

        pub inline fn getHinfo(self: *const Curl_dns_entry) ?*Curl_https_rrinfo {
            return self.hinfo;
        }

        pub inline fn setHinfo(self: *Curl_dns_entry, val: ?*Curl_https_rrinfo) void {
            self.hinfo = val;
        }

        pub inline fn hostnamePtr(self: anytype) [*:0]u8 {
            return @ptrCast(@constCast(&self.hostname));
        }
    } else extern struct {
        addr: ?*Curl_addrinfo,
        added: Curltime,
        refcount: u32,
        hostlen: u16,
        port: u16,
        type: u8,
        dns_queries: u8,
        dns_responses: u8,
        _pad0: u8 = 0,
        flags: u32,
        hostname: [1]u8,

        pub inline fn permanent(self: *const Curl_dns_entry) bool {
            return (self.flags & 1) != 0;
        }

        pub inline fn setPermanent(self: *Curl_dns_entry, val: bool) void {
            if (val) self.flags |= 1 else self.flags &= ~@as(u32, 1);
        }

        pub inline fn getHinfo(_: *const Curl_dns_entry) ?*Curl_https_rrinfo {
            return null;
        }

        pub inline fn setHinfo(_: *Curl_dns_entry, _: ?*Curl_https_rrinfo) void {}

        pub inline fn hostnamePtr(self: anytype) [*:0]u8 {
            return @ptrCast(@constCast(&self.hostname));
        }
    })
else if (use_httpsrr) extern struct {
    addr: ?*Curl_addrinfo,
    hinfo: ?*Curl_https_rrinfo,
    added: Curltime,
    refcount: u32,
    hostlen: u16,
    port: u16,
    type: u8,
    dns_queries: u8,
    dns_responses: u8,
    flags: u8,
    hostname: [1]u8,

    pub inline fn permanent(self: *const Curl_dns_entry) bool {
        return (self.flags & 1) != 0;
    }

    pub inline fn setPermanent(self: *Curl_dns_entry, val: bool) void {
        if (val) self.flags |= 1 else self.flags &= ~@as(u8, 1);
    }

    pub inline fn getHinfo(self: *const Curl_dns_entry) ?*Curl_https_rrinfo {
        return self.hinfo;
    }

    pub inline fn setHinfo(self: *Curl_dns_entry, val: ?*Curl_https_rrinfo) void {
        self.hinfo = val;
    }

    pub inline fn hostnamePtr(self: anytype) [*:0]u8 {
        return @ptrCast(@constCast(&self.hostname));
    }
} else extern struct {
    addr: ?*Curl_addrinfo,
    added: Curltime,
    refcount: u32,
    hostlen: u16,
    port: u16,
    type: u8,
    dns_queries: u8,
    dns_responses: u8,
    flags: u8,
    hostname: [1]u8,

    pub inline fn permanent(self: *const Curl_dns_entry) bool {
        return (self.flags & 1) != 0;
    }

    pub inline fn setPermanent(self: *Curl_dns_entry, val: bool) void {
        if (val) self.flags |= 1 else self.flags &= ~@as(u8, 1);
    }

    pub inline fn getHinfo(_: *const Curl_dns_entry) ?*Curl_https_rrinfo {
        return null;
    }

    pub inline fn setHinfo(_: *Curl_dns_entry, _: ?*Curl_https_rrinfo) void {}

    pub inline fn hostnamePtr(self: anytype) [*:0]u8 {
        return @ptrCast(@constCast(&self.hostname));
    }
};

pub const Curl_dnscache = extern struct {
    entries: collections.Curl_hash,
};

pub export fn dnsc_peer2id(pid: *dnsc_id, dtype: u8, peer: *CurlPeer) callconv(.c) void {
    const hname: [*:0]const u8 = peer.hostname orelse "";
    curlx_parse.curlx_str_assign(&pid.name, hname, std.mem.len(hname));
    pid.port = peer.port;
    pid.type = dtype;
}

fn dnsc_str2id(pid: *dnsc_id, dtype: u8, name: *const Curl_str, port: u16) void {
    pid.name = name.*;
    pid.port = port;
    pid.type = dtype;
}

pub export fn dnsc_id2key(key: *dnsc_key, id: *dnsc_id) callconv(.c) void {
    var namelen = curlx_parse.curlx_strlen(&id.name);
    if (namelen > (MAX_HOSTCACHE_LEN - 3)) {
        namelen = MAX_HOSTCACHE_LEN - 3;
    }
    key.data[0] = id.type;
    key.data[1] = @intCast((id.port >> 8) & 0xff);
    key.data[2] = @intCast(id.port & 0xff);
    if (namelen > 0) {
        if (curlx_parse.curlx_str(&id.name)) |s| {
            primitives.Curl_strntolower(@ptrCast(key.data[3..].ptr), s, namelen);
        }
    }
    key.len = namelen + 3;
}

pub export fn dnsc_id_matches_entry(
    id: *dnsc_id,
    dns_opt: ?*Curl_dns_entry,
) callconv(.c) bool {
    const dns = dns_opt orelse return false;
    if (dns.hostlen <= (MAX_HOSTCACHE_LEN - 3) and id.name.len <= (MAX_HOSTCACHE_LEN - 3)) {
        return true;
    }
    if (id.port != dns.port or id.name.len != dns.hostlen) {
        return false;
    }
    const id_str = id.name.str orelse return false;
    const dns_host = dns.hostnamePtr();
    const hlen: usize = dns.hostlen;
    if (std.mem.eql(u8, id_str[0..hlen], dns_host[0..hlen])) {
        return true;
    }
    return std.ascii.eqlIgnoreCase(id_str[0..hlen], dns_host[0..hlen]);
}

fn dnscache_entry_free(dns: *Curl_dns_entry) void {
    Curl_freeaddrinfo(dns.addr);
    if (dns.getHinfo()) |hinfo| {
        Curl_httpsrr_destroy(hinfo);
    }
    mem.free(@ptrCast(dns));
}

const DnscachePruneData = extern struct {
    pnow: *const Curltime,
    oldest_ms: timediff_t,
    max_age_ms: timediff_t,
};

fn dnscache_entry_is_stale(datap: ?*anyopaque, hc: ?*anyopaque) callconv(.c) c_int {
    const prune: *DnscachePruneData = @ptrCast(@alignCast(datap orelse return 0));
    const dns: *Curl_dns_entry = @ptrCast(@alignCast(hc orelse return 0));

    if (!dns.permanent()) {
        var age_ms = curlx_time_net.curlx_ptimediff_ms(prune.pnow, &dns.added);
        switch (dns.type) {
            CURL_DNST_ADDR => {
                if (dns.addr == null) {
                    age_ms *= 2;
                }
            },
            CURL_DNST_HTTPS => {
                if (dns.getHinfo() == null) {
                    age_ms *= 2;
                }
            },
            else => {},
        }
        if (age_ms >= prune.max_age_ms) {
            return 1;
        }
        if (age_ms > prune.oldest_ms) {
            prune.oldest_ms = age_ms;
        }
    }
    return 0;
}

fn dnscache_prune(
    hostcache: *collections.Curl_hash,
    cache_timeout_ms: timediff_t,
    pnow: *const Curltime,
) timediff_t {
    var user: DnscachePruneData = .{
        .pnow = pnow,
        .oldest_ms = 0,
        .max_age_ms = cache_timeout_ms,
    };
    Curl_hash_clean_with_criterium(hostcache, @ptrCast(&user), dnscache_entry_is_stale);
    return user.oldest_ms;
}

pub export fn Curl_dnscache_prune(
    data: ?*Curl_easy,
    pnow_opt: ?*const Curltime,
) callconv(.c) void {
    const dnscache = Curl_vdns_dnscache_get(data) orelse return;
    var timeout_ms = Curl_vdns_data_dns_cache_timeout_ms(data);
    if (timeout_ms == -1) return;
    const pnow = pnow_opt orelse Curl_pgrs_now(data);

    Curl_vdns_dnscache_lock(data, dnscache);
    while (true) {
        const oldest_ms = dnscache_prune(&dnscache.entries, timeout_ms, pnow);
        if (Curl_hash_count(&dnscache.entries) > MAX_DNS_CACHE_SIZE) {
            timeout_ms = @divTrunc(oldest_ms, 2);
        } else {
            break;
        }
        if (timeout_ms == 0) break;
    }
    Curl_vdns_dnscache_unlock(data, dnscache);
}

pub export fn Curl_dnscache_clear(data: ?*Curl_easy) callconv(.c) void {
    const dnscache = Curl_vdns_dnscache_get(data) orelse return;
    Curl_vdns_dnscache_lock(data, dnscache);
    Curl_hash_clean(&dnscache.entries);
    Curl_vdns_dnscache_unlock(data, dnscache);
}

fn fetch_entry(
    data: ?*Curl_easy,
    dnscache_opt: ?*Curl_dnscache,
    dns_queries: u8,
    peer: *CurlPeer,
    pdns: *?*Curl_dns_entry,
) CURLcode {
    var dns: ?*Curl_dns_entry = null;
    var id: dnsc_id = undefined;
    var key: dnsc_key = undefined;
    const dtype: u8 = if (curlDnsqIsAddr(dns_queries) != 0) CURL_DNST_ADDR else CURL_DNST_HTTPS;
    var result: CURLcode = CURLE_OK;

    pdns.* = null;
    const dnscache = dnscache_opt orelse return CURLE_OK;

    dnsc_peer2id(&id, dtype, peer);
    dnsc_id2key(&key, &id);

    dns = @ptrCast(@alignCast(Curl_hash_pick(&dnscache.entries, &key.data, key.len)));

    if (dns != null and !dnsc_id_matches_entry(&id, dns)) {
        dns = null;
    }

    if (dns == null and dtype == CURL_DNST_ADDR and Curl_vdns_data_get_wildcard_resolve(data)) {
        var wildname: Curl_str = .{ .str = null, .len = 0 };
        curlx_parse.curlx_str_assign(&wildname, "*", 1);
        dnsc_str2id(&id, CURL_DNST_ADDR, &wildname, peer.port);
        dnsc_id2key(&key, &id);
        dns = @ptrCast(@alignCast(Curl_hash_pick(&dnscache.entries, &key.data, key.len)));
    }

    const timeout_ms = Curl_vdns_data_dns_cache_timeout_ms(data);
    if (dns != null and timeout_ms != -1) {
        var user: DnscachePruneData = .{
            .pnow = Curl_pgrs_now(data),
            .oldest_ms = 0,
            .max_age_ms = timeout_ms,
        };
        if (dnscache_entry_is_stale(@ptrCast(&user), @ptrCast(dns)) != 0) {
            Curl_infof(data, "Hostname in DNS cache was stale, zapped");
            dns = null;
            _ = Curl_hash_delete(&dnscache.entries, &key.data, key.len);
        }
    }

    if (dns != null and curlDnsqIsAddr(dns_queries) != 0) {
        const d = dns.?;
        if ((d.dns_queries & dns_queries) != (dns_queries & CURL_DNSQ_ADDR)) {
            dns = null;
        } else if ((d.dns_responses & dns_queries) == 0) {
            if (Curl_vdns_trc_dns_is_verbose(data)) {
                Curl_trc_dns(
                    data,
                    "cache entry does not have type=%s addresses",
                    Curl_resolv_query_str(dns_queries),
                );
            }
            dns = null;
            result = CURLE_COULDNT_RESOLVE_HOST;
        } else if (d.addr == null) {
            dns = null;
            result = CURLE_COULDNT_RESOLVE_HOST;
        }
    }

    pdns.* = dns;
    return result;
}

pub export fn Curl_dnscache_get(
    data: ?*Curl_easy,
    dns_queries: u8,
    peer: *CurlPeer,
    pentry: *?*Curl_dns_entry,
) callconv(.c) CURLcode {
    const dnscache = Curl_vdns_dnscache_get(data);
    var dns: ?*Curl_dns_entry = null;

    Curl_vdns_dnscache_lock(data, dnscache);
    const result = fetch_entry(data, dnscache, dns_queries, peer, &dns);
    if (result == CURLE_OK and dns != null) {
        dns.?.refcount += 1;
    } else if (result != CURLE_OK) {
        dns = null;
    }
    Curl_vdns_dnscache_unlock(data, dnscache);

    if (Curl_vdns_trc_dns_is_verbose(data)) {
        const found_prefix: [*:0]const u8 = if (dns != null) "" else "not ";
        Curl_trc_dns(
            data,
            "cache lookup %s:%u queries=%s -> %d %sfound",
            peer.hostname,
            @as(c_uint, peer.port),
            Curl_resolv_query_str(dns_queries),
            @as(c_int, @intCast(result)),
            found_prefix,
        );
    }
    pentry.* = dns;
    return result;
}

fn num_addresses(addr_in: ?*const Curl_addrinfo) usize {
    var count: usize = 0;
    var cur = addr_in;
    while (cur) |a| : (cur = a.ai_next) {
        count += 1;
    }
    return count;
}

pub export fn dns_shuffle_addr(
    data: ?*Curl_easy,
    addr: *?*Curl_addrinfo,
) callconv(.c) CURLcode {
    var result: CURLcode = CURLE_OK;
    const num_addrs = num_addresses(addr.*);

    if (num_addrs > 1) {
        if (Curl_vdns_trc_dns_is_verbose(data)) {
            Curl_trc_dns(data, "Shuffling %d addresses", @as(c_int, @intCast(num_addrs)));
        }

        const nodes_raw = mem.malloc(num_addrs * @sizeOf(*Curl_addrinfo)) orelse return CURLE_OUT_OF_MEMORY;
        defer mem.free(nodes_raw);
        const nodes: [*]*Curl_addrinfo = @ptrCast(@alignCast(nodes_raw));

        nodes[0] = addr.*.?;
        for (1..num_addrs) |i| {
            nodes[i] = nodes[i - 1].ai_next.?;
        }

        const rnd_size = num_addrs * @sizeOf(c_uint);
        const rnd_raw = mem.malloc(rnd_size) orelse return CURLE_OUT_OF_MEMORY;
        defer mem.free(rnd_raw);
        const rnd: [*]c_uint = @ptrCast(@alignCast(rnd_raw));

        if (Curl_rand_bytes(data, rnd_raw, rnd_size) == CURLE_OK) {
            var i: usize = num_addrs - 1;
            while (i > 0) : (i -= 1) {
                const j: usize = @intCast(rnd[i] % @as(c_uint, @intCast(i + 1)));
                const swap_tmp = nodes[j];
                nodes[j] = nodes[i];
                nodes[i] = swap_tmp;
            }

            for (1..num_addrs) |k| {
                nodes[k - 1].ai_next = nodes[k];
            }
            nodes[num_addrs - 1].ai_next = null;
            addr.* = nodes[0];
        } else {
            result = CURLE_OUT_OF_MEMORY;
        }
    }
    return result;
}

fn dnscache_ai_has_family(ai_in: ?*const Curl_addrinfo, ai_family: c_int) bool {
    var ai = ai_in;
    while (ai) |a| : (ai = a.ai_next) {
        if (a.ai_family == ai_family) return true;
    }
    return false;
}

fn dnsc_entry_create(pid: *const dnsc_id, permanent: bool) ?*Curl_dns_entry {
    const namelen = curlx_parse.curlx_strlen(&pid.name);
    if (namelen > std.math.maxInt(u16)) return null;

    const raw = mem.calloc(1, @sizeOf(Curl_dns_entry) + namelen) orelse return null;
    const dns: *Curl_dns_entry = @ptrCast(@alignCast(raw));

    dns.refcount = 1;
    dns.port = pid.port;
    dns.hostlen = @intCast(namelen);
    if (namelen > 0) {
        if (curlx_parse.curlx_str(&pid.name)) |s| {
            @memcpy(dns.hostnamePtr()[0..namelen], s[0..namelen]);
        }
    }
    dns.hostnamePtr()[namelen] = 0;
    dns.setPermanent(permanent);
    return dns;
}

fn dnsc_entry_assign_addr(
    data: ?*Curl_easy,
    dns_in: ?*Curl_dns_entry,
    dns_queries: u8,
    paddr1: ?*?*Curl_addrinfo,
    paddr2: ?*?*Curl_addrinfo,
) ?*Curl_dns_entry {
    var dns = dns_in orelse {
        if (paddr1) |p1| {
            if (p1.*) |a1| {
                Curl_freeaddrinfo(a1);
                p1.* = null;
            }
        }
        if (paddr2) |p2| {
            if (p2.*) |a2| {
                Curl_freeaddrinfo(a2);
                p2.* = null;
            }
        }
        return null;
    };

    dns.type = CURL_DNST_ADDR;
    dns.dns_queries = dns_queries & CURL_DNSQ_ADDR;

    if (paddr1) |p1| {
        if (p1.*) |a1| {
            dns.addr = a1;
            p1.* = null;
        }
    }
    if (paddr2) |p2| {
        if (p2.*) |a2| {
            var phead: *?*Curl_addrinfo = &dns.addr;
            while (phead.*) |cur| {
                phead = &cur.ai_next;
            }
            phead.* = a2;
            p2.* = null;
        }
    }

    if ((dns_queries & CURL_DNSQ_A) != 0 and dnscache_ai_has_family(dns.addr, PF_INET)) {
        dns.dns_responses |= CURL_DNSQ_A;
    }
    if (use_ipv6 and (dns_queries & CURL_DNSQ_AAAA) != 0 and dnscache_ai_has_family(dns.addr, PF_INET6)) {
        dns.dns_responses |= CURL_DNSQ_AAAA;
    }

    if (Curl_vdns_data_dns_shuffle_addresses(data) and dns.addr != null) {
        if (dns_shuffle_addr(data, &dns.addr) != CURLE_OK) {
            dnscache_entry_free(dns);
            return null;
        }
    }

    if (paddr1) |p1| {
        if (p1.*) |a1| {
            Curl_freeaddrinfo(a1);
            p1.* = null;
        }
    }
    if (paddr2) |p2| {
        if (p2.*) |a2| {
            Curl_freeaddrinfo(a2);
            p2.* = null;
        }
    }
    return dns;
}

pub export fn Curl_dnsc_mk_addr(
    data: ?*Curl_easy,
    dns_queries: u8,
    paddr: ?*?*Curl_addrinfo,
    peer: *CurlPeer,
) callconv(.c) ?*Curl_dns_entry {
    var id: dnsc_id = undefined;
    dnsc_peer2id(&id, CURL_DNST_ADDR, peer);
    const dns = dnsc_entry_create(&id, false);
    return dnsc_entry_assign_addr(data, dns, dns_queries, paddr, null);
}

pub export fn Curl_dnsc_mk_addr2(
    data: ?*Curl_easy,
    dns_queries: u8,
    paddr1: ?*?*Curl_addrinfo,
    paddr2: ?*?*Curl_addrinfo,
    peer: *CurlPeer,
) callconv(.c) ?*Curl_dns_entry {
    var id: dnsc_id = undefined;
    dnsc_peer2id(&id, CURL_DNST_ADDR, peer);
    const dns = dnsc_entry_create(&id, false);
    return dnsc_entry_assign_addr(data, dns, dns_queries, paddr1, paddr2);
}

fn dnsc_add_entry(
    data: ?*Curl_easy,
    dnscache: *Curl_dnscache,
    key: *const dnsc_key,
    entry: *Curl_dns_entry,
) ?*Curl_dns_entry {
    entry.added = Curl_pgrs_now(data).*;
    return @ptrCast(@alignCast(Curl_hash_add(&dnscache.entries, &key.data, key.len, entry)));
}

fn dnsc_entry_assign_https(
    dns_in: ?*Curl_dns_entry,
    phinfo: ?*?*Curl_https_rrinfo,
) ?*Curl_dns_entry {
    const dns = dns_in orelse {
        if (phinfo) |ph| {
            if (ph.*) |hi| {
                Curl_httpsrr_destroy(hi);
                ph.* = null;
            }
        }
        return null;
    };

    if (dns.getHinfo()) |old_hi| {
        Curl_httpsrr_destroy(old_hi);
        dns.setHinfo(null);
    }
    dns.type = CURL_DNST_HTTPS;
    dns.dns_queries = CURL_DNSQ_HTTPS;
    dns.dns_responses = CURL_DNSQ_HTTPS;
    if (phinfo) |ph| {
        dns.setHinfo(ph.*);
        ph.* = null;
    }
    return dns;
}

pub export fn Curl_dnsc_mk_https(
    data: ?*Curl_easy,
    phinfo: ?*?*Curl_https_rrinfo,
    peer: *CurlPeer,
) callconv(.c) ?*Curl_dns_entry {
    _ = data;
    var id: dnsc_id = undefined;
    dnsc_peer2id(&id, CURL_DNST_HTTPS, peer);
    const dns = dnsc_entry_create(&id, false);
    return dnsc_entry_assign_https(dns, phinfo);
}

fn dnsc_add_https(
    data: ?*Curl_easy,
    dnscache: *Curl_dnscache,
    phinfo: ?*?*Curl_https_rrinfo,
    id: *dnsc_id,
) ?*Curl_dns_entry {
    var key: dnsc_key = undefined;
    var dns = dnsc_entry_create(id, false);
    dns = dnsc_entry_assign_https(dns, phinfo);
    const d = dns orelse return null;

    dnsc_id2key(&key, id);
    const dns2 = dnsc_add_entry(data, dnscache, &key, d) orelse {
        dnscache_entry_free(d);
        return null;
    };
    dns2.refcount += 1;
    return dns2;
}

fn dnsc_add_addr(
    data: ?*Curl_easy,
    dnscache: *Curl_dnscache,
    dns_queries: u8,
    paddr: ?*?*Curl_addrinfo,
    id: *const dnsc_id,
    key: *const dnsc_key,
    permanent: bool,
) ?*Curl_dns_entry {
    var dns = dnsc_entry_create(id, permanent);
    dns = dnsc_entry_assign_addr(data, dns, dns_queries, paddr, null);
    const d = dns orelse return null;

    const dns2 = dnsc_add_entry(data, dnscache, key, d) orelse {
        dnscache_entry_free(d);
        return null;
    };
    dns2.refcount += 1;
    return dns2;
}

fn dnsc_add_peer_addr(
    data: ?*Curl_easy,
    dnscache: *Curl_dnscache,
    dns_queries: u8,
    paddr: ?*?*Curl_addrinfo,
    id: *dnsc_id,
    permanent: bool,
) ?*Curl_dns_entry {
    var key: dnsc_key = undefined;
    var dns = dnsc_entry_create(id, permanent);
    dns = dnsc_entry_assign_addr(data, dns, dns_queries, paddr, null);
    const d = dns orelse return null;

    dnsc_id2key(&key, id);
    const dns2 = dnsc_add_entry(data, dnscache, &key, d) orelse {
        dnscache_entry_free(d);
        return null;
    };
    dns2.refcount += 1;
    return dns2;
}

pub export fn Curl_dnscache_add(
    data: ?*Curl_easy,
    entry_opt: ?*Curl_dns_entry,
) callconv(.c) CURLcode {
    const dnscache = Curl_vdns_dnscache_get(data) orelse return CURLE_FAILED_INIT;
    const entry = entry_opt orelse return CURLE_BAD_FUNCTION_ARGUMENT;
    if (entry.type == CURL_DNST_INIT) return CURLE_BAD_FUNCTION_ARGUMENT;

    var name: Curl_str = .{ .str = null, .len = 0 };
    var id: dnsc_id = undefined;
    var key: dnsc_key = undefined;

    curlx_parse.curlx_str_assign(&name, entry.hostnamePtr(), entry.hostlen);
    dnsc_str2id(&id, entry.type, &name, entry.port);
    dnsc_id2key(&key, &id);

    Curl_vdns_dnscache_lock(data, dnscache);
    if (dnsc_add_entry(data, dnscache, &key, entry) == null) {
        Curl_vdns_dnscache_unlock(data, dnscache);
        return CURLE_OUT_OF_MEMORY;
    }
    entry.refcount += 1;
    Curl_vdns_dnscache_unlock(data, dnscache);

    if (Curl_vdns_trc_dns_is_verbose(data)) {
        Curl_trc_dns(
            data,
            "cached entry for %s:%u queries=%s",
            entry.hostnamePtr(),
            @as(c_uint, entry.port),
            Curl_resolv_query_str(entry.dns_queries),
        );
    }
    return CURLE_OK;
}

pub export fn Curl_dnscache_add_negative(
    data: ?*Curl_easy,
    dns_queries: u8,
    peer: *CurlPeer,
) callconv(.c) CURLcode {
    const dnscache = Curl_vdns_dnscache_get(data) orelse return CURLE_FAILED_INIT;
    var dns: ?*Curl_dns_entry = null;
    var id: dnsc_id = undefined;
    var result: CURLcode = CURLE_OK;

    Curl_vdns_dnscache_lock(data, dnscache);

    if ((dns_queries & CURL_DNSQ_ADDR) != 0) {
        dnsc_peer2id(&id, CURL_DNST_ADDR, peer);
        dns = dnsc_add_peer_addr(data, dnscache, dns_queries, null, &id, false);
        if (dns == null) {
            result = CURLE_OUT_OF_MEMORY;
        }
    } else if (use_httpsrr and dns_queries == CURL_DNSQ_HTTPS) {
        dnsc_peer2id(&id, CURL_DNST_HTTPS, peer);
        dns = dnsc_add_https(data, dnscache, null, &id);
        if (dns == null) {
            result = CURLE_OUT_OF_MEMORY;
        }
    }

    if (dns) |d| {
        d.refcount -= 1;
        if (Curl_vdns_trc_dns_is_verbose(data)) {
            Curl_trc_dns(
                data,
                "cache negative name resolve for %s:%d type=%s",
                peer.hostname,
                @as(c_int, peer.port),
                Curl_resolv_query_str(dns_queries),
            );
        }
    }
    Curl_vdns_dnscache_unlock(data, dnscache);
    return result;
}

pub export fn Curl_dns_entry_unlink(
    data: ?*Curl_easy,
    pdns: *?*Curl_dns_entry,
) callconv(.c) void {
    if (pdns.*) |dns| {
        const dnscache = Curl_vdns_dnscache_get(data);
        pdns.* = null;
        if (dnscache) |dc| Curl_vdns_dnscache_lock(data, dc);
        dns.refcount -= 1;
        if (dns.refcount == 0) {
            dnscache_entry_free(dns);
        }
        if (dnscache) |dc| Curl_vdns_dnscache_unlock(data, dc);
    }
}

fn dnscache_entry_dtor(entry: ?*anyopaque) callconv(.c) void {
    const dns: *Curl_dns_entry = @ptrCast(@alignCast(entry orelse return));
    dns.refcount -= 1;
    if (dns.refcount == 0) {
        dnscache_entry_free(dns);
    }
}

pub export fn Curl_dnscache_init(dns: *Curl_dnscache, size: usize) callconv(.c) void {
    Curl_hash_init(
        &dns.entries,
        size,
        collections.CURL_HASH_TYPE_BYTES,
        dnscache_entry_dtor,
    );
}

pub export fn Curl_dnscache_destroy(dns: *Curl_dnscache) callconv(.c) void {
    Curl_hash_destroy(&dns.entries);
}

pub export fn Curl_loadhostpairs(data: ?*Curl_easy) callconv(.c) CURLcode {
    const dnscache = Curl_vdns_dnscache_get(data) orelse return CURLE_FAILED_INIT;
    var id: dnsc_id = undefined;
    var key: dnsc_key = undefined;

    Curl_vdns_data_set_wildcard_resolve(data, false);

    var hostp = Curl_vdns_data_get_resolve(data);
    while (hostp) |hp| : (hostp = hp.next) {
        const hp_data = hp.data orelse continue;
        var host: [*:0]const u8 = hp_data;
        var source: Curl_str = .{ .str = null, .len = 0 };

        if (hp_data[0] == '-') {
            var num: i64 = 0;
            host = hp_data + 1;
            if (curlx_parse.curlx_str_single(&host, '[') == 0) {
                if (curlx_parse.curlx_str_until(&host, &source, MAX_IPADR_LEN, ']') != 0 or
                    curlx_parse.curlx_str_single(&host, ']') != 0 or
                    curlx_parse.curlx_str_single(&host, ':') != 0)
                {
                    continue;
                }
            } else {
                if (curlx_parse.curlx_str_until(&host, &source, 4096, ':') != 0 or
                    curlx_parse.curlx_str_single(&host, ':') != 0)
                {
                    continue;
                }
            }

            if (curlx_parse.curlx_str_number(&host, &num, 0xffff) == 0) {
                dnsc_str2id(&id, CURL_DNST_ADDR, &source, @intCast(num));
                dnsc_id2key(&key, &id);
                Curl_vdns_dnscache_lock(data, dnscache);
                _ = Curl_hash_delete(&dnscache.entries, &key.data, key.len);
                Curl_vdns_dnscache_unlock(data, dnscache);
            }
        } else {
            var head: ?*Curl_addrinfo = null;
            var tail: ?*Curl_addrinfo = null;
            var address: [64]u8 = undefined;
            var tmpofft: i64 = 0;
            var port: u16 = 0;
            var permanent: bool = true;
            var has_error: bool = true;
            var addresses: ?[*:0]const u8 = null;

            if (host[0] == '+') {
                host += 1;
                permanent = false;
            }
            if (curlx_parse.curlx_str_single(&host, '[') == 0) {
                if (curlx_parse.curlx_str_until(&host, &source, MAX_IPADR_LEN, ']') != 0 or
                    curlx_parse.curlx_str_single(&host, ']') != 0)
                {
                    continue;
                }
            } else {
                if (curlx_parse.curlx_str_until(&host, &source, 4096, ':') != 0) {
                    continue;
                }
            }

            parse_blk: {
                if (curlx_parse.curlx_str_single(&host, ':') != 0 or
                    curlx_parse.curlx_str_number(&host, &tmpofft, 0xffff) != 0 or
                    curlx_parse.curlx_str_single(&host, ':') != 0)
                {
                    break :parse_blk;
                }
                port = @intCast(tmpofft);
                addresses = host;

                while (host[0] != 0) {
                    var target: Curl_str = .{ .str = null, .len = 0 };
                    var ai: ?*Curl_addrinfo = null;

                    if (curlx_parse.curlx_str_single(&host, '[') == 0) {
                        if (curlx_parse.curlx_str_until(&host, &target, MAX_IPADR_LEN, ']') != 0 or
                            curlx_parse.curlx_str_single(&host, ']') != 0)
                        {
                            break :parse_blk;
                        }
                    } else {
                        if (curlx_parse.curlx_str_until(&host, &target, 4096, ',') != 0) {
                            if (curlx_parse.curlx_str_single(&host, ',') != 0) {
                                break :parse_blk;
                            }
                            continue;
                        }
                    }

                    const tlen = curlx_parse.curlx_strlen(&target);
                    if (!use_ipv6) {
                        if (curlx_parse.curlx_str(&target)) |tstr| {
                            if (std.mem.indexOfScalar(u8, tstr[0..tlen], ':') != null) {
                                Curl_infof(
                                    data,
                                    "Ignoring resolve address '%.*s', missing IPv6 support.",
                                    @as(c_int, @intCast(tlen)),
                                    tstr,
                                );
                                if (curlx_parse.curlx_str_single(&host, ',') != 0) {
                                    break :parse_blk;
                                }
                                continue;
                            }
                        }
                    }

                    if (tlen >= address.len) {
                        break :parse_blk;
                    }
                    if (tlen > 0) {
                        if (curlx_parse.curlx_str(&target)) |tstr| {
                            @memcpy(address[0..tlen], tstr[0..tlen]);
                        }
                    }
                    address[tlen] = 0;

                    const addr_str: [*:0]const u8 = @ptrCast(&address);
                    if (Curl_str2addr(addr_str, port, &ai) != CURLE_OK) {
                        Curl_infof(data, "Resolve IP address '%s' found is illegal", addr_str);
                        break :parse_blk;
                    }

                    if (tail) |t| {
                        t.ai_next = ai;
                        tail = t.ai_next;
                    } else {
                        head = ai;
                        tail = ai;
                    }

                    if (curlx_parse.curlx_str_single(&host, ',') != 0) {
                        break;
                    }
                }

                if (head == null) {
                    break :parse_blk;
                }
                has_error = false;
            }

            if (has_error) {
                Curl_failf(data, "Could not parse CURLOPT_RESOLVE entry '%s'", hp_data);
                Curl_freeaddrinfo(head);
                return CURLE_SETOPT_OPTION_SYNTAX;
            }

            dnsc_str2id(&id, CURL_DNST_ADDR, &source, port);
            dnsc_id2key(&key, &id);
            Curl_vdns_dnscache_lock(data, dnscache);

            var dns: ?*Curl_dns_entry = @ptrCast(@alignCast(Curl_hash_pick(&dnscache.entries, &key.data, key.len)));
            if (dns != null) {
                Curl_infof(
                    data,
                    "RESOLVE %.*s:%u - old addresses discarded",
                    @as(c_int, @intCast(curlx_parse.curlx_strlen(&source))),
                    curlx_parse.curlx_str(&source) orelse "",
                    @as(c_uint, port),
                );
                _ = Curl_hash_delete(&dnscache.entries, &key.data, key.len);
            }

            dns = dnsc_add_addr(data, dnscache, CURL_DNSQ_ADDR, &head, &id, &key, permanent);
            if (dns) |d| {
                d.refcount -= 1;
            }
            Curl_vdns_dnscache_unlock(data, dnscache);

            if (dns == null) {
                return CURLE_OUT_OF_MEMORY;
            }

            const perm_suffix: [*:0]const u8 = if (permanent) "" else " (non-permanent)";
            Curl_infof(
                data,
                "[DNS] added %.*s:%u:%s to cache%s",
                @as(c_int, @intCast(curlx_parse.curlx_strlen(&id.name))),
                curlx_parse.curlx_str(&id.name) orelse "",
                @as(c_uint, id.port),
                addresses orelse "",
                perm_suffix,
            );

            if (curlx_parse.curlx_str_casecompare(&source, "*") != 0) {
                Curl_infof(data, "RESOLVE *:%u using wildcard", @as(c_uint, port));
                Curl_vdns_data_set_wildcard_resolve(data, true);
            }
        }
    }
    Curl_vdns_data_clear_resolve(data);
    return CURLE_OK;
}

// ============================================================================
// 3. lib/vdns/cf-dns.c — DNS Resolution Connection Filter (Curl_cft_dns)
// ============================================================================

const CfDnsCtx = struct {
    dns: ?*Curl_dns_entry = null,
    peer: ?*CurlPeer = null,
    resolv_result: CURLcode = CURLE_OK,
    he_aaaa_await_ms: timediff_t = CURL_HE_AAAA_AWAIT_MS,
    resolv_id: u32 = 0,
    dns_queries: u8 = 0,
    transport: u8 = 0,
    started: bool = false,
    announced: bool = false,
    for_proxy: bool = false,
};

fn cf_dns_ctx_create(
    data: ?*Curl_easy,
    peer: *CurlPeer,
    dns_queries: u8,
    transport: u8,
    for_proxy: bool,
) ?*CfDnsCtx {
    const raw = mem.calloc(1, @sizeOf(CfDnsCtx)) orelse return null;
    const ctx: *CfDnsCtx = @ptrCast(@alignCast(raw));
    ctx.* = .{
        .dns_queries = dns_queries,
        .transport = transport,
        .for_proxy = for_proxy,
        .he_aaaa_await_ms = CURL_HE_AAAA_AWAIT_MS,
    };
    Curl_peer_link(&ctx.peer, peer);

    if (Curl_vdns_trc_dns_is_verbose(data)) {
        Curl_trc_dns(
            data,
            "[%s] created DNS filter for %s:%u, transport=%x",
            Curl_resolv_query_str(ctx.dns_queries),
            peer.hostname,
            @as(c_uint, peer.port),
            @as(c_uint, ctx.transport),
        );
    }
    return ctx;
}

fn cf_dns_ctx_destroy(data: ?*Curl_easy, ctx_opt: ?*CfDnsCtx) void {
    if (ctx_opt) |ctx| {
        Curl_peer_unlink(&ctx.peer);
        Curl_dns_entry_unlink(data, &ctx.dns);
        mem.free(@ptrCast(ctx));
    }
}

fn cf_dns_report_addr(
    data: ?*Curl_easy,
    tmp: *containers.dynbuf,
    label: [*:0]const u8,
    ai_family: c_int,
    ai_in: ?*const Curl_addrinfo,
) void {
    var buf: [MAX_IPADR_LEN]u8 = undefined;
    var sep: [*:0]const u8 = "";

    containers.curlx_dyn_reset(tmp);
    var ai = ai_in;
    while (ai) |a| : (ai = a.ai_next) {
        if (a.ai_family == ai_family) {
            Curl_printable_address(a, &buf, buf.len);
            const result = curlx_dyn_addf(tmp, "%s%s", sep, @as([*:0]const u8, @ptrCast(&buf)));
            if (result != CURLE_OK) {
                Curl_infof(data, "too many IP, cannot show");
                return;
            }
            sep = ", ";
        }
    }

    const out_str: [*:0]const u8 = if (containers.curlx_dyn_len(tmp) != 0)
        containers.curlx_dyn_ptr(tmp).?
    else
        "(none)";
    Curl_infof(data, "%s%s", label, out_str);
}

fn cf_dns_report(
    cf: *Curl_cfilter,
    data: ?*Curl_easy,
    dns: *Curl_dns_entry,
) void {
    const ctx: *CfDnsCtx = @ptrCast(@alignCast(cf.ctx.?));
    const host_str = dns.hostnamePtr();

    if (!Curl_vdns_trc_is_verbose(data) or host_str[0] == 0 or Curl_host_is_ipnum(host_str)) {
        return;
    }

    const peer = ctx.peer.?;
    if (peer.isUnixSocket()) {
        if (use_unix_sockets) {
            if (Curl_trc_cf_is_verbose(cf, data)) {
                Curl_trc_cf_infof(data, cf, "resolved unix://%s", peer.hostname);
            }
        }
    } else {
        var tmp: containers.dynbuf = undefined;
        containers.curlx_dyn_init(&tmp, 1024);
        if (curlDnsqIsAddr(ctx.dns_queries) != 0) {
            Curl_infof(data, "Host %s:%u was resolved.", host_str, @as(c_uint, dns.port));
            if (use_ipv6) {
                cf_dns_report_addr(data, &tmp, "IPv6: ", AF_INET6, dns.addr);
            }
            cf_dns_report_addr(data, &tmp, "IPv4: ", AF_INET, dns.addr);
        } else if (use_httpsrr and (ctx.dns_queries & CURL_DNSQ_HTTPS) != 0) {
            if (dns.getHinfo() == null) {
                Curl_infof(data, "HTTPS-RR %s:%u: -", host_str, @as(c_uint, dns.port));
            } else if (!Curl_httpsrr_applicable(data, dns.getHinfo())) {
                Curl_infof(data, "HTTPS-RR %s:%u: not applicable", host_str, @as(c_uint, dns.port));
            } else {
                const result = Curl_httpsrr_print(&tmp, dns.getHinfo().?);
                if (result == CURLE_OK) {
                    Curl_infof(
                        data,
                        "HTTPS-RR %s:%u: %s",
                        host_str,
                        @as(c_uint, dns.port),
                        containers.curlx_dyn_ptr(&tmp) orelse "",
                    );
                } else {
                    Curl_infof(data, "Error printing HTTPS-RR information");
                }
            }
        }
        containers.curlx_dyn_free(&tmp);
    }
}

fn cf_dns_start(
    cf: *Curl_cfilter,
    data: ?*Curl_easy,
    pdns: *?*Curl_dns_entry,
) CURLcode {
    const ctx: *CfDnsCtx = @ptrCast(@alignCast(cf.ctx.?));
    const timeout_ms = Curl_timeleft_ms(data);
    var result: CURLcode = CURLE_OK;

    pdns.* = null;
    const peer = ctx.peer.?;

    if (Curl_trc_cf_is_verbose(cf, data)) {
        const kind: [*:0]const u8 = if (peer.isUnixSocket()) "unix-domain-socket" else "host";
        Curl_trc_cf_infof(
            data,
            cf,
            "[%s] cf_dns_start %s %s:%u",
            Curl_resolv_query_str(ctx.dns_queries),
            kind,
            peer.hostname,
            @as(c_uint, peer.port),
        );
    }
    if (peer.isUnixSocket()) {
        ctx.dns_queries = CURL_DNSQ_A;
    }

    if (curlDnsqIsAddr(ctx.dns_queries) != 0) {
        if (peer.hostname != null and Curl_is_ipv4addr(peer.hostname.?)) {
            ctx.dns_queries |= CURL_DNSQ_A;
        } else if (use_ipv6 and (peer.flags & 0x04) != 0) {
            ctx.dns_queries |= CURL_DNSQ_AAAA;
        }

        result = Curl_resolv(
            data,
            peer,
            ctx.dns_queries,
            ctx.transport,
            ctx.for_proxy,
            timeout_ms,
            &ctx.resolv_id,
            pdns,
        );
    } else if (use_httpsrr and ctx.dns_queries == CURL_DNSQ_HTTPS) {
        result = Curl_resolv(
            data,
            peer,
            CURL_DNSQ_HTTPS,
            TRNSPRT_TCP,
            ctx.for_proxy,
            timeout_ms,
            &ctx.resolv_id,
            pdns,
        );
    } else {
        Curl_failf(data, "unsupported DNS queries %x", @as(c_uint, ctx.dns_queries));
        return CURLE_FAILED_INIT;
    }

    if (result == CURLE_OK) {
        return CURLE_OK;
    } else if (result == CURLE_AGAIN) {
        return CURLE_OK;
    } else if (result == CURLE_OPERATION_TIMEDOUT) {
        Curl_failf(
            data,
            "Failed to resolve '%s' with timeout after %lld ms",
            peer.hostname,
            @as(c_longlong, Curl_pgrs_since_ms(data, null, TIMER_STARTSINGLE)),
        );
        return CURLE_OPERATION_TIMEDOUT;
    } else {
        if ((ctx.dns_queries & (CURL_DNSQ_A | CURL_DNSQ_AAAA)) != 0) {
            Curl_failf(data, "Could not resolve: %s", peer.hostname);
        }
        return result;
    }
}

fn cf_dns_ready_to_connect(cf: *Curl_cfilter, data: ?*Curl_easy) bool {
    const ctx: *CfDnsCtx = @ptrCast(@alignCast(cf.ctx.?));
    if (ctx.resolv_result != CURLE_OK) {
        return true;
    } else if (ctx.dns != null) {
        return true;
    } else if (use_curl_async) {
        if (curlDnsqIsAddr(ctx.dns_queries) != 0) {
            if (Curl_resolv_has_answers(data, ctx.resolv_id, CURL_DNSQ_AAAA)) {
                return true;
            }
            const pnow = Curl_pgrs_now(data);
            const remain_ms = ctx.he_aaaa_await_ms - Curl_resolv_elapsed_ms(data, ctx.resolv_id, pnow);
            if (remain_ms <= 0) {
                return true;
            }
            if (Curl_trc_cf_is_verbose(cf, data)) {
                Curl_trc_cf_infof(
                    data,
                    cf,
                    "[%s] still waiting %lldms for AAAA result",
                    Curl_resolv_query_str(ctx.dns_queries),
                    @as(c_longlong, remain_ms),
                );
            }
            Curl_expire_set(data, EXPIRE_HAPPY_EYEBALLS, remain_ms, pnow);
            return false;
        } else {
            return true;
        }
    } else {
        return false;
    }
}

fn cf_dns_connect(
    cf: *Curl_cfilter,
    data: ?*Curl_easy,
    done: *bool,
) callconv(.c) CURLcode {
    const ctx: *CfDnsCtx = @ptrCast(@alignCast(cf.ctx.?));
    const ip_query = (ctx.dns_queries & (CURL_DNSQ_A | CURL_DNSQ_AAAA)) != 0;

    if (cf.isConnected()) {
        done.* = true;
        return CURLE_OK;
    }

    done.* = false;
    if (!ctx.started) {
        ctx.started = true;
        ctx.resolv_result = cf_dns_start(cf, data, &ctx.dns);
    }

    if (ctx.dns == null and ctx.resolv_result == CURLE_OK) {
        ctx.resolv_result = Curl_resolv_take_result(data, ctx.resolv_id, &ctx.dns);
    }

    if (ctx.resolv_result != CURLE_OK and ip_query) {
        if (Curl_trc_cf_is_verbose(cf, data)) {
            Curl_trc_cf_infof(
                data,
                cf,
                "[%s] error resolving: %d",
                Curl_resolv_query_str(ctx.dns_queries),
                @as(c_int, @intCast(ctx.resolv_result)),
            );
        }
        return ctx.resolv_result;
    }

    if (ctx.dns != null and !ctx.announced) {
        ctx.announced = true;
        if (cf.sockindex == FIRSTSOCKET and ip_query) {
            Curl_vdns_conn_set_dns_resolved(cf.conn);
            Curl_pgrsTime(data, TIMER_NAMELOOKUP);
        }
        cf_dns_report(cf, data, ctx.dns.?);
    }

    if (!cf_dns_ready_to_connect(cf, data)) {
        return CURLE_OK;
    }

    if (cf.next) |next_cf| {
        if (!next_cf.isConnected()) {
            var sub_done: bool = false;
            const result = Curl_conn_cf_connect(next_cf, data, &sub_done);
            if (result != CURLE_OK or !sub_done) {
                return result;
            }
        }
    }

    if (Curl_trc_cf_is_verbose(cf, data)) {
        Curl_trc_cf_infof(data, cf, "connected filter chain below");
    }
    done.* = true;
    cf.setConnected(true);
    Curl_resolv_destroy(data, ctx.resolv_id);
    return CURLE_OK;
}

fn cf_dns_destroy(cf: *Curl_cfilter, data: ?*Curl_easy) callconv(.c) void {
    const ctx: ?*CfDnsCtx = if (cf.ctx) |p| @ptrCast(@alignCast(p)) else null;
    if (Curl_trc_cf_is_verbose(cf, data)) {
        Curl_trc_cf_infof(data, cf, "destroy");
    }
    cf_dns_ctx_destroy(data, ctx);
    cf.ctx = null;
}

fn cf_dns_adjust_pollset(
    cf: *Curl_cfilter,
    data: ?*Curl_easy,
    ps: *easy_pollset,
) callconv(.c) CURLcode {
    if (use_curl_async) {
        if (!cf.isConnected()) {
            const ctx: *CfDnsCtx = @ptrCast(@alignCast(cf.ctx.?));
            if (!ctx.started) {
                if (Curl_trc_cf_is_verbose(cf, data)) {
                    const peer = ctx.peer.?;
                    Curl_trc_cf_infof(
                        data,
                        cf,
                        "adjust_pollset, starting %s:%u queries=%s",
                        peer.hostname,
                        @as(c_uint, peer.port),
                        Curl_resolv_query_str(ctx.dns_queries),
                    );
                }
                ctx.started = true;
                ctx.resolv_result = cf_dns_start(cf, data, &ctx.dns);
                if (ctx.resolv_result != CURLE_OK or ctx.dns != null) {
                    Curl_multi_mark_dirty(data);
                }
            }
            return Curl_resolv_pollset(data, ps);
        }
    }
    return CURLE_OK;
}

fn cf_dns_cntrl(
    cf: *Curl_cfilter,
    data: ?*Curl_easy,
    event: c_int,
    arg1: c_int,
    arg2: ?*anyopaque,
) callconv(.c) CURLcode {
    _ = arg1;
    _ = arg2;
    const ctx: *CfDnsCtx = @ptrCast(@alignCast(cf.ctx.?));
    switch (event) {
        CF_CTRL_DATA_DONE => {
            if (ctx.dns != null) {
                Curl_dns_entry_unlink(data, &ctx.dns);
            }
        },
        else => {},
    }
    return CURLE_OK;
}

pub export var Curl_cft_dns: Curl_cftype = .{
    .name = "DNS",
    .flags = CF_TYPE_SETUP | CF_TYPE_DNS,
    .log_level = CURL_LOG_LVL_NONE,
    .destroy = cf_dns_destroy,
    .do_connect = cf_dns_connect,
    .do_shutdown = Curl_cf_def_shutdown,
    .adjust_pollset = cf_dns_adjust_pollset,
    .has_data_pending = Curl_cf_def_data_pending,
    .do_send = Curl_cf_def_send,
    .do_recv = Curl_cf_def_recv,
    .cntrl = cf_dns_cntrl,
    .is_alive = Curl_cf_def_conn_is_alive,
    .keep_alive = Curl_cf_def_conn_keep_alive,
    .query = Curl_cf_def_query,
};

fn cf_dns_create(
    pcf: *?*Curl_cfilter,
    data: ?*Curl_easy,
    peer: *CurlPeer,
    dns_queries: u8,
    transport: u8,
    for_proxy: bool,
) CURLcode {
    var cf: ?*Curl_cfilter = null;
    const ctx = cf_dns_ctx_create(data, peer, dns_queries, transport, for_proxy) orelse {
        pcf.* = null;
        return CURLE_OUT_OF_MEMORY;
    };

    const result = Curl_cf_create(&cf, &Curl_cft_dns, ctx);
    if (result != CURLE_OK) {
        cf_dns_ctx_destroy(data, ctx);
        pcf.* = null;
        return result;
    }
    pcf.* = cf;
    return CURLE_OK;
}

fn cf_dns_add(
    data: ?*Curl_easy,
    conn: ?*connectdata,
    sockindex: i8,
    peer_opt: ?*CurlPeer,
    dns_queries: u8,
    transport: u8,
) CURLcode {
    const peer = peer_opt orelse return CURLE_FAILED_INIT;
    const for_proxy = Curl_vdns_conn_is_proxy_peer(conn, peer);

    var cf: ?*Curl_cfilter = null;
    const result = cf_dns_create(&cf, data, peer, dns_queries, transport, for_proxy);
    if (result != CURLE_OK) return result;
    Curl_conn_cf_add(data, conn, sockindex, cf.?);
    return CURLE_OK;
}

fn cf_dns_insert_after(
    cf_at: *Curl_cfilter,
    data: ?*Curl_easy,
    peer: *CurlPeer,
    dns_queries: u8,
    transport: u8,
) CURLcode {
    var cf: ?*Curl_cfilter = null;
    const result = cf_dns_create(&cf, data, peer, dns_queries, transport, false);
    if (result != CURLE_OK) return result;
    Curl_conn_cf_insert_after(cf_at, cf);
    return CURLE_OK;
}

fn cf_dns_add_resolve(
    data: ?*Curl_easy,
    conn: ?*connectdata,
    sockindex: i8,
    peer_opt: ?*CurlPeer,
    dns_queries_in: u8,
    transport: u8,
) CURLcode {
    const peer = peer_opt orelse return CURLE_FAILED_INIT;
    const data_conn = Curl_vdns_data_conn(data) orelse conn;
    var cf = Curl_vdns_conn_cfilter(data_conn, sockindex);
    var cf_dns: ?*Curl_cfilter = null;
    var dns_queries = dns_queries_in;
    const is_addr = curlDnsqIsAddr(dns_queries) != 0;

    if ((dns_queries & CURL_DNSQ_HTTPS) != 0 and peer.hostname != null and Curl_is_ipaddr(peer.hostname.?)) {
        dns_queries &= ~CURL_DNSQ_HTTPS;
    }

    while (cf != null and dns_queries != 0) : (cf = cf.?.next) {
        const cur = cf.?;
        if (cur.cft == &Curl_cft_dns) {
            const ctx: *CfDnsCtx = @ptrCast(@alignCast(cur.ctx.?));
            cf_dns = cur;
            if (Curl_peer_same_destination(ctx.peer, peer)) {
                dns_queries = ~ctx.dns_queries & dns_queries;
                if (dns_queries == 0) {
                    return CURLE_OK;
                } else if (is_addr and !ctx.started and curlDnsqIsAddr(ctx.dns_queries) != 0) {
                    ctx.dns_queries |= dns_queries;
                    if (Curl_vdns_trc_dns_is_verbose(data)) {
                        Curl_trc_dns(
                            data,
                            "[%s] added queries=%s for %s:%u",
                            Curl_resolv_query_str(ctx.dns_queries),
                            Curl_resolv_query_str(dns_queries),
                            peer.hostname,
                            @as(c_uint, peer.port),
                        );
                    }
                    return CURLE_OK;
                }
            }
        }
    }

    if (dns_queries != 0) {
        if (cf_dns) |last_dns| {
            return cf_dns_insert_after(last_dns, data, peer, dns_queries, transport);
        } else {
            return cf_dns_add(data, conn, sockindex, peer, dns_queries, transport);
        }
    }
    return CURLE_OK;
}

pub export fn Curl_conn_dns_add_addr_resolve(
    data: ?*Curl_easy,
    conn: ?*connectdata,
    sockindex: i8,
    peer: ?*CurlPeer,
    dns_queries: u8,
    transport: u8,
) callconv(.c) CURLcode {
    return cf_dns_add_resolve(data, conn, sockindex, peer, dns_queries & CURL_DNSQ_ADDR, transport);
}

pub export fn Curl_conn_dns_addr_result(
    conn: ?*connectdata,
    sockindex: i8,
    peer: ?*CurlPeer,
) callconv(.c) CURLcode {
    var cf = Curl_vdns_conn_cfilter(conn, sockindex);
    while (cf) |cur| : (cf = cur.next) {
        if (cur.cft == &Curl_cft_dns) {
            const ctx: *CfDnsCtx = @ptrCast(@alignCast(cur.ctx.?));
            if (Curl_peer_same_destination(ctx.peer, peer) and
                (ctx.dns_queries & (CURL_DNSQ_A | CURL_DNSQ_AAAA)) != 0)
            {
                if (ctx.dns != null or ctx.resolv_result != CURLE_OK) {
                    return ctx.resolv_result;
                }
                return CURLE_AGAIN;
            }
        }
    }
    return CURLE_FAILED_INIT;
}

pub export fn Curl_conn_dns_get_ai(
    data: ?*Curl_easy,
    peer_opt: ?*CurlPeer,
    sockindex: i8,
    ai_family: c_int,
    index: c_uint,
) callconv(.c) ?*const Curl_addrinfo {
    const peer = peer_opt orelse return null;
    const conn = Curl_vdns_data_conn(data);
    var cf = Curl_vdns_conn_cfilter(conn, sockindex);

    while (cf) |cur| : (cf = cur.next) {
        if (cur.cft == &Curl_cft_dns) {
            const ctx: *CfDnsCtx = @ptrCast(@alignCast(cur.ctx.?));
            if (Curl_peer_same_destination(ctx.peer, peer) and
                (ctx.dns_queries & (CURL_DNSQ_A | CURL_DNSQ_AAAA)) != 0)
            {
                if (Curl_trc_cf_is_verbose(cur, data)) {
                    Curl_trc_cf_infof(
                        data,
                        cur,
                        "get %uth result for %s:%u, family=%d, dns=%d",
                        index,
                        peer.hostname,
                        @as(c_uint, peer.port),
                        ai_family,
                        @as(c_int, @intFromBool(ctx.dns != null)),
                    );
                }
                if (ctx.resolv_result != CURLE_OK) {
                    return null;
                } else if (ctx.dns) |dns| {
                    if (ai_family == AF_INET and (ctx.dns_queries & CURL_DNSQ_A) == 0) {
                        return null;
                    }
                    if (use_ipv6 and ai_family == AF_INET6 and (ctx.dns_queries & CURL_DNSQ_AAAA) == 0) {
                        return null;
                    }
                    return Curl_addrinfo_get(dns.addr, ai_family, index);
                } else {
                    return Curl_resolv_get_ai(data, ctx.resolv_id, ai_family, index);
                }
            }
        }
    }
    return null;
}

pub export fn Curl_conn_dns_add_https_resolve(
    data: ?*Curl_easy,
    conn: ?*connectdata,
    sockindex: i8,
    peer: ?*CurlPeer,
) callconv(.c) CURLcode {
    if (!use_httpsrr) return CURLE_OK;
    return cf_dns_add_resolve(
        data,
        conn,
        sockindex,
        peer,
        CURL_DNSQ_HTTPS,
        Curl_vdns_conn_transport_wanted(conn),
    );
}

pub export fn Curl_conn_dns_get_https(
    data: ?*Curl_easy,
    sockindex: i8,
    peer: ?*CurlPeer,
) callconv(.c) ?*const Curl_https_rrinfo {
    if (!use_httpsrr) return null;
    const conn = Curl_vdns_data_conn(data);
    var cf = Curl_vdns_conn_cfilter(conn, sockindex);
    while (cf) |cur| : (cf = cur.next) {
        if (cur.cft == &Curl_cft_dns) {
            const ctx: *CfDnsCtx = @ptrCast(@alignCast(cur.ctx.?));
            if (Curl_peer_same_destination(ctx.peer, peer) and
                (ctx.dns_queries & CURL_DNSQ_HTTPS) != 0)
            {
                if (ctx.dns) |dns| {
                    return dns.getHinfo();
                }
                return null;
            }
        }
    }
    return null;
}

pub export fn Curl_conn_dns_resolved_https(
    data: ?*Curl_easy,
    sockindex: i8,
    peer: ?*CurlPeer,
) callconv(.c) bool {
    if (!use_httpsrr) return true;
    const conn = Curl_vdns_data_conn(data);
    var cf = Curl_vdns_conn_cfilter(conn, sockindex);
    while (cf) |cur| : (cf = cur.next) {
        if (cur.cft == &Curl_cft_dns) {
            const ctx: *CfDnsCtx = @ptrCast(@alignCast(cur.ctx.?));
            if (Curl_peer_same_destination(ctx.peer, peer) and
                (ctx.dns_queries & CURL_DNSQ_HTTPS) != 0)
            {
                if (ctx.dns != null or ctx.resolv_result != CURLE_OK) return true;
                return false;
            }
        }
    }
    return true;
}

// ============================================================================
// 4. lib/vdns/asyn-ares.c — c-ares Asynchronous DNS Resolver (when USE_RESOLV_ARES)
// ============================================================================

const ARES_SUCCESS: c_int = 0;
const ARES_ENODATA: c_int = 1;
const ARES_ENOTFOUND: c_int = 4;
const ARES_EBADSTR: c_int = 10;
const ARES_ENOMEM: c_int = 15;
const ARES_EDESTRUCTION: c_int = 16;
const ARES_ENOTINITIALIZED: c_int = 23;
const ARES_LIB_INIT_ALL: c_int = 1;
const ARES_AI_NUMERICSERV: c_int = 1 << 3;
const CARES_MAX_ADDRS: c_uint = 256;

const SockaddrInSize: usize = 16;
const SockaddrIn6Size: usize = 28;

const ares_addrinfo_node = extern struct {
    ai_ttl: c_int,
    ai_flags: c_int,
    ai_family: c_int,
    ai_socktype: c_int,
    ai_protocol: c_int,
    ai_addrlen: c_uint,
    ai_addr: ?*const anyopaque,
    ai_next: ?*ares_addrinfo_node,
};

const ares_addrinfo = extern struct {
    cnames: ?*anyopaque,
    nodes: ?*ares_addrinfo_node,
    name: ?[*:0]u8,
};

const ares_addrinfo_hints = extern struct {
    ai_flags: c_int = 0,
    ai_family: c_int = 0,
    ai_socktype: c_int = 0,
    ai_protocol: c_int = 0,
};

const ares_addrinfo_callback = *const fn (
    arg: ?*anyopaque,
    status: c_int,
    timeouts: c_int,
    res: ?*ares_addrinfo,
) callconv(.c) void;

const ares_callback_dnsrec = *const fn (
    arg: ?*anyopaque,
    status: c_int,
    timeouts: usize,
    dnsrec: ?*const anyopaque,
) callconv(.c) void;

const asyn_ares_c = struct {
    extern fn ares_library_init(flags: c_int) callconv(.c) c_int;
    extern fn ares_library_cleanup() callconv(.c) void;
    extern fn ares_version(version: ?*c_int) callconv(.c) [*:0]const u8;
    extern fn ares_destroy(channel: ?*anyopaque) callconv(.c) void;
    extern fn ares_cancel(channel: ?*anyopaque) callconv(.c) void;
    extern fn ares_strerror(code: c_int) callconv(.c) [*:0]const u8;
    extern fn ares_timeout(
        channel: ?*const anyopaque,
        maxtv: ?*vdns_cfilters.AresTimeval,
        tv: *vdns_cfilters.AresTimeval,
    ) callconv(.c) ?*vdns_cfilters.AresTimeval;
    extern fn ares_getaddrinfo(
        channel: ?*anyopaque,
        node: [*:0]const u8,
        service: [*:0]const u8,
        hints: *const ares_addrinfo_hints,
        callback: ares_addrinfo_callback,
        arg: ?*anyopaque,
    ) callconv(.c) void;
    extern fn ares_freeaddrinfo(ai: ?*ares_addrinfo) callconv(.c) void;
    extern fn ares_query(
        channel: ?*anyopaque,
        name: [*:0]const u8,
        dnsclass: c_int,
        rec_type: c_int,
        callback: *const fn (?*anyopaque, c_int, c_int, ?[*]const u8, c_int) callconv(.c) void,
        arg: ?*anyopaque,
    ) callconv(.c) void;
    extern fn ares_dns_parse(
        buf: [*]const u8,
        buf_len: usize,
        flags: c_uint,
        dnsrec: *?*anyopaque,
    ) callconv(.c) c_int;
    extern fn ares_dns_record_destroy(dnsrec: ?*anyopaque) callconv(.c) void;
    extern fn ares_set_servers_ports_csv(channel: ?*anyopaque, servers: [*:0]const u8) callconv(.c) c_int;
    extern fn ares_set_local_dev(channel: ?*anyopaque, local_dev_name: [*:0]const u8) callconv(.c) void;
    extern fn ares_set_local_ip4(channel: ?*anyopaque, local_ip: c_uint) callconv(.c) void;
    extern fn ares_set_local_ip6(channel: ?*anyopaque, local_ip6: *const [16]u8) callconv(.c) void;
    extern fn ares_get_servers_csv(channel: ?*const anyopaque) callconv(.c) ?[*:0]u8;
    extern fn ares_free_string(str: ?*anyopaque) callconv(.c) void;

    extern fn Curl_zig_ares_init_channel(
        data: ?*Curl_easy,
        ares_ver: c_int,
        channel_out: *?*anyopaque,
    ) callconv(.c) c_int;
    extern fn Curl_zig_easy_get_dns_servers(data: ?*const Curl_easy) callconv(.c) ?[*:0]const u8;
    extern fn Curl_zig_easy_get_dns_interface(data: ?*const Curl_easy) callconv(.c) ?[*:0]const u8;
    extern fn Curl_zig_easy_get_dns_local_ip4(data: ?*const Curl_easy) callconv(.c) ?[*:0]const u8;
    extern fn Curl_zig_easy_get_dns_local_ip6(data: ?*const Curl_easy) callconv(.c) ?[*:0]const u8;

    extern fn Curl_resolv_announce_start(data: ?*Curl_easy, resolver: ?*anyopaque) callconv(.c) CURLcode;
    extern fn Curl_async_get(data: ?*Curl_easy, resolv_id: u32) callconv(.c) ?*Curl_resolv_async;
    extern fn Curl_async_failed(data: ?*Curl_easy, async_ctx: *Curl_resolv_async, detail: ?[*:0]const u8) callconv(.c) CURLcode;
    extern fn Curl_pgrsUpdate(data: ?*Curl_easy) callconv(.c) c_int;
    extern fn curl_msnprintf(buffer: [*]u8, maxlength: usize, format: [*:0]const u8, ...) callconv(.c) c_int;
    extern fn curl_maprintf(format: [*:0]const u8, ...) callconv(.c) ?[*:0]u8;
    extern fn Curl_conn_get_transport(data: ?*Curl_easy, conn: ?*connectdata) callconv(.c) u8;
    extern fn getenv(name: [*:0]const u8) callconv(.c) ?[*:0]const u8;
};

var ares_ver_global: c_int = 0;

pub fn Curl_async_ares_ver() callconv(.c) [*:0]const u8 {
    return asyn_ares_c.ares_version(null);
}

fn ares_global_init() callconv(.c) c_int {
    if (asyn_ares_c.ares_library_init(ARES_LIB_INIT_ALL) != 0) {
        return @intCast(CURLE_FAILED_INIT);
    }
    _ = asyn_ares_c.ares_version(&ares_ver_global);
    return @intCast(CURLE_OK);
}

fn ares_global_cleanup() callconv(.c) void {
    asyn_ares_c.ares_library_cleanup();
}

fn async_ares_set_dns_servers(data: ?*Curl_easy, async_ctx: ?*Curl_resolv_async) CURLcode {
    var servers = asyn_ares_c.Curl_zig_easy_get_dns_servers(data);
    if (asyn_ares_c.getenv("CURL_DNS_SERVER")) |env_servers| {
        servers = env_servers;
    }
    const srv = servers orelse return CURLE_OK;

    var ares_result: c_int = ARES_SUCCESS;
    if (async_ctx) |a| {
        if (a.ares.channel) |ch| {
            ares_result = asyn_ares_c.ares_set_servers_ports_csv(ch, srv);
        }
    }
    return switch (ares_result) {
        ARES_SUCCESS => CURLE_OK,
        ARES_ENOMEM => CURLE_OUT_OF_MEMORY,
        else => CURLE_BAD_FUNCTION_ARGUMENT,
    };
}

fn async_ares_set_dns_interface(data: ?*Curl_easy, async_ctx: ?*Curl_resolv_async) CURLcode {
    const interf = asyn_ares_c.Curl_zig_easy_get_dns_interface(data) orelse "";
    if (async_ctx) |a| {
        if (a.ares.channel) |ch| {
            asyn_ares_c.ares_set_local_dev(ch, interf);
        }
    }
    return CURLE_OK;
}

fn async_ares_set_dns_local_ip4(data: ?*Curl_easy, async_ctx: ?*Curl_resolv_async) CURLcode {
    var a4: u32 = 0;
    if (asyn_ares_c.Curl_zig_easy_get_dns_local_ip4(data)) |local_ip4| {
        if (local_ip4[0] != 0) {
            if (curlx_time_net.curlx_inet_pton(AF_INET, local_ip4, @ptrCast(&a4)) != 1) {
                return CURLE_BAD_FUNCTION_ARGUMENT;
            }
        }
    }
    if (async_ctx) |a| {
        if (a.ares.channel) |ch| {
            asyn_ares_c.ares_set_local_ip4(ch, std.mem.bigToNative(u32, a4));
        }
    }
    return CURLE_OK;
}

fn async_ares_set_dns_local_ip6(data: ?*Curl_easy, async_ctx: ?*Curl_resolv_async) CURLcode {
    if (!use_ipv6) return CURLE_NOT_BUILT_IN;
    var a6: [16]u8 = @splat(0);
    if (asyn_ares_c.Curl_zig_easy_get_dns_local_ip6(data)) |local_ip6| {
        if (local_ip6[0] != 0) {
            if (curlx_time_net.curlx_inet_pton(AF_INET6, local_ip6, @ptrCast(&a6)) != 1) {
                return CURLE_BAD_FUNCTION_ARGUMENT;
            }
        }
    }
    if (async_ctx) |a| {
        if (a.ares.channel) |ch| {
            asyn_ares_c.ares_set_local_ip6(ch, &a6);
        }
    }
    return CURLE_OK;
}

fn async_ares_init(data: ?*Curl_easy, async_ctx: *Curl_resolv_async) CURLcode {
    const ares = &async_ctx.ares;
    var result: CURLcode = CURLE_OK;

    ares.ares_status = ARES_ENOTFOUND;
    async_ctx.queries_ongoing = 0;

    if (ares_ver_global == 0) {
        _ = asyn_ares_c.ares_version(&ares_ver_global);
    }

    const status = asyn_ares_c.Curl_zig_ares_init_channel(data, ares_ver_global, &ares.channel);
    if (status != ARES_SUCCESS) {
        ares.channel = null;
        return if (status == ARES_ENOMEM) CURLE_OUT_OF_MEMORY else CURLE_FAILED_INIT;
    }

    blk: {
        result = async_ares_set_dns_servers(data, async_ctx);
        if (result != CURLE_OK and result != CURLE_NOT_BUILT_IN) break :blk;

        result = async_ares_set_dns_interface(data, async_ctx);
        if (result != CURLE_OK and result != CURLE_NOT_BUILT_IN) break :blk;

        result = async_ares_set_dns_local_ip4(data, async_ctx);
        if (result != CURLE_OK and result != CURLE_NOT_BUILT_IN) break :blk;

        result = async_ares_set_dns_local_ip6(data, async_ctx);
        if (result != CURLE_OK and result != CURLE_NOT_BUILT_IN) break :blk;

        result = CURLE_OK;
    }

    if (result != CURLE_OK) {
        if (ares.channel) |ch| {
            asyn_ares_c.ares_destroy(ch);
            ares.channel = null;
        }
    }
    return result;
}

fn ares_shutdown(data: ?*Curl_easy, async_ctx: ?*Curl_resolv_async) callconv(.c) void {
    ares_destroy_fn(data, async_ctx);
}

fn ares_destroy_fn(data: ?*Curl_easy, async_ctx: ?*Curl_resolv_async) callconv(.c) void {
    _ = data;
    const a = async_ctx orelse return;
    if (a.ares.channel) |ch| {
        asyn_ares_c.ares_destroy(ch);
        a.ares.channel = null;
    }
}

fn ares_pollset_fn(
    data: ?*Curl_easy,
    async_ctx: ?*Curl_resolv_async,
    ps: *easy_pollset,
) callconv(.c) CURLcode {
    const a = async_ctx orelse return CURLE_OK;
    var result: CURLcode = CURLE_OK;
    if (a.ares.channel) |ch| {
        result = vdns_cfilters.Curl_ares_pollset(data, ch, ps);
        if (result == CURLE_OK) {
            const ms = vdns_cfilters.Curl_ares_timeout_ms(data, a, ch);
            Curl_expire_set(data, EXPIRE_ASYNC_NAME, ms, Curl_pgrs_now(data));
        }
    }
    return result;
}

fn ares_take_result_fn(
    data: ?*Curl_easy,
    async_ctx: ?*Curl_resolv_async,
    pdns: *?*Curl_dns_entry,
) callconv(.c) CURLcode {
    pdns.* = null;
    const a = async_ctx orelse return CURLE_FAILED_INIT;
    const ares = &a.ares;
    var dns: ?*Curl_dns_entry = null;
    var result: CURLcode = CURLE_OK;

    out: {
        if (vdns_cfilters.Curl_ares_perform(ares.channel, 0) < 0) {
            result = CURLE_UNRECOVERABLE_POLL;
            break :out;
        }

        if (a.queries_ongoing != 0) {
            result = CURLE_AGAIN;
            break :out;
        }

        result = ares.result;
        if (ares.ares_status == ARES_SUCCESS and result == CURLE_OK) {
            if (curlDnsqIsAddr(a.dns_queries) != 0) {
                dns = Curl_dnsc_mk_addr2(data, a.dns_queries, &a.ai_AAAA, &a.ai_A, a.peer.?);
                if (dns == null) {
                    result = CURLE_OUT_OF_MEMORY;
                    break :out;
                }
            }

            if (use_httpsrr) {
                if (dns == null and (a.dns_queries & CURL_DNSQ_HTTPS) != 0) {
                    dns = Curl_dnsc_mk_https(data, &a.httpsrr, a.peer.?);
                    if (dns == null) {
                        result = CURLE_OUT_OF_MEMORY;
                        break :out;
                    }
                }
            }
        }

        if (result == CURLE_OK and dns == null) {
            var msg: ?[*:0]const u8 = null;
            a.setNegativeAnswer(
                !ares.transientErr() and
                    (ares.ares_status == ARES_ENOTFOUND or ares.ares_status == ARES_ENODATA),
            );
            if (ares.ares_status != ARES_SUCCESS) {
                msg = asyn_ares_c.ares_strerror(ares.ares_status);
            }
            result = asyn_ares_c.Curl_async_failed(data, a, msg);
        }

        if (Curl_vdns_trc_dns_is_verbose(data)) {
            const found_prefix: [*:0]const u8 = if (dns != null) "" else "not ";
            Curl_trc_dns(
                data,
                "[%s] ares_take_result, result=%d, ares_result=%d, ares_status=%d, dns=%sfound",
                Curl_resolv_query_str(a.dns_queries),
                @as(c_int, @intCast(result)),
                @as(c_int, @intCast(ares.result)),
                ares.ares_status,
                found_prefix,
            );
        }
    }

    if (result != CURLE_AGAIN) {
        ares.result = result;
    }
    pdns.* = if (result != CURLE_OK) null else dns;
    return result;
}

fn async_ares_poll_timeout(ares: *async_ares_ctx, timeout_ms: timediff_t) timediff_t {
    var time_buf: vdns_cfilters.AresTimeval = undefined;
    var max_timeout: vdns_cfilters.AresTimeval = undefined;
    const itimeout_ms: c_int = if (timeout_ms > std.math.maxInt(c_int))
        std.math.maxInt(c_int)
    else if (timeout_ms < 0)
        -1
    else
        @intCast(timeout_ms);

    max_timeout.tv_sec = @intCast(@divTrunc(itimeout_ms, 1000));
    max_timeout.tv_usec = @intCast(@rem(itimeout_ms, 1000) * 1000);

    const ares_calced = asyn_ares_c.ares_timeout(ares.channel, &max_timeout, &time_buf) orelse return 1000;
    if (ares_calced.tv_sec == 0) {
        return @intCast(@divTrunc(ares_calced.tv_usec, 1000));
    }
    return 1000;
}

fn ares_await_fn(
    data: ?*Curl_easy,
    resolv_id: u32,
    pdns: *?*Curl_dns_entry,
) callconv(.c) CURLcode {
    pdns.* = null;
    const a = asyn_ares_c.Curl_async_get(data, resolv_id) orelse return CURLE_FAILED_INIT;
    const ares = &a.ares;
    const start = Curl_pgrs_now(data).*;
    var result: CURLcode = CURLE_OK;

    while (result == CURLE_OK) {
        var timeout_ms = Curl_timeleft_ms(data);
        if (timeout_ms == 0) {
            const elapsed_ms = curlx_time_net.curlx_ptimediff_ms(Curl_pgrs_now(data), &start);
            if (elapsed_ms < CURL_TIMEOUT_RESOLVE_MS) {
                timeout_ms = CURL_TIMEOUT_RESOLVE_MS - elapsed_ms;
            } else {
                timeout_ms = -1;
            }
        }

        if (timeout_ms < 0) {
            result = CURLE_OPERATION_TIMEDOUT;
            break;
        }

        if (vdns_cfilters.Curl_ares_perform(ares.channel, async_ares_poll_timeout(ares, timeout_ms)) < 0) {
            result = CURLE_UNRECOVERABLE_POLL;
            break;
        }

        result = ares_take_result_fn(data, a, pdns);
        if (result == CURLE_AGAIN) {
            result = CURLE_OK;
        } else if (result != CURLE_OK or pdns.* != null) {
            break;
        }

        if (asyn_ares_c.Curl_pgrsUpdate(data) != 0) {
            result = CURLE_ABORTED_BY_CALLBACK;
            break;
        }
    }

    if (result != CURLE_OK) {
        asyn_ares_c.ares_cancel(ares.channel);
    }
    return result;
}

fn async_ares_addr_seen(
    cafirst: ?*const Curl_addrinfo,
    family: c_int,
    ss_size: usize,
    addr: *const anyopaque,
) bool {
    var ca = cafirst;
    const addr_bytes: [*]const u8 = @ptrCast(addr);
    while (ca) |cur| : (ca = cur.ai_next) {
        if (cur.ai_family == family and @as(usize, cur.ai_addrlen) == ss_size) {
            if (cur.ai_addr) |cur_addr| {
                const cur_bytes: [*]const u8 = @ptrCast(cur_addr);
                if (std.mem.eql(u8, cur_bytes[0..ss_size], addr_bytes[0..ss_size])) {
                    return true;
                }
            }
        }
    }
    return false;
}

fn async_ares_node2addr(node: ?*ares_addrinfo_node) ?*Curl_addrinfo {
    var ai = node;
    var cafirst: ?*Curl_addrinfo = null;
    var calast: ?*Curl_addrinfo = null;
    var had_error = false;
    var naddrs: c_uint = 0;

    while (ai != null and naddrs < CARES_MAX_ADDRS) : (ai = ai.?.ai_next) {
        const cur = ai.?;
        const ss_size: usize = if (cur.ai_family == AF_INET)
            SockaddrInSize
        else if (use_ipv6 and cur.ai_family == AF_INET6)
            SockaddrIn6Size
        else
            continue;

        const cur_addr = cur.ai_addr orelse continue;
        if (cur.ai_addrlen == 0 or @as(usize, cur.ai_addrlen) < ss_size)
            continue;

        if (async_ares_addr_seen(cafirst, cur.ai_family, ss_size, cur_addr))
            continue;

        const raw = mem.malloc(@sizeOf(Curl_addrinfo) + ss_size) orelse {
            had_error = true;
            break;
        };
        const ca: *Curl_addrinfo = @ptrCast(@alignCast(raw));
        const addr_dst = raw + @sizeOf(Curl_addrinfo);
        const addr_src: [*]const u8 = @ptrCast(cur_addr);

        ca.ai_flags = cur.ai_flags;
        ca.ai_family = cur.ai_family;
        ca.ai_socktype = cur.ai_socktype;
        ca.ai_protocol = cur.ai_protocol;
        ca.ai_addrlen = @intCast(ss_size);
        ca.ai_addr = @ptrCast(addr_dst);
        ca.ai_canonname = null;
        ca.ai_next = null;
        @memcpy(addr_dst[0..ss_size], addr_src[0..ss_size]);

        if (cafirst == null) {
            cafirst = ca;
        }
        if (calast) |last| {
            last.ai_next = ca;
        }
        calast = ca;
        naddrs += 1;
    }

    if (had_error) {
        Curl_freeaddrinfo(cafirst);
        cafirst = null;
    }
    return cafirst;
}

fn async_ares_A_cb(
    user_data: ?*anyopaque,
    status: c_int,
    timeouts: c_int,
    ares_ai: ?*ares_addrinfo,
) callconv(.c) void {
    _ = timeouts;
    const a: *Curl_resolv_async = @ptrCast(@alignCast(user_data orelse return));
    const ares = &a.ares;

    a.dns_responses |= CURL_DNSQ_A;
    a.queries_ongoing -= 1;
    a.setDone(a.queries_ongoing == 0);
    if (status == ARES_SUCCESS) {
        ares.ares_status = ARES_SUCCESS;
        if (ares_ai) |ai| {
            a.ai_A = async_ares_node2addr(ai.nodes);
            asyn_ares_c.ares_freeaddrinfo(ai);
        }
    } else {
        if (status != ARES_ENOTFOUND and status != ARES_ENODATA) {
            ares.setTransientErr(true);
        }
        if (ares.ares_status != ARES_SUCCESS) {
            ares.ares_status = status;
        }
    }
}

fn async_ares_AAAA_cb(
    user_data: ?*anyopaque,
    status: c_int,
    timeouts: c_int,
    ares_ai: ?*ares_addrinfo,
) callconv(.c) void {
    _ = timeouts;
    const a: *Curl_resolv_async = @ptrCast(@alignCast(user_data orelse return));
    const ares = &a.ares;

    a.dns_responses |= CURL_DNSQ_AAAA;
    a.queries_ongoing -= 1;
    a.setDone(a.queries_ongoing == 0);
    if (status == ARES_SUCCESS) {
        ares.ares_status = ARES_SUCCESS;
        if (ares_ai) |ai| {
            a.ai_AAAA = async_ares_node2addr(ai.nodes);
            asyn_ares_c.ares_freeaddrinfo(ai);
        }
    } else {
        if (status != ARES_ENOTFOUND and status != ARES_ENODATA) {
            ares.setTransientErr(true);
        }
        if (ares.ares_status != ARES_SUCCESS) {
            ares.ares_status = status;
        }
    }
}

fn async_ares_rr_done(
    user_data: ?*anyopaque,
    status: c_int,
    timeouts: usize,
    dnsrec: ?*const anyopaque,
) callconv(.c) void {
    _ = timeouts;
    if (!use_httpsrr) return;
    const a: *Curl_resolv_async = @ptrCast(@alignCast(user_data orelse return));
    const ares = &a.ares;

    a.dns_responses |= CURL_DNSQ_HTTPS;
    a.queries_ongoing -= 1;
    a.setDone(a.queries_ongoing == 0);
    ares.ares_status = status;
    if (status != ARES_ENOTFOUND and status != ARES_ENODATA) {
        ares.setTransientErr(true);
    }
    if (status != ARES_SUCCESS or dnsrec == null) {
        return;
    }
    ares.result = Curl_httpsrr_from_ares(dnsrec, &a.httpsrr);
}

fn async_ares_rr_query_cb(
    user_data: ?*anyopaque,
    status: c_int,
    timeouts: c_int,
    abuf: ?[*]const u8,
    alen: c_int,
) callconv(.c) void {
    var dnsrec: ?*anyopaque = null;
    var eff_status = status;
    if (status == ARES_SUCCESS and abuf != null and alen > 0) {
        eff_status = asyn_ares_c.ares_dns_parse(abuf.?, @intCast(alen), 0, &dnsrec);
    }
    defer if (dnsrec != null) asyn_ares_c.ares_dns_record_destroy(dnsrec);
    async_ares_rr_done(user_data, eff_status, @intCast(@max(timeouts, 0)), dnsrec);
}

fn ares_getaddrinfo_fn(
    data: ?*Curl_easy,
    async_ctx: ?*Curl_resolv_async,
) callconv(.c) CURLcode {
    const a = async_ctx orelse return CURLE_FAILED_INIT;
    const ares = &a.ares;
    var service: [12]u8 = undefined;
    var result: CURLcode = CURLE_OK;

    out: {
        if (ares.channel != null) {
            result = CURLE_FAILED_INIT;
            break :out;
        }

        result = async_ares_init(data, a);
        if (result != CURLE_OK) break :out;

        result = asyn_ares_c.Curl_resolv_announce_start(data, ares.channel);
        if (result != CURLE_OK) break :out;

        if (Curl_vdns_trc_dns_is_verbose(data)) {
            if (asyn_ares_c.ares_get_servers_csv(ares.channel)) |csv| {
                Curl_trc_dns(data, "ares: servers=%s", csv);
                asyn_ares_c.ares_free_string(@ptrCast(csv));
            }
        }

        const peer = a.peer.?;
        const hostname = peer.hostname.?;
        _ = asyn_ares_c.curl_msnprintf(&service, service.len, "%d", @as(c_int, peer.port));
        const service_str: [*:0]const u8 = @ptrCast(&service);
        const socktype: c_int = if (asyn_ares_c.Curl_conn_get_transport(data, Curl_vdns_data_conn(data)) == TRNSPRT_TCP)
            vdns_cfilters.SOCK_STREAM
        else
            vdns_cfilters.SOCK_DGRAM;

        if (use_ipv6 and (a.dns_queries & CURL_DNSQ_AAAA) != 0) {
            var hints: ares_addrinfo_hints = .{
                .ai_family = PF_INET6,
                .ai_socktype = socktype,
                .ai_flags = ARES_AI_NUMERICSERV,
            };
            if (Curl_vdns_trc_dns_is_verbose(data)) {
                Curl_trc_dns(data, "[AAAA] ares: query records for %s", hostname);
            }
            a.queries_ongoing += 1;
            asyn_ares_c.ares_getaddrinfo(
                ares.channel,
                hostname,
                service_str,
                &hints,
                async_ares_AAAA_cb,
                a,
            );
        }

        if ((a.dns_queries & CURL_DNSQ_A) != 0) {
            var hints: ares_addrinfo_hints = .{
                .ai_family = PF_INET,
                .ai_socktype = socktype,
                .ai_flags = ARES_AI_NUMERICSERV,
            };
            if (Curl_vdns_trc_dns_is_verbose(data)) {
                Curl_trc_dns(data, "[A] ares: query records for %s", hostname);
            }
            a.queries_ongoing += 1;
            asyn_ares_c.ares_getaddrinfo(
                ares.channel,
                hostname,
                service_str,
                &hints,
                async_ares_A_cb,
                a,
            );
        }

        if (use_httpsrr and (a.dns_queries & CURL_DNSQ_HTTPS) != 0) {
            var https_name: ?[*:0]u8 = null;
            if (peer.port != 443) {
                https_name = asyn_ares_c.curl_maprintf("_%u._https.%s", @as(c_uint, peer.port), hostname);
                if (https_name == null) {
                    return CURLE_OUT_OF_MEMORY;
                }
            }
            const qname: [*:0]const u8 = if (https_name) |hn| hn else hostname;
            if (Curl_vdns_trc_dns_is_verbose(data)) {
                Curl_trc_dns(data, "[HTTPS] ares: query records for %s", qname);
            }
            a.queries_ongoing += 1;
            asyn_ares_c.ares_query(
                ares.channel,
                qname,
                @intCast(ARES_CLASS_IN),
                @intCast(ARES_REC_TYPE_HTTPS),
                async_ares_rr_query_cb,
                a,
            );
            mem.free(@ptrCast(https_name));
        }
    }

    ares.result = result;
    return if (result != CURLE_OK) result else (if (a.queries_ongoing != 0) CURLE_AGAIN else CURLE_OK);
}

comptime {
    if (use_ares) {
        @export(&Curl_async_ares_ver, .{ .name = "Curl_async_ares_ver" });
    }
    if (use_resolv_ares) {
        @export(&ares_global_init, .{ .name = "Curl_async_global_init" });
        @export(&ares_global_cleanup, .{ .name = "Curl_async_global_cleanup" });
        @export(&ares_shutdown, .{ .name = "Curl_async_ares_shutdown" });
        @export(&ares_destroy_fn, .{ .name = "Curl_async_ares_destroy" });
        @export(&ares_pollset_fn, .{ .name = "Curl_async_pollset" });
        @export(&ares_take_result_fn, .{ .name = "Curl_async_take_result" });
        @export(&ares_await_fn, .{ .name = "Curl_async_await" });
        @export(&ares_getaddrinfo_fn, .{ .name = "Curl_async_getaddrinfo" });
    }
}

// ============================================================================
// Unit Tests
// ============================================================================

test "Curl_httpsrr_set and Curl_httpsrr_print" {
    const raw = mem.calloc(1, @sizeOf(Curl_https_rrinfo)) orelse return error.OutOfMemory;
    const rr: *Curl_https_rrinfo = @ptrCast(@alignCast(raw));
    defer Curl_httpsrr_destroy(rr);

    rr.priority = 1;
    // Set ALPN: "\x02h2\x02h3"
    const alpn_wire = "\x02h2\x02h3";
    try std.testing.expectEqual(CURLE_OK, Curl_httpsrr_set(rr, HTTPS_RR_CODE_ALPN, alpn_wire.ptr, alpn_wire.len));
    try std.testing.expectEqual(@as(u8, @intCast(ALPN_h2)), rr.alpns[0]);
    try std.testing.expectEqual(@as(u8, @intCast(ALPN_h3)), rr.alpns[1]);
    try std.testing.expectEqual(@as(u8, @intCast(ALPN_none)), rr.alpns[2]);

    // Set PORT: 8443 (0x20fb)
    const port_wire = [_]u8{ 0x20, 0xfb };
    try std.testing.expectEqual(CURLE_OK, Curl_httpsrr_set(rr, HTTPS_RR_CODE_PORT, &port_wire, port_wire.len));
    try std.testing.expect(rr.portSet());
    try std.testing.expectEqual(@as(u16, 8443), rr.port);

    // Set NO_DEF_ALPN
    try std.testing.expectEqual(CURLE_OK, Curl_httpsrr_set(rr, HTTPS_RR_CODE_NO_DEF_ALPN, null, 0));
    try std.testing.expect(rr.noDefAlpn());

    // Set IPV4 hint: 127.0.0.1
    const ipv4_wire = [_]u8{ 127, 0, 0, 1 };
    try std.testing.expectEqual(CURLE_OK, Curl_httpsrr_set(rr, HTTPS_RR_CODE_IPV4, &ipv4_wire, ipv4_wire.len));
    try std.testing.expectEqual(@as(usize, 4), rr.ipv4hints_len);

    // Print and verify
    var dyn: containers.dynbuf = undefined;
    containers.curlx_dyn_init(&dyn, 1024);
    defer containers.curlx_dyn_free(&dyn);

    try std.testing.expectEqual(CURLE_OK, Curl_httpsrr_print(&dyn, rr));
    const printed = std.mem.span(containers.curlx_dyn_ptr(&dyn).?);
    try std.testing.expectEqualStrings("1 . alpn=h2,h3 port=8443 no-default-alpn ipv4hint=127.0.0.1", printed);
}

test "dnsc_id2key and dnsc_id_matches_entry" {
    var id: dnsc_id = undefined;
    var key: dnsc_key = undefined;

    curlx_parse.curlx_str_assign(&id.name, "ExAmPlE.CoM", 11);
    id.port = 443;
    id.type = CURL_DNST_ADDR;

    dnsc_id2key(&key, &id);
    try std.testing.expectEqual(@as(usize, 14), key.len);
    try std.testing.expectEqual(@as(u8, CURL_DNST_ADDR), key.data[0]);
    try std.testing.expectEqual(@as(u8, 1), key.data[1]);
    try std.testing.expectEqual(@as(u8, 0xbb), key.data[2]);
    try std.testing.expectEqualStrings("example.com", key.data[3..14]);

    var dns = dnsc_entry_create(&id, true);
    try std.testing.expect(dns != null);
    defer Curl_dns_entry_unlink(null, &dns);

    try std.testing.expect(dnsc_id_matches_entry(&id, dns));
    try std.testing.expect(dns.?.permanent());
    try std.testing.expectEqual(@as(u16, 443), dns.?.port);
    try std.testing.expectEqualStrings("ExAmPlE.CoM", std.mem.span(dns.?.hostnamePtr()));
}

test "Curl_dnscache_init and Curl_dnscache_destroy" {
    var cache: Curl_dnscache = undefined;
    Curl_dnscache_init(&cache, 7);
    try std.testing.expectEqual(@as(usize, 0), Curl_hash_count(&cache.entries));
    Curl_dnscache_destroy(&cache);
}

test "async_ares_node2addr deduplicates and converts ares_addrinfo_node" {
    var sa1: [16]u8 = @splat(0);
    sa1[0] = 2; // AF_INET
    sa1[2] = 0x01;
    sa1[3] = 0xbb; // 443
    sa1[4] = 127;
    sa1[5] = 0;
    sa1[6] = 0;
    sa1[7] = 1;

    var node2: ares_addrinfo_node = .{
        .ai_ttl = 60,
        .ai_flags = 0,
        .ai_family = AF_INET,
        .ai_socktype = vdns_cfilters.SOCK_STREAM,
        .ai_protocol = 6,
        .ai_addrlen = 16,
        .ai_addr = &sa1,
        .ai_next = null,
    };
    var node1: ares_addrinfo_node = .{
        .ai_ttl = 60,
        .ai_flags = 0,
        .ai_family = AF_INET,
        .ai_socktype = vdns_cfilters.SOCK_STREAM,
        .ai_protocol = 6,
        .ai_addrlen = 16,
        .ai_addr = &sa1,
        .ai_next = &node2,
    };

    const ca = async_ares_node2addr(&node1);
    try std.testing.expect(ca != null);
    defer Curl_freeaddrinfo(ca);
    try std.testing.expectEqual(AF_INET, ca.?.ai_family);
    try std.testing.expect(ca.?.ai_next == null);
}

test "Curl_httpsrr_from_ares decodes c-ares HTTPS DNS record" {
    if (use_ares and use_httpsrr) {
        const ares_test_c = struct {
            extern fn ares_dns_record_create(
                dnsrec: *?*anyopaque,
                id: u16,
                flags: u16,
                opcode: c_uint,
                rcode: c_uint,
            ) callconv(.c) c_int;
            extern fn ares_dns_record_destroy(dnsrec: ?*anyopaque) callconv(.c) void;
            extern fn ares_dns_record_rr_add(
                rr_out: *?*anyopaque,
                dnsrec: ?*anyopaque,
                sect: c_uint,
                name: [*:0]const u8,
                rec_type: c_uint,
                rclass: c_uint,
                ttl: c_uint,
            ) callconv(.c) c_int;
            extern fn ares_dns_rr_set_u16(dns_rr: ?*anyopaque, key: c_uint, val: u16) callconv(.c) c_int;
            extern fn ares_dns_rr_set_str(dns_rr: ?*anyopaque, key: c_uint, val: [*:0]const u8) callconv(.c) c_int;
            extern fn ares_dns_rr_set_opt(
                dns_rr: ?*anyopaque,
                key: c_uint,
                opt: u16,
                val: ?[*]const u8,
                val_len: usize,
            ) callconv(.c) c_int;
        };

        var dnsrec: ?*anyopaque = null;
        try std.testing.expectEqual(@as(c_int, 0), ares_test_c.ares_dns_record_create(&dnsrec, 1, 0, 0, 0));
        defer ares_test_c.ares_dns_record_destroy(dnsrec);

        var rr: ?*anyopaque = null;
        try std.testing.expectEqual(
            @as(c_int, 0),
            ares_test_c.ares_dns_record_rr_add(
                &rr,
                dnsrec,
                ARES_SECTION_ANSWER,
                "example.com",
                ARES_REC_TYPE_HTTPS,
                ARES_CLASS_IN,
                300,
            ),
        );
        try std.testing.expectEqual(@as(c_int, 0), ares_test_c.ares_dns_rr_set_u16(rr, ARES_RR_HTTPS_PRIORITY, 1));
        try std.testing.expectEqual(@as(c_int, 0), ares_test_c.ares_dns_rr_set_str(rr, ARES_RR_HTTPS_TARGET, "."));

        const alpn_wire = "\x02h2\x02h3";
        try std.testing.expectEqual(
            @as(c_int, 0),
            ares_test_c.ares_dns_rr_set_opt(rr, ARES_RR_HTTPS_PARAMS, HTTPS_RR_CODE_ALPN, alpn_wire.ptr, alpn_wire.len),
        );
        const port_wire = [_]u8{ 0x20, 0xfb };
        try std.testing.expectEqual(
            @as(c_int, 0),
            ares_test_c.ares_dns_rr_set_opt(rr, ARES_RR_HTTPS_PARAMS, HTTPS_RR_CODE_PORT, &port_wire, port_wire.len),
        );

        var hinfo: ?*Curl_https_rrinfo = null;
        try std.testing.expectEqual(CURLE_OK, Curl_httpsrr_from_ares(dnsrec, &hinfo));
        try std.testing.expect(hinfo != null);
        defer Curl_httpsrr_destroy(hinfo);

        try std.testing.expectEqual(@as(u16, 1), hinfo.?.priority);
        try std.testing.expectEqualStrings(".", std.mem.span(hinfo.?.target.?));
        try std.testing.expectEqual(@as(u8, @intCast(ALPN_h2)), hinfo.?.alpns[0]);
        try std.testing.expectEqual(@as(u8, @intCast(ALPN_h3)), hinfo.?.alpns[1]);
        try std.testing.expect(hinfo.?.portSet());
        try std.testing.expectEqual(@as(u16, 8443), hinfo.?.port);
    }
}

test "Curl_httpsrr_set resets lengths before replacement failure and Curl_httpsrr_destroy scrubs ECH" {
    const raw = mem.calloc(1, @sizeOf(Curl_https_rrinfo)) orelse return error.OutOfMemory;
    const rr: *Curl_https_rrinfo = @ptrCast(@alignCast(raw));
    defer Curl_httpsrr_destroy(rr);

    const ipv4_wire = [_]u8{ 192, 0, 2, 1 };
    const ech_wire = [_]u8{ 0xfe, 0x0d, 0x00, 0x10, 0xaa, 0xbb, 0xcc, 0xdd };
    var ipv6_wire: [16]u8 = @splat(0x20);
    ipv6_wire[15] = 1;

    try std.testing.expectEqual(CURLE_OK, Curl_httpsrr_set(rr, HTTPS_RR_CODE_IPV4, &ipv4_wire, ipv4_wire.len));
    try std.testing.expect(rr.ipv4hints != null);
    try std.testing.expectEqual(@as(usize, 4), rr.ipv4hints_len);

    try std.testing.expectEqual(CURLE_OK, Curl_httpsrr_set(rr, HTTPS_RR_CODE_ECH, &ech_wire, ech_wire.len));
    try std.testing.expect(rr.echconfiglist != null);
    try std.testing.expectEqual(@as(usize, 8), rr.echconfiglist_len);

    try std.testing.expectEqual(CURLE_OK, Curl_httpsrr_set(rr, HTTPS_RR_CODE_IPV6, &ipv6_wire, ipv6_wire.len));
    try std.testing.expect(rr.ipv6hints != null);
    try std.testing.expectEqual(@as(usize, 16), rr.ipv6hints_len);

    // Passing null val with valid non-zero length simulates memdupBytes allocation failure
    // after freeing the old buffer; pointer and length must both be reset to null / 0.
    try std.testing.expectEqual(CURLE_OUT_OF_MEMORY, Curl_httpsrr_set(rr, HTTPS_RR_CODE_IPV4, null, 4));
    try std.testing.expect(rr.ipv4hints == null);
    try std.testing.expectEqual(@as(usize, 0), rr.ipv4hints_len);

    try std.testing.expectEqual(CURLE_OUT_OF_MEMORY, Curl_httpsrr_set(rr, HTTPS_RR_CODE_ECH, null, 8));
    try std.testing.expect(rr.echconfiglist == null);
    try std.testing.expectEqual(@as(usize, 0), rr.echconfiglist_len);

    try std.testing.expectEqual(CURLE_OUT_OF_MEMORY, Curl_httpsrr_set(rr, HTTPS_RR_CODE_IPV6, null, 16));
    try std.testing.expect(rr.ipv6hints == null);
    try std.testing.expectEqual(@as(usize, 0), rr.ipv6hints_len);

    // Re-populate ECH so Curl_httpsrr_destroy scrubs echconfiglist and poisons rrinfo
    try std.testing.expectEqual(CURLE_OK, Curl_httpsrr_set(rr, HTTPS_RR_CODE_ECH, &ech_wire, ech_wire.len));
}
