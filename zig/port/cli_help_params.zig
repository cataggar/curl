const std = @import("std");
const builtin = @import("builtin");

pub const CURLcode = c_uint;
pub const CURLE_OK: CURLcode = 0;
pub const CURLE_UNSUPPORTED_PROTOCOL: CURLcode = 1;
pub const CURLE_FAILED_INIT: CURLcode = 2;
pub const CURLE_URL_MALFORMAT: CURLcode = 3;
pub const CURLE_NOT_BUILT_IN: CURLcode = 4;
pub const CURLE_WRITE_ERROR: CURLcode = 23;
pub const CURLE_READ_ERROR: CURLcode = 26;
pub const CURLE_OUT_OF_MEMORY: CURLcode = 27;
pub const CURLE_BAD_FUNCTION_ARGUMENT: CURLcode = 43;
pub const CURLE_FILE_COULDNT_READ_FILE: CURLcode = 37;

pub const CURLUcode = c_uint;
pub const CURLUE_OK: CURLUcode = 0;
pub const CURLUE_BAD_HANDLE: CURLUcode = 1;
pub const CURLUE_UNSUPPORTED_SCHEME: CURLUcode = 5;
pub const CURLUE_OUT_OF_MEMORY: CURLUcode = 7;
pub const CURLUE_NO_QUERY: CURLUcode = 16;
pub const CURLUE_LACKS_IDN: CURLUcode = 30;

pub const CURLUPart = c_uint;
pub const CURLUPART_URL: CURLUPart = 0;
pub const CURLUPART_SCHEME: CURLUPart = 1;
pub const CURLUPART_HOST: CURLUPart = 5;
pub const CURLUPART_PORT: CURLUPart = 6;
pub const CURLUPART_PATH: CURLUPart = 7;
pub const CURLUPART_QUERY: CURLUPart = 8;

pub const CURLU_DEFAULT_PORT: c_uint = 1 << 0;
pub const CURLU_DEFAULT_SCHEME: c_uint = 1 << 2;
pub const CURLU_NON_SUPPORT_SCHEME: c_uint = 1 << 3;
pub const CURLU_URLDECODE: c_uint = 1 << 6;
pub const CURLU_URLENCODE: c_uint = 1 << 7;
pub const CURLU_GUESS_SCHEME: c_uint = 1 << 9;
pub const CURLU_NO_GUESS_SCHEME: c_uint = 1 << 15;

pub const CURLINFO = c_uint;
pub const CURLINFO_SLIST: CURLINFO = 0x400000;
pub const CURLINFO_SSL_ENGINES: CURLINFO = CURLINFO_SLIST + 27;

pub const CURLversion = c_uint;
pub const CURLVERSION_ELEVENTH: CURLversion = 10;
pub const CURLVERSION_TWELFTH: CURLversion = 11;
pub const CURLVERSION_NOW: CURLversion = CURLVERSION_TWELFTH;

pub const CURL_VERSION_IPV6: c_int = 1 << 0;
pub const CURL_VERSION_SSL: c_int = 1 << 2;
pub const CURL_VERSION_LIBZ: c_int = 1 << 3;
pub const CURL_VERSION_NTLM: c_int = 1 << 4;
pub const CURL_VERSION_DEBUG: c_int = 1 << 6;
pub const CURL_VERSION_ASYNCHDNS: c_int = 1 << 7;
pub const CURL_VERSION_SPNEGO: c_int = 1 << 8;
pub const CURL_VERSION_LARGEFILE: c_int = 1 << 9;
pub const CURL_VERSION_IDN: c_int = 1 << 10;
pub const CURL_VERSION_SSPI: c_int = 1 << 11;
pub const CURL_VERSION_CONV: c_int = 1 << 12;
pub const CURL_VERSION_NTLM_WB: c_int = 1 << 15;
pub const CURL_VERSION_HTTP2: c_int = 1 << 16;
pub const CURL_VERSION_GSSAPI: c_int = 1 << 17;
pub const CURL_VERSION_KERBEROS5: c_int = 1 << 18;
pub const CURL_VERSION_UNIX_SOCKETS: c_int = 1 << 19;
pub const CURL_VERSION_PSL: c_int = 1 << 20;
pub const CURL_VERSION_HTTPS_PROXY: c_int = 1 << 21;
pub const CURL_VERSION_MULTI_SSL: c_int = 1 << 22;
pub const CURL_VERSION_BROTLI: c_int = 1 << 23;
pub const CURL_VERSION_ALTSVC: c_int = 1 << 24;
pub const CURL_VERSION_HTTP3: c_int = 1 << 25;
pub const CURL_VERSION_ZSTD: c_int = 1 << 26;
pub const CURL_VERSION_UNICODE: c_int = 1 << 27;
pub const CURL_VERSION_HSTS: c_int = 1 << 28;
pub const CURL_VERSION_GSASL: c_int = 1 << 29;
pub const CURL_VERSION_THREADSAFE: c_int = 1 << 30;

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

pub const SANITIZEcode = c_uint;
pub const SANITIZE_ERR_OK: SANITIZEcode = 0;

pub const CURL_OFF_T_MAX: i64 = std.math.maxInt(i64);
pub const MAX_FILE2MEMORY: usize = if (@sizeOf(usize) > 4) 16 * 1024 * 1024 * 1024 else std.math.maxInt(c_int);
pub const MAX_GATEWAY_URL_LEN: usize = 10000;
pub const MAX_SSLS_LINE: usize = 64 * 1024;
pub const HEADER_LINE_BUFFER_SIZE: usize = 8192;
pub const STRERROR_LEN: usize = 256;

pub const DEFAULT_MAXREDIRS: c_long = 50;
pub const CURL_HET_DEFAULT: c_long = 200;
pub const CLOBBER_DEFAULT: c_uint = 0;
pub const CURLULFLAG_SEEN: u8 = 1 << 4;
pub const CURL_GLOBAL_DEFAULT: c_long = 3;

pub const CURLFTPMETHOD_MULTICWD: c_long = 1;
pub const CURLFTPMETHOD_NOCWD: c_long = 2;
pub const CURLFTPMETHOD_SINGLECWD: c_long = 3;

pub const CURLFTPSSL_CCC_PASSIVE: c_long = 1;
pub const CURLFTPSSL_CCC_ACTIVE: c_long = 2;

pub const CURLGSSAPI_DELEGATION_NONE: c_long = 0;
pub const CURLGSSAPI_DELEGATION_POLICY_FLAG: c_long = 1 << 0;
pub const CURLGSSAPI_DELEGATION_FLAG: c_long = 1 << 1;

pub const CURL_SEEKFUNC_OK: c_int = 0;
pub const CURL_SEEKFUNC_CANTSEEK: c_int = 2;
pub const CURL_READFUNC_ABORT: usize = 0x10000000;
pub const CURL_ZERO_TERMINATED: usize = std.math.maxInt(usize);

pub const SEEK_SET: c_int = 0;
pub const SEEK_CUR: c_int = 1;
pub const SEEK_END: c_int = 2;

pub const STRE_OVERFLOW: c_int = 7;

const FOPEN_READTEXT: [*:0]const u8 = if (builtin.os.tag == .windows) "rt" else "r";
const FOPEN_WRITETEXT: [*:0]const u8 = if (builtin.os.tag == .windows) "wt" else "w";

pub const CURLU = opaque {};
pub const GlobalConfig = opaque {};

pub const Dynbuf = extern struct {
    bufr: ?[*]u8,
    leng: usize,
    allc: usize,
    toobig: usize,
};

pub const curl_slist = extern struct {
    data: ?[*:0]u8,
    next: ?*curl_slist,
};

pub const slist_wc = extern struct {
    first: ?*curl_slist,
    last: ?*curl_slist,
};

pub const getout = extern struct {
    next: ?*getout,
    url: ?[*:0]u8,
    outfile: ?[*:0]u8,
    infile: ?[*:0]u8,
    num: i64,
    _flags_pad: u64,
};

pub const toolmimekind = c_uint;
pub const TOOLMIME_NONE: toolmimekind = 0;
pub const TOOLMIME_PARTS: toolmimekind = 1;
pub const TOOLMIME_DATA: toolmimekind = 2;
pub const TOOLMIME_FILE: toolmimekind = 3;
pub const TOOLMIME_FILEDATA: toolmimekind = 4;
pub const TOOLMIME_STDIN: toolmimekind = 5;
pub const TOOLMIME_STDINDATA: toolmimekind = 6;

pub const tool_mime = extern struct {
    kind: toolmimekind,
    parent: ?*tool_mime,
    prev: ?*tool_mime,
    data: ?[*:0]u8,
    name: ?[*:0]u8,
    filename: ?[*:0]u8,
    type: ?[*:0]u8,
    encoder: ?[*:0]u8,
    headers: ?*curl_slist,
    subparts: ?*tool_mime,
    origin: i64,
    size: i64,
    curpos: i64,
};

pub const OperationConfig = extern struct {
    postdata: Dynbuf,
    useragent: ?[*:0]u8,
    cookies: ?*curl_slist,
    cookiejar: ?[*:0]u8,
    cookiefiles: ?*curl_slist,
    altsvc: ?[*:0]u8,
    hsts: ?[*:0]u8,
    proto_str: ?[*:0]u8,
    proto_redir_str: ?[*:0]u8,
    proto_default: ?[*:0]u8,
    resume_from: i64,
    postfields: ?[*:0]u8,
    referer: ?[*:0]u8,
    query: ?[*:0]u8,
    max_filesize: i64,
    output_dir: ?[*:0]u8,
    headerfile: ?[*:0]u8,
    ftpport: ?[*:0]u8,
    iface: ?[*:0]u8,
    range: ?[*:0]u8,
    dns_servers: ?[*:0]u8,
    dns_interface: ?[*:0]u8,
    dns_ipv4_addr: ?[*:0]u8,
    dns_ipv6_addr: ?[*:0]u8,
    userpwd: ?[*:0]u8,
    login_options: ?[*:0]u8,
    proxyuserpwd: ?[*:0]u8,
    proxy: ?[*:0]u8,
    noproxy: ?[*:0]u8,
    knownhosts: ?[*:0]u8,
    mail_from: ?[*:0]u8,
    mail_rcpt: ?*curl_slist,
    mail_auth: ?[*:0]u8,
    sasl_authzid: ?[*:0]u8,
    netrc_file: ?[*:0]u8,
    url_list: ?*getout,
    url_last: ?*getout,
    url_get: ?*getout,
    url_out: ?*getout,
    url_ul: ?*getout,
    num_urls: usize,
    ipfs_gateway: ?[*:0]u8,
    doh_url: ?[*:0]u8,
    cipher_list: ?[*:0]u8,
    proxy_cipher_list: ?[*:0]u8,
    cipher13_list: ?[*:0]u8,
    proxy_cipher13_list: ?[*:0]u8,
    cert: ?[*:0]u8,
    proxy_cert: ?[*:0]u8,
    cert_type: ?[*:0]u8,
    proxy_cert_type: ?[*:0]u8,
    cacert: ?[*:0]u8,
    proxy_cacert: ?[*:0]u8,
    capath: ?[*:0]u8,
    proxy_capath: ?[*:0]u8,
    crlfile: ?[*:0]u8,
    proxy_crlfile: ?[*:0]u8,
    pinnedpubkey: ?[*:0]u8,
    proxy_pinnedpubkey: ?[*:0]u8,
    key: ?[*:0]u8,
    proxy_key: ?[*:0]u8,
    key_type: ?[*:0]u8,
    proxy_key_type: ?[*:0]u8,
    key_passwd: ?[*:0]u8,
    proxy_key_passwd: ?[*:0]u8,
    pubkey: ?[*:0]u8,
    hostpubmd5: ?[*:0]u8,
    hostpubsha256: ?[*:0]u8,
    engine: ?[*:0]u8,
    etag_save_file: ?[*:0]u8,
    etag_compare_file: ?[*:0]u8,
    customrequest: ?[*:0]u8,
    ssl_ec_curves: ?[*:0]u8,
    ssl_signature_algorithms: ?[*:0]u8,
    krblevel: ?[*:0]u8,
    request_target: ?[*:0]u8,
    writeout: ?[*:0]u8,
    httpgetfields: ?[*:0]u8,
    quote: ?*curl_slist,
    postquote: ?*curl_slist,
    prequote: ?*curl_slist,
    headers: ?*curl_slist,
    proxyheaders: ?*curl_slist,
    mimeroot: ?*tool_mime,
    mimecurrent: ?*tool_mime,
    mimepost: ?*anyopaque,
    telnet_options: ?*curl_slist,
    resolve: ?*curl_slist,
    connect_to: ?*curl_slist,
    preproxy: ?[*:0]u8,
    proxy_service_name: ?[*:0]u8,
    service_name: ?[*:0]u8,
    ftp_account: ?[*:0]u8,
    ftp_alternative_to_user: ?[*:0]u8,
    oauth_bearer: ?[*:0]u8,
    unix_socket_path: ?[*:0]u8,
    haproxy_clientip: ?[*:0]u8,
    aws_sigv4: ?[*:0]u8,
    httpsig_algorithm: ?[*:0]u8,
    httpsig_headers: ?[*:0]u8,
    httpsig_key: ?[*:0]u8,
    httpsig_keyid: ?[*:0]u8,
    ech: ?[*:0]u8,
    ech_config: ?[*:0]u8,
    ech_public: ?[*:0]u8,
    prev: ?*OperationConfig,
    next: ?*OperationConfig,
    condtime: i64,
    sendpersecond: i64,
    recvpersecond: i64,
    proxy_ssl_version: c_long,
    ip_version: c_long,
    create_file_mode: c_long,
    low_speed_limit: c_long,
    low_speed_time: c_long,
    ip_tos: c_long,
    vlan_priority: c_long,
    localport: c_long,
    localportrange: c_long,
    authtype: c_ulong,
    timeout_ms: c_long,
    connecttimeout_ms: c_long,
    maxredirs: c_long,
    httpversion: c_long,
    socks5_auth: c_ulong,
    req_retry: c_long,
    retry_delay_ms: u32,
    retry_maxtime_ms: c_long,
    mime_options: c_ulong,
    tftp_blksize: c_long,
    alivetime: c_long,
    alivecnt: c_long,
    gssapi_delegation: c_long,
    expect100timeout_ms: c_long,
    happy_eyeballs_timeout_ms: c_long,
    timecond: c_ulong,
    followlocation: c_long,
    httpreq: HttpReq,
    proxyver: c_long,
    ftp_ssl_ccc_mode: c_long,
    ftp_filemethod: c_long,
    file_clobber_mode: c_uint,
    upload_flags: u8,
    porttouse: u16,
    ssl_version: u8,
    ssl_version_max: u8,
    fail: u8,
};

pub const curl_version_info_data = extern struct {
    age: CURLversion,
    version: ?[*:0]const u8,
    version_num: c_uint,
    host: ?[*:0]const u8,
    features: c_int,
    ssl_version: ?[*:0]const u8,
    ssl_version_num: c_long,
    libz_version: ?[*:0]const u8,
    protocols: ?[*]const ?[*:0]const u8,
    ares: ?[*:0]const u8,
    ares_num: c_int,
    libidn: ?[*:0]const u8,
    iconv_ver_num: c_int,
    libssh_version: ?[*:0]const u8,
    brotli_ver_num: c_uint,
    brotli_version: ?[*:0]const u8,
    nghttp2_ver_num: c_uint,
    nghttp2_version: ?[*:0]const u8,
    quic_version: ?[*:0]const u8,
    cainfo: ?[*:0]const u8,
    capath: ?[*:0]const u8,
    zstd_ver_num: c_uint,
    zstd_version: ?[*:0]const u8,
    hyper_version: ?[*:0]const u8,
    gsasl_version: ?[*:0]const u8,
    feature_names: ?[*]const ?[*:0]const u8,
    rtmp_version: ?[*:0]const u8,
};

pub const scan_ctx = extern struct {
    trigger: ?[*:0]const u8,
    tlen: usize,
    arg: ?[*:0]const u8,
    flen: usize,
    endarg: ?[*:0]const u8,
    elen: usize,
    olen: usize,
    rbuf: [40]u8,
    obuf: [160]u8,
    show: u8,
};

pub const helptxt = extern struct {
    opt: ?[*:0]const u8,
    desc: ?[*:0]const u8,
    categories: c_uint,
};

// ============================================================================
// Extern declarations
// ============================================================================

const c = struct {
    extern "c" fn malloc(size: usize) ?*anyopaque;
    extern "c" fn calloc(nmemb: usize, size: usize) ?*anyopaque;
    extern "c" fn free(ptr: ?*anyopaque) void;
    extern "c" fn getenv(name: [*:0]const u8) ?[*:0]u8;
    extern "c" fn fputs(s: [*:0]const u8, stream: ?*anyopaque) c_int;
    extern "c" fn puts(s: [*:0]const u8) c_int;
    extern "c" fn getc(stream: ?*anyopaque) c_int;
    extern "c" fn fputc(ch: c_int, stream: ?*anyopaque) c_int;
    extern "c" fn fread(ptr: [*]u8, size: usize, nmemb: usize, stream: ?*anyopaque) usize;
    extern "c" fn fwrite(ptr: [*]const u8, size: usize, nmemb: usize, stream: ?*anyopaque) usize;
    extern "c" fn feof(stream: ?*anyopaque) c_int;
    extern "c" fn ferror(stream: ?*anyopaque) c_int;
    extern "c" fn fclose(stream: ?*anyopaque) c_int;
    extern "c" fn qsort(
        base: *anyopaque,
        nmemb: usize,
        size: usize,
        compar: *const fn (*const anyopaque, *const anyopaque) callconv(.c) c_int,
    ) void;
};

const posix_c = struct {
    extern "c" fn fopen(filename: [*:0]const u8, mode: [*:0]const u8) ?*anyopaque;
    extern "c" fn open(path: [*:0]const u8, oflag: c_int, ...) c_int;
    extern "c" fn close(fd: c_int) c_int;
    extern "c" fn read(fd: c_int, buf: [*]u8, count: usize) isize;
};

const win32_c = struct {
    extern "c" fn _getch() c_int;
    extern "c" fn _close(fd: c_int) c_int;
    extern fn curlx_win32_fopen(filename: ?[*:0]const u8, mode: ?[*:0]const u8) callconv(.c) ?*anyopaque;
    extern fn curlx_win32_open(filename: ?[*:0]const u8, oflag: c_int, pmode: c_int) callconv(.c) c_int;
};

extern var tool_stderr: ?*anyopaque;
extern const helptext: [1]helptxt;

inline fn helptextPtr() [*]const helptxt {
    return @ptrCast(&helptext);
}

extern fn curl_global_init(flags: c_long) callconv(.c) CURLcode;
extern fn curl_global_cleanup() callconv(.c) void;
extern fn curl_version() callconv(.c) [*:0]const u8;
extern fn curl_version_info(stamp: CURLversion) callconv(.c) ?*curl_version_info_data;
extern fn curl_easy_init() callconv(.c) ?*anyopaque;
extern fn curl_easy_cleanup(curl: ?*anyopaque) callconv(.c) void;
extern fn curl_easy_getinfo(curl: ?*anyopaque, info: CURLINFO, ...) callconv(.c) CURLcode;
extern fn curl_easy_escape(handle: ?*anyopaque, string: [*:0]const u8, length: c_int) callconv(.c) ?[*:0]u8;
extern fn curl_free(p: ?*anyopaque) callconv(.c) void;
extern fn curl_getenv(variable: [*:0]const u8) callconv(.c) ?[*:0]u8;
extern fn curl_strequal(s1: [*:0]const u8, s2: [*:0]const u8) callconv(.c) c_int;
extern fn curl_strnequal(s1: [*]const u8, s2: [*]const u8, max: usize) callconv(.c) c_int;
extern fn curl_mprintf(format: [*:0]const u8, ...) callconv(.c) c_int;
extern fn curl_mfprintf(fd: ?*anyopaque, format: [*:0]const u8, ...) callconv(.c) c_int;
extern fn curl_msnprintf(buffer: [*]u8, maxlength: usize, format: [*:0]const u8, ...) callconv(.c) c_int;
extern fn curl_maprintf(format: [*:0]const u8, ...) callconv(.c) ?[*:0]u8;

extern fn curl_slist_append(list: ?*curl_slist, data: [*:0]const u8) callconv(.c) ?*curl_slist;
extern fn curl_slist_free_all(list: ?*curl_slist) callconv(.c) void;

extern fn curl_url() callconv(.c) ?*CURLU;
extern fn curl_url_cleanup(handle: ?*CURLU) callconv(.c) void;
extern fn curl_url_set(handle: ?*CURLU, what: CURLUPart, part: ?[*:0]const u8, flags: c_uint) callconv(.c) CURLUcode;
extern fn curl_url_get(handle: ?*const CURLU, what: CURLUPart, part: *?[*:0]u8, flags: c_uint) callconv(.c) CURLUcode;

extern fn curl_mime_init(easy: ?*anyopaque) callconv(.c) ?*anyopaque;
extern fn curl_mime_free(mime: ?*anyopaque) callconv(.c) void;
extern fn curl_mime_addpart(mime: ?*anyopaque) callconv(.c) ?*anyopaque;
extern fn curl_mime_name(part: ?*anyopaque, name: ?[*:0]const u8) callconv(.c) CURLcode;
extern fn curl_mime_filename(part: ?*anyopaque, filename: ?[*:0]const u8) callconv(.c) CURLcode;
extern fn curl_mime_type(part: ?*anyopaque, mimetype: ?[*:0]const u8) callconv(.c) CURLcode;
extern fn curl_mime_encoder(part: ?*anyopaque, encoding: ?[*:0]const u8) callconv(.c) CURLcode;
extern fn curl_mime_data(part: ?*anyopaque, data: ?[*:0]const u8, datasize: usize) callconv(.c) CURLcode;
extern fn curl_mime_filedata(part: ?*anyopaque, filename: ?[*:0]const u8) callconv(.c) CURLcode;
extern fn curl_mime_data_cb(
    part: ?*anyopaque,
    datasize: i64,
    readfunc: ?*const fn ([*]u8, usize, usize, ?*anyopaque) callconv(.c) usize,
    seekfunc: ?*const fn (?*anyopaque, i64, c_int) callconv(.c) c_int,
    freefunc: ?*const fn (?*anyopaque) callconv(.c) void,
    arg: ?*anyopaque,
) callconv(.c) CURLcode;
extern fn curl_mime_subparts(part: ?*anyopaque, subparts: ?*anyopaque) callconv(.c) CURLcode;
extern fn curl_mime_headers(part: ?*anyopaque, headers: ?*curl_slist, take_ownership: c_int) callconv(.c) CURLcode;

extern fn curl_easy_ssls_import(
    easy: ?*anyopaque,
    session_key: ?[*:0]const u8,
    shmac: [*]const u8,
    shmac_len: usize,
    sdata: [*]const u8,
    sdata_len: usize,
) callconv(.c) CURLcode;

pub const curl_ssls_export_cb = *const fn (
    easy: ?*anyopaque,
    userptr: ?*anyopaque,
    session_key: [*:0]const u8,
    shmac: [*]const u8,
    shmac_len: usize,
    sdata: [*]const u8,
    sdata_len: usize,
    valid_until: i64,
    ietf_tls_id: c_int,
    alpn: ?[*:0]const u8,
    earlydata_max: usize,
) callconv(.c) CURLcode;

extern fn curl_easy_ssls_export(
    easy: ?*anyopaque,
    export_fn: curl_ssls_export_cb,
    userptr: ?*anyopaque,
) callconv(.c) CURLcode;

extern fn curlx_dyn_init(s: *Dynbuf, toobig: usize) callconv(.c) void;
extern fn curlx_dyn_free(s: *Dynbuf) callconv(.c) void;
extern fn curlx_dyn_addn(s: *Dynbuf, mem_ptr: ?*const anyopaque, len: usize) callconv(.c) CURLcode;
extern fn curlx_dyn_add(s: *Dynbuf, str: [*:0]const u8) callconv(.c) CURLcode;
extern fn curlx_dyn_addf(s: *Dynbuf, fmt: [*:0]const u8, ...) callconv(.c) CURLcode;
extern fn curlx_dyn_ptr(s: *const Dynbuf) callconv(.c) ?[*:0]u8;
extern fn curlx_dyn_len(s: *const Dynbuf) callconv(.c) usize;
extern fn curlx_dyn_setlen(s: *Dynbuf, set: usize) callconv(.c) CURLcode;

extern fn curlx_base64_encode(inputbuff: [*]const u8, insize: usize, outptr: *?[*:0]u8, outlen: *usize) callconv(.c) CURLcode;
extern fn curlx_base64_decode(src: [*:0]const u8, outptr: *?[*]u8, outlen: *usize) callconv(.c) CURLcode;
extern fn curlx_strerror(err: c_int, buf: [*]u8, buflen: usize) callconv(.c) [*:0]const u8;
extern fn curlx_str_number(linep: *[*:0]const u8, nump: *i64, max: i64) callconv(.c) c_int;
extern fn curlx_str_octal(linep: *[*:0]const u8, nump: *i64, max: i64) callconv(.c) c_int;
extern fn curlx_str_single(linep: *[*:0]const u8, byte: u8) callconv(.c) c_int;

extern fn slist_wc_append(list: ?*slist_wc, data: [*:0]const u8) callconv(.c) ?*slist_wc;
extern fn slist_wc_free_all(list: ?*slist_wc) callconv(.c) void;

extern fn warnf(fmt: [*:0]const u8, ...) callconv(.c) void;
extern fn notef(fmt: [*:0]const u8, ...) callconv(.c) void;
extern fn helpf(fmt: [*:0]const u8, ...) callconv(.c) void;
extern fn errorf(fmt: [*:0]const u8, ...) callconv(.c) void;

extern fn single_transfer_cleanup() callconv(.c) void;
extern fn get_terminal_columns() callconv(.c) c_uint;
extern fn my_get_line(fp: ?*anyopaque, line: *Dynbuf, err: *bool) callconv(.c) bool;
extern fn struplocompare4sort(p1: *const anyopaque, p2: *const anyopaque) callconv(.c) c_int;
extern fn sanitize_file_name(entino: *?[*:0]u8, file_name: ?[*:0]const u8, flags: c_int) callconv(.c) SANITIZEcode;

extern fn tool_zig_stdin() callconv(.c) ?*anyopaque;
extern fn tool_zig_get_errno() callconv(.c) c_int;

extern fn Curl_zig_ttyecho(enable: bool, fd: c_int) callconv(.c) bool;
extern fn Curl_zig_ssls_setopt(config: *OperationConfig, share: ?*anyopaque, easy: ?*anyopaque) callconv(.c) CURLcode;
extern fn Curl_zig_stdout() callconv(.c) ?*anyopaque;
extern fn Curl_zig_global_get_libcurl() callconv(.c) ?[*:0]const u8;
extern fn Curl_zig_stdin_regular_size(porigin: *i64, psize: *i64) callconv(.c) bool;
extern fn Curl_zig_fseek(stream: ?*anyopaque, offset: i64, whence: c_int) callconv(.c) c_int;
extern fn Curl_zig_sizeof_operation_config() callconv(.c) usize;
extern fn Curl_zig_sizeof_getout() callconv(.c) usize;
extern fn Curl_zig_config_init_bits(config: *OperationConfig) callconv(.c) void;
extern fn Curl_zig_global_init_storage(first: ?*OperationConfig) callconv(.c) ?*GlobalConfig;
extern fn Curl_zig_global_free_fields(g: *GlobalConfig) callconv(.c) ?*OperationConfig;
extern fn Curl_zig_getout_init_bits(config: *OperationConfig, node: *getout, num: i64) callconv(.c) void;
extern fn Curl_zig_config_is_jsoned(config: *OperationConfig) callconv(.c) bool;

// ============================================================================
// Internal helpers
// ============================================================================

inline fn isBlank(ch: u8) bool {
    return ch == ' ' or ch == '\t';
}

inline fn isNewline(ch: u8) bool {
    return ch == '\r' or ch == '\n';
}

inline fn isSpace(ch: u8) bool {
    return isBlank(ch) or (ch >= 0x0a and ch <= 0x0d);
}

fn cStrdup(s: [*:0]const u8) ?[*:0]u8 {
    const len = std.mem.len(s);
    if (len >= std.math.maxInt(usize)) return null;
    const raw = c.malloc(len + 1) orelse return null;
    const buf: [*]u8 = @ptrCast(raw);
    if (len > 0) {
        @memcpy(buf[0..len], s[0..len]);
    }
    buf[len] = 0;
    return @ptrCast(buf);
}

inline fn safeFreePtr(comptime T: type, ptr: *?T) void {
    if (ptr.*) |p| {
        c.free(@ptrCast(p));
        ptr.* = null;
    }
}

inline fn strZero(s: ?[*:0]u8) void {
    if (s) |ptr| {
        const len = std.mem.len(ptr);
        if (len > 0) {
            @memset(ptr[0..len], 0);
        }
    }
}

inline fn toolFopen(filename: [*:0]const u8, mode: [*:0]const u8) ?*anyopaque {
    if (builtin.os.tag == .windows) {
        return win32_c.curlx_win32_fopen(filename, mode);
    } else {
        return posix_c.fopen(filename, mode);
    }
}

inline fn toolFclose(file: ?*anyopaque) void {
    _ = c.fclose(file);
}

inline fn checkPrefix(prefix: []const u8, s: [*:0]const u8) bool {
    return curl_strnequal(s, prefix.ptr, prefix.len) != 0;
}

// ============================================================================
// 1. src/tool_getpass.c
// ============================================================================

pub export fn getpass_r(prompt: [*:0]const u8, buffer: [*]u8, buflen: usize) callconv(.c) [*:0]u8 {
    if (builtin.os.tag == .windows) {
        _ = c.fputs(prompt, tool_stderr);
        var i: usize = 0;
        while (i < buflen) : (i +%= 1) {
            const ch: u8 = @intCast(@as(u32, @bitCast(win32_c._getch())) & 0xff);
            buffer[i] = ch;
            if (ch == '\r' or ch == '\n') {
                buffer[i] = 0;
                break;
            } else if (ch == 0x08) {
                i -%= if (i >= 1) @as(usize, 2) else @as(usize, 1);
            }
        }
        _ = c.fputs("\n", tool_stderr);
        if (i == buflen and buflen > 0) {
            buffer[buflen - 1] = 0;
        }
        return @ptrCast(buffer);
    } else {
        const opened = posix_c.open("/dev/tty", 0);
        const fd: c_int = if (opened == -1) 0 else opened;
        const disabled = Curl_zig_ttyecho(false, fd);

        _ = c.fputs(prompt, tool_stderr);
        const nread = posix_c.read(fd, buffer, buflen);
        if (nread > 0) {
            const idx: usize = @intCast(nread - 1);
            buffer[idx] = 0;
        } else if (buflen > 0) {
            buffer[0] = 0;
        }

        if (disabled) {
            _ = c.fputs("\n", tool_stderr);
            _ = Curl_zig_ttyecho(true, fd);
        }

        if (fd != 0) {
            _ = posix_c.close(fd);
        }
        return @ptrCast(buffer);
    }
}

// ============================================================================
// 2. src/tool_helpers.c
// ============================================================================

pub export fn param2text(err: ParameterError) callconv(.c) [*:0]const u8 {
    return switch (err) {
        PARAM_GOT_EXTRA_PARAMETER => "had unsupported trailing garbage",
        PARAM_OPTION_UNKNOWN => "is unknown",
        PARAM_CONFIG_OPTION_UNKNOWN => "found an unknown config option",
        PARAM_REQUIRES_PARAMETER => "requires parameter",
        PARAM_BAD_USE => "is badly used here",
        PARAM_BAD_NUMERIC => "expected a proper numerical parameter",
        PARAM_NEGATIVE_NUMERIC => "expected a positive numerical parameter",
        PARAM_LIBCURL_DOESNT_SUPPORT => "the installed libcurl version does not support this",
        PARAM_LIBCURL_UNSUPPORTED_PROTOCOL => "a specified protocol is unsupported by libcurl",
        PARAM_NO_MEM => "out of memory",
        PARAM_NO_PREFIX => "the given option cannot be reversed with a --no- prefix",
        PARAM_NUMBER_TOO_LARGE => "too large number",
        PARAM_CONTDISP_RESUME_FROM => "--continue-at and --remote-header-name cannot be combined",
        PARAM_READ_ERROR => "error encountered when reading a file",
        PARAM_EXPAND_ERROR => "variable expansion failure",
        PARAM_BLANK_STRING => "blank argument where content is expected",
        PARAM_VAR_SYNTAX => "syntax error in --variable argument",
        else => "unknown error",
    };
}

const httpreq_names = [_][*:0]const u8{
    "",
    "GET (-G, --get)",
    "HEAD (-I, --head)",
    "multipart formpost (-F, --form)",
    "POST (-d, --data)",
    "PUT (-T, --upload-file)",
};

pub export fn SetHTTPrequest(req: HttpReq, store: *HttpReq) callconv(.c) c_int {
    if (store.* == TOOL_HTTPREQ_UNSPEC or store.* == req) {
        store.* = req;
        return 0;
    }
    const req_idx: usize = if (req < httpreq_names.len) req else 0;
    const store_idx: usize = if (store.* < httpreq_names.len) store.* else 0;
    warnf(
        "You can only select one HTTP request method! You asked for both %s and %s.",
        httpreq_names[req_idx],
        httpreq_names[store_idx],
    );
    return 1;
}

const httpreq_dflt = [_][*:0]const u8{
    "GET",
    "GET",
    "HEAD",
    "POST",
    "POST",
    "PUT",
};

pub export fn customrequest_helper(req: HttpReq, method: ?[*:0]const u8) callconv(.c) void {
    const m = method orelse return;
    const req_idx: usize = if (req < httpreq_dflt.len) req else 0;
    const dflt = httpreq_dflt[req_idx];
    if (curl_strequal(m, dflt) != 0) {
        notef("Unnecessary use of -X or --request, %s is already inferred.", dflt);
    } else if (curl_strequal(m, "head") != 0) {
        warnf("Setting custom HTTP method to HEAD with -X/--request may not work the way you want. Consider using -I/--head instead.");
    }
}

// ============================================================================
// 3. src/tool_ipfs.c
// ============================================================================

fn hasTrailingSlash(input: [*:0]const u8) bool {
    const len = std.mem.len(input);
    return len > 0 and input[len - 1] == '/';
}

fn ipfsGateway() ?[*:0]u8 {
    if (c.getenv("IPFS_GATEWAY")) |gateway_env| {
        return cStrdup(gateway_env);
    }

    var ipfs_path_c = curl_getenv("IPFS_PATH");
    if (ipfs_path_c == null) {
        if (c.getenv("HOME")) |home| {
            if (home[0] != 0) {
                ipfs_path_c = curl_maprintf("%s/.ipfs/", home);
            }
        }
        if (ipfs_path_c == null) {
            return null;
        }
    }

    const slash: [*:0]const u8 = if (hasTrailingSlash(ipfs_path_c.?)) "" else "/";
    const gateway_composed_c = curl_maprintf("%s%sgateway", ipfs_path_c.?, slash);
    if (gateway_composed_c == null) {
        curl_free(ipfs_path_c);
        return null;
    }

    const gfile = toolFopen(gateway_composed_c.?, FOPEN_READTEXT);
    curl_free(gateway_composed_c);

    if (gfile) |gf| {
        var dyn: Dynbuf = undefined;
        var gateway: ?[*:0]u8 = null;
        curlx_dyn_init(&dyn, MAX_GATEWAY_URL_LEN);

        while (true) {
            const ch = c.getc(gf);
            if (ch == -1 or ch == '\n' or ch == '\r') break;
            var ch_byte: u8 = @intCast(@as(u32, @bitCast(ch)) & 0xff);
            if (curlx_dyn_addn(&dyn, &ch_byte, 1) != CURLE_OK) {
                toolFclose(gf);
                curl_free(ipfs_path_c);
                return null;
            }
        }

        if (curlx_dyn_len(&dyn) != 0) {
            gateway = curlx_dyn_ptr(&dyn);
        }

        curl_free(ipfs_path_c);
        toolFclose(gf);
        return gateway;
    }

    curl_free(ipfs_path_c);
    return null;
}

pub export fn ipfs_url_rewrite(
    uh: ?*CURLU,
    protocol: [*:0]const u8,
    url: *?[*:0]u8,
    config: *OperationConfig,
) callconv(.c) CURLcode {
    var result: CURLcode = CURLE_URL_MALFORMAT;
    var gateway: ?[*:0]u8 = null;
    var gwhost: ?[*:0]u8 = null;
    var gwpath: ?[*:0]u8 = null;
    var gwquery: ?[*:0]u8 = null;
    var gwscheme: ?[*:0]u8 = null;
    var gwport: ?[*:0]u8 = null;
    var inputpath: ?[*:0]u8 = null;
    var cid: ?[*:0]u8 = null;
    var pathbuffer: ?[*:0]u8 = null;
    var cloneurl: ?[*:0]u8 = null;
    const gatewayurl = curl_url();

    blk: {
        if (gatewayurl == null) {
            result = CURLE_FAILED_INIT;
            break :blk;
        }

        if (curl_url_get(uh, CURLUPART_HOST, &cid, 0) != CURLUE_OK or cid == null) {
            break :blk;
        }

        if (config.ipfs_gateway) |cfg_gw| {
            if (curl_url_set(gatewayurl, CURLUPART_URL, cfg_gw, CURLU_GUESS_SCHEME) == CURLUE_OK) {
                gateway = cStrdup(cfg_gw);
                if (gateway == null) {
                    result = CURLE_URL_MALFORMAT;
                    break :blk;
                }
            } else {
                result = CURLE_BAD_FUNCTION_ARGUMENT;
                break :blk;
            }
        } else {
            gateway = ipfsGateway();
            if (gateway == null) {
                result = CURLE_FILE_COULDNT_READ_FILE;
                break :blk;
            }
            if (curl_url_set(gatewayurl, CURLUPART_URL, gateway, 0) != CURLUE_OK) {
                result = CURLE_URL_MALFORMAT;
                break :blk;
            }
        }

        if (curl_url_get(gatewayurl, CURLUPART_QUERY, &gwquery, 0) != CURLUE_NO_QUERY) {
            result = CURLE_URL_MALFORMAT;
            break :blk;
        }

        if (curl_url_get(gatewayurl, CURLUPART_HOST, &gwhost, CURLU_URLDECODE) != CURLUE_OK or
            curl_url_get(gatewayurl, CURLUPART_SCHEME, &gwscheme, CURLU_URLDECODE) != CURLUE_OK or
            curl_url_get(gatewayurl, CURLUPART_PORT, &gwport, CURLU_URLDECODE | CURLU_DEFAULT_PORT) != CURLUE_OK or
            curl_url_get(gatewayurl, CURLUPART_PATH, &gwpath, 0) != CURLUE_OK)
        {
            break :blk;
        }

        if (curl_url_get(uh, CURLUPART_PATH, &inputpath, 0) != CURLUE_OK) {
            break :blk;
        }

        if (curl_url_set(uh, CURLUPART_SCHEME, gwscheme, CURLU_URLENCODE) != CURLUE_OK or
            curl_url_set(uh, CURLUPART_HOST, gwhost, CURLU_URLENCODE) != CURLUE_OK or
            curl_url_set(uh, CURLUPART_PORT, gwport, CURLU_URLENCODE) != CURLUE_OK)
        {
            break :blk;
        }

        if (inputpath) |ip| {
            if (ip[0] == '/' and ip[1] == 0) {
                ip[0] = 0;
            }
        }

        const slash: [*:0]const u8 = if (hasTrailingSlash(gwpath.?)) "" else "/";
        const ip_str: [*:0]const u8 = if (inputpath) |ip| ip else "";
        pathbuffer = curl_maprintf("%s%s%s/%s%s", gwpath.?, slash, protocol, cid.?, ip_str);
        if (pathbuffer == null or curl_url_set(uh, CURLUPART_PATH, pathbuffer, 0) != CURLUE_OK) {
            break :blk;
        }

        safeFreePtr([*:0]u8, url);

        if (curl_url_get(uh, CURLUPART_URL, &cloneurl, CURLU_URLENCODE) != CURLUE_OK) {
            break :blk;
        }

        url.* = cStrdup(cloneurl.?);
        curl_free(cloneurl);
        if (url.* == null) {
            break :blk;
        }

        result = CURLE_OK;
    }

    c.free(gateway);
    curl_free(gwhost);
    curl_free(gwpath);
    curl_free(gwquery);
    curl_free(inputpath);
    curl_free(gwscheme);
    curl_free(gwport);
    curl_free(cid);
    curl_free(pathbuffer);
    curl_url_cleanup(gatewayurl);

    switch (result) {
        CURLE_URL_MALFORMAT => helpf("malformed target URL"),
        CURLE_FILE_COULDNT_READ_FILE => helpf("IPFS automatic gateway detection failed"),
        CURLE_BAD_FUNCTION_ARGUMENT => helpf("--ipfs-gateway was given a malformed URL"),
        else => {},
    }
    return result;
}

// ============================================================================
// 4. src/tool_libinfo.c
// ============================================================================

var no_protos: ?[*:0]const u8 = null;

pub export var curlinfo: ?*curl_version_info_data = null;
pub export var built_in_protos: [*]const ?[*:0]const u8 = @ptrCast(&no_protos);
pub export var proto_count: usize = 0;

pub export var proto_file: ?[*:0]const u8 = null;
pub export var proto_ftp: ?[*:0]const u8 = null;
pub export var proto_ftps: ?[*:0]const u8 = null;
pub export var proto_http: ?[*:0]const u8 = null;
pub export var proto_https: ?[*:0]const u8 = null;
pub export var proto_rtsp: ?[*:0]const u8 = null;
pub export var proto_scp: ?[*:0]const u8 = null;
pub export var proto_sftp: ?[*:0]const u8 = null;
pub export var proto_tftp: ?[*:0]const u8 = null;
pub export var proto_ipfs: ?[*:0]const u8 = "ipfs";
pub export var proto_ipns: ?[*:0]const u8 = "ipns";

const ProtoNameToken = struct {
    proto_name: [*:0]const u8,
    proto_tokenp: *?[*:0]const u8,
};

const possibly_built_in = [_]ProtoNameToken{
    .{ .proto_name = "file", .proto_tokenp = &proto_file },
    .{ .proto_name = "ftp", .proto_tokenp = &proto_ftp },
    .{ .proto_name = "ftps", .proto_tokenp = &proto_ftps },
    .{ .proto_name = "http", .proto_tokenp = &proto_http },
    .{ .proto_name = "https", .proto_tokenp = &proto_https },
    .{ .proto_name = "rtsp", .proto_tokenp = &proto_rtsp },
    .{ .proto_name = "scp", .proto_tokenp = &proto_scp },
    .{ .proto_name = "sftp", .proto_tokenp = &proto_sftp },
    .{ .proto_name = "tftp", .proto_tokenp = &proto_tftp },
};

pub export var feature_altsvc: bool = false;
pub export var feature_brotli: bool = false;
pub export var feature_hsts: bool = false;
pub export var feature_http2: bool = false;
pub export var feature_http3: bool = false;
pub export var feature_httpsig: bool = false;
pub export var feature_httpsproxy: bool = false;
pub export var feature_libz: bool = false;
pub export var feature_ntlm: bool = false;
pub export var feature_ntlm_wb: bool = false;
pub export var feature_spnego: bool = false;
pub export var feature_ssl: bool = false;
pub export var feature_zstd: bool = false;
pub export var feature_ech: bool = false;
pub export var feature_ssls_export: bool = false;

const FeatureNamePresent = struct {
    feature_name: [*:0]const u8,
    feature_presentp: ?*bool,
    feature_bitmask: c_int,
};

const maybe_feature = [_]FeatureNamePresent{
    .{ .feature_name = "alt-svc", .feature_presentp = &feature_altsvc, .feature_bitmask = CURL_VERSION_ALTSVC },
    .{ .feature_name = "AsynchDNS", .feature_presentp = null, .feature_bitmask = CURL_VERSION_ASYNCHDNS },
    .{ .feature_name = "brotli", .feature_presentp = &feature_brotli, .feature_bitmask = CURL_VERSION_BROTLI },
    .{ .feature_name = "CharConv", .feature_presentp = null, .feature_bitmask = CURL_VERSION_CONV },
    .{ .feature_name = "Debug", .feature_presentp = null, .feature_bitmask = CURL_VERSION_DEBUG },
    .{ .feature_name = "ECH", .feature_presentp = &feature_ech, .feature_bitmask = 0 },
    .{ .feature_name = "gsasl", .feature_presentp = null, .feature_bitmask = CURL_VERSION_GSASL },
    .{ .feature_name = "GSS-API", .feature_presentp = null, .feature_bitmask = CURL_VERSION_GSSAPI },
    .{ .feature_name = "HSTS", .feature_presentp = &feature_hsts, .feature_bitmask = CURL_VERSION_HSTS },
    .{ .feature_name = "HTTP2", .feature_presentp = &feature_http2, .feature_bitmask = CURL_VERSION_HTTP2 },
    .{ .feature_name = "HTTP3", .feature_presentp = &feature_http3, .feature_bitmask = CURL_VERSION_HTTP3 },
    .{ .feature_name = "HTTPS-proxy", .feature_presentp = &feature_httpsproxy, .feature_bitmask = CURL_VERSION_HTTPS_PROXY },
    .{ .feature_name = "HTTPSIG", .feature_presentp = &feature_httpsig, .feature_bitmask = 0 },
    .{ .feature_name = "IDN", .feature_presentp = null, .feature_bitmask = CURL_VERSION_IDN },
    .{ .feature_name = "IPv6", .feature_presentp = null, .feature_bitmask = CURL_VERSION_IPV6 },
    .{ .feature_name = "Kerberos", .feature_presentp = null, .feature_bitmask = CURL_VERSION_KERBEROS5 },
    .{ .feature_name = "Largefile", .feature_presentp = null, .feature_bitmask = CURL_VERSION_LARGEFILE },
    .{ .feature_name = "libz", .feature_presentp = &feature_libz, .feature_bitmask = CURL_VERSION_LIBZ },
    .{ .feature_name = "MultiSSL", .feature_presentp = null, .feature_bitmask = CURL_VERSION_MULTI_SSL },
    .{ .feature_name = "NTLM", .feature_presentp = &feature_ntlm, .feature_bitmask = CURL_VERSION_NTLM },
    .{ .feature_name = "NTLM_WB", .feature_presentp = &feature_ntlm_wb, .feature_bitmask = CURL_VERSION_NTLM_WB },
    .{ .feature_name = "PSL", .feature_presentp = null, .feature_bitmask = CURL_VERSION_PSL },
    .{ .feature_name = "SPNEGO", .feature_presentp = &feature_spnego, .feature_bitmask = CURL_VERSION_SPNEGO },
    .{ .feature_name = "SSL", .feature_presentp = &feature_ssl, .feature_bitmask = CURL_VERSION_SSL },
    .{ .feature_name = "SSPI", .feature_presentp = null, .feature_bitmask = CURL_VERSION_SSPI },
    .{ .feature_name = "SSLS-EXPORT", .feature_presentp = &feature_ssls_export, .feature_bitmask = 0 },
    .{ .feature_name = "threadsafe", .feature_presentp = null, .feature_bitmask = CURL_VERSION_THREADSAFE },
    .{ .feature_name = "Unicode", .feature_presentp = null, .feature_bitmask = CURL_VERSION_UNICODE },
    .{ .feature_name = "UnixSockets", .feature_presentp = null, .feature_bitmask = CURL_VERSION_UNIX_SOCKETS },
    .{ .feature_name = "zstd", .feature_presentp = &feature_zstd, .feature_bitmask = CURL_VERSION_ZSTD },
};

var fnames: [maybe_feature.len + 1]?[*:0]const u8 = @splat(null);
pub export var feature_names: [*]const ?[*:0]const u8 = @ptrCast(&fnames);
pub export var feature_count: usize = 0;

pub export fn get_libcurl_info() callconv(.c) CURLcode {
    const info = curl_version_info(CURLVERSION_NOW) orelse return CURLE_FAILED_INIT;
    curlinfo = info;

    if (info.protocols) |protos| {
        built_in_protos = protos;
        var idx: usize = 0;
        while (built_in_protos[idx]) |bproto| : (idx += 1) {
            for (possibly_built_in) |entry| {
                if (curl_strequal(entry.proto_name, bproto) != 0) {
                    entry.proto_tokenp.* = bproto;
                    break;
                }
            }
        }
        proto_count = idx;
    }

    if (info.age >= CURLVERSION_ELEVENTH and info.feature_names != null) {
        feature_names = info.feature_names.?;
    } else {
        var cpp_idx: usize = 0;
        for (maybe_feature) |entry| {
            if ((info.features & entry.feature_bitmask) != 0) {
                fnames[cpp_idx] = entry.feature_name;
                cpp_idx += 1;
            }
        }
        fnames[cpp_idx] = null;
        feature_names = @ptrCast(&fnames);
    }

    feature_count = 0;
    var fidx: usize = 0;
    while (feature_names[fidx]) |fname| : (fidx += 1) {
        for (maybe_feature) |entry| {
            if (curl_strequal(entry.feature_name, fname) != 0) {
                if (entry.feature_presentp) |fp| {
                    fp.* = true;
                }
                break;
            }
        }
        feature_count += 1;
    }

    return CURLE_OK;
}

pub export fn proto_token(proto: ?[*:0]const u8) callconv(.c) ?[*:0]const u8 {
    const p = proto orelse return null;
    var idx: usize = 0;
    while (built_in_protos[idx]) |bproto| : (idx += 1) {
        if (curl_strequal(bproto, p) != 0) {
            return bproto;
        }
    }
    return null;
}

// ============================================================================
// 5. src/tool_operhlp.c
// ============================================================================

pub export fn clean_getout(config: ?*OperationConfig) callconv(.c) void {
    if (config) |cfg| {
        var node = cfg.url_list;
        while (node) |n| {
            const next = n.next;
            safeFreePtr([*:0]u8, &n.url);
            safeFreePtr([*:0]u8, &n.outfile);
            safeFreePtr([*:0]u8, &n.infile);
            c.free(n);
            node = next;
        }
        cfg.url_list = null;
        single_transfer_cleanup();
    }
}

pub export fn output_expected(url: ?[*:0]const u8, uploadfile: ?[*:0]const u8) callconv(.c) bool {
    if (uploadfile == null) {
        return true;
    }
    const u = url orelse return false;
    if (checkPrefix("http://", u) or checkPrefix("https://", u)) {
        return true;
    }
    return false;
}

pub export fn stdin_upload(uploadfile: [*:0]const u8) callconv(.c) bool {
    const s = std.mem.span(uploadfile);
    return std.mem.eql(u8, s, "-") or std.mem.eql(u8, s, ".");
}

pub export fn urlerr_cvt(ucode: CURLUcode) callconv(.c) CURLcode {
    if (ucode == CURLUE_OUT_OF_MEMORY) {
        return CURLE_OUT_OF_MEMORY;
    } else if (ucode == CURLUE_UNSUPPORTED_SCHEME) {
        return CURLE_UNSUPPORTED_PROTOCOL;
    } else if (ucode == CURLUE_LACKS_IDN) {
        return CURLE_NOT_BUILT_IN;
    } else if (ucode == CURLUE_BAD_HANDLE) {
        return CURLE_BAD_FUNCTION_ARGUMENT;
    }
    return CURLE_URL_MALFORMAT;
}

pub export fn add_file_name_to_url(
    curl: ?*anyopaque,
    inurlp: *?[*:0]u8,
    filename: [*:0]const u8,
) callconv(.c) CURLcode {
    var result: CURLcode = CURLE_OUT_OF_MEMORY;
    const uh = curl_url();
    var path: ?[*:0]u8 = null;
    var query: ?[*:0]u8 = null;

    if (uh != null) {
        out: {
            var uerr = curl_url_set(uh, CURLUPART_URL, inurlp.*, CURLU_GUESS_SCHEME | CURLU_NON_SUPPORT_SCHEME);
            if (uerr != CURLUE_OK) {
                result = urlerr_cvt(uerr);
                break :out;
            }
            uerr = curl_url_get(uh, CURLUPART_PATH, &path, 0);
            if (uerr != CURLUE_OK) {
                result = urlerr_cvt(uerr);
                break :out;
            }
            uerr = curl_url_get(uh, CURLUPART_QUERY, &query, 0);
            if (uerr == CURLUE_OUT_OF_MEMORY) {
                result = urlerr_cvt(uerr);
                break :out;
            }
            if (uerr == CURLUE_OK and query != null) {
                curl_free(query);
                result = CURLE_OK;
                break :out;
            }

            const path_slice = std.mem.span(path.?);
            const last_slash = std.mem.findScalarLast(u8, path_slice, '/');
            const has_trailing_slash = last_slash != null;
            const no_filename_part = if (last_slash) |idx| (idx + 1 == path_slice.len) else true;

            if (no_filename_part) {
                const fn_slice = std.mem.span(filename);
                const slash_idx = std.mem.findScalarLast(u8, fn_slice, '/');
                const search_from: usize = if (slash_idx) |si| si else 0;
                const bslash_idx = std.mem.findScalarLast(u8, fn_slice[search_from..], '\\');

                const filep_offset: usize = if (bslash_idx) |bi|
                    search_from + bi + 1
                else if (slash_idx) |si|
                    si + 1
                else
                    0;

                const filep: [*:0]const u8 = filename + filep_offset;
                if (curl_easy_escape(curl, filep, 0)) |encfile| {
                    const newpath = if (has_trailing_slash)
                        curl_maprintf("%s%s", path.?, encfile)
                    else
                        curl_maprintf("%s/%s", path.?, encfile);

                    curl_free(encfile);
                    if (newpath == null) {
                        break :out;
                    }
                    uerr = curl_url_set(uh, CURLUPART_PATH, newpath, 0);
                    curl_free(newpath);
                    if (uerr != CURLUE_OK) {
                        result = urlerr_cvt(uerr);
                        break :out;
                    }
                    var newurl: ?[*:0]u8 = null;
                    uerr = curl_url_get(uh, CURLUPART_URL, &newurl, CURLU_DEFAULT_SCHEME | CURLU_NO_GUESS_SCHEME);
                    if (uerr != CURLUE_OK) {
                        result = urlerr_cvt(uerr);
                        break :out;
                    }
                    c.free(inurlp.*);
                    inurlp.* = cStrdup(newurl.?);
                    curl_free(newurl);
                    result = if (inurlp.* != null) CURLE_OK else CURLE_OUT_OF_MEMORY;
                }
            } else {
                result = CURLE_OK;
            }
        }
    }

    curl_url_cleanup(uh);
    curl_free(path);
    return result;
}

const DEFAULT_FILENAME = "curl_response";

pub export fn get_url_file_name(
    filename: *?[*:0]u8,
    url: [*:0]const u8,
    sc: *SANITIZEcode,
) callconv(.c) CURLcode {
    var uh = curl_url();
    var path: ?[*:0]u8 = null;

    sc.* = SANITIZE_ERR_OK;
    if (uh == null) {
        return CURLE_OUT_OF_MEMORY;
    }

    filename.* = null;

    var uerr = curl_url_set(uh, CURLUPART_URL, url, CURLU_GUESS_SCHEME);
    if (uerr == CURLUE_OK) {
        uerr = curl_url_get(uh, CURLUPART_PATH, &path, 0);
        curl_url_cleanup(uh);
        uh = null;
        if (uerr == CURLUE_OK) {
            const p = path.?;
            var len = std.mem.len(p);
            while (len > 0 and (p[len - 1] == '/' or p[len - 1] == '\\')) {
                len -= 1;
                p[len] = 0;
            }
            const slice = p[0..len];
            const slash_idx = std.mem.findScalarLast(u8, slice, '/');
            const search_start: usize = if (slash_idx) |si| si + 1 else 0;
            const bslash_idx = std.mem.findScalarLast(u8, slice[search_start..], '\\');

            const pc_idx: ?usize = if (bslash_idx) |bi|
                search_start + bi
            else
                slash_idx;

            if (pc_idx) |idx| {
                filename.* = cStrdup(p + idx + 1);
            } else {
                filename.* = cStrdup(DEFAULT_FILENAME);
                if (filename.* != null) {
                    warnf("No remote filename, uses \"" ++ DEFAULT_FILENAME ++ "\"");
                }
            }

            curl_free(path);
            if (filename.* == null) {
                return CURLE_OUT_OF_MEMORY;
            }

            if (builtin.os.tag == .windows) {
                var sanitized: ?[*:0]u8 = null;
                sc.* = sanitize_file_name(&sanitized, filename.*, 0);
                safeFreePtr([*:0]u8, filename);
                if (sc.* != SANITIZE_ERR_OK) {
                    return CURLE_BAD_FUNCTION_ARGUMENT;
                }
                filename.* = sanitized;
            }

            return CURLE_OK;
        }
    }
    curl_url_cleanup(uh);
    return urlerr_cvt(uerr);
}

// ============================================================================
// 6. src/tool_ssls.c
// ============================================================================

fn toolSslsEasy(config: *OperationConfig, share: ?*anyopaque, peasy: *?*anyopaque) CURLcode {
    const easy = curl_easy_init() orelse {
        peasy.* = null;
        return CURLE_OUT_OF_MEMORY;
    };
    peasy.* = easy;
    return Curl_zig_ssls_setopt(config, share, easy);
}

pub export fn tool_ssls_load(
    config: *OperationConfig,
    share: ?*anyopaque,
    filename: [*:0]const u8,
) callconv(.c) CURLcode {
    var easy: ?*anyopaque = null;
    var buf: Dynbuf = undefined;
    var shmac: ?[*]u8 = null;
    var sdata: ?[*]u8 = null;
    var shmac_len: usize = 0;
    var sdata_len: usize = 0;
    var result: CURLcode = CURLE_OK;
    var i: c_int = 0;
    var imported: c_int = 0;
    var err_flag: bool = false;

    curlx_dyn_init(&buf, MAX_SSLS_LINE);
    const fp = toolFopen(filename, FOPEN_READTEXT);
    if (fp == null) {
        notef("SSL session file does not exist (yet?): %s", filename);
        curlx_dyn_free(&buf);
        return CURLE_OK;
    }

    result = toolSslsEasy(config, share, &easy);
    if (result == CURLE_OK) {
        while (my_get_line(fp, &buf, &err_flag)) {
            i += 1;
            safeFreePtr([*]u8, &shmac);
            safeFreePtr([*]u8, &sdata);
            const line = curlx_dyn_ptr(&buf) orelse continue;
            const line_len = std.mem.len(line);
            const colon_idx = std.mem.findScalar(u8, line[0..line_len], ':') orelse {
                warnf("unrecognized line %d in SSL session file %s", i, filename);
                continue;
            };
            line[colon_idx] = 0;
            result = curlx_base64_decode(line, &shmac, &shmac_len);
            if (result != CURLE_OK) {
                warnf("invalid shmax base64 encoding in line %d", i);
                continue;
            }
            const sdata_line: [*:0]u8 = line + colon_idx + 1;
            var sdata_str_len = std.mem.len(sdata_line);
            while (sdata_str_len > 1 and (sdata_line[sdata_str_len - 1] == '\n' or
                sdata_line[sdata_str_len - 1] == '\r' or
                isBlank(sdata_line[0])))
            {
                sdata_str_len -= 1;
                sdata_line[sdata_str_len] = 0;
            }
            result = curlx_base64_decode(sdata_line, &sdata, &sdata_len);
            if (result != CURLE_OK) {
                warnf("invalid sdata base64 encoding in line %d: %s", i, sdata_line);
                continue;
            }
            result = curl_easy_ssls_import(easy, null, shmac.?, shmac_len, sdata.?, sdata_len);
            if (result != CURLE_OK) {
                warnf("import of session from line %d rejected(%d)", i, @as(c_int, @intCast(result)));
                continue;
            }
            imported += 1;
        }
        result = if (err_flag) CURLE_FAILED_INIT else CURLE_OK;
    }

    if (easy != null) {
        curl_easy_cleanup(easy);
    }
    toolFclose(fp);
    curlx_dyn_free(&buf);
    c.free(shmac);
    c.free(sdata);
    return result;
}

const ToolSslsCtx = extern struct {
    fp: ?*anyopaque,
    exported: c_int,
};

fn toolSslsExp(
    easy: ?*anyopaque,
    userptr: ?*anyopaque,
    session_key: [*:0]const u8,
    shmac: [*]const u8,
    shmac_len: usize,
    sdata: [*]const u8,
    sdata_len: usize,
    valid_until: i64,
    ietf_tls_id: c_int,
    alpn: ?[*:0]const u8,
    earlydata_max: usize,
) callconv(.c) CURLcode {
    _ = easy;
    _ = valid_until;
    _ = ietf_tls_id;
    _ = alpn;
    _ = earlydata_max;

    const ctx: *ToolSslsCtx = @ptrCast(@alignCast(userptr.?));
    var enc: ?[*:0]u8 = null;
    var enc_len: usize = 0;
    var result: CURLcode = CURLE_OK;

    if (ctx.exported == 0) {
        _ = c.fputs(
            "# Your SSL session cache. https://curl.se/docs/ssl-sessions.html\n" ++
                "# This file was generated by libcurl! Edit at your own risk.\n",
            ctx.fp,
        );
    }

    out: {
        result = curlx_base64_encode(shmac, shmac_len, &enc, &enc_len);
        if (result != CURLE_OK) break :out;
        result = CURLE_WRITE_ERROR;
        if (c.fwrite(enc.?, 1, enc_len, ctx.fp) != enc_len) break :out;
        if (c.fputc(':', ctx.fp) == -1) break :out;
        safeFreePtr([*:0]u8, &enc);
        result = curlx_base64_encode(sdata, sdata_len, &enc, &enc_len);
        if (result != CURLE_OK) break :out;
        result = CURLE_WRITE_ERROR;
        if (c.fwrite(enc.?, 1, enc_len, ctx.fp) != enc_len) break :out;
        if (c.fputc('\n', ctx.fp) == -1) break :out;
        result = CURLE_OK;
        ctx.exported += 1;
    }

    if (result != CURLE_OK) {
        warnf("Warning: error saving SSL session for '%s': %d", session_key, @as(c_int, @intCast(result)));
    }
    c.free(enc);
    return result;
}

pub export fn tool_ssls_save(
    config: *OperationConfig,
    share: ?*anyopaque,
    filename: [*:0]const u8,
) callconv(.c) CURLcode {
    var ctx = ToolSslsCtx{
        .fp = toolFopen(filename, FOPEN_WRITETEXT),
        .exported = 0,
    };
    var easy: ?*anyopaque = null;
    var result: CURLcode = CURLE_OK;

    if (ctx.fp == null) {
        warnf("Warning: Failed to create SSL session file %s", filename);
        return CURLE_OK;
    }

    result = toolSslsEasy(config, share, &easy);
    if (result == CURLE_OK) {
        result = curl_easy_ssls_export(easy, toolSslsExp, &ctx);
    }

    if (easy != null) {
        curl_easy_cleanup(easy);
    }
    toolFclose(ctx.fp);
    return result;
}

// ============================================================================
// 7. src/tool_easysrc.c
// ============================================================================

pub export var easysrc_decl: ?*slist_wc = null;
pub export var easysrc_data: ?*slist_wc = null;
pub export var easysrc_code: ?*slist_wc = null;
pub export var easysrc_toohard: ?*slist_wc = null;
pub export var easysrc_clean: ?*slist_wc = null;
pub export var easysrc_mime_count: c_int = 0;
pub export var easysrc_slist_count: c_int = 0;

var easysrc_performed: bool = false;
var easysrc_pending_reset: bool = false;

const srchead = [_][*:0]const u8{
    "/********* Sample code generated by the curl command line tool **********",
    " * All curl_easy_setopt() options are documented at:",
    " * https://curl.se/libcurl/c/curl_easy_setopt.html",
    " ************************************************************************/",
    "#include <curl/curl.h>",
    "",
    "int main(int argc, char *argv[])",
    "{",
    "  CURLcode result;",
    "  CURL *curl;",
};

const srchard = [_][*:0]const u8{
    "/* Here is a list of options the curl code used that cannot get generated",
    "   as source easily. You may choose to either not use them or implement",
    "   them yourself.",
    "",
};

const srcend = [_][*:0]const u8{
    "",
    "  return (int)result;",
    "}",
    "/**** End of sample code ****/",
};

fn easysrcFree() void {
    slist_wc_free_all(easysrc_decl);
    easysrc_decl = null;
    slist_wc_free_all(easysrc_data);
    easysrc_data = null;
    slist_wc_free_all(easysrc_code);
    easysrc_code = null;
    slist_wc_free_all(easysrc_toohard);
    easysrc_toohard = null;
    slist_wc_free_all(easysrc_clean);
    easysrc_clean = null;
}

pub export fn easysrc_add(plist: *?*slist_wc, line: [*:0]const u8) callconv(.c) CURLcode {
    if (easysrc_pending_reset and plist == &easysrc_code) {
        easysrc_pending_reset = false;
        const reset_res = easysrc_add(&easysrc_code, "curl_easy_reset(curl);");
        if (reset_res != CURLE_OK) {
            return reset_res;
        }
    }
    const list = slist_wc_append(plist.*, line);
    if (list == null) {
        easysrcFree();
        return CURLE_OUT_OF_MEMORY;
    }
    plist.* = list;
    return CURLE_OK;
}

pub export fn Curl_zig_easysrc_add_formatted(plist: *?*slist_wc, bufp: ?[*:0]u8) callconv(.c) CURLcode {
    const b = bufp orelse return CURLE_OUT_OF_MEMORY;
    const result = easysrc_add(plist, b);
    curl_free(b);
    return result;
}

pub export fn easysrc_init() callconv(.c) CURLcode {
    easysrc_performed = false;
    return easysrc_add(&easysrc_code, "curl = curl_easy_init();");
}

pub export fn easysrc_is_first() callconv(.c) bool {
    return !easysrc_performed;
}

pub export fn easysrc_perform() callconv(.c) CURLcode {
    var result: CURLcode = CURLE_OK;
    if (easysrc_toohard != null) {
        result = easysrc_add(&easysrc_code, "");
        for (srchard) |line| {
            if (result != CURLE_OK) break;
            result = easysrc_add(&easysrc_code, line);
        }
        if (easysrc_toohard) |th| {
            var ptr = th.first;
            while (ptr != null and result == CURLE_OK) : (ptr = ptr.?.next) {
                if (ptr.?.data) |d| {
                    result = easysrc_add(&easysrc_code, d);
                }
            }
        }
        if (result == CURLE_OK) {
            result = easysrc_add(&easysrc_code, "");
        }
        if (result == CURLE_OK) {
            result = easysrc_add(&easysrc_code, "*/");
        }
        slist_wc_free_all(easysrc_toohard);
        easysrc_toohard = null;
    }

    if (result == CURLE_OK) {
        result = easysrc_add(&easysrc_code, "");
    }
    if (result == CURLE_OK) {
        result = easysrc_add(&easysrc_code, "result = curl_easy_perform(curl);");
    }
    if (result == CURLE_OK) {
        result = easysrc_add(&easysrc_code, "");
    }
    if (result == CURLE_OK) {
        easysrc_performed = true;
        easysrc_pending_reset = true;
    }
    return result;
}

pub export fn easysrc_cleanup() callconv(.c) CURLcode {
    easysrc_pending_reset = false;
    var result = easysrc_add(&easysrc_code, "curl_easy_cleanup(curl);");
    if (result == CURLE_OK) {
        result = easysrc_add(&easysrc_code, "curl = NULL;");
    }
    return result;
}

pub export fn dumpeasysrc() callconv(.c) void {
    const o = Curl_zig_global_get_libcurl() orelse {
        easysrcFree();
        return;
    };

    var out: ?*anyopaque = null;
    var fopened = false;
    if (!std.mem.eql(u8, std.mem.span(o), "-")) {
        out = toolFopen(o, FOPEN_WRITETEXT);
        fopened = true;
    } else {
        out = Curl_zig_stdout();
    }

    if (out == null) {
        warnf("Failed to open %s to write libcurl code", o);
    } else {
        for (srchead) |line| {
            _ = curl_mfprintf(out, "%s\n", line);
        }

        if (easysrc_decl) |decl| {
            var ptr = decl.first;
            while (ptr) |p| : (ptr = p.next) {
                if (p.data) |d| {
                    _ = curl_mfprintf(out, "  %s\n", d);
                }
            }
        }

        if (easysrc_data) |data| {
            _ = curl_mfprintf(out, "\n");
            var ptr = data.first;
            while (ptr) |p| : (ptr = p.next) {
                if (p.data) |d| {
                    _ = curl_mfprintf(out, "  %s\n", d);
                }
            }
        }

        _ = curl_mfprintf(out, "\n");
        if (easysrc_code) |code| {
            var ptr = code.first;
            while (ptr) |p| : (ptr = p.next) {
                if (p.data) |d| {
                    if (d[0] != 0) {
                        _ = curl_mfprintf(out, "  %s\n", d);
                    } else {
                        _ = curl_mfprintf(out, "\n");
                    }
                }
            }
        }

        if (easysrc_clean) |clean| {
            var ptr = clean.first;
            while (ptr) |p| : (ptr = p.next) {
                if (p.data) |d| {
                    _ = curl_mfprintf(out, "  %s\n", d);
                }
            }
        }

        for (srcend) |line| {
            _ = curl_mfprintf(out, "%s\n", line);
        }

        if (fopened) {
            toolFclose(out);
        }
    }

    easysrcFree();
}

// ============================================================================
// 8. src/tool_cfgable.c
// ============================================================================

pub export var global: ?*GlobalConfig = null;

pub export fn config_alloc() callconv(.c) ?*OperationConfig {
    const raw = c.calloc(1, Curl_zig_sizeof_operation_config()) orelse return null;
    const config: *OperationConfig = @ptrCast(@alignCast(raw));

    config.maxredirs = DEFAULT_MAXREDIRS;
    config.proto_default = null;
    config.happy_eyeballs_timeout_ms = CURL_HET_DEFAULT;
    config.file_clobber_mode = CLOBBER_DEFAULT;
    config.upload_flags = CURLULFLAG_SEEN;
    Curl_zig_config_init_bits(config);
    curlx_dyn_init(&config.postdata, MAX_FILE2MEMORY);
    return config;
}

fn freeConfigFields(config: *OperationConfig) void {
    safeFreePtr([*:0]u8, &config.useragent);
    safeFreePtr([*:0]u8, &config.altsvc);
    safeFreePtr([*:0]u8, &config.hsts);
    safeFreePtr([*:0]u8, &config.haproxy_clientip);
    curl_slist_free_all(config.cookies);
    safeFreePtr([*:0]u8, &config.cookiejar);
    curl_slist_free_all(config.cookiefiles);

    curlx_dyn_free(&config.postdata);
    safeFreePtr([*:0]u8, &config.query);
    safeFreePtr([*:0]u8, &config.referer);

    safeFreePtr([*:0]u8, &config.headerfile);
    safeFreePtr([*:0]u8, &config.ftpport);
    safeFreePtr([*:0]u8, &config.iface);

    safeFreePtr([*:0]u8, &config.range);

    safeFreePtr([*:0]u8, &config.userpwd);
    safeFreePtr([*:0]u8, &config.proxyuserpwd);
    safeFreePtr([*:0]u8, &config.proxy);

    safeFreePtr([*:0]u8, &config.dns_ipv6_addr);
    safeFreePtr([*:0]u8, &config.dns_ipv4_addr);
    safeFreePtr([*:0]u8, &config.dns_interface);
    safeFreePtr([*:0]u8, &config.dns_servers);

    safeFreePtr([*:0]u8, &config.noproxy);

    safeFreePtr([*:0]u8, &config.mail_from);
    curl_slist_free_all(config.mail_rcpt);
    safeFreePtr([*:0]u8, &config.mail_auth);

    safeFreePtr([*:0]u8, &config.netrc_file);
    safeFreePtr([*:0]u8, &config.output_dir);
    safeFreePtr([*:0]u8, &config.proto_str);
    safeFreePtr([*:0]u8, &config.proto_redir_str);

    var urlnode = config.url_list;
    while (urlnode) |n| {
        const next = n.next;
        safeFreePtr([*:0]u8, &n.url);
        safeFreePtr([*:0]u8, &n.outfile);
        safeFreePtr([*:0]u8, &n.infile);
        c.free(n);
        urlnode = next;
    }
    config.url_list = null;
    config.url_last = null;
    config.url_get = null;
    config.url_out = null;

    safeFreePtr([*:0]u8, &config.ipfs_gateway);
    safeFreePtr([*:0]u8, &config.doh_url);
    safeFreePtr([*:0]u8, &config.cipher_list);
    safeFreePtr([*:0]u8, &config.proxy_cipher_list);
    safeFreePtr([*:0]u8, &config.cipher13_list);
    safeFreePtr([*:0]u8, &config.proxy_cipher13_list);
    safeFreePtr([*:0]u8, &config.cert);
    safeFreePtr([*:0]u8, &config.proxy_cert);
    safeFreePtr([*:0]u8, &config.cert_type);
    safeFreePtr([*:0]u8, &config.proxy_cert_type);
    safeFreePtr([*:0]u8, &config.cacert);
    safeFreePtr([*:0]u8, &config.login_options);
    safeFreePtr([*:0]u8, &config.proxy_cacert);
    safeFreePtr([*:0]u8, &config.capath);
    safeFreePtr([*:0]u8, &config.proxy_capath);
    safeFreePtr([*:0]u8, &config.crlfile);
    safeFreePtr([*:0]u8, &config.pinnedpubkey);
    safeFreePtr([*:0]u8, &config.proxy_pinnedpubkey);
    safeFreePtr([*:0]u8, &config.proxy_crlfile);
    safeFreePtr([*:0]u8, &config.key);
    safeFreePtr([*:0]u8, &config.proxy_key);
    safeFreePtr([*:0]u8, &config.key_type);
    safeFreePtr([*:0]u8, &config.proxy_key_type);
    strZero(config.key_passwd);
    safeFreePtr([*:0]u8, &config.key_passwd);
    strZero(config.proxy_key_passwd);
    safeFreePtr([*:0]u8, &config.proxy_key_passwd);
    safeFreePtr([*:0]u8, &config.pubkey);
    safeFreePtr([*:0]u8, &config.hostpubmd5);
    safeFreePtr([*:0]u8, &config.hostpubsha256);
    safeFreePtr([*:0]u8, &config.engine);
    safeFreePtr([*:0]u8, &config.etag_save_file);
    safeFreePtr([*:0]u8, &config.etag_compare_file);
    safeFreePtr([*:0]u8, &config.ssl_ec_curves);
    safeFreePtr([*:0]u8, &config.ssl_signature_algorithms);
    safeFreePtr([*:0]u8, &config.request_target);
    safeFreePtr([*:0]u8, &config.customrequest);
    safeFreePtr([*:0]u8, &config.krblevel);
    strZero(config.oauth_bearer);
    safeFreePtr([*:0]u8, &config.oauth_bearer);
    safeFreePtr([*:0]u8, &config.sasl_authzid);
    safeFreePtr([*:0]u8, &config.unix_socket_path);
    safeFreePtr([*:0]u8, &config.writeout);
    safeFreePtr([*:0]u8, &config.proto_default);

    curl_slist_free_all(config.quote);
    curl_slist_free_all(config.postquote);
    curl_slist_free_all(config.prequote);

    curl_slist_free_all(config.headers);
    curl_slist_free_all(config.proxyheaders);

    curl_mime_free(config.mimepost);
    config.mimepost = null;
    tool_mime_free(config.mimeroot);
    config.mimeroot = null;
    config.mimecurrent = null;

    curl_slist_free_all(config.telnet_options);
    curl_slist_free_all(config.resolve);
    curl_slist_free_all(config.connect_to);

    safeFreePtr([*:0]u8, &config.preproxy);
    safeFreePtr([*:0]u8, &config.proxy_service_name);
    safeFreePtr([*:0]u8, &config.service_name);
    safeFreePtr([*:0]u8, &config.ftp_account);
    safeFreePtr([*:0]u8, &config.ftp_alternative_to_user);
    safeFreePtr([*:0]u8, &config.aws_sigv4);
    safeFreePtr([*:0]u8, &config.httpsig_algorithm);
    safeFreePtr([*:0]u8, &config.httpsig_headers);
    safeFreePtr([*:0]u8, &config.httpsig_key);
    safeFreePtr([*:0]u8, &config.httpsig_keyid);
    safeFreePtr([*:0]u8, &config.ech);
    safeFreePtr([*:0]u8, &config.ech_config);
    safeFreePtr([*:0]u8, &config.ech_public);
    safeFreePtr([*:0]u8, &config.knownhosts);
}

pub export fn config_free(config: ?*OperationConfig) callconv(.c) void {
    var last = config;
    while (last) |curr| {
        const prev = curr.prev;
        freeConfigFields(curr);
        c.free(curr);
        last = prev;
    }
}

pub export fn globalconf_init() callconv(.c) CURLcode {
    const first = config_alloc();
    global = Curl_zig_global_init_storage(first);
    if (first) |f| {
        var result = curl_global_init(CURL_GLOBAL_DEFAULT);
        if (result == CURLE_OK) {
            result = get_libcurl_info();
            if (result != CURLE_OK) {
                errorf("error retrieving curl library information");
                c.free(f);
            }
        } else {
            errorf("error initializing curl library");
            c.free(f);
        }
        return result;
    } else {
        errorf("error initializing curl");
        return CURLE_FAILED_INIT;
    }
}

pub export fn globalconf_free() callconv(.c) void {
    curl_global_cleanup();
    if (global) |g| {
        const last = Curl_zig_global_free_fields(g);
        config_free(last);
    }
}

// ============================================================================
// 9. src/tool_help.c
// ============================================================================

const CURLHELP_AUTH: c_uint = 1 << 0;
const CURLHELP_CONNECTION: c_uint = 1 << 1;
const CURLHELP_CURL: c_uint = 1 << 2;
const CURLHELP_DEPRECATED: c_uint = 1 << 3;
const CURLHELP_DNS: c_uint = 1 << 4;
const CURLHELP_FILE: c_uint = 1 << 5;
const CURLHELP_FTP: c_uint = 1 << 6;
const CURLHELP_GLOBAL: c_uint = 1 << 7;
const CURLHELP_HTTP: c_uint = 1 << 8;
const CURLHELP_IMAP: c_uint = 1 << 9;
const CURLHELP_IMPORTANT: c_uint = 1 << 10;
const CURLHELP_LDAP: c_uint = 1 << 11;
const CURLHELP_OUTPUT: c_uint = 1 << 12;
const CURLHELP_POP3: c_uint = 1 << 13;
const CURLHELP_POST: c_uint = 1 << 14;
const CURLHELP_PROXY: c_uint = 1 << 15;
const CURLHELP_SCP: c_uint = 1 << 16;
const CURLHELP_SFTP: c_uint = 1 << 17;
const CURLHELP_SMTP: c_uint = 1 << 18;
const CURLHELP_SSH: c_uint = 1 << 19;
const CURLHELP_TELNET: c_uint = 1 << 20;
const CURLHELP_TFTP: c_uint = 1 << 21;
const CURLHELP_TIMEOUT: c_uint = 1 << 22;
const CURLHELP_TLS: c_uint = 1 << 23;
const CURLHELP_UPLOAD: c_uint = 1 << 24;
const CURLHELP_VERBOSE: c_uint = 1 << 25;
const CURLHELP_MQTT: c_uint = 1 << 26;
const CURLHELP_ALL: c_uint = 0xfffffff;

const CategoryDescriptor = struct {
    opt: [*:0]const u8,
    desc: [*:0]const u8,
    category: c_uint,
};

const categories = [_]CategoryDescriptor{
    .{ .opt = "auth", .desc = "Authentication methods", .category = CURLHELP_AUTH },
    .{ .opt = "connection", .desc = "Manage connections", .category = CURLHELP_CONNECTION },
    .{ .opt = "curl", .desc = "The command line tool itself", .category = CURLHELP_CURL },
    .{ .opt = "deprecated", .desc = "Legacy", .category = CURLHELP_DEPRECATED },
    .{ .opt = "dns", .desc = "Names and resolving", .category = CURLHELP_DNS },
    .{ .opt = "file", .desc = "FILE protocol", .category = CURLHELP_FILE },
    .{ .opt = "ftp", .desc = "FTP protocol", .category = CURLHELP_FTP },
    .{ .opt = "global", .desc = "Global options", .category = CURLHELP_GLOBAL },
    .{ .opt = "http", .desc = "HTTP and HTTPS protocol", .category = CURLHELP_HTTP },
    .{ .opt = "imap", .desc = "IMAP protocol", .category = CURLHELP_IMAP },
    .{ .opt = "ldap", .desc = "LDAP protocol", .category = CURLHELP_LDAP },
    .{ .opt = "mqtt", .desc = "MQTT protocol", .category = CURLHELP_MQTT },
    .{ .opt = "output", .desc = "File system output", .category = CURLHELP_OUTPUT },
    .{ .opt = "pop3", .desc = "POP3 protocol", .category = CURLHELP_POP3 },
    .{ .opt = "post", .desc = "HTTP POST specific", .category = CURLHELP_POST },
    .{ .opt = "proxy", .desc = "Options for proxies", .category = CURLHELP_PROXY },
    .{ .opt = "scp", .desc = "SCP protocol", .category = CURLHELP_SCP },
    .{ .opt = "sftp", .desc = "SFTP protocol", .category = CURLHELP_SFTP },
    .{ .opt = "smtp", .desc = "SMTP protocol", .category = CURLHELP_SMTP },
    .{ .opt = "ssh", .desc = "SSH protocol", .category = CURLHELP_SSH },
    .{ .opt = "telnet", .desc = "TELNET protocol", .category = CURLHELP_TELNET },
    .{ .opt = "tftp", .desc = "TFTP protocol", .category = CURLHELP_TFTP },
    .{ .opt = "timeout", .desc = "Timeouts and delays", .category = CURLHELP_TIMEOUT },
    .{ .opt = "tls", .desc = "TLS/SSL related", .category = CURLHELP_TLS },
    .{ .opt = "upload", .desc = "Upload, sending data", .category = CURLHELP_UPLOAD },
    .{ .opt = "verbose", .desc = "Tracing, logging etc", .category = CURLHELP_VERBOSE },
};

fn printCategory(category: c_uint, cols: c_uint) void {
    var longopt: usize = 5;
    var longdesc: usize = 5;
    const htxt = helptextPtr();

    var i: usize = 0;
    while (htxt[i].opt) |opt_s| : (i += 1) {
        if ((htxt[i].categories & category) == 0) continue;
        const opt_len = std.mem.len(opt_s);
        if (opt_len > longopt) longopt = opt_len;
        if (htxt[i].desc) |desc_s| {
            const desc_len = std.mem.len(desc_s);
            if (desc_len > longdesc) longdesc = desc_len;
        }
    }

    const cols_usize: usize = cols;
    if (longdesc > cols_usize) {
        longopt = 0;
    } else if (longopt + longdesc > cols_usize) {
        longopt = cols_usize - longdesc;
    }

    i = 0;
    while (htxt[i].opt) |opt_s| : (i += 1) {
        if ((htxt[i].categories & category) != 0) {
            var opt = longopt;
            const desc_s = htxt[i].desc.?;
            const desclen = std.mem.len(desc_s);
            if (cols_usize >= 2 and opt + desclen >= (cols_usize - 2)) {
                if (desclen < (cols_usize - 2)) {
                    opt = (cols_usize - 3) - desclen;
                } else {
                    opt = 0;
                }
            }
            _ = curl_mprintf(" %-*s  %s\n", @as(c_int, @intCast(opt)), opt_s, desc_s);
        }
    }
}

fn getCategoryContent(category: [*:0]const u8, cols: c_uint) c_int {
    for (categories) |cat| {
        if (curl_strequal(cat.opt, category) != 0) {
            _ = curl_mprintf("%s: %s\n", cat.opt, cat.desc);
            printCategory(cat.category, cols);
            return 0;
        }
    }
    return 1;
}

fn getCategories() void {
    for (categories) |cat| {
        _ = curl_mprintf(" %-11s %s\n", cat.opt, cat.desc);
    }
}

fn getCategoriesList(width: c_uint) void {
    var col: usize = 0;
    const width_usize: usize = width;
    for (categories, 0..) |cat, i| {
        const len = std.mem.len(cat.opt);
        if (i == categories.len - 1) {
            if (col + len + 1 < width_usize) {
                _ = curl_mprintf("%s.\n", cat.opt);
            } else {
                _ = curl_mprintf("\n%s.\n", cat.opt);
            }
        } else if (col + len + 2 < width_usize) {
            _ = curl_mprintf("%s, ", cat.opt);
            col += len + 2;
        } else {
            _ = curl_mprintf("\n%s, ", cat.opt);
            col = len + 2;
        }
    }
}

pub export fn inithelpscan(
    ctx: *scan_ctx,
    trigger: [*:0]const u8,
    arg: [*:0]const u8,
    endarg: [*:0]const u8,
) callconv(.c) void {
    ctx.trigger = trigger;
    ctx.tlen = std.mem.len(trigger);
    ctx.arg = arg;
    ctx.flen = std.mem.len(arg);
    ctx.endarg = endarg;
    ctx.elen = std.mem.len(endarg);
    ctx.show = 0;
    ctx.olen = 0;
    @memset(&ctx.rbuf, 0);
}

pub export fn helpscan(buf: [*]const u8, len: usize, ctx: *scan_ctx) callconv(.c) bool {
    var i: usize = 0;
    while (i < len) : (i += 1) {
        if (ctx.show == 0) {
            if (ctx.tlen > 1) {
                std.mem.copyForwards(u8, ctx.rbuf[0 .. ctx.tlen - 1], ctx.rbuf[1..ctx.tlen]);
            }
            if (ctx.tlen > 0) {
                ctx.rbuf[ctx.tlen - 1] = buf[i];
                if (std.mem.eql(u8, ctx.rbuf[0..ctx.tlen], ctx.trigger.?[0..ctx.tlen])) {
                    ctx.show += 1;
                }
            }
            continue;
        }
        if (ctx.show == 1) {
            if (ctx.flen > 1) {
                std.mem.copyForwards(u8, ctx.rbuf[0 .. ctx.flen - 1], ctx.rbuf[1..ctx.flen]);
            }
            if (ctx.flen > 0) {
                ctx.rbuf[ctx.flen - 1] = buf[i];
                if (std.mem.eql(u8, ctx.rbuf[0..ctx.flen], ctx.arg.?[0..ctx.flen])) {
                    _ = c.fputs(ctx.arg.? + 1, Curl_zig_stdout());
                    ctx.show += 1;
                }
            }
            continue;
        }
        if (ctx.elen > 1) {
            std.mem.copyForwards(u8, ctx.rbuf[0 .. ctx.elen - 1], ctx.rbuf[1..ctx.elen]);
        }
        if (ctx.elen > 0) {
            ctx.rbuf[ctx.elen - 1] = buf[i];
            if (std.mem.eql(u8, ctx.rbuf[0..ctx.elen], ctx.endarg.?[0..ctx.elen])) {
                return false;
            }
        }
        if (buf[i] == '\n') {
            if (ctx.olen == ctx.obuf.len) return false;
            ctx.obuf[ctx.olen] = 0;
            ctx.olen = 0;
            _ = c.puts(@ptrCast(&ctx.obuf));
        } else {
            if (ctx.olen == ctx.obuf.len) return false;
            ctx.obuf[ctx.olen] = buf[i];
            ctx.olen += 1;
        }
    }
    return true;
}

pub export fn tool_help(category: ?[*:0]const u8) callconv(.c) void {
    const cols = get_terminal_columns();
    const cat = category orelse {
        const category_note =
            "\nThis is not the full help; this " ++
            "menu is split into categories.\nUse \"--help category\" to get " ++
            "an overview of all categories, which are:";
        const category_note2 = "Use \"--help all\" to list all options";
        _ = c.puts("Usage: curl [options...] <url>");
        printCategory(CURLHELP_IMPORTANT, cols);
        _ = c.puts(category_note);
        getCategoriesList(cols);
        _ = c.puts(category_note2);
        return;
    };

    if (curl_strequal(cat, "all") != 0) {
        printCategory(CURLHELP_ALL, cols);
    } else if (curl_strequal(cat, "category") != 0) {
        getCategories();
    } else if (cat[0] == '-') {
        _ = curl_mfprintf(tool_stderr, "Cannot comply. This curl was built without built-in manual\n");
    } else if (getCategoryContent(cat, cols) != 0) {
        _ = c.puts("Unknown category provided, here is a list of all categories:\n");
        getCategories();
    }
}

fn isDebugFeature() bool {
    var i: usize = 0;
    while (feature_names[i]) |fname| : (i += 1) {
        if (curl_strequal("debug", fname) != 0) {
            return true;
        }
    }
    return false;
}

const backend_options = @import("backend_options");
const CURL_VERSION_STR: [:0]const u8 = backend_options.version ++ "";
const LIBCURL_TIMESTAMP_STR = "[unreleased]";
const CURL_OS_STR = @tagName(builtin.cpu.arch) ++ "-" ++ @tagName(builtin.os.tag) ++ "-" ++ @tagName(builtin.abi);
const CURL_ID_STR = "curl " ++ CURL_VERSION_STR ++ " (" ++ CURL_OS_STR ++ ") ";

pub export fn tool_version_info() callconv(.c) void {
    if (isDebugFeature()) {
        _ = curl_mfprintf(tool_stderr, "WARNING: this libcurl is Debug-enabled, do not use in production\n\n");
    }

    _ = curl_mprintf(CURL_ID_STR ++ "%s\n", curl_version());
    _ = curl_mprintf("Release-Date: %s\n", LIBCURL_TIMESTAMP_STR);

    if (built_in_protos[0] != null) {
        var insert: ?[*:0]const u8 = null;
        var idx: usize = 0;
        while (built_in_protos[idx]) |bproto| : (idx += 1) {
            if (insert != null) {
                if (std.mem.orderZ(u8, bproto, "ipfs") == .lt) {
                    insert = bproto;
                } else {
                    break;
                }
            } else if (std.mem.eql(u8, std.mem.span(bproto), "http")) {
                insert = bproto;
            }
        }
        _ = curl_mprintf("Protocols:");
        idx = 0;
        while (built_in_protos[idx]) |bproto| : (idx += 1) {
            _ = curl_mprintf(" %s", bproto);
            if (insert != null and insert.? == bproto) {
                _ = curl_mprintf(" ipfs ipns");
                insert = null;
            }
        }
        _ = c.puts("");
    }

    if (feature_names[0] != null) {
        const feat_ext_count = feature_count;
        const alloc_bytes = @sizeOf(?[*:0]const u8) * (feat_ext_count + 1);
        if (c.malloc(alloc_bytes)) |raw| {
            const feat_ext: [*]?[*:0]const u8 = @ptrCast(@alignCast(raw));
            for (0..feature_count) |i| {
                feat_ext[i] = feature_names[i];
            }
            feat_ext[feat_ext_count] = null;
            c.qsort(raw, feat_ext_count, @sizeOf(?[*:0]const u8), struplocompare4sort);
            _ = curl_mprintf("Features:");
            var idx: usize = 0;
            while (feat_ext[idx]) |fname| : (idx += 1) {
                _ = curl_mprintf(" %s", fname);
            }
            _ = c.puts("");
            c.free(raw);
        }
    }

    if (curlinfo) |info| {
        if (info.version) |ver| {
            if (!std.mem.eql(u8, std.mem.span(ver), CURL_VERSION_STR)) {
                _ = curl_mprintf("WARNING: curl and libcurl versions do not match. Functionality may be affected.\n");
            }
        }
    }
}

pub export fn tool_list_engines() callconv(.c) void {
    const curl = curl_easy_init();
    var engines: ?*curl_slist = null;

    _ = curl_easy_getinfo(curl, CURLINFO_SSL_ENGINES, &engines);

    _ = c.puts("Build-time engines:");
    if (engines) |first| {
        var curr: ?*curl_slist = first;
        while (curr) |node| : (curr = node.next) {
            if (node.data) |d| {
                _ = curl_mprintf("  %s\n", d);
            }
        }
    } else {
        _ = c.puts("  <none>");
    }

    curl_slist_free_all(engines);
    curl_easy_cleanup(curl);
}

// ============================================================================
// 10. src/tool_formparse.c
// ============================================================================

fn toolMimeNew(parent: ?*tool_mime, kind: toolmimekind) ?*tool_mime {
    const raw = c.calloc(1, @sizeOf(tool_mime)) orelse return null;
    const m: *tool_mime = @ptrCast(@alignCast(raw));
    m.kind = kind;
    m.parent = parent;
    if (parent) |p| {
        m.prev = p.subparts;
        p.subparts = m;
    }
    return m;
}

fn toolMimeNewParts(parent: ?*tool_mime) ?*tool_mime {
    return toolMimeNew(parent, TOOLMIME_PARTS);
}

fn toolMimeNewData(parent: ?*tool_mime, mime_data: [*:0]const u8) ?*tool_mime {
    const mime_data_copy = cStrdup(mime_data) orelse return null;
    const m = toolMimeNew(parent, TOOLMIME_DATA) orelse {
        c.free(mime_data_copy);
        return null;
    };
    m.data = mime_data_copy;
    return m;
}

fn uztoso(uznum: usize) i64 {
    const mask: usize = @intCast(std.math.maxInt(i64));
    return @intCast(uznum & mask);
}

fn sotouz(sonum: i64) usize {
    return if (sonum <= 0) 0 else @intCast(sonum);
}

fn toolMimeNewFiledata(
    parent: ?*tool_mime,
    filename: [*:0]const u8,
    isremotefile: bool,
    errcode: *CURLcode,
) ?*tool_mime {
    var result: CURLcode = CURLE_OK;
    errcode.* = CURLE_OUT_OF_MEMORY;

    if (!std.mem.eql(u8, std.mem.span(filename), "-")) {
        const filedup = cStrdup(filename) orelse return null;
        const m = toolMimeNew(parent, TOOLMIME_FILE) orelse {
            c.free(filedup);
            return null;
        };
        m.data = filedup;
        if (!isremotefile) {
            m.kind = TOOLMIME_FILEDATA;
        }
        errcode.* = CURLE_OK;
        return m;
    } else {
        var data: ?[*:0]u8 = null;
        var size: i64 = 0;
        var origin: i64 = 0;

        if (!Curl_zig_stdin_regular_size(&origin, &size)) {
            var stdinsize: usize = 0;
            switch (file2memory(&data, &stdinsize, tool_zig_stdin())) {
                PARAM_NO_MEM => return null,
                PARAM_READ_ERROR => {
                    result = CURLE_READ_ERROR;
                },
                else => {
                    if (stdinsize == 0) {
                        data = cStrdup("") orelse return null;
                    }
                },
            }
            size = uztoso(stdinsize);
            origin = 0;
        }

        const m = toolMimeNew(parent, TOOLMIME_STDIN) orelse {
            safeFreePtr([*:0]u8, &data);
            return null;
        };
        m.data = data;
        m.origin = origin;
        m.size = size;
        m.curpos = 0;
        if (!isremotefile) {
            m.kind = TOOLMIME_STDINDATA;
        }
        errcode.* = result;
        return m;
    }
}

pub export fn tool_mime_free(mime: ?*tool_mime) callconv(.c) void {
    const m = mime orelse return;
    if (m.subparts) |sp| {
        tool_mime_free(sp);
    }
    if (m.prev) |pr| {
        tool_mime_free(pr);
    }
    safeFreePtr([*:0]u8, &m.name);
    safeFreePtr([*:0]u8, &m.filename);
    safeFreePtr([*:0]u8, &m.type);
    safeFreePtr([*:0]u8, &m.encoder);
    safeFreePtr([*:0]u8, &m.data);
    curl_slist_free_all(m.headers);
    c.free(m);
}

fn toolMimeStdinRead(buffer: [*]u8, size: usize, nitems_in: usize, arg: ?*anyopaque) callconv(.c) usize {
    _ = size;
    const sip: *tool_mime = @ptrCast(@alignCast(arg.?));
    var nitems = nitems_in;

    if (sip.size >= 0) {
        if (sip.curpos >= sip.size) {
            return 0;
        }
        const bytesleft = sip.size - sip.curpos;
        if (uztoso(nitems) > bytesleft) {
            nitems = sotouz(bytesleft);
        }
    }
    if (nitems != 0) {
        if (sip.data) |d| {
            const offset = sotouz(sip.curpos);
            @memcpy(buffer[0..nitems], (d + offset)[0..nitems]);
        } else {
            const stdin_fp = tool_zig_stdin();
            nitems = c.fread(buffer, 1, nitems, stdin_fp);
            if (c.ferror(stdin_fp) != 0) {
                var errbuf: [STRERROR_LEN]u8 = undefined;
                warnf(
                    "Failed to read from stdin: %s",
                    curlx_strerror(tool_zig_get_errno(), &errbuf, errbuf.len),
                );
                return CURL_READFUNC_ABORT;
            }
        }
        sip.curpos += uztoso(nitems);
    }
    return nitems;
}

fn toolMimeStdinSeek(instream: ?*anyopaque, offset_in: i64, whence: c_int) callconv(.c) c_int {
    const sip: *tool_mime = @ptrCast(@alignCast(instream.?));
    var offset = offset_in;

    switch (whence) {
        SEEK_CUR => offset += sip.curpos,
        SEEK_END => offset += sip.size,
        else => {},
    }
    if (offset < 0) {
        return CURL_SEEKFUNC_CANTSEEK;
    }
    if (sip.data == null and Curl_zig_fseek(tool_zig_stdin(), offset + sip.origin, SEEK_SET) != 0) {
        return CURL_SEEKFUNC_CANTSEEK;
    }
    sip.curpos = offset;
    return CURL_SEEKFUNC_OK;
}

const MAX_FORMPARTS: usize = 100000;

fn tool2curlparts(curl: ?*anyopaque, m: ?*tool_mime, mime: ?*anyopaque) CURLcode {
    const first = m orelse return CURLE_OK;

    var count: usize = 0;
    var curr: ?*tool_mime = first;
    while (curr) |node| : (curr = node.prev) {
        if (count > MAX_FORMPARTS) {
            return CURLE_BAD_FUNCTION_ARGUMENT;
        }
        count += 1;
    }

    const raw = c.malloc(@sizeOf(*tool_mime) * count) orelse return CURLE_OUT_OF_MEMORY;
    const nodes: [*]*tool_mime = @ptrCast(@alignCast(raw));
    defer c.free(raw);

    curr = first;
    var idx = count;
    while (idx > 0) {
        idx -= 1;
        nodes[idx] = curr.?;
        curr = curr.?.prev;
    }

    var result: CURLcode = CURLE_OK;
    for (0..count) |i| {
        const node = nodes[i];
        var filename: ?[*:0]const u8 = node.filename;

        const part = curl_mime_addpart(mime) orelse {
            result = CURLE_OUT_OF_MEMORY;
            break;
        };

        switch (node.kind) {
            TOOLMIME_PARTS => {
                var submime: ?*anyopaque = null;
                result = tool2curlmime(curl, node, &submime);
                if (result == CURLE_OK) {
                    result = curl_mime_subparts(part, submime);
                    if (result != CURLE_OK) {
                        curl_mime_free(submime);
                    }
                }
            },
            TOOLMIME_DATA => {
                result = curl_mime_data(part, node.data, CURL_ZERO_TERMINATED);
            },
            TOOLMIME_FILE, TOOLMIME_FILEDATA => {
                result = curl_mime_filedata(part, node.data);
                if (result == CURLE_OK and node.kind == TOOLMIME_FILEDATA and filename == null) {
                    result = curl_mime_filename(part, null);
                }
            },
            TOOLMIME_STDIN, TOOLMIME_STDINDATA => {
                if (node.kind == TOOLMIME_STDIN and filename == null) {
                    filename = "-";
                }
                result = curl_mime_data_cb(
                    part,
                    node.size,
                    toolMimeStdinRead,
                    toolMimeStdinSeek,
                    null,
                    node,
                );
            },
            else => {},
        }

        if (result == CURLE_OK and filename != null) {
            result = curl_mime_filename(part, filename);
        }
        if (result == CURLE_OK) {
            result = curl_mime_type(part, node.type);
        }
        if (result == CURLE_OK) {
            result = curl_mime_headers(part, node.headers, 0);
        }
        if (result == CURLE_OK) {
            result = curl_mime_encoder(part, node.encoder);
        }
        if (result == CURLE_OK) {
            result = curl_mime_name(part, node.name);
        }
        if (result != CURLE_OK) {
            break;
        }
    }

    return result;
}

pub export fn tool2curlmime(curl: ?*anyopaque, m: *tool_mime, mime: *?*anyopaque) callconv(.c) CURLcode {
    var result: CURLcode = CURLE_OK;
    mime.* = curl_mime_init(curl);
    if (mime.* == null) {
        result = CURLE_OUT_OF_MEMORY;
    } else {
        result = tool2curlparts(curl, m.subparts, mime.*);
    }
    if (result != CURLE_OK) {
        curl_mime_free(mime.*);
        mime.* = null;
    }
    return result;
}

fn getParamWord(str: *[*:0]u8, end_pos: *[*:0]u8, endchar: u8) [*:0]u8 {
    var ptr = str.*;
    const word_begin = ptr;
    var escape: ?[*:0]u8 = null;

    if (ptr[0] == '"') {
        ptr += 1;
        while (ptr[0] != 0) {
            if (ptr[0] == '\\' and (ptr[1] == '\\' or ptr[1] == '"')) {
                if (escape == null) {
                    escape = ptr;
                }
                ptr += 2;
                continue;
            }
            if (ptr[0] == '"') {
                var trailing_data = false;
                const quote_pos = ptr;
                end_pos.* = quote_pos;
                if (escape) |esc| {
                    var p_src = esc;
                    var p_dst = esc;
                    while (true) {
                        if (p_src[0] == '\\' and (p_src[1] == '\\' or p_src[1] == '"')) {
                            p_src += 1;
                        }
                        p_dst[0] = p_src[0];
                        p_dst += 1;
                        p_src += 1;
                        if (@intFromPtr(p_src) >= @intFromPtr(quote_pos)) break;
                    }
                    end_pos.* = p_dst;
                }
                ptr = quote_pos + 1;
                while (ptr[0] != 0 and ptr[0] != ';' and ptr[0] != endchar) {
                    if (!isSpace(ptr[0])) {
                        trailing_data = true;
                    }
                    ptr += 1;
                }
                if (trailing_data) {
                    warnf("Trailing data after quoted form parameter");
                }
                str.* = ptr;
                return word_begin + 1;
            }
            ptr += 1;
        }
        ptr = word_begin;
    }

    while (ptr[0] != 0 and ptr[0] != ';' and ptr[0] != endchar) {
        ptr += 1;
    }
    str.* = ptr;
    end_pos.* = ptr;
    return word_begin;
}

fn slistAppend(plist: *?*curl_slist, data: [*:0]const u8) c_int {
    const s = curl_slist_append(plist.*, data) orelse return -1;
    plist.* = s;
    return 0;
}

fn readFieldHeaders(fp: ?*anyopaque, pheaders: *?*curl_slist) c_int {
    var line: Dynbuf = undefined;
    var err_flag: bool = false;
    var err: c_int = 0;

    curlx_dyn_init(&line, HEADER_LINE_BUFFER_SIZE);
    while (my_get_line(fp, &line, &err_flag)) {
        const ptr = curlx_dyn_ptr(&line) orelse continue;
        var len = curlx_dyn_len(&line);
        var folded = false;
        if (ptr[0] == '#') {
            continue;
        } else if (ptr[0] == ' ') {
            folded = true;
        }
        while (len > 0 and (isNewline(ptr[len - 1]) or isBlank(ptr[len - 1]))) {
            len -= 1;
        }
        if (len == 0) {
            continue;
        }
        _ = curlx_dyn_setlen(&line, len);

        if (folded and pheaders.* != null) {
            var amend: Dynbuf = undefined;
            var l = pheaders.*.?;
            curlx_dyn_init(&amend, HEADER_LINE_BUFFER_SIZE);
            while (l.next) |nxt| {
                l = nxt;
            }
            if (curlx_dyn_add(&amend, l.data.?) != CURLE_OK or
                curlx_dyn_addn(&amend, ptr, len) != CURLE_OK)
            {
                curlx_dyn_free(&amend);
                err = -1;
                break;
            }
            curl_free(l.data);
            l.data = curl_maprintf("%s", curlx_dyn_ptr(&amend).?);
            curlx_dyn_free(&amend);
            if (l.data == null) {
                err = -1;
            }
        } else {
            err = slistAppend(pheaders, ptr);
        }

        if (err != 0) {
            errorf("Out of memory for field headers");
            err = -1;
            break;
        }
    }
    if (err_flag and err == 0) {
        errorf("Failed to read field headers");
        err = -1;
    }
    curlx_dyn_free(&line);
    return err;
}

fn isContentTypeReject(ch: u8) bool {
    return switch (ch) {
        '(', ')', '<', '>', '@', ',', ';', ':', '\\', '"', '[', ']', '?', '=', '\r', '\n', ' ' => true,
        else => false,
    };
}

fn paramType(ptr: *[*:0]u8, ptype: *?[*:0]u8, endct: *?[*:0]u8, sep: *u8) void {
    var p = ptr.* + "type=".len;
    while (isBlank(p[0])) {
        p += 1;
    }
    ptype.* = p;
    while (p[0] != 0 and !isContentTypeReject(p[0])) {
        p += 1;
    }
    endct.* = p;
    sep.* = p[0];
    ptr.* = p;
}

fn stripUnquotedTrailingBlanks(word: [*:0]u8, tp: [*:0]u8, endpos: *[*:0]u8) void {
    if (@intFromPtr(word) == @intFromPtr(tp)) {
        while (@intFromPtr(endpos.*) > @intFromPtr(word) and isBlank((endpos.* - 1)[0])) {
            endpos.* -= 1;
        }
    }
}

fn paramFilename(ptr: *[*:0]u8, endct: *?[*:0]u8, pfilename: *?[*:0]u8, endchar: u8, sep: *u8) void {
    var p = ptr.*;
    var endpos: [*:0]u8 = undefined;
    if (endct.*) |ect| {
        ect[0] = 0;
        endct.* = null;
    }
    p += "filename=".len;
    while (isBlank(p[0])) {
        p += 1;
    }
    const tp = p;
    const fname = getParamWord(&p, &endpos, endchar);
    pfilename.* = fname;
    stripUnquotedTrailingBlanks(fname, tp, &endpos);
    sep.* = p[0];
    endpos[0] = 0;
    ptr.* = p;
}

fn paramHeaders(ptr: *[*:0]u8, endct: *?[*:0]u8, pheaders: *?*curl_slist, endchar: u8, sep: *u8) c_int {
    var p = ptr.*;
    var endpos: [*:0]u8 = undefined;
    if (endct.*) |ect| {
        ect[0] = 0;
        endct.* = null;
    }
    p += "headers=".len;
    if (p[0] == '@' or p[0] == '<') {
        p += 1;
        while (isBlank(p[0])) {
            p += 1;
        }
        const tp = p;
        const hdrfile = getParamWord(&p, &endpos, endchar);
        stripUnquotedTrailingBlanks(hdrfile, tp, &endpos);
        sep.* = p[0];
        endpos[0] = 0;
        const fp = toolFopen(hdrfile, FOPEN_READTEXT);
        if (fp == null) {
            var errbuf: [STRERROR_LEN]u8 = undefined;
            warnf(
                "Cannot read from %s: %s",
                hdrfile,
                curlx_strerror(tool_zig_get_errno(), &errbuf, errbuf.len),
            );
        } else {
            const rc = readFieldHeaders(fp, pheaders);
            toolFclose(fp);
            if (rc != 0) {
                curl_slist_free_all(pheaders.*);
                pheaders.* = null;
                return -1;
            }
        }
    } else {
        while (isBlank(p[0])) {
            p += 1;
        }
        const tp = p;
        const hdr = getParamWord(&p, &endpos, endchar);
        stripUnquotedTrailingBlanks(hdr, tp, &endpos);
        sep.* = p[0];
        endpos[0] = 0;
        if (slistAppend(pheaders, hdr) != 0) {
            errorf("Out of memory for field header");
            curl_slist_free_all(pheaders.*);
            pheaders.* = null;
            return -1;
        }
    }
    ptr.* = p;
    return 0;
}

fn paramEncoder(ptr: *[*:0]u8, endct: *?[*:0]u8, pencoder: *?[*:0]u8, endchar: u8, sep: *u8) void {
    var p = ptr.*;
    var endpos: [*:0]u8 = undefined;
    if (endct.*) |ect| {
        ect[0] = 0;
        endct.* = null;
    }
    p += "encoder=".len;
    while (isBlank(p[0])) {
        p += 1;
    }
    const tp = p;
    const enc = getParamWord(&p, &endpos, endchar);
    pencoder.* = enc;
    stripUnquotedTrailingBlanks(enc, tp, &endpos);
    sep.* = p[0];
    endpos[0] = 0;
    ptr.* = p;
}

fn getParamPart(
    endchar: u8,
    str: *[*:0]u8,
    pdata: *[*:0]u8,
    ptype: ?*?[*:0]u8,
    pfilename: ?*?[*:0]u8,
    pencoder: ?*?[*:0]u8,
    pheaders: ?*?*curl_slist,
) c_int {
    var p = str.*;
    var mime_type: ?[*:0]u8 = null;
    var filename: ?[*:0]u8 = null;
    var encoder: ?[*:0]u8 = null;
    var endpos: [*:0]u8 = undefined;
    var sep: u8 = 0;
    var endct: ?[*:0]u8 = null;
    var headers: ?*curl_slist = null;

    if (ptype) |pt| pt.* = null;
    if (pfilename) |pf| pf.* = null;
    if (pheaders) |ph| ph.* = null;
    if (pencoder) |pe| pe.* = null;

    while (isBlank(p[0])) {
        p += 1;
    }
    const tp = p;
    pdata.* = getParamWord(&p, &endpos, endchar);
    stripUnquotedTrailingBlanks(pdata.*, tp, &endpos);
    sep = p[0];
    endpos[0] = 0;

    while (sep == ';') {
        p += 1;
        while (isBlank(p[0])) {
            p += 1;
        }

        if (endct == null and checkPrefix("type=", p)) {
            paramType(&p, &mime_type, &endct, &sep);
        } else if (checkPrefix("filename=", p)) {
            paramFilename(&p, &endct, &filename, endchar, &sep);
        } else if (checkPrefix("headers=", p)) {
            if (paramHeaders(&p, &endct, &headers, endchar, &sep) != 0) {
                return -1;
            }
        } else if (checkPrefix("encoder=", p)) {
            paramEncoder(&p, &endct, &encoder, endchar, &sep);
        } else if (endct != null) {
            endct = p;
            while (p[0] != 0 and p[0] != ';' and p[0] != endchar) : (p += 1) {
                if (!isBlank(p[0])) {
                    endct = p + 1;
                }
            }
            sep = p[0];
        } else {
            const unknown = getParamWord(&p, &endpos, endchar);
            sep = p[0];
            endpos[0] = 0;
            if (unknown[0] != 0) {
                warnf("skip unknown form field: %s", unknown);
            }
        }
    }

    if (endct) |ect| {
        ect[0] = 0;
    }

    if (ptype) |pt| {
        pt.* = mime_type;
    } else if (mime_type) |t| {
        warnf("Field content type not allowed here: %s", t);
    }

    if (pfilename) |pf| {
        pf.* = filename;
    } else if (filename) |f| {
        warnf("Field filename not allowed here: %s", f);
    }

    if (pencoder) |pe| {
        pe.* = encoder;
    } else if (encoder) |e| {
        warnf("Field encoder not allowed here: %s", e);
    }

    if (pheaders) |ph| {
        ph.* = headers;
    } else if (headers) |h| {
        warnf("Field headers not allowed here: %s", h.data.?);
        curl_slist_free_all(headers);
    }

    str.* = p;
    return @as(c_int, sep);
}

fn setToolMimePtr(target: *?[*:0]u8, value: ?[*:0]const u8) bool {
    if (value) |v| {
        const dup = cStrdup(v) orelse return false;
        target.* = dup;
    }
    return true;
}

pub export fn formparse(
    input: [*:0]const u8,
    mimeroot: *?*tool_mime,
    mimecurrent: *?*tool_mime,
    literal_value: bool,
) callconv(.c) c_int {
    var name: ?[*:0]u8 = null;
    var contents: ?[*:0]u8 = null;
    var data: [*:0]u8 = undefined;
    var mime_type: ?[*:0]u8 = null;
    var filename: ?[*:0]u8 = null;
    var encoder: ?[*:0]u8 = null;
    var headers: ?*curl_slist = null;
    var part: ?*tool_mime = null;
    var result: CURLcode = CURLE_OK;
    var err: c_int = 1;

    fail: {
        if (mimecurrent.* == null) {
            mimeroot.* = toolMimeNewParts(null);
            if (mimeroot.* == null) break :fail;
            mimecurrent.* = mimeroot.*;
        }

        contents = cStrdup(input);
        if (contents == null) break :fail;

        const contents_ptr = contents.?;
        const contents_slice = std.mem.span(contents_ptr);
        const eq_idx = std.mem.findScalar(u8, contents_slice, '=') orelse {
            warnf("Illegally formatted input field");
            break :fail;
        };

        var sep: c_int = 0;
        if (eq_idx > 0) {
            name = contents_ptr;
        }
        contents_ptr[eq_idx] = 0;
        var contp: [*:0]u8 = contents_ptr + eq_idx + 1;

        if (contp[0] == '(' and !literal_value) {
            sep = getParamPart(0, &contp, &data, &mime_type, null, null, &headers);
            if (sep < 0) break :fail;
            part = toolMimeNewParts(mimecurrent.*);
            if (part == null) break :fail;
            mimecurrent.* = part;
            part.?.headers = headers;
            headers = null;
            if (!setToolMimePtr(&part.?.type, mime_type)) break :fail;
        } else if (name == null and std.mem.eql(u8, std.mem.span(contp), ")") and !literal_value) {
            if (mimecurrent.* == mimeroot.*) {
                warnf("no multipart to terminate");
                break :fail;
            }
            mimecurrent.* = mimecurrent.*.?.parent;
        } else if (contp[0] == '@' and !literal_value) {
            var subparts: ?*tool_mime = null;
            while (true) {
                contp += 1;
                sep = getParamPart(',', &contp, &data, &mime_type, &filename, &encoder, &headers);
                if (sep < 0) break :fail;

                if (subparts == null) {
                    if (sep != ',') {
                        subparts = mimecurrent.*;
                    } else {
                        subparts = toolMimeNewParts(mimecurrent.*);
                        if (subparts == null) break :fail;
                    }
                }

                part = toolMimeNewFiledata(subparts, data, true, &result);
                if (part == null) break :fail;
                part.?.headers = headers;
                headers = null;
                if (result == CURLE_READ_ERROR) {
                    if (part.?.size > 0) {
                        warnf("error while reading standard input");
                        break :fail;
                    }
                    safeFreePtr([*:0]u8, &part.?.data);
                    part.?.size = -1;
                    result = CURLE_OK;
                }
                if (!setToolMimePtr(&part.?.filename, filename)) break :fail;
                if (!setToolMimePtr(&part.?.type, mime_type)) break :fail;
                if (!setToolMimePtr(&part.?.encoder, encoder)) break :fail;

                if (sep != ',') break;
            }
            part = mimecurrent.*.?.subparts;
        } else {
            if (contp[0] == '<' and !literal_value) {
                contp += 1;
                sep = getParamPart(0, &contp, &data, &mime_type, null, &encoder, &headers);
                if (sep < 0) break :fail;

                part = toolMimeNewFiledata(mimecurrent.*, data, false, &result);
                if (part == null) break :fail;
                part.?.headers = headers;
                headers = null;
                if (result == CURLE_READ_ERROR) {
                    if (part.?.size > 0) {
                        warnf("error while reading standard input");
                        break :fail;
                    }
                    safeFreePtr([*:0]u8, &part.?.data);
                    part.?.size = -1;
                    result = CURLE_OK;
                }
            } else {
                if (literal_value) {
                    data = contp;
                } else {
                    sep = getParamPart(0, &contp, &data, &mime_type, &filename, &encoder, &headers);
                    if (sep < 0) break :fail;
                }

                part = toolMimeNewData(mimecurrent.*, data);
                if (part == null) break :fail;
                part.?.headers = headers;
                headers = null;
            }

            if (!setToolMimePtr(&part.?.filename, filename)) break :fail;
            if (!setToolMimePtr(&part.?.type, mime_type)) break :fail;
            if (!setToolMimePtr(&part.?.encoder, encoder)) break :fail;

            if (sep != 0) {
                contp[0] = @intCast(sep & 0xff);
                warnf("garbage at end of field specification: %s", contp);
            }
        }

        if (part) |p| {
            if (!setToolMimePtr(&p.name, name)) break :fail;
        }
        err = 0;
    }

    safeFreePtr([*:0]u8, &contents);
    curl_slist_free_all(headers);
    return err;
}

// ============================================================================
// 11. src/tool_paramhlp.c
// ============================================================================

var outnum_counter: i64 = 0;

pub export fn new_getout(config: *OperationConfig) callconv(.c) ?*getout {
    const raw = c.calloc(1, Curl_zig_sizeof_getout()) orelse return null;
    const node: *getout = @ptrCast(@alignCast(raw));
    const last = config.url_last;
    if (last) |l| {
        l.next = node;
    } else {
        config.url_list = node;
    }
    config.url_last = node;
    Curl_zig_getout_init_bits(config, node, outnum_counter);
    outnum_counter += 1;
    return node;
}

inline fn isCrlfOrNull(x: u8) bool {
    return x == '\r' or x == '\n' or x == 0;
}

fn memcrlf(orig: [*]const u8, countcrlf: bool, max: usize) usize {
    for (0..max) |idx| {
        const crlf = isCrlfOrNull(orig[idx]);
        if (countcrlf != crlf) {
            return idx;
        }
    }
    return max;
}

pub export fn file2string(bufp: *?[*:0]u8, file: ?*anyopaque) callconv(.c) ParameterError {
    var dyn: Dynbuf = undefined;
    curlx_dyn_init(&dyn, MAX_FILE2MEMORY);
    if (file) |fp| {
        while (true) {
            var buffer: [4096]u8 = undefined;
            var nread = c.fread(&buffer, 1, buffer.len, fp);
            if (c.ferror(fp) != 0) {
                curlx_dyn_free(&dyn);
                bufp.* = null;
                return PARAM_READ_ERROR;
            }
            var ptr: [*]const u8 = &buffer;
            while (nread > 0) {
                var nlen = memcrlf(ptr, false, nread);
                if (curlx_dyn_addn(&dyn, ptr, nlen) != CURLE_OK) {
                    return PARAM_NO_MEM;
                }
                nread -= nlen;
                if (nread > 0) {
                    ptr += nlen;
                    nlen = memcrlf(ptr, true, nread);
                    ptr += nlen;
                    nread -= nlen;
                }
            }
            if (c.feof(fp) != 0) break;
        }
    }
    bufp.* = curlx_dyn_ptr(&dyn);
    return PARAM_OK;
}

pub export fn file2memory_range(
    bufp: *?[*:0]u8,
    size: *usize,
    file: ?*anyopaque,
    starto: i64,
    endo: i64,
) callconv(.c) ParameterError {
    if (file) |fp| {
        var dyn: Dynbuf = undefined;
        var offset: i64 = 0;
        var throwaway: i64 = 0;

        if (starto != 0) {
            if (fp != tool_zig_stdin()) {
                if (Curl_zig_fseek(fp, starto, SEEK_SET) != 0) {
                    return PARAM_READ_ERROR;
                }
                offset = starto;
            } else {
                throwaway = starto;
            }
        }

        curlx_dyn_init(&dyn, MAX_FILE2MEMORY);
        while (true) {
            var buffer: [4096]u8 = undefined;
            const nread = c.fread(&buffer, 1, buffer.len, fp);
            if (c.ferror(fp) != 0) {
                curlx_dyn_free(&dyn);
                size.* = 0;
                bufp.* = null;
                return PARAM_READ_ERROR;
            }
            var n_add = nread;
            var ptr_add: [*]const u8 = &buffer;
            if (nread > 0) {
                if (throwaway > 0) {
                    const nread_off: i64 = @intCast(nread);
                    if (throwaway >= nread_off) {
                        throwaway -= nread_off;
                        offset += nread_off;
                        n_add = 0;
                    } else {
                        const ta_usize: usize = @intCast(throwaway);
                        n_add = nread - ta_usize;
                        ptr_add = (&buffer)[ta_usize..].ptr;
                        offset += throwaway;
                        throwaway = 0;
                    }
                }
                if (n_add > 0) {
                    const n_add_off: i64 = @intCast(n_add);
                    if (n_add_off + offset > endo) {
                        n_add = @intCast(endo - offset + 1);
                    }
                    if (curlx_dyn_addn(&dyn, ptr_add, n_add) != CURLE_OK) {
                        return PARAM_NO_MEM;
                    }
                    offset += @intCast(n_add);
                    if (offset > endo) {
                        break;
                    }
                }
            }
            if (c.feof(fp) != 0) break;
        }
        size.* = curlx_dyn_len(&dyn);
        bufp.* = curlx_dyn_ptr(&dyn);
    } else {
        size.* = 0;
        bufp.* = null;
    }
    return PARAM_OK;
}

pub export fn file2memory(bufp: *?[*:0]u8, size: *usize, file: ?*anyopaque) callconv(.c) ParameterError {
    return file2memory_range(bufp, size, file, 0, CURL_OFF_T_MAX);
}

pub export fn str2num(val: *c_long, str: [*:0]const u8) callconv(.c) ParameterError {
    var p = str;
    var num: i64 = 0;
    var is_neg = false;
    if (curlx_str_single(&p, '-') == 0) {
        is_neg = true;
    }
    if (curlx_str_number(&p, &num, std.math.maxInt(c_long)) != 0 or
        curlx_str_single(&p, 0) != 0)
    {
        return PARAM_BAD_NUMERIC;
    }
    val.* = @intCast(num);
    if (is_neg) {
        val.* = -val.*;
    }
    return PARAM_OK;
}

pub export fn oct2nummax(val: *c_long, str: [*:0]const u8, max: c_long) callconv(.c) ParameterError {
    var p = str;
    var num: i64 = 0;
    const rc = curlx_str_octal(&p, &num, max);
    if (rc != 0) {
        if (rc == STRE_OVERFLOW) {
            return PARAM_NUMBER_TOO_LARGE;
        }
        return PARAM_BAD_NUMERIC;
    }
    if (curlx_str_single(&p, 0) != 0) {
        return PARAM_BAD_NUMERIC;
    }
    if (num < 0) {
        return PARAM_NEGATIVE_NUMERIC;
    }
    val.* = @intCast(num);
    return PARAM_OK;
}

pub export fn str2unum(val: *c_long, str: [*:0]const u8) callconv(.c) ParameterError {
    const err = str2num(val, str);
    if (err != PARAM_OK) {
        return err;
    }
    if (val.* < 0) {
        return PARAM_NEGATIVE_NUMERIC;
    }
    return PARAM_OK;
}

pub export fn str2unummax(val: *c_long, str: [*:0]const u8, max: c_long) callconv(.c) ParameterError {
    const err = str2unum(val, str);
    if (err != PARAM_OK) {
        return err;
    }
    if (val.* > max) {
        return PARAM_NUMBER_TOO_LARGE;
    }
    return PARAM_OK;
}

const secs2ms_digs = [_]c_long{
    1,
    10,
    100,
    1000,
    10000,
    100000,
    1000000,
    10000000,
    100000000,
};

pub export fn secs2ms(val: *c_long, str: ?[*:0]const u8) callconv(.c) ParameterError {
    var p = str orelse return PARAM_BAD_NUMERIC;
    var secs: i64 = 0;
    var ms: c_long = 0;

    if (curlx_str_number(&p, &secs, @divTrunc(std.math.maxInt(c_long), 1000) - 1) != 0) {
        return PARAM_BAD_NUMERIC;
    }
    if (curlx_str_single(&p, '.') == 0) {
        var fracs: i64 = 0;
        const s = p;
        if (curlx_str_number(&p, &fracs, CURL_OFF_T_MAX) != 0) {
            return PARAM_NUMBER_TOO_LARGE;
        }
        var len: usize = @intFromPtr(p) - @intFromPtr(s);
        while (len > secs2ms_digs.len or fracs > @divTrunc(std.math.maxInt(c_long), 100)) {
            fracs = @divTrunc(fracs, 10);
            len -= 1;
        }
        const fracs_long: c_long = @intCast(fracs);
        ms = @divTrunc(fracs_long * 100, secs2ms_digs[len - 1]);
    }

    const secs_long: c_long = @intCast(secs);
    val.* = (secs_long * 1000) + ms;
    return PARAM_OK;
}

fn protosetIndex(protoset: [*]const ?[*:0]const u8, proto: ?[*:0]const u8) usize {
    var i: usize = 0;
    while (protoset[i]) |p| : (i += 1) {
        if (proto != null and proto.? == p) {
            break;
        }
    }
    return i;
}

fn protosetSet(protoset: [*]?[*:0]const u8, proto: ?[*:0]const u8) void {
    const p = proto orelse return;
    const n = protosetIndex(protoset, p);
    if (protoset[n] == null) {
        protoset[n] = p;
        protoset[n + 1] = null;
    }
}

fn protosetClear(protoset: [*]?[*:0]const u8, proto: ?[*:0]const u8) void {
    const p = proto orelse return;
    const n = protosetIndex(protoset, p);
    if (protoset[n] != null) {
        const m = protosetIndex(protoset, null) - 1;
        protoset[n] = protoset[m];
        protoset[m] = null;
    }
}

const MAX_PROTOS: usize = 34;
const MAX_PROTOSTRING: usize = MAX_PROTOS * 11;

pub export fn proto2num(
    val: [*]const ?[*:0]const u8,
    ostr: *?[*:0]u8,
    str_in: [*:0]const u8,
) callconv(.c) ParameterError {
    var obuf: Dynbuf = undefined;
    var protoset: [MAX_PROTOS + 1]?[*:0]const u8 = @splat(null);

    if (proto_count > MAX_PROTOS) {
        return PARAM_NO_MEM;
    }

    curlx_dyn_init(&obuf, MAX_PROTOSTRING);

    protoset[0] = null;
    var v_idx: usize = 0;
    while (val[v_idx]) |v| : (v_idx += 1) {
        if (proto_token(v)) |p| {
            protosetSet(&protoset, p);
        }
    }

    const Action = enum { allow, deny, set };
    var str = str_in;

    while (str[0] != 0) {
        const str_slice = std.mem.span(str);
        const comma_idx = std.mem.findScalar(u8, str_slice, ',');
        var plen: usize = 0;
        var action: Action = .allow;

        if (comma_idx) |ci| {
            if (ci == 0) {
                str += 1;
                continue;
            }
            plen = ci - 1;
        } else {
            plen = str_slice.len - 1;
        }

        const mod_ch = str[0];
        str += 1;
        switch (mod_ch) {
            '=' => action = .set,
            '-' => action = .deny,
            '+' => action = .allow,
            else => {
                str -= 1;
                plen += 1;
            },
        }

        if (plen == 3 and curl_strnequal(str, "all", 3) != 0) {
            switch (action) {
                .deny => {
                    protoset[0] = null;
                },
                .allow, .set => {
                    for (0..proto_count + 1) |i| {
                        protoset[i] = built_in_protos[i];
                    }
                },
            }
        } else {
            var buffer: [32]u8 = undefined;
            _ = curl_msnprintf(&buffer, buffer.len, "%.*s", @as(c_int, @intCast(plen)), str);
            const buf_z: [*:0]const u8 = @ptrCast(&buffer);
            if (proto_token(buf_z)) |p| {
                switch (action) {
                    .deny => protosetClear(&protoset, p),
                    .set => {
                        protoset[0] = null;
                        protosetSet(&protoset, p);
                    },
                    .allow => protosetSet(&protoset, p),
                }
            } else {
                if (action == .set) {
                    protoset[0] = null;
                }
                errorf("unrecognized protocol '%s'", buf_z);
                curlx_dyn_free(&obuf);
                return PARAM_BAD_USE;
            }
        }

        if (comma_idx) |ci| {
            str = str_slice[ci + 1 ..].ptr;
        } else {
            break;
        }
    }

    const count = protosetIndex(&protoset, null);
    c.qsort(&protoset, count, @sizeOf(?[*:0]const u8), struplocompare4sort);

    var result: CURLcode = CURLE_OK;
    var proto_idx: usize = 0;
    while (protoset[proto_idx]) |pname| : (proto_idx += 1) {
        const sep: [*:0]const u8 = if (curlx_dyn_len(&obuf) != 0) "," else "";
        result = curlx_dyn_addf(&obuf, "%s%s", sep, pname);
        if (result != CURLE_OK) break;
    }
    if (result != CURLE_OK) {
        return PARAM_NO_MEM;
    }
    if (curlx_dyn_len(&obuf) == 0) {
        curlx_dyn_free(&obuf);
        return PARAM_BAD_USE;
    }
    c.free(ostr.*);
    ostr.* = curlx_dyn_ptr(&obuf);
    return PARAM_OK;
}

pub export fn check_protocol(str: ?[*:0]const u8) callconv(.c) ParameterError {
    const s = str orelse return PARAM_REQUIRES_PARAMETER;
    if (proto_token(s) != null) {
        return PARAM_OK;
    }
    return PARAM_LIBCURL_UNSUPPORTED_PROTOCOL;
}

pub export fn str2offset(val: *i64, str: [*:0]const u8) callconv(.c) ParameterError {
    var p = str;
    if (curlx_str_number(&p, val, CURL_OFF_T_MAX) != 0 or
        curlx_str_single(&p, 0) != 0)
    {
        return PARAM_BAD_NUMERIC;
    }
    return PARAM_OK;
}

const MAX_USERPWDLENGTH: usize = 100 * 1024;

fn checkpasswd(kind: [*:0]const u8, i: usize, last: bool, userpwd: *?[*:0]u8) CURLcode {
    const up = userpwd.* orelse return CURLE_OK;
    const up_slice = std.mem.span(up);

    const psep_idx = std.mem.findScalar(u8, up_slice, ':');
    const osep_idx = std.mem.findScalar(u8, up_slice, ';');

    if (psep_idx == null and up[0] != ';') {
        var passwd: [2048]u8 = @splat(0);
        var prompt: [256]u8 = undefined;
        var dyn: Dynbuf = undefined;

        curlx_dyn_init(&dyn, MAX_USERPWDLENGTH);
        if (osep_idx) |oi| {
            up[oi] = 0;
        }

        if (i == 0 and last) {
            _ = curl_msnprintf(&prompt, prompt.len, "Enter %s password for user '%s':", kind, up);
        } else {
            _ = curl_msnprintf(&prompt, prompt.len, "Enter %s password for user '%s' on URL #%zu:", kind, up, i + 1);
        }

        _ = getpass_r(@ptrCast(&prompt), &passwd, passwd.len);
        if (osep_idx) |oi| {
            up[oi] = ';';
        }

        const passwd_z: [*:0]const u8 = @ptrCast(&passwd);
        if (curlx_dyn_addf(&dyn, "%s:%s", up, passwd_z) != CURLE_OK) {
            return CURLE_OUT_OF_MEMORY;
        }

        c.free(up);
        userpwd.* = curlx_dyn_ptr(&dyn);
    }

    return CURLE_OK;
}

pub export fn add2list(list: *?*curl_slist, ptr: [*:0]const u8) callconv(.c) ParameterError {
    const newlist = curl_slist_append(list.*, ptr) orelse return PARAM_NO_MEM;
    list.* = newlist;
    return PARAM_OK;
}

pub export fn ftpfilemethod(str: [*:0]const u8) callconv(.c) c_long {
    if (curl_strequal("singlecwd", str) != 0) {
        return CURLFTPMETHOD_SINGLECWD;
    }
    if (curl_strequal("nocwd", str) != 0) {
        return CURLFTPMETHOD_NOCWD;
    }
    if (curl_strequal("multicwd", str) != 0) {
        return CURLFTPMETHOD_MULTICWD;
    }
    warnf("unrecognized ftp file method '%s', using default", str);
    return CURLFTPMETHOD_MULTICWD;
}

pub export fn ftpcccmethod(str: [*:0]const u8) callconv(.c) c_long {
    if (curl_strequal("passive", str) != 0) {
        return CURLFTPSSL_CCC_PASSIVE;
    }
    if (curl_strequal("active", str) != 0) {
        return CURLFTPSSL_CCC_ACTIVE;
    }
    warnf("unrecognized ftp CCC method '%s', using default", str);
    return CURLFTPSSL_CCC_PASSIVE;
}

pub export fn delegation(str: [*:0]const u8) callconv(.c) c_long {
    if (curl_strequal("none", str) != 0) {
        return CURLGSSAPI_DELEGATION_NONE;
    }
    if (curl_strequal("policy", str) != 0) {
        return CURLGSSAPI_DELEGATION_POLICY_FLAG;
    }
    if (curl_strequal("always", str) != 0) {
        return CURLGSSAPI_DELEGATION_FLAG;
    }
    warnf("unrecognized delegation method '%s', using none", str);
    return CURLGSSAPI_DELEGATION_NONE;
}

fn isHeaderSep(x: u8) bool {
    return x == ':' or x == ';';
}

fn inlist(head_in: ?*const curl_slist, checkfor: []const u8) bool {
    var head = head_in;
    while (head) |node| : (head = node.next) {
        if (node.data) |d| {
            if (curl_strnequal(d, checkfor.ptr, checkfor.len) != 0 and
                isHeaderSep(d[checkfor.len]))
            {
                return true;
            }
        }
    }
    return false;
}

pub export fn get_args(config: *OperationConfig, i: usize) callconv(.c) CURLcode {
    var result: CURLcode = CURLE_OK;
    const last = (config.next == null);

    if (Curl_zig_config_is_jsoned(config)) {
        var err: ParameterError = PARAM_OK;
        if (!inlist(config.headers, "Content-Type")) {
            err = add2list(&config.headers, "Content-Type: application/json");
        }
        if (err == PARAM_OK and !inlist(config.headers, "Accept")) {
            err = add2list(&config.headers, "Accept: application/json");
        }
        if (err != PARAM_OK) {
            return CURLE_OUT_OF_MEMORY;
        }
    }

    if (config.userpwd != null and config.oauth_bearer == null) {
        result = checkpasswd("host", i, last, &config.userpwd);
    }

    if (result == CURLE_OK and config.proxyuserpwd != null) {
        result = checkpasswd("proxy", i, last, &config.proxyuserpwd);
    }

    return result;
}

const TlsMaxEntry = struct {
    tls_max_str: []const u8,
    tls_max: u8,
};

const tls_max_array = [_]TlsMaxEntry{
    .{ .tls_max_str = "default", .tls_max = 0 },
    .{ .tls_max_str = "1.0", .tls_max = 1 },
    .{ .tls_max_str = "1.1", .tls_max = 2 },
    .{ .tls_max_str = "1.2", .tls_max = 3 },
    .{ .tls_max_str = "1.3", .tls_max = 4 },
};

pub export fn str2tls_max(val: *u8, str: ?[*:0]const u8) callconv(.c) ParameterError {
    const s = str orelse return PARAM_REQUIRES_PARAMETER;
    const slice = std.mem.span(s);
    for (tls_max_array) |entry| {
        if (std.mem.eql(u8, slice, entry.tls_max_str)) {
            val.* = entry.tls_max;
            return PARAM_OK;
        }
    }
    return PARAM_BAD_USE;
}
