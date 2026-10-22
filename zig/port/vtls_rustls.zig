const std = @import("std");
const builtin = @import("builtin");
const backend_options = @import("backend_options");
const containers = @import("containers.zig");
const mem = @import("mem.zig");
const primitives = @import("primitives.zig");
const vtls_backends = @import("vtls_backends.zig");
const vtls_core = @import("vtls_core.zig");
const vtls_scache_asn1 = @import("vtls_scache_asn1.zig");

const vtls_impl = vtls_backends.vtls_impl;
const c_ext = vtls_backends.c_ext;

pub const use_rustls = backend_options.ssl == .rustls;

const CURLcode = vtls_impl.CURLcode;
const CurlCfilter = vtls_impl.CurlCfilter;
const CurlEasy = vtls_impl.CurlEasy;
const SslConnectData = vtls_impl.SslConnectData;
const SslFilterConfig = vtls_impl.SslFilterConfig;
const CurlBlob = vtls_impl.CurlBlob;
const DynBuf = vtls_backends.DynBuf;
const AlpnProtoBuf = vtls_backends.AlpnProtoBuf;

const CURLE_OK = vtls_impl.CURLE_OK;
const CURLE_COULDNT_CONNECT: CURLcode = 7;
const CURLE_WRITE_ERROR: CURLcode = 23;
const CURLE_READ_ERROR = vtls_impl.CURLE_READ_ERROR;
const CURLE_OUT_OF_MEMORY = vtls_impl.CURLE_OUT_OF_MEMORY;
const CURLE_BAD_FUNCTION_ARGUMENT = vtls_impl.CURLE_BAD_FUNCTION_ARGUMENT;
const CURLE_SSL_CONNECT_ERROR = vtls_impl.CURLE_SSL_CONNECT_ERROR;
const CURLE_SEND_ERROR = vtls_impl.CURLE_SEND_ERROR;
const CURLE_RECV_ERROR = vtls_impl.CURLE_RECV_ERROR;
const CURLE_SSL_CERTPROBLEM = vtls_impl.CURLE_SSL_CERTPROBLEM;
const CURLE_SSL_CIPHER = vtls_impl.CURLE_SSL_CIPHER;
const CURLE_PEER_FAILED_VERIFICATION = vtls_impl.CURLE_PEER_FAILED_VERIFICATION;
const CURLE_SSL_CACERT_BADFILE: CURLcode = 77;
const CURLE_AGAIN = vtls_impl.CURLE_AGAIN;
const CURLE_SSL_CRL_BADFILE = vtls_impl.CURLE_SSL_CRL_BADFILE;
const CURLE_SSL_SHUTDOWN_FAILED = vtls_impl.CURLE_SSL_SHUTDOWN_FAILED;
const CURLE_NOT_BUILT_IN = vtls_impl.CURLE_NOT_BUILT_IN;
const CURLE_TOO_LARGE = containers.CURLE_TOO_LARGE;

const CURL_SSLVERSION_DEFAULT = vtls_impl.CURL_SSLVERSION_DEFAULT;
const CURL_SSLVERSION_TLSv1 = vtls_impl.CURL_SSLVERSION_TLSv1;
const CURL_SSLVERSION_TLSv1_0 = vtls_impl.CURL_SSLVERSION_TLSv1_0;
const CURL_SSLVERSION_TLSv1_1 = vtls_impl.CURL_SSLVERSION_TLSv1_1;
const CURL_SSLVERSION_TLSv1_2 = vtls_impl.CURL_SSLVERSION_TLSv1_2;
const CURL_SSLVERSION_TLSv1_3 = vtls_impl.CURL_SSLVERSION_TLSv1_3;

const CURL_SSLVERSION_MAX_NONE = vtls_impl.CURL_SSLVERSION_MAX_NONE;
const CURL_SSLVERSION_MAX_DEFAULT = vtls_impl.CURL_SSLVERSION_MAX_DEFAULT;
const CURL_SSLVERSION_MAX_TLSv1_0 = vtls_impl.CURL_SSLVERSION_MAX_TLSv1_0;
const CURL_SSLVERSION_MAX_TLSv1_1 = vtls_impl.CURL_SSLVERSION_MAX_TLSv1_1;
const CR_SSLVERSION_MAX_TLSv1_2: u32 = @as(u32, CURL_SSLVERSION_TLSv1_2) << 16;
const CURL_SSLVERSION_MAX_TLSv1_3 = vtls_impl.CURL_SSLVERSION_MAX_TLSv1_3;

const CURL_SSL_IO_NEED_NONE = vtls_backends.CURL_SSL_IO_NEED_NONE;
const CURL_SSL_IO_NEED_RECV = vtls_backends.CURL_SSL_IO_NEED_RECV;
const CURL_SSL_IO_NEED_SEND = vtls_backends.CURL_SSL_IO_NEED_SEND;

const ssl_connection_none = vtls_impl.ssl_connection_none;
const ssl_connection_negotiating = vtls_impl.ssl_connection_negotiating;
const ssl_connection_complete = vtls_impl.ssl_connection_complete;
const ssl_connect_2 = vtls_impl.ssl_connect_2;

const ALPN_ENTRIES_MAX = vtls_impl.ALPN_ENTRIES_MAX;
const MAX_ALLOWED_CERT_AMOUNT: usize = 30;
const STRERROR_LEN: usize = 256;
const KEYLOG_LABEL_MAXLEN: usize = 32;
const CLIENT_RANDOM_SIZE: usize = 32;
const DYN_CRLFILE_SIZE: usize = 64 * 1024 * 1024;
const DYN_CERTFILE_SIZE: usize = 100 * 1024;
const DYN_KEYFILE_SIZE: usize = 100 * 1024;

const EAGAIN_VAL: c_int = if (builtin.os.tag.isDarwin()) 35 else 11;
const EINVAL_VAL: c_int = 22;
const WSAEWOULDBLOCK_VAL: c_int = 10035;

inline fn rawEagain(err: c_int) bool {
    return err == EAGAIN_VAL or (builtin.os.tag == .windows and err == WSAEWOULDBLOCK_VAL);
}

// ============================================================================
// rustls-ffi C ABI Types, Constants & Extern Declarations
// ============================================================================

pub const rustls_result = c_uint;
pub const rustls_io_result = c_int;
pub const rustls_tls_version = u16;

pub const RUSTLS_TLS_VERSION_TLSV1_2: rustls_tls_version = 0x0303;
pub const RUSTLS_TLS_VERSION_TLSV1_3: rustls_tls_version = 0x0304;

pub const RUSTLS_RESULT_OK: rustls_result = 7000;
pub const RUSTLS_RESULT_IO: rustls_result = 7001;
pub const RUSTLS_RESULT_NULL_PARAMETER: rustls_result = 7002;
pub const RUSTLS_RESULT_INVALID_DNS_NAME_ERROR: rustls_result = 7003;
pub const RUSTLS_RESULT_PANIC: rustls_result = 7004;
pub const RUSTLS_RESULT_CERTIFICATE_PARSE_ERROR: rustls_result = 7005;
pub const RUSTLS_RESULT_PRIVATE_KEY_PARSE_ERROR: rustls_result = 7006;
pub const RUSTLS_RESULT_INSUFFICIENT_SIZE: rustls_result = 7007;
pub const RUSTLS_RESULT_NOT_FOUND: rustls_result = 7008;
pub const RUSTLS_RESULT_INVALID_PARAMETER: rustls_result = 7009;
pub const RUSTLS_RESULT_UNEXPECTED_EOF: rustls_result = 7010;
pub const RUSTLS_RESULT_PLAINTEXT_EMPTY: rustls_result = 7011;
pub const RUSTLS_RESULT_BUILDER_INCOMPATIBLE_TLS_VERSIONS: rustls_result = 7022;

pub const RUSTLS_RESULT_DECRYPT_ERROR: rustls_result = 7102;
pub const RUSTLS_RESULT_PEER_INCOMPATIBLE_ERROR: rustls_result = 7107;
pub const RUSTLS_RESULT_ALERT_PEER_INCOMPATIBLE_ERROR: rustls_result = 7107;

pub const RUSTLS_RESULT_CERT_ENCODING_BAD: rustls_result = 7121;
pub const RUSTLS_RESULT_CERT_EXPIRED: rustls_result = 7122;
pub const RUSTLS_RESULT_CERT_NOT_VALID_YET: rustls_result = 7123;
pub const RUSTLS_RESULT_CERT_REVOKED: rustls_result = 7124;
pub const RUSTLS_RESULT_CERT_UNHANDLED_CRITICAL_EXTENSION: rustls_result = 7125;
pub const RUSTLS_RESULT_CERT_UNKNOWN_ISSUER: rustls_result = 7126;
pub const RUSTLS_RESULT_CERT_BAD_SIGNATURE: rustls_result = 7127;
pub const RUSTLS_RESULT_CERT_NOT_VALID_FOR_NAME: rustls_result = 7128;
pub const RUSTLS_RESULT_CERT_INVALID_PURPOSE: rustls_result = 7129;
pub const RUSTLS_RESULT_CERT_APPLICATION_VERIFICATION_FAILURE: rustls_result = 7130;
pub const RUSTLS_RESULT_CERT_OTHER_ERROR: rustls_result = 7131;
pub const RUSTLS_RESULT_CERT_SCT_MALFORMED: rustls_result = 7139;
pub const RUSTLS_RESULT_CERT_SCT_INVALID_SIGNATURE: rustls_result = 7140;
pub const RUSTLS_RESULT_CERT_SCT_TIMESTAMP_IN_FUTURE: rustls_result = 7141;
pub const RUSTLS_RESULT_CERT_SCT_UNSUPPORTED_VERSION: rustls_result = 7142;
pub const RUSTLS_RESULT_CERT_SCT_UNKNOWN_LOG: rustls_result = 7143;
pub const RUSTLS_RESULT_CERT_CRL_EXPIRED: rustls_result = 7154;
pub const RUSTLS_RESULT_CERT_ISSUER_NOT_CA: rustls_result = 7156;
pub const RUSTLS_RESULT_CERT_NOT_VALID_YET_AT: rustls_result = 7157;

pub const RUSTLS_RESULT_ALERT_BAD_CERTIFICATE: rustls_result = 7208;
pub const RUSTLS_RESULT_ALERT_UNSUPPORTED_CERTIFICATE: rustls_result = 7209;
pub const RUSTLS_RESULT_ALERT_CERTIFICATE_REVOKED: rustls_result = 7210;
pub const RUSTLS_RESULT_ALERT_CERTIFICATE_EXPIRED: rustls_result = 7211;
pub const RUSTLS_RESULT_ALERT_CERTIFICATE_UNKNOWN: rustls_result = 7212;
pub const RUSTLS_RESULT_ALERT_UNKNOWN_CA: rustls_result = 7214;
pub const RUSTLS_RESULT_ALERT_ACCESS_DENIED: rustls_result = 7215;
pub const RUSTLS_RESULT_ALERT_DECRYPT_ERROR: rustls_result = 7217;

pub const RustlsStr = extern struct {
    data: ?[*]const u8,
    len: usize,
};

pub const RustlsSliceBytes = extern struct {
    data: ?[*]const u8,
    len: usize,
};

pub const RustlsIovec = extern struct {
    base: ?[*]const u8,
    len: usize,
};

pub const rustls_certificate = opaque {};
pub const rustls_certified_key = opaque {};
pub const rustls_client_config = opaque {};
pub const rustls_client_config_builder = opaque {};
pub const rustls_connection = opaque {};
pub const rustls_crypto_provider = opaque {};
pub const rustls_crypto_provider_builder = opaque {};
pub const rustls_root_cert_store = opaque {};
pub const rustls_root_cert_store_builder = opaque {};
pub const rustls_server_cert_verifier = opaque {};
pub const rustls_server_config = opaque {};
pub const rustls_server_config_builder = opaque {};
pub const rustls_slice_slice_bytes = opaque {};
pub const rustls_supported_ciphersuite = opaque {};
pub const rustls_web_pki_server_cert_verifier_builder = opaque {};

pub const RustlsVerifyServerCertParams = extern struct {
    end_entity_cert_der: RustlsSliceBytes,
    intermediate_certs_der: ?*const rustls_slice_slice_bytes,
    server_name: RustlsStr,
    ocsp_response: RustlsSliceBytes,
};

pub const rustls_read_callback = ?*const fn (
    userdata: ?*anyopaque,
    buf: [*]u8,
    n: usize,
    out_n: *usize,
) callconv(.c) rustls_io_result;

pub const rustls_write_callback = ?*const fn (
    userdata: ?*anyopaque,
    buf: [*]const u8,
    n: usize,
    out_n: *usize,
) callconv(.c) rustls_io_result;

pub const rustls_write_vectored_callback = ?*const fn (
    userdata: ?*anyopaque,
    iov: [*]const RustlsIovec,
    count: usize,
    out_n: *usize,
) callconv(.c) rustls_io_result;

pub const rustls_verify_server_cert_callback = ?*const fn (
    userdata: ?*anyopaque,
    params: *const RustlsVerifyServerCertParams,
) callconv(.c) u32;

pub const rustls_keylog_log_callback = ?*const fn (
    label: RustlsStr,
    client_random: [*]const u8,
    client_random_len: usize,
    secret: [*]const u8,
    secret_len: usize,
) callconv(.c) void;

pub const rustls_keylog_will_log_callback = ?*const fn (
    label: RustlsStr,
) callconv(.c) u8;

const libc_ext = struct {
    extern fn feof(stream: *anyopaque) callconv(.c) c_int;
};

pub const rustls_ext = struct {
    pub extern fn rustls_version() callconv(.c) RustlsStr;
    pub extern fn rustls_error(result: c_uint, buf: [*]u8, len: usize, out_n: *usize) callconv(.c) void;
    pub extern fn rustls_result_is_cert_error(result: c_uint) callconv(.c) bool;

    pub extern fn rustls_default_crypto_provider_random(buf: [*]u8, len: usize) callconv(.c) rustls_result;
    pub extern fn rustls_default_crypto_provider_ciphersuites_len() callconv(.c) usize;
    pub extern fn rustls_default_crypto_provider_ciphersuites_get(index: usize) callconv(.c) ?*const rustls_supported_ciphersuite;

    pub extern fn rustls_supported_ciphersuite_get_suite(cs: *const rustls_supported_ciphersuite) callconv(.c) u16;
    pub extern fn rustls_supported_ciphersuite_get_name(cs: *const rustls_supported_ciphersuite) callconv(.c) RustlsStr;
    pub extern fn rustls_supported_ciphersuite_protocol_version(cs: *const rustls_supported_ciphersuite) callconv(.c) rustls_tls_version;

    pub extern fn rustls_crypto_provider_builder_new_from_default(
        builder_out: *?*rustls_crypto_provider_builder,
    ) callconv(.c) rustls_result;
    pub extern fn rustls_crypto_provider_builder_set_cipher_suites(
        builder: *rustls_crypto_provider_builder,
        cipher_suites: [*]const *const rustls_supported_ciphersuite,
        cipher_suites_len: usize,
    ) callconv(.c) rustls_result;
    pub extern fn rustls_crypto_provider_builder_build(
        builder: *rustls_crypto_provider_builder,
        provider_out: *?*const rustls_crypto_provider,
    ) callconv(.c) rustls_result;
    pub extern fn rustls_crypto_provider_builder_free(
        builder: ?*rustls_crypto_provider_builder,
    ) callconv(.c) void;
    pub extern fn rustls_crypto_provider_free(
        provider: ?*const rustls_crypto_provider,
    ) callconv(.c) void;

    pub extern fn rustls_client_config_builder_new() callconv(.c) ?*rustls_client_config_builder;
    pub extern fn rustls_client_config_builder_new_custom(
        provider: *const rustls_crypto_provider,
        tls_versions: [*]const u16,
        tls_versions_len: usize,
        builder_out: *?*rustls_client_config_builder,
    ) callconv(.c) rustls_result;
    pub extern fn rustls_client_config_builder_dangerous_set_certificate_verifier(
        config_builder: *rustls_client_config_builder,
        callback: rustls_verify_server_cert_callback,
    ) callconv(.c) rustls_result;
    pub extern fn rustls_client_config_builder_set_server_verifier(
        builder: *rustls_client_config_builder,
        verifier: *const rustls_server_cert_verifier,
    ) callconv(.c) void;
    pub extern fn rustls_client_config_builder_set_alpn_protocols(
        builder: *rustls_client_config_builder,
        protocols: [*]const RustlsSliceBytes,
        len: usize,
    ) callconv(.c) rustls_result;
    pub extern fn rustls_client_config_builder_set_enable_sni(
        config: *rustls_client_config_builder,
        enable: bool,
    ) callconv(.c) void;
    pub extern fn rustls_client_config_builder_set_certified_key(
        builder: *rustls_client_config_builder,
        certified_keys: [*]const *const rustls_certified_key,
        certified_keys_len: usize,
    ) callconv(.c) rustls_result;
    pub extern fn rustls_client_config_builder_set_key_log(
        builder: *rustls_client_config_builder,
        log_cb: rustls_keylog_log_callback,
        will_log_cb: rustls_keylog_will_log_callback,
    ) callconv(.c) rustls_result;
    pub extern fn rustls_client_config_builder_build(
        builder: *rustls_client_config_builder,
        config_out: *?*const rustls_client_config,
    ) callconv(.c) rustls_result;
    pub extern fn rustls_client_config_builder_free(
        config: ?*rustls_client_config_builder,
    ) callconv(.c) void;
    pub extern fn rustls_client_config_free(
        config: ?*const rustls_client_config,
    ) callconv(.c) void;

    pub extern fn rustls_root_cert_store_builder_new() callconv(.c) ?*rustls_root_cert_store_builder;
    pub extern fn rustls_root_cert_store_builder_add_pem(
        builder: *rustls_root_cert_store_builder,
        pem: [*]const u8,
        pem_len: usize,
        strict: bool,
    ) callconv(.c) rustls_result;
    pub extern fn rustls_root_cert_store_builder_load_roots_from_file(
        builder: *rustls_root_cert_store_builder,
        filename: [*:0]const u8,
        strict: bool,
    ) callconv(.c) rustls_result;
    pub extern fn rustls_root_cert_store_builder_build(
        builder: *rustls_root_cert_store_builder,
        root_cert_store_out: *?*const rustls_root_cert_store,
    ) callconv(.c) rustls_result;
    pub extern fn rustls_root_cert_store_builder_free(
        builder: ?*rustls_root_cert_store_builder,
    ) callconv(.c) void;
    pub extern fn rustls_root_cert_store_free(
        store: ?*const rustls_root_cert_store,
    ) callconv(.c) void;

    pub extern fn rustls_web_pki_server_cert_verifier_builder_new(
        store: *const rustls_root_cert_store,
    ) callconv(.c) ?*rustls_web_pki_server_cert_verifier_builder;
    pub extern fn rustls_web_pki_server_cert_verifier_builder_add_crl(
        builder: *rustls_web_pki_server_cert_verifier_builder,
        crl_pem: [*]const u8,
        crl_pem_len: usize,
    ) callconv(.c) rustls_result;
    pub extern fn rustls_web_pki_server_cert_verifier_builder_build(
        builder: *rustls_web_pki_server_cert_verifier_builder,
        verifier_out: *?*rustls_server_cert_verifier,
    ) callconv(.c) rustls_result;
    pub extern fn rustls_web_pki_server_cert_verifier_builder_free(
        builder: ?*rustls_web_pki_server_cert_verifier_builder,
    ) callconv(.c) void;

    pub extern fn rustls_platform_server_cert_verifier(
        verifier_out: *?*rustls_server_cert_verifier,
    ) callconv(.c) rustls_result;
    pub extern fn rustls_server_cert_verifier_free(
        verifier: ?*rustls_server_cert_verifier,
    ) callconv(.c) void;

    pub extern fn rustls_certified_key_build(
        cert_chain: [*]const u8,
        cert_chain_len: usize,
        private_key: [*]const u8,
        private_key_len: usize,
        certified_key_out: *?*const rustls_certified_key,
    ) callconv(.c) rustls_result;
    pub extern fn rustls_certified_key_keys_match(
        key: *const rustls_certified_key,
    ) callconv(.c) rustls_result;
    pub extern fn rustls_certified_key_free(
        key: ?*const rustls_certified_key,
    ) callconv(.c) void;

    pub extern fn rustls_client_connection_new(
        config: *const rustls_client_config,
        hostname: [*:0]const u8,
        conn_out: *?*rustls_connection,
    ) callconv(.c) rustls_result;
    pub extern fn rustls_connection_free(
        conn: ?*rustls_connection,
    ) callconv(.c) void;
    pub extern fn rustls_connection_set_userdata(
        conn: *rustls_connection,
        userdata: ?*anyopaque,
    ) callconv(.c) void;
    pub extern fn rustls_connection_wants_read(
        conn: *const rustls_connection,
    ) callconv(.c) bool;
    pub extern fn rustls_connection_wants_write(
        conn: *const rustls_connection,
    ) callconv(.c) bool;
    pub extern fn rustls_connection_is_handshaking(
        conn: *const rustls_connection,
    ) callconv(.c) bool;
    pub extern fn rustls_connection_read_tls(
        conn: *rustls_connection,
        cb: rustls_read_callback,
        userdata: ?*anyopaque,
        out_n: *usize,
    ) callconv(.c) rustls_io_result;
    pub extern fn rustls_connection_write_tls(
        conn: *rustls_connection,
        cb: rustls_write_callback,
        userdata: ?*anyopaque,
        out_n: *usize,
    ) callconv(.c) rustls_io_result;
    pub extern fn rustls_connection_write_tls_vectored(
        conn: *rustls_connection,
        cb: rustls_write_vectored_callback,
        userdata: ?*anyopaque,
        out_n: *usize,
    ) callconv(.c) rustls_io_result;
    pub extern fn rustls_connection_process_new_packets(
        conn: *rustls_connection,
    ) callconv(.c) rustls_result;
    pub extern fn rustls_connection_read(
        conn: *rustls_connection,
        buf: [*]u8,
        count: usize,
        out_n: *usize,
    ) callconv(.c) rustls_result;
    pub extern fn rustls_connection_write(
        conn: *rustls_connection,
        buf: [*]const u8,
        count: usize,
        out_n: *usize,
    ) callconv(.c) rustls_result;
    pub extern fn rustls_connection_send_close_notify(
        conn: *rustls_connection,
    ) callconv(.c) void;
    pub extern fn rustls_connection_get_peer_certificate(
        conn: *const rustls_connection,
        i: usize,
    ) callconv(.c) ?*const rustls_certificate;
    pub extern fn rustls_certificate_get_der(
        cert: *const rustls_certificate,
        out_der_data: *?[*]const u8,
        out_der_len: *usize,
    ) callconv(.c) rustls_result;
    pub extern fn rustls_connection_get_alpn_protocol(
        conn: *const rustls_connection,
        protocol_out: *?[*]const u8,
        protocol_len_out: *usize,
    ) callconv(.c) void;
    pub extern fn rustls_connection_get_protocol_version(
        conn: *const rustls_connection,
    ) callconv(.c) u16;
    pub extern fn rustls_connection_get_negotiated_ciphersuite(
        conn: *const rustls_connection,
    ) callconv(.c) ?*const rustls_supported_ciphersuite;
    pub extern fn rustls_connection_get_negotiated_ciphersuite_name(
        conn: *const rustls_connection,
    ) callconv(.c) RustlsStr;
    pub extern fn rustls_connection_get_negotiated_key_exchange_group_name(
        conn: *const rustls_connection,
    ) callconv(.c) RustlsStr;

    // Server APIs used for loopback TLS handshake testing
    pub extern fn rustls_server_config_builder_new() callconv(.c) ?*rustls_server_config_builder;
    pub extern fn rustls_server_config_builder_set_certified_keys(
        builder: *rustls_server_config_builder,
        certified_keys: [*]const *const rustls_certified_key,
        certified_keys_len: usize,
    ) callconv(.c) rustls_result;
    pub extern fn rustls_server_config_builder_set_alpn_protocols(
        builder: *rustls_server_config_builder,
        protocols: [*]const RustlsSliceBytes,
        len: usize,
    ) callconv(.c) rustls_result;
    pub extern fn rustls_server_config_builder_build(
        builder: *rustls_server_config_builder,
        config_out: *?*const rustls_server_config,
    ) callconv(.c) rustls_result;
    pub extern fn rustls_server_config_builder_free(
        config: ?*rustls_server_config_builder,
    ) callconv(.c) void;
    pub extern fn rustls_server_config_free(
        config: ?*const rustls_server_config,
    ) callconv(.c) void;
    pub extern fn rustls_server_connection_new(
        config: *const rustls_server_config,
        conn_out: *?*rustls_connection,
    ) callconv(.c) rustls_result;
};

// ============================================================================
// Backend State & Error Mapping
// ============================================================================

pub const RustlsSslBackendData = extern struct {
    config: ?*const rustls_client_config = null,
    conn: ?*rustls_connection = null,
    plain_out_buffered: usize = 0,
    data_in_pending: bool = false,
    sent_shutdown: bool = false,
};

pub fn freeRustlsBackendData(ptr: ?*RustlsSslBackendData) void {
    mem.freeTyped(ptr);
}

inline fn cfCtx(cf: *CurlCfilter) ?*SslConnectData {
    return @ptrCast(@alignCast(cf.ctx orelse return null));
}

inline fn connsslBackend(connssl: *const SslConnectData) ?*RustlsSslBackendData {
    return @ptrCast(@alignCast(connssl.backend orelse return null));
}

inline fn cfBackend(cf: *CurlCfilter) ?*RustlsSslBackendData {
    const connssl = cfCtx(cf) orelse return null;
    return connsslBackend(connssl);
}

pub fn rustlsVerifyHostSlice(san_bytes_opt: ?[*]const u8, len: usize, hostname: []const u8) bool {
    return vtls_scache_asn1.verifyX509SanOrCnSlice(san_bytes_opt, len, hostname);
}

pub fn map_error(r: rustls_result) CURLcode {
    if (comptime use_rustls) {
        if (rustls_ext.rustls_result_is_cert_error(r)) {
            return CURLE_PEER_FAILED_VERIFICATION;
        }
    }
    return switch (r) {
        RUSTLS_RESULT_OK => CURLE_OK,
        RUSTLS_RESULT_NULL_PARAMETER => CURLE_BAD_FUNCTION_ARGUMENT,
        RUSTLS_RESULT_PEER_INCOMPATIBLE_ERROR => CURLE_SSL_CONNECT_ERROR,
        RUSTLS_RESULT_DECRYPT_ERROR,
        RUSTLS_RESULT_CERT_ENCODING_BAD,
        RUSTLS_RESULT_CERT_EXPIRED,
        RUSTLS_RESULT_CERT_NOT_VALID_YET,
        RUSTLS_RESULT_CERT_REVOKED,
        RUSTLS_RESULT_CERT_UNHANDLED_CRITICAL_EXTENSION,
        RUSTLS_RESULT_CERT_UNKNOWN_ISSUER,
        RUSTLS_RESULT_CERT_BAD_SIGNATURE,
        RUSTLS_RESULT_CERT_NOT_VALID_FOR_NAME,
        RUSTLS_RESULT_CERT_INVALID_PURPOSE,
        RUSTLS_RESULT_CERT_APPLICATION_VERIFICATION_FAILURE,
        RUSTLS_RESULT_CERT_OTHER_ERROR,
        RUSTLS_RESULT_CERT_SCT_MALFORMED,
        RUSTLS_RESULT_CERT_SCT_INVALID_SIGNATURE,
        RUSTLS_RESULT_CERT_SCT_TIMESTAMP_IN_FUTURE,
        RUSTLS_RESULT_CERT_SCT_UNSUPPORTED_VERSION,
        RUSTLS_RESULT_CERT_SCT_UNKNOWN_LOG,
        RUSTLS_RESULT_CERT_CRL_EXPIRED,
        RUSTLS_RESULT_CERT_ISSUER_NOT_CA,
        RUSTLS_RESULT_CERT_NOT_VALID_YET_AT,
        RUSTLS_RESULT_ALERT_BAD_CERTIFICATE,
        RUSTLS_RESULT_ALERT_UNSUPPORTED_CERTIFICATE,
        RUSTLS_RESULT_ALERT_CERTIFICATE_REVOKED,
        RUSTLS_RESULT_ALERT_CERTIFICATE_EXPIRED,
        RUSTLS_RESULT_ALERT_CERTIFICATE_UNKNOWN,
        RUSTLS_RESULT_ALERT_UNKNOWN_CA,
        RUSTLS_RESULT_ALERT_ACCESS_DENIED,
        RUSTLS_RESULT_ALERT_DECRYPT_ERROR,
        => CURLE_PEER_FAILED_VERIFICATION,
        else => CURLE_RECV_ERROR,
    };
}

fn rustls_failf(data: ?*CurlEasy, rr: rustls_result, msg: [*:0]const u8) void {
    if (comptime use_rustls) {
        var errorbuf: [STRERROR_LEN]u8 = undefined;
        var errorlen: usize = 0;
        rustls_ext.rustls_error(rr, &errorbuf, errorbuf.len, &errorlen);
        c_ext.Curl_failf(
            data,
            "%s: %.*s",
            msg,
            @as(c_int, @intCast(errorlen)),
            @as([*]const u8, &errorbuf),
        );
    } else {
        c_ext.Curl_failf(data, "%s", msg);
    }
}

fn crDataPending(cf: *CurlCfilter, data: ?*const CurlEasy) callconv(.c) bool {
    _ = data;
    const backend = cfBackend(cf) orelse return false;
    return backend.data_in_pending;
}

// ============================================================================
// Custom Read/Write Callbacks & Plain/TLS I/O
// ============================================================================

const IoCtx = extern struct {
    cf: *CurlCfilter,
    data: ?*CurlEasy,
};

inline fn ioCtxFromOpaque(userdata: ?*anyopaque) ?*const IoCtx {
    return @ptrCast(@alignCast(userdata orelse return null));
}

fn read_cb(
    userdata: ?*anyopaque,
    buf: [*]u8,
    len: usize,
    out_n: *usize,
) callconv(.c) rustls_io_result {
    const io_ctx = ioCtxFromOpaque(userdata) orelse {
        out_n.* = 0;
        return EINVAL_VAL;
    };
    const connssl = cfCtx(io_ctx.cf) orelse {
        out_n.* = 0;
        return EINVAL_VAL;
    };
    var nread: usize = 0;
    var ret: rustls_io_result = 0;

    const result = c_ext.Curl_conn_cf_recv(io_ctx.cf.next, io_ctx.data, buf, len, &nread);
    if (result != CURLE_OK) {
        nread = 0;
        if (result == CURLE_AGAIN) {
            ret = EAGAIN_VAL;
        } else {
            ret = EINVAL_VAL;
        }
    } else if (nread == 0) {
        connssl.set_peer_closed(true);
    }
    out_n.* = nread;
    c_ext.Curl_trc_cf_infof(
        io_ctx.data,
        io_ctx.cf,
        "cf->next recv(len=%zu) -> %d, %zu",
        len,
        @as(c_int, @intCast(result)),
        nread,
    );
    return ret;
}

fn write_cb(
    userdata: ?*anyopaque,
    buf: [*]const u8,
    len: usize,
    out_n: *usize,
) callconv(.c) rustls_io_result {
    const io_ctx = ioCtxFromOpaque(userdata) orelse {
        out_n.* = 0;
        return EINVAL_VAL;
    };
    var nwritten: usize = 0;
    var ret: rustls_io_result = 0;

    const result = c_ext.Curl_conn_cf_send(io_ctx.cf.next, io_ctx.data, buf, len, false, &nwritten);
    if (result != CURLE_OK) {
        nwritten = 0;
        if (result == CURLE_AGAIN) {
            ret = EAGAIN_VAL;
        } else {
            ret = EINVAL_VAL;
        }
    }
    out_n.* = nwritten;
    c_ext.Curl_trc_cf_infof(
        io_ctx.data,
        io_ctx.cf,
        "cf->next send(len=%zu) -> %d, %zu",
        len,
        @as(c_int, @intCast(result)),
        nwritten,
    );
    return ret;
}

pub fn write_vectored_cb(
    userdata: ?*anyopaque,
    iov: [*]const RustlsIovec,
    count: usize,
    out_n: *usize,
) callconv(.c) rustls_io_result {
    out_n.* = 0;
    var total: usize = 0;
    var i: usize = 0;
    while (i < count) : (i += 1) {
        const vec = iov[i];
        if (vec.len == 0) continue;
        const base = vec.base orelse continue;
        var written: usize = 0;
        const rc = write_cb(userdata, base, vec.len, &written);
        total += written;
        if (rc != 0) {
            if (total > 0) {
                out_n.* = total;
                return 0;
            }
            return rc;
        }
        if (written < vec.len) {
            break;
        }
    }
    out_n.* = total;
    return 0;
}

fn tls_recv_more(
    cf: *CurlCfilter,
    data: ?*CurlEasy,
    err: *CURLcode,
) isize {
    if (comptime !use_rustls) {
        err.* = CURLE_NOT_BUILT_IN;
        return -1;
    }
    const backend = cfBackend(cf) orelse {
        err.* = CURLE_RECV_ERROR;
        return -1;
    };
    const rconn = backend.conn orelse {
        err.* = CURLE_RECV_ERROR;
        return -1;
    };

    var io_ctx = IoCtx{
        .cf = cf,
        .data = data,
    };
    var tls_bytes_read: usize = 0;
    const io_error = rustls_ext.rustls_connection_read_tls(
        rconn,
        read_cb,
        &io_ctx,
        &tls_bytes_read,
    );
    if (rawEagain(io_error)) {
        err.* = CURLE_AGAIN;
        return -1;
    } else if (io_error != 0) {
        var buffer: [STRERROR_LEN]u8 = undefined;
        c_ext.Curl_failf(
            data,
            "reading from socket: %s",
            c_ext.curlx_strerror(io_error, &buffer, buffer.len),
        );
        err.* = CURLE_RECV_ERROR;
        return -1;
    }

    const rresult = rustls_ext.rustls_connection_process_new_packets(rconn);
    if (rresult != RUSTLS_RESULT_OK) {
        rustls_failf(data, rresult, "rustls_connection_process_new_packets");
        err.* = map_error(rresult);
        return -1;
    }

    backend.data_in_pending = true;
    err.* = CURLE_OK;
    return @intCast(tls_bytes_read);
}

fn crRecv(
    cf: *CurlCfilter,
    data: ?*CurlEasy,
    plainbuf: [*]u8,
    plainlen: usize,
    pnread: *usize,
) callconv(.c) CURLcode {
    if (comptime !use_rustls) {
        pnread.* = 0;
        return CURLE_NOT_BUILT_IN;
    }
    const backend = cfBackend(cf) orelse {
        pnread.* = 0;
        return CURLE_RECV_ERROR;
    };
    const rconn = backend.conn orelse {
        pnread.* = 0;
        return CURLE_RECV_ERROR;
    };

    var result: CURLcode = CURLE_OK;
    var n: usize = 0;
    var rresult: rustls_result = 0;
    var eof = false;

    pnread.* = 0;

    out: {
        while (pnread.* < plainlen) {
            if (!backend.data_in_pending) {
                if (tls_recv_more(cf, data, &result) < 0) {
                    if (result != CURLE_AGAIN) {
                        break :out;
                    }
                    result = CURLE_OK;
                    break;
                }
            }

            rresult = rustls_ext.rustls_connection_read(
                rconn,
                plainbuf + pnread.*,
                plainlen - pnread.*,
                &n,
            );
            if (rresult == RUSTLS_RESULT_PLAINTEXT_EMPTY) {
                backend.data_in_pending = false;
                break;
            } else if (rresult == RUSTLS_RESULT_UNEXPECTED_EOF) {
                c_ext.Curl_failf(
                    data,
                    "rustls: peer closed TCP connection without first closing TLS connection",
                );
                result = CURLE_RECV_ERROR;
                break :out;
            } else if (rresult != RUSTLS_RESULT_OK) {
                rustls_failf(data, rresult, "rustls_connection_read");
                result = CURLE_RECV_ERROR;
                break :out;
            } else if (n == 0) {
                eof = true;
                break;
            } else {
                pnread.* += n;
            }
        }

        if (!eof and pnread.* == 0) {
            result = CURLE_AGAIN;
        }
    }

    c_ext.Curl_trc_cf_infof(
        data,
        cf,
        "rustls_recv(len=%zu) -> %d, %zu",
        plainlen,
        @as(c_int, @intCast(result)),
        pnread.*,
    );
    return result;
}

fn cr_flush_out(
    cf: *CurlCfilter,
    data: ?*CurlEasy,
    rconn: *rustls_connection,
) CURLcode {
    if (comptime !use_rustls) return CURLE_NOT_BUILT_IN;

    var io_ctx = IoCtx{
        .cf = cf,
        .data = data,
    };
    var tlswritten: usize = 0;
    var tlswritten_total: usize = 0;

    while (rustls_ext.rustls_connection_wants_write(rconn)) {
        const io_error = rustls_ext.rustls_connection_write_tls(
            rconn,
            write_cb,
            &io_ctx,
            &tlswritten,
        );
        if (rawEagain(io_error)) {
            c_ext.Curl_trc_cf_infof(data, cf, "cf_send: EAGAIN after %zu bytes", tlswritten_total);
            return CURLE_AGAIN;
        } else if (io_error != 0) {
            var buffer: [STRERROR_LEN]u8 = undefined;
            c_ext.Curl_failf(
                data,
                "writing to socket: %s",
                c_ext.curlx_strerror(io_error, &buffer, buffer.len),
            );
            return CURLE_SEND_ERROR;
        }
        if (tlswritten == 0) {
            c_ext.Curl_failf(data, "EOF in swrite");
            return CURLE_SEND_ERROR;
        }
        c_ext.Curl_trc_cf_infof(data, cf, "cf_send: wrote %zu TLS bytes", tlswritten);
        tlswritten_total += tlswritten;
    }
    return CURLE_OK;
}

fn crSend(
    cf: *CurlCfilter,
    data: ?*CurlEasy,
    plainbuf: ?*const anyopaque,
    plainlen: usize,
    pnwritten: *usize,
) callconv(.c) CURLcode {
    if (comptime !use_rustls) {
        pnwritten.* = 0;
        return CURLE_NOT_BUILT_IN;
    }
    const backend = cfBackend(cf) orelse {
        pnwritten.* = 0;
        return CURLE_SEND_ERROR;
    };
    const rconn = backend.conn orelse {
        pnwritten.* = 0;
        return CURLE_SEND_ERROR;
    };

    var plainwritten: usize = 0;
    var buf_opt: ?[*]const u8 = if (plainbuf) |p| @ptrCast(p) else null;
    var result: CURLcode = CURLE_OK;
    var blen: usize = plainlen;

    pnwritten.* = 0;

    c_ext.Curl_trc_cf_infof(data, cf, "cf_send(len=%zu)", plainlen);

    if (backend.plain_out_buffered > 0) {
        result = cr_flush_out(cf, data, rconn);
        c_ext.Curl_trc_cf_infof(
            data,
            cf,
            "cf_send: flushing %zu previously added bytes -> %d",
            backend.plain_out_buffered,
            @as(c_int, @intCast(result)),
        );
        if (result != CURLE_OK) return result;

        if (blen > backend.plain_out_buffered) {
            blen -= backend.plain_out_buffered;
            if (buf_opt) |b| {
                buf_opt = b + backend.plain_out_buffered;
            }
        } else {
            blen = 0;
        }
        pnwritten.* += backend.plain_out_buffered;
        backend.plain_out_buffered = 0;
    }

    out: {
        if (blen > 0) {
            const buf = buf_opt orelse {
                result = CURLE_BAD_FUNCTION_ARGUMENT;
                break :out;
            };
            c_ext.Curl_trc_cf_infof(data, cf, "cf_send: adding %zu plain bytes to Rustls", blen);
            const rresult = rustls_ext.rustls_connection_write(rconn, buf, blen, &plainwritten);
            if (rresult != RUSTLS_RESULT_OK) {
                rustls_failf(data, rresult, "rustls_connection_write");
                result = CURLE_WRITE_ERROR;
                break :out;
            } else if (plainwritten == 0) {
                c_ext.Curl_failf(data, "rustls_connection_write: EOF");
                result = CURLE_WRITE_ERROR;
                break :out;
            }
        }

        result = cr_flush_out(cf, data, rconn);
        if (result != CURLE_OK) {
            if (result == CURLE_AGAIN) {
                backend.plain_out_buffered = plainwritten;
                if (pnwritten.* > 0) {
                    result = CURLE_OK;
                }
            }
            break :out;
        } else {
            pnwritten.* += plainwritten;
        }
    }

    c_ext.Curl_trc_cf_infof(
        data,
        cf,
        "rustls_send(len=%zu) -> %d, %zu",
        plainlen,
        @as(c_int, @intCast(result)),
        pnwritten.*,
    );
    return result;
}

// ============================================================================
// Cipher Suites & Crypto Provider
// ============================================================================

pub const CipherIdMapEntry = struct {
    id: u16,
    name: [:0]const u8,
};

pub const ciphers_id_map = [_]CipherIdMapEntry{
    .{ .id = 0x1302, .name = "TLS13_AES_256_GCM_SHA384" },
    .{ .id = 0x1301, .name = "TLS13_AES_128_GCM_SHA256" },
    .{ .id = 0x1303, .name = "TLS13_CHACHA20_POLY1305_SHA256" },
    .{ .id = 0xc02c, .name = "TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384" },
    .{ .id = 0xc02b, .name = "TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256" },
    .{ .id = 0xcca9, .name = "TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305_SHA256" },
    .{ .id = 0xc030, .name = "TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384" },
    .{ .id = 0xc02f, .name = "TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256" },
    .{ .id = 0xcca8, .name = "TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305_SHA256" },
};

pub fn cr_cipher_suite_walk_str(str: *?[*:0]const u8, end: *?[*:0]const u8) u16 {
    var id = vtls_core.Curl_cipher_suite_walk_str(str, end);
    if (id == 0) {
        if (str.*) |s| {
            if (end.*) |e| {
                const len = @intFromPtr(e) - @intFromPtr(s);
                if (len > 0) {
                    for (ciphers_id_map) |entry| {
                        if (entry.name.len == len and
                            primitives.curl_strnequal(entry.name.ptr, s, len) != 0)
                        {
                            id = entry.id;
                            break;
                        }
                    }
                }
            }
        }
    }
    return id;
}

pub fn cr_get_Suite(id: u16) ?*const rustls_supported_ciphersuite {
    if (comptime !use_rustls) return null;
    if (id == 0) return null;
    const default_len = rustls_ext.rustls_default_crypto_provider_ciphersuites_len();
    var i: usize = 0;
    while (i < default_len) : (i += 1) {
        const entry = rustls_ext.rustls_default_crypto_provider_ciphersuites_get(i) orelse continue;
        if (rustls_ext.rustls_supported_ciphersuite_get_suite(entry) == id) {
            return entry;
        }
    }
    return null;
}

pub fn cr_get_selected_ciphers(
    data: ?*CurlEasy,
    ciphers12: ?[*:0]const u8,
    ciphers13: ?[*:0]const u8,
    selected: [*]*const rustls_supported_ciphersuite,
    selected_size: *usize,
) void {
    if (comptime !use_rustls) {
        selected_size.* = 0;
        return;
    }
    const supported_len = selected_size.*;
    const default_len = rustls_ext.rustls_default_crypto_provider_ciphersuites_len();
    var ciphers: [*:0]const u8 = ciphers12 orelse "";
    var count: usize = 0;
    var default13_count: usize = 0;
    var doing_ciphers13 = false;

    if (ciphers13 == null) {
        var j: usize = 0;
        while (j < default_len and count < supported_len) : (j += 1) {
            const entry = rustls_ext.rustls_default_crypto_provider_ciphersuites_get(j) orelse continue;
            if (rustls_ext.rustls_supported_ciphersuite_protocol_version(entry) != RUSTLS_TLS_VERSION_TLSV1_3)
                continue;
            selected[count] = entry;
            count += 1;
        }
        default13_count = count;
        if (ciphers12 == null) {
            ciphers = "";
        }
    } else {
        ciphers = ciphers13.?;
        doing_ciphers13 = true;
    }

    while (true) {
        var ptr: ?[*:0]const u8 = ciphers;
        var end: ?[*:0]const u8 = null;

        while (ptr != null and ptr.?[0] != 0 and count < supported_len) : (ptr = end) {
            var id = cr_cipher_suite_walk_str(&ptr, &end);
            var matched_entry: ?*const rustls_supported_ciphersuite = null;

            if (id != 0) {
                var i: usize = 0;
                while (i < supported_len and i < default_len) : (i += 1) {
                    const entry = rustls_ext.rustls_default_crypto_provider_ciphersuites_get(i) orelse continue;
                    if (rustls_ext.rustls_supported_ciphersuite_get_suite(entry) == id) {
                        matched_entry = entry;
                        break;
                    }
                }
                if (matched_entry == null) {
                    id = 0;
                }
            }

            if (id == 0 or matched_entry == null) {
                if (ptr != null and ptr.?[0] != 0) {
                    const tok_len: c_int = if (end) |e| @intCast(@intFromPtr(e) - @intFromPtr(ptr.?)) else 0;
                    c_ext.Curl_infof(data, "rustls: unknown cipher in list: \"%.*s\"", tok_len, ptr.?);
                }
                continue;
            }

            const entry = matched_entry.?;
            var dup_idx: usize = 0;
            while (dup_idx < count and selected[dup_idx] != entry) : (dup_idx += 1) {}
            if (dup_idx < count) {
                if (dup_idx >= default13_count) {
                    const tok_len: c_int = if (end) |e| @intCast(@intFromPtr(e) - @intFromPtr(ptr.?)) else 0;
                    c_ext.Curl_infof(data, "rustls: duplicate cipher in list: \"%.*s\"", tok_len, ptr.?);
                }
                continue;
            }

            selected[count] = entry;
            count += 1;
        }

        if (doing_ciphers13 and ciphers12 != null) {
            ciphers = ciphers12.?;
            doing_ciphers13 = false;
            continue;
        }
        break;
    }

    if (ciphers12 == null) {
        var j: usize = 0;
        while (j < default_len and count < supported_len) : (j += 1) {
            const entry = rustls_ext.rustls_default_crypto_provider_ciphersuites_get(j) orelse continue;
            if (rustls_ext.rustls_supported_ciphersuite_protocol_version(entry) == RUSTLS_TLS_VERSION_TLSV1_3)
                continue;

            var dup_idx: usize = 0;
            while (dup_idx < count and selected[dup_idx] != entry) : (dup_idx += 1) {}
            if (dup_idx < count)
                continue;

            selected[count] = entry;
            count += 1;
        }
    }

    selected_size.* = count;
}

// ============================================================================
// TLS Versions, Verifier, CRLs, Client Certs & Config Builder
// ============================================================================

fn cr_verify_none(
    userdata: ?*anyopaque,
    params: *const RustlsVerifyServerCertParams,
) callconv(.c) u32 {
    _ = userdata;
    _ = params;
    return RUSTLS_RESULT_OK;
}

fn read_file_into(filename: [*:0]const u8, out: *DynBuf) bool {
    const f = c_ext.fopen(filename, "r") orelse return false;
    var buf: [256]u8 = undefined;
    defer mem.secureZero(&buf, buf.len);
    while (true) {
        const rr = c_ext.fread(&buf, 1, buf.len, f);
        if ((rr == 0 and libc_ext.feof(f) == 0) or
            containers.curlx_dyn_addn(out, &buf, rr) != CURLE_OK)
        {
            _ = c_ext.fclose(f);
            return false;
        }
        if (rr < buf.len)
            break;
    }
    return c_ext.fclose(f) == 0;
}

fn cr_keylog_log_cb(
    label: RustlsStr,
    client_random: [*]const u8,
    client_random_len: usize,
    secret: [*]const u8,
    secret_len: usize,
) callconv(.c) void {
    if (client_random_len != CLIENT_RANDOM_SIZE) return;
    var clabel: [KEYLOG_LABEL_MAXLEN:0]u8 = @splat(0);
    defer mem.secureZero(&clabel, clabel.len);
    const label_ptr = label.data orelse "";
    _ = c_ext.curl_msnprintf(
        &clabel,
        clabel.len,
        "%.*s",
        @as(c_int, @intCast(label.len)),
        label_ptr,
    );
    _ = vtls_core.Curl_tls_keylog_write(
        &clabel,
        client_random[0..CLIENT_RANDOM_SIZE],
        client_random_len,
        secret,
        secret_len,
    );
}

pub fn cr_set_ssl_version_min_max(
    data: ?*CurlEasy,
    conn_config: *const SslFilterConfig,
    tls_versions: *[2]u16,
    tls_versions_len: *usize,
) CURLcode {
    tls_versions.* = .{
        RUSTLS_TLS_VERSION_TLSV1_2,
        RUSTLS_TLS_VERSION_TLSV1_3,
    };
    tls_versions_len.* = 2;

    switch (conn_config.version) {
        CURL_SSLVERSION_DEFAULT,
        CURL_SSLVERSION_TLSv1,
        CURL_SSLVERSION_TLSv1_0,
        CURL_SSLVERSION_TLSv1_1,
        CURL_SSLVERSION_TLSv1_2,
        => {},
        CURL_SSLVERSION_TLSv1_3 => {
            tls_versions[0] = RUSTLS_TLS_VERSION_TLSV1_3;
            tls_versions_len.* = 1;
        },
        else => {
            c_ext.Curl_failf(data, "rustls: unsupported minimum TLS version value");
            return CURLE_BAD_FUNCTION_ARGUMENT;
        },
    }

    switch (conn_config.version_max) {
        CURL_SSLVERSION_MAX_DEFAULT,
        CURL_SSLVERSION_MAX_NONE,
        CURL_SSLVERSION_MAX_TLSv1_3,
        => {},
        CR_SSLVERSION_MAX_TLSv1_2 => {
            if (tls_versions[0] == RUSTLS_TLS_VERSION_TLSV1_2) {
                tls_versions_len.* = 1;
            } else {
                c_ext.Curl_failf(data, "rustls: unsupported maximum TLS version value");
                return CURLE_BAD_FUNCTION_ARGUMENT;
            }
        },
        CURL_SSLVERSION_MAX_TLSv1_1,
        CURL_SSLVERSION_MAX_TLSv1_0,
        => {
            c_ext.Curl_failf(data, "rustls: unsupported maximum TLS version value");
            return CURLE_BAD_FUNCTION_ARGUMENT;
        },
        else => {
            c_ext.Curl_failf(data, "rustls: unsupported maximum TLS version value");
            return CURLE_BAD_FUNCTION_ARGUMENT;
        },
    }

    return CURLE_OK;
}

fn init_config_builderImpl(
    cf: *CurlCfilter,
    data: ?*CurlEasy,
    conn_config: *const SslFilterConfig,
    config_builder: *?*rustls_client_config_builder,
) !void {
    var tls_versions: [2]u16 = undefined;
    var tls_versions_len: usize = 0;
    const result = cr_set_ssl_version_min_max(data, conn_config, &tls_versions, &tls_versions_len);
    if (result != CURLE_OK) return error.BadVersion;

    var cipher_suites_len = rustls_ext.rustls_default_crypto_provider_ciphersuites_len();
    const cipher_suites = mem.allocMany(*const rustls_supported_ciphersuite, @max(cipher_suites_len, 1)) orelse {
        return error.OutOfMemory;
    };
    defer mem.freeTyped(cipher_suites);

    const is_proxy = vtls_impl.Curl_ssl_cf_is_proxy(cf);
    const cipher_list: ?[*:0]const u8 = if (conn_config.cipher_list) |c|
        c
    else if (data != null)
        c_ext.Curl_vtls_acc_ssl_cipher_list(data, is_proxy)
    else
        null;
    const cipher_list13: ?[*:0]const u8 = if (conn_config.cipher_list13) |c|
        c
    else if (data != null)
        c_ext.Curl_vtls_acc_ssl_cipher13_list(data, is_proxy)
    else
        null;

    cr_get_selected_ciphers(
        data,
        cipher_list,
        cipher_list13,
        cipher_suites,
        &cipher_suites_len,
    );
    if (cipher_suites_len == 0) {
        c_ext.Curl_failf(data, "rustls: no supported cipher in list");
        return error.SslCipher;
    }

    var custom_provider_builder: ?*rustls_crypto_provider_builder = null;
    errdefer if (custom_provider_builder) |cpb| rustls_ext.rustls_crypto_provider_builder_free(cpb);

    var rr = rustls_ext.rustls_crypto_provider_builder_new_from_default(&custom_provider_builder);
    if (rr != RUSTLS_RESULT_OK or custom_provider_builder == null) {
        rustls_failf(data, rr, "failed to create crypto provider builder from default");
        return error.SslCipher;
    }

    rr = rustls_ext.rustls_crypto_provider_builder_set_cipher_suites(
        custom_provider_builder.?,
        cipher_suites,
        cipher_suites_len,
    );
    if (rr != RUSTLS_RESULT_OK) {
        rustls_failf(data, rr, "failed to set ciphersuites for crypto provider builder");
        return error.SslCipher;
    }

    const cpb = custom_provider_builder.?;
    custom_provider_builder = null;
    var custom_provider: ?*const rustls_crypto_provider = null;
    defer if (custom_provider) |cp| rustls_ext.rustls_crypto_provider_free(cp);

    rr = rustls_ext.rustls_crypto_provider_builder_build(cpb, &custom_provider);
    if (rr != RUSTLS_RESULT_OK or custom_provider == null) {
        rustls_failf(data, rr, "failed to build custom crypto provider");
        return error.SslCipher;
    }

    rr = rustls_ext.rustls_client_config_builder_new_custom(
        custom_provider.?,
        &tls_versions,
        tls_versions_len,
        config_builder,
    );
    if (rr != RUSTLS_RESULT_OK) {
        rustls_failf(data, rr, "failed to create client config builder");
        return error.SslCipher;
    }
}

fn init_config_builder(
    cf: *CurlCfilter,
    data: ?*CurlEasy,
    conn_config: *const SslFilterConfig,
    config_builder: *?*rustls_client_config_builder,
) CURLcode {
    if (comptime !use_rustls) return CURLE_NOT_BUILT_IN;
    init_config_builderImpl(cf, data, conn_config, config_builder) catch |err| return switch (err) {
        error.BadVersion => CURLE_BAD_FUNCTION_ARGUMENT,
        error.OutOfMemory => CURLE_OUT_OF_MEMORY,
        error.SslCipher => CURLE_SSL_CIPHER,
    };
    return CURLE_OK;
}

fn init_config_builder_alpn(
    data: ?*CurlEasy,
    connssl: *const SslConnectData,
    config_builder: *rustls_client_config_builder,
) void {
    if (comptime !use_rustls) return;
    const alpn_spec = connssl.alpn orelse return;
    var proto: AlpnProtoBuf = undefined;
    var alpn: [ALPN_ENTRIES_MAX]RustlsSliceBytes = undefined;
    const count = @min(alpn_spec.count, ALPN_ENTRIES_MAX);

    var i: usize = 0;
    while (i < count) : (i += 1) {
        const entry_ptr: [*:0]const u8 = @ptrCast(&alpn_spec.entries[i]);
        alpn[i] = .{
            .data = entry_ptr,
            .len = std.mem.len(entry_ptr),
        };
    }
    _ = rustls_ext.rustls_client_config_builder_set_alpn_protocols(config_builder, &alpn, count);
    _ = vtls_impl.Curl_alpn_to_proto_str(&proto, alpn_spec);
    c_ext.Curl_infof(data, "ALPN: curl offers %s", @as([*:0]const u8, @ptrCast(&proto.data)));
}

fn init_config_builder_verifier_crl(
    data: ?*CurlEasy,
    crl_file: [*:0]const u8,
    builder: *rustls_web_pki_server_cert_verifier_builder,
) CURLcode {
    if (comptime !use_rustls) return CURLE_NOT_BUILT_IN;

    var crl_contents: DynBuf = undefined;
    containers.curlx_dyn_init(&crl_contents, DYN_CRLFILE_SIZE);
    defer containers.curlx_dyn_free(&crl_contents);

    if (!read_file_into(crl_file, &crl_contents)) {
        c_ext.Curl_failf(data, "rustls: failed to read revocation list file");
        return CURLE_SSL_CRL_BADFILE;
    }

    const crl_ptr: [*]const u8 = containers.curlx_dyn_uptr(&crl_contents) orelse "";
    const crl_len = containers.curlx_dyn_len(&crl_contents);
    const rr = rustls_ext.rustls_web_pki_server_cert_verifier_builder_add_crl(
        builder,
        crl_ptr,
        crl_len,
    );
    if (rr != RUSTLS_RESULT_OK) {
        rustls_failf(data, rr, "failed to parse revocation list");
        return CURLE_SSL_CRL_BADFILE;
    }

    return CURLE_OK;
}

fn init_config_builder_verifier(
    data: ?*CurlEasy,
    builder: *rustls_client_config_builder,
    crl_file: ?[*:0]const u8,
    ca_info_blob: ?*const CurlBlob,
    ssl_cafile: ?[*:0]const u8,
) CURLcode {
    if (comptime !use_rustls) return CURLE_NOT_BUILT_IN;

    const roots_builder: ?*rustls_root_cert_store_builder = rustls_ext.rustls_root_cert_store_builder_new();
    if (roots_builder == null) return CURLE_OUT_OF_MEMORY;
    defer if (roots_builder) |rb| rustls_ext.rustls_root_cert_store_builder_free(rb);

    var roots: ?*const rustls_root_cert_store = null;
    defer if (roots) |r| rustls_ext.rustls_root_cert_store_free(r);

    var verifier_builder: ?*rustls_web_pki_server_cert_verifier_builder = null;
    defer if (verifier_builder) |vb| rustls_ext.rustls_web_pki_server_cert_verifier_builder_free(vb);

    var server_cert_verifier: ?*rustls_server_cert_verifier = null;
    defer if (server_cert_verifier) |scv| rustls_ext.rustls_server_cert_verifier_free(scv);

    if (ca_info_blob) |blob| {
        const pem_ptr: [*]const u8 = if (blob.data) |d| @ptrCast(d) else "";
        const rr = rustls_ext.rustls_root_cert_store_builder_add_pem(
            roots_builder.?,
            pem_ptr,
            blob.len,
            true,
        );
        if (rr != RUSTLS_RESULT_OK) {
            rustls_failf(data, rr, "failed to parse trusted certificates from blob");
            return CURLE_SSL_CACERT_BADFILE;
        }
    } else if (ssl_cafile) |cafile| {
        const rr = rustls_ext.rustls_root_cert_store_builder_load_roots_from_file(
            roots_builder.?,
            cafile,
            true,
        );
        if (rr != RUSTLS_RESULT_OK) {
            rustls_failf(data, rr, "failed to load trusted certificates");
            return CURLE_SSL_CACERT_BADFILE;
        }
    }

    var rr = rustls_ext.rustls_root_cert_store_builder_build(roots_builder.?, &roots);
    if (rr != RUSTLS_RESULT_OK or roots == null) {
        rustls_failf(data, rr, "failed to build trusted root certificate store");
        return CURLE_SSL_CACERT_BADFILE;
    }

    verifier_builder = rustls_ext.rustls_web_pki_server_cert_verifier_builder_new(roots.?);
    if (verifier_builder == null) {
        return CURLE_OUT_OF_MEMORY;
    }

    if (crl_file) |crl| {
        const crl_res = init_config_builder_verifier_crl(data, crl, verifier_builder.?);
        if (crl_res != CURLE_OK) {
            return crl_res;
        }
    }

    rr = rustls_ext.rustls_web_pki_server_cert_verifier_builder_build(
        verifier_builder.?,
        &server_cert_verifier,
    );
    if (rr != RUSTLS_RESULT_OK or server_cert_verifier == null) {
        rustls_failf(data, rr, "failed to build certificate verifier");
        return CURLE_SSL_CACERT_BADFILE;
    }

    rustls_ext.rustls_client_config_builder_set_server_verifier(
        builder,
        server_cert_verifier.?,
    );
    return CURLE_OK;
}

fn init_config_builder_platform_verifier(
    data: ?*CurlEasy,
    builder: *rustls_client_config_builder,
) CURLcode {
    if (comptime !use_rustls) return CURLE_NOT_BUILT_IN;

    var server_cert_verifier: ?*rustls_server_cert_verifier = null;
    defer if (server_cert_verifier) |scv| rustls_ext.rustls_server_cert_verifier_free(scv);

    const rr = rustls_ext.rustls_platform_server_cert_verifier(&server_cert_verifier);
    if (rr != RUSTLS_RESULT_OK or server_cert_verifier == null) {
        rustls_failf(data, rr, "failed to create platform certificate verifier");
        return CURLE_SSL_CACERT_BADFILE;
    }

    rustls_ext.rustls_client_config_builder_set_server_verifier(
        builder,
        server_cert_verifier.?,
    );
    return CURLE_OK;
}

fn init_config_builder_keylog(
    data: ?*CurlEasy,
    builder: *rustls_client_config_builder,
) CURLcode {
    if (comptime !use_rustls) return CURLE_NOT_BUILT_IN;

    vtls_core.Curl_tls_keylog_open();
    if (!vtls_core.Curl_tls_keylog_enabled()) {
        return CURLE_OK;
    }

    const rr = rustls_ext.rustls_client_config_builder_set_key_log(
        builder,
        cr_keylog_log_cb,
        null,
    );
    if (rr != RUSTLS_RESULT_OK) {
        rustls_failf(data, rr, "rustls_client_config_builder_set_key_log");
        vtls_core.Curl_tls_keylog_close();
        return map_error(rr);
    }

    return CURLE_OK;
}

fn init_config_builder_client_auth(
    data: ?*CurlEasy,
    clientcert: ?[*:0]const u8,
    cert_blob: ?*const CurlBlob,
    cert_type: ?[*:0]const u8,
    key: ?[*:0]const u8,
    key_blob: ?*const CurlBlob,
    key_type: ?[*:0]const u8,
    builder: *rustls_client_config_builder,
) CURLcode {
    if (comptime !use_rustls) return CURLE_NOT_BUILT_IN;

    const have_cert = clientcert != null or cert_blob != null;
    const have_key = key != null or key_blob != null;

    if (have_cert and !have_key) {
        c_ext.Curl_failf(data, "rustls: must provide key with certificate");
        return CURLE_SSL_CERTPROBLEM;
    } else if (!have_cert and have_key) {
        c_ext.Curl_failf(data, "rustls: must provide certificate with key");
        return CURLE_SSL_CERTPROBLEM;
    }

    if (cert_type) |ct| {
        if (primitives.curl_strequal(ct, "PEM") == 0) {
            c_ext.Curl_failf(
                data,
                "rustls: unsupported certificate type '%s', only 'PEM' is supported",
                ct,
            );
            return CURLE_SSL_CERTPROBLEM;
        }
    }
    if (key_type) |kt| {
        if (primitives.curl_strequal(kt, "PEM") == 0) {
            c_ext.Curl_failf(
                data,
                "rustls: unsupported key type '%s', only 'PEM' is supported",
                kt,
            );
            return CURLE_SSL_CERTPROBLEM;
        }
    }

    var cert_contents: DynBuf = undefined;
    var key_contents: DynBuf = undefined;
    containers.curlx_dyn_init(&cert_contents, DYN_CERTFILE_SIZE);
    defer containers.curlx_dyn_free(&cert_contents);
    containers.curlx_dyn_init(&key_contents, DYN_KEYFILE_SIZE);
    defer {
        if (containers.curlx_dyn_uptr(&key_contents)) |kp| {
            mem.secureZero(@constCast(kp), containers.curlx_dyn_len(&key_contents));
        }
        containers.curlx_dyn_free(&key_contents);
    }

    var certified_key: ?*const rustls_certified_key = null;
    defer if (certified_key) |ck| rustls_ext.rustls_certified_key_free(ck);

    if (cert_blob) |cb| {
        const result = containers.curlx_dyn_addn(&cert_contents, cb.data, cb.len);
        if (result != CURLE_OK) {
            const reason: [*:0]const u8 = if (result == CURLE_TOO_LARGE) "too large" else "out of memory";
            c_ext.Curl_failf(data, "rustls: failed to copy client certificate blob (%s)", reason);
            return result;
        }
    } else if (clientcert) |cc| {
        if (!read_file_into(cc, &cert_contents)) {
            c_ext.Curl_failf(data, "rustls: failed to read client certificate file: '%s'", cc);
            return CURLE_SSL_CERTPROBLEM;
        }
    }

    if (key_blob) |kb| {
        const result = containers.curlx_dyn_addn(&key_contents, kb.data, kb.len);
        if (result != CURLE_OK) {
            const reason: [*:0]const u8 = if (result == CURLE_TOO_LARGE) "too large" else "out of memory";
            c_ext.Curl_failf(data, "rustls: failed to copy key blob (%s)", reason);
            return result;
        }
    } else if (key) |k| {
        if (!read_file_into(k, &key_contents)) {
            c_ext.Curl_failf(data, "rustls: failed to read key file: '%s'", k);
            return CURLE_SSL_CERTPROBLEM;
        }
    }

    const cert_ptr: [*]const u8 = containers.curlx_dyn_uptr(&cert_contents) orelse "";
    const cert_len = containers.curlx_dyn_len(&cert_contents);
    const key_ptr: [*]const u8 = containers.curlx_dyn_uptr(&key_contents) orelse "";
    const key_len = containers.curlx_dyn_len(&key_contents);

    var rr = rustls_ext.rustls_certified_key_build(
        cert_ptr,
        cert_len,
        key_ptr,
        key_len,
        &certified_key,
    );
    if (rr != RUSTLS_RESULT_OK or certified_key == null) {
        rustls_failf(data, rr, "rustls: failed to build certified key");
        return CURLE_SSL_CERTPROBLEM;
    }

    rr = rustls_ext.rustls_certified_key_keys_match(certified_key.?);
    if (rr != RUSTLS_RESULT_OK) {
        rustls_failf(data, rr, "rustls: client certificate and keypair files do not match:");
        return CURLE_SSL_CERTPROBLEM;
    }

    const ck_arr = [1]*const rustls_certified_key{certified_key.?};
    rr = rustls_ext.rustls_client_config_builder_set_certified_key(builder, &ck_arr, 1);
    if (rr != RUSTLS_RESULT_OK) {
        rustls_failf(data, rr, "rustls: failed to set certified key");
        return CURLE_SSL_CERTPROBLEM;
    }

    return CURLE_OK;
}

fn cr_init_backendImpl(
    cf: *CurlCfilter,
    data: ?*CurlEasy,
    backend: *RustlsSslBackendData,
) !void {
    const connssl = cfCtx(cf) orelse return error.SslConnectError;
    const conn_config = vtls_impl.Curl_ssl_cf_get_filter_config(cf) orelse return error.SslConnectError;
    const is_proxy = vtls_impl.Curl_ssl_cf_is_proxy(cf);

    var config_builder: ?*rustls_client_config_builder = null;
    errdefer if (config_builder) |cb| rustls_ext.rustls_client_config_builder_free(cb);

    const ca_info_blob: ?*const CurlBlob = if (conn_config.ca_info_blob) |b|
        b
    else if (data != null)
        c_ext.Curl_vtls_acc_ssl_ca_info_blob(data, is_proxy)
    else
        null;
    const ssl_cafile: ?[*:0]const u8 = if (ca_info_blob != null)
        null
    else if (conn_config.CAfile) |f|
        f
    else if (data != null)
        c_ext.Curl_vtls_acc_ssl_cainfo(data, is_proxy)
    else
        null;
    const crl_file: ?[*:0]const u8 = if (conn_config.CRLfile) |f|
        f
    else if (data != null)
        c_ext.Curl_vtls_acc_ssl_crlfile(data, is_proxy)
    else
        null;

    var result = init_config_builder(cf, data, conn_config, &config_builder);
    if (result != CURLE_OK or config_builder == null) {
        return error.InitConfigFailed;
    }

    if (connssl.alpn != null) {
        init_config_builder_alpn(data, connssl, config_builder.?);
    }

    if (!conn_config.verifypeer()) {
        _ = rustls_ext.rustls_client_config_builder_dangerous_set_certificate_verifier(
            config_builder.?,
            cr_verify_none,
        );
    } else if (conn_config.native_ca_store()) {
        if (crl_file != null) {
            c_ext.Curl_failf(
                data,
                "rustls: CRL file not supported with native CA store; the platform verifier has no CRL attachment API",
            );
            return error.NotBuiltIn;
        }
        result = init_config_builder_platform_verifier(data, config_builder.?);
        if (result != CURLE_OK) return error.CaCertBadFile;
    } else if (ca_info_blob != null or ssl_cafile != null) {
        result = init_config_builder_verifier(
            data,
            config_builder.?,
            crl_file,
            ca_info_blob,
            ssl_cafile,
        );
        if (result != CURLE_OK) return if (result == CURLE_SSL_CRL_BADFILE) error.CrlBadFile else if (result == CURLE_OUT_OF_MEMORY) error.OutOfMemory else error.CaCertBadFile;
    }

    const clientcert: ?[*:0]const u8 = if (conn_config.clientcert) |c|
        c
    else if (data != null)
        c_ext.Curl_vtls_acc_ssl_cert(data, is_proxy)
    else
        null;
    const cert_blob: ?*const CurlBlob = if (conn_config.cert_blob) |b|
        b
    else if (data != null)
        c_ext.Curl_vtls_acc_ssl_cert_blob(data, is_proxy)
    else
        null;
    const cert_type: ?[*:0]const u8 = if (conn_config.cert_type) |t|
        t
    else if (data != null)
        c_ext.Curl_vtls_acc_ssl_cert_type(data, is_proxy)
    else
        null;
    const key: ?[*:0]const u8 = if (conn_config.key) |k|
        k
    else if (data != null)
        c_ext.Curl_vtls_acc_ssl_key(data, is_proxy)
    else
        null;
    const key_blob: ?*const CurlBlob = conn_config.key_blob;
    const key_type: ?[*:0]const u8 = if (conn_config.key_type) |t|
        t
    else if (data != null)
        c_ext.Curl_vtls_acc_ssl_key_type(data, is_proxy)
    else
        null;

    if (clientcert != null or cert_blob != null or key != null or key_blob != null) {
        result = init_config_builder_client_auth(
            data,
            clientcert,
            cert_blob,
            cert_type,
            key,
            key_blob,
            key_type,
            config_builder.?,
        );
        if (result != CURLE_OK) return if (result == CURLE_OUT_OF_MEMORY) error.OutOfMemory else if (result == CURLE_TOO_LARGE) error.TooLarge else error.CertProblem;
    }

    result = init_config_builder_keylog(data, config_builder.?);
    if (result != CURLE_OK) return error.SslConnectError;

    const cb = config_builder.?;
    config_builder = null;
    var rr = rustls_ext.rustls_client_config_builder_build(cb, &backend.config);
    errdefer if (backend.config) |cfg| {
        rustls_ext.rustls_client_config_free(cfg);
        backend.config = null;
    };
    if (rr != RUSTLS_RESULT_OK or backend.config == null) {
        rustls_failf(data, rr, "failed to build client config");
        return error.SslConnectError;
    }

    const hostname: [*:0]const u8 = if (connssl.peer.origin) |orig|
        orig.hostname
    else if (connssl.peer.sni) |sni|
        sni
    else
        "";

    var rconn: ?*rustls_connection = null;
    rr = rustls_ext.rustls_client_connection_new(
        backend.config.?,
        hostname,
        &rconn,
    );
    if (rr != RUSTLS_RESULT_OK or rconn == null) {
        rustls_failf(data, rr, "rustls_client_connection_new");
        return error.CouldntConnect;
    }

    rustls_ext.rustls_connection_set_userdata(rconn.?, backend);
    backend.conn = rconn;
}

fn cr_init_backend(
    cf: *CurlCfilter,
    data: ?*CurlEasy,
    backend: *RustlsSslBackendData,
) CURLcode {
    if (comptime !use_rustls) return CURLE_NOT_BUILT_IN;
    cr_init_backendImpl(cf, data, backend) catch |err| return switch (err) {
        error.SslConnectError, error.InitConfigFailed => CURLE_SSL_CONNECT_ERROR,
        error.NotBuiltIn => CURLE_NOT_BUILT_IN,
        error.CaCertBadFile => CURLE_SSL_CACERT_BADFILE,
        error.CrlBadFile => CURLE_SSL_CRL_BADFILE,
        error.OutOfMemory => CURLE_OUT_OF_MEMORY,
        error.TooLarge => CURLE_TOO_LARGE,
        error.CertProblem => CURLE_SSL_CERTPROBLEM,
        error.CouldntConnect => CURLE_COULDNT_CONNECT,
    };
    return CURLE_OK;
}

// ============================================================================
// Handshake, Certchain, Shutdown, Close, Version & Random
// ============================================================================

fn cr_set_negotiated_alpn(
    cf: *CurlCfilter,
    data: ?*CurlEasy,
    rconn: *const rustls_connection,
) void {
    if (comptime !use_rustls) return;
    const connssl = cfCtx(cf) orelse return;
    var protocol: ?[*]const u8 = null;
    var len: usize = 0;

    rustls_ext.rustls_connection_get_alpn_protocol(rconn, &protocol, &len);
    _ = vtls_impl.Curl_alpn_set_negotiated(cf, data, connssl, protocol, len);
}

fn crConnect(
    cf: *CurlCfilter,
    data: ?*CurlEasy,
    done: *bool,
) callconv(.c) CURLcode {
    if (comptime !use_rustls) {
        done.* = false;
        return CURLE_NOT_BUILT_IN;
    }

    const connssl = cfCtx(cf) orelse {
        done.* = false;
        return CURLE_SSL_CONNECT_ERROR;
    };
    const backend = connsslBackend(connssl) orelse {
        done.* = false;
        return CURLE_SSL_CONNECT_ERROR;
    };

    c_ext.Curl_trc_cf_infof(data, cf, "cr_connect, state=%d", @as(c_int, @intCast(connssl.state)));
    done.* = false;

    if (backend.conn == null) {
        const init_res = cr_init_backend(cf, data, backend);
        c_ext.Curl_trc_cf_infof(data, cf, "cr_connect, init backend -> %d", @as(c_int, @intCast(init_res)));
        if (init_res != CURLE_OK) return init_res;
        connssl.state = ssl_connection_negotiating;
    }

    const rconn = backend.conn.?;

    while (true) {
        connssl.io_need = CURL_SSL_IO_NEED_NONE;
        if (!rustls_ext.rustls_connection_is_handshaking(rconn)) {
            var nwritten: usize = 0;
            cr_set_negotiated_alpn(cf, data, rconn);
            const tmperr = crSend(cf, data, null, 0, &nwritten);
            if (tmperr == CURLE_AGAIN) {
                connssl.io_need = CURL_SSL_IO_NEED_SEND;
                return CURLE_OK;
            } else if (tmperr != CURLE_OK) {
                return tmperr;
            }

            const proto = rustls_ext.rustls_connection_get_protocol_version(rconn);
            const ciphersuite_name = rustls_ext.rustls_connection_get_negotiated_ciphersuite_name(rconn);
            const kex_group_name = rustls_ext.rustls_connection_get_negotiated_key_exchange_group_name(rconn);
            const ver: [*:0]const u8 = if (proto == RUSTLS_TLS_VERSION_TLSV1_3)
                "TLSv1.3"
            else if (proto == RUSTLS_TLS_VERSION_TLSV1_2)
                "TLSv1.2"
            else
                "TLS version unknown";

            c_ext.Curl_infof(
                data,
                "rustls: handshake complete, %s, ciphersuite: %.*s, key exchange group: %.*s",
                ver,
                @as(c_int, @intCast(ciphersuite_name.len)),
                ciphersuite_name.data orelse "",
                @as(c_int, @intCast(kex_group_name.len)),
                kex_group_name.data orelse "",
            );

            if (c_ext.Curl_vtls_acc_ssl_certinfo(data)) {
                var num_certs: usize = 0;
                while (rustls_ext.rustls_connection_get_peer_certificate(rconn, num_certs) != null) {
                    num_certs += 1;
                    if (num_certs > MAX_ALLOWED_CERT_AMOUNT) {
                        c_ext.Curl_failf(
                            data,
                            "%zu certificates is more than allowed (%d)",
                            num_certs,
                            @as(c_int, @intCast(MAX_ALLOWED_CERT_AMOUNT)),
                        );
                        return CURLE_SSL_CONNECT_ERROR;
                    }
                }
                var result = vtls_impl.Curl_ssl_init_certinfo(data, @intCast(num_certs));
                if (result != CURLE_OK) return result;

                var i: usize = 0;
                while (i < num_certs) : (i += 1) {
                    const cert = rustls_ext.rustls_connection_get_peer_certificate(rconn, i) orelse continue;
                    var der_data: ?[*]const u8 = null;
                    var der_len: usize = 0;
                    const rresult = rustls_ext.rustls_certificate_get_der(cert, &der_data, &der_len);
                    if (rresult != RUSTLS_RESULT_OK or der_data == null) {
                        var errorbuf: [255]u8 = undefined;
                        var errorlen: usize = 0;
                        rustls_ext.rustls_error(rresult, &errorbuf, errorbuf.len, &errorlen);
                        c_ext.Curl_failf(
                            data,
                            "Failed getting DER of server certificate #%zu: %.*s",
                            i,
                            @as(c_int, @intCast(errorlen)),
                            @as([*]const u8, &errorbuf),
                        );
                        return map_error(rresult);
                    }
                    result = vtls_scache_asn1.Curl_extract_certinfo_zig(
                        data,
                        @intCast(i),
                        der_data.?,
                        der_data.? + der_len,
                        true,
                        @ptrCast(&vtls_impl.Curl_ssl_push_certinfo_len),
                    );
                    if (result != CURLE_OK) return result;
                }
            }

            connssl.state = ssl_connection_complete;
            done.* = true;
            return CURLE_OK;
        }

        connssl.connecting_state = ssl_connect_2;
        const wants_read = rustls_ext.rustls_connection_wants_read(rconn);
        const wants_write = rustls_ext.rustls_connection_wants_write(rconn) or
            backend.plain_out_buffered > 0;

        if (wants_write) {
            var nwritten: usize = 0;
            c_ext.Curl_trc_cf_infof(data, cf, "rustls_connection wants us to write_tls.");
            const tmperr = crSend(cf, data, null, 0, &nwritten);
            if (tmperr == CURLE_AGAIN) {
                c_ext.Curl_trc_cf_infof(data, cf, "writing would block");
                connssl.io_need = CURL_SSL_IO_NEED_SEND;
                return CURLE_OK;
            } else if (tmperr != CURLE_OK) {
                return tmperr;
            }
        }

        if (wants_read) {
            var tmperr: CURLcode = CURLE_OK;
            c_ext.Curl_trc_cf_infof(data, cf, "rustls_connection wants us to read_tls.");
            const nread = tls_recv_more(cf, data, &tmperr);
            if (nread == 0) {
                connssl.set_peer_closed(true);
                c_ext.Curl_failf(data, "TLS connect error: Connection closed abruptly");
                return CURLE_SSL_CONNECT_ERROR;
            }
            if (nread < 0) {
                if (tmperr == CURLE_AGAIN) {
                    c_ext.Curl_trc_cf_infof(data, cf, "reading would block");
                    connssl.io_need = CURL_SSL_IO_NEED_RECV;
                    return CURLE_OK;
                } else if (tmperr == CURLE_RECV_ERROR) {
                    return CURLE_SSL_CONNECT_ERROR;
                } else {
                    return tmperr;
                }
            }
        }
    }
}

fn crGetInternals(connssl: *SslConnectData, info: c_uint) callconv(.c) ?*anyopaque {
    _ = info;
    const backend = connsslBackend(connssl) orelse return null;
    return mem.toRawPtr(backend.conn);
}

fn crShutdown(
    cf: *CurlCfilter,
    data: ?*CurlEasy,
    send_shutdown: bool,
    done: *bool,
) callconv(.c) CURLcode {
    if (comptime !use_rustls) {
        done.* = true;
        return CURLE_OK;
    }

    const connssl = cfCtx(cf) orelse {
        done.* = true;
        return CURLE_OK;
    };
    const backend = connsslBackend(connssl) orelse {
        done.* = true;
        return CURLE_OK;
    };

    var result: CURLcode = CURLE_OK;
    var nread: usize = 0;
    var nwritten: usize = 0;

    if (backend.conn == null or cf.isShutdown()) {
        done.* = true;
        cf.setShutdown(true);
        return result;
    }

    connssl.io_need = CURL_SSL_IO_NEED_NONE;
    done.* = false;

    if (!backend.sent_shutdown) {
        backend.sent_shutdown = true;
        if (send_shutdown) {
            rustls_ext.rustls_connection_send_close_notify(backend.conn.?);
        }
    }

    out: {
        result = crSend(cf, data, null, 0, &nwritten);
        if (result != CURLE_OK) {
            if (result == CURLE_AGAIN) {
                connssl.io_need = CURL_SSL_IO_NEED_SEND;
                result = CURLE_OK;
                break :out;
            }
            c_ext.Curl_trc_cf_infof(data, cf, "shutdown send failed: %d", @as(c_int, @intCast(result)));
            break :out;
        }

        var i: usize = 0;
        while (i < 10) : (i += 1) {
            var buf: [1024]u8 = undefined;
            result = crRecv(cf, data, &buf, buf.len, &nread);
            if (result != CURLE_OK) break;
        }

        if (result == CURLE_AGAIN) {
            connssl.io_need = CURL_SSL_IO_NEED_RECV;
            result = CURLE_OK;
        } else if (result != CURLE_OK) {
            c_ext.Curl_trc_cf_infof(data, cf, "shutdown, error: %d", @as(c_int, @intCast(result)));
        } else if (nread == 0) {
            done.* = true;
        }
    }

    cf.setShutdown(result != CURLE_OK or done.*);
    return result;
}

fn crClose(cf: *CurlCfilter, data: ?*CurlEasy) callconv(.c) void {
    _ = data;
    if (comptime !use_rustls) return;

    const backend = cfBackend(cf) orelse return;

    if (backend.conn) |rconn| {
        rustls_ext.rustls_connection_free(rconn);
        backend.conn = null;
    }
    if (backend.config) |cfg| {
        rustls_ext.rustls_client_config_free(cfg);
        backend.config = null;
    }
}

fn crVersion(buffer: [*]u8, size: usize) callconv(.c) usize {
    if (comptime use_rustls) {
        const ver = rustls_ext.rustls_version();
        const ptr = ver.data orelse "";
        const n = c_ext.curl_msnprintf(buffer, size, "%.*s", @as(c_int, @intCast(ver.len)), ptr);
        return if (n > 0) @intCast(n) else 0;
    }
    return 0;
}

fn crRandom(
    data: ?*CurlEasy,
    entropy: [*]u8,
    length: usize,
) callconv(.c) CURLcode {
    _ = data;
    if (comptime use_rustls) {
        const rresult = rustls_ext.rustls_default_crypto_provider_random(entropy, length);
        return map_error(rresult);
    }
    return CURLE_NOT_BUILT_IN;
}

fn crCleanup() callconv(.c) void {
    if (comptime use_rustls) {
        vtls_core.Curl_tls_keylog_close();
    }
}

pub const Curl_ssl_rustls = vtls_impl.CurlSsl{
    .info = .{
        .id = vtls_impl.CURLSSLBACKEND_RUSTLS,
        .name = "rustls",
    },
    .supports = vtls_impl.SSLSUPP_CAINFO_BLOB |
        vtls_impl.SSLSUPP_HTTPS_PROXY |
        vtls_impl.SSLSUPP_CIPHER_LIST |
        vtls_impl.SSLSUPP_TLS13_CIPHERSUITES |
        vtls_impl.SSLSUPP_CERTINFO |
        vtls_impl.SSLSUPP_CRLFILE,
    .sizeof_ssl_backend_data = @sizeOf(RustlsSslBackendData),
    .init = null,
    .cleanup = crCleanup,
    .version = crVersion,
    .shut_down = crShutdown,
    .data_pending = crDataPending,
    .random = crRandom,
    .cert_status_request = null,
    .do_connect = crConnect,
    .adjust_pollset = vtls_impl.Curl_ssl_adjust_pollset,
    .get_internals = crGetInternals,
    .close = crClose,
    .close_all = null,
    .engines_list = null,
    .sha256sum = null,
    .recv_plain = crRecv,
    .send_plain = crSend,
    .get_channel_binding = null,
};

comptime {
    if (use_rustls) {
        @export(&Curl_ssl_rustls, .{ .name = "Curl_ssl_rustls" });
    }
}

// ============================================================================
// Unit & Loopback TLS Integration Tests
// ============================================================================

test "rustls map_error and TLS version min/max mapping" {
    try std.testing.expectEqual(CURLE_OK, map_error(RUSTLS_RESULT_OK));
    try std.testing.expectEqual(CURLE_BAD_FUNCTION_ARGUMENT, map_error(RUSTLS_RESULT_NULL_PARAMETER));
    try std.testing.expectEqual(CURLE_SSL_CONNECT_ERROR, map_error(RUSTLS_RESULT_PEER_INCOMPATIBLE_ERROR));
    try std.testing.expectEqual(CURLE_PEER_FAILED_VERIFICATION, map_error(RUSTLS_RESULT_ALERT_BAD_CERTIFICATE));
    try std.testing.expectEqual(CURLE_PEER_FAILED_VERIFICATION, map_error(RUSTLS_RESULT_ALERT_UNSUPPORTED_CERTIFICATE));
    try std.testing.expectEqual(CURLE_PEER_FAILED_VERIFICATION, map_error(RUSTLS_RESULT_ALERT_CERTIFICATE_REVOKED));
    try std.testing.expectEqual(CURLE_PEER_FAILED_VERIFICATION, map_error(RUSTLS_RESULT_ALERT_CERTIFICATE_EXPIRED));
    try std.testing.expectEqual(CURLE_PEER_FAILED_VERIFICATION, map_error(RUSTLS_RESULT_ALERT_UNKNOWN_CA));
    try std.testing.expectEqual(CURLE_PEER_FAILED_VERIFICATION, map_error(RUSTLS_RESULT_ALERT_ACCESS_DENIED));
    try std.testing.expectEqual(CURLE_PEER_FAILED_VERIFICATION, map_error(RUSTLS_RESULT_ALERT_DECRYPT_ERROR));
    try std.testing.expectEqual(CURLE_PEER_FAILED_VERIFICATION, map_error(RUSTLS_RESULT_DECRYPT_ERROR));
    try std.testing.expectEqual(CURLE_PEER_FAILED_VERIFICATION, map_error(RUSTLS_RESULT_CERT_EXPIRED));
    try std.testing.expectEqual(CURLE_PEER_FAILED_VERIFICATION, map_error(RUSTLS_RESULT_CERT_UNKNOWN_ISSUER));
    try std.testing.expectEqual(CURLE_PEER_FAILED_VERIFICATION, map_error(RUSTLS_RESULT_CERT_NOT_VALID_FOR_NAME));
    try std.testing.expectEqual(CURLE_RECV_ERROR, map_error(RUSTLS_RESULT_IO));

    var cfg = std.mem.zeroes(SslFilterConfig);
    var tls_versions: [2]u16 = undefined;
    var tls_versions_len: usize = 0;

    cfg.version = CURL_SSLVERSION_DEFAULT;
    cfg.version_max = CURL_SSLVERSION_MAX_DEFAULT;
    try std.testing.expectEqual(CURLE_OK, cr_set_ssl_version_min_max(null, &cfg, &tls_versions, &tls_versions_len));
    try std.testing.expectEqual(@as(usize, 2), tls_versions_len);
    try std.testing.expectEqual(RUSTLS_TLS_VERSION_TLSV1_2, tls_versions[0]);
    try std.testing.expectEqual(RUSTLS_TLS_VERSION_TLSV1_3, tls_versions[1]);

    cfg.version = CURL_SSLVERSION_TLSv1_2;
    cfg.version_max = CR_SSLVERSION_MAX_TLSv1_2;
    try std.testing.expectEqual(CURLE_OK, cr_set_ssl_version_min_max(null, &cfg, &tls_versions, &tls_versions_len));
    try std.testing.expectEqual(@as(usize, 1), tls_versions_len);
    try std.testing.expectEqual(RUSTLS_TLS_VERSION_TLSV1_2, tls_versions[0]);

    cfg.version = CURL_SSLVERSION_TLSv1_3;
    cfg.version_max = CURL_SSLVERSION_MAX_TLSv1_3;
    try std.testing.expectEqual(CURLE_OK, cr_set_ssl_version_min_max(null, &cfg, &tls_versions, &tls_versions_len));
    try std.testing.expectEqual(@as(usize, 1), tls_versions_len);
    try std.testing.expectEqual(RUSTLS_TLS_VERSION_TLSV1_3, tls_versions[0]);

    // min TLS 1.3 with max TLS 1.2 -> CURLE_BAD_FUNCTION_ARGUMENT
    cfg.version = CURL_SSLVERSION_TLSv1_3;
    cfg.version_max = CR_SSLVERSION_MAX_TLSv1_2;
    try std.testing.expectEqual(CURLE_BAD_FUNCTION_ARGUMENT, cr_set_ssl_version_min_max(null, &cfg, &tls_versions, &tls_versions_len));
}

test "rustls cipher suite walk and selection" {
    for (ciphers_id_map) |entry| {
        var buf: [64]u8 = @splat(0);
        @memcpy(buf[0..entry.name.len], entry.name);
        var ptr: ?[*:0]const u8 = @ptrCast(&buf);
        var end: ?[*:0]const u8 = null;
        try std.testing.expectEqual(entry.id, cr_cipher_suite_walk_str(&ptr, &end));
    }

    if (comptime use_rustls) {
        const default_len = rustls_ext.rustls_default_crypto_provider_ciphersuites_len();
        try std.testing.expect(default_len >= 9);

        var selected: [16]*const rustls_supported_ciphersuite = undefined;
        var selected_len: usize = default_len;
        cr_get_selected_ciphers(
            null,
            "TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256:TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256",
            "TLS13_AES_128_GCM_SHA256",
            &selected,
            &selected_len,
        );
        try std.testing.expectEqual(@as(usize, 2), selected_len);
        try std.testing.expectEqual(@as(u16, 0x1301), rustls_ext.rustls_supported_ciphersuite_get_suite(selected[0]));
        try std.testing.expectEqual(@as(u16, 0xc02f), rustls_ext.rustls_supported_ciphersuite_get_suite(selected[1]));

        selected_len = default_len;
        cr_get_selected_ciphers(
            null,
            "NOT_A_CIPHER",
            "ALSO_NOT_A_CIPHER",
            &selected,
            &selected_len,
        );
        try std.testing.expectEqual(@as(usize, 0), selected_len);
    }
}

test "rustls loopback TLS handshake and HTTPS GET via curl_easy_perform" {
    if (comptime !use_rustls) return;

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

    const curl_c = struct {
        const CURLoption = c_uint;
        const CURLOPTTYPE_LONG: CURLoption = 0;
        const CURLOPTTYPE_OBJECTPOINT: CURLoption = 10000;
        const CURLOPTTYPE_FUNCTIONPOINT: CURLoption = 20000;
        const CURLOPTTYPE_BLOB: CURLoption = 40000;

        const CURLOPT_WRITEDATA: CURLoption = CURLOPTTYPE_OBJECTPOINT + 1;
        const CURLOPT_URL: CURLoption = CURLOPTTYPE_OBJECTPOINT + 2;
        const CURLOPT_WRITEFUNCTION: CURLoption = CURLOPTTYPE_FUNCTIONPOINT + 11;
        const CURLOPT_SSL_VERIFYPEER: CURLoption = CURLOPTTYPE_LONG + 64;
        const CURLOPT_SSL_VERIFYHOST: CURLoption = CURLOPTTYPE_LONG + 81;
        const CURLOPT_NOSIGNAL: CURLoption = CURLOPTTYPE_LONG + 99;
        const CURLOPT_TIMEOUT_MS: CURLoption = CURLOPTTYPE_LONG + 155;
        const CURLOPT_CERTINFO: CURLoption = CURLOPTTYPE_LONG + 172;
        const CURLOPT_RESOLVE: CURLoption = CURLOPTTYPE_OBJECTPOINT + 203;
        const CURLOPT_CAINFO_BLOB: CURLoption = CURLOPTTYPE_BLOB + 309;

        const CURLINFO = c_uint;
        const CURLINFO_RESPONSE_CODE: CURLINFO = 0x200000 + 2;
        const CURLINFO_CERTINFO: CURLINFO = 0x400000 + 34;

        const CURL_BLOB_COPY: c_uint = 1;

        extern fn curl_easy_init() callconv(.c) ?*anyopaque;
        extern fn curl_easy_cleanup(handle: ?*anyopaque) callconv(.c) void;
        extern fn curl_easy_setopt(handle: ?*anyopaque, option: CURLoption, ...) callconv(.c) CURLcode;
        extern fn curl_easy_perform(handle: ?*anyopaque) callconv(.c) CURLcode;
        extern fn curl_easy_getinfo(handle: ?*anyopaque, info: CURLINFO, ...) callconv(.c) CURLcode;
        extern fn curl_slist_append(list: ?*containers.curl_slist, data: [*:0]const u8) callconv(.c) ?*containers.curl_slist;
        extern fn curl_slist_free_all(list: ?*containers.curl_slist) callconv(.c) void;
    };

    const sock_c = struct {
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

        extern "c" fn socket(domain: c_int, sock_type: c_int, protocol: c_int) c_int;
        extern "c" fn setsockopt(sockfd: c_int, level: c_int, optname: c_int, optval: *const anyopaque, optlen: u32) c_int;
        extern "c" fn bind(sockfd: c_int, addr: *const sockaddr_in, addrlen: u32) c_int;
        extern "c" fn listen(sockfd: c_int, backlog: c_int) c_int;
        extern "c" fn getsockname(sockfd: c_int, addr: *sockaddr_in, addrlen: *u32) c_int;
        extern "c" fn accept(sockfd: c_int, addr: ?*anyopaque, addrlen: ?*u32) c_int;
        extern "c" fn recv(sockfd: c_int, buf: [*]u8, len: usize, flags: c_int) isize;
        extern "c" fn send(sockfd: c_int, buf: [*]const u8, len: usize, flags: c_int) isize;
        extern "c" fn close(fd: c_int) c_int;

        fn setTimeouts(fd: c_int) void {
            if (builtin.os.tag == .linux) {
                const tv = timeval{ .tv_sec = 5, .tv_usec = 0 };
                _ = setsockopt(fd, SOL_SOCKET, SO_RCVTIMEO, &tv, @sizeOf(timeval));
                _ = setsockopt(fd, SOL_SOCKET, SO_SNDTIMEO, &tv, @sizeOf(timeval));
            }
        }

        fn srvReadCb(userdata: ?*anyopaque, buf: [*]u8, n: usize, out_n: *usize) callconv(.c) rustls_io_result {
            const fd_ptr: *const c_int = @ptrCast(@alignCast(userdata.?));
            const r = recv(fd_ptr.*, buf, n, 0);
            if (r < 0) {
                out_n.* = 0;
                return EINVAL_VAL;
            }
            out_n.* = @intCast(r);
            return 0;
        }

        fn srvWriteCb(userdata: ?*anyopaque, buf: [*]const u8, n: usize, out_n: *usize) callconv(.c) rustls_io_result {
            const fd_ptr: *const c_int = @ptrCast(@alignCast(userdata.?));
            const w = send(fd_ptr.*, buf, n, 0);
            if (w < 0) {
                out_n.* = 0;
                return EINVAL_VAL;
            }
            out_n.* = @intCast(w);
            return 0;
        }

        fn serveRustlsOnce(listen_fd: c_int) void {
            var client_fd = accept(listen_fd, null, null);
            if (client_fd < 0) return;
            defer _ = close(client_fd);
            setTimeouts(client_fd);

            var ckey: ?*const rustls_certified_key = null;
            if (rustls_ext.rustls_certified_key_build(
                test_server_cert_pem.ptr,
                test_server_cert_pem.len,
                test_server_key_pem.ptr,
                test_server_key_pem.len,
                &ckey,
            ) != RUSTLS_RESULT_OK or ckey == null) return;
            defer rustls_ext.rustls_certified_key_free(ckey);

            const sbuilder = rustls_ext.rustls_server_config_builder_new() orelse return;
            const ckeys = [1]*const rustls_certified_key{ckey.?};
            if (rustls_ext.rustls_server_config_builder_set_certified_keys(sbuilder, &ckeys, 1) != RUSTLS_RESULT_OK) {
                rustls_ext.rustls_server_config_builder_free(sbuilder);
                return;
            }

            var sconfig: ?*const rustls_server_config = null;
            if (rustls_ext.rustls_server_config_builder_build(sbuilder, &sconfig) != RUSTLS_RESULT_OK or sconfig == null) {
                return;
            }
            defer rustls_ext.rustls_server_config_free(sconfig);

            var sconn: ?*rustls_connection = null;
            if (rustls_ext.rustls_server_connection_new(sconfig.?, &sconn) != RUSTLS_RESULT_OK or sconn == null) return;
            defer rustls_ext.rustls_connection_free(sconn);

            const conn = sconn.?;
            while (rustls_ext.rustls_connection_is_handshaking(conn)) {
                while (rustls_ext.rustls_connection_wants_write(conn)) {
                    var nw: usize = 0;
                    if (rustls_ext.rustls_connection_write_tls(conn, srvWriteCb, &client_fd, &nw) != 0) return;
                }
                if (rustls_ext.rustls_connection_wants_read(conn)) {
                    var nr: usize = 0;
                    if (rustls_ext.rustls_connection_read_tls(conn, srvReadCb, &client_fd, &nr) != 0 or nr == 0) return;
                    if (rustls_ext.rustls_connection_process_new_packets(conn) != RUSTLS_RESULT_OK) {
                        while (rustls_ext.rustls_connection_wants_write(conn)) {
                            var nw: usize = 0;
                            _ = rustls_ext.rustls_connection_write_tls(conn, srvWriteCb, &client_fd, &nw);
                        }
                        return;
                    }
                }
            }
            while (rustls_ext.rustls_connection_wants_write(conn)) {
                var nw: usize = 0;
                if (rustls_ext.rustls_connection_write_tls(conn, srvWriteCb, &client_fd, &nw) != 0) return;
            }

            var req_buf: [512]u8 = undefined;
            var req_n: usize = 0;
            while (req_n == 0) {
                if (rustls_ext.rustls_connection_wants_read(conn)) {
                    var nr: usize = 0;
                    if (rustls_ext.rustls_connection_read_tls(conn, srvReadCb, &client_fd, &nr) != 0 or nr == 0) return;
                    if (rustls_ext.rustls_connection_process_new_packets(conn) != RUSTLS_RESULT_OK) return;
                }
                const rr = rustls_ext.rustls_connection_read(conn, &req_buf, req_buf.len, &req_n);
                if (rr == RUSTLS_RESULT_PLAINTEXT_EMPTY) continue;
                if (rr != RUSTLS_RESULT_OK) return;
            }

            const resp = "HTTP/1.1 200 OK\r\nContent-Length: 2\r\nConnection: close\r\n\r\nok";
            var plain_nw: usize = 0;
            if (rustls_ext.rustls_connection_write(conn, resp.ptr, resp.len, &plain_nw) != RUSTLS_RESULT_OK) return;
            rustls_ext.rustls_connection_send_close_notify(conn);
            while (rustls_ext.rustls_connection_wants_write(conn)) {
                var nw: usize = 0;
                if (rustls_ext.rustls_connection_write_tls(conn, srvWriteCb, &client_fd, &nw) != 0) return;
            }
        }

        const ResponseBuf = struct {
            data: [256]u8 = undefined,
            len: usize = 0,
        };

        fn writeCallback(ptr: [*]const u8, size: usize, nmemb: usize, userdata: ?*ResponseBuf) callconv(.c) usize {
            const total = size * nmemb;
            const rbuf = userdata orelse return total;
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
            ca_pem: [:0]const u8,
            verifypeer: c_long = 1,
            verifyhost: c_long = 2,
            certinfo: bool = false,
        };

        const TransferOutcome = struct {
            code: CURLcode,
            status_code: c_long = 0,
            body_ok: bool = false,
            certinfo_certs: c_int = 0,
            certinfo_has_subject: bool = false,
        };

        fn runTransfer(opts: TransferOpts) !TransferOutcome {
            const listen_fd = socket(AF_INET, SOCK_STREAM, 0);
            try std.testing.expect(listen_fd >= 0);
            defer _ = close(listen_fd);

            const one: c_int = 1;
            _ = setsockopt(listen_fd, SOL_SOCKET, SO_REUSEADDR, &one, @sizeOf(c_int));

            var bind_addr = sockaddr_in{
                .sin_family = AF_INET,
                .sin_port = 0,
                .sin_addr = std.mem.nativeToBig(u32, 0x7f000001),
            };
            try std.testing.expectEqual(@as(c_int, 0), bind(listen_fd, &bind_addr, @sizeOf(sockaddr_in)));
            try std.testing.expectEqual(@as(c_int, 0), listen(listen_fd, 4));
            setTimeouts(listen_fd);

            var bound_addr = sockaddr_in{};
            var addr_len: u32 = @sizeOf(sockaddr_in);
            try std.testing.expectEqual(@as(c_int, 0), getsockname(listen_fd, &bound_addr, &addr_len));
            const port = std.mem.bigToNative(u16, bound_addr.sin_port);

            const srv_thread = try std.Thread.spawn(.{}, serveRustlsOnce, .{listen_fd});
            defer srv_thread.join();

            const easy = curl_c.curl_easy_init() orelse return error.EasyInitFailed;
            defer curl_c.curl_easy_cleanup(easy);

            var url_buf: [128:0]u8 = undefined;
            const url_s = try std.fmt.bufPrint(&url_buf, "https://{s}:{d}/test", .{ opts.hostname, port });
            url_buf[url_s.len] = 0;
            const url: [*:0]const u8 = &url_buf;

            var resolve_buf: [128:0]u8 = undefined;
            const resolve_s = try std.fmt.bufPrint(&resolve_buf, "{s}:{d}:127.0.0.1", .{ opts.hostname, port });
            resolve_buf[resolve_s.len] = 0;
            const resolve_list = curl_c.curl_slist_append(null, &resolve_buf) orelse return error.SlistFailed;
            defer curl_c.curl_slist_free_all(resolve_list);

            var resp_buf = ResponseBuf{};
            var blob = CurlBlob{
                .data = mem.toRawPtr(opts.ca_pem.ptr),
                .len = opts.ca_pem.len,
                .flags = curl_c.CURL_BLOB_COPY,
            };

            try std.testing.expectEqual(CURLE_OK, curl_c.curl_easy_setopt(easy, curl_c.CURLOPT_URL, url.ptr));
            try std.testing.expectEqual(CURLE_OK, curl_c.curl_easy_setopt(easy, curl_c.CURLOPT_RESOLVE, resolve_list));
            try std.testing.expectEqual(CURLE_OK, curl_c.curl_easy_setopt(easy, curl_c.CURLOPT_NOSIGNAL, @as(c_long, 1)));
            try std.testing.expectEqual(CURLE_OK, curl_c.curl_easy_setopt(easy, curl_c.CURLOPT_TIMEOUT_MS, @as(c_long, 5000)));
            try std.testing.expectEqual(CURLE_OK, curl_c.curl_easy_setopt(easy, curl_c.CURLOPT_WRITEFUNCTION, &writeCallback));
            try std.testing.expectEqual(CURLE_OK, curl_c.curl_easy_setopt(easy, curl_c.CURLOPT_WRITEDATA, &resp_buf));
            try std.testing.expectEqual(CURLE_OK, curl_c.curl_easy_setopt(easy, curl_c.CURLOPT_SSL_VERIFYPEER, opts.verifypeer));
            try std.testing.expectEqual(CURLE_OK, curl_c.curl_easy_setopt(easy, curl_c.CURLOPT_SSL_VERIFYHOST, opts.verifyhost));
            try std.testing.expectEqual(CURLE_OK, curl_c.curl_easy_setopt(easy, curl_c.CURLOPT_CAINFO_BLOB, &blob));
            if (opts.certinfo) {
                try std.testing.expectEqual(CURLE_OK, curl_c.curl_easy_setopt(easy, curl_c.CURLOPT_CERTINFO, @as(c_long, 1)));
            }

            const code = curl_c.curl_easy_perform(easy);
            var outcome = TransferOutcome{
                .code = code,
                .body_ok = std.mem.eql(u8, resp_buf.data[0..resp_buf.len], "ok"),
            };

            if (code == CURLE_OK) {
                _ = curl_c.curl_easy_getinfo(easy, curl_c.CURLINFO_RESPONSE_CODE, &outcome.status_code);
                if (opts.certinfo) {
                    var ci_ptr: ?*vtls_backends.CurlCertinfo = null;
                    if (curl_c.curl_easy_getinfo(easy, curl_c.CURLINFO_CERTINFO, &ci_ptr) == CURLE_OK) {
                        if (ci_ptr) |ci| {
                            outcome.certinfo_certs = ci.num_of_certs;
                            if (ci.num_of_certs > 0 and ci.certinfo != null) {
                                var node = ci.certinfo.?[0];
                                while (node) |cur| : (node = cur.next) {
                                    if (cur.data) |entry| {
                                        const entry_str = std.mem.span(entry);
                                        if (std.mem.startsWith(u8, entry_str, "Subject:") or
                                            std.mem.startsWith(u8, entry_str, "Cert:"))
                                        {
                                            outcome.certinfo_has_subject = true;
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            return outcome;
        }
    };

    // 1. Trusted CA via CURLOPT_CAINFO_BLOB + CURLOPT_CERTINFO -> CURLE_OK & populated certinfo
    {
        const res = try sock_c.runTransfer(.{
            .ca_pem = test_ca_cert_pem,
            .certinfo = true,
        });
        try std.testing.expectEqual(CURLE_OK, res.code);
        try std.testing.expectEqual(@as(c_long, 200), res.status_code);
        try std.testing.expect(res.body_ok);
        try std.testing.expect(res.certinfo_certs >= 1);
        try std.testing.expect(res.certinfo_has_subject);
    }

    // 2. Untrusted CA with verifypeer=1 -> CURLE_PEER_FAILED_VERIFICATION
    {
        const res = try sock_c.runTransfer(.{
            .ca_pem = test_untrusted_ca_cert_pem,
            .verifypeer = 1,
        });
        try std.testing.expectEqual(CURLE_PEER_FAILED_VERIFICATION, res.code);
    }

    // 3. Untrusted CA with verifypeer=0 (cr_verify_none) -> CURLE_OK
    {
        const res = try sock_c.runTransfer(.{
            .ca_pem = test_untrusted_ca_cert_pem,
            .verifypeer = 0,
        });
        try std.testing.expectEqual(CURLE_OK, res.code);
        try std.testing.expectEqual(@as(c_long, 200), res.status_code);
        try std.testing.expect(res.body_ok);
    }

    // 4. Hostname mismatch against SAN=DNS:localhost -> CURLE_PEER_FAILED_VERIFICATION
    {
        const res = try sock_c.runTransfer(.{
            .hostname = "wrong.localhost",
            .ca_pem = test_ca_cert_pem,
            .verifypeer = 1,
            .verifyhost = 2,
        });
        try std.testing.expectEqual(CURLE_PEER_FAILED_VERIFICATION, res.code);
    }
}
