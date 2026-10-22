const std = @import("std");
const builtin = @import("builtin");
const backend_options = @import("backend_options");
const mem = @import("mem.zig");
const primitives = @import("primitives.zig");
const curlx_parse = @import("curlx_parse.zig");
const curlx_time_net = @import("curlx_time_net.zig");
const os_leaf = @import("os_leaf.zig");
const crypto = @import("crypto.zig");
const containers = @import("containers.zig");
const collections = @import("collections.zig");
const cookie_getinfo_trc = @import("cookie_getinfo_trc.zig");
const sendf = @import("sendf.zig");
const cfsocket_transfer = @import("cfsocket_transfer.zig");
const setopt = @import("setopt.zig");
const protocol_version_mime = @import("protocol_version_mime.zig");
const vssh_libssh = @import("vssh_libssh.zig");

pub const ssh_backend = if (@hasDecl(backend_options, "ssh")) backend_options.ssh else .none;
pub const use_ssh = ssh_backend != .none;
pub const use_libssh2 = ssh_backend == .libssh2;
pub const use_libssh = ssh_backend == .libssh;

pub const CURLcode = c_uint;
pub const curl_off_t = i64;
pub const curl_prot_t = i64;
pub const timediff_t = i64;
pub const curl_socket_t = if (builtin.os.tag == .windows) usize else c_int;
pub const CURL_SOCKET_BAD: curl_socket_t = if (builtin.os.tag == .windows) ~@as(usize, 0) else -1;

pub const Curl_easy = setopt.Curl_easy;
pub const connectdata = opaque {};
pub const easy_pollset = opaque {};
pub const curl_slist = protocol_version_mime.curl_slist;

pub const CURLE_OK: CURLcode = 0;
pub const CURLE_UNSUPPORTED_PROTOCOL: CURLcode = 1;
pub const CURLE_FAILED_INIT: CURLcode = 2;
pub const CURLE_URL_MALFORMAT: CURLcode = 3;
pub const CURLE_NOT_BUILT_IN: CURLcode = 4;
pub const CURLE_COULDNT_CONNECT: CURLcode = 7;
pub const CURLE_REMOTE_ACCESS_DENIED: CURLcode = 9;
pub const CURLE_QUOTE_ERROR: CURLcode = 21;
pub const CURLE_WRITE_ERROR: CURLcode = 23;
pub const CURLE_UPLOAD_FAILED: CURLcode = 25;
pub const CURLE_READ_ERROR: CURLcode = 26;
pub const CURLE_OUT_OF_MEMORY: CURLcode = 27;
pub const CURLE_OPERATION_TIMEDOUT: CURLcode = 28;
pub const CURLE_RANGE_ERROR: CURLcode = 33;
pub const CURLE_ABORTED_BY_CALLBACK: CURLcode = 42;
pub const CURLE_BAD_FUNCTION_ARGUMENT: CURLcode = 43;
pub const CURLE_SEND_ERROR: CURLcode = 55;
pub const CURLE_RECV_ERROR: CURLcode = 56;
pub const CURLE_PEER_FAILED_VERIFICATION: CURLcode = 60;
pub const CURLE_FILESIZE_EXCEEDED: CURLcode = 63;
pub const CURLE_USE_SSL_FAILED: CURLcode = 64;
pub const CURLE_SEND_FAIL_REWIND: CURLcode = 65;
pub const CURLE_LOGIN_DENIED: CURLcode = 67;
pub const CURLE_REMOTE_DISK_FULL: CURLcode = 70;
pub const CURLE_REMOTE_FILE_EXISTS: CURLcode = 73;
pub const CURLE_TOO_LARGE: CURLcode = 100;
pub const CURLE_REMOTE_FILE_NOT_FOUND: CURLcode = 78;
pub const CURLE_SSH: CURLcode = 79;
pub const CURLE_AGAIN: CURLcode = 81;

pub const CURLPROTO_SCP: curl_prot_t = 1 << 4;
pub const CURLPROTO_SFTP: curl_prot_t = 1 << 5;
pub const PROTO_FAMILY_SSH: curl_prot_t = CURLPROTO_SCP | CURLPROTO_SFTP;

pub const FIRSTSOCKET: c_int = 0;
pub const CLIENTWRITE_BODY: c_int = 1 << 0;
pub const CLIENTWRITE_HEADER: c_int = 1 << 2;

pub const CURL_POLL_IN: c_int = 1;
pub const CURL_POLL_OUT: c_int = 2;

pub const CURLSSH_AUTH_PUBLICKEY: u32 = 1 << 0;
pub const CURLSSH_AUTH_PASSWORD: u32 = 1 << 1;
pub const CURLSSH_AUTH_HOST: u32 = 1 << 2;
pub const CURLSSH_AUTH_KEYBOARD: u32 = 1 << 3;
pub const CURLSSH_AUTH_AGENT: u32 = 1 << 4;
pub const CURLSSH_AUTH_GSSAPI: u32 = 1 << 5;

pub const CURLKHTYPE_UNKNOWN: c_uint = 0;
pub const CURLKHTYPE_RSA1: c_uint = 1;
pub const CURLKHTYPE_RSA: c_uint = 2;
pub const CURLKHTYPE_DSS: c_uint = 3;
pub const CURLKHTYPE_ECDSA: c_uint = 4;
pub const CURLKHTYPE_ED25519: c_uint = 5;

pub const CURLKHMATCH_OK: c_uint = 0;
pub const CURLKHMATCH_MISMATCH: c_uint = 1;
pub const CURLKHMATCH_MISSING: c_uint = 2;
pub const CURLKHMATCH_LAST: c_uint = 3;

pub const CURLKHSTAT_FINE_ADD_TO_FILE: c_int = 0;
pub const CURLKHSTAT_FINE: c_int = 1;
pub const CURLKHSTAT_REJECT: c_int = 2;
pub const CURLKHSTAT_DEFER: c_int = 3;
pub const CURLKHSTAT_FINE_REPLACE: c_int = 4;

pub const curl_khkey = extern struct {
    key: ?[*]const u8,
    len: usize,
    keytype: c_uint,
};

pub const CURLFTP_CREATE_DIR_NONE: i64 = 0;
pub const CURLFTP_CREATE_DIR: i64 = 1;
pub const CURLFTP_CREATE_DIR_RETRY: i64 = 2;

pub const TIMER_STARTACCEPT: c_uint = 9;
pub const SEEK_SET: c_int = 0;
pub const CURL_SEEKFUNC_OK: c_int = 0;
pub const CURL_SEEKFUNC_CANTSEEK: c_int = 2;
pub const CURL_READFUNC_ABORT: usize = 0x10000000;
pub const CURL_READFUNC_PAUSE: usize = 0x10000001;
pub const REJECT_CTRL: c_uint = 3;
pub const DYN_PATH_MAX: usize = 4096;

pub const CURL_META_SSH_EASY = "meta:proto:ssh:easy";
pub const CURL_META_SSH_CONN = "meta:proto:ssh:conn";

pub const Curl_send_fn = *const fn (
    data: *Curl_easy,
    sockindex: c_int,
    buf: *const anyopaque,
    len: usize,
    eos: bool,
    uppercase_pnwritten: *usize,
) callconv(.c) CURLcode;

pub const Curl_recv_fn = *const fn (
    data: *Curl_easy,
    sockindex: c_int,
    buf: [*]u8,
    len: usize,
    pnread: *usize,
) callconv(.c) CURLcode;

pub const Curl_protocol = extern struct {
    setup_connection: ?*const fn (?*Curl_easy, ?*connectdata) callconv(.c) CURLcode = null,
    do_it: ?*const fn (?*Curl_easy, *bool) callconv(.c) CURLcode = null,
    done: ?*const fn (?*Curl_easy, CURLcode, bool) callconv(.c) CURLcode = null,
    do_more: ?*const fn (?*Curl_easy, *c_int) callconv(.c) CURLcode = null,
    connect_it: ?*const fn (?*Curl_easy, *bool) callconv(.c) CURLcode = null,
    connecting: ?*const fn (?*Curl_easy, *bool) callconv(.c) CURLcode = null,
    doing: ?*const fn (?*Curl_easy, *bool) callconv(.c) CURLcode = null,
    proto_pollset: ?*const fn (?*Curl_easy, ?*easy_pollset) callconv(.c) CURLcode = null,
    doing_pollset: ?*const fn (?*Curl_easy, ?*easy_pollset) callconv(.c) CURLcode = null,
    domore_pollset: ?*const fn (?*Curl_easy, ?*easy_pollset) callconv(.c) CURLcode = null,
    perform_pollset: ?*const fn (?*Curl_easy, ?*easy_pollset) callconv(.c) CURLcode = null,
    disconnect: ?*const fn (?*Curl_easy, ?*connectdata, bool) callconv(.c) CURLcode = null,
    write_resp: ?*const fn (?*Curl_easy, [*]const u8, usize, bool) callconv(.c) CURLcode = null,
    write_resp_hd: ?*const fn (?*Curl_easy, [*]const u8, usize, bool) callconv(.c) CURLcode = null,
    connection_is_dead: ?*const fn (?*Curl_easy, ?*connectdata) callconv(.c) bool = null,
    attach: ?*const fn (?*Curl_easy, ?*connectdata) callconv(.c) void = null,
    follow: ?*const fn (?*Curl_easy, [*:0]const u8, c_uint) callconv(.c) CURLcode = null,
};

// ============================================================================
// External C / Zig port helpers
// ============================================================================

extern fn Curl_infof(data: ?*Curl_easy, fmt: [*:0]const u8, ...) callconv(.c) void;
extern fn Curl_failf(data: ?*Curl_easy, fmt: [*:0]const u8, ...) callconv(.c) void;
extern fn Curl_trc_feat_infof(
    data: ?*Curl_easy,
    feat: *cookie_getinfo_trc.curl_trc_feat,
    fmt: [*:0]const u8,
    ...,
) callconv(.c) void;
extern fn Curl_socket_check(
    readfd0: curl_socket_t,
    readfd1: curl_socket_t,
    writefd: curl_socket_t,
    timeout_ms: timediff_t,
) callconv(.c) c_int;
extern fn curl_maprintf(fmt: [*:0]const u8, ...) callconv(.c) ?[*:0]u8;
extern fn curl_getdate(p: ?[*:0]const u8, unused: ?*const isize) callconv(.c) isize;
extern fn curlx_str_number(linep: *[*:0]const u8, nump: *i64, max: i64) callconv(.c) c_int;
extern fn curlx_str_numblanks(str: *[*:0]const u8, num: *i64) callconv(.c) c_int;
extern fn curlx_str_octal(linep: *[*:0]const u8, nump: *i64, max: i64) callconv(.c) c_int;
extern fn curlx_str_single(linep: *[*:0]const u8, byte: u8) callconv(.c) c_int;
extern fn curlx_str_passblanks(linep: *[*:0]const u8) callconv(.c) void;
extern fn curlx_str_word(linep: *[*:0]const u8, out: *curlx_parse.Curl_str, max: usize) callconv(.c) c_int;
extern fn curlx_str_cspn(linep: *[*:0]const u8, out: *curlx_parse.Curl_str, reject: [*:0]const u8) callconv(.c) c_int;
extern fn Curl_easy_strset_ptr(data: *Curl_easy) callconv(.c) *collections.u8_strset;
extern fn Curl_setopt_get_bit(data: *Curl_easy, bit_id: c_int) callconv(.c) bool;
extern fn Curl_setopt_get_i64(data: *Curl_easy, field_id: c_int) callconv(.c) i64;
extern fn Curl_setopt_trc_bind_is_verbose(data: *Curl_easy) callconv(.c) bool;

extern fn Curl_meta_set(
    data: *Curl_easy,
    key: [*:0]const u8,
    meta_data: ?*anyopaque,
    meta_dtor: *const fn ([*:0]const u8, usize, ?*anyopaque) callconv(.c) void,
) callconv(.c) CURLcode;
extern fn Curl_meta_get(data: *Curl_easy, key: [*:0]const u8) callconv(.c) ?*anyopaque;
extern fn Curl_conn_meta_set(
    conn: *connectdata,
    key: [*:0]const u8,
    meta_data: ?*anyopaque,
    meta_dtor: *const fn ([*:0]const u8, usize, ?*anyopaque) callconv(.c) void,
) callconv(.c) CURLcode;
extern fn Curl_conn_meta_get(conn: *connectdata, key: [*:0]const u8) callconv(.c) ?*anyopaque;

extern fn Curl_pollset_change(
    data: *Curl_easy,
    ps: *easy_pollset,
    sock: curl_socket_t,
    add_flags: c_int,
    remove_flags: c_int,
) callconv(.c) CURLcode;
extern fn Curl_multi_mark_dirty(data: *Curl_easy) callconv(.c) void;
extern fn Curl_timeleft_ms(data: *Curl_easy, duringconnect: bool) callconv(.c) timediff_t;
extern fn Curl_pgrsSetDownloadSize(data: *Curl_easy, size: curl_off_t) callconv(.c) void;
extern fn Curl_pgrsSetUploadSize(data: *Curl_easy, size: curl_off_t) callconv(.c) void;
extern fn Curl_pgrsReset(data: *Curl_easy) callconv(.c) void;
extern fn Curl_pgrsTime(data: *Curl_easy, timer: c_uint) callconv(.c) void;
extern fn Curl_urldecode(
    string: [*:0]const u8,
    length: usize,
    ostring: *?[*:0]u8,
    olen: ?*usize,
    ctrl: c_uint,
) callconv(.c) CURLcode;
extern fn Curl_saferealloc(ptr: ?*anyopaque, size: usize) callconv(.c) ?*anyopaque;

extern fn Curl_ftp_acc_get_conn(data: *Curl_easy) callconv(.c) ?*connectdata;
extern fn Curl_ftp_acc_get_upload(data: *Curl_easy) callconv(.c) bool;
extern fn Curl_ftp_acc_get_list_only(data: *Curl_easy) callconv(.c) bool;
extern fn Curl_ftp_acc_get_no_body(data: *Curl_easy) callconv(.c) bool;
extern fn Curl_ftp_acc_get_infilesize(data: *Curl_easy) callconv(.c) curl_off_t;
extern fn Curl_ftp_acc_get_resume_from(data: *Curl_easy) callconv(.c) curl_off_t;
extern fn Curl_ftp_acc_set_resume_from(data: *Curl_easy, val: curl_off_t) callconv(.c) void;
extern fn Curl_ftp_acc_get_req_size(data: *Curl_easy) callconv(.c) curl_off_t;
extern fn Curl_ftp_acc_set_req_size(data: *Curl_easy, val: curl_off_t) callconv(.c) void;
extern fn Curl_ftp_acc_get_req_maxdownload(data: *Curl_easy) callconv(.c) curl_off_t;
extern fn Curl_http_acc_req_set_maxdownload(data: *Curl_easy, val: curl_off_t) callconv(.c) void;
extern fn Curl_ftp_acc_get_req_bytecount(data: *Curl_easy) callconv(.c) curl_off_t;
extern fn Curl_ftp_acc_get_max_filesize(data: *Curl_easy) callconv(.c) curl_off_t;
extern fn Curl_ftp_acc_get_remote_append(data: *Curl_easy) callconv(.c) bool;
extern fn Curl_ftp_acc_get_ftp_create_missing_dirs(data: *Curl_easy) callconv(.c) u8;
extern fn Curl_ftp_acc_get_get_filetime(data: *Curl_easy) callconv(.c) bool;
extern fn Curl_ftp_acc_get_quote(data: *Curl_easy) callconv(.c) ?*curl_slist;
extern fn Curl_ftp_acc_get_postquote(data: *Curl_easy) callconv(.c) ?*curl_slist;
extern fn Curl_ftp_acc_get_prequote(data: *Curl_easy) callconv(.c) ?*curl_slist;
extern fn Curl_ftp_acc_has_seek_func(data: *Curl_easy) callconv(.c) bool;
extern fn Curl_ftp_acc_call_seek_func(data: *Curl_easy, offset: curl_off_t, origin: c_int) callconv(.c) c_int;
extern fn Curl_ftp_acc_call_fread_func(data: *Curl_easy, buf: [*]u8, size: usize, nitems: usize) callconv(.c) usize;
extern fn Curl_ftp_acc_connclose(conn: *connectdata, msg: [*:0]const u8) callconv(.c) void;

extern fn Curl_vssh_get_url_path(data: *const Curl_easy) callconv(.c) ?[*:0]const u8;
extern fn Curl_vssh_get_conn_user(conn: *const connectdata) callconv(.c) ?[*:0]const u8;
extern fn Curl_vssh_get_conn_passwd(conn: *const connectdata) callconv(.c) ?[*:0]const u8;
extern fn Curl_vssh_get_conn_host_name(conn: *const connectdata) callconv(.c) [*:0]const u8;
extern fn Curl_vssh_get_conn_remote_port(conn: *const connectdata) callconv(.c) c_int;
extern fn Curl_vssh_get_conn_firstsocket(conn: *const connectdata) callconv(.c) curl_socket_t;
extern fn Curl_vssh_get_conn_protocol(conn: *const connectdata) callconv(.c) curl_prot_t;
extern fn Curl_vssh_set_conn_send_recv(
    conn: *connectdata,
    send_fn: ?Curl_send_fn,
    recv_fn: ?Curl_recv_fn,
) callconv(.c) void;
extern fn Curl_vssh_get_state_wildcardmatch(data: *const Curl_easy) callconv(.c) bool;
extern fn Curl_vssh_set_state_wildcardmatch(data: *Curl_easy, val: bool) callconv(.c) void;
extern fn Curl_vssh_set_info_filetime(data: *Curl_easy, ft: curl_off_t) callconv(.c) void;
extern fn Curl_vssh_has_ssh_keyfunc(data: *const Curl_easy) callconv(.c) bool;
extern fn Curl_vssh_call_ssh_keyfunc(
    data: *Curl_easy,
    knownkey: ?*const curl_khkey,
    foundkey: *const curl_khkey,
    match: c_uint,
) callconv(.c) c_int;
extern fn Curl_vssh_has_ssh_hostkeyfunc(data: *const Curl_easy) callconv(.c) bool;
extern fn Curl_vssh_call_ssh_hostkeyfunc(
    data: *Curl_easy,
    keytype: c_int,
    key: [*]const u8,
    keylen: usize,
) callconv(.c) c_int;

inline fn easyStrGet(data: *Curl_easy, id: c_uint) ?[*:0]const u8 {
    return collections.Curl_u8_strset_get(Curl_easy_strset_ptr(data), @intCast(id));
}

inline fn trcSshEnabled(data: *Curl_easy) bool {
    return Curl_setopt_trc_bind_is_verbose(data) and
        cookie_getinfo_trc.Curl_trc_feat_ssh.log_level >= cookie_getinfo_trc.CURL_LOG_LVL_INFO;
}

// ============================================================================
// 1. State Machine Enum & Error Tables (lib/vssh/ssh.h, vssh.c, libssh2.c)
// ============================================================================

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

/// Map an SFTP `SSH_FX_*` / `LIBSSH2_FX_*` error code to `CURLcode`.
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

// ============================================================================
// 2. lib/vssh/vssh.c — Shared SSH Utilities
// ============================================================================

/// Parse an SFTP/SCP range string (`from-to`) and configure start/size limits.
pub export fn Curl_ssh_range(
    data: *Curl_easy,
    range_opt: ?[*:0]const u8,
    filesize: curl_off_t,
    startp: *curl_off_t,
    sizep: *curl_off_t,
) callconv(.c) CURLcode {
    var range: [*:0]const u8 = range_opt orelse return CURLE_RANGE_ERROR;
    var from: curl_off_t = 0;
    var to: curl_off_t = 0;
    const from_t = curlx_str_number(&range, &from, std.math.maxInt(curl_off_t));
    if (from_t == curlx_parse.STRE_OVERFLOW) {
        return CURLE_RANGE_ERROR;
    }
    curlx_str_passblanks(&range);
    _ = curlx_str_single(&range, '-');

    const to_t = curlx_str_numblanks(&range, &to);
    if ((to_t == curlx_parse.STRE_OVERFLOW) or ((to_t != 0) and (from_t != 0)) or (range[0] != 0)) {
        return CURLE_RANGE_ERROR;
    }

    if (from_t != 0) {
        if (to == 0) {
            return CURLE_RANGE_ERROR;
        } else if (to > filesize) {
            to = filesize;
        }
        from = filesize - to;
        to = filesize - 1;
    } else if (from > filesize) {
        Curl_failf(
            data,
            "Offset (%lld) was beyond file size (%lld)",
            @as(c_longlong, from),
            @as(c_longlong, filesize),
        );
        return CURLE_RANGE_ERROR;
    } else if ((to_t == curlx_parse.STRE_NO_NUM) or (to >= filesize)) {
        to = filesize - 1;
    }

    if (from > to) {
        Curl_failf(data, "Bad range: start offset larger than end offset");
        return CURLE_RANGE_ERROR;
    }
    if ((to - from) == std.math.maxInt(curl_off_t)) {
        return CURLE_RANGE_ERROR;
    }

    startp.* = from;
    sizep.* = to - from + 1;
    return CURLE_OK;
}

/// Translate the URL path into a remote filesystem path, expanding `/~/` for SCP
/// and `~/` for SFTP using `homedir`.
pub export fn Curl_getworkingpath(
    data: *Curl_easy,
    homedir: [*:0]const u8,
    path: *?[*:0]u8,
) callconv(.c) CURLcode {
    var working_path: ?[*:0]u8 = null;
    var real_path: ?[*:0]u8 = null;
    var working_path_len: usize = 0;

    const up_path = Curl_vssh_get_url_path(data) orelse return CURLE_URL_MALFORMAT;
    const result = Curl_urldecode(up_path, 0, &real_path, &working_path_len, REJECT_CTRL);
    if (result != CURLE_OK) {
        return result;
    }
    const rp = real_path orelse return CURLE_OUT_OF_MEMORY;

    const conn = Curl_ftp_acc_get_conn(data);
    const proto: curl_prot_t = if (conn) |c| Curl_vssh_get_conn_protocol(c) else 0;

    if ((proto & CURLPROTO_SCP) != 0) {
        if ((working_path_len > 3) and (std.mem.eql(u8, rp[0..3], "/~/"))) {
            working_path = curl_maprintf("%s/%s", homedir, rp + 3);
            mem.free(rp);
            if (working_path == null) {
                return CURLE_OUT_OF_MEMORY;
            }
        } else {
            working_path = rp;
        }
    } else if ((proto & CURLPROTO_SFTP) != 0) {
        if ((working_path_len > 1) and (rp[1] == '~')) {
            if ((working_path_len > 2) and (rp[2] == '/')) {
                working_path = curl_maprintf("%s/%s", homedir, rp + 3);
            } else if (working_path_len == 2) {
                working_path = curl_maprintf("%s/", homedir);
            }
            mem.free(rp);
            if (working_path == null) {
                return CURLE_OUT_OF_MEMORY;
            }
        } else {
            working_path = rp;
        }
    } else {
        mem.free(rp);
        return CURLE_FAILED_INIT;
    }

    path.* = working_path;
    return CURLE_OK;
}

/// Skip leading whitespace and strip trailing whitespace in-place on a quote line.
pub export fn Curl_quote_line(cp_in: [*:0]const u8) callconv(.c) [*:0]const u8 {
    var cp: [*:0]const u8 = cp_in;
    curlx_str_passblanks(&cp);
    const keep: [*:0]const u8 = cp;
    var out: curlx_parse.Curl_str = .{ .str = null, .len = 0 };
    var end_pos: [*:0]const u8 = cp;
    while (curlx_str_cspn(&cp, &out, "\t ") == curlx_parse.STRE_OK) {
        end_pos = cp;
        curlx_str_passblanks(&cp);
    }
    const mut_end: [*]u8 = @constCast(end_pos);
    mut_end[0] = 0;
    return keep;
}

/// Parse the next quoted or unquoted path argument from `cpp.*`, expanding leading
/// `/~/` with `homedir`.
pub export fn Curl_get_pathname(
    cpp: *?[*:0]const u8,
    path: *?[*:0]u8,
    homedir_opt: ?[*:0]const u8,
) callconv(.c) CURLcode {
    const MAX_PATHLENGTH: usize = 65535;

    path.* = null;
    const start = cpp.*;
    cpp.* = null;
    const cp_init = start orelse return CURLE_QUOTE_ERROR;
    const homedir = homedir_opt orelse return CURLE_QUOTE_ERROR;
    if (cp_init[0] == 0) {
        return CURLE_QUOTE_ERROR;
    }

    var out: containers.dynbuf = undefined;
    containers.curlx_dyn_init(&out, MAX_PATHLENGTH);

    var cp: [*:0]const u8 = cp_init;
    curlx_str_passblanks(&cp);

    if (cp[0] == '"' or cp[0] == '\'') {
        const quot = cp[0];
        cp += 1;

        while (cp[0] != quot) {
            if (cp[0] == 0) {
                containers.curlx_dyn_free(&out);
                return CURLE_QUOTE_ERROR;
            }
            if (cp[0] == '\\') {
                cp += 1;
                if (cp[0] != '\'' and cp[0] != '"' and cp[0] != '\\') {
                    containers.curlx_dyn_free(&out);
                    return CURLE_QUOTE_ERROR;
                }
            }
            const result = containers.curlx_dyn_addn(&out, cp, 1);
            if (result != CURLE_OK) {
                return result;
            }
            cp += 1;
        }
        cp += 1;

        if (containers.curlx_dyn_len(&out) == 0) {
            containers.curlx_dyn_free(&out);
            return CURLE_QUOTE_ERROR;
        }
    } else {
        var word: curlx_parse.Curl_str = .{ .str = null, .len = 0 };
        var content = false;
        if (cp[0] == '/' and cp[1] == '~' and cp[2] == '/') {
            var result = containers.curlx_dyn_add(&out, homedir);
            if (result == CURLE_OK) {
                result = containers.curlx_dyn_addn(&out, "/", 1);
            }
            if (result != CURLE_OK) {
                return result;
            }
            cp += 3;
            content = true;
        }
        const rc = curlx_str_word(&cp, &word, MAX_PATHLENGTH);
        if (rc != 0) {
            if (rc == curlx_parse.STRE_BIG) {
                containers.curlx_dyn_free(&out);
                return CURLE_TOO_LARGE;
            } else if (!content) {
                containers.curlx_dyn_free(&out);
                return CURLE_QUOTE_ERROR;
            }
        } else {
            const result = containers.curlx_dyn_addn(&out, word.str.?, word.len);
            if (result != CURLE_OK) {
                return result;
            }
        }
    }

    curlx_str_passblanks(&cp);
    cpp.* = cp;
    path.* = containers.curlx_dyn_ptr(&out);
    return CURLE_OK;
}

// ============================================================================
// 3. lib/vssh/libssh2.c — Libssh2 Types, Externs, and State Machine
// ============================================================================

pub const LIBSSH2_SESSION = opaque {};
pub const LIBSSH2_CHANNEL = opaque {};
pub const LIBSSH2_SFTP = opaque {};
pub const LIBSSH2_SFTP_HANDLE = opaque {};
pub const LIBSSH2_KNOWNHOSTS = opaque {};
pub const LIBSSH2_AGENT = opaque {};

pub const libssh2_knownhost = extern struct {
    magic: c_uint,
    node: ?*anyopaque,
    name: ?[*:0]u8,
    key: ?[*:0]const u8,
    typemask: c_int,
};

pub const libssh2_agent_publickey = extern struct {
    magic: c_uint,
    node: ?*anyopaque,
    blob: ?[*]u8,
    blob_len: usize,
    comment: ?[*:0]u8,
};

pub const LIBSSH2_SFTP_ATTRIBUTES = extern struct {
    flags: c_ulong,
    filesize: u64,
    uid: c_ulong,
    gid: c_ulong,
    permissions: c_ulong,
    atime: c_ulong,
    mtime: c_ulong,
};

pub const LIBSSH2_SFTP_STATVFS = extern struct {
    f_bsize: u64,
    f_frsize: u64,
    f_blocks: u64,
    f_bfree: u64,
    f_bavail: u64,
    f_files: u64,
    f_ffree: u64,
    f_favail: u64,
    f_fsid: u64,
    f_flag: u64,
    f_namemax: u64,
};

pub const LIBSSH2_USERAUTH_KBDINT_PROMPT = extern struct {
    text: ?[*]u8,
    length: c_uint,
    echo: u8,
};

pub const LIBSSH2_USERAUTH_KBDINT_RESPONSE = extern struct {
    text: ?[*]u8,
    length: c_uint,
};

const LIBSSH2_ERROR_NONE: c_int = 0;
const LIBSSH2_ERROR_EAGAIN: c_int = -37;
const LIBSSH2_ERROR_SFTP_PROTOCOL: c_int = -31;
const LIBSSH2_ERROR_ALLOC: c_int = -6;
const LIBSSH2_ERROR_SOCKET_SEND: c_int = -7;
const LIBSSH2_ERROR_SOCKET_TIMEOUT: c_int = -30;
const LIBSSH2_ERROR_PUBLICKEY_UNVERIFIED: c_int = -19;

const LIBSSH2_FLAG_COMPRESS: c_int = 2;

const LIBSSH2_HOSTKEY_HASH_MD5: c_int = 1;
const LIBSSH2_HOSTKEY_TYPE_UNKNOWN: c_int = 0;
const LIBSSH2_HOSTKEY_TYPE_RSA: c_int = 1;
const LIBSSH2_HOSTKEY_TYPE_DSS: c_int = 2;
const LIBSSH2_HOSTKEY_TYPE_ECDSA_256: c_int = 3;
const LIBSSH2_HOSTKEY_TYPE_ECDSA_384: c_int = 4;
const LIBSSH2_HOSTKEY_TYPE_ECDSA_521: c_int = 5;
const LIBSSH2_HOSTKEY_TYPE_ED25519: c_int = 6;

const LIBSSH2_KNOWNHOST_FILE_OPENSSH: c_int = 1;
const LIBSSH2_KNOWNHOST_TYPE_PLAIN: c_int = 1;
const LIBSSH2_KNOWNHOST_KEYENC_RAW: c_int = 1 << 16;
const LIBSSH2_KNOWNHOST_KEY_SHIFT: c_uint = 18;
const LIBSSH2_KNOWNHOST_KEY_RSA1: c_int = 1 << 18;
const LIBSSH2_KNOWNHOST_KEY_SSHRSA: c_int = 2 << 18;
const LIBSSH2_KNOWNHOST_KEY_SSHDSS: c_int = 3 << 18;
const LIBSSH2_KNOWNHOST_KEY_ECDSA_256: c_int = 4 << 18;
const LIBSSH2_KNOWNHOST_KEY_ECDSA_384: c_int = 5 << 18;
const LIBSSH2_KNOWNHOST_KEY_ECDSA_521: c_int = 6 << 18;
const LIBSSH2_KNOWNHOST_KEY_ED25519: c_int = 7 << 18;
const LIBSSH2_KNOWNHOST_KEY_MASK: c_int = 7 << 18;

const LIBSSH2_KNOWNHOST_CHECK_MATCH: c_int = 0;
const LIBSSH2_KNOWNHOST_CHECK_MISMATCH: c_int = 1;
const LIBSSH2_KNOWNHOST_CHECK_NOTFOUND: c_int = 2;
const LIBSSH2_KNOWNHOST_CHECK_FAILURE: c_int = 3;

const LIBSSH2_SESSION_BLOCK_INBOUND: c_int = 0x0001;
const LIBSSH2_SESSION_BLOCK_OUTBOUND: c_int = 0x0002;

const SSH_DISCONNECT_BY_APPLICATION: c_int = 11;

const LIBSSH2_FXF_READ: c_ulong = 0x00000001;
const LIBSSH2_FXF_WRITE: c_ulong = 0x00000002;
const LIBSSH2_FXF_APPEND: c_ulong = 0x00000004;
const LIBSSH2_FXF_CREAT: c_ulong = 0x00000008;
const LIBSSH2_FXF_TRUNC: c_ulong = 0x00000010;

const LIBSSH2_SFTP_OPENFILE: c_int = 0;
const LIBSSH2_SFTP_OPENDIR: c_int = 1;

const LIBSSH2_SFTP_STAT: c_int = 0;
const LIBSSH2_SFTP_LSTAT: c_int = 1;
const LIBSSH2_SFTP_SETSTAT: c_int = 2;

const LIBSSH2_SFTP_SYMLINK: c_int = 0;
const LIBSSH2_SFTP_READLINK: c_int = 1;
const LIBSSH2_SFTP_REALPATH: c_int = 2;

const LIBSSH2_SFTP_RENAME_OVERWRITE: c_long = 0x00000001;
const LIBSSH2_SFTP_RENAME_ATOMIC: c_long = 0x00000002;
const LIBSSH2_SFTP_RENAME_NATIVE: c_long = 0x00000004;

const LIBSSH2_SFTP_ATTR_SIZE: c_ulong = 0x00000001;
const LIBSSH2_SFTP_ATTR_UIDGID: c_ulong = 0x00000002;
const LIBSSH2_SFTP_ATTR_PERMISSIONS: c_ulong = 0x00000004;
const LIBSSH2_SFTP_ATTR_ACMODTIME: c_ulong = 0x00000008;

const LIBSSH2_SFTP_S_IFMT: c_ulong = 0o170000;
const LIBSSH2_SFTP_S_IFIFO: c_ulong = 0o010000;
const LIBSSH2_SFTP_S_IFCHR: c_ulong = 0o020000;
const LIBSSH2_SFTP_S_IFDIR: c_ulong = 0o040000;
const LIBSSH2_SFTP_S_IFBLK: c_ulong = 0o060000;
const LIBSSH2_SFTP_S_IFREG: c_ulong = 0o100000;
const LIBSSH2_SFTP_S_IFLNK: c_ulong = 0o120000;
const LIBSSH2_SFTP_S_IFSOCK: c_ulong = 0o140000;
const LIBSSH2_SFTP_S_IRWXU: c_ulong = 0o0700;
const LIBSSH2_SFTP_S_IRUSR: c_ulong = 0o0400;
const LIBSSH2_SFTP_S_IWUSR: c_ulong = 0o0200;
const LIBSSH2_SFTP_S_IXUSR: c_ulong = 0o0100;
const LIBSSH2_SFTP_S_IRGRP: c_ulong = 0o0040;
const LIBSSH2_SFTP_S_IWGRP: c_ulong = 0o0020;
const LIBSSH2_SFTP_S_IXGRP: c_ulong = 0o0010;
const LIBSSH2_SFTP_S_IROTH: c_ulong = 0o0004;
const LIBSSH2_SFTP_S_IWOTH: c_ulong = 0o0002;
const LIBSSH2_SFTP_S_IXOTH: c_ulong = 0o0001;
const LIBSSH2_SFTP_S_ISUID: c_ulong = 0o4000;
const LIBSSH2_SFTP_S_ISGID: c_ulong = 0o2000;
const LIBSSH2_SFTP_S_ISVTX: c_ulong = 0o1000;

const LIBSSH2_ST_RDONLY: u64 = 1;
const LIBSSH2_ST_NOSUID: u64 = 2;

/// Per-easy-handle SSH protocol state (`struct SSHPROTO` in `lib/vssh/ssh.h`).
pub const SSHPROTO = extern struct {
    path: ?[*:0]u8 = null,
    readdir_filename: ?[*:0]u8 = null,
    readdir_longentry: ?[*:0]u8 = null,
    readdir: containers.dynbuf = std.mem.zeroes(containers.dynbuf),
    readdir_linkPath: ?[*:0]u8 = null,
    readdir_attrs: LIBSSH2_SFTP_ATTRIBUTES = std.mem.zeroes(LIBSSH2_SFTP_ATTRIBUTES),
};

/// Per-connection SSH state (`struct ssh_conn` in `lib/vssh/ssh.h`).
/// Note: `priv_key` and `pub_key` are kept first for `Curl_zig_url_ssh_conn_keys`.
pub const ssh_conn = extern struct {
    priv_key: ?[*:0]const u8 = null,
    pub_key: ?[*:0]const u8 = null,
    authlist: ?[*:0]const u8 = null,
    passphrase: ?[*:0]const u8 = null,
    rsa_pub: ?[*:0]u8 = null,
    rsa: ?[*:0]u8 = null,
    authed: bool = false,
    acceptfail: bool = false,
    initialised: bool = false,
    state: sshstate = .SSH_NO_STATE,
    nextstate: sshstate = .SSH_NO_STATE,
    actualcode: CURLcode = CURLE_OK,
    quote_item: ?*curl_slist = null,
    quote_path1: ?[*:0]u8 = null,
    quote_path2: ?[*:0]u8 = null,
    homedir: ?[*:0]u8 = null,
    secondCreateDirs: usize = 0,
    slash_pos: ?[*:0]u8 = null,
    orig_waitfor: c_int = 0,
    quote_attrs: LIBSSH2_SFTP_ATTRIBUTES = std.mem.zeroes(LIBSSH2_SFTP_ATTRIBUTES),
    ssh_session: ?*LIBSSH2_SESSION = null,
    ssh_channel: ?*LIBSSH2_CHANNEL = null,
    sftp_session: ?*LIBSSH2_SFTP = null,
    sftp_handle: ?*LIBSSH2_SFTP_HANDLE = null,
    kh: ?*LIBSSH2_KNOWNHOSTS = null,
    ssh_agent: ?*LIBSSH2_AGENT = null,
    sshagent_identity: ?*libssh2_agent_publickey = null,
    sshagent_prev_identity: ?*libssh2_agent_publickey = null,
};

extern fn libssh2_init(flags: c_int) callconv(.c) c_int;
extern fn libssh2_exit() callconv(.c) void;
extern fn libssh2_version(req_version_num: c_int) callconv(.c) ?[*:0]const u8;
extern fn libssh2_session_init_ex(
    my_alloc: ?*const anyopaque,
    my_free: ?*const anyopaque,
    my_realloc: ?*const anyopaque,
    abstract: ?*anyopaque,
) callconv(.c) ?*LIBSSH2_SESSION;
extern fn libssh2_session_free(session: *LIBSSH2_SESSION) callconv(.c) c_int;
extern fn libssh2_session_set_blocking(session: *LIBSSH2_SESSION, blocking: c_int) callconv(.c) void;
extern fn libssh2_session_flag(session: *LIBSSH2_SESSION, flag: c_int, value: c_int) callconv(.c) c_int;
extern fn libssh2_session_handshake(session: *LIBSSH2_SESSION, sock: curl_socket_t) callconv(.c) c_int;
extern fn libssh2_session_hostkey(session: *LIBSSH2_SESSION, len: *usize, typ: *c_int) callconv(.c) ?[*]const u8;
extern fn libssh2_hostkey_hash(session: *LIBSSH2_SESSION, hash_type: c_int) callconv(.c) ?[*]const u8;
extern fn libssh2_session_last_errno(session: *LIBSSH2_SESSION) callconv(.c) c_int;
extern fn libssh2_session_last_error(
    session: *LIBSSH2_SESSION,
    errmsg: *?[*:0]u8,
    errmsg_len: ?*c_int,
    want_buf: c_int,
) callconv(.c) c_int;
extern fn libssh2_session_block_directions(session: *LIBSSH2_SESSION) callconv(.c) c_int;
extern fn libssh2_session_disconnect_ex(
    session: *LIBSSH2_SESSION,
    reason: c_int,
    description: [*:0]const u8,
    lang: [*:0]const u8,
) callconv(.c) c_int;
extern fn libssh2_knownhost_init(session: *LIBSSH2_SESSION) callconv(.c) ?*LIBSSH2_KNOWNHOSTS;
extern fn libssh2_knownhost_free(hosts: *LIBSSH2_KNOWNHOSTS) callconv(.c) void;
extern fn libssh2_knownhost_readfile(
    hosts: *LIBSSH2_KNOWNHOSTS,
    filename: [*:0]const u8,
    typ: c_int,
) callconv(.c) c_int;
extern fn libssh2_knownhost_writefile(
    hosts: *LIBSSH2_KNOWNHOSTS,
    filename: [*:0]const u8,
    typ: c_int,
) callconv(.c) c_int;
extern fn libssh2_knownhost_checkp(
    hosts: *LIBSSH2_KNOWNHOSTS,
    host: [*:0]const u8,
    port: c_int,
    key: [*]const u8,
    keylen: usize,
    typemask: c_int,
    known: *?*libssh2_knownhost,
) callconv(.c) c_int;
extern fn libssh2_knownhost_add(
    hosts: *LIBSSH2_KNOWNHOSTS,
    host: [*:0]const u8,
    salt: ?[*:0]const u8,
    key: [*]const u8,
    keylen: usize,
    typemask: c_int,
    store: *?*libssh2_knownhost,
) callconv(.c) c_int;
extern fn libssh2_userauth_list(
    session: *LIBSSH2_SESSION,
    username: [*:0]const u8,
    username_len: c_uint,
) callconv(.c) ?[*:0]u8;
extern fn libssh2_userauth_authenticated(session: *LIBSSH2_SESSION) callconv(.c) c_int;
extern fn libssh2_userauth_publickey_fromfile_ex(
    session: *LIBSSH2_SESSION,
    username: [*:0]const u8,
    username_len: c_uint,
    publickey: ?[*:0]const u8,
    privatekey: [*:0]const u8,
    passphrase: ?[*:0]const u8,
) callconv(.c) c_int;
extern fn libssh2_userauth_password_ex(
    session: *LIBSSH2_SESSION,
    username: [*:0]const u8,
    username_len: c_uint,
    password: [*:0]const u8,
    password_len: c_uint,
    passwd_change_cb: ?*const anyopaque,
) callconv(.c) c_int;
extern fn libssh2_userauth_keyboard_interactive_ex(
    session: *LIBSSH2_SESSION,
    username: [*:0]const u8,
    username_len: c_uint,
    response_callback: *const anyopaque,
) callconv(.c) c_int;
extern fn libssh2_agent_init(session: *LIBSSH2_SESSION) callconv(.c) ?*LIBSSH2_AGENT;
extern fn libssh2_agent_connect(agent: *LIBSSH2_AGENT) callconv(.c) c_int;
extern fn libssh2_agent_disconnect(agent: *LIBSSH2_AGENT) callconv(.c) c_int;
extern fn libssh2_agent_free(agent: *LIBSSH2_AGENT) callconv(.c) void;
extern fn libssh2_agent_list_identities(agent: *LIBSSH2_AGENT) callconv(.c) c_int;
extern fn libssh2_agent_get_identity(
    agent: *LIBSSH2_AGENT,
    store: *?*libssh2_agent_publickey,
    prev: ?*libssh2_agent_publickey,
) callconv(.c) c_int;
extern fn libssh2_agent_userauth(
    agent: *LIBSSH2_AGENT,
    username: [*:0]const u8,
    identity: *libssh2_agent_publickey,
) callconv(.c) c_int;
extern fn libssh2_sftp_init(session: *LIBSSH2_SESSION) callconv(.c) ?*LIBSSH2_SFTP;
extern fn libssh2_sftp_shutdown(sftp: *LIBSSH2_SFTP) callconv(.c) c_int;
extern fn libssh2_sftp_last_error(sftp: *LIBSSH2_SFTP) callconv(.c) c_ulong;
extern fn libssh2_sftp_open_ex(
    sftp: *LIBSSH2_SFTP,
    filename: [*:0]const u8,
    filename_len: c_uint,
    flags: c_ulong,
    mode: c_long,
    open_type: c_int,
) callconv(.c) ?*LIBSSH2_SFTP_HANDLE;
extern fn libssh2_sftp_close_handle(handle: *LIBSSH2_SFTP_HANDLE) callconv(.c) c_int;
extern fn libssh2_sftp_read(handle: *LIBSSH2_SFTP_HANDLE, buffer: [*]u8, buffer_maxlen: usize) callconv(.c) isize;
extern fn libssh2_sftp_write(handle: *LIBSSH2_SFTP_HANDLE, buffer: [*]const u8, count: usize) callconv(.c) isize;
extern fn libssh2_sftp_seek64(handle: *LIBSSH2_SFTP_HANDLE, offset: u64) callconv(.c) void;
extern fn libssh2_sftp_stat_ex(
    sftp: *LIBSSH2_SFTP,
    path: [*:0]const u8,
    path_len: c_uint,
    stat_type: c_int,
    attrs: *LIBSSH2_SFTP_ATTRIBUTES,
) callconv(.c) c_int;
extern fn libssh2_sftp_symlink_ex(
    sftp: *LIBSSH2_SFTP,
    path: [*:0]const u8,
    path_len: c_uint,
    target: [*]u8,
    target_len: c_uint,
    link_type: c_int,
) callconv(.c) c_int;
extern fn libssh2_sftp_mkdir_ex(
    sftp: *LIBSSH2_SFTP,
    path: [*:0]const u8,
    path_len: c_uint,
    mode: c_long,
) callconv(.c) c_int;
extern fn libssh2_sftp_rmdir_ex(
    sftp: *LIBSSH2_SFTP,
    path: [*:0]const u8,
    path_len: c_uint,
) callconv(.c) c_int;
extern fn libssh2_sftp_rename_ex(
    sftp: *LIBSSH2_SFTP,
    source_filename: [*:0]const u8,
    source_filename_len: c_uint,
    dest_filename: [*:0]const u8,
    dest_filename_len: c_uint,
    flags: c_long,
) callconv(.c) c_int;
extern fn libssh2_sftp_unlink_ex(
    sftp: *LIBSSH2_SFTP,
    filename: [*:0]const u8,
    filename_len: c_uint,
) callconv(.c) c_int;
extern fn libssh2_sftp_statvfs(
    sftp: *LIBSSH2_SFTP,
    path: [*:0]const u8,
    path_len: usize,
    st: *LIBSSH2_SFTP_STATVFS,
) callconv(.c) c_int;
extern fn libssh2_sftp_readdir_ex(
    handle: *LIBSSH2_SFTP_HANDLE,
    buffer: [*]u8,
    buffer_maxlen: usize,
    longentry: ?[*]u8,
    longentry_maxlen: usize,
    attrs: *LIBSSH2_SFTP_ATTRIBUTES,
) callconv(.c) c_int;
extern fn libssh2_scp_send64(
    session: *LIBSSH2_SESSION,
    path: [*:0]const u8,
    mode: c_int,
    size: i64,
    mtime: isize,
    atime: isize,
) callconv(.c) ?*LIBSSH2_CHANNEL;
extern fn Curl_libssh2_scp_recv2_size(
    session: *LIBSSH2_SESSION,
    path: [*:0]const u8,
    pbytecount: *curl_off_t,
) callconv(.c) ?*LIBSSH2_CHANNEL;
extern fn libssh2_channel_write_ex(
    channel: *LIBSSH2_CHANNEL,
    stream_id: c_int,
    buf: [*]const u8,
    buflen: usize,
) callconv(.c) isize;
extern fn libssh2_channel_read_ex(
    channel: *LIBSSH2_CHANNEL,
    stream_id: c_int,
    buf: [*]u8,
    buflen: usize,
) callconv(.c) isize;
extern fn libssh2_channel_send_eof(channel: *LIBSSH2_CHANNEL) callconv(.c) c_int;
extern fn libssh2_channel_wait_eof(channel: *LIBSSH2_CHANNEL) callconv(.c) c_int;
extern fn libssh2_channel_wait_closed(channel: *LIBSSH2_CHANNEL) callconv(.c) c_int;
extern fn libssh2_channel_free(channel: *LIBSSH2_CHANNEL) callconv(.c) c_int;

pub export fn Curl_zig_url_ssh_conn_keys(
    sshc_raw: ?*const anyopaque,
    ppriv_key: *?[*:0]const u8,
    ppub_key: *?[*:0]const u8,
) callconv(.c) void {
    if (comptime use_ssh) {
        if (sshc_raw) |raw| {
            const sshc: *const ssh_conn = @ptrCast(@alignCast(raw));
            ppriv_key.* = sshc.priv_key;
            ppub_key.* = sshc.pub_key;
            return;
        }
    }
    ppriv_key.* = null;
    ppub_key.* = null;
}

pub fn ssh_easy_dtor(key: [*:0]const u8, klen: usize, entry: ?*anyopaque) callconv(.c) void {
    _ = key;
    _ = klen;
    const sshp: *SSHPROTO = @ptrCast(@alignCast(entry orelse return));
    if (sshp.path) |p| {
        mem.free(p);
        sshp.path = null;
    }
    if (sshp.readdir_filename) |f| {
        mem.free(f);
        sshp.readdir_filename = null;
    }
    if (sshp.readdir_longentry) |le| {
        mem.free(le);
        sshp.readdir_longentry = null;
    }
    if (sshp.readdir_linkPath) |lp| {
        mem.free(lp);
        sshp.readdir_linkPath = null;
    }
    containers.curlx_dyn_free(&sshp.readdir);
    mem.freeSized(sshp, @sizeOf(SSHPROTO));
}

pub fn ssh_conn_dtor(key: [*:0]const u8, klen: usize, entry: ?*anyopaque) callconv(.c) void {
    _ = key;
    _ = klen;
    const sshc: *ssh_conn = @ptrCast(@alignCast(entry orelse return));
    if (sshc.rsa) |r| {
        mem.freeSecretZ(r);
        sshc.rsa = null;
    }
    if (sshc.rsa_pub) |rp| {
        mem.freeSecretZ(rp);
        sshc.rsa_pub = null;
    }
    if (sshc.quote_path1) |p1| {
        mem.free(p1);
        sshc.quote_path1 = null;
    }
    if (sshc.quote_path2) |p2| {
        mem.free(p2);
        sshc.quote_path2 = null;
    }
    if (sshc.homedir) |hd| {
        mem.free(hd);
        sshc.homedir = null;
    }
    mem.freeSized(sshc, @sizeOf(ssh_conn));
}

/// Multi-step SFTP quote path allocation with `errdefer` so a failed second
/// path allocation frees and nulls `quote_path1` automatically.
pub fn allocSftpQuotePaths(
    arg_ptr: *?[*:0]const u8,
    homedir: [*:0]const u8,
    need_second: bool,
    out_path1: *?[*:0]u8,
    out_path2: *?[*:0]u8,
) error{ OutOfMemory, QuoteError }!void {
    out_path1.* = null;
    out_path2.* = null;
    const r1 = Curl_get_pathname(arg_ptr, out_path1, homedir);
    if (r1 != CURLE_OK) {
        return if (r1 == CURLE_OUT_OF_MEMORY) error.OutOfMemory else error.QuoteError;
    }
    errdefer {
        if (out_path1.*) |p1| {
            mem.free(p1);
            out_path1.* = null;
        }
    }
    if (need_second) {
        const r2 = Curl_get_pathname(arg_ptr, out_path2, homedir);
        if (r2 != CURLE_OK) {
            return if (r2 == CURLE_OUT_OF_MEMORY) error.OutOfMemory else error.QuoteError;
        }
    }
}

/// Multi-step SFTP readdir buffer allocation with `errdefer` so failure on the
/// second buffer frees and nulls the first buffer.
pub fn allocSftpReaddirBuffers(sshp: *SSHPROTO) error{OutOfMemory}!void {
    const f_raw = mem.malloc(DYN_PATH_MAX + 1) orelse return error.OutOfMemory;
    sshp.readdir_filename = @ptrCast(f_raw);
    errdefer {
        mem.freeSized(sshp.readdir_filename, DYN_PATH_MAX + 1);
        sshp.readdir_filename = null;
    }
    const le_raw = mem.malloc(DYN_PATH_MAX + 1) orelse return error.OutOfMemory;
    sshp.readdir_longentry = @ptrCast(le_raw);
}

pub export fn Curl_ssh_setup_connection(
    data_opt: ?*Curl_easy,
    conn_opt: ?*connectdata,
) callconv(.c) CURLcode {
    const data = data_opt orelse return CURLE_BAD_FUNCTION_ARGUMENT;
    const conn = conn_opt orelse return CURLE_BAD_FUNCTION_ARGUMENT;

    const sshp_raw = mem.calloc(1, @sizeOf(SSHPROTO)) orelse return CURLE_OUT_OF_MEMORY;
    const sshp: *SSHPROTO = @ptrCast(@alignCast(sshp_raw));
    containers.curlx_dyn_init(&sshp.readdir, DYN_PATH_MAX * 2);
    if (Curl_meta_set(data, CURL_META_SSH_EASY, sshp, ssh_easy_dtor) != CURLE_OK) {
        return CURLE_OUT_OF_MEMORY;
    }

    if (Curl_conn_meta_get(conn, CURL_META_SSH_CONN) == null) {
        const ssh_raw = mem.calloc(1, @sizeOf(ssh_conn)) orelse return CURLE_OUT_OF_MEMORY;
        if (Curl_conn_meta_set(conn, CURL_META_SSH_CONN, ssh_raw, ssh_conn_dtor) != CURLE_OK) {
            return CURLE_OUT_OF_MEMORY;
        }
    }
    return CURLE_OK;
}

inline fn sftp_libssh2_last_error(sftp: ?*LIBSSH2_SFTP) c_ulong {
    if (sftp) |s| {
        return libssh2_sftp_last_error(s);
    }
    return 0;
}

fn session_error_to_CURLE(err: c_int) CURLcode {
    return switch (err) {
        LIBSSH2_ERROR_NONE => CURLE_OK,
        LIBSSH2_ERROR_ALLOC => CURLE_OUT_OF_MEMORY,
        LIBSSH2_ERROR_SOCKET_SEND => CURLE_SEND_ERROR,
        LIBSSH2_ERROR_SOCKET_TIMEOUT => CURLE_OPERATION_TIMEDOUT,
        LIBSSH2_ERROR_PUBLICKEY_UNVERIFIED => CURLE_PEER_FAILED_VERIFICATION,
        else => CURLE_SSH,
    };
}

fn libssh2_malloc_cb(count: usize, abstract: *?*anyopaque) callconv(.c) ?*anyopaque {
    _ = abstract;
    return mem.malloc(count);
}

fn libssh2_realloc_cb(ptr: ?*anyopaque, count: usize, abstract: *?*anyopaque) callconv(.c) ?*anyopaque {
    _ = abstract;
    return mem.realloc(ptr, count);
}

fn libssh2_free_cb(ptr: ?*anyopaque, abstract: *?*anyopaque) callconv(.c) void {
    _ = abstract;
    if (ptr) |p| {
        mem.free(p);
    }
}

fn ssh_state(data: *Curl_easy, sshc: *ssh_conn, nowstate: sshstate) void {
    const oldstate = sshc.state;
    if (oldstate != nowstate) {
        if (trcSshEnabled(data)) {
            Curl_trc_feat_infof(
                data,
                &cookie_getinfo_trc.Curl_trc_feat_ssh,
                "[%s] -> [%s]",
                Curl_ssh_statename(oldstate),
                Curl_ssh_statename(nowstate),
            );
        }
    }
    sshc.state = nowstate;
}

fn kbd_callback(
    name: ?[*]const u8,
    name_len: c_int,
    instruction: ?[*]const u8,
    instruction_len: c_int,
    num_prompts: c_int,
    prompts: ?[*]const LIBSSH2_USERAUTH_KBDINT_PROMPT,
    responses: ?[*]LIBSSH2_USERAUTH_KBDINT_RESPONSE,
    abstract: *?*anyopaque,
) callconv(.c) void {
    _ = name;
    _ = name_len;
    _ = instruction;
    _ = instruction_len;
    const data: *Curl_easy = @ptrCast(@alignCast(abstract.* orelse return));
    const conn = Curl_ftp_acc_get_conn(data) orelse return;
    if (num_prompts == 1) {
        if (prompts) |pr| {
            if (responses) |resp| {
                const passwd = Curl_vssh_get_conn_passwd(conn) orelse return;
                _ = pr;
                const dup = mem.strdup(passwd) orelse return;
                resp[0].text = dup;
                resp[0].length = @intCast(std.mem.len(passwd));
            }
        }
    }
}

fn convert_ssh2_keytype(sshkeytype: c_int) c_uint {
    return switch (sshkeytype) {
        LIBSSH2_HOSTKEY_TYPE_RSA => CURLKHTYPE_RSA,
        LIBSSH2_HOSTKEY_TYPE_DSS => CURLKHTYPE_DSS,
        LIBSSH2_HOSTKEY_TYPE_ECDSA_256,
        LIBSSH2_HOSTKEY_TYPE_ECDSA_384,
        LIBSSH2_HOSTKEY_TYPE_ECDSA_521,
        => CURLKHTYPE_ECDSA,
        LIBSSH2_HOSTKEY_TYPE_ED25519 => CURLKHTYPE_ED25519,
        else => CURLKHTYPE_UNKNOWN,
    };
}

fn ssh_knownhost(data: *Curl_easy, sshc: *ssh_conn) CURLcode {
    var result: CURLcode = CURLE_OK;
    const kh_file = easyStrGet(data, setopt.STRING_SSH_KNOWNHOSTS);
    const has_keyfunc = Curl_vssh_has_ssh_keyfunc(data);

    if (kh_file != null or has_keyfunc) {
        const session = sshc.ssh_session orelse return CURLE_FAILED_INIT;
        const conn = Curl_ftp_acc_get_conn(data) orelse return CURLE_FAILED_INIT;
        var keylen: usize = 0;
        var keytype: c_int = 0;
        const remotekey = libssh2_session_hostkey(session, &keylen, &keytype) orelse {
            var err_msg: ?[*:0]u8 = null;
            _ = libssh2_session_last_error(session, &err_msg, null, 0);
            Curl_failf(
                data,
                "Cannot obtain remote host key from SSH session: %s",
                err_msg orelse "unknown",
            );
            ssh_state(data, sshc, .SSH_SESSION_FREE);
            return CURLE_PEER_FAILED_VERIFICATION;
        };

        var keycheck: c_int = LIBSSH2_KNOWNHOST_CHECK_FAILURE;
        var keybit: c_int = 0;
        var host: ?*libssh2_knownhost = null;

        if (kh_file != null) {
            const kh = sshc.kh orelse {
                ssh_state(data, sshc, .SSH_SESSION_FREE);
                return CURLE_PEER_FAILED_VERIFICATION;
            };
            keybit = switch (keytype) {
                LIBSSH2_HOSTKEY_TYPE_RSA => LIBSSH2_KNOWNHOST_KEY_SSHRSA,
                LIBSSH2_HOSTKEY_TYPE_DSS => LIBSSH2_KNOWNHOST_KEY_SSHDSS,
                LIBSSH2_HOSTKEY_TYPE_ECDSA_256 => LIBSSH2_KNOWNHOST_KEY_ECDSA_256,
                LIBSSH2_HOSTKEY_TYPE_ECDSA_384 => LIBSSH2_KNOWNHOST_KEY_ECDSA_384,
                LIBSSH2_HOSTKEY_TYPE_ECDSA_521 => LIBSSH2_KNOWNHOST_KEY_ECDSA_521,
                LIBSSH2_HOSTKEY_TYPE_ED25519 => LIBSSH2_KNOWNHOST_KEY_ED25519,
                else => 0,
            };
            if (keybit == 0) {
                Curl_failf(data, "Unsupported key type, cannot check knownhosts");
                ssh_state(data, sshc, .SSH_SESSION_FREE);
                return CURLE_PEER_FAILED_VERIFICATION;
            }

            keycheck = libssh2_knownhost_checkp(
                kh,
                Curl_vssh_get_conn_host_name(conn),
                Curl_vssh_get_conn_remote_port(conn),
                remotekey,
                keylen,
                LIBSSH2_KNOWNHOST_TYPE_PLAIN | LIBSSH2_KNOWNHOST_KEYENC_RAW | keybit,
                &host,
            );

            if (trcSshEnabled(data)) {
                const check_str: [*:0]const u8 = switch (keycheck) {
                    LIBSSH2_KNOWNHOST_CHECK_FAILURE => "failure",
                    LIBSSH2_KNOWNHOST_CHECK_NOTFOUND => "not found",
                    LIBSSH2_KNOWNHOST_CHECK_MATCH => "match",
                    else => "mismatch",
                };
                const key_str: [*:0]const u8 = if (keycheck <= LIBSSH2_KNOWNHOST_CHECK_MISMATCH and host != null)
                    (host.?.key orelse "<none>")
                else
                    "<none>";
                Curl_trc_feat_infof(
                    data,
                    &cookie_getinfo_trc.Curl_trc_feat_ssh,
                    "Host key check: %s, key: %s",
                    check_str,
                    key_str,
                );
            }
        }

        if (keycheck != LIBSSH2_KNOWNHOST_CHECK_MATCH) {
            if (has_keyfunc) {
                var knownkey_buf: curl_khkey = undefined;
                var knownkeyp: ?*const curl_khkey = null;
                if (keycheck <= LIBSSH2_KNOWNHOST_CHECK_MISMATCH) {
                    if (host) |h| {
                        if (h.key) |hk| {
                            const keytype_kh: c_uint = @intCast(@as(c_uint, @bitCast(h.typemask & LIBSSH2_KNOWNHOST_KEY_MASK)) >> LIBSSH2_KNOWNHOST_KEY_SHIFT);
                            knownkey_buf = .{
                                .key = hk,
                                .len = std.mem.len(hk),
                                .keytype = keytype_kh,
                            };
                            knownkeyp = &knownkey_buf;
                        }
                    }
                }
                const foundkey = curl_khkey{
                    .key = remotekey,
                    .len = keylen,
                    .keytype = convert_ssh2_keytype(keytype),
                };
                const khmatch: c_uint = if (@as(c_uint, @bitCast(keycheck)) < CURLKHMATCH_LAST)
                    @bitCast(keycheck)
                else
                    CURLKHMATCH_LAST;

                const rc = Curl_vssh_call_ssh_keyfunc(data, knownkeyp, &foundkey, khmatch);
                switch (rc) {
                    CURLKHSTAT_FINE_ADD_TO_FILE => {
                        if (kh_file) |kf| {
                            if (sshc.kh) |kh| {
                                const addrc = libssh2_knownhost_add(
                                    kh,
                                    Curl_vssh_get_conn_host_name(conn),
                                    null,
                                    remotekey,
                                    keylen,
                                    LIBSSH2_KNOWNHOST_TYPE_PLAIN | LIBSSH2_KNOWNHOST_KEYENC_RAW | keybit,
                                    &host,
                                );
                                if (addrc != 0) {
                                    Curl_infof(data, "WARNING: failed to store the SSH host key, rc=%d", addrc);
                                } else {
                                    const wrc = libssh2_knownhost_writefile(kh, kf, LIBSSH2_KNOWNHOST_FILE_OPENSSH);
                                    if (wrc != 0) {
                                        Curl_infof(data, "WARNING: failed to write known_hosts %s", kf);
                                    }
                                }
                            }
                        }
                    },
                    CURLKHSTAT_FINE => {},
                    else => {
                        Curl_failf(data, "The Trick callback aborted the SSHissen");
                        result = CURLE_PEER_FAILED_VERIFICATION;
                    },
                }
            } else {
                Curl_failf(data, "SSH public key verification failed");
                result = CURLE_PEER_FAILED_VERIFICATION;
            }
        }
    }
    if (result != CURLE_OK) {
        ssh_state(data, sshc, .SSH_SESSION_FREE);
    }
    return result;
}

fn ssh_check_fingerprint(data: *Curl_easy, sshc: *ssh_conn) CURLcode {
    const session = sshc.ssh_session orelse return CURLE_FAILED_INIT;
    const pubkey_md5 = easyStrGet(data, setopt.STRING_SSH_HOST_PUBLIC_KEY_MD5);
    const pubkey_sha256 = easyStrGet(data, setopt.STRING_SSH_HOST_PUBLIC_KEY_SHA256);

    if (Curl_vssh_has_ssh_hostkeyfunc(data)) {
        var keylen: usize = 0;
        var keytype: c_int = 0;
        const remotekey = libssh2_session_hostkey(session, &keylen, &keytype) orelse {
            ssh_state(data, sshc, .SSH_SESSION_FREE);
            return CURLE_PEER_FAILED_VERIFICATION;
        };
        const ctype: c_int = @intCast(convert_ssh2_keytype(keytype));
        if (Curl_vssh_call_ssh_hostkeyfunc(data, ctype, remotekey, keylen) != CURLKHMATCH_OK) {
            ssh_state(data, sshc, .SSH_SESSION_FREE);
            return CURLE_PEER_FAILED_VERIFICATION;
        }
        return ssh_knownhost(data, sshc);
    }

    if (pubkey_sha256) |expected_sha256| {
        var fingerprint_b64: ?[*:0]u8 = null;
        var b64_len: usize = 0;
        var keylen: usize = 0;
        var keytype: c_int = 0;
        const remotekey = libssh2_session_hostkey(session, &keylen, &keytype) orelse {
            var err_msg: ?[*:0]u8 = null;
            _ = libssh2_session_last_error(session, &err_msg, null, 0);
            Curl_failf(
                data,
                "Denied establishing ssh session: sha256 fingerprint: %s",
                err_msg orelse "not available",
            );
            ssh_state(data, sshc, .SSH_SESSION_FREE);
            return CURLE_PEER_FAILED_VERIFICATION;
        };

        var hash: [32]u8 = undefined;
        if (crypto.Curl_sha256it(&hash, remotekey, keylen) != CURLE_OK) {
            Curl_failf(data, "Denied establishing ssh session: sha256 fingerprint could not be calculated");
            ssh_state(data, sshc, .SSH_SESSION_FREE);
            return CURLE_PEER_FAILED_VERIFICATION;
        }

        if (curlx_parse.curlx_base64_encode(&hash, hash.len, &fingerprint_b64, &b64_len) != CURLE_OK) {
            ssh_state(data, sshc, .SSH_SESSION_FREE);
            return CURLE_PEER_FAILED_VERIFICATION;
        }
        const fp = fingerprint_b64 orelse {
            ssh_state(data, sshc, .SSH_SESSION_FREE);
            return CURLE_PEER_FAILED_VERIFICATION;
        };
        defer mem.free(fp);

        // Strip trailing '=' padding characters if expected_sha256 has no trailing '='
        const exp_slice = std.mem.span(expected_sha256);
        var fp_slice = fp[0..b64_len];
        if (!std.mem.endsWith(u8, exp_slice, "=")) {
            while (fp_slice.len > 0 and fp_slice[fp_slice.len - 1] == '=') {
                fp_slice = fp_slice[0 .. fp_slice.len - 1];
            }
        }
        if (!std.mem.eql(u8, fp_slice, exp_slice)) {
            Curl_failf(
                data,
                "Denied establishing ssh session: mismatch sha256 fingerprint. Remote %s is not equal to %s",
                fp,
                expected_sha256,
            );
            ssh_state(data, sshc, .SSH_SESSION_FREE);
            return CURLE_PEER_FAILED_VERIFICATION;
        }
    }

    if (pubkey_md5) |expected_md5| {
        const fingerprint = libssh2_hostkey_hash(session, LIBSSH2_HOSTKEY_HASH_MD5) orelse {
            Curl_failf(
                data,
                "Denied establishing ssh session: md5 fingerprint: not available",
            );
            ssh_state(data, sshc, .SSH_SESSION_FREE);
            return CURLE_PEER_FAILED_VERIFICATION;
        };
        var md5buffer: [33]u8 = undefined;
        const hex_chars = "0123456789abcdef";
        for (0..16) |i| {
            const b = fingerprint[i];
            md5buffer[i * 2] = hex_chars[b >> 4];
            md5buffer[i * 2 + 1] = hex_chars[b & 0x0f];
        }
        md5buffer[32] = 0;
        const md5_cstr: [*:0]const u8 = @ptrCast(&md5buffer);
        if (primitives.curl_strequal(md5_cstr, expected_md5) == 0) {
            Curl_failf(
                data,
                "Denied establishing ssh session: mismatch md5 fingerprint. Remote %s is not equal to %s",
                md5_cstr,
                expected_md5,
            );
            ssh_state(data, sshc, .SSH_SESSION_FREE);
            return CURLE_PEER_FAILED_VERIFICATION;
        }
    }

    return ssh_knownhost(data, sshc);
}

fn ssh_force_knownhost_key_type(data: *Curl_easy, sshc: *ssh_conn) CURLcode {
    _ = data;
    _ = sshc;
    return CURLE_OK;
}

fn ssh_EndOfResp(line: [*:0]const u8, target: [*:0]const u8) bool {
    const line_slice = std.mem.span(line);
    const target_slice = std.mem.span(target);
    if (std.mem.indexOf(u8, line_slice, target_slice)) |idx| {
        const before_ok = (idx == 0) or (line_slice[idx - 1] == ',');
        const after_idx = idx + target_slice.len;
        const after_ok = (after_idx == line_slice.len) or (line_slice[after_idx] == ',');
        return before_ok and after_ok;
    }
    return false;
}

fn ssh_statemach_act(data: *Curl_easy, sshc: *ssh_conn, sshp: *SSHPROTO, block: *bool) CURLcode {
    var result: CURLcode = CURLE_OK;
    const conn = Curl_ftp_acc_get_conn(data) orelse return CURLE_FAILED_INIT;
    var rc: c_int = 0;
    block.* = false;

    while (true) {
        switch (sshc.state) {
            .SSH_INIT => {
                sshc.secondCreateDirs = 0;
                sshc.nextstate = .SSH_NO_STATE;
                sshc.actualcode = CURLE_OK;
                if (sshc.ssh_session) |sess| {
                    libssh2_session_set_blocking(sess, 0);
                }
                result = ssh_force_knownhost_key_type(data, sshc);
                if (result != CURLE_OK) {
                    ssh_state(data, sshc, .SSH_SESSION_FREE);
                    break;
                }
                ssh_state(data, sshc, .SSH_S_STARTUP);
            },

            .SSH_S_STARTUP => {
                const session = sshc.ssh_session orelse return CURLE_FAILED_INIT;
                rc = libssh2_session_handshake(session, Curl_vssh_get_conn_firstsocket(conn));
                if (rc == LIBSSH2_ERROR_EAGAIN) {
                    break;
                }
                if (rc != 0) {
                    var err_msg: ?[*:0]u8 = null;
                    _ = libssh2_session_last_error(session, &err_msg, null, 0);
                    Curl_failf(data, "Failure establishing ssh session: %d, %s", rc, err_msg orelse "unknown");
                    ssh_state(data, sshc, .SSH_SESSION_FREE);
                    sshc.actualcode = CURLE_SSH;
                    break;
                }
                ssh_state(data, sshc, .SSH_HOSTKEY);
            },

            .SSH_HOSTKEY => {
                result = ssh_check_fingerprint(data, sshc);
                if (result != CURLE_OK) {
                    sshc.actualcode = result;
                } else {
                    ssh_state(data, sshc, .SSH_AUTHLIST);
                }
            },

            .SSH_AUTHLIST => {
                sshc.authed = false;
                const session = sshc.ssh_session orelse return CURLE_FAILED_INIT;
                const user = Curl_vssh_get_conn_user(conn) orelse "";
                sshc.authlist = libssh2_userauth_list(session, user, @intCast(std.mem.len(user)));
                if (sshc.authlist == null) {
                    if (libssh2_userauth_authenticated(session) != 0) {
                        sshc.authed = true;
                        Curl_infof(data, "SSH user accepted with no authentication");
                        ssh_state(data, sshc, .SSH_AUTH_DONE);
                        break;
                    }
                    const err = libssh2_session_last_errno(session);
                    if (err == LIBSSH2_ERROR_EAGAIN) {
                        rc = LIBSSH2_ERROR_EAGAIN;
                    } else {
                        ssh_state(data, sshc, .SSH_SESSION_FREE);
                        sshc.actualcode = session_error_to_CURLE(err);
                    }
                    break;
                }
                Curl_infof(data, "SSH authentication methods available: %s", sshc.authlist.?);
                ssh_state(data, sshc, .SSH_AUTH_PKEY_INIT);
            },

            .SSH_AUTH_PKEY_INIT => {
                sshc.rsa_pub = null;
                sshc.rsa = null;
                const auth_types: u32 = @intCast(Curl_setopt_get_i64(data, 54));
                const authlist = sshc.authlist orelse "";
                if ((auth_types & CURLSSH_AUTH_PUBLICKEY) != 0 and ssh_EndOfResp(authlist, "publickey")) {
                    var out_of_memory = false;
                    sshc.rsa_pub = null;
                    sshc.rsa = null;

                    if (easyStrGet(data, setopt.STRING_SSH_PRIVATE_KEY)) |priv| {
                        sshc.rsa = mem.strdup(priv);
                        if (sshc.rsa == null) out_of_memory = true;
                    } else {
                        const home = os_leaf.curl_getenv("HOME");
                        defer if (home) |h| mem.freeSecretZ(h);
                        if (home) |h| {
                            sshc.rsa = curl_maprintf("%s/.ssh/id_rsa", h);
                            if (sshc.rsa == null) {
                                out_of_memory = true;
                            } else if (std.c.access(sshc.rsa.?, 0) != 0) {
                                mem.freeSecretZ(sshc.rsa);
                                sshc.rsa = curl_maprintf("%s/.ssh/id_dsa", h);
                                if (sshc.rsa == null) {
                                    out_of_memory = true;
                                } else if (std.c.access(sshc.rsa.?, 0) != 0) {
                                    mem.freeSecretZ(sshc.rsa);
                                    sshc.rsa = null;
                                }
                            }
                        }
                        if (!out_of_memory and sshc.rsa == null) {
                            sshc.rsa = mem.strdup("id_rsa");
                            if (sshc.rsa != null and std.c.access(sshc.rsa.?, 0) != 0) {
                                mem.freeSecretZ(sshc.rsa);
                                sshc.rsa = mem.strdup("id_dsa");
                                if (sshc.rsa != null and std.c.access(sshc.rsa.?, 0) != 0) {
                                    mem.freeSecretZ(sshc.rsa);
                                    sshc.rsa = mem.strdup("");
                                }
                            }
                        }
                    }

                    if (easyStrGet(data, setopt.STRING_SSH_PUBLIC_KEY)) |pubk| {
                        if (pubk[0] != 0) {
                            sshc.rsa_pub = mem.strdup(pubk);
                            if (sshc.rsa_pub == null) out_of_memory = true;
                        }
                    }

                    if (out_of_memory or sshc.rsa == null) {
                        if (sshc.rsa) |r| mem.freeSecretZ(r);
                        if (sshc.rsa_pub) |rp| mem.freeSecretZ(rp);
                        sshc.rsa = null;
                        sshc.rsa_pub = null;
                        ssh_state(data, sshc, .SSH_SESSION_FREE);
                        sshc.actualcode = CURLE_OUT_OF_MEMORY;
                        break;
                    }

                    sshc.passphrase = easyStrGet(data, setopt.STRING_KEY_PASSWD) orelse "";
                    ssh_state(data, sshc, .SSH_AUTH_PKEY);
                } else {
                    ssh_state(data, sshc, .SSH_AUTH_PASS_INIT);
                }
            },

            .SSH_AUTH_PKEY => {
                const session = sshc.ssh_session orelse return CURLE_FAILED_INIT;
                const user = Curl_vssh_get_conn_user(conn) orelse "";
                rc = libssh2_userauth_publickey_fromfile_ex(
                    session,
                    user,
                    @intCast(std.mem.len(user)),
                    sshc.rsa_pub,
                    sshc.rsa.?,
                    sshc.passphrase,
                );
                if (rc == LIBSSH2_ERROR_EAGAIN) {
                    break;
                }
                if (sshc.rsa) |r| mem.freeSecretZ(r);
                if (sshc.rsa_pub) |rp| mem.freeSecretZ(rp);
                sshc.rsa = null;
                sshc.rsa_pub = null;

                if (rc == 0) {
                    sshc.authed = true;
                    Curl_infof(data, "Initialized SSH public key authentication");
                    ssh_state(data, sshc, .SSH_AUTH_DONE);
                } else {
                    var err_msg: ?[*:0]u8 = null;
                    _ = libssh2_session_last_error(session, &err_msg, null, 0);
                    Curl_infof(data, "SSH public key authentication failed: %s", err_msg orelse "unknown");
                    ssh_state(data, sshc, .SSH_AUTH_PASS_INIT);
                    rc = 0;
                }
            },

            .SSH_AUTH_PASS_INIT => {
                const auth_types: u32 = @intCast(Curl_setopt_get_i64(data, 54));
                const authlist = sshc.authlist orelse "";
                if ((auth_types & CURLSSH_AUTH_PASSWORD) != 0 and ssh_EndOfResp(authlist, "password")) {
                    ssh_state(data, sshc, .SSH_AUTH_PASS);
                } else {
                    ssh_state(data, sshc, .SSH_AUTH_HOST_INIT);
                }
            },

            .SSH_AUTH_PASS => {
                const session = sshc.ssh_session orelse return CURLE_FAILED_INIT;
                const user = Curl_vssh_get_conn_user(conn) orelse "";
                const passwd = Curl_vssh_get_conn_passwd(conn) orelse "";
                rc = libssh2_userauth_password_ex(
                    session,
                    user,
                    @intCast(std.mem.len(user)),
                    passwd,
                    @intCast(std.mem.len(passwd)),
                    null,
                );
                if (rc == LIBSSH2_ERROR_EAGAIN) {
                    break;
                }
                if (rc == 0) {
                    sshc.authed = true;
                    Curl_infof(data, "Initialized password authentication");
                    ssh_state(data, sshc, .SSH_AUTH_DONE);
                } else {
                    ssh_state(data, sshc, .SSH_AUTH_HOST_INIT);
                    rc = 0;
                }
            },

            .SSH_AUTH_HOST_INIT => {
                const auth_types: u32 = @intCast(Curl_setopt_get_i64(data, 54));
                const authlist = sshc.authlist orelse "";
                if ((auth_types & CURLSSH_AUTH_HOST) != 0 and ssh_EndOfResp(authlist, "hostbased")) {
                    ssh_state(data, sshc, .SSH_AUTH_HOST);
                } else {
                    ssh_state(data, sshc, .SSH_AUTH_AGENT_INIT);
                }
            },

            .SSH_AUTH_HOST => {
                ssh_state(data, sshc, .SSH_AUTH_AGENT_INIT);
            },

            .SSH_AUTH_AGENT_INIT => {
                const auth_types: u32 = @intCast(Curl_setopt_get_i64(data, 54));
                const authlist = sshc.authlist orelse "";
                if ((auth_types & CURLSSH_AUTH_AGENT) != 0 and ssh_EndOfResp(authlist, "publickey")) {
                    const session = sshc.ssh_session orelse return CURLE_FAILED_INIT;
                    if (sshc.ssh_agent == null) {
                        sshc.ssh_agent = libssh2_agent_init(session);
                        if (sshc.ssh_agent == null) {
                            Curl_infof(data, "Could not create agent object");
                            ssh_state(data, sshc, .SSH_AUTH_KEY_INIT);
                            break;
                        }
                    }
                    rc = libssh2_agent_connect(sshc.ssh_agent.?);
                    if (rc == LIBSSH2_ERROR_EAGAIN) {
                        break;
                    }
                    if (rc < 0) {
                        Curl_infof(data, "Failure connecting to agent");
                        ssh_state(data, sshc, .SSH_AUTH_KEY_INIT);
                        rc = 0;
                    } else {
                        ssh_state(data, sshc, .SSH_AUTH_AGENT_LIST);
                    }
                } else {
                    ssh_state(data, sshc, .SSH_AUTH_KEY_INIT);
                }
            },

            .SSH_AUTH_AGENT_LIST => {
                rc = libssh2_agent_list_identities(sshc.ssh_agent.?);
                if (rc == LIBSSH2_ERROR_EAGAIN) {
                    break;
                }
                if (rc < 0) {
                    Curl_infof(data, "Failure requesting identities to agent");
                    ssh_state(data, sshc, .SSH_AUTH_KEY_INIT);
                    rc = 0;
                } else {
                    ssh_state(data, sshc, .SSH_AUTH_AGENT);
                    sshc.sshagent_prev_identity = null;
                }
            },

            .SSH_AUTH_AGENT => {
                rc = libssh2_agent_get_identity(
                    sshc.ssh_agent.?,
                    &sshc.sshagent_identity,
                    sshc.sshagent_prev_identity,
                );
                if (rc == LIBSSH2_ERROR_EAGAIN) {
                    break;
                }
                if (rc == 0) {
                    const user = Curl_vssh_get_conn_user(conn) orelse "";
                    rc = libssh2_agent_userauth(
                        sshc.ssh_agent.?,
                        user,
                        sshc.sshagent_identity.?,
                    );
                    if (rc < 0) {
                        if (rc != LIBSSH2_ERROR_EAGAIN) {
                            sshc.sshagent_prev_identity = sshc.sshagent_identity;
                            continue;
                        }
                        break;
                    }
                }
                if (rc == 0) {
                    sshc.authed = true;
                    Curl_infof(data, "SSH agent authentication succeeded");
                    ssh_state(data, sshc, .SSH_AUTH_DONE);
                } else {
                    Curl_infof(data, "Failure authenticating with agent");
                    ssh_state(data, sshc, .SSH_AUTH_KEY_INIT);
                    rc = 0;
                }
            },

            .SSH_AUTH_KEY_INIT => {
                const auth_types: u32 = @intCast(Curl_setopt_get_i64(data, 54));
                const authlist = sshc.authlist orelse "";
                if ((auth_types & CURLSSH_AUTH_KEYBOARD) != 0 and ssh_EndOfResp(authlist, "keyboard-interactive")) {
                    ssh_state(data, sshc, .SSH_AUTH_KEY);
                } else {
                    ssh_state(data, sshc, .SSH_AUTH_DONE);
                }
            },

            .SSH_AUTH_KEY => {
                const session = sshc.ssh_session orelse return CURLE_FAILED_INIT;
                const user = Curl_vssh_get_conn_user(conn) orelse "";
                rc = libssh2_userauth_keyboard_interactive_ex(
                    session,
                    user,
                    @intCast(std.mem.len(user)),
                    @ptrCast(&kbd_callback),
                );
                if (rc == LIBSSH2_ERROR_EAGAIN) {
                    break;
                }
                if (rc == 0) {
                    sshc.authed = true;
                    Curl_infof(data, "Initialized keyboard interactive authentication");
                }
                ssh_state(data, sshc, .SSH_AUTH_DONE);
            },

            .SSH_AUTH_DONE => {
                if (!sshc.authed) {
                    Curl_failf(data, "Authentication failure");
                    ssh_state(data, sshc, .SSH_SESSION_FREE);
                    sshc.actualcode = CURLE_LOGIN_DENIED;
                    break;
                }
                Curl_infof(data, "SSH CONNECT phase done");
                ssh_state(data, sshc, .SSH_STOP);
            },

            .SSH_SFTP_INIT => {
                const session = sshc.ssh_session orelse return CURLE_FAILED_INIT;
                sshc.sftp_session = libssh2_sftp_init(session);
                if (sshc.sftp_session == null) {
                    if (libssh2_session_last_errno(session) == LIBSSH2_ERROR_EAGAIN) {
                        rc = LIBSSH2_ERROR_EAGAIN;
                        break;
                    }
                    var err_msg: ?[*:0]u8 = null;
                    _ = libssh2_session_last_error(session, &err_msg, null, 0);
                    Curl_failf(data, "Failure initializing sftp session: %s", err_msg orelse "unknown");
                    ssh_state(data, sshc, .SSH_SESSION_FREE);
                    sshc.actualcode = CURLE_SSH;
                    break;
                }
                ssh_state(data, sshc, .SSH_SFTP_REALPATH);
            },

            .SSH_SFTP_REALPATH => {
                var tempHome: [DYN_PATH_MAX]u8 = undefined;
                rc = libssh2_sftp_symlink_ex(
                    sshc.sftp_session.?,
                    ".",
                    1,
                    &tempHome,
                    @intCast(tempHome.len - 1),
                    LIBSSH2_SFTP_REALPATH,
                );
                if (rc == LIBSSH2_ERROR_EAGAIN) {
                    break;
                }
                if (rc > 0) {
                    tempHome[@intCast(rc)] = 0;
                    sshc.homedir = mem.strdup(@ptrCast(&tempHome));
                    if (sshc.homedir == null) {
                        ssh_state(data, sshc, .SSH_SFTP_SHUTDOWN);
                        sshc.actualcode = CURLE_OUT_OF_MEMORY;
                        break;
                    }
                } else {
                    const err = sftp_libssh2_last_error(sshc.sftp_session);
                    if (err != 0) {
                        result = sftpErrorToCurle(err);
                        sshc.actualcode = if (result != CURLE_OK) result else CURLE_SSH;
                        ssh_state(data, sshc, .SSH_SFTP_SHUTDOWN);
                        break;
                    }
                    sshc.homedir = mem.strdup(".");
                    if (sshc.homedir == null) {
                        ssh_state(data, sshc, .SSH_SFTP_SHUTDOWN);
                        sshc.actualcode = CURLE_OUT_OF_MEMORY;
                        break;
                    }
                }
                ssh_state(data, sshc, .SSH_STOP);
            },

            .SSH_SFTP_QUOTE_INIT => {
                result = Curl_getworkingpath(data, sshc.homedir orelse ".", &sshp.path);
                if (result != CURLE_OK) {
                    sshc.actualcode = result;
                    ssh_state(data, sshc, .SSH_STOP);
                    break;
                }
                if (Curl_ftp_acc_get_quote(data)) |q| {
                    sshc.quote_item = q;
                    ssh_state(data, sshc, .SSH_SFTP_QUOTE);
                } else {
                    ssh_state(data, sshc, .SSH_SFTP_GETINFO);
                }
            },

            .SSH_SFTP_POSTQUOTE_INIT => {
                if (Curl_ftp_acc_get_postquote(data)) |pq| {
                    sshc.quote_item = pq;
                    ssh_state(data, sshc, .SSH_SFTP_QUOTE);
                } else {
                    ssh_state(data, sshc, .SSH_STOP);
                }
            },

            .SSH_SFTP_QUOTE => {
                const qi = sshc.quote_item orelse {
                    ssh_state(data, sshc, .SSH_SFTP_GETINFO);
                    continue;
                };
                var cp: [*:0]const u8 = qi.data orelse "";
                if (cp[0] == '*') {
                    cp += 1;
                    sshc.acceptfail = true;
                } else {
                    sshc.acceptfail = false;
                }
                cp = Curl_quote_line(cp);

                var cmd_end: usize = 0;
                while (cp[cmd_end] != 0 and cp[cmd_end] != ' ' and cp[cmd_end] != '\t') : (cmd_end += 1) {}
                const cmd = cp[0..cmd_end];
                var arg_raw: [*:0]const u8 = cp + cmd_end;
                curlx_str_passblanks(&arg_raw);
                var arg_ptr: ?[*:0]const u8 = arg_raw;

                if (std.ascii.eqlIgnoreCase(cmd, "pwd")) {
                    const header = curl_maprintf("257 \"%s\" is current directory.\n", sshp.path orelse "/");
                    if (header == null) {
                        sshc.actualcode = CURLE_OUT_OF_MEMORY;
                        ssh_state(data, sshc, .SSH_SFTP_SHUTDOWN);
                        break;
                    }
                    defer mem.free(header);
                    result = sendf.Curl_client_write(@ptrCast(data), CLIENTWRITE_HEADER, header.?, std.mem.len(header.?));
                    if (result != CURLE_OK) {
                        sshc.actualcode = result;
                        ssh_state(data, sshc, .SSH_SFTP_SHUTDOWN);
                        break;
                    }
                    ssh_state(data, sshc, .SSH_SFTP_NEXT_QUOTE);
                    continue;
                }

                const homedir = sshc.homedir orelse ".";
                const is_stat_cmd = std.ascii.eqlIgnoreCase(cmd, "chgrp") or
                    std.ascii.eqlIgnoreCase(cmd, "chmod") or
                    std.ascii.eqlIgnoreCase(cmd, "chown") or
                    std.ascii.eqlIgnoreCase(cmd, "atime") or
                    std.ascii.eqlIgnoreCase(cmd, "mtime");
                const is_symlink_cmd = std.ascii.eqlIgnoreCase(cmd, "ln") or std.ascii.eqlIgnoreCase(cmd, "symlink");
                const is_rename_cmd = std.ascii.eqlIgnoreCase(cmd, "rename");
                const is_mkdir_cmd = std.ascii.eqlIgnoreCase(cmd, "mkdir");
                const is_rmdir_cmd = std.ascii.eqlIgnoreCase(cmd, "rmdir");
                const is_rm_cmd = std.ascii.eqlIgnoreCase(cmd, "rm");
                const is_statvfs_cmd = std.ascii.eqlIgnoreCase(cmd, "statvfs");
                const need_second = is_stat_cmd or is_symlink_cmd or is_rename_cmd;

                allocSftpQuotePaths(&arg_ptr, homedir, need_second, &sshc.quote_path1, &sshc.quote_path2) catch |err| {
                    result = if (err == error.OutOfMemory) CURLE_OUT_OF_MEMORY else CURLE_QUOTE_ERROR;
                    if (result != CURLE_OUT_OF_MEMORY) {
                        if (is_stat_cmd) {
                            Curl_failf(data, "Syntax error in %.*s: Bad parameter", @as(c_int, @intCast(cmd.len)), cmd.ptr);
                        } else if (!need_second) {
                            Curl_failf(data, "Syntax error: Bad first parameter to '%.*s'", @as(c_int, @intCast(cmd.len)), cmd.ptr);
                        }
                    }
                    sshc.actualcode = result;
                    ssh_state(data, sshc, .SSH_SFTP_SHUTDOWN);
                    break;
                };

                if (is_stat_cmd) {
                    sshc.quote_attrs = std.mem.zeroes(LIBSSH2_SFTP_ATTRIBUTES);
                    ssh_state(data, sshc, .SSH_SFTP_QUOTE_STAT);
                } else if (is_symlink_cmd) {
                    ssh_state(data, sshc, .SSH_SFTP_QUOTE_SYMLINK);
                } else if (is_mkdir_cmd) {
                    ssh_state(data, sshc, .SSH_SFTP_QUOTE_MKDIR);
                } else if (is_rename_cmd) {
                    ssh_state(data, sshc, .SSH_SFTP_QUOTE_RENAME);
                } else if (is_rmdir_cmd) {
                    ssh_state(data, sshc, .SSH_SFTP_QUOTE_RMDIR);
                } else if (is_rm_cmd) {
                    ssh_state(data, sshc, .SSH_SFTP_QUOTE_UNLINK);
                } else if (is_statvfs_cmd) {
                    ssh_state(data, sshc, .SSH_SFTP_QUOTE_STATVFS);
                } else {
                    Curl_failf(data, "Unknown SFTP command");
                    if (sshc.quote_path1) |p1| mem.free(p1);
                    if (sshc.quote_path2) |p2| mem.free(p2);
                    sshc.quote_path1 = null;
                    sshc.quote_path2 = null;
                    sshc.actualcode = CURLE_QUOTE_ERROR;
                    ssh_state(data, sshc, .SSH_SFTP_SHUTDOWN);
                    break;
                }
            },

            .SSH_SFTP_NEXT_QUOTE => {
                if (sshc.quote_path1) |p1| mem.free(p1);
                if (sshc.quote_path2) |p2| mem.free(p2);
                sshc.quote_path1 = null;
                sshc.quote_path2 = null;

                sshc.quote_item = if (sshc.quote_item) |qi| qi.next else null;
                if (sshc.quote_item != null) {
                    ssh_state(data, sshc, .SSH_SFTP_QUOTE);
                } else {
                    if (sshc.nextstate != .SSH_NO_STATE) {
                        ssh_state(data, sshc, sshc.nextstate);
                        sshc.nextstate = .SSH_NO_STATE;
                    } else {
                        ssh_state(data, sshc, .SSH_SFTP_GETINFO);
                    }
                }
            },

            .SSH_SFTP_QUOTE_STAT => {
                const p2 = sshc.quote_path2 orelse "";
                rc = libssh2_sftp_stat_ex(
                    sshc.sftp_session.?,
                    p2,
                    @intCast(std.mem.len(p2)),
                    LIBSSH2_SFTP_LSTAT,
                    &sshc.quote_attrs,
                );
                if (rc == LIBSSH2_ERROR_EAGAIN) {
                    break;
                }
                if (rc != 0 and !sshc.acceptfail) {
                    const err = sftp_libssh2_last_error(sshc.sftp_session);
                    Curl_failf(data, "Attempt tofull stat on %s failed: %s", p2, sftpLibssh2Strerror(err));
                    sshc.actualcode = CURLE_QUOTE_ERROR;
                    ssh_state(data, sshc, .SSH_SFTP_SHUTDOWN);
                    break;
                }

                const qi = sshc.quote_item.?;
                var cp: [*:0]const u8 = qi.data orelse "";
                if (cp[0] == '*') cp += 1;
                cp = Curl_quote_line(cp);
                const p1 = sshc.quote_path1 orelse "";
                var p1_cur: [*:0]const u8 = p1;

                if (primitives.curl_strnequal(cp, "chgrp", 5) != 0) {
                    var gid: i64 = 0;
                    if (curlx_str_number(&p1_cur, &gid, @min(std.math.maxInt(c_ulong), std.math.maxInt(i64))) != curlx_parse.STRE_OK) {
                        if (!sshc.acceptfail) {
                            sshc.actualcode = CURLE_QUOTE_ERROR;
                            ssh_state(data, sshc, .SSH_SFTP_SHUTDOWN);
                            break;
                        }
                    }
                    sshc.quote_attrs.gid = @intCast(gid);
                    sshc.quote_attrs.flags |= LIBSSH2_SFTP_ATTR_UIDGID;
                } else if (primitives.curl_strnequal(cp, "chmod", 5) != 0) {
                    var perms: i64 = 0;
                    if (curlx_str_octal(&p1_cur, &perms, 0o7777) != curlx_parse.STRE_OK) {
                        if (!sshc.acceptfail) {
                            sshc.actualcode = CURLE_QUOTE_ERROR;
                            ssh_state(data, sshc, .SSH_SFTP_SHUTDOWN);
                            break;
                        }
                    }
                    sshc.quote_attrs.permissions &= ~@as(c_ulong, 0o7777);
                    sshc.quote_attrs.permissions |= @intCast(perms);
                    sshc.quote_attrs.flags |= LIBSSH2_SFTP_ATTR_PERMISSIONS;
                } else if (primitives.curl_strnequal(cp, "chown", 5) != 0) {
                    var uid: i64 = 0;
                    if (curlx_str_number(&p1_cur, &uid, @min(std.math.maxInt(c_ulong), std.math.maxInt(i64))) != curlx_parse.STRE_OK) {
                        if (!sshc.acceptfail) {
                            sshc.actualcode = CURLE_QUOTE_ERROR;
                            ssh_state(data, sshc, .SSH_SFTP_SHUTDOWN);
                            break;
                        }
                    }
                    sshc.quote_attrs.uid = @intCast(uid);
                    sshc.quote_attrs.flags |= LIBSSH2_SFTP_ATTR_UIDGID;
                } else if (primitives.curl_strnequal(cp, "atime", 5) != 0 or
                    primitives.curl_strnequal(cp, "mtime", 5) != 0)
                {
                    const date = curl_getdate(p1, null);
                    if (date == -1) {
                        if (!sshc.acceptfail) {
                            sshc.actualcode = CURLE_QUOTE_ERROR;
                            ssh_state(data, sshc, .SSH_SFTP_SHUTDOWN);
                            break;
                        }
                    }
                    if (primitives.curl_strnequal(cp, "atime", 5) != 0) {
                        sshc.quote_attrs.atime = @intCast(date);
                    } else {
                        sshc.quote_attrs.mtime = @intCast(date);
                    }
                    sshc.quote_attrs.flags |= LIBSSH2_SFTP_ATTR_ACMODTIME;
                }
                ssh_state(data, sshc, .SSH_SFTP_QUOTE_SETSTAT);
            },

            .SSH_SFTP_QUOTE_SETSTAT => {
                const p2 = sshc.quote_path2 orelse "";
                rc = libssh2_sftp_stat_ex(
                    sshc.sftp_session.?,
                    p2,
                    @intCast(std.mem.len(p2)),
                    LIBSSH2_SFTP_SETSTAT,
                    &sshc.quote_attrs,
                );
                if (rc == LIBSSH2_ERROR_EAGAIN) {
                    break;
                }
                if (rc != 0 and !sshc.acceptfail) {
                    sshc.actualcode = CURLE_QUOTE_ERROR;
                    ssh_state(data, sshc, .SSH_SFTP_SHUTDOWN);
                    break;
                }
                ssh_state(data, sshc, .SSH_SFTP_NEXT_QUOTE);
            },

            .SSH_SFTP_QUOTE_SYMLINK => {
                const p1 = sshc.quote_path1 orelse "";
                const p2 = sshc.quote_path2 orelse "";
                rc = libssh2_sftp_symlink_ex(
                    sshc.sftp_session.?,
                    p1,
                    @intCast(std.mem.len(p1)),
                    @constCast(p2),
                    @intCast(std.mem.len(p2)),
                    LIBSSH2_SFTP_SYMLINK,
                );
                if (rc == LIBSSH2_ERROR_EAGAIN) {
                    break;
                }
                if (rc != 0 and !sshc.acceptfail) {
                    sshc.actualcode = CURLE_QUOTE_ERROR;
                    ssh_state(data, sshc, .SSH_SFTP_SHUTDOWN);
                    break;
                }
                ssh_state(data, sshc, .SSH_SFTP_NEXT_QUOTE);
            },

            .SSH_SFTP_QUOTE_MKDIR => {
                const p1 = sshc.quote_path1 orelse "";
                const dir_perms: c_long = @intCast(Curl_setopt_get_i64(data, 55));
                rc = libssh2_sftp_mkdir_ex(
                    sshc.sftp_session.?,
                    p1,
                    @intCast(std.mem.len(p1)),
                    dir_perms,
                );
                if (rc == LIBSSH2_ERROR_EAGAIN) {
                    break;
                }
                if (rc != 0 and !sshc.acceptfail) {
                    sshc.actualcode = CURLE_QUOTE_ERROR;
                    ssh_state(data, sshc, .SSH_SFTP_SHUTDOWN);
                    break;
                }
                ssh_state(data, sshc, .SSH_SFTP_NEXT_QUOTE);
            },

            .SSH_SFTP_QUOTE_RENAME => {
                const p1 = sshc.quote_path1 orelse "";
                const p2 = sshc.quote_path2 orelse "";
                rc = libssh2_sftp_rename_ex(
                    sshc.sftp_session.?,
                    p1,
                    @intCast(std.mem.len(p1)),
                    p2,
                    @intCast(std.mem.len(p2)),
                    LIBSSH2_SFTP_RENAME_OVERWRITE | LIBSSH2_SFTP_RENAME_ATOMIC | LIBSSH2_SFTP_RENAME_NATIVE,
                );
                if (rc == LIBSSH2_ERROR_EAGAIN) {
                    break;
                }
                if (rc != 0 and !sshc.acceptfail) {
                    sshc.actualcode = CURLE_QUOTE_ERROR;
                    ssh_state(data, sshc, .SSH_SFTP_SHUTDOWN);
                    break;
                }
                ssh_state(data, sshc, .SSH_SFTP_NEXT_QUOTE);
            },

            .SSH_SFTP_QUOTE_RMDIR => {
                const p1 = sshc.quote_path1 orelse "";
                rc = libssh2_sftp_rmdir_ex(
                    sshc.sftp_session.?,
                    p1,
                    @intCast(std.mem.len(p1)),
                );
                if (rc == LIBSSH2_ERROR_EAGAIN) {
                    break;
                }
                if (rc != 0 and !sshc.acceptfail) {
                    sshc.actualcode = CURLE_QUOTE_ERROR;
                    ssh_state(data, sshc, .SSH_SFTP_SHUTDOWN);
                    break;
                }
                ssh_state(data, sshc, .SSH_SFTP_NEXT_QUOTE);
            },

            .SSH_SFTP_QUOTE_UNLINK => {
                const p1 = sshc.quote_path1 orelse "";
                rc = libssh2_sftp_unlink_ex(
                    sshc.sftp_session.?,
                    p1,
                    @intCast(std.mem.len(p1)),
                );
                if (rc == LIBSSH2_ERROR_EAGAIN) {
                    break;
                }
                if (rc != 0 and !sshc.acceptfail) {
                    sshc.actualcode = CURLE_QUOTE_ERROR;
                    ssh_state(data, sshc, .SSH_SFTP_SHUTDOWN);
                    break;
                }
                ssh_state(data, sshc, .SSH_SFTP_NEXT_QUOTE);
            },

            .SSH_SFTP_QUOTE_STATVFS => {
                const p1 = sshc.quote_path1 orelse "";
                var statvfs: LIBSSH2_SFTP_STATVFS = std.mem.zeroes(LIBSSH2_SFTP_STATVFS);
                rc = libssh2_sftp_statvfs(
                    sshc.sftp_session.?,
                    p1,
                    std.mem.len(p1),
                    &statvfs,
                );
                if (rc == LIBSSH2_ERROR_EAGAIN) {
                    break;
                }
                if (rc != 0 and !sshc.acceptfail) {
                    sshc.actualcode = CURLE_QUOTE_ERROR;
                    ssh_state(data, sshc, .SSH_SFTP_SHUTDOWN);
                    break;
                } else if (rc == 0) {
                    const tmp = curl_maprintf(
                        "statvfs:\n" ++
                            "f_bsize: %llu\n" ++
                            "f_frsize: %llu\n" ++
                            "f_blocks: %llu\n" ++
                            "f_bfree: %llu\n" ++
                            "f_bavail: %llu\n" ++
                            "f_files: %llu\n" ++
                            "f_ffree: %llu\n" ++
                            "f_favail: %llu\n" ++
                            "f_fsid: %llu\n" ++
                            "f_flag: %s%s\n" ++
                            "f_namemax: %llu\n",
                        statvfs.f_bsize,
                        statvfs.f_frsize,
                        statvfs.f_blocks,
                        statvfs.f_bfree,
                        statvfs.f_bavail,
                        statvfs.f_files,
                        statvfs.f_ffree,
                        statvfs.f_favail,
                        statvfs.f_fsid,
                        @as([*:0]const u8, if ((statvfs.f_flag & LIBSSH2_ST_RDONLY) != 0) "ST_RDONLY " else ""),
                        @as([*:0]const u8, if ((statvfs.f_flag & LIBSSH2_ST_NOSUID) != 0) "ST_NOSUID" else ""),
                        statvfs.f_namemax,
                    );
                    if (tmp == null) {
                        sshc.actualcode = CURLE_OUT_OF_MEMORY;
                        ssh_state(data, sshc, .SSH_SFTP_SHUTDOWN);
                        break;
                    }
                    defer mem.free(tmp);
                    result = sendf.Curl_client_write(@ptrCast(data), CLIENTWRITE_HEADER, tmp.?, std.mem.len(tmp.?));
                    if (result != CURLE_OK) {
                        sshc.actualcode = result;
                        ssh_state(data, sshc, .SSH_SFTP_SHUTDOWN);
                        break;
                    }
                }
                ssh_state(data, sshc, .SSH_SFTP_NEXT_QUOTE);
            },

            .SSH_SFTP_GETINFO => {
                if (Curl_ftp_acc_get_get_filetime(data)) {
                    ssh_state(data, sshc, .SSH_SFTP_FILETIME);
                } else {
                    ssh_state(data, sshc, .SSH_SFTP_TRANS_INIT);
                }
            },

            .SSH_SFTP_FILETIME => {
                var attrs: LIBSSH2_SFTP_ATTRIBUTES = std.mem.zeroes(LIBSSH2_SFTP_ATTRIBUTES);
                const path = sshp.path orelse "";
                rc = libssh2_sftp_stat_ex(
                    sshc.sftp_session.?,
                    path,
                    @intCast(std.mem.len(path)),
                    LIBSSH2_SFTP_STAT,
                    &attrs,
                );
                if (rc == LIBSSH2_ERROR_EAGAIN) {
                    break;
                }
                if (rc == 0) {
                    Curl_vssh_set_info_filetime(data, @intCast(attrs.mtime));
                }
                ssh_state(data, sshc, .SSH_SFTP_TRANS_INIT);
            },

            .SSH_SFTP_TRANS_INIT => {
                if (Curl_ftp_acc_get_upload(data)) {
                    ssh_state(data, sshc, .SSH_SFTP_UPLOAD_INIT);
                } else {
                    const path = sshp.path orelse "";
                    const plen = std.mem.len(path);
                    if (plen > 0 and path[plen - 1] == '/') {
                        ssh_state(data, sshc, .SSH_SFTP_READDIR_INIT);
                    } else {
                        ssh_state(data, sshc, .SSH_SFTP_DOWNLOAD_INIT);
                    }
                }
            },

            .SSH_SFTP_UPLOAD_INIT => {
                var flags: c_ulong = 0;
                const resume_from = Curl_ftp_acc_get_resume_from(data);
                if (resume_from != 0) {
                    var attrs: LIBSSH2_SFTP_ATTRIBUTES = std.mem.zeroes(LIBSSH2_SFTP_ATTRIBUTES);
                    if (resume_from < 0) {
                        const path = sshp.path orelse "";
                        rc = libssh2_sftp_stat_ex(
                            sshc.sftp_session.?,
                            path,
                            @intCast(std.mem.len(path)),
                            LIBSSH2_SFTP_STAT,
                            &attrs,
                        );
                        if (rc == LIBSSH2_ERROR_EAGAIN) {
                            break;
                        }
                        if (rc != 0) {
                            Curl_ftp_acc_set_resume_from(data, 0);
                        } else {
                            const size: curl_off_t = @intCast(attrs.filesize);
                            if (size < 0) {
                                Curl_failf(data, "Bad file size (%" ++ "lld" ++ ")", size);
                                sshc.actualcode = CURLE_BAD_FUNCTION_ARGUMENT;
                                ssh_state(data, sshc, .SSH_SFTP_SHUTDOWN);
                                break;
                            }
                            Curl_ftp_acc_set_resume_from(data, size);
                        }
                    }
                }

                if (Curl_ftp_acc_get_remote_append(data)) {
                    flags = LIBSSH2_FXF_WRITE | LIBSSH2_FXF_CREAT | LIBSSH2_FXF_APPEND;
                } else if (Curl_ftp_acc_get_resume_from(data) > 0) {
                    flags = LIBSSH2_FXF_WRITE | LIBSSH2_FXF_APPEND;
                } else {
                    flags = LIBSSH2_FXF_WRITE | LIBSSH2_FXF_CREAT | LIBSSH2_FXF_TRUNC;
                }

                const path = sshp.path orelse "";
                const file_perms: c_long = @intCast(Curl_setopt_get_i64(data, 51));
                sshc.sftp_handle = libssh2_sftp_open_ex(
                    sshc.sftp_session.?,
                    path,
                    @intCast(std.mem.len(path)),
                    flags,
                    file_perms,
                    LIBSSH2_SFTP_OPENFILE,
                );
                if (sshc.sftp_handle == null) {
                    rc = libssh2_session_last_errno(sshc.ssh_session.?);
                    if (LIBSSH2_ERROR_EAGAIN == rc) {
                        break;
                    }
                    if (LIBSSH2_ERROR_SFTP_PROTOCOL == rc) {
                        const sftperr = sftp_libssh2_last_error(sshc.sftp_session);
                        const create_dirs = Curl_ftp_acc_get_ftp_create_missing_dirs(data);
                        if ((create_dirs == CURLFTP_CREATE_DIR or create_dirs == CURLFTP_CREATE_DIR_RETRY) and
                            sshc.secondCreateDirs == 0 and
                            (sftperr == LIBSSH2_FX_NO_SUCH_FILE or
                                sftperr == LIBSSH2_FX_FAILURE or
                                sftperr == LIBSSH2_FX_NO_SUCH_PATH))
                        {
                            sshc.secondCreateDirs = 1;
                            ssh_state(data, sshc, .SSH_SFTP_CREATE_DIRS_INIT);
                            continue;
                        }
                        sshc.actualcode = sftpErrorToCurle(sftperr);
                    } else {
                        sshc.actualcode = session_error_to_CURLE(rc);
                    }
                    ssh_state(data, sshc, .SSH_SFTP_SHUTDOWN);
                    break;
                }

                const rf = Curl_ftp_acc_get_resume_from(data);
                if (rf > 0) {
                    if (Curl_ftp_acc_has_seek_func(data)) {
                        const seekerr = Curl_ftp_acc_call_seek_func(data, rf, SEEK_SET);
                        if (seekerr != CURL_SEEKFUNC_OK) {
                            sshc.actualcode = if (seekerr == CURL_SEEKFUNC_CANTSEEK)
                                CURLE_SSH
                            else
                                CURLE_ABORTED_BY_CALLBACK;
                            ssh_state(data, sshc, .SSH_SFTP_SHUTDOWN);
                            break;
                        }
                    } else {
                        var passed: curl_off_t = 0;
                        while (passed != rf) {
                            var scratch: [16384]u8 = undefined;
                            defer mem.secureZero(&scratch, scratch.len);
                            const readthisamountnow: usize = @intCast(@min(rf - passed, @as(curl_off_t, scratch.len)));
                            const actuallyread = Curl_ftp_acc_call_fread_func(data, &scratch, 1, readthisamountnow);
                            passed += @intCast(actuallyread);
                            if ((actuallyread == 0) or (actuallyread > readthisamountnow)) {
                                sshc.actualcode = CURLE_READ_ERROR;
                                ssh_state(data, sshc, .SSH_SFTP_SHUTDOWN);
                                break;
                            }
                        }
                        if (sshc.state == .SSH_SFTP_SHUTDOWN) break;
                    }
                    if (Curl_ftp_acc_get_infilesize(data) > 0) {
                        Curl_ftp_acc_set_req_size(data, Curl_ftp_acc_get_infilesize(data) - rf);
                        Curl_pgrsSetUploadSize(data, Curl_ftp_acc_get_infilesize(data) - rf);
                    }
                    libssh2_sftp_seek64(sshc.sftp_handle.?, @intCast(rf));
                } else if (Curl_ftp_acc_get_infilesize(data) > 0) {
                    Curl_ftp_acc_set_req_size(data, Curl_ftp_acc_get_infilesize(data));
                    Curl_pgrsSetUploadSize(data, Curl_ftp_acc_get_infilesize(data));
                }

                cfsocket_transfer.Curl_xfer_setup_send(@ptrCast(data), FIRSTSOCKET);
                Curl_vssh_set_conn_send_recv(conn, sftp_send, sftp_recv);
                sshc.orig_waitfor = CURL_POLL_OUT;
                ssh_state(data, sshc, .SSH_STOP);
            },

            .SSH_SFTP_CREATE_DIRS_INIT => {
                if (sshp.path) |path| {
                    if (std.mem.len(path) > 1) {
                        sshc.slash_pos = path + 1;
                        ssh_state(data, sshc, .SSH_SFTP_CREATE_DIRS);
                    } else {
                        ssh_state(data, sshc, .SSH_SFTP_UPLOAD_INIT);
                    }
                } else {
                    ssh_state(data, sshc, .SSH_SFTP_UPLOAD_INIT);
                }
            },

            .SSH_SFTP_CREATE_DIRS => {
                if (sshc.slash_pos) |sp| {
                    if (std.mem.indexOfScalar(u8, std.mem.span(sp), '/')) |idx| {
                        sshc.slash_pos = sp + idx;
                        sshc.slash_pos.?[0] = 0;
                        ssh_state(data, sshc, .SSH_SFTP_CREATE_DIRS_MKDIR);
                        continue;
                    }
                }
                ssh_state(data, sshc, .SSH_SFTP_UPLOAD_INIT);
            },

            .SSH_SFTP_CREATE_DIRS_MKDIR => {
                const path = sshp.path orelse "";
                const dir_perms: c_long = @intCast(Curl_setopt_get_i64(data, 55));
                rc = libssh2_sftp_mkdir_ex(
                    sshc.sftp_session.?,
                    path,
                    @intCast(std.mem.len(path)),
                    dir_perms,
                );
                if (rc == LIBSSH2_ERROR_EAGAIN) {
                    break;
                }
                if (sshc.slash_pos) |sp| {
                    sp[0] = '/';
                    sshc.slash_pos = sp + 1;
                }
                if (rc < 0) {
                    const sftperr = sftp_libssh2_last_error(sshc.sftp_session);
                    if ((sftperr != LIBSSH2_FX_FILE_ALREADY_EXISTS) and
                        (sftperr != LIBSSH2_FX_FAILURE) and
                        (sftperr != LIBSSH2_FX_PERMISSION_DENIED))
                    {
                        sshc.actualcode = sftpErrorToCurle(sftperr);
                        ssh_state(data, sshc, .SSH_SFTP_SHUTDOWN);
                        break;
                    }
                    rc = 0;
                }
                ssh_state(data, sshc, .SSH_SFTP_CREATE_DIRS);
            },

            .SSH_SFTP_READDIR_INIT => {
                Curl_pgrsSetDownloadSize(data, -1);
                if (Curl_ftp_acc_get_no_body(data)) {
                    ssh_state(data, sshc, .SSH_STOP);
                    break;
                }
                const path = sshp.path orelse "";
                sshc.sftp_handle = libssh2_sftp_open_ex(
                    sshc.sftp_session.?,
                    path,
                    @intCast(std.mem.len(path)),
                    0,
                    0,
                    LIBSSH2_SFTP_OPENDIR,
                );
                if (sshc.sftp_handle == null) {
                    if (libssh2_session_last_errno(sshc.ssh_session.?) == LIBSSH2_ERROR_EAGAIN) {
                        rc = LIBSSH2_ERROR_EAGAIN;
                        break;
                    }
                    const sftperr = sftp_libssh2_last_error(sshc.sftp_session);
                    sshc.actualcode = sftpErrorToCurle(sftperr);
                    ssh_state(data, sshc, .SSH_SFTP_SHUTDOWN);
                    break;
                }
                allocSftpReaddirBuffers(sshp) catch {
                    sshc.actualcode = CURLE_OUT_OF_MEMORY;
                    ssh_state(data, sshc, .SSH_SFTP_SHUTDOWN);
                    break;
                };
                containers.curlx_dyn_reset(&sshp.readdir);
                ssh_state(data, sshc, .SSH_SFTP_READDIR);
            },

            .SSH_SFTP_READDIR => {
                rc = libssh2_sftp_readdir_ex(
                    sshc.sftp_handle.?,
                    sshp.readdir_filename.?,
                    DYN_PATH_MAX,
                    sshp.readdir_longentry.?,
                    DYN_PATH_MAX,
                    &sshp.readdir_attrs,
                );
                if (rc == LIBSSH2_ERROR_EAGAIN) {
                    break;
                }
                if (rc > 0) {
                    const readdir_len: usize = @intCast(rc);
                    sshp.readdir_filename.?[readdir_len] = 0;

                    if (Curl_ftp_acc_get_list_only(data)) {
                        result = sendf.Curl_client_write(@ptrCast(data), CLIENTWRITE_BODY, sshp.readdir_filename.?, readdir_len);
                        if (result == CURLE_OK) {
                            result = sendf.Curl_client_write(@ptrCast(data), CLIENTWRITE_BODY, "\n", 1);
                        }
                        if (result != CURLE_OK) {
                            sshc.actualcode = result;
                            ssh_state(data, sshc, .SSH_STOP);
                            break;
                        }
                        continue;
                    }

                    result = containers.curlx_dyn_add(&sshp.readdir, sshp.readdir_longentry.?);
                    if (result == CURLE_OK) {
                        if ((sshp.readdir_attrs.flags & LIBSSH2_SFTP_ATTR_PERMISSIONS) != 0 and
                            (sshp.readdir_attrs.permissions & LIBSSH2_SFTP_S_IFMT) == LIBSSH2_SFTP_S_IFLNK)
                        {
                            const path = sshp.path orelse "";
                            sshp.readdir_linkPath = curl_maprintf("%s%s", path, sshp.readdir_filename.?);
                            if (sshp.readdir_linkPath == null) {
                                sshc.actualcode = CURLE_OUT_OF_MEMORY;
                                ssh_state(data, sshc, .SSH_SFTP_SHUTDOWN);
                                break;
                            }
                            ssh_state(data, sshc, .SSH_SFTP_READDIR_LINK);
                            continue;
                        }
                        ssh_state(data, sshc, .SSH_SFTP_READDIR_BOTTOM);
                        continue;
                    }
                    sshc.actualcode = result;
                    ssh_state(data, sshc, .SSH_SFTP_SHUTDOWN);
                    break;
                } else if (rc == 0) {
                    ssh_state(data, sshc, .SSH_SFTP_READDIR_DONE);
                } else {
                    const sftperr = sftp_libssh2_last_error(sshc.sftp_session);
                    sshc.actualcode = if (sftperr != 0) sftpErrorToCurle(sftperr) else CURLE_SSH;
                    ssh_state(data, sshc, .SSH_SFTP_SHUTDOWN);
                    break;
                }
            },

            .SSH_SFTP_READDIR_LINK => {
                const lp = sshp.readdir_linkPath orelse "";
                rc = libssh2_sftp_symlink_ex(
                    sshc.sftp_session.?,
                    lp,
                    @intCast(std.mem.len(lp)),
                    sshp.readdir_filename.?,
                    DYN_PATH_MAX,
                    LIBSSH2_SFTP_READLINK,
                );
                if (rc == LIBSSH2_ERROR_EAGAIN) {
                    break;
                }
                if (sshp.readdir_linkPath) |p| {
                    mem.free(p);
                    sshp.readdir_linkPath = null;
                }
                if (rc >= 0) {
                    const link_len: usize = @intCast(rc);
                    sshp.readdir_filename.?[link_len] = 0;
                    result = containers.curlx_dyn_addn(&sshp.readdir, " -> ", 4);
                    if (result == CURLE_OK) {
                        result = containers.curlx_dyn_addn(&sshp.readdir, sshp.readdir_filename.?, link_len);
                    }
                    if (result != CURLE_OK) {
                        sshc.actualcode = result;
                        ssh_state(data, sshc, .SSH_SFTP_SHUTDOWN);
                        break;
                    }
                }
                ssh_state(data, sshc, .SSH_SFTP_READDIR_BOTTOM);
            },

            .SSH_SFTP_READDIR_BOTTOM => {
                result = containers.curlx_dyn_addn(&sshp.readdir, "\n", 1);
                if (result == CURLE_OK) {
                    if (containers.curlx_dyn_ptr(&sshp.readdir)) |ptr| {
                        result = sendf.Curl_client_write(
                            @ptrCast(data),
                            CLIENTWRITE_BODY,
                            ptr,
                            containers.curlx_dyn_len(&sshp.readdir),
                        );
                    }
                }
                containers.curlx_dyn_reset(&sshp.readdir);
                if (result != CURLE_OK) {
                    sshc.actualcode = result;
                    ssh_state(data, sshc, .SSH_STOP);
                } else {
                    ssh_state(data, sshc, .SSH_SFTP_READDIR);
                }
            },

            .SSH_SFTP_READDIR_DONE => {
                if (libssh2_sftp_close_handle(sshc.sftp_handle.?) == LIBSSH2_ERROR_EAGAIN) {
                    rc = LIBSSH2_ERROR_EAGAIN;
                    break;
                }
                sshc.sftp_handle = null;
                if (sshp.readdir_filename) |f| {
                    mem.free(f);
                    sshp.readdir_filename = null;
                }
                if (sshp.readdir_longentry) |le| {
                    mem.free(le);
                    sshp.readdir_longentry = null;
                }
                cfsocket_transfer.Curl_xfer_setup_nop(@ptrCast(data));
                ssh_state(data, sshc, .SSH_STOP);
            },

            .SSH_SFTP_DOWNLOAD_INIT => {
                const path = sshp.path orelse "";
                sshc.sftp_handle = libssh2_sftp_open_ex(
                    sshc.sftp_session.?,
                    path,
                    @intCast(std.mem.len(path)),
                    LIBSSH2_FXF_READ,
                    0,
                    LIBSSH2_SFTP_OPENFILE,
                );
                if (sshc.sftp_handle == null) {
                    if (libssh2_session_last_errno(sshc.ssh_session.?) == LIBSSH2_ERROR_EAGAIN) {
                        rc = LIBSSH2_ERROR_EAGAIN;
                        break;
                    }
                    const sftperr = sftp_libssh2_last_error(sshc.sftp_session);
                    sshc.actualcode = sftpErrorToCurle(sftperr);
                    ssh_state(data, sshc, .SSH_SFTP_SHUTDOWN);
                    break;
                }
                ssh_state(data, sshc, .SSH_SFTP_DOWNLOAD_STAT);
            },

            .SSH_SFTP_DOWNLOAD_STAT => {
                var attrs: LIBSSH2_SFTP_ATTRIBUTES = std.mem.zeroes(LIBSSH2_SFTP_ATTRIBUTES);
                const path = sshp.path orelse "";
                rc = libssh2_sftp_stat_ex(
                    sshc.sftp_session.?,
                    path,
                    @intCast(std.mem.len(path)),
                    LIBSSH2_SFTP_STAT,
                    &attrs,
                );
                if (rc == LIBSSH2_ERROR_EAGAIN) {
                    break;
                }
                var size: curl_off_t = -1;
                if (rc == 0 and (attrs.flags & LIBSSH2_SFTP_ATTR_SIZE) != 0) {
                    size = @intCast(attrs.filesize);
                    if (size < 0) {
                        sshc.actualcode = CURLE_BAD_FUNCTION_ARGUMENT;
                        ssh_state(data, sshc, .SSH_SFTP_CLOSE);
                        break;
                    }
                    const max_fs = Curl_ftp_acc_get_max_filesize(data);
                    if (max_fs > 0 and size > max_fs) {
                        sshc.actualcode = CURLE_FILESIZE_EXCEEDED;
                        ssh_state(data, sshc, .SSH_SFTP_CLOSE);
                        break;
                    }
                    Curl_ftp_acc_set_req_size(data, size);
                }

                if (easyStrGet(data, setopt.STRING_SET_RANGE)) |range_str| {
                    if (size < 0) {
                        sshc.actualcode = CURLE_RANGE_ERROR;
                        ssh_state(data, sshc, .SSH_SFTP_CLOSE);
                        break;
                    }
                    var from: curl_off_t = 0;
                    result = Curl_ssh_range(data, range_str, size, &from, &size);
                    if (result != CURLE_OK) {
                        sshc.actualcode = result;
                        ssh_state(data, sshc, .SSH_SFTP_CLOSE);
                        break;
                    }
                    libssh2_sftp_seek64(sshc.sftp_handle.?, @intCast(from));
                    Curl_ftp_acc_set_req_size(data, size);
                    Curl_http_acc_req_set_maxdownload(data, size);
                    Curl_pgrsSetDownloadSize(data, size);
                }

                const rf = Curl_ftp_acc_get_resume_from(data);
                if (rf > 0) {
                    if (size >= 0 and rf >= size) {
                        Curl_ftp_acc_set_req_size(data, 0);
                        Curl_pgrsSetDownloadSize(data, 0);
                        cfsocket_transfer.Curl_xfer_setup_nop(@ptrCast(data));
                        ssh_state(data, sshc, .SSH_STOP);
                        break;
                    }
                    libssh2_sftp_seek64(sshc.sftp_handle.?, @intCast(rf));
                    if (size >= 0) {
                        size -= rf;
                    }
                }

                if (Curl_ftp_acc_get_req_maxdownload(data) > 0 and
                    (size < 0 or Curl_ftp_acc_get_req_maxdownload(data) < size))
                {
                    size = Curl_ftp_acc_get_req_maxdownload(data);
                }
                if (size >= 0) {
                    Curl_ftp_acc_set_req_size(data, size);
                    Curl_pgrsSetDownloadSize(data, size);
                }

                if (Curl_ftp_acc_get_no_body(data) or size == 0) {
                    cfsocket_transfer.Curl_xfer_setup_nop(@ptrCast(data));
                } else {
                    cfsocket_transfer.Curl_xfer_setup_recv(@ptrCast(data), FIRSTSOCKET, size);
                    Curl_vssh_set_conn_send_recv(conn, sftp_send, sftp_recv);
                    sshc.orig_waitfor = CURL_POLL_IN;
                }
                ssh_state(data, sshc, .SSH_STOP);
            },

            .SSH_SFTP_CLOSE => {
                if (sshc.sftp_handle) |h| {
                    rc = libssh2_sftp_close_handle(h);
                    if (rc == LIBSSH2_ERROR_EAGAIN) {
                        break;
                    }
                    sshc.sftp_handle = null;
                }
                if (sshp.path) |p| {
                    mem.free(p);
                    sshp.path = null;
                }
                if (sshc.nextstate != .SSH_NO_STATE and sshc.nextstate != .SSH_SFTP_CLOSE) {
                    ssh_state(data, sshc, sshc.nextstate);
                    sshc.nextstate = .SSH_SFTP_CLOSE;
                } else {
                    ssh_state(data, sshc, .SSH_STOP);
                    sshc.nextstate = .SSH_NO_STATE;
                }
            },

            .SSH_SFTP_SHUTDOWN => {
                if (sshc.sftp_handle) |h| {
                    rc = libssh2_sftp_close_handle(h);
                    if (rc == LIBSSH2_ERROR_EAGAIN) {
                        break;
                    }
                    sshc.sftp_handle = null;
                }
                if (sshc.sftp_session) |sftp| {
                    rc = libssh2_sftp_shutdown(sftp);
                    if (rc == LIBSSH2_ERROR_EAGAIN) {
                        break;
                    }
                    sshc.sftp_session = null;
                }
                if (sshp.path) |p| {
                    mem.free(p);
                    sshp.path = null;
                }
                containers.curlx_dyn_free(&sshp.readdir);
                if (sshc.homedir) |hd| {
                    mem.free(hd);
                    sshc.homedir = null;
                }
                ssh_state(data, sshc, .SSH_SESSION_DISCONNECT);
            },

            .SSH_SCP_TRANS_INIT => {
                result = Curl_getworkingpath(data, sshc.homedir orelse ".", &sshp.path);
                if (result != CURLE_OK) {
                    sshc.actualcode = result;
                    ssh_state(data, sshc, .SSH_STOP);
                    break;
                }
                if (Curl_ftp_acc_get_upload(data)) {
                    if (Curl_ftp_acc_get_infilesize(data) < 0) {
                        Curl_failf(data, "SCP requires a known file size for upload");
                        sshc.actualcode = CURLE_UPLOAD_FAILED;
                        ssh_state(data, sshc, .SSH_SCP_CHANNEL_FREE);
                        break;
                    }
                    ssh_state(data, sshc, .SSH_SCP_UPLOAD_INIT);
                } else {
                    ssh_state(data, sshc, .SSH_SCP_DOWNLOAD_INIT);
                }
            },

            .SSH_SCP_UPLOAD_INIT => {
                const path = sshp.path orelse "";
                const file_perms: c_int = @intCast(Curl_setopt_get_i64(data, 51));
                const infilesize = Curl_ftp_acc_get_infilesize(data);
                sshc.ssh_channel = libssh2_scp_send64(
                    sshc.ssh_session.?,
                    path,
                    file_perms,
                    infilesize,
                    0,
                    0,
                );
                if (sshc.ssh_channel == null) {
                    const err = libssh2_session_last_errno(sshc.ssh_session.?);
                    if (err == LIBSSH2_ERROR_EAGAIN) {
                        rc = LIBSSH2_ERROR_EAGAIN;
                        break;
                    }
                    sshc.actualcode = session_error_to_CURLE(err);
                    ssh_state(data, sshc, .SSH_SCP_CHANNEL_FREE);
                    break;
                }
                Curl_ftp_acc_set_req_size(data, infilesize);
                Curl_pgrsSetUploadSize(data, infilesize);
                cfsocket_transfer.Curl_xfer_setup_send(@ptrCast(data), FIRSTSOCKET);
                Curl_vssh_set_conn_send_recv(conn, scp_send, scp_recv);
                sshc.orig_waitfor = CURL_POLL_OUT;
                ssh_state(data, sshc, .SSH_STOP);
            },

            .SSH_SCP_DOWNLOAD_INIT => {
                var bytecount: curl_off_t = 0;
                const path = sshp.path orelse "";
                sshc.ssh_channel = Curl_libssh2_scp_recv2_size(
                    sshc.ssh_session.?,
                    path,
                    &bytecount,
                );
                if (sshc.ssh_channel == null) {
                    const err = libssh2_session_last_errno(sshc.ssh_session.?);
                    if (err == LIBSSH2_ERROR_EAGAIN) {
                        rc = LIBSSH2_ERROR_EAGAIN;
                        break;
                    }
                    sshc.actualcode = session_error_to_CURLE(err);
                    ssh_state(data, sshc, .SSH_SCP_CHANNEL_FREE);
                    break;
                }

                const max_fs = Curl_ftp_acc_get_max_filesize(data);
                if (max_fs > 0 and bytecount > max_fs) {
                    sshc.actualcode = CURLE_FILESIZE_EXCEEDED;
                    ssh_state(data, sshc, .SSH_SCP_CHANNEL_FREE);
                    break;
                }
                if (bytecount < 0) {
                    sshc.actualcode = CURLE_BAD_FUNCTION_ARGUMENT;
                    ssh_state(data, sshc, .SSH_SCP_CHANNEL_FREE);
                    break;
                }
                Curl_pgrsSetDownloadSize(data, bytecount);
                Curl_ftp_acc_set_req_size(data, bytecount);
                cfsocket_transfer.Curl_xfer_setup_recv(@ptrCast(data), FIRSTSOCKET, bytecount);
                Curl_vssh_set_conn_send_recv(conn, scp_send, scp_recv);
                sshc.orig_waitfor = CURL_POLL_IN;
                ssh_state(data, sshc, .SSH_STOP);
            },

            .SSH_SCP_DONE => {
                if (Curl_ftp_acc_get_upload(data)) {
                    ssh_state(data, sshc, .SSH_SCP_SEND_EOF);
                } else {
                    ssh_state(data, sshc, .SSH_SCP_CHANNEL_FREE);
                }
            },

            .SSH_SCP_SEND_EOF => {
                if (sshc.ssh_channel) |ch| {
                    rc = libssh2_channel_send_eof(ch);
                    if (rc == LIBSSH2_ERROR_EAGAIN) {
                        break;
                    }
                }
                ssh_state(data, sshc, .SSH_SCP_WAIT_EOF);
            },

            .SSH_SCP_WAIT_EOF => {
                if (sshc.ssh_channel) |ch| {
                    rc = libssh2_channel_wait_eof(ch);
                    if (rc == LIBSSH2_ERROR_EAGAIN) {
                        break;
                    }
                }
                ssh_state(data, sshc, .SSH_SCP_WAIT_CLOSE);
            },

            .SSH_SCP_WAIT_CLOSE => {
                if (sshc.ssh_channel) |ch| {
                    rc = libssh2_channel_wait_closed(ch);
                    if (rc == LIBSSH2_ERROR_EAGAIN) {
                        break;
                    }
                }
                ssh_state(data, sshc, .SSH_SCP_CHANNEL_FREE);
            },

            .SSH_SCP_CHANNEL_FREE => {
                if (sshc.ssh_channel) |ch| {
                    rc = libssh2_channel_free(ch);
                    if (rc == LIBSSH2_ERROR_EAGAIN) {
                        break;
                    }
                    sshc.ssh_channel = null;
                }
                if (sshc.nextstate != .SSH_NO_STATE) {
                    ssh_state(data, sshc, sshc.nextstate);
                    sshc.nextstate = .SSH_NO_STATE;
                } else {
                    ssh_state(data, sshc, .SSH_STOP);
                }
            },

            .SSH_SESSION_DISCONNECT => {
                if (sshc.ssh_channel) |ch| {
                    rc = libssh2_channel_free(ch);
                    if (rc == LIBSSH2_ERROR_EAGAIN) {
                        break;
                    }
                    sshc.ssh_channel = null;
                }
                if (sshc.ssh_session) |sess| {
                    rc = libssh2_session_disconnect_ex(sess, SSH_DISCONNECT_BY_APPLICATION, "Shutdown", "");
                    if (rc == LIBSSH2_ERROR_EAGAIN) {
                        break;
                    }
                }
                ssh_state(data, sshc, .SSH_SESSION_FREE);
            },

            .SSH_SESSION_FREE => {
                if (sshc.kh) |kh| {
                    libssh2_knownhost_free(kh);
                    sshc.kh = null;
                }
                if (sshc.ssh_agent) |ag| {
                    rc = libssh2_agent_disconnect(ag);
                    if (rc == LIBSSH2_ERROR_EAGAIN) {
                        break;
                    }
                    libssh2_agent_free(ag);
                    sshc.ssh_agent = null;
                    sshc.sshagent_identity = null;
                    sshc.sshagent_prev_identity = null;
                }
                if (sshc.ssh_session) |sess| {
                    rc = libssh2_session_free(sess);
                    if (rc == LIBSSH2_ERROR_EAGAIN) {
                        break;
                    }
                    sshc.ssh_session = null;
                }
                if (sshc.rsa) |r| {
                    mem.freeSecretZ(r);
                    sshc.rsa = null;
                }
                if (sshc.rsa_pub) |rp| {
                    mem.freeSecretZ(rp);
                    sshc.rsa_pub = null;
                }
                if (sshc.quote_path1) |p1| {
                    mem.free(p1);
                    sshc.quote_path1 = null;
                }
                if (sshc.quote_path2) |p2| {
                    mem.free(p2);
                    sshc.quote_path2 = null;
                }
                if (sshc.homedir) |hd| {
                    mem.free(hd);
                    sshc.homedir = null;
                }
                ssh_state(data, sshc, .SSH_STOP);
                result = sshc.actualcode;
                const nextstate = sshc.nextstate;
                mem.secureZero(sshc, @sizeOf(ssh_conn));
                sshc.* = .{};
                if (nextstate != .SSH_NO_STATE) {
                    ssh_state(data, sshc, nextstate);
                }
            },

            .SSH_QUIT, .SSH_STOP, .SSH_NO_STATE, .SSH_LAST, .SSH_AUTH_GSSAPI, .SSH_SCP_DOWNLOAD => {
                ssh_state(data, sshc, .SSH_STOP);
                break;
            },
        }

        if (rc == LIBSSH2_ERROR_EAGAIN or sshc.state == .SSH_STOP) {
            break;
        }
    }

    if (rc == LIBSSH2_ERROR_EAGAIN) {
        block.* = true;
    }

    return if (result == CURLE_OK) sshc.actualcode else result;
}

fn ssh_multi_statemach(data: *Curl_easy, done: *bool) CURLcode {
    const conn = Curl_ftp_acc_get_conn(data) orelse return CURLE_FAILED_INIT;
    const sshc: *ssh_conn = @ptrCast(@alignCast(Curl_conn_meta_get(conn, CURL_META_SSH_CONN) orelse return CURLE_FAILED_INIT));
    const sshp: *SSHPROTO = @ptrCast(@alignCast(Curl_meta_get(data, CURL_META_SSH_EASY) orelse return CURLE_FAILED_INIT));
    var block: bool = false;
    const result = ssh_statemach_act(data, sshc, sshp, &block);
    done.* = (sshc.state == .SSH_STOP) and !block;
    return result;
}

fn ssh_block_statemach(data: *Curl_easy, sshc: *ssh_conn, sshp: *SSHPROTO, disconnect: bool) CURLcode {
    const conn = Curl_ftp_acc_get_conn(data) orelse return CURLE_FAILED_INIT;
    var result: CURLcode = CURLE_OK;

    while ((sshc.state != .SSH_STOP) and (result == CURLE_OK)) {
        var block: bool = false;
        var left: timediff_t = 1000;

        result = ssh_statemach_act(data, sshc, sshp, &block);
        if (result != CURLE_OK) {
            break;
        }

        if (!disconnect) {
            left = Curl_timeleft_ms(data, false);
            if (left < 0) {
                Curl_failf(data, "Operation timed out");
                return CURLE_OPERATION_TIMEDOUT;
            }
        }

        if (block) {
            const session = sshc.ssh_session orelse break;
            const dir = libssh2_session_block_directions(session);
            const sock = Curl_vssh_get_conn_firstsocket(conn);
            const wait_ms: timediff_t = if (left > 1000) 1000 else left;
            const rc = Curl_socket_check(
                if ((dir & LIBSSH2_SESSION_BLOCK_INBOUND) != 0) sock else CURL_SOCKET_BAD,
                CURL_SOCKET_BAD,
                if ((dir & LIBSSH2_SESSION_BLOCK_OUTBOUND) != 0) sock else CURL_SOCKET_BAD,
                wait_ms,
            );
            if (rc == -1) {
                return CURLE_OUT_OF_MEMORY;
            }
        }
    }
    return result;
}

fn ssh_pollset(data_opt: ?*Curl_easy, ps_opt: ?*easy_pollset) callconv(.c) CURLcode {
    const data = data_opt orelse return CURLE_BAD_FUNCTION_ARGUMENT;
    const ps = ps_opt orelse return CURLE_OK;
    const conn = Curl_ftp_acc_get_conn(data) orelse return CURLE_OK;
    const sshc: *ssh_conn = @ptrCast(@alignCast(Curl_conn_meta_get(conn, CURL_META_SSH_CONN) orelse return CURLE_OK));
    const sock = Curl_vssh_get_conn_firstsocket(conn);
    if (sock == CURL_SOCKET_BAD) return CURLE_OK;

    var waitfor = sshc.orig_waitfor;
    if (sshc.ssh_session) |sess| {
        const dir = libssh2_session_block_directions(sess);
        if (dir != 0) {
            waitfor = 0;
            if ((dir & LIBSSH2_SESSION_BLOCK_INBOUND) != 0) {
                waitfor |= CURL_POLL_IN;
            }
            if ((dir & LIBSSH2_SESSION_BLOCK_OUTBOUND) != 0) {
                waitfor |= CURL_POLL_OUT;
            }
        }
    }
    if (waitfor != 0) {
        return Curl_pollset_change(data, ps, sock, waitfor, 0);
    }
    return CURLE_OK;
}

fn ssh_block2waitfor(data: *Curl_easy, sshc: *ssh_conn, block: bool) void {
    if (block) {
        if (sshc.ssh_session) |sess| {
            const dir = libssh2_session_block_directions(sess);
            if (dir != 0) {
                sshc.orig_waitfor = 0;
                if ((dir & LIBSSH2_SESSION_BLOCK_INBOUND) != 0) {
                    sshc.orig_waitfor |= CURL_POLL_IN;
                }
                if ((dir & LIBSSH2_SESSION_BLOCK_OUTBOUND) != 0) {
                    sshc.orig_waitfor |= CURL_POLL_OUT;
                }
                return;
            }
        }
    }
    Curl_multi_mark_dirty(data);
}

fn ssh_connect(data_opt: ?*Curl_easy, done: *bool) callconv(.c) CURLcode {
    const data = data_opt orelse return CURLE_BAD_FUNCTION_ARGUMENT;
    if (comptime !use_libssh2) {
        done.* = false;
        return CURLE_NOT_BUILT_IN;
    }

    const conn = Curl_ftp_acc_get_conn(data) orelse return CURLE_FAILED_INIT;
    const sshc: *ssh_conn = @ptrCast(@alignCast(Curl_conn_meta_get(conn, CURL_META_SSH_CONN) orelse return CURLE_FAILED_INIT));
    if (Curl_meta_get(data, CURL_META_SSH_EASY) == null) {
        const sc_res = Curl_ssh_setup_connection(data, conn);
        if (sc_res != CURLE_OK) return sc_res;
    }

    sshc.priv_key = easyStrGet(data, setopt.STRING_SSH_PRIVATE_KEY);
    sshc.pub_key = easyStrGet(data, setopt.STRING_SSH_PUBLIC_KEY);

    sshc.ssh_session = libssh2_session_init_ex(
        @ptrCast(&libssh2_malloc_cb),
        @ptrCast(&libssh2_free_cb),
        @ptrCast(&libssh2_realloc_cb),
        data,
    );
    if (sshc.ssh_session == null) {
        Curl_failf(data, "Failure initialising ssh session");
        return CURLE_FAILED_INIT;
    }

    if (Curl_setopt_get_bit(data, 45)) {
        _ = libssh2_session_flag(sshc.ssh_session.?, LIBSSH2_FLAG_COMPRESS, 1);
    }

    if (easyStrGet(data, setopt.STRING_SSH_KNOWNHOSTS)) |kh_file| {
        sshc.kh = libssh2_knownhost_init(sshc.ssh_session.?);
        if (sshc.kh == null) {
            _ = libssh2_session_free(sshc.ssh_session.?);
            sshc.ssh_session = null;
            return CURLE_FAILED_INIT;
        }
        const rc = libssh2_knownhost_readfile(sshc.kh.?, kh_file, LIBSSH2_KNOWNHOST_FILE_OPENSSH);
        if (rc < 0) {
            Curl_infof(data, "Failed to read known hosts from %s", kh_file);
        }
    }

    ssh_state(data, sshc, .SSH_INIT);
    const result = ssh_multi_statemach(data, done);
    if (result == CURLE_OK and done.*) {
        sshc.initialised = true;
    }
    return result;
}

fn ssh_connecting(data_opt: ?*Curl_easy, done: *bool) callconv(.c) CURLcode {
    const data = data_opt orelse return CURLE_BAD_FUNCTION_ARGUMENT;
    if (comptime !use_libssh2) {
        done.* = false;
        return CURLE_NOT_BUILT_IN;
    }
    const conn = Curl_ftp_acc_get_conn(data) orelse return CURLE_FAILED_INIT;
    const sshc: *ssh_conn = @ptrCast(@alignCast(Curl_conn_meta_get(conn, CURL_META_SSH_CONN) orelse return CURLE_FAILED_INIT));
    const result = ssh_multi_statemach(data, done);
    if (result == CURLE_OK and done.*) {
        sshc.initialised = true;
    }
    return result;
}

fn ssh_doing(data_opt: ?*Curl_easy, dophase_done: *bool) callconv(.c) CURLcode {
    const data = data_opt orelse return CURLE_BAD_FUNCTION_ARGUMENT;
    const result = ssh_multi_statemach(data, dophase_done);
    return result;
}

fn scp_perform(data: *Curl_easy, connected: *bool, dophase_done: *bool) CURLcode {
    const conn = Curl_ftp_acc_get_conn(data) orelse return CURLE_FAILED_INIT;
    const sshc: *ssh_conn = @ptrCast(@alignCast(Curl_conn_meta_get(conn, CURL_META_SSH_CONN) orelse return CURLE_FAILED_INIT));

    dophase_done.* = false;
    ssh_state(data, sshc, .SSH_SCP_TRANS_INIT);
    const result = ssh_multi_statemach(data, dophase_done);
    connected.* = true;
    return result;
}

fn scp_do(data_opt: ?*Curl_easy, done: *bool) callconv(.c) CURLcode {
    const data = data_opt orelse return CURLE_BAD_FUNCTION_ARGUMENT;
    if (comptime !use_libssh2) {
        done.* = false;
        return CURLE_NOT_BUILT_IN;
    }
    var connected: bool = false;
    done.* = false;

    Curl_ftp_acc_set_req_size(data, -1);
    Curl_pgrsReset(data);

    return scp_perform(data, &connected, done);
}

fn scp_done(data_opt: ?*Curl_easy, status: CURLcode, premature: bool) callconv(.c) CURLcode {
    _ = premature;
    const data = data_opt orelse return CURLE_BAD_FUNCTION_ARGUMENT;
    if (comptime !use_libssh2) return CURLE_NOT_BUILT_IN;

    const conn = Curl_ftp_acc_get_conn(data) orelse return CURLE_FAILED_INIT;
    const sshc: *ssh_conn = @ptrCast(@alignCast(Curl_conn_meta_get(conn, CURL_META_SSH_CONN) orelse return CURLE_FAILED_INIT));
    const sshp: *SSHPROTO = @ptrCast(@alignCast(Curl_meta_get(data, CURL_META_SSH_EASY) orelse return CURLE_FAILED_INIT));

    if (sshp.path) |p| {
        mem.free(p);
        sshp.path = null;
    }

    var result: CURLcode = CURLE_OK;
    if (status == CURLE_OK) {
        ssh_state(data, sshc, .SSH_SCP_DONE);
        result = ssh_block_statemach(data, sshc, sshp, false);
    } else {
        result = status;
    }
    return result;
}

fn scp_disconnect(data_opt: ?*Curl_easy, conn_opt: ?*connectdata, dead_connection: bool) callconv(.c) CURLcode {
    const data = data_opt orelse return CURLE_BAD_FUNCTION_ARGUMENT;
    const conn = conn_opt orelse return CURLE_BAD_FUNCTION_ARGUMENT;
    if (comptime !use_libssh2) return CURLE_OK;

    const sshc: *ssh_conn = @ptrCast(@alignCast(Curl_conn_meta_get(conn, CURL_META_SSH_CONN) orelse return CURLE_OK));
    const sshp: ?*SSHPROTO = @ptrCast(@alignCast(Curl_meta_get(data, CURL_META_SSH_EASY)));
    if (sshp) |sp| {
        if (sp.path) |p| {
            mem.free(p);
            sp.path = null;
        }
    }

    var result: CURLcode = CURLE_OK;
    if (sshc.ssh_session != null) {
        if (!dead_connection) {
            ssh_state(data, sshc, .SSH_SESSION_DISCONNECT);
        } else {
            ssh_state(data, sshc, .SSH_SCP_CHANNEL_FREE);
            sshc.nextstate = .SSH_SESSION_FREE;
        }
        var dummy_proto: SSHPROTO = .{};
        result = ssh_block_statemach(data, sshc, sshp orelse &dummy_proto, true);
    }
    return result;
}

fn sftp_perform(data: *Curl_easy, connected: *bool, dophase_done: *bool) CURLcode {
    const conn = Curl_ftp_acc_get_conn(data) orelse return CURLE_FAILED_INIT;
    const sshc: *ssh_conn = @ptrCast(@alignCast(Curl_conn_meta_get(conn, CURL_META_SSH_CONN) orelse return CURLE_FAILED_INIT));

    dophase_done.* = false;
    ssh_state(data, sshc, .SSH_SFTP_QUOTE_INIT);
    const result = ssh_multi_statemach(data, dophase_done);
    connected.* = true;
    return result;
}

fn sftp_connect_it(data_opt: ?*Curl_easy, done: *bool) callconv(.c) CURLcode {
    const data = data_opt orelse return CURLE_BAD_FUNCTION_ARGUMENT;
    if (comptime !use_libssh2) {
        done.* = false;
        return CURLE_NOT_BUILT_IN;
    }
    const conn = Curl_ftp_acc_get_conn(data) orelse return CURLE_FAILED_INIT;
    const sshc: *ssh_conn = @ptrCast(@alignCast(Curl_conn_meta_get(conn, CURL_META_SSH_CONN) orelse return CURLE_FAILED_INIT));

    if (!sshc.initialised) {
        var ssh_done: bool = false;
        const result = ssh_connect(data, &ssh_done);
        if (result != CURLE_OK or !ssh_done) {
            done.* = false;
            return result;
        }
        ssh_state(data, sshc, .SSH_SFTP_INIT);
        return ssh_multi_statemach(data, done);
    }
    done.* = true;
    return CURLE_OK;
}

fn sftp_connecting(data_opt: ?*Curl_easy, done: *bool) callconv(.c) CURLcode {
    const data = data_opt orelse return CURLE_BAD_FUNCTION_ARGUMENT;
    if (comptime !use_libssh2) {
        done.* = false;
        return CURLE_NOT_BUILT_IN;
    }
    const conn = Curl_ftp_acc_get_conn(data) orelse return CURLE_FAILED_INIT;
    const sshc: *ssh_conn = @ptrCast(@alignCast(Curl_conn_meta_get(conn, CURL_META_SSH_CONN) orelse return CURLE_FAILED_INIT));

    var result = ssh_multi_statemach(data, done);
    if (result == CURLE_OK and done.*) {
        if (!sshc.initialised) {
            sshc.initialised = true;
            done.* = false;
            ssh_state(data, sshc, .SSH_SFTP_INIT);
            result = ssh_multi_statemach(data, done);
        }
    }
    return result;
}

fn sftp_do(data_opt: ?*Curl_easy, done: *bool) callconv(.c) CURLcode {
    const data = data_opt orelse return CURLE_BAD_FUNCTION_ARGUMENT;
    if (comptime !use_libssh2) {
        done.* = false;
        return CURLE_NOT_BUILT_IN;
    }
    var connected: bool = false;
    done.* = false;

    Curl_ftp_acc_set_req_size(data, -1);
    Curl_vssh_set_state_wildcardmatch(data, false);
    Curl_pgrsReset(data);

    return sftp_perform(data, &connected, done);
}

fn sftp_done(data_opt: ?*Curl_easy, status: CURLcode, premature: bool) callconv(.c) CURLcode {
    const data = data_opt orelse return CURLE_BAD_FUNCTION_ARGUMENT;
    if (comptime !use_libssh2) return CURLE_NOT_BUILT_IN;

    const conn = Curl_ftp_acc_get_conn(data) orelse return CURLE_FAILED_INIT;
    const sshc: *ssh_conn = @ptrCast(@alignCast(Curl_conn_meta_get(conn, CURL_META_SSH_CONN) orelse return CURLE_FAILED_INIT));
    const sshp: *SSHPROTO = @ptrCast(@alignCast(Curl_meta_get(data, CURL_META_SSH_EASY) orelse return CURLE_FAILED_INIT));

    var result: CURLcode = CURLE_OK;
    var disconnect = false;

    if (status == CURLE_OK) {
        if (!premature and Curl_ftp_acc_get_postquote(data) != null and !Curl_vssh_get_state_wildcardmatch(data)) {
            sshc.nextstate = .SSH_SFTP_POSTQUOTE_INIT;
            ssh_state(data, sshc, .SSH_SFTP_CLOSE);
        } else {
            ssh_state(data, sshc, .SSH_SFTP_CLOSE);
        }
    } else {
        result = status;
        disconnect = true;
        ssh_state(data, sshc, .SSH_SFTP_CLOSE);
    }

    if (ssh_block_statemach(data, sshc, sshp, disconnect) != CURLE_OK) {
        if (result == CURLE_OK) {
            result = sshc.actualcode;
        }
    }
    return result;
}

fn sftp_disconnect(data_opt: ?*Curl_easy, conn_opt: ?*connectdata, dead_connection: bool) callconv(.c) CURLcode {
    const data = data_opt orelse return CURLE_BAD_FUNCTION_ARGUMENT;
    const conn = conn_opt orelse return CURLE_BAD_FUNCTION_ARGUMENT;
    if (comptime !use_libssh2) return CURLE_OK;

    const sshc: *ssh_conn = @ptrCast(@alignCast(Curl_conn_meta_get(conn, CURL_META_SSH_CONN) orelse return CURLE_OK));
    const sshp: ?*SSHPROTO = @ptrCast(@alignCast(Curl_meta_get(data, CURL_META_SSH_EASY)));
    if (sshp) |sp| {
        if (sp.path) |p| {
            mem.free(p);
            sp.path = null;
        }
    }

    var result: CURLcode = CURLE_OK;
    if (sshc.ssh_session != null) {
        if (!dead_connection) {
            ssh_state(data, sshc, .SSH_SFTP_SHUTDOWN);
        } else {
            ssh_state(data, sshc, .SSH_SESSION_FREE);
        }
        var dummy_proto: SSHPROTO = .{};
        result = ssh_block_statemach(data, sshc, sshp orelse &dummy_proto, true);
    }
    return result;
}

fn scp_send(
    data: *Curl_easy,
    sockindex: c_int,
    mem_buf: *const anyopaque,
    len: usize,
    eos: bool,
    pnwritten: *usize,
) callconv(.c) CURLcode {
    _ = sockindex;
    _ = eos;
    pnwritten.* = 0;
    const conn = Curl_ftp_acc_get_conn(data) orelse return CURLE_FAILED_INIT;
    const sshc: *ssh_conn = @ptrCast(@alignCast(Curl_conn_meta_get(conn, CURL_META_SSH_CONN) orelse return CURLE_FAILED_INIT));
    const ch = sshc.ssh_channel orelse return CURLE_SEND_ERROR;

    const nwrite = libssh2_channel_write_ex(ch, 0, @ptrCast(mem_buf), len);
    ssh_block2waitfor(data, sshc, nwrite == LIBSSH2_ERROR_EAGAIN);
    if (nwrite == LIBSSH2_ERROR_EAGAIN) {
        return CURLE_AGAIN;
    } else if (nwrite < 0) {
        return session_error_to_CURLE(@intCast(nwrite));
    }
    pnwritten.* = @intCast(nwrite);
    return CURLE_OK;
}

fn scp_recv(
    data: *Curl_easy,
    sockindex: c_int,
    mem_buf: [*]u8,
    len: usize,
    pnread: *usize,
) callconv(.c) CURLcode {
    _ = sockindex;
    pnread.* = 0;
    const conn = Curl_ftp_acc_get_conn(data) orelse return CURLE_FAILED_INIT;
    const sshc: *ssh_conn = @ptrCast(@alignCast(Curl_conn_meta_get(conn, CURL_META_SSH_CONN) orelse return CURLE_FAILED_INIT));
    const ch = sshc.ssh_channel orelse return CURLE_RECV_ERROR;

    const nread = libssh2_channel_read_ex(ch, 0, mem_buf, len);
    ssh_block2waitfor(data, sshc, nread == LIBSSH2_ERROR_EAGAIN);
    if (nread == LIBSSH2_ERROR_EAGAIN) {
        return CURLE_AGAIN;
    } else if (nread < 0) {
        return session_error_to_CURLE(@intCast(nread));
    }
    pnread.* = @intCast(nread);
    return CURLE_OK;
}

fn sftp_send(
    data: *Curl_easy,
    sockindex: c_int,
    mem_buf: *const anyopaque,
    len: usize,
    eos: bool,
    pnwritten: *usize,
) callconv(.c) CURLcode {
    _ = sockindex;
    _ = eos;
    pnwritten.* = 0;
    const conn = Curl_ftp_acc_get_conn(data) orelse return CURLE_FAILED_INIT;
    const sshc: *ssh_conn = @ptrCast(@alignCast(Curl_conn_meta_get(conn, CURL_META_SSH_CONN) orelse return CURLE_FAILED_INIT));
    const h = sshc.sftp_handle orelse return CURLE_SEND_ERROR;

    const nwrite = libssh2_sftp_write(h, @ptrCast(mem_buf), len);
    ssh_block2waitfor(data, sshc, nwrite == LIBSSH2_ERROR_EAGAIN);
    if (nwrite == LIBSSH2_ERROR_EAGAIN) {
        return CURLE_AGAIN;
    } else if (nwrite < 0) {
        return session_error_to_CURLE(@intCast(nwrite));
    }
    pnwritten.* = @intCast(nwrite);
    return CURLE_OK;
}

fn sftp_recv(
    data: *Curl_easy,
    sockindex: c_int,
    mem_buf: [*]u8,
    len: usize,
    pnread: *usize,
) callconv(.c) CURLcode {
    _ = sockindex;
    pnread.* = 0;
    const conn = Curl_ftp_acc_get_conn(data) orelse return CURLE_FAILED_INIT;
    const sshc: *ssh_conn = @ptrCast(@alignCast(Curl_conn_meta_get(conn, CURL_META_SSH_CONN) orelse return CURLE_FAILED_INIT));
    const h = sshc.sftp_handle orelse return CURLE_RECV_ERROR;

    const nread = libssh2_sftp_read(h, mem_buf, len);
    ssh_block2waitfor(data, sshc, nread == LIBSSH2_ERROR_EAGAIN);
    if (nread == LIBSSH2_ERROR_EAGAIN) {
        return CURLE_AGAIN;
    } else if (nread < 0) {
        return session_error_to_CURLE(@intCast(nread));
    }
    pnread.* = @intCast(nread);
    return CURLE_OK;
}

// ============================================================================
// 4. Public Protocol Descriptors & Global Init/Cleanup/Version
// ============================================================================

fn sshDisabledDo(data: ?*Curl_easy, done: *bool) callconv(.c) CURLcode {
    _ = data;
    done.* = false;
    return CURLE_NOT_BUILT_IN;
}

pub export const Curl_protocol_scp: Curl_protocol = if (use_libssh2) .{
    .setup_connection = Curl_ssh_setup_connection,
    .do_it = scp_do,
    .done = scp_done,
    .connect_it = ssh_connect,
    .connecting = ssh_connecting,
    .doing = ssh_doing,
    .proto_pollset = ssh_pollset,
    .doing_pollset = ssh_pollset,
    .perform_pollset = ssh_pollset,
    .disconnect = scp_disconnect,
} else if (use_libssh)
    vssh_libssh.protocol_scp
else
    .{
        .do_it = sshDisabledDo,
    };

pub export const Curl_protocol_sftp: Curl_protocol = if (use_libssh2) .{
    .setup_connection = Curl_ssh_setup_connection,
    .do_it = sftp_do,
    .done = sftp_done,
    .connect_it = sftp_connect_it,
    .connecting = sftp_connecting,
    .doing = ssh_doing,
    .proto_pollset = ssh_pollset,
    .doing_pollset = ssh_pollset,
    .perform_pollset = ssh_pollset,
    .disconnect = sftp_disconnect,
} else if (use_libssh)
    vssh_libssh.protocol_sftp
else
    .{
        .do_it = sshDisabledDo,
    };

pub export fn Curl_ssh_init() callconv(.c) CURLcode {
    if (comptime use_libssh2) {
        if (libssh2_init(0) != 0) {
            return CURLE_FAILED_INIT;
        }
    } else if (comptime use_libssh) {
        return vssh_libssh.init();
    }
    return CURLE_OK;
}

pub export fn Curl_ssh_cleanup() callconv(.c) void {
    if (comptime use_libssh2) {
        libssh2_exit();
    } else if (comptime use_libssh) {
        vssh_libssh.cleanup();
    }
}

pub export fn Curl_ssh_version(buffer: [*]u8, buflen: usize) callconv(.c) void {
    if (buflen == 0) return;
    if (comptime use_libssh2) {
        const ver = if (libssh2_version(0)) |p| std.mem.span(p) else "";
        const s = std.fmt.bufPrint(buffer[0 .. buflen - 1], "libssh2/{s}", .{ver}) catch {
            buffer[0] = 0;
            return;
        };
        buffer[s.len] = 0;
    } else if (comptime use_libssh) {
        _ = vssh_libssh.version(buffer, buflen);
    } else {
        buffer[0] = 0;
    }
}

// ============================================================================
// 5. Unit Tests
// ============================================================================

extern fn curl_easy_init() callconv(.c) ?*Curl_easy;
extern fn curl_easy_cleanup(handle: ?*Curl_easy) callconv(.c) void;
extern fn curl_easy_setopt(handle: ?*Curl_easy, option: c_int, ...) callconv(.c) CURLcode;

test "Curl_quote_line trims leading and trailing whitespace" {
    var line1 = "   mkdir /tmp/foo   \t ".*;
    const res1 = Curl_quote_line(&line1);
    try std.testing.expectEqualStrings("mkdir /tmp/foo", std.mem.span(res1));

    var line2 = "\t  pwd\t".*;
    const res2 = Curl_quote_line(&line2);
    try std.testing.expectEqualStrings("pwd", std.mem.span(res2));
}

test "Curl_get_pathname parses unquoted, quoted, escaped, and homedir-relative paths" {
    var path: ?[*:0]u8 = null;

    var cmd1: ?[*:0]const u8 = "/var/log/syslog next_arg";
    try std.testing.expectEqual(CURLE_OK, Curl_get_pathname(&cmd1, &path, "/home/alice"));
    try std.testing.expect(path != null);
    try std.testing.expectEqualStrings("/var/log/syslog", std.mem.span(path.?));
    try std.testing.expectEqualStrings("next_arg", std.mem.span(cmd1.?));
    mem.free(path);
    path = null;

    var cmd2: ?[*:0]const u8 = "\"/home/alice/my docs/file\\\"1\\\\\\'a.txt\"  rest";
    try std.testing.expectEqual(CURLE_OK, Curl_get_pathname(&cmd2, &path, "/home/alice"));
    try std.testing.expect(path != null);
    try std.testing.expectEqualStrings("/home/alice/my docs/file\"1\\'a.txt", std.mem.span(path.?));
    try std.testing.expectEqualStrings("rest", std.mem.span(cmd2.?));
    mem.free(path);
    path = null;

    var cmd3: ?[*:0]const u8 = "/~/upload.bin";
    try std.testing.expectEqual(CURLE_OK, Curl_get_pathname(&cmd3, &path, "/home/bob"));
    try std.testing.expect(path != null);
    try std.testing.expectEqualStrings("/home/bob/upload.bin", std.mem.span(path.?));
    mem.free(path);
    path = null;

    var bad_cmd: ?[*:0]const u8 = "\"unterminated";
    try std.testing.expectEqual(CURLE_QUOTE_ERROR, Curl_get_pathname(&bad_cmd, &path, "/home/bob"));
}

test "Curl_ssh_range parses valid and invalid byte ranges" {
    const easy = curl_easy_init() orelse return error.OutOfMemory;
    defer curl_easy_cleanup(easy);

    var start: curl_off_t = 0;
    var size: curl_off_t = -1;

    try std.testing.expectEqual(CURLE_OK, Curl_ssh_range(easy, "100-199", 1000, &start, &size));
    try std.testing.expectEqual(@as(curl_off_t, 100), start);
    try std.testing.expectEqual(@as(curl_off_t, 100), size);

    start = 0;
    size = -1;
    try std.testing.expectEqual(CURLE_OK, Curl_ssh_range(easy, "500-", 1000, &start, &size));
    try std.testing.expectEqual(@as(curl_off_t, 500), start);
    try std.testing.expectEqual(@as(curl_off_t, 500), size);

    start = 0;
    size = -1;
    try std.testing.expectEqual(CURLE_OK, Curl_ssh_range(easy, "-250", 1000, &start, &size));
    try std.testing.expectEqual(@as(curl_off_t, 750), start);
    try std.testing.expectEqual(@as(curl_off_t, 250), size);

    try std.testing.expectEqual(CURLE_RANGE_ERROR, Curl_ssh_range(easy, "200-100", 1000, &start, &size));
    try std.testing.expectEqual(CURLE_RANGE_ERROR, Curl_ssh_range(easy, "-", 1000, &start, &size));
    try std.testing.expectEqual(CURLE_RANGE_ERROR, Curl_ssh_range(easy, "10-20extra", 1000, &start, &size));
}

test "CURLOPT_SSH_* options and version info with libssh2" {
    const easy = curl_easy_init() orelse return error.OutOfMemory;
    defer curl_easy_cleanup(easy);

    if (use_ssh) {
        try std.testing.expectEqual(CURLE_OK, curl_easy_setopt(easy, @intCast(setopt.CURLOPT_SSH_AUTH_TYPES), @as(c_long, 3)));
        try std.testing.expectEqual(CURLE_OK, curl_easy_setopt(easy, @intCast(setopt.CURLOPT_SSH_COMPRESSION), @as(c_long, 1)));
        try std.testing.expectEqual(CURLE_OK, curl_easy_setopt(easy, @intCast(setopt.CURLOPT_NEW_DIRECTORY_PERMS), @as(c_long, 0o750)));
        try std.testing.expectEqual(CURLE_BAD_FUNCTION_ARGUMENT, curl_easy_setopt(easy, @intCast(setopt.CURLOPT_NEW_DIRECTORY_PERMS), @as(c_long, 0o1777)));
        try std.testing.expectEqual(CURLE_OK, curl_easy_setopt(easy, @intCast(setopt.CURLOPT_SSH_PUBLIC_KEYFILE), "/tmp/id_rsa.pub"));
        try std.testing.expectEqual(CURLE_OK, curl_easy_setopt(easy, @intCast(setopt.CURLOPT_SSH_PRIVATE_KEYFILE), "/tmp/id_rsa"));
        try std.testing.expectEqual(CURLE_OK, curl_easy_setopt(easy, @intCast(setopt.CURLOPT_SSH_KNOWNHOSTS), "/tmp/known_hosts"));
        try std.testing.expectEqual(CURLE_OK, curl_easy_setopt(easy, @intCast(setopt.CURLOPT_SSH_HOST_PUBLIC_KEY_MD5), "0123456789abcdef0123456789abcdef"));
        try std.testing.expectEqual(CURLE_BAD_FUNCTION_ARGUMENT, curl_easy_setopt(easy, @intCast(setopt.CURLOPT_SSH_HOST_PUBLIC_KEY_MD5), "short"));
        try std.testing.expectEqual(CURLE_OK, curl_easy_setopt(easy, @intCast(setopt.CURLOPT_SSH_HOST_PUBLIC_KEY_SHA256), "aaaa"));

        var vbuf: [64]u8 = undefined;
        Curl_ssh_version(&vbuf, vbuf.len);
        if (use_libssh2) {
            try std.testing.expect(std.mem.startsWith(u8, std.mem.sliceTo(&vbuf, 0), "libssh2/"));
        } else if (use_libssh) {
            try std.testing.expect(std.mem.startsWith(u8, std.mem.sliceTo(&vbuf, 0), "libssh/"));
        }
    } else {
        try std.testing.expectEqual(setopt.CURLE_UNKNOWN_OPTION, curl_easy_setopt(easy, @intCast(setopt.CURLOPT_SSH_AUTH_TYPES), @as(c_long, 3)));
    }
}

test "ssh_conn and SSHPROTO teardown poisoning, key scrubbing, and errdefer quote path cleanup" {
    // 1. Verify errdefer in allocSftpQuotePaths frees first path if second path fails
    var p1: ?[*:0]u8 = null;
    var p2: ?[*:0]u8 = null;
    var bad_second: ?[*:0]const u8 = "/remote/src \"unterminated_dest";
    try std.testing.expectError(
        error.QuoteError,
        allocSftpQuotePaths(&bad_second, "/home/user", true, &p1, &p2),
    );
    try std.testing.expect(p1 == null);
    try std.testing.expect(p2 == null);

    // Valid two-path allocation succeeds
    var ok_two: ?[*:0]const u8 = "/~/src_file /remote/dst_file";
    try allocSftpQuotePaths(&ok_two, "/home/user", true, &p1, &p2);
    try std.testing.expect(p1 != null);
    try std.testing.expect(p2 != null);
    try std.testing.expectEqualStrings("/home/user/src_file", std.mem.span(p1.?));
    try std.testing.expectEqualStrings("/remote/dst_file", std.mem.span(p2.?));
    mem.free(p1);
    mem.free(p2);

    // 2. Verify ssh_conn_dtor scrubs rsa / rsa_pub and poisons freed ssh_conn
    const cb = struct {
        extern var Curl_cfree: mem.FreeCallback;
    };
    const expected_poison: u8 = switch (builtin.mode) {
        .Debug, .ReleaseSafe => 0xaa,
        .ReleaseFast, .ReleaseSmall => 0x00,
    };
    var poisoned_frees: usize = 0;
    var scrubbed_secrets: usize = 0;
    const TestHooks = struct {
        var poison_count: *usize = undefined;
        var scrub_count: *usize = undefined;
        var expected: u8 = 0xaa;
        var orig_free: mem.FreeCallback = undefined;
        fn freeFn(p: ?*anyopaque) callconv(.c) void {
            if (p) |non_null| {
                const bytes: [*]const u8 = @ptrCast(non_null);
                if (bytes[0] == expected and bytes[1] == expected) {
                    poison_count.* += 1;
                } else if (bytes[0] == 0 and bytes[1] == 0) {
                    scrub_count.* += 1;
                }
            }
            orig_free(p);
        }
    };
    TestHooks.poison_count = &poisoned_frees;
    TestHooks.scrub_count = &scrubbed_secrets;
    TestHooks.expected = expected_poison;
    TestHooks.orig_free = cb.Curl_cfree;
    cb.Curl_cfree = &TestHooks.freeFn;
    defer cb.Curl_cfree = TestHooks.orig_free;

    const conn_ptr: *ssh_conn = @ptrCast(@alignCast(mem.calloc(1, @sizeOf(ssh_conn)).?));
    conn_ptr.rsa = mem.strdup("/secret/path/id_ed25519");
    conn_ptr.rsa_pub = mem.strdup("/secret/path/id_ed25519.pub");
    conn_ptr.quote_path1 = mem.strdup("/remote/q1");
    ssh_conn_dtor("ssh", 3, conn_ptr);
    try std.testing.expect(poisoned_frees >= 1);
    try std.testing.expect(scrubbed_secrets >= 2);

    // 3. Verify ssh_easy_dtor cleans up buffers and poisons freed SSHPROTO
    const before_proto = poisoned_frees;
    const proto_ptr: *SSHPROTO = @ptrCast(@alignCast(mem.calloc(1, @sizeOf(SSHPROTO)).?));
    containers.curlx_dyn_init(&proto_ptr.readdir, DYN_PATH_MAX * 2);
    proto_ptr.path = mem.strdup("/remote/file");
    try allocSftpReaddirBuffers(proto_ptr);
    ssh_easy_dtor("ssh_easy", 8, proto_ptr);
    try std.testing.expect(poisoned_frees > before_proto);
}
