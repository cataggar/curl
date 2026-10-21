const std = @import("std");
const builtin = @import("builtin");
const backend_options = @import("backend_options");
const mem = @import("mem.zig");
const bufref_mod = @import("io_buffers.zig");
const containers = @import("containers.zig");
const cookie_getinfo_trc = @import("cookie_getinfo_trc.zig");
const curlx_parse = @import("curlx_parse.zig");
const format_parse = @import("format_parse.zig");
const primitives = @import("primitives.zig");
const setopt = @import("setopt.zig");

const alloc = struct {
    pub const Curl_calloc = mem.calloc;
    pub const Curl_free = mem.free;
    pub const Curl_strdup = mem.strdup;
};

const is_windows = builtin.os.tag == .windows;
const ldap_backend = if (@hasDecl(backend_options, "ldap")) backend_options.ldap else .none;
const use_openldap = ldap_backend == .openldap;
const use_legacy_ldap = ldap_backend == .ldap or ldap_backend == .winldap;
const use_win32_ldap = is_windows or ldap_backend == .winldap;
const use_ssl = backend_options.ssl != .none;
const has_ldap = if (@hasDecl(backend_options, "has_ldap")) backend_options.has_ldap else false;
const has_ldaps = if (@hasDecl(backend_options, "has_ldaps")) backend_options.has_ldaps else false;

pub const CURLcode = c_uint;
pub const CURLE_OK: CURLcode = 0;
pub const CURLE_UNSUPPORTED_PROTOCOL: CURLcode = 1;
pub const CURLE_FAILED_INIT: CURLcode = 2;
pub const CURLE_URL_MALFORMAT: CURLcode = 3;
pub const CURLE_NOT_BUILT_IN: CURLcode = 4;
pub const CURLE_COULDNT_CONNECT: CURLcode = 7;
pub const CURLE_WEIRD_SERVER_REPLY: CURLcode = 8;
pub const CURLE_REMOTE_ACCESS_DENIED: CURLcode = 9;
pub const CURLE_OUT_OF_MEMORY: CURLcode = 27;
pub const CURLE_OPERATION_TIMEDOUT: CURLcode = 28;
pub const CURLE_LDAP_CANNOT_BIND: CURLcode = 38;
pub const CURLE_LDAP_SEARCH_FAILED: CURLcode = 39;
pub const CURLE_ABORTED_BY_CALLBACK: CURLcode = 42;
pub const CURLE_BAD_FUNCTION_ARGUMENT: CURLcode = 43;
pub const CURLE_TOO_MANY_REDIRECTS: CURLcode = 47;
pub const CURLE_GOT_NOTHING: CURLcode = 52;
pub const CURLE_SEND_ERROR: CURLcode = 55;
pub const CURLE_RECV_ERROR: CURLcode = 56;
pub const CURLE_SSL_CERTPROBLEM: CURLcode = 58;
pub const CURLE_PEER_FAILED_VERIFICATION: CURLcode = 60;
pub const CURLE_BAD_CONTENT_ENCODING: CURLcode = 61;
pub const CURLE_FILESIZE_EXCEEDED: CURLcode = 63;
pub const CURLE_USE_SSL_FAILED: CURLcode = 64;
pub const CURLE_LOGIN_DENIED: CURLcode = 67;
pub const CURLE_REMOTE_DISK_FULL: CURLcode = 70;
pub const CURLE_REMOTE_FILE_EXISTS: CURLcode = 73;
pub const CURLE_SSL_CACERT_BADFILE: CURLcode = 77;
pub const CURLE_REMOTE_FILE_NOT_FOUND: CURLcode = 78;
pub const CURLE_AGAIN: CURLcode = 81;
pub const CURLE_AUTH_ERROR: CURLcode = 94;
pub const CURLE_SETOPT_OPTION_SYNTAX: CURLcode = 98;

pub const curl_off_t = i64;
pub const curl_prot_t = u32;
pub const curl_socket_t = if (is_windows) usize else c_int;
pub const CURL_SOCKET_BAD: curl_socket_t = if (is_windows)
    std.math.maxInt(curl_socket_t)
else
    -1;
pub const FIRSTSOCKET: i8 = 0;

pub const CURLPROTO_LDAP: curl_prot_t = 1 << 7;
pub const CURLPROTO_LDAPS: curl_prot_t = 1 << 8;
pub const PROTO_FAMILY_LDAP: curl_prot_t = CURLPROTO_LDAP | CURLPROTO_LDAPS;

pub const PORT_LDAP: u16 = 389;
pub const PORT_LDAPS: u16 = 636;

pub const CURLUSESSL_NONE: u8 = 0;
pub const CURLUSESSL_TRY: u8 = 1;

pub const CLIENTWRITE_BODY: c_int = 1 << 0;

pub const CURL_WAIT_POLLIN: c_int = 0x0001;
pub const CURL_WAIT_POLLOUT: c_int = 0x0004;

pub const CURLAUTH_BASIC: c_ulong = 1 << 0;

pub const Curl_easy = opaque {};
pub const connectdata = opaque {};
const bufref = containers.bufref;
extern fn Curl_bufref_set(br: *bufref, ptr: ?*const anyopaque, len: usize, dtor: ?*const fn (?*anyopaque) callconv(.c) void) callconv(.c) void;
extern fn Curl_bufref_ptr(br: *const bufref) callconv(.c) ?[*:0]const u8;
extern fn Curl_bufref_len(br: *const bufref) callconv(.c) usize;

pub const Curl_recv = *const fn (
    data: *Curl_easy,
    num: i8,
    buf: [*]u8,
    len: usize,
    pnread: *usize,
) callconv(.c) CURLcode;

pub const Curl_send = *const fn (
    data: *Curl_easy,
    num: i8,
    mem: [*]const u8,
    len: usize,
    eos: bool,
    pnwritten: *usize,
) callconv(.c) CURLcode;

pub const Curl_protocol = extern struct {
    setup_connection: ?*const fn (?*anyopaque, ?*anyopaque) callconv(.c) CURLcode = null,
    do_it: ?*const fn (?*anyopaque, *bool) callconv(.c) CURLcode = null,
    done: ?*const fn (?*anyopaque, CURLcode, bool) callconv(.c) CURLcode = null,
    do_more: ?*const fn (?*anyopaque, *c_int) callconv(.c) CURLcode = null,
    connect_it: ?*const fn (?*anyopaque, *bool) callconv(.c) CURLcode = null,
    connecting: ?*const fn (?*anyopaque, *bool) callconv(.c) CURLcode = null,
    doing: ?*const fn (?*anyopaque, *bool) callconv(.c) CURLcode = null,
    proto_pollset: ?*const fn (?*anyopaque, ?*anyopaque) callconv(.c) CURLcode = null,
    doing_pollset: ?*const fn (?*anyopaque, ?*anyopaque) callconv(.c) CURLcode = null,
    domore_pollset: ?*const fn (?*anyopaque, ?*anyopaque) callconv(.c) CURLcode = null,
    perform_pollset: ?*const fn (?*anyopaque, ?*anyopaque) callconv(.c) CURLcode = null,
    disconnect: ?*const fn (?*anyopaque, ?*anyopaque, bool) callconv(.c) CURLcode = null,
    write_resp: ?*const fn (?*anyopaque, [*]const u8, usize, bool, *bool) callconv(.c) CURLcode = null,
    write_resp_hd: ?*const fn (?*anyopaque, [*]const u8, usize, bool) callconv(.c) CURLcode = null,
    connection_is_dead: ?*const fn (?*anyopaque, ?*anyopaque) callconv(.c) bool = null,
    attach: ?*const fn (?*anyopaque, ?*anyopaque) callconv(.c) void = null,
    cntrl: ?*const fn (?*anyopaque, c_int, c_int) callconv(.c) CURLcode = null,
};

pub const CURL_META_LDAP_EASY = "meta:proto:ldap:easy";
pub const CURL_META_LDAP_CONN = "meta:proto:ldap:conn";

pub const ldapstate = enum(c_uint) {
    OLDAP_STOP = 0,
    OLDAP_SSL,
    OLDAP_STARTTLS,
    OLDAP_TLS,
    OLDAP_MECHS,
    OLDAP_SASL,
    OLDAP_BIND,
    OLDAP_BINDV2,
    OLDAP_LAST,
};

const oldap_statenames = [_][*:0]const u8{
    "STOP",
    "SSL",
    "STARTTLS",
    "TLS",
    "MECHS",
    "SASL",
    "BIND",
    "BINDV2",
};

pub fn oldapStateName(state: ldapstate) [*:0]const u8 {
    const idx: usize = @backingInt(state);
    if (idx < oldap_statenames.len) {
        return oldap_statenames[idx];
    }
    return "";
}

/// Check for the presence of characters in `s` that cannot be represented
/// as an LDIF SAFE-STRING (RFC 2849) and therefore require base64 encoding.
/// Matches `str_needs_base64()` in `lib/openldap.c` and `lib/ldap.c`.
pub fn oldapStrNeedsBase64(s: []const u8) bool {
    if (s.len == 0) return false;
    // Not a SAFE-INIT-CHAR (`:` or `<`)
    if (s[0] == ':' or s[0] == '<') return true;
    // Leading or trailing space / horizontal tab (`ISBLANK`)
    if (isBlank(s[0]) or isBlank(s[s.len - 1])) return true;
    for (s) |ch| {
        if (!isPrintAscii(ch)) return true;
    }
    return false;
}

fn isBlank(ch: u8) bool {
    return ch == ' ' or ch == '\t';
}

fn isPrintAscii(ch: u8) bool {
    return ch >= 0x20 and ch <= 0x7e;
}

fn isCntrlAscii(ch: u8) bool {
    return ch < 0x20 or ch == 0x7f;
}

// ============================================================================
// LDAP / LBER Constants & Types
// ============================================================================

pub const LDAP = opaque {};
pub const LDAPMessage = opaque {};
pub const BerElement = opaque {};
pub const Sockbuf = opaque {};
pub const LDAPControl = opaque {};

pub const ber_len_t = if (use_win32_ldap) c_uint else c_ulong;
pub const ber_slen_t = if (use_win32_ldap) c_int else c_long;
pub const ber_int_t = c_int;
pub const ber_tag_t = if (use_win32_ldap) c_uint else c_ulong;
pub const ber_socket_t = c_int;

pub const BerValue = extern struct {
    bv_len: ber_len_t = 0,
    bv_val: ?[*]u8 = null,
};

pub const LDAPURLDesc = extern struct {
    lud_next: ?*LDAPURLDesc = null,
    lud_scheme: ?[*:0]u8 = null,
    lud_host: ?[*:0]u8 = null,
    lud_port: c_int = 0,
    lud_dn: ?[*:0]u8 = null,
    lud_attrs: ?[*]?[*:0]u8 = null,
    lud_scope: c_int = 0,
    lud_filter: ?[*:0]u8 = null,
    lud_exts: ?[*]?[*:0]u8 = null,
    lud_crit_exts: c_int = 0,
};

pub const LDAPAPIInfo = extern struct {
    ldapai_info_version: c_int = 0,
    ldapai_api_version: c_int = 0,
    ldapai_protocol_version: c_int = 0,
    ldapai_extensions: ?[*]?[*:0]u8 = null,
    ldapai_vendor_name: ?[*:0]u8 = null,
    ldapai_vendor_version: c_int = 0,
};

pub const Sockbuf_IO_Desc = extern struct {
    sbiod_level: c_int,
    sbiod_sb: ?*Sockbuf,
    sbiod_io: ?*Sockbuf_IO,
    sbiod_pvt: ?*anyopaque,
    sbiod_next: ?*Sockbuf_IO_Desc,
};

pub const Sockbuf_IO = extern struct {
    sbi_setup: ?*const fn (sbiod: *Sockbuf_IO_Desc, arg: ?*anyopaque) callconv(.c) c_int,
    sbi_remove: ?*const fn (sbiod: *Sockbuf_IO_Desc) callconv(.c) c_int,
    sbi_ctrl: ?*const fn (sbiod: *Sockbuf_IO_Desc, opt: c_int, arg: ?*anyopaque) callconv(.c) c_int,
    sbi_read: ?*const fn (sbiod: *Sockbuf_IO_Desc, buf: *anyopaque, len: ber_len_t) callconv(.c) ber_slen_t,
    sbi_write: ?*const fn (sbiod: *Sockbuf_IO_Desc, buf: *anyopaque, len: ber_len_t) callconv(.c) ber_slen_t,
    sbi_close: ?*const fn (sbiod: *Sockbuf_IO_Desc) callconv(.c) c_int,
};

pub const l_timeval = extern struct {
    tv_sec: if (is_windows) c_long else isize = 0,
    tv_usec: if (is_windows) c_long else isize = 0,
};

pub const LDAP_VERSION2: c_int = 2;
pub const LDAP_VERSION3: c_int = 3;

pub const LDAP_OPT_API_INFO: c_int = 0x0000;
pub const LDAP_OPT_REFERRALS: c_int = 0x0008;
pub const LDAP_OPT_SSL: c_int = 0x000a;
pub const LDAP_OPT_PROTOCOL_VERSION: c_int = 0x0011;
pub const LDAP_OPT_NETWORK_TIMEOUT: c_int = 0x5005;
pub const LDAP_OPT_SOCKBUF: c_int = 0x5008;
pub const LDAP_OPT_X_TLS: c_int = 0x6000;
pub const LDAP_OPT_X_TLS_HARD: c_int = 1;
pub const LDAP_OPT_X_TLS_CACERTFILE: c_int = 0x6002;
pub const LDAP_OPT_X_TLS_CACERTDIR: c_int = 0x6003;
pub const LDAP_OPT_X_TLS_CERTFILE: c_int = 0x6004;
pub const LDAP_OPT_X_TLS_KEYFILE: c_int = 0x6005;
pub const LDAP_OPT_X_TLS_REQUIRE_CERT: c_int = 0x6006;
pub const LDAP_OPT_X_TLS_CRLCHECK: c_int = 0x600b;
pub const LDAP_OPT_X_TLS_CRL_NONE: c_int = 0;
pub const LDAP_OPT_X_TLS_CRL_ALL: c_int = 2;
pub const LDAP_OPT_X_TLS_NEVER: c_int = 0;
pub const LDAP_OPT_X_TLS_DEMAND: c_int = 2;
pub const LDAP_OPT_X_TLS_NEWCTX: c_int = 0x600f;
pub const LDAP_OPT_X_TLS_CRLFILE: c_int = 0x6010;
pub const LDAP_OPT_SUCCESS: c_int = 0;
pub const LDAP_OPT_OFF: ?*const anyopaque = null;
pub const LDAP_OPT_ON: ?*const anyopaque = @ptrFromInt(1);
pub const LDAP_API_INFO_VERSION: c_int = 1;

pub const LDAP_SUCCESS: c_int = 0x00;
pub const LDAP_OPERATIONS_ERROR: c_int = 0x01;
pub const LDAP_PROTOCOL_ERROR: c_int = 0x02;
pub const LDAP_TIMELIMIT_EXCEEDED: c_int = 0x03;
pub const LDAP_SIZELIMIT_EXCEEDED: c_int = 0x04;
pub const LDAP_COMPARE_FALSE: c_int = 0x05;
pub const LDAP_COMPARE_TRUE: c_int = 0x06;
pub const LDAP_AUTH_METHOD_NOT_SUPPORTED: c_int = 0x07;
pub const LDAP_STRONG_AUTH_REQUIRED: c_int = 0x08;
pub const LDAP_PARTIAL_RESULTS: c_int = 0x09;
pub const LDAP_REFERRAL: c_int = 0x0a;
pub const LDAP_ADMINLIMIT_EXCEEDED: c_int = 0x0b;
pub const LDAP_UNAVAILABLE_CRITICAL_EXTENSION: c_int = 0x0c;
pub const LDAP_CONFIDENTIALITY_REQUIRED: c_int = 0x0d;
pub const LDAP_SASL_BIND_IN_PROGRESS: c_int = 0x0e;
pub const LDAP_NO_SUCH_ATTRIBUTE: c_int = 0x10;
pub const LDAP_UNDEFINED_TYPE: c_int = 0x11;
pub const LDAP_INAPPROPRIATE_MATCHING: c_int = 0x12;
pub const LDAP_CONSTRAINT_VIOLATION: c_int = 0x13;
pub const LDAP_TYPE_OR_VALUE_EXISTS: c_int = 0x14;
pub const LDAP_INVALID_SYNTAX: c_int = 0x15;
pub const LDAP_NO_SUCH_OBJECT: c_int = 0x20;
pub const LDAP_ALIAS_PROBLEM: c_int = 0x21;
pub const LDAP_INVALID_DN_SYNTAX: c_int = 0x22;
pub const LDAP_IS_LEAF: c_int = 0x23;
pub const LDAP_ALIAS_DEREF_PROBLEM: c_int = 0x24;
pub const LDAP_INAPPROPRIATE_AUTH: c_int = 0x30;
pub const LDAP_INVALID_CREDENTIALS: c_int = 0x31;
pub const LDAP_INSUFFICIENT_ACCESS: c_int = 0x32;
pub const LDAP_BUSY: c_int = 0x33;
pub const LDAP_UNAVAILABLE: c_int = 0x34;
pub const LDAP_UNWILLING_TO_PERFORM: c_int = 0x35;
pub const LDAP_LOOP_DETECT: c_int = 0x36;
pub const LDAP_NAMING_VIOLATION: c_int = 0x40;
pub const LDAP_OBJECT_CLASS_VIOLATION: c_int = 0x41;
pub const LDAP_NOT_ALLOWED_ON_NONLEAF: c_int = 0x42;
pub const LDAP_NOT_ALLOWED_ON_RDN: c_int = 0x43;
pub const LDAP_ALREADY_EXISTS: c_int = 0x44;
pub const LDAP_NO_OBJECT_CLASS_MODS: c_int = 0x45;
pub const LDAP_RESULTS_TOO_LARGE: c_int = 0x46;
pub const LDAP_AFFECTS_MULTIPLE_DSAS: c_int = 0x47;
pub const LDAP_OTHER: c_int = 0x50;
pub const LDAP_SERVER_DOWN: c_int = if (use_win32_ldap) 0x51 else -1;
pub const LDAP_LOCAL_ERROR: c_int = if (use_win32_ldap) 0x52 else -2;
pub const LDAP_ENCODING_ERROR: c_int = if (use_win32_ldap) 0x53 else -3;
pub const LDAP_DECODING_ERROR: c_int = if (use_win32_ldap) 0x54 else -4;
pub const LDAP_TIMEOUT: c_int = if (use_win32_ldap) 0x55 else -5;
pub const LDAP_AUTH_UNKNOWN: c_int = if (use_win32_ldap) 0x56 else -6;
pub const LDAP_FILTER_ERROR: c_int = if (use_win32_ldap) 0x57 else -7;
pub const LDAP_USER_CANCELLED: c_int = if (use_win32_ldap) 0x58 else -8;
pub const LDAP_PARAM_ERROR: c_int = if (use_win32_ldap) 0x59 else -9;
pub const LDAP_NO_MEMORY: c_int = if (use_win32_ldap) 0x5a else -10;
pub const LDAP_CONNECT_ERROR: c_int = if (use_win32_ldap) 0x5b else -11;
pub const LDAP_NOT_SUPPORTED: c_int = if (use_win32_ldap) 0x5c else -12;
pub const LDAP_CONTROL_NOT_FOUND: c_int = if (use_win32_ldap) 0x5d else -13;
pub const LDAP_NO_RESULTS_RETURNED: c_int = if (use_win32_ldap) 0x5e else -14;
pub const LDAP_MORE_RESULTS_TO_RETURN: c_int = if (use_win32_ldap) 0x5f else -15;
pub const LDAP_CLIENT_LOOP: c_int = if (use_win32_ldap) 0x60 else -16;
pub const LDAP_REFERRAL_LIMIT_EXCEEDED: c_int = if (use_win32_ldap) 0x61 else -17;

pub const LDAP_SCOPE_BASE: c_int = 0x0000;
pub const LDAP_SCOPE_ONELEVEL: c_int = 0x0001;
pub const LDAP_SCOPE_SUBTREE: c_int = 0x0002;
pub const LDAP_SCOPE_DEFAULT: c_int = -1;

pub const LDAP_URL_SUCCESS: c_int = 0x00;
pub const LDAP_URL_ERR_MEM: c_int = 0x01;
pub const LDAP_URL_ERR_PARAM: c_int = 0x02;
pub const LDAP_URL_ERR_BADSCHEME: c_int = 0x03;
pub const LDAP_URL_ERR_BADENCLOSURE: c_int = 0x04;
pub const LDAP_URL_ERR_BADURL: c_int = 0x05;
pub const LDAP_URL_ERR_BADHOST: c_int = 0x06;
pub const LDAP_URL_ERR_BADATTRS: c_int = 0x07;
pub const LDAP_URL_ERR_BADSCOPE: c_int = 0x08;
pub const LDAP_URL_ERR_BADFILTER: c_int = 0x09;
pub const LDAP_URL_ERR_BADEXTS: c_int = 0x0a;

pub const LDAP_RES_BIND: ber_tag_t = 0x61;
pub const LDAP_RES_SEARCH_ENTRY: ber_tag_t = 0x64;
pub const LDAP_RES_SEARCH_RESULT: ber_tag_t = 0x65;
pub const LDAP_RES_SEARCH_REFERENCE: ber_tag_t = 0x73;
pub const LDAP_RES_EXTENDED: ber_tag_t = 0x78;
pub const LDAP_RES_ANY: c_int = -1;
pub const LDAP_MSG_ONE: c_int = 0x00;
pub const LDAP_NO_LIMIT: c_int = 0;

pub const LBER_SBIOD_LEVEL_TRANSPORT: c_int = 20;
pub const LBER_SB_OPT_DATA_READY: c_int = 8;
pub const LBER_SB_OPT_SET_MAX_INCOMING: c_int = 14;

pub const LDAP_EXOP_START_TLS: [*:0]const u8 = "1.3.6.1.4.1.1466.20037";
pub const LDAP_SASL_SIMPLE: ?[*:0]const u8 = null;
pub const LDAP_SASL_NULL: [*:0]const u8 = "";

const SASL_IDLE: c_uint = 0;
const SASL_INPROGRESS: c_uint = 1;
const SASL_DONE: c_uint = 2;
const SASL_AUTH_NONE: c_ushort = 0;

const SASLproto = extern struct {
    service: [*:0]const u8,
    sendauth: *const fn (data: ?*anyopaque, mech: [*:0]const u8, ir: *const bufref) callconv(.c) CURLcode,
    contauth: *const fn (data: ?*anyopaque, mech: [*:0]const u8, contauth: *const bufref) callconv(.c) CURLcode,
    cancelauth: *const fn (data: ?*anyopaque, mech: [*:0]const u8) callconv(.c) CURLcode,
    getmessage: *const fn (data: ?*anyopaque, out: *bufref) callconv(.c) CURLcode,
    maxirlen: usize,
    contcode: c_int,
    finalcode: c_int,
    defmechs: c_ushort,
    flags: c_ushort,
};

const SASL = extern struct {
    params: ?*const SASLproto = null,
    state: c_uint = 0,
    curmech: ?[*:0]const u8 = null,
    authmechs: c_ushort = 0,
    prefmech: c_ushort = 0,
    authused: c_ushort = 0,
    flags: u8 = 0,
};

const Curl_meta_dtor = *const fn (key: ?*const anyopaque, key_len: usize, entry: ?*anyopaque) callconv(.c) void;

// ============================================================================
// Extern C Helpers & Internal libcurl Functions
// ============================================================================

extern fn Curl_meta_set(data: *Curl_easy, key: [*:0]const u8, entry: ?*anyopaque, dtor: Curl_meta_dtor) callconv(.c) CURLcode;
extern fn Curl_meta_get(data: *Curl_easy, key: [*:0]const u8) callconv(.c) ?*anyopaque;
extern fn Curl_meta_remove(data: *Curl_easy, key: [*:0]const u8) callconv(.c) void;
extern fn Curl_conn_meta_set(conn: *connectdata, key: [*:0]const u8, entry: ?*anyopaque, dtor: Curl_meta_dtor) callconv(.c) CURLcode;
extern fn Curl_conn_meta_get(conn: *connectdata, key: [*:0]const u8) callconv(.c) ?*anyopaque;

extern fn Curl_ftp_acc_get_conn(data: *Curl_easy) callconv(.c) ?*connectdata;
extern fn Curl_vssh_get_conn_user(conn: *const connectdata) callconv(.c) ?[*:0]const u8;
extern fn Curl_vssh_get_conn_passwd(conn: *const connectdata) callconv(.c) ?[*:0]const u8;
extern fn Curl_vssh_get_conn_host_name(conn: *const connectdata) callconv(.c) [*:0]const u8;
extern fn Curl_vssh_get_conn_remote_port(conn: *const connectdata) callconv(.c) c_int;
extern fn Curl_vssh_get_conn_firstsocket(conn: *const connectdata) callconv(.c) curl_socket_t;
extern fn Curl_vssh_get_conn_protocol(conn: *const connectdata) callconv(.c) curl_prot_t;

extern fn Curl_ldap_url_has_creds_or_options(data: *const Curl_easy) callconv(.c) bool;
extern fn Curl_ldap_get_state_url(data: *const Curl_easy) callconv(.c) ?[*:0]const u8;
extern fn Curl_ldap_has_state_creds(data: *const Curl_easy) callconv(.c) bool;
extern fn Curl_ldap_get_state_creds_user(data: *const Curl_easy) callconv(.c) ?[*:0]const u8;
extern fn Curl_ldap_get_state_creds_passwd(data: *const Curl_easy) callconv(.c) ?[*:0]const u8;
extern fn Curl_ldap_get_conn_options(conn: *const connectdata) callconv(.c) ?[*:0]const u8;
extern fn Curl_ldap_get_conn_scheme_name(conn: *const connectdata) callconv(.c) [*:0]const u8;
extern fn Curl_ldap_get_origin_scheme_name(data: *const Curl_easy) callconv(.c) [*:0]const u8;
extern fn Curl_ldap_format_hosturl(conn: *const connectdata) callconv(.c) ?[*:0]u8;
extern fn Curl_ldap_get_conn_recv(conn: *const connectdata, sockindex: i8) callconv(.c) ?Curl_recv;
extern fn Curl_ldap_set_conn_recv(conn: *connectdata, recv_fn: Curl_recv) callconv(.c) void;
extern fn Curl_ldap_get_conn_send(conn: *const connectdata, sockindex: i8) callconv(.c) ?Curl_send;
extern fn Curl_ldap_set_sockerrno_einval() callconv(.c) void;
extern fn Curl_ldap_set_sockerrno_ewouldblock() callconv(.c) void;
extern fn Curl_ldap_dup_socket(s: curl_socket_t) callconv(.c) curl_socket_t;
extern fn Curl_ldap_sclose(s: curl_socket_t) callconv(.c) void;
extern fn Curl_ldap_get_ssl_verifypeer(conn: *const connectdata) callconv(.c) bool;
extern fn Curl_ldap_get_ssl_verifyhost(conn: *const connectdata) callconv(.c) bool;
extern fn Curl_ldap_get_ssl_cafile(conn: *const connectdata) callconv(.c) ?[*:0]const u8;
extern fn Curl_ldap_get_ssl_cert_type(conn: *const connectdata) callconv(.c) ?[*:0]const u8;
extern fn Curl_ldap_conn_is_ssl(conn: *const connectdata) callconv(.c) bool;
extern fn Curl_ldap_add_ssl_cfilter(data: *Curl_easy, conn: *connectdata) callconv(.c) CURLcode;
extern fn Curl_ldap_set_info_httpcode(data: *Curl_easy, code: c_int) callconv(.c) void;
extern fn Curl_ldap_set_req_size_from_bytecount(data: *Curl_easy) callconv(.c) void;
extern fn Curl_ldap_get_remote_port(data: *Curl_easy, conn: *connectdata, pport: *c_int) callconv(.c) CURLcode;
extern fn Curl_ldap_get_conn_hostname(conn: *const connectdata) callconv(.c) [*:0]const u8;
extern fn Curl_ldap_get_conn_user_hostname(conn: *const connectdata) callconv(.c) [*:0]const u8;
extern fn Curl_ldap_get_up_path(data: *const Curl_easy) callconv(.c) ?[*:0]const u8;
extern fn Curl_ldap_get_up_query(data: *const Curl_easy) callconv(.c) ?[*:0]const u8;
extern fn Curl_ldap_connclose(conn: *connectdata) callconv(.c) void;
extern fn Curl_ldap_get_vendor_name() callconv(.c) [*:0]const u8;
extern fn Curl_ldap_get_vendor_version() callconv(.c) c_int;
extern fn Curl_ldap_set_win32_bypass_cert_verify(server: *LDAP) callconv(.c) void;
extern fn Curl_ldap_win_bind(data: *Curl_easy, server: *LDAP, user: ?[*:0]const u8, passwd: ?[*:0]const u8) callconv(.c) c_int;

extern fn Curl_conn_connect(data: *Curl_easy, sockindex: i8, blocking: bool, done: *bool) callconv(.c) CURLcode;
extern fn Curl_conn_data_pending(data: *Curl_easy, sockindex: i8) callconv(.c) bool;
extern fn Curl_xfer_setup_recv(data: *Curl_easy, sockindex: i8, size: curl_off_t) callconv(.c) void;
extern fn Curl_xfer_setup_nop(data: *Curl_easy) callconv(.c) void;
extern fn Curl_client_write(data: *Curl_easy, @"type": c_int, buf: [*]const u8, blen: usize) callconv(.c) CURLcode;
extern fn Curl_pgrsReset(data: *Curl_easy) callconv(.c) void;
extern fn Curl_urldecode(string: [*]const u8, length: usize, ostring: *?[*:0]u8, olen: ?*usize, ctrl: c_uint) callconv(.c) CURLcode;

extern fn Curl_pop3_smtp_sasl_init(sasl: *SASL, data: ?*anyopaque, params: *const SASLproto) callconv(.c) void;
extern fn Curl_pop3_smtp_sasl_can_authenticate(sasl: *SASL, data: ?*anyopaque) callconv(.c) bool;
extern fn Curl_pop3_smtp_sasl_start(sasl: *SASL, data: ?*anyopaque, force_ir: bool, progress: *c_uint) callconv(.c) CURLcode;
extern fn Curl_pop3_smtp_sasl_continue(sasl: *SASL, data: ?*anyopaque, code: c_int, progress: *c_uint) callconv(.c) CURLcode;
extern fn Curl_pop3_smtp_sasl_is_blocked(sasl: *SASL, data: ?*anyopaque) callconv(.c) CURLcode;
extern fn Curl_pop3_smtp_sasl_decode_mech(ptr: [*]const u8, maxlen: usize, len: *usize) callconv(.c) c_ushort;
extern fn Curl_pop3_smtp_sasl_parse_url_auth_option(sasl: *SASL, value: [*]const u8, len: usize) callconv(.c) CURLcode;
extern fn Curl_pop3_smtp_sasl_get_prefmech(sasl: *const SASL) callconv(.c) c_ushort;
extern fn Curl_pop3_smtp_sasl_or_authmechs(sasl: *SASL, mech: c_ushort) callconv(.c) void;

extern fn Curl_set_str(data: *Curl_easy, idx: c_uint) callconv(.c) ?[*:0]u8;
extern fn Curl_imap_ws_get_use_ssl(data: *const Curl_easy) callconv(.c) u8;
const Curl_get_use_ssl = Curl_imap_ws_get_use_ssl;
extern fn curlx_str_until(linep: *?[*:0]const u8, out: *curlx_parse.Curl_str, max: usize, delim: u8) callconv(.c) c_int;
extern fn curlx_str_single(linep: *?[*:0]const u8, expect: u8) callconv(.c) c_int;
extern fn Curl_get_ssl_primary_verifypeer(data: *Curl_easy) callconv(.c) bool;
extern fn Curl_get_ssl_fsslctx(data: *Curl_easy) callconv(.c) ?*const anyopaque;
extern fn Curl_get_timeout_ms(data: *Curl_easy) callconv(.c) c_long;
extern fn Curl_setopt_trc_bind_is_verbose(data: *Curl_easy) callconv(.c) bool;

// ============================================================================
// Extern OpenLDAP / LDAP / LBER Library Functions
// ============================================================================

extern fn ldap_get_option(ld: ?*LDAP, option: c_int, outvalue: *anyopaque) callconv(.c) c_int;
extern fn ldap_set_option(ld: ?*LDAP, option: c_int, invalue: ?*const anyopaque) callconv(.c) c_int;
extern fn ldap_err2string(err: c_int) callconv(.c) ?[*:0]const u8;
extern fn ldap_msgfree(lm: ?*LDAPMessage) callconv(.c) c_int;
extern fn ldap_first_entry(ld: *LDAP, chain: *LDAPMessage) callconv(.c) ?*LDAPMessage;
extern fn ldap_next_entry(ld: *LDAP, entry: *LDAPMessage) callconv(.c) ?*LDAPMessage;
extern fn ldap_first_attribute(ld: *LDAP, entry: *LDAPMessage, berout: *?*BerElement) callconv(.c) ?[*:0]u8;
extern fn ldap_next_attribute(ld: *LDAP, entry: *LDAPMessage, ber: *BerElement) callconv(.c) ?[*:0]u8;
extern fn ldap_get_values_len(ld: *LDAP, entry: *LDAPMessage, target: [*:0]const u8) callconv(.c) ?[*]?*BerValue;
extern fn ldap_value_free_len(vals: [*]?*BerValue) callconv(.c) void;
extern fn ldap_get_dn(ld: *LDAP, entry: *LDAPMessage) callconv(.c) ?[*:0]u8;
extern fn ldap_memfree(p: ?*anyopaque) callconv(.c) void;
extern fn ber_free(ber: ?*BerElement, freebuf: c_int) callconv(.c) void;

// OpenLDAP-specific externs (used when use_openldap is true)
extern fn ldap_url_parse(url: [*:0]const u8, ludpp: *?*LDAPURLDesc) callconv(.c) c_int;
extern fn ldap_free_urldesc(ludp: ?*LDAPURLDesc) callconv(.c) void;
extern fn ldap_pvt_url_scheme2proto(scheme: [*:0]const u8) callconv(.c) c_int;
extern fn ldap_init_fd(fd: ber_socket_t, proto: c_int, url: ?[*:0]const u8, ldp: *?*LDAP) callconv(.c) c_int;
extern fn ldap_sasl_bind(
    ld: *LDAP,
    dn: ?[*:0]const u8,
    mechanism: ?[*:0]const u8,
    cred: ?*BerValue,
    sctrls: ?*?*LDAPControl,
    cctrls: ?*?*LDAPControl,
    msgidp: *c_int,
) callconv(.c) c_int;
extern fn ldap_search_ext(
    ld: *LDAP,
    base: ?[*:0]const u8,
    scope: c_int,
    filter: ?[*:0]const u8,
    attrs: ?[*]?[*:0]u8,
    attrsonly: c_int,
    sctrls: ?*?*LDAPControl,
    cctrls: ?*?*LDAPControl,
    timeout: ?*l_timeval,
    sizelimit: c_int,
    msgidp: *c_int,
) callconv(.c) c_int;
extern fn ldap_extended_operation(
    ld: *LDAP,
    reqoid: [*:0]const u8,
    reqdata: ?*BerValue,
    sctrls: ?*?*LDAPControl,
    cctrls: ?*?*LDAPControl,
    msgidp: *c_int,
) callconv(.c) c_int;
extern fn ldap_unbind_ext(ld: *LDAP, sctrls: ?*?*LDAPControl, cctrls: ?*?*LDAPControl) callconv(.c) c_int;
extern fn ldap_abandon_ext(ld: *LDAP, msgid: c_int, sctrls: ?*?*LDAPControl, cctrls: ?*?*LDAPControl) callconv(.c) c_int;
extern fn ldap_result(
    ld: *LDAP,
    msgid: c_int,
    all: c_int,
    timeout: ?*l_timeval,
    result: *?*LDAPMessage,
) callconv(.c) c_int;
extern fn ldap_msgtype(lm: *LDAPMessage) callconv(.c) ber_tag_t;
extern fn ldap_parse_result(
    ld: *LDAP,
    res: *LDAPMessage,
    errcodep: *c_int,
    matcheddnp: ?*?[*:0]u8,
    errmsgp: ?*?[*:0]u8,
    referralsp: ?*?[*]?[*:0]u8,
    serverctrlsp: ?*?*?*LDAPControl,
    freeit: c_int,
) callconv(.c) c_int;
extern fn ldap_parse_sasl_bind_result(
    ld: *LDAP,
    res: *LDAPMessage,
    servercredp: *?*BerValue,
    freeit: c_int,
) callconv(.c) c_int;
extern fn ldap_get_dn_ber(
    ld: *LDAP,
    entry: *LDAPMessage,
    berout: *?*BerElement,
    dn: *BerValue,
) callconv(.c) c_int;
extern fn ldap_get_attribute_ber(
    ld: *LDAP,
    entry: *LDAPMessage,
    ber: *BerElement,
    attr: *BerValue,
    vals: *?[*]BerValue,
) callconv(.c) c_int;
extern fn ldap_memvfree(v: [*]?*anyopaque) callconv(.c) void;
extern fn ber_memfree_x(p: ?*anyopaque, ctx: ?*anyopaque) callconv(.c) void;
extern fn ber_memvfree_x(vec: ?[*]?*anyopaque, ctx: ?*anyopaque) callconv(.c) void;
extern fn ber_bvfree_x(bv: ?*BerValue, ctx: ?*anyopaque) callconv(.c) void;
extern fn ber_bvecfree_x(bvec: ?[*]?*BerValue, ctx: ?*anyopaque) callconv(.c) void;
extern fn ber_sockbuf_add_io(sb: *Sockbuf, sbio: *Sockbuf_IO, layer: c_int, arg: ?*anyopaque) callconv(.c) c_int;
extern fn ber_sockbuf_ctrl(sb: *Sockbuf, opt: c_int, arg: ?*anyopaque) callconv(.c) c_int;

// Legacy LDAP / WinLDAP externs (used when use_legacy_ldap is true)
extern fn ldap_init(host: ?[*:0]const u8, port: c_int) callconv(.c) ?*LDAP;
extern fn ldap_sslinit(host: ?[*:0]const u8, port: c_int, secure: c_int) callconv(.c) ?*LDAP;
extern fn ldap_simple_bind_s(ld: *LDAP, who: ?[*:0]const u8, passwd: ?[*:0]const u8) callconv(.c) c_int;
extern fn ldap_unbind_s(ld: *LDAP) callconv(.c) c_int;
extern fn ldap_search_s(
    ld: *LDAP,
    base: ?[*:0]const u8,
    scope: c_int,
    filter: ?[*:0]const u8,
    attrs: ?[*]?[*:0]u8,
    attrsonly: c_int,
    res: *?*LDAPMessage,
) callconv(.c) c_int;

// ============================================================================
// Logging Helpers
// ============================================================================

extern fn Curl_infof(data: ?*Curl_easy, fmt: [*:0]const u8, ...) callconv(.c) void;
extern fn Curl_failf(data: ?*Curl_easy, fmt: [*:0]const u8, ...) callconv(.c) void;

fn failfMsg(data: *Curl_easy, comptime fmt: [*:0]const u8, args: anytype) void {
    @call(.auto, Curl_failf, .{ data, fmt } ++ args);
}

fn infofMsg(data: ?*Curl_easy, comptime fmt: [*:0]const u8, args: anytype) void {
    const d = data orelse return;
    if (!Curl_setopt_trc_bind_is_verbose(d)) return;
    @call(.auto, Curl_infof, .{ d, fmt } ++ args);
}

// ============================================================================
// Shared LDIF Writer Helper
// ============================================================================

fn writeData(data: *Curl_easy, prefix: []const u8, val: []const u8, is_b64: bool) CURLcode {
    const sep: []const u8 = if (is_b64) ":: " else ": ";
    var result: CURLcode = CURLE_OK;

    if (prefix.len > 0) {
        result = Curl_client_write(data, CLIENTWRITE_BODY, prefix.ptr, prefix.len);
        if (result != CURLE_OK) return result;
    }

    result = Curl_client_write(data, CLIENTWRITE_BODY, sep.ptr, sep.len);
    if (result != CURLE_OK) return result;

    if (val.len > 0) {
        result = Curl_client_write(data, CLIENTWRITE_BODY, val.ptr, val.len);
        if (result != CURLE_OK) return result;
    }

    const nl = "\n";
    return Curl_client_write(data, CLIENTWRITE_BODY, nl.ptr, 1);
}

fn writeEncodedOrRaw(data: *Curl_easy, prefix: []const u8, raw: []const u8, force_b64: bool) CURLcode {
    const needs_b64 = force_b64 or oldapStrNeedsBase64(raw);
    if (!needs_b64) {
        return writeData(data, prefix, raw, false);
    }
    var b64_ptr: ?[*:0]u8 = null;
    var b64_len: usize = 0;
    const result = curlx_parse.curlx_base64_encode(
        if (raw.len > 0) raw.ptr else "",
        raw.len,
        &b64_ptr,
        &b64_len,
    );
    if (result != CURLE_OK) return result;
    defer if (b64_ptr) |p| alloc.Curl_free(p);
    const encoded = if (b64_ptr) |p| p[0..b64_len] else "";
    return writeData(data, prefix, encoded, true);
}

// ============================================================================
// OpenLDAP Backend Implementation (lib/openldap.c)
// ============================================================================

pub const ldapconninfo = struct {
    sasl: SASL = .{},
    ld: ?*LDAP = null,
    recv: ?Curl_recv = null,
    send: ?Curl_send = null,
    servercred: ?*BerValue = null,
    state: ldapstate = .OLDAP_STOP,
    proto: c_int = 0,
    msgid: c_int = 0,
    dupfd: curl_socket_t = CURL_SOCKET_BAD,
    ssldone: bool = false,
    sslinst: bool = false,
    didbind: bool = false,
};

pub const ldapreqinfo = struct {
    msgid: c_int = 0,
    num_entries: c_int = 0,
};

const url_errs = [_][*:0]const u8{
    "success",
    "out of memory",
    "bad parameter",
    "unrecognized scheme",
    "unbalanced delimiter",
    "bad URL",
    "bad host or port",
    "bad or missing attributes",
    "bad or missing scope",
    "bad or missing filter",
    "bad or missing extensions",
};

fn oldapState(data: *Curl_easy, li: *ldapconninfo, newstate: ldapstate) void {
    if (li.state != newstate) {
        infofMsg(data, "LDAP %p state change from %s to %s", .{
            li,
            oldapStateName(li.state),
            oldapStateName(newstate),
        });
    }
    li.state = newstate;
}

pub fn oldapMapError(rc: c_int, dflt: CURLcode) CURLcode {
    return switch (rc) {
        LDAP_NO_MEMORY => CURLE_OUT_OF_MEMORY,
        LDAP_INVALID_CREDENTIALS => CURLE_LOGIN_DENIED,
        LDAP_PROTOCOL_ERROR => CURLE_UNSUPPORTED_PROTOCOL,
        LDAP_INSUFFICIENT_ACCESS => CURLE_REMOTE_ACCESS_DENIED,
        else => dflt,
    };
}

fn oldapUrlParse(data: *Curl_easy, ludp: *?*LDAPURLDesc) CURLcode {
    ludp.* = null;
    var rc: c_int = LDAP_URL_SUCCESS;
    if (Curl_ldap_url_has_creds_or_options(data)) {
        rc = LDAP_URL_ERR_BADURL;
    } else {
        const url = Curl_ldap_get_state_url(data) orelse "";
        rc = ldap_url_parse(url, ludp);
    }

    if (rc != LDAP_URL_SUCCESS) {
        var msg: [*:0]const u8 = "url parsing problem";
        const result: CURLcode = if (rc == LDAP_URL_ERR_MEM)
            CURLE_OUT_OF_MEMORY
        else
            CURLE_URL_MALFORMAT;
        const idx = rc - LDAP_URL_SUCCESS;
        if (idx >= 0 and @as(usize, @intCast(idx)) < url_errs.len) {
            msg = url_errs[@intCast(idx)];
        }
        failfMsg(data, "LDAP local: %s", .{msg});
        return result;
    }
    return CURLE_OK;
}

fn oldapParseLoginOptions(conn: *connectdata) CURLcode {
    const li: *ldapconninfo = @ptrCast(@alignCast(Curl_conn_meta_get(conn, CURL_META_LDAP_CONN) orelse return CURLE_FAILED_INIT));
    var ptr = Curl_ldap_get_conn_options(conn) orelse return CURLE_OK;
    var result: CURLcode = CURLE_OK;

    while (result == CURLE_OK and ptr[0] != 0) {
        const key = ptr;
        while (ptr[0] != 0 and ptr[0] != '=') : (ptr += 1) {}
        const value = if (ptr[0] != 0) ptr + 1 else ptr;
        while (ptr[0] != 0 and ptr[0] != ';') : (ptr += 1) {}

        if (primitives.curl_strnequal(key, "AUTH=", 5) != 0) {
            const vlen = @intFromPtr(ptr) - @intFromPtr(value);
            result = Curl_pop3_smtp_sasl_parse_url_auth_option(&li.sasl, value, vlen);
        } else {
            result = CURLE_SETOPT_OPTION_SYNTAX;
        }

        if (ptr[0] == ';') {
            ptr += 1;
        }
    }

    return if (result == CURLE_URL_MALFORMAT) CURLE_SETOPT_OPTION_SYNTAX else result;
}

fn oldapSetupConnection(data_opt: ?*anyopaque, conn_opt: ?*anyopaque) callconv(.c) CURLcode {
    _ = conn_opt;
    if (comptime !use_openldap) return CURLE_NOT_BUILT_IN;
    const data: *Curl_easy = @ptrCast(data_opt orelse return CURLE_BAD_FUNCTION_ARGUMENT);
    var lud: ?*LDAPURLDesc = null;
    const result = oldapUrlParse(data, &lud);
    ldap_free_urldesc(lud);
    return result;
}

fn oldapGetMessage(data_opt: ?*anyopaque, out: *bufref) callconv(.c) CURLcode {
    if (comptime !use_openldap) return CURLE_NOT_BUILT_IN;
    const data: *Curl_easy = @ptrCast(data_opt orelse return CURLE_FAILED_INIT);
    const conn = Curl_ftp_acc_get_conn(data) orelse return CURLE_FAILED_INIT;
    const li: *ldapconninfo = @ptrCast(@alignCast(Curl_conn_meta_get(conn, CURL_META_LDAP_CONN) orelse return CURLE_FAILED_INIT));
    const servercred = li.servercred orelse return CURLE_WEIRD_SERVER_REPLY;
    const val = servercred.bv_val orelse return CURLE_WEIRD_SERVER_REPLY;
    Curl_bufref_set(out, val, @intCast(servercred.bv_len), null);
    return CURLE_OK;
}

fn oldapPerformAuth(data_opt: ?*anyopaque, mech: [*:0]const u8, initresp: *const bufref) callconv(.c) CURLcode {
    if (comptime !use_openldap) return CURLE_NOT_BUILT_IN;
    const data: *Curl_easy = @ptrCast(data_opt orelse return CURLE_FAILED_INIT);
    const conn = Curl_ftp_acc_get_conn(data) orelse return CURLE_FAILED_INIT;
    const li: *ldapconninfo = @ptrCast(@alignCast(Curl_conn_meta_get(conn, CURL_META_LDAP_CONN) orelse return CURLE_FAILED_INIT));
    const ld = li.ld orelse return CURLE_FAILED_INIT;

    var cred = BerValue{
        .bv_val = @constCast(Curl_bufref_ptr(initresp)),
        .bv_len = @intCast(Curl_bufref_len(initresp)),
    };
    defer mem.secureZero(&cred, @sizeOf(BerValue));
    const pcred: ?*BerValue = if (cred.bv_val != null) &cred else null;
    const rc = ldap_sasl_bind(ld, null, mech, pcred, null, null, &li.msgid);
    if (rc != LDAP_SUCCESS) {
        return oldapMapError(rc, CURLE_LDAP_CANNOT_BIND);
    }
    return CURLE_OK;
}

fn oldapContinueAuth(data_opt: ?*anyopaque, mech: [*:0]const u8, resp: *const bufref) callconv(.c) CURLcode {
    if (comptime !use_openldap) return CURLE_NOT_BUILT_IN;
    const data: *Curl_easy = @ptrCast(data_opt orelse return CURLE_FAILED_INIT);
    const conn = Curl_ftp_acc_get_conn(data) orelse return CURLE_FAILED_INIT;
    const li: *ldapconninfo = @ptrCast(@alignCast(Curl_conn_meta_get(conn, CURL_META_LDAP_CONN) orelse return CURLE_FAILED_INIT));
    const ld = li.ld orelse return CURLE_FAILED_INIT;

    var cred = BerValue{
        .bv_val = @constCast(Curl_bufref_ptr(resp)),
        .bv_len = @intCast(Curl_bufref_len(resp)),
    };
    defer mem.secureZero(&cred, @sizeOf(BerValue));
    const pcred: ?*BerValue = if (cred.bv_val != null) &cred else null;
    const rc = ldap_sasl_bind(ld, null, mech, pcred, null, null, &li.msgid);
    if (rc != LDAP_SUCCESS) {
        return oldapMapError(rc, CURLE_LDAP_CANNOT_BIND);
    }
    return CURLE_OK;
}

fn oldapCancelAuth(data_opt: ?*anyopaque, mech: [*:0]const u8) callconv(.c) CURLcode {
    _ = mech;
    if (comptime !use_openldap) return CURLE_NOT_BUILT_IN;
    const data: *Curl_easy = @ptrCast(data_opt orelse return CURLE_FAILED_INIT);
    const conn = Curl_ftp_acc_get_conn(data) orelse return CURLE_FAILED_INIT;
    const li: *ldapconninfo = @ptrCast(@alignCast(Curl_conn_meta_get(conn, CURL_META_LDAP_CONN) orelse return CURLE_FAILED_INIT));
    const ld = li.ld orelse return CURLE_FAILED_INIT;

    const rc = ldap_sasl_bind(ld, null, LDAP_SASL_NULL, null, null, null, &li.msgid);
    if (rc != LDAP_SUCCESS) {
        return oldapMapError(rc, CURLE_LDAP_CANNOT_BIND);
    }
    return CURLE_OK;
}

fn oldapPerformBind(data: *Curl_easy, newstate: ldapstate) CURLcode {
    const conn = Curl_ftp_acc_get_conn(data) orelse return CURLE_FAILED_INIT;
    const li: *ldapconninfo = @ptrCast(@alignCast(Curl_conn_meta_get(conn, CURL_META_LDAP_CONN) orelse return CURLE_FAILED_INIT));
    const ld = li.ld orelse return CURLE_FAILED_INIT;

    var binddn: ?[*:0]const u8 = null;
    var passwd = BerValue{};
    defer mem.secureZero(&passwd, @sizeOf(BerValue));
    if (Curl_vssh_get_conn_user(conn)) |u| {
        binddn = u;
        if (Curl_vssh_get_conn_passwd(conn)) |pw| {
            passwd.bv_val = @constCast(pw);
            passwd.bv_len = @intCast(std.mem.len(pw));
        }
    }

    const rc = ldap_sasl_bind(ld, binddn, LDAP_SASL_SIMPLE, &passwd, null, null, &li.msgid);
    if (rc != LDAP_SUCCESS) {
        return oldapMapError(
            rc,
            if (Curl_ldap_has_state_creds(data)) CURLE_LOGIN_DENIED else CURLE_LDAP_CANNOT_BIND,
        );
    }
    oldapState(data, li, newstate);
    return CURLE_OK;
}

fn oldapPerformMechs(data: *Curl_easy) CURLcode {
    const conn = Curl_ftp_acc_get_conn(data) orelse return CURLE_FAILED_INIT;
    const li: *ldapconninfo = @ptrCast(@alignCast(Curl_conn_meta_get(conn, CURL_META_LDAP_CONN) orelse return CURLE_FAILED_INIT));
    const ld = li.ld orelse return CURLE_FAILED_INIT;

    var supported_sasl_mechs = [_]?[*:0]u8{
        @constCast("supportedSASLMechanisms"),
        null,
    };

    const rc = ldap_search_ext(
        ld,
        "",
        LDAP_SCOPE_BASE,
        "(objectclass=*)",
        &supported_sasl_mechs,
        0,
        null,
        null,
        null,
        0,
        &li.msgid,
    );
    if (rc != LDAP_SUCCESS) {
        return oldapMapError(rc, CURLE_LOGIN_DENIED);
    }
    oldapState(data, li, .OLDAP_MECHS);
    return CURLE_OK;
}

fn oldapPerformSasl(data: *Curl_easy) CURLcode {
    const conn = Curl_ftp_acc_get_conn(data) orelse return CURLE_FAILED_INIT;
    const li: *ldapconninfo = @ptrCast(@alignCast(Curl_conn_meta_get(conn, CURL_META_LDAP_CONN) orelse return CURLE_FAILED_INIT));
    var progress: c_uint = SASL_IDLE;
    var result = Curl_pop3_smtp_sasl_start(&li.sasl, data, true, &progress);
    oldapState(data, li, .OLDAP_SASL);
    if (result == CURLE_OK and progress != SASL_INPROGRESS) {
        result = Curl_pop3_smtp_sasl_is_blocked(&li.sasl, data);
    }
    return result;
}

pub const CURLEASY_MAGIC_NUMBER: u32 = 0xc0dedbad;

pub fn ldapsbValidEasy(ptr_opt: ?*anyopaque) ?*Curl_easy {
    const ptr = ptr_opt orelse return null;
    if (@intFromPtr(ptr) % @alignOf(u32) != 0) return null;
    const magic_ptr: *const u32 = @ptrCast(@alignCast(ptr));
    if (magic_ptr.* != CURLEASY_MAGIC_NUMBER) return null;
    return @ptrCast(ptr);
}

pub fn ldapsbTlsSetup(sbiod: *Sockbuf_IO_Desc, arg: ?*anyopaque) callconv(.c) c_int {
    if (ldapsbValidEasy(arg) == null) {
        sbiod.sbiod_pvt = null;
        return -1;
    }
    sbiod.sbiod_pvt = arg;
    return 0;
}

pub fn ldapsbTlsRemove(sbiod: *Sockbuf_IO_Desc) callconv(.c) c_int {
    sbiod.sbiod_pvt = null;
    return 0;
}

pub fn ldapsbTlsClose(sbiod: *Sockbuf_IO_Desc) callconv(.c) c_int {
    const data = ldapsbValidEasy(sbiod.sbiod_pvt) orelse return -1;
    if (Curl_ftp_acc_get_conn(data)) |conn| {
        if (Curl_conn_meta_get(conn, CURL_META_LDAP_CONN)) |li_raw| {
            const li: *ldapconninfo = @ptrCast(@alignCast(li_raw));
            if (li.dupfd != CURL_SOCKET_BAD) {
                Curl_ldap_sclose(li.dupfd);
                li.dupfd = CURL_SOCKET_BAD;
            }
        }
    }
    return 0;
}

pub fn ldapsbTlsCtrl(sbiod: *Sockbuf_IO_Desc, opt: c_int, arg: ?*anyopaque) callconv(.c) c_int {
    _ = arg;
    if (opt == LBER_SB_OPT_DATA_READY) {
        const data = ldapsbValidEasy(sbiod.sbiod_pvt) orelse return -1;
        return if (Curl_conn_data_pending(data, FIRSTSOCKET)) 1 else 0;
    }
    return 0;
}

pub fn ldapsbTlsRead(sbiod: *Sockbuf_IO_Desc, buf: *anyopaque, len: ber_len_t) callconv(.c) ber_slen_t {
    const data = ldapsbValidEasy(sbiod.sbiod_pvt) orelse {
        Curl_ldap_set_sockerrno_einval();
        return -1;
    };
    const conn = Curl_ftp_acc_get_conn(data) orelse return 0;
    const li_raw = Curl_conn_meta_get(conn, CURL_META_LDAP_CONN) orelse {
        Curl_ldap_set_sockerrno_einval();
        return -1;
    };
    const li: *ldapconninfo = @ptrCast(@alignCast(li_raw));
    const recv_fn = li.recv orelse {
        Curl_ldap_set_sockerrno_einval();
        return -1;
    };
    var nread: usize = 0;
    const result = recv_fn(data, FIRSTSOCKET, @ptrCast(buf), @intCast(len), &nread);
    if (result == CURLE_AGAIN) {
        Curl_ldap_set_sockerrno_ewouldblock();
    }
    return if (result != CURLE_OK) -1 else @intCast(nread);
}

pub fn ldapsbTlsWrite(sbiod: *Sockbuf_IO_Desc, buf: *anyopaque, len: ber_len_t) callconv(.c) ber_slen_t {
    const data = ldapsbValidEasy(sbiod.sbiod_pvt) orelse {
        Curl_ldap_set_sockerrno_einval();
        return -1;
    };
    const conn = Curl_ftp_acc_get_conn(data) orelse return 0;
    const li_raw = Curl_conn_meta_get(conn, CURL_META_LDAP_CONN) orelse {
        Curl_ldap_set_sockerrno_einval();
        return -1;
    };
    const li: *ldapconninfo = @ptrCast(@alignCast(li_raw));
    const send_fn = li.send orelse {
        Curl_ldap_set_sockerrno_einval();
        return -1;
    };
    var nwritten: usize = 0;
    const result = send_fn(data, FIRSTSOCKET, @ptrCast(buf), @intCast(len), false, &nwritten);
    if (result == CURLE_AGAIN) {
        Curl_ldap_set_sockerrno_ewouldblock();
    }
    return if (result != CURLE_OK) -1 else @intCast(nwritten);
}

pub const oldapSbRead = ldapsbTlsRead;
pub const oldapSbWrite = ldapsbTlsWrite;

var ldapsb_tls = Sockbuf_IO{
    .sbi_setup = ldapsbTlsSetup,
    .sbi_remove = ldapsbTlsRemove,
    .sbi_ctrl = ldapsbTlsCtrl,
    .sbi_read = ldapsbTlsRead,
    .sbi_write = ldapsbTlsWrite,
    .sbi_close = ldapsbTlsClose,
};

fn sslInstalled(conn: *connectdata) bool {
    const li_raw = Curl_conn_meta_get(conn, CURL_META_LDAP_CONN) orelse return false;
    const li: *ldapconninfo = @ptrCast(@alignCast(li_raw));
    return li.recv != null;
}

fn oldapSslConnect(data: *Curl_easy, newstate: ldapstate) CURLcode {
    if (comptime !use_ssl) return CURLE_FAILED_INIT;
    const conn = Curl_ftp_acc_get_conn(data) orelse return CURLE_FAILED_INIT;
    const li: *ldapconninfo = @ptrCast(@alignCast(Curl_conn_meta_get(conn, CURL_META_LDAP_CONN) orelse return CURLE_FAILED_INIT));
    const ld = li.ld orelse return CURLE_FAILED_INIT;

    var ssldone: bool = false;
    const result = Curl_conn_connect(data, FIRSTSOCKET, false, &ssldone);
    if (result != CURLE_OK) return result;
    oldapState(data, li, newstate);

    if (ssldone) {
        var sb: ?*Sockbuf = null;
        if (ldap_get_option(ld, LDAP_OPT_SOCKBUF, @ptrCast(&sb)) != LDAP_OPT_SUCCESS or
            sb == null or
            ber_sockbuf_add_io(sb.?, &ldapsb_tls, LBER_SBIOD_LEVEL_TRANSPORT, data) != 0)
        {
            return CURLE_FAILED_INIT;
        }
        li.recv = Curl_ldap_get_conn_recv(conn, FIRSTSOCKET);
        li.send = Curl_ldap_get_conn_send(conn, FIRSTSOCKET);
    }
    return result;
}

const saslldap = SASLproto{
    .service = "ldap",
    .sendauth = oldapPerformAuth,
    .contauth = oldapContinueAuth,
    .cancelauth = oldapCancelAuth,
    .getmessage = oldapGetMessage,
    .maxirlen = 0,
    .contcode = LDAP_SASL_BIND_IN_PROGRESS,
    .finalcode = LDAP_SUCCESS,
    .defmechs = SASL_AUTH_NONE,
    .flags = 0,
};

pub fn oldapConnDtor(key: ?*const anyopaque, key_len: usize, entry: ?*anyopaque) callconv(.c) void {
    _ = key;
    _ = key_len;
    const li_raw = entry orelse return;
    const li: *ldapconninfo = @ptrCast(@alignCast(li_raw));
    if (comptime use_openldap) {
        if (li.servercred) |sc| {
            if (sc.bv_val) |p| {
                if (sc.bv_len > 0) {
                    mem.secureZero(p, @intCast(sc.bv_len));
                }
            }
            ber_bvfree_x(sc, null);
            li.servercred = null;
        }
        if (li.ld) |ld| {
            _ = ldap_unbind_ext(ld, null, null);
            li.ld = null;
        }
        if (li.dupfd != CURL_SOCKET_BAD) {
            Curl_ldap_sclose(li.dupfd);
            li.dupfd = CURL_SOCKET_BAD;
        }
    }
    mem.secureZero(&li.sasl, @sizeOf(SASL));
    mem.freeSized(li, @sizeOf(ldapconninfo));
}

pub fn oldapReqDtor(key: ?*const anyopaque, key_len: usize, entry: ?*anyopaque) callconv(.c) void {
    _ = key;
    _ = key_len;
    const req_raw = entry orelse return;
    const req: *ldapreqinfo = @ptrCast(@alignCast(req_raw));
    mem.freeSized(req, @sizeOf(ldapreqinfo));
}

fn oldapPerformStarttls(data: *Curl_easy) CURLcode {
    const conn = Curl_ftp_acc_get_conn(data) orelse return CURLE_FAILED_INIT;
    const li: *ldapconninfo = @ptrCast(@alignCast(Curl_conn_meta_get(conn, CURL_META_LDAP_CONN) orelse return CURLE_FAILED_INIT));
    const ld = li.ld orelse return CURLE_FAILED_INIT;

    const rc = ldap_extended_operation(ld, LDAP_EXOP_START_TLS, null, null, null, &li.msgid);
    if (rc != LDAP_SUCCESS) {
        return oldapMapError(rc, CURLE_USE_SSL_FAILED);
    }
    oldapState(data, li, .OLDAP_STARTTLS);
    return CURLE_OK;
}

fn oldapConnect(data_opt: ?*anyopaque, done: *bool) callconv(.c) CURLcode {
    _ = done;
    if (comptime !use_openldap) {
        return CURLE_NOT_BUILT_IN;
    }
    const data: *Curl_easy = @ptrCast(data_opt orelse return CURLE_BAD_FUNCTION_ARGUMENT);
    const conn = Curl_ftp_acc_get_conn(data) orelse return CURLE_FAILED_INIT;
    const li_raw = alloc.Curl_calloc(1, @sizeOf(ldapconninfo)) orelse return CURLE_OUT_OF_MEMORY;
    const li: *ldapconninfo = @ptrCast(@alignCast(li_raw));
    li.* = .{};

    var result = Curl_conn_meta_set(conn, CURL_META_LDAP_CONN, li, oldapConnDtor);
    if (result != CURLE_OK) return result;

    li.proto = ldap_pvt_url_scheme2proto(Curl_ldap_get_origin_scheme_name(data));

    Curl_pop3_smtp_sasl_init(&li.sasl, data, &saslldap);

    result = oldapParseLoginOptions(conn);
    if (result != CURLE_OK) return result;

    const hosturl = Curl_ldap_format_hosturl(conn) orelse return CURLE_OUT_OF_MEMORY;
    defer alloc.Curl_free(hosturl);

    const sockfd = Curl_vssh_get_conn_firstsocket(conn);
    const dupfd = Curl_ldap_dup_socket(sockfd);
    if (dupfd == CURL_SOCKET_BAD) {
        return CURLE_COULDNT_CONNECT;
    }

    const rc = ldap_init_fd(@intCast(dupfd), li.proto, hosturl, &li.ld);
    if (rc != LDAP_SUCCESS) {
        Curl_ldap_sclose(dupfd);
        failfMsg(data, "LDAP local: Cannot connect to %s, %s", .{
            hosturl,
            ldap_err2string(rc) orelse "unknown",
        });
        return CURLE_COULDNT_CONNECT;
    }
    li.dupfd = dupfd;

    var ver: c_int = LDAP_VERSION3;
    _ = ldap_set_option(li.ld, LDAP_OPT_PROTOCOL_VERSION, &ver);
    _ = ldap_set_option(li.ld, LDAP_OPT_REFERRALS, LDAP_OPT_OFF);

    {
        var max: ber_len_t = 256 * 1024;
        var sb: ?*Sockbuf = null;
        if (ldap_get_option(li.ld, LDAP_OPT_SOCKBUF, @ptrCast(&sb)) != LDAP_OPT_SUCCESS or
            sb == null or
            ber_sockbuf_ctrl(sb.?, LBER_SB_OPT_SET_MAX_INCOMING, @ptrCast(&max)) == 0)
        {
            return CURLE_FAILED_INIT;
        }
    }

    if (comptime use_ssl) {
        if (Curl_ldap_conn_is_ssl(conn)) {
            return oldapSslConnect(data, .OLDAP_SSL);
        }
        if (Curl_get_use_ssl(data) != CURLUSESSL_NONE) {
            result = oldapPerformStarttls(data);
            if (result == CURLE_OK or Curl_get_use_ssl(data) != CURLUSESSL_TRY) {
                return result;
            }
        }
    }

    if (Curl_pop3_smtp_sasl_get_prefmech(&li.sasl) != SASL_AUTH_NONE) {
        return oldapPerformMechs(data);
    }

    return oldapPerformBind(data, .OLDAP_BIND);
}

fn oldapStateMechsResp(data: *Curl_easy, msg: *LDAPMessage, code: c_int) CURLcode {
    const conn = Curl_ftp_acc_get_conn(data) orelse return CURLE_FAILED_INIT;
    const li: *ldapconninfo = @ptrCast(@alignCast(Curl_conn_meta_get(conn, CURL_META_LDAP_CONN) orelse return CURLE_FAILED_INIT));
    const ld = li.ld orelse return CURLE_FAILED_INIT;

    var ber: ?*BerElement = null;
    var bv = BerValue{};
    var bvals: ?[*]BerValue = null;

    switch (ldap_msgtype(msg)) {
        LDAP_RES_SEARCH_ENTRY => {
            if (code != LDAP_SUCCESS and code != LDAP_NO_RESULTS_RETURNED) {
                return CURLE_LOGIN_DENIED;
            }
            var rc = ldap_get_dn_ber(ld, msg, &ber, &bv);
            if (rc < 0) {
                return oldapMapError(rc, CURLE_BAD_CONTENT_ENCODING);
            }
            rc = ldap_get_attribute_ber(ld, msg, ber.?, &bv, &bvals);
            while (rc == LDAP_SUCCESS) : (rc = ldap_get_attribute_ber(ld, msg, ber.?, &bv, &bvals)) {
                if (bv.bv_val == null) break;
                if (bvals) |vals| {
                    var i: usize = 0;
                    while (vals[i].bv_val) |val_ptr| : (i += 1) {
                        var llen: usize = 0;
                        const mech = Curl_pop3_smtp_sasl_decode_mech(
                            val_ptr,
                            @intCast(vals[i].bv_len),
                            &llen,
                        );
                        if (@as(usize, @intCast(vals[i].bv_len)) == llen) {
                            Curl_pop3_smtp_sasl_or_authmechs(&li.sasl, mech);
                        }
                    }
                    ber_memfree_x(vals, null);
                    bvals = null;
                }
            }
            ber_free(ber, 0);
            return CURLE_OK;
        },
        LDAP_RES_SEARCH_RESULT => {
            switch (code) {
                LDAP_SIZELIMIT_EXCEEDED => {
                    infofMsg(data, "Too many authentication mechanisms", .{});
                    if (Curl_pop3_smtp_sasl_can_authenticate(&li.sasl, data)) {
                        return oldapPerformSasl(data);
                    }
                    return CURLE_LOGIN_DENIED;
                },
                LDAP_SUCCESS, LDAP_NO_RESULTS_RETURNED => {
                    if (Curl_pop3_smtp_sasl_can_authenticate(&li.sasl, data)) {
                        return oldapPerformSasl(data);
                    }
                    return CURLE_LOGIN_DENIED;
                },
                else => return oldapMapError(code, CURLE_LOGIN_DENIED),
            }
        },
        else => return CURLE_OK,
    }
}

fn oldapStateSaslResp(data: *Curl_easy, msg: *LDAPMessage, code: c_int) CURLcode {
    const conn = Curl_ftp_acc_get_conn(data) orelse return CURLE_FAILED_INIT;
    const li: *ldapconninfo = @ptrCast(@alignCast(Curl_conn_meta_get(conn, CURL_META_LDAP_CONN) orelse return CURLE_FAILED_INIT));
    const ld = li.ld orelse return CURLE_FAILED_INIT;

    li.servercred = null;
    const rc = ldap_parse_sasl_bind_result(ld, msg, &li.servercred, 0);
    var result: CURLcode = CURLE_OK;
    if (rc != LDAP_SUCCESS) {
        failfMsg(data, "LDAP local: sasl ldap_parse_result %s", .{
            ldap_err2string(rc) orelse "unknown",
        });
        result = oldapMapError(rc, CURLE_LOGIN_DENIED);
    } else {
        var progress: c_uint = SASL_IDLE;
        result = Curl_pop3_smtp_sasl_continue(&li.sasl, data, code, &progress);
        if (result == CURLE_OK) {
            switch (progress) {
                SASL_DONE => oldapState(data, li, .OLDAP_STOP),
                SASL_IDLE => {
                    failfMsg(data, "Authentication cancelled", .{});
                    result = CURLE_LOGIN_DENIED;
                },
                else => {},
            }
        }
    }
    if (li.servercred) |sc| {
        if (sc.bv_val) |p| {
            if (sc.bv_len > 0) {
                mem.secureZero(p, @intCast(sc.bv_len));
            }
        }
        ber_bvfree_x(sc, null);
        li.servercred = null;
    }
    return result;
}

fn oldapStateBindResp(data: *Curl_easy, msg: *LDAPMessage, code: c_int) CURLcode {
    const conn = Curl_ftp_acc_get_conn(data) orelse return CURLE_FAILED_INIT;
    const li: *ldapconninfo = @ptrCast(@alignCast(Curl_conn_meta_get(conn, CURL_META_LDAP_CONN) orelse return CURLE_FAILED_INIT));
    const ld = li.ld orelse return CURLE_FAILED_INIT;

    if (code != LDAP_SUCCESS) {
        return oldapMapError(code, CURLE_LDAP_CANNOT_BIND);
    }

    var bv: ?*BerValue = null;
    const rc = ldap_parse_sasl_bind_result(ld, msg, &bv, 0);
    var result: CURLcode = CURLE_OK;
    if (rc != LDAP_SUCCESS) {
        failfMsg(data, "LDAP local: bind ldap_parse_sasl_bind_result %s", .{
            ldap_err2string(rc) orelse "unknown",
        });
        result = oldapMapError(rc, CURLE_LDAP_CANNOT_BIND);
    } else {
        oldapState(data, li, .OLDAP_STOP);
    }
    if (bv) |p| {
        if (p.bv_val) |v| {
            if (p.bv_len > 0) {
                mem.secureZero(v, @intCast(p.bv_len));
            }
        }
        ber_bvfree_x(p, null);
    }
    return result;
}

fn oldapConnecting(data_opt: ?*anyopaque, done: *bool) callconv(.c) CURLcode {
    if (comptime !use_openldap) {
        done.* = false;
        return CURLE_NOT_BUILT_IN;
    }
    const data: *Curl_easy = @ptrCast(data_opt orelse return CURLE_BAD_FUNCTION_ARGUMENT);
    const conn = Curl_ftp_acc_get_conn(data) orelse return CURLE_FAILED_INIT;
    const li: *ldapconninfo = @ptrCast(@alignCast(Curl_conn_meta_get(conn, CURL_META_LDAP_CONN) orelse return CURLE_FAILED_INIT));
    const ld = li.ld orelse return CURLE_FAILED_INIT;

    var result: CURLcode = CURLE_OK;
    var msg: ?*LDAPMessage = null;
    var tv = l_timeval{ .tv_sec = 0, .tv_usec = 0 };
    var code: c_int = LDAP_SUCCESS;

    if (li.state != .OLDAP_SSL and li.state != .OLDAP_TLS) {
        var rc = ldap_result(ld, li.msgid, LDAP_MSG_ONE, &tv, &msg);
        switch (rc) {
            0 => return CURLE_OK,
            @as(c_int, @intCast(LDAP_RES_SEARCH_ENTRY)),
            @as(c_int, @intCast(LDAP_RES_SEARCH_REFERENCE)),
            => {},
            else => {
                li.msgid = 0;
                if (rc < 0) {
                    failfMsg(data, "LDAP local: connecting ldap_result %s", .{
                        ldap_err2string(rc) orelse "unknown",
                    });
                    return oldapMapError(rc, CURLE_COULDNT_CONNECT);
                }
            },
        }

        rc = ldap_parse_result(ld, msg.?, &code, null, null, null, null, 0);
        if (rc != LDAP_SUCCESS) {
            code = rc;
        } else {
            Curl_ldap_set_info_httpcode(data, code);
        }

        const ssl_ok = if (comptime use_ssl)
            (sslInstalled(conn) or Curl_get_use_ssl(data) <= CURLUSESSL_TRY)
        else
            true;
        if (code == LDAP_PROTOCOL_ERROR and
            li.state != .OLDAP_BINDV2 and
            ssl_ok and
            Curl_pop3_smtp_sasl_get_prefmech(&li.sasl) == SASL_AUTH_NONE)
        {
            var version: c_int = LDAP_VERSION2;
            _ = ldap_set_option(ld, LDAP_OPT_PROTOCOL_VERSION, &version);
            _ = ldap_msgfree(msg);
            return oldapPerformBind(data, .OLDAP_BINDV2);
        }
    }

    switch (li.state) {
        .OLDAP_SSL => {
            if (comptime use_ssl) {
                result = oldapSslConnect(data, .OLDAP_SSL);
                if (result == CURLE_OK and sslInstalled(conn)) {
                    if (Curl_pop3_smtp_sasl_get_prefmech(&li.sasl) != SASL_AUTH_NONE) {
                        result = oldapPerformMechs(data);
                    } else {
                        result = oldapPerformBind(data, .OLDAP_BIND);
                    }
                }
            }
        },
        .OLDAP_STARTTLS => {
            if (comptime use_ssl) {
                if (code != LDAP_SUCCESS) {
                    if (Curl_get_use_ssl(data) != CURLUSESSL_TRY) {
                        result = oldapMapError(code, CURLE_USE_SSL_FAILED);
                    } else if (Curl_pop3_smtp_sasl_get_prefmech(&li.sasl) != SASL_AUTH_NONE) {
                        result = oldapPerformMechs(data);
                    } else {
                        result = oldapPerformBind(data, .OLDAP_BIND);
                    }
                } else {
                    result = Curl_ldap_add_ssl_cfilter(data, conn);
                    if (result == CURLE_OK) {
                        result = oldapSslConnect(data, .OLDAP_TLS);
                        if (result != CURLE_OK) {
                            result = oldapMapError(code, CURLE_USE_SSL_FAILED);
                        } else if (sslInstalled(conn)) {
                            if (Curl_pop3_smtp_sasl_get_prefmech(&li.sasl) != SASL_AUTH_NONE) {
                                result = oldapPerformMechs(data);
                            } else if (Curl_ldap_has_state_creds(data)) {
                                result = oldapPerformBind(data, .OLDAP_BIND);
                            } else {
                                oldapState(data, li, .OLDAP_STOP);
                                result = CURLE_OK;
                            }
                        }
                    }
                }
            }
        },
        .OLDAP_TLS => {
            if (comptime use_ssl) {
                result = oldapSslConnect(data, .OLDAP_TLS);
                if (result != CURLE_OK) {
                    result = oldapMapError(code, CURLE_USE_SSL_FAILED);
                } else if (sslInstalled(conn)) {
                    if (Curl_pop3_smtp_sasl_get_prefmech(&li.sasl) != SASL_AUTH_NONE) {
                        result = oldapPerformMechs(data);
                    } else if (Curl_ldap_has_state_creds(data)) {
                        result = oldapPerformBind(data, .OLDAP_BIND);
                    } else {
                        oldapState(data, li, .OLDAP_STOP);
                        result = CURLE_OK;
                    }
                }
            }
        },
        .OLDAP_MECHS => result = oldapStateMechsResp(data, msg.?, code),
        .OLDAP_SASL => result = oldapStateSaslResp(data, msg.?, code),
        .OLDAP_BIND, .OLDAP_BINDV2 => result = oldapStateBindResp(data, msg.?, code),
        else => result = CURLE_COULDNT_CONNECT,
    }

    _ = ldap_msgfree(msg);

    done.* = li.state == .OLDAP_STOP;
    if (done.*) {
        Curl_ldap_set_conn_recv(conn, oldapRecv);
    }

    if (result != CURLE_OK and li.msgid != 0) {
        _ = ldap_abandon_ext(ld, li.msgid, null, null);
        li.msgid = 0;
    }
    return result;
}

fn oldapDisconnect(data_opt: ?*anyopaque, conn_opt: ?*anyopaque, dead_connection: bool) callconv(.c) CURLcode {
    _ = dead_connection;
    if (comptime !use_openldap) return CURLE_OK;
    const data: *Curl_easy = @ptrCast(data_opt orelse return CURLE_OK);
    const conn: *connectdata = @ptrCast(conn_opt orelse return CURLE_OK);
    if (Curl_conn_meta_get(conn, CURL_META_LDAP_CONN)) |li_raw| {
        const li: *ldapconninfo = @ptrCast(@alignCast(li_raw));
        if (li.ld) |ld| {
            if (comptime use_ssl) {
                if (sslInstalled(conn)) {
                    var sb: ?*Sockbuf = null;
                    if (ldap_get_option(ld, LDAP_OPT_SOCKBUF, @ptrCast(&sb)) != LDAP_OPT_SUCCESS or
                        sb == null or
                        ber_sockbuf_add_io(sb.?, &ldapsb_tls, LBER_SBIOD_LEVEL_TRANSPORT, data) != 0)
                    {
                        return CURLE_FAILED_INIT;
                    }
                }
            }
            _ = ldap_unbind_ext(ld, null, null);
            li.ld = null;
        }
    }
    return CURLE_OK;
}

fn oldapDo(data_opt: ?*anyopaque, done: *bool) callconv(.c) CURLcode {
    if (comptime !use_openldap) {
        done.* = false;
        return CURLE_NOT_BUILT_IN;
    }
    const data: *Curl_easy = @ptrCast(data_opt orelse return CURLE_BAD_FUNCTION_ARGUMENT);
    const conn = Curl_ftp_acc_get_conn(data) orelse return CURLE_FAILED_INIT;
    const li: *ldapconninfo = @ptrCast(@alignCast(Curl_conn_meta_get(conn, CURL_META_LDAP_CONN) orelse return CURLE_FAILED_INIT));
    const ld = li.ld orelse return CURLE_FAILED_INIT;

    infofMsg(data, "LDAP local: %s", .{Curl_ldap_get_state_url(data) orelse ""});

    var lud: ?*LDAPURLDesc = null;
    var result = oldapUrlParse(data, &lud);
    if (result != CURLE_OK) return result;

    if (comptime use_ssl) {
        if (sslInstalled(conn)) {
            var sb: ?*Sockbuf = null;
            if (ldap_get_option(ld, LDAP_OPT_SOCKBUF, @ptrCast(&sb)) != LDAP_OPT_SUCCESS or
                sb == null or
                ber_sockbuf_add_io(sb.?, &ldapsb_tls, LBER_SBIOD_LEVEL_TRANSPORT, data) != 0)
            {
                ldap_free_urldesc(lud);
                return CURLE_FAILED_INIT;
            }
        }
    }

    var msgid: c_int = 0;
    const lud_ptr = lud.?;
    const rc = ldap_search_ext(
        ld,
        lud_ptr.lud_dn,
        lud_ptr.lud_scope,
        lud_ptr.lud_filter,
        lud_ptr.lud_attrs,
        0,
        null,
        null,
        null,
        0,
        &msgid,
    );
    ldap_free_urldesc(lud);
    if (rc != LDAP_SUCCESS) {
        failfMsg(data, "LDAP local: ldap_search_ext %s", .{
            ldap_err2string(rc) orelse "unknown",
        });
        return CURLE_LDAP_SEARCH_FAILED;
    }

    const lr_raw = alloc.Curl_calloc(1, @sizeOf(ldapreqinfo)) orelse {
        _ = ldap_abandon_ext(ld, msgid, null, null);
        return CURLE_OUT_OF_MEMORY;
    };
    const lr: *ldapreqinfo = @ptrCast(@alignCast(lr_raw));
    lr.* = .{ .msgid = msgid, .num_entries = 0 };
    result = Curl_meta_set(data, CURL_META_LDAP_EASY, lr, oldapReqDtor);
    if (result != CURLE_OK) {
        _ = ldap_abandon_ext(ld, msgid, null, null);
        return CURLE_OUT_OF_MEMORY;
    }

    Curl_xfer_setup_recv(data, FIRSTSOCKET, -1);
    done.* = true;
    return CURLE_OK;
}

fn oldapDone(data_opt: ?*anyopaque, res: CURLcode, premature: bool) callconv(.c) CURLcode {
    _ = res;
    _ = premature;
    if (comptime !use_openldap) return CURLE_OK;
    const data: *Curl_easy = @ptrCast(data_opt orelse return CURLE_OK);
    if (Curl_meta_get(data, CURL_META_LDAP_EASY)) |lr_raw| {
        const lr: *ldapreqinfo = @ptrCast(@alignCast(lr_raw));
        if (lr.msgid != 0) {
            if (Curl_ftp_acc_get_conn(data)) |conn| {
                if (Curl_conn_meta_get(conn, CURL_META_LDAP_CONN)) |li_raw| {
                    const li: *ldapconninfo = @ptrCast(@alignCast(li_raw));
                    if (li.ld) |ld| {
                        _ = ldap_abandon_ext(ld, lr.msgid, null, null);
                    }
                }
            }
            lr.msgid = 0;
        }
        Curl_meta_remove(data, CURL_META_LDAP_EASY);
    }
    return CURLE_OK;
}

fn oldapClientWrite(
    data: *Curl_easy,
    prefix: ?[]const u8,
    value: ?[]const u8,
    suffix: ?[]const u8,
) CURLcode {
    var result: CURLcode = CURLE_OK;
    if (prefix) |p| {
        var plen = p.len;
        const vlen = if (value) |v| v.len else 0;
        if (vlen == 0 and plen > 0 and p[plen - 1] == ' ') {
            plen -= 1;
        }
        if (plen > 0) {
            result = Curl_client_write(data, CLIENTWRITE_BODY, p.ptr, plen);
        }
    }
    if (result == CURLE_OK) {
        if (value) |v| {
            if (v.len > 0) {
                result = Curl_client_write(data, CLIENTWRITE_BODY, v.ptr, v.len);
            }
        }
    }
    if (result == CURLE_OK) {
        if (suffix) |s| {
            if (s.len > 0) {
                result = Curl_client_write(data, CLIENTWRITE_BODY, s.ptr, s.len);
            }
        }
    }
    return result;
}

fn oldapRecv(
    data: *Curl_easy,
    sockindex: i8,
    buf: [*]u8,
    len: usize,
    pnread: *usize,
) callconv(.c) CURLcode {
    _ = sockindex;
    _ = buf;
    _ = len;
    pnread.* = 0;
    const conn = Curl_ftp_acc_get_conn(data) orelse return CURLE_FAILED_INIT;
    const li: *ldapconninfo = @ptrCast(@alignCast(Curl_conn_meta_get(conn, CURL_META_LDAP_CONN) orelse return CURLE_FAILED_INIT));
    const lr: *ldapreqinfo = @ptrCast(@alignCast(Curl_meta_get(data, CURL_META_LDAP_EASY) orelse return CURLE_FAILED_INIT));
    const ld = li.ld orelse return CURLE_FAILED_INIT;

    var msg: ?*LDAPMessage = null;
    var ber: ?*BerElement = null;
    var tv = l_timeval{ .tv_sec = 0, .tv_usec = 0 };
    var bv = BerValue{};
    var bvals: ?[*]BerValue = null;
    var result: CURLcode = CURLE_AGAIN;

    var rc = ldap_result(ld, lr.msgid, LDAP_MSG_ONE, &tv, &msg);
    if (rc < 0) {
        failfMsg(data, "LDAP local: search ldap_result %s", .{
            ldap_err2string(rc) orelse "unknown",
        });
        result = CURLE_RECV_ERROR;
    }

    const m = msg orelse return result;
    result = CURLE_OK;

    switch (ldap_msgtype(m)) {
        LDAP_RES_SEARCH_RESULT => {
            lr.msgid = 0;
            var code: c_int = LDAP_SUCCESS;
            var info: ?[*:0]u8 = null;
            rc = ldap_parse_result(ld, m, &code, null, &info, null, null, 0);
            if (rc != LDAP_SUCCESS) {
                failfMsg(data, "LDAP local: search ldap_parse_result %s", .{
                    ldap_err2string(rc) orelse "unknown",
                });
                result = CURLE_LDAP_SEARCH_FAILED;
            } else {
                Curl_ldap_set_info_httpcode(data, code);
                switch (code) {
                    LDAP_SIZELIMIT_EXCEEDED => {
                        infofMsg(data, "There are more than %d entries", .{lr.num_entries});
                        Curl_ldap_set_req_size_from_bytecount(data);
                    },
                    LDAP_SUCCESS => {
                        Curl_ldap_set_req_size_from_bytecount(data);
                    },
                    else => {
                        failfMsg(data, "LDAP remote: search failed %s %s", .{
                            ldap_err2string(code) orelse "unknown",
                            info orelse "",
                        });
                        result = CURLE_LDAP_SEARCH_FAILED;
                    },
                }
            }
            if (info) |p| ldap_memfree(p);
        },
        LDAP_RES_SEARCH_ENTRY => {
            lr.num_entries += 1;
            rc = ldap_get_dn_ber(ld, m, &ber, &bv);
            if (rc < 0) {
                result = CURLE_RECV_ERROR;
            } else {
                const dn_slice = if (bv.bv_val) |p| p[0..@intCast(bv.bv_len)] else "";
                if (oldapStrNeedsBase64(dn_slice)) {
                    var dn_b64: ?[*:0]u8 = null;
                    var dn_b64_sz: usize = 0;
                    result = curlx_parse.curlx_base64_encode(dn_slice.ptr, dn_slice.len, &dn_b64, &dn_b64_sz);
                    if (result == CURLE_OK) {
                        const enc_slice = if (dn_b64) |p| p[0..dn_b64_sz] else "";
                        result = oldapClientWrite(data, "DN:: ", enc_slice, "\n");
                    }
                    if (dn_b64) |p| alloc.Curl_free(p);
                } else {
                    result = oldapClientWrite(data, "DN: ", dn_slice, "\n");
                }

                if (result == CURLE_OK) {
                    rc = ldap_get_attribute_ber(ld, m, ber.?, &bv, &bvals);
                    while (rc == LDAP_SUCCESS) : (rc = ldap_get_attribute_ber(ld, m, ber.?, &bv, &bvals)) {
                        const attr_ptr = bv.bv_val orelse break;
                        const attr_len: usize = @intCast(bv.bv_len);
                        const attr_slice = attr_ptr[0..attr_len];

                        if (oldapStrNeedsBase64(attr_slice)) {
                            failfMsg(data, "LDAP local: attribute type contains illegal bytes", .{});
                            if (bvals) |vals| ber_memfree_x(vals, null);
                            result = CURLE_WEIRD_SERVER_REPLY;
                            break;
                        }

                        if (bvals == null) {
                            result = oldapClientWrite(data, "\t", attr_slice, ":\n");
                            if (result != CURLE_OK) break;
                            continue;
                        }

                        const binary = attr_len > 7 and
                            primitives.curl_strnequal(@ptrCast(attr_ptr + (attr_len - 7)), ";binary", 7) != 0;

                        const vals = bvals.?;
                        var i: usize = 0;
                        while (vals[i].bv_val) |val_ptr| : (i += 1) {
                            const val_len: usize = @intCast(vals[i].bv_len);
                            const val_slice = val_ptr[0..val_len];

                            result = oldapClientWrite(data, "\t", attr_slice, ":");
                            if (result != CURLE_OK) break;

                            const binval = if (!binary) oldapStrNeedsBase64(val_slice) else false;
                            if (binary or binval) {
                                var val_b64: ?[*:0]u8 = null;
                                var val_b64_sz: usize = 0;
                                if (val_len > 0) {
                                    result = curlx_parse.curlx_base64_encode(val_slice.ptr, val_len, &val_b64, &val_b64_sz);
                                }
                                if (result == CURLE_OK) {
                                    const enc_slice = if (val_b64) |p| p[0..val_b64_sz] else "";
                                    result = oldapClientWrite(data, ": ", enc_slice, "\n");
                                }
                                if (val_b64) |p| alloc.Curl_free(p);
                            } else {
                                result = oldapClientWrite(data, " ", val_slice, "\n");
                            }
                            if (result != CURLE_OK) break;
                        }

                        ber_memfree_x(vals, null);
                        bvals = null;
                        if (result == CURLE_OK) {
                            result = oldapClientWrite(data, "\n", null, null);
                        }
                        if (result != CURLE_OK) break;
                    }
                }

                if (result == CURLE_OK) {
                    result = oldapClientWrite(data, "\n", null, null);
                }
                if (result == CURLE_OK) {
                    result = CURLE_AGAIN;
                }
            }
        },
        else => {},
    }

    ber_free(ber, 0);
    _ = ldap_msgfree(m);
    return result;
}

// ============================================================================
// Legacy LDAP / WinLDAP Backend Implementation (lib/ldap.c)
// ============================================================================

pub const LdapUrlDescLow = struct {
    lud_dn: ?[*:0]u8 = null,
    lud_attrs: ?[*]?[*:0]u8 = null,
    lud_attrs_dups: usize = 0,
    lud_scope: c_int = LDAP_SCOPE_BASE,
    lud_filter: ?[*:0]u8 = null,
    lud_port: c_int = 0,
    lud_host: ?[*:0]const u8 = null,
};

pub fn str2scope(p: [*:0]const u8) c_int {
    if (primitives.curl_strequal(p, "one") != 0) return LDAP_SCOPE_ONELEVEL;
    if (primitives.curl_strequal(p, "onetree") != 0) return LDAP_SCOPE_ONELEVEL;
    if (primitives.curl_strequal(p, "base") != 0) return LDAP_SCOPE_BASE;
    if (primitives.curl_strequal(p, "sub") != 0) return LDAP_SCOPE_SUBTREE;
    if (primitives.curl_strequal(p, "subtree") != 0) return LDAP_SCOPE_SUBTREE;
    return -1;
}

pub fn numEntries(s: [*:0]const u8) usize {
    var items: usize = 1;
    var i: usize = 0;
    while (s[i] != 0) : (i += 1) {
        if (s[i] == ',') items += 1;
    }
    return items;
}

fn strchrMut(s: [*:0]u8, ch: u8) ?[*:0]u8 {
    var p = s;
    while (p[0] != 0) : (p += 1) {
        if (p[0] == ch) return p;
    }
    return null;
}

pub fn ldapCleanupUrldescLowFields(ludp: *LdapUrlDescLow) void {
    if (ludp.lud_dn) |p| {
        alloc.Curl_free(p);
        ludp.lud_dn = null;
    }
    if (ludp.lud_filter) |p| {
        alloc.Curl_free(p);
        ludp.lud_filter = null;
    }
    if (ludp.lud_attrs) |attrs| {
        var i: usize = 0;
        while (i < ludp.lud_attrs_dups) : (i += 1) {
            if (attrs[i]) |a| {
                alloc.Curl_free(a);
                attrs[i] = null;
            }
        }
        alloc.Curl_free(@ptrCast(attrs));
        ludp.lud_attrs = null;
    }
    ludp.lud_attrs_dups = 0;
}

const LdapUrlParseLowError = error{
    OutOfMemory,
    InvalidSyntax,
};

fn ldapUrlParse2LowInner(
    up_path_opt: ?[*:0]const u8,
    up_query_opt: ?[*:0]const u8,
    scheme_name: [*:0]const u8,
    host: [*:0]const u8,
    port: c_int,
    ludp: *LdapUrlDescLow,
) LdapUrlParseLowError!void {
    const up_path = up_path_opt orelse return error.InvalidSyntax;
    if (up_path[0] != '/' or
        (primitives.curl_strequal(scheme_name, "ldap") == 0 and
            primitives.curl_strequal(scheme_name, "ldaps") == 0))
    {
        return error.InvalidSyntax;
    }

    ludp.lud_scope = LDAP_SCOPE_BASE;
    ludp.lud_port = port;
    ludp.lud_host = host;

    errdefer ldapCleanupUrldescLowFields(ludp);

    const path = alloc.Curl_strdup(up_path + 1) orelse return error.OutOfMemory;
    defer alloc.Curl_free(path);
    var p: ?[*:0]u8 = path;

    var query: ?[*:0]u8 = null;
    if (up_query_opt) |uq| {
        query = alloc.Curl_strdup(uq) orelse return error.OutOfMemory;
    }
    defer if (query) |q_alloc| alloc.Curl_free(q_alloc);
    var q: ?[*:0]u8 = query;

    if (p.?[0] != 0) {
        var unescaped: ?[*:0]u8 = null;
        if (Curl_urldecode(p.?, 0, &unescaped, null, format_parse.REJECT_ZERO) != CURLE_OK) {
            return error.OutOfMemory;
        }
        ludp.lud_dn = unescaped;
    }

    p = q;
    if (p == null) return;

    q = strchrMut(p.?, '?');
    if (q) |qptr| {
        qptr[0] = 0;
        q = qptr + 1;
    }

    if (p.?[0] != 0) {
        const count = numEntries(p.?);
        const attrs_raw = alloc.Curl_calloc(count + 1, @sizeOf(?[*:0]u8)) orelse return error.OutOfMemory;
        const attrs: [*]?[*:0]u8 = @ptrCast(@alignCast(attrs_raw));
        ludp.lud_attrs = attrs;

        var atp: ?[*:0]const u8 = p.?;
        var i: usize = 0;
        while (i < count) : (i += 1) {
            var out = curlx_parse.Curl_str{ .str = null, .len = 0 };
            if (curlx_str_until(&atp, &out, 1024, ',') != 0) break;
            var unescaped: ?[*:0]u8 = null;
            if (Curl_urldecode(out.str.?, out.len, &unescaped, null, format_parse.REJECT_ZERO) != CURLE_OK) {
                return error.OutOfMemory;
            }
            attrs[i] = unescaped;
            ludp.lud_attrs_dups += 1;
            if (curlx_str_single(&atp, ',') != 0) break;
        }
    }

    p = q;
    if (p == null) return;

    q = strchrMut(p.?, '?');
    if (q) |qptr| {
        qptr[0] = 0;
        q = qptr + 1;
    }

    if (p.?[0] != 0) {
        ludp.lud_scope = str2scope(p.?);
        if (ludp.lud_scope == -1) {
            return error.InvalidSyntax;
        }
    }

    p = q;
    if (p == null) return;

    q = strchrMut(p.?, '?');
    if (q) |qptr| {
        qptr[0] = 0;
        q = qptr + 1;
    }

    if (p.?[0] != 0) {
        var unescaped: ?[*:0]u8 = null;
        if (Curl_urldecode(p.?, 0, &unescaped, null, format_parse.REJECT_CTRL) != CURLE_OK) {
            return error.OutOfMemory;
        }
        ludp.lud_filter = unescaped;
    }

    p = q;
    if (p != null and p.?[0] == 0) {
        return error.InvalidSyntax;
    }
}

pub fn ldapUrlParse2Low(
    up_path_opt: ?[*:0]const u8,
    up_query_opt: ?[*:0]const u8,
    scheme_name: [*:0]const u8,
    host: [*:0]const u8,
    port: c_int,
    ludp: *LdapUrlDescLow,
) c_int {
    ldapUrlParse2LowInner(
        up_path_opt,
        up_query_opt,
        scheme_name,
        host,
        port,
        ludp,
    ) catch |err| return switch (err) {
        error.OutOfMemory => LDAP_NO_MEMORY,
        error.InvalidSyntax => LDAP_INVALID_SYNTAX,
    };
    return LDAP_SUCCESS;
}

pub fn ldapFreeUrldescLow(ludp: ?*LdapUrlDescLow) void {
    const d = ludp orelse return;
    ldapCleanupUrldescLowFields(d);
    mem.freeSized(d, @sizeOf(LdapUrlDescLow));
}

fn ldapValueNeedsBase64(attr_slice: []const u8, val: *const BerValue) bool {
    if (attr_slice.len > 7 and std.mem.eql(u8, attr_slice[attr_slice.len - 7 ..], ";binary")) {
        return true;
    }
    const v_slice = if (val.bv_val) |p| p[0..@intCast(val.bv_len)] else "";
    return oldapStrNeedsBase64(v_slice);
}

fn showVals(data: *Curl_easy, vals: [*]?*BerValue, attr: [*:0]const u8) CURLcode {
    const attr_len = std.mem.len(attr);
    const attr_slice = attr[0..attr_len];

    if (oldapStrNeedsBase64(attr_slice)) {
        failfMsg(data, "LDAP local: attribute type contains illegal bytes", .{});
        return CURLE_WEIRD_SERVER_REPLY;
    }

    var result: CURLcode = CURLE_OK;
    var i: usize = 0;
    while (vals[i]) |val_ptr| : (i += 1) {
        result = Curl_client_write(data, CLIENTWRITE_BODY, "\t", 1);
        if (result == CURLE_OK) {
            result = Curl_client_write(data, CLIENTWRITE_BODY, attr, attr_len);
        }
        if (result == CURLE_OK) {
            result = Curl_client_write(data, CLIENTWRITE_BODY, ":", 1);
        }
        if (result != CURLE_OK) break;

        if (ldapValueNeedsBase64(attr_slice, val_ptr)) {
            var val_b64: ?[*:0]u8 = null;
            var val_b64_sz: usize = 0;
            const vlen: usize = @intCast(val_ptr.bv_len);
            if (vlen > 0 and val_ptr.bv_val != null) {
                result = curlx_parse.curlx_base64_encode(val_ptr.bv_val.?, vlen, &val_b64, &val_b64_sz);
            }
            if (result == CURLE_OK) {
                result = Curl_client_write(data, CLIENTWRITE_BODY, ": ", 2);
            }
            if (result == CURLE_OK and val_b64_sz > 0 and val_b64 != null) {
                result = Curl_client_write(data, CLIENTWRITE_BODY, val_b64.?, val_b64_sz);
            }
            if (val_b64) |p| alloc.Curl_free(p);
        } else {
            result = Curl_client_write(data, CLIENTWRITE_BODY, " ", 1);
            if (result == CURLE_OK) {
                const vlen: usize = @intCast(val_ptr.bv_len);
                if (vlen > 0 and val_ptr.bv_val != null) {
                    result = Curl_client_write(data, CLIENTWRITE_BODY, val_ptr.bv_val.?, vlen);
                }
            }
        }

        if (result == CURLE_OK) {
            result = Curl_client_write(data, CLIENTWRITE_BODY, "\n", 1);
        }
        if (result != CURLE_OK) break;
    }
    return result;
}

fn legacyLdapDo(data_opt: ?*anyopaque, done: *bool) callconv(.c) CURLcode {
    if (comptime !use_legacy_ldap) {
        done.* = false;
        return CURLE_NOT_BUILT_IN;
    }
    const data: *Curl_easy = @ptrCast(data_opt orelse return CURLE_BAD_FUNCTION_ARGUMENT);
    const conn = Curl_ftp_acc_get_conn(data) orelse return CURLE_FAILED_INIT;

    done.* = true;
    infofMsg(data, "LDAP local: LDAP Vendor = %s ; LDAP Version = %d", .{
        Curl_ldap_get_vendor_name(),
        Curl_ldap_get_vendor_version(),
    });
    infofMsg(data, "LDAP local: %s", .{Curl_ldap_get_state_url(data) orelse ""});

    var result: CURLcode = CURLE_OK;
    var rc: c_int = LDAP_SUCCESS;
    var server: ?*LDAP = null;
    var ludp: ?*LDAPURLDesc = null;
    var ludp_low: ?*LdapUrlDescLow = null;
    var ldapmsg: ?*LDAPMessage = null;
    var ber: ?*BerElement = null;
    var num: c_int = 0;

    defer {
        if (ber) |b| ber_free(b, 0);
        if (ldapmsg) |m| _ = ldap_msgfree(m);
        if (rc == LDAP_SIZELIMIT_EXCEEDED) {
            infofMsg(data, "There are more than %d entries", .{num});
        }
        if (comptime use_win32_ldap) {
            ldapFreeUrldescLow(ludp_low);
        } else {
            if (ludp) |l| ldap_free_urldesc(l);
        }
        if (server) |s| _ = ldap_unbind_s(s);
        Curl_xfer_setup_nop(data);
        Curl_ldap_connclose(conn);
    }

    if (comptime use_win32_ldap) {
        const low_raw = alloc.Curl_calloc(1, @sizeOf(LdapUrlDescLow)) orelse {
            rc = LDAP_NO_MEMORY;
            failfMsg(data, "Bad LDAP URL: %s", .{ldap_err2string(rc) orelse "unknown"});
            return CURLE_URL_MALFORMAT;
        };
        const low_ptr: *LdapUrlDescLow = @ptrCast(@alignCast(low_raw));
        low_ptr.* = .{};
        rc = ldapUrlParse2Low(
            Curl_ldap_get_up_path(data),
            Curl_ldap_get_up_query(data),
            Curl_ldap_get_origin_scheme_name(data),
            Curl_ldap_get_conn_hostname(conn),
            Curl_vssh_get_conn_remote_port(conn),
            low_ptr,
        );
        if (rc != LDAP_SUCCESS) {
            ldapFreeUrldescLow(low_ptr);
        } else {
            ludp_low = low_ptr;
        }
    } else {
        rc = ldap_url_parse(Curl_ldap_get_state_url(data) orelse "", &ludp);
    }
    if (rc != LDAP_SUCCESS) {
        failfMsg(data, "Bad LDAP URL: %s", .{ldap_err2string(rc) orelse "unknown"});
        return CURLE_URL_MALFORMAT;
    }

    var remote_port: c_int = 0;
    result = Curl_ldap_get_remote_port(data, conn, &remote_port);
    if (result != CURLE_OK) return result;

    const ldap_ssl = Curl_ldap_conn_is_ssl(conn);
    infofMsg(data, "LDAP local: trying to establish %s connection", .{
        if (ldap_ssl) "encrypted" else "cleartext",
    });

    const host = Curl_ldap_get_conn_hostname(conn);
    if (comptime use_win32_ldap) {
        if (ldap_ssl) {
            server = ldap_sslinit(host, remote_port, 1);
        } else {
            server = ldap_init(host, remote_port);
        }
    } else {
        server = ldap_init(host, remote_port);
    }
    const srv = server orelse {
        failfMsg(data, "LDAP: cannot setup connect to %s:%d", .{
            Curl_ldap_get_conn_user_hostname(conn),
            remote_port,
        });
        return CURLE_COULDNT_CONNECT;
    };

    var ldap_timeout = l_timeval{ .tv_sec = 10, .tv_usec = 0 };
    _ = ldap_set_option(srv, LDAP_OPT_NETWORK_TIMEOUT, &ldap_timeout);
    var ldap_proto: c_int = LDAP_VERSION3;
    _ = ldap_set_option(srv, LDAP_OPT_PROTOCOL_VERSION, &ldap_proto);
    _ = ldap_set_option(srv, LDAP_OPT_REFERRALS, LDAP_OPT_OFF);

    if (ldap_ssl) {
        if (comptime use_win32_ldap) {
            _ = ldap_set_option(srv, LDAP_OPT_SSL, LDAP_OPT_ON);
            if (!Curl_ldap_get_ssl_verifypeer(conn)) {
                if (Curl_ldap_get_ssl_verifyhost(conn)) {
                    failfMsg(data, "LDAP local: host verification cannot be enabled when peer verification is disabled for Windows native LDAP", .{});
                    return CURLE_NOT_BUILT_IN;
                }
                Curl_ldap_set_win32_bypass_cert_verify(srv);
            }
        } else {
            var ldap_option: c_int = LDAP_OPT_X_TLS_NEVER;
            const ldap_ca = Curl_ldap_get_ssl_cafile(conn);
            if (Curl_ldap_get_ssl_verifypeer(conn)) {
                if (Curl_ldap_get_ssl_cert_type(conn)) |ct| {
                    if (primitives.curl_strequal(ct, "PEM") == 0) {
                        failfMsg(data, "LDAP local: ERROR OpenLDAP only supports PEM cert-type", .{});
                        return CURLE_SSL_CERTPROBLEM;
                    }
                }
                const ca = ldap_ca orelse {
                    failfMsg(data, "LDAP local: ERROR PEM CA cert not set", .{});
                    return CURLE_SSL_CERTPROBLEM;
                };
                infofMsg(data, "LDAP local: using PEM CA cert: %s", .{ca});
                rc = ldap_set_option(srv, LDAP_OPT_X_TLS_CACERTFILE, ca);
                if (rc != LDAP_SUCCESS) {
                    failfMsg(data, "LDAP local: ERROR setting PEM CA cert: %s", .{
                        ldap_err2string(rc) orelse "unknown",
                    });
                    return CURLE_SSL_CERTPROBLEM;
                }
                ldap_option = LDAP_OPT_X_TLS_DEMAND;
            }
            rc = ldap_set_option(srv, LDAP_OPT_X_TLS_REQUIRE_CERT, &ldap_option);
            if (rc != LDAP_SUCCESS) {
                failfMsg(data, "LDAP local: ERROR setting cert verify mode: %s", .{
                    ldap_err2string(rc) orelse "unknown",
                });
                return CURLE_SSL_CERTPROBLEM;
            }
            ldap_option = LDAP_OPT_X_TLS_HARD;
            rc = ldap_set_option(srv, LDAP_OPT_X_TLS, &ldap_option);
            if (rc != LDAP_SUCCESS) {
                failfMsg(data, "LDAP local: ERROR setting SSL/TLS mode: %s", .{
                    ldap_err2string(rc) orelse "unknown",
                });
                return CURLE_SSL_CERTPROBLEM;
            }
        }
    } else if (Curl_get_use_ssl(data) > CURLUSESSL_TRY) {
        failfMsg(data, "LDAP local: explicit TLS not supported", .{});
        return CURLE_NOT_BUILT_IN;
    }

    const user = Curl_ldap_get_state_creds_user(data);
    const passwd = Curl_ldap_get_state_creds_passwd(data);

    if (comptime use_win32_ldap) {
        rc = Curl_ldap_win_bind(data, srv, user, passwd);
    } else {
        rc = ldap_simple_bind_s(srv, user, passwd);
    }
    if (!ldap_ssl and rc != LDAP_SUCCESS) {
        ldap_proto = LDAP_VERSION2;
        _ = ldap_set_option(srv, LDAP_OPT_PROTOCOL_VERSION, &ldap_proto);
        if (comptime use_win32_ldap) {
            rc = Curl_ldap_win_bind(data, srv, user, passwd);
        } else {
            rc = ldap_simple_bind_s(srv, user, passwd);
        }
    }
    if (rc != LDAP_SUCCESS) {
        if (comptime use_win32_ldap) {
            failfMsg(data, "LDAP local: bind via ldap_win_bind %s", .{
                ldap_err2string(rc) orelse "unknown",
            });
        } else {
            failfMsg(data, "LDAP local: bind via ldap_simple_bind_s %s", .{
                ldap_err2string(rc) orelse "unknown",
            });
        }
        return CURLE_LDAP_CANNOT_BIND;
    }

    Curl_pgrsReset(data);
    if (comptime use_win32_ldap) {
        const l = ludp_low.?;
        rc = ldap_search_s(srv, l.lud_dn, l.lud_scope, l.lud_filter, l.lud_attrs, 0, &ldapmsg);
    } else {
        const l = ludp.?;
        rc = ldap_search_s(srv, l.lud_dn, l.lud_scope, l.lud_filter, l.lud_attrs, 0, &ldapmsg);
    }

    if (rc != LDAP_SUCCESS and rc != LDAP_SIZELIMIT_EXCEEDED) {
        failfMsg(data, "LDAP remote: %s", .{ldap_err2string(rc) orelse "unknown"});
        return CURLE_LDAP_SEARCH_FAILED;
    }

    var entry_it = if (ldapmsg) |m| ldap_first_entry(srv, m) else null;
    while (entry_it) |entry| : ({
        entry_it = ldap_next_entry(srv, entry);
        num += 1;
    }) {
        {
            const dn = ldap_get_dn(srv, entry);
            if (dn) |dn_str| {
                const name_len = std.mem.len(dn_str);
                const name_slice = dn_str[0..name_len];
                if (oldapStrNeedsBase64(name_slice)) {
                    var dn_b64: ?[*:0]u8 = null;
                    var dn_b64_sz: usize = 0;
                    result = curlx_parse.curlx_base64_encode(name_slice.ptr, name_len, &dn_b64, &dn_b64_sz);
                    if (result == CURLE_OK) {
                        result = Curl_client_write(data, CLIENTWRITE_BODY, "DN:: ", 5);
                    }
                    if (result == CURLE_OK and dn_b64_sz > 0 and dn_b64 != null) {
                        result = Curl_client_write(data, CLIENTWRITE_BODY, dn_b64.?, dn_b64_sz);
                    }
                    if (dn_b64) |p| alloc.Curl_free(p);
                } else {
                    result = Curl_client_write(data, CLIENTWRITE_BODY, "DN: ", 4);
                    if (result == CURLE_OK and name_len > 0) {
                        result = Curl_client_write(data, CLIENTWRITE_BODY, dn_str, name_len);
                    }
                }
                if (result == CURLE_OK) {
                    result = Curl_client_write(data, CLIENTWRITE_BODY, "\n", 1);
                }
                ldap_memfree(dn_str);
            } else {
                result = CURLE_FAILED_INIT;
            }
            if (result != CURLE_OK) return result;
        }

        var attribute = ldap_first_attribute(srv, entry, &ber);
        while (attribute) |attr_str| : (attribute = if (ber) |b| ldap_next_attribute(srv, entry, b) else null) {
            if (ldap_get_values_len(srv, entry, attr_str)) |vals| {
                result = showVals(data, vals, attr_str);
                ldap_value_free_len(vals);
            }
            ldap_memfree(attr_str);
            if (result == CURLE_OK) {
                result = Curl_client_write(data, CLIENTWRITE_BODY, "\n", 1);
            }
            if (result != CURLE_OK) return result;
        }

        if (ber) |b| {
            ber_free(b, 0);
            ber = null;
        }
    }

    return result;
}

// ============================================================================
// Version & Protocol Dispatch Table
// ============================================================================

pub fn Curl_ldap_version(buf: [*]u8, bufsz: usize) callconv(.c) void {
    if (bufsz == 0) return;
    if (comptime use_openldap) {
        var api = LDAPAPIInfo{ .ldapai_info_version = LDAP_API_INFO_VERSION };
        if (ldap_get_option(null, LDAP_OPT_API_INFO, @ptrCast(&api)) == LDAP_OPT_SUCCESS) {
            const ver_u: c_uint = @intCast(@max(api.ldapai_vendor_version, 0));
            const patch: c_uint = ver_u % 100;
            const major: c_uint = ver_u / 10000;
            const minor: c_uint = ((ver_u - (major * 10000)) - patch) / 100;
            const vname = if (api.ldapai_vendor_name) |vn| std.mem.span(vn) else "OpenLDAP";
            const s = std.fmt.bufPrint(buf[0 .. bufsz - 1], "{s}/{d}.{d}.{d}", .{
                vname,
                major,
                minor,
                patch,
            }) catch "OpenLDAP";
            buf[s.len] = 0;
            if (api.ldapai_vendor_name) |vn| ldap_memfree(vn);
            if (api.ldapai_extensions) |ext| ber_memvfree_x(@ptrCast(ext), null);
            return;
        }
        const prefix = "OpenLDAP";
        const copy_len = @min(prefix.len, bufsz - 1);
        @memcpy(buf[0..copy_len], prefix[0..copy_len]);
        buf[copy_len] = 0;
        return;
    } else if (comptime use_legacy_ldap) {
        if (comptime use_win32_ldap) {
            const prefix = "WinLDAP";
            const copy_len = @min(prefix.len, bufsz - 1);
            @memcpy(buf[0..copy_len], prefix[0..copy_len]);
            buf[copy_len] = 0;
            return;
        }
        var api = LDAPAPIInfo{ .ldapai_info_version = LDAP_API_INFO_VERSION };
        if (ldap_get_option(null, LDAP_OPT_API_INFO, @ptrCast(&api)) == 0) {
            const ver_u: c_uint = @intCast(@max(api.ldapai_vendor_version, 0));
            const patch: c_uint = ver_u % 100;
            const major: c_uint = ver_u / 10000;
            const minor: c_uint = ((ver_u - (major * 10000)) - patch) / 100;
            const vname = if (api.ldapai_vendor_name) |vn| std.mem.span(vn) else "LDAP";
            const flavor = if (comptime builtin.os.tag.isDarwin()) "/Apple" else "";
            const s = std.fmt.bufPrint(buf[0 .. bufsz - 1], "{s}/{d}.{d}.{d}{s}", .{
                vname,
                major,
                minor,
                patch,
                flavor,
            }) catch "LDAP";
            buf[s.len] = 0;
            if (api.ldapai_vendor_name) |vn| ldap_memfree(vn);
            if (api.ldapai_extensions) |ext| ber_memvfree_x(@ptrCast(ext), null);
            return;
        }
        const prefix = "LDAP/1";
        const copy_len = @min(prefix.len, bufsz - 1);
        @memcpy(buf[0..copy_len], prefix[0..copy_len]);
        buf[copy_len] = 0;
        return;
    } else {
        const prefix = "OpenLDAP";
        const copy_len = @min(prefix.len, bufsz - 1);
        @memcpy(buf[0..copy_len], prefix[0..copy_len]);
        buf[copy_len] = 0;
    }
}

fn ldapDisabledDo(data: ?*anyopaque, done: *bool) callconv(.c) CURLcode {
    _ = data;
    done.* = false;
    return CURLE_NOT_BUILT_IN;
}

pub const Curl_protocol_ldap: Curl_protocol = if (use_openldap) .{
    .setup_connection = oldapSetupConnection,
    .do_it = oldapDo,
    .done = oldapDone,
    .connect_it = oldapConnect,
    .connecting = oldapConnecting,
    .disconnect = oldapDisconnect,
} else if (use_legacy_ldap) .{
    .do_it = legacyLdapDo,
} else .{
    .do_it = ldapDisabledDo,
};

// ============================================================================
// Unit Tests
// ============================================================================

test "LDAP state names and LDIF base64 detection" {
    try std.testing.expectEqualStrings("STOP", std.mem.span(oldapStateName(.OLDAP_STOP)));
    try std.testing.expectEqualStrings("SSL", std.mem.span(oldapStateName(.OLDAP_SSL)));
    try std.testing.expectEqualStrings("STARTTLS", std.mem.span(oldapStateName(.OLDAP_STARTTLS)));
    try std.testing.expectEqualStrings("TLS", std.mem.span(oldapStateName(.OLDAP_TLS)));
    try std.testing.expectEqualStrings("MECHS", std.mem.span(oldapStateName(.OLDAP_MECHS)));
    try std.testing.expectEqualStrings("SASL", std.mem.span(oldapStateName(.OLDAP_SASL)));
    try std.testing.expectEqualStrings("BIND", std.mem.span(oldapStateName(.OLDAP_BIND)));
    try std.testing.expectEqualStrings("BINDV2", std.mem.span(oldapStateName(.OLDAP_BINDV2)));
    try std.testing.expectEqualStrings("", std.mem.span(oldapStateName(.OLDAP_LAST)));

    try std.testing.expect(!oldapStrNeedsBase64(""));
    try std.testing.expect(!oldapStrNeedsBase64("cn=admin,dc=example,dc=com"));
    try std.testing.expect(oldapStrNeedsBase64(":leading-colon"));
    try std.testing.expect(oldapStrNeedsBase64("<leading-lt"));
    try std.testing.expect(oldapStrNeedsBase64(" leading-space"));
    try std.testing.expect(oldapStrNeedsBase64("trailing-space "));
    try std.testing.expect(oldapStrNeedsBase64("\tleading-tab"));
    try std.testing.expect(oldapStrNeedsBase64("has\nnewline"));
    try std.testing.expect(oldapStrNeedsBase64("non-ascii-\x80"));
}

test "LDAP error mapping and low-level URL parser" {
    try std.testing.expectEqual(CURLE_OUT_OF_MEMORY, oldapMapError(LDAP_NO_MEMORY, CURLE_COULDNT_CONNECT));
    try std.testing.expectEqual(CURLE_LOGIN_DENIED, oldapMapError(LDAP_INVALID_CREDENTIALS, CURLE_COULDNT_CONNECT));
    try std.testing.expectEqual(CURLE_UNSUPPORTED_PROTOCOL, oldapMapError(LDAP_PROTOCOL_ERROR, CURLE_COULDNT_CONNECT));
    try std.testing.expectEqual(CURLE_REMOTE_ACCESS_DENIED, oldapMapError(LDAP_INSUFFICIENT_ACCESS, CURLE_COULDNT_CONNECT));
    try std.testing.expectEqual(CURLE_COULDNT_CONNECT, oldapMapError(LDAP_OTHER, CURLE_COULDNT_CONNECT));

    try std.testing.expectEqual(LDAP_SCOPE_BASE, str2scope("base"));
    try std.testing.expectEqual(LDAP_SCOPE_ONELEVEL, str2scope("one"));
    try std.testing.expectEqual(LDAP_SCOPE_ONELEVEL, str2scope("onetree"));
    try std.testing.expectEqual(LDAP_SCOPE_SUBTREE, str2scope("sub"));
    try std.testing.expectEqual(LDAP_SCOPE_SUBTREE, str2scope("subtree"));
    try std.testing.expectEqual(@as(c_int, -1), str2scope("invalid"));

    const desc_raw = alloc.Curl_calloc(1, @sizeOf(LdapUrlDescLow)) orelse unreachable;
    const desc: *LdapUrlDescLow = @ptrCast(@alignCast(desc_raw));
    desc.* = .{};
    defer ldapFreeUrldescLow(desc);

    const rc = ldapUrlParse2Low(
        "/dc=example,dc=com",
        "cn,mail?sub?(objectClass=person)",
        "ldap",
        "localhost",
        389,
        desc,
    );
    try std.testing.expectEqual(LDAP_SUCCESS, rc);
    try std.testing.expectEqualStrings("dc=example,dc=com", std.mem.span(desc.lud_dn.?));
    try std.testing.expectEqual(LDAP_SCOPE_SUBTREE, desc.lud_scope);
    try std.testing.expectEqualStrings("(objectClass=person)", std.mem.span(desc.lud_filter.?));
    try std.testing.expectEqual(@as(usize, 2), desc.lud_attrs_dups);
    try std.testing.expectEqualStrings("cn", std.mem.span(desc.lud_attrs.?[0].?));
    try std.testing.expectEqualStrings("mail", std.mem.span(desc.lud_attrs.?[1].?));
    try std.testing.expect(desc.lud_attrs.?[2] == null);

    var vbuf: [64]u8 = undefined;
    Curl_ldap_version(&vbuf, vbuf.len);
    const vstr = std.mem.sliceTo(&vbuf, 0);
    try std.testing.expect(vstr.len > 0);
}

test "ldapUrlParse2Low errdefer cleanup on scope, filter, attribute, and extension failures" {
    const desc_raw = alloc.Curl_calloc(1, @sizeOf(LdapUrlDescLow)) orelse unreachable;
    const desc: *LdapUrlDescLow = @ptrCast(@alignCast(desc_raw));
    desc.* = .{};
    defer ldapFreeUrldescLow(desc);

    // 1. Invalid scope after lud_dn and lud_attrs are allocated
    const rc_scope = ldapUrlParse2Low(
        "/dc=example,dc=com",
        "cn,mail?badscope?(objectClass=person)",
        "ldap",
        "localhost",
        389,
        desc,
    );
    try std.testing.expectEqual(LDAP_INVALID_SYNTAX, rc_scope);
    try std.testing.expect(desc.lud_dn == null);
    try std.testing.expect(desc.lud_attrs == null);
    try std.testing.expectEqual(@as(usize, 0), desc.lud_attrs_dups);
    try std.testing.expect(desc.lud_filter == null);

    // 2. Invalid filter (%01 rejected by REJECT_CTRL) after lud_dn and lud_attrs are allocated
    const rc_filter = ldapUrlParse2Low(
        "/dc=example,dc=com",
        "cn,mail?sub?(cn=%01)",
        "ldap",
        "localhost",
        389,
        desc,
    );
    try std.testing.expectEqual(LDAP_NO_MEMORY, rc_filter);
    try std.testing.expect(desc.lud_dn == null);
    try std.testing.expect(desc.lud_attrs == null);
    try std.testing.expectEqual(@as(usize, 0), desc.lud_attrs_dups);
    try std.testing.expect(desc.lud_filter == null);

    // 3. Second attribute fails Curl_urldecode (%00 rejected by REJECT_ZERO) after first attribute is allocated
    const rc_attr = ldapUrlParse2Low(
        "/dc=example,dc=com",
        "cn,bad%00attr?sub?(objectClass=*)",
        "ldap",
        "localhost",
        389,
        desc,
    );
    try std.testing.expectEqual(LDAP_NO_MEMORY, rc_attr);
    try std.testing.expect(desc.lud_dn == null);
    try std.testing.expect(desc.lud_attrs == null);
    try std.testing.expectEqual(@as(usize, 0), desc.lud_attrs_dups);
    try std.testing.expect(desc.lud_filter == null);

    // 4. Trailing empty extension ('?') after lud_dn, lud_attrs, and lud_filter are allocated
    const rc_ext = ldapUrlParse2Low(
        "/dc=example,dc=com",
        "cn,mail?sub?(objectClass=person)?",
        "ldap",
        "localhost",
        389,
        desc,
    );
    try std.testing.expectEqual(LDAP_INVALID_SYNTAX, rc_ext);
    try std.testing.expect(desc.lud_dn == null);
    try std.testing.expect(desc.lud_attrs == null);
    try std.testing.expectEqual(@as(usize, 0), desc.lud_attrs_dups);
    try std.testing.expect(desc.lud_filter == null);
}

test "ldapconninfo and ldapreqinfo poisoning and ldapsb_tls invalid-magic rejection" {
    const cb = struct {
        extern var Curl_cfree: mem.FreeCallback;
    };
    const expected_poison: u8 = switch (builtin.mode) {
        .Debug, .ReleaseSafe => 0xaa,
        .ReleaseFast, .ReleaseSmall => 0x00,
    };
    var poisoned_frees: usize = 0;
    const TestHooks = struct {
        var count: *usize = undefined;
        var expected: u8 = 0xaa;
        var orig_free: mem.FreeCallback = undefined;
        fn freeFn(p: ?*anyopaque) callconv(.c) void {
            if (p) |non_null| {
                const bytes: [*]const u8 = @ptrCast(non_null);
                if (bytes[0] == expected and bytes[1] == expected) {
                    count.* += 1;
                }
            }
            orig_free(p);
        }
    };
    TestHooks.count = &poisoned_frees;
    TestHooks.expected = expected_poison;
    TestHooks.orig_free = cb.Curl_cfree;
    cb.Curl_cfree = &TestHooks.freeFn;
    defer cb.Curl_cfree = TestHooks.orig_free;

    const li_raw = alloc.Curl_calloc(1, @sizeOf(ldapconninfo)) orelse unreachable;
    const li: *ldapconninfo = @ptrCast(@alignCast(li_raw));
    li.* = .{};
    oldapConnDtor(null, 0, li);
    try std.testing.expectEqual(@as(usize, 1), poisoned_frees);

    const lr_raw = alloc.Curl_calloc(1, @sizeOf(ldapreqinfo)) orelse unreachable;
    const lr: *ldapreqinfo = @ptrCast(@alignCast(lr_raw));
    lr.* = .{ .msgid = 42, .num_entries = 3 };
    oldapReqDtor(null, 0, lr);
    try std.testing.expectEqual(@as(usize, 2), poisoned_frees);

    // Validate ldapsb_tls magic guard rejects null or corrupted magic numbers
    var fake_easy_bad: u32 align(8) = 0xdeadbeef;
    var fake_easy_good: u32 align(8) = CURLEASY_MAGIC_NUMBER;
    var sbiod = Sockbuf_IO_Desc{
        .sbiod_level = LBER_SBIOD_LEVEL_TRANSPORT,
        .sbiod_sb = null,
        .sbiod_io = &ldapsb_tls,
        .sbiod_pvt = null,
        .sbiod_next = null,
    };

    try std.testing.expect(ldapsbValidEasy(null) == null);
    try std.testing.expect(ldapsbValidEasy(@ptrCast(&fake_easy_bad)) == null);
    try std.testing.expect(ldapsbValidEasy(@ptrCast(&fake_easy_good)) != null);

    try std.testing.expectEqual(@as(c_int, -1), ldapsbTlsSetup(&sbiod, null));
    try std.testing.expectEqual(@as(c_int, -1), ldapsbTlsSetup(&sbiod, @ptrCast(&fake_easy_bad)));
    try std.testing.expect(sbiod.sbiod_pvt == null);

    try std.testing.expectEqual(@as(c_int, 0), ldapsbTlsSetup(&sbiod, @ptrCast(&fake_easy_good)));
    try std.testing.expect(sbiod.sbiod_pvt != null);

    // Corrupt magic in-place (simulating use-after-free / 0xaaaaaaaa poison)
    fake_easy_good = 0xaaaaaaaa;
    var dummy_buf: [8]u8 = undefined;
    try std.testing.expectEqual(@as(ber_slen_t, -1), oldapSbRead(&sbiod, &dummy_buf, dummy_buf.len));
    try std.testing.expectEqual(@as(ber_slen_t, -1), oldapSbWrite(&sbiod, &dummy_buf, dummy_buf.len));
    try std.testing.expectEqual(@as(c_int, -1), ldapsbTlsCtrl(&sbiod, LBER_SB_OPT_DATA_READY, null));
    try std.testing.expectEqual(@as(c_int, -1), ldapsbTlsClose(&sbiod));
}
