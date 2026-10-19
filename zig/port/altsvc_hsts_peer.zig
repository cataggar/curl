const std = @import("std");
const builtin = @import("builtin");
const mem = @import("mem.zig");
const primitives = @import("primitives.zig");
const containers_mod = @import("containers.zig");
const curlx_parse_mod = @import("curlx_parse.zig");
const curlx_time_net = @import("curlx_time_net.zig");
const os_leaf = @import("os_leaf.zig");
const urlapi = @import("urlapi.zig");

const Curl_str = curlx_parse_mod.Curl_str;

const containers = struct {
    pub const Curl_llist = containers_mod.Curl_llist;
    pub const Curl_llist_node = containers_mod.Curl_llist_node;
    pub const Curl_llist_dtor = containers_mod.Curl_llist_dtor;
    pub const curl_slist = containers_mod.curl_slist;
    pub const dynbuf = containers_mod.dynbuf;

    pub extern fn Curl_llist_init(l: *Curl_llist, dtor: ?Curl_llist_dtor) callconv(.c) void;
    pub extern fn Curl_llist_append(list: *Curl_llist, p: ?*const anyopaque, ne: *Curl_llist_node) callconv(.c) void;
    pub extern fn Curl_llist_head(list: *const Curl_llist) callconv(.c) ?*Curl_llist_node;
    pub extern fn Curl_llist_count(list: *const Curl_llist) callconv(.c) usize;
    pub extern fn Curl_node_elem(n: *const Curl_llist_node) callconv(.c) ?*anyopaque;
    pub extern fn Curl_node_next(n: *const Curl_llist_node) callconv(.c) ?*Curl_llist_node;
    pub extern fn Curl_node_remove(e: ?*Curl_llist_node) callconv(.c) void;
    pub extern fn curlx_dyn_init(s: *dynbuf, toobig: usize) callconv(.c) void;
    pub extern fn curlx_dyn_free(s: *dynbuf) callconv(.c) void;
    pub extern fn curlx_dyn_ptr(s: *const dynbuf) callconv(.c) ?[*:0]u8;
};

const curlx_parse = struct {
    pub const STRE_OVERFLOW = curlx_parse_mod.STRE_OVERFLOW;
    pub const curlx_parsedate = curlx_parse_mod.curlx_parsedate;

    pub extern fn curlx_str_assign(out: *Curl_str, str: [*]const u8, len: usize) callconv(.c) void;
    pub extern fn curlx_str_until(linep: *?[*:0]const u8, out: *Curl_str, max: usize, delim: u8) callconv(.c) c_int;
    pub extern fn curlx_str_word(linep: *?[*:0]const u8, out: *Curl_str, max: usize) callconv(.c) c_int;
    pub extern fn curlx_str_quotedword(linep: *?[*:0]const u8, out: *Curl_str, max: usize) callconv(.c) c_int;
    pub extern fn curlx_str_single(linep: *?[*:0]const u8, byte: u8) callconv(.c) c_int;
    pub extern fn curlx_str_singlespace(linep: *?[*:0]const u8) callconv(.c) c_int;
    pub extern fn curlx_str_number(linep: *?[*:0]const u8, nump: *i64, max: i64) callconv(.c) c_int;
    pub extern fn curlx_str_newline(linep: *?[*:0]const u8) callconv(.c) c_int;
    pub extern fn curlx_str_casecompare(str: *Curl_str, check: ?[*:0]const u8) callconv(.c) c_int;
    pub extern fn curlx_str_cspn(linep: *?[*:0]const u8, out: *Curl_str, reject: [*:0]const u8) callconv(.c) c_int;
    pub extern fn curlx_str_trimblanks(out: *Curl_str) callconv(.c) void;
    pub extern fn curlx_str_passblanks(linep: *?[*:0]const u8) callconv(.c) void;
};
const time_t = curlx_time_net.time_t;
const TIME_T_MAX: time_t = std.math.maxInt(time_t);
const CURL_OFF_T_MAX: i64 = std.math.maxInt(i64);

pub const CURLE_OK: c_uint = 0;
pub const CURLE_UNSUPPORTED_PROTOCOL: c_uint = 1;
pub const CURLE_FAILED_INIT: c_uint = 2;
pub const CURLE_URL_MALFORMAT: c_uint = 3;
pub const CURLE_NOT_BUILT_IN: c_uint = 4;
pub const CURLE_COULDNT_RESOLVE_PROXY: c_uint = 5;
pub const CURLE_COULDNT_CONNECT: c_uint = 7;
pub const CURLE_WRITE_ERROR: c_uint = 23;
pub const CURLE_OUT_OF_MEMORY: c_uint = 27;
pub const CURLE_ABORTED_BY_CALLBACK: c_uint = 42;
pub const CURLE_BAD_FUNCTION_ARGUMENT: c_uint = 43;
pub const CURLE_AGAIN: c_uint = 81;
pub const CURLE_SETOPT_OPTION_SYNTAX: c_uint = 98;

pub const CURLM_OK: c_int = 0;
pub const CURLM_OUT_OF_MEMORY: c_int = 3;
pub const CURLM_UNKNOWN_OPTION: c_int = 6;
pub const CURLM_BAD_FUNCTION_ARGUMENT: c_int = 10;

pub const CURLALTSVC_READONLYFILE: c_long = 1 << 2;
pub const CURLALTSVC_H1: c_long = 1 << 3;
pub const CURLALTSVC_H2: c_long = 1 << 4;
pub const CURLALTSVC_H3: c_long = 1 << 5;

pub const ALPN_none: c_uint = 0;
pub const ALPN_h1: c_uint = 1 << 3;
pub const ALPN_h2: c_uint = 1 << 4;
pub const ALPN_h3: c_uint = 1 << 5;

pub const CURLHSTS_ENABLE: c_uint = 1 << 0;
pub const CURLHSTS_READONLYFILE: c_uint = 1 << 1;

pub const CURLSTS_OK: c_uint = 0;
pub const CURLSTS_DONE: c_uint = 1;
pub const CURLSTS_FAIL: c_uint = 2;

pub const CURL_LOCK_DATA_HSTS: c_uint = 7;
pub const CURL_LOCK_ACCESS_SINGLE: c_uint = 2;

pub const CURLPROXY_HTTP: u8 = 0;
pub const CURLPROXY_HTTP_1_0: u8 = 1;
pub const CURLPROXY_HTTPS: u8 = 2;
pub const CURLPROXY_HTTPS2: u8 = 3;
pub const CURLPROXY_SOCKS4: u8 = 4;
pub const CURLPROXY_SOCKS5: u8 = 5;
pub const CURLPROXY_SOCKS4A: u8 = 6;
pub const CURLPROXY_SOCKS5_HOSTNAME: u8 = 7;
pub const CURLPROXY_HTTPS3: u8 = 8;

pub const CURL_DEFAULT_PROXY_PORT: u16 = 1080;
pub const SSLSUPP_HTTPS_PROXY: c_uint = 1 << 4;

pub const PROTOPT_SSL: u32 = 1 << 0;
pub const PROTOPT_NONETWORK: u32 = 1 << 4;

pub const CURLPROTO_HTTP: i64 = 1 << 0;
pub const CURLPROTO_SOCKS: i64 = 1 << 33;

pub const MAX_IPADR_LEN: usize = 46;
pub const MAX_URL_LEN: usize = 0xffff;

pub const TRNSPRT_TCP: u8 = 3;
pub const TRNSPRT_UDP: u8 = 4;
pub const TRNSPRT_QUIC: u8 = 5;

pub const FIRSTSOCKET: i8 = 0;
pub const SECONDARYSOCKET: i8 = 1;

pub const CURL_CF_SSL_DEFAULT: c_int = -1;
pub const CURL_CF_SSL_DISABLE: c_int = 0;
pub const CURL_CF_SSL_ENABLE: c_int = 1;

pub const CF_TYPE_SETUP: c_int = 1 << 5;
pub const CURL_LOG_LVL_NONE: c_int = 0;

pub const CURLMNOTIFY_INFO_READ: c_uint = 0;
pub const CURLMNOTIFY_EASY_DONE: c_uint = 1;
pub const CURLMNOTIFY_LAST: c_uint = 2;
pub const CURL_MNTFY_FLAG_HAS_ENTRIES: u32 = @as(u32, 1) << 31;

const CURL_VERSION_HTTP2: c_int = 1 << 16;
const CURL_VERSION_HTTP3: c_int = 1 << 25;

const CurlVersionInfoData = extern struct {
    age: c_int,
    version: ?[*:0]const u8,
    version_num: c_uint,
    host: ?[*:0]const u8,
    features: c_int,
};

const Tm = extern struct {
    tm_sec: c_int,
    tm_min: c_int,
    tm_hour: c_int,
    tm_mday: c_int,
    tm_mon: c_int,
    tm_year: c_int,
    tm_wday: c_int,
    tm_yday: c_int,
    tm_isdst: c_int,
    _extra: [32]u8 = undefined,
};

extern fn curl_version_info(stamp: c_int) callconv(.c) ?*const CurlVersionInfoData;
extern fn Curl_alpn2alpnid(name: [*]const u8, len: usize) callconv(.c) c_uint;
extern fn Curl_getdate_capped(p: [*:0]const u8, output: *time_t) callconv(.c) c_int;
extern fn Curl_fopen(data: ?*anyopaque, filename: [*:0]const u8, fh: *?*anyopaque, tempstore: *?[*:0]u8) callconv(.c) c_uint;
extern fn curl_mfprintf(fd: ?*anyopaque, format: [*:0]const u8, ...) callconv(.c) c_int;
extern fn curl_msnprintf(buffer: [*]u8, maxlength: usize, format: [*:0]const u8, ...) callconv(.c) c_int;
extern fn Curl_infof(data: ?*anyopaque, fmt: [*:0]const u8, ...) callconv(.c) void;
extern fn Curl_failf(data: ?*anyopaque, fmt: [*:0]const u8, ...) callconv(.c) void;
inline fn Curl_trc_cf_is_verbose(cf: *const CurlCfilter, data: ?*anyopaque) bool {
    return data != null and cf.cft.log_level >= 1;
}
extern fn Curl_trc_cf_infof(data: ?*anyopaque, cf: ?*const CurlCfilter, fmt: [*:0]const u8, ...) callconv(.c) void;
extern fn Curl_conn_trc_filters(data: ?*anyopaque, sockindex: i8, info: [*:0]const u8) callconv(.c) void;
extern fn Curl_host_is_ipnum(hostname: [*:0]const u8) callconv(.c) bool;
extern fn Curl_share_lock(data: ?*anyopaque, ltype: c_uint, accesstype: c_uint) callconv(.c) c_uint;
extern fn Curl_share_unlock(data: ?*anyopaque, ltype: c_uint) callconv(.c) c_uint;
extern fn Curl_looks_like_ipv6(s: [*]const u8, len: usize, maybe_url_encoded: bool, phost: *Curl_str, pzoneid: *Curl_str) callconv(.c) bool;
extern fn Curl_is_ipv4addr(address: [*:0]const u8) callconv(.c) bool;
extern fn Curl_uc_to_curlcode(uc: urlapi.CURLUcode) callconv(.c) c_uint;
extern fn Curl_get_scheme(scheme: [*:0]const u8) callconv(.c) ?*const CurlScheme;
extern fn Curl_ssl_supports(data: ?*anyopaque, ssl_option: c_uint) callconv(.c) bool;

extern const Curl_scheme_http: CurlScheme;
extern const Curl_scheme_https: CurlScheme;
extern const Curl_scheme_socks4: CurlScheme;
extern const Curl_scheme_socks4a: CurlScheme;
extern const Curl_scheme_socks5: CurlScheme;
extern const Curl_scheme_socks5h: CurlScheme;

extern "c" fn fopen(pathname: [*:0]const u8, mode: [*:0]const u8) ?*anyopaque;
extern "c" fn fclose(stream: ?*anyopaque) c_int;
extern "c" fn fputs(s: [*:0]const u8, stream: ?*anyopaque) c_int;
extern "c" fn rename(oldpath: [*:0]const u8, newpath: [*:0]const u8) c_int;
extern "c" fn unlink(pathname: [*:0]const u8) c_int;

const posix_c = struct {
    extern "c" fn time(tloc: ?*time_t) time_t;
    extern "c" fn fileno(stream: ?*anyopaque) c_int;
    extern "c" fn if_nametoindex(ifname: [*:0]const u8) c_uint;
};

const win_c = struct {
    extern "c" fn _time64(timer: ?*i64) i64;
    extern fn curlx_win32_fopen(filename: ?[*:0]const u8, mode: ?[*:0]const u8) callconv(.c) ?*anyopaque;
    extern fn curlx_win32_rename(oldpath: ?[*:0]const u8, newpath: ?[*:0]const u8) callconv(.c) c_int;
};

fn nowTime() time_t {
    if (builtin.os.tag == .windows) {
        return win_c._time64(null);
    } else {
        return posix_c.time(null);
    }
}

fn curlxFopenReadText(file: [*:0]const u8) ?*anyopaque {
    if (builtin.os.tag == .windows) {
        return win_c.curlx_win32_fopen(file, "rt");
    } else {
        return fopen(file, "r");
    }
}

fn curlxRename(oldpath: [*:0]const u8, newpath: [*:0]const u8) c_int {
    if (builtin.os.tag == .windows) {
        return win_c.curlx_win32_rename(oldpath, newpath);
    } else {
        return rename(oldpath, newpath);
    }
}

fn isFpNotDir(fp: ?*anyopaque) bool {
    if (builtin.os.tag == .windows) {
        return true;
    } else if (builtin.os.tag == .linux) {
        var stx: std.os.linux.Statx = undefined;
        const fd = posix_c.fileno(fp);
        const rc = std.os.linux.statx(fd, "", std.os.linux.AT.EMPTY_PATH, .{ .TYPE = true }, &stx);
        if (std.os.linux.errno(rc) != .SUCCESS) return true;
        return !std.os.linux.S.ISDIR(stx.mode);
    } else {
        var st: std.c.Stat = undefined;
        const fd = posix_c.fileno(fp);
        if (std.c.fstat(fd, &st) == -1) return true;
        return !std.c.S.ISDIR(st.mode);
    }
}

// ============================================================================
// 1. lib/peer.c — SSL / Connection Peer Identity
// ============================================================================

pub const CurlScheme = extern struct {
    name: ?[*:0]const u8,
    run: ?*const anyopaque,
    protocol: i64,
    family: i64,
    flags: u32,
    defport: u16,
};

pub const CurlPeer = if (builtin.os.tag == .windows) extern struct {
    scheme: ?*const CurlScheme,
    hostname: [*:0]u8,
    zoneid: ?[*:0]u8,
    refcount: u32,
    scopeid: u32,
    port: u16,
    _pad: u16 = 0,
    flags: u32,
    user_hostname: [1]u8,

    pub fn unixSocket(self: *const CurlPeer) bool {
        return (self.flags & 1) != 0;
    }
    pub fn setUnixSocket(self: *CurlPeer, v: bool) void {
        if (v) self.flags |= 1 else self.flags &= ~@as(u32, 1);
    }
    pub fn abstractUds(self: *const CurlPeer) bool {
        return (self.flags & 2) != 0;
    }
    pub fn setAbstractUds(self: *CurlPeer, v: bool) void {
        if (v) self.flags |= 2 else self.flags &= ~@as(u32, 2);
    }
    pub fn ipv6(self: *const CurlPeer) bool {
        return (self.flags & 4) != 0;
    }
    pub fn setIpv6(self: *CurlPeer, v: bool) void {
        if (v) self.flags |= 4 else self.flags &= ~@as(u32, 4);
    }
} else extern struct {
    scheme: ?*const CurlScheme,
    hostname: [*:0]u8,
    zoneid: ?[*:0]u8,
    refcount: u32,
    scopeid: u32,
    port: u16,
    flags: u8,
    user_hostname: [1]u8,

    pub fn unixSocket(self: *const CurlPeer) bool {
        return (self.flags & 1) != 0;
    }
    pub fn setUnixSocket(self: *CurlPeer, v: bool) void {
        if (v) self.flags |= 1 else self.flags &= ~@as(u8, 1);
    }
    pub fn abstractUds(self: *const CurlPeer) bool {
        return (self.flags & 2) != 0;
    }
    pub fn setAbstractUds(self: *CurlPeer, v: bool) void {
        if (v) self.flags |= 2 else self.flags &= ~@as(u8, 2);
    }
    pub fn ipv6(self: *const CurlPeer) bool {
        return (self.flags & 4) != 0;
    }
    pub fn setIpv6(self: *CurlPeer, v: bool) void {
        if (v) self.flags |= 4 else self.flags &= ~@as(u8, 4);
    }
};

const PeerParse = struct {
    scheme: ?*const CurlScheme = null,
    host_user: Curl_str = .{ .str = null, .len = 0 },
    host: Curl_str = .{ .str = null, .len = 0 },
    zoneid: Curl_str = .{ .str = null, .len = 0 },
    tmp_host_user: ?[*:0]u8 = null,
    tmp_host: ?[*:0]u8 = null,
    tmp_zoneid: ?[*:0]u8 = null,
    scopeid: u32 = 0,
    port: u16 = 0,
    ipv6: bool = false,
    unix_socket: bool = false,
    abstract_uds: bool = false,
};

fn peerParseClear(pp: *PeerParse) void {
    mem.free(pp.tmp_host_user);
    mem.free(pp.tmp_host);
    mem.free(pp.tmp_zoneid);
    pp.* = .{};
}

fn peerCreate(pp: *PeerParse, ppeer: *?*CurlPeer) c_uint {
    const scheme = pp.scheme orelse return CURLE_FAILED_INIT;
    if (pp.host.len == 0 and (scheme.flags & PROTOPT_NONETWORK) == 0) {
        return CURLE_FAILED_INIT;
    }

    var host_alen: usize = 0;
    if (pp.host.str != pp.host_user.str or pp.host.len != pp.host_user.len) {
        host_alen = pp.host.len + 1;
    }
    const zone_alen: usize = if (pp.zoneid.len != 0) pp.zoneid.len + 1 else 0;

    const total_size = @sizeOf(CurlPeer) + pp.host_user.len + host_alen + zone_alen;
    const raw = mem.calloc(1, total_size) orelse return CURLE_OUT_OF_MEMORY;
    const peer: *CurlPeer = @ptrCast(@alignCast(raw));

    const user_host_base: [*]u8 = @ptrCast(&peer.user_hostname);

    peer.refcount = 1;
    peer.scheme = scheme;
    peer.hostname = @ptrCast(user_host_base);
    peer.port = pp.port;
    peer.scopeid = pp.scopeid;
    peer.setIpv6(pp.ipv6);
    peer.setUnixSocket(pp.unix_socket);
    peer.setAbstractUds(pp.abstract_uds);

    if (pp.host_user.len != 0) {
        if (pp.host_user.str) |s| {
            @memcpy(user_host_base[0..pp.host_user.len], s[0..pp.host_user.len]);
        }
    }

    if (host_alen != 0) {
        const host_dst = user_host_base + pp.host_user.len + 1;
        peer.hostname = @ptrCast(host_dst);
        if (pp.host.str) |s| {
            @memcpy(host_dst[0..pp.host.len], s[0..pp.host.len]);
        }
    }

    if (zone_alen != 0) {
        const zone_dst = user_host_base + pp.host_user.len + 1 + host_alen;
        peer.zoneid = @ptrCast(zone_dst);
        if (pp.zoneid.str) |s| {
            @memcpy(zone_dst[0..pp.zoneid.len], s[0..pp.zoneid.len]);
        }
        if (peer.scopeid == 0) {
            const z: [*:0]const u8 = peer.zoneid.?;
            var p: ?[*:0]const u8 = z;
            var scope: i64 = 0;
            if (curlx_parse.curlx_str_number(&p, &scope, std.math.maxInt(c_uint)) == 0 and p != null and p.?[0] == 0) {
                peer.scopeid = @intCast(scope);
            } else if (builtin.os.tag != .windows) {
                const idx = posix_c.if_nametoindex(z);
                if (idx != 0) {
                    peer.scopeid = idx;
                }
            }
        }
    }

    ppeer.* = peer;
    return CURLE_OK;
}

fn peerParseHost(data: ?*anyopaque, pp: *PeerParse, scan_for_ipv6: bool) c_uint {
    const hu_str = pp.host_user.str orelse return CURLE_FAILED_INIT;
    if (pp.host_user.len == 0) return CURLE_FAILED_INIT;

    if (hu_str[0] == '[') {
        var s: ?[*:0]const u8 = @ptrCast(hu_str + 1);
        var tmp: Curl_str = .{ .str = null, .len = 0 };
        if (curlx_parse.curlx_str_until(&s, &tmp, pp.host_user.len - 1, ']') != 0) {
            return CURLE_URL_MALFORMAT;
        }
        const tmp_ptr = tmp.str orelse return CURLE_URL_MALFORMAT;
        if (!Curl_looks_like_ipv6(tmp_ptr, tmp.len, true, &pp.host, &pp.zoneid)) {
            Curl_failf(data, "Invalid IPv6 address format in '%.*s'", @as(c_int, @intCast(pp.host_user.len)), hu_str);
            return CURLE_URL_MALFORMAT;
        }
        pp.ipv6 = true;
    } else if (scan_for_ipv6 and Curl_looks_like_ipv6(hu_str, pp.host_user.len, true, &pp.host, &pp.zoneid)) {
        if (pp.host_user.len < MAX_IPADR_LEN) {
            var tmp: [MAX_IPADR_LEN]u8 = undefined;
            @memcpy(tmp[0..pp.host_user.len], hu_str[0..pp.host_user.len]);
            tmp[pp.host_user.len] = 0;
            pp.ipv6 = !Curl_is_ipv4addr(@ptrCast(&tmp));
        } else {
            pp.ipv6 = true;
        }
    } else {
        pp.host = pp.host_user;
    }
    return CURLE_OK;
}

pub export fn Curl_peer_create(
    data: ?*anyopaque,
    scheme: ?*const CurlScheme,
    hostname: [*:0]const u8,
    port: u16,
    ppeer: *?*CurlPeer,
) callconv(.c) c_uint {
    var pp: PeerParse = .{};
    Curl_peer_unlink(ppeer);
    pp.scheme = scheme;
    pp.host_user.str = hostname;
    pp.host_user.len = std.mem.len(hostname);
    pp.port = port;

    var result = peerParseHost(data, &pp, true);
    if (result == CURLE_OK) {
        result = peerCreate(&pp, ppeer);
    }
    peerParseClear(&pp);
    return result;
}

pub export fn Curl_peer_uds_create(
    scheme: ?*const CurlScheme,
    path: ?[*:0]const u8,
    abstract_unix_socket: bool,
    ppeer: *?*CurlPeer,
) callconv(.c) c_uint {
    var pp: PeerParse = .{};
    Curl_peer_unlink(ppeer);
    const p = path orelse return CURLE_FAILED_INIT;
    const pathlen = std.mem.len(p);
    if (scheme == null or pathlen == 0) return CURLE_FAILED_INIT;

    pp.scheme = scheme;
    pp.host_user.str = p;
    pp.host_user.len = pathlen;
    pp.host.str = p;
    pp.host.len = pathlen;
    pp.unix_socket = true;
    pp.abstract_uds = abstract_unix_socket;

    const result = peerCreate(&pp, ppeer);
    peerParseClear(&pp);
    return result;
}

pub export fn Curl_peer_link(pdest: *?*CurlPeer, src: ?*CurlPeer) callconv(.c) void {
    if (pdest.* != src) {
        Curl_peer_unlink(pdest);
        pdest.* = src;
        if (src) |s| {
            s.refcount += 1;
        }
    }
}

pub export fn Curl_peer_unlink(ppeer: *?*CurlPeer) callconv(.c) void {
    if (ppeer.*) |peer| {
        ppeer.* = null;
        if (peer.refcount != 0) {
            peer.refcount -= 1;
        }
        if (peer.refcount == 0) {
            mem.free(peer);
        }
    }
}

fn peerSameHostname(p1: *const CurlPeer, p2: *const CurlPeer) bool {
    if (p1.unixSocket() != p2.unixSocket() or
        p1.abstractUds() != p2.abstractUds() or
        p1.ipv6() != p2.ipv6())
    {
        return false;
    }
    const h1 = std.mem.span(p1.hostname);
    const h2 = std.mem.span(p2.hostname);
    if (std.mem.eql(u8, h1, h2)) return true;
    if (!p1.unixSocket() and primitives.curl_strequal(p1.hostname, p2.hostname) != 0) return true;
    return false;
}

fn peerSameZoneid(z1: ?[*:0]const u8, z2: ?[*:0]const u8) bool {
    if (z1 == z2) return true;
    if (z1 != null and z2 != null) {
        return std.mem.eql(u8, std.mem.span(z1.?), std.mem.span(z2.?));
    }
    return false;
}

pub export fn Curl_peer_same_destination(p1_opt: ?*const CurlPeer, p2_opt: ?*const CurlPeer) callconv(.c) bool {
    if (p1_opt == p2_opt) return true;
    const p1 = p1_opt orelse return false;
    const p2 = p2_opt orelse return false;
    return (p1.port == p2.port) and
        peerSameHostname(p1, p2) and
        (p1.scopeid == p2.scopeid) and
        (p1.scopeid != 0 or peerSameZoneid(p1.zoneid, p2.zoneid));
}

pub export fn Curl_peer_equal(p1_opt: ?*const CurlPeer, p2_opt: ?*const CurlPeer) callconv(.c) bool {
    if (p1_opt == p2_opt) return true;
    const p1 = p1_opt orelse return false;
    const p2 = p2_opt orelse return false;
    return (p1.scheme == p2.scheme) and Curl_peer_same_destination(p1, p2);
}

pub export fn Curl_peer_from_url(
    uh: *urlapi.Curl_URL,
    data: ?*anyopaque,
    port_override: u16,
    scopeid_override: u32,
    is_a_follow: bool,
    ppeer: *?*CurlPeer,
) callconv(.c) c_uint {
    var pp: PeerParse = .{};
    var zoneid: ?[*:0]u8 = null;
    var scheme: ?[*:0]u8 = null;
    var hostname: ?[*:0]u8 = null;
    var result: c_uint = CURLE_OK;

    Curl_peer_unlink(ppeer);

    var uc = urlapi.curl_url_get(uh, .CURLUPART_SCHEME, &scheme, 0);
    if (uc != .CURLUE_OK) {
        return Curl_uc_to_curlcode(uc);
    }
    defer {
        peerParseClear(&pp);
        mem.free(scheme);
        mem.free(hostname);
        mem.free(zoneid);
    }

    pp.scheme = if (scheme) |s| Curl_get_scheme(s) else null;
    if (pp.scheme == null) {
        const redirect_suffix: [*:0]const u8 = if (is_a_follow) " (in redirect)" else "";
        Curl_failf(data, "Protocol \"%s\" not supported%s", scheme.?, redirect_suffix);
        return CURLE_UNSUPPORTED_PROTOCOL;
    }

    uc = urlapi.curl_url_get(uh, .CURLUPART_HOST, &hostname, 0);
    if (uc != .CURLUE_OK) {
        if (uc == .CURLUE_NO_HOST and (pp.scheme.?.flags & PROTOPT_NONETWORK) != 0) {
            // acceptable
        } else {
            return CURLE_OUT_OF_MEMORY;
        }
    } else if (hostname != null and std.mem.len(hostname.?) > MAX_URL_LEN) {
        Curl_failf(data, "Too long hostname (maximum is %d)", @as(c_int, MAX_URL_LEN));
        return CURLE_URL_MALFORMAT;
    }

    const host_cstr: [*:0]const u8 = if (hostname) |h| h else "";
    pp.host_user.str = host_cstr;
    pp.host_user.len = std.mem.len(host_cstr);
    if (pp.host_user.len != 0) {
        result = peerParseHost(data, &pp, false);
        if (result != CURLE_OK) return result;
    } else {
        pp.host = pp.host_user;
    }

    if (port_override != 0) {
        var portbuf: [16]u8 = undefined;
        _ = curl_msnprintf(&portbuf, portbuf.len, "%d", @as(c_int, port_override));
        uc = urlapi.curl_url_set(uh, .CURLUPART_PORT, @ptrCast(&portbuf), 0);
        if (uc != .CURLUE_OK) {
            return CURLE_OUT_OF_MEMORY;
        }
        pp.port = port_override;
    } else {
        uc = urlapi.Curl_url_get_port(uh, &pp.port);
        if (uc != .CURLUE_OK) {
            if (uc == .CURLUE_OUT_OF_MEMORY) {
                return CURLE_OUT_OF_MEMORY;
            } else if ((pp.scheme.?.flags & PROTOPT_NONETWORK) == 0) {
                return CURLE_URL_MALFORMAT;
            }
        }
    }

    if (scopeid_override != 0) {
        pp.scopeid = scopeid_override;
    } else {
        if (urlapi.curl_url_get(uh, .CURLUPART_ZONEID, &zoneid, 0) == .CURLUE_OUT_OF_MEMORY) {
            return CURLE_OUT_OF_MEMORY;
        }
        if (zoneid) |z| {
            pp.zoneid.str = z;
            pp.zoneid.len = std.mem.len(z);
        }
    }

    result = peerCreate(&pp, ppeer);
    if (result != CURLE_OK) {
        Curl_failf(data, "Error %d creating peer for %s:%u", @as(c_int, @intCast(result)), pp.host_user.str.?, @as(c_uint, pp.port));
    }
    return result;
}

pub export fn Curl_peer_from_connect_to(
    data: ?*anyopaque,
    dest: *const CurlPeer,
    connect_to_opt: ?[*:0]const u8,
    ppeer: *?*CurlPeer,
) callconv(.c) c_uint {
    var pp: PeerParse = .{};
    var portstr: ?[*:0]const u8 = null;
    var port_switch = false;
    var result: c_uint = CURLE_OK;

    Curl_peer_unlink(ppeer);
    const connect_to = connect_to_opt orelse return CURLE_FAILED_INIT;
    if (connect_to[0] == 0) return CURLE_FAILED_INIT;

    defer peerParseClear(&pp);

    pp.scheme = dest.scheme;

    if (connect_to[0] == '[') {
        const rest = std.mem.span(connect_to + 1);
        const close_rel = std.mem.indexOfScalar(u8, rest, ']') orelse {
            Curl_failf(data, "Invalid IPv6 address format in '%s'", connect_to);
            return CURLE_SETOPT_OPTION_SYNTAX;
        };
        const s: [*:0]const u8 = connect_to + 1 + close_rel;
        if (std.mem.indexOfScalar(u8, std.mem.span(s), ':')) |colon_rel| {
            portstr = s + colon_rel;
        }
        pp.host_user.str = connect_to;
        pp.host_user.len = close_rel + 2;
        pp.ipv6 = true;
    } else {
        const ct_slice = std.mem.span(connect_to);
        if (std.mem.indexOfScalar(u8, ct_slice, ':')) |colon_rel| {
            portstr = connect_to + colon_rel;
            pp.host_user.str = connect_to;
            pp.host_user.len = colon_rel;
        } else {
            pp.host_user.str = connect_to;
            pp.host_user.len = ct_slice.len;
        }
    }

    if (pp.host_user.len == 0) {
        port_switch = true;
        const uh_ptr: [*:0]const u8 = @ptrCast(&dest.user_hostname);
        pp.host_user.str = uh_ptr;
        pp.host_user.len = std.mem.len(uh_ptr);
    }

    result = peerParseHost(data, &pp, false);
    if (result != CURLE_OK) return result;

    if (portstr != null and portstr.?[1] != 0) {
        var p: ?[*:0]const u8 = portstr.? + 1;
        var portparse: i64 = 0;
        if (curlx_parse.curlx_str_number(&p, &portparse, 0xffff) != 0) {
            Curl_failf(data, "No valid port number in '%s'", connect_to);
            return CURLE_SETOPT_OPTION_SYNTAX;
        }
        pp.port = @intCast(portparse);
    } else {
        pp.port = dest.port;
    }

    if (pp.ipv6 and port_switch) {
        if (dest.zoneid) |z| {
            pp.zoneid.str = z;
            pp.zoneid.len = std.mem.len(z);
        }
        pp.scopeid = dest.scopeid;
    }

    return peerCreate(&pp, ppeer);
}

pub export fn Curl_scheme_to_proxytype(
    data: ?*anyopaque,
    scheme_opt: ?[*:0]const u8,
    proxytype: *u8,
    url: ?[*:0]const u8,
) callconv(.c) c_uint {
    const scheme = scheme_opt orelse return CURLE_OK;

    if (primitives.curl_strequal("https", scheme) != 0) {
        if (proxytype.* != CURLPROXY_HTTPS2 and proxytype.* != CURLPROXY_HTTPS3) {
            proxytype.* = CURLPROXY_HTTPS;
        }
    } else if (primitives.curl_strequal("socks5h", scheme) != 0) {
        proxytype.* = CURLPROXY_SOCKS5_HOSTNAME;
    } else if (primitives.curl_strequal("socks5", scheme) != 0) {
        proxytype.* = CURLPROXY_SOCKS5;
    } else if (primitives.curl_strequal("socks4a", scheme) != 0) {
        proxytype.* = CURLPROXY_SOCKS4A;
    } else if (primitives.curl_strequal("socks4", scheme) != 0 or primitives.curl_strequal("socks", scheme) != 0) {
        proxytype.* = CURLPROXY_SOCKS4;
    } else if (primitives.curl_strequal("http", scheme) != 0) {
        if (proxytype.* != CURLPROXY_HTTP_1_0) {
            proxytype.* = CURLPROXY_HTTP;
        }
    } else {
        Curl_failf(data, "Unsupported proxy scheme for '%s'", url orelse "");
        return CURLE_COULDNT_CONNECT;
    }
    return CURLE_OK;
}

fn isHttpsProxy(pt: u8) bool {
    return pt == CURLPROXY_HTTPS or pt == CURLPROXY_HTTPS2 or pt == CURLPROXY_HTTPS3;
}

pub export fn Curl_peer_from_proxy_url(
    uh: *urlapi.Curl_URL,
    data: ?*anyopaque,
    url: ?[*:0]const u8,
    proxytype_in: u8,
    default_proxyport: u16,
    ppeer: *?*CurlPeer,
    pproxytype: *u8,
) callconv(.c) c_uint {
    var pp: PeerParse = .{};
    var scheme: ?[*:0]u8 = null;
    var portptr: ?[*:0]u8 = null;
    var proxytype = proxytype_in;
    var is_socks = false;
    var result: c_uint = CURLE_OK;

    Curl_peer_unlink(ppeer);
    defer {
        peerParseClear(&pp);
        mem.free(scheme);
    }

    pp.port = CURL_DEFAULT_PROXY_PORT;
    var uc = urlapi.curl_url_get(
        uh,
        .CURLUPART_SCHEME,
        &scheme,
        urlapi.CURLU_NON_SUPPORT_SCHEME | urlapi.CURLU_NO_GUESS_SCHEME,
    );
    if (uc != .CURLUE_OK) {
        if (uc == .CURLUE_OUT_OF_MEMORY) return CURLE_OUT_OF_MEMORY;
        switch (proxytype) {
            CURLPROXY_HTTP, CURLPROXY_HTTP_1_0 => pp.scheme = &Curl_scheme_http,
            CURLPROXY_HTTPS, CURLPROXY_HTTPS2, CURLPROXY_HTTPS3 => pp.scheme = &Curl_scheme_https,
            CURLPROXY_SOCKS4 => pp.scheme = &Curl_scheme_socks4,
            CURLPROXY_SOCKS4A => pp.scheme = &Curl_scheme_socks4a,
            CURLPROXY_SOCKS5 => pp.scheme = &Curl_scheme_socks5,
            CURLPROXY_SOCKS5_HOSTNAME => pp.scheme = &Curl_scheme_socks5h,
            else => {
                Curl_failf(data, "Unsupported proxy type %u for '%s'", @as(c_uint, proxytype), url orelse "");
                return CURLE_COULDNT_RESOLVE_PROXY;
            },
        }
    } else {
        pp.scheme = if (scheme) |s| Curl_get_scheme(s) else null;
        result = Curl_scheme_to_proxytype(data, scheme, &proxytype, url);
        if (result != CURLE_OK) return result;
    }

    const sch = pp.scheme orelse return CURLE_COULDNT_CONNECT;

    if (isHttpsProxy(proxytype) and !Curl_ssl_supports(data, SSLSUPP_HTTPS_PROXY)) {
        Curl_failf(data, "Unsupported proxy '%s', libcurl is built without the HTTPS-proxy support.", url orelse "");
        return CURLE_NOT_BUILT_IN;
    }

    if (sch.family == CURLPROTO_SOCKS) {
        is_socks = true;
    } else if (sch.family == CURLPROTO_HTTP) {
        // ok
    } else {
        Curl_failf(data, "Unsupported proxy protocol for '%s'", url orelse "");
        return CURLE_COULDNT_CONNECT;
    }

    uc = urlapi.curl_url_get(uh, .CURLUPART_PORT, &portptr, urlapi.CURLU_NO_DEFAULT_PORT);
    if (uc == .CURLUE_OUT_OF_MEMORY) return CURLE_OUT_OF_MEMORY;
    if (portptr) |pptr| {
        var num: i64 = 0;
        var p: ?[*:0]const u8 = pptr;
        if (curlx_parse.curlx_str_number(&p, &num, std.math.maxInt(u16)) == 0) {
            pp.port = @intCast(num);
        }
        mem.free(pptr);
    } else {
        if (default_proxyport != 0) {
            pp.port = default_proxyport;
        } else {
            pp.port = sch.defport;
        }
    }

    uc = urlapi.curl_url_get(uh, .CURLUPART_HOST, &pp.tmp_host_user, urlapi.CURLU_URLDECODE);
    if (uc != .CURLUE_OK) return CURLE_OUT_OF_MEMORY;
    pp.host_user.str = pp.tmp_host_user;
    pp.host_user.len = if (pp.tmp_host_user) |h| std.mem.len(h) else 0;

    if (is_socks and pp.tmp_host_user != null and primitives.curl_strequal("localhost", pp.tmp_host_user) != 0) {
        uc = urlapi.curl_url_get(uh, .CURLUPART_PATH, &pp.tmp_host, urlapi.CURLU_URLDECODE);
        if (uc != .CURLUE_OK) return CURLE_OUT_OF_MEMORY;
        if (pp.tmp_host) |th| {
            if (!std.mem.eql(u8, std.mem.span(th), "/")) {
                pp.host.str = th;
                pp.host.len = std.mem.len(th);
                pp.unix_socket = true;
            } else {
                pp.host = pp.host_user;
            }
        }
    }

    if (pp.host.len == 0) {
        result = peerParseHost(data, &pp, false);
        if (result != CURLE_OK) return result;
    }

    uc = urlapi.curl_url_get(uh, .CURLUPART_ZONEID, &pp.tmp_zoneid, 0);
    if (uc == .CURLUE_OUT_OF_MEMORY) return CURLE_OUT_OF_MEMORY;
    if (pp.tmp_zoneid) |tz| {
        pp.zoneid.str = tz;
        pp.zoneid.len = std.mem.len(tz);
    }

    pproxytype.* = proxytype;
    return peerCreate(&pp, ppeer);
}

// ============================================================================
// 2. lib/altsvc.c — HTTP Alt-Svc Cache
// ============================================================================

const MAX_ALTSVC_ENTRIES: usize = 5000;
const MAX_ALTSVC_LINE: usize = 4095;
const MAX_ALTSVC_DATELEN: usize = 17;
const MAX_ALTSVC_HOSTLEN: usize = 2048;
const MAX_ALTSVC_ALPNLEN: usize = 10;
const CAP_ALTSVC_MAX_AGE: i64 = 2 * 365 * 24 * 3600;

pub const Althost = extern struct {
    host: ?[*:0]u8,
    port: u16,
    alpnid: c_uint,
};

pub const Altsvc = extern struct {
    src: Althost,
    dst: Althost,
    expires: time_t,
    node: containers.Curl_llist_node,
    persist: u8,
};

pub const Altsvcinfo = extern struct {
    filename: ?[*:0]u8,
    list: containers.Curl_llist,
    flags: c_long,
};

pub export fn Curl_alpnid2str(id: c_uint) callconv(.c) [*:0]const u8 {
    return switch (id) {
        ALPN_h1 => "h1",
        ALPN_h2 => "h2",
        ALPN_h3 => "h3",
        else => "",
    };
}

fn str2alpnid(cstr: *const Curl_str) c_uint {
    const s = cstr.str orelse return ALPN_none;
    return Curl_alpn2alpnid(s, cstr.len);
}

fn altsvcCreateId(
    srchost_in: [*]const u8,
    hlen_in: usize,
    dsthost_in: [*]const u8,
    dlen_in: usize,
    srcalpnid: c_uint,
    dstalpnid: c_uint,
    srcport: usize,
    dstport: usize,
) ?*Altsvc {
    var srchost = srchost_in;
    var hlen = hlen_in;
    var dsthost = dsthost_in;
    var dlen = dlen_in;

    if (hlen > 2 and srchost[0] == '[') {
        srchost += 1;
        hlen -= 2;
    } else if (hlen != 0 and srchost[hlen - 1] == '.') {
        hlen -= 1;
    }
    if (dlen > 2 and dsthost[0] == '[') {
        dsthost += 1;
        dlen -= 2;
    }
    if (hlen == 0 or dlen == 0) return null;

    const total = @sizeOf(Altsvc) + (hlen + 1) + (dlen + 1);
    const raw = mem.calloc(1, total) orelse return null;
    const as: *Altsvc = @ptrCast(@alignCast(raw));
    const base: [*]u8 = @ptrCast(raw);

    const src_ptr = base + @sizeOf(Altsvc);
    @memcpy(src_ptr[0..hlen], srchost[0..hlen]);
    as.src.host = @ptrCast(src_ptr);

    const dst_ptr = base + @sizeOf(Altsvc) + hlen + 1;
    @memcpy(dst_ptr[0..dlen], dsthost[0..dlen]);
    as.dst.host = @ptrCast(dst_ptr);

    as.src.alpnid = srcalpnid;
    as.dst.alpnid = dstalpnid;
    as.src.port = @intCast(srcport);
    as.dst.port = @intCast(dstport);
    return as;
}

fn altsvcCreate(
    srchost: *const Curl_str,
    dsthost: *const Curl_str,
    srcalpn: *const Curl_str,
    dstalpn: *const Curl_str,
    srcport: usize,
    dstport: usize,
) ?*Altsvc {
    const dstalpnid = str2alpnid(dstalpn);
    const srcalpnid = str2alpnid(srcalpn);
    if (srcalpnid == 0 or dstalpnid == 0) return null;
    const sh = srchost.str orelse return null;
    const dh = dsthost.str orelse return null;
    return altsvcCreateId(sh, srchost.len, dh, dsthost.len, srcalpnid, dstalpnid, srcport, dstport);
}

fn altsvcAppend(asi: *Altsvcinfo, as: *Altsvc) void {
    while (containers.Curl_llist_count(&asi.list) >= MAX_ALTSVC_ENTRIES) {
        const e = containers.Curl_llist_head(&asi.list) orelse break;
        const oldas = containers.Curl_node_elem(e);
        containers.Curl_node_remove(e);
        mem.free(oldas);
    }
    containers.Curl_llist_append(&asi.list, as, &as.node);
}

fn altsvcAdd(asi: *Altsvcinfo, line_in: [*:0]const u8) c_uint {
    var line: ?[*:0]const u8 = line_in;
    var srchost: Curl_str = .{ .str = null, .len = 0 };
    var dsthost: Curl_str = .{ .str = null, .len = 0 };
    var srcalpn: Curl_str = .{ .str = null, .len = 0 };
    var dstalpn: Curl_str = .{ .str = null, .len = 0 };
    var date: Curl_str = .{ .str = null, .len = 0 };
    var srcport: i64 = 0;
    var dstport: i64 = 0;
    var persist: i64 = 0;
    var prio: i64 = 0;

    if (curlx_parse.curlx_str_word(&line, &srcalpn, MAX_ALTSVC_ALPNLEN) != 0 or
        curlx_parse.curlx_str_singlespace(&line) != 0 or
        curlx_parse.curlx_str_word(&line, &srchost, MAX_ALTSVC_HOSTLEN) != 0 or
        curlx_parse.curlx_str_singlespace(&line) != 0 or
        curlx_parse.curlx_str_number(&line, &srcport, 65535) != 0 or
        curlx_parse.curlx_str_singlespace(&line) != 0 or
        curlx_parse.curlx_str_word(&line, &dstalpn, MAX_ALTSVC_ALPNLEN) != 0 or
        curlx_parse.curlx_str_singlespace(&line) != 0 or
        curlx_parse.curlx_str_word(&line, &dsthost, MAX_ALTSVC_HOSTLEN) != 0 or
        curlx_parse.curlx_str_singlespace(&line) != 0 or
        curlx_parse.curlx_str_number(&line, &dstport, 65535) != 0 or
        curlx_parse.curlx_str_singlespace(&line) != 0 or
        curlx_parse.curlx_str_quotedword(&line, &date, MAX_ALTSVC_DATELEN) != 0 or
        curlx_parse.curlx_str_singlespace(&line) != 0 or
        curlx_parse.curlx_str_number(&line, &persist, 1) != 0 or
        curlx_parse.curlx_str_singlespace(&line) != 0 or
        curlx_parse.curlx_str_number(&line, &prio, 0) != 0 or
        curlx_parse.curlx_str_newline(&line) != 0)
    {
        return CURLE_OK;
    }

    var dbuf: [MAX_ALTSVC_DATELEN + 1]u8 = undefined;
    var expires: time_t = 0;
    const now = nowTime();

    if (date.str) |ds| {
        @memcpy(dbuf[0..date.len], ds[0..date.len]);
    }
    dbuf[date.len] = 0;
    _ = Curl_getdate_capped(@ptrCast(&dbuf), &expires);

    if (now < expires) {
        const as = altsvcCreate(&srchost, &dsthost, &srcalpn, &dstalpn, @intCast(srcport), @intCast(dstport)) orelse return CURLE_OUT_OF_MEMORY;
        as.expires = expires;
        as.persist = if (persist != 0) 1 else 0;
        altsvcAppend(asi, as);
    }

    return CURLE_OK;
}

fn altsvcOut(as: *Altsvc, fp: ?*anyopaque) c_uint {
    var stamp: Tm = std.mem.zeroes(Tm);
    var dst6_pre: [*:0]const u8 = "";
    var dst6_post: [*:0]const u8 = "";
    var src6_pre: [*:0]const u8 = "";
    var src6_post: [*:0]const u8 = "";

    const result = curlx_time_net.curlx_gmtime(as.expires, &stamp);
    if (result != CURLE_OK) return CURLE_OK;

    var ipv6_unused: [16]u8 = undefined;
    if (as.dst.host) |dh| {
        if (curlx_time_net.curlx_inet_pton(curlx_time_net.AF_INET6, dh, &ipv6_unused) == 1) {
            dst6_pre = "[";
            dst6_post = "]";
        }
    }
    if (as.src.host) |sh| {
        if (curlx_time_net.curlx_inet_pton(curlx_time_net.AF_INET6, sh, &ipv6_unused) == 1) {
            src6_pre = "[";
            src6_post = "]";
        }
    }

    _ = curl_mfprintf(
        fp,
        "%s %s%s%s %u %s %s%s%s %u \"%d%02d%02d %02d:%02d:%02d\" %d 0\n",
        Curl_alpnid2str(as.src.alpnid),
        src6_pre,
        as.src.host orelse @as([*:0]const u8, ""),
        src6_post,
        @as(c_uint, as.src.port),
        Curl_alpnid2str(as.dst.alpnid),
        dst6_pre,
        as.dst.host orelse @as([*:0]const u8, ""),
        dst6_post,
        @as(c_uint, as.dst.port),
        stamp.tm_year + 1900,
        stamp.tm_mon + 1,
        stamp.tm_mday,
        stamp.tm_hour,
        stamp.tm_min,
        stamp.tm_sec,
        @as(c_int, as.persist & 1),
    );
    return CURLE_OK;
}

pub export fn Curl_altsvc_init() callconv(.c) ?*Altsvcinfo {
    const raw = mem.calloc(1, @sizeOf(Altsvcinfo)) orelse return null;
    const asi: *Altsvcinfo = @ptrCast(@alignCast(raw));
    containers.Curl_llist_init(&asi.list, null);

    var flags: c_long = CURLALTSVC_H1;
    if (curl_version_info(0)) |vinfo| {
        if ((vinfo.features & CURL_VERSION_HTTP2) != 0) flags |= CURLALTSVC_H2;
        if ((vinfo.features & CURL_VERSION_HTTP3) != 0) flags |= CURLALTSVC_H3;
    }
    asi.flags = flags;
    return asi;
}

pub export fn Curl_altsvc_load(asi: *Altsvcinfo, file: [*:0]const u8) callconv(.c) c_uint {
    var result: c_uint = CURLE_OK;

    mem.free(asi.filename);
    asi.filename = mem.strdup(file);
    if (asi.filename == null) return CURLE_OUT_OF_MEMORY;

    if (curlxFopenReadText(file)) |fp| {
        if (isFpNotDir(fp)) {
            var eof = false;
            var buf: os_leaf.Dynbuf = undefined;
            containers.curlx_dyn_init(@ptrCast(&buf), MAX_ALTSVC_LINE);
            while (true) {
                result = os_leaf.Curl_get_line(&buf, fp, &eof);
                if (result == CURLE_OK) {
                    var lineptr: ?[*:0]const u8 = containers.curlx_dyn_ptr(@ptrCast(&buf));
                    curlx_parse.curlx_str_passblanks(&lineptr);
                    if (curlx_parse.curlx_str_single(&lineptr, '#') != 0) {
                        if (lineptr) |lp| {
                            _ = altsvcAdd(asi, lp);
                        }
                    }
                }
                if (result != CURLE_OK or eof) break;
            }
            containers.curlx_dyn_free(@ptrCast(&buf));
        }
        _ = fclose(fp);
    }
    return result;
}

pub export fn Curl_altsvc_ctrl(asip: *?*Altsvcinfo, ctrl: c_long) callconv(.c) c_uint {
    if (ctrl == 0) return CURLE_BAD_FUNCTION_ARGUMENT;
    if (asip.* == null) {
        asip.* = Curl_altsvc_init();
        if (asip.* == null) return CURLE_OUT_OF_MEMORY;
    }
    asip.*.?.flags = ctrl;
    return CURLE_OK;
}

pub export fn Curl_altsvc_cleanup(asip: *?*Altsvcinfo) callconv(.c) void {
    if (asip.*) |altsvc| {
        var e = containers.Curl_llist_head(&altsvc.list);
        while (e) |node| {
            const as = containers.Curl_node_elem(node);
            const n = containers.Curl_node_next(node);
            mem.free(as);
            e = n;
        }
        mem.free(altsvc.filename);
        mem.free(altsvc);
        asip.* = null;
    }
}

pub export fn Curl_altsvc_save(data: ?*anyopaque, asi_opt: ?*Altsvcinfo, file_in: ?[*:0]const u8) callconv(.c) c_uint {
    const asi = asi_opt orelse return CURLE_OK;
    var file = file_in;
    if (file == null and asi.filename != null) {
        file = asi.filename;
    }
    if ((asi.flags & CURLALTSVC_READONLYFILE) != 0 or file == null or file.?[0] == 0) {
        return CURLE_OK;
    }

    var out: ?*anyopaque = null;
    var tempstore: ?[*:0]u8 = null;
    var result = Curl_fopen(data, file.?, &out, &tempstore);
    if (result == CURLE_OK) {
        _ = fputs(
            "# Your alt-svc cache. https://curl.se/docs/alt-svc.html\n" ++
                "# This file was generated by libcurl! Edit at your own risk.\n",
            out,
        );
        var e = containers.Curl_llist_head(&asi.list);
        while (e) |node| {
            const as: *Altsvc = @ptrCast(@alignCast(containers.Curl_node_elem(node).?));
            const n = containers.Curl_node_next(node);
            result = altsvcOut(as, out);
            if (result != CURLE_OK) break;
            e = n;
        }
        _ = fclose(out);
        if (result == CURLE_OK and tempstore != null and curlxRename(tempstore.?, file.?) != 0) {
            result = CURLE_WRITE_ERROR;
        }
        if (result != CURLE_OK and tempstore != null) {
            _ = unlink(tempstore.?);
        }
    }
    mem.free(tempstore);
    return result;
}

fn hostcompare(host: [*:0]const u8, check: [*:0]const u8) bool {
    var hlen = std.mem.len(host);
    const clen = std.mem.len(check);
    if (hlen != 0 and host[hlen - 1] == '.') {
        hlen -= 1;
    }
    if (hlen != clen) return false;
    return primitives.curl_strnequal(host, check, hlen) != 0;
}

fn altsvcFlush(asi: *Altsvcinfo, origin: *const CurlPeer, origin_alpnid: c_uint) void {
    var e = containers.Curl_llist_head(&asi.list);
    while (e) |node| {
        const as: *Altsvc = @ptrCast(@alignCast(containers.Curl_node_elem(node).?));
        const n = containers.Curl_node_next(node);
        if (origin_alpnid == as.src.alpnid and
            origin.port == as.src.port and
            as.src.host != null and
            hostcompare(origin.hostname, as.src.host.?))
        {
            containers.Curl_node_remove(node);
            mem.free(as);
        }
        e = n;
    }
}

fn altsvcParseParams(pp: *?[*:0]const u8, pmaxage: *time_t, ppersist: *bool) void {
    curlx_parse.curlx_str_passblanks(pp);
    if (curlx_parse.curlx_str_single(pp, ';') != 0) return;

    while (true) {
        var name: Curl_str = .{ .str = null, .len = 0 };
        var val: Curl_str = .{ .str = null, .len = 0 };
        var num: i64 = 0;
        var keyword: c_int = 0;

        if (curlx_parse.curlx_str_until(pp, &name, MAX_ALTSVC_LINE, '=') != 0 or
            curlx_parse.curlx_str_single(pp, '=') != 0)
        {
            break;
        }

        curlx_parse.curlx_str_trimblanks(&name);
        curlx_parse.curlx_str_passblanks(pp);
        if (pp.* != null and pp.*.?[0] == '"') {
            if (curlx_parse.curlx_str_quotedword(pp, &val, MAX_ALTSVC_LINE) != 0) break;
        } else {
            if (curlx_parse.curlx_str_cspn(pp, &val, ",;\r\n") != 0) break;
        }
        curlx_parse.curlx_str_trimblanks(&val);

        if (curlx_parse.curlx_str_casecompare(&name, "ma") != 0) {
            keyword = 1;
        } else if (curlx_parse.curlx_str_casecompare(&name, "persist") != 0) {
            keyword = 2;
        }

        if (keyword != 0) {
            if (val.str) |vs| {
                var vp: ?[*:0]const u8 = @ptrCast(vs);
                const vend: [*]const u8 = vs + val.len;
                if (curlx_parse.curlx_str_number(&vp, &num, CURL_OFF_T_MAX) != 0) break;
                if (vp == null or @intFromPtr(vp.?) != @intFromPtr(vend)) break;
                if (keyword == 1) {
                    if (num > CAP_ALTSVC_MAX_AGE) num = CAP_ALTSVC_MAX_AGE;
                    pmaxage.* = @intCast(num);
                } else if (num == 1) {
                    ppersist.* = true;
                }
            } else {
                break;
            }
        }

        curlx_parse.curlx_str_passblanks(pp);
        if (curlx_parse.curlx_str_single(pp, ';') != 0) break;
    }
}

fn altsvcParseDest(
    pp: *?[*:0]const u8,
    data: ?*anyopaque,
    origin: *const CurlPeer,
    dsthost: *Curl_str,
    pdstport: *u16,
) bool {
    var port: i64 = 0;
    if (curlx_parse.curlx_str_single(pp, '"') != 0) return false;

    if (curlx_parse.curlx_str_single(pp, ':') != 0) {
        if (curlx_parse.curlx_str_single(pp, '[') != 0) {
            if (curlx_parse.curlx_str_until(pp, dsthost, MAX_ALTSVC_HOSTLEN, ':') != 0) {
                Curl_infof(data, "Bad alt-svc hostname, ignoring.");
                return false;
            }
        } else {
            if (curlx_parse.curlx_str_until(pp, dsthost, MAX_IPADR_LEN, ']') != 0 or
                curlx_parse.curlx_str_single(pp, ']') != 0)
            {
                Curl_infof(data, "Bad alt-svc IPv6 hostname, ignoring.");
                return false;
            }
        }
        if (curlx_parse.curlx_str_single(pp, ':') != 0) return false;
    } else {
        curlx_parse.curlx_str_assign(dsthost, origin.hostname, std.mem.len(origin.hostname));
    }

    if (curlx_parse.curlx_str_number(pp, &port, 0xffff) != 0) {
        Curl_infof(data, "Unknown alt-svc port number, ignoring.");
        return false;
    }

    pdstport.* = @intCast(port);
    if (curlx_parse.curlx_str_single(pp, '"') != 0) return false;
    return true;
}

pub export fn Curl_altsvc_parse(
    data: ?*anyopaque,
    asi: *Altsvcinfo,
    value: [*:0]const u8,
    origin: *CurlPeer,
    origin_alpnid: c_uint,
) callconv(.c) c_uint {
    var entries: usize = 0;
    var alpn: Curl_str = .{ .str = null, .len = 0 };
    var p: ?[*:0]const u8 = value;

    if (curlx_parse.curlx_str_cspn(&p, &alpn, ";\n\r") == 0) {
        curlx_parse.curlx_str_trimblanks(&alpn);
        if (curlx_parse.curlx_str_casecompare(&alpn, "clear") != 0) {
            altsvcFlush(asi, origin, origin_alpnid);
            return CURLE_OK;
        }
    }

    p = value;
    while (p != null and p.?[0] != 0) {
        var maxage: time_t = 24 * 3600;
        var persist = false;
        var dsthost: Curl_str = .{ .str = null, .len = 0 };
        var dstport: u16 = 0;

        if (curlx_parse.curlx_str_until(&p, &alpn, MAX_ALTSVC_LINE, '=') != 0) break;
        curlx_parse.curlx_str_trimblanks(&alpn);
        const dstalpnid = str2alpnid(&alpn);

        if (curlx_parse.curlx_str_single(&p, '=') != 0) break;
        if (!altsvcParseDest(&p, data, origin, &dsthost, &dstport)) break;

        altsvcParseParams(&p, &maxage, &persist);

        if (dstalpnid != 0) {
            if (entries == 0) {
                altsvcFlush(asi, origin, origin_alpnid);
            }
            entries += 1;

            const dh_ptr = dsthost.str orelse return CURLE_OUT_OF_MEMORY;
            const as = altsvcCreateId(
                origin.hostname,
                std.mem.len(origin.hostname),
                dh_ptr,
                dsthost.len,
                origin_alpnid,
                dstalpnid,
                origin.port,
                dstport,
            ) orelse return CURLE_OUT_OF_MEMORY;

            const secs = nowTime();
            if (maxage > (TIME_T_MAX - secs)) {
                as.expires = TIME_T_MAX;
            } else {
                as.expires = maxage + secs;
            }
            as.persist = if (persist) 1 else 0;
            altsvcAppend(asi, as);
            Curl_infof(
                data,
                "Added alt-svc: %.*s:%u over %s",
                @as(c_int, @intCast(dsthost.len)),
                dh_ptr,
                @as(c_uint, dstport),
                Curl_alpnid2str(dstalpnid),
            );
        }

        if (curlx_parse.curlx_str_single(&p, ',') != 0) break;
    }

    return CURLE_OK;
}

pub export fn Curl_altsvc_lookup(
    asi: *Altsvcinfo,
    origin: *CurlPeer,
    origin_alpnid: c_uint,
    dstentry: *?*Altsvc,
    versions: c_int,
    psame_destination: *bool,
) callconv(.c) bool {
    psame_destination.* = false;

    if (containers.Curl_llist_count(&asi.list) != 0) {
        var e = containers.Curl_llist_head(&asi.list);
        const now = nowTime();

        while (e) |node| {
            const as: *Altsvc = @ptrCast(@alignCast(containers.Curl_node_elem(node).?));
            const n = containers.Curl_node_next(node);
            if (as.expires < now) {
                containers.Curl_node_remove(node);
                mem.free(as);
                e = n;
                continue;
            }
            if (origin_alpnid == as.src.alpnid and
                (versions & @as(c_int, @intCast(as.dst.alpnid))) != 0 and
                origin.port == as.src.port and
                as.src.host != null and
                hostcompare(origin.hostname, as.src.host.?))
            {
                dstentry.* = as;
                psame_destination.* = (origin.port == as.dst.port) and
                    as.dst.host != null and
                    hostcompare(origin.hostname, as.dst.host.?);
                return true;
            }
            e = n;
        }
    }
    return false;
}

// ============================================================================
// 3. lib/hsts.c — HTTP Strict Transport Security Cache
// ============================================================================

const MAX_HSTS_ENTRIES: usize = 10000;
const MAX_HSTS_LINE: usize = 4095;
const MAX_HSTS_HOSTLEN: usize = 2048;
const MAX_HSTS_DATELEN: usize = 17;
const CAP_HSTS_MAX_AGE: i64 = 2 * 365 * 24 * 3600;
const UNLIMITED = "unlimited";

pub export var deltatime: time_t = 0;

pub const StsEntry = if (builtin.os.tag == .windows) extern struct {
    node: containers.Curl_llist_node,
    expires: i64,
    includeSubDomains: u32,
    host: [1]u8,
} else extern struct {
    node: containers.Curl_llist_node,
    expires: i64,
    includeSubDomains: u8,
    host: [1]u8,
};

pub const Hsts = extern struct {
    list: containers.Curl_llist,
    filename: ?[*:0]u8,
    flags: c_uint,
};

pub const CurlHstsEntry = if (builtin.os.tag == .windows) extern struct {
    name: ?[*]u8,
    namelen: usize,
    includeSubDomains: u32,
    expire: [18]u8,
} else extern struct {
    name: ?[*]u8,
    namelen: usize,
    includeSubDomains: u8,
    expire: [18]u8,
};

pub const CurlIndex = extern struct {
    index: usize,
    total: usize,
};

pub const HstsReadCallback = *const fn (easy: ?*anyopaque, e: *CurlHstsEntry, userp: ?*anyopaque) callconv(.c) c_uint;
pub const HstsWriteCallback = *const fn (easy: ?*anyopaque, e: *CurlHstsEntry, i: *CurlIndex, userp: ?*anyopaque) callconv(.c) c_uint;

pub export fn Curl_hsts_init() callconv(.c) ?*Hsts {
    const raw = mem.calloc(1, @sizeOf(Hsts)) orelse return null;
    const h: *Hsts = @ptrCast(@alignCast(raw));
    containers.Curl_llist_init(&h.list, null);
    return h;
}

pub export fn Curl_hsts_cleanup(hp: *?*Hsts) callconv(.c) void {
    if (hp.*) |h| {
        var e = containers.Curl_llist_head(&h.list);
        while (e) |node| {
            const sts = containers.Curl_node_elem(node);
            const n = containers.Curl_node_next(node);
            mem.free(sts);
            e = n;
        }
        mem.free(h.filename);
        mem.free(h);
        hp.* = null;
    }
}

fn hstsAppend(h: *Hsts, sts: *StsEntry) void {
    if (containers.Curl_llist_count(&h.list) == MAX_HSTS_ENTRIES) {
        if (containers.Curl_llist_head(&h.list)) |e| {
            const oldsts = containers.Curl_node_elem(e);
            containers.Curl_node_remove(e);
            mem.free(oldsts);
        }
    }
    containers.Curl_llist_append(&h.list, sts, &sts.node);
}

fn hstsCreate(h: *Hsts, hostname: [*]const u8, hlen_in: usize, subdomains: bool, expires: i64) c_uint {
    var hlen = hlen_in;
    if (hlen != 0 and hostname[hlen - 1] == '.') {
        hlen -= 1;
    }
    if (hlen != 0) {
        const raw = mem.calloc(1, @sizeOf(StsEntry) + hlen) orelse return CURLE_OUT_OF_MEMORY;
        const sts: *StsEntry = @ptrCast(@alignCast(raw));
        const host_dst: [*]u8 = @ptrCast(&sts.host);
        @memcpy(host_dst[0..hlen], hostname[0..hlen]);
        sts.expires = expires;
        sts.includeSubDomains = if (subdomains) 1 else 0;
        hstsAppend(h, sts);
    }
    return CURLE_OK;
}

pub export fn Curl_hsts_copy(dst: *Hsts, src: *Hsts) callconv(.c) c_uint {
    const now = nowTime();
    var e = containers.Curl_llist_head(&src.list);
    while (e) |node| {
        const sts: *StsEntry = @ptrCast(@alignCast(containers.Curl_node_elem(node).?));
        if (sts.expires > now) {
            const host_ptr: [*:0]const u8 = @ptrCast(&sts.host);
            const result = hstsCreate(dst, host_ptr, std.mem.len(host_ptr), (sts.includeSubDomains & 1) != 0, sts.expires);
            if (result != CURLE_OK) return result;
        }
        e = containers.Curl_node_next(node);
    }
    return CURLE_OK;
}

pub export fn hsts_check(h_opt: ?*Hsts, hostname: [*]const u8, hlen_in: usize, subdomain: bool) callconv(.c) ?*StsEntry {
    const h = h_opt orelse return null;
    const now = nowTime();
    var bestsub: ?*StsEntry = null;
    var blen: usize = 0;
    var hlen = hlen_in;

    if (hlen > MAX_HSTS_HOSTLEN or hlen == 0) return null;
    if (hostname[hlen - 1] == '.') {
        hlen -= 1;
    }

    var e = containers.Curl_llist_head(&h.list);
    while (e) |node| {
        const sts: *StsEntry = @ptrCast(@alignCast(containers.Curl_node_elem(node).?));
        const n = containers.Curl_node_next(node);
        if (sts.expires <= now) {
            containers.Curl_node_remove(&sts.node);
            mem.free(sts);
            e = n;
            continue;
        }
        const sts_host: [*:0]const u8 = @ptrCast(&sts.host);
        const ntail = std.mem.len(sts_host);
        if (subdomain and (sts.includeSubDomains & 1) != 0 and ntail < hlen) {
            const offs = hlen - ntail;
            if (hostname[offs - 1] == '.' and
                primitives.curl_strnequal(@ptrCast(hostname + offs), sts_host, ntail) != 0 and
                ntail > blen)
            {
                bestsub = sts;
                blen = ntail;
            }
        }
        if (hlen == ntail and primitives.curl_strnequal(@ptrCast(hostname), sts_host, hlen) != 0) {
            return sts;
        }
        e = n;
    }
    return bestsub;
}

pub export fn Curl_hsts(h: ?*Hsts, hostname: [*]const u8, hlen: usize, subdomain: bool) callconv(.c) ?*StsEntry {
    return hsts_check(h, hostname, hlen, subdomain);
}

pub export fn Curl_hsts_parse(h: *Hsts, hostname: [*:0]const u8, header: [*:0]const u8) callconv(.c) c_uint {
    var p: ?[*:0]const u8 = header;
    var expires: i64 = 0;
    var gotma = false;
    var gotinc = false;
    var subdomains = false;
    const now = nowTime();
    const hlen = std.mem.len(hostname);

    if (Curl_host_is_ipnum(hostname)) {
        return CURLE_OK;
    }

    while (true) {
        var word: Curl_str = .{ .str = null, .len = 0 };
        var val: Curl_str = .{ .str = null, .len = 0 };
        var assign = false;

        while (true) {
            curlx_parse.curlx_str_passblanks(&p);
            if (p != null and p.?[0] == ';') {
                p = p.? + 1;
            } else {
                break;
            }
        }
        if (curlx_parse.curlx_str_cspn(&p, &word, ";=\r\n \t") != 0) break;

        curlx_parse.curlx_str_passblanks(&p);
        if (curlx_parse.curlx_str_single(&p, '=') == 0) {
            assign = true;
            curlx_parse.curlx_str_passblanks(&p);
            if (p != null and p.?[0] == '"') {
                if (curlx_parse.curlx_str_quotedword(&p, &val, MAX_HSTS_LINE) != 0) break;
            } else {
                if (curlx_parse.curlx_str_cspn(&p, &val, ", ;\r\n") != 0) break;
            }
        }

        if (assign and curlx_parse.curlx_str_casecompare(&word, "max-age") != 0) {
            if (gotma) return CURLE_BAD_FUNCTION_ARGUMENT;
            var vp: ?[*:0]const u8 = if (val.str) |vs| @ptrCast(vs) else null;
            const rc = curlx_parse.curlx_str_number(&vp, &expires, CAP_HSTS_MAX_AGE);
            if (rc == curlx_parse.STRE_OVERFLOW) {
                expires = CAP_HSTS_MAX_AGE;
            } else if (rc != 0) {
                return CURLE_BAD_FUNCTION_ARGUMENT;
            }
            gotma = true;
        } else if (curlx_parse.curlx_str_casecompare(&word, "includesubdomains") != 0) {
            if (gotinc) return CURLE_BAD_FUNCTION_ARGUMENT;
            subdomains = true;
            gotinc = true;
        }

        if (p == null or p.?[0] == 0) break;
    }

    if (!gotma) return CURLE_BAD_FUNCTION_ARGUMENT;

    if (expires == 0) {
        if (hsts_check(h, hostname, hlen, false)) |sts| {
            containers.Curl_node_remove(&sts.node);
            mem.free(sts);
        }
        return CURLE_OK;
    }

    if (CURL_OFF_T_MAX - now < expires) {
        expires = CURL_OFF_T_MAX;
    } else {
        expires += now;
    }

    if (hsts_check(h, hostname, hlen, false)) |sts| {
        sts.expires = expires;
        sts.includeSubDomains = if (subdomains) 1 else 0;
        return CURLE_OK;
    }
    return hstsCreate(h, hostname, hlen, subdomains, expires);
}

fn hstsPush(
    data: ?*anyopaque,
    i: *CurlIndex,
    sts: *StsEntry,
    stop: *bool,
    hsts_write: HstsWriteCallback,
    hsts_write_userp: ?*anyopaque,
) c_uint {
    var e: CurlHstsEntry = std.mem.zeroes(CurlHstsEntry);
    var stamp: Tm = std.mem.zeroes(Tm);
    const sts_host: [*:0]u8 = @ptrCast(&sts.host);

    e.name = sts_host;
    e.namelen = std.mem.len(sts_host);
    e.includeSubDomains = if ((sts.includeSubDomains & 1) != 0) 1 else 0;

    if (sts.expires != TIME_T_MAX) {
        const result = curlx_time_net.curlx_gmtime(@intCast(sts.expires), &stamp);
        if (result != CURLE_OK) return result;
        _ = curl_msnprintf(
            &e.expire,
            e.expire.len,
            "%d%02d%02d %02d:%02d:%02d",
            stamp.tm_year + 1900,
            stamp.tm_mon + 1,
            stamp.tm_mday,
            stamp.tm_hour,
            stamp.tm_min,
            stamp.tm_sec,
        );
    } else {
        primitives.curlx_strcopy(&e.expire, e.expire.len, UNLIMITED, UNLIMITED.len);
    }

    const sc = hsts_write(data, &e, i, hsts_write_userp);
    stop.* = (sc != CURLSTS_OK);
    return if (sc == CURLSTS_FAIL) CURLE_BAD_FUNCTION_ARGUMENT else CURLE_OK;
}

fn hstsOut(sts: *StsEntry, fp: ?*anyopaque) void {
    var stamp: Tm = std.mem.zeroes(Tm);
    const sts_host: [*:0]const u8 = @ptrCast(&sts.host);
    const dot_prefix: [*:0]const u8 = if ((sts.includeSubDomains & 1) != 0) "." else "";

    if (sts.expires != TIME_T_MAX) {
        if (curlx_time_net.curlx_gmtime(@intCast(sts.expires), &stamp) == CURLE_OK) {
            _ = curl_mfprintf(
                fp,
                "%s%s \"%d%02d%02d %02d:%02d:%02d\"\n",
                dot_prefix,
                sts_host,
                stamp.tm_year + 1900,
                stamp.tm_mon + 1,
                stamp.tm_mday,
                stamp.tm_hour,
                stamp.tm_min,
                stamp.tm_sec,
            );
        }
    } else {
        _ = curl_mfprintf(fp, "%s%s \"%s\"\n", dot_prefix, sts_host, @as([*:0]const u8, UNLIMITED));
    }
}

pub export fn Curl_hsts_save(
    data: ?*anyopaque,
    h_opt: ?*Hsts,
    file_in: ?[*:0]const u8,
    hsts_write_opt: ?HstsWriteCallback,
    hsts_write_userp: ?*anyopaque,
) callconv(.c) c_uint {
    const h = h_opt orelse return CURLE_OK;
    var result: c_uint = CURLE_OK;
    var file = file_in;

    if (file == null and h.filename != null) {
        file = h.filename;
    }

    if ((h.flags & CURLHSTS_READONLYFILE) == 0 and file != null and file.?[0] != 0) {
        var out: ?*anyopaque = null;
        var tempstore: ?[*:0]u8 = null;
        result = Curl_fopen(data, file.?, &out, &tempstore);
        if (result == CURLE_OK) {
            _ = fputs(
                "# Your HSTS cache. https://curl.se/docs/hsts.html\n" ++
                    "# This file was generated by libcurl! Edit at your own risk.\n",
                out,
            );
            var e = containers.Curl_llist_head(&h.list);
            while (e) |node| {
                const sts: *StsEntry = @ptrCast(@alignCast(containers.Curl_node_elem(node).?));
                const n = containers.Curl_node_next(node);
                hstsOut(sts, out);
                e = n;
            }
            _ = fclose(out);
            if (result == CURLE_OK and tempstore != null and curlxRename(tempstore.?, file.?) != 0) {
                result = CURLE_WRITE_ERROR;
            }
            if (result != CURLE_OK and tempstore != null) {
                _ = unlink(tempstore.?);
            }
        }
        mem.free(tempstore);
    }

    if (hsts_write_opt) |hsts_write| {
        var i: CurlIndex = .{
            .total = containers.Curl_llist_count(&h.list),
            .index = 0,
        };
        var e = containers.Curl_llist_head(&h.list);
        while (e) |node| {
            const sts: *StsEntry = @ptrCast(@alignCast(containers.Curl_node_elem(node).?));
            var stop = false;
            const n = containers.Curl_node_next(node);
            result = hstsPush(data, &i, sts, &stop, hsts_write, hsts_write_userp);
            if (result != CURLE_OK or stop) break;
            i.index += 1;
            e = n;
        }
    }
    return result;
}

fn hstsAddHostExpire(
    h: *Hsts,
    host_in: [*]const u8,
    hostlen_in: usize,
    expire: [*]const u8,
    explen: usize,
    subdomain_in: bool,
) c_uint {
    var result: c_uint = CURLE_OK;
    var dbuf: [MAX_HSTS_DATELEN + 1]u8 = undefined;
    var expires: time_t = 0;
    const now = nowTime();
    var host = host_in;
    var hostlen = hostlen_in;
    var subdomain = subdomain_in;

    if (explen > MAX_HSTS_DATELEN) return CURLE_BAD_FUNCTION_ARGUMENT;
    @memcpy(dbuf[0..explen], expire[0..explen]);
    dbuf[explen] = 0;

    if (std.mem.eql(u8, dbuf[0..explen], UNLIMITED)) {
        expires = TIME_T_MAX;
    } else {
        _ = Curl_getdate_capped(@ptrCast(&dbuf), &expires);
    }

    if (expires <= now) return CURLE_OK;

    if (hostlen != 0 and host[0] == '.') {
        host += 1;
        hostlen -= 1;
        subdomain = true;
    }
    if (hostlen != 0 and host[hostlen - 1] == '.') {
        hostlen -= 1;
    }

    if (hostlen != 0) {
        const e = hsts_check(h, host, hostlen, false);
        if (e == null) {
            result = hstsCreate(h, host, hostlen, subdomain, expires);
        } else {
            const entry = e.?;
            const entry_host: [*:0]const u8 = @ptrCast(&entry.host);
            if (hostlen == std.mem.len(entry_host) and primitives.curl_strnequal(@ptrCast(host), entry_host, hostlen) != 0) {
                if (expires > entry.expires) {
                    entry.expires = expires;
                }
                if (subdomain) {
                    entry.includeSubDomains = 1;
                }
            }
        }
    }
    return result;
}

fn hstsAdd(h: *Hsts, line_in: [*:0]const u8) c_uint {
    var line: ?[*:0]const u8 = line_in;
    var host: Curl_str = .{ .str = null, .len = 0 };
    var date: Curl_str = .{ .str = null, .len = 0 };

    if (curlx_parse.curlx_str_word(&line, &host, MAX_HSTS_HOSTLEN) != 0 or
        curlx_parse.curlx_str_singlespace(&line) != 0 or
        curlx_parse.curlx_str_quotedword(&line, &date, MAX_HSTS_DATELEN) != 0 or
        curlx_parse.curlx_str_newline(&line) != 0)
    {
        return CURLE_OK;
    }

    const h_ptr = host.str orelse return CURLE_OK;
    const d_ptr = date.str orelse return CURLE_OK;
    return hstsAddHostExpire(h, h_ptr, host.len, d_ptr, date.len, false);
}

fn hstsPull(data: ?*anyopaque, h: *Hsts, hsts_read_opt: ?HstsReadCallback, hsts_read_userp: ?*anyopaque) c_uint {
    if (hsts_read_opt) |hsts_read| {
        while (true) {
            var buffer: [MAX_HSTS_HOSTLEN + 1]u8 = undefined;
            var e: CurlHstsEntry = std.mem.zeroes(CurlHstsEntry);
            e.name = &buffer;
            e.namelen = buffer.len - 1;
            e.includeSubDomains = 0;
            e.expire[0] = 0;
            e.expire[MAX_HSTS_DATELEN] = 0;
            buffer[0] = 0;
            buffer[MAX_HSTS_HOSTLEN] = 0;

            const sc = hsts_read(data, &e, hsts_read_userp);
            if (sc == CURLSTS_OK) {
                const name_ptr: [*:0]const u8 = @ptrCast(e.name orelse return CURLE_BAD_FUNCTION_ARGUMENT);
                if (name_ptr[0] == 0 or e.expire[MAX_HSTS_DATELEN] != 0 or name_ptr[MAX_HSTS_HOSTLEN] != 0) {
                    return CURLE_BAD_FUNCTION_ARGUMENT;
                }
                const date: [*:0]const u8 = if (e.expire[0] != 0) @ptrCast(&e.expire) else UNLIMITED;
                const result = hstsAddHostExpire(
                    h,
                    name_ptr,
                    std.mem.len(name_ptr),
                    date,
                    std.mem.len(date),
                    (e.includeSubDomains & 1) != 0,
                );
                if (result != CURLE_OK) return result;
            } else if (sc == CURLSTS_FAIL) {
                return CURLE_ABORTED_BY_CALLBACK;
            } else {
                break;
            }
        }
    }
    return CURLE_OK;
}

pub export fn Curl_hsts_loadfile(data: ?*anyopaque, h: *Hsts, file: [*:0]const u8) callconv(.c) c_uint {
    _ = data;
    var result: c_uint = CURLE_OK;

    mem.free(h.filename);
    h.filename = mem.strdup(file);
    if (h.filename == null) return CURLE_OUT_OF_MEMORY;

    if (curlxFopenReadText(file)) |fp| {
        if (isFpNotDir(fp)) {
            var buf: os_leaf.Dynbuf = undefined;
            var eof = false;
            containers.curlx_dyn_init(@ptrCast(&buf), MAX_HSTS_LINE);
            while (true) {
                result = os_leaf.Curl_get_line(&buf, fp, &eof);
                if (result == CURLE_OK) {
                    var lineptr: ?[*:0]const u8 = containers.curlx_dyn_ptr(@ptrCast(&buf));
                    curlx_parse.curlx_str_passblanks(&lineptr);
                    if (lineptr) |lp| {
                        if (lp[0] != '#' and std.mem.len(lp) > 1) {
                            _ = hstsAdd(h, lp);
                        }
                    }
                }
                if (result != CURLE_OK or eof) break;
            }
            containers.curlx_dyn_free(@ptrCast(&buf));
        }
        _ = fclose(fp);
    }
    return result;
}

pub export fn Curl_hsts_loadcb(
    data: ?*anyopaque,
    h_opt: ?*Hsts,
    hsts_read_opt: ?HstsReadCallback,
    hsts_read_userp: ?*anyopaque,
) callconv(.c) c_uint {
    if (h_opt) |h| {
        return hstsPull(data, h, hsts_read_opt, hsts_read_userp);
    }
    return CURLE_OK;
}

pub export fn Curl_hsts_loadfiles(
    data: ?*anyopaque,
    h_opt: ?*Hsts,
    hstslist_opt: ?*containers.curl_slist,
) callconv(.c) c_uint {
    var result: c_uint = CURLE_OK;
    var l = hstslist_opt;
    if (l != null) {
        const h = h_opt orelse return CURLE_OK;
        _ = Curl_share_lock(data, CURL_LOCK_DATA_HSTS, CURL_LOCK_ACCESS_SINGLE);
        while (l) |node| {
            if (node.data) |file| {
                result = Curl_hsts_loadfile(data, h, file);
                if (result != CURLE_OK) break;
            }
            l = node.next;
        }
        _ = Curl_share_unlock(data, CURL_LOCK_DATA_HSTS);
    }
    return result;
}

pub export fn Curl_hsts_applies(h_opt: ?*Hsts, dest: *const CurlPeer) callconv(.c) bool {
    return hsts_check(h_opt, dest.hostname, std.mem.len(dest.hostname), true) != null;
}

// ============================================================================
// 4. lib/cf-setup.c — Connection Setup Filter
// ============================================================================

pub const CurlCftype = extern struct {
    name: [*:0]const u8,
    flags: c_int,
    log_level: c_int,
    destroy: ?*const fn (cf: *CurlCfilter, data: ?*anyopaque) callconv(.c) void,
    do_connect: ?*const fn (cf: *CurlCfilter, data: ?*anyopaque, done: *bool) callconv(.c) c_uint,
    do_shutdown: ?*const fn (cf: *CurlCfilter, data: ?*anyopaque, done: *bool) callconv(.c) c_uint,
    adjust_pollset: ?*const fn (cf: *CurlCfilter, data: ?*anyopaque, ps: ?*anyopaque) callconv(.c) c_uint,
    has_data_pending: ?*const fn (cf: *CurlCfilter, data: ?*const anyopaque) callconv(.c) bool,
    do_send: ?*const fn (cf: *CurlCfilter, data: ?*anyopaque, buf: [*]const u8, len: usize, eos: bool, pnwritten: *usize) callconv(.c) c_uint,
    do_recv: ?*const fn (cf: *CurlCfilter, data: ?*anyopaque, buf: [*]u8, len: usize, pnread: *usize) callconv(.c) c_uint,
    cntrl: ?*const fn (cf: *CurlCfilter, data: ?*anyopaque, event: c_int, arg1: c_int, arg2: ?*anyopaque) callconv(.c) c_uint,
    is_alive: ?*const fn (cf: *CurlCfilter, data: ?*anyopaque, input_pending: *bool) callconv(.c) bool,
    keep_alive: ?*const fn (cf: *CurlCfilter, data: ?*anyopaque) callconv(.c) c_uint,
    query: ?*const fn (cf: *CurlCfilter, data: ?*anyopaque, query: c_int, pres1: ?*c_int, pres2: ?*anyopaque) callconv(.c) c_uint,
};

pub const CurlCfilter = if (builtin.os.tag == .windows) extern struct {
    cft: *const CurlCftype,
    next: ?*CurlCfilter,
    ctx: ?*anyopaque,
    conn: ?*anyopaque,
    sockindex: i8,
    _pad: [3]u8 = .{ 0, 0, 0 },
    flags: u32,

    pub fn isConnected(self: *const CurlCfilter) bool {
        return (self.flags & 1) != 0;
    }
    pub fn setConnected(self: *CurlCfilter, val: bool) void {
        if (val) self.flags |= 1 else self.flags &= ~@as(u32, 1);
    }
} else extern struct {
    cft: *const CurlCftype,
    next: ?*CurlCfilter,
    ctx: ?*anyopaque,
    conn: ?*anyopaque,
    sockindex: i8,
    flags: u8,

    pub fn isConnected(self: *const CurlCfilter) bool {
        return (self.flags & 1) != 0;
    }
    pub fn setConnected(self: *CurlCfilter, val: bool) void {
        if (val) self.flags |= 1 else self.flags &= ~@as(u8, 1);
    }
};

extern fn Curl_cf_def_shutdown(cf: *CurlCfilter, data: ?*anyopaque, done: *bool) callconv(.c) c_uint;
extern fn Curl_cf_def_adjust_pollset(cf: *CurlCfilter, data: ?*anyopaque, ps: ?*anyopaque) callconv(.c) c_uint;
extern fn Curl_cf_def_data_pending(cf: *CurlCfilter, data: ?*const anyopaque) callconv(.c) bool;
extern fn Curl_cf_def_send(cf: *CurlCfilter, data: ?*anyopaque, buf: [*]const u8, len: usize, eos: bool, pnwritten: *usize) callconv(.c) c_uint;
extern fn Curl_cf_def_recv(cf: *CurlCfilter, data: ?*anyopaque, buf: [*]u8, len: usize, pnread: *usize) callconv(.c) c_uint;
extern fn Curl_cf_def_cntrl(cf: *CurlCfilter, data: ?*anyopaque, event: c_int, arg1: c_int, arg2: ?*anyopaque) callconv(.c) c_uint;
extern fn Curl_cf_def_conn_is_alive(cf: *CurlCfilter, data: ?*anyopaque, input_pending: *bool) callconv(.c) bool;
extern fn Curl_cf_def_conn_keep_alive(cf: *CurlCfilter, data: ?*anyopaque) callconv(.c) c_uint;
extern fn Curl_cf_def_query(cf: *CurlCfilter, data: ?*anyopaque, query: c_int, pres1: ?*c_int, pres2: ?*anyopaque) callconv(.c) c_uint;

extern fn Curl_cf_create(pcf: *?*CurlCfilter, cft: *const CurlCftype, ctx: ?*anyopaque) callconv(.c) c_uint;
extern fn Curl_conn_cf_add(data: ?*anyopaque, conn: ?*anyopaque, sockindex: i8, cf: *CurlCfilter) callconv(.c) void;
extern fn Curl_conn_cf_insert_after(cf_at: *CurlCfilter, cf_new: *CurlCfilter) callconv(.c) void;
extern fn Curl_conn_cf_connect(cf: *CurlCfilter, data: ?*anyopaque, done: *bool) callconv(.c) c_uint;
extern fn Curl_conn_cf_discard_chain(pcf: *?*CurlCfilter, data: ?*anyopaque) callconv(.c) void;
extern fn Curl_conn_is_ssl(conn: ?*anyopaque, sockindex: i8) callconv(.c) bool;

extern fn Curl_conn_get_origin(conn: ?*anyopaque, sockindex: i8) callconv(.c) ?*CurlPeer;
extern fn Curl_conn_get_destination(conn: ?*anyopaque, sockindex: i8) callconv(.c) ?*CurlPeer;
extern fn Curl_conn_get_first_peer(conn: ?*anyopaque, sockindex: i8) callconv(.c) ?*CurlPeer;

extern fn Curl_cf_haproxy_insert_after(cf_at: *CurlCfilter, data: ?*anyopaque) callconv(.c) c_uint;
extern fn Curl_cf_socks_proxy_insert_after(
    cf_at: *CurlCfilter,
    data: ?*anyopaque,
    dest: *CurlPeer,
    ip_version: u8,
    proxy_type: u8,
    creds: ?*anyopaque,
) callconv(.c) c_uint;
extern fn Curl_cf_http_proxy_insert_after(
    cf_at: *CurlCfilter,
    data: ?*anyopaque,
    peer: *CurlPeer,
    tunnel_peer: ?*CurlPeer,
    tunnel_transport: u8,
    proxytype: u8,
) callconv(.c) c_uint;
extern fn Curl_http_proxy_transport(proxytype: u8) callconv(.c) u8;
extern fn Curl_cf_ip_happy_insert_after(
    cf_at: *CurlCfilter,
    data: ?*anyopaque,
    origin: ?*CurlPeer,
    peer: *CurlPeer,
    transport_peer: u8,
    tunnel_peer: ?*CurlPeer,
    tunnel_transport: u8,
) callconv(.c) c_uint;
extern fn Curl_cf_ssl_insert_after(
    cf_at: *CurlCfilter,
    data: ?*anyopaque,
    origin: ?*CurlPeer,
    peer: ?*CurlPeer,
) callconv(.c) c_uint;
extern fn Curl_cf_ssl_proxy_insert_after(
    cf_at: *CurlCfilter,
    data: ?*anyopaque,
    peer: ?*CurlPeer,
) callconv(.c) c_uint;

const CfSetupState = enum(c_int) {
    init = 0,
    cnnct_eyeballs = 1,
    cnnct_socks = 2,
    cnnct_http_proxy = 3,
    cnnct_haproxy = 4,
    cnnct_ssl = 5,
    done = 6,
};

const CfSetupCtx = struct {
    state: CfSetupState,
    ssl_mode: c_int,
    transport: u8,
    retry_count: u8,
    socks_peer: ?*CurlPeer,
    socks_creds: ?*anyopaque,
    http_peer: ?*CurlPeer,
    socks_type: u8,
    http_type: u8,
    ip_version: u8,
    setup_flags: u8,
};

fn cfSetupAddHaproxy(cf: *CurlCfilter, data: ?*anyopaque) c_uint {
    const ctx: *CfSetupCtx = @ptrCast(@alignCast(cf.ctx.?));
    var result: c_uint = CURLE_OK;

    if (@backingInt(ctx.state) < @backingInt(CfSetupState.cnnct_haproxy)) {
        if ((ctx.setup_flags & 4) != 0) {
            if (ctx.transport == TRNSPRT_QUIC) {
                Curl_failf(data, "haproxy protocol does not support QUIC");
                return CURLE_UNSUPPORTED_PROTOCOL;
            }
            result = Curl_cf_haproxy_insert_after(cf, data);
            if (result != CURLE_OK) {
                if (Curl_trc_cf_is_verbose(cf, data)) {
                    Curl_trc_cf_infof(data, cf, "adding HAPROXY filter failed -> %d", @as(c_int, @intCast(result)));
                }
                return result;
            }
            if (Curl_trc_cf_is_verbose(cf, data)) {
                Curl_trc_cf_infof(data, cf, "added HAPROXY filter");
            }
        }
        ctx.state = .cnnct_haproxy;
    }
    return result;
}

fn cfSetupAddSocks(cf: *CurlCfilter, data: ?*anyopaque) c_uint {
    const ctx: *CfSetupCtx = @ptrCast(@alignCast(cf.ctx.?));
    var result: c_uint = CURLE_OK;

    if (@backingInt(ctx.state) < @backingInt(CfSetupState.cnnct_socks) and ctx.socks_peer != null) {
        const second_peer_opt: ?*CurlPeer = if (ctx.http_peer) |hp|
            hp
        else
            Curl_conn_get_destination(cf.conn, cf.sockindex);
        const second_peer = second_peer_opt orelse return CURLE_FAILED_INIT;

        result = Curl_cf_socks_proxy_insert_after(
            cf,
            data,
            second_peer,
            ctx.ip_version,
            ctx.socks_type,
            ctx.socks_creds,
        );
        if (result != CURLE_OK) {
            if (Curl_trc_cf_is_verbose(cf, data)) {
                Curl_trc_cf_infof(data, cf, "adding SOCKS filter failed -> %d", @as(c_int, @intCast(result)));
            }
            return result;
        }
        if (Curl_trc_cf_is_verbose(cf, data)) {
            Curl_trc_cf_infof(data, cf, "added SOCKS filter to %s:%u", second_peer.hostname, @as(c_uint, second_peer.port));
        }
        ctx.state = .cnnct_socks;
    }
    return result;
}

fn cfSetupAddHttpProxy(cf: *CurlCfilter, data: ?*anyopaque) c_uint {
    const ctx: *CfSetupCtx = @ptrCast(@alignCast(cf.ctx.?));
    var result: c_uint = CURLE_OK;

    if (@backingInt(ctx.state) < @backingInt(CfSetupState.cnnct_http_proxy) and
        ctx.http_peer != null and (ctx.setup_flags & 1) == 0)
    {
        const peer = ctx.http_peer.?;
        const tunnel_peer = Curl_conn_get_destination(cf.conn, cf.sockindex);

        if ((ctx.setup_flags & 8) != 0 and
            isHttpsProxy(ctx.http_type) and
            !Curl_conn_is_ssl(cf.conn, cf.sockindex))
        {
            result = Curl_cf_ssl_proxy_insert_after(cf, data, peer);
            if (result != CURLE_OK) {
                if (Curl_trc_cf_is_verbose(cf, data)) {
                    Curl_trc_cf_infof(data, cf, "adding SSL filter for HTTP proxy failed -> %d", @as(c_int, @intCast(result)));
                }
                return result;
            }
            if (Curl_trc_cf_is_verbose(cf, data)) {
                Curl_trc_cf_infof(data, cf, "added SSL filter for HTTP proxy");
            }
        }

        result = Curl_cf_http_proxy_insert_after(cf, data, peer, tunnel_peer, ctx.transport, ctx.http_type);
        if (result != CURLE_OK) {
            if (Curl_trc_cf_is_verbose(cf, data)) {
                Curl_trc_cf_infof(data, cf, "adding HTTP proxy tunnel filter failed -> %d", @as(c_int, @intCast(result)));
            }
            return result;
        }
        if (Curl_trc_cf_is_verbose(cf, data)) {
            Curl_trc_cf_infof(data, cf, "added HTTP proxy tunnel filter");
        }
        ctx.state = .cnnct_http_proxy;
    }
    return result;
}

fn connGetFirstOrigin(ctx: *const CfSetupCtx, conn: ?*anyopaque, sockindex: i8) ?*CurlPeer {
    if (ctx.socks_peer) |sp| return sp;
    if (ctx.http_peer) |hp| return hp;
    return Curl_conn_get_origin(conn, sockindex);
}

fn cfSetupAddIpHappy(cf: *CurlCfilter, data: ?*anyopaque) c_uint {
    const ctx: *CfSetupCtx = @ptrCast(@alignCast(cf.ctx.?));
    var result: c_uint = CURLE_OK;

    if (@backingInt(ctx.state) < @backingInt(CfSetupState.cnnct_eyeballs)) {
        const first_origin = connGetFirstOrigin(ctx, cf.conn, cf.sockindex);
        const first_peer = Curl_conn_get_first_peer(cf.conn, cf.sockindex) orelse return CURLE_FAILED_INIT;
        var tunnel_peer: ?*CurlPeer = null;
        var first_transport = ctx.transport;

        if (ctx.http_peer != null and (ctx.setup_flags & 1) == 0) {
            first_transport = Curl_http_proxy_transport(ctx.http_type);
            tunnel_peer = Curl_conn_get_destination(cf.conn, cf.sockindex);
            if (first_transport == TRNSPRT_QUIC and ctx.socks_peer != null) {
                Curl_failf(data, "HTTP/3 proxy not possible via SOCKS");
                return CURLE_UNSUPPORTED_PROTOCOL;
            }
        }

        result = Curl_cf_ip_happy_insert_after(
            cf,
            data,
            first_origin,
            first_peer,
            first_transport,
            tunnel_peer,
            ctx.transport,
        );
        if (result != CURLE_OK) {
            if (Curl_trc_cf_is_verbose(cf, data)) {
                Curl_trc_cf_infof(data, cf, "adding happy eyeballs failed -> %d", @as(c_int, @intCast(result)));
            }
            return result;
        }

        if (tunnel_peer != null and first_transport == TRNSPRT_QUIC) {
            if (Curl_trc_cf_is_verbose(cf, data)) {
                Curl_trc_cf_infof(data, cf, "happy eyeballing to HTTP/3 proxy %s:%u", first_peer.hostname, @as(c_uint, first_peer.port));
            }
            ctx.state = .cnnct_http_proxy;
        } else {
            if (Curl_trc_cf_is_verbose(cf, data)) {
                const kind: [*:0]const u8 = if (tunnel_peer != null) "proxy" else "origin";
                Curl_trc_cf_infof(data, cf, "happy eyeballing to %s %s:%u", kind, first_peer.hostname, @as(c_uint, first_peer.port));
            }
            ctx.state = .cnnct_eyeballs;
        }
    }
    return result;
}

fn cfSetupAddOriginFilters(cf: *CurlCfilter, data: ?*anyopaque) c_uint {
    const ctx: *CfSetupCtx = @ptrCast(@alignCast(cf.ctx.?));
    var result: c_uint = CURLE_OK;

    if (@backingInt(ctx.state) < @backingInt(CfSetupState.cnnct_ssl)) {
        if ((ctx.setup_flags & 8) != 0) {
            const proto_ssl = (ctx.setup_flags & 2) != 0;
            if ((ctx.ssl_mode == CURL_CF_SSL_ENABLE or
                (ctx.ssl_mode != CURL_CF_SSL_DISABLE and proto_ssl)) and
                !Curl_conn_is_ssl(cf.conn, cf.sockindex))
            {
                if ((ctx.setup_flags & 1) != 0) {
                    result = Curl_cf_ssl_proxy_insert_after(cf, data, Curl_conn_get_origin(cf.conn, FIRSTSOCKET));
                } else {
                    result = Curl_cf_ssl_insert_after(
                        cf,
                        data,
                        Curl_conn_get_origin(cf.conn, FIRSTSOCKET),
                        Curl_conn_get_destination(cf.conn, FIRSTSOCKET),
                    );
                }
                if (result != CURLE_OK) {
                    if (Curl_trc_cf_is_verbose(cf, data)) {
                        Curl_trc_cf_infof(data, cf, "adding SSL filter for origin failed -> %d", @as(c_int, @intCast(result)));
                    }
                    return result;
                }
                if (Curl_trc_cf_is_verbose(cf, data)) {
                    Curl_trc_cf_infof(data, cf, "added SSL filter for origin");
                }
            }
        }
        ctx.state = .cnnct_ssl;
    }
    return result;
}

fn cfSetupConnectSteps(cf: *CurlCfilter, data: ?*anyopaque, done: *bool) c_uint {
    const ctx: *CfSetupCtx = @ptrCast(@alignCast(cf.ctx.?));
    var result: c_uint = CURLE_OK;

    if (cf.isConnected()) {
        done.* = true;
        return CURLE_OK;
    }

    while (true) {
        Curl_conn_trc_filters(data, cf.sockindex, "cf_setup_connect");

        if (cf.next) |next_cf| {
            if (!next_cf.isConnected()) {
                result = Curl_conn_cf_connect(next_cf, data, done);
                if (result != CURLE_OK or !done.*) return result;
            }
        }

        result = cfSetupAddIpHappy(cf, data);
        if (result != CURLE_OK) return result;
        if (cf.next == null or !cf.next.?.isConnected()) continue;

        result = cfSetupAddSocks(cf, data);
        if (result != CURLE_OK) return result;
        if (cf.next == null or !cf.next.?.isConnected()) continue;

        result = cfSetupAddHttpProxy(cf, data);
        if (result != CURLE_OK) return result;
        if (cf.next == null or !cf.next.?.isConnected()) continue;

        result = cfSetupAddHaproxy(cf, data);
        if (result != CURLE_OK) return result;
        if (cf.next == null or !cf.next.?.isConnected()) continue;

        result = cfSetupAddOriginFilters(cf, data);
        if (result != CURLE_OK) return result;
        if (cf.next == null or !cf.next.?.isConnected()) continue;

        break;
    }

    ctx.state = .done;
    cf.setConnected(true);
    done.* = true;
    return CURLE_OK;
}

fn cfSetupConnect(cf: *CurlCfilter, data: ?*anyopaque, done: *bool) callconv(.c) c_uint {
    const ctx: *CfSetupCtx = @ptrCast(@alignCast(cf.ctx.?));
    while (true) {
        const result = cfSetupConnectSteps(cf, data, done);
        if (result == CURLE_AGAIN) {
            ctx.retry_count += 1;
            if (ctx.retry_count > 5) return CURLE_COULDNT_CONNECT;
            if (Curl_trc_cf_is_verbose(cf, data)) {
                Curl_trc_cf_infof(data, cf, "retrying connect, %d. time", @as(c_int, ctx.retry_count));
            }
            Curl_conn_cf_discard_chain(&cf.next, data);
            ctx.state = .init;
            continue;
        }
        return result;
    }
}

fn cfSetupDestroy(cf: *CurlCfilter, data: ?*anyopaque) callconv(.c) void {
    if (Curl_trc_cf_is_verbose(cf, data)) {
        Curl_trc_cf_infof(data, cf, "destroy");
    }
    mem.free(cf.ctx);
    cf.ctx = null;
}

pub export var Curl_cft_setup: CurlCftype = .{
    .name = "SETUP",
    .flags = CF_TYPE_SETUP,
    .log_level = CURL_LOG_LVL_NONE,
    .destroy = cfSetupDestroy,
    .do_connect = cfSetupConnect,
    .do_shutdown = Curl_cf_def_shutdown,
    .adjust_pollset = Curl_cf_def_adjust_pollset,
    .has_data_pending = Curl_cf_def_data_pending,
    .do_send = Curl_cf_def_send,
    .do_recv = Curl_cf_def_recv,
    .cntrl = Curl_cf_def_cntrl,
    .is_alive = Curl_cf_def_conn_is_alive,
    .keep_alive = Curl_cf_def_conn_keep_alive,
    .query = Curl_cf_def_query,
};

fn cfSetupCreate(
    pcf: *?*CurlCfilter,
    transport: u8,
    ssl_mode: c_int,
    socks_peer: ?*CurlPeer,
    socks_creds: ?*anyopaque,
    http_peer: ?*CurlPeer,
    socks_type: u8,
    http_type: u8,
    ip_version: u8,
    setup_flags: u8,
) c_uint {
    var cf: ?*CurlCfilter = null;
    const raw = mem.calloc(1, @sizeOf(CfSetupCtx)) orelse {
        pcf.* = null;
        return CURLE_OUT_OF_MEMORY;
    };
    const ctx: *CfSetupCtx = @ptrCast(@alignCast(raw));
    ctx.* = .{
        .state = .init,
        .ssl_mode = ssl_mode,
        .transport = transport,
        .retry_count = 0,
        .socks_peer = socks_peer,
        .socks_creds = socks_creds,
        .http_peer = http_peer,
        .socks_type = socks_type,
        .http_type = http_type,
        .ip_version = ip_version,
        .setup_flags = setup_flags,
    };

    const result = Curl_cf_create(&cf, &Curl_cft_setup, ctx);
    if (result != CURLE_OK) {
        mem.free(ctx);
        pcf.* = null;
        return result;
    }
    pcf.* = cf;
    return CURLE_OK;
}

pub export fn Curl_cf_setup_add(
    data: ?*anyopaque,
    conn: ?*anyopaque,
    sockindex: i8,
    transport: u8,
    ssl_mode: c_int,
    socks_peer: ?*CurlPeer,
    socks_creds: ?*anyopaque,
    http_peer: ?*CurlPeer,
    socks_type: u8,
    http_type: u8,
    ip_version: u8,
    setup_flags: u8,
) callconv(.c) c_uint {
    var cf: ?*CurlCfilter = null;
    const result = cfSetupCreate(
        &cf,
        transport,
        ssl_mode,
        socks_peer,
        socks_creds,
        http_peer,
        socks_type,
        http_type,
        ip_version,
        setup_flags,
    );
    if (result != CURLE_OK) return result;
    Curl_conn_cf_add(data, conn, sockindex, cf.?);
    return CURLE_OK;
}

pub export fn Curl_cf_setup_insert_after(
    cf_at: *CurlCfilter,
    data: ?*anyopaque,
    transport: u8,
    ssl_mode: c_int,
    socks_peer: ?*CurlPeer,
    socks_creds: ?*anyopaque,
    http_peer: ?*CurlPeer,
    socks_type: u8,
    http_type: u8,
    ip_version: u8,
    setup_flags: u8,
) callconv(.c) c_uint {
    _ = data;
    var cf: ?*CurlCfilter = null;
    const result = cfSetupCreate(
        &cf,
        transport,
        ssl_mode,
        socks_peer,
        socks_creds,
        http_peer,
        socks_type,
        http_type,
        ip_version,
        setup_flags,
    );
    if (result != CURLE_OK) return result;
    Curl_conn_cf_insert_after(cf_at, cf.?);
    return CURLE_OK;
}

// ============================================================================
// 5. lib/multi_ntfy.c — Multi Notification Dispatch
// ============================================================================

const CURL_MNTFY_CHUNK_SIZE: usize = 128;
const CURL_CBAPI_FN_multi_ntfy_cb: c_int = 150;

pub const CurlNotifyCallback = *const fn (m: ?*anyopaque, notification: c_uint, easy: ?*anyopaque, user_data: ?*anyopaque) callconv(.c) void;

pub const MntfyEntry = extern struct {
    mid: u32,
    type: u32,
};

pub const MntfyChunk = extern struct {
    next: ?*MntfyChunk,
    r_offset: usize,
    w_offset: usize,
    entries: [CURL_MNTFY_CHUNK_SIZE]MntfyEntry,
};

pub const CurlMultiNtfy = extern struct {
    ntfy_cb: ?CurlNotifyCallback,
    ntfy_cb_data: ?*anyopaque,
    head: ?*MntfyChunk,
    tail: ?*MntfyChunk,
    flags: u32,
    failure: c_int,
};

const CurlMapiGuard = extern struct {
    multi: ?*anyopaque,
    depth: u8,
};

extern fn Curl_multi_get_easy(multi: ?*anyopaque, mid: u32) callconv(.c) ?*anyopaque;
extern fn Curl_cbapi_enter(guard: *CurlMapiGuard, data: ?*anyopaque, multi: ?*anyopaque, fn_id: c_int) callconv(.c) void;
extern fn Curl_cbapi_leave(guard: *CurlMapiGuard) callconv(.c) void;

fn mntfyTypeFlag(t: u32) u32 {
    return @as(u32, 1) << @intCast(t);
}

fn mntfyChunkCreate() ?*MntfyChunk {
    const raw = mem.calloc(1, @sizeOf(MntfyChunk)) orelse return null;
    return @ptrCast(@alignCast(raw));
}

fn mntfyChunkDestroy(chunk: ?*MntfyChunk) void {
    mem.free(chunk);
}

fn mntfyChunkReset(chunk: *MntfyChunk) void {
    chunk.r_offset = 0;
    chunk.w_offset = 0;
}

fn mntfyChunkAppend(chunk: *MntfyChunk, mid: u32, t: u32) bool {
    if (chunk.w_offset >= CURL_MNTFY_CHUNK_SIZE) return false;
    chunk.entries[chunk.w_offset] = .{ .mid = mid, .type = t };
    chunk.w_offset += 1;
    return true;
}

fn mntfyNonFullTail(mntfy: *CurlMultiNtfy) ?*MntfyChunk {
    if (mntfy.tail == null) {
        const chunk = mntfyChunkCreate() orelse return null;
        mntfy.head = chunk;
        mntfy.tail = chunk;
        return chunk;
    } else if (mntfy.tail.?.w_offset < CURL_MNTFY_CHUNK_SIZE) {
        return mntfy.tail;
    } else {
        const chunk = mntfyChunkCreate() orelse return null;
        mntfy.tail.?.next = chunk;
        mntfy.tail = chunk;
        return chunk;
    }
}

fn mntfyChunkDispatchAll(multi: ?*anyopaque, ntfy: *CurlMultiNtfy, admin: ?*anyopaque, chunk: *MntfyChunk) void {
    while (ntfy.ntfy_cb != null and chunk.r_offset < chunk.w_offset and ntfy.failure == CURLM_OK) {
        const e = chunk.entries[chunk.r_offset];
        const data = if (e.mid != 0) Curl_multi_get_easy(multi, e.mid) else admin;
        if (data != null and (ntfy.flags & mntfyTypeFlag(e.type)) != 0) {
            if (ntfy.ntfy_cb) |cb| {
                cb(multi, e.type, data, ntfy.ntfy_cb_data);
            }
        }
        chunk.r_offset += 1;
    }
    mntfyChunkReset(chunk);
}

pub export fn Curl_mntfy_init(multi: ?*anyopaque, ntfy_opt: ?*CurlMultiNtfy) callconv(.c) void {
    _ = multi;
    const ntfy = ntfy_opt orelse return;
    ntfy.* = .{
        .ntfy_cb = null,
        .ntfy_cb_data = null,
        .head = null,
        .tail = null,
        .flags = 0,
        .failure = CURLM_OK,
    };
}

pub export fn Curl_mntfy_cleanup(multi: ?*anyopaque, ntfy_opt: ?*CurlMultiNtfy) callconv(.c) void {
    _ = multi;
    const ntfy = ntfy_opt orelse return;
    while (ntfy.head) |chunk| {
        ntfy.head = chunk.next;
        mntfyChunkDestroy(chunk);
    }
    ntfy.tail = null;
}

pub export fn Curl_mntfy_enable(multi: ?*anyopaque, ntfy_opt: ?*CurlMultiNtfy, t: c_uint) callconv(.c) c_int {
    _ = multi;
    const ntfy = ntfy_opt orelse return CURLM_BAD_FUNCTION_ARGUMENT;
    if (t >= CURLMNOTIFY_LAST) return CURLM_UNKNOWN_OPTION;
    ntfy.flags |= mntfyTypeFlag(t);
    return CURLM_OK;
}

pub export fn Curl_mntfy_disable(multi: ?*anyopaque, ntfy_opt: ?*CurlMultiNtfy, t: c_uint) callconv(.c) c_int {
    _ = multi;
    const ntfy = ntfy_opt orelse return CURLM_BAD_FUNCTION_ARGUMENT;
    if (t >= CURLMNOTIFY_LAST) return CURLM_UNKNOWN_OPTION;
    ntfy.flags &= ~mntfyTypeFlag(t);
    return CURLM_OK;
}

pub export fn Curl_mntfy_add(data: ?*anyopaque, ntfy_opt: ?*CurlMultiNtfy, mid: u32, t: c_uint) callconv(.c) void {
    _ = data;
    const ntfy = ntfy_opt orelse return;
    if (ntfy.ntfy_cb != null and ntfy.failure == CURLM_OK and
        t < CURLMNOTIFY_LAST and
        (ntfy.flags & mntfyTypeFlag(t)) != 0)
    {
        if (mntfyNonFullTail(ntfy)) |tail| {
            _ = mntfyChunkAppend(tail, mid, t);
        } else {
            ntfy.failure = CURLM_OUT_OF_MEMORY;
        }
        ntfy.flags |= CURL_MNTFY_FLAG_HAS_ENTRIES;
    }
}

pub export fn Curl_mntfy_dispatch_all(multi: ?*anyopaque, ntfy_opt: ?*CurlMultiNtfy, admin: ?*anyopaque) callconv(.c) c_int {
    if (multi == null) return CURLM_BAD_FUNCTION_ARGUMENT;
    const ntfy = ntfy_opt orelse return CURLM_BAD_FUNCTION_ARGUMENT;

    var guard: CurlMapiGuard = .{ .multi = null, .depth = 0 };
    Curl_cbapi_enter(&guard, null, multi, CURL_CBAPI_FN_multi_ntfy_cb);

    while (ntfy.head != null and ntfy.failure == CURLM_OK) {
        const chunk = ntfy.head.?;
        mntfyChunkDispatchAll(multi, ntfy, admin, chunk);
        if (chunk == ntfy.tail) break;
        ntfy.head = chunk.next;
        mntfyChunkDestroy(chunk);
    }

    Curl_cbapi_leave(&guard);

    if (ntfy.failure != CURLM_OK) {
        const mresult = ntfy.failure;
        ntfy.failure = CURLM_OK;
        return mresult;
    } else {
        ntfy.flags &= ~CURL_MNTFY_FLAG_HAS_ENTRIES;
    }
    return CURLM_OK;
}

// ============================================================================
// Unit Tests
// ============================================================================

test "Curl_altsvc_init, Curl_altsvc_parse, Curl_altsvc_lookup, Curl_altsvc_cleanup" {
    var asi: ?*Altsvcinfo = Curl_altsvc_init();
    try std.testing.expect(asi != null);
    defer Curl_altsvc_cleanup(&asi);

    try std.testing.expectEqualStrings("h1", std.mem.span(Curl_alpnid2str(ALPN_h1)));
    try std.testing.expectEqualStrings("h2", std.mem.span(Curl_alpnid2str(ALPN_h2)));
    try std.testing.expectEqualStrings("h3", std.mem.span(Curl_alpnid2str(ALPN_h3)));

    var peer: ?*CurlPeer = null;
    try std.testing.expectEqual(CURLE_OK, Curl_peer_create(null, &Curl_scheme_https, "example.com", 443, &peer));
    try std.testing.expect(peer != null);
    defer Curl_peer_unlink(&peer);

    try std.testing.expectEqual(
        CURLE_OK,
        Curl_altsvc_parse(null, asi.?, "h2=\"alt.example.com:8443\"; ma=3600; persist=1", peer.?, ALPN_h1),
    );

    var dst: ?*Altsvc = null;
    var same_dest = true;
    try std.testing.expect(Curl_altsvc_lookup(asi.?, peer.?, ALPN_h1, &dst, @intCast(ALPN_h2), &same_dest));
    try std.testing.expect(dst != null);
    try std.testing.expect(!same_dest);
    try std.testing.expectEqual(@as(u16, 8443), dst.?.dst.port);
    try std.testing.expectEqual(ALPN_h2, dst.?.dst.alpnid);
    try std.testing.expectEqualStrings("alt.example.com", std.mem.span(dst.?.dst.host.?));

    // "clear" flushes cached alternatives for origin
    try std.testing.expectEqual(CURLE_OK, Curl_altsvc_parse(null, asi.?, "clear", peer.?, ALPN_h1));
    try std.testing.expect(!Curl_altsvc_lookup(asi.?, peer.?, ALPN_h1, &dst, @intCast(ALPN_h2), &same_dest));
}

test "Curl_hsts_init, Curl_hsts_parse, Curl_hsts, Curl_hsts_cleanup" {
    var h: ?*Hsts = Curl_hsts_init();
    try std.testing.expect(h != null);
    defer Curl_hsts_cleanup(&h);

    try std.testing.expectEqual(
        CURLE_OK,
        Curl_hsts_parse(h.?, "example.com", "max-age=31536000; includeSubDomains"),
    );

    const exact = Curl_hsts(h, "example.com", "example.com".len, false);
    try std.testing.expect(exact != null);
    try std.testing.expect((exact.?.includeSubDomains & 1) != 0);

    const sub = Curl_hsts(h, "sub.example.com", "sub.example.com".len, true);
    try std.testing.expect(sub != null);

    const nosub = Curl_hsts(h, "sub.example.com", "sub.example.com".len, false);
    try std.testing.expect(nosub == null);

    // max-age=0 removes the entry
    try std.testing.expectEqual(CURLE_OK, Curl_hsts_parse(h.?, "example.com", "max-age=0"));
    try std.testing.expect(Curl_hsts(h, "example.com", "example.com".len, false) == null);
}

test "Curl_peer_create, Curl_peer_equal, Curl_peer_link, Curl_peer_unlink" {
    var p1: ?*CurlPeer = null;
    var p2: ?*CurlPeer = null;
    defer Curl_peer_unlink(&p1);
    defer Curl_peer_unlink(&p2);

    try std.testing.expectEqual(CURLE_OK, Curl_peer_create(null, &Curl_scheme_https, "Example.COM", 443, &p1));
    try std.testing.expectEqual(CURLE_OK, Curl_peer_create(null, &Curl_scheme_https, "example.com", 443, &p2));
    try std.testing.expect(Curl_peer_equal(p1, p2));

    var linked: ?*CurlPeer = null;
    Curl_peer_link(&linked, p1);
    try std.testing.expectEqual(@as(u32, 2), p1.?.refcount);
    Curl_peer_unlink(&linked);
    try std.testing.expect(linked == null);
    try std.testing.expectEqual(@as(u32, 1), p1.?.refcount);
}
