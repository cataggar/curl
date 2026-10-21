const std = @import("std");
const builtin = @import("builtin");
const backend_options = @import("backend_options");
const vssh = @import("vssh.zig");
const mem = @import("mem.zig");
const primitives = @import("primitives.zig");
const curlx_parse = @import("curlx_parse.zig");
const curlx_time_net = @import("curlx_time_net.zig");
const containers = @import("containers.zig");
const collections = @import("collections.zig");
const cookie_getinfo_trc = @import("cookie_getinfo_trc.zig");
const sendf = @import("sendf.zig");
const cfsocket_transfer = @import("cfsocket_transfer.zig");
const setopt = @import("setopt.zig");
const protocol_version_mime = @import("protocol_version_mime.zig");

const use_libssh = vssh.use_libssh;
const CURLcode = vssh.CURLcode;
const curl_off_t = vssh.curl_off_t;
const curl_prot_t = vssh.curl_prot_t;
const timediff_t = vssh.timediff_t;
const curl_socket_t = vssh.curl_socket_t;
const CURL_SOCKET_BAD = vssh.CURL_SOCKET_BAD;
const sshstate = vssh.sshstate;
const Curl_easy = vssh.Curl_easy;
const connectdata = vssh.connectdata;
const easy_pollset = vssh.easy_pollset;
const curl_khkey = vssh.curl_khkey;
const CURL_META_SSH_EASY = vssh.CURL_META_SSH_EASY;
const CURL_META_SSH_CONN = vssh.CURL_META_SSH_CONN;

const CURLE_OK: CURLcode = 0;
const CURLE_FAILED_INIT: CURLcode = 2;
const CURLE_COULDNT_CONNECT: CURLcode = 7;
const CURLE_REMOTE_ACCESS_DENIED: CURLcode = 9;
const CURLE_QUOTE_ERROR: CURLcode = 21;
const CURLE_UPLOAD_FAILED: CURLcode = 25;
const CURLE_OUT_OF_MEMORY: CURLcode = 27;
const CURLE_OPERATION_TIMEDOUT: CURLcode = 28;
const CURLE_FTP_COULDNT_USE_REST: CURLcode = 31;
const CURLE_RANGE_ERROR: CURLcode = 33;
const CURLE_BAD_DOWNLOAD_RESUME: CURLcode = 36;
const CURLE_ABORTED_BY_CALLBACK: CURLcode = 42;
const CURLE_BAD_FUNCTION_ARGUMENT: CURLcode = 43;
const CURLE_SEND_ERROR: CURLcode = 55;
const CURLE_RECV_ERROR: CURLcode = 56;
const CURLE_PEER_FAILED_VERIFICATION: CURLcode = 60;
const CURLE_LOGIN_DENIED: CURLcode = 67;
const CURLE_REMOTE_FILE_EXISTS: CURLcode = 73;
const CURLE_REMOTE_FILE_NOT_FOUND: CURLcode = 78;
const CURLE_SSH: CURLcode = 79;
const CURLE_AGAIN: CURLcode = 81;

const CURLPROTO_SCP: curl_prot_t = 1 << 4;
const CURLPROTO_SFTP: curl_prot_t = 1 << 5;

const CURLSSH_AUTH_PUBLICKEY: c_long = 1 << 0;
const CURLSSH_AUTH_PASSWORD: c_long = 1 << 1;
const CURLSSH_AUTH_KEYBOARD: c_long = 1 << 3;
const CURLSSH_AUTH_AGENT: c_long = 1 << 4;
const CURLSSH_AUTH_GSSAPI: c_long = 1 << 5;

const CURL_POLL_IN: c_int = 1;
const CURL_POLL_OUT: c_int = 2;
const FIRSTSOCKET: i8 = 0;
const TIMER_APPCONNECT: c_uint = 5;
const CLIENTWRITE_BODY: c_int = 1 << 0;
const CLIENTWRITE_HEADER: c_int = 1 << 1;

const REQ_IO_RECV: c_int = 1 << 0;
const REQ_IO_SEND: c_int = 1 << 1;

const CURL_SEEKFUNC_OK: c_int = 0;
const CURL_SEEKFUNC_CANTSEEK: c_int = 2;

const CURL_PATH_MAX: usize = 1024;

// libssh constants
const SSH_OK: c_int = 0;
const SSH_NO_ERROR: c_int = 0;
const SSH_ERROR: c_int = -1;
const SSH_AGAIN: c_int = -2;

const SSH_AUTH_SUCCESS: c_int = 0;
const SSH_AUTH_DENIED: c_int = 1;
const SSH_AUTH_PARTIAL: c_int = 2;
const SSH_AUTH_INFO: c_int = 3;
const SSH_AUTH_AGAIN: c_int = 4;
const SSH_AUTH_ERROR: c_int = -1;

const SSH_AUTH_METHOD_UNKNOWN: c_uint = 0x0000;
const SSH_AUTH_METHOD_NONE: c_uint = 0x0001;
const SSH_AUTH_METHOD_PASSWORD: c_uint = 0x0002;
const SSH_AUTH_METHOD_PUBLICKEY: c_uint = 0x0004;
const SSH_AUTH_METHOD_HOSTBASED: c_uint = 0x0008;
const SSH_AUTH_METHOD_INTERACTIVE: c_uint = 0x0010;
const SSH_AUTH_METHOD_GSSAPI_MIC: c_uint = 0x0020;

const SSH_READ_PENDING: c_int = 0x02;
const SSH_WRITE_PENDING: c_int = 0x08;

const SSH_OPTIONS_HOST: c_uint = 0;
const SSH_OPTIONS_PORT: c_uint = 1;
const SSH_OPTIONS_FD: c_uint = 3;
const SSH_OPTIONS_USER: c_uint = 4;
const SSH_OPTIONS_KNOWNHOSTS: c_uint = 8;
const SSH_OPTIONS_COMPRESSION: c_uint = 22;
const SSH_OPTIONS_GLOBAL_KNOWNHOSTS: c_uint = 35;

const SSH_PUBLICKEY_HASH_SHA1: c_uint = 0;
const SSH_PUBLICKEY_HASH_MD5: c_uint = 1;
const SSH_PUBLICKEY_HASH_SHA256: c_uint = 2;

const SSH_KEYTYPE_UNKNOWN: c_uint = 0;
const SSH_KEYTYPE_DSS: c_uint = 1;
const SSH_KEYTYPE_RSA: c_uint = 2;
const SSH_KEYTYPE_RSA1: c_uint = 3;
const SSH_KEYTYPE_ECDSA: c_uint = 4;
const SSH_KEYTYPE_ED25519: c_uint = 5;
const SSH_KEYTYPE_ECDSA_P256: c_uint = 8;
const SSH_KEYTYPE_ECDSA_P384: c_uint = 9;
const SSH_KEYTYPE_ECDSA_P521: c_uint = 10;

const SSH_KNOWN_HOSTS_ERROR: c_int = -2;
const SSH_KNOWN_HOSTS_NOT_FOUND: c_int = -1;
const SSH_KNOWN_HOSTS_UNKNOWN: c_int = 0;
const SSH_KNOWN_HOSTS_OK: c_int = 1;
const SSH_KNOWN_HOSTS_CHANGED: c_int = 2;
const SSH_KNOWN_HOSTS_OTHER: c_int = 3;

const SSH_SCP_WRITE: c_int = 0;
const SSH_SCP_READ: c_int = 1;

const SSH_SCP_REQUEST_NEWDIR: c_int = 1;
const SSH_SCP_REQUEST_NEWFILE: c_int = 2;
const SSH_SCP_REQUEST_EOF: c_int = 3;
const SSH_SCP_REQUEST_ENDDIR: c_int = 4;
const SSH_SCP_REQUEST_WARNING: c_int = 5;

const SSH_FX_OK: c_int = 0;
const SSH_FX_EOF: c_int = 1;
const SSH_FX_NO_SUCH_FILE: c_int = 2;
const SSH_FX_PERMISSION_DENIED: c_int = 3;
const SSH_FX_FAILURE: c_int = 4;
const SSH_FX_NO_SUCH_PATH: c_int = 10;
const SSH_FX_FILE_ALREADY_EXISTS: c_int = 11;
const SSH_FX_WRITE_PROTECT: c_int = 12;

const SSH_FILEXFER_ATTR_SIZE: u32 = 0x00000001;
const SSH_FILEXFER_ATTR_UIDGID: u32 = 0x00000002;
const SSH_FILEXFER_ATTR_PERMISSIONS: u32 = 0x00000004;
const SSH_FILEXFER_ATTR_ACMODTIME: u32 = 0x00000008;

const SSH_S_IFMT: u32 = 0o0170000;
const SSH_S_IFLNK: u32 = 0o0120000;

const O_RDONLY: c_int = 0;
const O_WRONLY: c_int = 1;
const O_CREAT: c_int = if (builtin.os.tag == .macos) 0x0200 else if (builtin.os.tag == .windows) 0x0100 else 0o0100;
const O_TRUNC: c_int = if (builtin.os.tag == .macos) 0x0400 else if (builtin.os.tag == .windows) 0x0200 else 0o1000;
const O_APPEND: c_int = if (builtin.os.tag == .macos) 0x0008 else if (builtin.os.tag == .windows) 0x0008 else 0o2000;

pub const ssh_session_struct = opaque {};
pub const ssh_session = *ssh_session_struct;
pub const ssh_key_struct = opaque {};
pub const ssh_key = *ssh_key_struct;
pub const ssh_scp_struct = opaque {};
pub const ssh_scp = *ssh_scp_struct;
pub const sftp_session_struct = opaque {};
pub const sftp_session = *sftp_session_struct;
pub const sftp_file_struct = opaque {};
pub const sftp_file = *sftp_file_struct;
pub const sftp_dir_struct = opaque {};
pub const sftp_dir = *sftp_dir_struct;
pub const sftp_aio_struct = opaque {};
pub const sftp_aio = *sftp_aio_struct;
pub const ssh_string_struct = opaque {};
pub const ssh_string = *ssh_string_struct;

pub const ssh_knownhosts_entry = extern struct {
    hostname: ?[*:0]u8 = null,
    unparsed: ?[*:0]u8 = null,
    publickey: ?ssh_key = null,
    comment: ?[*:0]u8 = null,
};

pub const sftp_attributes_struct = extern struct {
    name: ?[*:0]u8 = null,
    longname: ?[*:0]u8 = null,
    flags: u32 = 0,
    type: u8 = 0,
    size: u64 = 0,
    uid: u32 = 0,
    gid: u32 = 0,
    owner: ?[*:0]u8 = null,
    group: ?[*:0]u8 = null,
    permissions: u32 = 0,
    atime64: u64 = 0,
    atime: u32 = 0,
    atime_nseconds: u32 = 0,
    createtime: u64 = 0,
    createtime_nseconds: u32 = 0,
    mtime64: u64 = 0,
    mtime: u32 = 0,
    mtime_nseconds: u32 = 0,
    acl: ?ssh_string = null,
    extended_count: u32 = 0,
    extended_type: ?ssh_string = null,
    extended_data: ?ssh_string = null,
};
pub const sftp_attributes = *sftp_attributes_struct;

pub const sftp_statvfs_struct = extern struct {
    f_bsize: u64 = 0,
    f_frsize: u64 = 0,
    f_blocks: u64 = 0,
    f_bfree: u64 = 0,
    f_bavail: u64 = 0,
    f_files: u64 = 0,
    f_ffree: u64 = 0,
    f_favail: u64 = 0,
    f_fsid: u64 = 0,
    f_flag: u64 = 0,
    f_namemax: u64 = 0,
};
pub const sftp_statvfs_t = *sftp_statvfs_struct;

pub const SSHPROTO_libssh = struct {
    path: ?[*:0]u8 = null,
};

pub const ssh_conn_libssh = struct {
    authlist: ?[*:0]const u8 = null,
    passphrase: ?[*:0]u8 = null,
    pub_key: ?[*:0]u8 = null,
    priv_key: ?[*:0]u8 = null,
    state: sshstate = .SSH_NO_STATE,
    nextstate: sshstate = .SSH_NO_STATE,
    quote_item: ?*vssh.curl_slist = null,
    quote_path1: ?[*:0]u8 = null,
    quote_path2: ?[*:0]u8 = null,
    homedir: ?[*:0]u8 = null,
    secondCreateDirs: c_int = 0,
    waitfor: c_int = 0,
    slash_pos: ?[*:0]u8 = null,
    actualcode: CURLcode = CURLE_OK,
    readdir_linkPath: ?[*:0]u8 = null,
    readdir_len: usize = 0,
    readdir_buf: containers.dynbuf = std.mem.zeroes(containers.dynbuf),
    kbd_state: c_uint = 0,
    privkey: ?ssh_key = null,
    pubkey: ?ssh_key = null,
    auth_methods: c_uint = 0,
    ssh_session: ?ssh_session = null,
    scp_session: ?ssh_scp = null,
    sftp_session: ?sftp_session = null,
    sftp_file: ?sftp_file = null,
    sftp_dir: ?sftp_dir = null,
    sftp_recv_state: c_uint = 0,
    sftp_recv_aio: ?sftp_aio = null,
    sftp_send_aio: ?sftp_aio = null,
    sftp_send_state: c_uint = 0,
    readdir_attrs: ?sftp_attributes = null,
    readdir_link_attrs: ?sftp_attributes = null,
    quote_attrs: ?sftp_attributes = null,
    readdir_filename: ?[*:0]const u8 = null,
    readdir_longentry: ?[*:0]const u8 = null,
    readdir_tmp: ?[*:0]u8 = null,
    initialized: bool = false,
    authed: bool = false,
    acceptfail: bool = false,
};

const Curl_meta_dtor = *const fn (key: ?*const anyopaque, key_len: usize, entry: ?*anyopaque) callconv(.c) void;
extern fn Curl_meta_set(data: *Curl_easy, key: [*:0]const u8, entry: ?*anyopaque, dtor: Curl_meta_dtor) callconv(.c) CURLcode;
extern fn Curl_meta_get(data: *const Curl_easy, key: [*:0]const u8) callconv(.c) ?*anyopaque;
extern fn Curl_conn_meta_set(conn: *connectdata, key: [*:0]const u8, entry: ?*anyopaque, dtor: Curl_meta_dtor) callconv(.c) CURLcode;
extern fn Curl_conn_meta_get(conn: *const connectdata, key: [*:0]const u8) callconv(.c) ?*anyopaque;

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
extern fn curl_msnprintf(buffer: [*]u8, maxlength: usize, format: [*:0]const u8, ...) callconv(.c) c_int;
extern fn curl_getenv(variable: [*:0]const u8) callconv(.c) ?[*:0]u8;
extern fn Curl_getdate_capped(p: ?[*:0]const u8, tp: *isize) callconv(.c) c_int;
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
extern fn Curl_pgrsCheck(data: *Curl_easy) callconv(.c) CURLcode;
extern fn Curl_pgrsDone(data: *Curl_easy) callconv(.c) c_int;

extern fn Curl_ftp_acc_get_conn(data: *Curl_easy) callconv(.c) ?*connectdata;
extern fn Curl_ftp_acc_get_upload(data: *Curl_easy) callconv(.c) bool;
extern fn Curl_ftp_acc_get_list_only(data: *Curl_easy) callconv(.c) bool;
extern fn Curl_ftp_acc_get_no_body(data: *Curl_easy) callconv(.c) bool;
extern fn Curl_ftp_acc_get_infilesize(data: *Curl_easy) callconv(.c) curl_off_t;
extern fn Curl_ftp_acc_set_infilesize(data: *Curl_easy, val: curl_off_t) callconv(.c) void;
extern fn Curl_ftp_acc_get_resume_from(data: *Curl_easy) callconv(.c) curl_off_t;
extern fn Curl_ftp_acc_set_resume_from(data: *Curl_easy, val: curl_off_t) callconv(.c) void;
extern fn Curl_ftp_acc_get_req_size(data: *Curl_easy) callconv(.c) curl_off_t;
extern fn Curl_ftp_acc_set_req_size(data: *Curl_easy, val: curl_off_t) callconv(.c) void;
extern fn Curl_http_acc_req_set_maxdownload(data: *Curl_easy, val: curl_off_t) callconv(.c) void;
extern fn Curl_ftp_acc_get_remote_append(data: *Curl_easy) callconv(.c) bool;
extern fn Curl_ftp_acc_get_ftp_create_missing_dirs(data: *Curl_easy) callconv(.c) u8;
extern fn Curl_ftp_acc_get_get_filetime(data: *Curl_easy) callconv(.c) bool;
extern fn Curl_ftp_acc_set_most_recent_ftp_entrypath(data: *Curl_easy, path: [*:0]const u8) callconv(.c) CURLcode;
extern fn Curl_ftp_acc_get_quote(data: *Curl_easy) callconv(.c) ?*vssh.curl_slist;
extern fn Curl_ftp_acc_get_postquote(data: *Curl_easy) callconv(.c) ?*vssh.curl_slist;
extern fn Curl_ftp_acc_connclose(conn: *connectdata) callconv(.c) void;
extern fn Curl_ftp_acc_has_seek_func(data: *Curl_easy) callconv(.c) bool;
extern fn Curl_ftp_acc_call_seek_func(data: *Curl_easy, offset: curl_off_t) callconv(.c) c_int;
extern fn Curl_ftp_acc_call_fread_func(data: *Curl_easy, buf: [*]u8, amount: usize) callconv(.c) usize;

extern fn Curl_easy_strset_ptr(data: *Curl_easy) callconv(.c) *collections.u8_strset;
extern fn Curl_setopt_get_i64(data: *const Curl_easy, field_id: c_int) callconv(.c) i64;
extern fn Curl_setopt_get_bit(data: *const Curl_easy, bit_id: c_int) callconv(.c) bool;
extern fn curlx_str_number(linep: *[*:0]const u8, nump: *i64, max: i64) callconv(.c) c_int;
extern fn curlx_str_octal(linep: *[*:0]const u8, nump: *i64, max: i64) callconv(.c) c_int;

inline fn Curl_setopt_get_str(data: *Curl_easy, idx: c_uint) ?[*:0]const u8 {
    return collections.Curl_u8_strset_get(Curl_easy_strset_ptr(data), @intCast(idx));
}

extern fn Curl_vssh_get_conn_user(conn: *const connectdata) callconv(.c) ?[*:0]const u8;
extern fn Curl_vssh_get_conn_passwd(conn: *const connectdata) callconv(.c) ?[*:0]const u8;
extern fn Curl_vssh_get_conn_host_name(conn: *const connectdata) callconv(.c) [*:0]const u8;
extern fn Curl_vssh_get_conn_remote_port(conn: *const connectdata) callconv(.c) c_int;
extern fn Curl_vssh_get_conn_firstsocket(conn: *const connectdata) callconv(.c) curl_socket_t;
extern fn Curl_vssh_get_conn_protocol(conn: *const connectdata) callconv(.c) curl_prot_t;
extern fn Curl_vssh_set_conn_send_recv(
    conn: *connectdata,
    send_fn: *const anyopaque,
    recv_fn: *const anyopaque,
) callconv(.c) void;
extern fn Curl_vssh_set_info_filetime(data: *Curl_easy, ft: curl_off_t) callconv(.c) void;
extern fn Curl_vssh_has_ssh_keyfunc(data: *const Curl_easy) callconv(.c) bool;
extern fn Curl_vssh_call_ssh_keyfunc(
    data: *Curl_easy,
    knownkey: ?*const curl_khkey,
    foundkey: *const curl_khkey,
    match: c_uint,
) callconv(.c) c_int;
extern fn Curl_vssh_get_req_io_flags(data: *const Curl_easy) callconv(.c) u8;
extern fn Curl_vssh_clear_req_io(data: *Curl_easy) callconv(.c) void;
extern fn Curl_vssh_set_conn_idx(conn: *connectdata, recv_idx: i8, send_idx: i8) callconv(.c) void;
extern fn Curl_vssh_get_conn_retry(conn: *const connectdata) callconv(.c) bool;
extern fn Curl_vssh_get_state_use_range(data: *const Curl_easy) callconv(.c) bool;
extern fn Curl_vssh_get_state_range(data: *const Curl_easy) callconv(.c) ?[*:0]const u8;
extern fn Curl_vssh_conn_forget_socket(data: *Curl_easy, sockindex: i8) callconv(.c) void;

// libssh C functions
extern fn ssh_init() callconv(.c) c_int;
extern fn ssh_finalize() callconv(.c) c_int;
extern fn ssh_version(req_version: c_int) callconv(.c) ?[*:0]const u8;
extern fn ssh_new() callconv(.c) ?ssh_session;
extern fn ssh_free(session: ssh_session) callconv(.c) void;
extern fn ssh_connect(session: ssh_session) callconv(.c) c_int;
extern fn ssh_disconnect(session: ssh_session) callconv(.c) void;
extern fn ssh_options_set(session: ssh_session, opt_type: c_uint, value: ?*const anyopaque) callconv(.c) c_int;
extern fn ssh_options_parse_config(session: ssh_session, filename: ?[*:0]const u8) callconv(.c) c_int;
extern fn ssh_set_blocking(session: ssh_session, blocking: c_int) callconv(.c) void;
extern fn ssh_get_poll_flags(session: ssh_session) callconv(.c) c_int;
extern fn ssh_get_error(error_obj: ?*anyopaque) callconv(.c) [*:0]const u8;
extern fn ssh_get_server_publickey(session: ssh_session, key: *?ssh_key) callconv(.c) c_int;
extern fn ssh_get_publickey_hash(
    key: ssh_key,
    hash_type: c_uint,
    hash: *?[*]u8,
    hlen: *usize,
) callconv(.c) c_int;
extern fn ssh_clean_pubkey_hash(hash: *?[*]u8) callconv(.c) void;
extern fn ssh_session_get_known_hosts_entry(
    session: ssh_session,
    pentry: *?*ssh_knownhosts_entry,
) callconv(.c) c_int;
extern fn ssh_knownhosts_entry_free(entry: ?*ssh_knownhosts_entry) callconv(.c) void;
extern fn ssh_session_update_known_hosts(session: ssh_session) callconv(.c) c_int;
extern fn ssh_pki_export_pubkey_base64(key: ssh_key, b64_key: *?[*:0]u8) callconv(.c) c_int;
extern fn ssh_pki_import_pubkey_file(filename: [*:0]const u8, pkey: *?ssh_key) callconv(.c) c_int;
extern fn ssh_pki_import_privkey_file(
    filename: [*:0]const u8,
    passphrase: ?[*:0]const u8,
    auth_fn: ?*const anyopaque,
    auth_data: ?*anyopaque,
    pkey: *?ssh_key,
) callconv(.c) c_int;
extern fn ssh_key_type(key: ssh_key) callconv(.c) c_uint;
extern fn ssh_key_free(key: ?ssh_key) callconv(.c) void;
extern fn ssh_string_free_char(s: ?[*:0]u8) callconv(.c) void;
extern fn ssh_userauth_none(session: ssh_session, username: ?[*:0]const u8) callconv(.c) c_int;
extern fn ssh_userauth_list(session: ssh_session, username: ?[*:0]const u8) callconv(.c) c_int;
extern fn ssh_userauth_try_publickey(session: ssh_session, username: ?[*:0]const u8, pubkey: ssh_key) callconv(.c) c_int;
extern fn ssh_userauth_publickey(session: ssh_session, username: ?[*:0]const u8, privkey: ssh_key) callconv(.c) c_int;
extern fn ssh_userauth_publickey_auto(
    session: ssh_session,
    username: ?[*:0]const u8,
    passphrase: ?[*:0]const u8,
) callconv(.c) c_int;
extern fn ssh_userauth_gssapi(session: ssh_session) callconv(.c) c_int;
extern fn ssh_userauth_kbdint(
    session: ssh_session,
    user: ?[*:0]const u8,
    submethods: ?[*:0]const u8,
) callconv(.c) c_int;
extern fn ssh_userauth_kbdint_getnprompts(session: ssh_session) callconv(.c) c_int;
extern fn ssh_userauth_kbdint_setanswer(
    session: ssh_session,
    i: c_uint,
    answer: [*:0]const u8,
) callconv(.c) c_int;
extern fn ssh_userauth_password(
    session: ssh_session,
    username: ?[*:0]const u8,
    password: [*:0]const u8,
) callconv(.c) c_int;

extern fn ssh_scp_new(session: ssh_session, mode: c_int, location: [*:0]const u8) callconv(.c) ?ssh_scp;
extern fn ssh_scp_init(scp: ssh_scp) callconv(.c) c_int;
extern fn ssh_scp_close(scp: ssh_scp) callconv(.c) c_int;
extern fn ssh_scp_free(scp: ssh_scp) callconv(.c) void;
extern fn ssh_scp_push_file64(scp: ssh_scp, filename: [*:0]const u8, size: u64, mode: c_int) callconv(.c) c_int;
extern fn ssh_scp_pull_request(scp: ssh_scp) callconv(.c) c_int;
extern fn ssh_scp_request_get_size64(scp: ssh_scp) callconv(.c) u64;
extern fn ssh_scp_write(scp: ssh_scp, buffer: *const anyopaque, size: usize) callconv(.c) c_int;
extern fn ssh_scp_read(scp: ssh_scp, buffer: *anyopaque, size: usize) callconv(.c) c_int;

extern fn sftp_new(session: ssh_session) callconv(.c) ?sftp_session;
extern fn sftp_free(sftp: sftp_session) callconv(.c) void;
extern fn sftp_init(sftp: sftp_session) callconv(.c) c_int;
extern fn sftp_get_error(sftp: sftp_session) callconv(.c) c_int;
extern fn sftp_canonicalize_path(sftp: sftp_session, path: [*:0]const u8) callconv(.c) ?[*:0]u8;
extern fn sftp_opendir(sftp: sftp_session, path: [*:0]const u8) callconv(.c) ?sftp_dir;
extern fn sftp_readdir(sftp: sftp_session, dir: sftp_dir) callconv(.c) ?sftp_attributes;
extern fn sftp_dir_eof(dir: sftp_dir) callconv(.c) c_int;
extern fn sftp_closedir(dir: sftp_dir) callconv(.c) c_int;
extern fn sftp_attributes_free(file: sftp_attributes) callconv(.c) void;
extern fn sftp_stat(sftp: sftp_session, path: [*:0]const u8) callconv(.c) ?sftp_attributes;
extern fn sftp_lstat(sftp: sftp_session, path: [*:0]const u8) callconv(.c) ?sftp_attributes;
extern fn sftp_fstat(file: sftp_file) callconv(.c) ?sftp_attributes;
extern fn sftp_setstat(sftp: sftp_session, file: [*:0]const u8, attr: sftp_attributes) callconv(.c) c_int;
extern fn sftp_readlink(sftp: sftp_session, path: [*:0]const u8) callconv(.c) ?[*:0]u8;
extern fn sftp_symlink(sftp: sftp_session, to: [*:0]const u8, from: [*:0]const u8) callconv(.c) c_int;
extern fn sftp_mkdir(sftp: sftp_session, directory: [*:0]const u8, mode: u32) callconv(.c) c_int;
extern fn sftp_rename(sftp: sftp_session, original: [*:0]const u8, newname: [*:0]const u8) callconv(.c) c_int;
extern fn sftp_rmdir(sftp: sftp_session, directory: [*:0]const u8) callconv(.c) c_int;
extern fn sftp_unlink(sftp: sftp_session, file: [*:0]const u8) callconv(.c) c_int;
extern fn sftp_statvfs(sftp: sftp_session, path: [*:0]const u8) callconv(.c) ?sftp_statvfs_t;
extern fn sftp_statvfs_free(statvfs_o: sftp_statvfs_t) callconv(.c) void;
extern fn sftp_open(sftp: sftp_session, file: [*:0]const u8, accesstype: c_int, mode: u32) callconv(.c) ?sftp_file;
extern fn sftp_close(file: sftp_file) callconv(.c) c_int;
extern fn sftp_file_set_nonblocking(handle: sftp_file) callconv(.c) void;
extern fn sftp_seek64(file: sftp_file, new_offset: u64) callconv(.c) c_int;
extern fn sftp_aio_free(aio: ?sftp_aio) callconv(.c) void;
extern fn sftp_aio_begin_read(file: sftp_file, len: usize, aio: *?sftp_aio) callconv(.c) isize;
extern fn sftp_aio_wait_read(aio: *?sftp_aio, buf: *anyopaque, buf_size: usize) callconv(.c) isize;
extern fn sftp_aio_begin_write(file: sftp_file, buf: *const anyopaque, len: usize, aio: *?sftp_aio) callconv(.c) isize;
extern fn sftp_aio_wait_write(aio: *?sftp_aio) callconv(.c) isize;

const STRING_SSH_PRIVATE_KEY = setopt.STRING_SSH_PRIVATE_KEY;
const STRING_SSH_PUBLIC_KEY = setopt.STRING_SSH_PUBLIC_KEY;
const STRING_SSH_HOST_PUBLIC_KEY_MD5 = setopt.STRING_SSH_HOST_PUBLIC_KEY_MD5;
const STRING_SSH_HOST_PUBLIC_KEY_SHA256 = setopt.STRING_SSH_HOST_PUBLIC_KEY_SHA256;
const STRING_SSH_KNOWNHOSTS = setopt.STRING_SSH_KNOWNHOSTS;
const STRING_KEY_PASSWD = setopt.STRING_KEY_PASSWD;

extern fn Curl_setopt_trc_bind_is_verbose(data: *Curl_easy) callconv(.c) bool;

fn trcSshEnabled(data: ?*Curl_easy) bool {
    const d = data orelse return false;
    return Curl_setopt_trc_bind_is_verbose(d) and
        cookie_getinfo_trc.Curl_trc_feat_ssh.log_level >= cookie_getinfo_trc.CURL_LOG_LVL_INFO;
}

fn myssh_to(data: *Curl_easy, sshc: *ssh_conn_libssh, nowstate: sshstate) void {
    const oldstate = sshc.state;
    if (oldstate != nowstate) {
        if (trcSshEnabled(data)) {
            Curl_trc_feat_infof(
                data,
                &cookie_getinfo_trc.Curl_trc_feat_ssh,
                "[%s] -> [%s]",
                vssh.Curl_ssh_statename(oldstate),
                vssh.Curl_ssh_statename(nowstate),
            );
        }
    }
    sshc.state = nowstate;
}

fn sftpErrorToCurle(err: c_int) CURLcode {
    return switch (err) {
        SSH_FX_OK => CURLE_OK,
        SSH_FX_NO_SUCH_FILE, SSH_FX_NO_SUCH_PATH => CURLE_REMOTE_FILE_NOT_FOUND,
        SSH_FX_PERMISSION_DENIED, SSH_FX_WRITE_PROTECT => CURLE_REMOTE_ACCESS_DENIED,
        SSH_FX_FILE_ALREADY_EXISTS => CURLE_REMOTE_FILE_EXISTS,
        else => CURLE_SSH,
    };
}

fn myssh_to_ERROR(data: *Curl_easy, sshc: *ssh_conn_libssh, result: CURLcode) c_int {
    myssh_to(data, sshc, .SSH_SESSION_DISCONNECT);
    sshc.actualcode = result;
    return SSH_ERROR;
}

fn myssh_to_SFTP_CLOSE(data: *Curl_easy, sshc: *ssh_conn_libssh) c_int {
    myssh_to(data, sshc, .SSH_SFTP_CLOSE);
    sshc.actualcode = if (sshc.sftp_session) |sftp|
        sftpErrorToCurle(sftp_get_error(sftp))
    else
        CURLE_SSH;
    return SSH_ERROR;
}

fn myssh_to_PASSWD_AUTH(data: *Curl_easy, sshc: *ssh_conn_libssh) c_int {
    if ((sshc.auth_methods & SSH_AUTH_METHOD_PASSWORD) != 0) {
        myssh_to(data, sshc, .SSH_AUTH_PASS_INIT);
        return SSH_OK;
    }
    return myssh_to_ERROR(data, sshc, CURLE_LOGIN_DENIED);
}

fn myssh_to_KEY_AUTH(data: *Curl_easy, sshc: *ssh_conn_libssh) c_int {
    if ((sshc.auth_methods & SSH_AUTH_METHOD_INTERACTIVE) != 0) {
        myssh_to(data, sshc, .SSH_AUTH_KEY_INIT);
        return SSH_OK;
    }
    return myssh_to_PASSWD_AUTH(data, sshc);
}

fn myssh_to_GSSAPI_AUTH(data: *Curl_easy, sshc: *ssh_conn_libssh) c_int {
    if ((sshc.auth_methods & SSH_AUTH_METHOD_GSSAPI_MIC) != 0) {
        myssh_to(data, sshc, .SSH_AUTH_GSSAPI);
        return SSH_OK;
    }
    return myssh_to_KEY_AUTH(data, sshc);
}

fn mapSshKeyType(kt: c_uint) ?c_uint {
    return switch (kt) {
        SSH_KEYTYPE_RSA => vssh.CURLKHTYPE_RSA,
        SSH_KEYTYPE_RSA1 => vssh.CURLKHTYPE_RSA1,
        SSH_KEYTYPE_ECDSA, SSH_KEYTYPE_ECDSA_P256, SSH_KEYTYPE_ECDSA_P384, SSH_KEYTYPE_ECDSA_P521 => vssh.CURLKHTYPE_ECDSA,
        SSH_KEYTYPE_ED25519 => vssh.CURLKHTYPE_ED25519,
        SSH_KEYTYPE_DSS => vssh.CURLKHTYPE_DSS,
        else => null,
    };
}

fn myssh_is_known(data: *Curl_easy, sshc: *ssh_conn_libssh) c_int {
    const session = sshc.ssh_session orelse return SSH_ERROR;
    var pubkey_opt: ?ssh_key = null;
    var rc = ssh_get_server_publickey(session, &pubkey_opt);
    if (rc != SSH_OK or pubkey_opt == null) return rc;
    const pubkey = pubkey_opt.?;

    var hash_sha256: ?[*]u8 = null;
    var hlen_sha256: usize = 0;
    var hash_md5: ?[*]u8 = null;
    var hlen_md5: usize = 0;
    var found_base64: ?[*:0]u8 = null;
    var known_base64: ?[*:0]u8 = null;
    var knownhostsentry: ?*ssh_knownhosts_entry = null;

    defer {
        if (found_base64) |p| std.c.free(p);
        if (known_base64) |p| std.c.free(p);
        if (hash_sha256 != null) ssh_clean_pubkey_hash(&hash_sha256);
        if (hash_md5 != null) ssh_clean_pubkey_hash(&hash_md5);
        ssh_key_free(pubkey);
        if (knownhostsentry) |e| ssh_knownhosts_entry_free(e);
    }

    if (Curl_setopt_get_str(data, STRING_SSH_HOST_PUBLIC_KEY_SHA256)) |pubkey_sha256| {
        var fingerprint_b64: ?[*:0]u8 = null;
        var fingerprint_b64_len: usize = 0;

        rc = ssh_get_publickey_hash(pubkey, SSH_PUBLICKEY_HASH_SHA256, &hash_sha256, &hlen_sha256);
        if (rc != SSH_OK or hlen_sha256 != 32 or hash_sha256 == null) {
            Curl_failf(data, "Denied establishing ssh session: SHA256 fingerprint not available");
            return rc;
        }

        if (curlx_parse.curlx_base64_encode(hash_sha256.?, 32, &fingerprint_b64, &fingerprint_b64_len) != CURLE_OK or fingerprint_b64 == null) {
            return SSH_ERROR;
        }
        defer mem.free(fingerprint_b64);

        const fb64 = fingerprint_b64.?;
        Curl_infof(data, "SSH SHA256 fingerprint: %s", fb64);

        var pub_pos: usize = 0;
        while (pubkey_sha256[pub_pos] != 0 and pubkey_sha256[pub_pos] != '=') : (pub_pos += 1) {}
        var b64_pos: usize = 0;
        while (fb64[b64_pos] != 0 and fb64[b64_pos] != '=') : (b64_pos += 1) {}

        if (pub_pos != b64_pos or !std.mem.eql(u8, fb64[0..b64_pos], pubkey_sha256[0..pub_pos])) {
            Curl_failf(
                data,
                "Denied establishing ssh session: mismatch SHA256 fingerprint. Remote %s is not equal to %s",
                fb64,
                pubkey_sha256,
            );
            return SSH_ERROR;
        }
        return SSH_OK;
    }

    if (Curl_setopt_get_str(data, STRING_SSH_HOST_PUBLIC_KEY_MD5)) |pubkey_md5| {
        rc = ssh_get_publickey_hash(pubkey, SSH_PUBLICKEY_HASH_MD5, &hash_md5, &hlen_md5);
        if (rc != SSH_OK or hlen_md5 != 16 or hash_md5 == null) {
            Curl_failf(data, "Denied establishing ssh session: MD5 fingerprint not available");
            return rc;
        }
        var md5buffer: [33]u8 = undefined;
        const hex = "0123456789abcdef";
        const h = hash_md5.?;
        for (0..16) |i| {
            md5buffer[i * 2] = hex[h[i] >> 4];
            md5buffer[i * 2 + 1] = hex[h[i] & 0x0f];
        }
        md5buffer[32] = 0;
        const md5_cstr: [*:0]const u8 = md5buffer[0..32 :0];
        Curl_infof(data, "SSH MD5 fingerprint: %s", md5_cstr);

        if (primitives.curl_strequal(md5_cstr, pubkey_md5) == 0) {
            Curl_failf(
                data,
                "Denied establishing ssh session: mismatch MD5 fingerprint. Remote %s is not equal to %s",
                md5_cstr,
                pubkey_md5,
            );
            return SSH_ERROR;
        }
        return SSH_OK;
    }

    if (Curl_setopt_get_str(data, STRING_SSH_KNOWNHOSTS) != null) {
        var knownkey: curl_khkey = .{ .key = null, .len = 0, .keytype = vssh.CURLKHTYPE_UNKNOWN };
        var knownkeyp: ?*const curl_khkey = null;

        const vstate = ssh_session_get_known_hosts_entry(session, &knownhostsentry);
        if (knownhostsentry) |entry| {
            if (entry.publickey) |ekey| {
                rc = ssh_pki_export_pubkey_base64(ekey, &known_base64);
                if (rc != SSH_OK or known_base64 == null) return rc;
                knownkey.key = known_base64;
                knownkey.len = std.mem.len(known_base64.?);
                knownkey.keytype = mapSshKeyType(ssh_key_type(ekey)) orelse return SSH_ERROR;
                knownkeyp = &knownkey;
            }
        }

        const keymatch: c_uint = switch (vstate) {
            SSH_KNOWN_HOSTS_OK => vssh.CURLKHMATCH_OK,
            SSH_KNOWN_HOSTS_OTHER => vssh.CURLKHMATCH_MISMATCH,
            SSH_KNOWN_HOSTS_NOT_FOUND, SSH_KNOWN_HOSTS_UNKNOWN, SSH_KNOWN_HOSTS_ERROR => vssh.CURLKHMATCH_MISSING,
            else => vssh.CURLKHMATCH_MISMATCH,
        };

        if (Curl_vssh_has_ssh_keyfunc(data)) {
            rc = ssh_pki_export_pubkey_base64(pubkey, &found_base64);
            if (rc != SSH_OK or found_base64 == null) return rc;
            const foundkey = curl_khkey{
                .key = found_base64,
                .len = std.mem.len(found_base64.?),
                .keytype = mapSshKeyType(ssh_key_type(pubkey)) orelse return SSH_ERROR,
            };

            const cb_rc = Curl_vssh_call_ssh_keyfunc(data, knownkeyp, &foundkey, keymatch);
            switch (cb_rc) {
                vssh.CURLKHSTAT_FINE_ADD_TO_FILE => {
                    rc = ssh_session_update_known_hosts(session);
                    if (rc != SSH_OK) return rc;
                },
                vssh.CURLKHSTAT_FINE => {},
                else => return SSH_ERROR,
            }
        } else {
            if (keymatch != vssh.CURLKHMATCH_OK) return SSH_ERROR;
        }
    }
    return SSH_OK;
}

fn myssh_in_SFTP_READDIR_INIT(data: *Curl_easy, sshc: *ssh_conn_libssh, sshp: *SSHPROTO_libssh) c_int {
    Curl_pgrsSetDownloadSize(data, -1);
    if (Curl_ftp_acc_get_no_body(data)) {
        myssh_to(data, sshc, .SSH_STOP);
        return SSH_NO_ERROR;
    }

    sshc.sftp_dir = sftp_opendir(sshc.sftp_session.?, sshp.path orelse "/");
    if (sshc.sftp_dir == null) {
        Curl_failf(data, "Could not open directory for reading: %s", ssh_get_error(@ptrCast(sshc.ssh_session)));
        return myssh_to_SFTP_CLOSE(data, sshc);
    }
    myssh_to(data, sshc, .SSH_SFTP_READDIR);
    return SSH_NO_ERROR;
}

fn myssh_in_SFTP_READDIR(data: *Curl_easy, sshc: *ssh_conn_libssh, sshp: *SSHPROTO_libssh) c_int {
    containers.curlx_dyn_reset(&sshc.readdir_buf);
    if (sshc.readdir_attrs) |attrs| {
        sftp_attributes_free(attrs);
        sshc.readdir_attrs = null;
    }

    sshc.readdir_attrs = sftp_readdir(sshc.sftp_session.?, sshc.sftp_dir.?);
    if (sshc.readdir_attrs) |attrs| {
        sshc.readdir_filename = attrs.name;
        sshc.readdir_longentry = attrs.longname;
        const fname = sshc.readdir_filename orelse "";
        sshc.readdir_len = std.mem.len(fname);

        if (Curl_ftp_acc_get_list_only(data)) {
            const tmpLine = curl_maprintf("%s\n", fname);
            if (tmpLine == null) {
                myssh_to(data, sshc, .SSH_SFTP_CLOSE);
                sshc.actualcode = CURLE_OUT_OF_MEMORY;
                return SSH_ERROR;
            }
            defer mem.free(tmpLine);
            const result = sendf.Curl_client_write(@ptrCast(data), CLIENTWRITE_BODY, tmpLine.?, sshc.readdir_len + 1);
            if (result != CURLE_OK) {
                myssh_to(data, sshc, .SSH_STOP);
                sshc.actualcode = result;
                return SSH_NO_ERROR;
            }
        } else {
            const longentry = sshc.readdir_longentry orelse fname;
            if (containers.curlx_dyn_add(&sshc.readdir_buf, longentry) != CURLE_OK) {
                sshc.actualcode = CURLE_OUT_OF_MEMORY;
                myssh_to(data, sshc, .SSH_STOP);
                return SSH_ERROR;
            }

            if ((attrs.flags & SSH_FILEXFER_ATTR_PERMISSIONS) != 0 and
                (attrs.permissions & SSH_S_IFMT) == SSH_S_IFLNK)
            {
                sshc.readdir_linkPath = curl_maprintf("%s%s", sshp.path orelse "", fname);
                if (sshc.readdir_linkPath == null) {
                    myssh_to(data, sshc, .SSH_SFTP_CLOSE);
                    sshc.actualcode = CURLE_OUT_OF_MEMORY;
                    return SSH_ERROR;
                }
                myssh_to(data, sshc, .SSH_SFTP_READDIR_LINK);
                return SSH_NO_ERROR;
            }
            myssh_to(data, sshc, .SSH_SFTP_READDIR_BOTTOM);
            return SSH_NO_ERROR;
        }
    } else if (sftp_dir_eof(sshc.sftp_dir.?) != 0) {
        myssh_to(data, sshc, .SSH_SFTP_READDIR_DONE);
    } else {
        Curl_failf(data, "Could not open remote directory for reading: %s", ssh_get_error(@ptrCast(sshc.ssh_session)));
        return myssh_to_SFTP_CLOSE(data, sshc);
    }
    return SSH_NO_ERROR;
}

fn myssh_in_SFTP_READDIR_LINK(data: *Curl_easy, sshc: *ssh_conn_libssh) c_int {
    if (sshc.readdir_link_attrs) |attrs| {
        sftp_attributes_free(attrs);
        sshc.readdir_link_attrs = null;
    }

    const link_path = sshc.readdir_linkPath orelse "";
    sshc.readdir_link_attrs = sftp_lstat(sshc.sftp_session.?, link_path);
    if (sshc.readdir_link_attrs == null) {
        Curl_failf(data, "Could not read symlink for reading: %s", ssh_get_error(@ptrCast(sshc.ssh_session)));
        return myssh_to_SFTP_CLOSE(data, sshc);
    }

    const link_attrs = sshc.readdir_link_attrs.?;
    if (link_attrs.name == null) {
        sshc.readdir_tmp = sftp_readlink(sshc.sftp_session.?, link_path);
        if (sshc.readdir_tmp) |tmp| {
            sshc.readdir_len = std.mem.len(tmp);
        } else {
            sshc.readdir_len = 0;
        }
        sshc.readdir_longentry = null;
        sshc.readdir_filename = sshc.readdir_tmp;
    } else {
        sshc.readdir_len = std.mem.len(link_attrs.name.?);
        sshc.readdir_filename = link_attrs.name;
        sshc.readdir_longentry = link_attrs.longname;
    }

    if (sshc.readdir_linkPath) |lp| {
        mem.free(lp);
        sshc.readdir_linkPath = null;
    }

    if (containers.curlx_dyn_addn(&sshc.readdir_buf, " -> ", 4) != CURLE_OK or
        containers.curlx_dyn_add(&sshc.readdir_buf, sshc.readdir_filename orelse "") != CURLE_OK)
    {
        myssh_to(data, sshc, .SSH_SFTP_CLOSE);
        sshc.actualcode = CURLE_OUT_OF_MEMORY;
        return SSH_ERROR;
    }

    sftp_attributes_free(link_attrs);
    sshc.readdir_link_attrs = null;
    sshc.readdir_filename = null;
    sshc.readdir_longentry = null;

    myssh_to(data, sshc, .SSH_SFTP_READDIR_BOTTOM);
    return SSH_NO_ERROR;
}

fn myssh_in_SFTP_READDIR_BOTTOM(data: *Curl_easy, sshc: *ssh_conn_libssh) c_int {
    var result: CURLcode = CURLE_OK;
    if (containers.curlx_dyn_addn(&sshc.readdir_buf, "\n", 1) != CURLE_OK) {
        result = CURLE_OUT_OF_MEMORY;
    } else if (containers.curlx_dyn_ptr(&sshc.readdir_buf)) |ptr| {
        result = sendf.Curl_client_write(
            @ptrCast(data),
            CLIENTWRITE_BODY,
            ptr,
            containers.curlx_dyn_len(&sshc.readdir_buf),
        );
    }

    if (sshc.readdir_tmp) |tmp| {
        ssh_string_free_char(tmp);
        sshc.readdir_tmp = null;
    }

    if (result != CURLE_OK) {
        myssh_to(data, sshc, .SSH_STOP);
        sshc.actualcode = result;
    } else {
        myssh_to(data, sshc, .SSH_SFTP_READDIR);
    }
    return SSH_NO_ERROR;
}

fn myssh_in_SFTP_READDIR_DONE(data: *Curl_easy, sshc: *ssh_conn_libssh) c_int {
    if (sshc.sftp_dir) |dir| {
        _ = sftp_closedir(dir);
        sshc.sftp_dir = null;
    }
    cfsocket_transfer.Curl_xfer_setup_nop(@ptrCast(data));
    myssh_to(data, sshc, .SSH_STOP);
    return SSH_NO_ERROR;
}

fn myssh_quote_error(data: *Curl_easy, sshc: *ssh_conn_libssh, cmd: ?[*:0]const u8) void {
    if (cmd) |c| {
        Curl_failf(data, "%s command failed: %s", c, ssh_get_error(@ptrCast(sshc.ssh_session)));
    }
    if (sshc.quote_path1) |p| {
        mem.free(p);
        sshc.quote_path1 = null;
    }
    if (sshc.quote_path2) |p| {
        mem.free(p);
        sshc.quote_path2 = null;
    }
    myssh_to(data, sshc, .SSH_SFTP_CLOSE);
    sshc.nextstate = .SSH_NO_STATE;
    sshc.actualcode = CURLE_QUOTE_ERROR;
}

fn myssh_in_SFTP_QUOTE_STATVFS(data: *Curl_easy, sshc: *ssh_conn_libssh) c_int {
    const statvfs = sftp_statvfs(sshc.sftp_session.?, sshc.quote_path1 orelse "");
    if (statvfs == null and !sshc.acceptfail) {
        myssh_quote_error(data, sshc, "statvfs");
        return SSH_OK;
    } else if (statvfs) |svfs| {
        defer sftp_statvfs_free(svfs);
        var result: CURLcode = CURLE_OK;
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
                "f_flag: %llu\n" ++
                "f_namemax: %llu\n",
            @as(c_ulonglong, svfs.f_bsize),
            @as(c_ulonglong, svfs.f_frsize),
            @as(c_ulonglong, svfs.f_blocks),
            @as(c_ulonglong, svfs.f_bfree),
            @as(c_ulonglong, svfs.f_bavail),
            @as(c_ulonglong, svfs.f_files),
            @as(c_ulonglong, svfs.f_ffree),
            @as(c_ulonglong, svfs.f_favail),
            @as(c_ulonglong, svfs.f_fsid),
            @as(c_ulonglong, svfs.f_flag),
            @as(c_ulonglong, svfs.f_namemax),
        );
        if (tmp == null) {
            result = CURLE_OUT_OF_MEMORY;
        } else {
            defer mem.free(tmp);
            result = sendf.Curl_client_write(@ptrCast(data), CLIENTWRITE_HEADER, tmp.?, std.mem.len(tmp.?));
        }
        if (result != CURLE_OK) {
            myssh_to(data, sshc, .SSH_SFTP_CLOSE);
            sshc.nextstate = .SSH_NO_STATE;
            sshc.actualcode = result;
            return SSH_OK;
        }
    }
    myssh_to(data, sshc, .SSH_SFTP_NEXT_QUOTE);
    return SSH_OK;
}

fn myssh_auth_interactive(conn: *connectdata, sshc: *ssh_conn_libssh) c_int {
    const session = sshc.ssh_session orelse return SSH_ERROR;
    while (true) {
        switch (sshc.kbd_state) {
            0 => {
                var rc = ssh_userauth_kbdint(session, null, null);
                if (rc == SSH_AUTH_AGAIN) return SSH_AGAIN;
                if (rc != SSH_AUTH_INFO) return SSH_ERROR;

                const nprompts = ssh_userauth_kbdint_getnprompts(session);
                if (nprompts != 1) return SSH_ERROR;

                rc = ssh_userauth_kbdint_setanswer(session, 0, Curl_vssh_get_conn_passwd(conn) orelse "");
                if (rc < 0) return SSH_ERROR;
                sshc.kbd_state = 1;
                continue;
            },
            1 => {
                const rc = ssh_userauth_kbdint(session, null, null);
                if (rc == SSH_AUTH_AGAIN) return SSH_AGAIN;
                if (rc == SSH_AUTH_SUCCESS) {
                    sshc.kbd_state = 0;
                    return SSH_OK;
                }
                if (rc == SSH_AUTH_INFO) {
                    const nprompts = ssh_userauth_kbdint_getnprompts(session);
                    if (nprompts != 0) return SSH_ERROR;
                    sshc.kbd_state = 2;
                    continue;
                }
                sshc.kbd_state = 0;
                return SSH_ERROR;
            },
            2 => {
                const rc = ssh_userauth_kbdint(session, null, null);
                if (rc == SSH_AUTH_AGAIN) return SSH_AGAIN;
                sshc.kbd_state = 0;
                return if (rc == SSH_AUTH_SUCCESS) SSH_OK else SSH_ERROR;
            },
            else => return SSH_ERROR,
        }
    }
}

fn myssh_state_init(data: *Curl_easy, sshc: *ssh_conn_libssh) void {
    sshc.secondCreateDirs = 0;
    sshc.nextstate = .SSH_NO_STATE;
    sshc.actualcode = CURLE_OK;
    if (sshc.ssh_session) |s| {
        ssh_set_blocking(s, 0);
    }
    myssh_to(data, sshc, .SSH_S_STARTUP);
}

fn myssh_block2waitfor(sshc: *ssh_conn_libssh, block: bool) void {
    if (block) {
        if (sshc.ssh_session) |s| {
            const dir = ssh_get_poll_flags(s);
            sshc.waitfor =
                (if ((dir & SSH_READ_PENDING) != 0) REQ_IO_RECV else 0) |
                (if ((dir & SSH_WRITE_PENDING) != 0) REQ_IO_SEND else 0);
            return;
        }
    }
    sshc.waitfor = 0;
}

fn myssh_in_S_STARTUP(data: *Curl_easy, sshc: *ssh_conn_libssh) c_int {
    const rc = ssh_connect(sshc.ssh_session.?);
    myssh_block2waitfor(sshc, rc == SSH_AGAIN);
    if (rc == SSH_AGAIN) {
        if (trcSshEnabled(data)) {
            Curl_trc_feat_infof(data, &cookie_getinfo_trc.Curl_trc_feat_ssh, "connect -> EAGAIN");
        }
        return rc;
    } else if (rc != SSH_OK) {
        Curl_failf(data, "Failure establishing ssh session");
        return myssh_to_ERROR(data, sshc, CURLE_FAILED_INIT);
    }
    myssh_to(data, sshc, .SSH_HOSTKEY);
    return rc;
}

fn myssh_in_AUTHLIST(data: *Curl_easy, sshc: *ssh_conn_libssh) c_int {
    sshc.authed = false;
    const session = sshc.ssh_session.?;
    const rc = ssh_userauth_none(session, null);
    if (rc == SSH_AUTH_AGAIN) return SSH_AGAIN;
    if (rc == SSH_AUTH_SUCCESS) {
        sshc.authed = true;
        Curl_infof(data, "Authenticated with none");
        myssh_to(data, sshc, .SSH_AUTH_DONE);
        return rc;
    } else if (rc == SSH_AUTH_ERROR) {
        return myssh_to_ERROR(data, sshc, CURLE_LOGIN_DENIED);
    }

    sshc.auth_methods = @bitCast(ssh_userauth_list(session, null));
    if (sshc.auth_methods != 0) {
        const pk: [*:0]const u8 = if ((sshc.auth_methods & SSH_AUTH_METHOD_PUBLICKEY) != 0) "public key, " else "";
        const gss: [*:0]const u8 = if ((sshc.auth_methods & SSH_AUTH_METHOD_GSSAPI_MIC) != 0) "GSSAPI, " else "";
        const kbd: [*:0]const u8 = if ((sshc.auth_methods & SSH_AUTH_METHOD_INTERACTIVE) != 0) "keyboard-interactive, " else "";
        const pw: [*:0]const u8 = if ((sshc.auth_methods & SSH_AUTH_METHOD_PASSWORD) != 0) "password" else "";
        Curl_infof(data, "SSH authentication methods available: %s%s%s%s", pk, gss, kbd, pw);
    }

    const auth_types: c_long = @intCast(Curl_setopt_get_i64(data, 54));
    const has_priv = sshc.priv_key != null and sshc.priv_key.?[0] != 0;
    if ((sshc.auth_methods & SSH_AUTH_METHOD_PUBLICKEY) != 0 and
        (has_priv or (auth_types & CURLSSH_AUTH_AGENT) != 0))
    {
        myssh_to(data, sshc, .SSH_AUTH_PKEY_INIT);
        Curl_infof(data, "Authentication using SSH public key file");
    } else if ((sshc.auth_methods & SSH_AUTH_METHOD_GSSAPI_MIC) != 0) {
        myssh_to(data, sshc, .SSH_AUTH_GSSAPI);
    } else if ((sshc.auth_methods & SSH_AUTH_METHOD_INTERACTIVE) != 0) {
        myssh_to(data, sshc, .SSH_AUTH_KEY_INIT);
    } else if ((sshc.auth_methods & SSH_AUTH_METHOD_PASSWORD) != 0) {
        myssh_to(data, sshc, .SSH_AUTH_PASS_INIT);
    } else {
        return myssh_to_ERROR(data, sshc, CURLE_LOGIN_DENIED);
    }
    return rc;
}

fn myssh_in_AUTH_PKEY_INIT(data: *Curl_easy, sshc: *ssh_conn_libssh) c_int {
    const auth_types: c_long = @intCast(Curl_setopt_get_i64(data, 54));
    if ((auth_types & CURLSSH_AUTH_PUBLICKEY) == 0) {
        return myssh_to_GSSAPI_AUTH(data, sshc);
    }

    const session = sshc.ssh_session.?;
    if (sshc.priv_key) |pk| {
        if (pk[0] != 0) {
            if (sshc.pubkey != null and sshc.passphrase == null) {
                const rc = ssh_userauth_try_publickey(session, null, sshc.pubkey.?);
                if (rc == SSH_AUTH_AGAIN) return SSH_AGAIN;
                if (rc != SSH_OK) return myssh_to_GSSAPI_AUTH(data, sshc);
            }

            const rc = ssh_pki_import_privkey_file(pk, sshc.passphrase, null, null, &sshc.privkey);
            if (rc != SSH_OK) {
                Curl_failf(data, "Could not load private key file %s", pk);
                return myssh_to_ERROR(data, sshc, CURLE_LOGIN_DENIED);
            }
            myssh_to(data, sshc, .SSH_AUTH_PKEY);
            return SSH_OK;
        }
    }

    const rc = ssh_userauth_publickey_auto(session, null, sshc.passphrase);
    if (rc == SSH_AUTH_AGAIN) return SSH_AGAIN;
    if (rc == SSH_AUTH_SUCCESS) {
        sshc.authed = true;
        Curl_infof(data, "Completed public key authentication");
        myssh_to(data, sshc, .SSH_AUTH_DONE);
        return SSH_OK;
    }
    return myssh_to_GSSAPI_AUTH(data, sshc);
}

fn myssh_in_AUTH_PKEY(data: *Curl_easy, sshc: *ssh_conn_libssh) c_int {
    const rc = ssh_userauth_publickey(sshc.ssh_session.?, null, sshc.privkey.?);
    if (rc == SSH_AUTH_AGAIN) return SSH_AGAIN;
    if (rc == SSH_AUTH_SUCCESS) {
        sshc.authed = true;
        Curl_infof(data, "Completed public key authentication");
        myssh_to(data, sshc, .SSH_AUTH_DONE);
        return SSH_OK;
    }
    Curl_infof(data, "Failed public key authentication (rc: %d)", rc);
    return myssh_to_GSSAPI_AUTH(data, sshc);
}

fn myssh_in_AUTH_GSSAPI(data: *Curl_easy, sshc: *ssh_conn_libssh) c_int {
    const auth_types: c_long = @intCast(Curl_setopt_get_i64(data, 54));
    if ((auth_types & CURLSSH_AUTH_GSSAPI) == 0) {
        return myssh_to_KEY_AUTH(data, sshc);
    }
    const rc = ssh_userauth_gssapi(sshc.ssh_session.?);
    if (rc == SSH_AUTH_AGAIN) return SSH_AGAIN;
    if (rc == SSH_AUTH_SUCCESS) {
        sshc.authed = true;
        Curl_infof(data, "Completed gssapi authentication");
        myssh_to(data, sshc, .SSH_AUTH_DONE);
        return SSH_OK;
    }
    return myssh_to_KEY_AUTH(data, sshc);
}

fn myssh_in_AUTH_KEY_INIT(data: *Curl_easy, sshc: *ssh_conn_libssh) c_int {
    const auth_types: c_long = @intCast(Curl_setopt_get_i64(data, 54));
    if ((auth_types & CURLSSH_AUTH_KEYBOARD) != 0) {
        myssh_to(data, sshc, .SSH_AUTH_KEY);
        return SSH_NO_ERROR;
    }
    return myssh_to_PASSWD_AUTH(data, sshc);
}

fn myssh_in_AUTH_KEY(data: *Curl_easy, sshc: *ssh_conn_libssh) c_int {
    const conn = Curl_ftp_acc_get_conn(data) orelse return SSH_ERROR;
    const rc = myssh_auth_interactive(conn, sshc);
    if (rc == SSH_AGAIN) return rc;
    if (rc == SSH_OK) {
        sshc.authed = true;
        Curl_infof(data, "completed keyboard interactive authentication");
        myssh_to(data, sshc, .SSH_AUTH_DONE);
        return SSH_NO_ERROR;
    }
    return myssh_to_PASSWD_AUTH(data, sshc);
}

fn myssh_in_AUTH_PASS_INIT(data: *Curl_easy, sshc: *ssh_conn_libssh) c_int {
    const auth_types: c_long = @intCast(Curl_setopt_get_i64(data, 54));
    if ((auth_types & CURLSSH_AUTH_PASSWORD) == 0) {
        return myssh_to_ERROR(data, sshc, CURLE_LOGIN_DENIED);
    }
    myssh_to(data, sshc, .SSH_AUTH_PASS);
    return SSH_NO_ERROR;
}

fn myssh_in_AUTH_PASS(data: *Curl_easy, sshc: *ssh_conn_libssh) c_int {
    const conn = Curl_ftp_acc_get_conn(data) orelse return SSH_ERROR;
    const rc = ssh_userauth_password(sshc.ssh_session.?, null, Curl_vssh_get_conn_passwd(conn) orelse "");
    if (rc == SSH_AUTH_AGAIN) return SSH_AGAIN;
    if (rc == SSH_AUTH_SUCCESS) {
        sshc.authed = true;
        Curl_infof(data, "Completed password authentication");
        myssh_to(data, sshc, .SSH_AUTH_DONE);
        return SSH_NO_ERROR;
    }
    return myssh_to_ERROR(data, sshc, CURLE_LOGIN_DENIED);
}

fn myssh_in_AUTH_DONE(data: *Curl_easy, sshc: *ssh_conn_libssh) c_int {
    const conn = Curl_ftp_acc_get_conn(data) orelse return SSH_ERROR;
    if (!sshc.authed) {
        Curl_failf(data, "Authentication failure");
        return myssh_to_ERROR(data, sshc, CURLE_LOGIN_DENIED);
    }
    Curl_infof(data, "Authentication complete");
    Curl_pgrsTime(data, TIMER_APPCONNECT);
    Curl_vssh_set_conn_idx(conn, FIRSTSOCKET, -1);

    if (Curl_vssh_get_conn_protocol(conn) == CURLPROTO_SFTP) {
        myssh_to(data, sshc, .SSH_SFTP_INIT);
        return SSH_NO_ERROR;
    }
    Curl_infof(data, "SSH CONNECT phase done");
    myssh_to(data, sshc, .SSH_STOP);
    return SSH_NO_ERROR;
}

fn myssh_in_UPLOAD_INIT(data: *Curl_easy, sshc: *ssh_conn_libssh, sshp: *SSHPROTO_libssh) c_int {
    const conn = Curl_ftp_acc_get_conn(data) orelse return myssh_to_ERROR(data, sshc, CURLE_FAILED_INIT);
    var rf = Curl_ftp_acc_get_resume_from(data);
    if (rf != 0) {
        if (rf < 0) {
            const attrs = sftp_stat(sshc.sftp_session.?, sshp.path orelse "");
            if (attrs) |a| {
                const size: curl_off_t = @intCast(a.size);
                sftp_attributes_free(a);
                if (size < 0) {
                    Curl_failf(data, "Bad file size (%lld)", @as(c_longlong, size));
                    return myssh_to_ERROR(data, sshc, CURLE_BAD_DOWNLOAD_RESUME);
                }
                rf = size;
                Curl_ftp_acc_set_resume_from(data, rf);
            } else {
                rf = 0;
                Curl_ftp_acc_set_resume_from(data, 0);
            }
        }
    }

    const flags: c_int = if (Curl_ftp_acc_get_remote_append(data))
        (O_WRONLY | O_CREAT | O_APPEND)
    else if (rf > 0)
        O_WRONLY
    else
        (O_WRONLY | O_CREAT | O_TRUNC);

    if (sshc.sftp_file) |f| {
        _ = sftp_close(f);
        sshc.sftp_file = null;
    }
    const file_perms: u32 = @intCast(Curl_setopt_get_i64(data, 51));
    const path = sshp.path orelse "";
    sshc.sftp_file = sftp_open(sshc.sftp_session.?, path, flags, file_perms);
    if (sshc.sftp_file == null) {
        const err = sftp_get_error(sshc.sftp_session.?);
        if ((err == SSH_FX_NO_SUCH_FILE or err == SSH_FX_FAILURE or err == SSH_FX_NO_SUCH_PATH) and
            Curl_ftp_acc_get_ftp_create_missing_dirs(data) != 0 and
            std.mem.len(path) > 1)
        {
            sshc.secondCreateDirs = 1;
            myssh_to(data, sshc, .SSH_SFTP_CREATE_DIRS_INIT);
            return 0;
        }
        return myssh_to_SFTP_CLOSE(data, sshc);
    }

    if (rf > 0 and !Curl_ftp_acc_get_remote_append(data)) {
        var seekerr: c_int = CURL_SEEKFUNC_OK;
        if (Curl_ftp_acc_has_seek_func(data)) {
            seekerr = Curl_ftp_acc_call_seek_func(data, rf);
        }
        if (seekerr != CURL_SEEKFUNC_OK) {
            if (seekerr != CURL_SEEKFUNC_CANTSEEK) {
                Curl_failf(data, "Could not seek stream");
                return myssh_to_ERROR(data, sshc, CURLE_FTP_COULDNT_USE_REST);
            }
            var passed: curl_off_t = 0;
            var scratch: [4 * 1024]u8 = undefined;
            while (passed < rf) {
                const rem: usize = @intCast(rf - passed);
                const readthisamountnow = @min(rem, scratch.len);
                const actuallyread = Curl_ftp_acc_call_fread_func(data, &scratch, readthisamountnow);
                passed += @intCast(actuallyread);
                if (actuallyread == 0 or actuallyread > readthisamountnow) {
                    Curl_failf(data, "Failed to read data");
                    return myssh_to_ERROR(data, sshc, CURLE_FTP_COULDNT_USE_REST);
                }
            }
        }

        const infilesize = Curl_ftp_acc_get_infilesize(data);
        if (infilesize > 0) {
            if (rf > infilesize) {
                Curl_failf(data, "Resume point beyond size");
                return myssh_to_ERROR(data, sshc, CURLE_BAD_FUNCTION_ARGUMENT);
            }
            const new_size = infilesize - rf;
            Curl_ftp_acc_set_infilesize(data, new_size);
            Curl_ftp_acc_set_req_size(data, new_size);
            Curl_pgrsSetUploadSize(data, new_size);
        }

        if (sftp_seek64(sshc.sftp_file.?, @intCast(rf)) != 0) {
            return myssh_to_SFTP_CLOSE(data, sshc);
        }
    }

    const infilesize = Curl_ftp_acc_get_infilesize(data);
    if (infilesize > 0) {
        Curl_ftp_acc_set_req_size(data, infilesize);
        Curl_pgrsSetUploadSize(data, infilesize);
    }
    cfsocket_transfer.Curl_xfer_setup_send(@ptrCast(data), FIRSTSOCKET);
    Curl_vssh_set_conn_idx(conn, FIRSTSOCKET, 0);
    Curl_multi_mark_dirty(data);
    sshc.sftp_send_state = 0;
    myssh_to(data, sshc, .SSH_STOP);
    return 0;
}

fn myssh_in_SFTP_DOWNLOAD_INIT(data: *Curl_easy, sshc: *ssh_conn_libssh, sshp: *SSHPROTO_libssh) c_int {
    if (sshc.sftp_file) |f| {
        _ = sftp_close(f);
        sshc.sftp_file = null;
    }
    const file_perms: u32 = @intCast(Curl_setopt_get_i64(data, 51));
    sshc.sftp_file = sftp_open(sshc.sftp_session.?, sshp.path orelse "", O_RDONLY, file_perms);
    if (sshc.sftp_file == null) {
        Curl_failf(data, "Could not open remote file for reading: %s", ssh_get_error(@ptrCast(sshc.ssh_session)));
        return myssh_to_SFTP_CLOSE(data, sshc);
    }
    sftp_file_set_nonblocking(sshc.sftp_file.?);
    myssh_to(data, sshc, .SSH_SFTP_DOWNLOAD_STAT);
    return SSH_NO_ERROR;
}

fn myssh_in_SFTP_DOWNLOAD_STAT(data: *Curl_easy, sshc: *ssh_conn_libssh) c_int {
    const conn = Curl_ftp_acc_get_conn(data) orelse return myssh_to_ERROR(data, sshc, CURLE_FAILED_INIT);
    var size: curl_off_t = 0;
    const attrs = sftp_fstat(sshc.sftp_file.?);
    if (attrs == null or (attrs.?.flags & SSH_FILEXFER_ATTR_SIZE) == 0 or attrs.?.size == 0) {
        Curl_ftp_acc_set_req_size(data, -1);
        Curl_http_acc_req_set_maxdownload(data, -1);
        Curl_pgrsSetDownloadSize(data, -1);
        size = 0;
        if (attrs) |a| sftp_attributes_free(a);
    } else {
        size = @intCast(attrs.?.size);
        sftp_attributes_free(attrs.?);
        if (size < 0) {
            Curl_failf(data, "Bad file size (%lld)", @as(c_longlong, size));
            return myssh_to_ERROR(data, sshc, CURLE_BAD_DOWNLOAD_RESUME);
        }
        if (Curl_vssh_get_state_use_range(data)) {
            var from: curl_off_t = 0;
            var maxdl: curl_off_t = -1;
            const range_str = Curl_vssh_get_state_range(data) orelse "";
            const result = vssh.Curl_ssh_range(data, range_str, &from, &maxdl);
            if (result != CURLE_OK) {
                return myssh_to_ERROR(data, sshc, result);
            }
            if (from < 0) {
                if (-from > size) {
                    from = 0;
                } else {
                    from = size + from;
                    size = maxdl;
                }
            } else if (from > size) {
                Curl_failf(data, "Offset (%lld) was beyond file size (%lld)", @as(c_longlong, from), @as(c_longlong, size));
                return myssh_to_ERROR(data, sshc, CURLE_RANGE_ERROR);
            } else if (maxdl < 0 or from + maxdl > size) {
                size = size - from;
            } else {
                size = maxdl;
            }
            if (sftp_seek64(sshc.sftp_file.?, @intCast(from)) != 0) {
                return myssh_to_SFTP_CLOSE(data, sshc);
            }
        }
        Curl_ftp_acc_set_req_size(data, size);
        Curl_http_acc_req_set_maxdownload(data, size);
        Curl_pgrsSetDownloadSize(data, size);
    }

    var rf = Curl_ftp_acc_get_resume_from(data);
    if (rf != 0) {
        if (rf < 0) {
            if (size < -rf) {
                Curl_failf(
                    data,
                    "Offset (%lld) was beyond file size (%lld)",
                    @as(c_longlong, rf),
                    @as(c_longlong, size),
                );
                return myssh_to_ERROR(data, sshc, CURLE_BAD_DOWNLOAD_RESUME);
            }
            rf += size;
            Curl_ftp_acc_set_resume_from(data, rf);
        } else {
            if (size < rf) {
                Curl_failf(
                    data,
                    "Offset (%lld) was beyond file size (%lld)",
                    @as(c_longlong, rf),
                    @as(c_longlong, size),
                );
                return myssh_to_ERROR(data, sshc, CURLE_BAD_DOWNLOAD_RESUME);
            }
        }
        const rem_size = size - rf;
        Curl_ftp_acc_set_req_size(data, rem_size);
        Curl_http_acc_req_set_maxdownload(data, rem_size);
        Curl_pgrsSetDownloadSize(data, rem_size);
        if (sftp_seek64(sshc.sftp_file.?, @intCast(rf)) != 0) {
            return myssh_to_SFTP_CLOSE(data, sshc);
        }
    }

    const req_size = Curl_ftp_acc_get_req_size(data);
    if (req_size == 0) {
        cfsocket_transfer.Curl_xfer_setup_nop(@ptrCast(data));
        Curl_infof(data, "File already completely downloaded");
        myssh_to(data, sshc, .SSH_STOP);
        return 0;
    }
    cfsocket_transfer.Curl_xfer_setup_recv(@ptrCast(data), FIRSTSOCKET, req_size);
    Curl_vssh_set_conn_idx(conn, FIRSTSOCKET, 0);
    sshc.sftp_recv_state = 0;
    myssh_to(data, sshc, .SSH_STOP);
    return 0;
}

fn myssh_in_SFTP_CLOSE(data: *Curl_easy, sshc: *ssh_conn_libssh, sshp: *SSHPROTO_libssh) c_int {
    if (sshc.sftp_file) |f| {
        _ = sftp_close(f);
        sshc.sftp_file = null;
    }
    if (sshp.path) |p| {
        mem.free(p);
        sshp.path = null;
    }
    if (trcSshEnabled(data)) {
        Curl_trc_feat_infof(data, &cookie_getinfo_trc.Curl_trc_feat_ssh, "SFTP DONE done");
    }
    if (sshc.nextstate != .SSH_NO_STATE and sshc.nextstate != .SSH_SFTP_CLOSE) {
        myssh_to(data, sshc, sshc.nextstate);
        sshc.nextstate = .SSH_SFTP_CLOSE;
    } else {
        myssh_to(data, sshc, .SSH_STOP);
    }
    return SSH_NO_ERROR;
}

fn myssh_in_SFTP_SHUTDOWN(data: *Curl_easy, sshc: *ssh_conn_libssh) c_int {
    if (sshc.ssh_session) |s| {
        ssh_set_blocking(s, 0);
    }
    if (sshc.sftp_send_aio) |aio| {
        sftp_aio_free(aio);
        sshc.sftp_send_aio = null;
    }
    if (sshc.sftp_recv_aio) |aio| {
        sftp_aio_free(aio);
        sshc.sftp_recv_aio = null;
    }
    if (sshc.sftp_file) |f| {
        _ = sftp_close(f);
        sshc.sftp_file = null;
    }
    if (sshc.sftp_session) |sftp| {
        sftp_free(sftp);
        sshc.sftp_session = null;
    }
    if (sshc.homedir) |hd| {
        ssh_string_free_char(hd);
        sshc.homedir = null;
    }
    myssh_to(data, sshc, .SSH_SESSION_DISCONNECT);
    return SSH_NO_ERROR;
}

fn myssh_in_SFTP_INIT(data: *Curl_easy, sshc: *ssh_conn_libssh) c_int {
    const session = sshc.ssh_session.?;
    ssh_set_blocking(session, 1);
    sshc.sftp_session = sftp_new(session);
    if (sshc.sftp_session == null) {
        Curl_failf(data, "Failure initializing sftp session: %s", ssh_get_error(@ptrCast(session)));
        return myssh_to_ERROR(data, sshc, CURLE_COULDNT_CONNECT);
    }
    const rc = sftp_init(sshc.sftp_session.?);
    if (rc != SSH_OK) {
        Curl_failf(data, "Failure initializing sftp session: %s", ssh_get_error(@ptrCast(session)));
        return myssh_to_ERROR(data, sshc, sftpErrorToCurle(SSH_FX_FAILURE));
    }
    myssh_to(data, sshc, .SSH_SFTP_REALPATH);
    return SSH_NO_ERROR;
}

fn myssh_in_SFTP_REALPATH(data: *Curl_easy, sshc: *ssh_conn_libssh) c_int {
    sshc.homedir = sftp_canonicalize_path(sshc.sftp_session.?, ".");
    if (sshc.homedir == null) {
        return myssh_to_ERROR(data, sshc, CURLE_COULDNT_CONNECT);
    }
    if (Curl_ftp_acc_set_most_recent_ftp_entrypath(data, sshc.homedir.?) != CURLE_OK) {
        return myssh_to_ERROR(data, sshc, CURLE_OUT_OF_MEMORY);
    }
    if (trcSshEnabled(data)) {
        Curl_trc_feat_infof(data, &cookie_getinfo_trc.Curl_trc_feat_ssh, "CONNECT phase done");
    }
    myssh_to(data, sshc, .SSH_STOP);
    return SSH_NO_ERROR;
}

fn myssh_in_SFTP_QUOTE_INIT(data: *Curl_easy, sshc: *ssh_conn_libssh, sshp: *SSHPROTO_libssh) c_int {
    const result = vssh.Curl_getworkingpath(data, sshc.homedir orelse "", &sshp.path);
    if (result != CURLE_OK) {
        sshc.actualcode = result;
        myssh_to(data, sshc, .SSH_STOP);
    } else if (Curl_ftp_acc_get_quote(data)) |q| {
        Curl_infof(data, "Sending quote commands");
        sshc.quote_item = q;
        myssh_to(data, sshc, .SSH_SFTP_QUOTE);
    } else {
        myssh_to(data, sshc, .SSH_SFTP_GETINFO);
    }
    return SSH_NO_ERROR;
}

fn myssh_in_SFTP_POSTQUOTE_INIT(data: *Curl_easy, sshc: *ssh_conn_libssh) c_int {
    if (Curl_ftp_acc_get_postquote(data)) |pq| {
        Curl_infof(data, "Sending quote commands");
        sshc.quote_item = pq;
        myssh_to(data, sshc, .SSH_SFTP_QUOTE);
    } else {
        myssh_to(data, sshc, .SSH_STOP);
    }
    return SSH_NO_ERROR;
}

fn quote_error(data: *Curl_easy, sshc: *ssh_conn_libssh) c_int {
    Curl_failf(data, "Suspicious data after the command line");
    if (sshc.quote_path1) |p| {
        mem.free(p);
        sshc.quote_path1 = null;
    }
    if (sshc.quote_path2) |p| {
        mem.free(p);
        sshc.quote_path2 = null;
    }
    myssh_to(data, sshc, .SSH_SFTP_CLOSE);
    sshc.nextstate = .SSH_NO_STATE;
    sshc.actualcode = CURLE_QUOTE_ERROR;
    return SSH_NO_ERROR;
}

fn myssh_in_SFTP_QUOTE(data: *Curl_easy, sshc: *ssh_conn_libssh, sshp: *SSHPROTO_libssh) c_int {
    const qi = sshc.quote_item orelse {
        myssh_to(data, sshc, .SSH_SFTP_GETINFO);
        return SSH_NO_ERROR;
    };
    var cmd: [*:0]const u8 = qi.data orelse "";
    sshc.acceptfail = false;

    if (cmd[0] == '*') {
        cmd += 1;
        sshc.acceptfail = true;
    }

    if (primitives.curl_strequal("pwd", cmd) != 0) {
        const tmp = curl_maprintf("257 \"%s\" is current directory.\n", sshp.path orelse "/");
        if (tmp == null) {
            sshc.actualcode = CURLE_OUT_OF_MEMORY;
            myssh_to(data, sshc, .SSH_SFTP_CLOSE);
            sshc.nextstate = .SSH_NO_STATE;
            return SSH_NO_ERROR;
        }
        defer mem.free(tmp);
        const result = sendf.Curl_client_write(@ptrCast(data), CLIENTWRITE_HEADER, tmp.?, std.mem.len(tmp.?));
        if (result != CURLE_OK) {
            myssh_to(data, sshc, .SSH_SFTP_CLOSE);
            sshc.nextstate = .SSH_NO_STATE;
            sshc.actualcode = result;
        } else {
            myssh_to(data, sshc, .SSH_SFTP_NEXT_QUOTE);
        }
        return SSH_NO_ERROR;
    }

    const cmd_slice = std.mem.span(cmd);
    const space_idx = std.mem.indexOfScalar(u8, cmd_slice, ' ') orelse {
        Curl_failf(data, "Syntax error in SFTP command. Supply parameter(s)");
        myssh_to(data, sshc, .SSH_SFTP_CLOSE);
        sshc.nextstate = .SSH_NO_STATE;
        sshc.actualcode = CURLE_QUOTE_ERROR;
        return SSH_NO_ERROR;
    };
    var cp: ?[*:0]const u8 = cmd + space_idx;
    const hdir = sshc.homedir orelse "";

    var result = vssh.Curl_get_pathname(&cp, &sshc.quote_path1, hdir);
    if (result != CURLE_OK) {
        if (result == CURLE_OUT_OF_MEMORY) {
            Curl_failf(data, "Out of memory");
        } else {
            Curl_failf(data, "Syntax error: Bad first parameter");
        }
        myssh_to(data, sshc, .SSH_SFTP_CLOSE);
        sshc.nextstate = .SSH_NO_STATE;
        sshc.actualcode = result;
        return SSH_NO_ERROR;
    }

    if (std.mem.startsWith(u8, cmd_slice, "chgrp ") or
        std.mem.startsWith(u8, cmd_slice, "chmod ") or
        std.mem.startsWith(u8, cmd_slice, "chown ") or
        std.mem.startsWith(u8, cmd_slice, "atime ") or
        std.mem.startsWith(u8, cmd_slice, "mtime "))
    {
        result = vssh.Curl_get_pathname(&cp, &sshc.quote_path2, hdir);
        if (result != CURLE_OK) {
            if (result == CURLE_OUT_OF_MEMORY) {
                Curl_failf(data, "Out of memory");
            } else {
                Curl_failf(data, "Syntax error in chgrp/chmod/chown/atime/mtime: Bad second parameter");
            }
            if (sshc.quote_path1) |p| {
                mem.free(p);
                sshc.quote_path1 = null;
            }
            myssh_to(data, sshc, .SSH_SFTP_CLOSE);
            sshc.nextstate = .SSH_NO_STATE;
            sshc.actualcode = result;
            return SSH_NO_ERROR;
        }
        if (cp != null and cp.?[0] != 0) return quote_error(data, sshc);
        if (sshc.quote_attrs) |a| {
            sftp_attributes_free(a);
            sshc.quote_attrs = null;
        }
        myssh_to(data, sshc, .SSH_SFTP_QUOTE_STAT);
        return SSH_NO_ERROR;
    }
    if (std.mem.startsWith(u8, cmd_slice, "ln ") or
        std.mem.startsWith(u8, cmd_slice, "symlink "))
    {
        result = vssh.Curl_get_pathname(&cp, &sshc.quote_path2, hdir);
        if (result != CURLE_OK) {
            if (result == CURLE_OUT_OF_MEMORY) {
                Curl_failf(data, "Out of memory");
            } else {
                Curl_failf(data, "Syntax error in ln/symlink: Bad second parameter");
            }
            if (sshc.quote_path1) |p| {
                mem.free(p);
                sshc.quote_path1 = null;
            }
            myssh_to(data, sshc, .SSH_SFTP_CLOSE);
            sshc.nextstate = .SSH_NO_STATE;
            sshc.actualcode = result;
            return SSH_NO_ERROR;
        }
        if (cp != null and cp.?[0] != 0) return quote_error(data, sshc);
        myssh_to(data, sshc, .SSH_SFTP_QUOTE_SYMLINK);
        return SSH_NO_ERROR;
    }
    if (std.mem.startsWith(u8, cmd_slice, "mkdir ")) {
        if (cp != null and cp.?[0] != 0) return quote_error(data, sshc);
        myssh_to(data, sshc, .SSH_SFTP_QUOTE_MKDIR);
        return SSH_NO_ERROR;
    }
    if (std.mem.startsWith(u8, cmd_slice, "rename ")) {
        result = vssh.Curl_get_pathname(&cp, &sshc.quote_path2, hdir);
        if (result != CURLE_OK) {
            if (result == CURLE_OUT_OF_MEMORY) {
                Curl_failf(data, "Out of memory");
            } else {
                Curl_failf(data, "Syntax error in rename: Bad second parameter");
            }
            if (sshc.quote_path1) |p| {
                mem.free(p);
                sshc.quote_path1 = null;
            }
            myssh_to(data, sshc, .SSH_SFTP_CLOSE);
            sshc.nextstate = .SSH_NO_STATE;
            sshc.actualcode = result;
            return SSH_NO_ERROR;
        }
        if (cp != null and cp.?[0] != 0) return quote_error(data, sshc);
        myssh_to(data, sshc, .SSH_SFTP_QUOTE_RENAME);
        return SSH_NO_ERROR;
    }
    if (std.mem.startsWith(u8, cmd_slice, "rmdir ")) {
        if (cp != null and cp.?[0] != 0) return quote_error(data, sshc);
        myssh_to(data, sshc, .SSH_SFTP_QUOTE_RMDIR);
        return SSH_NO_ERROR;
    }
    if (std.mem.startsWith(u8, cmd_slice, "rm ")) {
        if (cp != null and cp.?[0] != 0) return quote_error(data, sshc);
        myssh_to(data, sshc, .SSH_SFTP_QUOTE_UNLINK);
        return SSH_NO_ERROR;
    }
    if (std.mem.startsWith(u8, cmd_slice, "statvfs ")) {
        if (cp != null and cp.?[0] != 0) return quote_error(data, sshc);
        myssh_to(data, sshc, .SSH_SFTP_QUOTE_STATVFS);
        return SSH_NO_ERROR;
    }

    Curl_failf(data, "Unknown SFTP command");
    if (sshc.quote_path1) |p| {
        mem.free(p);
        sshc.quote_path1 = null;
    }
    if (sshc.quote_path2) |p| {
        mem.free(p);
        sshc.quote_path2 = null;
    }
    myssh_to(data, sshc, .SSH_SFTP_CLOSE);
    sshc.nextstate = .SSH_NO_STATE;
    sshc.actualcode = CURLE_QUOTE_ERROR;
    return SSH_NO_ERROR;
}

fn myssh_in_SFTP_NEXT_QUOTE(data: *Curl_easy, sshc: *ssh_conn_libssh) c_int {
    if (sshc.quote_path1) |p| {
        mem.free(p);
        sshc.quote_path1 = null;
    }
    if (sshc.quote_path2) |p| {
        mem.free(p);
        sshc.quote_path2 = null;
    }
    if (sshc.quote_item) |qi| {
        sshc.quote_item = qi.next;
    }
    if (sshc.quote_item != null) {
        myssh_to(data, sshc, .SSH_SFTP_QUOTE);
    } else if (sshc.nextstate != .SSH_NO_STATE) {
        myssh_to(data, sshc, sshc.nextstate);
        sshc.nextstate = .SSH_NO_STATE;
    } else {
        myssh_to(data, sshc, .SSH_SFTP_GETINFO);
    }
    return SSH_NO_ERROR;
}

fn myssh_in_SFTP_QUOTE_STAT(data: *Curl_easy, sshc: *ssh_conn_libssh) c_int {
    const qi = sshc.quote_item.?;
    var cmd: [*:0]const u8 = qi.data orelse "";
    sshc.acceptfail = false;
    if (cmd[0] == '*') {
        cmd += 1;
        sshc.acceptfail = true;
    }
    const cmd_slice = std.mem.span(cmd);

    if (sshc.quote_attrs) |a| {
        sftp_attributes_free(a);
        sshc.quote_attrs = null;
    }
    sshc.quote_attrs = sftp_stat(sshc.sftp_session.?, sshc.quote_path2 orelse "");
    if (sshc.quote_attrs == null) {
        Curl_failf(data, "Attempt to get SFTP stats failed: %d", sftp_get_error(sshc.sftp_session.?));
        myssh_quote_error(data, sshc, null);
        return SSH_NO_ERROR;
    }
    const attrs = sshc.quote_attrs.?;
    const p1 = sshc.quote_path1 orelse "";
    var p1_cur: [*:0]const u8 = p1;

    if (std.mem.startsWith(u8, cmd_slice, "chgrp")) {
        var gid: i64 = 0;
        if (curlx_str_number(&p1_cur, &gid, std.math.maxInt(u32)) != curlx_parse.STRE_OK) {
            Curl_failf(data, "Syntax error: chgrp gid not a number");
            myssh_quote_error(data, sshc, null);
            return SSH_NO_ERROR;
        }
        attrs.gid = @intCast(gid);
        attrs.flags |= SSH_FILEXFER_ATTR_UIDGID;
    } else if (std.mem.startsWith(u8, cmd_slice, "chmod")) {
        var perms: i64 = 0;
        if (curlx_str_octal(&p1_cur, &perms, 0o7777) != curlx_parse.STRE_OK) {
            Curl_failf(data, "Syntax error: chmod permissions not a number");
            myssh_quote_error(data, sshc, null);
            return SSH_NO_ERROR;
        }
        attrs.permissions = @intCast(perms);
        attrs.flags |= SSH_FILEXFER_ATTR_PERMISSIONS;
    } else if (std.mem.startsWith(u8, cmd_slice, "chown")) {
        var uid: i64 = 0;
        if (curlx_str_number(&p1_cur, &uid, std.math.maxInt(u32)) != curlx_parse.STRE_OK) {
            Curl_failf(data, "Syntax error: chown uid not a number");
            myssh_quote_error(data, sshc, null);
            return SSH_NO_ERROR;
        }
        attrs.uid = @intCast(uid);
        attrs.flags |= SSH_FILEXFER_ATTR_UIDGID;
    } else if (std.mem.startsWith(u8, cmd_slice, "atime") or std.mem.startsWith(u8, cmd_slice, "mtime")) {
        var date: isize = 0;
        var fail = false;
        if (Curl_getdate_capped(p1, &date) != 0) {
            Curl_failf(data, "incorrect date format for %.*s", @as(c_int, 5), cmd);
            fail = true;
        } else if (date > 0xffffffff or date < 0) {
            Curl_failf(data, "date overflow");
            fail = true;
        }
        if (fail) {
            myssh_quote_error(data, sshc, null);
            return SSH_NO_ERROR;
        }
        if (std.mem.startsWith(u8, cmd_slice, "atime")) {
            attrs.atime = @intCast(date);
        } else {
            attrs.mtime = @intCast(date);
        }
        attrs.flags |= SSH_FILEXFER_ATTR_ACMODTIME;
    }

    myssh_to(data, sshc, .SSH_SFTP_QUOTE_SETSTAT);
    return SSH_NO_ERROR;
}

fn myssh_in_SFTP_QUOTE_SETSTAT(data: *Curl_easy, sshc: *ssh_conn_libssh) c_int {
    const rc = sftp_setstat(sshc.sftp_session.?, sshc.quote_path2 orelse "", sshc.quote_attrs.?);
    if (rc == SSH_AGAIN) return rc;
    if (rc != 0 and !sshc.acceptfail) {
        myssh_quote_error(data, sshc, "setstat");
        return rc;
    }
    myssh_to(data, sshc, .SSH_SFTP_NEXT_QUOTE);
    return SSH_NO_ERROR;
}

fn myssh_in_SFTP_QUOTE_SYMLINK(data: *Curl_easy, sshc: *ssh_conn_libssh) c_int {
    const rc = sftp_symlink(sshc.sftp_session.?, sshc.quote_path2 orelse "", sshc.quote_path1 orelse "");
    if (rc == SSH_AGAIN) return rc;
    if (rc != 0 and !sshc.acceptfail) {
        myssh_quote_error(data, sshc, "symlink");
        return rc;
    }
    myssh_to(data, sshc, .SSH_SFTP_NEXT_QUOTE);
    return SSH_NO_ERROR;
}

fn myssh_in_SFTP_QUOTE_MKDIR(data: *Curl_easy, sshc: *ssh_conn_libssh) c_int {
    const dir_perms: u32 = @intCast(Curl_setopt_get_i64(data, 55));
    const rc = sftp_mkdir(sshc.sftp_session.?, sshc.quote_path1 orelse "", dir_perms);
    if (rc == SSH_AGAIN) return rc;
    if (rc != 0 and !sshc.acceptfail) {
        myssh_quote_error(data, sshc, "mkdir");
        return rc;
    }
    myssh_to(data, sshc, .SSH_SFTP_NEXT_QUOTE);
    return SSH_NO_ERROR;
}

fn myssh_in_SFTP_QUOTE_RENAME(data: *Curl_easy, sshc: *ssh_conn_libssh) c_int {
    const rc = sftp_rename(sshc.sftp_session.?, sshc.quote_path1 orelse "", sshc.quote_path2 orelse "");
    if (rc == SSH_AGAIN) return rc;
    if (rc != 0 and !sshc.acceptfail) {
        myssh_quote_error(data, sshc, "rename");
        return rc;
    }
    myssh_to(data, sshc, .SSH_SFTP_NEXT_QUOTE);
    return SSH_NO_ERROR;
}

fn myssh_in_SFTP_QUOTE_RMDIR(data: *Curl_easy, sshc: *ssh_conn_libssh) c_int {
    const rc = sftp_rmdir(sshc.sftp_session.?, sshc.quote_path1 orelse "");
    if (rc == SSH_AGAIN) return rc;
    if (rc != 0 and !sshc.acceptfail) {
        myssh_quote_error(data, sshc, "rmdir");
        return rc;
    }
    myssh_to(data, sshc, .SSH_SFTP_NEXT_QUOTE);
    return SSH_NO_ERROR;
}

fn myssh_in_SFTP_QUOTE_UNLINK(data: *Curl_easy, sshc: *ssh_conn_libssh) c_int {
    const rc = sftp_unlink(sshc.sftp_session.?, sshc.quote_path1 orelse "");
    if (rc == SSH_AGAIN) return rc;
    if (rc != 0 and !sshc.acceptfail) {
        myssh_quote_error(data, sshc, "rm");
        return rc;
    }
    myssh_to(data, sshc, .SSH_SFTP_NEXT_QUOTE);
    return SSH_NO_ERROR;
}

fn myssh_in_SFTP_GETINFO(data: *Curl_easy, sshc: *ssh_conn_libssh) c_int {
    if (Curl_ftp_acc_get_get_filetime(data)) {
        myssh_to(data, sshc, .SSH_SFTP_FILETIME);
    } else {
        myssh_to(data, sshc, .SSH_SFTP_TRANS_INIT);
    }
    return SSH_NO_ERROR;
}

fn myssh_in_SFTP_FILETIME(data: *Curl_easy, sshc: *ssh_conn_libssh, sshp: *SSHPROTO_libssh) c_int {
    if (sftp_stat(sshc.sftp_session.?, sshp.path orelse "")) |attrs| {
        Curl_vssh_set_info_filetime(data, @intCast(attrs.mtime));
        sftp_attributes_free(attrs);
    }
    myssh_to(data, sshc, .SSH_SFTP_TRANS_INIT);
    return SSH_NO_ERROR;
}

fn myssh_in_SFTP_TRANS_INIT(data: *Curl_easy, sshc: *ssh_conn_libssh, sshp: *SSHPROTO_libssh) c_int {
    if (Curl_ftp_acc_get_upload(data)) {
        myssh_to(data, sshc, .SSH_SFTP_UPLOAD_INIT);
    } else {
        const p = sshp.path orelse "";
        const len = std.mem.len(p);
        if (len > 0 and p[len - 1] == '/') {
            myssh_to(data, sshc, .SSH_SFTP_READDIR_INIT);
        } else {
            myssh_to(data, sshc, .SSH_SFTP_DOWNLOAD_INIT);
        }
    }
    return SSH_NO_ERROR;
}

fn myssh_in_SFTP_CREATE_DIRS_INIT(data: *Curl_easy, sshc: *ssh_conn_libssh, sshp: *SSHPROTO_libssh) c_int {
    if (sshp.path) |p| {
        if (std.mem.len(p) > 1) {
            sshc.slash_pos = p + 1;
            myssh_to(data, sshc, .SSH_SFTP_CREATE_DIRS);
            return SSH_NO_ERROR;
        }
    }
    myssh_to(data, sshc, .SSH_SFTP_UPLOAD_INIT);
    return SSH_NO_ERROR;
}

fn myssh_in_SFTP_CREATE_DIRS(data: *Curl_easy, sshc: *ssh_conn_libssh, sshp: *SSHPROTO_libssh) c_int {
    if (sshc.slash_pos) |sp| {
        if (std.mem.indexOfScalar(u8, std.mem.span(sp), '/')) |idx| {
            sshc.slash_pos = sp + idx;
            sshc.slash_pos.?[0] = 0;
            Curl_infof(data, "Creating directory '%s'", sshp.path orelse "");
            myssh_to(data, sshc, .SSH_SFTP_CREATE_DIRS_MKDIR);
            return SSH_NO_ERROR;
        }
    }
    sshc.slash_pos = null;
    myssh_to(data, sshc, .SSH_SFTP_UPLOAD_INIT);
    return SSH_NO_ERROR;
}

fn myssh_in_SFTP_CREATE_DIRS_MKDIR(data: *Curl_easy, sshc: *ssh_conn_libssh, sshp: *SSHPROTO_libssh) c_int {
    const dir_perms: u32 = @intCast(Curl_setopt_get_i64(data, 55));
    var rc = sftp_mkdir(sshc.sftp_session.?, sshp.path orelse "", dir_perms);
    if (rc == SSH_AGAIN) return rc;
    if (sshc.slash_pos) |sp| {
        sp[0] = '/';
        sshc.slash_pos = sp + 1;
    }
    if (rc < 0) {
        const err = sftp_get_error(sshc.sftp_session.?);
        if (err != SSH_FX_FILE_ALREADY_EXISTS and err != SSH_FX_FAILURE and err != SSH_FX_PERMISSION_DENIED) {
            return myssh_to_SFTP_CLOSE(data, sshc);
        }
        rc = 0;
    }
    myssh_to(data, sshc, .SSH_SFTP_CREATE_DIRS);
    return rc;
}

fn myssh_in_TRANS_INIT(data: *Curl_easy, sshc: *ssh_conn_libssh, sshp: *SSHPROTO_libssh) c_int {
    const result = vssh.Curl_getworkingpath(data, sshc.homedir orelse "", &sshp.path);
    if (result != CURLE_OK) {
        sshc.actualcode = result;
        myssh_to(data, sshc, .SSH_STOP);
        return 0;
    }

    const session = sshc.ssh_session.?;
    ssh_set_blocking(session, 1);

    if (Curl_ftp_acc_get_upload(data)) {
        if (Curl_ftp_acc_get_infilesize(data) < 0) {
            Curl_failf(data, "SCP requires a known file size for upload");
            return myssh_to_ERROR(data, sshc, CURLE_UPLOAD_FAILED);
        }
        sshc.scp_session = ssh_scp_new(session, SSH_SCP_WRITE, sshp.path orelse "");
        myssh_to(data, sshc, .SSH_SCP_UPLOAD_INIT);
    } else {
        sshc.scp_session = ssh_scp_new(session, SSH_SCP_READ, sshp.path orelse "");
        myssh_to(data, sshc, .SSH_SCP_DOWNLOAD_INIT);
    }

    if (sshc.scp_session == null) {
        Curl_failf(data, "%s", ssh_get_error(@ptrCast(session)));
        return myssh_to_ERROR(data, sshc, CURLE_UPLOAD_FAILED);
    }
    return 0;
}

fn myssh_in_SCP_UPLOAD_INIT(data: *Curl_easy, sshc: *ssh_conn_libssh, sshp: *SSHPROTO_libssh) c_int {
    const conn = Curl_ftp_acc_get_conn(data) orelse return myssh_to_ERROR(data, sshc, CURLE_FAILED_INIT);
    var rc = ssh_scp_init(sshc.scp_session.?);
    if (rc != SSH_OK) {
        Curl_failf(data, "%s", ssh_get_error(@ptrCast(sshc.ssh_session)));
        return myssh_to_ERROR(data, sshc, CURLE_UPLOAD_FAILED);
    }
    const file_perms: c_int = @intCast(Curl_setopt_get_i64(data, 51));
    rc = ssh_scp_push_file64(
        sshc.scp_session.?,
        sshp.path orelse "",
        @intCast(Curl_ftp_acc_get_infilesize(data)),
        file_perms,
    );
    if (rc != SSH_OK) {
        Curl_failf(data, "%s", ssh_get_error(@ptrCast(sshc.ssh_session)));
        return myssh_to_ERROR(data, sshc, CURLE_UPLOAD_FAILED);
    }
    cfsocket_transfer.Curl_xfer_setup_send(@ptrCast(data), FIRSTSOCKET);
    Curl_vssh_set_conn_idx(conn, FIRSTSOCKET, 0);
    myssh_to(data, sshc, .SSH_STOP);
    return SSH_NO_ERROR;
}

fn myssh_in_SCP_DOWNLOAD_INIT(data: *Curl_easy, sshc: *ssh_conn_libssh) c_int {
    const rc = ssh_scp_init(sshc.scp_session.?);
    if (rc != SSH_OK) {
        Curl_failf(data, "%s", ssh_get_error(@ptrCast(sshc.ssh_session)));
        return myssh_to_ERROR(data, sshc, CURLE_COULDNT_CONNECT);
    }
    myssh_to(data, sshc, .SSH_SCP_DOWNLOAD);
    return SSH_NO_ERROR;
}

fn myssh_SSH_SCP_DOWNLOAD(data: *Curl_easy, sshc: *ssh_conn_libssh) c_int {
    const conn = Curl_ftp_acc_get_conn(data) orelse return myssh_to_ERROR(data, sshc, CURLE_FAILED_INIT);
    const rc = ssh_scp_pull_request(sshc.scp_session.?);
    if (rc != SSH_SCP_REQUEST_NEWFILE) {
        Curl_failf(data, "%s", ssh_get_error(@ptrCast(sshc.ssh_session)));
        return myssh_to_ERROR(data, sshc, CURLE_REMOTE_FILE_NOT_FOUND);
    }
    const bytecount: curl_off_t = @intCast(ssh_scp_request_get_size64(sshc.scp_session.?));
    Curl_http_acc_req_set_maxdownload(data, bytecount);
    cfsocket_transfer.Curl_xfer_setup_recv(@ptrCast(data), FIRSTSOCKET, bytecount);
    Curl_vssh_set_conn_idx(conn, FIRSTSOCKET, 0);
    myssh_to(data, sshc, .SSH_STOP);
    return 0;
}

fn myssh_in_SCP_DONE(data: *Curl_easy, sshc: *ssh_conn_libssh) c_int {
    if (Curl_ftp_acc_get_upload(data)) {
        myssh_to(data, sshc, .SSH_SCP_SEND_EOF);
    } else {
        myssh_to(data, sshc, .SSH_SCP_CHANNEL_FREE);
    }
    return SSH_NO_ERROR;
}

fn myssh_in_SCP_SEND_EOF(data: *Curl_easy, sshc: *ssh_conn_libssh) c_int {
    if (sshc.scp_session) |scp| {
        const rc = ssh_scp_close(scp);
        if (rc == SSH_AGAIN) return SSH_AGAIN;
        if (rc != SSH_OK) {
            Curl_infof(data, "Failed to close libssh scp channel: %s", ssh_get_error(@ptrCast(sshc.ssh_session)));
        }
    }
    myssh_to(data, sshc, .SSH_SCP_CHANNEL_FREE);
    return SSH_NO_ERROR;
}

fn myssh_in_SCP_CHANNEL_FREE(data: *Curl_easy, sshc: *ssh_conn_libssh) void {
    if (sshc.scp_session) |scp| {
        ssh_scp_free(scp);
        sshc.scp_session = null;
    }
    if (trcSshEnabled(data)) {
        Curl_trc_feat_infof(data, &cookie_getinfo_trc.Curl_trc_feat_ssh, "SCP DONE phase complete");
    }
    if (sshc.ssh_session) |s| {
        ssh_set_blocking(s, 0);
    }
    myssh_to(data, sshc, .SSH_SESSION_DISCONNECT);
}

fn myssh_SESSION_DISCONNECT(data: *Curl_easy, sshc: *ssh_conn_libssh) void {
    if (sshc.scp_session) |scp| {
        ssh_scp_free(scp);
        sshc.scp_session = null;
    }
    if (sshc.sftp_file) |f| {
        _ = sftp_close(f);
        sshc.sftp_file = null;
    }
    if (sshc.sftp_session) |sftp| {
        sftp_free(sftp);
        sshc.sftp_session = null;
    }
    if (sshc.ssh_session) |s| {
        ssh_disconnect(s);
    }
    const ver_0_10_0 = (0 << 16) | (10 << 8) | 0;
    if (ssh_version(ver_0_10_0) == null) {
        Curl_vssh_conn_forget_socket(data, FIRSTSOCKET);
    }
    if (sshc.homedir) |hd| {
        ssh_string_free_char(hd);
        sshc.homedir = null;
    }
    myssh_to(data, sshc, .SSH_SESSION_FREE);
}

fn sshc_cleanup(sshc: *ssh_conn_libssh) void {
    if (sshc.initialized) {
        if (sshc.sftp_send_aio) |aio| {
            sftp_aio_free(aio);
            sshc.sftp_send_aio = null;
        }
        if (sshc.sftp_recv_aio) |aio| {
            sftp_aio_free(aio);
            sshc.sftp_recv_aio = null;
        }
        if (sshc.sftp_file) |f| {
            _ = sftp_close(f);
            sshc.sftp_file = null;
        }
        if (sshc.sftp_session) |sftp| {
            sftp_free(sftp);
            sshc.sftp_session = null;
        }
        if (sshc.ssh_session) |s| {
            ssh_free(s);
            sshc.ssh_session = null;
        }
        if (sshc.readdir_tmp) |tmp| {
            ssh_string_free_char(tmp);
            sshc.readdir_tmp = null;
        }
        if (sshc.quote_attrs) |a| {
            sftp_attributes_free(a);
            sshc.quote_attrs = null;
        }
        if (sshc.readdir_attrs) |a| {
            sftp_attributes_free(a);
            sshc.readdir_attrs = null;
        }
        if (sshc.readdir_link_attrs) |a| {
            sftp_attributes_free(a);
            sshc.readdir_link_attrs = null;
        }
        if (sshc.privkey) |k| {
            ssh_key_free(k);
            sshc.privkey = null;
        }
        if (sshc.pubkey) |k| {
            ssh_key_free(k);
            sshc.pubkey = null;
        }
        if (sshc.passphrase) |p| {
            mem.free(p);
            sshc.passphrase = null;
        }
        if (sshc.pub_key) |p| {
            mem.free(p);
            sshc.pub_key = null;
        }
        if (sshc.priv_key) |p| {
            mem.free(p);
            sshc.priv_key = null;
        }
        if (sshc.quote_path1) |p| {
            mem.free(p);
            sshc.quote_path1 = null;
        }
        if (sshc.quote_path2) |p| {
            mem.free(p);
            sshc.quote_path2 = null;
        }
        containers.curlx_dyn_free(&sshc.readdir_buf);
        if (sshc.readdir_linkPath) |p| {
            mem.free(p);
            sshc.readdir_linkPath = null;
        }
        if (sshc.homedir) |hd| {
            ssh_string_free_char(hd);
            sshc.homedir = null;
        }
        sshc.initialized = false;
    }
}

fn myssh_in_SESSION_FREE(data: *Curl_easy, sshc: *ssh_conn_libssh) CURLcode {
    sshc_cleanup(sshc);
    const result = sshc.actualcode;
    sshc.* = .{};
    if (Curl_ftp_acc_get_conn(data)) |conn| {
        Curl_ftp_acc_connclose(conn);
    }
    sshc.state = .SSH_SESSION_FREE;
    sshc.nextstate = .SSH_NO_STATE;
    myssh_to(data, sshc, .SSH_STOP);
    return result;
}

fn myssh_statemachine(
    data: *Curl_easy,
    sshc: *ssh_conn_libssh,
    sshp: *SSHPROTO_libssh,
    block: *bool,
) CURLcode {
    var result: CURLcode = CURLE_OK;
    var rc: c_int = SSH_NO_ERROR;
    block.* = false;

    while (true) {
        switch (sshc.state) {
            .SSH_INIT => {
                myssh_state_init(data, sshc);
                rc = myssh_in_S_STARTUP(data, sshc);
                if (rc != 0) {} else {
                    rc = myssh_is_known(data, sshc);
                    if (rc != SSH_OK) {
                        rc = myssh_to_ERROR(data, sshc, CURLE_PEER_FAILED_VERIFICATION);
                    } else {
                        myssh_to(data, sshc, .SSH_AUTHLIST);
                        rc = myssh_in_AUTHLIST(data, sshc);
                    }
                }
            },
            .SSH_S_STARTUP => {
                rc = myssh_in_S_STARTUP(data, sshc);
                if (rc == 0) {
                    rc = myssh_is_known(data, sshc);
                    if (rc != SSH_OK) {
                        rc = myssh_to_ERROR(data, sshc, CURLE_PEER_FAILED_VERIFICATION);
                    } else {
                        myssh_to(data, sshc, .SSH_AUTHLIST);
                        rc = myssh_in_AUTHLIST(data, sshc);
                    }
                }
            },
            .SSH_HOSTKEY => {
                rc = myssh_is_known(data, sshc);
                if (rc != SSH_OK) {
                    rc = myssh_to_ERROR(data, sshc, CURLE_PEER_FAILED_VERIFICATION);
                } else {
                    myssh_to(data, sshc, .SSH_AUTHLIST);
                    rc = myssh_in_AUTHLIST(data, sshc);
                }
            },
            .SSH_AUTHLIST => rc = myssh_in_AUTHLIST(data, sshc),
            .SSH_AUTH_PKEY_INIT => rc = myssh_in_AUTH_PKEY_INIT(data, sshc),
            .SSH_AUTH_PKEY => rc = myssh_in_AUTH_PKEY(data, sshc),
            .SSH_AUTH_GSSAPI => rc = myssh_in_AUTH_GSSAPI(data, sshc),
            .SSH_AUTH_KEY_INIT => rc = myssh_in_AUTH_KEY_INIT(data, sshc),
            .SSH_AUTH_KEY => rc = myssh_in_AUTH_KEY(data, sshc),
            .SSH_AUTH_PASS_INIT => rc = myssh_in_AUTH_PASS_INIT(data, sshc),
            .SSH_AUTH_PASS => rc = myssh_in_AUTH_PASS(data, sshc),
            .SSH_AUTH_DONE => rc = myssh_in_AUTH_DONE(data, sshc),
            .SSH_SFTP_INIT => rc = myssh_in_SFTP_INIT(data, sshc),
            .SSH_SFTP_REALPATH => rc = myssh_in_SFTP_REALPATH(data, sshc),
            .SSH_SFTP_QUOTE_INIT => rc = myssh_in_SFTP_QUOTE_INIT(data, sshc, sshp),
            .SSH_SFTP_POSTQUOTE_INIT => rc = myssh_in_SFTP_POSTQUOTE_INIT(data, sshc),
            .SSH_SFTP_QUOTE => rc = myssh_in_SFTP_QUOTE(data, sshc, sshp),
            .SSH_SFTP_NEXT_QUOTE => rc = myssh_in_SFTP_NEXT_QUOTE(data, sshc),
            .SSH_SFTP_QUOTE_STAT => rc = myssh_in_SFTP_QUOTE_STAT(data, sshc),
            .SSH_SFTP_QUOTE_SETSTAT => rc = myssh_in_SFTP_QUOTE_SETSTAT(data, sshc),
            .SSH_SFTP_QUOTE_SYMLINK => rc = myssh_in_SFTP_QUOTE_SYMLINK(data, sshc),
            .SSH_SFTP_QUOTE_MKDIR => rc = myssh_in_SFTP_QUOTE_MKDIR(data, sshc),
            .SSH_SFTP_QUOTE_RENAME => rc = myssh_in_SFTP_QUOTE_RENAME(data, sshc),
            .SSH_SFTP_QUOTE_RMDIR => rc = myssh_in_SFTP_QUOTE_RMDIR(data, sshc),
            .SSH_SFTP_QUOTE_UNLINK => rc = myssh_in_SFTP_QUOTE_UNLINK(data, sshc),
            .SSH_SFTP_QUOTE_STATVFS => rc = myssh_in_SFTP_QUOTE_STATVFS(data, sshc),
            .SSH_SFTP_GETINFO => rc = myssh_in_SFTP_GETINFO(data, sshc),
            .SSH_SFTP_FILETIME => rc = myssh_in_SFTP_FILETIME(data, sshc, sshp),
            .SSH_SFTP_TRANS_INIT => rc = myssh_in_SFTP_TRANS_INIT(data, sshc, sshp),
            .SSH_SFTP_UPLOAD_INIT => rc = myssh_in_UPLOAD_INIT(data, sshc, sshp),
            .SSH_SFTP_CREATE_DIRS_INIT => rc = myssh_in_SFTP_CREATE_DIRS_INIT(data, sshc, sshp),
            .SSH_SFTP_CREATE_DIRS => rc = myssh_in_SFTP_CREATE_DIRS(data, sshc, sshp),
            .SSH_SFTP_CREATE_DIRS_MKDIR => rc = myssh_in_SFTP_CREATE_DIRS_MKDIR(data, sshc, sshp),
            .SSH_SFTP_READDIR_INIT => rc = myssh_in_SFTP_READDIR_INIT(data, sshc, sshp),
            .SSH_SFTP_READDIR => rc = myssh_in_SFTP_READDIR(data, sshc, sshp),
            .SSH_SFTP_READDIR_LINK => rc = myssh_in_SFTP_READDIR_LINK(data, sshc),
            .SSH_SFTP_READDIR_BOTTOM => rc = myssh_in_SFTP_READDIR_BOTTOM(data, sshc),
            .SSH_SFTP_READDIR_DONE => rc = myssh_in_SFTP_READDIR_DONE(data, sshc),
            .SSH_SFTP_DOWNLOAD_INIT => rc = myssh_in_SFTP_DOWNLOAD_INIT(data, sshc, sshp),
            .SSH_SFTP_DOWNLOAD_STAT => rc = myssh_in_SFTP_DOWNLOAD_STAT(data, sshc),
            .SSH_SFTP_CLOSE => rc = myssh_in_SFTP_CLOSE(data, sshc, sshp),
            .SSH_SFTP_SHUTDOWN => rc = myssh_in_SFTP_SHUTDOWN(data, sshc),
            .SSH_SCP_TRANS_INIT => rc = myssh_in_TRANS_INIT(data, sshc, sshp),
            .SSH_SCP_UPLOAD_INIT => rc = myssh_in_SCP_UPLOAD_INIT(data, sshc, sshp),
            .SSH_SCP_DOWNLOAD_INIT => {
                rc = myssh_in_SCP_DOWNLOAD_INIT(data, sshc);
                if (rc == 0) {
                    rc = myssh_SSH_SCP_DOWNLOAD(data, sshc);
                }
            },
            .SSH_SCP_DOWNLOAD => rc = myssh_SSH_SCP_DOWNLOAD(data, sshc),
            .SSH_SCP_DONE => rc = myssh_in_SCP_DONE(data, sshc),
            .SSH_SCP_SEND_EOF => rc = myssh_in_SCP_SEND_EOF(data, sshc),
            .SSH_SCP_CHANNEL_FREE => {
                myssh_in_SCP_CHANNEL_FREE(data, sshc);
                myssh_SESSION_DISCONNECT(data, sshc);
                result = myssh_in_SESSION_FREE(data, sshc);
            },
            .SSH_SESSION_DISCONNECT => {
                myssh_SESSION_DISCONNECT(data, sshc);
                result = myssh_in_SESSION_FREE(data, sshc);
            },
            .SSH_SESSION_FREE => result = myssh_in_SESSION_FREE(data, sshc),
            else => {
                sshc.nextstate = .SSH_NO_STATE;
                myssh_to(data, sshc, .SSH_STOP);
            },
        }
        if (rc == SSH_AGAIN or sshc.state == .SSH_STOP) break;
    }

    if (rc == SSH_AGAIN) {
        block.* = true;
    }
    if (result == CURLE_OK and sshc.state == .SSH_STOP) {
        result = sshc.actualcode;
    }
    if (trcSshEnabled(data)) {
        Curl_trc_feat_infof(
            data,
            &cookie_getinfo_trc.Curl_trc_feat_ssh,
            "[%s] statemachine() -> %d, block=%d",
            vssh.Curl_ssh_statename(sshc.state),
            @as(c_int, @intCast(result)),
            @as(c_int, @intFromBool(block.*)),
        );
    }
    return result;
}

pub fn myssh_multi_statemach(data_opt: ?*Curl_easy, done: *bool) callconv(.c) CURLcode {
    const data = data_opt orelse return CURLE_BAD_FUNCTION_ARGUMENT;
    if (comptime !use_libssh) {
        done.* = false;
        return CURLE_FAILED_INIT;
    }
    const conn = Curl_ftp_acc_get_conn(data) orelse return CURLE_FAILED_INIT;
    const sshc: *ssh_conn_libssh = @ptrCast(@alignCast(Curl_conn_meta_get(conn, CURL_META_SSH_CONN) orelse return CURLE_FAILED_INIT));
    const sshp: *SSHPROTO_libssh = @ptrCast(@alignCast(Curl_meta_get(data, CURL_META_SSH_EASY) orelse return CURLE_FAILED_INIT));

    var block: bool = false;
    const result = myssh_statemachine(data, sshc, sshp, &block);
    done.* = (sshc.state == .SSH_STOP);
    myssh_block2waitfor(sshc, block);
    return result;
}

fn myssh_block_statemach(
    data: *Curl_easy,
    sshc: *ssh_conn_libssh,
    sshp: *SSHPROTO_libssh,
    disconnect: bool,
) CURLcode {
    const conn = Curl_ftp_acc_get_conn(data) orelse return CURLE_FAILED_INIT;
    var result: CURLcode = CURLE_OK;

    while (sshc.state != .SSH_STOP and result == CURLE_OK) {
        var block: bool = false;
        var left_ms: timediff_t = 1000;

        result = myssh_statemachine(data, sshc, sshp, &block);
        if (result != CURLE_OK) break;

        if (!disconnect) {
            result = Curl_pgrsCheck(data);
            if (result != CURLE_OK) break;

            left_ms = Curl_timeleft_ms(data, false);
            if (left_ms < 0) {
                Curl_failf(data, "Operation timed out");
                return CURLE_OPERATION_TIMEDOUT;
            }
        }

        if (block) {
            const fd_read = Curl_vssh_get_conn_firstsocket(conn);
            const wait_ms: timediff_t = if (left_ms == 0 or left_ms > 1000) 1000 else left_ms;
            _ = Curl_socket_check(fd_read, CURL_SOCKET_BAD, CURL_SOCKET_BAD, wait_ms);
        }
    }
    return result;
}

fn myssh_easy_dtor(key: ?*const anyopaque, klen: usize, entry: ?*anyopaque) callconv(.c) void {
    _ = key;
    _ = klen;
    const sshp: *SSHPROTO_libssh = @ptrCast(@alignCast(entry orelse return));
    if (sshp.path) |p| {
        mem.free(p);
        sshp.path = null;
    }
    mem.free(sshp);
}

fn myssh_conn_dtor(key: ?*const anyopaque, klen: usize, entry: ?*anyopaque) callconv(.c) void {
    _ = key;
    _ = klen;
    const sshc: *ssh_conn_libssh = @ptrCast(@alignCast(entry orelse return));
    sshc_cleanup(sshc);
    mem.free(sshc);
}

fn setupPkeyLibssh(data: *Curl_easy, sshc: *ssh_conn_libssh) CURLcode {
    const auth_types: c_long = @intCast(Curl_setopt_get_i64(data, 54));
    if ((auth_types & CURLSSH_AUTH_PUBLICKEY) == 0) return CURLE_OK;

    sshc.pub_key = null;
    sshc.priv_key = null;

    if (Curl_setopt_get_str(data, STRING_SSH_PRIVATE_KEY)) |pk| {
        sshc.priv_key = mem.strdup(pk) orelse return CURLE_OUT_OF_MEMORY;
    } else {
        const home = curl_getenv("HOME");
        defer if (home) |h| mem.free(h);
        if (home) |h| {
            sshc.priv_key = curl_maprintf("%s/.ssh/id_rsa", h);
            if (sshc.priv_key == null) return CURLE_OUT_OF_MEMORY;
            if (std.c.access(sshc.priv_key.?, 0) != 0) {
                mem.free(sshc.priv_key);
                sshc.priv_key = curl_maprintf("%s/.ssh/id_dsa", h);
                if (sshc.priv_key == null) return CURLE_OUT_OF_MEMORY;
                if (std.c.access(sshc.priv_key.?, 0) != 0) {
                    mem.free(sshc.priv_key);
                    sshc.priv_key = null;
                }
            }
        }
        if (sshc.priv_key == null) {
            sshc.priv_key = mem.strdup("id_rsa");
            if (sshc.priv_key != null and std.c.access(sshc.priv_key.?, 0) != 0) {
                mem.free(sshc.priv_key);
                sshc.priv_key = mem.strdup("id_dsa");
                if (sshc.priv_key != null and std.c.access(sshc.priv_key.?, 0) != 0) {
                    mem.free(sshc.priv_key);
                    sshc.priv_key = mem.strdup("");
                }
            }
        }
    }

    if (Curl_setopt_get_str(data, STRING_SSH_PUBLIC_KEY)) |pubk| {
        if (pubk[0] != 0) {
            sshc.pub_key = mem.strdup(pubk) orelse {
                mem.free(sshc.priv_key);
                sshc.priv_key = null;
                return CURLE_OUT_OF_MEMORY;
            };
        }
    }

    if (Curl_setopt_get_str(data, STRING_KEY_PASSWD)) |kp| {
        sshc.passphrase = mem.strdup(kp) orelse {
            mem.free(sshc.priv_key);
            sshc.priv_key = null;
            mem.free(sshc.pub_key);
            sshc.pub_key = null;
            return CURLE_OUT_OF_MEMORY;
        };
    }

    if (sshc.pub_key) |pk| Curl_infof(data, "SSH: public key file '%s'", pk);
    if (sshc.priv_key) |pk| {
        Curl_infof(data, "SSH: private key file '%s'", pk);
    } else {
        Curl_infof(data, "SSH: public key auth without private key set!");
    }
    return CURLE_OK;
}

pub fn myssh_setup_connection(data_opt: ?*Curl_easy, conn_opt: ?*connectdata) callconv(.c) CURLcode {
    const data = data_opt orelse return CURLE_BAD_FUNCTION_ARGUMENT;
    const conn = conn_opt orelse return CURLE_BAD_FUNCTION_ARGUMENT;
    if (comptime !use_libssh) return CURLE_FAILED_INIT;

    const sshc_raw = mem.calloc(1, @sizeOf(ssh_conn_libssh)) orelse return CURLE_OUT_OF_MEMORY;
    const sshc: *ssh_conn_libssh = @ptrCast(@alignCast(sshc_raw));
    sshc.* = .{};
    containers.curlx_dyn_init(&sshc.readdir_buf, CURL_PATH_MAX * 2);
    sshc.initialized = true;
    if (Curl_conn_meta_set(conn, CURL_META_SSH_CONN, sshc, myssh_conn_dtor) != CURLE_OK) {
        return CURLE_OUT_OF_MEMORY;
    }

    const sshp_raw = mem.calloc(1, @sizeOf(SSHPROTO_libssh)) orelse return CURLE_OUT_OF_MEMORY;
    const sshp: *SSHPROTO_libssh = @ptrCast(@alignCast(sshp_raw));
    sshp.* = .{};
    if (Curl_meta_set(data, CURL_META_SSH_EASY, sshp, myssh_easy_dtor) != CURLE_OK) {
        return CURLE_OUT_OF_MEMORY;
    }

    return setupPkeyLibssh(data, sshc);
}

pub fn myssh_connect(data_opt: ?*Curl_easy, done: *bool) callconv(.c) CURLcode {
    const data = data_opt orelse return CURLE_BAD_FUNCTION_ARGUMENT;
    if (comptime !use_libssh) {
        done.* = false;
        return CURLE_FAILED_INIT;
    }
    const conn = Curl_ftp_acc_get_conn(data) orelse return CURLE_FAILED_INIT;
    const sshc: *ssh_conn_libssh = @ptrCast(@alignCast(Curl_conn_meta_get(conn, CURL_META_SSH_CONN) orelse return CURLE_FAILED_INIT));
    const ssh: *SSHPROTO_libssh = @ptrCast(@alignCast(Curl_meta_get(data, CURL_META_SSH_EASY) orelse return CURLE_FAILED_INIT));
    _ = ssh;
    var sock = Curl_vssh_get_conn_firstsocket(conn);

    if (trcSshEnabled(data)) {
        Curl_trc_feat_infof(data, &cookie_getinfo_trc.Curl_trc_feat_ssh, "myssh_connect");
    }
    if ((Curl_vssh_get_conn_protocol(conn) & CURLPROTO_SCP) != 0) {
        Curl_vssh_set_conn_send_recv(conn, scp_send, scp_recv);
    } else {
        Curl_vssh_set_conn_send_recv(conn, sftp_send, sftp_recv);
    }

    sshc.ssh_session = ssh_new();
    if (sshc.ssh_session == null) {
        Curl_failf(data, "Failure initializing ssh session");
        return CURLE_FAILED_INIT;
    }
    const session = sshc.ssh_session.?;

    const host_name = Curl_vssh_get_conn_host_name(conn);
    if (ssh_options_set(session, SSH_OPTIONS_HOST, host_name) != SSH_OK) {
        Curl_failf(data, "Could not set remote host");
        return CURLE_FAILED_INIT;
    }

    if (ssh_options_parse_config(session, null) != SSH_OK) {
        Curl_infof(data, "Could not parse SSH configuration files");
    }

    if (ssh_options_set(session, SSH_OPTIONS_FD, &sock) != SSH_OK) {
        Curl_failf(data, "Could not set socket");
        return CURLE_FAILED_INIT;
    }

    if (Curl_vssh_get_conn_user(conn)) |user| {
        if (user[0] != 0) {
            Curl_infof(data, "User: %s", user);
            if (ssh_options_set(session, SSH_OPTIONS_USER, user) != SSH_OK) {
                Curl_failf(data, "Could not set user");
                return CURLE_FAILED_INIT;
            }
        }
    }

    if (Curl_setopt_get_str(data, STRING_SSH_KNOWNHOSTS)) |kh_file| {
        Curl_infof(data, "Known hosts: %s", kh_file);
        var rc = ssh_options_set(session, SSH_OPTIONS_KNOWNHOSTS, kh_file);
        if (rc == SSH_OK) {
            rc = ssh_options_set(session, SSH_OPTIONS_GLOBAL_KNOWNHOSTS, kh_file);
        }
        if (rc != SSH_OK) {
            Curl_failf(data, "Could not set known hosts file path");
            return CURLE_FAILED_INIT;
        }
    }

    var port = Curl_vssh_get_conn_remote_port(conn);
    if (port != 0) {
        if (ssh_options_set(session, SSH_OPTIONS_PORT, &port) != SSH_OK) {
            Curl_failf(data, "Could not set remote port");
            return CURLE_FAILED_INIT;
        }
    }

    if (Curl_setopt_get_bit(data, 45)) {
        const comp_str: [*:0]const u8 = "zlib,zlib@openssh.com,none";
        if (ssh_options_set(session, SSH_OPTIONS_COMPRESSION, comp_str) != SSH_OK) {
            Curl_failf(data, "Could not set compression");
            return CURLE_FAILED_INIT;
        }
    }

    sshc.privkey = null;
    sshc.pubkey = null;

    if (sshc.pub_key) |pubk| {
        if (ssh_pki_import_pubkey_file(pubk, &sshc.pubkey) != SSH_OK) {
            Curl_failf(data, "Could not load public key file");
            return CURLE_FAILED_INIT;
        }
    }

    myssh_to(data, sshc, .SSH_INIT);
    return myssh_multi_statemach(data, done);
}

pub fn scp_doing(data_opt: ?*Curl_easy, dophase_done: *bool) callconv(.c) CURLcode {
    const result = myssh_multi_statemach(data_opt, dophase_done);
    if (dophase_done.*) {
        if (data_opt) |data| {
            if (trcSshEnabled(data)) {
                Curl_trc_feat_infof(data, &cookie_getinfo_trc.Curl_trc_feat_ssh, "DO phase is complete");
            }
        }
    }
    return result;
}

fn scp_perform(data: *Curl_easy, connected: *bool, dophase_done: *bool) CURLcode {
    const conn = Curl_ftp_acc_get_conn(data) orelse return CURLE_FAILED_INIT;
    const sshc: *ssh_conn_libssh = @ptrCast(@alignCast(Curl_conn_meta_get(conn, CURL_META_SSH_CONN) orelse return CURLE_FAILED_INIT));
    if (trcSshEnabled(data)) {
        Curl_trc_feat_infof(data, &cookie_getinfo_trc.Curl_trc_feat_ssh, "DO phase starts");
    }
    dophase_done.* = false;
    myssh_to(data, sshc, .SSH_SCP_TRANS_INIT);
    const result = myssh_multi_statemach(data, dophase_done);
    connected.* = true;
    if (dophase_done.*) {
        if (trcSshEnabled(data)) {
            Curl_trc_feat_infof(data, &cookie_getinfo_trc.Curl_trc_feat_ssh, "DO phase is complete");
        }
    }
    return result;
}

pub fn scp_disconnect(data_opt: ?*Curl_easy, conn_opt: ?*connectdata, dead_connection: bool) callconv(.c) CURLcode {
    _ = dead_connection;
    const data = data_opt orelse return CURLE_BAD_FUNCTION_ARGUMENT;
    const conn = conn_opt orelse return CURLE_BAD_FUNCTION_ARGUMENT;
    if (comptime !use_libssh) return CURLE_OK;

    const sshc: *ssh_conn_libssh = @ptrCast(@alignCast(Curl_conn_meta_get(conn, CURL_META_SSH_CONN) orelse return CURLE_OK));
    const sshp_opt: ?*SSHPROTO_libssh = @ptrCast(@alignCast(Curl_meta_get(data, CURL_META_SSH_EASY)));
    var dummy_proto: SSHPROTO_libssh = .{};
    var result: CURLcode = CURLE_OK;
    if (sshc.ssh_session != null) {
        myssh_to(data, sshc, .SSH_SESSION_DISCONNECT);
        result = myssh_block_statemach(data, sshc, sshp_opt orelse &dummy_proto, true);
    }
    return result;
}

fn myssh_done(data: *Curl_easy, sshc: *ssh_conn_libssh, status: CURLcode) CURLcode {
    var result: CURLcode = CURLE_OK;
    const sshp_opt: ?*SSHPROTO_libssh = @ptrCast(@alignCast(Curl_meta_get(data, CURL_META_SSH_EASY)));
    if (status == CURLE_OK and sshp_opt != null) {
        result = myssh_block_statemach(data, sshc, sshp_opt.?, false);
    } else {
        result = status;
    }
    if (Curl_pgrsDone(data) != 0) {
        return CURLE_ABORTED_BY_CALLBACK;
    }
    Curl_vssh_clear_req_io(data);
    return result;
}

pub fn scp_done(data_opt: ?*Curl_easy, status: CURLcode, premature: bool) callconv(.c) CURLcode {
    _ = premature;
    const data = data_opt orelse return CURLE_BAD_FUNCTION_ARGUMENT;
    if (comptime !use_libssh) return CURLE_FAILED_INIT;
    const conn = Curl_ftp_acc_get_conn(data) orelse return CURLE_FAILED_INIT;
    const sshc: *ssh_conn_libssh = @ptrCast(@alignCast(Curl_conn_meta_get(conn, CURL_META_SSH_CONN) orelse return CURLE_FAILED_INIT));
    if (status == CURLE_OK) {
        myssh_to(data, sshc, .SSH_SCP_DONE);
    }
    return myssh_done(data, sshc, status);
}

fn scp_send(
    data: *Curl_easy,
    sockindex: i8,
    buf: [*]const u8,
    len: usize,
    eos: bool,
    pnwritten: *usize,
) callconv(.c) CURLcode {
    _ = sockindex;
    _ = eos;
    pnwritten.* = 0;
    const conn = Curl_ftp_acc_get_conn(data) orelse return CURLE_FAILED_INIT;
    const sshc: *ssh_conn_libssh = @ptrCast(@alignCast(Curl_conn_meta_get(conn, CURL_META_SSH_CONN) orelse return CURLE_FAILED_INIT));
    const rc = ssh_scp_write(sshc.scp_session orelse return CURLE_FAILED_INIT, buf, len);
    if (rc != SSH_OK) return CURLE_SSH;
    pnwritten.* = len;
    return CURLE_OK;
}

fn scp_recv(
    data: *Curl_easy,
    sockindex: i8,
    buf: [*]u8,
    len: usize,
    pnread: *usize,
) callconv(.c) CURLcode {
    _ = sockindex;
    pnread.* = 0;
    const conn = Curl_ftp_acc_get_conn(data) orelse return CURLE_FAILED_INIT;
    const sshc: *ssh_conn_libssh = @ptrCast(@alignCast(Curl_conn_meta_get(conn, CURL_META_SSH_CONN) orelse return CURLE_FAILED_INIT));
    const nread = ssh_scp_read(sshc.scp_session orelse return CURLE_FAILED_INIT, buf, len);
    if (nread == SSH_ERROR or nread < 0) return CURLE_SSH;
    pnread.* = @intCast(nread);
    return CURLE_OK;
}

fn sftp_perform(data: *Curl_easy, connected: *bool, dophase_done: *bool) CURLcode {
    const conn = Curl_ftp_acc_get_conn(data) orelse return CURLE_FAILED_INIT;
    const sshc: *ssh_conn_libssh = @ptrCast(@alignCast(Curl_conn_meta_get(conn, CURL_META_SSH_CONN) orelse return CURLE_FAILED_INIT));
    if (trcSshEnabled(data)) {
        Curl_trc_feat_infof(data, &cookie_getinfo_trc.Curl_trc_feat_ssh, "DO phase starts");
    }
    dophase_done.* = false;
    myssh_to(data, sshc, .SSH_SFTP_QUOTE_INIT);
    const result = myssh_multi_statemach(data, dophase_done);
    connected.* = true;
    if (dophase_done.*) {
        if (trcSshEnabled(data)) {
            Curl_trc_feat_infof(data, &cookie_getinfo_trc.Curl_trc_feat_ssh, "DO phase is complete");
        }
    }
    return result;
}

pub fn sftp_doing(data_opt: ?*Curl_easy, dophase_done: *bool) callconv(.c) CURLcode {
    const result = myssh_multi_statemach(data_opt, dophase_done);
    if (dophase_done.*) {
        if (data_opt) |data| {
            if (trcSshEnabled(data)) {
                Curl_trc_feat_infof(data, &cookie_getinfo_trc.Curl_trc_feat_ssh, "DO phase is complete");
            }
        }
    }
    return result;
}

pub fn sftp_disconnect(data_opt: ?*Curl_easy, conn_opt: ?*connectdata, dead_connection: bool) callconv(.c) CURLcode {
    _ = dead_connection;
    const data = data_opt orelse return CURLE_BAD_FUNCTION_ARGUMENT;
    const conn = conn_opt orelse return CURLE_BAD_FUNCTION_ARGUMENT;
    if (comptime !use_libssh) return CURLE_OK;

    const sshc: *ssh_conn_libssh = @ptrCast(@alignCast(Curl_conn_meta_get(conn, CURL_META_SSH_CONN) orelse return CURLE_OK));
    const sshp_opt: ?*SSHPROTO_libssh = @ptrCast(@alignCast(Curl_meta_get(data, CURL_META_SSH_EASY)));
    var dummy_proto: SSHPROTO_libssh = .{};
    var result: CURLcode = CURLE_OK;
    if (trcSshEnabled(data)) {
        Curl_trc_feat_infof(data, &cookie_getinfo_trc.Curl_trc_feat_ssh, "DISCONNECT starts now");
    }
    if (sshc.ssh_session != null) {
        myssh_to(data, sshc, .SSH_SFTP_SHUTDOWN);
        result = myssh_block_statemach(data, sshc, sshp_opt orelse &dummy_proto, true);
    }
    if (trcSshEnabled(data)) {
        Curl_trc_feat_infof(data, &cookie_getinfo_trc.Curl_trc_feat_ssh, "DISCONNECT is done");
    }
    return result;
}

pub fn sftp_done(data_opt: ?*Curl_easy, status: CURLcode, premature: bool) callconv(.c) CURLcode {
    const data = data_opt orelse return CURLE_BAD_FUNCTION_ARGUMENT;
    if (comptime !use_libssh) return CURLE_FAILED_INIT;
    const conn = Curl_ftp_acc_get_conn(data) orelse return CURLE_FAILED_INIT;
    const sshc: *ssh_conn_libssh = @ptrCast(@alignCast(Curl_conn_meta_get(conn, CURL_META_SSH_CONN) orelse return CURLE_FAILED_INIT));
    if (status == CURLE_OK) {
        if (!premature and Curl_ftp_acc_get_postquote(data) != null and !Curl_vssh_get_conn_retry(conn)) {
            sshc.nextstate = .SSH_SFTP_POSTQUOTE_INIT;
        }
        myssh_to(data, sshc, .SSH_SFTP_CLOSE);
    }
    return myssh_done(data, sshc, status);
}

fn sftp_send(
    data: *Curl_easy,
    sockindex: i8,
    buf: [*]const u8,
    len: usize,
    eos: bool,
    pnwritten: *usize,
) callconv(.c) CURLcode {
    _ = sockindex;
    _ = eos;
    pnwritten.* = 0;
    const conn = Curl_ftp_acc_get_conn(data) orelse return CURLE_FAILED_INIT;
    const sshc: *ssh_conn_libssh = @ptrCast(@alignCast(Curl_conn_meta_get(conn, CURL_META_SSH_CONN) orelse return CURLE_FAILED_INIT));
    const file = sshc.sftp_file orelse return CURLE_FAILED_INIT;

    switch (sshc.sftp_send_state) {
        0 => {
            sftp_file_set_nonblocking(file);
            if (sftp_aio_begin_write(file, buf, len, &sshc.sftp_send_aio) == SSH_ERROR) {
                return CURLE_SEND_ERROR;
            }
            sshc.sftp_send_state = 1;
            const nwrite = sftp_aio_wait_write(&sshc.sftp_send_aio);
            myssh_block2waitfor(sshc, nwrite == SSH_AGAIN);
            if (nwrite == SSH_AGAIN) return CURLE_AGAIN;
            if (nwrite < 0) return CURLE_SEND_ERROR;
            sshc.sftp_send_state = 0;
            pnwritten.* = @intCast(nwrite);
            return CURLE_OK;
        },
        1 => {
            const nwrite = sftp_aio_wait_write(&sshc.sftp_send_aio);
            myssh_block2waitfor(sshc, nwrite == SSH_AGAIN);
            if (nwrite == SSH_AGAIN) return CURLE_AGAIN;
            if (nwrite < 0) return CURLE_SEND_ERROR;
            sshc.sftp_send_state = 0;
            pnwritten.* = @intCast(nwrite);
            return CURLE_OK;
        },
        else => return CURLE_SEND_ERROR,
    }
}

fn sftp_recv(
    data: *Curl_easy,
    sockindex: i8,
    buf: [*]u8,
    len: usize,
    pnread: *usize,
) callconv(.c) CURLcode {
    _ = sockindex;
    pnread.* = 0;
    const conn = Curl_ftp_acc_get_conn(data) orelse return CURLE_FAILED_INIT;
    const sshc: *ssh_conn_libssh = @ptrCast(@alignCast(Curl_conn_meta_get(conn, CURL_META_SSH_CONN) orelse return CURLE_FAILED_INIT));
    const file = sshc.sftp_file orelse return CURLE_FAILED_INIT;

    switch (sshc.sftp_recv_state) {
        0 => {
            if (sftp_aio_begin_read(file, len, &sshc.sftp_recv_aio) == SSH_ERROR) {
                return CURLE_RECV_ERROR;
            }
            sshc.sftp_recv_state = 1;
            const nread = sftp_aio_wait_read(&sshc.sftp_recv_aio, buf, len);
            myssh_block2waitfor(sshc, nread == SSH_AGAIN);
            if (nread == SSH_AGAIN) return CURLE_AGAIN;
            if (nread < 0) return CURLE_RECV_ERROR;
            sshc.sftp_recv_state = 0;
            pnread.* = @intCast(nread);
            return CURLE_OK;
        },
        1 => {
            const nread = sftp_aio_wait_read(&sshc.sftp_recv_aio, buf, len);
            myssh_block2waitfor(sshc, nread == SSH_AGAIN);
            if (nread == SSH_AGAIN) return CURLE_AGAIN;
            if (nread < 0) return CURLE_RECV_ERROR;
            sshc.sftp_recv_state = 0;
            pnread.* = @intCast(nread);
            return CURLE_OK;
        },
        else => return CURLE_RECV_ERROR,
    }
}

pub fn myssh_do_it(data_opt: ?*Curl_easy, done: *bool) callconv(.c) CURLcode {
    const data = data_opt orelse return CURLE_BAD_FUNCTION_ARGUMENT;
    if (comptime !use_libssh) {
        done.* = false;
        return CURLE_FAILED_INIT;
    }
    var connected: bool = false;
    done.* = false;
    const conn = Curl_ftp_acc_get_conn(data) orelse return CURLE_FAILED_INIT;
    const sshc: *ssh_conn_libssh = @ptrCast(@alignCast(Curl_conn_meta_get(conn, CURL_META_SSH_CONN) orelse return CURLE_FAILED_INIT));

    Curl_ftp_acc_set_req_size(data, -1);
    sshc.actualcode = CURLE_OK;
    sshc.secondCreateDirs = 0;
    Curl_pgrsReset(data);

    if ((Curl_vssh_get_conn_protocol(conn) & CURLPROTO_SCP) != 0) {
        return scp_perform(data, &connected, done);
    } else {
        return sftp_perform(data, &connected, done);
    }
}

pub fn myssh_pollset(data_opt: ?*Curl_easy, ps_opt: ?*easy_pollset) callconv(.c) CURLcode {
    const data = data_opt orelse return CURLE_BAD_FUNCTION_ARGUMENT;
    const ps = ps_opt orelse return CURLE_OK;
    const conn = Curl_ftp_acc_get_conn(data) orelse return CURLE_FAILED_INIT;
    const sshc: *ssh_conn_libssh = @ptrCast(@alignCast(Curl_conn_meta_get(conn, CURL_META_SSH_CONN) orelse return CURLE_FAILED_INIT));
    const sock = Curl_vssh_get_conn_firstsocket(conn);
    if (sock == CURL_SOCKET_BAD) return CURLE_FAILED_INIT;

    const waitfor: c_int = if (sshc.waitfor != 0) sshc.waitfor else @intCast(Curl_vssh_get_req_io_flags(data));
    if (waitfor != 0) {
        var flags: c_int = 0;
        if ((waitfor & REQ_IO_RECV) != 0) flags |= CURL_POLL_IN;
        if ((waitfor & REQ_IO_SEND) != 0) flags |= CURL_POLL_OUT;
        if (trcSshEnabled(data)) {
            Curl_trc_feat_infof(data, &cookie_getinfo_trc.Curl_trc_feat_ssh, "pollset, flags=%x", @as(c_uint, @intCast(flags)));
        }
        return Curl_pollset_change(data, ps, sock, flags, 0);
    }
    if (sshc.ssh_session != null) {
        return Curl_pollset_change(data, ps, sock, CURL_POLL_IN, 0);
    }
    return CURLE_OK;
}

pub fn init() CURLcode {
    if (ssh_init() != 0) return CURLE_FAILED_INIT;
    return CURLE_OK;
}

pub fn cleanup() void {
    _ = ssh_finalize();
}

pub fn version(buffer: [*]u8, buflen: usize) usize {
    const ver = ssh_version(0) orelse "";
    const n = curl_msnprintf(buffer, buflen, "libssh/%s", ver);
    return if (n > 0) @intCast(n) else 0;
}

pub const protocol_scp: vssh.Curl_protocol = .{
    .setup_connection = myssh_setup_connection,
    .do_it = myssh_do_it,
    .done = scp_done,
    .do_more = null,
    .connect_it = myssh_connect,
    .connecting = myssh_multi_statemach,
    .doing = scp_doing,
    .proto_pollset = myssh_pollset,
    .doing_pollset = myssh_pollset,
    .domore_pollset = null,
    .perform_pollset = myssh_pollset,
    .disconnect = scp_disconnect,
    .write_resp = null,
    .write_resp_hd = null,
    .connection_is_dead = null,
    .attach = null,
    .follow = null,
};

pub const protocol_sftp: vssh.Curl_protocol = .{
    .setup_connection = myssh_setup_connection,
    .do_it = myssh_do_it,
    .done = sftp_done,
    .do_more = null,
    .connect_it = myssh_connect,
    .connecting = myssh_multi_statemach,
    .doing = sftp_doing,
    .proto_pollset = myssh_pollset,
    .doing_pollset = myssh_pollset,
    .domore_pollset = null,
    .perform_pollset = myssh_pollset,
    .disconnect = sftp_disconnect,
    .write_resp = null,
    .write_resp_hd = null,
    .connection_is_dead = null,
    .attach = null,
    .follow = null,
};

test "libssh protocol descriptors and version string" {
    try std.testing.expect(protocol_scp.setup_connection != null);
    try std.testing.expect(protocol_scp.do_it != null);
    try std.testing.expect(protocol_scp.connect_it != null);
    try std.testing.expect(protocol_sftp.setup_connection != null);
    try std.testing.expect(protocol_sftp.do_it != null);
    try std.testing.expect(protocol_sftp.connect_it != null);

    if (comptime use_libssh) {
        try std.testing.expectEqual(CURLE_OK, init());
        defer cleanup();
        var buf: [64]u8 = undefined;
        const n = version(&buf, buf.len);
        try std.testing.expect(n > 0);
        try std.testing.expect(std.mem.startsWith(u8, buf[0..n], "libssh/"));
    }
}
