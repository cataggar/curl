const std = @import("std");

pub const CURLcode = c_uint;
pub const CURLE_OK: CURLcode = 0;
pub const CURLE_UNSUPPORTED_PROTOCOL: CURLcode = 1;
pub const CURLE_FAILED_INIT: CURLcode = 2;
pub const CURLE_URL_MALFORMAT: CURLcode = 3;
pub const CURLE_NOT_BUILT_IN: CURLcode = 4;
pub const CURLE_WEIRD_SERVER_REPLY: CURLcode = 8;
pub const CURLE_REMOTE_ACCESS_DENIED: CURLcode = 9;
pub const CURLE_HTTP_RETURNED_ERROR: CURLcode = 22;
pub const CURLE_WRITE_ERROR: CURLcode = 23;
pub const CURLE_READ_ERROR: CURLcode = 26;
pub const CURLE_OUT_OF_MEMORY: CURLcode = 27;
pub const CURLE_RANGE_ERROR: CURLcode = 33;
pub const CURLE_BAD_FUNCTION_ARGUMENT: CURLcode = 43;
pub const CURLE_ABORTED_BY_CALLBACK: CURLcode = 42;
pub const CURLE_SEND_ERROR: CURLcode = 55;
pub const CURLE_RECV_ERROR: CURLcode = 56;
pub const CURLE_BAD_CONTENT_ENCODING: CURLcode = 61;
pub const CURLE_LOGIN_DENIED: CURLcode = 67;
pub const CURLE_AUTH_ERROR: CURLcode = 94;

const STRE_OK: c_int = 0;
const STRE_BIG: c_int = 1;
const STRE_SHORT: c_int = 2;
const STRE_BEGQUOTE: c_int = 3;
const STRE_ENDQUOTE: c_int = 4;
const STRE_BYTE: c_int = 5;
const STRE_NEWLINE: c_int = 6;
const STRE_OVERFLOW: c_int = 7;
const STRE_NO_NUM: c_int = 8;

const CURL_OFF_T_MAX: i64 = std.math.maxInt(i64);

pub const Curl_easy = opaque {};
pub const connectdata = opaque {};
pub const Curl_peer = opaque {};
pub const Curl_creds = opaque {};
pub const NtlmData = opaque {};
pub const HmacParams = opaque {};
pub const HmacCtx = opaque {};

pub const curl_slist = extern struct {
    data: ?[*:0]u8,
    next: ?*curl_slist,
};

pub const Dynbuf = extern struct {
    bufr: ?[*]u8 = null,
    leng: usize = 0,
    allc: usize = 0,
    toobig: usize = 0,
};

pub const BufRef = extern struct {
    dtor: ?*const fn (?*anyopaque) callconv(.c) void = null,
    ptr: ?[*]const u8 = null,
    len: usize = 0,
    signature: c_uint = 0,
};

pub const Bufq = extern struct {
    head: ?*anyopaque = null,
    tail: ?*anyopaque = null,
    spare: ?*anyopaque = null,
    pool: ?*anyopaque = null,
    chunk_count: usize = 0,
    max_chunks: usize = 0,
    chunk_size: usize = 0,
    opts: c_int = 0,
};

pub const AuthStruct = extern struct {
    want: u32 = 0,
    picked: u32 = 0,
    avail: u32 = 0,
    bits: u32 = 0,

    pub inline fn setDone(self: *AuthStruct, val: bool) void {
        if (val) {
            self.bits |= 1;
        } else {
            self.bits &= ~@as(u32, 1);
        }
    }

    pub inline fn getDone(self: *const AuthStruct) bool {
        return (self.bits & 1) != 0;
    }
};

pub const DigestDataPrefix = extern struct {
    creds: ?*Curl_creds = null,
    origin: ?*Curl_peer = null,
    nonce_or_input_token: ?*anyopaque = null,
};

pub const NegotiateDataPrefix = extern struct {
    bits: u32 = 0,

    pub inline fn getNoauthpersist(self: *const NegotiateDataPrefix) bool {
        return (self.bits & (1 << 0)) != 0;
    }
    pub inline fn setNoauthpersist(self: *NegotiateDataPrefix, val: bool) void {
        if (val) self.bits |= (1 << 0) else self.bits &= ~@as(u32, 1 << 0);
    }
    pub inline fn getHavenoauthpersist(self: *const NegotiateDataPrefix) bool {
        return (self.bits & (1 << 1)) != 0;
    }
    pub inline fn setHavenoauthpersist(self: *NegotiateDataPrefix, val: bool) void {
        if (val) self.bits |= (1 << 1) else self.bits &= ~@as(u32, 1 << 1);
    }
    pub inline fn getHavenegdata(self: *const NegotiateDataPrefix) bool {
        return (self.bits & (1 << 2)) != 0;
    }
    pub inline fn setHavenegdata(self: *NegotiateDataPrefix, val: bool) void {
        if (val) self.bits |= (1 << 2) else self.bits &= ~@as(u32, 1 << 2);
    }
    pub inline fn getHavemultiplerequests(self: *const NegotiateDataPrefix) bool {
        return (self.bits & (1 << 3)) != 0;
    }
    pub inline fn setHavemultiplerequests(self: *NegotiateDataPrefix, val: bool) void {
        if (val) self.bits |= (1 << 3) else self.bits &= ~@as(u32, 1 << 3);
    }
};

// External C helpers
extern var Curl_cfree: *const fn (?*anyopaque) callconv(.c) void;

inline fn curlx_free(ptr: ?*anyopaque) void {
    Curl_cfree(ptr);
}
extern fn curl_maprintf(fmt: [*:0]const u8, ...) callconv(.c) ?[*:0]u8;
extern fn curl_msnprintf(buffer: [*]u8, maxlength: usize, format: [*:0]const u8, ...) callconv(.c) c_int;
extern fn curl_strnequal(s1: [*:0]const u8, s2: [*:0]const u8, n: usize) callconv(.c) c_int;
extern fn Curl_failf(data: ?*Curl_easy, fmt: [*:0]const u8, ...) callconv(.c) void;
extern fn Curl_infof(data: ?*Curl_easy, fmt: [*:0]const u8, ...) callconv(.c) void;
extern fn Curl_trc_write(data: ?*Curl_easy, fmt: [*:0]const u8, ...) callconv(.c) void;
extern fn Curl_trc_read(data: ?*Curl_easy, fmt: [*:0]const u8, ...) callconv(.c) void;

extern fn curlx_str_number(strp: *[*:0]const u8, num: *i64, max: i64) callconv(.c) c_int;
extern fn curlx_str_numblanks(strp: *[*:0]const u8, num: *i64) callconv(.c) c_int;
extern fn curlx_str_single(strp: *[*:0]const u8, byte: u8) callconv(.c) c_int;
extern fn curlx_str_passblanks(strp: *[*:0]const u8) callconv(.c) void;
extern fn curlx_str_hex(strp: *[*:0]const u8, num: *i64, max: i64) callconv(.c) c_int;

extern fn curlx_dyn_init(s: *Dynbuf, toobig: usize) callconv(.c) void;
extern fn curlx_dyn_free(s: *Dynbuf) callconv(.c) void;
extern fn curlx_dyn_reset(s: *Dynbuf) callconv(.c) void;
extern fn curlx_dyn_add(s: *Dynbuf, str: [*:0]const u8) callconv(.c) CURLcode;
extern fn curlx_dyn_addn(s: *Dynbuf, mem: ?*const anyopaque, len: usize) callconv(.c) CURLcode;
extern fn curlx_dyn_addf(s: *Dynbuf, fmt: [*:0]const u8, ...) callconv(.c) CURLcode;
extern fn curlx_dyn_ptr(s: *const Dynbuf) callconv(.c) ?[*:0]u8;
extern fn curlx_dyn_len(s: *const Dynbuf) callconv(.c) usize;

extern fn Curl_peer_equal(p1: ?*const Curl_peer, p2: ?*const Curl_peer) callconv(.c) bool;
extern fn Curl_peer_link(dst: *?*Curl_peer, src: ?*Curl_peer) callconv(.c) void;
extern fn Curl_peer_unlink(dst: *?*Curl_peer) callconv(.c) void;
extern fn Curl_creds_same(c1: ?*const Curl_creds, c2: ?*const Curl_creds) callconv(.c) bool;
extern fn Curl_creds_link(dst: *?*Curl_creds, src: ?*Curl_creds) callconv(.c) void;
extern fn Curl_creds_unlink(dst: *?*Curl_creds) callconv(.c) void;

extern fn Curl_auth_digest_cleanup(digest: *DigestDataPrefix) callconv(.c) void;
extern fn Curl_auth_decode_digest_http_message(chlg: [*:0]const u8, digest: *DigestDataPrefix) callconv(.c) CURLcode;
extern fn Curl_auth_create_digest_http_message(
    data: ?*Curl_easy,
    creds: ?*Curl_creds,
    request: ?[*:0]const u8,
    uripath: ?[*:0]const u8,
    digest: *DigestDataPrefix,
    outptr: *?[*:0]u8,
    outlen: *usize,
) callconv(.c) CURLcode;

extern fn Curl_bufref_init(br: *BufRef) callconv(.c) void;
extern fn Curl_bufref_set(
    br: *BufRef,
    ptr: ?*const anyopaque,
    len: usize,
    dtor: ?*const fn (?*anyopaque) callconv(.c) void,
) callconv(.c) void;
extern fn Curl_bufref_ptr(br: *const BufRef) callconv(.c) ?[*]const u8;
extern fn Curl_bufref_len(br: *const BufRef) callconv(.c) usize;
extern fn Curl_bufref_free(br: *BufRef) callconv(.c) void;

extern fn curlx_base64_decode(src: [*:0]const u8, outptr: *?[*]u8, outlen: *usize) callconv(.c) CURLcode;
extern fn curlx_base64_encode(inp: [*]const u8, insize: usize, outptr: *?[*:0]u8, outlen: *usize) callconv(.c) CURLcode;

extern fn Curl_auth_decode_ntlm_type2_message(
    data: ?*Curl_easy,
    type2ref: *const BufRef,
    ntlm: *NtlmData,
) callconv(.c) CURLcode;
extern fn Curl_auth_create_ntlm_type1_message(
    data: ?*Curl_easy,
    creds: ?*Curl_creds,
    service: [*:0]const u8,
    hostname: [*:0]const u8,
    ntlm: *NtlmData,
    out: *BufRef,
) callconv(.c) CURLcode;
extern fn Curl_auth_create_ntlm_type3_message(
    data: ?*Curl_easy,
    creds: ?*Curl_creds,
    ntlm: *NtlmData,
    out: *BufRef,
) callconv(.c) CURLcode;
extern fn Curl_conn_meta_remove(conn: ?*connectdata, key: [*:0]const u8) callconv(.c) void;

inline fn isBlank(c: u8) bool {
    return c == ' ' or c == '\t';
}

inline fn isSpace(c: u8) bool {
    return c == ' ' or c == '\t' or c == '\r' or c == '\n' or c == '\x0b' or c == '\x0c';
}

inline fn isXdigit(c: u8) bool {
    return (c >= '0' and c <= '9') or (c >= 'a' and c <= 'f') or (c >= 'A' and c <= 'F');
}

inline fn isCntrl(c: u8) bool {
    return c < 0x20 or c == 0x7f;
}

inline fn isLower(c: u8) bool {
    return c >= 'a' and c <= 'z';
}

inline fn isDigit(c: u8) bool {
    return c >= '0' and c <= '9';
}

// ============================================================================
// 1. lib/curl_range.c
// ============================================================================

export fn Curl_range(
    data: ?*Curl_easy,
    use_range: bool,
    range_opt: ?[*:0]const u8,
    resume_from: ?*i64,
    maxdownload: ?*i64,
) callconv(.c) CURLcode {
    _ = data;
    if (use_range) {
        if (range_opt) |s| {
            var from: i64 = 0;
            var to: i64 = 0;
            var first_num: bool = true;
            var p: [*:0]const u8 = s;

            if (curlx_str_number(&p, &from, CURL_OFF_T_MAX) != STRE_OK) {
                first_num = false;
            }

            if (curlx_str_single(&p, '-') != STRE_OK) {
                return CURLE_RANGE_ERROR;
            }

            if (curlx_str_number(&p, &to, CURL_OFF_T_MAX) != STRE_OK) {
                if (resume_from) |rf| rf.* = from;
            } else if (!first_num) {
                if (to == 0) return CURLE_RANGE_ERROR;
                if (maxdownload) |md| md.* = to;
                if (resume_from) |rf| rf.* = -to;
            } else {
                if (from > to) return CURLE_RANGE_ERROR;
                const totalsize: i64 = to - from;
                if (totalsize == CURL_OFF_T_MAX) return CURLE_RANGE_ERROR;
                if (maxdownload) |md| md.* = totalsize + 1;
                if (resume_from) |rf| rf.* = from;
            }
            return CURLE_OK;
        }
    }
    if (maxdownload) |md| {
        md.* = -1;
    }
    return CURLE_OK;
}

// ============================================================================
// 2. lib/http_digest.c
// ============================================================================

fn digest_flush_stale(
    data: ?*Curl_easy,
    digest: *DigestDataPrefix,
    origin: ?*Curl_peer,
    creds: ?*Curl_creds,
) void {
    _ = data;
    var flush = false;
    if (digest.origin == null or !Curl_peer_equal(origin, digest.origin)) {
        flush = true;
    } else if (digest.creds != null and !Curl_creds_same(creds, digest.creds)) {
        flush = true;
    }

    if (flush) {
        Curl_auth_digest_cleanup(digest);
    }

    Curl_peer_link(&digest.origin, origin);
    Curl_creds_link(&digest.creds, creds);
}

export fn Curl_input_digest(
    data: ?*Curl_easy,
    proxy: bool,
    header: ?[*:0]const u8,
    digest: ?*DigestDataPrefix,
    origin: ?*Curl_peer,
) callconv(.c) CURLcode {
    _ = data;
    const dig = digest orelse return CURLE_BAD_FUNCTION_ARGUMENT;
    if (proxy and origin == null) {
        Curl_auth_digest_cleanup(dig);
        return CURLE_OK;
    }
    const hdr = header orelse {
        Curl_auth_digest_cleanup(dig);
        return CURLE_AUTH_ERROR;
    };
    if (curl_strnequal(hdr, "Digest", 6) == 0 or !isBlank(hdr[6])) {
        Curl_auth_digest_cleanup(dig);
        return CURLE_AUTH_ERROR;
    }

    var p: [*:0]const u8 = hdr + 6;
    while (p[0] != 0 and isBlank(p[0])) : (p += 1) {}

    const result = Curl_auth_decode_digest_http_message(p, dig);
    if (result == CURLE_OK) {
        Curl_peer_link(&dig.origin, origin);
    }
    return result;
}

export fn Curl_output_digest(
    data: ?*Curl_easy,
    proxy: bool,
    request: ?[*:0]const u8,
    uripath: ?[*:0]const u8,
    digest: ?*DigestDataPrefix,
    origin: ?*Curl_peer,
    creds: ?*Curl_creds,
    allocuserpwd: ?*?[*:0]u8,
    authp: ?*AuthStruct,
) callconv(.c) CURLcode {
    if (proxy and origin == null) return CURLE_NOT_BUILT_IN;
    const dig = digest orelse return CURLE_BAD_FUNCTION_ARGUMENT;
    const alloc_ptr = allocuserpwd orelse return CURLE_BAD_FUNCTION_ARGUMENT;
    const auth_ptr = authp orelse return CURLE_BAD_FUNCTION_ARGUMENT;

    digest_flush_stale(data, dig, origin, creds);

    if (alloc_ptr.*) |old| {
        curlx_free(old);
        alloc_ptr.* = null;
    }

    const have_chlg = dig.nonce_or_input_token != null;
    if (!have_chlg) {
        auth_ptr.setDone(false);
        return CURLE_OK;
    }

    var response: ?[*:0]u8 = null;
    var len: usize = 0;
    const result = Curl_auth_create_digest_http_message(
        data,
        creds,
        request,
        uripath,
        dig,
        &response,
        &len,
    );
    if (result != CURLE_OK) return result;

    if (dig.creds == null) {
        Curl_creds_link(&dig.creds, creds);
    }

    const prefix: [*:0]const u8 = if (proxy) "Proxy-" else "";
    alloc_ptr.* = curl_maprintf("%sAuthorization: Digest %s\r\n", prefix, response);
    curlx_free(response);
    if (alloc_ptr.* == null) return CURLE_OUT_OF_MEMORY;

    auth_ptr.setDone(true);
    return CURLE_OK;
}

export fn Curl_http_auth_cleanup_digest(
    data: ?*Curl_easy,
    digest: ?*DigestDataPrefix,
    proxydigest: ?*DigestDataPrefix,
) callconv(.c) void {
    _ = data;
    if (digest) |d| Curl_auth_digest_cleanup(d);
    if (proxydigest) |pd| Curl_auth_digest_cleanup(pd);
}

// ============================================================================
// 3. lib/http_negotiate.c
// ============================================================================

pub const CURL_NEGO_AUTH_NONE: u8 = 0;
pub const CURL_NEGO_AUTH_RECV: u8 = 1;
pub const CURL_NEGO_AUTH_SENT: u8 = 2;
pub const CURL_NEGO_AUTH_DONE: u8 = 3;
pub const CURL_NEGO_AUTH_SUCC: u8 = 4;

pub const SpnegoDecodeFn = *const fn (
    ?*Curl_easy,
    ?*connectdata,
    ?*Curl_creds,
    ?[*:0]const u8,
    [*:0]const u8,
    *NegotiateDataPrefix,
) callconv(.c) CURLcode;

pub const SpnegoCreateFn = *const fn (
    *NegotiateDataPrefix,
    *?[*:0]u8,
    *usize,
    *bool,
    *bool,
) callconv(.c) CURLcode;

pub const SpnegoCleanupFn = *const fn (*NegotiateDataPrefix) callconv(.c) void;

fn http_auth_nego_reset(
    proxy: bool,
    neg_ctx: ?*NegotiateDataPrefix,
    state: *u8,
    conn_creds_origin: ?*?*Curl_peer,
    conn_creds: ?*?*Curl_creds,
    cleanup_fn: ?SpnegoCleanupFn,
) void {
    state.* = CURL_NEGO_AUTH_NONE;
    if (!proxy) {
        if (conn_creds_origin) |cco| Curl_peer_unlink(cco);
        if (conn_creds) |cc| Curl_creds_unlink(cc);
    }
    if (neg_ctx) |ctx| {
        if (cleanup_fn) |clean| clean(ctx);
    }
}

export fn Curl_input_negotiate(
    data: ?*Curl_easy,
    conn: ?*connectdata,
    proxy: bool,
    header: ?[*:0]const u8,
    creds: ?*Curl_creds,
    host: ?[*:0]const u8,
    neg_ctx: ?*NegotiateDataPrefix,
    state: ?*u8,
    origin: ?*Curl_peer,
    conn_creds_origin: ?*?*Curl_peer,
    conn_creds: ?*?*Curl_creds,
    decode_fn: ?SpnegoDecodeFn,
    cleanup_fn: ?SpnegoCleanupFn,
) callconv(.c) CURLcode {
    const ctx = neg_ctx orelse return CURLE_OUT_OF_MEMORY;
    const st = state orelse return CURLE_BAD_FUNCTION_ARGUMENT;
    const hdr = header orelse return CURLE_BAD_FUNCTION_ARGUMENT;
    if (curl_strnequal(hdr, "Negotiate", "Negotiate".len) == 0)
        return CURLE_BAD_FUNCTION_ARGUMENT;

    var p: [*:0]const u8 = hdr + "Negotiate".len;
    while (p[0] != 0 and isBlank(p[0])) : (p += 1) {}

    const len = std.mem.len(p);
    ctx.setHavenegdata(len != 0);
    if (len == 0) {
        if (st.* == CURL_NEGO_AUTH_SUCC) {
            if (data != null) Curl_infof(data, "Negotiate auth restarted");
            http_auth_nego_reset(proxy, ctx, st, conn_creds_origin, conn_creds, cleanup_fn);
        } else if (st.* != CURL_NEGO_AUTH_NONE) {
            http_auth_nego_reset(proxy, ctx, st, conn_creds_origin, conn_creds, cleanup_fn);
            return CURLE_LOGIN_DENIED;
        }
    }

    var result: CURLcode = CURLE_OK;
    if (decode_fn) |dec| {
        result = dec(data, conn, creds, host, p, ctx);
    }
    if (result != CURLE_OK) {
        http_auth_nego_reset(proxy, ctx, st, conn_creds_origin, conn_creds, cleanup_fn);
    }
    if (result == CURLE_OK and !proxy) {
        if (conn_creds_origin) |cco| {
            if (cco.* != null and !Curl_peer_equal(cco.*, origin))
                return CURLE_FAILED_INIT;
        }
        if (conn_creds) |cc| {
            if (cc.* != null and !Curl_creds_same(cc.*, creds))
                return CURLE_FAILED_INIT;
        }
        if (conn_creds_origin) |cco| {
            Curl_peer_link(cco, origin);
        }
        if (conn_creds) |cc| {
            Curl_creds_link(cc, creds);
        }
    }
    return result;
}

export fn Curl_output_negotiate(
    data: ?*Curl_easy,
    conn: ?*connectdata,
    proxy: bool,
    creds: ?*Curl_creds,
    host: ?[*:0]const u8,
    neg_ctx: ?*NegotiateDataPrefix,
    state: ?*u8,
    origin: ?*Curl_peer,
    conn_creds_origin: ?*?*Curl_peer,
    conn_creds: ?*?*Curl_creds,
    allocuserpwd: ?*?[*:0]u8,
    authp: ?*AuthStruct,
    decode_fn: ?SpnegoDecodeFn,
    create_fn: ?SpnegoCreateFn,
    cleanup_fn: ?SpnegoCleanupFn,
) callconv(.c) CURLcode {
    const ctx = neg_ctx orelse return CURLE_OUT_OF_MEMORY;
    const st = state orelse return CURLE_BAD_FUNCTION_ARGUMENT;
    const alloc_ptr = allocuserpwd orelse return CURLE_BAD_FUNCTION_ARGUMENT;
    const auth_ptr = authp orelse return CURLE_BAD_FUNCTION_ARGUMENT;
    const create_cb = create_fn orelse return CURLE_BAD_FUNCTION_ARGUMENT;

    auth_ptr.setDone(false);

    if (st.* == CURL_NEGO_AUTH_RECV) {
        if (ctx.getHavemultiplerequests()) {
            ctx.setHavenoauthpersist(true);
            ctx.setNoauthpersist(!ctx.getHavenegdata());
            if (ctx.getNoauthpersist()) {
                return CURLE_AUTH_ERROR;
            }
        }
    } else if (st.* == CURL_NEGO_AUTH_DONE or st.* == CURL_NEGO_AUTH_SUCC) {
        if (!ctx.getHavenoauthpersist()) {
            ctx.setHavemultiplerequests(true);
        }
    }

    var dummy_out: ?[*:0]u8 = null;
    var dummy_len: usize = 0;
    var has_context: bool = false;
    var is_done: bool = false;
    _ = @call(.auto, @as(
        *const fn (*NegotiateDataPrefix, ?*?[*:0]u8, *usize, *bool, *bool) callconv(.c) CURLcode,
        @ptrCast(create_cb),
    ), .{ ctx, null, &dummy_len, &has_context, &is_done });

    var result: CURLcode = CURLE_OK;
    if (!has_context and st.* == CURL_NEGO_AUTH_DONE) {
        st.* = CURL_NEGO_AUTH_SUCC;
        http_auth_nego_reset(proxy, ctx, st, conn_creds_origin, conn_creds, cleanup_fn);
        return CURLE_OK;
    } else if (!has_context) {
        result = Curl_input_negotiate(
            data,
            conn,
            proxy,
            "Negotiate",
            creds,
            host,
            ctx,
            st,
            origin,
            conn_creds_origin,
            conn_creds,
            decode_fn,
            cleanup_fn,
        );
        if (result == CURLE_AUTH_ERROR) {
            auth_ptr.setDone(true);
            return CURLE_OK;
        } else if (result != CURLE_OK) {
            return result;
        }
    }

    result = create_cb(ctx, &dummy_out, &dummy_len, &has_context, &is_done);
    if (result != CURLE_OK) return result;

    const prefix: [*:0]const u8 = if (proxy) "Proxy-" else "";
    const userp = curl_maprintf("%sAuthorization: Negotiate %s\r\n", prefix, dummy_out);
    if (alloc_ptr.*) |old| {
        curlx_free(old);
    }
    alloc_ptr.* = userp;
    curlx_free(dummy_out);

    if (userp == null) return CURLE_OUT_OF_MEMORY;

    st.* = if (is_done) CURL_NEGO_AUTH_DONE else CURL_NEGO_AUTH_SENT;

    if (st.* == CURL_NEGO_AUTH_DONE or st.* == CURL_NEGO_AUTH_SUCC) {
        auth_ptr.setDone(true);
    }

    ctx.setHavenegdata(false);
    return CURLE_OK;
}

// ============================================================================
// 4. lib/http_ntlm.c
// ============================================================================

pub const NTLMSTATE_NONE: c_uint = 0;
pub const NTLMSTATE_TYPE1: c_uint = 1;
pub const NTLMSTATE_TYPE2: c_uint = 2;
pub const NTLMSTATE_TYPE3: c_uint = 3;
pub const NTLMSTATE_LAST: c_uint = 4;

pub const CURLAUTH_NTLM: u32 = 1 << 3;

const CURL_CONN_META_NTLM_CONN: [*:0]const u8 = "meta:auth:ntml:conn";
const CURL_CONN_META_NTLM_PROXY_CONN: [*:0]const u8 = "meta:auth:ntml-proxy:conn";

pub const NtlmSspiPrepFn = *const fn (?*connectdata, ?*NtlmData) callconv(.c) CURLcode;

fn http_auth_ntlm_remove(conn: ?*connectdata, proxy: bool) void {
    if (conn != null) {
        Curl_conn_meta_remove(conn, if (proxy) CURL_CONN_META_NTLM_PROXY_CONN else CURL_CONN_META_NTLM_CONN);
    }
}

export fn Curl_input_ntlm(
    data: ?*Curl_easy,
    proxy: bool,
    header: ?[*:0]const u8,
    conn: ?*connectdata,
    ntlm: ?*NtlmData,
    state: ?*c_uint,
    conn_creds_origin: ?*?*Curl_peer,
    conn_creds: ?*?*Curl_creds,
) callconv(.c) CURLcode {
    const hdr = header orelse return CURLE_BAD_FUNCTION_ARGUMENT;
    const st = state orelse return CURLE_BAD_FUNCTION_ARGUMENT;

    if (curl_strnequal(hdr, "NTLM", 4) == 0)
        return CURLE_BAD_FUNCTION_ARGUMENT;

    const ntlm_ptr = ntlm orelse return CURLE_OUT_OF_MEMORY;

    var p: [*:0]const u8 = hdr + 4;
    while (p[0] != 0 and isBlank(p[0])) : (p += 1) {}

    if (p[0] != 0) {
        var hdr_bytes: ?[*]u8 = null;
        var hdrlen: usize = 0;
        var hdrbuf: BufRef = .{};

        var result = curlx_base64_decode(p, &hdr_bytes, &hdrlen);
        if (result == CURLE_OK) {
            Curl_bufref_init(&hdrbuf);
            Curl_bufref_set(&hdrbuf, hdr_bytes, hdrlen, Curl_cfree);
            result = Curl_auth_decode_ntlm_type2_message(data, &hdrbuf, ntlm_ptr);
            Curl_bufref_free(&hdrbuf);
        }
        if (result != CURLE_OK) return result;
        st.* = NTLMSTATE_TYPE2;
    } else {
        if (st.* == NTLMSTATE_LAST) {
            if (data != null) Curl_infof(data, "NTLM auth restarted");
            http_auth_ntlm_remove(conn, proxy);
        } else if (st.* == NTLMSTATE_TYPE3) {
            if (data != null) Curl_infof(data, "NTLM handshake rejected");
            http_auth_ntlm_remove(conn, proxy);
            if (!proxy) {
                if (conn_creds_origin) |cco| Curl_peer_unlink(cco);
                if (conn_creds) |cc| Curl_creds_unlink(cc);
            }
            st.* = NTLMSTATE_NONE;
            return CURLE_REMOTE_ACCESS_DENIED;
        } else if (st.* >= NTLMSTATE_TYPE1) {
            if (data != null) Curl_infof(data, "NTLM handshake failure (internal error)");
            return CURLE_REMOTE_ACCESS_DENIED;
        }

        st.* = NTLMSTATE_TYPE1;
    }

    return CURLE_OK;
}

export fn Curl_output_ntlm(
    data: ?*Curl_easy,
    proxy: bool,
    conn: ?*connectdata,
    ntlm: ?*NtlmData,
    hostname: ?[*:0]const u8,
    creds: ?*Curl_creds,
    state: ?*c_uint,
    allocuserpwd: ?*?[*:0]u8,
    authp: ?*AuthStruct,
    origin: ?*Curl_peer,
    conn_creds_origin: ?*?*Curl_peer,
    conn_creds: ?*?*Curl_creds,
    authpicked: ?*u32,
    sspi_prep_fn: ?NtlmSspiPrepFn,
) callconv(.c) CURLcode {
    const ntlm_ptr = ntlm orelse return CURLE_OUT_OF_MEMORY;
    const st = state orelse return CURLE_BAD_FUNCTION_ARGUMENT;
    const alloc_ptr = allocuserpwd orelse return CURLE_BAD_FUNCTION_ARGUMENT;
    const auth_ptr = authp orelse return CURLE_BAD_FUNCTION_ARGUMENT;
    const host_str: [*:0]const u8 = hostname orelse "";

    auth_ptr.setDone(false);

    if (sspi_prep_fn) |prep| {
        const sspi_res = prep(conn, ntlm_ptr);
        if (sspi_res != CURLE_OK) return sspi_res;
    }

    var base64: ?[*:0]u8 = null;
    var len: usize = 0;
    var result: CURLcode = CURLE_OK;
    var ntlmmsg: BufRef = .{};
    Curl_bufref_init(&ntlmmsg);

    if (st.* == NTLMSTATE_TYPE3) {
        st.* = NTLMSTATE_LAST;
    }

    switch (st.*) {
        NTLMSTATE_TYPE2 => {
            result = Curl_auth_create_ntlm_type3_message(data, creds, ntlm_ptr, &ntlmmsg);
            if (result == CURLE_OK and Curl_bufref_len(&ntlmmsg) != 0) {
                const msg_ptr = Curl_bufref_ptr(&ntlmmsg) orelse unreachable;
                result = curlx_base64_encode(msg_ptr, Curl_bufref_len(&ntlmmsg), &base64, &len);
                if (result == CURLE_OK) {
                    if (alloc_ptr.*) |old| curlx_free(old);
                    const prefix: [*:0]const u8 = if (proxy) "Proxy-" else "";
                    alloc_ptr.* = curl_maprintf("%sAuthorization: NTLM %s\r\n", prefix, base64);
                    curlx_free(base64);
                    if (alloc_ptr.* == null) {
                        result = CURLE_OUT_OF_MEMORY;
                    } else {
                        st.* = NTLMSTATE_TYPE3;
                        auth_ptr.setDone(true);
                    }
                }
            }
        },
        NTLMSTATE_LAST => {
            if (authpicked) |ap| ap.* = CURLAUTH_NTLM;
            if (alloc_ptr.*) |old| {
                curlx_free(old);
                alloc_ptr.* = null;
            }
            auth_ptr.setDone(true);
        },
        else => {
            if (!proxy) {
                if (conn_creds_origin) |cco| {
                    if (cco.* != null and !Curl_peer_equal(cco.*, origin))
                        return CURLE_FAILED_INIT;
                }
                if (conn_creds) |cc| {
                    if (cc.* != null and !Curl_creds_same(cc.*, creds))
                        return CURLE_FAILED_INIT;
                }
                if (conn_creds_origin) |cco| {
                    Curl_peer_link(cco, origin);
                }
                if (conn_creds) |cc| {
                    Curl_creds_link(cc, creds);
                }
            }
            result = Curl_auth_create_ntlm_type1_message(data, creds, "HTTP", host_str, ntlm_ptr, &ntlmmsg);
            if (result == CURLE_OK) {
                if (Curl_bufref_len(&ntlmmsg) != 0) {
                    const msg_ptr = Curl_bufref_ptr(&ntlmmsg) orelse unreachable;
                    result = curlx_base64_encode(msg_ptr, Curl_bufref_len(&ntlmmsg), &base64, &len);
                    if (result == CURLE_OK) {
                        if (alloc_ptr.*) |old| curlx_free(old);
                        const prefix: [*:0]const u8 = if (proxy) "Proxy-" else "";
                        alloc_ptr.* = curl_maprintf("%sAuthorization: NTLM %s\r\n", prefix, base64);
                        curlx_free(base64);
                        if (alloc_ptr.* == null) {
                            result = CURLE_OUT_OF_MEMORY;
                        }
                    }
                }
            }
        },
    }

    Curl_bufref_free(&ntlmmsg);
    return result;
}

// ============================================================================
// 5. lib/http_chunks.c
// ============================================================================

pub const CHUNK_MAXNUM_LEN: usize = 17;
pub const CURL_MAX_HTTP_HEADER: usize = 100 * 1024;

pub const ChunkyState = enum(c_int) {
    CHUNK_HEX = 0,
    CHUNK_LF = 1,
    CHUNK_DATA = 2,
    CHUNK_POSTLF = 3,
    CHUNK_STOP = 4,
    CHUNK_TRAILER = 5,
    CHUNK_TRAILER_CR = 6,
    CHUNK_TRAILER_POSTCR = 7,
    CHUNK_DONE = 8,
    CHUNK_FAILED = 9,
};

pub const CHUNKcode = enum(c_int) {
    CHUNKE_STOP = -1,
    CHUNKE_OK = 0,
    CHUNKE_TOO_LONG_HEX = 1,
    CHUNKE_ILLEGAL_HEX = 2,
    CHUNKE_BAD_CHUNK = 3,
    CHUNKE_BAD_ENCODING = 4,
    CHUNKE_OUT_OF_MEMORY = 5,
    CHUNKE_PASSTHRU_ERROR = 6,
    CHUNKE_TRAILER_LIMIT = 7,
};

pub const Curl_chunker = extern struct {
    datasize: i64,
    state: ChunkyState,
    last_code: CHUNKcode,
    trailer: Dynbuf,
    hexindex: u8,
    hexbuffer: [CHUNK_MAXNUM_LEN + 1]u8,
    ignore_body: bool,
    in_connect: bool,
};

const CLIENTWRITE_BODY: c_int = 1 << 0;
const CLIENTWRITE_INFO: c_int = 1 << 1;
const CLIENTWRITE_HEADER: c_int = 1 << 2;
const CLIENTWRITE_STATUS: c_int = 1 << 3;
const CLIENTWRITE_CONNECT: c_int = 1 << 4;
const CLIENTWRITE_1XX: c_int = 1 << 5;
const CLIENTWRITE_TRAILER: c_int = 1 << 6;
const CLIENTWRITE_EOS: c_int = 1 << 7;
const CLIENTWRITE_0LEN: c_int = 1 << 8;

const CURL_TRAILERFUNC_OK: c_int = 0;

pub const Curl_cwriter = extern struct {
    cwt: *const Curl_cwtype,
    next: ?*Curl_cwriter,
    ctx: *anyopaque,
    phase: c_uint,
};

pub const Curl_cwtype = extern struct {
    name: [*:0]const u8,
    alias: ?[*:0]const u8,
    flags: u8,
    do_init: *const fn (?*Curl_easy, *Curl_cwriter) callconv(.c) CURLcode,
    do_write: *const fn (?*Curl_easy, *Curl_cwriter, c_int, [*]const u8, usize) callconv(.c) CURLcode,
    do_flush: *const fn (?*Curl_easy, *Curl_cwriter) callconv(.c) CURLcode,
    do_close: *const fn (?*Curl_easy, *Curl_cwriter) callconv(.c) void,
    cwriter_size: usize,
};

pub const cw_chunked_ctx = extern struct {
    super: Curl_cwriter,
    ch: Curl_chunker,
};

pub const Curl_creader_phase = c_uint;
pub const CURL_CR_TRANSFER_ENCODE: Curl_creader_phase = 1;

pub const Curl_creader = extern struct {
    crt: *const Curl_crtype,
    next: ?*Curl_creader,
    ctx: *anyopaque,
    phase: Curl_creader_phase,
};

pub const Curl_crtype = extern struct {
    name: [*:0]const u8,
    do_init: *const fn (?*Curl_easy, *Curl_creader) callconv(.c) CURLcode,
    do_read: *const fn (?*Curl_easy, *Curl_creader, [*]u8, usize, *usize, *bool) callconv(.c) CURLcode,
    do_close: *const fn (?*Curl_easy, *Curl_creader) callconv(.c) void,
    needs_rewind: *const fn (?*Curl_easy, *Curl_creader) callconv(.c) bool,
    total_length: *const fn (?*Curl_easy, *Curl_creader) callconv(.c) i64,
    resume_from: *const fn (?*Curl_easy, *Curl_creader, i64) callconv(.c) CURLcode,
    cntrl: *const fn (?*Curl_easy, *Curl_creader, c_uint) callconv(.c) CURLcode,
    is_paused: *const fn (?*Curl_easy, *Curl_creader) callconv(.c) bool,
    done: *const fn (?*Curl_easy, *Curl_creader, c_int) callconv(.c) void,
    creader_size: usize,
};

pub const cr_chunked_ctx = extern struct {
    super: Curl_creader,
    buf: Bufq,
    read_eos: bool,
    eos: bool,
};

inline fn Curl_cwriter_write(
    data: ?*Curl_easy,
    writer: ?*Curl_cwriter,
    type_: c_int,
    buf: [*]const u8,
    nbytes: usize,
) CURLcode {
    const w = writer orelse return CURLE_WRITE_ERROR;
    return w.cwt.do_write(data, w, type_, buf, nbytes);
}

extern fn Curl_creader_read(
    data: ?*Curl_easy,
    reader: ?*Curl_creader,
    buf: [*]u8,
    blen: usize,
    nread: *usize,
    eos: *bool,
) callconv(.c) CURLcode;
extern fn Curl_creader_create(
    preader: *?*Curl_creader,
    data: ?*Curl_easy,
    crt: *const Curl_crtype,
    phase: Curl_creader_phase,
) callconv(.c) CURLcode;
extern fn Curl_creader_add(data: ?*Curl_easy, reader: *Curl_creader) callconv(.c) CURLcode;
extern fn Curl_creader_free(data: ?*Curl_easy, reader: *Curl_creader) callconv(.c) void;

extern fn Curl_creader_def_needs_rewind(data: ?*Curl_easy, reader: *Curl_creader) callconv(.c) bool;
extern fn Curl_creader_def_resume_from(data: ?*Curl_easy, reader: *Curl_creader, offset: i64) callconv(.c) CURLcode;
extern fn Curl_creader_def_cntrl(data: ?*Curl_easy, reader: *Curl_creader, opcode: c_uint) callconv(.c) CURLcode;
extern fn Curl_creader_def_is_paused(data: ?*Curl_easy, reader: *Curl_creader) callconv(.c) bool;
extern fn Curl_creader_def_done(data: ?*Curl_easy, reader: *Curl_creader, premature: c_int) callconv(.c) void;

extern fn Curl_bufq_init2(q: *Bufq, chunk_size: usize, max_chunks: usize, opts: c_int) callconv(.c) void;
extern fn Curl_bufq_free(q: *Bufq) callconv(.c) void;
extern fn Curl_bufq_is_empty(q: *const Bufq) callconv(.c) bool;
extern fn Curl_bufq_cread(q: *Bufq, buf: [*]u8, len: usize, pnread: *usize) callconv(.c) CURLcode;
extern fn Curl_bufq_cwrite(q: *Bufq, buf: [*]const u8, len: usize, pnwritten: *usize) callconv(.c) CURLcode;
extern fn curl_slist_free_all(list: ?*curl_slist) callconv(.c) void;

extern fn Curl_chunked_te_skip(data: ?*const Curl_easy) callconv(.c) bool;
extern fn Curl_chunked_set_req_chunk(data: ?*Curl_easy) callconv(.c) void;
extern fn Curl_chunked_set_download_done(data: ?*Curl_easy) callconv(.c) bool;
extern fn Curl_chunked_no_body(data: ?*const Curl_easy) callconv(.c) bool;
extern fn Curl_chunked_call_trailer_cb(data: ?*Curl_easy, trailers: *?*curl_slist) callconv(.c) c_int;

export fn Curl_httpchunk_init(
    data: ?*Curl_easy,
    ch: *Curl_chunker,
    ignore_body: bool,
    in_connect: bool,
) callconv(.c) void {
    _ = data;
    ch.hexindex = 0;
    ch.state = .CHUNK_HEX;
    ch.last_code = .CHUNKE_OK;
    curlx_dyn_init(&ch.trailer, CURL_MAX_HTTP_HEADER);
    ch.ignore_body = ignore_body;
    ch.in_connect = in_connect;
}

export fn Curl_httpchunk_reset(
    data: ?*Curl_easy,
    ch: *Curl_chunker,
    ignore_body: bool,
) callconv(.c) void {
    _ = data;
    ch.hexindex = 0;
    ch.state = .CHUNK_HEX;
    ch.last_code = .CHUNKE_OK;
    curlx_dyn_reset(&ch.trailer);
    ch.ignore_body = ignore_body;
}

export fn Curl_httpchunk_free(data: ?*Curl_easy, ch: *Curl_chunker) callconv(.c) void {
    _ = data;
    curlx_dyn_free(&ch.trailer);
}

extern fn Curl_client_write(data: ?*Curl_easy, type_: c_int, buf: [*]const u8, len: usize) callconv(.c) CURLcode;
extern fn Curl_verify_header(data: ?*Curl_easy, header: [*]const u8, hlen: usize) callconv(.c) CURLcode;
extern fn Curl_bump_headersize(data: ?*Curl_easy, delta: usize, connect_only: bool) callconv(.c) CURLcode;

export fn Curl_httpchunk_is_done(data: ?*Curl_easy, ch: *Curl_chunker) callconv(.c) bool {
    _ = data;
    return ch.state == .CHUNK_DONE;
}

fn httpchunk_readwrite(
    data: ?*Curl_easy,
    ch: *Curl_chunker,
    cw_next: ?*Curl_cwriter,
    buf: [*]const u8,
    blen: usize,
    pconsumed: *usize,
) CURLcode {
    var result: CURLcode = CURLE_OK;
    var datap: [*]const u8 = buf;
    var length: usize = blen;
    var piece: usize = 0;

    pconsumed.* = 0;
    if (ch.state == .CHUNK_DONE) return CURLE_OK;
    if (ch.state == .CHUNK_FAILED) return CURLE_RECV_ERROR;

    const te_skip = Curl_chunked_te_skip(data);
    if (te_skip and !ch.ignore_body) {
        if (cw_next != null) {
            result = Curl_cwriter_write(data, cw_next, CLIENTWRITE_BODY, buf, blen);
        } else {
            result = Curl_client_write(data, CLIENTWRITE_BODY, buf, blen);
        }
        if (result != CURLE_OK) {
            ch.state = .CHUNK_FAILED;
            ch.last_code = .CHUNKE_PASSTHRU_ERROR;
            return result;
        }
    }

    while (length > 0) {
        switch (ch.state) {
            .CHUNK_HEX => {
                if (isXdigit(datap[0])) {
                    if (ch.hexindex >= CHUNK_MAXNUM_LEN) {
                        if (data != null) {
                            Curl_failf(data, "chunk hex-length longer than %d", CHUNK_MAXNUM_LEN);
                        }
                        ch.state = .CHUNK_FAILED;
                        ch.last_code = .CHUNKE_TOO_LONG_HEX;
                        return CURLE_RECV_ERROR;
                    }
                    ch.hexbuffer[ch.hexindex] = datap[0];
                    datap += 1;
                    length -= 1;
                    pconsumed.* += 1;
                    ch.hexindex += 1;
                } else {
                    if (ch.hexindex == 0) {
                        if (data != null) {
                            Curl_failf(data, "chunk hex-length char not a hex digit: 0x%x", @as(c_uint, datap[0]));
                        }
                        ch.state = .CHUNK_FAILED;
                        ch.last_code = .CHUNKE_ILLEGAL_HEX;
                        return CURLE_RECV_ERROR;
                    }
                    ch.hexbuffer[ch.hexindex] = 0;
                    var hex_ptr: [*:0]const u8 = @ptrCast(&ch.hexbuffer[0]);
                    if (curlx_str_hex(&hex_ptr, &ch.datasize, CURL_OFF_T_MAX) != STRE_OK) {
                        if (data != null) {
                            Curl_failf(data, "invalid chunk size: '%s'", @as([*:0]const u8, @ptrCast(&ch.hexbuffer[0])));
                        }
                        ch.state = .CHUNK_FAILED;
                        ch.last_code = .CHUNKE_ILLEGAL_HEX;
                        return CURLE_RECV_ERROR;
                    }
                    ch.state = .CHUNK_LF;
                }
            },

            .CHUNK_LF => {
                if (datap[0] == '\n') {
                    if (ch.datasize == 0) {
                        ch.state = .CHUNK_TRAILER;
                    } else {
                        ch.state = .CHUNK_DATA;
                    }
                }
                datap += 1;
                length -= 1;
                pconsumed.* += 1;
            },

            .CHUNK_DATA => {
                piece = length;
                if (ch.datasize >= 0 and @as(usize, @intCast(ch.datasize)) < length) {
                    piece = @intCast(ch.datasize);
                }

                if (!te_skip and !ch.ignore_body) {
                    if (cw_next != null) {
                        result = Curl_cwriter_write(data, cw_next, CLIENTWRITE_BODY, datap, piece);
                    } else {
                        result = Curl_client_write(data, CLIENTWRITE_BODY, datap, piece);
                    }
                    if (result != CURLE_OK) {
                        ch.state = .CHUNK_FAILED;
                        ch.last_code = .CHUNKE_PASSTHRU_ERROR;
                        return result;
                    }
                }

                datap += piece;
                pconsumed.* += piece;
                length -= piece;
                ch.datasize -= @intCast(piece);

                if (ch.datasize == 0) {
                    ch.state = .CHUNK_POSTLF;
                }
            },

            .CHUNK_POSTLF => {
                if (datap[0] == '\n') {
                    Curl_httpchunk_reset(data, ch, ch.ignore_body);
                } else if (datap[0] != '\r') {
                    ch.state = .CHUNK_FAILED;
                    ch.last_code = .CHUNKE_BAD_CHUNK;
                    return CURLE_RECV_ERROR;
                }
                datap += 1;
                length -= 1;
                pconsumed.* += 1;
            },

            .CHUNK_TRAILER => {
                if (datap[0] == '\r' or datap[0] == '\n') {
                    const tr = curlx_dyn_ptr(&ch.trailer);
                    if (tr) |tr_ptr| {
                        var trlen = curlx_dyn_len(&ch.trailer);
                        result = curlx_dyn_addn(&ch.trailer, "\r\n", 2);
                        if (result != CURLE_OK) {
                            ch.state = .CHUNK_FAILED;
                            ch.last_code = .CHUNKE_OUT_OF_MEMORY;
                            return result;
                        }
                        const full_tr = curlx_dyn_ptr(&ch.trailer) orelse tr_ptr;
                        trlen = curlx_dyn_len(&ch.trailer);
                        if (data != null) {
                            result = Curl_verify_header(data, full_tr, trlen);
                            if (result != CURLE_OK) {
                                ch.state = .CHUNK_FAILED;
                                ch.last_code = .CHUNKE_BAD_CHUNK;
                                return result;
                            }
                        }
                        if (!te_skip) {
                            const hd_type = CLIENTWRITE_HEADER | CLIENTWRITE_TRAILER |
                                (if (ch.in_connect) CLIENTWRITE_CONNECT else @as(c_int, 0));
                            if (cw_next != null) {
                                result = Curl_cwriter_write(data, cw_next, hd_type, full_tr, trlen);
                            } else if (data != null) {
                                result = Curl_client_write(data, hd_type, full_tr, trlen);
                            }
                            if (result != CURLE_OK) {
                                ch.state = .CHUNK_FAILED;
                                ch.last_code = .CHUNKE_PASSTHRU_ERROR;
                                return result;
                            }
                            if (data != null) {
                                result = Curl_bump_headersize(data, trlen, false);
                                if (result != CURLE_OK) {
                                    ch.state = .CHUNK_FAILED;
                                    ch.last_code = .CHUNKE_TRAILER_LIMIT;
                                    return result;
                                }
                            }
                        }
                        curlx_dyn_reset(&ch.trailer);
                        ch.state = .CHUNK_TRAILER_CR;
                        if (datap[0] == '\n') continue;
                    } else {
                        ch.state = .CHUNK_TRAILER_POSTCR;
                        continue;
                    }
                } else {
                    result = curlx_dyn_addn(&ch.trailer, datap, 1);
                    if (result != CURLE_OK) {
                        ch.state = .CHUNK_FAILED;
                        ch.last_code = .CHUNKE_OUT_OF_MEMORY;
                        return result;
                    }
                }
                datap += 1;
                length -= 1;
                pconsumed.* += 1;
            },

            .CHUNK_TRAILER_CR => {
                if (datap[0] == '\n') {
                    ch.state = .CHUNK_TRAILER_POSTCR;
                    datap += 1;
                    length -= 1;
                    pconsumed.* += 1;
                } else {
                    ch.state = .CHUNK_FAILED;
                    ch.last_code = .CHUNKE_BAD_CHUNK;
                    return CURLE_RECV_ERROR;
                }
            },

            .CHUNK_TRAILER_POSTCR => {
                if (datap[0] != '\r' and datap[0] != '\n') {
                    ch.state = .CHUNK_TRAILER;
                    continue;
                }
                if (datap[0] == '\r') {
                    datap += 1;
                    length -= 1;
                    pconsumed.* += 1;
                }
                ch.state = .CHUNK_STOP;
            },

            .CHUNK_STOP => {
                if (datap[0] == '\n') {
                    length -= 1;
                    pconsumed.* += 1;
                    ch.datasize = @intCast(length);
                    ch.state = .CHUNK_DONE;
                    return CURLE_OK;
                } else {
                    ch.state = .CHUNK_FAILED;
                    ch.last_code = .CHUNKE_BAD_CHUNK;
                    return CURLE_RECV_ERROR;
                }
            },

            .CHUNK_DONE => {
                return CURLE_OK;
            },

            .CHUNK_FAILED => {
                return CURLE_RECV_ERROR;
            },
        }
    }

    return CURLE_OK;
}

export fn Curl_chunked_strerror(code: CHUNKcode) callconv(.c) [*:0]const u8 {
    return switch (code) {
        .CHUNKE_TOO_LONG_HEX => "Too long hexadecimal number",
        .CHUNKE_ILLEGAL_HEX => "Illegal or missing hexadecimal sequence",
        .CHUNKE_BAD_CHUNK => "Malformed encoding found",
        .CHUNKE_PASSTHRU_ERROR => "Error writing data to client",
        .CHUNKE_BAD_ENCODING => "Bad content-encoding found",
        .CHUNKE_OUT_OF_MEMORY => "Out of memory",
        .CHUNKE_TRAILER_LIMIT => "trailers exceeded header limit",
        else => "OK",
    };
}

export fn Curl_httpchunk_read(
    data: ?*Curl_easy,
    ch: *Curl_chunker,
    buf: [*]u8,
    blen: usize,
    pconsumed: *usize,
) callconv(.c) CURLcode {
    return httpchunk_readwrite(data, ch, null, buf, blen, pconsumed);
}

fn cw_chunked_init(data: ?*Curl_easy, writer: *Curl_cwriter) callconv(.c) CURLcode {
    const ctx: *cw_chunked_ctx = @ptrCast(@alignCast(writer.ctx));
    Curl_chunked_set_req_chunk(data);
    Curl_httpchunk_init(data, &ctx.ch, false, false);
    return CURLE_OK;
}

fn cw_chunked_close(data: ?*Curl_easy, writer: *Curl_cwriter) callconv(.c) void {
    const ctx: *cw_chunked_ctx = @ptrCast(@alignCast(writer.ctx));
    Curl_httpchunk_free(data, &ctx.ch);
}

fn cw_chunked_write(
    data: ?*Curl_easy,
    writer: *Curl_cwriter,
    type_: c_int,
    buf: [*]const u8,
    blen: usize,
) callconv(.c) CURLcode {
    const ctx: *cw_chunked_ctx = @ptrCast(@alignCast(writer.ctx));
    var result: CURLcode = CURLE_OK;
    var consumed: usize = 0;

    if ((type_ & CLIENTWRITE_BODY) == 0) {
        return Curl_cwriter_write(data, writer.next, type_, buf, blen);
    }

    consumed = 0;
    result = httpchunk_readwrite(data, &ctx.ch, writer.next, buf, blen, &consumed);

    if (result != CURLE_OK) {
        if (ctx.ch.last_code == .CHUNKE_PASSTHRU_ERROR) {
            if (data != null) {
                Curl_failf(data, "Failed reading the chunked-encoded stream");
            }
        } else if (data != null) {
            Curl_failf(
                data,
                "%s in chunked-encoding",
                Curl_chunked_strerror(ctx.ch.last_code),
            );
        }
        return result;
    }

    const rest_len = blen - consumed;
    if (ctx.ch.state == .CHUNK_DONE) {
        _ = Curl_chunked_set_download_done(data);
        if (rest_len > 0) {
            if (data != null) {
                Curl_infof(
                    data,
                    "Leftovers after chunking: %zu bytes",
                    rest_len,
                );
            }
        }
    } else if ((type_ & CLIENTWRITE_EOS) != 0) {
        const no_body = if (data != null) Curl_chunked_no_body(data) else false;
        if (!no_body) {
            if (data != null) {
                Curl_failf(data, "transfer closed with outstanding read data remaining");
            }
            return CURLE_PARTIAL_FILE_CONST;
        }
    }

    return CURLE_OK;
}

const CURLE_PARTIAL_FILE_CONST: CURLcode = 18;

extern fn Curl_cwriter_def_flush(data: ?*Curl_easy, writer: *Curl_cwriter) callconv(.c) CURLcode;

pub export const Curl_httpchunk_unencoder: Curl_cwtype = .{
    .name = "chunked",
    .alias = "x-chunked",
    .flags = 0,
    .do_init = cw_chunked_init,
    .do_write = cw_chunked_write,
    .do_flush = Curl_cwriter_def_flush,
    .do_close = cw_chunked_close,
    .cwriter_size = @sizeOf(cw_chunked_ctx),
};

const BUFQ_OPT_SOFT_LIMIT: c_int = 1 << 0;

fn cr_chunked_init(data: ?*Curl_easy, reader: *Curl_creader) callconv(.c) CURLcode {
    _ = data;
    const ctx: *cr_chunked_ctx = @ptrCast(@alignCast(reader.ctx));
    Curl_bufq_init2(&ctx.buf, 16 * 1024, 2, BUFQ_OPT_SOFT_LIMIT);
    return CURLE_OK;
}

fn cr_chunked_close(data: ?*Curl_easy, reader: *Curl_creader) callconv(.c) void {
    _ = data;
    const ctx: *cr_chunked_ctx = @ptrCast(@alignCast(reader.ctx));
    Curl_bufq_free(&ctx.buf);
}

fn add_last_chunk(data: ?*Curl_easy, reader: *Curl_creader) CURLcode {
    const ctx: *cr_chunked_ctx = @ptrCast(@alignCast(reader.ctx));
    var trailers: ?*curl_slist = null;
    var result: CURLcode = CURLE_OK;
    var n: usize = 0;

    const rc = Curl_chunked_call_trailer_cb(data, &trailers);
    if (rc < 0) {
        return Curl_bufq_cwrite(&ctx.buf, "0\r\n\r\n", 5, &n);
    }

    if (rc != CURL_TRAILERFUNC_OK) {
        if (data != null) {
            Curl_failf(data, "operation aborted by trailing headers callback");
        }
        curl_slist_free_all(trailers);
        return CURLE_ABORTED_BY_CALLBACK;
    }

    result = Curl_bufq_cwrite(&ctx.buf, "0\r\n", 3, &n);
    if (result != CURLE_OK) {
        curl_slist_free_all(trailers);
        return result;
    }

    var cur = trailers;
    while (cur) |node| : (cur = node.next) {
        const s = node.data orelse continue;
        var ptr: [*:0]const u8 = s;
        while (ptr[0] != 0 and ptr[0] != ':') : (ptr += 1) {}
        if (ptr[0] == 0 or (ptr + 1)[0] == 0) continue;

        result = Curl_bufq_cwrite(&ctx.buf, s, std.mem.len(s), &n);
        if (result == CURLE_OK) {
            result = Curl_bufq_cwrite(&ctx.buf, "\r\n", 2, &n);
        }
        if (result != CURLE_OK) {
            curl_slist_free_all(trailers);
            return result;
        }
    }

    result = Curl_bufq_cwrite(&ctx.buf, "\r\n", 2, &n);
    curl_slist_free_all(trailers);
    return result;
}

const CHUNK_SCRATCH_SIZE: usize = 32;

fn cr_chunked_read(
    data: ?*Curl_easy,
    reader: *Curl_creader,
    buf: [*]u8,
    blen: usize,
    pnread: *usize,
    peos: *bool,
) callconv(.c) CURLcode {
    const ctx: *cr_chunked_ctx = @ptrCast(@alignCast(reader.ctx));
    var result: CURLcode = CURLE_OK;
    var nread: usize = 0;
    var n: usize = 0;
    var eos: bool = false;

    pnread.* = 0;
    peos.* = false;
    if (ctx.eos) {
        peos.* = true;
        return CURLE_OK;
    }

    if (Curl_bufq_is_empty(&ctx.buf)) {
        if (ctx.read_eos) {
            result = Curl_bufq_cread(&ctx.buf, buf, blen, pnread);
            if (result == CURLE_OK and Curl_bufq_is_empty(&ctx.buf)) {
                ctx.eos = true;
                peos.* = true;
            }
            return result;
        }

        var scratch: [CHUNK_SCRATCH_SIZE]u8 = std.mem.zeroes([CHUNK_SCRATCH_SIZE]u8);
        var read_buf = buf;
        var read_len = blen;
        if (read_len < CHUNK_SCRATCH_SIZE) {
            read_buf = &scratch;
            read_len = CHUNK_SCRATCH_SIZE;
        }
        read_len -= (11 + 2);

        result = Curl_creader_read(data, reader.next, read_buf + 11, read_len, &nread, &eos);
        if (result != CURLE_OK) return result;
        if (eos) {
            ctx.read_eos = true;
        }

        if (nread > 0) {
            var hdr: [11]u8 = std.mem.zeroes([11]u8);
            const hlen_i = curl_msnprintf(&hdr, hdr.len, "%zx\r\n", nread);
            if (hlen_i <= 0) return CURLE_READ_ERROR;
            const hlen: usize = @intCast(hlen_i);

            if (read_buf == buf and !eos) {
                std.mem.copyForwards(u8, buf[0..hlen], hdr[0..hlen]);
                std.mem.copyForwards(u8, buf[hlen .. hlen + nread], buf[11 .. 11 + nread]);
                buf[hlen + nread] = '\r';
                buf[hlen + nread + 1] = '\n';
                pnread.* = hlen + nread + 2;
                if (data != null) {
                    Curl_trc_read(data, "cr_chunked_read(%zu) -> %d, nread=%zu, eos=%d", blen, result, pnread.*, peos.*);
                }
                return CURLE_OK;
            }

            result = Curl_bufq_cwrite(&ctx.buf, &hdr, hlen, &n);
            if (result == CURLE_OK) {
                result = Curl_bufq_cwrite(&ctx.buf, read_buf + 11, nread, &n);
            }
            if (result == CURLE_OK) {
                result = Curl_bufq_cwrite(&ctx.buf, "\r\n", 2, &n);
            }
            if (result != CURLE_OK) return result;
        }

        if (ctx.read_eos) {
            result = add_last_chunk(data, reader);
            if (result != CURLE_OK) return result;
        }
    }

    if (Curl_bufq_is_empty(&ctx.buf)) {
        return CURLE_OK;
    }

    result = Curl_bufq_cread(&ctx.buf, buf, blen, pnread);
    if (result == CURLE_OK and ctx.read_eos and Curl_bufq_is_empty(&ctx.buf)) {
        ctx.eos = true;
        peos.* = true;
    }

    if (data != null) {
        Curl_trc_read(data, "cr_chunked_read(%zu) -> %d, nread=%zu, eos=%d", blen, result, pnread.*, peos.*);
    }
    return result;
}

fn cr_chunked_total_length(data: ?*Curl_easy, reader: *Curl_creader) callconv(.c) i64 {
    _ = data;
    _ = reader;
    return -1;
}

pub export const Curl_httpchunk_encoder: Curl_crtype = .{
    .name = "chunked",
    .do_init = cr_chunked_init,
    .do_read = cr_chunked_read,
    .do_close = cr_chunked_close,
    .needs_rewind = Curl_creader_def_needs_rewind,
    .total_length = cr_chunked_total_length,
    .resume_from = Curl_creader_def_resume_from,
    .cntrl = Curl_creader_def_cntrl,
    .is_paused = Curl_creader_def_is_paused,
    .done = Curl_creader_def_done,
    .creader_size = @sizeOf(cr_chunked_ctx),
};

export fn Curl_httpchunk_add_reader(data: ?*Curl_easy) callconv(.c) CURLcode {
    var reader: ?*Curl_creader = null;
    var result = Curl_creader_create(&reader, data, &Curl_httpchunk_encoder, CURL_CR_TRANSFER_ENCODE);
    if (result == CURLE_OK) {
        if (reader) |r| {
            result = Curl_creader_add(data, r);
        }
    }

    if (result != CURLE_OK) {
        if (reader) |r| {
            Curl_creader_free(data, r);
        }
    }
    return result;
}

// ============================================================================
// 6. lib/http_httpsig.c
// ============================================================================

pub const CURL_HTTPSIG_HMAC_SHA256: u8 = 1;

const HTTPSIG_MAX_BASE_LEN: usize = 65536;
const HTTPSIG_MAX_PARAMS_LEN: usize = 4096;
const HTTPSIG_MAX_VAL_LEN: usize = 8192;
const HTTPSIG_MAX_KEYID_LEN: usize = 256;

const SHA256_DIGEST_LENGTH: usize = 32;

const HttpsigAlg = struct {
    id: u8,
    iana_name: [*:0]const u8,
    hmac_params: *const HmacParams,
    key_len: usize,
    sig_len: usize,
};

extern const Curl_HMAC_SHA256: HmacParams;
extern fn Curl_HMAC_init(hashparams: *const HmacParams, key: [*]const u8, keylen: c_uint) callconv(.c) ?*HmacCtx;
extern fn Curl_HMAC_update(ctx: *HmacCtx, data: [*]const u8, len: c_uint) callconv(.c) c_int;
extern fn Curl_HMAC_final(ctx: *HmacCtx, result: [*]u8) callconv(.c) c_int;

extern fn Curl_http_method(
    data: ?*Curl_easy,
    method: *?[*:0]const u8,
    reqp: *c_uint,
) callconv(.c) void;
extern fn Curl_checkheaders(
    data: ?*const Curl_easy,
    thisheader: [*]const u8,
    thislen: usize,
) callconv(.c) ?[*:0]u8;

fn httpsig_find_alg(alg_id: u8) ?HttpsigAlg {
    if (alg_id == CURL_HTTPSIG_HMAC_SHA256) {
        return .{
            .id = CURL_HTTPSIG_HMAC_SHA256,
            .iana_name = "hmac-sha256",
            .hmac_params = &Curl_HMAC_SHA256,
            .key_len = SHA256_DIGEST_LENGTH,
            .sig_len = SHA256_DIGEST_LENGTH,
        };
    }
    return null;
}

fn hex_val(c: u8) i32 {
    if (c >= '0' and c <= '9') return @intCast(c - '0');
    if (c >= 'a' and c <= 'f') return @intCast(c - 'a' + 10);
    if (c >= 'A' and c <= 'F') return @intCast(c - 'A' + 10);
    return -1;
}

fn httpsig_parse_hex_key(
    data: ?*Curl_easy,
    hex: [*:0]const u8,
    out: [*]u8,
    expected_len: usize,
) CURLcode {
    const hexlen = std.mem.len(hex);
    if (hexlen != expected_len * 2) {
        if (data != null) {
            Curl_failf(
                data,
                "HTTPSIG: key must be %zu hex digits (%zu bytes), got %zu chars",
                expected_len * 2,
                expected_len,
                hexlen,
            );
        }
        return CURLE_BAD_FUNCTION_ARGUMENT;
    }
    var i: usize = 0;
    while (i < expected_len) : (i += 1) {
        const hi = hex_val(hex[i * 2]);
        const lo = hex_val(hex[i * 2 + 1]);
        if (hi < 0 or lo < 0) {
            if (data != null) {
                Curl_failf(
                    data,
                    "HTTPSIG: invalid hex character in key at position %zu",
                    i * 2,
                );
            }
            return CURLE_BAD_FUNCTION_ARGUMENT;
        }
        out[i] = @intCast((hi << 4) | lo);
    }
    return CURLE_OK;
}

fn httpsig_valid_keyid(keyid: [*:0]const u8) bool {
    var len: usize = 0;
    var p = keyid;
    while (p[0] != 0) : (p += 1) {
        const c = p[0];
        if (isCntrl(c) or c == '"' or c == '\\') return false;
        len += 1;
        if (len > HTTPSIG_MAX_KEYID_LEN) return false;
    }
    return len > 0;
}

fn is_sf_tchar(c: u8) bool {
    return isLower(c) or isDigit(c) or
        c == '_' or c == '-' or c == '.' or c == '*';
}

fn httpsig_valid_component_name(name: [*]const u8, len: usize) bool {
    if (len == 0) return false;
    var start: usize = 0;
    if (name[0] == '@') {
        if (len == 1) return false;
        start = 1;
    }
    var i: usize = start;
    while (i < len) : (i += 1) {
        if (!is_sf_tchar(name[i])) return false;
    }
    return true;
}

fn httpsig_resolve_derived(
    data: ?*Curl_easy,
    name: [*]const u8,
    nlen: usize,
    val_buf: *Dynbuf,
    http_host: ?[*:0]const u8,
    up_path: ?[*:0]const u8,
    up_query: ?[*:0]const u8,
    origin_hostname: ?[*:0]const u8,
    origin_port: u16,
    origin_defport: u16,
    method_override: ?[*:0]const u8,
) CURLcode {
    const name_slice = name[0..nlen];
    if (std.mem.eql(u8, name_slice, "@method")) {
        var method: ?[*:0]const u8 = method_override;
        if (method == null and data != null) {
            var httpreq: c_uint = 0;
            Curl_http_method(data, &method, &httpreq);
        }
        return curlx_dyn_add(val_buf, method orelse "GET");
    } else if (std.mem.eql(u8, name_slice, "@authority")) {
        if (http_host) |hh| {
            if (hh[0] != 0) {
                var p: [*:0]const u8 = hh;
                while (p[0] != 0) : (p += 1) {
                    const c = p[0];
                    const lc: u8 = if (c >= 'A' and c <= 'Z') c + ('a' - 'A') else c;
                    const res = curlx_dyn_addn(val_buf, &lc, 1);
                    if (res != CURLE_OK) return res;
                }
                return CURLE_OK;
            }
        }
        const host = origin_hostname orelse "";
        var p: [*:0]const u8 = host;
        while (p[0] != 0) : (p += 1) {
            const c = p[0];
            const lc: u8 = if (c >= 'A' and c <= 'Z') c + ('a' - 'A') else c;
            const res = curlx_dyn_addn(val_buf, &lc, 1);
            if (res != CURLE_OK) return res;
        }
        if (origin_port != origin_defport) {
            return curlx_dyn_addf(val_buf, ":%u", @as(c_uint, origin_port));
        }
        return CURLE_OK;
    } else if (std.mem.eql(u8, name_slice, "@path")) {
        const path: [*:0]const u8 = if (up_path != null and up_path.?[0] != 0) up_path.? else "/";
        return curlx_dyn_add(val_buf, path);
    } else if (std.mem.eql(u8, name_slice, "@query")) {
        const res = curlx_dyn_addn(val_buf, "?", 1);
        if (res != CURLE_OK) return res;
        if (up_query) |uq| {
            return curlx_dyn_add(val_buf, uq);
        }
        return CURLE_OK;
    } else if (std.mem.eql(u8, name_slice, "@request-target")) {
        const path: [*:0]const u8 = if (up_path != null and up_path.?[0] != 0) up_path.? else "/";
        if (up_query) |uq| {
            return curlx_dyn_addf(val_buf, "%s?%s", path, uq);
        }
        return curlx_dyn_add(val_buf, path);
    } else {
        if (data != null) {
            Curl_failf(
                data,
                "HTTPSIG: unsupported derived component '%.*s'",
                @as(c_int, @intCast(nlen)),
                name,
            );
        }
        return CURLE_BAD_FUNCTION_ARGUMENT;
    }
}

fn httpsig_resolve_header(
    data: ?*Curl_easy,
    name: [*]const u8,
    nlen: usize,
    val_buf: *Dynbuf,
    headers: ?*curl_slist,
    http_host: ?[*:0]const u8,
    origin_hostname: ?[*:0]const u8,
    origin_port: u16,
    origin_defport: u16,
) CURLcode {
    var found: bool = false;
    var h = headers;
    while (h) |node| : (h = node.next) {
        const hdata = node.data orelse continue;
        var colon: ?usize = null;
        var idx: usize = 0;
        while (hdata[idx] != 0) : (idx += 1) {
            if (hdata[idx] == ':') {
                colon = idx;
                break;
            }
        }
        const hnamelen = colon orelse continue;
        if (hnamelen != nlen) continue;
        if (curl_strnequal(hdata, @ptrCast(name), nlen) == 0) continue;

        var vstart: usize = hnamelen + 1;
        while (hdata[vstart] != 0 and isBlank(hdata[vstart])) : (vstart += 1) {}
        var vend: usize = vstart + std.mem.len(@as([*:0]const u8, @ptrCast(hdata + vstart)));
        while (vend > vstart and isBlank(hdata[vend - 1])) : (vend -= 1) {}

        var c_idx = vstart;
        while (c_idx < vend) : (c_idx += 1) {
            if (isCntrl(hdata[c_idx]) and hdata[c_idx] != '\t') {
                if (data != null) {
                    Curl_failf(
                        data,
                        "HTTPSIG: header '%.*s' value contains control characters",
                        @as(c_int, @intCast(nlen)),
                        name,
                    );
                }
                return CURLE_BAD_FUNCTION_ARGUMENT;
            }
        }

        if (found) {
            const res = curlx_dyn_addn(val_buf, ", ", 2);
            if (res != CURLE_OK) return res;
        }
        const res = curlx_dyn_addn(val_buf, hdata + vstart, vend - vstart);
        if (res != CURLE_OK) return res;
        found = true;
    }

    if (!found and nlen == 4 and curl_strnequal(@ptrCast(name), "host", 4) != 0) {
        if (http_host) |hh| {
            if (hh[0] != 0) {
                return curlx_dyn_add(val_buf, hh);
            }
        }
        if (origin_hostname) |oh| {
            if (origin_port != origin_defport) {
                return curlx_dyn_addf(val_buf, "%s:%u", oh, @as(c_uint, origin_port));
            }
            return curlx_dyn_add(val_buf, oh);
        }
    }

    if (!found) {
        if (data != null) {
            Curl_failf(
                data,
                "HTTPSIG: header '%.*s' not found in request",
                @as(c_int, @intCast(nlen)),
                name,
            );
        }
        return CURLE_BAD_FUNCTION_ARGUMENT;
    }

    return CURLE_OK;
}

fn httpsig_build_base(
    data: ?*Curl_easy,
    alg: HttpsigAlg,
    keyid: [*:0]const u8,
    hdr_list: ?[*:0]const u8,
    created: i64,
    base_buf: *Dynbuf,
    params_buf: *Dynbuf,
    http_host: ?[*:0]const u8,
    up_path: ?[*:0]const u8,
    up_query: ?[*:0]const u8,
    headers: ?*curl_slist,
    origin_hostname: ?[*:0]const u8,
    origin_port: u16,
    origin_defport: u16,
    method_override: ?[*:0]const u8,
) CURLcode {
    var result: CURLcode = CURLE_OK;
    var val_buf: Dynbuf = .{};
    var seen_buf: Dynbuf = .{};
    var first_comp: bool = true;

    curlx_dyn_init(&val_buf, HTTPSIG_MAX_VAL_LEN);
    curlx_dyn_init(&seen_buf, HTTPSIG_MAX_PARAMS_LEN);

    const effective_hdrs: [*:0]const u8 = if (hdr_list != null and hdr_list.?[0] != 0)
        hdr_list.?
    else
        "@method @authority @path";

    result = curlx_dyn_addn(params_buf, "(", 1);
    if (result != CURLE_OK) {
        curlx_dyn_free(&val_buf);
        curlx_dyn_free(&seen_buf);
        return result;
    }

    result = curlx_dyn_addn(&seen_buf, " ", 1);
    if (result != CURLE_OK) {
        curlx_dyn_free(&val_buf);
        curlx_dyn_free(&seen_buf);
        return result;
    }

    var p: [*:0]const u8 = effective_hdrs;
    while (p[0] != 0) {
        while (p[0] != 0 and isSpace(p[0])) : (p += 1) {}
        if (p[0] == 0) break;

        const tok_start = p;
        var tok_len: usize = 0;
        while (p[0] != 0 and !isSpace(p[0])) {
            p += 1;
            tok_len += 1;
        }

        if (!httpsig_valid_component_name(tok_start, tok_len)) {
            if (data != null) {
                Curl_failf(
                    data,
                    "HTTPSIG: invalid component name '%.*s' (must be lowercase ASCII token)",
                    @as(c_int, @intCast(tok_len)),
                    tok_start,
                );
            }
            curlx_dyn_free(&val_buf);
            curlx_dyn_free(&seen_buf);
            return CURLE_BAD_FUNCTION_ARGUMENT;
        }

        if (tok_len < 126) {
            var needle: [130]u8 = std.mem.zeroes([130]u8);
            _ = curl_msnprintf(&needle, needle.len, " %.*s ", @as(c_int, @intCast(tok_len)), tok_start);
            const needle_slice = std.mem.sliceTo(&needle, 0);
            if (curlx_dyn_ptr(&seen_buf)) |seen_ptr| {
                const seen_slice = seen_ptr[0..curlx_dyn_len(&seen_buf)];
                if (std.mem.indexOf(u8, seen_slice, needle_slice) != null) {
                    if (data != null) {
                        Curl_failf(
                            data,
                            "HTTPSIG: duplicate component '%.*s'",
                            @as(c_int, @intCast(tok_len)),
                            tok_start,
                        );
                    }
                    curlx_dyn_free(&val_buf);
                    curlx_dyn_free(&seen_buf);
                    return CURLE_BAD_FUNCTION_ARGUMENT;
                }
            }
            result = curlx_dyn_addf(&seen_buf, "%.*s ", @as(c_int, @intCast(tok_len)), tok_start);
            if (result != CURLE_OK) {
                curlx_dyn_free(&val_buf);
                curlx_dyn_free(&seen_buf);
                return result;
            }
        }

        curlx_dyn_reset(&val_buf);

        if (tok_start[0] == '@') {
            result = httpsig_resolve_derived(
                data,
                tok_start,
                tok_len,
                &val_buf,
                http_host,
                up_path,
                up_query,
                origin_hostname,
                origin_port,
                origin_defport,
                method_override,
            );
        } else {
            result = httpsig_resolve_header(
                data,
                tok_start,
                tok_len,
                &val_buf,
                headers,
                http_host,
                origin_hostname,
                origin_port,
                origin_defport,
            );
        }

        if (result != CURLE_OK) {
            curlx_dyn_free(&val_buf);
            curlx_dyn_free(&seen_buf);
            return result;
        }

        const val_str: [*:0]const u8 = curlx_dyn_ptr(&val_buf) orelse "";
        result = curlx_dyn_addf(
            base_buf,
            "\"%.*s\": %s\n",
            @as(c_int, @intCast(tok_len)),
            tok_start,
            val_str,
        );
        if (result != CURLE_OK) {
            curlx_dyn_free(&val_buf);
            curlx_dyn_free(&seen_buf);
            return result;
        }

        if (!first_comp) {
            result = curlx_dyn_addn(params_buf, " ", 1);
            if (result != CURLE_OK) {
                curlx_dyn_free(&val_buf);
                curlx_dyn_free(&seen_buf);
                return result;
            }
        }
        result = curlx_dyn_addf(params_buf, "\"%.*s\"", @as(c_int, @intCast(tok_len)), tok_start);
        if (result != CURLE_OK) {
            curlx_dyn_free(&val_buf);
            curlx_dyn_free(&seen_buf);
            return result;
        }
        first_comp = false;
    }

    result = curlx_dyn_addf(
        params_buf,
        ");created=%lld;keyid=\"%s\";alg=\"%s\"",
        @as(c_longlong, created),
        keyid,
        alg.iana_name,
    );
    if (result != CURLE_OK) {
        curlx_dyn_free(&val_buf);
        curlx_dyn_free(&seen_buf);
        return result;
    }

    const params_str: [*:0]const u8 = curlx_dyn_ptr(params_buf) orelse "";
    result = curlx_dyn_addf(base_buf, "\"@signature-params\": %s", params_str);

    curlx_dyn_free(&val_buf);
    curlx_dyn_free(&seen_buf);
    return result;
}

export fn Curl_output_httpsig(
    data: ?*Curl_easy,
    alg_id: u8,
    hexkey: ?[*:0]const u8,
    keyid: ?[*:0]const u8,
    hdr_list: ?[*:0]const u8,
    http_host: ?[*:0]const u8,
    up_path: ?[*:0]const u8,
    up_query: ?[*:0]const u8,
    headers: ?*curl_slist,
    origin_hostname: ?[*:0]const u8,
    origin_port: u16,
    origin_defport: u16,
    created: i64,
    hd_auth: ?*?[*:0]u8,
    authhost: ?*AuthStruct,
    method_override: ?[*:0]const u8,
) callconv(.c) CURLcode {
    var raw_key: [SHA256_DIGEST_LENGTH]u8 = std.mem.zeroes([SHA256_DIGEST_LENGTH]u8);
    var sig_raw: [SHA256_DIGEST_LENGTH]u8 = std.mem.zeroes([SHA256_DIGEST_LENGTH]u8);
    var sig_b64: ?[*:0]u8 = null;
    var sig_b64_len: usize = 0;
    var base_buf: Dynbuf = .{};
    var params_buf: Dynbuf = .{};

    if (alg_id == 0) {
        if (data != null) Curl_failf(data, "HTTPSIG: algorithm not configured");
        return CURLE_BAD_FUNCTION_ARGUMENT;
    }

    const alg = httpsig_find_alg(alg_id) orelse {
        if (data != null) Curl_failf(data, "HTTPSIG: unsupported algorithm (%d)", @as(c_int, alg_id));
        return CURLE_BAD_FUNCTION_ARGUMENT;
    };

    const hk = hexkey orelse {
        if (data != null) Curl_failf(data, "HTTPSIG: key not configured");
        return CURLE_BAD_FUNCTION_ARGUMENT;
    };
    if (hk[0] == 0) {
        if (data != null) Curl_failf(data, "HTTPSIG: key not configured");
        return CURLE_BAD_FUNCTION_ARGUMENT;
    }

    const kid = keyid orelse {
        if (data != null) Curl_failf(data, "HTTPSIG: keyid not configured");
        return CURLE_BAD_FUNCTION_ARGUMENT;
    };
    if (kid[0] == 0) {
        if (data != null) Curl_failf(data, "HTTPSIG: keyid not configured");
        return CURLE_BAD_FUNCTION_ARGUMENT;
    }

    if (!httpsig_valid_keyid(kid)) {
        if (data != null) {
            Curl_failf(
                data,
                "HTTPSIG: keyid contains invalid characters (no quotes, backslashes, or control characters allowed)",
            );
        }
        std.crypto.secureZero(u8, &raw_key);
        return CURLE_BAD_FUNCTION_ARGUMENT;
    }

    var result = httpsig_parse_hex_key(data, hk, &raw_key, alg.key_len);
    if (result != CURLE_OK) {
        std.crypto.secureZero(u8, &raw_key);
        return result;
    }

    curlx_dyn_init(&base_buf, HTTPSIG_MAX_BASE_LEN);
    curlx_dyn_init(&params_buf, HTTPSIG_MAX_PARAMS_LEN);

    result = httpsig_build_base(
        data,
        alg,
        kid,
        hdr_list,
        created,
        &base_buf,
        &params_buf,
        http_host,
        up_path,
        up_query,
        headers,
        origin_hostname,
        origin_port,
        origin_defport,
        method_override,
    );
    if (result != CURLE_OK) {
        curlx_dyn_free(&base_buf);
        curlx_dyn_free(&params_buf);
        curlx_free(sig_b64);
        std.crypto.secureZero(u8, &raw_key);
        return result;
    }

    const hmac_ctx = Curl_HMAC_init(alg.hmac_params, &raw_key, @intCast(alg.key_len)) orelse {
        curlx_dyn_free(&base_buf);
        curlx_dyn_free(&params_buf);
        curlx_free(sig_b64);
        std.crypto.secureZero(u8, &raw_key);
        return CURLE_OUT_OF_MEMORY;
    };

    const base_str: [*:0]const u8 = curlx_dyn_ptr(&base_buf) orelse "";
    const base_len = curlx_dyn_len(&base_buf);
    _ = Curl_HMAC_update(hmac_ctx, base_str, @intCast(base_len));
    _ = Curl_HMAC_final(hmac_ctx, &sig_raw);

    result = curlx_base64_encode(&sig_raw, alg.sig_len, &sig_b64, &sig_b64_len);
    if (result != CURLE_OK) {
        curlx_dyn_free(&base_buf);
        curlx_dyn_free(&params_buf);
        curlx_free(sig_b64);
        std.crypto.secureZero(u8, &raw_key);
        return result;
    }

    var has_sig = false;
    var has_sig_input = false;
    if (data != null and method_override == null) {
        has_sig = Curl_checkheaders(data, "Signature", 9) != null;
        has_sig_input = Curl_checkheaders(data, "Signature-Input", 15) != null;
    } else {
        var h = headers;
        while (h) |node| : (h = node.next) {
            const hdata = node.data orelse continue;
            if (curl_strnequal(hdata, "Signature:", 10) != 0) has_sig = true;
            if (curl_strnequal(hdata, "Signature-Input:", 16) != 0) has_sig_input = true;
        }
    }

    if (has_sig or has_sig_input) {
        if (data != null) {
            Curl_failf(
                data,
                "HTTPSIG: custom Signature or Signature-Input headers conflict with automatic signing",
            );
        }
        curlx_dyn_free(&base_buf);
        curlx_dyn_free(&params_buf);
        curlx_free(sig_b64);
        std.crypto.secureZero(u8, &raw_key);
        return CURLE_BAD_FUNCTION_ARGUMENT;
    }

    if (hd_auth) |hda| {
        if (hda.*) |old| curlx_free(old);
        const params_str: [*:0]const u8 = curlx_dyn_ptr(&params_buf) orelse "";
        hda.* = curl_maprintf(
            "Signature-Input: sig1=%s\r\nSignature: sig1=:%s:\r\n",
            params_str,
            sig_b64,
        );
        if (hda.* == null) {
            curlx_dyn_free(&base_buf);
            curlx_dyn_free(&params_buf);
            curlx_free(sig_b64);
            std.crypto.secureZero(u8, &raw_key);
            return CURLE_OUT_OF_MEMORY;
        }
    }

    if (authhost) |ah| {
        ah.setDone(true);
    }

    curlx_dyn_free(&base_buf);
    curlx_dyn_free(&params_buf);
    curlx_free(sig_b64);
    std.crypto.secureZero(u8, &raw_key);
    return CURLE_OK;
}

// ============================================================================
// Unit Tests
// ============================================================================

test "Curl_range parses valid and invalid byte ranges" {
    var resume_from: i64 = 0;
    var maxdownload: i64 = 0;

    try std.testing.expectEqual(CURLE_OK, Curl_range(null, true, "0-499", &resume_from, &maxdownload));
    try std.testing.expectEqual(@as(i64, 0), resume_from);
    try std.testing.expectEqual(@as(i64, 500), maxdownload);

    try std.testing.expectEqual(CURLE_OK, Curl_range(null, true, "100-", &resume_from, &maxdownload));
    try std.testing.expectEqual(@as(i64, 100), resume_from);

    try std.testing.expectEqual(CURLE_OK, Curl_range(null, true, "-250", &resume_from, &maxdownload));
    try std.testing.expectEqual(@as(i64, -250), resume_from);
    try std.testing.expectEqual(@as(i64, 250), maxdownload);

    try std.testing.expectEqual(CURLE_RANGE_ERROR, Curl_range(null, true, "500-100", &resume_from, &maxdownload));
    try std.testing.expectEqual(CURLE_RANGE_ERROR, Curl_range(null, true, "-0", &resume_from, &maxdownload));
    try std.testing.expectEqual(CURLE_RANGE_ERROR, Curl_range(null, true, "100", &resume_from, &maxdownload));

    try std.testing.expectEqual(CURLE_OK, Curl_range(null, false, "0-499", &resume_from, &maxdownload));
    try std.testing.expectEqual(@as(i64, -1), maxdownload);
}

test "Curl_input_digest and Curl_output_digest handle headers and state" {
    var digest_bytes: [128]u8 align(@alignOf(DigestDataPrefix)) = std.mem.zeroes([128]u8);
    const dig: *DigestDataPrefix = @ptrCast(&digest_bytes[0]);
    defer Curl_http_auth_cleanup_digest(null, dig, null);

    try std.testing.expectEqual(CURLE_AUTH_ERROR, Curl_input_digest(null, false, "Basic Zm9vOmJhcg==", dig, null));

    try std.testing.expectEqual(
        CURLE_OK,
        Curl_input_digest(null, false, "Digest realm=\"test\", nonce=\"123456\"", dig, null),
    );
    try std.testing.expect(dig.nonce_or_input_token != null);
}

test "Curl_input_ntlm and Curl_output_ntlm state transitions" {
    var ntlm_bytes: [64]u8 align(8) = std.mem.zeroes([64]u8);
    const ntlm: *NtlmData = @ptrCast(&ntlm_bytes[0]);
    var state: c_uint = NTLMSTATE_NONE;
    var alloc_hdr: ?[*:0]u8 = null;
    defer if (alloc_hdr) |p| curlx_free(p);
    var auth: AuthStruct = .{};
    var picked: u32 = 0;

    try std.testing.expectEqual(CURLE_OK, Curl_input_ntlm(null, false, "NTLM", null, ntlm, &state, null, null));
    try std.testing.expectEqual(NTLMSTATE_TYPE1, state);

    state = NTLMSTATE_TYPE3;
    try std.testing.expectEqual(
        CURLE_OK,
        Curl_output_ntlm(null, false, null, ntlm, "example.com", null, &state, &alloc_hdr, &auth, null, null, null, &picked, null),
    );
    try std.testing.expectEqual(NTLMSTATE_LAST, state);
    try std.testing.expectEqual(CURLAUTH_NTLM, picked);
    try std.testing.expect(auth.getDone());
}

test "Curl_httpchunk_read decodes chunked body and trailers" {
    var ch: Curl_chunker = undefined;
    Curl_httpchunk_init(null, &ch, true, false);
    defer Curl_httpchunk_free(null, &ch);

    var input = "5\r\nhello\r\n0\r\nX-Trailer: val\r\n\r\n".*;
    var consumed: usize = 0;
    try std.testing.expectEqual(CURLE_OK, Curl_httpchunk_read(null, &ch, &input, input.len, &consumed));
    try std.testing.expectEqual(input.len, consumed);
    try std.testing.expect(Curl_httpchunk_is_done(null, &ch));
    try std.testing.expectEqualStrings("OK", std.mem.span(Curl_chunked_strerror(ch.last_code)));
}

test "Curl_output_httpsig generates RFC 9421 HMAC-SHA256 signature headers" {
    var hd_auth: ?[*:0]u8 = null;
    defer if (hd_auth) |p| curlx_free(p);
    var authhost: AuthStruct = .{};

    const hexkey = "000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f";
    const rc = Curl_output_httpsig(
        null,
        CURL_HTTPSIG_HMAC_SHA256,
        hexkey,
        "test-key-1",
        "@method @authority @path",
        "example.com",
        "/hello",
        null,
        null,
        "example.com",
        80,
        80,
        1618884473,
        &hd_auth,
        &authhost,
        "GET",
    );
    try std.testing.expectEqual(CURLE_OK, rc);
    try std.testing.expect(authhost.getDone());
    try std.testing.expect(hd_auth != null);
    const out_str = std.mem.span(hd_auth.?);
    try std.testing.expect(std.mem.indexOf(
        u8,
        out_str,
        "Signature-Input: sig1=(\"@method\" \"@authority\" \"@path\");created=1618884473;keyid=\"test-key-1\";alg=\"hmac-sha256\"\r\n",
    ) != null);
    try std.testing.expect(std.mem.indexOf(u8, out_str, "Signature: sig1=:") != null);
}

test "adversarial chunked transfer-encoding overflow and digest unquoting edge cases" {
    var ch: Curl_chunker = undefined;
    Curl_httpchunk_init(null, &ch, true, false);
    defer Curl_httpchunk_free(null, &ch);

    // 1. Hex size exceeding CHUNK_MAXNUM_LEN (17 hex digits) -> CHUNKE_TOO_LONG_HEX
    var consumed: usize = 0;
    var too_long_hex = "ffffffffffffffffff\r\n".*;
    try std.testing.expectEqual(
        CURLE_RECV_ERROR,
        Curl_httpchunk_read(null, &ch, &too_long_hex, too_long_hex.len, &consumed),
    );
    try std.testing.expectEqual(CHUNKcode.CHUNKE_TOO_LONG_HEX, ch.last_code);

    // 2. 16 hex digits overflowing i64 max (0x8000000000000000) -> CHUNKE_ILLEGAL_HEX
    Curl_httpchunk_reset(null, &ch, true);
    var i64_overflow_hex = "8000000000000000\r\n".*;
    try std.testing.expectEqual(
        CURLE_RECV_ERROR,
        Curl_httpchunk_read(null, &ch, &i64_overflow_hex, i64_overflow_hex.len, &consumed),
    );
    try std.testing.expectEqual(CHUNKcode.CHUNKE_ILLEGAL_HEX, ch.last_code);

    // 3. Valid hex with chunk extension followed by data and bad post-data byte (missing CR/LF)
    Curl_httpchunk_reset(null, &ch, true);
    var bad_ext_term = "4;ext=val\r\nABCDX\n".*;
    try std.testing.expectEqual(
        CURLE_RECV_ERROR,
        Curl_httpchunk_read(null, &ch, &bad_ext_term, bad_ext_term.len, &consumed),
    );
    try std.testing.expectEqual(CHUNKcode.CHUNKE_BAD_CHUNK, ch.last_code);

    // 4. Digest auth header with trailing backslash before NUL and unterminated quotes
    var digest_bytes: [128]u8 align(@alignOf(DigestDataPrefix)) = std.mem.zeroes([128]u8);
    const dig: *DigestDataPrefix = @ptrCast(&digest_bytes[0]);
    defer Curl_http_auth_cleanup_digest(null, dig, null);

    const malformed_digest = "Digest realm=\"test\\";
    try std.testing.expectEqual(CURLE_BAD_CONTENT_ENCODING, Curl_input_digest(null, false, malformed_digest, dig, null));

    const escaped_quote_digest = "Digest realm=\"te\\\"st\", nonce=\"abc\\\\def\", opaque=\"unterminated";
    try std.testing.expectEqual(CURLE_OK, Curl_input_digest(null, false, escaped_quote_digest, dig, null));
    try std.testing.expect(dig.nonce_or_input_token != null);
    try std.testing.expectEqualStrings("abc\\def", std.mem.span(@as([*:0]const u8, @ptrCast(dig.nonce_or_input_token.?))));
}
