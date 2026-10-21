const std = @import("std");
const backend_options = @import("backend_options");
const mem = @import("mem.zig");
const vtls_core = @import("vtls_core.zig");
const vtls_scache_asn1 = @import("vtls_scache_asn1.zig");
const vtls_backends = @import("vtls_backends.zig");
const vtls_impl = vtls_backends.vtls_impl;
const c_ext = vtls_backends.c_ext;

pub const use_wolfssl = backend_options.ssl == .wolfssl;

const CURLcode = vtls_impl.CURLcode;
const CURLE_OK = vtls_impl.CURLE_OK;
const CURLE_UNSUPPORTED_PROTOCOL = vtls_impl.CURLE_UNSUPPORTED_PROTOCOL;
const CURLE_FAILED_INIT = vtls_impl.CURLE_FAILED_INIT;
const CURLE_NOT_BUILT_IN = vtls_impl.CURLE_NOT_BUILT_IN;
const CURLE_OUT_OF_MEMORY = vtls_impl.CURLE_OUT_OF_MEMORY;
const CURLE_SSL_CONNECT_ERROR = vtls_impl.CURLE_SSL_CONNECT_ERROR;
const CURLE_BAD_FUNCTION_ARGUMENT = vtls_impl.CURLE_BAD_FUNCTION_ARGUMENT;
const CURLE_SEND_ERROR = vtls_impl.CURLE_SEND_ERROR;
const CURLE_RECV_ERROR = vtls_impl.CURLE_RECV_ERROR;
const CURLE_SSL_CERTPROBLEM = vtls_impl.CURLE_SSL_CERTPROBLEM;
const CURLE_SSL_CIPHER = vtls_impl.CURLE_SSL_CIPHER;
const CURLE_PEER_FAILED_VERIFICATION = vtls_impl.CURLE_PEER_FAILED_VERIFICATION;
const CURLE_SSL_CACERT_BADFILE: CURLcode = 77;
const CURLE_SSL_SHUTDOWN_FAILED = vtls_impl.CURLE_SSL_SHUTDOWN_FAILED;
const CURLE_AGAIN = vtls_impl.CURLE_AGAIN;
const CURLE_SSL_CRL_BADFILE = vtls_impl.CURLE_SSL_CRL_BADFILE;
const CURLE_SSL_PINNEDPUBKEYNOTMATCH = vtls_impl.CURLE_SSL_PINNEDPUBKEYNOTMATCH;
const CURLE_SSL_CLIENTCERT = vtls_impl.CURLE_SSL_CLIENTCERT;

const CurlEasy = vtls_impl.CurlEasy;
const CurlCfilter = vtls_impl.CurlCfilter;
const SslConnectData = vtls_impl.SslConnectData;
const SslFilterConfig = vtls_impl.SslFilterConfig;
const SslPeer = vtls_impl.SslPeer;
const CurlBlob = vtls_impl.CurlBlob;
const CurlSslSession = vtls_backends.CurlSslSession;
const CurlTime = vtls_impl.CurlTime;

// ============================================================================
// wolfSSL C Types, Constants & Extern Declarations (wolfSSL 5.x ABI)
// ============================================================================

pub const WOLFSSL = opaque {};
pub const WOLFSSL_CTX = opaque {};
pub const WOLFSSL_METHOD = opaque {};
pub const WOLFSSL_SESSION = opaque {};
pub const WOLFSSL_X509 = opaque {};
pub const WOLFSSL_X509_STORE = opaque {};
pub const WOLFSSL_X509_NAME = opaque {};
pub const WOLFSSL_X509_PUBKEY = opaque {};
pub const WOLFSSL_X509_CHAIN = opaque {};
pub const WOLFSSL_EVP_PKEY = opaque {};
pub const WOLFSSL_BIO = opaque {};
pub const WOLFSSL_BIO_METHOD = opaque {};

pub const WOLFSSL_SUCCESS: c_int = 1;
const WOLFSSL_FAILURE: c_int = 0;
const SSL_SUCCESS: c_int = 1;
const SSL_FAILURE: c_int = 0;

const SSL_FILETYPE_ASN1: c_int = 2;
const SSL_FILETYPE_PEM: c_int = 1;
const SSL_FILETYPE_DEFAULT: c_int = 2;

const WOLFSSL_VERIFY_NONE: c_int = 0;
const WOLFSSL_VERIFY_PEER: c_int = 1;
const WOLFSSL_VERIFY_FAIL_IF_NO_PEER_CERT: c_int = 2;
const WOLFSSL_VERIFY_CLIENT_ONCE: c_int = 4;
const WOLFSSL_VERIFY_DEFAULT: c_int = 9;

const WOLFSSL_SESS_CACHE_OFF: c_long = 0x0000;

const WOLFSSL_SSLv3: c_int = 0;
const WOLFSSL_TLSV1: c_int = 1;
const WOLFSSL_TLSV1_1: c_int = 2;
const WOLFSSL_TLSV1_2: c_int = 3;
const WOLFSSL_TLSV1_3: c_int = 4;

const TLS1_VERSION: c_ushort = 0x0301;
const TLS1_1_VERSION: c_ushort = 0x0302;
const TLS1_2_VERSION: c_ushort = 0x0303;
const TLS1_3_VERSION: c_ushort = 0x0304;

const WOLFSSL_ERROR_NONE: c_int = 0;
const WOLFSSL_ERROR_WANT_READ: c_int = 2;
const WOLFSSL_ERROR_WANT_WRITE: c_int = 3;
const WOLFSSL_ERROR_SYSCALL: c_int = 5;
const WOLFSSL_ERROR_ZERO_RETURN: c_int = 6;

const WOLFSSL_CBIO_ERR_GENERAL: c_int = -1;
const WOLFSSL_CBIO_ERR_WANT_READ: c_int = -2;
const WOLFSSL_CBIO_ERR_WANT_WRITE: c_int = -2;
const WOLFSSL_CBIO_ERR_CONN_RST: c_int = -3;
const WOLFSSL_CBIO_ERR_ISR: c_int = -4;
const WOLFSSL_CBIO_ERR_CONN_CLOSE: c_int = -5;
const WOLFSSL_CBIO_ERR_TIMEOUT: c_int = -6;

const WOLFSSL_SNI_HOST_NAME: u8 = 0;
const WOLFSSL_ALPN_CONTINUE_ON_MISMATCH: u8 = 2;
const WOLFSSL_ALPN_FAILED_ON_MISMATCH: u8 = 4;

const WOLFSSL_CRL_CHECK: c_int = 0x01;
const WOLFSSL_CRL_CHECKALL: c_int = 0x02;

const WOLFSSL_MAX_ERROR_SZ: usize = 80;
const ASN_NO_SIGNER_E: c_int = -188;
const ASN_BEFORE_DATE_E: c_int = -150;
const ASN_AFTER_DATE_E: c_int = -151;
const ASN_PARSE_E: c_int = -140;
const MEMORY_E: c_int = -125;
const BUFFER_E: c_int = -132;
const DOMAIN_NAME_MISMATCH: c_int = -322;
const SECURE_RENEGOTIATION_E: c_int = -384;

const X509_V_OK: c_long = 0;
const X509_V_ERR_UNABLE_TO_GET_ISSUER_CERT_LOCALLY: c_long = 20;

const WOLFSSL_BIO_UNSET: c_int = -1;
const BIO_CTRL_FLUSH: c_int = 11;
const WOLFSSL_BIO_FLAG_READ: c_int = 0x01;
const WOLFSSL_BIO_FLAG_WRITE: c_int = 0x02;
const WOLFSSL_BIO_FLAG_IO_SPECIAL: c_int = 0x04;
const WOLFSSL_BIO_FLAG_RWS: c_int = WOLFSSL_BIO_FLAG_READ | WOLFSSL_BIO_FLAG_WRITE | WOLFSSL_BIO_FLAG_IO_SPECIAL;
const WOLFSSL_BIO_FLAG_RETRY: c_int = 0x08;

const SSL_DEFAULT_CIPHER_LIST: [*:0]const u8 =
    "TLS_AES_256_GCM_SHA384:" ++
    "TLS_CHACHA20_POLY1305_SHA256:" ++
    "TLS_AES_128_GCM_SHA256:" ++
    "TLS_AES_128_CCM_SHA256:" ++
    "TLS_AES_128_CCM_8_SHA256:" ++
    "ECDHE-ECDSA-AES128-GCM-SHA256:" ++
    "ECDHE-RSA-AES128-GCM-SHA256:" ++
    "ECDHE-ECDSA-AES256-GCM-SHA384:" ++
    "ECDHE-RSA-AES256-GCM-SHA384:" ++
    "ECDHE-ECDSA-CHACHA20-POLY1305:" ++
    "ECDHE-RSA-CHACHA20-POLY1305:" ++
    "ECDHE-ECDSA-AES128-SHA256:" ++
    "ECDHE-RSA-AES128-SHA256:" ++
    "ECDHE-ECDSA-AES256-SHA384:" ++
    "ECDHE-RSA-AES256-SHA384:" ++
    "DHE-RSA-AES128-GCM-SHA256:" ++
    "DHE-RSA-AES256-GCM-SHA384:" ++
    "DHE-RSA-CHACHA20-POLY1305:" ++
    "DHE-RSA-AES128-SHA256:" ++
    "DHE-RSA-AES256-SHA256";

const WcSha256Storage = extern struct {
    words: [64]u64 align(16) = @splat(0),
};

const WcRngStorage = extern struct {
    words: [64]u64 align(16) = @splat(0),
};

const CallbackIORecv = *const fn (ssl: ?*WOLFSSL, buf: ?[*]u8, sz: c_int, ctx: ?*anyopaque) callconv(.c) c_int;
const CallbackIOSend = *const fn (ssl: ?*WOLFSSL, buf: ?[*]const u8, sz: c_int, ctx: ?*anyopaque) callconv(.c) c_int;
const WcPasswdCb = *const fn (buf: [*]u8, sz: c_int, rwflag: c_int, userdata: ?*anyopaque) callconv(.c) c_int;
const NewSessionCb = *const fn (ssl: ?*WOLFSSL, session: ?*WOLFSSL_SESSION) callconv(.c) c_int;
const KeylogCb = *const fn (ssl: ?*const WOLFSSL, line: ?[*:0]const u8) callconv(.c) void;

const BioMethodWriteCb = *const fn (bio: ?*WOLFSSL_BIO, buf: ?[*]const u8, blen: c_int) callconv(.c) c_int;
const BioMethodReadCb = *const fn (bio: ?*WOLFSSL_BIO, buf: ?[*]u8, blen: c_int) callconv(.c) c_int;
const BioMethodPutsCb = *const fn (bio: ?*WOLFSSL_BIO, str: ?[*:0]const u8) callconv(.c) c_int;
const BioMethodGetsCb = *const fn (bio: ?*WOLFSSL_BIO, buf: ?[*]u8, size: c_int) callconv(.c) c_int;
const BioMethodCtrlCb = *const fn (bio: ?*WOLFSSL_BIO, cmd: c_int, num: c_long, ptr: ?*anyopaque) callconv(.c) c_long;
const BioMethodCreateCb = *const fn (bio: ?*WOLFSSL_BIO) callconv(.c) c_int;
const BioMethodDestroyCb = *const fn (bio: ?*WOLFSSL_BIO) callconv(.c) c_int;

pub const wssl_ext = struct {
    pub extern "c" fn wolfSSL_Init() callconv(.c) c_int;
    pub extern "c" fn wolfSSL_Cleanup() callconv(.c) c_int;
    pub extern "c" fn wolfSSL_lib_version() callconv(.c) ?[*:0]const u8;

    pub extern "c" fn wolfSSLv23_client_method() callconv(.c) ?*WOLFSSL_METHOD;
    pub extern "c" fn wolfSSL_CTX_new(method: ?*WOLFSSL_METHOD) callconv(.c) ?*WOLFSSL_CTX;
    pub extern "c" fn wolfSSL_CTX_free(ctx: ?*WOLFSSL_CTX) callconv(.c) void;

    pub extern "c" fn wolfSSL_CTX_set_min_proto_version(ctx: *WOLFSSL_CTX, version: c_int) callconv(.c) c_int;
    pub extern "c" fn wolfSSL_CTX_set_max_proto_version(ctx: *WOLFSSL_CTX, version: c_int) callconv(.c) c_int;
    pub extern "c" fn wolfSSL_CTX_set_cipher_list(ctx: *WOLFSSL_CTX, list: [*:0]const u8) callconv(.c) c_int;
    pub extern "c" fn wolfSSL_CTX_set1_curves_list(ctx: *WOLFSSL_CTX, names: [*:0]const u8) callconv(.c) c_int;
    pub extern "c" fn wolfSSL_CTX_set_options(ctx: *WOLFSSL_CTX, opt: c_long) callconv(.c) c_long;

    pub extern "c" fn wolfSSL_CTX_load_verify_locations(ctx: *WOLFSSL_CTX, file: ?[*:0]const u8, path: ?[*:0]const u8) callconv(.c) c_int;
    pub extern "c" fn wolfSSL_CTX_load_verify_buffer(ctx: *WOLFSSL_CTX, in: [*]const u8, sz: c_long, format: c_int) callconv(.c) c_int;
    pub extern "c" fn wolfSSL_CTX_load_system_CA_certs(ctx: *WOLFSSL_CTX) callconv(.c) c_int;

    pub extern "c" fn wolfSSL_CTX_use_certificate_file(ctx: *WOLFSSL_CTX, file: [*:0]const u8, format: c_int) callconv(.c) c_int;
    pub extern "c" fn wolfSSL_CTX_use_certificate_chain_file(ctx: *WOLFSSL_CTX, file: [*:0]const u8) callconv(.c) c_int;
    pub extern "c" fn wolfSSL_CTX_use_certificate_buffer(ctx: *WOLFSSL_CTX, in: [*]const u8, sz: c_long, format: c_int) callconv(.c) c_int;
    pub extern "c" fn wolfSSL_CTX_use_certificate_chain_buffer(ctx: *WOLFSSL_CTX, in: [*]const u8, sz: c_long) callconv(.c) c_int;
    pub extern "c" fn wolfSSL_CTX_use_PrivateKey_file(ctx: *WOLFSSL_CTX, file: [*:0]const u8, format: c_int) callconv(.c) c_int;
    pub extern "c" fn wolfSSL_CTX_use_PrivateKey_buffer(ctx: *WOLFSSL_CTX, in: [*]const u8, sz: c_long, format: c_int) callconv(.c) c_int;

    pub extern "c" fn wolfSSL_CTX_set_default_passwd_cb(ctx: *WOLFSSL_CTX, cb: ?WcPasswdCb) callconv(.c) void;
    pub extern "c" fn wolfSSL_CTX_set_default_passwd_cb_userdata(ctx: *WOLFSSL_CTX, userdata: ?*anyopaque) callconv(.c) void;

    pub extern "c" fn wolfSSL_CTX_set_verify(ctx: *WOLFSSL_CTX, mode: c_int, verify_callback: ?*const anyopaque) callconv(.c) void;
    pub extern "c" fn wolfSSL_CTX_SetIORecv(ctx: *WOLFSSL_CTX, cb: CallbackIORecv) callconv(.c) void;
    pub extern "c" fn wolfSSL_CTX_SetIOSend(ctx: *WOLFSSL_CTX, cb: CallbackIOSend) callconv(.c) void;

    pub extern "c" fn wolfSSL_CTX_set_session_cache_mode(ctx: *WOLFSSL_CTX, mode: c_long) callconv(.c) c_long;
    pub extern "c" fn wolfSSL_CTX_sess_set_new_cb(ctx: *WOLFSSL_CTX, cb: ?NewSessionCb) callconv(.c) void;

    pub extern "c" fn wolfSSL_CTX_get_cert_store(ctx: *WOLFSSL_CTX) callconv(.c) ?*WOLFSSL_X509_STORE;
    pub extern "c" fn wolfSSL_CTX_set_cert_store(ctx: *WOLFSSL_CTX, store: *WOLFSSL_X509_STORE) callconv(.c) void;
    pub extern "c" fn wolfSSL_X509_STORE_new() callconv(.c) ?*WOLFSSL_X509_STORE;
    pub extern "c" fn wolfSSL_X509_STORE_free(store: ?*WOLFSSL_X509_STORE) callconv(.c) void;
    pub extern "c" fn wolfSSL_X509_STORE_up_ref(store: *WOLFSSL_X509_STORE) callconv(.c) c_int;

    pub extern "c" fn wolfSSL_new(ctx: *WOLFSSL_CTX) callconv(.c) ?*WOLFSSL;
    pub extern "c" fn wolfSSL_free(ssl: ?*WOLFSSL) callconv(.c) void;
    pub extern "c" fn wolfSSL_SetIOReadCtx(ssl: *WOLFSSL, ctx: ?*anyopaque) callconv(.c) void;
    pub extern "c" fn wolfSSL_SetIOWriteCtx(ssl: *WOLFSSL, ctx: ?*anyopaque) callconv(.c) void;
    pub extern "c" fn wolfSSL_set_app_data(ssl: *WOLFSSL, arg: ?*anyopaque) callconv(.c) c_int;
    pub extern "c" fn wolfSSL_get_app_data(ssl: *const WOLFSSL) callconv(.c) ?*anyopaque;

    pub extern "c" fn wolfSSL_UseSNI(ssl: *WOLFSSL, sni_type: u8, data: *const anyopaque, size: c_ushort) callconv(.c) c_int;
    pub extern "c" fn wolfSSL_check_domain_name(ssl: *WOLFSSL, dn: [*:0]const u8) callconv(.c) c_int;
    pub extern "c" fn wolfSSL_UseALPN(ssl: *WOLFSSL, protocol_name_list: [*]u8, protocol_name_list_sz: c_uint, options: u8) callconv(.c) c_int;
    pub extern "c" fn wolfSSL_ALPN_GetProtocol(ssl: *WOLFSSL, protocol_name: *?[*]u8, size: *c_ushort) callconv(.c) c_int;
    pub extern "c" fn wolfSSL_UseSupportedCurve(ssl: *WOLFSSL, name: c_ushort) callconv(.c) c_int;
    pub extern "c" fn wolfSSL_UseSecureRenegotiation(ssl: *WOLFSSL) callconv(.c) c_int;

    pub extern "c" fn wolfSSL_EnableCRL(ssl: *WOLFSSL, options: c_int) callconv(.c) c_int;
    pub extern "c" fn wolfSSL_LoadCRLFile(ssl: *WOLFSSL, file: [*:0]const u8, format: c_int, monitor: c_int) callconv(.c) c_int;

    pub extern "c" fn wolfSSL_set_session(ssl: *WOLFSSL, session: *WOLFSSL_SESSION) callconv(.c) c_int;
    pub extern "c" fn wolfSSL_SESSION_dup(session: *WOLFSSL_SESSION) callconv(.c) ?*WOLFSSL_SESSION;
    pub extern "c" fn wolfSSL_SESSION_free(session: ?*WOLFSSL_SESSION) callconv(.c) void;
    pub extern "c" fn wolfSSL_SESSION_get_timeout(session: *const WOLFSSL_SESSION) callconv(.c) c_long;
    pub extern "c" fn wolfSSL_i2d_SSL_SESSION(session: *WOLFSSL_SESSION, pp: ?*?[*]u8) callconv(.c) c_int;
    pub extern "c" fn wolfSSL_d2i_SSL_SESSION(session: ?*?*WOLFSSL_SESSION, pp: *[*]const u8, length: c_long) callconv(.c) ?*WOLFSSL_SESSION;
    pub extern "c" fn wolfSSL_session_reused(ssl: *WOLFSSL) callconv(.c) c_int;
    pub extern "c" fn wolfSSL_version(ssl: *const WOLFSSL) callconv(.c) c_int;

    pub extern "c" fn wolfSSL_connect(ssl: *WOLFSSL) callconv(.c) c_int;
    pub extern "c" fn wolfSSL_write(ssl: *WOLFSSL, data: ?*const anyopaque, sz: c_int) callconv(.c) c_int;
    pub extern "c" fn wolfSSL_read(ssl: *WOLFSSL, data: [*]u8, sz: c_int) callconv(.c) c_int;
    pub extern "c" fn wolfSSL_pending(ssl: *const WOLFSSL) callconv(.c) c_int;
    pub extern "c" fn wolfSSL_shutdown(ssl: *WOLFSSL) callconv(.c) c_int;
    pub extern "c" fn wolfSSL_get_shutdown(ssl: *const WOLFSSL) callconv(.c) c_int;

    pub extern "c" fn wolfSSL_get_error(ssl: *WOLFSSL, ret: c_int) callconv(.c) c_int;
    pub extern "c" fn wolfSSL_ERR_error_string(errNumber: c_ulong, data: [*]u8) callconv(.c) [*:0]u8;
    pub extern "c" fn wolfSSL_ERR_clear_error() callconv(.c) void;
    pub extern "c" fn wolfSSL_get_verify_result(ssl: *const WOLFSSL) callconv(.c) c_long;

    pub extern "c" fn wolfSSL_get_version(ssl: *const WOLFSSL) callconv(.c) ?[*:0]const u8;
    pub extern "c" fn wolfSSL_get_cipher_name(ssl: *WOLFSSL) callconv(.c) ?[*:0]const u8;

    pub extern "c" fn wolfSSL_get_peer_certificate(ssl: *WOLFSSL) callconv(.c) ?*WOLFSSL_X509;
    pub extern "c" fn wolfSSL_X509_free(x509: ?*WOLFSSL_X509) callconv(.c) void;
    pub extern "c" fn wolfSSL_X509_check_ip_asc(x509: *WOLFSSL_X509, ipasc: [*:0]const u8, flags: c_uint) callconv(.c) c_int;
    pub extern "c" fn wolfSSL_X509_get_pubkey(x509: *WOLFSSL_X509) callconv(.c) ?*WOLFSSL_EVP_PKEY;
    pub extern "c" fn wolfSSL_EVP_PKEY_free(pkey: ?*WOLFSSL_EVP_PKEY) callconv(.c) void;
    pub extern "c" fn wolfSSL_i2d_PUBKEY(pkey: *WOLFSSL_EVP_PKEY, pp: *?[*]u8) callconv(.c) c_int;
    pub extern "c" fn wolfSSL_X509_get_der(x509: *WOLFSSL_X509, outSz: *c_int) callconv(.c) ?[*]const u8;

    pub extern "c" fn wolfSSL_get_peer_chain(ssl: *WOLFSSL) callconv(.c) ?*WOLFSSL_X509_CHAIN;
    pub extern "c" fn wolfSSL_get_chain_count(chain: *WOLFSSL_X509_CHAIN) callconv(.c) c_int;
    pub extern "c" fn wolfSSL_get_chain_length(chain: *WOLFSSL_X509_CHAIN, idx: c_int) callconv(.c) c_int;
    pub extern "c" fn wolfSSL_get_chain_cert(chain: *WOLFSSL_X509_CHAIN, idx: c_int) callconv(.c) ?[*]const u8;
    pub extern "c" fn wolfSSL_get_chain_X509(chain: *WOLFSSL_X509_CHAIN, idx: c_int) callconv(.c) ?*WOLFSSL_X509;
    pub extern "c" fn wolfSSL_PEM_write_bio_X509(bio: *WOLFSSL_BIO, x509: *WOLFSSL_X509) callconv(.c) c_int;

    pub extern "c" fn wolfSSL_KeepArrays(ssl: *WOLFSSL) callconv(.c) void;
    pub extern "c" fn wolfSSL_FreeArrays(ssl: *WOLFSSL) callconv(.c) void;
    pub extern "c" fn wolfSSL_GetVersion(ssl: *const WOLFSSL) callconv(.c) c_int;
    pub extern "c" fn wolfSSL_get_keys(
        ssl: *WOLFSSL,
        ms: *?[*]u8,
        msLen: *c_uint,
        sr: *?[*]u8,
        srLen: *c_uint,
        cr: *?[*]u8,
        crLen: *c_uint,
    ) callconv(.c) c_int;
    pub extern "c" fn wolfSSL_want_read(ssl: *WOLFSSL) callconv(.c) c_int;
    pub extern "c" fn wolfSSL_want_write(ssl: *WOLFSSL) callconv(.c) c_int;

    pub extern "c" fn wolfSSL_BIO_new(method: *const WOLFSSL_BIO_METHOD) callconv(.c) ?*WOLFSSL_BIO;
    pub extern "c" fn wolfSSL_BIO_free(bio: ?*WOLFSSL_BIO) callconv(.c) c_int;
    pub extern "c" fn wolfSSL_BIO_s_mem() callconv(.c) ?*const WOLFSSL_BIO_METHOD;
    pub extern "c" fn wolfSSL_BIO_get_mem_data(bio: *WOLFSSL_BIO, p: *?[*]const u8) callconv(.c) c_int;
    pub extern "c" fn wolfSSL_BIO_set_data(bio: *WOLFSSL_BIO, ptr: ?*anyopaque) callconv(.c) void;
    pub extern "c" fn wolfSSL_BIO_get_data(bio: *WOLFSSL_BIO) callconv(.c) ?*anyopaque;
    pub extern "c" fn wolfSSL_BIO_set_init(bio: *WOLFSSL_BIO, init: c_int) callconv(.c) void;
    pub extern "c" fn wolfSSL_BIO_set_shutdown(bio: *WOLFSSL_BIO, shut: c_int) callconv(.c) void;
    pub extern "c" fn wolfSSL_BIO_get_shutdown(bio: *WOLFSSL_BIO) callconv(.c) c_int;
    pub extern "c" fn wolfSSL_BIO_set_flags(bio: *WOLFSSL_BIO, flags: c_int) callconv(.c) void;
    pub extern "c" fn wolfSSL_BIO_clear_flags(bio: *WOLFSSL_BIO, flags: c_int) callconv(.c) void;
    pub extern "c" fn wolfSSL_BIO_meth_new(bio_type: c_int, name: [*:0]const u8) callconv(.c) ?*WOLFSSL_BIO_METHOD;
    pub extern "c" fn wolfSSL_BIO_meth_free(biom: ?*WOLFSSL_BIO_METHOD) callconv(.c) void;
    pub extern "c" fn wolfSSL_BIO_meth_set_write(biom: *WOLFSSL_BIO_METHOD, write: BioMethodWriteCb) callconv(.c) c_int;
    pub extern "c" fn wolfSSL_BIO_meth_set_read(biom: *WOLFSSL_BIO_METHOD, read: BioMethodReadCb) callconv(.c) c_int;
    pub extern "c" fn wolfSSL_BIO_meth_set_puts(biom: *WOLFSSL_BIO_METHOD, puts: BioMethodPutsCb) callconv(.c) c_int;
    pub extern "c" fn wolfSSL_BIO_meth_set_gets(biom: *WOLFSSL_BIO_METHOD, gets: BioMethodGetsCb) callconv(.c) c_int;
    pub extern "c" fn wolfSSL_BIO_meth_set_ctrl(biom: *WOLFSSL_BIO_METHOD, ctrl: BioMethodCtrlCb) callconv(.c) c_long;
    pub extern "c" fn wolfSSL_BIO_meth_set_create(biom: *WOLFSSL_BIO_METHOD, create: BioMethodCreateCb) callconv(.c) c_int;
    pub extern "c" fn wolfSSL_BIO_meth_set_destroy(biom: *WOLFSSL_BIO_METHOD, destroy: BioMethodDestroyCb) callconv(.c) c_int;
    pub extern "c" fn wolfSSL_set_bio(ssl: *WOLFSSL, rd: ?*WOLFSSL_BIO, wr: ?*WOLFSSL_BIO) callconv(.c) void;

    pub extern "c" fn wc_InitSha256(sha: *anyopaque) callconv(.c) c_int;
    pub extern "c" fn wc_Sha256Update(sha: *anyopaque, data: ?[*]const u8, len: u32) callconv(.c) c_int;
    pub extern "c" fn wc_Sha256Final(sha: *anyopaque, hash: [*]u8) callconv(.c) c_int;

    pub extern "c" fn wc_InitRng(rng: *anyopaque) callconv(.c) c_int;
    pub extern "c" fn wc_RNG_GenerateBlock(rng: *anyopaque, output: [*]u8, sz: c_uint) callconv(.c) c_int;
    pub extern "c" fn wc_FreeRng(rng: *anyopaque) callconv(.c) c_int;
    pub extern "c" fn wc_GetPubKeyDerFromCert(certDer: [*]const u8, certSz: u32, pubKeyDer: [*]u8, pubKeySz: *u32) callconv(.c) c_int;
};

// ============================================================================
// 1. Types & State (wssl_ssl_backend_data / WsslSslBackendData)
// ============================================================================

pub const WsslSslBackendData = extern struct {
    ssl_ctx: ?*WOLFSSL_CTX = null,
    ssl: ?*WOLFSSL = null,
    handle: ?*CurlEasy = null,
    io_result: CURLcode = CURLE_OK,
    io_flags: u8 = 0,
    flags: u8 = 0,

    pub fn x509_store_setup(self: *const WsslSslBackendData) bool {
        return (self.flags & 1) != 0;
    }
    pub fn set_x509_store_setup(self: *WsslSslBackendData, v: bool) void {
        if (v) self.flags |= 1 else self.flags &= ~@as(u8, 1);
    }

    pub fn shutting_down(self: *const WsslSslBackendData) bool {
        return (self.flags & 2) != 0;
    }
    pub fn set_shutting_down(self: *WsslSslBackendData, v: bool) void {
        if (v) self.flags |= 2 else self.flags &= ~@as(u8, 2);
    }
};

pub const WsslCtx = WsslSslBackendData;

const WsslX509Share = extern struct {
    CAfile: ?[*:0]u8,
    store: ?*WOLFSSL_X509_STORE,
    time: CurlTime,
};

var wssl_bio_cf_method: ?*WOLFSSL_BIO_METHOD = null;

// ============================================================================
// 2. Custom BIO / I/O Callbacks
// ============================================================================

fn wssl_bio_cf_create(bio: ?*WOLFSSL_BIO) callconv(.c) c_int {
    if (comptime !use_wolfssl) return 0;
    const b = bio orelse return 0;
    wssl_ext.wolfSSL_BIO_set_shutdown(b, 1);
    wssl_ext.wolfSSL_BIO_set_init(b, 1);
    wssl_ext.wolfSSL_BIO_set_data(b, null);
    return 1;
}

fn wssl_bio_cf_free(bio: ?*WOLFSSL_BIO) callconv(.c) c_int {
    if (comptime !use_wolfssl) return 0;
    if (bio == null) return 0;
    return 1;
}

fn wssl_bio_cf_ctrl(bio: ?*WOLFSSL_BIO, cmd: c_int, num: c_long, ptr: ?*anyopaque) callconv(.c) c_long {
    if (comptime !use_wolfssl) return 0;
    _ = num;
    _ = ptr;
    _ = bio;
    return switch (cmd) {
        BIO_CTRL_FLUSH => 1,
        else => 0,
    };
}

fn wssl_bio_cf_out_write(bio: ?*WOLFSSL_BIO, buf: ?[*]const u8, blen: c_int) callconv(.c) c_int {
    if (comptime !use_wolfssl) return -1;
    const b = bio orelse return -1;
    const cf: *CurlCfilter = @ptrCast(@alignCast(wssl_ext.wolfSSL_BIO_get_data(b) orelse return -1));
    const connssl: *SslConnectData = @ptrCast(@alignCast(cf.ctx orelse return -1));
    const backend: *WsslSslBackendData = @ptrCast(@alignCast(connssl.backend orelse return -1));
    const data = connssl.call_data;

    wssl_ext.wolfSSL_BIO_clear_flags(b, WOLFSSL_BIO_FLAG_RWS | WOLFSSL_BIO_FLAG_RETRY);
    if (blen < 0) return 0;

    var nwritten: usize = 0;
    var result: CURLcode = CURLE_OK;
    if (blen > 0) {
        result = c_ext.Curl_conn_cf_send(cf.next, data, buf, @intCast(blen), false, &nwritten);
    }
    backend.io_result = result;
    if (result != CURLE_OK) {
        if (result == CURLE_AGAIN) {
            wssl_ext.wolfSSL_BIO_set_flags(b, WOLFSSL_BIO_FLAG_WRITE | WOLFSSL_BIO_FLAG_RETRY);
        }
        return -1;
    }
    return @intCast(nwritten);
}

fn wssl_bio_cf_in_read(bio: ?*WOLFSSL_BIO, buf_opt: ?[*]u8, blen: c_int) callconv(.c) c_int {
    if (comptime !use_wolfssl) return -1;
    const b = bio orelse return -1;
    const cf: *CurlCfilter = @ptrCast(@alignCast(wssl_ext.wolfSSL_BIO_get_data(b) orelse return -1));
    const connssl: *SslConnectData = @ptrCast(@alignCast(cf.ctx orelse return -1));
    const backend: *WsslSslBackendData = @ptrCast(@alignCast(connssl.backend orelse return -1));
    const data = connssl.call_data;

    wssl_ext.wolfSSL_BIO_clear_flags(b, WOLFSSL_BIO_FLAG_RWS | WOLFSSL_BIO_FLAG_RETRY);
    const buf = buf_opt orelse return 0;
    if (blen <= 0) return 0;

    var nread: usize = 0;
    const result = c_ext.Curl_conn_cf_recv(cf.next, data, buf, @intCast(blen), &nread);
    backend.io_result = result;
    if (result != CURLE_OK) {
        if (result == CURLE_AGAIN) {
            wssl_ext.wolfSSL_BIO_set_flags(b, WOLFSSL_BIO_FLAG_READ | WOLFSSL_BIO_FLAG_RETRY);
        }
        return -1;
    }
    if (nread == 0) {
        connssl.set_peer_closed(true);
    }
    return @intCast(nread);
}

fn wssl_bio_cf_puts(bio: ?*WOLFSSL_BIO, str: ?[*:0]const u8) callconv(.c) c_int {
    if (comptime !use_wolfssl) return -1;
    const s = str orelse return 0;
    return wssl_bio_cf_out_write(bio, s, @intCast(std.mem.len(s)));
}

fn wssl_bio_cf_gets(bio: ?*WOLFSSL_BIO, buf: ?[*]u8, size: c_int) callconv(.c) c_int {
    _ = bio;
    _ = buf;
    _ = size;
    return -1;
}

fn wssl_bio_cf_init_methods() CURLcode {
    if (comptime !use_wolfssl) return CURLE_OK;
    const m = wssl_ext.wolfSSL_BIO_meth_new(WOLFSSL_BIO_UNSET, "cf-bio") orelse return CURLE_OUT_OF_MEMORY;
    _ = wssl_ext.wolfSSL_BIO_meth_set_write(m, &wssl_bio_cf_out_write);
    _ = wssl_ext.wolfSSL_BIO_meth_set_read(m, &wssl_bio_cf_in_read);
    _ = wssl_ext.wolfSSL_BIO_meth_set_puts(m, &wssl_bio_cf_puts);
    _ = wssl_ext.wolfSSL_BIO_meth_set_gets(m, &wssl_bio_cf_gets);
    _ = wssl_ext.wolfSSL_BIO_meth_set_ctrl(m, &wssl_bio_cf_ctrl);
    _ = wssl_ext.wolfSSL_BIO_meth_set_create(m, &wssl_bio_cf_create);
    _ = wssl_ext.wolfSSL_BIO_meth_set_destroy(m, &wssl_bio_cf_free);
    wssl_bio_cf_method = m;
    return CURLE_OK;
}

fn wssl_bio_cf_free_methods() void {
    if (comptime !use_wolfssl) return;
    if (wssl_bio_cf_method) |m| {
        wssl_ext.wolfSSL_BIO_meth_free(m);
        wssl_bio_cf_method = null;
    }
}

fn wssl_io_send(ssl: ?*WOLFSSL, buf_opt: ?[*]const u8, sz: c_int, ctx: ?*anyopaque) callconv(.c) c_int {
    if (comptime !use_wolfssl) return WOLFSSL_CBIO_ERR_GENERAL;
    _ = ssl;
    const cf: *CurlCfilter = @ptrCast(@alignCast(ctx orelse return WOLFSSL_CBIO_ERR_GENERAL));
    const connssl: *SslConnectData = @ptrCast(@alignCast(cf.ctx orelse return WOLFSSL_CBIO_ERR_GENERAL));
    const backend: *WsslSslBackendData = @ptrCast(@alignCast(connssl.backend orelse return WOLFSSL_CBIO_ERR_GENERAL));
    const data = connssl.call_data;

    if (sz <= 0) return 0;

    var nwritten: usize = 0;
    const result = c_ext.Curl_conn_cf_send(cf.next, data, buf_opt, @intCast(sz), false, &nwritten);
    backend.io_result = result;
    if (result != CURLE_OK) {
        if (result == CURLE_AGAIN) {
            return WOLFSSL_CBIO_ERR_WANT_WRITE;
        }
        return WOLFSSL_CBIO_ERR_GENERAL;
    }
    return @intCast(nwritten);
}

fn wssl_io_recv(ssl: ?*WOLFSSL, buf_opt: ?[*]u8, sz: c_int, ctx: ?*anyopaque) callconv(.c) c_int {
    if (comptime !use_wolfssl) return WOLFSSL_CBIO_ERR_GENERAL;
    _ = ssl;
    const cf: *CurlCfilter = @ptrCast(@alignCast(ctx orelse return WOLFSSL_CBIO_ERR_GENERAL));
    const connssl: *SslConnectData = @ptrCast(@alignCast(cf.ctx orelse return WOLFSSL_CBIO_ERR_GENERAL));
    const backend: *WsslSslBackendData = @ptrCast(@alignCast(connssl.backend orelse return WOLFSSL_CBIO_ERR_GENERAL));
    const data = connssl.call_data;
    const buf = buf_opt orelse return 0;

    if (sz <= 0) return 0;

    var nread: usize = 0;
    const result = c_ext.Curl_conn_cf_recv(cf.next, data, buf, @intCast(sz), &nread);
    backend.io_result = result;
    if (result != CURLE_OK) {
        if (result == CURLE_AGAIN) {
            return WOLFSSL_CBIO_ERR_WANT_READ;
        }
        return WOLFSSL_CBIO_ERR_GENERAL;
    }
    if (nread == 0) {
        connssl.set_peer_closed(true);
        return WOLFSSL_CBIO_ERR_CONN_CLOSE;
    }
    return @intCast(nread);
}

// ============================================================================
// Helpers
// ============================================================================

fn do_file_type(type_opt: ?[*:0]const u8) c_int {
    const type_str = type_opt orelse return SSL_FILETYPE_PEM;
    if (type_str[0] == 0) return SSL_FILETYPE_PEM;
    const s = type_str[0..std.mem.len(type_str)];
    if (std.ascii.eqlIgnoreCase(s, "PEM")) return SSL_FILETYPE_PEM;
    if (std.ascii.eqlIgnoreCase(s, "DER")) return SSL_FILETYPE_ASN1;
    return -1;
}

fn peerDispname(peer: *const SslPeer) [*:0]const u8 {
    if (peer.origin) |orig| {
        if (orig.user_hostname[0] != 0) {
            return @ptrCast(&orig.user_hostname[0]);
        }
        return orig.hostname;
    }
    if (peer.sni) |sni| return sni;
    return "";
}

fn peerHostname(peer: *const SslPeer) [*:0]const u8 {
    if (peer.origin) |orig| return orig.hostname;
    if (peer.sni) |sni| return sni;
    return "";
}

fn wsslStrerror(err: c_ulong, buf: *[WOLFSSL_MAX_ERROR_SZ]u8) [*:0]const u8 {
    if (comptime !use_wolfssl) {
        buf[0] = 0;
        return @ptrCast(buf);
    }
    buf.* = @splat(0);
    if (err != 0) {
        return wssl_ext.wolfSSL_ERR_error_string(err, buf);
    }
    return "Unknown error";
}

fn wsslPasswdCallback(buf: [*]u8, sz: c_int, rwflag: c_int, userdata: ?*anyopaque) callconv(.c) c_int {
    _ = rwflag;
    const kpasswd: [*:0]const u8 = @ptrCast(userdata orelse return 0);
    if (sz <= 0) return 0;
    const max_len: usize = @intCast(sz);
    const pw_len = std.mem.len(kpasswd);
    if (pw_len >= max_len) return 0;
    @memcpy(buf[0..pw_len], kpasswd[0..pw_len]);
    buf[pw_len] = 0;
    return @intCast(pw_len);
}

fn wssl_log_tls12_secret(ssl: *WOLFSSL) void {
    if (comptime !use_wolfssl) return;
    switch (wssl_ext.wolfSSL_GetVersion(ssl)) {
        WOLFSSL_SSLv3, WOLFSSL_TLSV1, WOLFSSL_TLSV1_1, WOLFSSL_TLSV1_2 => {},
        else => return,
    }
    var ms: ?[*]u8 = null;
    var sr: ?[*]u8 = null;
    var cr: ?[*]u8 = null;
    var msLen: c_uint = 0;
    var srLen: c_uint = 0;
    var crLen: c_uint = 0;
    if (wssl_ext.wolfSSL_get_keys(ssl, &ms, &msLen, &sr, &srLen, &cr, &crLen) != WOLFSSL_SUCCESS) {
        return;
    }
    const ms_ptr = ms orelse return;
    const cr_ptr = cr orelse return;
    var x: u8 = 0;
    var i: usize = 0;
    while (i < msLen) : (i += 1) {
        x |= ms_ptr[i];
    }
    if (x == 0) return;
    _ = vtls_core.Curl_tls_keylog_write("CLIENT_RANDOM", cr_ptr, crLen, ms_ptr, msLen);
}

// ============================================================================
// 3. X509 Store & CA Caching
// ============================================================================

fn wssl_x509_share_free(obj: ?*anyopaque) callconv(.c) void {
    if (comptime !use_wolfssl) return;
    const share: *WsslX509Share = @ptrCast(@alignCast(obj orelse return));
    if (share.store) |store| {
        wssl_ext.wolfSSL_X509_STORE_free(store);
    }
    if (share.CAfile) |ca| {
        mem.free(ca);
    }
    mem.free(share);
}

fn wssl_cached_x509_store_expired(data: ?*CurlEasy, mb: *const WsslX509Share) bool {
    const timeout = c_ext.Curl_vtls_acc_ssl_ca_cache_timeout(data);
    if (timeout < 0) return false;
    const now = c_ext.Curl_pgrs_now(data).*;
    const elapsed_sec = now.tv_sec - mb.time.tv_sec;
    return elapsed_sec >= timeout;
}

fn wssl_cached_x509_store_different(cf: *CurlCfilter, data: ?*CurlEasy, mb: *const WsslX509Share) bool {
    const conn_config = vtls_impl.Curl_ssl_cf_get_filter_config(cf);
    const is_proxy = vtls_impl.Curl_ssl_cf_is_proxy(cf);
    const cafile: ?[*:0]const u8 = if (conn_config != null and conn_config.?.CAfile != null)
        conn_config.?.CAfile
    else
        c_ext.Curl_vtls_acc_ssl_cainfo(data, is_proxy);

    if (mb.CAfile == null or cafile == null) {
        return mb.CAfile != cafile;
    }
    const s1 = mb.CAfile.?[0..std.mem.len(mb.CAfile.?)];
    const s2 = cafile.?[0..std.mem.len(cafile.?)];
    return !std.mem.eql(u8, s1, s2);
}

fn get_cached_x509_store(cf: *CurlCfilter, data: ?*CurlEasy) ?*WOLFSSL_X509_STORE {
    if (comptime !use_wolfssl) return null;
    const d = data orelse return null;
    const connssl: *SslConnectData = @ptrCast(@alignCast(cf.ctx orelse return null));
    const scache_key = connssl.peer.scache_key orelse return null;
    const conn_config = vtls_impl.Curl_ssl_cf_get_filter_config(cf);
    var scache: ?*vtls_impl.CurlSslScache = null;
    var has_share_scache = false;
    var trc_feat: ?*vtls_impl.CurlTrcFeat = null;
    c_ext.Curl_vtls_acc_scache_params(d, &scache, &has_share_scache, &trc_feat);
    vtls_scache_asn1.Curl_ssl_scache_lock_zig(d, scache, has_share_scache);
    defer vtls_scache_asn1.Curl_ssl_scache_unlock_zig(d, scache, has_share_scache);
    const share_raw = vtls_scache_asn1.Curl_ssl_scache_get_obj_zig(cf, d, scache, conn_config, trc_feat, scache_key) orelse return null;
    const share: *WsslX509Share = @ptrCast(@alignCast(share_raw));
    const store = share.store orelse return null;

    if (!wssl_cached_x509_store_expired(d, share) and
        !wssl_cached_x509_store_different(cf, d, share))
    {
        if (wssl_ext.wolfSSL_X509_STORE_up_ref(store) != 0) {
            return store;
        }
    }
    return null;
}

fn set_cached_x509_store(cf: *CurlCfilter, data: ?*CurlEasy, store: *WOLFSSL_X509_STORE) void {
    if (comptime !use_wolfssl) return;
    const d = data orelse return;
    const connssl: *SslConnectData = @ptrCast(@alignCast(cf.ctx orelse return));
    const scache_key = connssl.peer.scache_key orelse return;

    const share_raw = mem.calloc(1, @sizeOf(WsslX509Share)) orelse return;
    const share: *WsslX509Share = @ptrCast(@alignCast(share_raw));

    if (wssl_ext.wolfSSL_X509_STORE_up_ref(store) == 0) {
        mem.free(share_raw);
        return;
    }
    share.time = c_ext.Curl_pgrs_now(d).*;
    share.store = store;

    const conn_config = vtls_impl.Curl_ssl_cf_get_filter_config(cf);
    const is_proxy = vtls_impl.Curl_ssl_cf_is_proxy(cf);
    const cafile: ?[*:0]const u8 = if (conn_config != null and conn_config.?.CAfile != null)
        conn_config.?.CAfile
    else
        c_ext.Curl_vtls_acc_ssl_cainfo(d, is_proxy);

    if (cafile) |ca| {
        const dup = mem.strdup(ca) orelse {
            wssl_ext.wolfSSL_X509_STORE_free(store);
            mem.free(share_raw);
            return;
        };
        share.CAfile = dup;
    }

    var scache: ?*vtls_impl.CurlSslScache = null;
    var has_share_scache = false;
    var trc_feat: ?*vtls_impl.CurlTrcFeat = null;
    c_ext.Curl_vtls_acc_scache_params(d, &scache, &has_share_scache, &trc_feat);
    vtls_scache_asn1.Curl_ssl_scache_lock_zig(d, scache, has_share_scache);
    defer vtls_scache_asn1.Curl_ssl_scache_unlock_zig(d, scache, has_share_scache);
    _ = vtls_scache_asn1.Curl_ssl_scache_add_obj_zig(cf, d, scache, conn_config, trc_feat, scache_key, share, &wssl_x509_share_free);
}

fn wssl_populate_x509_store(
    cf: *CurlCfilter,
    data: ?*CurlEasy,
    ssl_ctx: *WOLFSSL_CTX,
    backend: *WsslSslBackendData,
) CURLcode {
    if (comptime !use_wolfssl) return CURLE_NOT_BUILT_IN;
    const conn_config = vtls_impl.Curl_ssl_cf_get_filter_config(cf);
    const is_proxy = vtls_impl.Curl_ssl_cf_is_proxy(cf);

    const verifypeer = if (conn_config) |cc| cc.verifypeer() else true;
    const native_ca_store = if (conn_config) |cc| cc.native_ca_store() else false;

    const ca_info_blob: ?*const CurlBlob = if (conn_config != null and conn_config.?.ca_info_blob != null)
        conn_config.?.ca_info_blob
    else
        c_ext.Curl_vtls_acc_ssl_ca_info_blob(data, is_proxy);

    const ssl_cafile: ?[*:0]const u8 = if (conn_config != null and conn_config.?.CAfile != null)
        conn_config.?.CAfile
    else
        c_ext.Curl_vtls_acc_ssl_cainfo(data, is_proxy);

    const ssl_capath: ?[*:0]const u8 = if (conn_config != null and conn_config.?.CApath != null)
        conn_config.?.CApath
    else
        c_ext.Curl_vtls_acc_ssl_capath(data, is_proxy);

    const ssl_crlfile: ?[*:0]const u8 = if (conn_config != null and conn_config.?.CRLfile != null)
        conn_config.?.CRLfile
    else
        c_ext.Curl_vtls_acc_ssl_crlfile(data, is_proxy);

    var imported_native_ca = false;
    var imported_ca_info_blob = false;

    if (!verifypeer) {
        return CURLE_OK;
    }

    if (native_ca_store) {
        if (wssl_ext.wolfSSL_CTX_load_system_CA_certs(ssl_ctx) != WOLFSSL_SUCCESS) {
            c_ext.Curl_infof(data, "error importing native CA store, continuing anyway");
        } else {
            imported_native_ca = true;
            c_ext.Curl_infof(data, "successfully imported native CA store");
            backend.set_x509_store_setup(true);
        }
    }

    if (ca_info_blob) |blob| {
        if (blob.data != null and blob.len > 0) {
            const ptr: [*]const u8 = @ptrCast(blob.data.?);
            if (wssl_ext.wolfSSL_CTX_load_verify_buffer(
                ssl_ctx,
                ptr,
                @intCast(blob.len),
                SSL_FILETYPE_PEM,
            ) != SSL_SUCCESS) {
                if (imported_native_ca) {
                    c_ext.Curl_infof(data, "error importing CA certificate blob, continuing anyway");
                } else {
                    c_ext.Curl_failf(data, "error importing CA certificate blob");
                    return CURLE_SSL_CACERT_BADFILE;
                }
            } else {
                imported_ca_info_blob = true;
                c_ext.Curl_infof(data, "successfully imported CA certificate blob");
                backend.set_x509_store_setup(true);
            }
        }
    }

    const load_file: ?[*:0]const u8 = if (!imported_ca_info_blob) ssl_cafile else null;
    if (load_file != null or ssl_capath != null) {
        const rc = wssl_ext.wolfSSL_CTX_load_verify_locations(ssl_ctx, load_file, ssl_capath);
        if (rc != SSL_SUCCESS) {
            if (imported_native_ca or imported_ca_info_blob) {
                c_ext.Curl_infof(
                    data,
                    "error setting certificate verify locations, continuing anyway:\n  CAfile: %s\n  CApath: %s",
                    load_file orelse "none",
                    ssl_capath orelse "none",
                );
            } else {
                c_ext.Curl_failf(
                    data,
                    "error setting certificate verify locations:\n  CAfile: %s\n  CApath: %s",
                    load_file orelse "none",
                    ssl_capath orelse "none",
                );
                return CURLE_SSL_CACERT_BADFILE;
            }
        } else {
            c_ext.Curl_infof(
                data,
                "  CAfile: %s",
                load_file orelse "none",
            );
            c_ext.Curl_infof(
                data,
                "  CApath: %s",
                ssl_capath orelse "none",
            );
        }
    }

    if (ssl_crlfile) |crlfile| {
        if (backend.ssl) |ssl| {
            if (wssl_ext.wolfSSL_EnableCRL(ssl, WOLFSSL_CRL_CHECK | WOLFSSL_CRL_CHECKALL) != SSL_SUCCESS) {
                c_ext.Curl_failf(data, "unable to Enable CRL");
                return CURLE_SSL_CRL_BADFILE;
            }
            if (wssl_ext.wolfSSL_LoadCRLFile(ssl, crlfile, SSL_FILETYPE_PEM, 0) != SSL_SUCCESS) {
                c_ext.Curl_failf(data, "unable to load CRL file: %s", crlfile);
                return CURLE_SSL_CRL_BADFILE;
            }
        }
    }

    if (load_file == null and ssl_capath == null and !imported_native_ca and !imported_ca_info_blob) {
        if (backend_options.ca_fallback) {
            _ = wssl_ext.wolfSSL_CTX_load_system_CA_certs(ssl_ctx);
        } else {
            wssl_ext.wolfSSL_CTX_set_verify(ssl_ctx, WOLFSSL_VERIFY_NONE, null);
        }
    }

    backend.set_x509_store_setup(true);
    return CURLE_OK;
}

pub fn Curl_wssl_setup_x509_store(
    cf: *CurlCfilter,
    data: ?*CurlEasy,
    wssl_raw: ?*anyopaque,
) callconv(.c) CURLcode {
    if (comptime !use_wolfssl) return CURLE_OK;
    const backend: *WsslSslBackendData = if (wssl_raw) |p|
        @ptrCast(@alignCast(p))
    else blk: {
        const connssl: *SslConnectData = @ptrCast(@alignCast(cf.ctx orelse return CURLE_SSL_CONNECT_ERROR));
        break :blk @ptrCast(@alignCast(connssl.backend orelse return CURLE_SSL_CONNECT_ERROR));
    };
    const ssl_ctx = backend.ssl_ctx orelse return CURLE_SSL_CONNECT_ERROR;

    if (backend.x509_store_setup()) {
        return CURLE_OK;
    }

    const conn_config = vtls_impl.Curl_ssl_cf_get_filter_config(cf);
    const verifypeer = if (conn_config) |cc| cc.verifypeer() else true;
    if (!verifypeer) {
        wssl_ext.wolfSSL_CTX_set_verify(ssl_ctx, WOLFSSL_VERIFY_NONE, null);
        backend.set_x509_store_setup(true);
        return CURLE_OK;
    }

    const is_proxy = vtls_impl.Curl_ssl_cf_is_proxy(cf);
    const ca_info_blob: ?*const CurlBlob = if (conn_config != null and conn_config.?.ca_info_blob != null)
        conn_config.?.ca_info_blob
    else
        c_ext.Curl_vtls_acc_ssl_ca_info_blob(data, is_proxy);

    const ssl_capath: ?[*:0]const u8 = if (conn_config != null and conn_config.?.CApath != null)
        conn_config.?.CApath
    else
        c_ext.Curl_vtls_acc_ssl_capath(data, is_proxy);

    const ssl_crlfile: ?[*:0]const u8 = if (conn_config != null and conn_config.?.CRLfile != null)
        conn_config.?.CRLfile
    else
        c_ext.Curl_vtls_acc_ssl_crlfile(data, is_proxy);

    var fsslctx_fn: ?*const anyopaque = null;
    var fsslctx_p: ?*anyopaque = null;
    const has_user_fsslctx = c_ext.Curl_vtls_acc_ssl_fsslctx(data, &fsslctx_fn, &fsslctx_p);

    const cache_criteria_met = (c_ext.Curl_vtls_acc_ssl_ca_cache_timeout(data) != 0) and
        verifypeer and
        (ssl_capath == null) and
        (ca_info_blob == null) and
        (ssl_crlfile == null) and
        !has_user_fsslctx;

    const cached_store: ?*WOLFSSL_X509_STORE = if (cache_criteria_met)
        get_cached_x509_store(cf, data)
    else
        null;

    if (cached_store) |s| {
        c_ext.Curl_infof(data, "successfully imported windows ca store from cache");
        wssl_ext.wolfSSL_CTX_set_cert_store(ssl_ctx, s);
        backend.set_x509_store_setup(true);
        return CURLE_OK;
    }

    if (cache_criteria_met) {
        const store = wssl_ext.wolfSSL_X509_STORE_new() orelse return CURLE_OUT_OF_MEMORY;
        wssl_ext.wolfSSL_CTX_set_cert_store(ssl_ctx, store);

        const rc = wssl_populate_x509_store(cf, data, ssl_ctx, backend);
        if (rc == CURLE_OK) {
            set_cached_x509_store(cf, data, store);
        }
        return rc;
    }

    return wssl_populate_x509_store(cf, data, ssl_ctx, backend);
}

// ============================================================================
// 4. Context & Session Setup (wssl_init_step1 / wssl_connect_step1)
// ============================================================================

fn wssl_set_ssl_version_min_max(ctx: *WOLFSSL_CTX, cf: *CurlCfilter, data: ?*CurlEasy) CURLcode {
    if (comptime !use_wolfssl) return CURLE_NOT_BUILT_IN;
    const conn_config = vtls_impl.Curl_ssl_cf_get_filter_config(cf) orelse return CURLE_SSL_CONNECT_ERROR;

    var ssl_version = conn_config.version;
    const ssl_version_max: u32 = @intCast(conn_config.version_max);

    switch (ssl_version) {
        vtls_impl.CURL_SSLVERSION_DEFAULT, vtls_impl.CURL_SSLVERSION_TLSv1 => {
            ssl_version = vtls_impl.CURL_SSLVERSION_TLSv1_0;
        },
        else => {},
    }

    switch (ssl_version) {
        vtls_impl.CURL_SSLVERSION_TLSv1_0 => {
            if (wssl_ext.wolfSSL_CTX_set_min_proto_version(ctx, TLS1_VERSION) != WOLFSSL_SUCCESS) {
                c_ext.Curl_failf(data, "wolfSSL: failed to set min TLS version to TLSv1.0");
                return CURLE_SSL_CONNECT_ERROR;
            }
        },
        vtls_impl.CURL_SSLVERSION_TLSv1_1 => {
            if (wssl_ext.wolfSSL_CTX_set_min_proto_version(ctx, TLS1_1_VERSION) != WOLFSSL_SUCCESS) {
                c_ext.Curl_failf(data, "wolfSSL: failed to set min TLS version to TLSv1.1");
                return CURLE_SSL_CONNECT_ERROR;
            }
        },
        vtls_impl.CURL_SSLVERSION_TLSv1_2 => {
            if (wssl_ext.wolfSSL_CTX_set_min_proto_version(ctx, TLS1_2_VERSION) != WOLFSSL_SUCCESS) {
                c_ext.Curl_failf(data, "wolfSSL: failed to set min TLS version to TLSv1.2");
                return CURLE_SSL_CONNECT_ERROR;
            }
        },
        vtls_impl.CURL_SSLVERSION_TLSv1_3 => {
            if (wssl_ext.wolfSSL_CTX_set_min_proto_version(ctx, TLS1_3_VERSION) != WOLFSSL_SUCCESS) {
                c_ext.Curl_failf(data, "wolfSSL: failed to set min TLS version to TLSv1.3");
                return CURLE_SSL_CONNECT_ERROR;
            }
        },
        else => {
            c_ext.Curl_failf(data, "wolfSSL: unsupported minimum TLS version value");
            return CURLE_SSL_CONNECT_ERROR;
        },
    }

    const max_code: u32 = ssl_version_max >> 16;
    switch (max_code) {
        0 => {},
        vtls_impl.CURL_SSLVERSION_TLSv1, vtls_impl.CURL_SSLVERSION_TLSv1_3 => {
            if (wssl_ext.wolfSSL_CTX_set_max_proto_version(ctx, TLS1_3_VERSION) != WOLFSSL_SUCCESS) {
                c_ext.Curl_failf(data, "wolfSSL: failed to set max TLS version to TLSv1.3");
                return CURLE_SSL_CONNECT_ERROR;
            }
        },
        vtls_impl.CURL_SSLVERSION_TLSv1_0 => {
            if (wssl_ext.wolfSSL_CTX_set_max_proto_version(ctx, TLS1_VERSION) != WOLFSSL_SUCCESS) {
                c_ext.Curl_failf(data, "wolfSSL: failed to set max TLS version to TLSv1.0");
                return CURLE_SSL_CONNECT_ERROR;
            }
        },
        vtls_impl.CURL_SSLVERSION_TLSv1_1 => {
            if (wssl_ext.wolfSSL_CTX_set_max_proto_version(ctx, TLS1_1_VERSION) != WOLFSSL_SUCCESS) {
                c_ext.Curl_failf(data, "wolfSSL: failed to set max TLS version to TLSv1.1");
                return CURLE_SSL_CONNECT_ERROR;
            }
        },
        vtls_impl.CURL_SSLVERSION_TLSv1_2 => {
            if (wssl_ext.wolfSSL_CTX_set_max_proto_version(ctx, TLS1_2_VERSION) != WOLFSSL_SUCCESS) {
                c_ext.Curl_failf(data, "wolfSSL: failed to set max TLS version to TLSv1.2");
                return CURLE_SSL_CONNECT_ERROR;
            }
        },
        else => {
            c_ext.Curl_failf(data, "wolfSSL: unsupported maximum TLS version value");
            return CURLE_SSL_CONNECT_ERROR;
        },
    }

    return CURLE_OK;
}

fn wssl_new_session_cb(ssl: ?*WOLFSSL, session: ?*WOLFSSL_SESSION) callconv(.c) c_int {
    if (comptime !use_wolfssl) return 0;
    const s = ssl orelse return 0;
    const sess = session orelse return 0;
    const cf_raw = wssl_ext.wolfSSL_get_app_data(s) orelse return 0;
    const cf: *CurlCfilter = @ptrCast(@alignCast(cf_raw));
    const connssl: *SslConnectData = @ptrCast(@alignCast(cf.ctx orelse return 0));
    const backend: *WsslSslBackendData = @ptrCast(@alignCast(connssl.backend orelse return 0));
    const data = connssl.call_data orelse backend.handle orelse return 0;
    const conn_config = vtls_impl.Curl_ssl_cf_get_filter_config(cf) orelse return 0;
    if (!conn_config.primary_cache_session()) return 0;
    const scache_key = connssl.peer.scache_key orelse return 0;

    const sdata_len_int = wssl_ext.wolfSSL_i2d_SSL_SESSION(sess, null);
    if (sdata_len_int <= 0) return 0;
    const sdata_len: usize = @intCast(sdata_len_int);
    const sdata_raw = mem.calloc(1, sdata_len) orelse return 0;
    var sdata_ptr: ?[*]u8 = @ptrCast(sdata_raw);
    const enc_len = wssl_ext.wolfSSL_i2d_SSL_SESSION(sess, &sdata_ptr);
    if (enc_len <= 0) {
        mem.free(sdata_raw);
        return 0;
    }

    const timeout = wssl_ext.wolfSSL_SESSION_get_timeout(sess);
    const valid_until = if (timeout > 0) c_ext.Curl_pgrs_now(data).tv_sec + @as(i64, @intCast(timeout)) else 0;
    const ietf_tls_id = wssl_ext.wolfSSL_version(s);
    var sc_session: ?*CurlSslSession = null;
    const rc = vtls_scache_asn1.Curl_ssl_session_create2(
        @ptrCast(sdata_raw),
        @intCast(enc_len),
        ietf_tls_id,
        connssl.negotiated_alpn,
        valid_until,
        0,
        null,
        0,
        &sc_session,
    );
    if (rc == CURLE_OK) {
        if (sc_session) |scs| {
            var scache: ?*vtls_impl.CurlSslScache = null;
            var has_share_scache = false;
            var trc_feat: ?*vtls_impl.CurlTrcFeat = null;
            c_ext.Curl_vtls_acc_scache_params(data, &scache, &has_share_scache, &trc_feat);
            _ = vtls_scache_asn1.Curl_ssl_scache_put_zig(cf, data, scache, has_share_scache, conn_config, trc_feat, scache_key, scs);
        }
    }
    return 0;
}

fn wssl_setup_session(cf: *CurlCfilter, data: ?*CurlEasy, backend: *WsslSslBackendData) CURLcode {
    if (comptime !use_wolfssl) return CURLE_NOT_BUILT_IN;
    const conn_config = vtls_impl.Curl_ssl_cf_get_filter_config(cf) orelse return CURLE_OK;
    if (!conn_config.primary_cache_session()) return CURLE_OK;
    const ssl_ctx = backend.ssl_ctx orelse return CURLE_SSL_CONNECT_ERROR;
    const ssl = backend.ssl orelse return CURLE_SSL_CONNECT_ERROR;
    const connssl: *SslConnectData = @ptrCast(@alignCast(cf.ctx orelse return CURLE_SSL_CONNECT_ERROR));

    _ = wssl_ext.wolfSSL_set_app_data(ssl, cf);
    _ = wssl_ext.wolfSSL_CTX_set_session_cache_mode(ssl_ctx, WOLFSSL_SESS_CACHE_OFF);
    wssl_ext.wolfSSL_CTX_sess_set_new_cb(ssl_ctx, &wssl_new_session_cb);

    const scache_key = connssl.peer.scache_key orelse return CURLE_OK;
    if (data) |d| {
        var scache: ?*vtls_impl.CurlSslScache = null;
        var has_share_scache = false;
        var trc_feat: ?*vtls_impl.CurlTrcFeat = null;
        c_ext.Curl_vtls_acc_scache_params(d, &scache, &has_share_scache, &trc_feat);
        var scs: ?*CurlSslSession = null;
        if (vtls_scache_asn1.Curl_ssl_scache_take_zig(cf, d, scache, has_share_scache, conn_config, trc_feat, scache_key, &scs) == CURLE_OK) {
            if (scs) |s| {
                if (s.sdata != null and s.sdata_len > 0) {
                    var sdata_ptr: [*]const u8 = @ptrCast(s.sdata.?);
                    if (wssl_ext.wolfSSL_d2i_SSL_SESSION(null, &sdata_ptr, @intCast(s.sdata_len))) |w_sess| {
                        defer wssl_ext.wolfSSL_SESSION_free(w_sess);
                        if (wssl_ext.wolfSSL_set_session(ssl, w_sess) == WOLFSSL_SUCCESS) {
                            c_ext.Curl_infof(d, "SSL reusing session ID");
                            vtls_scache_asn1.Curl_ssl_scache_return_zig(cf, d, scache, has_share_scache, conn_config, trc_feat, scache_key, s);
                            return CURLE_OK;
                        }
                    }
                }
                vtls_scache_asn1.Curl_ssl_session_destroy(s);
            }
        }
    }
    return CURLE_OK;
}

fn wssl_init_step1(cf: *CurlCfilter, data: ?*CurlEasy) CURLcode {
    if (comptime !use_wolfssl) return CURLE_NOT_BUILT_IN;
    const connssl: *SslConnectData = @ptrCast(@alignCast(cf.ctx orelse return CURLE_SSL_CONNECT_ERROR));
    const backend: *WsslSslBackendData = @ptrCast(@alignCast(connssl.backend orelse return CURLE_SSL_CONNECT_ERROR));
    const conn_config = vtls_impl.Curl_ssl_cf_get_filter_config(cf) orelse return CURLE_SSL_CONNECT_ERROR;
    const is_proxy = vtls_impl.Curl_ssl_cf_is_proxy(cf);

    if (backend.ssl != null) {
        return CURLE_OK;
    }

    backend.handle = data;

    const req_method = wssl_ext.wolfSSLv23_client_method() orelse return CURLE_OUT_OF_MEMORY;
    if (backend.ssl_ctx) |old_ctx| {
        wssl_ext.wolfSSL_CTX_free(old_ctx);
    }
    const ssl_ctx = wssl_ext.wolfSSL_CTX_new(req_method) orelse return CURLE_OUT_OF_MEMORY;
    backend.ssl_ctx = ssl_ctx;

    const ver_rc = wssl_set_ssl_version_min_max(ssl_ctx, cf, data);
    if (ver_rc != CURLE_OK) return ver_rc;

    const ciphers12: ?[*:0]const u8 = if (conn_config.cipher_list) |cl|
        cl
    else
        c_ext.Curl_vtls_acc_ssl_cipher_list(data, is_proxy);

    const ciphers13: ?[*:0]const u8 = if (conn_config.cipher_list13) |cl13|
        cl13
    else
        c_ext.Curl_vtls_acc_ssl_cipher13_list(data, is_proxy);

    if (ciphers13) |c13| {
        if (ciphers12) |c12| {
            const len13 = std.mem.len(c13);
            const len12 = std.mem.len(c12);
            const total = len13 + 1 + len12 + 1;
            const combined_raw = mem.malloc(total) orelse return CURLE_OUT_OF_MEMORY;
            defer mem.free(combined_raw);
            const combined: [*]u8 = @ptrCast(combined_raw);
            @memcpy(combined[0..len13], c13[0..len13]);
            combined[len13] = ':';
            @memcpy(combined[len13 + 1 .. len13 + 1 + len12], c12[0..len12]);
            combined[len13 + 1 + len12] = 0;
            if (wssl_ext.wolfSSL_CTX_set_cipher_list(ssl_ctx, @ptrCast(combined)) == 0) {
                c_ext.Curl_failf(data, "failed setting cipher list: %s:%s", c13, c12);
                return CURLE_SSL_CIPHER;
            }
            c_ext.Curl_infof(data, "Cipher selection: %s:%s", c13, c12);
        } else {
            if (wssl_ext.wolfSSL_CTX_set_cipher_list(ssl_ctx, c13) == 0) {
                c_ext.Curl_failf(data, "failed setting TLS 1.3 cipher suite: %s", c13);
                return CURLE_SSL_CIPHER;
            }
            c_ext.Curl_infof(data, "Cipher selection: %s", c13);
        }
    } else if (ciphers12) |c12| {
        if (wssl_ext.wolfSSL_CTX_set_cipher_list(ssl_ctx, c12) == 0) {
            c_ext.Curl_failf(data, "failed setting cipher list: %s", c12);
            return CURLE_SSL_CIPHER;
        }
        c_ext.Curl_infof(data, "Cipher selection: %s", c12);
    } else {
        _ = wssl_ext.wolfSSL_CTX_set_cipher_list(ssl_ctx, SSL_DEFAULT_CIPHER_LIST);
    }

    const curves: ?[*:0]const u8 = if (conn_config.curves) |cv|
        cv
    else
        c_ext.Curl_vtls_acc_ssl_ec_curves(data);

    if (curves) |cv| {
        if (wssl_ext.wolfSSL_CTX_set1_curves_list(ssl_ctx, cv) != WOLFSSL_SUCCESS) {
            c_ext.Curl_failf(data, "failed setting curves list: '%s'", cv);
            return CURLE_SSL_CIPHER;
        }
    }

    // Load client certificate & private key
    const cert_file: ?[*:0]const u8 = if (conn_config.clientcert) |p| p else c_ext.Curl_vtls_acc_ssl_cert(data, is_proxy);
    const cert_blob: ?*const CurlBlob = if (conn_config.cert_blob) |b| b else c_ext.Curl_vtls_acc_ssl_cert_blob(data, is_proxy);
    const cert_type_str: ?[*:0]const u8 = if (conn_config.cert_type) |t| t else c_ext.Curl_vtls_acc_ssl_cert_type(data, is_proxy);
    var key_file: ?[*:0]const u8 = if (conn_config.key) |k| k else c_ext.Curl_vtls_acc_ssl_key(data, is_proxy);
    var key_blob: ?*const CurlBlob = conn_config.key_blob;
    const key_type_str: ?[*:0]const u8 = if (conn_config.key_type) |kt| kt else c_ext.Curl_vtls_acc_ssl_key_type(data, is_proxy);
    const key_passwd: ?[*:0]const u8 = if (conn_config.key_passwd) |kp| kp else c_ext.Curl_vtls_acc_ssl_key_passwd(data, is_proxy);

    if (cert_file != null or cert_blob != null) {
        const file_type = do_file_type(cert_type_str);
        if (file_type == SSL_FILETYPE_PEM) {
            const ret = if (cert_blob) |cb|
                if (cb.data != null and cb.len > 0)
                    wssl_ext.wolfSSL_CTX_use_certificate_chain_buffer(ssl_ctx, @ptrCast(cb.data.?), @intCast(cb.len))
                else
                    0
            else
                wssl_ext.wolfSSL_CTX_use_certificate_chain_file(ssl_ctx, cert_file.?);
            if (ret != 1) {
                c_ext.Curl_failf(data, "unable to use client certificate");
                return CURLE_SSL_CERTPROBLEM;
            }
        } else if (file_type == SSL_FILETYPE_ASN1) {
            const ret = if (cert_blob) |cb|
                if (cb.data != null and cb.len > 0)
                    wssl_ext.wolfSSL_CTX_use_certificate_buffer(ssl_ctx, @ptrCast(cb.data.?), @intCast(cb.len), file_type)
                else
                    0
            else
                wssl_ext.wolfSSL_CTX_use_certificate_file(ssl_ctx, cert_file.?, file_type);
            if (ret != 1) {
                c_ext.Curl_failf(data, "unable to use client certificate");
                return CURLE_SSL_CERTPROBLEM;
            }
        } else {
            c_ext.Curl_failf(data, "unknown cert type");
            return CURLE_SSL_CERTPROBLEM;
        }

        if (key_file == null and key_blob == null) {
            key_file = cert_file;
            key_blob = cert_blob;
        }
    }

    if (key_file != null or key_blob != null) {
        const file_type = do_file_type(key_type_str);
        if (file_type != SSL_FILETYPE_PEM and file_type != SSL_FILETYPE_ASN1) {
            c_ext.Curl_failf(data, "unknown key type");
            return CURLE_SSL_CERTPROBLEM;
        }
        if (key_passwd) |pw| {
            wssl_ext.wolfSSL_CTX_set_default_passwd_cb(ssl_ctx, &wsslPasswdCallback);
            wssl_ext.wolfSSL_CTX_set_default_passwd_cb_userdata(ssl_ctx, @ptrCast(@constCast(pw)));
        }
        const ret = if (key_blob) |kb|
            if (kb.data != null and kb.len > 0)
                wssl_ext.wolfSSL_CTX_use_PrivateKey_buffer(ssl_ctx, @ptrCast(kb.data.?), @intCast(kb.len), file_type)
            else
                0
        else
            wssl_ext.wolfSSL_CTX_use_PrivateKey_file(ssl_ctx, key_file.?, file_type);
        if (ret != 1) {
            c_ext.Curl_failf(data, "unable to set private key");
            return CURLE_SSL_CERTPROBLEM;
        }
    }

    wssl_ext.wolfSSL_CTX_set_verify(
        ssl_ctx,
        if (conn_config.verifypeer()) WOLFSSL_VERIFY_PEER else WOLFSSL_VERIFY_NONE,
        null,
    );

    wssl_ext.wolfSSL_CTX_SetIOSend(ssl_ctx, &wssl_io_send);
    wssl_ext.wolfSSL_CTX_SetIORecv(ssl_ctx, &wssl_io_recv);

    const ssl = wssl_ext.wolfSSL_new(ssl_ctx) orelse return CURLE_OUT_OF_MEMORY;
    backend.ssl = ssl;

    if (connssl.peer.sni) |sni| {
        const sni_len = std.mem.len(sni);
        if (sni_len > 0 and sni_len <= std.math.maxInt(c_ushort)) {
            if (wssl_ext.wolfSSL_UseSNI(ssl, WOLFSSL_SNI_HOST_NAME, sni, @intCast(sni_len)) != WOLFSSL_SUCCESS) {
                c_ext.Curl_failf(data, "Failed to set SNI");
                return CURLE_SSL_CONNECT_ERROR;
            }
        }
    }

    if (connssl.alpn) |alpn_spec| {
        if (alpn_spec.count > 0) {
            var proto: vtls_backends.AlpnProtoBuf = .{
                .data = @splat(0),
                .len = 0,
            };
            const rc = vtls_impl.Curl_alpn_to_proto_str(&proto, alpn_spec);
            if (rc != CURLE_OK) return rc;
            if (proto.len > 0) {
                if (wssl_ext.wolfSSL_UseALPN(
                    ssl,
                    &proto.data,
                    @intCast(proto.len),
                    WOLFSSL_ALPN_CONTINUE_ON_MISMATCH,
                ) != SSL_SUCCESS) {
                    c_ext.Curl_failf(data, "SSL: failed setting ALPN protocols");
                    return CURLE_SSL_CONNECT_ERROR;
                }
                c_ext.Curl_infof(data, "ALPN: curl offers %s", @as([*:0]const u8, @ptrCast(&proto.data)));
            }
        }
    }

    if (vtls_core.Curl_tls_keylog_enabled()) {
        wssl_ext.wolfSSL_KeepArrays(ssl);
    }

    _ = wssl_ext.wolfSSL_UseSecureRenegotiation(ssl);

    wssl_ext.wolfSSL_SetIOReadCtx(ssl, cf);
    wssl_ext.wolfSSL_SetIOWriteCtx(ssl, cf);

    if (conn_config.verifyhost()) {
        if (connssl.peer.sni) |sni| {
            if (wssl_ext.wolfSSL_check_domain_name(ssl, sni) != WOLFSSL_SUCCESS) {
                return CURLE_SSL_CONNECT_ERROR;
            }
        }
    }

    const sess_rc = wssl_setup_session(cf, data, backend);
    if (sess_rc != CURLE_OK) return sess_rc;

    var fsslctx_fn: ?*const anyopaque = null;
    var fsslctx_p: ?*anyopaque = null;
    if (c_ext.Curl_vtls_acc_ssl_fsslctx(data, &fsslctx_fn, &fsslctx_p)) {
        if (fsslctx_fn) |fn_ptr| {
            c_ext.Curl_pgrsTime(data, vtls_backends.TIMER_APPCONNECT);
            const cb: *const fn (?*CurlEasy, ?*anyopaque, ?*anyopaque) callconv(.c) CURLcode = @ptrCast(@alignCast(fn_ptr));
            const cb_rc = cb(data, ssl_ctx, fsslctx_p);
            if (cb_rc != CURLE_OK) {
                c_ext.Curl_failf(data, "error signaled by ssl ctx callback");
                return cb_rc;
            }
        }
    }

    return CURLE_OK;
}

// ============================================================================
// 5. Handshake & Post-Handshake Verification (wssl_connect_step2 / step3)
// ============================================================================

fn wssl_pin_peer_pubkey(cf: *CurlCfilter, data: ?*CurlEasy, backend: *WsslSslBackendData) CURLcode {
    if (comptime !use_wolfssl) return CURLE_NOT_BUILT_IN;
    const conn_config = vtls_impl.Curl_ssl_cf_get_filter_config(cf);
    const is_proxy = vtls_impl.Curl_ssl_cf_is_proxy(cf);
    const pinned_key: ?[*:0]const u8 = if (conn_config != null and conn_config.?.pinned_key != null)
        conn_config.?.pinned_key
    else
        c_ext.Curl_vtls_acc_pinned_pubkey(data, is_proxy);

    const pinnedpubkey = pinned_key orelse return CURLE_OK;
    const ssl = backend.ssl orelse return CURLE_SSL_PINNEDPUBKEYNOTMATCH;

    const x509 = wssl_ext.wolfSSL_get_peer_certificate(ssl) orelse {
        c_ext.Curl_failf(data, "SSL: failed retrieving server certificate");
        return CURLE_SSL_PINNEDPUBKEYNOTMATCH;
    };
    defer wssl_ext.wolfSSL_X509_free(x509);

    var der_sz: c_int = 0;
    const der_ptr = wssl_ext.wolfSSL_X509_get_der(x509, &der_sz);
    if (der_ptr != null and der_sz > 0) {
        var x509_parsed: vtls_scache_asn1.CurlX509certificate = std.mem.zeroes(vtls_scache_asn1.CurlX509certificate);
        const beg = der_ptr.?;
        const end = beg + @as(usize, @intCast(der_sz));
        if (vtls_scache_asn1.Curl_parseX509(&x509_parsed, beg, end) == 0) {
            const pubkey = &x509_parsed.subjectPublicKeyInfo;
            if (pubkey.header != null and pubkey.end != null and @intFromPtr(pubkey.end.?) > @intFromPtr(pubkey.header.?)) {
                const pk_len = @intFromPtr(pubkey.end.?) - @intFromPtr(pubkey.header.?);
                return vtls_impl.Curl_pin_peer_pubkey(data, pinnedpubkey, pubkey.header.?, pk_len);
            }
        }
    }

    const pkey = wssl_ext.wolfSSL_X509_get_pubkey(x509) orelse {
        c_ext.Curl_failf(data, "SSL: failed retrieving public key from server certificate");
        return CURLE_SSL_PINNEDPUBKEYNOTMATCH;
    };
    defer wssl_ext.wolfSSL_EVP_PKEY_free(pkey);

    var null_pp: ?[*]u8 = null;
    const len_int = wssl_ext.wolfSSL_i2d_PUBKEY(pkey, &null_pp);
    if (len_int <= 0 or len_int > @as(c_int, @intCast(vtls_backends.MAX_PINNED_PUBKEY_SIZE))) {
        c_ext.Curl_failf(data, "SSL: failed retrieving public key from server certificate");
        return CURLE_SSL_PINNEDPUBKEYNOTMATCH;
    }

    const len: usize = @intCast(len_int);
    const buff1_raw = mem.malloc(len) orelse return CURLE_OUT_OF_MEMORY;
    defer mem.free(buff1_raw);

    var temp: ?[*]u8 = @ptrCast(buff1_raw);
    const enc_len = wssl_ext.wolfSSL_i2d_PUBKEY(pkey, &temp);
    if (enc_len != len_int) {
        c_ext.Curl_failf(data, "SSL: failed retrieving public key from server certificate");
        return CURLE_SSL_PINNEDPUBKEYNOTMATCH;
    }

    return vtls_impl.Curl_pin_peer_pubkey(data, pinnedpubkey, @ptrCast(buff1_raw), len);
}

pub fn Curl_wssl_verify_pinned(
    cf: *CurlCfilter,
    data: ?*CurlEasy,
    wssl: *WsslSslBackendData,
) callconv(.c) CURLcode {
    return wssl_pin_peer_pubkey(cf, data, wssl);
}

pub fn Curl_wssl_report_handshake(
    data: ?*CurlEasy,
    wssl: *WsslSslBackendData,
) callconv(.c) void {
    if (comptime !use_wolfssl) return;
    const ssl = wssl.ssl orelse return;
    c_ext.Curl_infof(
        data,
        "SSL connection using %s / %s",
        wssl_ext.wolfSSL_get_version(ssl) orelse "unknown",
        wssl_ext.wolfSSL_get_cipher_name(ssl) orelse "unknown",
    );
}

pub const CurlWsslCtxSetupCb = *const fn (
    cf: *CurlCfilter,
    data: ?*CurlEasy,
    cb_user_data: ?*anyopaque,
) callconv(.c) CURLcode;

pub const CurlWsslInitSessionReuseCb = *const fn (
    cf: *CurlCfilter,
    data: ?*CurlEasy,
    alpns: ?*const vtls_backends.AlpnSpec,
    scs: *CurlSslSession,
    do_early_data: *bool,
) callconv(.c) CURLcode;

pub fn Curl_wssl_ctx_init(
    wctx: *WsslSslBackendData,
    cf: *CurlCfilter,
    data: ?*CurlEasy,
    peer: *const vtls_backends.SslPeer,
    alpns_requested: ?*const vtls_backends.AlpnSpec,
    cb_setup: ?CurlWsslCtxSetupCb,
    cb_user_data: ?*anyopaque,
    ssl_user_data: ?*anyopaque,
    sess_reuse_cb: ?CurlWsslInitSessionReuseCb,
) callconv(.c) CURLcode {
    if (comptime !use_wolfssl) return CURLE_NOT_BUILT_IN;
    const conn_config = vtls_impl.Curl_ssl_cf_get_filter_config(cf) orelse return CURLE_FAILED_INIT;
    const is_proxy = vtls_impl.Curl_ssl_cf_is_proxy(cf);

    wctx.handle = data;
    const req_method = wssl_ext.wolfSSLv23_client_method() orelse return CURLE_OUT_OF_MEMORY;
    if (wctx.ssl_ctx) |old_ctx| {
        wssl_ext.wolfSSL_CTX_free(old_ctx);
    }
    const ssl_ctx = wssl_ext.wolfSSL_CTX_new(req_method) orelse return CURLE_OUT_OF_MEMORY;
    wctx.ssl_ctx = ssl_ctx;

    var result: CURLcode = CURLE_OK;
    defer if (result != CURLE_OK) {
        if (wctx.ssl) |s| {
            wssl_ext.wolfSSL_free(s);
            wctx.ssl = null;
        }
        if (wctx.ssl_ctx) |c| {
            wssl_ext.wolfSSL_CTX_free(c);
            wctx.ssl_ctx = null;
        }
    };

    result = wssl_set_ssl_version_min_max(ssl_ctx, cf, data);
    if (result != CURLE_OK) return result;

    const ciphers12: ?[*:0]const u8 = if (conn_config.cipher_list) |cl|
        cl
    else
        c_ext.Curl_vtls_acc_ssl_cipher_list(data, is_proxy);

    const ciphers13: ?[*:0]const u8 = if (conn_config.cipher_list13) |cl13|
        cl13
    else
        c_ext.Curl_vtls_acc_ssl_cipher13_list(data, is_proxy);

    if (ciphers13) |c13| {
        if (ciphers12) |c12| {
            const len13 = std.mem.len(c13);
            const len12 = std.mem.len(c12);
            const total = len13 + 1 + len12 + 1;
            const combined_raw = mem.malloc(total) orelse {
                result = CURLE_OUT_OF_MEMORY;
                return result;
            };
            defer mem.free(combined_raw);
            const combined: [*]u8 = @ptrCast(combined_raw);
            @memcpy(combined[0..len13], c13[0..len13]);
            combined[len13] = ':';
            @memcpy(combined[len13 + 1 .. len13 + 1 + len12], c12[0..len12]);
            combined[len13 + 1 + len12] = 0;
            if (wssl_ext.wolfSSL_CTX_set_cipher_list(ssl_ctx, @ptrCast(combined)) == 0) {
                c_ext.Curl_failf(data, "failed setting cipher list: %s:%s", c13, c12);
                result = CURLE_SSL_CIPHER;
                return result;
            }
        } else {
            if (wssl_ext.wolfSSL_CTX_set_cipher_list(ssl_ctx, c13) == 0) {
                c_ext.Curl_failf(data, "failed setting TLS 1.3 cipher suite: %s", c13);
                result = CURLE_SSL_CIPHER;
                return result;
            }
        }
    } else if (ciphers12) |c12| {
        if (wssl_ext.wolfSSL_CTX_set_cipher_list(ssl_ctx, c12) == 0) {
            c_ext.Curl_failf(data, "failed setting cipher list: %s", c12);
            result = CURLE_SSL_CIPHER;
            return result;
        }
    } else {
        _ = wssl_ext.wolfSSL_CTX_set_cipher_list(ssl_ctx, SSL_DEFAULT_CIPHER_LIST);
    }

    const curves: ?[*:0]const u8 = if (conn_config.curves) |cv|
        cv
    else
        c_ext.Curl_vtls_acc_ssl_ec_curves(data);

    if (curves) |cv| {
        if (wssl_ext.wolfSSL_CTX_set1_curves_list(ssl_ctx, cv) != WOLFSSL_SUCCESS) {
            c_ext.Curl_failf(data, "failed setting curves list: '%s'", cv);
            result = CURLE_SSL_CIPHER;
            return result;
        }
    }

    const cert_file: ?[*:0]const u8 = if (conn_config.clientcert) |p| p else c_ext.Curl_vtls_acc_ssl_cert(data, is_proxy);
    const cert_blob: ?*const CurlBlob = if (conn_config.cert_blob) |b| b else c_ext.Curl_vtls_acc_ssl_cert_blob(data, is_proxy);
    const cert_type_str: ?[*:0]const u8 = if (conn_config.cert_type) |t| t else c_ext.Curl_vtls_acc_ssl_cert_type(data, is_proxy);
    var key_file: ?[*:0]const u8 = if (conn_config.key) |k| k else c_ext.Curl_vtls_acc_ssl_key(data, is_proxy);
    var key_blob: ?*const CurlBlob = conn_config.key_blob;
    const key_type_str: ?[*:0]const u8 = if (conn_config.key_type) |kt| kt else c_ext.Curl_vtls_acc_ssl_key_type(data, is_proxy);
    const key_passwd: ?[*:0]const u8 = if (conn_config.key_passwd) |kp| kp else c_ext.Curl_vtls_acc_ssl_key_passwd(data, is_proxy);

    if (cert_file != null or cert_blob != null) {
        const file_type = do_file_type(cert_type_str);
        if (file_type == SSL_FILETYPE_PEM) {
            const ret = if (cert_blob) |cb|
                if (cb.data != null and cb.len > 0)
                    wssl_ext.wolfSSL_CTX_use_certificate_chain_buffer(ssl_ctx, @ptrCast(cb.data.?), @intCast(cb.len))
                else
                    0
            else
                wssl_ext.wolfSSL_CTX_use_certificate_chain_file(ssl_ctx, cert_file.?);
            if (ret != 1) {
                c_ext.Curl_failf(data, "unable to use client certificate");
                result = CURLE_SSL_CERTPROBLEM;
                return result;
            }
        } else if (file_type == SSL_FILETYPE_ASN1) {
            const ret = if (cert_blob) |cb|
                if (cb.data != null and cb.len > 0)
                    wssl_ext.wolfSSL_CTX_use_certificate_buffer(ssl_ctx, @ptrCast(cb.data.?), @intCast(cb.len), file_type)
                else
                    0
            else
                wssl_ext.wolfSSL_CTX_use_certificate_file(ssl_ctx, cert_file.?, file_type);
            if (ret != 1) {
                c_ext.Curl_failf(data, "unable to use client certificate");
                result = CURLE_SSL_CERTPROBLEM;
                return result;
            }
        } else {
            c_ext.Curl_failf(data, "unknown cert type");
            result = CURLE_SSL_CERTPROBLEM;
            return result;
        }

        if (key_file == null and key_blob == null) {
            key_file = cert_file;
            key_blob = cert_blob;
        }
    }

    if (key_file != null or key_blob != null) {
        const file_type = do_file_type(key_type_str);
        if (file_type != SSL_FILETYPE_PEM and file_type != SSL_FILETYPE_ASN1) {
            c_ext.Curl_failf(data, "unknown key type");
            result = CURLE_SSL_CERTPROBLEM;
            return result;
        }
        if (key_passwd) |pw| {
            wssl_ext.wolfSSL_CTX_set_default_passwd_cb(ssl_ctx, &wsslPasswdCallback);
            wssl_ext.wolfSSL_CTX_set_default_passwd_cb_userdata(ssl_ctx, @ptrCast(@constCast(pw)));
        }
        const ret = if (key_blob) |kb|
            if (kb.data != null and kb.len > 0)
                wssl_ext.wolfSSL_CTX_use_PrivateKey_buffer(ssl_ctx, @ptrCast(kb.data.?), @intCast(kb.len), file_type)
            else
                0
        else
            wssl_ext.wolfSSL_CTX_use_PrivateKey_file(ssl_ctx, key_file.?, file_type);
        if (ret != 1) {
            c_ext.Curl_failf(data, "unable to set private key");
            result = CURLE_SSL_CERTPROBLEM;
            return result;
        }
    }

    wssl_ext.wolfSSL_CTX_set_verify(
        ssl_ctx,
        if (conn_config.verifypeer()) WOLFSSL_VERIFY_PEER else WOLFSSL_VERIFY_NONE,
        null,
    );

    if (cb_setup) |setup_fn| {
        result = setup_fn(cf, data, cb_user_data);
        if (result != CURLE_OK) return result;
    }

    var fsslctx_fn: ?*const anyopaque = null;
    var fsslctx_p: ?*anyopaque = null;
    if (c_ext.Curl_vtls_acc_ssl_fsslctx(data, &fsslctx_fn, &fsslctx_p)) {
        if (!wctx.x509_store_setup()) {
            result = Curl_wssl_setup_x509_store(cf, data, wctx);
            if (result != CURLE_OK) return result;
        }
        if (fsslctx_fn) |fn_ptr| {
            c_ext.Curl_pgrsTime(data, vtls_backends.TIMER_APPCONNECT);
            const cb: *const fn (?*CurlEasy, ?*anyopaque, ?*anyopaque) callconv(.c) CURLcode = @ptrCast(@alignCast(fn_ptr));
            result = cb(data, ssl_ctx, fsslctx_p);
            if (result != CURLE_OK) {
                c_ext.Curl_failf(data, "error signaled by SSL ctx callback");
                return result;
            }
        }
    }

    const ssl = wssl_ext.wolfSSL_new(ssl_ctx) orelse {
        result = CURLE_OUT_OF_MEMORY;
        return result;
    };
    wctx.ssl = ssl;
    _ = wssl_ext.wolfSSL_set_app_data(ssl, ssl_user_data);

    if (peer.sni) |sni| {
        const sni_len = std.mem.len(sni);
        if (sni_len > 0 and sni_len <= std.math.maxInt(c_ushort)) {
            if (wssl_ext.wolfSSL_UseSNI(ssl, WOLFSSL_SNI_HOST_NAME, sni, @intCast(sni_len)) != WOLFSSL_SUCCESS) {
                c_ext.Curl_failf(data, "Failed to set SNI");
                result = CURLE_SSL_CONNECT_ERROR;
                return result;
            }
        }
    }

    if (conn_config.primary_cache_session()) {
        if (peer.scache_key) |scache_key| {
            if (data) |d| {
                var scache: ?*vtls_impl.CurlSslScache = null;
                var has_share_scache = false;
                var trc_feat: ?*vtls_impl.CurlTrcFeat = null;
                c_ext.Curl_vtls_acc_scache_params(d, &scache, &has_share_scache, &trc_feat);
                var scs: ?*CurlSslSession = null;
                if (vtls_scache_asn1.Curl_ssl_scache_take_zig(cf, d, scache, has_share_scache, conn_config, trc_feat, scache_key, &scs) == CURLE_OK) {
                    if (scs) |s| {
                        var applied = false;
                        if (s.sdata != null and s.sdata_len > 0) {
                            var sdata_ptr: [*]const u8 = @ptrCast(s.sdata.?);
                            if (wssl_ext.wolfSSL_d2i_SSL_SESSION(null, &sdata_ptr, @intCast(s.sdata_len))) |w_sess| {
                                defer wssl_ext.wolfSSL_SESSION_free(w_sess);
                                if (wssl_ext.wolfSSL_set_session(ssl, w_sess) == WOLFSSL_SUCCESS) {
                                    applied = true;
                                    if (sess_reuse_cb) |reuse_cb| {
                                        var do_early_data = false;
                                        if (reuse_cb(cf, data, alpns_requested, s, &do_early_data) != CURLE_OK) {
                                            applied = false;
                                        }
                                    }
                                }
                            }
                        }
                        if (applied) {
                            c_ext.Curl_infof(d, "SSL reusing session ID");
                            vtls_scache_asn1.Curl_ssl_scache_return_zig(cf, d, scache, has_share_scache, conn_config, trc_feat, scache_key, s);
                        } else {
                            vtls_scache_asn1.Curl_ssl_session_destroy(s);
                        }
                    }
                }
            }
        }
    }

    if (alpns_requested) |alpn_spec| {
        if (alpn_spec.count > 0) {
            var proto: vtls_backends.AlpnProtoBuf = .{
                .data = @splat(0),
                .len = 0,
            };
            result = vtls_impl.Curl_alpn_to_proto_str(&proto, alpn_spec);
            if (result != CURLE_OK) return result;
            if (proto.len > 0) {
                if (wssl_ext.wolfSSL_UseALPN(
                    ssl,
                    &proto.data,
                    @intCast(proto.len),
                    WOLFSSL_ALPN_CONTINUE_ON_MISMATCH,
                ) != SSL_SUCCESS) {
                    c_ext.Curl_failf(data, "SSL: failed setting ALPN protocols");
                    result = CURLE_SSL_CONNECT_ERROR;
                    return result;
                }
            }
        }
    }

    if (vtls_core.Curl_tls_keylog_enabled()) {
        wssl_ext.wolfSSL_KeepArrays(ssl);
    }

    _ = wssl_ext.wolfSSL_UseSecureRenegotiation(ssl);
    return CURLE_OK;
}

fn wssl_collect_certinfo(data: ?*CurlEasy, ssl: *WOLFSSL) CURLcode {
    if (comptime !use_wolfssl) return CURLE_NOT_BUILT_IN;
    const chain = wssl_ext.wolfSSL_get_peer_chain(ssl) orelse return CURLE_OK;
    const num_certs = wssl_ext.wolfSSL_get_chain_count(chain);
    if (num_certs <= 0) return CURLE_OK;

    var rc = vtls_impl.Curl_ssl_init_certinfo(data, num_certs);
    if (rc != CURLE_OK) return rc;

    var i: c_int = 0;
    while (i < num_certs) : (i += 1) {
        const der_ptr = wssl_ext.wolfSSL_get_chain_cert(chain, i) orelse continue;
        const der_len = wssl_ext.wolfSSL_get_chain_length(chain, i);
        if (der_len > 0) {
            rc = vtls_scache_asn1.Curl_extract_certinfo_zig(
                data,
                i,
                der_ptr,
                der_ptr + @as(usize, @intCast(der_len)),
                true,
                @ptrCast(&vtls_impl.Curl_ssl_push_certinfo_len),
            );
            if (rc != CURLE_OK) return rc;
        }
    }
    return CURLE_OK;
}

fn wssl_handshake(cf: *CurlCfilter, data: ?*CurlEasy) CURLcode {
    if (comptime !use_wolfssl) return CURLE_NOT_BUILT_IN;
    const connssl: *SslConnectData = @ptrCast(@alignCast(cf.ctx orelse return CURLE_SSL_CONNECT_ERROR));
    const backend: *WsslSslBackendData = @ptrCast(@alignCast(connssl.backend orelse return CURLE_SSL_CONNECT_ERROR));
    const conn_config = vtls_impl.Curl_ssl_cf_get_filter_config(cf) orelse return CURLE_SSL_CONNECT_ERROR;
    const ssl_config = vtls_impl.Curl_ssl_cf_get_easy_config(cf, data);
    const ssl = backend.ssl orelse return CURLE_SSL_CONNECT_ERROR;
    _ = backend.ssl_ctx orelse return CURLE_SSL_CONNECT_ERROR;

    const store_rc = Curl_wssl_setup_x509_store(cf, data, backend);
    if (store_rc != CURLE_OK) return store_rc;

    connssl.io_need = vtls_backends.CURL_SSL_IO_NEED_NONE;
    wssl_ext.wolfSSL_ERR_clear_error();
    backend.io_result = CURLE_OK;

    var ret = wssl_ext.wolfSSL_connect(ssl);

    if (!backend.x509_store_setup()) {
        const after_rc = Curl_wssl_setup_x509_store(cf, data, backend);
        if (after_rc != CURLE_OK) return after_rc;
    }

    if (vtls_core.Curl_tls_keylog_enabled()) {
        if (ret == WOLFSSL_SUCCESS or
            (wssl_ext.wolfSSL_want_read(ssl) == 0 and wssl_ext.wolfSSL_want_write(ssl) == 0))
        {
            wssl_log_tls12_secret(ssl);
            wssl_ext.wolfSSL_FreeArrays(ssl);
        }
    }

    var detail = wssl_ext.wolfSSL_get_error(ssl, ret);

    if (ret == WOLFSSL_SUCCESS and conn_config.verifyhost() and connssl.peer.sni == null) {
        const cert = wssl_ext.wolfSSL_get_peer_certificate(ssl) orelse {
            c_ext.Curl_failf(data, "unable to get peer certificate");
            return CURLE_PEER_FAILED_VERIFICATION;
        };
        defer wssl_ext.wolfSSL_X509_free(cert);
        ret = wssl_ext.wolfSSL_X509_check_ip_asc(cert, peerHostname(&connssl.peer), 0);
        if (ret != WOLFSSL_SUCCESS) {
            detail = DOMAIN_NAME_MISMATCH;
        }
    }

    if (ret != 1) {
        if (detail == WOLFSSL_ERROR_WANT_READ) {
            connssl.io_need = vtls_backends.CURL_SSL_IO_NEED_RECV;
            return CURLE_OK;
        } else if (detail == WOLFSSL_ERROR_WANT_WRITE) {
            connssl.io_need = vtls_backends.CURL_SSL_IO_NEED_SEND;
            return CURLE_OK;
        } else if (detail == DOMAIN_NAME_MISMATCH) {
            c_ext.Curl_failf(data, " subject alt name(s) or common name do not match \"%s\"", peerDispname(&connssl.peer));
            return CURLE_PEER_FAILED_VERIFICATION;
        } else if (detail == ASN_NO_SIGNER_E) {
            c_ext.Curl_failf(data, "SSL: certificate Verify locations/signers failed (ASN_NO_SIGNER_E)");
            if (ssl_config) |sc| {
                sc.certverifyresult = X509_V_ERR_UNABLE_TO_GET_ISSUER_CERT_LOCALLY;
            }
            return CURLE_PEER_FAILED_VERIFICATION;
        } else if (detail == ASN_AFTER_DATE_E) {
            c_ext.Curl_failf(data, "server verification failed: certificate has expired.");
            return CURLE_PEER_FAILED_VERIFICATION;
        } else if (detail == ASN_BEFORE_DATE_E) {
            c_ext.Curl_failf(data, "server verification failed: certificate not valid yet.");
            return CURLE_PEER_FAILED_VERIFICATION;
        } else if (detail == WOLFSSL_ERROR_SYSCALL) {
            if (backend.io_result != CURLE_OK and backend.io_result != CURLE_AGAIN) {
                return backend.io_result;
            }
            c_ext.Curl_failf(
                data,
                "SSL_connect failed with error %d: %s",
                detail,
                peerDispname(&connssl.peer),
            );
            return CURLE_SSL_CONNECT_ERROR;
        } else {
            const verify_res = wssl_ext.wolfSSL_get_verify_result(ssl);
            if (ssl_config) |sc| {
                sc.certverifyresult = verify_res;
            }
            var error_buffer: [WOLFSSL_MAX_ERROR_SZ]u8 = @splat(0);
            const err_str = wsslStrerror(@intCast(@as(c_uint, @bitCast(detail))), &error_buffer);
            if (verify_res != X509_V_OK and conn_config.verifypeer()) {
                c_ext.Curl_failf(data, "SSL certificate problem: %s", err_str);
                return CURLE_PEER_FAILED_VERIFICATION;
            }
            if (conn_config.verifyhost() and std.mem.indexOf(u8, err_str[0..std.mem.len(err_str)], "domain name mismatch") != null) {
                c_ext.Curl_failf(data, "SSL: certificate subject name does not match target host name '%s'", peerDispname(&connssl.peer));
                return CURLE_PEER_FAILED_VERIFICATION;
            }
            c_ext.Curl_failf(data, "SSL_connect failed with error %d: %s", detail, err_str);
            return CURLE_SSL_CONNECT_ERROR;
        }
    }

    connssl.connecting_state = vtls_impl.ssl_connect_3;
    c_ext.Curl_infof(data, "SSL connection using %s / %s", wssl_ext.wolfSSL_get_version(ssl) orelse "unknown", wssl_ext.wolfSSL_get_cipher_name(ssl) orelse "unknown");
    return CURLE_OK;
}

fn wssl_connect_step3(cf: *CurlCfilter, data: ?*CurlEasy) CURLcode {
    if (comptime !use_wolfssl) return CURLE_NOT_BUILT_IN;
    const connssl: *SslConnectData = @ptrCast(@alignCast(cf.ctx orelse return CURLE_SSL_CONNECT_ERROR));
    const backend: *WsslSslBackendData = @ptrCast(@alignCast(connssl.backend orelse return CURLE_SSL_CONNECT_ERROR));
    const ssl = backend.ssl orelse return CURLE_SSL_CONNECT_ERROR;

    const pin_rc = wssl_pin_peer_pubkey(cf, data, backend);
    if (pin_rc != CURLE_OK) {
        c_ext.Curl_failf(data, "SSL: public key does not match pinned public key");
        return pin_rc;
    }

    if (connssl.alpn != null) {
        var proto: ?[*]u8 = null;
        var proto_len: c_ushort = 0;
        const rc_alpn = wssl_ext.wolfSSL_ALPN_GetProtocol(ssl, &proto, &proto_len);
        if (rc_alpn == WOLFSSL_SUCCESS) {
            const set_rc = vtls_impl.Curl_alpn_set_negotiated(cf, data, connssl, proto, proto_len);
            if (set_rc != CURLE_OK) return set_rc;
        } else {
            const set_rc = vtls_impl.Curl_alpn_set_negotiated(cf, data, connssl, null, 0);
            if (set_rc != CURLE_OK) return set_rc;
        }
    }

    if (c_ext.Curl_vtls_acc_ssl_certinfo(data)) {
        const cert_rc = wssl_collect_certinfo(data, ssl);
        if (cert_rc != CURLE_OK) return cert_rc;
    }

    connssl.connecting_state = vtls_impl.ssl_connect_done;
    return CURLE_OK;
}

fn wsslInit() callconv(.c) c_int {
    if (comptime use_wolfssl) {
        if (wssl_ext.wolfSSL_Init() != WOLFSSL_SUCCESS) {
            return 0;
        }
        if (wssl_bio_cf_init_methods() != CURLE_OK) {
            return 0;
        }
        vtls_core.Curl_tls_keylog_open();
        return 1;
    }
    return 0;
}

fn wsslCleanup() callconv(.c) void {
    if (comptime use_wolfssl) {
        wssl_bio_cf_free_methods();
        _ = wssl_ext.wolfSSL_Cleanup();
        vtls_core.Curl_tls_keylog_close();
    }
}

fn wsslVersion(buffer: [*]u8, size: usize) callconv(.c) usize {
    if (comptime use_wolfssl) {
        const ver = wssl_ext.wolfSSL_lib_version() orelse "";
        const n = c_ext.curl_msnprintf(buffer, size, "wolfSSL/%s", ver);
        return if (n > 0) @intCast(n) else 0;
    }
    return 0;
}

fn wsslShutdown(
    cf: *CurlCfilter,
    data: ?*CurlEasy,
    send_shutdown: bool,
    done: *bool,
) callconv(.c) CURLcode {
    if (comptime !use_wolfssl) {
        done.* = true;
        return CURLE_OK;
    }
    const connssl: *SslConnectData = @ptrCast(@alignCast(cf.ctx orelse {
        done.* = true;
        return CURLE_OK;
    }));
    const backend: *WsslSslBackendData = @ptrCast(@alignCast(connssl.backend orelse {
        done.* = true;
        return CURLE_OK;
    }));

    if (backend.ssl == null or cf.isShutdown()) {
        done.* = true;
        return CURLE_OK;
    }

    const ssl = backend.ssl.?;
    connssl.call_data = data;
    backend.handle = data;
    defer connssl.call_data = null;

    backend.set_shutting_down(true);
    connssl.io_need = vtls_backends.CURL_SSL_IO_NEED_NONE;
    done.* = false;

    const result: CURLcode = CURLE_OK;
    var buf: [1024]u8 = undefined;
    var loop_max: usize = 10;

    while (!connssl.peer_closed() and loop_max > 0) : (loop_max -= 1) {
        wssl_ext.wolfSSL_ERR_clear_error();
        backend.io_result = CURLE_OK;

        if (send_shutdown) {
            const sret = wssl_ext.wolfSSL_shutdown(ssl);
            if (sret == 1) {
                done.* = true;
                break;
            }
        }

        wssl_ext.wolfSSL_ERR_clear_error();
        const nread = wssl_ext.wolfSSL_read(ssl, &buf, @intCast(buf.len));
        if (nread <= 0) {
            const err = wssl_ext.wolfSSL_get_error(ssl, nread);
            switch (err) {
                WOLFSSL_ERROR_ZERO_RETURN, WOLFSSL_ERROR_NONE => {
                    connssl.set_peer_closed(true);
                    done.* = true;
                    break;
                },
                WOLFSSL_ERROR_WANT_READ => {
                    connssl.io_need = vtls_backends.CURL_SSL_IO_NEED_RECV;
                    break;
                },
                WOLFSSL_ERROR_WANT_WRITE => {
                    connssl.io_need = vtls_backends.CURL_SSL_IO_NEED_SEND;
                    break;
                },
                else => {
                    done.* = true;
                    break;
                },
            }
        }
    }

    if (done.* or (connssl.io_need == 0 and loop_max == 0)) {
        cf.setShutdown(true);
        done.* = true;
    }
    return result;
}

fn wsslDataPending(cf: *CurlCfilter, data: ?*const CurlEasy) callconv(.c) bool {
    if (comptime !use_wolfssl) return false;
    _ = data;
    const connssl: *SslConnectData = @ptrCast(@alignCast(cf.ctx orelse return false));
    const backend: *WsslSslBackendData = @ptrCast(@alignCast(connssl.backend orelse return false));
    if (backend.ssl) |ssl| {
        return wssl_ext.wolfSSL_pending(ssl) != 0;
    }
    return false;
}

fn wsslRandom(
    data: ?*CurlEasy,
    entropy: [*]u8,
    length: usize,
) callconv(.c) CURLcode {
    _ = data;
    if (comptime use_wolfssl) {
        var rng_buf: WcRngStorage = .{};
        if (wssl_ext.wc_InitRng(&rng_buf) != 0) {
            return CURLE_FAILED_INIT;
        }
        defer _ = wssl_ext.wc_FreeRng(&rng_buf);
        if (length > std.math.maxInt(c_uint)) {
            return CURLE_FAILED_INIT;
        }
        if (wssl_ext.wc_RNG_GenerateBlock(&rng_buf, entropy, @intCast(length)) != 0) {
            return CURLE_FAILED_INIT;
        }
        return CURLE_OK;
    }
    return CURLE_NOT_BUILT_IN;
}

fn wsslConnect(
    cf: *CurlCfilter,
    data: ?*CurlEasy,
    done: *bool,
) callconv(.c) CURLcode {
    if (comptime !use_wolfssl) {
        done.* = false;
        return CURLE_SSL_CONNECT_ERROR;
    }
    const connssl: *SslConnectData = @ptrCast(@alignCast(cf.ctx orelse return CURLE_SSL_CONNECT_ERROR));
    const backend: *WsslSslBackendData = @ptrCast(@alignCast(connssl.backend orelse return CURLE_SSL_CONNECT_ERROR));

    if (connssl.state == vtls_impl.ssl_connection_complete) {
        done.* = true;
        return CURLE_OK;
    }

    done.* = false;
    connssl.io_need = vtls_backends.CURL_SSL_IO_NEED_NONE;
    connssl.call_data = data;
    backend.handle = data;
    defer connssl.call_data = null;

    if (connssl.connecting_state == vtls_impl.ssl_connect_1) {
        const rc = wssl_init_step1(cf, data);
        if (rc != CURLE_OK) return rc;
        connssl.connecting_state = vtls_impl.ssl_connect_2;
    }

    if (connssl.connecting_state == vtls_impl.ssl_connect_2) {
        const rc = wssl_handshake(cf, data);
        if (rc != CURLE_OK) return rc;
    }

    if (connssl.connecting_state == vtls_impl.ssl_connect_3) {
        const rc = wssl_connect_step3(cf, data);
        if (rc != CURLE_OK) return rc;
    }

    if (connssl.connecting_state == vtls_impl.ssl_connect_done) {
        connssl.state = vtls_impl.ssl_connection_complete;
        done.* = true;
    }
    return CURLE_OK;
}

fn wsslGetInternals(connssl: *SslConnectData, info: c_uint) callconv(.c) ?*anyopaque {
    const backend: *WsslSslBackendData = @ptrCast(@alignCast(connssl.backend orelse return null));
    return if (info == vtls_impl.CURLINFO_TLS_SESSION)
        @ptrCast(backend.ssl_ctx)
    else
        @ptrCast(backend.ssl);
}

fn wsslClose(cf: *CurlCfilter, data: ?*CurlEasy) callconv(.c) void {
    if (comptime !use_wolfssl) return;
    const connssl: *SslConnectData = @ptrCast(@alignCast(cf.ctx orelse return));
    const backend: *WsslSslBackendData = @ptrCast(@alignCast(connssl.backend orelse return));

    connssl.call_data = data;
    backend.handle = data;
    defer connssl.call_data = null;

    if (backend.ssl) |ssl| {
        wssl_ext.wolfSSL_free(ssl);
        backend.ssl = null;
    }
    if (backend.ssl_ctx) |ctx| {
        wssl_ext.wolfSSL_CTX_free(ctx);
        backend.ssl_ctx = null;
    }
    backend.set_shutting_down(false);
    backend.set_x509_store_setup(false);
}

fn wsslSha256sum(
    input: ?[*]const u8,
    inputlen: usize,
    sha256sum: [*]u8,
    sha256len: usize,
) callconv(.c) CURLcode {
    _ = sha256len;
    if (comptime use_wolfssl) {
        var sha_buf: WcSha256Storage = .{};
        if (wssl_ext.wc_InitSha256(&sha_buf) != 0) {
            return CURLE_FAILED_INIT;
        }
        if (wssl_ext.wc_Sha256Update(&sha_buf, input, @intCast(inputlen)) != 0) {
            return CURLE_FAILED_INIT;
        }
        if (wssl_ext.wc_Sha256Final(&sha_buf, sha256sum) != 0) {
            return CURLE_FAILED_INIT;
        }
        return CURLE_OK;
    }
    return CURLE_NOT_BUILT_IN;
}

fn wsslRecv(
    cf: *CurlCfilter,
    data: ?*CurlEasy,
    buf: [*]u8,
    buffersize: usize,
    pnread: *usize,
) callconv(.c) CURLcode {
    if (comptime !use_wolfssl) {
        pnread.* = 0;
        return CURLE_RECV_ERROR;
    }
    const connssl: *SslConnectData = @ptrCast(@alignCast(cf.ctx orelse return CURLE_RECV_ERROR));
    const backend: *WsslSslBackendData = @ptrCast(@alignCast(connssl.backend orelse return CURLE_RECV_ERROR));
    const ssl = backend.ssl orelse return CURLE_RECV_ERROR;

    pnread.* = 0;
    connssl.io_need = vtls_backends.CURL_SSL_IO_NEED_NONE;
    connssl.call_data = data;
    backend.handle = data;
    defer connssl.call_data = null;

    wssl_ext.wolfSSL_ERR_clear_error();
    backend.io_result = CURLE_OK;

    const buffsize: c_int = if (buffersize > std.math.maxInt(c_int)) std.math.maxInt(c_int) else @intCast(buffersize);
    const nread = wssl_ext.wolfSSL_read(ssl, buf, buffsize);
    if (nread <= 0) {
        const err = wssl_ext.wolfSSL_get_error(ssl, nread);
        switch (err) {
            WOLFSSL_ERROR_ZERO_RETURN => {
                connssl.set_peer_closed(true);
                return CURLE_OK;
            },
            WOLFSSL_ERROR_NONE => {
                return CURLE_OK;
            },
            WOLFSSL_ERROR_SYSCALL => {
                if (backend.io_result == CURLE_OK and connssl.peer_closed()) {
                    return CURLE_OK;
                }
                if (backend.io_result == CURLE_AGAIN) {
                    return CURLE_AGAIN;
                }
                if (backend.io_result != CURLE_OK) {
                    return backend.io_result;
                }
                return CURLE_RECV_ERROR;
            },
            WOLFSSL_ERROR_WANT_READ => {
                connssl.io_need = vtls_backends.CURL_SSL_IO_NEED_RECV;
                return CURLE_AGAIN;
            },
            WOLFSSL_ERROR_WANT_WRITE => {
                connssl.io_need = vtls_backends.CURL_SSL_IO_NEED_SEND;
                return CURLE_AGAIN;
            },
            MEMORY_E => return CURLE_OUT_OF_MEMORY,
            else => {
                if (backend.io_result == CURLE_AGAIN) {
                    return CURLE_AGAIN;
                }
                var error_buffer: [WOLFSSL_MAX_ERROR_SZ]u8 = @splat(0);
                c_ext.Curl_failf(
                    data,
                    "wolfSSL_read() returned %s (%d)",
                    wsslStrerror(@intCast(@as(c_uint, @bitCast(err))), &error_buffer),
                    err,
                );
                return CURLE_RECV_ERROR;
            },
        }
    }

    pnread.* = @intCast(nread);
    return CURLE_OK;
}

fn wsslSend(
    cf: *CurlCfilter,
    data: ?*CurlEasy,
    mem_ptr: ?*const anyopaque,
    len: usize,
    pnwritten: *usize,
) callconv(.c) CURLcode {
    if (comptime !use_wolfssl) {
        pnwritten.* = 0;
        return CURLE_SEND_ERROR;
    }
    const connssl: *SslConnectData = @ptrCast(@alignCast(cf.ctx orelse return CURLE_SEND_ERROR));
    const backend: *WsslSslBackendData = @ptrCast(@alignCast(connssl.backend orelse return CURLE_SEND_ERROR));
    const ssl = backend.ssl orelse return CURLE_SEND_ERROR;

    pnwritten.* = 0;
    connssl.io_need = vtls_backends.CURL_SSL_IO_NEED_NONE;
    connssl.call_data = data;
    backend.handle = data;
    defer connssl.call_data = null;

    wssl_ext.wolfSSL_ERR_clear_error();
    backend.io_result = CURLE_OK;

    const write_len: c_int = if (len > std.math.maxInt(c_int)) std.math.maxInt(c_int) else @intCast(len);
    const rc = wssl_ext.wolfSSL_write(ssl, mem_ptr, write_len);
    if (rc <= 0) {
        const err = wssl_ext.wolfSSL_get_error(ssl, rc);
        switch (err) {
            WOLFSSL_ERROR_WANT_READ => {
                connssl.io_need = vtls_backends.CURL_SSL_IO_NEED_RECV;
                return CURLE_AGAIN;
            },
            WOLFSSL_ERROR_WANT_WRITE => {
                connssl.io_need = vtls_backends.CURL_SSL_IO_NEED_SEND;
                return CURLE_AGAIN;
            },
            MEMORY_E => return CURLE_OUT_OF_MEMORY,
            WOLFSSL_ERROR_SYSCALL => {
                if (backend.io_result == CURLE_AGAIN) return CURLE_AGAIN;
                if (backend.io_result != CURLE_OK) return backend.io_result;
                return CURLE_SEND_ERROR;
            },
            else => {
                var error_buffer: [WOLFSSL_MAX_ERROR_SZ]u8 = @splat(0);
                c_ext.Curl_failf(
                    data,
                    "wolfSSL_write() returned %s (%d)",
                    wsslStrerror(@intCast(@as(c_uint, @bitCast(err))), &error_buffer),
                    err,
                );
                return CURLE_SEND_ERROR;
            },
        }
    }

    pnwritten.* = @intCast(rc);
    return CURLE_OK;
}

pub const Curl_ssl_wolfssl = vtls_impl.CurlSsl{
    .info = .{
        .id = vtls_impl.CURLSSLBACKEND_WOLFSSL,
        .name = "wolfssl",
    },
    .supports = vtls_impl.SSLSUPP_PINNEDPUBKEY |
        vtls_impl.SSLSUPP_HTTPS_PROXY |
        vtls_impl.SSLSUPP_CA_PATH |
        vtls_impl.SSLSUPP_CAINFO_BLOB |
        vtls_impl.SSLSUPP_SSL_CTX |
        vtls_impl.SSLSUPP_TLS13_CIPHERSUITES |
        vtls_impl.SSLSUPP_CA_CACHE |
        vtls_impl.SSLSUPP_CIPHER_LIST |
        vtls_impl.SSLSUPP_SSL_EC_CURVES,
    .sizeof_ssl_backend_data = @sizeOf(WsslSslBackendData),
    .init = wsslInit,
    .cleanup = wsslCleanup,
    .version = wsslVersion,
    .shut_down = wsslShutdown,
    .data_pending = wsslDataPending,
    .random = wsslRandom,
    .cert_status_request = null,
    .do_connect = wsslConnect,
    .adjust_pollset = vtls_impl.Curl_ssl_adjust_pollset,
    .get_internals = wsslGetInternals,
    .close = wsslClose,
    .close_all = null,
    .engines_list = null,
    .sha256sum = wsslSha256sum,
    .recv_plain = wsslRecv,
    .send_plain = wsslSend,
    .get_channel_binding = null,
};

comptime {
    if (use_wolfssl) {
        @export(&Curl_ssl_wolfssl, .{ .name = "Curl_ssl_wolfssl" });
        @export(&Curl_wssl_setup_x509_store, .{ .name = "Curl_wssl_setup_x509_store" });
    }
}

test "wolfSSL helpers, flags, and crypto callbacks" {
    try std.testing.expectEqual(SSL_FILETYPE_PEM, do_file_type(null));
    try std.testing.expectEqual(SSL_FILETYPE_PEM, do_file_type(""));
    try std.testing.expectEqual(SSL_FILETYPE_PEM, do_file_type("PEM"));
    try std.testing.expectEqual(SSL_FILETYPE_PEM, do_file_type("pem"));
    try std.testing.expectEqual(SSL_FILETYPE_ASN1, do_file_type("DER"));
    try std.testing.expectEqual(SSL_FILETYPE_ASN1, do_file_type("der"));
    try std.testing.expectEqual(@as(c_int, -1), do_file_type("P12"));

    var bdata = WsslSslBackendData{};
    try std.testing.expect(!bdata.x509_store_setup());
    try std.testing.expect(!bdata.shutting_down());
    bdata.set_x509_store_setup(true);
    try std.testing.expect(bdata.x509_store_setup());
    bdata.set_shutting_down(true);
    try std.testing.expect(bdata.shutting_down());
    bdata.set_x509_store_setup(false);
    try std.testing.expect(!bdata.x509_store_setup());
    try std.testing.expect(bdata.shutting_down());

    var pw_buf: [16]u8 = @splat(0);
    const pw: [*:0]const u8 = "secret";
    try std.testing.expectEqual(@as(c_int, 6), wsslPasswdCallback(&pw_buf, pw_buf.len, 0, @ptrCast(@constCast(pw))));
    try std.testing.expectEqualStrings("secret", pw_buf[0..6]);
    try std.testing.expectEqual(@as(c_int, 0), wsslPasswdCallback(&pw_buf, 4, 0, @ptrCast(@constCast(pw))));

    if (comptime use_wolfssl) {
        var ver_buf: [64]u8 = @splat(0);
        const ver_len = wsslVersion(&ver_buf, ver_buf.len);
        try std.testing.expect(ver_len > "wolfSSL/".len);
        try std.testing.expect(std.mem.startsWith(u8, ver_buf[0..ver_len], "wolfSSL/"));

        var sha_out: [32]u8 = undefined;
        const msg = "abc";
        try std.testing.expectEqual(CURLE_OK, wsslSha256sum(msg.ptr, msg.len, &sha_out, sha_out.len));
        const expected_abc = [_]u8{
            0xba, 0x78, 0x16, 0xbf, 0x8f, 0x01, 0xcf, 0xea,
            0x41, 0x41, 0x40, 0xde, 0x5d, 0xae, 0x22, 0x23,
            0xb0, 0x03, 0x61, 0xa3, 0x96, 0x17, 0x7a, 0x9c,
            0xb4, 0x10, 0xff, 0x61, 0xf2, 0x00, 0x15, 0xad,
        };
        try std.testing.expectEqualSlices(u8, &expected_abc, &sha_out);

        var rand_buf: [16]u8 = @splat(0);
        try std.testing.expectEqual(CURLE_OK, wsslRandom(null, &rand_buf, rand_buf.len));
    }
}
