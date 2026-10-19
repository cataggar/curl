const std = @import("std");
const builtin = @import("builtin");
const backend_options = @import("backend_options");
const mem = @import("mem.zig");
const primitives = @import("primitives.zig");
const containers = @import("containers.zig");
const collections = @import("collections.zig");
const curlx_time_net = @import("curlx_time_net.zig");
const urlapi = @import("urlapi.zig");
const protocol_version_mime = @import("protocol_version_mime.zig");
const vtls_core = @import("vtls_core.zig");
const vtls_scache_asn1 = @import("vtls_scache_asn1.zig");
const altsvc_hsts_peer = @import("altsvc_hsts_peer.zig");
const http1_options = @import("http1_options.zig");
const netrc_addr_idn = @import("netrc_addr_idn.zig");
const setopt = @import("setopt.zig");
const ftp = @import("ftp.zig");

const is_windows = builtin.os.tag == .windows;
const has_ssl_backend = switch (backend_options.ssl) {
    .openssl, .mbedtls, .schannel => true,
    .none, .sectransport => false,
};

pub const CURLcode = c_uint;
pub const CURLUcode = c_uint;
pub const curl_off_t = i64;
pub const curl_prot_t = i64;
pub const timediff_t = i64;
pub const curl_socket_t = curlx_time_net.curl_socket_t;
pub const Curltime = curlx_time_net.Curltime;

pub const Curl_easy = setopt.Curl_easy;
pub const Curl_multi = opaque {};
pub const connectdata = ftp.connectdata;
pub const CURLU = urlapi.Curl_URL;
pub const Curl_scheme = protocol_version_mime.Curl_scheme;
pub const CurlProtocol = ftp.CurlProtocol;
pub const CurlPeer = altsvc_hsts_peer.CurlPeer;
pub const Altsvc = altsvc_hsts_peer.Altsvc;
pub const Altsvcinfo = altsvc_hsts_peer.Altsvcinfo;
pub const Curl_creds = http1_options.Curl_creds;
pub const SslFilterConfig = vtls_scache_asn1.SslFilterConfig;
pub const SslEasyConfig = vtls_scache_asn1.SslEasyConfig;
pub const curl_slist = protocol_version_mime.curl_slist;
pub const curl_mimepart = protocol_version_mime.curl_mimepart;
pub const curl_blob = setopt.curl_blob;
pub const Curl_hash = collections.Curl_hash;

pub const Curl_meta_dtor = *const fn (key: ?*const anyopaque, key_len: usize, meta_data: ?*anyopaque) callconv(.c) void;

pub const proxy_info = extern struct {
    peer: ?*CurlPeer,
    creds: ?*Curl_creds,
    proxytype: u8,
};

pub const urlpieces = extern struct {
    options: ?[*:0]u8,
    path: ?[*:0]u8,
    query: ?[*:0]u8,
};

pub const url_conn_match = struct {
    found: ?*connectdata = null,
    data: *Curl_easy,
    needle: *connectdata,
    now: Curltime = .{ .tv_sec = 0, .tv_usec = 0 },
    ssl_config: SslFilterConfig = std.mem.zeroes(SslFilterConfig),
    proxy_ssl_config: SslFilterConfig = std.mem.zeroes(SslFilterConfig),
    may_multiplex: bool = false,
    want_ntlm_http: bool = false,
    want_proxy_ntlm_http: bool = false,
    want_nego_http: bool = false,
    want_proxy_nego_http: bool = false,
    may_tls: bool = false,
    require_tls: bool = false,
    wait_pipe: bool = false,
    seen_pending_conn: bool = false,
    seen_single_use_conn: bool = false,
    seen_multiplex_conn: bool = false,
};

// CURLcode constants
pub const CURLE_OK: CURLcode = 0;
pub const CURLE_UNSUPPORTED_PROTOCOL: CURLcode = 1;
pub const CURLE_FAILED_INIT: CURLcode = 2;
pub const CURLE_URL_MALFORMAT: CURLcode = 3;
pub const CURLE_READ_ERROR: CURLcode = 26;
pub const CURLE_OUT_OF_MEMORY: CURLcode = 27;
pub const CURLE_BAD_FUNCTION_ARGUMENT: CURLcode = 43;
pub const CURLE_LOGIN_DENIED: CURLcode = 67;
pub const CURLE_AGAIN: CURLcode = 81;
pub const CURLE_NO_CONNECTION_AVAILABLE: CURLcode = 82;

// CURLUcode constants
pub const CURLUE_OK: CURLUcode = 0;
pub const CURLUE_UNSUPPORTED_SCHEME: CURLUcode = 2;
pub const CURLUE_USER_NOT_ALLOWED: CURLUcode = 8;
pub const CURLUE_NO_SCHEME: CURLUcode = 10;
pub const CURLUE_NO_USER: CURLUcode = 11;
pub const CURLUE_NO_PASSWORD: CURLUcode = 12;
pub const CURLUE_NO_OPTIONS: CURLUcode = 13;
pub const CURLUE_NO_QUERY: CURLUcode = 16;
pub const CURLUE_OUT_OF_MEMORY: CURLUcode = 29;

// CURLUPart constants
pub const CURLUPART_URL: c_uint = 0;
pub const CURLUPART_SCHEME: c_uint = 1;
pub const CURLUPART_USER: c_uint = 2;
pub const CURLUPART_PASSWORD: c_uint = 3;
pub const CURLUPART_OPTIONS: c_uint = 4;
pub const CURLUPART_PATH: c_uint = 7;
pub const CURLUPART_QUERY: c_uint = 8;

// CURLU flags
pub const CURLU_NON_SUPPORT_SCHEME: c_uint = 1 << 1;
pub const CURLU_PATH_AS_IS: c_uint = 1 << 4;
pub const CURLU_DISALLOW_USER: c_uint = 1 << 5;
pub const CURLU_URLDECODE: c_uint = 1 << 6;
pub const CURLU_URLENCODE: c_uint = 1 << 7;
pub const CURLU_GUESS_SCHEME: c_uint = 1 << 9;
pub const CURLU_NO_GUESS_SCHEME: c_uint = 1 << 10;
pub const CURLU_GET_EMPTY: c_uint = 1 << 15;

// Protocol flags & families
pub const PROTOPT_SSL: u32 = protocol_version_mime.PROTOPT_SSL;
pub const PROTOPT_NONETWORK: u32 = protocol_version_mime.PROTOPT_NONETWORK;
pub const PROTOPT_NEEDSPWD: u32 = protocol_version_mime.PROTOPT_NEEDSPWD;
pub const PROTOPT_CREDSPERREQUEST: u32 = protocol_version_mime.PROTOPT_CREDSPERREQUEST;
pub const PROTOPT_ALPN: u32 = protocol_version_mime.PROTOPT_ALPN;
pub const PROTOPT_WILDCARD: u32 = protocol_version_mime.PROTOPT_WILDCARD;
pub const PROTOPT_USERPWDCTRL: u32 = protocol_version_mime.PROTOPT_USERPWDCTRL;
pub const PROTOPT_SSL_REUSE: u32 = protocol_version_mime.PROTOPT_SSL_REUSE;
pub const PROTOPT_NO_TRANSFER: u32 = protocol_version_mime.PROTOPT_NO_TRANSFER;

pub const CURLPROTO_HTTP: curl_prot_t = protocol_version_mime.CURLPROTO_HTTP;
pub const CURLPROTO_HTTPS: curl_prot_t = protocol_version_mime.CURLPROTO_HTTPS;
pub const CURLPROTO_FTP: curl_prot_t = protocol_version_mime.CURLPROTO_FTP;
pub const CURLPROTO_FTPS: curl_prot_t = protocol_version_mime.CURLPROTO_FTPS;
pub const CURLPROTO_SCP: curl_prot_t = protocol_version_mime.CURLPROTO_SCP;
pub const CURLPROTO_SFTP: curl_prot_t = protocol_version_mime.CURLPROTO_SFTP;
pub const CURLPROTO_FILE: curl_prot_t = protocol_version_mime.CURLPROTO_FILE;
pub const CURLPROTO_WS: curl_prot_t = protocol_version_mime.CURLPROTO_WS;
pub const CURLPROTO_WSS: curl_prot_t = protocol_version_mime.CURLPROTO_WSS;
pub const CURLPROTO_64ALL: curl_prot_t = -1;
pub const CURLPROTO_REDIR: curl_prot_t = CURLPROTO_HTTP | CURLPROTO_HTTPS | CURLPROTO_FTP | CURLPROTO_FTPS;
pub const CURLPROTO_MASK: curl_prot_t = (1 << 30) - 1;

pub const PROTO_FAMILY_HTTP: curl_prot_t = CURLPROTO_HTTP | CURLPROTO_HTTPS | CURLPROTO_WS | CURLPROTO_WSS;
pub const PROTO_FAMILY_FTP: curl_prot_t = CURLPROTO_FTP | CURLPROTO_FTPS;
pub const PROTO_FAMILY_SSH: curl_prot_t = CURLPROTO_SCP | CURLPROTO_SFTP;

// Transport & socket constants
pub const FIRSTSOCKET: i8 = 0;
pub const SECONDARYSOCKET: i8 = 1;
pub const CURL_SOCKET_BAD: curl_socket_t = if (is_windows)
    std.math.maxInt(curl_socket_t)
else
    -1;
pub const TRNSPRT_TCP: u8 = 3;
pub const TRNSPRT_QUIC: u8 = 5;
pub const TRNSPRT_UNIX: u8 = 6;
pub const CURL_CF_SSL_DEFAULT: c_int = 0;

// Cpool match result
pub const cpool_match_result = c_int;
pub const CPOOL_MATCH_CONT: cpool_match_result = 0;
pub const CPOOL_MATCH_FOUND: cpool_match_result = 1;
pub const CPOOL_MATCH_TOO_OLD: cpool_match_result = 2;
pub const CPOOL_MATCH_CLOSE: cpool_match_result = 3;

// Proxy types
pub const CURLPROXY_HTTP: u8 = 0;
pub const CURLPROXY_HTTPS: u8 = 2;
pub const CURLPROXY_HTTPS2: u8 = 3;
pub const CURLPROXY_SOCKS5: u8 = 5;
pub const CURLPROXY_SOCKS5_HOSTNAME: u8 = 7;

// HTTP negotiation flags
pub const CURL_HTTP_V1x: u8 = 1 << 0;
pub const CURL_HTTP_V2x: u8 = 1 << 1;
pub const CURL_HTTP_V3x: u8 = 1 << 2;

pub const ALPN_none: c_uint = 0;
pub const ALPN_h1: c_uint = 1 << 3;
pub const ALPN_h2: c_uint = 1 << 4;
pub const ALPN_h3: c_uint = 1 << 5;

// Auth & TLS constants
pub const CURLAUTH_NONE: u32 = 0;
pub const CURLAUTH_BASIC: u32 = 1 << 0;
pub const CURLAUTH_NEGOTIATE: u32 = 1 << 2;
pub const CURLAUTH_GSSAPI: u32 = CURLAUTH_NEGOTIATE;
pub const CURLAUTH_NTLM: u32 = 1 << 3;

pub const NTLMSTATE_NONE: i64 = 0;
pub const CURL_NEGO_AUTH_NONE: i64 = 0;

pub const CURLUSESSL_NONE: i64 = 0;
pub const CURLUSESSL_CONTROL: i64 = 2;
pub const CURL_SSLVERSION_DEFAULT: c_long = 0;
pub const CURL_IPRESOLVE_WHATEVER: i64 = 0;

pub const CREDS_NONE: u32 = http1_options.CREDS_NONE;
pub const CREDS_URL: u32 = http1_options.CREDS_URL;
pub const CREDS_OPTION: u32 = http1_options.CREDS_OPTION;
pub const CREDS_NETRC: u32 = http1_options.CREDS_NETRC;

pub const CURL_NETRC_OPTIONAL: i64 = 1;
pub const CURL_NETRC_REQUIRED: i64 = 2;
pub const NETRC_OK: c_uint = netrc_addr_idn.NETRC_OK;
pub const NETRC_NO_MATCH: c_uint = netrc_addr_idn.NETRC_NO_MATCH;
pub const NETRC_OUT_OF_MEMORY: c_uint = netrc_addr_idn.NETRC_OUT_OF_MEMORY;

pub const REJECT_CTRL: c_uint = 3;
pub const REJECT_ZERO: c_uint = 4;

// Default constants for Curl_init_userdefined / Curl_open
pub const CURLEASY_MAGIC_NUMBER: i64 = 0xc0dedbad;
pub const CURL_MAX_HTTP_HEADER: usize = 100 * 1024;
pub const HTTPREQ_GET: i64 = 0;
pub const HTTPREQ_HEAD: i64 = 5;
pub const RTSPREQ_OPTIONS: i64 = 1;
pub const FTPFILE_MULTICWD: i64 = 1;
pub const CURLSSH_AUTH_DEFAULT: i64 = -1;
pub const READBUFFER_SIZE: i64 = 16384;
pub const UPLOADBUFFER_DEFAULT: i64 = 65536;
pub const CURLULFLAG_SEEN: i64 = 1 << 0;
pub const CURL_HET_DEFAULT: i64 = 200;
pub const CURL_UPKEEP_INTERVAL_DEFAULT: i64 = 60000;
pub const DEFAULT_CONNCACHE_SIZE: i64 = 5;
pub const CURL_HTTP_VERSION_NONE: i64 = 0;
pub const TIMER_POSTQUEUE: c_uint = 2;
pub const TIMER_NAMELOOKUP: c_uint = 3;

pub const CURL_DEFAULT_USER: [*:0]const u8 = "anonymous";
pub const CURL_DEFAULT_PASSWORD: [*:0]const u8 = "ftp@example.com";
pub const CURL_META_SSH_CONN: [*:0]const u8 = "meta:proto:ssh:conn";

// String & Blob indices from setopt.zig / urldata.h
pub const STRING_ALTSVC: u8 = @intCast(setopt.STRING_ALTSVC);
pub const STRING_BEARER: u8 = @intCast(setopt.STRING_BEARER);
pub const STRING_COOKIEJAR: u8 = @intCast(setopt.STRING_COOKIEJAR);
pub const STRING_DEFAULT_PROTOCOL: u8 = @intCast(setopt.STRING_DEFAULT_PROTOCOL);
pub const STRING_INTERFACE_OPT: u8 = @intCast(setopt.STRING_INTERFACE_OPT);
pub const STRING_HSTS: u8 = @intCast(setopt.STRING_HSTS);
pub const STRING_KEY_PASSWD: u8 = @intCast(setopt.STRING_KEY_PASSWD);
pub const STRING_KEY_PASSWD_PROXY: u8 = @intCast(setopt.STRING_KEY_PASSWD_PROXY);
pub const STRING_NETRC_FILE: u8 = @intCast(setopt.STRING_NETRC_FILE);
pub const STRING_OPTIONS: u8 = @intCast(setopt.STRING_OPTIONS);
pub const STRING_PASSWORD: u8 = @intCast(setopt.STRING_PASSWORD);
pub const STRING_PROXYPASSWORD: u8 = @intCast(setopt.STRING_PROXYPASSWORD);
pub const STRING_SASL_AUTHZID: u8 = @intCast(setopt.STRING_SASL_AUTHZID);
pub const STRING_SERVICE_NAME: u8 = @intCast(setopt.STRING_SERVICE_NAME);
pub const STRING_SET_RANGE: u8 = @intCast(setopt.STRING_SET_RANGE);
pub const STRING_SSL_EC_CURVES: u8 = @intCast(setopt.STRING_SSL_EC_CURVES);
pub const STRING_SSL_SIGNATURE_ALGORITHMS: u8 = @intCast(setopt.STRING_SSL_SIGNATURE_ALGORITHMS);
pub const STRING_UNIX_SOCKET_PATH: u8 = @intCast(setopt.STRING_UNIX_SOCKET_PATH);
pub const STRING_USERNAME: u8 = @intCast(setopt.STRING_USERNAME);
pub const BLOB_LAST: u32 = 8;

// Curl_setopt_* IDs in lib/multi.c
const BIT_REUSE_FORBID: c_int = 1;
const BIT_REUSE_FRESH: c_int = 2;
const BIT_VERBOSE: c_int = 3;
const BIT_OPT_NO_BODY: c_int = 6;
const BIT_HTTP09_ALLOWED: c_int = 10;
const BIT_ALLOW_AUTH_TO_OTHER_HOSTS: c_int = 14;
const BIT_SOCKS5_GSSAPI_NEC: c_int = 22;
const BIT_FTP_USE_EPRT: c_int = 25;
const BIT_FTP_USE_EPSV: c_int = 26;
const BIT_FTP_USE_PRET: c_int = 27;
const BIT_FTP_SKIP_IP: c_int = 28;
const BIT_WILDCARD_ENABLED: c_int = 29;
const BIT_DOH_VERIFYPEER: c_int = 34;
const BIT_DOH_VERIFYHOST: c_int = 35;
const BIT_NO_SIGNAL: c_int = 40;
const BIT_TCP_NODELAY: c_int = 41;
const BIT_TCP_KEEPALIVE: c_int = 48;
const BIT_TCP_FASTOPEN: c_int = 49;
const BIT_SSL_ENABLE_ALPN: c_int = 50;
const BIT_PATH_AS_IS: c_int = 51;
const BIT_PIPEWAIT: c_int = 52;
const BIT_DISALLOW_USERNAME_IN_URL: c_int = 55;
const BIT_QUICK_EXIT: c_int = 56;
const BIT_CONNECT_ONLY: c_int = 57;
const BIT_SOCKS5_AUTH_ONLY: c_int = 60;
const BIT_SEP_HEADERS: c_int = 64;
const BIT_WS_RAW_MODE: c_int = 65;
const BIT_WS_NO_AUTO_PONG: c_int = 66;
const BIT_ABSTRACT_UNIX_SOCKET: c_int = 74;
const BIT_IS_FREAD_SET: c_int = 77;

const FIELD_HTTPAUTH: c_int = 1;
const FIELD_PROXYAUTH: c_int = 2;
const FIELD_HTTPWANT: c_int = 3;
const FIELD_RTSPREQ: c_int = 8;
const FIELD_METHOD: c_int = 9;
const FIELD_DNS_CACHE_TIMEOUT_MS: c_int = 10;
const FIELD_MAXCONNECTS: c_int = 11;
const FIELD_SERVER_RESPONSE_TIMEOUT: c_int = 12;
const FIELD_USE_PORT: c_int = 15;
const FIELD_TIMEOUT: c_int = 16;
const FIELD_LOCALPORT: c_int = 18;
const FIELD_LOCALPORTRANGE: c_int = 19;
const FIELD_BUFFER_SIZE: c_int = 20;
const FIELD_UPLOAD_BUFFER_SIZE: c_int = 21;
const FIELD_IPVER: c_int = 23;
const FIELD_SCOPE_ID: c_int = 24;
const FIELD_TCP_KEEPIDLE: c_int = 25;
const FIELD_TCP_KEEPINTVL: c_int = 26;
const FIELD_TCP_KEEPCNT: c_int = 27;
const FIELD_HAPPY_EYEBALLS_TIMEOUT: c_int = 28;
const FIELD_UPKEEP_INTERVAL_MS: c_int = 29;
const FIELD_CONN_MAX_IDLE_MS: c_int = 30;
const FIELD_CONN_MAX_AGE_MS: c_int = 31;
const FIELD_SSL_CA_CACHE_TIMEOUT: c_int = 32;
const FIELD_USE_SSL: c_int = 33;
const FIELD_PROXYPORT: c_int = 36;
const FIELD_PROXYTYPE: c_int = 37;
const FIELD_SOCKS5AUTH: c_int = 38;
const FIELD_MAXREDIRS: c_int = 40;
const FIELD_EXPECT_100_TIMEOUT: c_int = 41;
const FIELD_WEIGHT: c_int = 42;
const FIELD_USE_NETRC: c_int = 45;
const FIELD_FTP_FILEMETHOD: c_int = 46;
const FIELD_NEW_FILE_PERMS: c_int = 51;
const FIELD_SSH_AUTH_TYPES: c_int = 54;
const FIELD_NEW_DIRECTORY_PERMS: c_int = 55;
const FIELD_ALLOWED_PROTOCOLS: c_int = 56;
const FIELD_REDIR_PROTOCOLS: c_int = 57;
const FIELD_POSTFIELDSIZE: c_int = 60;
const FIELD_FILESIZE: c_int = 61;
const FIELD_SET_RESUME_FROM: c_int = 62;
const FIELD_UPLOAD_FLAGS: c_int = 63;
const FIELD_GSSAPI_DELEGATION: c_int = 64;

const PTR_SET_STR_COPYPOSTFIELDS: c_int = 1;
const PTR_SET_POSTFIELDS: c_int = 2;
const PTR_DATA_HSTS: c_int = 3;
const PTR_DATA_SHARE: c_int = 4;
const PTR_SHARE_HSTS: c_int = 5;
const PTR_STATE_HSTSLIST: c_int = 6;
const PTR_SET_CONNECT_TO: c_int = 17;
const PTR_SET_MIMEPOSTP: c_int = 18;
const PTR_STATE_FORMP: c_int = 19;
const PTR_SET_UH: c_int = 22;
const PTR_SET_ERR: c_int = 24;
const PTR_STATE_COOKIELIST: c_int = 26;
const PTR_SHARE_COOKIES: c_int = 27;
const PTR_SET_IN_SET: c_int = 33;
const PTR_SET_OUT: c_int = 34;
const PTR_SET_SEEK_CLIENT: c_int = 37;
const PTR_SET_CLOSESOCKET_CLIENT: c_int = 42;
const PTR_SET_HSTS_READ_USERP: c_int = 47;
const PTR_SET_HSTS_WRITE_USERP: c_int = 48;
const PTR_DATA_ASI: c_int = 49;
const PTR_SET_FWRITE_FUNC: c_int = 54;
const PTR_SET_FREAD_FUNC_SET: c_int = 55;
const PTR_SET_FCLOSESOCKET: c_int = 61;
const PTR_SET_CHUNK_BGN: c_int = 64;
const PTR_SET_CHUNK_END: c_int = 65;
const PTR_SET_FNMATCH: c_int = 66;
const PTR_SET_HSTS_READ: c_int = 68;
const PTR_SET_HSTS_WRITE: c_int = 69;

const PTR_REF_STATE_PROXYDIGEST: c_int = 1;
const PTR_REF_DATA_HSTS: c_int = 3;
const PTR_REF_DATA_ASI: c_int = 4;
const PTR_REF_STATE_URL: c_int = 5;
const PTR_REF_DATA_COOKIES: c_int = 6;
const PTR_REF_STATE_REFERER: c_int = 8;
const PTR_REF_SET_SSL: c_int = 12;
const PTR_REF_SET_PROXY_SSL: c_int = 13;

// Build flags from Curl_zig_url_build_flags()
const FLAG_USE_SSL: u32 = 1 << 0;
const FLAG_USE_NTLM: u32 = 1 << 1;
const FLAG_USE_SPNEGO: u32 = 1 << 2;
const FLAG_USE_IPV6: u32 = 1 << 4;
const FLAG_USE_UNIX_SOCKETS: u32 = 1 << 5;
const FLAG_USE_HTTP2: u32 = 1 << 6;
const FLAG_USE_HTTP3: u32 = 1 << 7;
const FLAG_USE_SSH: u32 = 1 << 8;
const FLAG_HAVE_GSSAPI_OR_SSPI: u32 = 1 << 9;
const FLAG_DISABLE_PROXY: u32 = 1 << 10;
const FLAG_DISABLE_HTTP: u32 = 1 << 11;
const FLAG_DISABLE_FTP: u32 = 1 << 12;
const FLAG_DISABLE_NETRC: u32 = 1 << 13;
const FLAG_DISABLE_ALTSVC: u32 = 1 << 14;
const FLAG_DISABLE_HSTS: u32 = 1 << 15;
const FLAG_DISABLE_DOH: u32 = 1 << 16;
const FLAG_DISABLE_COOKIES: u32 = 1 << 17;
const FLAG_DISABLE_DIGEST_AUTH: u32 = 1 << 18;
const FLAG_DISABLE_RTSP: u32 = 1 << 19;
const FLAG_DISABLE_BINDLOCAL: u32 = 1 << 20;
const FLAG_DISABLE_VERBOSE_STRINGS: u32 = 1 << 21;
const FLAG_DEBUGBUILD: u32 = 1 << 22;
const FLAG_FORCE_NATIVE_CA: u32 = 1 << 23;
const FLAG_DISABLE_FILE: u32 = 1 << 24;
const FLAG_DISABLE_FORM_API: u32 = 1 << 25;
const FLAG_DISABLE_MIME: u32 = 1 << 26;
const FLAG_DISABLE_WEBSOCKETS: u32 = 1 << 29;

// Curl_zig_url_data_* IDs
const DATA_BIT_INTERNAL: c_int = 1;
const DATA_BIT_RANGESTRINGALLOC: c_int = 2;
const DATA_BIT_USE_RANGE: c_int = 3;
const DATA_BIT_THIS_IS_A_FOLLOW: c_int = 4;
const DATA_BIT_ALLOW_PORT: c_int = 5;
const DATA_BIT_WILDCARDMATCH: c_int = 6;
const DATA_BIT_DONE: c_int = 7;
const DATA_BIT_REQ_NO_BODY: c_int = 8;
const DATA_BIT_AUTHHOST_DONE: c_int = 9;
const DATA_BIT_AUTHPROXY_DONE: c_int = 10;
const DATA_BIT_HTTP_NEG_H2_PRIOR_KNOWLEDGE: c_int = 11;
const DATA_BIT_HTTP_NEG_ONLY_10: c_int = 12;
const DATA_BIT_PROGRESS_HIDE: c_int = 13;

const DATA_I64_MAGIC: c_int = 1;
const DATA_I64_ID: c_int = 2;
const DATA_I64_MID: c_int = 3;
const DATA_I64_MASTER_MID: c_int = 4;
const DATA_I64_LAST_CONN_ID: c_int = 5;
const DATA_I64_LAST_CPID: c_int = 6;
const DATA_I64_RESUME_FROM: c_int = 7;
const DATA_I64_FOLLOWLOCATION: c_int = 8;
const DATA_I64_HTTPREQ: c_int = 9;
const DATA_I64_STATE_WEIGHT: c_int = 10;
const DATA_I64_AUTHHOST_WANT: c_int = 11;
const DATA_I64_AUTHHOST_PICKED: c_int = 12;
const DATA_I64_AUTHPROXY_WANT: c_int = 13;
const DATA_I64_AUTHPROXY_PICKED: c_int = 14;
const DATA_I64_HTTP_NEG_WANTED: c_int = 15;
const DATA_I64_HTTP_NEG_ALLOWED: c_int = 16;
const DATA_I64_HTTP_NEG_PREFERRED: c_int = 17;
const DATA_I64_INFO_CONN_PROTOCOL: c_int = 18;
const DATA_I64_INFO_USED_PROXY: c_int = 19;

const DATA_PTR_MULTI: c_int = 1;
const DATA_PTR_MULTI_EASY: c_int = 2;
const DATA_PTR_CONN: c_int = 3;
const DATA_PTR_STATE_UH: c_int = 4;
const DATA_PTR_STATE_ORIGIN: c_int = 5;
const DATA_PTR_STATE_INITIAL_ORIGIN: c_int = 6;
const DATA_PTR_STATE_CREDS: c_int = 7;
const DATA_PTR_STATE_RANGE: c_int = 8;
const DATA_PTR_MOST_RECENT_FTP_ENTRYPATH: c_int = 9;
const DATA_PTR_STATE_RANGELINE: c_int = 10;
const DATA_PTR_STATE_HTTP_HOST: c_int = 11;
const DATA_PTR_STATE_ENVPROXY: c_int = 12;
const DATA_PTR_INFO_CONTENTTYPE: c_int = 13;
const DATA_PTR_INFO_WOULDREDIRECT: c_int = 14;
const DATA_PTR_INFO_EFFECTIVE_URL: c_int = 15;
const DATA_PTR_INFO_CONN_SCHEME: c_int = 16;
const DATA_PTR_REQ_COOKIEHOST: c_int = 17;
const DATA_PTR_REF_REQ: c_int = 18;
const DATA_PTR_REF_STATE_UP: c_int = 19;
const DATA_PTR_REF_STATE_HEADERB: c_int = 20;
const DATA_PTR_REF_STATE_NETRC: c_int = 21;
const DATA_PTR_REF_STATE_HTTPHDRS: c_int = 22;
const DATA_PTR_REF_WILDCARD: c_int = 23;
const DATA_PTR_REF_STATE_ORIGIN: c_int = 24;
const DATA_PTR_REF_STATE_INITIAL_ORIGIN: c_int = 25;
const DATA_PTR_REF_STATE_RTSP_SESSION_ORIGIN: c_int = 26;
const DATA_PTR_REF_STATE_CREDS: c_int = 27;
const DATA_PTR_REF_META_HASH: c_int = 28;
const DATA_PTR_REF_STATE_DIGEST: c_int = 29;
const DATA_PTR_REF_STATE_RESUME_FROM: c_int = 30;
const DATA_PTR_REF_REQ_MAXDOWNLOAD: c_int = 31;
const DATA_PTR_SET_BLOBS: c_int = 32;

// Curl_zig_url_conn_* IDs
const CONN_BIT_CONNECT_ONLY: c_int = 1;
const CONN_BIT_ORIGIN_IS_PROXY: c_int = 2;
const CONN_BIT_SOCKS5_AUTHENTICATED: c_int = 3;
const CONN_BIT_CLOSE: c_int = 4;
const CONN_BIT_REUSE: c_int = 5;
const CONN_BIT_ALTUSED: c_int = 6;
const CONN_BIT_IPV6: c_int = 7;
const CONN_BIT_DO_MORE: c_int = 8;
const CONN_BIT_PROTOCONNSTART: c_int = 9;
const CONN_BIT_RETRY: c_int = 10;
const CONN_BIT_FTP_USE_EPSV: c_int = 11;
const CONN_BIT_FTP_USE_EPRT: c_int = 12;
const CONN_BIT_UPGRADE_IN_PROGRESS: c_int = 13;
const CONN_BIT_MULTIPLEX: c_int = 14;
const CONN_BIT_TCP_FASTOPEN: c_int = 15;
const CONN_BIT_TLS_ENABLE_ALPN: c_int = 16;
const CONN_BIT_NO_REUSE: c_int = 17;
const CONN_BIT_SHUTDOWN_HANDLER: c_int = 18;

const CONN_I64_CONNECTION_ID: c_int = 1;
const CONN_I64_CPID: c_int = 2;
const CONN_I64_ATTACHED_XFERS: c_int = 3;
const CONN_I64_IP_VERSION: c_int = 4;
const CONN_I64_LOCALPORT: c_int = 5;
const CONN_I64_LOCALPORTRANGE: c_int = 6;
const CONN_I64_HTTPVERSION_SEEN: c_int = 7;
const CONN_I64_GSSAPI_DELEGATION: c_int = 8;
const CONN_I64_HTTP_NTLM_STATE: c_int = 9;
const CONN_I64_PROXY_NTLM_STATE: c_int = 10;
const CONN_I64_HTTP_NEGOTIATE_STATE: c_int = 11;
const CONN_I64_PROXY_NEGOTIATE_STATE: c_int = 12;
const CONN_I64_SCOPE_ID: c_int = 13;
const CONN_I64_TRANSPORT_WANTED: c_int = 14;
const CONN_I64_RECV_IDX: c_int = 15;
const CONN_I64_SEND_IDX: c_int = 16;
const CONN_I64_SOCK_FIRST: c_int = 17;
const CONN_I64_SOCK_SECOND: c_int = 18;
const CONN_I64_SHUTDOWN_START_FIRST: c_int = 19;
const CONN_I64_SHUTDOWN_START_SECOND: c_int = 20;

const CONN_PTR_SCHEME: c_int = 1;
const CONN_PTR_ORIGIN: c_int = 2;
const CONN_PTR_VIA_PEER: c_int = 3;
const CONN_PTR_ORIGIN2: c_int = 4;
const CONN_PTR_VIA_PEER2: c_int = 5;
const CONN_PTR_CREDS: c_int = 6;
const CONN_PTR_CREDS_ORIGIN: c_int = 7;
const CONN_PTR_DESTINATION: c_int = 8;
const CONN_PTR_OPTIONS: c_int = 9;
const CONN_PTR_INTERFACE_OPTS: c_int = 10;
const CONN_PTR_ATTACHED_MULTI: c_int = 11;
const CONN_PTR_CLOSESOCKET_CLIENT: c_int = 12;
const CONN_PTR_FCLOSESOCKET: c_int = 13;
const CONN_PTR_REF_META_HASH: c_int = 14;
const CONN_PTR_REF_ORIGIN: c_int = 15;
const CONN_PTR_REF_VIA_PEER: c_int = 16;
const CONN_PTR_REF_ORIGIN2: c_int = 17;
const CONN_PTR_REF_VIA_PEER2: c_int = 18;
const CONN_PTR_REF_CREDS: c_int = 19;
const CONN_PTR_REF_CREDS_ORIGIN: c_int = 20;
const CONN_PTR_REF_HTTP_PROXY: c_int = 21;
const CONN_PTR_REF_SOCKS_PROXY: c_int = 22;
const CONN_PTR_REF_SSL_CONFIG: c_int = 23;
const CONN_PTR_REF_PROXY_SSL_CONFIG: c_int = 24;
const CONN_PTR_RECV_FIRST: c_int = 25;
const CONN_PTR_SEND_FIRST: c_int = 26;
const CONN_PTR_RECV_SECOND: c_int = 27;
const CONN_PTR_SEND_SECOND: c_int = 28;

// External C accessors & functions
extern fn Curl_zig_url_build_flags() callconv(.c) u32;
extern fn Curl_zig_url_default_stdout() callconv(.c) ?*anyopaque;
extern fn Curl_zig_url_default_stdin() callconv(.c) ?*anyopaque;
extern fn Curl_zig_url_default_ca_path() callconv(.c) ?[*:0]const u8;
extern fn Curl_zig_url_default_ca_bundle() callconv(.c) ?[*:0]const u8;
extern fn Curl_zig_url_easy_sizeof() callconv(.c) usize;
extern fn Curl_zig_url_conn_sizeof() callconv(.c) usize;
extern fn Curl_zig_url_ssh_conn_keys(sshc: ?*const anyopaque, ppriv_key: *?[*:0]const u8, ppub_key: *?[*:0]const u8) callconv(.c) void;
extern fn Curl_zig_url_multi_admin(multi: ?*const Curl_multi) callconv(.c) ?*Curl_easy;
extern fn Curl_zig_url_multi_max_total_connections(multi: ?*const Curl_multi) callconv(.c) usize;
extern fn Curl_zig_url_multi_max_host_connections(multi: ?*const Curl_multi) callconv(.c) usize;
extern fn Curl_zig_url_data_get_bit(data: *const Curl_easy, bit_id: c_int) callconv(.c) bool;
extern fn Curl_zig_url_data_set_bit(data: *Curl_easy, bit_id: c_int, val: bool) callconv(.c) void;
extern fn Curl_zig_url_data_get_i64(data: *const Curl_easy, field_id: c_int) callconv(.c) i64;
extern fn Curl_zig_url_data_set_i64(data: *Curl_easy, field_id: c_int, val: i64) callconv(.c) void;
extern fn Curl_zig_url_data_get_ptr(data: *Curl_easy, ptr_id: c_int) callconv(.c) ?*anyopaque;
extern fn Curl_zig_url_data_set_ptr(data: *Curl_easy, ptr_id: c_int, val: ?*anyopaque) callconv(.c) void;
extern fn Curl_zig_url_conn_get_bit(conn: *const connectdata, bit_id: c_int) callconv(.c) bool;
extern fn Curl_zig_url_conn_set_bit(conn: *connectdata, bit_id: c_int, val: bool) callconv(.c) void;
extern fn Curl_zig_url_conn_get_i64(conn: *const connectdata, field_id: c_int) callconv(.c) i64;
extern fn Curl_zig_url_conn_set_i64(conn: *connectdata, field_id: c_int, val: i64) callconv(.c) void;
extern fn Curl_zig_url_conn_get_ptr(conn: *connectdata, ptr_id: c_int) callconv(.c) ?*anyopaque;
extern fn Curl_zig_url_conn_set_ptr(conn: *connectdata, ptr_id: c_int, val: ?*anyopaque) callconv(.c) void;

extern fn Curl_easy_strset_ptr(data: *Curl_easy) callconv(.c) *collections.u8_strset;
extern fn Curl_u8_strset_init(set: *collections.u8_strset) callconv(.c) void;
extern fn Curl_u8_strset_clear(set: *collections.u8_strset) callconv(.c) void;
extern fn Curl_hash_init(
    h: *Curl_hash,
    slots: usize,
    hash_type: collections.Curl_hash_type,
    dtor: ?collections.Curl_hash_dtor,
) callconv(.c) void;
extern fn Curl_hash_add2(
    h: *Curl_hash,
    key: ?*const anyopaque,
    key_len: usize,
    p: ?*anyopaque,
    dtor: ?collections.Curl_hash_elem_dtor,
) callconv(.c) ?*anyopaque;
extern fn Curl_hash_delete(
    h: *Curl_hash,
    key: ?*const anyopaque,
    key_len: usize,
) callconv(.c) c_int;
extern fn Curl_hash_pick(
    h: *Curl_hash,
    key: ?*const anyopaque,
    key_len: usize,
) callconv(.c) ?*anyopaque;
extern fn Curl_hash_destroy(h: *Curl_hash) callconv(.c) void;
extern fn curlx_memdup0(src: ?[*]const u8, length: usize) callconv(.c) ?[*:0]u8;
extern fn curlx_memzero(dest: ?*anyopaque, n: usize) callconv(.c) void;
extern fn curlx_str_number(linep: *[*:0]const u8, nump: *i64, max: i64) callconv(.c) c_int;
extern fn curl_free(p: ?*anyopaque) callconv(.c) void;
extern fn Curl_easy_blob_ptr(data: *Curl_easy, idx: c_uint) callconv(.c) *?*curl_blob;
extern fn Curl_setopt_default_stderr() callconv(.c) ?*anyopaque;
extern fn Curl_setopt_default_fwrite() callconv(.c) ?*anyopaque;
extern fn Curl_setopt_default_fread() callconv(.c) ?*anyopaque;
extern fn Curl_setopt_get_bit(data: *const Curl_easy, bit_id: c_int) callconv(.c) bool;
extern fn Curl_setopt_set_bit(data: *Curl_easy, bit_id: c_int, val: bool) callconv(.c) void;
extern fn Curl_setopt_get_i64(data: *const Curl_easy, field_id: c_int) callconv(.c) i64;
extern fn Curl_setopt_set_i64(data: *Curl_easy, field_id: c_int, val: i64) callconv(.c) void;
extern fn Curl_setopt_get_ptr(data: *Curl_easy, ptr_id: c_int) callconv(.c) ?*anyopaque;
extern fn Curl_setopt_set_ptr(data: *Curl_easy, ptr_id: c_int, val: ?*anyopaque) callconv(.c) void;
extern fn Curl_setopt_get_ptr_ref(data: *Curl_easy, ref_id: c_int) callconv(.c) ?*anyopaque;

extern fn Curl_infof(data: ?*Curl_easy, fmt: [*:0]const u8, ...) callconv(.c) void;
extern fn Curl_failf(data: ?*Curl_easy, fmt: [*:0]const u8, ...) callconv(.c) void;
extern fn Curl_trc_multi(data: ?*Curl_easy, fmt: [*:0]const u8, ...) callconv(.c) void;
extern fn Curl_trc_is_verbose_fn(data: ?*Curl_easy) callconv(.c) bool;
extern fn curl_maprintf(fmt: [*:0]const u8, ...) callconv(.c) ?[*:0]u8;
extern fn curl_mfprintf(fd: ?*anyopaque, fmt: [*:0]const u8, ...) callconv(.c) c_int;
extern fn getenv(name: [*:0]const u8) callconv(.c) ?[*:0]const u8;

extern const Curl_scheme_http: Curl_scheme;

extern fn curl_url() callconv(.c) ?*CURLU;
extern fn curl_url_dup(in_uh: *const CURLU) callconv(.c) ?*CURLU;
extern fn curl_url_cleanup(uh: ?*CURLU) callconv(.c) void;
extern fn curl_url_get(uh: *const CURLU, what: c_uint, part: *?[*:0]u8, flags: c_uint) callconv(.c) CURLUcode;
extern fn curl_url_set(uh: *CURLU, what: c_uint, part: ?[*:0]const u8, flags: c_uint) callconv(.c) CURLUcode;
extern fn curl_url_strerror(err: CURLUcode) callconv(.c) [*:0]const u8;
extern fn Curl_is_absolute_url(url: [*:0]const u8, buf: ?[*]u8, buflen: usize, guess_scheme: bool) callconv(.c) bool;

extern fn Curl_multi_remove_handle(multi: *Curl_multi, data: *Curl_easy) callconv(.c) c_uint;
extern fn curl_multi_cleanup(multi: *Curl_multi) callconv(.c) c_uint;
extern fn Curl_detach_connection(data: *Curl_easy) callconv(.c) void;
extern fn Curl_attach_connection(data: *Curl_easy, conn: *connectdata, keep_alive: bool) callconv(.c) void;
extern fn Curl_expire_clear_all(data: *Curl_easy) callconv(.c) void;
extern fn Curl_resolv_destroy_all(data: *Curl_easy) callconv(.c) void;
extern fn Curl_req_init(req: *anyopaque) callconv(.c) void;
extern fn Curl_req_free(req: *anyopaque, data: *Curl_easy) callconv(.c) void;
extern fn Curl_req_hard_reset(req: *anyopaque, data: *Curl_easy) callconv(.c) void;
extern fn Curl_req_start(req: *anyopaque, data: *Curl_easy) callconv(.c) CURLcode;
extern fn Curl_initinfo(data: *Curl_easy) callconv(.c) CURLcode;
extern fn Curl_ssl_close_all(data: *Curl_easy) callconv(.c) void;
extern fn Curl_ssl_free_certinfo(data: *Curl_easy) callconv(.c) void;
extern fn Curl_bufref_init(br: *anyopaque) callconv(.c) void;
extern fn Curl_bufref_free(br: *anyopaque) callconv(.c) void;
extern fn Curl_bufref_ptr(br: *const anyopaque) callconv(.c) ?[*:0]const u8;
extern fn Curl_bufref_set(br: *anyopaque, ptr: ?[*]const u8, len: usize, dtor: ?*const anyopaque) callconv(.c) void;
extern fn curl_slist_free_all(list: ?*curl_slist) callconv(.c) void;
extern fn Curl_mime_cleanpart(part: ?*curl_mimepart) callconv(.c) void;
extern fn Curl_wildcard_dtor(wcp: *anyopaque) callconv(.c) void;
extern fn Curl_headers_init(data: *Curl_easy) callconv(.c) CURLcode;
extern fn Curl_headers_cleanup(data: *Curl_easy) callconv(.c) CURLcode;
extern fn Curl_share_easy_unlink(data: *Curl_easy) callconv(.c) CURLcode;
extern fn Curl_flush_cookies(
    data: *Curl_easy,
    cleanup: bool,
    pcookies: *?*anyopaque,
    cookiejar: ?[*:0]const u8,
    share_cookies: ?*anyopaque,
) callconv(.c) void;
extern fn Curl_http_auth_cleanup_digest(
    data: ?*Curl_easy,
    digest: ?*anyopaque,
    proxydigest: ?*anyopaque,
) callconv(.c) void;

extern fn Curl_conn_cf_discard_all(data: ?*Curl_easy, conn: *connectdata, index: i8) callconv(.c) void;
extern fn Curl_conn_is_connected(conn: *connectdata, sockindex: i8) callconv(.c) bool;
extern fn Curl_conn_is_ssl(conn: ?*connectdata, sockindex: i8) callconv(.c) bool;
extern fn Curl_conn_get_max_concurrent(data: *Curl_easy, conn: *connectdata, sockindex: i8) callconv(.c) u32;
extern fn Curl_conn_http_version(data: *Curl_easy, conn: *connectdata) callconv(.c) u8;
extern fn Curl_conn_get_destination(conn: *connectdata, sockindex: i8) callconv(.c) ?*CurlPeer;
extern fn Curl_conn_get_first_peer(conn: *connectdata, sockindex: i8) callconv(.c) ?*CurlPeer;
extern fn Curl_conn_ev_data_setup(data: *Curl_easy) callconv(.c) CURLcode;
extern fn Curl_conn_setup(data: *Curl_easy, conn: *connectdata, sockindex: i8, ssl_mode: c_int) callconv(.c) CURLcode;
extern fn Curl_conn_close(data: *Curl_easy, conn: *connectdata, aborted: bool) callconv(.c) void;
extern fn Curl_cf_recv(data: *Curl_easy, num: c_int, buf: [*]u8, len: usize, pnrcvd: *usize) callconv(.c) CURLcode;
extern fn Curl_cf_send(data: *Curl_easy, num: c_int, buf: [*]const u8, len: usize, eos: bool, pnsent: *usize) callconv(.c) CURLcode;

extern fn Curl_multiplex_wanted(multi: ?*const Curl_multi) callconv(.c) bool;
extern fn Curl_multi_max_concurrent_streams(multi: ?*const Curl_multi) callconv(.c) u32;
extern fn Curl_ftp_conns_match(one: *connectdata, two: *connectdata) callconv(.c) bool;
extern fn Curl_proxy_init_conn(data: *Curl_easy, conn: *connectdata) callconv(.c) CURLcode;
extern fn Curl_xfer_setup_nop(data: *Curl_easy) callconv(.c) void;

pub const CpoolMatchCb = *const fn (conn: *connectdata, userdata: ?*anyopaque) callconv(.c) cpool_match_result;
pub const CpoolResultCb = *const fn (userdata: ?*anyopaque) callconv(.c) bool;

extern fn Curl_cpool_conn_age_ms(data: *Curl_easy, conn: *connectdata, pnow: *const Curltime) callconv(.c) timediff_t;
extern fn Curl_cpool_conn_seems_healthy(conn: *connectdata, data: *Curl_easy, pnow: *const Curltime) callconv(.c) bool;
extern fn Curl_cpool_find(
    data: *Curl_easy,
    destination: ?[*:0]const u8,
    lock: bool,
    pnow: *const Curltime,
    match_cb: CpoolMatchCb,
    result_cb: CpoolResultCb,
    userdata: ?*anyopaque,
) callconv(.c) bool;
extern fn Curl_cpool_add(
    data: *Curl_easy,
    conn: *connectdata,
    max_total_conns: usize,
    max_host_conns: usize,
    pnow: *const Curltime,
) callconv(.c) CURLcode;

extern fn Curl_pgrs_now(data: *Curl_easy) callconv(.c) *const Curltime;
extern fn Curl_pgrsTimeWas(data: *Curl_easy, timer: c_uint, timestamp: Curltime) callconv(.c) void;
extern fn Curl_pgrsTime(data: *Curl_easy, timer: c_uint) callconv(.c) void;
extern fn Curl_pgrsReset(data: *Curl_easy) callconv(.c) void;
extern fn Curl_urldecode(
    string: [*:0]const u8,
    length: usize,
    ostring: *?[*:0]u8,
    olen: ?*usize,
    ctrl: c_uint,
) callconv(.c) CURLcode;
extern fn Curl_auth_allowed_to_origin_ex(
    allow_auth_to_other_hosts: bool,
    initial_origin: ?*CurlPeer,
    origin: ?*CurlPeer,
) callconv(.c) bool;

inline fn buildFlags() u32 {
    return Curl_zig_url_build_flags();
}

inline fn hasFlag(flag: u32) bool {
    return (buildFlags() & flag) != 0;
}

inline fn infof(data: ?*Curl_easy, comptime fmt: [*:0]const u8, args: anytype) void {
    if (!hasFlag(FLAG_DISABLE_VERBOSE_STRINGS) and Curl_trc_is_verbose_fn(data)) {
        @call(.auto, Curl_infof, .{ data, fmt } ++ args);
    }
}

inline fn debugInfof(data: ?*Curl_easy, comptime fmt: [*:0]const u8, args: anytype) void {
    if (hasFlag(FLAG_DEBUGBUILD)) {
        infof(data, fmt, args);
    }
}

inline fn failf(data: ?*Curl_easy, comptime fmt: [*:0]const u8, args: anytype) void {
    if (!hasFlag(FLAG_DISABLE_VERBOSE_STRINGS)) {
        @call(.auto, Curl_failf, .{ data, fmt } ++ args);
    }
}

inline fn easyStr(data: *Curl_easy, id: u8) ?[*:0]const u8 {
    return collections.Curl_u8_strset_get(Curl_easy_strset_ptr(data), id);
}

inline fn easyStrClear0(data: *Curl_easy, id: u8) void {
    collections.Curl_u8_strset_unset0(Curl_easy_strset_ptr(data), id);
}

inline fn connInUse(conn: *const connectdata) bool {
    return Curl_zig_url_conn_get_i64(conn, CONN_I64_ATTACHED_XFERS) > 0;
}

inline fn connScheme(conn: *connectdata) ?*const Curl_scheme {
    return @ptrCast(@alignCast(Curl_zig_url_conn_get_ptr(conn, CONN_PTR_SCHEME)));
}

inline fn schemeRun(scheme: *const Curl_scheme) ?*const CurlProtocol {
    return @ptrCast(@alignCast(scheme.run));
}

inline fn connOrigin(conn: *connectdata) ?*CurlPeer {
    return @ptrCast(@alignCast(Curl_zig_url_conn_get_ptr(conn, CONN_PTR_ORIGIN)));
}

inline fn connViaPeer(conn: *connectdata) ?*CurlPeer {
    return @ptrCast(@alignCast(Curl_zig_url_conn_get_ptr(conn, CONN_PTR_VIA_PEER)));
}

inline fn connCreds(conn: *connectdata) ?*Curl_creds {
    return @ptrCast(@alignCast(Curl_zig_url_conn_get_ptr(conn, CONN_PTR_CREDS)));
}

inline fn connCredsOrigin(conn: *connectdata) ?*CurlPeer {
    return @ptrCast(@alignCast(Curl_zig_url_conn_get_ptr(conn, CONN_PTR_CREDS_ORIGIN)));
}

inline fn connHttpProxy(conn: *connectdata) ?*proxy_info {
    return @ptrCast(@alignCast(Curl_zig_url_conn_get_ptr(conn, CONN_PTR_REF_HTTP_PROXY)));
}

inline fn connSocksProxy(conn: *connectdata) ?*proxy_info {
    return @ptrCast(@alignCast(Curl_zig_url_conn_get_ptr(conn, CONN_PTR_REF_SOCKS_PROXY)));
}

inline fn dataOrigin(data: *Curl_easy) ?*CurlPeer {
    return @ptrCast(@alignCast(Curl_zig_url_data_get_ptr(data, DATA_PTR_STATE_ORIGIN)));
}

inline fn dataInitialOrigin(data: *Curl_easy) ?*CurlPeer {
    return @ptrCast(@alignCast(Curl_zig_url_data_get_ptr(data, DATA_PTR_STATE_INITIAL_ORIGIN)));
}

inline fn dataCreds(data: *Curl_easy) ?*Curl_creds {
    return @ptrCast(@alignCast(Curl_zig_url_data_get_ptr(data, DATA_PTR_STATE_CREDS)));
}

inline fn authAllowedToOrigin(data: *Curl_easy, origin: ?*CurlPeer) bool {
    return Curl_auth_allowed_to_origin_ex(
        Curl_setopt_get_bit(data, BIT_ALLOW_AUTH_TO_OTHER_HOSTS),
        dataInitialOrigin(data),
        origin,
    );
}

inline fn authAllowedToHost(data: *Curl_easy) bool {
    return authAllowedToOrigin(data, dataOrigin(data));
}

inline fn credsUser(c: ?*const Curl_creds) [*:0]const u8 {
    if (c) |creds| {
        return creds.user;
    }
    return "";
}

inline fn credsPasswd(c: ?*const Curl_creds) [*:0]const u8 {
    if (c) |creds| {
        return creds.passwd;
    }
    return "";
}

inline fn credsHasUser(c: ?*const Curl_creds) bool {
    if (c) |creds| {
        return creds.user[0] != 0;
    }
    return false;
}

inline fn credsHasPasswd(c: ?*const Curl_creds) bool {
    if (c) |creds| {
        return creds.passwd[0] != 0;
    }
    return false;
}

// ============================================================================
// Ported static and exported functions from lib/url.c (lines 1–2637)
// ============================================================================

fn get_protocol_family(s: *const Curl_scheme) curl_prot_t {
    return s.family;
}

pub export fn Curl_freeset(data: *Curl_easy) callconv(.c) void {
    easyStrClear0(data, STRING_PASSWORD);
    easyStrClear0(data, STRING_KEY_PASSWD);
    easyStrClear0(data, STRING_BEARER);
    if (!hasFlag(FLAG_DISABLE_PROXY)) {
        easyStrClear0(data, STRING_PROXYPASSWORD);
        easyStrClear0(data, STRING_KEY_PASSWD_PROXY);
    }
    const strset = Curl_easy_strset_ptr(data);
    const slot_cnt: usize = @as(usize, 1) << @intCast(strset.slotbits);
    for (0..slot_cnt) |i| {
        if (strset.data[i]) |s| {
            mem.freeSecretZ(s);
            strset.data[i] = null;
        }
    }
    mem.secureZero(@ptrCast(strset.data), slot_cnt * @sizeOf(?[*:0]u8));
    Curl_u8_strset_clear(strset);

    if (Curl_setopt_get_ptr(data, PTR_SET_STR_COPYPOSTFIELDS)) |p| {
        if (Curl_setopt_get_ptr(data, PTR_SET_POSTFIELDS) == p) {
            Curl_setopt_set_ptr(data, PTR_SET_POSTFIELDS, null);
        }
        mem.free(p);
        Curl_setopt_set_ptr(data, PTR_SET_STR_COPYPOSTFIELDS, null);
    }

    var j: u32 = 0;
    while (j < BLOB_LAST) : (j += 1) {
        const bptr = Curl_easy_blob_ptr(data, j);
        if (bptr.*) |b| {
            const copy = (b.flags & 1) != 0;
            if (copy and b.len > 0) {
                if (b.data) |bdata| {
                    mem.secureZero(bdata, b.len);
                }
            }
            const blob_total = @sizeOf(curl_blob) +| (if (copy) b.len else 0);
            mem.secureZero(@ptrCast(b), blob_total);
            mem.freeSized(@ptrCast(b), blob_total);
            bptr.* = null;
        }
    }

    if (Curl_setopt_get_ptr_ref(data, PTR_REF_STATE_REFERER)) |ref_br| {
        Curl_bufref_free(ref_br);
    }
    if (Curl_setopt_get_ptr_ref(data, PTR_REF_STATE_URL)) |url_br| {
        Curl_bufref_free(url_br);
    }

    if (!hasFlag(FLAG_DISABLE_MIME) or !hasFlag(FLAG_DISABLE_FORM_API)) {
        const mimepostp: ?*curl_mimepart = @ptrCast(@alignCast(Curl_setopt_get_ptr(data, PTR_SET_MIMEPOSTP)));
        Curl_mime_cleanpart(mimepostp);
        if (mimepostp) |mp| {
            mem.freeSized(@ptrCast(mp), @sizeOf(curl_mimepart));
            Curl_setopt_set_ptr(data, PTR_SET_MIMEPOSTP, null);
        }
    }

    if (!hasFlag(FLAG_DISABLE_COOKIES)) {
        const clist: ?*curl_slist = @ptrCast(@alignCast(Curl_setopt_get_ptr(data, PTR_STATE_COOKIELIST)));
        curl_slist_free_all(clist);
        Curl_setopt_set_ptr(data, PTR_STATE_COOKIELIST, null);
    }
}

fn up_free(data: *Curl_easy) void {
    const up: *urlpieces = @ptrCast(@alignCast(Curl_zig_url_data_get_ptr(data, DATA_PTR_REF_STATE_UP).?));
    if (up.options) |p| {
        mem.free(p);
        up.options = null;
    }
    if (up.path) |p| {
        mem.free(p);
        up.path = null;
    }
    if (up.query) |p| {
        mem.free(p);
        up.query = null;
    }
    const uh: ?*CURLU = @ptrCast(@alignCast(Curl_zig_url_data_get_ptr(data, DATA_PTR_STATE_UH)));
    curl_url_cleanup(uh);
    Curl_zig_url_data_set_ptr(data, DATA_PTR_STATE_UH, null);
}

pub export fn Curl_close(datap: ?*?*Curl_easy) callconv(.c) CURLcode {
    const dp = datap orelse return CURLE_OK;
    const data = dp.* orelse return CURLE_OK;
    dp.* = null;
    if (Curl_zig_url_data_get_i64(data, DATA_I64_MAGIC) != CURLEASY_MAGIC_NUMBER) {
        return CURLE_OK;
    }

    const is_internal = Curl_zig_url_data_get_bit(data, DATA_BIT_INTERNAL);
    const multi: ?*Curl_multi = @ptrCast(@alignCast(Curl_zig_url_data_get_ptr(data, DATA_PTR_MULTI)));
    if (!is_internal and multi != null) {
        _ = Curl_multi_remove_handle(multi.?, data);
    } else {
        Curl_detach_connection(data);
        const multi_easy: ?*Curl_multi = @ptrCast(@alignCast(Curl_zig_url_data_get_ptr(data, DATA_PTR_MULTI_EASY)));
        if (!is_internal and multi_easy != null) {
            Curl_zig_url_data_set_ptr(data, DATA_PTR_MULTI_EASY, null);
            _ = curl_multi_cleanup(multi_easy.?);
        }
    }

    Curl_expire_clear_all(data);

    if (Curl_zig_url_data_get_bit(data, DATA_BIT_RANGESTRINGALLOC)) {
        if (Curl_zig_url_data_get_ptr(data, DATA_PTR_STATE_RANGE)) |r| {
            mem.free(r);
            Curl_zig_url_data_set_ptr(data, DATA_PTR_STATE_RANGE, null);
        }
        Curl_zig_url_data_set_bit(data, DATA_BIT_RANGESTRINGALLOC, false);
    }

    Curl_resolv_destroy_all(data);

    Curl_setopt_set_bit(data, BIT_VERBOSE, false);
    Curl_zig_url_data_set_i64(data, DATA_I64_MAGIC, 0);

    if (Curl_zig_url_data_get_ptr(data, DATA_PTR_REF_REQ)) |req| {
        Curl_req_free(req, data);
    }

    if (comptime has_ssl_backend) {
        Curl_ssl_close_all(data);
    }
    if (Curl_zig_url_data_get_ptr(data, DATA_PTR_REF_STATE_ORIGIN)) |p| {
        altsvc_hsts_peer.Curl_peer_unlink(@ptrCast(@alignCast(p)));
    }
    if (Curl_zig_url_data_get_ptr(data, DATA_PTR_REF_STATE_INITIAL_ORIGIN)) |p| {
        altsvc_hsts_peer.Curl_peer_unlink(@ptrCast(@alignCast(p)));
    }
    if (!hasFlag(FLAG_DISABLE_RTSP)) {
        if (Curl_zig_url_data_get_ptr(data, DATA_PTR_REF_STATE_RTSP_SESSION_ORIGIN)) |p| {
            altsvc_hsts_peer.Curl_peer_unlink(@ptrCast(@alignCast(p)));
        }
    }
    if (comptime has_ssl_backend) {
        Curl_ssl_free_certinfo(data);
    }

    if (Curl_setopt_get_ptr_ref(data, PTR_REF_STATE_REFERER)) |ref_br| {
        Curl_bufref_free(ref_br);
    }

    up_free(data);
    if (Curl_zig_url_data_get_ptr(data, DATA_PTR_REF_STATE_HEADERB)) |hb| {
        containers.curlx_dyn_free(@ptrCast(@alignCast(hb)));
    }
    if (!hasFlag(FLAG_DISABLE_HTTP) and !hasFlag(FLAG_DISABLE_COOKIES)) {
        if (Curl_setopt_get_ptr_ref(data, PTR_REF_DATA_COOKIES)) |pcookies| {
            Curl_flush_cookies(
                data,
                true,
                @ptrCast(@alignCast(pcookies)),
                easyStr(data, STRING_COOKIEJAR),
                Curl_setopt_get_ptr(data, PTR_SHARE_COOKIES),
            );
        }
    }
    if (!hasFlag(FLAG_DISABLE_ALTSVC)) {
        const asi: ?*Altsvcinfo = @ptrCast(@alignCast(Curl_setopt_get_ptr(data, PTR_DATA_ASI)));
        _ = altsvc_hsts_peer.Curl_altsvc_save(data, asi, easyStr(data, STRING_ALTSVC));
        if (Curl_setopt_get_ptr_ref(data, PTR_REF_DATA_ASI)) |asip| {
            altsvc_hsts_peer.Curl_altsvc_cleanup(@ptrCast(@alignCast(asip)));
        }
    }
    if (!hasFlag(FLAG_DISABLE_HTTP) and !hasFlag(FLAG_DISABLE_HSTS)) {
        const hsts: ?*altsvc_hsts_peer.Hsts = @ptrCast(@alignCast(Curl_setopt_get_ptr(data, PTR_DATA_HSTS)));
        const hsts_write: ?altsvc_hsts_peer.HstsWriteCallback = @ptrCast(@alignCast(Curl_setopt_get_ptr(data, PTR_SET_HSTS_WRITE)));
        const hsts_write_userp = Curl_setopt_get_ptr(data, PTR_SET_HSTS_WRITE_USERP);
        _ = altsvc_hsts_peer.Curl_hsts_save(data, hsts, easyStr(data, STRING_HSTS), hsts_write, hsts_write_userp);
        if (Curl_setopt_get_ptr(data, PTR_DATA_SHARE) == null or Curl_setopt_get_ptr(data, PTR_SHARE_HSTS) == null) {
            if (Curl_setopt_get_ptr_ref(data, PTR_REF_DATA_HSTS)) |hp| {
                altsvc_hsts_peer.Curl_hsts_cleanup(@ptrCast(@alignCast(hp)));
            }
        }
        const hstslist: ?*curl_slist = @ptrCast(@alignCast(Curl_setopt_get_ptr(data, PTR_STATE_HSTSLIST)));
        curl_slist_free_all(hstslist);
        Curl_setopt_set_ptr(data, PTR_STATE_HSTSLIST, null);
    }
    if (!hasFlag(FLAG_DISABLE_HTTP) and !hasFlag(FLAG_DISABLE_DIGEST_AUTH)) {
        Curl_http_auth_cleanup_digest(
            data,
            Curl_zig_url_data_get_ptr(data, DATA_PTR_REF_STATE_DIGEST),
            Curl_setopt_get_ptr_ref(data, PTR_REF_STATE_PROXYDIGEST),
        );
    }

    inline for (.{
        DATA_PTR_MOST_RECENT_FTP_ENTRYPATH,
        DATA_PTR_INFO_CONTENTTYPE,
        DATA_PTR_INFO_WOULDREDIRECT,
        DATA_PTR_INFO_EFFECTIVE_URL,
    }) |pid| {
        if (Curl_zig_url_data_get_ptr(data, pid)) |p| {
            mem.free(p);
            Curl_zig_url_data_set_ptr(data, pid, null);
        }
    }

    _ = Curl_share_easy_unlink(data);

    if (Curl_zig_url_data_get_ptr(data, DATA_PTR_REF_META_HASH)) |mh| {
        Curl_hash_destroy(@ptrCast(@alignCast(mh)));
    }
    if (Curl_zig_url_data_get_ptr(data, DATA_PTR_REF_STATE_CREDS)) |cp| {
        http1_options.Curl_creds_unlink(@ptrCast(@alignCast(cp)));
    }
    if (!hasFlag(FLAG_DISABLE_HTTP)) {
        inline for (.{ DATA_PTR_STATE_RANGELINE, DATA_PTR_STATE_HTTP_HOST }) |pid| {
            if (Curl_zig_url_data_get_ptr(data, pid)) |p| {
                mem.free(p);
                Curl_zig_url_data_set_ptr(data, pid, null);
            }
        }
    }
    if (!hasFlag(FLAG_DISABLE_COOKIES)) {
        if (Curl_zig_url_data_get_ptr(data, DATA_PTR_REQ_COOKIEHOST)) |p| {
            mem.free(p);
            Curl_zig_url_data_set_ptr(data, DATA_PTR_REQ_COOKIEHOST, null);
        }
    }
    if (!hasFlag(FLAG_DISABLE_HTTP) and !hasFlag(FLAG_DISABLE_FORM_API)) {
        const formp: ?*curl_mimepart = @ptrCast(@alignCast(Curl_setopt_get_ptr(data, PTR_STATE_FORMP)));
        Curl_mime_cleanpart(formp);
        if (formp) |fp| {
            mem.freeSized(@ptrCast(fp), @sizeOf(curl_mimepart));
            Curl_setopt_set_ptr(data, PTR_STATE_FORMP, null);
        }
    }

    if (Curl_zig_url_data_get_ptr(data, DATA_PTR_REF_WILDCARD)) |wc| {
        Curl_wildcard_dtor(wc);
    }
    Curl_freeset(data);
    _ = Curl_headers_cleanup(data);
    if (Curl_zig_url_data_get_ptr(data, DATA_PTR_REF_STATE_NETRC)) |nr| {
        netrc_addr_idn.Curl_netrc_cleanup(@ptrCast(@alignCast(nr)));
    }
    if (!hasFlag(FLAG_DISABLE_DIGEST_AUTH)) {
        if (Curl_zig_url_data_get_ptr(data, DATA_PTR_STATE_ENVPROXY)) |ep| {
            mem.free(ep);
            Curl_zig_url_data_set_ptr(data, DATA_PTR_STATE_ENVPROXY, null);
        }
    }

    const easy_size = Curl_zig_url_easy_sizeof();
    mem.secureZero(@ptrCast(data), easy_size);
    mem.freeSized(@ptrCast(data), easy_size);
    return CURLE_OK;
}

pub export fn Curl_init_userdefined(data: *Curl_easy) callconv(.c) void {
    Curl_setopt_set_ptr(data, PTR_SET_OUT, Curl_zig_url_default_stdout());
    Curl_setopt_set_ptr(data, PTR_SET_IN_SET, Curl_zig_url_default_stdin());
    Curl_setopt_set_ptr(data, PTR_SET_ERR, Curl_setopt_default_stderr());

    Curl_u8_strset_init(Curl_easy_strset_ptr(data));

    Curl_setopt_set_ptr(data, PTR_SET_FWRITE_FUNC, Curl_setopt_default_fwrite());
    Curl_setopt_set_ptr(data, PTR_SET_FREAD_FUNC_SET, Curl_setopt_default_fread());
    Curl_setopt_set_bit(data, BIT_IS_FREAD_SET, false);

    Curl_setopt_set_ptr(data, PTR_SET_SEEK_CLIENT, null);

    Curl_setopt_set_i64(data, FIELD_FILESIZE, -1);
    Curl_setopt_set_i64(data, FIELD_POSTFIELDSIZE, -1);
    Curl_setopt_set_i64(data, FIELD_MAXREDIRS, 30);

    Curl_setopt_set_i64(data, FIELD_METHOD, HTTPREQ_GET);
    if (!hasFlag(FLAG_DISABLE_RTSP)) {
        Curl_setopt_set_i64(data, FIELD_RTSPREQ, RTSPREQ_OPTIONS);
    }
    if (!hasFlag(FLAG_DISABLE_FTP)) {
        Curl_setopt_set_bit(data, BIT_FTP_USE_EPSV, true);
        Curl_setopt_set_bit(data, BIT_FTP_USE_EPRT, true);
        Curl_setopt_set_bit(data, BIT_FTP_USE_PRET, false);
        Curl_setopt_set_i64(data, FIELD_FTP_FILEMETHOD, FTPFILE_MULTICWD);
        Curl_setopt_set_bit(data, BIT_FTP_SKIP_IP, true);
    }
    Curl_setopt_set_i64(data, FIELD_DNS_CACHE_TIMEOUT_MS, 60000);
    Curl_setopt_set_i64(data, FIELD_SSL_CA_CACHE_TIMEOUT, 24 * 60 * 60);
    Curl_setopt_set_i64(data, FIELD_HTTPAUTH, @intCast(CURLAUTH_BASIC));

    if (Curl_setopt_get_ptr_ref(data, PTR_REF_SET_SSL)) |sslc| {
        vtls_scache_asn1.Curl_ssl_config_init(@ptrCast(@alignCast(sslc)));
    }
    if (!hasFlag(FLAG_DISABLE_PROXY)) {
        if (Curl_setopt_get_ptr_ref(data, PTR_REF_SET_PROXY_SSL)) |psslc| {
            vtls_scache_asn1.Curl_ssl_config_init(@ptrCast(@alignCast(psslc)));
        }
        Curl_setopt_set_i64(data, FIELD_PROXYPORT, 0);
        Curl_setopt_set_i64(data, FIELD_PROXYTYPE, CURLPROXY_HTTP);
        Curl_setopt_set_i64(data, FIELD_PROXYAUTH, @intCast(CURLAUTH_BASIC));
        Curl_setopt_set_i64(data, FIELD_SOCKS5AUTH, @intCast(CURLAUTH_BASIC | CURLAUTH_GSSAPI));
    }

    if (!hasFlag(FLAG_DISABLE_DOH)) {
        Curl_setopt_set_bit(data, BIT_DOH_VERIFYHOST, true);
        Curl_setopt_set_bit(data, BIT_DOH_VERIFYPEER, true);
    }
    if (hasFlag(FLAG_USE_SSH)) {
        Curl_setopt_set_i64(data, FIELD_SSH_AUTH_TYPES, CURLSSH_AUTH_DEFAULT);
        Curl_setopt_set_i64(data, FIELD_NEW_DIRECTORY_PERMS, 0o755);
    }

    Curl_setopt_set_i64(data, FIELD_NEW_FILE_PERMS, 0o644);
    Curl_setopt_set_i64(data, FIELD_ALLOWED_PROTOCOLS, CURLPROTO_64ALL);
    Curl_setopt_set_i64(data, FIELD_REDIR_PROTOCOLS, CURLPROTO_REDIR);

    if (hasFlag(FLAG_HAVE_GSSAPI_OR_SSPI)) {
        Curl_setopt_set_bit(data, BIT_SOCKS5_GSSAPI_NEC, false);
    }

    if (hasFlag(FLAG_USE_SSL)) {
        _ = setopt.Curl_setopt_SSLVERSION(data, setopt.CURLOPT_SSLVERSION, CURL_SSLVERSION_DEFAULT);
        if (!hasFlag(FLAG_DISABLE_PROXY)) {
            _ = setopt.Curl_setopt_SSLVERSION(data, setopt.CURLOPT_PROXY_SSLVERSION, CURL_SSLVERSION_DEFAULT);
        }
    }

    if (!hasFlag(FLAG_DISABLE_FTP)) {
        Curl_setopt_set_bit(data, BIT_WILDCARD_ENABLED, false);
        Curl_setopt_set_ptr(data, PTR_SET_CHUNK_BGN, null);
        Curl_setopt_set_ptr(data, PTR_SET_CHUNK_END, null);
        Curl_setopt_set_ptr(data, PTR_SET_FNMATCH, null);
    }

    Curl_setopt_set_bit(data, BIT_TCP_KEEPALIVE, false);
    Curl_setopt_set_i64(data, FIELD_TCP_KEEPINTVL, 60);
    Curl_setopt_set_i64(data, FIELD_TCP_KEEPIDLE, 60);
    Curl_setopt_set_i64(data, FIELD_TCP_KEEPCNT, 9);
    Curl_setopt_set_bit(data, BIT_TCP_FASTOPEN, false);
    Curl_setopt_set_bit(data, BIT_TCP_NODELAY, true);
    Curl_setopt_set_bit(data, BIT_SSL_ENABLE_ALPN, true);
    Curl_setopt_set_i64(data, FIELD_EXPECT_100_TIMEOUT, 1000);
    Curl_setopt_set_bit(data, BIT_SEP_HEADERS, true);
    Curl_setopt_set_i64(data, FIELD_BUFFER_SIZE, READBUFFER_SIZE);
    Curl_setopt_set_i64(data, FIELD_UPLOAD_BUFFER_SIZE, UPLOADBUFFER_DEFAULT);
    Curl_setopt_set_i64(data, FIELD_UPLOAD_FLAGS, CURLULFLAG_SEEN);
    Curl_setopt_set_i64(data, FIELD_HAPPY_EYEBALLS_TIMEOUT, CURL_HET_DEFAULT);
    Curl_setopt_set_i64(data, FIELD_UPKEEP_INTERVAL_MS, CURL_UPKEEP_INTERVAL_DEFAULT);
    Curl_setopt_set_i64(data, FIELD_MAXCONNECTS, DEFAULT_CONNCACHE_SIZE);
    Curl_setopt_set_i64(data, FIELD_CONN_MAX_IDLE_MS, 118 * 1000);
    Curl_setopt_set_i64(data, FIELD_CONN_MAX_AGE_MS, 24 * 3600 * 1000);
    Curl_setopt_set_bit(data, BIT_HTTP09_ALLOWED, false);
    Curl_setopt_set_i64(data, FIELD_HTTPWANT, CURL_HTTP_VERSION_NONE);
    if (hasFlag(FLAG_USE_HTTP2) or hasFlag(FLAG_USE_HTTP3)) {
        Curl_setopt_set_i64(data, FIELD_WEIGHT, 0);
    }
    Curl_setopt_set_bit(data, BIT_QUICK_EXIT, false);
    if (!hasFlag(FLAG_DISABLE_WEBSOCKETS)) {
        Curl_setopt_set_bit(data, BIT_WS_RAW_MODE, false);
        Curl_setopt_set_bit(data, BIT_WS_NO_AUTO_PONG, false);
    }
}

fn easy_meta_freeentry(p: ?*anyopaque) callconv(.c) void {
    _ = p;
}

pub export fn Curl_open(curl: *?*Curl_easy) callconv(.c) CURLcode {
    const raw = mem.calloc(1, Curl_zig_url_easy_sizeof()) orelse {
        if (hasFlag(FLAG_DEBUGBUILD)) {
            _ = curl_mfprintf(Curl_setopt_default_stderr(), "Error: calloc of Curl_easy failed\n");
        }
        return CURLE_OUT_OF_MEMORY;
    };
    const data: *Curl_easy = @ptrCast(raw);

    Curl_zig_url_data_set_i64(data, DATA_I64_MAGIC, CURLEASY_MAGIC_NUMBER);
    Curl_zig_url_data_set_i64(data, DATA_I64_LAST_CONN_ID, -1);
    Curl_zig_url_data_set_i64(data, DATA_I64_LAST_CPID, std.math.maxInt(u32));
    Curl_zig_url_data_set_i64(data, DATA_I64_ID, -1);
    Curl_zig_url_data_set_i64(data, DATA_I64_MID, std.math.maxInt(u32));
    Curl_zig_url_data_set_i64(data, DATA_I64_MASTER_MID, std.math.maxInt(u32));
    Curl_zig_url_data_set_bit(data, DATA_BIT_PROGRESS_HIDE, true);

    if (Curl_zig_url_data_get_ptr(data, DATA_PTR_REF_META_HASH)) |mh| {
        Curl_hash_init(@ptrCast(@alignCast(mh)), 23, collections.CURL_HASH_TYPE_BYTES, easy_meta_freeentry);
    }
    Curl_u8_strset_init(Curl_easy_strset_ptr(data));
    if (Curl_zig_url_data_get_ptr(data, DATA_PTR_REF_STATE_HEADERB)) |hb| {
        containers.curlx_dyn_init(@ptrCast(@alignCast(hb)), CURL_MAX_HTTP_HEADER);
    }
    if (Curl_setopt_get_ptr_ref(data, PTR_REF_STATE_URL)) |url_br| {
        Curl_bufref_init(url_br);
    }
    if (Curl_setopt_get_ptr_ref(data, PTR_REF_STATE_REFERER)) |ref_br| {
        Curl_bufref_init(ref_br);
    }
    if (Curl_zig_url_data_get_ptr(data, DATA_PTR_REF_REQ)) |req| {
        Curl_req_init(req);
    }
    _ = Curl_initinfo(data);
    if (!hasFlag(FLAG_DISABLE_HTTP)) {
        if (Curl_zig_url_data_get_ptr(data, DATA_PTR_REF_STATE_HTTPHDRS)) |hdrs| {
            containers.Curl_llist_init(@ptrCast(@alignCast(hdrs)), null);
        }
    }
    if (Curl_zig_url_data_get_ptr(data, DATA_PTR_REF_STATE_NETRC)) |nr| {
        netrc_addr_idn.Curl_netrc_init(@ptrCast(@alignCast(nr)));
    }
    Curl_init_userdefined(data);

    curl.* = data;
    return CURLE_OK;
}

pub export fn Curl_conn_free(data: ?*Curl_easy, conn: *connectdata) callconv(.c) void {
    if (connScheme(conn)) |scheme| {
        if (schemeRun(scheme)) |run| {
            if (run.disconnect) |disconnect_fn| {
                if (!Curl_zig_url_conn_get_bit(conn, CONN_BIT_SHUTDOWN_HANDLER)) {
                    const RawDisconnectFn = *const fn (?*Curl_easy, *connectdata, bool) callconv(.c) CURLcode;
                    const raw_fn: RawDisconnectFn = @ptrCast(disconnect_fn);
                    _ = raw_fn(data, conn, true);
                }
            }
        }
    }

    var i: i8 = 0;
    while (i < 2) : (i += 1) {
        Curl_conn_cf_discard_all(data, conn, i);
    }

    if (!hasFlag(FLAG_DISABLE_PROXY)) {
        if (connHttpProxy(conn)) |hp| {
            altsvc_hsts_peer.Curl_peer_unlink(&hp.peer);
            http1_options.Curl_creds_unlink(&hp.creds);
        }
        if (connSocksProxy(conn)) |sp| {
            altsvc_hsts_peer.Curl_peer_unlink(&sp.peer);
            http1_options.Curl_creds_unlink(&sp.creds);
        }
    }

    if (Curl_zig_url_conn_get_ptr(conn, CONN_PTR_REF_CREDS)) |cp| {
        http1_options.Curl_creds_unlink(@ptrCast(@alignCast(cp)));
    }
    if (Curl_zig_url_conn_get_ptr(conn, CONN_PTR_REF_CREDS_ORIGIN)) |cop| {
        altsvc_hsts_peer.Curl_peer_unlink(@ptrCast(@alignCast(cop)));
    }

    inline for (.{ CONN_PTR_OPTIONS, CONN_PTR_INTERFACE_OPTS }) |pid| {
        if (Curl_zig_url_conn_get_ptr(conn, pid)) |p| {
            mem.free(p);
            Curl_zig_url_conn_set_ptr(conn, pid, null);
        }
    }

    const conn_ssl: *SslFilterConfig = @ptrCast(@alignCast(Curl_zig_url_conn_get_ptr(conn, CONN_PTR_REF_SSL_CONFIG).?));
    const conn_proxy_ssl: ?*SslFilterConfig = if (!hasFlag(FLAG_DISABLE_PROXY))
        @ptrCast(@alignCast(Curl_zig_url_conn_get_ptr(conn, CONN_PTR_REF_PROXY_SSL_CONFIG)))
    else
        null;
    vtls_scache_asn1.Curl_ssl_conn_config_cleanup_zig(conn_ssl, conn_proxy_ssl);

    if (Curl_zig_url_conn_get_ptr(conn, CONN_PTR_DESTINATION)) |dest| {
        mem.free(dest);
        Curl_zig_url_conn_set_ptr(conn, CONN_PTR_DESTINATION, null);
    }
    if (Curl_zig_url_conn_get_ptr(conn, CONN_PTR_REF_META_HASH)) |mh| {
        Curl_hash_destroy(@ptrCast(@alignCast(mh)));
    }

    inline for (.{
        CONN_PTR_REF_ORIGIN,
        CONN_PTR_REF_VIA_PEER,
        CONN_PTR_REF_ORIGIN2,
        CONN_PTR_REF_VIA_PEER2,
    }) |pid| {
        if (Curl_zig_url_conn_get_ptr(conn, pid)) |pp| {
            altsvc_hsts_peer.Curl_peer_unlink(@ptrCast(@alignCast(pp)));
        }
    }

    const conn_size = Curl_zig_url_conn_sizeof();
    mem.secureZero(@ptrCast(conn), conn_size);
    mem.freeSized(@ptrCast(conn), conn_size);
}

fn xfer_may_multiplex(data: *const Curl_easy, conn: *const connectdata) bool {
    if (!hasFlag(FLAG_DISABLE_HTTP)) {
        const c_mut: *connectdata = @constCast(conn);
        const d_mut: *Curl_easy = @constCast(data);
        if (connScheme(c_mut)) |scheme| {
            if ((scheme.protocol & PROTO_FAMILY_HTTP) != 0 and
                (!Curl_zig_url_conn_get_bit(conn, CONN_BIT_PROTOCONNSTART) or
                    !Curl_zig_url_conn_get_bit(conn, CONN_BIT_CLOSE)))
            {
                const multi: ?*const Curl_multi = @ptrCast(@alignCast(Curl_zig_url_data_get_ptr(d_mut, DATA_PTR_MULTI)));
                const allowed: u8 = @intCast(Curl_zig_url_data_get_i64(data, DATA_I64_HTTP_NEG_ALLOWED));
                if (Curl_multiplex_wanted(multi) and (allowed & (CURL_HTTP_V2x | CURL_HTTP_V3x)) != 0) {
                    return true;
                }
            }
        }
    }
    return false;
}

fn proxy_info_matches(data: *const proxy_info, needle: *const proxy_info) bool {
    if (data.proxytype == needle.proxytype and
        altsvc_hsts_peer.Curl_peer_same_destination(data.peer, needle.peer) and
        http1_options.Curl_creds_same(data.creds, needle.creds))
    {
        return true;
    }
    return false;
}

fn ssh_config_matches(one: *connectdata, two: *connectdata) bool {
    const sshc1 = Curl_conn_meta_get(one, CURL_META_SSH_CONN);
    const sshc2 = Curl_conn_meta_get(two, CURL_META_SSH_CONN);
    if (sshc1 != null and sshc2 != null) {
        var priv1: ?[*:0]const u8 = null;
        var pub1: ?[*:0]const u8 = null;
        var priv2: ?[*:0]const u8 = null;
        var pub2: ?[*:0]const u8 = null;
        Curl_zig_url_ssh_conn_keys(sshc1, &priv1, &pub1);
        Curl_zig_url_ssh_conn_keys(sshc2, &priv2, &pub2);
        return primitives.Curl_safecmp(@constCast(priv1), @constCast(priv2)) and
            primitives.Curl_safecmp(@constCast(pub1), @constCast(pub2));
    }
    return false;
}

fn url_match_connect_config(conn: *connectdata, m: *url_conn_match) bool {
    if (Curl_zig_url_conn_get_bit(conn, CONN_BIT_CONNECT_ONLY) or
        Curl_zig_url_conn_get_bit(conn, CONN_BIT_CLOSE) or
        Curl_zig_url_conn_get_bit(conn, CONN_BIT_NO_REUSE))
    {
        return false;
    }

    const set_ipver = Curl_setopt_get_i64(m.data, FIELD_IPVER);
    if (set_ipver != CURL_IPRESOLVE_WHATEVER and
        set_ipver != Curl_zig_url_conn_get_i64(conn, CONN_I64_IP_VERSION))
    {
        return false;
    }

    const needle_localport = Curl_zig_url_conn_get_i64(m.needle, CONN_I64_LOCALPORT);
    const conn_localport = Curl_zig_url_conn_get_i64(conn, CONN_I64_LOCALPORT);
    const needle_localportrange = Curl_zig_url_conn_get_i64(m.needle, CONN_I64_LOCALPORTRANGE);
    const conn_localportrange = Curl_zig_url_conn_get_i64(conn, CONN_I64_LOCALPORTRANGE);

    if (needle_localport != 0 and
        (conn_localport != needle_localport or conn_localportrange != needle_localportrange))
    {
        return false;
    }

    const needle_if: ?[*:0]const u8 = @ptrCast(Curl_zig_url_conn_get_ptr(m.needle, CONN_PTR_INTERFACE_OPTS));
    const conn_if: ?[*:0]const u8 = @ptrCast(Curl_zig_url_conn_get_ptr(conn, CONN_PTR_INTERFACE_OPTS));

    if (needle_if != conn_if and
        (needle_if == null or conn_if == null or std.mem.orderZ(u8, conn_if.?, needle_if.?) != .eq))
    {
        return false;
    }

    if ((needle_if != null or needle_localport != 0) and
        (conn_localport != needle_localport or
            conn_localportrange != needle_localportrange or
            (needle_if != null and (conn_if == null or std.mem.orderZ(u8, conn_if.?, needle_if.?) != .eq))))
    {
        return false;
    }

    if ((connViaPeer(m.needle) == null) != (connViaPeer(conn) == null)) {
        return false;
    }

    return true;
}

fn url_match_fully_connected(conn: *connectdata, m: *url_conn_match) bool {
    if (!Curl_conn_is_connected(conn, FIRSTSOCKET) or
        Curl_zig_url_conn_get_bit(conn, CONN_BIT_UPGRADE_IN_PROGRESS))
    {
        if (m.may_multiplex) {
            m.seen_pending_conn = true;
            infof(m.data, "Connection #%lld is not open enough, cannot reuse", .{
                @as(c_longlong, Curl_zig_url_conn_get_i64(conn, CONN_I64_CONNECTION_ID)),
            });
        }
        return false;
    }
    return true;
}

fn url_match_multi(conn: *connectdata, m: *url_conn_match) bool {
    if (connInUse(conn)) {
        const attached_multi = Curl_zig_url_conn_get_ptr(conn, CONN_PTR_ATTACHED_MULTI);
        const data_multi = Curl_zig_url_data_get_ptr(m.data, DATA_PTR_MULTI);
        if (attached_multi != data_multi) return false;
    }
    return true;
}

fn url_match_multiplex_needs(conn: *connectdata, m: *url_conn_match) bool {
    if (connInUse(conn)) {
        if (!Curl_zig_url_conn_get_bit(conn, CONN_BIT_MULTIPLEX)) {
            m.seen_single_use_conn = true;
            return false;
        }
        m.seen_multiplex_conn = true;
        if (!m.may_multiplex or !url_match_multi(conn, m)) {
            return false;
        }
    }
    return true;
}

fn url_match_multiplex_limits(conn: *connectdata, m: *url_conn_match) bool {
    if (connInUse(conn) and m.may_multiplex) {
        const attached_xfers: u32 = @intCast(Curl_zig_url_conn_get_i64(conn, CONN_I64_ATTACHED_XFERS));
        const multi: ?*const Curl_multi = @ptrCast(@alignCast(Curl_zig_url_data_get_ptr(m.data, DATA_PTR_MULTI)));
        const conn_id: c_longlong = Curl_zig_url_conn_get_i64(conn, CONN_I64_CONNECTION_ID);
        if (attached_xfers >= Curl_multi_max_concurrent_streams(multi)) {
            infof(m.data, "connection #%lld reached MAX_CONCURRENT_STREAMS(%u), skip", .{
                conn_id,
                attached_xfers,
            });
            return false;
        }
        if (attached_xfers >= Curl_conn_get_max_concurrent(m.data, conn, FIRSTSOCKET)) {
            infof(m.data, "connection #%lldreached MAX_CONCURRENT_STREAMS(%u), skip", .{
                conn_id,
                attached_xfers,
            });
            return false;
        }
        infof(m.data, "Multiplexed connection found", .{});
    }
    return true;
}

fn connSslConfigMatch(m: *url_conn_match, cfg: *SslFilterConfig, conn: *connectdata, proxy: bool) bool {
    _ = m;
    const cand_ssl: *SslFilterConfig = @ptrCast(@alignCast(Curl_zig_url_conn_get_ptr(conn, CONN_PTR_REF_SSL_CONFIG).?));
    const cand_proxy_ssl: ?*SslFilterConfig = if (!hasFlag(FLAG_DISABLE_PROXY))
        @ptrCast(@alignCast(Curl_zig_url_conn_get_ptr(conn, CONN_PTR_REF_PROXY_SSL_CONFIG)))
    else
        null;
    return vtls_scache_asn1.Curl_ssl_conn_config_match_zig(cfg, cand_ssl, cand_proxy_ssl, proxy);
}

fn url_match_ssl_use(conn: *connectdata, m: *url_conn_match) bool {
    const needle_scheme = connScheme(m.needle).?;
    if ((needle_scheme.flags & PROTOPT_SSL) != 0) {
        if (!Curl_conn_is_ssl(conn, FIRSTSOCKET)) return false;
    } else if (Curl_conn_is_ssl(conn, FIRSTSOCKET)) {
        const c_scheme = connScheme(conn) orelse return false;
        if ((needle_scheme.flags & PROTOPT_SSL_REUSE) == 0 or
            get_protocol_family(c_scheme) != needle_scheme.protocol)
        {
            return false;
        }
        if (!connSslConfigMatch(m, &m.ssl_config, conn, false)) {
            return false;
        }
    } else if (m.require_tls) {
        return false;
    }
    return true;
}

fn url_match_proxy_use(conn: *connectdata, m: *url_conn_match) bool {
    if (hasFlag(FLAG_DISABLE_PROXY)) return true;

    if (Curl_zig_url_conn_get_bit(m.needle, CONN_BIT_ORIGIN_IS_PROXY) !=
        Curl_zig_url_conn_get_bit(conn, CONN_BIT_ORIGIN_IS_PROXY))
    {
        return false;
    }

    const needle_socks = connSocksProxy(m.needle).?;
    const conn_socks = connSocksProxy(conn).?;
    if (!proxy_info_matches(needle_socks, conn_socks)) return false;

    const needle_http = connHttpProxy(m.needle).?;
    const conn_http = connHttpProxy(conn).?;
    if (!proxy_info_matches(needle_http, conn_http)) return false;

    if (Curl_setopt_get_bit(m.data, BIT_SOCKS5_AUTH_ONLY) and
        !Curl_zig_url_conn_get_bit(conn, CONN_BIT_SOCKS5_AUTHENTICATED) and
        (conn_socks.proxytype == CURLPROXY_SOCKS5 or conn_socks.proxytype == CURLPROXY_SOCKS5_HOSTNAME))
    {
        debugInfof(m.data, "Connection #%lld was not SOCKS5 authenticated, cannot reuse", .{
            @as(c_longlong, Curl_zig_url_conn_get_i64(conn, CONN_I64_CONNECTION_ID)),
        });
        return false;
    }

    if (needle_http.proxytype == CURLPROXY_HTTPS or needle_http.proxytype == CURLPROXY_HTTPS2) {
        if (!connSslConfigMatch(m, &m.proxy_ssl_config, conn, true)) {
            debugInfof(m.data, "Connection #%lld has different SSL proxy parameters, cannot reuse", .{
                @as(c_longlong, Curl_zig_url_conn_get_i64(conn, CONN_I64_CONNECTION_ID)),
            });
            return false;
        }
    }
    return true;
}

fn url_match_http_multiplex(conn: *connectdata, m: *url_conn_match, pwait_pipe: *bool) bool {
    if (hasFlag(FLAG_DISABLE_HTTP)) return true;

    const allowed: u8 = @intCast(Curl_zig_url_data_get_i64(m.data, DATA_I64_HTTP_NEG_ALLOWED));
    const needle_scheme = connScheme(m.needle).?;
    if (m.may_multiplex and
        (allowed & (CURL_HTTP_V2x | CURL_HTTP_V3x)) != 0 and
        (needle_scheme.protocol & CURLPROTO_HTTP) != 0 and
        Curl_zig_url_conn_get_i64(conn, CONN_I64_HTTPVERSION_SEEN) == 0)
    {
        if (Curl_setopt_get_bit(m.data, BIT_PIPEWAIT)) {
            infof(m.data, "Server upgrade does not support multiplex yet, wait", .{});
            m.found = null;
            pwait_pipe.* = true;
            return true;
        }
        infof(m.data, "Server upgrade cannot be used", .{});
        return false;
    }
    return true;
}

fn url_match_http_version(conn: *connectdata, m: *url_conn_match) bool {
    if (hasFlag(FLAG_DISABLE_HTTP)) return true;

    const needle_scheme = connScheme(m.needle).?;
    if ((needle_scheme.protocol & PROTO_FAMILY_HTTP) != 0) {
        const allowed: u8 = @intCast(Curl_zig_url_data_get_i64(m.data, DATA_I64_HTTP_NEG_ALLOWED));
        const conn_id: c_longlong = Curl_zig_url_conn_get_i64(conn, CONN_I64_CONNECTION_ID);
        switch (Curl_conn_http_version(m.data, conn)) {
            30 => {
                if ((allowed & CURL_HTTP_V3x) == 0) {
                    debugInfof(m.data, "not reusing conn #%lld, we do not want h3", .{conn_id});
                    return false;
                }
            },
            20 => {
                if ((allowed & CURL_HTTP_V2x) == 0) {
                    debugInfof(m.data, "not reusing conn #%lld, we do not want h2", .{conn_id});
                    return false;
                }
            },
            else => {
                if ((allowed & CURL_HTTP_V1x) == 0) {
                    debugInfof(m.data, "not reusing conn #%lld, we do not want h1", .{conn_id});
                    return false;
                }
            },
        }
    }
    return true;
}

fn url_match_proto_config(conn: *connectdata, m: *url_conn_match) bool {
    if (!url_match_http_version(conn, m)) return false;

    const needle_scheme = connScheme(m.needle).?;
    const fam = get_protocol_family(needle_scheme);
    if (hasFlag(FLAG_USE_SSH) and (fam & PROTO_FAMILY_SSH) != 0) {
        if (!ssh_config_matches(m.needle, conn)) return false;
    } else if (!hasFlag(FLAG_DISABLE_FTP) and (fam & PROTO_FAMILY_FTP) != 0) {
        if (!Curl_ftp_conns_match(m.needle, conn)) return false;
    }
    return true;
}

fn url_match_auth(conn: *connectdata, m: *url_conn_match) bool {
    const n_creds = connCreds(m.needle);
    const c_creds = connCreds(conn);
    if (!http1_options.Curl_creds_same(n_creds, c_creds)) {
        if (n_creds != null) return false;
        if (!http1_options.Curl_creds_same(dataCreds(m.data), c_creds)) return false;
    }
    if (hasFlag(FLAG_HAVE_GSSAPI_OR_SSPI)) {
        if (Curl_zig_url_conn_get_i64(m.needle, CONN_I64_GSSAPI_DELEGATION) !=
            Curl_zig_url_conn_get_i64(conn, CONN_I64_GSSAPI_DELEGATION))
        {
            return false;
        }
    }
    return true;
}

fn url_match_destination(conn: *connectdata, m: *url_conn_match) bool {
    if (!altsvc_hsts_peer.Curl_peer_same_destination(connViaPeer(m.needle), connViaPeer(conn))) {
        return false;
    }

    const n_origin = connOrigin(m.needle) orelse return false;
    const c_origin = connOrigin(conn) orelse return false;
    const n_scheme = connScheme(m.needle) orelse return false;

    if (n_origin.scheme != c_origin.scheme and
        get_protocol_family(@ptrCast(@alignCast(c_origin.scheme.?))) != n_scheme.protocol)
    {
        return false;
    }

    return altsvc_hsts_peer.Curl_peer_same_destination(n_origin, c_origin);
}

fn url_match_ssl_config(conn: *connectdata, m: *url_conn_match) bool {
    const needle_scheme = connScheme(m.needle).?;
    if (((needle_scheme.flags & PROTOPT_SSL) != 0 or m.may_tls) and
        !connSslConfigMatch(m, &m.ssl_config, conn, false))
    {
        debugInfof(m.data, "Connection #%lld has different SSL parameters, cannot reuse", .{
            @as(c_longlong, Curl_zig_url_conn_get_i64(conn, CONN_I64_CONNECTION_ID)),
        });
        return false;
    }
    return true;
}

fn url_match_auth_ntlm(conn: *connectdata, m: *url_conn_match) bool {
    if (!hasFlag(FLAG_USE_NTLM)) return true;

    const http_ntlm_state = Curl_zig_url_conn_get_i64(conn, CONN_I64_HTTP_NTLM_STATE);
    if (http_ntlm_state != NTLMSTATE_NONE) {
        if (!m.want_ntlm_http or
            !http1_options.Curl_creds_same(connCreds(conn), dataCreds(m.data)) or
            !altsvc_hsts_peer.Curl_peer_equal(connCredsOrigin(conn), dataOrigin(m.data)))
        {
            return false;
        }
    } else if (m.want_ntlm_http) {
        if (connCredsOrigin(conn) != null and
            (!http1_options.Curl_creds_same(connCreds(conn), dataCreds(m.data)) or
                !altsvc_hsts_peer.Curl_peer_equal(connCredsOrigin(conn), dataOrigin(m.data))))
        {
            return false;
        }
    }

    if (!hasFlag(FLAG_DISABLE_PROXY)) {
        const proxy_ntlm_state = Curl_zig_url_conn_get_i64(conn, CONN_I64_PROXY_NTLM_STATE);
        const n_hp = connHttpProxy(m.needle).?;
        const c_hp = connHttpProxy(conn).?;
        if (proxy_ntlm_state != NTLMSTATE_NONE) {
            if (!m.want_proxy_ntlm_http or !http1_options.Curl_creds_same(n_hp.creds, c_hp.creds)) {
                return false;
            }
        } else if (m.want_proxy_ntlm_http) {
            if (c_hp.creds != null and !http1_options.Curl_creds_same(n_hp.creds, c_hp.creds)) {
                return false;
            }
        }
    }
    return true;
}

fn url_match_auth_nego(conn: *connectdata, m: *url_conn_match) bool {
    if (!hasFlag(FLAG_USE_SPNEGO)) return true;

    const http_nego_state = Curl_zig_url_conn_get_i64(conn, CONN_I64_HTTP_NEGOTIATE_STATE);
    if (http_nego_state != CURL_NEGO_AUTH_NONE) {
        if (!m.want_nego_http or
            !http1_options.Curl_creds_same(connCreds(conn), dataCreds(m.data)) or
            !altsvc_hsts_peer.Curl_peer_equal(connCredsOrigin(conn), dataOrigin(m.data)))
        {
            return false;
        }
    } else if (m.want_nego_http) {
        if (connCredsOrigin(conn) != null and
            (!http1_options.Curl_creds_same(connCreds(conn), dataCreds(m.data)) or
                !altsvc_hsts_peer.Curl_peer_equal(connCredsOrigin(conn), dataOrigin(m.data))))
        {
            return false;
        }
    }

    if (!hasFlag(FLAG_DISABLE_PROXY)) {
        const proxy_nego_state = Curl_zig_url_conn_get_i64(conn, CONN_I64_PROXY_NEGOTIATE_STATE);
        const n_hp = connHttpProxy(m.needle).?;
        const c_hp = connHttpProxy(conn).?;
        if (proxy_nego_state != CURL_NEGO_AUTH_NONE) {
            if (!m.want_proxy_nego_http or !http1_options.Curl_creds_same(n_hp.creds, c_hp.creds)) {
                return false;
            }
        } else if (m.want_proxy_nego_http) {
            if (c_hp.creds != null and !http1_options.Curl_creds_same(n_hp.creds, c_hp.creds)) {
                return false;
            }
        }
    }
    return true;
}

fn url_match_conn(conn: *connectdata, userdata: ?*anyopaque) callconv(.c) cpool_match_result {
    const m: *url_conn_match = @ptrCast(@alignCast(userdata.?));
    var wait_pipe = false;

    if (!url_match_connect_config(conn, m)) return CPOOL_MATCH_CONT;
    if (!url_match_destination(conn, m)) return CPOOL_MATCH_CONT;
    if (!url_match_fully_connected(conn, m)) return CPOOL_MATCH_CONT;
    if (!url_match_multiplex_needs(conn, m)) return CPOOL_MATCH_CONT;
    if (!url_match_ssl_use(conn, m)) return CPOOL_MATCH_CONT;
    if (!url_match_proxy_use(conn, m)) return CPOOL_MATCH_CONT;
    if (!url_match_ssl_config(conn, m)) return CPOOL_MATCH_CONT;
    if (!url_match_http_multiplex(conn, m, &wait_pipe)) return CPOOL_MATCH_CONT;
    if (!url_match_auth(conn, m)) return CPOOL_MATCH_CONT;
    if (!url_match_proto_config(conn, m)) return CPOOL_MATCH_CONT;
    if (!url_match_auth_ntlm(conn, m)) return CPOOL_MATCH_CONT;
    if (!url_match_auth_nego(conn, m)) return CPOOL_MATCH_CONT;
    if (!url_match_multiplex_limits(conn, m)) return CPOOL_MATCH_CONT;

    if (wait_pipe) {
        m.wait_pipe = true;
        return CPOOL_MATCH_FOUND;
    }

    const conn_max_age_ms = Curl_setopt_get_i64(m.data, FIELD_CONN_MAX_AGE_MS);
    if (conn_max_age_ms > 0) {
        const age_ms = Curl_cpool_conn_age_ms(m.data, conn, &m.now);
        if (age_ms > conn_max_age_ms) {
            return CPOOL_MATCH_TOO_OLD;
        }
    }

    if (!connInUse(conn) and !Curl_cpool_conn_seems_healthy(conn, m.data, &m.now)) {
        infof(m.data, "Connection %lld seems to be dead, terminating", .{
            @as(c_longlong, Curl_zig_url_conn_get_i64(conn, CONN_I64_CONNECTION_ID)),
        });
        return CPOOL_MATCH_CLOSE;
    }

    m.found = conn;
    return CPOOL_MATCH_FOUND;
}

fn url_match_result(userdata: ?*anyopaque) callconv(.c) bool {
    const match: *url_conn_match = @ptrCast(@alignCast(userdata.?));
    if (match.found) |found| {
        Curl_attach_connection(match.data, found, true);
        return true;
    } else if (match.seen_single_use_conn and !match.seen_multiplex_conn) {
        match.wait_pipe = false;
    } else if (match.seen_pending_conn and Curl_setopt_get_bit(match.data, BIT_PIPEWAIT)) {
        infof(match.data, "Found pending candidate for reuse and CURLOPT_PIPEWAIT is set", .{});
        match.wait_pipe = true;
    }
    return false;
}

fn url_attach_existing(
    data: *Curl_easy,
    needle: *connectdata,
    m: *url_conn_match,
    pnow: *const Curltime,
) bool {
    const dest: ?[*:0]const u8 = @ptrCast(Curl_zig_url_conn_get_ptr(needle, CONN_PTR_DESTINATION));
    return Curl_cpool_find(data, dest, true, pnow, url_match_conn, url_match_result, m);
}

fn allocate_conn(data: *Curl_easy) ?*connectdata {
    const raw = mem.calloc(1, Curl_zig_url_conn_sizeof()) orelse return null;
    const conn: *connectdata = @ptrCast(raw);

    Curl_zig_url_conn_set_i64(conn, CONN_I64_SOCK_FIRST, -1);
    Curl_zig_url_conn_set_i64(conn, CONN_I64_SOCK_SECOND, -1);
    Curl_zig_url_conn_set_i64(conn, CONN_I64_RECV_IDX, 0);
    Curl_zig_url_conn_set_i64(conn, CONN_I64_SEND_IDX, 0);
    Curl_zig_url_conn_set_i64(conn, CONN_I64_CONNECTION_ID, -1);
    Curl_zig_url_conn_set_i64(conn, CONN_I64_CPID, std.math.maxInt(u32));
    Curl_zig_url_conn_set_i64(conn, CONN_I64_ATTACHED_XFERS, 0);
    Curl_zig_url_conn_set_i64(conn, CONN_I64_SHUTDOWN_START_FIRST, -1);
    Curl_zig_url_conn_set_i64(conn, CONN_I64_SHUTDOWN_START_SECOND, -1);

    if (!hasFlag(FLAG_DISABLE_FTP)) {
        Curl_zig_url_conn_set_bit(conn, CONN_BIT_FTP_USE_EPSV, Curl_setopt_get_bit(data, BIT_FTP_USE_EPSV));
        Curl_zig_url_conn_set_bit(conn, CONN_BIT_FTP_USE_EPRT, Curl_setopt_get_bit(data, BIT_FTP_USE_EPRT));
    }
    Curl_zig_url_conn_set_i64(conn, CONN_I64_IP_VERSION, Curl_setopt_get_i64(data, FIELD_IPVER));
    Curl_zig_url_conn_set_bit(conn, CONN_BIT_CONNECT_ONLY, Curl_setopt_get_bit(data, BIT_CONNECT_ONLY));
    Curl_zig_url_conn_set_i64(conn, CONN_I64_TRANSPORT_WANTED, TRNSPRT_TCP);

    if (easyStr(data, STRING_INTERFACE_OPT)) |if_opt| {
        const dup = mem.strdup(if_opt) orelse {
            const conn_size = Curl_zig_url_conn_sizeof();
            mem.secureZero(@ptrCast(conn), conn_size);
            mem.freeSized(@ptrCast(conn), conn_size);
            return null;
        };
        Curl_zig_url_conn_set_ptr(conn, CONN_PTR_INTERFACE_OPTS, dup);
    }

    if (!hasFlag(FLAG_DISABLE_BINDLOCAL)) {
        Curl_zig_url_conn_set_i64(conn, CONN_I64_LOCALPORTRANGE, Curl_setopt_get_i64(data, FIELD_LOCALPORTRANGE));
        Curl_zig_url_conn_set_i64(conn, CONN_I64_LOCALPORT, Curl_setopt_get_i64(data, FIELD_LOCALPORT));
    }

    Curl_zig_url_conn_set_ptr(conn, CONN_PTR_FCLOSESOCKET, Curl_setopt_get_ptr(data, PTR_SET_FCLOSESOCKET));
    Curl_zig_url_conn_set_ptr(conn, CONN_PTR_CLOSESOCKET_CLIENT, Curl_setopt_get_ptr(data, PTR_SET_CLOSESOCKET_CLIENT));

    if (hasFlag(FLAG_HAVE_GSSAPI_OR_SSPI)) {
        Curl_zig_url_conn_set_i64(conn, CONN_I64_GSSAPI_DELEGATION, Curl_setopt_get_i64(data, FIELD_GSSAPI_DELEGATION));
    }

    return conn;
}

fn url_set_conn_scheme(data: *Curl_easy, conn: *connectdata) CURLcode {
    const origin = connOrigin(conn) orelse return CURLE_UNSUPPORTED_PROTOCOL;
    const scheme: *const Curl_scheme = @ptrCast(@alignCast(origin.scheme orelse return CURLE_UNSUPPORTED_PROTOCOL));
    const allowed_protocols = Curl_setopt_get_i64(data, FIELD_ALLOWED_PROTOCOLS);
    const redir_protocols = Curl_setopt_get_i64(data, FIELD_REDIR_PROTOCOLS);
    const is_follow = Curl_zig_url_data_get_bit(data, DATA_BIT_THIS_IS_A_FOLLOW);

    if (scheme.run != null and
        (allowed_protocols & scheme.protocol) != 0 and
        (!is_follow or (redir_protocols & scheme.protocol) != 0))
    {
        Curl_zig_url_conn_set_ptr(conn, CONN_PTR_SCHEME, @constCast(scheme));
        return CURLE_OK;
    }

    if ((scheme.flags & PROTOPT_NO_TRANSFER) != 0) {
        failf(data, "Protocol \"%s\" is not for transfers", .{scheme.name});
    } else {
        const suffix: [*:0]const u8 = if (is_follow) " (in redirect)" else "";
        failf(data, "Protocol \"%s\" is disabled%s", .{ scheme.name, suffix });
    }
    return CURLE_UNSUPPORTED_PROTOCOL;
}

pub export fn Curl_uc_to_curlcode(uc: CURLUcode) callconv(.c) CURLcode {
    return switch (uc) {
        CURLUE_UNSUPPORTED_SCHEME => CURLE_UNSUPPORTED_PROTOCOL,
        CURLUE_OUT_OF_MEMORY => CURLE_OUT_OF_MEMORY,
        CURLUE_USER_NOT_ALLOWED => CURLE_LOGIN_DENIED,
        else => CURLE_URL_MALFORMAT,
    };
}

fn hsts_upgrade(
    data: *Curl_easy,
    uh: *CURLU,
    port_override: u16,
    scope_id: u32,
) CURLcode {
    if (hasFlag(FLAG_DISABLE_HTTP) or hasFlag(FLAG_DISABLE_HSTS)) return CURLE_OK;

    const hsts: ?*altsvc_hsts_peer.Hsts = @ptrCast(@alignCast(Curl_setopt_get_ptr(data, PTR_DATA_HSTS)));
    const origin = dataOrigin(data);
    if (hsts != null and origin != null and
        origin.?.scheme == @as(?*const altsvc_hsts_peer.CurlScheme, @ptrCast(&Curl_scheme_http)) and
        altsvc_hsts_peer.Curl_hsts_applies(hsts, origin.?))
    {
        var url: ?[*:0]u8 = null;
        var uc = curl_url_set(uh, CURLUPART_SCHEME, "https", 0);
        if (uc != CURLUE_OK) return Curl_uc_to_curlcode(uc);

        const url_br = Curl_setopt_get_ptr_ref(data, PTR_REF_STATE_URL).?;
        Curl_bufref_free(url_br);

        uc = curl_url_get(uh, CURLUPART_URL, &url, 0);
        if (uc != CURLUE_OK) return Curl_uc_to_curlcode(uc);

        Curl_bufref_set(url_br, url, 0, &curl_free);

        const p_origin: *?*CurlPeer = @ptrCast(@alignCast(Curl_zig_url_data_get_ptr(data, DATA_PTR_REF_STATE_ORIGIN).?));
        const result = altsvc_hsts_peer.Curl_peer_from_url(
            uh,
            data,
            port_override,
            scope_id,
            Curl_zig_url_data_get_bit(data, DATA_BIT_THIS_IS_A_FOLLOW),
            p_origin,
        );
        if (result != CURLE_OK) return result;
        infof(data, "Switched from HTTP to HTTPS due to HSTS => %s", .{url});
    }
    return CURLE_OK;
}

fn str_has_ctrl(input: ?[*:0]const u8) bool {
    const str = input orelse return false;
    var i: usize = 0;
    while (str[i] != 0) : (i += 1) {
        if (str[i] < 0x20) return true;
    }
    return false;
}

fn url_set_data_creds_netrc(data: *Curl_easy, pcreds: *?*Curl_creds) CURLcode {
    if (hasFlag(FLAG_DISABLE_NETRC)) return CURLE_OK;

    var ncreds_out: ?*Curl_creds = null;
    var result: CURLcode = CURLE_OK;
    const use_netrc = Curl_setopt_get_i64(data, FIELD_USE_NETRC);

    if (use_netrc != 0) {
        var ncreds_in: ?*Curl_creds = null;
        var scan_netrc = true;

        if (pcreds.*) |creds| {
            switch (creds.source) {
                CREDS_OPTION => {
                    scan_netrc = false;
                },
                CREDS_URL => {
                    if (use_netrc == CURL_NETRC_REQUIRED) {
                        ncreds_in = creds;
                    } else if (!credsHasUser(creds) or !credsHasPasswd(creds)) {
                        ncreds_in = creds;
                    } else {
                        scan_netrc = false;
                    }
                },
                else => {},
            }
        }

        if (scan_netrc) {
            const origin = dataOrigin(data).?;
            const store: *netrc_addr_idn.StoreNetrc = @ptrCast(@alignCast(Curl_zig_url_data_get_ptr(data, DATA_PTR_REF_STATE_NETRC).?));
            const netrc_file = easyStr(data, STRING_NETRC_FILE);
            const ret = netrc_addr_idn.Curl_netrc_scan(
                data,
                store,
                origin.hostname,
                credsUser(ncreds_in),
                netrc_file,
                @ptrCast(&ncreds_out),
            );
            if (ret == NETRC_OUT_OF_MEMORY) {
                result = CURLE_OUT_OF_MEMORY;
            } else if (ret != NETRC_OK and (ret == NETRC_NO_MATCH or use_netrc == CURL_NETRC_OPTIONAL)) {
                const fname: [*:0]const u8 = if (netrc_file) |nf| nf else ".netrc";
                infof(data, "Could not find host %s in the %s file; using defaults", .{
                    origin.hostname,
                    fname,
                });
            } else if (ret != NETRC_OK) {
                const m = netrc_addr_idn.Curl_netrc_strerror(ret);
                failf(data, ".netrc error: %s", .{m});
                result = CURLE_READ_ERROR;
            } else if (ncreds_out) |nc| {
                const scheme: *const Curl_scheme = @ptrCast(@alignCast(origin.scheme.?));
                if ((scheme.flags & PROTOPT_USERPWDCTRL) == 0 and
                    (str_has_ctrl(nc.user) or str_has_ctrl(nc.passwd)))
                {
                    failf(data, "control code detected in .netrc credentials", .{});
                    result = CURLE_READ_ERROR;
                } else {
                    if (!hasFlag(FLAG_DISABLE_VERBOSE_STRINGS)) {
                        Curl_trc_multi(data, "netrc: using credentials for %s as %s", origin.hostname, nc.user);
                    }
                    result = http1_options.Curl_creds_merge(
                        nc.user,
                        nc.passwd,
                        pcreds.*,
                        CREDS_NETRC,
                        pcreds,
                    );
                    if (result == CURLE_OK) {
                        const uh: *CURLU = @ptrCast(@alignCast(Curl_zig_url_data_get_ptr(data, DATA_PTR_STATE_UH).?));
                        var uc = curl_url_set(uh, CURLUPART_USER, credsUser(pcreds.*), CURLU_URLENCODE);
                        if (uc == CURLUE_OK) {
                            uc = curl_url_set(uh, CURLUPART_PASSWORD, credsPasswd(pcreds.*), CURLU_URLENCODE);
                        }
                        if (uc != CURLUE_OK) {
                            result = Curl_uc_to_curlcode(uc);
                        }
                    }
                }
            }
        }
    }

    if (result == CURLE_OK and scan_netrc_trace_applicable(use_netrc, pcreds.*)) {
        if (!hasFlag(FLAG_DISABLE_VERBOSE_STRINGS)) {
            http1_options.Curl_creds_trace(data, dataCreds(data), "transfer credentials");
        }
    }

    http1_options.Curl_creds_unlink(&ncreds_out);
    return result;
}

inline fn scan_netrc_trace_applicable(use_netrc: i64, creds_opt: ?*Curl_creds) bool {
    if (use_netrc == 0) return true;
    if (creds_opt) |creds| {
        if (creds.source == CREDS_OPTION) return false;
        if (creds.source == CREDS_URL and use_netrc != CURL_NETRC_REQUIRED and
            credsHasUser(creds) and credsHasPasswd(creds))
        {
            return false;
        }
    }
    return true;
}

fn url_set_data_creds(data: *Curl_easy, uh: *CURLU) CURLcode {
    var newcreds: ?*Curl_creds = null;
    var result: CURLcode = CURLE_OK;

    const u_str = easyStr(data, STRING_USERNAME);
    const p_str = easyStr(data, STRING_PASSWORD);
    const b_str = easyStr(data, STRING_BEARER);
    const a_str = easyStr(data, STRING_SASL_AUTHZID);
    const s_str = easyStr(data, STRING_SERVICE_NAME);

    if ((u_str != null or p_str != null or b_str != null or a_str != null or s_str != null) and
        authAllowedToOrigin(data, dataOrigin(data)))
    {
        result = http1_options.Curl_creds_create(
            u_str,
            p_str,
            b_str,
            a_str,
            s_str,
            CREDS_OPTION,
            &newcreds,
        );
        if (result != CURLE_OK) {
            http1_options.Curl_creds_unlink(&newcreds);
            return result;
        }
        if (newcreds) |nc| {
            const origin = dataOrigin(data).?;
            const scheme: *const Curl_scheme = @ptrCast(@alignCast(origin.scheme.?));
            if ((scheme.flags & PROTOPT_USERPWDCTRL) == 0 and
                (str_has_ctrl(credsUser(nc)) or str_has_ctrl(credsPasswd(nc))))
            {
                failf(data, "control code detected in credentials", .{});
                http1_options.Curl_creds_unlink(&newcreds);
                return CURLE_BAD_FUNCTION_ARGUMENT;
            }
        }
    }

    if (newcreds == null or !credsHasUser(newcreds)) {
        var user: ?[*:0]u8 = null;
        var passwd: ?[*:0]u8 = null;
        var udecoded: ?[*:0]u8 = null;
        var pdecoded: ?[*:0]u8 = null;

        var uc = curl_url_get(uh, CURLUPART_USER, &user, 0);
        if (uc != CURLUE_OK and uc != CURLUE_NO_USER) {
            result = Curl_uc_to_curlcode(uc);
        }
        if (result == CURLE_OK) {
            uc = curl_url_get(uh, CURLUPART_PASSWORD, &passwd, 0);
            if (uc != CURLUE_OK and uc != CURLUE_NO_PASSWORD) {
                result = Curl_uc_to_curlcode(uc);
            }
        }

        const origin = dataOrigin(data).?;
        const scheme: *const Curl_scheme = @ptrCast(@alignCast(origin.scheme.?));
        const ctrl_mode: c_uint = if ((scheme.flags & PROTOPT_USERPWDCTRL) != 0) REJECT_ZERO else REJECT_CTRL;

        if (result == CURLE_OK and user != null) {
            result = Curl_urldecode(user.?, 0, &udecoded, null, ctrl_mode);
        }
        if (result == CURLE_OK and passwd != null) {
            result = Curl_urldecode(passwd.?, 0, &pdecoded, null, ctrl_mode);
        }
        if (result == CURLE_OK) {
            result = http1_options.Curl_creds_merge(udecoded, pdecoded, newcreds, CREDS_URL, &newcreds);
        }

        if (udecoded) |p| mem.free(p);
        mem.freeSecretZ(pdecoded);
        mem.freeSecretZ(passwd);
        if (user) |p| mem.free(p);

        if (result != CURLE_OK) {
            failf(data, "error extracting credentials from URL", .{});
            http1_options.Curl_creds_unlink(&newcreds);
            return result;
        }
    }

    if (!hasFlag(FLAG_DISABLE_NETRC)) {
        result = url_set_data_creds_netrc(data, &newcreds);
    }

    if (result == CURLE_OK and !http1_options.Curl_creds_equal(dataCreds(data), newcreds)) {
        const p_data_creds: *?*Curl_creds = @ptrCast(@alignCast(Curl_zig_url_data_get_ptr(data, DATA_PTR_REF_STATE_CREDS).?));
        http1_options.Curl_creds_link(p_data_creds, newcreds);
    }
    http1_options.Curl_creds_unlink(&newcreds);
    return result;
}

fn url_set_conn_origin_etc(data: *Curl_easy, conn: *connectdata) CURLcode {
    const p_conn_origin: *?*CurlPeer = @ptrCast(@alignCast(Curl_zig_url_conn_get_ptr(conn, CONN_PTR_REF_ORIGIN).?));
    altsvc_hsts_peer.Curl_peer_link(p_conn_origin, dataOrigin(data));

    const result = url_set_conn_scheme(data, conn);
    if (result != CURLE_OK) return result;

    const up: *urlpieces = @ptrCast(@alignCast(Curl_zig_url_data_get_ptr(data, DATA_PTR_REF_STATE_UP).?));
    if (easyStr(data, STRING_OPTIONS)) |opt_str| {
        const dup = mem.strdup(opt_str) orelse return CURLE_OUT_OF_MEMORY;
        Curl_zig_url_conn_set_ptr(conn, CONN_PTR_OPTIONS, dup);
    } else if (up.options) |up_opt| {
        const dup = mem.strdup(up_opt) orelse return CURLE_OUT_OF_MEMORY;
        Curl_zig_url_conn_set_ptr(conn, CONN_PTR_OPTIONS, dup);
    }

    return CURLE_OK;
}

fn setup_range(data: *Curl_easy) CURLcode {
    const resume_from = Curl_setopt_get_i64(data, FIELD_SET_RESUME_FROM);
    Curl_zig_url_data_set_i64(data, DATA_I64_RESUME_FROM, resume_from);
    const set_range = easyStr(data, STRING_SET_RANGE);

    if (resume_from != 0 or set_range != null) {
        if (Curl_zig_url_data_get_bit(data, DATA_BIT_RANGESTRINGALLOC)) {
            if (Curl_zig_url_data_get_ptr(data, DATA_PTR_STATE_RANGE)) |r| {
                mem.free(r);
            }
        }

        const new_range: ?[*:0]u8 = if (resume_from != 0)
            curl_maprintf("%lld-", @as(c_longlong, resume_from))
        else
            mem.strdup(set_range.?);

        if (new_range == null) {
            Curl_zig_url_data_set_ptr(data, DATA_PTR_STATE_RANGE, null);
            return CURLE_OUT_OF_MEMORY;
        }
        Curl_zig_url_data_set_ptr(data, DATA_PTR_STATE_RANGE, new_range);
        Curl_zig_url_data_set_bit(data, DATA_BIT_RANGESTRINGALLOC, true);
        Curl_zig_url_data_set_bit(data, DATA_BIT_USE_RANGE, true);
    } else {
        Curl_zig_url_data_set_bit(data, DATA_BIT_USE_RANGE, false);
    }

    return CURLE_OK;
}

fn setup_connection_internals(data: *Curl_easy, conn: *connectdata) CURLcode {
    const scheme = connScheme(conn) orelse return CURLE_FAILED_INIT;
    if (schemeRun(scheme)) |run| {
        if (run.setup_connection) |setup_fn| {
            const result = setup_fn(@ptrCast(data), conn);
            if (result != CURLE_OK) return result;
        }
    }

    const peer = Curl_conn_get_destination(conn, FIRSTSOCKET) orelse return CURLE_FAILED_INIT;
    const hostname = peer.hostname;
    const port: c_uint = peer.port;

    const dest: ?[*:0]u8 = if (peer.ipv6())
        if (peer.scopeid != 0)
            curl_maprintf("[%s%%%u]:%u", hostname, @as(c_uint, peer.scopeid), port)
        else
            curl_maprintf("[%s]:%u", hostname, port)
    else
        curl_maprintf("%s:%u", hostname, port);

    const dest_ptr = dest orelse return CURLE_OUT_OF_MEMORY;
    Curl_zig_url_conn_set_ptr(conn, CONN_PTR_DESTINATION, dest_ptr);
    primitives.Curl_strntolower(dest_ptr, dest_ptr, std.mem.len(dest_ptr));

    if (hasFlag(FLAG_USE_IPV6)) {
        const set_scope = Curl_setopt_get_i64(data, FIELD_SCOPE_ID);
        if (set_scope != 0) {
            Curl_zig_url_conn_set_i64(conn, CONN_I64_SCOPE_ID, set_scope);
        } else {
            const first_peer = Curl_conn_get_first_peer(conn, FIRSTSOCKET) orelse return CURLE_FAILED_INIT;
            Curl_zig_url_conn_set_i64(conn, CONN_I64_SCOPE_ID, @intCast(first_peer.scopeid));
        }
    }

    return CURLE_OK;
}

pub export fn Curl_parse_login_details(
    login: [*]const u8,
    len: usize,
    userp: ?*?[*:0]u8,
    passwdp: ?*?[*:0]u8,
    optionsp: ?*?[*:0]u8,
) callconv(.c) CURLcode {
    const psep_idx = std.mem.indexOfScalar(u8, login[0..len], ':');
    const osep_idx = if (optionsp != null) std.mem.indexOfScalar(u8, login[0..len], ';') else null;

    const ulen: usize = if (psep_idx) |pidx|
        if (osep_idx != null and pidx > osep_idx.?) osep_idx.? else pidx
    else if (osep_idx) |oidx|
        oidx
    else
        len;

    const plen: usize = if (psep_idx) |pidx|
        (if (osep_idx != null and osep_idx.? > pidx) osep_idx.? - pidx else len - pidx) - 1
    else
        0;

    const olen: usize = if (osep_idx) |oidx|
        (if (psep_idx != null and psep_idx.? > oidx) psep_idx.? - oidx else len - oidx) - 1
    else
        0;

    const ubuf = curlx_memdup0(login, ulen) orelse return CURLE_OUT_OF_MEMORY;

    var pbuf: ?[*:0]u8 = null;
    if (psep_idx) |pidx| {
        pbuf = curlx_memdup0(login + pidx + 1, plen) orelse {
            mem.free(ubuf);
            return CURLE_OUT_OF_MEMORY;
        };
    }

    if (optionsp) |opt_out| {
        var obuf: ?[*:0]u8 = null;
        if (olen != 0) {
            const oidx = osep_idx.?;
            obuf = curlx_memdup0(login + oidx + 1, olen) orelse {
                mem.free(ubuf);
                mem.freeSecretZ(pbuf);
                return CURLE_OUT_OF_MEMORY;
            };
        }
        opt_out.* = obuf;
    }

    if (userp) |up| up.* = ubuf else mem.free(ubuf);
    if (passwdp) |pp| pp.* = pbuf else mem.freeSecretZ(pbuf);
    return CURLE_OK;
}

fn url_set_conn_login(data: *Curl_easy, conn: *connectdata) CURLcode {
    const scheme = connScheme(conn).?;
    const p_creds_origin: *?*CurlPeer = @ptrCast(@alignCast(Curl_zig_url_conn_get_ptr(conn, CONN_PTR_REF_CREDS_ORIGIN).?));
    const p_creds: *?*Curl_creds = @ptrCast(@alignCast(Curl_zig_url_conn_get_ptr(conn, CONN_PTR_REF_CREDS).?));

    if ((scheme.flags & PROTOPT_NEEDSPWD) != 0 and connCreds(conn) == null) {
        altsvc_hsts_peer.Curl_peer_link(p_creds_origin, dataOrigin(data));
        if (dataCreds(data)) |dcreds| {
            http1_options.Curl_creds_link(p_creds, dcreds);
        } else {
            return http1_options.Curl_creds_create(
                CURL_DEFAULT_USER,
                CURL_DEFAULT_PASSWORD,
                null,
                null,
                null,
                CREDS_NONE,
                p_creds,
            );
        }
    } else if ((scheme.flags & PROTOPT_CREDSPERREQUEST) == 0) {
        altsvc_hsts_peer.Curl_peer_link(p_creds_origin, dataOrigin(data));
        http1_options.Curl_creds_link(p_creds, dataCreds(data));
    }

    return CURLE_OK;
}

fn parse_connect_to_string(
    data: *Curl_easy,
    dest: *const CurlPeer,
    conn_to_line_opt: ?[*:0]const u8,
    pvia_dest: *?*CurlPeer,
) CURLcode {
    pvia_dest.* = null;
    const conn_to_line = conn_to_line_opt orelse return CURLE_OK;
    var ptr: [*:0]const u8 = conn_to_line;
    var host_match = false;
    var port_match = false;

    if (ptr[0] == ':') {
        host_match = true;
        ptr += 1;
    } else {
        const hostname = dest.hostname;
        var hlen = std.mem.len(hostname);
        host_match = primitives.curl_strnequal(ptr, hostname, hlen) != 0;
        const user_hostname: [*:0]const u8 = @ptrCast(&dest.user_hostname);
        if (!host_match and user_hostname != hostname) {
            hlen = std.mem.len(user_hostname);
            host_match = primitives.curl_strnequal(ptr, user_hostname, hlen) != 0;
        }
        host_match = host_match and ptr[hlen] == ':';
        if (host_match) {
            ptr += hlen + 1;
        }
    }

    if (host_match) {
        if (ptr[0] == ':') {
            port_match = true;
            ptr += 1;
        } else {
            const rest = std.mem.span(ptr);
            if (std.mem.indexOfScalar(u8, rest, ':')) |colon_pos| {
                var num_ptr: [*:0]const u8 = ptr;
                var port_to_match: curl_off_t = 0;
                if (curlx_str_number(&num_ptr, &port_to_match, 0xffff) == 0 and
                    @as(u16, @intCast(port_to_match)) == dest.port)
                {
                    port_match = true;
                }
                ptr += colon_pos + 1;
            }
        }
    }

    if (host_match and port_match and ptr[0] != 0) {
        return altsvc_hsts_peer.Curl_peer_from_connect_to(data, dest, ptr, pvia_dest);
    }

    return CURLE_OK;
}

fn url_set_conn_peer(data: *Curl_easy, conn: *connectdata) CURLcode {
    var result: CURLcode = CURLE_OK;
    const origin = connOrigin(conn) orelse return CURLE_FAILED_INIT;
    var via_peer: ?*CurlPeer = null;
    var conn_to_entry: ?*curl_slist = @ptrCast(@alignCast(Curl_setopt_get_ptr(data, PTR_SET_CONNECT_TO)));

    const p_via_peer: *?*CurlPeer = @ptrCast(@alignCast(Curl_zig_url_conn_get_ptr(conn, CONN_PTR_REF_VIA_PEER).?));
    altsvc_hsts_peer.Curl_peer_unlink(p_via_peer);

    while (conn_to_entry != null and via_peer == null) {
        const entry = conn_to_entry.?;
        result = parse_connect_to_string(data, origin, entry.data, &via_peer);
        if (result != CURLE_OK) return result;
        conn_to_entry = entry.next;
    }

    if (!hasFlag(FLAG_DISABLE_ALTSVC)) {
        const asi: ?*Altsvcinfo = @ptrCast(@alignCast(Curl_setopt_get_ptr(data, PTR_DATA_ASI)));
        const scheme = connScheme(conn).?;
        const altsvc_http = hasFlag(FLAG_DEBUGBUILD) and getenv("CURL_ALTSVC_HTTP") != null;
        if (asi != null and via_peer == null and (scheme.protocol == CURLPROTO_HTTPS or altsvc_http)) {
            var srcalpnid: c_uint = ALPN_none;
            var hit = false;
            var as: ?*Altsvc = null;
            var allowed_alpns: c_int = @intCast(ALPN_none);
            var neg_wanted: u8 = @intCast(Curl_zig_url_data_get_i64(data, DATA_I64_HTTP_NEG_WANTED));
            var neg_allowed: u8 = @intCast(Curl_zig_url_data_get_i64(data, DATA_I64_HTTP_NEG_ALLOWED));
            const h2_prior = Curl_zig_url_data_get_bit(data, DATA_BIT_HTTP_NEG_H2_PRIOR_KNOWLEDGE);
            const only_10 = Curl_zig_url_data_get_bit(data, DATA_BIT_HTTP_NEG_ONLY_10);
            var same_dest = false;

            debugInfof(data, "Alt-svc check wanted=%x, allowed=%x", .{
                @as(c_uint, neg_wanted),
                @as(c_uint, neg_allowed),
            });
            if (hasFlag(FLAG_USE_HTTP3) and (neg_allowed & CURL_HTTP_V3x) != 0) {
                allowed_alpns |= @intCast(ALPN_h3);
            }
            if (hasFlag(FLAG_USE_HTTP2) and (neg_allowed & CURL_HTTP_V2x) != 0) {
                allowed_alpns |= @intCast(ALPN_h2);
            }
            if ((neg_allowed & CURL_HTTP_V1x) != 0) {
                allowed_alpns |= @intCast(ALPN_h1);
            }
            allowed_alpns &= @intCast(asi.?.flags);

            debugInfof(data, "check Alt-Svc for host '%s'", .{origin.hostname});
            if (hasFlag(FLAG_USE_HTTP3) and !hit and (neg_wanted & CURL_HTTP_V3x) != 0) {
                srcalpnid = ALPN_h3;
                hit = altsvc_hsts_peer.Curl_altsvc_lookup(asi.?, origin, ALPN_h3, &as, allowed_alpns, &same_dest);
            }
            if (hasFlag(FLAG_USE_HTTP2) and !hit and (neg_wanted & CURL_HTTP_V2x) != 0 and !h2_prior) {
                srcalpnid = ALPN_h2;
                hit = altsvc_hsts_peer.Curl_altsvc_lookup(asi.?, origin, ALPN_h2, &as, allowed_alpns, &same_dest);
            }
            if (!hit and (neg_wanted & CURL_HTTP_V1x) != 0 and !only_10) {
                srcalpnid = ALPN_h1;
                hit = altsvc_hsts_peer.Curl_altsvc_lookup(asi.?, origin, ALPN_h1, &as, allowed_alpns, &same_dest);
            }

            if (hit and same_dest) {
                switch (as.?.dst.alpnid) {
                    ALPN_h1 => {
                        neg_wanted |= CURL_HTTP_V1x;
                        Curl_zig_url_data_set_i64(data, DATA_I64_HTTP_NEG_WANTED, neg_wanted);
                        Curl_zig_url_data_set_i64(data, DATA_I64_HTTP_NEG_PREFERRED, CURL_HTTP_V1x);
                    },
                    ALPN_h2 => {
                        neg_wanted |= CURL_HTTP_V2x;
                        Curl_zig_url_data_set_i64(data, DATA_I64_HTTP_NEG_WANTED, neg_wanted);
                        Curl_zig_url_data_set_i64(data, DATA_I64_HTTP_NEG_PREFERRED, CURL_HTTP_V2x);
                    },
                    ALPN_h3 => {
                        neg_wanted |= CURL_HTTP_V3x;
                        Curl_zig_url_data_set_i64(data, DATA_I64_HTTP_NEG_WANTED, neg_wanted);
                        Curl_zig_url_data_set_i64(data, DATA_I64_HTTP_NEG_PREFERRED, CURL_HTTP_V3x);
                    },
                    else => {},
                }
            } else if (hit) {
                const as_entry = as.?;
                result = altsvc_hsts_peer.Curl_peer_create(
                    data,
                    origin.scheme,
                    as_entry.dst.host.?,
                    as_entry.dst.port,
                    &via_peer,
                );
                if (result != CURLE_OK) return result;
                const vp = via_peer.?;
                infof(data, "Alt-svc connecting from [%s]%s:%u to [%s]%s:%u", .{
                    altsvc_hsts_peer.Curl_alpnid2str(srcalpnid),
                    origin.hostname,
                    @as(c_uint, origin.port),
                    altsvc_hsts_peer.Curl_alpnid2str(as_entry.dst.alpnid),
                    vp.hostname,
                    @as(c_uint, vp.port),
                });
                Curl_zig_url_conn_set_bit(conn, CONN_BIT_ALTUSED, true);
                if (srcalpnid != as_entry.dst.alpnid) {
                    switch (as_entry.dst.alpnid) {
                        ALPN_h1 => {
                            neg_wanted = CURL_HTTP_V1x;
                            neg_allowed = CURL_HTTP_V1x;
                            Curl_zig_url_data_set_i64(data, DATA_I64_HTTP_NEG_WANTED, neg_wanted);
                            Curl_zig_url_data_set_i64(data, DATA_I64_HTTP_NEG_ALLOWED, neg_allowed);
                            Curl_zig_url_data_set_bit(data, DATA_BIT_HTTP_NEG_ONLY_10, false);
                        },
                        ALPN_h2 => {
                            neg_wanted = CURL_HTTP_V2x;
                            neg_allowed = CURL_HTTP_V2x;
                            Curl_zig_url_data_set_i64(data, DATA_I64_HTTP_NEG_WANTED, neg_wanted);
                            Curl_zig_url_data_set_i64(data, DATA_I64_HTTP_NEG_ALLOWED, neg_allowed);
                        },
                        ALPN_h3 => {
                            Curl_zig_url_conn_set_i64(conn, CONN_I64_TRANSPORT_WANTED, TRNSPRT_QUIC);
                            neg_wanted = CURL_HTTP_V3x;
                            neg_allowed = CURL_HTTP_V3x;
                            Curl_zig_url_data_set_i64(data, DATA_I64_HTTP_NEG_WANTED, neg_wanted);
                            Curl_zig_url_data_set_i64(data, DATA_I64_HTTP_NEG_ALLOWED, neg_allowed);
                        },
                        else => {},
                    }
                }
            }
        }
    }

    if (via_peer) |vp| {
        Curl_zig_url_conn_set_ptr(conn, CONN_PTR_VIA_PEER, vp);
    }

    return result;
}

fn url_conn_reuse_adjust(data: *Curl_easy, needle: *connectdata) void {
    const conn: *connectdata = @ptrCast(@alignCast(Curl_zig_url_data_get_ptr(data, DATA_PTR_CONN).?));

    if (connCreds(needle)) |ncreds| {
        const p_conn_creds: *?*Curl_creds = @ptrCast(@alignCast(Curl_zig_url_conn_get_ptr(conn, CONN_PTR_REF_CREDS).?));
        http1_options.Curl_creds_link(p_conn_creds, ncreds);
    }

    if (!hasFlag(FLAG_DISABLE_PROXY)) {
        const c_hp = connHttpProxy(conn).?;
        const n_hp = connHttpProxy(needle).?;
        http1_options.Curl_creds_link(&c_hp.creds, n_hp.creds);

        const c_sp = connSocksProxy(conn).?;
        const n_sp = connSocksProxy(needle).?;
        http1_options.Curl_creds_link(&c_sp.creds, n_sp.creds);
    }

    inline for (.{
        .{ CONN_PTR_REF_ORIGIN, CONN_PTR_ORIGIN },
        .{ CONN_PTR_REF_VIA_PEER, CONN_PTR_VIA_PEER },
        .{ CONN_PTR_REF_ORIGIN2, CONN_PTR_ORIGIN2 },
        .{ CONN_PTR_REF_VIA_PEER2, CONN_PTR_VIA_PEER2 },
    }) |pair| {
        const dst_ref: *?*CurlPeer = @ptrCast(@alignCast(Curl_zig_url_conn_get_ptr(conn, pair[0]).?));
        const src_peer: ?*CurlPeer = @ptrCast(@alignCast(Curl_zig_url_conn_get_ptr(needle, pair[1])));
        altsvc_hsts_peer.Curl_peer_link(dst_ref, src_peer);
    }
}

fn conn_meta_freeentry(p: ?*anyopaque) callconv(.c) void {
    _ = p;
}

fn url_create_needle(data: *Curl_easy, pneedle: *?*connectdata) CURLcode {
    var result: CURLcode = CURLE_OK;
    var network_scheme = true;

    const needle = allocate_conn(data) orelse {
        pneedle.* = null;
        return CURLE_OUT_OF_MEMORY;
    };

    if (Curl_zig_url_conn_get_ptr(needle, CONN_PTR_REF_META_HASH)) |mh| {
        Curl_hash_init(@ptrCast(@alignCast(mh)), 23, collections.CURL_HASH_TYPE_BYTES, conn_meta_freeentry);
    }

    result = url_set_conn_origin_etc(data, needle);
    if (result != CURLE_OK) {
        pneedle.* = null;
        Curl_conn_free(data, needle);
        return result;
    }

    const origin = connOrigin(needle).?;
    const origin_scheme: *const Curl_scheme = @ptrCast(@alignCast(origin.scheme.?));
    network_scheme = (origin_scheme.flags & PROTOPT_NONETWORK) == 0;

    if (hasFlag(FLAG_USE_UNIX_SOCKETS)) {
        if (network_scheme) {
            if (easyStr(data, STRING_UNIX_SOCKET_PATH)) |uds_path| {
                const p_via_peer: *?*CurlPeer = @ptrCast(@alignCast(Curl_zig_url_conn_get_ptr(needle, CONN_PTR_REF_VIA_PEER).?));
                result = altsvc_hsts_peer.Curl_peer_uds_create(
                    origin.scheme,
                    uds_path,
                    Curl_setopt_get_bit(data, BIT_ABSTRACT_UNIX_SOCKET),
                    p_via_peer,
                );
                if (result != CURLE_OK) {
                    pneedle.* = null;
                    Curl_conn_free(data, needle);
                    return result;
                }
            }
        }
    }

    if (network_scheme and connViaPeer(needle) == null) {
        result = url_set_conn_peer(data, needle);
        if (result != CURLE_OK) {
            pneedle.* = null;
            Curl_conn_free(data, needle);
            return result;
        }
    }

    if (altsvc_hsts_peer.Curl_peer_equal(connOrigin(needle), connViaPeer(needle))) {
        const p_via_peer: *?*CurlPeer = @ptrCast(@alignCast(Curl_zig_url_conn_get_ptr(needle, CONN_PTR_REF_VIA_PEER).?));
        altsvc_hsts_peer.Curl_peer_unlink(p_via_peer);
    }

    if (!hasFlag(FLAG_DISABLE_PROXY)) {
        const vp = connViaPeer(needle);
        if (network_scheme and (vp == null or !vp.?.unixSocket())) {
            result = Curl_proxy_init_conn(data, needle);
            if (result != CURLE_OK) {
                pneedle.* = null;
                Curl_conn_free(data, needle);
                return result;
            }
        }
    }

    result = url_set_conn_login(data, needle);
    if (result != CURLE_OK) {
        pneedle.* = null;
        Curl_conn_free(data, needle);
        return result;
    }

    result = setup_connection_internals(data, needle);
    if (result != CURLE_OK) {
        pneedle.* = null;
        Curl_conn_free(data, needle);
        return result;
    }

    const scheme = connScheme(needle).?;
    if ((scheme.flags & PROTOPT_ALPN) != 0) {
        if (Curl_setopt_get_bit(data, BIT_SSL_ENABLE_ALPN)) {
            Curl_zig_url_conn_set_bit(needle, CONN_BIT_TLS_ENABLE_ALPN, true);
        }
    }

    if (network_scheme) {
        Curl_zig_url_conn_set_ptr(needle, CONN_PTR_RECV_FIRST, @ptrCast(@constCast(&Curl_cf_recv)));
        Curl_zig_url_conn_set_ptr(needle, CONN_PTR_SEND_FIRST, @ptrCast(@constCast(&Curl_cf_send)));
        Curl_zig_url_conn_set_ptr(needle, CONN_PTR_RECV_SECOND, @ptrCast(@constCast(&Curl_cf_recv)));
        Curl_zig_url_conn_set_ptr(needle, CONN_PTR_SEND_SECOND, @ptrCast(@constCast(&Curl_cf_send)));
        Curl_zig_url_conn_set_bit(needle, CONN_BIT_TCP_FASTOPEN, Curl_setopt_get_bit(data, BIT_TCP_FASTOPEN));
        if (hasFlag(FLAG_USE_UNIX_SOCKETS)) {
            if (Curl_conn_get_first_peer(needle, FIRSTSOCKET)) |fp| {
                if (fp.unixSocket()) {
                    Curl_zig_url_conn_set_i64(needle, CONN_I64_TRANSPORT_WANTED, TRNSPRT_UNIX);
                }
            }
        }
    }

    pneedle.* = needle;
    return CURLE_OK;
}

fn url_set_data_origin_and_creds(data: *Curl_easy) CURLcode {
    var result: CURLcode = CURLE_OK;
    var uc: CURLUcode = CURLUE_OK;
    const set_uh: ?*CURLU = @ptrCast(@alignCast(Curl_setopt_get_ptr(data, PTR_SET_UH)));
    const is_follow = Curl_zig_url_data_get_bit(data, DATA_BIT_THIS_IS_A_FOLLOW);
    const use_set_uh = (set_uh != null and !is_follow);
    const port_override: u16 = if (Curl_zig_url_data_get_bit(data, DATA_BIT_ALLOW_PORT))
        @intCast(Curl_setopt_get_i64(data, FIELD_USE_PORT))
    else
        0;
    var scope_id: u32 = 0;

    const url_br = Curl_setopt_get_ptr_ref(data, PTR_REF_STATE_URL).?;
    const url_ptr = Curl_bufref_ptr(url_br) orelse return CURLE_URL_MALFORMAT;

    up_free(data);

    const uh_opt: ?*CURLU = if (use_set_uh) curl_url_dup(set_uh.?) else curl_url();
    Curl_zig_url_data_set_ptr(data, DATA_PTR_STATE_UH, uh_opt);
    const uh = uh_opt orelse return CURLE_OUT_OF_MEMORY;

    if (!use_set_uh) {
        var prepend_scheme = false;
        const def_proto = easyStr(data, STRING_DEFAULT_PROTOCOL);
        const url_flags: c_uint = CURLU_GUESS_SCHEME |
            CURLU_NON_SUPPORT_SCHEME |
            (if (Curl_setopt_get_bit(data, BIT_DISALLOW_USERNAME_IN_URL)) CURLU_DISALLOW_USER else 0) |
            (if (Curl_setopt_get_bit(data, BIT_PATH_AS_IS)) CURLU_PATH_AS_IS else 0);

        if (def_proto != null and
            primitives.curl_strequal("file", def_proto) != 0 and
            !Curl_is_absolute_url(url_ptr, null, 0, true))
        {
            prepend_scheme = true;
        } else {
            uc = curl_url_set(uh, CURLUPART_URL, url_ptr, url_flags);
            if (uc != CURLUE_OK) {
                failf(data, "URL rejected: %s", .{curl_url_strerror(uc)});
                return Curl_uc_to_curlcode(uc);
            }

            if (def_proto != null) {
                var scheme: ?[*:0]u8 = null;
                uc = curl_url_get(uh, CURLUPART_SCHEME, &scheme, CURLU_NO_GUESS_SCHEME);
                if (uc == CURLUE_NO_SCHEME) {
                    prepend_scheme = true;
                }
                if (scheme) |s| mem.free(s);
                if (uc != CURLUE_OK and uc != CURLUE_NO_SCHEME) {
                    return Curl_uc_to_curlcode(uc);
                }
            }
        }

        if (prepend_scheme) {
            const url = curl_maprintf("%s://%s", def_proto.?, Curl_bufref_ptr(url_br).?) orelse return CURLE_OUT_OF_MEMORY;
            uc = curl_url_set(uh, CURLUPART_URL, url, url_flags);
            mem.free(url);
            if (uc != CURLUE_OK) {
                failf(data, "URL rejected: %s", .{curl_url_strerror(uc)});
                return Curl_uc_to_curlcode(uc);
            }
        }

        var newurl: ?[*:0]u8 = null;
        uc = curl_url_get(uh, CURLUPART_URL, &newurl, CURLU_GET_EMPTY);
        if (uc != CURLUE_OK) {
            return Curl_uc_to_curlcode(uc);
        }
        if (prepend_scheme) {
            infof(data, "Applied default protocol '%s'", .{def_proto.?});
        }
        Curl_bufref_set(url_br, newurl, 0, &curl_free);
    }

    if (hasFlag(FLAG_USE_IPV6)) {
        scope_id = @intCast(Curl_setopt_get_i64(data, FIELD_SCOPE_ID));
    }

    const p_origin: *?*CurlPeer = @ptrCast(@alignCast(Curl_zig_url_data_get_ptr(data, DATA_PTR_REF_STATE_ORIGIN).?));
    result = altsvc_hsts_peer.Curl_peer_from_url(
        uh,
        data,
        port_override,
        scope_id,
        Curl_zig_url_data_get_bit(data, DATA_BIT_THIS_IS_A_FOLLOW),
        p_origin,
    );
    if (result != CURLE_OK) return result;

    result = hsts_upgrade(data, uh, port_override, scope_id);
    if (result != CURLE_OK) return result;

    if (dataInitialOrigin(data) == null) {
        const p_init_origin: *?*CurlPeer = @ptrCast(@alignCast(Curl_zig_url_data_get_ptr(data, DATA_PTR_REF_STATE_INITIAL_ORIGIN).?));
        altsvc_hsts_peer.Curl_peer_link(p_init_origin, dataOrigin(data));
    }

    const up: *urlpieces = @ptrCast(@alignCast(Curl_zig_url_data_get_ptr(data, DATA_PTR_REF_STATE_UP).?));
    uc = curl_url_get(uh, CURLUPART_PATH, &up.path, CURLU_URLENCODE);
    if (uc != CURLUE_OK) return Curl_uc_to_curlcode(uc);

    uc = curl_url_get(uh, CURLUPART_QUERY, &up.query, CURLU_GET_EMPTY);
    if (uc != CURLUE_OK and uc != CURLUE_NO_QUERY) return CURLE_OUT_OF_MEMORY;

    uc = curl_url_get(uh, CURLUPART_OPTIONS, &up.options, CURLU_URLDECODE);
    if (uc != CURLUE_OK and uc != CURLUE_NO_OPTIONS) return Curl_uc_to_curlcode(uc);

    return url_set_data_creds(data, uh);
}

fn url_match_init(data: *Curl_easy, needle: *connectdata, m: *url_conn_match) CURLcode {
    m.* = .{
        .data = data,
        .needle = needle,
        .now = Curl_pgrs_now(data).*,
        .may_multiplex = xfer_may_multiplex(data, needle),
    };

    const needle_scheme = connScheme(needle).?;
    const authhost_want: u32 = @intCast(Curl_zig_url_data_get_i64(data, DATA_I64_AUTHHOST_WANT));
    const authproxy_want: u32 = @intCast(Curl_zig_url_data_get_i64(data, DATA_I64_AUTHPROXY_WANT));

    if (hasFlag(FLAG_USE_NTLM)) {
        m.want_ntlm_http = (authhost_want & CURLAUTH_NTLM) != 0 and
            (needle_scheme.protocol & PROTO_FAMILY_HTTP) != 0 and
            authAllowedToHost(data);
        if (!hasFlag(FLAG_DISABLE_PROXY)) {
            const n_hp = connHttpProxy(needle).?;
            m.want_proxy_ntlm_http = n_hp.creds != null and
                (authproxy_want & CURLAUTH_NTLM) != 0 and
                (needle_scheme.protocol & PROTO_FAMILY_HTTP) != 0;
        }
    }

    if (!hasFlag(FLAG_DISABLE_HTTP) and hasFlag(FLAG_USE_SPNEGO)) {
        m.want_nego_http = (authhost_want & CURLAUTH_NEGOTIATE) != 0 and
            (needle_scheme.protocol & PROTO_FAMILY_HTTP) != 0 and
            authAllowedToHost(data);
        if (!hasFlag(FLAG_DISABLE_PROXY)) {
            const n_hp = connHttpProxy(needle).?;
            m.want_proxy_nego_http = n_hp.creds != null and
                (authproxy_want & CURLAUTH_NEGOTIATE) != 0 and
                (needle_scheme.protocol & PROTO_FAMILY_HTTP) != 0;
        }
    }

    const use_ssl = Curl_setopt_get_i64(data, FIELD_USE_SSL);
    m.require_tls = use_ssl >= CURLUSESSL_CONTROL;
    m.may_tls = use_ssl > CURLUSESSL_NONE;

    const sslc: *SslEasyConfig = @ptrCast(@alignCast(Curl_setopt_get_ptr_ref(data, PTR_REF_SET_SSL).?));
    const proxy_sslc: ?*SslEasyConfig = if (!hasFlag(FLAG_DISABLE_PROXY))
        @ptrCast(@alignCast(Curl_setopt_get_ptr_ref(data, PTR_REF_SET_PROXY_SSL)))
    else
        null;
    const blobs: [*]?*vtls_core.CurlBlob = @ptrCast(@alignCast(Curl_zig_url_data_get_ptr(data, DATA_PTR_SET_BLOBS).?));
    const proxy_ssl_cfg: ?*SslFilterConfig = if (!hasFlag(FLAG_DISABLE_PROXY)) &m.proxy_ssl_config else null;

    return vtls_scache_asn1.Curl_ssl_filter_config_tmp_init_zig(
        data,
        connOrigin(needle),
        dataInitialOrigin(data),
        sslc,
        proxy_sslc,
        @ptrCast(Curl_easy_strset_ptr(data)),
        blobs,
        &m.ssl_config,
        proxy_ssl_cfg,
        Curl_zig_url_default_ca_path(),
        Curl_zig_url_default_ca_bundle(),
        hasFlag(FLAG_FORCE_NATIVE_CA),
        STRING_SSL_EC_CURVES,
        STRING_SSL_SIGNATURE_ALGORITHMS,
    );
}

fn url_match_destroy(m: *url_conn_match) void {
    vtls_scache_asn1.Curl_ssl_config_cleanup(&m.ssl_config);
    if (!hasFlag(FLAG_DISABLE_PROXY)) {
        vtls_scache_asn1.Curl_ssl_config_cleanup(&m.proxy_ssl_config);
    }
}

fn url_find_or_create_conn(data: *Curl_easy, pnow: *const Curltime) CURLcode {
    var needle: ?*connectdata = null;
    var match: url_conn_match = undefined;
    var match_initialized = false;
    var result: CURLcode = CURLE_OK;

    defer {
        if (match_initialized) url_match_destroy(&match);
        if (needle) |n| Curl_conn_free(data, n);
    }

    result = url_create_needle(data, &needle);
    if (result != CURLE_OK) return result;
    const n_conn = needle.?;

    result = url_match_init(data, n_conn, &match);
    if (result != CURLE_OK) return result;
    match_initialized = true;

    const n_scheme = connScheme(n_conn).?;
    if (!hasFlag(FLAG_DISABLE_FILE) and (n_scheme.flags & PROTOPT_NONETWORK) != 0) {
        var done = false;
        Curl_zig_url_data_set_ptr(data, DATA_PTR_INFO_CONN_SCHEME, @ptrCast(@constCast(n_scheme.name)));
        Curl_zig_url_data_set_i64(data, DATA_I64_INFO_CONN_PROTOCOL, n_scheme.protocol & CURLPROTO_MASK);
        const run = schemeRun(n_scheme).?;
        result = run.connect_it.?(@ptrCast(data), &done);
        if (result != CURLE_OK) return result;

        result = Curl_cpool_add(data, n_conn, 0, 0, pnow);
        Curl_attach_connection(data, n_conn, true);
        needle = null;
        if (result == CURLE_OK) {
            result = setup_range(data);
            if (result == CURLE_OK) {
                Curl_xfer_setup_nop(data);
                const d_conn: ?*connectdata = @ptrCast(@alignCast(Curl_zig_url_data_get_ptr(data, DATA_PTR_CONN)));
                result = Curl_init_transfer(data, d_conn);
            }
        }

        if (result != CURLE_OK) {
            const d_conn: *connectdata = @ptrCast(@alignCast(Curl_zig_url_data_get_ptr(data, DATA_PTR_CONN).?));
            const d_scheme = connScheme(d_conn).?;
            if (schemeRun(d_scheme)) |d_run| {
                if (d_run.done) |done_fn| {
                    _ = done_fn(@ptrCast(data), result, false);
                }
            }
        }
        return result;
    }

    if ((!Curl_setopt_get_bit(data, BIT_REUSE_FRESH) or Curl_zig_url_data_get_i64(data, DATA_I64_FOLLOWLOCATION) != 0) and
        !Curl_setopt_get_bit(data, BIT_CONNECT_ONLY))
    {
        if (url_attach_existing(data, n_conn, &match, pnow)) {
            const conn: *connectdata = @ptrCast(@alignCast(Curl_zig_url_data_get_ptr(data, DATA_PTR_CONN).?));
            const n_origin = connOrigin(n_conn).?;
            const n_origin_scheme: *const Curl_scheme = @ptrCast(@alignCast(n_origin.scheme.?));
            const tls_upgraded = (n_origin_scheme.flags & PROTOPT_SSL) == 0 and Curl_conn_is_ssl(conn, FIRSTSOCKET);

            Curl_zig_url_conn_set_bit(conn, CONN_BIT_REUSE, true);
            url_conn_reuse_adjust(data, n_conn);

            const c_origin = connOrigin(conn).?;
            const c_origin_scheme: *const Curl_scheme = @ptrCast(@alignCast(c_origin.scheme.?));
            const upg_str: [*:0]const u8 = if (tls_upgraded) " (upgraded to SSL)" else "";

            if (!hasFlag(FLAG_DISABLE_PROXY)) {
                const c_sp = connSocksProxy(conn).?;
                const c_hp = connHttpProxy(conn).?;
                const kind_str: [*:0]const u8 = if (c_sp.peer != null or c_hp.peer != null) "proxy" else "host";
                const host_str: [*:0]const u8 = if (c_sp.peer) |sp_peer|
                    @ptrCast(&sp_peer.user_hostname)
                else if (c_hp.peer) |hp_peer|
                    @ptrCast(&hp_peer.user_hostname)
                else
                    c_origin.hostname;
                infof(data, "Reusing existing %s: connection%s with %s %s", .{
                    c_origin_scheme.name,
                    upg_str,
                    kind_str,
                    host_str,
                });
            } else {
                infof(data, "Reusing existing %s: connection%s with host %s", .{
                    c_origin_scheme.name,
                    upg_str,
                    c_origin.hostname,
                });
            }
        }
    }

    if (Curl_zig_url_data_get_ptr(data, DATA_PTR_CONN) == null) {
        if (match.wait_pipe) {
            infof(data, "Waiting on connection to negotiate possible multiplexing.", .{});
            return CURLE_NO_CONNECTION_AVAILABLE;
        }

        const multi: ?*const Curl_multi = @ptrCast(@alignCast(Curl_zig_url_data_get_ptr(data, DATA_PTR_MULTI)));
        result = Curl_cpool_add(
            data,
            n_conn,
            Curl_zig_url_multi_max_total_connections(multi),
            Curl_zig_url_multi_max_host_connections(multi),
            pnow,
        );
        if (result != CURLE_OK) return result;

        Curl_attach_connection(data, n_conn, true);
        needle = null;

        const d_conn: *connectdata = @ptrCast(@alignCast(Curl_zig_url_data_get_ptr(data, DATA_PTR_CONN).?));
        const conn_ssl: *SslFilterConfig = @ptrCast(@alignCast(Curl_zig_url_conn_get_ptr(d_conn, CONN_PTR_REF_SSL_CONFIG).?));
        const conn_proxy_ssl: ?*SslFilterConfig = if (!hasFlag(FLAG_DISABLE_PROXY))
            @ptrCast(@alignCast(Curl_zig_url_conn_get_ptr(d_conn, CONN_PTR_REF_PROXY_SSL_CONFIG)))
        else
            null;
        const match_proxy_ssl: ?*SslFilterConfig = if (!hasFlag(FLAG_DISABLE_PROXY)) &match.proxy_ssl_config else null;

        result = vtls_scache_asn1.Curl_ssl_conn_config_clone_zig(
            &match.ssl_config,
            match_proxy_ssl,
            conn_ssl,
            conn_proxy_ssl,
        );
        if (result != CURLE_OK) {
            debugInfof(data, "Error: clone connection SSL config", .{});
            return result;
        }

        if (hasFlag(FLAG_USE_NTLM)) {
            const authhost_picked: u32 = @intCast(Curl_zig_url_data_get_i64(data, DATA_I64_AUTHHOST_PICKED));
            if ((authhost_picked & CURLAUTH_NTLM) != 0 and Curl_zig_url_data_get_bit(data, DATA_BIT_AUTHHOST_DONE)) {
                infof(data, "NTLM picked AND auth done set, clear picked", .{});
                Curl_zig_url_data_set_i64(data, DATA_I64_AUTHHOST_PICKED, CURLAUTH_NONE);
                Curl_zig_url_data_set_bit(data, DATA_BIT_AUTHHOST_DONE, false);
            }

            const authproxy_picked: u32 = @intCast(Curl_zig_url_data_get_i64(data, DATA_I64_AUTHPROXY_PICKED));
            if ((authproxy_picked & CURLAUTH_NTLM) != 0 and Curl_zig_url_data_get_bit(data, DATA_BIT_AUTHPROXY_DONE)) {
                infof(data, "NTLM-proxy picked AND auth done set, clear picked", .{});
                Curl_zig_url_data_set_i64(data, DATA_I64_AUTHPROXY_PICKED, CURLAUTH_NONE);
                Curl_zig_url_data_set_bit(data, DATA_BIT_AUTHPROXY_DONE, false);
            }
        }
    }

    const d_conn: *connectdata = @ptrCast(@alignCast(Curl_zig_url_data_get_ptr(data, DATA_PTR_CONN).?));
    result = Curl_init_transfer(data, d_conn);
    if (result != CURLE_OK) return result;

    result = setup_range(data);
    if (result != CURLE_OK) return result;

    const d_scheme = connScheme(d_conn).?;
    Curl_zig_url_data_set_ptr(data, DATA_PTR_INFO_CONN_SCHEME, @ptrCast(@constCast(d_scheme.name)));
    Curl_zig_url_data_set_i64(data, DATA_I64_INFO_CONN_PROTOCOL, d_scheme.protocol & CURLPROTO_MASK);

    const used_proxy: i64 = if (hasFlag(FLAG_DISABLE_PROXY))
        0
    else blk: {
        const sp = connSocksProxy(d_conn).?;
        const hp = connHttpProxy(d_conn).?;
        break :blk if (sp.peer != null or hp.peer != null) 1 else 0;
    };
    Curl_zig_url_data_set_i64(data, DATA_I64_INFO_USED_PROXY, used_proxy);

    return Curl_conn_ev_data_setup(data);
}

pub export fn Curl_connect(data: *Curl_easy, pconnected: *bool) callconv(.c) CURLcode {
    var result: CURLcode = CURLE_OK;
    var conn: ?*connectdata = null;
    pconnected.* = false;

    if (Curl_zig_url_data_get_ptr(data, DATA_PTR_REF_REQ)) |req| {
        Curl_req_hard_reset(req, data);
    }

    result = url_set_data_origin_and_creds(data);
    if (result == CURLE_OK and dataOrigin(data) == null) {
        result = CURLE_FAILED_INIT;
    }

    if (result == CURLE_OK) {
        const pnow = Curl_pgrs_now(data);
        Curl_pgrsTimeWas(data, TIMER_POSTQUEUE, pnow.*);
        result = url_find_or_create_conn(data, pnow);
        conn = @ptrCast(@alignCast(Curl_zig_url_data_get_ptr(data, DATA_PTR_CONN)));
        if (result == CURLE_OK and conn == null) {
            result = CURLE_FAILED_INIT;
        }
    }

    if (result == CURLE_OK) {
        const c = conn.?;
        const c_scheme = connScheme(c).?;
        if (Curl_zig_url_conn_get_bit(c, CONN_BIT_REUSE)) {
            if (Curl_zig_url_conn_get_i64(c, CONN_I64_ATTACHED_XFERS) > 1) {
                pconnected.* = true;
            }
        } else if ((c_scheme.flags & PROTOPT_NONETWORK) != 0) {
            Curl_pgrsTime(data, TIMER_NAMELOOKUP);
            pconnected.* = true;
        } else {
            result = Curl_conn_setup(data, c, FIRSTSOCKET, CURL_CF_SSL_DEFAULT);
            if (result == CURLE_OK) {
                result = Curl_headers_init(data);
            }
            if (!hasFlag(FLAG_DISABLE_VERBOSE_STRINGS)) {
                Curl_trc_multi(data, "Curl_conn_setup() -> %d", @as(c_int, @intCast(result)));
            }
        }
    }

    if (result != CURLE_OK) {
        if (conn) |c| {
            Curl_detach_connection(data);
            Curl_conn_close(data, c, true);
        }
    }

    return result;
}

pub export fn Curl_init_transfer(data: *Curl_easy, conn: ?*connectdata) callconv(.c) CURLcode {
    if (conn) |c| {
        Curl_zig_url_conn_set_bit(c, CONN_BIT_DO_MORE, false);
        if (!hasFlag(FLAG_DISABLE_FTP) and Curl_zig_url_data_get_bit(data, DATA_BIT_WILDCARDMATCH)) {
            if (connScheme(c)) |scheme| {
                if ((scheme.flags & PROTOPT_WILDCARD) == 0) {
                    Curl_zig_url_data_set_bit(data, DATA_BIT_WILDCARDMATCH, false);
                }
            }
        }
    }

    Curl_zig_url_data_set_bit(data, DATA_BIT_DONE, false);

    const no_body = Curl_setopt_get_bit(data, BIT_OPT_NO_BODY);
    Curl_zig_url_data_set_bit(data, DATA_BIT_REQ_NO_BODY, no_body);
    if (no_body) {
        Curl_zig_url_data_set_i64(data, DATA_I64_HTTPREQ, HTTPREQ_HEAD);
    }

    const req = Curl_zig_url_data_get_ptr(data, DATA_PTR_REF_REQ).?;
    const result = Curl_req_start(req, data);
    if (result == CURLE_OK) {
        Curl_pgrsReset(data);
    }
    return result;
}

pub export fn Curl_data_priority_clear_state(data: *Curl_easy) callconv(.c) void {
    if (hasFlag(FLAG_USE_HTTP2) or hasFlag(FLAG_USE_HTTP3)) {
        Curl_zig_url_data_set_i64(data, DATA_I64_STATE_WEIGHT, 0);
    }
}

pub export fn Curl_conn_meta_set(
    conn: *connectdata,
    key: [*:0]const u8,
    meta_data: ?*anyopaque,
    meta_dtor: Curl_meta_dtor,
) callconv(.c) CURLcode {
    const mh: *Curl_hash = @ptrCast(@alignCast(Curl_zig_url_conn_get_ptr(conn, CONN_PTR_REF_META_HASH).?));
    const klen = std.mem.len(key) + 1;
    if (Curl_hash_add2(mh, key, klen, meta_data, meta_dtor) == null) {
        meta_dtor(key, klen, meta_data);
        return CURLE_OUT_OF_MEMORY;
    }
    return CURLE_OK;
}

pub export fn Curl_conn_meta_remove(conn: *connectdata, key: [*:0]const u8) callconv(.c) void {
    const mh: *Curl_hash = @ptrCast(@alignCast(Curl_zig_url_conn_get_ptr(conn, CONN_PTR_REF_META_HASH).?));
    _ = Curl_hash_delete(mh, key, std.mem.len(key) + 1);
}

pub export fn Curl_conn_meta_get(conn: *connectdata, key: [*:0]const u8) callconv(.c) ?*anyopaque {
    const mh: *Curl_hash = @ptrCast(@alignCast(Curl_zig_url_conn_get_ptr(conn, CONN_PTR_REF_META_HASH).?));
    return Curl_hash_pick(mh, key, std.mem.len(key) + 1);
}

pub export fn Curl_get_admin(data: *Curl_easy) callconv(.c) *Curl_easy {
    var admin: *Curl_easy = data;

    if (Curl_zig_url_data_get_i64(data, DATA_I64_MID) == 0) {
        admin = data;
    } else if (Curl_zig_url_data_get_ptr(data, DATA_PTR_MULTI)) |m| {
        admin = Curl_zig_url_multi_admin(@ptrCast(@alignCast(m))) orelse data;
    } else if (Curl_zig_url_data_get_ptr(data, DATA_PTR_MULTI_EASY)) |me| {
        admin = Curl_zig_url_multi_admin(@ptrCast(@alignCast(me))) orelse data;
    }

    if (admin != data) {
        inline for (.{
            FIELD_CONN_MAX_IDLE_MS,
            FIELD_CONN_MAX_AGE_MS,
            FIELD_UPKEEP_INTERVAL_MS,
            FIELD_TIMEOUT,
            FIELD_SERVER_RESPONSE_TIMEOUT,
        }) |fid| {
            Curl_setopt_set_i64(admin, fid, Curl_setopt_get_i64(data, fid));
        }
        Curl_setopt_set_bit(admin, BIT_NO_SIGNAL, Curl_setopt_get_bit(data, BIT_NO_SIGNAL));
    }
    return admin;
}

pub export fn Curl_1st_fatal(r1: CURLcode, r2: CURLcode) callconv(.c) CURLcode {
    if (r1 != CURLE_OK and r1 != CURLE_AGAIN) return r1;
    if (r2 != CURLE_OK and r2 != CURLE_AGAIN) return r2;
    return r1;
}

// ============================================================================
// Unit Tests
// ============================================================================

test "Curl_uc_to_curlcode maps URL error codes" {
    try std.testing.expectEqual(CURLE_UNSUPPORTED_PROTOCOL, Curl_uc_to_curlcode(CURLUE_UNSUPPORTED_SCHEME));
    try std.testing.expectEqual(CURLE_OUT_OF_MEMORY, Curl_uc_to_curlcode(CURLUE_OUT_OF_MEMORY));
    try std.testing.expectEqual(CURLE_LOGIN_DENIED, Curl_uc_to_curlcode(CURLUE_USER_NOT_ALLOWED));
    try std.testing.expectEqual(CURLE_URL_MALFORMAT, Curl_uc_to_curlcode(CURLUE_NO_SCHEME));
}

test "Curl_1st_fatal prioritizes non-EAGAIN errors" {
    try std.testing.expectEqual(CURLE_OK, Curl_1st_fatal(CURLE_OK, CURLE_OK));
    try std.testing.expectEqual(CURLE_AGAIN, Curl_1st_fatal(CURLE_AGAIN, CURLE_OK));
    try std.testing.expectEqual(CURLE_OUT_OF_MEMORY, Curl_1st_fatal(CURLE_AGAIN, CURLE_OUT_OF_MEMORY));
    try std.testing.expectEqual(CURLE_URL_MALFORMAT, Curl_1st_fatal(CURLE_URL_MALFORMAT, CURLE_OUT_OF_MEMORY));
}

test "str_has_ctrl and get_protocol_family" {
    try std.testing.expect(!str_has_ctrl(null));
    try std.testing.expect(!str_has_ctrl("normal_user"));
    try std.testing.expect(str_has_ctrl("bad\nuser"));
    try std.testing.expect(str_has_ctrl("bad\x1fuser"));
    try std.testing.expectEqual(CURLPROTO_FILE, get_protocol_family(&protocol_version_mime.Curl_scheme_file));
}

test "Curl_parse_login_details parses user, password, and options" {
    const input = "alice;AUTH=PLAIN:s3cr3t";
    var user: ?[*:0]u8 = null;
    var passwd: ?[*:0]u8 = null;
    var options: ?[*:0]u8 = null;

    const rc = Curl_parse_login_details(input.ptr, input.len, &user, &passwd, &options);
    try std.testing.expectEqual(CURLE_OK, rc);
    defer {
        if (user) |u| mem.free(u);
        if (passwd) |p| mem.free(p);
        if (options) |o| mem.free(o);
    }

    try std.testing.expectEqualStrings("alice", std.mem.span(user.?));
    try std.testing.expectEqualStrings("s3cr3t", std.mem.span(passwd.?));
    try std.testing.expectEqualStrings("AUTH=PLAIN", std.mem.span(options.?));
}

fn testMetaDtor(key: ?*const anyopaque, key_len: usize, meta_data: ?*anyopaque) callconv(.c) void {
    _ = key;
    _ = key_len;
    if (meta_data) |ptr| {
        const flag: *bool = @ptrCast(@alignCast(ptr));
        flag.* = true;
    }
}

test "Curl_open, Curl_close, and connection metadata lifecycle" {
    var data_opt: ?*Curl_easy = null;
    try std.testing.expectEqual(CURLE_OK, Curl_open(&data_opt));
    const data = data_opt.?;
    defer _ = Curl_close(&data_opt);

    try std.testing.expectEqual(CURLEASY_MAGIC_NUMBER, Curl_zig_url_data_get_i64(data, DATA_I64_MAGIC));
    try std.testing.expectEqual(data, Curl_get_admin(data));

    const conn = allocate_conn(data) orelse return error.OutOfMemory;
    defer Curl_conn_free(data, conn);

    if (Curl_zig_url_conn_get_ptr(conn, CONN_PTR_REF_META_HASH)) |mh| {
        Curl_hash_init(@ptrCast(@alignCast(mh)), 23, collections.CURL_HASH_TYPE_BYTES, conn_meta_freeentry);
    }

    var destroyed = false;
    try std.testing.expectEqual(CURLE_OK, Curl_conn_meta_set(conn, "test:meta:key", &destroyed, testMetaDtor));
    try std.testing.expectEqual(@as(?*anyopaque, &destroyed), Curl_conn_meta_get(conn, "test:meta:key"));
    Curl_conn_meta_remove(conn, "test:meta:key");
    try std.testing.expect(destroyed);
    try std.testing.expectEqual(@as(?*anyopaque, null), Curl_conn_meta_get(conn, "test:meta:key"));
}
