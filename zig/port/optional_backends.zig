const std = @import("std");
const vquic_core = @import("vquic_core.zig");
const vssh = @import("vssh.zig");

// Zig port of optional/disabled backend modules (Phase 7 Session 38):
//   - lib/ldap.c, lib/openldap.c (lib/curl_ldap.h)
//   - lib/vquic/cf-ngtcp2-cmn.c, lib/vquic/cf-ngtcp2-proxy.c,
//     lib/vquic/cf-ngtcp2.c, lib/vquic/cf-quiche.c,
//     lib/vquic/vquic-tls.c, lib/vquic/vquic.c (lib/vquic/vquic.h)
//   - lib/vssh/libssh.c, lib/vssh/libssh2.c, lib/vssh/vssh.c
//     (lib/vssh/ssh.h, lib/vssh/vssh.h)
//   - lib/vtls/gtls.c (lib/vtls/gtls.h),
//     lib/vtls/rustls.c (lib/vtls/rustls.h),
//     lib/vtls/wolfssl.c (lib/vtls/wolfssl.h)

pub const CURLcode = c_uint;
pub const CURLE_OK: CURLcode = 0;
pub const CURLE_UNSUPPORTED_PROTOCOL: CURLcode = 1;
pub const CURLE_FAILED_INIT: CURLcode = 2;
pub const CURLE_URL_MALFORMAT: CURLcode = 3;
pub const CURLE_NOT_BUILT_IN: CURLcode = 4;
pub const CURLE_COULDNT_CONNECT: CURLcode = 7;
pub const CURLE_REMOTE_ACCESS_DENIED: CURLcode = 9;
pub const CURLE_OUT_OF_MEMORY: CURLcode = 27;
pub const CURLE_OPERATION_TIMEDOUT: CURLcode = 28;
pub const CURLE_RANGE_ERROR: CURLcode = 33;
pub const CURLE_SEND_ERROR: CURLcode = 55;
pub const CURLE_RECV_ERROR: CURLcode = 56;
pub const CURLE_PEER_FAILED_VERIFICATION: CURLcode = 60;
pub const CURLE_LOGIN_DENIED: CURLcode = 67;
pub const CURLE_REMOTE_DISK_FULL: CURLcode = 70;
pub const CURLE_REMOTE_FILE_EXISTS: CURLcode = 73;
pub const CURLE_REMOTE_FILE_NOT_FOUND: CURLcode = 78;
pub const CURLE_SSH: CURLcode = 79;
pub const CURLE_AGAIN: CURLcode = 81;
pub const CURLE_HTTP3: CURLcode = 95;
pub const CURLE_QUIC_CONNECT_ERROR: CURLcode = 96;

pub const curl_off_t = i64;

pub const CURLPROTO_SCP: u32 = 1 << 4;
pub const CURLPROTO_SFTP: u32 = 1 << 5;
pub const CURLPROTO_LDAP: u32 = 1 << 7;
pub const CURLPROTO_LDAPS: u32 = 1 << 8;

pub const PROTO_FAMILY_SSH: u32 = CURLPROTO_SCP | CURLPROTO_SFTP;
pub const PROTO_FAMILY_LDAP: u32 = CURLPROTO_LDAP | CURLPROTO_LDAPS;

pub const PORT_SSH: u16 = 22;
pub const PORT_LDAP: u16 = 389;
pub const PORT_LDAPS: u16 = 636;

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

// ============================================================================
// 1. LDAP / OpenLDAP (lib/ldap.c, lib/openldap.c, lib/curl_ldap.h)
// ============================================================================

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
/// Matches `str_needs_base64()` in `lib/openldap.c`.
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

pub fn Curl_ldap_version(buf: [*]u8, bufsz: usize) callconv(.c) void {
    if (bufsz == 0) return;
    const prefix = "OpenLDAP";
    const copy_len = @min(prefix.len, bufsz - 1);
    @memcpy(buf[0..copy_len], prefix[0..copy_len]);
    buf[copy_len] = 0;
}

fn ldapDisabledDo(data: ?*anyopaque, done: *bool) callconv(.c) CURLcode {
    _ = data;
    done.* = false;
    return CURLE_NOT_BUILT_IN;
}

pub const Curl_protocol_ldap = Curl_protocol{
    .do_it = ldapDisabledDo,
};

// ============================================================================
// 2. VQUIC / HTTP/3 (lib/vquic/vquic.c, cf-ngtcp2*.c, cf-quiche.c, vquic-tls.c)
// ============================================================================

pub const CF_TYPE_IP_CONNECT: c_int = 1 << 0;
pub const CF_TYPE_SSL: c_int = 1 << 1;
pub const CF_TYPE_MULTIPLEX: c_int = 1 << 2;
pub const CF_TYPE_PROXY: c_int = 1 << 3;
pub const CF_TYPE_HTTP: c_int = 1 << 4;

pub const vquic_h3_error = enum(u64) {
    CURL_H3_ERR_NO_ERROR = 0x0100,
    CURL_H3_ERR_GENERAL_PROTOCOL_ERROR = 0x0101,
    CURL_H3_ERR_INTERNAL_ERROR = 0x0102,
    CURL_H3_ERR_STREAM_CREATION_ERROR = 0x0103,
    CURL_H3_ERR_CLOSED_CRITICAL_STREAM = 0x0104,
    CURL_H3_ERR_FRAME_UNEXPECTED = 0x0105,
    CURL_H3_ERR_FRAME_ERROR = 0x0106,
    CURL_H3_ERR_EXCESSIVE_LOAD = 0x0107,
    CURL_H3_ERR_ID_ERROR = 0x0108,
    CURL_H3_ERR_SETTINGS_ERROR = 0x0109,
    CURL_H3_ERR_MISSING_SETTINGS = 0x010a,
    CURL_H3_ERR_REQUEST_REJECTED = 0x010b,
    CURL_H3_ERR_REQUEST_CANCELLED = 0x010c,
    CURL_H3_ERR_REQUEST_INCOMPLETE = 0x010d,
    CURL_H3_ERR_MESSAGE_ERROR = 0x010e,
    CURL_H3_ERR_CONNECT_ERROR = 0x010f,
    CURL_H3_ERR_VERSION_FALLBACK = 0x0110,
};

pub const h3_tunnel_state = enum(c_uint) {
    H3_TUNNEL_INIT = 0,
    H3_TUNNEL_CONNECT,
    H3_TUNNEL_RESPONSE,
    H3_TUNNEL_ESTABLISHED,
    H3_TUNNEL_FAILED,
};

pub const VquicCftypeDescriptor = struct {
    name: [*:0]const u8,
    flags: c_int,
    log_level: c_int,
};

pub const Curl_cft_http3_desc = VquicCftypeDescriptor{
    .name = "HTTP/3",
    .flags = CF_TYPE_IP_CONNECT | CF_TYPE_SSL | CF_TYPE_MULTIPLEX | CF_TYPE_HTTP,
    .log_level = 2,
};

pub const Curl_cft_h3_proxy_desc = VquicCftypeDescriptor{
    .name = "H3-PROXY",
    .flags = CF_TYPE_IP_CONNECT | CF_TYPE_PROXY | CF_TYPE_SSL,
    .log_level = 1,
};

/// Convert an HTTP/3 error code (RFC 9114) into a human-readable string.
/// Matches `Curl_vquic_h3_err_str()` in `lib/vquic/vquic.c`.
pub fn Curl_vquic_h3_err_str(error_code: u64) callconv(.c) [*:0]const u8 {
    return vquic_core.Curl_vquic_h3_err_str(error_code);
}

pub const Curl_conn_may_http3 = vquic_core.Curl_conn_may_http3;
pub const Curl_vquic_init = vquic_core.Curl_vquic_init;
pub const Curl_vquic_cleanup = vquic_core.Curl_vquic_cleanup;
pub const Curl_quic_ver = vquic_core.Curl_quic_ver;

// ============================================================================
// 3. VSSH / libssh / libssh2 (lib/vssh/vssh.c, libssh.c, libssh2.c, ssh.h)
// ============================================================================

pub const CURL_META_SSH_EASY = "meta:proto:ssh:easy";
pub const CURL_META_SSH_CONN = "meta:proto:ssh:conn";

pub const CURLE_QUOTE_ERROR: CURLcode = 21;

pub const sshstate = vssh.sshstate;
pub const Curl_ssh_statename = vssh.Curl_ssh_statename;
pub const LIBSSH2_FX_OK = vssh.LIBSSH2_FX_OK;
pub const LIBSSH2_FX_EOF = vssh.LIBSSH2_FX_EOF;
pub const LIBSSH2_FX_NO_SUCH_FILE = vssh.LIBSSH2_FX_NO_SUCH_FILE;
pub const LIBSSH2_FX_PERMISSION_DENIED = vssh.LIBSSH2_FX_PERMISSION_DENIED;
pub const LIBSSH2_FX_FAILURE = vssh.LIBSSH2_FX_FAILURE;
pub const LIBSSH2_FX_BAD_MESSAGE = vssh.LIBSSH2_FX_BAD_MESSAGE;
pub const LIBSSH2_FX_NO_CONNECTION = vssh.LIBSSH2_FX_NO_CONNECTION;
pub const LIBSSH2_FX_CONNECTION_LOST = vssh.LIBSSH2_FX_CONNECTION_LOST;
pub const LIBSSH2_FX_OP_UNSUPPORTED = vssh.LIBSSH2_FX_OP_UNSUPPORTED;
pub const LIBSSH2_FX_INVALID_HANDLE = vssh.LIBSSH2_FX_INVALID_HANDLE;
pub const LIBSSH2_FX_NO_SUCH_PATH = vssh.LIBSSH2_FX_NO_SUCH_PATH;
pub const LIBSSH2_FX_FILE_ALREADY_EXISTS = vssh.LIBSSH2_FX_FILE_ALREADY_EXISTS;
pub const LIBSSH2_FX_WRITE_PROTECT = vssh.LIBSSH2_FX_WRITE_PROTECT;
pub const LIBSSH2_FX_NO_MEDIA = vssh.LIBSSH2_FX_NO_MEDIA;
pub const LIBSSH2_FX_NO_SPACE_ON_FILESYSTEM = vssh.LIBSSH2_FX_NO_SPACE_ON_FILESYSTEM;
pub const LIBSSH2_FX_QUOTA_EXCEEDED = vssh.LIBSSH2_FX_QUOTA_EXCEEDED;
pub const LIBSSH2_FX_UNKNOWN_PRINCIPLE = vssh.LIBSSH2_FX_UNKNOWN_PRINCIPLE;
pub const LIBSSH2_FX_LOCK_CONFlICT = vssh.LIBSSH2_FX_LOCK_CONFlICT;
pub const LIBSSH2_FX_DIR_NOT_EMPTY = vssh.LIBSSH2_FX_DIR_NOT_EMPTY;
pub const LIBSSH2_FX_NOT_A_DIRECTORY = vssh.LIBSSH2_FX_NOT_A_DIRECTORY;
pub const LIBSSH2_FX_INVALID_FILENAME = vssh.LIBSSH2_FX_INVALID_FILENAME;
pub const LIBSSH2_FX_LINK_LOOP = vssh.LIBSSH2_FX_LINK_LOOP;
pub const sftpLibssh2Strerror = vssh.sftpLibssh2Strerror;
pub const sftpErrorToCurle = vssh.sftpErrorToCurle;
pub const Curl_ssh_init = vssh.Curl_ssh_init;
pub const Curl_ssh_cleanup = vssh.Curl_ssh_cleanup;
pub const Curl_ssh_version = vssh.Curl_ssh_version;
pub const Curl_protocol_scp = vssh.Curl_protocol_scp;
pub const Curl_protocol_sftp = vssh.Curl_protocol_sftp;

// ============================================================================
// 4. Optional VTLS Backends: GnuTLS, Rustls, wolfSSL
//    (lib/vtls/gtls.c, lib/vtls/rustls.c, lib/vtls/wolfssl.c)
// ============================================================================

pub const curl_sslbackend = enum(c_uint) {
    CURLSSLBACKEND_NONE = 0,
    CURLSSLBACKEND_OPENSSL = 1,
    CURLSSLBACKEND_GNUTLS = 2,
    CURLSSLBACKEND_NSS = 3,
    CURLSSLBACKEND_OBSOLETE4 = 4,
    CURLSSLBACKEND_GSKIT = 5,
    CURLSSLBACKEND_POLARSSL = 6,
    CURLSSLBACKEND_WOLFSSL = 7,
    CURLSSLBACKEND_SCHANNEL = 8,
    CURLSSLBACKEND_SECURETRANSPORT = 9,
    CURLSSLBACKEND_AXTLS = 10,
    CURLSSLBACKEND_MBEDTLS = 11,
    CURLSSLBACKEND_MESALINK = 12,
    CURLSSLBACKEND_BEARSSL = 13,
    CURLSSLBACKEND_RUSTLS = 14,
};

pub const curl_ssl_backend = extern struct {
    id: curl_sslbackend,
    name: [*:0]const u8,
};

pub const SSLSUPP_CA_PATH: c_uint = 1 << 0;
pub const SSLSUPP_CERTINFO: c_uint = 1 << 1;
pub const SSLSUPP_PINNEDPUBKEY: c_uint = 1 << 2;
pub const SSLSUPP_SSL_CTX: c_uint = 1 << 3;
pub const SSLSUPP_HTTPS_PROXY: c_uint = 1 << 4;
pub const SSLSUPP_TLS13_CIPHERSUITES: c_uint = 1 << 5;
pub const SSLSUPP_CAINFO_BLOB: c_uint = 1 << 6;
pub const SSLSUPP_ECH: c_uint = 1 << 7;
pub const SSLSUPP_CA_CACHE: c_uint = 1 << 8;
pub const SSLSUPP_CIPHER_LIST: c_uint = 1 << 9;
pub const SSLSUPP_SIGNATURE_ALGORITHMS: c_uint = 1 << 10;
pub const SSLSUPP_ISSUERCERT: c_uint = 1 << 11;
pub const SSLSUPP_SSL_EC_CURVES: c_uint = 1 << 12;
pub const SSLSUPP_CRLFILE: c_uint = 1 << 13;
pub const SSLSUPP_ISSUERCERT_BLOB: c_uint = 1 << 14;

pub const OptionalSslBackendDescriptor = struct {
    info: curl_ssl_backend,
    supports: c_uint,
};

/// GnuTLS backend descriptor (`Curl_ssl_gnutls` in `lib/vtls/gtls.c`).
pub const Curl_ssl_gnutls_desc = OptionalSslBackendDescriptor{
    .info = .{
        .id = .CURLSSLBACKEND_GNUTLS,
        .name = "gnutls",
    },
    .supports = SSLSUPP_CA_PATH |
        SSLSUPP_CERTINFO |
        SSLSUPP_PINNEDPUBKEY |
        SSLSUPP_HTTPS_PROXY |
        SSLSUPP_CAINFO_BLOB |
        SSLSUPP_CIPHER_LIST |
        SSLSUPP_CA_CACHE |
        SSLSUPP_ISSUERCERT |
        SSLSUPP_CRLFILE,
};

/// Rustls backend descriptor (`Curl_ssl_rustls` in `lib/vtls/rustls.c`).
pub const Curl_ssl_rustls_desc = OptionalSslBackendDescriptor{
    .info = .{
        .id = .CURLSSLBACKEND_RUSTLS,
        .name = "rustls",
    },
    .supports = SSLSUPP_CAINFO_BLOB |
        SSLSUPP_HTTPS_PROXY |
        SSLSUPP_CIPHER_LIST |
        SSLSUPP_TLS13_CIPHERSUITES |
        SSLSUPP_CERTINFO |
        SSLSUPP_CRLFILE,
};

/// wolfSSL backend descriptor (`Curl_ssl_wolfssl` in `lib/vtls/wolfssl.c`).
pub const Curl_ssl_wolfssl_desc = OptionalSslBackendDescriptor{
    .info = .{
        .id = .CURLSSLBACKEND_WOLFSSL,
        .name = "wolfssl",
    },
    .supports = SSLSUPP_PINNEDPUBKEY |
        SSLSUPP_HTTPS_PROXY |
        SSLSUPP_CA_PATH |
        SSLSUPP_CAINFO_BLOB |
        SSLSUPP_SSL_CTX |
        SSLSUPP_TLS13_CIPHERSUITES |
        SSLSUPP_CA_CACHE |
        SSLSUPP_CIPHER_LIST |
        SSLSUPP_SSL_EC_CURVES,
};

// ============================================================================
// Unit Tests
// ============================================================================

test "Curl_conn_may_http3 returns CURLE_NOT_BUILT_IN when HTTP/3 disabled" {
    if (!vquic_core.use_http3) {
        try std.testing.expectEqual(CURLE_NOT_BUILT_IN, Curl_conn_may_http3(null, null));
        try std.testing.expectEqual(@as(CURLcode, 4), Curl_conn_may_http3(null, null));
    } else {
        try std.testing.expectEqual(CURLE_QUIC_CONNECT_ERROR, Curl_conn_may_http3(null, null));
    }
}

test "Curl_vquic_h3_err_str maps standard and RFC 9114 reserved HTTP/3 error codes" {
    try std.testing.expectEqualStrings("NO_ERROR", std.mem.span(Curl_vquic_h3_err_str(0x0100)));
    try std.testing.expectEqualStrings("GENERAL_PROTOCOL_ERROR", std.mem.span(Curl_vquic_h3_err_str(0x0101)));
    try std.testing.expectEqualStrings("INTERNAL_ERROR", std.mem.span(Curl_vquic_h3_err_str(0x0102)));
    try std.testing.expectEqualStrings("REQUEST_CANCELLED", std.mem.span(Curl_vquic_h3_err_str(0x010c)));
    try std.testing.expectEqualStrings("VERSION_FALLBACK", std.mem.span(Curl_vquic_h3_err_str(0x0110)));

    // RFC 9114 reserved error codes: 0x1f * N + 0x21 -> "NO_ERROR"
    try std.testing.expectEqualStrings("NO_ERROR", std.mem.span(Curl_vquic_h3_err_str(0x21)));
    try std.testing.expectEqualStrings("NO_ERROR", std.mem.span(Curl_vquic_h3_err_str(0x40)));
    try std.testing.expectEqualStrings("NO_ERROR", std.mem.span(Curl_vquic_h3_err_str(0x5f)));

    // Non-matching codes -> "unknown"
    try std.testing.expectEqualStrings("unknown", std.mem.span(Curl_vquic_h3_err_str(0x0)));
    try std.testing.expectEqualStrings("unknown", std.mem.span(Curl_vquic_h3_err_str(0x20)));
    try std.testing.expectEqualStrings("unknown", std.mem.span(Curl_vquic_h3_err_str(0x22)));
    try std.testing.expectEqualStrings("unknown", std.mem.span(Curl_vquic_h3_err_str(0x0111)));
}

test "Curl_ssh_statename maps all SSH states and bounds" {
    try std.testing.expectEqualStrings("", std.mem.span(Curl_ssh_statename(.SSH_NO_STATE)));
    try std.testing.expectEqualStrings("SSH_STOP", std.mem.span(Curl_ssh_statename(.SSH_STOP)));
    try std.testing.expectEqualStrings("SSH_INIT", std.mem.span(Curl_ssh_statename(.SSH_INIT)));
    try std.testing.expectEqualStrings("SSH_SFTP_INIT", std.mem.span(Curl_ssh_statename(.SSH_SFTP_INIT)));
    try std.testing.expectEqualStrings("SSH_SCP_TRANS_INIT", std.mem.span(Curl_ssh_statename(.SSH_SCP_TRANS_INIT)));
    try std.testing.expectEqualStrings("SSH_SESSION_FREE", std.mem.span(Curl_ssh_statename(.SSH_SESSION_FREE)));
    try std.testing.expectEqualStrings("QUIT", std.mem.span(Curl_ssh_statename(.SSH_QUIT)));
    try std.testing.expectEqualStrings("", std.mem.span(Curl_ssh_statename(.SSH_LAST)));
}

test "OpenLDAP state names and LDIF base64 check" {
    try std.testing.expectEqualStrings("STOP", std.mem.span(oldapStateName(.OLDAP_STOP)));
    try std.testing.expectEqualStrings("STARTTLS", std.mem.span(oldapStateName(.OLDAP_STARTTLS)));
    try std.testing.expectEqualStrings("BINDV2", std.mem.span(oldapStateName(.OLDAP_BINDV2)));
    try std.testing.expectEqualStrings("", std.mem.span(oldapStateName(.OLDAP_LAST)));

    try std.testing.expect(!oldapStrNeedsBase64(""));
    try std.testing.expect(!oldapStrNeedsBase64("cn=admin,dc=example,dc=com"));
    try std.testing.expect(oldapStrNeedsBase64(":leading-colon"));
    try std.testing.expect(oldapStrNeedsBase64("<leading-lt"));
    try std.testing.expect(oldapStrNeedsBase64(" leading-space"));
    try std.testing.expect(oldapStrNeedsBase64("trailing-space "));
    try std.testing.expect(oldapStrNeedsBase64("\tleading-tab"));
    try std.testing.expect(oldapStrNeedsBase64("non-printable\nline"));
    try std.testing.expect(oldapStrNeedsBase64("utf8-\xc3\xa9"));
}

test "SFTP error string and CURLcode mapping" {
    try std.testing.expectEqualStrings("No such file or directory", std.mem.span(sftpLibssh2Strerror(LIBSSH2_FX_NO_SUCH_FILE)));
    try std.testing.expectEqualStrings("Permission denied", std.mem.span(sftpLibssh2Strerror(LIBSSH2_FX_PERMISSION_DENIED)));
    try std.testing.expectEqualStrings("Disk full", std.mem.span(sftpLibssh2Strerror(LIBSSH2_FX_NO_SPACE_ON_FILESYSTEM)));
    try std.testing.expectEqualStrings("Unknown error in libssh2", std.mem.span(sftpLibssh2Strerror(999)));

    try std.testing.expectEqual(CURLE_OK, sftpErrorToCurle(LIBSSH2_FX_OK));
    try std.testing.expectEqual(CURLE_REMOTE_FILE_NOT_FOUND, sftpErrorToCurle(LIBSSH2_FX_NO_SUCH_FILE));
    try std.testing.expectEqual(CURLE_REMOTE_ACCESS_DENIED, sftpErrorToCurle(LIBSSH2_FX_PERMISSION_DENIED));
    try std.testing.expectEqual(CURLE_REMOTE_DISK_FULL, sftpErrorToCurle(LIBSSH2_FX_QUOTA_EXCEEDED));
    try std.testing.expectEqual(CURLE_REMOTE_FILE_EXISTS, sftpErrorToCurle(LIBSSH2_FX_FILE_ALREADY_EXISTS));
    try std.testing.expectEqual(CURLE_SSH, sftpErrorToCurle(999));
}

test "Optional VTLS and VQUIC backend descriptors" {
    try std.testing.expectEqual(curl_sslbackend.CURLSSLBACKEND_GNUTLS, Curl_ssl_gnutls_desc.info.id);
    try std.testing.expectEqualStrings("gnutls", std.mem.span(Curl_ssl_gnutls_desc.info.name));
    try std.testing.expectEqual(
        SSLSUPP_CA_PATH | SSLSUPP_CERTINFO | SSLSUPP_PINNEDPUBKEY | SSLSUPP_HTTPS_PROXY |
            SSLSUPP_CAINFO_BLOB | SSLSUPP_CIPHER_LIST | SSLSUPP_CA_CACHE | SSLSUPP_ISSUERCERT | SSLSUPP_CRLFILE,
        Curl_ssl_gnutls_desc.supports,
    );

    try std.testing.expectEqual(curl_sslbackend.CURLSSLBACKEND_RUSTLS, Curl_ssl_rustls_desc.info.id);
    try std.testing.expectEqualStrings("rustls", std.mem.span(Curl_ssl_rustls_desc.info.name));
    try std.testing.expectEqual(
        SSLSUPP_CAINFO_BLOB | SSLSUPP_HTTPS_PROXY | SSLSUPP_CIPHER_LIST |
            SSLSUPP_TLS13_CIPHERSUITES | SSLSUPP_CERTINFO | SSLSUPP_CRLFILE,
        Curl_ssl_rustls_desc.supports,
    );

    try std.testing.expectEqual(curl_sslbackend.CURLSSLBACKEND_WOLFSSL, Curl_ssl_wolfssl_desc.info.id);
    try std.testing.expectEqualStrings("wolfssl", std.mem.span(Curl_ssl_wolfssl_desc.info.name));
    try std.testing.expectEqual(
        SSLSUPP_PINNEDPUBKEY | SSLSUPP_HTTPS_PROXY | SSLSUPP_CA_PATH | SSLSUPP_CAINFO_BLOB |
            SSLSUPP_SSL_CTX | SSLSUPP_TLS13_CIPHERSUITES | SSLSUPP_CA_CACHE | SSLSUPP_CIPHER_LIST | SSLSUPP_SSL_EC_CURVES,
        Curl_ssl_wolfssl_desc.supports,
    );

    try std.testing.expectEqualStrings("HTTP/3", std.mem.span(Curl_cft_http3_desc.name));
    try std.testing.expectEqualStrings("H3-PROXY", std.mem.span(Curl_cft_h3_proxy_desc.name));
}
