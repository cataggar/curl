const std = @import("std");
const builtin = @import("builtin");
const mem = @import("mem.zig");

pub const curl_off_t = i64;
pub const timediff_t = i64;
pub const curl_socket_t = if (builtin.os.tag == .windows and @sizeOf(usize) == 8) u64 else c_int;

pub const FILE = opaque {};
pub const CURL = opaque {};
pub const CURLM = opaque {};
pub const CURLU = opaque {};
pub const GlobalConfig = opaque {};
pub const OperationConfig = opaque {};
pub const per_transfer = opaque {};
pub const OutStruct = opaque {};
pub const HdrCbData = opaque {};

pub const curltime = extern struct {
    tv_sec: i64 = 0,
    tv_usec: c_int = 0,
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

pub const curl_slist = extern struct {
    data: ?[*:0]u8,
    next: ?*curl_slist,
};

pub const slist_wc = extern struct {
    first: ?*curl_slist,
    last: ?*curl_slist,
};

pub const curl_certinfo = extern struct {
    num_of_certs: c_int,
    certinfo: ?[*]?*curl_slist,
};

pub const curl_header = extern struct {
    name: [*:0]u8,
    value: [*:0]u8,
    amount: usize,
    index: usize,
    origin: c_uint,
    anchor: ?*anyopaque,
};

pub const curl_sockaddr = extern struct {
    family: c_int,
    socktype: c_int,
    protocol: c_int,
    addrlen: c_uint,
    addr: [16]u8,
};

pub const dynbuf = extern struct {
    bufr: ?[*:0]u8 = null,
    leng: usize = 0,
    allc: usize = 0,
    toobig: usize = 0,
    init: c_int = 0,
};

pub const writeoutvar = extern struct {
    name: [*:0]const u8,
    id: c_uint,
    ci: c_uint,
    writefunc: ?*const fn (
        stream: ?*FILE,
        wovar: *const writeoutvar,
        per: *per_transfer,
        per_result: c_uint,
        use_json: bool,
    ) callconv(.c) c_int,
};

const CURL_OFF_T_MAX: curl_off_t = std.math.maxInt(curl_off_t);
const UNPRINTABLE_CHAR: u8 = '.';
const STRERROR_LEN: usize = 256;

const TRACE_NONE: c_uint = 0;
const TRACE_BIN: c_uint = 1;
const TRACE_ASCII: c_uint = 2;
const TRACE_PLAIN: c_uint = 3;

const CURLINFO_TEXT: c_uint = 0;
const CURLINFO_HEADER_IN: c_uint = 1;
const CURLINFO_HEADER_OUT: c_uint = 2;
const CURLINFO_DATA_IN: c_uint = 3;
const CURLINFO_DATA_OUT: c_uint = 4;
const CURLINFO_SSL_DATA_IN: c_uint = 5;
const CURLINFO_SSL_DATA_OUT: c_uint = 6;

const CLOBBER_DEFAULT: c_uint = 0;
const CLOBBER_NEVER: c_uint = 1;
const CLOBBER_ALWAYS: c_uint = 2;

const CURL_WRITEFUNC_ERROR: usize = 0xFFFFFFFF;
const CURL_READFUNC_PAUSE: usize = 0x10000001;
const CURL_PROGRESSFUNC_CONTINUE: c_int = 0x10000001;
const CURL_SEEKFUNC_OK: c_int = 0;
const CURL_SEEKFUNC_FAIL: c_int = 1;
const CURL_SEEKFUNC_CANTSEEK: c_int = 2;
const CURLPAUSE_CONT: c_int = 0;

const CURLH_HEADER: c_uint = 1 << 0;
const CURLHE_OK: c_uint = 0;

const CURLMINFO_XFERS_RUNNING: c_uint = 2;
const CURLMINFO_XFERS_ADDED: c_uint = 5;

const CURLUPART_URL: c_uint = 0;
const CURLUPART_SCHEME: c_uint = 1;
const CURLUPART_USER: c_uint = 2;
const CURLUPART_PASSWORD: c_uint = 3;
const CURLUPART_OPTIONS: c_uint = 4;
const CURLUPART_HOST: c_uint = 5;
const CURLUPART_PORT: c_uint = 6;
const CURLUPART_PATH: c_uint = 7;
const CURLUPART_QUERY: c_uint = 8;
const CURLUPART_FRAGMENT: c_uint = 9;
const CURLUPART_ZONEID: c_uint = 10;

const CURLU_DEFAULT_PORT: c_uint = 1 << 0;
const CURLU_NO_DEFAULT_PORT: c_uint = 1 << 1;
const CURLU_NON_SUPPORT_SCHEME: c_uint = 1 << 3;
const CURLU_GUESS_SCHEME: c_uint = 1 << 9;

const CURL_HTTP_VERSION_NONE: c_long = 0;
const CURL_HTTP_VERSION_1_0: c_long = 1;
const CURL_HTTP_VERSION_1_1: c_long = 2;
const CURL_HTTP_VERSION_2: c_long = 3;
const CURL_HTTP_VERSION_3: c_long = 30;

const CURLINFO_NONE: c_uint = 0;
const CURLINFO_STRING: c_uint = 0x100000;
const CURLINFO_LONG: c_uint = 0x200000;
const CURLINFO_PTR: c_uint = 0x400000;
const CURLINFO_OFF_T: c_uint = 0x600000;

const CURLINFO_EFFECTIVE_URL: c_uint = CURLINFO_STRING + 1;
const CURLINFO_RESPONSE_CODE: c_uint = CURLINFO_LONG + 2;
const CURLINFO_SIZE_UPLOAD_T: c_uint = CURLINFO_OFF_T + 7;
const CURLINFO_SIZE_DOWNLOAD_T: c_uint = CURLINFO_OFF_T + 8;
const CURLINFO_SPEED_DOWNLOAD_T: c_uint = CURLINFO_OFF_T + 9;
const CURLINFO_SPEED_UPLOAD_T: c_uint = CURLINFO_OFF_T + 10;
const CURLINFO_HEADER_SIZE: c_uint = CURLINFO_LONG + 11;
const CURLINFO_REQUEST_SIZE: c_uint = CURLINFO_LONG + 12;
const CURLINFO_SSL_VERIFYRESULT: c_uint = CURLINFO_LONG + 13;
const CURLINFO_CONTENT_TYPE: c_uint = CURLINFO_STRING + 18;
const CURLINFO_REDIRECT_COUNT: c_uint = CURLINFO_LONG + 20;
const CURLINFO_HTTP_CONNECTCODE: c_uint = CURLINFO_LONG + 22;
const CURLINFO_NUM_CONNECTS: c_uint = CURLINFO_LONG + 26;
const CURLINFO_FTP_ENTRY_PATH: c_uint = CURLINFO_STRING + 30;
const CURLINFO_REDIRECT_URL: c_uint = CURLINFO_STRING + 31;
const CURLINFO_PRIMARY_IP: c_uint = CURLINFO_STRING + 32;
const CURLINFO_CERTINFO: c_uint = CURLINFO_PTR + 34;
const CURLINFO_PRIMARY_PORT: c_uint = CURLINFO_LONG + 40;
const CURLINFO_LOCAL_IP: c_uint = CURLINFO_STRING + 41;
const CURLINFO_LOCAL_PORT: c_uint = CURLINFO_LONG + 42;
const CURLINFO_HTTP_VERSION: c_uint = CURLINFO_LONG + 46;
const CURLINFO_PROXY_SSL_VERIFYRESULT: c_uint = CURLINFO_LONG + 47;
const CURLINFO_SCHEME: c_uint = CURLINFO_STRING + 49;
const CURLINFO_TOTAL_TIME_T: c_uint = CURLINFO_OFF_T + 50;
const CURLINFO_NAMELOOKUP_TIME_T: c_uint = CURLINFO_OFF_T + 51;
const CURLINFO_CONNECT_TIME_T: c_uint = CURLINFO_OFF_T + 52;
const CURLINFO_PRETRANSFER_TIME_T: c_uint = CURLINFO_OFF_T + 53;
const CURLINFO_STARTTRANSFER_TIME_T: c_uint = CURLINFO_OFF_T + 54;
const CURLINFO_REDIRECT_TIME_T: c_uint = CURLINFO_OFF_T + 55;
const CURLINFO_APPCONNECT_TIME_T: c_uint = CURLINFO_OFF_T + 56;
const CURLINFO_EFFECTIVE_METHOD: c_uint = CURLINFO_STRING + 58;
const CURLINFO_REFERER: c_uint = CURLINFO_STRING + 60;
const CURLINFO_XFER_ID: c_uint = CURLINFO_OFF_T + 63;
const CURLINFO_CONN_ID: c_uint = CURLINFO_OFF_T + 64;
const CURLINFO_QUEUE_TIME_T: c_uint = CURLINFO_OFF_T + 65;
const CURLINFO_USED_PROXY: c_uint = CURLINFO_LONG + 66;
const CURLINFO_POSTTRANSFER_TIME_T: c_uint = CURLINFO_OFF_T + 67;
const CURLINFO_EARLYDATA_SENT_T: c_uint = CURLINFO_OFF_T + 68;
const CURLINFO_SIZE_DELIVERED: c_uint = CURLINFO_OFF_T + 71;

const VAR_NONE: c_uint = 0;
const VAR_APPCONNECT_TIME: c_uint = 1;
const VAR_CERT: c_uint = 2;
const VAR_CONNECT_TIME: c_uint = 3;
const VAR_CONTENT_TYPE: c_uint = 4;
const VAR_CONN_ID: c_uint = 5;
const VAR_EASY_ID: c_uint = 6;
const VAR_EFFECTIVE_FILENAME: c_uint = 7;
const VAR_EFFECTIVE_METHOD: c_uint = 8;
const VAR_EFFECTIVE_URL: c_uint = 9;
const VAR_ERRORMSG: c_uint = 10;
const VAR_EXITCODE: c_uint = 11;
const VAR_FTP_ENTRY_PATH: c_uint = 12;
const VAR_HEADER_JSON: c_uint = 13;
const VAR_HEADER_SIZE: c_uint = 14;
const VAR_HTTP_CODE: c_uint = 15;
const VAR_HTTP_CODE_PROXY: c_uint = 16;
const VAR_HTTP_VERSION: c_uint = 17;
const VAR_INPUT_URL: c_uint = 18;
const VAR_INPUT_URLSCHEME: c_uint = 19;
const VAR_INPUT_URLUSER: c_uint = 20;
const VAR_INPUT_URLPASSWORD: c_uint = 21;
const VAR_INPUT_URLOPTIONS: c_uint = 22;
const VAR_INPUT_URLHOST: c_uint = 23;
const VAR_INPUT_URLPORT: c_uint = 24;
const VAR_INPUT_URLPATH: c_uint = 25;
const VAR_INPUT_URLQUERY: c_uint = 26;
const VAR_INPUT_URLFRAGMENT: c_uint = 27;
const VAR_INPUT_URLZONEID: c_uint = 28;
const VAR_INPUT_URLESCHEME: c_uint = 29;
const VAR_INPUT_URLEUSER: c_uint = 30;
const VAR_INPUT_URLEPASSWORD: c_uint = 31;
const VAR_INPUT_URLEOPTIONS: c_uint = 32;
const VAR_INPUT_URLEHOST: c_uint = 33;
const VAR_INPUT_URLEPORT: c_uint = 34;
const VAR_INPUT_URLEPATH: c_uint = 35;
const VAR_INPUT_URLEQUERY: c_uint = 36;
const VAR_INPUT_URLEFRAGMENT: c_uint = 37;
const VAR_INPUT_URLEZONEID: c_uint = 38;
const VAR_JSON: c_uint = 39;
const VAR_LOCAL_IP: c_uint = 40;
const VAR_LOCAL_PORT: c_uint = 41;
const VAR_NAMELOOKUP_TIME: c_uint = 42;
const VAR_NUM_CERTS: c_uint = 43;
const VAR_NUM_CONNECTS: c_uint = 44;
const VAR_NUM_HEADERS: c_uint = 45;
const VAR_NUM_RETRY: c_uint = 46;
const VAR_ONERROR: c_uint = 47;
const VAR_PRETRANSFER_TIME: c_uint = 48;
const VAR_POSTTRANSFER_TIME: c_uint = 49;
const VAR_PRIMARY_IP: c_uint = 50;
const VAR_PRIMARY_PORT: c_uint = 51;
const VAR_PROXY_SSL_VERIFY_RESULT: c_uint = 52;
const VAR_PROXY_USED: c_uint = 53;
const VAR_QUEUE_TIME: c_uint = 54;
const VAR_REDIRECT_COUNT: c_uint = 55;
const VAR_REDIRECT_TIME: c_uint = 56;
const VAR_REDIRECT_URL: c_uint = 57;
const VAR_REFERER: c_uint = 58;
const VAR_REQUEST_SIZE: c_uint = 59;
const VAR_SCHEME: c_uint = 60;
const VAR_SIZE_DELIVERED: c_uint = 61;
const VAR_SIZE_DOWNLOAD: c_uint = 62;
const VAR_SIZE_UPLOAD: c_uint = 63;
const VAR_SPEED_DOWNLOAD: c_uint = 64;
const VAR_SPEED_UPLOAD: c_uint = 65;
const VAR_SSL_VERIFY_RESULT: c_uint = 66;
const VAR_STARTTRANSFER_TIME: c_uint = 67;
const VAR_STDERR: c_uint = 68;
const VAR_STDOUT: c_uint = 69;
const VAR_TLS_EARLYDATA_SENT: c_uint = 70;
const VAR_TOTAL_TIME: c_uint = 71;
const VAR_URLNUM: c_uint = 72;

// Libc & libcurl externs
extern fn fputs(s: [*:0]const u8, stream: ?*FILE) callconv(.c) c_int;
extern fn fputc(c: c_int, stream: ?*FILE) callconv(.c) c_int;
extern fn fwrite(ptr: [*]const u8, size: usize, nmemb: usize, stream: ?*FILE) callconv(.c) usize;
extern fn fflush(stream: ?*FILE) callconv(.c) c_int;
extern fn getenv(name: [*:0]const u8) callconv(.c) ?[*:0]const u8;
extern fn malloc(size: usize) callconv(.c) ?*anyopaque;
extern fn free(ptr: ?*anyopaque) callconv(.c) void;

fn curlx_free(p: anytype) void {
    mem.free(p);
}

fn curlx_strdup(src: [*:0]const u8) ?[*:0]u8 {
    return mem.strdup(src);
}

extern fn curl_getenv(name: [*:0]const u8) callconv(.c) ?[*:0]u8;
extern fn curl_free(p: ?*anyopaque) callconv(.c) void;
extern fn curl_version() callconv(.c) [*:0]const u8;
extern fn curl_strnequal(s1: [*]const u8, s2: [*]const u8, max: usize) callconv(.c) c_int;
extern fn curl_msnprintf(buffer: [*]u8, maxlength: usize, format: [*:0]const u8, ...) callconv(.c) c_int;
extern fn curl_mfprintf(fd: ?*FILE, format: [*:0]const u8, ...) callconv(.c) c_int;
extern fn curl_maprintf(format: [*:0]const u8, ...) callconv(.c) ?[*:0]u8;
extern fn curl_easy_getinfo(curl: ?*CURL, info: c_uint, ...) callconv(.c) c_uint;
extern fn curl_easy_pause(handle: ?*CURL, bitmask: c_int) callconv(.c) c_uint;
extern fn curl_easy_strerror(code: c_uint) callconv(.c) [*:0]const u8;
extern fn curl_easy_header(easy: ?*CURL, name: [*:0]const u8, index: usize, origin: c_uint, request: c_int, hout: *?*curl_header) callconv(.c) c_uint;
extern fn curl_easy_nextheader(easy: ?*CURL, origin: c_uint, request: c_int, prev: ?*curl_header) callconv(.c) ?*curl_header;
extern fn curl_multi_get_offt(multi_handle: ?*CURLM, info: c_uint, pvalue: *curl_off_t) callconv(.c) c_uint;
extern fn curl_url() callconv(.c) ?*CURLU;
extern fn curl_url_cleanup(handle: ?*CURLU) callconv(.c) void;
extern fn curl_url_get(handle: ?*const CURLU, what: c_uint, part: *?[*:0]u8, flags: c_uint) callconv(.c) c_uint;
extern fn curl_url_set(handle: ?*CURLU, what: c_uint, part: ?[*:0]const u8, flags: c_uint) callconv(.c) c_uint;

extern fn curlx_str_number(linep: *[*:0]const u8, nump: *curl_off_t, max: curl_off_t) callconv(.c) c_int;
extern fn curlx_str_passblanks(linep: *[*]const u8) callconv(.c) void;
extern fn curlx_strcopy(dest: [*]u8, dsize: usize, src: [*]const u8, slen: usize) callconv(.c) void;
extern fn curlx_memdup0(src: [*]const u8, length: usize) callconv(.c) ?[*:0]u8;
extern fn curlx_pnow(pnow: *curltime) callconv(.c) void;
extern fn curlx_ptimediff_ms(newer: *const curltime, older: *const curltime) callconv(.c) timediff_t;
extern fn curlx_wait_ms(timeout_ms: timediff_t) callconv(.c) c_int;
extern fn curlx_dyn_init(s: *dynbuf, toobig: usize) callconv(.c) void;
extern fn curlx_dyn_free(s: *dynbuf) callconv(.c) void;
extern fn curlx_dyn_reset(s: *dynbuf) callconv(.c) void;
extern fn curlx_dyn_addn(s: *dynbuf, mem: [*]const u8, len: usize) callconv(.c) c_uint;
extern fn curlx_dyn_add(s: *dynbuf, str: [*:0]const u8) callconv(.c) c_uint;
extern fn curlx_dyn_addf(s: *dynbuf, fmt: [*:0]const u8, ...) callconv(.c) c_uint;
extern fn curlx_dyn_ptr(s: *const dynbuf) callconv(.c) ?[*:0]u8;
extern fn curlx_dyn_len(s: *const dynbuf) callconv(.c) usize;

// src/ C helpers and existing tool functions
extern fn slist_wc_append(list: ?*slist_wc, data: [*:0]const u8) callconv(.c) ?*slist_wc;
extern fn slist_wc_free_all(list: ?*slist_wc) callconv(.c) void;
extern fn proto_token(proto: ?[*:0]const u8) callconv(.c) ?[*:0]const u8;

extern fn tool_zig_manual_help_hint() callconv(.c) [*:0]const u8;
extern fn tool_zig_get_global() callconv(.c) ?*GlobalConfig;
extern fn tool_zig_get_transfers() callconv(.c) ?*per_transfer;
extern fn tool_zig_get_stdout() callconv(.c) ?*FILE;
extern fn tool_zig_get_stderr() callconv(.c) ?*FILE;
extern fn tool_zig_fopen_writetext() callconv(.c) [*:0]const u8;
extern fn tool_zig_fopen_appendtext() callconv(.c) [*:0]const u8;
extern fn tool_zig_fopen(fname: [*:0]const u8, mode: [*:0]const u8) callconv(.c) ?*FILE;
extern fn tool_zig_freopen(fname: [*:0]const u8, mode: [*:0]const u8, stream: ?*FILE) callconv(.c) ?*FILE;
extern fn tool_zig_fclose(stream: ?*FILE) callconv(.c) c_int;
extern fn tool_zig_os_terminal_cols() callconv(.c) c_int;
extern fn tool_zig_tvrealnow(sec: *curl_off_t, usec: *c_long) callconv(.c) void;
extern fn tool_zig_localtime_hms(tv_sec: curl_off_t, hour: *c_int, min: *c_int, sec: *c_int) callconv(.c) void;

extern fn tool_zig_global_tracetime(g: ?*const GlobalConfig) callconv(.c) bool;
extern fn tool_zig_global_traceids(g: ?*const GlobalConfig) callconv(.c) bool;
extern fn tool_zig_global_trace_stream(g: ?*const GlobalConfig) callconv(.c) ?*FILE;
extern fn tool_zig_global_set_trace_stream(g: ?*GlobalConfig, s: ?*FILE) callconv(.c) void;
extern fn tool_zig_global_trace_dump(g: ?*const GlobalConfig) callconv(.c) ?[*:0]const u8;
extern fn tool_zig_global_set_trace_fopened(g: ?*GlobalConfig, v: bool) callconv(.c) void;
extern fn tool_zig_global_tracetype(g: ?*const GlobalConfig) callconv(.c) c_uint;
extern fn tool_zig_global_isatty(g: ?*const GlobalConfig) callconv(.c) bool;
extern fn tool_zig_global_styled_output(g: ?*const GlobalConfig) callconv(.c) bool;
extern fn tool_zig_global_noprogress(g: ?*const GlobalConfig) callconv(.c) bool;
extern fn tool_zig_global_silent(g: ?*const GlobalConfig) callconv(.c) bool;
extern fn tool_zig_global_showerror(g: ?*const GlobalConfig) callconv(.c) bool;
extern fn tool_zig_term_has_bold() callconv(.c) bool;

extern fn tool_zig_config_output_dir(c: *const OperationConfig) callconv(.c) ?[*:0]const u8;
extern fn tool_zig_config_headerfile(c: *const OperationConfig) callconv(.c) ?[*:0]const u8;
extern fn tool_zig_config_etag_save_file(c: *const OperationConfig) callconv(.c) ?[*:0]const u8;
extern fn tool_zig_config_writeout(c: *const OperationConfig) callconv(.c) ?[*:0]const u8;
extern fn tool_zig_config_show_headers(c: *const OperationConfig) callconv(.c) bool;
extern fn tool_zig_config_readbusy(c: *const OperationConfig) callconv(.c) bool;
extern fn tool_zig_config_set_readbusy(c: *OperationConfig, v: bool) callconv(.c) void;
extern fn tool_zig_config_use_resume(c: *const OperationConfig) callconv(.c) bool;
extern fn tool_zig_config_resume_from(c: *const OperationConfig) callconv(.c) curl_off_t;
extern fn tool_zig_config_timeout_ms(c: *const OperationConfig) callconv(.c) c_long;
extern fn tool_zig_config_file_clobber_mode(c: *const OperationConfig) callconv(.c) c_uint;
extern fn tool_zig_config_terminal_binary_ok(c: *const OperationConfig) callconv(.c) bool;
extern fn tool_zig_config_nobuffer(c: *const OperationConfig) callconv(.c) bool;

extern fn tool_zig_outs_filename(o: *const OutStruct) callconv(.c) ?[*:0]u8;
extern fn tool_zig_outs_set_filename(o: *OutStruct, f: ?[*:0]u8) callconv(.c) void;
extern fn tool_zig_outs_stream(o: *const OutStruct) callconv(.c) ?*FILE;
extern fn tool_zig_outs_set_stream(o: *OutStruct, s: ?*FILE) callconv(.c) void;
extern fn tool_zig_outs_bytes(o: *const OutStruct) callconv(.c) curl_off_t;
extern fn tool_zig_outs_set_bytes(o: *OutStruct, b: curl_off_t) callconv(.c) void;
extern fn tool_zig_outs_set_init(o: *OutStruct, i: curl_off_t) callconv(.c) void;
extern fn tool_zig_outs_alloc_filename(o: *const OutStruct) callconv(.c) bool;
extern fn tool_zig_outs_set_alloc_filename(o: *OutStruct, v: bool) callconv(.c) void;
extern fn tool_zig_outs_is_cd_filename(o: *const OutStruct) callconv(.c) bool;
extern fn tool_zig_outs_set_is_cd_filename(o: *OutStruct, v: bool) callconv(.c) void;
extern fn tool_zig_outs_regular_file(o: *const OutStruct) callconv(.c) bool;
extern fn tool_zig_outs_set_regular_file(o: *OutStruct, v: bool) callconv(.c) void;
extern fn tool_zig_outs_fopened(o: *const OutStruct) callconv(.c) bool;
extern fn tool_zig_outs_set_fopened(o: *OutStruct, v: bool) callconv(.c) void;
extern fn tool_zig_outs_out_null(o: *const OutStruct) callconv(.c) bool;
extern fn tool_zig_outs_reset_utf8seq(o: *OutStruct) callconv(.c) void;

extern fn tool_zig_hdrcb_config(h: *const HdrCbData) callconv(.c) ?*OperationConfig;
extern fn tool_zig_hdrcb_headlist(h: *const HdrCbData) callconv(.c) ?*slist_wc;
extern fn tool_zig_hdrcb_set_headlist(h: *HdrCbData, l: ?*slist_wc) callconv(.c) void;
extern fn tool_zig_hdrcb_honor_cd_filename(h: *const HdrCbData) callconv(.c) bool;
extern fn tool_zig_hdrcb_set_honor_cd_filename(h: *HdrCbData, v: bool) callconv(.c) void;

extern fn tool_zig_per_next(p: *const per_transfer) callconv(.c) ?*per_transfer;
extern fn tool_zig_per_config(p: *const per_transfer) callconv(.c) ?*OperationConfig;
extern fn tool_zig_per_certinfo(p: *const per_transfer) callconv(.c) ?*const curl_certinfo;
extern fn tool_zig_per_set_certinfo(p: *per_transfer, ci: ?*const curl_certinfo) callconv(.c) void;
extern fn tool_zig_per_curl(p: *const per_transfer) callconv(.c) ?*CURL;
extern fn tool_zig_per_num_retries(p: *const per_transfer) callconv(.c) c_long;
extern fn tool_zig_per_start_ptr(p: *const per_transfer) callconv(.c) *const curltime;
extern fn tool_zig_per_url(p: *const per_transfer) callconv(.c) ?[*:0]const u8;
extern fn tool_zig_per_urlnum(p: *const per_transfer) callconv(.c) curl_off_t;
extern fn tool_zig_per_out_scheme(p: *const per_transfer) callconv(.c) ?[*:0]const u8;
extern fn tool_zig_per_set_out_scheme(p: *per_transfer, s: ?[*:0]const u8) callconv(.c) void;
extern fn tool_zig_per_infd(p: *const per_transfer) callconv(.c) c_int;
extern fn tool_zig_per_progressbar(p: *per_transfer) callconv(.c) *ProgressData;
extern fn tool_zig_per_outs(p: *per_transfer) callconv(.c) *OutStruct;
extern fn tool_zig_per_heads(p: *per_transfer) callconv(.c) *OutStruct;
extern fn tool_zig_per_etag_save(p: *per_transfer) callconv(.c) *OutStruct;
extern fn tool_zig_per_hdrcbdata(p: *per_transfer) callconv(.c) *HdrCbData;
extern fn tool_zig_per_num_headers(p: *const per_transfer) callconv(.c) c_long;
extern fn tool_zig_per_set_num_headers(p: *per_transfer, n: c_long) callconv(.c) void;
extern fn tool_zig_per_dltotal(p: *const per_transfer) callconv(.c) curl_off_t;
extern fn tool_zig_per_set_dltotal(p: *per_transfer, v: curl_off_t) callconv(.c) void;
extern fn tool_zig_per_dlnow(p: *const per_transfer) callconv(.c) curl_off_t;
extern fn tool_zig_per_set_dlnow(p: *per_transfer, v: curl_off_t) callconv(.c) void;
extern fn tool_zig_per_ultotal(p: *const per_transfer) callconv(.c) curl_off_t;
extern fn tool_zig_per_set_ultotal(p: *per_transfer, v: curl_off_t) callconv(.c) void;
extern fn tool_zig_per_ulnow(p: *const per_transfer) callconv(.c) curl_off_t;
extern fn tool_zig_per_set_ulnow(p: *per_transfer, v: curl_off_t) callconv(.c) void;
extern fn tool_zig_per_uploadfilesize(p: *const per_transfer) callconv(.c) curl_off_t;
extern fn tool_zig_per_uploadedsofar(p: *const per_transfer) callconv(.c) curl_off_t;
extern fn tool_zig_per_dltotal_added(p: *const per_transfer) callconv(.c) bool;
extern fn tool_zig_per_set_dltotal_added(p: *per_transfer, v: bool) callconv(.c) void;
extern fn tool_zig_per_ultotal_added(p: *const per_transfer) callconv(.c) bool;
extern fn tool_zig_per_set_ultotal_added(p: *per_transfer, v: bool) callconv(.c) void;
extern fn tool_zig_per_noprogress(p: *const per_transfer) callconv(.c) bool;
extern fn tool_zig_per_was_last_header_empty(p: *const per_transfer) callconv(.c) bool;
extern fn tool_zig_per_set_was_last_header_empty(p: *per_transfer, v: bool) callconv(.c) void;
extern fn tool_zig_per_abort(p: *const per_transfer) callconv(.c) bool;
extern fn tool_zig_per_errorbuffer(p: *const per_transfer) callconv(.c) [*:0]const u8;

extern fn tool_zig_scheme_is_http_or_https(scheme: ?[*:0]const u8) callconv(.c) bool;
extern fn tool_zig_scheme_is_header_shown(scheme: ?[*:0]const u8) callconv(.c) bool;
extern fn tool_zig_sanitize_filename(copy: [*:0]u8) callconv(.c) ?[*:0]u8;
extern fn tool_zig_truncate_regular_stream(stream: ?*FILE) callconv(.c) bool;
extern fn tool_zig_waitfd(waitms: c_int, fd: c_int) callconv(.c) void;
extern fn tool_zig_read_fd(per: *per_transfer, buffer: [*]u8, nbytes: usize, is_eagain: *bool) callconv(.c) isize;
extern fn tool_zig_seek_fd(fd: c_int, offset: curl_off_t, whence: c_int) callconv(.c) c_int;
extern fn tool_zig_ftruncate64(fd: c_int, where: curl_off_t) callconv(.c) c_int;
extern fn tool_zig_open_socket(family: c_int, socktype: c_int, protocol: c_int) callconv(.c) curl_socket_t;
extern fn tool_zig_open_excl(fname: [*:0]const u8, is_exist_or_isdir: *bool) callconv(.c) c_int;
extern fn tool_zig_fdopen_wb(fd: c_int) callconv(.c) ?*FILE;
extern fn tool_zig_strerror_errno(buf: [*]u8, len: usize) callconv(.c) [*:0]const u8;
extern fn tool_zig_win_console_write(stream: ?*FILE, outs: *OutStruct, buffer: [*]u8, bytes: usize, rc_out: *usize) callconv(.c) c_int;
extern fn tool_zig_fflush_retry(stream: ?*FILE) callconv(.c) bool;
extern fn tool_zig_gettime_now(secs: *curl_off_t, usecs: *c_uint) callconv(.c) void;
extern fn tool_zig_strftime_utc(secs: curl_off_t, fmt: [*:0]const u8, output: [*]u8, outsize: usize) callconv(.c) bool;

// ============================================================================
// Small internal string helpers
// ============================================================================

inline fn isBlank(ch: u8) bool {
    return ch == ' ' or ch == '\t';
}

inline fn isSpace(ch: u8) bool {
    return ch == ' ' or ch == '\t' or ch == '\r' or ch == '\n' or ch == 0x0b or ch == 0x0c;
}

inline fn isAlpha(ch: u8) bool {
    return (ch >= 'a' and ch <= 'z') or (ch >= 'A' and ch <= 'Z');
}

fn findCharMut(s: [*:0]u8, target: u8) ?[*:0]u8 {
    var i: usize = 0;
    while (s[i] != 0) : (i += 1) {
        if (s[i] == target) return s + i;
    }
    return null;
}

fn findLastCharMut(s: [*:0]u8, target: u8) ?[*:0]u8 {
    var last: ?[*:0]u8 = null;
    var i: usize = 0;
    while (s[i] != 0) : (i += 1) {
        if (s[i] == target) last = s + i;
    }
    return last;
}

fn findCharConst(s: [*:0]const u8, target: u8) ?[*:0]const u8 {
    var i: usize = 0;
    while (s[i] != 0) : (i += 1) {
        if (s[i] == target) return s + i;
    }
    return null;
}

fn findLastCharConst(s: [*:0]const u8, target: u8) ?[*:0]const u8 {
    var last: ?[*:0]const u8 = null;
    var i: usize = 0;
    while (s[i] != 0) : (i += 1) {
        if (s[i] == target) last = s + i;
    }
    return last;
}

// ============================================================================
// 1. src/tool_stderr.c
// ============================================================================

pub export var tool_stderr: ?*FILE = null;

export fn tool_init_stderr() callconv(.c) void {
    tool_stderr = tool_zig_get_stderr();
}

export fn tool_set_stderr_file(filename: ?[*:0]const u8) callconv(.c) void {
    const fname = filename orelse return;
    if (std.mem.orderZ(u8, fname, "-") == .eq) {
        tool_stderr = tool_zig_get_stdout();
        return;
    }

    const mode = tool_zig_fopen_writetext();
    const fp = tool_zig_fopen(fname, mode);
    if (fp == null) {
        if (curl_maprintf("Warning: Failed to open %s", fname)) |msg| {
            defer curl_free(msg);
            warnf_str(msg);
        }
        return;
    }
    _ = tool_zig_fclose(fp);

    const fp2 = tool_zig_freopen(fname, mode, tool_zig_get_stderr());
    if (fp2 == null) {
        return;
    }
    tool_stderr = tool_zig_get_stderr();
}

// ============================================================================
// 2. src/terminal.c
// ============================================================================

export fn get_terminal_columns() callconv(.c) c_uint {
    var width: c_uint = 0;
    if (curl_getenv("COLUMNS")) |colp| {
        var num: curl_off_t = 0;
        var p: [*:0]const u8 = colp;
        if (curlx_str_number(&p, &num, 10000) == 0 and num > 20) {
            width = @intCast(num);
        }
        curl_free(colp);
    }

    if (width == 0) {
        const cols = tool_zig_os_terminal_cols();
        if (cols >= 0 and cols < 10000) {
            width = @intCast(cols);
        }
    }
    if (width == 0) {
        width = 79;
    }
    return width;
}

// ============================================================================
// 3. src/tool_msgs.c
// ============================================================================

const WARN_PREFIX: [*:0]const u8 = "Warning: ";
const NOTE_PREFIX: [*:0]const u8 = "Note: ";
const ERROR_PREFIX: [*:0]const u8 = "curl: ";

pub fn nextLineWrapCut(ptr: [*]const u8, width: usize) usize {
    var cut: usize = width - 1;
    while (cut > 0 and !isBlank(ptr[cut])) {
        cut -= 1;
    }
    if (cut == 0) {
        cut = width - 1;
    }
    return cut;
}

export fn tool_voutf_zig(global_cfg: ?*GlobalConfig, prefix: [*:0]const u8, msg: [*:0]const u8) callconv(.c) void {
    _ = global_cfg;
    const termw: usize = @intCast(get_terminal_columns());
    const prefw: usize = std.mem.len(prefix);
    const width: usize = if (termw > prefw) termw - prefw else std.math.maxInt(usize);
    var ptr: [*:0]const u8 = msg;
    var len: usize = std.mem.len(msg);
    const err_stream = tool_stderr;

    while (len > 0) {
        _ = fputs(prefix, err_stream);

        if (len > width) {
            const cut = nextLineWrapCut(ptr, width);
            _ = fwrite(ptr, cut + 1, 1, err_stream);
            _ = fputs("\n", err_stream);
            ptr += cut + 1;
            len -= cut + 1;
        } else {
            _ = fputs(ptr, err_stream);
            _ = fputs("\n", err_stream);
            len = 0;
        }
    }
}

export fn voutf(prefix: [*:0]const u8, msg: [*:0]const u8) callconv(.c) void {
    tool_voutf_zig(tool_zig_get_global(), prefix, msg);
}

export fn tool_helpf_zig(msg: ?[*:0]const u8) callconv(.c) void {
    const err_stream = tool_stderr;
    if (msg) |m| {
        _ = fputs("curl: ", err_stream);
        _ = fputs(m, err_stream);
        _ = fputs("\n", err_stream);
    }
    _ = fputs("curl: try 'curl --help' ", err_stream);
    const manual_hint = tool_zig_manual_help_hint();
    if (manual_hint[0] != 0) {
        _ = fputs(manual_hint, err_stream);
    }
    _ = fputs("for more information\n", err_stream);
}

fn warnf_str(msg: [*:0]const u8) void {
    const g = tool_zig_get_global();
    if (g == null or !tool_zig_global_silent(g)) {
        tool_voutf_zig(g, WARN_PREFIX, msg);
    }
}

fn errorf_str(msg: [*:0]const u8) void {
    const g = tool_zig_get_global();
    if (g == null or !tool_zig_global_silent(g) or tool_zig_global_showerror(g)) {
        tool_voutf_zig(g, ERROR_PREFIX, msg);
    }
}

// ============================================================================
// 4. src/tool_cb_dbg.c
// ============================================================================

const HmsState = struct {
    var cached_tv_sec: curl_off_t = 0;
    var hms_buf: [12:0]u8 = @splat(0);
};

fn hms_for_sec(tv_sec: curl_off_t) [*:0]const u8 {
    if (tv_sec != HmsState.cached_tv_sec) {
        var hour: c_int = 0;
        var min: c_int = 0;
        var sec: c_int = 0;
        tool_zig_localtime_hms(tv_sec, &hour, &min, &sec);
        _ = curl_msnprintf(&HmsState.hms_buf, HmsState.hms_buf.len + 1, "%02d:%02d:%02d", hour, min, sec);
        HmsState.cached_tv_sec = tv_sec;
    }
    return &HmsState.hms_buf;
}

fn log_line_start(log: ?*FILE, time_buf: [*:0]const u8, idsbuf: [*:0]const u8, info_type: c_uint) void {
    const s_infotype = [_][*:0]const u8{
        "* ", "< ", "> ", "{ ", "} ", "{ ", "} ",
    };
    const prefix = if (info_type < s_infotype.len) s_infotype[info_type] else "* ";
    if (time_buf[0] != 0 or idsbuf[0] != 0) {
        _ = curl_mfprintf(log, "%s%s%s", time_buf, idsbuf, prefix);
    } else {
        _ = fputs(prefix, log);
    }
}

fn dump(
    time_buf: [*:0]const u8,
    idsbuf: [*:0]const u8,
    text: [*:0]const u8,
    stream: ?*FILE,
    ptr: [*]const u8,
    size: usize,
    tracetype: c_uint,
    infotype: c_uint,
) void {
    _ = infotype;
    const width: usize = if (tracetype == TRACE_ASCII) 0x40 else 0x10;

    _ = curl_mfprintf(stream, "%s%s%s, %zu bytes (0x%zx)\n", time_buf, idsbuf, text, size, size);

    var i: usize = 0;
    while (i < size) {
        var next_i: usize = i + width;
        _ = curl_mfprintf(stream, "%04zx: ", i);

        if (tracetype == TRACE_BIN) {
            var c: usize = 0;
            while (c < width) : (c += 1) {
                if (i + c < size) {
                    _ = curl_mfprintf(stream, "%02x ", @as(c_uint, ptr[i + c]));
                } else {
                    _ = fputs("   ", stream);
                }
            }
        }

        var c: usize = 0;
        while (c < width and i + c < size) : (c += 1) {
            if (tracetype == TRACE_ASCII and
                i + c + 1 < size and
                ptr[i + c] == 0x0D and
                ptr[i + c + 1] == 0x0A)
            {
                next_i = i + c + 2;
                break;
            }
            const ch: u8 = if (ptr[i + c] >= 0x20 and ptr[i + c] < 0x7F) ptr[i + c] else UNPRINTABLE_CHAR;
            _ = fputc(@intCast(ch), stream);
            if (tracetype == TRACE_ASCII and
                i + c + 2 < size and
                ptr[i + c + 1] == 0x0D and
                ptr[i + c + 2] == 0x0A)
            {
                next_i = i + c + 3;
                break;
            }
        }
        _ = fputc('\n', stream);
        i = next_i;
    }
    _ = fflush(stream);
}

export fn tool_debug_cb(
    handle: ?*CURL,
    info_type: c_uint,
    data: [*]u8,
    size: usize,
    userdata: ?*OperationConfig,
) callconv(.c) c_int {
    _ = userdata;
    const g = tool_zig_get_global();
    var time_buf: [20:0]u8 = @splat(0);
    var idsbuf: [60:0]u8 = @splat(0);

    if (tool_zig_global_tracetime(g)) {
        var tv_sec: curl_off_t = 0;
        var tv_usec: c_long = 0;
        tool_zig_tvrealnow(&tv_sec, &tv_usec);
        _ = curl_msnprintf(&time_buf, time_buf.len + 1, "%s.%06ld ", hms_for_sec(tv_sec), tv_usec);
    } else {
        time_buf[0] = 0;
    }

    var xfer_id: curl_off_t = 0;
    var conn_id: curl_off_t = 0;
    if (handle != null and tool_zig_global_traceids(g) and
        curl_easy_getinfo(handle, CURLINFO_XFER_ID, &xfer_id) == 0 and xfer_id >= 0)
    {
        if (curl_easy_getinfo(handle, CURLINFO_CONN_ID, &conn_id) == 0 and conn_id >= 0) {
            _ = curl_msnprintf(&idsbuf, idsbuf.len + 1, "[%lld-%lld] ", xfer_id, conn_id);
        } else {
            _ = curl_msnprintf(&idsbuf, idsbuf.len + 1, "[%lld-x] ", xfer_id);
        }
    } else {
        idsbuf[0] = 0;
    }

    if (tool_zig_global_trace_stream(g) == null) {
        if (tool_zig_global_trace_dump(g)) |trace_dump| {
            if (std.mem.orderZ(u8, trace_dump, "-") == .eq) {
                tool_zig_global_set_trace_stream(g, tool_zig_get_stdout());
            } else if (std.mem.orderZ(u8, trace_dump, "%") == .eq) {
                tool_zig_global_set_trace_stream(g, tool_stderr);
            } else {
                tool_zig_global_set_trace_stream(g, tool_zig_fopen(trace_dump, tool_zig_fopen_writetext()));
                tool_zig_global_set_trace_fopened(g, true);
            }
        }
    }

    var output: ?*FILE = tool_stderr;
    if (tool_zig_global_trace_stream(g)) |ts| {
        output = ts;
    }

    if (output == null) {
        warnf_str("Failed to create/open output");
        return 0;
    }

    const time_cstr: [*:0]const u8 = &time_buf;
    const ids_cstr: [*:0]const u8 = &idsbuf;
    const tracetype = tool_zig_global_tracetype(g);

    if (tracetype == TRACE_PLAIN) {
        const PlainState = struct {
            var newl: bool = false;
            var traced_data: bool = false;
        };

        switch (info_type) {
            CURLINFO_HEADER_OUT => {
                if (size > 0) {
                    var st: usize = 0;
                    var i: usize = 0;
                    while (i < size - 1) : (i += 1) {
                        if (data[i] == '\n') {
                            if (!PlainState.newl) {
                                log_line_start(output, time_cstr, ids_cstr, info_type);
                            }
                            _ = fwrite(data + st, i - st + 1, 1, output);
                            st = i + 1;
                            PlainState.newl = false;
                        }
                    }
                    if (!PlainState.newl) {
                        log_line_start(output, time_cstr, ids_cstr, info_type);
                    }
                    _ = fwrite(data + st, i - st + 1, 1, output);
                }
                PlainState.newl = (size > 0 and data[size - 1] != '\n');
                PlainState.traced_data = false;
            },
            CURLINFO_TEXT, CURLINFO_HEADER_IN => {
                if (!PlainState.newl) {
                    log_line_start(output, time_cstr, ids_cstr, info_type);
                }
                _ = fwrite(data, size, 1, output);
                PlainState.newl = (size > 0 and data[size - 1] != '\n');
                PlainState.traced_data = false;
            },
            CURLINFO_DATA_OUT, CURLINFO_DATA_IN, CURLINFO_SSL_DATA_IN, CURLINFO_SSL_DATA_OUT => {
                if (!PlainState.traced_data and
                    (!tool_zig_global_isatty(g) or
                        (output != tool_stderr and output != tool_zig_get_stdout())))
                {
                    if (!PlainState.newl) {
                        log_line_start(output, time_cstr, ids_cstr, info_type);
                    }
                    _ = curl_mfprintf(output, "[%zu bytes data]\n", size);
                    PlainState.newl = false;
                    PlainState.traced_data = true;
                }
            },
            else => {
                PlainState.newl = false;
                PlainState.traced_data = false;
            },
        }
        return 0;
    }

    const text: [*:0]const u8 = switch (info_type) {
        CURLINFO_TEXT => {
            _ = curl_mfprintf(output, "%s%s* %.*s", time_cstr, ids_cstr, @as(c_int, @intCast(size)), data);
            return 0;
        },
        CURLINFO_HEADER_OUT => "=> Send header",
        CURLINFO_DATA_OUT => "=> Send data",
        CURLINFO_HEADER_IN => "<= Recv header",
        CURLINFO_DATA_IN => "<= Recv data",
        CURLINFO_SSL_DATA_IN => "<= Recv SSL data",
        CURLINFO_SSL_DATA_OUT => "=> Send SSL data",
        else => return 0,
    };

    dump(time_cstr, ids_cstr, text, output, data, size, tracetype, info_type);
    return 0;
}

// ============================================================================
// 5. src/tool_cb_hdr.c
// ============================================================================

const BOLD = "\x1b[1m";
const BOLDOFF = if (builtin.os.tag == .windows) "\x1b[22m" else "\x1b[0m";
const LINK = "\x1b]8;;";
const LINKST = "\x1b\\";
const LINKOFF = LINK ++ LINKST;

fn write_linked_location(curl: ?*CURL, location: [*]const u8, loclen: usize, stream: ?*FILE) void {
    var u: ?*CURLU = null;
    var copyloc: ?[*:0]u8 = null;
    var scheme: ?[*:0]u8 = null;
    var finalurl: ?[*:0]u8 = null;
    var loc: [*]const u8 = location;
    var locurl: ?[*:0]const u8 = null;
    var llen: usize = loclen;
    var space_skipped: c_int = 0;

    defer {
        if (u != null) {
            curl_free(finalurl);
            curl_free(scheme);
            curl_url_cleanup(u);
            curlx_free(copyloc);
        }
    }

    if (getenv("VTE_VERSION")) |vver_init| {
        var vver = vver_init;
        var num: curl_off_t = 0;
        if (curlx_str_number(&vver, &num, CURL_OFF_T_MAX) != 0 or num <= 4801) {
            _ = fwrite(location, loclen, 1, stream);
            return;
        }
    }

    while (llen > 0 and (loc[0] == ' ' or loc[0] == '\t')) {
        loc += 1;
        llen -= 1;
        space_skipped += 1;
    }

    while (llen > 0 and (loc[llen - 1] == '\n' or loc[llen - 1] == '\r')) {
        llen -= 1;
    }

    u = curl_url();
    if (u == null) {
        _ = fwrite(location, loclen, 1, stream);
        return;
    }

    copyloc = curlx_memdup0(loc, llen);
    if (copyloc == null) {
        _ = fwrite(location, loclen, 1, stream);
        return;
    }

    if (curl_easy_getinfo(curl, CURLINFO_EFFECTIVE_URL, &locurl) != 0 or
        curl_url_set(u, CURLUPART_URL, locurl, 0) != 0 or
        curl_url_set(u, CURLUPART_URL, copyloc, 0) != 0 or
        curl_url_get(u, CURLUPART_URL, &finalurl, CURLU_NO_DEFAULT_PORT) != 0 or
        curl_url_get(u, CURLUPART_SCHEME, &scheme, 0) != 0)
    {
        _ = fwrite(location, loclen, 1, stream);
        return;
    }

    if (scheme) |sc| {
        if (std.mem.orderZ(u8, sc, "http") == .eq or
            std.mem.orderZ(u8, sc, "https") == .eq or
            std.mem.orderZ(u8, sc, "ftp") == .eq or
            std.mem.orderZ(u8, sc, "ftps") == .eq)
        {
            const rem_len: c_int = @as(c_int, @intCast(loclen)) - space_skipped;
            _ = curl_mfprintf(
                stream,
                "%.*s" ++ LINK ++ "%s" ++ LINKST ++ "%.*s" ++ LINKOFF,
                space_skipped,
                location,
                finalurl.?,
                rem_len,
                loc,
            );
            return;
        }
    }

    _ = fwrite(location, loclen, 1, stream);
}

fn parseFilenameInner(ptr: [*]const u8, len: usize, stop_in: u8) error{InvalidFilename}![*:0]u8 {
    const copy = curlx_memdup0(ptr, len) orelse return error.InvalidFilename;
    errdefer curlx_free(copy);
    var p: [*:0]u8 = copy;
    var stop = stop_in;
    if (stop != 0) {
        if (p[0] == '\'' or p[0] == '"') {
            stop = p[0];
            p += 1;
        }
        if (findCharMut(p, stop)) |q| {
            q[0] = 0;
        }
    } else {
        if (findCharMut(p, '?')) |q| {
            q[0] = 0;
        }
        if (findCharMut(p, '#')) |q| {
            q[0] = 0;
        }
    }

    if (findLastCharMut(p, '/')) |q| {
        p = q + 1;
        if (p[0] == 0) return error.InvalidFilename;
    }

    if (findLastCharMut(p, '\\')) |q| {
        p = q + 1;
        if (p[0] == 0) return error.InvalidFilename;
    }

    if (findCharMut(p, '\r')) |q| {
        q[0] = 0;
    }
    if (findCharMut(p, '\n')) |q| {
        q[0] = 0;
    }

    if (copy != p) {
        const plen = std.mem.len(p);
        std.mem.copyForwards(u8, copy[0 .. plen + 1], p[0 .. plen + 1]);
    }

    return copy;
}

fn parse_filename(ptr: [*]const u8, len: usize, stop_in: u8) ?[*:0]u8 {
    const copy = parseFilenameInner(ptr, len, stop_in) catch return null;
    return tool_zig_sanitize_filename(copy);
}

export fn tool_write_headers(hdrcbdata: *HdrCbData, stream: ?*FILE) callconv(.c) c_int {
    const headlist = tool_zig_hdrcb_headlist(hdrcbdata);
    var h: ?*curl_slist = if (headlist) |hl| hl.first else null;
    var rc: c_int = 1;
    while (h) |node| : (h = node.next) {
        if (node.data) |d| {
            const len = std.mem.len(d);
            if (len != fwrite(d, 1, len, stream)) {
                slist_wc_free_all(headlist);
                tool_zig_hdrcb_set_headlist(hdrcbdata, null);
                return rc;
            }
        }
    }
    rc = 0;
    slist_wc_free_all(headlist);
    tool_zig_hdrcb_set_headlist(hdrcbdata, null);
    return rc;
}

fn bufferHeaderInner(hdrcbdata: *HdrCbData, str: [*]const u8, cb: usize) error{OutOfMemory}!usize {
    const headlist = tool_zig_hdrcb_headlist(hdrcbdata);
    errdefer {
        slist_wc_free_all(headlist);
        tool_zig_hdrcb_set_headlist(hdrcbdata, null);
    }
    const clone = curlx_memdup0(str, cb) orelse return error.OutOfMemory;
    defer curlx_free(clone);
    const entry = slist_wc_append(headlist, clone) orelse return error.OutOfMemory;
    tool_zig_hdrcb_set_headlist(hdrcbdata, entry);
    return cb;
}

fn buffer_header(hdrcbdata: *HdrCbData, str: [*]const u8, cb: usize) usize {
    return bufferHeaderInner(hdrcbdata, str, cb) catch CURL_WRITEFUNC_ERROR;
}

fn save_etag(etag_h_in: [*]const u8, endp: [*]const u8, etag_save: *OutStruct) usize {
    if (@intFromPtr(endp) <= @intFromPtr(etag_h_in)) return 0;
    var etag_h = etag_h_in;
    var eot = endp - 1;
    if (eot[0] == '\n') {
        while (isBlank(etag_h[0]) and @intFromPtr(etag_h) < @intFromPtr(eot)) {
            etag_h += 1;
        }
        while (@intFromPtr(eot) >= @intFromPtr(etag_h) and isSpace(eot[0])) {
            if (@intFromPtr(eot) == @intFromPtr(etag_h)) {
                return 0;
            }
            eot -= 1;
        }

        if (@intFromPtr(eot) >= @intFromPtr(etag_h)) {
            const etag_length = (@intFromPtr(eot) - @intFromPtr(etag_h)) + 1;
            const stream = tool_zig_outs_stream(etag_save);
            if (tool_zig_outs_regular_file(etag_save) and !tool_zig_truncate_regular_stream(stream)) {
                return CURL_WRITEFUNC_ERROR;
            }
            _ = fwrite(etag_h, 1, etag_length, stream);
            _ = fputc('\n', stream);
            _ = fflush(stream);
        }
    }
    return 0;
}

fn setFilenameInner(outs: *OutStruct, per: *per_transfer, filename: [*:0]u8) error{SetFilenameFailed}!void {
    errdefer curlx_free(filename);
    if (tool_zig_outs_stream(outs) != null) return error.SetFilenameFailed;

    if (tool_zig_outs_alloc_filename(outs)) {
        curlx_free(tool_zig_outs_filename(outs));
        tool_zig_outs_set_filename(outs, null);
    }

    const config = tool_zig_per_config(per).?;
    if (tool_zig_config_output_dir(config)) |out_dir| {
        const f = curl_maprintf("%s/%s", out_dir, filename) orelse return error.SetFilenameFailed;
        defer curl_free(f);
        curlx_free(filename);
        const dup = curlx_strdup(f);
        tool_zig_outs_set_filename(outs, dup);
        if (dup == null) return error.SetFilenameFailed;
    } else {
        tool_zig_outs_set_filename(outs, filename);
    }
}

fn set_filename(outs: *OutStruct, per: *per_transfer, filename: [*:0]u8) bool {
    setFilenameInner(outs, per, filename) catch return false;
    return true;
}

fn content_disposition(
    str: [*]const u8,
    end: [*]const u8,
    cb: usize,
    per: *per_transfer,
    response: c_long,
) usize {
    const hdrcbdata = tool_zig_per_hdrcbdata(per);
    const outs = tool_zig_per_outs(per);
    const config = tool_zig_per_config(per);

    if (cb > 9 and curl_strnequal(str, "Location:", 9) != 0 and @divTrunc(response, 100) == 3) {
        var p: [*]const u8 = str + 9;
        curlx_str_passblanks(&p);
        if (@intFromPtr(p) < @intFromPtr(end)) {
            const offset = @intFromPtr(p) - @intFromPtr(str);
            if (parse_filename(p, cb - offset, 0)) |filename| {
                if (!set_filename(outs, per, filename))
                    return CURL_WRITEFUNC_ERROR;
                tool_zig_outs_set_alloc_filename(outs, true);
                tool_zig_outs_set_is_cd_filename(outs, true);
            }
        }
    } else if (cb > 20 and curl_strnequal(str, "Content-disposition:", 20) != 0) {
        var p: [*]const u8 = str + 20;
        const end_addr = @intFromPtr(end);
        while (true) {
            while (@intFromPtr(p) < end_addr and p[0] != 0 and !isAlpha(p[0])) {
                p += 1;
            }
            if (end_addr < 9 or @intFromPtr(p) > end_addr - 9) {
                break;
            }
            if (!std.mem.eql(u8, p[0..9], "filename=")) {
                while (@intFromPtr(p) < end_addr and p[0] != 0 and p[0] != ';') {
                    p += 1;
                }
                if (@intFromPtr(p) < end_addr and p[0] != 0)
                    continue
                else
                    break;
            }
            p += 9;
            curlx_str_passblanks(&p);
            const len = cb - (@intFromPtr(p) - @intFromPtr(str));
            if (parse_filename(p, len, ';')) |filename| {
                if (!set_filename(outs, per, filename))
                    return CURL_WRITEFUNC_ERROR;
                tool_zig_outs_set_is_cd_filename(outs, true);
                tool_zig_outs_set_regular_file(outs, true);
                tool_zig_outs_set_fopened(outs, false);
                tool_zig_outs_set_alloc_filename(outs, true);
                tool_zig_hdrcb_set_honor_cd_filename(hdrcbdata, false);
                if (!tool_create_output_file(outs, config))
                    return CURL_WRITEFUNC_ERROR;
                if (tool_write_headers(hdrcbdata, tool_zig_outs_stream(outs)) != 0)
                    return CURL_WRITEFUNC_ERROR;
            }
            break;
        }
        if (tool_zig_outs_stream(outs) == null and !tool_create_output_file(outs, config))
            return CURL_WRITEFUNC_ERROR;
        if (tool_write_headers(hdrcbdata, tool_zig_outs_stream(outs)) != 0)
            return CURL_WRITEFUNC_ERROR;
    }

    if (tool_zig_hdrcb_honor_cd_filename(hdrcbdata)) {
        if (tool_zig_hdrcb_config(hdrcbdata)) |hcfg| {
            if (tool_zig_config_show_headers(hcfg)) {
                return buffer_header(hdrcbdata, str, cb);
            }
        }
    }

    return 0;
}

export fn tool_header_cb(ptr: [*]u8, size: usize, nmemb: usize, userdata: ?*per_transfer) callconv(.c) usize {
    const per = userdata orelse return CURL_WRITEFUNC_ERROR;
    const config = tool_zig_per_config(per) orelse return CURL_WRITEFUNC_ERROR;
    const hdrcbdata = tool_zig_per_hdrcbdata(per);
    const outs = tool_zig_per_outs(per);
    const heads = tool_zig_per_heads(per);
    const etag_save = tool_zig_per_etag_save(per);
    const str: [*]const u8 = ptr;
    const cb = size * nmemb;
    const end = str + cb;
    var cd_checked = false;

    tool_zig_outs_reset_utf8seq(outs);

    if (tool_zig_per_out_scheme(per) == null or tool_zig_per_was_last_header_empty(per)) {
        var scheme: ?[*:0]const u8 = null;
        _ = curl_easy_getinfo(tool_zig_per_curl(per), CURLINFO_SCHEME, &scheme);
        tool_zig_per_set_out_scheme(per, proto_token(scheme));
        tool_zig_per_set_num_headers(per, 0);
    }
    tool_zig_per_set_was_last_header_empty(per, cb > 0 and (ptr[0] == '\r' or ptr[0] == '\n'));

    if (tool_zig_config_headerfile(config)) |hfile| {
        if (tool_zig_outs_stream(heads)) |hstream| {
            const rc = fwrite(ptr, size, nmemb, hstream);
            if (rc != nmemb) return rc;
            if (fflush(hstream) != 0) {
                if (curl_maprintf("Failed writing headers to %s", hfile)) |msg| {
                    defer curl_free(msg);
                    errorf_str(msg);
                }
                return CURL_WRITEFUNC_ERROR;
            }
        }
    }

    const out_scheme = tool_zig_per_out_scheme(per);
    if (tool_zig_scheme_is_http_or_https(out_scheme)) {
        var response: c_long = 0;
        _ = curl_easy_getinfo(tool_zig_per_curl(per), CURLINFO_RESPONSE_CODE, &response);

        if (@divTrunc(response, 100) != 2 and @divTrunc(response, 100) != 3) {
            // ignore
        } else if (tool_zig_config_etag_save_file(config) != null and
            tool_zig_outs_stream(etag_save) != null and
            cb >= 5 and curl_strnequal(str, "etag:", 5) != 0)
        {
            const rc = save_etag(str + 5, end, etag_save);
            if (rc != 0) return rc;
        } else if (tool_zig_hdrcb_honor_cd_filename(hdrcbdata)) {
            const rc = content_disposition(str, end, cb, per, response);
            if (rc != 0) return rc;
            cd_checked = true;
        }
    }

    if (tool_zig_hdrcb_config(hdrcbdata)) |hcfg| {
        if (tool_zig_config_writeout(hcfg) != null and std.mem.indexOfScalar(u8, ptr[0..cb], ':') != null) {
            tool_zig_per_set_num_headers(per, tool_zig_per_num_headers(per) + 1);
        }

        if (tool_zig_config_show_headers(hcfg) and !tool_zig_outs_out_null(outs) and
            tool_zig_scheme_is_header_shown(out_scheme))
        {
            if (tool_zig_hdrcb_honor_cd_filename(hdrcbdata) and !cd_checked and
                tool_zig_scheme_is_http_or_https(out_scheme))
            {
                return buffer_header(hdrcbdata, str, cb);
            }

            if (tool_zig_outs_stream(outs) == null and !tool_create_output_file(outs, config))
                return CURL_WRITEFUNC_ERROR;

            const g = tool_zig_get_global();
            var colon_idx: ?usize = null;
            if (tool_zig_global_isatty(g) and tool_zig_term_has_bold() and tool_zig_global_styled_output(g)) {
                colon_idx = std.mem.indexOfScalar(u8, ptr[0..cb], ':');
            }

            const out_stream = tool_zig_outs_stream(outs);
            if (colon_idx) |namelen| {
                _ = curl_mfprintf(out_stream, BOLD ++ "%.*s" ++ BOLDOFF ++ ":", @as(c_int, @intCast(namelen)), ptr);
                if (builtin.os.tag != .windows and namelen == 8 and curl_strnequal("Location", ptr, namelen) != 0) {
                    write_linked_location(tool_zig_per_curl(per), ptr + namelen + 1, cb - namelen - 1, out_stream);
                } else {
                    _ = fwrite(ptr + namelen + 1, cb - namelen - 1, 1, out_stream);
                }
            } else {
                _ = fwrite(ptr, cb, 1, out_stream);
            }
        }
    }

    return cb;
}

// ============================================================================
// 6. src/tool_cb_prg.c
// ============================================================================

const MAX_BARLENGTH: c_int = 400;
const MIN_BARLENGTH: c_int = 20;

const sinus = [200]c_int{
    515704, 531394, 547052, 562664, 578214, 593687, 609068, 624341, 639491,
    654504, 669364, 684057, 698568, 712883, 726989, 740870, 754513, 767906,
    781034, 793885, 806445, 818704, 830647, 842265, 853545, 864476, 875047,
    885248, 895069, 904500, 913532, 922156, 930363, 938145, 945495, 952406,
    958870, 964881, 970434, 975522, 980141, 984286, 987954, 991139, 993840,
    996054, 997778, 999011, 999752, 999999, 999754, 999014, 997783, 996060,
    993848, 991148, 987964, 984298, 980154, 975536, 970449, 964898, 958888,
    952426, 945516, 938168, 930386, 922180, 913558, 904527, 895097, 885277,
    875077, 864507, 853577, 842299, 830682, 818739, 806482, 793922, 781072,
    767945, 754553, 740910, 727030, 712925, 698610, 684100, 669407, 654548,
    639536, 624386, 609113, 593733, 578260, 562710, 547098, 531440, 515751,
    500046, 484341, 468651, 452993, 437381, 421830, 406357, 390976, 375703,
    360552, 345539, 330679, 315985, 301474, 287158, 273052, 259170, 245525,
    232132, 219003, 206152, 193590, 181331, 169386, 157768, 146487, 135555,
    124983, 114781, 104959, 95526,  86493,  77868,  69660,  61876,  54525,
    47613,  41147,  35135,  29581,  24491,  19871,  15724,  12056,  8868,
    6166,   3951,   2225,   990,    248,    0,      244,    982,    2212,
    3933,   6144,   8842,   12025,  15690,  19832,  24448,  29534,  35084,
    41092,  47554,  54462,  61809,  69589,  77794,  86415,  95445,  104873,
    114692, 124891, 135460, 146389, 157667, 169282, 181224, 193480, 206039,
    218888, 232015, 245406, 259048, 272928, 287032, 301346, 315856, 330548,
    345407, 360419, 375568, 390841, 406221, 421693, 437243, 452854, 468513,
    484202, 499907,
};

fn fly(bar: *ProgressData, moved: bool) void {
    var buf: [402:0]u8 = @splat(0);
    const check: c_int = bar.width - 2;
    const w: usize = @intCast(bar.width);

    buf[0] = '\r';
    @memset(buf[1 .. w + 1], ' ');
    buf[w + 1] = 0;

    const bar_pos: usize = @intCast(bar.bar + 1);
    @memcpy(buf[bar_pos .. bar_pos + 5], "-=O=-");

    const denom = @divTrunc(@as(c_int, 1000000), check);
    const offsets = [_]c_uint{ 0, 5, 10, 15 };
    for (offsets) |off| {
        const idx: usize = @intCast((bar.tick + off) % 200);
        const pos: usize = @intCast(@divTrunc(sinus[idx], denom) + 1);
        buf[pos] = '#';
    }

    _ = fputs(&buf, bar.out);
    bar.tick += 2;
    if (bar.tick >= 200)
        bar.tick -= 200;

    bar.bar += if (moved) bar.barmove else 0;
    if (bar.bar >= (bar.width - 6)) {
        bar.barmove = -1;
        bar.bar = bar.width - 6;
    } else if (bar.bar < 0) {
        bar.barmove = 1;
        bar.bar = 0;
    }
}

fn update_width(bar: *ProgressData) void {
    const cols: c_int = @intCast(get_terminal_columns());
    if (cols > MAX_BARLENGTH) {
        bar.width = MAX_BARLENGTH;
    } else if (cols > MIN_BARLENGTH) {
        bar.width = cols;
    } else {
        bar.width = MIN_BARLENGTH;
    }
}

export fn tool_progress_cb(
    clientp: ?*per_transfer,
    dltotal: curl_off_t,
    dlnow: curl_off_t,
    ultotal: curl_off_t,
    ulnow: curl_off_t,
) callconv(.c) c_int {
    var now: curltime = .{};
    curlx_pnow(&now);
    const per = clientp orelse return 0;
    const config = tool_zig_per_config(per).?;
    const bar = tool_zig_per_progressbar(per);

    const totalall: curl_off_t = if ((CURL_OFF_T_MAX - dltotal) < ultotal)
        CURL_OFF_T_MAX
    else
        dltotal + ultotal;

    const nowall: curl_off_t = if ((CURL_OFF_T_MAX - dlnow) < ulnow)
        CURL_OFF_T_MAX
    else
        dlnow + ulnow;

    if (bar.calls == 0)
        update_width(bar);

    var total: curl_off_t = if (bar.initial_size < 0)
        (if (dltotal != 0 or ultotal != 0) totalall else CURL_OFF_T_MAX)
    else if ((CURL_OFF_T_MAX - bar.initial_size) < totalall)
        CURL_OFF_T_MAX
    else
        totalall + bar.initial_size;

    const point: curl_off_t = if (bar.initial_size < 0)
        (if (dltotal != 0 or ultotal != 0) nowall else CURL_OFF_T_MAX)
    else if ((CURL_OFF_T_MAX - bar.initial_size) < nowall)
        CURL_OFF_T_MAX
    else
        nowall + bar.initial_size;

    if (bar.calls != 0) {
        if (total != 0) {
            if (bar.prev == point)
                return 0;
            if (curlx_ptimediff_ms(&now, &bar.prevtime) < 100 and point < total)
                return 0;
        } else {
            if (curlx_ptimediff_ms(&now, &bar.prevtime) < 100)
                return 0;
            update_width(bar);
            fly(bar, point != bar.prev);
        }
    }

    bar.calls += 1;

    update_width(bar);
    if (total > 0 and point != bar.prev) {
        var line: [401:0]u8 = @splat(0);
        var format: [40:0]u8 = @splat(0);
        if (point > total)
            total = point;

        const frac: f64 = @as(f64, @floatFromInt(point)) / @as(f64, @floatFromInt(total));
        const percent: f64 = frac * 100.0;
        const barwidth: c_int = bar.width - 7;
        var num: usize = @intFromFloat(@as(f64, @floatFromInt(barwidth)) * frac);
        if (num > @as(usize, @intCast(MAX_BARLENGTH)))
            num = @intCast(MAX_BARLENGTH);
        @memset(line[0..num], '#');
        line[num] = 0;
        _ = curl_msnprintf(&format, format.len + 1, "\r%%-%ds %%5.1f%%%%", barwidth);
        const fmt_cstr: [*:0]const u8 = &format;
        const line_cstr: [*:0]const u8 = &line;
        _ = curl_mfprintf(bar.out, fmt_cstr, line_cstr, percent);
    }
    _ = fflush(bar.out);
    bar.prev = point;
    bar.prevtime = now;

    if (tool_zig_config_readbusy(config)) {
        tool_zig_config_set_readbusy(config, false);
        _ = curl_easy_pause(tool_zig_per_curl(per), CURLPAUSE_CONT);
    }

    return 0;
}

export fn progressbarinit(bar: *ProgressData, config: ?*OperationConfig) callconv(.c) void {
    bar.* = .{};
    if (config) |cfg| {
        if (tool_zig_config_use_resume(cfg))
            bar.initial_size = tool_zig_config_resume_from(cfg);
    }
    bar.out = tool_stderr;
    bar.tick = 150;
    bar.barmove = 1;
}

// ============================================================================
// 7. src/tool_cb_rea.c
// ============================================================================

export fn tool_read_cb(buffer: [*]u8, sz: usize, nmemb: usize, userdata: ?*per_transfer) callconv(.c) usize {
    const per = userdata orelse return 0;
    const config = tool_zig_per_config(per) orelse return 0;

    const uploadfilesize = tool_zig_per_uploadfilesize(per);
    const uploadedsofar = tool_zig_per_uploadedsofar(per);
    if (uploadfilesize != -1 and uploadedsofar == uploadfilesize) {
        return 0;
    }

    const timeout_ms = tool_zig_config_timeout_ms(config);
    if (timeout_ms != 0) {
        var now: curltime = .{};
        curlx_pnow(&now);
        const msdelta = curlx_ptimediff_ms(&now, tool_zig_per_start_ptr(per));
        if (msdelta > timeout_ms) {
            return 0;
        }
        if (builtin.os.tag != .windows) {
            var w = timeout_ms - msdelta;
            if (w > std.math.maxInt(c_int))
                w = std.math.maxInt(c_int);
            tool_zig_waitfd(@intCast(w), tool_zig_per_infd(per));
        }
    }

    var is_eagain = false;
    var rc = tool_zig_read_fd(per, buffer, sz * nmemb, &is_eagain);
    if (rc < 0) {
        if (is_eagain) {
            tool_zig_config_set_readbusy(config, true);
            return CURL_READFUNC_PAUSE;
        }
        rc = 0;
    }

    if (uploadfilesize != -1 and uploadedsofar + rc > uploadfilesize) {
        const delta: curl_off_t = uploadedsofar + rc - uploadfilesize;
        if (curl_maprintf("File size larger in the end than when started. Dropping at least %lld bytes", delta)) |msg| {
            defer curl_free(msg);
            warnf_str(msg);
        }
        rc = @intCast(uploadfilesize - uploadedsofar);
    }
    tool_zig_config_set_readbusy(config, false);

    return @intCast(rc);
}

export fn tool_readbusy_cb(
    clientp: ?*per_transfer,
    dltotal: curl_off_t,
    dlnow: curl_off_t,
    ultotal: curl_off_t,
    ulnow: curl_off_t,
) callconv(.c) c_int {
    _ = dltotal;
    _ = dlnow;
    _ = ultotal;
    const per = clientp orelse return 0;
    const config = tool_zig_per_config(per) orelse return 0;
    const ReadBusyState = struct {
        var ulprev: curl_off_t = 0;
    };

    if (tool_zig_config_readbusy(config)) {
        if (ReadBusyState.ulprev == ulnow) {
            if (builtin.os.tag != .windows) {
                tool_zig_waitfd(1, tool_zig_per_infd(per));
            } else {
                _ = curlx_wait_ms(1);
            }
        }
        tool_zig_config_set_readbusy(config, false);
        _ = curl_easy_pause(tool_zig_per_curl(per), CURLPAUSE_CONT);
    }

    ReadBusyState.ulprev = ulnow;
    return if (tool_zig_per_noprogress(per)) 0 else CURL_PROGRESSFUNC_CONTINUE;
}

// ============================================================================
// 8. src/tool_cb_see.c
// ============================================================================

export fn tool_seek_cb(userdata: ?*per_transfer, offset: curl_off_t, whence: c_int) callconv(.c) c_int {
    const per = userdata orelse return CURL_SEEKFUNC_FAIL;
    return tool_zig_seek_fd(tool_zig_per_infd(per), offset, whence);
}

export fn tool_ftruncate64(fd: c_int, where: curl_off_t) callconv(.c) c_int {
    return tool_zig_ftruncate64(fd, where);
}

// ============================================================================
// 9. src/tool_cb_soc.c
// ============================================================================

const IPPROTO_TCP: c_int = 6;
const IPPROTO_MPTCP: c_int = 262;
const CURL_SOCKET_BAD: curl_socket_t = if (builtin.os.tag == .windows) ~@as(curl_socket_t, 0) else -1;

export fn tool_socket_open_mptcp_cb(
    clientp: ?*OperationConfig,
    purpose: c_uint,
    addr: *curl_sockaddr,
) callconv(.c) curl_socket_t {
    _ = clientp;
    _ = purpose;
    var protocol = addr.protocol;
    if (protocol == IPPROTO_TCP) {
        if (builtin.os.tag == .linux) {
            protocol = IPPROTO_MPTCP;
        } else {
            return CURL_SOCKET_BAD;
        }
    }
    return tool_zig_open_socket(addr.family, addr.socktype, protocol);
}

export fn tool_sockopt_cb(
    clientp: ?*OperationConfig,
    curlfd: curl_socket_t,
    purpose: c_uint,
) callconv(.c) c_int {
    _ = clientp;
    _ = curlfd;
    _ = purpose;
    return 0;
}

// ============================================================================
// 10. src/tool_cb_wrt.c
// ============================================================================

const MAX_CLOBBER_ATTEMPTS: c_int = 9999;

fn clobber_name(fbuf: *dynbuf, fname: [*:0]const u8, next_num: c_int) bool {
    var slash = findLastCharConst(fname, '/');
    var base: [*:0]const u8 = fname;
    if (builtin.os.tag == .windows) {
        const bslash = findLastCharConst(fname, '\\');
        if (bslash) |bs| {
            if (slash == null or @intFromPtr(bs) > @intFromPtr(slash.?)) {
                slash = bs;
            }
        }
    }
    if (slash) |s| {
        base = s + 1;
    }

    const dot = findLastCharConst(base, '.');
    curlx_dyn_reset(fbuf);
    if (dot) |d| {
        if (d != base and d[1] != 0) {
            const prefix: c_int = @intCast(@intFromPtr(d) - @intFromPtr(fname));
            if (curlx_dyn_addf(fbuf, "%.*s-%d.%s", prefix, fname, next_num, d + 1) != 0)
                return false;
            return true;
        }
    }
    if (curlx_dyn_addf(fbuf, "%s.%d", fname, next_num) != 0)
        return false;
    return true;
}

export fn tool_create_output_file(outs: *OutStruct, config_opt: ?*OperationConfig) callconv(.c) bool {
    const config = config_opt orelse return false;
    const fname = tool_zig_outs_filename(outs) orelse return false;
    var file: ?*FILE = null;

    const clobber_mode = tool_zig_config_file_clobber_mode(config);
    if (clobber_mode == CLOBBER_ALWAYS or
        (clobber_mode == CLOBBER_DEFAULT and !tool_zig_outs_is_cd_filename(outs)))
    {
        file = tool_zig_fopen(fname, "wb");
    } else {
        var is_exist_or_isdir = false;
        var fd = tool_zig_open_excl(fname, &is_exist_or_isdir);
        if (clobber_mode == CLOBBER_NEVER and fd == -1) {
            var next_num: c_int = 1;
            var fbuffer: dynbuf = .{};
            curlx_dyn_init(&fbuffer, 1025);
            while (fd == -1 and is_exist_or_isdir and next_num < MAX_CLOBBER_ATTEMPTS) {
                if (!clobber_name(&fbuffer, fname, next_num)) {
                    curlx_dyn_free(&fbuffer);
                    return false;
                }
                next_num += 1;
                if (curlx_dyn_ptr(&fbuffer)) |cand| {
                    fd = tool_zig_open_excl(cand, &is_exist_or_isdir);
                } else {
                    break;
                }
            }
            if (curlx_dyn_ptr(&fbuffer)) |newfile| {
                tool_zig_outs_set_filename(outs, newfile);
                tool_zig_outs_set_alloc_filename(outs, true);
            }
        }
        if (fd != -1) {
            file = tool_zig_fdopen_wb(fd);
        }
    }

    if (file == null) {
        var errbuf: [STRERROR_LEN:0]u8 = @splat(0);
        const errstr = tool_zig_strerror_errno(&errbuf, errbuf.len);
        if (curl_maprintf("Failed to open the file %s: %s", fname, errstr)) |msg| {
            defer curl_free(msg);
            warnf_str(msg);
        }
        return false;
    }

    tool_zig_outs_set_regular_file(outs, true);
    tool_zig_outs_set_fopened(outs, true);
    tool_zig_outs_set_stream(outs, file);
    tool_zig_outs_set_bytes(outs, 0);
    tool_zig_outs_set_init(outs, 0);
    return true;
}

export fn tool_write_cb(buffer: [*]u8, sz: usize, nmemb: usize, userdata: ?*per_transfer) callconv(.c) usize {
    const per = userdata orelse return CURL_WRITEFUNC_ERROR;
    const outs = tool_zig_per_outs(per);
    const config = tool_zig_per_config(per) orelse return CURL_WRITEFUNC_ERROR;
    const bytes = sz * nmemb;
    const is_tty = tool_zig_global_isatty(tool_zig_get_global());

    if (tool_zig_outs_out_null(outs))
        return bytes;

    if (tool_zig_outs_stream(outs) == null and !tool_create_output_file(outs, config))
        return CURL_WRITEFUNC_ERROR;

    if (is_tty and tool_zig_outs_bytes(outs) < 2000 and !tool_zig_config_terminal_binary_ok(config)) {
        if (std.mem.indexOfScalar(u8, buffer[0..bytes], 0) != null) {
            warnf_str("Binary output can mess up your terminal. " ++
                "Use \"--output -\" to tell curl to output it to your terminal " ++
                "anyway, or consider \"--output <FILE>\" to save to a file.");
            return CURL_WRITEFUNC_ERROR;
        }
    }

    const stream = tool_zig_outs_stream(outs);
    var rc: usize = 0;
    const win_res = tool_zig_win_console_write(stream, outs, buffer, bytes, &rc);
    if (win_res < 0) {
        return CURL_WRITEFUNC_ERROR;
    } else if (win_res == 0) {
        const hdrcbdata = tool_zig_per_hdrcbdata(per);
        if (tool_zig_hdrcb_headlist(hdrcbdata) != null and
            tool_write_headers(hdrcbdata, stream) != 0)
        {
            return CURL_WRITEFUNC_ERROR;
        }
        rc = fwrite(buffer, sz, nmemb, stream);
    }

    if (bytes == rc) {
        tool_zig_outs_set_bytes(outs, tool_zig_outs_bytes(outs) + @as(curl_off_t, @intCast(bytes)));
    }

    if (tool_zig_config_readbusy(config)) {
        tool_zig_config_set_readbusy(config, false);
        _ = curl_easy_pause(tool_zig_per_curl(per), CURLPAUSE_CONT);
    }

    if (tool_zig_config_nobuffer(config)) {
        if (!tool_zig_fflush_retry(stream))
            return CURL_WRITEFUNC_ERROR;
    }

    return rc;
}

// ============================================================================
// 11. src/tool_progress.c
// ============================================================================

export fn max5data(bytes_in: curl_off_t, max5: [*]u8, mlen: usize) callconv(.c) [*]u8 {
    const unit = [_]u8{ 'k', 'M', 'G', 'T', 'P', 'E', 0 };
    var bytes = bytes_in;
    var k: usize = 0;
    if (bytes < 100000) {
        _ = curl_msnprintf(max5, mlen, "%5lld", bytes);
        return max5;
    }

    while (unit[k] != 0) {
        const nbytes = @divTrunc(bytes, 1024);
        if (nbytes < 100) {
            _ = curl_msnprintf(
                max5,
                mlen,
                "%2lld.%lld%c",
                @divTrunc(bytes, 1024),
                @divTrunc(@rem(bytes, 1024) * 10, 1024),
                @as(c_int, unit[k]),
            );
            break;
        } else if (nbytes < 10000) {
            _ = curl_msnprintf(max5, mlen, "%4lld%c", nbytes, @as(c_int, unit[k]));
            break;
        }
        bytes = nbytes;
        k += 1;
    }
    return max5;
}

export fn xferinfo_cb(
    clientp: ?*per_transfer,
    dltotal: curl_off_t,
    dlnow: curl_off_t,
    ultotal: curl_off_t,
    ulnow: curl_off_t,
) callconv(.c) c_int {
    const per = clientp orelse return 0;
    const config = tool_zig_per_config(per).?;
    tool_zig_per_set_dltotal(per, dltotal);
    tool_zig_per_set_dlnow(per, dlnow);
    tool_zig_per_set_ultotal(per, ultotal);
    tool_zig_per_set_ulnow(per, ulnow);

    if (tool_zig_per_abort(per))
        return 1;

    if (tool_zig_config_readbusy(config)) {
        tool_zig_config_set_readbusy(config, false);
        _ = curl_easy_pause(tool_zig_per_curl(per), CURLPAUSE_CONT);
    }

    return 0;
}

export fn timebuf(r: [*]u8, rlen: usize, seconds: curl_off_t) callconv(.c) void {
    if (seconds <= 0) {
        curlx_strcopy(r, rlen, "        ", 8);
        return;
    }
    var h = @divTrunc(seconds, 3600);
    if (h <= 99) {
        const m = @divTrunc(seconds - (h * 3600), 60);
        const s = (seconds - (h * 3600)) - (m * 60);
        _ = curl_msnprintf(r, rlen, "%02lld:%02lld:%02lld", h, m, s);
    } else {
        const d = @divTrunc(seconds, 86400);
        h = @divTrunc(seconds - (d * 86400), 3600);
        if (d <= 999) {
            _ = curl_msnprintf(r, rlen, "%3lldd %02lldh", d, h);
        } else {
            const m = @divTrunc(d, 30);
            if (m <= 999) {
                _ = curl_msnprintf(r, rlen, "%3lldm %02lldd", m, @rem(d, 30));
            } else {
                const y = @divTrunc(d, 365);
                if (y <= 99999) {
                    _ = curl_msnprintf(r, rlen, "%7lldy", y);
                } else {
                    curlx_strcopy(r, rlen, " >99999y", 8);
                }
            }
        }
    }
}

const SPEEDCNT: usize = 10;
const speedcount = struct {
    dl: curl_off_t = 0,
    ul: curl_off_t = 0,
    stamp: curltime = .{},
};

var all_dltotal: curl_off_t = 0;
var all_ultotal: curl_off_t = 0;
var all_dlalready: curl_off_t = 0;
var all_ulalready: curl_off_t = 0;
var speedindex: usize = 0;
var indexwrapped: bool = false;
var speedstore: [SPEEDCNT]speedcount = @splat(.{});

fn add_offt(val: *curl_off_t, add: curl_off_t) void {
    if (CURL_OFF_T_MAX - val.* < add) {
        val.* = CURL_OFF_T_MAX;
    } else {
        val.* += add;
    }
}

export fn progress_meter(multi: ?*CURLM, start: *const curltime, final: bool) callconv(.c) bool {
    const MeterState = struct {
        var stamp: curltime = .{};
        var header: bool = false;
    };

    const g = tool_zig_get_global();
    if (tool_zig_global_noprogress(g) or tool_zig_global_silent(g))
        return false;

    var now: curltime = .{};
    curlx_pnow(&now);
    const diff = curlx_ptimediff_ms(&now, &MeterState.stamp);

    if (!MeterState.header) {
        MeterState.header = true;
        _ = fputs("DL% UL%  Dled  Uled  Xfers  Live Total     Current  Left    Speed\n", tool_stderr);
    }

    if (final or diff > 500) {
        var time_left: [9:0]u8 = @splat(0);
        var time_total: [9:0]u8 = @splat(0);
        var time_spent: [9:0]u8 = @splat(0);
        var buffer: [3][6:0]u8 = @splat(@splat(0));
        const spent: curl_off_t = @divTrunc(curlx_ptimediff_ms(&now, start), 1000);
        var dlpercen: [3:0]u8 = .{ '-', '-', 0 };
        var ulpercen: [3:0]u8 = .{ '-', '-', 0 };
        var all_dlnow: curl_off_t = 0;
        var all_ulnow: curl_off_t = 0;
        var xfers_added: curl_off_t = 0;
        var xfers_running: curl_off_t = 0;
        var dlknown = true;
        var ulknown = true;
        var speed: curl_off_t = 0;
        MeterState.stamp = now;

        add_offt(&all_dlnow, all_dlalready);
        add_offt(&all_ulnow, all_ulalready);

        var per_opt = tool_zig_get_transfers();
        while (per_opt) |per| : (per_opt = tool_zig_per_next(per)) {
            add_offt(&all_dlnow, tool_zig_per_dlnow(per));
            add_offt(&all_ulnow, tool_zig_per_ulnow(per));
            const pdltotal = tool_zig_per_dltotal(per);
            if (pdltotal == 0) {
                dlknown = false;
            } else if (!tool_zig_per_dltotal_added(per)) {
                add_offt(&all_dltotal, pdltotal);
                tool_zig_per_set_dltotal_added(per, true);
            }
            const pultotal = tool_zig_per_ultotal(per);
            if (pultotal == 0) {
                ulknown = false;
            } else if (!tool_zig_per_ultotal_added(per)) {
                add_offt(&all_ultotal, pultotal);
                tool_zig_per_set_ultotal_added(per, true);
            }
        }

        if (dlknown and all_dltotal != 0) {
            const pct = if (all_dlnow < @divTrunc(CURL_OFF_T_MAX, 100))
                @divTrunc(all_dlnow * 100, all_dltotal)
            else
                @divTrunc(all_dlnow, @divTrunc(all_dltotal, 100));
            _ = curl_msnprintf(&dlpercen, dlpercen.len + 1, "%3lld", pct);
        }

        if (ulknown and all_ultotal != 0) {
            const pct = if (all_ulnow < @divTrunc(CURL_OFF_T_MAX, 100))
                @divTrunc(all_ulnow * 100, all_ultotal)
            else
                @divTrunc(all_ulnow, @divTrunc(all_ultotal, 100));
            _ = curl_msnprintf(&ulpercen, ulpercen.len + 1, "%3lld", pct);
        }

        const idx = speedindex;
        speedstore[idx].dl = all_dlnow;
        speedstore[idx].ul = all_ulnow;
        speedstore[idx].stamp = now;
        speedindex += 1;
        if (speedindex >= SPEEDCNT) {
            indexwrapped = true;
            speedindex = 0;
        }

        {
            var deltams: timediff_t = 0;
            var dl: curl_off_t = 0;
            var ul: curl_off_t = 0;
            if (indexwrapped) {
                deltams = curlx_ptimediff_ms(&now, &speedstore[speedindex].stamp);
                dl = all_dlnow - speedstore[speedindex].dl;
                ul = all_ulnow - speedstore[speedindex].ul;
            } else {
                deltams = curlx_ptimediff_ms(&now, start);
                dl = all_dlnow;
                ul = all_ulnow;
            }
            if (deltams == 0)
                deltams += 1;
            const secs_f: f64 = @as(f64, @floatFromInt(deltams)) / 1000.0;
            const dls: curl_off_t = @intFromFloat(@as(f64, @floatFromInt(dl)) / secs_f);
            const uls: curl_off_t = @intFromFloat(@as(f64, @floatFromInt(ul)) / secs_f);
            speed = if (dls > uls) dls else uls;
        }

        if (dlknown and speed != 0) {
            const est = @divTrunc(all_dltotal, speed);
            const left = @divTrunc(all_dltotal - all_dlnow, speed);
            timebuf(&time_left, time_left.len + 1, left);
            timebuf(&time_total, time_total.len + 1, est);
        } else {
            timebuf(&time_left, time_left.len + 1, 0);
            timebuf(&time_total, time_total.len + 1, 0);
        }
        timebuf(&time_spent, time_spent.len + 1, spent);

        _ = curl_multi_get_offt(multi, CURLMINFO_XFERS_ADDED, &xfers_added);
        _ = curl_multi_get_offt(multi, CURLMINFO_XFERS_RUNNING, &xfers_running);

        const dlp_cstr: [*:0]const u8 = &dlpercen;
        const ulp_cstr: [*:0]const u8 = &ulpercen;
        const b0_cstr = max5data(all_dlnow, &buffer[0], buffer[0].len + 1);
        const b1_cstr = max5data(all_ulnow, &buffer[1], buffer[1].len + 1);
        const b2_cstr = max5data(speed, &buffer[2], buffer[2].len + 1);
        const ttot_cstr: [*:0]const u8 = &time_total;
        const tsp_cstr: [*:0]const u8 = &time_spent;
        const tleft_cstr: [*:0]const u8 = &time_left;
        const fin_cstr: [*:0]const u8 = if (final) "\n" else "";

        _ = curl_mfprintf(
            tool_stderr,
            "\r%-3s %-3s %s %s %5lld %5lld  %s %s %s %s %5s",
            dlp_cstr,
            ulp_cstr,
            b0_cstr,
            b1_cstr,
            xfers_added,
            xfers_running,
            ttot_cstr,
            tsp_cstr,
            tleft_cstr,
            b2_cstr,
            fin_cstr,
        );
        return true;
    }
    return false;
}

export fn progress_finalize(per: *per_transfer) callconv(.c) void {
    add_offt(&all_dlalready, tool_zig_per_dlnow(per));
    add_offt(&all_ulalready, tool_zig_per_ulnow(per));
    if (!tool_zig_per_dltotal_added(per)) {
        add_offt(&all_dltotal, tool_zig_per_dltotal(per));
        tool_zig_per_set_dltotal_added(per, true);
    }
    if (!tool_zig_per_ultotal_added(per)) {
        add_offt(&all_ultotal, tool_zig_per_ultotal(per));
        tool_zig_per_set_ultotal_added(per, true);
    }
}

// ============================================================================
// 12. src/tool_writeout_json.c
// ============================================================================

const MAX_JSON_STRING: usize = 100000;

export fn jsonquoted(in_opt: ?[*]const u8, len: usize, out: *dynbuf, lowercase: bool) callconv(.c) c_int {
    const in = in_opt orelse return 0;
    var result: c_uint = 0;
    var idx: usize = 0;
    while (idx < len and result == 0) : (idx += 1) {
        const ch = in[idx];
        switch (ch) {
            '\\' => result = curlx_dyn_addn(out, "\\\\", 2),
            '"' => result = curlx_dyn_addn(out, "\\\"", 2),
            0x08 => result = curlx_dyn_addn(out, "\\b", 2),
            0x0c => result = curlx_dyn_addn(out, "\\f", 2),
            '\n' => result = curlx_dyn_addn(out, "\\n", 2),
            '\r' => result = curlx_dyn_addn(out, "\\r", 2),
            '\t' => result = curlx_dyn_addn(out, "\\t", 2),
            else => {
                if (ch < 32) {
                    result = curlx_dyn_addf(out, "\\u%04x", @as(c_uint, ch));
                } else {
                    var o = ch;
                    if (lowercase and (o >= 'A' and o <= 'Z')) {
                        o |= ('a' - 'A');
                    }
                    const one = [1]u8{o};
                    result = curlx_dyn_addn(out, &one, 1);
                }
            },
        }
    }
    return @intCast(result);
}

export fn jsonWriteString(stream: ?*FILE, in: [*:0]const u8, lowercase: bool) callconv(.c) void {
    var out: dynbuf = .{};
    curlx_dyn_init(&out, MAX_JSON_STRING);
    defer curlx_dyn_free(&out);

    if (jsonquoted(in, std.mem.len(in), &out, lowercase) == 0) {
        _ = fputc('"', stream);
        if (curlx_dyn_len(&out) != 0) {
            if (curlx_dyn_ptr(&out)) |ptr| {
                _ = fputs(ptr, stream);
            }
        }
        _ = fputc('"', stream);
    }
}

export fn ourWriteOutJSON(
    stream: ?*FILE,
    mappings: [*]const writeoutvar,
    nentries: usize,
    per: *per_transfer,
    per_result: c_uint,
) callconv(.c) void {
    _ = fputs("{", stream);
    var i: usize = 0;
    while (i < nentries) : (i += 1) {
        if (mappings[i].writefunc) |wf| {
            if (wf(stream, &mappings[i], per, per_result, true) != 0) {
                _ = fputs(",", stream);
            }
        }
    }
    _ = curl_mfprintf(stream, "\"curl_version\":");
    jsonWriteString(stream, curl_version(), false);
    _ = curl_mfprintf(stream, "}");
}

export fn headerJSON(stream: ?*FILE, per: *per_transfer) callconv(.c) void {
    var prev: ?*curl_header = null;
    const curl = tool_zig_per_curl(per);

    _ = fputc('{', stream);
    while (curl_easy_nextheader(curl, CURLH_HEADER, -1, prev)) |hdr_init| {
        var header: *curl_header = hdr_init;
        if (header.amount > 1) {
            if (header.index == 0) {
                const a = header.amount;
                var i: usize = 0;
                const name = header.name;
                if (prev != null)
                    _ = fputs(",\n", stream);
                jsonWriteString(stream, header.name, true);
                _ = fputc(':', stream);
                prev = header;
                _ = fputc('[', stream);
                while (true) {
                    jsonWriteString(stream, header.value, false);
                    i += 1;
                    if (i >= a)
                        break;
                    _ = fputc(',', stream);
                    var next_hdr: ?*curl_header = null;
                    if (curl_easy_header(curl, name, i, CURLH_HEADER, -1, &next_hdr) != 0 or next_hdr == null)
                        break;
                    header = next_hdr.?;
                }
                _ = fputc(']', stream);
            }
        } else {
            if (prev != null)
                _ = fputs(",\n", stream);
            jsonWriteString(stream, header.name, true);
            _ = fputc(':', stream);
            _ = fputc('[', stream);
            jsonWriteString(stream, header.value, false);
            _ = fputc(']', stream);
            prev = header;
        }
    }
    _ = fputs("\n}", stream);
}

// ============================================================================
// 13. src/tool_writeout.c
// ============================================================================

const httpmap = struct {
    str: [*:0]const u8,
    num: c_long,
};

const http_version = [_]httpmap{
    .{ .str = "0", .num = CURL_HTTP_VERSION_NONE },
    .{ .str = "1", .num = CURL_HTTP_VERSION_1_0 },
    .{ .str = "1.1", .num = CURL_HTTP_VERSION_1_1 },
    .{ .str = "2", .num = CURL_HTTP_VERSION_2 },
    .{ .str = "3", .num = CURL_HTTP_VERSION_3 },
};

fn writeTime(
    stream: ?*FILE,
    wovar: *const writeoutvar,
    per: *per_transfer,
    per_result: c_uint,
    use_json: bool,
) callconv(.c) c_int {
    _ = per_result;
    var valid = false;
    var us: curl_off_t = 0;

    if (wovar.ci != 0) {
        if (curl_easy_getinfo(tool_zig_per_curl(per), wovar.ci, &us) == 0)
            valid = true;
    }

    if (valid) {
        const secs = @divTrunc(us, 1000000);
        us = @rem(us, 1000000);
        if (use_json)
            _ = curl_mfprintf(stream, "\"%s\":", wovar.name);
        _ = curl_mfprintf(stream, "%lld.%06lld", secs, us);
    } else {
        if (use_json)
            _ = curl_mfprintf(stream, "\"%s\":null", wovar.name);
    }
    return 1;
}

fn urlpart(per: *per_transfer, vid: c_uint, contentp: *?[*:0]const u8) c_int {
    const uh = curl_url() orelse return 1;
    defer curl_url_cleanup(uh);

    var rc: c_int = 0;
    var cpart: c_uint = CURLUPART_HOST;
    var part: ?[*:0]u8 = null;
    var url: ?[*:0]const u8 = null;

    if (vid >= VAR_INPUT_URLESCHEME) {
        if (curl_easy_getinfo(tool_zig_per_curl(per), CURLINFO_EFFECTIVE_URL, &url) != 0)
            rc = 5;
    } else {
        url = tool_zig_per_url(per);
    }

    if (rc == 0) {
        switch (vid) {
            VAR_INPUT_URLSCHEME, VAR_INPUT_URLESCHEME => cpart = CURLUPART_SCHEME,
            VAR_INPUT_URLUSER, VAR_INPUT_URLEUSER => cpart = CURLUPART_USER,
            VAR_INPUT_URLPASSWORD, VAR_INPUT_URLEPASSWORD => cpart = CURLUPART_PASSWORD,
            VAR_INPUT_URLOPTIONS, VAR_INPUT_URLEOPTIONS => cpart = CURLUPART_OPTIONS,
            VAR_INPUT_URLHOST, VAR_INPUT_URLEHOST => cpart = CURLUPART_HOST,
            VAR_INPUT_URLPORT, VAR_INPUT_URLEPORT => cpart = CURLUPART_PORT,
            VAR_INPUT_URLPATH, VAR_INPUT_URLEPATH => cpart = CURLUPART_PATH,
            VAR_INPUT_URLQUERY, VAR_INPUT_URLEQUERY => cpart = CURLUPART_QUERY,
            VAR_INPUT_URLFRAGMENT, VAR_INPUT_URLEFRAGMENT => cpart = CURLUPART_FRAGMENT,
            VAR_INPUT_URLZONEID, VAR_INPUT_URLEZONEID => cpart = CURLUPART_ZONEID,
            else => rc = 4,
        }
    }
    if (rc == 0 and curl_url_set(uh, CURLUPART_URL, url, CURLU_GUESS_SCHEME | CURLU_NON_SUPPORT_SCHEME) != 0)
        rc = 2;
    if (rc == 0 and curl_url_get(uh, cpart, &part, CURLU_DEFAULT_PORT) != 0)
        rc = 3;
    if (rc == 0 and part != null)
        contentp.* = part;
    return rc;
}

fn certinfo(per: *per_transfer) void {
    if (tool_zig_per_certinfo(per) == null) {
        var ci: ?*const curl_certinfo = null;
        const result = curl_easy_getinfo(tool_zig_per_curl(per), CURLINFO_CERTINFO, &ci);
        tool_zig_per_set_certinfo(per, if (result == 0) ci else null);
    }
}

fn writeString(
    stream: ?*FILE,
    wovar: *const writeoutvar,
    per: *per_transfer,
    per_result: c_uint,
    use_json: bool,
) callconv(.c) c_int {
    var valid = false;
    var strinfo: ?[*:0]const u8 = null;
    var freestr: ?[*:0]const u8 = null;
    var buf: dynbuf = .{};
    curlx_dyn_init(&buf, 256 * 1024);
    defer {
        curl_free(@constCast(freestr));
        curlx_dyn_free(&buf);
    }

    if (wovar.ci != 0) {
        if (wovar.ci == CURLINFO_HTTP_VERSION) {
            var version: c_long = 0;
            if (curl_easy_getinfo(tool_zig_per_curl(per), CURLINFO_HTTP_VERSION, &version) == 0) {
                for (http_version) |m| {
                    if (m.num == version) {
                        strinfo = m.str;
                        valid = true;
                        break;
                    }
                }
            }
        } else {
            if (curl_easy_getinfo(tool_zig_per_curl(per), wovar.ci, &strinfo) == 0 and strinfo != null)
                valid = true;
        }
    } else {
        switch (wovar.id) {
            VAR_CERT => {
                certinfo(per);
                if (tool_zig_per_certinfo(per)) |ci| {
                    var err = false;
                    var i: usize = 0;
                    const ncerts: usize = if (ci.num_of_certs > 0) @intCast(ci.num_of_certs) else 0;
                    while (i < ncerts and !err) : (i += 1) {
                        var slist: ?*curl_slist = if (ci.certinfo) |arr| arr[i] else null;
                        while (slist) |node| : (slist = node.next) {
                            if (node.data) |d| {
                                if (curl_strnequal(d, "cert:", 5) != 0) {
                                    if (curlx_dyn_add(&buf, d + 5) != 0) {
                                        err = true;
                                        break;
                                    }
                                } else {
                                    if (curlx_dyn_add(&buf, d) != 0) {
                                        err = true;
                                        break;
                                    }
                                }
                                const len = curlx_dyn_len(&buf);
                                if (len != 0) {
                                    if (curlx_dyn_ptr(&buf)) |ptr| {
                                        if (ptr[len - 1] != '\n' and curlx_dyn_addn(&buf, "\n", 1) != 0) {
                                            err = true;
                                            break;
                                        }
                                    }
                                }
                            }
                        }
                    }
                    if (!err) {
                        strinfo = curlx_dyn_ptr(&buf) orelse "";
                        valid = true;
                    }
                } else {
                    strinfo = "";
                }
            },
            VAR_ERRORMSG => {
                if (per_result != 0) {
                    const eb = tool_zig_per_errorbuffer(per);
                    strinfo = if (eb[0] != 0) eb else curl_easy_strerror(per_result);
                    valid = true;
                }
            },
            VAR_EFFECTIVE_FILENAME => {
                if (tool_zig_outs_filename(tool_zig_per_outs(per))) |fn_ptr| {
                    strinfo = fn_ptr;
                    valid = true;
                }
            },
            VAR_INPUT_URL => {
                if (tool_zig_per_url(per)) |u| {
                    strinfo = u;
                    valid = true;
                }
            },
            VAR_INPUT_URLSCHEME,
            VAR_INPUT_URLUSER,
            VAR_INPUT_URLPASSWORD,
            VAR_INPUT_URLOPTIONS,
            VAR_INPUT_URLHOST,
            VAR_INPUT_URLPORT,
            VAR_INPUT_URLPATH,
            VAR_INPUT_URLQUERY,
            VAR_INPUT_URLFRAGMENT,
            VAR_INPUT_URLZONEID,
            VAR_INPUT_URLESCHEME,
            VAR_INPUT_URLEUSER,
            VAR_INPUT_URLEPASSWORD,
            VAR_INPUT_URLEOPTIONS,
            VAR_INPUT_URLEHOST,
            VAR_INPUT_URLEPORT,
            VAR_INPUT_URLEPATH,
            VAR_INPUT_URLEQUERY,
            VAR_INPUT_URLEFRAGMENT,
            VAR_INPUT_URLEZONEID,
            => {
                if (tool_zig_per_url(per) != null and urlpart(per, wovar.id, &strinfo) == 0) {
                    freestr = strinfo;
                    valid = true;
                }
            },
            else => {},
        }
    }

    if (valid and strinfo != null) {
        if (use_json) {
            _ = curl_mfprintf(stream, "\"%s\":", wovar.name);
            jsonWriteString(stream, strinfo.?, false);
        } else {
            _ = fputs(strinfo.?, stream);
        }
    } else {
        if (use_json)
            _ = curl_mfprintf(stream, "\"%s\":null", wovar.name);
    }

    return 1;
}

fn writeLong(
    stream: ?*FILE,
    wovar: *const writeoutvar,
    per: *per_transfer,
    per_result: c_uint,
    use_json: bool,
) callconv(.c) c_int {
    var valid = false;
    var longinfo: c_long = 0;

    if (wovar.ci != 0) {
        if (curl_easy_getinfo(tool_zig_per_curl(per), wovar.ci, &longinfo) == 0)
            valid = true;
    } else {
        switch (wovar.id) {
            VAR_NUM_RETRY => {
                longinfo = tool_zig_per_num_retries(per);
                valid = true;
            },
            VAR_NUM_CERTS => {
                certinfo(per);
                longinfo = if (tool_zig_per_certinfo(per)) |ci| ci.num_of_certs else 0;
                valid = true;
            },
            VAR_NUM_HEADERS => {
                longinfo = tool_zig_per_num_headers(per);
                valid = true;
            },
            VAR_EXITCODE => {
                longinfo = @intCast(per_result);
                valid = true;
            },
            else => {},
        }
    }

    if (valid) {
        if (use_json) {
            _ = curl_mfprintf(stream, "\"%s\":%ld", wovar.name, longinfo);
        } else {
            if (wovar.id == VAR_HTTP_CODE or wovar.id == VAR_HTTP_CODE_PROXY) {
                _ = curl_mfprintf(stream, "%03ld", longinfo);
            } else {
                _ = curl_mfprintf(stream, "%ld", longinfo);
            }
        }
    } else {
        if (use_json)
            _ = curl_mfprintf(stream, "\"%s\":null", wovar.name);
    }

    return 1;
}

fn writeOffset(
    stream: ?*FILE,
    wovar: *const writeoutvar,
    per: *per_transfer,
    per_result: c_uint,
    use_json: bool,
) callconv(.c) c_int {
    _ = per_result;
    var valid = false;
    var offinfo: curl_off_t = 0;

    if (wovar.ci != 0) {
        if (curl_easy_getinfo(tool_zig_per_curl(per), wovar.ci, &offinfo) == 0)
            valid = true;
    } else {
        switch (wovar.id) {
            VAR_URLNUM => {
                const unum = tool_zig_per_urlnum(per);
                if (unum <= std.math.maxInt(c_int)) {
                    offinfo = unum;
                    valid = true;
                }
            },
            else => {},
        }
    }

    if (valid) {
        if (use_json)
            _ = curl_mfprintf(stream, "\"%s\":", wovar.name);
        _ = curl_mfprintf(stream, "%lld", offinfo);
    } else {
        if (use_json)
            _ = curl_mfprintf(stream, "\"%s\":null", wovar.name);
    }

    return 1;
}

pub const variables = [_]writeoutvar{
    .{ .name = "certs", .id = VAR_CERT, .ci = CURLINFO_NONE, .writefunc = writeString },
    .{ .name = "conn_id", .id = VAR_CONN_ID, .ci = CURLINFO_CONN_ID, .writefunc = writeOffset },
    .{ .name = "content_type", .id = VAR_CONTENT_TYPE, .ci = CURLINFO_CONTENT_TYPE, .writefunc = writeString },
    .{ .name = "errormsg", .id = VAR_ERRORMSG, .ci = CURLINFO_NONE, .writefunc = writeString },
    .{ .name = "exitcode", .id = VAR_EXITCODE, .ci = CURLINFO_NONE, .writefunc = writeLong },
    .{ .name = "filename_effective", .id = VAR_EFFECTIVE_FILENAME, .ci = CURLINFO_NONE, .writefunc = writeString },
    .{ .name = "ftp_entry_path", .id = VAR_FTP_ENTRY_PATH, .ci = CURLINFO_FTP_ENTRY_PATH, .writefunc = writeString },
    .{ .name = "header_json", .id = VAR_HEADER_JSON, .ci = CURLINFO_NONE, .writefunc = null },
    .{ .name = "http_code", .id = VAR_HTTP_CODE, .ci = CURLINFO_RESPONSE_CODE, .writefunc = writeLong },
    .{ .name = "http_connect", .id = VAR_HTTP_CODE_PROXY, .ci = CURLINFO_HTTP_CONNECTCODE, .writefunc = writeLong },
    .{ .name = "http_version", .id = VAR_HTTP_VERSION, .ci = CURLINFO_HTTP_VERSION, .writefunc = writeString },
    .{ .name = "json", .id = VAR_JSON, .ci = CURLINFO_NONE, .writefunc = null },
    .{ .name = "local_ip", .id = VAR_LOCAL_IP, .ci = CURLINFO_LOCAL_IP, .writefunc = writeString },
    .{ .name = "local_port", .id = VAR_LOCAL_PORT, .ci = CURLINFO_LOCAL_PORT, .writefunc = writeLong },
    .{ .name = "method", .id = VAR_EFFECTIVE_METHOD, .ci = CURLINFO_EFFECTIVE_METHOD, .writefunc = writeString },
    .{ .name = "num_certs", .id = VAR_NUM_CERTS, .ci = CURLINFO_NONE, .writefunc = writeLong },
    .{ .name = "num_connects", .id = VAR_NUM_CONNECTS, .ci = CURLINFO_NUM_CONNECTS, .writefunc = writeLong },
    .{ .name = "num_headers", .id = VAR_NUM_HEADERS, .ci = CURLINFO_NONE, .writefunc = writeLong },
    .{ .name = "num_redirects", .id = VAR_REDIRECT_COUNT, .ci = CURLINFO_REDIRECT_COUNT, .writefunc = writeLong },
    .{ .name = "num_retries", .id = VAR_NUM_RETRY, .ci = CURLINFO_NONE, .writefunc = writeLong },
    .{ .name = "onerror", .id = VAR_ONERROR, .ci = CURLINFO_NONE, .writefunc = null },
    .{ .name = "proxy_ssl_verify_result", .id = VAR_PROXY_SSL_VERIFY_RESULT, .ci = CURLINFO_PROXY_SSL_VERIFYRESULT, .writefunc = writeLong },
    .{ .name = "proxy_used", .id = VAR_PROXY_USED, .ci = CURLINFO_USED_PROXY, .writefunc = writeLong },
    .{ .name = "redirect_url", .id = VAR_REDIRECT_URL, .ci = CURLINFO_REDIRECT_URL, .writefunc = writeString },
    .{ .name = "referer", .id = VAR_REFERER, .ci = CURLINFO_REFERER, .writefunc = writeString },
    .{ .name = "remote_ip", .id = VAR_PRIMARY_IP, .ci = CURLINFO_PRIMARY_IP, .writefunc = writeString },
    .{ .name = "remote_port", .id = VAR_PRIMARY_PORT, .ci = CURLINFO_PRIMARY_PORT, .writefunc = writeLong },
    .{ .name = "response_code", .id = VAR_HTTP_CODE, .ci = CURLINFO_RESPONSE_CODE, .writefunc = writeLong },
    .{ .name = "scheme", .id = VAR_SCHEME, .ci = CURLINFO_SCHEME, .writefunc = writeString },
    .{ .name = "size_delivered", .id = VAR_SIZE_DELIVERED, .ci = CURLINFO_SIZE_DELIVERED, .writefunc = writeOffset },
    .{ .name = "size_download", .id = VAR_SIZE_DOWNLOAD, .ci = CURLINFO_SIZE_DOWNLOAD_T, .writefunc = writeOffset },
    .{ .name = "size_header", .id = VAR_HEADER_SIZE, .ci = CURLINFO_HEADER_SIZE, .writefunc = writeLong },
    .{ .name = "size_request", .id = VAR_REQUEST_SIZE, .ci = CURLINFO_REQUEST_SIZE, .writefunc = writeLong },
    .{ .name = "size_upload", .id = VAR_SIZE_UPLOAD, .ci = CURLINFO_SIZE_UPLOAD_T, .writefunc = writeOffset },
    .{ .name = "speed_download", .id = VAR_SPEED_DOWNLOAD, .ci = CURLINFO_SPEED_DOWNLOAD_T, .writefunc = writeOffset },
    .{ .name = "speed_upload", .id = VAR_SPEED_UPLOAD, .ci = CURLINFO_SPEED_UPLOAD_T, .writefunc = writeOffset },
    .{ .name = "ssl_verify_result", .id = VAR_SSL_VERIFY_RESULT, .ci = CURLINFO_SSL_VERIFYRESULT, .writefunc = writeLong },
    .{ .name = "stderr", .id = VAR_STDERR, .ci = CURLINFO_NONE, .writefunc = null },
    .{ .name = "stdout", .id = VAR_STDOUT, .ci = CURLINFO_NONE, .writefunc = null },
    .{ .name = "time_appconnect", .id = VAR_APPCONNECT_TIME, .ci = CURLINFO_APPCONNECT_TIME_T, .writefunc = writeTime },
    .{ .name = "time_connect", .id = VAR_CONNECT_TIME, .ci = CURLINFO_CONNECT_TIME_T, .writefunc = writeTime },
    .{ .name = "time_namelookup", .id = VAR_NAMELOOKUP_TIME, .ci = CURLINFO_NAMELOOKUP_TIME_T, .writefunc = writeTime },
    .{ .name = "time_posttransfer", .id = VAR_POSTTRANSFER_TIME, .ci = CURLINFO_POSTTRANSFER_TIME_T, .writefunc = writeTime },
    .{ .name = "time_pretransfer", .id = VAR_PRETRANSFER_TIME, .ci = CURLINFO_PRETRANSFER_TIME_T, .writefunc = writeTime },
    .{ .name = "time_queue", .id = VAR_QUEUE_TIME, .ci = CURLINFO_QUEUE_TIME_T, .writefunc = writeTime },
    .{ .name = "time_redirect", .id = VAR_REDIRECT_TIME, .ci = CURLINFO_REDIRECT_TIME_T, .writefunc = writeTime },
    .{ .name = "time_starttransfer", .id = VAR_STARTTRANSFER_TIME, .ci = CURLINFO_STARTTRANSFER_TIME_T, .writefunc = writeTime },
    .{ .name = "time_total", .id = VAR_TOTAL_TIME, .ci = CURLINFO_TOTAL_TIME_T, .writefunc = writeTime },
    .{ .name = "tls_earlydata", .id = VAR_TLS_EARLYDATA_SENT, .ci = CURLINFO_EARLYDATA_SENT_T, .writefunc = writeOffset },
    .{ .name = "url", .id = VAR_INPUT_URL, .ci = CURLINFO_NONE, .writefunc = writeString },
    .{ .name = "url.fragment", .id = VAR_INPUT_URLFRAGMENT, .ci = CURLINFO_NONE, .writefunc = writeString },
    .{ .name = "url.host", .id = VAR_INPUT_URLHOST, .ci = CURLINFO_NONE, .writefunc = writeString },
    .{ .name = "url.options", .id = VAR_INPUT_URLOPTIONS, .ci = CURLINFO_NONE, .writefunc = writeString },
    .{ .name = "url.password", .id = VAR_INPUT_URLPASSWORD, .ci = CURLINFO_NONE, .writefunc = writeString },
    .{ .name = "url.path", .id = VAR_INPUT_URLPATH, .ci = CURLINFO_NONE, .writefunc = writeString },
    .{ .name = "url.port", .id = VAR_INPUT_URLPORT, .ci = CURLINFO_NONE, .writefunc = writeString },
    .{ .name = "url.query", .id = VAR_INPUT_URLQUERY, .ci = CURLINFO_NONE, .writefunc = writeString },
    .{ .name = "url.scheme", .id = VAR_INPUT_URLSCHEME, .ci = CURLINFO_NONE, .writefunc = writeString },
    .{ .name = "url.user", .id = VAR_INPUT_URLUSER, .ci = CURLINFO_NONE, .writefunc = writeString },
    .{ .name = "url.zoneid", .id = VAR_INPUT_URLZONEID, .ci = CURLINFO_NONE, .writefunc = writeString },
    .{ .name = "url_effective", .id = VAR_EFFECTIVE_URL, .ci = CURLINFO_EFFECTIVE_URL, .writefunc = writeString },
    .{ .name = "urle.fragment", .id = VAR_INPUT_URLEFRAGMENT, .ci = CURLINFO_NONE, .writefunc = writeString },
    .{ .name = "urle.host", .id = VAR_INPUT_URLEHOST, .ci = CURLINFO_NONE, .writefunc = writeString },
    .{ .name = "urle.options", .id = VAR_INPUT_URLEOPTIONS, .ci = CURLINFO_NONE, .writefunc = writeString },
    .{ .name = "urle.password", .id = VAR_INPUT_URLEPASSWORD, .ci = CURLINFO_NONE, .writefunc = writeString },
    .{ .name = "urle.path", .id = VAR_INPUT_URLEPATH, .ci = CURLINFO_NONE, .writefunc = writeString },
    .{ .name = "urle.port", .id = VAR_INPUT_URLEPORT, .ci = CURLINFO_NONE, .writefunc = writeString },
    .{ .name = "urle.query", .id = VAR_INPUT_URLEQUERY, .ci = CURLINFO_NONE, .writefunc = writeString },
    .{ .name = "urle.scheme", .id = VAR_INPUT_URLESCHEME, .ci = CURLINFO_NONE, .writefunc = writeString },
    .{ .name = "urle.user", .id = VAR_INPUT_URLEUSER, .ci = CURLINFO_NONE, .writefunc = writeString },
    .{ .name = "urle.zoneid", .id = VAR_INPUT_URLEZONEID, .ci = CURLINFO_NONE, .writefunc = writeString },
    .{ .name = "urlnum", .id = VAR_URLNUM, .ci = CURLINFO_NONE, .writefunc = writeOffset },
    .{ .name = "xfer_id", .id = VAR_EASY_ID, .ci = CURLINFO_XFER_ID, .writefunc = writeOffset },
};

const MAX_WRITEOUT_NAME_LENGTH: usize = 24;

pub fn findWriteoutVar(name: [*:0]const u8) ?*const writeoutvar {
    var low: usize = 0;
    var high: usize = variables.len;
    while (low < high) {
        const mid = low + (high - low) / 2;
        switch (std.mem.orderZ(u8, name, variables[mid].name)) {
            .eq => return &variables[mid],
            .lt => high = mid,
            .gt => low = mid + 1,
        }
    }
    return null;
}

fn outtime(ptr_in: [*:0]const u8, stream: ?*FILE) [*:0]const u8 {
    var ptr = ptr_in + 6;
    if (findCharConst(ptr, '}')) |end| {
        var format: dynbuf = .{};
        var output: [256:0]u8 = @splat(0);
        var secs: curl_off_t = 0;
        var usecs: c_uint = 0;
        var result: c_uint = 0;

        tool_zig_gettime_now(&secs, &usecs);
        const vlen = @intFromPtr(end) - @intFromPtr(ptr);
        curlx_dyn_init(&format, 1024);

        var i: usize = 0;
        while (result == 0 and i < vlen) : (i += 1) {
            if (i < vlen - 1 and ptr[i] == '%') {
                switch (ptr[i + 1]) {
                    'f' => result = curlx_dyn_addf(&format, "%06u", usecs),
                    's' => result = curlx_dyn_addf(&format, "%lld", secs),
                    'Z' => result = curlx_dyn_addn(&format, "UTC", 3),
                    'z' => result = curlx_dyn_addn(&format, "+0000", 5),
                    '%' => result = curlx_dyn_addn(&format, "%%", 2),
                    else => {
                        result = curlx_dyn_addn(&format, ptr + i, 1);
                        continue;
                    },
                }
                i += 1;
            } else {
                result = curlx_dyn_addn(&format, ptr + i, 1);
            }
        }
        if (result == 0) {
            if (curlx_dyn_len(&format) != 0) {
                if (curlx_dyn_ptr(&format)) |fmt_ptr| {
                    if (tool_zig_strftime_utc(secs, fmt_ptr, &output, output.len)) {
                        _ = fputs(&output, stream);
                    }
                }
            }
            curlx_dyn_free(&format);
        }
        ptr = end + 1;
    } else {
        _ = fputs("%time{", stream);
    }
    return ptr;
}

fn separator(sep_in: [*]const u8, seplen_in: usize, stream: ?*FILE) void {
    var sep = sep_in;
    var seplen = seplen_in;
    while (seplen != 0) {
        if (sep[0] == '\\') {
            switch (sep[1]) {
                'r' => _ = fputc('\r', stream),
                'n' => _ = fputc('\n', stream),
                't' => _ = fputc('\t', stream),
                '}' => _ = fputc('}', stream),
                0 => {},
                else => {
                    _ = fputc(@intCast(sep[0]), stream);
                    _ = fputc(@intCast(sep[1]), stream);
                },
            }
            if (seplen < 2) break;
            sep += 2;
            seplen -= 2;
        } else {
            _ = fputc(@intCast(sep[0]), stream);
            sep += 1;
            seplen -= 1;
        }
    }
}

fn output_header(per: *per_transfer, stream: ?*FILE, pptr: *[*:0]const u8) void {
    var ptr = pptr.*;
    var end = findCharConst(ptr, '}');
    while (end) |e| {
        if (@intFromPtr(e) <= @intFromPtr(ptr) or (e - 1)[0] != '\\')
            break;
        end = findCharConst(e + 1, '}');
    }
    if (end) |e| {
        var hname: [256:0]u8 = @splat(0);
        var header: ?*curl_header = null;
        var sep: ?[*]const u8 = null;
        var seplen: usize = 0;
        var vlen = @intFromPtr(e) - @intFromPtr(ptr);
        if (std.mem.indexOfScalar(u8, ptr[0..vlen], ':')) |colon_idx| {
            const rem = vlen - (colon_idx + 1);
            if (rem >= 4 and std.mem.eql(u8, ptr[colon_idx + 1 .. colon_idx + 5], "all:")) {
                sep = ptr + colon_idx + 5;
                seplen = @intFromPtr(e) - @intFromPtr(sep.?);
                vlen -= (seplen + 5);
            }
        }
        if (vlen < hname.len) {
            @memcpy(hname[0..vlen], ptr[0..vlen]);
            hname[vlen] = 0;
            const curl = tool_zig_per_curl(per);
            if (sep) |sp| {
                var reqno: c_int = 0;
                var indno: usize = 0;
                var output = false;
                while (true) {
                    if (curl_easy_header(curl, &hname, indno, CURLH_HEADER, reqno, &header) == CURLHE_OK and header != null) {
                        if (output)
                            separator(sp, seplen, stream);
                        _ = fputs(header.?.value, stream);
                        output = true;
                    } else {
                        break;
                    }
                    if ((header.?.index + 1) < header.?.amount) {
                        indno += 1;
                    } else {
                        reqno += 1;
                        indno = 0;
                    }
                }
            } else {
                if (curl_easy_header(curl, &hname, 0, CURLH_HEADER, -1, &header) == CURLHE_OK and header != null) {
                    _ = fputs(header.?.value, stream);
                }
            }
        }
        ptr = e + 1;
    } else {
        _ = fputs("%header{", stream);
    }
    pptr.* = ptr;
}

fn hasPrefixZ(s: [*:0]const u8, prefix: []const u8) bool {
    var i: usize = 0;
    while (i < prefix.len) : (i += 1) {
        if (s[i] == 0 or s[i] != prefix[i]) return false;
    }
    return true;
}

export fn ourWriteOut(config_opt: ?*OperationConfig, per: *per_transfer, per_result: c_uint) callconv(.c) void {
    const config = config_opt orelse return;
    const writeinfo = tool_zig_config_writeout(config) orelse return;
    var stream: ?*FILE = tool_zig_get_stdout();
    var ptr: [*:0]const u8 = writeinfo;
    var done = false;
    var fclose_stream = false;
    var name: dynbuf = .{};

    curlx_dyn_init(&name, MAX_WRITEOUT_NAME_LENGTH);
    defer {
        if (fclose_stream)
            _ = tool_zig_fclose(stream);
        curlx_dyn_free(&name);
    }

    while (ptr[0] != 0 and !done) {
        if (ptr[0] == '%' and ptr[1] != 0) {
            if (ptr[1] == '%') {
                _ = fputc('%', stream);
                ptr += 2;
            } else if (ptr[1] == '{') {
                const end = findCharConst(ptr, '}');
                ptr += 2;
                if (end == null) {
                    _ = fputs("%{", stream);
                    continue;
                }
                const vlen = @intFromPtr(end.?) - @intFromPtr(ptr);
                curlx_dyn_reset(&name);
                if (curlx_dyn_addn(&name, ptr, vlen) != 0)
                    break;
                const name_ptr = curlx_dyn_ptr(&name) orelse "";
                if (findWriteoutVar(name_ptr)) |wv| {
                    switch (wv.id) {
                        VAR_ONERROR => {
                            if (per_result == 0)
                                done = true;
                        },
                        VAR_STDOUT => {
                            if (fclose_stream)
                                _ = tool_zig_fclose(stream);
                            fclose_stream = false;
                            stream = tool_zig_get_stdout();
                        },
                        VAR_STDERR => {
                            if (fclose_stream)
                                _ = tool_zig_fclose(stream);
                            fclose_stream = false;
                            stream = tool_stderr;
                        },
                        VAR_JSON => {
                            ourWriteOutJSON(stream, &variables, variables.len, per, per_result);
                        },
                        VAR_HEADER_JSON => {
                            headerJSON(stream, per);
                        },
                        else => {
                            if (wv.writefunc) |wf| {
                                _ = wf(stream, wv, per, per_result, false);
                            }
                        },
                    }
                } else {
                    _ = curl_mfprintf(tool_stderr, "curl: unknown --write-out variable: '%.*s'\n", @as(c_int, @intCast(vlen)), ptr);
                }
                ptr = end.? + 1;
            } else if (hasPrefixZ(ptr + 1, "header{")) {
                ptr += 8;
                output_header(per, stream, &ptr);
            } else if (hasPrefixZ(ptr + 1, "time{")) {
                ptr = outtime(ptr, stream);
            } else if (hasPrefixZ(ptr + 1, "output{")) {
                var append = false;
                ptr += 8;
                if (ptr[0] == '>' and ptr[1] == '>') {
                    append = true;
                    ptr += 2;
                }
                if (findCharConst(ptr, '}')) |end| {
                    var fname: [512:0]u8 = @splat(0);
                    const flen = @intFromPtr(end) - @intFromPtr(ptr);
                    if (flen < fname.len) {
                        @memcpy(fname[0..flen], ptr[0..flen]);
                        fname[flen] = 0;
                        const mode = if (append) tool_zig_fopen_appendtext() else tool_zig_fopen_writetext();
                        if (tool_zig_fopen(&fname, mode)) |stream2| {
                            if (fclose_stream)
                                _ = tool_zig_fclose(stream);
                            stream = stream2;
                            fclose_stream = true;
                        }
                    }
                    ptr = end + 1;
                } else {
                    _ = fputs("%output{", stream);
                }
            } else {
                _ = fputc('%', stream);
                _ = fputc(@intCast(ptr[1]), stream);
                ptr += 2;
            }
        } else if (ptr[0] == '\\' and ptr[1] != 0) {
            switch (ptr[1]) {
                'r' => _ = fputc('\r', stream),
                'n' => _ = fputc('\n', stream),
                't' => _ = fputc('\t', stream),
                else => {
                    _ = fputc(@intCast(ptr[0]), stream);
                    _ = fputc(@intCast(ptr[1]), stream);
                },
            }
            ptr += 2;
        } else {
            _ = fputc(@intCast(ptr[0]), stream);
            ptr += 1;
        }
    }
}
