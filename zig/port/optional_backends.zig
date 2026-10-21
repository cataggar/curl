const std = @import("std");
const vquic_core = @import("vquic_core.zig");

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

/// All possible states in the SSH/SFTP/SCP state machine (`lib/vssh/ssh.h`).
pub const sshstate = enum(c_int) {
    SSH_NO_STATE = -1,
    SSH_STOP = 0,
    SSH_INIT,
    SSH_S_STARTUP,
    SSH_HOSTKEY,
    SSH_AUTHLIST,
    SSH_AUTH_PKEY_INIT,
    SSH_AUTH_PKEY,
    SSH_AUTH_PASS_INIT,
    SSH_AUTH_PASS,
    SSH_AUTH_AGENT_INIT,
    SSH_AUTH_AGENT_LIST,
    SSH_AUTH_AGENT,
    SSH_AUTH_HOST_INIT,
    SSH_AUTH_HOST,
    SSH_AUTH_KEY_INIT,
    SSH_AUTH_KEY,
    SSH_AUTH_GSSAPI,
    SSH_AUTH_DONE,
    SSH_SFTP_INIT,
    SSH_SFTP_REALPATH,
    SSH_SFTP_QUOTE_INIT,
    SSH_SFTP_POSTQUOTE_INIT,
    SSH_SFTP_QUOTE,
    SSH_SFTP_NEXT_QUOTE,
    SSH_SFTP_QUOTE_STAT,
    SSH_SFTP_QUOTE_SETSTAT,
    SSH_SFTP_QUOTE_SYMLINK,
    SSH_SFTP_QUOTE_MKDIR,
    SSH_SFTP_QUOTE_RMDIR,
    SSH_SFTP_QUOTE_RENAME,
    SSH_SFTP_QUOTE_UNLINK,
    SSH_SFTP_QUOTE_STATVFS,
    SSH_SFTP_GETINFO,
    SSH_SFTP_FILETIME,
    SSH_SFTP_TRANS_INIT,
    SSH_SFTP_UPLOAD_INIT,
    SSH_SFTP_CREATE_DIRS_INIT,
    SSH_SFTP_CREATE_DIRS,
    SSH_SFTP_CREATE_DIRS_MKDIR,
    SSH_SFTP_READDIR_INIT,
    SSH_SFTP_READDIR,
    SSH_SFTP_READDIR_LINK,
    SSH_SFTP_READDIR_BOTTOM,
    SSH_SFTP_READDIR_DONE,
    SSH_SFTP_DOWNLOAD_INIT,
    SSH_SFTP_DOWNLOAD_STAT,
    SSH_SFTP_CLOSE,
    SSH_SFTP_SHUTDOWN,
    SSH_SCP_TRANS_INIT,
    SSH_SCP_UPLOAD_INIT,
    SSH_SCP_DOWNLOAD_INIT,
    SSH_SCP_DOWNLOAD,
    SSH_SCP_DONE,
    SSH_SCP_SEND_EOF,
    SSH_SCP_WAIT_EOF,
    SSH_SCP_WAIT_CLOSE,
    SSH_SCP_CHANNEL_FREE,
    SSH_SESSION_DISCONNECT,
    SSH_SESSION_FREE,
    SSH_QUIT,
    SSH_LAST,
};

const ssh_statenames = [_][*:0]const u8{
    "SSH_STOP",
    "SSH_INIT",
    "SSH_S_STARTUP",
    "SSH_HOSTKEY",
    "SSH_AUTHLIST",
    "SSH_AUTH_PKEY_INIT",
    "SSH_AUTH_PKEY",
    "SSH_AUTH_PASS_INIT",
    "SSH_AUTH_PASS",
    "SSH_AUTH_AGENT_INIT",
    "SSH_AUTH_AGENT_LIST",
    "SSH_AUTH_AGENT",
    "SSH_AUTH_HOST_INIT",
    "SSH_AUTH_HOST",
    "SSH_AUTH_KEY_INIT",
    "SSH_AUTH_KEY",
    "SSH_AUTH_GSSAPI",
    "SSH_AUTH_DONE",
    "SSH_SFTP_INIT",
    "SSH_SFTP_REALPATH",
    "SSH_SFTP_QUOTE_INIT",
    "SSH_SFTP_POSTQUOTE_INIT",
    "SSH_SFTP_QUOTE",
    "SSH_SFTP_NEXT_QUOTE",
    "SSH_SFTP_QUOTE_STAT",
    "SSH_SFTP_QUOTE_SETSTAT",
    "SSH_SFTP_QUOTE_SYMLINK",
    "SSH_SFTP_QUOTE_MKDIR",
    "SSH_SFTP_QUOTE_RMDIR",
    "SSH_SFTP_QUOTE_RENAME",
    "SSH_SFTP_QUOTE_UNLINK",
    "SSH_SFTP_QUOTE_STATVFS",
    "SSH_SFTP_GETINFO",
    "SSH_SFTP_FILETIME",
    "SSH_SFTP_TRANS_INIT",
    "SSH_SFTP_UPLOAD_INIT",
    "SSH_SFTP_CREATE_DIRS_INIT",
    "SSH_SFTP_CREATE_DIRS",
    "SSH_SFTP_CREATE_DIRS_MKDIR",
    "SSH_SFTP_READDIR_INIT",
    "SSH_SFTP_READDIR",
    "SSH_SFTP_READDIR_LINK",
    "SSH_SFTP_READDIR_BOTTOM",
    "SSH_SFTP_READDIR_DONE",
    "SSH_SFTP_DOWNLOAD_INIT",
    "SSH_SFTP_DOWNLOAD_STAT",
    "SSH_SFTP_CLOSE",
    "SSH_SFTP_SHUTDOWN",
    "SSH_SCP_TRANS_INIT",
    "SSH_SCP_UPLOAD_INIT",
    "SSH_SCP_DOWNLOAD_INIT",
    "SSH_SCP_DOWNLOAD",
    "SSH_SCP_DONE",
    "SSH_SCP_SEND_EOF",
    "SSH_SCP_WAIT_EOF",
    "SSH_SCP_WAIT_CLOSE",
    "SSH_SCP_CHANNEL_FREE",
    "SSH_SESSION_DISCONNECT",
    "SSH_SESSION_FREE",
    "QUIT",
};

comptime {
    std.debug.assert(ssh_statenames.len == @backingInt(sshstate.SSH_LAST));
}

/// Return the state name for an `sshstate` value (`lib/vssh/vssh.c`).
pub export fn Curl_ssh_statename(state: sshstate) callconv(.c) [*:0]const u8 {
    const raw: c_int = @backingInt(state);
    if (raw >= 0 and raw < @as(c_int, @intCast(ssh_statenames.len))) {
        return ssh_statenames[@intCast(raw)];
    }
    return "";
}

pub const LIBSSH2_FX_OK: c_ulong = 0;
pub const LIBSSH2_FX_EOF: c_ulong = 1;
pub const LIBSSH2_FX_NO_SUCH_FILE: c_ulong = 2;
pub const LIBSSH2_FX_PERMISSION_DENIED: c_ulong = 3;
pub const LIBSSH2_FX_FAILURE: c_ulong = 4;
pub const LIBSSH2_FX_BAD_MESSAGE: c_ulong = 5;
pub const LIBSSH2_FX_NO_CONNECTION: c_ulong = 6;
pub const LIBSSH2_FX_CONNECTION_LOST: c_ulong = 7;
pub const LIBSSH2_FX_OP_UNSUPPORTED: c_ulong = 8;
pub const LIBSSH2_FX_INVALID_HANDLE: c_ulong = 9;
pub const LIBSSH2_FX_NO_SUCH_PATH: c_ulong = 10;
pub const LIBSSH2_FX_FILE_ALREADY_EXISTS: c_ulong = 11;
pub const LIBSSH2_FX_WRITE_PROTECT: c_ulong = 12;
pub const LIBSSH2_FX_NO_MEDIA: c_ulong = 13;
pub const LIBSSH2_FX_NO_SPACE_ON_FILESYSTEM: c_ulong = 14;
pub const LIBSSH2_FX_QUOTA_EXCEEDED: c_ulong = 15;
pub const LIBSSH2_FX_UNKNOWN_PRINCIPLE: c_ulong = 16;
pub const LIBSSH2_FX_LOCK_CONFlICT: c_ulong = 17;
pub const LIBSSH2_FX_DIR_NOT_EMPTY: c_ulong = 18;
pub const LIBSSH2_FX_NOT_A_DIRECTORY: c_ulong = 19;
pub const LIBSSH2_FX_INVALID_FILENAME: c_ulong = 20;
pub const LIBSSH2_FX_LINK_LOOP: c_ulong = 21;

/// Map a libssh2 SFTP status code to its descriptive message (`lib/vssh/libssh2.c`).
pub fn sftpLibssh2Strerror(err: c_ulong) [*:0]const u8 {
    return switch (err) {
        LIBSSH2_FX_NO_SUCH_FILE => "No such file or directory",
        LIBSSH2_FX_PERMISSION_DENIED => "Permission denied",
        LIBSSH2_FX_FAILURE => "Operation failed",
        LIBSSH2_FX_BAD_MESSAGE => "Bad message from SFTP server",
        LIBSSH2_FX_NO_CONNECTION => "Not connected to SFTP server",
        LIBSSH2_FX_CONNECTION_LOST => "Connection to SFTP server lost",
        LIBSSH2_FX_OP_UNSUPPORTED => "Operation not supported by SFTP server",
        LIBSSH2_FX_INVALID_HANDLE => "Invalid handle",
        LIBSSH2_FX_NO_SUCH_PATH => "No such file or directory",
        LIBSSH2_FX_FILE_ALREADY_EXISTS => "File already exists",
        LIBSSH2_FX_WRITE_PROTECT => "File is write protected",
        LIBSSH2_FX_NO_MEDIA => "No media",
        LIBSSH2_FX_NO_SPACE_ON_FILESYSTEM => "Disk full",
        LIBSSH2_FX_QUOTA_EXCEEDED => "User quota exceeded",
        LIBSSH2_FX_UNKNOWN_PRINCIPLE => "Unknown principle",
        LIBSSH2_FX_LOCK_CONFlICT => "File lock conflict",
        LIBSSH2_FX_DIR_NOT_EMPTY => "Directory not empty",
        LIBSSH2_FX_NOT_A_DIRECTORY => "Not a directory",
        LIBSSH2_FX_INVALID_FILENAME => "Invalid filename",
        LIBSSH2_FX_LINK_LOOP => "Link points to itself",
        else => "Unknown error in libssh2",
    };
}

/// Map an SFTP `SSH_FX_*` / `LIBSSH2_FX_*` error code to `CURLcode`
/// (`sftp_error_to_CURLE` in `lib/vssh/libssh.c` and `sftp_libssh2_error_to_CURLE` in `lib/vssh/libssh2.c`).
pub fn sftpErrorToCurle(err: c_ulong) CURLcode {
    return switch (err) {
        LIBSSH2_FX_OK => CURLE_OK,
        LIBSSH2_FX_NO_SUCH_FILE, LIBSSH2_FX_NO_SUCH_PATH => CURLE_REMOTE_FILE_NOT_FOUND,
        LIBSSH2_FX_PERMISSION_DENIED, LIBSSH2_FX_WRITE_PROTECT, LIBSSH2_FX_LOCK_CONFlICT => CURLE_REMOTE_ACCESS_DENIED,
        LIBSSH2_FX_NO_SPACE_ON_FILESYSTEM, LIBSSH2_FX_QUOTA_EXCEEDED => CURLE_REMOTE_DISK_FULL,
        LIBSSH2_FX_CONNECTION_LOST => CURLE_SEND_ERROR,
        LIBSSH2_FX_FILE_ALREADY_EXISTS => CURLE_REMOTE_FILE_EXISTS,
        LIBSSH2_FX_DIR_NOT_EMPTY => CURLE_QUOTE_ERROR,
        else => CURLE_SSH,
    };
}

pub const CURLE_QUOTE_ERROR: CURLcode = 21;

pub fn Curl_ssh_init() callconv(.c) CURLcode {
    return CURLE_OK;
}

pub fn Curl_ssh_cleanup() callconv(.c) void {}

pub fn Curl_ssh_version(buffer: [*]u8, buflen: usize) callconv(.c) void {
    if (buflen > 0) {
        buffer[0] = 0;
    }
}

fn sshDisabledDo(data: ?*anyopaque, done: *bool) callconv(.c) CURLcode {
    _ = data;
    done.* = false;
    return CURLE_NOT_BUILT_IN;
}

pub const Curl_protocol_scp = Curl_protocol{
    .do_it = sshDisabledDo,
};

pub const Curl_protocol_sftp = Curl_protocol{
    .do_it = sshDisabledDo,
};

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
