const std = @import("std");
const builtin = @import("builtin");
const backend_options = @import("backend_options");
const vtls_backends = @import("vtls_backends.zig");
const vtls_scache_asn1 = @import("vtls_scache_asn1.zig");
const vtls_core = @import("vtls_core.zig");
const format_parse = @import("format_parse.zig");
const mem = @import("mem.zig");
const containers = @import("containers.zig");
const primitives = @import("primitives.zig");
const io_buffers = @import("io_buffers.zig");
const curlx_time_net = @import("curlx_time_net.zig");
const vtls_impl = vtls_backends.vtls_impl;
const c_ext = vtls_backends.c_ext;

pub const use_gnutls = backend_options.ssl == .gnutls;
var gtls_inited: bool = false;

inline fn cfCtx(cf: *vtls_backends.CurlCfilter) ?*vtls_backends.SslConnectData {
    if (cf.cft != &vtls_backends.vtls_impl.Curl_cft_ssl and cf.cft != &vtls_backends.vtls_impl.Curl_cft_ssl_proxy)
        return null;
    const raw = cf.ctx orelse return null;
    return @ptrCast(@alignCast(raw));
}

inline fn cfCtxCallData(cf: *vtls_backends.CurlCfilter) ?*vtls_backends.CurlEasy {
    const connssl = cfCtx(cf) orelse return null;
    return connssl.call_data;
}

fn peerDispname(peer: *const vtls_backends.SslPeer) [*:0]const u8 {
    if (peer.origin) |orig| {
        if (orig.user_hostname[0] != 0) {
            return @ptrCast(&orig.user_hostname[0]);
        }
        return orig.hostname;
    }
    if (peer.sni) |sni| return sni;
    return "";
}

fn peerHostname(peer: *const vtls_backends.SslPeer) [*:0]const u8 {
    if (peer.origin) |orig| return orig.hostname;
    if (peer.sni) |sni| return sni;
    return "";
}

const CURLcode = vtls_backends.CURLcode;
const CURLE_OK = vtls_backends.CURLE_OK;
const CURLE_NOT_BUILT_IN = vtls_backends.CURLE_NOT_BUILT_IN;
const CURLE_COULDNT_RESOLVE_HOST: CURLcode = 6;
const CURLE_OUT_OF_MEMORY = vtls_backends.CURLE_OUT_OF_MEMORY;
const CURLE_SSL_CONNECT_ERROR = vtls_backends.CURLE_SSL_CONNECT_ERROR;
const CURLE_BAD_FUNCTION_ARGUMENT = vtls_backends.CURLE_BAD_FUNCTION_ARGUMENT;
const CURLE_SEND_ERROR = vtls_backends.CURLE_SEND_ERROR;
const CURLE_RECV_ERROR = vtls_backends.CURLE_RECV_ERROR;
const CURLE_SSL_CIPHER = vtls_backends.CURLE_SSL_CIPHER;
const CURLE_PEER_FAILED_VERIFICATION = vtls_backends.CURLE_PEER_FAILED_VERIFICATION;
const CURLE_SSL_CACERT_BADFILE: CURLcode = 77;
const CURLE_AGAIN = vtls_backends.CURLE_AGAIN;
const CURLE_SSL_CRL_BADFILE = vtls_backends.CURLE_SSL_CRL_BADFILE;
const CURLE_SSL_ISSUER_ERROR = vtls_backends.CURLE_SSL_ISSUER_ERROR;
const CURLE_SSL_PINNEDPUBKEYNOTMATCH = vtls_backends.CURLE_SSL_PINNEDPUBKEYNOTMATCH;
const CURLE_SSL_INVALIDCERTSTATUS = vtls_backends.CURLE_SSL_INVALIDCERTSTATUS;
const CURLE_SSL_CLIENTCERT = vtls_backends.CURLE_SSL_CLIENTCERT;
const CURLE_FAILED_INIT = vtls_backends.CURLE_FAILED_INIT;

const CURL_SSLVERSION_DEFAULT = vtls_backends.CURL_SSLVERSION_DEFAULT;
const CURL_SSLVERSION_TLSv1 = vtls_backends.CURL_SSLVERSION_TLSv1;
const CURL_SSLVERSION_SSLv2 = vtls_backends.CURL_SSLVERSION_SSLv2;
const CURL_SSLVERSION_SSLv3 = vtls_backends.CURL_SSLVERSION_SSLv3;
const CURL_SSLVERSION_TLSv1_0 = vtls_backends.CURL_SSLVERSION_TLSv1_0;
const CURL_SSLVERSION_TLSv1_1 = vtls_backends.CURL_SSLVERSION_TLSv1_1;
const CURL_SSLVERSION_TLSv1_2 = vtls_backends.CURL_SSLVERSION_TLSv1_2;
const CURL_SSLVERSION_TLSv1_3 = vtls_backends.CURL_SSLVERSION_TLSv1_3;

const CURL_SSLVERSION_MAX_NONE = vtls_backends.CURL_SSLVERSION_MAX_NONE;
const CURL_SSLVERSION_MAX_DEFAULT = vtls_backends.CURL_SSLVERSION_MAX_DEFAULT;
const CURL_SSLVERSION_MAX_TLSv1_0 = vtls_backends.CURL_SSLVERSION_MAX_TLSv1_0;
const CURL_SSLVERSION_MAX_TLSv1_1 = vtls_backends.CURL_SSLVERSION_MAX_TLSv1_1;
const CURL_SSLVERSION_MAX_TLSv1_2: u32 = @as(u32, CURL_SSLVERSION_TLSv1_2) << 16;
const CURL_SSLVERSION_MAX_TLSv1_3 = vtls_backends.CURL_SSLVERSION_MAX_TLSv1_3;

const SSLSUPP_CA_PATH = vtls_backends.SSLSUPP_CA_PATH;
const SSLSUPP_CERTINFO = vtls_backends.SSLSUPP_CERTINFO;
const SSLSUPP_PINNEDPUBKEY = vtls_backends.SSLSUPP_PINNEDPUBKEY;
const SSLSUPP_HTTPS_PROXY = vtls_backends.SSLSUPP_HTTPS_PROXY;
const SSLSUPP_CAINFO_BLOB = vtls_backends.SSLSUPP_CAINFO_BLOB;
const SSLSUPP_EARLYDATA: c_uint = 1 << 7;
const SSLSUPP_CA_CACHE = vtls_backends.SSLSUPP_CA_CACHE;
const SSLSUPP_CIPHER_LIST = vtls_backends.SSLSUPP_CIPHER_LIST;
const SSLSUPP_ISSUERCERT = vtls_backends.SSLSUPP_ISSUERCERT;
const SSLSUPP_CRLFILE = vtls_backends.SSLSUPP_CRLFILE;

const CURL_SSL_IO_NEED_NONE = vtls_backends.CURL_SSL_IO_NEED_NONE;
const CURL_SSL_IO_NEED_RECV = vtls_backends.CURL_SSL_IO_NEED_RECV;
const CURL_SSL_IO_NEED_SEND = vtls_backends.CURL_SSL_IO_NEED_SEND;

const ssl_connection_none = vtls_backends.ssl_connection_none;
const ssl_connection_negotiating = vtls_backends.ssl_connection_negotiating;
const ssl_connection_complete = vtls_backends.ssl_connection_complete;

const ssl_connect_1 = vtls_backends.ssl_connect_1;
const ssl_connect_2 = vtls_backends.ssl_connect_2;
const ssl_connect_3 = vtls_backends.ssl_connect_3;
const ssl_connect_done = vtls_backends.ssl_connect_done;

const ssl_earlydata_none = vtls_backends.ssl_earlydata_none;
const ssl_earlydata_await = vtls_backends.ssl_earlydata_await;
const ssl_earlydata_sending = vtls_backends.ssl_earlydata_sending;
const ssl_earlydata_sent = vtls_backends.ssl_earlydata_sent;
const ssl_earlydata_accepted = vtls_backends.ssl_earlydata_accepted;
const ssl_earlydata_rejected = vtls_backends.ssl_earlydata_rejected;

const CURL_TLSAUTH_NONE: c_uint = 0;
const CURL_TLSAUTH_SRP: c_uint = 1;

const EAGAIN_ERRNO: c_int = @backingInt(std.posix.E.AGAIN);
const EINVAL_ERRNO: c_int = @backingInt(std.posix.E.INVAL);

const MPROTO_GTLS_X509_KEY = "tls:gtls:x509:share";

// GnuTLS C constants (verified against GnuTLS 3.8.x headers)
pub const GNUTLS_SERVER: c_uint = 1;
pub const GNUTLS_CLIENT: c_uint = 1 << 1;
pub const GNUTLS_FORCE_CLIENT_CERT: c_uint = 1 << 9;
pub const GNUTLS_NO_TICKETS: c_uint = 1 << 10;
pub const GNUTLS_ENABLE_EARLY_DATA: c_uint = 1 << 20;
pub const GNUTLS_NO_END_OF_EARLY_DATA: c_uint = 1 << 22;
pub const GNUTLS_NO_TICKETS_TLS12: c_uint = 1 << 23;
pub const GNUTLS_NO_STATUS_REQUEST: c_uint = 1 << 24;

pub const GNUTLS_CRD_CERTIFICATE: c_uint = 1;
pub const GNUTLS_CRD_SRP: c_uint = 3;

pub const GNUTLS_X509_FMT_DER: c_uint = 0;
pub const GNUTLS_X509_FMT_PEM: c_uint = 1;
pub const GNUTLS_X509_FMT_PKCS12: c_int = 2;

pub const GNUTLS_NAME_DNS: c_uint = 1;
pub const GNUTLS_ALPN_MANDATORY: c_uint = 1;

pub const GNUTLS_HANDSHAKE_NEW_SESSION_TICKET: c_uint = 4;
pub const GNUTLS_HANDSHAKE_ANY: c_uint = 0xffffffff;
pub const GNUTLS_HOOK_POST: c_int = 1;

pub const GNUTLS_SHUT_RDWR: c_uint = 0;
pub const GNUTLS_SHUT_WR: c_uint = 1;

pub const GNUTLS_VERIFY_ALLOW_X509_V1_CA_CRT: c_uint = 0;
pub const GNUTLS_VERIFY_DO_NOT_ALLOW_SAME: c_uint = 1 << 2;

pub const GNUTLS_CERT_INVALID: c_uint = 1 << 1;
pub const GNUTLS_CERT_REVOKED: c_uint = 1 << 5;
pub const GNUTLS_CERT_SIGNER_NOT_FOUND: c_uint = 1 << 6;
pub const GNUTLS_CERT_SIGNER_NOT_CA: c_uint = 1 << 7;
pub const GNUTLS_CERT_INSECURE_ALGORITHM: c_uint = 1 << 8;
pub const GNUTLS_CERT_NOT_ACTIVATED: c_uint = 1 << 9;
pub const GNUTLS_CERT_EXPIRED: c_uint = 1 << 10;
pub const GNUTLS_CERT_UNEXPECTED_OWNER: c_uint = 1 << 14;
pub const GNUTLS_CERT_INVALID_OCSP_STATUS: c_uint = 1 << 20;

pub const GNUTLS_SSL3: c_uint = 1;
pub const GNUTLS_TLS1_0: c_uint = 2;
pub const GNUTLS_TLS1_1: c_uint = 3;
pub const GNUTLS_TLS1_2: c_uint = 4;
pub const GNUTLS_TLS1_3: c_uint = 5;

pub const GNUTLS_SFLAGS_EXT_MASTER_SECRET: c_uint = 1 << 1;
pub const GNUTLS_SFLAGS_SESSION_TICKET: c_uint = 1 << 7;
pub const GNUTLS_SFLAGS_EARLY_DATA: c_uint = 1 << 10;

pub const GNUTLS_CB_TLS_SERVER_END_POINT: c_uint = 1;
pub const GNUTLS_CB_TLS_EXPORTER: c_uint = 2;

pub const GNUTLS_OCSP_RESP_SUCCESSFUL: c_uint = 0;
pub const GNUTLS_OCSP_CERT_GOOD: c_uint = 0;
pub const GNUTLS_OCSP_CERT_REVOKED: c_uint = 1;
pub const GNUTLS_OCSP_CERT_UNKNOWN: c_uint = 2;

pub const GNUTLS_PKCS_USE_PKCS12_3DES: c_uint = 1 << 1;
pub const GNUTLS_PKCS_USE_PKCS12_ARCFOUR: c_uint = 1 << 2;
pub const GNUTLS_PKCS_USE_PKCS12_RC2_40: c_uint = 1 << 3;
pub const GNUTLS_PKCS_USE_PBES2_3DES: c_uint = 1 << 4;
pub const GNUTLS_PKCS_USE_PBES2_AES_128: c_uint = 1 << 5;
pub const GNUTLS_PKCS_USE_PBES2_AES_192: c_uint = 1 << 6;
pub const GNUTLS_PKCS_USE_PBES2_AES_256: c_uint = 1 << 7;

pub const GNUTLS_E_SUCCESS: c_int = 0;
pub const GNUTLS_E_UNSUPPORTED_VERSION_PACKET: c_int = -8;
pub const GNUTLS_E_FATAL_ALERT_RECEIVED: c_int = -12;
pub const GNUTLS_E_WARNING_ALERT_RECEIVED: c_int = -16;
pub const GNUTLS_E_DECRYPTION_FAILED: c_int = -24;
pub const GNUTLS_E_MEMORY_ERROR: c_int = -25;
pub const GNUTLS_E_AGAIN: c_int = -28;
pub const GNUTLS_E_INSUFFICIENT_CREDENTIALS: c_int = -32;
pub const GNUTLS_E_REHANDSHAKE: c_int = -37;
pub const GNUTLS_E_NO_CERTIFICATE_FOUND: c_int = -49;
pub const GNUTLS_E_SHORT_MEMORY_BUFFER: c_int = -51;
pub const GNUTLS_E_INTERRUPTED: c_int = -52;
pub const GNUTLS_E_REQUESTED_DATA_NOT_AVAILABLE: c_int = -56;
pub const GNUTLS_E_PREMATURE_TERMINATION: c_int = -110;

pub const GNUTLS_OID_X520_COMMON_NAME: [*:0]const u8 = "2.5.4.3";

pub const gnutls_session_t = ?*anyopaque;
pub const gnutls_certificate_credentials_t = ?*anyopaque;
pub const gnutls_srp_client_credentials_t = ?*anyopaque;
pub const gnutls_x509_crt_t = ?*anyopaque;
pub const gnutls_pubkey_t = ?*anyopaque;
pub const gnutls_ocsp_resp_t = ?*anyopaque;
pub const gnutls_transport_ptr_t = ?*anyopaque;

pub const gnutls_datum_t = extern struct {
    data: ?[*]u8 = null,
    size: c_uint = 0,
};

pub const gnutls_push_func = *const fn (gnutls_transport_ptr_t, ?*const anyopaque, usize) callconv(.c) isize;
pub const gnutls_pull_func = *const fn (gnutls_transport_ptr_t, ?*anyopaque, usize) callconv(.c) isize;
pub const gnutls_handshake_hook_func = *const fn (
    gnutls_session_t,
    c_uint,
    c_uint,
    c_uint,
    *const gnutls_datum_t,
) callconv(.c) c_int;
pub const gnutls_keylog_func = *const fn (
    gnutls_session_t,
    [*:0]const u8,
    *const gnutls_datum_t,
) callconv(.c) c_int;

pub const Sha256Ctx = extern struct {
    state: [8]u32,
    count: u64,
    index: c_uint,
    block: [64]u8,
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

pub const gtls_ext = struct {
    pub extern fn gnutls_global_init() callconv(.c) c_int;
    pub extern fn gnutls_global_deinit() callconv(.c) void;
    pub extern fn gnutls_check_version(req_version: ?[*:0]const u8) callconv(.c) ?[*:0]const u8;
    pub extern fn gnutls_rnd(level: c_uint, data: *anyopaque, len: usize) callconv(.c) c_int;

    pub extern fn gnutls_init(session: *gnutls_session_t, flags: c_uint) callconv(.c) c_int;
    pub extern fn gnutls_deinit(session: gnutls_session_t) callconv(.c) void;
    pub extern fn gnutls_bye(session: gnutls_session_t, how: c_uint) callconv(.c) c_int;
    pub extern fn gnutls_handshake(session: gnutls_session_t) callconv(.c) c_int;
    pub extern fn gnutls_record_get_direction(session: gnutls_session_t) callconv(.c) c_int;
    pub extern fn gnutls_record_send(session: gnutls_session_t, data: ?*const anyopaque, data_size: usize) callconv(.c) isize;
    pub extern fn gnutls_record_recv(session: gnutls_session_t, data: ?*anyopaque, data_size: usize) callconv(.c) isize;
    pub extern fn gnutls_record_send_early_data(session: gnutls_session_t, data: ?*const anyopaque, length: usize) callconv(.c) isize;
    pub extern fn gnutls_record_get_max_early_data_size(session: gnutls_session_t) callconv(.c) usize;
    pub extern fn gnutls_record_check_pending(session: gnutls_session_t) callconv(.c) usize;

    pub extern fn gnutls_error_is_fatal(err: c_int) callconv(.c) c_int;
    pub extern fn gnutls_strerror(err: c_int) callconv(.c) [*:0]const u8;
    pub extern fn gnutls_alert_get(session: gnutls_session_t) callconv(.c) c_uint;
    pub extern fn gnutls_alert_get_name(alert: c_uint) callconv(.c) ?[*:0]const u8;

    pub extern fn gnutls_cipher_get(session: gnutls_session_t) callconv(.c) c_uint;
    pub extern fn gnutls_cipher_get_name(algorithm: c_uint) callconv(.c) ?[*:0]const u8;
    pub extern fn gnutls_kx_get(session: gnutls_session_t) callconv(.c) c_uint;
    pub extern fn gnutls_kx_get_name(algorithm: c_uint) callconv(.c) ?[*:0]const u8;
    pub extern fn gnutls_mac_get(session: gnutls_session_t) callconv(.c) c_uint;
    pub extern fn gnutls_mac_get_name(algorithm: c_uint) callconv(.c) ?[*:0]const u8;
    pub extern fn gnutls_protocol_get_version(session: gnutls_session_t) callconv(.c) c_uint;
    pub extern fn gnutls_protocol_get_name(version: c_uint) callconv(.c) ?[*:0]const u8;
    pub extern fn gnutls_cipher_suite_get_name(kx_algorithm: c_uint, cipher_algorithm: c_uint, mac_algorithm: c_uint) callconv(.c) ?[*:0]const u8;

    pub extern fn gnutls_priority_set_direct(session: gnutls_session_t, priorities: [*:0]const u8, err_pos: ?*?[*:0]const u8) callconv(.c) c_int;
    pub extern fn gnutls_credentials_set(session: gnutls_session_t, cred_type: c_uint, cred: ?*anyopaque) callconv(.c) c_int;

    pub extern fn gnutls_certificate_allocate_credentials(res: *gnutls_certificate_credentials_t) callconv(.c) c_int;
    pub extern fn gnutls_certificate_free_credentials(sc: gnutls_certificate_credentials_t) callconv(.c) void;
    pub extern fn gnutls_certificate_set_verify_flags(res: gnutls_certificate_credentials_t, flags: c_uint) callconv(.c) void;
    pub extern fn gnutls_certificate_set_x509_system_trust(cred: gnutls_certificate_credentials_t) callconv(.c) c_int;
    pub extern fn gnutls_certificate_set_x509_trust_mem(cred: gnutls_certificate_credentials_t, ca: *const gnutls_datum_t, fmt: c_uint) callconv(.c) c_int;
    pub extern fn gnutls_certificate_set_x509_trust_file(cred: gnutls_certificate_credentials_t, cafile: [*:0]const u8, fmt: c_uint) callconv(.c) c_int;
    pub extern fn gnutls_certificate_set_x509_trust_dir(cred: gnutls_certificate_credentials_t, ca_dir: [*:0]const u8, fmt: c_uint) callconv(.c) c_int;
    pub extern fn gnutls_certificate_set_x509_crl_file(res: gnutls_certificate_credentials_t, crlfile: [*:0]const u8, fmt: c_uint) callconv(.c) c_int;
    pub extern fn gnutls_certificate_set_x509_key_file(res: gnutls_certificate_credentials_t, certfile: [*:0]const u8, keyfile: [*:0]const u8, fmt: c_uint) callconv(.c) c_int;
    pub extern fn gnutls_certificate_set_x509_key_file2(res: gnutls_certificate_credentials_t, certfile: [*:0]const u8, keyfile: [*:0]const u8, fmt: c_uint, pass: ?[*:0]const u8, flags: c_uint) callconv(.c) c_int;
    pub extern fn gnutls_certificate_set_x509_key_mem(res: gnutls_certificate_credentials_t, cert: *const gnutls_datum_t, key: *const gnutls_datum_t, fmt: c_uint) callconv(.c) c_int;
    pub extern fn gnutls_certificate_set_x509_key_mem2(res: gnutls_certificate_credentials_t, cert: *const gnutls_datum_t, key: *const gnutls_datum_t, fmt: c_uint, pass: ?[*:0]const u8, flags: c_uint) callconv(.c) c_int;
    pub extern fn gnutls_certificate_set_x509_simple_pkcs12_file(res: gnutls_certificate_credentials_t, pkcs12file: [*:0]const u8, fmt: c_uint, password: ?[*:0]const u8) callconv(.c) c_int;
    pub extern fn gnutls_certificate_set_x509_simple_pkcs12_mem(res: gnutls_certificate_credentials_t, p12blob: *const gnutls_datum_t, fmt: c_uint, password: ?[*:0]const u8) callconv(.c) c_int;
    pub extern fn gnutls_certificate_get_peers(session: gnutls_session_t, list_size: *c_uint) callconv(.c) ?[*]const gnutls_datum_t;
    pub extern fn gnutls_certificate_verify_peers2(session: gnutls_session_t, status: *c_uint) callconv(.c) c_int;
    pub extern fn gnutls_certificate_verify_peers3(session: gnutls_session_t, hostname: ?[*:0]const u8, status: *c_uint) callconv(.c) c_int;

    pub extern fn gnutls_srp_allocate_client_credentials(sc: *gnutls_srp_client_credentials_t) callconv(.c) c_int;
    pub extern fn gnutls_srp_free_client_credentials(sc: gnutls_srp_client_credentials_t) callconv(.c) void;
    pub extern fn gnutls_srp_set_client_credentials(res: gnutls_srp_client_credentials_t, username: [*:0]const u8, password: [*:0]const u8) callconv(.c) c_int;

    pub extern fn gnutls_server_name_set(session: gnutls_session_t, name_type: c_uint, name: *const anyopaque, name_length: usize) callconv(.c) c_int;
    pub extern fn gnutls_alpn_set_protocols(session: gnutls_session_t, protocols: [*]const gnutls_datum_t, protocols_size: c_uint, flags: c_uint) callconv(.c) c_int;
    pub extern fn gnutls_alpn_get_selected_protocol(session: gnutls_session_t, protocol: *gnutls_datum_t) callconv(.c) c_int;

    pub extern fn gnutls_session_get_flags(session: gnutls_session_t) callconv(.c) c_uint;
    pub extern fn gnutls_session_is_resumed(session: gnutls_session_t) callconv(.c) c_int;
    pub extern fn gnutls_session_get_data2(session: gnutls_session_t, data: *gnutls_datum_t) callconv(.c) c_int;
    pub extern fn gnutls_session_set_data(session: gnutls_session_t, session_data: ?*const anyopaque, session_data_size: usize) callconv(.c) c_int;
    pub extern fn gnutls_session_set_ptr(session: gnutls_session_t, ptr: ?*anyopaque) callconv(.c) void;
    pub extern fn gnutls_session_get_ptr(session: gnutls_session_t) callconv(.c) ?*anyopaque;
    pub extern fn gnutls_session_set_keylog_function(session: gnutls_session_t, func: gnutls_keylog_func) callconv(.c) void;
    pub extern fn gnutls_session_channel_binding(session: gnutls_session_t, cbtype: c_uint, cb: *gnutls_datum_t) callconv(.c) c_int;
    pub extern fn gnutls_handshake_set_hook_function(session: gnutls_session_t, htype: c_uint, when: c_int, func: ?gnutls_handshake_hook_func) callconv(.c) void;

    pub extern fn gnutls_transport_set_ptr(session: gnutls_session_t, ptr: gnutls_transport_ptr_t) callconv(.c) void;
    pub extern fn gnutls_transport_set_push_function(session: gnutls_session_t, push_func: gnutls_push_func) callconv(.c) void;
    pub extern fn gnutls_transport_set_pull_function(session: gnutls_session_t, pull_func: gnutls_pull_func) callconv(.c) void;
    pub extern fn gnutls_transport_set_errno(session: gnutls_session_t, err: c_int) callconv(.c) void;

    pub extern fn gnutls_x509_crt_init(cert: *gnutls_x509_crt_t) callconv(.c) c_int;
    pub extern fn gnutls_x509_crt_deinit(cert: gnutls_x509_crt_t) callconv(.c) void;
    pub extern fn gnutls_x509_crt_import(cert: gnutls_x509_crt_t, data: *const gnutls_datum_t, format: c_uint) callconv(.c) c_int;
    pub extern fn gnutls_x509_crt_get_dn(cert: gnutls_x509_crt_t, buf: ?[*]u8, buf_size: *usize) callconv(.c) c_int;
    pub extern fn gnutls_x509_crt_get_issuer_dn(cert: gnutls_x509_crt_t, buf: ?[*]u8, buf_size: *usize) callconv(.c) c_int;
    pub extern fn gnutls_x509_crt_get_activation_time(cert: gnutls_x509_crt_t) callconv(.c) isize;
    pub extern fn gnutls_x509_crt_get_expiration_time(cert: gnutls_x509_crt_t) callconv(.c) isize;
    pub extern fn gnutls_x509_crt_get_version(cert: gnutls_x509_crt_t) callconv(.c) c_int;
    pub extern fn gnutls_x509_crt_get_pk_algorithm(cert: gnutls_x509_crt_t, bits: ?*c_uint) callconv(.c) c_int;
    pub extern fn gnutls_x509_crt_check_hostname(cert: gnutls_x509_crt_t, hostname: [*:0]const u8) callconv(.c) c_int;
    pub extern fn gnutls_x509_crt_check_issuer(cert: gnutls_x509_crt_t, issuer: gnutls_x509_crt_t) callconv(.c) c_int;
    pub extern fn gnutls_x509_crt_get_dn_by_oid(cert: gnutls_x509_crt_t, oid: [*:0]const u8, indx: c_uint, raw_flag: c_uint, buf: ?*anyopaque, buf_size: *usize) callconv(.c) c_int;
    pub extern fn gnutls_pk_algorithm_get_name(algorithm: c_uint) callconv(.c) ?[*:0]const u8;

    pub extern fn gnutls_pubkey_init(key: *gnutls_pubkey_t) callconv(.c) c_int;
    pub extern fn gnutls_pubkey_deinit(key: gnutls_pubkey_t) callconv(.c) void;
    pub extern fn gnutls_pubkey_import_x509(key: gnutls_pubkey_t, crt: gnutls_x509_crt_t, flags: c_uint) callconv(.c) c_int;
    pub extern fn gnutls_pubkey_export(key: gnutls_pubkey_t, format: c_uint, output_data: ?*anyopaque, output_data_size: *usize) callconv(.c) c_int;
    pub extern fn gnutls_pubkey_export2(key: gnutls_pubkey_t, format: c_uint, out: *gnutls_datum_t) callconv(.c) c_int;

    pub extern fn gnutls_ocsp_status_request_enable_client(session: gnutls_session_t, responder_id: ?*anyopaque, responder_id_size: usize, extensions: ?*gnutls_datum_t) callconv(.c) c_int;
    pub extern fn gnutls_ocsp_status_request_get(session: gnutls_session_t, response: *gnutls_datum_t) callconv(.c) c_int;
    pub extern fn gnutls_ocsp_status_request_is_checked(session: gnutls_session_t, flags: c_uint) callconv(.c) c_int;
    pub extern fn gnutls_ocsp_resp_init(resp: *gnutls_ocsp_resp_t) callconv(.c) c_int;
    pub extern fn gnutls_ocsp_resp_deinit(resp: gnutls_ocsp_resp_t) callconv(.c) void;
    pub extern fn gnutls_ocsp_resp_import(resp: gnutls_ocsp_resp_t, data: *const gnutls_datum_t) callconv(.c) c_int;
    pub extern fn gnutls_ocsp_resp_get_status(resp: gnutls_ocsp_resp_t) callconv(.c) c_int;
    pub extern fn gnutls_ocsp_resp_get_single(
        resp: gnutls_ocsp_resp_t,
        indx: c_uint,
        digest: ?*c_uint,
        issuer_name_hash: ?*gnutls_datum_t,
        issuer_key_hash: ?*gnutls_datum_t,
        serial_number: ?*gnutls_datum_t,
        cert_status: ?*c_uint,
        this_update: ?*isize,
        next_update: ?*isize,
        revocation_time: ?*isize,
        revocation_reason: ?*c_uint,
    ) callconv(.c) c_int;
    pub extern fn gnutls_ocsp_resp_verify_direct(resp: gnutls_ocsp_resp_t, issuer: gnutls_x509_crt_t, verify: *c_uint, flags: c_uint) callconv(.c) c_int;

    pub extern var gnutls_free: *const fn (?*anyopaque) callconv(.c) void;

    pub extern fn nettle_sha256_init(ctx: *Sha256Ctx) callconv(.c) void;
    pub extern fn nettle_sha256_update(ctx: *Sha256Ctx, length: usize, data: [*]const u8) callconv(.c) void;
    pub extern fn nettle_sha256_digest(ctx: *Sha256Ctx, length: usize, digest: [*]u8) callconv(.c) void;

    pub extern fn Curl_gmtime(intime: isize, store: *Tm) callconv(.c) CURLcode;
    pub extern fn Curl_http_acc_auth_allowed_to_host(data: ?*vtls_impl.CurlEasy) callconv(.c) bool;
    pub extern "c" fn time(tloc: ?*isize) callconv(.c) isize;
    pub extern fn curlx_fopen(filename: [*:0]const u8, mode: [*:0]const u8) callconv(.c) ?*anyopaque;
    pub extern fn curlx_fclose(file: ?*anyopaque) callconv(.c) c_int;
    pub extern fn gnutls_x509_trust_list_add_Waiting_unused() void;
    pub extern fn fread(ptr: ?*anyopaque, size: usize, nmemb: usize, stream: ?*anyopaque) callconv(.c) usize;
};

pub const gtls_shared_creds = extern struct {
    creds: gnutls_certificate_credentials_t = null,
    CAfile: ?[*:0]u8 = null,
    time: vtls_impl.CurlTime = .{ .tv_sec = 0, .tv_usec = 0 },
    refcount: usize = 0,
    trust_setup: bool = false,
};

pub const GtlsSslBackendData = extern struct {
    session: gnutls_session_t = null,
    shared_creds: ?*gtls_shared_creds = null,
    srp_client_cred: gnutls_srp_client_credentials_t = null,
    io_result: CURLcode = CURLE_OK,
    sent_shutdown: bool = false,
};

pub const GtlsCtx = GtlsSslBackendData;

pub const gtls_ssl_backend_data = GtlsSslBackendData;
pub const gtls_ctx = GtlsSslBackendData;

fn gnutlsFreePtr(ptr: ?*anyopaque) void {
    if (comptime use_gnutls) {
        if (ptr) |p| {
            gtls_ext.gnutls_free(p);
        }
    }
}

fn gtls_push(
    s: gnutls_transport_ptr_t,
    buf: ?*const anyopaque,
    blen: usize,
) callconv(.c) isize {
    if (comptime !use_gnutls) return -1;
    const cf: *vtls_impl.CurlCfilter = @ptrCast(@alignCast(s orelse return -1));
    const connssl = cfCtx(cf) orelse return -1;
    const backend: *GtlsSslBackendData = @ptrCast(@alignCast(connssl.backend orelse return -1));
    const data = cfCtxCallData(cf);
    var nwritten: usize = 0;

    backend.io_result = c_ext.Curl_conn_cf_send(
        cf.next,
        data,
        @ptrCast(buf orelse return -1),
        blen,
        false,
        &nwritten,
    );
    if (backend.io_result != CURLE_OK) {
        gtls_ext.gnutls_transport_set_errno(
            backend.session,
            if (backend.io_result == CURLE_AGAIN) EAGAIN_ERRNO else EINVAL_ERRNO,
        );
        return -1;
    }
    return @intCast(nwritten);
}

fn gtls_pull(
    s: gnutls_transport_ptr_t,
    buf: ?*anyopaque,
    blen: usize,
) callconv(.c) isize {
    if (comptime !use_gnutls) return -1;
    const cf: *vtls_impl.CurlCfilter = @ptrCast(@alignCast(s orelse return -1));
    const connssl = cfCtx(cf) orelse return -1;
    const backend: *GtlsSslBackendData = @ptrCast(@alignCast(connssl.backend orelse return -1));
    const data = cfCtxCallData(cf);
    var nread: usize = 0;

    if (!backend.shared_creds.?.trust_setup) {
        const result = Curl_gtls_client_trust_setup(cf, data, backend);
        if (result != CURLE_OK) {
            gtls_ext.gnutls_transport_set_errno(backend.session, EINVAL_ERRNO);
            backend.io_result = result;
            return -1;
        }
    }

    backend.io_result = c_ext.Curl_conn_cf_recv(
        cf.next,
        data,
        @ptrCast(buf orelse return -1),
        blen,
        &nread,
    );
    if (backend.io_result != CURLE_OK) {
        gtls_ext.gnutls_transport_set_errno(
            backend.session,
            if (backend.io_result == CURLE_AGAIN) EAGAIN_ERRNO else EINVAL_ERRNO,
        );
        return -1;
    }
    return @intCast(nread);
}

fn gtlsInit() callconv(.c) c_int {
    if (comptime use_gnutls) {
        return if (gtls_ext.gnutls_global_init() == 0) 1 else 0;
    }
    return 0;
}

fn gtlsCleanup() callconv(.c) void {
    if (comptime use_gnutls) {
        gtls_ext.gnutls_global_deinit();
    }
}

fn showtime(data: ?*vtls_impl.CurlEasy, text: [*:0]const u8, stamp: isize) void {
    const wkday = [7][*:0]const u8{ "Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat" };
    const month = [12][*:0]const u8{ "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec" };
    var tm: Tm = std.mem.zeroes(Tm);
    const result = curlx_time_net.curlx_gmtime(@intCast(stamp), &tm);
    if (result != CURLE_OK) return;

    const wday_idx: usize = if (tm.tm_wday >= 0 and tm.tm_wday < 7) @intCast(tm.tm_wday) else 0;
    const mon_idx: usize = if (tm.tm_mon >= 0 and tm.tm_mon < 12) @intCast(tm.tm_mon) else 0;
    c_ext.Curl_infof(
        data,
        "  %s: %s, %02d %s %4d %02d:%02d:%02d GMT",
        text,
        wkday[wday_idx],
        tm.tm_mday,
        month[mon_idx],
        tm.tm_year + 1900,
        tm.tm_hour,
        tm.tm_min,
        tm.tm_sec,
    );
}

fn load_file(file: [*:0]const u8) gnutls_datum_t {
    var loaded_file = gnutls_datum_t{ .data = null, .size = 0 };
    const f = c_ext.fopen(file, "rb") orelse return loaded_file;
    defer _ = c_ext.fclose(f);

    const max_buf: usize = 1024 * 1024;
    const buf = mem.malloc(max_buf) orelse return loaded_file;
    const n = c_ext.fread(buf, 1, max_buf, f);
    if (n == 0 and max_buf > 0) {
        mem.free(buf);
        return loaded_file;
    }
    loaded_file.data = buf;
    loaded_file.size = @intCast(n);
    return loaded_file;
}

fn unload_file(file: gnutls_datum_t) void {
    if (file.data) |d| {
        if (file.size > 0) mem.secureZero(d, file.size);
        mem.freeSized(d, file.size);
    }
}

fn do_file_type(filetype: ?[*:0]const u8) c_int {
    const ft = filetype orelse return @intCast(GNUTLS_X509_FMT_PEM);
    if (ft[0] == 0) return @intCast(GNUTLS_X509_FMT_PEM);
    if (primitives.curl_strequal(ft, "PEM") != 0) return @intCast(GNUTLS_X509_FMT_PEM);
    if (primitives.curl_strequal(ft, "DER") != 0) return @intCast(GNUTLS_X509_FMT_DER);
    if (primitives.curl_strequal(ft, "P12") != 0) return GNUTLS_X509_FMT_PKCS12;
    return -1;
}

pub fn set_ssl_version_min_max(
    data: ?*vtls_impl.CurlEasy,
    prioritylist: *?[*:0]const u8,
    ssl_config: *const vtls_backends.SslFilterConfig,
    tls13support: bool,
) CURLcode {
    var ssl_version = ssl_config.version;
    var ssl_version_max = ssl_config.version_max;

    if ((ssl_version == CURL_SSLVERSION_DEFAULT) or (ssl_version == CURL_SSLVERSION_TLSv1)) {
        ssl_version = CURL_SSLVERSION_TLSv1_0;
    }
    if (ssl_version_max == CURL_SSLVERSION_MAX_NONE) {
        ssl_version_max = CURL_SSLVERSION_MAX_DEFAULT;
    }
    // Accept both canonical CURL_SSLVERSION_MAX_TLSv1_2 (6 << 16) and vtls_impl's bitmask alias
    if (ssl_version_max == vtls_impl.CURL_SSLVERSION_MAX_TLSv1_2) {
        ssl_version_max = CURL_SSLVERSION_MAX_TLSv1_2;
    }

    if (!tls13support) {
        if ((ssl_version_max == CURL_SSLVERSION_MAX_TLSv1_3) or
            (ssl_version_max == CURL_SSLVERSION_MAX_DEFAULT))
        {
            ssl_version_max = CURL_SSLVERSION_MAX_TLSv1_2;
        }
    } else if (ssl_version_max == CURL_SSLVERSION_MAX_DEFAULT) {
        ssl_version_max = CURL_SSLVERSION_MAX_TLSv1_3;
    }

    switch (ssl_version | ssl_version_max) {
        CURL_SSLVERSION_TLSv1_0 | CURL_SSLVERSION_MAX_TLSv1_0 => {
            prioritylist.* = "+VERS-TLS1.0";
            return CURLE_OK;
        },
        CURL_SSLVERSION_TLSv1_0 | CURL_SSLVERSION_MAX_TLSv1_1 => {
            prioritylist.* = "+VERS-TLS1.0:+VERS-TLS1.1";
            return CURLE_OK;
        },
        CURL_SSLVERSION_TLSv1_0 | CURL_SSLVERSION_MAX_TLSv1_2 => {
            prioritylist.* = "+VERS-TLS1.0:+VERS-TLS1.1:+VERS-TLS1.2";
            return CURLE_OK;
        },
        CURL_SSLVERSION_TLSv1_1 | CURL_SSLVERSION_MAX_TLSv1_1 => {
            prioritylist.* = "+VERS-TLS1.1";
            return CURLE_OK;
        },
        CURL_SSLVERSION_TLSv1_1 | CURL_SSLVERSION_MAX_TLSv1_2 => {
            prioritylist.* = "+VERS-TLS1.1:+VERS-TLS1.2";
            return CURLE_OK;
        },
        CURL_SSLVERSION_TLSv1_2 | CURL_SSLVERSION_MAX_TLSv1_2 => {
            prioritylist.* = "+VERS-TLS1.2";
            return CURLE_OK;
        },
        CURL_SSLVERSION_TLSv1_3 | CURL_SSLVERSION_MAX_TLSv1_3 => {
            if (tls13support) {
                prioritylist.* = "+VERS-TLS1.3";
                return CURLE_OK;
            }
        },
        CURL_SSLVERSION_TLSv1_0 | CURL_SSLVERSION_MAX_TLSv1_3 => {
            if (tls13support) {
                prioritylist.* = "+VERS-TLS1.0:+VERS-TLS1.1:+VERS-TLS1.2:+VERS-TLS1.3";
                return CURLE_OK;
            }
        },
        CURL_SSLVERSION_TLSv1_1 | CURL_SSLVERSION_MAX_TLSv1_3 => {
            if (tls13support) {
                prioritylist.* = "+VERS-TLS1.1:+VERS-TLS1.2:+VERS-TLS1.3";
                return CURLE_OK;
            }
        },
        CURL_SSLVERSION_TLSv1_2 | CURL_SSLVERSION_MAX_TLSv1_3 => {
            if (tls13support) {
                prioritylist.* = "+VERS-TLS1.2:+VERS-TLS1.3";
                return CURLE_OK;
            }
        },
        else => {},
    }

    c_ext.Curl_failf(data, "GnuTLS: cannot set ssl protocol");
    return CURLE_SSL_CONNECT_ERROR;
}

pub const gnutls_set_ssl_version_min_max = set_ssl_version_min_max;

fn cf_gtls_update_session_id(
    cf: *vtls_impl.CurlCfilter,
    data: ?*vtls_impl.CurlEasy,
    session: gnutls_session_t,
) CURLcode {
    if (comptime !use_gnutls) return CURLE_NOT_BUILT_IN;
    const d = data orelse return CURLE_OK;
    const conn_config = vtls_impl.Curl_ssl_cf_get_filter_config(cf) orelse return CURLE_OK;
    if (!conn_config.primary_cache_session()) return CURLE_OK;

    const connssl = cfCtx(cf) orelse return CURLE_OK;
    const peer_key = connssl.peer.scache_key orelse return CURLE_OK;

    var scache: ?*vtls_backends.CurlSslScache = null;
    var has_share_scache = false;
    var trc_feat: ?*vtls_backends.CurlTrcFeat = null;
    c_ext.Curl_vtls_acc_scache_params(d, &scache, &has_share_scache, &trc_feat);
    if (!vtls_scache_asn1.Curl_ssl_scache_use_zig(d, scache, conn_config)) {
        return CURLE_OK;
    }

    var connect_id = gnutls_datum_t{};
    var result: CURLcode = CURLE_OK;

    const rc = gtls_ext.gnutls_session_get_data2(session, &connect_id);
    if (rc == GNUTLS_E_SUCCESS and connect_id.data != null and connect_id.size > 0) {
        defer gnutlsFreePtr(connect_id.data);
        const sdata_copy = mem.malloc(connect_id.size) orelse return CURLE_OUT_OF_MEMORY;
        @memcpy(sdata_copy[0..connect_id.size], connect_id.data.?[0..connect_id.size]);

        var sc_session: ?*vtls_core.CurlSslSession = null;
        var earlydata_max: usize = 0;

        if ((gtls_ext.gnutls_session_get_flags(session) & GNUTLS_SFLAGS_EARLY_DATA) != 0) {
            earlydata_max = gtls_ext.gnutls_record_get_max_early_data_size(session);
        }

        const ietf_tls_id = @as(c_int, @intCast(gtls_ext.gnutls_protocol_get_version(session))) + 0x0300;
        result = vtls_scache_asn1.Curl_ssl_session_create2(
            sdata_copy,
            connect_id.size,
            ietf_tls_id,
            connssl.negotiated_alpn,
            0,
            earlydata_max,
            null,
            0,
            &sc_session,
        );
        if (result == CURLE_OK and sc_session != null) {
            result = vtls_scache_asn1.Curl_ssl_scache_put_zig(
                cf,
                d,
                scache,
                has_share_scache,
                conn_config,
                trc_feat,
                peer_key,
                sc_session,
            );
        } else {
            mem.secureZero(sdata_copy, connect_id.size);
            mem.freeSized(sdata_copy, connect_id.size);
        }
    }
    return result;
}

fn gtls_handshake_cb(
    session: gnutls_session_t,
    htype: c_uint,
    when: c_uint,
    incoming: c_uint,
    msg: *const gnutls_datum_t,
) callconv(.c) c_int {
    _ = msg;
    if (comptime !use_gnutls) return 0;
    const cf_opt: ?*vtls_impl.CurlCfilter = @ptrCast(@alignCast(gtls_ext.gnutls_session_get_ptr(session)));
    if (when == @as(c_uint, @intCast(GNUTLS_HOOK_POST)) and incoming != 0) {
        const cf = cf_opt orelse return 0;
        const data = cfCtxCallData(cf);
        if (data != null and htype == GNUTLS_HANDSHAKE_NEW_SESSION_TICKET) {
            _ = cf_gtls_update_session_id(cf, data, session);
        }
    }
    return 0;
}

pub fn Curl_gtls_shared_creds_create(
    data: ?*vtls_impl.CurlEasy,
    pcreds: *?*gtls_shared_creds,
) CURLcode {
    pcreds.* = null;
    if (comptime !use_gnutls) return CURLE_NOT_BUILT_IN;

    const raw = mem.calloc(1, @sizeOf(gtls_shared_creds)) orelse return CURLE_OUT_OF_MEMORY;
    const shared: *gtls_shared_creds = @ptrCast(@alignCast(raw));
    const rc = gtls_ext.gnutls_certificate_allocate_credentials(&shared.creds);
    if (rc != GNUTLS_E_SUCCESS) {
        c_ext.Curl_failf(data, "gnutls_cert_all_cred() failed: %s", gtls_ext.gnutls_strerror(rc));
        mem.freeSized(shared, @sizeOf(gtls_shared_creds));
        return CURLE_SSL_CONNECT_ERROR;
    }
    shared.refcount = 1;
    shared.time = curlx_time_net.curlx_now();
    pcreds.* = shared;
    return CURLE_OK;
}

pub const gtls_shared_creds_Create = Curl_gtls_shared_creds_create;
pub const gtls_shared_creds_create = Curl_gtls_shared_creds_create;

pub fn Curl_gtls_shared_creds_up_ref(creds: *gtls_shared_creds) CURLcode {
    creds.refcount += 1;
    return CURLE_OK;
}

pub const gtls_shared_creds_up_ref = Curl_gtls_shared_creds_up_ref;

pub fn Curl_gtls_shared_creds_free(pcreds: *?*gtls_shared_creds) void {
    const creds = pcreds.* orelse return;
    pcreds.* = null;
    creds.refcount -= 1;
    if (creds.refcount == 0) {
        if (comptime use_gnutls) {
            if (creds.creds != null) {
                gtls_ext.gnutls_certificate_free_credentials(creds.creds);
            }
        }
        mem.free(creds.CAfile);
        mem.freeSized(creds, @sizeOf(gtls_shared_creds));
    }
}

pub const gtls_shared_creds_free = Curl_gtls_shared_creds_free;

pub fn gtls_populate_creds(
    cf: *vtls_impl.CurlCfilter,
    data: ?*vtls_impl.CurlEasy,
    creds: gnutls_certificate_credentials_t,
) CURLcode {
    if (comptime !use_gnutls) return CURLE_NOT_BUILT_IN;
    const config = vtls_impl.Curl_ssl_cf_get_filter_config(cf) orelse return CURLE_SSL_CONNECT_ERROR;
    const is_proxy = vtls_impl.Curl_ssl_cf_is_proxy(cf);
    var rc: c_int = 0;

    if (!config.verifypeer()) {
        return CURLE_OK;
    }

    const ca_info_blob: ?*const vtls_backends.CurlBlob = if (config.ca_info_blob) |b| b else c_ext.Curl_vtls_acc_ssl_ca_info_blob(data, is_proxy);
    const cafile_opt: ?[*:0]const u8 = if (config.CAfile) |f| f else c_ext.Curl_vtls_acc_ssl_cainfo(data, is_proxy);
    const capath_opt: ?[*:0]const u8 = if (config.CApath) |p| p else c_ext.Curl_vtls_acc_ssl_capath(data, is_proxy);
    const crlfile_opt: ?[*:0]const u8 = if (config.CRLfile) |c| c else c_ext.Curl_vtls_acc_ssl_crlfile(data, is_proxy);

    if (config.native_ca_store()) {
        rc = gtls_ext.gnutls_certificate_set_x509_system_trust(creds);
        if (rc < 0) {
            c_ext.Curl_infof(
                data,
                "error reading native ca store (%s), continuing anyway",
                gtls_ext.gnutls_strerror(rc),
            );
        } else {
            c_ext.Curl_infof(data, "found %d certificates in native ca store", rc);
            if (ca_info_blob == null and cafile_opt == null and capath_opt == null) {
                return CURLE_OK;
            }
        }
    }

    if (ca_info_blob) |blob| {
        if (blob.len > std.math.maxInt(c_uint)) {
            c_ext.Curl_failf(data, "CA info blob too large");
            return CURLE_SSL_CACERT_BADFILE;
        }
        const ca_instruction_datum = gnutls_datum_t{
            .data = @ptrCast(@constCast(blob.data)),
            .size = @intCast(blob.len),
        };
        rc = gtls_ext.gnutls_certificate_set_x509_trust_mem(creds, &ca_instruction_datum, GNUTLS_X509_FMT_PEM);
        if (rc < 0) {
            c_ext.Curl_infof(
                data,
                "error reading ca cert blob (%s)%s",
                gtls_ext.gnutls_strerror(rc),
                if (config.native_ca_store()) @as([*:0]const u8, ", continuing anyway") else @as([*:0]const u8, ""),
            );
            if (!config.native_ca_store()) {
                c_ext.Curl_failf(data, "error reading ca cert blob (%s)", gtls_ext.gnutls_strerror(rc));
                return CURLE_SSL_CACERT_BADFILE;
            }
        } else {
            c_ext.Curl_infof(data, "found %d certificates in ca cert blob", rc);
        }
    } else if (cafile_opt) |cafile| {
        gtls_ext.gnutls_certificate_set_verify_flags(creds, GNUTLS_VERIFY_ALLOW_X509_V1_CA_CRT);
        rc = gtls_ext.gnutls_certificate_set_x509_trust_file(creds, cafile, GNUTLS_X509_FMT_PEM);
        if (rc < 0) {
            c_ext.Curl_infof(
                data,
                "error reading ca cert file %s (%s)%s",
                cafile,
                gtls_ext.gnutls_strerror(rc),
                if (config.native_ca_store()) @as([*:0]const u8, ", continuing anyway") else @as([*:0]const u8, ""),
            );
            if (!config.native_ca_store()) {
                c_ext.Curl_failf(
                    data,
                    "error reading ca cert file %s (%s)",
                    cafile,
                    gtls_ext.gnutls_strerror(rc),
                );
                return CURLE_SSL_CACERT_BADFILE;
            }
        } else {
            c_ext.Curl_infof(data, "found %d certificates in %s", rc, cafile);
        }
    }

    if (capath_opt) |capath| {
        rc = gtls_ext.gnutls_certificate_set_x509_trust_dir(creds, capath, GNUTLS_X509_FMT_PEM);
        if (rc < 0) {
            c_ext.Curl_infof(
                data,
                "error reading ca cert file %s (%s)%s",
                capath,
                gtls_ext.gnutls_strerror(rc),
                if (config.native_ca_store()) @as([*:0]const u8, ", continuing anyway") else @as([*:0]const u8, ""),
            );
            if (!config.native_ca_store()) {
                c_ext.Curl_failf(
                    data,
                    "error reading ca cert file %s (%s)",
                    capath,
                    gtls_ext.gnutls_strerror(rc),
                );
                return CURLE_SSL_CACERT_BADFILE;
            }
        } else {
            c_ext.Curl_infof(data, "found %d certificates in %s", rc, capath);
        }
    }

    if (crlfile_opt) |crlfile| {
        rc = gtls_ext.gnutls_certificate_set_x509_crl_file(creds, crlfile, GNUTLS_X509_FMT_PEM);
        if (rc < 0) {
            c_ext.Curl_failf(data, "error reading crl file %s (%s)", crlfile, gtls_ext.gnutls_strerror(rc));
            return CURLE_SSL_CRL_BADFILE;
        } else {
            c_ext.Curl_infof(data, "found %d CRL in %s", rc, crlfile);
        }
    }

    return CURLE_OK;
}

fn gtls_shared_creds_expired(
    data: ?*vtls_impl.CurlEasy,
    sc: *const gtls_shared_creds,
) bool {
    const timeout = c_ext.Curl_vtls_acc_ssl_ca_cache_timeout(data);
    if (timeout < 0) return false;
    const now = curlx_time_net.curlx_now();
    const elapsed_ms = curlx_time_net.curlx_ptimediff_ms(&now, &sc.time);
    return elapsed_ms > (@as(i64, timeout) * 1000);
}

fn gtls_shared_creds_different(
    cf: *vtls_impl.CurlCfilter,
    sc: *const gtls_shared_creds,
) bool {
    const conn_config = vtls_impl.Curl_ssl_cf_get_filter_config(cf) orelse return true;
    if (sc.CAfile == null or conn_config.CAfile == null) {
        return sc.CAfile != conn_config.CAfile;
    }
    return !std.mem.eql(u8, std.mem.span(sc.CAfile.?), std.mem.span(conn_config.CAfile.?));
}

fn gtls_get_cached_creds(
    cf: *vtls_impl.CurlCfilter,
    data: *vtls_impl.CurlEasy,
) ?*gtls_shared_creds {
    const multi_proto_hash = c_ext.Curl_vtls_acc_multi_proto_hash(data) orelse return null;
    const raw = c_ext.Curl_hash_pick(
        multi_proto_hash,
        @ptrCast(@constCast(MPROTO_GTLS_X509_KEY.ptr)),
        MPROTO_GTLS_X509_KEY.len,
    ) orelse return null;
    const shared: *gtls_shared_creds = @ptrCast(@alignCast(raw));
    if (!gtls_shared_creds_expired(data, shared) and !gtls_shared_creds_different(cf, shared)) {
        return shared;
    }
    return null;
}

fn gtls_shared_creds_hash_free(
    key: *const anyopaque,
    key_len: usize,
    p: *anyopaque,
) callconv(.c) void {
    _ = key;
    _ = key_len;
    var shared: ?*gtls_shared_creds = @ptrCast(@alignCast(p));
    Curl_gtls_shared_creds_free(&shared);
}

fn gtls_set_cached_creds(
    cf: *vtls_impl.CurlCfilter,
    data: *vtls_impl.CurlEasy,
    shared: *gtls_shared_creds,
) void {
    const multi_proto_hash = c_ext.Curl_vtls_acc_multi_proto_hash(data) orelse return;
    const conn_config = vtls_impl.Curl_ssl_cf_get_filter_config(cf) orelse return;

    if (conn_config.CAfile) |cafile| {
        shared.CAfile = mem.strdup(cafile);
        if (shared.CAfile == null) return;
    }

    if (Curl_gtls_shared_creds_up_ref(shared) != CURLE_OK) return;

    if (c_ext.Curl_hash_add2(
        multi_proto_hash,
        @ptrCast(@constCast(MPROTO_GTLS_X509_KEY.ptr)),
        MPROTO_GTLS_X509_KEY.len,
        shared,
        gtls_shared_creds_hash_free,
    ) == null) {
        var s: ?*gtls_shared_creds = shared;
        Curl_gtls_shared_creds_free(&s);
    }
}

pub fn Curl_gtls_client_trust_setup(
    cf: *vtls_impl.CurlCfilter,
    data: ?*vtls_impl.CurlEasy,
    gtls: *GtlsSslBackendData,
) CURLcode {
    if (comptime !use_gnutls) return CURLE_NOT_BUILT_IN;
    const conn_config = vtls_impl.Curl_ssl_cf_get_filter_config(cf) orelse return CURLE_SSL_CONNECT_ERROR;

    const cache_criteria_met = (data != null and c_ext.Curl_vtls_acc_ssl_ca_cache_timeout(data) != 0) and
        conn_config.verifypeer() and
        conn_config.CApath == null and
        conn_config.ca_info_blob == null and
        conn_config.CRLfile == null and
        !conn_config.native_ca_store() and
        conn_config.clientcert == null and
        conn_config.cert_blob == null;

    var cached_creds: ?*gtls_shared_creds = null;
    if (cache_criteria_met) {
        cached_creds = gtls_get_cached_creds(cf, data.?);
    }

    var result: CURLcode = CURLE_OK;
    if (cached_creds != null and Curl_gtls_shared_creds_up_ref(cached_creds.?) == CURLE_OK) {
        c_ext.Curl_infof(data, "UsingSSL: reusing x509 credentials from cache");
        Curl_gtls_shared_creds_free(&gtls.shared_creds);
        gtls.shared_creds = cached_creds;
        const rc = gtls_ext.gnutls_credentials_set(
            gtls.session,
            GNUTLS_CRD_CERTIFICATE,
            gtls.shared_creds.?.creds,
        );
        if (rc != GNUTLS_E_SUCCESS) {
            c_ext.Curl_failf(data, "gnutls_credentials_set() failed: %s", gtls_ext.gnutls_strerror(rc));
            return CURLE_SSL_CONNECT_ERROR;
        }
    } else {
        c_ext.Curl_infof(data, "UsingSSL: populating x509 credentials");
        result = gtls_populate_creds(cf, data, gtls.shared_creds.?.creds);
        if (result != CURLE_OK) return result;
        gtls.shared_creds.?.trust_setup = true;
        if (cache_criteria_met) {
            gtls_set_cached_creds(cf, data.?, gtls.shared_creds.?);
        }
    }
    return result;
}

fn keylog_callback(
    session: gnutls_session_t,
    label: [*:0]const u8,
    secret: *const gnutls_datum_t,
) callconv(.c) c_int {
    if (comptime !use_gnutls) return 0;
    var crandom = gnutls_datum_t{};
    var srandom = gnutls_datum_t{};

    gtls_ext_random: {
        // gnutls_session_get_random is optional; only log if client random is 32 bytes
        const S = struct {
            extern fn gnutls_session_get_random(
                s: gnutls_session_t,
                client: *gnutls_datum_t,
                server: *gnutls_datum_t,
            ) callconv(.c) void;
        };
        S.gnutls_session_get_random(session, &crandom, &srandom);
        if (crandom.size != 32 or crandom.data == null or secret.data == null) {
            break :gtls_ext_random;
        }
        _ = vtls_core.Curl_tls_keylog_write(
            label,
            @ptrCast(crandom.data.?),
            crandom.size,
            secret.data.?,
            secret.size,
        );
    }
    return 0;
}

pub fn gtls_set_priority(
    cf: *vtls_impl.CurlCfilter,
    data: ?*vtls_impl.CurlEasy,
    gtls: *GtlsSslBackendData,
    priority: [*:0]const u8,
) CURLcode {
    if (comptime !use_gnutls) return CURLE_NOT_BUILT_IN;
    const conn_config = vtls_impl.Curl_ssl_cf_get_filter_config(cf) orelse return CURLE_SSL_CONNECT_ERROR;
    var dyn_buf: containers.dynbuf = undefined;
    var err: ?[*:0]const u8 = null;
    var result: CURLcode = CURLE_OK;

    containers.curlx_dyn_init(&dyn_buf, 4096);
    defer containers.curlx_dyn_free(&dyn_buf);

    var to_set: [*:0]const u8 = priority;
    if (conn_config.cipher_list) |cipher_list| {
        if (cipher_list[0] == '+' or cipher_list[0] == '-' or cipher_list[0] == '!') {
            result = containers.curlx_dyn_addf(&dyn_buf, "%s:%s", priority, cipher_list);
            if (result != CURLE_OK) return result;
            to_set = containers.curlx_dyn_ptr(&dyn_buf) orelse return CURLE_OUT_OF_MEMORY;
        } else {
            to_set = cipher_list;
        }
    }

    c_ext.Curl_infof(data, "GnuTLS priority: %s", to_set);
    const rc = gtls_ext.gnutls_priority_set_direct(gtls.session, to_set, &err);
    if (rc != GNUTLS_E_SUCCESS) {
        c_ext.Curl_failf(
            data,
            "Error %d setting GnuTLS priority: %s",
            rc,
            err orelse @as([*:0]const u8, ""),
        );
        return CURLE_SSL_CONNECT_ERROR;
    }
    return CURLE_OK;
}

pub const gtls_Priority_Set = gtls_set_priority;

pub fn gtls_client_init(
    cf: *vtls_impl.CurlCfilter,
    data: ?*vtls_impl.CurlEasy,
    peer: *const vtls_backends.SslPeer,
    earlydata_max: usize,
    gtls: *GtlsSslBackendData,
) CURLcode {
    if (comptime !use_gnutls) return CURLE_NOT_BUILT_IN;
    const conn_config = vtls_impl.Curl_ssl_cf_get_filter_config(cf) orelse return CURLE_SSL_CONNECT_ERROR;
    const is_proxy = vtls_impl.Curl_ssl_cf_is_proxy(cf);
    const username = c_ext.Curl_vtls_acc_ssl_username(data, is_proxy);
    const password = c_ext.Curl_vtls_acc_ssl_password(data, is_proxy);
    var init_flags: c_uint = GNUTLS_CLIENT;
    var tls13support = false;
    var rc: c_int = 0;

    if (!gtls_inited) {
        _ = gtlsInit();
        gtls_inited = true;
    }

    if (conn_config.version == CURL_SSLVERSION_SSLv2) {
        c_ext.Curl_failf(data, "GnuTLS does not support SSLv2");
        return CURLE_SSL_CONNECT_ERROR;
    } else if (conn_config.version == CURL_SSLVERSION_SSLv3) {
        c_ext.Curl_failf(data, "GnuTLS does not support SSLv3");
        return CURLE_SSL_CONNECT_ERROR;
    }

    var result = Curl_gtls_shared_creds_create(data, &gtls.shared_creds);
    if (result != CURLE_OK) return result;

    if (username != null and gtls_ext.Curl_http_acc_auth_allowed_to_host(data)) {
        rc = gtls_ext.gnutls_srp_allocate_client_credentials(&gtls.srp_client_cred);
        if (rc != GNUTLS_E_SUCCESS) {
            c_ext.Curl_failf(
                data,
                "gnutls_srp_allocate_client_cred() failed: %s",
                gtls_ext.gnutls_strerror(rc),
            );
            return CURLE_OUT_OF_MEMORY;
        }
        rc = gtls_ext.gnutls_srp_set_client_credentials(
            gtls.srp_client_cred,
            username.?,
            password orelse "",
        );
        if (rc != GNUTLS_E_SUCCESS) {
            c_ext.Curl_failf(
                data,
                "gnutls_srp_set_client_cred() failed: %s",
                gtls_ext.gnutls_strerror(rc),
            );
            return CURLE_BAD_FUNCTION_ARGUMENT;
        }
    }

    init_flags |= GNUTLS_NO_TICKETS_TLS12;
    init_flags |= GNUTLS_FORCE_CLIENT_CERT;

    if (!conn_config.verifystatus()) {
        init_flags |= GNUTLS_NO_STATUS_REQUEST;
    }

    if (peer.transport == vtls_backends.TRNSPRT_QUIC and earlydata_max > 0) {
        init_flags |= GNUTLS_ENABLE_EARLY_DATA | GNUTLS_NO_END_OF_EARLY_DATA;
    } else if (earlydata_max > 0 and earlydata_max != std.math.maxInt(usize)) {
        init_flags |= GNUTLS_ENABLE_EARLY_DATA | GNUTLS_NO_END_OF_EARLY_DATA;
    }

    rc = gtls_ext.gnutls_init(&gtls.session, init_flags);
    if (rc != GNUTLS_E_SUCCESS) {
        c_ext.Curl_failf(data, "gnutls_init() failed: %d", rc);
        return CURLE_SSL_CONNECT_ERROR;
    }

    if (peer.sni) |sni| {
        const sni_slice = std.mem.span(sni);
        if (gtls_ext.gnutls_server_name_set(
            gtls.session,
            GNUTLS_NAME_DNS,
            sni_slice.ptr,
            sni_slice.len,
        ) < 0) {
            c_ext.Curl_failf(data, "Failed to set SNI");
            return CURLE_SSL_CONNECT_ERROR;
        }
    }

    rc = gtls_ext.gnutls_priority_set_direct(gtls.session, "NORMAL", null);
    if (rc != GNUTLS_E_SUCCESS) {
        c_ext.Curl_failf(data, "Failed to set default GnuTLS priority (%d)", rc);
        return CURLE_SSL_CONNECT_ERROR;
    }

    if (conn_config.version == CURL_SSLVERSION_DEFAULT or
        conn_config.version == CURL_SSLVERSION_TLSv1)
    {
        if (conn_config.version_max == CURL_SSLVERSION_MAX_NONE or
            conn_config.version_max == CURL_SSLVERSION_MAX_DEFAULT or
            conn_config.version_max == CURL_SSLVERSION_MAX_TLSv1_3)
        {
            conn_config.version_max = CURL_SSLVERSION_MAX_TLSv1_3;
        }
    }

    var prioritylist: ?[*:0]const u8 = null;
    var priority_buf: [256]u8 = undefined;
    if (peer.transport == vtls_backends.TRNSPRT_QUIC) {
        const eff_max = if (conn_config.version_max == CURL_SSLVERSION_MAX_NONE or
            conn_config.version_max == CURL_SSLVERSION_MAX_DEFAULT)
            CURL_SSLVERSION_MAX_TLSv1_3
        else
            conn_config.version_max;
        if (eff_max < CURL_SSLVERSION_MAX_TLSv1_3) {
            c_ext.Curl_failf(data, "QUIC needs at least TLS version 1.3");
            return CURLE_SSL_CONNECT_ERROR;
        }
        prioritylist = "NORMAL:%PROFILE_MEDIUM:-VERS-ALL:+VERS-TLS1.3:-CIPHER-ALL:+AES-128-GCM:" ++
            "+AES-256-GCM:+CHACHA20-POLY1305:+AES-128-CCM:-GROUP-ALL:" ++
            "+GROUP-SECP256R1:+GROUP-X25519:+GROUP-SECP384R1:+GROUP-SECP521R1:" ++
            "%DISABLE_TLS13_COMPAT_MODE";
    } else if (conn_config.version != CURL_SSLVERSION_DEFAULT or
        conn_config.version_max != CURL_SSLVERSION_MAX_TLSv1_3 or
        username != null)
    {
        const ver = gtls_ext.gnutls_check_version("3.6.5");
        tls13support = (ver != null);

        result = set_ssl_version_min_max(data, &prioritylist, conn_config, tls13support);
        if (result != CURLE_OK) return result;

        if (username == null) {
            _ = c_ext.curl_msnprintf(
                &priority_buf,
                priority_buf.len,
                "NORMAL:-VERS-ALL:%s",
                prioritylist.?,
            );
        } else {
            _ = c_ext.curl_msnprintf(
                &priority_buf,
                priority_buf.len,
                "NORMAL:-VERS-ALL:+SRP:%s",
                prioritylist.?,
            );
        }
        prioritylist = @ptrCast(&priority_buf);
    } else {
        prioritylist = "NORMAL";
    }

    result = gtls_set_priority(cf, data, gtls, prioritylist.?);
    if (result != CURLE_OK) return result;

    if (conn_config.clientcert != null or conn_config.cert_blob != null) {
        if (gtls.shared_creds.?.trust_setup) {
            var new_creds: ?*gtls_shared_creds = null;
            result = Curl_gtls_shared_creds_create(data, &new_creds);
            if (result != CURLE_OK) return result;
            Curl_gtls_shared_creds_free(&gtls.shared_creds);
            gtls.shared_creds = new_creds;
        }

        const file_type = do_file_type(conn_config.cert_type);
        if (file_type < 0) {
            c_ext.Curl_failf(
                data,
                "unknown cert type '%s' for certificate",
                conn_config.cert_type orelse "",
            );
            return CURLE_SSL_CLIENTCERT;
        }

        if (conn_config.key_passwd != null) {
            const pass = conn_config.key_passwd.?;
            const ft_flags: c_uint = GNUTLS_PKCS_USE_PKCS12_3DES |
                GNUTLS_PKCS_USE_PKCS12_ARCFOUR |
                GNUTLS_PKCS_USE_PKCS12_RC2_40 |
                GNUTLS_PKCS_USE_PBES2_3DES |
                GNUTLS_PKCS_USE_PBES2_AES_128 |
                GNUTLS_PKCS_USE_PBES2_AES_192 |
                GNUTLS_PKCS_USE_PBES2_AES_256;

            if (file_type != GNUTLS_X509_FMT_PKCS12) {
                const ft_u: c_uint = @intCast(file_type);
                if (conn_config.cert_blob) |cert_blob| {
                    const cert_d = gnutls_datum_t{
                        .data = @ptrCast(@constCast(cert_blob.data)),
                        .size = @intCast(cert_blob.len),
                    };
                    var key_d = gnutls_datum_t{ .data = null, .size = 0 };
                    var loaded_key = gnutls_datum_t{ .data = null, .size = 0 };
                    defer unload_file(loaded_key);

                    if (conn_config.key_blob) |kb| {
                        key_d = .{ .data = @ptrCast(@constCast(kb.data)), .size = @intCast(kb.len) };
                    } else if (conn_config.key) |keyfile| {
                        loaded_key = load_file(keyfile);
                        key_d = loaded_key;
                    } else {
                        key_d = cert_d;
                    }
                    rc = gtls_ext.gnutls_certificate_set_x509_key_mem2(
                        gtls.shared_creds.?.creds,
                        &cert_d,
                        &key_d,
                        ft_u,
                        pass,
                        ft_flags,
                    );
                } else if (conn_config.key_blob) |kb| {
                    const key_d = gnutls_datum_t{
                        .data = @ptrCast(@constCast(kb.data)),
                        .size = @intCast(kb.len),
                    };
                    const loaded_cert = load_file(conn_config.clientcert.?);
                    defer unload_file(loaded_cert);
                    rc = gtls_ext.gnutls_certificate_set_x509_key_mem2(
                        gtls.shared_creds.?.creds,
                        &loaded_cert,
                        &key_d,
                        ft_u,
                        pass,
                        ft_flags,
                    );
                } else {
                    const certfile = conn_config.clientcert.?;
                    rc = gtls_ext.gnutls_certificate_set_x509_key_file2(
                        gtls.shared_creds.?.creds,
                        certfile,
                        conn_config.key orelse certfile,
                        ft_u,
                        pass,
                        ft_flags,
                    );
                }
                if (rc != GNUTLS_E_SUCCESS) {
                    c_ext.Curl_failf(
                        data,
                        "error reading X.509 potentially-encrypted key or certificate file: %s",
                        gtls_ext.gnutls_strerror(rc),
                    );
                    return CURLE_SSL_CONNECT_ERROR;
                }
            } else {
                if (conn_config.cert_blob) |cert_blob| {
                    const p12_d = gnutls_datum_t{
                        .data = @ptrCast(@constCast(cert_blob.data)),
                        .size = @intCast(cert_blob.len),
                    };
                    rc = gtls_ext.gnutls_certificate_set_x509_simple_pkcs12_mem(
                        gtls.shared_creds.?.creds,
                        &p12_d,
                        GNUTLS_X509_FMT_DER,
                        pass,
                    );
                } else {
                    rc = gtls_ext.gnutls_certificate_set_x509_simple_pkcs12_file(
                        gtls.shared_creds.?.creds,
                        conn_config.clientcert.?,
                        GNUTLS_X509_FMT_DER,
                        pass,
                    );
                }
                if (rc != GNUTLS_E_SUCCESS) {
                    c_ext.Curl_failf(
                        data,
                        "error reading X.509 key or certificate file: %s",
                        gtls_ext.gnutls_strerror(rc),
                    );
                    return CURLE_SSL_CONNECT_ERROR;
                }
            }
        } else {
            if (file_type == GNUTLS_X509_FMT_PKCS12) {
                if (conn_config.cert_blob) |cert_blob| {
                    const p12_d = gnutls_datum_t{
                        .data = @ptrCast(@constCast(cert_blob.data)),
                        .size = @intCast(cert_blob.len),
                    };
                    rc = gtls_ext.gnutls_certificate_set_x509_simple_pkcs12_mem(
                        gtls.shared_creds.?.creds,
                        &p12_d,
                        GNUTLS_X509_FMT_DER,
                        null,
                    );
                } else {
                    rc = gtls_ext.gnutls_certificate_set_x509_simple_pkcs12_file(
                        gtls.shared_creds.?.creds,
                        conn_config.clientcert.?,
                        GNUTLS_X509_FMT_DER,
                        null,
                    );
                }
            } else {
                const ft_u: c_uint = @intCast(file_type);
                if (conn_config.cert_blob) |cert_blob| {
                    const cert_d = gnutls_datum_t{
                        .data = @ptrCast(@constCast(cert_blob.data)),
                        .size = @intCast(cert_blob.len),
                    };
                    var key_d = gnutls_datum_t{ .data = null, .size = 0 };
                    var loaded_key = gnutls_datum_t{ .data = null, .size = 0 };
                    defer unload_file(loaded_key);

                    if (conn_config.key_blob) |kb| {
                        key_d = .{ .data = @ptrCast(@constCast(kb.data)), .size = @intCast(kb.len) };
                    } else if (conn_config.key) |keyfile| {
                        loaded_key = load_file(keyfile);
                        key_d = loaded_key;
                    } else {
                        key_d = cert_d;
                    }
                    rc = gtls_ext.gnutls_certificate_set_x509_key_mem2(
                        gtls.shared_creds.?.creds,
                        &cert_d,
                        &key_d,
                        ft_u,
                        null,
                        0,
                    );
                } else if (conn_config.key_blob) |kb| {
                    const key_d = gnutls_datum_t{
                        .data = @ptrCast(@constCast(kb.data)),
                        .size = @intCast(kb.len),
                    };
                    const loaded_cert = load_file(conn_config.clientcert.?);
                    defer unload_file(loaded_cert);
                    rc = gtls_ext.gnutls_certificate_set_x509_key_mem2(
                        gtls.shared_creds.?.creds,
                        &loaded_cert,
                        &key_d,
                        ft_u,
                        null,
                        0,
                    );
                } else {
                    const certfile = conn_config.clientcert.?;
                    rc = gtls_ext.gnutls_certificate_set_x509_key_file2(
                        gtls.shared_creds.?.creds,
                        certfile,
                        conn_config.key orelse certfile,
                        ft_u,
                        null,
                        0,
                    );
                }
            }
            if (rc != GNUTLS_E_SUCCESS) {
                c_ext.Curl_failf(
                    data,
                    "error reading X.509 key or certificate file: %s",
                    gtls_ext.gnutls_strerror(rc),
                );
                return CURLE_SSL_CONNECT_ERROR;
            }
        }
    }

    if (username != null and gtls.srp_client_cred != null) {
        rc = gtls_ext.gnutls_credentials_set(
            gtls.session,
            GNUTLS_CRD_SRP,
            gtls.srp_client_cred,
        );
        if (rc != GNUTLS_E_SUCCESS) {
            c_ext.Curl_failf(data, "gnutls_credentials_set() failed: %s", gtls_ext.gnutls_strerror(rc));
            return CURLE_SSL_CONNECT_ERROR;
        }
    } else {
        rc = gtls_ext.gnutls_credentials_set(
            gtls.session,
            GNUTLS_CRD_CERTIFICATE,
            gtls.shared_creds.?.creds,
        );
        if (rc != GNUTLS_E_SUCCESS) {
            c_ext.Curl_failf(data, "gnutls_credentials_set() failed: %s", gtls_ext.gnutls_strerror(rc));
            return CURLE_SSL_CONNECT_ERROR;
        }
    }

    if (conn_config.verifystatus()) {
        rc = gtls_ext.gnutls_ocsp_status_request_enable_client(gtls.session, null, 0, null);
        if (rc != GNUTLS_E_SUCCESS) {
            c_ext.Curl_failf(
                data,
                "gnutls_ocsp_status_request_enable_client() failed: %d",
                rc,
            );
            return CURLE_SSL_CONNECT_ERROR;
        }
    }

    vtls_core.Curl_tls_keylog_open();
    if (vtls_core.Curl_tls_keylog_enabled()) {
        gtls_ext.gnutls_session_set_keylog_function(gtls.session, keylog_callback);
    }

    return CURLE_OK;
}

pub const CurlGtlsCtxSetupCb = *const fn (
    cf: *vtls_impl.CurlCfilter,
    data: ?*vtls_impl.CurlEasy,
    cb_user_data: ?*anyopaque,
) callconv(.c) CURLcode;

pub const CurlGtlsInitSessionReuseCb = *const fn (
    cf: *vtls_impl.CurlCfilter,
    data: ?*vtls_impl.CurlEasy,
    alpns: ?*const vtls_backends.AlpnSpec,
    scs: *vtls_core.CurlSslSession,
    do_early_data: *bool,
) callconv(.c) CURLcode;

fn gtls_apply_session(
    gctx: *GtlsSslBackendData,
    cf: *vtls_impl.CurlCfilter,
    data: ?*vtls_impl.CurlEasy,
    peer: *const vtls_backends.SslPeer,
    alpns: *vtls_backends.AlpnSpec,
    sess_reuse_cb: ?CurlGtlsInitSessionReuseCb,
    scs_opt: ?*vtls_core.CurlSslSession,
    pwas_setup: *bool,
) CURLcode {
    if (comptime !use_gnutls) return CURLE_NOT_BUILT_IN;
    const conn_config = vtls_impl.Curl_ssl_cf_get_filter_config(cf) orelse return CURLE_SSL_CONNECT_ERROR;
    const scs = scs_opt orelse return CURLE_OK;

    if (scs.sdata != null and scs.sdata_len > 0 and
        (scs.alpn == null or vtls_impl.Curl_alpn_contains_proto(alpns, scs.alpn)))
    {
        var result = gtls_client_init(cf, data, peer, scs.earlydata_max, gctx);
        if (result != CURLE_OK) return result;
        pwas_setup.* = true;

        const rc = gtls_ext.gnutls_session_set_data(gctx.session, scs.sdata, scs.sdata_len);
        if (rc < 0) {
            c_ext.Curl_infof(data, "SSL session not accepted by GnuTLS, continuing without");
        } else {
            c_ext.Curl_infof(
                data,
                "SSL reusing session with ALPN '%s'",
                scs.alpn orelse @as([*:0]const u8, "-"),
            );
            if (conn_config.earlydata() and scs.alpn != null and
                !c_ext.Curl_conn_is_connect_only(cf.conn))
            {
                var do_early_data = false;
                if (sess_reuse_cb) |cb| {
                    result = cb(cf, data, alpns, scs, &do_early_data);
                    if (result != CURLE_OK) return result;
                }
                if (do_early_data) {
                    vtls_impl.Curl_alpn_restrict_to(alpns, scs.alpn.?);
                }
            }
        }
    }
    return CURLE_OK;
}

pub fn Curl_gtls_ctx_init(
    gctx: *GtlsSslBackendData,
    cf: *vtls_impl.CurlCfilter,
    data: ?*vtls_impl.CurlEasy,
    peer: *const vtls_backends.SslPeer,
    alpns_requested: ?*const vtls_backends.AlpnSpec,
    cb_setup: ?CurlGtlsCtxSetupCb,
    cb_user_data: ?*anyopaque,
    ssl_user_data: ?*anyopaque,
    sess_reuse_cb: ?CurlGtlsInitSessionReuseCb,
) callconv(.c) CURLcode {
    if (comptime !use_gnutls) return CURLE_NOT_BUILT_IN;
    const conn_config = vtls_impl.Curl_ssl_cf_get_filter_config(cf) orelse return CURLE_SSL_CONNECT_ERROR;

    var alpns: vtls_backends.AlpnSpec = std.mem.zeroes(vtls_backends.AlpnSpec);
    vtls_impl.Curl_alpn_copy(&alpns, alpns_requested);

    var scs: ?*vtls_core.CurlSslSession = null;
    var gtls_session_setup = false;
    var result: CURLcode = CURLE_OK;

    var scache: ?*vtls_backends.CurlSslScache = null;
    var has_share_scache = false;
    var trc_feat: ?*vtls_backends.CurlTrcFeat = null;
    c_ext.Curl_vtls_acc_scache_params(data, &scache, &has_share_scache, &trc_feat);

    if (!gtls_session_setup and conn_config.primary_cache_session() and !conn_config.verifystatus()) {
        if (peer.scache_key) |peer_key| {
            if (vtls_scache_asn1.Curl_ssl_scache_use_zig(data, scache, conn_config)) {
                result = vtls_scache_asn1.Curl_ssl_scache_take_zig(
                    cf,
                    data,
                    scache,
                    has_share_scache,
                    conn_config,
                    trc_feat,
                    peer_key,
                    &scs,
                );
                if (result == CURLE_OK) {
                    result = gtls_apply_session(
                        gctx,
                        cf,
                        data,
                        peer,
                        &alpns,
                        sess_reuse_cb,
                        scs,
                        &gtls_session_setup,
                    );
                }
            }
        }
    }

    defer if (scs) |s| {
        if (peer.scache_key) |peer_key| {
            _ = vtls_scache_asn1.Curl_ssl_scache_return_zig(
                cf,
                data,
                scache,
                has_share_scache,
                conn_config,
                trc_feat,
                peer_key,
                s,
            );
        } else {
            vtls_scache_asn1.Curl_ssl_session_destroy(s);
        }
    };

    if (result != CURLE_OK) return result;

    if (!gtls_session_setup) {
        result = gtls_client_init(cf, data, peer, 0, gctx);
        if (result != CURLE_OK) return result;
    }

    gtls_ext.gnutls_session_set_ptr(gctx.session, ssl_user_data);

    if (cb_setup) |cb| {
        result = cb(cf, data, cb_user_data);
        if (result != CURLE_OK) return result;
    }

    vtls_core.Curl_tls_keylog_open();
    if (vtls_core.Curl_tls_keylog_enabled()) {
        gtls_ext.gnutls_session_set_keylog_function(gctx.session, keylog_callback);
    }

    if (alpns.count > 0) {
        var gtls_alpns: [vtls_backends.ALPN_ENTRIES_MAX]gnutls_datum_t = undefined;
        var i: usize = 0;
        while (i < alpns.count) : (i += 1) {
            const entry_slice = std.mem.sliceTo(&alpns.entries[i], 0);
            gtls_alpns[i] = .{
                .data = @constCast(entry_slice.ptr),
                .size = @intCast(entry_slice.len),
            };
        }
        if (gtls_ext.gnutls_alpn_set_protocols(
            gctx.session,
            &gtls_alpns,
            @intCast(alpns.count),
            GNUTLS_ALPN_MANDATORY,
        ) != 0) {
            c_ext.Curl_failf(data, "failed setting ALPN");
            return CURLE_SSL_CONNECT_ERROR;
        }
    }

    return CURLE_OK;
}

fn gtls_ctx_init_stream(
    gctx: *GtlsSslBackendData,
    cf: *vtls_impl.CurlCfilter,
    data: ?*vtls_impl.CurlEasy,
    peer: *const vtls_backends.SslPeer,
    alpns: ?*const vtls_backends.AlpnSpec,
    sc_session: ?*vtls_core.CurlSslSession,
    cb_new_session: ?gnutls_handshake_hook_func,
    user_data: ?*anyopaque,
) CURLcode {
    if (comptime !use_gnutls) return CURLE_NOT_BUILT_IN;

    const earlydata_max: usize = if (sc_session) |s| s.earlydata_max else 0;
    const result = gtls_client_init(cf, data, peer, earlydata_max, gctx);
    if (result != CURLE_OK) return result;

    gtls_ext.gnutls_session_set_ptr(gctx.session, user_data);

    if (alpns) |alpn_spec| {
        if (alpn_spec.count > 0) {
            var gtls_alpns: [vtls_backends.ALPN_ENTRIES_MAX]gnutls_datum_t = undefined;
            var i: usize = 0;
            while (i < alpn_spec.count) : (i += 1) {
                const entry_slice = std.mem.sliceTo(&alpn_spec.entries[i], 0);
                gtls_alpns[i] = .{
                    .data = @constCast(entry_slice.ptr),
                    .size = @intCast(entry_slice.len),
                };
            }
            if (gtls_ext.gnutls_alpn_set_protocols(
                gctx.session,
                &gtls_alpns,
                @intCast(alpn_spec.count),
                GNUTLS_ALPN_MANDATORY,
            ) != 0) {
                c_ext.Curl_failf(data, "failed setting ALPN");
                return CURLE_SSL_CONNECT_ERROR;
            }
        }
    }

    if (cb_new_session) |hook| {
        gtls_ext.gnutls_handshake_set_hook_function(
            gctx.session,
            GNUTLS_HANDSHAKE_ANY,
            GNUTLS_HOOK_POST,
            hook,
        );
    }

    if (sc_session) |sess| {
        if (sess.sdata != null and sess.sdata_len > 0) {
            const rc = gtls_ext.gnutls_session_set_data(gctx.session, sess.sdata, sess.sdata_len);
            if (rc < 0) {
                c_ext.Curl_infof(data, "SSL failed to set session ID");
            } else {
                c_ext.Curl_infof(
                    data,
                    "SSL reusing session ID (early data: %zu)",
                    sess.earlydata_max,
                );
            }
        }
    }

    return CURLE_OK;
}

fn gtls_connect_step1(
    cf: *vtls_impl.CurlCfilter,
    data: *vtls_impl.CurlEasy,
) CURLcode {
    if (comptime !use_gnutls) return CURLE_NOT_BUILT_IN;
    const connssl = cfCtx(cf) orelse return CURLE_SSL_CONNECT_ERROR;
    const backend: *GtlsSslBackendData = @ptrCast(@alignCast(connssl.backend orelse return CURLE_SSL_CONNECT_ERROR));
    const conn_config = vtls_impl.Curl_ssl_cf_get_filter_config(cf) orelse return CURLE_SSL_CONNECT_ERROR;
    var sc_session: ?*vtls_core.CurlSslSession = null;
    var result: CURLcode = CURLE_OK;

    if (connssl.state == ssl_connection_complete) return CURLE_OK;

    if (conn_config.primary_cache_session()) {
        if (connssl.peer.scache_key) |peer_key| {
            var scache: ?*vtls_backends.CurlSslScache = null;
            var has_share_scache = false;
            var trc_feat: ?*vtls_backends.CurlTrcFeat = null;
            c_ext.Curl_vtls_acc_scache_params(data, &scache, &has_share_scache, &trc_feat);
            if (vtls_scache_asn1.Curl_ssl_scache_use_zig(data, scache, conn_config)) {
                _ = vtls_scache_asn1.Curl_ssl_scache_take_zig(
                    cf,
                    data,
                    scache,
                    has_share_scache,
                    conn_config,
                    trc_feat,
                    peer_key,
                    &sc_session,
                );
            }
        }
        if (sc_session) |sess| {
            if (sess.earlydata_max > 0 and conn_config.earlydata()) {
                var do_early_data = false;
                result = vtls_impl.Curl_on_session_reuse(
                    cf,
                    data,
                    connssl.alpn,
                    sess,
                    &do_early_data,
                    cf.sockindex == vtls_backends.FIRSTSOCKET,
                );
                if (result != CURLE_OK) {
                    vtls_scache_asn1.Curl_ssl_session_destroy(sc_session);
                    return result;
                }
                if (!do_early_data) {
                    sess.earlydata_max = 0;
                } else {
                    connssl.earlydata_max = sess.earlydata_max;
                    connssl.earlydata_state = ssl_earlydata_await;
                    io_buffers.Curl_bufq_init2(
                        &connssl.earlydata,
                        connssl.earlydata_max,
                        1,
                        io_buffers.BUFQ_OPT_NO_SPARES,
                    );
                }
            }
        }
    }

    result = gtls_ctx_init_stream(
        backend,
        cf,
        data,
        &connssl.peer,
        connssl.alpn,
        sc_session,
        gtls_handshake_cb,
        cf,
    );
    vtls_scache_asn1.Curl_ssl_session_destroy(sc_session);
    if (result != CURLE_OK) return result;

    if (conn_config.primary_cache_session() and cf.conn != null and vtls_impl.Curl_ssl_cf_is_proxy(cf)) {
        const proxy_cf = c_ext.Curl_vtls_acc_conn_cfilter(cf.conn, cf.sockindex);
        if (proxy_cf != null and proxy_cf.?.ctx != null) {
            const proxy_ssl = cfCtx(proxy_cf.?);
            if (proxy_ssl != null and proxy_ssl.?.backend != null) {
                const proxy_backend: *GtlsSslBackendData = @ptrCast(@alignCast(proxy_ssl.?.backend.?));
                if (proxy_backend.session != null and proxy_backend.session != backend.session) {
                    var sess_datum = gnutls_datum_t{};
                    if (gtls_ext.gnutls_session_get_data2(proxy_backend.session, &sess_datum) == GNUTLS_E_SUCCESS) {
                        defer gnutlsFreePtr(sess_datum.data);
                        _ = gtls_ext.gnutls_session_set_data(backend.session, sess_datum.data, sess_datum.size);
                    }
                }
            }
        }
    }

    gtls_ext.gnutls_transport_set_ptr(backend.session, cf);
    gtls_ext.gnutls_transport_set_push_function(backend.session, gtls_push);
    gtls_ext.gnutls_transport_set_pull_function(backend.session, gtls_pull);

    return CURLE_OK;
}

pub fn pkp_pin_peer_pubkey(
    data: ?*vtls_impl.CurlEasy,
    cert: gnutls_x509_crt_t,
    pinnedpubkey: ?[*:0]const u8,
) CURLcode {
    if (comptime !use_gnutls) return CURLE_NOT_BUILT_IN;
    const pin = pinnedpubkey orelse return CURLE_OK;

    var pubkey: gnutls_pubkey_t = null;
    if (gtls_ext.gnutls_pubkey_init(&pubkey) < 0 or pubkey == null) {
        c_ext.Curl_failf(data, "SSL: failed to initialize public key");
        return CURLE_SSL_PINNEDPUBKEYNOTMATCH;
    }
    defer gtls_ext.gnutls_pubkey_deinit(pubkey);

    if (gtls_ext.gnutls_pubkey_import_x509(pubkey, cert, 0) < 0) {
        c_ext.Curl_failf(data, "SSL: failed to import public key from x509 cert");
        return CURLE_SSL_PINNEDPUBKEYNOTMATCH;
    }

    var out = gnutls_datum_t{};
    if (gtls_ext.gnutls_pubkey_export2(pubkey, GNUTLS_X509_FMT_DER, &out) == 0 and out.data != null) {
        defer gnutlsFreePtr(out.data);
        return vtls_impl.Curl_pin_peer_pubkey(data, pin, out.data, out.size);
    }

    var len: usize = 0;
    const ret = gtls_ext.gnutls_pubkey_export(pubkey, GNUTLS_X509_FMT_DER, null, &len);
    if (ret != GNUTLS_E_SHORT_MEMORY_BUFFER or len == 0) {
        return CURLE_SSL_PINNEDPUBKEYNOTMATCH;
    }

    const buff: [*]u8 = mem.malloc(len) orelse return CURLE_SSL_PINNEDPUBKEYNOTMATCH;
    defer mem.free(buff);

    if (gtls_ext.gnutls_pubkey_export(pubkey, GNUTLS_X509_FMT_DER, buff, &len) != 0) {
        return CURLE_SSL_PINNEDPUBKEYNOTMATCH;
    }

    return vtls_impl.Curl_pin_peer_pubkey(data, pin, buff, len);
}

pub const gtls_pinned_peer_pubkey = pkp_pin_peer_pubkey;

fn gtls_verify_cert(
    cf: *vtls_impl.CurlCfilter,
    data: ?*vtls_impl.CurlEasy,
    session: gnutls_session_t,
    peer: *const vtls_backends.SslPeer,
) CURLcode {
    if (comptime !use_gnutls) return CURLE_NOT_BUILT_IN;
    const config = vtls_impl.Curl_ssl_cf_get_filter_config(cf) orelse return CURLE_SSL_CONNECT_ERROR;
    const ssl_config = vtls_impl.Curl_ssl_cf_get_easy_config(cf, data);
    var status: c_uint = 0;

    const rc = gtls_ext.gnutls_certificate_verify_peers2(session, &status);
    if (rc < 0) {
        c_ext.Curl_failf(
            data,
            "Server cert verify failed: %d (%s)",
            rc,
            gtls_ext.gnutls_strerror(rc),
        );
        return CURLE_SSL_CONNECT_ERROR;
    }

    if (ssl_config) |sc| {
        sc.certverifyresult = @intCast(status);
    }

    if (status & GNUTLS_CERT_INVALID != 0) {
        if (config.verifypeer()) {
            var reason: [*:0]const u8 = "no reason, ONLY_INVALID";
            if (status & GNUTLS_CERT_EXPIRED != 0) {
                reason = "certificate has expired";
            } else if (status & GNUTLS_CERT_NOT_ACTIVATED != 0) {
                reason = "certificate not activated yet";
            } else if (status & GNUTLS_CERT_REVOKED != 0) {
                reason = "certificate has been revoked";
            } else if (status & GNUTLS_CERT_SIGNER_NOT_FOUND != 0) {
                reason = "certificate signer not found";
            } else if (status & GNUTLS_CERT_SIGNER_NOT_CA != 0) {
                reason = "certificate signer not a CA";
            } else if (status & GNUTLS_CERT_INSECURE_ALGORITHM != 0) {
                reason = "certificate uses an insecure algorithm";
            } else if (status & GNUTLS_CERT_UNEXPECTED_OWNER != 0) {
                reason = "The owner is not the expected one";
            } else if (status & GNUTLS_CERT_INVALID_OCSP_STATUS != 0) {
                reason = "The OCSP status response is invalid";
            }
            c_ext.Curl_failf(
                data,
                "server certificate verification failed. CAfile: %s CRLfile: %s (%s)",
                config.CAfile orelse @as([*:0]const u8, "none"),
                config.CRLfile orelse @as([*:0]const u8, "none"),
                reason,
            );
            return CURLE_PEER_FAILED_VERIFICATION;
        } else {
            c_ext.Curl_infof(data, "  server certificate verification FAILED");
        }
    } else {
        c_ext.Curl_infof(data, "  server certificate verification OK");
    }
    _ = peer;
    return CURLE_OK;
}

fn gtls_verify_ocsp_status(
    data: ?*vtls_impl.CurlEasy,
    session: gnutls_session_t,
    chainp: [*]const gnutls_datum_t,
    num_certs: c_uint,
) CURLcode {
    if (comptime !use_gnutls) return CURLE_NOT_BUILT_IN;
    var status_request = gnutls_datum_t{};
    var ocsp_resp: gnutls_ocsp_resp_t = null;
    var status: c_uint = 0;
    var verify_status: c_uint = 0;
    var rc: c_int = 0;

    if (gtls_ext.gnutls_ocsp_status_request_is_checked(session, 0) == 0) {
        rc = gtls_ext.gnutls_ocsp_status_request_get(session, &status_request);
        c_ext.Curl_infof(data, "  server certificate status verification FAILED");

        if (rc == GNUTLS_E_REQUESTED_DATA_NOT_AVAILABLE) {
            c_ext.Curl_failf(data, "No OCSP response received");
            return CURLE_SSL_INVALIDCERTSTATUS;
        }
        if (rc < 0) {
            c_ext.Curl_failf(data, "Invalid OCSP response received");
            return CURLE_SSL_INVALIDCERTSTATUS;
        }

        _ = gtls_ext.gnutls_ocsp_resp_init(&ocsp_resp);
        defer gtls_ext.gnutls_ocsp_resp_deinit(ocsp_resp);

        rc = gtls_ext.gnutls_ocsp_resp_import(ocsp_resp, &status_request);
        if (rc < 0) {
            c_ext.Curl_failf(data, "Invalid OCSP response received");
            return CURLE_SSL_INVALIDCERTSTATUS;
        }

        _ = gtls_ext.gnutls_ocsp_resp_get_single(
            ocsp_resp,
            0,
            null,
            null,
            null,
            null,
            &status,
            null,
            null,
            null,
            null,
        );

        switch (status) {
            GNUTLS_OCSP_CERT_GOOD => {},
            GNUTLS_OCSP_CERT_REVOKED => {
                c_ext.Curl_failf(data, "SSL certificate revocation reason: REVOKED");
                return CURLE_SSL_INVALIDCERTSTATUS;
            },
            else => {
                c_ext.Curl_failf(data, "SSL certificate revocation reason: UNKNOWN");
                return CURLE_SSL_INVALIDCERTSTATUS;
            },
        }

        if (num_certs > 1) {
            var x509_issuer: gnutls_x509_crt_t = null;
            _ = gtls_ext.gnutls_x509_crt_init(&x509_issuer);
            defer gtls_ext.gnutls_x509_crt_deinit(x509_issuer);

            rc = gtls_ext.gnutls_x509_crt_import(x509_issuer, &chainp[1], GNUTLS_X509_FMT_DER);
            if (rc >= 0) {
                rc = gtls_ext.gnutls_ocsp_resp_verify_direct(ocsp_resp, x509_issuer, &verify_status, 0);
                if (rc >= 0 and verify_status == 0) {
                    c_ext.Curl_failf(data, "OCSP response verification failed");
                    return CURLE_SSL_INVALIDCERTSTATUS;
                }
            }
        }

        c_ext.Curl_failf(data, "OCSP status verification failed");
        return CURLE_SSL_INVALIDCERTSTATUS;
    } else {
        c_ext.Curl_infof(data, "  server certificate status verification OK");
    }
    return CURLE_OK;
}

fn gtls_check_issuer(
    cf: *vtls_impl.CurlCfilter,
    data: ?*vtls_impl.CurlEasy,
    x509_cert: gnutls_x509_crt_t,
    issuercert: [*:0]const u8,
) CURLcode {
    if (comptime !use_gnutls) return CURLE_NOT_BUILT_IN;
    const config = vtls_impl.Curl_ssl_cf_get_filter_config(cf) orelse return CURLE_SSL_CONNECT_ERROR;
    var x509_issuer: gnutls_x509_crt_t = null;
    const issuerp = load_file(issuercert);
    defer unload_file(issuerp);

    if (issuerp.data == null) return CURLE_SSL_ISSUER_ERROR;

    _ = gtls_ext.gnutls_x509_crt_init(&x509_issuer);
    defer gtls_ext.gnutls_x509_crt_deinit(x509_issuer);

    var rc = gtls_ext.gnutls_x509_crt_import(x509_issuer, &issuerp, GNUTLS_X509_FMT_PEM);
    if (rc < 0) {
        c_ext.Curl_failf(data, "Issuer cert: invalid PEM in %s (%s)", issuercert, gtls_ext.gnutls_strerror(rc));
        return CURLE_SSL_ISSUER_ERROR;
    }

    rc = gtls_ext.gnutls_x509_crt_check_issuer(x509_cert, x509_issuer);
    if (rc <= 0) {
        c_ext.Curl_failf(
            data,
            "Issuer check against peer certificate failed (%s)",
            gtls_ext.gnutls_strerror(rc),
        );
        return CURLE_SSL_ISSUER_ERROR;
    }

    c_ext.Curl_infof(
        data,
        "  TLS server certificate issuer check OK (Issuer Cert: %s)",
        config.issuercert orelse @as([*:0]const u8, "none"),
    );
    return CURLE_OK;
}

fn gtls_verify_EmptyOrHostname(
    data: ?*vtls_impl.CurlEasy,
    x509_cert: gnutls_x509_crt_t,
    peer: *const vtls_backends.SslPeer,
    verifyhost: bool,
) CURLcode {
    if (comptime !use_gnutls) return CURLE_NOT_BUILT_IN;
    var certbuf: [256]u8 = @splat(0);
    var size: usize = certbuf.len;

    const verify_name = peerHostname(peer);
    const rc = gtls_ext.gnutls_x509_crt_check_hostname(x509_cert, verify_name);
    if (rc == 0) {
        if (verifyhost) {
            c_ext.Curl_failf(
                data,
                "SSL: certificate subject name (%s) does not match target host name '%s'",
                @as([*:0]const u8, @ptrCast(&certbuf)),
                peerDispname(peer),
            );
            return CURLE_PEER_FAILED_VERIFICATION;
        } else {
            c_ext.Curl_infof(
                data,
                "  common name: WARNING couldn't obtain (GnuTLS: %s)",
                gtls_ext.gnutls_strerror(rc),
            );
        }
    } else {
        size = certbuf.len;
        if (gtls_ext.gnutls_x509_crt_get_dn_by_oid(
            x509_cert,
            GNUTLS_OID_X520_COMMON_NAME,
            0,
            0,
            &certbuf,
            &size,
        ) == 0) {
            const cn_len = @min(size, certbuf.len);
            const san_slice = certbuf[0..cn_len];
            if (std.mem.indexOfScalar(u8, san_slice, 0) != null) {
                if (verifyhost) {
                    c_ext.Curl_failf(
                        data,
                        "SSL: certificate subject name contains embedded NUL for target host name '%s'",
                        peerDispname(peer),
                    );
                    return CURLE_PEER_FAILED_VERIFICATION;
                }
            }
            if (size < certbuf.len) certbuf[size] = 0 else certbuf[certbuf.len - 1] = 0;
            c_ext.Curl_infof(
                data,
                "  common name: %s (matched)",
                @as([*:0]const u8, @ptrCast(&certbuf)),
            );
        } else {
            c_ext.Curl_infof(data, "  common name: <none> (SAN matched)");
        }
    }
    return CURLE_OK;
}

pub fn gtlsVerifyHostSlice(san_bytes_opt: ?[*]const u8, len: usize, hostname: []const u8) bool {
    return vtls_scache_asn1.verifyX509SanOrCnSlice(san_bytes_opt, len, hostname);
}

pub fn freeGtlsBackendData(ptr: ?*GtlsSslBackendData) void {
    mem.freeSized(ptr, @sizeOf(GtlsSslBackendData));
}

fn gtls_infof_cert(
    data: ?*vtls_impl.CurlEasy,
    cert: gnutls_x509_crt_t,
) CURLcode {
    if (comptime !use_gnutls) return CURLE_NOT_BUILT_IN;
    const d = data orelse return CURLE_OK;
    if (!c_ext.Curl_trc_is_verbose_fn(d)) return CURLE_OK;

    var certbuf: [256]u8 = @splat(0);
    var size: usize = certbuf.len;
    var algo: c_int = 0;
    var bits: c_uint = 0;

    var rc = gtls_ext.gnutls_x509_crt_get_dn(cert, &certbuf, &size);
    if (rc < 0) {
        c_ext.Curl_infof(d, "error fetching peer cert subject (%s)", gtls_ext.gnutls_strerror(rc));
        return CURLE_SSL_CONNECT_ERROR;
    }
    if (size < certbuf.len) certbuf[size] = 0 else certbuf[certbuf.len - 1] = 0;
    c_ext.Curl_infof(d, "  subject: %s", @as([*:0]const u8, @ptrCast(&certbuf)));

    const certclock_start = gtls_ext.gnutls_x509_crt_get_activation_time(cert);
    showtime(d, "start date", certclock_start);

    const certclock_exp = gtls_ext.gnutls_x509_crt_get_expiration_time(cert);
    showtime(d, "expire date", certclock_exp);

    size = certbuf.len;
    rc = gtls_ext.gnutls_x509_crt_get_issuer_dn(cert, &certbuf, &size);
    if (rc < 0) {
        c_ext.Curl_infof(d, "error fetching peer cert issuer (%s)", gtls_ext.gnutls_strerror(rc));
    } else {
        if (size < certbuf.len) certbuf[size] = 0 else certbuf[certbuf.len - 1] = 0;
        c_ext.Curl_infof(d, "  issuer: %s", @as([*:0]const u8, @ptrCast(&certbuf)));
    }

    const version = gtls_ext.gnutls_x509_crt_get_version(cert);
    c_ext.Curl_infof(d, "  certificate version: #%d", version);

    algo = gtls_ext.gnutls_x509_crt_get_pk_algorithm(cert, &bits);
    c_ext.Curl_infof(
        d,
        "  certificate public key: %s (%u bits)",
        if (algo >= 0) (gtls_ext.gnutls_pk_algorithm_get_name(@intCast(algo)) orelse "unknown") else "unknown",
        bits,
    );

    return CURLE_OK;
}

pub fn Curl_gtls_report_handshake(
    data: ?*vtls_impl.CurlEasy,
    gctx: *GtlsSslBackendData,
) void {
    if (comptime !use_gnutls) return;
    const session = gctx.session orelse return;
    const version = gtls_ext.gnutls_protocol_get_version(session);
    const proto_name = gtls_ext.gnutls_protocol_get_name(version) orelse "unknown";
    const kx = gtls_ext.gnutls_kx_get(session);
    const cipher = gtls_ext.gnutls_cipher_get(session);
    const mac = gtls_ext.gnutls_mac_get(session);
    const suite = gtls_ext.gnutls_cipher_suite_get_name(kx, cipher, mac);
    if (suite) |s| {
        c_ext.Curl_infof(data, "SSL connection using %s / %s", proto_name, s);
    } else {
        const kx_name = gtls_ext.gnutls_kx_get_name(kx) orelse "unknown";
        const cipher_name = gtls_ext.gnutls_cipher_get_name(cipher) orelse "unknown";
        const mac_name = gtls_ext.gnutls_mac_get_name(mac) orelse "unknown";
        c_ext.Curl_infof(
            data,
            "SSL connection using %s / %s-%s-%s",
            proto_name,
            kx_name,
            cipher_name,
            mac_name,
        );
    }
}

pub fn Curl_gtls_verifyserver(
    cf: *vtls_impl.CurlCfilter,
    data: ?*vtls_impl.CurlEasy,
    session: gnutls_session_t,
    config: *vtls_backends.SslFilterConfig,
    ssl_config: ?*vtls_backends.SslEasyConfig,
    peer: *const vtls_backends.SslPeer,
    pinned_key: ?[*:0]const u8,
) CURLcode {
    if (comptime !use_gnutls) return CURLE_NOT_BUILT_IN;
    var cert_list_size: c_uint = 0;
    var x509_cert: gnutls_x509_crt_t = null;
    var result: CURLcode = CURLE_OK;
    const is_proxy = vtls_impl.Curl_ssl_cf_is_proxy(cf);
    const username = c_ext.Curl_vtls_acc_ssl_username(data, is_proxy);

    const chainp_opt = gtls_ext.gnutls_certificate_get_peers(session, &cert_list_size);
    if (chainp_opt == null) {
        if (config.verifypeer() or config.verifyhost() or config.issuercert != null) {
            if (username != null and
                !config.verifypeer() and
                gtls_ext.gnutls_cipher_get(session) != 0)
            {
                // no peer cert, but auth is ok if we have SRP user and cipher and no verify peer
            } else {
                c_ext.Curl_failf(data, "failed to get server cert");
                if (ssl_config) |sc| sc.certverifyresult = GNUTLS_E_NO_CERTIFICATE_FOUND;
                return CURLE_PEER_FAILED_VERIFICATION;
            }
        }
        c_ext.Curl_infof(data, "  common name: WARNING couldn't obtain");
    }

    const chainp = chainp_opt orelse {
        return CURLE_OK;
    };

    if (data != null and c_ext.Curl_vtls_acc_ssl_certinfo(data) and cert_list_size > 0) {
        result = vtls_impl.Curl_ssl_init_certinfo(data, @intCast(cert_list_size));
        if (result != CURLE_OK) return result;

        var i: c_uint = 0;
        while (i < cert_list_size) : (i += 1) {
            if (chainp[i].data) |beg| {
                const end = beg + chainp[i].size;
                result = vtls_scache_asn1.Curl_extract_certinfo_zig(
                    data,
                    @intCast(i),
                    beg,
                    end,
                    true,
                    @ptrCast(&vtls_impl.Curl_ssl_push_certinfo_len),
                );
                if (result != CURLE_OK) return result;
            }
        }
    }

    if (config.verifypeer()) {
        result = gtls_verify_cert(cf, data, session, peer);
        if (result != CURLE_OK) return result;
    } else {
        c_ext.Curl_infof(data, "  server certificate verification SKIPPED");
    }

    var rc = gtls_ext.gnutls_x509_crt_init(&x509_cert);
    if (rc < 0 or x509_cert == null) {
        c_ext.Curl_failf(data, "error initializing gnutls_x509_crt_t");
        return CURLE_OUT_OF_MEMORY;
    }
    defer gtls_ext.gnutls_x509_crt_deinit(x509_cert);

    rc = gtls_ext.gnutls_x509_crt_import(x509_cert, &chainp[0], GNUTLS_X509_FMT_DER);
    if (rc < 0) {
        c_ext.Curl_failf(data, "error parsing server's certificate (%s)", gtls_ext.gnutls_strerror(rc));
        return CURLE_SSL_CONNECT_ERROR;
    }

    const now_sec: isize = gtls_ext.time(null);
    const exp_time = gtls_ext.gnutls_x509_crt_get_expiration_time(x509_cert);
    if (exp_time == -1) {
        if (config.verifypeer()) {
            c_ext.Curl_failf(data, "server cert expiration date verify failed");
            if (ssl_config) |sc| sc.certverifyresult = @intCast(GNUTLS_CERT_EXPIRED);
            return CURLE_SSL_CONNECT_ERROR;
        } else {
            c_ext.Curl_infof(data, "  SSL certificate expiration date verify FAILED");
        }
    } else if (exp_time < now_sec) {
        if (config.verifypeer()) {
            c_ext.Curl_failf(data, "server certificate expiration date has passed.");
            if (ssl_config) |sc| sc.certverifyresult = @intCast(GNUTLS_CERT_EXPIRED);
            return CURLE_PEER_FAILED_VERIFICATION;
        } else {
            c_ext.Curl_infof(data, "  SSL certificate expiration date FAILED");
        }
    } else {
        c_ext.Curl_infof(data, "  SSL certificate expiration date OK");
    }

    const act_time = gtls_ext.gnutls_x509_crt_get_activation_time(x509_cert);
    if (act_time == -1) {
        if (config.verifypeer()) {
            c_ext.Curl_failf(data, "server cert activation date verify failed");
            if (ssl_config) |sc| sc.certverifyresult = @intCast(GNUTLS_CERT_NOT_ACTIVATED);
            return CURLE_SSL_CONNECT_ERROR;
        } else {
            c_ext.Curl_infof(data, "  SSL certificate activation date verify FAILED");
        }
    } else if (act_time > now_sec) {
        if (config.verifypeer()) {
            c_ext.Curl_failf(data, "server certificate not activated yet.");
            if (ssl_config) |sc| sc.certverifyresult = @intCast(GNUTLS_CERT_NOT_ACTIVATED);
            return CURLE_PEER_FAILED_VERIFICATION;
        } else {
            c_ext.Curl_infof(data, "  SSL certificate activation date FAILED");
        }
    } else {
        c_ext.Curl_infof(data, "  SSL certificate activation date OK");
    }

    if (config.verifystatus()) {
        result = gtls_verify_ocsp_status(data, session, chainp, cert_list_size);
        if (result != CURLE_OK) return result;
    } else {
        c_ext.Curl_infof(data, "  server certificate status verification SKIPPED");
    }

    const issuercert: ?[*:0]const u8 = if (config.issuercert) |ic| ic else c_ext.Curl_vtls_acc_ssl_issuercert(data, is_proxy);
    if (issuercert) |ic| {
        result = gtls_check_issuer(cf, data, x509_cert, ic);
        if (result != CURLE_OK) return result;
    }

    if (config.verifyhost()) {
        result = gtls_verify_EmptyOrHostname(data, x509_cert, peer, config.verifyhost());
        if (result != CURLE_OK) return result;
    } else {
        c_ext.Curl_infof(data, "  common name: WARNING verification of host name skipped");
    }

    if (pinned_key) |pk| {
        result = pkp_pin_peer_pubkey(data, x509_cert, pk);
        if (result != CURLE_OK) {
            c_ext.Curl_failf(data, "SSL: public key does not match pinned public key");
            return result;
        }
    }

    return gtls_infof_cert(data, x509_cert);
}

pub fn gtls_verifyserver(
    cf: *vtls_impl.CurlCfilter,
    data: ?*vtls_impl.CurlEasy,
    session: gnutls_session_t,
) CURLcode {
    const connssl = cfCtx(cf) orelse return CURLE_SSL_CONNECT_ERROR;
    const conn_config = vtls_impl.Curl_ssl_cf_get_filter_config(cf) orelse return CURLE_SSL_CONNECT_ERROR;
    const ssl_config = vtls_impl.Curl_ssl_cf_get_easy_config(cf, data);
    const is_proxy = vtls_impl.Curl_ssl_cf_is_proxy(cf);
    const pinned_key: ?[*:0]const u8 = if (conn_config.pinned_key) |pk|
        pk
    else
        c_ext.Curl_vtls_acc_pinned_pubkey(data, is_proxy);

    return Curl_gtls_verifyserver(
        cf,
        data,
        session,
        conn_config,
        ssl_config,
        &connssl.peer,
        pinned_key,
    );
}

fn cf_gtls_send_earlydata(
    cf: *vtls_impl.CurlCfilter,
    data: ?*vtls_impl.CurlEasy,
) CURLcode {
    if (comptime !use_gnutls) return CURLE_NOT_BUILT_IN;
    const connssl = cfCtx(cf) orelse return CURLE_SSL_CONNECT_ERROR;
    const backend: *GtlsSslBackendData = @ptrCast(@alignCast(connssl.backend orelse return CURLE_SSL_CONNECT_ERROR));
    var result: CURLcode = CURLE_OK;
    var pbuf: ?[*]const u8 = null;
    var nsend: usize = 0;

    connssl.earlydata_state = ssl_earlydata_sending;
    while (io_buffers.Curl_bufq_peek(&connssl.earlydata, &pbuf, &nsend)) {
        const n = gtls_ext.gnutls_record_send_early_data(backend.session, pbuf, nsend);
        if (n < 0) {
            if (n == GNUTLS_E_AGAIN or n == GNUTLS_E_INTERRUPTED) {
                result = CURLE_AGAIN;
                break;
            }
            c_ext.Curl_infof(
                data,
                "SSL: gnutls_record_send_early_data() failed: %s",
                gtls_ext.gnutls_strerror(@intCast(n)),
            );
            result = CURLE_SEND_ERROR;
            break;
        }
        if (n == 0) break;
        const written: usize = @intCast(n);
        connssl.earlydata_skip += written;
        io_buffers.Curl_bufq_skip(&connssl.earlydata, written);
    }

    if (result == CURLE_OK and io_buffers.Curl_bufq_is_empty(&connssl.earlydata)) {
        connssl.earlydata_state = ssl_earlydata_sent;
        c_ext.Curl_infof(data, "SSL: sent %zu bytes of early data", connssl.earlydata_skip);
    }
    return result;
}

pub fn cf_gtls_handshake(
    cf: *vtls_impl.CurlCfilter,
    data: ?*vtls_impl.CurlEasy,
) CURLcode {
    if (comptime !use_gnutls) return CURLE_NOT_BUILT_IN;
    const connssl = cfCtx(cf) orelse return CURLE_SSL_CONNECT_ERROR;
    const backend: *GtlsSslBackendData = @ptrCast(@alignCast(connssl.backend orelse return CURLE_SSL_CONNECT_ERROR));
    const session = backend.session;

    connssl.io_need = CURL_SSL_IO_NEED_NONE;

    if (connssl.earlydata_state == ssl_earlydata_await or
        connssl.earlydata_state == ssl_earlydata_sending)
    {
        const ed_res = cf_gtls_send_earlydata(cf, data);
        if (ed_res != CURLE_OK) {
            if (ed_res == CURLE_AGAIN) {
                connssl.io_need = if (gtls_ext.gnutls_record_get_direction(session) != 0)
                    CURL_SSL_IO_NEED_SEND
                else
                    CURL_SSL_IO_NEED_RECV;
            }
            return ed_res;
        }
    }

    const rc = gtls_ext.gnutls_handshake(session);

    if (!backend.shared_creds.?.trust_setup) {
        const result = Curl_gtls_client_trust_setup(cf, data, backend);
        if (result != CURLE_OK) return result;
    }

    if ((rc == GNUTLS_E_AGAIN) or (rc == GNUTLS_E_INTERRUPTED)) {
        connssl.io_need = if (gtls_ext.gnutls_record_get_direction(session) != 0)
            CURL_SSL_IO_NEED_SEND
        else
            CURL_SSL_IO_NEED_RECV;
        return CURLE_AGAIN;
    } else if ((rc < 0) and (gtls_ext.gnutls_error_is_fatal(rc) == 0)) {
        var strerr: ?[*:0]const u8 = null;
        if (rc == GNUTLS_E_WARNING_ALERT_RECEIVED) {
            const alert = gtls_ext.gnutls_alert_get(session);
            strerr = gtls_ext.gnutls_alert_get_name(alert);
        }
        if (strerr == null) {
            strerr = gtls_ext.gnutls_strerror(rc);
        }
        c_ext.Curl_infof(data, "GnuTLS recv warning (-%d): %s", -rc, strerr.?);
        return CURLE_AGAIN;
    } else if (rc < 0) {
        var strerr: ?[*:0]const u8 = null;
        if (rc == GNUTLS_E_FATAL_ALERT_RECEIVED) {
            const alert = gtls_ext.gnutls_alert_get(session);
            strerr = gtls_ext.gnutls_alert_get_name(alert);
        }
        if (strerr == null) {
            strerr = gtls_ext.gnutls_strerror(rc);
        }
        c_ext.Curl_failf(data, "GnuTLS recv error (%d): %s", rc, strerr.?);
        return if (backend.io_result != CURLE_OK) backend.io_result else CURLE_SSL_CONNECT_ERROR;
    }

    return CURLE_OK;
}

pub const gtls_handshake = cf_gtls_handshake;

fn gtls_connect_common(
    cf: *vtls_impl.CurlCfilter,
    data: *vtls_impl.CurlEasy,
    done: *bool,
) CURLcode {
    if (comptime !use_gnutls) return CURLE_NOT_BUILT_IN;
    const connssl = cfCtx(cf) orelse return CURLE_SSL_CONNECT_ERROR;
    const backend: *GtlsSslBackendData = @ptrCast(@alignCast(connssl.backend orelse return CURLE_SSL_CONNECT_ERROR));
    var result: CURLcode = CURLE_OK;

    if (connssl.state == ssl_connection_complete) {
        done.* = true;
        return CURLE_OK;
    }

    const saved_call_data = connssl.call_data;
    connssl.call_data = data;
    defer connssl.call_data = saved_call_data;

    if (connssl.connecting_state == ssl_connect_1) {
        result = gtls_connect_step1(cf, data);
        if (result != CURLE_OK) return result;
        connssl.connecting_state = ssl_connect_2;
    }

    if (connssl.connecting_state == ssl_connect_2) {
        result = cf_gtls_handshake(cf, data);
        if (result == CURLE_AGAIN) {
            done.* = false;
            return CURLE_OK;
        } else if (result != CURLE_OK) {
            return result;
        }
        connssl.connecting_state = ssl_connect_3;
    }

    if (connssl.connecting_state == ssl_connect_3) {
        const session = backend.session;
        var proto = gnutls_datum_t{};

        Curl_gtls_report_handshake(data, backend);

        result = gtls_verifyserver(cf, data, session);
        if (result != CURLE_OK) return result;

        connssl.state = ssl_connection_complete;

        if (connssl.alpn != null) {
            const rc = gtls_ext.gnutls_alpn_get_selected_protocol(session, &proto);
            if (rc == 0) {
                result = vtls_impl.Curl_alpn_set_negotiated(cf, data, connssl, proto.data, proto.size);
            } else {
                result = vtls_impl.Curl_alpn_set_negotiated(cf, data, connssl, null, 0);
            }
            if (result != CURLE_OK) return result;
        }

        if (gtls_ext.gnutls_protocol_get_version(session) < GNUTLS_TLS1_3) {
            result = cf_gtls_update_session_id(cf, data, session);
            if (result != CURLE_OK) return result;
        }

        if (connssl.earlydata_state > ssl_earlydata_none) {
            connssl.earlydata_state = if ((gtls_ext.gnutls_session_get_flags(session) & GNUTLS_SFLAGS_EARLY_DATA) != 0)
                ssl_earlydata_accepted
            else
                ssl_earlydata_rejected;
        }

        connssl.connecting_state = ssl_connect_done;
    }

    done.* = (connssl.connecting_state == ssl_connect_done);
    return CURLE_OK;
}

fn gtlsConnect(
    cf: *vtls_impl.CurlCfilter,
    data: ?*vtls_impl.CurlEasy,
    done: *bool,
) callconv(.c) CURLcode {
    if (comptime !use_gnutls) {
        done.* = false;
        return CURLE_NOT_BUILT_IN;
    }
    const d = data orelse {
        done.* = false;
        return CURLE_BAD_FUNCTION_ARGUMENT;
    };
    return gtls_connect_common(cf, d, done);
}

fn gtlsSend(
    cf: *vtls_impl.CurlCfilter,
    data: ?*vtls_impl.CurlEasy,
    mem_ptr: ?*const anyopaque,
    len: usize,
    pnwritten: *usize,
) callconv(.c) CURLcode {
    if (comptime !use_gnutls) {
        pnwritten.* = 0;
        return CURLE_NOT_BUILT_IN;
    }
    const connssl = cfCtx(cf) orelse return CURLE_SEND_ERROR;
    const backend: *GtlsSslBackendData = @ptrCast(@alignCast(connssl.backend orelse return CURLE_SEND_ERROR));
    var remain = len;
    var buf: [*]const u8 = if (mem_ptr) |p| @ptrCast(p) else return CURLE_BAD_FUNCTION_ARGUMENT;
    var result: CURLcode = CURLE_OK;

    const saved_call_data = connssl.call_data;
    connssl.call_data = data;
    defer connssl.call_data = saved_call_data;

    pnwritten.* = 0;
    while (remain > 0) {
        connssl.io_need = CURL_SSL_IO_NEED_NONE;
        backend.io_result = CURLE_OK;
        const rc = gtls_ext.gnutls_record_send(backend.session, buf, remain);

        if (rc < 0) {
            if (rc == GNUTLS_E_AGAIN or rc == GNUTLS_E_INTERRUPTED) {
                connssl.io_need = CURL_SSL_IO_NEED_SEND;
                result = if (pnwritten.* > 0) CURLE_OK else CURLE_AGAIN;
                break;
            }
            result = if (backend.io_result == CURLE_AGAIN)
                CURLE_AGAIN
            else if (backend.io_result != CURLE_OK)
                backend.io_result
            else
                CURLE_SEND_ERROR;
            c_ext.Curl_infof(
                data,
                "GnuTLS send error (%zd): %s",
                rc,
                gtls_ext.gnutls_strerror(@intCast(rc)),
            );
            break;
        }
        const sent: usize = @intCast(rc);
        pnwritten.* += sent;
        buf += sent;
        remain -= sent;
    }
    return result;
}

fn gtlsClose(cf: *vtls_impl.CurlCfilter, data: ?*vtls_impl.CurlEasy) callconv(.c) void {
    _ = data;
    if (comptime !use_gnutls) return;
    const connssl = cfCtx(cf) orelse return;
    const backend: *GtlsSslBackendData = @ptrCast(@alignCast(connssl.backend orelse return));

    if (backend.session != null) {
        gtls_ext.gnutls_deinit(backend.session);
        backend.session = null;
    }
    Curl_gtls_shared_creds_free(&backend.shared_creds);
    if (backend.srp_client_cred != null) {
        gtls_ext.gnutls_srp_free_client_credentials(backend.srp_client_cred);
        backend.srp_client_cred = null;
    }
}

fn gtlsShutdown(
    cf: *vtls_impl.CurlCfilter,
    data: ?*vtls_impl.CurlEasy,
    send_shutdown: bool,
    done: *bool,
) callconv(.c) CURLcode {
    if (comptime !use_gnutls) {
        done.* = true;
        return CURLE_OK;
    }
    const connssl = cfCtx(cf) orelse {
        done.* = true;
        return CURLE_OK;
    };
    const backend: *GtlsSslBackendData = @ptrCast(@alignCast(connssl.backend orelse {
        done.* = true;
        return CURLE_OK;
    }));
    var buf: [1024]u8 = undefined;
    var result: CURLcode = CURLE_OK;

    if (cf.isShutdown() or backend.session == null) {
        done.* = true;
        return CURLE_OK;
    }

    connssl.io_need = CURL_SSL_IO_NEED_NONE;
    done.* = false;

    const saved_call_data = connssl.call_data;
    connssl.call_data = data;
    defer connssl.call_data = saved_call_data;

    if (!backend.sent_shutdown) {
        backend.sent_shutdown = true;
        if (send_shutdown) {
            const retval = gtls_ext.gnutls_bye(backend.session, GNUTLS_SHUT_RDWR);
            if (retval == GNUTLS_E_AGAIN or retval == GNUTLS_E_INTERRUPTED) {
                c_ext.Curl_infof(data, "SSL: gnutls_bye() AGAIN");
                connssl.io_need = if (gtls_ext.gnutls_record_get_direction(backend.session) != 0)
                    CURL_SSL_IO_NEED_SEND
                else
                    CURL_SSL_IO_NEED_RECV;
                backend.sent_shutdown = false;
                return CURLE_OK;
            } else if (retval != GNUTLS_E_SUCCESS) {
                c_ext.Curl_infof(
                    data,
                    "SSL: gnutls_bye() returned %d (%s)",
                    retval,
                    gtls_ext.gnutls_strerror(retval),
                );
                result = CURLE_SSL_CONNECT_ERROR;
            }
        }
    }

    if (result == CURLE_OK) {
        var i: usize = 0;
        while (i < 10) : (i += 1) {
            const nread = gtls_ext.gnutls_record_recv(backend.session, &buf, buf.len);
            if (nread <= 0) {
                if (nread == 0) {
                    done.* = true;
                } else if (nread == GNUTLS_E_AGAIN or nread == GNUTLS_E_INTERRUPTED) {
                    connssl.io_need = if (gtls_ext.gnutls_record_get_direction(backend.session) != 0)
                        CURL_SSL_IO_NEED_SEND
                    else
                        CURL_SSL_IO_NEED_RECV;
                } else {
                    c_ext.Curl_infof(
                        data,
                        "SSL: gnutls_record_recv() after bye returned %zd (%s)",
                        nread,
                        gtls_ext.gnutls_strerror(@intCast(nread)),
                    );
                    result = CURLE_SSL_CONNECT_ERROR;
                }
                break;
            }
        }
    }

    cf.setShutdown(result != CURLE_OK or done.*);
    return result;
}

fn gtlsRecv(
    cf: *vtls_impl.CurlCfilter,
    data: ?*vtls_impl.CurlEasy,
    buf: [*]u8,
    buffersize: usize,
    pnread: *usize,
) callconv(.c) CURLcode {
    if (comptime !use_gnutls) {
        pnread.* = 0;
        return CURLE_NOT_BUILT_IN;
    }
    const connssl = cfCtx(cf) orelse return CURLE_RECV_ERROR;
    const backend: *GtlsSslBackendData = @ptrCast(@alignCast(connssl.backend orelse return CURLE_RECV_ERROR));

    const saved_call_data = connssl.call_data;
    connssl.call_data = data;
    defer connssl.call_data = saved_call_data;

    pnread.* = 0;
    connssl.io_need = CURL_SSL_IO_NEED_NONE;
    backend.io_result = CURLE_OK;
    const ret = gtls_ext.gnutls_record_recv(backend.session, buf, buffersize);

    if ((ret == GNUTLS_E_AGAIN) or (ret == GNUTLS_E_INTERRUPTED)) {
        connssl.io_need = if (gtls_ext.gnutls_record_get_direction(backend.session) != 0)
            CURL_SSL_IO_NEED_SEND
        else
            CURL_SSL_IO_NEED_RECV;
        return CURLE_AGAIN;
    }

    if (ret == GNUTLS_E_REHANDSHAKE) {
        const result = cf_gtls_handshake(cf, data);
        if (result != CURLE_OK) return result;
        return CURLE_AGAIN;
    }

    if (ret < 0) {
        c_ext.Curl_failf(
            data,
            "GnuTLS recv error (%d): %s",
            @as(c_int, @intCast(ret)),
            gtls_ext.gnutls_strerror(@intCast(ret)),
        );
        return if (backend.io_result != CURLE_OK) backend.io_result else CURLE_RECV_ERROR;
    }

    pnread.* = @intCast(ret);
    return CURLE_OK;
}

fn gtlsVersion(buffer: [*]u8, size: usize) callconv(.c) usize {
    if (comptime use_gnutls) {
        const ver = gtls_ext.gnutls_check_version(null) orelse "";
        const n = c_ext.curl_msnprintf(buffer, size, "GnuTLS/%s", ver);
        return if (n > 0) @intCast(n) else 0;
    }
    return 0;
}

fn gtlsSha256sum(
    input: [*]const u8,
    inputlen: usize,
    sha256sum: [*]u8,
    sha256len: usize,
) callconv(.c) CURLcode {
    if (comptime use_gnutls) {
        var ctx: Sha256Ctx = std.mem.zeroes(Sha256Ctx);
        gtls_ext.nettle_sha256_init(&ctx);
        if (inputlen > 0) {
            gtls_ext.nettle_sha256_update(&ctx, inputlen, input);
        }
        gtls_ext.nettle_sha256_digest(&ctx, sha256len, sha256sum);
        return CURLE_OK;
    }
    return CURLE_NOT_BUILT_IN;
}

fn gtlsCertStatusRequest() callconv(.c) bool {
    return true;
}

fn gtlsGetInternals(connssl: *vtls_backends.SslConnectData, info: c_uint) callconv(.c) ?*anyopaque {
    _ = info;
    const backend: *GtlsSslBackendData = @ptrCast(@alignCast(connssl.backend orelse return null));
    return backend.session;
}

fn gtlsDataPending(cf: *vtls_impl.CurlCfilter, data: ?*const vtls_impl.CurlEasy) callconv(.c) bool {
    _ = data;
    if (comptime !use_gnutls) return false;
    const connssl = cfCtx(cf) orelse return false;
    const backend: *GtlsSslBackendData = @ptrCast(@alignCast(connssl.backend orelse return false));
    return backend.session != null and gtls_ext.gnutls_record_check_pending(backend.session) != 0;
}

fn gtlsRandom(
    data: ?*vtls_impl.CurlEasy,
    entropy: [*]u8,
    length: usize,
) callconv(.c) CURLcode {
    _ = data;
    if (comptime use_gnutls) {
        if (!gtls_inited) {
            _ = gtlsInit();
            gtls_inited = true;
        }
        const rc = gtls_ext.gnutls_rnd(1, entropy, length);
        return if (rc == GNUTLS_E_SUCCESS) CURLE_OK else CURLE_FAILED_INIT;
    }
    return CURLE_NOT_BUILT_IN;
}

fn gtlsGetChannelBinding(
    data: ?*vtls_impl.CurlEasy,
    sockindex: i8,
    binding: *containers.dynbuf,
) callconv(.c) CURLcode {
    if (comptime !use_gnutls) return CURLE_NOT_BUILT_IN;
    const conn = c_ext.Curl_vtls_acc_data_conn(data) orelse return CURLE_OK;
    var cf = c_ext.Curl_vtls_acc_conn_cfilter(conn, sockindex);
    while (cf) |cur| : (cf = cur.next) {
        if (cur.cft == &vtls_impl.Curl_cft_ssl or cur.cft == &vtls_impl.Curl_cft_ssl_proxy) {
            const connssl = cfCtx(cur) orelse return CURLE_OK;
            const backend: *GtlsSslBackendData = @ptrCast(@alignCast(connssl.backend orelse return CURLE_OK));
            if (backend.session != null) {
                var cb = gnutls_datum_t{};
                var rc = gtls_ext.gnutls_session_channel_binding(
                    backend.session,
                    GNUTLS_CB_TLS_EXPORTER,
                    &cb,
                );
                if (rc == GNUTLS_E_REQUESTED_DATA_NOT_AVAILABLE) {
                    rc = gtls_ext.gnutls_session_channel_binding(
                        backend.session,
                        GNUTLS_CB_TLS_SERVER_END_POINT,
                        &cb,
                    );
                }
                if (rc < 0) return CURLE_SSL_CONNECT_ERROR;
                if (cb.data != null and cb.size > 0) {
                    defer gnutlsFreePtr(cb.data);
                    return containers.curlx_dyn_addn(binding, cb.data.?, cb.size);
                }
            }
            break;
        }
    }
    return CURLE_OK;
}

pub const Curl_ssl_gnutls = vtls_impl.CurlSsl{
    .info = .{
        .id = vtls_impl.CURLSSLBACKEND_GNUTLS,
        .name = "gnutls",
    },
    .supports = SSLSUPP_CA_PATH |
        SSLSUPP_CERTINFO |
        SSLSUPP_PINNEDPUBKEY |
        SSLSUPP_HTTPS_PROXY |
        SSLSUPP_CAINFO_BLOB |
        SSLSUPP_EARLYDATA |
        SSLSUPP_CIPHER_LIST |
        SSLSUPP_CA_CACHE |
        SSLSUPP_ISSUERCERT |
        SSLSUPP_CRLFILE,
    .sizeof_ssl_backend_data = @sizeOf(GtlsSslBackendData),
    .init = gtlsInit,
    .cleanup = gtlsCleanup,
    .version = gtlsVersion,
    .shut_down = gtlsShutdown,
    .data_pending = gtlsDataPending,
    .random = gtlsRandom,
    .cert_status_request = gtlsCertStatusRequest,
    .do_connect = gtlsConnect,
    .adjust_pollset = vtls_impl.Curl_ssl_adjust_pollset,
    .get_internals = gtlsGetInternals,
    .close = gtlsClose,
    .close_all = null,
    .engines_list = null,
    .sha256sum = gtlsSha256sum,
    .recv_plain = gtlsRecv,
    .send_plain = gtlsSend,
    .get_channel_binding = gtlsGetChannelBinding,
};

comptime {
    if (use_gnutls) {
        @export(&Curl_ssl_gnutls, .{ .name = "Curl_ssl_gnutls" });
    }
}

test "gnutls loopback TLS handshake, ALPN, HTTPS GET, CA verification, and pinned pubkey" {
    if (comptime !use_gnutls) return;

    const test_ca_cert_pem: [:0]const u8 =
        \\-----BEGIN CERTIFICATE-----
        \\MIIBmjCCAUGgAwIBAgIUfQZTbIpX8IFrj+WYZ+0OmKXNqk4wCgYIKoZIzj0EAwIw
        \\GzEZMBcGA1UEAwwQY3VybC16aWctdGVzdC1jYTAeFw0yMDAxMDEwMDAwMDBaFw00
        \\OTEyMzEyMzU5NTlaMBsxGTAXBgNVBAMMEGN1cmwtemlnLXRlc3QtY2EwWTATBgcq
        \\hkjOPQIBBggqhkjOPQMBBwNCAAQoTpIGrJFs0dVUkOluncBTMmEbofWLFURcdyou
        \\sb+FzrsceHhEEl4h55xtljCG6XNC8cpTq0bccAdq0HGuUmsjo2MwYTAdBgNVHQ4E
        \\FgQUUp9GU1TG6cFp+dqw5YaKTmZlcGYwHwYDVR0jBBgwFoAUUp9GU1TG6cFp+dqw
        \\5YaKTmZlcGYwDwYDVR0TAQH/BAUwAwEB/zAOBgNVHQ8BAf8EBAMCAQYwCgYIKoZI
        \\zj0EAwIDRwAwRAIgOCcUaHTn5/FKJKRznvWWZ+IXT0mFBVLaSyBF6ZWJhDoCICuQ
        \\tCNyaA71GDSYE4P7BYPmYgtZvbiLrZWmtUwQTaPW
        \\-----END CERTIFICATE-----
        \\
    ;

    const test_server_cert_pem: [:0]const u8 =
        \\-----BEGIN CERTIFICATE-----
        \\MIIBvjCCAWSgAwIBAgIUDGM3QqxgD+aktmk/PZC3V+UmcRMwCgYIKoZIzj0EAwIw
        \\GzEZMBcGA1UEAwwQY3VybC16aWctdGVzdC1jYTAeFw0yMDAxMDEwMDAwMDBaFw00
        \\OTEyMzEyMzU5NTlaMBQxEjAQBgNVBAMMCWxvY2FsaG9zdDBZMBMGByqGSM49AgEG
        \\CCqGSM49AwEHA0IABH2/lUFJsfqzBJujZlnCUhST3sZ6pgEYWr2xUtHfgufM9mP5
        \\i9zf0FS2D8pY8U1suMaK5OGoRqF1uNwD8LjbCbyjgYwwgYkwDAYDVR0TAQH/BAIw
        \\ADAOBgNVHQ8BAf8EBAMCBaAwEwYDVR0lBAwwCgYIKwYBBQUHAwEwFAYDVR0RBA0w
        \\C4IJbG9jYWxob3N0MB0GA1UdDgQWBBQL/sY8G/6M1bRs9oCzusjRxAdNWjAfBgNV
        \\HSMEGDAWgBRSn0ZTVMbpwWn52rDlhopOZmVwZjAKBggqhkjOPQQDAgNIADBFAiBp
        \\ZjwF2DyqZdSBmM/3+z7UqjFuWf6iIqSi8Yy1xPsySAIhAMPz4B3Wi/NRC8OkffDo
        \\rAa4SYs5WWQ4DwgS6XWjGlcz
        \\-----END CERTIFICATE-----
        \\
    ;

    const test_server_key_pem: [:0]const u8 =
        \\-----BEGIN EC PRIVATE KEY-----
        \\MHcCAQEEIOax4UqvKuoDsEOgbNodLAuWNZExlnybWGMLt9HPI72eoAoGCCqGSM49
        \\AwEHoUQDQgAEfb+VQUmx+rMEm6NmWcJSFJPexnqmARhavbFS0d+C58z2Y/mL3N/Q
        \\VLYPyljxTWy4xork4ahGoXW43APwuNsJvA==
        \\-----END EC PRIVATE KEY-----
        \\
    ;

    const test_untrusted_ca_cert_pem: [:0]const u8 =
        \\-----BEGIN CERTIFICATE-----
        \\MIIBpDCCAUugAwIBAgIUK1tdYusyCHZyruJw0TlYuTB+jWQwCgYIKoZIzj0EAwIw
        \\IDEeMBwGA1UEAwwVY3VybC16aWctdW50cnVzdGVkLWNhMB4XDTIwMDEwMTAwMDAw
        \\MFoXDTQ5MTIzMTIzNTk1OVowIDEeMBwGA1UEAwwVY3VybC16aWctdW50cnVzdGVk
        \\LWNhMFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAEBAN7h+PJuafFmclAXY9TdehT
        \\k0lCIKEVedYCVNdcqyivGEKobi3ggX2XczEz2tkuBYhgX1xSu5rAp7Qh8EdiXqNj
        \\MGEwHQYDVR0OBBYEFLmTzCbGW9eoesCGa0YkVyWMAvLhMB8GA1UdIwQYMBaAFLmT
        \\zCbGW9eoesCGa0YkVyWMAvLhMA8GA1UdEwEB/wQFMAMBAf8wDgYDVR0PAQH/BAQD
        \\AgEGMAoGCCqGSM49BAMCA0cAMEQCICw+8kVkXGTV0Y3KJGGCJTyO81HVwzzvrrZh
        \\7JiUJ/mhAiAgmXm9IXO+LnpgDToIFLISTMmovuVmX9dYPksZAfpz+g==
        \\-----END CERTIFICATE-----
        \\
    ;

    const test_server_pubkey_pin: [*:0]const u8 = "sha256//J5gIj+3IzbJ3r9lrFIvGtH1RgZOmPQNTuxxtsDkCOpc=";
    const test_wrong_pubkey_pin: [*:0]const u8 = "sha256//AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";

    const H = struct {
        const AF_INET: c_int = 2;
        const SOCK_STREAM: c_int = 1;
        const SOL_SOCKET: c_int = 1;
        const SO_REUSEADDR: c_int = 2;
        const SO_RCVTIMEO: c_int = 20;
        const SO_SNDTIMEO: c_int = 21;

        const sockaddr_in = extern struct {
            sin_family: u16 = AF_INET,
            sin_port: u16 = 0,
            sin_addr: u32 = 0,
            sin_zero: [8]u8 = @splat(0),
        };

        const timeval = extern struct {
            tv_sec: c_long,
            tv_usec: c_long,
        };

        const curl_blob = extern struct {
            data: ?*anyopaque,
            len: usize,
            flags: c_uint,
        };

        const curl_slist = extern struct {
            data: ?[*:0]u8,
            next: ?*curl_slist,
        };

        const curl_certinfo = extern struct {
            num_of_certs: c_int,
            certinfo: ?[*]?*curl_slist,
        };

        const CURLOPT_WRITEDATA: c_uint = 10001;
        const CURLOPT_URL: c_uint = 10002;
        const CURLOPT_WRITEFUNCTION: c_uint = 20011;
        const CURLOPT_SSL_VERIFYPEER: c_uint = 64;
        const CURLOPT_CAINFO: c_uint = 10065;
        const CURLOPT_SSL_VERIFYHOST: c_uint = 81;
        const CURLOPT_NOSIGNAL: c_uint = 99;
        const CURLOPT_TIMEOUT_MS: c_uint = 155;
        const CURLOPT_CERTINFO: c_uint = 172;
        const CURLOPT_RESOLVE: c_uint = 10203;
        const CURLOPT_PINNEDPUBLICKEY: c_uint = 10230;
        const CURLOPT_CAINFO_BLOB: c_uint = 40309;

        const CURLINFO_RESPONSE_CODE: c_uint = 0x200000 + 2;
        const CURLINFO_SSL_VERIFYRESULT: c_uint = 0x200000 + 13;
        const CURLINFO_CERTINFO: c_uint = 0x400000 + 34;

        extern "c" fn socket(domain: c_int, sock_type: c_int, protocol: c_int) c_int;
        extern "c" fn setsockopt(sockfd: c_int, level: c_int, optname: c_int, optval: *const anyopaque, optlen: u32) c_int;
        extern "c" fn bind(sockfd: c_int, addr: *const sockaddr_in, addrlen: u32) c_int;
        extern "c" fn listen(sockfd: c_int, backlog: c_int) c_int;
        extern "c" fn getsockname(sockfd: c_int, addr: *sockaddr_in, addrlen: *u32) c_int;
        extern "c" fn accept(sockfd: c_int, addr: ?*anyopaque, addrlen: ?*u32) c_int;
        extern "c" fn close(fd: c_int) c_int;
        extern fn gnutls_transport_set_int2(session: gnutls_session_t, r: c_int, s: c_int) callconv(.c) void;

        extern fn curl_easy_init() callconv(.c) ?*anyopaque;
        extern fn curl_easy_cleanup(handle: ?*anyopaque) callconv(.c) void;
        extern fn curl_easy_setopt(handle: ?*anyopaque, option: c_uint, ...) callconv(.c) CURLcode;
        extern fn curl_easy_perform(handle: ?*anyopaque) callconv(.c) CURLcode;
        extern fn curl_easy_getinfo(handle: ?*anyopaque, info: c_uint, ...) callconv(.c) CURLcode;
        extern fn curl_slist_append(list: ?*curl_slist, data: [*:0]const u8) callconv(.c) ?*curl_slist;
        extern fn curl_slist_free_all(list: ?*curl_slist) callconv(.c) void;

        const http_response = "HTTP/1.1 200 OK\r\nContent-Length: 20\r\nConnection: close\r\n\r\nhello from local tls";

        const ServerState = struct {
            listen_fd: c_int,
            negotiated_alpn_buf: [16]u8 = @splat(0),
            negotiated_alpn_len: usize = 0,
        };

        fn serveGnuTlsOnce(state: *ServerState) void {
            const client_fd = accept(state.listen_fd, null, null);
            if (client_fd < 0) return;
            defer _ = close(client_fd);

            if (builtin.os.tag == .linux) {
                const tv = timeval{ .tv_sec = 5, .tv_usec = 0 };
                _ = setsockopt(client_fd, SOL_SOCKET, SO_RCVTIMEO, &tv, @sizeOf(timeval));
                _ = setsockopt(client_fd, SOL_SOCKET, SO_SNDTIMEO, &tv, @sizeOf(timeval));
            }

            var creds: gnutls_certificate_credentials_t = null;
            if (gtls_ext.gnutls_certificate_allocate_credentials(&creds) != 0) return;
            defer gtls_ext.gnutls_certificate_free_credentials(creds);

            const cert_d = gnutls_datum_t{
                .data = @constCast(test_server_cert_pem.ptr),
                .size = @intCast(test_server_cert_pem.len),
            };
            const key_d = gnutls_datum_t{
                .data = @constCast(test_server_key_pem.ptr),
                .size = @intCast(test_server_key_pem.len),
            };
            if (gtls_ext.gnutls_certificate_set_x509_key_mem(creds, &cert_d, &key_d, GNUTLS_X509_FMT_PEM) < 0) return;

            var session: gnutls_session_t = null;
            if (gtls_ext.gnutls_init(&session, GNUTLS_SERVER) != 0) return;
            defer gtls_ext.gnutls_deinit(session);

            if (gtls_ext.gnutls_priority_set_direct(session, "NORMAL", null) != 0) return;
            if (gtls_ext.gnutls_credentials_set(session, GNUTLS_CRD_CERTIFICATE, creds) != 0) return;

            const alpn_proto = "http/1.1";
            var alpn_datum = [1]gnutls_datum_t{.{
                .data = @constCast(alpn_proto.ptr),
                .size = alpn_proto.len,
            }};
            _ = gtls_ext.gnutls_alpn_set_protocols(session, &alpn_datum, 1, 0);

            gnutls_transport_set_int2(session, client_fd, client_fd);

            while (true) {
                const rc = gtls_ext.gnutls_handshake(session);
                if (rc == 0) break;
                if (rc == GNUTLS_E_AGAIN or rc == GNUTLS_E_INTERRUPTED) continue;
                return;
            }

            var sel_alpn = gnutls_datum_t{};
            if (gtls_ext.gnutls_alpn_get_selected_protocol(session, &sel_alpn) == 0 and sel_alpn.data != null) {
                const copy_len = @min(sel_alpn.size, state.negotiated_alpn_buf.len);
                @memcpy(state.negotiated_alpn_buf[0..copy_len], sel_alpn.data.?[0..copy_len]);
                state.negotiated_alpn_len = copy_len;
            }

            var req_buf: [1024]u8 = undefined;
            const nread = gtls_ext.gnutls_record_recv(session, &req_buf, req_buf.len);
            if (nread > 0) {
                _ = gtls_ext.gnutls_record_send(session, http_response.ptr, http_response.len);
                _ = gtls_ext.gnutls_bye(session, GNUTLS_SHUT_WR);
            }
        }

        const ResponseBuf = struct {
            data: [256]u8 = undefined,
            len: usize = 0,
        };

        fn writeCb(ptr: [*]const u8, size: usize, nmemb: usize, userdata: ?*anyopaque) callconv(.c) usize {
            const total = size * nmemb;
            const rbuf: *ResponseBuf = @ptrCast(@alignCast(userdata orelse return total));
            const avail = rbuf.data.len - rbuf.len;
            const copy_len = @min(total, avail);
            if (copy_len > 0) {
                @memcpy(rbuf.data[rbuf.len .. rbuf.len + copy_len], ptr[0..copy_len]);
                rbuf.len += copy_len;
            }
            return total;
        }

        const TransferOpts = struct {
            hostname: []const u8 = "localhost",
            ca_pem_blob: ?[:0]const u8 = test_ca_cert_pem,
            cainfo_path: ?[*:0]const u8 = null,
            verifypeer: c_long = 1,
            verifyhost: c_long = 2,
            certinfo: bool = false,
            pinnedpubkey: ?[*:0]const u8 = null,
        };

        const TransferOutcome = struct {
            code: CURLcode,
            status_code: c_long = 0,
            verify_result: c_long = 0,
            body_ok: bool = false,
            alpn_ok: bool = false,
            certinfo_certs: c_int = 0,
        };

        fn runTransfer(opts: TransferOpts) !TransferOutcome {
            const listen_fd = socket(AF_INET, SOCK_STREAM, 0);
            if (listen_fd < 0) return error.SocketFailed;
            defer _ = close(listen_fd);

            const one: c_int = 1;
            _ = setsockopt(listen_fd, SOL_SOCKET, SO_REUSEADDR, &one, @sizeOf(c_int));

            var addr = sockaddr_in{
                .sin_family = AF_INET,
                .sin_port = 0,
                .sin_addr = std.mem.nativeToBig(u32, 0x7f000001),
            };
            if (bind(listen_fd, &addr, @sizeOf(sockaddr_in)) != 0) return error.BindFailed;
            if (listen(listen_fd, 4) != 0) return error.ListenFailed;

            var bound_addr = sockaddr_in{};
            var addr_len: u32 = @sizeOf(sockaddr_in);
            if (getsockname(listen_fd, &bound_addr, &addr_len) != 0) return error.GetsocknameFailed;
            const port = std.mem.bigToNative(u16, bound_addr.sin_port);

            var srv_state = ServerState{ .listen_fd = listen_fd };
            const srv_thread = try std.Thread.spawn(.{}, serveGnuTlsOnce, .{&srv_state});
            defer srv_thread.join();

            const easy = curl_easy_init() orelse return error.EasyInitFailed;
            defer curl_easy_cleanup(easy);

            var url_buf: [128]u8 = undefined;
            const url_s = try std.fmt.bufPrint(&url_buf, "https://{s}:{d}/test\x00", .{ opts.hostname, port });
            const url_z: [*:0]const u8 = @ptrCast(url_s.ptr);

            var resolve_list: ?*curl_slist = null;
            defer if (resolve_list) |l| curl_slist_free_all(l);
            var resolve_buf: [128]u8 = undefined;
            const resolve_s = try std.fmt.bufPrint(&resolve_buf, "{s}:{d}:127.0.0.1\x00", .{ opts.hostname, port });
            const resolve_entry: [*:0]const u8 = @ptrCast(resolve_s.ptr);
            resolve_list = curl_slist_append(null, resolve_entry);

            var rbuf = ResponseBuf{};
            _ = curl_easy_setopt(easy, CURLOPT_URL, url_z);
            _ = curl_easy_setopt(easy, CURLOPT_RESOLVE, resolve_list);
            _ = curl_easy_setopt(easy, CURLOPT_NOSIGNAL, @as(c_long, 1));
            _ = curl_easy_setopt(easy, CURLOPT_TIMEOUT_MS, @as(c_long, 5000));
            _ = curl_easy_setopt(easy, CURLOPT_WRITEFUNCTION, &writeCb);
            _ = curl_easy_setopt(easy, CURLOPT_WRITEDATA, &rbuf);
            _ = curl_easy_setopt(easy, CURLOPT_SSL_VERIFYPEER, opts.verifypeer);
            _ = curl_easy_setopt(easy, CURLOPT_SSL_VERIFYHOST, opts.verifyhost);

            if (opts.ca_pem_blob) |ca_pem| {
                var blob = curl_blob{
                    .data = @ptrCast(@constCast(ca_pem.ptr)),
                    .len = ca_pem.len,
                    .flags = 1,
                };
                _ = curl_easy_setopt(easy, CURLOPT_CAINFO_BLOB, &blob);
            }
            if (opts.cainfo_path) |path_z| {
                _ = curl_easy_setopt(easy, CURLOPT_CAINFO, path_z);
            }
            if (opts.certinfo) {
                _ = curl_easy_setopt(easy, CURLOPT_CERTINFO, @as(c_long, 1));
            }
            if (opts.pinnedpubkey) |pin| {
                _ = curl_easy_setopt(easy, CURLOPT_PINNEDPUBLICKEY, pin);
            }

            const code = curl_easy_perform(easy);
            var outcome = TransferOutcome{ .code = code };

            _ = curl_easy_getinfo(easy, CURLINFO_SSL_VERIFYRESULT, &outcome.verify_result);

            if (code == CURLE_OK) {
                _ = curl_easy_getinfo(easy, CURLINFO_RESPONSE_CODE, &outcome.status_code);
                outcome.body_ok = std.mem.eql(u8, rbuf.data[0..rbuf.len], "hello from local tls");
                outcome.alpn_ok = std.mem.eql(
                    u8,
                    srv_state.negotiated_alpn_buf[0..srv_state.negotiated_alpn_len],
                    "http/1.1",
                );
                if (opts.certinfo) {
                    var ci_ptr: ?*curl_certinfo = null;
                    if (curl_easy_getinfo(easy, CURLINFO_CERTINFO, &ci_ptr) == CURLE_OK and ci_ptr != null) {
                        outcome.certinfo_certs = ci_ptr.?.num_of_certs;
                    }
                }
            }
            return outcome;
        }
    };

    // 1. Trusted CA via CAINFO_BLOB + ALPN + CERTINFO + PINNEDPUBLICKEY match
    const ok_res = try H.runTransfer(.{
        .ca_pem_blob = test_ca_cert_pem,
        .certinfo = true,
        .pinnedpubkey = test_server_pubkey_pin,
    });
    try std.testing.expectEqual(CURLE_OK, ok_res.code);
    try std.testing.expectEqual(@as(c_long, 200), ok_res.status_code);
    try std.testing.expectEqual(@as(c_long, 0), ok_res.verify_result);
    try std.testing.expect(ok_res.body_ok);
    try std.testing.expect(ok_res.alpn_ok);
    try std.testing.expect(ok_res.certinfo_certs >= 1);

    // 2. Wrong CA must fail with CURLE_PEER_FAILED_VERIFICATION
    const wrong_ca_res = try H.runTransfer(.{
        .ca_pem_blob = test_untrusted_ca_cert_pem,
    });
    try std.testing.expectEqual(CURLE_PEER_FAILED_VERIFICATION, wrong_ca_res.code);
    try std.testing.expect(wrong_ca_res.verify_result != 0);

    // 3. Wrong CA with VERIFYPEER=0 succeeds
    const skip_verify_res = try H.runTransfer(.{
        .ca_pem_blob = test_untrusted_ca_cert_pem,
        .verifypeer = 0,
    });
    try std.testing.expectEqual(CURLE_OK, skip_verify_res.code);
    try std.testing.expect(skip_verify_res.body_ok);

    // 4. Wrong hostname with VERIFYHOST=2 fails with CURLE_PEER_FAILED_VERIFICATION
    const wrong_host_res = try H.runTransfer(.{
        .hostname = "evil.example.com",
        .ca_pem_blob = test_ca_cert_pem,
        .verifyhost = 2,
    });
    try std.testing.expectEqual(CURLE_PEER_FAILED_VERIFICATION, wrong_host_res.code);

    // 5. Wrong pinned public key fails with CURLE_SSL_PINNEDPUBKEYNOTMATCH
    const wrong_pin_res = try H.runTransfer(.{
        .ca_pem_blob = test_ca_cert_pem,
        .pinnedpubkey = test_wrong_pubkey_pin,
    });
    try std.testing.expectEqual(CURLE_SSL_PINNEDPUBKEYNOTMATCH, wrong_pin_res.code);
}
