const std = @import("std");
const builtin = @import("builtin");
const mem = @import("mem.zig");
const primitives = @import("primitives.zig");
const containers = @import("containers.zig");
const collections = @import("collections.zig");
const crypto = @import("crypto.zig");
const threads_psl = @import("threads_psl.zig");
const http1_options = @import("http1_options.zig");
const vtls_core = @import("vtls_core.zig");
const base64 = @import("curlx_parse.zig");

extern fn curlx_dyn_addf(s: *containers.dynbuf, fmt: [*:0]const u8, ...) callconv(.c) CURLcode;
extern fn curl_msnprintf(buffer: ?[*]u8, maxlength: usize, format: [*:0]const u8, ...) callconv(.c) c_int;

fn memdup(src_opt: ?[*]const u8, len: usize) ?[*]u8 {
    const src = src_opt orelse return null;
    const dst = mem.malloc(len) orelse return null;
    if (len > 0) {
        @memcpy(dst[0..len], src[0..len]);
    }
    return dst;
}

const CURLcode = c_uint;
const CURLE_OK: CURLcode = 0;
const CURLE_FAILED_INIT: CURLcode = 2;
const CURLE_WEIRD_SERVER_REPLY: CURLcode = 8;
const CURLE_OUT_OF_MEMORY: CURLcode = 27;
const CURLE_BAD_FUNCTION_ARGUMENT: CURLcode = 43;
const CURLE_PEER_FAILED_VERIFICATION: CURLcode = 60;

const curl_off_t = i64;
const dynbuf = containers.dynbuf;
const Curl_llist = containers.Curl_llist;
const Curl_llist_node = containers.Curl_llist_node;
const CurlBlob = vtls_core.CurlBlob;
const CurlSslSession = vtls_core.CurlSslSession;
const CurlMutex = threads_psl.CurlMutex;
const curl_thread_id_t = threads_psl.curl_thread_id_t;

const CURLSSLBACKEND_SCHANNEL: c_uint = 8;

const CURLSSLOPT_ALLOW_BEAST: u8 = 1 << 0;
const CURLSSLOPT_NO_REVOKE: u8 = 1 << 1;
const CURLSSLOPT_NO_PARTIALCHAIN: u8 = 1 << 2;
const CURLSSLOPT_REVOKE_BEST_EFFORT: u8 = 1 << 3;
const CURLSSLOPT_NATIVE_CA: u8 = 1 << 4;
const CURLSSLOPT_AUTO_CLIENT_CERT: u8 = 1 << 5;
const CURLSSLOPT_EARLYDATA: u8 = 1 << 6;

const STRING_CERT: u8 = 0;
const STRING_CERT_TYPE: u8 = 1;
const STRING_KEY: u8 = 2;
const STRING_KEY_PASSWD: u8 = 3;
const STRING_KEY_TYPE: u8 = 4;
const STRING_SSL_CAPATH: u8 = 5;
const STRING_SSL_CAFILE: u8 = 6;
const STRING_SSL_PINNEDPUBLICKEY: u8 = 7;
const STRING_SSL_CIPHER_LIST: u8 = 8;
const STRING_SSL_CIPHER13_LIST: u8 = 9;
const STRING_SSL_CRLFILE: u8 = 10;
const STRING_SSL_ISSUERCERT: u8 = 11;
const STRING_CERT_PROXY: u8 = 13;
const STRING_CERT_TYPE_PROXY: u8 = 14;
const STRING_KEY_PROXY: u8 = 15;
const STRING_KEY_PASSWD_PROXY: u8 = 16;
const STRING_KEY_TYPE_PROXY: u8 = 17;
const STRING_SSL_CAPATH_PROXY: u8 = 18;
const STRING_SSL_CAFILE_PROXY: u8 = 19;
const STRING_SSL_PINNEDPUBLICKEY_PROXY: u8 = 20;
const STRING_SSL_CIPHER_LIST_PROXY: u8 = 21;
const STRING_SSL_CIPHER13_LIST_PROXY: u8 = 22;
const STRING_SSL_CRLFILE_PROXY: u8 = 23;
const STRING_SSL_ISSUERCERT_PROXY: u8 = 24;

const BLOB_CERT: usize = 0;
const BLOB_KEY: usize = 1;
const BLOB_SSL_ISSUERCERT: usize = 2;
const BLOB_CAINFO: usize = 3;
const BLOB_CERT_PROXY: usize = 4;
const BLOB_KEY_PROXY: usize = 5;
const BLOB_SSL_ISSUERCERT_PROXY: usize = 6;
const BLOB_CAINFO_PROXY: usize = 7;

const TRNSPRT_TCP: u8 = 3;
const TRNSPRT_UDP: u8 = 4;
const TRNSPRT_QUIC: u8 = 5;
const TRNSPRT_UNIX: u8 = 6;

const CURL_IETF_PROTO_TLS1_3: c_int = 0x0304;
const CURL_SCACHE_MAX_13_LIFETIME_SEC: curl_off_t = 60 * 60 * 24 * 7;
const CURL_SCACHE_MAX_12_LIFETIME_SEC: curl_off_t = 60 * 60 * 24;
const CURL_SHA256_DIGEST_LENGTH: usize = 32;
const CURL_SSL_TICKET_MAX: usize = 16 * 1024;
const CURL_X509_STR_MAX: usize = 100000;
const CURL_ASN1_MAX: usize = 0x40000;
const CURL_ASN1_MAX_RECURSIONS: usize = 16;

const CURL_LOCK_DATA_SSL_SESSION: c_uint = 4;
const CURL_LOCK_ACCESS_SINGLE: c_uint = 2;
const CURL_LOG_LVL_INFO: c_int = 1;

pub const CurlTrcFeat = extern struct {
    name: [*:0]const u8,
    log_level: c_int,
};

const c_ext = struct {
    extern "c" fn Curl_ssl_backend() c_uint;
    extern "c" fn Curl_setstropt(data: ?*anyopaque, option: c_uint, s: ?[*:0]const u8) CURLcode;
    extern "c" fn Curl_peer_equal(p1: ?*const anyopaque, p2: ?*const anyopaque) bool;
    extern "c" fn Curl_share_lock(data: ?*anyopaque, lock_type: c_uint, accesstype: c_uint) c_uint;
    extern "c" fn Curl_share_unlock(data: ?*anyopaque, lock_type: c_uint) c_uint;
    extern "c" fn Curl_failf(data: ?*anyopaque, fmt: [*:0]const u8, ...) void;
    extern "c" fn Curl_infof(data: ?*anyopaque, fmt: [*:0]const u8, ...) void;
    extern "c" fn Curl_trc_feat_infof(data: ?*anyopaque, feat: *CurlTrcFeat, fmt: [*:0]const u8, ...) void;
    extern "c" fn free(ptr: ?*anyopaque) void;
    extern "c" fn time(tloc: ?*anyopaque) i64;
    extern "c" fn realpath(path: [*:0]const u8, resolved_path: ?[*]u8) ?[*:0]u8;
    extern "c" fn _fullpath(absPath: ?[*]u8, relPath: [*:0]const u8, maxLength: usize) ?[*:0]u8;
};

inline fn trcSsls(data: ?*anyopaque, feat: ?*CurlTrcFeat, comptime fmt: [*:0]const u8, args: anytype) void {
    if (builtin.output_mode == .Lib) {
        if (data != null) {
            if (feat) |f| {
                if (f.log_level >= CURL_LOG_LVL_INFO) {
                    @call(.auto, c_ext.Curl_trc_feat_infof, .{ data, f, fmt } ++ args);
                }
            }
        }
    }
}

inline fn failf(data: ?*anyopaque, comptime fmt: [*:0]const u8, args: anytype) void {
    if (builtin.output_mode == .Lib) {
        if (data != null) {
            @call(.auto, c_ext.Curl_failf, .{ data, fmt } ++ args);
        }
    }
}

inline fn infof(data: ?*anyopaque, comptime fmt: [*:0]const u8, args: anytype) void {
    if (builtin.output_mode == .Lib) {
        if (data != null) {
            @call(.auto, c_ext.Curl_infof, .{ data, fmt } ++ args);
        }
    }
}

inline fn nowEpochSecs() curl_off_t {
    return @intCast(c_ext.time(null));
}

// ============================================================================
// 1. lib/vtls/vtls_config.c (lib/vtls/vtls_config.h)
// ============================================================================

const FilterFlagsType = if (builtin.os.tag == .windows) u32 else u16;
const EasyFlagsType = if (builtin.os.tag == .windows) u32 else u16;

pub const SslFilterConfig = extern struct {
    CApath: ?[*:0]u8,
    CAfile: ?[*:0]u8,
    issuercert: ?[*:0]u8,
    clientcert: ?[*:0]u8,
    cipher_list: ?[*:0]u8,
    cipher_list13: ?[*:0]u8,
    signature_algorithms: ?[*:0]u8,
    pinned_key: ?[*:0]u8,
    CRLfile: ?[*:0]u8,
    cert_type: ?[*:0]u8,
    key: ?[*:0]u8,
    key_type: ?[*:0]u8,
    key_passwd: ?[*:0]u8,
    cert_blob: ?*CurlBlob,
    ca_info_blob: ?*CurlBlob,
    issuercert_blob: ?*CurlBlob,
    key_blob: ?*CurlBlob,
    curves: ?[*:0]u8,
    version_max: u32,
    ssl_options: u8,
    version: u8,
    _win_pad: if (builtin.os.tag == .windows) [2]u8 else [0]u8 = if (builtin.os.tag == .windows) .{ 0, 0 } else .{},
    flags: FilterFlagsType,

    const BIT_VERIFYPEER: FilterFlagsType = 1 << 0;
    const BIT_VERIFYHOST: FilterFlagsType = 1 << 1;
    const BIT_VERIFYSTATUS: FilterFlagsType = 1 << 2;
    const BIT_NATIVE_CA_STORE: FilterFlagsType = 1 << 3;
    const BIT_CACHE_SESSION: FilterFlagsType = 1 << 4;
    const BIT_DEEP_COPY: FilterFlagsType = 1 << 5;
    const BIT_EARLYDATA: FilterFlagsType = 1 << 6;
    const BIT_AUTO_CLIENT_CERT: FilterFlagsType = 1 << 7;
    const BIT_ENABLE_BEAST: FilterFlagsType = 1 << 8;
    const BIT_NO_PARTIALCHAIN: FilterFlagsType = 1 << 9;
    const BIT_NO_REVOKE: FilterFlagsType = 1 << 10;
    const BIT_REVOKE_BEST_EFFORT: FilterFlagsType = 1 << 11;

    pub inline fn getFlag(self: *const SslFilterConfig, mask: FilterFlagsType) bool {
        return (self.flags & mask) != 0;
    }

    pub inline fn setFlag(self: *SslFilterConfig, mask: FilterFlagsType, val: bool) void {
        if (val) {
            self.flags |= mask;
        } else {
            self.flags &= ~mask;
        }
    }

    pub inline fn verifypeer(self: *const SslFilterConfig) bool {
        return self.getFlag(BIT_VERIFYPEER);
    }
    pub inline fn verifyhost(self: *const SslFilterConfig) bool {
        return self.getFlag(BIT_VERIFYHOST);
    }
    pub inline fn verifystatus(self: *const SslFilterConfig) bool {
        return self.getFlag(BIT_VERIFYSTATUS);
    }
    pub inline fn native_ca_store(self: *const SslFilterConfig) bool {
        return self.getFlag(BIT_NATIVE_CA_STORE);
    }
    pub inline fn primary_cache_session(self: *const SslFilterConfig) bool {
        return self.getFlag(BIT_CACHE_SESSION);
    }
    pub inline fn earlydata(self: *const SslFilterConfig) bool {
        return self.getFlag(BIT_EARLYDATA);
    }
    pub inline fn auto_client_cert(self: *const SslFilterConfig) bool {
        return self.getFlag(BIT_AUTO_CLIENT_CERT);
    }
    pub inline fn enable_beast(self: *const SslFilterConfig) bool {
        return self.getFlag(BIT_ENABLE_BEAST);
    }
    pub inline fn no_partialchain(self: *const SslFilterConfig) bool {
        return self.getFlag(BIT_NO_PARTIALCHAIN);
    }
    pub inline fn no_revoke(self: *const SslFilterConfig) bool {
        return self.getFlag(BIT_NO_REVOKE);
    }
    pub inline fn revoke_best_effort(self: *const SslFilterConfig) bool {
        return self.getFlag(BIT_REVOKE_BEST_EFFORT);
    }
};

pub const SslEasyConfig = extern struct {
    certverifyresult: c_long,
    version_max: u32,
    version: u8,
    ssl_options: u8,
    _win_pad: if (builtin.os.tag == .windows) [2]u8 else [0]u8 = if (builtin.os.tag == .windows) .{ 0, 0 } else .{},
    flags: EasyFlagsType,

    const BIT_VERIFYPEER: EasyFlagsType = 1 << 0;
    const BIT_VERIFYHOST: EasyFlagsType = 1 << 1;
    const BIT_VERIFYSTATUS: EasyFlagsType = 1 << 2;
    const BIT_CACHE_SESSION: EasyFlagsType = 1 << 3;
    const BIT_CERTINFO: EasyFlagsType = 1 << 4;
    const BIT_CUSTOM_CAFILE: EasyFlagsType = 1 << 5;
    const BIT_CUSTOM_CAPATH: EasyFlagsType = 1 << 6;
    const BIT_CUSTOM_CABLOB: EasyFlagsType = 1 << 7;

    pub inline fn getFlag(self: *const SslEasyConfig, mask: EasyFlagsType) bool {
        return (self.flags & mask) != 0;
    }

    pub inline fn setFlag(self: *SslEasyConfig, mask: EasyFlagsType, val: bool) void {
        if (val) {
            self.flags |= mask;
        } else {
            self.flags &= ~mask;
        }
    }
};

fn blobcmp(first: ?*CurlBlob, second: ?*CurlBlob) bool {
    if (first == null and second == null) return true;
    if (first == null or second == null) return false;
    const f = first.?;
    const s = second.?;
    if (f.len != s.len) return false;
    if (f.len == 0) return true;
    return std.mem.eql(u8, f.data.?[0..f.len], s.data.?[0..s.len]);
}

pub export fn Curl_ssl_config_init(sslc: *SslEasyConfig) callconv(.c) void {
    sslc.* = std.mem.zeroes(SslEasyConfig);
    sslc.setFlag(SslEasyConfig.BIT_VERIFYPEER, true);
    sslc.setFlag(SslEasyConfig.BIT_VERIFYHOST, true);
    sslc.setFlag(SslEasyConfig.BIT_CACHE_SESSION, true);
}

fn sslFilterConfigMatches(data: *const SslFilterConfig, needle: *const SslFilterConfig) bool {
    if ((data.version == needle.version) and
        (data.version_max == needle.version_max) and
        (data.ssl_options == needle.ssl_options) and
        (data.getFlag(SslFilterConfig.BIT_VERIFYPEER) == needle.getFlag(SslFilterConfig.BIT_VERIFYPEER)) and
        (data.getFlag(SslFilterConfig.BIT_VERIFYHOST) == needle.getFlag(SslFilterConfig.BIT_VERIFYHOST)) and
        (data.getFlag(SslFilterConfig.BIT_VERIFYSTATUS) == needle.getFlag(SslFilterConfig.BIT_VERIFYSTATUS)) and
        blobcmp(data.cert_blob, needle.cert_blob) and
        blobcmp(data.ca_info_blob, needle.ca_info_blob) and
        blobcmp(data.issuercert_blob, needle.issuercert_blob) and
        primitives.Curl_safecmp(data.CApath, needle.CApath) and
        primitives.Curl_safecmp(data.CAfile, needle.CAfile) and
        primitives.Curl_safecmp(data.issuercert, needle.issuercert) and
        primitives.Curl_safecmp(data.clientcert, needle.clientcert) and
        primitives.Curl_safecmp(data.key, needle.key) and
        (primitives.Curl_timestrcmp(data.key_passwd, needle.key_passwd) == 0) and
        (primitives.curl_strequal(data.cert_type, needle.cert_type) != 0 or (data.cert_type == null and needle.cert_type == null)) and
        (primitives.curl_strequal(data.key_type, needle.key_type) != 0 or (data.key_type == null and needle.key_type == null)) and
        blobcmp(data.key_blob, needle.key_blob) and
        (data.getFlag(SslFilterConfig.BIT_AUTO_CLIENT_CERT) == needle.getFlag(SslFilterConfig.BIT_AUTO_CLIENT_CERT)) and
        primitives.Curl_safecmp(data.cipher_list, needle.cipher_list) and
        primitives.Curl_safecmp(data.cipher_list13, needle.cipher_list13) and
        primitives.Curl_safecmp(data.pinned_key, needle.pinned_key) and
        primitives.Curl_safecmp(data.CRLfile, needle.CRLfile) and
        primitives.Curl_safecmp(data.curves, needle.curves) and
        primitives.Curl_safecmp(data.signature_algorithms, needle.signature_algorithms) and
        (data.getFlag(SslFilterConfig.BIT_NATIVE_CA_STORE) == needle.getFlag(SslFilterConfig.BIT_NATIVE_CA_STORE)))
    {
        return true;
    }
    return false;
}

pub export fn Curl_ssl_conn_config_match_zig(
    conn_config: *SslFilterConfig,
    cand_ssl_config: *SslFilterConfig,
    cand_proxy_ssl_config: ?*SslFilterConfig,
    proxy: bool,
) callconv(.c) bool {
    if (proxy) {
        if (cand_proxy_ssl_config) |p_cfg| {
            return sslFilterConfigMatches(conn_config, p_cfg);
        }
    }
    return sslFilterConfigMatches(conn_config, cand_ssl_config);
}

fn dupFieldStr(dest: *?[*:0]u8, src: ?[*:0]u8) bool {
    if (src) |s| {
        const d = mem.strdup(s);
        if (d == null) return false;
        dest.* = d;
    } else {
        dest.* = null;
    }
    return true;
}

fn dupFieldBlob(dest: *?*CurlBlob, src: ?*CurlBlob) bool {
    dest.* = null;
    if (src) |s| {
        const total = std.math.add(usize, @sizeOf(CurlBlob), s.len) catch return false;
        const raw = mem.malloc(total) orelse return false;
        const d: *CurlBlob = @ptrCast(@alignCast(raw));
        d.len = s.len;
        d.flags = 1; // CURL_BLOB_COPY
        const data_ptr: [*]u8 = raw + @sizeOf(CurlBlob);
        d.data = data_ptr;
        if (s.len > 0) {
            if (s.data) |src_data| {
                const src_bytes: [*]const u8 = @ptrCast(src_data);
                @memcpy(data_ptr[0..s.len], src_bytes[0..s.len]);
            }
        }
        dest.* = d;
    }
    return true;
}

fn cloneSslFilterConfig(source: *const SslFilterConfig, dest: *SslFilterConfig) bool {
    std.debug.assert(!dest.getFlag(SslFilterConfig.BIT_DEEP_COPY));
    dest.* = source.*;
    dest.setFlag(SslFilterConfig.BIT_DEEP_COPY, true);

    // Zero all owned pointers first so cleanup on partial failure is safe
    dest.CAfile = null;
    dest.CApath = null;
    dest.cipher_list = null;
    dest.cipher_list13 = null;
    dest.pinned_key = null;
    dest.cert_type = null;
    dest.CRLfile = null;
    dest.issuercert = null;
    dest.clientcert = null;
    dest.key = null;
    dest.key_type = null;
    dest.key_passwd = null;
    dest.curves = null;
    dest.signature_algorithms = null;
    dest.cert_blob = null;
    dest.ca_info_blob = null;
    dest.issuercert_blob = null;
    dest.key_blob = null;

    if (!dupFieldBlob(&dest.cert_blob, source.cert_blob)) {
        Curl_ssl_config_cleanup(dest);
        return false;
    }
    if (!dupFieldBlob(&dest.ca_info_blob, source.ca_info_blob)) {
        Curl_ssl_config_cleanup(dest);
        return false;
    }
    if (!dupFieldBlob(&dest.issuercert_blob, source.issuercert_blob)) {
        Curl_ssl_config_cleanup(dest);
        return false;
    }
    if (!dupFieldBlob(&dest.key_blob, source.key_blob)) {
        Curl_ssl_config_cleanup(dest);
        return false;
    }

    if (!dupFieldStr(&dest.CAfile, source.CAfile) or
        !dupFieldStr(&dest.CApath, source.CApath) or
        !dupFieldStr(&dest.cipher_list, source.cipher_list) or
        !dupFieldStr(&dest.cipher_list13, source.cipher_list13) or
        !dupFieldStr(&dest.pinned_key, source.pinned_key) or
        !dupFieldStr(&dest.cert_type, source.cert_type) or
        !dupFieldStr(&dest.CRLfile, source.CRLfile) or
        !dupFieldStr(&dest.issuercert, source.issuercert) or
        !dupFieldStr(&dest.clientcert, source.clientcert) or
        !dupFieldStr(&dest.key, source.key) or
        !dupFieldStr(&dest.key_type, source.key_type) or
        !dupFieldStr(&dest.key_passwd, source.key_passwd) or
        !dupFieldStr(&dest.curves, source.curves) or
        !dupFieldStr(&dest.signature_algorithms, source.signature_algorithms))
    {
        Curl_ssl_config_cleanup(dest);
        return false;
    }

    return true;
}

fn freeBlobScrubbed(blob_opt: ?*CurlBlob) void {
    if (blob_opt) |blob| {
        const copy = (blob.flags & 1) != 0;
        if (copy and blob.len > 0) {
            if (blob.data) |bdata| {
                mem.secureZero(@ptrCast(@constCast(bdata)), blob.len);
            }
        }
        const total = @sizeOf(CurlBlob) +| (if (copy) blob.len else 0);
        mem.secureZero(blob, total);
        mem.freeSized(blob, total);
    }
}

pub export fn Curl_ssl_config_cleanup(sslc: *SslFilterConfig) callconv(.c) void {
    if (sslc.getFlag(SslFilterConfig.BIT_DEEP_COPY)) {
        mem.free(sslc.CAfile);
        sslc.CAfile = null;
        mem.free(sslc.CApath);
        sslc.CApath = null;
        mem.free(sslc.cipher_list);
        sslc.cipher_list = null;
        mem.free(sslc.cipher_list13);
        sslc.cipher_list13 = null;
        mem.free(sslc.pinned_key);
        sslc.pinned_key = null;
        mem.free(sslc.cert_type);
        sslc.cert_type = null;
        mem.free(sslc.CRLfile);
        sslc.CRLfile = null;
        mem.free(sslc.issuercert);
        sslc.issuercert = null;
        mem.free(sslc.clientcert);
        sslc.clientcert = null;
        mem.free(sslc.key);
        sslc.key = null;
        mem.free(sslc.key_type);
        sslc.key_type = null;
        mem.freeSecretZ(sslc.key_passwd);
        sslc.key_passwd = null;
        mem.free(sslc.curves);
        sslc.curves = null;
        mem.free(sslc.signature_algorithms);
        sslc.signature_algorithms = null;
        freeBlobScrubbed(sslc.cert_blob);
        sslc.cert_blob = null;
        freeBlobScrubbed(sslc.ca_info_blob);
        sslc.ca_info_blob = null;
        freeBlobScrubbed(sslc.issuercert_blob);
        sslc.issuercert_blob = null;
        freeBlobScrubbed(sslc.key_blob);
        sslc.key_blob = null;
        sslc.setFlag(SslFilterConfig.BIT_DEEP_COPY, false);
    }
}

pub export fn Curl_ssl_conn_config_clone_zig(
    ssl_config: *SslFilterConfig,
    proxy_ssl_config: ?*SslFilterConfig,
    conn_ssl_config: *SslFilterConfig,
    conn_proxy_ssl_config: ?*SslFilterConfig,
) callconv(.c) CURLcode {
    if (!cloneSslFilterConfig(ssl_config, conn_ssl_config)) {
        return CURLE_OUT_OF_MEMORY;
    }
    if (proxy_ssl_config) |p_src| {
        if (conn_proxy_ssl_config) |p_dst| {
            if (!cloneSslFilterConfig(p_src, p_dst)) {
                return CURLE_OUT_OF_MEMORY;
            }
        }
    }
    return CURLE_OK;
}

pub export fn Curl_ssl_conn_config_cleanup_zig(
    conn_ssl_config: *SslFilterConfig,
    conn_proxy_ssl_config: ?*SslFilterConfig,
) callconv(.c) void {
    Curl_ssl_config_cleanup(conn_ssl_config);
    if (conn_proxy_ssl_config) |p_cfg| {
        Curl_ssl_config_cleanup(p_cfg);
    }
}

pub export fn Curl_ssl_conn_config_update_zig(
    src: *SslEasyConfig,
    dest: ?*SslFilterConfig,
) callconv(.c) void {
    if (dest) |d| {
        d.setFlag(SslFilterConfig.BIT_VERIFYHOST, src.getFlag(SslEasyConfig.BIT_VERIFYHOST));
        d.setFlag(SslFilterConfig.BIT_VERIFYPEER, src.getFlag(SslEasyConfig.BIT_VERIFYPEER));
    }
}

fn sslEasyConfigComplOptions(
    origin: ?*const anyopaque,
    initial_origin: ?*const anyopaque,
    sslc: *const SslEasyConfig,
    sslfc: *SslFilterConfig,
) void {
    sslfc.version = sslc.version;
    sslfc.version_max = sslc.version_max;
    sslfc.ssl_options = sslc.ssl_options;
    sslfc.setFlag(SslFilterConfig.BIT_VERIFYPEER, sslc.getFlag(SslEasyConfig.BIT_VERIFYPEER));
    sslfc.setFlag(SslFilterConfig.BIT_VERIFYHOST, sslc.getFlag(SslEasyConfig.BIT_VERIFYHOST));
    sslfc.setFlag(SslFilterConfig.BIT_VERIFYSTATUS, sslc.getFlag(SslEasyConfig.BIT_VERIFYSTATUS));
    sslfc.setFlag(SslFilterConfig.BIT_CACHE_SESSION, sslc.getFlag(SslEasyConfig.BIT_CACHE_SESSION));

    var peer_differs = false;
    if (builtin.output_mode == .Lib) {
        if (initial_origin != null and origin != null and !c_ext.Curl_peer_equal(origin, initial_origin)) {
            peer_differs = true;
        }
    }
    if (peer_differs) {
        sslfc.setFlag(SslFilterConfig.BIT_EARLYDATA, false);
    } else {
        sslfc.setFlag(SslFilterConfig.BIT_EARLYDATA, (sslc.ssl_options & CURLSSLOPT_EARLYDATA) != 0);
    }
    sslfc.setFlag(SslFilterConfig.BIT_AUTO_CLIENT_CERT, (sslc.ssl_options & CURLSSLOPT_AUTO_CLIENT_CERT) != 0);
    sslfc.setFlag(SslFilterConfig.BIT_ENABLE_BEAST, (sslc.ssl_options & CURLSSLOPT_ALLOW_BEAST) != 0);
    sslfc.setFlag(SslFilterConfig.BIT_NO_REVOKE, (sslc.ssl_options & CURLSSLOPT_NO_REVOKE) != 0);
    sslfc.setFlag(SslFilterConfig.BIT_NO_PARTIALCHAIN, (sslc.ssl_options & CURLSSLOPT_NO_PARTIALCHAIN) != 0);
    sslfc.setFlag(SslFilterConfig.BIT_REVOKE_BEST_EFFORT, (sslc.ssl_options & CURLSSLOPT_REVOKE_BEST_EFFORT) != 0);
    sslfc.setFlag(SslFilterConfig.BIT_NATIVE_CA_STORE, (sslc.ssl_options & CURLSSLOPT_NATIVE_CA) != 0);
}

inline fn strsetGet(strings: *collections.u8_strset, id: u8) ?[*:0]u8 {
    return if (collections.Curl_u8_strset_get(strings, id)) |p| @constCast(p) else null;
}

pub export fn Curl_ssl_filter_config_tmp_init_zig(
    data: ?*anyopaque,
    origin: ?*anyopaque,
    initial_origin: ?*anyopaque,
    sslc: *SslEasyConfig,
    proxy_sslc: ?*SslEasyConfig,
    strings: *collections.u8_strset,
    blobs: [*]?*CurlBlob,
    ssl_origin: *SslFilterConfig,
    ssl_proxy: ?*SslFilterConfig,
    default_ca_path: ?[*:0]const u8,
    default_ca_bundle: ?[*:0]const u8,
    force_native_ca: bool,
    str_ec_curves_id: c_uint,
    str_sig_algs_id: c_uint,
) callconv(.c) CURLcode {
    std.debug.assert(!ssl_origin.getFlag(SslFilterConfig.BIT_DEEP_COPY));
    sslEasyConfigComplOptions(origin, initial_origin, sslc, ssl_origin);

    const is_schannel = if (builtin.output_mode == .Lib)
        c_ext.Curl_ssl_backend() == CURLSSLBACKEND_SCHANNEL
    else
        false;

    if (!is_schannel) {
        if (force_native_ca) {
            if (!sslc.getFlag(SslEasyConfig.BIT_CUSTOM_CAPATH) and
                !sslc.getFlag(SslEasyConfig.BIT_CUSTOM_CAFILE) and
                !sslc.getFlag(SslEasyConfig.BIT_CUSTOM_CABLOB))
            {
                ssl_origin.setFlag(SslFilterConfig.BIT_NATIVE_CA_STORE, true);
            }
        }
        if (default_ca_path) |ca_path| {
            if (!sslc.getFlag(SslEasyConfig.BIT_CUSTOM_CAPATH) and
                strsetGet(strings, STRING_SSL_CAPATH) == null)
            {
                if (builtin.output_mode == .Lib) {
                    const result = c_ext.Curl_setstropt(data, STRING_SSL_CAPATH, ca_path);
                    if (result != CURLE_OK) return result;
                }
            }
        }
        if (default_ca_bundle) |ca_bundle| {
            if (!sslc.getFlag(SslEasyConfig.BIT_CUSTOM_CAFILE) and
                strsetGet(strings, STRING_SSL_CAFILE) == null)
            {
                if (builtin.output_mode == .Lib) {
                    const result = c_ext.Curl_setstropt(data, STRING_SSL_CAFILE, ca_bundle);
                    if (result != CURLE_OK) return result;
                }
            }
        }
    }

    ssl_origin.CApath = strsetGet(strings, STRING_SSL_CAPATH);
    ssl_origin.CAfile = strsetGet(strings, STRING_SSL_CAFILE);
    ssl_origin.CRLfile = strsetGet(strings, STRING_SSL_CRLFILE);
    ssl_origin.issuercert = strsetGet(strings, STRING_SSL_ISSUERCERT);
    ssl_origin.issuercert_blob = blobs[BLOB_SSL_ISSUERCERT];
    ssl_origin.cipher_list = strsetGet(strings, STRING_SSL_CIPHER_LIST);
    ssl_origin.cipher_list13 = strsetGet(strings, STRING_SSL_CIPHER13_LIST);
    ssl_origin.pinned_key = strsetGet(strings, STRING_SSL_PINNEDPUBLICKEY);
    ssl_origin.cert_blob = blobs[BLOB_CERT];
    ssl_origin.ca_info_blob = blobs[BLOB_CAINFO];
    ssl_origin.curves = strsetGet(strings, @intCast(str_ec_curves_id));
    ssl_origin.signature_algorithms = strsetGet(strings, @intCast(str_sig_algs_id));
    ssl_origin.clientcert = strsetGet(strings, STRING_CERT);
    ssl_origin.key = strsetGet(strings, STRING_KEY);
    ssl_origin.key_blob = blobs[BLOB_KEY];
    ssl_origin.cert_type = strsetGet(strings, STRING_CERT_TYPE);
    ssl_origin.key_type = strsetGet(strings, STRING_KEY_TYPE);
    ssl_origin.key_passwd = strsetGet(strings, STRING_KEY_PASSWD);

    if (proxy_sslc) |psslc| {
        if (ssl_proxy) |pssl_proxy| {
            std.debug.assert(!pssl_proxy.getFlag(SslFilterConfig.BIT_DEEP_COPY));
            sslEasyConfigComplOptions(null, null, psslc, pssl_proxy);
            if (!is_schannel) {
                if (force_native_ca) {
                    if (!psslc.getFlag(SslEasyConfig.BIT_CUSTOM_CAPATH) and
                        !psslc.getFlag(SslEasyConfig.BIT_CUSTOM_CAFILE) and
                        !psslc.getFlag(SslEasyConfig.BIT_CUSTOM_CABLOB))
                    {
                        pssl_proxy.setFlag(SslFilterConfig.BIT_NATIVE_CA_STORE, true);
                    }
                }
                if (default_ca_path) |ca_path| {
                    if (!psslc.getFlag(SslEasyConfig.BIT_CUSTOM_CAPATH) and
                        strsetGet(strings, STRING_SSL_CAPATH_PROXY) == null)
                    {
                        if (builtin.output_mode == .Lib) {
                            const result = c_ext.Curl_setstropt(data, STRING_SSL_CAPATH_PROXY, ca_path);
                            if (result != CURLE_OK) return result;
                        }
                    }
                }
                if (default_ca_bundle) |ca_bundle| {
                    if (!psslc.getFlag(SslEasyConfig.BIT_CUSTOM_CAFILE) and
                        strsetGet(strings, STRING_SSL_CAFILE_PROXY) == null)
                    {
                        if (builtin.output_mode == .Lib) {
                            const result = c_ext.Curl_setstropt(data, STRING_SSL_CAFILE_PROXY, ca_bundle);
                            if (result != CURLE_OK) return result;
                        }
                    }
                }
            }
            pssl_proxy.CApath = strsetGet(strings, STRING_SSL_CAPATH_PROXY);
            pssl_proxy.CAfile = strsetGet(strings, STRING_SSL_CAFILE_PROXY);
            pssl_proxy.CRLfile = strsetGet(strings, STRING_SSL_CRLFILE_PROXY);
            pssl_proxy.issuercert = strsetGet(strings, STRING_SSL_ISSUERCERT_PROXY);
            pssl_proxy.issuercert_blob = blobs[BLOB_SSL_ISSUERCERT_PROXY];
            pssl_proxy.cipher_list = strsetGet(strings, STRING_SSL_CIPHER_LIST_PROXY);
            pssl_proxy.cipher_list13 = strsetGet(strings, STRING_SSL_CIPHER13_LIST_PROXY);
            pssl_proxy.pinned_key = strsetGet(strings, STRING_SSL_PINNEDPUBLICKEY_PROXY);
            pssl_proxy.cert_blob = blobs[BLOB_CERT_PROXY];
            pssl_proxy.ca_info_blob = blobs[BLOB_CAINFO_PROXY];
            pssl_proxy.curves = strsetGet(strings, @intCast(str_ec_curves_id));
            pssl_proxy.signature_algorithms = strsetGet(strings, @intCast(str_sig_algs_id));
            pssl_proxy.clientcert = strsetGet(strings, STRING_CERT_PROXY);
            pssl_proxy.key = strsetGet(strings, STRING_KEY_PROXY);
            pssl_proxy.key_blob = blobs[BLOB_KEY_PROXY];
            pssl_proxy.cert_type = strsetGet(strings, STRING_CERT_TYPE_PROXY);
            pssl_proxy.key_type = strsetGet(strings, STRING_KEY_TYPE_PROXY);
            pssl_proxy.key_passwd = strsetGet(strings, STRING_KEY_PASSWD_PROXY);
        }
    }
    return CURLE_OK;
}

// ============================================================================
// 2. lib/vtls/vtls_scache.c (lib/vtls/vtls_scache.h)
// ============================================================================

pub const CurlScheme = extern struct {
    name: [*:0]const u8,
};

pub const CurlPeer = extern struct {
    scheme: *const CurlScheme,
    hostname: [*:0]const u8,
    zoneid: ?[*:0]u8 = null,
    refcount: u32 = 1,
    scopeid: u32 = 0,
    port: u16,
    _win_pad: if (builtin.os.tag == .windows) [2]u8 else [0]u8 = if (builtin.os.tag == .windows) .{ 0, 0 } else .{},
    flags: if (builtin.os.tag == .windows) u32 else u8 = 0,
    user_hostname: [1]u8 = .{0},
};

pub const SslPeer = extern struct {
    origin: ?*CurlPeer,
    peer: ?*CurlPeer,
    sni: ?[*:0]u8,
    scache_key: ?[*:0]u8,
    type: c_uint,
    transport: u8,
};

pub const CurlSslScacheObjDtor = *const fn (sobj: ?*anyopaque) callconv(.c) void;

pub const CurlSslScachePeer = extern struct {
    ssl_peer_key: ?[*:0]u8,
    clientcert: ?[*:0]u8,
    key_passwd: ?[*:0]u8,
    sessions: Curl_llist,
    sobj: ?*anyopaque,
    sobj_free: ?CurlSslScacheObjDtor,
    key_salt: [CURL_SHA256_DIGEST_LENGTH]u8,
    key_hmac: [CURL_SHA256_DIGEST_LENGTH]u8,
    max_sessions: usize,
    age: c_long,
    flags: u32,

    const BIT_HMAC_SET: u32 = 1 << 0;
    const BIT_EXPORTABLE: u32 = 1 << 1;

    pub inline fn getHmacSet(self: *const CurlSslScachePeer) bool {
        return (self.flags & BIT_HMAC_SET) != 0;
    }

    pub inline fn setHmacSet(self: *CurlSslScachePeer, val: bool) void {
        if (val) self.flags |= BIT_HMAC_SET else self.flags &= ~BIT_HMAC_SET;
    }

    pub inline fn getExportable(self: *const CurlSslScachePeer) bool {
        return (self.flags & BIT_EXPORTABLE) != 0;
    }

    pub inline fn setExportable(self: *CurlSslScachePeer, val: bool) void {
        if (val) self.flags |= BIT_EXPORTABLE else self.flags &= ~BIT_EXPORTABLE;
    }
};

const CURL_SCACHE_MAGIC: c_uint = 0x000e1551;

pub const CurlSslScache = extern struct {
    magic: c_uint,
    peers: [*]CurlSslScachePeer,
    peer_count: usize,
    default_lifetime_secs: c_int,
    age: c_long,
    mutex: CurlMutex,
    locking_thread: curl_thread_id_t,
    is_locked: bool,
};

inline fn goodScache(scache: ?*const CurlSslScache) bool {
    return if (scache) |sc| sc.magic == CURL_SCACHE_MAGIC else false;
}

fn cfSslScacheGet(data: ?*anyopaque, raw_scache: ?*CurlSslScache) ?*CurlSslScache {
    if (raw_scache) |sc| {
        if (!goodScache(sc)) {
            failf(data, "transfer would use an invalid scache at %p, denied", .{@as(?*const anyopaque, sc)});
            std.debug.assert(false);
            return null;
        }
        return sc;
    }
    return null;
}

fn cfSslPeerKeyAddString(buf: *dynbuf, name: [*:0]const u8, value: [*:0]const u8) CURLcode {
    const val_len = std.mem.len(value);
    return curlx_dyn_addf(buf, ":%s-%zu:%s", name, val_len, value);
}

fn cfSslPeerKeyAddPath(buf: *dynbuf, name: [*:0]const u8, path_opt: ?[*:0]const u8, is_local: *bool) CURLcode {
    if (path_opt) |path| {
        if (path[0] != 0) {
            if (builtin.os.tag == .windows) {
                if (c_ext._fullpath(null, path, 0)) |abspath| {
                    const result = cfSslPeerKeyAddString(buf, name, abspath);
                    c_ext.free(abspath);
                    return result;
                }
                is_local.* = true;
            } else {
                if (path[0] != '/') {
                    if (c_ext.realpath(path, null)) |abspath| {
                        const result = cfSslPeerKeyAddString(buf, name, abspath);
                        c_ext.free(abspath);
                        return result;
                    }
                    is_local.* = true;
                }
            }
            return cfSslPeerKeyAddString(buf, name, path);
        }
    }
    return CURLE_OK;
}

fn cfSslPeerKeyAddHash(buf: *dynbuf, name: [*:0]const u8, blob_opt: ?*const CurlBlob) CURLcode {
    if (blob_opt) |blob| {
        if (blob.len > 0) {
            var hash: [CURL_SHA256_DIGEST_LENGTH]u8 = undefined;
            var result = curlx_dyn_addf(buf, ":%s-", name);
            if (result != CURLE_OK) return result;
            result = crypto.Curl_sha256it(&hash, blob.data, blob.len);
            if (result != CURLE_OK) return result;
            for (hash) |b| {
                result = curlx_dyn_addf(buf, "%02x", @as(c_uint, b));
                if (result != CURLE_OK) return result;
            }
        }
    }
    return CURLE_OK;
}

fn cfSslPeerKeyAddMtls(buf: *dynbuf, ssl: *const SslFilterConfig, is_local: *bool) CURLcode {
    var result: CURLcode = CURLE_OK;
    if (ssl.clientcert) |cc| {
        if (cc[0] != 0) {
            result = cfSslPeerKeyAddPath(buf, "CCERT", cc, is_local);
            if (result != CURLE_OK) return result;
        }
    }
    if (ssl.key) |k| {
        if (k[0] != 0) {
            result = cfSslPeerKeyAddPath(buf, "KEY", k, is_local);
            if (result != CURLE_OK) return result;
        }
    }
    if (ssl.key_blob) |kb| {
        result = cfSslPeerKeyAddHash(buf, "KEYBlob", kb);
        if (result != CURLE_OK) return result;
    }
    if (ssl.cert_type) |ct| {
        if (ct[0] != 0) {
            const len = std.mem.len(ct);
            result = curlx_dyn_addf(buf, ":CT-%zu:", len);
            var i: usize = 0;
            while (result == CURLE_OK and ct[i] != 0) : (i += 1) {
                var c = primitives.rawToupper(ct[i]);
                result = containers.curlx_dyn_addn(buf, @ptrCast(&c), 1);
            }
            if (result != CURLE_OK) return result;
        }
    }
    if (ssl.key_type) |kt| {
        if (kt[0] != 0) {
            const len = std.mem.len(kt);
            result = curlx_dyn_addf(buf, ":KT-%zu:", len);
            var i: usize = 0;
            while (result == CURLE_OK and kt[i] != 0) : (i += 1) {
                var c = primitives.rawToupper(kt[i]);
                result = containers.curlx_dyn_addn(buf, @ptrCast(&c), 1);
            }
        }
    }
    return result;
}

const CURL_SSLS_LOCAL_SUFFIX: [*:0]const u8 = ":L";
const CURL_SSLS_GLOBAL_SUFFIX: [*:0]const u8 = ":G";

fn cfSslPeerKeyIsGlobal(peer_key_opt: ?[*:0]const u8) bool {
    const peer_key = peer_key_opt orelse return false;
    const len = std.mem.len(peer_key);
    return (len > 2) and (peer_key[len - 1] == 'G') and (peer_key[len - 2] == ':');
}

fn sslPeerKeyAddTransport(buf: *dynbuf, transport: u8) CURLcode {
    return switch (transport) {
        TRNSPRT_TCP => CURLE_OK,
        TRNSPRT_UDP => containers.curlx_dyn_add(buf, ":UDP"),
        TRNSPRT_QUIC => containers.curlx_dyn_add(buf, ":QUIC"),
        TRNSPRT_UNIX => containers.curlx_dyn_add(buf, ":UNIX"),
        else => curlx_dyn_addf(buf, ":TRNSPRT-%d", @as(c_int, transport)),
    };
}

fn sslPeerKeyAddVrfy(buf: *dynbuf, ssl: *const SslFilterConfig, peer: *const SslPeer) CURLcode {
    var result: CURLcode = CURLE_OK;
    if (!ssl.getFlag(SslFilterConfig.BIT_VERIFYPEER)) {
        result = containers.curlx_dyn_add(buf, ":NO-VRFY-PEER");
        if (result != CURLE_OK) return result;
    }
    if (!ssl.getFlag(SslFilterConfig.BIT_VERIFYHOST)) {
        result = containers.curlx_dyn_add(buf, ":NO-VRFY-HOST");
        if (result != CURLE_OK) return result;
    }
    if (ssl.getFlag(SslFilterConfig.BIT_VERIFYSTATUS)) {
        result = containers.curlx_dyn_add(buf, ":VRFY-STATUS");
        if (result != CURLE_OK) return result;
    }
    if ((!ssl.getFlag(SslFilterConfig.BIT_VERIFYPEER) or !ssl.getFlag(SslFilterConfig.BIT_VERIFYHOST)) and
        peer.peer != null)
    {
        const p = peer.peer.?;
        const is_equal = if (builtin.output_mode == .Lib)
            c_ext.Curl_peer_equal(peer.origin, p)
        else
            (peer.origin == p);
        if (!is_equal) {
            result = cfSslPeerKeyAddString(buf, "CHOST", p.hostname);
            if (result == CURLE_OK) {
                result = curlx_dyn_addf(buf, ":CPORT-%u", @as(c_uint, @intCast(p.port)));
            }
            if (result != CURLE_OK) return result;
        }
    }
    return CURLE_OK;
}

pub export fn Curl_ssl_peer_key_make(
    peer: *const SslPeer,
    ssl: *SslFilterConfig,
    tls_id: ?[*:0]const u8,
    ppeer_key: *?[*:0]u8,
) callconv(.c) CURLcode {
    var buf: dynbuf = undefined;
    var key_len: usize = 0;
    var is_local: bool = false;
    var result: CURLcode = CURLE_OK;

    const orig = peer.origin orelse return CURLE_FAILED_INIT;
    ppeer_key.* = null;
    containers.curlx_dyn_init(&buf, 10 * 1024);
    defer containers.curlx_dyn_free(&buf);

    result = curlx_dyn_addf(
        &buf,
        "%s:%s:%d:KEY-V3",
        orig.scheme.name,
        orig.hostname,
        @as(c_int, orig.port),
    );
    if (result != CURLE_OK) return result;

    result = sslPeerKeyAddTransport(&buf, peer.transport);
    if (result != CURLE_OK) return result;

    result = sslPeerKeyAddVrfy(&buf, ssl, peer);
    if (result != CURLE_OK) return result;

    if (ssl.version != 0 or ssl.version_max != 0) {
        result = curlx_dyn_addf(
            &buf,
            ":TLSVER-%d-%u",
            @as(c_int, ssl.version),
            @as(c_uint, ssl.version_max >> 16),
        );
        if (result != CURLE_OK) return result;
    }
    if (ssl.ssl_options != 0) {
        result = curlx_dyn_addf(&buf, ":TLSOPT-%x", @as(c_uint, ssl.ssl_options));
        if (result != CURLE_OK) return result;
    }
    if (ssl.cipher_list) |cl| {
        result = cfSslPeerKeyAddString(&buf, "CIPHER", cl);
        if (result != CURLE_OK) return result;
    }
    if (ssl.cipher_list13) |cl13| {
        result = cfSslPeerKeyAddString(&buf, "CIPHER13", cl13);
        if (result != CURLE_OK) return result;
    }
    if (ssl.curves) |curves| {
        result = cfSslPeerKeyAddString(&buf, "CURVES", curves);
        if (result != CURLE_OK) return result;
    }
    if (ssl.signature_algorithms) |sigalgs| {
        result = cfSslPeerKeyAddString(&buf, "SIGALGS", sigalgs);
        if (result != CURLE_OK) return result;
    }
    if (ssl.getFlag(SslFilterConfig.BIT_VERIFYPEER)) {
        result = cfSslPeerKeyAddPath(&buf, "CA", ssl.CAfile, &is_local);
        if (result != CURLE_OK) return result;
        result = cfSslPeerKeyAddPath(&buf, "CApath", ssl.CApath, &is_local);
        if (result != CURLE_OK) return result;
        result = cfSslPeerKeyAddPath(&buf, "CRL", ssl.CRLfile, &is_local);
        if (result != CURLE_OK) return result;
        result = cfSslPeerKeyAddPath(&buf, "Issuer", ssl.issuercert, &is_local);
        if (result != CURLE_OK) return result;
        if (ssl.ca_info_blob) |b| {
            result = cfSslPeerKeyAddHash(&buf, "CAInfoBlob", b);
            if (result != CURLE_OK) return result;
        }
        if (ssl.issuercert_blob) |b| {
            result = cfSslPeerKeyAddHash(&buf, "IssuerBlob", b);
            if (result != CURLE_OK) return result;
        }
    }
    if (ssl.cert_blob) |b| {
        result = cfSslPeerKeyAddHash(&buf, "CertBlob", b);
        if (result != CURLE_OK) return result;
    }
    if (ssl.pinned_key) |pk| {
        if (pk[0] != 0) {
            result = cfSslPeerKeyAddString(&buf, "Pinned", pk);
            if (result != CURLE_OK) return result;
        }
    }

    result = cfSslPeerKeyAddMtls(&buf, ssl, &is_local);
    if (result != CURLE_OK) return result;

    if (tls_id == null or tls_id.?[0] == 0) {
        return CURLE_FAILED_INIT;
    }
    result = cfSslPeerKeyAddString(&buf, "IMPL", tls_id.?);
    if (result != CURLE_OK) return result;

    result = curlx_dyn_addf(
        &buf,
        "%s",
        if (is_local) CURL_SSLS_LOCAL_SUFFIX else CURL_SSLS_GLOBAL_SUFFIX,
    );
    if (result != CURLE_OK) return result;

    ppeer_key.* = containers.curlx_dyn_take(&buf, &key_len);
    return CURLE_OK;
}

fn cfSslScacheSessionLdestroy(udata: ?*anyopaque, obj: ?*anyopaque) callconv(.c) void {
    _ = udata;
    const s: *CurlSslSession = @ptrCast(@alignCast(obj orelse return));
    if (s.sdata) |sd| {
        mem.secureZero(sd, s.sdata_len);
        mem.freeSized(sd, s.sdata_len);
        s.sdata = null;
        s.sdata_len = 0;
    }
    if (s.quic_tp) |qtp| {
        mem.secureZero(qtp, s.quic_tp_len);
        mem.freeSized(qtp, s.quic_tp_len);
        s.quic_tp = null;
        s.quic_tp_len = 0;
    }
    mem.free(s.alpn);
    s.alpn = null;
    mem.secureZero(s, @sizeOf(CurlSslSession));
    mem.freeSized(s, @sizeOf(CurlSslSession));
}

pub export fn Curl_ssl_session_create(
    sdata: ?*anyopaque,
    sdata_len: usize,
    ietf_tls_id: c_int,
    alpn: ?[*:0]const u8,
    valid_until: curl_off_t,
    earlydata_max: usize,
    psession: *?*CurlSslSession,
) callconv(.c) CURLcode {
    return Curl_ssl_session_create2(
        sdata,
        sdata_len,
        ietf_tls_id,
        alpn,
        valid_until,
        earlydata_max,
        null,
        0,
        psession,
    );
}

pub export fn Curl_ssl_session_create2(
    sdata: ?*anyopaque,
    sdata_len: usize,
    ietf_tls_id: c_int,
    alpn: ?[*:0]const u8,
    valid_until: curl_off_t,
    earlydata_max: usize,
    quic_tp: ?[*]u8,
    quic_tp_len: usize,
    psession: *?*CurlSslSession,
) callconv(.c) CURLcode {
    if (sdata == null or sdata_len == 0) {
        if (sdata) |sd| {
            mem.secureZero(sd, sdata_len);
            mem.freeSized(sd, sdata_len);
        }
        return CURLE_BAD_FUNCTION_ARGUMENT;
    }

    psession.* = null;
    const s_raw = mem.calloc(1, @sizeOf(CurlSslSession)) orelse {
        if (sdata) |sd| {
            mem.secureZero(sd, sdata_len);
            mem.freeSized(sd, sdata_len);
        }
        if (quic_tp) |qtp| {
            mem.secureZero(qtp, quic_tp_len);
            mem.freeSized(qtp, quic_tp_len);
        }
        return CURLE_OUT_OF_MEMORY;
    };
    const s: *CurlSslSession = @ptrCast(@alignCast(s_raw));

    s.ietf_tls_id = ietf_tls_id;
    s.valid_until = valid_until;
    s.earlydata_max = earlydata_max;
    s.sdata = @ptrCast(sdata);
    s.sdata_len = sdata_len;
    s.quic_tp = quic_tp;
    s.quic_tp_len = quic_tp_len;
    if (alpn) |a| {
        s.alpn = mem.strdup(a) orelse {
            cfSslScacheSessionLdestroy(null, s);
            return CURLE_OUT_OF_MEMORY;
        };
    }
    psession.* = s;
    return CURLE_OK;
}

pub export fn Curl_ssl_session_destroy(s_opt: ?*CurlSslSession) callconv(.c) void {
    if (s_opt) |s| {
        if (containers.Curl_node_llist(&s.list) != null) {
            containers.Curl_node_remove(&s.list);
        } else {
            cfSslScacheSessionLdestroy(null, s);
        }
    }
}

pub export fn Curl_ssl_session_dup(
    src_opt: ?*CurlSslSession,
    pdest_opt: ?*?*CurlSslSession,
) callconv(.c) CURLcode {
    const src = src_opt orelse return CURLE_BAD_FUNCTION_ARGUMENT;
    const pdest = pdest_opt orelse return CURLE_BAD_FUNCTION_ARGUMENT;
    pdest.* = null;

    const dest_raw = mem.calloc(1, @sizeOf(CurlSslSession)) orelse return CURLE_OUT_OF_MEMORY;
    const dest: *CurlSslSession = @ptrCast(@alignCast(dest_raw));

    dest.ietf_tls_id = src.ietf_tls_id;
    dest.valid_until = src.valid_until;
    dest.earlydata_max = src.earlydata_max;
    dest.flags = src.flags;

    if (src.sdata_len > 0) {
        dest.sdata = memdup(src.sdata, src.sdata_len) orelse {
            Curl_ssl_session_destroy(dest);
            return CURLE_OUT_OF_MEMORY;
        };
        dest.sdata_len = src.sdata_len;
    }
    if (src.quic_tp_len > 0) {
        dest.quic_tp = memdup(src.quic_tp, src.quic_tp_len) orelse {
            Curl_ssl_session_destroy(dest);
            return CURLE_OUT_OF_MEMORY;
        };
        dest.quic_tp_len = src.quic_tp_len;
    }
    if (src.alpn) |a| {
        dest.alpn = mem.strdup(a) orelse {
            Curl_ssl_session_destroy(dest);
            return CURLE_OUT_OF_MEMORY;
        };
    }

    pdest.* = dest;
    return CURLE_OK;
}

fn cfSslScacheClearPeer(peer: *CurlSslScachePeer) void {
    containers.Curl_llist_destroy(&peer.sessions, null);
    if (peer.sobj) |sobj| {
        if (peer.sobj_free) |dtor| {
            dtor(sobj);
        }
        peer.sobj = null;
    }
    peer.sobj_free = null;
    mem.free(peer.clientcert);
    peer.clientcert = null;
    mem.freeSecretZ(peer.key_passwd);
    peer.key_passwd = null;
    mem.freeSecretZ(peer.ssl_peer_key);
    peer.ssl_peer_key = null;
    mem.secureZero(&peer.key_salt, peer.key_salt.len);
    mem.secureZero(&peer.key_hmac, peer.key_hmac.len);
    peer.age = 0;
    peer.setHmacSet(false);
}

fn cfSslScachePeerSetObj(
    peer: *CurlSslScachePeer,
    sobj: ?*anyopaque,
    sobj_free: ?CurlSslScacheObjDtor,
) void {
    if (peer.sobj_free) |dtor| {
        dtor(peer.sobj);
    }
    peer.sobj = sobj;
    peer.sobj_free = sobj_free;
}

fn cfSslCachePeerUpdate(peer: *CurlSslScachePeer) void {
    peer.setExportable(
        peer.clientcert == null and
            peer.key_passwd == null and
            (peer.ssl_peer_key == null or cfSslPeerKeyIsGlobal(peer.ssl_peer_key)),
    );
}

fn cfSslScachePeerInit(
    peer: *CurlSslScachePeer,
    ssl_peer_key: ?[*:0]const u8,
    clientcert: ?[*:0]const u8,
    key_passwd: ?[*:0]const u8,
    salt: ?[*]const u8,
    hmac: ?[*]const u8,
) CURLcode {
    std.debug.assert(peer.ssl_peer_key == null);
    if (ssl_peer_key) |spk| {
        peer.ssl_peer_key = mem.strdup(spk) orelse {
            cfSslScacheClearPeer(peer);
            return CURLE_OUT_OF_MEMORY;
        };
        peer.setHmacSet(false);
    } else if (salt != null and hmac != null) {
        @memcpy(&peer.key_salt, salt.?[0..CURL_SHA256_DIGEST_LENGTH]);
        @memcpy(&peer.key_hmac, hmac.?[0..CURL_SHA256_DIGEST_LENGTH]);
        peer.setHmacSet(true);
    } else {
        cfSslScacheClearPeer(peer);
        return CURLE_BAD_FUNCTION_ARGUMENT;
    }
    if (clientcert) |cc| {
        peer.clientcert = mem.strdup(cc) orelse {
            cfSslScacheClearPeer(peer);
            return CURLE_OUT_OF_MEMORY;
        };
    }
    if (key_passwd) |kp| {
        peer.key_passwd = mem.strdup(kp) orelse {
            cfSslScacheClearPeer(peer);
            return CURLE_OUT_OF_MEMORY;
        };
    }
    cfSslCachePeerUpdate(peer);
    return CURLE_OK;
}

fn cfScacheSessionRemove(peer: *CurlSslScachePeer, s: *CurlSslSession) void {
    _ = peer;
    Curl_ssl_session_destroy(s);
}

inline fn cfScacheSessionExpired(s: *const CurlSslSession, now: curl_off_t) bool {
    return (s.valid_until > 0) and (s.valid_until < now);
}

fn cfScachePeerRemoveExpired(peer: *CurlSslScachePeer, now: curl_off_t) void {
    var n = containers.Curl_llist_head(&peer.sessions);
    while (n) |node| {
        const s: *CurlSslSession = @ptrCast(@alignCast(containers.Curl_node_elem(node).?));
        n = containers.Curl_node_next(node);
        if (cfScacheSessionExpired(s, now)) {
            cfScacheSessionRemove(peer, s);
        }
    }
}

fn cfScachePeerRemoveNon13(peer: *CurlSslScachePeer) void {
    var n = containers.Curl_llist_head(&peer.sessions);
    while (n) |node| {
        const s: *CurlSslSession = @ptrCast(@alignCast(containers.Curl_node_elem(node).?));
        n = containers.Curl_node_next(node);
        if (s.ietf_tls_id != CURL_IETF_PROTO_TLS1_3) {
            cfScacheSessionRemove(peer, s);
        }
    }
}

pub export fn Curl_ssl_scache_create(
    max_peers: usize,
    max_sessions_per_peer: usize,
    pscache: *?*CurlSslScache,
) callconv(.c) CURLcode {
    pscache.* = null;
    const peers_raw = mem.calloc(max_peers, @sizeOf(CurlSslScachePeer)) orelse return CURLE_OUT_OF_MEMORY;
    const peers: [*]CurlSslScachePeer = @ptrCast(@alignCast(peers_raw));

    const scache_raw = mem.calloc(1, @sizeOf(CurlSslScache)) orelse {
        mem.free(peers_raw);
        return CURLE_OUT_OF_MEMORY;
    };
    const scache: *CurlSslScache = @ptrCast(@alignCast(scache_raw));

    scache.magic = CURL_SCACHE_MAGIC;
    scache.default_lifetime_secs = 24 * 60 * 60;
    scache.peer_count = max_peers;
    scache.peers = peers;
    scache.age = 1;
    for (0..scache.peer_count) |i| {
        scache.peers[i].max_sessions = max_sessions_per_peer;
        containers.Curl_llist_init(&scache.peers[i].sessions, cfSslScacheSessionLdestroy);
    }
    threads_psl.mutexInit(&scache.mutex);
    pscache.* = scache;
    return CURLE_OK;
}

pub export fn Curl_ssl_scache_destroy(scache_opt: ?*CurlSslScache) callconv(.c) void {
    if (scache_opt) |scache| {
        if (goodScache(scache)) {
            scache.magic = 0;
            const peer_count = scache.peer_count;
            for (0..peer_count) |i| {
                cfSslScacheClearPeer(&scache.peers[i]);
            }
            const peers_size = peer_count *| @sizeOf(CurlSslScachePeer);
            mem.secureZero(scache.peers, peers_size);
            mem.freeSized(scache.peers, peers_size);
            threads_psl.mutexDestroy(&scache.mutex);
            mem.secureZero(scache, @sizeOf(CurlSslScache));
            mem.freeSized(scache, @sizeOf(CurlSslScache));
        }
    }
}

pub export fn Curl_ssl_scache_use_zig(
    data: ?*anyopaque,
    raw_scache: ?*CurlSslScache,
    conn_config: ?*SslFilterConfig,
) callconv(.c) bool {
    if (cfSslScacheGet(data, raw_scache) != null) {
        if (conn_config) |cfg| {
            return cfg.getFlag(SslFilterConfig.BIT_CACHE_SESSION);
        }
    }
    return false;
}

pub export fn Curl_ssl_scache_lock_zig(
    data: ?*anyopaque,
    raw_scache: ?*CurlSslScache,
    has_share_scache: bool,
) callconv(.c) void {
    if (cfSslScacheGet(data, raw_scache)) |scache| {
        if (has_share_scache and builtin.output_mode == .Lib) {
            _ = c_ext.Curl_share_lock(data, CURL_LOCK_DATA_SSL_SESSION, CURL_LOCK_ACCESS_SINGLE);
        }
        threads_psl.mutexAcquire(&scache.mutex);
        scache.locking_thread = threads_psl.Curl_thread_get_current_id();
        std.debug.assert(!scache.is_locked);
        scache.is_locked = true;
        threads_psl.mutexRelease(&scache.mutex);
    }
}

pub export fn Curl_ssl_scache_unlock_zig(
    data: ?*anyopaque,
    raw_scache: ?*CurlSslScache,
    has_share_scache: bool,
) callconv(.c) void {
    if (cfSslScacheGet(data, raw_scache)) |scache| {
        threads_psl.mutexAcquire(&scache.mutex);
        scache.locking_thread = if (builtin.os.tag == .windows) 0 else @intCast(0);
        std.debug.assert(scache.is_locked);
        scache.is_locked = false;
        threads_psl.mutexRelease(&scache.mutex);
        if (has_share_scache and builtin.output_mode == .Lib) {
            _ = c_ext.Curl_share_unlock(data, CURL_LOCK_DATA_SSL_SESSION);
        }
    }
}

pub export fn Curl_ssl_scache_is_locked_by_current_thread_zig(
    data: ?*anyopaque,
    raw_scache: ?*CurlSslScache,
) callconv(.c) bool {
    const scache = cfSslScacheGet(data, raw_scache) orelse return false;
    threads_psl.mutexAcquire(&scache.mutex);
    const locked = scache.is_locked and threads_psl.Curl_thread_is_current(scache.locking_thread);
    threads_psl.mutexRelease(&scache.mutex);
    return locked;
}

fn cfSslScacheMatchAuth(peer: *const CurlSslScachePeer, conn_config_opt: ?*const SslFilterConfig) bool {
    const conn_config = conn_config_opt orelse {
        return peer.clientcert == null and peer.key_passwd == null;
    };
    if (!primitives.Curl_safecmp(peer.clientcert, conn_config.clientcert)) {
        return false;
    }
    if (primitives.Curl_timestrcmp(peer.key_passwd, conn_config.key_passwd) != 0) {
        return false;
    }
    return true;
}

fn cfSslFindPeerByKey(
    data: ?*anyopaque,
    scache: *CurlSslScache,
    trc_feat: ?*CurlTrcFeat,
    ssl_peer_key: [*:0]const u8,
    conn_config: ?*const SslFilterConfig,
    ppeer: *?*CurlSslScachePeer,
) CURLcode {
    var peer_key_len: usize = 0;
    ppeer.* = null;
    if (!goodScache(scache)) {
        return CURLE_BAD_FUNCTION_ARGUMENT;
    }

    trcSsls(data, trc_feat, "find peer slot for %s among %zu slots", .{ ssl_peer_key, scache.peer_count });

    for (0..scache.peer_count) |i| {
        if (scache.peers[i].ssl_peer_key) |pk| {
            if (std.mem.orderZ(u8, ssl_peer_key, pk) == .eq and
                cfSslScacheMatchAuth(&scache.peers[i], conn_config))
            {
                ppeer.* = &scache.peers[i];
                return CURLE_OK;
            }
        }
    }

    for (0..scache.peer_count) |i| {
        if (scache.peers[i].ssl_peer_key == null and
            scache.peers[i].getHmacSet() and
            cfSslScacheMatchAuth(&scache.peers[i], conn_config))
        {
            var my_hmac: [CURL_SHA256_DIGEST_LENGTH]u8 = undefined;
            if (peer_key_len == 0) {
                peer_key_len = std.mem.len(ssl_peer_key);
            }
            const result = crypto.Curl_hmacit(
                &crypto.Curl_HMAC_SHA256[0],
                &scache.peers[i].key_salt,
                scache.peers[i].key_salt.len,
                ssl_peer_key,
                peer_key_len,
                &my_hmac,
            );
            if (result != CURLE_OK) return result;
            if (std.mem.eql(u8, &scache.peers[i].key_hmac, &my_hmac)) {
                trcSsls(data, trc_feat, "peer entry %zu key recovered: %s", .{ i, ssl_peer_key });
                scache.peers[i].ssl_peer_key = mem.strdup(ssl_peer_key) orelse return CURLE_OUT_OF_MEMORY;
                cfSslCachePeerUpdate(&scache.peers[i]);
                ppeer.* = &scache.peers[i];
                return CURLE_OK;
            }
        }
    }

    trcSsls(data, trc_feat, "peer not found for %s", .{ssl_peer_key});
    return CURLE_OK;
}

fn cfSslGetFreePeer(scache: *CurlSslScache) ?*CurlSslScachePeer {
    var peer: ?*CurlSslScachePeer = null;
    for (0..scache.peer_count) |i| {
        if (scache.peers[i].ssl_peer_key == null and !scache.peers[i].getHmacSet()) {
            peer = &scache.peers[i];
            break;
        }
        if (scache.peers[i].sobj == null and containers.Curl_llist_count(&scache.peers[i].sessions) == 0) {
            peer = &scache.peers[i];
            break;
        }
        if (peer == null or scache.peers[i].age < peer.?.age) {
            peer = &scache.peers[i];
        }
    }
    if (peer) |p| {
        cfSslScacheClearPeer(p);
    }
    return peer;
}

fn cfSslAddPeer(
    data: ?*anyopaque,
    scache: *CurlSslScache,
    trc_feat: ?*CurlTrcFeat,
    ssl_peer_key: ?[*:0]const u8,
    conn_config: ?*const SslFilterConfig,
    ppeer: *?*CurlSslScachePeer,
) CURLcode {
    var peer: ?*CurlSslScachePeer = null;
    var result: CURLcode = CURLE_OK;

    ppeer.* = null;
    if (ssl_peer_key) |spk| {
        result = cfSslFindPeerByKey(data, scache, trc_feat, spk, conn_config, &peer);
        if (result != CURLE_OK or scache.peer_count == 0) {
            return result;
        }
    }

    if (peer != null) {
        ppeer.* = peer;
        return CURLE_OK;
    }

    peer = cfSslGetFreePeer(scache);
    if (peer) |p| {
        var buffer: [64]u8 = undefined;
        var ccert: ?[*:0]const u8 = if (conn_config) |cfg| cfg.clientcert else null;
        const kpasswd: ?[*:0]const u8 = if (conn_config) |cfg| cfg.key_passwd else null;
        if (ccert == null and conn_config != null and conn_config.?.cert_blob != null) {
            _ = curl_msnprintf(
                &buffer,
                buffer.len,
                "cert-%p",
                conn_config.?.cert_blob.?.data,
            );
            ccert = @ptrCast(&buffer);
        }
        result = cfSslScachePeerInit(p, ssl_peer_key, ccert, kpasswd, null, null);
        if (result != CURLE_OK) {
            cfSslScacheClearPeer(p);
            return result;
        }
        ppeer.* = p;
    }
    return CURLE_OK;
}

fn cfScachePeerAddSession(peer: *CurlSslScachePeer, s: *CurlSslSession, now: curl_off_t) void {
    if (s.ietf_tls_id != CURL_IETF_PROTO_TLS1_3) {
        containers.Curl_llist_destroy(&peer.sessions, null);
        containers.Curl_llist_append(&peer.sessions, s, &s.list);
    } else {
        cfScachePeerRemoveExpired(peer, now);
        cfScachePeerRemoveNon13(peer);
        containers.Curl_llist_append(&peer.sessions, s, &s.list);
        while (containers.Curl_llist_count(&peer.sessions) > peer.max_sessions) {
            if (containers.Curl_llist_head(&peer.sessions)) |head| {
                containers.Curl_node_remove(head);
            } else break;
        }
    }
}

fn cfScacheAddSession(
    data: ?*anyopaque,
    scache_opt: ?*CurlSslScache,
    conn_config: ?*const SslFilterConfig,
    trc_feat: ?*CurlTrcFeat,
    ssl_peer_key: [*:0]const u8,
    s: *CurlSslSession,
) CURLcode {
    var peer: ?*CurlSslScachePeer = null;
    const now = nowEpochSecs();

    const scache = scache_opt orelse {
        Curl_ssl_session_destroy(s);
        return CURLE_OK;
    };
    if (scache.peer_count == 0) {
        Curl_ssl_session_destroy(s);
        return CURLE_OK;
    }

    if (s.valid_until <= 0) {
        s.valid_until = now + scache.default_lifetime_secs;
    }

    const max_lifetime = if (s.ietf_tls_id == CURL_IETF_PROTO_TLS1_3)
        CURL_SCACHE_MAX_13_LIFETIME_SEC
    else
        CURL_SCACHE_MAX_12_LIFETIME_SEC;
    if (s.valid_until > (now + max_lifetime)) {
        s.valid_until = now + max_lifetime;
    }

    if (cfScacheSessionExpired(s, now)) {
        trcSsls(data, trc_feat, "add, session already expired", .{});
        Curl_ssl_session_destroy(s);
        return CURLE_OK;
    }

    const result = cfSslAddPeer(data, scache, trc_feat, ssl_peer_key, conn_config, &peer);
    if (result != CURLE_OK or peer == null) {
        trcSsls(data, trc_feat, "unable to add scache peer: %d", .{@as(c_int, @intCast(result))});
        Curl_ssl_session_destroy(s);
        failf(data, "[SCACHE] failed to add session for %s, error=%d", .{ ssl_peer_key, @as(c_int, @intCast(result)) });
        return result;
    }

    cfScachePeerAddSession(peer.?, s, now);
    const yes_str: [*:0]const u8 = "yes";
    const no_str: [*:0]const u8 = "no";
    trcSsls(
        data,
        trc_feat,
        "added session for %s [proto=0x%x, valid_secs=%lld, alpn=%s, earlydata=%zu, quic_tp=%s], peer has %zu sessions now",
        .{
            ssl_peer_key,
            @as(c_uint, @intCast(s.ietf_tls_id)),
            @as(c_longlong, s.valid_until - now),
            s.alpn,
            s.earlydata_max,
            if (s.quic_tp != null) yes_str else no_str,
            containers.Curl_llist_count(&peer.?.sessions),
        },
    );
    return CURLE_OK;
}

pub export fn Curl_ssl_scache_put_zig(
    cf: ?*anyopaque,
    data: ?*anyopaque,
    raw_scache: ?*CurlSslScache,
    has_share_scache: bool,
    conn_config_opt: ?*SslFilterConfig,
    trc_feat: ?*CurlTrcFeat,
    ssl_peer_key: [*:0]const u8,
    s: ?*CurlSslSession,
) callconv(.c) CURLcode {
    _ = cf;
    const sess = s orelse return CURLE_OK;
    const scache = cfSslScacheGet(data, raw_scache);
    const conn_config = conn_config_opt orelse {
        Curl_ssl_session_destroy(sess);
        return CURLE_OK;
    };

    if (scache == null or !conn_config.getFlag(SslFilterConfig.BIT_CACHE_SESSION)) {
        Curl_ssl_session_destroy(sess);
        return CURLE_OK;
    }

    Curl_ssl_scache_lock_zig(data, scache, has_share_scache);
    const result = cfScacheAddSession(data, scache, conn_config, trc_feat, ssl_peer_key, sess);
    Curl_ssl_scache_unlock_zig(data, scache, has_share_scache);
    return result;
}

pub export fn Curl_ssl_scache_return_zig(
    cf: ?*anyopaque,
    data: ?*anyopaque,
    raw_scache: ?*CurlSslScache,
    has_share_scache: bool,
    conn_config: ?*SslFilterConfig,
    trc_feat: ?*CurlTrcFeat,
    ssl_peer_key: [*:0]const u8,
    s_opt: ?*CurlSslSession,
) callconv(.c) void {
    if (s_opt) |s| {
        if (s.ietf_tls_id < 0x304) {
            _ = Curl_ssl_scache_put_zig(cf, data, raw_scache, has_share_scache, conn_config, trc_feat, ssl_peer_key, s);
            return;
        }
    }
    Curl_ssl_session_destroy(s_opt);
}

pub export fn Curl_ssl_scache_take_zig(
    cf: ?*anyopaque,
    data: ?*anyopaque,
    raw_scache: ?*CurlSslScache,
    has_share_scache: bool,
    conn_config: ?*SslFilterConfig,
    trc_feat: ?*CurlTrcFeat,
    ssl_peer_key: [*:0]const u8,
    ps: *?*CurlSslSession,
) callconv(.c) CURLcode {
    _ = cf;
    ps.* = null;
    const scache = cfSslScacheGet(data, raw_scache) orelse return CURLE_OK;

    var peer: ?*CurlSslScachePeer = null;
    var s: ?*CurlSslSession = null;

    Curl_ssl_scache_lock_zig(data, scache, has_share_scache);
    const result = cfSslFindPeerByKey(data, scache, trc_feat, ssl_peer_key, conn_config, &peer);
    if (result == CURLE_OK and peer != null) {
        const p = peer.?;
        cfScachePeerRemoveExpired(p, nowEpochSecs());
        if (containers.Curl_llist_head(&p.sessions)) |n| {
            s = @ptrCast(@alignCast(containers.Curl_node_take_elem(n)));
            scache.age += 1;
            p.age = scache.age;
        }
    }
    if (s) |sess| {
        ps.* = sess;
        const yes_str: [*:0]const u8 = "yes";
        const no_str: [*:0]const u8 = "no";
        trcSsls(
            data,
            trc_feat,
            "took session for %s [proto=0x%x, alpn=%s, earlydata=%zu, quic_tp=%s], %zu sessions remain",
            .{
                ssl_peer_key,
                @as(c_uint, @intCast(sess.ietf_tls_id)),
                sess.alpn,
                sess.earlydata_max,
                if (sess.quic_tp != null) yes_str else no_str,
                containers.Curl_llist_count(&peer.?.sessions),
            },
        );
    } else {
        trcSsls(data, trc_feat, "no cached session for %s", .{ssl_peer_key});
    }
    Curl_ssl_scache_unlock_zig(data, scache, has_share_scache);
    return result;
}

pub export fn Curl_ssl_scache_add_obj_zig(
    cf: ?*anyopaque,
    data: ?*anyopaque,
    raw_scache: ?*CurlSslScache,
    conn_config: ?*SslFilterConfig,
    trc_feat: ?*CurlTrcFeat,
    ssl_peer_key: [*:0]const u8,
    sobj_in: ?*anyopaque,
    sobj_dtor_cb: ?CurlSslScacheObjDtor,
) callconv(.c) CURLcode {
    _ = cf;
    var sobj = sobj_in;
    const scache = cfSslScacheGet(data, raw_scache) orelse {
        if (sobj != null and sobj_dtor_cb != null) {
            sobj_dtor_cb.?(sobj);
        }
        return CURLE_BAD_FUNCTION_ARGUMENT;
    };

    var peer: ?*CurlSslScachePeer = null;
    const result = cfSslAddPeer(data, scache, trc_feat, ssl_peer_key, conn_config, &peer);
    if (result != CURLE_OK or peer == null) {
        trcSsls(data, trc_feat, "unable to add scache peer: %d", .{@as(c_int, @intCast(result))});
        if (sobj != null and sobj_dtor_cb != null) {
            sobj_dtor_cb.?(sobj);
        }
        return result;
    }

    cfSslScachePeerSetObj(peer.?, sobj, sobj_dtor_cb);
    sobj = null;
    return CURLE_OK;
}

pub export fn Curl_ssl_scache_get_obj_zig(
    cf: ?*anyopaque,
    data: ?*anyopaque,
    raw_scache: ?*CurlSslScache,
    conn_config: ?*SslFilterConfig,
    trc_feat: ?*CurlTrcFeat,
    ssl_peer_key: [*:0]const u8,
) callconv(.c) ?*anyopaque {
    _ = cf;
    const scache = cfSslScacheGet(data, raw_scache) orelse return null;
    var peer: ?*CurlSslScachePeer = null;
    const result = cfSslFindPeerByKey(data, scache, trc_feat, ssl_peer_key, conn_config, &peer);
    if (result != CURLE_OK) return null;

    const sobj = if (peer) |p| p.sobj else null;
    const found_str: [*:0]const u8 = "Found";
    const no_str: [*:0]const u8 = "No";
    trcSsls(data, trc_feat, "%s cached session for '%s'", .{ if (sobj != null) found_str else no_str, ssl_peer_key });
    return sobj;
}

pub export fn Curl_ssl_scache_remove_all_zig(
    cf: ?*anyopaque,
    data: ?*anyopaque,
    raw_scache: ?*CurlSslScache,
    has_share_scache: bool,
    conn_config: ?*SslFilterConfig,
    trc_feat: ?*CurlTrcFeat,
    ssl_peer_key: [*:0]const u8,
) callconv(.c) void {
    _ = cf;
    const scache = cfSslScacheGet(data, raw_scache) orelse return;
    var peer: ?*CurlSslScachePeer = null;
    Curl_ssl_scache_lock_zig(data, scache, has_share_scache);
    const result = cfSslFindPeerByKey(data, scache, trc_feat, ssl_peer_key, conn_config, &peer);
    if (result == CURLE_OK and peer != null) {
        cfSslScacheClearPeer(peer.?);
    }
    Curl_ssl_scache_unlock_zig(data, scache, has_share_scache);
}

fn cfSslScachePeerSetHmac(peer: *CurlSslScachePeer) CURLcode {
    const spk = peer.ssl_peer_key orelse return CURLE_BAD_FUNCTION_ARGUMENT;
    var result = http1_options.Curl_rand_bytes(null, &peer.key_salt, peer.key_salt.len);
    if (result != CURLE_OK) return result;

    result = crypto.Curl_hmacit(
        &crypto.Curl_HMAC_SHA256[0],
        &peer.key_salt,
        peer.key_salt.len,
        spk,
        std.mem.len(spk),
        &peer.key_hmac,
    );
    if (result == CURLE_OK) {
        peer.setHmacSet(true);
    }
    return result;
}

fn cfSslFindPeerByHmac(
    scache: *CurlSslScache,
    salt: [*]const u8,
    hmac: [*]const u8,
    ppeer: *?*CurlSslScachePeer,
) CURLcode {
    ppeer.* = null;
    if (!goodScache(scache)) return CURLE_BAD_FUNCTION_ARGUMENT;

    for (0..scache.peer_count) |i| {
        const peer = &scache.peers[i];
        if (!cfSslScacheMatchAuth(peer, null)) continue;
        if (peer.getHmacSet() and
            std.mem.eql(u8, &peer.key_salt, salt[0..CURL_SHA256_DIGEST_LENGTH]) and
            std.mem.eql(u8, &peer.key_hmac, hmac[0..CURL_SHA256_DIGEST_LENGTH]))
        {
            ppeer.* = peer;
            return CURLE_OK;
        } else if (peer.ssl_peer_key) |spk| {
            var my_hmac: [CURL_SHA256_DIGEST_LENGTH]u8 = undefined;
            const result = crypto.Curl_hmacit(
                &crypto.Curl_HMAC_SHA256[0],
                salt,
                CURL_SHA256_DIGEST_LENGTH,
                spk,
                std.mem.len(spk),
                &my_hmac,
            );
            if (result != CURLE_OK) return result;
            if (std.mem.eql(u8, &my_hmac, hmac[0..CURL_SHA256_DIGEST_LENGTH])) {
                if (!peer.getHmacSet()) {
                    @memcpy(&peer.key_salt, salt[0..CURL_SHA256_DIGEST_LENGTH]);
                    @memcpy(&peer.key_hmac, hmac[0..CURL_SHA256_DIGEST_LENGTH]);
                    peer.setHmacSet(true);
                }
                ppeer.* = peer;
                return CURLE_OK;
            }
        }
    }
    return CURLE_OK;
}

pub export fn Curl_ssl_session_import_zig(
    data: ?*anyopaque,
    raw_scache: ?*CurlSslScache,
    has_share_scache: bool,
    trc_feat: ?*CurlTrcFeat,
    ssl_peer_key: ?[*:0]const u8,
    shmac: ?[*]const u8,
    shmac_len: usize,
    sdata: ?*const anyopaque,
    sdata_len: usize,
) callconv(.c) CURLcode {
    const scache = cfSslScacheGet(data, raw_scache);
    var peer: ?*CurlSslScachePeer = null;
    var s: ?*CurlSslSession = null;
    var have_lock = false;
    var result: CURLcode = CURLE_OK;

    if (scache == null or sdata == null or sdata_len == 0) {
        return CURLE_BAD_FUNCTION_ARGUMENT;
    }
    if (ssl_peer_key == null and (shmac == null or shmac_len == 0)) {
        return CURLE_BAD_FUNCTION_ARGUMENT;
    }

    result = vtls_core.Curl_ssl_session_unpack(data, sdata, sdata_len, &s);
    if (result != CURLE_OK) {
        Curl_ssl_session_destroy(s);
        return result;
    }

    Curl_ssl_scache_lock_zig(data, scache, has_share_scache);
    have_lock = true;

    if (ssl_peer_key != null) {
        result = cfSslAddPeer(data, scache.?, trc_feat, ssl_peer_key, null, &peer);
        if (result != CURLE_OK) {
            if (have_lock) Curl_ssl_scache_unlock_zig(data, scache, has_share_scache);
            Curl_ssl_session_destroy(s);
            return result;
        }
    } else if (shmac_len != (CURL_SHA256_DIGEST_LENGTH * 2)) {
        if (have_lock) Curl_ssl_scache_unlock_zig(data, scache, has_share_scache);
        Curl_ssl_session_destroy(s);
        return CURLE_BAD_FUNCTION_ARGUMENT;
    } else {
        const salt = shmac.?;
        const hmac = shmac.? + CURL_SHA256_DIGEST_LENGTH;
        result = cfSslFindPeerByHmac(scache.?, salt, hmac, &peer);
        if (result != CURLE_OK) {
            if (have_lock) Curl_ssl_scache_unlock_zig(data, scache, has_share_scache);
            Curl_ssl_session_destroy(s);
            return result;
        }
        if (peer == null) {
            peer = cfSslGetFreePeer(scache.?);
            if (peer) |p| {
                result = cfSslScachePeerInit(p, ssl_peer_key, null, null, salt, hmac);
                if (result != CURLE_OK) {
                    if (have_lock) Curl_ssl_scache_unlock_zig(data, scache, has_share_scache);
                    Curl_ssl_session_destroy(s);
                    return result;
                }
            }
        }
    }

    if (peer) |p| {
        cfScachePeerAddSession(p, s.?, nowEpochSecs());
        s = null;
        const without_key: [*:0]const u8 = "without key";
        trcSsls(
            data,
            trc_feat,
            "successfully imported ticket for peer %s, now with %zu tickets",
            .{
                if (p.ssl_peer_key) |spk| @as([*:0]const u8, spk) else without_key,
                containers.Curl_llist_count(&p.sessions),
            },
        );
    }

    if (have_lock) {
        Curl_ssl_scache_unlock_zig(data, scache, has_share_scache);
    }
    Curl_ssl_session_destroy(s);
    return result;
}

pub const CurlSslsExportCb = *const fn (
    data: ?*anyopaque,
    userptr: ?*anyopaque,
    session_key: ?[*:0]const u8,
    shmac: ?[*]const u8,
    shmac_len: usize,
    sdata: ?*const anyopaque,
    sdata_len: usize,
    valid_until: curl_off_t,
    ietf_tls_id: c_int,
    alpn: ?[*:0]const u8,
    earlydata_max: usize,
) callconv(.c) CURLcode;

pub export fn Curl_ssl_session_export_zig(
    data: ?*anyopaque,
    raw_scache: ?*CurlSslScache,
    has_share_scache: bool,
    trc_feat: ?*CurlTrcFeat,
    export_fn_opt: ?CurlSslsExportCb,
    userptr: ?*anyopaque,
) callconv(.c) CURLcode {
    const export_fn = export_fn_opt orelse return CURLE_BAD_FUNCTION_ARGUMENT;
    const scache_opt = cfSslScacheGet(data, raw_scache);
    var hbuf: dynbuf = undefined;
    var sbuf: dynbuf = undefined;
    const now = nowEpochSecs();
    var result: CURLcode = CURLE_OK;
    var npeers: usize = 0;
    var ntickets: usize = 0;

    Curl_ssl_scache_lock_zig(data, scache_opt, has_share_scache);
    containers.curlx_dyn_init(&hbuf, (CURL_SHA256_DIGEST_LENGTH * 2) + 1);
    containers.curlx_dyn_init(&sbuf, CURL_SSL_TICKET_MAX);
    defer {
        Curl_ssl_scache_unlock_zig(data, scache_opt, has_share_scache);
        containers.curlx_dyn_free(&hbuf);
        containers.curlx_dyn_free(&sbuf);
    }

    if (scache_opt) |scache| {
        for (0..scache.peer_count) |i| {
            const peer = &scache.peers[i];
            if (peer.ssl_peer_key == null and !peer.getHmacSet()) continue;
            if (!peer.getExportable()) continue;

            containers.curlx_dyn_reset(&hbuf);
            cfScachePeerRemoveExpired(peer, now);
            var n = containers.Curl_llist_head(&peer.sessions);
            if (n != null) {
                npeers += 1;
            }
            while (n) |node| {
                const s: *CurlSslSession = @ptrCast(@alignCast(containers.Curl_node_elem(node).?));
                if (!peer.getHmacSet()) {
                    result = cfSslScachePeerSetHmac(peer);
                    if (result != CURLE_OK) return result;
                }
                if (containers.curlx_dyn_len(&hbuf) == 0) {
                    result = containers.curlx_dyn_addn(&hbuf, &peer.key_salt, peer.key_salt.len);
                    if (result != CURLE_OK) return result;
                    result = containers.curlx_dyn_addn(&hbuf, &peer.key_hmac, peer.key_hmac.len);
                    if (result != CURLE_OK) return result;
                }
                containers.curlx_dyn_reset(&sbuf);
                result = vtls_core.Curl_ssl_session_pack(data, s, &sbuf);
                if (result != CURLE_OK) return result;

                result = export_fn(
                    data,
                    userptr,
                    peer.ssl_peer_key,
                    containers.curlx_dyn_uptr(&hbuf),
                    containers.curlx_dyn_len(&hbuf),
                    containers.curlx_dyn_uptr(&sbuf),
                    containers.curlx_dyn_len(&sbuf),
                    s.valid_until,
                    s.ietf_tls_id,
                    s.alpn,
                    s.earlydata_max,
                );
                if (result != CURLE_OK) return result;
                ntickets += 1;
                n = containers.Curl_node_next(node);
            }
        }
    }

    trcSsls(data, trc_feat, "exported %zu session tickets for %zu peers", .{ ntickets, npeers });
    return CURLE_OK;
}

// ============================================================================
// 3. lib/vtls/x509asn1.c (lib/vtls/x509asn1.h)
// ============================================================================

pub const CURL_ASN1_BOOLEAN: u8 = 1;
pub const CURL_ASN1_INTEGER: u8 = 2;
pub const CURL_ASN1_BIT_STRING: u8 = 3;
pub const CURL_ASN1_OCTET_STRING: u8 = 4;
pub const CURL_ASN1_NULL: u8 = 5;
pub const CURL_ASN1_OBJECT_IDENTIFIER: u8 = 6;
pub const CURL_ASN1_ENUMERATED: u8 = 10;
pub const CURL_ASN1_UTF8_STRING: u8 = 12;
pub const CURL_ASN1_NUMERIC_STRING: u8 = 18;
pub const CURL_ASN1_PRINTABLE_STRING: u8 = 19;
pub const CURL_ASN1_TELETEX_STRING: u8 = 20;
pub const CURL_ASN1_IA5_STRING: u8 = 22;
pub const CURL_ASN1_UTC_TIME: u8 = 23;
pub const CURL_ASN1_GENERALIZED_TIME: u8 = 24;
pub const CURL_ASN1_VISIBLE_STRING: u8 = 26;
pub const CURL_ASN1_UNIVERSAL_STRING: u8 = 28;
pub const CURL_ASN1_BMP_STRING: u8 = 30;

const Asn1FlagsType = if (builtin.os.tag == .windows) u32 else u8;

pub const CurlAsn1Element = extern struct {
    header: ?[*]const u8,
    beg: ?[*]const u8,
    end: ?[*]const u8,
    eclass: u8,
    tag: u8,
    _win_pad: if (builtin.os.tag == .windows) [2]u8 else [0]u8 = if (builtin.os.tag == .windows) .{ 0, 0 } else .{},
    flags: Asn1FlagsType,

    pub inline fn getConstructed(self: *const CurlAsn1Element) bool {
        return (self.flags & 1) != 0;
    }

    pub inline fn setConstructed(self: *CurlAsn1Element, val: bool) void {
        if (val) {
            self.flags |= 1;
        } else {
            self.flags &= ~@as(Asn1FlagsType, 1);
        }
    }
};

pub const CurlX509certificate = extern struct {
    certificate: CurlAsn1Element,
    version: CurlAsn1Element,
    serialNumber: CurlAsn1Element,
    signatureAlgorithm: CurlAsn1Element,
    signature: CurlAsn1Element,
    issuer: CurlAsn1Element,
    notBefore: CurlAsn1Element,
    notAfter: CurlAsn1Element,
    subject: CurlAsn1Element,
    subjectPublicKeyInfo: CurlAsn1Element,
    subjectPublicKeyAlgorithm: CurlAsn1Element,
    subjectPublicKey: CurlAsn1Element,
    issuerUniqueID: CurlAsn1Element,
    subjectUniqueID: CurlAsn1Element,
    extensions: CurlAsn1Element,
};

const CurlOid = struct {
    numoid: [*:0]const u8,
    textoid: [*:0]const u8,
};

const OIDtable = [_]CurlOid{
    .{ .numoid = "1.2.840.10040.4.1", .textoid = "dsa" },
    .{ .numoid = "1.2.840.10040.4.3", .textoid = "dsa-with-sha1" },
    .{ .numoid = "1.2.840.10045.2.1", .textoid = "ecPublicKey" },
    .{ .numoid = "1.2.840.10045.3.0.1", .textoid = "c2pnb163v1" },
    .{ .numoid = "1.2.840.10045.4.1", .textoid = "ecdsa-with-SHA1" },
    .{ .numoid = "1.2.840.10045.4.3.1", .textoid = "ecdsa-with-SHA224" },
    .{ .numoid = "1.2.840.10045.4.3.2", .textoid = "ecdsa-with-SHA256" },
    .{ .numoid = "1.2.840.10045.4.3.3", .textoid = "ecdsa-with-SHA384" },
    .{ .numoid = "1.2.840.10045.4.3.4", .textoid = "ecdsa-with-SHA512" },
    .{ .numoid = "1.2.840.10046.2.1", .textoid = "dhpublicnumber" },
    .{ .numoid = "1.2.840.113549.1.1.1", .textoid = "rsaEncryption" },
    .{ .numoid = "1.2.840.113549.1.1.2", .textoid = "md2WithRSAEncryption" },
    .{ .numoid = "1.2.840.113549.1.1.4", .textoid = "md5WithRSAEncryption" },
    .{ .numoid = "1.2.840.113549.1.1.5", .textoid = "sha1WithRSAEncryption" },
    .{ .numoid = "1.2.840.113549.1.1.10", .textoid = "RSASSA-PSS" },
    .{ .numoid = "1.2.840.113549.1.1.14", .textoid = "sha224WithRSAEncryption" },
    .{ .numoid = "1.2.840.113549.1.1.11", .textoid = "sha256WithRSAEncryption" },
    .{ .numoid = "1.2.840.113549.1.1.12", .textoid = "sha384WithRSAEncryption" },
    .{ .numoid = "1.2.840.113549.1.1.13", .textoid = "sha512WithRSAEncryption" },
    .{ .numoid = "1.2.840.113549.2.2", .textoid = "md2" },
    .{ .numoid = "1.2.840.113549.2.5", .textoid = "md5" },
    .{ .numoid = "1.3.14.3.2.26", .textoid = "sha1" },
    .{ .numoid = "2.5.4.3", .textoid = "CN" },
    .{ .numoid = "2.5.4.4", .textoid = "SN" },
    .{ .numoid = "2.5.4.5", .textoid = "serialNumber" },
    .{ .numoid = "2.5.4.6", .textoid = "C" },
    .{ .numoid = "2.5.4.7", .textoid = "L" },
    .{ .numoid = "2.5.4.8", .textoid = "ST" },
    .{ .numoid = "2.5.4.9", .textoid = "streetAddress" },
    .{ .numoid = "2.5.4.10", .textoid = "O" },
    .{ .numoid = "2.5.4.11", .textoid = "OU" },
    .{ .numoid = "2.5.4.12", .textoid = "title" },
    .{ .numoid = "2.5.4.13", .textoid = "description" },
    .{ .numoid = "2.5.4.17", .textoid = "postalCode" },
    .{ .numoid = "2.5.4.41", .textoid = "name" },
    .{ .numoid = "2.5.4.42", .textoid = "givenName" },
    .{ .numoid = "2.5.4.43", .textoid = "initials" },
    .{ .numoid = "2.5.4.44", .textoid = "generationQualifier" },
    .{ .numoid = "2.5.4.45", .textoid = "X500UniqueIdentifier" },
    .{ .numoid = "2.5.4.46", .textoid = "dnQualifier" },
    .{ .numoid = "2.5.4.65", .textoid = "pseudonym" },
    .{ .numoid = "1.2.840.113549.1.9.1", .textoid = "emailAddress" },
    .{ .numoid = "2.5.4.72", .textoid = "role" },
    .{ .numoid = "2.5.29.17", .textoid = "subjectAltName" },
    .{ .numoid = "2.5.29.18", .textoid = "issuerAltName" },
    .{ .numoid = "2.5.29.19", .textoid = "basicConstraints" },
    .{ .numoid = "2.16.840.1.101.3.4.2.4", .textoid = "sha224" },
    .{ .numoid = "2.16.840.1.101.3.4.2.1", .textoid = "sha256" },
    .{ .numoid = "2.16.840.1.101.3.4.2.2", .textoid = "sha384" },
    .{ .numoid = "2.16.840.1.101.3.4.2.3", .textoid = "sha512" },
    .{ .numoid = "1.2.840.113549.1.9.2", .textoid = "unstructuredName" },
};

fn searchOID(oid_opt: ?[*:0]const u8) ?*const CurlOid {
    const oid = oid_opt orelse return null;
    for (&OIDtable) |*op| {
        if (std.mem.orderZ(u8, op.numoid, oid) == .eq or primitives.curl_strequal(op.textoid, oid) != 0) {
            return op;
        }
    }
    return null;
}

fn getASN1ElementImpl(
    elem: *CurlAsn1Element,
    beg_opt: ?[*]const u8,
    end_opt: ?[*]const u8,
    lvl: usize,
) ?[*]const u8 {
    var beg = beg_opt orelse return null;
    const end = end_opt orelse return null;
    if (@intFromPtr(beg) >= @intFromPtr(end) or beg[0] == 0 or
        (@intFromPtr(end) - @intFromPtr(beg) > CURL_ASN1_MAX) or
        lvl >= CURL_ASN1_MAX_RECURSIONS)
    {
        return null;
    }
    const next_lvl = lvl + 1;

    elem.header = beg;
    var b = beg[0];
    beg += 1;
    elem.setConstructed((b & 0x20) != 0);
    elem.eclass = (b >> 6) & 3;
    b &= 0x1F;
    if (b == 0x1F) return null;
    elem.tag = b;

    if (@intFromPtr(beg) >= @intFromPtr(end)) return null;
    b = beg[0];
    beg += 1;
    var len: usize = 0;
    if ((b & 0x80) == 0) {
        len = b;
    } else {
        b &= 0x7F;
        if (b == 0) {
            if (!elem.getConstructed()) return null;
            elem.beg = beg;
            var lelem: CurlAsn1Element = std.mem.zeroes(CurlAsn1Element);
            while (@intFromPtr(beg) < @intFromPtr(end) and beg[0] != 0) {
                beg = getASN1ElementImpl(&lelem, beg, end, next_lvl) orelse return null;
            }
            if (@intFromPtr(end) - @intFromPtr(beg) < 2 or beg[1] != 0) {
                return null;
            }
            elem.end = beg;
            return beg + 2;
        } else if (b > (@intFromPtr(end) - @intFromPtr(beg))) {
            return null;
        } else {
            len = 0;
            var rem: u8 = b;
            while (rem > 0) : (rem -= 1) {
                if ((len & 0xFF000000) != 0) return null;
                len = (len << 8) | beg[0];
                beg += 1;
            }
        }
    }
    if (len > (@intFromPtr(end) - @intFromPtr(beg))) {
        return null;
    }
    elem.beg = beg;
    elem.end = beg + len;
    return elem.end;
}

pub export fn getASN1Element(
    elem: *CurlAsn1Element,
    beg: ?[*]const u8,
    end: ?[*]const u8,
) callconv(.c) ?[*]const u8 {
    return getASN1ElementImpl(elem, beg, end, 0);
}

fn bool2str(store: *dynbuf, beg: [*]const u8, end: [*]const u8) CURLcode {
    if (@intFromPtr(end) - @intFromPtr(beg) != 1) {
        return CURLE_BAD_FUNCTION_ARGUMENT;
    }
    const val = beg[0];
    if (val != 0xff and val != 0x00) {
        return CURLE_BAD_FUNCTION_ARGUMENT;
    }
    return containers.curlx_dyn_add(store, if (val != 0) "TRUE" else "FALSE");
}

fn octet2str(store: *dynbuf, beg_in: [*]const u8, end: [*]const u8) CURLcode {
    var result: CURLcode = CURLE_OK;
    var beg = beg_in;
    while (result == CURLE_OK and @intFromPtr(beg) < @intFromPtr(end)) : (beg += 1) {
        result = curlx_dyn_addf(store, "%02x:", @as(c_uint, beg[0]));
    }
    return result;
}

fn bit2str(store: *dynbuf, beg_in: [*]const u8, end: [*]const u8) CURLcode {
    var beg = beg_in;
    if (@intFromPtr(beg) < @intFromPtr(end)) {
        const unused_bits = beg[0];
        beg += 1;
        if (unused_bits > 7) return CURLE_BAD_FUNCTION_ARGUMENT;
    } else {
        return CURLE_BAD_FUNCTION_ARGUMENT;
    }
    return octet2str(store, beg, end);
}

fn int2str(store: *dynbuf, beg: [*]const u8, end: [*]const u8) CURLcode {
    var uval: u32 = 0;
    const n = @intFromPtr(end) - @intFromPtr(beg);
    if (n == 0) return CURLE_BAD_FUNCTION_ARGUMENT;
    if (n > 4) return octet2str(store, beg, end);

    if ((beg[0] & 0x80) != 0) {
        uval = ~@as(u32, 0);
    }
    for (0..n) |i| {
        uval = (uval << 8) | beg[i];
    }
    const sval: i32 = @bitCast(uval);
    if (sval > -10000 and sval < 10000) {
        return curlx_dyn_addf(store, "%d", @as(c_int, sval));
    }
    return curlx_dyn_addf(store, "0x%x", @as(c_uint, uval));
}

fn utf8asn1str(to: *dynbuf, asn1_type: c_int, from_in: [*]const u8, end: [*]const u8) CURLcode {
    var from = from_in;
    const inlength = @intFromPtr(end) - @intFromPtr(from);
    const size: usize = switch (@as(u8, @intCast(asn1_type))) {
        CURL_ASN1_BMP_STRING => 2,
        CURL_ASN1_UNIVERSAL_STRING => 4,
        CURL_ASN1_NUMERIC_STRING,
        CURL_ASN1_PRINTABLE_STRING,
        CURL_ASN1_TELETEX_STRING,
        CURL_ASN1_IA5_STRING,
        CURL_ASN1_VISIBLE_STRING,
        CURL_ASN1_UTF8_STRING,
        => 1,
        else => return CURLE_BAD_FUNCTION_ARGUMENT,
    };

    if ((inlength % size) != 0) {
        return CURLE_BAD_FUNCTION_ARGUMENT;
    }

    var result: CURLcode = CURLE_OK;
    if (@as(u8, @intCast(asn1_type)) == CURL_ASN1_UTF8_STRING) {
        if (inlength > 0) {
            result = containers.curlx_dyn_addn(to, from, inlength);
        }
    } else {
        while (result == CURLE_OK and @intFromPtr(from) < @intFromPtr(end)) {
            var buf: [4]u8 = undefined;
            var charsize: usize = 1;
            var wc: u32 = 0;

            switch (size) {
                4 => {
                    wc = (wc << 8) | from[0];
                    from += 1;
                    wc = (wc << 8) | from[0];
                    from += 1;
                    wc = (wc << 8) | from[0];
                    from += 1;
                    wc = (wc << 8) | from[0];
                    from += 1;
                },
                2 => {
                    wc = (wc << 8) | from[0];
                    from += 1;
                    wc = (wc << 8) | from[0];
                    from += 1;
                },
                else => {
                    wc = (wc << 8) | from[0];
                    from += 1;
                },
            }
            if (wc >= 0x00000080) {
                if (wc >= 0x00000800) {
                    if (wc >= 0x00010000) {
                        if (wc >= 0x00200000) {
                            return CURLE_WEIRD_SERVER_REPLY;
                        }
                        buf[3] = @truncate(0x80 | (wc & 0x3F));
                        wc = (wc >> 6) | 0x00010000;
                        charsize += 1;
                    }
                    buf[2] = @truncate(0x80 | (wc & 0x3F));
                    wc = (wc >> 6) | 0x00000800;
                    charsize += 1;
                }
                buf[1] = @truncate(0x80 | (wc & 0x3F));
                wc = (wc >> 6) | 0x000000C0;
                charsize += 1;
            }
            buf[0] = @truncate(wc);
            result = containers.curlx_dyn_addn(to, &buf, charsize);
        }
    }
    return result;
}

pub export fn encodeOID(
    store: *dynbuf,
    beg_opt: ?[*]const u8,
    end_opt: ?[*]const u8,
) callconv(.c) CURLcode {
    var beg = beg_opt orelse return CURLE_BAD_FUNCTION_ARGUMENT;
    const end = end_opt orelse return CURLE_BAD_FUNCTION_ARGUMENT;
    if (@intFromPtr(end) <= @intFromPtr(beg)) {
        return CURLE_BAD_FUNCTION_ARGUMENT;
    }

    var y: u32 = beg[0];
    beg += 1;
    var x: u32 = if (y <= 80) y / 40 else 2;
    var result = curlx_dyn_addf(store, "%u", @as(c_uint, x));
    if (result != CURLE_OK) return result;

    if ((y & 0x80) != 0) {
        var t: u32 = y & 0x7F;
        if (t == 0) return CURLE_BAD_FUNCTION_ARGUMENT;
        while (true) {
            if ((t & 0xFE000000) != 0 or @intFromPtr(beg) >= @intFromPtr(end)) {
                return CURLE_BAD_FUNCTION_ARGUMENT;
            }
            y = beg[0];
            beg += 1;
            t = (t << 7) | (y & 0x7F);
            if ((y & 0x80) == 0) break;
        }
        y = t;
    }

    result = curlx_dyn_addf(store, ".%u", @as(c_uint, y - (x * 40)));
    if (result != CURLE_OK) return result;

    while (@intFromPtr(beg) < @intFromPtr(end) and result == CURLE_OK) {
        x = 0;
        y = 0;
        while (true) {
            if ((y & 0x80) != 0 and x == 0) {
                return CURLE_BAD_FUNCTION_ARGUMENT;
            } else if ((x & 0xFE000000) != 0 or @intFromPtr(beg) == @intFromPtr(end)) {
                return CURLE_BAD_FUNCTION_ARGUMENT;
            }
            y = beg[0];
            beg += 1;
            x = (x << 7) | (y & 0x7F);
            if ((y & 0x80) == 0) break;
        }
        result = curlx_dyn_addf(store, ".%u", @as(c_uint, x));
    }
    return result;
}

fn OID2str(store: *dynbuf, beg: [*]const u8, end: [*]const u8) CURLcode {
    var result: CURLcode = CURLE_OK;
    if (@intFromPtr(beg) < @intFromPtr(end)) {
        var buf: dynbuf = undefined;
        containers.curlx_dyn_init(&buf, CURL_X509_STR_MAX);
        defer containers.curlx_dyn_free(&buf);

        result = encodeOID(&buf, beg, end);
        if (result == CURLE_OK) {
            const ptr = containers.curlx_dyn_ptr(&buf);
            if (searchOID(ptr)) |op| {
                result = containers.curlx_dyn_add(store, op.textoid);
            } else if (ptr) |p| {
                result = containers.curlx_dyn_add(store, p);
            }
        }
    }
    return result;
}

pub export fn GTime2str(
    store: *dynbuf,
    beg_opt: ?[*]const u8,
    end_opt: ?[*]const u8,
) callconv(.c) CURLcode {
    const beg = beg_opt orelse return CURLE_BAD_FUNCTION_ARGUMENT;
    const end = end_opt orelse return CURLE_BAD_FUNCTION_ARGUMENT;
    if (@intFromPtr(end) < @intFromPtr(beg)) return CURLE_BAD_FUNCTION_ARGUMENT;

    var fracp = beg;
    while (@intFromPtr(fracp) < @intFromPtr(end) and std.ascii.isDigit(fracp[0])) : (fracp += 1) {}

    var sec1: u8 = '0';
    var sec2: u8 = '0';
    const digit_len = @intFromPtr(fracp) - @intFromPtr(beg);
    if (digit_len < 12) return CURLE_BAD_FUNCTION_ARGUMENT;
    switch (digit_len - 12) {
        0 => {
            sec2 = '0';
        },
        2 => {
            sec1 = (fracp - 2)[0];
            sec2 = (fracp - 1)[0];
        },
        1 => {
            sec2 = (fracp - 1)[0];
        },
        else => return CURLE_BAD_FUNCTION_ARGUMENT,
    }

    var tzp = fracp;
    var fracl: usize = 0;
    if (@intFromPtr(fracp) < @intFromPtr(end) and (fracp[0] == '.' or fracp[0] == ',')) {
        fracp += 1;
        tzp = fracp;
        while (@intFromPtr(tzp) < @intFromPtr(end) and std.ascii.isDigit(tzp[0])) : (tzp += 1) {}
        if (tzp == fracp) return CURLE_BAD_FUNCTION_ARGUMENT;
        fracl = @intFromPtr(tzp) - @intFromPtr(fracp);
        while (fracl > 0 and fracp[fracl - 1] == '0') : (fracl -= 1) {}
    }

    var sep: [*:0]const u8 = "";
    var tzl: usize = 0;
    const empty_str: [*]const u8 = "";
    const gmt_str: [*]const u8 = "GMT";
    if (@intFromPtr(tzp) >= @intFromPtr(end)) {
        tzp = empty_str;
        tzl = 0;
    } else if (tzp[0] == 'Z') {
        sep = " ";
        tzp = gmt_str;
        tzl = 3;
    } else if (tzp[0] == '+' or tzp[0] == '-') {
        sep = " UTC";
        tzl = @intFromPtr(end) - @intFromPtr(tzp);
    } else {
        sep = " ";
        tzl = @intFromPtr(end) - @intFromPtr(tzp);
    }

    const dot_str: [*:0]const u8 = ".";
    const no_dot_str: [*:0]const u8 = "";
    return curlx_dyn_addf(
        store,
        "%.4s-%.2s-%.2s %.2s:%.2s:%c%c%s%.*s%s%.*s",
        beg,
        beg + 4,
        beg + 6,
        beg + 8,
        beg + 10,
        @as(c_int, sec1),
        @as(c_int, sec2),
        if (fracl > 0) dot_str else no_dot_str,
        @as(c_int, @intCast(fracl)),
        fracp,
        sep,
        @as(c_int, @intCast(tzl)),
        tzp,
    );
}

fn UTime2str(store: *dynbuf, beg: [*]const u8, end_in: [*]const u8) CURLcode {
    var end = end_in;
    var tzp = beg;
    while (@intFromPtr(tzp) < @intFromPtr(end) and tzp[0] >= '0' and tzp[0] <= '9') : (tzp += 1) {}

    if (@intFromPtr(tzp) - @intFromPtr(beg) < 10) return CURLE_BAD_FUNCTION_ARGUMENT;
    var sec: [*]const u8 = beg + 10;
    const sec_digits = @intFromPtr(tzp) - @intFromPtr(sec);
    const zero_sec: [*]const u8 = "00";
    switch (sec_digits) {
        0 => sec = zero_sec,
        2 => {},
        else => return CURLE_BAD_FUNCTION_ARGUMENT,
    }

    if (@intFromPtr(tzp) >= @intFromPtr(end)) {
        return CURLE_BAD_FUNCTION_ARGUMENT;
    }
    const gmt_str: [*]const u8 = "GMT";
    if (tzp[0] == 'Z') {
        tzp = gmt_str;
        end = tzp + 3;
    }

    const tzl = @intFromPtr(end) - @intFromPtr(tzp);
    const century: c_int = if (beg[0] >= '5') 19 else 20;
    return curlx_dyn_addf(
        store,
        "%d%.2s-%.2s-%.2s %.2s:%.2s:%.2s %.*s",
        century,
        beg,
        beg + 2,
        beg + 4,
        beg + 6,
        beg + 8,
        sec,
        @as(c_int, @intCast(tzl)),
        tzp,
    );
}

pub export fn ASN1tostr(
    store: *dynbuf,
    elem: *CurlAsn1Element,
) callconv(.c) CURLcode {
    if (elem.getConstructed()) {
        return CURLE_BAD_FUNCTION_ARGUMENT;
    }
    const beg = elem.beg orelse return CURLE_BAD_FUNCTION_ARGUMENT;
    const end = elem.end orelse return CURLE_BAD_FUNCTION_ARGUMENT;
    const asn1_type = elem.tag;

    return switch (asn1_type) {
        CURL_ASN1_BOOLEAN => bool2str(store, beg, end),
        CURL_ASN1_INTEGER, CURL_ASN1_ENUMERATED => int2str(store, beg, end),
        CURL_ASN1_BIT_STRING => bit2str(store, beg, end),
        CURL_ASN1_OCTET_STRING => octet2str(store, beg, end),
        CURL_ASN1_NULL => containers.curlx_dyn_addn(store, "", 1),
        CURL_ASN1_OBJECT_IDENTIFIER => OID2str(store, beg, end),
        CURL_ASN1_UTC_TIME => UTime2str(store, beg, end),
        CURL_ASN1_GENERALIZED_TIME => GTime2str(store, beg, end),
        CURL_ASN1_UTF8_STRING,
        CURL_ASN1_NUMERIC_STRING,
        CURL_ASN1_PRINTABLE_STRING,
        CURL_ASN1_TELETEX_STRING,
        CURL_ASN1_IA5_STRING,
        CURL_ASN1_VISIBLE_STRING,
        CURL_ASN1_UNIVERSAL_STRING,
        CURL_ASN1_BMP_STRING,
        => utf8asn1str(store, @intCast(asn1_type), beg, end),
        else => CURLE_BAD_FUNCTION_ARGUMENT,
    };
}

fn encodeDN(store: *dynbuf, dn: *CurlAsn1Element) CURLcode {
    var rdn: CurlAsn1Element = std.mem.zeroes(CurlAsn1Element);
    var atv: CurlAsn1Element = std.mem.zeroes(CurlAsn1Element);
    var oid: CurlAsn1Element = std.mem.zeroes(CurlAsn1Element);
    var value: CurlAsn1Element = std.mem.zeroes(CurlAsn1Element);
    var result: CURLcode = CURLE_OK;
    var added = false;
    var temp: dynbuf = undefined;
    containers.curlx_dyn_init(&temp, CURL_X509_STR_MAX);
    defer containers.curlx_dyn_free(&temp);

    var p1 = dn.beg orelse return CURLE_OK;
    const dn_end = dn.end orelse return CURLE_OK;

    while (@intFromPtr(p1) < @intFromPtr(dn_end)) {
        p1 = getASN1Element(&rdn, p1, dn_end) orelse return CURLE_BAD_FUNCTION_ARGUMENT;
        var p2 = rdn.beg orelse return CURLE_BAD_FUNCTION_ARGUMENT;
        const rdn_end = rdn.end orelse return CURLE_BAD_FUNCTION_ARGUMENT;
        while (@intFromPtr(p2) < @intFromPtr(rdn_end)) {
            p2 = getASN1Element(&atv, p2, rdn_end) orelse return CURLE_BAD_FUNCTION_ARGUMENT;
            var p3 = getASN1Element(&oid, atv.beg, atv.end) orelse return CURLE_BAD_FUNCTION_ARGUMENT;
            if (getASN1Element(&value, p3, atv.end) == null) {
                return CURLE_BAD_FUNCTION_ARGUMENT;
            }
            containers.curlx_dyn_reset(&temp);
            result = ASN1tostr(&temp, &oid);
            if (result != CURLE_OK) return result;

            const str = containers.curlx_dyn_uptr(&temp) orelse return CURLE_BAD_FUNCTION_ARGUMENT;

            p3 = str;
            while (std.ascii.isUpper(p3[0])) : (p3 += 1) {}
            if (added) {
                if (@intFromPtr(p3) - @intFromPtr(str) > 2) {
                    result = containers.curlx_dyn_addn(store, "/", 1);
                } else {
                    result = containers.curlx_dyn_addn(store, ", ", 2);
                }
                if (result != CURLE_OK) return result;
            }

            result = containers.curlx_dyn_add(store, @ptrCast(str));
            if (result != CURLE_OK) return result;

            result = containers.curlx_dyn_addn(store, "=", 1);
            if (result != CURLE_OK) return result;

            result = ASN1tostr(store, &value);
            if (result != CURLE_OK) return result;
            containers.curlx_dyn_reset(&temp);
            added = true;
        }
    }
    return CURLE_OK;
}

const defaultVersion: [1]u8 = .{0};

pub export fn Curl_parseX509(
    cert: *CurlX509certificate,
    beg_opt: ?[*]const u8,
    end_opt: ?[*]const u8,
) callconv(.c) c_int {
    var elem: CurlAsn1Element = std.mem.zeroes(CurlAsn1Element);
    var tbsCertificate: CurlAsn1Element = std.mem.zeroes(CurlAsn1Element);

    cert.* = std.mem.zeroes(CurlX509certificate);
    cert.certificate.header = null;
    cert.certificate.beg = beg_opt;
    cert.certificate.end = end_opt;

    if (getASN1Element(&elem, beg_opt, end_opt) == null) {
        return -1;
    }
    var beg = elem.beg;
    var end = elem.end;

    beg = getASN1Element(&tbsCertificate, beg, end) orelse return -1;
    beg = getASN1Element(&cert.signatureAlgorithm, beg, end) orelse return -1;
    if (getASN1Element(&cert.signature, beg, end) == null) {
        return -1;
    }

    beg = tbsCertificate.beg;
    end = tbsCertificate.end;
    cert.version.header = null;
    cert.version.beg = &defaultVersion;
    cert.version.end = @as([*]const u8, &defaultVersion) + 1;
    beg = getASN1Element(&elem, beg, end) orelse return -1;
    if (elem.tag == 0) {
        if (getASN1Element(&cert.version, elem.beg, elem.end) == null) {
            return -1;
        }
        beg = getASN1Element(&elem, beg, end) orelse return -1;
    }
    cert.serialNumber = elem;
    beg = getASN1Element(&cert.signatureAlgorithm, beg, end);
    beg = getASN1Element(&cert.issuer, beg, end) orelse return -1;
    beg = getASN1Element(&elem, beg, end) orelse return -1;
    var ccp = getASN1Element(&cert.notBefore, elem.beg, elem.end) orelse return -1;
    if (getASN1Element(&cert.notAfter, ccp, elem.end) == null) {
        return -1;
    }
    if (elem.end != cert.notAfter.end) {
        return -1;
    }
    beg = getASN1Element(&cert.subject, beg, end) orelse return -1;
    beg = getASN1Element(&cert.subjectPublicKeyInfo, beg, end) orelse return -1;
    ccp = getASN1Element(
        &cert.subjectPublicKeyAlgorithm,
        cert.subjectPublicKeyInfo.beg,
        cert.subjectPublicKeyInfo.end,
    ) orelse return -1;
    if (getASN1Element(&cert.subjectPublicKey, ccp, cert.subjectPublicKeyInfo.end) == null) {
        return -1;
    }

    cert.issuerUniqueID.tag = 0;
    cert.subjectUniqueID.tag = 0;
    cert.extensions.tag = 0;
    elem.tag = 0;
    cert.issuerUniqueID.header = null;
    cert.subjectUniqueID.header = null;
    cert.issuerUniqueID.beg = beg;
    cert.issuerUniqueID.end = beg;
    cert.subjectUniqueID.beg = beg;
    cert.subjectUniqueID.end = beg;
    cert.extensions.header = null;
    cert.extensions.beg = beg;
    cert.extensions.end = beg;

    if (beg != null and end != null and @intFromPtr(beg.?) < @intFromPtr(end.?)) {
        beg = getASN1Element(&elem, beg, end) orelse return -1;
    }
    if (elem.tag == 1) {
        cert.issuerUniqueID = elem;
        if (beg != null and end != null and @intFromPtr(beg.?) < @intFromPtr(end.?)) {
            beg = getASN1Element(&elem, beg, end) orelse return -1;
        }
    }
    if (elem.tag == 2) {
        cert.subjectUniqueID = elem;
        if (beg != null and end != null and @intFromPtr(beg.?) < @intFromPtr(end.?)) {
            beg = getASN1Element(&elem, beg, end) orelse return -1;
        }
    }
    if (elem.tag == 3) {
        if (getASN1Element(&cert.extensions, elem.beg, elem.end) == null) {
            return -1;
        }
    }
    return 0;
}

fn dumpAlgo(
    store: *dynbuf,
    param: *CurlAsn1Element,
    beg_opt: ?[*]const u8,
    end_opt: ?[*]const u8,
) CURLcode {
    var oid: CurlAsn1Element = std.mem.zeroes(CurlAsn1Element);
    const beg = getASN1Element(&oid, beg_opt, end_opt) orelse return CURLE_BAD_FUNCTION_ARGUMENT;
    const end = end_opt orelse return CURLE_BAD_FUNCTION_ARGUMENT;
    param.header = null;
    param.tag = 0;
    param.beg = end;
    param.end = end;
    if (@intFromPtr(beg) < @intFromPtr(end)) {
        if (getASN1Element(param, beg, end) == null) {
            return CURLE_BAD_FUNCTION_ARGUMENT;
        }
    }
    return OID2str(store, oid.beg.?, oid.end.?);
}

pub const CurlSslPushCertinfoLenFn = *const fn (
    data: ?*anyopaque,
    certnum: c_int,
    label: [*:0]const u8,
    value: ?[*]const u8,
    valuelen: usize,
) callconv(.c) CURLcode;

fn sslPushCertinfo(
    data: ?*anyopaque,
    certnum: c_int,
    label: [*:0]const u8,
    value: [*:0]const u8,
    push_fn: CurlSslPushCertinfoLenFn,
) CURLcode {
    return push_fn(data, certnum, label, value, std.mem.len(value));
}

fn sslPushCertinfoDyn(
    data: ?*anyopaque,
    certnum: c_int,
    label: [*:0]const u8,
    ptr: *dynbuf,
    push_fn: CurlSslPushCertinfoLenFn,
) CURLcode {
    const valuelen = containers.curlx_dyn_len(ptr);
    const value = containers.curlx_dyn_ptr(ptr);
    const result = push_fn(data, certnum, label, value, valuelen);
    if (certnum == 0 and result == CURLE_OK) {
        infof(data, "   %s: %s", .{ label, value });
    }
    return result;
}

fn doPubkeyField(
    data: ?*anyopaque,
    certnum: c_int,
    label: [*:0]const u8,
    elem: *CurlAsn1Element,
    certinfo: bool,
    push_fn: CurlSslPushCertinfoLenFn,
) CURLcode {
    var out: dynbuf = undefined;
    containers.curlx_dyn_init(&out, CURL_X509_STR_MAX);
    var result = ASN1tostr(&out, elem);
    if (result == CURLE_OK) {
        if (certinfo) {
            result = sslPushCertinfoDyn(data, certnum, label, &out, push_fn);
        }
        containers.curlx_dyn_free(&out);
    }
    return result;
}

fn doPubkey(
    data: ?*anyopaque,
    certnum: c_int,
    algo_opt: ?[*:0]const u8,
    param: *CurlAsn1Element,
    pubkey: *CurlAsn1Element,
    certinfo: bool,
    push_fn: CurlSslPushCertinfoLenFn,
) c_int {
    var elem: CurlAsn1Element = std.mem.zeroes(CurlAsn1Element);
    var pk: CurlAsn1Element = std.mem.zeroes(CurlAsn1Element);
    const pub_beg = pubkey.beg orelse return 1;
    const pub_end = pubkey.end orelse return 1;

    if (primitives.curl_strequal(algo_opt, "ecPublicKey") != 0) {
        const dlen = @intFromPtr(pub_end) - @intFromPtr(pub_beg);
        if (dlen < 2) return 1;
        const len = (dlen - 2) * 4;
        if (certnum == 0) {
            infof(data, "   ECC Public Key (%zu bits)", .{len});
        }
        if (certinfo) {
            var q: [32]u8 = undefined;
            _ = curl_msnprintf(&q, q.len, "%zu", len);
            if (sslPushCertinfo(data, certnum, "ECC Public Key", @ptrCast(&q), push_fn) != CURLE_OK) {
                return 1;
            }
        }
        return if (doPubkeyField(data, certnum, "ecPublicKey", pubkey, certinfo, push_fn) == CURLE_OK) 0 else 1;
    }

    if (@intFromPtr(pub_beg + 1) > @intFromPtr(pub_end)) return 1;
    if (getASN1Element(&pk, pub_beg + 1, pub_end) == null) {
        return 1;
    }

    if (primitives.curl_strequal(algo_opt, "rsaEncryption") != 0) {
        const p = getASN1Element(&elem, pk.beg, pk.end) orelse return 1;
        var q = elem.beg.?;
        const elem_end = elem.end.?;
        while (@intFromPtr(q) < @intFromPtr(elem_end) and q[0] == 0) : (q += 1) {}
        var len = (@intFromPtr(elem_end) - @intFromPtr(q)) * 8;
        if (len > 0) {
            var i: u32 = q[0];
            while ((i & 0x80) == 0) : (i <<= 1) {
                len -= 1;
            }
        }
        if (len > 32) {
            elem.beg = q;
        }
        if (certnum == 0) {
            infof(data, "   RSA Public Key (%zu bits)", .{len});
        }
        if (certinfo) {
            var r: [32]u8 = undefined;
            _ = curl_msnprintf(&r, r.len, "%zu", len);
            if (sslPushCertinfo(data, certnum, "RSA Public Key", @ptrCast(&r), push_fn) != CURLE_OK) {
                return 1;
            }
        }
        if (doPubkeyField(data, certnum, "rsa(n)", &elem, certinfo, push_fn) != CURLE_OK) return 1;
        if (getASN1Element(&elem, p, pk.end) == null) return 1;
        if (doPubkeyField(data, certnum, "rsa(e)", &elem, certinfo, push_fn) != CURLE_OK) return 1;
    } else if (primitives.curl_strequal(algo_opt, "dsa") != 0) {
        if (getASN1Element(&elem, param.beg, param.end)) |p1| {
            if (doPubkeyField(data, certnum, "dsa(p)", &elem, certinfo, push_fn) != CURLE_OK) return 1;
            if (getASN1Element(&elem, p1, param.end)) |p2| {
                if (doPubkeyField(data, certnum, "dsa(q)", &elem, certinfo, push_fn) != CURLE_OK) return 1;
                if (getASN1Element(&elem, p2, param.end) != null) {
                    if (doPubkeyField(data, certnum, "dsa(g)", &elem, certinfo, push_fn) != CURLE_OK) return 1;
                    if (doPubkeyField(data, certnum, "dsa(pub_key)", &pk, certinfo, push_fn) != CURLE_OK) return 1;
                }
            }
        }
    } else if (primitives.curl_strequal(algo_opt, "dhpublicnumber") != 0) {
        if (getASN1Element(&elem, param.beg, param.end)) |p1| {
            if (doPubkeyField(data, certnum, "dh(p)", &elem, certinfo, push_fn) != CURLE_OK) return 1;
            if (getASN1Element(&elem, p1, param.end) != null) {
                if (doPubkeyField(data, certnum, "dh(g)", &elem, certinfo, push_fn) != CURLE_OK) return 1;
                if (doPubkeyField(data, certnum, "dh(pub_key)", &pk, certinfo, push_fn) != CURLE_OK) return 1;
            }
        }
    }
    return 0;
}

pub export fn Curl_extract_certinfo_zig(
    data: ?*anyopaque,
    certnum: c_int,
    beg: ?[*]const u8,
    end: ?[*]const u8,
    certinfo: bool,
    push_fn: CurlSslPushCertinfoLenFn,
) callconv(.c) CURLcode {
    var cert: CurlX509certificate = undefined;
    var param: CurlAsn1Element = std.mem.zeroes(CurlAsn1Element);
    var certptr: ?[*:0]u8 = null;
    var clen: usize = 0;
    var out: dynbuf = undefined;
    var result: CURLcode = CURLE_OK;

    if (!certinfo and certnum != 0) {
        return CURLE_OK;
    }

    containers.curlx_dyn_init(&out, CURL_X509_STR_MAX);

    if (Curl_parseX509(&cert, beg, end) != 0) {
        return CURLE_PEER_FAILED_VERIFICATION;
    }

    defer {
        if (result != CURLE_OK) {
            failf(data, "Failed extracting certificate chain", .{});
        }
        containers.curlx_dyn_free(&out);
    }

    result = encodeDN(&out, &cert.subject);
    if (result != CURLE_OK) return result;
    if (certinfo) {
        result = sslPushCertinfoDyn(data, certnum, "Subject", &out, push_fn);
        if (result != CURLE_OK) return result;
    }
    containers.curlx_dyn_reset(&out);

    result = encodeDN(&out, &cert.issuer);
    if (result != CURLE_OK) return result;
    if (certinfo) {
        result = sslPushCertinfoDyn(data, certnum, "Issuer", &out, push_fn);
        if (result != CURLE_OK) return result;
    }
    containers.curlx_dyn_reset(&out);

    var version: c_uint = 0;
    var ptr = cert.version.beg.?;
    const ver_end = cert.version.end.?;
    while (@intFromPtr(ptr) < @intFromPtr(ver_end)) : (ptr += 1) {
        version = (version << 8) | ptr[0];
    }
    if (certinfo) {
        result = curlx_dyn_addf(&out, "%x", version);
        if (result != CURLE_OK) return result;
        result = sslPushCertinfoDyn(data, certnum, "Version", &out, push_fn);
        if (result != CURLE_OK) return result;
        containers.curlx_dyn_reset(&out);
    }

    result = ASN1tostr(&out, &cert.serialNumber);
    if (result != CURLE_OK) return result;
    if (certinfo) {
        result = sslPushCertinfoDyn(data, certnum, "Serial Number", &out, push_fn);
        if (result != CURLE_OK) return result;
    }
    containers.curlx_dyn_reset(&out);

    result = dumpAlgo(&out, &param, cert.signatureAlgorithm.beg, cert.signatureAlgorithm.end);
    if (result != CURLE_OK) return result;
    if (certinfo) {
        result = sslPushCertinfoDyn(data, certnum, "Signature Algorithm", &out, push_fn);
        if (result != CURLE_OK) return result;
    }
    containers.curlx_dyn_reset(&out);

    result = ASN1tostr(&out, &cert.notBefore);
    if (result != CURLE_OK) return result;
    if (certinfo) {
        result = sslPushCertinfoDyn(data, certnum, "Start Date", &out, push_fn);
        if (result != CURLE_OK) return result;
    }
    containers.curlx_dyn_reset(&out);

    result = ASN1tostr(&out, &cert.notAfter);
    if (result != CURLE_OK) return result;
    if (certinfo) {
        result = sslPushCertinfoDyn(data, certnum, "Expire Date", &out, push_fn);
        if (result != CURLE_OK) return result;
    }
    containers.curlx_dyn_reset(&out);

    result = dumpAlgo(&out, &param, cert.subjectPublicKeyAlgorithm.beg, cert.subjectPublicKeyAlgorithm.end);
    if (result != CURLE_OK) return result;
    if (certinfo) {
        result = sslPushCertinfoDyn(data, certnum, "Public Key Algorithm", &out, push_fn);
        if (result != CURLE_OK) return result;
    }

    const rc = doPubkey(data, certnum, containers.curlx_dyn_ptr(&out), &param, &cert.subjectPublicKey, certinfo, push_fn);
    if (rc != 0) {
        result = CURLE_OUT_OF_MEMORY;
        return result;
    }
    containers.curlx_dyn_reset(&out);

    result = ASN1tostr(&out, &cert.signature);
    if (result != CURLE_OK) return result;
    if (certinfo) {
        result = sslPushCertinfoDyn(data, certnum, "Signature", &out, push_fn);
        if (result != CURLE_OK) return result;
    }
    containers.curlx_dyn_reset(&out);

    const cert_beg = cert.certificate.beg.?;
    const cert_end = cert.certificate.end.?;
    result = base64.curlx_base64_encode(
        cert_beg,
        @intFromPtr(cert_end) - @intFromPtr(cert_beg),
        &certptr,
        &clen,
    );
    if (result != CURLE_OK) return result;

    containers.curlx_dyn_reset(&out);

    result = containers.curlx_dyn_add(&out, "-----BEGIN CERTIFICATE-----\n");
    if (result == CURLE_OK) {
        var j: usize = 0;
        const cptr = certptr.?;
        while (result == CURLE_OK and j < clen) {
            const chunksize = if ((clen - j) > 64) 64 else (clen - j);
            result = containers.curlx_dyn_addn(&out, cptr + j, chunksize);
            if (result == CURLE_OK) {
                result = containers.curlx_dyn_addn(&out, "\n", 1);
            }
            j += chunksize;
        }
        if (result == CURLE_OK) {
            result = containers.curlx_dyn_add(&out, "-----END CERTIFICATE-----\n");
        }
    }
    mem.free(certptr);
    if (result == CURLE_OK and certinfo) {
        result = sslPushCertinfoDyn(data, certnum, "Cert", &out, push_fn);
    }
    return result;
}

// ============================================================================
// Unit Tests
// ============================================================================

test "GTime2str ASN.1 GeneralizedTime formatting (unit1656)" {
    const Spec = struct {
        input: []const u8,
        expected: ?[]const u8,
        result_exp: CURLcode,
    };
    const specs = [_]Spec{
        .{ .input = "190321134340", .expected = "1903-21-13 43:40:00", .result_exp = CURLE_OK },
        .{ .input = "", .expected = null, .result_exp = CURLE_BAD_FUNCTION_ARGUMENT },
        .{ .input = "WTF", .expected = null, .result_exp = CURLE_BAD_FUNCTION_ARGUMENT },
        .{ .input = "0WTF", .expected = null, .result_exp = CURLE_BAD_FUNCTION_ARGUMENT },
        .{ .input = "19032113434", .expected = null, .result_exp = CURLE_BAD_FUNCTION_ARGUMENT },
        .{ .input = "19032113434WTF", .expected = null, .result_exp = CURLE_BAD_FUNCTION_ARGUMENT },
        .{ .input = "190321134340.", .expected = null, .result_exp = CURLE_BAD_FUNCTION_ARGUMENT },
        .{ .input = "190321134340.1", .expected = "1903-21-13 43:40:00.1", .result_exp = CURLE_OK },
        .{ .input = "19032113434017.0", .expected = "1903-21-13 43:40:17", .result_exp = CURLE_OK },
        .{ .input = "19032113434017.01", .expected = "1903-21-13 43:40:17.01", .result_exp = CURLE_OK },
        .{ .input = "19032113434003.001", .expected = "1903-21-13 43:40:03.001", .result_exp = CURLE_OK },
        .{ .input = "19032113434003.090", .expected = "1903-21-13 43:40:03.09", .result_exp = CURLE_OK },
        .{ .input = "190321134340Z", .expected = "1903-21-13 43:40:00 GMT", .result_exp = CURLE_OK },
        .{ .input = "19032113434017.0Z", .expected = "1903-21-13 43:40:17 GMT", .result_exp = CURLE_OK },
        .{ .input = "19032113434017.01Z", .expected = "1903-21-13 43:40:17.01 GMT", .result_exp = CURLE_OK },
        .{ .input = "19032113434003.001Z", .expected = "1903-21-13 43:40:03.001 GMT", .result_exp = CURLE_OK },
        .{ .input = "19032113434003.090Z", .expected = "1903-21-13 43:40:03.09 GMT", .result_exp = CURLE_OK },
        .{ .input = "190321134340CET", .expected = "1903-21-13 43:40:00 CET", .result_exp = CURLE_OK },
        .{ .input = "19032113434017.0CET", .expected = "1903-21-13 43:40:17 CET", .result_exp = CURLE_OK },
        .{ .input = "19032113434017.01CET", .expected = "1903-21-13 43:40:17.01 CET", .result_exp = CURLE_OK },
        .{ .input = "190321134340+02:30", .expected = "1903-21-13 43:40:00 UTC+02:30", .result_exp = CURLE_OK },
        .{ .input = "19032113434017.0+02:30", .expected = "1903-21-13 43:40:17 UTC+02:30", .result_exp = CURLE_OK },
        .{ .input = "19032113434017.01+02:30", .expected = "1903-21-13 43:40:17.01 UTC+02:30", .result_exp = CURLE_OK },
        .{ .input = "190321134340-3", .expected = "1903-21-13 43:40:00 UTC-3", .result_exp = CURLE_OK },
        .{ .input = "19032113434017.0-04", .expected = "1903-21-13 43:40:17 UTC-04", .result_exp = CURLE_OK },
        .{ .input = "19032113434017.01-01:10", .expected = "1903-21-13 43:40:17.01 UTC-01:10", .result_exp = CURLE_OK },
    };

    var dbuf: dynbuf = undefined;
    containers.curlx_dyn_init(&dbuf, 32 * 1024);
    defer containers.curlx_dyn_free(&dbuf);

    for (specs) |spec| {
        containers.curlx_dyn_reset(&dbuf);
        const res = GTime2str(&dbuf, spec.input.ptr, spec.input.ptr + spec.input.len);
        try std.testing.expectEqual(spec.result_exp, res);
        if (spec.expected) |exp| {
            const actual = std.mem.span(containers.curlx_dyn_ptr(&dbuf).?);
            try std.testing.expectEqualStrings(exp, actual);
        }
    }
}

test "getASN1Element and encodeOID and ASN1tostr" {
    var dbuf: dynbuf = undefined;
    containers.curlx_dyn_init(&dbuf, 32 * 1024);
    defer containers.curlx_dyn_free(&dbuf);

    // 1. encodeOID for rsaEncryption (1.2.840.113549.1.1.1)
    const rsa_oid_bytes = [_]u8{ 0x2A, 0x86, 0x48, 0x86, 0xF7, 0x0D, 0x01, 0x01, 0x01 };
    const oid_res = encodeOID(&dbuf, &rsa_oid_bytes, @as([*]const u8, &rsa_oid_bytes) + rsa_oid_bytes.len);
    try std.testing.expectEqual(CURLE_OK, oid_res);
    try std.testing.expectEqualStrings("1.2.840.113549.1.1.1", std.mem.span(containers.curlx_dyn_ptr(&dbuf).?));

    // 2. getASN1Element + ASN1tostr for OID element -> symbolic "rsaEncryption"
    const der_oid = [_]u8{ 0x06, 0x09, 0x2A, 0x86, 0x48, 0x86, 0xF7, 0x0D, 0x01, 0x01, 0x01 };
    var elem: CurlAsn1Element = std.mem.zeroes(CurlAsn1Element);
    const next_ptr = getASN1Element(&elem, &der_oid, @as([*]const u8, &der_oid) + der_oid.len);
    try std.testing.expect(next_ptr != null);
    try std.testing.expectEqual(@as(u8, CURL_ASN1_OBJECT_IDENTIFIER), elem.tag);
    try std.testing.expect(!elem.getConstructed());

    containers.curlx_dyn_reset(&dbuf);
    try std.testing.expectEqual(CURLE_OK, ASN1tostr(&dbuf, &elem));
    try std.testing.expectEqualStrings("rsaEncryption", std.mem.span(containers.curlx_dyn_ptr(&dbuf).?));

    // 3. Nested indefinite-length recursion limit (unit1657)
    var nested_buf: dynbuf = undefined;
    containers.curlx_dyn_init(&nested_buf, 1024);
    defer containers.curlx_dyn_free(&nested_buf);

    for ([_]usize{ 3, 16, 17 }) |depth| {
        containers.curlx_dyn_reset(&nested_buf);
        const open_undef = [_]u8{ 0x32, 0x80 };
        const close_undef = [_]u8{ 0x00, 0x00 };
        for (0..depth) |_| {
            try std.testing.expectEqual(CURLE_OK, containers.curlx_dyn_addn(&nested_buf, &open_undef, open_undef.len));
        }
        for (0..depth) |_| {
            try std.testing.expectEqual(CURLE_OK, containers.curlx_dyn_addn(&nested_buf, &close_undef, close_undef.len));
        }
        const in_ptr = containers.curlx_dyn_uptr(&nested_buf).?;
        const in_len = containers.curlx_dyn_len(&nested_buf);
        const p = getASN1Element(&elem, in_ptr, in_ptr + in_len);
        if (depth <= 16) {
            try std.testing.expect(p != null);
        } else {
            try std.testing.expect(p == null);
        }
    }
}

test "SslFilterConfig cloning, matching, and peer key generation (unit3303 & unit3304)" {
    var easy_cfg: SslEasyConfig = undefined;
    Curl_ssl_config_init(&easy_cfg);
    try std.testing.expect(easy_cfg.getFlag(SslEasyConfig.BIT_VERIFYPEER));
    try std.testing.expect(easy_cfg.getFlag(SslEasyConfig.BIT_VERIFYHOST));
    try std.testing.expect(easy_cfg.getFlag(SslEasyConfig.BIT_CACHE_SESSION));

    var ssl_cfg: SslFilterConfig = std.mem.zeroes(SslFilterConfig);
    ssl_cfg.setFlag(SslFilterConfig.BIT_VERIFYPEER, true);
    ssl_cfg.setFlag(SslFilterConfig.BIT_VERIFYHOST, true);

    var cert_buf = "client.pem".*;
    var key_buf = "client.key".*;
    var passwd_buf = "secret".*;
    var ctype_buf = "PEM".*;
    var ktype_buf = "PEM".*;
    const key_blob_bytes = "PRIVATE-KEY-MATERIAL";
    var key_blob = CurlBlob{
        .data = @ptrCast(@constCast(key_blob_bytes.ptr)),
        .len = key_blob_bytes.len,
        .flags = 1,
    };

    ssl_cfg.clientcert = &cert_buf;
    ssl_cfg.key = &key_buf;
    ssl_cfg.key_passwd = &passwd_buf;
    ssl_cfg.cert_type = &ctype_buf;
    ssl_cfg.key_type = &ktype_buf;
    ssl_cfg.key_blob = &key_blob;

    var cloned_cfg: SslFilterConfig = std.mem.zeroes(SslFilterConfig);
    try std.testing.expectEqual(CURLE_OK, Curl_ssl_conn_config_clone_zig(&ssl_cfg, null, &cloned_cfg, null));
    defer Curl_ssl_conn_config_cleanup_zig(&cloned_cfg, null);

    try std.testing.expect(Curl_ssl_conn_config_match_zig(&ssl_cfg, &cloned_cfg, null, false));

    var alt_passwd = "wrong".*;
    ssl_cfg.key_passwd = &alt_passwd;
    try std.testing.expect(!Curl_ssl_conn_config_match_zig(&ssl_cfg, &cloned_cfg, null, false));
    ssl_cfg.key_passwd = &passwd_buf;
    try std.testing.expect(Curl_ssl_conn_config_match_zig(&ssl_cfg, &cloned_cfg, null, false));

    // Verify session ticket & QUIC transport parameter scrubbing on destroy
    const ticket_raw = mem.malloc(16) orelse return error.OutOfMemory;
    @memset(ticket_raw[0..16], 0x77);
    const qtp_raw = mem.malloc(8) orelse return error.OutOfMemory;
    @memset(qtp_raw[0..8], 0x88);
    var sess: ?*CurlSslSession = null;
    try std.testing.expectEqual(
        CURLE_OK,
        Curl_ssl_session_create2(ticket_raw, 16, 0x0304, "h2", 999999, 0, qtp_raw, 8, &sess),
    );
    try std.testing.expect(sess != null);
    Curl_ssl_session_destroy(sess);

    const scheme = CurlScheme{ .name = "https" };
    var origin = CurlPeer{
        .scheme = &scheme,
        .hostname = "example.com",
        .port = 443,
    };
    const peer = SslPeer{
        .origin = &origin,
        .peer = null,
        .sni = null,
        .scache_key = null,
        .type = 0,
        .transport = TRNSPRT_TCP,
    };

    var key1: ?[*:0]u8 = null;
    var key2: ?[*:0]u8 = null;
    try std.testing.expectEqual(CURLE_OK, Curl_ssl_peer_key_make(&peer, &ssl_cfg, "test", &key1));
    defer mem.free(key1);
    try std.testing.expectEqual(CURLE_OK, Curl_ssl_peer_key_make(&peer, &ssl_cfg, "test", &key2));
    defer mem.free(key2);

    const k1_slice = std.mem.span(key1.?);
    const k2_slice = std.mem.span(key2.?);
    try std.testing.expectEqualStrings(k1_slice, k2_slice);
    try std.testing.expect(std.mem.startsWith(u8, k1_slice, "https:example.com:443:KEY-V3:"));
}
