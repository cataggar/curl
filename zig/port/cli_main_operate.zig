//
// Ported from:
//   src/config2setopts.c
//   src/tool_operate.c
//   src/tool_main.c
//
// Phase 9 Session 48: Final CLI session — 100% pure-Zig curl CLI executable.
//

const std = @import("std");
const builtin = @import("builtin");

const is_windows = builtin.os.tag == .windows;
const is_darwin = builtin.os.tag.isDarwin();
const is_linux = builtin.os.tag == .linux;

pub const CURLcode = c_uint;
pub const CURLE_OK: CURLcode = 0;
pub const CURLE_UNSUPPORTED_PROTOCOL: CURLcode = 1;
pub const CURLE_FAILED_INIT: CURLcode = 2;
pub const CURLE_COULDNT_RESOLVE_PROXY: CURLcode = 5;
pub const CURLE_COULDNT_RESOLVE_HOST: CURLcode = 6;
pub const CURLE_COULDNT_CONNECT: CURLcode = 7;
pub const CURLE_FTP_ACCEPT_TIMEOUT: CURLcode = 12;
pub const CURLE_HTTP_RETURNED_ERROR: CURLcode = 22;
pub const CURLE_WRITE_ERROR: CURLcode = 23;
pub const CURLE_READ_ERROR: CURLcode = 26;
pub const CURLE_OUT_OF_MEMORY: CURLcode = 27;
pub const CURLE_OPERATION_TIMEDOUT: CURLcode = 28;
pub const CURLE_RANGE_ERROR: CURLcode = 33;
pub const CURLE_ABORTED_BY_CALLBACK: CURLcode = 42;
pub const CURLE_BAD_FUNCTION_ARGUMENT: CURLcode = 43;
pub const CURLE_UNKNOWN_OPTION: CURLcode = 48;
pub const CURLE_PEER_FAILED_VERIFICATION: CURLcode = 60;
pub const CURLE_NOT_BUILT_IN: CURLcode = 4;

pub const CURLMcode = c_int;
pub const CURLM_OK: CURLMcode = 0;
pub const CURLM_OUT_OF_MEMORY: CURLMcode = 3;

pub const CURLSHcode = c_uint;
pub const CURLSHE_OK: CURLSHcode = 0;
pub const CURLSHE_NOT_BUILT_IN: CURLSHcode = 5;

pub const CURLUcode = c_uint;
pub const CURLUE_OK: CURLUcode = 0;
pub const CURLUE_OUT_OF_MEMORY: CURLUcode = 7;
pub const CURLUE_NO_SCHEME: CURLUcode = 10;

pub const CURLUPart = c_uint;
pub const CURLUPART_URL: CURLUPart = 0;
pub const CURLUPART_SCHEME: CURLUPart = 1;
pub const CURLUPART_QUERY: CURLUPart = 8;

pub const CURLU_DEFAULT_SCHEME: c_uint = 1 << 2;
pub const CURLU_NON_SUPPORT_SCHEME: c_uint = 1 << 3;
pub const CURLU_APPENDQUERY: c_uint = 1 << 8;
pub const CURLU_GUESS_SCHEME: c_uint = 1 << 9;
pub const CURLU_NO_GUESS_SCHEME: c_uint = 1 << 15;

pub const CURLoption = c_uint;
pub const CURLMoption = c_uint;
pub const CURLSHoption = c_uint;
pub const CURLINFO = c_uint;
pub const CURLMinfo_offt = c_uint;

pub const curl_off_t = i64;
pub const timediff_t = i64;
pub const curl_socket_t = if (is_windows) usize else c_int;
pub const CURL_SOCKET_BAD: curl_socket_t = if (is_windows) ~@as(usize, 0) else -1;
pub const CURL_OFF_T_MAX: curl_off_t = std.math.maxInt(i64);
pub const LONG_MAX: curl_off_t = std.math.maxInt(c_long);

pub const CURL = opaque {};
pub const CURLM = opaque {};
pub const CURLSH = opaque {};
pub const CURLU = opaque {};
pub const FILE = opaque {};
pub const curl_mime = opaque {};
pub const curl_certinfo = opaque {};
pub const tool_var = opaque {};

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

pub const curltime = extern struct {
    tv_sec: i64 = 0,
    tv_usec: c_int = 0,
};

pub const URLPattern = opaque {};

pub const URLGlob = extern struct {
    buf: Dynbuf = .{ .bufr = null, .leng = 0, .allc = 0, .toobig = 0 },
    pattern: ?*URLPattern = null,
    literal: bool = false,
    palloc: usize = 0,
    pnum: usize = 0,
    beenhere: u8 = 0,
    @"error": ?[*:0]const u8 = null,
    pos: usize = 0,
};

pub const getout = extern struct {
    next: ?*getout = null,
    url: ?[*:0]u8 = null,
    outfile: ?[*:0]u8 = null,
    infile: ?[*:0]u8 = null,
    num: curl_off_t = 0,
    outset: bool = false,
    urlset: bool = false,
    uploadset: bool = false,
    useremote: bool = false,
    noupload: bool = false,
    noglob: bool = false,
    out_null: bool = false,
};

pub const State = extern struct {
    urlnode: ?*getout = null,
    inglob: URLGlob = .{},
    urlglob: URLGlob = .{},
    uploadfile: ?[*:0]u8 = null,
    upnum: curl_off_t = 0,
    upidx: curl_off_t = 0,
    urlnum: curl_off_t = 0,
    urlidx: curl_off_t = 0,
};

pub const tool_mime = extern struct {
    kind: c_uint,
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

pub const Timeval = extern struct {
    tv_sec: i64 = 0,
    tv_usec: c_long = 0,
};

pub const HttpReq = c_uint;
pub const TOOL_HTTPREQ_UNSPEC: HttpReq = 0;
pub const TOOL_HTTPREQ_GET: HttpReq = 1;
pub const TOOL_HTTPREQ_HEAD: HttpReq = 2;
pub const TOOL_HTTPREQ_MIMEPOST: HttpReq = 3;
pub const TOOL_HTTPREQ_SIMPLEPOST: HttpReq = 4;
pub const TOOL_HTTPREQ_PUT: HttpReq = 5;

pub const trace = c_uint;
pub const TRACE_NONE: trace = 0;
pub const TRACE_BIN: trace = 1;
pub const TRACE_ASCII: trace = 2;
pub const TRACE_PLAIN: trace = 3;

pub const SANITIZEcode = c_uint;
pub const SANITIZE_ERR_OK: SANITIZEcode = 0;
pub const SANITIZE_ERR_INVALID_PATH: SANITIZEcode = 1;
pub const SANITIZE_ERR_BAD_ARGUMENT: SANITIZEcode = 2;
pub const SANITIZE_ERR_OUT_OF_MEMORY: SANITIZEcode = 3;

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

pub const FAIL_NONE: u8 = 0;
pub const FAIL_WO_BODY: u8 = 1;
pub const FAIL_WITH_BODY: u8 = 2;

pub const CLOBBER_DEFAULT: c_uint = 0;
pub const CLOBBER_NEVER: c_uint = 1;
pub const CLOBBER_ALWAYS: c_uint = 2;

pub const CURL_PROGRESS_STATS: c_int = 0;
pub const CURL_PROGRESS_BAR: c_int = 1;
pub const PARALLEL_DEFAULT: c_ushort = 50;
pub const CONFIG_MAX_LEVELS: c_int = 10;
pub const CURL_ERROR_SIZE: usize = 256;
pub const STRERROR_LEN: usize = 256;

pub const RETRY_SLEEP_DEFAULT: u32 = 1000;
pub const RETRY_SLEEP_MAX: u32 = 600000;

// libcurl option / info / multi / share constants
pub const CURLOPTTYPE_LONG: CURLoption = 0;
pub const CURLOPTTYPE_OBJECTPOINT: CURLoption = 10000;
pub const CURLOPTTYPE_FUNCTIONPOINT: CURLoption = 20000;
pub const CURLOPTTYPE_OFF_T: CURLoption = 30000;
pub const CURLOPTTYPE_BLOB: CURLoption = 40000;
pub const CURLOPTTYPE_STRINGPOINT: CURLoption = CURLOPTTYPE_OBJECTPOINT;
pub const CURLOPTTYPE_SLISTPOINT: CURLoption = CURLOPTTYPE_OBJECTPOINT;
pub const CURLOPTTYPE_CBPOINT: CURLoption = CURLOPTTYPE_OBJECTPOINT;
pub const CURLOPTTYPE_VALUES: CURLoption = CURLOPTTYPE_LONG;

pub const CURLOPT_WRITEDATA: CURLoption = CURLOPTTYPE_CBPOINT + 1;
pub const CURLOPT_URL: CURLoption = CURLOPTTYPE_STRINGPOINT + 2;
pub const CURLOPT_PORT: CURLoption = CURLOPTTYPE_LONG + 3;
pub const CURLOPT_PROXY: CURLoption = CURLOPTTYPE_STRINGPOINT + 4;
pub const CURLOPT_USERPWD: CURLoption = CURLOPTTYPE_STRINGPOINT + 5;
pub const CURLOPT_PROXYUSERPWD: CURLoption = CURLOPTTYPE_STRINGPOINT + 6;
pub const CURLOPT_RANGE: CURLoption = CURLOPTTYPE_STRINGPOINT + 7;
pub const CURLOPT_READDATA: CURLoption = CURLOPTTYPE_CBPOINT + 9;
pub const CURLOPT_ERRORBUFFER: CURLoption = CURLOPTTYPE_OBJECTPOINT + 10;
pub const CURLOPT_WRITEFUNCTION: CURLoption = CURLOPTTYPE_FUNCTIONPOINT + 11;
pub const CURLOPT_READFUNCTION: CURLoption = CURLOPTTYPE_FUNCTIONPOINT + 12;
pub const CURLOPT_POSTFIELDS: CURLoption = CURLOPTTYPE_OBJECTPOINT + 15;
pub const CURLOPT_REFERER: CURLoption = CURLOPTTYPE_STRINGPOINT + 16;
pub const CURLOPT_FTPPORT: CURLoption = CURLOPTTYPE_STRINGPOINT + 17;
pub const CURLOPT_USERAGENT: CURLoption = CURLOPTTYPE_STRINGPOINT + 18;
pub const CURLOPT_LOW_SPEED_LIMIT: CURLoption = CURLOPTTYPE_LONG + 19;
pub const CURLOPT_LOW_SPEED_TIME: CURLoption = CURLOPTTYPE_LONG + 20;
pub const CURLOPT_COOKIE: CURLoption = CURLOPTTYPE_STRINGPOINT + 22;
pub const CURLOPT_HTTPHEADER: CURLoption = CURLOPTTYPE_SLISTPOINT + 23;
pub const CURLOPT_SSLCERT: CURLoption = CURLOPTTYPE_STRINGPOINT + 25;
pub const CURLOPT_KEYPASSWD: CURLoption = CURLOPTTYPE_STRINGPOINT + 26;
pub const CURLOPT_CRLF: CURLoption = CURLOPTTYPE_LONG + 27;
pub const CURLOPT_QUOTE: CURLoption = CURLOPTTYPE_SLISTPOINT + 28;
pub const CURLOPT_HEADERDATA: CURLoption = CURLOPTTYPE_CBPOINT + 29;
pub const CURLOPT_COOKIEFILE: CURLoption = CURLOPTTYPE_STRINGPOINT + 31;
pub const CURLOPT_SSLVERSION: CURLoption = CURLOPTTYPE_VALUES + 32;
pub const CURLOPT_TIMECONDITION: CURLoption = CURLOPTTYPE_VALUES + 33;
pub const CURLOPT_CUSTOMREQUEST: CURLoption = CURLOPTTYPE_STRINGPOINT + 36;
pub const CURLOPT_POSTQUOTE: CURLoption = CURLOPTTYPE_SLISTPOINT + 39;
pub const CURLOPT_VERBOSE: CURLoption = CURLOPTTYPE_LONG + 41;
pub const CURLOPT_HEADER: CURLoption = CURLOPTTYPE_LONG + 42;
pub const CURLOPT_NOBODY: CURLoption = CURLOPTTYPE_LONG + 44;
pub const CURLOPT_FAILONERROR: CURLoption = CURLOPTTYPE_LONG + 45;
pub const CURLOPT_UPLOAD: CURLoption = CURLOPTTYPE_LONG + 46;
pub const CURLOPT_POST: CURLoption = CURLOPTTYPE_LONG + 47;
pub const CURLOPT_DIRLISTONLY: CURLoption = CURLOPTTYPE_LONG + 48;
pub const CURLOPT_APPEND: CURLoption = CURLOPTTYPE_LONG + 50;
pub const CURLOPT_NETRC: CURLoption = CURLOPTTYPE_VALUES + 51;
pub const CURLOPT_FOLLOWLOCATION: CURLoption = CURLOPTTYPE_LONG + 52;
pub const CURLOPT_TRANSFERTEXT: CURLoption = CURLOPTTYPE_LONG + 53;
pub const CURLOPT_XFERINFODATA: CURLoption = CURLOPTTYPE_CBPOINT + 57;
pub const CURLOPT_AUTOREFERER: CURLoption = CURLOPTTYPE_LONG + 58;
pub const CURLOPT_HTTPPROXYTUNNEL: CURLoption = CURLOPTTYPE_LONG + 61;
pub const CURLOPT_INTERFACE: CURLoption = CURLOPTTYPE_STRINGPOINT + 62;
pub const CURLOPT_KRBLEVEL: CURLoption = CURLOPTTYPE_STRINGPOINT + 63;
pub const CURLOPT_SSL_VERIFYPEER: CURLoption = CURLOPTTYPE_LONG + 64;
pub const CURLOPT_CAINFO: CURLoption = CURLOPTTYPE_STRINGPOINT + 65;
pub const CURLOPT_MAXREDIRS: CURLoption = CURLOPTTYPE_LONG + 68;
pub const CURLOPT_FILETIME: CURLoption = CURLOPTTYPE_LONG + 69;
pub const CURLOPT_TELNETOPTIONS: CURLoption = CURLOPTTYPE_SLISTPOINT + 70;
pub const CURLOPT_HTTPGET: CURLoption = CURLOPTTYPE_LONG + 80;
pub const CURLOPT_SSL_VERIFYHOST: CURLoption = CURLOPTTYPE_LONG + 81;
pub const CURLOPT_COOKIEJAR: CURLoption = CURLOPTTYPE_STRINGPOINT + 82;
pub const CURLOPT_SSL_CIPHER_LIST: CURLoption = CURLOPTTYPE_STRINGPOINT + 83;
pub const CURLOPT_HTTP_VERSION: CURLoption = CURLOPTTYPE_VALUES + 84;
pub const CURLOPT_FTP_USE_EPSV: CURLoption = CURLOPTTYPE_LONG + 85;
pub const CURLOPT_SSLCERTTYPE: CURLoption = CURLOPTTYPE_STRINGPOINT + 86;
pub const CURLOPT_SSLKEY: CURLoption = CURLOPTTYPE_STRINGPOINT + 87;
pub const CURLOPT_SSLKEYTYPE: CURLoption = CURLOPTTYPE_STRINGPOINT + 88;
pub const CURLOPT_SSLENGINE: CURLoption = CURLOPTTYPE_STRINGPOINT + 89;
pub const CURLOPT_SSLENGINE_DEFAULT: CURLoption = CURLOPTTYPE_LONG + 90;
pub const CURLOPT_PREQUOTE: CURLoption = CURLOPTTYPE_SLISTPOINT + 93;
pub const CURLOPT_DEBUGFUNCTION: CURLoption = CURLOPTTYPE_FUNCTIONPOINT + 94;
pub const CURLOPT_DEBUGDATA: CURLoption = CURLOPTTYPE_CBPOINT + 95;
pub const CURLOPT_COOKIESESSION: CURLoption = CURLOPTTYPE_LONG + 96;
pub const CURLOPT_CAPATH: CURLoption = CURLOPTTYPE_STRINGPOINT + 97;
pub const CURLOPT_BUFFERSIZE: CURLoption = CURLOPTTYPE_LONG + 98;
pub const CURLOPT_NOSIGNAL: CURLoption = CURLOPTTYPE_LONG + 99;
pub const CURLOPT_SHARE: CURLoption = CURLOPTTYPE_OBJECTPOINT + 100;
pub const CURLOPT_PROXYTYPE: CURLoption = CURLOPTTYPE_VALUES + 101;
pub const CURLOPT_ACCEPT_ENCODING: CURLoption = CURLOPTTYPE_STRINGPOINT + 102;
pub const CURLOPT_PRIVATE: CURLoption = CURLOPTTYPE_OBJECTPOINT + 103;
pub const CURLOPT_UNRESTRICTED_AUTH: CURLoption = CURLOPTTYPE_LONG + 105;
pub const CURLOPT_FTP_USE_EPRT: CURLoption = CURLOPTTYPE_LONG + 106;
pub const CURLOPT_HTTPAUTH: CURLoption = CURLOPTTYPE_VALUES + 107;
pub const CURLOPT_FTP_CREATE_MISSING_DIRS: CURLoption = CURLOPTTYPE_LONG + 110;
pub const CURLOPT_PROXYAUTH: CURLoption = CURLOPTTYPE_VALUES + 111;
pub const CURLOPT_MAXFILESIZE_LARGE: CURLoption = CURLOPTTYPE_OFF_T + 117;
pub const CURLOPT_NETRC_FILE: CURLoption = CURLOPTTYPE_STRINGPOINT + 118;
pub const CURLOPT_USE_SSL: CURLoption = CURLOPTTYPE_VALUES + 119;
pub const CURLOPT_POSTFIELDSIZE_LARGE: CURLoption = CURLOPTTYPE_OFF_T + 120;
pub const CURLOPT_TCP_NODELAY: CURLoption = CURLOPTTYPE_LONG + 121;
pub const CURLOPT_FTPSSLAUTH: CURLoption = CURLOPTTYPE_VALUES + 129;
pub const CURLOPT_FTP_ACCOUNT: CURLoption = CURLOPTTYPE_STRINGPOINT + 134;
pub const CURLOPT_IGNORE_CONTENT_LENGTH: CURLoption = CURLOPTTYPE_LONG + 136;
pub const CURLOPT_FTP_SKIP_PASV_IP: CURLoption = CURLOPTTYPE_LONG + 137;
pub const CURLOPT_FTP_FILEMETHOD: CURLoption = CURLOPTTYPE_VALUES + 138;
pub const CURLOPT_LOCALPORT: CURLoption = CURLOPTTYPE_LONG + 139;
pub const CURLOPT_LOCALPORTRANGE: CURLoption = CURLOPTTYPE_LONG + 140;
pub const CURLOPT_MAX_SEND_SPEED_LARGE: CURLoption = CURLOPTTYPE_OFF_T + 145;
pub const CURLOPT_MAX_RECV_SPEED_LARGE: CURLoption = CURLOPTTYPE_OFF_T + 146;
pub const CURLOPT_FTP_ALTERNATIVE_TO_USER: CURLoption = CURLOPTTYPE_STRINGPOINT + 147;
pub const CURLOPT_SSL_SESSIONID_CACHE: CURLoption = CURLOPTTYPE_LONG + 150;
pub const CURLOPT_SSH_PUBLIC_KEYFILE: CURLoption = CURLOPTTYPE_STRINGPOINT + 152;
pub const CURLOPT_SSH_PRIVATE_KEYFILE: CURLoption = CURLOPTTYPE_STRINGPOINT + 153;
pub const CURLOPT_FTP_SSL_CCC: CURLoption = CURLOPTTYPE_LONG + 154;
pub const CURLOPT_TIMEOUT_MS: CURLoption = CURLOPTTYPE_LONG + 155;
pub const CURLOPT_CONNECTTIMEOUT_MS: CURLoption = CURLOPTTYPE_LONG + 156;
pub const CURLOPT_HTTP_TRANSFER_DECODING: CURLoption = CURLOPTTYPE_LONG + 157;
pub const CURLOPT_HTTP_CONTENT_DECODING: CURLoption = CURLOPTTYPE_LONG + 158;
pub const CURLOPT_NEW_FILE_PERMS: CURLoption = CURLOPTTYPE_LONG + 159;
pub const CURLOPT_POSTREDIR: CURLoption = CURLOPTTYPE_VALUES + 161;
pub const CURLOPT_SSH_HOST_PUBLIC_KEY_MD5: CURLoption = CURLOPTTYPE_STRINGPOINT + 162;
pub const CURLOPT_OPENSOCKETFUNCTION: CURLoption = CURLOPTTYPE_FUNCTIONPOINT + 163;
pub const CURLOPT_OPENSOCKETDATA: CURLoption = CURLOPTTYPE_CBPOINT + 164;
pub const CURLOPT_PROXY_TRANSFER_MODE: CURLoption = CURLOPTTYPE_LONG + 166;
pub const CURLOPT_SEEKFUNCTION: CURLoption = CURLOPTTYPE_FUNCTIONPOINT + 167;
pub const CURLOPT_SEEKDATA: CURLoption = CURLOPTTYPE_CBPOINT + 168;
pub const CURLOPT_CRLFILE: CURLoption = CURLOPTTYPE_STRINGPOINT + 169;
pub const CURLOPT_CERTINFO: CURLoption = CURLOPTTYPE_LONG + 172;
pub const CURLOPT_NOPROXY: CURLoption = CURLOPTTYPE_STRINGPOINT + 177;
pub const CURLOPT_TFTP_BLKSIZE: CURLoption = CURLOPTTYPE_LONG + 178;
pub const CURLOPT_SOCKS5_GSSAPI_NEC: CURLoption = CURLOPTTYPE_LONG + 180;
pub const CURLOPT_SSH_KNOWNHOSTS: CURLoption = CURLOPTTYPE_STRINGPOINT + 183;
pub const CURLOPT_MAIL_FROM: CURLoption = CURLOPTTYPE_STRINGPOINT + 186;
pub const CURLOPT_MAIL_RCPT: CURLoption = CURLOPTTYPE_SLISTPOINT + 187;
pub const CURLOPT_FTP_USE_PRET: CURLoption = CURLOPTTYPE_LONG + 188;
pub const CURLOPT_RTSP_REQUEST: CURLoption = CURLOPTTYPE_VALUES + 189;
pub const CURLOPT_RESOLVE: CURLoption = CURLOPTTYPE_SLISTPOINT + 203;
pub const CURLOPT_TLSAUTH_USERNAME: CURLoption = CURLOPTTYPE_STRINGPOINT + 204;
pub const CURLOPT_TLSAUTH_PASSWORD: CURLoption = CURLOPTTYPE_STRINGPOINT + 205;
pub const CURLOPT_TLSAUTH_TYPE: CURLoption = CURLOPTTYPE_STRINGPOINT + 206;
pub const CURLOPT_TRANSFER_ENCODING: CURLoption = CURLOPTTYPE_LONG + 207;
pub const CURLOPT_GSSAPI_DELEGATION: CURLoption = CURLOPTTYPE_VALUES + 210;
pub const CURLOPT_DNS_SERVERS: CURLoption = CURLOPTTYPE_STRINGPOINT + 211;
pub const CURLOPT_ACCEPTTIMEOUT_MS: CURLoption = CURLOPTTYPE_LONG + 212;
pub const CURLOPT_TCP_KEEPALIVE: CURLoption = CURLOPTTYPE_LONG + 213;
pub const CURLOPT_TCP_KEEPIDLE: CURLoption = CURLOPTTYPE_LONG + 214;
pub const CURLOPT_TCP_KEEPINTVL: CURLoption = CURLOPTTYPE_LONG + 215;
pub const CURLOPT_SSL_OPTIONS: CURLoption = CURLOPTTYPE_VALUES + 216;
pub const CURLOPT_MAIL_AUTH: CURLoption = CURLOPTTYPE_STRINGPOINT + 217;
pub const CURLOPT_XFERINFOFUNCTION: CURLoption = CURLOPTTYPE_FUNCTIONPOINT + 219;
pub const CURLOPT_XOAUTH2_BEARER: CURLoption = CURLOPTTYPE_STRINGPOINT + 220;
pub const CURLOPT_DNS_INTERFACE: CURLoption = CURLOPTTYPE_STRINGPOINT + 221;
pub const CURLOPT_DNS_LOCAL_IP4: CURLoption = CURLOPTTYPE_STRINGPOINT + 222;
pub const CURLOPT_DNS_LOCAL_IP6: CURLoption = CURLOPTTYPE_STRINGPOINT + 223;
pub const CURLOPT_LOGIN_OPTIONS: CURLoption = CURLOPTTYPE_STRINGPOINT + 224;
pub const CURLOPT_SSL_ENABLE_ALPN: CURLoption = CURLOPTTYPE_LONG + 226;
pub const CURLOPT_EXPECT_100_TIMEOUT_MS: CURLoption = CURLOPTTYPE_LONG + 227;
pub const CURLOPT_PROXYHEADER: CURLoption = CURLOPTTYPE_SLISTPOINT + 228;
pub const CURLOPT_HEADEROPT: CURLoption = CURLOPTTYPE_VALUES + 229;
pub const CURLOPT_PINNEDPUBLICKEY: CURLoption = CURLOPTTYPE_STRINGPOINT + 230;
pub const CURLOPT_UNIX_SOCKET_PATH: CURLoption = CURLOPTTYPE_STRINGPOINT + 231;
pub const CURLOPT_SSL_VERIFYSTATUS: CURLoption = CURLOPTTYPE_LONG + 232;
pub const CURLOPT_PATH_AS_IS: CURLoption = CURLOPTTYPE_LONG + 234;
pub const CURLOPT_PROXY_SERVICE_NAME: CURLoption = CURLOPTTYPE_STRINGPOINT + 235;
pub const CURLOPT_SERVICE_NAME: CURLoption = CURLOPTTYPE_STRINGPOINT + 236;
pub const CURLOPT_DEFAULT_PROTOCOL: CURLoption = CURLOPTTYPE_STRINGPOINT + 238;
pub const CURLOPT_CONNECT_TO: CURLoption = CURLOPTTYPE_SLISTPOINT + 243;
pub const CURLOPT_TCP_FASTOPEN: CURLoption = CURLOPTTYPE_LONG + 244;
pub const CURLOPT_KEEP_SENDING_ON_ERROR: CURLoption = CURLOPTTYPE_LONG + 245;
pub const CURLOPT_PRE_PROXY: CURLoption = CURLOPTTYPE_STRINGPOINT + 262;
pub const CURLOPT_PROXY_CAINFO: CURLoption = CURLOPTTYPE_STRINGPOINT + 246;
pub const CURLOPT_PROXY_CAPATH: CURLoption = CURLOPTTYPE_STRINGPOINT + 247;
pub const CURLOPT_PROXY_SSL_VERIFYPEER: CURLoption = CURLOPTTYPE_LONG + 248;
pub const CURLOPT_PROXY_SSL_VERIFYHOST: CURLoption = CURLOPTTYPE_LONG + 249;
pub const CURLOPT_PROXY_SSLVERSION: CURLoption = CURLOPTTYPE_VALUES + 250;
pub const CURLOPT_PROXY_TLSAUTH_USERNAME: CURLoption = CURLOPTTYPE_STRINGPOINT + 252;
pub const CURLOPT_PROXY_TLSAUTH_PASSWORD: CURLoption = CURLOPTTYPE_STRINGPOINT + 253;
pub const CURLOPT_PROXY_TLSAUTH_TYPE: CURLoption = CURLOPTTYPE_STRINGPOINT + 254;
pub const CURLOPT_PROXY_SSLCERT: CURLoption = CURLOPTTYPE_STRINGPOINT + 254;
pub const CURLOPT_PROXY_SSLCERTTYPE: CURLoption = CURLOPTTYPE_STRINGPOINT + 255;
pub const CURLOPT_PROXY_SSLKEY: CURLoption = CURLOPTTYPE_STRINGPOINT + 256;
pub const CURLOPT_PROXY_SSLKEYTYPE: CURLoption = CURLOPTTYPE_STRINGPOINT + 257;
pub const CURLOPT_PROXY_KEYPASSWD: CURLoption = CURLOPTTYPE_STRINGPOINT + 258;
pub const CURLOPT_PROXY_SSL_CIPHER_LIST: CURLoption = CURLOPTTYPE_STRINGPOINT + 259;
pub const CURLOPT_PROXY_CRLFILE: CURLoption = CURLOPTTYPE_STRINGPOINT + 260;
pub const CURLOPT_PROXY_SSL_OPTIONS: CURLoption = CURLOPTTYPE_LONG + 261;
pub const CURLOPT_SUPPRESS_CONNECT_HEADERS: CURLoption = CURLOPTTYPE_LONG + 265;
pub const CURLOPT_ABSTRACT_UNIX_SOCKET: CURLoption = CURLOPTTYPE_STRINGPOINT + 264;
pub const CURLOPT_REQUEST_TARGET: CURLoption = CURLOPTTYPE_STRINGPOINT + 266;
pub const CURLOPT_SOCKS5_AUTH: CURLoption = CURLOPTTYPE_LONG + 267;
pub const CURLOPT_SSH_COMPRESSION: CURLoption = CURLOPTTYPE_LONG + 268;
pub const CURLOPT_MIMEPOST: CURLoption = CURLOPTTYPE_OBJECTPOINT + 269;
pub const CURLOPT_TIMEVALUE_LARGE: CURLoption = CURLOPTTYPE_OFF_T + 270;
pub const CURLOPT_HAPPY_EYEBALLS_TIMEOUT_MS: CURLoption = CURLOPTTYPE_LONG + 271;
pub const CURLOPT_HAPROXYPROTOCOL: CURLoption = CURLOPTTYPE_LONG + 274;
pub const CURLOPT_DNS_SHUFFLE_ADDRESSES: CURLoption = CURLOPTTYPE_LONG + 275;
pub const CURLOPT_TLS13_CIPHERS: CURLoption = CURLOPTTYPE_STRINGPOINT + 276;
pub const CURLOPT_PROXY_TLS13_CIPHERS: CURLoption = CURLOPTTYPE_STRINGPOINT + 277;
pub const CURLOPT_DISALLOW_USERNAME_IN_URL: CURLoption = CURLOPTTYPE_LONG + 278;
pub const CURLOPT_DOH_URL: CURLoption = CURLOPTTYPE_STRINGPOINT + 279;
pub const CURLOPT_HTTP09_ALLOWED: CURLoption = CURLOPTTYPE_LONG + 285;
pub const CURLOPT_ALTSVC: CURLoption = CURLOPTTYPE_STRINGPOINT + 287;
pub const CURLOPT_SASL_AUTHZID: CURLoption = CURLOPTTYPE_STRINGPOINT + 289;
pub const CURLOPT_MAIL_RCPT_ALLOWFAILS: CURLoption = CURLOPTTYPE_LONG + 290;
pub const CURLOPT_SSLCERT_BLOB: CURLoption = CURLOPTTYPE_BLOB + 291;
pub const CURLOPT_SSLKEY_BLOB: CURLoption = CURLOPTTYPE_BLOB + 292;
pub const CURLOPT_PROXY_SSLCERT_BLOB: CURLoption = CURLOPTTYPE_BLOB + 293;
pub const CURLOPT_PROXY_SSLKEY_BLOB: CURLoption = CURLOPTTYPE_BLOB + 294;
pub const CURLOPT_SSL_EC_CURVES: CURLoption = CURLOPTTYPE_STRINGPOINT + 298;
pub const CURLOPT_HSTS: CURLoption = CURLOPTTYPE_STRINGPOINT + 300;
pub const CURLOPT_HSTS_CTRL: CURLoption = CURLOPTTYPE_LONG + 299;
pub const CURLOPT_AWS_SIGV4: CURLoption = CURLOPTTYPE_STRINGPOINT + 305;
pub const CURLOPT_DOH_SSL_VERIFYPEER: CURLoption = CURLOPTTYPE_LONG + 306;
pub const CURLOPT_DOH_SSL_VERIFYHOST: CURLoption = CURLOPTTYPE_LONG + 307;
pub const CURLOPT_DOH_SSL_VERIFYSTATUS: CURLoption = CURLOPTTYPE_LONG + 308;
pub const CURLOPT_CAINFO_BLOB: CURLoption = CURLOPTTYPE_BLOB + 309;
pub const CURLOPT_PROXY_CAINFO_BLOB: CURLoption = CURLOPTTYPE_BLOB + 310;
pub const CURLOPT_SSH_HOST_PUBLIC_KEY_SHA256: CURLoption = CURLOPTTYPE_STRINGPOINT + 311;
pub const CURLOPT_MAXLIFETIME_CONN: CURLoption = CURLOPTTYPE_LONG + 314;
pub const CURLOPT_MIME_OPTIONS: CURLoption = CURLOPTTYPE_LONG + 315;
pub const CURLOPT_PROTOCOLS_STR: CURLoption = CURLOPTTYPE_STRINGPOINT + 318;
pub const CURLOPT_REDIR_PROTOCOLS_STR: CURLoption = CURLOPTTYPE_STRINGPOINT + 319;
pub const CURLOPT_HAPROXY_CLIENT_IP: CURLoption = CURLOPTTYPE_STRINGPOINT + 323;
pub const CURLOPT_QUICK_EXIT: CURLoption = CURLOPTTYPE_LONG + 322;
pub const CURLOPT_ECH: CURLoption = CURLOPTTYPE_STRINGPOINT + 325;
pub const CURLOPT_TCP_KEEPCNT: CURLoption = CURLOPTTYPE_LONG + 326;
pub const CURLOPT_UPLOAD_FLAGS: CURLoption = CURLOPTTYPE_LONG + 327;
pub const CURLOPT_SSL_SIGNATURE_ALGORITHMS: CURLoption = CURLOPTTYPE_STRINGPOINT + 328;
pub const CURLOPT_IP_TOS: CURLoption = CURLOPTTYPE_LONG + 329;
pub const CURLOPT_VLAN_PRIORITY: CURLoption = CURLOPTTYPE_LONG + 330;
pub const CURLOPT_HTTPSIG_ALGORITHM: CURLoption = CURLOPTTYPE_VALUES + 329;
pub const CURLOPT_HTTPSIG_KEY: CURLoption = CURLOPTTYPE_STRINGPOINT + 330;
pub const CURLOPT_HTTPSIG_KEYID: CURLoption = CURLOPTTYPE_STRINGPOINT + 331;
pub const CURLOPT_HTTPSIG_HEADERS: CURLoption = CURLOPTTYPE_STRINGPOINT + 332;
pub const CURLOPT_SASL_IR: CURLoption = CURLOPTTYPE_LONG + 218;
pub const CURLOPT_TFTP_NO_OPTIONS: CURLoption = CURLOPTTYPE_LONG + 242;
pub const CURLOPT_IPRESOLVE: CURLoption = CURLOPTTYPE_VALUES + 113;
pub const CURLOPT_RESUME_FROM_LARGE: CURLoption = CURLOPTTYPE_OFF_T + 116;
pub const CURLOPT_INFILESIZE_LARGE: CURLoption = CURLOPTTYPE_OFF_T + 115;
pub const CURLOPT_PROXY_PINNEDPUBLICKEY: CURLoption = CURLOPTTYPE_STRINGPOINT + 263;

pub const CURLFOLLOW_ALL: c_long = 1;
pub const CURLFOLLOW_OBEYCODE: c_long = 2;
pub const CURLFOLLOW_FIRSTONLY: c_long = 3;

pub const CURL_REDIR_POST_301: c_long = 1;
pub const CURL_REDIR_POST_302: c_long = 2;
pub const CURL_REDIR_POST_303: c_long = 4;

pub const CURL_NETRC_OPTIONAL: c_long = 1;
pub const CURL_NETRC_REQUIRED: c_long = 2;

pub const CURL_SSLVERSION_DEFAULT: c_long = 0;

pub const CURLSSLOPT_ALLOW_BEAST: c_long = (1 << 0);
pub const CURLSSLOPT_NO_REVOKE: c_long = (1 << 1);
pub const CURLSSLOPT_NO_PARTIALCHAIN: c_long = (1 << 2);
pub const CURLSSLOPT_REVOKE_BEST_EFFORT: c_long = (1 << 3);
pub const CURLSSLOPT_NATIVE_CA: c_long = (1 << 4);
pub const CURLSSLOPT_AUTO_CLIENT_CERT: c_long = (1 << 5);
pub const CURLSSLOPT_EARLYDATA: c_long = (1 << 6);

pub const CURLUSESSL_TRY: c_long = 1;
pub const CURLUSESSL_CONTROL: c_long = 2;
pub const CURLUSESSL_ALL: c_long = 3;

pub const CURLFTPAUTH_DEFAULT: c_long = 0;

pub const CURLAUTH_NONE: c_ulong = 0;
pub const CURLAUTH_BASIC: c_ulong = (1 << 0);
pub const CURLAUTH_DIGEST: c_ulong = (1 << 1);
pub const CURLAUTH_NEGOTIATE: c_ulong = (1 << 2);
pub const CURLAUTH_NTLM: c_ulong = (1 << 3);
pub const CURLAUTH_DIGEST_IE: c_ulong = (1 << 4);
pub const CURLAUTH_BEARER: c_ulong = (1 << 6);
pub const CURLAUTH_AWS_SIGV4: c_ulong = (1 << 7);
pub const CURLAUTH_HTTPSIG: c_ulong = (1 << 8);
pub const CURLAUTH_ONLY: c_ulong = (@as(c_ulong, 1) << 31);
pub const CURLAUTH_ANY: c_ulong = (~(CURLAUTH_DIGEST_IE | CURLAUTH_HTTPSIG)) & 0xffffffff;

pub const CURLHEADER_UNIFIED: c_long = 0;
pub const CURLHEADER_SEPARATE: c_long = (1 << 0);

pub const CURLHSTS_ENABLE: c_long = (1 << 0);

pub const CURLFTP_CREATE_DIR: c_long = 1;
pub const CURLFTP_CREATE_DIR_RETRY: c_long = 2;

pub const CURL_RTSPREQ_NONE: c_long = 0;
pub const CURL_RTSPREQ_OPTIONS: c_long = 1;
pub const CURL_RTSPREQ_DESCRIBE: c_long = 2;

pub const CURLINFO_STRING: CURLINFO = 0x100000;
pub const CURLINFO_LONG: CURLINFO = 0x200000;
pub const CURLINFO_DOUBLE: CURLINFO = 0x300000;
pub const CURLINFO_SLIST: CURLINFO = 0x400000;
pub const CURLINFO_PTR: CURLINFO = 0x400000;
pub const CURLINFO_SOCKET: CURLINFO = 0x500000;
pub const CURLINFO_OFF_T: CURLINFO = 0x600000;

pub const CURLINFO_EFFECTIVE_URL: CURLINFO = CURLINFO_STRING + 1;
pub const CURLINFO_RESPONSE_CODE: CURLINFO = CURLINFO_LONG + 2;
pub const CURLINFO_FILETIME_T: CURLINFO = CURLINFO_OFF_T + 14;
pub const CURLINFO_REDIRECT_COUNT: CURLINFO = CURLINFO_LONG + 20;
pub const CURLINFO_PRIVATE: CURLINFO = CURLINFO_STRING + 21;
pub const CURLINFO_HTTP_CONNECTCODE: CURLINFO = CURLINFO_LONG + 22;
pub const CURLINFO_OS_ERRNO: CURLINFO = CURLINFO_LONG + 25;
pub const CURLINFO_LASTSOCKET: CURLINFO = CURLINFO_LONG + 29;
pub const CURLINFO_FTP_ENTRY_PATH: CURLINFO = CURLINFO_STRING + 30;
pub const CURLINFO_REDIRECT_URL: CURLINFO = CURLINFO_STRING + 31;
pub const CURLINFO_CERTINFO: CURLINFO = CURLINFO_PTR + 34;
pub const CURLINFO_ACTIVESOCKET: CURLINFO = CURLINFO_SOCKET + 44;
pub const CURLINFO_HTTP_VERSION: CURLINFO = CURLINFO_LONG + 46;
pub const CURLINFO_PROTOCOL: CURLINFO = CURLINFO_LONG + 48;
pub const CURLINFO_SCHEME: CURLINFO = CURLINFO_STRING + 49;
pub const CURLINFO_RETRY_AFTER: CURLINFO = CURLINFO_OFF_T + 57;

pub const CURLMOPT_PIPELINING: CURLMoption = CURLOPTTYPE_LONG + 3;
pub const CURLMOPT_MAX_HOST_CONNECTIONS: CURLMoption = CURLOPTTYPE_LONG + 7;
pub const CURLMOPT_MAX_CONCURRENT_STREAMS: CURLMoption = CURLOPTTYPE_LONG + 16;

pub const CURLPAUSE_RECV: c_int = (1 << 0);
pub const CURLPAUSE_SEND: c_int = (1 << 2);
pub const CURLPAUSE_ALL: c_int = (CURLPAUSE_RECV | CURLPAUSE_SEND);
pub const CURLPAUSE_CONT: c_int = 0;

pub const CURLMSG_DONE: c_uint = 1;

pub const CURLSHOPT_SHARE: CURLSHoption = 1;

pub const curl_lock_data = c_uint;
pub const CURL_LOCK_DATA_COOKIE: curl_lock_data = 2;
pub const CURL_LOCK_DATA_DNS: curl_lock_data = 3;
pub const CURL_LOCK_DATA_SSL_SESSION: curl_lock_data = 4;
pub const CURL_LOCK_DATA_CONNECT: curl_lock_data = 5;
pub const CURL_LOCK_DATA_PSL: curl_lock_data = 6;
pub const CURL_LOCK_DATA_HSTS: curl_lock_data = 7;

pub const CURLH_HEADER: c_uint = (1 << 0);
pub const CURLHE_OK: c_uint = 0;

pub const CURL_VERSION_SSL: c_int = (1 << 2);
pub const CURL_VERSION_LARGEFILE: c_int = (1 << 9);

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
    resume_from: curl_off_t,
    postfields: ?[*:0]u8,
    referer: ?[*:0]u8,
    query: ?[*:0]u8,
    max_filesize: curl_off_t,
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
    mimepost: ?*curl_mime,
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
    condtime: curl_off_t,
    sendpersecond: curl_off_t,
    recvpersecond: curl_off_t,
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
    remote_name_all: bool,
    remote_time: bool,
    cookiesession: bool,
    encoding: bool,
    tr_encoding: bool,
    use_resume: bool,
    resume_from_current: bool,
    disable_epsv: bool,
    disable_eprt: bool,
    ftp_pret: bool,
    proto_present: bool,
    proto_redir_present: bool,
    mail_rcpt_allowfails: bool,
    sasl_ir: bool,
    proxytunnel: bool,
    ftp_append: bool,
    use_ascii: bool,
    autoreferer: bool,
    show_headers: bool,
    no_body: bool,
    dirlistonly: bool,
    unrestricted_auth: bool,
    netrc_opt: bool,
    netrc: bool,
    crlf: bool,
    http09_allowed: bool,
    nobuffer: bool,
    readbusy: bool,
    globoff: bool,
    use_httpget: bool,
    insecure_ok: bool,
    doh_insecure_ok: bool,
    proxy_insecure_ok: bool,
    terminal_binary_ok: bool,
    verifystatus: bool,
    doh_verifystatus: bool,
    create_dirs: bool,
    ftp_create_dirs: bool,
    ftp_skip_ip: bool,
    proxynegotiate: bool,
    proxyntlm: bool,
    proxydigest: bool,
    proxybasic: bool,
    proxyanyauth: bool,
    jsoned: bool,
    ftp_ssl: bool,
    ftp_ssl_reqd: bool,
    ftp_ssl_control: bool,
    ftp_ssl_ccc: bool,
    socks5_gssapi_nec: bool,
    tcp_nodelay: bool,
    tcp_fastopen: bool,
    retry_all_errors: bool,
    retry_connrefused: bool,
    tftp_no_options: bool,
    ignorecl: bool,
    disable_sessionid: bool,
    raw: bool,
    post301: bool,
    post302: bool,
    post303: bool,
    nokeepalive: bool,
    content_disposition: bool,
    xattr: bool,
    ssl_allow_beast: bool,
    ssl_allow_earlydata: bool,
    proxy_ssl_allow_beast: bool,
    ssl_no_revoke: bool,
    ssl_revoke_best_effort: bool,
    native_ca_store: bool,
    proxy_native_ca_store: bool,
    ssl_auto_client_cert: bool,
    proxy_ssl_auto_client_cert: bool,
    noalpn: bool,
    abstract_unix_socket: bool,
    path_as_is: bool,
    suppress_connect_headers: bool,
    synthetic_error: bool,
    ssh_compression: bool,
    haproxy_protocol: bool,
    disallow_username_in_url: bool,
    mptcp: bool,
    rm_partial: bool,
    skip_existing: bool,
};

pub const termout = extern struct {
    buf: ?[*]u16 = null,
    len: u32 = 0,
};

pub const GlobalConfig = extern struct {
    state: State = .{},
    trace_dump: ?[*:0]u8 = null,
    trace_stream: ?*FILE = null,
    libcurl: ?[*:0]u8 = null,
    ssl_sessions: ?[*:0]u8 = null,
    variables: ?*tool_var = null,
    first: ?*OperationConfig = null,
    current: ?*OperationConfig = null,
    last: ?*OperationConfig = null,
    term: termout = .{},
    ms_per_transfer: timediff_t = 0,
    tracetype: trace = TRACE_NONE,
    progressmode: c_int = CURL_PROGRESS_STATS,
    parallel_host: c_ushort = 0,
    parallel_max: c_ushort = PARALLEL_DEFAULT,
    verbosity: u8 = 0,
    parallel: bool = false,
    parallel_connect: bool = false,
    fail_early: bool = false,
    styled_output: bool = true,
    trace_fopened: bool = false,
    tracetime: bool = false,
    traceids: bool = false,
    showerror: bool = false,
    silent: bool = false,
    noprogress: bool = false,
    isatty: bool = false,
    trace_set: bool = false,
};

pub const OutStruct = extern struct {
    filename: ?[*:0]u8 = null,
    stream: ?*FILE = null,
    bytes: curl_off_t = 0,
    init: curl_off_t = 0,
    utf8seq: [5]u8 = @splat(0),
    alloc_filename: bool = false,
    is_cd_filename: bool = false,
    regular_file: bool = false,
    fopened: bool = false,
    out_null: bool = false,
};

pub const HdrCbData = extern struct {
    config: ?*OperationConfig = null,
    outs: ?*OutStruct = null,
    heads: ?*OutStruct = null,
    etag_save: ?*OutStruct = null,
    headlist: ?*slist_wc = null,
    honor_cd_filename: bool = false,
};

pub const ProgressData = extern struct {
    calls: c_int = 0,
    prev: curl_off_t = 0,
    prevtime: curltime = .{},
    width: c_int = 0,
    out: ?*FILE = null,
    initial_size: curl_off_t = 0,
    tick: c_uint = 0,
    bar: c_int = 0,
    barmove: c_int = 0,
};

pub const per_transfer = extern struct {
    errorbuffer: [CURL_ERROR_SIZE]u8 = @splat(0),
    next: ?*per_transfer = null,
    prev: ?*per_transfer = null,
    config: ?*OperationConfig = null,
    certinfo: ?*const curl_certinfo = null,
    curl: ?*CURL = null,
    uploadfile: ?[*:0]u8 = null,
    retry_remaining: c_long = 0,
    num_retries: c_long = 0,
    start: curltime = .{},
    retrystart: curltime = .{},
    url: ?[*:0]u8 = null,
    urlnum: curl_off_t = 0,
    outfile: ?[*:0]u8 = null,
    out_scheme: ?[*:0]const u8 = null,
    infd: c_int = 0,
    progressbar: ProgressData = .{},
    outs: OutStruct = .{},
    heads: OutStruct = .{},
    etag_save: OutStruct = .{},
    hdrcbdata: HdrCbData = .{},
    num_headers: c_long = 0,
    startat: i64 = 0,
    dltotal: curl_off_t = 0,
    dlnow: curl_off_t = 0,
    ultotal: curl_off_t = 0,
    ulnow: curl_off_t = 0,
    uploadfilesize: curl_off_t = 0,
    uploadedsofar: curl_off_t = 0,
    retry_sleep_default: u32 = 0,
    retry_sleep: u32 = 0,
    dltotal_added: bool = false,
    ultotal_added: bool = false,
    infdopen: bool = false,
    noprogress: bool = false,
    was_last_header_empty: bool = false,
    added: bool = false,
    abort: bool = false,
    skip: bool = false,
};

pub const NameValue = extern struct {
    name: ?[*:0]const u8,
    value: c_long,
};

pub const NameValueUnsigned = extern struct {
    name: ?[*:0]const u8,
    value: c_ulong,
};

pub const curl_version_info_data = extern struct {
    age: c_uint,
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
};

// ============================================================================
// Externs from libcurl, libc, and sibling Zig CLI modules
// ============================================================================

extern var global: ?*GlobalConfig;
extern var tool_stderr: ?*FILE;
extern var curlinfo: ?*curl_version_info_data;

extern var proto_http: ?[*:0]const u8;
extern var proto_https: ?[*:0]const u8;
extern var proto_ftp: ?[*:0]const u8;
extern var proto_ftps: ?[*:0]const u8;
extern var proto_scp: ?[*:0]const u8;
extern var proto_sftp: ?[*:0]const u8;
extern var proto_tftp: ?[*:0]const u8;
extern var proto_rtsp: ?[*:0]const u8;
extern var proto_file: ?[*:0]const u8;
extern var proto_ipfs: ?[*:0]const u8;
extern var proto_ipns: ?[*:0]const u8;

extern var feature_ssl: bool;
extern var feature_ech: bool;
extern var feature_ssls_export: bool;

extern const setopt_nv_CURLPROXY: [8]NameValue;
extern const setopt_nv_CURL_SOCKS_PROXY: [5]NameValue;
extern const setopt_nv_CURL_HTTP_VERSION: [8]NameValue;
extern const setopt_nv_CURL_SSLVERSION: [9]NameValue;
extern const setopt_nv_CURL_SSLVERSION_MAX: [7]NameValue;
extern const setopt_nv_CURL_TIMECOND: [5]NameValue;
extern const setopt_nv_CURLFTPSSL_CCC: [4]NameValue;
extern const setopt_nv_CURLUSESSL: [5]NameValue;
extern const setopt_nv_CURLSSLOPT: [7]NameValueUnsigned;
extern const setopt_nv_CURL_NETRC: [4]NameValue;
extern const setopt_nv_CURLOPT_FOLLOWLOCATION: [5]NameValue;
extern const setopt_nv_CURLAUTH: [10]NameValueUnsigned;
extern const setopt_nv_CURLHSTS: [2]NameValueUnsigned;

extern fn tool_setopt_enum(curl: ?*CURL, name: [*:0]const u8, tag: CURLoption, nvlist: [*]const NameValue, lval: c_long) callconv(.c) CURLcode;
extern fn tool_setopt_SSLVERSION(curl: ?*CURL, name: [*:0]const u8, tag: CURLoption, lval: c_long) callconv(.c) CURLcode;
extern fn tool_setopt_bitmask(curl: ?*CURL, name: [*:0]const u8, tag: CURLoption, nvlist: [*]const NameValueUnsigned, lval: c_long) callconv(.c) CURLcode;
extern fn tool_setopt_mimepost(curl: ?*CURL, config: *OperationConfig, name: [*:0]const u8, tag: CURLoption, mimepost: ?*curl_mime) callconv(.c) CURLcode;
extern fn tool_setopt_slist(curl: ?*CURL, name: [*:0]const u8, tag: CURLoption, list: ?*curl_slist) callconv(.c) CURLcode;
extern fn tool_setopt_long(curl: ?*CURL, name: [*:0]const u8, tag: CURLoption, lval: c_long) callconv(.c) CURLcode;
extern fn tool_setopt_long_force(curl: ?*CURL, name: [*:0]const u8, tag: CURLoption, lval: c_long) callconv(.c) CURLcode;
extern fn tool_setopt_offt(curl: ?*CURL, name: [*:0]const u8, tag: CURLoption, lval: curl_off_t) callconv(.c) CURLcode;
extern fn tool_setopt_str(curl: ?*CURL, config: *OperationConfig, name: [*:0]const u8, tag: CURLoption, value: ?[*:0]const u8) callconv(.c) CURLcode;
extern fn tool_setopt_ptr(curl: ?*CURL, name: [*:0]const u8, tag: CURLoption, ...) callconv(.c) CURLcode;

extern fn tool_debug_cb(handle: ?*CURL, @"type": c_uint, data: [*]u8, size: usize, userptr: ?*anyopaque) callconv(.c) c_int;
extern fn tool_write_cb(buffer: [*]u8, sz: usize, nmemb: usize, userdata: ?*anyopaque) callconv(.c) usize;
extern fn tool_read_cb(buffer: [*]u8, sz: usize, nmemb: usize, userdata: ?*anyopaque) callconv(.c) usize;
extern fn tool_seek_cb(userdata: ?*anyopaque, offset: curl_off_t, whence: c_int) callconv(.c) c_int;
extern fn tool_progress_cb(clientp: ?*anyopaque, dltotal: curl_off_t, dlnow: curl_off_t, ultotal: curl_off_t, ulnow: curl_off_t) callconv(.c) c_int;
extern fn tool_readbusy_cb(clientp: ?*anyopaque, dltotal: curl_off_t, dlnow: curl_off_t, ultotal: curl_off_t, ulnow: curl_off_t) callconv(.c) c_int;
extern fn tool_header_cb(ptr: [*]u8, size: usize, nmemb: usize, userdata: ?*anyopaque) callconv(.c) usize;
extern fn tool_socket_open_mptcp_cb(clientp: ?*anyopaque, purpose: c_uint, address: ?*anyopaque) callconv(.c) curl_socket_t;
extern fn xferinfo_cb(clientp: ?*anyopaque, dltotal: curl_off_t, dlnow: curl_off_t, ultotal: curl_off_t, ulnow: curl_off_t) callconv(.c) c_int;

extern fn progressbarinit(bar: *ProgressData, config: *OperationConfig) callconv(.c) void;
extern fn progress_meter(multi: ?*CURLM, start: *curltime, final: bool) callconv(.c) bool;
extern fn progress_finalize(per: *per_transfer) callconv(.c) void;
extern fn tool_create_output_file(outs: *OutStruct, config: *OperationConfig) callconv(.c) bool;
extern fn ourWriteOut(config: *OperationConfig, per: *per_transfer, per_result: CURLcode) callconv(.c) void;
extern fn fwrite_xattr(curl: ?*CURL, url: ?[*:0]const u8, fd: c_int, filename: ?[*:0]const u8) callconv(.c) c_int;
extern fn setfiletime(filetime: curl_off_t, filename: [*:0]const u8) callconv(.c) void;
extern fn create_dir_hierarchy(outfile: [*:0]const u8) callconv(.c) CURLcode;
extern fn slist_wc_free_all(list: ?*slist_wc) callconv(.c) void;

extern fn config_alloc() callconv(.c) ?*OperationConfig;
extern fn config_free(config: ?*OperationConfig) callconv(.c) void;
extern fn globalconf_init() callconv(.c) CURLcode;
extern fn globalconf_free() callconv(.c) void;
extern fn tool_init_stderr() callconv(.c) void;
extern fn proto_token(proto: ?[*:0]const u8) callconv(.c) ?[*:0]const u8;
extern fn ipfs_url_rewrite(uh: *CURLU, protocol: [*:0]const u8, url: *?[*:0]u8, config: *OperationConfig) callconv(.c) CURLcode;
extern fn findfile(fname: [*:0]const u8, dotscore: c_int) callconv(.c) ?[*:0]u8;
extern fn file2string(bufp: *?[*:0]u8, file: ?*FILE) callconv(.c) ParameterError;
extern fn tool2curlmime(curl: ?*CURL, m: ?*tool_mime, mime: *?*curl_mime) callconv(.c) CURLcode;
extern fn customrequest_helper(req: HttpReq, custom: ?[*:0]const u8) callconv(.c) void;
extern fn SetHTTPrequest(request: HttpReq, reqp: *HttpReq) callconv(.c) c_int;
extern fn add2list(list: *?*curl_slist, ptr: [*:0]const u8) callconv(.c) ParameterError;
extern fn urlerr_cvt(ucode: CURLUcode) callconv(.c) CURLcode;
extern fn stdin_upload(uploadfile: [*:0]const u8) callconv(.c) bool;
extern fn output_expected(url: [*:0]const u8, uploadfile: ?[*:0]const u8) callconv(.c) bool;
extern fn add_file_name_to_url(curl: ?*CURL, inurlp: *?[*:0]u8, filename: [*:0]const u8) callconv(.c) CURLcode;
extern fn get_url_file_name(filename: *?[*:0]u8, url: ?[*:0]const u8, sc: *SANITIZEcode) callconv(.c) CURLcode;
extern fn clean_getout(config: *OperationConfig) callconv(.c) void;
extern fn get_args(config: *OperationConfig, i: usize) callconv(.c) CURLcode;
extern fn parse_args(argc: c_int, argv: [*]?[*:0]u8) callconv(.c) ParameterError;
extern fn parseconfig(filename: ?[*:0]const u8, max_recursive: c_int, used_path: *?[*:0]u8) callconv(.c) c_int;
extern fn sanitize_file_name(entino: *?[*:0]u8, file_name: ?[*:0]const u8, flags: c_int) callconv(.c) SANITIZEcode;
extern fn toolx_ftruncate_win32(fd: c_int, where: i64) callconv(.c) c_int;
extern fn FindWin32CACert(config: *OperationConfig, bundle_file: [*:0]const u8) callconv(.c) CURLcode;
extern fn win32_init() callconv(.c) CURLcode;
extern fn win32_stdin_read_thread() callconv(.c) curl_socket_t;
extern fn tvrealnow() callconv(.c) Timeval;
extern fn toolx_localtime(intime: i64, store: ?*anyopaque) callconv(.c) CURLcode;

extern var easysrc_decl: ?*slist_wc;
extern var easysrc_data: ?*slist_wc;
extern var easysrc_code: ?*slist_wc;
extern var easysrc_toohard: ?*slist_wc;
extern var easysrc_clean: ?*slist_wc;
extern var easysrc_mime_count: c_int;
extern var easysrc_slist_count: c_int;

extern fn easysrc_add(plist: *?*slist_wc, bline: [*:0]const u8) callconv(.c) CURLcode;

// ============================================================================
// Platform / OS / Stdio Abstractions
// ============================================================================

const ToolStat = struct {
    is_reg: bool = false,
    is_dir: bool = false,
    is_chr: bool = false,
    size: i64 = 0,
    mtime: i64 = 0,
};

const win_c = if (is_windows) struct {
    const Win32Stat64 = extern struct {
        st_dev: u32,
        st_ino: u16,
        st_mode: u16,
        st_nlink: i16,
        st_uid: i16,
        st_gid: i16,
        st_rdev: u32,
        st_size: i64,
        st_atime: i64,
        st_mtime: i64,
        st_ctime: i64,
    };

    const O_RDONLY: c_int = 0x0000;
    const O_WRONLY: c_int = 0x0001;
    const O_RDWR: c_int = 0x0002;
    const O_CREAT: c_int = 0x0100;
    const O_TRUNC: c_int = 0x0200;
    const O_EXCL: c_int = 0x0400;
    const O_BINARY: c_int = 0x8000;

    extern "c" fn __acrt_iob_func(ix: c_uint) callconv(.c) ?*FILE;
    extern "c" fn _fileno(stream: ?*FILE) callconv(.c) c_int;
    extern "c" fn _setmode(fd: c_int, mode: c_int) callconv(.c) c_int;
    extern "c" fn _fstati64(fd: c_int, buffer: *Win32Stat64) callconv(.c) c_int;
    extern "c" fn _fseeki64(stream: ?*FILE, offset: i64, origin: c_int) callconv(.c) c_int;
    extern "c" fn _ftelli64(stream: ?*FILE) callconv(.c) i64;
    extern "c" fn _fdopen(fd: c_int, mode: [*:0]const u8) callconv(.c) ?*FILE;
    extern "c" fn _close(fd: c_int) callconv(.c) c_int;
    extern "c" fn _unlink(filename: [*:0]const u8) callconv(.c) c_int;
    extern "c" fn _errno() callconv(.c) *c_int;
    extern fn curlx_win32_fopen(filename: ?[*:0]const u8, mode: ?[*:0]const u8) callconv(.c) ?*FILE;
    extern fn curlx_win32_open(filename: ?[*:0]const u8, oflag: c_int, pmode: c_int) callconv(.c) c_int;
    extern fn curlx_win32_stat(path: ?[*:0]const u8, buffer: ?*anyopaque) callconv(.c) c_int;
    extern "kernel32" fn GetStdHandle(nStdHandle: u32) callconv(.winapi) ?*anyopaque;
    extern "kernel32" fn GetConsoleMode(hConsoleHandle: ?*anyopaque, lpMode: *u32) callconv(.winapi) c_int;
    extern "kernel32" fn SetConsoleMode(hConsoleHandle: ?*anyopaque, dwMode: u32) callconv(.winapi) c_int;
} else struct {};

const posix_c = if (!is_windows) struct {
    const passwd = extern struct {
        pw_name: ?[*:0]u8,
        pw_passwd: ?[*:0]u8,
        pw_uid: u32,
        pw_gid: u32,
        pw_gecos: ?[*:0]u8,
        pw_dir: ?[*:0]u8,
        pw_shell: ?[*:0]u8,
    };

    const passwd_darwin = extern struct {
        pw_name: ?[*:0]u8,
        pw_passwd: ?[*:0]u8,
        pw_uid: u32,
        pw_gid: u32,
        pw_change: c_long,
        pw_class: ?[*:0]u8,
        pw_gecos: ?[*:0]u8,
        pw_dir: ?[*:0]u8,
        pw_shell: ?[*:0]u8,
        pw_expire: c_long,
    };

    const termios_linux = extern struct {
        c_iflag: c_uint,
        c_oflag: c_uint,
        c_cflag: c_uint,
        c_lflag: c_uint,
        c_line: u8,
        c_cc: [32]u8,
        c_ispeed: c_uint,
        c_ospeed: c_uint,
    };

    const termios_darwin = extern struct {
        c_iflag: c_ulong,
        c_oflag: c_ulong,
        c_cflag: c_ulong,
        c_lflag: c_ulong,
        c_cc: [20]u8,
        c_ispeed: c_ulong,
        c_ospeed: c_ulong,
    };

    const Termios = if (builtin.os.tag.isDarwin()) termios_darwin else termios_linux;
    const ECHO_FLAG: u32 = 0o000010;
    const TCSANOW: c_int = 0;

    const O_RDONLY: c_int = 0;
    const O_WRONLY: c_int = 1;
    const O_RDWR: c_int = 2;
    const O_CREAT: c_int = if (builtin.os.tag.isDarwin()) 0x0200 else 0o100;
    const O_EXCL: c_int = if (builtin.os.tag.isDarwin()) 0x0800 else 0o200;
    const O_TRUNC: c_int = if (builtin.os.tag.isDarwin()) 0x0400 else 0o1000;
    const O_BINARY: c_int = 0;

    extern "c" fn fopen(filename: [*:0]const u8, mode: [*:0]const u8) callconv(.c) ?*FILE;
    extern "c" fn fdopen(fd: c_int, mode: [*:0]const u8) callconv(.c) ?*FILE;
    extern "c" fn fileno(stream: ?*FILE) callconv(.c) c_int;
    extern "c" fn fseeko(stream: ?*FILE, offset: i64, whence: c_int) callconv(.c) c_int;
    extern "c" fn ftello(stream: ?*FILE) callconv(.c) i64;
    extern "c" fn open(path: [*:0]const u8, oflag: c_int, ...) callconv(.c) c_int;
    extern "c" fn close(fd: c_int) callconv(.c) c_int;
    extern "c" fn pipe(pipefd: *[2]c_int) callconv(.c) c_int;
    extern "c" fn ftruncate(fd: c_int, length: i64) callconv(.c) c_int;
    extern "c" fn unlink(pathname: [*:0]const u8) callconv(.c) c_int;
    extern "c" fn geteuid() callconv(.c) u32;
    extern "c" fn getpwuid(uid: u32) callconv(.c) ?*anyopaque;
    extern "c" fn tcgetattr(fd: c_int, termios_p: *Termios) callconv(.c) c_int;
    extern "c" fn tcsetattr(fd: c_int, optional_actions: c_int, termios_p: *const Termios) callconv(.c) c_int;
} else struct {};

const stdio_streams = if (is_windows) struct {
    inline fn getStdin() ?*FILE {
        return win_c.__acrt_iob_func(0);
    }
    inline fn getStdout() ?*FILE {
        return win_c.__acrt_iob_func(1);
    }
    inline fn getStderr() ?*FILE {
        return win_c.__acrt_iob_func(2);
    }
} else if (builtin.os.tag.isDarwin()) struct {
    extern "c" var __stdinp: ?*FILE;
    extern "c" var __stdoutp: ?*FILE;
    extern "c" var __stderrp: ?*FILE;
    inline fn getStdin() ?*FILE {
        return __stdinp;
    }
    inline fn getStdout() ?*FILE {
        return __stdoutp;
    }
    inline fn getStderr() ?*FILE {
        return __stderrp;
    }
} else struct {
    extern "c" var stdin: ?*FILE;
    extern "c" var stdout: ?*FILE;
    extern "c" var stderr: ?*FILE;
    inline fn getStdin() ?*FILE {
        return stdin;
    }
    inline fn getStdout() ?*FILE {
        return stdout;
    }
    inline fn getStderr() ?*FILE {
        return stderr;
    }
};

const O_RDONLY_VAL: c_int = if (is_windows) win_c.O_RDONLY else posix_c.O_RDONLY;
const O_WRONLY_VAL: c_int = if (is_windows) win_c.O_WRONLY else posix_c.O_WRONLY;
const O_RDWR_VAL: c_int = if (is_windows) win_c.O_RDWR else posix_c.O_RDWR;
const O_CREAT_VAL: c_int = if (is_windows) win_c.O_CREAT else posix_c.O_CREAT;
const O_EXCL_VAL: c_int = if (is_windows) win_c.O_EXCL else posix_c.O_EXCL;
const O_TRUNC_VAL: c_int = if (is_windows) win_c.O_TRUNC else posix_c.O_TRUNC;
const O_BINARY_VAL: c_int = if (is_windows) win_c.O_BINARY else posix_c.O_BINARY;

const EACCES_VAL: c_int = 13;
const EEXIST_VAL: c_int = 17;
const EBADF_VAL: c_int = 9;

inline fn getErrno() c_int {
    if (is_windows) {
        return win_c._errno().*;
    } else {
        return std.c._errno().*;
    }
}

inline fn setErrno(val: c_int) void {
    if (is_windows) {
        win_c._errno().* = val;
    } else {
        std.c._errno().* = val;
    }
}

fn toolFopen(filename: [*:0]const u8, mode: [*:0]const u8) ?*FILE {
    if (is_windows) {
        return win_c.curlx_win32_fopen(filename, mode);
    } else {
        return posix_c.fopen(filename, mode);
    }
}

fn toolFdopen(fd: c_int, mode: [*:0]const u8) ?*FILE {
    if (is_windows) {
        return win_c._fdopen(fd, mode);
    } else {
        return posix_c.fdopen(fd, mode);
    }
}

fn toolFileno(stream: ?*FILE) c_int {
    if (is_windows) {
        return win_c._fileno(stream);
    } else {
        return posix_c.fileno(stream);
    }
}

fn toolOpen(filename: [*:0]const u8, oflag: c_int, mode: c_int) c_int {
    if (is_windows) {
        return win_c.curlx_win32_open(filename, oflag, mode);
    } else {
        return posix_c.open(filename, oflag, @as(c_uint, @intCast(mode)));
    }
}

fn toolClose(fd: c_int) c_int {
    if (is_windows) {
        return win_c._close(fd);
    } else {
        return posix_c.close(fd);
    }
}

fn toolUnlink(filename: [*:0]const u8) c_int {
    if (is_windows) {
        return win_c._unlink(filename);
    } else {
        return posix_c.unlink(filename);
    }
}

fn toolFtruncate(fd: c_int, where: i64) c_int {
    if (is_windows) {
        return toolx_ftruncate_win32(fd, where);
    } else {
        return posix_c.ftruncate(fd, where);
    }
}

fn toolFtell(stream: ?*FILE) i64 {
    if (is_windows) {
        return win_c._ftelli64(stream);
    } else {
        return posix_c.ftello(stream);
    }
}

fn toolStat(path: [*:0]const u8, out: *ToolStat) c_int {
    if (is_windows) {
        var sbuf: win_c.Win32Stat64 = std.mem.zeroes(win_c.Win32Stat64);
        const rc = win_c.curlx_win32_stat(path, &sbuf);
        if (rc != 0) return -1;
        out.* = .{
            .is_reg = (sbuf.st_mode & 0xf000) == 0x8000,
            .is_dir = (sbuf.st_mode & 0xf000) == 0x4000,
            .is_chr = (sbuf.st_mode & 0xf000) == 0x2000,
            .size = sbuf.st_size,
            .mtime = sbuf.st_mtime,
        };
        return 0;
    } else if (builtin.os.tag == .linux) {
        var stx: std.os.linux.Statx = std.mem.zeroes(std.os.linux.Statx);
        const rc = std.os.linux.statx(
            std.os.linux.AT.FDCWD,
            path,
            0,
            std.os.linux.STATX.BASIC_STATS,
            &stx,
        );
        const err = std.os.linux.errno(rc);
        if (err != .SUCCESS) {
            setErrno(@intCast(@backingInt(err)));
            return -1;
        }
        out.* = .{
            .is_reg = (stx.mode & std.os.linux.S.IFMT) == std.os.linux.S.IFREG,
            .is_dir = (stx.mode & std.os.linux.S.IFMT) == std.os.linux.S.IFDIR,
            .is_chr = (stx.mode & std.os.linux.S.IFMT) == std.os.linux.S.IFCHR,
            .size = @intCast(stx.size),
            .mtime = stx.mtime.sec,
        };
        return 0;
    } else {
        var st: std.c.Stat = std.mem.zeroes(std.c.Stat);
        if (std.c.stat(path, &st) != 0) return -1;
        out.* = .{
            .is_reg = (st.mode & std.c.S.IFMT) == std.c.S.IFREG,
            .is_dir = (st.mode & std.c.S.IFMT) == std.c.S.IFDIR,
            .is_chr = (st.mode & std.c.S.IFMT) == std.c.S.IFCHR,
            .size = @intCast(st.size),
            .mtime = st.mtime().sec,
        };
        return 0;
    }
}

fn toolFstat(fd: c_int, out: *ToolStat) c_int {
    if (fd < 0) {
        setErrno(EBADF_VAL);
        return -1;
    }
    if (is_windows) {
        var sbuf: win_c.Win32Stat64 = std.mem.zeroes(win_c.Win32Stat64);
        if (win_c._fstati64(fd, &sbuf) != 0) return -1;
        out.* = .{
            .is_reg = (sbuf.st_mode & 0xf000) == 0x8000,
            .is_dir = (sbuf.st_mode & 0xf000) == 0x4000,
            .is_chr = (sbuf.st_mode & 0xf000) == 0x2000,
            .size = sbuf.st_size,
            .mtime = sbuf.st_mtime,
        };
        return 0;
    } else if (builtin.os.tag == .linux) {
        var stx: std.os.linux.Statx = std.mem.zeroes(std.os.linux.Statx);
        const rc = std.os.linux.statx(
            fd,
            "",
            std.os.linux.AT.EMPTY_PATH,
            std.os.linux.STATX.BASIC_STATS,
            &stx,
        );
        const err = std.os.linux.errno(rc);
        if (err != .SUCCESS) {
            setErrno(@intCast(@backingInt(err)));
            return -1;
        }
        out.* = .{
            .is_reg = (stx.mode & std.os.linux.S.IFMT) == std.os.linux.S.IFREG,
            .is_dir = (stx.mode & std.os.linux.S.IFMT) == std.os.linux.S.IFDIR,
            .is_chr = (stx.mode & std.os.linux.S.IFMT) == std.os.linux.S.IFCHR,
            .size = @intCast(stx.size),
            .mtime = stx.mtime.sec,
        };
        return 0;
    } else {
        var st: std.c.Stat = std.mem.zeroes(std.c.Stat);
        if (std.c.fstat(fd, &st) != 0) return -1;
        out.* = .{
            .is_reg = (st.mode & std.c.S.IFMT) == std.c.S.IFREG,
            .is_dir = (st.mode & std.c.S.IFMT) == std.c.S.IFDIR,
            .is_chr = (st.mode & std.c.S.IFMT) == std.c.S.IFCHR,
            .size = @intCast(st.size),
            .mtime = st.mtime().sec,
        };
        return 0;
    }
}

fn cStrdup(s: [*:0]const u8) ?[*:0]u8 {
    return Curl_cstrdup(s);
}

inline fn safeFreePtr(comptime T: type, ptr: *?T) void {
    if (ptr.*) |p| {
        Curl_cfree(@ptrCast(p));
        ptr.* = null;
    }
}

inline fn checkPrefix(prefix: []const u8, s: [*:0]const u8) bool {
    return curl_strnequal(s, prefix.ptr, prefix.len) != 0;
}

inline fn isAlpha(ch: u8) bool {
    return (ch >= 'a' and ch <= 'z') or (ch >= 'A' and ch <= 'Z');
}

inline fn isDigit(ch: u8) bool {
    return ch >= '0' and ch <= '9';
}

inline fn isAlnum(ch: u8) bool {
    return isDigit(ch) or isAlpha(ch);
}

// ============================================================================
// Global State Storage
// ============================================================================

var global_storage: GlobalConfig = std.mem.zeroes(GlobalConfig);
pub export var transfers: ?*per_transfer = null;
var transfers_l: ?*per_transfer = null;

pub const _CRT_glob: c_int = 0;
comptime {
    if (is_windows and builtin.abi == .gnu) {
        @export(&_CRT_glob, .{ .name = "_CRT_glob" });
    }
}

// ============================================================================
// Variadic C shims (notef, warnf, helpf, errorf, easysrc_addf)
// ============================================================================

const use_c_vastart = switch (builtin.cpu.arch) {
    .x86_64 => builtin.os.tag != .windows,
    .aarch64 => builtin.os.tag.isDarwin() or builtin.os.tag == .windows,
    .x86, .arm, .riscv64, .powerpc64le, .s390x => true,
    else => false,
};

const CVaListParam = switch (builtin.cpu.arch) {
    .x86_64 => if (builtin.os.tag == .windows) [*]u8 else *std.builtin.VaListX86_64,
    .aarch64, .aarch64_be => switch (builtin.os.tag) {
        .macos, .ios, .tvos, .watchos, .visionos, .driverkit, .maccatalyst, .windows => [*]u8,
        else => std.builtin.VaListAarch64,
    },
    else => *anyopaque,
};

pub export fn notef_va(fmt: [*:0]const u8, ap: CVaListParam) callconv(.c) void {
    if (global) |g| {
        if (g.tracetype != TRACE_NONE and !g.silent) {
            if (curl_mvaprintf(fmt, ap)) |msg| {
                tool_voutf_zig(global, "Note: ", msg);
                curl_free(msg);
            }
        }
    }
}

pub export fn warnf_va(fmt: [*:0]const u8, ap: CVaListParam) callconv(.c) void {
    if (global == null or !global.?.silent) {
        if (curl_mvaprintf(fmt, ap)) |msg| {
            tool_voutf_zig(global, "Warning: ", msg);
            curl_free(msg);
        }
    }
}

pub export fn helpf_va(fmt: ?[*:0]const u8, ap: CVaListParam) callconv(.c) void {
    var msg: ?[*:0]u8 = null;
    if (fmt) |f| {
        msg = curl_mvaprintf(f, ap);
    }
    tool_helpf_zig(msg);
    curl_free(msg);
}

pub export fn errorf_va(fmt: [*:0]const u8, ap: CVaListParam) callconv(.c) void {
    if (global == null or !global.?.silent or global.?.showerror) {
        if (curl_mvaprintf(fmt, ap)) |msg| {
            tool_voutf_zig(global, "curl: ", msg);
            curl_free(msg);
        }
    }
}

pub export fn easysrc_addf_va(plist: *?*slist_wc, fmt: [*:0]const u8, ap: CVaListParam) callconv(.c) CURLcode {
    const bufp = curl_mvaprintf(fmt, ap);
    return Curl_zig_easysrc_add_formatted(plist, bufp);
}

const variadic_impl = struct {
    pub const notef = if (use_c_vastart)
        struct {
            pub fn f(fmt: [*:0]const u8, ...) callconv(.c) void {
                var ap = @cVaStart();
                defer @cVaEnd(&ap);
                const param: CVaListParam = if (builtin.cpu.arch == .x86_64) &ap else @ptrCast(ap);
                notef_va(fmt, param);
            }
        }.f
    else switch (builtin.cpu.arch) {
        .x86_64 => struct {
            pub fn f() callconv(.naked) void {
                asm volatile (
                    \\movq %%rdx, 16(%%rsp)
                    \\movq %%r8, 24(%%rsp)
                    \\movq %%r9, 32(%%rsp)
                    \\leaq 16(%%rsp), %%rdx
                    \\jmp notef_va
                );
            }
        }.f,
        .aarch64 => struct {
            pub fn f() callconv(.naked) void {
                asm volatile (
                    \\sub sp, sp, #256
                    \\stp x29, x30, [sp, #240]
                    \\add x29, sp, #240
                    \\stp x1, x2, [x29, #-56]
                    \\stp x3, x4, [x29, #-40]
                    \\stp x5, x6, [x29, #-24]
                    \\str x7, [x29, #-8]
                    \\stp q0, q1, [sp, #32]
                    \\stp q2, q3, [sp, #64]
                    \\stp q4, q5, [sp, #96]
                    \\stp q6, q7, [sp, #128]
                    \\add x8, x29, #16
                    \\str x8, [sp, #0]
                    \\sub x8, x29, #0
                    \\str x8, [sp, #8]
                    \\add x8, sp, #160
                    \\str x8, [sp, #16]
                    \\mov w8, #-56
                    \\str w8, [sp, #24]
                    \\mov w8, #-128
                    \\str w8, [sp, #28]
                    \\mov x1, sp
                    \\bl notef_va
                    \\ldp x29, x30, [sp, #240]
                    \\add sp, sp, #256
                    \\ret
                );
            }
        }.f,
        else => @compileError("unsupported variadic forwarding target"),
    };

    pub const warnf = if (use_c_vastart)
        struct {
            pub fn f(fmt: [*:0]const u8, ...) callconv(.c) void {
                var ap = @cVaStart();
                defer @cVaEnd(&ap);
                const param: CVaListParam = if (builtin.cpu.arch == .x86_64) &ap else @ptrCast(ap);
                warnf_va(fmt, param);
            }
        }.f
    else switch (builtin.cpu.arch) {
        .x86_64 => struct {
            pub fn f() callconv(.naked) void {
                asm volatile (
                    \\movq %%rdx, 16(%%rsp)
                    \\movq %%r8, 24(%%rsp)
                    \\movq %%r9, 32(%%rsp)
                    \\leaq 16(%%rsp), %%rdx
                    \\jmp warnf_va
                );
            }
        }.f,
        .aarch64 => struct {
            pub fn f() callconv(.naked) void {
                asm volatile (
                    \\sub sp, sp, #256
                    \\stp x29, x30, [sp, #240]
                    \\add x29, sp, #240
                    \\stp x1, x2, [x29, #-56]
                    \\stp x3, x4, [x29, #-40]
                    \\stp x5, x6, [x29, #-24]
                    \\str x7, [x29, #-8]
                    \\stp q0, q1, [sp, #32]
                    \\stp q2, q3, [sp, #64]
                    \\stp q4, q5, [sp, #96]
                    \\stp q6, q7, [sp, #128]
                    \\add x8, x29, #16
                    \\str x8, [sp, #0]
                    \\sub x8, x29, #0
                    \\str x8, [sp, #8]
                    \\add x8, sp, #160
                    \\str x8, [sp, #16]
                    \\mov w8, #-56
                    \\str w8, [sp, #24]
                    \\mov w8, #-128
                    \\str w8, [sp, #28]
                    \\mov x1, sp
                    \\bl warnf_va
                    \\ldp x29, x30, [sp, #240]
                    \\add sp, sp, #256
                    \\ret
                );
            }
        }.f,
        else => @compileError("unsupported variadic forwarding target"),
    };

    pub const helpf = if (use_c_vastart)
        struct {
            pub fn f(fmt: ?[*:0]const u8, ...) callconv(.c) void {
                var ap = @cVaStart();
                defer @cVaEnd(&ap);
                const param: CVaListParam = if (builtin.cpu.arch == .x86_64) &ap else @ptrCast(ap);
                helpf_va(fmt, param);
            }
        }.f
    else switch (builtin.cpu.arch) {
        .x86_64 => struct {
            pub fn f() callconv(.naked) void {
                asm volatile (
                    \\movq %%rdx, 16(%%rsp)
                    \\movq %%r8, 24(%%rsp)
                    \\movq %%r9, 32(%%rsp)
                    \\leaq 16(%%rsp), %%rdx
                    \\jmp helpf_va
                );
            }
        }.f,
        .aarch64 => struct {
            pub fn f() callconv(.naked) void {
                asm volatile (
                    \\sub sp, sp, #256
                    \\stp x29, x30, [sp, #240]
                    \\add x29, sp, #240
                    \\stp x1, x2, [x29, #-56]
                    \\stp x3, x4, [x29, #-40]
                    \\stp x5, x6, [x29, #-24]
                    \\str x7, [x29, #-8]
                    \\stp q0, q1, [sp, #32]
                    \\stp q2, q3, [sp, #64]
                    \\stp q4, q5, [sp, #96]
                    \\stp q6, q7, [sp, #128]
                    \\add x8, x29, #16
                    \\str x8, [sp, #0]
                    \\sub x8, x29, #0
                    \\str x8, [sp, #8]
                    \\add x8, sp, #160
                    \\str x8, [sp, #16]
                    \\mov w8, #-56
                    \\str w8, [sp, #24]
                    \\mov w8, #-128
                    \\str w8, [sp, #28]
                    \\mov x1, sp
                    \\bl helpf_va
                    \\ldp x29, x30, [sp, #240]
                    \\add sp, sp, #256
                    \\ret
                );
            }
        }.f,
        else => @compileError("unsupported variadic forwarding target"),
    };

    pub const errorf = if (use_c_vastart)
        struct {
            pub fn f(fmt: [*:0]const u8, ...) callconv(.c) void {
                var ap = @cVaStart();
                defer @cVaEnd(&ap);
                const param: CVaListParam = if (builtin.cpu.arch == .x86_64) &ap else @ptrCast(ap);
                errorf_va(fmt, param);
            }
        }.f
    else switch (builtin.cpu.arch) {
        .x86_64 => struct {
            pub fn f() callconv(.naked) void {
                asm volatile (
                    \\movq %%rdx, 16(%%rsp)
                    \\movq %%r8, 24(%%rsp)
                    \\movq %%r9, 32(%%rsp)
                    \\leaq 16(%%rsp), %%rdx
                    \\jmp errorf_va
                );
            }
        }.f,
        .aarch64 => struct {
            pub fn f() callconv(.naked) void {
                asm volatile (
                    \\sub sp, sp, #256
                    \\stp x29, x30, [sp, #240]
                    \\add x29, sp, #240
                    \\stp x1, x2, [x29, #-56]
                    \\stp x3, x4, [x29, #-40]
                    \\stp x5, x6, [x29, #-24]
                    \\str x7, [x29, #-8]
                    \\stp q0, q1, [sp, #32]
                    \\stp q2, q3, [sp, #64]
                    \\stp q4, q5, [sp, #96]
                    \\stp q6, q7, [sp, #128]
                    \\add x8, x29, #16
                    \\str x8, [sp, #0]
                    \\sub x8, x29, #0
                    \\str x8, [sp, #8]
                    \\add x8, sp, #160
                    \\str x8, [sp, #16]
                    \\mov w8, #-56
                    \\str w8, [sp, #24]
                    \\mov w8, #-128
                    \\str w8, [sp, #28]
                    \\mov x1, sp
                    \\bl errorf_va
                    \\ldp x29, x30, [sp, #240]
                    \\add sp, sp, #256
                    \\ret
                );
            }
        }.f,
        else => @compileError("unsupported variadic forwarding target"),
    };

    pub const easysrc_addf = if (use_c_vastart)
        struct {
            pub fn f(plist: *?*slist_wc, fmt: [*:0]const u8, ...) callconv(.c) CURLcode {
                var ap = @cVaStart();
                defer @cVaEnd(&ap);
                const param: CVaListParam = if (builtin.cpu.arch == .x86_64) &ap else @ptrCast(ap);
                return easysrc_addf_va(plist, fmt, param);
            }
        }.f
    else switch (builtin.cpu.arch) {
        .x86_64 => struct {
            pub fn f() callconv(.naked) void {
                asm volatile (
                    \\movq %%r8, 24(%%rsp)
                    \\movq %%r9, 32(%%rsp)
                    \\leaq 24(%%rsp), %%r8
                    \\jmp easysrc_addf_va
                );
            }
        }.f,
        .aarch64 => struct {
            pub fn f() callconv(.naked) void {
                asm volatile (
                    \\sub sp, sp, #256
                    \\stp x29, x30, [sp, #240]
                    \\add x29, sp, #240
                    \\stp x2, x3, [x29, #-48]
                    \\stp x4, x5, [x29, #-32]
                    \\stp x6, x7, [x29, #-16]
                    \\stp q0, q1, [sp, #32]
                    \\stp q2, q3, [sp, #64]
                    \\stp q4, q5, [sp, #96]
                    \\stp q6, q7, [sp, #128]
                    \\add x8, x29, #16
                    \\str x8, [sp, #0]
                    \\sub x8, x29, #0
                    \\str x8, [sp, #8]
                    \\add x8, sp, #160
                    \\str x8, [sp, #16]
                    \\mov w8, #-48
                    \\str w8, [sp, #24]
                    \\mov w8, #-128
                    \\str w8, [sp, #28]
                    \\mov x2, sp
                    \\bl easysrc_addf_va
                    \\ldp x29, x30, [sp, #240]
                    \\add sp, sp, #256
                    \\ret
                );
            }
        }.f,
        else => @compileError("unsupported variadic forwarding target"),
    };
};

comptime {
    @export(&variadic_impl.notef, .{ .name = "notef", .linkage = .strong });
    @export(&variadic_impl.warnf, .{ .name = "warnf", .linkage = .strong });
    @export(&variadic_impl.helpf, .{ .name = "helpf", .linkage = .strong });
    @export(&variadic_impl.errorf, .{ .name = "errorf", .linkage = .strong });
    @export(&variadic_impl.easysrc_addf, .{ .name = "easysrc_addf", .linkage = .strong });
}

extern fn notef(fmt: [*:0]const u8, ...) callconv(.c) void;
extern fn warnf(fmt: [*:0]const u8, ...) callconv(.c) void;
extern fn helpf(fmt: ?[*:0]const u8, ...) callconv(.c) void;
extern fn errorf(fmt: [*:0]const u8, ...) callconv(.c) void;
extern fn easysrc_addf(plist: *?*slist_wc, fmt: [*:0]const u8, ...) callconv(.c) CURLcode;

// ============================================================================
// Part 2: src/tool_main.c
// ============================================================================

fn main_checkfds() void {
    if (!is_windows) {
        var fd: [2]c_int = .{ 0, 0 };
        var st: ToolStat = undefined;
        while (toolFstat(fd[0], &st) == -1 and getErrno() == EBADF_VAL) {
            if (posix_c.pipe(&fd) < 0) return;
        }
        while (toolFstat(fd[1], &st) == -1 and getErrno() == EBADF_VAL) {
            if (posix_c.pipe(&fd) < 0) return;
        }
        if (fd[0] > 2) _ = posix_c.close(fd[0]);
        if (fd[1] > 2) _ = posix_c.close(fd[1]);
    }
}

pub fn main(argc: c_int, argv: [*]?[*:0]u8) callconv(.c) c_int {
    var result: CURLcode = CURLE_OK;

    tool_init_stderr();

    if (is_windows) {
        if (argc == 2 and argv[1] != null and std.mem.orderZ(u8, argv[1].?, "--dump-module-paths") == .eq) {
            return 0;
        }
    }

    main_checkfds();

    const sigpipe_Mask = if (!is_windows) struct {
        const SIGPIPE: c_int = 13;
        const SIG_IGN_PTR: ?*const anyopaque = @ptrFromInt(1);
        extern "c" fn signal(sig: c_int, func: ?*const anyopaque) callconv(.c) ?*const anyopaque;
    } else struct {};

    var orig_sigpipe: ?*const anyopaque = null;
    if (!is_windows) {
        orig_sigpipe = sigpipe_Mask.signal(sigpipe_Mask.SIGPIPE, sigpipe_Mask.SIG_IGN_PTR);
    }

    result = globalconf_init();
    if (result == CURLE_OK) {
        result = operate(argc, argv);
        globalconf_free();
    }

    if (!is_windows) {
        _ = sigpipe_Mask.signal(sigpipe_Mask.SIGPIPE, orig_sigpipe);
    }

    if (is_windows) {
        _ = fflush(stdio_streams.getStdout());
        _ = fflush(stdio_streams.getStderr());
        _ = fflush(tool_stderr);
    }

    return @intCast(result);
}

pub export fn tool_zig_get_variables() callconv(.c) ?*tool_var {
    return if (global) |g| g.variables else null;
}

pub export fn tool_zig_set_variables(v: ?*tool_var) callconv(.c) void {
    if (global) |g| {
        g.variables = v;
    }
}

pub export fn tool_zig_get_global_last() callconv(.c) ?*OperationConfig {
    return if (global) |g| g.last else null;
}

pub export fn tool_zig_next_operation(configp: *?*OperationConfig) callconv(.c) bool {
    const config = configp.* orelse return false;
    if (config.url_list != null and config.url_list.?.url != null) {
        config.next = config_alloc();
        if (config.next) |next| {
            if (global) |g| {
                g.last = next;
            }
            next.prev = config;
            configp.* = next;
        } else {
            return false;
        }
    }
    return true;
}

pub export fn tool_zig_stdin() callconv(.c) ?*FILE {
    return stdio_streams.getStdin();
}

pub export fn tool_zig_get_errno() callconv(.c) c_int {
    return getErrno();
}

pub export fn tool_zig_errno_is_acces_or_exist() callconv(.c) bool {
    const e = getErrno();
    return e == EACCES_VAL or e == EEXIST_VAL;
}

pub export fn tool_zig_show_dir_errno(name: [*:0]const u8) callconv(.c) void {
    const e = getErrno();
    const ENAMETOOLONG_VAL: c_int = if (is_windows) 38 else if (builtin.os.tag.isDarwin()) 63 else 36;
    const EROFS_VAL: c_int = 30;
    const ENOSPC_VAL: c_int = 28;
    const EDQUOT_VAL: c_int = if (builtin.os.tag.isDarwin()) 69 else 122;
    if (e == EACCES_VAL) {
        errorf("You do not have permission to create %s", name);
    } else if (e == ENAMETOOLONG_VAL) {
        errorf("The directory name %s is too long", name);
    } else if (!is_windows and e == EROFS_VAL) {
        errorf("%s resides on a read-only file system", name);
    } else if (e == ENOSPC_VAL) {
        errorf("No space left on the file system that would contain the directory %s", name);
    } else if (!is_windows and e == EDQUOT_VAL) {
        errorf("Cannot create directory %s because you exceeded your quota", name);
    } else {
        errorf("Error creating directory %s", name);
    }
}

pub export fn tool_zig_stat_mtime(filename: [*:0]const u8, stamp: *i64) callconv(.c) c_int {
    var st: ToolStat = undefined;
    if (toolStat(filename, &st) == -1) return -1;
    stamp.* = st.mtime;
    return 0;
}

pub export fn tool_zig_get_pw_dir() callconv(.c) ?[*:0]const u8 {
    if (!is_windows) {
        const pw_raw = posix_c.getpwuid(posix_c.geteuid()) orelse return null;
        if (builtin.os.tag.isDarwin()) {
            const pw: *posix_c.passwd_darwin = @ptrCast(@alignCast(pw_raw));
            if (pw.pw_dir) |d| {
                if (d[0] != 0) return d;
            }
        } else {
            const pw: *posix_c.passwd = @ptrCast(@alignCast(pw_raw));
            if (pw.pw_dir) |d| {
                if (d[0] != 0) return d;
            }
        }
    }
    return null;
}

pub export fn tool_zig_errorf_0(msg: [*:0]const u8) callconv(.c) void {
    errorf("%s", msg);
}
pub export fn tool_zig_errorf_s(fmt: [*:0]const u8, s: [*:0]const u8) callconv(.c) void {
    errorf(fmt, s);
}
pub export fn tool_zig_errorf_ss(fmt: [*:0]const u8, s1: [*:0]const u8, s2: [*:0]const u8) callconv(.c) void {
    errorf(fmt, s1, s2);
}
pub export fn tool_zig_errorf_ns(fmt: [*:0]const u8, n: c_int, s: [*:0]const u8) callconv(.c) void {
    errorf(fmt, n, s);
}
pub export fn tool_zig_errorf_d(fmt: [*:0]const u8, d: c_int) callconv(.c) void {
    errorf(fmt, d);
}
pub export fn tool_zig_errorf_lx(fmt: [*:0]const u8, lx: c_ulong) callconv(.c) void {
    errorf(fmt, lx);
}
pub export fn tool_zig_errorf_cfg(display: [*:0]const u8, lineno: c_int, option: [*:0]const u8, reason: [*:0]const u8) callconv(.c) void {
    errorf("%s:%d config file option '%s' %s", display, lineno, option, reason);
}

pub export fn tool_zig_warnf_0(msg: [*:0]const u8) callconv(.c) void {
    warnf("%s", msg);
}
pub export fn tool_zig_warnf_s(fmt: [*:0]const u8, s: [*:0]const u8) callconv(.c) void {
    warnf(fmt, s);
}
pub export fn tool_zig_warnf_zu(fmt: [*:0]const u8, n: usize) callconv(.c) void {
    warnf(fmt, n);
}
pub export fn tool_zig_warnf_lx(fmt: [*:0]const u8, lx: c_ulong) callconv(.c) void {
    warnf(fmt, lx);
}
pub export fn tool_zig_warnf_off_lx(fmt: [*:0]const u8, off: curl_off_t, lx: c_ulong) callconv(.c) void {
    warnf(fmt, off, lx);
}
pub export fn tool_zig_warnf_off_ss(fmt: [*:0]const u8, off: curl_off_t, s1: [*:0]const u8, s2: [*:0]const u8) callconv(.c) void {
    warnf(fmt, off, s1, s2);
}
pub export fn tool_zig_warnf_cfg(fmt: [*:0]const u8, filename: [*:0]const u8, lineno: c_int, option: [*:0]const u8) callconv(.c) void {
    warnf(fmt, filename, lineno, option);
}

pub export fn tool_zig_notef_s(fmt: [*:0]const u8, s: [*:0]const u8) callconv(.c) void {
    notef(fmt, s);
}

pub export fn tool_zig_has_ares() callconv(.c) bool {
    return curlinfo != null and curlinfo.?.ares_num != 0;
}

pub export fn tool_zig_existingfile(filename: [*:0]const u8) callconv(.c) bool {
    var info: ToolStat = undefined;
    return toolStat(filename, &info) == 0;
}

pub export fn tool_zig_stdin_binmode() callconv(.c) void {
    if (is_windows) {
        _ = win_c._setmode(win_c._fileno(stdio_streams.getStdin()), win_c.O_BINARY);
    }
}

pub export fn tool_zig_set_config_cacert(config: *OperationConfig, cacert: ?[*:0]u8) callconv(.c) void {
    Curl_cfree(config.cacert);
    config.cacert = cacert;
}

pub export fn tool_zig_config_get_postdata(config: *OperationConfig) callconv(.c) *Dynbuf {
    return &config.postdata;
}

pub export fn tool_zig_config_str_ptr(config: *OperationConfig, id: c_int) callconv(.c) *?[*:0]u8 {
    return switch (id) {
        0 => &config.altsvc,
        1 => &config.aws_sigv4,
        2 => &config.cacert,
        3 => &config.capath,
        4 => &config.cert,
        5 => &config.cert_type,
        6 => &config.cipher13_list,
        7 => &config.cipher_list,
        8 => &config.cookiejar,
        9 => &config.crlfile,
        10 => &config.customrequest,
        11 => &config.dns_interface,
        12 => &config.dns_ipv4_addr,
        13 => &config.dns_ipv6_addr,
        14 => &config.dns_servers,
        15 => &config.doh_url,
        16 => &config.ech,
        17 => &config.ech_config,
        18 => &config.ech_public,
        19 => &config.engine,
        20 => &config.etag_compare_file,
        21 => &config.etag_save_file,
        22 => &config.ftp_account,
        23 => &config.ftp_alternative_to_user,
        24 => &config.ftpport,
        25 => &config.haproxy_clientip,
        26 => &config.headerfile,
        27 => &config.hostpubmd5,
        28 => &config.hostpubsha256,
        29 => &config.hsts,
        30 => &config.httpsig_algorithm,
        31 => &config.httpsig_headers,
        32 => &config.httpsig_key,
        33 => &config.httpsig_keyid,
        34 => &config.iface,
        35 => &config.ipfs_gateway,
        36 => &config.key,
        37 => &config.key_passwd,
        38 => &config.key_type,
        39 => &config.knownhosts,
        40 => &config.login_options,
        41 => &config.mail_auth,
        42 => &config.mail_from,
        43 => &config.netrc_file,
        44 => &config.noproxy,
        45 => &config.oauth_bearer,
        46 => &config.output_dir,
        47 => &config.pinnedpubkey,
        48 => &config.postfields,
        49 => &config.preproxy,
        50 => &config.proto_default,
        51 => &config.proto_redir_str,
        52 => &config.proto_str,
        53 => &config.proxy,
        54 => &config.proxy_cacert,
        55 => &config.proxy_capath,
        56 => &config.proxy_cert,
        57 => &config.proxy_cert_type,
        58 => &config.proxy_cipher13_list,
        59 => &config.proxy_cipher_list,
        60 => &config.proxy_crlfile,
        61 => &config.proxy_key,
        62 => &config.proxy_key_passwd,
        63 => &config.proxy_key_type,
        64 => &config.proxy_pinnedpubkey,
        65 => &config.proxy_service_name,
        66 => &config.proxyuserpwd,
        67 => &config.pubkey,
        68 => &config.query,
        69 => &config.range,
        70 => &config.referer,
        71 => &config.request_target,
        72 => &config.sasl_authzid,
        73 => &config.service_name,
        74 => &config.ssl_ec_curves,
        75 => &config.ssl_signature_algorithms,
        76 => &config.unix_socket_path,
        77 => &config.useragent,
        78 => &config.userpwd,
        79 => &config.writeout,
        else => &config.useragent,
    };
}

pub export fn tool_zig_config_slist_ptr(config: *OperationConfig, id: c_int) callconv(.c) *?*curl_slist {
    return switch (id) {
        0 => &config.connect_to,
        1 => &config.cookiefiles,
        2 => &config.cookies,
        3 => &config.headers,
        4 => &config.mail_rcpt,
        5 => &config.postquote,
        6 => &config.prequote,
        7 => &config.proxyheaders,
        8 => &config.quote,
        9 => &config.resolve,
        10 => &config.telnet_options,
        else => &config.headers,
    };
}

pub export fn tool_zig_config_get_bit(config: *const OperationConfig, id: c_int) callconv(.c) bool {
    return switch (id) {
        0 => config.abstract_unix_socket,
        1 => config.autoreferer,
        2 => config.content_disposition,
        3 => config.cookiesession,
        4 => config.create_dirs,
        5 => config.crlf,
        6 => config.dirlistonly,
        7 => config.disable_eprt,
        8 => config.disable_epsv,
        9 => config.disable_sessionid,
        10 => config.disallow_username_in_url,
        11 => config.doh_insecure_ok,
        12 => config.doh_verifystatus,
        13 => config.encoding,
        14 => config.ftp_append,
        15 => config.ftp_create_dirs,
        16 => config.ftp_pret,
        17 => config.ftp_skip_ip,
        18 => config.ftp_ssl,
        19 => config.ftp_ssl_ccc,
        20 => config.ftp_ssl_control,
        21 => config.ftp_ssl_reqd,
        22 => config.globoff,
        23 => config.haproxy_protocol,
        24 => config.http09_allowed,
        25 => config.ignorecl,
        26 => config.insecure_ok,
        27 => config.jsoned,
        28 => config.mail_rcpt_allowfails,
        29 => config.mptcp,
        30 => config.native_ca_store,
        31 => config.netrc,
        32 => config.netrc_opt,
        33 => config.no_body,
        34 => config.noalpn,
        35 => config.nobuffer,
        36 => config.nokeepalive,
        37 => config.path_as_is,
        38 => config.post301,
        39 => config.post302,
        40 => config.post303,
        41 => config.proto_present,
        42 => config.proto_redir_present,
        43 => config.proxy_insecure_ok,
        44 => config.proxy_native_ca_store,
        45 => config.proxy_ssl_allow_beast,
        46 => config.proxy_ssl_auto_client_cert,
        47 => config.proxyanyauth,
        48 => config.proxybasic,
        49 => config.proxydigest,
        50 => config.proxynegotiate,
        51 => config.proxyntlm,
        52 => config.proxytunnel,
        53 => config.raw,
        54 => config.remote_name_all,
        55 => config.remote_time,
        56 => config.resume_from_current,
        57 => config.retry_all_errors,
        58 => config.retry_connrefused,
        59 => config.rm_partial,
        60 => config.sasl_ir,
        61 => config.show_headers,
        62 => config.skip_existing,
        63 => config.socks5_gssapi_nec,
        64 => config.ssh_compression,
        65 => config.ssl_allow_beast,
        66 => config.ssl_allow_earlydata,
        67 => config.ssl_auto_client_cert,
        68 => config.ssl_no_revoke,
        69 => config.ssl_revoke_best_effort,
        70 => config.suppress_connect_headers,
        71 => config.tcp_fastopen,
        72 => config.tcp_nodelay,
        73 => config.tftp_no_options,
        74 => config.tr_encoding,
        75 => config.unrestricted_auth,
        76 => config.use_ascii,
        77 => config.use_httpget,
        78 => config.use_resume,
        79 => config.verifystatus,
        80 => config.xattr,
        else => false,
    };
}

pub export fn tool_zig_config_set_bit(config: *OperationConfig, id: c_int, val: bool) callconv(.c) void {
    switch (id) {
        0 => config.abstract_unix_socket = val,
        1 => config.autoreferer = val,
        2 => config.content_disposition = val,
        3 => config.cookiesession = val,
        4 => config.create_dirs = val,
        5 => config.crlf = val,
        6 => config.dirlistonly = val,
        7 => config.disable_eprt = val,
        8 => config.disable_epsv = val,
        9 => config.disable_sessionid = val,
        10 => config.disallow_username_in_url = val,
        11 => config.doh_insecure_ok = val,
        12 => config.doh_verifystatus = val,
        13 => config.encoding = val,
        14 => config.ftp_append = val,
        15 => config.ftp_create_dirs = val,
        16 => config.ftp_pret = val,
        17 => config.ftp_skip_ip = val,
        18 => config.ftp_ssl = val,
        19 => config.ftp_ssl_ccc = val,
        20 => config.ftp_ssl_control = val,
        21 => config.ftp_ssl_reqd = val,
        22 => config.globoff = val,
        23 => config.haproxy_protocol = val,
        24 => config.http09_allowed = val,
        25 => config.ignorecl = val,
        26 => config.insecure_ok = val,
        27 => config.jsoned = val,
        28 => config.mail_rcpt_allowfails = val,
        29 => config.mptcp = val,
        30 => config.native_ca_store = val,
        31 => config.netrc = val,
        32 => config.netrc_opt = val,
        33 => config.no_body = val,
        34 => config.noalpn = val,
        35 => config.nobuffer = val,
        36 => config.nokeepalive = val,
        37 => config.path_as_is = val,
        38 => config.post301 = val,
        39 => config.post302 = val,
        40 => config.post303 = val,
        41 => config.proto_present = val,
        42 => config.proto_redir_present = val,
        43 => config.proxy_insecure_ok = val,
        44 => config.proxy_native_ca_store = val,
        45 => config.proxy_ssl_allow_beast = val,
        46 => config.proxy_ssl_auto_client_cert = val,
        47 => config.proxyanyauth = val,
        48 => config.proxybasic = val,
        49 => config.proxydigest = val,
        50 => config.proxynegotiate = val,
        51 => config.proxyntlm = val,
        52 => config.proxytunnel = val,
        53 => config.raw = val,
        54 => config.remote_name_all = val,
        55 => config.remote_time = val,
        56 => config.resume_from_current = val,
        57 => config.retry_all_errors = val,
        58 => config.retry_connrefused = val,
        59 => config.rm_partial = val,
        60 => config.sasl_ir = val,
        61 => config.show_headers = val,
        62 => config.skip_existing = val,
        63 => config.socks5_gssapi_nec = val,
        64 => config.ssh_compression = val,
        65 => config.ssl_allow_beast = val,
        66 => config.ssl_allow_earlydata = val,
        67 => config.ssl_auto_client_cert = val,
        68 => config.ssl_no_revoke = val,
        69 => config.ssl_revoke_best_effort = val,
        70 => config.suppress_connect_headers = val,
        71 => config.tcp_fastopen = val,
        72 => config.tcp_nodelay = val,
        73 => config.tftp_no_options = val,
        74 => config.tr_encoding = val,
        75 => config.unrestricted_auth = val,
        76 => config.use_ascii = val,
        77 => config.use_httpget = val,
        78 => config.use_resume = val,
        79 => config.verifystatus = val,
        80 => config.xattr = val,
        else => {},
    }
}

pub export fn tool_zig_config_get_int(config: *const OperationConfig, id: c_int) callconv(.c) i64 {
    return switch (id) {
        0 => @intCast(config.alivecnt),
        1 => @intCast(config.alivetime),
        2 => @intCast(config.authtype),
        3 => @intCast(config.condtime),
        4 => @intCast(config.connecttimeout_ms),
        5 => @intCast(config.create_file_mode),
        6 => @intCast(config.expect100timeout_ms),
        7 => @intCast(config.fail),
        8 => @intCast(config.file_clobber_mode),
        9 => @intCast(config.followlocation),
        10 => @intCast(config.ftp_filemethod),
        11 => @intCast(config.ftp_ssl_ccc_mode),
        12 => @intCast(config.gssapi_delegation),
        13 => @intCast(config.happy_eyeballs_timeout_ms),
        14 => @intCast(config.httpreq),
        15 => @intCast(config.httpversion),
        16 => @intCast(config.ip_tos),
        17 => @intCast(config.ip_version),
        18 => @intCast(config.localport),
        19 => @intCast(config.localportrange),
        20 => @intCast(config.low_speed_limit),
        21 => @intCast(config.low_speed_time),
        22 => @intCast(config.max_filesize),
        23 => @intCast(config.maxredirs),
        24 => @intCast(config.mime_options),
        25 => @intCast(config.num_urls),
        26 => @intCast(config.proxy_ssl_version),
        27 => @intCast(config.proxyver),
        28 => @intCast(config.recvpersecond),
        29 => @intCast(config.req_retry),
        30 => @intCast(config.resume_from),
        31 => @intCast(config.retry_delay_ms),
        32 => @intCast(config.retry_maxtime_ms),
        33 => @intCast(config.sendpersecond),
        34 => @intCast(config.socks5_auth),
        35 => @intCast(config.ssl_version),
        36 => @intCast(config.ssl_version_max),
        37 => @intCast(config.tftp_blksize),
        38 => @intCast(config.timecond),
        39 => @intCast(config.timeout_ms),
        40 => @intCast(config.upload_flags),
        41 => @intCast(config.vlan_priority),
        else => 0,
    };
}

pub export fn tool_zig_config_set_int(config: *OperationConfig, id: c_int, val: i64) callconv(.c) void {
    switch (id) {
        0 => config.alivecnt = @intCast(val),
        1 => config.alivetime = @intCast(val),
        2 => config.authtype = @intCast(val),
        3 => config.condtime = @intCast(val),
        4 => config.connecttimeout_ms = @intCast(val),
        5 => config.create_file_mode = @intCast(val),
        6 => config.expect100timeout_ms = @intCast(val),
        7 => config.fail = @intCast(val),
        8 => config.file_clobber_mode = @intCast(val),
        9 => config.followlocation = @intCast(val),
        10 => config.ftp_filemethod = @intCast(val),
        11 => config.ftp_ssl_ccc_mode = @intCast(val),
        12 => config.gssapi_delegation = @intCast(val),
        13 => config.happy_eyeballs_timeout_ms = @intCast(val),
        14 => config.httpreq = @intCast(val),
        15 => config.httpversion = @intCast(val),
        16 => config.ip_tos = @intCast(val),
        17 => config.ip_version = @intCast(val),
        18 => config.localport = @intCast(val),
        19 => config.localportrange = @intCast(val),
        20 => config.low_speed_limit = @intCast(val),
        21 => config.low_speed_time = @intCast(val),
        22 => config.max_filesize = @intCast(val),
        23 => config.maxredirs = @intCast(val),
        24 => config.mime_options = @intCast(val),
        25 => config.num_urls = @intCast(val),
        26 => config.proxy_ssl_version = @intCast(val),
        27 => config.proxyver = @intCast(val),
        28 => config.recvpersecond = @intCast(val),
        29 => config.req_retry = @intCast(val),
        30 => config.resume_from = @intCast(val),
        31 => config.retry_delay_ms = @intCast(val),
        32 => config.retry_maxtime_ms = @intCast(val),
        33 => config.sendpersecond = @intCast(val),
        34 => config.socks5_auth = @intCast(val),
        35 => config.ssl_version = @intCast(val),
        36 => config.ssl_version_max = @intCast(val),
        37 => config.tftp_blksize = @intCast(val),
        38 => config.timecond = @intCast(val),
        39 => config.timeout_ms = @intCast(val),
        40 => config.upload_flags = @intCast(val),
        41 => config.vlan_priority = @intCast(val),
        else => {},
    }
}

pub export fn tool_zig_config_getout_ptr(config: *OperationConfig, id: c_int) callconv(.c) *?*getout {
    return switch (id) {
        0 => &config.url_get,
        1 => &config.url_list,
        2 => &config.url_out,
        3 => &config.url_ul,
        else => &config.url_list,
    };
}

pub export fn tool_zig_config_httpreq_ptr(config: *OperationConfig) callconv(.c) *HttpReq {
    return &config.httpreq;
}

pub export fn tool_zig_config_mimeroot_ptr(config: *OperationConfig) callconv(.c) *?*tool_mime {
    return &config.mimeroot;
}

pub export fn tool_zig_config_mimecurrent_ptr(config: *OperationConfig) callconv(.c) *?*tool_mime {
    return &config.mimecurrent;
}

pub export fn tool_zig_config_postdata_ptr(config: *OperationConfig) callconv(.c) *Dynbuf {
    return &config.postdata;
}

pub export fn tool_zig_config_alloc_next(config: *OperationConfig) callconv(.c) ?*OperationConfig {
    config.next = config_alloc();
    if (config.next) |next| {
        next.prev = config;
        if (global) |g| {
            g.last = next;
        }
        return next;
    }
    return null;
}

pub export fn tool_zig_global_first() callconv(.c) ?*OperationConfig {
    return if (global) |g| g.first else null;
}

pub export fn tool_zig_global_str_ptr(id: c_int) callconv(.c) *?[*:0]u8 {
    const g = global.?;
    return switch (id) {
        0 => &g.libcurl,
        1 => &g.ssl_sessions,
        2 => &g.trace_dump,
        else => &g.libcurl,
    };
}

pub export fn tool_zig_global_get_bit(id: c_int) callconv(.c) bool {
    const g = global orelse return false;
    return switch (id) {
        0 => g.fail_early,
        1 => g.noprogress,
        2 => g.parallel,
        3 => g.parallel_connect,
        4 => g.showerror,
        5 => g.silent,
        6 => g.styled_output,
        7 => g.trace_set,
        8 => g.traceids,
        9 => g.tracetime,
        else => false,
    };
}

pub export fn tool_zig_global_set_bit(id: c_int, val: bool) callconv(.c) void {
    const g = global orelse return;
    switch (id) {
        0 => g.fail_early = val,
        1 => g.noprogress = val,
        2 => g.parallel = val,
        3 => g.parallel_connect = val,
        4 => g.showerror = val,
        5 => g.silent = val,
        6 => g.styled_output = val,
        7 => g.trace_set = val,
        8 => g.traceids = val,
        9 => g.tracetime = val,
        else => {},
    }
}

pub export fn tool_zig_global_get_int(id: c_int) callconv(.c) i64 {
    const g = global orelse return 0;
    return switch (id) {
        0 => @intCast(g.ms_per_transfer),
        1 => @intCast(g.parallel_host),
        2 => @intCast(g.parallel_max),
        3 => @intCast(g.progressmode),
        4 => @intCast(g.tracetype),
        5 => @intCast(g.verbosity),
        else => 0,
    };
}

pub export fn tool_zig_global_set_int(id: c_int, val: i64) callconv(.c) void {
    const g = global orelse return;
    switch (id) {
        0 => g.ms_per_transfer = @intCast(val),
        1 => g.parallel_host = @intCast(val),
        2 => g.parallel_max = @intCast(val),
        3 => g.progressmode = @intCast(val),
        4 => g.tracetype = @intCast(val),
        5 => g.verbosity = @intCast(val),
        else => {},
    }
}

pub export fn tool_zig_getout_next(node: *const getout) callconv(.c) ?*getout {
    return node.next;
}

pub export fn tool_zig_getout_get_next(node: *const getout) callconv(.c) ?*getout {
    return node.next;
}

pub export fn tool_zig_getout_set_next(node: *getout, next: ?*getout) callconv(.c) void {
    node.next = next;
}

pub export fn tool_zig_getout_str_ptr(node: *getout, id: c_int) callconv(.c) *?[*:0]u8 {
    return switch (id) {
        0 => &node.infile,
        1 => &node.outfile,
        2 => &node.url,
        else => &node.url,
    };
}

pub export fn tool_zig_getout_get_bit(node: *const getout, id: c_int) callconv(.c) bool {
    return switch (id) {
        0 => node.noglob,
        1 => node.noupload,
        2 => node.out_null,
        3 => node.outset,
        4 => node.uploadset,
        5 => node.urlset,
        6 => node.useremote,
        else => false,
    };
}

pub export fn tool_zig_getout_set_bit(node: *getout, id: c_int, val: bool) callconv(.c) void {
    switch (id) {
        0 => node.noglob = val,
        1 => node.noupload = val,
        2 => node.out_null = val,
        3 => node.outset = val,
        4 => node.uploadset = val,
        5 => node.urlset = val,
        6 => node.useremote = val,
        else => {},
    }
}

pub export fn tool_zig_easysrc_add(plist: *?*slist_wc, line: [*:0]const u8) callconv(.c) CURLcode {
    return easysrc_add(plist, line);
}
pub export fn tool_zig_easysrc_addf_s(plist: *?*slist_wc, fmt: [*:0]const u8, s: [*:0]const u8) callconv(.c) CURLcode {
    return easysrc_addf(plist, fmt, s);
}
pub export fn tool_zig_easysrc_addf_ss(plist: *?*slist_wc, fmt: [*:0]const u8, s1: [*:0]const u8, s2: [*:0]const u8) callconv(.c) CURLcode {
    return easysrc_addf(plist, fmt, s1, s2);
}
pub export fn tool_zig_easysrc_addf_sd(plist: *?*slist_wc, fmt: [*:0]const u8, s: [*:0]const u8, d: c_int) callconv(.c) CURLcode {
    return easysrc_addf(plist, fmt, s, d);
}
pub export fn tool_zig_easysrc_addf_sl(plist: *?*slist_wc, fmt: [*:0]const u8, s: [*:0]const u8, l: c_long) callconv(.c) CURLcode {
    return easysrc_addf(plist, fmt, s, l);
}
pub export fn tool_zig_easysrc_addf_so(plist: *?*slist_wc, fmt: [*:0]const u8, s: [*:0]const u8, o: curl_off_t) callconv(.c) CURLcode {
    return easysrc_addf(plist, fmt, s, o);
}
pub export fn tool_zig_easysrc_addf_ds(plist: *?*slist_wc, fmt: [*:0]const u8, d: c_int, s: [*:0]const u8) callconv(.c) CURLcode {
    return easysrc_addf(plist, fmt, d, s);
}
pub export fn tool_zig_easysrc_addf_dd(plist: *?*slist_wc, fmt: [*:0]const u8, d1: c_int, d2: c_int) callconv(.c) CURLcode {
    return easysrc_addf(plist, fmt, d1, d2);
}
pub export fn tool_zig_easysrc_addf_d(plist: *?*slist_wc, fmt: [*:0]const u8, d: c_int) callconv(.c) CURLcode {
    return easysrc_addf(plist, fmt, d);
}

// ============================================================================
// Part 2b: Curl_zig_* helpers from src/config2setopts.c
// ============================================================================

pub export fn Curl_zig_ttyecho(enable: bool, fd: c_int) callconv(.c) bool {
    if (is_windows) {
        const STD_INPUT_HANDLE: u32 = @bitCast(@as(i32, -10));
        const ENABLE_ECHO_INPUT: u32 = 0x0004;
        const input_handle = win_c.GetStdHandle(STD_INPUT_HANDLE);
        var mode: u32 = 0;
        if (win_c.GetConsoleMode(input_handle, &mode) == 0) {
            return false;
        }
        const new_mode = if (enable) (mode | ENABLE_ECHO_INPUT) else (mode & ~ENABLE_ECHO_INPUT);
        return win_c.SetConsoleMode(input_handle, new_mode) != 0;
    } else {
        const StateEcho = struct {
            var withecho: posix_c.Termios = std.mem.zeroes(posix_c.Termios);
            var noecho: posix_c.Termios = std.mem.zeroes(posix_c.Termios);
        };
        const TCSAFLUSH_VAL: c_int = 2;
        if (!enable) {
            _ = posix_c.tcgetattr(fd, &StateEcho.withecho);
            StateEcho.noecho = StateEcho.withecho;
            StateEcho.noecho.c_lflag &= ~@as(@TypeOf(StateEcho.noecho.c_lflag), posix_c.ECHO_FLAG);
            _ = posix_c.tcsetattr(fd, posix_c.TCSANOW, &StateEcho.noecho);
            return true;
        }
        _ = posix_c.tcsetattr(fd, TCSAFLUSH_VAL, &StateEcho.withecho);
        return true;
    }
}

pub export fn Curl_zig_ssls_setopt(config: *OperationConfig, share: ?*CURLSH, easy: ?*CURL) callconv(.c) CURLcode {
    var result: CURLcode = curl_easy_setopt(easy, CURLOPT_SHARE, share);
    if (result == CURLE_OK and global != null and global.?.tracetype != TRACE_NONE) {
        result = tool_setopt_ptr(easy, "CURLOPT_DEBUGFUNCTION", CURLOPT_DEBUGFUNCTION, @as(?*const anyopaque, @ptrCast(&tool_debug_cb)));
        if (result == CURLE_OK) {
            result = tool_setopt_ptr(easy, "CURLOPT_DEBUGDATA", CURLOPT_DEBUGDATA, @as(?*const anyopaque, @ptrCast(config)));
        }
        _ = tool_setopt_long(easy, "CURLOPT_VERBOSE", CURLOPT_VERBOSE, 1);
    }
    return result;
}

pub export fn Curl_zig_stdout() callconv(.c) ?*FILE {
    return stdio_streams.getStdout();
}

pub export fn Curl_zig_global_get_libcurl() callconv(.c) ?[*:0]const u8 {
    return if (global) |g| g.libcurl else null;
}

pub export fn Curl_zig_stdin_regular_size(porigin: *curl_off_t, psize: *curl_off_t) callconv(.c) bool {
    const stdin_fp = stdio_streams.getStdin();
    const fd = toolFileno(stdin_fp);
    if (is_windows) {
        _ = win_c._setmode(fd, win_c.O_BINARY);
    }
    const origin: curl_off_t = @intCast(ftell(stdin_fp));
    porigin.* = origin;
    var s: ToolStat = undefined;
    if (fd >= 0 and origin >= 0 and toolFstat(fd, &s) == 0 and s.is_reg) {
        var size = s.size - origin;
        if (size < 0) size = 0;
        psize.* = size;
        return true;
    }
    return false;
}

pub export fn Curl_zig_fseek(stream: ?*FILE, offset: curl_off_t, whence: c_int) callconv(.c) c_int {
    if (is_windows) {
        return win_c._fseeki64(stream, offset, whence);
    } else {
        return posix_c.fseeko(stream, offset, whence);
    }
}

pub export fn Curl_zig_sizeof_operation_config() callconv(.c) usize {
    return @sizeOf(OperationConfig);
}

pub export fn Curl_zig_sizeof_getout() callconv(.c) usize {
    return @sizeOf(getout);
}

pub export fn Curl_zig_config_init_bits(config: *OperationConfig) callconv(.c) void {
    config.use_httpget = false;
    config.create_dirs = false;
    config.proto_present = false;
    config.proto_redir_present = false;
    config.tcp_nodelay = true;
    config.http09_allowed = false;
    config.ftp_skip_ip = true;
}

pub export fn Curl_zig_global_init_storage(first: ?*OperationConfig) callconv(.c) ?*GlobalConfig {
    global_storage = std.mem.zeroes(GlobalConfig);
    global_storage.showerror = false;
    global_storage.styled_output = true;
    global_storage.parallel_max = PARALLEL_DEFAULT;
    global_storage.first = first;
    global_storage.last = first;
    return &global_storage;
}

pub export fn Curl_zig_global_free_fields(g: *GlobalConfig) callconv(.c) ?*OperationConfig {
    Curl_cfree(g.trace_dump);
    g.trace_dump = null;
    if (g.trace_fopened and g.trace_stream != null) {
        _ = fclose(g.trace_stream);
    }
    g.trace_stream = null;
    Curl_cfree(g.ssl_sessions);
    g.ssl_sessions = null;
    Curl_cfree(g.libcurl);
    g.libcurl = null;
    if (is_windows) {
        Curl_cfree(@ptrCast(g.term.buf));
        g.term.buf = null;
    }
    const last = g.last;
    g.first = null;
    g.last = null;
    return last;
}

pub export fn Curl_zig_getout_init_bits(config: *OperationConfig, node: *getout, num: i64) callconv(.c) void {
    node.useremote = config.remote_name_all;
    node.num = num;
}

pub export fn Curl_zig_config_is_jsoned(config: *OperationConfig) callconv(.c) bool {
    return config.jsoned;
}

extern fn tool_version_info() callconv(.c) void;
extern fn tool_list_engines() callconv(.c) void;
extern fn easysrc_init() callconv(.c) CURLcode;
extern fn easysrc_perform() callconv(.c) CURLcode;
extern fn easysrc_cleanup() callconv(.c) CURLcode;
extern fn dumpeasysrc() callconv(.c) void;
extern fn tool_ssls_load(config: *OperationConfig, share: ?*CURLSH, file: [*:0]const u8) callconv(.c) CURLcode;
extern fn tool_ssls_save(config: *OperationConfig, share: ?*CURLSH, file: [*:0]const u8) callconv(.c) CURLcode;
extern fn varcleanup() callconv(.c) void;
extern fn Curl_zig_easysrc_add_formatted(pplist: *?*slist_wc, ret: ?[*:0]u8) callconv(.c) CURLcode;
extern fn tool_voutf_zig(global_cfg: ?*GlobalConfig, prefix: [*:0]const u8, msg: [*:0]const u8) callconv(.c) void;
extern fn tool_helpf_zig(msg: ?[*:0]const u8) callconv(.c) void;

extern fn glob_show_error(glob: *URLGlob, url: ?[*:0]const u8, err: ?*FILE, result: CURLcode) callconv(.c) void;
extern fn glob_url(glob: *URLGlob, url: [*:0]const u8, urlnum: *curl_off_t, err: ?*FILE) callconv(.c) CURLcode;
extern fn glob_next_url(globbed: *?[*:0]u8, glob: *URLGlob) callconv(.c) CURLcode;
extern fn glob_match_url(output: *?[*:0]u8, filename: [*:0]const u8, glob: *URLGlob, glob2: ?*URLGlob, sc: *SANITIZEcode) callconv(.c) CURLcode;
extern fn glob_cleanup(glob: *URLGlob) callconv(.c) void;
extern fn glob_inuse(glob: *URLGlob) callconv(.c) bool;
extern fn glob_is_literal(glob: *const URLGlob) callconv(.c) bool;

// curl / curlx functions
extern fn curl_easy_init() callconv(.c) ?*CURL;
extern fn curl_easy_cleanup(curl: ?*CURL) callconv(.c) void;
extern fn curl_easy_perform(curl: ?*CURL) callconv(.c) CURLcode;
extern fn curl_easy_setopt(curl: ?*CURL, option: CURLoption, ...) callconv(.c) CURLcode;
extern fn curl_easy_getinfo(curl: ?*CURL, info: CURLINFO, ...) callconv(.c) CURLcode;
extern fn curl_easy_strerror(code: CURLcode) callconv(.c) [*:0]const u8;
extern fn curl_easy_header(easy: ?*CURL, name: [*:0]const u8, index: usize, origin: c_uint, request: c_int, hout: *?*curl_header) callconv(.c) c_uint;

pub const curl_header = extern struct {
    name: [*:0]u8,
    value: [*:0]u8,
    amount: usize,
    index: usize,
    origin: c_uint,
    anchor: ?*anyopaque,
};

extern fn curl_multi_init() callconv(.c) ?*CURLM;
extern fn curl_multi_cleanup(multi: ?*CURLM) callconv(.c) CURLMcode;
extern fn curl_multi_add_handle(multi: ?*CURLM, easy: ?*CURL) callconv(.c) CURLMcode;
extern fn curl_multi_remove_handle(multi: ?*CURLM, easy: ?*CURL) callconv(.c) CURLMcode;
extern fn curl_multi_perform(multi: ?*CURLM, running_handles: *c_int) callconv(.c) CURLMcode;
extern fn curl_multi_poll(multi: ?*CURLM, extra_fds: ?*anyopaque, extra_nfds: c_uint, timeout_ms: c_int, ret: ?*c_int) callconv(.c) CURLMcode;
extern fn curl_multi_info_read(multi: ?*CURLM, msgs_in_queue: *c_int) callconv(.c) ?*CURLMsg;
extern fn curl_multi_setopt(multi: ?*CURLM, option: CURLMoption, ...) callconv(.c) CURLMcode;
extern fn curl_multi_notify_enable(multi: ?*CURLM, notification: c_uint) callconv(.c) CURLMcode;
extern fn curl_multi_get_offt(multi: ?*CURLM, info: CURLMinfo_offt, pvalue: *curl_off_t) callconv(.c) CURLMcode;

pub const CURLMsg = extern struct {
    msg: c_uint,
    easy_handle: ?*CURL,
    data: extern union {
        whatever: ?*anyopaque,
        result: CURLcode,
    },
};

extern fn curl_share_init() callconv(.c) ?*CURLSH;
extern fn curl_share_cleanup(share: ?*CURLSH) callconv(.c) CURLSHcode;
extern fn curl_share_setopt(share: ?*CURLSH, option: CURLSHoption, ...) callconv(.c) CURLSHcode;

extern fn curl_url() callconv(.c) ?*CURLU;
extern fn curl_url_cleanup(handle: ?*CURLU) callconv(.c) void;
extern fn curl_url_set(handle: ?*CURLU, what: CURLUPart, part: ?[*:0]const u8, flags: c_uint) callconv(.c) CURLUcode;
extern fn curl_url_get(handle: ?*CURLU, what: CURLUPart, part: *?[*:0]u8, flags: c_uint) callconv(.c) CURLUcode;

extern fn curl_mime_free(mime: ?*curl_mime) callconv(.c) void;
extern fn curl_version_info(age: c_uint) callconv(.c) *curl_version_info_data;
extern fn curl_getenv(variable: [*:0]const u8) callconv(.c) ?[*:0]u8;
extern fn curl_free(p: ?*anyopaque) callconv(.c) void;
extern fn curl_strequal(s1: ?[*:0]const u8, s2: ?[*:0]const u8) callconv(.c) c_int;
extern fn curl_strnequal(s1: ?[*:0]const u8, s2: ?[*:0]const u8, n: usize) callconv(.c) c_int;
extern fn curl_msnprintf(buffer: [*]u8, maxlength: usize, format: [*:0]const u8, ...) callconv(.c) c_int;
extern fn curl_maprintf(format: [*:0]const u8, ...) callconv(.c) ?[*:0]u8;
extern fn curl_mfprintf(fd: ?*FILE, format: [*:0]const u8, ...) callconv(.c) c_int;
extern fn curl_mvaprintf(format: [*:0]const u8, args: CVaListParam) callconv(.c) ?[*:0]u8;

extern var Curl_cstrdup: *const fn ([*:0]const u8) callconv(.c) ?[*:0]u8;
extern var Curl_ccalloc: *const fn (usize, usize) callconv(.c) ?*anyopaque;
extern var Curl_crealloc: *const fn (?*anyopaque, usize) callconv(.c) ?*anyopaque;
extern var Curl_cfree: *const fn (?*anyopaque) callconv(.c) void;
extern var Curl_cmalloc: *const fn (usize) callconv(.c) ?*anyopaque;

extern fn curlx_dyn_init(s: *Dynbuf, toobig: usize) callconv(.c) void;
extern fn curlx_dyn_add(s: *Dynbuf, str: [*:0]const u8) callconv(.c) CURLcode;
extern fn curlx_dyn_addf(s: *Dynbuf, fmt: [*:0]const u8, ...) callconv(.c) CURLcode;
extern fn curlx_dyn_ptr(s: *const Dynbuf) callconv(.c) ?[*:0]u8;
extern fn curlx_dyn_len(s: *const Dynbuf) callconv(.c) usize;
extern fn curlx_dyn_free(s: *Dynbuf) callconv(.c) void;
extern fn curlx_now() callconv(.c) curltime;
extern fn curlx_timediff_ms(newer: curltime, older: curltime) callconv(.c) timediff_t;
extern fn curlx_wait_ms(hms: timediff_t) callconv(.c) c_int;
extern fn curlx_nonblock(sockfd: curl_socket_t, nonblock: c_int) callconv(.c) c_int;
extern fn curlx_strerror(err: c_int, buf: [*]u8, buflen: usize) callconv(.c) [*:0]const u8;
extern fn curlx_gmtime(t: i64, store: *tm) callconv(.c) CURLcode;
extern fn curlx_str_number(str: *?[*:0]const u8, num: *curl_off_t, max: curl_off_t) callconv(.c) c_int;

extern fn fopen(filename: [*:0]const u8, mode: [*:0]const u8) callconv(.c) ?*FILE;
extern fn freopen(filename: [*:0]const u8, mode: [*:0]const u8, stream: ?*FILE) callconv(.c) ?*FILE;
extern fn fclose(stream: ?*FILE) callconv(.c) c_int;
extern fn fflush(stream: ?*FILE) callconv(.c) c_int;
extern fn ferror(stream: ?*FILE) callconv(.c) c_int;
extern fn fputs(s: [*:0]const u8, stream: ?*FILE) callconv(.c) c_int;
extern fn ftell(stream: ?*FILE) callconv(.c) c_long;
extern fn fseek(stream: ?*FILE, offset: c_long, whence: c_int) callconv(.c) c_int;
extern fn fileno(stream: ?*FILE) callconv(.c) c_int;
extern fn getenv(name: [*:0]const u8) callconv(.c) ?[*:0]u8;
extern fn strcmp(s1: [*:0]const u8, s2: [*:0]const u8) callconv(.c) c_int;
extern fn strncmp(s1: [*:0]const u8, s2: [*:0]const u8, n: usize) callconv(.c) c_int;
extern fn strcspn(s: [*:0]const u8, reject: [*:0]const u8) callconv(.c) usize;
extern fn time(tloc: ?*i64) callconv(.c) i64;
extern fn strftime(s: [*]u8, max: usize, format: [*:0]const u8, tm_ptr: *const tm) callconv(.c) usize;
extern fn setlocale(category: c_int, locale: [*:0]const u8) callconv(.c) ?[*:0]u8;

// ============================================================================
// Part 3: src/config2setopts.c (config2setopts and helpers)
// ============================================================================

const BUFFER_SIZE: c_long = 102400;
const CURLHTTPSIG_NONE: c_long = 0;
const CURLHTTPSIG_ED25519: c_long = 1;
const CURLHTTPSIG_HMAC_SHA256: c_long = 2;
const backend_options = @import("backend_options");
const CURL_USERAGENT_DEFAULT: [*:0]const u8 = "curl/" ++ backend_options.version;
const CURLVERSION_NOW: c_uint = 11;
const CURL_SSLVERSION_TLSv1_0: c_long = 4;
const CURL_SSLVERSION_TLSv1_1: c_long = 5;
const CURL_SSLVERSION_TLSv1_2: c_long = 6;
const CURL_SSLVERSION_TLSv1_3: c_long = 7;
const CURL_SSLVERSION_MAX_TLSv1_0: c_long = (CURL_SSLVERSION_TLSv1_0 << 16);
const CURL_SSLVERSION_MAX_TLSv1_1: c_long = (CURL_SSLVERSION_TLSv1_1 << 16);
const CURL_SSLVERSION_MAX_TLSv1_2: c_long = (CURL_SSLVERSION_TLSv1_2 << 16);
const CURL_SSLVERSION_MAX_TLSv1_3: c_long = (CURL_SSLVERSION_TLSv1_3 << 16);
const CURLOPT_INTERLEAVEDATA: CURLoption = CURLOPTTYPE_CBPOINT + 195;
const CURLAUTH_GSSNEGOTIATE: c_ulong = CURLAUTH_NEGOTIATE;
const CURL_NETRC_IGNORED: c_long = 0;
const CURLFTP_CREATE_DIR_NONE: c_long = 0;
const CURLOPT_STDERR: CURLoption = CURLOPTTYPE_OBJECTPOINT + 37;
const CURLOPT_NOPROGRESS: CURLoption = CURLOPTTYPE_LONG + 43;
const CURLINFO_EFFECTIVE_METHOD: CURLINFO = CURLINFO_STRING + 58;
const CURLINFO_CONDITION_UNMET: CURLINFO = CURLINFO_LONG + 35;
const CURLINFO_TLS_SSL_PTR: CURLINFO = CURLINFO_PTR + 45;
const CURLMINFO_XFERS_CURRENT: CURLMinfo_offt = 1;
const CURLMNOTIFY_INFO_READ: c_uint = 0;
const CURLMOPT_NOTIFYFUNCTION: CURLMoption = CURLOPTTYPE_FUNCTIONPOINT + 18;
const CURLMOPT_NOTIFYDATA: CURLMoption = CURLOPTTYPE_OBJECTPOINT + 19;
const CURLMOPT_QUICK_EXIT: CURLMoption = CURLOPTTYPE_LONG + 21;
const CURLOPT_HEADERFUNCTION: CURLoption = CURLOPTTYPE_FUNCTIONPOINT + 79;
const CURLOPT_SOCKOPTFUNCTION: CURLoption = CURLOPTTYPE_FUNCTIONPOINT + 148;
const CURLOPT_SOCKOPTDATA: CURLoption = CURLOPTTYPE_CBPOINT + 149;
const CURLOPT_PIPEWAIT: CURLoption = CURLOPTTYPE_LONG + 237;
const CURL_HET_DEFAULT: c_long = 200;

fn toolIsatty(fd: c_int) c_int {
    if (is_windows) {
        const WinIsatty = struct {
            extern "c" fn _isatty(f: c_int) callconv(.c) c_int;
        };
        return WinIsatty._isatty(fd);
    } else {
        const PosixIsatty = struct {
            extern "c" fn isatty(f: c_int) callconv(.c) c_int;
        };
        return PosixIsatty.isatty(fd);
    }
}

fn setopt_bad(result: CURLcode) bool {
    return result != CURLE_OK and
        result != CURLE_NOT_BUILT_IN and
        result != CURLE_UNKNOWN_OPTION;
}

fn sockopt_callback(clientp: ?*anyopaque, curlfd: curl_socket_t, purpose: c_uint) callconv(.c) c_int {
    if (purpose != 0) return 0; // CURLSOCKTYPE_IPCXN = 0, CURL_SOCKOPT_OK = 0
    if (is_windows) {
        return 0;
    } else {
        const config: *OperationConfig = @ptrCast(@alignCast(clientp orelse return 0));
        const PosixSockopt = struct {
            const sockaddr = extern struct {
                sa_family: if (builtin.os.tag.isDarwin()) u8 else u16,
                sa_data: [14]u8,
            };
            extern "c" fn getsockname(sockfd: c_int, addr: *sockaddr, addrlen: *u32) callconv(.c) c_int;
            extern "c" fn setsockopt(sockfd: c_int, level: c_int, optname: c_int, optval: *const anyopaque, optlen: u32) callconv(.c) c_int;
        };
        if (config.ip_tos > 0) {
            var tos: c_int = @intCast(config.ip_tos);
            var res: c_int = 0;
            var addr: PosixSockopt.sockaddr = std.mem.zeroes(PosixSockopt.sockaddr);
            var addrlen: u32 = @sizeOf(PosixSockopt.sockaddr);
            var family: c_int = 0;
            if (PosixSockopt.getsockname(curlfd, &addr, &addrlen) == 0) {
                family = if (builtin.os.tag.isDarwin()) @intCast(addr.sa_data[0]) else @intCast(addr.sa_family);
            }
            const AF_INET_VAL: c_int = 2;
            const AF_INET6_VAL: c_int = if (builtin.os.tag.isDarwin()) 30 else 10;
            const IPPROTO_IP_VAL: c_int = 0;
            const IP_TOS_VAL: c_int = if (builtin.os.tag.isDarwin()) 3 else 1;
            const IPPROTO_IPV6_VAL: c_int = 41;
            const IPV6_TCLASS_VAL: c_int = if (builtin.os.tag.isDarwin()) 36 else 67;
            if (family == AF_INET_VAL) {
                res = PosixSockopt.setsockopt(curlfd, IPPROTO_IP_VAL, IP_TOS_VAL, &tos, @sizeOf(c_int));
            } else if (family == AF_INET6_VAL) {
                res = PosixSockopt.setsockopt(curlfd, IPPROTO_IPV6_VAL, IPV6_TCLASS_VAL, &tos, @sizeOf(c_int));
            }
            if (res < 0) {
                var errbuf: [STRERROR_LEN]u8 = undefined;
                const err = getErrno();
                warnf("Setting type of service to %d failed with errno %d: %s", tos, err, curlx_strerror(err, &errbuf, errbuf.len));
            }
        }
        if (!builtin.os.tag.isDarwin() and config.vlan_priority > 0) {
            var priority: c_int = @intCast(config.vlan_priority);
            const SOL_SOCKET_VAL: c_int = 1;
            const SO_PRIORITY_VAL: c_int = 12;
            if (PosixSockopt.setsockopt(curlfd, SOL_SOCKET_VAL, SO_PRIORITY_VAL, &priority, @sizeOf(c_int)) != 0) {
                var errbuf: [STRERROR_LEN]u8 = undefined;
                const err = getErrno();
                warnf("VLAN priority %d failed with errno %d: %s", priority, err, curlx_strerror(err, &errbuf, errbuf.len));
            }
        }
        return 0;
    }
}

var ssl_ver_buf: [80:0]u8 = blk: {
    var b: [80:0]u8 = @splat(0);
    const init = "no ssl";
    @memcpy(b[0..init.len], init);
    break :blk b;
};
var ssl_ver_already: bool = false;

fn ssl_backend() [*:0]const u8 {
    if (!ssl_ver_already) {
        if (curl_version_info(CURLVERSION_NOW).ssl_version) |v| {
            const len: c_int = @intCast(strcspn(v, " "));
            _ = curl_msnprintf(&ssl_ver_buf, ssl_ver_buf.len, "%.*s", len, v);
        }
        ssl_ver_already = true;
    }
    return &ssl_ver_buf;
}

fn url_proto_and_rewrite(url: *?[*:0]u8, config: *OperationConfig, scheme: *?[*:0]const u8) CURLcode {
    var result: CURLcode = CURLE_OK;
    const uh = curl_url();
    var proto: ?[*:0]const u8 = null;
    scheme.* = null;

    if (uh) |u| {
        var schemep: ?[*:0]u8 = null;
        var uc = curl_url_set(u, CURLUPART_URL, url.*, CURLU_GUESS_SCHEME | CURLU_NON_SUPPORT_SCHEME);
        if (uc == CURLUE_OK) {
            if (config.proto_default) |pdef| {
                uc = curl_url_get(u, CURLUPART_SCHEME, &schemep, CURLU_NO_GUESS_SCHEME);
                if (uc == CURLUE_NO_SCHEME) {
                    proto = proto_token(pdef);
                    if (proto != null) {
                        uc = CURLUE_OK;
                    }
                }
            } else {
                uc = curl_url_get(u, CURLUPART_SCHEME, &schemep, CURLU_DEFAULT_SCHEME);
            }
            if (schemep) |sp| {
                proto = proto_token(sp);
            }
            if (uc == CURLUE_OK and schemep != null and
                ((proto_ipfs != null and curl_strequal(schemep, proto_ipfs) != 0) or
                    (proto_ipns != null and curl_strequal(schemep, proto_ipns) != 0)))
            {
                result = ipfs_url_rewrite(u, schemep.?, url, config);
                if (proto_ipfs != null and curl_strequal(schemep, proto_ipfs) != 0) {
                    proto = proto_ipfs;
                } else if (proto_ipns != null and curl_strequal(schemep, proto_ipns) != 0) {
                    proto = proto_ipns;
                }
                if (result != CURLE_OK) {
                    config.synthetic_error = true;
                }
            }
            if (uc == CURLUE_OUT_OF_MEMORY) {
                result = CURLE_OUT_OF_MEMORY;
            }
            curl_free(schemep);
        } else if (uc == CURLUE_OUT_OF_MEMORY) {
            result = CURLE_OUT_OF_MEMORY;
        }
        curl_url_cleanup(u);
    } else {
        result = CURLE_OUT_OF_MEMORY;
    }

    scheme.* = if (proto) |p| p else "?";
    return result;
}

fn ssh_setopts(config: *OperationConfig, curl: ?*CURL) CURLcode {
    var result: CURLcode = CURLE_OK;

    if (proto_scp == null and proto_sftp == null) {
        return CURLE_OK;
    }

    result = tool_setopt_str(curl, config, "CURLOPT_SSH_PRIVATE_KEYFILE", CURLOPT_SSH_PRIVATE_KEYFILE, config.key);
    if (setopt_bad(result)) return result;

    result = tool_setopt_str(curl, config, "CURLOPT_SSH_PUBLIC_KEYFILE", CURLOPT_SSH_PUBLIC_KEYFILE, config.pubkey);
    if (setopt_bad(result)) return result;

    result = tool_setopt_str(curl, config, "CURLOPT_SSH_HOST_PUBLIC_KEY_MD5", CURLOPT_SSH_HOST_PUBLIC_KEY_MD5, config.hostpubmd5);
    if (setopt_bad(result)) return result;

    result = tool_setopt_str(curl, config, "CURLOPT_SSH_HOST_PUBLIC_KEY_SHA256", CURLOPT_SSH_HOST_PUBLIC_KEY_SHA256, config.hostpubsha256);
    if (setopt_bad(result)) return result;

    if (config.ssh_compression) {
        _ = tool_setopt_long(curl, "CURLOPT_SSH_COMPRESSION", CURLOPT_SSH_COMPRESSION, 1);
    }

    if (!config.insecure_ok) {
        var known = config.knownhosts;
        if (known == null) {
            const found = findfile(".ssh/known_hosts", 0);
            if (found) |f| {
                known = Curl_cstrdup(f);
                curl_free(f);
                if (known == null) return CURLE_OUT_OF_MEMORY;
            } else if (config.hostpubmd5 == null and config.hostpubsha256 == null) {
                var k: Dynbuf = undefined;
                const home = getenv("HOME");
                curlx_dyn_init(&k, 256);
                const dir_char = if (is_windows) "\\" else "/";
                result = curlx_dyn_addf(&k, "%s" ++ dir_char ++ ".ssh" ++ dir_char ++ "known_hosts", if (home) |h| h else "");
                if (result != CURLE_OK) return result;
                known = curlx_dyn_ptr(&k);
            }
        }

        if (known) |kn| {
            result = tool_setopt_str(curl, config, "CURLOPT_SSH_KNOWNHOSTS", CURLOPT_SSH_KNOWNHOSTS, kn);
            if (result != CURLE_OK) {
                config.knownhosts = null;
                Curl_cfree(kn);
                return result;
            }
            config.knownhosts = kn;
        }
    }
    return CURLE_OK;
}

fn tlsversion(mintls_in: u8, maxtls: u8) c_long {
    var mintls = mintls_in;
    var tlsver: c_long = 0;
    if (mintls == 0 and maxtls != 0 and maxtls < 3) {
        mintls = maxtls;
    }
    switch (mintls) {
        1 => tlsver = CURL_SSLVERSION_TLSv1_0,
        2 => tlsver = CURL_SSLVERSION_TLSv1_1,
        0, 3 => tlsver = CURL_SSLVERSION_TLSv1_2,
        else => tlsver = CURL_SSLVERSION_TLSv1_3,
    }
    switch (maxtls) {
        0 => {},
        1 => tlsver |= CURL_SSLVERSION_MAX_TLSv1_0,
        2 => tlsver |= CURL_SSLVERSION_MAX_TLSv1_1,
        3 => tlsver |= CURL_SSLVERSION_MAX_TLSv1_2,
        else => tlsver |= CURL_SSLVERSION_MAX_TLSv1_3,
    }
    return tlsver;
}

fn ssl_ca_setopts(config: *OperationConfig, curl: ?*CURL) CURLcode {
    var result: CURLcode = CURLE_OK;

    if (config.cacert) |cacert| {
        result = tool_setopt_str(curl, config, "CURLOPT_CAINFO", CURLOPT_CAINFO, cacert);
        if (setopt_bad(result)) return result;
    }
    if (config.proxy_cacert) |proxy_cacert| {
        result = tool_setopt_str(curl, config, "CURLOPT_PROXY_CAINFO", CURLOPT_PROXY_CAINFO, proxy_cacert);
        if (setopt_bad(result)) return result;
    }
    if (config.capath) |capath| {
        result = tool_setopt_str(curl, config, "CURLOPT_CAPATH", CURLOPT_CAPATH, capath);
        if (setopt_bad(result)) return result;
    }

    if (config.proxy_capath != null or config.capath != null) {
        const pcapath = if (config.proxy_capath) |p| p else config.capath;
        result = tool_setopt_str(curl, config, "CURLOPT_PROXY_CAPATH", CURLOPT_PROXY_CAPATH, pcapath);
        if (setopt_bad(result)) return result;
        if (result == CURLE_NOT_BUILT_IN or result == CURLE_UNKNOWN_OPTION) {
            warnf("ignoring %s, not supported by libcurl with %s", "setting the CA path for the proxy", ssl_backend());
            result = CURLE_OK;
        }
    }
    return result;
}

fn ssl_setopts(config: *OperationConfig, curl: ?*CURL) CURLcode {
    var result: CURLcode = CURLE_OK;

    if (config.crlfile) |crlfile| {
        result = tool_setopt_str(curl, config, "CURLOPT_CRLFILE", CURLOPT_CRLFILE, crlfile);
        if (setopt_bad(result)) return result;
    }
    if (config.proxy_crlfile) |proxy_crlfile| {
        result = tool_setopt_str(curl, config, "CURLOPT_PROXY_CRLFILE", CURLOPT_PROXY_CRLFILE, proxy_crlfile);
        if (setopt_bad(result)) return result;
    } else if (config.crlfile) |crlfile| {
        result = tool_setopt_str(curl, config, "CURLOPT_PROXY_CRLFILE", CURLOPT_PROXY_CRLFILE, crlfile);
        if (setopt_bad(result)) return result;
    }

    if (config.pinnedpubkey) |pinnedpubkey| {
        result = tool_setopt_str(curl, config, "CURLOPT_PINNEDPUBLICKEY", CURLOPT_PINNEDPUBLICKEY, pinnedpubkey);
        if (setopt_bad(result)) return result;
        if (result != CURLE_OK) {
            warnf("ignoring %s, not supported by libcurl with %s", "--pinnedpubkey", ssl_backend());
        }
    }
    if (config.proxy_pinnedpubkey) |proxy_pinnedpubkey| {
        result = tool_setopt_str(curl, config, "CURLOPT_PROXY_PINNEDPUBLICKEY", CURLOPT_PROXY_PINNEDPUBLICKEY, proxy_pinnedpubkey);
        if (setopt_bad(result)) return result;
        if (result != CURLE_OK) {
            warnf("ignoring %s, not supported by libcurl with %s", "--proxy-pinnedpubkey", ssl_backend());
        }
    }

    if (config.ssl_ec_curves) |ssl_ec_curves| {
        result = tool_setopt_str(curl, config, "CURLOPT_SSL_EC_CURVES", CURLOPT_SSL_EC_CURVES, ssl_ec_curves);
        if (setopt_bad(result)) return result;
    }

    if (config.ssl_signature_algorithms) |ssl_signature_algorithms| {
        result = tool_setopt_str(curl, config, "CURLOPT_SSL_SIGNATURE_ALGORITHMS", CURLOPT_SSL_SIGNATURE_ALGORITHMS, ssl_signature_algorithms);
        if (setopt_bad(result)) return result;
    }

    if (config.writeout != null) {
        _ = tool_setopt_long(curl, "CURLOPT_CERTINFO", CURLOPT_CERTINFO, 1);
    }

    result = tool_setopt_str(curl, config, "CURLOPT_SSLCERT", CURLOPT_SSLCERT, config.cert);
    if (setopt_bad(result)) return result;
    result = tool_setopt_str(curl, config, "CURLOPT_PROXY_SSLCERT", CURLOPT_PROXY_SSLCERT, config.proxy_cert);
    if (setopt_bad(result)) return result;
    result = tool_setopt_str(curl, config, "CURLOPT_SSLCERTTYPE", CURLOPT_SSLCERTTYPE, config.cert_type);
    if (setopt_bad(result)) return result;
    result = tool_setopt_str(curl, config, "CURLOPT_PROXY_SSLCERTTYPE", CURLOPT_PROXY_SSLCERTTYPE, config.proxy_cert_type);
    if (setopt_bad(result)) return result;
    result = tool_setopt_str(curl, config, "CURLOPT_SSLKEY", CURLOPT_SSLKEY, config.key);
    if (setopt_bad(result)) return result;
    result = tool_setopt_str(curl, config, "CURLOPT_PROXY_SSLKEY", CURLOPT_PROXY_SSLKEY, config.proxy_key);
    if (setopt_bad(result)) return result;
    result = tool_setopt_str(curl, config, "CURLOPT_SSLKEYTYPE", CURLOPT_SSLKEYTYPE, config.key_type);
    if (setopt_bad(result)) return result;
    result = tool_setopt_str(curl, config, "CURLOPT_PROXY_SSLKEYTYPE", CURLOPT_PROXY_SSLKEYTYPE, config.proxy_key_type);
    if (setopt_bad(result)) return result;

    _ = tool_setopt_long_force(curl, "CURLOPT_SSL_VERIFYPEER", CURLOPT_SSL_VERIFYPEER, if (config.insecure_ok) 0 else 1);
    _ = tool_setopt_long_force(curl, "CURLOPT_SSL_VERIFYHOST", CURLOPT_SSL_VERIFYHOST, if (config.insecure_ok) 0 else 1);

    if (config.doh_insecure_ok) {
        _ = tool_setopt_long(curl, "CURLOPT_DOH_SSL_VERIFYPEER", CURLOPT_DOH_SSL_VERIFYPEER, 0);
        _ = tool_setopt_long(curl, "CURLOPT_DOH_SSL_VERIFYHOST", CURLOPT_DOH_SSL_VERIFYHOST, 0);
    }

    if (config.proxy_insecure_ok) {
        _ = tool_setopt_long(curl, "CURLOPT_PROXY_SSL_VERIFYPEER", CURLOPT_PROXY_SSL_VERIFYPEER, 0);
        _ = tool_setopt_long(curl, "CURLOPT_PROXY_SSL_VERIFYHOST", CURLOPT_PROXY_SSL_VERIFYHOST, 0);
    }

    if (config.verifystatus) {
        _ = tool_setopt_long(curl, "CURLOPT_SSL_VERIFYSTATUS", CURLOPT_SSL_VERIFYSTATUS, 1);
    }

    if (config.doh_verifystatus) {
        _ = tool_setopt_long(curl, "CURLOPT_DOH_SSL_VERIFYSTATUS", CURLOPT_DOH_SSL_VERIFYSTATUS, 1);
    }

    _ = tool_setopt_SSLVERSION(curl, "CURLOPT_SSLVERSION", CURLOPT_SSLVERSION, tlsversion(config.ssl_version, config.ssl_version_max));
    if (config.proxy != null) {
        _ = tool_setopt_SSLVERSION(curl, "CURLOPT_PROXY_SSLVERSION", CURLOPT_PROXY_SSLVERSION, config.proxy_ssl_version);
    }

    {
        const mask: c_long =
            (if (config.ssl_allow_beast) CURLSSLOPT_ALLOW_BEAST else 0) |
            (if (config.ssl_allow_earlydata) CURLSSLOPT_EARLYDATA else 0) |
            (if (config.ssl_no_revoke) CURLSSLOPT_NO_REVOKE else 0) |
            (if (config.ssl_revoke_best_effort) CURLSSLOPT_REVOKE_BEST_EFFORT else 0) |
            (if (config.native_ca_store) CURLSSLOPT_NATIVE_CA else 0) |
            (if (config.ssl_auto_client_cert) CURLSSLOPT_AUTO_CLIENT_CERT else 0);
        if (mask != 0) {
            _ = tool_setopt_bitmask(curl, "CURLOPT_SSL_OPTIONS", CURLOPT_SSL_OPTIONS, &setopt_nv_CURLSSLOPT, mask);
        }
    }

    {
        const mask: c_long =
            (if (config.proxy_ssl_allow_beast) CURLSSLOPT_ALLOW_BEAST else 0) |
            (if (config.proxy_ssl_auto_client_cert) CURLSSLOPT_AUTO_CLIENT_CERT else 0) |
            (if (config.proxy_native_ca_store) CURLSSLOPT_NATIVE_CA else 0);
        if (mask != 0) {
            _ = tool_setopt_bitmask(curl, "CURLOPT_PROXY_SSL_OPTIONS", CURLOPT_PROXY_SSL_OPTIONS, &setopt_nv_CURLSSLOPT, mask);
        }
    }

    if (config.cipher_list) |cipher_list| {
        result = tool_setopt_str(curl, config, "CURLOPT_SSL_CIPHER_LIST", CURLOPT_SSL_CIPHER_LIST, cipher_list);
        if (setopt_bad(result)) return result;
        if (result != CURLE_OK) {
            warnf("ignoring %s, not supported by libcurl with %s", "--ciphers", ssl_backend());
        }
    }
    if (config.proxy_cipher_list) |proxy_cipher_list| {
        result = tool_setopt_str(curl, config, "CURLOPT_PROXY_SSL_CIPHER_LIST", CURLOPT_PROXY_SSL_CIPHER_LIST, proxy_cipher_list);
        if (setopt_bad(result)) return result;
        if (result != CURLE_OK) {
            warnf("ignoring %s, not supported by libcurl with %s", "--proxy-ciphers", ssl_backend());
        }
    }
    if (config.cipher13_list) |cipher13_list| {
        result = tool_setopt_str(curl, config, "CURLOPT_TLS13_CIPHERS", CURLOPT_TLS13_CIPHERS, cipher13_list);
        if (setopt_bad(result)) return result;
        if (result != CURLE_OK) {
            warnf("ignoring %s, not supported by libcurl with %s", "--tls13-ciphers", ssl_backend());
        }
    }
    if (config.proxy_cipher13_list) |proxy_cipher13_list| {
        result = tool_setopt_str(curl, config, "CURLOPT_PROXY_TLS13_CIPHERS", CURLOPT_PROXY_TLS13_CIPHERS, proxy_cipher13_list);
        if (setopt_bad(result)) return result;
        if (result != CURLE_OK) {
            warnf("ignoring %s, not supported by libcurl with %s", "--proxy-tls13-ciphers", ssl_backend());
        }
    }

    if (config.disable_sessionid) {
        _ = tool_setopt_long(curl, "CURLOPT_SSL_SESSIONID_CACHE", CURLOPT_SSL_SESSIONID_CACHE, 0);
    }

    if (feature_ech) {
        if (config.ech_public) |ech_public| {
            result = tool_setopt_str(curl, config, "CURLOPT_ECH", CURLOPT_ECH, ech_public);
            if (setopt_bad(result)) return result;
        }
        if (config.ech_config) |ech_config| {
            result = tool_setopt_str(curl, config, "CURLOPT_ECH", CURLOPT_ECH, ech_config);
            if (setopt_bad(result)) return result;
        }
        if (config.ech) |ech| {
            result = tool_setopt_str(curl, config, "CURLOPT_ECH", CURLOPT_ECH, ech);
            if (setopt_bad(result)) return result;
        }
    }

    if (config.engine) |engine| {
        result = tool_setopt_str(curl, config, "CURLOPT_SSLENGINE", CURLOPT_SSLENGINE, engine);
        if (setopt_bad(result)) return result;
    }

    if (config.ftp_ssl_reqd) {
        _ = tool_setopt_enum(curl, "CURLOPT_USE_SSL", CURLOPT_USE_SSL, &setopt_nv_CURLUSESSL, CURLUSESSL_ALL);
    } else if (config.ftp_ssl) {
        _ = tool_setopt_enum(curl, "CURLOPT_USE_SSL", CURLOPT_USE_SSL, &setopt_nv_CURLUSESSL, CURLUSESSL_TRY);
    } else if (config.ftp_ssl_control) {
        _ = tool_setopt_enum(curl, "CURLOPT_USE_SSL", CURLOPT_USE_SSL, &setopt_nv_CURLUSESSL, CURLUSESSL_CONTROL);
    }

    if (config.noalpn) {
        _ = tool_setopt_long(curl, "CURLOPT_SSL_ENABLE_ALPN", CURLOPT_SSL_ENABLE_ALPN, 0);
    }

    return CURLE_OK;
}

fn cookie_setopts(config: *OperationConfig, curl: ?*CURL) CURLcode {
    var result: CURLcode = CURLE_OK;
    if (config.cookies) |first_cookie| {
        const MAX_REQUEST_COOKIE = 8200;
        var cookies: Dynbuf = undefined;
        curlx_dyn_init(&cookies, MAX_REQUEST_COOKIE);
        var cl: ?*curl_slist = first_cookie;
        while (cl) |node| : (cl = node.next) {
            if (node.data) |d| {
                if (node == first_cookie) {
                    result = curlx_dyn_add(&cookies, d);
                } else {
                    const is_blank = (d[0] == ' ' or d[0] == '\t');
                    const sep: [*:0]const u8 = if (is_blank) "" else " ";
                    result = curlx_dyn_addf(&cookies, ";%s%s", sep, d);
                }
                if (result != CURLE_OK) {
                    warnf("skipped provided cookie, the cookie header would go over %d bytes", @as(c_int, MAX_REQUEST_COOKIE));
                    curlx_dyn_free(&cookies);
                    return result;
                }
            }
        }
        result = tool_setopt_str(curl, config, "CURLOPT_COOKIE", CURLOPT_COOKIE, curlx_dyn_ptr(&cookies));
        curlx_dyn_free(&cookies);
        if (result != CURLE_OK) return result;
    }

    if (config.cookiefiles) |cfiles| {
        var cfl: ?*curl_slist = cfiles;
        while (cfl) |node| : (cfl = node.next) {
            result = tool_setopt_str(curl, config, "CURLOPT_COOKIEFILE", CURLOPT_COOKIEFILE, node.data);
            if (setopt_bad(result)) return result;
        }
    }

    if (config.cookiejar) |cookiejar| {
        result = tool_setopt_str(curl, config, "CURLOPT_COOKIEJAR", CURLOPT_COOKIEJAR, cookiejar);
        if (setopt_bad(result)) return result;
    }

    _ = tool_setopt_long(curl, "CURLOPT_COOKIESESSION", CURLOPT_COOKIESESSION, if (config.cookiesession) 1 else 0);

    return result;
}

fn httpsig_setopts(config: *OperationConfig, curl: ?*CURL) CURLcode {
    var result: CURLcode = CURLE_OK;
    if (config.httpsig_algorithm != null or config.httpsig_key != null or
        config.httpsig_keyid != null or config.httpsig_headers != null)
    {
        var httpsig_alg: c_long = CURLHTTPSIG_NONE;
        const key = config.httpsig_key orelse {
            errorf("--httpsig-key is required");
            return CURLE_FAILED_INIT;
        };
        if (config.httpsig_keyid == null) {
            errorf("--httpsig-keyid is required");
            return CURLE_FAILED_INIT;
        }
        if (config.httpsig_algorithm == null or curl_strequal(config.httpsig_algorithm, "ed25519") != 0) {
            httpsig_alg = CURLHTTPSIG_ED25519;
        } else if (curl_strequal(config.httpsig_algorithm, "hmac-sha256") != 0) {
            httpsig_alg = CURLHTTPSIG_HMAC_SHA256;
        } else {
            errorf("--httpsig-algo: unsupported algorithm '%s'", config.httpsig_algorithm.?);
            return CURLE_FAILED_INIT;
        }
        _ = tool_setopt_long(curl, "CURLOPT_HTTPSIG_ALGORITHM", CURLOPT_HTTPSIG_ALGORITHM, httpsig_alg);
        result = tool_setopt_str(curl, config, "CURLOPT_HTTPSIG_HEADERS", CURLOPT_HTTPSIG_HEADERS, config.httpsig_headers);
        if (setopt_bad(result)) return result;
        result = tool_setopt_str(curl, config, "CURLOPT_HTTPSIG_KEYID", CURLOPT_HTTPSIG_KEYID, config.httpsig_keyid);
        if (setopt_bad(result)) return result;

        if (key[0] == '@') {
            const keyfile_path: [*:0]const u8 = key + 1;
            const keyf = toolFopen(keyfile_path, if (is_windows) "rt" else "r");
            if (keyf) |fp| {
                var hexdata: ?[*:0]u8 = null;
                const pe = file2string(&hexdata, fp);
                _ = fclose(fp);
                if (pe == PARAM_NO_MEM) {
                    Curl_cfree(hexdata);
                    return CURLE_OUT_OF_MEMORY;
                }
                if (pe == PARAM_READ_ERROR) {
                    Curl_cfree(hexdata);
                    errorf("httpsig: cannot read key file '%s'", keyfile_path);
                    return CURLE_READ_ERROR;
                }
                if (hexdata == null or hexdata.?[0] == 0) {
                    Curl_cfree(hexdata);
                    errorf("httpsig: key file '%s' is empty", keyfile_path);
                    return CURLE_BAD_FUNCTION_ARGUMENT;
                }
                result = tool_setopt_str(curl, config, "CURLOPT_HTTPSIG_KEY", CURLOPT_HTTPSIG_KEY, hexdata);
                Curl_cfree(hexdata);
                if (setopt_bad(result)) return result;
            } else {
                errorf("httpsig: cannot open key file '%s'", keyfile_path);
                return CURLE_READ_ERROR;
            }
        } else {
            if (key[0] == 0) {
                errorf("httpsig: key is empty");
                return CURLE_BAD_FUNCTION_ARGUMENT;
            }
            result = tool_setopt_str(curl, config, "CURLOPT_HTTPSIG_KEY", CURLOPT_HTTPSIG_KEY, key);
            if (setopt_bad(result)) return result;
        }
    }
    return CURLE_OK;
}

fn http_setopts(config: *OperationConfig, curl: ?*CURL, use_proto: ?[*:0]const u8) CURLcode {
    var result: CURLcode = CURLE_OK;
    var postRedir: c_long = 0;

    if (use_proto != proto_http and use_proto != proto_https) {
        return CURLE_OK;
    }

    _ = tool_setopt_long(curl, "CURLOPT_FOLLOWLOCATION", CURLOPT_FOLLOWLOCATION, config.followlocation);
    _ = tool_setopt_long(curl, "CURLOPT_UNRESTRICTED_AUTH", CURLOPT_UNRESTRICTED_AUTH, if (config.unrestricted_auth) 1 else 0);

    result = tool_setopt_str(curl, config, "CURLOPT_AWS_SIGV4", CURLOPT_AWS_SIGV4, config.aws_sigv4);
    if (setopt_bad(result)) return result;

    result = httpsig_setopts(config, curl);
    if (result != CURLE_OK) return result;

    _ = tool_setopt_long(curl, "CURLOPT_AUTOREFERER", CURLOPT_AUTOREFERER, if (config.autoreferer) 1 else 0);

    if (config.proxyheaders != null) {
        _ = tool_setopt_slist(curl, "CURLOPT_PROXYHEADER", CURLOPT_PROXYHEADER, config.proxyheaders);
    }

    _ = tool_setopt_long(curl, "CURLOPT_MAXREDIRS", CURLOPT_MAXREDIRS, config.maxredirs);

    if (config.httpversion != 0) {
        _ = tool_setopt_enum(curl, "CURLOPT_HTTP_VERSION", CURLOPT_HTTP_VERSION, &setopt_nv_CURL_HTTP_VERSION, config.httpversion);
    }

    if (config.post301) postRedir |= CURL_REDIR_POST_301;
    if (config.post302) postRedir |= CURL_REDIR_POST_302;
    if (config.post303) postRedir |= CURL_REDIR_POST_303;
    _ = tool_setopt_long(curl, "CURLOPT_POSTREDIR", CURLOPT_POSTREDIR, postRedir);

    if (config.encoding) {
        result = tool_setopt_str(curl, config, "CURLOPT_ACCEPT_ENCODING", CURLOPT_ACCEPT_ENCODING, "");
        if (setopt_bad(result)) return result;
    }

    if (config.tr_encoding) {
        _ = tool_setopt_long(curl, "CURLOPT_TRANSFER_ENCODING", CURLOPT_TRANSFER_ENCODING, 1);
    }

    _ = tool_setopt_long(curl, "CURLOPT_HTTP09_ALLOWED", CURLOPT_HTTP09_ALLOWED, if (config.http09_allowed) 1 else 0);

    if (config.altsvc) |altsvc| {
        result = tool_setopt_str(curl, config, "CURLOPT_ALTSVC", CURLOPT_ALTSVC, altsvc);
        if (setopt_bad(result)) return result;
    }

    if (config.hsts) |hsts| {
        result = tool_setopt_str(curl, config, "CURLOPT_HSTS", CURLOPT_HSTS, hsts);
        if (setopt_bad(result)) return result;
    }

    if (config.expect100timeout_ms > 0) {
        _ = tool_setopt_long(curl, "CURLOPT_EXPECT_100_TIMEOUT_MS", CURLOPT_EXPECT_100_TIMEOUT_MS, config.expect100timeout_ms);
    }

    if (result == CURLE_OK) {
        result = cookie_setopts(config, curl);
    }
    if (result != CURLE_OK) return result;

    if ((config.proxy != null or config.proxyheaders != null) and
        (use_proto == proto_https or config.proxytunnel))
    {
        _ = tool_setopt_long(curl, "CURLOPT_HEADEROPT", CURLOPT_HEADEROPT, CURLHEADER_SEPARATE);
    }
    return result;
}

fn tcp_setopts(config: *OperationConfig, curl: ?*CURL) void {
    if (!config.tcp_nodelay) {
        _ = tool_setopt_long(curl, "CURLOPT_TCP_NODELAY", CURLOPT_TCP_NODELAY, 0);
    }
    if (config.tcp_fastopen) {
        _ = tool_setopt_long(curl, "CURLOPT_TCP_FASTOPEN", CURLOPT_TCP_FASTOPEN, 1);
    }
    if (config.mptcp) {
        _ = tool_setopt_ptr(curl, "CURLOPT_OPENSOCKETFUNCTION", CURLOPT_OPENSOCKETFUNCTION, @as(?*const anyopaque, @ptrCast(&tool_socket_open_mptcp_cb)));
    }
    if (!config.nokeepalive) {
        _ = tool_setopt_long(curl, "CURLOPT_TCP_KEEPALIVE", CURLOPT_TCP_KEEPALIVE, 1);
        if (config.alivetime != 0) {
            _ = tool_setopt_long(curl, "CURLOPT_TCP_KEEPIDLE", CURLOPT_TCP_KEEPIDLE, config.alivetime);
            _ = tool_setopt_long(curl, "CURLOPT_TCP_KEEPINTVL", CURLOPT_TCP_KEEPINTVL, config.alivetime);
        }
        if (config.alivecnt != 0) {
            _ = tool_setopt_long(curl, "CURLOPT_TCP_KEEPCNT", CURLOPT_TCP_KEEPCNT, config.alivecnt);
        }
    } else {
        _ = tool_setopt_long(curl, "CURLOPT_TCP_KEEPALIVE", CURLOPT_TCP_KEEPALIVE, 0);
    }
}

fn ftp_setopts(config: *OperationConfig, curl: ?*CURL, use_proto: ?[*:0]const u8) CURLcode {
    var result: CURLcode = CURLE_OK;

    if (use_proto != proto_ftp and use_proto != proto_ftps) {
        return CURLE_OK;
    }

    result = tool_setopt_str(curl, config, "CURLOPT_FTPPORT", CURLOPT_FTPPORT, config.ftpport);
    if (setopt_bad(result)) return result;

    if (config.disable_epsv) {
        _ = tool_setopt_long(curl, "CURLOPT_FTP_USE_EPSV", CURLOPT_FTP_USE_EPSV, 0);
    }
    if (config.disable_eprt) {
        _ = tool_setopt_long(curl, "CURLOPT_FTP_USE_EPRT", CURLOPT_FTP_USE_EPRT, 0);
    }
    if (config.ftp_ssl_ccc) {
        _ = tool_setopt_enum(curl, "CURLOPT_FTP_SSL_CCC", CURLOPT_FTP_SSL_CCC, &setopt_nv_CURLFTPSSL_CCC, config.ftp_ssl_ccc_mode);
    }

    result = tool_setopt_str(curl, config, "CURLOPT_FTP_ACCOUNT", CURLOPT_FTP_ACCOUNT, config.ftp_account);
    if (setopt_bad(result)) return result;

    _ = tool_setopt_long(curl, "CURLOPT_FTP_SKIP_PASV_IP", CURLOPT_FTP_SKIP_PASV_IP, if (config.ftp_skip_ip) 1 else 0);
    _ = tool_setopt_long(curl, "CURLOPT_FTP_FILEMETHOD", CURLOPT_FTP_FILEMETHOD, config.ftp_filemethod);

    result = tool_setopt_str(curl, config, "CURLOPT_FTP_ALTERNATIVE_TO_USER", CURLOPT_FTP_ALTERNATIVE_TO_USER, config.ftp_alternative_to_user);
    if (setopt_bad(result)) return result;

    if (config.ftp_pret) {
        _ = tool_setopt_long(curl, "CURLOPT_FTP_USE_PRET", CURLOPT_FTP_USE_PRET, 1);
    }

    return result;
}

fn gen_trace_setopts(config: *OperationConfig, curl: ?*CURL) void {
    if (global != null and global.?.tracetype != TRACE_NONE) {
        _ = tool_setopt_ptr(curl, "CURLOPT_DEBUGFUNCTION", CURLOPT_DEBUGFUNCTION, @as(?*const anyopaque, @ptrCast(&tool_debug_cb)));
        _ = tool_setopt_ptr(curl, "CURLOPT_DEBUGDATA", CURLOPT_DEBUGDATA, @as(?*const anyopaque, @ptrCast(config)));
        _ = tool_setopt_long(curl, "CURLOPT_VERBOSE", CURLOPT_VERBOSE, 1);
    }
}

fn gen_cb_setopts(config: *OperationConfig, per: *per_transfer, curl: ?*CURL) void {
    _ = config;
    _ = tool_setopt_ptr(curl, "CURLOPT_WRITEDATA", CURLOPT_WRITEDATA, @as(?*const anyopaque, @ptrCast(per)));
    _ = tool_setopt_ptr(curl, "CURLOPT_INTERLEAVEDATA", CURLOPT_INTERLEAVEDATA, @as(?*const anyopaque, @ptrCast(per)));
    _ = tool_setopt_ptr(curl, "CURLOPT_WRITEFUNCTION", CURLOPT_WRITEFUNCTION, @as(?*const anyopaque, @ptrCast(&tool_write_cb)));
    _ = tool_setopt_ptr(curl, "CURLOPT_READDATA", CURLOPT_READDATA, @as(?*const anyopaque, @ptrCast(per)));
    _ = tool_setopt_ptr(curl, "CURLOPT_READFUNCTION", CURLOPT_READFUNCTION, @as(?*const anyopaque, @ptrCast(&tool_read_cb)));
    _ = tool_setopt_ptr(curl, "CURLOPT_SEEKDATA", CURLOPT_SEEKDATA, @as(?*const anyopaque, @ptrCast(per)));
    _ = tool_setopt_ptr(curl, "CURLOPT_SEEKFUNCTION", CURLOPT_SEEKFUNCTION, @as(?*const anyopaque, @ptrCast(&tool_seek_cb)));

    if (global != null and global.?.progressmode == CURL_PROGRESS_BAR and !global.?.noprogress and !global.?.silent) {
        _ = tool_setopt_ptr(curl, "CURLOPT_XFERINFOFUNCTION", CURLOPT_XFERINFOFUNCTION, @as(?*const anyopaque, @ptrCast(&tool_progress_cb)));
        _ = tool_setopt_ptr(curl, "CURLOPT_XFERINFODATA", CURLOPT_XFERINFODATA, @as(?*const anyopaque, @ptrCast(per)));
    } else if (per.uploadfile != null and strcmp(per.uploadfile.?, ".") == 0) {
        _ = tool_setopt_long(curl, "CURLOPT_NOPROGRESS", CURLOPT_NOPROGRESS, 0);
        _ = tool_setopt_ptr(curl, "CURLOPT_XFERINFOFUNCTION", CURLOPT_XFERINFOFUNCTION, @as(?*const anyopaque, @ptrCast(&tool_readbusy_cb)));
        _ = tool_setopt_ptr(curl, "CURLOPT_XFERINFODATA", CURLOPT_XFERINFODATA, @as(?*const anyopaque, @ptrCast(per)));
    }

    _ = tool_setopt_ptr(curl, "CURLOPT_HEADERFUNCTION", CURLOPT_HEADERFUNCTION, @as(?*const anyopaque, @ptrCast(&tool_header_cb)));
    _ = tool_setopt_ptr(curl, "CURLOPT_HEADERDATA", CURLOPT_HEADERDATA, @as(?*const anyopaque, @ptrCast(per)));
}

fn proxy_setopts(config: *OperationConfig, curl: ?*CURL) CURLcode {
    var result: CURLcode = CURLE_OK;
    if (config.proxy) |proxy| {
        result = tool_setopt_str(curl, config, "CURLOPT_PROXY", CURLOPT_PROXY, proxy);
        if (result != CURLE_OK) {
            errorf("proxy support is disabled in this libcurl");
            config.synthetic_error = true;
            return CURLE_NOT_BUILT_IN;
        }
    }

    if (config.proxy != null) {
        _ = tool_setopt_enum(curl, "CURLOPT_PROXYTYPE", CURLOPT_PROXYTYPE, &setopt_nv_CURLPROXY, config.proxyver);
    }

    result = tool_setopt_str(curl, config, "CURLOPT_PROXYUSERPWD", CURLOPT_PROXYUSERPWD, config.proxyuserpwd);
    if (setopt_bad(result)) return result;

    _ = tool_setopt_long(curl, "CURLOPT_HTTPPROXYTUNNEL", CURLOPT_HTTPPROXYTUNNEL, if (config.proxytunnel) 1 else 0);

    if (config.preproxy) |preproxy| {
        result = tool_setopt_str(curl, config, "CURLOPT_PRE_PROXY", CURLOPT_PRE_PROXY, preproxy);
        if (setopt_bad(result)) return result;
    }

    if (config.proxyanyauth) {
        _ = tool_setopt_bitmask(curl, "CURLOPT_PROXYAUTH", CURLOPT_PROXYAUTH, &setopt_nv_CURLAUTH, @bitCast(CURLAUTH_ANY));
    } else if (config.proxynegotiate) {
        _ = tool_setopt_bitmask(curl, "CURLOPT_PROXYAUTH", CURLOPT_PROXYAUTH, &setopt_nv_CURLAUTH, @bitCast(CURLAUTH_GSSNEGOTIATE));
    } else if (config.proxyntlm) {
        _ = tool_setopt_bitmask(curl, "CURLOPT_PROXYAUTH", CURLOPT_PROXYAUTH, &setopt_nv_CURLAUTH, @bitCast(CURLAUTH_NTLM));
    } else if (config.proxydigest) {
        _ = tool_setopt_bitmask(curl, "CURLOPT_PROXYAUTH", CURLOPT_PROXYAUTH, &setopt_nv_CURLAUTH, @bitCast(CURLAUTH_DIGEST));
    } else if (config.proxybasic) {
        _ = tool_setopt_bitmask(curl, "CURLOPT_PROXYAUTH", CURLOPT_PROXYAUTH, &setopt_nv_CURLAUTH, @bitCast(CURLAUTH_BASIC));
    }

    result = tool_setopt_str(curl, config, "CURLOPT_NOPROXY", CURLOPT_NOPROXY, config.noproxy);
    if (setopt_bad(result)) return result;

    _ = tool_setopt_long(curl, "CURLOPT_SUPPRESS_CONNECT_HEADERS", CURLOPT_SUPPRESS_CONNECT_HEADERS, if (config.suppress_connect_headers) 1 else 0);

    if (config.proxy_service_name) |proxy_service_name| {
        result = tool_setopt_str(curl, config, "CURLOPT_PROXY_SERVICE_NAME", CURLOPT_PROXY_SERVICE_NAME, proxy_service_name);
        if (setopt_bad(result)) return result;
    }

    if (config.haproxy_protocol) {
        _ = tool_setopt_long(curl, "CURLOPT_HAPROXYPROTOCOL", CURLOPT_HAPROXYPROTOCOL, 1);
    }

    if (config.haproxy_clientip) |haproxy_clientip| {
        result = tool_setopt_str(curl, config, "CURLOPT_HAPROXY_CLIENT_IP", CURLOPT_HAPROXY_CLIENT_IP, haproxy_clientip);
        if (setopt_bad(result)) return result;
    }

    result = tool_setopt_str(curl, config, "CURLOPT_PROXY_KEYPASSWD", CURLOPT_PROXY_KEYPASSWD, config.proxy_key_passwd);
    if (setopt_bad(result)) return result;

    return result;
}

fn check_post_resume(config: *OperationConfig) CURLcode {
    if (config.use_resume and (config.resume_from != 0 or config.resume_from_current)) {
        errorf("(%d) HTTP upload cannot be resumed", @as(c_int, @intCast(CURLE_BAD_FUNCTION_ARGUMENT)));
        config.synthetic_error = true;
        return CURLE_BAD_FUNCTION_ARGUMENT;
    }
    return CURLE_OK;
}

fn setopt_post(config: *OperationConfig, curl: ?*CURL) CURLcode {
    var result: CURLcode = CURLE_OK;
    switch (config.httpreq) {
        TOOL_HTTPREQ_SIMPLEPOST => {
            result = check_post_resume(config);
            if (result == CURLE_OK) {
                result = tool_setopt_str(curl, config, "CURLOPT_POSTFIELDS", CURLOPT_POSTFIELDS, curlx_dyn_ptr(&config.postdata));
                if (setopt_bad(result)) return result;
                _ = tool_setopt_offt(curl, "CURLOPT_POSTFIELDSIZE_LARGE", CURLOPT_POSTFIELDSIZE_LARGE, @intCast(curlx_dyn_len(&config.postdata)));
            }
        },
        TOOL_HTTPREQ_MIMEPOST => {
            curl_mime_free(config.mimepost);
            config.mimepost = null;
            result = check_post_resume(config);
            if (result == CURLE_OK) {
                result = tool2curlmime(curl, config.mimeroot, &config.mimepost);
                if (result == CURLE_OK) {
                    result = tool_setopt_mimepost(curl, config, "CURLOPT_MIMEPOST", CURLOPT_MIMEPOST, config.mimepost);
                }
            }
        },
        else => {},
    }
    return result;
}

fn buffersize(config: *OperationConfig, curl: ?*CURL) void {
    if (config.recvpersecond != 0 and config.recvpersecond < BUFFER_SIZE) {
        _ = tool_setopt_long(curl, "CURLOPT_BUFFERSIZE", CURLOPT_BUFFERSIZE, @intCast(config.recvpersecond));
    } else {
        _ = tool_setopt_long(curl, "CURLOPT_BUFFERSIZE", CURLOPT_BUFFERSIZE, BUFFER_SIZE);
    }
}

fn credentials_and_headers_setopts(config: *OperationConfig, curl: ?*CURL) CURLcode {
    var result: CURLcode = CURLE_OK;

    result = tool_setopt_str(curl, config, "CURLOPT_XOAUTH2_BEARER", CURLOPT_XOAUTH2_BEARER, config.oauth_bearer);
    if (setopt_bad(result)) return result;

    if (config.netrc_opt) {
        _ = tool_setopt_enum(curl, "CURLOPT_NETRC", CURLOPT_NETRC, &setopt_nv_CURL_NETRC, CURL_NETRC_OPTIONAL);
    } else if (config.netrc or config.netrc_file != null) {
        _ = tool_setopt_enum(curl, "CURLOPT_NETRC", CURLOPT_NETRC, &setopt_nv_CURL_NETRC, CURL_NETRC_REQUIRED);
    } else {
        _ = tool_setopt_enum(curl, "CURLOPT_NETRC", CURLOPT_NETRC, &setopt_nv_CURL_NETRC, CURL_NETRC_IGNORED);
    }

    result = tool_setopt_str(curl, config, "CURLOPT_NETRC_FILE", CURLOPT_NETRC_FILE, config.netrc_file);
    if (setopt_bad(result)) return result;

    result = tool_setopt_str(curl, config, "CURLOPT_LOGIN_OPTIONS", CURLOPT_LOGIN_OPTIONS, config.login_options);
    if (setopt_bad(result)) return result;

    result = tool_setopt_str(curl, config, "CURLOPT_USERPWD", CURLOPT_USERPWD, config.userpwd);
    if (setopt_bad(result)) return result;

    if (config.authtype != 0) {
        _ = tool_setopt_bitmask(curl, "CURLOPT_HTTPAUTH", CURLOPT_HTTPAUTH, &setopt_nv_CURLAUTH, @bitCast(config.authtype));
    }

    _ = tool_setopt_slist(curl, "CURLOPT_HTTPHEADER", CURLOPT_HTTPHEADER, config.headers);

    if (proto_http != null or proto_rtsp != null) {
        result = tool_setopt_str(curl, config, "CURLOPT_REFERER", CURLOPT_REFERER, config.referer);
        if (setopt_bad(result)) return result;

        result = tool_setopt_str(curl, config, "CURLOPT_USERAGENT", CURLOPT_USERAGENT, if (config.useragent) |ua| ua else CURL_USERAGENT_DEFAULT);
        if (setopt_bad(result)) return result;
    }

    result = tool_setopt_str(curl, config, "CURLOPT_KEYPASSWD", CURLOPT_KEYPASSWD, config.key_passwd);
    if (setopt_bad(result)) return result;

    return result;
}

fn transfer_setopts(config: *OperationConfig, per: *per_transfer, curl: ?*CURL) CURLcode {
    var result: CURLcode = CURLE_OK;

    _ = tool_setopt_long(curl, "CURLOPT_NOBODY", CURLOPT_NOBODY, if (config.no_body) 1 else 0);
    _ = tool_setopt_long(curl, "CURLOPT_FAILONERROR", CURLOPT_FAILONERROR, if (config.fail == FAIL_WO_BODY) 1 else 0);

    result = tool_setopt_str(curl, config, "CURLOPT_REQUEST_TARGET", CURLOPT_REQUEST_TARGET, config.request_target);
    if (setopt_bad(result)) return result;

    _ = tool_setopt_long(curl, "CURLOPT_UPLOAD", CURLOPT_UPLOAD, if (per.uploadfile != null) 1 else 0);
    _ = tool_setopt_long(curl, "CURLOPT_DIRLISTONLY", CURLOPT_DIRLISTONLY, if (config.dirlistonly) 1 else 0);
    _ = tool_setopt_long(curl, "CURLOPT_APPEND", CURLOPT_APPEND, if (config.ftp_append) 1 else 0);
    _ = tool_setopt_long(curl, "CURLOPT_TRANSFERTEXT", CURLOPT_TRANSFERTEXT, if (config.use_ascii) 1 else 0);

    result = tool_setopt_str(curl, config, "CURLOPT_RANGE", CURLOPT_RANGE, config.range);
    if (setopt_bad(result)) return result;

    _ = tool_setopt_ptr(curl, "CURLOPT_ERRORBUFFER", CURLOPT_ERRORBUFFER, @as(?*const anyopaque, @ptrCast(&per.errorbuffer)));
    _ = tool_setopt_long(curl, "CURLOPT_TIMEOUT_MS", CURLOPT_TIMEOUT_MS, config.timeout_ms);

    result = setopt_post(config, curl);
    if (result != CURLE_OK) return result;

    if (config.mime_options != 0) {
        _ = tool_setopt_long(curl, "CURLOPT_MIME_OPTIONS", CURLOPT_MIME_OPTIONS, @bitCast(config.mime_options));
    }

    _ = tool_setopt_long(curl, "CURLOPT_LOW_SPEED_LIMIT", CURLOPT_LOW_SPEED_LIMIT, config.low_speed_limit);
    _ = tool_setopt_long(curl, "CURLOPT_LOW_SPEED_TIME", CURLOPT_LOW_SPEED_TIME, config.low_speed_time);
    _ = tool_setopt_offt(curl, "CURLOPT_MAX_SEND_SPEED_LARGE", CURLOPT_MAX_SEND_SPEED_LARGE, config.sendpersecond);
    _ = tool_setopt_offt(curl, "CURLOPT_MAX_RECV_SPEED_LARGE", CURLOPT_MAX_RECV_SPEED_LARGE, config.recvpersecond);

    if (config.use_resume) {
        _ = tool_setopt_offt(curl, "CURLOPT_RESUME_FROM_LARGE", CURLOPT_RESUME_FROM_LARGE, config.resume_from);
    } else {
        _ = tool_setopt_offt(curl, "CURLOPT_RESUME_FROM_LARGE", CURLOPT_RESUME_FROM_LARGE, 0);
    }

    if (config.path_as_is) {
        _ = tool_setopt_long(curl, "CURLOPT_PATH_AS_IS", CURLOPT_PATH_AS_IS, 1);
    }

    if (config.no_body or config.remote_time) {
        _ = tool_setopt_long(curl, "CURLOPT_FILETIME", CURLOPT_FILETIME, 1);
    }

    _ = tool_setopt_long(curl, "CURLOPT_CRLF", CURLOPT_CRLF, if (config.crlf) 1 else 0);
    _ = tool_setopt_slist(curl, "CURLOPT_QUOTE", CURLOPT_QUOTE, config.quote);
    _ = tool_setopt_slist(curl, "CURLOPT_POSTQUOTE", CURLOPT_POSTQUOTE, config.postquote);
    _ = tool_setopt_slist(curl, "CURLOPT_PREQUOTE", CURLOPT_PREQUOTE, config.prequote);

    _ = tool_setopt_enum(curl, "CURLOPT_TIMECONDITION", CURLOPT_TIMECONDITION, &setopt_nv_CURL_TIMECOND, @bitCast(config.timecond));
    _ = tool_setopt_offt(curl, "CURLOPT_TIMEVALUE_LARGE", CURLOPT_TIMEVALUE_LARGE, config.condtime);

    result = tool_setopt_str(curl, config, "CURLOPT_CUSTOMREQUEST", CURLOPT_CUSTOMREQUEST, config.customrequest);
    if (setopt_bad(result)) return result;

    customrequest_helper(config.httpreq, config.customrequest);

    return result;
}

fn protocol_setopts(config: *OperationConfig, per: *per_transfer, curl: ?*CURL, use_proto: ?[*:0]const u8) CURLcode {
    _ = per;
    var result = http_setopts(config, curl, use_proto);
    if (result == CURLE_OK) {
        result = ftp_setopts(config, curl, use_proto);
    }
    if (result != CURLE_OK) return result;

    result = ssh_setopts(config, curl);
    if (setopt_bad(result)) return result;

    if (feature_ssl) {
        result = ssl_ca_setopts(config, curl);
        if (result == CURLE_OK) {
            result = ssl_setopts(config, curl);
        }
        if (setopt_bad(result)) return result;
    }

    return result;
}

fn dns_and_network_setopts(config: *OperationConfig, per: *per_transfer, curl: ?*CURL) CURLcode {
    var result: CURLcode = CURLE_OK;

    result = tool_setopt_str(curl, config, "CURLOPT_INTERFACE", CURLOPT_INTERFACE, config.iface);
    if (setopt_bad(result)) return result;

    progressbarinit(&per.progressbar, config);

    result = tool_setopt_str(curl, config, "CURLOPT_DNS_SERVERS", CURLOPT_DNS_SERVERS, config.dns_servers);
    if (setopt_bad(result)) return result;

    result = tool_setopt_str(curl, config, "CURLOPT_DNS_INTERFACE", CURLOPT_DNS_INTERFACE, config.dns_interface);
    if (setopt_bad(result)) return result;

    result = tool_setopt_str(curl, config, "CURLOPT_DNS_LOCAL_IP4", CURLOPT_DNS_LOCAL_IP4, config.dns_ipv4_addr);
    if (setopt_bad(result)) return result;

    result = tool_setopt_str(curl, config, "CURLOPT_DNS_LOCAL_IP6", CURLOPT_DNS_LOCAL_IP6, config.dns_ipv6_addr);
    if (setopt_bad(result)) return result;

    _ = tool_setopt_slist(curl, "CURLOPT_TELNETOPTIONS", CURLOPT_TELNETOPTIONS, config.telnet_options);
    _ = tool_setopt_long(curl, "CURLOPT_CONNECTTIMEOUT_MS", CURLOPT_CONNECTTIMEOUT_MS, config.connecttimeout_ms);

    result = tool_setopt_str(curl, config, "CURLOPT_DOH_URL", CURLOPT_DOH_URL, config.doh_url);
    if (setopt_bad(result)) return result;

    _ = tool_setopt_long(curl, "CURLOPT_FTP_CREATE_MISSING_DIRS", CURLOPT_FTP_CREATE_MISSING_DIRS, if (config.ftp_create_dirs) CURLFTP_CREATE_DIR_RETRY else CURLFTP_CREATE_DIR_NONE);
    _ = tool_setopt_offt(curl, "CURLOPT_MAXFILESIZE_LARGE", CURLOPT_MAXFILESIZE_LARGE, config.max_filesize);
    _ = tool_setopt_long(curl, "CURLOPT_IPRESOLVE", CURLOPT_IPRESOLVE, config.ip_version);

    if (config.socks5_gssapi_nec) {
        _ = tool_setopt_long(curl, "CURLOPT_SOCKS5_GSSAPI_NEC", CURLOPT_SOCKS5_GSSAPI_NEC, 1);
    }
    if (config.socks5_auth != 0) {
        _ = tool_setopt_bitmask(curl, "CURLOPT_SOCKS5_AUTH", CURLOPT_SOCKS5_AUTH, &setopt_nv_CURLAUTH, @bitCast(config.socks5_auth));
    }

    result = tool_setopt_str(curl, config, "CURLOPT_SERVICE_NAME", CURLOPT_SERVICE_NAME, config.service_name);
    if (setopt_bad(result)) return result;

    _ = tool_setopt_long(curl, "CURLOPT_IGNORE_CONTENT_LENGTH", CURLOPT_IGNORE_CONTENT_LENGTH, if (config.ignorecl) 1 else 0);

    if (config.localport != 0) {
        _ = tool_setopt_long(curl, "CURLOPT_LOCALPORT", CURLOPT_LOCALPORT, @intCast(config.localport));
        _ = tool_setopt_long(curl, "CURLOPT_LOCALPORTRANGE", CURLOPT_LOCALPORTRANGE, @intCast(config.localportrange));
    }

    if (config.raw) {
        _ = tool_setopt_long(curl, "CURLOPT_HTTP_CONTENT_DECODING", CURLOPT_HTTP_CONTENT_DECODING, 0);
        _ = tool_setopt_long(curl, "CURLOPT_HTTP_TRANSFER_DECODING", CURLOPT_HTTP_TRANSFER_DECODING, 0);
    }

    tcp_setopts(config, curl);

    if (config.tftp_blksize != 0 and proto_tftp != null) {
        _ = tool_setopt_long(curl, "CURLOPT_TFTP_BLKSIZE", CURLOPT_TFTP_BLKSIZE, config.tftp_blksize);
    }

    return result;
}

fn mail_and_sasl_setopts(config: *OperationConfig, curl: ?*CURL) CURLcode {
    var result: CURLcode = CURLE_OK;

    result = tool_setopt_str(curl, config, "CURLOPT_MAIL_FROM", CURLOPT_MAIL_FROM, config.mail_from);
    if (setopt_bad(result)) return result;

    _ = tool_setopt_slist(curl, "CURLOPT_MAIL_RCPT", CURLOPT_MAIL_RCPT, config.mail_rcpt);
    _ = tool_setopt_long(curl, "CURLOPT_MAIL_RCPT_ALLOWFAILS", CURLOPT_MAIL_RCPT_ALLOWFAILS, if (config.mail_rcpt_allowfails) 1 else 0);

    result = tool_setopt_str(curl, config, "CURLOPT_MAIL_AUTH", CURLOPT_MAIL_AUTH, config.mail_auth);
    if (setopt_bad(result)) return result;

    result = tool_setopt_str(curl, config, "CURLOPT_SASL_AUTHZID", CURLOPT_SASL_AUTHZID, config.sasl_authzid);
    if (setopt_bad(result)) return result;

    _ = tool_setopt_long(curl, "CURLOPT_SASL_IR", CURLOPT_SASL_IR, if (config.sasl_ir) 1 else 0);

    if (config.create_file_mode != 0) {
        _ = tool_setopt_long(curl, "CURLOPT_NEW_FILE_PERMS", CURLOPT_NEW_FILE_PERMS, @intCast(config.create_file_mode));
    }

    return result;
}

fn misc_setopts(config: *OperationConfig, curl: ?*CURL) CURLcode {
    var result: CURLcode = CURLE_OK;

    _ = tool_setopt_ptr(curl, "CURLOPT_STDERR", CURLOPT_STDERR, @as(?*const anyopaque, @ptrCast(tool_stderr)));
    if (config.resolve != null) {
        _ = tool_setopt_slist(curl, "CURLOPT_RESOLVE", CURLOPT_RESOLVE, config.resolve);
    }
    if (config.connect_to != null) {
        _ = tool_setopt_slist(curl, "CURLOPT_CONNECT_TO", CURLOPT_CONNECT_TO, config.connect_to);
    }

    if (config.gssapi_delegation != 0) {
        _ = tool_setopt_long(curl, "CURLOPT_GSSAPI_DELEGATION", CURLOPT_GSSAPI_DELEGATION, config.gssapi_delegation);
    }

    if (config.proto_present) {
        result = tool_setopt_str(curl, config, "CURLOPT_PROTOCOLS_STR", CURLOPT_PROTOCOLS_STR, config.proto_str);
        if (setopt_bad(result)) return result;
    }
    if (config.proto_redir_present) {
        result = tool_setopt_str(curl, config, "CURLOPT_REDIR_PROTOCOLS_STR", CURLOPT_REDIR_PROTOCOLS_STR, config.proto_redir_str);
        if (setopt_bad(result)) return result;
    }

    if (config.gssapi_delegation != 0) {
        _ = tool_setopt_long(curl, "CURLOPT_GSSAPI_DELEGATION", CURLOPT_GSSAPI_DELEGATION, config.gssapi_delegation);
    }

    result = tool_setopt_str(curl, config, "CURLOPT_MAIL_AUTH", CURLOPT_MAIL_AUTH, config.mail_auth);
    if (setopt_bad(result)) return result;

    result = tool_setopt_str(curl, config, "CURLOPT_SASL_AUTHZID", CURLOPT_SASL_AUTHZID, config.sasl_authzid);
    if (setopt_bad(result)) return result;

    _ = tool_setopt_long(curl, "CURLOPT_SASL_IR", CURLOPT_SASL_IR, if (config.sasl_ir) 1 else 0);

    if (config.unix_socket_path) |unix_socket_path| {
        if (config.abstract_unix_socket) {
            result = tool_setopt_str(curl, config, "CURLOPT_ABSTRACT_UNIX_SOCKET", CURLOPT_ABSTRACT_UNIX_SOCKET, unix_socket_path);
        } else {
            result = tool_setopt_str(curl, config, "CURLOPT_UNIX_SOCKET_PATH", CURLOPT_UNIX_SOCKET_PATH, unix_socket_path);
        }
        if (setopt_bad(result)) return result;
    }

    result = tool_setopt_str(curl, config, "CURLOPT_DEFAULT_PROTOCOL", CURLOPT_DEFAULT_PROTOCOL, config.proto_default);
    if (setopt_bad(result)) return result;

    _ = tool_setopt_long(curl, "CURLOPT_TFTP_NO_OPTIONS", CURLOPT_TFTP_NO_OPTIONS, if (config.tftp_no_options and proto_tftp != null) 1 else 0);

    if (config.happy_eyeballs_timeout_ms != CURL_HET_DEFAULT) {
        _ = tool_setopt_long(curl, "CURLOPT_HAPPY_EYEBALLS_TIMEOUT_MS", CURLOPT_HAPPY_EYEBALLS_TIMEOUT_MS, config.happy_eyeballs_timeout_ms);
    }

    _ = tool_setopt_long(curl, "CURLOPT_DISALLOW_USERNAME_IN_URL", CURLOPT_DISALLOW_USERNAME_IN_URL, if (config.disallow_username_in_url) 1 else 0);

    if (config.ip_tos > 0 or config.vlan_priority > 0) {
        if (!is_windows and (!builtin.os.tag.isDarwin() or config.vlan_priority == 0)) {
            _ = tool_setopt_ptr(curl, "CURLOPT_SOCKOPTFUNCTION", CURLOPT_SOCKOPTFUNCTION, @as(?*const anyopaque, @ptrCast(&sockopt_callback)));
            _ = tool_setopt_ptr(curl, "CURLOPT_SOCKOPTDATA", CURLOPT_SOCKOPTDATA, @as(?*const anyopaque, @ptrCast(config)));
        } else {
            if (is_windows and config.ip_tos > 0) {
                errorf("Type of service is not supported in this build.");
                result = CURLE_NOT_BUILT_IN;
            }
            if ((is_windows or builtin.os.tag.isDarwin()) and config.vlan_priority > 0) {
                errorf("VLAN priority is not supported in this build.");
                result = CURLE_NOT_BUILT_IN;
            }
        }
    }
    if (result == CURLE_OK) {
        _ = tool_setopt_long(curl, "CURLOPT_UPLOAD_FLAGS", CURLOPT_UPLOAD_FLAGS, @intCast(config.upload_flags));
    }

    return result;
}

pub export fn config2setopts(config: *OperationConfig, per: *per_transfer, curl: ?*CURL, share: ?*CURLSH) callconv(.c) CURLcode {
    var use_proto: ?[*:0]const u8 = null;
    var result = url_proto_and_rewrite(&per.url, config, &use_proto);

    if (result == CURLE_OK) {
        result = curl_easy_setopt(curl, CURLOPT_SHARE, share);
    }
    if (result != CURLE_OK) return result;

    result = curl_easy_setopt(curl, CURLOPT_QUICK_EXIT, @as(c_long, 1));
    if (result != CURLE_OK) return result;

    gen_trace_setopts(config, curl);

    buffersize(config, curl);

    result = tool_setopt_str(curl, config, "CURLOPT_URL", CURLOPT_URL, per.url);
    if (setopt_bad(result)) return result;

    _ = tool_setopt_long(curl, "CURLOPT_NOPROGRESS", CURLOPT_NOPROGRESS, if (global != null and (global.?.noprogress or global.?.silent)) 1 else 0);
    gen_cb_setopts(config, per, curl);

    result = proxy_setopts(config, curl);
    if (setopt_bad(result) or config.synthetic_error) return result;

    result = credentials_and_headers_setopts(config, curl);
    if (!setopt_bad(result)) {
        result = transfer_setopts(config, per, curl);
    }
    if (!setopt_bad(result)) {
        result = protocol_setopts(config, per, curl, use_proto);
    }
    if (!setopt_bad(result)) {
        result = dns_and_network_setopts(config, per, curl);
    }
    if (!setopt_bad(result)) {
        result = mail_and_sasl_setopts(config, curl);
    }
    if (!setopt_bad(result)) {
        result = misc_setopts(config, curl);
    }

    if (result == CURLE_OK and config.synthetic_error) {
        result = CURLE_FAILED_INIT;
    }

    return result;
}

// ============================================================================
// Part 4a: src/tool_operate.c (operate, single_transfer, parallel/serial, etc.)
// ============================================================================

const CURL_CA_CERT_ERRORMSG: [*:0]const u8 =
    "More details here: https://curl.se/docs/sslcerts.html\n\n" ++
    "curl failed to verify the legitimacy of the server and therefore " ++
    "could not\nestablish a secure connection to it. To learn more about " ++
    "this situation and\nhow to fix it, please visit the webpage mentioned " ++
    "above.\n";

const SEEK_END_VAL: c_int = 2;
const LC_ALL_VAL: c_int = if (is_windows) 0 else if (builtin.os.tag.isDarwin()) 0 else 6;
const LC_NUMERIC_VAL: c_int = if (is_windows) 4 else if (builtin.os.tag.isDarwin()) 4 else 1;

fn is_fatal_error(code: CURLcode) bool {
    return switch (code) {
        CURLE_FAILED_INIT,
        CURLE_OUT_OF_MEMORY,
        CURLE_UNKNOWN_OPTION,
        CURLE_BAD_FUNCTION_ARGUMENT,
        => true,
        else => false,
    };
}

fn is_pkcs11_uri(string: ?[*:0]const u8) bool {
    const s = string orelse return false;
    return curl_strnequal(s, "pkcs11:", 7) != 0;
}

fn add_per_transfer(per: *?*per_transfer) CURLcode {
    const raw = Curl_ccalloc(1, @sizeOf(per_transfer)) orelse return CURLE_OUT_OF_MEMORY;
    const p: *per_transfer = @ptrCast(@alignCast(raw));
    if (transfers == null) {
        transfers_l = p;
        transfers = p;
    } else {
        transfers_l.?.next = p;
        p.prev = transfers_l;
        transfers_l = p;
    }
    per.* = p;
    return CURLE_OK;
}

fn del_per_transfer(per: *per_transfer) ?*per_transfer {
    const n = per.next;
    const p = per.prev;
    if (p) |prev| {
        prev.next = n;
    } else {
        transfers = n;
    }
    if (n) |next| {
        next.prev = p;
    } else {
        transfers_l = p;
    }
    Curl_cfree(per.uploadfile);
    Curl_cfree(per.outfile);
    Curl_cfree(per.url);
    curl_easy_cleanup(per.curl);
    Curl_cfree(per);
    return n;
}

fn pre_transfer(per: *per_transfer) CURLcode {
    var uploadfilesize: curl_off_t = -1;
    var fileinfo: ToolStat = undefined;

    if (per.uploadfile != null and !stdin_upload(per.uploadfile.?)) {
        per.infd = toolOpen(per.uploadfile.?, O_RDONLY_VAL | O_BINARY_VAL, 0);
        if (per.infd == -1 or toolFstat(per.infd, &fileinfo) != 0) {
            helpf("cannot open '%s'", per.uploadfile.?);
            if (per.infd != -1) {
                _ = toolClose(per.infd);
                per.infd = 0; // STDIN_FILENO
            }
            return CURLE_READ_ERROR;
        }
        per.infdopen = true;

        if (fileinfo.is_reg) {
            uploadfilesize = fileinfo.size;
        }

        if (uploadfilesize != -1) {
            _ = tool_setopt_offt(per.curl, "CURLOPT_INFILESIZE_LARGE", CURLOPT_INFILESIZE_LARGE, uploadfilesize);
        }
    }
    per.uploadfilesize = uploadfilesize;
    per.start = curlx_now();
    return CURLE_OK;
}

pub export fn single_transfer_cleanup() callconv(.c) void {
    if (global) |g| {
        const state = &g.state;
        glob_cleanup(&state.urlglob);
        Curl_cfree(state.uploadfile);
        state.uploadfile = null;
        glob_cleanup(&state.inglob);
    }
}

fn is_outfile_auto_resumable(config: *OperationConfig, per: *per_transfer, result: CURLcode) bool {
    const outs = &per.outs;
    return config.use_resume and config.resume_from_current and
        config.resume_from >= 0 and outs.init == config.resume_from and
        outs.bytes > 0 and outs.filename != null and outs.regular_file and outs.fopened and
        outs.stream != null and ferror(outs.stream) == 0 and
        config.customrequest == null and per.uploadfile == null and
        (config.httpreq == TOOL_HTTPREQ_UNSPEC or config.httpreq == TOOL_HTTPREQ_GET) and
        result != CURLE_WRITE_ERROR and result != CURLE_RANGE_ERROR;
}

const RetryReason = enum(u8) {
    RETRY_NO = 0,
    RETRY_ALL_ERRORS = 1,
    RETRY_TIMEOUT = 2,
    RETRY_CONNREFUSED = 3,
    RETRY_HTTP = 4,
    RETRY_FTP = 5,
};

fn retry_sleep(config: *OperationConfig, per: *per_transfer, retry: RetryReason, retryp: *bool) u32 {
    const m = [_][*:0]const u8{
        "(retrying all errors)",
        ": timeout",
        ": connection refused",
        ": HTTP error",
        ": FTP error",
    };
    const curl = per.curl;
    var sleeptime: u32 = 0;
    if (retry == .RETRY_HTTP) {
        var retry_after: curl_off_t = 0;
        _ = curl_easy_getinfo(curl, CURLINFO_RETRY_AFTER, &retry_after);
        if (retry_after != 0) {
            if (retry_after > @as(curl_off_t, std.math.maxInt(u32) / 1000)) {
                sleeptime = std.math.maxInt(u32);
            } else {
                sleeptime = @as(u32, @intCast(retry_after)) * 1000;
            }
            if (config.retry_maxtime_ms != 0) {
                const ms = curlx_timediff_ms(curlx_now(), per.retrystart);
                if ((std.math.maxInt(curl_off_t) - @as(curl_off_t, sleeptime) < ms) or
                    (ms + @as(curl_off_t, sleeptime) > config.retry_maxtime_ms))
                {
                    warnf("The Retry-After: time would make this command line exceed the maximum allowed time for retries.");
                    retryp.* = false;
                    return 0;
                }
            }
        }
    }
    if (sleeptime == 0 and config.retry_delay_ms == 0) {
        if (per.retry_sleep == 0) {
            per.retry_sleep = RETRY_SLEEP_DEFAULT;
        } else {
            per.retry_sleep *= 2;
        }
        if (per.retry_sleep > RETRY_SLEEP_MAX) {
            per.retry_sleep = RETRY_SLEEP_MAX;
        }
    }
    if (sleeptime == 0) {
        sleeptime = per.retry_sleep;
    }

    const idx: usize = @backingInt(retry) - 1;
    const dot: [*:0]const u8 = if (sleeptime % 1000 != 0) "." else "";
    const plural_s: [*:0]const u8 = if (sleeptime == 1000) "" else "s";
    const plural_y: [*:0]const u8 = if (per.retry_remaining > 1) "ies" else "y";
    warnf(
        "Problem %s. Retrying in %u%s%.*u second%s. %ld retr%s left.",
        m[idx],
        sleeptime / 1000,
        dot,
        @as(c_int, if (sleeptime % 1000 != 0) 3 else 0),
        sleeptime % 1000,
        plural_s,
        per.retry_remaining,
        plural_y,
    );

    return sleeptime;
}

fn retrycheck(config: *OperationConfig, per: *per_transfer, result_in: CURLcode, retryp: *bool, delayms: *u32) CURLcode {
    var result = result_in;
    const curl = per.curl;
    const outs = &per.outs;
    var reason: RetryReason = .RETRY_NO;

    if (result == CURLE_OPERATION_TIMEDOUT or
        result == CURLE_COULDNT_RESOLVE_HOST or
        result == CURLE_COULDNT_RESOLVE_PROXY or
        result == CURLE_FTP_ACCEPT_TIMEOUT)
    {
        reason = .RETRY_TIMEOUT;
    } else if (config.retry_connrefused and result == CURLE_COULDNT_CONNECT) {
        var oserrno: c_long = 0;
        _ = curl_easy_getinfo(curl, CURLINFO_OS_ERRNO, &oserrno);
        const SOCKECONNREFUSED_VAL: c_long = if (is_windows) 10061 else if (builtin.os.tag.isDarwin()) 61 else 111;
        if (oserrno == SOCKECONNREFUSED_VAL) {
            reason = .RETRY_CONNREFUSED;
        }
    } else if (result == CURLE_OK or (config.fail != 0 and result == CURLE_HTTP_RETURNED_ERROR)) {
        var scheme: ?[*:0]const u8 = null;
        _ = curl_easy_getinfo(curl, CURLINFO_SCHEME, &scheme);
        scheme = proto_token(scheme);
        if (scheme == proto_http or scheme == proto_https) {
            var response: c_long = 0;
            _ = curl_easy_getinfo(curl, CURLINFO_RESPONSE_CODE, &response);
            switch (response) {
                408, 429, 500, 502, 503, 504, 522, 524 => reason = .RETRY_HTTP,
                else => {},
            }
        }
    } else if (result != CURLE_OK) {
        var scheme: ?[*:0]const u8 = null;
        var response: c_long = 0;
        _ = curl_easy_getinfo(curl, CURLINFO_RESPONSE_CODE, &response);
        _ = curl_easy_getinfo(curl, CURLINFO_SCHEME, &scheme);
        scheme = proto_token(scheme);
        if ((scheme == proto_ftp or scheme == proto_ftps) and @divTrunc(response, 100) == 4) {
            reason = .RETRY_FTP;
        }
    }

    if (result != CURLE_OK and reason == .RETRY_NO and config.retry_all_errors) {
        reason = .RETRY_ALL_ERRORS;
    }

    if (reason != .RETRY_NO) {
        var truncate = true;
        retryp.* = true;

        const sleeptime = retry_sleep(config, per, reason, retryp);
        if (!retryp.*) {
            return CURLE_OK;
        }
        per.retry_remaining -= 1;

        if (is_outfile_auto_resumable(config, per, result)) {
            var response: c_long = 0;
            var header: ?*curl_header = null;
            var method: ?[*:0]const u8 = null;
            var scheme: ?[*:0]const u8 = null;

            _ = curl_easy_getinfo(curl, CURLINFO_EFFECTIVE_METHOD, &method);
            _ = curl_easy_getinfo(curl, CURLINFO_RESPONSE_CODE, &response);
            _ = curl_easy_getinfo(curl, CURLINFO_SCHEME, &scheme);
            scheme = proto_token(scheme);

            if ((scheme == proto_http or scheme == proto_https) and
                method != null and strcmp(method.?, "GET") == 0 and
                ((response == 206 and config.resume_from != 0) or
                    (response == 200 and
                        curl_easy_header(curl, "Accept-Ranges", 0, CURLH_HEADER, -1, &header) == 0 and
                        header != null and strcmp(header.?.value, "bytes") == 0)))
            {
                notef("Keeping %" ++ "lld" ++ " bytes", outs.bytes);
                if (fflush(outs.stream) != 0) {
                    errorf("Failed to flush output file stream");
                    retryp.* = false;
                    return CURLE_WRITE_ERROR;
                }
                if (outs.bytes >= std.math.maxInt(curl_off_t) - outs.init) {
                    errorf("Exceeded maximum supported file size (%" ++ "lld" ++ " + %" ++ "lld" ++ ")", outs.init, outs.bytes);
                    retryp.* = false;
                    return CURLE_WRITE_ERROR;
                }
                truncate = false;
                outs.init += outs.bytes;
                outs.bytes = 0;
                config.resume_from = outs.init;
                _ = curl_easy_setopt(curl, CURLOPT_RESUME_FROM_LARGE, config.resume_from);
            }
        }

        if (truncate and outs.bytes != 0 and outs.filename != null and outs.stream != null) {
            var fileinfo: ToolStat = undefined;
            const fd = toolFileno(outs.stream);
            if (toolFstat(fd, &fileinfo) == 0 and fileinfo.is_reg) {
                _ = fflush(outs.stream);
                notef("Throwing away %" ++ "lld" ++ " bytes", outs.bytes);
                if (toolFtruncate(fd, outs.init) != 0) {
                    errorf("Failed to truncate file");
                    retryp.* = false;
                    return CURLE_WRITE_ERROR;
                }
                if (fseek(outs.stream, 0, SEEK_END_VAL) != 0) {
                    errorf("Failed seeking to end of file");
                    retryp.* = false;
                    return CURLE_WRITE_ERROR;
                }
                outs.bytes = 0;
            }
        }
        per.num_retries += 1;
        delayms.* = sleeptime;
        result = CURLE_OK;
    }
    return result;
}

fn post_check_result(per: *per_transfer, result: CURLcode) CURLcode {
    const config = per.config.?;
    const g = global.?;

    if (!config.synthetic_error and result != CURLE_OK and (!g.silent or g.showerror)) {
        const msg: [*:0]const u8 = @ptrCast(&per.errorbuffer);
        _ = curl_mfprintf(tool_stderr, "curl: (%d) %s\n", @as(c_int, @intCast(result)), if (msg[0] != 0) msg else curl_easy_strerror(result));
        if (result == CURLE_PEER_FAILED_VERIFICATION) {
            _ = fputs(CURL_CA_CERT_ERRORMSG, tool_stderr);
        }
    } else if (config.fail == FAIL_WITH_BODY) {
        var code: c_long = 0;
        _ = curl_easy_getinfo(per.curl, CURLINFO_RESPONSE_CODE, &code);
        if (code >= 400) {
            if (!g.silent or g.showerror) {
                _ = curl_mfprintf(tool_stderr, "curl: (%d) The requested URL returned error: %ld\n", @as(c_int, @intCast(CURLE_HTTP_RETURNED_ERROR)), code);
            }
            return CURLE_HTTP_RETURNED_ERROR;
        }
    }
    return result;
}

fn post_output_handling(per: *per_transfer, result: CURLcode) CURLcode {
    const outs = &per.outs;
    const config = per.config.?;
    const curl = per.curl;

    if (is_windows) {
        @memset(&outs.utf8seq, 0);
    }

    if (result == CURLE_OK and config.xattr and outs.fopened and outs.stream != null) {
        const rc = fwrite_xattr(curl, per.url, toolFileno(outs.stream), outs.filename);
        if (rc != 0) {
            var errbuf: [STRERROR_LEN]u8 = undefined;
            warnf("Error setting extended attributes on '%s': %s", if (outs.filename) |f| f else "", curlx_strerror(getErrno(), &errbuf, errbuf.len));
        }
    }

    if (result == CURLE_OK and outs.stream == null and outs.bytes == 0) {
        var cond_unmet: c_long = 0;
        _ = curl_easy_getinfo(curl, CURLINFO_CONDITION_UNMET, &cond_unmet);
        if (cond_unmet == 0 and !tool_create_output_file(outs, config)) {
            return CURLE_WRITE_ERROR;
        }
    }

    if (!outs.regular_file and outs.stream != null and !outs.out_null) {
        const rc = fflush(outs.stream);
        if (result == CURLE_OK and rc != 0) {
            errorf("Failed writing body");
            return CURLE_WRITE_ERROR;
        }
    }

    return result;
}

fn post_close_output(per: *per_transfer, result_in: CURLcode) CURLcode {
    var result = result_in;
    const outs = &per.outs;
    const config = per.config.?;

    if (outs.fopened and outs.stream != null) {
        const rc = fclose(outs.stream);
        outs.stream = null;
        outs.fopened = false;
        if (result == CURLE_OK and rc != 0) {
            result = CURLE_WRITE_ERROR;
            errorf("curl: (%d) Failed writing body", @as(c_int, @intCast(result)));
        }
        if (result != CURLE_OK and config.rm_partial and outs.filename != null) {
            var st: ToolStat = undefined;
            if (toolStat(outs.filename.?, &st) == 0 and st.is_reg) {
                if (toolUnlink(outs.filename.?) == 0) {
                    notef("Removed output file: %s", outs.filename.?);
                } else {
                    warnf("Failed removing: %s", outs.filename.?);
                }
            } else {
                warnf("Skipping removal; not a regular file: %s", outs.filename.?);
            }
        }
    }

    if (result == CURLE_OK and config.remote_time and outs.regular_file and outs.filename != null) {
        var filetime: curl_off_t = -1;
        _ = curl_easy_getinfo(per.curl, CURLINFO_FILETIME_T, &filetime);
        if (filetime != -1) {
            setfiletime(filetime, outs.filename.?);
        }
    }
    return result;
}

fn post_per_transfer(per: *per_transfer, result_in: CURLcode, retryp: *bool, delay: *u32) CURLcode {
    var result = result_in;
    const outs = &per.outs;
    const config = per.config;

    retryp.* = false;
    delay.* = 0;

    if (per.curl == null or config == null) {
        return result;
    }
    const cfg = config.?;

    if (is_windows and per.uploadfile != null) {
        if (strcmp(per.uploadfile.?, ".") == 0 and per.infd > 0) {
            const WinSockClose = struct {
                extern "ws2_32" fn closesocket(s: curl_socket_t) callconv(.winapi) c_int;
            };
            _ = WinSockClose.closesocket(@intCast(per.infd));
        } else if (per.infdopen) {
            _ = toolClose(per.infd);
        }
    } else if (per.infdopen) {
        _ = toolClose(per.infd);
    }

    if (!per.skip) {
        result = post_check_result(per, result);
        result = post_output_handling(per, result);

        if (per.retry_remaining != 0 and
            (cfg.retry_maxtime_ms == 0 or
                curlx_timediff_ms(curlx_now(), per.retrystart) < cfg.retry_maxtime_ms))
        {
            result = retrycheck(cfg, per, result, retryp, delay);
            if (result == CURLE_OK and retryp.*) {
                return CURLE_OK;
            }
        }

        if (global != null and global.?.progressmode == CURL_PROGRESS_BAR and per.progressbar.calls != 0) {
            _ = fputs("\n", per.progressbar.out);
        }

        result = post_close_output(per, result);
    }

    if (cfg.writeout != null) {
        ourWriteOut(cfg, per, result);
    }

    if (per.heads.fopened and per.heads.stream != null) {
        _ = fclose(per.heads.stream);
    }
    if (per.heads.alloc_filename) {
        Curl_cfree(per.heads.filename);
        per.heads.filename = null;
    }

    if (per.etag_save.fopened and per.etag_save.stream != null) {
        _ = fclose(per.etag_save.stream);
    }
    if (per.etag_save.alloc_filename) {
        Curl_cfree(per.etag_save.filename);
        per.etag_save.filename = null;
    }

    if (outs.alloc_filename) {
        Curl_cfree(outs.filename);
        outs.filename = null;
    }
    slist_wc_free_all(per.hdrcbdata.headlist);
    per.hdrcbdata.headlist = null;
    return result;
}

fn set_cert_types(config: *OperationConfig) CURLcode {
    if (feature_ssl) {
        if (config.cert != null and config.cert_type == null and is_pkcs11_uri(config.cert)) {
            config.cert_type = Curl_cstrdup("ENG");
            if (config.cert_type == null) return CURLE_OUT_OF_MEMORY;
        }
        if (config.key != null and config.key_type == null and is_pkcs11_uri(config.key)) {
            config.key_type = Curl_cstrdup("ENG");
            if (config.key_type == null) return CURLE_OUT_OF_MEMORY;
        }
        if (config.proxy_cert != null and config.proxy_cert_type == null and is_pkcs11_uri(config.proxy_cert)) {
            config.proxy_cert_type = Curl_cstrdup("ENG");
            if (config.proxy_cert_type == null) return CURLE_OUT_OF_MEMORY;
        }
        if (config.proxy_key != null and config.proxy_key_type == null and is_pkcs11_uri(config.proxy_key)) {
            config.proxy_key_type = Curl_cstrdup("ENG");
            if (config.proxy_key_type == null) return CURLE_OUT_OF_MEMORY;
        }
    }
    return CURLE_OK;
}

fn append2query(config: *OperationConfig, per: *per_transfer, q: ?[*:0]const u8) CURLcode {
    var result: CURLcode = CURLE_OK;
    if (q) |query| {
        const uh = curl_url();
        if (uh) |u| {
            var uerr = curl_url_set(u, CURLUPART_URL, per.url, CURLU_GUESS_SCHEME);
            if (uerr != CURLUE_OK) {
                result = urlerr_cvt(uerr);
                errorf("(%d) Could not parse the URL, failed to set query", @as(c_int, @intCast(result)));
                config.synthetic_error = true;
            } else {
                var updated: ?[*:0]u8 = null;
                uerr = curl_url_set(u, CURLUPART_QUERY, query, CURLU_APPENDQUERY);
                if (uerr == CURLUE_OK) {
                    uerr = curl_url_get(u, CURLUPART_URL, &updated, CURLU_NO_GUESS_SCHEME);
                }
                if (uerr != CURLUE_OK) {
                    result = urlerr_cvt(uerr);
                } else {
                    Curl_cfree(per.url);
                    per.url = if (updated) |up| Curl_cstrdup(up) else null;
                    curl_free(updated);
                    if (per.url == null) {
                        result = CURLE_OUT_OF_MEMORY;
                    }
                }
            }
            curl_url_cleanup(u);
        } else {
            result = CURLE_OUT_OF_MEMORY;
        }
    }
    return result;
}

fn etag_compare(config: *OperationConfig) CURLcode {
    var result: CURLcode = CURLE_OK;
    var etag_from_file: ?[*:0]u8 = null;
    var header: ?[*:0]u8 = null;

    const file = toolFopen(config.etag_compare_file.?, if (is_windows) "rt" else "r");
    if (file == null) {
        var errbuf: [STRERROR_LEN]u8 = undefined;
        warnf("Failed to open %s: %s", config.etag_compare_file.?, curlx_strerror(getErrno(), &errbuf, errbuf.len));
    }

    if (file2string(&etag_from_file, file) == PARAM_OK and etag_from_file != null) {
        const h = curl_maprintf("If-None-Match: %s", etag_from_file.?);
        Curl_cfree(etag_from_file);
        etag_from_file = null;
        if (h) |h_str| {
            header = Curl_cstrdup(h_str);
            curl_free(h_str);
        }
    } else {
        Curl_cfree(etag_from_file);
        header = Curl_cstrdup("If-None-Match: \"\"");
    }

    if (header == null) {
        if (file) |fp| _ = fclose(fp);
        errorf("Failed to allocate memory for custom etag header");
        return CURLE_OUT_OF_MEMORY;
    }

    const pe = add2list(&config.headers, header.?);
    Curl_cfree(header);

    if (file) |fp| _ = fclose(fp);
    if (pe != PARAM_OK) {
        result = CURLE_OUT_OF_MEMORY;
    }
    return result;
}

fn etag_store(config: *OperationConfig, etag_save: *OutStruct, skip: *bool) CURLcode {
    const save_file = config.etag_save_file.?;
    if (config.create_dirs) {
        const result = create_dir_hierarchy(save_file);
        if (result != CURLE_OK) return result;
    }

    if (strcmp(save_file, "-") != 0) {
        const newfile = toolFopen(save_file, "ab");
        if (newfile == null) {
            warnf("Failed creating file for saving etags: \"%s\". Skip this transfer", save_file);
            skip.* = true;
            return CURLE_OK;
        } else {
            etag_save.filename = save_file;
            etag_save.regular_file = true;
            etag_save.fopened = true;
            etag_save.stream = newfile;
        }
    } else {
        if (is_windows) {
            _ = win_c._setmode(toolFileno(etag_save.stream), win_c.O_BINARY);
        }
    }
    return CURLE_OK;
}

fn setup_headerfile(config: *OperationConfig, per: *per_transfer, heads: *OutStruct) CURLcode {
    if (config.headerfile) |hdrfile| {
        if (strcmp(hdrfile, "%") == 0) {
            heads.stream = stdio_streams.getStderr();
            if (is_windows) {
                _ = win_c._setmode(toolFileno(heads.stream), win_c.O_BINARY);
            }
        } else if (strcmp(hdrfile, "-") != 0) {
            if (config.create_dirs) {
                const result = create_dir_hierarchy(hdrfile);
                if (result != CURLE_OK) return result;
            }
            if (per.prev == null or per.prev.?.config != config) {
                if (toolFopen(hdrfile, "wb")) |newfile| {
                    _ = fclose(newfile);
                }
            }
            const newfile = toolFopen(hdrfile, "ab");
            if (newfile == null) {
                errorf("Failed to open %s", hdrfile);
                return CURLE_WRITE_ERROR;
            } else {
                heads.filename = hdrfile;
                heads.regular_file = true;
                heads.fopened = true;
                heads.stream = newfile;
            }
        } else {
            if (is_windows) {
                _ = win_c._setmode(toolFileno(heads.stream), win_c.O_BINARY);
            }
        }
    }
    return CURLE_OK;
}

fn setup_outfile(config: *OperationConfig, per: *per_transfer, u: *getout, outs: *OutStruct, skipped: *bool) CURLcode {
    const state = &global.?.state;

    outs.out_null = u.out_null;
    if (outs.out_null or (!u.useremote and (u.outfile == null or strcmp("-", u.outfile.?) == 0))) {
        per.outfile = u.outfile;
        u.outfile = null;
        return CURLE_OK;
    }

    if (u.outfile == null) {
        var sc: SANITIZEcode = SANITIZE_ERR_OK;
        const result = get_url_file_name(&per.outfile, per.url, &sc);
        if (sc != SANITIZE_ERR_OK) {
            if (sc == SANITIZE_ERR_OUT_OF_MEMORY) return CURLE_OUT_OF_MEMORY;
            if (sc == SANITIZE_ERR_INVALID_PATH) errorf("bad output filename");
            return result;
        } else if (result != CURLE_OK) {
            errorf("Failed to extract a filename from the URL to use for storage");
            return result;
        }
    } else if (glob_inuse(&state.urlglob) or glob_inuse(&state.inglob)) {
        var sc: SANITIZEcode = SANITIZE_ERR_OK;
        const result = glob_match_url(
            &per.outfile,
            u.outfile.?,
            &state.urlglob,
            if (glob_inuse(&state.inglob)) &state.inglob else null,
            &sc,
        );
        if (sc != SANITIZE_ERR_OK) {
            if (sc == SANITIZE_ERR_OUT_OF_MEMORY) return CURLE_OUT_OF_MEMORY;
            if (sc == SANITIZE_ERR_INVALID_PATH) warnf("bad output filename");
            return result;
        } else if (result != CURLE_OK) {
            if (state.urlglob.@"error" != null) {
                glob_show_error(&state.urlglob, u.outfile, tool_stderr, result);
                config.synthetic_error = true;
            } else {
                warnf("bad output glob");
            }
            return result;
        }
        if (per.outfile == null or per.outfile.?[0] == 0) {
            warnf("output glob produces empty string");
            return CURLE_WRITE_ERROR;
        }
    } else {
        per.outfile = Curl_cstrdup(u.outfile.?);
        if (per.outfile == null) return CURLE_OUT_OF_MEMORY;
    }

    if (config.output_dir) |odir| {
        if (odir[0] != 0) {
            const d = curl_maprintf("%s/%s", odir, per.outfile.?);
            Curl_cfree(per.outfile);
            per.outfile = null;
            if (d) |d_str| {
                per.outfile = Curl_cstrdup(d_str);
                curl_free(d_str);
            }
            if (d == null or per.outfile == null) {
                return CURLE_WRITE_ERROR;
            }
        }
    }

    if (config.create_dirs) {
        const result = create_dir_hierarchy(per.outfile.?);
        if (result != CURLE_OK) return result;
    }

    if (config.skip_existing) {
        var fileinfo: ToolStat = undefined;
        if (toolStat(per.outfile.?, &fileinfo) == 0) {
            notef("skips transfer, \"%s\" exists locally", per.outfile.?);
            per.skip = true;
            skipped.* = true;
        }
    }

    if (config.resume_from_current) {
        var fileinfo: ToolStat = undefined;
        if (toolStat(per.outfile.?, &fileinfo) == 0) {
            config.resume_from = fileinfo.size;
        } else {
            config.resume_from = 0;
        }
    }

    if (config.resume_from != 0) {
        const file = toolFopen(per.outfile.?, "ab");
        if (file == null) {
            errorf("cannot open '%s'", per.outfile.?);
            return CURLE_WRITE_ERROR;
        }
        outs.fopened = true;
        outs.stream = file;
        outs.init = config.resume_from;
    } else {
        outs.stream = null;
    }
    outs.filename = per.outfile;
    outs.regular_file = true;
    return CURLE_OK;
}

fn check_stdin_upload(config: *OperationConfig, per: *per_transfer) void {
    var authbits: c_int = 0;
    var bitcheck: u5 = 0;
    while (true) : (bitcheck += 1) {
        if ((config.authtype & (@as(c_ulong, 1) << bitcheck)) != 0) {
            authbits += 1;
            if (authbits > 1) break;
        }
        if (bitcheck == 31) break;
    }

    if (config.proxyanyauth or authbits > 1) {
        warnf("Using --anyauth or --proxy-anyauth with upload from stdin involves a big risk of it not working. Use a temporary file or a fixed auth type instead");
    }

    if (is_windows) {
        _ = win_c._setmode(toolFileno(stdio_streams.getStdin()), win_c.O_BINARY);
    }
    if (strcmp(per.uploadfile.?, ".") == 0) {
        if (is_windows) {
            const f = win32_stdin_read_thread();
            if (f == CURL_SOCKET_BAD) {
                warnf("win32_stdin_read_thread returned INVALID_SOCKET falling back to blocking mode");
            } else if (f > std.math.maxInt(c_int)) {
                warnf("win32_stdin_read_thread returned identifier larger than INT_MAX. This should not happen unless the upper 32 bits of a Windows socket have started being used for something... falling back to blocking mode");
                const WinSockClose = struct {
                    extern "ws2_32" fn closesocket(s: curl_socket_t) callconv(.winapi) c_int;
                };
                _ = WinSockClose.closesocket(f);
            } else {
                per.infd = @intCast(f);
            }
        }
        if (curlx_nonblock(@intCast(per.infd), 1) < 0) {
            var errbuf: [STRERROR_LEN]u8 = undefined;
            warnf("fcntl failed on fd=%d: %s", per.infd, curlx_strerror(getErrno(), &errbuf, errbuf.len));
        }
    }
}

fn setup_header_cb(config: *OperationConfig, hdrcbdata: *HdrCbData, u: *getout, outs: *OutStruct, heads: *OutStruct, etag: *OutStruct) void {
    hdrcbdata.honor_cd_filename = (config.content_disposition and u.useremote);
    hdrcbdata.outs = outs;
    hdrcbdata.heads = heads;
    hdrcbdata.etag_save = etag;
    hdrcbdata.config = config;
}

fn setup_input_file(config: *OperationConfig, state: *State, u: *getout, err: ?*FILE) CURLcode {
    var result: CURLcode = CURLE_OK;
    if (u.infile) |inf| {
        if (!config.globoff and !glob_inuse(&state.inglob)) {
            result = glob_url(&state.inglob, inf, &state.upnum, err);
        }
        if (result == CURLE_OK and state.uploadfile == null) {
            if (glob_inuse(&state.inglob) and !glob_is_literal(&state.inglob)) {
                result = glob_next_url(&state.uploadfile, &state.inglob);
            } else if (state.upidx == 0) {
                state.uploadfile = u.infile;
                u.infile = null;
            }
        }
    }
    return result;
}

fn setup_url_pattern(config: *OperationConfig, state: *State, u: *getout, err: ?*FILE) CURLcode {
    var result: CURLcode = CURLE_OK;
    if (state.urlnum == 0) {
        if (!config.globoff and !u.noglob) {
            result = glob_url(&state.urlglob, u.url.?, &state.urlnum, err);
        } else {
            state.urlnum = 1;
        }
    }
    return result;
}

fn setup_etag_files(config: *OperationConfig, etag_save: *OutStruct, break_loop: *bool) CURLcode {
    var result: CURLcode = CURLE_OK;
    break_loop.* = false;

    etag_save.* = std.mem.zeroes(OutStruct);
    etag_save.stream = stdio_streams.getStdout();

    if (config.etag_compare_file != null) {
        result = etag_compare(config);
        if (result != CURLE_OK) return result;
    }

    if (config.etag_save_file != null) {
        var badetag = false;
        result = etag_store(config, etag_save, &badetag);
        if (result != CURLE_OK or badetag) {
            break_loop.* = true;
            return result;
        }
    }
    return result;
}

fn select_next_url(state: *State, u: *getout, url: *?[*:0]u8) CURLcode {
    var result: CURLcode = CURLE_OK;
    if (glob_inuse(&state.urlglob) and !glob_is_literal(&state.urlglob)) {
        result = glob_next_url(url, &state.urlglob);
    } else if (state.urlidx == 0) {
        url.* = Curl_cstrdup(u.url.?);
        if (url.* == null) {
            result = CURLE_OUT_OF_MEMORY;
        }
    } else {
        url.* = null;
    }
    return result;
}

fn setup_transfer_upload(config: *OperationConfig, per: *per_transfer) CURLcode {
    var result: CURLcode = CURLE_OK;
    if (per.uploadfile) |upfile| {
        if (stdin_upload(upfile)) {
            check_stdin_upload(config, per);
        } else {
            result = add_file_name_to_url(per.curl, &per.url, upfile);
            if (result != CURLE_OK) return result;
        }

        if (config.resume_from_current) {
            config.resume_from = -1;
        }
    }
    return result;
}

fn stream_isatty(stream: ?*FILE) bool {
    return toolIsatty(toolFileno(stream)) != 0;
}

fn create_single(config: *OperationConfig, share: ?*CURLSH, state: *State, added: *bool, skipped: *bool) CURLcode {
    const g = global.?;
    const orig_isatty = g.isatty;
    const orig_noprogress = g.noprogress;
    var result: CURLcode = CURLE_OK;

    while (state.urlnode) |u| {
        var per: ?*per_transfer = null;
        var etag_first: OutStruct = std.mem.zeroes(OutStruct);
        const err: ?*FILE = if (!g.silent or g.showerror) tool_stderr else null;
        var break_loop = false;

        if (u.url == null) {
            warnf("Got more output options than URLs");
            break;
        }

        result = setup_input_file(config, state, u, err);
        if (result != CURLE_OK) return result;

        if (state.upidx >= state.upnum) {
            state.urlnum = 0;
            Curl_cfree(state.uploadfile);
            state.uploadfile = null;
            glob_cleanup(&state.inglob);
            state.upidx = 0;
            state.urlnode = u.next;
            state.upnum = 1;
            continue;
        }

        result = setup_url_pattern(config, state, u, err);
        if (result != CURLE_OK) return result;

        result = setup_etag_files(config, &etag_first, &break_loop);
        if (result != CURLE_OK or break_loop) return result;

        const curl = curl_easy_init();
        if (curl != null) {
            result = add_per_transfer(&per);
        } else {
            result = CURLE_OUT_OF_MEMORY;
        }
        if (result != CURLE_OK) {
            curl_easy_cleanup(curl);
            if (etag_first.fopened) {
                _ = fclose(etag_first.stream);
            }
            return result;
        }
        const p = per.?;
        p.etag_save = etag_first;
        if (state.uploadfile) |upfile| {
            p.uploadfile = Curl_cstrdup(upfile);
            if (p.uploadfile == null or SetHTTPrequest(TOOL_HTTPREQ_PUT, &config.httpreq) != 0) {
                Curl_cfree(p.uploadfile);
                p.uploadfile = null;
                curl_easy_cleanup(curl);
                return CURLE_FAILED_INIT;
            }
        }
        p.config = config;
        p.curl = curl;
        p.urlnum = u.num;
        p.out_scheme = null;

        const heads = &p.heads;
        heads.stream = stdio_streams.getStdout();

        result = setup_headerfile(config, p, heads);
        if (result != CURLE_OK) return result;
        const outs = &p.outs;

        p.infdopen = false;
        p.infd = 0; // STDIN_FILENO

        outs.stream = stdio_streams.getStdout();

        result = select_next_url(state, u, &p.url);
        if (result != CURLE_OK) return result;
        if (p.url == null) break;

        result = setup_outfile(config, p, u, outs, skipped);
        if (result != CURLE_OK) return result;

        result = setup_transfer_upload(config, p);
        if (result != CURLE_OK) return result;

        if (!outs.out_null and output_expected(p.url.?, p.uploadfile) and
            outs.stream != null and stream_isatty(outs.stream))
        {
            p.noprogress = true;
            g.noprogress = true;
            g.isatty = true;
        } else {
            p.noprogress = orig_noprogress;
            g.noprogress = orig_noprogress;
            g.isatty = orig_isatty;
        }

        result = append2query(config, p, config.httpgetfields);
        if (result != CURLE_OK) return result;

        if ((p.outfile == null or strcmp(p.outfile.?, "-") == 0) and !config.use_ascii) {
            if (is_windows) {
                _ = win_c._setmode(toolFileno(stdio_streams.getStdout()), win_c.O_BINARY);
            }
        }

        config.terminal_binary_ok = (p.outfile != null and strcmp(p.outfile.?, "-") == 0);

        setup_header_cb(config, &p.hdrcbdata, u, outs, heads, &etag_first);

        result = config2setopts(config, p, curl, share);
        if (result != CURLE_OK) return result;

        p.retry_sleep_default = @intCast(config.retry_delay_ms);
        p.retry_remaining = config.req_retry;
        p.retry_sleep = p.retry_sleep_default;
        p.retrystart = curlx_now();

        state.urlidx += 1;
        if (state.urlidx >= state.urlnum) {
            state.urlidx = 0;
            state.urlnum = 0;
            glob_cleanup(&state.urlglob);
            state.upidx += 1;
            Curl_cfree(state.uploadfile);
            state.uploadfile = null;
        }
        added.* = true;
        break;
    }
    return result;
}

fn single_transfer(config: *OperationConfig, share: ?*CURLSH, added: *bool, skipped: *bool) CURLcode {
    var result: CURLcode = CURLE_OK;
    const state = &global.?.state;
    var httpgetfields = config.httpgetfields;

    skipped.* = false;
    added.* = false;

    if (config.postfields != null) {
        if (config.use_httpget) {
            if (httpgetfields == null) {
                httpgetfields = config.postfields;
                config.httpgetfields = config.postfields;
                config.postfields = null;
                if (SetHTTPrequest(if (config.no_body) TOOL_HTTPREQ_HEAD else TOOL_HTTPREQ_GET, &config.httpreq) != 0) {
                    return CURLE_FAILED_INIT;
                }
            }
        } else if (SetHTTPrequest(TOOL_HTTPREQ_SIMPLEPOST, &config.httpreq) != 0) {
            return CURLE_FAILED_INIT;
        }
    }
    if (httpgetfields == null) {
        config.httpgetfields = config.query;
    }

    result = set_cert_types(config);
    if (result != CURLE_OK) return result;

    if (state.urlnode == null) {
        state.urlnode = config.url_list;
        state.upnum = 1;
    }

    return create_single(config, share, state, added, skipped);
}

var all_added: c_long = 0;

fn add_parallel_transfers(multi: ?*CURLM, share: ?*CURLSH, morep: *bool, addedp: *bool) CURLcode {
    var per: ?*per_transfer = null;
    var result: CURLcode = CURLE_OK;
    var mcode: CURLMcode = CURLM_OK;
    var sleeping = false;
    var nxfers: curl_off_t = 0;
    const g = global.?;

    addedp.* = false;
    morep.* = false;
    mcode = curl_multi_get_offt(multi, CURLMINFO_XFERS_CURRENT, &nxfers);
    if (mcode != CURLM_OK) {
        return CURLE_UNKNOWN_OPTION;
    }

    if (all_added >= g.parallel_max) {
        morep.* = true;
        return CURLE_OK;
    }

    if (transfers == null) {
        var skipped = false;
        while (true) {
            result = create_transfer(share, addedp, &skipped);
            if (result != CURLE_OK) return result;
            if (!skipped) break;
        }
    }

    per = transfers;
    while (per != null and all_added < g.parallel_max) : (per = per.?.next) {
        const p = per.?;
        if (p.added or p.skip) continue;
        if (p.startat != 0 and time(null) < p.startat) {
            sleeping = true;
            continue;
        }
        p.added = true;

        result = pre_transfer(p);
        if (result != CURLE_OK) return result;

        _ = curl_easy_setopt(p.curl, CURLOPT_PIPEWAIT, @as(c_long, if (g.parallel_connect) 0 else 1));
        _ = curl_easy_setopt(p.curl, CURLOPT_PRIVATE, p);
        _ = curl_easy_setopt(p.curl, CURLOPT_NOSIGNAL, @as(c_long, 1));
        _ = curl_easy_setopt(p.curl, CURLOPT_XFERINFOFUNCTION, @as(?*const anyopaque, @ptrCast(&xferinfo_cb)));
        _ = curl_easy_setopt(p.curl, CURLOPT_XFERINFODATA, p);
        _ = curl_easy_setopt(p.curl, CURLOPT_NOPROGRESS, @as(c_long, 0));
        _ = curl_easy_setopt(p.curl, CURLOPT_ERRORBUFFER, &p.errorbuffer);

        mcode = curl_multi_add_handle(multi, p.curl);
        if (mcode != CURLM_OK) {
            result = CURLE_OUT_OF_MEMORY;
        }

        if (result == CURLE_OK) {
            var getadded = false;
            var skipped = false;
            while (true) {
                result = create_transfer(share, &getadded, &skipped);
                if (result != CURLE_OK) break;
                if (!skipped) break;
            }
        }
        if (result != CURLE_OK) return result;

        p.errorbuffer[0] = 0;
        p.added = true;
        all_added += 1;
        addedp.* = true;
    }
    morep.* = (per != null or sleeping);
    return CURLE_OK;
}

const parastate = struct {
    multi: ?*CURLM = null,
    share: ?*CURLSH = null,
    mcode: CURLMcode = CURLM_OK,
    result: CURLcode = CURLE_OK,
    still_running: c_int = 0,
    start: curltime = .{ .tv_sec = 0, .tv_usec = 0 },
    more_transfers: bool = false,
    added_transfers: bool = false,
    wrapitup: bool = false,
    wrapitup_processed: bool = false,
    tick: i64 = 0,
};

fn check_finished(s: *parastate) CURLcode {
    var result: CURLcode = CURLE_OK;
    var rc: c_int = 0;
    var checkmore = false;
    const g = global.?;

    while (true) {
        const msg = curl_multi_info_read(s.multi, &rc) orelse break;
        var retry = false;
        var delay: u32 = 0;
        var ended: ?*per_transfer = null;
        const easy = msg.easy_handle;
        var tres = msg.data.result;
        _ = curl_easy_getinfo(easy, CURLINFO_PRIVATE, &ended);
        _ = curl_multi_remove_handle(s.multi, easy);

        if (ended) |p| {
            if (p.abort and tres == CURLE_ABORTED_BY_CALLBACK) {
                _ = curl_msnprintf(&p.errorbuffer, CURL_ERROR_SIZE, "Transfer aborted due to critical error in another transfer");
            }
            tres = post_per_transfer(p, tres, &retry, &delay);
            progress_finalize(p);
            all_added -= 1;
            checkmore = true;
            if (retry) {
                p.added = false;
                p.startat = if (delay != 0) time(null) + @as(i64, @intCast(delay / 1000)) else 0;
            } else {
                if (tres != CURLE_OK and (!p.abort or result == CURLE_OK)) {
                    result = tres;
                }
                if (is_fatal_error(result) or (result != CURLE_OK and g.fail_early)) {
                    s.wrapitup = true;
                }
                _ = del_per_transfer(p);
            }
        }
    }
    if (!s.wrapitup) {
        if (!checkmore) {
            const tock = time(null);
            if (s.tick != tock) {
                checkmore = true;
                s.tick = tock;
            }
        }
        if (checkmore) {
            const tres = add_parallel_transfers(s.multi, s.share, &s.more_transfers, &s.added_transfers);
            if (tres != CURLE_OK) {
                result = tres;
            }
            if (s.added_transfers) {
                s.still_running = 1;
            }
        }
        if (is_fatal_error(result) or (result != CURLE_OK and g.fail_early)) {
            s.wrapitup = true;
        }
    }
    return result;
}

fn mnotify(multi: ?*CURLM, notification: c_uint, easy: ?*CURL, user_data: ?*anyopaque) callconv(.c) void {
    _ = multi;
    _ = easy;
    const s: *parastate = @ptrCast(@alignCast(user_data orelse return));
    if (notification == CURLMNOTIFY_INFO_READ) {
        const result = check_finished(s);
        if (result != CURLE_OK and s.result == CURLE_OK) {
            s.result = result;
        }
    }
}

fn parallel_transfers(share: ?*CURLSH) CURLcode {
    var result: CURLcode = CURLE_OK;
    var p: parastate = .{
        .share = share,
        .mcode = CURLM_OK,
        .result = CURLE_OK,
        .still_running = 1,
        .start = curlx_now(),
        .wrapitup = false,
        .wrapitup_processed = false,
        .tick = time(null),
        .multi = curl_multi_init(),
    };
    const s = &p;
    if (s.multi == null) return CURLE_OUT_OF_MEMORY;

    _ = curl_multi_setopt(s.multi, CURLMOPT_QUICK_EXIT, @as(c_long, 1));
    _ = curl_multi_setopt(s.multi, CURLMOPT_NOTIFYFUNCTION, @as(?*const anyopaque, @ptrCast(&mnotify)));
    _ = curl_multi_setopt(s.multi, CURLMOPT_NOTIFYDATA, s);
    _ = curl_multi_setopt(s.multi, CURLMOPT_MAX_HOST_CONNECTIONS, @as(c_long, @intCast(global.?.parallel_host)));
    _ = curl_multi_notify_enable(s.multi, CURLMNOTIFY_INFO_READ);

    result = add_parallel_transfers(s.multi, s.share, &s.more_transfers, &s.added_transfers);
    if (result != CURLE_OK) {
        _ = curl_multi_cleanup(s.multi);
        return result;
    }

    if (all_added != 0) {
        while (s.mcode == CURLM_OK and (s.still_running != 0 or s.more_transfers)) {
            if (s.wrapitup) {
                if (s.still_running == 0) break;
                if (!s.wrapitup_processed) {
                    var per = transfers;
                    while (per) |cur| : (per = cur.next) {
                        if (cur.added) cur.abort = true;
                    }
                    s.wrapitup_processed = true;
                }
            } else if (s.more_transfers) {
                s.result = add_parallel_transfers(s.multi, s.share, &s.more_transfers, &s.added_transfers);
                if (s.result != CURLE_OK) break;
            }

            s.mcode = curl_multi_poll(s.multi, null, 0, 1000, null);
            if (s.mcode == CURLM_OK) {
                s.mcode = curl_multi_perform(s.multi, &s.still_running);
            }

            _ = progress_meter(s.multi, &s.start, false);
        }

        _ = progress_meter(s.multi, &s.start, true);
    }

    result = s.result;

    if (s.mcode != CURLM_OK) {
        result = if (s.mcode == CURLM_OUT_OF_MEMORY) CURLE_OUT_OF_MEMORY else CURLE_BAD_FUNCTION_ARGUMENT;
    }

    _ = curl_multi_cleanup(s.multi);

    return result;
}

fn serial_transfers(share: ?*CURLSH) CURLcode {
    var returncode: CURLcode = CURLE_OK;
    var result: CURLcode = CURLE_OK;
    var added = false;
    var skipped = false;
    const g = global.?;

    result = create_transfer(share, &added, &skipped);
    if (result != CURLE_OK) return result;
    if (!added) {
        errorf("no transfer performed");
        return CURLE_READ_ERROR;
    }
    var per = transfers;
    while (per) |p| {
        var retry = false;
        var delay_ms: u32 = 0;
        var bailout = false;
        const start = curlx_now();

        if (!p.skip) {
            result = pre_transfer(p);
            if (result != CURLE_OK) break;

            if (g.libcurl != null) {
                result = easysrc_perform();
                if (result != CURLE_OK) break;
            }

            result = curl_easy_perform(p.curl);
        }

        returncode = post_per_transfer(p, result, &retry, &delay_ms);
        if (retry) {
            _ = curlx_wait_ms(@intCast(delay_ms));
            continue;
        }

        if (is_fatal_error(returncode) or (returncode != CURLE_OK and g.fail_early)) {
            bailout = true;
        } else {
            while (true) {
                result = create_transfer(share, &added, &skipped);
                if (result != CURLE_OK) {
                    returncode = result;
                    bailout = true;
                    break;
                }
                if (!skipped) break;
            }
        }

        per = del_per_transfer(p);

        if (bailout) break;

        if (per != null and g.ms_per_transfer != 0) {
            const milli = curlx_timediff_ms(curlx_now(), start);
            if (milli < g.ms_per_transfer) {
                const wait_diff: c_long = @intCast(g.ms_per_transfer - milli);
                notef("Transfer took %" ++ "lld" ++ " ms, waits %ldms as set by --rate", milli, wait_diff);
                _ = curlx_wait_ms(wait_diff);
            }
        }
    }
    if (returncode != CURLE_OK) {
        result = returncode;
    }

    if (result != CURLE_OK) {
        single_transfer_cleanup();
    }

    return result;
}

const curl_tlssessioninfo = extern struct {
    backend: c_uint,
    internals: ?*anyopaque,
};
const CURLSSLBACKEND_SCHANNEL: c_uint = 8;

var win32_using_schannel_state: c_int = -1;

fn win32_using_schannel(resultp: *CURLcode) bool {
    resultp.* = CURLE_OK;
    if (!is_windows) return false;
    if (win32_using_schannel_state == -1) {
        const curl = curl_easy_init();
        var tls_backend_info: ?*const curl_tlssessioninfo = null;
        if (curl == null) {
            resultp.* = CURLE_OUT_OF_MEMORY;
        } else {
            resultp.* = curl_easy_getinfo(curl, CURLINFO_TLS_SSL_PTR, &tls_backend_info);
            if (resultp.* == CURLE_OK and tls_backend_info != null) {
                win32_using_schannel_state = if (tls_backend_info.?.backend == CURLSSLBACKEND_SCHANNEL) 1 else 0;
            }
        }
        curl_easy_cleanup(curl);
        if (resultp.* != CURLE_OK) return true;
    }
    return win32_using_schannel_state == 1;
}

fn win32_setup_certs(config: *OperationConfig) CURLcode {
    if (!is_windows) return CURLE_OK;
    if (config.capath == null and config.cacert == null) {
        const result = FindWin32CACert(config, "curl-ca-bundle.crt");
        if (result != CURLE_OK) return result;
    }
    return CURLE_OK;
}

fn cacertpaths(config: *OperationConfig) CURLcode {
    var result: CURLcode = CURLE_OK;

    if (!feature_ssl or config.cacert != null or config.capath != null or
        (config.insecure_ok and (config.doh_url == null or config.doh_insecure_ok)))
    {
        return CURLE_OK;
    }

    if (win32_using_schannel(&result)) {
        return result;
    }

    var env = curl_getenv("CURL_CA_BUNDLE");
    if (env) |e| {
        config.cacert = Curl_cstrdup(e);
        curl_free(e);
        if (config.cacert == null) {
            result = CURLE_OUT_OF_MEMORY;
        }
    } else {
        env = curl_getenv("SSL_CERT_DIR");
        if (env) |e| {
            config.capath = Curl_cstrdup(e);
            curl_free(e);
            if (config.capath == null) {
                result = CURLE_OUT_OF_MEMORY;
            }
        }
        if (result == CURLE_OK) {
            env = curl_getenv("SSL_CERT_FILE");
            if (env) |e| {
                config.cacert = Curl_cstrdup(e);
                curl_free(e);
                if (config.cacert == null) {
                    result = CURLE_OUT_OF_MEMORY;
                }
            }
        }
    }

    if (result == CURLE_OK) {
        result = win32_setup_certs(config);
    }
    if (result == CURLE_OK and config.cacert == null and config.capath == null) {
        const default_cacertpaths = switch (builtin.os.tag) {
            .linux => [_]?[*:0]const u8{
                "/etc/ssl/certs/ca-certificates.crt",
                "/etc/pki/tls/certs/ca-bundle.crt",
                "/etc/ssl/ca-bundle.pem",
                "/etc/pki/tls/cacert.pem",
                "/etc/pki/ca-trust/extracted/pem/tls-ca-bundle.pem",
                "/etc/ssl/cert.pem",
                null,
            },
            .macos => [_]?[*:0]const u8{
                "/etc/ssl/cert.pem",
                "/etc/ssl/certs/ca-certificates.crt",
                null,
            },
            else => [_]?[*:0]const u8{
                null,
            },
        };
        for (default_cacertpaths) |maybe_path| {
            const path = maybe_path orelse break;
            var st: ToolStat = undefined;
            if (toolStat(path, &st) == 0) {
                config.cacert = Curl_cstrdup(path);
                if (config.cacert == null) {
                    result = CURLE_OUT_OF_MEMORY;
                }
                break;
            }
        }
    }
    if (result != CURLE_OK) {
        Curl_cfree(config.capath);
        config.capath = null;
        Curl_cfree(config.cacert);
        config.cacert = null;
    }
    return result;
}

fn transfer_per_config(config: *OperationConfig, share: ?*CURLSH, added: *bool, skipped: *bool) CURLcode {
    var result: CURLcode = CURLE_OK;
    added.* = false;

    if (config.url_list == null or config.url_list.?.url == null) {
        helpf("(%d) no URL specified", @as(c_int, @intCast(CURLE_FAILED_INIT)));
        result = CURLE_FAILED_INIT;
    } else {
        result = cacertpaths(config);
        if (result == CURLE_OK) {
            result = single_transfer(config, share, added, skipped);
            if (!added.* or result != CURLE_OK) {
                single_transfer_cleanup();
            }
        }
    }

    return result;
}

fn create_transfer(share: ?*CURLSH, added: *bool, skipped: *bool) CURLcode {
    var result: CURLcode = CURLE_OK;
    const g = global.?;
    added.* = false;
    while (g.current) |curr| {
        result = transfer_per_config(curr, share, added, skipped);
        if (result == CURLE_OK and !added.*) {
            g.current = curr.next;
            continue;
        }
        break;
    }
    return result;
}

fn run_all_transfers(share: ?*CURLSH, result_in: CURLcode) CURLcode {
    var result = result_in;
    const g = global.?;
    const orig_noprogress = g.noprogress;
    const orig_isatty = g.isatty;

    if (result == CURLE_OK) {
        if (g.parallel) {
            result = parallel_transfers(share);
        } else {
            result = serial_transfers(share);
        }
    }

    var per = transfers;
    while (per) |p| {
        var retry = false;
        var delay: u32 = 0;
        const result2 = post_per_transfer(p, result, &retry, &delay);
        if (result == CURLE_OK) {
            result = result2;
        }
        if (p.config) |cfg| {
            clean_getout(cfg);
        }
        per = del_per_transfer(p);
    }

    g.noprogress = orig_noprogress;
    g.isatty = orig_isatty;

    return result;
}

fn share_setopt(share: ?*CURLSH, opt: c_int) CURLcode {
    const shres = curl_share_setopt(share, CURLSHOPT_SHARE, opt);
    if (shres == CURLSHE_OK or shres == CURLSHE_NOT_BUILT_IN) {
        return CURLE_OK;
    }
    return CURLE_FAILED_INIT;
}

fn share_setup(share: ?*CURLSH) CURLcode {
    var result: CURLcode = CURLE_OK;
    var options = [7]c_int{
        @intCast(CURL_LOCK_DATA_COOKIE),
        @intCast(CURL_LOCK_DATA_DNS),
        @intCast(CURL_LOCK_DATA_SSL_SESSION),
        @intCast(CURL_LOCK_DATA_PSL),
        @intCast(CURL_LOCK_DATA_HSTS),
        0,
        0,
    };
    if (global != null and !global.?.parallel) {
        options[5] = @intCast(CURL_LOCK_DATA_CONNECT);
    }
    var i: usize = 0;
    while (result == CURLE_OK and options[i] != 0) : (i += 1) {
        result = share_setopt(share, options[i]);
    }
    return result;
}

pub export fn operate(argc: c_int, argv: [*]?[*:0]u8) callconv(.c) CURLcode {
    var result: CURLcode = CURLE_OK;
    const g = global orelse return CURLE_FAILED_INIT;
    const first_arg: ?[*:0]const u8 = if (argc > 1) argv[1] else null;
    var curlrc_path: ?[*:0]u8 = null;
    var found_curlrc = false;

    _ = setlocale(LC_ALL_VAL, "");
    _ = setlocale(LC_NUMERIC_VAL, "C");

    if (argc == 1 or
        (first_arg != null and strncmp(first_arg.?, "-q", 2) != 0 and
            strcmp(first_arg.?, "--disable") != 0))
    {
        if (parseconfig(null, CONFIG_MAX_LEVELS, &curlrc_path) == 0) {
            found_curlrc = true;
        }

        if (argc < 2 and (g.first == null or g.first.?.url_list == null)) {
            helpf(null);
            result = CURLE_FAILED_INIT;
        }
    }

    if (result == CURLE_OK) {
        const err = parse_args(argc, argv);
        if (found_curlrc) {
            if (curlrc_path) |rcpath| {
                notef("Read config file from '%s'", rcpath);
            }
        }
        if (err != PARAM_OK) {
            result = CURLE_OK;
            if (err == PARAM_HELP_REQUESTED) {
                // already done
            } else if (err == PARAM_MANUAL_REQUESTED) {
                warnf("built-in manual was disabled at build-time");
            } else if (err == PARAM_VERSION_INFO_REQUESTED) {
                tool_version_info();
            } else if (err == PARAM_ENGINES_REQUESTED) {
                tool_list_engines();
            } else if (err == PARAM_CA_EMBED_REQUESTED) {
                // CURL_CA_EMBED not enabled
            } else if (err == PARAM_LIBCURL_UNSUPPORTED_PROTOCOL) {
                result = CURLE_UNSUPPORTED_PROTOCOL;
            } else if (err == PARAM_READ_ERROR) {
                result = CURLE_READ_ERROR;
            } else {
                result = CURLE_FAILED_INIT;
            }
        } else {
            if (g.libcurl != null) {
                result = easysrc_init();
            }

            if (result == CURLE_OK) {
                var count: usize = 0;
                var operation = g.first;
                const share = curl_share_init();
                if (share == null) {
                    if (g.libcurl != null) {
                        _ = easysrc_cleanup();
                    }
                    result = CURLE_OUT_OF_MEMORY;
                }

                if (result == CURLE_OK) {
                    result = share_setup(share);
                }

                if (result == CURLE_OK and g.ssl_sessions != null and feature_ssls_export) {
                    result = tool_ssls_load(g.first.?, share, g.ssl_sessions.?);
                }

                if (result == CURLE_OK) {
                    while (true) {
                        result = get_args(operation.?, count);
                        count += 1;
                        operation = operation.?.next;
                        if (result != CURLE_OK or operation == null) break;
                    }

                    if (result == CURLE_OK) {
                        g.current = g.first;

                        result = run_all_transfers(share, result);

                        if (g.ssl_sessions != null and feature_ssls_export) {
                            const r2 = tool_ssls_save(g.first.?, share, g.ssl_sessions.?);
                            if (r2 != CURLE_OK and result == CURLE_OK) {
                                result = r2;
                            }
                        }
                    }
                }

                _ = curl_share_cleanup(share);
                if (g.libcurl != null) {
                    _ = easysrc_cleanup();
                    dumpeasysrc();
                }
            } else {
                errorf("out of memory");
            }
        }
    }
    Curl_cfree(curlrc_path);
    varcleanup();

    return result;
}

// ============================================================================
// Part 4b: tool_zig_* helpers from src/tool_operate.c for cli_callbacks.zig
// ============================================================================

pub export fn tool_zig_manual_help_hint() callconv(.c) [*:0]const u8 {
    return "";
}

pub export fn tool_zig_get_global() callconv(.c) ?*GlobalConfig {
    return global;
}

pub export fn tool_zig_get_transfers() callconv(.c) ?*per_transfer {
    return transfers;
}

pub export fn tool_zig_get_stdout() callconv(.c) ?*FILE {
    return stdio_streams.getStdout();
}

pub export fn tool_zig_get_stderr() callconv(.c) ?*FILE {
    return stdio_streams.getStderr();
}

pub export fn tool_zig_fopen_writetext() callconv(.c) [*:0]const u8 {
    return if (is_windows) "wt" else "w";
}

pub export fn tool_zig_fopen_appendtext() callconv(.c) [*:0]const u8 {
    return if (is_windows) "at" else "a";
}

pub export fn tool_zig_fopen(fname: [*:0]const u8, mode: [*:0]const u8) callconv(.c) ?*FILE {
    return toolFopen(fname, mode);
}

pub export fn tool_zig_freopen(fname: [*:0]const u8, mode: [*:0]const u8, stream: ?*FILE) callconv(.c) ?*FILE {
    return freopen(fname, mode, stream);
}

pub export fn tool_zig_fclose(stream: ?*FILE) callconv(.c) c_int {
    return fclose(stream);
}

pub export fn tool_zig_os_terminal_cols() callconv(.c) c_int {
    if (is_windows) {
        const CONSOLE_SCREEN_BUFFER_INFO = extern struct {
            dwSize_X: i16,
            dwSize_Y: i16,
            dwCursorPosition_X: i16,
            dwCursorPosition_Y: i16,
            wAttributes: u16,
            srWindow_Left: i16,
            srWindow_Top: i16,
            srWindow_Right: i16,
            srWindow_Bottom: i16,
            dwMaximumWindowSize_X: i16,
            dwMaximumWindowSize_Y: i16,
        };
        const WinCon = struct {
            extern "kernel32" fn GetConsoleScreenBufferInfo(hConsoleOutput: ?*anyopaque, lpConsoleScreenBufferInfo: *CONSOLE_SCREEN_BUFFER_INFO) callconv(.winapi) c_int;
        };
        const stderr_fd = toolFileno(tool_stderr);
        if (stderr_fd >= 0) {
            const STD_ERROR_HANDLE: u32 = @bitCast(@as(i32, -12));
            const hnd = win_c.GetStdHandle(STD_ERROR_HANDLE);
            var csbi: CONSOLE_SCREEN_BUFFER_INFO = std.mem.zeroes(CONSOLE_SCREEN_BUFFER_INFO);
            if (WinCon.GetConsoleScreenBufferInfo(hnd, &csbi) != 0) {
                return @as(c_int, csbi.srWindow_Right) - @as(c_int, csbi.srWindow_Left) + 1;
            }
        }
        return 0;
    } else {
        const winsize = extern struct {
            ws_row: c_ushort,
            ws_col: c_ushort,
            ws_xpixel: c_ushort,
            ws_ypixel: c_ushort,
        };
        const PosixIoctl = struct {
            extern "c" fn ioctl(fd: c_int, request: c_ulong, ...) callconv(.c) c_int;
        };
        const TIOCGWINSZ_VAL: c_ulong = if (builtin.os.tag.isDarwin()) 0x40087468 else 0x5413;
        var ts: winsize = std.mem.zeroes(winsize);
        if (PosixIoctl.ioctl(toolFileno(tool_stderr), TIOCGWINSZ_VAL, &ts) == 0) {
            return @intCast(ts.ws_col);
        }
        return 0;
    }
}

pub export fn tool_zig_tvrealnow(sec: *curl_off_t, usec: *c_long) callconv(.c) void {
    const now = tvrealnow();
    sec.* = @intCast(now.tv_sec);
    usec.* = @intCast(now.tv_usec);
}

pub export fn tool_zig_localtime_hms(tv_sec: curl_off_t, hour: *c_int, min: *c_int, sec: *c_int) callconv(.c) void {
    var now_tm: tm = std.mem.zeroes(tm);
    if (toolx_localtime(@intCast(tv_sec), &now_tm) == CURLE_OK) {
        hour.* = now_tm.tm_hour;
        min.* = now_tm.tm_min;
        sec.* = now_tm.tm_sec;
    } else {
        hour.* = 0;
        min.* = 0;
        sec.* = 0;
    }
}

pub export fn tool_zig_global_tracetime(g: ?*const GlobalConfig) callconv(.c) bool {
    return if (g) |cfg| cfg.tracetime else false;
}
pub export fn tool_zig_global_traceids(g: ?*const GlobalConfig) callconv(.c) bool {
    return if (g) |cfg| cfg.traceids else false;
}
pub export fn tool_zig_global_trace_stream(g: ?*const GlobalConfig) callconv(.c) ?*FILE {
    return if (g) |cfg| cfg.trace_stream else null;
}
pub export fn tool_zig_global_set_trace_stream(g: ?*GlobalConfig, s: ?*FILE) callconv(.c) void {
    if (g) |cfg| cfg.trace_stream = s;
}
pub export fn tool_zig_global_trace_dump(g: ?*const GlobalConfig) callconv(.c) ?[*:0]const u8 {
    return if (g) |cfg| cfg.trace_dump else null;
}
pub export fn tool_zig_global_set_trace_fopened(g: ?*GlobalConfig, v: bool) callconv(.c) void {
    if (g) |cfg| cfg.trace_fopened = v;
}
pub export fn tool_zig_global_tracetype(g: ?*const GlobalConfig) callconv(.c) c_uint {
    return if (g) |cfg| cfg.tracetype else 0;
}
pub export fn tool_zig_global_isatty(g: ?*const GlobalConfig) callconv(.c) bool {
    return if (g) |cfg| cfg.isatty else false;
}
pub export fn tool_zig_global_styled_output(g: ?*const GlobalConfig) callconv(.c) bool {
    return if (g) |cfg| cfg.styled_output else false;
}
pub export fn tool_zig_global_noprogress(g: ?*const GlobalConfig) callconv(.c) bool {
    return if (g) |cfg| cfg.noprogress else false;
}
pub export fn tool_zig_global_silent(g: ?*const GlobalConfig) callconv(.c) bool {
    return if (g) |cfg| cfg.silent else false;
}
pub export fn tool_zig_global_showerror(g: ?*const GlobalConfig) callconv(.c) bool {
    return if (g) |cfg| cfg.showerror else false;
}
pub export fn tool_zig_term_has_bold() callconv(.c) bool {
    if (is_windows) {
        const WinTerm = struct {
            extern var tool_term_has_bold: bool;
        };
        return WinTerm.tool_term_has_bold;
    } else {
        return true;
    }
}

pub export fn tool_zig_config_output_dir(cfg: *const OperationConfig) callconv(.c) ?[*:0]const u8 {
    return cfg.output_dir;
}
pub export fn tool_zig_config_headerfile(cfg: *const OperationConfig) callconv(.c) ?[*:0]const u8 {
    return cfg.headerfile;
}
pub export fn tool_zig_config_etag_save_file(cfg: *const OperationConfig) callconv(.c) ?[*:0]const u8 {
    return cfg.etag_save_file;
}
pub export fn tool_zig_config_writeout(cfg: *const OperationConfig) callconv(.c) ?[*:0]const u8 {
    return cfg.writeout;
}
pub export fn tool_zig_config_show_headers(cfg: *const OperationConfig) callconv(.c) bool {
    return cfg.show_headers;
}
pub export fn tool_zig_config_readbusy(cfg: *const OperationConfig) callconv(.c) bool {
    return cfg.readbusy;
}
pub export fn tool_zig_config_set_readbusy(cfg: *OperationConfig, v: bool) callconv(.c) void {
    cfg.readbusy = v;
}
pub export fn tool_zig_config_use_resume(cfg: *const OperationConfig) callconv(.c) bool {
    return cfg.use_resume;
}
pub export fn tool_zig_config_resume_from(cfg: *const OperationConfig) callconv(.c) curl_off_t {
    return cfg.resume_from;
}
pub export fn tool_zig_config_timeout_ms(cfg: *const OperationConfig) callconv(.c) c_long {
    return cfg.timeout_ms;
}
pub export fn tool_zig_config_file_clobber_mode(cfg: *const OperationConfig) callconv(.c) c_uint {
    return cfg.file_clobber_mode;
}
pub export fn tool_zig_config_terminal_binary_ok(cfg: *const OperationConfig) callconv(.c) bool {
    return cfg.terminal_binary_ok;
}
pub export fn tool_zig_config_nobuffer(cfg: *const OperationConfig) callconv(.c) bool {
    return cfg.nobuffer;
}

pub export fn tool_zig_outs_filename(o: *const OutStruct) callconv(.c) ?[*:0]u8 {
    return o.filename;
}
pub export fn tool_zig_outs_set_filename(o: *OutStruct, f: ?[*:0]u8) callconv(.c) void {
    o.filename = f;
}
pub export fn tool_zig_outs_stream(o: *const OutStruct) callconv(.c) ?*FILE {
    return o.stream;
}
pub export fn tool_zig_outs_set_stream(o: *OutStruct, s: ?*FILE) callconv(.c) void {
    o.stream = s;
}
pub export fn tool_zig_outs_bytes(o: *const OutStruct) callconv(.c) curl_off_t {
    return o.bytes;
}
pub export fn tool_zig_outs_set_bytes(o: *OutStruct, b: curl_off_t) callconv(.c) void {
    o.bytes = b;
}
pub export fn tool_zig_outs_set_init(o: *OutStruct, i: curl_off_t) callconv(.c) void {
    o.init = i;
}
pub export fn tool_zig_outs_alloc_filename(o: *const OutStruct) callconv(.c) bool {
    return o.alloc_filename;
}
pub export fn tool_zig_outs_set_alloc_filename(o: *OutStruct, v: bool) callconv(.c) void {
    o.alloc_filename = v;
}
pub export fn tool_zig_outs_is_cd_filename(o: *const OutStruct) callconv(.c) bool {
    return o.is_cd_filename;
}
pub export fn tool_zig_outs_set_is_cd_filename(o: *OutStruct, v: bool) callconv(.c) void {
    o.is_cd_filename = v;
}
pub export fn tool_zig_outs_regular_file(o: *const OutStruct) callconv(.c) bool {
    return o.regular_file;
}
pub export fn tool_zig_outs_set_regular_file(o: *OutStruct, v: bool) callconv(.c) void {
    o.regular_file = v;
}
pub export fn tool_zig_outs_fopened(o: *const OutStruct) callconv(.c) bool {
    return o.fopened;
}
pub export fn tool_zig_outs_set_fopened(o: *OutStruct, v: bool) callconv(.c) void {
    o.fopened = v;
}
pub export fn tool_zig_outs_out_null(o: *const OutStruct) callconv(.c) bool {
    return o.out_null;
}
pub export fn tool_zig_outs_reset_utf8seq(o: *OutStruct) callconv(.c) void {
    if (is_windows) {
        @memset(&o.utf8seq, 0);
    }
}

pub export fn tool_zig_hdrcb_config(h: *const HdrCbData) callconv(.c) ?*OperationConfig {
    return h.config;
}
pub export fn tool_zig_hdrcb_headlist(h: *const HdrCbData) callconv(.c) ?*slist_wc {
    return h.headlist;
}
pub export fn tool_zig_hdrcb_set_headlist(h: *HdrCbData, l: ?*slist_wc) callconv(.c) void {
    h.headlist = l;
}
pub export fn tool_zig_hdrcb_honor_cd_filename(h: *const HdrCbData) callconv(.c) bool {
    return h.honor_cd_filename;
}
pub export fn tool_zig_hdrcb_set_honor_cd_filename(h: *HdrCbData, v: bool) callconv(.c) void {
    h.honor_cd_filename = v;
}

pub export fn tool_zig_per_next(p: *const per_transfer) callconv(.c) ?*per_transfer {
    return p.next;
}
pub export fn tool_zig_per_config(p: *const per_transfer) callconv(.c) ?*OperationConfig {
    return p.config;
}
pub export fn tool_zig_per_certinfo(p: *const per_transfer) callconv(.c) ?*const curl_certinfo {
    return p.certinfo;
}
pub export fn tool_zig_per_set_certinfo(p: *per_transfer, ci: ?*const curl_certinfo) callconv(.c) void {
    p.certinfo = @constCast(ci);
}
pub export fn tool_zig_per_curl(p: *const per_transfer) callconv(.c) ?*CURL {
    return p.curl;
}
pub export fn tool_zig_per_num_retries(p: *const per_transfer) callconv(.c) c_long {
    return p.num_retries;
}
pub export fn tool_zig_per_start_ptr(p: *const per_transfer) callconv(.c) *const curltime {
    return &p.start;
}
pub export fn tool_zig_per_url(p: *const per_transfer) callconv(.c) ?[*:0]const u8 {
    return p.url;
}
pub export fn tool_zig_per_uploadfile(p: *const per_transfer) callconv(.c) ?[*:0]const u8 {
    return p.uploadfile;
}
pub export fn tool_zig_per_urlnum(p: *const per_transfer) callconv(.c) curl_off_t {
    return @intCast(p.urlnum);
}
pub export fn tool_zig_per_out_scheme(p: *const per_transfer) callconv(.c) ?[*:0]const u8 {
    return p.out_scheme;
}
pub export fn tool_zig_per_set_out_scheme(p: *per_transfer, s: ?[*:0]const u8) callconv(.c) void {
    p.out_scheme = s;
}
pub export fn tool_zig_per_infd(p: *const per_transfer) callconv(.c) c_int {
    return p.infd;
}
pub export fn tool_zig_per_progressbar(p: *per_transfer) callconv(.c) *ProgressData {
    return &p.progressbar;
}
pub export fn tool_zig_per_outs(p: *per_transfer) callconv(.c) *OutStruct {
    return &p.outs;
}
pub export fn tool_zig_per_heads(p: *per_transfer) callconv(.c) *OutStruct {
    return &p.heads;
}
pub export fn tool_zig_per_etag_save(p: *per_transfer) callconv(.c) *OutStruct {
    return &p.etag_save;
}
pub export fn tool_zig_per_hdrcbdata(p: *per_transfer) callconv(.c) *HdrCbData {
    return &p.hdrcbdata;
}
pub export fn tool_zig_per_num_headers(p: *const per_transfer) callconv(.c) c_long {
    return p.num_headers;
}
pub export fn tool_zig_per_set_num_headers(p: *per_transfer, n: c_long) callconv(.c) void {
    p.num_headers = n;
}
pub export fn tool_zig_per_dltotal(p: *const per_transfer) callconv(.c) curl_off_t {
    return p.dltotal;
}
pub export fn tool_zig_per_set_dltotal(p: *per_transfer, v: curl_off_t) callconv(.c) void {
    p.dltotal = v;
}
pub export fn tool_zig_per_dlnow(p: *const per_transfer) callconv(.c) curl_off_t {
    return p.dlnow;
}
pub export fn tool_zig_per_set_dlnow(p: *per_transfer, v: curl_off_t) callconv(.c) void {
    p.dlnow = v;
}
pub export fn tool_zig_per_ultotal(p: *const per_transfer) callconv(.c) curl_off_t {
    return p.ultotal;
}
pub export fn tool_zig_per_set_ultotal(p: *per_transfer, v: curl_off_t) callconv(.c) void {
    p.ultotal = v;
}
pub export fn tool_zig_per_ulnow(p: *const per_transfer) callconv(.c) curl_off_t {
    return p.ulnow;
}
pub export fn tool_zig_per_set_ulnow(p: *per_transfer, v: curl_off_t) callconv(.c) void {
    p.ulnow = v;
}
pub export fn tool_zig_per_uploadfilesize(p: *const per_transfer) callconv(.c) curl_off_t {
    return p.uploadfilesize;
}
pub export fn tool_zig_per_uploadedsofar(p: *const per_transfer) callconv(.c) curl_off_t {
    return p.uploadedsofar;
}
pub export fn tool_zig_per_dltotal_added(p: *const per_transfer) callconv(.c) bool {
    return p.dltotal_added;
}
pub export fn tool_zig_per_set_dltotal_added(p: *per_transfer, v: bool) callconv(.c) void {
    p.dltotal_added = v;
}
pub export fn tool_zig_per_ultotal_added(p: *const per_transfer) callconv(.c) bool {
    return p.ultotal_added;
}
pub export fn tool_zig_per_set_ultotal_added(p: *per_transfer, v: bool) callconv(.c) void {
    p.ultotal_added = v;
}
pub export fn tool_zig_per_noprogress(p: *const per_transfer) callconv(.c) bool {
    return p.noprogress;
}
pub export fn tool_zig_per_was_last_header_empty(p: *const per_transfer) callconv(.c) bool {
    return p.was_last_header_empty;
}
pub export fn tool_zig_per_set_was_last_header_empty(p: *per_transfer, v: bool) callconv(.c) void {
    p.was_last_header_empty = v;
}
pub export fn tool_zig_per_abort(p: *const per_transfer) callconv(.c) bool {
    return p.abort;
}
pub export fn tool_zig_per_errorbuffer(p: *const per_transfer) callconv(.c) [*:0]const u8 {
    return @ptrCast(&p.errorbuffer);
}

pub export fn tool_zig_scheme_is_http_or_https(scheme: ?[*:0]const u8) callconv(.c) bool {
    return (scheme == proto_http) or (scheme == proto_https);
}

pub export fn tool_zig_scheme_is_header_shown(scheme: ?[*:0]const u8) callconv(.c) bool {
    return (scheme == proto_http) or (scheme == proto_https) or (scheme == proto_rtsp) or (scheme == proto_file);
}

pub export fn tool_zig_sanitize_filename(copy: [*:0]u8) callconv(.c) ?[*:0]u8 {
    if (is_windows) {
        var sanitized: ?[*:0]u8 = null;
        if (sanitize_file_name(&sanitized, copy, 0) != SANITIZE_ERR_OK) {
            Curl_cfree(copy);
            return null;
        }
        Curl_cfree(copy);
        return sanitized;
    } else {
        return copy;
    }
}

pub export fn tool_zig_truncate_regular_stream(stream: ?*FILE) callconv(.c) bool {
    var file_stat: ToolStat = undefined;
    const fd = toolFileno(stream);
    if (toolFstat(fd, &file_stat) == 0 and file_stat.is_reg) {
        if (toolFtruncate(fd, 0) != 0) {
            return false;
        }
    }
    return true;
}

pub export fn tool_zig_waitfd(waitms: c_int, fd: c_int) callconv(.c) void {
    if (is_windows) {
        _ = curlx_wait_ms(waitms);
    } else {
        const pollfd = extern struct {
            fd: c_int,
            events: c_short,
            revents: c_short,
        };
        const PosixPoll = struct {
            extern "c" fn poll(fds: [*]pollfd, nfds: c_ulong, timeout: c_int) callconv(.c) c_int;
        };
        var pfd = [1]pollfd{.{
            .fd = fd,
            .events = 0x0001, // POLLIN
            .revents = 0,
        }};
        _ = PosixPoll.poll(&pfd, 1, waitms);
    }
}

pub export fn tool_zig_read_fd(per: *per_transfer, buffer: [*]u8, nbytes: usize, is_eagain: *bool) callconv(.c) isize {
    is_eagain.* = false;
    var rc: isize = 0;
    if (is_windows) {
        const WinRead = struct {
            extern "c" fn _read(fd: c_int, buffer: [*]u8, count: c_uint) callconv(.c) c_int;
        };
        const max_chunk: c_uint = @intCast(@min(nbytes, @as(usize, 65536)));
        rc = WinRead._read(per.infd, buffer, max_chunk);
    } else {
        const PosixRead = struct {
            extern "c" fn read(fd: c_int, buf: [*]u8, count: usize) callconv(.c) isize;
        };
        rc = PosixRead.read(per.infd, buffer, nbytes);
    }
    if (rc < 0) {
        const e = getErrno();
        const EAGAIN_VAL: c_int = if (builtin.os.tag.isDarwin()) 35 else 11;
        const EINTR_VAL: c_int = 4;
        if (e == EAGAIN_VAL or e == EINTR_VAL) {
            setErrno(0);
            is_eagain.* = true;
            return -1;
        }
        rc = 0;
    }
    return rc;
}

pub export fn tool_zig_seek_fd(fd: c_int, offset: curl_off_t, whence: c_int) callconv(.c) c_int {
    if (is_windows) {
        const WinLseek = struct {
            extern "c" fn _lseeki64(fd: c_int, offset: i64, origin: c_int) callconv(.c) i64;
        };
        return if (WinLseek._lseeki64(fd, offset, whence) == -1) 2 else 0; // CURL_SEEKFUNC_CANTSEEK = 2, CURL_SEEKFUNC_OK = 0
    } else {
        const PosixLseek = struct {
            extern "c" fn lseek(fd: c_int, offset: i64, whence: c_int) callconv(.c) i64;
        };
        return if (PosixLseek.lseek(fd, offset, whence) == -1) 2 else 0;
    }
}

pub export fn tool_zig_ftruncate64(fd: c_int, where: curl_off_t) callconv(.c) c_int {
    return toolFtruncate(fd, where);
}

pub export fn tool_zig_open_socket(family: c_int, socktype: c_int, protocol: c_int) callconv(.c) curl_socket_t {
    if (is_windows) {
        const WinSock = struct {
            extern "ws2_32" fn socket(af: c_int, @"type": c_int, protocol: c_int) callconv(.winapi) curl_socket_t;
        };
        return WinSock.socket(family, socktype, protocol);
    } else {
        const PosixSock = struct {
            extern "c" fn socket(domain: c_int, @"type": c_int, protocol: c_int) callconv(.c) c_int;
        };
        return PosixSock.socket(family, socktype, protocol);
    }
}

pub export fn tool_zig_open_excl(fname: [*:0]const u8, is_exist_or_isdir: *bool) callconv(.c) c_int {
    is_exist_or_isdir.* = false;
    const mode: c_int = if (is_windows) 0o600 else 0o666;
    const EINTR_VAL: c_int = 4;
    var fd: c_int = -1;
    while (true) {
        fd = toolOpen(fname, O_CREAT_VAL | O_WRONLY_VAL | O_EXCL_VAL | O_BINARY_VAL, mode);
        if (fd != -1 or getErrno() != EINTR_VAL) break;
    }
    if (fd == -1) {
        const e = getErrno();
        const EISDIR_VAL: c_int = 21;
        if (e == EEXIST_VAL or e == EISDIR_VAL) {
            is_exist_or_isdir.* = true;
        }
    }
    return fd;
}

pub export fn tool_zig_fdopen_wb(fd: c_int) callconv(.c) ?*FILE {
    const file = toolFdopen(fd, "wb");
    if (file == null) {
        _ = toolClose(fd);
    }
    return file;
}

pub export fn tool_zig_strerror_errno(buf: [*]u8, len: usize) callconv(.c) [*:0]const u8 {
    return curlx_strerror(getErrno(), buf, len);
}

pub export fn tool_zig_win_console_write(stream: ?*FILE, outs: *OutStruct, buffer: [*]u8, bytes: usize, rc_out: *usize) callconv(.c) c_int {
    if (is_windows) {
        const CONSOLE_SCREEN_BUFFER_INFO = extern struct {
            dwSize_X: i16,
            dwSize_Y: i16,
            dwCursorPosition_X: i16,
            dwCursorPosition_Y: i16,
            wAttributes: u16,
            srWindow_Left: i16,
            srWindow_Top: i16,
            srWindow_Right: i16,
            srWindow_Bottom: i16,
            dwMaximumWindowSize_X: i16,
            dwMaximumWindowSize_Y: i16,
        };
        const WinCon = struct {
            extern "c" fn _get_osfhandle(fd: c_int) callconv(.c) isize;
            extern "kernel32" fn GetConsoleScreenBufferInfo(hConsoleOutput: ?*anyopaque, lpConsoleScreenBufferInfo: *CONSOLE_SCREEN_BUFFER_INFO) callconv(.winapi) c_int;
            extern "kernel32" fn MultiByteToWideChar(CodePage: u32, dwFlags: u32, lpMultiByteStr: [*]const u8, cbMultiByte: c_int, lpWideCharStr: ?[*]u16, cchWideChar: c_int) callconv(.winapi) c_int;
            extern "kernel32" fn WriteConsoleW(hConsoleOutput: ?*anyopaque, lpBuffer: [*]const u16, nNumberOfCharsToWrite: u32, lpNumberOfCharsWritten: *u32, lpReserved: ?*anyopaque) callconv(.winapi) c_int;
        };
        const CP_UTF8: u32 = 65001;
        var console_info: CONSOLE_SCREEN_BUFFER_INFO = std.mem.zeroes(CONSOLE_SCREEN_BUFFER_INFO);
        const fd = toolFileno(stream);
        const fhnd_int = WinCon._get_osfhandle(fd);
        const fhnd: ?*anyopaque = if (fhnd_int == -1) null else @ptrFromInt(@as(usize, @bitCast(fhnd_int)));
        if (toolIsatty(fd) != 0 and WinCon.GetConsoleScreenBufferInfo(fhnd, &console_info) != 0) {
            var chars_written: u32 = 0;
            var rbuf: [*]const u8 = buffer;
            var rlen: u32 = @intCast(bytes);

            if (outs.utf8seq[0] != 0 and rlen != 0) {
                var complete = false;
                if (0xC0 <= outs.utf8seq[0] and outs.utf8seq[0] < 0xE0) {
                    outs.utf8seq[1] = rbuf[0];
                    rbuf += 1;
                    rlen -= 1;
                    complete = true;
                } else if (0xE0 <= outs.utf8seq[0] and outs.utf8seq[0] < 0xF0) {
                    if (outs.utf8seq[1] == 0) {
                        outs.utf8seq[1] = rbuf[0];
                        rbuf += 1;
                        rlen -= 1;
                    }
                    if (rlen != 0 and outs.utf8seq[2] == 0) {
                        outs.utf8seq[2] = rbuf[0];
                        rbuf += 1;
                        rlen -= 1;
                        complete = true;
                    }
                } else if (0xF0 <= outs.utf8seq[0] and outs.utf8seq[0] < 0xF8) {
                    if (outs.utf8seq[1] == 0) {
                        outs.utf8seq[1] = rbuf[0];
                        rbuf += 1;
                        rlen -= 1;
                    }
                    if (rlen != 0 and outs.utf8seq[2] == 0) {
                        outs.utf8seq[2] = rbuf[0];
                        rbuf += 1;
                        rlen -= 1;
                    }
                    if (rlen != 0 and outs.utf8seq[3] == 0) {
                        outs.utf8seq[3] = rbuf[0];
                        rbuf += 1;
                        rlen -= 1;
                        complete = true;
                    }
                }

                if (complete) {
                    var prefix: [3]u16 = .{ 0, 0, 0 };
                    if (WinCon.MultiByteToWideChar(CP_UTF8, 0, &outs.utf8seq, -1, &prefix, 3) != 0) {
                        if (WinCon.WriteConsoleW(fhnd, &prefix, if (prefix[1] != 0) 2 else 1, &chars_written, null) == 0) {
                            return -1;
                        }
                    }
                    @memset(&outs.utf8seq, 0);
                }
            }

            if (outs.utf8seq[0] == 0 and rlen != 0 and (rbuf[rlen - 1] & 0x80) != 0) {
                if (0xC0 <= rbuf[rlen - 1] and rbuf[rlen - 1] < 0xF8) {
                    outs.utf8seq[0] = rbuf[rlen - 1];
                    rlen -= 1;
                } else if (rlen >= 2 and (0x80 <= rbuf[rlen - 1] and rbuf[rlen - 1] < 0xC0)) {
                    if (0xE0 <= rbuf[rlen - 2] and rbuf[rlen - 2] < 0xF8) {
                        outs.utf8seq[0] = rbuf[rlen - 2];
                        outs.utf8seq[1] = rbuf[rlen - 1];
                        rlen -= 2;
                    } else if (rlen >= 3 and (0x80 <= rbuf[rlen - 2] and rbuf[rlen - 2] < 0xC0)) {
                        if (0xF0 <= rbuf[rlen - 3] and rbuf[rlen - 3] < 0xF8) {
                            outs.utf8seq[0] = rbuf[rlen - 3];
                            outs.utf8seq[1] = rbuf[rlen - 2];
                            outs.utf8seq[2] = rbuf[rlen - 1];
                            rlen -= 3;
                        }
                    }
                }
            }

            if (rlen != 0) {
                const g = global orelse return -1;
                const wlen_int = WinCon.MultiByteToWideChar(CP_UTF8, 0, rbuf, @intCast(rlen), null, 0);
                if (wlen_int <= 0) return -1;
                const wlen: u32 = @intCast(wlen_int);
                if (wlen > g.term.len) {
                    const new_buf = Curl_crealloc(@ptrCast(g.term.buf), @as(usize, wlen) * @sizeOf(u16)) orelse return -1;
                    g.term.len = wlen;
                    g.term.buf = @ptrCast(@alignCast(new_buf));
                }
                const wlen2 = WinCon.MultiByteToWideChar(CP_UTF8, 0, rbuf, @intCast(rlen), g.term.buf, @intCast(wlen));
                if (wlen2 <= 0) return -1;
                if (WinCon.WriteConsoleW(fhnd, g.term.buf.?, @intCast(wlen2), &chars_written, null) == 0) {
                    return -1;
                }
            }

            rc_out.* = bytes;
            return 1;
        }
        return 0;
    } else {
        return 0;
    }
}

pub export fn tool_zig_fflush_retry(stream: ?*FILE) callconv(.c) bool {
    const EINTR_VAL: c_int = 4;
    var res: c_int = 0;
    while (true) {
        res = fflush(stream);
        if (res == 0 or getErrno() != EINTR_VAL) break;
    }
    return res == 0;
}

pub export fn tool_zig_gettime_now(secs: *curl_off_t, usecs: *c_uint) callconv(.c) void {
    const now = tvrealnow();
    secs.* = @intCast(now.tv_sec);
    usecs.* = @intCast(now.tv_usec);
}

pub export fn tool_zig_strftime_utc(secs: curl_off_t, fmt: [*:0]const u8, output: [*]u8, outsize: usize) callconv(.c) bool {
    var utc: tm = std.mem.zeroes(tm);
    if (curlx_gmtime(@intCast(secs), &utc) != CURLE_OK) {
        return false;
    }
    if (strftime(output, outsize, fmt, &utc) == 0) {
        return false;
    }
    return true;
}

pub const tm = extern struct {
    tm_sec: c_int = 0,
    tm_min: c_int = 0,
    tm_hour: c_int = 0,
    tm_mday: c_int = 0,
    tm_mon: c_int = 0,
    tm_year: c_int = 0,
    tm_wday: c_int = 0,
    tm_yday: c_int = 0,
    tm_isdst: c_int = 0,
    tm_gmtoff: if (is_windows) void else c_long = if (is_windows) {} else 0,
    tm_zone: if (is_windows) void else ?[*:0]const u8 = if (is_windows) {} else null,
};
