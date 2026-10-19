// Ported from:
//   src/tool_listhelp.c
//   src/tool_setopt.c
//   src/tool_getparam.c

const std = @import("std");
const builtin = @import("builtin");

const c = struct {
    extern fn malloc(size: usize) ?*anyopaque;
    extern fn free(ptr: ?*anyopaque) void;
    extern fn fopen(filename: [*:0]const u8, mode: [*:0]const u8) ?*anyopaque;
    extern fn fclose(stream: ?*anyopaque) c_int;
};

const win32 = if (builtin.os.tag == .windows) struct {
    extern fn curlx_win32_fopen(filename: ?[*:0]const u8, mode: ?[*:0]const u8) callconv(.c) ?*anyopaque;
} else struct {};

inline fn toolFopen(filename: [*:0]const u8, mode: [*:0]const u8) ?*anyopaque {
    if (builtin.os.tag == .windows) {
        return win32.curlx_win32_fopen(filename, mode);
    }
    return c.fopen(filename, mode);
}

inline fn toolFclose(stream: ?*anyopaque) void {
    _ = c.fclose(stream);
}

fn cDup0(src: ?[*]const u8, length: usize) ?[*:0]u8 {
    if (length >= std.math.maxInt(usize)) return null;
    const raw = c.malloc(length + 1) orelse return null;
    const buf: [*]u8 = @ptrCast(raw);
    if (length > 0) {
        if (src) |s| {
            @memcpy(buf[0..length], s[0..length]);
        }
    }
    buf[length] = 0;
    return @ptrCast(buf);
}

fn cStrdup(s: [*:0]const u8) ?[*:0]u8 {
    return cDup0(s, std.mem.len(s));
}

// ============================================================================
// Common Types & Constants
// ============================================================================

pub const CURL = opaque {};
pub const OperationConfig = opaque {};
pub const getout = opaque {};
pub const curl_mime = opaque {};

pub const CURLcode = c_uint;
pub const CURLE_OK: CURLcode = 0;
pub const CURLE_OUT_OF_MEMORY: CURLcode = 27;

pub const CURLoption = c_uint;
pub const CURLOPTTYPE_FUNCTIONPOINT: CURLoption = 20000;
pub const CURLOPT_POSTFIELDS: CURLoption = 10015;

pub const curl_off_t = i64;
pub const CURL_OFF_T_MAX: curl_off_t = std.math.maxInt(curl_off_t);
pub const CURL_ZERO_TERMINATED: usize = std.math.maxInt(usize);

pub const ParameterError = c_uint;
pub const PARAM_OK: ParameterError = 0;
pub const PARAM_OPTION_UNKNOWN: ParameterError = 1;
pub const PARAM_CONFIG_OPTION_UNKNOWN: ParameterError = 2;
pub const PARAM_REQUIRES_PARAMETER: ParameterError = 3;
pub const PARAM_BAD_USE: ParameterError = 4;
pub const PARAM_HELP_REQUESTED: ParameterError = 5;
pub const PARAM_MANUAL_REQUESTED: ParameterError = 6;
pub const PARAM_VERSION_INFO_REQUESTED: ParameterError = 7;
pub const PARAM_ENGINES_REQUESTED: ParameterError = 8;
pub const PARAM_CA_EMBED_REQUESTED: ParameterError = 9;
pub const PARAM_GOT_EXTRA_PARAMETER: ParameterError = 10;
pub const PARAM_BAD_NUMERIC: ParameterError = 11;
pub const PARAM_NEGATIVE_NUMERIC: ParameterError = 12;
pub const PARAM_LIBCURL_DOESNT_SUPPORT: ParameterError = 13;
pub const PARAM_LIBCURL_UNSUPPORTED_PROTOCOL: ParameterError = 14;
pub const PARAM_NO_MEM: ParameterError = 15;
pub const PARAM_NEXT_OPERATION: ParameterError = 16;
pub const PARAM_NO_PREFIX: ParameterError = 17;
pub const PARAM_NUMBER_TOO_LARGE: ParameterError = 18;
pub const PARAM_CONTDISP_RESUME_FROM: ParameterError = 19;
pub const PARAM_READ_ERROR: ParameterError = 20;
pub const PARAM_EXPAND_ERROR: ParameterError = 21;
pub const PARAM_BLANK_STRING: ParameterError = 22;
pub const PARAM_VAR_SYNTAX: ParameterError = 23;
pub const PARAM_RECURSION: ParameterError = 24;
pub const PARAM_LAST: ParameterError = 25;

pub const HttpReq = c_uint;
pub const TOOL_HTTPREQ_UNSPEC: HttpReq = 0;
pub const TOOL_HTTPREQ_GET: HttpReq = 1;
pub const TOOL_HTTPREQ_HEAD: HttpReq = 2;
pub const TOOL_HTTPREQ_MIMEPOST: HttpReq = 3;
pub const TOOL_HTTPREQ_SIMPLEPOST: HttpReq = 4;
pub const TOOL_HTTPREQ_PUT: HttpReq = 5;

pub const TRACE_NONE: curl_off_t = 0;
pub const TRACE_BIN: curl_off_t = 1;
pub const TRACE_ASCII: curl_off_t = 2;
pub const TRACE_PLAIN: curl_off_t = 3;

pub const FAIL_NONE: curl_off_t = 0;
pub const FAIL_WO_BODY: curl_off_t = 1;
pub const FAIL_WITH_BODY: curl_off_t = 2;

pub const CLOBBER_DEFAULT: curl_off_t = 0;
pub const CLOBBER_NEVER: curl_off_t = 1;
pub const CLOBBER_ALWAYS: curl_off_t = 2;

pub const CURL_PROGRESS_STATS: curl_off_t = 0;
pub const CURL_PROGRESS_BAR: curl_off_t = 1;

pub const MAX_PARALLEL: c_long = 65535;
pub const PARALLEL_DEFAULT: curl_off_t = 50;
pub const MAX_PARALLEL_HOST: c_long = 65535;
pub const PARALLEL_HOST_DEFAULT: curl_off_t = 0;
pub const CONFIG_MAX_LEVELS: c_int = 10;

pub const ALLOW_BLANK: bool = true;
pub const DENY_BLANK: bool = false;

pub const STRE_OVERFLOW: c_int = 7;

pub const FOPEN_READTEXT: [*:0]const u8 = if (builtin.os.tag == .windows) "rt" else "r";

pub const curl_slist = extern struct {
    data: ?[*:0]u8,
    next: ?*curl_slist,
};

pub const slist_wc = extern struct {
    first: ?*curl_slist,
    last: ?*curl_slist,
};

pub const Dynbuf = extern struct {
    bufr: ?[*]u8 = null,
    leng: usize = 0,
    allc: usize = 0,
    toobig: usize = 0,
};

pub const Curl_str = extern struct {
    str: ?[*]const u8 = null,
    len: usize = 0,
};

pub const tool_mime_kind = c_uint;
pub const TOOLMIME_NONE: tool_mime_kind = 0;
pub const TOOLMIME_PARTS: tool_mime_kind = 1;
pub const TOOLMIME_DATA: tool_mime_kind = 2;
pub const TOOLMIME_FILE: tool_mime_kind = 3;
pub const TOOLMIME_FILEDATA: tool_mime_kind = 4;
pub const TOOLMIME_STDIN: tool_mime_kind = 5;
pub const TOOLMIME_STDINDATA: tool_mime_kind = 6;

pub const tool_mime = extern struct {
    kind: tool_mime_kind,
    parent: ?*tool_mime,
    prev: ?*tool_mime,
    data: ?[*:0]const u8,
    name: ?[*:0]const u8,
    filename: ?[*:0]const u8,
    type: ?[*:0]const u8,
    encoder: ?[*:0]const u8,
    headers: ?*curl_slist,
    subparts: ?*tool_mime,
    origin: curl_off_t,
    size: curl_off_t,
    curpos: curl_off_t,
    config: ?*OperationConfig,
};

// libcurl constants
pub const CURLPROXY_HTTP: c_long = 0;
pub const CURLPROXY_HTTP_1_0: c_long = 1;
pub const CURLPROXY_HTTPS: c_long = 2;
pub const CURLPROXY_HTTPS2: c_long = 3;
pub const CURLPROXY_SOCKS4: c_long = 4;
pub const CURLPROXY_SOCKS5: c_long = 5;
pub const CURLPROXY_SOCKS4A: c_long = 6;
pub const CURLPROXY_SOCKS5_HOSTNAME: c_long = 7;
pub const CURLPROXY_HTTPS3: c_long = 8;

pub const CURL_HTTP_VERSION_NONE: c_long = 0;
pub const CURL_HTTP_VERSION_1_0: c_long = 1;
pub const CURL_HTTP_VERSION_1_1: c_long = 2;
pub const CURL_HTTP_VERSION_2_0: c_long = 3;
pub const CURL_HTTP_VERSION_2TLS: c_long = 4;
pub const CURL_HTTP_VERSION_2_PRIOR_KNOWLEDGE: c_long = 5;
pub const CURL_HTTP_VERSION_3: c_long = 30;
pub const CURL_HTTP_VERSION_3ONLY: c_long = 31;

pub const CURL_SSLVERSION_DEFAULT: c_long = 0;
pub const CURL_SSLVERSION_TLSv1: c_long = 1;
pub const CURL_SSLVERSION_SSLv2: c_long = 2;
pub const CURL_SSLVERSION_SSLv3: c_long = 3;
pub const CURL_SSLVERSION_TLSv1_0: c_long = 4;
pub const CURL_SSLVERSION_TLSv1_1: c_long = 5;
pub const CURL_SSLVERSION_TLSv1_2: c_long = 6;
pub const CURL_SSLVERSION_TLSv1_3: c_long = 7;

pub const CURL_SSLVERSION_MAX_NONE: c_long = 0;
pub const CURL_SSLVERSION_MAX_DEFAULT: c_long = (CURL_SSLVERSION_TLSv1 << 16);
pub const CURL_SSLVERSION_MAX_TLSv1_0: c_long = (CURL_SSLVERSION_TLSv1_0 << 16);
pub const CURL_SSLVERSION_MAX_TLSv1_1: c_long = (CURL_SSLVERSION_MAX_TLSv1_0 + (1 << 16));
pub const CURL_SSLVERSION_MAX_TLSv1_2: c_long = (CURL_SSLVERSION_TLSv1_2 << 16);
pub const CURL_SSLVERSION_MAX_TLSv1_3: c_long = (CURL_SSLVERSION_TLSv1_3 << 16);

pub const CURL_TIMECOND_NONE: c_long = 0;
pub const CURL_TIMECOND_IFMODSINCE: c_long = 1;
pub const CURL_TIMECOND_IFUNMODSINCE: c_long = 2;
pub const CURL_TIMECOND_LASTMOD: c_long = 3;

pub const CURLFTPSSL_CCC_NONE: c_long = 0;
pub const CURLFTPSSL_CCC_PASSIVE: c_long = 1;
pub const CURLFTPSSL_CCC_ACTIVE: c_long = 2;

pub const CURLUSESSL_NONE: c_long = 0;
pub const CURLUSESSL_TRY: c_long = 1;
pub const CURLUSESSL_CONTROL: c_long = 2;
pub const CURLUSESSL_ALL: c_long = 3;

pub const CURL_NETRC_IGNORED: c_long = 0;
pub const CURL_NETRC_OPTIONAL: c_long = 1;
pub const CURL_NETRC_REQUIRED: c_long = 2;

pub const CURLFTPMETHOD_DEFAULT: c_long = 0;
pub const CURLFTPMETHOD_MULTICWD: c_long = 1;
pub const CURLFTPMETHOD_NOCWD: c_long = 2;
pub const CURLFTPMETHOD_SINGLECWD: c_long = 3;

pub const CURLFTP_CREATE_DIR_NONE: c_long = 0;
pub const CURLFTP_CREATE_DIR: c_long = 1;
pub const CURLFTP_CREATE_DIR_RETRY: c_long = 2;

pub const CURLHEADER_UNIFIED: c_long = 0;
pub const CURLHEADER_SEPARATE: c_long = (1 << 0);

pub const CURLMIMEOPT_FORMESCAPE: c_ulong = (1 << 0);

pub const CURLAUTH_NONE: c_ulong = 0;
pub const CURLAUTH_BASIC: c_ulong = (1 << 0);
pub const CURLAUTH_DIGEST: c_ulong = (1 << 1);
pub const CURLAUTH_NEGOTIATE: c_ulong = (1 << 2);
pub const CURLAUTH_GSSNEGOTIATE: c_ulong = CURLAUTH_NEGOTIATE;
pub const CURLAUTH_GSSAPI: c_ulong = CURLAUTH_NEGOTIATE;
pub const CURLAUTH_NTLM: c_ulong = (1 << 3);
pub const CURLAUTH_DIGEST_IE: c_ulong = (1 << 4);
pub const CURLAUTH_ONLY: c_ulong = (@as(c_ulong, 1) << 31);
pub const CURLAUTH_BEARER: c_ulong = (1 << 6);
pub const CURLAUTH_AWS_SIGV4: c_ulong = (1 << 7);
pub const CURLAUTH_HTTPSIG: c_ulong = (1 << 8);
pub const CURLAUTH_ANY: c_ulong = (~(CURLAUTH_DIGEST_IE | CURLAUTH_HTTPSIG)) & 0xffffffff;
pub const CURLAUTH_ANYSAFE: c_ulong = (~(CURLAUTH_BASIC | CURLAUTH_DIGEST_IE | CURLAUTH_HTTPSIG)) & 0xffffffff;

pub const CURLHSTS_ENABLE: c_ulong = (1 << 0);
pub const CURLHSTS_READONLYFILE: c_ulong = (1 << 1);

pub const CURLSSLOPT_ALLOW_BEAST: c_ulong = (1 << 0);
pub const CURLSSLOPT_NO_REVOKE: c_ulong = (1 << 1);
pub const CURLSSLOPT_NO_PARTIALCHAIN: c_ulong = (1 << 2);
pub const CURLSSLOPT_REVOKE_BEST_EFFORT: c_ulong = (1 << 3);
pub const CURLSSLOPT_NATIVE_CA: c_ulong = (1 << 4);
pub const CURLSSLOPT_AUTO_CLIENT_CERT: c_ulong = (1 << 5);
pub const CURLSSLOPT_EARLYDATA: c_ulong = (1 << 6);

pub const CURLULFLAG_ANSWERED: u8 = (1 << 0);
pub const CURLULFLAG_DELETED: u8 = (1 << 1);
pub const CURLULFLAG_DRAFT: u8 = (1 << 2);
pub const CURLULFLAG_FLAGGED: u8 = (1 << 3);
pub const CURLULFLAG_SEEN: u8 = (1 << 4);

pub const CURL_IPRESOLVE_WHATEVER: c_long = 0;
pub const CURL_IPRESOLVE_V4: c_long = 1;
pub const CURL_IPRESOLVE_V6: c_long = 2;

pub const CURLFOLLOW_ALL: c_long = 1;
pub const CURLFOLLOW_OBEYCODE: c_long = 2;
pub const CURLFOLLOW_FIRSTONLY: c_long = 3;

// External functions from libcurl / curlx / tool_*
extern fn curl_easy_setopt(curl: ?*CURL, tag: CURLoption, ...) callconv(.c) CURLcode;
extern fn curl_easy_escape(handle: ?*CURL, string: [*]const u8, length: c_int) callconv(.c) ?[*:0]u8;
extern fn curl_free(p: ?*anyopaque) callconv(.c) void;
extern fn curl_getdate(p: [*:0]const u8, unused: ?*const anyopaque) callconv(.c) isize;
extern fn curl_global_trace(config: [*:0]const u8) callconv(.c) CURLcode;
extern fn curl_maprintf(format: [*:0]const u8, ...) callconv(.c) ?[*:0]u8;
extern fn curl_msnprintf(buffer: [*]u8, maxlength: usize, format: [*:0]const u8, ...) callconv(.c) c_int;
extern fn curl_strnequal(s1: [*:0]const u8, s2: [*:0]const u8, max: usize) callconv(.c) c_int;

extern fn curlx_dyn_init(s: *Dynbuf, toobig: usize) callconv(.c) void;
extern fn curlx_dyn_free(s: *Dynbuf) callconv(.c) void;
extern fn curlx_dyn_addn(s: *Dynbuf, mem_ptr: ?*const anyopaque, len: usize) callconv(.c) CURLcode;
extern fn curlx_dyn_add(s: *Dynbuf, str: [*:0]const u8) callconv(.c) CURLcode;
extern fn curlx_dyn_addf(s: *Dynbuf, fmt: [*:0]const u8, ...) callconv(.c) CURLcode;
extern fn curlx_dyn_ptr(s: *const Dynbuf) callconv(.c) ?[*:0]u8;
extern fn curlx_dyn_len(s: *const Dynbuf) callconv(.c) usize;

extern fn curlx_str_until(linep: *[*:0]const u8, out: *Curl_str, max: usize, delim: u8) callconv(.c) c_int;
extern fn curlx_str_number(linep: *[*:0]const u8, nump: *curl_off_t, max: curl_off_t) callconv(.c) c_int;
extern fn curlx_str_single(linep: *[*:0]const u8, byte: u8) callconv(.c) c_int;

extern fn warnf(fmt: [*:0]const u8, ...) callconv(.c) void;
extern fn errorf(fmt: [*:0]const u8, ...) callconv(.c) void;
extern fn helpf(fmt: [*:0]const u8, ...) callconv(.c) void;

extern var easysrc_decl: ?*slist_wc;
extern var easysrc_data: ?*slist_wc;
extern var easysrc_code: ?*slist_wc;
extern var easysrc_toohard: ?*slist_wc;
extern var easysrc_clean: ?*slist_wc;
extern var easysrc_mime_count: c_int;
extern var easysrc_slist_count: c_int;

extern fn easysrc_add(pp: *?*slist_wc, line: [*:0]const u8) callconv(.c) CURLcode;
extern fn easysrc_addf(pp: *?*slist_wc, fmt: [*:0]const u8, ...) callconv(.c) CURLcode;
extern fn easysrc_is_first() callconv(.c) bool;

extern var built_in_protos: [*:null]const ?[*:0]const u8;
extern var feature_altsvc: bool;
extern var feature_brotli: bool;
extern var feature_ech: bool;
extern var feature_hsts: bool;
extern var feature_http2: bool;
extern var feature_http3: bool;
extern var feature_httpsproxy: bool;
extern var feature_httpsig: bool;
extern var feature_libz: bool;
extern var feature_ntlm: bool;
extern var feature_spnego: bool;
extern var feature_ssl: bool;
extern var feature_ssls_export: bool;
extern var feature_zstd: bool;

extern fn check_protocol(str: ?[*:0]const u8) callconv(.c) ParameterError;
extern fn str2offset(valp: *curl_off_t, str: [*:0]const u8) callconv(.c) ParameterError;
extern fn str2num(valp: *c_long, str: [*:0]const u8) callconv(.c) ParameterError;
extern fn str2unum(valp: *c_long, str: [*:0]const u8) callconv(.c) ParameterError;
extern fn oct2nummax(valp: *c_long, str: [*:0]const u8, max: c_long) callconv(.c) ParameterError;
extern fn str2unummax(valp: *c_long, str: [*:0]const u8, max: c_long) callconv(.c) ParameterError;
extern fn secs2ms(valp: *c_long, str: [*:0]const u8) callconv(.c) ParameterError;
extern fn proto2num(set: [*:null]const ?[*:0]const u8, val: *?[*:0]u8, str: [*:0]const u8) callconv(.c) ParameterError;
extern fn add2list(list: *?*curl_slist, ptr: [*:0]const u8) callconv(.c) ParameterError;
extern fn ftpfilemethod(str: [*:0]const u8) callconv(.c) c_int;
extern fn ftpcccmethod(str: [*:0]const u8) callconv(.c) c_int;
extern fn delegation(str: [*:0]const u8) callconv(.c) c_long;
extern fn str2tls_max(valp: *u8, str: [*:0]const u8) callconv(.c) ParameterError;
extern fn file2string(bufp: *?[*:0]u8, file: ?*anyopaque) callconv(.c) ParameterError;
extern fn file2memory(bufp: *?[*:0]u8, size: *usize, file: ?*anyopaque) callconv(.c) ParameterError;
extern fn getfiletime(filename: [*:0]const u8, stamp: *curl_off_t) callconv(.c) c_int;
extern fn SetHTTPrequest(req: HttpReq, store: *HttpReq) callconv(.c) c_int;
extern fn new_getout(config: *OperationConfig) callconv(.c) ?*getout;
extern fn param2text(err: ParameterError) callconv(.c) [*:0]const u8;
extern fn my_get_line(input: ?*anyopaque, buf: *Dynbuf, error_out: *bool) callconv(.c) bool;
extern fn parseconfig(filename: ?[*:0]const u8, max_recursive: c_int, global_arg: ?*anyopaque) callconv(.c) ParameterError;
extern fn formparse(input: [*:0]const u8, mimeroot: *?*tool_mime, mimecurrent: *?*tool_mime, literal_value: bool) callconv(.c) c_int;
extern fn tool_help(category: ?[*:0]const u8) callconv(.c) void;
extern fn tool_set_stderr_file(filename: ?[*:0]const u8) callconv(.c) void;
extern fn setvariable(input: [*:0]const u8) callconv(.c) ParameterError;
extern fn varexpand(line: [*:0]const u8, out: *Dynbuf, replaced: *bool) callconv(.c) ParameterError;

// Accessors in src/tool_main.c
extern fn tool_zig_stdin() callconv(.c) ?*anyopaque;
extern fn tool_zig_stdin_binmode() callconv(.c) void;
extern fn tool_zig_has_ares() callconv(.c) bool;
extern fn tool_zig_existingfile(filename: [*:0]const u8) callconv(.c) bool;
extern fn tool_zig_get_global_last() callconv(.c) ?*OperationConfig;
extern fn tool_zig_global_first() callconv(.c) ?*OperationConfig;
extern fn tool_zig_config_alloc_next(config: *OperationConfig) callconv(.c) ?*OperationConfig;
extern fn tool_zig_config_str_ptr(config: *OperationConfig, id: c_int) callconv(.c) *?[*:0]u8;
extern fn tool_zig_config_slist_ptr(config: *OperationConfig, id: c_int) callconv(.c) *?*curl_slist;
extern fn tool_zig_config_get_bit(config: *const OperationConfig, id: c_int) callconv(.c) bool;
extern fn tool_zig_config_set_bit(config: *OperationConfig, id: c_int, val: bool) callconv(.c) void;
extern fn tool_zig_config_get_int(config: *const OperationConfig, id: c_int) callconv(.c) curl_off_t;
extern fn tool_zig_config_set_int(config: *OperationConfig, id: c_int, val: curl_off_t) callconv(.c) void;
extern fn tool_zig_config_getout_ptr(config: *OperationConfig, id: c_int) callconv(.c) *?*getout;
extern fn tool_zig_config_mimeroot_ptr(config: *OperationConfig) callconv(.c) *?*tool_mime;
extern fn tool_zig_config_mimecurrent_ptr(config: *OperationConfig) callconv(.c) *?*tool_mime;
extern fn tool_zig_config_postdata_ptr(config: *OperationConfig) callconv(.c) *Dynbuf;
extern fn tool_zig_global_str_ptr(id: c_int) callconv(.c) *?[*:0]u8;
extern fn tool_zig_global_get_bit(id: c_int) callconv(.c) bool;
extern fn tool_zig_global_set_bit(id: c_int, val: bool) callconv(.c) void;
extern fn tool_zig_global_get_int(id: c_int) callconv(.c) curl_off_t;
extern fn tool_zig_global_set_int(id: c_int, val: curl_off_t) callconv(.c) void;
extern fn tool_zig_getout_str_ptr(node: *getout, id: c_int) callconv(.c) *?[*:0]u8;
extern fn tool_zig_getout_get_bit(node: *const getout, id: c_int) callconv(.c) bool;
extern fn tool_zig_getout_set_bit(node: *getout, id: c_int, val: bool) callconv(.c) void;
extern fn tool_zig_getout_next(node: *const getout) callconv(.c) ?*getout;

const CfgStr = enum(c_int) {
    altsvc = 0,
    aws_sigv4 = 1,
    cacert = 2,
    capath = 3,
    cert = 4,
    cert_type = 5,
    cipher13_list = 6,
    cipher_list = 7,
    cookiejar = 8,
    crlfile = 9,
    customrequest = 10,
    dns_interface = 11,
    dns_ipv4_addr = 12,
    dns_ipv6_addr = 13,
    dns_servers = 14,
    doh_url = 15,
    ech = 16,
    ech_config = 17,
    ech_public = 18,
    engine = 19,
    etag_compare_file = 20,
    etag_save_file = 21,
    ftp_account = 22,
    ftp_alternative_to_user = 23,
    ftpport = 24,
    haproxy_clientip = 25,
    headerfile = 26,
    hostpubmd5 = 27,
    hostpubsha256 = 28,
    hsts = 29,
    httpsig_algorithm = 30,
    httpsig_headers = 31,
    httpsig_key = 32,
    httpsig_keyid = 33,
    iface = 34,
    ipfs_gateway = 35,
    key = 36,
    key_passwd = 37,
    key_type = 38,
    knownhosts = 39,
    login_options = 40,
    mail_auth = 41,
    mail_from = 42,
    netrc_file = 43,
    noproxy = 44,
    oauth_bearer = 45,
    output_dir = 46,
    pinnedpubkey = 47,
    postfields = 48,
    preproxy = 49,
    proto_default = 50,
    proto_redir_str = 51,
    proto_str = 52,
    proxy = 53,
    proxy_cacert = 54,
    proxy_capath = 55,
    proxy_cert = 56,
    proxy_cert_type = 57,
    proxy_cipher13_list = 58,
    proxy_cipher_list = 59,
    proxy_crlfile = 60,
    proxy_key = 61,
    proxy_key_passwd = 62,
    proxy_key_type = 63,
    proxy_pinnedpubkey = 64,
    proxy_service_name = 65,
    proxyuserpwd = 66,
    pubkey = 67,
    query = 68,
    range = 69,
    referer = 70,
    request_target = 71,
    sasl_authzid = 72,
    service_name = 73,
    ssl_ec_curves = 74,
    ssl_signature_algorithms = 75,
    unix_socket_path = 76,
    useragent = 77,
    userpwd = 78,
    writeout = 79,
};

const CfgSlist = enum(c_int) {
    connect_to = 0,
    cookiefiles = 1,
    cookies = 2,
    headers = 3,
    mail_rcpt = 4,
    postquote = 5,
    prequote = 6,
    proxyheaders = 7,
    quote = 8,
    resolve = 9,
    telnet_options = 10,
};

const CfgBit = enum(c_int) {
    abstract_unix_socket = 0,
    autoreferer = 1,
    content_disposition = 2,
    cookiesession = 3,
    create_dirs = 4,
    crlf = 5,
    dirlistonly = 6,
    disable_eprt = 7,
    disable_epsv = 8,
    disable_sessionid = 9,
    disallow_username_in_url = 10,
    doh_insecure_ok = 11,
    doh_verifystatus = 12,
    encoding = 13,
    ftp_append = 14,
    ftp_create_dirs = 15,
    ftp_pret = 16,
    ftp_skip_ip = 17,
    ftp_ssl = 18,
    ftp_ssl_ccc = 19,
    ftp_ssl_control = 20,
    ftp_ssl_reqd = 21,
    globoff = 22,
    haproxy_protocol = 23,
    http09_allowed = 24,
    ignorecl = 25,
    insecure_ok = 26,
    jsoned = 27,
    mail_rcpt_allowfails = 28,
    mptcp = 29,
    native_ca_store = 30,
    netrc = 31,
    netrc_opt = 32,
    no_body = 33,
    noalpn = 34,
    nobuffer = 35,
    nokeepalive = 36,
    path_as_is = 37,
    post301 = 38,
    post302 = 39,
    post303 = 40,
    proto_present = 41,
    proto_redir_present = 42,
    proxy_insecure_ok = 43,
    proxy_native_ca_store = 44,
    proxy_ssl_allow_beast = 45,
    proxy_ssl_auto_client_cert = 46,
    proxyanyauth = 47,
    proxybasic = 48,
    proxydigest = 49,
    proxynegotiate = 50,
    proxyntlm = 51,
    proxytunnel = 52,
    raw = 53,
    remote_name_all = 54,
    remote_time = 55,
    resume_from_current = 56,
    retry_all_errors = 57,
    retry_connrefused = 58,
    rm_partial = 59,
    sasl_ir = 60,
    show_headers = 61,
    skip_existing = 62,
    socks5_gssapi_nec = 63,
    ssh_compression = 64,
    ssl_allow_beast = 65,
    ssl_allow_earlydata = 66,
    ssl_auto_client_cert = 67,
    ssl_no_revoke = 68,
    ssl_revoke_best_effort = 69,
    suppress_connect_headers = 70,
    tcp_fastopen = 71,
    tcp_nodelay = 72,
    tftp_no_options = 73,
    tr_encoding = 74,
    unrestricted_auth = 75,
    use_ascii = 76,
    use_httpget = 77,
    use_resume = 78,
    verifystatus = 79,
    xattr = 80,
};

const CfgInt = enum(c_int) {
    alivecnt = 0,
    alivetime = 1,
    authtype = 2,
    condtime = 3,
    connecttimeout_ms = 4,
    create_file_mode = 5,
    expect100timeout_ms = 6,
    fail = 7,
    file_clobber_mode = 8,
    followlocation = 9,
    ftp_filemethod = 10,
    ftp_ssl_ccc_mode = 11,
    gssapi_delegation = 12,
    happy_eyeballs_timeout_ms = 13,
    httpreq = 14,
    httpversion = 15,
    ip_tos = 16,
    ip_version = 17,
    localport = 18,
    localportrange = 19,
    low_speed_limit = 20,
    low_speed_time = 21,
    max_filesize = 22,
    maxredirs = 23,
    mime_options = 24,
    num_urls = 25,
    proxy_ssl_version = 26,
    proxyver = 27,
    recvpersecond = 28,
    req_retry = 29,
    resume_from = 30,
    retry_delay_ms = 31,
    retry_maxtime_ms = 32,
    sendpersecond = 33,
    socks5_auth = 34,
    ssl_version = 35,
    ssl_version_max = 36,
    tftp_blksize = 37,
    timecond = 38,
    timeout_ms = 39,
    upload_flags = 40,
    vlan_priority = 41,
};

const CfgGetout = enum(c_int) {
    url_get = 0,
    url_list = 1,
    url_out = 2,
    url_ul = 3,
};

const GlobStr = enum(c_int) {
    libcurl = 0,
    ssl_sessions = 1,
    trace_dump = 2,
};

const GlobBit = enum(c_int) {
    fail_early = 0,
    noprogress = 1,
    parallel = 2,
    parallel_connect = 3,
    showerror = 4,
    silent = 5,
    styled_output = 6,
    trace_set = 7,
    traceids = 8,
    tracetime = 9,
};

const GlobInt = enum(c_int) {
    ms_per_transfer = 0,
    parallel_host = 1,
    parallel_max = 2,
    progressmode = 3,
    tracetype = 4,
    verbosity = 5,
};

const GetoutStr = enum(c_int) {
    infile = 0,
    outfile = 1,
    url = 2,
};

const GetoutBit = enum(c_int) {
    noglob = 0,
    noupload = 1,
    out_null = 2,
    outset = 3,
    uploadset = 4,
    urlset = 5,
    useremote = 6,
};

inline fn cfgStrPtr(config: *OperationConfig, field: CfgStr) *?[*:0]u8 {
    return tool_zig_config_str_ptr(config, @backingInt(field));
}
inline fn cfgStrFree(config: *OperationConfig, field: CfgStr) void {
    const p = cfgStrPtr(config, field);
    c.free(p.*);
    p.* = null;
}
inline fn cfgSlistPtr(config: *OperationConfig, field: CfgSlist) *?*curl_slist {
    return tool_zig_config_slist_ptr(config, @backingInt(field));
}
inline fn cfgBit(config: *const OperationConfig, field: CfgBit) bool {
    return tool_zig_config_get_bit(config, @backingInt(field));
}
inline fn setCfgBit(config: *OperationConfig, field: CfgBit, val: bool) void {
    tool_zig_config_set_bit(config, @backingInt(field), val);
}
inline fn cfgInt(config: *const OperationConfig, field: CfgInt) curl_off_t {
    return tool_zig_config_get_int(config, @backingInt(field));
}
inline fn setCfgInt(config: *OperationConfig, field: CfgInt, val: anytype) void {
    tool_zig_config_set_int(config, @backingInt(field), @intCast(val));
}
inline fn cfgGetoutPtr(config: *OperationConfig, field: CfgGetout) *?*getout {
    return tool_zig_config_getout_ptr(config, @backingInt(field));
}
inline fn globStrPtr(field: GlobStr) *?[*:0]u8 {
    return tool_zig_global_str_ptr(@backingInt(field));
}
inline fn globBit(field: GlobBit) bool {
    return tool_zig_global_get_bit(@backingInt(field));
}
inline fn setGlobBit(field: GlobBit, val: bool) void {
    tool_zig_global_set_bit(@backingInt(field), val);
}
inline fn globInt(field: GlobInt) curl_off_t {
    return tool_zig_global_get_int(@backingInt(field));
}
inline fn setGlobInt(field: GlobInt, val: anytype) void {
    tool_zig_global_set_int(@backingInt(field), @intCast(val));
}
inline fn getoutStrPtr(node: *getout, field: GetoutStr) *?[*:0]u8 {
    return tool_zig_getout_str_ptr(node, @backingInt(field));
}
inline fn getoutBit(node: *const getout, field: GetoutBit) bool {
    return tool_zig_getout_get_bit(node, @backingInt(field));
}
inline fn setGetoutBit(node: *getout, field: GetoutBit, val: bool) void {
    tool_zig_getout_set_bit(node, @backingInt(field), val);
}

// ============================================================================
// 1. src/tool_listhelp.c
// ============================================================================

pub const curl_help_t = c_uint;
pub const CURLHELP_AUTH: curl_help_t = 1 << 0;
pub const CURLHELP_CONNECTION: curl_help_t = 1 << 1;
pub const CURLHELP_CURL: curl_help_t = 1 << 2;
pub const CURLHELP_DEPRECATED: curl_help_t = 1 << 3;
pub const CURLHELP_DNS: curl_help_t = 1 << 4;
pub const CURLHELP_FILE: curl_help_t = 1 << 5;
pub const CURLHELP_FTP: curl_help_t = 1 << 6;
pub const CURLHELP_GLOBAL: curl_help_t = 1 << 7;
pub const CURLHELP_HTTP: curl_help_t = 1 << 8;
pub const CURLHELP_IMAP: curl_help_t = 1 << 9;
pub const CURLHELP_IMPORTANT: curl_help_t = 1 << 10;
pub const CURLHELP_LDAP: curl_help_t = 1 << 11;
pub const CURLHELP_OUTPUT: curl_help_t = 1 << 12;
pub const CURLHELP_POP3: curl_help_t = 1 << 13;
pub const CURLHELP_POST: curl_help_t = 1 << 14;
pub const CURLHELP_PROXY: curl_help_t = 1 << 15;
pub const CURLHELP_SCP: curl_help_t = 1 << 16;
pub const CURLHELP_SFTP: curl_help_t = 1 << 17;
pub const CURLHELP_SMTP: curl_help_t = 1 << 18;
pub const CURLHELP_SSH: curl_help_t = 1 << 19;
pub const CURLHELP_TELNET: curl_help_t = 1 << 20;
pub const CURLHELP_TFTP: curl_help_t = 1 << 21;
pub const CURLHELP_TIMEOUT: curl_help_t = 1 << 22;
pub const CURLHELP_TLS: curl_help_t = 1 << 23;
pub const CURLHELP_UPLOAD: curl_help_t = 1 << 24;
pub const CURLHELP_VERBOSE: curl_help_t = 1 << 25;
pub const CURLHELP_MQTT: curl_help_t = 1 << 26;

pub const helptxt = extern struct {
    opt: ?[*:0]const u8,
    desc: ?[*:0]const u8,
    categories: curl_help_t,
};

pub export const helptext: [279]helptxt = .{
    .{ .opt = "    --abstract-unix-socket <path>", .desc = "Connect via abstract Unix domain socket", .categories = CURLHELP_CONNECTION | CURLHELP_HTTP },
    .{ .opt = "    --alt-svc <filename>", .desc = "Enable alt-svc with this cache file", .categories = CURLHELP_HTTP },
    .{ .opt = "    --anyauth", .desc = "Pick any authentication method", .categories = CURLHELP_HTTP | CURLHELP_PROXY | CURLHELP_AUTH },
    .{ .opt = "-a, --append", .desc = "Append to target file when uploading", .categories = CURLHELP_FTP | CURLHELP_SFTP },
    .{ .opt = "    --aws-sigv4 <provider1[:prvdr2[:reg[:srv]]]>", .desc = "AWS V4 signature auth", .categories = CURLHELP_AUTH | CURLHELP_HTTP },
    .{ .opt = "    --basic", .desc = "HTTP Basic Authentication", .categories = CURLHELP_AUTH | CURLHELP_HTTP },
    .{ .opt = "    --ca-native", .desc = "Load CA certs from the OS", .categories = CURLHELP_TLS },
    .{ .opt = "    --cacert <file>", .desc = "CA certificate to verify peer against", .categories = CURLHELP_TLS },
    .{ .opt = "    --capath <dir>", .desc = "CA directory to verify peer against", .categories = CURLHELP_TLS },
    .{ .opt = "-E, --cert <certificate[:password]>", .desc = "Client certificate file and password", .categories = CURLHELP_TLS },
    .{ .opt = "    --cert-status", .desc = "Verify server cert status OCSP-staple", .categories = CURLHELP_TLS },
    .{ .opt = "    --cert-type <type>", .desc = "Certificate type (DER/PEM/ENG/PROV/P12)", .categories = CURLHELP_TLS },
    .{ .opt = "    --ciphers <list>", .desc = "TLS 1.2 (1.1, 1.0) ciphers to use", .categories = CURLHELP_TLS },
    .{ .opt = "    --compressed", .desc = "Request compressed response", .categories = CURLHELP_HTTP },
    .{ .opt = "    --compressed-ssh", .desc = "Enable SSH compression", .categories = CURLHELP_SCP | CURLHELP_SFTP | CURLHELP_SSH },
    .{ .opt = "-K, --config <file>", .desc = "Read config from a file", .categories = CURLHELP_CURL },
    .{ .opt = "    --connect-timeout <seconds>", .desc = "Maximum time allowed to connect", .categories = CURLHELP_CONNECTION | CURLHELP_TIMEOUT },
    .{ .opt = "    --connect-to <HOST1:PORT1:HOST2:PORT2>", .desc = "Connect to host2 instead of host1", .categories = CURLHELP_CONNECTION | CURLHELP_DNS },
    .{ .opt = "-C, --continue-at <offset>", .desc = "Resumed transfer offset", .categories = CURLHELP_CONNECTION },
    .{ .opt = "-b, --cookie <data|filename>", .desc = "Send cookies from string/load from file", .categories = CURLHELP_HTTP },
    .{ .opt = "-c, --cookie-jar <filename>", .desc = "Save cookies to <filename> after operation", .categories = CURLHELP_HTTP },
    .{ .opt = "    --create-dirs", .desc = "Create necessary local directory hierarchy", .categories = CURLHELP_OUTPUT },
    .{ .opt = "    --create-file-mode <mode>", .desc = "File mode for created files", .categories = CURLHELP_SFTP | CURLHELP_SCP | CURLHELP_FILE | CURLHELP_UPLOAD },
    .{ .opt = "    --crlf", .desc = "Convert LF to CRLF in upload", .categories = CURLHELP_FTP | CURLHELP_SMTP },
    .{ .opt = "    --crlfile <file>", .desc = "Certificate Revocation list", .categories = CURLHELP_TLS },
    .{ .opt = "    --curves <list>", .desc = "(EC) TLS key exchange algorithms to request", .categories = CURLHELP_TLS },
    .{ .opt = "-d, --data <data>", .desc = "Post data", .categories = CURLHELP_IMPORTANT | CURLHELP_HTTP | CURLHELP_POST | CURLHELP_UPLOAD | CURLHELP_MQTT },
    .{ .opt = "    --data-ascii <data>", .desc = "HTTP POST ASCII data", .categories = CURLHELP_HTTP | CURLHELP_POST | CURLHELP_UPLOAD },
    .{ .opt = "    --data-binary <data>", .desc = "HTTP POST binary data", .categories = CURLHELP_HTTP | CURLHELP_POST | CURLHELP_UPLOAD },
    .{ .opt = "    --data-raw <data>", .desc = "HTTP POST data, '@' allowed", .categories = CURLHELP_HTTP | CURLHELP_POST | CURLHELP_UPLOAD },
    .{ .opt = "    --data-urlencode <data>", .desc = "HTTP POST data URL encoded", .categories = CURLHELP_HTTP | CURLHELP_POST | CURLHELP_UPLOAD },
    .{ .opt = "    --delegation <LEVEL>", .desc = "GSS-API delegation permission", .categories = CURLHELP_AUTH },
    .{ .opt = "    --digest", .desc = "HTTP Digest Authentication", .categories = CURLHELP_PROXY | CURLHELP_AUTH | CURLHELP_HTTP },
    .{ .opt = "-q, --disable", .desc = "Disable .curlrc", .categories = CURLHELP_CURL },
    .{ .opt = "    --disable-eprt", .desc = "Inhibit using EPRT or LPRT", .categories = CURLHELP_FTP },
    .{ .opt = "    --disable-epsv", .desc = "Inhibit using EPSV", .categories = CURLHELP_FTP },
    .{ .opt = "    --disallow-username-in-url", .desc = "Disallow username in URL", .categories = CURLHELP_CURL },
    .{ .opt = "    --dns-interface <interface>", .desc = "Interface to use for DNS requests", .categories = CURLHELP_DNS },
    .{ .opt = "    --dns-ipv4-addr <address>", .desc = "IPv4 address to use for DNS requests", .categories = CURLHELP_DNS },
    .{ .opt = "    --dns-ipv6-addr <address>", .desc = "IPv6 address to use for DNS requests", .categories = CURLHELP_DNS },
    .{ .opt = "    --dns-servers <addresses>", .desc = "DNS server addrs to use", .categories = CURLHELP_DNS },
    .{ .opt = "    --doh-cert-status", .desc = "Verify DoH server cert status OCSP-staple", .categories = CURLHELP_DNS | CURLHELP_TLS },
    .{ .opt = "    --doh-insecure", .desc = "Allow insecure DoH server connections", .categories = CURLHELP_DNS | CURLHELP_TLS },
    .{ .opt = "    --doh-url <URL>", .desc = "Resolve hostnames over DoH", .categories = CURLHELP_DNS },
    .{ .opt = "    --dump-ca-embed", .desc = "Write the embedded CA bundle to standard output", .categories = CURLHELP_HTTP | CURLHELP_PROXY | CURLHELP_TLS },
    .{ .opt = "-D, --dump-header <filename>", .desc = "Write the received headers to <filename>", .categories = CURLHELP_HTTP | CURLHELP_FTP },
    .{ .opt = "    --ech <config>", .desc = "Configure ECH", .categories = CURLHELP_TLS },
    .{ .opt = "    --egd-file <file>", .desc = "EGD socket path for random data", .categories = CURLHELP_DEPRECATED },
    .{ .opt = "    --engine <name>", .desc = "Crypto engine to use", .categories = CURLHELP_TLS },
    .{ .opt = "    --etag-compare <file>", .desc = "Load ETag from file", .categories = CURLHELP_HTTP },
    .{ .opt = "    --etag-save <file>", .desc = "Parse incoming ETag and save to a file", .categories = CURLHELP_HTTP },
    .{ .opt = "    --expect100-timeout <seconds>", .desc = "How long to wait for 100-continue", .categories = CURLHELP_HTTP | CURLHELP_TIMEOUT },
    .{ .opt = "-f, --fail", .desc = "Fail fast with no output on HTTP errors", .categories = CURLHELP_IMPORTANT | CURLHELP_HTTP },
    .{ .opt = "    --fail-early", .desc = "Fail on first transfer error", .categories = CURLHELP_CURL | CURLHELP_GLOBAL },
    .{ .opt = "    --fail-with-body", .desc = "Fail on HTTP errors but save the body", .categories = CURLHELP_HTTP | CURLHELP_OUTPUT },
    .{ .opt = "    --false-start", .desc = "Enable TLS False Start", .categories = CURLHELP_DEPRECATED },
    .{ .opt = "    --follow", .desc = "Follow redirects per spec", .categories = CURLHELP_HTTP },
    .{ .opt = "-F, --form <name=content>", .desc = "Specify multipart MIME data", .categories = CURLHELP_HTTP | CURLHELP_UPLOAD | CURLHELP_POST | CURLHELP_IMAP | CURLHELP_SMTP },
    .{ .opt = "    --form-escape", .desc = "Escape form fields using backslash", .categories = CURLHELP_HTTP | CURLHELP_UPLOAD | CURLHELP_POST | CURLHELP_IMAP | CURLHELP_SMTP },
    .{ .opt = "    --form-string <name=string>", .desc = "Specify multipart MIME data", .categories = CURLHELP_HTTP | CURLHELP_UPLOAD | CURLHELP_POST | CURLHELP_SMTP | CURLHELP_IMAP },
    .{ .opt = "    --ftp-account <data>", .desc = "Account data string", .categories = CURLHELP_FTP | CURLHELP_AUTH },
    .{ .opt = "    --ftp-alternative-to-user <command>", .desc = "String to replace USER [name]", .categories = CURLHELP_FTP },
    .{ .opt = "    --ftp-create-dirs", .desc = "Create the remote dirs if not present", .categories = CURLHELP_FTP | CURLHELP_SFTP },
    .{ .opt = "    --ftp-method <method>", .desc = "Control CWD usage", .categories = CURLHELP_FTP },
    .{ .opt = "    --ftp-pasv", .desc = "Send PASV/EPSV instead of PORT", .categories = CURLHELP_FTP },
    .{ .opt = "-P, --ftp-port <address>", .desc = "Send PORT instead of PASV", .categories = CURLHELP_FTP },
    .{ .opt = "    --ftp-pret", .desc = "Send PRET before PASV", .categories = CURLHELP_FTP },
    .{ .opt = "    --ftp-skip-pasv-ip", .desc = "Skip the IP address for PASV", .categories = CURLHELP_FTP },
    .{ .opt = "    --ftp-ssl-ccc", .desc = "Send CCC after authenticating", .categories = CURLHELP_FTP | CURLHELP_TLS },
    .{ .opt = "    --ftp-ssl-ccc-mode <active/passive>", .desc = "Set CCC mode", .categories = CURLHELP_FTP | CURLHELP_TLS },
    .{ .opt = "    --ftp-ssl-control", .desc = "Require TLS for login, clear for transfer", .categories = CURLHELP_FTP | CURLHELP_TLS },
    .{ .opt = "-G, --get", .desc = "Put the post data in the URL and use GET", .categories = CURLHELP_HTTP },
    .{ .opt = "-g, --globoff", .desc = "Disable URL globbing with {} and []", .categories = CURLHELP_CURL },
    .{ .opt = "    --happy-eyeballs-timeout-ms <ms>", .desc = "Time for IPv6 before IPv4", .categories = CURLHELP_CONNECTION | CURLHELP_TIMEOUT },
    .{ .opt = "    --haproxy-clientip <ip>", .desc = "Set address in HAProxy PROXY", .categories = CURLHELP_HTTP | CURLHELP_PROXY },
    .{ .opt = "    --haproxy-protocol", .desc = "Send HAProxy PROXY protocol v1 header", .categories = CURLHELP_HTTP | CURLHELP_PROXY },
    .{ .opt = "-I, --head", .desc = "Show document info only", .categories = CURLHELP_IMPORTANT | CURLHELP_HTTP | CURLHELP_FTP | CURLHELP_FILE },
    .{ .opt = "-H, --header <header/@file>", .desc = "Pass custom header(s) to server", .categories = CURLHELP_IMPORTANT | CURLHELP_HTTP | CURLHELP_IMAP | CURLHELP_SMTP },
    .{ .opt = "-h, --help <subject>", .desc = "Get help for commands", .categories = CURLHELP_IMPORTANT | CURLHELP_CURL },
    .{ .opt = "    --hostpubmd5 <md5>", .desc = "Acceptable MD5 hash of host public key", .categories = CURLHELP_SFTP | CURLHELP_SCP | CURLHELP_SSH },
    .{ .opt = "    --hostpubsha256 <sha256>", .desc = "Acceptable SHA256 hash of host public key", .categories = CURLHELP_SFTP | CURLHELP_SCP | CURLHELP_SSH },
    .{ .opt = "    --hsts <filename>", .desc = "Enable HSTS with this cache file", .categories = CURLHELP_HTTP },
    .{ .opt = "    --http0.9", .desc = "Allow HTTP/0.9 responses", .categories = CURLHELP_HTTP },
    .{ .opt = "-0, --http1.0", .desc = "Use HTTP/1.0", .categories = CURLHELP_HTTP },
    .{ .opt = "    --http1.1", .desc = "Use HTTP/1.1", .categories = CURLHELP_HTTP },
    .{ .opt = "    --http2", .desc = "Use HTTP/2", .categories = CURLHELP_HTTP },
    .{ .opt = "    --http2-prior-knowledge", .desc = "Use HTTP/2 without HTTP/1.1 Upgrade", .categories = CURLHELP_HTTP },
    .{ .opt = "    --http3", .desc = "Use HTTP/3", .categories = CURLHELP_HTTP },
    .{ .opt = "    --http3-only", .desc = "Use HTTP/3 only", .categories = CURLHELP_HTTP },
    .{ .opt = "    --httpsig-algo <algorithm>", .desc = "Algorithm for HTTP Message Signatures", .categories = CURLHELP_AUTH | CURLHELP_HTTP },
    .{ .opt = "    --httpsig-headers <components>", .desc = "Components to sign for HTTP Message Signatures", .categories = CURLHELP_AUTH | CURLHELP_HTTP },
    .{ .opt = "    --httpsig-key <key/file>", .desc = "Key for HTTP Message Signatures", .categories = CURLHELP_AUTH | CURLHELP_HTTP },
    .{ .opt = "    --httpsig-keyid <id>", .desc = "Key identifier for HTTP Message Signatures", .categories = CURLHELP_AUTH | CURLHELP_HTTP },
    .{ .opt = "    --ignore-content-length", .desc = "Ignore the size of the remote resource", .categories = CURLHELP_HTTP | CURLHELP_FTP },
    .{ .opt = "-k, --insecure", .desc = "Allow insecure server connections", .categories = CURLHELP_TLS | CURLHELP_SFTP | CURLHELP_SCP | CURLHELP_SSH },
    .{ .opt = "    --interface <name>", .desc = "Use network interface", .categories = CURLHELP_CONNECTION },
    .{ .opt = "    --ip-tos <string>", .desc = "Set IP Type of Service or Traffic Class", .categories = CURLHELP_CONNECTION },
    .{ .opt = "    --ipfs-gateway <URL>", .desc = "Gateway for IPFS", .categories = CURLHELP_CURL },
    .{ .opt = "-4, --ipv4", .desc = "Resolve names to IPv4 addresses", .categories = CURLHELP_CONNECTION | CURLHELP_DNS },
    .{ .opt = "-6, --ipv6", .desc = "Resolve names to IPv6 addresses", .categories = CURLHELP_CONNECTION | CURLHELP_DNS },
    .{ .opt = "    --json <data>", .desc = "HTTP POST JSON", .categories = CURLHELP_HTTP | CURLHELP_POST | CURLHELP_UPLOAD },
    .{ .opt = "-j, --junk-session-cookies", .desc = "Ignore session cookies read from file", .categories = CURLHELP_HTTP },
    .{ .opt = "    --keepalive-cnt <integer>", .desc = "Maximum number of keepalive probes", .categories = CURLHELP_CONNECTION },
    .{ .opt = "    --keepalive-time <seconds>", .desc = "Interval time for keepalive probes", .categories = CURLHELP_CONNECTION | CURLHELP_TIMEOUT },
    .{ .opt = "    --key <key>", .desc = "Private key filename", .categories = CURLHELP_TLS | CURLHELP_SFTP | CURLHELP_SCP | CURLHELP_SSH },
    .{ .opt = "    --key-type <type>", .desc = "Private key file type (DER/PEM/ENG)", .categories = CURLHELP_TLS },
    .{ .opt = "    --knownhosts <file>", .desc = "Specify knownhosts path", .categories = CURLHELP_SFTP | CURLHELP_SCP | CURLHELP_SSH },
    .{ .opt = "    --krb <level>", .desc = "Enable Kerberos with security <level>", .categories = CURLHELP_DEPRECATED },
    .{ .opt = "    --libcurl <file>", .desc = "Generate libcurl code for this command line", .categories = CURLHELP_CURL | CURLHELP_GLOBAL },
    .{ .opt = "    --limit-rate <speed>", .desc = "Limit transfer speed to RATE", .categories = CURLHELP_CONNECTION },
    .{ .opt = "-l, --list-only", .desc = "List only mode", .categories = CURLHELP_FTP | CURLHELP_POP3 | CURLHELP_SFTP | CURLHELP_FILE },
    .{ .opt = "    --local-port <range>", .desc = "Use a local port number within RANGE", .categories = CURLHELP_CONNECTION },
    .{ .opt = "-L, --location", .desc = "Follow redirects", .categories = CURLHELP_HTTP },
    .{ .opt = "    --location-trusted", .desc = "As --location, but send secrets to other hosts", .categories = CURLHELP_HTTP | CURLHELP_AUTH },
    .{ .opt = "    --login-options <options>", .desc = "Server login options", .categories = CURLHELP_IMAP | CURLHELP_POP3 | CURLHELP_SMTP | CURLHELP_AUTH | CURLHELP_LDAP },
    .{ .opt = "    --mail-auth <address>", .desc = "Originator address of the original email", .categories = CURLHELP_SMTP },
    .{ .opt = "    --mail-from <address>", .desc = "Mail from this address", .categories = CURLHELP_SMTP },
    .{ .opt = "    --mail-rcpt <address>", .desc = "Mail to this address", .categories = CURLHELP_SMTP },
    .{ .opt = "    --mail-rcpt-allowfails", .desc = "Allow RCPT TO command to fail", .categories = CURLHELP_SMTP },
    .{ .opt = "-M, --manual", .desc = "Display the full manual", .categories = CURLHELP_CURL },
    .{ .opt = "    --max-filesize <bytes>", .desc = "Maximum file size to download", .categories = CURLHELP_CONNECTION | CURLHELP_FTP | CURLHELP_HTTP | CURLHELP_MQTT },
    .{ .opt = "    --max-redirs <num>", .desc = "Maximum number of redirects allowed", .categories = CURLHELP_HTTP },
    .{ .opt = "-m, --max-time <seconds>", .desc = "Maximum time allowed for transfer", .categories = CURLHELP_CONNECTION | CURLHELP_TIMEOUT },
    .{ .opt = "    --metalink", .desc = "Process given URLs as metalink XML file", .categories = CURLHELP_DEPRECATED },
    .{ .opt = "    --mptcp", .desc = "Enable Multipath TCP", .categories = CURLHELP_CONNECTION },
    .{ .opt = "    --negotiate", .desc = "Use HTTP Negotiate (SPNEGO) authentication", .categories = CURLHELP_AUTH | CURLHELP_HTTP },
    .{ .opt = "-n, --netrc", .desc = "Must read .netrc for username and password", .categories = CURLHELP_AUTH },
    .{ .opt = "    --netrc-file <filename>", .desc = "Specify FILE for netrc", .categories = CURLHELP_AUTH },
    .{ .opt = "    --netrc-optional", .desc = "Use either .netrc or URL", .categories = CURLHELP_AUTH },
    .{ .opt = "-:, --next", .desc = "Make next URL use separate options", .categories = CURLHELP_CURL },
    .{ .opt = "    --no-alpn", .desc = "Disable the ALPN TLS extension", .categories = CURLHELP_TLS | CURLHELP_HTTP },
    .{ .opt = "-N, --no-buffer", .desc = "Disable buffering of the output stream", .categories = CURLHELP_OUTPUT },
    .{ .opt = "    --no-clobber", .desc = "Do not overwrite files that already exist", .categories = CURLHELP_OUTPUT },
    .{ .opt = "    --no-keepalive", .desc = "Disable TCP keepalive on the connection", .categories = CURLHELP_CONNECTION },
    .{ .opt = "    --no-npn", .desc = "Disable the NPN TLS extension", .categories = CURLHELP_DEPRECATED },
    .{ .opt = "    --no-progress-meter", .desc = "Do not show the progress meter", .categories = CURLHELP_VERBOSE },
    .{ .opt = "    --no-sessionid", .desc = "Disable SSL session-ID reusing", .categories = CURLHELP_TLS },
    .{ .opt = "    --noproxy <no-proxy-list>", .desc = "List of hosts which do not use proxy", .categories = CURLHELP_PROXY },
    .{ .opt = "    --ntlm", .desc = "HTTP NTLM authentication", .categories = CURLHELP_AUTH | CURLHELP_HTTP },
    .{ .opt = "    --ntlm-wb", .desc = "HTTP NTLM authentication with winbind", .categories = CURLHELP_DEPRECATED },
    .{ .opt = "    --oauth2-bearer <token>", .desc = "OAuth 2 Bearer Token", .categories = CURLHELP_AUTH | CURLHELP_IMAP | CURLHELP_POP3 | CURLHELP_SMTP | CURLHELP_LDAP | CURLHELP_HTTP },
    .{ .opt = "    --out-null", .desc = "Discard response data into the void", .categories = CURLHELP_OUTPUT },
    .{ .opt = "-o, --output <file>", .desc = "Write to file instead of stdout", .categories = CURLHELP_IMPORTANT | CURLHELP_OUTPUT },
    .{ .opt = "    --output-dir <dir>", .desc = "Directory to save files in", .categories = CURLHELP_OUTPUT },
    .{ .opt = "-Z, --parallel", .desc = "Perform transfers in parallel", .categories = CURLHELP_CONNECTION | CURLHELP_CURL | CURLHELP_GLOBAL },
    .{ .opt = "    --parallel-immediate", .desc = "Do not wait for multiplexing", .categories = CURLHELP_CONNECTION | CURLHELP_CURL | CURLHELP_GLOBAL },
    .{ .opt = "    --parallel-max <num>", .desc = "Maximum concurrency for parallel transfers", .categories = CURLHELP_CONNECTION | CURLHELP_CURL | CURLHELP_GLOBAL },
    .{ .opt = "    --parallel-max-host <num>", .desc = "Maximum connections to a single host", .categories = CURLHELP_CONNECTION | CURLHELP_CURL | CURLHELP_GLOBAL },
    .{ .opt = "    --pass <phrase>", .desc = "Passphrase for the private key", .categories = CURLHELP_TLS | CURLHELP_SFTP | CURLHELP_SCP | CURLHELP_SSH | CURLHELP_AUTH },
    .{ .opt = "    --path-as-is", .desc = "Do not squash .. sequences in URL path", .categories = CURLHELP_CURL },
    .{ .opt = "    --pinnedpubkey <hashes>", .desc = "Public key to verify peer against", .categories = CURLHELP_TLS },
    .{ .opt = "    --post301", .desc = "Do not switch to GET after a 301 redirect", .categories = CURLHELP_HTTP | CURLHELP_POST },
    .{ .opt = "    --post302", .desc = "Do not switch to GET after a 302 redirect", .categories = CURLHELP_HTTP | CURLHELP_POST },
    .{ .opt = "    --post303", .desc = "Do not switch to GET after a 303 redirect", .categories = CURLHELP_HTTP | CURLHELP_POST },
    .{ .opt = "    --preproxy <[protocol://]host[:port]>", .desc = "Use this proxy first", .categories = CURLHELP_PROXY },
    .{ .opt = "-#, --progress-bar", .desc = "Display transfer progress as a bar", .categories = CURLHELP_VERBOSE | CURLHELP_GLOBAL },
    .{ .opt = "    --proto <protocols>", .desc = "Enable/disable PROTOCOLS", .categories = CURLHELP_CONNECTION | CURLHELP_CURL },
    .{ .opt = "    --proto-default <protocol>", .desc = "Use PROTOCOL for any URL missing a scheme", .categories = CURLHELP_CONNECTION | CURLHELP_CURL },
    .{ .opt = "    --proto-redir <protocols>", .desc = "Enable/disable PROTOCOLS on redirect", .categories = CURLHELP_CONNECTION | CURLHELP_CURL },
    .{ .opt = "-x, --proxy <[protocol://]host[:port]>", .desc = "Use this proxy", .categories = CURLHELP_PROXY },
    .{ .opt = "    --proxy-anyauth", .desc = "Pick any proxy authentication method", .categories = CURLHELP_PROXY | CURLHELP_AUTH },
    .{ .opt = "    --proxy-basic", .desc = "Use Basic authentication on the proxy", .categories = CURLHELP_PROXY | CURLHELP_AUTH },
    .{ .opt = "    --proxy-ca-native", .desc = "Load CA certs from the OS to verify proxy", .categories = CURLHELP_TLS },
    .{ .opt = "    --proxy-cacert <file>", .desc = "CA certificates to verify proxy against", .categories = CURLHELP_PROXY | CURLHELP_TLS },
    .{ .opt = "    --proxy-capath <dir>", .desc = "CA directory to verify proxy against", .categories = CURLHELP_PROXY | CURLHELP_TLS },
    .{ .opt = "    --proxy-cert <cert[:passwd]>", .desc = "Set client certificate for proxy", .categories = CURLHELP_PROXY | CURLHELP_TLS },
    .{ .opt = "    --proxy-cert-type <type>", .desc = "Client certificate type for HTTPS proxy", .categories = CURLHELP_PROXY | CURLHELP_TLS },
    .{ .opt = "    --proxy-ciphers <list>", .desc = "TLS 1.2 (1.1, 1.0) ciphers to use for proxy", .categories = CURLHELP_PROXY | CURLHELP_TLS },
    .{ .opt = "    --proxy-crlfile <file>", .desc = "Set a CRL list for proxy", .categories = CURLHELP_PROXY | CURLHELP_TLS },
    .{ .opt = "    --proxy-digest", .desc = "Digest auth with the proxy", .categories = CURLHELP_PROXY | CURLHELP_TLS },
    .{ .opt = "    --proxy-header <header/@file>", .desc = "Pass custom header(s) to proxy", .categories = CURLHELP_PROXY | CURLHELP_HTTP },
    .{ .opt = "    --proxy-http2", .desc = "Use HTTP/2 with HTTPS proxy", .categories = CURLHELP_HTTP | CURLHELP_PROXY },
    .{ .opt = "    --proxy-http3", .desc = "Use HTTP/3 with HTTPS proxy", .categories = CURLHELP_HTTP | CURLHELP_PROXY },
    .{ .opt = "    --proxy-insecure", .desc = "Skip HTTPS proxy cert verification", .categories = CURLHELP_PROXY | CURLHELP_TLS },
    .{ .opt = "    --proxy-key <key>", .desc = "Private key for HTTPS proxy", .categories = CURLHELP_PROXY | CURLHELP_TLS },
    .{ .opt = "    --proxy-key-type <type>", .desc = "Private key file type for proxy", .categories = CURLHELP_PROXY | CURLHELP_TLS },
    .{ .opt = "    --proxy-negotiate", .desc = "HTTP Negotiate (SPNEGO) auth with the proxy", .categories = CURLHELP_PROXY | CURLHELP_AUTH },
    .{ .opt = "    --proxy-ntlm", .desc = "NTLM authentication with the proxy", .categories = CURLHELP_PROXY | CURLHELP_AUTH },
    .{ .opt = "    --proxy-pass <phrase>", .desc = "Passphrase for private key for HTTPS proxy", .categories = CURLHELP_PROXY | CURLHELP_TLS | CURLHELP_AUTH },
    .{ .opt = "    --proxy-pinnedpubkey <hashes>", .desc = "FILE/HASHES public key to verify proxy with", .categories = CURLHELP_PROXY | CURLHELP_TLS },
    .{ .opt = "    --proxy-service-name <name>", .desc = "SPNEGO proxy service name", .categories = CURLHELP_PROXY | CURLHELP_TLS },
    .{ .opt = "    --proxy-ssl-allow-beast", .desc = "Allow this security flaw for HTTPS proxy", .categories = CURLHELP_PROXY | CURLHELP_TLS },
    .{ .opt = "    --proxy-ssl-auto-client-cert", .desc = "Auto client certificate for proxy", .categories = CURLHELP_PROXY | CURLHELP_TLS },
    .{ .opt = "    --proxy-tls13-ciphers <list>", .desc = "TLS 1.3 proxy cipher suites", .categories = CURLHELP_PROXY | CURLHELP_TLS },
    .{ .opt = "    --proxy-tlsauthtype <type>", .desc = "TLS authentication type for HTTPS proxy", .categories = CURLHELP_PROXY | CURLHELP_TLS | CURLHELP_AUTH },
    .{ .opt = "    --proxy-tlspassword <string>", .desc = "TLS password for HTTPS proxy", .categories = CURLHELP_PROXY | CURLHELP_TLS | CURLHELP_AUTH },
    .{ .opt = "    --proxy-tlsuser <name>", .desc = "TLS username for HTTPS proxy", .categories = CURLHELP_PROXY | CURLHELP_TLS | CURLHELP_AUTH },
    .{ .opt = "    --proxy-tlsv1", .desc = "TLSv1 for HTTPS proxy", .categories = CURLHELP_PROXY | CURLHELP_TLS | CURLHELP_AUTH },
    .{ .opt = "-U, --proxy-user <user:password>", .desc = "Proxy user and password", .categories = CURLHELP_PROXY | CURLHELP_AUTH },
    .{ .opt = "    --proxy1.0 <host[:port]>", .desc = "Use HTTP/1.0 proxy on given port", .categories = CURLHELP_PROXY },
    .{ .opt = "-p, --proxytunnel", .desc = "HTTP proxy tunnel (using CONNECT)", .categories = CURLHELP_PROXY },
    .{ .opt = "    --pubkey <key>", .desc = "SSH Public key filename", .categories = CURLHELP_SFTP | CURLHELP_SCP | CURLHELP_SSH | CURLHELP_AUTH },
    .{ .opt = "-Q, --quote <command>", .desc = "Send command(s) to server before transfer", .categories = CURLHELP_FTP | CURLHELP_SFTP },
    .{ .opt = "    --random-file <file>", .desc = "File for reading random data from", .categories = CURLHELP_DEPRECATED },
    .{ .opt = "-r, --range <range>", .desc = "Retrieve only the bytes within RANGE", .categories = CURLHELP_HTTP | CURLHELP_FTP | CURLHELP_SFTP | CURLHELP_FILE },
    .{ .opt = "    --rate <max request rate>", .desc = "Request rate for serial transfers", .categories = CURLHELP_CONNECTION | CURLHELP_GLOBAL },
    .{ .opt = "    --raw", .desc = "Do HTTP raw; no transfer decoding", .categories = CURLHELP_HTTP },
    .{ .opt = "-e, --referer <URL>", .desc = "Referrer URL", .categories = CURLHELP_HTTP },
    .{ .opt = "-J, --remote-header-name", .desc = "Use the header-provided filename", .categories = CURLHELP_OUTPUT | CURLHELP_HTTP },
    .{ .opt = "-O, --remote-name", .desc = "Write output to file named as remote file", .categories = CURLHELP_IMPORTANT | CURLHELP_OUTPUT },
    .{ .opt = "    --remote-name-all", .desc = "Use the remote filename for all URLs", .categories = CURLHELP_OUTPUT },
    .{ .opt = "-R, --remote-time", .desc = "Set remote file's time on local output", .categories = CURLHELP_OUTPUT },
    .{ .opt = "    --remove-on-error", .desc = "Remove output file on errors", .categories = CURLHELP_OUTPUT },
    .{ .opt = "-X, --request <method>", .desc = "Specify request method to use", .categories = CURLHELP_CONNECTION | CURLHELP_POP3 | CURLHELP_FTP | CURLHELP_IMAP | CURLHELP_SMTP },
    .{ .opt = "    --request-target <path>", .desc = "Specify the target for this request", .categories = CURLHELP_HTTP },
    .{ .opt = "    --resolve <[+]host:port:addr[,addr]...>", .desc = "Resolve host+port to address", .categories = CURLHELP_CONNECTION | CURLHELP_DNS },
    .{ .opt = "    --retry <num>", .desc = "Retry request if transient problems occur", .categories = CURLHELP_CURL },
    .{ .opt = "    --retry-all-errors", .desc = "Retry all errors (with --retry)", .categories = CURLHELP_CURL },
    .{ .opt = "    --retry-connrefused", .desc = "Retry on connection refused (with --retry)", .categories = CURLHELP_CURL },
    .{ .opt = "    --retry-delay <seconds>", .desc = "Wait time between retries", .categories = CURLHELP_CURL | CURLHELP_TIMEOUT },
    .{ .opt = "    --retry-max-time <seconds>", .desc = "Retry only within this period", .categories = CURLHELP_CURL | CURLHELP_TIMEOUT },
    .{ .opt = "    --sasl-authzid <identity>", .desc = "Identity for SASL PLAIN authentication", .categories = CURLHELP_AUTH | CURLHELP_IMAP | CURLHELP_SMTP | CURLHELP_POP3 | CURLHELP_LDAP },
    .{ .opt = "    --sasl-ir", .desc = "Initial response in SASL authentication", .categories = CURLHELP_AUTH | CURLHELP_IMAP | CURLHELP_POP3 | CURLHELP_LDAP | CURLHELP_SMTP },
    .{ .opt = "    --service-name <name>", .desc = "SPNEGO service name", .categories = CURLHELP_AUTH },
    .{ .opt = "-S, --show-error", .desc = "Show error even when -s is used", .categories = CURLHELP_CURL | CURLHELP_GLOBAL },
    .{ .opt = "-i, --show-headers", .desc = "Show response headers in output", .categories = CURLHELP_IMPORTANT | CURLHELP_VERBOSE | CURLHELP_OUTPUT | CURLHELP_HTTP | CURLHELP_FTP },
    .{ .opt = "    --sigalgs <list>", .desc = "TLS signature algorithms to use", .categories = CURLHELP_TLS },
    .{ .opt = "-s, --silent", .desc = "Silent mode", .categories = CURLHELP_IMPORTANT | CURLHELP_VERBOSE },
    .{ .opt = "    --skip-existing", .desc = "Skip download if local file already exists", .categories = CURLHELP_CURL | CURLHELP_OUTPUT },
    .{ .opt = "    --socks4 <host[:port]>", .desc = "SOCKS4 proxy on given host + port", .categories = CURLHELP_PROXY },
    .{ .opt = "    --socks4a <host[:port]>", .desc = "SOCKS4a proxy on given host + port", .categories = CURLHELP_PROXY },
    .{ .opt = "    --socks5 <host[:port]>", .desc = "SOCKS5 proxy on given host + port", .categories = CURLHELP_PROXY },
    .{ .opt = "    --socks5-basic", .desc = "Username/password auth for SOCKS5 proxies", .categories = CURLHELP_PROXY | CURLHELP_AUTH },
    .{ .opt = "    --socks5-gssapi", .desc = "Enable GSS-API auth for SOCKS5 proxies", .categories = CURLHELP_PROXY | CURLHELP_AUTH },
    .{ .opt = "    --socks5-gssapi-nec", .desc = "Compatibility with NEC SOCKS5 server", .categories = CURLHELP_PROXY | CURLHELP_AUTH },
    .{ .opt = "    --socks5-gssapi-service <name>", .desc = "SOCKS5 proxy service name for GSS-API", .categories = CURLHELP_PROXY | CURLHELP_AUTH },
    .{ .opt = "    --socks5-hostname <host[:port]>", .desc = "SOCKS5 proxy, pass hostname to proxy", .categories = CURLHELP_PROXY },
    .{ .opt = "-Y, --speed-limit <speed>", .desc = "Stop transfers slower than this", .categories = CURLHELP_CONNECTION },
    .{ .opt = "-y, --speed-time <seconds>", .desc = "Trigger 'speed-limit' abort after this time", .categories = CURLHELP_CONNECTION | CURLHELP_TIMEOUT },
    .{ .opt = "    --ssl", .desc = "Try enabling TLS", .categories = CURLHELP_TLS | CURLHELP_IMAP | CURLHELP_POP3 | CURLHELP_SMTP | CURLHELP_LDAP | CURLHELP_FTP },
    .{ .opt = "    --ssl-allow-beast", .desc = "Allow security flaw to improve interop", .categories = CURLHELP_TLS },
    .{ .opt = "    --ssl-auto-client-cert", .desc = "Use auto client certificate (Schannel)", .categories = CURLHELP_TLS },
    .{ .opt = "    --ssl-no-revoke", .desc = "Disable cert revocation checks (Schannel)", .categories = CURLHELP_TLS },
    .{ .opt = "    --ssl-reqd", .desc = "Require SSL/TLS", .categories = CURLHELP_TLS | CURLHELP_IMAP | CURLHELP_POP3 | CURLHELP_SMTP | CURLHELP_LDAP | CURLHELP_FTP },
    .{ .opt = "    --ssl-revoke-best-effort", .desc = "Ignore missing cert CRL dist points", .categories = CURLHELP_TLS },
    .{ .opt = "    --ssl-sessions <filename>", .desc = "Load/save SSL session tickets from/to this file", .categories = CURLHELP_TLS },
    .{ .opt = "-2, --sslv2", .desc = "SSLv2", .categories = CURLHELP_DEPRECATED },
    .{ .opt = "-3, --sslv3", .desc = "SSLv3", .categories = CURLHELP_DEPRECATED },
    .{ .opt = "    --stderr <file>", .desc = "Where to redirect stderr", .categories = CURLHELP_VERBOSE | CURLHELP_GLOBAL },
    .{ .opt = "    --styled-output", .desc = "Enable styled output for HTTP headers", .categories = CURLHELP_VERBOSE | CURLHELP_GLOBAL },
    .{ .opt = "    --suppress-connect-headers", .desc = "Suppress proxy CONNECT response headers", .categories = CURLHELP_PROXY },
    .{ .opt = "    --tcp-fastopen", .desc = "Use TCP Fast Open", .categories = CURLHELP_CONNECTION },
    .{ .opt = "    --tcp-nodelay", .desc = "Set TCP_NODELAY", .categories = CURLHELP_CONNECTION },
    .{ .opt = "-t, --telnet-option <opt=val>", .desc = "Set telnet option", .categories = CURLHELP_TELNET },
    .{ .opt = "    --tftp-blksize <value>", .desc = "Set TFTP BLKSIZE option", .categories = CURLHELP_TFTP },
    .{ .opt = "    --tftp-no-options", .desc = "Do not send any TFTP options", .categories = CURLHELP_TFTP },
    .{ .opt = "-z, --time-cond <time>", .desc = "Transfer based on a time condition", .categories = CURLHELP_HTTP | CURLHELP_FTP },
    .{ .opt = "    --tls-earlydata", .desc = "Allow use of TLSv1.3 early data (0RTT)", .categories = CURLHELP_TLS },
    .{ .opt = "    --tls-max <VERSION>", .desc = "Maximum allowed TLS version", .categories = CURLHELP_TLS },
    .{ .opt = "    --tls13-ciphers <list>", .desc = "TLS 1.3 cipher suites to use", .categories = CURLHELP_TLS },
    .{ .opt = "    --tlsauthtype <type>", .desc = "TLS authentication type", .categories = CURLHELP_TLS | CURLHELP_AUTH },
    .{ .opt = "    --tlspassword <string>", .desc = "TLS password", .categories = CURLHELP_TLS | CURLHELP_AUTH },
    .{ .opt = "    --tlsuser <name>", .desc = "TLS username", .categories = CURLHELP_TLS | CURLHELP_AUTH },
    .{ .opt = "-1, --tlsv1", .desc = "TLSv1.0 or greater", .categories = CURLHELP_TLS },
    .{ .opt = "    --tlsv1.0", .desc = "TLSv1.0 or greater", .categories = CURLHELP_TLS },
    .{ .opt = "    --tlsv1.1", .desc = "TLSv1.1 or greater", .categories = CURLHELP_TLS },
    .{ .opt = "    --tlsv1.2", .desc = "TLSv1.2 or greater", .categories = CURLHELP_TLS },
    .{ .opt = "    --tlsv1.3", .desc = "TLSv1.3 or greater", .categories = CURLHELP_TLS },
    .{ .opt = "    --tr-encoding", .desc = "Request compressed transfer encoding", .categories = CURLHELP_HTTP },
    .{ .opt = "    --trace <file>", .desc = "Write a debug trace to FILE", .categories = CURLHELP_VERBOSE | CURLHELP_GLOBAL },
    .{ .opt = "    --trace-ascii <file>", .desc = "Like --trace, but without hex output", .categories = CURLHELP_VERBOSE | CURLHELP_GLOBAL },
    .{ .opt = "    --trace-config <string>", .desc = "Details to log in trace/verbose output", .categories = CURLHELP_VERBOSE | CURLHELP_GLOBAL },
    .{ .opt = "    --trace-ids", .desc = "Transfer + connection ids in verbose output", .categories = CURLHELP_VERBOSE | CURLHELP_GLOBAL },
    .{ .opt = "    --trace-time", .desc = "Add time stamps to trace/verbose output", .categories = CURLHELP_VERBOSE | CURLHELP_GLOBAL },
    .{ .opt = "    --unix-socket <path>", .desc = "Connect through this Unix domain socket", .categories = CURLHELP_CONNECTION | CURLHELP_HTTP },
    .{ .opt = "-T, --upload-file <file>", .desc = "Transfer local FILE to destination", .categories = CURLHELP_IMPORTANT | CURLHELP_UPLOAD | CURLHELP_IMAP },
    .{ .opt = "    --upload-flags <flags>", .desc = "IMAP upload behavior", .categories = CURLHELP_CURL | CURLHELP_OUTPUT | CURLHELP_IMAP | CURLHELP_UPLOAD },
    .{ .opt = "    --url <url/file>", .desc = "URL(s) to work with", .categories = CURLHELP_CURL },
    .{ .opt = "    --url-query <data>", .desc = "Add a URL query part", .categories = CURLHELP_HTTP | CURLHELP_POST | CURLHELP_UPLOAD },
    .{ .opt = "-B, --use-ascii", .desc = "Use ASCII/text transfer", .categories = CURLHELP_FTP | CURLHELP_OUTPUT | CURLHELP_LDAP | CURLHELP_TFTP },
    .{ .opt = "-u, --user <user:password>", .desc = "Server user and password", .categories = CURLHELP_IMPORTANT | CURLHELP_AUTH },
    .{ .opt = "-A, --user-agent <name>", .desc = "Send User-Agent <name> to server", .categories = CURLHELP_IMPORTANT | CURLHELP_HTTP },
    .{ .opt = "    --variable <[%]name=text/@file>", .desc = "Set variable", .categories = CURLHELP_CURL },
    .{ .opt = "-v, --verbose", .desc = "Make the operation more talkative", .categories = CURLHELP_IMPORTANT | CURLHELP_VERBOSE | CURLHELP_GLOBAL },
    .{ .opt = "-V, --version", .desc = "Show version number and quit", .categories = CURLHELP_IMPORTANT | CURLHELP_CURL },
    .{ .opt = "    --vlan-priority <priority>", .desc = "Set VLAN priority", .categories = CURLHELP_CONNECTION },
    .{ .opt = "-w, --write-out <format>", .desc = "Output FORMAT after completion", .categories = CURLHELP_VERBOSE },
    .{ .opt = "    --xattr", .desc = "Store metadata in extended file attributes", .categories = CURLHELP_OUTPUT },
    .{ .opt = null, .desc = null, .categories = 0 },
};

// ============================================================================
// 2. src/tool_setopt.c
// ============================================================================

pub const NameValue = extern struct {
    name: ?[*:0]const u8,
    value: c_long,
};

pub const NameValueUnsigned = extern struct {
    name: ?[*:0]const u8,
    value: c_ulong,
};

fn nv(comptime name: [*:0]const u8, value: c_long) NameValue {
    return .{ .name = name, .value = value };
}

fn nvu(comptime name: [*:0]const u8, value: c_ulong) NameValueUnsigned {
    return .{ .name = name, .value = value };
}

const NVEND = NameValue{ .name = null, .value = 0 };
const NVUEND = NameValueUnsigned{ .name = null, .value = 0 };

pub export const setopt_nv_CURLPROXY: [8]NameValue = .{
    nv("CURLPROXY_HTTP", CURLPROXY_HTTP),
    nv("CURLPROXY_HTTP_1_0", CURLPROXY_HTTP_1_0),
    nv("CURLPROXY_HTTPS", CURLPROXY_HTTPS),
    nv("CURLPROXY_SOCKS4", CURLPROXY_SOCKS4),
    nv("CURLPROXY_SOCKS5", CURLPROXY_SOCKS5),
    nv("CURLPROXY_SOCKS4A", CURLPROXY_SOCKS4A),
    nv("CURLPROXY_SOCKS5_HOSTNAME", CURLPROXY_SOCKS5_HOSTNAME),
    NVEND,
};

pub export const setopt_nv_CURL_SOCKS_PROXY: [5]NameValue = .{
    nv("CURLPROXY_SOCKS4", CURLPROXY_SOCKS4),
    nv("CURLPROXY_SOCKS5", CURLPROXY_SOCKS5),
    nv("CURLPROXY_SOCKS4A", CURLPROXY_SOCKS4A),
    nv("CURLPROXY_SOCKS5_HOSTNAME", CURLPROXY_SOCKS5_HOSTNAME),
    NVEND,
};

pub export const setopt_nv_CURLHSTS: [2]NameValueUnsigned = .{
    nvu("CURLHSTS_ENABLE", CURLHSTS_ENABLE),
    NVUEND,
};

pub export const setopt_nv_CURLAUTH: [10]NameValueUnsigned = .{
    nvu("CURLAUTH_ANY", CURLAUTH_ANY),
    nvu("CURLAUTH_ANYSAFE", CURLAUTH_ANYSAFE),
    nvu("CURLAUTH_BASIC", CURLAUTH_BASIC),
    nvu("CURLAUTH_DIGEST", CURLAUTH_DIGEST),
    nvu("CURLAUTH_GSSNEGOTIATE", CURLAUTH_GSSNEGOTIATE),
    nvu("CURLAUTH_NTLM", CURLAUTH_NTLM),
    nvu("CURLAUTH_DIGEST_IE", CURLAUTH_DIGEST_IE),
    nvu("CURLAUTH_ONLY", CURLAUTH_ONLY),
    nvu("CURLAUTH_NONE", CURLAUTH_NONE),
    NVUEND,
};

pub export const setopt_nv_CURL_HTTP_VERSION: [8]NameValue = .{
    nv("CURL_HTTP_VERSION_NONE", CURL_HTTP_VERSION_NONE),
    nv("CURL_HTTP_VERSION_1_0", CURL_HTTP_VERSION_1_0),
    nv("CURL_HTTP_VERSION_1_1", CURL_HTTP_VERSION_1_1),
    nv("CURL_HTTP_VERSION_2_0", CURL_HTTP_VERSION_2_0),
    nv("CURL_HTTP_VERSION_2TLS", CURL_HTTP_VERSION_2TLS),
    nv("CURL_HTTP_VERSION_3", CURL_HTTP_VERSION_3),
    nv("CURL_HTTP_VERSION_3ONLY", CURL_HTTP_VERSION_3ONLY),
    NVEND,
};

pub export const setopt_nv_CURL_SSLVERSION: [9]NameValue = .{
    nv("CURL_SSLVERSION_DEFAULT", CURL_SSLVERSION_DEFAULT),
    nv("CURL_SSLVERSION_TLSv1", CURL_SSLVERSION_TLSv1),
    nv("CURL_SSLVERSION_SSLv2", CURL_SSLVERSION_SSLv2),
    nv("CURL_SSLVERSION_SSLv3", CURL_SSLVERSION_SSLv3),
    nv("CURL_SSLVERSION_TLSv1_0", CURL_SSLVERSION_TLSv1_0),
    nv("CURL_SSLVERSION_TLSv1_1", CURL_SSLVERSION_TLSv1_1),
    nv("CURL_SSLVERSION_TLSv1_2", CURL_SSLVERSION_TLSv1_2),
    nv("CURL_SSLVERSION_TLSv1_3", CURL_SSLVERSION_TLSv1_3),
    NVEND,
};

pub export const setopt_nv_CURL_SSLVERSION_MAX: [7]NameValue = .{
    nv("", CURL_SSLVERSION_MAX_NONE),
    nv("CURL_SSLVERSION_MAX_DEFAULT", CURL_SSLVERSION_MAX_DEFAULT),
    nv("CURL_SSLVERSION_MAX_TLSv1_0", CURL_SSLVERSION_MAX_TLSv1_0),
    nv("CURL_SSLVERSION_MAX_TLSv1_1", CURL_SSLVERSION_MAX_TLSv1_1),
    nv("CURL_SSLVERSION_MAX_TLSv1_2", CURL_SSLVERSION_MAX_TLSv1_2),
    nv("CURL_SSLVERSION_MAX_TLSv1_3", CURL_SSLVERSION_MAX_TLSv1_3),
    NVEND,
};

pub export const setopt_nv_CURL_TIMECOND: [5]NameValue = .{
    nv("CURL_TIMECOND_IFMODSINCE", CURL_TIMECOND_IFMODSINCE),
    nv("CURL_TIMECOND_IFUNMODSINCE", CURL_TIMECOND_IFUNMODSINCE),
    nv("CURL_TIMECOND_LASTMOD", CURL_TIMECOND_LASTMOD),
    nv("CURL_TIMECOND_NONE", CURL_TIMECOND_NONE),
    NVEND,
};

pub export const setopt_nv_CURLFTPSSL_CCC: [4]NameValue = .{
    nv("CURLFTPSSL_CCC_NONE", CURLFTPSSL_CCC_NONE),
    nv("CURLFTPSSL_CCC_PASSIVE", CURLFTPSSL_CCC_PASSIVE),
    nv("CURLFTPSSL_CCC_ACTIVE", CURLFTPSSL_CCC_ACTIVE),
    NVEND,
};

pub export const setopt_nv_CURLUSESSL: [5]NameValue = .{
    nv("CURLUSESSL_NONE", CURLUSESSL_NONE),
    nv("CURLUSESSL_TRY", CURLUSESSL_TRY),
    nv("CURLUSESSL_CONTROL", CURLUSESSL_CONTROL),
    nv("CURLUSESSL_ALL", CURLUSESSL_ALL),
    NVEND,
};

pub export const setopt_nv_CURLSSLOPT: [7]NameValueUnsigned = .{
    nvu("CURLSSLOPT_ALLOW_BEAST", CURLSSLOPT_ALLOW_BEAST),
    nvu("CURLSSLOPT_NO_REVOKE", CURLSSLOPT_NO_REVOKE),
    nvu("CURLSSLOPT_NO_PARTIALCHAIN", CURLSSLOPT_NO_PARTIALCHAIN),
    nvu("CURLSSLOPT_REVOKE_BEST_EFFORT", CURLSSLOPT_REVOKE_BEST_EFFORT),
    nvu("CURLSSLOPT_NATIVE_CA", CURLSSLOPT_NATIVE_CA),
    nvu("CURLSSLOPT_AUTO_CLIENT_CERT", CURLSSLOPT_AUTO_CLIENT_CERT),
    NVUEND,
};

pub export const setopt_nv_CURL_NETRC: [4]NameValue = .{
    nv("CURL_NETRC_IGNORED", CURL_NETRC_IGNORED),
    nv("CURL_NETRC_OPTIONAL", CURL_NETRC_OPTIONAL),
    nv("CURL_NETRC_REQUIRED", CURL_NETRC_REQUIRED),
    NVEND,
};

pub export const setopt_nv_CURLOPT_FOLLOWLOCATION: [5]NameValue = .{
    nv("0L", 0),
    nv("CURLFOLLOW_ALL", CURLFOLLOW_ALL),
    nv("CURLFOLLOW_OBEYCODE", CURLFOLLOW_OBEYCODE),
    nv("CURLFOLLOW_FIRSTONLY", CURLFOLLOW_FIRSTONLY),
    NVEND,
};

const setopt_nv_CURLNONZERODEFAULTS: [10]NameValue = .{
    nv("CURLOPT_SSL_VERIFYPEER", 1),
    nv("CURLOPT_SSL_VERIFYHOST", 1),
    nv("CURLOPT_SSL_ENABLE_NPN", 1),
    nv("CURLOPT_SSL_ENABLE_ALPN", 1),
    nv("CURLOPT_TCP_NODELAY", 1),
    nv("CURLOPT_PROXY_SSL_VERIFYPEER", 1),
    nv("CURLOPT_PROXY_SSL_VERIFYHOST", 1),
    nv("CURLOPT_SOCKS5_AUTH", 1),
    nv("CURLOPT_UPLOAD_FLAGS", CURLULFLAG_SEEN),
    NVEND,
};

inline fn libcurlEnabled() bool {
    return globStrPtr(.libcurl).* != null;
}

const MAX_STRING_LENGTH_OUTPUT: curl_off_t = 2000;
const ZERO_TERMINATED: curl_off_t = -1;

fn isPrintAscii(ch: u8) bool {
    return ch >= 0x20 and ch <= 0x7e;
}

fn isXDigitAscii(ch: u8) bool {
    return (ch >= '0' and ch <= '9') or (ch >= 'a' and ch <= 'f') or (ch >= 'A' and ch <= 'F');
}

fn cEscape(str_in: [*:0]const u8, len_in: curl_off_t) ?[*:0]u8 {
    var str: [*]const u8 = str_in;
    var cutoff: usize = 0;
    var escaped: Dynbuf = .{};

    curlx_dyn_init(&escaped, (4 * @as(usize, @intCast(MAX_STRING_LENGTH_OUTPUT))) + 3);

    var len: usize = if (len_in == ZERO_TERMINATED)
        std.mem.len(str_in)
    else
        @intCast(len_in);

    if (len > @as(usize, @intCast(MAX_STRING_LENGTH_OUTPUT))) {
        len = @intCast(MAX_STRING_LENGTH_OUTPUT);
        cutoff = 3;
    }

    var result = curlx_dyn_addn(&escaped, "", 0);
    var s: [*]const u8 = str;
    while (result == CURLE_OK and len > 0) : ({
        s += 1;
        len -= 1;
    }) {
        const ch = s[0];
        const esc_pair: ?*const [2]u8 = switch (ch) {
            '\t' => "\\t",
            '\r' => "\\r",
            '\n' => "\\n",
            '?' => "\\?",
            '"' => "\\\"",
            '\\' => "\\\\",
            else => null,
        };

        if (esc_pair == null and isPrintAscii(ch))
            continue;

        result = curlx_dyn_addn(&escaped, str, @intFromPtr(s) - @intFromPtr(str));
        str = s + 1;

        if (result == CURLE_OK) {
            if (esc_pair) |pair| {
                result = curlx_dyn_addn(&escaped, pair, 2);
            } else {
                const fmt: [*:0]const u8 = if (len > 1 and isXDigitAscii(s[1])) "\\%03o" else "\\x%02x";
                result = curlx_dyn_addf(&escaped, fmt, @as(c_uint, ch));
            }
        }
    }

    if (result == CURLE_OK)
        result = curlx_dyn_addn(&escaped, str, @intFromPtr(s) - @intFromPtr(str));

    if (result == CURLE_OK)
        result = curlx_dyn_addn(&escaped, "...", cutoff);

    if (result != CURLE_OK)
        return null;
    return curlx_dyn_ptr(&escaped);
}

pub export fn tool_setopt_enum(
    curl: ?*CURL,
    name: [*:0]const u8,
    tag: CURLoption,
    nvlist: [*]const NameValue,
    lval: c_long,
) callconv(.c) CURLcode {
    var result: CURLcode = CURLE_OK;
    var skip = false;

    result = curl_easy_setopt(curl, tag, lval);
    if (lval == 0)
        skip = true;

    if (libcurlEnabled() and !skip and result == CURLE_OK) {
        var i: usize = 0;
        while (nvlist[i].name) |nv_name| : (i += 1) {
            if (nvlist[i].value == lval) {
                return easysrc_addf(&easysrc_code, "curl_easy_setopt(curl, %s, (long)%s);", name, nv_name);
            }
        }
        return easysrc_addf(&easysrc_code, "curl_easy_setopt(curl, %s, %ldL);", name, lval);
    }
    return result;
}

pub export fn tool_setopt_SSLVERSION(
    curl: ?*CURL,
    name: [*:0]const u8,
    tag: CURLoption,
    lval: c_long,
) callconv(.c) CURLcode {
    var result: CURLcode = CURLE_OK;
    var skip = false;

    result = curl_easy_setopt(curl, tag, lval);
    if (lval == 0)
        skip = true;

    if (libcurlEnabled() and !skip and result == CURLE_OK) {
        var nv_match: ?[*:0]const u8 = null;
        var nv2_match: ?[*:0]const u8 = null;
        var i: usize = 0;
        while (setopt_nv_CURL_SSLVERSION[i].name) |nv_name| : (i += 1) {
            if (setopt_nv_CURL_SSLVERSION[i].value == (lval & 0xffff)) {
                nv_match = nv_name;
                break;
            }
        }
        var j: usize = 0;
        while (setopt_nv_CURL_SSLVERSION_MAX[j].name) |nv2_name| : (j += 1) {
            if (setopt_nv_CURL_SSLVERSION_MAX[j].value == (lval & ~@as(c_long, 0xffff))) {
                nv2_match = nv2_name;
                break;
            }
        }
        if (nv_match == null) {
            result = easysrc_addf(&easysrc_code, "curl_easy_setopt(curl, %s, %ldL);", name, lval);
        } else {
            if (nv2_match != null and nv2_match.?[0] != 0) {
                result = easysrc_addf(&easysrc_code, "curl_easy_setopt(curl, %s, (long)(%s | %s));", name, nv_match.?, nv2_match.?);
            } else {
                result = easysrc_addf(&easysrc_code, "curl_easy_setopt(curl, %s, (long)%s);", name, nv_match.?);
            }
        }
    }
    return result;
}

pub export fn tool_setopt_bitmask(
    curl: ?*CURL,
    name: [*:0]const u8,
    tag: CURLoption,
    nvlist: [*]const NameValueUnsigned,
    lval: c_long,
) callconv(.c) CURLcode {
    var skip = false;
    var result: CURLcode = curl_easy_setopt(curl, tag, lval);
    if (lval == 0)
        skip = true;

    if (libcurlEnabled() and !skip and result == CURLE_OK) {
        var preamble: [80]u8 = undefined;
        var rest: c_ulong = @bitCast(lval);
        _ = curl_msnprintf(&preamble, preamble.len, "curl_easy_setopt(curl, %s, ", name);
        var i: usize = 0;
        while (nvlist[i].name) |nv_name| : (i += 1) {
            if ((nvlist[i].value & ~rest) == 0) {
                rest &= ~nvlist[i].value;
                result = easysrc_addf(
                    &easysrc_code,
                    "%s(long)%s%s",
                    @as([*:0]const u8, @ptrCast(&preamble)),
                    nv_name,
                    if (rest != 0) " |" else ");",
                );
                if (rest == 0 or result != CURLE_OK)
                    break;
                _ = curl_msnprintf(&preamble, preamble.len, "%*s", @as(c_int, @intCast(std.mem.len(@as([*:0]const u8, @ptrCast(&preamble))))), "");
            }
        }
        if (rest != 0 and result == CURLE_OK)
            result = easysrc_addf(&easysrc_code, "%s%luUL);", @as([*:0]const u8, @ptrCast(&preamble)), rest);
    }
    return result;
}

fn libcurlGenerateSlist(slist: *curl_slist, slistno: *c_int) CURLcode {
    var result: CURLcode = CURLE_OK;

    easysrc_slist_count += 1;
    slistno.* = easysrc_slist_count;

    result = easysrc_addf(&easysrc_decl, "struct curl_slist *slist%d;", slistno.*);
    if (result == CURLE_OK)
        result = easysrc_addf(&easysrc_data, "slist%d = NULL;", slistno.*);
    if (result == CURLE_OK)
        result = easysrc_addf(&easysrc_clean, "curl_slist_free_all(slist%d);", slistno.*);
    if (result == CURLE_OK)
        result = easysrc_addf(&easysrc_clean, "slist%d = NULL;", slistno.*);
    if (result != CURLE_OK)
        return result;

    var cur: ?*curl_slist = slist;
    while (cur != null and result == CURLE_OK) : (cur = cur.?.next) {
        const node = cur.?;
        const data_str: [*:0]const u8 = if (node.data) |d| d else "";
        const escaped = cEscape(data_str, ZERO_TERMINATED) orelse return CURLE_OUT_OF_MEMORY;
        result = easysrc_addf(&easysrc_data, "slist%d = curl_slist_append(slist%d, \"%s\");", slistno.*, slistno.*, escaped);
        c.free(@ptrCast(@constCast(escaped)));
    }

    return result;
}

fn libcurlGenerateMimePart(
    curl: ?*CURL,
    config: *OperationConfig,
    part: *tool_mime,
    mimeno: c_int,
) CURLcode {
    var result: CURLcode = CURLE_OK;
    var submimeno: c_int = 0;
    var filename = part.filename;

    if (part.prev) |prev|
        result = libcurlGenerateMimePart(curl, config, prev, mimeno);

    if (result == CURLE_OK)
        result = easysrc_addf(&easysrc_code, "part%d = curl_mime_addpart(mime%d);", mimeno, mimeno);
    if (result != CURLE_OK)
        return result;

    switch (part.kind) {
        TOOLMIME_PARTS => {
            result = libcurlGenerateMime(curl, config, part, &submimeno);
            if (result == CURLE_OK) {
                result = easysrc_addf(&easysrc_code, "curl_mime_subparts(part%d, mime%d);", mimeno, submimeno);
                if (result == CURLE_OK)
                    result = easysrc_addf(&easysrc_code, "mime%d = NULL;", submimeno);
            }
        },
        TOOLMIME_DATA => {
            if (part.data) |data| {
                const escaped = cEscape(data, ZERO_TERMINATED) orelse return CURLE_OUT_OF_MEMORY;
                result = easysrc_addf(&easysrc_code, "curl_mime_data(part%d, \"%s\", CURL_ZERO_TERMINATED);", mimeno, escaped);
                c.free(@ptrCast(@constCast(escaped)));
            }
        },
        TOOLMIME_FILE, TOOLMIME_FILEDATA => {
            if (part.data) |data| {
                const escaped = cEscape(data, ZERO_TERMINATED) orelse return CURLE_OUT_OF_MEMORY;
                result = easysrc_addf(&easysrc_code, "curl_mime_filedata(part%d, \"%s\");", mimeno, escaped);
                if (part.kind == TOOLMIME_FILEDATA and filename == null and result == CURLE_OK) {
                    result = easysrc_addf(&easysrc_code, "curl_mime_filename(part%d, NULL);", mimeno);
                }
                c.free(@ptrCast(@constCast(escaped)));
            }
        },
        TOOLMIME_STDIN => {
            if (filename == null)
                filename = "-";
            result = easysrc_addf(&easysrc_code, "curl_mime_data_cb(part%d, -1, (curl_read_callback)fread, \\", mimeno);
            if (result == CURLE_OK)
                result = easysrc_addf(&easysrc_code, "                  (curl_seek_callback)fseek, NULL, stdin);");
        },
        TOOLMIME_STDINDATA => {
            result = easysrc_addf(&easysrc_code, "curl_mime_data_cb(part%d, -1, (curl_read_callback)fread, \\", mimeno);
            if (result == CURLE_OK)
                result = easysrc_addf(&easysrc_code, "                  (curl_seek_callback)fseek, NULL, stdin);");
        },
        else => {},
    }

    if (result == CURLE_OK and part.encoder != null) {
        const escaped = cEscape(part.encoder.?, ZERO_TERMINATED) orelse return CURLE_OUT_OF_MEMORY;
        result = easysrc_addf(&easysrc_code, "curl_mime_encoder(part%d, \"%s\");", mimeno, escaped);
        c.free(@ptrCast(@constCast(escaped)));
    }

    if (result == CURLE_OK and filename != null) {
        const escaped = cEscape(filename.?, ZERO_TERMINATED) orelse return CURLE_OUT_OF_MEMORY;
        result = easysrc_addf(&easysrc_code, "curl_mime_filename(part%d, \"%s\");", mimeno, escaped);
        c.free(@ptrCast(@constCast(escaped)));
    }

    if (result == CURLE_OK and part.name != null) {
        const escaped = cEscape(part.name.?, ZERO_TERMINATED) orelse return CURLE_OUT_OF_MEMORY;
        result = easysrc_addf(&easysrc_code, "curl_mime_name(part%d, \"%s\");", mimeno, escaped);
        c.free(@ptrCast(@constCast(escaped)));
    }

    if (result == CURLE_OK and part.type != null) {
        const escaped = cEscape(part.type.?, ZERO_TERMINATED) orelse return CURLE_OUT_OF_MEMORY;
        result = easysrc_addf(&easysrc_code, "curl_mime_type(part%d, \"%s\");", mimeno, escaped);
        c.free(@ptrCast(@constCast(escaped)));
    }

    if (result == CURLE_OK and part.headers != null) {
        var slistno: c_int = 0;
        result = libcurlGenerateSlist(part.headers.?, &slistno);
        if (result == CURLE_OK) {
            result = easysrc_addf(&easysrc_code, "curl_mime_headers(part%d, slist%d, 1);", mimeno, slistno);
            if (result == CURLE_OK)
                result = easysrc_addf(&easysrc_code, "slist%d = NULL;", slistno);
        }
    }

    return result;
}

fn libcurlGenerateMime(
    curl: ?*CURL,
    config: *OperationConfig,
    toolmime: *tool_mime,
    mimeno: *c_int,
) CURLcode {
    var result: CURLcode = CURLE_OK;

    easysrc_mime_count += 1;
    mimeno.* = easysrc_mime_count;

    result = easysrc_addf(&easysrc_decl, "curl_mime *mime%d;", mimeno.*);
    if (result == CURLE_OK)
        result = easysrc_addf(&easysrc_data, "mime%d = NULL;", mimeno.*);
    if (result == CURLE_OK)
        result = easysrc_addf(&easysrc_code, "mime%d = curl_mime_init(curl);", mimeno.*);
    if (result == CURLE_OK)
        result = easysrc_addf(&easysrc_clean, "curl_mime_free(mime%d);", mimeno.*);
    if (result == CURLE_OK)
        result = easysrc_addf(&easysrc_clean, "mime%d = NULL;", mimeno.*);

    if (toolmime.subparts != null and result == CURLE_OK) {
        result = easysrc_addf(&easysrc_decl, "curl_mimepart *part%d;", mimeno.*);
        if (result == CURLE_OK)
            result = libcurlGenerateMimePart(curl, config, toolmime.subparts.?, mimeno.*);
    }

    return result;
}

pub export fn tool_setopt_mimepost(
    curl: ?*CURL,
    config: *OperationConfig,
    name: [*:0]const u8,
    tag: CURLoption,
    mimepost: ?*curl_mime,
) callconv(.c) CURLcode {
    var result = curl_easy_setopt(curl, tag, mimepost);
    var mimeno: c_int = 0;

    if (result == CURLE_OK and libcurlEnabled()) {
        if (tool_zig_config_mimeroot_ptr(config).*) |mimeroot| {
            result = libcurlGenerateMime(curl, config, mimeroot, &mimeno);
            if (result == CURLE_OK)
                result = easysrc_addf(&easysrc_code, "curl_easy_setopt(curl, %s, mime%d);", name, mimeno);
        }
    }
    return result;
}

pub export fn tool_setopt_slist(
    curl: ?*CURL,
    name: [*:0]const u8,
    tag: CURLoption,
    list: ?*curl_slist,
) callconv(.c) CURLcode {
    var result: CURLcode = CURLE_OK;

    result = curl_easy_setopt(curl, tag, list);

    if (libcurlEnabled() and list != null and result == CURLE_OK) {
        var i: c_int = 0;
        result = libcurlGenerateSlist(list.?, &i);
        if (result == CURLE_OK)
            result = easysrc_addf(&easysrc_code, "curl_easy_setopt(curl, %s, slist%d);", name, i);
    }
    return result;
}

pub export fn tool_setopt_long(
    curl: ?*CURL,
    name: [*:0]const u8,
    tag: CURLoption,
    lval: c_long,
) callconv(.c) CURLcode {
    var result: CURLcode = CURLE_OK;

    result = curl_easy_setopt(curl, tag, lval);
    if (result == CURLE_OK and libcurlEnabled()) {
        var defval: c_long = 0;
        var i: usize = 0;
        const name_slice = std.mem.span(name);
        while (setopt_nv_CURLNONZERODEFAULTS[i].name) |nv_name| : (i += 1) {
            if (std.mem.eql(u8, name_slice, std.mem.span(nv_name))) {
                defval = setopt_nv_CURLNONZERODEFAULTS[i].value;
                break;
            }
        }
        if (lval != defval) {
            result = easysrc_addf(&easysrc_code, "curl_easy_setopt(curl, %s, %ldL);", name, lval);
        }
    }
    return result;
}

pub export fn tool_setopt_long_force(
    curl: ?*CURL,
    name: [*:0]const u8,
    tag: CURLoption,
    lval: c_long,
) callconv(.c) CURLcode {
    var result: CURLcode = curl_easy_setopt(curl, tag, lval);
    if (libcurlEnabled() and result == CURLE_OK and (!easysrc_is_first() or lval == 0))
        result = easysrc_addf(&easysrc_code, "curl_easy_setopt(curl, %s, %ldL);", name, lval);
    return result;
}

pub export fn tool_setopt_offt(
    curl: ?*CURL,
    name: [*:0]const u8,
    tag: CURLoption,
    lval: curl_off_t,
) callconv(.c) CURLcode {
    var result: CURLcode = CURLE_OK;

    result = curl_easy_setopt(curl, tag, lval);
    if (libcurlEnabled() and result == CURLE_OK and lval != 0) {
        var buf: [32]u8 = undefined;
        const slice = std.fmt.bufPrint(buf[0 .. buf.len - 1], "{d}", .{lval}) catch "0";
        buf[slice.len] = 0;
        const formatted: [*:0]const u8 = @ptrCast(&buf);
        result = easysrc_addf(&easysrc_code, "curl_easy_setopt(curl, %s, (curl_off_t)%s);", name, formatted);
    }
    return result;
}

const use_c_vastart = switch (builtin.cpu.arch) {
    .x86_64 => builtin.os.tag != .windows,
    .aarch64, .aarch64_be => builtin.os.tag.isDarwin(),
    else => false,
};

fn toolSetoptPtrImpl(curl: ?*CURL, name: [*:0]const u8, tag: CURLoption, pval: ?*anyopaque) CURLcode {
    var result = curl_easy_setopt(curl, tag, pval);
    if (libcurlEnabled() and pval != null and result == CURLE_OK) {
        const remark: [*:0]const u8 = if (tag >= CURLOPTTYPE_FUNCTIONPOINT) "function" else "object";
        const suffix: [*:0]const u8 = if (remark[0] == 'o') "n" else "";
        result = easysrc_addf(&easysrc_toohard, "%s was set to a%s %s pointer", name, suffix, remark);
    }
    return result;
}

const ToolSetoptPtrExports = if (use_c_vastart) struct {
    fn tool_setopt_ptr(curl: ?*CURL, name: [*:0]const u8, tag: CURLoption, ...) callconv(.c) CURLcode {
        var ap = @cVaStart();
        defer @cVaEnd(&ap);
        const pval = @cVaArg(&ap, ?*anyopaque);
        return toolSetoptPtrImpl(curl, name, tag, pval);
    }
} else struct {
    fn tool_setopt_ptr(curl: ?*CURL, name: [*:0]const u8, tag: CURLoption, pval: ?*anyopaque) callconv(.c) CURLcode {
        return toolSetoptPtrImpl(curl, name, tag, pval);
    }
};

comptime {
    @export(&ToolSetoptPtrExports.tool_setopt_ptr, .{ .name = "tool_setopt_ptr", .linkage = .strong });
}

pub export fn tool_setopt_str(
    curl: ?*CURL,
    config: *OperationConfig,
    name: [*:0]const u8,
    tag: CURLoption,
    value: ?[*:0]const u8,
) callconv(.c) CURLcode {
    var result: CURLcode = curl_easy_setopt(curl, tag, value);
    if (libcurlEnabled() and value != null and result == CURLE_OK) {
        const len: curl_off_t = if (tag == CURLOPT_POSTFIELDS)
            @intCast(curlx_dyn_len(tool_zig_config_postdata_ptr(config)))
        else
            ZERO_TERMINATED;
        const escaped = cEscape(value.?, len);
        if (escaped) |esc| {
            result = easysrc_addf(&easysrc_code, "curl_easy_setopt(curl, %s, \"%s\");", name, esc);
            c.free(@ptrCast(@constCast(esc)));
        } else {
            result = CURLE_OUT_OF_MEMORY;
        }
    }
    return result;
}

// ============================================================================
// 3. src/tool_getparam.c
// ============================================================================

fn getstr(str: *?[*:0]u8, val: ?[*:0]const u8, allowblank: bool) ParameterError {
    if (str.*) |p| {
        c.free(p);
        str.* = null;
    }
    const v = val orelse return PARAM_BLANK_STRING;
    if (!allowblank and v[0] == 0)
        return PARAM_BLANK_STRING;
    str.* = cStrdup(v);
    if (str.* == null)
        return PARAM_NO_MEM;
    return PARAM_OK;
}

fn getstrn(str: *?[*:0]u8, val: ?[*]const u8, len: usize, allowblank: bool) ParameterError {
    if (str.*) |p| {
        c.free(p);
        str.* = null;
    }
    const v = val orelse return PARAM_BLANK_STRING;
    if (!allowblank and (len == 0 or v[0] == 0))
        return PARAM_BLANK_STRING;
    str.* = cDup0(v, len);
    if (str.* == null)
        return PARAM_NO_MEM;
    return PARAM_OK;
}

pub const cmdline_t = c_uint;
pub const C_ABSTRACT_UNIX_SOCKET: cmdline_t = 0;
pub const C_ALPN: cmdline_t = 1;
pub const C_ALT_SVC: cmdline_t = 2;
pub const C_ANYAUTH: cmdline_t = 3;
pub const C_APPEND: cmdline_t = 4;
pub const C_AWS_SIGV4: cmdline_t = 5;
pub const C_BASIC: cmdline_t = 6;
pub const C_BUFFER: cmdline_t = 7;
pub const C_CA_NATIVE: cmdline_t = 8;
pub const C_CACERT: cmdline_t = 9;
pub const C_CAPATH: cmdline_t = 10;
pub const C_CERT: cmdline_t = 11;
pub const C_CERT_STATUS: cmdline_t = 12;
pub const C_CERT_TYPE: cmdline_t = 13;
pub const C_CIPHERS: cmdline_t = 14;
pub const C_CLOBBER: cmdline_t = 15;
pub const C_COMPRESSED: cmdline_t = 16;
pub const C_COMPRESSED_SSH: cmdline_t = 17;
pub const C_CONFIG: cmdline_t = 18;
pub const C_CONNECT_TIMEOUT: cmdline_t = 19;
pub const C_CONNECT_TO: cmdline_t = 20;
pub const C_CONTINUE_AT: cmdline_t = 21;
pub const C_COOKIE: cmdline_t = 22;
pub const C_COOKIE_JAR: cmdline_t = 23;
pub const C_CREATE_DIRS: cmdline_t = 24;
pub const C_CREATE_FILE_MODE: cmdline_t = 25;
pub const C_CRLF: cmdline_t = 26;
pub const C_CRLFILE: cmdline_t = 27;
pub const C_CURVES: cmdline_t = 28;
pub const C_DATA: cmdline_t = 29;
pub const C_DATA_ASCII: cmdline_t = 30;
pub const C_DATA_BINARY: cmdline_t = 31;
pub const C_DATA_RAW: cmdline_t = 32;
pub const C_DATA_URLENCODE: cmdline_t = 33;
pub const C_DELEGATION: cmdline_t = 34;
pub const C_DIGEST: cmdline_t = 35;
pub const C_DISABLE: cmdline_t = 36;
pub const C_DISABLE_EPRT: cmdline_t = 37;
pub const C_DISABLE_EPSV: cmdline_t = 38;
pub const C_DISALLOW_USERNAME_IN_URL: cmdline_t = 39;
pub const C_DNS_INTERFACE: cmdline_t = 40;
pub const C_DNS_IPV4_ADDR: cmdline_t = 41;
pub const C_DNS_IPV6_ADDR: cmdline_t = 42;
pub const C_DNS_SERVERS: cmdline_t = 43;
pub const C_DOH_CERT_STATUS: cmdline_t = 44;
pub const C_DOH_INSECURE: cmdline_t = 45;
pub const C_DOH_URL: cmdline_t = 46;
pub const C_DUMP_CA_EMBED: cmdline_t = 47;
pub const C_DUMP_HEADER: cmdline_t = 48;
pub const C_ECH: cmdline_t = 49;
pub const C_EGD_FILE: cmdline_t = 50;
pub const C_ENGINE: cmdline_t = 51;
pub const C_EPRT: cmdline_t = 52;
pub const C_EPSV: cmdline_t = 53;
pub const C_ETAG_COMPARE: cmdline_t = 54;
pub const C_ETAG_SAVE: cmdline_t = 55;
pub const C_EXPECT100_TIMEOUT: cmdline_t = 56;
pub const C_FAIL: cmdline_t = 57;
pub const C_FAIL_EARLY: cmdline_t = 58;
pub const C_FAIL_WITH_BODY: cmdline_t = 59;
pub const C_FALSE_START: cmdline_t = 60;
pub const C_FOLLOW: cmdline_t = 61;
pub const C_FORM: cmdline_t = 62;
pub const C_FORM_ESCAPE: cmdline_t = 63;
pub const C_FORM_STRING: cmdline_t = 64;
pub const C_FTP_ACCOUNT: cmdline_t = 65;
pub const C_FTP_ALTERNATIVE_TO_USER: cmdline_t = 66;
pub const C_FTP_CREATE_DIRS: cmdline_t = 67;
pub const C_FTP_METHOD: cmdline_t = 68;
pub const C_FTP_PASV: cmdline_t = 69;
pub const C_FTP_PORT: cmdline_t = 70;
pub const C_FTP_PRET: cmdline_t = 71;
pub const C_FTP_SKIP_PASV_IP: cmdline_t = 72;
pub const C_FTP_SSL: cmdline_t = 73;
pub const C_FTP_SSL_CCC: cmdline_t = 74;
pub const C_FTP_SSL_CCC_MODE: cmdline_t = 75;
pub const C_FTP_SSL_CONTROL: cmdline_t = 76;
pub const C_FTP_SSL_REQD: cmdline_t = 77;
pub const C_GET: cmdline_t = 78;
pub const C_GLOBOFF: cmdline_t = 79;
pub const C_HAPPY_EYEBALLS_TIMEOUT_MS: cmdline_t = 80;
pub const C_HAPROXY_CLIENTIP: cmdline_t = 81;
pub const C_HAPROXY_PROTOCOL: cmdline_t = 82;
pub const C_HEAD: cmdline_t = 83;
pub const C_HEADER: cmdline_t = 84;
pub const C_HELP: cmdline_t = 85;
pub const C_HOSTPUBMD5: cmdline_t = 86;
pub const C_HOSTPUBSHA256: cmdline_t = 87;
pub const C_HSTS: cmdline_t = 88;
pub const C_HTTP0_9: cmdline_t = 89;
pub const C_HTTP1_0: cmdline_t = 90;
pub const C_HTTP1_1: cmdline_t = 91;
pub const C_HTTP2: cmdline_t = 92;
pub const C_HTTP2_PRIOR_KNOWLEDGE: cmdline_t = 93;
pub const C_HTTP3: cmdline_t = 94;
pub const C_HTTP3_ONLY: cmdline_t = 95;
pub const C_HTTPSIG_ALGORITHM: cmdline_t = 96;
pub const C_HTTPSIG_HEADERS: cmdline_t = 97;
pub const C_HTTPSIG_KEY: cmdline_t = 98;
pub const C_HTTPSIG_KEYID: cmdline_t = 99;
pub const C_IGNORE_CONTENT_LENGTH: cmdline_t = 100;
pub const C_INCLUDE: cmdline_t = 101;
pub const C_INSECURE: cmdline_t = 102;
pub const C_INTERFACE: cmdline_t = 103;
pub const C_IPFS_GATEWAY: cmdline_t = 104;
pub const C_IPV4: cmdline_t = 105;
pub const C_IPV6: cmdline_t = 106;
pub const C_JSON: cmdline_t = 107;
pub const C_JUNK_SESSION_COOKIES: cmdline_t = 108;
pub const C_KEEPALIVE: cmdline_t = 109;
pub const C_KEEPALIVE_CNT: cmdline_t = 110;
pub const C_KEEPALIVE_TIME: cmdline_t = 111;
pub const C_KEY: cmdline_t = 112;
pub const C_KEY_TYPE: cmdline_t = 113;
pub const C_KNOWNHOSTS: cmdline_t = 114;
pub const C_KRB: cmdline_t = 115;
pub const C_KRB4: cmdline_t = 116;
pub const C_LIBCURL: cmdline_t = 117;
pub const C_LIMIT_RATE: cmdline_t = 118;
pub const C_LIST_ONLY: cmdline_t = 119;
pub const C_LOCAL_PORT: cmdline_t = 120;
pub const C_LOCATION: cmdline_t = 121;
pub const C_LOCATION_TRUSTED: cmdline_t = 122;
pub const C_LOGIN_OPTIONS: cmdline_t = 123;
pub const C_MAIL_AUTH: cmdline_t = 124;
pub const C_MAIL_FROM: cmdline_t = 125;
pub const C_MAIL_RCPT: cmdline_t = 126;
pub const C_MAIL_RCPT_ALLOWFAILS: cmdline_t = 127;
pub const C_MANUAL: cmdline_t = 128;
pub const C_MAX_FILESIZE: cmdline_t = 129;
pub const C_MAX_REDIRS: cmdline_t = 130;
pub const C_MAX_TIME: cmdline_t = 131;
pub const C_METALINK: cmdline_t = 132;
pub const C_MPTCP: cmdline_t = 133;
pub const C_NEGOTIATE: cmdline_t = 134;
pub const C_NETRC: cmdline_t = 135;
pub const C_NETRC_FILE: cmdline_t = 136;
pub const C_NETRC_OPTIONAL: cmdline_t = 137;
pub const C_NEXT: cmdline_t = 138;
pub const C_NOPROXY: cmdline_t = 139;
pub const C_NPN: cmdline_t = 140;
pub const C_NTLM: cmdline_t = 141;
pub const C_NTLM_WB: cmdline_t = 142;
pub const C_OAUTH2_BEARER: cmdline_t = 143;
pub const C_OUT_NULL: cmdline_t = 144;
pub const C_OUTPUT: cmdline_t = 145;
pub const C_OUTPUT_DIR: cmdline_t = 146;
pub const C_PARALLEL: cmdline_t = 147;
pub const C_PARALLEL_HOST: cmdline_t = 148;
pub const C_PARALLEL_IMMEDIATE: cmdline_t = 149;
pub const C_PARALLEL_MAX: cmdline_t = 150;
pub const C_PASS: cmdline_t = 151;
pub const C_PATH_AS_IS: cmdline_t = 152;
pub const C_PINNEDPUBKEY: cmdline_t = 153;
pub const C_POST301: cmdline_t = 154;
pub const C_POST302: cmdline_t = 155;
pub const C_POST303: cmdline_t = 156;
pub const C_PREPROXY: cmdline_t = 157;
pub const C_PROGRESS_BAR: cmdline_t = 158;
pub const C_PROGRESS_METER: cmdline_t = 159;
pub const C_PROTO: cmdline_t = 160;
pub const C_PROTO_DEFAULT: cmdline_t = 161;
pub const C_PROTO_REDIR: cmdline_t = 162;
pub const C_PROXY: cmdline_t = 163;
pub const C_PROXY_ANYAUTH: cmdline_t = 164;
pub const C_PROXY_BASIC: cmdline_t = 165;
pub const C_PROXY_CA_NATIVE: cmdline_t = 166;
pub const C_PROXY_CACERT: cmdline_t = 167;
pub const C_PROXY_CAPATH: cmdline_t = 168;
pub const C_PROXY_CERT: cmdline_t = 169;
pub const C_PROXY_CERT_TYPE: cmdline_t = 170;
pub const C_PROXY_CIPHERS: cmdline_t = 171;
pub const C_PROXY_CRLFILE: cmdline_t = 172;
pub const C_PROXY_DIGEST: cmdline_t = 173;
pub const C_PROXY_HEADER: cmdline_t = 174;
pub const C_PROXY_HTTP2: cmdline_t = 175;
pub const C_PROXY_HTTP3: cmdline_t = 176;
pub const C_PROXY_INSECURE: cmdline_t = 177;
pub const C_PROXY_KEY: cmdline_t = 178;
pub const C_PROXY_KEY_TYPE: cmdline_t = 179;
pub const C_PROXY_NEGOTIATE: cmdline_t = 180;
pub const C_PROXY_NTLM: cmdline_t = 181;
pub const C_PROXY_PASS: cmdline_t = 182;
pub const C_PROXY_PINNEDPUBKEY: cmdline_t = 183;
pub const C_PROXY_SERVICE_NAME: cmdline_t = 184;
pub const C_PROXY_SSL_ALLOW_BEAST: cmdline_t = 185;
pub const C_PROXY_SSL_AUTO_CLIENT_CERT: cmdline_t = 186;
pub const C_PROXY_TLS13_CIPHERS: cmdline_t = 187;
pub const C_PROXY_TLSAUTHTYPE: cmdline_t = 188;
pub const C_PROXY_TLSPASSWORD: cmdline_t = 189;
pub const C_PROXY_TLSUSER: cmdline_t = 190;
pub const C_PROXY_TLSV1: cmdline_t = 191;
pub const C_PROXY_USER: cmdline_t = 192;
pub const C_PROXY1_0: cmdline_t = 193;
pub const C_PROXYTUNNEL: cmdline_t = 194;
pub const C_PUBKEY: cmdline_t = 195;
pub const C_QUOTE: cmdline_t = 196;
pub const C_RANDOM_FILE: cmdline_t = 197;
pub const C_RANGE: cmdline_t = 198;
pub const C_RATE: cmdline_t = 199;
pub const C_RAW: cmdline_t = 200;
pub const C_REFERER: cmdline_t = 201;
pub const C_REMOTE_HEADER_NAME: cmdline_t = 202;
pub const C_REMOTE_NAME: cmdline_t = 203;
pub const C_REMOTE_NAME_ALL: cmdline_t = 204;
pub const C_REMOTE_TIME: cmdline_t = 205;
pub const C_REMOVE_ON_ERROR: cmdline_t = 206;
pub const C_REQUEST: cmdline_t = 207;
pub const C_REQUEST_TARGET: cmdline_t = 208;
pub const C_RESOLVE: cmdline_t = 209;
pub const C_RETRY: cmdline_t = 210;
pub const C_RETRY_ALL_ERRORS: cmdline_t = 211;
pub const C_RETRY_CONNREFUSED: cmdline_t = 212;
pub const C_RETRY_DELAY: cmdline_t = 213;
pub const C_RETRY_MAX_TIME: cmdline_t = 214;
pub const C_SASL_AUTHZID: cmdline_t = 215;
pub const C_SASL_IR: cmdline_t = 216;
pub const C_SERVICE_NAME: cmdline_t = 217;
pub const C_SESSIONID: cmdline_t = 218;
pub const C_SHOW_ERROR: cmdline_t = 219;
pub const C_SHOW_HEADERS: cmdline_t = 220;
pub const C_SILENT: cmdline_t = 221;
pub const C_SIGNATURE_ALGORITHMS: cmdline_t = 222;
pub const C_SKIP_EXISTING: cmdline_t = 223;
pub const C_SOCKS4: cmdline_t = 224;
pub const C_SOCKS4A: cmdline_t = 225;
pub const C_SOCKS5: cmdline_t = 226;
pub const C_SOCKS5_BASIC: cmdline_t = 227;
pub const C_SOCKS5_GSSAPI: cmdline_t = 228;
pub const C_SOCKS5_GSSAPI_NEC: cmdline_t = 229;
pub const C_SOCKS5_GSSAPI_SERVICE: cmdline_t = 230;
pub const C_SOCKS5_HOSTNAME: cmdline_t = 231;
pub const C_SPEED_LIMIT: cmdline_t = 232;
pub const C_SPEED_TIME: cmdline_t = 233;
pub const C_SSL: cmdline_t = 234;
pub const C_SSL_ALLOW_BEAST: cmdline_t = 235;
pub const C_SSL_AUTO_CLIENT_CERT: cmdline_t = 236;
pub const C_SSL_NO_REVOKE: cmdline_t = 237;
pub const C_SSL_REQD: cmdline_t = 238;
pub const C_SSL_REVOKE_BEST_EFFORT: cmdline_t = 239;
pub const C_SSL_SESSIONS: cmdline_t = 240;
pub const C_SSLV2: cmdline_t = 241;
pub const C_SSLV3: cmdline_t = 242;
pub const C_STDERR: cmdline_t = 243;
pub const C_STYLED_OUTPUT: cmdline_t = 244;
pub const C_SUPPRESS_CONNECT_HEADERS: cmdline_t = 245;
pub const C_TCP_FASTOPEN: cmdline_t = 246;
pub const C_TCP_NODELAY: cmdline_t = 247;
pub const C_TELNET_OPTION: cmdline_t = 248;
pub const C_TEST_DUPHANDLE: cmdline_t = 249;
pub const C_TEST_EVENT: cmdline_t = 250;
pub const C_TFTP_BLKSIZE: cmdline_t = 251;
pub const C_TFTP_NO_OPTIONS: cmdline_t = 252;
pub const C_TIME_COND: cmdline_t = 253;
pub const C_TLS_EARLYDATA: cmdline_t = 254;
pub const C_TLS_MAX: cmdline_t = 255;
pub const C_TLS13_CIPHERS: cmdline_t = 256;
pub const C_TLSAUTHTYPE: cmdline_t = 257;
pub const C_TLSPASSWORD: cmdline_t = 258;
pub const C_TLSUSER: cmdline_t = 259;
pub const C_TLSV1: cmdline_t = 260;
pub const C_TLSV1_0: cmdline_t = 261;
pub const C_TLSV1_1: cmdline_t = 262;
pub const C_TLSV1_2: cmdline_t = 263;
pub const C_TLSV1_3: cmdline_t = 264;
pub const C_TR_ENCODING: cmdline_t = 265;
pub const C_TRACE: cmdline_t = 266;
pub const C_TRACE_ASCII: cmdline_t = 267;
pub const C_TRACE_CONFIG: cmdline_t = 268;
pub const C_TRACE_IDS: cmdline_t = 269;
pub const C_TRACE_TIME: cmdline_t = 270;
pub const C_IP_TOS: cmdline_t = 271;
pub const C_UNIX_SOCKET: cmdline_t = 272;
pub const C_UPLOAD_FILE: cmdline_t = 273;
pub const C_UPLOAD_FLAGS: cmdline_t = 274;
pub const C_URL: cmdline_t = 275;
pub const C_URL_QUERY: cmdline_t = 276;
pub const C_USE_ASCII: cmdline_t = 277;
pub const C_USER: cmdline_t = 278;
pub const C_USER_AGENT: cmdline_t = 279;
pub const C_VARIABLE: cmdline_t = 280;
pub const C_VERBOSE: cmdline_t = 281;
pub const C_VERSION: cmdline_t = 282;
pub const C_VLAN_PRIORITY: cmdline_t = 283;
pub const C_WDEBUG: cmdline_t = 284;
pub const C_WRITE_OUT: cmdline_t = 285;
pub const C_XATTR: cmdline_t = 286;

pub const ARG_NONE: u8 = 0x0;
pub const ARG_BOOL: u8 = 0x1;
pub const ARG_STRG: u8 = 0x2;
pub const ARG_FILE: u8 = 0x3;
pub const ARG_SECS: u8 = 0x4;
pub const ARG_UNUM: u8 = 0x5;
pub const ARG_TYPEMASK: u8 = 0x0f;

pub const ARG_NO: u8 = 1 << 4;
pub const ARG_DEPR: u8 = 1 << 5;
pub const ARG_CLEAR: u8 = 1 << 6;
pub const ARG_TLS: u8 = 1 << 7;

inline fn argType(x: u8) u8 {
    return x & ARG_TYPEMASK;
}

pub const LongShort = extern struct {
    lname: [*:0]const u8,
    desc: u8,
    letter: u8,
    cmd: cmdline_t,
};

const aliases: [284]LongShort = .{
    .{ .lname = "abstract-unix-socket", .desc = ARG_FILE, .letter = ' ', .cmd = C_ABSTRACT_UNIX_SOCKET },
    .{ .lname = "alpn", .desc = ARG_BOOL | ARG_NO | ARG_TLS, .letter = ' ', .cmd = C_ALPN },
    .{ .lname = "alt-svc", .desc = ARG_STRG, .letter = ' ', .cmd = C_ALT_SVC },
    .{ .lname = "anyauth", .desc = ARG_NONE, .letter = ' ', .cmd = C_ANYAUTH },
    .{ .lname = "append", .desc = ARG_BOOL, .letter = 'a', .cmd = C_APPEND },
    .{ .lname = "aws-sigv4", .desc = ARG_STRG, .letter = ' ', .cmd = C_AWS_SIGV4 },
    .{ .lname = "basic", .desc = ARG_BOOL, .letter = ' ', .cmd = C_BASIC },
    .{ .lname = "buffer", .desc = ARG_BOOL | ARG_NO, .letter = 'N', .cmd = C_BUFFER },
    .{ .lname = "ca-native", .desc = ARG_BOOL | ARG_TLS, .letter = ' ', .cmd = C_CA_NATIVE },
    .{ .lname = "cacert", .desc = ARG_FILE | ARG_TLS, .letter = ' ', .cmd = C_CACERT },
    .{ .lname = "capath", .desc = ARG_FILE | ARG_TLS, .letter = ' ', .cmd = C_CAPATH },
    .{ .lname = "cert", .desc = ARG_FILE | ARG_TLS | ARG_CLEAR, .letter = 'E', .cmd = C_CERT },
    .{ .lname = "cert-status", .desc = ARG_BOOL | ARG_TLS, .letter = ' ', .cmd = C_CERT_STATUS },
    .{ .lname = "cert-type", .desc = ARG_STRG | ARG_TLS, .letter = ' ', .cmd = C_CERT_TYPE },
    .{ .lname = "ciphers", .desc = ARG_STRG | ARG_TLS, .letter = ' ', .cmd = C_CIPHERS },
    .{ .lname = "clobber", .desc = ARG_BOOL | ARG_NO, .letter = ' ', .cmd = C_CLOBBER },
    .{ .lname = "compressed", .desc = ARG_BOOL, .letter = ' ', .cmd = C_COMPRESSED },
    .{ .lname = "compressed-ssh", .desc = ARG_BOOL, .letter = ' ', .cmd = C_COMPRESSED_SSH },
    .{ .lname = "config", .desc = ARG_FILE, .letter = 'K', .cmd = C_CONFIG },
    .{ .lname = "connect-timeout", .desc = ARG_SECS, .letter = ' ', .cmd = C_CONNECT_TIMEOUT },
    .{ .lname = "connect-to", .desc = ARG_STRG, .letter = ' ', .cmd = C_CONNECT_TO },
    .{ .lname = "continue-at", .desc = ARG_STRG, .letter = 'C', .cmd = C_CONTINUE_AT },
    .{ .lname = "cookie", .desc = ARG_STRG, .letter = 'b', .cmd = C_COOKIE },
    .{ .lname = "cookie-jar", .desc = ARG_STRG, .letter = 'c', .cmd = C_COOKIE_JAR },
    .{ .lname = "create-dirs", .desc = ARG_BOOL, .letter = ' ', .cmd = C_CREATE_DIRS },
    .{ .lname = "create-file-mode", .desc = ARG_STRG, .letter = ' ', .cmd = C_CREATE_FILE_MODE },
    .{ .lname = "crlf", .desc = ARG_BOOL, .letter = ' ', .cmd = C_CRLF },
    .{ .lname = "crlfile", .desc = ARG_FILE | ARG_TLS, .letter = ' ', .cmd = C_CRLFILE },
    .{ .lname = "curves", .desc = ARG_STRG | ARG_TLS, .letter = ' ', .cmd = C_CURVES },
    .{ .lname = "data", .desc = ARG_STRG, .letter = 'd', .cmd = C_DATA },
    .{ .lname = "data-ascii", .desc = ARG_STRG, .letter = ' ', .cmd = C_DATA_ASCII },
    .{ .lname = "data-binary", .desc = ARG_STRG, .letter = ' ', .cmd = C_DATA_BINARY },
    .{ .lname = "data-raw", .desc = ARG_STRG, .letter = ' ', .cmd = C_DATA_RAW },
    .{ .lname = "data-urlencode", .desc = ARG_STRG, .letter = ' ', .cmd = C_DATA_URLENCODE },
    .{ .lname = "delegation", .desc = ARG_STRG, .letter = ' ', .cmd = C_DELEGATION },
    .{ .lname = "digest", .desc = ARG_BOOL, .letter = ' ', .cmd = C_DIGEST },
    .{ .lname = "disable", .desc = ARG_BOOL, .letter = 'q', .cmd = C_DISABLE },
    .{ .lname = "disable-eprt", .desc = ARG_BOOL, .letter = ' ', .cmd = C_DISABLE_EPRT },
    .{ .lname = "disable-epsv", .desc = ARG_BOOL, .letter = ' ', .cmd = C_DISABLE_EPSV },
    .{ .lname = "disallow-username-in-url", .desc = ARG_BOOL, .letter = ' ', .cmd = C_DISALLOW_USERNAME_IN_URL },
    .{ .lname = "dns-interface", .desc = ARG_STRG, .letter = ' ', .cmd = C_DNS_INTERFACE },
    .{ .lname = "dns-ipv4-addr", .desc = ARG_STRG, .letter = ' ', .cmd = C_DNS_IPV4_ADDR },
    .{ .lname = "dns-ipv6-addr", .desc = ARG_STRG, .letter = ' ', .cmd = C_DNS_IPV6_ADDR },
    .{ .lname = "dns-servers", .desc = ARG_STRG, .letter = ' ', .cmd = C_DNS_SERVERS },
    .{ .lname = "doh-cert-status", .desc = ARG_BOOL | ARG_TLS, .letter = ' ', .cmd = C_DOH_CERT_STATUS },
    .{ .lname = "doh-insecure", .desc = ARG_BOOL | ARG_TLS, .letter = ' ', .cmd = C_DOH_INSECURE },
    .{ .lname = "doh-url", .desc = ARG_STRG, .letter = ' ', .cmd = C_DOH_URL },
    .{ .lname = "dump-ca-embed", .desc = ARG_NONE | ARG_TLS, .letter = ' ', .cmd = C_DUMP_CA_EMBED },
    .{ .lname = "dump-header", .desc = ARG_FILE, .letter = 'D', .cmd = C_DUMP_HEADER },
    .{ .lname = "ech", .desc = ARG_STRG | ARG_TLS, .letter = ' ', .cmd = C_ECH },
    .{ .lname = "egd-file", .desc = ARG_STRG | ARG_DEPR, .letter = ' ', .cmd = C_EGD_FILE },
    .{ .lname = "engine", .desc = ARG_STRG | ARG_TLS, .letter = ' ', .cmd = C_ENGINE },
    .{ .lname = "eprt", .desc = ARG_BOOL, .letter = ' ', .cmd = C_EPRT },
    .{ .lname = "epsv", .desc = ARG_BOOL, .letter = ' ', .cmd = C_EPSV },
    .{ .lname = "etag-compare", .desc = ARG_FILE, .letter = ' ', .cmd = C_ETAG_COMPARE },
    .{ .lname = "etag-save", .desc = ARG_FILE, .letter = ' ', .cmd = C_ETAG_SAVE },
    .{ .lname = "expect100-timeout", .desc = ARG_SECS, .letter = ' ', .cmd = C_EXPECT100_TIMEOUT },
    .{ .lname = "fail", .desc = ARG_BOOL, .letter = 'f', .cmd = C_FAIL },
    .{ .lname = "fail-early", .desc = ARG_BOOL, .letter = ' ', .cmd = C_FAIL_EARLY },
    .{ .lname = "fail-with-body", .desc = ARG_BOOL, .letter = ' ', .cmd = C_FAIL_WITH_BODY },
    .{ .lname = "false-start", .desc = ARG_BOOL, .letter = ' ', .cmd = C_FALSE_START },
    .{ .lname = "follow", .desc = ARG_BOOL, .letter = ' ', .cmd = C_FOLLOW },
    .{ .lname = "form", .desc = ARG_STRG, .letter = 'F', .cmd = C_FORM },
    .{ .lname = "form-escape", .desc = ARG_BOOL, .letter = ' ', .cmd = C_FORM_ESCAPE },
    .{ .lname = "form-string", .desc = ARG_STRG, .letter = ' ', .cmd = C_FORM_STRING },
    .{ .lname = "ftp-account", .desc = ARG_STRG, .letter = ' ', .cmd = C_FTP_ACCOUNT },
    .{ .lname = "ftp-alternative-to-user", .desc = ARG_STRG, .letter = ' ', .cmd = C_FTP_ALTERNATIVE_TO_USER },
    .{ .lname = "ftp-create-dirs", .desc = ARG_BOOL, .letter = ' ', .cmd = C_FTP_CREATE_DIRS },
    .{ .lname = "ftp-method", .desc = ARG_STRG, .letter = ' ', .cmd = C_FTP_METHOD },
    .{ .lname = "ftp-pasv", .desc = ARG_NONE, .letter = ' ', .cmd = C_FTP_PASV },
    .{ .lname = "ftp-port", .desc = ARG_STRG, .letter = 'P', .cmd = C_FTP_PORT },
    .{ .lname = "ftp-pret", .desc = ARG_BOOL, .letter = ' ', .cmd = C_FTP_PRET },
    .{ .lname = "ftp-skip-pasv-ip", .desc = ARG_BOOL, .letter = ' ', .cmd = C_FTP_SKIP_PASV_IP },
    .{ .lname = "ftp-ssl", .desc = ARG_BOOL | ARG_TLS, .letter = ' ', .cmd = C_FTP_SSL },
    .{ .lname = "ftp-ssl-ccc", .desc = ARG_BOOL | ARG_TLS, .letter = ' ', .cmd = C_FTP_SSL_CCC },
    .{ .lname = "ftp-ssl-ccc-mode", .desc = ARG_STRG | ARG_TLS, .letter = ' ', .cmd = C_FTP_SSL_CCC_MODE },
    .{ .lname = "ftp-ssl-control", .desc = ARG_BOOL | ARG_TLS, .letter = ' ', .cmd = C_FTP_SSL_CONTROL },
    .{ .lname = "ftp-ssl-reqd", .desc = ARG_BOOL | ARG_TLS, .letter = ' ', .cmd = C_FTP_SSL_REQD },
    .{ .lname = "get", .desc = ARG_BOOL, .letter = 'G', .cmd = C_GET },
    .{ .lname = "globoff", .desc = ARG_BOOL, .letter = 'g', .cmd = C_GLOBOFF },
    .{ .lname = "happy-eyeballs-timeout-ms", .desc = ARG_UNUM, .letter = ' ', .cmd = C_HAPPY_EYEBALLS_TIMEOUT_MS },
    .{ .lname = "haproxy-clientip", .desc = ARG_STRG, .letter = ' ', .cmd = C_HAPROXY_CLIENTIP },
    .{ .lname = "haproxy-protocol", .desc = ARG_BOOL, .letter = ' ', .cmd = C_HAPROXY_PROTOCOL },
    .{ .lname = "head", .desc = ARG_BOOL, .letter = 'I', .cmd = C_HEAD },
    .{ .lname = "header", .desc = ARG_STRG, .letter = 'H', .cmd = C_HEADER },
    .{ .lname = "help", .desc = ARG_STRG, .letter = 'h', .cmd = C_HELP },
    .{ .lname = "hostpubmd5", .desc = ARG_STRG, .letter = ' ', .cmd = C_HOSTPUBMD5 },
    .{ .lname = "hostpubsha256", .desc = ARG_STRG, .letter = ' ', .cmd = C_HOSTPUBSHA256 },
    .{ .lname = "hsts", .desc = ARG_STRG | ARG_TLS, .letter = ' ', .cmd = C_HSTS },
    .{ .lname = "http0.9", .desc = ARG_BOOL, .letter = ' ', .cmd = C_HTTP0_9 },
    .{ .lname = "http1.0", .desc = ARG_NONE, .letter = '0', .cmd = C_HTTP1_0 },
    .{ .lname = "http1.1", .desc = ARG_NONE, .letter = ' ', .cmd = C_HTTP1_1 },
    .{ .lname = "http2", .desc = ARG_NONE, .letter = ' ', .cmd = C_HTTP2 },
    .{ .lname = "http2-prior-knowledge", .desc = ARG_NONE, .letter = ' ', .cmd = C_HTTP2_PRIOR_KNOWLEDGE },
    .{ .lname = "http3", .desc = ARG_NONE | ARG_TLS, .letter = ' ', .cmd = C_HTTP3 },
    .{ .lname = "http3-only", .desc = ARG_NONE | ARG_TLS, .letter = ' ', .cmd = C_HTTP3_ONLY },
    .{ .lname = "httpsig-algo", .desc = ARG_STRG, .letter = ' ', .cmd = C_HTTPSIG_ALGORITHM },
    .{ .lname = "httpsig-headers", .desc = ARG_STRG, .letter = ' ', .cmd = C_HTTPSIG_HEADERS },
    .{ .lname = "httpsig-key", .desc = ARG_FILE | ARG_CLEAR, .letter = ' ', .cmd = C_HTTPSIG_KEY },
    .{ .lname = "httpsig-keyid", .desc = ARG_STRG, .letter = ' ', .cmd = C_HTTPSIG_KEYID },
    .{ .lname = "ignore-content-length", .desc = ARG_BOOL, .letter = ' ', .cmd = C_IGNORE_CONTENT_LENGTH },
    .{ .lname = "include", .desc = ARG_BOOL, .letter = ' ', .cmd = C_INCLUDE },
    .{ .lname = "insecure", .desc = ARG_BOOL, .letter = 'k', .cmd = C_INSECURE },
    .{ .lname = "interface", .desc = ARG_STRG, .letter = ' ', .cmd = C_INTERFACE },
    .{ .lname = "ip-tos", .desc = ARG_STRG, .letter = ' ', .cmd = C_IP_TOS },
    .{ .lname = "ipfs-gateway", .desc = ARG_STRG, .letter = ' ', .cmd = C_IPFS_GATEWAY },
    .{ .lname = "ipv4", .desc = ARG_NONE, .letter = '4', .cmd = C_IPV4 },
    .{ .lname = "ipv6", .desc = ARG_NONE, .letter = '6', .cmd = C_IPV6 },
    .{ .lname = "json", .desc = ARG_STRG, .letter = ' ', .cmd = C_JSON },
    .{ .lname = "junk-session-cookies", .desc = ARG_BOOL, .letter = 'j', .cmd = C_JUNK_SESSION_COOKIES },
    .{ .lname = "keepalive", .desc = ARG_BOOL | ARG_NO, .letter = ' ', .cmd = C_KEEPALIVE },
    .{ .lname = "keepalive-cnt", .desc = ARG_UNUM, .letter = ' ', .cmd = C_KEEPALIVE_CNT },
    .{ .lname = "keepalive-time", .desc = ARG_UNUM, .letter = ' ', .cmd = C_KEEPALIVE_TIME },
    .{ .lname = "key", .desc = ARG_FILE, .letter = ' ', .cmd = C_KEY },
    .{ .lname = "key-type", .desc = ARG_STRG | ARG_TLS, .letter = ' ', .cmd = C_KEY_TYPE },
    .{ .lname = "knownhosts", .desc = ARG_FILE, .letter = ' ', .cmd = C_KNOWNHOSTS },
    .{ .lname = "krb", .desc = ARG_STRG | ARG_DEPR, .letter = ' ', .cmd = C_KRB },
    .{ .lname = "krb4", .desc = ARG_STRG | ARG_DEPR, .letter = ' ', .cmd = C_KRB4 },
    .{ .lname = "libcurl", .desc = ARG_STRG, .letter = ' ', .cmd = C_LIBCURL },
    .{ .lname = "limit-rate", .desc = ARG_STRG, .letter = ' ', .cmd = C_LIMIT_RATE },
    .{ .lname = "list-only", .desc = ARG_BOOL, .letter = 'l', .cmd = C_LIST_ONLY },
    .{ .lname = "local-port", .desc = ARG_STRG, .letter = ' ', .cmd = C_LOCAL_PORT },
    .{ .lname = "location", .desc = ARG_BOOL, .letter = 'L', .cmd = C_LOCATION },
    .{ .lname = "location-trusted", .desc = ARG_BOOL, .letter = ' ', .cmd = C_LOCATION_TRUSTED },
    .{ .lname = "login-options", .desc = ARG_STRG, .letter = ' ', .cmd = C_LOGIN_OPTIONS },
    .{ .lname = "mail-auth", .desc = ARG_STRG, .letter = ' ', .cmd = C_MAIL_AUTH },
    .{ .lname = "mail-from", .desc = ARG_STRG, .letter = ' ', .cmd = C_MAIL_FROM },
    .{ .lname = "mail-rcpt", .desc = ARG_STRG, .letter = ' ', .cmd = C_MAIL_RCPT },
    .{ .lname = "mail-rcpt-allowfails", .desc = ARG_BOOL, .letter = ' ', .cmd = C_MAIL_RCPT_ALLOWFAILS },
    .{ .lname = "manual", .desc = ARG_BOOL, .letter = 'M', .cmd = C_MANUAL },
    .{ .lname = "max-filesize", .desc = ARG_STRG, .letter = ' ', .cmd = C_MAX_FILESIZE },
    .{ .lname = "max-redirs", .desc = ARG_STRG, .letter = ' ', .cmd = C_MAX_REDIRS },
    .{ .lname = "max-time", .desc = ARG_SECS, .letter = 'm', .cmd = C_MAX_TIME },
    .{ .lname = "metalink", .desc = ARG_BOOL | ARG_DEPR, .letter = ' ', .cmd = C_METALINK },
    .{ .lname = "mptcp", .desc = ARG_BOOL, .letter = ' ', .cmd = C_MPTCP },
    .{ .lname = "negotiate", .desc = ARG_BOOL, .letter = ' ', .cmd = C_NEGOTIATE },
    .{ .lname = "netrc", .desc = ARG_BOOL, .letter = 'n', .cmd = C_NETRC },
    .{ .lname = "netrc-file", .desc = ARG_FILE, .letter = ' ', .cmd = C_NETRC_FILE },
    .{ .lname = "netrc-optional", .desc = ARG_BOOL, .letter = ' ', .cmd = C_NETRC_OPTIONAL },
    .{ .lname = "next", .desc = ARG_NONE, .letter = ':', .cmd = C_NEXT },
    .{ .lname = "noproxy", .desc = ARG_STRG, .letter = ' ', .cmd = C_NOPROXY },
    .{ .lname = "npn", .desc = ARG_BOOL | ARG_DEPR, .letter = ' ', .cmd = C_NPN },
    .{ .lname = "ntlm", .desc = ARG_BOOL, .letter = ' ', .cmd = C_NTLM },
    .{ .lname = "ntlm-wb", .desc = ARG_BOOL | ARG_DEPR, .letter = ' ', .cmd = C_NTLM_WB },
    .{ .lname = "oauth2-bearer", .desc = ARG_STRG | ARG_CLEAR, .letter = ' ', .cmd = C_OAUTH2_BEARER },
    .{ .lname = "out-null", .desc = ARG_BOOL, .letter = ' ', .cmd = C_OUT_NULL },
    .{ .lname = "output", .desc = ARG_FILE, .letter = 'o', .cmd = C_OUTPUT },
    .{ .lname = "output-dir", .desc = ARG_STRG, .letter = ' ', .cmd = C_OUTPUT_DIR },
    .{ .lname = "parallel", .desc = ARG_BOOL, .letter = 'Z', .cmd = C_PARALLEL },
    .{ .lname = "parallel-immediate", .desc = ARG_BOOL, .letter = ' ', .cmd = C_PARALLEL_IMMEDIATE },
    .{ .lname = "parallel-max", .desc = ARG_UNUM, .letter = ' ', .cmd = C_PARALLEL_MAX },
    .{ .lname = "parallel-max-host", .desc = ARG_UNUM, .letter = ' ', .cmd = C_PARALLEL_HOST },
    .{ .lname = "pass", .desc = ARG_STRG | ARG_CLEAR, .letter = ' ', .cmd = C_PASS },
    .{ .lname = "path-as-is", .desc = ARG_BOOL, .letter = ' ', .cmd = C_PATH_AS_IS },
    .{ .lname = "pinnedpubkey", .desc = ARG_STRG | ARG_TLS, .letter = ' ', .cmd = C_PINNEDPUBKEY },
    .{ .lname = "post301", .desc = ARG_BOOL, .letter = ' ', .cmd = C_POST301 },
    .{ .lname = "post302", .desc = ARG_BOOL, .letter = ' ', .cmd = C_POST302 },
    .{ .lname = "post303", .desc = ARG_BOOL, .letter = ' ', .cmd = C_POST303 },
    .{ .lname = "preproxy", .desc = ARG_STRG, .letter = ' ', .cmd = C_PREPROXY },
    .{ .lname = "progress-bar", .desc = ARG_BOOL, .letter = '#', .cmd = C_PROGRESS_BAR },
    .{ .lname = "progress-meter", .desc = ARG_BOOL | ARG_NO, .letter = ' ', .cmd = C_PROGRESS_METER },
    .{ .lname = "proto", .desc = ARG_STRG, .letter = ' ', .cmd = C_PROTO },
    .{ .lname = "proto-default", .desc = ARG_STRG, .letter = ' ', .cmd = C_PROTO_DEFAULT },
    .{ .lname = "proto-redir", .desc = ARG_STRG, .letter = ' ', .cmd = C_PROTO_REDIR },
    .{ .lname = "proxy", .desc = ARG_STRG, .letter = 'x', .cmd = C_PROXY },
    .{ .lname = "proxy-anyauth", .desc = ARG_BOOL, .letter = ' ', .cmd = C_PROXY_ANYAUTH },
    .{ .lname = "proxy-basic", .desc = ARG_BOOL, .letter = ' ', .cmd = C_PROXY_BASIC },
    .{ .lname = "proxy-ca-native", .desc = ARG_BOOL | ARG_TLS, .letter = ' ', .cmd = C_PROXY_CA_NATIVE },
    .{ .lname = "proxy-cacert", .desc = ARG_FILE | ARG_TLS, .letter = ' ', .cmd = C_PROXY_CACERT },
    .{ .lname = "proxy-capath", .desc = ARG_FILE | ARG_TLS, .letter = ' ', .cmd = C_PROXY_CAPATH },
    .{ .lname = "proxy-cert", .desc = ARG_FILE | ARG_TLS | ARG_CLEAR, .letter = ' ', .cmd = C_PROXY_CERT },
    .{ .lname = "proxy-cert-type", .desc = ARG_STRG | ARG_TLS, .letter = ' ', .cmd = C_PROXY_CERT_TYPE },
    .{ .lname = "proxy-ciphers", .desc = ARG_STRG | ARG_TLS, .letter = ' ', .cmd = C_PROXY_CIPHERS },
    .{ .lname = "proxy-crlfile", .desc = ARG_FILE | ARG_TLS, .letter = ' ', .cmd = C_PROXY_CRLFILE },
    .{ .lname = "proxy-digest", .desc = ARG_BOOL, .letter = ' ', .cmd = C_PROXY_DIGEST },
    .{ .lname = "proxy-header", .desc = ARG_STRG, .letter = ' ', .cmd = C_PROXY_HEADER },
    .{ .lname = "proxy-http2", .desc = ARG_BOOL, .letter = ' ', .cmd = C_PROXY_HTTP2 },
    .{ .lname = "proxy-http3", .desc = ARG_BOOL, .letter = ' ', .cmd = C_PROXY_HTTP3 },
    .{ .lname = "proxy-insecure", .desc = ARG_BOOL, .letter = ' ', .cmd = C_PROXY_INSECURE },
    .{ .lname = "proxy-key", .desc = ARG_FILE | ARG_TLS, .letter = ' ', .cmd = C_PROXY_KEY },
    .{ .lname = "proxy-key-type", .desc = ARG_STRG | ARG_TLS, .letter = ' ', .cmd = C_PROXY_KEY_TYPE },
    .{ .lname = "proxy-negotiate", .desc = ARG_BOOL, .letter = ' ', .cmd = C_PROXY_NEGOTIATE },
    .{ .lname = "proxy-ntlm", .desc = ARG_BOOL, .letter = ' ', .cmd = C_PROXY_NTLM },
    .{ .lname = "proxy-pass", .desc = ARG_STRG | ARG_CLEAR, .letter = ' ', .cmd = C_PROXY_PASS },
    .{ .lname = "proxy-pinnedpubkey", .desc = ARG_STRG | ARG_TLS, .letter = ' ', .cmd = C_PROXY_PINNEDPUBKEY },
    .{ .lname = "proxy-service-name", .desc = ARG_STRG, .letter = ' ', .cmd = C_PROXY_SERVICE_NAME },
    .{ .lname = "proxy-ssl-allow-beast", .desc = ARG_BOOL | ARG_TLS, .letter = ' ', .cmd = C_PROXY_SSL_ALLOW_BEAST },
    .{ .lname = "proxy-ssl-auto-client-cert", .desc = ARG_BOOL | ARG_TLS, .letter = ' ', .cmd = C_PROXY_SSL_AUTO_CLIENT_CERT },
    .{ .lname = "proxy-tls13-ciphers", .desc = ARG_STRG | ARG_TLS, .letter = ' ', .cmd = C_PROXY_TLS13_CIPHERS },
    .{ .lname = "proxy-tlsauthtype", .desc = ARG_STRG | ARG_TLS | ARG_DEPR, .letter = ' ', .cmd = C_PROXY_TLSAUTHTYPE },
    .{ .lname = "proxy-tlspassword", .desc = ARG_STRG | ARG_TLS | ARG_CLEAR | ARG_DEPR, .letter = ' ', .cmd = C_PROXY_TLSPASSWORD },
    .{ .lname = "proxy-tlsuser", .desc = ARG_STRG | ARG_TLS | ARG_CLEAR | ARG_DEPR, .letter = ' ', .cmd = C_PROXY_TLSUSER },
    .{ .lname = "proxy-tlsv1", .desc = ARG_NONE | ARG_TLS, .letter = ' ', .cmd = C_PROXY_TLSV1 },
    .{ .lname = "proxy-user", .desc = ARG_STRG | ARG_CLEAR, .letter = 'U', .cmd = C_PROXY_USER },
    .{ .lname = "proxy1.0", .desc = ARG_STRG, .letter = ' ', .cmd = C_PROXY1_0 },
    .{ .lname = "proxytunnel", .desc = ARG_BOOL, .letter = 'p', .cmd = C_PROXYTUNNEL },
    .{ .lname = "pubkey", .desc = ARG_STRG, .letter = ' ', .cmd = C_PUBKEY },
    .{ .lname = "quote", .desc = ARG_STRG, .letter = 'Q', .cmd = C_QUOTE },
    .{ .lname = "random-file", .desc = ARG_FILE | ARG_DEPR, .letter = ' ', .cmd = C_RANDOM_FILE },
    .{ .lname = "range", .desc = ARG_STRG, .letter = 'r', .cmd = C_RANGE },
    .{ .lname = "rate", .desc = ARG_STRG, .letter = ' ', .cmd = C_RATE },
    .{ .lname = "raw", .desc = ARG_BOOL, .letter = ' ', .cmd = C_RAW },
    .{ .lname = "referer", .desc = ARG_STRG, .letter = 'e', .cmd = C_REFERER },
    .{ .lname = "remote-header-name", .desc = ARG_BOOL, .letter = 'J', .cmd = C_REMOTE_HEADER_NAME },
    .{ .lname = "remote-name", .desc = ARG_BOOL, .letter = 'O', .cmd = C_REMOTE_NAME },
    .{ .lname = "remote-name-all", .desc = ARG_BOOL, .letter = ' ', .cmd = C_REMOTE_NAME_ALL },
    .{ .lname = "remote-time", .desc = ARG_BOOL, .letter = 'R', .cmd = C_REMOTE_TIME },
    .{ .lname = "remove-on-error", .desc = ARG_BOOL, .letter = ' ', .cmd = C_REMOVE_ON_ERROR },
    .{ .lname = "request", .desc = ARG_STRG, .letter = 'X', .cmd = C_REQUEST },
    .{ .lname = "request-target", .desc = ARG_STRG, .letter = ' ', .cmd = C_REQUEST_TARGET },
    .{ .lname = "resolve", .desc = ARG_STRG, .letter = ' ', .cmd = C_RESOLVE },
    .{ .lname = "retry", .desc = ARG_UNUM, .letter = ' ', .cmd = C_RETRY },
    .{ .lname = "retry-all-errors", .desc = ARG_BOOL, .letter = ' ', .cmd = C_RETRY_ALL_ERRORS },
    .{ .lname = "retry-connrefused", .desc = ARG_BOOL, .letter = ' ', .cmd = C_RETRY_CONNREFUSED },
    .{ .lname = "retry-delay", .desc = ARG_SECS, .letter = ' ', .cmd = C_RETRY_DELAY },
    .{ .lname = "retry-max-time", .desc = ARG_SECS, .letter = ' ', .cmd = C_RETRY_MAX_TIME },
    .{ .lname = "sasl-authzid", .desc = ARG_STRG, .letter = ' ', .cmd = C_SASL_AUTHZID },
    .{ .lname = "sasl-ir", .desc = ARG_BOOL, .letter = ' ', .cmd = C_SASL_IR },
    .{ .lname = "service-name", .desc = ARG_STRG, .letter = ' ', .cmd = C_SERVICE_NAME },
    .{ .lname = "sessionid", .desc = ARG_BOOL | ARG_NO, .letter = ' ', .cmd = C_SESSIONID },
    .{ .lname = "show-error", .desc = ARG_BOOL, .letter = 'S', .cmd = C_SHOW_ERROR },
    .{ .lname = "show-headers", .desc = ARG_BOOL, .letter = 'i', .cmd = C_SHOW_HEADERS },
    .{ .lname = "sigalgs", .desc = ARG_STRG | ARG_TLS, .letter = ' ', .cmd = C_SIGNATURE_ALGORITHMS },
    .{ .lname = "silent", .desc = ARG_BOOL, .letter = 's', .cmd = C_SILENT },
    .{ .lname = "skip-existing", .desc = ARG_BOOL, .letter = ' ', .cmd = C_SKIP_EXISTING },
    .{ .lname = "socks4", .desc = ARG_STRG, .letter = ' ', .cmd = C_SOCKS4 },
    .{ .lname = "socks4a", .desc = ARG_STRG, .letter = ' ', .cmd = C_SOCKS4A },
    .{ .lname = "socks5", .desc = ARG_STRG, .letter = ' ', .cmd = C_SOCKS5 },
    .{ .lname = "socks5-basic", .desc = ARG_BOOL, .letter = ' ', .cmd = C_SOCKS5_BASIC },
    .{ .lname = "socks5-gssapi", .desc = ARG_BOOL, .letter = ' ', .cmd = C_SOCKS5_GSSAPI },
    .{ .lname = "socks5-gssapi-nec", .desc = ARG_BOOL, .letter = ' ', .cmd = C_SOCKS5_GSSAPI_NEC },
    .{ .lname = "socks5-gssapi-service", .desc = ARG_STRG, .letter = ' ', .cmd = C_SOCKS5_GSSAPI_SERVICE },
    .{ .lname = "socks5-hostname", .desc = ARG_STRG, .letter = ' ', .cmd = C_SOCKS5_HOSTNAME },
    .{ .lname = "speed-limit", .desc = ARG_UNUM, .letter = 'Y', .cmd = C_SPEED_LIMIT },
    .{ .lname = "speed-time", .desc = ARG_UNUM, .letter = 'y', .cmd = C_SPEED_TIME },
    .{ .lname = "ssl", .desc = ARG_BOOL | ARG_TLS, .letter = ' ', .cmd = C_SSL },
    .{ .lname = "ssl-allow-beast", .desc = ARG_BOOL | ARG_TLS, .letter = ' ', .cmd = C_SSL_ALLOW_BEAST },
    .{ .lname = "ssl-auto-client-cert", .desc = ARG_BOOL | ARG_TLS, .letter = ' ', .cmd = C_SSL_AUTO_CLIENT_CERT },
    .{ .lname = "ssl-no-revoke", .desc = ARG_BOOL | ARG_TLS, .letter = ' ', .cmd = C_SSL_NO_REVOKE },
    .{ .lname = "ssl-reqd", .desc = ARG_BOOL | ARG_TLS, .letter = ' ', .cmd = C_SSL_REQD },
    .{ .lname = "ssl-revoke-best-effort", .desc = ARG_BOOL | ARG_TLS, .letter = ' ', .cmd = C_SSL_REVOKE_BEST_EFFORT },
    .{ .lname = "ssl-sessions", .desc = ARG_FILE | ARG_TLS, .letter = ' ', .cmd = C_SSL_SESSIONS },
    .{ .lname = "sslv2", .desc = ARG_NONE | ARG_DEPR, .letter = '2', .cmd = C_SSLV2 },
    .{ .lname = "sslv3", .desc = ARG_NONE | ARG_DEPR, .letter = '3', .cmd = C_SSLV3 },
    .{ .lname = "stderr", .desc = ARG_FILE, .letter = ' ', .cmd = C_STDERR },
    .{ .lname = "styled-output", .desc = ARG_BOOL, .letter = ' ', .cmd = C_STYLED_OUTPUT },
    .{ .lname = "suppress-connect-headers", .desc = ARG_BOOL, .letter = ' ', .cmd = C_SUPPRESS_CONNECT_HEADERS },
    .{ .lname = "tcp-fastopen", .desc = ARG_BOOL, .letter = ' ', .cmd = C_TCP_FASTOPEN },
    .{ .lname = "tcp-nodelay", .desc = ARG_BOOL, .letter = ' ', .cmd = C_TCP_NODELAY },
    .{ .lname = "telnet-option", .desc = ARG_STRG, .letter = 't', .cmd = C_TELNET_OPTION },
    .{ .lname = "tftp-blksize", .desc = ARG_UNUM, .letter = ' ', .cmd = C_TFTP_BLKSIZE },
    .{ .lname = "tftp-no-options", .desc = ARG_BOOL, .letter = ' ', .cmd = C_TFTP_NO_OPTIONS },
    .{ .lname = "time-cond", .desc = ARG_STRG, .letter = 'z', .cmd = C_TIME_COND },
    .{ .lname = "tls-earlydata", .desc = ARG_BOOL | ARG_TLS, .letter = ' ', .cmd = C_TLS_EARLYDATA },
    .{ .lname = "tls-max", .desc = ARG_STRG | ARG_TLS, .letter = ' ', .cmd = C_TLS_MAX },
    .{ .lname = "tls13-ciphers", .desc = ARG_STRG | ARG_TLS, .letter = ' ', .cmd = C_TLS13_CIPHERS },
    .{ .lname = "tlsauthtype", .desc = ARG_STRG | ARG_TLS | ARG_DEPR, .letter = ' ', .cmd = C_TLSAUTHTYPE },
    .{ .lname = "tlspassword", .desc = ARG_STRG | ARG_TLS | ARG_CLEAR | ARG_DEPR, .letter = ' ', .cmd = C_TLSPASSWORD },
    .{ .lname = "tlsuser", .desc = ARG_STRG | ARG_TLS | ARG_CLEAR | ARG_DEPR, .letter = ' ', .cmd = C_TLSUSER },
    .{ .lname = "tlsv1", .desc = ARG_NONE | ARG_TLS, .letter = '1', .cmd = C_TLSV1 },
    .{ .lname = "tlsv1.0", .desc = ARG_NONE | ARG_TLS, .letter = ' ', .cmd = C_TLSV1_0 },
    .{ .lname = "tlsv1.1", .desc = ARG_NONE | ARG_TLS, .letter = ' ', .cmd = C_TLSV1_1 },
    .{ .lname = "tlsv1.2", .desc = ARG_NONE | ARG_TLS, .letter = ' ', .cmd = C_TLSV1_2 },
    .{ .lname = "tlsv1.3", .desc = ARG_NONE | ARG_TLS, .letter = ' ', .cmd = C_TLSV1_3 },
    .{ .lname = "tr-encoding", .desc = ARG_BOOL, .letter = ' ', .cmd = C_TR_ENCODING },
    .{ .lname = "trace", .desc = ARG_FILE, .letter = ' ', .cmd = C_TRACE },
    .{ .lname = "trace-ascii", .desc = ARG_FILE, .letter = ' ', .cmd = C_TRACE_ASCII },
    .{ .lname = "trace-config", .desc = ARG_STRG, .letter = ' ', .cmd = C_TRACE_CONFIG },
    .{ .lname = "trace-ids", .desc = ARG_BOOL, .letter = ' ', .cmd = C_TRACE_IDS },
    .{ .lname = "trace-time", .desc = ARG_BOOL, .letter = ' ', .cmd = C_TRACE_TIME },
    .{ .lname = "unix-socket", .desc = ARG_FILE, .letter = ' ', .cmd = C_UNIX_SOCKET },
    .{ .lname = "upload-file", .desc = ARG_FILE, .letter = 'T', .cmd = C_UPLOAD_FILE },
    .{ .lname = "upload-flags", .desc = ARG_STRG, .letter = ' ', .cmd = C_UPLOAD_FLAGS },
    .{ .lname = "url", .desc = ARG_STRG, .letter = ' ', .cmd = C_URL },
    .{ .lname = "url-query", .desc = ARG_STRG, .letter = ' ', .cmd = C_URL_QUERY },
    .{ .lname = "use-ascii", .desc = ARG_BOOL, .letter = 'B', .cmd = C_USE_ASCII },
    .{ .lname = "user", .desc = ARG_STRG | ARG_CLEAR, .letter = 'u', .cmd = C_USER },
    .{ .lname = "user-agent", .desc = ARG_STRG, .letter = 'A', .cmd = C_USER_AGENT },
    .{ .lname = "variable", .desc = ARG_STRG, .letter = ' ', .cmd = C_VARIABLE },
    .{ .lname = "verbose", .desc = ARG_BOOL, .letter = 'v', .cmd = C_VERBOSE },
    .{ .lname = "version", .desc = ARG_BOOL, .letter = 'V', .cmd = C_VERSION },
    .{ .lname = "vlan-priority", .desc = ARG_UNUM, .letter = ' ', .cmd = C_VLAN_PRIORITY },
    .{ .lname = "write-out", .desc = ARG_STRG, .letter = 'w', .cmd = C_WRITE_OUT },
    .{ .lname = "xattr", .desc = ARG_BOOL, .letter = ' ', .cmd = C_XATTR },
};

pub export fn parse_cert_parameter(
    cert_parameter: [*:0]const u8,
    certname: *?[*:0]u8,
    passphrase: *?[*:0]u8,
) callconv(.c) ParameterError {
    var param_length = std.mem.len(cert_parameter);
    var offset: usize = 0;
    var almost_passphrase: ?[*:0]u8 = null;

    certname.* = null;
    passphrase.* = null;

    if (param_length == 0)
        return PARAM_OK;

    if (curl_strnequal(cert_parameter, "pkcs11:", 7) != 0 or
        std.mem.indexOfAny(u8, cert_parameter[0..param_length], ":\\") == null)
    {
        certname.* = cStrdup(cert_parameter);
        if (certname.* == null)
            return PARAM_NO_MEM;
        return PARAM_OK;
    }

    const certname_raw = c.malloc(param_length + 1) orelse return PARAM_NO_MEM;
    const actual_certname: [*:0]u8 = @ptrCast(certname_raw);

    if (param_length >= 2 and
        ((cert_parameter[0] >= 'a' and cert_parameter[0] <= 'z') or
            (cert_parameter[0] >= 'A' and cert_parameter[0] <= 'Z')) and
        cert_parameter[1] == ':')
    {
        actual_certname[0] = cert_parameter[0];
        actual_certname[1] = cert_parameter[1];
        offset = 2;
    }

    var i: usize = offset;
    var j: usize = offset;
    while (i < param_length) : (i += 1) {
        if (cert_parameter[i] == '\\') {
            i += 1;
            if (i == param_length) {
                actual_certname[j] = '\\';
                j += 1;
                break;
            }
            actual_certname[j] = cert_parameter[i];
            j += 1;
        } else if (cert_parameter[i] == ':') {
            i += 1;
            almost_passphrase = @constCast(cert_parameter + i);
            break;
        } else {
            actual_certname[j] = cert_parameter[i];
            j += 1;
        }
    }
    actual_certname[j] = 0;

    if (almost_passphrase) |ap| {
        param_length = std.mem.len(ap);
        const pass_raw = c.malloc(param_length + 1);
        if (pass_raw == null) {
            c.free(actual_certname);
            return PARAM_NO_MEM;
        }
        const actual_passphrase: [*:0]u8 = @ptrCast(pass_raw.?);
        i = 0;
        j = 0;
        while (i < param_length) : (i += 1) {
            if (ap[i] == '\\' and (i + 1) < param_length and ap[i + 1] == '\\') {
                i += 1;
            }
            actual_passphrase[j] = ap[i];
            j += 1;
        }
        actual_passphrase[j] = 0;
        passphrase.* = actual_passphrase;
    }

    certname.* = actual_certname;
    return PARAM_OK;
}

fn replaceUrlEncodedSpaceByPlus(url: [*:0]u8) usize {
    const orig_len = std.mem.len(url);
    var orig_index: usize = 0;
    var new_index: usize = 0;

    while (orig_index < orig_len) {
        if (url[orig_index] == '%' and
            url[orig_index + 1] == '2' and
            url[orig_index + 2] == '0')
        {
            url[new_index] = '+';
            orig_index += 3;
        } else {
            if (new_index != orig_index) {
                url[new_index] = url[orig_index];
            }
            orig_index += 1;
        }
        new_index += 1;
    }

    url[new_index] = 0;
    return new_index;
}

fn GetFileAndPassword(
    nextarg: [*:0]const u8,
    file: *?[*:0]u8,
    password: *?[*:0]u8,
) ParameterError {
    var certname: ?[*:0]u8 = null;
    var passphrase: ?[*:0]u8 = null;
    const err = parse_cert_parameter(nextarg, &certname, &passphrase);
    if (err == PARAM_OK) {
        c.free(file.*);
        file.* = certname;
        if (passphrase) |pp| {
            c.free(password.*);
            password.* = pp;
        }
    }
    return err;
}

const SizeUnit = struct {
    unit: u8,
    mul: curl_off_t,
    mlen: usize,
};

const size_unit_list = [_]SizeUnit{
    .{ .unit = 'p', .mul = 1125899906842624, .mlen = 16 },
    .{ .unit = 't', .mul = 1099511627776, .mlen = 13 },
    .{ .unit = 'g', .mul = 1073741824, .mlen = 10 },
    .{ .unit = 'm', .mul = 1048576, .mlen = 7 },
    .{ .unit = 'k', .mul = 1024, .mlen = 4 },
};

fn getunit(unit: u8) ?*const SizeUnit {
    for (&size_unit_list) |*su| {
        if ((unit | 0x20) == su.unit)
            return su;
    }
    return null;
}

pub export fn GetSizeParameter(arg: [*:0]const u8, out: *curl_off_t) callconv(.c) ParameterError {
    var unit: [*:0]const u8 = arg;
    var value: curl_off_t = 0;
    var prec: curl_off_t = 0;
    var plen: usize = 0;
    var add: curl_off_t = 0;
    var mul: curl_off_t = 1;

    const rc = curlx_str_number(&unit, &value, CURL_OFF_T_MAX);
    if (rc == STRE_OVERFLOW)
        return PARAM_NUMBER_TOO_LARGE
    else if (rc != 0)
        return PARAM_BAD_NUMERIC;

    if (curlx_str_single(&unit, '.') == 0) {
        const s = unit;
        if (curlx_str_number(&unit, &prec, CURL_OFF_T_MAX) != 0)
            return PARAM_BAD_NUMERIC;
        plen = @intFromPtr(unit) - @intFromPtr(s);
    }

    if (std.mem.len(unit) > 1)
        return PARAM_BAD_USE
    else if (unit[0] == 0 or (unit[0] | 0x20) == 'b') {
        if (plen != 0)
            return PARAM_BAD_USE;
    } else {
        const su = getunit(unit[0]) orelse return PARAM_BAD_USE;
        mul = su.mul;

        if (prec != 0) {
            var frac: curl_off_t = 1;
            while (su.mlen <= plen) {
                prec = @divTrunc(prec, 10);
                plen -= 1;
            }
            while (plen > 0) : (plen -= 1) {
                frac *= 10;
            }
            if (@divTrunc(CURL_OFF_T_MAX, mul) > prec)
                add = @divTrunc(mul * prec, frac)
            else
                add = @divTrunc(mul, frac) * prec;
        }
    }

    if (value > @divTrunc(CURL_OFF_T_MAX - add, mul))
        return PARAM_NUMBER_TOO_LARGE;

    out.* = (value * mul) + add;
    return PARAM_OK;
}

const MAX_DATAURLENCODE: usize = 500 * 1024 * 1024;

fn strChrZ(s: [*:0]const u8, ch: u8) ?[*:0]const u8 {
    var p = s;
    while (p[0] != 0) : (p += 1) {
        if (p[0] == ch) return p;
    }
    return null;
}

fn dataUrlencode(
    nextarg: [*:0]const u8,
    postp: *?[*:0]u8,
    lenp: *usize,
) ParameterError {
    var err: ParameterError = PARAM_OK;
    var p_opt = strChrZ(nextarg, '=');
    var nlen: usize = 0;
    var is_file: u8 = 0;
    var postdata: ?[*:0]u8 = null;
    var size: usize = 0;

    if (p_opt == null)
        p_opt = strChrZ(nextarg, '@');

    var p: [*:0]const u8 = nextarg;
    if (p_opt) |sep| {
        nlen = @intFromPtr(sep) - @intFromPtr(nextarg);
        is_file = sep[0];
        p = sep + 1;
    }

    if (is_file == '@') {
        var file: ?*anyopaque = null;
        const stdin_ptr = tool_zig_stdin();
        if (std.mem.eql(u8, std.mem.span(p), "-")) {
            file = stdin_ptr;
            tool_zig_stdin_binmode();
        } else {
            file = toolFopen(p, "rb");
            if (file == null) {
                errorf("Failed to open %s", p);
                return PARAM_READ_ERROR;
            }
        }

        err = file2memory(&postdata, &size, file);
        if (file != null and file != stdin_ptr)
            toolFclose(file);
        if (err != PARAM_OK)
            return err;
    } else {
        err = getstr(&postdata, p, ALLOW_BLANK);
        if (err != PARAM_OK)
            return err;
        size = std.mem.len(postdata.?);
    }

    if (postdata == null) {
        postdata = cStrdup("");
        if (postdata == null)
            return PARAM_NO_MEM;
        size = 0;
    } else {
        const enc = curl_easy_escape(null, postdata.?, @intCast(size));
        c.free(postdata);
        postdata = null;
        if (enc) |enc_ptr| {
            var n: ?[*:0]u8 = null;
            _ = replaceUrlEncodedSpaceByPlus(enc_ptr);
            if (nlen > 0) {
                var dyn: Dynbuf = .{};
                curlx_dyn_init(&dyn, MAX_DATAURLENCODE);
                if (curlx_dyn_addn(&dyn, nextarg, nlen) != CURLE_OK or
                    curlx_dyn_addn(&dyn, "=", 1) != CURLE_OK or
                    curlx_dyn_add(&dyn, enc_ptr) != CURLE_OK)
                {
                    curl_free(enc_ptr);
                    return PARAM_NO_MEM;
                }
                curl_free(enc_ptr);
                n = curlx_dyn_ptr(&dyn);
                size = curlx_dyn_len(&dyn);
            } else {
                n = cStrdup(enc_ptr);
                curl_free(enc_ptr);
                if (n == null)
                    return PARAM_NO_MEM;
                size = std.mem.len(n.?);
            }
            postdata = n;
        } else {
            return PARAM_NO_MEM;
        }
    }

    postp.* = postdata;
    lenp.* = size;
    return PARAM_OK;
}

fn sethttpver(config: *OperationConfig, httpversion: c_long) void {
    const cur = cfgInt(config, .httpversion);
    if (cur != 0 and cur != httpversion)
        warnf("Overrides previous HTTP version option");
    setCfgInt(config, .httpversion, httpversion);
}

fn setTraceConfig(token_in: [*:0]const u8) CURLcode {
    var result: CURLcode = CURLE_OK;
    var token_opt: ?[*:0]const u8 = token_in;

    while (token_opt) |token| {
        const next_opt = strChrZ(token, ',');
        var len: usize = if (next_opt) |nx| @intFromPtr(nx) - @intFromPtr(token) else std.mem.len(token);
        var toggle = true;
        var name: [*:0]const u8 = token;

        switch (token[0]) {
            '-' => {
                toggle = false;
                name = token + 1;
                len -= 1;
            },
            '+' => {
                toggle = true;
                name = token + 1;
                len -= 1;
            },
            else => {},
        }

        if (len == 3 and curl_strnequal(name, "all", 3) != 0) {
            setGlobBit(.traceids, toggle);
            setGlobBit(.tracetime, toggle);
            if (toggle)
                result = curl_global_trace("all,-lib-ids")
            else
                result = curl_global_trace(token);
            if (result != CURLE_OK)
                return result;
        } else if (len == 3 and curl_strnequal(name, "ids", 3) != 0) {
            setGlobBit(.traceids, toggle);
        } else if (len == 4 and curl_strnequal(name, "time", 4) != 0) {
            setGlobBit(.tracetime, toggle);
        } else {
            var buffer: [64]u8 = undefined;
            _ = curl_msnprintf(
                &buffer,
                buffer.len,
                "%c%.*s,-lib-ids",
                @as(c_int, if (toggle) '+' else '-'),
                @as(c_int, @intCast(len)),
                name,
            );
            result = curl_global_trace(@ptrCast(&buffer));
            if (result != CURLE_OK)
                return result;
        }

        if (next_opt) |nx| {
            var p = nx + 1;
            if (p[0] == ' ')
                p += 1;
            token_opt = p;
        } else {
            token_opt = null;
        }
    }
    return result;
}

pub export fn findlongopt(opt: [*:0]const u8) callconv(.c) ?*const LongShort {
    const target = std.mem.span(opt);
    var low: usize = 0;
    var high: usize = aliases.len;
    while (low < high) {
        const mid = low + (high - low) / 2;
        const mid_name = std.mem.span(aliases[mid].lname);
        switch (std.mem.order(u8, target, mid_name)) {
            .eq => return &aliases[mid],
            .lt => high = mid,
            .gt => low = mid + 1,
        }
    }
    return null;
}

var singles_table: [128 - ' ']?*const LongShort = @splat(null);
var singles_done: bool = false;

pub export fn findshortopt(letter_in: u8) callconv(.c) ?*const LongShort {
    if (letter_in >= 127 or letter_in <= ' ')
        return null;

    if (!singles_done) {
        for (&aliases) |*entry| {
            if (entry.letter != ' ') {
                singles_table[entry.letter - ' '] = entry;
            }
        }
        singles_done = true;
    }
    return singles_table[letter_in - ' '];
}

const TOSEntry = struct {
    name: []const u8,
    value: u8,
};

const tos_entries = [_]TOSEntry{
    .{ .name = "AF11", .value = 0x28 },
    .{ .name = "AF12", .value = 0x30 },
    .{ .name = "AF13", .value = 0x38 },
    .{ .name = "AF21", .value = 0x48 },
    .{ .name = "AF22", .value = 0x50 },
    .{ .name = "AF23", .value = 0x58 },
    .{ .name = "AF31", .value = 0x68 },
    .{ .name = "AF32", .value = 0x70 },
    .{ .name = "AF33", .value = 0x78 },
    .{ .name = "AF41", .value = 0x88 },
    .{ .name = "AF42", .value = 0x90 },
    .{ .name = "AF43", .value = 0x98 },
    .{ .name = "CE", .value = 0x03 },
    .{ .name = "CS0", .value = 0x00 },
    .{ .name = "CS1", .value = 0x20 },
    .{ .name = "CS2", .value = 0x40 },
    .{ .name = "CS3", .value = 0x60 },
    .{ .name = "CS4", .value = 0x80 },
    .{ .name = "CS5", .value = 0xa0 },
    .{ .name = "CS6", .value = 0xc0 },
    .{ .name = "CS7", .value = 0xe0 },
    .{ .name = "ECT0", .value = 0x02 },
    .{ .name = "ECT1", .value = 0x01 },
    .{ .name = "EF", .value = 0xb8 },
    .{ .name = "LE", .value = 0x04 },
    .{ .name = "LOWCOST", .value = 0x02 },
    .{ .name = "LOWDELAY", .value = 0x10 },
    .{ .name = "MINCOST", .value = 0x02 },
    .{ .name = "RELIABILITY", .value = 0x04 },
    .{ .name = "THROUGHPUT", .value = 0x08 },
    .{ .name = "VOICE-ADMIT", .value = 0xb0 },
};

fn findTos(name: [*:0]const u8) ?u8 {
    const target = std.mem.span(name);
    for (tos_entries) |entry| {
        if (std.mem.eql(u8, target, entry.name))
            return entry.value;
    }
    return null;
}

const MAX_QUERY_LEN: usize = 100000;

fn urlQuery(nextarg: [*:0]const u8, config: *OperationConfig) ParameterError {
    var size: usize = 0;
    var err: ParameterError = PARAM_OK;
    var query: ?[*:0]u8 = null;
    var dyn: Dynbuf = .{};
    curlx_dyn_init(&dyn, MAX_QUERY_LEN);

    if (nextarg[0] == '+') {
        query = cStrdup(nextarg + 1);
        if (query == null)
            err = PARAM_NO_MEM;
    } else {
        err = dataUrlencode(nextarg, &query, &size);
    }

    if (err == PARAM_OK) {
        const cfg_query_ptr = cfgStrPtr(config, .query);
        if (cfg_query_ptr.*) |existing_query| {
            const result = curlx_dyn_addf(&dyn, "%s&%s", existing_query, query.?);
            c.free(query);
            if (result != CURLE_OK) {
                err = PARAM_NO_MEM;
            } else {
                c.free(existing_query);
                cfg_query_ptr.* = curlx_dyn_ptr(&dyn);
            }
        } else {
            cfg_query_ptr.* = query;
        }
    }
    return err;
}

fn setData(cmd: cmdline_t, nextarg_in: [*:0]const u8, config: *OperationConfig) ParameterError {
    var nextarg = nextarg_in;
    var postdata: ?[*:0]u8 = null;
    var file: ?*anyopaque = null;
    var size: usize = 0;
    var err: ParameterError = PARAM_OK;

    if (cmd == C_DATA_URLENCODE) {
        err = dataUrlencode(nextarg, &postdata, &size);
        if (err != PARAM_OK)
            return err;
    } else if (nextarg[0] == '@' and cmd != C_DATA_RAW) {
        nextarg += 1;
        const stdin_ptr = tool_zig_stdin();
        if (std.mem.eql(u8, std.mem.span(nextarg), "-")) {
            file = stdin_ptr;
            if (cmd == C_DATA_BINARY)
                tool_zig_stdin_binmode();
        } else {
            file = toolFopen(nextarg, "rb");
            if (file == null) {
                errorf("Failed to open %s", nextarg);
                return PARAM_READ_ERROR;
            }
        }

        if (cmd == C_DATA_BINARY or cmd == C_JSON) {
            err = file2memory(&postdata, &size, file);
        } else {
            err = file2string(&postdata, file);
            if (postdata) |pd|
                size = std.mem.len(pd);
        }

        if (file != null and file != stdin_ptr)
            toolFclose(file);
        if (err != PARAM_OK)
            return err;

        if (postdata == null) {
            postdata = cStrdup("");
            if (postdata == null)
                return PARAM_NO_MEM;
        }
    } else {
        err = getstr(&postdata, nextarg, ALLOW_BLANK);
        if (err != PARAM_OK)
            return err;
        size = std.mem.len(postdata.?);
    }

    if (cmd == C_JSON)
        setCfgBit(config, .jsoned, true);

    const postdata_dyn = tool_zig_config_postdata_ptr(config);
    if (curlx_dyn_len(postdata_dyn) != 0 and err == PARAM_OK and cmd != C_JSON and
        curlx_dyn_addn(postdata_dyn, "&", 1) != CURLE_OK)
    {
        err = PARAM_NO_MEM;
    }

    if (err == PARAM_OK and curlx_dyn_addn(postdata_dyn, postdata, size) != CURLE_OK)
        err = PARAM_NO_MEM;

    c.free(postdata);
    cfgStrPtr(config, .postfields).* = curlx_dyn_ptr(postdata_dyn);
    return err;
}

fn setRate(nextarg: [*:0]const u8) ParameterError {
    var err: ParameterError = PARAM_OK;
    var p: [*:0]const u8 = nextarg;
    var denominator: curl_off_t = 0;
    var numerator: curl_off_t = 60 * 60 * 1000;

    if (curlx_str_number(&p, &denominator, CURL_OFF_T_MAX) != 0)
        return PARAM_BAD_NUMERIC;

    if (denominator < 1)
        return PARAM_BAD_USE;

    if (curlx_str_single(&p, '/') == 0) {
        var numunits: curl_off_t = 0;
        if (curlx_str_number(&p, &numunits, CURL_OFF_T_MAX) != 0)
            numunits = 1;

        switch (p[0]) {
            's' => numerator = 1000,
            'm' => numerator = 60 * 1000,
            'h' => {},
            'd' => numerator = 24 * 60 * 60 * 1000,
            else => {
                errorf("unsupported --rate unit");
                err = PARAM_BAD_USE;
            },
        }

        if (@divTrunc(CURL_OFF_T_MAX, numerator) < numunits) {
            errorf("too large --rate unit");
            err = PARAM_NUMBER_TOO_LARGE;
        } else {
            numerator *= numunits;
        }
    }

    if (err != PARAM_OK) {
        // keep err
    } else if (denominator > numerator) {
        err = PARAM_NUMBER_TOO_LARGE;
    } else {
        setGlobInt(.ms_per_transfer, @divTrunc(numerator, denominator));
    }
    return err;
}

fn addUrl(config: *OperationConfig, thisurl: [*:0]const u8, remote_noglob: bool) ParameterError {
    var err: ParameterError = PARAM_OK;
    const url_get_ptr = cfgGetoutPtr(config, .url_get);
    const url_list_ptr = cfgGetoutPtr(config, .url_list);

    if (url_get_ptr.* == null)
        url_get_ptr.* = url_list_ptr.*;

    while (url_get_ptr.*) |node| {
        if (!getoutBit(node, .urlset)) break;
        url_get_ptr.* = tool_zig_getout_next(node);
    }

    const url_node: *getout = if (url_get_ptr.*) |existing| existing else blk: {
        const created = new_getout(config) orelse return PARAM_NO_MEM;
        url_get_ptr.* = created;
        break :blk created;
    };

    err = getstr(getoutStrPtr(url_node, .url), thisurl, DENY_BLANK);
    setGetoutBit(url_node, .urlset, true);
    if (remote_noglob) {
        setGetoutBit(url_node, .useremote, true);
        setGetoutBit(url_node, .noglob, true);
    }
    if (err == PARAM_OK) {
        const num_urls = cfgInt(config, .num_urls) + 1;
        setCfgInt(config, .num_urls, num_urls);
        if (num_urls > 1 and
            (cfgStrPtr(config, .etag_save_file).* != null or cfgStrPtr(config, .etag_compare_file).* != null))
        {
            errorf("The etag options only work on a single URL");
            return PARAM_BAD_USE;
        }
    }
    return err;
}

fn parseUrl(config: *OperationConfig, nextarg: [*:0]const u8) ParameterError {
    if (nextarg[0] == '@') {
        var line: Dynbuf = .{};
        var err: ParameterError = PARAM_OK;
        var has_error = false;
        const fname = nextarg + 1;
        const fromstdin = std.mem.eql(u8, std.mem.span(fname), "-");
        const f = if (fromstdin) tool_zig_stdin() else toolFopen(fname, FOPEN_READTEXT);
        if (f != null) {
            curlx_dyn_init(&line, 8092);
            while (my_get_line(f, &line, &has_error)) {
                const ptr = curlx_dyn_ptr(&line) orelse "";
                err = addUrl(config, ptr, true);
                if (err != PARAM_OK)
                    break;
            }
            if (!fromstdin)
                toolFclose(f);
            curlx_dyn_free(&line);
            if (has_error or err != PARAM_OK)
                return PARAM_READ_ERROR;
            return PARAM_OK;
        }
        return PARAM_READ_ERROR;
    }
    return addUrl(config, nextarg, false);
}

inline fn isDigit(ch: u8) bool {
    return ch >= '0' and ch <= '9';
}

inline fn isBlank(ch: u8) bool {
    return ch == ' ' or ch == '\t';
}

fn parseLocalport(config: *OperationConfig, nextarg: [*:0]const u8) ParameterError {
    var pp: ?[*:0]const u8 = null;
    var p: [*:0]const u8 = nextarg;
    var buffer: [22]u8 = undefined;

    while (isDigit(p[0]))
        p += 1;
    const plen = @intFromPtr(p) - @intFromPtr(nextarg);
    if (p[0] != 0) {
        var cur = p;
        if (isBlank(cur[0]))
            cur += 1;
        if (cur[0] != '-')
            return PARAM_BAD_USE;
        cur += 1;
        if (isBlank(cur[0]))
            cur += 1;
        pp = cur;
    }
    _ = curl_msnprintf(&buffer, buffer.len, "%.*s", @as(c_int, @intCast(plen)), nextarg);
    var localport: c_long = @intCast(cfgInt(config, .localport));
    if (str2unummax(&localport, @ptrCast(&buffer), 65535) != PARAM_OK)
        return PARAM_BAD_USE;
    setCfgInt(config, .localport, localport);

    if (pp == null) {
        setCfgInt(config, .localportrange, 1);
    } else {
        var range: c_long = @intCast(cfgInt(config, .localportrange));
        if (str2unummax(&range, pp.?, 65535) != PARAM_OK)
            return PARAM_BAD_USE;
        range -= (localport - 1);
        setCfgInt(config, .localportrange, range);
        if (range < 1)
            return PARAM_BAD_USE;
    }
    return PARAM_OK;
}

fn parseContinueAt(config: *OperationConfig, nextarg: [*:0]const u8) ParameterError {
    var err: ParameterError = PARAM_OK;
    if (cfgStrPtr(config, .range).* != null) {
        errorf("--continue-at is mutually exclusive with --range");
        return PARAM_BAD_USE;
    }
    if (cfgBit(config, .rm_partial)) {
        errorf("--continue-at is mutually exclusive with --remove-on-error");
        return PARAM_BAD_USE;
    }
    if (cfgInt(config, .file_clobber_mode) == CLOBBER_NEVER) {
        errorf("--continue-at is mutually exclusive with --no-clobber");
        return PARAM_BAD_USE;
    }
    if (!std.mem.eql(u8, std.mem.span(nextarg), "-")) {
        var resume_from: curl_off_t = cfgInt(config, .resume_from);
        err = str2offset(&resume_from, nextarg);
        setCfgInt(config, .resume_from, resume_from);
        setCfgBit(config, .resume_from_current, false);
    } else {
        setCfgBit(config, .resume_from_current, true);
        setCfgInt(config, .resume_from, 0);
    }
    setCfgBit(config, .use_resume, true);
    return err;
}

fn parseEch(config: *OperationConfig, nextarg_in: [*:0]const u8) ParameterError {
    var nextarg = nextarg_in;
    var err: ParameterError = PARAM_OK;
    const len = std.mem.len(nextarg);
    if (!feature_ech) {
        err = PARAM_LIBCURL_DOESNT_SUPPORT;
    } else if (len > 4 and curl_strnequal("pn:", nextarg, 3) != 0) {
        err = getstr(cfgStrPtr(config, .ech_public), nextarg, DENY_BLANK);
    } else if (len > 5 and curl_strnequal("ecl:", nextarg, 4) != 0) {
        if (nextarg[4] != '@') {
            err = getstr(cfgStrPtr(config, .ech_config), nextarg, DENY_BLANK);
        } else {
            var tmpcfg: ?[*:0]u8 = null;
            nextarg += 5;
            const stdin_ptr = tool_zig_stdin();
            const file = if (std.mem.eql(u8, std.mem.span(nextarg), "-"))
                stdin_ptr
            else
                toolFopen(nextarg, FOPEN_READTEXT);
            if (file == null) {
                warnf("Could not read file \"%s\" specified for \"--ech ecl:\" option", nextarg);
                return PARAM_BAD_USE;
            }
            err = file2string(&tmpcfg, file);
            if (file != stdin_ptr)
                toolFclose(file);
            if (err != PARAM_OK)
                return err;
            const tmp = curl_maprintf("ecl:%s", tmpcfg);
            c.free(tmpcfg);
            if (tmp == null)
                return PARAM_NO_MEM;
            const dup = cStrdup(tmp.?);
            curl_free(tmp);
            cfgStrPtr(config, .ech_config).* = dup;
            if (dup == null)
                return PARAM_NO_MEM;
        }
    } else {
        err = getstr(cfgStrPtr(config, .ech), nextarg, DENY_BLANK);
    }
    return err;
}

fn parseHeader(config: *OperationConfig, cmd: cmdline_t, nextarg: [*:0]const u8) ParameterError {
    var err: ParameterError = PARAM_OK;
    if (nextarg[0] == '@') {
        const fname = nextarg + 1;
        const use_stdin = std.mem.eql(u8, std.mem.span(fname), "-");
        const file = if (use_stdin) tool_zig_stdin() else toolFopen(fname, FOPEN_READTEXT);
        if (file == null) {
            errorf("Failed to open %s", fname);
            err = PARAM_READ_ERROR;
        } else {
            var line: Dynbuf = .{};
            var has_error = false;
            curlx_dyn_init(&line, 1024 * 100);
            while (my_get_line(file, &line, &has_error)) {
                const ptr = curlx_dyn_ptr(&line) orelse "";
                err = add2list(
                    cfgSlistPtr(config, if (cmd == C_PROXY_HEADER) .proxyheaders else .headers),
                    ptr,
                );
                if (err != PARAM_OK)
                    break;
            }
            if (has_error)
                err = PARAM_READ_ERROR;
            curlx_dyn_free(&line);
            if (!use_stdin)
                toolFclose(file);
        }
    } else {
        if (strChrZ(nextarg, ':') == null and strChrZ(nextarg, ';') == null) {
            warnf(
                "The provided %s header '%s' does not look like a header?",
                @as([*:0]const u8, if (cmd == C_PROXY_HEADER) "proxy" else "HTTP"),
                nextarg,
            );
        }
        err = add2list(
            cfgSlistPtr(config, if (cmd == C_PROXY_HEADER) .proxyheaders else .headers),
            nextarg,
        );
    }
    return err;
}

fn parseOutput(config: *OperationConfig, nextarg: ?[*:0]const u8) ParameterError {
    var err: ParameterError = PARAM_OK;
    const url_out_ptr = cfgGetoutPtr(config, .url_out);
    const url_list_ptr = cfgGetoutPtr(config, .url_list);

    if (url_out_ptr.* == null)
        url_out_ptr.* = url_list_ptr.*;
    while (url_out_ptr.*) |node| {
        if (!getoutBit(node, .outset)) break;
        url_out_ptr.* = tool_zig_getout_next(node);
    }

    const url_node: *getout = if (url_out_ptr.*) |existing| existing else blk: {
        const created = new_getout(config) orelse return PARAM_NO_MEM;
        url_out_ptr.* = created;
        break :blk created;
    };

    if (nextarg) |na| {
        err = getstr(getoutStrPtr(url_node, .outfile), na, DENY_BLANK);
    } else {
        getoutStrPtr(url_node, .outfile).* = null;
    }
    setGetoutBit(url_node, .useremote, false);
    setGetoutBit(url_node, .outset, true);
    setGetoutBit(url_node, .out_null, nextarg == null);
    return err;
}

fn parseRemoteName(config: *OperationConfig, toggle: bool) ParameterError {
    if (!toggle and !cfgBit(config, .remote_name_all))
        return PARAM_OK;

    const url_out_ptr = cfgGetoutPtr(config, .url_out);
    const url_list_ptr = cfgGetoutPtr(config, .url_list);

    if (url_out_ptr.* == null)
        url_out_ptr.* = url_list_ptr.*;
    while (url_out_ptr.*) |node| {
        if (!getoutBit(node, .outset)) break;
        url_out_ptr.* = tool_zig_getout_next(node);
    }

    const url_node: *getout = if (url_out_ptr.*) |existing| existing else blk: {
        const created = new_getout(config) orelse return PARAM_NO_MEM;
        url_out_ptr.* = created;
        break :blk created;
    };

    getoutStrPtr(url_node, .outfile).* = null;
    setGetoutBit(url_node, .useremote, toggle);
    setGetoutBit(url_node, .outset, true);
    setGetoutBit(url_node, .out_null, false);
    return PARAM_OK;
}

fn parseQuote(config: *OperationConfig, nextarg: [*:0]const u8) ParameterError {
    return switch (nextarg[0]) {
        '-' => add2list(cfgSlistPtr(config, .postquote), nextarg + 1),
        '+' => add2list(cfgSlistPtr(config, .prequote), nextarg + 1),
        else => add2list(cfgSlistPtr(config, .quote), nextarg),
    };
}

fn parseRange(config: *OperationConfig, nextarg_in: [*:0]const u8) ParameterError {
    var nextarg = nextarg_in;
    var err: ParameterError = PARAM_OK;
    var value: curl_off_t = 0;
    const orig = nextarg;

    if (cfgBit(config, .use_resume)) {
        errorf("--continue-at is mutually exclusive with --range");
        return PARAM_BAD_USE;
    }
    if (curlx_str_number(&nextarg, &value, CURL_OFF_T_MAX) == 0 and
        curlx_str_single(&nextarg, '-') != 0)
    {
        var buffer: [32]u8 = undefined;
        warnf("A specified range MUST include at least one dash (-). Appending one for you");
        const slice = std.fmt.bufPrint(buffer[0 .. buffer.len - 1], "{d}-", .{value}) catch unreachable;
        buffer[slice.len] = 0;
        cfgStrFree(config, .range);
        const dup = cStrdup(@ptrCast(&buffer));
        cfgStrPtr(config, .range).* = dup;
        if (dup == null)
            err = PARAM_NO_MEM;
    } else {
        while (nextarg[0] != 0) : (nextarg += 1) {
            if (!isDigit(nextarg[0]) and nextarg[0] != '-' and nextarg[0] != ',') {
                warnf("Invalid character is found in given range. A specified range MUST have only digits in 'start'-'stop'. The server's response to this request is uncertain.");
                break;
            }
        }
        err = getstr(cfgStrPtr(config, .range), orig, DENY_BLANK);
    }
    return err;
}

fn parseUploadFile(config: *OperationConfig, nextarg: [*:0]const u8) ParameterError {
    var err: ParameterError = PARAM_OK;
    const url_ul_ptr = cfgGetoutPtr(config, .url_ul);
    const url_list_ptr = cfgGetoutPtr(config, .url_list);

    if (url_ul_ptr.* == null)
        url_ul_ptr.* = url_list_ptr.*;
    while (url_ul_ptr.*) |node| {
        if (!getoutBit(node, .uploadset)) break;
        url_ul_ptr.* = tool_zig_getout_next(node);
    }

    const url_node: *getout = if (url_ul_ptr.*) |existing| existing else blk: {
        const created = new_getout(config) orelse return PARAM_NO_MEM;
        url_ul_ptr.* = created;
        break :blk created;
    };

    setGetoutBit(url_node, .uploadset, true);
    if (nextarg[0] == 0) {
        setGetoutBit(url_node, .noupload, true);
    } else {
        err = getstr(getoutStrPtr(url_node, .infile), nextarg, DENY_BLANK);
    }
    return err;
}

var verbose_nopts: usize = 0;

fn parseVerbose(toggle: bool) ParameterError {
    var err: ParameterError = PARAM_OK;

    if (!toggle) {
        setGlobInt(.verbosity, 0);
        if (setTraceConfig("-all") != CURLE_OK)
            err = PARAM_NO_MEM;
        setGlobInt(.tracetype, TRACE_NONE);
        return err;
    } else if (verbose_nopts == 0) {
        setGlobInt(.verbosity, 0);
        if (!globBit(.trace_set) and setTraceConfig("-all") != CURLE_OK)
            return PARAM_NO_MEM;
    }

    switch (globInt(.verbosity)) {
        0 => {
            setGlobInt(.verbosity, 1);
            const td_ptr = globStrPtr(.trace_dump);
            c.free(td_ptr.*);
            td_ptr.* = cStrdup("%");
            if (td_ptr.* == null) {
                err = PARAM_NO_MEM;
            } else {
                const tt = globInt(.tracetype);
                if (tt != 0 and tt != TRACE_PLAIN)
                    warnf("-v, --verbose overrides an earlier trace option");
                setGlobInt(.tracetype, TRACE_PLAIN);
            }
        },
        1 => {
            setGlobInt(.verbosity, 2);
            if (setTraceConfig("ids,time,protocol") != CURLE_OK)
                err = PARAM_NO_MEM;
        },
        2 => {
            setGlobInt(.verbosity, 3);
            setGlobInt(.tracetype, TRACE_ASCII);
            if (setTraceConfig("ssl,read,write") != CURLE_OK)
                err = PARAM_NO_MEM;
        },
        3 => {
            setGlobInt(.verbosity, 4);
            if (setTraceConfig("network") != CURLE_OK)
                err = PARAM_NO_MEM;
        },
        else => {},
    }
    return err;
}

fn parseWriteout(config: *OperationConfig, nextarg_in: [*:0]const u8) ParameterError {
    var nextarg = nextarg_in;
    var err: ParameterError = PARAM_OK;

    if (nextarg[0] == '@') {
        var file: ?*anyopaque = null;
        var fname: [*:0]const u8 = undefined;
        nextarg += 1;
        const stdin_ptr = tool_zig_stdin();
        if (std.mem.eql(u8, std.mem.span(nextarg), "-")) {
            fname = "<stdin>";
            file = stdin_ptr;
        } else {
            fname = nextarg;
            file = toolFopen(fname, FOPEN_READTEXT);
            if (file == null) {
                errorf("Failed to open %s", fname);
                return PARAM_READ_ERROR;
            }
        }
        cfgStrFree(config, .writeout);
        err = file2string(cfgStrPtr(config, .writeout), file);
        if (file != null and file != stdin_ptr)
            toolFclose(file);
        if (err != PARAM_OK)
            return err;
        if (cfgStrPtr(config, .writeout).* == null)
            warnf("Failed to read %s", fname);
    } else {
        err = getstr(cfgStrPtr(config, .writeout), nextarg, ALLOW_BLANK);
    }
    return err;
}

fn parseTimeCond(config: *OperationConfig, nextarg_in: [*:0]const u8) ParameterError {
    var nextarg = nextarg_in;
    switch (nextarg[0]) {
        '+' => {
            nextarg += 1;
            setCfgInt(config, .timecond, CURL_TIMECOND_IFMODSINCE);
        },
        '-' => {
            setCfgInt(config, .timecond, CURL_TIMECOND_IFUNMODSINCE);
            nextarg += 1;
        },
        '=' => {
            setCfgInt(config, .timecond, CURL_TIMECOND_LASTMOD);
            nextarg += 1;
        },
        else => {
            setCfgInt(config, .timecond, CURL_TIMECOND_IFMODSINCE);
        },
    }
    const condtime: curl_off_t = @intCast(curl_getdate(nextarg, null));
    setCfgInt(config, .condtime, condtime);
    if (condtime == -1) {
        var value: curl_off_t = 0;
        const rc = getfiletime(nextarg, &value);
        if (rc == 0) {
            setCfgInt(config, .condtime, value);
        } else {
            setCfgInt(config, .timecond, CURL_TIMECOND_NONE);
            warnf("Illegal date format for -z, --time-cond (and not a filename). Disabling time condition. See curl_getdate(3) for valid date syntax.");
        }
    }
    return PARAM_OK;
}

const FlagMap = struct {
    name: []const u8,
    flag: u8,
};

const flag_table = [_]FlagMap{
    .{ .name = "answered", .flag = CURLULFLAG_ANSWERED },
    .{ .name = "deleted", .flag = CURLULFLAG_DELETED },
    .{ .name = "draft", .flag = CURLULFLAG_DRAFT },
    .{ .name = "flagged", .flag = CURLULFLAG_FLAGGED },
    .{ .name = "seen", .flag = CURLULFLAG_SEEN },
};

fn parseUploadFlags(config: *OperationConfig, flag_in: [*:0]const u8) ParameterError {
    var flag_opt: ?[*:0]const u8 = flag_in;

    while (flag_opt) |flag_cur| {
        var flag = flag_cur;
        const next_opt = strChrZ(flag, ',');
        var len: usize = if (next_opt) |nx| @intFromPtr(nx) - @intFromPtr(flag) else std.mem.len(flag);

        const negate = (flag[0] == '-');
        if (negate) {
            flag += 1;
            len -= 1;
        }

        var matched = false;
        const token = flag[0..len];
        for (flag_table) |map| {
            if (std.mem.eql(u8, token, map.name)) {
                var cur_flags: u8 = @intCast(cfgInt(config, .upload_flags));
                if (negate)
                    cur_flags &= ~map.flag
                else
                    cur_flags |= map.flag;
                setCfgInt(config, .upload_flags, cur_flags);
                matched = true;
                break;
            }
        }

        if (!matched)
            return PARAM_OPTION_UNKNOWN;

        flag_opt = if (next_opt) |nx| nx + 1 else null;
    }
    return PARAM_OK;
}

fn toggleCfgIntBits(config: *OperationConfig, field: CfgInt, toggle: bool, bits: c_ulong) void {
    var val: c_ulong = @intCast(cfgInt(config, field));
    if (toggle)
        val |= bits
    else
        val &= ~bits;
    setCfgInt(config, field, val);
}

fn optDepr(a: *const LongShort) void {
    warnf("--%s is deprecated and has no function anymore", a.lname);
}

fn optSslver(config: *OperationConfig, ver: u8) ParameterError {
    const max_ver: u8 = @intCast(cfgInt(config, .ssl_version_max));
    if (max_ver != 0 and max_ver < ver) {
        errorf("Minimum TLS version set higher than max");
        return PARAM_BAD_USE;
    }
    setCfgInt(config, .ssl_version, ver);
    return PARAM_OK;
}

fn optNone(config: *OperationConfig, a: *const LongShort) ParameterError {
    var err: ParameterError = PARAM_OK;
    switch (a.cmd) {
        C_ANYAUTH => setCfgInt(config, .authtype, CURLAUTH_ANY),
        C_DUMP_CA_EMBED => return PARAM_CA_EMBED_REQUESTED,
        C_FTP_PASV => cfgStrFree(config, .ftpport),
        C_HTTP1_0 => sethttpver(config, CURL_HTTP_VERSION_1_0),
        C_HTTP1_1 => sethttpver(config, CURL_HTTP_VERSION_1_1),
        C_HTTP2 => {
            if (!feature_http2) return PARAM_LIBCURL_DOESNT_SUPPORT;
            sethttpver(config, CURL_HTTP_VERSION_2_0);
        },
        C_HTTP2_PRIOR_KNOWLEDGE => {
            if (!feature_http2) return PARAM_LIBCURL_DOESNT_SUPPORT;
            sethttpver(config, CURL_HTTP_VERSION_2_PRIOR_KNOWLEDGE);
        },
        C_HTTP3 => {
            if (!feature_http3) return PARAM_LIBCURL_DOESNT_SUPPORT;
            sethttpver(config, CURL_HTTP_VERSION_3);
        },
        C_HTTP3_ONLY => {
            if (!feature_http3) return PARAM_LIBCURL_DOESNT_SUPPORT;
            sethttpver(config, CURL_HTTP_VERSION_3ONLY);
        },
        C_TLSV1, C_TLSV1_0 => err = optSslver(config, 1),
        C_TLSV1_1 => err = optSslver(config, 2),
        C_TLSV1_2 => err = optSslver(config, 3),
        C_TLSV1_3 => err = optSslver(config, 4),
        C_IPV4 => setCfgInt(config, .ip_version, CURL_IPRESOLVE_V4),
        C_IPV6 => setCfgInt(config, .ip_version, CURL_IPRESOLVE_V6),
        C_NEXT => return PARAM_NEXT_OPERATION,
        C_PROXY_TLSV1 => setCfgInt(config, .proxy_ssl_version, CURL_SSLVERSION_TLSv1),
        else => {},
    }
    return err;
}

fn optBool(config: *OperationConfig, a: *const LongShort, toggle: bool) ParameterError {
    switch (a.cmd) {
        C_ALPN => setCfgBit(config, .noalpn, !toggle),
        C_DISABLE_EPSV => setCfgBit(config, .disable_epsv, toggle),
        C_DISALLOW_USERNAME_IN_URL => setCfgBit(config, .disallow_username_in_url, toggle),
        C_EPSV => setCfgBit(config, .disable_epsv, !toggle),
        C_COMPRESSED => {
            if (toggle and !(feature_libz or feature_brotli or feature_zstd))
                return PARAM_LIBCURL_DOESNT_SUPPORT;
            setCfgBit(config, .encoding, toggle);
        },
        C_TR_ENCODING => setCfgBit(config, .tr_encoding, toggle),
        C_DIGEST => toggleCfgIntBits(config, .authtype, toggle, CURLAUTH_DIGEST),
        C_FTP_CREATE_DIRS => setCfgBit(config, .ftp_create_dirs, toggle),
        C_CREATE_DIRS => setCfgBit(config, .create_dirs, toggle),
        C_PROXY_NTLM => {
            if (!feature_ntlm) return PARAM_LIBCURL_DOESNT_SUPPORT;
            setCfgBit(config, .proxyntlm, toggle);
        },
        C_CRLF => setCfgBit(config, .crlf, toggle),
        C_HAPROXY_PROTOCOL => setCfgBit(config, .haproxy_protocol, toggle),
        C_NEGOTIATE => {
            if (!feature_spnego and toggle) return PARAM_LIBCURL_DOESNT_SUPPORT;
            toggleCfgIntBits(config, .authtype, toggle, CURLAUTH_NEGOTIATE);
        },
        C_NTLM => {
            if (!feature_ntlm and toggle) return PARAM_LIBCURL_DOESNT_SUPPORT;
            toggleCfgIntBits(config, .authtype, toggle, CURLAUTH_NTLM);
        },
        C_OUT_NULL => return parseOutput(config, null),
        C_BASIC => toggleCfgIntBits(config, .authtype, toggle, CURLAUTH_BASIC),
        C_DISABLE_EPRT => setCfgBit(config, .disable_eprt, toggle),
        C_EPRT => setCfgBit(config, .disable_eprt, !toggle),
        C_XATTR => setCfgBit(config, .xattr, toggle),
        C_FTP_SSL, C_SSL => {
            setCfgBit(config, .ftp_ssl, toggle);
            if (cfgBit(config, .ftp_ssl))
                warnf("--%s is an insecure option, consider --ssl-reqd instead", a.lname);
            if (toggle and cfgBit(config, .ftp_ssl_control)) {
                setCfgBit(config, .ftp_ssl_control, false);
                warnf("--%s overrides --ftp-ssl-control", a.lname);
            }
        },
        C_FTP_SSL_CCC => {
            setCfgBit(config, .ftp_ssl_ccc, toggle);
            if (cfgInt(config, .ftp_ssl_ccc_mode) == 0)
                setCfgInt(config, .ftp_ssl_ccc_mode, CURLFTPSSL_CCC_PASSIVE);
        },
        C_TCP_NODELAY => setCfgBit(config, .tcp_nodelay, toggle),
        C_PROXY_DIGEST => setCfgBit(config, .proxydigest, toggle),
        C_PROXY_BASIC => setCfgBit(config, .proxybasic, toggle),
        C_RETRY_CONNREFUSED => setCfgBit(config, .retry_connrefused, toggle),
        C_RETRY_ALL_ERRORS => setCfgBit(config, .retry_all_errors, toggle),
        C_PROXY_NEGOTIATE => {
            if (!feature_spnego) return PARAM_LIBCURL_DOESNT_SUPPORT;
            setCfgBit(config, .proxynegotiate, toggle);
        },
        C_FORM_ESCAPE => toggleCfgIntBits(config, .mime_options, toggle, CURLMIMEOPT_FORMESCAPE),
        C_PROXY_ANYAUTH => setCfgBit(config, .proxyanyauth, toggle),
        C_TRACE_TIME => setGlobBit(.tracetime, toggle),
        C_IGNORE_CONTENT_LENGTH => setCfgBit(config, .ignorecl, toggle),
        C_FTP_SKIP_PASV_IP => setCfgBit(config, .ftp_skip_ip, toggle),
        C_FTP_SSL_REQD, C_SSL_REQD => setCfgBit(config, .ftp_ssl_reqd, toggle),
        C_SESSIONID => setCfgBit(config, .disable_sessionid, !toggle),
        C_FTP_SSL_CONTROL => {
            setCfgBit(config, .ftp_ssl_control, toggle);
            if (toggle and cfgBit(config, .ftp_ssl)) {
                setCfgBit(config, .ftp_ssl, false);
                warnf("--%s overrides --ssl", a.lname);
            }
        },
        C_RAW => setCfgBit(config, .raw, toggle),
        C_KEEPALIVE => setCfgBit(config, .nokeepalive, !toggle),
        C_POST301 => setCfgBit(config, .post301, toggle),
        C_POST302 => setCfgBit(config, .post302, toggle),
        C_POST303 => setCfgBit(config, .post303, toggle),
        C_SOCKS5_GSSAPI_NEC => setCfgBit(config, .socks5_gssapi_nec, toggle),
        C_FTP_PRET => setCfgBit(config, .ftp_pret, toggle),
        C_SASL_IR => setCfgBit(config, .sasl_ir, toggle),
        C_PATH_AS_IS => setCfgBit(config, .path_as_is, toggle),
        C_TFTP_NO_OPTIONS => setCfgBit(config, .tftp_no_options, toggle),
        C_TLS_EARLYDATA => setCfgBit(config, .ssl_allow_earlydata, toggle),
        C_SUPPRESS_CONNECT_HEADERS => setCfgBit(config, .suppress_connect_headers, toggle),
        C_COMPRESSED_SSH => setCfgBit(config, .ssh_compression, toggle),
        C_TRACE_IDS => setGlobBit(.traceids, toggle),
        C_PROGRESS_METER => setGlobBit(.noprogress, !toggle),
        C_PROGRESS_BAR => setGlobInt(.progressmode, if (toggle) CURL_PROGRESS_BAR else CURL_PROGRESS_STATS),
        C_HTTP0_9 => setCfgBit(config, .http09_allowed, toggle),
        C_PROXY_HTTP2 => {
            if (!feature_httpsproxy or !feature_http2)
                return PARAM_LIBCURL_DOESNT_SUPPORT;
            setCfgInt(config, .proxyver, if (toggle) CURLPROXY_HTTPS2 else CURLPROXY_HTTPS);
        },
        C_PROXY_HTTP3 => {
            if (toggle)
                return PARAM_LIBCURL_DOESNT_SUPPORT;
            setCfgInt(config, .proxyver, CURLPROXY_HTTPS);
        },
        C_APPEND => setCfgBit(config, .ftp_append, toggle),
        C_USE_ASCII => setCfgBit(config, .use_ascii, toggle),
        C_CA_NATIVE => setCfgBit(config, .native_ca_store, toggle),
        C_PROXY_CA_NATIVE => setCfgBit(config, .proxy_native_ca_store, toggle),
        C_SSL_ALLOW_BEAST => setCfgBit(config, .ssl_allow_beast, toggle),
        C_SSL_AUTO_CLIENT_CERT => setCfgBit(config, .ssl_auto_client_cert, toggle),
        C_PROXY_SSL_AUTO_CLIENT_CERT => setCfgBit(config, .proxy_ssl_auto_client_cert, toggle),
        C_CERT_STATUS => setCfgBit(config, .verifystatus, toggle),
        C_DOH_CERT_STATUS => setCfgBit(config, .doh_verifystatus, toggle),
        C_FALSE_START => optDepr(a),
        C_SSL_NO_REVOKE => setCfgBit(config, .ssl_no_revoke, toggle),
        C_SSL_REVOKE_BEST_EFFORT => setCfgBit(config, .ssl_revoke_best_effort, toggle),
        C_TCP_FASTOPEN => setCfgBit(config, .tcp_fastopen, toggle),
        C_PROXY_SSL_ALLOW_BEAST => setCfgBit(config, .proxy_ssl_allow_beast, toggle),
        C_PROXY_INSECURE => setCfgBit(config, .proxy_insecure_ok, toggle),
        C_SOCKS5_BASIC => toggleCfgIntBits(config, .socks5_auth, toggle, CURLAUTH_BASIC),
        C_SOCKS5_GSSAPI => toggleCfgIntBits(config, .socks5_auth, toggle, CURLAUTH_GSSAPI),
        C_FAIL_EARLY => setGlobBit(.fail_early, toggle),
        C_STYLED_OUTPUT => setGlobBit(.styled_output, toggle),
        C_MAIL_RCPT_ALLOWFAILS => setCfgBit(config, .mail_rcpt_allowfails, toggle),
        C_REMOVE_ON_ERROR => {
            if (cfgBit(config, .use_resume) and toggle) {
                errorf("--continue-at is mutually exclusive with --remove-on-error");
                return PARAM_BAD_USE;
            }
            setCfgBit(config, .rm_partial, toggle);
        },
        C_FAIL => {
            if (toggle and cfgInt(config, .fail) == FAIL_WITH_BODY)
                warnf("--fail deselects --fail-with-body here");
            setCfgInt(config, .fail, if (toggle) FAIL_WO_BODY else FAIL_NONE);
        },
        C_FAIL_WITH_BODY => {
            if (toggle and cfgInt(config, .fail) == FAIL_WO_BODY)
                warnf("--fail-with-body deselects --fail here");
            setCfgInt(config, .fail, if (toggle) FAIL_WITH_BODY else FAIL_NONE);
        },
        C_GLOBOFF => setCfgBit(config, .globoff, toggle),
        C_GET => setCfgBit(config, .use_httpget, toggle),
        C_INCLUDE, C_SHOW_HEADERS => setCfgBit(config, .show_headers, toggle),
        C_JUNK_SESSION_COOKIES => setCfgBit(config, .cookiesession, toggle),
        C_HEAD => {
            setCfgBit(config, .no_body, toggle);
            setCfgBit(config, .show_headers, toggle);
            var httpreq: HttpReq = @intCast(cfgInt(config, .httpreq));
            if (SetHTTPrequest(if (toggle) TOOL_HTTPREQ_HEAD else TOOL_HTTPREQ_GET, &httpreq) != 0) {
                setCfgInt(config, .httpreq, httpreq);
                return PARAM_BAD_USE;
            }
            setCfgInt(config, .httpreq, httpreq);
        },
        C_REMOTE_HEADER_NAME => {
            setCfgBit(config, .content_disposition, toggle);
            setCfgBit(config, .suppress_connect_headers, toggle);
        },
        C_INSECURE => setCfgBit(config, .insecure_ok, toggle),
        C_DOH_INSECURE => setCfgBit(config, .doh_insecure_ok, toggle),
        C_LIST_ONLY => setCfgBit(config, .dirlistonly, toggle),
        C_MANUAL => {
            if (toggle) return PARAM_MANUAL_REQUESTED;
        },
        C_NETRC_OPTIONAL => setCfgBit(config, .netrc_opt, toggle),
        C_NETRC => setCfgBit(config, .netrc, toggle),
        C_BUFFER => setCfgBit(config, .nobuffer, !toggle),
        C_REMOTE_NAME_ALL => setCfgBit(config, .remote_name_all, toggle),
        C_CLOBBER => {
            if (cfgBit(config, .use_resume) and !toggle) {
                errorf("--continue-at is mutually exclusive with --no-clobber");
                return PARAM_BAD_USE;
            }
            setCfgInt(config, .file_clobber_mode, if (toggle) CLOBBER_ALWAYS else CLOBBER_NEVER);
        },
        C_REMOTE_NAME => return parseRemoteName(config, toggle),
        C_PROXYTUNNEL => setCfgBit(config, .proxytunnel, toggle),
        C_DISABLE => {},
        C_REMOTE_TIME => setCfgBit(config, .remote_time, toggle),
        C_SILENT => setGlobBit(.silent, toggle),
        C_SKIP_EXISTING => setCfgBit(config, .skip_existing, toggle),
        C_SHOW_ERROR => setGlobBit(.showerror, toggle),
        C_VERBOSE => return parseVerbose(toggle),
        C_VERSION => {
            if (toggle) return PARAM_VERSION_INFO_REQUESTED;
        },
        C_PARALLEL => setGlobBit(.parallel, toggle),
        C_PARALLEL_IMMEDIATE => setGlobBit(.parallel_connect, toggle),
        C_MPTCP => setCfgBit(config, .mptcp, toggle),
        C_LOCATION_TRUSTED => {
            setCfgBit(config, .unrestricted_auth, toggle);
            if (cfgInt(config, .followlocation) == CURLFOLLOW_OBEYCODE)
                warnf("--location overrides --follow");
            setCfgInt(config, .followlocation, if (toggle) CURLFOLLOW_ALL else 0);
        },
        C_LOCATION => {
            if (cfgInt(config, .followlocation) == CURLFOLLOW_OBEYCODE)
                warnf("--location overrides --follow");
            setCfgInt(config, .followlocation, if (toggle) CURLFOLLOW_ALL else 0);
        },
        C_FOLLOW => {
            if (cfgInt(config, .followlocation) == CURLFOLLOW_ALL)
                warnf("--follow overrides --location");
            setCfgInt(config, .followlocation, if (toggle) CURLFOLLOW_OBEYCODE else 0);
        },
        else => return PARAM_OPTION_UNKNOWN,
    }
    return PARAM_OK;
}

fn existingFile(store: *?[*:0]u8, a: *const LongShort, filename: [*:0]const u8) ParameterError {
    if (!tool_zig_existingfile(filename)) {
        errorf("The file '%s' provided to --%s does not exist", filename, a.lname);
        return PARAM_BAD_USE;
    }
    return getstr(store, filename, DENY_BLANK);
}

fn optFile(
    config: *OperationConfig,
    a: *const LongShort,
    nextarg: [*:0]const u8,
    max_recursive_in: c_int,
) ParameterError {
    var max_recursive = max_recursive_in;
    var err: ParameterError = PARAM_OK;
    if (nextarg[0] == '-' and nextarg[1] != 0) {
        warnf("The filename argument '%s' looks like a flag.", nextarg);
    }
    switch (a.cmd) {
        C_ABSTRACT_UNIX_SOCKET => {
            setCfgBit(config, .abstract_unix_socket, true);
            err = getstr(cfgStrPtr(config, .unix_socket_path), nextarg, DENY_BLANK);
        },
        C_CACERT => err = existingFile(cfgStrPtr(config, .cacert), a, nextarg),
        C_CAPATH => err = getstr(cfgStrPtr(config, .capath), nextarg, DENY_BLANK),
        C_CERT => err = GetFileAndPassword(nextarg, cfgStrPtr(config, .cert), cfgStrPtr(config, .key_passwd)),
        C_CONFIG => {
            max_recursive -= 1;
            if (max_recursive < 0) {
                errorf("Max config file recursion level reached (%d)", CONFIG_MAX_LEVELS);
                err = PARAM_BAD_USE;
            } else {
                err = parseconfig(nextarg, max_recursive, null);
            }
        },
        C_CRLFILE => err = existingFile(cfgStrPtr(config, .crlfile), a, nextarg),
        C_DUMP_HEADER => err = getstr(cfgStrPtr(config, .headerfile), nextarg, DENY_BLANK),
        C_ETAG_SAVE => {
            if (cfgInt(config, .num_urls) > 1) {
                errorf("The etag options only work on a single URL");
                err = PARAM_BAD_USE;
            } else {
                err = getstr(cfgStrPtr(config, .etag_save_file), nextarg, DENY_BLANK);
            }
        },
        C_ETAG_COMPARE => {
            if (cfgInt(config, .num_urls) > 1) {
                errorf("The etag options only work on a single URL");
                err = PARAM_BAD_USE;
            } else {
                err = getstr(cfgStrPtr(config, .etag_compare_file), nextarg, DENY_BLANK);
            }
        },
        C_KEY => err = getstr(cfgStrPtr(config, .key), nextarg, DENY_BLANK),
        C_KNOWNHOSTS => err = existingFile(cfgStrPtr(config, .knownhosts), a, nextarg),
        C_NETRC_FILE => err = existingFile(cfgStrPtr(config, .netrc_file), a, nextarg),
        C_OUTPUT => err = parseOutput(config, nextarg),
        C_PROXY_CACERT => err = existingFile(cfgStrPtr(config, .proxy_cacert), a, nextarg),
        C_PROXY_CAPATH => err = getstr(cfgStrPtr(config, .proxy_capath), nextarg, DENY_BLANK),
        C_PROXY_CERT => err = GetFileAndPassword(nextarg, cfgStrPtr(config, .proxy_cert), cfgStrPtr(config, .proxy_key_passwd)),
        C_PROXY_CRLFILE => err = existingFile(cfgStrPtr(config, .proxy_crlfile), a, nextarg),
        C_PROXY_KEY => err = getstr(cfgStrPtr(config, .proxy_key), nextarg, ALLOW_BLANK),
        C_SSL_SESSIONS => {
            if (feature_ssls_export)
                err = getstr(globStrPtr(.ssl_sessions), nextarg, DENY_BLANK)
            else
                err = PARAM_LIBCURL_DOESNT_SUPPORT;
        },
        C_STDERR => tool_set_stderr_file(nextarg),
        C_TRACE => {
            err = getstr(globStrPtr(.trace_dump), nextarg, DENY_BLANK);
            if (err == PARAM_OK) {
                const tt = globInt(.tracetype);
                if (tt != 0 and tt != TRACE_BIN)
                    warnf("--trace overrides an earlier trace/verbose option");
                setGlobInt(.tracetype, TRACE_BIN);
            }
        },
        C_TRACE_ASCII => {
            err = getstr(globStrPtr(.trace_dump), nextarg, DENY_BLANK);
            if (err == PARAM_OK) {
                const tt = globInt(.tracetype);
                if (tt != 0 and tt != TRACE_ASCII)
                    warnf("--trace-ascii overrides an earlier trace/verbose option");
                setGlobInt(.tracetype, TRACE_ASCII);
            }
        },
        C_UNIX_SOCKET => {
            setCfgBit(config, .abstract_unix_socket, false);
            err = getstr(cfgStrPtr(config, .unix_socket_path), nextarg, DENY_BLANK);
        },
        C_UPLOAD_FILE => err = parseUploadFile(config, nextarg),
        C_HTTPSIG_KEY => {
            if (!feature_httpsig)
                err = PARAM_LIBCURL_DOESNT_SUPPORT
            else
                err = getstr(cfgStrPtr(config, .httpsig_key), nextarg, DENY_BLANK);
        },
        else => {},
    }
    return err;
}

fn optUnum(config: *OperationConfig, a: *const LongShort, nextarg: [*:0]const u8) ParameterError {
    var val: c_long = 0;
    const err = str2unum(&val, nextarg);
    if (err != PARAM_OK)
        return err;
    switch (a.cmd) {
        C_VLAN_PRIORITY => {
            if (val > 7) return PARAM_NUMBER_TOO_LARGE;
            setCfgInt(config, .vlan_priority, val);
        },
        C_RETRY => setCfgInt(config, .req_retry, val),
        C_KEEPALIVE_TIME => setCfgInt(config, .alivetime, val),
        C_KEEPALIVE_CNT => setCfgInt(config, .alivecnt, val),
        C_TFTP_BLKSIZE => setCfgInt(config, .tftp_blksize, val),
        C_HAPPY_EYEBALLS_TIMEOUT_MS => setCfgInt(config, .happy_eyeballs_timeout_ms, val),
        C_SPEED_TIME => {
            setCfgInt(config, .low_speed_time, val);
            if (cfgInt(config, .low_speed_limit) == 0)
                setCfgInt(config, .low_speed_limit, 1);
        },
        C_SPEED_LIMIT => {
            setCfgInt(config, .low_speed_limit, val);
            if (cfgInt(config, .low_speed_time) == 0)
                setCfgInt(config, .low_speed_time, 30);
        },
        C_PARALLEL_HOST => {
            if (val > MAX_PARALLEL_HOST)
                setGlobInt(.parallel_host, MAX_PARALLEL_HOST)
            else if (val < 1)
                setGlobInt(.parallel_host, PARALLEL_HOST_DEFAULT)
            else
                setGlobInt(.parallel_host, val);
        },
        C_PARALLEL_MAX => {
            if (val > MAX_PARALLEL)
                setGlobInt(.parallel_max, MAX_PARALLEL)
            else if (val < 1)
                setGlobInt(.parallel_max, PARALLEL_DEFAULT)
            else
                setGlobInt(.parallel_max, val);
        },
        else => return PARAM_OPTION_UNKNOWN,
    }
    return err;
}

fn optSecs(config: *OperationConfig, a: *const LongShort, nextarg: [*:0]const u8) ParameterError {
    var val: c_long = 0;
    const err = secs2ms(&val, nextarg);
    if (err != PARAM_OK)
        return err;
    switch (a.cmd) {
        C_CONNECT_TIMEOUT => setCfgInt(config, .connecttimeout_ms, val),
        C_RETRY_DELAY => {
            if (val >= std.math.maxInt(i32))
                val = std.math.maxInt(i32);
            setCfgInt(config, .retry_delay_ms, val);
        },
        C_RETRY_MAX_TIME => setCfgInt(config, .retry_maxtime_ms, val),
        C_EXPECT100_TIMEOUT => setCfgInt(config, .expect100timeout_ms, val),
        C_MAX_TIME => setCfgInt(config, .timeout_ms, val),
        else => return PARAM_OPTION_UNKNOWN,
    }
    return err;
}

const redir_protos = [_:null]?[*:0]const u8{
    "http",
    "https",
    "ftp",
    "ftps",
};

fn optString(
    config: *OperationConfig,
    a: *const LongShort,
    nextarg_in: ?[*:0]const u8,
) ParameterError {
    var err: ParameterError = PARAM_OK;
    var value: curl_off_t = 0;
    const nextarg: [*:0]const u8 = nextarg_in orelse "";

    switch (a.cmd) {
        C_DNS_IPV4_ADDR => {
            if (!tool_zig_has_ares()) return PARAM_LIBCURL_DOESNT_SUPPORT;
            return getstr(cfgStrPtr(config, .dns_ipv4_addr), nextarg, DENY_BLANK);
        },
        C_DNS_IPV6_ADDR => {
            if (!tool_zig_has_ares()) return PARAM_LIBCURL_DOESNT_SUPPORT;
            return getstr(cfgStrPtr(config, .dns_ipv6_addr), nextarg, DENY_BLANK);
        },
        C_OAUTH2_BEARER => {
            toggleCfgIntBits(config, .authtype, true, CURLAUTH_BEARER);
            return getstr(cfgStrPtr(config, .oauth_bearer), nextarg, DENY_BLANK);
        },
        C_DOH_URL => {
            const p = cfgStrPtr(config, .doh_url);
            err = getstr(p, nextarg, ALLOW_BLANK);
            if (err == PARAM_OK and p.* != null and p.*.?[0] == 0)
                cfgStrFree(config, .doh_url);
        },
        C_CIPHERS => err = getstr(cfgStrPtr(config, .cipher_list), nextarg, DENY_BLANK),
        C_DNS_INTERFACE => {
            if (!tool_zig_has_ares())
                err = PARAM_LIBCURL_DOESNT_SUPPORT
            else
                err = getstr(cfgStrPtr(config, .dns_interface), nextarg, DENY_BLANK);
        },
        C_DNS_SERVERS => {
            if (!tool_zig_has_ares())
                err = PARAM_LIBCURL_DOESNT_SUPPORT
            else
                err = getstr(cfgStrPtr(config, .dns_servers), nextarg, DENY_BLANK);
        },
        C_LIMIT_RATE => {
            err = GetSizeParameter(nextarg, &value);
            if (err == PARAM_OK) {
                setCfgInt(config, .recvpersecond, value);
                setCfgInt(config, .sendpersecond, value);
            }
        },
        C_RATE => err = setRate(nextarg),
        C_CREATE_FILE_MODE => {
            var mode: c_long = @intCast(cfgInt(config, .create_file_mode));
            err = oct2nummax(&mode, nextarg, 0o777);
            setCfgInt(config, .create_file_mode, mode);
        },
        C_MAX_REDIRS => {
            var maxredirs: c_long = @intCast(cfgInt(config, .maxredirs));
            err = str2num(&maxredirs, nextarg);
            setCfgInt(config, .maxredirs, maxredirs);
            if (err == PARAM_OK and maxredirs < -1)
                err = PARAM_BAD_NUMERIC;
        },
        C_IPFS_GATEWAY => err = getstr(cfgStrPtr(config, .ipfs_gateway), nextarg, DENY_BLANK),
        C_AWS_SIGV4 => {
            toggleCfgIntBits(config, .authtype, true, CURLAUTH_AWS_SIGV4);
            err = getstr(cfgStrPtr(config, .aws_sigv4), nextarg, ALLOW_BLANK);
        },
        C_HTTPSIG_ALGORITHM => {
            if (!feature_httpsig) {
                err = PARAM_LIBCURL_DOESNT_SUPPORT;
            } else {
                toggleCfgIntBits(config, .authtype, true, CURLAUTH_HTTPSIG);
                err = getstr(cfgStrPtr(config, .httpsig_algorithm), nextarg, DENY_BLANK);
            }
        },
        C_HTTPSIG_KEYID => {
            if (!feature_httpsig)
                err = PARAM_LIBCURL_DOESNT_SUPPORT
            else
                err = getstr(cfgStrPtr(config, .httpsig_keyid), nextarg, DENY_BLANK);
        },
        C_HTTPSIG_HEADERS => {
            if (!feature_httpsig)
                err = PARAM_LIBCURL_DOESNT_SUPPORT
            else
                err = getstr(cfgStrPtr(config, .httpsig_headers), nextarg, DENY_BLANK);
        },
        C_INTERFACE => err = getstr(cfgStrPtr(config, .iface), nextarg, DENY_BLANK),
        C_HAPROXY_CLIENTIP => err = getstr(cfgStrPtr(config, .haproxy_clientip), nextarg, DENY_BLANK),
        C_MAX_FILESIZE => {
            err = GetSizeParameter(nextarg, &value);
            if (err == PARAM_OK)
                setCfgInt(config, .max_filesize, value);
        },
        C_URL => err = parseUrl(config, nextarg),
        C_SOCKS5 => {
            err = getstr(cfgStrPtr(config, .proxy), nextarg, DENY_BLANK);
            setCfgInt(config, .proxyver, CURLPROXY_SOCKS5);
        },
        C_SOCKS4 => {
            err = getstr(cfgStrPtr(config, .proxy), nextarg, DENY_BLANK);
            setCfgInt(config, .proxyver, CURLPROXY_SOCKS4);
        },
        C_SOCKS4A => {
            err = getstr(cfgStrPtr(config, .proxy), nextarg, DENY_BLANK);
            setCfgInt(config, .proxyver, CURLPROXY_SOCKS4A);
        },
        C_SOCKS5_HOSTNAME => {
            err = getstr(cfgStrPtr(config, .proxy), nextarg, DENY_BLANK);
            setCfgInt(config, .proxyver, CURLPROXY_SOCKS5_HOSTNAME);
        },
        C_IP_TOS => {
            if (findTos(nextarg)) |tos_val| {
                setCfgInt(config, .ip_tos, tos_val);
            } else {
                var ip_tos: c_long = @intCast(cfgInt(config, .ip_tos));
                err = str2unummax(&ip_tos, nextarg, 0xFF);
                setCfgInt(config, .ip_tos, ip_tos);
            }
        },
        C_FTP_ACCOUNT => err = getstr(cfgStrPtr(config, .ftp_account), nextarg, DENY_BLANK),
        C_FTP_METHOD => setCfgInt(config, .ftp_filemethod, ftpfilemethod(nextarg)),
        C_LOCAL_PORT => err = parseLocalport(config, nextarg),
        C_FTP_ALTERNATIVE_TO_USER => err = getstr(cfgStrPtr(config, .ftp_alternative_to_user), nextarg, DENY_BLANK),
        C_LIBCURL => err = getstr(globStrPtr(.libcurl), nextarg, DENY_BLANK),
        C_NOPROXY => err = getstr(cfgStrPtr(config, .noproxy), nextarg, ALLOW_BLANK),
        C_PROXY1_0 => {
            err = getstr(cfgStrPtr(config, .proxy), nextarg, DENY_BLANK);
            setCfgInt(config, .proxyver, CURLPROXY_HTTP_1_0);
        },
        C_MAIL_FROM => err = getstr(cfgStrPtr(config, .mail_from), nextarg, DENY_BLANK),
        C_MAIL_RCPT => err = add2list(cfgSlistPtr(config, .mail_rcpt), nextarg),
        C_PROTO => {
            setCfgBit(config, .proto_present, true);
            err = proto2num(built_in_protos, cfgStrPtr(config, .proto_str), nextarg);
        },
        C_PROTO_REDIR => {
            setCfgBit(config, .proto_redir_present, true);
            if (proto2num(&redir_protos, cfgStrPtr(config, .proto_redir_str), nextarg) != PARAM_OK)
                err = PARAM_BAD_USE;
        },
        C_RESOLVE => err = add2list(cfgSlistPtr(config, .resolve), nextarg),
        C_DELEGATION => setCfgInt(config, .gssapi_delegation, delegation(nextarg)),
        C_MAIL_AUTH => err = getstr(cfgStrPtr(config, .mail_auth), nextarg, DENY_BLANK),
        C_SASL_AUTHZID => err = getstr(cfgStrPtr(config, .sasl_authzid), nextarg, DENY_BLANK),
        C_PROXY_SERVICE_NAME, C_SOCKS5_GSSAPI_SERVICE => err = getstr(cfgStrPtr(config, .proxy_service_name), nextarg, DENY_BLANK),
        C_SERVICE_NAME => err = getstr(cfgStrPtr(config, .service_name), nextarg, DENY_BLANK),
        C_PROTO_DEFAULT => {
            const p = cfgStrPtr(config, .proto_default);
            err = getstr(p, nextarg, DENY_BLANK);
            if (err == PARAM_OK)
                err = check_protocol(p.*);
        },
        C_CONNECT_TO => err = add2list(cfgSlistPtr(config, .connect_to), nextarg),
        C_TLS_MAX => {
            var ssl_max: u8 = @intCast(cfgInt(config, .ssl_version_max));
            err = str2tls_max(&ssl_max, nextarg);
            setCfgInt(config, .ssl_version_max, ssl_max);
            if (err == PARAM_OK and ssl_max < @as(u8, @intCast(cfgInt(config, .ssl_version)))) {
                errorf("--tls-max set lower than minimum accepted version");
                err = PARAM_BAD_USE;
            }
        },
        C_TRACE_CONFIG => {
            setGlobBit(.trace_set, true);
            if (setTraceConfig(nextarg) != CURLE_OK)
                err = PARAM_NO_MEM;
        },
        C_VARIABLE => err = setvariable(nextarg),
        C_TLS13_CIPHERS => err = getstr(cfgStrPtr(config, .cipher13_list), nextarg, DENY_BLANK),
        C_PROXY_TLS13_CIPHERS => err = getstr(cfgStrPtr(config, .proxy_cipher13_list), nextarg, DENY_BLANK),
        C_USER_AGENT => err = getstr(cfgStrPtr(config, .useragent), nextarg, ALLOW_BLANK),
        C_ALT_SVC => {
            if (!feature_altsvc)
                err = PARAM_LIBCURL_DOESNT_SUPPORT
            else
                err = getstr(cfgStrPtr(config, .altsvc), nextarg, ALLOW_BLANK);
        },
        C_HSTS => {
            if (!feature_hsts)
                err = PARAM_LIBCURL_DOESNT_SUPPORT
            else
                err = getstr(cfgStrPtr(config, .hsts), nextarg, ALLOW_BLANK);
        },
        C_COOKIE => {
            if (strChrZ(nextarg, '=') != null)
                err = add2list(cfgSlistPtr(config, .cookies), nextarg)
            else
                err = add2list(cfgSlistPtr(config, .cookiefiles), nextarg);
        },
        C_COOKIE_JAR => err = getstr(cfgStrPtr(config, .cookiejar), nextarg, DENY_BLANK),
        C_CONTINUE_AT => err = parseContinueAt(config, nextarg),
        C_DATA, C_DATA_ASCII, C_DATA_BINARY, C_DATA_URLENCODE, C_JSON, C_DATA_RAW => {
            err = setData(a.cmd, nextarg, config);
        },
        C_URL_QUERY => err = urlQuery(nextarg, config),
        C_REFERER => {
            var len = std.mem.len(nextarg);
            if (len >= 5 and std.mem.eql(u8, nextarg[len - 5 .. len], ";auto")) {
                setCfgBit(config, .autoreferer, true);
                len -= 5;
            } else {
                setCfgBit(config, .autoreferer, false);
            }
            if (len != 0)
                err = getstrn(cfgStrPtr(config, .referer), nextarg, len, ALLOW_BLANK)
            else
                cfgStrFree(config, .referer);
        },
        C_CERT_TYPE => err = getstr(cfgStrPtr(config, .cert_type), nextarg, DENY_BLANK),
        C_KEY_TYPE => err = getstr(cfgStrPtr(config, .key_type), nextarg, DENY_BLANK),
        C_PASS => err = getstr(cfgStrPtr(config, .key_passwd), nextarg, DENY_BLANK),
        C_ENGINE => {
            const p = cfgStrPtr(config, .engine);
            err = getstr(p, nextarg, DENY_BLANK);
            if (err == PARAM_OK and p.* != null and std.mem.eql(u8, std.mem.span(p.*.?), "list")) {
                err = PARAM_ENGINES_REQUESTED;
            }
        },
        C_ECH => err = parseEch(config, nextarg),
        C_PUBKEY => err = getstr(cfgStrPtr(config, .pubkey), nextarg, DENY_BLANK),
        C_HOSTPUBMD5 => {
            const p = cfgStrPtr(config, .hostpubmd5);
            err = getstr(p, nextarg, DENY_BLANK);
            if (err == PARAM_OK and (p.* == null or std.mem.len(p.*.?) != 32))
                err = PARAM_BAD_USE;
        },
        C_HOSTPUBSHA256 => err = getstr(cfgStrPtr(config, .hostpubsha256), nextarg, DENY_BLANK),
        C_PINNEDPUBKEY => err = getstr(cfgStrPtr(config, .pinnedpubkey), nextarg, DENY_BLANK),
        C_PROXY_PINNEDPUBKEY => err = getstr(cfgStrPtr(config, .proxy_pinnedpubkey), nextarg, DENY_BLANK),
        C_PROXY_CERT_TYPE => err = getstr(cfgStrPtr(config, .proxy_cert_type), nextarg, DENY_BLANK),
        C_PROXY_KEY_TYPE => err = getstr(cfgStrPtr(config, .proxy_key_type), nextarg, DENY_BLANK),
        C_PROXY_PASS => err = getstr(cfgStrPtr(config, .proxy_key_passwd), nextarg, ALLOW_BLANK),
        C_PROXY_CIPHERS => err = getstr(cfgStrPtr(config, .proxy_cipher_list), nextarg, DENY_BLANK),
        C_LOGIN_OPTIONS => err = getstr(cfgStrPtr(config, .login_options), nextarg, ALLOW_BLANK),
        C_CURVES => err = getstr(cfgStrPtr(config, .ssl_ec_curves), nextarg, DENY_BLANK),
        C_SIGNATURE_ALGORITHMS => err = getstr(cfgStrPtr(config, .ssl_signature_algorithms), nextarg, DENY_BLANK),
        C_FORM, C_FORM_STRING => {
            if (formparse(
                nextarg,
                tool_zig_config_mimeroot_ptr(config),
                tool_zig_config_mimecurrent_ptr(config),
                a.cmd == C_FORM_STRING,
            ) != 0) {
                err = PARAM_BAD_USE;
            } else {
                var httpreq: HttpReq = @intCast(cfgInt(config, .httpreq));
                if (SetHTTPrequest(TOOL_HTTPREQ_MIMEPOST, &httpreq) != 0)
                    err = PARAM_BAD_USE;
                setCfgInt(config, .httpreq, httpreq);
            }
        },
        C_REQUEST_TARGET => err = getstr(cfgStrPtr(config, .request_target), nextarg, DENY_BLANK),
        C_HEADER, C_PROXY_HEADER => err = parseHeader(config, a.cmd, nextarg),
        C_OUTPUT_DIR => err = getstr(cfgStrPtr(config, .output_dir), nextarg, DENY_BLANK),
        C_FTP_PORT => err = getstr(cfgStrPtr(config, .ftpport), nextarg, DENY_BLANK),
        C_FTP_SSL_CCC_MODE => {
            setCfgBit(config, .ftp_ssl_ccc, true);
            setCfgInt(config, .ftp_ssl_ccc_mode, ftpcccmethod(nextarg));
        },
        C_QUOTE => err = parseQuote(config, nextarg),
        C_RANGE => err = parseRange(config, nextarg),
        C_TELNET_OPTION => err = add2list(cfgSlistPtr(config, .telnet_options), nextarg),
        C_USER => err = getstr(cfgStrPtr(config, .userpwd), nextarg, ALLOW_BLANK),
        C_PROXY_USER => err = getstr(cfgStrPtr(config, .proxyuserpwd), nextarg, ALLOW_BLANK),
        C_WRITE_OUT => err = parseWriteout(config, nextarg),
        C_PREPROXY => err = getstr(cfgStrPtr(config, .preproxy), nextarg, DENY_BLANK),
        C_PROXY => {
            err = getstr(cfgStrPtr(config, .proxy), nextarg, ALLOW_BLANK);
            const pv = cfgInt(config, .proxyver);
            if (pv != CURLPROXY_HTTPS2 and pv != CURLPROXY_HTTPS3)
                setCfgInt(config, .proxyver, CURLPROXY_HTTP);
        },
        C_REQUEST => err = getstr(cfgStrPtr(config, .customrequest), nextarg, DENY_BLANK),
        C_TIME_COND => err = parseTimeCond(config, nextarg),
        C_UPLOAD_FLAGS => err = parseUploadFlags(config, nextarg),
        else => {},
    }
    return err;
}

inline fn hasLeadingUnicode(arg: [*:0]const u8) bool {
    return arg[0] == 0xe2 and arg[1] == 0x80 and (arg[2] & 0x80) != 0;
}

const MAX_OPTION_LEN: usize = 26;

pub export fn getparameter(
    flag_in: [*:0]const u8,
    nextarg_in: ?[*:0]const u8,
    usedarg: *bool,
    config: *OperationConfig,
    max_recursive: c_int,
) callconv(.c) ParameterError {
    var flag = flag_in;
    var nextarg = nextarg_in;
    var parse: [*:0]const u8 = undefined;
    var longopt = false;
    var singleopt = false;
    var err: ParameterError = PARAM_OK;
    var toggle = true;
    var nextalloc = false;
    var consumearg = true;
    var a_opt: ?*const LongShort = null;
    verbose_nopts = 0;

    usedarg.* = false;

    if (flag[0] != '-' or flag[1] == '-') {
        var word: [*:0]const u8 = if (flag[0] == '-') flag + 2 else flag;
        var noflagged = false;
        var expand = false;
        var out: Curl_str = .{};

        const word_slice = std.mem.span(word);
        if (std.mem.startsWith(u8, word_slice, "no-")) {
            word += 3;
            toggle = false;
            noflagged = true;
        } else if (std.mem.startsWith(u8, word_slice, "expand-")) {
            word += 7;
            expand = true;
        }

        var p = word;
        if (curlx_str_until(&p, &out, MAX_OPTION_LEN, '=') == 0 and
            curlx_str_single(&p, '=') == 0)
        {
            var tempword: [MAX_OPTION_LEN + 1]u8 = undefined;
            if (out.len > 0) {
                if (out.str) |s| {
                    @memcpy(tempword[0..out.len], s[0..out.len]);
                }
            }
            tempword[out.len] = 0;
            a_opt = findlongopt(@ptrCast(&tempword));
            nextarg = p;
            consumearg = false;
        } else {
            a_opt = findlongopt(word);
        }

        if (a_opt) |a| {
            longopt = true;
            if (noflagged and argType(a.desc) != ARG_BOOL) {
                err = PARAM_NO_PREFIX;
                if (nextalloc) c.free(@constCast(nextarg));
                return err;
            } else if (expand and nextarg != null) {
                var nbuf: Dynbuf = .{};
                var replaced = false;

                if (argType(a.desc) < ARG_STRG) {
                    err = PARAM_EXPAND_ERROR;
                    if (nextalloc) c.free(@constCast(nextarg));
                    return err;
                }
                err = varexpand(nextarg.?, &nbuf, &replaced);
                if (err != PARAM_OK) {
                    curlx_dyn_free(&nbuf);
                    if (nextalloc) c.free(@constCast(nextarg));
                    return err;
                }
                if (replaced) {
                    nextarg = curlx_dyn_ptr(&nbuf);
                    nextalloc = true;
                }
            }
        } else {
            err = PARAM_OPTION_UNKNOWN;
            if (nextalloc) c.free(@constCast(nextarg));
            return err;
        }
    } else {
        flag += 1;
        parse = flag;
    }

    while (true) {
        if (!longopt) {
            a_opt = findshortopt(parse[0]);
            if (a_opt == null) {
                err = PARAM_OPTION_UNKNOWN;
                break;
            }
            toggle = (a_opt.?.desc & ARG_NO) == 0;
        }
        const a = a_opt.?;
        if ((a.desc & ARG_TLS) != 0 and !feature_ssl) {
            err = PARAM_LIBCURL_DOESNT_SUPPORT;
            break;
        } else if (argType(a.desc) >= ARG_STRG) {
            if (!longopt and parse[1] != 0) {
                nextarg = parse + 1;
                singleopt = true;
            } else if (a.cmd == C_HELP) {
                tool_help(if (nextarg != null and nextarg.?[0] != 0) nextarg else null);
                err = PARAM_HELP_REQUESTED;
                break;
            } else if (nextarg == null) {
                err = PARAM_REQUIRES_PARAMETER;
                break;
            } else {
                usedarg.* = consumearg;
            }
            if ((a.desc & ARG_DEPR) != 0) {
                optDepr(a);
                break;
            }

            const na = nextarg.?;
            if (hasLeadingUnicode(na)) {
                if ((a.desc & ARG_CLEAR) != 0)
                    warnf("The argument to --%s starts with a Unicode character. Maybe ASCII was intended?", a.lname)
                else
                    warnf("The argument '%s' starts with a Unicode character. Maybe ASCII was intended?", na);
            }
            switch (argType(a.desc)) {
                ARG_FILE => err = optFile(config, a, na, max_recursive),
                ARG_STRG => err = optString(config, a, na),
                ARG_SECS => err = optSecs(config, a, na),
                ARG_UNUM => err = optUnum(config, a, na),
                else => err = PARAM_OPTION_UNKNOWN,
            }
        } else {
            if ((a.desc & ARG_DEPR) != 0) {
                optDepr(a);
                break;
            }
            if (argType(a.desc) == ARG_BOOL)
                err = optBool(config, a, toggle)
            else
                err = optNone(config, a);
        }

        verbose_nopts += 1;
        if (longopt or singleopt or usedarg.* or err != PARAM_OK)
            break;
        parse += 1;
        if (parse[0] == 0)
            break;
    }

    if (nextalloc)
        c.free(@constCast(nextarg));
    return err;
}

pub export fn parse_args(argc: c_int, argv: [*]?[*:0]u8) callconv(.c) ParameterError {
    var i: usize = 1;
    var stillflags = true;
    var orig_opt: ?[*:0]const u8 = null;
    var err: ParameterError = PARAM_OK;
    var config: *OperationConfig = tool_zig_global_first() orelse return PARAM_NO_MEM;
    const uargc: usize = if (argc > 0) @intCast(argc) else 0;

    while (i < uargc and err == PARAM_OK) : (i += 1) {
        orig_opt = argv[i];
        if (orig_opt == null)
            return PARAM_NO_MEM;
        const opt = orig_opt.?;

        if (stillflags and opt[0] == '-') {
            var passarg = false;

            if (std.mem.eql(u8, std.mem.span(opt), "--")) {
                stillflags = false;
            } else {
                var nextarg: ?[*:0]const u8 = null;
                if (i < (uargc - 1)) {
                    nextarg = argv[i + 1];
                    if (nextarg == null)
                        return PARAM_NO_MEM;
                }

                err = getparameter(opt, nextarg, &passarg, config, CONFIG_MAX_LEVELS);
                config = tool_zig_get_global_last() orelse config;
                if (err == PARAM_NEXT_OPERATION) {
                    err = PARAM_OK;
                    const url_list = cfgGetoutPtr(config, .url_list).*;
                    if (url_list != null and getoutStrPtr(url_list.?, .url).* != null) {
                        if (tool_zig_config_alloc_next(config)) |next_cfg| {
                            config = next_cfg;
                        } else {
                            err = PARAM_NO_MEM;
                        }
                    } else {
                        errorf("missing URL before --next");
                        err = PARAM_BAD_USE;
                    }
                } else if (err == PARAM_OK and passarg) {
                    i += 1;
                }
            }
        } else {
            var used = false;
            err = getparameter("--url", opt, &used, config, 0);
        }

        if (err == PARAM_OK) {
            orig_opt = null;
        }
    }

    if (err == PARAM_OK and cfgBit(config, .content_disposition) and cfgBit(config, .resume_from_current))
        err = PARAM_CONTDISP_RESUME_FROM;

    if (err != PARAM_OK and
        err != PARAM_HELP_REQUESTED and
        err != PARAM_MANUAL_REQUESTED and
        err != PARAM_VERSION_INFO_REQUESTED and
        err != PARAM_ENGINES_REQUESTED and
        err != PARAM_CA_EMBED_REQUESTED)
    {
        const reason = param2text(err);
        if (orig_opt != null and !std.mem.eql(u8, std.mem.span(orig_opt.?), ":"))
            helpf("option %s: %s", orig_opt.?, reason)
        else
            helpf("%s", reason);
    }

    return err;
}
