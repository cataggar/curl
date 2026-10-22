const std = @import("std");
const builtin = @import("builtin");
const mem = @import("mem.zig");
const primitives_mod = @import("primitives.zig");
const os_leaf_mod = @import("os_leaf.zig");
const containers_mod = @import("containers.zig");
const backend_options = @import("backend_options");

pub const CURLcode = c_uint;
pub const CURLE_OK: CURLcode = 0;
pub const CURLE_UNSUPPORTED_PROTOCOL: CURLcode = 1;
pub const CURLE_FAILED_INIT: CURLcode = 2;
pub const CURLE_URL_MALFORMAT: CURLcode = 3;
pub const CURLE_NOT_BUILT_IN: CURLcode = 4;
pub const CURLE_WEIRD_SERVER_REPLY: CURLcode = 8;
pub const CURLE_REMOTE_ACCESS_DENIED: CURLcode = 9;
pub const CURLE_UPLOAD_FAILED: CURLcode = 25;
pub const CURLE_WRITE_ERROR: CURLcode = 23;
pub const CURLE_OUT_OF_MEMORY: CURLcode = 27;
pub const CURLE_BAD_FUNCTION_ARGUMENT: CURLcode = 43;
pub const CURLE_SEND_ERROR: CURLcode = 55;
pub const CURLE_RECV_ERROR: CURLcode = 56;
pub const CURLE_BAD_CONTENT_ENCODING: CURLcode = 61;
pub const CURLE_LOGIN_DENIED: CURLcode = 67;
pub const CURLE_AGAIN: CURLcode = 81;
pub const CURLE_RTSP_CSEQ_ERROR: CURLcode = 85;
pub const CURLE_RTSP_SESSION_ERROR: CURLcode = 86;
pub const CURLE_FTP_BAD_FILE_LIST: CURLcode = 87;
pub const CURLE_AUTH_ERROR: CURLcode = 94;

pub const curl_off_t = i64;
pub const curl_socket_t = if (builtin.os.tag == .windows) usize else c_int;
pub const FIRSTSOCKET: c_int = 0;

pub const Curl_easy = opaque {};
pub const connectdata = opaque {};
pub const easy_pollset = opaque {};
pub const Curl_multi = opaque {};

pub const bufref = containers_mod.bufref;
pub const dynbuf = containers_mod.dynbuf;
pub const Curl_llist = containers_mod.Curl_llist;
pub const Curl_llist_node = containers_mod.Curl_llist_node;
pub const curl_fileinfo = os_leaf_mod.CurlFileinfo;

pub const fileinfo = extern struct {
    info: curl_fileinfo,
    list: Curl_llist_node,
    buf: dynbuf,
};

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

const primitives = struct {
    pub const curl_strnequal = primitives_mod.curl_strnequal;

    pub inline fn curlx_isupper(c: u8) bool {
        return c >= 'A' and c <= 'Z';
    }
    pub inline fn curlx_isdigit(c: u8) bool {
        return c >= '0' and c <= '9';
    }
    pub inline fn curlx_isalnum(c: u8) bool {
        return (c >= '0' and c <= '9') or (c >= 'A' and c <= 'Z') or (c >= 'a' and c <= 'z');
    }
    pub inline fn curlx_isprint(c: u8) bool {
        return c >= 0x20 and c <= 0x7e;
    }
    pub inline fn curlx_isspace(c: u8) bool {
        return c == ' ' or c == '\t' or (c >= 0x0a and c <= 0x0d);
    }
};

const io_buffers = struct {
    pub extern fn Curl_bufref_init(br: *bufref) callconv(.c) void;
    pub extern fn Curl_bufref_free(br: *bufref) callconv(.c) void;
    pub extern fn Curl_bufref_set(br: *bufref, ptr: ?*const anyopaque, len: usize, dtor: ?containers_mod.BufrefDtor) callconv(.c) void;
    pub extern fn Curl_bufref_uptr(br: *const bufref) callconv(.c) ?[*]const u8;
    pub extern fn Curl_bufref_ptr(br: *const bufref) callconv(.c) ?[*:0]const u8;
    pub extern fn Curl_bufref_len(br: *const bufref) callconv(.c) usize;

    pub const curlx_dyn_init = containers_mod.curlx_dyn_init;
    pub const curlx_dyn_free = containers_mod.curlx_dyn_free;
    pub const curlx_dyn_reset = containers_mod.curlx_dyn_reset;
    pub const curlx_dyn_addn = containers_mod.curlx_dyn_addn;
    pub const curlx_dyn_ptr = containers_mod.curlx_dyn_ptr;
    pub const curlx_dyn_len = containers_mod.curlx_dyn_len;
};

const containers = struct {
    pub const Curl_llist_init = containers_mod.Curl_llist_init;
    pub const Curl_llist_destroy = containers_mod.Curl_llist_destroy;
    pub const Curl_llist_insert_next = containers_mod.Curl_llist_insert_next;

    pub extern fn Curl_fileinfo_alloc() callconv(.c) ?*fileinfo;
    pub extern fn Curl_fileinfo_cleanup(finfo: ?*fileinfo) callconv(.c) void;

    pub inline fn Curl_creds_has_user(c: ?*const Curl_creds) bool {
        const cr = c orelse return false;
        return cr.user[0] != 0;
    }
    pub inline fn Curl_creds_has_passwd(c: ?*const Curl_creds) bool {
        const cr = c orelse return false;
        return cr.passwd[0] != 0;
    }
    pub inline fn Curl_creds_user(c: ?*const Curl_creds) [*:0]const u8 {
        if (c) |cr| return cr.user;
        return "";
    }
    pub inline fn Curl_creds_passwd(c: ?*const Curl_creds) [*:0]const u8 {
        if (c) |cr| return cr.passwd;
        return "";
    }
    pub inline fn Curl_creds_has_sasl_service(c: ?*const Curl_creds) bool {
        const cr = c orelse return false;
        return cr.sasl_service[0] != 0;
    }
    pub inline fn Curl_creds_sasl_service(c: ?*const Curl_creds) [*:0]const u8 {
        if (c) |cr| return cr.sasl_service;
        return "";
    }
    pub inline fn Curl_creds_has_oauth_bearer(c: ?*const Curl_creds) bool {
        const cr = c orelse return false;
        return cr.oauth_bearer[0] != 0;
    }
};

fn memdup0(src: [*]const u8, len: usize) ?[*:0]u8 {
    const total = std.math.add(usize, len, 1) catch return null;
    const dst = mem.malloc(total) orelse return null;
    if (len > 0) {
        @memcpy(dst[0..len], src[0..len]);
    }
    dst[len] = 0;
    return @ptrCast(dst);
}

// ============================================================================
// Sibling Zig module externs (always available in both build and test)
// ============================================================================

extern fn curlx_base64_encode(inputbuff: ?[*]const u8, insize: usize, outptr: *?[*:0]u8, outlen: *usize) callconv(.c) CURLcode;
extern fn curlx_base64_decode(src: [*:0]const u8, outptr: *?[*]u8, outlen: *usize) callconv(.c) CURLcode;

extern fn curl_maprintf(format: [*:0]const u8, ...) callconv(.c) ?[*:0]u8;
extern fn curlx_dyn_addf(dbp: *dynbuf, fmt: [*:0]const u8, ...) callconv(.c) CURLcode;

extern fn curlx_str_passblanks(strp: *?[*:0]const u8) callconv(.c) void;
extern fn curlx_str_number(strp: *?[*:0]const u8, nump: *curl_off_t, max: curl_off_t) callconv(.c) c_int;
extern fn curlx_str_single(strp: *?[*:0]const u8, c: u8) callconv(.c) c_int;

extern fn Curl_fnmatch(ptr: ?*anyopaque, pattern: ?[*:0]const u8, string: ?[*:0]const u8) callconv(.c) c_int;

extern fn Curl_auth_create_plain_message(creds: *Curl_creds, out: *bufref) callconv(.c) CURLcode;
extern fn Curl_auth_create_login_message(value: [*:0]const u8, out: *bufref) callconv(.c) void;
extern fn Curl_auth_create_external_message(user: [*:0]const u8, out: *bufref) callconv(.c) void;
extern fn Curl_auth_create_cram_md5_message(chlg: *const bufref, creds: *Curl_creds, out: *bufref) callconv(.c) CURLcode;
extern fn Curl_auth_create_oauth_bearer_message(creds: *Curl_creds, host: [*:0]const u8, port: c_long, out: *bufref) callconv(.c) CURLcode;
extern fn Curl_auth_create_xoauth_bearer_message(creds: *Curl_creds, out: *bufref) callconv(.c) CURLcode;
extern fn Curl_auth_is_digest_supported() callconv(.c) bool;
extern fn Curl_auth_create_digest_md5_message_host(
    data: ?*Curl_easy,
    hostname: [*:0]const u8,
    chlg: *const bufref,
    creds: *Curl_creds,
    default_service: [*:0]const u8,
    out: *bufref,
) callconv(.c) CURLcode;
extern fn Curl_auth_user_contains_domain(creds: ?*Curl_creds) callconv(.c) bool;

const use_kerberos5 = (builtin.os.tag == .windows and (if (@hasDecl(backend_options, "sspi")) (backend_options.sspi orelse (backend_options.ssl == .schannel)) else (backend_options.ssl == .schannel))) or (if (@hasDecl(backend_options, "gssapi")) backend_options.gssapi else false);

const krb5_ext = struct {
    extern fn Curl_auth_is_gssapi_supported() callconv(.c) bool;
    extern fn Curl_auth_krb5_get(conn: ?*connectdata) callconv(.c) ?*anyopaque;
    extern fn Curl_auth_create_gssapi_user_message(
        data: ?*Curl_easy,
        creds: ?*Curl_creds,
        default_service: ?[*:0]const u8,
        host: ?[*:0]const u8,
        mutual_auth: bool,
        chlg: ?*const bufref,
        krb5: *anyopaque,
        out: *bufref,
    ) callconv(.c) CURLcode;
    extern fn Curl_auth_create_gssapi_security_message(
        data: ?*Curl_easy,
        creds: ?*Curl_creds,
        chlg: *const bufref,
        krb5: *anyopaque,
        out: *bufref,
    ) callconv(.c) CURLcode;
};

// ============================================================================
// External C symbols (guarded by !builtin.is_test)
// ============================================================================

pub const Curl_mapi_guard = extern struct {
    multi: ?*Curl_multi = null,
    depth: u8 = 0,
};

pub const CURL_CBAPI_FN_START: c_uint = 128;
pub const CURL_CBAPI_FN_easy_fnmatch_data: c_uint = CURL_CBAPI_FN_START + 7;
pub const CURL_CBAPI_FN_easy_fwrite_rtp: c_uint = CURL_CBAPI_FN_START + 14;

pub const curl_fnmatch_callback = *const fn (
    ptr: ?*anyopaque,
    pattern: ?[*:0]const u8,
    string: ?[*:0]const u8,
) callconv(.c) c_int;

pub const curl_write_callback = *const fn (
    buffer: [*]u8,
    size: usize,
    nitems: usize,
    outstream: ?*anyopaque,
) callconv(.c) usize;

pub const Curl_meta_dtor = *const fn (
    key: ?*const anyopaque,
    klen: usize,
    entry: ?*anyopaque,
) callconv(.c) void;

const c_ext = struct {
    extern fn Curl_infof(data: ?*Curl_easy, fmt: [*:0]const u8, ...) callconv(.c) void;
    extern fn Curl_failf(data: ?*Curl_easy, fmt: [*:0]const u8, ...) callconv(.c) void;

    extern fn Curl_cbapi_enter(
        guard: *Curl_mapi_guard,
        easy: ?*Curl_easy,
        multi: ?*Curl_multi,
        fn_id: c_uint,
    ) callconv(.c) void;
    extern fn Curl_cbapi_leave(guard: *Curl_mapi_guard) callconv(.c) void;

    // FTP list parser C helper (in lib/http.c)
    extern fn Curl_ftp_parselist_get_easy(
        data: ?*Curl_easy,
        pwc: *?*WildcardData,
        pfnmatch: *?curl_fnmatch_callback,
        pfnmatch_data: *?*anyopaque,
    ) callconv(.c) void;

    // RTSP / HTTP / transfer C helpers
    extern fn Curl_pollset_change(
        data: ?*Curl_easy,
        ps: ?*easy_pollset,
        sock: curl_socket_t,
        add_flags: c_int,
        remove_flags: c_int,
    ) callconv(.c) CURLcode;
    extern fn Curl_conn_meta_set(conn: ?*connectdata, key: [*:0]const u8, entry: ?*anyopaque, dtor: Curl_meta_dtor) callconv(.c) CURLcode;
    extern fn Curl_conn_meta_get(conn: ?*connectdata, key: [*:0]const u8) callconv(.c) ?*anyopaque;
    extern fn Curl_meta_set(data: ?*Curl_easy, key: [*:0]const u8, entry: ?*anyopaque, dtor: Curl_meta_dtor) callconv(.c) CURLcode;
    extern fn Curl_meta_get(data: ?*Curl_easy, key: [*:0]const u8) callconv(.c) ?*anyopaque;
    extern fn Curl_conn_is_alive(data: ?*Curl_easy, conn: ?*connectdata, input_pending: *bool) callconv(.c) bool;
    extern fn Curl_http_done(data: ?*Curl_easy, status: CURLcode, premature: bool) callconv(.c) CURLcode;
    extern fn Curl_http_perform_pollset(data: ?*Curl_easy, ps: ?*easy_pollset) callconv(.c) CURLcode;
    extern fn Curl_http_follow(data: ?*Curl_easy, newurl: ?[*:0]u8, follow: c_uint) callconv(.c) CURLcode;
    extern fn Curl_creader_set_fread(data: ?*Curl_easy, len: curl_off_t) callconv(.c) CURLcode;
    extern fn Curl_creader_set_buf(data: ?*Curl_easy, buf: [*]const u8, blen: usize) callconv(.c) CURLcode;
    extern fn Curl_creader_set_null(data: ?*Curl_easy) callconv(.c) CURLcode;
    extern fn Curl_checkheaders(data: ?*Curl_easy, thisheader: [*]const u8, thislen: usize) callconv(.c) ?[*:0]u8;
    extern fn Curl_http_output_auth(
        data: ?*Curl_easy,
        conn: ?*connectdata,
        request: [*:0]const u8,
        httpreq: u8,
        path: [*:0]const u8,
        query: ?[*:0]const u8,
        proxytunnel: bool,
    ) callconv(.c) CURLcode;
    extern fn Curl_xfer_setup_recv(
        data: ?*Curl_easy,
        sockindex: i8,
        recv_size: curl_off_t,
    ) callconv(.c) void;
    extern fn Curl_xfer_setup_sendrecv(
        data: ?*Curl_easy,
        sockindex: i8,
        recv_size: curl_off_t,
    ) callconv(.c) void;
    extern fn Curl_add_timecondition(data: ?*Curl_easy, req: *dynbuf) callconv(.c) CURLcode;
    extern fn Curl_add_custom_headers(data: ?*Curl_easy, is_connect: bool, httpversion: c_int, req: *dynbuf) callconv(.c) CURLcode;
    extern fn Curl_req_send(data: ?*Curl_easy, req: *dynbuf, httpversion: u8) callconv(.c) CURLcode;
    extern fn Curl_pgrsSetUploadCounter(data: ?*Curl_easy, size: curl_off_t) callconv(.c) void;
    extern fn Curl_pgrsUpdate(data: ?*Curl_easy) callconv(.c) CURLcode;
    extern fn Curl_client_write(data: ?*Curl_easy, type_flags: c_int, buf: ?[*]const u8, blen: usize) callconv(.c) CURLcode;
    extern fn Curl_http_write_resp_hds(data: ?*Curl_easy, buf: [*]const u8, blen: usize, pconsumed: *usize) callconv(.c) CURLcode;

    // RTSP field accessors in lib/http.c
    extern fn Curl_rtsp_get_conn(data: ?*Curl_easy) callconv(.c) ?*connectdata;
    extern fn Curl_rtsp_get_firstsocket(data: ?*Curl_easy) callconv(.c) curl_socket_t;
    extern fn Curl_rtsp_init_cseq(data: ?*Curl_easy) callconv(.c) void;
    extern fn Curl_rtsp_get_next_client_cseq(data: ?*Curl_easy) callconv(.c) u32;
    extern fn Curl_rtsp_inc_next_client_cseq(data: ?*Curl_easy) callconv(.c) void;
    extern fn Curl_rtsp_set_cseq_recv(data: ?*Curl_easy, cseq: u32) callconv(.c) void;
    extern fn Curl_rtsp_get_rtspreq(data: ?*Curl_easy) callconv(.c) u8;
    extern fn Curl_rtsp_get_eos_written(data: ?*Curl_easy) callconv(.c) bool;
    extern fn Curl_rtsp_set_no_body(data: ?*Curl_easy, no_body: bool) callconv(.c) void;
    extern fn Curl_rtsp_set_httpreq(data: ?*Curl_easy, httpreq: u8) callconv(.c) void;
    extern fn Curl_rtsp_get_body_info(
        data: ?*Curl_easy,
        pupload: *bool,
        pinfilesize: *curl_off_t,
        ppostfields: *?[*]const u8,
        ppostfieldsize: *curl_off_t,
        pcrlf: *bool,
    ) callconv(.c) void;
    extern fn Curl_rtsp_get_request_info(
        data: ?*Curl_easy,
        psession_id: *?[*:0]const u8,
        pstream_uri: *?[*:0]const u8,
        ptransport: *?[*:0]const u8,
        pencoding: *?[*:0]const u8,
        puseragent: *?[*:0]const u8,
        preferer: *?[*:0]const u8,
        puse_range: *bool,
        prange: *?[*:0]const u8,
        prangeline: **?[*:0]u8,
    ) callconv(.c) void;
    extern fn Curl_rtsp_get_auth_headers(
        data: ?*Curl_easy,
        phd_proxy_auth: *?[*:0]const u8,
        phd_auth: *?[*:0]const u8,
    ) callconv(.c) void;
    extern fn Curl_rtsp_allow_session_to_host(data: ?*Curl_easy) callconv(.c) bool;
    extern fn Curl_rtsp_get_writebytecount(data: ?*Curl_easy) callconv(.c) curl_off_t;
    extern fn Curl_rtsp_get_req_state(
        data: ?*Curl_easy,
        pheaderline: *c_int,
        pheader: *bool,
        psize: *curl_off_t,
        pbytecount: *curl_off_t,
        pdone: *bool,
    ) callconv(.c) void;
    extern fn Curl_rtsp_set_req_size_zero_done(data: ?*Curl_easy) callconv(.c) void;
    extern fn Curl_rtsp_set_download_done(data: ?*Curl_easy) callconv(.c) void;
    extern fn Curl_rtsp_set_req_done_false(data: ?*Curl_easy) callconv(.c) void;
    extern fn Curl_rtsp_get_rtp_writer(
        data: ?*Curl_easy,
        pwriteit: *?curl_write_callback,
        puser_ptr: *?*anyopaque,
    ) callconv(.c) void;
    extern fn Curl_rtsp_get_rtp_channel_mask(data: ?*Curl_easy) callconv(.c) [*]u8;
    extern fn Curl_rtsp_get_session_id(data: ?*Curl_easy) callconv(.c) ?[*:0]const u8;
    extern fn Curl_rtsp_set_session_id(data: ?*Curl_easy, mem_ptr: [*:0]u8) callconv(.c) CURLcode;
};

fn infof0(data: ?*Curl_easy, msg: [*:0]const u8) void {
    if (!builtin.is_test and data != null) {
        c_ext.Curl_infof(data, "%s", msg);
    }
}

fn failf0(data: ?*Curl_easy, msg: [*:0]const u8) void {
    if (!builtin.is_test and data != null) {
        c_ext.Curl_failf(data, "%s", msg);
    }
}

// ============================================================================
// 1. lib/curl_sasl.c — SASL Authentication State Machine
// ============================================================================

pub const SASL_MECH_LOGIN: c_ushort = 1 << 0;
pub const SASL_MECH_PLAIN: c_ushort = 1 << 1;
pub const SASL_MECH_CRAM_MD5: c_ushort = 1 << 2;
pub const SASL_MECH_DIGEST_MD5: c_ushort = 1 << 3;
pub const SASL_MECH_GSSAPI: c_ushort = 1 << 4;
pub const SASL_MECH_EXTERNAL: c_ushort = 1 << 5;
pub const SASL_MECH_NTLM: c_ushort = 1 << 6;
pub const SASL_MECH_XOAUTH2: c_ushort = 1 << 7;
pub const SASL_MECH_OAUTHBEARER: c_ushort = 1 << 8;
pub const SASL_MECH_SCRAM_SHA_1: c_ushort = 1 << 9;
pub const SASL_MECH_SCRAM_SHA_256: c_ushort = 1 << 10;

pub const SASL_AUTH_NONE: c_ushort = 0;
pub const SASL_AUTH_ANY: c_ushort = 0xffff;
pub const SASL_AUTH_DEFAULT: c_ushort = SASL_AUTH_ANY & ~SASL_MECH_EXTERNAL;

pub const SASL_MECH_STRING_LOGIN: [*:0]const u8 = "LOGIN";
pub const SASL_MECH_STRING_PLAIN: [*:0]const u8 = "PLAIN";
pub const SASL_MECH_STRING_CRAM_MD5: [*:0]const u8 = "CRAM-MD5";
pub const SASL_MECH_STRING_DIGEST_MD5: [*:0]const u8 = "DIGEST-MD5";
pub const SASL_MECH_STRING_GSSAPI: [*:0]const u8 = "GSSAPI";
pub const SASL_MECH_STRING_EXTERNAL: [*:0]const u8 = "EXTERNAL";
pub const SASL_MECH_STRING_NTLM: [*:0]const u8 = "NTLM";
pub const SASL_MECH_STRING_XOAUTH2: [*:0]const u8 = "XOAUTH2";
pub const SASL_MECH_STRING_OAUTHBEARER: [*:0]const u8 = "OAUTHBEARER";
pub const SASL_MECH_STRING_SCRAM_SHA_1: [*:0]const u8 = "SCRAM-SHA-1";
pub const SASL_MECH_STRING_SCRAM_SHA_256: [*:0]const u8 = "SCRAM-SHA-256";

pub const SASL_FLAG_BASE64: c_ushort = 0x0001;

pub const saslstate = c_uint;
pub const SASL_STOP: saslstate = 0;
pub const SASL_PLAIN: saslstate = 1;
pub const SASL_LOGIN: saslstate = 2;
pub const SASL_LOGIN_PASSWD: saslstate = 3;
pub const SASL_EXTERNAL: saslstate = 4;
pub const SASL_CRAMMD5: saslstate = 5;
pub const SASL_DIGESTMD5: saslstate = 6;
pub const SASL_DIGESTMD5_RESP: saslstate = 7;
pub const SASL_NTLM: saslstate = 8;
pub const SASL_NTLM_TYPE2MSG: saslstate = 9;
pub const SASL_GSSAPI: saslstate = 10;
pub const SASL_GSSAPI_TOKEN: saslstate = 11;
pub const SASL_GSSAPI_NO_DATA: saslstate = 12;
pub const SASL_OAUTH2: saslstate = 13;
pub const SASL_OAUTH2_RESP: saslstate = 14;
pub const SASL_GSASL: saslstate = 15;
pub const SASL_CANCEL: saslstate = 16;
pub const SASL_FINAL: saslstate = 17;

pub const saslprogress = c_uint;
pub const SASL_IDLE: saslprogress = 0;
pub const SASL_INPROGRESS: saslprogress = 1;
pub const SASL_DONE: saslprogress = 2;

pub const CURLAUTH_NONE: u32 = 0;
pub const CURLAUTH_BASIC: u32 = 1 << 0;
pub const CURLAUTH_DIGEST: u32 = 1 << 1;
pub const CURLAUTH_NEGOTIATE: u32 = 1 << 2;
pub const CURLAUTH_NTLM: u32 = 1 << 3;
pub const CURLAUTH_BEARER: u32 = 1 << 6;

pub const SASLproto = extern struct {
    service: ?[*:0]const u8 = null,
    sendauth: ?*const fn (data: ?*Curl_easy, mech: [*:0]const u8, ir: *const bufref) callconv(.c) CURLcode = null,
    contauth: ?*const fn (data: ?*Curl_easy, mech: [*:0]const u8, contauth: *const bufref) callconv(.c) CURLcode = null,
    cancelauth: ?*const fn (data: ?*Curl_easy, mech: [*:0]const u8) callconv(.c) CURLcode = null,
    getmessage: ?*const fn (data: ?*Curl_easy, out: *bufref) callconv(.c) CURLcode = null,
    maxirlen: usize = 0,
    contcode: c_int = 0,
    finalcode: c_int = 0,
    defmechs: c_ushort = 0,
    flags: c_ushort = 0,
};

// Bitfields in struct SASL:
// bit 0: resetprefs
// bit 1: mutual_auth
// bit 2: force_ir
// On SysV x86_64 (Linux), the 3 bits pack into the 2-byte hole at offset 30 (sizeof == 32).
// On MS ABI x86_64 (Windows), unsigned int bitfield starts a new 4-byte unit at offset 32 (sizeof == 40).
const SASL_BIT_RESETPREFS: u16 = 1 << 0;
const SASL_BIT_MUTUAL_AUTH: u16 = 1 << 1;
const SASL_BIT_FORCE_IR: u16 = 1 << 2;

pub const SASL = if (builtin.os.tag == .windows) extern struct {
    params: ?*const SASLproto = null,
    state: saslstate = SASL_STOP,
    curmech: ?[*:0]const u8 = null,
    authmechs: c_ushort = SASL_AUTH_NONE,
    prefmech: c_ushort = SASL_AUTH_NONE,
    authused: c_ushort = SASL_AUTH_NONE,
    flags: c_uint = 0,
} else extern struct {
    params: ?*const SASLproto = null,
    state: saslstate = SASL_STOP,
    curmech: ?[*:0]const u8 = null,
    authmechs: c_ushort = SASL_AUTH_NONE,
    prefmech: c_ushort = SASL_AUTH_NONE,
    authused: c_ushort = SASL_AUTH_NONE,
    flags: u16 = 0,
};

fn saslGetResetPrefs(sasl: *const SASL) bool {
    return (sasl.flags & SASL_BIT_RESETPREFS) != 0;
}

fn saslSetResetPrefs(sasl: *SASL, val: bool) void {
    if (val) {
        sasl.flags |= SASL_BIT_RESETPREFS;
    } else {
        sasl.flags &= ~@as(@TypeOf(sasl.flags), SASL_BIT_RESETPREFS);
    }
}

fn saslGetMutualAuth(sasl: *const SASL) bool {
    return (sasl.flags & SASL_BIT_MUTUAL_AUTH) != 0;
}

fn saslSetMutualAuth(sasl: *SASL, val: bool) void {
    if (val) {
        sasl.flags |= SASL_BIT_MUTUAL_AUTH;
    } else {
        sasl.flags &= ~@as(@TypeOf(sasl.flags), SASL_BIT_MUTUAL_AUTH);
    }
}

fn saslGetForceIr(sasl: *const SASL) bool {
    return (sasl.flags & SASL_BIT_FORCE_IR) != 0;
}

fn saslSetForceIr(sasl: *SASL, val: bool) void {
    if (val) {
        sasl.flags |= SASL_BIT_FORCE_IR;
    } else {
        sasl.flags &= ~@as(@TypeOf(sasl.flags), SASL_BIT_FORCE_IR);
    }
}

const MechEntry = struct {
    name: [:0]const u8,
    bit: c_ushort,
};

const mechtable = [_]MechEntry{
    .{ .name = "LOGIN", .bit = SASL_MECH_LOGIN },
    .{ .name = "PLAIN", .bit = SASL_MECH_PLAIN },
    .{ .name = "CRAM-MD5", .bit = SASL_MECH_CRAM_MD5 },
    .{ .name = "DIGEST-MD5", .bit = SASL_MECH_DIGEST_MD5 },
    .{ .name = "GSSAPI", .bit = SASL_MECH_GSSAPI },
    .{ .name = "EXTERNAL", .bit = SASL_MECH_EXTERNAL },
    .{ .name = "NTLM", .bit = SASL_MECH_NTLM },
    .{ .name = "XOAUTH2", .bit = SASL_MECH_XOAUTH2 },
    .{ .name = "OAUTHBEARER", .bit = SASL_MECH_OAUTHBEARER },
    .{ .name = "SCRAM-SHA-1", .bit = SASL_MECH_SCRAM_SHA_1 },
    .{ .name = "SCRAM-SHA-256", .bit = SASL_MECH_SCRAM_SHA_256 },
};

pub export fn Curl_sasl_cleanup(conn: ?*connectdata, authused: c_ushort) callconv(.c) void {
    _ = conn;
    _ = authused;
}

pub export fn Curl_sasl_decode_mech(
    ptr: [*:0]const u8,
    maxlen: usize,
    len: ?*usize,
) callconv(.c) c_ushort {
    for (mechtable) |entry| {
        const l = entry.name.len;
        if (maxlen >= l and primitives.curl_strnequal(ptr, entry.name.ptr, l) != 0) {
            if (len) |out_len| {
                out_len.* = l;
            }
            if (maxlen == l) {
                return entry.bit;
            }
            const c = ptr[l];
            if (!primitives.curlx_isupper(c) and !primitives.curlx_isdigit(c) and c != '-' and c != '_') {
                return entry.bit;
            }
        }
    }
    return 0;
}

pub export fn Curl_sasl_parse_url_auth_option(
    sasl: *SASL,
    value: [*:0]const u8,
    len: usize,
) callconv(.c) CURLcode {
    var mechlen: usize = 0;

    if (len == 0)
        return CURLE_URL_MALFORMAT;

    if (saslGetResetPrefs(sasl)) {
        saslSetResetPrefs(sasl, false);
        sasl.prefmech = SASL_AUTH_NONE;
    }

    if (std.mem.eql(u8, value[0..len], "*"[0..@min(len, 1)])) {
        sasl.prefmech = SASL_AUTH_DEFAULT;
        return CURLE_OK;
    }

    const mechbit = Curl_sasl_decode_mech(value, len, &mechlen);
    if (mechbit != 0 and mechlen == len) {
        sasl.prefmech |= mechbit;
        return CURLE_OK;
    }

    return CURLE_URL_MALFORMAT;
}

pub export fn Curl_sasl_init_zig(
    sasl: *SASL,
    data: ?*Curl_easy,
    params: *const SASLproto,
    httpauth: u32,
) callconv(.c) void {
    _ = data;
    sasl.params = params;
    sasl.state = SASL_STOP;
    sasl.curmech = null;
    sasl.authmechs = SASL_AUTH_NONE;
    sasl.prefmech = params.defmechs;
    sasl.authused = SASL_AUTH_NONE;
    saslSetResetPrefs(sasl, true);
    saslSetMutualAuth(sasl, false);
    saslSetForceIr(sasl, false);

    if (httpauth != CURLAUTH_BASIC) {
        var mechs: c_ushort = SASL_AUTH_NONE;
        if ((httpauth & CURLAUTH_BASIC) != 0)
            mechs |= SASL_MECH_PLAIN | SASL_MECH_LOGIN;
        if ((httpauth & CURLAUTH_DIGEST) != 0)
            mechs |= SASL_MECH_DIGEST_MD5;
        if ((httpauth & CURLAUTH_NTLM) != 0)
            mechs |= SASL_MECH_NTLM;
        if ((httpauth & CURLAUTH_BEARER) != 0)
            mechs |= SASL_MECH_OAUTHBEARER | SASL_MECH_XOAUTH2;
        if ((httpauth & CURLAUTH_NEGOTIATE) != 0)
            mechs |= SASL_MECH_GSSAPI;
        if (mechs != SASL_AUTH_NONE)
            sasl.prefmech = mechs;
    }
}

const sasl_state_names = [_][*:0]const u8{
    "STOP",
    "PLAIN",
    "LOGIN",
    "LOGIN_PASSWD",
    "EXTERNAL",
    "CRAMMD5",
    "DIGESTMD5",
    "DIGESTMD5_RESP",
    "NTLM",
    "NTLM_TYPE2MSG",
    "GSSAPI",
    "GSSAPI_TOKEN",
    "GSSAPI_NO_DATA",
    "OAUTH2",
    "OAUTH2_RESP",
    "GSASL",
    "CANCEL",
    "FINAL",
};

fn saslState(sasl: *SASL, data: ?*Curl_easy, newstate: saslstate) void {
    if (sasl.state != newstate) {
        if (!builtin.is_test and data != null) {
            const old_name = if (sasl.state < sasl_state_names.len) sasl_state_names[sasl.state] else "?";
            const new_name = if (newstate < sasl_state_names.len) sasl_state_names[newstate] else "?";
            c_ext.Curl_infof(data, "[SASL] %p state %s -> %s", sasl, old_name, new_name);
        }
    }
    sasl.state = newstate;
}

fn freeBufrefMem(ptr: ?*anyopaque) callconv(.c) void {
    mem.free(ptr);
}

fn getServerMessage(sasl: *SASL, data: ?*Curl_easy, out: *bufref) CURLcode {
    const params = sasl.params orelse return CURLE_FAILED_INIT;
    const getmsg = params.getmessage orelse return CURLE_FAILED_INIT;
    var result = getmsg(data, out);
    if (result == CURLE_OK and (params.flags & SASL_FLAG_BASE64) != 0) {
        var msg: ?[*]u8 = null;
        var msglen: usize = 0;
        const serverdata = io_buffers.Curl_bufref_ptr(out) orelse "";
        if (serverdata[0] == 0) {
            io_buffers.Curl_bufref_set(out, null, 0, null);
        } else {
            result = curlx_base64_decode(serverdata, &msg, &msglen);
            if (result == CURLE_OK) {
                io_buffers.Curl_bufref_set(out, msg, msglen, &freeBufrefMem);
            }
        }
    }
    return result;
}

fn buildMessage(sasl: *SASL, msg: *bufref) CURLcode {
    var result: CURLcode = CURLE_OK;
    const params = sasl.params orelse return CURLE_FAILED_INIT;
    if ((params.flags & SASL_FLAG_BASE64) != 0) {
        var base64: ?[*:0]u8 = null;
        var base64len: usize = 0;
        if (io_buffers.Curl_bufref_ptr(msg) == null) {
            io_buffers.Curl_bufref_set(msg, "", 0, null);
        } else if (io_buffers.Curl_bufref_len(msg) != 0) {
            result = curlx_base64_encode(
                io_buffers.Curl_bufref_uptr(msg),
                io_buffers.Curl_bufref_len(msg),
                &base64,
                &base64len,
            );
            if (result == CURLE_OK) {
                io_buffers.Curl_bufref_set(msg, base64, base64len, &freeBufrefMem);
            }
        }
    }
    return result;
}

pub export fn Curl_sasl_can_authenticate_zig(
    sasl: *SASL,
    data: ?*Curl_easy,
    conn_creds: ?*Curl_creds,
) callconv(.c) bool {
    _ = data;
    if (containers.Curl_creds_has_user(conn_creds))
        return true;
    if ((sasl.authmechs & sasl.prefmech & SASL_MECH_EXTERNAL) != 0)
        return true;
    return false;
}

const SaslStartCtx = struct {
    sasl: *SASL,
    conn: ?*connectdata,
    conn_creds: ?*Curl_creds,
    state_creds: ?*Curl_creds,
    conn_hostname: [*:0]const u8,
    conn_port: c_int,
    sasl_ir: bool,
    enabledmechs: c_ushort,
    mech: ?[*:0]const u8 = null,
    resp: bufref = undefined,
    state1: saslstate = SASL_STOP,
    state2: saslstate = SASL_FINAL,
    result: CURLcode = CURLE_OK,
};

fn saslChooseExternal(sctx: *SaslStartCtx) bool {
    if ((sctx.enabledmechs & SASL_MECH_EXTERNAL) != 0 and
        !containers.Curl_creds_has_passwd(sctx.conn_creds))
    {
        sctx.mech = SASL_MECH_STRING_EXTERNAL;
        sctx.state1 = SASL_EXTERNAL;
        sctx.sasl.authused = SASL_MECH_EXTERNAL;

        if (saslGetForceIr(sctx.sasl) or sctx.sasl_ir) {
            Curl_auth_create_external_message(
                containers.Curl_creds_user(sctx.conn_creds),
                &sctx.resp,
            );
        }
        return true;
    }
    return false;
}

fn saslChooseGssapi(data: ?*Curl_easy, sctx: *SaslStartCtx) bool {
    if (use_kerberos5) {
        if ((sctx.enabledmechs & SASL_MECH_GSSAPI) != 0 and
            krb5_ext.Curl_auth_is_gssapi_supported() and
            Curl_auth_user_contains_domain(sctx.conn_creds))
        {
            const params = sctx.sasl.params.?;
            const service: ?[*:0]const u8 = if (containers.Curl_creds_has_sasl_service(sctx.conn_creds))
                containers.Curl_creds_sasl_service(sctx.conn_creds)
            else
                params.service;
            const krb5 = krb5_ext.Curl_auth_krb5_get(sctx.conn);
            saslSetMutualAuth(sctx.sasl, false);
            sctx.mech = SASL_MECH_STRING_GSSAPI;
            sctx.state1 = SASL_GSSAPI;
            sctx.state2 = SASL_GSSAPI_TOKEN;
            sctx.sasl.authused = SASL_MECH_GSSAPI;

            if (krb5 == null) {
                sctx.result = CURLE_OUT_OF_MEMORY;
            } else if (saslGetForceIr(sctx.sasl) or sctx.sasl_ir) {
                sctx.result = krb5_ext.Curl_auth_create_gssapi_user_message(
                    data,
                    sctx.conn_creds,
                    service,
                    sctx.conn_hostname,
                    saslGetMutualAuth(sctx.sasl),
                    null,
                    krb5.?,
                    &sctx.resp,
                );
            }
            return true;
        }
    }
    return false;
}

fn saslChooseDigestMd5(sctx: *SaslStartCtx) bool {
    if ((sctx.enabledmechs & SASL_MECH_DIGEST_MD5) != 0 and
        Curl_auth_is_digest_supported())
    {
        sctx.mech = SASL_MECH_STRING_DIGEST_MD5;
        sctx.state1 = SASL_DIGESTMD5;
        sctx.sasl.authused = SASL_MECH_DIGEST_MD5;
        return true;
    }
    return false;
}

fn saslChooseCramMd5(sctx: *SaslStartCtx) bool {
    if ((sctx.enabledmechs & SASL_MECH_CRAM_MD5) != 0) {
        sctx.mech = SASL_MECH_STRING_CRAM_MD5;
        sctx.state1 = SASL_CRAMMD5;
        sctx.sasl.authused = SASL_MECH_CRAM_MD5;
        return true;
    }
    return false;
}

fn saslChooseOauth(sctx: *SaslStartCtx) bool {
    if (!containers.Curl_creds_has_oauth_bearer(sctx.state_creds))
        return false;

    if ((sctx.enabledmechs & SASL_MECH_OAUTHBEARER) != 0) {
        sctx.mech = SASL_MECH_STRING_OAUTHBEARER;
        sctx.state1 = SASL_OAUTH2;
        sctx.state2 = SASL_OAUTH2_RESP;
        sctx.sasl.authused = SASL_MECH_OAUTHBEARER;

        if (saslGetForceIr(sctx.sasl) or sctx.sasl_ir) {
            sctx.result = Curl_auth_create_oauth_bearer_message(
                sctx.conn_creds.?,
                sctx.conn_hostname,
                @intCast(sctx.conn_port),
                &sctx.resp,
            );
        }
        return true;
    }

    if ((sctx.enabledmechs & SASL_MECH_XOAUTH2) != 0) {
        sctx.mech = SASL_MECH_STRING_XOAUTH2;
        sctx.state1 = SASL_OAUTH2;
        sctx.sasl.authused = SASL_MECH_XOAUTH2;

        if (saslGetForceIr(sctx.sasl) or sctx.sasl_ir) {
            sctx.result = Curl_auth_create_xoauth_bearer_message(
                sctx.conn_creds.?,
                &sctx.resp,
            );
        }
        return true;
    }
    return false;
}

fn saslChoosePlain(sctx: *SaslStartCtx) bool {
    if ((sctx.enabledmechs & SASL_MECH_PLAIN) != 0) {
        sctx.mech = SASL_MECH_STRING_PLAIN;
        sctx.state1 = SASL_PLAIN;
        sctx.sasl.authused = SASL_MECH_PLAIN;

        if (saslGetForceIr(sctx.sasl) or sctx.sasl_ir) {
            sctx.result = Curl_auth_create_plain_message(
                sctx.conn_creds.?,
                &sctx.resp,
            );
        }
        return true;
    }
    return false;
}

fn saslChooseLogin(sctx: *SaslStartCtx) bool {
    if ((sctx.enabledmechs & SASL_MECH_LOGIN) != 0) {
        sctx.mech = SASL_MECH_STRING_LOGIN;
        sctx.state1 = SASL_LOGIN;
        sctx.state2 = SASL_LOGIN_PASSWD;
        sctx.sasl.authused = SASL_MECH_LOGIN;

        if (saslGetForceIr(sctx.sasl) or sctx.sasl_ir) {
            Curl_auth_create_login_message(
                containers.Curl_creds_user(sctx.conn_creds),
                &sctx.resp,
            );
        }
        return true;
    }
    return false;
}

pub export fn Curl_sasl_start_zig(
    sasl: *SASL,
    data: ?*Curl_easy,
    force_ir: bool,
    progress: *saslprogress,
    conn: ?*connectdata,
    conn_creds: ?*Curl_creds,
    state_creds: ?*Curl_creds,
    conn_hostname: ?[*:0]const u8,
    conn_port: c_int,
    sasl_ir: bool,
) callconv(.c) CURLcode {
    var sctx = SaslStartCtx{
        .sasl = sasl,
        .conn = conn,
        .conn_creds = conn_creds,
        .state_creds = state_creds,
        .conn_hostname = conn_hostname orelse "",
        .conn_port = conn_port,
        .sasl_ir = sasl_ir,
        .enabledmechs = sasl.authmechs & sasl.prefmech,
    };

    saslSetForceIr(sasl, force_ir);
    sasl.authused = 0;
    progress.* = SASL_IDLE;

    io_buffers.Curl_bufref_init(&sctx.resp);

    if (!saslChooseExternal(&sctx) and
        containers.Curl_creds_has_user(conn_creds))
    {
        if (!saslChooseGssapi(data, &sctx) and
            !saslChooseDigestMd5(&sctx) and
            !saslChooseCramMd5(&sctx) and
            !saslChooseOauth(&sctx) and
            !saslChoosePlain(&sctx))
        {
            _ = saslChooseLogin(&sctx);
        }
    }

    if (sctx.result == CURLE_OK and sctx.mech != null) {
        const mech = sctx.mech.?;
        const params = sasl.params.?;
        sasl.curmech = mech;
        if (io_buffers.Curl_bufref_ptr(&sctx.resp) != null) {
            sctx.result = buildMessage(sasl, &sctx.resp);
        }

        if (params.maxirlen != 0 and
            std.mem.len(mech) + io_buffers.Curl_bufref_len(&sctx.resp) > params.maxirlen)
        {
            io_buffers.Curl_bufref_free(&sctx.resp);
        }

        if (sctx.result == CURLE_OK) {
            if (params.sendauth) |sendauth_fn| {
                sctx.result = sendauth_fn(data, mech, &sctx.resp);
            }
            if (sctx.result == CURLE_OK) {
                progress.* = SASL_INPROGRESS;
                saslState(sasl, data, if (io_buffers.Curl_bufref_ptr(&sctx.resp) != null) sctx.state2 else sctx.state1);
            }
        }
    }

    io_buffers.Curl_bufref_free(&sctx.resp);
    return sctx.result;
}

pub export fn Curl_sasl_continue_zig(
    sasl: *SASL,
    data: ?*Curl_easy,
    code: c_int,
    progress: *saslprogress,
    conn: ?*connectdata,
    conn_creds: ?*Curl_creds,
    state_creds: ?*Curl_creds,
    conn_hostname_opt: ?[*:0]const u8,
    conn_port: c_int,
    origin_hostname_opt: ?[*:0]const u8,
    sasl_ir: bool,
) callconv(.c) CURLcode {
    var result: CURLcode = CURLE_OK;
    var newstate: saslstate = SASL_FINAL;
    var resp: bufref = undefined;
    var serverdata: bufref = undefined;
    const params = sasl.params orelse return CURLE_FAILED_INIT;
    const conn_hostname: [*:0]const u8 = conn_hostname_opt orelse "";
    const origin_hostname: [*:0]const u8 = origin_hostname_opt orelse conn_hostname;

    io_buffers.Curl_bufref_init(&resp);
    io_buffers.Curl_bufref_init(&serverdata);

    progress.* = SASL_INPROGRESS;

    if (sasl.state == SASL_FINAL) {
        if (code != params.finalcode)
            result = CURLE_LOGIN_DENIED;
        progress.* = SASL_DONE;
        saslState(sasl, data, SASL_STOP);
        return result;
    }

    if (sasl.state != SASL_CANCEL and sasl.state != SASL_OAUTH2_RESP and
        code != params.contcode)
    {
        progress.* = SASL_DONE;
        saslState(sasl, data, SASL_STOP);
        return CURLE_LOGIN_DENIED;
    }

    switch (sasl.state) {
        SASL_STOP => {
            progress.* = SASL_DONE;
            return result;
        },
        SASL_PLAIN => {
            if (conn_creds) |creds| {
                result = Curl_auth_create_plain_message(creds, &resp);
            } else {
                result = CURLE_LOGIN_DENIED;
            }
        },
        SASL_LOGIN => {
            Curl_auth_create_login_message(containers.Curl_creds_user(conn_creds), &resp);
            newstate = SASL_LOGIN_PASSWD;
        },
        SASL_LOGIN_PASSWD => {
            Curl_auth_create_login_message(containers.Curl_creds_passwd(conn_creds), &resp);
        },
        SASL_EXTERNAL => {
            Curl_auth_create_external_message(containers.Curl_creds_user(conn_creds), &resp);
        },
        SASL_CRAMMD5 => {
            result = getServerMessage(sasl, data, &serverdata);
            if (result == CURLE_OK) {
                if (conn_creds) |creds| {
                    result = Curl_auth_create_cram_md5_message(&serverdata, creds, &resp);
                } else {
                    result = CURLE_LOGIN_DENIED;
                }
            }
        },
        SASL_DIGESTMD5 => {
            result = getServerMessage(sasl, data, &serverdata);
            if (result == CURLE_OK) {
                if (conn_creds) |creds| {
                    result = Curl_auth_create_digest_md5_message_host(
                        data,
                        origin_hostname,
                        &serverdata,
                        creds,
                        params.service orelse "",
                        &resp,
                    );
                } else {
                    result = CURLE_LOGIN_DENIED;
                }
                if (result == CURLE_OK and (params.flags & SASL_FLAG_BASE64) != 0) {
                    newstate = SASL_DIGESTMD5_RESP;
                }
            }
        },
        SASL_DIGESTMD5_RESP => {
            io_buffers.Curl_bufref_set(&resp, "", 0, null);
        },
        SASL_GSSAPI => {
            if (use_kerberos5) {
                const service: ?[*:0]const u8 = if (containers.Curl_creds_has_sasl_service(conn_creds))
                    containers.Curl_creds_sasl_service(conn_creds)
                else
                    params.service;
                const krb5 = krb5_ext.Curl_auth_krb5_get(conn);
                if (krb5 == null) {
                    result = CURLE_OUT_OF_MEMORY;
                } else {
                    result = krb5_ext.Curl_auth_create_gssapi_user_message(
                        data,
                        conn_creds,
                        service,
                        conn_hostname,
                        saslGetMutualAuth(sasl),
                        null,
                        krb5.?,
                        &resp,
                    );
                }
                newstate = SASL_GSSAPI_TOKEN;
            } else {
                result = CURLE_NOT_BUILT_IN;
            }
        },
        SASL_GSSAPI_TOKEN => {
            if (use_kerberos5) {
                const krb5 = krb5_ext.Curl_auth_krb5_get(conn);
                if (krb5 == null) {
                    result = CURLE_OUT_OF_MEMORY;
                } else {
                    result = getServerMessage(sasl, data, &serverdata);
                    if (result == CURLE_OK) {
                        if (saslGetMutualAuth(sasl)) {
                            result = krb5_ext.Curl_auth_create_gssapi_user_message(
                                data,
                                null,
                                null,
                                null,
                                true,
                                &serverdata,
                                krb5.?,
                                &resp,
                            );
                            newstate = SASL_GSSAPI_NO_DATA;
                        } else {
                            result = krb5_ext.Curl_auth_create_gssapi_security_message(
                                data,
                                conn_creds,
                                &serverdata,
                                krb5.?,
                                &resp,
                            );
                        }
                    }
                }
            } else {
                result = CURLE_NOT_BUILT_IN;
            }
        },
        SASL_GSSAPI_NO_DATA => {
            if (use_kerberos5) {
                const krb5 = krb5_ext.Curl_auth_krb5_get(conn);
                if (krb5 == null) {
                    result = CURLE_OUT_OF_MEMORY;
                } else {
                    result = getServerMessage(sasl, data, &serverdata);
                    if (result == CURLE_OK) {
                        result = krb5_ext.Curl_auth_create_gssapi_security_message(
                            data,
                            conn_creds,
                            &serverdata,
                            krb5.?,
                            &resp,
                        );
                    }
                }
            } else {
                result = CURLE_NOT_BUILT_IN;
            }
        },
        SASL_OAUTH2 => {
            if (conn_creds) |creds| {
                if (sasl.authused == SASL_MECH_OAUTHBEARER) {
                    result = Curl_auth_create_oauth_bearer_message(
                        creds,
                        conn_hostname,
                        @intCast(conn_port),
                        &resp,
                    );
                    newstate = SASL_OAUTH2_RESP;
                } else {
                    result = Curl_auth_create_xoauth_bearer_message(creds, &resp);
                }
            } else {
                result = CURLE_LOGIN_DENIED;
            }
        },
        SASL_OAUTH2_RESP => {
            if (code == params.finalcode) {
                progress.* = SASL_DONE;
                saslState(sasl, data, SASL_STOP);
                return result;
            } else if (code == params.contcode) {
                io_buffers.Curl_bufref_set(&resp, "\x01", 1, null);
            } else {
                progress.* = SASL_DONE;
                saslState(sasl, data, SASL_STOP);
                return CURLE_LOGIN_DENIED;
            }
        },
        SASL_CANCEL => {
            sasl.authmechs &= ~sasl.authused;
            sasl.authused = SASL_AUTH_NONE;
            sasl.curmech = null;
            return Curl_sasl_start_zig(
                sasl,
                data,
                saslGetForceIr(sasl),
                progress,
                conn,
                conn_creds,
                state_creds,
                conn_hostname,
                conn_port,
                sasl_ir,
            );
        },
        else => {
            failf0(data, "Unsupported SASL authentication mechanism");
            result = CURLE_UNSUPPORTED_PROTOCOL;
        },
    }

    io_buffers.Curl_bufref_free(&serverdata);

    switch (result) {
        CURLE_BAD_CONTENT_ENCODING => {
            if (params.cancelauth) |cancel_fn| {
                if (sasl.curmech) |cm| {
                    result = cancel_fn(data, cm);
                }
            }
            newstate = SASL_CANCEL;
        },
        CURLE_OK => {
            result = buildMessage(sasl, &resp);
            if (result == CURLE_OK) {
                if (params.contauth) |cont_fn| {
                    if (sasl.curmech) |cm| {
                        result = cont_fn(data, cm, &resp);
                    }
                }
            }
        },
        else => {
            newstate = SASL_STOP;
            progress.* = SASL_DONE;
        },
    }

    io_buffers.Curl_bufref_free(&resp);
    saslState(sasl, data, newstate);
    return result;
}

pub export fn Curl_sasl_is_blocked_zig(
    sasl: *SASL,
    data: ?*Curl_easy,
    conn_creds: ?*Curl_creds,
) callconv(.c) CURLcode {
    _ = conn_creds;
    const enabledmechs = sasl.authmechs & sasl.prefmech;

    if (sasl.authmechs == 0) {
        infof0(data, "SASL: no auth mechanism was offered or recognized");
    } else if (enabledmechs == 0) {
        infof0(data, "SASL: no overlap between offered and configured auth mechanisms");
    } else {
        infof0(data, "SASL: no auth mechanism offered could be selected");
    }

    return CURLE_LOGIN_DENIED;
}

// ============================================================================
// 2. lib/ftplistparser.c — FTP LIST Response Parser & Wildcard Helpers
// ============================================================================

pub const CURLWC_CLEAR: u8 = 0;
pub const CURLWC_INIT: u8 = 1;
pub const CURLWC_MATCHING: u8 = 2;
pub const CURLWC_DOWNLOADING: u8 = 3;
pub const CURLWC_CLEAN: u8 = 4;
pub const CURLWC_SKIP: u8 = 5;
pub const CURLWC_ERROR: u8 = 6;
pub const CURLWC_DONE: u8 = 7;

pub const wildcard_dtor = ?*const fn (ptr: ?*anyopaque) callconv(.c) void;

pub const ftp_wc = extern struct {
    parser: ?*ftp_parselist_data,
    backup: extern struct {
        write_function: ?curl_write_callback,
        file_descriptor: ?*anyopaque,
    },
};

pub const WildcardData = extern struct {
    path: ?[*:0]u8 = null,
    pattern: ?[*:0]u8 = null,
    filelist: Curl_llist = undefined,
    ftpwc: ?*ftp_wc = null,
    dtor: wildcard_dtor = null,
    state: u8 = CURLWC_CLEAR,
};

pub const CURLFILETYPE_FILE: c_uint = 0;
pub const CURLFILETYPE_DIRECTORY: c_uint = 1;
pub const CURLFILETYPE_SYMLINK: c_uint = 2;
pub const CURLFILETYPE_DEVICE_BLOCK: c_uint = 3;
pub const CURLFILETYPE_DEVICE_CHAR: c_uint = 4;
pub const CURLFILETYPE_NAMEDPIPE: c_uint = 5;
pub const CURLFILETYPE_SOCKET: c_uint = 6;
pub const CURLFILETYPE_DOOR: c_uint = 7;
pub const CURLFILETYPE_UNKNOWN: c_uint = 8;

pub const CURLFINFOFLAG_KNOWN_FILENAME: c_uint = 1 << 0;
pub const CURLFINFOFLAG_KNOWN_FILETYPE: c_uint = 1 << 1;
pub const CURLFINFOFLAG_KNOWN_TIME: c_uint = 1 << 2;
pub const CURLFINFOFLAG_KNOWN_PERM: c_uint = 1 << 3;
pub const CURLFINFOFLAG_KNOWN_UID: c_uint = 1 << 4;
pub const CURLFINFOFLAG_KNOWN_GID: c_uint = 1 << 5;
pub const CURLFINFOFLAG_KNOWN_SIZE: c_uint = 1 << 6;
pub const CURLFINFOFLAG_KNOWN_HLINKCOUNT: c_uint = 1 << 7;

pub const CURL_FNMATCH_MATCH: c_int = 0;
pub const CURL_FNMATCH_NOMATCH: c_int = 1;
pub const CURL_FNMATCH_FAIL: c_int = 2;
pub const CURL_WRITEFUNC_ERROR: usize = 0xffffffff;

const MAX_FTPLIST_BUFFER: usize = 64 * 1024;

const OsType = enum(u8) {
    UNKNOWN = 0,
    UNIX = 1,
    WIN_NT = 2,
};

const UnixMainState = enum(u8) {
    TOTALSIZE = 0,
    FILETYPE,
    PERMISSION,
    HLINKS,
    USER,
    GROUP,
    SIZE,
    TIME,
    FILENAME,
    SYMLINK,
};

const UnixSubState = u8;
const PL_UNIX_TOTALSIZE_INIT: UnixSubState = 0;
const PL_UNIX_TOTALSIZE_READING: UnixSubState = 1;
const PL_UNIX_HLINKS_PRESPACE: UnixSubState = 0;
const PL_UNIX_HLINKS_NUMBER: UnixSubState = 1;
const PL_UNIX_USER_PRESPACE: UnixSubState = 0;
const PL_UNIX_USER_PARSING: UnixSubState = 1;
const PL_UNIX_GROUP_PRESPACE: UnixSubState = 0;
const PL_UNIX_GROUP_NAME: UnixSubState = 1;
const PL_UNIX_SIZE_PRESPACE: UnixSubState = 0;
const PL_UNIX_SIZE_NUMBER: UnixSubState = 1;
const PL_UNIX_TIME_PREPART1: UnixSubState = 0;
const PL_UNIX_TIME_PART1: UnixSubState = 1;
const PL_UNIX_TIME_PREPART2: UnixSubState = 2;
const PL_UNIX_TIME_PART2: UnixSubState = 3;
const PL_UNIX_TIME_PREPART3: UnixSubState = 4;
const PL_UNIX_TIME_PART3: UnixSubState = 5;
const PL_UNIX_FILENAME_PRESPACE: UnixSubState = 0;
const PL_UNIX_FILENAME_NAME: UnixSubState = 1;
const PL_UNIX_FILENAME_WINDOWSEOL: UnixSubState = 2;
const PL_UNIX_SYMLINK_PRESPACE: UnixSubState = 0;
const PL_UNIX_SYMLINK_NAME: UnixSubState = 1;
const PL_UNIX_SYMLINK_PRETARGET1: UnixSubState = 2;
const PL_UNIX_SYMLINK_PRETARGET2: UnixSubState = 3;
const PL_UNIX_SYMLINK_PRETARGET3: UnixSubState = 4;
const PL_UNIX_SYMLINK_PRETARGET4: UnixSubState = 5;
const PL_UNIX_SYMLINK_TARGET: UnixSubState = 6;
const PL_UNIX_SYMLINK_WINDOWSEOL: UnixSubState = 7;

const WinntMainState = enum(u8) {
    DATE = 0,
    TIME,
    DIRORSIZE,
    FILENAME,
};

const WinntSubState = u8;
const PL_WINNT_TIME_PRESPACE: WinntSubState = 0;
const PL_WINNT_TIME_TIME: WinntSubState = 1;
const PL_WINNT_DIRORSIZE_PRESPACE: WinntSubState = 0;
const PL_WINNT_DIRORSIZE_CONTENT: WinntSubState = 1;
const PL_WINNT_FILENAME_PRESPACE: WinntSubState = 0;
const PL_WINNT_FILENAME_CONTENT: WinntSubState = 1;
const PL_WINNT_FILENAME_WINEOL: WinntSubState = 2;

pub const ftp_parselist_data = extern struct {
    os_type: OsType = .UNKNOWN,
    unix_main: UnixMainState = .TOTALSIZE,
    unix_sub: UnixSubState = 0,
    nt_main: WinntMainState = .DATE,
    nt_sub: WinntSubState = 0,
    err: CURLcode = CURLE_OK,
    file_data: ?*fileinfo = null,
    item_length: usize = 0,
    item_offset: usize = 0,
    offsets: extern struct {
        filename: usize = 0,
        user: usize = 0,
        group: usize = 0,
        time: usize = 0,
        perm: usize = 0,
        target: usize = 0,
    } = .{},
};

fn fileinfoDtor(user: ?*anyopaque, element: ?*anyopaque) callconv(.c) void {
    _ = user;
    if (element) |el| {
        const finfo: *fileinfo = @ptrCast(@alignCast(el));
        containers.Curl_fileinfo_cleanup(finfo);
    }
}

pub export fn Curl_wildcard_init(wc: *WildcardData) callconv(.c) void {
    containers.Curl_llist_init(&wc.filelist, &fileinfoDtor);
    wc.state = CURLWC_INIT;
}

pub export fn Curl_wildcard_dtor(wcp: *?*WildcardData) callconv(.c) void {
    const wc = wcp.* orelse return;

    if (wc.dtor) |dtor_fn| {
        dtor_fn(wc.ftpwc);
        wc.dtor = null;
        wc.ftpwc = null;
    }
    std.debug.assert(wc.ftpwc == null);

    containers.Curl_llist_destroy(&wc.filelist, null);
    mem.free(wc.path);
    wc.path = null;
    mem.free(wc.pattern);
    wc.pattern = null;
    wc.state = CURLWC_INIT;
    mem.freeSized(wc, @sizeOf(WildcardData));
    wcp.* = null;
}

pub export fn Curl_ftp_parselist_data_alloc() callconv(.c) ?*ftp_parselist_data {
    return @ptrCast(@alignCast(mem.calloc(1, @sizeOf(ftp_parselist_data))));
}

pub export fn Curl_ftp_parselist_data_free(parserp: *?*ftp_parselist_data) callconv(.c) void {
    const parser = parserp.* orelse return;
    containers.Curl_fileinfo_cleanup(parser.file_data);
    mem.freeSized(parser, @sizeOf(ftp_parselist_data));
    parserp.* = null;
}

pub export fn Curl_ftp_parselist_geterror(pl_data: *ftp_parselist_data) callconv(.c) CURLcode {
    return pl_data.err;
}

pub export fn Curl_ftp_listmode_zig(
    data: ?*Curl_easy,
    wildcardmatch: bool,
    wildcard: ?*WildcardData,
) callconv(.c) bool {
    _ = data;
    if (wildcardmatch) {
        const wc = wildcard orelse return false;
        return switch (wc.state) {
            CURLWC_CLEAR, CURLWC_INIT, CURLWC_MATCHING => true,
            else => false,
        };
    }
    return false;
}

fn ftpPlGetPermission(str: [*]const u8) c_uint {
    var permissions: c_uint = 0;
    // USER
    if (str[0] == 'r') {
        permissions |= 1 << 8;
    } else if (str[0] != '-') {
        permissions |= 1 << 12;
    }
    if (str[1] == 'w') {
        permissions |= 1 << 7;
    } else if (str[1] != '-') {
        permissions |= 1 << 12;
    }
    if (str[2] == 'x') {
        permissions |= 1 << 6;
    } else if (str[2] == 's') {
        permissions |= 1 << 6;
        permissions |= 1 << 11;
    } else if (str[2] == 'S') {
        permissions |= 1 << 11;
    } else if (str[2] != '-') {
        permissions |= 1 << 12;
    }
    // GROUP
    if (str[3] == 'r') {
        permissions |= 1 << 5;
    } else if (str[3] != '-') {
        permissions |= 1 << 12;
    }
    if (str[4] == 'w') {
        permissions |= 1 << 4;
    } else if (str[4] != '-') {
        permissions |= 1 << 12;
    }
    if (str[5] == 'x') {
        permissions |= 1 << 3;
    } else if (str[5] == 's') {
        permissions |= 1 << 3;
        permissions |= 1 << 10;
    } else if (str[5] == 'S') {
        permissions |= 1 << 10;
    } else if (str[5] != '-') {
        permissions |= 1 << 12;
    }
    // OTHERS
    if (str[6] == 'r') {
        permissions |= 1 << 2;
    } else if (str[6] != '-') {
        permissions |= 1 << 12;
    }
    if (str[7] == 'w') {
        permissions |= 1 << 1;
    } else if (str[7] != '-') {
        permissions |= 1 << 12;
    }
    if (str[8] == 'x') {
        permissions |= 1 << 0;
    } else if (str[8] == 't') {
        permissions |= 1 << 0;
        permissions |= 1 << 9;
    } else if (str[8] == 'T') {
        permissions |= 1 << 9;
    } else if (str[8] != '-') {
        permissions |= 1 << 12;
    }
    return permissions;
}

fn ftpPlInsertFinfo(data: ?*Curl_easy, parser: *ftp_parselist_data) CURLcode {
    const finfo = parser.file_data orelse return CURLE_FAILED_INIT;
    const infop = &finfo.info;
    const b_ptr = io_buffers.curlx_dyn_ptr(&finfo.buf) orelse return CURLE_OUT_OF_MEMORY;

    infop.b_data = b_ptr;
    infop.b_size = 0;
    infop.b_used = io_buffers.curlx_dyn_len(&finfo.buf);

    const offsets = &parser.offsets;
    infop.filename = @ptrCast(b_ptr + offsets.filename);
    infop.strings.time = @ptrCast(b_ptr + offsets.time);
    if (offsets.perm != 0)
        infop.strings.perm = @ptrCast(b_ptr + offsets.perm);
    if (offsets.user != 0)
        infop.strings.user = @ptrCast(b_ptr + offsets.user);
    if (offsets.group != 0)
        infop.strings.group = @ptrCast(b_ptr + offsets.group);
    if (infop.filetype == CURLFILETYPE_SYMLINK) {
        infop.strings.target = @ptrCast(b_ptr + offsets.target);
    }

    const fname_slice = std.mem.span(infop.filename.?);
    if (std.mem.indexOfScalar(u8, fname_slice, '/') == null) {
        var wc_opt: ?*WildcardData = null;
        var fnmatch_opt: ?curl_fnmatch_callback = null;
        var fnmatch_data: ?*anyopaque = null;
        if (!builtin.is_test and data != null) {
            c_ext.Curl_ftp_parselist_get_easy(data, &wc_opt, &fnmatch_opt, &fnmatch_data);
        }
        const wc = wc_opt orelse {
            containers.Curl_fileinfo_cleanup(finfo);
            parser.file_data = null;
            return CURLE_OK;
        };
        const list = &wc.filelist;
        const fnmatch_fn: curl_fnmatch_callback = fnmatch_opt orelse &Curl_fnmatch;

        var guard: Curl_mapi_guard = .{};
        if (!builtin.is_test and data != null) {
            c_ext.Curl_cbapi_enter(&guard, data, null, CURL_CBAPI_FN_easy_fnmatch_data);
        }
        const fnm_res = fnmatch_fn(fnmatch_data, wc.pattern, infop.filename);
        if (!builtin.is_test and data != null) {
            c_ext.Curl_cbapi_leave(&guard);
        }

        var add = false;
        if (fnm_res == CURL_FNMATCH_MATCH) {
            add = true;
            if (infop.filetype == CURLFILETYPE_SYMLINK and infop.strings.target != null) {
                const target_slice = std.mem.span(infop.strings.target.?);
                if (std.mem.indexOf(u8, target_slice, " -> ") != null) {
                    add = false;
                }
            }
        }

        if (add) {
            containers.Curl_llist_insert_next(list, list._tail, infop, &finfo.list);
        } else {
            containers.Curl_fileinfo_cleanup(finfo);
        }
    } else {
        containers.Curl_fileinfo_cleanup(finfo);
    }

    parser.file_data = null;
    return CURLE_OK;
}

fn unixLineParser(
    data: ?*Curl_easy,
    parser: *ftp_parselist_data,
    finfo: *fileinfo,
    c: u8,
) CURLcode {
    const infop = &finfo.info;
    const len = io_buffers.curlx_dyn_len(&finfo.buf);
    const mem_ptr = io_buffers.curlx_dyn_ptr(&finfo.buf) orelse return CURLE_OUT_OF_MEMORY;
    var result: CURLcode = CURLE_OK;

    switch (parser.unix_main) {
        .TOTALSIZE => {
            switch (parser.unix_sub) {
                PL_UNIX_TOTALSIZE_INIT => {
                    if (c == 't') {
                        parser.unix_sub = PL_UNIX_TOTALSIZE_READING;
                        parser.item_length += 1;
                    } else {
                        parser.unix_main = .FILETYPE;
                        return unixLineParser(data, parser, finfo, c);
                    }
                },
                PL_UNIX_TOTALSIZE_READING => {
                    parser.item_length += 1;
                    if (c == '\r') {
                        parser.item_length -= 1;
                        if (parser.item_length == 0)
                            return CURLE_FTP_BAD_FILE_LIST;
                    } else if (c == '\n') {
                        mem_ptr[parser.item_length - 1] = 0;
                        if (parser.item_length >= 6 and std.mem.eql(u8, mem_ptr[0..6], "total ")) {
                            var endptr: ?[*:0]const u8 = @ptrCast(mem_ptr + 6);
                            curlx_str_passblanks(&endptr);
                            while (primitives.curlx_isdigit(endptr.?[0])) {
                                endptr = endptr.? + 1;
                            }
                            if (endptr.?[0] != 0) {
                                return CURLE_FTP_BAD_FILE_LIST;
                            }
                            parser.unix_main = .FILETYPE;
                        } else {
                            return CURLE_FTP_BAD_FILE_LIST;
                        }
                        io_buffers.curlx_dyn_reset(&finfo.buf);
                    }
                },
                else => {},
            }
        },
        .FILETYPE => {
            switch (c) {
                '-' => infop.filetype = CURLFILETYPE_FILE,
                'd' => infop.filetype = CURLFILETYPE_DIRECTORY,
                'l' => infop.filetype = CURLFILETYPE_SYMLINK,
                'p' => infop.filetype = CURLFILETYPE_NAMEDPIPE,
                's' => infop.filetype = CURLFILETYPE_SOCKET,
                'c' => infop.filetype = CURLFILETYPE_DEVICE_CHAR,
                'b' => infop.filetype = CURLFILETYPE_DEVICE_BLOCK,
                'D' => infop.filetype = CURLFILETYPE_DOOR,
                else => return CURLE_FTP_BAD_FILE_LIST,
            }
            infop.flags |= CURLFINFOFLAG_KNOWN_FILETYPE;
            parser.unix_main = .PERMISSION;
            parser.item_length = 0;
            parser.item_offset = 1;
        },
        .PERMISSION => {
            parser.item_length += 1;
            if ((parser.item_length <= 9) and
                std.mem.indexOfScalar(u8, "rwx-tTsS", c) == null)
            {
                return CURLE_FTP_BAD_FILE_LIST;
            } else if (parser.item_length == 10) {
                var perm: c_uint = 0;
                if (c != ' ') {
                    return CURLE_FTP_BAD_FILE_LIST;
                }
                mem_ptr[10] = 0;
                perm = ftpPlGetPermission(mem_ptr + parser.item_offset);
                if ((perm & (1 << 12)) != 0) {
                    return CURLE_FTP_BAD_FILE_LIST;
                }
                parser.offsets.perm = parser.item_offset;
                infop.flags |= CURLFINFOFLAG_KNOWN_PERM;
                infop.perm = perm;

                parser.offsets.user = 0;
                parser.offsets.group = 0;
                parser.unix_main = .HLINKS;
                parser.unix_sub = PL_UNIX_HLINKS_PRESPACE;
            }
        },
        .HLINKS => {
            switch (parser.unix_sub) {
                PL_UNIX_HLINKS_PRESPACE => {
                    if (c != ' ') {
                        if (primitives.curlx_isdigit(c) and len != 0) {
                            parser.item_offset = len - 1;
                            parser.item_length = 1;
                            parser.unix_sub = PL_UNIX_HLINKS_NUMBER;
                        } else {
                            return CURLE_FTP_BAD_FILE_LIST;
                        }
                    }
                },
                PL_UNIX_HLINKS_NUMBER => {
                    parser.item_length += 1;
                    if (c == ' ') {
                        var p: ?[*:0]const u8 = @ptrCast(mem_ptr + parser.item_offset);
                        var hlinks: curl_off_t = 0;
                        mem_ptr[parser.item_offset + parser.item_length - 1] = 0;
                        if (curlx_str_number(&p, &hlinks, std.math.maxInt(c_long)) == 0) {
                            infop.flags |= CURLFINFOFLAG_KNOWN_HLINKCOUNT;
                            infop.hardlinks = @intCast(hlinks);
                        }
                        parser.unix_main = .USER;
                        parser.unix_sub = PL_UNIX_USER_PRESPACE;
                    } else if (!primitives.curlx_isdigit(c)) {
                        return CURLE_FTP_BAD_FILE_LIST;
                    }
                },
                else => {},
            }
        },
        .USER => {
            switch (parser.unix_sub) {
                PL_UNIX_USER_PRESPACE => {
                    if (c != ' ' and len != 0) {
                        parser.item_offset = len - 1;
                        parser.item_length = 1;
                        parser.unix_sub = PL_UNIX_USER_PARSING;
                    }
                },
                PL_UNIX_USER_PARSING => {
                    parser.item_length += 1;
                    if (c == ' ') {
                        mem_ptr[parser.item_offset + parser.item_length - 1] = 0;
                        parser.offsets.user = parser.item_offset;
                        parser.unix_main = .GROUP;
                        parser.unix_sub = PL_UNIX_GROUP_PRESPACE;
                        parser.item_offset = 0;
                        parser.item_length = 0;
                    } else if (!primitives.curlx_isprint(c)) {
                        return CURLE_FTP_BAD_FILE_LIST;
                    }
                },
                else => {},
            }
        },
        .GROUP => {
            switch (parser.unix_sub) {
                PL_UNIX_GROUP_PRESPACE => {
                    if (c != ' ' and len != 0) {
                        parser.item_offset = len - 1;
                        parser.item_length = 1;
                        parser.unix_sub = PL_UNIX_GROUP_NAME;
                    }
                },
                PL_UNIX_GROUP_NAME => {
                    parser.item_length += 1;
                    if (c == ' ') {
                        mem_ptr[parser.item_offset + parser.item_length - 1] = 0;
                        parser.offsets.group = parser.item_offset;
                        parser.unix_main = .SIZE;
                        parser.unix_sub = PL_UNIX_SIZE_PRESPACE;
                        parser.item_offset = 0;
                        parser.item_length = 0;
                    } else if (!primitives.curlx_isprint(c)) {
                        return CURLE_FTP_BAD_FILE_LIST;
                    }
                },
                else => {},
            }
        },
        .SIZE => {
            switch (parser.unix_sub) {
                PL_UNIX_SIZE_PRESPACE => {
                    if (c != ' ') {
                        if (primitives.curlx_isdigit(c) and len != 0) {
                            parser.item_offset = len - 1;
                            parser.item_length = 1;
                            parser.unix_sub = PL_UNIX_SIZE_NUMBER;
                        } else {
                            return CURLE_FTP_BAD_FILE_LIST;
                        }
                    }
                },
                PL_UNIX_SIZE_NUMBER => {
                    parser.item_length += 1;
                    if (c == ' ') {
                        var p: ?[*:0]const u8 = @ptrCast(mem_ptr + parser.item_offset);
                        var fsize: curl_off_t = 0;
                        mem_ptr[parser.item_offset + parser.item_length - 1] = 0;
                        if (curlx_str_number(&p, &fsize, std.math.maxInt(curl_off_t)) == 0) {
                            if (p.?[0] == 0) {
                                infop.flags |= CURLFINFOFLAG_KNOWN_SIZE;
                                infop.size = fsize;
                            }
                            parser.unix_main = .TIME;
                            parser.unix_sub = PL_UNIX_TIME_PREPART1;
                        }
                    } else if (!primitives.curlx_isdigit(c)) {
                        return CURLE_FTP_BAD_FILE_LIST;
                    }
                },
                else => {},
            }
        },
        .TIME => {
            switch (parser.unix_sub) {
                PL_UNIX_TIME_PREPART1 => {
                    if (c != ' ') {
                        if (primitives.curlx_isalnum(c) and len != 0) {
                            parser.item_offset = len - 1;
                            parser.item_length = 1;
                            parser.unix_sub = PL_UNIX_TIME_PART1;
                        } else {
                            return CURLE_FTP_BAD_FILE_LIST;
                        }
                    }
                },
                PL_UNIX_TIME_PART1 => {
                    parser.item_length += 1;
                    if (c == ' ') {
                        parser.unix_sub = PL_UNIX_TIME_PREPART2;
                    } else if (!primitives.curlx_isalnum(c) and c != '.') {
                        return CURLE_FTP_BAD_FILE_LIST;
                    }
                },
                PL_UNIX_TIME_PREPART2 => {
                    parser.item_length += 1;
                    if (c != ' ') {
                        if (primitives.curlx_isalnum(c)) {
                            parser.unix_sub = PL_UNIX_TIME_PART2;
                        } else {
                            return CURLE_FTP_BAD_FILE_LIST;
                        }
                    }
                },
                PL_UNIX_TIME_PART2 => {
                    parser.item_length += 1;
                    if (c == ' ') {
                        parser.unix_sub = PL_UNIX_TIME_PREPART3;
                    } else if (!primitives.curlx_isalnum(c) and c != '.') {
                        return CURLE_FTP_BAD_FILE_LIST;
                    }
                },
                PL_UNIX_TIME_PREPART3 => {
                    parser.item_length += 1;
                    if (c != ' ') {
                        if (primitives.curlx_isalnum(c)) {
                            parser.unix_sub = PL_UNIX_TIME_PART3;
                        } else {
                            return CURLE_FTP_BAD_FILE_LIST;
                        }
                    }
                },
                PL_UNIX_TIME_PART3 => {
                    parser.item_length += 1;
                    if (c == ' ') {
                        mem_ptr[parser.item_offset + parser.item_length - 1] = 0;
                        parser.offsets.time = parser.item_offset;
                        if (infop.filetype == CURLFILETYPE_SYMLINK) {
                            parser.unix_main = .SYMLINK;
                            parser.unix_sub = PL_UNIX_SYMLINK_PRESPACE;
                        } else {
                            parser.unix_main = .FILENAME;
                            parser.unix_sub = PL_UNIX_FILENAME_PRESPACE;
                        }
                    } else if (!primitives.curlx_isalnum(c) and c != '.' and c != ':') {
                        return CURLE_FTP_BAD_FILE_LIST;
                    }
                },
                else => {},
            }
        },
        .FILENAME => {
            switch (parser.unix_sub) {
                PL_UNIX_FILENAME_PRESPACE => {
                    if (c != ' ' and len != 0) {
                        parser.item_offset = len - 1;
                        parser.item_length = 1;
                        parser.unix_sub = PL_UNIX_FILENAME_NAME;
                    }
                },
                PL_UNIX_FILENAME_NAME => {
                    parser.item_length += 1;
                    if (c == '\r') {
                        parser.unix_sub = PL_UNIX_FILENAME_WINDOWSEOL;
                    } else if (c == '\n') {
                        mem_ptr[parser.item_offset + parser.item_length - 1] = 0;
                        parser.offsets.filename = parser.item_offset;
                        parser.unix_main = .FILETYPE;
                        result = ftpPlInsertFinfo(data, parser);
                    }
                },
                PL_UNIX_FILENAME_WINDOWSEOL => {
                    if (c == '\n') {
                        mem_ptr[parser.item_offset + parser.item_length - 1] = 0;
                        parser.offsets.filename = parser.item_offset;
                        parser.unix_main = .FILETYPE;
                        result = ftpPlInsertFinfo(data, parser);
                    } else {
                        return CURLE_FTP_BAD_FILE_LIST;
                    }
                },
                else => {},
            }
        },
        .SYMLINK => {
            switch (parser.unix_sub) {
                PL_UNIX_SYMLINK_PRESPACE => {
                    if (c != ' ' and len != 0) {
                        parser.item_offset = len - 1;
                        parser.item_length = 1;
                        parser.unix_sub = PL_UNIX_SYMLINK_NAME;
                    }
                },
                PL_UNIX_SYMLINK_NAME => {
                    parser.item_length += 1;
                    if (c == ' ') {
                        parser.unix_sub = PL_UNIX_SYMLINK_PRETARGET1;
                    } else if (c == '\r' or c == '\n') {
                        return CURLE_FTP_BAD_FILE_LIST;
                    }
                },
                PL_UNIX_SYMLINK_PRETARGET1 => {
                    parser.item_length += 1;
                    if (c == '-') {
                        parser.unix_sub = PL_UNIX_SYMLINK_PRETARGET2;
                    } else if (c == '\r' or c == '\n') {
                        return CURLE_FTP_BAD_FILE_LIST;
                    } else {
                        parser.unix_sub = PL_UNIX_SYMLINK_NAME;
                    }
                },
                PL_UNIX_SYMLINK_PRETARGET2 => {
                    parser.item_length += 1;
                    if (c == '>') {
                        parser.unix_sub = PL_UNIX_SYMLINK_PRETARGET3;
                    } else if (c == '\r' or c == '\n') {
                        return CURLE_FTP_BAD_FILE_LIST;
                    } else {
                        parser.unix_sub = PL_UNIX_SYMLINK_NAME;
                    }
                },
                PL_UNIX_SYMLINK_PRETARGET3 => {
                    parser.item_length += 1;
                    if (c == ' ') {
                        parser.unix_sub = PL_UNIX_SYMLINK_PRETARGET4;
                        mem_ptr[parser.item_offset + parser.item_length - 4] = 0;
                        parser.offsets.filename = parser.item_offset;
                        parser.item_length = 0;
                        parser.item_offset = 0;
                    } else if (c == '\r' or c == '\n') {
                        return CURLE_FTP_BAD_FILE_LIST;
                    } else {
                        parser.unix_sub = PL_UNIX_SYMLINK_NAME;
                    }
                },
                PL_UNIX_SYMLINK_PRETARGET4 => {
                    if (c != '\r' and c != '\n' and len != 0) {
                        parser.unix_sub = PL_UNIX_SYMLINK_TARGET;
                        parser.item_offset = len - 1;
                        parser.item_length = 1;
                    } else {
                        return CURLE_FTP_BAD_FILE_LIST;
                    }
                },
                PL_UNIX_SYMLINK_TARGET => {
                    parser.item_length += 1;
                    if (c == '\r') {
                        parser.unix_sub = PL_UNIX_SYMLINK_WINDOWSEOL;
                    } else if (c == '\n') {
                        mem_ptr[parser.item_offset + parser.item_length - 1] = 0;
                        parser.offsets.target = parser.item_offset;
                        parser.unix_main = .FILETYPE;
                        result = ftpPlInsertFinfo(data, parser);
                    }
                },
                PL_UNIX_SYMLINK_WINDOWSEOL => {
                    if (c == '\n') {
                        mem_ptr[parser.item_offset + parser.item_length - 1] = 0;
                        parser.offsets.target = parser.item_offset;
                        parser.unix_main = .FILETYPE;
                        result = ftpPlInsertFinfo(data, parser);
                    } else {
                        return CURLE_FTP_BAD_FILE_LIST;
                    }
                },
                else => {},
            }
        },
    }
    return result;
}

fn winntLineParser(
    data: ?*Curl_easy,
    parser: *ftp_parselist_data,
    finfo: *fileinfo,
    c: u8,
) CURLcode {
    const infop = &finfo.info;
    const len = io_buffers.curlx_dyn_len(&finfo.buf);
    const mem_ptr = io_buffers.curlx_dyn_ptr(&finfo.buf) orelse return CURLE_OUT_OF_MEMORY;
    var result: CURLcode = CURLE_OK;

    switch (parser.nt_main) {
        .DATE => {
            parser.item_length += 1;
            if (parser.item_length < 9) {
                if (std.mem.indexOfScalar(u8, "0123456789-", c) == null) {
                    return CURLE_FTP_BAD_FILE_LIST;
                }
            } else if (parser.item_length == 9) {
                if (c == ' ') {
                    parser.nt_main = .TIME;
                    parser.nt_sub = PL_WINNT_TIME_PRESPACE;
                } else {
                    return CURLE_FTP_BAD_FILE_LIST;
                }
            }
        },
        .TIME => {
            parser.item_length += 1;
            switch (parser.nt_sub) {
                PL_WINNT_TIME_PRESPACE => {
                    if (!primitives.curlx_isspace(c)) {
                        parser.nt_sub = PL_WINNT_TIME_TIME;
                    }
                },
                PL_WINNT_TIME_TIME => {
                    if (c == ' ') {
                        parser.offsets.time = parser.item_offset;
                        mem_ptr[parser.item_offset + parser.item_length - 1] = 0;
                        parser.nt_main = .DIRORSIZE;
                        parser.nt_sub = PL_WINNT_DIRORSIZE_PRESPACE;
                        parser.item_length = 0;
                    } else if (std.mem.indexOfScalar(u8, "APM0123456789:", c) == null) {
                        return CURLE_FTP_BAD_FILE_LIST;
                    }
                },
                else => {},
            }
        },
        .DIRORSIZE => {
            switch (parser.nt_sub) {
                PL_WINNT_DIRORSIZE_PRESPACE => {
                    if (c != ' ' and len != 0) {
                        parser.item_offset = len - 1;
                        parser.item_length = 1;
                        parser.nt_sub = PL_WINNT_DIRORSIZE_CONTENT;
                    }
                },
                PL_WINNT_DIRORSIZE_CONTENT => {
                    parser.item_length += 1;
                    if (c == ' ') {
                        mem_ptr[parser.item_offset + parser.item_length - 1] = 0;
                        const dirorsize = mem_ptr + parser.item_offset;
                        if (parser.item_length - 1 == 5 and std.mem.eql(u8, dirorsize[0..5], "<DIR>")) {
                            infop.filetype = CURLFILETYPE_DIRECTORY;
                            infop.size = 0;
                        } else {
                            var endptr: ?[*:0]const u8 = @ptrCast(dirorsize);
                            if (curlx_str_number(&endptr, &infop.size, std.math.maxInt(curl_off_t)) != 0) {
                                return CURLE_FTP_BAD_FILE_LIST;
                            }
                            infop.filetype = CURLFILETYPE_FILE;
                        }
                        infop.flags |= CURLFINFOFLAG_KNOWN_SIZE | CURLFINFOFLAG_KNOWN_FILETYPE;
                        parser.item_length = 0;
                        parser.nt_main = .FILENAME;
                        parser.nt_sub = PL_WINNT_FILENAME_PRESPACE;
                    }
                },
                else => {},
            }
        },
        .FILENAME => {
            switch (parser.nt_sub) {
                PL_WINNT_FILENAME_PRESPACE => {
                    if (c != ' ' and len != 0) {
                        parser.item_offset = len - 1;
                        parser.item_length = 1;
                        parser.nt_sub = PL_WINNT_FILENAME_CONTENT;
                    }
                },
                PL_WINNT_FILENAME_CONTENT => {
                    parser.item_length += 1;
                    if (len == 0)
                        return CURLE_FTP_BAD_FILE_LIST;
                    if (c == '\r') {
                        parser.nt_sub = PL_WINNT_FILENAME_WINEOL;
                        mem_ptr[len - 1] = 0;
                    } else if (c == '\n') {
                        parser.offsets.filename = parser.item_offset;
                        mem_ptr[len - 1] = 0;
                        result = ftpPlInsertFinfo(data, parser);
                        parser.nt_main = .DATE;
                        parser.nt_sub = 0;
                    }
                },
                PL_WINNT_FILENAME_WINEOL => {
                    if (c == '\n') {
                        parser.offsets.filename = parser.item_offset;
                        result = ftpPlInsertFinfo(data, parser);
                        parser.nt_main = .DATE;
                        parser.nt_sub = 0;
                    } else {
                        return CURLE_FTP_BAD_FILE_LIST;
                    }
                },
                else => {},
            }
        },
    }
    return result;
}

pub export fn Curl_ftp_parselist(
    buffer: [*]u8,
    size: usize,
    nmemb: usize,
    connptr: ?*anyopaque,
) callconv(.c) usize {
    const bufflen = size * nmemb;
    const data: ?*Curl_easy = @ptrCast(connptr);
    var wc_opt: ?*WildcardData = null;
    var fnmatch_opt: ?curl_fnmatch_callback = null;
    var fnmatch_data: ?*anyopaque = null;

    if (!builtin.is_test and data != null) {
        c_ext.Curl_ftp_parselist_get_easy(data, &wc_opt, &fnmatch_opt, &fnmatch_data);
    }

    const wc = wc_opt orelse return CURL_WRITEFUNC_ERROR;
    const ftpwc = wc.ftpwc orelse return CURL_WRITEFUNC_ERROR;
    const parser = ftpwc.parser orelse return CURL_WRITEFUNC_ERROR;

    var i: usize = 0;
    var result: CURLcode = CURLE_OK;

    if (parser.err != CURLE_OK) {
        if (parser.file_data) |fd| {
            containers.Curl_fileinfo_cleanup(fd);
            parser.file_data = null;
        }
        return bufflen;
    }

    while (i < bufflen) {
        const c = buffer[i];
        var finfo: *fileinfo = undefined;
        if (parser.file_data == null) {
            parser.file_data = containers.Curl_fileinfo_alloc();
            if (parser.file_data == null) {
                parser.err = CURLE_OUT_OF_MEMORY;
                return bufflen;
            }
            finfo = parser.file_data.?;
            io_buffers.curlx_dyn_init(&finfo.buf, MAX_FTPLIST_BUFFER);
            parser.item_offset = 0;
            parser.item_length = 0;
        } else {
            finfo = parser.file_data.?;
        }

        if (io_buffers.curlx_dyn_addn(&finfo.buf, buffer + i, 1) != CURLE_OK) {
            parser.err = CURLE_OUT_OF_MEMORY;
            if (parser.file_data) |fd| {
                containers.Curl_fileinfo_cleanup(fd);
                parser.file_data = null;
            }
            return bufflen;
        }

        switch (parser.os_type) {
            .UNKNOWN => {
                if (primitives.curlx_isdigit(c)) {
                    parser.os_type = .WIN_NT;
                    parser.nt_main = .DATE;
                    parser.nt_sub = 0;
                } else {
                    parser.os_type = .UNIX;
                    parser.unix_main = .TOTALSIZE;
                    parser.unix_sub = PL_UNIX_TOTALSIZE_INIT;
                }
                if (parser.os_type == .UNIX) {
                    result = unixLineParser(data, parser, finfo, c);
                } else {
                    result = winntLineParser(data, parser, finfo, c);
                }
            },
            .UNIX => {
                result = unixLineParser(data, parser, finfo, c);
            },
            .WIN_NT => {
                result = winntLineParser(data, parser, finfo, c);
            },
        }

        if (result != CURLE_OK) {
            parser.err = result;
            if (parser.file_data) |fd| {
                containers.Curl_fileinfo_cleanup(fd);
                parser.file_data = null;
            }
            return bufflen;
        }

        i += 1;
    }
    return bufflen;
}

// ============================================================================
// 3. lib/rtsp.c — RTSP Protocol Implementation
// ============================================================================

pub const CURL_RTSPREQ_NONE: u8 = 0;
pub const CURL_RTSPREQ_OPTIONS: u8 = 1;
pub const CURL_RTSPREQ_DESCRIBE: u8 = 2;
pub const CURL_RTSPREQ_ANNOUNCE: u8 = 3;
pub const CURL_RTSPREQ_SETUP: u8 = 4;
pub const CURL_RTSPREQ_PLAY: u8 = 5;
pub const CURL_RTSPREQ_PAUSE: u8 = 6;
pub const CURL_RTSPREQ_TEARDOWN: u8 = 7;
pub const CURL_RTSPREQ_GET_PARAMETER: u8 = 8;
pub const CURL_RTSPREQ_SET_PARAMETER: u8 = 9;
pub const CURL_RTSPREQ_RECORD: u8 = 10;
pub const CURL_RTSPREQ_RECEIVE: u8 = 11;
pub const CURL_RTSPREQ_LAST: u8 = 12;

const HTTPREQ_GET: u8 = 0;
const HTTPREQ_PUT: u8 = 4;
const HTTPREQ_HEAD: u8 = 5;

const CLIENTWRITE_BODY: c_int = 1 << 0;
const CLIENTWRITE_EOS: c_int = 1 << 7;
const CURL_WRITEFUNC_PAUSE: usize = 0x10000001;

const DYN_RTSP_REQ_HEADER: usize = 64 * 1024;
const MAX_RTP_BUFFERSIZE: usize = 1000000;
const HTTPVERSION: u8 = 11;

const CURL_XFER_RECV: c_int = 1 << 0;
const CURL_XFER_SEND: c_int = 1 << 1;
const CURL_XFER_SENDRECV: c_int = CURL_XFER_RECV | CURL_XFER_SEND;

const CURL_META_RTSP_EASY: [*:0]const u8 = "meta:proto:rtsp:easy";
const CURL_META_RTSP_CONN: [*:0]const u8 = "meta:proto:rtsp:conn";

pub const RtpParseState = enum(c_uint) {
    SKIP = 0,
    CHANNEL = 1,
    LEN = 2,
    DATA = 3,
};

pub const rtsp_conn = extern struct {
    buf: dynbuf,
    rtp_channel: c_int,
    rtp_len: usize,
    state: RtpParseState,
    in_header: bool,
};

pub const RTSP = extern struct {
    CSeq_sent: u32,
    CSeq_recv: u32,
};

pub const Curl_protocol = extern struct {
    setup_connection: ?*const fn (data: ?*Curl_easy, conn: ?*connectdata) callconv(.c) CURLcode = null,
    do_it: ?*const fn (data: ?*Curl_easy, done: *bool) callconv(.c) CURLcode = null,
    done: ?*const fn (data: ?*Curl_easy, status: CURLcode, premature: bool) callconv(.c) CURLcode = null,
    do_more: ?*const fn (data: ?*Curl_easy, completed: *c_int) callconv(.c) CURLcode = null,
    connect_it: ?*const fn (data: ?*Curl_easy, done: *bool) callconv(.c) CURLcode = null,
    connecting: ?*const fn (data: ?*Curl_easy, done: *bool) callconv(.c) CURLcode = null,
    doing: ?*const fn (data: ?*Curl_easy, dophase_done: *bool) callconv(.c) CURLcode = null,
    proto_pollset: ?*const fn (data: ?*Curl_easy, ps: ?*easy_pollset) callconv(.c) CURLcode = null,
    doing_pollset: ?*const fn (data: ?*Curl_easy, ps: ?*easy_pollset) callconv(.c) CURLcode = null,
    domore_pollset: ?*const fn (data: ?*Curl_easy, ps: ?*easy_pollset) callconv(.c) CURLcode = null,
    perform_pollset: ?*const fn (data: ?*Curl_easy, ps: ?*easy_pollset) callconv(.c) CURLcode = null,
    disconnect: ?*const fn (data: ?*Curl_easy, conn: ?*connectdata, dead_connection: bool) callconv(.c) CURLcode = null,
    write_resp: ?*const fn (data: ?*Curl_easy, buf: [*]const u8, blen: usize, is_eos: bool) callconv(.c) CURLcode = null,
    write_resp_hd: ?*const fn (data: ?*Curl_easy, buf: [*]const u8, blen: usize, is_eos: bool) callconv(.c) CURLcode = null,
    connection_is_dead: ?*const fn (data: ?*Curl_easy, conn: ?*connectdata) callconv(.c) bool = null,
    attach: ?*const fn (data: ?*Curl_easy, conn: ?*connectdata) callconv(.c) CURLcode = null,
    follow: ?*const fn (data: ?*Curl_easy, newurl: ?[*:0]u8, follow: c_uint) callconv(.c) CURLcode = null,
};

fn rtpPktLength(p: []const u8) usize {
    return (@as(usize, p[2]) << 8) | @as(usize, p[3]);
}

const CURL_POLL_OUT: c_int = 2;

fn rtspDoPollset(data: ?*Curl_easy, ps: ?*easy_pollset) callconv(.c) CURLcode {
    if (builtin.is_test) return CURLE_OK;
    return c_ext.Curl_pollset_change(data, ps, c_ext.Curl_rtsp_get_firstsocket(data), CURL_POLL_OUT, 0);
}

fn rtspEasyDtor(key: ?*const anyopaque, klen: usize, entry: ?*anyopaque) callconv(.c) void {
    _ = key;
    _ = klen;
    const p = entry orelse return;
    mem.freeSized(p, @sizeOf(RTSP));
}

fn rtspConnDtor(key: ?*const anyopaque, klen: usize, entry: ?*anyopaque) callconv(.c) void {
    _ = key;
    _ = klen;
    const rtspc: *rtsp_conn = @ptrCast(@alignCast(entry orelse return));
    io_buffers.curlx_dyn_free(&rtspc.buf);
    mem.freeSized(rtspc, @sizeOf(rtsp_conn));
}

fn rtspSetupConnection(data: ?*Curl_easy, conn: ?*connectdata) callconv(.c) CURLcode {
    if (builtin.is_test) return CURLE_OK;
    const rtspc: *rtsp_conn = @ptrCast(@alignCast(mem.calloc(1, @sizeOf(rtsp_conn)) orelse return CURLE_OUT_OF_MEMORY));
    io_buffers.curlx_dyn_init(&rtspc.buf, MAX_RTP_BUFFERSIZE);
    if (c_ext.Curl_conn_meta_set(conn, CURL_META_RTSP_CONN, rtspc, &rtspConnDtor) != CURLE_OK)
        return CURLE_OUT_OF_MEMORY;

    const rtsp: *RTSP = @ptrCast(@alignCast(mem.calloc(1, @sizeOf(RTSP)) orelse return CURLE_OUT_OF_MEMORY));
    if (c_ext.Curl_meta_set(data, CURL_META_RTSP_EASY, rtsp, &rtspEasyDtor) != CURLE_OK)
        return CURLE_OUT_OF_MEMORY;

    return CURLE_OK;
}

fn rtspConnIsDead(data: ?*Curl_easy, conn: ?*connectdata) callconv(.c) bool {
    if (builtin.is_test) return false;
    var input_pending: bool = false;
    return !c_ext.Curl_conn_is_alive(data, conn, &input_pending);
}

fn rtspConnect(data: ?*Curl_easy, done: *bool) callconv(.c) CURLcode {
    if (builtin.is_test) return CURLE_OK;
    const conn = c_ext.Curl_rtsp_get_conn(data);
    const rtspc: *rtsp_conn = @ptrCast(@alignCast(c_ext.Curl_conn_meta_get(conn, CURL_META_RTSP_CONN) orelse return CURLE_FAILED_INIT));

    c_ext.Curl_rtsp_init_cseq(data);
    rtspc.rtp_channel = -1;
    done.* = true;
    return CURLE_OK;
}

fn rtspDone(data: ?*Curl_easy, status: CURLcode, premature_in: bool) callconv(.c) CURLcode {
    if (builtin.is_test) return CURLE_OK;
    var premature = premature_in;
    const conn = c_ext.Curl_rtsp_get_conn(data);
    const rtspc: *rtsp_conn = @ptrCast(@alignCast(c_ext.Curl_conn_meta_get(conn, CURL_META_RTSP_CONN) orelse return CURLE_FAILED_INIT));
    const rtsp: *RTSP = @ptrCast(@alignCast(c_ext.Curl_meta_get(data, CURL_META_RTSP_EASY) orelse return CURLE_FAILED_INIT));
    const rtspreq = c_ext.Curl_rtsp_get_rtspreq(data);

    if (rtspreq == CURL_RTSPREQ_RECEIVE)
        premature = true;

    const result = c_ext.Curl_http_done(data, status, premature);

    if (status == CURLE_OK and result == CURLE_OK) {
        const cseq_sent = rtsp.CSeq_sent;
        const cseq_recv = rtsp.CSeq_recv;
        if (rtspreq != CURL_RTSPREQ_RECEIVE and cseq_sent != cseq_recv) {
            c_ext.Curl_failf(
                data,
                "The CSeq of this request %u did not match the response %u",
                cseq_sent,
                cseq_recv,
            );
            return CURLE_RTSP_CSEQ_ERROR;
        }
        if (rtspreq == CURL_RTSPREQ_RECEIVE and rtspc.rtp_channel == -1) {
            c_ext.Curl_infof(data, "Got an RTP Receive with a CSeq of %u", cseq_recv);
        }
        if (rtspreq == CURL_RTSPREQ_RECEIVE and c_ext.Curl_rtsp_get_eos_written(data)) {
            failf0(data, "Server prematurely closed the RTSP connection.");
            return CURLE_RECV_ERROR;
        }
    }

    return result;
}

fn checkHeaders(data: ?*Curl_easy, hdr: []const u8) ?[*:0]u8 {
    if (builtin.is_test) return null;
    return c_ext.Curl_checkheaders(data, hdr.ptr, hdr.len);
}

fn rtspSetupBody(data: ?*Curl_easy, rtspreq: u8, reqp: *dynbuf) CURLcode {
    if (builtin.is_test) return CURLE_OK;
    var result: CURLcode = CURLE_OK;
    if (rtspreq == CURL_RTSPREQ_ANNOUNCE or
        rtspreq == CURL_RTSPREQ_SET_PARAMETER or
        rtspreq == CURL_RTSPREQ_GET_PARAMETER)
    {
        var upload: bool = false;
        var infilesize: curl_off_t = 0;
        var postfields: ?[*]const u8 = null;
        var postfieldsize: curl_off_t = 0;
        var crlf: bool = false;
        c_ext.Curl_rtsp_get_body_info(data, &upload, &infilesize, &postfields, &postfieldsize, &crlf);

        var req_clen: curl_off_t = 0;
        if (upload) {
            req_clen = infilesize;
            c_ext.Curl_rtsp_set_httpreq(data, HTTPREQ_PUT);
            result = c_ext.Curl_creader_set_fread(data, req_clen);
            if (result != CURLE_OK)
                return result;
        } else {
            if (postfields) |pf| {
                const plen: usize = if (postfieldsize >= 0)
                    @intCast(postfieldsize)
                else
                    std.mem.len(@as([*:0]const u8, @ptrCast(pf)));
                req_clen = @intCast(plen);
                result = c_ext.Curl_creader_set_buf(data, pf, plen);
            } else if (infilesize >= 0) {
                req_clen = infilesize;
                result = c_ext.Curl_creader_set_fread(data, req_clen);
            } else {
                req_clen = 0;
                result = c_ext.Curl_creader_set_null(data);
            }
            if (result != CURLE_OK)
                return result;
        }

        if (req_clen > 0) {
            if (crlf) {
                failf0(data, "Cannot do CRLF conversions on upload");
                return CURLE_UPLOAD_FAILED;
            }
            if (checkHeaders(data, "Content-Length") == null) {
                result = curlx_dyn_addf(reqp, "Content-Length: %lld\r\n", @as(c_longlong, req_clen));
                if (result != CURLE_OK)
                    return result;
            }

            if (rtspreq == CURL_RTSPREQ_SET_PARAMETER or rtspreq == CURL_RTSPREQ_GET_PARAMETER) {
                if (checkHeaders(data, "Content-Type") == null) {
                    const ct = "Content-Type: text/parameters\r\n";
                    result = io_buffers.curlx_dyn_addn(reqp, ct.ptr, ct.len);
                    if (result != CURLE_OK)
                        return result;
                }
            }

            if (rtspreq == CURL_RTSPREQ_ANNOUNCE) {
                if (checkHeaders(data, "Content-Type") == null) {
                    const ct = "Content-Type: application/sdp\r\n";
                    result = io_buffers.curlx_dyn_addn(reqp, ct.ptr, ct.len);
                    if (result != CURLE_OK)
                        return result;
                }
            }
        } else if (rtspreq == CURL_RTSPREQ_GET_PARAMETER) {
            c_ext.Curl_rtsp_set_httpreq(data, HTTPREQ_HEAD);
            c_ext.Curl_rtsp_set_no_body(data, true);
        }
    } else {
        result = c_ext.Curl_creader_set_null(data);
    }
    return result;
}

const RtspSelect = struct {
    method: [*:0]const u8,
    no_body: bool,
};

const rtsp_methods = [_]RtspSelect{
    .{ .method = "OPTIONS", .no_body = true },
    .{ .method = "DESCRIBE", .no_body = false },
    .{ .method = "ANNOUNCE", .no_body = true },
    .{ .method = "SETUP", .no_body = true },
    .{ .method = "PLAY", .no_body = true },
    .{ .method = "PAUSE", .no_body = true },
    .{ .method = "TEARDOWN", .no_body = true },
    .{ .method = "GET_PARAMETER", .no_body = false },
    .{ .method = "SET_PARAMETER", .no_body = true },
    .{ .method = "RECORD", .no_body = true },
    .{ .method = "", .no_body = false }, // RECEIVE
};

fn pickMethod(data: ?*Curl_easy, rtspreq: u8, p: *?[*:0]const u8) CURLcode {
    if (rtspreq <= CURL_RTSPREQ_NONE or rtspreq >= CURL_RTSPREQ_LAST)
        return CURLE_BAD_FUNCTION_ARGUMENT;
    const entry = rtsp_methods[rtspreq - 1];
    p.* = entry.method;
    if (!builtin.is_test and data != null) {
        c_ext.Curl_rtsp_set_no_body(data, entry.no_body);
    }
    return CURLE_OK;
}

fn rtspHeaderAlloc(header_name: [*:0]const u8, value: ?[*:0]const u8, target: *?[*:0]u8) CURLcode {
    const val = value orelse return CURLE_OK;
    mem.free(target.*);
    target.* = curl_maprintf("%s: %s\r\n", header_name, val);
    if (target.* == null)
        return CURLE_OUT_OF_MEMORY;
    return CURLE_OK;
}

const RtspBlocks = struct {
    request: ?[*:0]const u8 = null,
    session_id: ?[*:0]const u8 = null,
    accept: ?[*:0]const u8 = null,
    range: ?[*:0]const u8 = null,
    stream_uri: [*:0]const u8 = "*",
    hd_proxy_auth: ?[*:0]const u8 = null,
    hd_auth: ?[*:0]const u8 = null,
    referrer: ?[*:0]u8 = null,
    accept_encoding: ?[*:0]u8 = null,
    transport: ?[*:0]u8 = null,
    transport_alloc: bool = false,
};

fn rtspSetupRequest(data: ?*Curl_easy, b: *RtspBlocks, rtspreq: u8) CURLcode {
    if (builtin.is_test) return CURLE_OK;
    var result: CURLcode = CURLE_OK;
    const conn = c_ext.Curl_rtsp_get_conn(data);

    var session_id: ?[*:0]const u8 = null;
    var stream_uri: ?[*:0]const u8 = null;
    var opt_transport: ?[*:0]const u8 = null;
    var opt_encoding: ?[*:0]const u8 = null;
    var opt_useragent: ?[*:0]const u8 = null;
    var opt_referer: ?[*:0]const u8 = null;
    var use_range: bool = false;
    var range_str: ?[*:0]const u8 = null;
    var rangeline_ptr: *?[*:0]u8 = undefined;

    c_ext.Curl_rtsp_get_request_info(
        data,
        &session_id,
        &stream_uri,
        &opt_transport,
        &opt_encoding,
        &opt_useragent,
        &opt_referer,
        &use_range,
        &range_str,
        &rangeline_ptr,
    );

    b.session_id = session_id;
    b.stream_uri = stream_uri orelse "*";

    b.transport = checkHeaders(data, "Transport");
    if (rtspreq == CURL_RTSPREQ_SETUP and b.transport == null) {
        if (opt_transport) |tr| {
            result = rtspHeaderAlloc("Transport", tr, &b.transport);
            if (result != CURLE_OK)
                return result;
            b.transport_alloc = true;
        } else {
            failf0(data, "Refusing to issue an RTSP SETUP without a Transport: header.");
            return CURLE_BAD_FUNCTION_ARGUMENT;
        }
    }

    if (rtspreq == CURL_RTSPREQ_DESCRIBE) {
        b.accept = if (checkHeaders(data, "Accept") != null) null else "Accept: application/sdp\r\n";

        if (checkHeaders(data, "Accept-Encoding") == null and opt_encoding != null) {
            result = rtspHeaderAlloc("Accept-Encoding", opt_encoding, &b.accept_encoding);
            if (result != CURLE_OK)
                return result;
        }
    }

    result = c_ext.Curl_http_output_auth(
        data,
        conn,
        b.request orelse "",
        HTTPREQ_GET,
        b.stream_uri,
        null,
        false,
    );
    if (result != CURLE_OK)
        return result;

    c_ext.Curl_rtsp_get_auth_headers(data, &b.hd_proxy_auth, &b.hd_auth);

    if (opt_referer != null and checkHeaders(data, "Referer") == null) {
        b.referrer = curl_maprintf("Referer: %s\r\n", opt_referer.?);
        if (b.referrer == null)
            result = CURLE_OUT_OF_MEMORY;
    }

    if (result == CURLE_OK and use_range and
        (rtspreq == CURL_RTSPREQ_PLAY or
            rtspreq == CURL_RTSPREQ_PAUSE or
            rtspreq == CURL_RTSPREQ_RECORD) and
        checkHeaders(data, "Range") == null and range_str != null)
    {
        result = rtspHeaderAlloc("Range", range_str, rangeline_ptr);
        if (result == CURLE_OK)
            b.range = rangeline_ptr.*;
    }

    return result;
}

fn rtspDo(data: ?*Curl_easy, done: *bool) callconv(.c) CURLcode {
    if (builtin.is_test) return CURLE_OK;
    var result: CURLcode = CURLE_OK;
    const rtspreq = c_ext.Curl_rtsp_get_rtspreq(data);
    const rtsp: *RTSP = @ptrCast(@alignCast(c_ext.Curl_meta_get(data, CURL_META_RTSP_EASY) orelse {
        done.* = true;
        return CURLE_FAILED_INIT;
    }));
    var req_buffer: dynbuf = undefined;
    var block = RtspBlocks{};

    done.* = true;

    io_buffers.curlx_dyn_init(&req_buffer, DYN_RTSP_REQ_HEADER);
    defer {
        if (block.transport_alloc)
            mem.free(block.transport);
        mem.free(block.accept_encoding);
        mem.free(block.referrer);
        io_buffers.curlx_dyn_free(&req_buffer);
    }

    rtsp.CSeq_sent = c_ext.Curl_rtsp_get_next_client_cseq(data);
    rtsp.CSeq_recv = 0;

    result = pickMethod(data, rtspreq, &block.request);
    if (result != CURLE_OK)
        return result;

    if (rtspreq == CURL_RTSPREQ_RECEIVE) {
        c_ext.Curl_xfer_setup_recv(data, FIRSTSOCKET, -1);
        return result;
    }

    result = rtspSetupRequest(data, &block, rtspreq);
    if (result != CURLE_OK)
        return result;

    if (block.session_id != null and !c_ext.Curl_rtsp_allow_session_to_host(data)) {
        block.session_id = null;
    }

    if (checkHeaders(data, "CSeq") != null) {
        failf0(data, "CSeq cannot be set as a custom header.");
        return CURLE_RTSP_CSEQ_ERROR;
    }
    if (checkHeaders(data, "Session") != null) {
        failf0(data, "Session ID cannot be set as a custom header.");
        return CURLE_BAD_FUNCTION_ARGUMENT;
    }

    result = curlx_dyn_addf(
        &req_buffer,
        "%s %s RTSP/1.0\r\nCSeq: %u\r\n",
        block.request orelse "",
        block.stream_uri,
        rtsp.CSeq_sent,
    );
    if (result != CURLE_OK)
        return result;

    if (block.session_id) |sid| {
        result = curlx_dyn_addf(&req_buffer, "Session: %s\r\n", sid);
        if (result != CURLE_OK)
            return result;
    }

    const empty: [*:0]const u8 = "";
    result = curlx_dyn_addf(
        &req_buffer,
        "%s%s%s%s%s",
        if (block.transport) |t| @as([*:0]const u8, t) else empty,
        block.accept orelse empty,
        if (block.accept_encoding) |ae| @as([*:0]const u8, ae) else empty,
        block.range orelse empty,
        if (block.referrer) |rf| @as([*:0]const u8, rf) else empty,
    );

    var dummy_sid: ?[*:0]const u8 = null;
    var dummy_uri: ?[*:0]const u8 = null;
    var dummy_tr: ?[*:0]const u8 = null;
    var dummy_enc: ?[*:0]const u8 = null;
    var useragent: ?[*:0]const u8 = null;
    var dummy_ref: ?[*:0]const u8 = null;
    var dummy_use_range: bool = false;
    var dummy_range: ?[*:0]const u8 = null;
    var dummy_rangeline: *?[*:0]u8 = undefined;
    c_ext.Curl_rtsp_get_request_info(
        data,
        &dummy_sid,
        &dummy_uri,
        &dummy_tr,
        &dummy_enc,
        &useragent,
        &dummy_ref,
        &dummy_use_range,
        &dummy_range,
        &dummy_rangeline,
    );

    if (result == CURLE_OK) {
        if (useragent) |ua| {
            if (ua[0] != 0 and checkHeaders(data, "User-Agent") == null) {
                result = curlx_dyn_addf(&req_buffer, "User-Agent: %s\r\n", ua);
            }
        }
    }

    if (result == CURLE_OK) {
        result = curlx_dyn_addf(
            &req_buffer,
            "%s%s",
            block.hd_proxy_auth orelse empty,
            block.hd_auth orelse empty,
        );
    }
    if (result != CURLE_OK)
        return result;

    if (rtspreq == CURL_RTSPREQ_SETUP or rtspreq == CURL_RTSPREQ_DESCRIBE) {
        result = c_ext.Curl_add_timecondition(data, &req_buffer);
        if (result != CURLE_OK)
            return result;
    }

    result = c_ext.Curl_add_custom_headers(data, false, HTTPVERSION, &req_buffer);
    if (result != CURLE_OK)
        return result;

    result = rtspSetupBody(data, rtspreq, &req_buffer);
    if (result != CURLE_OK)
        return result;

    result = io_buffers.curlx_dyn_addn(&req_buffer, "\r\n", 2);
    if (result != CURLE_OK)
        return result;

    c_ext.Curl_xfer_setup_sendrecv(data, FIRSTSOCKET, -1);

    result = c_ext.Curl_req_send(data, &req_buffer, HTTPVERSION);
    if (result != CURLE_OK) {
        failf0(data, "Failed sending RTSP request");
        return result;
    }

    c_ext.Curl_rtsp_inc_next_client_cseq(data);

    const writebytecount = c_ext.Curl_rtsp_get_writebytecount(data);
    if (writebytecount != 0) {
        c_ext.Curl_pgrsSetUploadCounter(data, writebytecount);
        result = c_ext.Curl_pgrsUpdate(data);
    }

    return result;
}

fn rtpWriteBodyJunk(
    data: ?*Curl_easy,
    rtspc: *rtsp_conn,
    junk_slice: []const u8,
) CURLcode {
    if (junk_slice.len == 0 or builtin.is_test) return CURLE_OK;
    var headerline: c_int = 0;
    var header: bool = false;
    var req_size: curl_off_t = 0;
    var bytecount: curl_off_t = 0;
    var req_done: bool = false;
    c_ext.Curl_rtsp_get_req_state(data, &headerline, &header, &req_size, &bytecount, &req_done);

    const in_body = (headerline != 0 and !rtspc.in_header) and
        (req_size >= 0) and
        (bytecount < req_size);
    const body_remain: curl_off_t = if (in_body) (req_size - bytecount) else 0;
    if (body_remain > 0) {
        var blen = junk_slice.len;
        const remain_uz = std.math.cast(usize, body_remain) orelse blen;
        if (blen > remain_uz)
            blen = remain_uz;
        return c_ext.Curl_client_write(data, CLIENTWRITE_BODY, junk_slice.ptr, blen);
    }
    return CURLE_OK;
}

fn rtpClientWrite(data: ?*Curl_easy, ptr: [*]const u8, len: usize) CURLcode {
    if (len == 0) {
        failf0(data, "Cannot write a 0 size RTP packet.");
        return CURLE_WRITE_ERROR;
    }
    if (builtin.is_test) return CURLE_OK;

    var writeit_opt: ?curl_write_callback = null;
    var user_ptr: ?*anyopaque = null;
    c_ext.Curl_rtsp_get_rtp_writer(data, &writeit_opt, &user_ptr);
    const writeit = writeit_opt orelse return CURLE_WRITE_ERROR;

    var guard: Curl_mapi_guard = .{};
    c_ext.Curl_cbapi_enter(&guard, data, null, CURL_CBAPI_FN_easy_fwrite_rtp);
    const wrote = writeit(@constCast(ptr), 1, len, user_ptr);
    c_ext.Curl_cbapi_leave(&guard);

    if (wrote == CURL_WRITEFUNC_PAUSE) {
        failf0(data, "Cannot pause RTP");
        return CURLE_WRITE_ERROR;
    }
    if (wrote != len) {
        failf0(data, "Failed writing RTP data");
        return CURLE_WRITE_ERROR;
    }
    return CURLE_OK;
}

fn rtspFilterRtp(
    data: ?*Curl_easy,
    rtspc: *rtsp_conn,
    buf_in: [*]const u8,
    blen_in: usize,
    pconsumed: *usize,
) CURLcode {
    return rtspFilterRtpWithMask(data, rtspc, buf_in, blen_in, pconsumed, null);
}

fn rtspFilterRtpWithMask(
    data: ?*Curl_easy,
    rtspc: *rtsp_conn,
    buf_in: [*]const u8,
    blen_in: usize,
    pconsumed: *usize,
    test_mask: ?*const [32]u8,
) CURLcode {
    var result: CURLcode = CURLE_OK;
    var skip_len: usize = 0;
    const full_slice: []const u8 = buf_in[0..blen_in];
    var buf_slice: []const u8 = full_slice;
    var pos: usize = 0;

    pconsumed.* = 0;
    while (buf_slice.len != 0) {
        var headerline: c_int = 0;
        var header: bool = false;
        var req_size: curl_off_t = 0;
        var bytecount: curl_off_t = 0;
        var req_done: bool = false;
        var rtspreq: u8 = CURL_RTSPREQ_NONE;
        if (!builtin.is_test and data != null) {
            c_ext.Curl_rtsp_get_req_state(data, &headerline, &header, &req_size, &bytecount, &req_done);
            rtspreq = c_ext.Curl_rtsp_get_rtspreq(data);
        }
        const in_body = (headerline != 0 and !rtspc.in_header) and
            (req_size >= 0) and
            (bytecount < req_size);

        switch (rtspc.state) {
            .SKIP => {
                while (buf_slice.len != 0 and buf_slice[0] != '$') {
                    if (!in_body and buf_slice[0] == 'R' and rtspreq != CURL_RTSPREQ_RECEIVE) {
                        const cmp_len = @min(buf_slice.len, 5);
                        if (std.mem.eql(u8, buf_slice[0..cmp_len], "RTSP/"[0..cmp_len])) {
                            rtspc.state = .SKIP;
                            rtspc.in_header = true;
                            if (result == CURLE_OK and skip_len != 0 and skip_len <= pos) {
                                result = rtpWriteBodyJunk(data, rtspc, full_slice[pos - skip_len .. pos]);
                            }
                            return result;
                        }
                    }
                    pconsumed.* += 1;
                    buf_slice = buf_slice[1..];
                    pos += 1;
                    skip_len += 1;
                }
                if (buf_slice.len != 0 and buf_slice[0] == '$') {
                    if (skip_len != 0 and skip_len <= pos) {
                        result = rtpWriteBodyJunk(data, rtspc, full_slice[pos - skip_len .. pos]);
                        skip_len = 0;
                        if (result != CURLE_OK)
                            break;
                    }
                    if (io_buffers.curlx_dyn_addn(&rtspc.buf, buf_slice.ptr, 1) != CURLE_OK) {
                        result = CURLE_OUT_OF_MEMORY;
                        break;
                    }
                    pconsumed.* += 1;
                    buf_slice = buf_slice[1..];
                    pos += 1;
                    rtspc.state = .CHANNEL;
                }
            },
            .CHANNEL => {
                const ch: u8 = buf_slice[0];
                const channel_idx: usize = @as(usize, ch) / 8;
                if (channel_idx >= 32)
                    return CURLE_WEIRD_SERVER_REPLY;
                const off: u3 = @truncate(@as(usize, ch) % 8);
                var mask_bit: u8 = 0;
                if (test_mask) |tm| {
                    mask_bit = tm[channel_idx] & (@as(u8, 1) << off);
                } else if (!builtin.is_test and data != null) {
                    const mask = c_ext.Curl_rtsp_get_rtp_channel_mask(data)[0..32];
                    mask_bit = mask[channel_idx] & (@as(u8, 1) << off);
                }
                if (mask_bit == 0) {
                    rtspc.state = .SKIP;
                    if (pconsumed.* == 0) {
                        if (io_buffers.curlx_dyn_ptr(&rtspc.buf)) |dptr| {
                            result = rtpWriteBodyJunk(data, rtspc, dptr[0..1]);
                            if (result != CURLE_OK)
                                break;
                        }
                    } else {
                        skip_len = 1;
                    }
                    io_buffers.curlx_dyn_free(&rtspc.buf);
                    continue;
                }
                rtspc.rtp_channel = @intCast(ch);
                if (io_buffers.curlx_dyn_addn(&rtspc.buf, buf_slice.ptr, 1) != CURLE_OK) {
                    result = CURLE_OUT_OF_MEMORY;
                    break;
                }
                pconsumed.* += 1;
                buf_slice = buf_slice[1..];
                pos += 1;
                rtspc.state = .LEN;
            },
            .LEN => {
                const rtp_len = io_buffers.curlx_dyn_len(&rtspc.buf);
                if (io_buffers.curlx_dyn_addn(&rtspc.buf, buf_slice.ptr, 1) != CURLE_OK) {
                    result = CURLE_OUT_OF_MEMORY;
                    break;
                }
                pconsumed.* += 1;
                buf_slice = buf_slice[1..];
                pos += 1;
                if (rtp_len == 2)
                    continue;
                const rtp_ptr = io_buffers.curlx_dyn_ptr(&rtspc.buf) orelse return CURLE_WEIRD_SERVER_REPLY;
                const rtp_hdr = rtp_ptr[0..4];
                rtspc.rtp_len = rtpPktLength(rtp_hdr) + 4;
                if (rtspc.rtp_len == 4) {
                    result = rtpClientWrite(data, rtp_hdr.ptr, rtspc.rtp_len);
                    io_buffers.curlx_dyn_free(&rtspc.buf);
                    rtspc.state = .SKIP;
                    if (result != CURLE_OK)
                        break;
                    continue;
                }
                rtspc.state = .DATA;
            },
            .DATA => {
                const rtp_len = io_buffers.curlx_dyn_len(&rtspc.buf);
                const needed = rtspc.rtp_len - rtp_len;
                if (needed <= buf_slice.len) {
                    if (io_buffers.curlx_dyn_addn(&rtspc.buf, buf_slice.ptr, needed) != CURLE_OK) {
                        result = CURLE_OUT_OF_MEMORY;
                        break;
                    }
                    pconsumed.* += needed;
                    buf_slice = buf_slice[needed..];
                    pos += needed;
                    const rtp_ptr = io_buffers.curlx_dyn_ptr(&rtspc.buf) orelse return CURLE_WEIRD_SERVER_REPLY;
                    const rtp_pkt = rtp_ptr[0..rtspc.rtp_len];
                    result = rtpClientWrite(data, rtp_pkt.ptr, rtp_pkt.len);
                    io_buffers.curlx_dyn_free(&rtspc.buf);
                    rtspc.state = .SKIP;
                    if (result != CURLE_OK)
                        break;
                } else {
                    if (io_buffers.curlx_dyn_addn(&rtspc.buf, buf_slice.ptr, buf_slice.len) != CURLE_OK) {
                        result = CURLE_OUT_OF_MEMORY;
                        break;
                    }
                    pconsumed.* += buf_slice.len;
                    pos += buf_slice.len;
                    buf_slice = buf_slice[buf_slice.len..];
                }
            },
        }
    }

    if (result == CURLE_OK and skip_len != 0 and skip_len <= pos) {
        result = rtpWriteBodyJunk(data, rtspc, full_slice[pos - skip_len .. pos]);
    }
    return result;
}

fn rtspRtpWriteResp(
    data: ?*Curl_easy,
    buf_in: [*]const u8,
    blen_in: usize,
    is_eos: bool,
) callconv(.c) CURLcode {
    if (builtin.is_test) return CURLE_OK;
    const conn = c_ext.Curl_rtsp_get_conn(data);
    const rtspc: *rtsp_conn = @ptrCast(@alignCast(c_ext.Curl_conn_meta_get(conn, CURL_META_RTSP_CONN) orelse return CURLE_FAILED_INIT));
    var result: CURLcode = CURLE_OK;
    var consumed: usize = 0;
    var buf_slice: []const u8 = buf_in[0..blen_in];

    var headerline: c_int = 0;
    var req_header: bool = false;
    var req_size: curl_off_t = 0;
    var bytecount: curl_off_t = 0;
    var req_done: bool = false;
    c_ext.Curl_rtsp_get_req_state(data, &headerline, &req_header, &req_size, &bytecount, &req_done);

    if (!req_header)
        rtspc.in_header = false;

    if (buf_slice.len != 0) {
        if (!rtspc.in_header) {
            result = rtspFilterRtp(data, rtspc, buf_slice.ptr, buf_slice.len, &consumed);
            if (result != CURLE_OK)
                return finishWriteResp(data, rtspc, result);
            buf_slice = buf_slice[consumed..];
        }

        c_ext.Curl_rtsp_get_req_state(data, &headerline, &req_header, &req_size, &bytecount, &req_done);
        if (req_header and buf_slice.len != 0) {
            rtspc.in_header = true;
            result = c_ext.Curl_http_write_resp_hds(data, buf_slice.ptr, buf_slice.len, &consumed);
            if (result != CURLE_OK)
                return finishWriteResp(data, rtspc, result);

            buf_slice = buf_slice[consumed..];

            c_ext.Curl_rtsp_get_req_state(data, &headerline, &req_header, &req_size, &bytecount, &req_done);
            if (!req_header)
                rtspc.in_header = false;

            if (!rtspc.in_header) {
                if (req_size <= -1) {
                    c_ext.Curl_rtsp_set_req_size_zero_done(data);
                }
                result = rtspFilterRtp(data, rtspc, buf_slice.ptr, buf_slice.len, &consumed);
                if (result != CURLE_OK)
                    return finishWriteResp(data, rtspc, result);
                buf_slice = buf_slice[consumed..];
            }
        }

        if (rtspc.state != .SKIP)
            c_ext.Curl_rtsp_set_req_done_false(data);

        if (result == CURLE_OK and (is_eos or buf_slice.len != 0)) {
            result = c_ext.Curl_client_write(
                data,
                CLIENTWRITE_BODY | (if (is_eos) CLIENTWRITE_EOS else 0),
                buf_slice.ptr,
                buf_slice.len,
            );
        }
    }

    return finishWriteResp(data, rtspc, result);
}

fn finishWriteResp(data: ?*Curl_easy, rtspc: *rtsp_conn, result: CURLcode) CURLcode {
    if (!builtin.is_test and data != null) {
        if (c_ext.Curl_rtsp_get_rtspreq(data) == CURL_RTSPREQ_RECEIVE and
            rtspc.state == .SKIP)
        {
            c_ext.Curl_rtsp_set_download_done(data);
        }
    }
    return result;
}

fn rtspRtpWriteRespHd(
    data: ?*Curl_easy,
    buf: [*]const u8,
    blen: usize,
    is_eos: bool,
) callconv(.c) CURLcode {
    return rtspRtpWriteResp(data, buf, blen, is_eos);
}

fn checkPrefix(prefix: []const u8, str: [*:0]const u8) bool {
    return primitives.curl_strnequal(str, @ptrCast(prefix.ptr), prefix.len) != 0;
}

pub fn rtspParseTransportMask(
    data: ?*Curl_easy,
    transport: [*:0]const u8,
    rtp_channel_mask: *[32]u8,
) CURLcode {
    var start_opt: ?[*:0]const u8 = transport;
    while (start_opt) |s| {
        if (s[0] == 0)
            break;
        var cur: ?[*:0]const u8 = s;
        curlx_str_passblanks(&cur);
        const start = cur.?;
        const span = std.mem.span(start);
        const semi_idx = std.mem.indexOfScalar(u8, span, ';');
        if (checkPrefix("interleaved=", start)) {
            var chan1: curl_off_t = 0;
            var chan2: curl_off_t = 0;
            var p: ?[*:0]const u8 = start + 12;
            if (curlx_str_number(&p, &chan1, 255) == 0) {
                chan2 = chan1;
                if (curlx_str_single(&p, '-') == 0 and curlx_str_number(&p, &chan2, 255) != 0) {
                    if (!builtin.is_test and data != null) {
                        c_ext.Curl_infof(
                            data,
                            "Unable to read the interleaved parameter from Transport header: [%s]",
                            transport,
                        );
                    }
                    chan2 = chan1;
                }
                var chan = chan1;
                while (chan <= chan2) : (chan += 1) {
                    const ch = std.math.cast(u8, chan) orelse break;
                    const channel_idx: usize = @as(usize, ch) / 8;
                    if (channel_idx >= rtp_channel_mask.len) break;
                    const off: u3 = @truncate(@as(usize, ch) % 8);
                    rtp_channel_mask[channel_idx] |= @as(u8, 1) << off;
                }
            } else {
                if (!builtin.is_test and data != null) {
                    c_ext.Curl_infof(
                        data,
                        "Unable to read the interleaved parameter from Transport header: [%s]",
                        transport,
                    );
                }
            }
            break;
        }
        if (semi_idx) |idx| {
            start_opt = start + idx + 1;
        } else {
            start_opt = null;
        }
    }
    return CURLE_OK;
}

pub export fn Curl_rtsp_parseheader(
    data: ?*Curl_easy,
    header: [*:0]const u8,
) callconv(.c) CURLcode {
    if (checkPrefix("CSeq:", header)) {
        if (builtin.is_test) return CURLE_OK;
        var cseq: curl_off_t = 0;
        const rtsp: *RTSP = @ptrCast(@alignCast(c_ext.Curl_meta_get(data, CURL_META_RTSP_EASY) orelse return CURLE_FAILED_INIT));
        var p: ?[*:0]const u8 = header + 5;
        curlx_str_passblanks(&p);
        if (curlx_str_number(&p, &cseq, std.math.maxInt(u32)) != 0) {
            c_ext.Curl_failf(data, "Unable to read the CSeq header: [%s]", header);
            return CURLE_RTSP_CSEQ_ERROR;
        }
        const cseq_u32: u32 = @intCast(cseq);
        rtsp.CSeq_recv = cseq_u32;
        c_ext.Curl_rtsp_set_cseq_recv(data, cseq_u32);
    } else if (checkPrefix("Session:", header)) {
        if (builtin.is_test) return CURLE_OK;
        var start_opt: ?[*:0]const u8 = header + 8;
        curlx_str_passblanks(&start_opt);
        const start = start_opt.?;
        if (start[0] == 0) {
            failf0(data, "Got a blank Session ID");
            return CURLE_RTSP_SESSION_ERROR;
        }
        var idlen: usize = 0;
        while (start[idlen] > ' ' and start[idlen] != ';') : (idlen += 1) {}

        if (c_ext.Curl_rtsp_get_session_id(data)) |existing| {
            const existing_slice = std.mem.span(existing);
            if (!std.mem.eql(u8, existing_slice, start[0..idlen])) {
                c_ext.Curl_failf(
                    data,
                    "Got RTSP Session ID Line [%s], but wanted ID [%s]",
                    start,
                    existing,
                );
                return CURLE_RTSP_SESSION_ERROR;
            }
        } else {
            const dup = memdup0(start, idlen) orelse return CURLE_OUT_OF_MEMORY;
            if (c_ext.Curl_rtsp_set_session_id(data, @ptrCast(dup)) != CURLE_OK)
                return CURLE_OUT_OF_MEMORY;
        }
    } else if (checkPrefix("Transport:", header)) {
        if (builtin.is_test) return CURLE_OK;
        const mask_ptr: *[32]u8 = @ptrCast(c_ext.Curl_rtsp_get_rtp_channel_mask(data));
        return rtspParseTransportMask(data, header + 10, mask_ptr);
    }
    return CURLE_OK;
}

pub export const Curl_protocol_rtsp: Curl_protocol = .{
    .setup_connection = &rtspSetupConnection,
    .do_it = &rtspDo,
    .done = &rtspDone,
    .do_more = null,
    .connect_it = &rtspConnect,
    .connecting = null,
    .doing = null,
    .proto_pollset = null,
    .doing_pollset = &rtspDoPollset,
    .domore_pollset = null,
    .perform_pollset = if (builtin.is_test) null else &c_ext.Curl_http_perform_pollset,
    .disconnect = null,
    .write_resp = &rtspRtpWriteResp,
    .write_resp_hd = &rtspRtpWriteRespHd,
    .connection_is_dead = &rtspConnIsDead,
    .attach = null,
    .follow = if (builtin.is_test) null else &c_ext.Curl_http_follow,
};

// ============================================================================
// Unit Tests
// ============================================================================

test "Curl_sasl_decode_mech and Curl_sasl_parse_url_auth_option" {
    var mech_len: usize = 0;

    try std.testing.expectEqual(SASL_MECH_PLAIN, Curl_sasl_decode_mech("PLAIN", 5, &mech_len));
    try std.testing.expectEqual(@as(usize, 5), mech_len);

    try std.testing.expectEqual(SASL_MECH_SCRAM_SHA_256, Curl_sasl_decode_mech("SCRAM-SHA-256 ", 14, &mech_len));
    try std.testing.expectEqual(@as(usize, 13), mech_len);

    // Reject partial prefix followed by uppercase/digit/hyphen
    try std.testing.expectEqual(@as(c_ushort, 0), Curl_sasl_decode_mech("PLAINX", 6, &mech_len));
    try std.testing.expectEqual(@as(c_ushort, 0), Curl_sasl_decode_mech("SCRAM-SHA-1-PLUS", 16, &mech_len));

    const proto = SASLproto{
        .service = "imap",
        .defmechs = SASL_AUTH_DEFAULT,
    };
    var sasl = SASL{};
    Curl_sasl_init_zig(&sasl, null, &proto, CURLAUTH_BASIC);
    try std.testing.expectEqual(SASL_AUTH_DEFAULT, sasl.prefmech);
    try std.testing.expect(saslGetResetPrefs(&sasl));

    try std.testing.expectEqual(CURLE_OK, Curl_sasl_parse_url_auth_option(&sasl, "XOAUTH2", 7));
    try std.testing.expectEqual(SASL_MECH_XOAUTH2, sasl.prefmech);
    try std.testing.expect(!saslGetResetPrefs(&sasl));

    try std.testing.expectEqual(CURLE_OK, Curl_sasl_parse_url_auth_option(&sasl, "PLAIN", 5));
    try std.testing.expectEqual(SASL_MECH_XOAUTH2 | SASL_MECH_PLAIN, sasl.prefmech);

    try std.testing.expectEqual(CURLE_OK, Curl_sasl_parse_url_auth_option(&sasl, "*", 1));
    try std.testing.expectEqual(SASL_AUTH_DEFAULT, sasl.prefmech);

    try std.testing.expectEqual(CURLE_URL_MALFORMAT, Curl_sasl_parse_url_auth_option(&sasl, "", 0));
    try std.testing.expectEqual(CURLE_URL_MALFORMAT, Curl_sasl_parse_url_auth_option(&sasl, "INVALID", 7));
}

test "Curl_ftp_parselist_data_alloc, free, permission parser, and wildcard init/dtor" {
    var parser = Curl_ftp_parselist_data_alloc();
    try std.testing.expect(parser != null);
    try std.testing.expectEqual(CURLE_OK, Curl_ftp_parselist_geterror(parser.?));
    Curl_ftp_parselist_data_free(&parser);
    try std.testing.expect(parser == null);

    try std.testing.expectEqual(@as(c_uint, 0o755), ftpPlGetPermission("rwxr-xr-x"));
    try std.testing.expectEqual(@as(c_uint, 0o644), ftpPlGetPermission("rw-r--r--"));
    try std.testing.expectEqual(@as(c_uint, 0o4755), ftpPlGetPermission("rwsr-xr-x"));
    try std.testing.expectEqual(@as(c_uint, 0o1777), ftpPlGetPermission("rwxrwxrwt"));

    var wc_ptr: ?*WildcardData = @ptrCast(@alignCast(mem.calloc(1, @sizeOf(WildcardData))));
    try std.testing.expect(wc_ptr != null);
    Curl_wildcard_init(wc_ptr.?);
    try std.testing.expectEqual(CURLWC_INIT, wc_ptr.?.state);
    try std.testing.expect(Curl_ftp_listmode_zig(null, true, wc_ptr));
    wc_ptr.?.state = CURLWC_DONE;
    try std.testing.expect(!Curl_ftp_listmode_zig(null, true, wc_ptr));
    Curl_wildcard_dtor(&wc_ptr);
    try std.testing.expect(wc_ptr == null);
}

test "RTSP transport channel mask parser and protocol table" {
    var mask: [32]u8 = @splat(0);
    try std.testing.expectEqual(
        CURLE_OK,
        rtspParseTransportMask(null, "RTP/AVP/TCP;unicast;interleaved=2-3", &mask),
    );
    try std.testing.expectEqual(@as(u8, (1 << 2) | (1 << 3)), mask[0]);

    try std.testing.expect(Curl_protocol_rtsp.setup_connection != null);
    try std.testing.expect(Curl_protocol_rtsp.do_it != null);
    try std.testing.expect(Curl_protocol_rtsp.done != null);
    try std.testing.expect(Curl_protocol_rtsp.connect_it != null);
    try std.testing.expect(Curl_protocol_rtsp.write_resp != null);
    try std.testing.expect(Curl_protocol_rtsp.write_resp_hd != null);
    try std.testing.expect(Curl_protocol_rtsp.connection_is_dead != null);
}

test "RTSP interleaved $ RTP packet boundary and malformed channel handling" {
    var rtspc = rtsp_conn{
        .buf = undefined,
        .rtp_channel = 0,
        .rtp_len = 0,
        .state = .SKIP,
        .in_header = false,
    };
    io_buffers.curlx_dyn_init(&rtspc.buf, MAX_RTP_BUFFERSIZE);
    defer io_buffers.curlx_dyn_free(&rtspc.buf);

    var mask: [32]u8 = @splat(0);
    // Unmasked channel 0xff ('$' followed by 0xff) falls back to SKIP cleanly without OOB
    const unmasked = "prefix$\xffRTSP/1.0 200 OK\r\n";
    var consumed: usize = 0;
    try std.testing.expectEqual(
        CURLE_OK,
        rtspFilterRtpWithMask(null, &rtspc, unmasked.ptr, unmasked.len, &consumed, &mask),
    );
    try std.testing.expectEqual(@as(usize, 8), consumed);
    try std.testing.expectEqual(RtpParseState.SKIP, rtspc.state);
    try std.testing.expect(rtspc.in_header);

    // Enable channel 255 (idx = 31, off = 7) and split RTP packet across boundaries
    mask[31] = 1 << 7;
    rtspc.in_header = false;
    const part1 = [_]u8{ '$', 255, 0x00 };
    consumed = 0;
    try std.testing.expectEqual(
        CURLE_OK,
        rtspFilterRtpWithMask(null, &rtspc, &part1, part1.len, &consumed, &mask),
    );
    try std.testing.expectEqual(@as(usize, 3), consumed);
    try std.testing.expectEqual(RtpParseState.LEN, rtspc.state);
    try std.testing.expectEqual(@as(c_int, 255), rtspc.rtp_channel);

    // Complete length (4 bytes payload -> rtp_len = 8) + 2 payload bytes
    const part2 = [_]u8{ 0x04, 'A', 'B' };
    consumed = 0;
    try std.testing.expectEqual(
        CURLE_OK,
        rtspFilterRtpWithMask(null, &rtspc, &part2, part2.len, &consumed, &mask),
    );
    try std.testing.expectEqual(@as(usize, 3), consumed);
    try std.testing.expectEqual(RtpParseState.DATA, rtspc.state);
    try std.testing.expectEqual(@as(usize, 8), rtspc.rtp_len);

    // Final 2 payload bytes complete the RTP packet and return to SKIP
    const part3 = [_]u8{ 'C', 'D' };
    consumed = 0;
    try std.testing.expectEqual(
        CURLE_OK,
        rtspFilterRtpWithMask(null, &rtspc, &part3, part3.len, &consumed, &mask),
    );
    try std.testing.expectEqual(@as(usize, 2), consumed);
    try std.testing.expectEqual(RtpParseState.SKIP, rtspc.state);
}
